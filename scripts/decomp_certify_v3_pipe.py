#!/usr/bin/env python3
"""Adaptive (recursive) Shannon-decomposed CERTIFIED model counting, v3.

Extends the n9-validated v2 pipeline with recursion: a piece whose
d4/cpog pipeline exceeds a RAM budget (ulimit -v) or a wall budget is SPLIT
FURTHER instead of failing the run.  Splitting continues until every leaf's
whole pipeline fits the budget, so `parallelism = RAM / budget` by
construction.

Split primitives (both sound, chosen automatically):
  1. Clause split (preferred): pick the next unused clause C of the ORIGINAL
     formula, |C| >= 3, whose literals are pairwise excluded by binary clauses
     ALSO in the original formula.  count(P) = sum_l count(P & l) for l in C:
     exhaustiveness is witnessed by C being literally one of P's clauses,
     exclusivity by the binary clauses being literally P's clauses.  Both
     witnesses are SYNTACTIC (membership), checked at startup - no semantic
     trust.  (In this project's encodings these are the per-slot
     exactly-one(Y[s,.]) blocks, in file order.)
  2. Cube split (fallback when no unused witnessed clause remains): split on
     an unassigned variable; x / -x is exhaustive+exclusive tautologically.

Certification per LEAF (unchanged from v2, every gate hard):
  SAT piece  (route CPOG):  d4 -> cpog-gen (rc==0) -> cpog-check with
     FULL-PROOF SUCCESS string + count line, against the piece CNF.
  UNSAT piece (route DRAT0): cadical rc==20 + DRAT proof; drat-trim must
     print `s VERIFIED`.  Certified count 0.
Trusted base: cpog-check, PLUS drat-trim for count-0 pieces (the project's
trusted-base ruling of 2026-08-21).  Every leaf's route is recorded.

UNCERTIFIED mode (--uncertified, 2026-08-22, operator-authorised): leaf
counts are taken directly from d4's `s N` line with route D4ONLY - no CPOG,
no DRAT.  The total is an INDEPENDENT DERIVATION that still TRUSTS d4; it is
NOT a certified count and both the ledger routes and the result line say so.

Checkpoint/resume (eviction-safety, 2026-08-21): every terminal event is
appended to WORKDIR/ledger.tsv and fsync'd THE MOMENT it happens - LEAF lines
carry the piece's certified count + route, SPLIT lines record that a piece
was split (so resume does not re-attempt it).  On startup the ledger is
replayed: recorded leaves are not re-run, recorded splits re-expand without
re-attempting.  The final total is summed FROM THE LEDGER, not from memory.
An eviction therefore costs only the in-flight pieces.  A malformed ledger
line aborts the run (fail-closed).

Failure classification per attempt:
  SPLIT-RETRYABLE: d4 rc!=0 / timeout / no count line; cadical timeout;
     cpog-gen rc!=0 (memory/disk/timeout kill) ; projected CPOG > disk gate.
  FATAL (soundness alarm, run aborts, NO total claimed): cpog-gen rc==0 but
     cpog-check lacks FULL-PROOF SUCCESS, or certified != d4 count.

2026-11-05 (Q-1051 Phase A, Fable's pre-publication items P3/P4 and Q-1055; Fable
claude-fable-5-1).  Five changes, each red-tested before the n=12 run:
  P3.1 BOUNDED CAPTURE.  run() no longer holds a tool's whole stdout in memory
     (Q-424 defect b: cpog-check prints two `Looking for clause` lines per
     clause lookup, 7.7 GB at n=9, and the capture OOM-killed a 15 GiB box).
     The merged stdout+stderr stream is read in 1 MiB chunks; only the last
     TAIL_BYTES are kept, and the markers in STREAM_MARKERS are also watched
     over the WHOLE stream, so an `ERROR.` printed early and buried under
     later output is still seen (a rejection must never be reclassified as
     "killed/incomplete" because its line scrolled out of the tail).
  P3.2 PER-PIECE TAILS KEPT.  Each stage's tail is written to
     WORKDIR/<tag>/{d4,cad,dt,gen,chk}.tail and is NOT deleted without --keep,
     so the per-leaf verdict lines (FULL-PROOF SUCCESS / Regular model count /
     s VERIFIED) can be grepped after the proofs are gone.
  P3.3 proofs.tsv.  One fsync'd line per LEAF, written by the main thread
     immediately BEFORE the ledger LEAF line:
       <tag> <route> <count> <sha256 piece.cnf> <sha256 proof> <proof bytes> <check wall s>
     (proof = piece.cpog for CPOG, piece.drat for DRAT0).  It identifies each
     certificate once its bytes are deleted, as SAT_CLI.md identifies n=9's.
  P4.1 CNF BINDING.  WORKDIR/source.sha256 holds the sha256 of the source CNF;
     a resume against a different CNF dies before touching the ledger.
  P4.2 SPLIT WITNESS IN THE LEDGER.  SPLIT rows are `SPLIT <tag> <how> -` with
     how = clause#N (1-based index into the source clauses) or cube-varV; on
     resume the regenerated witness must equal the recorded one (die if not).
     scripts/n12_partition_all.py regenerates every parent/child pair from the
     ledger and runs scripts/q424_partition_check.py on each split.
  Also: --bin DIR (or $SATCERT_BIN) replaces the hardcoded ~/satcert/bin (the
     n=12 run's toolchain lived in ~/tools/bin); the
     run log opens with DRIVER_SHA256=, SOURCE_SHA256= and one TOOL_SHA256 line
     per binary, so a log is self-identifying against the pinned toolchain.
"""
import argparse, hashlib, os, re, select, subprocess, sys, time

