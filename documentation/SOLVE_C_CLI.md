# solve(1) — King Wen sequence enumerator and verifier

> **CLI references:** this documents the **`solve` C binary** (compiled from `solve.c`). See also [`solve.py`](SOLVE_PY_CLI.md) (analysis + ground truth) · [`roae.py`](ROAE_PY_CLI.md) (descriptive analyses) · [`sat.py`](SAT_CLI.md) (SAT / certificate layer).

A man-page-style command-line reference for the `solve` binary compiled
from `solve.c`. Covers the subcommands, environment variables,
exit codes, and common workflows. The SYNOPSIS below lists the principal
forms; every subcommand also has its own section under SUBCOMMANDS below.

## NAME

**solve** — multi-threaded enumerator, verifier, merger, and analyzer
for orderings of the 64 hexagrams satisfying the King Wen constraint
specification (see [SPECIFICATION.md](SPECIFICATION.md)).

## SYNOPSIS

```
solve [time_limit] [threads]                            # default: full enumeration
solve --selftest                                        # regression check (~5 sec)
solve --selftest-resume                                 # checkpoint/resume byte-exactness gate
solve --verify [solutions.bin]                          # constraint check on solutions.bin
solve --merge                                           # combine sub_*.bin shards in CWD
solve --merge-layers <root>                             # merge across layered enumerations
solve --analyze [solutions.bin]                         # statistics across solution set
solve --validate [solutions.bin]                        # full integrity check (sort, dedup, KW present, C1-C5)
solve --show [N] [--mode M] [--format F] [--from FILE]  # visual sample of records
solve --branch <p1> <o1> [time_limit] [threads]         # single first-level branch
solve --sub-branch <p1> <o1> <p2> <o2> <p3> <o3> [time_limit] [threads]
                                                        # depth-3 sub-branch only
solve --list-branches                                   # 56 valid first-level (p,o) pairs
solve --c3-min                                          # complement-distance minimum search
solve --yield-report < log                              # per-sub-branch yield analysis from stdin log
solve --symmetry-search                                 # group-theoretic symmetry hunt
solve --null-<family>                                   # null-model comparison families
solve --prove-cascade | --prove-self-comp | --prove-shift
                                                        # symbolic proofs
solve --regression-test [scope]                         # canonical-sha regression matrix
solve --double-regression-test [base]                   # full-enum vs 56-branch sha equivalence
solve --kde-score-stream --fit-file PATH --d N --bandwidth BW --threshold T
                                                        # streaming KDE scorer
solve --emit-shard-manifest [dir]                       # write shard_manifest.txt for sub_*.bin in dir
solve --verify-shard-manifest [dir]                     # check shard_manifest.txt vs current shards
solve --compare-provenance A.json B.json                # assert two solutions.provenance.json are equivalent
solve.py --extended-selftest <solve>                    # 9-subtest harness (solve.py command, NOT a solve C subcommand)
solve --preflight [node_limit]                          # run in-process gates (no enum)
solve --disk-precheck <mount> [gb] [uuid]               # capacity/writability/identity check
solve --print-config                                    # dump build provenance + SOLVE_* env values
solve --canonical-config <SCALE> [--full]               # emit env vars to reproduce a canonical sha
solve --validate-launcher-config <SCALE> <PSB>          # assert launcher PSB matches canonical recipe
solve --verify-rule2 [solutions.bin]                    # McKenna Rule-2 audit
solve --verify-9th-six [solutions.bin]                  # 9th-six between-pair value-6 audit
solve --verify-wrap-parity [solutions.bin]              # wrap-around parity tabulation
solve --f4p-verify | --f5-verify | --f6-verify | --dav-verify | --dav2-verify | --db1-verify
                                                        # two-language functional-battery gates
solve --rc4b-verify [SEQ]                               # R13 HEC two-convention parity gate (KW anchors)
solve --rc1c-verify [SEQ]                               # R6 circular anchor-adjacency (R-C1c) gate (KW A2={21,42})
solve --r11-verify [SEQ]                                # R11 frozen 8-axis violation-bundle gate (KW 2,2,2,0,0,0,0,0)
solve --validate-canonical <sha256> <scale>             # pre-campaign drift gate
solve --estimate-knuth <N> [<p1> <o1> ...]              # Knuth random-probe tree-size estimator
solve --knuth-dump-prefix <depth> <seed>                # dev utility: emit a random VALID deep prefix
solve --c3-dist [solutions.bin]                         # C3 complement-distance histogram
solve --f1-exact-c1c2c4 [--layers-dir DIR]              # exact |C1∩C2∩C4| orbit DP
solve --f1-exact-c1c2c4c5 [--f1-pairs N] [--f1-out-of-core DIR]
                                                        # exact |C1∩C2∩C4∩C5| orbit DP
solve --f1c5-gzip-selftest | --f1c5-verify-layer <v1> <v2>
                                                        # f1c5 layer-codec self-test / cross-check
solve --cpu-features | --cpu-freq [MHZ]                 # ISA / throttle diagnostics
```

## DESCRIPTION

`solve` is a single-binary command-line tool that performs all of the
following on the C1–C5 constraint specification (see
[SPECIFICATION.md](SPECIFICATION.md)):

- Enumerates orderings of 64 hexagrams satisfying C1–C5, writing
  results as a sorted, deduplicated 32-byte-per-record canonical
  binary file `solutions.bin` (format described in
  [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md)).
- Verifies an existing `solutions.bin` against the constraint
  specification independently of the enumeration code path
  (`--verify`).
- Merges multiple shard files (`sub_*.bin`) into a single sorted
  deduplicated solutions.bin (`--merge`).
- Computes statistics across the solution set (`--analyze`).
- Performs symbolic proofs of theorems about the constraint system
  (`--prove-*`).
- Compares the King Wen sequence to null-model families (`--null-*`).
- Generates the canonical sha256 anchors recorded in
  [CANONICAL_HASHES.md](CANONICAL_HASHES.md).

The default action (no subcommand) is **full enumeration**: walk the
constraint search tree exhaustively (or up to a node budget) and write
the resulting sorted-deduplicated solutions.bin in the current
directory, accompanied by a sha256 file and a metadata JSON. This is
the action that produces the canonical artifacts (e.g.,
`915abf30…` at d3 100T scale).

## SUBCOMMANDS

### (default — no subcommand)

```
solve [time_limit] [threads]
```

Run a full multi-threaded enumeration. Writes `solutions.bin`,
`solutions.sha256`, and `solutions.meta.json` to CWD. With
`SOLVE_DFS_CHECKPOINT=1` (recommended), also writes per-sub-branch
`.dfs_state` sidecar files and a `checkpoint.txt` so the run can
resume after interrupt or eviction.

- `time_limit` — wall-clock seconds; `0` means run to completion.
  Default 0.
- `threads` — number of pthreads to use. Default `min(128, nproc)`.

Output sha matches a canonical entry in
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) iff inputs (env vars +
solver version) match. Mismatch is a bug, not a new result.

Wall time scales with `SOLVE_NODE_LIMIT / threads`; see
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) for budget-to-wall
mappings.

### --selftest

```
solve --selftest
```

Regression test — forks a child running a fixed-budget tiny
enumeration scenario (`SOLVE_THREADS=4`, `SOLVE_NODE_LIMIT=100000000`,
default depth-2). Computes the resulting `solutions.bin` sha256 and
compares it to the canonical baseline `403f7202…`. Prints PASS or
FAIL.

Runs in ~5 seconds. Every commit to solve.c MUST preserve this sha;
divergence is a regression.

Exits 0 on PASS, 1 on FAIL.

### --selftest-resume

```
solve --selftest-resume
```

Resume-correctness gate (distinct from `--selftest`). Runs a fixed-budget
enumeration, interrupts and resumes it from the `.dfs_state` checkpoint,
and confirms the resumed run produces the same `solutions.bin` sha as an
uninterrupted run — i.e. that mid-walk checkpoint/resume is byte-exact.
Guards the budget-upgrade-resume / asymmetric-extension code path that
canonical extensions (e.g. 560T → 1120T) and eviction recovery rely on.

Any commit touching the checkpoint format or resume logic MUST keep this
passing (see the checkpoint-format merge gate). Exits 0 on PASS, non-zero
on FAIL.

### --validate-canonical

```
solve --validate-canonical <expected-sha256> <scale>
```

Pre-campaign drift-detection gate (task #110). `<scale>` ∈ {`1T`,
`11.2T`, `100T`} (alternate forms `1`, `11`, `100`). Runs a fresh
canonical enum at the requested scale in a temp dir with the canonical
env vars, sha256s the resulting `solutions.bin`, and compares to
`<expected-sha256>`. The cheapest way to catch host-environment drift
(gcc/glibc/kernel/CPU-microcode patch deltas) BEFORE committing a
$100+ campaign. Prints the host fingerprint on mismatch.

Recommended pre-560T: `solve --validate-canonical 0c0fe37c… 11.2T`
(the drift-robust anchor). Exits **0** match / **33** mismatch /
**2** usage error / **10** infra error / **40** enum error.

### --preflight

```
solve --preflight [node_limit]          # default node_limit = 560T
```

In-process pre-flight aggregator (2026-05-28). Runs every gate solve.c
can check from inside its own process — auto-selftest (sha
`403f7202…`), disk-space projection, disk-IOPS probe — in report mode,
**without running the enum**. One command to confirm a campaign VM is
ready. Run it FROM the campaign run-dir (the gates check the cwd).

Does NOT cover what lives outside the process: VM/eviction/cost (the
external monitor, task #55), full disk SMART/fsck
(`scripts`-side `disk_health_precheck.sh`), or disk identity (use
`--disk-precheck`). Exits **0** if all gates pass, else the first
failing gate's exit code (24 / 29 / 31).

### --disk-precheck

```
solve --disk-precheck <mountpoint> [required_gb] [expected_uuid]
```

Native local disk pre-check (2026-05-28) — the in-binary subset of
`disk_health_precheck.sh`: capacity (`statvfs`), writability
(write+fsync+read smoke test), and identity (marker file +
filesystem UUID via `findmnt`). SMART + fsck stay in the bash script
(they shell out to `smartctl`/`fsck` regardless); this is the fast,
no-extra-deps check runnable from the solve binary already on the VM.

`required_gb` default 1200 (560T placeholder — calibrate from the #62
11.2T dry-run footprint). Marker file: `$SOLVE_DISK_MARKER` (default
`solutions.sha256`). Exits **0** pass / **1** warning (e.g. no
expected UUID passed, or marker missing) / **2** usage / **5**
identity mismatch (wrong disk — do NOT launch) / **6** insufficient
capacity / **7** read-write smoke test failed.

### --print-config

```
solve --print-config
```

Config introspection (2026-05-28). Dumps build provenance (GIT_HASH,
build date/time, canonical selftest sha) and every `SOLVE_*` environment
variable's effective value (its value, or `(unset)` = built-in default in
effect). Purpose: when a future change drifts the canonical sha, the
config delta is **explicit** rather than reverse-engineered. Complements
`--cpu-features` (ISA) and the `canonical-host-fingerprint.json` sidecar
(host env). Compile-time choices (LTO/PGO/-march/AVX-512) are not
runtime-introspectable — record them at build time (DEVELOPMENT.md
reproducible-build recipe + `build.sha`). No enumeration; exits 0.

### --canonical-config

```
solve --canonical-config <SCALE>            # 3 sha-determining env vars
solve --canonical-config <SCALE> --full     # also emit DFS_ITERATIVE=1 + DFS_CHECKPOINT=1
```

