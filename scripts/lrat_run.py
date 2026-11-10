#!/usr/bin/env python3
"""lrat_run.py — resumable pass over the DRAT0 (UNSAT) leaves of a decomp_certify_v3 run, re-verifying each
leaf with the formally verified LRAT checker shipped in the Lean 4 toolchain (lratcheck, ~/lrat/lratcheck).

Per leaf, in order (every binary under `nice -n 19 timeout -k 10 <T> prlimit --as=<cap>`):
  1. piece.cnf regenerated from the SOURCE CNF (tag_units/piece_text of n12_partition_all.py); its sha256 must
     equal proofs.tsv col 4                                   -> else FAIL_CNF_SHA
  2. cadical --no-binary --unsat -q piece.cnf proof.drat; rc must be 20   -> rc 10 FAIL_SAT, other rc RETRY_CADICAL
     (regenerated DRAT sha/bytes are compared with proofs.tsv cols 5/6 and RECORDED, not gated: cadical's
      determinism is not a certificate property)
  3. LRAT hints: default `cadical --no-binary --lrat --unsat -q piece.cnf proof.lrat` (rc 20 required), or with
     --lrat-source drat-trim: `drat-trim piece.cnf proof.drat -L proof.lrat` (verdict recorded, not the judge;
     NOTE: the Lean checker rejects drat-trim's LRAT: its lemma ids are not consecutive)   -> no/empty proof.lrat: FAIL_NO_LRAT
  4. lratcheck piece.cnf proof.lrat: rc 0 + whole line `LRAT_LEAN=VERIFIED` -> ACCEPT
     rc 1 / `LRAT_LEAN=REJECTED` -> FAIL_LEAN_REJECT; rc 2 / `LRAT_LEAN=ERROR` -> FAIL_LEAN_ERROR;
     rc >= 124 or signal -> RETRY_LEAN
Pre-registered: every FAIL_* is written and the census continues; RETRY_* are re-queued up to --max-attempts,
then FAIL_RESOURCE.  Ledgers results.tsv / done.tsv are append-only, one fsync per line; done.tsv is the resume
ledger (ACCEPT and FAIL_* final).  Abort rule: after >= --abort-after-s and >= 20 leaves, projected total wall
> 2 x --estimate-s -> ABORT_EVALUATION_TRIGGERED (no new admissions, in-flight finish, token FAIL, resumable).
Admission: in-flight < --jobs and MemAvailable - --headroom-gb >= --reserve-gb x (in-flight + 1) and
--reserve-gb x (in-flight + 1) <= --max-rss-gb.  Final token (last line of run.log):
  UNSAT_LEAN_FULL=PASS|FAIL run=<name> leaves=<n> verified=<n> fails=<n> [not_done=<n> ...]
"""
import argparse, hashlib, os, re, signal, subprocess, sys, time, threading, random
from concurrent.futures import ThreadPoolExecutor, wait, FIRST_COMPLETED

STOP = False
INFLIGHT = {}            # tag -> Popen (for SIGTERM)
INFLIGHT_LOCK = threading.Lock()

def ts():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())

def mem_available_gb():
    for ln in open("/proc/meminfo"):
        if ln.startswith("MemAvailable:"):
            return int(ln.split()[1]) / 1048576.0
    return 0.0

def sha256_bytes(b):
    return hashlib.sha256(b).hexdigest()

def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for ch in iter(lambda: f.read(1 << 20), b""):
            h.update(ch)
    return h.hexdigest()

# ---- piece emission (copied from n12_partition_all.py) ----
def read_cnf(p):
    header, clauses = None, []
    for line in open(p):
        if line.startswith("p cnf"):
            header = line.split(); continue
        if line[:1] == "c" or not line.strip():
            continue
        clauses.append([int(t) for t in line.split()[:-1]])
    if header is None or len(clauses) != int(header[3]):
        raise SystemExit("FATAL source CNF parse mismatch")
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

# ---- ledgers ----
class Ledger:
    def __init__(self, path, header=None):
        new = not os.path.exists(path) or os.path.getsize(path) == 0
        self.f = open(path, "a")
        self.lock = threading.Lock()
        if new and header:
            self.write(header)
    def write(self, cols):
        line = "\t".join(str(c) for c in cols) + "\n"
        with self.lock:
            self.f.write(line); self.f.flush(); os.fsync(self.f.fileno())

RES_COLS = ["tag", "route", "rec_cnf_sha", "regen_cnf_sha", "cnf_match", "rec_drat_sha", "regen_drat_sha",
            "drat_match", "rec_bytes", "regen_bytes", "cadical_rc", "cadical_wall", "cadical_rss_kb",
            "drattrim_verdict", "drattrim_rc", "drattrim_wall", "drattrim_rss_kb", "lrat_bytes", "lrat_actions",
            "lean_out", "lean_rc", "lean_wall", "lean_rss_kb", "attempt", "verdict", "ts"]