BIN = os.path.expanduser(os.environ.get("SATCERT_BIN", "~/satcert/bin"))

TAIL_BYTES = 65536                  # ~900 lines of cpog-check chatter; Q-424's chk.tail was 40
CHUNK = 1 << 20
STREAM_MARKERS = (b"FULL-PROOF SUCCESS", b"ERROR.", b"bad_alloc", b"Killed", b"s VERIFIED")
TOOLS = ("d4", "cpog-gen", "cpog-check", "cadical", "drat-trim")


def die(msg):
    print("FATAL: " + msg)
    sys.exit(2)


def sha256_file(path, bufsize=1 << 20):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            b = f.read(bufsize)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def fsync_append(path, line):
    """Durable one-line append: write, flush, fsync before returning."""
    with open(path, "a") as f:
        f.write(line)
        f.flush()
        os.fsync(f.fileno())


def ledger_append(path, kind, tag, route="-", count="-"):
    """Durable one-line checkpoint; called the moment a piece reaches a
    terminal state (LEAF = certified, SPLIT = expanded).  fsync before
    returning so an eviction can lose only in-flight pieces.  For SPLIT rows
    the third column carries the witness (clause#N / cube-varV)."""
    fsync_append(path, "%s\t%s\t%s\t%s\n" % (kind, tag, route, count))


def proofs_append(path, tag, route, count, cnf_sha, proof_sha, proof_bytes, check_wall):
    fsync_append(path, "%s\t%s\t%d\t%s\t%s\t%d\t%.1f\n"
                 % (tag, route, count, cnf_sha, proof_sha, proof_bytes, check_wall))


def ledger_load(path):
    """Replay the ledger.  Returns (leaves {tag: (route, count)},
    splits {tag: how}).  Malformed lines abort - a half-trusted checkpoint is
    worse than a restart."""
    leaves, splits = {}, {}
    if not os.path.exists(path):
        return leaves, splits
    for ln, line in enumerate(open(path), 1):
        parts = line.rstrip("\n").split("\t")
        if len(parts) != 4 or parts[0] not in ("LEAF", "SPLIT"):
            die("ledger %s line %d malformed: %r" % (path, ln, line))
        kind, tag, route, count = parts
        if kind == "LEAF":
            if route not in ("CPOG", "DRAT0", "D4ONLY") or not count.isdigit():
                die("ledger %s line %d malformed LEAF: %r" % (path, ln, line))
            leaves[tag] = (route, int(count))
        else:
            splits[tag] = route            # the witness: clause#N / cube-varV / "-" (pre-P4 ledgers)
    return leaves, splits


def units_tag(units):
    return "p" + ("_".join(str(u).replace("-", "m") for u in units) or "root")


def read_cnf(p):
    header, clauses = None, []
    for line in open(p):
        if line.startswith("p cnf"):
            header = line.split(); continue
        if line[:1] == "c" or not line.strip():
            continue
        clauses.append([int(t) for t in line.split()[:-1]])
    if header is None or len(clauses) != int(header[3]):
        die("CNF parse mismatch in %s" % p)
    return int(header[2]), clauses


