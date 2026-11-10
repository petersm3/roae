#!/usr/bin/env python3
"""n10lean_run.py -- n=10 Lean pass over the 9,497 CPOG leaves of the certified n=10 run (K-43, Q-1103).

PARAMETRISES, does not fork, the n=12 runner: the per-leaf pipeline, verdict parser, scheduler, ledgers, cap and
2x abort rule are the code of `n12lean_run.py` (the runner that produced N12_LEAN_FULL=PASS 7085/7085; the copy
that ran had sha 36f31ead46b2bc18..., the shipped copy differs in docstring and comment lines only, and the pin
below is the shipped copy's sha), imported unmodified from this directory.  This file only
  * pins and imports that runner (refuses if its sha256 differs),
  * changes the defaults to the n=10 inputs (proofs.tsv sha 3f24d001..., source n10.cnf sha 271e80a6...),
  * names the token N10_LEAN_FULL (full CPOG census) / N10_LEAN_SUBSET (--tags), and defaults --expect-sum to
    123677568 for the full census,
  * replaces the runner's threading.Lock with an RLock (fixes a self-deadlock on the first in-run RETRY re-queue,
    see N10Runner.__init__), and on SIGTERM also signals every process in each in-flight tool chain's session
    (the pinned runner's killpg misses the tool, which GNU timeout moves to its own process group; see _on_sig),
  * keeps regenerated pieces under <tmpfs>/n10lean_<route> (the `where` column then reads n10lean_cpog),
  * adds --dry-cnf: step 1 only (regenerate every piece.cnf in memory with the runner's own tag_units/piece_text,
    compare with proofs.tsv col 4), no tools run -> N10_CNF_DRY=PASS|FAIL.
Every other option is the n=12 runner's (`python3 n10lean_run.py --help`); options given on the command line
override the n=10 defaults.

Token (last line of <out>/run.log):
  N10_LEAN_FULL=PASS|FAIL cpog_leaves=<n> accepted=<n> sum_count=<..> fails=<..> not_done=<n> elapsed_s=<..>
  abort_eval=<bool> cap_hit=<bool> signal=<n>
"""
import hashlib, os, signal, sys, threading, time

HERE = os.path.dirname(os.path.abspath(__file__))
N12_RUNNER_SHA = "ca84ba2ae2e1aa25cf7a0a9a5c895af9cc07cd9336b04294967410ba8271fd3b"
N10_EXPECT_SUM = 123677568
N10_CPOG_LEAVES = 9497


def _sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 22), b""):
            h.update(b)
    return h.hexdigest()


_rp = os.path.join(HERE, "n12lean_run.py")
if not os.path.exists(_rp) or _sha(_rp) != N12_RUNNER_SHA:
    raise SystemExit("REFUSE: %s missing or sha != %s (the runner of N12_LEAN_FULL=PASS)" % (_rp, N12_RUNNER_SHA))
sys.path.insert(0, HERE)
import n12lean_run as R  # noqa: E402


