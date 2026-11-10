#!/usr/bin/env python3
"""n12lean_run.py -- full n=12 Lean pass over the CPOG leaves of the n=12 certified run.

For every leaf of the chosen route in the n=12 run's proofs.tsv (copied from the run's host, sha e9ded285...):
  1. regenerate piece.cnf from the SOURCE CNF exactly as the driver wrote it (tag_units/piece_text are the
     functions of scripts/n12_partition_all.py, copied in below); its sha256 must equal
     proofs.tsv <sha256 piece.cnf>                      -> else FAIL_CNF_SHA (final)
  2. pinned d4 -dDNNF piece.cnf -out=piece.nnf; `s N` must equal the recorded count -> else FAIL_D4_COUNT
  3. pinned cpog-gen piece.cnf piece.nnf piece.cpog; route CPOG: sha256 and size of piece.cpog must equal
     proofs.tsv <sha256 proof> <bytes>                  -> else FAIL_CPOG_SHA (final)
  4. the formally verified Lean 4 checker (VerifiedChecker `checker --count`) must print the whole line
     `PROOF SUCCESSFUL` and `Model count: <recorded count>` and exit 0
                                                        -> `PROOF FAILED` / wrong count = FAIL_LEAN (final)
  5. delete piece.{cnf,nnf,cpog}; keep the small logs (d4.out, gen.out, lean.out, *.time) under pieces/<tag>/.
Resource kills (timeout -k / prlimit / OOM, rc>=124 without a verdict) are RETRY_* and are re-run on resume
(up to --max-attempts, then FAIL_RESOURCE).  Pre-registered: ANY FAIL_* is recorded and the run CONTINUES
to finish the census; the final token is PASS only if every leaf of the route in proofs.tsv is ACCEPT and
(route CPOG) the accepted counts sum to --expect-sum.

Scheduling: a piece is admitted only if its predicted footprint
    reserve = rss_factor * proof_bytes + margin  (+ proof_bytes again when its files live in tmpfs)
fits under MemAvailable - headroom minus the NOT-YET-REALISED part of every in-flight reservation
(reserve_i - measured RSS of the piece's process tree - bytes already on tmpfs), and only while elapsed +
predicted wall (--s-per-gb x GB + --s-fixed) stays below the remaining-seconds cap.  Pieces are admitted
largest-first.  Every tool runs under nice, /usr/bin/time, timeout -k, prlimit --as.

Outputs (append-only, fsync'd per line): results.tsv, done.tsv (resume ledger), run.log, progress.log.
Abort rule (operator, 2026-11-08): if after >= 1 h the projected total wall exceeds
2 x --estimate-s, log ABORT_EVALUATION_TRIGGERED, stop admitting new pieces, finish the in-flight ones,
report; the caller also wraps the whole run in `timeout -k 60 <cap>`.
"""
import argparse, hashlib, os, re, shutil, signal, subprocess, sys, threading, time

RESULT_COLS = ("tag", "route", "rec_count", "rec_cnf_sha", "cnf_sha", "cnf_match", "d4_count", "rec_proof_sha",
               "cpog_sha", "cpog_match", "rec_bytes", "cpog_bytes", "bytes_match", "d4_wall_s", "gen_wall_s",
               "gen_rss_kb", "lean_wall_s", "lean_rss_kb", "lean_count", "lean_rc", "attempt", "where", "verdict",
               "ts")
FINAL_FAIL = ("FAIL_CNF_SHA", "FAIL_D4_COUNT", "FAIL_CPOG_SHA", "FAIL_LEAN", "FAIL_GEN_UNSAT_UNSUPPORTED",
              "FAIL_RESOURCE")
RETRY = ("RETRY_D4", "RETRY_GEN", "RETRY_LEAN")