def witnessed_xo_clauses(clauses):
    """Clauses |C|>=3 whose literal pairs are all excluded by binary clauses
    of the formula (syntactic witnesses), in file order."""
    bins = set()
    for c in clauses:
        if len(c) == 2:
            bins.add(frozenset(c))
    out = []
    for idx, c in enumerate(clauses):
        if len(c) < 3:
            continue
        if all(frozenset((-a, -b)) in bins
               for i, a in enumerate(c) for b in c[i + 1:]):
            out.append((idx, list(c)))
    return out


def run(argv, timeout, vcap_kb, cwd, tail_path=None):
    """Run one tool under /usr/bin/time + timeout + prlimit, streaming its
    merged stdout/stderr.  Returns (rc, tail_text, rss_kb, wall_s, seen) where
    tail_text is the decoded last TAIL_BYTES of the stream (first partial line
    dropped when truncated) and seen is the set of STREAM_MARKERS observed
    anywhere in the stream.  Memory held: O(TAIL_BYTES + CHUNK), never O(stream).

    prlimit (util-linux) applies RLIMIT_AS to the tool without preexec_fn,
    which is documented thread-unsafe - this runner executes from a
    ThreadPoolExecutor (2026-08-22 fix: the fork-based process pool left
    orphaned workers parked in futex_do_wait when the driver was killed,
    and fork start-method + management threads risks inherited-lock hangs)."""
    tool = os.path.basename(argv[0])
    argv = ["/usr/bin/time", "-f", "TIMERSSKB=%M",
            "timeout", "-k", "30", str(int(timeout)),
            "prlimit", "--as=%d" % (vcap_kb * 1024)] + argv
    t0 = time.time()
    deadline = t0 + timeout + 90
    seen, total, tail = set(), 0, b""
    keep = max(len(m) for m in STREAM_MARKERS) - 1
    try:
        p = subprocess.Popen(argv, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             stdin=subprocess.DEVNULL, cwd=cwd)
    except OSError as e:
        return -98, "[spawn failed: %s]" % e, -1, time.time() - t0, seen
    # 2026-11-08 (n=10 run): cpog-check prints one unconditional "Looking for clause" line per
    # clause lookup (cpog-check.c:692,707; ~12 bytes of text per proof byte, not gated by -v).  Reading that
    # through this Python loop capped 28 concurrent checks at ~5 % CPU each on the n=10 host.  Drop those lines in
    # a C-speed filter per tool.  No STREAM_MARKER and no verdict line ("CHECK: ...", "TIMERSSKB=") can occur
    # on a dropped line; rc is still the tool's own (p.wait()).  Other tools are read exactly as before.
    flt = None
    if tool == "cpog-check":
        flt = subprocess.Popen(["grep", "-a", "-v", "^Looking for clause"],
                               stdin=p.stdout, stdout=subprocess.PIPE)
        p.stdout.close()                 # grep holds the only read end now; EOF reaches it when the tool exits
    fd = (flt.stdout if flt is not None else p.stdout).fileno()
    outer_timeout = False
    while True:
        remaining = deadline - time.time()
        if remaining <= 0:
            outer_timeout = True
            break
        r, _, _ = select.select([fd], [], [], remaining)
        if not r:
            outer_timeout = True
            break
        chunk = os.read(fd, CHUNK)
        if not chunk:
            break
        total += len(chunk)
        window = tail[-keep:] + chunk
        for m in STREAM_MARKERS:
            if m not in seen and m in window:
                seen.add(m)
        tail = (tail + chunk)[-TAIL_BYTES:]
    if outer_timeout:
        try:
            p.kill()
        except OSError:
            pass
    if flt is not None:
        flt.stdout.close()
        if outer_timeout:
            try:
                flt.kill()
            except OSError:
                pass
        flt.wait()
    p.stdout.close()
    rc = p.wait()
    if outer_timeout:
        rc = -99
        tail += b"\n[outer timeout]\n"
    if total > TAIL_BYTES:
        nl = tail.find(b"\n")
        if nl >= 0:
            tail = tail[nl + 1:]
    out = tail.decode("utf-8", "replace")
    if tail_path is not None:
        try:
            with open(tail_path, "wb") as f:
                f.write(("[stream bytes=%d rc=%d markers=%s]\n"
                         % (total, rc, ",".join(sorted(m.decode() for m in seen)))).encode())
                f.write(tail)
        except OSError:
            pass
    m = re.findall(r"TIMERSSKB=(\d+)", out)
    return rc, out, (int(m[-1]) if m else -1), time.time() - t0, seen