def run_tool(tag, argv, cwd, timeout_s, cap_kb, logpath):
    """nice 19, timeout -k 10, prlimit --as; returns (rc, stdout_text, wall, rss_kb). rc 124/137 = timeout."""
    cmd = ["nice", "-n", "19", "/usr/bin/time", "-f", "TIMEV %e %M", "timeout", "-k", "10", str(timeout_s),
           "prlimit", "--as=%d" % (cap_kb * 1024)] + argv
    t0 = time.time()
    with open(logpath, "w") as lf:
        p = subprocess.Popen(cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=lf, start_new_session=True, text=True)
        with INFLIGHT_LOCK:
            INFLIGHT[tag] = p
        out, _ = p.communicate()
        with INFLIGHT_LOCK:
            INFLIGHT.pop(tag, None)
    wall = time.time() - t0
    rss = -1
    try:
        for ln in open(logpath):
            if ln.startswith("TIMEV "):
                _, w, m = ln.split(); wall = float(w); rss = int(m)
    except Exception:
        pass
    return p.returncode, out or "", wall, rss

def leaf(a, src, rec, attempt, ledger):
    tag = rec[0]; route = rec[1]; rec_cnf = rec[3]; rec_drat = rec[4]; rec_bytes = int(rec[5])
    d = os.path.join(a.out, "work", tag); os.makedirs(d, exist_ok=True)
    row = dict.fromkeys(RES_COLS, "-"); row.update(tag=tag, route=route, rec_cnf_sha=rec_cnf, rec_drat_sha=rec_drat,
                                                    rec_bytes=rec_bytes, attempt=attempt)
    def finish(verdict):
        row["verdict"] = verdict; row["ts"] = ts()
        ledger.write([row[c] for c in RES_COLS])
        if not a.keep:
            for fn in ("piece.cnf", "proof.drat", "proof.lrat"):
                try: os.unlink(os.path.join(d, fn))
                except FileNotFoundError: pass
        return verdict
    text = piece_text(src[0], src[1], tag_units(tag))
    sha = sha256_bytes(text.encode())
    row["regen_cnf_sha"] = sha; row["cnf_match"] = "YES" if sha == rec_cnf else "NO"
    if sha != rec_cnf:
        return finish("FAIL_CNF_SHA")
    cnf = os.path.join(d, "piece.cnf"); drat = os.path.join(d, "proof.drat"); lrat = os.path.join(d, "proof.lrat")
    with open(cnf, "w") as f:
        f.write(text)
    rc, out, w, rss = run_tool(tag, [os.path.join(a.bin, "cadical"), "--no-binary", "--unsat", "-q", cnf, drat],
                               d, a.tool_timeout, a.cap_kb, os.path.join(d, "cadical.err"))
    row.update(cadical_rc=rc, cadical_wall="%.2f" % w, cadical_rss_kb=rss)
    if rc == 10:
        return finish("FAIL_SAT")
    if rc != 20:
        return finish("RETRY_CADICAL")
    row["regen_bytes"] = os.path.getsize(drat); row["regen_drat_sha"] = sha256_file(drat)
    row["drat_match"] = "YES" if (row["regen_drat_sha"] == rec_drat and row["regen_bytes"] == rec_bytes) else "NO"
    try: os.unlink(lrat)
    except FileNotFoundError: pass
    if a.lrat_source == "drat-trim":
        rc, out, w, rss = run_tool(tag, [os.path.join(a.bin, "drat-trim"), cnf, drat, "-L", lrat],
                                   d, a.tool_timeout, a.cap_kb, os.path.join(d, "drattrim.err"))
        verd = [ln.strip("\r") for ln in out.split("\n") if ln.strip("\r").startswith("s ")]
        row.update(drattrim_verdict=(verd[-1] if verd else "none"), drattrim_rc=rc, drattrim_wall="%.2f" % w,
                   drattrim_rss_kb=rss)
        if rc >= 124:
            return finish("RETRY_DRATTRIM")
    else:  # cadical's native LRAT (the hint producer bv_decide itself uses); a second, independent solve
        rc, out, w, rss = run_tool(tag, [os.path.join(a.bin, "cadical"), "--no-binary", "--lrat", "--unsat", "-q", cnf, lrat],
                                   d, a.tool_timeout, a.cap_kb, os.path.join(d, "cadical_lrat.err"))
        row.update(drattrim_verdict="cadical--lrat", drattrim_rc=rc, drattrim_wall="%.2f" % w, drattrim_rss_kb=rss)
        if rc == 10:
            return finish("FAIL_SAT")
        if rc != 20:
            return finish("RETRY_CADICAL_LRAT")
    if not os.path.exists(lrat) or os.path.getsize(lrat) == 0:
        return finish("FAIL_NO_LRAT")
    row["lrat_bytes"] = os.path.getsize(lrat)
    rc, out, w, rss = run_tool(tag, [a.lean, cnf, lrat], d, a.tool_timeout, a.cap_kb, os.path.join(d, "lean.err"))
    lines = [ln.strip("\r") for ln in out.split("\n")]
    m = [ln for ln in lines if ln.startswith("LRAT_LEAN=")]
    acts = [ln for ln in lines if ln.startswith("c vars=")]
    if acts:
        mm = re.search(r"lrat_actions=(\d+)", acts[-1]); row["lrat_actions"] = mm.group(1) if mm else "-"
    row.update(lean_out=(m[-1][:80] if m else "none"), lean_rc=rc, lean_wall="%.2f" % w, lean_rss_kb=rss)
    if rc >= 124 or rc < 0:
        return finish("RETRY_LEAN")
    if rc == 0 and m and m[-1] == "LRAT_LEAN=VERIFIED" and len(m) == 1:
        return finish("ACCEPT")
    if rc == 1 and m and m[-1] == "LRAT_LEAN=REJECTED":
        return finish("FAIL_LEAN_REJECT")
    return finish("FAIL_LEAN_ERROR")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True); ap.add_argument("--run-name", required=True)
    ap.add_argument("--proofs", required=True); ap.add_argument("--source", required=True)
    ap.add_argument("--bin", default=os.path.expanduser("~/tools/bin"))
    ap.add_argument("--lean", default=os.path.expanduser("~/lrat/lratcheck/.lake/build/bin/lratcheck"))
    ap.add_argument("--route", default="DRAT0"); ap.add_argument("--tags", help="file of tags (default: all of --route)")
    ap.add_argument("--jobs", type=int, default=3); ap.add_argument("--tool-timeout", type=int, default=600)
    ap.add_argument("--cap-kb", type=int, default=8 << 20, help="prlimit --as per tool, kB (default 8 GiB)")
    ap.add_argument("--reserve-gb", type=float, default=1.0); ap.add_argument("--headroom-gb", type=float, default=20.0)
    ap.add_argument("--max-rss-gb", type=float, default=24.0)
    ap.add_argument("--remaining-s", type=int, default=7200); ap.add_argument("--estimate-s", type=int, default=3600)
    ap.add_argument("--abort-after-s", type=int, default=600); ap.add_argument("--max-attempts", type=int, default=3)
    ap.add_argument("--lrat-source", choices=["cadical", "drat-trim"], default="cadical",
                    help="hint producer: cadical --lrat (default) or drat-trim -L (rejected by the Lean checker: non-consecutive lemma ids)")
    ap.add_argument("--keep", action="store_true"); ap.add_argument("--shuffle", action="store_true")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    runlog = open(os.path.join(a.out, "run.log"), "a")
    def log(msg):
        line = "%s %s" % (ts(), msg); print(line, flush=True); runlog.write(line + "\n"); runlog.flush()
    t_start = time.time()
    for p in (a.proofs, a.source, a.lean, os.path.join(a.bin, "cadical"), os.path.join(a.bin, "drat-trim")):
        if not os.path.exists(p):
            log("FATAL missing %s" % p); print_token(a, 0, 0, {}, 0, False); sys.exit(2)
    log("START run=%s pid=%d proofs=%s sha=%s source=%s sha=%s lean=%s sha=%s cadical=%s drat-trim=%s" % (
        a.run_name, os.getpid(), a.proofs, sha256_file(a.proofs), a.source, sha256_file(a.source), a.lean,
        sha256_file(a.lean), sha256_file(os.path.join(a.bin, "cadical")), sha256_file(os.path.join(a.bin, "drat-trim"))))
    recs = {}
    for ln in open(a.proofs):
        f = ln.rstrip("\n").split("\t")
        if len(f) >= 6 and f[1] == a.route:
            recs[f[0]] = f
    tags = [t.strip() for t in open(a.tags) if t.strip()] if a.tags else sorted(recs, key=lambda t: -int(recs[t][5]))
    missing = [t for t in tags if t not in recs]
    if missing:
        log("FATAL %d tags not in proofs.tsv with route %s: %s" % (len(missing), a.route, missing[:5])); sys.exit(2)
    if a.shuffle:
        random.shuffle(tags)
    res = Ledger(os.path.join(a.out, "results.tsv"), RES_COLS)
    done_path = os.path.join(a.out, "done.tsv")
    state = {}
    if os.path.exists(done_path):
        for ln in open(done_path):
            f = ln.rstrip("\n").split("\t")
            if len(f) >= 3: state[f[0]] = (f[1], int(f[2]))
    done = Ledger(done_path)
    pending = []
    for t in tags:
        v, att = state.get(t, (None, 0))
        if v is None or v.startswith("RETRY_"):
            pending.append((t, att + 1))
    log("leaves=%d already_final=%d pending=%d jobs=%d" % (len(tags), len(tags) - len(pending), len(pending), a.jobs))
    src = read_cnf(a.source)
    def on_term(sig, frm):
        global STOP
        STOP = True
        log("SIGNAL %d: no new admissions, killing in-flight process groups" % sig)
        with INFLIGHT_LOCK:
            for t, p in INFLIGHT.items():
                try: os.killpg(p.pid, signal.SIGTERM)
                except Exception: pass
    signal.signal(signal.SIGTERM, on_term); signal.signal(signal.SIGINT, on_term)
    counts = {}; n_done_now = 0; aborted = False; cap_hit = False; last_prog = time.time()
    pool = ThreadPoolExecutor(max_workers=a.jobs); futs = {}
    i = 0
    while i < len(pending) or futs:
        now = time.time(); elapsed = now - t_start
        # progress + abort evaluation
        if now - last_prog >= 60 and n_done_now:
            rate = elapsed / n_done_now; proj = rate * len(pending)
            log("PROGRESS done=%d/%d elapsed_s=%.0f per_leaf_s=%.3f projected_total_s=%.0f memavail_gb=%.1f" % (
                n_done_now, len(pending), elapsed, rate, proj, mem_available_gb()))
            last_prog = now
            if elapsed >= a.abort_after_s and n_done_now >= 20 and proj > 2 * a.estimate_s and not aborted:
                aborted = True; log("ABORT_EVALUATION_TRIGGERED projected=%.0f > 2 x estimate %d" % (proj, a.estimate_s))
        if i < len(pending) and not STOP and not aborted:
            if elapsed + 2 * a.tool_timeout > a.remaining_s:
                cap_hit = True; log("CAP_REACHED remaining_s=%d pending=%d" % (a.remaining_s, len(pending) - i)); aborted = True
            elif len(futs) < a.jobs and a.reserve_gb * (len(futs) + 1) <= a.max_rss_gb and \
                    mem_available_gb() - a.headroom_gb >= a.reserve_gb * (len(futs) + 1):
                t, att = pending[i]; i += 1
                futs[pool.submit(leaf, a, src, recs[t], att, res)] = (t, att)
                continue
        if not futs:
            if STOP or aborted: break
            time.sleep(0.2); continue
        fin, _ = wait(list(futs), timeout=0.5, return_when=FIRST_COMPLETED)
        for f in fin:
            t, att = futs.pop(f)
            try:
                v = f.result()
            except Exception as e:
                v = "RETRY_EXC"; log("EXC %s attempt %d: %r" % (t, att, e))
            if v.startswith("RETRY_") and att >= a.max_attempts:
                v = "FAIL_RESOURCE"
            if v.startswith("RETRY_") and not STOP and not aborted and att < a.max_attempts:
                pending.append((t, att + 1))
            done.write([t, v, att, ts()])
            counts[v] = counts.get(v, 0) + 1; n_done_now += 1
        if (STOP or aborted) and not futs:
            break
    pool.shutdown(wait=True)
    # final census from done.tsv (last word per tag)
    final = {}
    for ln in open(done_path):
        f = ln.rstrip("\n").split("\t")
        if len(f) >= 3: final[f[0]] = f[1]
    print_token(a, len(tags), sum(1 for t in tags if final.get(t) == "ACCEPT"),
                {k: v for k, v in counts.items()}, sum(1 for t in tags if not final.get(t) or final[t].startswith("RETRY_")),
                aborted, final, tags, time.time() - t_start, log)

def print_token(a, n, acc, counts, not_done, aborted, final=None, tags=None, elapsed=0, log=print):
    fails = {}
    for t in (tags or []):
        v = final.get(t, "NOT_DONE")
        if v.startswith("FAIL_"):
            fails[v] = fails.get(v, 0) + 1
    nf = sum(fails.values())
    status = "PASS" if (n > 0 and acc == n and nf == 0 and not_done == 0) else "FAIL"
    log("UNSAT_LEAN_FULL=%s run=%s leaves=%d verified=%d fails=%d not_done=%d fail_kinds=%s elapsed_s=%.0f abort_eval=%s" % (
        status, a.run_name, n, acc, nf, not_done, ",".join("%s:%d" % kv for kv in sorted(fails.items())) or "none",
        elapsed, aborted))

if __name__ == "__main__":
    main()