# ---- piece construction: copied from scripts/n12_partition_all.py ------------------------------------------
def read_cnf(p):
    header, clauses = None, []
    for line in open(p):
        if line.startswith("p cnf"):
            header = line.split(); continue
        if line[:1] == "c" or not line.strip():
            continue
        clauses.append([int(t) for t in line.split()[:-1]])
    if header is None or len(clauses) != int(header[3]):
        raise SystemExit("EMIT_PIECE=FAIL source CNF parse mismatch")
    return int(header[2]), clauses


def tag_units(tag):
    if tag == "proot":
        return ()
    assert tag.startswith("p"), tag
    return tuple(int(x.replace("m", "-")) for x in tag[1:].split("_"))


def piece_text(nvars, clauses, units):
    out = ["p cnf %d %d\n" % (nvars, len(clauses) + len(units))]
    out += [" ".join(map(str, c)) + " 0\n" for c in clauses]
    out += ["%d 0\n" % u for u in units]
    return "".join(out)
# -------------------------------------------------------------------------------------------------------------


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 22), b""):
            h.update(b)
    return h.hexdigest()


def mem_available_b():
    for ln in open("/proc/meminfo"):
        if ln.startswith("MemAvailable:"):
            return int(ln.split()[1]) * 1024
    raise RuntimeError("no MemAvailable")


def tmpfs_free_b(path):
    st = os.statvfs(path)
    return st.f_bavail * st.f_frsize


def proc_tree_rss(roots):
    """RSS (bytes) of every process whose ancestry reaches a pid in `roots`, one /proc scan."""
    ppid, rss = {}, {}
    for d in os.listdir("/proc"):
        if not d.isdigit():
            continue
        try:
            with open("/proc/%s/stat" % d) as f:
                s = f.read()
            r = s.rfind(")")
            fld = s[r + 2:].split()
            ppid[int(d)] = int(fld[1])
            rss[int(d)] = int(fld[21]) * 4096
        except (OSError, IndexError, ValueError):
            pass
    out = {r: 0 for r in roots}
    for pid in rss:
        p, hops = pid, 0
        while p > 1 and hops < 64:
            if p in out:
                out[p] += rss[pid]; break
            p = ppid.get(p, 0); hops += 1
    return out


class Lean:
    SUCCESS = re.compile(r"^PROOF SUCCESSFUL\s*$", re.M)
    FAILED = re.compile(r"^PROOF FAILED\s*$", re.M)
    COUNT = re.compile(r"^Model count: (\d+)\s*$", re.M)

    @staticmethod
    def verdict(stdout, rc, expected):
        """-> (verdict, count|None).  ACCEPT only for rc 0 + whole-line PROOF SUCCESSFUL + exactly the expected count."""
        counts = Lean.COUNT.findall(stdout)
        c = int(counts[-1]) if counts else None
        if Lean.FAILED.search(stdout):
            return "FAIL_LEAN", c
        if Lean.SUCCESS.search(stdout):
            if rc == 0 and len(counts) == 1 and c == expected:
                return "ACCEPT", c
            return "FAIL_LEAN", c                      # success line but wrong/absent count or nonzero rc
        if rc >= 124 or rc < 0 or rc not in (0, 1) or "out of memory" in stdout or "bad_alloc" in stdout:
            return "RETRY_LEAN", c                     # timeout -k / signal / prlimit kill / OOM, no verdict
        return "FAIL_LEAN", c                          # exited rc 0/1 without any verdict line