def attempt_piece(src_clauses, nvars, units, workdir, timeout, vcap_kb,
                  disk_gate_mb, keep, uncertified=False):
    """Try to certify piece = original clauses + unit(units).
    Returns dict with status in {OK, OK-UNSAT, SPLIT, FATAL}."""
    tag = units_tag(units)
    d = os.path.join(workdir, tag)
    os.makedirs(d, exist_ok=True)
    # 2026-11-08 (n=10 run): if SATCERT_PIECE_TMP is set, the piece files (cnf/nnf/cpog/drat) are
    # written under that directory (a tmpfs on the n=10 host, whose 200 MB/s disk was saturated by concurrent
    # cpog-gen writers); the *.tail files, ledger.tsv and proofs.tsv stay in workdir exactly as before.
    pd = os.path.join(os.environ["SATCERT_PIECE_TMP"], tag) if os.environ.get("SATCERT_PIECE_TMP") else d
    os.makedirs(pd, exist_ok=True)
    cnf = os.path.join(pd, "piece.cnf")
    nnf, cpog, drat = (os.path.join(pd, "piece." + e) for e in ("nnf", "cpog", "drat"))
    tails = {s: os.path.join(d, s + ".tail") for s in ("d4", "cad", "dt", "gen", "chk")}
    with open(cnf, "w") as f:
        f.write("p cnf %d %d\n" % (nvars, len(src_clauses) + len(units)))
        for c in src_clauses:
            f.write(" ".join(map(str, c)) + " 0\n")
        for u in units:
            f.write("%d 0\n" % u)
    res = {"tag": tag, "units": units, "count": None, "route": "-",
           "status": "SPLIT", "why": "", "rss_kb": -1, "cpog_bytes": 0,
           "wall_s": 0.0, "cpu_s": 0.0,
           "cnf_sha": None, "proof_sha": None, "proof_bytes": 0, "check_wall": 0.0}
    t0 = time.time()
    try:
        res["cnf_sha"] = sha256_file(cnf)
        rc, out, rss, w, seen = run([os.path.join(BIN, "d4"), "-dDNNF", cnf,
                                     "-out=" + nnf], timeout, vcap_kb, d, tails["d4"])
        res["rss_kb"] = max(res["rss_kb"], rss)
        m = re.findall(r"(?m)^s (\d+)\s*$", out)
        if rc != 0 or not m:
            res["why"] = "d4 rc=%d" % rc
            return res                                   # SPLIT
        d4_count = int(m[-1])
        if uncertified:
            # operator-authorised d4-only mode: trust d4, no proof stage
            res.update(count=d4_count, status="OK", route="D4ONLY")
            return res
        if d4_count == 0:
            rc, out, rss, w, seen = run([os.path.join(BIN, "cadical"), "--no-binary",
                                         "--unsat", "-q", cnf, drat],
                                        timeout, vcap_kb, d, tails["cad"])
            res["rss_kb"] = max(res["rss_kb"], rss)
            if rc != 20:
                res["why"] = "cadical rc=%d" % rc
                return res                               # SPLIT
            rc, out, rss, w, seen = run([os.path.join(BIN, "drat-trim"), cnf, drat],
                                        timeout, vcap_kb, d, tails["dt"])
            res["rss_kb"] = max(res["rss_kb"], rss)
            # whole-line verdict (drat-trim prefixes lines with a bare CR on some builds)
            if not any(ln.strip("\r") == "s VERIFIED" for ln in out.split("\n")):
                res["why"] = "drat-trim not VERIFIED (rc=%d)" % rc
                return res                               # SPLIT (retry deeper)
            res.update(proof_sha=sha256_file(drat), proof_bytes=os.path.getsize(drat),
                       check_wall=w)
            res.update(count=0, status="OK-UNSAT", route="DRAT0")
            return res
        # disk gate before cpog-gen (measured 759-894 bytes CPOG per nnf byte)
        proj_mb = os.path.getsize(nnf) * 900 / 1e6
        if proj_mb > disk_gate_mb:
            res["why"] = "CPOG projection %.0fMB > disk gate %dMB" % (proj_mb, disk_gate_mb)
            return res                                   # SPLIT
        rc, out, rss, w, seen = run([os.path.join(BIN, "cpog-gen"), cnf, nnf, cpog],
                                    timeout, vcap_kb, d, tails["gen"])
        res["rss_kb"] = max(res["rss_kb"], rss)
        if rc != 0 or not os.path.exists(cpog):
            res["why"] = "cpog-gen rc=%d" % rc
            return res                                   # SPLIT
        res["cpog_bytes"] = os.path.getsize(cpog)
        rc, out, rss, w, seen = run([os.path.join(BIN, "cpog-check"), cnf, cpog],
                                    timeout, vcap_kb, d, tails["chk"])
        res["rss_kb"] = max(res["rss_kb"], rss)
        # verdict = a WHOLE line that begins with the token (sat.py's rule since 2026-10-29)
        full = any(re.match(r"(?:CHECK: )?FULL-PROOF SUCCESS\b", ln.rstrip("\r"))
                   for ln in out.split("\n"))
        if not full:
            # A checker VERDICT (ERROR. line, rc 0/1, no kill signature) is a
            # soundness alarm; a resource kill (timeout/OOM) is retryable by
            # splitting deeper.  `seen` covers the WHOLE stream, `out` the tail.
            killed = rc in (124, 137, -9, -99) or rc >= 128 or \
                     b"bad_alloc" in seen or b"Killed" in seen
            if not killed and rc in (0, 1) and (b"ERROR." in seen):
                res.update(status="FATAL",
                           why="cpog-check REJECTED the proof: "
                               + out[-200:].replace("\n", " | "))
                return res
            res["why"] = "cpog-check killed/incomplete rc=%d" % rc
            return res                                   # SPLIT
        m = re.findall(r"(?m)^CHECK: Regular model count = (\d+)\s*$", out)
        if not m:
            res.update(status="FATAL", why="FULL-PROOF but no count line")
            return res
        certified = int(m[-1])
        if certified != d4_count:
            res.update(status="FATAL",
                       why="certified %d != d4 %d" % (certified, d4_count))
            return res
        res.update(proof_sha=sha256_file(cpog), proof_bytes=res["cpog_bytes"], check_wall=w)
        res.update(count=certified, status="OK", route="CPOG")
        return res
    finally:
        res["wall_s"] = time.time() - t0
        res["cpu_s"] = res["wall_s"]   # single-threaded stages, sequential
        if not keep:
            for f in (nnf, cpog, drat, cnf):           # the *.tail files stay
                if os.path.exists(f):
                    try:
                        os.remove(f)
                    except OSError:
                        pass
            if pd != d:                                # tmpfs piece dir: leave nothing behind
                try:
                    os.rmdir(pd)
                except OSError:
                    pass