PSB calculator (2026-06-13). Hardcoded recipe table inside `solve.c` is
the authoritative source for `SOLVE_PER_SUB_BRANCH_LIMIT` per canonical
scale — the same values published in
[CANONICAL_HASHES.md §Reproducibility parameters](CANONICAL_HASHES.md#reproducibility-parameters).
Known scales: `1T 5.6T 10T 11.2T 100T 560T d2-10T`.

Output is sha-determining only — `SOLVE_DEPTH`, `SOLVE_NODE_LIMIT`,
`SOLVE_PER_SUB_BRANCH_LIMIT`. Deliberately does NOT emit `SOLVE_THREADS`
(not sha-determining; depends on caller hardware) or
campaign-operational vars (`SOLVE_ALLOW_BUILD_MISMATCH`,
`SOLVE_SKIP_AUTOMERGE`, `SOLVE_SKIP_IOPS_CHECK`).

Use case: launchers that want to avoid hardcoding PSB:

```
eval $(./solve --canonical-config 100T)
SOLVE_THREADS=128 ./solve 0 128
```

Exit 0 on success; exit 25 on unknown scale or missing arg. Sha-neutral:
argv-dispatched, never on the enum path. No enumeration; exits immediately.

Motivated by the 2026-06-12 PSB math error (see
`petersm3/roae-private:LESSONS_LEARNED_2026_06_12_PSB_MATH_ERROR.md`)
where two re-derive launchers shipped with PSBs re-derived from a wrong
floor formula, costing ~$15 of compute and ~16h of wall before being
caught against the recipe table.

### --estimate-knuth

```
solve --estimate-knuth <N_probes> [<p1> <o1> [<p2> <o2> [<p3> <o3>]]]
```

Knuth (1975) random-probe estimator (#195, exploration) for the **un-budgeted**
C1–C5 backtrack tree — estimates its total size *without enumerating it* and
without any shard/`solutions.bin` data (pure compute). Each probe is one random
root→dead-end walk: weight `W=1`; at a node with `d` live (C1/C2/C4/C5-satisfying)
children, `W*=d` and descend to a uniform-random one; stop at a dead end or a
depth-32 leaf. Averaging `N` independent probes is an **unbiased** estimate of:
`tree_nodes` (total nodes), `leaves_C1C2C4C5` (complete orderings), and
`leaves_canonical_C1C5` (C3-valid = canonical, un-deduped). Prints mean, 95 % CI,
relative error, and hit-rate for each. `SOLVE_THREADS` sets parallelism (default
`nproc`); each thread uses an independent xorshift seed.

- No prefix → the whole C1–C5 tree (all 56 first-level branches).
- A `<p> <o>` prefix (up to 3 levels, e.g. `22 0 30 1 20 0`) scopes the estimate
  to one branch / sub-branch.
- `N_probes = 0` → **exact deterministic** subtree count instead of estimation
  (only tractable for a deep prefix; used to validate the estimator against
  ground truth — matches to <1 % at prefix depths 22/24/26).

Sha-neutral: argv-dispatched, reuses (copies) the `backtrack()` prune predicates,
never touches the enumeration/merge path (`--selftest` unchanged). No shard data.
Exits 0. Reuses the same C1–C5 constraints as the enumerator so it walks the
identical tree. See `petersm3/roae-private:SEARCH_SPACE_CHARACTERIZATION_PLAN.md`
and `ANALYSIS_195_*` for method + results.

### --knuth-dump-prefix

```
solve --knuth-dump-prefix <depth> <seed>
```

**Dev/calibration utility** (companion to `--estimate-knuth`). Emits a single random
VALID (C1–C5) deep prefix, to the requested `<depth>`, as a `"<pair> <orient> ..."`
list on stdout — the input format the `--estimate-knuth` prefix argument consumes.
Used to generate the deep prefixes for the exact-count calibration audit that
validates the Knuth random-probe estimator against ground truth. `<seed>` seeds the
walk so a prefix is reproducible. Sha-neutral: argv-dispatched, off the
enumeration/estimator hot path — never touches `--selftest` or the enum. Exits 0.

### --validate-launcher-config

```
solve --validate-launcher-config <SCALE> <PSB>
```

Pre-flight gate (2026-06-13, companion to `--canonical-config`). Asserts
the caller's `SOLVE_PER_SUB_BRANCH_LIMIT` matches the canonical recipe
for the given scale. Intended for launcher pre-flight:

```
./solve --validate-launcher-config 100T "$PSB_OVERRIDE" || exit 1
```

Exit codes:
- `0` — PSB matches recipe; safe to launch.
- `1` — PSB mismatch; sha-reproduction will fail. Stderr includes the
  diff and the fix (`solve --canonical-config <SCALE>`).
- `25` — unknown scale or bad arg count. (Note: exit 25 is also used elsewhere
  by the sub-canonical hard-gate — `SOLVE_NODE_LIMIT < 1T` without
  `SOLVE_PER_SUB_BRANCH_LIMIT` set and without `SOLVE_ALLOW_SUB_CANONICAL=1`;
  see the Hardening overrides table. The two uses are distinguished by the
  stderr message and by which subcommand was invoked.)

Sha-neutral. No enumeration; exits immediately. Bake into every
canonical-targeting launcher; catches PSB typos before any VM is
provisioned.

### --cpu-features

```
solve --cpu-features
```

Diagnostic. Prints `__builtin_cpu_supports` results for all AVX-512
sub-extensions (f / bw / dq / vl / vpopcntdq / vnni / bitalg / vbmi /
vbmi2) plus avx2, bmi2, popcnt, fma. Concludes with the composite
verdict `v2 AVX-512 dispatch ready: YES/NO` based on the
foundation+bw+vpopcntdq triple that the v2 runtime dispatcher uses.

No enumeration; instantaneous. Used by `v2_bench_d64.sh` fingerprint
capture and by pre-flight checks before AVX-512 work.

Exits 0 always.

### --cpu-freq

```
solve --cpu-freq [THRESHOLD_MHZ]
```

Diagnostic. Reads `cpu MHz` from `/proc/cpuinfo`, reports cores / min /
avg / max across all cores, and emits a HEALTHY or THROTTLED verdict
against `THRESHOLD_MHZ` (default 2000). Useful mid-bench to detect
thermal throttling that would invalidate the run — Standard on-demand
D128als_v7 hosts in westus3 have been observed to hand back hosts
running at ~600 MHz instead of the expected 2596 MHz base / 3700 MHz
boost. Companion to the orchestrator-side
`scripts/d128_preflight_throttle_probe.sh` (pre-flight probe).

No enumeration; instantaneous. Exits 0 if HEALTHY, 1 if any core is
below threshold, 2 on I/O error.

### --extended-selftest (solve.py, NOT a solve C subcommand)

```
solve.py --extended-selftest <path-to-solve-binary>
```

A `solve.py` command (`extended_selftest`, solve.py:4684) — **not** a `solve`
C subcommand; `solve --extended-selftest` is not dispatched by the binary.
Runs the 9-subtest harness covering single-thread / multi-thread / different
node limits / clean and resumed runs. Stricter than `--selftest`. Used in CI
and pre-merge gating.

### --compare-depth-profile (solve.py only)

```
solve.py --compare-depth-profile RUN_A.log RUN_B.log [--compare-depth-profile-threshold 0.005]
```

`solve.py` companion command (not a `solve` C subcommand). Tree-walk
validator: parses the `DEPTH_PROFILE depth=<d> nodes=<n>` lines from
two run logs (each produced with `SOLVE_DEPTH_PROFILE=1`; `.gz` logs
accepted) and reports per-depth plus overall **L1 / distribution
divergence**, PASS if under the threshold (default 0.5%). For
cross-build / cross-architecture / cross-thread determinism checks.
Tolerance-based, **not** byte-exact: the parallel per-sub-branch budget
cutoff overshoots by a thread-timing-dependent amount, so node counts
wiggle slightly even on identical inputs — the solution sha256 is the
byte-exact anchor; this catches *gross* tree-walk divergence. For full
(EXHAUSTED) runs the profiles match exactly. Exit 0 = PASS, 1 = FAIL,
2 = missing/empty profile.

### --verify

```
solve --verify [solutions.bin]
```

Independent constraint verification: reads every record of the
specified file (default `solutions.bin` in CWD), reconstructs the
full 64-hexagram sequence, and checks C1, C2, C3, C4, C5
independently of the enumeration code path. Catches enumeration
bugs that produce subtly wrong outputs.

Auto-detects ROAE-header (full canonical solutions.bin) vs raw
shard mode (sub_*.bin file with no header).

Reports PASS or per-record failure counts. Fast — the constraint
checks are pure-arithmetic per record.

### --validate

```
solve --validate [solutions.bin]
```

Stricter version of `--verify`: in addition to per-record
constraint checks, verifies sort order, dedup integrity, and
King Wen presence in the file. Used in regression validation when
both record-level correctness and file-level structure must pass.

### --verify-rule2

> ✅ **Live subcommand** — dispatched by `solve.c` (implemented/restored 2026-06, task #156).
> gz-aware (#169), sha-preserving (post-enumeration analysis, no enumeration-path impact). See [MCKENNA.md](MCKENNA.md) for context.

```
solve --verify-rule2 [solutions.bin]
```

[McKenna](CITATIONS.md#mckenna-mckenna1975) Rule 2 audit (cf. *The Invisible Landscape*, Chapter 9): for
each record, count value-1 transitions and check whether each occurs
at a "C2-forced position" — i.e., the orient-flip alternative for
the surrounding pair would have produced a value-5 transition. King
Wen's two value-1 transitions occur only at such C2-forced positions
per McKenna; this subcommand measures the violation rate across an
arbitrary solutions.bin. Sha-preserving (post-enumeration analysis,
no impact on the enumeration code path). See [MCKENNA.md](MCKENNA.md) for context.

### --verify-9th-six

> ✅ **Live subcommand** — dispatched by `solve.c` (task #156). gz-aware (#169),
> sha-preserving (post-enumeration analysis). See [MCKENNA.md](MCKENNA.md) for context.

```
solve --verify-9th-six [solutions.bin]
```

Audit of the "9th six" — the single between-pair value-6 transition
that every C1-C5 record contains (C5's `6:9` budget = 8 within-pair
value-6 from WPD=6 pairs + exactly 1 between-pair). Tabulates the
distribution of which boundary index that between-pair value-6 lands
at. In King Wen, it lands at boundary 19 (the transition between
hexagrams 38 and 39, the unique "synthetic" value-6 noted by McKenna
in Chapter 9). Sha-preserving.

### --verify-wrap-parity

```
solve --verify-wrap-parity [solutions.bin]
```

Tabulates the wrap-around parity of every record — whether the value between the
last and first hexagram is odd (d=1/3 split) — and reports the odd/even fractions
and the d=1 vs d=3 breakdown. At the 560T canonical, 100% of records are odd-wrap
(91.83% d=3, 8.17% d=1). gz-aware (#169), sha-preserving (post-enumeration analysis).

### --f4p-verify

```
solve --f4p-verify
```

Two-language gate for the 13 F4' ordering-layer functionals (the pre-registered
battery of [documentation/CRITIQUE.md](CRITIQUE.md) §F4'): computes each on the King Wen sequence
and checks against the embedded KW expected values. Ground truth is
`solve.py --f4p-verify`; the two outputs must match line-for-line (verify_all.sh
diffs them). Exit 0 iff all 13 match. Sha-neutral (argv-dispatched, never on the
enumeration path). Population scoring of the same functionals:
`SOLVE_KNUTH_SCORE_F4P` below.

### --dav-verify

```
solve --dav-verify
```

Two-language gate for the 9 [Davis (2012)](CITATIONS.md#davis2012) composite candidates (pre-registered in
documentation/CRITIQUE.md §Davis): computes each on the King Wen sequence and checks
against the embedded KW expected values. Ground truth is `solve.py --dav-verify`;
outputs must match byte-for-byte. Exit 0 iff all 9 match. Sha-neutral. Population
scoring: `SOLVE_KNUTH_SCORE_DAV` below.

### --dav2-verify

```
solve --dav2-verify
```

Two-language gate for the 2 [Davis (2012)](CITATIONS.md#davis2012) wave-2 candidates
(`tquartet` = C-D9 coordinated per-trigram-rotation quartet at Davis's compactness, KW=1;
`xunslots` = C-D10 Xun-bearing hexagrams at the twelve x7/x8 decade slots, KW=5;
pre-registered in `roae-private/R8_DAVIS_PREREG_2026_07_10.md` §3.1/§3.2): computes each
on the King Wen sequence and checks against the embedded KW expected values. Ground truth
is `solve.py --dav2-verify`; outputs must match byte-for-byte. Exit 0 iff both match.
Sha-neutral. Population scoring: `SOLVE_KNUTH_SCORE_DAV2` below. (C-D5 `namedsize` is
operator-declined — prereg §3.3 — and is deliberately not implemented.)

### --db1-verify

```
solve --db1-verify
```

Two-language gate for Drasny's **"Rule of Ten"** candidate **D-B1** (Rule-of-Ten
conformity count), operational spec frozen in
`roae-private/DRASNY_RULE_OF_TEN_SCOPING_2026_07_11.md` (measured 2026-07-11:
verified true and reported as a data-like fitted description — a tautology of a
KW-extracted template, no p attached; [TR-10 §3b](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)). Asserts that the bit-structural precedence classifier
(`B ≻ A ≻ F ≻ C ≻ D ≻ E ≻ G`) reproduces Drasny's Table 4.1 (book p. 75) eight-group
system EXACTLY for all 64 hexagrams — flip-equivariant, C1-pair-consistent, zero
residue, group sizes (A,B,C,D,E,F,G)=(5,4,4,4,6,3,6) — and that the King Wen
pair→slot conformity count **X = 22** (deviant slots 2 5 7 10 11 15 18 24 31 32, i.e.
Drasny's Table 4.2 list of 10 deviant pairs), plus the analytic uniform-permutation
null mean **E[X] = 190/32**. Ground truth / SPEC is `solve.py --db1-verify`; outputs
must match byte-for-byte. Exit 0 iff all pass. Sha-neutral (argv-dispatched, never on
the enum/selftest path). Population scoring (Null B): `SOLVE_KNUTH_SCORE_DB1` below.
Attribution: József Drasny (*The Yi-globe*, 2007/2011); the classifier reduction and
conformity operationalization are ROAE's. **Name-collision note:** unrelated to Scott
Davis's (2012, p. 126) separately-named "rule of ten" (#18/#27 ten ordinals apart,
registry C-D14).

### --rc4b-verify

```
solve --rc4b-verify [SEQ]
```

Two-language gate for the **R13 HEC two-convention** parity predicates (exception-clause
robustness re-run of the published R-C4 rows; design frozen 2026-07-11, private repo).
Without an argument, computes on the King Wen sequence — over the 36 inversion-class
positions in first-occurrence order, with [Schulz 1990](CITATIONS.md#schulz1990-motifs) /
[Cook 2006](CITATIONS.md#cook2006) minority-line gender (popcount < 3 male → odd class
position, > 3 female → even; popcounts {0, 3, 6} exempt) — and asserts the analytic KW
anchors:

- `rc4_viol` = 2, at class positions 25 and 26 (adjacent; the exception pair first
  recognized by Zhu Yuansheng, 13th c., per Schulz 2018 fn. 42);
- `rc4a_le2` — the published ≤2-violation relaxation (R-C4-A) passes;
- `rc4b_exc_form` — the Cook-faithful exception form (**R-C4-B**: 0 violations OR exactly
  2 at adjacent positions, i.e. strict parity up to one adjacent-transposition defect;
  a subset of R-C4-A by construction) passes;
- `rc4c_kw_locus` — 2 violations exactly at {25, 26} (**R-C4-C**; KW-anchored,
  data-like, report-only) passes;
- `rc3_exact` / `rc3w_sgap` — the level-3 class positions equal KW's
  {7,10,12,19,24,27,30,31,33,36} and contain the {6,4,2,2,0} gap window.

With a 64-int `SEQ` argument, instead prints
`viol,vp0,vp1,rc4a,rc4b,rc4c,rc3,rc3w` for cross-language / corpus-control gating.
Ground truth is `solve.py --rc4b-verify`; outputs must match byte-for-byte. Exit 0 iff
all anchors pass. Sha-neutral (argv-dispatched, never on the enum/selftest path).
Population scoring: the R-C4-B/R-C4-C mass lines ride `SOLVE_KNUTH_SCORE=1` (paired with
the published R-C4 line on identical probes); optional per-leaf T1 assertion:
`SOLVE_RC4B_ASSERT_T1` below.

### --rc1c-verify

```
solve --rc1c-verify [SEQ]
```

Two-language gate for the **R6 circular anchor-adjacency** predicate (**R-C1c**):
whether the A2 anchor pair `{21, 42}` falls in pair slot 2 or slot 32, and whether
those slots are adjacent, on a circular (wrap-around) reading. Without an argument,
computes on the King Wen sequence and asserts the analytic KW anchors — `slot2 = 0`,
`slot32 = 1`, `adjacent = 1`. With a 64-int `SEQ` argument, instead prints
`slot2,slot32,adjacent` for cross-language / corpus-control gating. Ground truth is
`solve.py --rc1c-verify`; outputs must match byte-for-byte. Exit 0 iff all anchors
pass. Sha-neutral (argv-dispatched, never on the enum/selftest path).

### --r11-verify

```
solve --r11-verify [SEQ]
```

Two-language gate for the **R11 frozen 8-axis violation bundle** — the g1..g6
tier-1 (T1) axes plus the g7, g8 tier-2 (T2) axes. Without an argument, computes each
on the King Wen sequence and asserts the frozen KW expected vector `2,2,2,0,0,0,0,0`.
With a 64-int `SEQ` argument, instead prints the 8 values for cross-language /
corpus-control gating. This is the KW-reproduction gate for the `SOLVE_KNUTH_R11_HIST`
instrument. Ground truth is `solve.py --r11-verify`; outputs must match byte-for-byte.
Exit 0 iff the vector matches. Sha-neutral (argv-dispatched, never on the enum/selftest
path).

### --f5-verify

```
solve --f5-verify
```

Two-language gate for the 11 frozen F5 orientation-layer functionals
(pre-registered and frozen 2026-07-05 before any population measurement;
[Bonferroni](CITATIONS.md#bonferroni1936) N=11): computes each on the King Wen sequence and checks against
the embedded frozen-spec KW values (computed against `solve.py`
`binary_hexagrams`; #11 `f5_vdb_nuc` is a port of `solve.py vdb_nucorient` —
`solve.py --vdb-verify`, KW=29). Exit 0 iff all 11 match. Sha-neutral.
Population scoring: `SOLVE_KNUTH_SCORE_F5` below; explicit-sequence hook:
`SOLVE_F5_TESTVEC`.

### --f6-verify

```
solve --f6-verify
```

Two-language gate for the 7 FROZEN F6 Nielsen-audit functionals — [Wu Deng's](CITATIONS.md#wudeng)
warp/weft skeleton (`warp_blocks`, `warp_pow2`, `warp_adj`, `wudeng_profile`,
`wudeng_slots`) plus the [Jing Fang](CITATIONS.md#jingfang) eight-palace
(bagong) measures (`palace_adj`, `palace_types`). Computes each on the King Wen
sequence and checks against the embedded frozen-spec KW values (KW =
6,6,1,1,8,2,24, computed against `solve.py binary_hexagrams`). Ground truth is
`solve.py --f6-verify`; the two outputs must match. Exit 0 iff all 7 match.
Sha-neutral (argv-dispatched, never on the enumeration path). Population
scoring: `SOLVE_KNUTH_SCORE_F6` below; `=2` + `SOLVE_F6_TESTVEC`:
explicit-sequence cross-verification hook.

### --vdb-verify (solve.py only)

```
solve.py --vdb-verify
```

`solve.py` companion command (not a `solve` C subcommand). Verifies the 8 Van
den Berghe (c.1998–2005) structural candidates (elementary-pair skeleton,
special-pair placement, counter-couple slope locality, six-pair group closure,
sunrise, landscape, …) on the King Wen sequence against embedded expected
values. Prints one `vdb_<name>: <value> OK/FAIL` line per candidate. Exit 0 iff
all 8 match. Two-language convention: any `solve` C `--vdb-verify` must
reproduce this output byte-identically. `f5_vdb_nuc` (#11 of the F5 battery) is
a port of this tool's `vdb_nucorient` (KW=29). Sha-neutral.

### --registry-verify (solve.py only)

```
solve.py --registry-verify
```

`solve.py` companion command (not a `solve` C subcommand). Ground-truth checker
for the candidate-rule registry (`CANDIDATE_REGISTRY_2026_07`): runs every
`reg_*` checker against the King Wen sequence and asserts each equals its
registry KW-expected value. Prints one `reg_<id>: <value> OK/FAIL` line per
rule, then an `ALL N REGISTRY CHECKS PASS` / `N of M ... FAILED` summary. Exit 0
on full PASS, 1 on any mismatch. This is the ground truth for the per-leaf
`SOLVE_KNUTH_SCORE_REG` population scorer. Sha-neutral.

### --books-verify (solve.py only)

```
solve.py --books-verify
```

`solve.py` companion command (not a `solve` C subcommand). Book-claims
verification battery (added 2026-07-05, operator-approved "write code to prove
the statements in the book"): programmatically verifies, against the King Wen
sequence, the 14 machine-checkable structural claims surfaced by the 2026-07
book audits — Wu Deng's (1249–1333) warp/weft skeleton (WD-1..4), [Lai Zhide's](CITATIONS.md#laizhide)
(1525–1604) great-image endpoint feeders (LZ-1..2), [Goldenberg's (1975, JCP 2)](CITATIONS.md#goldenberg1975)
GF(2)⁶ algebra theorems T1–T4 + T7 including his H5↔H63-via-H7 mediator
example (G-T1..T7), the [Jing Fang](CITATIONS.md#jingfang) (77–37 BCE) eight-palace table against
[Nielsen 2003](CITATIONS.md#nielsen2003) Table 2 in all 64 cells (JF-1, re-exposing the corpus-gate
check), and the classical [Yu Fan](CITATIONS.md#yufan) (164–233) fandui/pangtong pair-structure
statement including Nielsen's printed 32-couple pangtong table (YF-1..2).
Classical items sourced via Nielsen, Bent (2003), *A Companion to Yi jing
Numerology and Cosmology*; Goldenberg via [Hacker, Moore & Patsco (2002)](CITATIONS.md#hacker-moore2002) B:154
(annotation-level; primary text pending). Prints one PASS/FAIL line per claim
with expected + computed values. Exit 0 iff all 14 pass. Wall <1 s.
Attribution per claim function in solve.py; master ledger
[CITATIONS.md](CITATIONS.md).

### --r7-verify (solve.py only)

```
solve.py --r7-verify
```

`solve.py` companion command (not a `solve` C subcommand). Deterministic anchor gate for
**R7 — the cross-tradition corpus-control battery** (design frozen 2026-07-11, private repo
`R7_CORPUS_CONTROL_DESIGN_FROZEN_2026_07_11.md`). R7 asks whether ROAE's extraction
methodology manufactures ×10³-class "design" discriminators for *any* systematic ordering
of the 64 hexagrams, or correctly identifies which orderings are structured, where, and how
much. `--r7-verify` asserts the frozen anchors without running the N=10⁶ measurement:

- **FC-2 construction cross-validation** — the [Mawangdui](CITATIONS.md#shaughnessy2022) array parsed from
  `roae.py` equals the one built from `solve.c --null-historical`'s `kw[]`/`md_idx[]`
  (corrected 2026-07-05 erratum array); each of KW / [Jing Fang](CITATIONS.md#jingfang) / Mawangdui /
  Fu Xi is a permutation of 0..63.
- **Jing Fang family J1–J5** reproduces its tradition (palace-orbit representation): J1
  partition holds with t_b = [Qian,Zhen,Kan,Gen,Kun,Xun,Li,Dui]; J2∧J3 determine the
  sequence uniquely (residual 0 bits); the derived J4 complement symmetry; J5 diff-wave
  multiset {1:48, 3:15}.
- **Mawangdui family M1–M5** (trigram-octet representation): M1 constant-upper octets with
  M4 upper order [Qian,Gen,Kan,Zhen,Kun,Dui,Li,Xun]; M2 pure heads; M3 Λ-promotion lowers;
  M5 diff-wave {1:21,2:10,3:29,4:2,5:1}; and **M1∧M3∧M4 reconstruct the corrected silk-text
  array EXACTLY** (Shaughnessy 2022 Table 11.2).
- **Cross-application matrix** a-priori/theorem cells (§5): C1/C2/C3 and J1/M1/M-joint/B1
  applied to all four orderings match the frozen pass/fail table — including the honest
  off-home M1 pass on Fu Xi (excluded from the manufacture alarm only by the joint-M
  requirement, which Fu Xi fails at M2/M3/M4).
- **FC-1 positive-control expectation** reproduced at the pilot N=10⁴ (already-observed
  ledger): Jing Fang and Mawangdui each flag ≥8/11 EXTREME (both 9/11), KW extremes ==
  {a,b,f} (the C1/C2/C3 axes). A battery that fails to flag the provably-algorithmic Jing
  Fang is declared broken, published as such — no threshold tuning.

Prints one PASS/FAIL line per anchor; exit 0 iff all pass. Report-only (nothing promotes to
a solver constraint). Sha-neutral (solve.py-only; no `solve.c` change; off every
enum/selftest path). Attribution: the classical orderings are not project inventions and the
J/M formalizations are hedged, not claimed novel — see the solve.py `r7_verify` header and
[CITATIONS.md](CITATIONS.md).

### --r7-corpus (solve.py only)

```
solve.py --r7-corpus [--r7-n N] [--r7-seed S]
```

`solve.py` companion command (not a `solve` C subcommand). Runs the full R7 battery — the
operator-gated **measurement** (execution is separate from code review). For each historical
ordering it evaluates that ordering's own natural constraint family in its own
representation, then emits, as markdown to stdout:

- the **L0 uniform-null scoreboard** — the 11 F8 observables (a,b,c1,c2,d,e,f,g,h,i,j,
  normative implementation from the F8 pilot) × 4 orderings, percentile + EXTREME flags;
- the **KW pair-preserving second null** (project-standard);
- the **cross-application matrix** (families × orderings) with the off-home manufacture
  alarm — FC-3 fires on any off-home pass among {C1, J1, joint-M, B1} or any off-home
  ×10³-class enrichment;
- the **Jing Fang L1 exact** enrichment (all 8!=40,320 J1-conditioned block assignments —
  no subsampling where the space permits) and the **Mawangdui L1 sampled** ladder;
- the **MDL pricing row** (KW ≈126.6-bit residual vs Jing Fang / Mawangdui / Fu Xi 0-bit
  residuals);
- the **FC-1..FC-4 falsification-gate verdicts**, stated as outcomes of pre-committed gates.

Report-only; every cell is printed whatever it says. **Heavy** at the frozen defaults
(`--r7-n 1000000 --r7-seed 42`): hours-class on one core → run on a **Spot D4/D8 worker**,
NOT the 2-core orchestrator (heavy-ops-offboard rule). `--r7-n`/`--r7-seed` override only for
smoke tests; the canonical measurement uses the frozen defaults. Sha-neutral.

> **Note (design vs. code, surfaced during implementation):** the exact Jing Fang L1
> enumeration shows comp-sum 1024 is reached by the full block-distance-maximizing set
> (9,216/40,320 ≈ 22.9%, percentile ≈88.6), not by the 384/40,320 (~0.95%, ≥99th percentile)
> the frozen §8 FC-4 anchor states — the design conflated "reaches comp-sum 1024" with
> "satisfies J4" (J4=384 is a strict subset). The measurement stands; only the design's
> stated FC-4 percentile prediction needs a dated amendment. `--r7-corpus` prints this
> discrepancy inline.

### --compute-stats (solve.py only)

```
solve.py --compute-stats SOLUTIONS_BIN OUT_DIR
```

`solve.py` companion command (P2 distributional-analysis pipeline, stage 1). Streams
a `solutions.bin` and emits per-chunk parquet files of the observable statistics for
every enumerated ordering. `OUT_DIR` becomes the `CHUNKS_DIR` input to the
`--marginals` / `--bivariate` / `--joint-density` stages below. See
[DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md) for the full pipeline and
interpretation.

### --marginals (solve.py only)

```
solve.py --marginals CHUNKS_DIR OUT_MD
```

`solve.py` companion command (P2 stage 2). Computes per-dimension marginal
percentiles across the enumerated population, with King Wen's position marked, and
writes a Markdown report to `OUT_MD`. Consumes the `CHUNKS_DIR` from `--compute-stats`.

### --bivariate (solve.py only)

```
solve.py --bivariate CHUNKS_DIR OUT_DIR
```

`solve.py` companion command (P2 stage 2). Renders hexbin heatmaps for 5 observable
pairs with King Wen marked, into `OUT_DIR`. Consumes the `--compute-stats` chunks.

### --joint-density (solve.py only)

```
solve.py --joint-density CHUNKS_DIR OUT_MD
```

`solve.py` companion command (P2 stage 3). KDE joint density over the 7 informative
dimensions plus a bootstrap confidence interval on King Wen's percentile; writes a
Markdown report to `OUT_MD`. A refined `--joint-density-v2` variant adds an automatic
variance filter and CV bandwidth selection (`--joint-density-bandwidth silverman|cv`,
default `cv`; sampled by default, `--joint-density-exhaustive` for exact). See
[DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md).

### --f1-exact-c1c2c4

```
solve --f1-exact-c1c2c4 [--layers-dir DIR] [--f1-subset U1|U2|U3|"L.I,L.I,...[@START]"]
```

**Exact** (integer, not estimated) count of |C1 ∩ C2 ∩ C4| via the S₄-orbit-quotient
layered dynamic program (#215; the quotient uses the [TR-5](../reports/TR5_SYMMETRY.md) symmetry group, which is
what makes the DP fit in memory). Published value: 7.5706×10⁴¹ (4 s.f. of the exact
42-digit integer) — the C2-layer row of [documentation/DESCRIPTION_LENGTH.md](DESCRIPTION_LENGTH.md), exactly
divisible by 24 as the TR-5 free-action theorem requires. `--layers-dir` checkpoints per-layer state for
resume; `--f1-subset` restricts to group-closed subsets (validation gates).
Sha-neutral (argv-dispatched, never on the enumeration path).

### --f1-exact-c1c2c4c5

```
solve --f1-exact-c1c2c4c5 [--f1-pairs N] [--layers-dir DIR | --f1-out-of-core DIR] [--resume-from-layers]
```

Extension of the orbit DP with the capped C5-residual dimension (#217): exact
|C1 ∩ C2 ∩ C4 ∩ C5| over group-closed pair-orbit unions. `--f1-pairs N` with
N ∈ {9,13,16,18,19,24,25,27,28,31} (default 31 = full run at KW's budget).
Sha-neutral.

`--f1-out-of-core DIR` (#221) runs the same DP with a different memory
strategy: NO layer's entries are ever held in RAM in full — only fixed
streaming buffers plus the two live layers' indexes (12 B/mask). Layers live
in DIR (same atomic per-layer files + manifest as `--layers-dir`; with
`SOLVE_F1_OOC_FORMAT=v1` the two modes' layer files are byte-identical — under
the v2 out-of-core default they are content-identical, byte-different; see
`--f1c5-verify-layer`); the next layer's gather streams the
previous layer's file via bucketed, coalesced sequential reads (no per-entry
random file access), and the layer being BUILT is streamed back to disk
chunk-by-chunk as it is emitted (2026-07-05 fix — the original #221 build
accumulated the whole built layer in RAM, which OOMs at full-31 where mid
layers exceed 100 GB; peak RSS is now ~2.2x `SOLVE_F1_OOC_SCRATCH_MB` plus
read windows, independent of layer size). Purpose:
(a) reproducibility of the exact count on commodity hardware (~64 GB RAM +
~4 TB disk); (b) independent-path validation — the identical integer via a
different memory strategy; (c) Spot-safety — layer files are free checkpoints.
Per-layer `[f1c5-ooc]` stderr telemetry reports bytes read/written, effective
MB/s, and current/peak RSS so the memory claim is verifiable from the log.
Buffer knobs: `SOLVE_F1_OOC_READ_MB`, `SOLVE_F1_OOC_SCRATCH_MB`,
`SOLVE_F1_OOC_GAP_KB` (see env table). `--resume-from-layers` requires resume
from DIR's last complete layer (hard error if there is nothing to resume);
without it resume is still automatic when a matching manifest exists,
mirroring `--layers-dir`. Mutually exclusive with `--layers-dir`.

Layer files use the **v2 zlib-blocked format by default** (`SOLVE_F1_OOC_FORMAT`;
per-block RFC-1950 zlib via `compress2` — **not** gzip-framed `.gz`, despite the
"gzip" shorthand in the tool/env names; see
[F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md) — compression level via
`SOLVE_F1_OOC_GZIP_LEVEL`, default 6) — smaller disk/I-O than the raw
`v1` reference, with the count format- and level-invariant. For long multi-day runs
(e.g. the full n=31 count) the DP also writes an **intra-layer checkpoint** every
`SOLVE_F1_CKPT_SEC` seconds (default 300), so `--resume-from-layers` resumes *mid-layer*
after a Spot eviction rather than restarting the current layer. (#223)

### --f1c5-gzip-selftest

```
solve --f1c5-gzip-selftest
```

Self-test of the `--f1-out-of-core` **v2** per-block zlib layer codec (#223
retool; the codec is RFC-1950 zlib, not gzip — the flag name is historical):
round-trips the per-block zlib compress/decompress path across compression
levels and asserts byte-identical recovery of the key/value block payload. Exit
0 on PASS, non-zero on any round-trip mismatch or allocation failure. Verifies
the on-disk layer-file format layer in isolation; sha-neutral (argv-dispatched,
never on the enumeration path).

### --f1c5-verify-layer

```
solve --f1c5-verify-layer <v1_raw> <v2_gzip>
```

Cross-checks one `--f1-out-of-core` layer file written in the **v1** raw format
(`F1C5LAY1` magic) against the same layer written in the **v2** zlib-blocked
format (`F1C5LAY2` magic; the `<v2_gzip>` placeholder name is historical — the
codec is RFC-1950 zlib), asserting they decode to byte-identical mask/entry
content (#223). Both path arguments are required (exit 2 on usage error or read
error); exit 1 on a content mismatch, 0 on match. This is the format-invariance
check that backs the "count is format-invariant" claim for the OOC DP.
Sha-neutral.

### --merge

```
solve --merge
```

Scans CWD for `sub_*.bin` shard files (depth-2 or depth-3 naming
`sub_P1_O1_P2_O2[_P3_O3].bin`), reads them all, sorts globally,
deduplicates by canonical form, and writes
`solutions.bin` + `solutions.sha256` + `solutions.meta.json`.

By default uses in-memory merge if records fit in RAM; falls back
to external sort to `SOLVE_TEMP_DIR` if not. External sort writes
chunks named `temp_sorted_*.bin` to the temp dir and merges them
into the final solutions.bin.

`SOLVE_TEMP_DIR` should point to a directory with at least
1.5× the expected solutions.bin size of free space.

Skip files matching `*.tmp` (in-progress writes). Refuses to run
if any sub_*.bin file size is not a multiple of 32 bytes
(SOL_RECORD_SIZE).

### --merge-layers

```
solve --merge-layers <run_root>
```

Walks subdirs of `<run_root>` in lexical order ("layers"), and
for each sub-branch tuple produces the LAST layer's shard as the
canonical version (last-writer-wins). Symlinks the winning shards
into `<run_root>/_merged_/` along with a `MANIFEST.txt` recording
provenance, then runs the standard merge in that directory.

Used when extending an enumeration with deeper-budget runs on a
subset of sub-branches without rewriting earlier layer shards.

Convention: layer dirs are named `<NN>_<scope>_<budget>_<date>/`,
e.g., `01_full_5T_2026_04_29/`, `02_extend_dead_50T_2026_04_30/`.

### --analyze

```
solve --analyze [solutions.bin]
```

Computes statistics across the entire solution set: complement-
distance distribution, position-2 marginal distribution, line-
autocorrelation per position, K-N pair-frequency tables,
boundary-uniqueness exhaustive search, and more.

Outputs a long human-readable report to stdout. Used during
research to characterize where King Wen sits in the
solution-space distribution.

`-fopenmp` parallelizes the hot loops in this subcommand.

### --show

```
solve --show [N] [--mode first|last|random] [--format kw|binary|glyph|raw]
            [--from FILE] [--from-first M] [--seed S]
```

Visual-inspection sample of solutions.bin records.

Default: first 10 records of `solutions.bin` in CWD, in `kw` format
(King Wen pair numbers like `[1,2] [3,4] ...`).

Modes:
- `first` — first N records (lex-smallest).
- `last` — last N records.
- `random` — N uniform-random records. Use `--from-first M` to
  restrict the random pool to records 0..M-1. Use `--seed S` for
  reproducible random sampling.

Formats:
- `kw` — King Wen hexagram numbers in pairs, e.g., `[1,2] [3,4]`.
- `binary` — 6-bit line patterns: `111111 000000 | 010001 100010 | …`.
- `glyph` — Unicode hexagram glyphs (U+4DC0..U+4DFF), requires
  UTF-8 terminal: `䷀䷁ ䷂䷃ ䷄䷅ …`.
- `raw` — `pair_index/orient` per byte: `0/0 1/0 2/0 …` (debugging).

O(N) seek cost regardless of file size — random fseek over the
102 GB canonical is O(1) per seek (header offset + index ×
SOL_RECORD_SIZE), so this is fast even on huge solutions.bin.

Useful for visual-validating C4 (every record's first pair should
print as `[1,2]` / `䷀䷁`) or eyeballing record structure.

### --branch

```
solve --branch <p1> <o1> [time_limit] [threads]
```

Single first-level branch: enumerates only those orderings whose
first non-fixed pair is `(p1, o1)`. The fixed pair-0 (Creative+
Receptive at slot 0) per C4 is implicit.

Used for partition-invariant 56-branch reconstruction and for
single-branch deep-walk experiments.

`p1` ∈ {1..31}, `o1` ∈ {0, 1}. With C2 some `(p1, o1)` are
infeasible (transition from hex-0 to first hex of pair `p1` is
hamming-5); 6 of the 62 candidates fail-fast, leaving 56 effective
branches. See `--list-branches`.

Output: `sub_*.bin` shards in CWD; auto-merge at end produces
`solutions.bin` for that branch.

### --sub-branch

```
solve --sub-branch <p1> <o1> <p2> <o2> <p3> <o3> [time_limit] [threads]
```

Depth-3 sub-branch only: enumerates orderings whose first three
non-fixed pair placements are exactly `(p1, o1, p2, o2, p3, o3)`.
Used for targeted exhaustion of single sub-branches at extreme
node budgets (10T, 100T, 1000T).

Output: shard files `sub_P1_O1_P2_O2_P3_O3.bin` in CWD; checkpoint
+ DFS state sidecar files for resume.

### --list-branches

```
solve --list-branches
```

Prints the 56 valid first-level `(p1, o1)` branches (those that
don't fail-fast on C2 at the first transition). Each line:
`p1 o1` with optional commentary. Useful for scripting `--branch`
loops.

### --c3-min

```
solve --c3-min
```

Searches the canonical solution set for the orderings with minimum
total complement distance. Used in the c3-minimum analysis that
established KW sits at the C3 *ceiling* (776), not the floor.

### --c3-dist

```
solve --c3-dist [SOLUTIONS_BIN]
```

`--analyze` fast-path that emits **only** the C3 complement-distance
histogram over the solution set (sibling of `--c3-min`; the same C3
observable, tabulated across the whole population rather than reduced to
the minimum). Runs the analyze reader with the `c3dist_only` flag set, so
it skips the other analyze passes. `SOLUTIONS_BIN` defaults to
`solutions.bin`. Read-only; sha-neutral.

### --yield-report

```
solve --yield-report < log
```

Reads a depth-3 enumeration log on stdin and produces a
per-sub-branch yield-clustering report. Identifies dead branches,
dominant branches, and orientation-symmetry patterns.

### --symmetry-search

```
solve --symmetry-search [--validate-counts]
```

Group-theoretic symmetry hunt across the solution space. Searches
for non-trivial automorphisms of the C1-C5 ordering structure.
Has produced negative results to date (no non-trivial group
discovered).

`--validate-counts` annotates each candidate symmetry with empirical
yield equality across orientations.

### --null-*

```
solve --null-debruijn-exact
solve --null-gray
solve --null-latin
solve --null-latin-col
solve --null-lex
solve --null-historical
solve --null-random
solve --null-pair-constrained
solve --null-latin-explain
solve --null-gray-random
```

Null-model comparisons: how does King Wen rank against various
classes of structured sequences (DeBruijn, Gray code, Latin square
construction, lex-ordered, historical orderings like Mawangdui /
Fu Xi, random pair-constrained, etc.)?

Each variant tests KW's structural metrics against a different
null distribution. Used to qualify "robust" findings (where KW is
extreme against multiple null models) from "constraint-extraction"
findings (where KW appears extreme only against unconstrained
random).

### --prove-cascade

```
solve --prove-cascade
```

Symbolic proof: cascade theorem (C1-C5 implies certain structural
properties). Walks the proof tree exhaustively up to depth-N
configurations, verifying invariants. Finishes in seconds at small
N; exponential at deeper N. Each config is capped at `PROVE_CONFIG_TIMEOUT` seconds (default 300; `0` = no cap).

### --prove-self-comp

```
solve --prove-self-comp
```

Symbolic proof: self-complementary configurations are bounded by
the C3 ceiling.

### --prove-shift

```
solve --prove-shift
```

Symbolic proof: shift-invariance of the C2 + C5 distribution.

### --regression-test

```
solve --regression-test [scope]
```

Runs a canonical-sha regression matrix at multiple scopes (1B,
10B, 100B, 1T budgets) and verifies each produces the recorded
sha. Used in CI for catching subtle solver regressions.

### --double-regression-test

```
solve --double-regression-test [base_dir]
```

Two-path regression: full-enum at depth-3 vs 56-branch
reconstruction at the same per-sub-branch budget, both merged
globally. Both paths must produce byte-identical sha256. Used to
verify the partition invariance theorem at empirical scales.

Reads/writes test artifacts under `<base_dir>` (default `./`).

### --emit-shard-manifest

```
solve --emit-shard-manifest [dir]
```

Walks `dir` (default CWD), opens each `sub_*.bin`, computes its sha256,
and writes `shard_manifest.txt` recording `<filename> <size_bytes>
<sha256>` per line. Header records the manifest version, build sha of
the emitting binary, and emission timestamp.

Used by the auto-emit gate (default, suppressed via
`SOLVE_SKIP_AUTO_MANIFEST=1`): solve auto-emits a `shard_manifest.txt`
after every `flush_sub_solutions` rename + after the
`promote_orphaned_shards` path completes, so the manifest stays in
lockstep with the shard set. Operator-invocable for explicit
re-baselining.

### --verify-shard-manifest

```
solve --verify-shard-manifest [dir]
```

Reads `shard_manifest.txt` from `dir` (default CWD), re-computes
sha256 of every shard, and reports MISSING / SHRUNK / DIVERGED /
EXTRA entries. Exits 22 on any anomaly. Run at every canonical-enum
startup as the auto-verify gate — catches cross-run shard-set
contamination before the new enumeration begins building on top of
ambiguous prior state.

`EXTRA` (shard present in dir but not in manifest) is a non-fatal
warning; the auto-emit at next checkpoint absorbs new shards. MISSING
/ SHRUNK / DIVERGED are fatal.

### --compare-provenance

```
solve --compare-provenance A.json B.json
```

Assert that two `solutions.provenance.json` files are structurally
equivalent — i.e., they were produced by enumerations targeting the
same canonical set, even if via different execution paths
(single-shot vs branch-merged vs extension-merged). Normalizes away
fields that legitimately differ across paths: timestamps, host
fingerprints, merge-invocation metadata, sum_compute_seconds,
campaign_wall_seconds, extensions_observed timestamps.

Must-match fields:
- `solutions_bin_sha256`
- `solutions_bin_record_count`
- `shard_count`
- `shards_by_final_status` (the EXHAUSTED / BUDGETED / INTERRUPTED counts)
- `final_budget_distribution` (the budget → shard-count map)
- `cumulative.total_nodes_explored`
- `cumulative.total_records_emitted`

Exits 0 on PASS, 1 on FAIL (and prints per-field diff on FAIL). Used
by Phase G of task #101 (pre-560T PI + extension test) to witness
metadata equivalence end-to-end.

### --kde-score-stream

```
solve --kde-score-stream --fit-file PATH --d N --bandwidth BW --threshold T
```

Streaming KDE scorer for the joint-density analysis pipeline. Reads
`solutions.bin` records on stdin, scores each against the
KDE-fitted joint observable density (loaded from `--fit-file`), and
writes a stream of (record_index, density_score) pairs. Used by
[DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md).

## ENVIRONMENT

### Core (DFS / merge / threading)

| Variable | Default | Effect |
|---|---|---|
| `SOLVE_THREADS` | `min(128, nproc)` | Number of pthreads for enumeration |
| `SOLVE_DEPTH` | 3 | DFS sub-branch depth: 2 (3,030 sub-branches) or 3 (158,364 sub-branches) |
| `SOLVE_NODE_LIMIT` | 0 (no limit) | Total node budget across the enumeration |
| `SOLVE_PER_SUB_BRANCH_LIMIT` | derived | Per-sub-branch node cap; overrides auto-divide of `SOLVE_NODE_LIMIT`. Setting this also suppresses the sub-canonical hard-gate (intended for partition-invariance and within-code-state runs). |
| `SOLVE_PER_TASK_NODE_LIMIT` | derived | Per-task cap (depth-3 sub-branch granularity for parallel `--sub-branch`) |
| `SOLVE_DFS_ITERATIVE` | 0 (recursive); **1 if `SOLVE_NODE_LIMIT >= 1T` (canonical-scale default since 2026-05-26)** | `=1`: iterative DFS using explicit stack frames (resume-capable) |
| `SOLVE_DFS_CHECKPOINT` | 0 (off); **1 if `SOLVE_NODE_LIMIT >= 1T` (canonical-scale default since 2026-05-26)** | `=1`: write `.dfs_state` per-sub-branch sidecar + `checkpoint.txt` for resume after interrupt or eviction |
| `SOLVE_CKPT_INTERVAL` | 30 (seconds) | Wall-time interval between checkpoint writes |
| `SOLVE_TEMP_DIR` | (CWD) | Where `--merge` external sort writes `temp_sorted_*.bin` chunks; needs ~1.5× output size |
| `SOLVE_MERGE_MODE` | auto | `external`: force external sort (use chunks). `memory`: force in-memory merge (fail if doesn't fit) |
| `SOLVE_MERGE_CHUNK_GB` | 4 | Per-chunk size for external merge sort |
| `SOLVE_COMPRESS` | 1 (gzip) | `=0`: write shards/outputs raw (uncompressed). Default writes gzip; reads auto-detect via magic bytes, so raw and gz interoperate |
| `SOLVE_GZIP_LEVEL` | 9 | gzip level for shards and the final `solutions.bin` (the durable/archival artifacts) |
| `SOLVE_MERGE_TEMP_GZIP_LEVEL` | 6 | gzip level for **transient** external-merge temp chunks only (`temp_sorted_*.bin`, `temp_merge_records.bin`) — the "knee" of the speed/ratio curve. **The final `solutions.bin` and any cold archive stay `SOLVE_GZIP_LEVEL` (9) regardless of this** — it never touches a durable artifact |
| `SOLVE_MERGE_THREADS` | 1 (serial) | `=N`: parallelize external-merge Phase 1 (sort+gz-write of chunks) across N threads; RAM/nproc-capped. Default 1 = the validated serial path |
| `SOLVE_SKIP_TEMP_SPACE_CHECK` | 0 | `=1`: skip the pre-merge free-space pre-flight (sum of input shard bytes ×1.5 vs `statvfs(SOLVE_TEMP_DIR)`) |
| `SOLVE_MEMORY_FLUSH_COUNT` | 200000000 | Records-per-thread before flushing hash table to shard (memory-relief flush threshold) |
| `SOLVE_DEPTH_PROFILE` | 0 (off) | `=1`: emit per-depth node-count histogram to log |
| `SOLVE_CONCENTRATE_BUDGET` | 0 | Concentrate budget on richest sub-branches (deep-walk pilot mode) |
| `SOLVE_DEAD_LIMIT` | 0 (no limit) | Cap on per-sub-branch dead-branch attempts (calibration use only) |
| `SOLVE_SUB_BRANCH_PARALLELISM` | 0 (off) | `=N`: parallelize `--sub-branch` mode across N CPU cores per task |
| `SOLVE_REGRESS_DIR` | `./` | Directory for `--regression-test` artifacts |
| `SOLVE_HASH_LOG2` | 24 | Hash table slots = 2^N; default 16M slots × 32 bytes = 512 MB per thread |
| `SOLVE_RESUME_HISTORY` | (none) | Operator-supplied annotation written to `solutions.sha256` metadata. Use to record interruption/eviction context for forensic continuity. |
| `PROVE_CONFIG_TIMEOUT` | 300 (per-config; `0` = no limit) | Per-config wall-time cap (seconds) for the `--prove-cascade` multi-config survey. Default 300 s (5-min survey); set `0` to run each config to completion. |
| `PATH` | inherited | Used to locate `solve` binary for self-spawning subprocesses |
| `SOLVE_SKIP_AUTOMERGE` | 0 (off) | `=set` (any value): skip the automatic `--merge` at enum completion; leave shards in place. Used for split enum/merge campaigns (separate right-sized merge VM) and the #149 milestone-staging ladder. |
| `SOLVE_FSYNC_BATCH_SIZE` | 1 | Batch N checkpoint fsyncs per flush to amortize fsync cost on fsync-bound disks (#108b). Higher = fewer fsyncs, larger replay window on crash. |
| `SOLVE_MANIFEST_THREADS` | `SOLVE_THREADS` | Override the thread count for the parallel `shard_manifest.txt` sha256 sweep (#116). |
| `SOLVE_DISK_MARKER` | (none) | Custom marker filename for `--disk-precheck` to test free space against (otherwise a default probe path is used). |

### Hardening overrides (2026-05-25/26 — every gate has an explicit escape)

All hardening gates fire by default on canonical-enum dispatch (no `--xxx` subcommand). Each can be individually suppressed via env var. Suppressing a gate is operator-acknowledgment that they understand the failure mode being bypassed.

| Variable | Default | What it disables |
|---|---|---|
| `SOLVE_ALLOW_SUB_CANONICAL` | 0 | Sub-canonical hard-gate (exit 25): allows `SOLVE_NODE_LIMIT < 1T` without `SOLVE_PER_SUB_BRANCH_LIMIT` set. Output sha will be code-specific (see [HISTORY.md](HISTORY.md) "100B canonical drift" 2026-05-25). |
| `SOLVE_SKIP_CANONICAL_LOCK` | 0 | LOCK file (exit 27): allows concurrent `solve` invocations on the same cwd. Risk: interleaved shard writes / checkpoint corruption. |
| `SOLVE_ALLOW_BUILD_MISMATCH` | 0 | `build.sha` check (exit 26): allows resuming with a binary that differs from the one that last wrote `build.sha`. Risk: cross-lineage merge contamination. Canonical launchers (LAUNCH_*) handle legitimate rebuild scenarios by deleting stale `build.sha` post-rebuild (preserved as `parent_build.sha.<timestamp>` for archival), so the override is no longer required for normal campaign flow as of 2026-06-13. Override remains available for ad-hoc operator-authorized resumes after a manual mid-campaign rebuild. See [DEVELOPMENT.md §build.sha invariant](DEVELOPMENT.md#buildsha-invariant-outlier-4). |
| `SOLVE_ALLOW_MISSING_BUDGET_SIDECAR` | 0 | `.budget` sidecar strict-default (orphan refuse): allows promotion of legacy shards without sidecars (pre-2026-05-25 runs). Risk: Outlier #5 budget-mismatch. |
| `SOLVE_SKIP_AUTO_MANIFEST` | 0 | Auto-emit + auto-verify `shard_manifest.txt` (exit 22): disables both startup verify and post-promote emit. |
| `SOLVE_SKIP_AUTO_SELFTEST` | 0 | Auto-selftest before canonical launch (exit 24): skips the smoke test that confirms binary produces canonical selftest sha. |
| `SOLVE_SKIP_DISK_CHECK` | 0 | Disk-space pre-check (exit 29): skips the projected-vs-available check at canonical-enum startup. |
| `SOLVE_SKIP_BINARY_SNAPSHOT` | 0 | `solve.binary.snapshot` write at canonical-enum startup. |
| `SOLVE_SKIP_STACK_RAISE` | 0 | `setrlimit(RLIMIT_STACK, RLIM_INFINITY)` at `--merge` startup (exit 28). |
| `SOLVE_MERGE_NOFILE` | (auto) | `--merge` auto-raises `RLIMIT_NOFILE` soft→hard at startup so the Phase-2 k-way merge can open every sorted chunk at once (thousands at canonical scale — a 1 GB-chunk 560T merge makes ~1,308). `=N` pins the soft-limit target instead of the hard limit. Only ever *raises*, never lowers. Non-fatal (a low hard cap surfaces later as a clear "Too many open files"). Sha-neutral. #196. |
| `SOLVE_SKIP_NOFILE_RAISE` | 0 | `=1`: disable the `--merge` `RLIMIT_NOFILE` auto-raise (mirror of `SOLVE_SKIP_STACK_RAISE`). |
| `SOLVE_KNUTH_C67` | 0 | `=1`: `--estimate-knuth` (both probe and exact modes) additionally enforces the spec's C6/C7 adjacency constraints (slots 24–27 pinned to KW's pairs, orientation free) — estimates \|C1–C7\| instead of \|C1–C5\|. Estimator-only; sha-neutral. Uniqueness-conjecture probe (2026-07-02). |
| `SOLVE_KNUTH_PIN_SLOTS` | comma list of slots 1–31 | Pin listed slots to KW's pairs during Knuth walks (orientation free); generalizes `SOLVE_KNUTH_C67`. F2 S(k) boundary-information curve. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_BOUNDARY_COND` | `1` | Per-boundary KW-agreement mass accumulators (31; the `--analyze` §[6] predicate on the estimator); conditional on the pin prefix if set. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SCORE_REG` | `1` | Score all 31 registry candidate rules ([Schulz 1990](CITATIONS.md#schulz1990-motifs)/[2011](CITATIONS.md#schulz2011)/[2016](CITATIONS.md#schulz2016)/diss, [McKenna-Mair 1979](CITATIONS.md#mckenna-mair1979), [Drasny](CITATIONS.md#drasny2007), [Schöter](CITATIONS.md#schoter1998) — attribution per rule in code) per canonical leaf; ground truth: `solve.py --registry-verify`. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SCORE_PERM` | 0 | `=1`: score the 13 FROZEN R3 permutation-cycle functionals per canonical leaf (`perm_ncyc_bot`, `perm_lcyc_bot`, `perm_ord_bot`, … `perm_desc_top`; KW = 7,33,1,1,1320,31,1,3,52,0,1,260,30). Observable axis anchor: [Ge 2026](CITATIONS.md#ge2026) (KW cycle type of the top permutation (52,10,2)). Ground truth / two-language gate: `solve.py --perm-verify`. `=2` + `SOLVE_PERM_TESTVEC`: explicit-sequence cross-verification hook. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_PERM_HIST` | 0 | `=1` (requires `SOLVE_KNUTH_SCORE_PERM=1`): additionally emit `perm_hist <name> <value> <mass>` per-functional weighted value histograms (the two `ord` functionals are wide-binned into 512 bins, Landau bound g(64)=2,042,040). Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SCORE` | 0 | `=1`: `--estimate-knuth` additionally reports weighted canonical-mass fractions for externally-attributed candidate rules — R-C1 final-pair anchor + R-C2 first-7 level coverage ([Cook 2006](CITATIONS.md#cook2006)), R-C5 18:18 split (Zheng Qiao ~1150 / Hu Yigui 1247 / [Hacker & Moore 2003](CITATIONS.md#hacker-moore2003) / Cook 2006), R-M1 pair-positioning parity ([Moore 2005](CITATIONS.md#moore2005)). Since 2026-07-12 also reports, paired on the same probes as the R-C4 gender/parity line, the R13 two-convention masses **R-C4-B** (exception form: 0 violations OR exactly 2 at adjacent class positions; subset of the published ≤2 relaxation) and **R-C4-C** (2 violations exactly at {25,26}; data-like, report-only) — KW gate `--rc4b-verify`. See CITATIONS.md §Attributed candidate rules. Estimator-only; sha-neutral (2026-07-02). |
| `SOLVE_KNUTH_MOORE_STRICT` | 0 | `=1`: prune the Knuth walk to orderings satisfying BOTH Moore rules strictly (2005 pair-positioning parity 18/18 AND [1989](CITATIONS.md#moore1989) rising/falling 0-breaks) — `leaves_canonical` then estimates the joint-strict space ([TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) §4: ≈1.13×10²⁹ ±4.7%; F11 runs B/C, archived reports/evidence/f11/). Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_GENDER_STRICT` | 0 | `=1`: prune the walk to orderings satisfying the Schulz 1990 gender/position-parity rule strictly (0 violations; semantics identical to the rc4 leaf scorer / `solve.py rc4_violations`; exception first noted by Zhu Yuansheng, 13th c.). Composes with `SOLVE_KNUTH_MOORE_STRICT` to estimate the triple-strict ("grand-strict") space (F11 M_corr precursor set). Prints a leaf-scorer cross-check line (mismatches must be 0). Estimator-only, sha-neutral. |
| `SOLVE_RC4B_ASSERT_T1` | 0 | `=1` (requires `SOLVE_KNUTH_SCORE=1`): per-leaf T1 assertion for the R13 R-C4-B instrument — on every canonical leaf where the adjacent-defect clause fires, assert that the level-3 (neuter, gender-exempt) class-position set is disjoint from the two violating positions, so the repairing adjacent transposition moves no level-3 class (the analytic convention-invariance argument for the level-3 rows). Prints `checked=<n> fail=<n>` (expected fail=0). An assertion, not a measurement. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_F11_HIST` | 0 | `=1` (requires `SOLVE_KNUTH_SCORE=1`): emit the F11 joint violation histogram — `f11_hist v1 v2 v3 <mass>` lines over (v1 = 18 − Moore-2005 parity compliance, v2 = Moore-1989 rhythm breaks, v3 = Schulz-1990 gender violations; KW = (2,2,2)) — the M_tend normalizer ingredient of the [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) v1.7 Bayes comparison (archived instance: reports/evidence/f11/f11_runA.out). Under strict walks the fractions are conditional on the pruned space. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SCORE_F4P` | 0 | `=1`: score the 13 pre-registered F4' ordering-layer functionals per canonical leaf (below/at/above-KW weighted masses; CRITIQUE.md §F4'; [TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md) v1.3). Ground truth / two-language gate: `--f4p-verify`. Archived tier-1 run: reports/evidence/f4p_tier1.out. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_F4P_HIST` | 0 | `=1` (with `SOLVE_KNUTH_SCORE_F4P=1`): additionally emit `f4p_hist <name> <value> <mass>` full per-functional weighted value histograms. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SCORE_DAV` | 0 | `=1`: score the 9 pre-registered Davis (2012) composite candidates per canonical leaf (CRITIQUE.md §Davis; [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) §3). Ground truth / two-language gate: `--dav-verify`. Archived tier-1 run: reports/evidence/dav_tier1.out. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_DAV_HIST` | 0 | `=1` (with `SOLVE_KNUTH_SCORE_DAV=1`): additionally emit `dav_hist` per-candidate weighted value histograms. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SCORE_DAV2` | 0 | `=1`: score the 2 pre-registered Davis (2012) wave-2 candidates (`tquartet` C-D9 bounds 0..55; `xunslots` C-D10 bounds 0..12) per canonical leaf (`roae-private/R8_DAVIS_PREREG_2026_07_10.md` §3.1/§3.2). Ground truth / two-language gate: `--dav2-verify`. Estimator-only, sha-neutral. C-D5 `namedsize` is operator-declined (prereg §3.3). |
| `SOLVE_KNUTH_DAV2_HIST` | 0 | `=1` (with `SOLVE_KNUTH_SCORE_DAV2=1`): additionally emit `dav2_hist` per-candidate weighted value histograms. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SCORE_DB1` | 0 | `=1`: score Drasny's "Rule of Ten" candidate D-B1 (conformity count X, bounds 0..32; KW X=22) per canonical leaf — **Null B**, the dispositive population null over C1–C5 space (`roae-private/DRASNY_RULE_OF_TEN_SCOPING_2026_07_11.md` §2). Emits `[db1 rule-of-ten] mean … below/at/above/atinc` (weighted canonical-mass fractions relative to KW's X=22). Ground truth / two-language gate: `--db1-verify`. Estimator-only, sha-neutral. Attribution: József Drasny (*The Yi-globe* 2007/2011); classifier reduction ROAE's. Unrelated to Davis 2012's separately-named "rule of ten" (C-D14). |
| `SOLVE_KNUTH_DB1_HIST` | 0 | `=1` (with `SOLVE_KNUTH_SCORE_DB1=1`): additionally emit `db1_hist <X> <mass>` weighted conformity-count histogram lines (X = 0..32). Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SCORE_F5` | 0 | `=1`: score the 11 FROZEN F5 orientation-layer functionals per canonical leaf (below/at/above-KW weighted masses). Leaves are orientation-BEARING (the walk enumerates orientation branches pre-dedup) as the F5 preregistration §4 requires — canonical `solutions.bin` records are orient-dedup'd and must NOT feed F5 scoring. Ground truth / two-language gate: `--f5-verify` (+ `solve.py --vdb-verify` for #11). `=2` + `SOLVE_F5_TESTVEC`: cross-verification hook. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_F5_HIST` | 0 | `=1` (with `SOLVE_KNUTH_SCORE_F5=1`): additionally emit `f5_hist <name> <value> <mass>` full per-functional weighted value histograms. Estimator-only, sha-neutral. |
| `SOLVE_F5_TESTVEC` | unset | With `SOLVE_KNUTH_SCORE_F5=2`: evaluate the 11 F5 functionals on an explicit sequence (`"h0,h1,...,h63"`, hexagram VALUES not KW indices), print them comma-separated, exit. Verifies a non-lex-oriented sequence scores as itself (F5 preregistration §4 gate); also used for corpus/gauge control snapshots. Test-only, sha-neutral. |
| `SOLVE_KNUTH_SCORE_F6` | 0 | `=1`: score the 7 FROZEN F6 Nielsen-audit functionals per canonical leaf (below/at/above-KW weighted masses; Wu Deng warp/weft + [Jing Fang](CITATIONS.md#jingfang) bagong). Ground truth / two-language gate: `--f6-verify`. `=2` + `SOLVE_F6_TESTVEC`: explicit-sequence cross-verification hook. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_F6_HIST` | 0 | `=1` (with `SOLVE_KNUTH_SCORE_F6=1`): additionally emit `f6_hist <name> <value> <mass>` full per-functional weighted value histograms. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_RELAX_C5` | 0 | `=1`: relax C5 to C2-only in the Knuth walk (transition budgets unbounded except d=5 forbidden), so `leaves_C1C2C4C5` counts \|C1 ∩ C2 ∩ C4\| — used to price C5's marginal compression in DESCRIPTION_LENGTH.md (superseded for the headline number by the exact `--f1-exact-c1c2c4` DP). Estimator-only, sha-neutral. |
| `SOLVE_F1_OOC_READ_MB` | 256 | `--f1-out-of-core` (#221): read-window buffer size in MB for the bucketed streaming gather (auto-raised to fit one full predecessor span, auto-clamped to the previous layer's size). Sha-neutral. |
| `SOLVE_F1_OOC_SCRATCH_MB` | 1024 | `--f1-out-of-core` (#221): dense per-chunk gather-scratch budget in MB; sets how many targets are gathered per streaming pass (larger = fewer passes = less read amplification; the emit staging buffer scales with it, total RSS ~2.2x this value). For full-31 raise it (e.g. 16384 on a 64 GiB box) to keep per-layer read amplification tractable. Sha-neutral. |
| `SOLVE_F1_OOC_GAP_KB` | 1024 | `--f1-out-of-core` (#221): gap read-through threshold in KB — adjacent needed file spans closer than this are coalesced into one sequential read instead of a seek. Sha-neutral. |
| `SOLVE_F1_OOC_FORMAT` | `v2` | `--f1-out-of-core` (#223): per-layer file format. `v2` (default) = zlib-blocked (per-block RFC-1950 zlib, not gzip-framed `.gz` — [F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md)) with a kidx/vidx seek index (smaller disk + I/O). `v1` = raw uncompressed (pristine reference). The count is **format-invariant** → Sha-neutral. |
| `SOLVE_F1_OOC_GZIP_LEVEL` | 6 | `--f1-out-of-core` (#223, `v2` only): zlib compression level 1–9 for the per-block layer compression (the env name's "GZIP" is historical — the codec is zlib). Default 6 — measured knee (level 9 is ~2× slower for only ~3% smaller). **Level-invariant** → Sha-neutral. |
| `SOLVE_F1_CKPT_SEC` | 300 | `--f1-out-of-core` (#223): intra-layer checkpoint cadence in seconds. The DP snapshots a CRC32-guarded chunk-boundary marker (`f1c5_build.ckpt`) every interval; `--resume-from-layers` then resumes **mid-layer** from it after an interruption/eviction (not just at a layer boundary). Sha-neutral. |
| `SOLVE_F1_MAX_LAYER` | `n` (all layers) | `--f1-exact-c1c2c4c5` / `--f1-out-of-core` "PROBE MODE": stop the layered DP after layer `k=N` (clamped to `[1, n]`) instead of running to completion. Used for validation and partial builds (e.g. checking early-layer counts or exercising resume without a full multi-day run). Emits a `[f1] PROBE MODE` stderr line. A capped build is a partial count, not the published exact integer. Sha-neutral. |
| `SOLVE_F1_KEEP_LAYERS` | 0 | `--f1-exact-c1c2c4c5` / `--f1-out-of-core`: when `=1`, retain **every** layer file `0..n` instead of rolling the two-layer window (the default drops layer `k-2` as the window advances). The preserve-all-layers substrate for the knowledge-compiler query tool and a full on-disk ladder for archival. Peak disk becomes the **full** ladder (full-31: ~2.5–2.7 TB in the v2 zlib-blocked format — plan a 4 TB disk), not the ~1×-largest-layer transient. The flag only suppresses the `k-2` unlink; the count and the layer bytes are unchanged → **Sha-neutral**. Emits a `[f1c5] KEEP-LAYERS` stderr banner. |
| `SOLVE_F1_STREAM_COLD_CMD` | (unset) | `--f1-exact-c1c2c4c5` / `--f1-out-of-core`: operational archival hook. When set, the command is run on each about-to-be-deleted finalized layer file **before** the rolling-window `unlink`, invoked as `<cmd> <layer_path> <k>` — so a layer can be streamed to cold storage as the DP advances without keeping the whole ladder on local disk (contrast `SOLVE_F1_KEEP_LAYERS`, which keeps all layers). The hook's exit status is logged (`[f1c5] STREAM-COLD` / `STREAM-COLD WARNING`) but **non-fatal**: the DP continues and the local delete proceeds regardless. Fires only when the window would delete a layer (not under `KEEP_LAYERS`); the final two layers are never window-deleted, so grab those directly at the end. Purely off the arithmetic path → **Sha-neutral**. |
| `SOLVE_F1_PROGRESS_JSON` | 1 (on when a run dir exists) | `--f1-exact-c1c2c4c5` / `--f1-out-of-core`: emit `f1c5_progress.json` in the run dir, refreshed ~every 5 s and written **atomically** (temp + `rename`, so a reader never sees a torn write). Pure observability — reports `schema_version`, `phase` (`counting`/`finalizing_write`/`layer_complete`/`resuming`/`done`), `cumulative_count` (running partial count), the in-progress `layer{masks_target, masks_done, entries_done, bin_bytes_target/written, rates, eta}`, a `completed[]` per-layer table, and `resumes{}`. Set `=0` to disable. It only reads state the DP already tracks and writes a side file (best-effort; a failed emit never aborts the run) → **Sha-neutral**. |
| `SOLVE_SKIP_AUTO_VERIFY` | 0 | Auto-`solve --verify solutions.bin` after `--merge` (exit 30 on C1-C5 fail). |
| `SOLVE_MERGE_RUN_ANALYZE` | 0 | **Opt-in:** when `=1`, `--merge` forks `solve --analyze` after solutions.bin finalize and captures output to `solutions.analytics.txt`. Off by default because of the wall-time cost (~30 min at 11.2T, ~2-4h at 560T). Recommended ON for archival merges. |
| `SOLVE_ALLOW_MISSING_BUDGET_SIDECAR` | 0 | (existing, repeated for cross-reference) — also bypasses the per-shard `.budget` integrity gate for legacy shards. |
| `SOLVE_SKIP_IOPS_CHECK` | 0 | IOPS pre-flight gate (exit 31): skips the startup fsync-rate probe entirely. Recommended on every eviction-resume / post-`az vm start` launch (cold caches give noisy readings; the first-launch gate is authoritative). See #107/#115. |
| `SOLVE_ALLOW_SLOW_IOPS` | 0 | IOPS gate verdict (exit 31): runs the probe but proceeds even when the projected fsync-wall-fraction exceeds threshold (operator accepts the fsync-bound slowdown). |
| `SOLVE_SKIP_HOST_FINGERPRINT` | 0 | `canonical-host-fingerprint.json` write at canonical-enum startup (Tier 1 determinism-hardening provenance; #110). |

### Test / internal hooks (not for production use)

These variables exist for the test harness, the two-language cross-verification
gates, and the checkpoint kill-resume drills. They are **not** user-facing
features — they inject failures or feed explicit test vectors, and have no place
in a canonical or analysis run. All are sha-neutral. Listed here for
completeness and honesty, not as knobs to set.

| Variable | Default | Effect |
|---|---|---|
| `SOLVE_KILL_AFTER_NODES` | unset | Deterministic eviction-injection hook (#165): abort the enumeration after `g_kill_after_nodes` DFS nodes, simulating a Spot eviction at a fixed point so checkpoint/resume can be tested reproducibly. |
| `SOLVE_F1_KILL_AFTER_CHUNK` | unset (`-1`) | `--f1-out-of-core` deterministic kill hook: terminate the layer build after N emitted chunks, to exercise mid-layer `--resume-from-layers` recovery. |
| `SOLVE_F1_TEST_LAYER_DELAY_MS` | 0 | `--f1-out-of-core` per-layer artificial delay in milliseconds; widens the eviction window in resume drills / timing tests. |
| `SOLVE_F6_TESTVEC` | unset | With `SOLVE_KNUTH_SCORE_F6=2`: evaluate the 7 F6 functionals on an explicit 64-int sequence (`"h0,h1,...,h63"`), print them comma-separated in `f6_names` order, exit. Two-language test vector gating the C port against `solve.py` f6_* ground truth. |
| `SOLVE_REG_TESTVEC` | unset | With `SOLVE_KNUTH_SCORE_REG=2`: evaluate `score_registry` on an explicit 64-int sequence with W=1, print the 31 candidate-rule indicators (0/1, comma-separated, `REGISTRY_KW_EXPECTED` order), exit. Gates the C registry port against `solve.py` reg_* ground truth. |
| `SOLVE_PERM_TESTVEC` | unset | With `SOLVE_KNUTH_SCORE_PERM=2`: evaluate the 13 R3 perm functionals + 2 template-match indicators on an explicit 64-int sequence (`"h0,...,h63"`), print them, exit. Two-language test vector gating the C `perm_*` port against `solve.py` `perm_*` / `--perm-verify` ground truth. |
| `SOLVE_GZ_TEST_SHARDS` | 0 | `=1`: run a paranoid per-shard `gzip -t` CRC integrity test after each shard write (#169). Default OFF — a full decompress per shard roughly doubles compression CPU across ~65K shards, and the gzfwrite return-count + durable-close checks already cover write completeness. |

## EXIT STATUS

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | General failure (invalid args, constraint check failed, regression test FAIL) |
| 10 | I/O error (file not found, opendir failed, malloc failed) |
| 20 | Format error (file size not a multiple of 32 bytes; corrupted header; truncated record) |
| **21** | **Resume-state invariant violation** — `backtrack()` detected malformed `dfs_resume_partition_prefix_len` or `(pair_idx, orient)` frame out of `[0,31]×[0,1]`. Indicates checkpoint or `.dfs_state` is corrupted. Recovery: clear affected sub-branches' `.dfs_state` + `.bin` files and let LOAD path re-walk. (Phase E.2 defense, re-landed 2026-05-25.) |
| **22** | **Shard-manifest verify failed** — MISSING / SHRUNK / DIVERGED shard detected by `--verify-shard-manifest` or by the auto-verify at canonical-enum startup. Recovery: investigate the named shard; for MISSING / SHRUNK delete from manifest and let LOAD path re-walk; for DIVERGED do NOT trust the new content. |
| **24** | **Auto-selftest failed** — binary does not reproduce canonical selftest sha `403f7202…`. Compile toolchain regression. Recovery: rebuild with verified flags, investigate compiler/libc/optimizer differences. Override: `SOLVE_SKIP_AUTO_SELFTEST=1` only after investigation. |
| **25** | **Sub-canonical scale gate** — `SOLVE_NODE_LIMIT < 1T` without `SOLVE_PER_SUB_BRANCH_LIMIT` set (canonical-grade reproducibility requires ≥1T). Recovery: either raise `SOLVE_NODE_LIMIT` to ≥1T, OR set `SOLVE_PER_SUB_BRANCH_LIMIT` (partition-invariance use case), OR set `SOLVE_ALLOW_SUB_CANONICAL=1` (acknowledged sub-canonical run). |
| **26** | **Build provenance mismatch** — `build.sha` in cwd was written by a different binary than the current one. Recovery: restore the prior binary (continue cleanly), OR `SOLVE_ALLOW_BUILD_MISMATCH=1` + accept lineage-mix risk, OR `rm build.sha` and restart from scratch. |
| **27** | **LOCK file held by live process** — concurrent `solve` invocation on same cwd refused. Recovery: kill the conflicting process OR use a different cwd. Stale locks (dead PID or different hostname) auto-reclaimed. |
| **28** | **`--merge` cannot raise RLIMIT_STACK** — `setrlimit` could not raise to unlimited or to ≥64MB hard cap. External-merge spill would silently SIGSEGV. Recovery: run `ulimit -s unlimited` in shell before `solve --merge`. |
| **29** | **Disk-space pre-check failed** — projected required bytes for `SOLVE_NODE_LIMIT` exceed free bytes in cwd's filesystem. Recovery: move to a larger filesystem (`solver-data-westus3` has 2 TB free), OR `SOLVE_SKIP_DISK_CHECK=1` if you're confident the projection is wrong. |
| 30 | Logic error (decode failed mid-record; depth mismatch; iterator stack overflow) — or auto-verify-solutions FAIL after merge (C1-C5 violation). For auto-verify case: do NOT archive solutions.bin; investigate. |
| **31** | **Disk-IOPS pre-check failed** (task #107, retooled #115) — the projected fsync-wait would consume too large a fraction of the estimated enum wall (default cap 25%). The gate runs a **concurrent** probe (`min(threads,32)` pthreads measuring *aggregate* fsync/sec, so it adapts to the box — D64 vs D128 — and to the storage's real parallel throughput, not a single-thread number), projects expected fsyncs (`node_limit / 1.4e7 / SOLVE_FSYNC_BATCH_SIZE`) against estimated wall (`node_limit / (threads × 1e7)`), and refuses if `fsync_wait / est_wall > 0.25`. (The earlier revision gated on a raw single-thread "below 1000 fsync/sec" threshold, which mis-fired on Premium SSD — 218/sec single-thread but 2464/sec concurrent.) Canonical enum's per-shard/.budget/.dfs_state/per-thread-checkpoint fsyncs bottleneck on slow storage. The probe result is recorded in `canonical-host-fingerprint.json` under `disk_iops`. Recovery: put the run-dir on Standard/Premium SSD, OR `SOLVE_SKIP_IOPS_CHECK=1` (skip probe) / `SOLVE_ALLOW_SLOW_IOPS=1` (probe + proceed). |
| 50 | Self-test sha mismatch (regression) |

**Subcommand-specific exit codes** (distinct from the enum-path codes above):
- `--validate-canonical`: **33** sha mismatch, **40** enum error (in addition to 0/2/10).
- `--disk-precheck`: **5** identity mismatch (wrong disk), **6** insufficient capacity, **7** read-write smoke test failed (in addition to 0/1/2).
- `--preflight`: returns the first failing in-process gate's code (24 / 29 / 31), else 0.
- `--canonical-config` / `--validate-launcher-config`: **25** = unknown scale or bad arg count
  (distinct from the enum-path sub-canonical gate that also uses 25; disambiguated by which
  subcommand was invoked and by the stderr message — see those subcommands' sections).

## EXAMPLES

**Run the canonical 11.2T enumeration (matches sha `0c0fe37c…`):**

```
SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=11200000000000 SOLVE_PER_SUB_BRANCH_LIMIT=70723196 \
SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128 \
ulimit -s unlimited
solve 0 128
```

Wall: ~2.1h on D128als_v7. Output: `solutions.bin` (24.3 GB) +
sha256 + meta.json.

**Verify an existing canonical against the spec:**

```
solve --verify solutions.bin
```

Wall: ~30-60 min on D128 for the 100T canonical (102 GB).

**Quick visual sanity check (first 5 records as Unicode hexagrams):**

```
solve --show 5 --format glyph
```

**Reproduce a single first-level branch:**

```
SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=2000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=631456644 \
SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128 \
ulimit -s unlimited
solve --branch 4 0 0 128
```

**Merge shards into a final solutions.bin:**

```
SOLVE_TEMP_DIR=/mnt/work/merge_scratch
solve --merge
```

**Run the self-test gate before any commit:**

```
solve --selftest
# Expect: sha 403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e
```

**Two-path regression check (5.6T scale):**

```
SOLVE_REGRESS_DIR=/mnt/work/regress
solve --double-regression-test
```

## FILES

**Reads:**
- `sub_*.bin` — shard files (depth-2 or depth-3 naming) in CWD or
  the path implied by subcommand argument.
- `sub_*.bin.budget` — per-shard budget sidecar (one int64 per line:
  the `SOLVE_PER_SUB_BRANCH_LIMIT` under which the shard was last
  written). Read by `promote_orphaned_shards` to gate the orphan-
  promotion path; mismatch refuses promotion and forces re-walk
  through `.dfs_state` LOAD (Outlier #5 mitigation). Strict-default
  since 2026-05-25; override with `SOLVE_ALLOW_MISSING_BUDGET_SIDECAR=1`.
- `solutions.bin` (when verifying / analyzing / showing).
- `checkpoint.txt` (resume state for interrupted runs).
- `*.dfs_state` (per-sub-branch DFS-frame sidecars when
  `SOLVE_DFS_CHECKPOINT=1`).
- `build.sha` — sha256 of the binary that last touched this cwd.
  Read on canonical-enum dispatch; mismatch exits 26 unless
  `SOLVE_ALLOW_BUILD_MISMATCH=1`.
- `shard_manifest.txt` — auto-verified at canonical-enum startup
  (exit 22 on MISSING / SHRUNK / DIVERGED) unless
  `SOLVE_SKIP_AUTO_MANIFEST=1`.

**Writes:**
- `solutions.bin` — canonical sorted-deduplicated output.
- `solutions.sha256` — sha256 of solutions.bin, with optional metadata
  trailer (build sha, host, timestamp, `SOLVE_RESUME_HISTORY`).
- `solutions.meta.json` — record count, format version, encoding,
  generation timestamp, generator commit (when GIT_HASH was passed
  at build).
- `sub_*.bin` — per-sub-branch shards during enumeration.
- `sub_*.bin.budget` — per-shard budget sidecar (auto-written by
  `flush_sub_solutions` / `flush_sub_solutions_d3` after the shard
  rename).
- `sub_*.bin.provenance.json` — per-shard provenance sidecar
  (write-utc, binary sha, host fingerprint, budget, nodes explored,
  records emitted, status, append-only `writes[]` array tracking
  extension history). Auto-emitted by the same flush sites; auto-
  detects extension when prior `final_per_sub_branch_limit` < current.
  Task #102 (metadata equivalence) 2026-05-26.
- `solutions.provenance.json` — aggregate provenance written by
  `--merge` and by the full-enum auto-merge path. Rolls up
  shard-level provenance across the campaign (shard count by status,
  budget distribution, extensions observed, binary/git/host
  fingerprint sets, cumulative node + record counts, earliest +
  latest write UTCs). Comparable via `--compare-provenance`.
- `solutions.analytics.txt` — optional captured output of
  `solve --analyze solutions.bin` post-merge; opt-in via
  `SOLVE_MERGE_RUN_ANALYZE=1`.
- `results_P_O.json.<utc>.bak` — per-branch run analytics archive
  (auto-renamed before each `--branch` run's `results_P_O.json` to
  preserve extension-run history).
- `checkpoint.txt` — running enumeration state for resume.
- `progress.txt` — human-readable progress reporting.
- `solve.lock` — PID + hostname LOCK file. Held for the duration of
  any canonical-enum invocation; refuses concurrent invocations on
  the same cwd (exit 27). Stale locks (dead PID or different host)
  are auto-reclaimed. Override: `SOLVE_SKIP_CANONICAL_LOCK=1`.
- `build.sha` — sha256 of the running binary, written at canonical-
  enum startup if absent. Future invocations cross-check.
- `shard_manifest.txt` — auto-emitted after every `flush_sub_solutions`
  rename + after `promote_orphaned_shards` (unless
  `SOLVE_SKIP_AUTO_MANIFEST=1`).
- `solve.binary.snapshot` — copy of the running solve binary, captured
  at canonical-enum startup (unless `SOLVE_SKIP_BINARY_SNAPSHOT=1`).
  Forensic artifact for cross-build reproduction.
- `temp_sorted_*.bin` — external-sort chunks in `SOLVE_TEMP_DIR`
  during `--merge`.

**Note on temp file hygiene:** failed `--merge` runs may leave
`*.tmp` orphan files. solve.c's `--merge` skips them automatically
on retry (filtered at line 9528 of solve.c). External cleanup is
not required but is a disk-hygiene best practice.

## REPRODUCIBILITY

- The default action and `--branch` / `--sub-branch` produce
  byte-identical sha256 across hardware, region, thread count
  (above a minimum), and merge mode (in-memory vs external),
  given matching solver version and inputs. See
  [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) for the
  formal theorem.
- Canonical sha256 anchors are recorded in
  [CANONICAL_HASHES.md](CANONICAL_HASHES.md). The selftest sha
  `403f7202…` MUST be preserved by every commit; CI fails otherwise.
- `--verify` is a constraint check, not a sha check — it tests
  that the file's records satisfy the spec, regardless of which
  solver produced them.
- `--analyze` is non-deterministic in output formatting (some
  histogram reports use double precision); its raw counts are
  deterministic.
- `--prove-*` results are deterministic but do not produce
  sha-anchored artifacts.

## PERFORMANCE

Approximate wall-clock on D128als_v7 (Zen 5 Turin, 128 vCPU spot)
with `SOLVE_DFS_CHECKPOINT=1`:

| Subcommand / scale | Wall | Notes |
|---|---|---|
| `--selftest` | ~5 sec | Runs on 4 threads internally |
| `solve 0 128` at d3 11.2T | ~2.1 h | Tier 1 canonical |
| `solve 0 128` at d3 100T | ~11-19 h | 100T canonical; varies with sub-branch yield distribution |
| `solve 0 128` at d3 560T | ~3.5 days (171.5 h incl. eviction defers) | 560T canonical — completed 2026-06, re-verified 2026-06-30 (`9a968fa2…`, 10.525 B records) |
| `--branch p o 0 128` at d3 100T | ~12-15 min | One first-level branch |
| `--verify` on 102 GB solutions.bin | ~30-60 min | I/O bound on Standard HDD |
| `verify.py --jobs 128` on 102 GB | ~25-30 min | Python parallel verify |
| `--merge` on 60K shards (414 GB raw) | ~2-3 h | Standard HDD I/O bound |
| `--analyze` on 102 GB | ~30-60 min | OpenMP-parallelized |

Single-thread `--branch p o 0 1`: ~22M nodes/sec on Zen 5 Turin.
Multi-thread saturates at ~2.5B nodes/sec on 128 threads.

## SEE ALSO

- [SPECIFICATION.md](SPECIFICATION.md) — formal C1–C5 constraint definitions
- [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) — binary output format
- [CANONICAL_HASHES.md](CANONICAL_HASHES.md) — sha256 anchors
- [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) — reproducibility theorem
- [DEVELOPMENT.md](DEVELOPMENT.md) — build instructions + invariants
- [DEPLOYMENT.md](DEPLOYMENT.md) — Azure VM sizing + deployment patterns
- [BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md) — what branches and sub-branches mean
- `solve.py` — Python companion for analysis and verification (`verify.py`,
  distributional analysis subcommands, extended-selftest driver)

## NOTES

**Always set `ulimit -s unlimited`** before running large
enumerations or ASan-instrumented builds. main()'s frame can
exceed the default 8 MB stack limit at depth 3 with 128 threads.
A pre-`main()` constructor (added 2026-05-06 task #75) warns at
startup if RLIMIT_STACK is below the build's recommended threshold.

**Memory:** the hash table sizes at 2^N slots × 32 bytes per
thread, defaults to 512 MB/thread. At 128 threads that's 64 GB
of RAM. Need at least ~80 GB system RAM for safe operation at
the canonical budgets. D128als_v7 has 384 GB.

**Single C source file:** all functionality lives in `solve.c`
per the project's standing rule. No new `.c` files allowed; new
analysis tools become subcommands instead.

**License:** see [LICENSE.md](../LICENSE.md). solve.c links only to
glibc, pthread, m, and gomp. No third-party C dependencies.

## HISTORY

Recent material changes (full record in [HISTORY.md](HISTORY.md)):

- 2026-05-26 Metadata equivalence retool (task #102) landed:
  - Per-shard `.provenance.json` sidecar (append-only `writes[]` array;
    captures budget, nodes, records, status, binary sha, host fingerprint,
    write-utc per write; auto-detects extension on subsequent writes)
  - Aggregate `solutions.provenance.json` written by `--merge` and
    full-enum auto-merge (campaign-level rollup; comparable across paths)
  - `--compare-provenance A.json B.json` subcommand for structural
    equivalence (normalizes timestamps + host fingerprints)
  - `SOLVE_MERGE_RUN_ANALYZE=1` opt-in for post-merge `--analyze` capture
  - Per-branch `results_P_O.json` archived to `.<utc>.bak` on extension
    runs (preserves first-write analytics)
- 2026-05-25/26 v3.1 hardening + dummy-proof defaults landed:
  - Sub-canonical hard-gate (exit 25) on `SOLVE_NODE_LIMIT < 1T`
  - LOCK file `solve.lock` (exit 27)
  - `build.sha` provenance gate (exit 26)
  - `.budget` sidecar strict-default (Outlier #5)
  - Auto-emit + auto-verify `shard_manifest.txt` (exit 22) with new
    `--emit-shard-manifest` / `--verify-shard-manifest` subcommands
  - Phase E.2 resume invariants re-landed (exit 21)
  - Auto-selftest on canonical-enum startup (exit 24)
  - Auto-raise `RLIMIT_STACK` at `--merge` (exit 28)
  - Auto-`solve --verify` after `--merge` (exit 30 on C1-C5 fail)
  - Disk-space pre-check (exit 29)
  - `solve.binary.snapshot` capture
  - `SOLVE_DFS_ITERATIVE` + `SOLVE_DFS_CHECKPOINT` default to 1 at
    canonical scale (`SOLVE_NODE_LIMIT >= 1T`)
  - `SOLVE_RESUME_HISTORY` env var for forensic continuity notes
- 2026-05-07 added `--show` for visual sample inspection
- 2026-05-06 fixed all_top stack-buffer-overflow at line 12058
  (#54); selftest sha `403f7202…` preserved
- 2026-05-06 added pre-main constructor `check_stack_ulimit()`
  (#75) to warn on insufficient RLIMIT_STACK
- 2026-05-04 added C3 complement-distance check to `--verify`
  (#66)
- 2026-05-01 fixed `completed_sub_key` bit overlap in depth-2
  resume path (commit d11bc0d); depth-3 was unaffected
- 2026-04 11.2T canonical established (sha `0c0fe37c…`); 100T
  canonical established (sha `915abf30…`)