def selftest():
    ok = Lean.verdict("Parsing CNF..\ndone.\nParsing CPOG..\ndone.\nChecking proof..\nPROOF SUCCESSFUL\nModel count: 80512\n", 0, 80512)
    assert ok == ("ACCEPT", 80512), ok
    bad = Lean.verdict("Parsing CNF..\ndone.\nParsing CPOG..\ndone.\nChecking proof..\nPROOF FAILED\nproof done but root literal was not set\n", 1, 0)
    assert bad == ("FAIL_LEAN", None), bad
    assert Lean.verdict("PROOF SUCCESSFUL\nModel count: 80513\n", 0, 80512) == ("FAIL_LEAN", 80513)
    assert Lean.verdict("PROOF SUCCESSFUL\nModel count: 80512\n", 1, 80512) == ("FAIL_LEAN", 80512)
    assert Lean.verdict("PROOF SUCCESSFUL\n", 0, 80512) == ("FAIL_LEAN", None)
    assert Lean.verdict("Parsing CNF..\ndone.\nParsing CPOG..\n", 124, 80512) == ("RETRY_LEAN", None)
    assert Lean.verdict("Parsing CNF..\ndone.\nParsing CPOG..\n", 137, 80512) == ("RETRY_LEAN", None)
    assert Lean.verdict("Parsing CNF..\ndone.\n", 1, 80512) == ("FAIL_LEAN", None)
    assert Lean.verdict("Parsing CNF..\ndone.\n", 134, 80512) == ("RETRY_LEAN", None)
    assert Lean.verdict("Parsing CNF..\nout of memory\n", 1, 80512) == ("RETRY_LEAN", None)
    assert Lean.verdict("PROOF SUCCESSFUL\nModel count: 7\nModel count: 7\n", 0, 7) == ("FAIL_LEAN", 7)
    assert Lean.verdict("xPROOF SUCCESSFUL\nModel count: 5\n", 0, 5) == ("FAIL_LEAN", 5)   # whole-line rule
    assert tag_units("p23_40_62") == (23, 40, 62) and tag_units("p1_m5") == (1, -5)
    print("SELFTEST=PASS")