def main():
    global BIN
    ap = argparse.ArgumentParser()
    ap.add_argument("cnf")
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--workdir", default="decomp_v3_work")
    ap.add_argument("--expect", type=int)
    ap.add_argument("--vcap-kb", type=int, required=True,
                    help="RAM budget per piece; parallelism = RAM/budget")
    ap.add_argument("--timeout", type=int, default=3600,
                    help="wall budget per tool invocation per piece")
    ap.add_argument("--disk-gate-mb", type=int, default=50000)
    ap.add_argument("--force-split-depth", type=int, default=0,
                    help="split pieces above this depth without attempting "
                         "(recursion-machinery validation)")
    ap.add_argument("--max-pieces", type=int, default=200000)
    ap.add_argument("--keep", action="store_true")
    ap.add_argument("--bin", default=BIN,
                    help="directory holding d4, cpog-gen, cpog-check, cadical, drat-trim "
                         "(default $SATCERT_BIN or ~/satcert/bin)")
    ap.add_argument("--uncertified", action="store_true",
                    help="d4-only counts (route D4ONLY): independent "
                         "derivation that TRUSTS d4; NOT a certified count")
    a = ap.parse_args()
    a.workdir = os.path.abspath(a.workdir)
    a.cnf = os.path.abspath(a.cnf)
    BIN = os.path.abspath(os.path.expanduser(a.bin))
    os.environ["PATH"] = BIN + os.pathsep + os.environ.get("PATH", "")
    os.makedirs(a.workdir, exist_ok=True)

    print("DRIVER_SHA256=%s %s" % (sha256_file(os.path.abspath(__file__)), os.path.abspath(__file__)))
    for b in TOOLS:
        p = os.path.join(BIN, b)
        if not os.access(p, os.X_OK):
            die("missing binary " + b)
        print("TOOL_SHA256 %s=%s %s" % (b, sha256_file(p), os.path.realpath(p)))
    # P4.1: bind the workdir (ledger, proofs) to this exact CNF
    src_sha = sha256_file(a.cnf)
    bind = os.path.join(a.workdir, "source.sha256")
    if os.path.exists(bind):
        prev = open(bind).read().split()[0]
        if prev != src_sha:
            die("ledger belongs to a different CNF: %s has %s, %s is %s"
                % (bind, prev, a.cnf, src_sha))
    else:
        fsync_append(bind, "%s  %s\n" % (src_sha, os.path.basename(a.cnf)))
    print("SOURCE_SHA256=%s %s" % (src_sha, a.cnf))
    nvars, clauses = read_cnf(a.cnf)
    xo = witnessed_xo_clauses(clauses)
    print("source=%s vars=%d clauses=%d witnessed-xo-clauses=%d jobs=%d "
          "vcap_kb=%d timeout=%d force_split_depth=%d bin=%s"
          % (a.cnf, nvars, len(clauses), len(xo), a.jobs, a.vcap_kb,
             a.timeout, a.force_split_depth, BIN))

    def children(units, depth):
        """Split piece `units`: next unused witnessed clause, else cube."""
        used_vars = {abs(u) for u in units}
        for idx, lits in xo:
            if not any(abs(l) in used_vars for l in lits):
                return [units + (l,) for l in lits], "clause#%d" % (idx + 1)
        for v in range(1, nvars + 1):          # cube fallback
            if v not in used_vars:
                return [units + (v,), units + (-v,)], "cube-var%d" % v
        die("piece %s cannot be split further" % (units,))

    ledger = os.path.join(a.workdir, "ledger.tsv")
    proofs = os.path.join(a.workdir, "proofs.tsv")
    done_leaves, done_splits = ledger_load(ledger)
    if done_leaves or done_splits:
        print("RESUME: ledger has %d certified leaves, %d recorded splits"
              % (len(done_leaves), len(done_splits)))

    from concurrent.futures import ThreadPoolExecutor
    t0 = time.time()
    leaves, frontier, depth, total_attempted, resumed = [], [()], 0, 0, 0
    split_reasons = {}

    def record_leaf(r):
        if r["route"] in ("CPOG", "DRAT0"):
            proofs_append(proofs, r["tag"], r["route"], r["count"], r["cnf_sha"],
                          r["proof_sha"], r["proof_bytes"], r["check_wall"])
        ledger_append(ledger, "LEAF", r["tag"], r["route"], str(r["count"]))

    with ThreadPoolExecutor(max_workers=a.jobs) as ex:
        while frontier:
            nxt, attempt_now = [], []
            for u in frontier:
                tg = units_tag(u)
                if tg in done_leaves:
                    route, cnt = done_leaves[tg]
                    leaves.append((depth, {"tag": tg, "units": u, "count": cnt,
                                           "route": route, "status": "OK(resumed)",
                                           "why": "", "rss_kb": -1,
                                           "cpog_bytes": 0, "wall_s": 0.0,
                                           "cpu_s": 0.0}))
                    resumed += 1
                elif tg in done_splits:
                    ch, how = children(u, depth)
                    if done_splits[tg] not in ("-", how):
                        die("ledger SPLIT %s recorded witness %s, regenerated %s"
                            % (tg, done_splits[tg], how))
                    nxt.extend(ch)
                    resumed += 1
                else:
                    attempt_now.append(u)
            if a.force_split_depth > depth:
                for u in attempt_now:
                    ch, how = children(u, depth)
                    print("depth %d: force-split %s via %s -> %d children"
                          % (depth, u or "(root)", how, len(ch)))
                    ledger_append(ledger, "SPLIT", units_tag(u), how)
                    nxt.extend(ch)
            else:
              chunks = [attempt_now[i:i + a.jobs * 40]
                        for i in range(0, len(attempt_now), a.jobs * 40)]
              for chunk in chunks:
                futs = {ex.submit(attempt_piece, clauses, nvars, u, a.workdir,
                                  a.timeout, a.vcap_kb, a.disk_gate_mb,
                                  a.keep, a.uncertified): u for u in chunk}
                for fu, u in futs.items():
                    r = fu.result()
                    total_attempted += 1
                    if r["status"] == "FATAL":
                        print("FATAL piece %s: %s" % (r["tag"], r["why"]))
                        print("DECOMP_RESULT=FAIL (soundness alarm; no total claimed)")
                        sys.exit(1)
                    if r["status"] == "SPLIT":
                        ch, how = children(u, depth)
                        print("depth %d: %s needs split (%s) via %s -> %d children"
                              % (depth, r["tag"], r["why"], how, len(ch)))
                        key = re.sub(r"\d+", "N", r["why"])
                        split_reasons[key] = split_reasons.get(key, 0) + 1
                        ledger_append(ledger, "SPLIT", r["tag"], how)
                        nxt.extend(ch)
                    else:
                        record_leaf(r)
                        leaves.append((depth, r))
                        print("depth %d: %s %s route=%s count=%d rss=%.1fMB proof=%dB %.1fs"
                              % (depth, r["tag"], r["status"], r["route"], r["count"],
                                 r["rss_kb"] / 1024.0, r["proof_bytes"], r["wall_s"]),
                              flush=True)
            if len(nxt) + len(leaves) > a.max_pieces:
                die("piece budget exceeded (%d)" % a.max_pieces)
            frontier, depth = nxt, depth + 1
    wall = time.time() - t0
    if resumed:
        print("RESUMED_PIECES=%d (not re-run)" % resumed)

    n_cpog = sum(1 for _, r in leaves if r["route"] == "CPOG")
    n_drat = sum(1 for _, r in leaves if r["route"] == "DRAT0")
    n_d4o = sum(1 for _, r in leaves if r["route"] == "D4ONLY")
    for dpt, r in (sorted(leaves, key=lambda x: x[1]["tag"])
                   if len(leaves) <= 10000 else []):
        print("  d%-2d %-28s %-8s route=%-5s count=%-14s rss=%9.1fMB "
              "cpog=%9.1fMB %8.1fs"
              % (dpt, r["tag"], r["status"], r["route"], r["count"],
                 r["rss_kb"] / 1024.0, r["cpog_bytes"] / 1e6, r["wall_s"]))
    print("LEAVES=%d (CPOG=%d DRAT0=%d D4ONLY=%d) ATTEMPTS=%d"
          % (len(leaves), n_cpog, n_drat, n_d4o, total_attempted))
    print("SPLIT_REASONS=%s" % ("; ".join("%s x%d" % kv for kv in sorted(split_reasons.items())) or "none"))
    print("PEAK_PIECE_RSS_MB=%.1f" % (max(r["rss_kb"] for _, r in leaves) / 1024.0))
    print("PEAK_PIECE_CPOG_MB=%.1f" % (max(r["cpog_bytes"] for _, r in leaves) / 1e6))
    print("SUM_PIECE_CPU_S=%.1f" % sum(r["cpu_s"] for _, r in leaves))
    print("WALL_S=%.1f" % wall)
    led_leaves, _ = ledger_load(ledger)          # sum from the LEDGER (durable)
    tot = sum(cnt for _, cnt in led_leaves.values())
    mem_tot = sum(r["count"] for _, r in leaves)
    if tot != mem_tot or len(led_leaves) != len(leaves):
        print("DECOMP_RESULT=FAIL (ledger/memory mismatch: %d/%d leaves, %d vs %d)"
              % (len(led_leaves), len(leaves), tot, mem_tot))
        sys.exit(1)
    print("DECOMP_TOTAL=%d" % tot)
    if a.expect is not None:
        if tot != a.expect:
            print("DECOMP_RESULT=FAIL (total %d != expected %d)" % (tot, a.expect))
            sys.exit(1)
        lbl = "UNCERTIFIED-d4only" if a.uncertified else "certified"
        print("DECOMP_RESULT=PASS (%s total matches expected %d)" % (lbl, a.expect))
    else:
        print("DECOMP_RESULT=%s_TOTAL_NO_EXPECT"
              % ("UNCERTIFIED_D4ONLY" if a.uncertified else "CERTIFIED"))


if __name__ == "__main__":
    main()