class N10Runner(R.Runner):
    def __init__(self, a):
        super().__init__(a)
        # FIX (found by a local dry run before the n=10 pass): in n12lean_run.py main(), the
        # in-run re-queue of a RETRY_* leaf calls self.log() -- which takes self.lock -- while already holding
        # self.lock (`with self.lock: ... self.log("REQUEUE ...")`).  threading.Lock is not re-entrant, so the first
        # in-run RETRY deadlocks the main thread for good (the SIGTERM handler only sets a flag, so the outer
        # `timeout` cannot get a token out either).  The n=12 pass never hit it (7,085/7,085 ACCEPT on attempt 1).
        # A re-entrant lock removes the self-deadlock without touching the pinned runner's logic.
        self.lock = threading.RLock()
        if self.tmp_root:                                   # n12lean_<route> -> n10lean_<route>
            old = self.tmp_root
            self.tmp_root = os.path.join(a.tmpfs, "n10lean_%s" % a.route.lower())
            os.makedirs(self.tmp_root, exist_ok=True)
            try:
                os.rmdir(old)                               # only if empty (it was just created by super)
            except OSError:
                pass

    def _on_sig(self, signum, frame):
        # FIX 2 (same dry run): on SIGTERM the pinned runner does os.killpg(<pid of `nice`>, 15), but GNU
        # `timeout` (third in the chain nice -> /usr/bin/time -> timeout -> prlimit -> tool) calls setpgid(0,0), so
        # the tool lives in timeout's own process group and survived the kill (observed: orphans re-parented to
        # pid 1, still running, still holding pieces/<tag>/lean.out open).  Every tool chain was started with
        # start_new_session=True, so its SESSION id is the `nice` pid: SIGTERM every process in those sessions --
        # now, and once a second afterwards (reaper thread, main()) for a chain that started during the handler;
        # and run_tool() refuses to start a new tool once a signal has been received.
        self.sig = signum
        self._kill_sessions()

    def _kill_sessions(self):
        sids = {v.get("pid") for v in list(self.inflight.values()) if v.get("pid")}
        if not sids:
            return
        for d in os.listdir("/proc"):
            if not d.isdigit():
                continue
            try:
                with open("/proc/%s/stat" % d) as f:
                    s = f.read()
                if int(s[s.rfind(")") + 2:].split()[3]) in sids:
                    os.kill(int(d), signal.SIGTERM)
            except (OSError, IndexError, ValueError):
                pass

    def run_tool(self, argv, cwd, timeout_s, as_bytes, stdout_path, time_path, tag):
        if self.sig:                       # no new tool after a signal: empty output + rc 143 -> RETRY_* verdict
            open(stdout_path, "wb").close()
            return 143, -1.0, -1
        return super().run_tool(argv, cwd, timeout_s, as_bytes, stdout_path, time_path, tag)

    def main(self):
        def reaper():
            while True:
                time.sleep(1)
                if self.sig:
                    self._kill_sessions()
        threading.Thread(target=reaper, daemon=True).start()
        return super().main()


def dry_cnf(a):
    """Step 1 of the runner for every selected leaf, no tools: regenerated piece.cnf sha == proofs.tsv col 4."""
    t0 = time.time()
    nvars, clauses = R.read_cnf(a.src)
    rows = R.Runner._load_proofs(type("X", (), {"a": a})())
    bad = []
    for t, r in rows.items():
        s = hashlib.sha256(R.piece_text(nvars, clauses, R.tag_units(t)).encode()).hexdigest()
        if s != r["cnf_sha"]:
            bad.append(t)
    tot_b = sum(r["bytes"] for r in rows.values())
    tok = ("N10_CNF_DRY=%s route=%s leaves=%d mismatch=%d sum_recorded_count=%d sum_bytes=%d src_sha=%s proofs_sha=%s "
           "elapsed_s=%.1f" % ("PASS" if not bad else "FAIL", a.route, len(rows), len(bad),
                               sum(r["count"] for r in rows.values()), tot_b, _sha(a.src), _sha(a.proofs),
                               time.time() - t0))
    print(tok, flush=True)
    if bad:
        print("N10_CNF_DRY mismatched tags (first 20): %s" % ",".join(bad[:20]), flush=True)
    return 0 if not bad else 1


def parse():
    H = os.path.expanduser("~")
    user = sys.argv[1:]
    dry = "--dry-cnf" in user
    user = [x for x in user if x != "--dry-cnf"]
    given = {x.split("=")[0] for x in user if x.startswith("--")}
    defaults = ["--proofs", H + "/n10lean/proofs.tsv", "--src", H + "/n10/n10.cnf"]
    if dry and "--out" not in given:
        defaults += ["--out", os.devnull]
    sys.argv = [sys.argv[0]] + defaults + user               # argparse: the later (user) value wins
    a = R.parse()
    if "--token" not in given:
        a.token = "N10_LEAN_FULL" if (a.tags is None and a.route == "CPOG") else "N10_LEAN_SUBSET"
    if "--expect-sum" not in given and a.tags is None and a.route == "CPOG":
        a.expect_sum = N10_EXPECT_SUM
    return a, dry


if __name__ == "__main__":
    a, dry = parse()
    if a.selftest:
        R.selftest(); sys.exit(0)
    if dry:
        sys.exit(dry_cnf(a))
    sys.exit(N10Runner(a).main())