class Runner:
    def __init__(self, a):
        self.a = a
        self.lock = threading.Lock()
        self.t0 = time.time()
        os.makedirs(a.out, exist_ok=True)
        self.pieces_dir = os.path.join(a.out, "pieces"); os.makedirs(self.pieces_dir, exist_ok=True)
        self.disk_work = os.path.join(a.out, "work"); os.makedirs(self.disk_work, exist_ok=True)
        self.tmp_root = os.path.join(a.tmpfs, "n12lean_%s" % a.route.lower()) if a.tmpfs else None
        if self.tmp_root:
            os.makedirs(self.tmp_root, exist_ok=True)
        self.logf = open(os.path.join(a.out, "run.log"), "a")
        self.progf = open(os.path.join(a.out, "progress.log"), "a")
        self.resf = open(os.path.join(a.out, "results.tsv"), "a")
        self.donef = open(os.path.join(a.out, "done.tsv"), "a")
        if os.path.getsize(os.path.join(a.out, "results.tsv")) == 0:
            self._append(self.resf, "\t".join(RESULT_COLS))
        self.nvars, self.clauses = read_cnf(a.src)
        self.src_sha = sha256_file(a.src)
        self.rows = self._load_proofs()
        self.done = self._load_done()
        self.inflight = {}        # tag -> dict(reserve, tmp_bytes, pid, files, state)
        self.abort_eval = False
        self.cap_hit = False
        self.stop_admit = False
        self.no_fit = 0
        self.sig = 0
        self.retry = []           # tags with a RETRY_* verdict and attempts left: re-queued by the main loop
        signal.signal(signal.SIGTERM, self._on_sig)
        signal.signal(signal.SIGINT, self._on_sig)

    def _on_sig(self, signum, frame):
        self.sig = signum

    # ---------- bookkeeping ----------
    def _append(self, f, line):
        f.write(line + "\n"); f.flush(); os.fsync(f.fileno())

    def log(self, msg):
        with self.lock:
            self._append(self.logf, "%s %s" % (time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), msg))

    def _load_proofs(self):
        rows = {}
        for ln in open(self.a.proofs):
            f = ln.rstrip("\n").split("\t")
            if len(f) < 6 or f[1] != self.a.route:
                continue
            rows[f[0]] = dict(tag=f[0], route=f[1], count=int(f[2]), cnf_sha=f[3], proof_sha=f[4], bytes=int(f[5]))
        if self.a.tags:
            want = [t.strip() for t in open(self.a.tags) if t.strip()] if os.path.exists(self.a.tags) \
                else self.a.tags.split(",")
            missing = [t for t in want if t not in rows]
            if missing:
                raise SystemExit("tags not in proofs.tsv with route %s: %s" % (self.a.route, missing))
            rows = {t: rows[t] for t in want}
        return rows

    def _load_done(self):
        done, attempts = {}, {}
        p = os.path.join(self.a.out, "done.tsv")
        for ln in open(p):
            f = ln.rstrip("\n").split("\t")
            if len(f) < 4:
                continue
            tag, verdict, att = f[0], f[1], int(f[2])
            attempts[tag] = max(attempts.get(tag, 0), att)
            if verdict == "ACCEPT" or verdict in FINAL_FAIL:
                done[tag] = verdict
        self.attempts = attempts
        return done

    # ---------- tool execution ----------
    def run_tool(self, argv, cwd, timeout_s, as_bytes, stdout_path, time_path, tag):
        cmd = ["nice", "-n", str(self.a.nice), "/usr/bin/time", "-f", "TIME wall=%e rss_kb=%M rc=%x", "-o", time_path,
               "timeout", "-k", "30", str(int(timeout_s)), "prlimit", "--as=%d" % int(as_bytes)] + argv
        # cpog-gen calls `cadical` and `drat-trim` by bare name (clausal.cpp:599,678,2206) -> pinned tools dir first on PATH
        env = dict(os.environ, LEAN_NUM_THREADS="1",
                   PATH=os.path.dirname(os.path.abspath(self.a.cpog_gen)) + ":" + os.environ.get("PATH", ""))
        with open(stdout_path, "wb") as so:
            p = subprocess.Popen(cmd, cwd=cwd, stdout=so, stderr=subprocess.STDOUT, env=env, start_new_session=True)
            with self.lock:
                if tag in self.inflight:
                    self.inflight[tag]["pid"] = p.pid
            rc = p.wait()
        with self.lock:
            if tag in self.inflight:
                self.inflight[tag]["pid"] = None
        wall, rss = -1.0, -1
        try:
            m = re.search(r"TIME wall=([\d.]+) rss_kb=(\d+)", open(time_path).read())
            if m:
                wall, rss = float(m.group(1)), int(m.group(2))
        except OSError:
            pass
        return rc, wall, rss

    # ---------- one piece ----------
    def do_piece(self, row, where):
        a, tag = self.a, row["tag"]
        attempt = self.attempts.get(tag, 0) + 1
        self.attempts[tag] = attempt
        keep = os.path.join(self.pieces_dir, tag); os.makedirs(keep, exist_ok=True)
        wd = os.path.join(where, tag)
        shutil.rmtree(wd, ignore_errors=True); os.makedirs(wd)
        cnf, nnf, cpog = (os.path.join(wd, "piece." + e) for e in ("cnf", "nnf", "cpog"))
        with self.lock:
            self.inflight[tag]["files"] = (cnf, nnf, cpog)
        gb = row["bytes"] / 1e9
        R = dict((c, "") for c in RESULT_COLS)
        R.update(tag=tag, route=row["route"], rec_count=row["count"], rec_cnf_sha=row["cnf_sha"],
                 rec_proof_sha=row["proof_sha"], rec_bytes=row["bytes"], attempt=attempt, where=os.path.basename(where))
        verdict = None
        try:
            # 1. emit + cnf sha
            text = piece_text(self.nvars, self.clauses, tag_units(tag))
            with open(cnf, "w") as f:
                f.write(text)
            R["cnf_sha"] = hashlib.sha256(text.encode()).hexdigest()
            R["cnf_match"] = "YES" if R["cnf_sha"] == row["cnf_sha"] else "NO"
            if R["cnf_match"] != "YES":
                verdict = "FAIL_CNF_SHA"; return
            # 2. d4
            rc, w, rss = self.run_tool([a.d4, "-dDNNF", cnf, "-out=" + nnf], wd, a.d4_timeout,
                                       4 << 30, os.path.join(keep, "d4.out"), os.path.join(keep, "d4.time"), tag)
            R["d4_wall_s"] = w
            m = re.findall(r"(?m)^s (\d+)\s*$", open(os.path.join(keep, "d4.out"), errors="replace").read())
            if rc != 0 or not m or not os.path.exists(nnf):
                verdict = "RETRY_D4"; return
            R["d4_count"] = int(m[-1])
            if R["d4_count"] != row["count"]:
                verdict = "FAIL_D4_COUNT"; return
            # 3. cpog-gen
            gen_as = max(8 << 30, int(row["bytes"] * 4) + (4 << 30))
            rc, w, rss = self.run_tool([a.cpog_gen, cnf, nnf, cpog], wd, a.gen_fixed + a.gen_s_per_gb * gb, gen_as,
                                       os.path.join(keep, "gen.out"), os.path.join(keep, "gen.time"), tag)
            R["gen_wall_s"], R["gen_rss_kb"] = w, rss
            if rc != 0 or not os.path.exists(cpog):
                txt = open(os.path.join(keep, "gen.out"), errors="replace").read()
                if "Compiled formula unsatisfiable" in txt:
                    if os.path.exists(cpog):
                        R["cpog_sha"], R["cpog_bytes"] = sha256_file(cpog), os.path.getsize(cpog)
                    verdict = "FAIL_GEN_UNSAT_UNSUPPORTED"; return
                verdict = "RETRY_GEN"; return
            R["cpog_sha"], R["cpog_bytes"] = sha256_file(cpog), os.path.getsize(cpog)
            if row["route"] == "CPOG":
                R["cpog_match"] = "YES" if R["cpog_sha"] == row["proof_sha"] else "NO"
                R["bytes_match"] = "YES" if R["cpog_bytes"] == row["bytes"] else "NO"
                if R["cpog_match"] != "YES" or R["bytes_match"] != "YES":
                    verdict = "FAIL_CPOG_SHA"; return
            else:
                R["cpog_match"] = R["bytes_match"] = "n/a"      # recorded proof is a DRAT, not a CPOG
            if os.path.exists(nnf):
                os.unlink(nnf)
            # 4. verified checker
            lean_as = max(8 << 30, int(R["cpog_bytes"] * 8) + (4 << 30))
            rc, w, rss = self.run_tool([a.checker, "--count", cnf, cpog], wd,
                                       a.lean_fixed + a.lean_s_per_gb * R["cpog_bytes"] / 1e9, lean_as,
                                       os.path.join(keep, "lean.out"), os.path.join(keep, "lean.time"), tag)
            R["lean_wall_s"], R["lean_rss_kb"], R["lean_rc"] = w, rss, rc
            out = open(os.path.join(keep, "lean.out"), errors="replace").read()
            verdict, R["lean_count"] = Lean.verdict(out, rc, row["count"])
            if R["lean_count"] is None:
                R["lean_count"] = ""
        except Exception as e:  # noqa
            self.log("EXCEPTION tag=%s %r" % (tag, e))
            verdict = "RETRY_GEN" if verdict is None else verdict
        finally:
            if verdict in RETRY and attempt >= a.max_attempts:
                verdict = "FAIL_RESOURCE"
            R["verdict"] = verdict
            R["ts"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
            shutil.rmtree(wd, ignore_errors=True)           # 5. delete the regenerated proof + cnf + nnf
            with self.lock:
                self._append(self.resf, "\t".join(str(R[c]) for c in RESULT_COLS))
                self._append(self.donef, "\t".join([tag, verdict, str(attempt), R["ts"]]))
                if verdict == "ACCEPT" or verdict in FINAL_FAIL:
                    self.done[tag] = verdict
                elif verdict in RETRY and not self.sig:
                    self.retry.append(tag)
                self.inflight.pop(tag, None)
            self.log("PIECE tag=%s verdict=%s attempt=%d bytes=%d gen=%ss lean=%ss lean_rss_kb=%s where=%s"
                     % (tag, verdict, attempt, row["bytes"], R["gen_wall_s"], R["lean_wall_s"], R["lean_rss_kb"],
                        R["where"]))

    # ---------- scheduler ----------
    def reserve_for(self, row, on_tmpfs):
        return int(self.a.rss_factor * row["bytes"] + self.a.margin_mb * 1e6 + (row["bytes"] if on_tmpfs else 0))

    def unrealised(self):
        """Sum over in-flight pieces of (reserve - what is already visible in MemAvailable)."""
        pids = [v["pid"] for v in self.inflight.values() if v.get("pid")]
        rss = proc_tree_rss(pids) if pids else {}
        tot = 0
        for v in self.inflight.values():
            used = rss.get(v.get("pid") or -1, 0)
            if v["on_tmpfs"]:
                for f in v.get("files", ()):
                    try:
                        used += os.path.getsize(f)
                    except OSError:
                        pass
            tot += max(0, v["reserve"] - used)
        return tot

    def tmpfs_unrealised(self):
        tot = 0
        for v in self.inflight.values():
            if not v["on_tmpfs"]:
                continue
            present = 0
            for f in v.get("files", ()):
                try:
                    present += os.path.getsize(f)
                except OSError:
                    pass
            tot += max(0, v["tmp_bytes"] - present)
        return tot

    def predicted_wall(self, row):
        return self.a.s_fixed + self.a.s_per_gb * row["bytes"] / 1e9

    def main(self):
        a = self.a
        pending = sorted((r for t, r in self.rows.items() if t not in self.done), key=lambda r: -r["bytes"])
        total_b = sum(r["bytes"] for r in self.rows.values())
        done_b0 = sum(self.rows[t]["bytes"] for t in self.done)
        self.log("START route=%s leaves=%d pending=%d bytes_total=%d bytes_done_before=%d jobs=%d headroom_gb=%.1f "
                 "rss_factor=%.2f margin_mb=%d remaining_s=%d estimate_s=%d tmpfs=%s src=%s src_sha=%s proofs_sha=%s "
                 "d4=%s cpog_gen=%s checker=%s" %
                 (a.route, len(self.rows), len(pending), total_b, done_b0, a.jobs, a.headroom_gb, a.rss_factor,
                  a.margin_mb, a.remaining_s, a.estimate_s, self.tmp_root, a.src, self.src_sha,
                  sha256_file(a.proofs), sha256_file(a.d4), sha256_file(a.cpog_gen), sha256_file(a.checker)))
        threads, last_prog, last_eval = [], 0, 0
        while pending or self.inflight or self.retry:
            now = time.time(); elapsed = now - self.t0
            with self.lock:
                if self.retry and not self.stop_admit:
                    pending = sorted(pending + [self.rows[t] for t in self.retry], key=lambda r: -r["bytes"])
                    self.log("REQUEUE %s" % ",".join(self.retry))
                self.retry = []
            # progress + abort rule
            if now - last_prog >= a.progress_s:
                last_prog = now
                done_b = sum(self.rows[t]["bytes"] for t in self.done)
                frac = (done_b - done_b0) / max(1, total_b - done_b0)
                proj = elapsed / frac if frac > 0 else float("inf")
                self._append(self.progf, "%s elapsed_s=%d done=%d/%d bytes_done=%d/%d inflight=%d mem_avail_gb=%.1f "
                             "tmpfs_free_gb=%.1f projected_total_s=%s" %
                             (time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()), elapsed, len(self.done), len(self.rows),
                              done_b, total_b, len(self.inflight), mem_available_b() / 1e9,
                              (tmpfs_free_b(self.tmp_root) / 1e9) if self.tmp_root else 0,
                              "%d" % proj if proj != float("inf") else "inf"))
                if elapsed >= 3600 and frac > 0 and proj > 2 * a.estimate_s and not self.abort_eval:
                    self.abort_eval = True; self.stop_admit = True
                    self.log("ABORT_EVALUATION_TRIGGERED projected_total_s=%d > 2x estimate_s=%d; no new admissions, "
                             "finishing in-flight pieces (resumable)" % (proj, a.estimate_s))
            if self.sig:
                if not self.stop_admit:
                    self.stop_admit = True
                    self.log("SIGNAL %d received: no new admissions, killing in-flight process groups (they resume as RETRY)" % self.sig)
                with self.lock:
                    for v in self.inflight.values():
                        if v.get("pid"):
                            try:
                                os.killpg(v["pid"], 15)
                            except OSError:
                                pass
                pending = []
            # admissions
            admitted = False; wait_s = a.poll_s
            if pending and not self.stop_admit and len(self.inflight) < a.jobs:
                with self.lock:
                    mem_now = mem_available_b()
                    budget = mem_now - int(a.headroom_gb * 1e9) - self.unrealised()
                    if a.max_reserve_gb:
                        budget = min(budget, int(a.max_reserve_gb * 1e9) - sum(v["reserve"] for v in self.inflight.values()))
                    tfree = (tmpfs_free_b(self.tmp_root) - int(a.tmpfs_reserve_gb * 1e9) - self.tmpfs_unrealised()) \
                        if self.tmp_root else -1
                    for i, row in enumerate(pending):
                        if elapsed + self.predicted_wall(row) > a.remaining_s - a.cap_margin_s:
                            continue
                        tmp_bytes = row["bytes"] + 32 * 1024 * 1024 + len(self.clauses) * 64
                        on_tmpfs = self.tmp_root is not None and tmp_bytes <= tfree
                        res = self.reserve_for(row, on_tmpfs)
                        if res <= budget:
                            self.inflight[row["tag"]] = dict(reserve=res, tmp_bytes=tmp_bytes if on_tmpfs else 0,
                                                              on_tmpfs=on_tmpfs, pid=None, files=())
                            where = self.tmp_root if on_tmpfs else self.disk_work
                            th = threading.Thread(target=self.do_piece, args=(row, where), daemon=True)
                            th.start(); threads.append(th)
                            pending.pop(i); admitted = True
                            break
                    idle = not self.inflight
                if not admitted and idle and pending:
                    # nothing fits on an idle machine: the cap, or a piece larger than the whole budget
                    smallest = min(pending, key=lambda r: r["bytes"])
                    if elapsed + self.predicted_wall(smallest) > a.remaining_s - a.cap_margin_s:
                        self.cap_hit = True
                        self.log("CAP_REACHED remaining_s=%d elapsed_s=%d pending=%d; stopping admissions"
                                 % (a.remaining_s, elapsed, len(pending)))
                        pending = []
                    elif self.reserve_for(smallest, False) > mem_now - int(a.headroom_gb * 1e9) or \
                            (a.max_reserve_gb and self.reserve_for(smallest, False) > a.max_reserve_gb * 1e9):
                        self.no_fit += 1
                        if self.no_fit >= 30:
                            self.log("NO_FIT_PERMANENT pending=%d smallest_bytes=%d mem_avail_b=%d; stopping admissions"
                                     % (len(pending), smallest["bytes"], mem_now))
                            pending = []
                        else:
                            self.log("NO_FIT pending=%d smallest_bytes=%d budget_b=%d mem_avail_b=%d; waiting %ds"
                                     % (len(pending), smallest["bytes"], budget, mem_now, a.poll_s * 10))
                            wait_s = a.poll_s * 10
                    else:
                        wait_s = a.poll_s * 5     # transient: tmpfs/unrealised accounting; try again
            if not admitted:
                time.sleep(wait_s)
            threads = [t for t in threads if t.is_alive()]
        for t in threads:
            t.join()
        return self.finish(pending_left=len(pending))

    def finish(self, pending_left):
        a = self.a
        acc = [t for t, v in self.done.items() if v == "ACCEPT"]
        fails = {}
        for t, v in self.done.items():
            if v != "ACCEPT":
                fails[v] = fails.get(v, 0) + 1
        not_done = [t for t in self.rows if t not in self.done]   # includes RETRY-state and never-admitted pieces
        ssum = sum(self.rows[t]["count"] for t in acc)
        ok = len(acc) == len(self.rows) and not fails and not not_done and (a.expect_sum is None or ssum == a.expect_sum)
        name = a.token
        tok = ("%s=%s %s_leaves=%d accepted=%d sum_count=%d fails=%s not_done=%d elapsed_s=%d abort_eval=%s cap_hit=%s signal=%d"
               % (name, "PASS" if ok else "FAIL", a.route.lower(), len(self.rows), len(acc), ssum,
                  ",".join("%s:%d" % kv for kv in sorted(fails.items())) or "none", len(not_done),
                  time.time() - self.t0, self.abort_eval, self.cap_hit, self.sig))
        self.log(tok); print(tok, flush=True)
        if self.tmp_root:
            shutil.rmtree(self.tmp_root, ignore_errors=True)
        return 0 if ok else 1


