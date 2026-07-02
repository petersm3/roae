# solve(1) — King Wen sequence enumerator and verifier

A man-page-style command-line reference for the `solve` binary compiled
from `solve.c`. Covers every subcommand, all environment variables,
exit codes, and common workflows.

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
- `25` — unknown scale or bad arg count.

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
> gz-aware (#169), sha-preserving (post-enumeration analysis, no enumeration-path impact). See MCKENNA.md for context.

```
solve --verify-rule2 [solutions.bin]
```

McKenna Rule 2 audit (cf. *The Invisible Landscape*, Chapter 9): for
each record, count value-1 transitions and check whether each occurs
at a "C2-forced position" — i.e., the orient-flip alternative for
the surrounding pair would have produced a value-5 transition. King
Wen's two value-1 transitions occur only at such C2-forced positions
per McKenna; this subcommand measures the violation rate across an
arbitrary solutions.bin. Sha-preserving (post-enumeration analysis,
no impact on the enumeration code path). See MCKENNA.md for context.

### --verify-9th-six

> ✅ **Live subcommand** — dispatched by `solve.c` (task #156). gz-aware (#169),
> sha-preserving (post-enumeration analysis). See MCKENNA.md for context.

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
N; exponential at deeper N. Limited by `PROVE_CONFIG_TIMEOUT` env var.

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
| `PROVE_CONFIG_TIMEOUT` | unlimited | Wall-time limit for `--prove-*` exhaustive walks |
| `PATH` | inherited | Used to locate `solve` binary for self-spawning subprocesses |
| `SOLVE_SKIP_AUTOMERGE` | 0 (off) | `=set` (any value): skip the automatic `--merge` at enum completion; leave shards in place. Used for split enum/merge campaigns (separate right-sized merge VM) and the #149 milestone-staging ladder. |
| `SOLVE_FSYNC_BATCH_SIZE` | 1 | Batch N checkpoint fsyncs per flush to amortize fsync cost on fsync-bound disks (#108b). Higher = fewer fsyncs, larger replay window on crash. |
| `SOLVE_MANIFEST_THREADS` | `SOLVE_THREADS` | Override the thread count for the parallel `shard_manifest.txt` sha256 sweep (#116). |
| `SOLVE_DISK_MARKER` | (none) | Custom marker filename for `--disk-precheck` to test free space against (otherwise a default probe path is used). |

### Hardening overrides (2026-05-25/26 — every gate has an explicit escape)

All hardening gates fire by default on canonical-enum dispatch (no `--xxx` subcommand). Each can be individually suppressed via env var. Suppressing a gate is operator-acknowledgment that they understand the failure mode being bypassed.

| Variable | Default | What it disables |
|---|---|---|
| `SOLVE_ALLOW_SUB_CANONICAL` | 0 | Sub-canonical hard-gate (exit 25): allows `SOLVE_NODE_LIMIT < 1T` without `SOLVE_PER_SUB_BRANCH_LIMIT` set. Output sha will be code-specific (see HISTORY.md "100B canonical drift" 2026-05-25). |
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
| `SOLVE_KNUTH_SCORE` | 0 | `=1`: `--estimate-knuth` additionally reports weighted canonical-mass fractions for externally-attributed candidate rules — R-C1 final-pair anchor + R-C2 first-7 level coverage (Cook 2006), R-C5 18:18 split (Zheng Qiao ~1150 / Hu Yigui 1247 / Hacker & Moore 2003 / Cook 2006), R-M1 pair-positioning parity (Moore 2005). See CITATIONS.md §Attributed candidate rules. Estimator-only; sha-neutral (2026-07-02). |
| `SOLVE_SKIP_AUTO_VERIFY` | 0 | Auto-`solve --verify solutions.bin` after `--merge` (exit 30 on C1-C5 fail). |
| `SOLVE_MERGE_RUN_ANALYZE` | 0 | **Opt-in:** when `=1`, `--merge` forks `solve --analyze` after solutions.bin finalize and captures output to `solutions.analytics.txt`. Off by default because of the wall-time cost (~30 min at 11.2T, ~2-4h at 560T). Recommended ON for archival merges. |
| `SOLVE_ALLOW_MISSING_BUDGET_SIDECAR` | 0 | (existing, repeated for cross-reference) — also bypasses the per-shard `.budget` integrity gate for legacy shards. |
| `SOLVE_SKIP_IOPS_CHECK` | 0 | IOPS pre-flight gate (exit 31): skips the startup fsync-rate probe entirely. Recommended on every eviction-resume / post-`az vm start` launch (cold caches give noisy readings; the first-launch gate is authoritative). See #107/#115. |
| `SOLVE_ALLOW_SLOW_IOPS` | 0 | IOPS gate verdict (exit 31): runs the probe but proceeds even when the projected fsync-wall-fraction exceeds threshold (operator accepts the fsync-bound slowdown). |
| `SOLVE_SKIP_HOST_FINGERPRINT` | 0 | `canonical-host-fingerprint.json` write at canonical-enum startup (Tier 1 determinism-hardening provenance; #110). |

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