def parse():
    H = os.path.expanduser("~")
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--proofs", default=H + "/n12lean/proofs.tsv")
    p.add_argument("--src", default=H + "/n12/n12.cnf")
    p.add_argument("--route", default="CPOG", choices=("CPOG", "DRAT0"))
    p.add_argument("--tags", default=None, help="file of tags or comma list; default = every leaf of --route")
    p.add_argument("--out", required=True)
    p.add_argument("--token", default=None, help="summary token name; default N12_LEAN_FULL when --tags is absent "
                                                 "and route CPOG, else N12_LEAN_SUBSET")
    p.add_argument("--expect-sum", type=int, default=None)
    p.add_argument("--jobs", type=int, default=40)
    p.add_argument("--nice", type=int, default=19)
    p.add_argument("--headroom-gb", type=float, default=20.0)
    p.add_argument("--max-reserve-gb", type=float, default=0, help="cap on the sum of in-flight reservations (0 = none)")
    p.add_argument("--rss-factor", type=float, default=3.7)
    p.add_argument("--margin-mb", type=int, default=512)
    p.add_argument("--tmpfs", default="/dev/shm", help="'' to keep every piece on disk")
    p.add_argument("--tmpfs-reserve-gb", type=float, default=8.0)
    p.add_argument("--remaining-s", type=int, default=43200, help="wall cap for admissions (seconds from start)")
    p.add_argument("--cap-margin-s", type=int, default=600)
    p.add_argument("--estimate-s", type=int, default=21600, help="central wall estimate; 2x triggers ABORT_EVALUATION")
    p.add_argument("--s-per-gb", type=float, default=150.0, help="predicted wall per GB of proof (admission vs cap)")
    p.add_argument("--s-fixed", type=float, default=60.0)
    p.add_argument("--d4-timeout", type=float, default=900)
    p.add_argument("--gen-fixed", type=float, default=600); p.add_argument("--gen-s-per-gb", type=float, default=300)
    p.add_argument("--lean-fixed", type=float, default=600); p.add_argument("--lean-s-per-gb", type=float, default=200)
    p.add_argument("--max-attempts", type=int, default=3)
    p.add_argument("--poll-s", type=float, default=2.0)
    p.add_argument("--progress-s", type=float, default=300)
    p.add_argument("--d4", default=H + "/tools/bin/d4")
    p.add_argument("--cpog-gen", default=H + "/tools/bin/cpog-gen")
    p.add_argument("--checker", default=H + "/k0910/VerifiedChecker/.lake/build/bin/checker")
    p.add_argument("--selftest", action="store_true")
    a = p.parse_args()
    if a.token is None:
        a.token = "N12_LEAN_FULL" if (a.tags is None and a.route == "CPOG") else "N12_LEAN_SUBSET"
    if a.tmpfs == "":
        a.tmpfs = None
    return a


if __name__ == "__main__":
    a = parse()
    if a.selftest:
        selftest(); sys.exit(0)
    sys.exit(Runner(a).main())
