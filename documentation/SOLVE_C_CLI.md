# solve(1) — King Wen sequence enumerator and verifier

> **CLI references:** this documents the **`solve` C binary** (compiled from `solve.c`). See also [`solve.py`](SOLVE_PY_CLI.md) (analysis + ground truth) · [`roae.py`](ROAE_PY_CLI.md) (descriptive analyses) · [`sat.py`](SAT_CLI.md) (SAT / certificate layer).
>
> **Access boundary.** Some subcommand entries cite design, pre-registration, or incident files in
> `roae-private`, the project's private staging repository, which is not publicly accessible. Those
> citations are provenance (what was frozen, when, and why a gate exists), not evidence a reader can
> fetch — a fact whose only cited support is a `roae-private` file is operator-attested. Every
> subcommand documented here is runnable from this repository as published; where an entry names a
> frozen private pre-registration, the checkable public leg is the subcommand's own embedded
> expected values and its two-language gate.

A man-page-style command-line reference for the `solve` binary compiled
from `solve.c`. Covers the subcommands, environment variables,
exit codes, and common workflows. The SYNOPSIS below lists the principal
forms; every subcommand also has its own section under SUBCOMMANDS below,
**except the `--kc-*` family** (the v4-compiler knowledge-compiler branch
tools), which is documented in-source in `solve.c` (see the KC and KC-H
module headers) by branch convention — the SYNOPSIS lists only their
entry points.

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
solve --validate [solutions.bin] [--expect-kw]          # C1-C5 + sort + dedup enforced; KW reported (fatal under --expect-kw); VALIDATE=PASS|FAIL
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
solve --regression-test [budget]                        # partition-invariance check at one budget
solve --double-regression-test [budget]                 # layered full-enum vs 56-branch sha equivalence
solve --kde-score-stream --fit-file PATH --d N --bandwidth BW --threshold T
                                                        # streaming KDE scorer
solve --emit-shard-manifest [manifest_path]             # write a manifest for sub_*.bin in the CWD
solve --verify-shard-manifest [manifest_path]           # check a manifest vs the CWD's shards
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
solve --kc-enum-desc DIR [--kc-c3-max T] [--kc-limit M] # REL-DESCENDING in-order enumeration (TR12 Q2 LAST^C15)
solve --kc-enum-desc-selftest                           # its n=9 exhaustive brute-force gate
solve --kc-profile FDIR GDIR "e,x,..."|KW               # per-step rarity/surprise profile of a walk (TR12 Q3/EW-1/V4)
solve --kc-profile-selftest                             # its n=9 exhaustive brute-force gate
solve --kc-scan F G OUT.chunk.json --kc-layers A B      # chunked partial atlas over HALF-OPEN layers [A,B)
solve --kc-scan-merge F G OUT.json CHUNK.json ...       # reassemble chunks; PROVES coverage; byte-identical atlas
solve --kc-layers-selftest                              # its n=9 chunk/merge gate (byte-identity + rejections)
solve --kc-extremal FUNC DIR max|min [--kc-witness]     # TR12 Q5 DP extremal sweep + witness (G-invariance gated)
solve --kc-extremal list                                # print the functional registry
solve --kc-extremal-selftest                            # its n=9 exhaustive brute-force gate
solve --check-arrangement "h0,...,h63"|KW               # first-principles C1..C5 verdict (H3a/CAP-2)
solve --check-arrangement-selftest                      # its KW/historical/mutation battery
solve --verify-certificate CERT.json [--kc-mutate]      # H6 certificate re-verifier + non-vacuity battery
solve --rc1c-verify [SEQ]                               # R6 circular anchor-adjacency (R-C1c) gate (KW A2={21,42})
solve --r11-verify [SEQ]                                # R11 frozen 8-axis violation-bundle gate (KW 2,2,2,0,0,0,0,0)
solve --validate-canonical <sha256> <scale>             # pre-campaign drift gate
solve --estimate-knuth <N> [<p1> <o1> ...]              # Knuth random-probe tree-size estimator
solve --knuth-dump-prefix <depth> <seed>                # dev utility: emit a random VALID deep prefix
solve --c3-dist [solutions.bin]                         # C3 complement-distance histogram
solve --f1-exact-c1c2c4 [--layers-dir DIR]              # exact |C1∩C2∩C4| orbit DP
solve --f1-exact-c1c2c4c5 [--f1-pairs N] [--f1-out-of-core DIR]
                                                        # exact |C1∩C2∩C4∩C5| orbit DP
solve --f1-exact-c1c2 --f1-mod P [--f1-start-orbit 0..5|all]
                                                        # exact-mod-P |C1∩C2| (start unpinned)
solve --f1-c3-hist [--f1-pairs N] [--with-c5] [--no-c2] # exact C3 G-histogram (uncapped)
                                                        # G≤95 cumulative = exact |C1∩C2∩C3∩C4|
solve --f1c5-gzip-selftest | --f1c5-verify-layer <v1> <v2>
                                                        # f1c5 layer-codec self-test / cross-check
solve --f1c5-layer-sha FILE|DIR [FILE|DIR ...]          # sha256 of a layer's DECOMPRESSED stream (f/g/t ladders)
solve --f1c5-layer-cmp FILE_A FILE_B                    # decompressed-stream layer byte-compare (f/g/t ladders)
solve --f1c5-sidecar-retrofit DIR [DIR ...]             # regenerate catalog layer-stats sidecars
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

### --help / -h

```
solve --help
```

Print a short orientation: the build line, the `--selftest` check, and the
handful of common modes (`--verify`, `--validate`, `--estimate-knuth`,
`--list-branches`, `--branch`, `--merge`). The listing is deliberately not
exhaustive; this document is the full reference. One caveat on "full": until
2026-09-01 five variables the binary reads had no mention here at all — the
Purdom/fiber estimator controls `SOLVE_KNUTH_PURDOM_W`,
`SOLVE_KNUTH_PURDOM_DEPTH`, `SOLVE_KNUTH_FIBER`, `SOLVE_KNUTH_FIBER_XCHECK`
and `SOLVE_KNUTH_FIBER_PERM` (solve.c:19000 ff.). They are named here now, but
they still have no row in the ENVIRONMENT tables below; read them out of
`solve.c` directly. Every other `SOLVE_*` variable `solve.c` reads is
documented in this file (measured 2026-09-01 by diffing every
`getenv("SOLVE_*")` against the names appearing here). Exits 0.

Added 2026-08-28. Until then there was **no** `--help` handler and no
unknown-argument rejection at the top level: any unrecognised first argument
fell through to the default enumeration, so `./solve --help` acquired
`solve.lock` and started an unbounded full run. An unrecognised leading
`--option` is now rejected with an error (pointing here) instead of silently
enumerating.

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
- `threads` — number of pthreads to use. Default `nproc`, clamped to the
  sub-branch count and to a 256 ceiling (solve.c:26433-26443). *(Corrected
  2026-09-01: this line previously capped the default at 128.)*

Output sha matches a canonical entry in
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) iff inputs (env vars +
solver version) match. Mismatch **within the tested toolchain class**
(see [DEVELOPMENT.md](DEVELOPMENT.md):945) is a bug, not a new result;
across toolchain classes, see the scope note under REPRODUCIBILITY below.
*(Qualifier added 2026-09-01.)*

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

Exits 0 on PASS and **40** on a sha mismatch (`solve.c:18031`, "validation
mismatch"). *(Corrected 2026-09-01: this line previously gave 1 and the EXIT STATUS table
gave 50 for the same failure; the binary returns neither.)*

### --selftest-resume

```
solve --selftest-resume
```

Resume-correctness gate (distinct from `--selftest`). Runs a 50M-node
enumeration to completion, **extends the budget** by re-running the same
directory at 200M so the second pass resumes from the `.dfs_state`
checkpoint, and compares the result against a clean single-shot 200M run in a
fresh directory. Guards the budget-upgrade-resume / asymmetric-extension code
path that canonical extensions (e.g. 560T → 1120T) rely on.

> ⚠️ **It sends no signal.** All three phases are `system()` calls allowed to
> exit normally at their node limit, each checked with `if (rc != 0) return
> 40`; there is no `kill`, no SIGTERM, and no termination during a checkpoint
> write anywhere in the block (solve.c:18405-18452). So it does **not** cover
> interruption or eviction recovery. The real SIGTERM-mid-walk exercise is
> elsewhere in this tree: `solve.py` extended-selftest **subtest 8**
> ("single-branch eviction-resume invariance"), which calls `proc.terminate()`
> during a `--branch` walk and then resumes — solve.py:6502-6535.
> *(Corrected 2026-09-01: this paragraph described the gate as interrupting
> the run and as covering eviction recovery.)*

Any commit touching the checkpoint format or resume logic MUST keep this
passing (see the checkpoint-format merge gate). Exits 0 on PASS, non-zero
on FAIL.

### --selftest-resume-d3

```
solve --selftest-resume-d3
```

Depth-3 **hard-kill**/resume sha-equivalence mini-gate (2026-07-17). The
depth-3 sibling of `--selftest-resume`, covering what that gate does not:
`--selftest-resume` exercises depth-2 budget-**extension** resume, while
canonical campaigns run depth-3 with hard-kill (Spot-eviction / SIGKILL)
resume. Runs two legs at a pinned deterministic shape (depth 3, 4 threads,
`SOLVE_PER_SUB_BRANCH_LIMIT=10000`, `SOLVE_NODE_LIMIT`≈1.58B,
iterative+checkpoint, fsync batch 16, `SOLVE_SKIP_AUTOMERGE=1` + explicit
`--merge` per leg): leg A uninterrupted; leg B interrupted mid-run by the
`SOLVE_KILL_AFTER_NODES` (#165) SIGKILL hook (default twice), then resumed
to completion. PASS iff both merged `solutions.bin` gz-aware shas match.

Knobs (defaults in parentheses): `SOLVE_D3_GATE_ENGINE` (self — path of the
solve binary to drive, enabling cross-build regression discrimination),
`SOLVE_D3_GATE_THREADS` (4), `SOLVE_D3_GATE_PSB` (10000),
`SOLVE_D3_GATE_NODE_LIMIT` (1583640000), `SOLVE_D3_GATE_KILL_NODES`
(130000000), `SOLVE_D3_GATE_KILLS` (2), `SOLVE_D3_GATE_TMPBASE` (`/tmp`;
use `/dev/shm` on low-IOPS OS disks). Sub-canonical scale ⇒ shas are
code-specific: legs compare within one engine build only, never across
builds. Exits **0** PASS / **41** sha mismatch (regression signal) /
**42** vacuous (kill never fired or no frontier existed) / **40** leg or
merge infrastructure failure / **10**/**30** setup errors. On FAIL the
two run dirs are kept for evidence.

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
solve --preflight [node_limit]     # default 560000000000000 (= 560T nodes)
```

In-process pre-flight aggregator (2026-05-28). Runs every gate solve.c
can check from inside its own process — auto-selftest (sha
`403f7202…`), disk-space projection, disk-IOPS probe — in report mode,
**without running the enum**. One command to confirm a campaign VM is
ready. Run it FROM the campaign run-dir (the gates check the cwd).

`node_limit` is a **bare node count**, not a scale token. It is parsed
with `atoll` (solve.c:18668), which stops at the first non-digit and
does not reject the remainder: `--preflight 560T` is taken as
`NODE_LIMIT=560` and `--preflight 11.2T` as `11`. Pass the integer
(`560000000000000`, `11200000000000`), or omit the argument and take the
built-in default `560000000000000` (solve.c:18668).

Does NOT cover what lives outside the process: VM/eviction/cost (the
external monitor, task #55), full disk SMART/fsck
(`scripts`-side `disk_health_precheck.sh`), or disk identity (use
`--disk-precheck`).

Exit codes are two, but the outcomes are three — read them with that in
mind:

- **0**, printed as `RESULT: all in-process gates PASS.` — emitted **only when all three gates
  actually RAN** (see below).
- the first failing gate's exit code (**24** / **29** / **31**), printed
  as `RESULT: FAIL - first failing gate exit N. Do NOT launch.`
- **2** for a refused argument, or for a run in which any gate was **SKIPPED**.

> ✅ **SKIPPED is now a distinct verdict, and a bad argument is refused (landed 2026-09-04,
> Codex v2 `solve.c:18678`).** This section previously described two defects as open; both are
> closed and the description below is what the code now does.
>
> **The argument is parsed strictly.** It is a node **count**, not a scale label: `560T` and
> `560Q` are *not* parsed. They used to be silently truncated by `atoll` to 560 and 0
> respectively, which turned a typo into a green light for a budget nobody asked about. Any
> trailing character now gives `PREFLIGHT=REFUSED-BAD-ARG` and exit 2. Pass
> `560000000000000`.
>
> **Skipped gates are counted and named.** Each of the three gates returns 0 unconditionally when
> `node_limit` is sub-canonical (< 1T), which is indistinguishable from a pass — so
> `./solve --preflight 560` used to print `RESULT: all in-process gates PASS` having executed
> **nothing**. The dispatcher now applies that same threshold itself, prints
> `-> SKIPPED (sub-canonical: ...)` per gate, and emits whole-line `PREFLIGHT_GATES_RAN=<n>` and
> `PREFLIGHT_GATES_SKIPPED=<n>` tokens. When anything was skipped the verdict is
> `RESULT: N gate(s) SKIPPED — this preflight attests NOTHING at this budget` with exit 2, and
> the all-PASS line is not printed at all.
>
> **Still read the per-gate lines.** A gate can also decline for reasons the dispatcher cannot
> see — its `SOLVE_SKIP_*` override, or the check being unavailable (`statvfs` fails; the probe
> cannot create files or threads; `/proc/self/exe` is unreadable). Those still report as
> `PASS (rc=0)`; each prints its own loud `SKIPPED` line to stderr. Gates:
> `tests.py::TestSolveCliHardeningTokens`, both legs red-tested against the pre-fix binary.

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

Config introspection (2026-05-28). Dumps build provenance — `git_hash`,
`build_source_sha`, `canonical_selftest_sha256` and an ISA pointer
(solve.c:19554-19558) — then a **fixed, hand-maintained subset** of `SOLVE_*`
variables with each one's effective value (its value, or `(unset)` = built-in
default in effect). Purpose: when a future change drifts the canonical sha,
the config delta for the covered variables is **explicit** rather than
reverse-engineered.

> ⚠️ **Coverage is partial, and the omissions are sha-relevant.** Measured on
> this tree by diffing the printed rows against every `getenv("SOLVE_*")` in
> `solve.c`: the binary **reads 101** distinct `SOLVE_*` variables and
> **prints 35** — **66 are omitted**. Among them are `SOLVE_COMPRESS`,
> `SOLVE_GZIP_LEVEL`, `SOLVE_HASH_LOG2`, `SOLVE_MERGE_TEMP_GZIP_LEVEL`,
> `SOLVE_MERGE_THREADS` and `SOLVE_SKIP_TEMP_SPACE_CHECK`, plus the whole
> `SOLVE_KNUTH_*` estimator surface and the `SOLVE_F1_*` layer surface. No
> printed variable is one the binary never reads, so the list is a stale
> subset rather than a wrong one — but a config dump omitting two-thirds of
> the surface cannot on its own support a reproducibility claim. Read it
> together with this document's ENVIRONMENT section, and record compile-time
> choices separately. Build **date/time are not printed either**, contrary to
> what this section used to promise. Generating the printed list from the
> source at build time is an open code change.
> *(Corrected 2026-09-01: this section previously promised build date/time and
> complete coverage of the `SOLVE_*` surface.)*

Complements `--cpu-features` (ISA) and the
`canonical-host-fingerprint.json` sidecar (host env). Compile-time choices (LTO/PGO/-march/AVX-512) are not
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
set -a; eval "$(./solve --canonical-config 100T)"; set +a
SOLVE_THREADS=128 ./solve 0 128
```

`set -a` is load-bearing: `--canonical-config` emits **bare** assignments
(`printf("SOLVE_DEPTH=%d\n", …)`, solve.c:19624) with no `export`, so a plain
`eval $(…)` creates shell variables that the child `./solve` never sees.
Measured on this tree: after `eval $(./solve --canonical-config 100T)`,
`$SOLVE_DEPTH` is `3` in the shell but `env | grep -c '^SOLVE_'` is **0**;
with the `set -a` form it is **3**. *(Corrected 2026-09-01.)*

Exit 0 on success; exit 25 on unknown scale or missing arg. Sha-neutral:
argv-dispatched, never on the enum path. No enumeration; exits immediately.

Motivated by the 2026-06-12 PSB math error (see
`petersm3/roae-private:LESSONS_LEARNED_2026_06_12_PSB_MATH_ERROR.md`)
where two re-derive launchers shipped with PSBs re-derived from a wrong
floor formula, costing ~$15 of compute and ~16h of wall before being
caught against the recipe table.

### --estimate-knuth

```
solve --estimate-knuth <N_probes> [<p1> <o1> [<p2> <o2> ... up to <p28> <o28>]]
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
`nproc`); each thread uses a **distinct** xorshift seed, derived as
`base ^ ((i+1) * 0x9E3779B97F4A7C15)` (`solve.c`).

⚠ **[CORRECTED 2026-09-03 — this read "an independent xorshift seed" (Codex v2,
lane B sibling sweep).]** Distinct is not independent, and the distinction is
mechanical rather than pedantic: **xorshift64 has a single cycle of length
2⁶⁴−1**, so seeding threads differently chooses different *starting points on the
same orbit*, not different streams. Two threads whose start points happen to fall
within one thread's consumption of the cycle will replay the same values, and
nothing in the estimator detects that. The overlap probability is negligible at
the scales run here (~10⁻⁵ pairwise at the headline budget), so **no published
figure is affected** — but the guarantee the old word implied does not exist, and
a reader sizing a much larger run should know which property they actually have.
A genuinely independent construction would need a generator with provably
disjoint substreams, which this is not.

- No prefix → the whole C1–C5 tree (all 56 first-level branches).
- A `<p> <o>` prefix (up to **28** levels, e.g. `22 0 30 1 20 0`) scopes the estimate
  to one branch / sub-branch.
- `N_probes = 0` → **exact deterministic** subtree count instead of estimation
  (only tractable for a deep prefix; used to validate the estimator against
  ground truth — matches to <1 % at prefix depths 22/24/26).

> ✅ **Output-honesty fixes landed 2026-09-04** (Codex v2 `solve.c:8073`, `:8136`,
> `:8137/:8093/:8149`, `:8341`, `:8343`). All are estimator-only and sha-neutral.
>
> **`CI=UNAVAILABLE` and `STARVATION` replace two CIs that were never meaningful.** Every
> interval now uses the **sample** variance (divisor `N-1`, not `N`) — the old intervals were
> biased narrow, worst exactly where it matters. At `N < 2` the variance is undefined and the
> code used to print an interval anyway: at `N=1` a zero-width `95%CI=[x, x]` with
> `relerr=0.00%`, which reads as infinite precision rather than as no information. It now prints
> `CI=UNAVAILABLE (N<2 probes)`. And **`est=0` with `0` hits is a sampling artifact, not a
> bound** — it now prints `STARVATION (0 hits in N probes)` and no interval, because none is
> meaningful. Measured at `N=2`: `relerr` moves 28.06 % → 39.68 % on `tree_nodes` (the honest,
> wider interval) and the two leaf layers switch from `95%CI=[0,0]` to `STARVATION`. The fiber
> layers had **no hit counters at all** and now have them. All three emission sites go through
> one helper, because three sites drifted apart once and would again.
>
> **The reported probe count is now the count that RAN.** `pthread_create`'s return was
> discarded, and the denominator was built from the *planned* quota, so a worker that never
> launched still contributed its full share while running nothing — a silently biased number at
> exit 0 (measured 2× low under a create-failing preload). Both `pthread_create` and
> `pthread_join` are checked (`ESTIMATOR=ABORTED-WORKER-LAUNCH`, exit 70), the denominator comes
> from a worker-side executed-probe counter, and a `KNUTH-PROBES planned=<n> executed=<n>` line
> plus a whole-line `KNUTH_PROBES=EXECUTED-EQ-PLANNED` token is printed. A shortfall is fatal.
> The one legitimate zero — a strict-dead prefix, where no probe *should* run — is named
> `KNUTH_PROBES=SKIPPED-DEAD-PREFIX` rather than lumped in with a failure.
>
> ⚠ **Exact mode (`N_probes = 0`) does NOT support the strict walk predicates, and now says so.**
> `exact_count()` prunes on C1/C2/C5 only — it has no Moore-parity, Moore-rhythm or
> Schulz-gender predicate. Two consequences, both now fixed. It **ignored its own dead-prefix
> guard**: with a strict flag set and a prefix that violates it, the code printed
> `STRICT-PREFIX DEAD … reporting zero estimates` and then printed *non-zero counts* directly
> beneath — worse, it spent unbounded time enumerating a subtree it had just proven empty
> (measured 2026-09-04: the pre-fix binary did not finish an 11-level dead prefix in 120 s; the
> fixed one returns zeros instantly with `EXACT_COUNT=DEAD-PREFIX`). And on a *live* prefix it
> silently counted the **unrestricted** subtree while strict flags were active, so the
> "validation anchor" validated a different tree than the estimator was sampling. That
> combination is now **refused** — `EXACT_COUNT=REFUSED-STRICT-UNSUPPORTED`, exit 2 — rather
> than implemented, because duplicating the worker's predicate logic in a second place is how
> the R11 gate-2 defect arose. Unset the strict flags, or use the sampling estimator, which does
> implement them. **Supported matrix:** exact mode ⟂ strict flags (refused); sampling mode ×
> strict flags (supported); either mode × a plain prefix (supported).

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
- `25` — **unknown scale (a typo)** or bad arg count. Stderr lists the scales
  that carry a published PSB, generated from the recipe table itself. (Note:
  exit 25 is also used elsewhere by the sub-canonical hard-gate —
  `SOLVE_NODE_LIMIT < 1T` without `SOLVE_PER_SUB_BRANCH_LIMIT` set and without
  `SOLVE_ALLOW_SUB_CANONICAL=1`; see the Hardening overrides table. The two uses
  are distinguished by the stderr message and by which subcommand was invoked.)
- `34` — **known scale, nothing to validate.** The scale is real and
  `--canonical-config` resolves it, but it publishes no per-sub-branch budget, so
  there is no PSB to check. Currently only `d2-10T`: depth-2 mechanics do not use
  one, and a launcher targeting it must not set `SOLVE_PER_SUB_BRANCH_LIMIT` at
  all. **This is not an error condition** — a launcher pre-flight should treat 34
  as "proceed without a PSB", not as an abort.

  *Added 2026-08-29 (Q-345). Before that, a known-but-PSB-less scale fell through
  to the `25 unknown scale` path and was reported with the byte-identical message
  and exit code as a typo, while `--canonical-config` resolved the same scale
  cleanly — so the two subcommands disagreed about whether it existed. A
  pre-flight that reports "unknown scale" for a real configuration fails **open**
  for any caller that does not inspect the exit code, which is the whole point of
  a pre-flight. Q-324 corrected the documentation; this corrects the code beneath
  it.*

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
foundation+bw+vpopcntdq triple that a **future** v2 dispatcher would require.

> ⚠️ **This build has no vectorised path.** The subcommand's own header says
> it reports capability "used by *future* AVX-512 runtime dispatch" with "no
> behavioral change to canonical enumeration" (solve.c:19717-19726), yet on a
> capable host it prints a YES verdict asserting a vectorised path will be
> selected
> (solve.c:19745-19746). Measured on this tree: `solve.c` contains 17
> `avx512`/`AVX-512` strings and **zero** occurrences of `_mm512_*`,
> `immintrin.h`, or `__attribute__((target(...)))` — there is no vectorised
> path to select, so a YES here does not explain throughput. Rewording that
> printf is an open code change. *(Doc corrected 2026-09-01: this sentence
> previously attributed the triple, in the present tense, to a dispatcher that
> exists in this build.)*

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
boost. This subcommand IS the pre-flight probe; the project's campaign launcher
calls it directly and logs `[--cpu-freq] cores=... below=N`. (This line
previously named a companion script that does not exist in this repository.
Corrected 2026-08-09.)

No enumeration; instantaneous. Exits 0 if HEALTHY, 1 if any core is
below threshold, 2 on I/O error.

### --extended-selftest (solve.py, NOT a solve C subcommand)

```
solve.py --extended-selftest <path-to-solve-binary>
```

A `solve.py` command (the `extended_selftest` function in solve.py) — **not** a `solve`
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

Parallel (OpenMP + mmap) whole-file checker: per-record C1-C5,
strict-ascending sort order, and King Wen presence. Unlike
`--verify` it has no headerless-shard fallback — it requires a
valid `ROAE` header and aborts on bad magic or unknown version.

> ⚠️ **King Wen presence is reported, not enforced — in *both* checkers.**
> `kw_found_v` is printed (`solve.c:37978` for `--validate`, `:37536` for
> `--verify`) and is folded into neither verdict: `--validate` returns
> `errors > 0 ? 1 : 0` (`solve.c:37992`) and `--verify`'s `total_fail`
> (`solve.c:37559`) sums C1-C5, decode, sort and dup only. Measured on this
> tree: an artifact with the King Wen record deleted and its header count
> patched prints `King Wen present:  No` and `ALL CONSTRAINTS VERIFIED`,
> exiting **0** — and `--verify` on the same file also exits 0. Sort order and
> cross-record duplicates *are* enforced (the sorted-order loop increments
> `errors` at `solve.c:37872`); the same fixtures, deliberately unsorted or
> carrying an adjacent duplicate, both exit **1**. So treat the KW line as a
> banner and check it by eye.
>
> **`--expect-kw` closes the open change, opt-in (added 2026-09-04).** Both checkers now accept
> `--expect-kw`, mirroring `verify.py --expect-kw`: with it, King Wen's absence is folded into the
> verdict and the run exits non-zero; without it, behaviour is exactly as described above. Both
> **`--validate` now emits `VALIDATE=PASS|FAIL` too (added 2026-09-04).** Until then it had **no
> `KEY=value` verdict token at all** — only the prose `Result: ALL CONSTRAINTS VERIFIED`, which a
> harness could gate on only by matching output *shape*. That is the failure that cost this project a
> run once already, when a monitor grepped `"SEARCH COMPLETE"` against a solver writing
> `"SEARCH_COMPLETE"` (`HISTORY.md`). Both prose lines are unchanged and kept for human readers;
> `grep -qx VALIDATE=PASS` is now the machine-readable sibling. `--verify` has emitted
> `VERIFY=PASS|FAIL` since it was written.
>
> print a whole-line `KW_REQUIRED=YES|NO` token so a log says which contract was in force. It is
> **not** the default, and must not become one: the "expect exactly one canonical KW record per
> file" rule was retracted 2026-09-02 (registry `RP-60347080`) because a shard or a budgeted slice
> legitimately lacks the record, and `tests.py`'s `TestSolveVerifyKingWenScope` pins the
> reported-not-enforced default with a mutation test that goes red on exactly that change.
>
> ⓘ **Line citations in this box were re-measured 2026-09-04 and five were stale** — they read
> `:21451`, `:21063`, `:21456`, `:21065`, `:21359`, which now land in unrelated KC walk and RNG
> code (`:21451` is a `memcmp`, `:21359` a `kc_splitmix64` call). `solve.c` grew by roughly 16,500
> lines between the citation and this reading. The claims themselves were all still true; only the
> coordinates had moved. The two `solve.c:21051/:21439` references below are NOT tree coordinates
> and were left alone: they are the Codex adjudication's own identifiers for the finding, used the
> same way in the engine comment at `solve.c:37538`.
>
> `--validate`'s runtime banner also used to list "King Wen presence" among the things it
> *checks*, which contradicted this note; corrected 2026-09-04 (Codex v2 `solve.c:21051/:21439`).
> The behaviour was always deliberate — the promise was the defect. *(Added 2026-09-01;
> extended 2026-09-04.)*

**Not a superset of `--verify`.** `--verify` already checks sort
order and duplicates (and reports King Wen presence — see the note
above; neither checker enforces it), and it is *stronger on
duplicates*: `--verify` compares adjacent records with
`compare_canonical` (orient bits masked), so it detects
orientation-variant duplicates — the class this format is
deduplicated by. `--validate` only flags records that compare
equal under `compare_solutions`, i.e. byte-identical ones, so a
file carrying two orient variants of the same canonical ordering
passes `--validate` and fails `--verify`. `--validate` also stops
at the first ordering violation, while `--verify` counts them all.
Run both: treat `--verify` as the dedup authority and `--validate`
as the fast parallel constraint sweep over large files.
*(Corrected 2026-08-01, solve.c sweep: this section previously
called `--validate` a "stricter version of `--verify`".)*

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
per McKenna; this subcommand measures the violation rate across the
records a `solutions.bin` **declares**. Sha-preserving (post-enumeration
analysis, no impact on the enumeration code path). See [MCKENNA.md](MCKENNA.md) for context.

> ⚠️ **Input-trust limits — these apply equally to `--verify-9th-six`
> and `--verify-wrap-parity`.** The three audit readers are tabulators,
> not validators; they trust the artifact more than `--verify` does.
>
> - **Framing is not checked.** The record count comes from the header
>   (solve.c:18071) and the read loop is bounded by it (solve.c:18088),
>   with no comparison against the file's logical size. The Q-277
>   invariant — logical size == 32-byte header + 32 bytes per declared
>   record — landed in `--verify` only (solve.c:20915); the three audit
>   readers were not swept. Measured on this tree: a 96-byte artifact
>   whose header declares 1 record but carries 2 reports `records=1`,
>   scans only the first, and prints `RULE2=TABULATED` — likewise
>   `NINTH_SIX=PASS` and `WRAP_PARITY=PASS` — with the surplus record
>   silently unexamined, while `--verify` on the same file prints
>   `VERIFY=ERROR`.
> - **Pair indices are not bounds-checked.** A record byte decodes to
>   `pidx = (rec[i] >> 2) & 0x3F`, range 0-63 (solve.c:18101), and
>   indexes `pairs[]`, which has 32 entries (solve.c:443), with no
>   `pidx < 32` guard. Measured: a one-record artifact whose first byte
>   is `0x80` (pidx 32) reads past the array and still prints a normal
>   `RULE2=TABULATED` at exit 0.
>
> So run these on artifacts `--verify` has already accepted; on a
> hand-crafted or corrupt file their verdicts are not trustworthy.
> Adding the framing invariant and the `pidx` bound to all three readers
> is an open code change.

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
in Chapter 9). Sha-preserving. Subject to the input-trust limits noted
under `--verify-rule2` above — unchecked framing, unchecked
`pidx` bound.

### --verify-wrap-parity

```
solve --verify-wrap-parity [solutions.bin]
```

Tabulates the wrap-around parity of every record — whether the value between the
last and first hexagram is odd (d=1/3 split) — and reports the odd/even fractions
and the d=1 vs d=3 breakdown. At the 560T canonical, 100% of records are odd-wrap
(91.83% d=3, 8.17% d=1). gz-aware (#169), sha-preserving (post-enumeration analysis).
Subject to the input-trust limits noted under
`--verify-rule2` above — unchecked framing, unchecked `pidx` bound.

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
tier-1 (T1) axes plus the g7, g8 tier-2 (T2) axes. (**"tier-1/tier-2" here is the
*scoring-axis class* — T1 = principled rules stated ahead of the data, T2 = data-like rules — and
is unrelated to the campaign "Tier 1" of the 11.2T canonical in the wall-clock table below, or to
the "Tier 1 determinism-hardening" of `SOLVE_SKIP_HOST_FINGERPRINT`. The archived evidence files
`dav_tier1.out`, `f5_tier1.out` and `perm_tier1.out` all carry *this* sense.) Without an argument, computes each
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
Numerology and Cosmology*; Goldenberg encoded from the primary text (official
ILL scan read 2026-07-11; all five encoded claims G-T1..T4, T7 verified
first-hand), with [Hacker, Moore & Patsco (2002)](CITATIONS.md#hacker-moore2002) B:154
the entry that first surfaced the theorem statements. *(Source status
corrected 2026-09-01: this sentence previously graded the attribution as
annotation-only with the primary source still unread — a status the
attribution block at solve.py:9682-9685 and the ledger entry at
[CITATIONS.md](CITATIONS.md):1855 had already superseded on 2026-07-11.)* Prints one PASS/FAIL line per claim
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
N ∈ {3,4,6,7,9,10,12,13,15,16,18,19,21,22,24,25,27,28,31} (default 31 = full
run at KW's budget). Sha-neutral.

A rung must be a union of WHOLE pair-orbits, and the orbit sizes are
{3,3,3,4,6,6,6}, so that set is exactly the realizable pair counts — the other
twelve values (1,2,5,8,11,14,17,20,23,26,29,30) are not expressible at all and
are rejected. Note nothing lies strictly between 28 and 31: the smallest orbit
is 3, so the largest proper union is 31−3 = 28. Sizes 3,4,6,7,10,12,15,21,22
were added 2026-08-09; sizes 9…28 are the historical validation unions whose
counts are published in [TR-11 §4b](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md).
Several distinct unions can share a size (127 unions in all); `--f1-pairs`
selects one per size, so it does not reach the alternatives.

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

### --f1-exact-c1c2

```
solve --f1-exact-c1c2 --f1-mod P [--f1-start-orbit 0..5|all] [--f1-subset "L.I,L.I,..."]
```

**Exact-mod-P** count of |C1 ∩ C2| with the **start unpinned** (E1, 2026-07-25):
complete 64-hexagram sequences built from the 32 KW pairs (C1), no Hamming-5
adjacent transition (C2), and **no C4 start pin**. This is a *distinct quantity*
from `--f1-exact-c1c2c4` above: that DP seeds only the C4-pinned start (first
pair Qian/Kun = (63, 0)) and delivers |C1 ∩ C2 ∩ C4| as a full-precision
192-bit integer; `--f1-exact-c1c2` seeds layer 1 with *every* (pair,
orientation) start and delivers the larger start-free count |C1 ∩ C2| — but as
a residue mod a chosen prime. Three runs at distinct 63-bit primes plus offline
CRT reconstruct the exact integer (rigorous, since |C1 ∩ C2| ≤ |C1| =
32!·2³² ≈ 1.13×10⁴⁵ < p₁p₂p₃). Purpose: remove the last sampled figure in the
C2-rarity chain (the "~4.3% of pair-constrained orderings" estimate in
[SPECIFICATION.md](SPECIFICATION.md)).

Method: the #215 orbit-quotient layered DP with a complement-extended
48-element mask-quotient group (lifted by XOR-63, a Hamming isometry that maps
the KW pairing to itself) and mod-P `uint64` values, which shrink the peak
footprint to ~13.1 GB (fits an 8-core/15 GB box, vs ~39 GB for 192-bit
counters at this quotient).

- `--f1-mod P` — **required**. The modulus: a decimal odd prime with
  2 < P < 2⁶², primality checked at startup (deterministic Miller–Rabin). A **missing** `--f1-mod` is a usage error
  (exit 2); a *malformed, even, out-of-range or composite* P fails the startup `F1_CHECK` assertion and
  exits **71** (the `F1_CHECK` macro in `solve.c`), as does an invalid `--f1-start-orbit` value.
- `--f1-start-orbit 0..5|all` (default `all`) — restrict the layer-1 seed to
  one of the six ⟨G48, XOR-63⟩-orbits of the 64 possible first-pair exit
  hexagrams (census asserted at startup: sizes {2,12,24,8,6,12}, representatives
  {0,1,3,7,12,13}). Per-orbit totals sum to the start-unpinned count. The
  start-orbit-0 run doubles as the full-scale validation gate: it must
  reproduce 2 × the `--f1-exact-c1c2c4` exact integer, reduced mod P.
- `--f1-subset "L.I,L.I,..."` — restrict to a union of extended-group
  pair-orbits (`1.0,3.0,4.0,6.0,6.1,12.0`; validation rungs). In subset mode an
  internal plain-DP cross-check runs when n ≤ 16 and the exit code reflects its
  PASS/FAIL.

Prints per-layer `[f1u]` telemetry to stderr and final
`F1U RESULT ... residue=<r>` / `F1U DONE` lines to stdout. Exit 0 on success
(including a passing subset gate), 1 on a subset-gate mismatch, 2 on usage
errors. Test/probe-only env knob (never on enum paths):
`SOLVE_F1U_MAX_LAYER=K` stops after layer K completes (memory/timing probe;
partial result, exit 0). Sha-neutral (argv-dispatched, never on the
enumeration path).

### --f1-c3-hist

```
solve --f1-c3-hist [--f1-pairs N] [--with-c5] [--no-c2] [--layers-dir DIR | --f1-out-of-core DIR] [--resume-from-layers]
```

The **C3 "G-channel"** (BACKLOG-2a): augments the orbit-DP state with the
running C3 slot-gap sum G — `C3 = 16 + 8·G` universally over C1-valid
orderings (`c3_slot_decomposition`, machine-checked in
`lean/C3Decomposition.lean`; KW has G = 95, so `C3 ≤ 776 ⟺ G ≤ 95`,
inclusive) — and emits the **exact final-layer G-histogram**. The mode is
**uncapped** (no G-prune): the histogram answers *every* threshold at once,
and its `G ≤ 95` cumulative (`G_HIST_CUM_LE_95`) is the derived exact
**|C1 ∩ C2 ∩ C3 ∩ C4|** under the default base. Bases:

- default (no flags): **C1 ∩ C2 ∩ C4** (the C5 residual is disabled, rid ≡ 0)
  — the BACKLOG-2a production base. Gate: the histogram total must equal the
  `--f1-exact-c1c2c4` count (full-31: 7.5706…×10⁴¹).
- `--with-c5`: keeps the exact C5 boundary-budget residual (#217 semantics) —
  the rung-validation base; totals must reproduce the published rung counts
  (n=9 → 26,112; n=13 → 2,063,395,607,040; n=16 → 267,765,117,419,520 —
  verified 2026-07-22).
- `--no-c2`: drops the C2 adjacency test — the **C1 ∩ C4 null** gate base. At
  full-31 the histogram must equal 2³¹ × the exact null G-distribution:
  support exactly [12, 228], `E[G] = 128` (asserted in-binary as the integer
  identity `WSUM == 128 × TOTAL`), and
  `P(G ≤ 95) = 641983711307479 / 7919632354008375` exactly. Mutually
  exclusive with `--with-c5`.

Key packing keeps **28 B/entry**: `key32 = (gofs << 22) | (last << 16) | rid`
with `gofs = g + 496` (10 bits; running |g| ≤ 496 for every rung). The cost
of the channel is an *entry-count* multiplier only — measured uncapped
multipliers vs the rid-free base at the validation rungs: ~5–6× (n=9), ~10×
(n=13), ~17–19× (n=16), rising with the achievable G-width (a full-31 run
should expect substantially more; measure, don't extrapolate). Storage,
checkpointing, `--f1-out-of-core`, the v2 zlib-blocked layer format, and the
intra-layer checkpoint are all inherited from #217/#221/#223 unchanged, under
distinct layer magics (`F1C3LAY1`/`F1C3LAY2`/`F1C3BLD1`) and a manifest
`gmode=` line, so a G-run and an f1c5 run can never resume from each other's
directories (hard abort in both directions). All `SOLVE_F1_*` env knobs apply.

Built-in gates (hard aborts): KW witness at init (static couple slot-gap sum
= 95 AND the incremental open/close accumulator over KW's walk = 95); every
gathered g inside the per-layer worst-case band (printed at startup); at
full-31, support within the proven [12, 228], per-bin **mod-48 divisibility**
(the free 48-action — the order-48 lift, since `rev` flips orientation and fixes
no sequence — preserves G, so it acts on every G-fiber and each fibre is a
disjoint union of 48-orbits; applied under **either** base, i.e. no longer
skipped under `--no-c2`. Was mod-24 and C2-on-only until 2026-08-10; both limits
were weaker than the space affords, and were lifted on measurement of 987 bins
across six runs and two bases with zero exceptions), and the G=95 bin populated. Output: one `G_HIST g=<g>
count=<exact>` line per nonzero bin plus `G_HIST_TOTAL`, `G_HIST_WSUM`
(Σ g·count) and `G_HIST_CUM_LE_95`. Sha-neutral (argv-dispatched, never on
the enumeration path; the #215/#217 kernels are untouched).

### --f1-dec-selftest

```
solve --f1-dec-selftest        # reads "l2 l1 l0" triples on stdin
```

Renders 192-bit limb triples through the real `f1_dec()` and prints
`l2 l1 l0 <decimal>` for each. It carries **no expected values of its own** — the
battery and the arithmetic live in `verify.py --f1-dec-roundtrip`, so this mode
cannot pass by containing the answer.

Why it exists: `f1_dec()` renders every exact count this project publishes, up to
the 40-digit `|C1∩C2∩C4∩C5|`, but its only end-to-end exercise was the n=9 rung
total **26112** — five digits, entirely inside limb 0. The multi-limb carry in
`f1_divmod_small()` had no proof at any width. Argv-dispatched and never on the
enumeration path, so the canonical `--selftest` sha is unchanged.

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

### --f1c5-layer-sha

```
solve --f1c5-layer-sha FILE|DIR [FILE|DIR ...]
```

Prints, for each f1c5 layer file, the sha256 of its **decompressed logical
stream** — `masks[nm] | off[nm+1] | keys[ne] | vals[ne]`, exactly the bytes the
v2 layer reader yields to the DP, inflated in order through the same per-block
codec the engine uses (CR-3b, 2026-07-16). Because the digest is defined on
decompressed bytes, it is **immune to zlib version/level byte differences** in
the compressed file: the same layer written at `SOLVE_F1_OOC_GZIP_LEVEL=1` and
`=9` (raw-byte shas differ) produces the same `--f1c5-layer-sha`. Both formats
are accepted — a **v1** raw (`F1C5LAY1`) and **v2** per-block-gzip (`F1C5LAY2`)
layer of the same build digest identically (for v1 the logical stream *is* the
file body after the 72-byte header, so `tail -c +73 file | sha256sum`
reproduces the digest independently). **Stage-G g-ladder layers** (`F1C5GLY1`/
`F1C5GLY2` magic, `g_layer_NN.bin`) and **Stage-T t-ladder layers**
(`F1C5TLY1`/`F1C5TLY2`, `t_layer_NN.bin`) share the identical binary format
and are accepted the same way (operator g-ladder directive, 2026-07-17; t
added with the t-ladder). The layer
header is not digested. This is the zlib-independent registration digest for
Stage-F, Stage-G **and Stage-T** layer ladders (V2 layer-sha registration).

Output per file: `sha256(decompressed) <hex>  <file>  (kind=f|g|t, blocks=N, bytes=M)`
where `kind` reports the ladder family from the magic, N is the number of
compressed blocks inflated (0 for v1) and M the decompressed logical byte
count. A DIR argument expands to its `f1c5_layer_NN.bin`, `g_layer_NN.bin`
**and** `t_layer_NN.bin` files in layer order. The digest itself is computed by the
system SHA-256 tool (`sha256sum` / `shasum -a 256` — the project's standard
external digest mechanism), streamed with bounded memory (one block in
flight). Integrity checks (block-size match, index monotonicity, exact file
size) mirror the resume loader's; truncation or corruption fails loudly. Exit
0 on success, 2 on file/tool error, 30 if no SHA-256 tool is on PATH.
Sha-neutral (argv-dispatched, never on the enumeration/count path).

### --f1c5-layer-cmp

```
solve --f1c5-layer-cmp FILE_A FILE_B
```

Byte-compares the **decompressed logical streams** of two layer files (f1c5
`F1C5LAY1/2`, Stage-G g-ladder `F1C5GLY1/2`, or Stage-T t-ladder
`F1C5TLY1/2`), streaming both in lockstep
with bounded memory (CR-3b, 2026-07-16; g acceptance 2026-07-17). Formats
and compression levels may differ (v1 vs v2, or v2 written at different zlib
levels) — equality is defined on the logical stream, so this is the
zlib-independent equality check for Stage-F/G layer comparisons. Comparing an
f layer against a g layer prints a kind-mismatch warning but proceeds. On
mismatch it reports the **first divergence offset** in the decompressed
stream, the section it falls in (`masks`/`off`/`keys`/`vals`) with the element
index, and the differing byte values; a length divergence reports which stream
ended first and at what offset. Exit 0 identical, 1 divergent, 2 error.
Sha-neutral.

### --f1c5-sidecar-retrofit

```
solve --f1c5-sidecar-retrofit DIR [DIR ...]
```

Regenerates the **catalog future-proofing layer-stats sidecars**
(`<pfx>_layer_stats_NN.json`) for every retained f1c5/g/t layer in DIR, using
DIR's manifest for context, in hash-chain order (f ascending, g and t
descending layer index). Each sidecar records: log2-bucketed value histograms,
entries-per-mask and exact branching-factor distributions, per-layer u192 mass
marginals grouped by `last` and by budget vector (rid) in the
canonical-quotient frame, the top-16 heaviest/lightest states with
identities, numerical-headroom telemetry (peak u192 magnitude vs the 192-bit
overflow guard), and a **decompressed-stream sha256 hash chain** (own layer +
input layer, same digest as `--f1c5-layer-sha`) making the ladder
self-authenticating.

**Schema v2 (2026-07-18, future-proofing for the full-31 t-ladder)** adds:
a `channels` self-description array (channel name + unit string — the format
hook for future multi-channel co-scheduled runs); a rolling `chain_sha256`
(`sha256(chain_prev_hex || own_sha_hex)`, genesis = `sha256(own_sha_hex)`) so
any single sidecar pins its whole lineage; `full_entries` — the complete
(mask, last, rid, value) dump for layers with ≤ 4096 entries (branch roots and
genesis layers; lets the Exhaustion Atlas assemble from sidecars alone);
`orbit_size_census` (mask-count and entry-count per G-orbit size — the
quotient-frame/raw-frame expansion record); runtime provenance (`threads`,
`gzip_level`, `rss_peak_mb`, `utc_epoch`, `host_fingerprint`, and on the
out-of-core build paths `build_wall_s` per layer); for g/t layers built
out-of-core, `x_input_sha256` — the f-layer own-sha whose mask domain the
layer rode (cross-ladder provenance); and two sanitized env passthroughs,
`SOLVE_SIDECAR_CONVENTION_CERT` (e.g. the t-unit node-convention certificate
sha) and `SOLVE_SIDECAR_PROVENANCE` (free-form launcher note), recorded as
`convention_cert` / `provenance_note` when set. All scalar/provenance keys
stay in the JSON head (first 8 KB, the head-key reader contract); the large
arrays are tail-emitted. v1 keys and their formats are unchanged;
`--kc-ladder-verify` cross-checks are key-scoped and pass on both versions.
Known boundary unchanged: cd (C3) is not part of the DP state, so C3-value
distributions remain non-retrofittable re-runs by design. Builds emit these sidecars automatically at every layer
commit (the Stage-F f-build, Stage-G g-build and Stage-T t-build, in-memory
and out-of-core; `SOLVE_F1_LAYER_SIDECARS=0` disables); this subcommand retrofits
ladders built before the feature or with the gate off. Emission is structurally
byte-neutral (read-only on layer bytes; writes only separate `.json` files,
atomically) and non-fatal (any sidecar failure warns, never aborts a build).
Known boundary: extended-state questions (e.g. exact C3-value distributions)
are **not** retrofittable from these aggregates — they are re-runs by design.
Exit 0 ok, 2 error, 30 if no SHA-256 tool is on PATH. Sha-neutral.

### --check-arrangement

```
solve --check-arrangement "h0,h1,...,h63"|KW [--cert-out FILE]
solve --check-arrangement-selftest
```

**First-principles constraint verdict** for an explicit 64-hexagram
arrangement (values 0–63; `KW` = the built-in King Wen sequence) — the
H3a/CAP-2 claim-verifier (TR-12 Q7). Deliberately an **independent
re-implementation** of C1–C5 inside the KC-H module (self-contained; derives
the pair-partner table and C5's distance multiset from the KW array alone;
calls nothing on the enumeration path), so it can serve as a cross-check
against `verify.py`/`solve.py` and the enum predicates rather than
restating them. Reports, in the **pinned check order C1→C2→C3→C4→C5**:
per-constraint HOLD/FAIL with first-offending detail, the exact C3
complement-distance value (ceiling 776), the boundary-distance histogram,
the first violated constraint, and BOTH space verdicts — SUPER
(C1∧C2∧C4∧C5, the compiled walk superspace) and C15 (SUPER ∧ C3≤776).
`--cert-out` writes a JSON arrangement certificate re-verifiable (and
mutation-testable) via `--verify-certificate`. The selftest battery covers
KW (IN, C3=776 exactly), a distinct IN member (orientation-flip variant),
single-constraint violations (reversed KW = C4 only), and the three
historical arrangements (Fu Xi, Jing Fang, Mawangdui — all OUT with pinned
expected profiles incl. Mawangdui's single d=5 seam and C3=2048). Exit
**0** = IN (C15), **1** = OUT, **2** = parse/usage. Sha-neutral.

### --verify-certificate

```
solve --verify-certificate CERT.json [--kc-mutate]
                                     [--kc-fdir F] [--kc-gdir G]
                                     [--kc-ooc] [--kc-cache-mb MB]
```

**H6 one-command certificate re-verifier.** Reads a JSON certificate emitted
by the H-tier tools and **re-derives every claim** from the referenced
dirs/files, fail-closed per check. Supported types: `roae-h3b-rank-certificate`
(from `--kc-o3-cert`: rank3/m/orient_idx/class_first recomputed via the O3
ranker, unrank roundtrip, neighbor bracket re-unranked + re-ranked +
strict-order-checked via the independent comparator, N/pl_hash/n
cross-checked), `roae-h1-oracle-certificate` (from `--kc-oracle`: every input
file re-streamed, stream shas + all tallies + verdict compared), and
`roae-arrangement-certificate` (from `--check-arrangement`: full recompute).
`--kc-fdir`/`--kc-gdir` override the ladder paths recorded in the
certificate (e.g. after a dir move). `--kc-mutate` runs the **non-vacuity
mutation battery** ("test the test"): after the baseline verification
passes, every certificate field is mutated in memory and the verifier must
CATCH each mutation; any uncaught mutation fails the run. Outputs are
certificates, not proofs. Exit **0** verified (and, with `--kc-mutate`, all
mutations caught) / **1** any mismatch or uncaught mutation / **2**
usage/parse/open errors. Sha-neutral. The `--kc-*` H-tier family
(`--kc-oracle`, `--kc-ladder-verify`, `--kc-o3-cert`, `--kc-scan`,
`--kc-scan-merge`, `--kc-ar2`, `--kc-enum-desc`, `--kc-profile`,
`--kc-extremal` + their selftests, including `--kc-enum-desc-selftest`,
`--kc-profile-selftest`, `--kc-layers-selftest` and
`--kc-extremal-selftest`, and the modifiers `--kc-tsv` / `--kc-alts` /
`--kc-layers` / `--kc-witness` / `--kc-json` / `--kc-gdir`) is documented
in-source in the KC/KC-H/KC-P/KC-X module headers in `solve.c`, per the
`--kc-*` convention.

### --kc-enum-desc

```
solve --kc-enum-desc DIR [--kc-c3-max T] [--kc-limit M]
                         [--kc-ooc] [--kc-cache-mb MB]
solve --kc-enum-desc-selftest
```

Descending in-order enumeration over the compiled f ladder in `DIR` (TR-12
§8 item 6, query Q2). It is the **same** enumerator as `--kc-enum` with every
choice loop reversed — one implementation, one direction flag — so it has the
identical argv surface, needs only the f ladder (no g ladder), and honours
`--kc-c3-max` / `--kc-limit` / `--kc-ooc` / `--kc-cache-mb` identically.

Element *r* of the descending stream is element *N−1−r* of the ascending one.
Consequently `--kc-limit 1` emits the **last** walk in the order, and
`--kc-enum-desc DIR --kc-c3-max T --kc-limit 1` emits `LAST^C15` — the
counterpart of the `FIRST^C15` that `--kc-enum … --kc-limit 1` already gives.
The C3 in-path prune is direction-independent (`partial_cd` is a monotone
lower bound on the prefix), so the admissible set is identical either way.

**Order label — this matters and must not be dropped when quoting a result.**
The order is **REL** (reverse-exit lexicographic: walks ordered by
`(exit_n, exit_{n-1}, …, exit_1)`), the compiler's native descent order. It is
**not** O3, the citable order. Every emitted `#provenance` line says
`order=REL-DESCENDING`. O3-order endpoints come from
`--kc-o3-unrank FDIR GDIR 0|N-1`, which needs both ladders. Publishing a REL
endpoint as "the last solution" without the order label conflates two
different orders.

Output is the usual one-walk-per-line `entry,exit,entry,exit,…` stream,
followed by a `#provenance` line (engine, git, source sha, `n`, order label,
`object=WALK`, and the `space=` label — `C1C2C4C5-SUPERSPACE`, or
`C1C2C4C5+walk-cd<=T` when `--kc-c3-max` was passed) and the verdict token
`KC_ENUM_DESC=OK` (`KC_ENUM_DESC=FAIL` on an open/parse failure). Exit **0**
ok / **2** usage or ladder-open error.

`--kc-enum-desc-selftest` is the reduced-n gate: it builds an n=9 ladder in a
scratch directory and cross-checks the descending stream against the
independent forward brute enumerator and an independent reverse-exit-lex
comparator — count, exact element-wise reversal of the ascending stream,
strict REL-monotonicity, the `--kc-limit 1` extremes at both ends, the
C3-filtered mirror, and an end-to-end leg that re-invokes the real binary so
the argv wiring itself is gated. It prints one `PASS`/`FAIL` line per gate and
ends with `KC_ENUM_DESC_SELFTEST=PASS` or `=FAIL`; exit **0** / **1**. It runs
in well under a second, is argv-dispatched only, and is **never** reached from
`--selftest` (whose output is sha-pinned).

### --kc-profile

```
solve --kc-profile FDIR GDIR "e,x,..."|KW [--kc-tsv OUT.tsv] [--kc-alts]
                                          [--kc-ooc] [--kc-cache-mb MB]
solve --kc-profile-selftest
```

The TR-12 §1 **Q3** rarity/surprise profile of an **arbitrary** walk — the data
behind **EW-1** (the surprise-localization ledger) and figure **V4**
(`viz_kc_shells.md`). One row per prefix step *k*: the pair placed, `f` and `g`
at the node reached, the completions still remaining, and the surprise measure
Q3 defines. `FDIR` is an f (forward) retained-layers dir, `GDIR` the matching g
(suffix-DP) ladder; **both are required** — `f` comes from the first, everything
else from the second. The walk argument is `"e,x,e,x,…"` (2·n values) or the
literal `KW` (full-31 ladders only).

Q3's definitions, in the terms the columns use: with `s_i` the walk's prefix
state after *i* placements, `g(s_i)` is the exact number of completions
remaining, `f(s_i)` the number of prefixes reaching that state, and
`p_i = g(s_i) / Σ_{c admissible at s_{i−1}} g(s_{i−1}∘c) = g(s_i)/g(s_{i−1})`
(the denominator equals `g(s_{i−1})` by the DP recurrence). The self-check
`Π p_i = 1/N` follows by telescoping from `g(s_0)=N` and `g(s_n)=1`.

**Columns** (tab-separated; a label line, then a real header row, then *n* data
rows):

| column | meaning |
|---|---|
| `step` | 1-based prefix step *k* |
| `pair` | global pair label of the pair placed |
| `entry`, `exit` | the two hexagrams placed, in order |
| `orient` | 1 if the exit is the pair's `pa` element, else 0 |
| `dclass` | boundary distance class of the transition, in {1,2,3,4,6} |
| `alts` | number of admissible successors at `s_{k−1}` with ≥1 completion |
| `f` | `f(s_k)` — prefixes reaching that state (quotient count) |
| `g` | `g(s_k)` — completions remaining (V4's "neighborhood shell") |
| `g_parent` | `g(s_{k−1})` |
| `p_num`, `p_den` | `p_k` as an **exact** rational: `g(s_k) / g(s_{k−1})` |
| `bits` | `−log₂ p_k`, EW-1's surprise bar — **display-only double** |
| `g_alt_min`, `g_alt_max` | V4's optional band: min/max `g` over the step's alternatives |
| `choice_rank` | 1-based rank of the chosen alternative's `g` among the alternatives, **descending g** (1 = the walk took the fattest branch) |

**Tie rule for `choice_rank`, pinned because EW-1 quotes this column:** ties in
`g` are broken by `(global pair label, orient)` **ascending**.

`--kc-alts` additionally emits one `#alt` row per admissible successor per step
— Q3's "g of each alternative" in full. It is off by default because at n=31
step 1 alone has up to 62 alternatives. `--kc-tsv OUT.tsv` writes the label
line + header + data rows to a file through the **same writer** used for
stdout, so the file is the stdout block verbatim (this is the artifact TR-12
files as `tr12/q3_profile_kw.tsv`).

**Order / object / space labels.** There is no ranking here: rows follow the
walk's own path, labelled `order=NATIVE-WALK-PATH`, `object=WALK`,
`space=C1C2C4C5-SUPERSPACE`. `p_k` is a conditional probability under the
**uniform measure on SUPER**, and `g` counts SUPER completions.

**`--kc-c3-max` is refused, not ignored** (exit **2**). A C3-conditioned
profile is not computable (the C3 counting obstruction); Q3's C15 companion is
a *sampled* rejection correction and rides `--kc-sample`.

**Exactness.** `p_k` ships as the exact rational `p_num/p_den`; nothing is
verified through the floating-point `bits` column. The product self-check is
not floating point either — `KC_PROFILE_PRODUCT=EXACT` attests the conjunction
`g(s_0) == N` **and** `g(s_n) == 1` **and** `Σ over alternatives of g ==
g_parent at every step`, which telescopes to `Π p_i = 1/N` exactly. Reader-side
arithmetic over `p_num`/`p_den` is a separate obligation (TR-12 §R step 7): the
columns are emitted so the reader can multiply the rationals out independently
rather than take the engine's word for it.

Output ends with `#profile-summary` (the two endpoint checks, the flow-identity
count, `sum_bits` vs `log₂N`), a `#provenance` line, then
`KC_PROFILE_PRODUCT=EXACT|MISMATCH` and `KC_PROFILE=OK|FAIL`. Exit **0** ok /
**1** invalid walk or a failed exactness check (no rows are emitted for an
invalid walk) / **2** usage, ladder-open, or a rejected `--kc-c3-max`.

**Relationship to `--kc-o3-rank --kc-trace`.** The O3 ranker's trace covers the
`p_i` / `bits` columns and the product self-check, but it discards the
alternatives' individual `g` values, has no `choice_rank`, emits `#`-prefixed
diagnostic rows rather than the TSV deliverable, and only runs as a side effect
of a full O3 rank. `--kc-profile` recomputes the profile **independently** from
f/g point lookups alone — no frontier, no `kc_o3_mass`. Its gate then requires
**row-for-row agreement** between the two, so the two implementations
cross-check each other inside one binary.

`--kc-profile-selftest` is the reduced-n gate: it builds n=9 f and g ladders in
a scratch directory and cross-checks six fixed witness walks (REL rank 0,
`N−1`, `⌊N/2⌋`, plus three seeded ranks) against the exhaustive brute
enumeration of all 26,112 walks — P1 the flow identity and every alternative's
`g` against brute prefix-completion counts, P2 the `g` column, P3
`orbit(cm)·f` against a brute count of all distinct oriented prefixes landing
on that stored state, P4 `alts`, P5 the band and `choice_rank`, P6 row-for-row
agreement with `--kc-o3-rank --kc-trace`, P7 the product token, P8 rejection of
a non-member walk, P9 an end-to-end argv leg through the real dispatcher
including `--kc-tsv`, and P10 the `--kc-c3-max` refusal. It prints one
`PASS`/`FAIL` line per gate and ends with `KC_PROFILE_SELFTEST=PASS` or
`=FAIL`; exit **0** / **1**. It runs in well under a second, is
argv-dispatched only, and is **never** reached from `--selftest` (whose output
is sha-pinned).

### --kc-layers / --kc-scan-merge

```
solve --kc-scan FDIR GDIR OUT.chunk.json --kc-layers A B
                [--kc-tdir TDIR] [--kc-raw] [--kc-ooc] [--kc-cache-mb MB]
solve --kc-scan-merge FDIR GDIR OUT.json CHUNK.json [CHUNK.json ...]
                [--kc-tdir TDIR] [--kc-raw] [--kc-ooc] [--kc-cache-mb MB]
solve --kc-layers-selftest
```

🔴 **`--kc-tdir` is bracketed above because it is syntactically optional — it is not scientifically
optional.** It supplies the only value-level check on `fmass[k]` for `k < n`, and on a merged table
those masses are carried from one chunk each and never recomputed. Without it the cross-chunk
identity `t(root) == sum_k fmass[k]` is skipped, `gate_fails` stays 0, and the atlas reports
`"fails": 0` with every other gate `true`. The atlas discloses the skip as
`gates.t_root_eq_f_layer_sum: "not-run (requires --kc-tdir)"` (2026-08-25); see the mandatory merge
recipe in `VERIFY.md`.

Both paths report the outcome as `KEY=value` tokens intended for `grep -qx`:
`KC_SCAN_TIDENTITY=` / `KC_SCAN=` on `--kc-scan`, and `KC_SCAN_MERGE_TIDENTITY=` / `KC_SCAN_MERGE=`
on `--kc-scan-merge`, each taking `VERIFIED`, `SKIPPED` or `FAILED` (`OK`/`FAIL` for the run tokens).
**`SKIPPED` is reported alongside `OK`**, because a run with no t ladder has not failed anything — it
has merely checked less. Do not gate on the `VERDICT:` sentence, which cannot distinguish the two.

Chunked, eviction-survivable `--kc-scan`. The full-31 atlas scan is a single
**48–85 h unresumable pass** against a Spot MTBE of roughly **15 h**;
`--kc-layers A B` splits it into independent per-layer-range processes, so an
evicted chunk is simply re-run and completed chunks are durable. The
granularity floor is one layer — this is not mid-layer resume.

**`A B` is a HALF-OPEN range `[A, B)`** over the transition layers
`k ∈ [0, n)`. Off-by-one here is the primary bug risk, which is why the merge's
coverage proof exists and why the range is restated in the chunk file itself.

**Why the split is sound.** Chunking is a *loop-bound* restriction, not a data
restriction. The scan streams the f layers directly by path and serves the g
side by random lookups against the whole, untrimmed g ladder, so both ladders
stay complete and open exactly as in a whole run and only the outer `k` loop's
range changes — no directory, manifest, or total is touched. (Chunking by
*trimming* a ladder directory does not work: the reader requires layers `0..n`,
and f/g total equality is a hard abort.) Every accumulator the layer pass
touches is indexed by `k` alone; everything else — `fmass[n]`, the branch
atlas, the t recursion, the t ladder — is tail-side and is recomputed whole by
the merge.

A chunk writes a `roae-kc-scan-chunk` object (**not** an atlas): the per-layer
rows for its range, `fmass` for its range, the identity bindings, and the
decompressed-stream digest of each f layer it read. It ends with
`KC_SCAN_CHUNK_RANGE=A-B` and `KC_SCAN_CHUNK=OK|FAIL`; exit **0** / **1** if a
per-layer gate failed / **2** on usage or IO.

**The merged atlas is byte-identical to a whole-run atlas** over the same
ladders and the same argv paths — by construction, not by hope: the merge
writes through the *unmodified* atlas emitter, layer rows come from the single
row writer shared by both files, and the branch atlas / `fmass[n]` / t work are
recomputed by the merge rather than serialised. Chunk submission order is
irrelevant; rows are placed by `k`.

**The merge PROVES coverage; it never assumes it.** Five independent legs:

1. **Coverage, exactly once.** Every `k ∈ [0, n)` must be covered by exactly
   one chunk's `[k_lo, k_hi)`. A gap or a double-count (which would silently
   *double* a flow value) is reported per `k` and the merge writes **no output
   file at all**.
2. **Identity binding.** `n`, `N_total`, `pl_hash`, `start_exit`, `b0`,
   `want_raw`, `fdir`, `gdir`, `engine_git`, `engine_source_sha` must agree
   across every chunk *and* with the ladders the merge just opened. Chunks from
   two builds or two ladders never merge.
3. **Ladder-bytes binding, re-checked at merge time.** The merge recomputes
   each f layer's decompressed-stream sha256 (the `--f1c5-layer-sha` digest)
   and requires it to equal what the chunk recorded — so "all chunks read the
   same ladder" is a *checked* statement, and a ladder mutated between chunk
   runs is caught.
4. **Every gate re-run on the assembled table.** The chunks' own `gate_fails`
   is not trusted. Leg 1 × the per-layer `flow[k] == N` gate is a complete-
   coverage argument at layer granularity: a truncated layer stream or an early
   loop exit yields `flow[k] < N`.
5. **The cross-chunk arithmetic identity.** With `--kc-tdir`,
   `t(root) == Σ_{k=0..n} fmass[k]`. Every `fmass[k]` for `k < n` came from a
   *different* chunk, while `fmass[n]` and `t(root)` come from the merge's own
   reads — one 192-bit equation ties all chunks to one independently computed
   total. **`--kc-tdir` is therefore effectively required for a production
   merged atlas.** A merge without it still runs, but prints
   `KC_SCAN_MERGE_TIDENTITY=SKIPPED` and a loud degraded-attestation warning.

Verdict block: `KC_SCAN_MERGE_COVERAGE=COMPLETE|INCOMPLETE|ABORTED`,
`KC_SCAN_MERGE_TIDENTITY=VERIFIED|SKIPPED|FAILED|NOT-REACHED`,
`KC_SCAN_MERGE=OK|FAIL`. Exit **0** ok / **1** coverage incomplete or a gate
failed / **2** hard abort (identity or ladder-digest mismatch, unreadable
chunk). Preserve every chunk JSON alongside the merged atlas — together with
the merge's verdict block they are the completeness evidence.

**Operational note.** Layer cost is strongly peaked mid-ladder (at n=9 the f
layer entry counts run 1, 4, 19, 58, 139, 244, 271, 160, 48, 6 — a ~270×
spread), so choose chunk boundaries by *measured* per-layer cost, not by layer
index. Time a probe with
`solve --kc-scan F G /dev/null --kc-layers $k $((k+1))` per k. Chunks are a
Spot workload; the merge is short, uncheckpointable and reads both ladders, so
it belongs on a right-sized Standard VM.

`--kc-layers-selftest` is the reduced-n gate (n=9, well under a minute,
argv-dispatched only, **never** reached from `--selftest`, whose output is
sha-pinned). It re-invokes the binary as real processes and checks L1 the
whole-run reference atlas, L2 chunks `[0,3) [3,6) [6,9)` merging to bytes
identical to the whole run, L3 nine single-layer chunks doing the same, L4 a
shuffled submission order doing the same, L5 a gap and L5b a missing middle
chunk both rejected with the offending layers named and **no atlas written**,
L6 an overlap rejected as a double-count, L7 a mixed-identity chunk aborting,
L8 a chunk bound to different ladder bytes aborting, L9 a tampered accumulator
failing the merge's re-run per-layer gate, L10 the t-identity leg and the
measured `t_root_t_units == 229861`, L11 every chunk's own tokens and
`flow == 26112 == N`, and L12 the degraded no-`--kc-tdir` attestation. It ends
with `KC_LAYERS_SELFTEST=PASS|FAIL`; exit **0** / **1**.

#### Atlas field: `fmass` (added 2026-08-22)

The atlas carries `"fmass": ["1", …]`, an `n+1` element array of decimal strings: **`fmass[k]` is
the orbit-weighted f layer mass, i.e. the EXACT number of valid depth-`k` prefixes** — the `M_j`
sequence the XA section is stated in. `fmass[0] == 1` is the anchor.

It was previously computed by the scan, consumed by the internal gates, and freed without ever
being written out. Emitting it costs one `fprintf` and lets a reader re-derive

```
t(root) == Σ_{k=0..n} fmass[k]
```

**from the atlas alone**, rather than taking the engine's own `t_root_t_units` on trust. Verified at
n=13: both sides are `5,163,044,120,623`.

⚠ Not to be confused with the **chunk** format's `fmass_00`, `fmass_01`, … keys, which are private
merge-support fields on `roae-kc-scan-chunk`, not part of the atlas schema.

### --kc-extremal

```
solve --kc-extremal FUNC DIR max|min [--kc-witness] [--kc-json OUT.json]
                    [--kc-gdir GDIR] [--kc-ooc] [--kc-cache-mb MB]
solve --kc-extremal list
solve --kc-extremal-selftest
```

The TR-12 **Q5** per-functional **DP extremal sweep with an explicit witness
walk**, over the C1&C2&C4&C5 SUPERSPACE. For a functional that is
*edge-additive* on the compiled DP graph,

```
Phi(w) = SUM over j = 1..n of weight(j, last_{j-1}, entry_j, exit_j)
```

it builds a backward max-plus / min-plus ladder `X(s)` on the **f ladder's
exact state space** — geometry (masks, offsets, keys) mirrored byte-identically
from the f layer, only the value channel differs, exactly as the Stage-T
ladder does — and then extracts the witness by a **forward greedy descent**
from the root. No backpointers are stored: `X` is kept for every state, so the
descent costs `n · 2n` lookups. That is the whole reason the DP runs backward.

Values are stored biased: `l0 = Phi_suffix + 2^31`, with **`l0 == 0` as the
NULL sentinel** for a dead-end prefix. This is a real semantic difference from
the t ladder (which counts dead-end nodes and so never stores 0) and it is
asserted on every read; a value outside the biased range is a defect, not a
data condition.

`DIR` is an f (forward) retained-layers dir. **No g ladder is required** —
reachability is f's state space and the NULL sentinel handles dead ends. Pass
one with `--kc-gdir` only to enable the free structural cross-gate
`X(s) == NULL <=> g(s) == 0` over every stored state, reported as
`KC_EXTREMAL_NULL_VS_G=CONSISTENT|INCONSISTENT`.

**The G-invariance gate, and why the tool refuses rather than approximates.**
The ladders are an **orbit quotient**: a stored state's `(last, entry, exit)`
live in the canonical representative's frame, which differs from a given raw
walk's frame by a group element. A DP over the quotient computes the extremum
over *orbits*, which equals the extremum over raw walks **iff the edge weight
is invariant under every frame map the DP applies**. Those maps are exactly the
24 `el[g].hmap[]`, so the question is finite and is settled by brute force
before the DP runs: `<= 24 * 64 * 64 * n` comparisons. The verdict is
`KC_EXTREMAL_INVARIANT=yes|no`; on `no` the tool prints the concrete
counterexample `(g, step, last, entry, exit, w, w_mapped)`, emits **no value**,
and exits **1**. A non-invariant functional needs the plain unquotiented DP,
which is memory-infeasible at full-31 and is deferred (TR-12 §Q5 caveat 1).
Because G48 acts by permuting the six *line positions*, `popcount(h)` and
`popcount(a ^ b)` are invariant while any specific line, trigram or hexagram is
not — but the gate decides per functional rather than the reader reasoning
about it.

`--kc-c3-max` is **rejected** with an explicit error: C3 is not
DP-optimisable, only a monotone in-path prune.

**The v1 registry** (`--kc-extremal list`, which prints name / class /
invariance expectation / `py_ref` / note and exits 0):

| FUNC | weight | status |
|---|---|---|
| `dclass:1` `dclass:2` `dclass:3` `dclass:4` `dclass:6` | `[ boundary distance class of (last, entry) == D ]` | invariant; **C5-forced CONSTANT** — `max == min == b0[D]` |
| `linechanges` | `popcount(last ^ entry)` (Q5's per-line change count) | invariant; **also constant** — `SUM_c b0[c]*dval[c]` |
| `graycode` | `[ popcount(last ^ entry) == 1 ]` | invariant; alias of `dclass:1` (exercises the alias path) |
| `yangcount` | `popcount(exit)` | invariant and **genuinely non-constant** — the row that exercises the DP |
| `entryyang` | `popcount(entry)` | invariant; exact complement of `yangcount`, a free cross-check |
| `posyang0` | bit 0 of `exit` | **NON-INVARIANT negative control.** Must trip `KC_EXTREMAL_INVARIANT=no`. Never publishable. |

Reporting the C5-forced rows as *constants* rather than as extrema is
deliberate — TR-12 §Q5 asks for exactly that, and `constant_on_space=yes|no`
plus `opposite_extreme=` are emitted on every run so the reader never has to
infer it. Class (b) functionals ("small extra state": `--markov`
self-transition counts, `--yinyang` running-balance *excursion*, prefix
level-cover masks) are **not** in v1 — each multiplies the state space by a
factor K and breaks the byte-identical f-geometry mirroring, and is a separate,
sized item.

**Scope: v1 is in-memory only (n ≤ 22).** An out-of-core f ladder is refused
with an explanatory error rather than silently mishandled. The streaming,
eviction-resumable OOC extremal builder is the full-31 enabler and is a
separate, unbuilt item, so **full-31 is not reachable from this subcommand**;
TR-12 §7 independently rules Q5 wave 3, deferred and not budgeted.

`--kc-witness` runs the greedy descent and emits the witness in the standard
`entry,exit,…` form. `KC_EXTREMAL_WITNESS=VERIFIED` requires **all three** of:
the descent produced a walk; `kc_member` accepts it; and a **straight-line
evaluator that never touches the DP** re-evaluates `Phi` on it to exactly
`extreme_value`. Anything less is `=FAILED`, `KC_EXTREMAL=FAIL`, exit 1.
TR-12 §Q5 additionally requires the witness to be re-checked in `solve.py` —
that is a **run-harness obligation**, not something a second evaluator inside
the same binary can discharge, and no Q5 number should ship without it.

`--kc-json OUT.json` writes a `roae-kc-extremal-certificate` object carrying
the same fields plus the ladder identity (`n`, `N_total`, `pl_hash`, `fdir`,
`gdir`, `engine_git`, `engine_source_sha`). Output is a certificate, not a
proof.

Verdict tokens: `KC_EXTREMAL_INVARIANT=yes|no`, `KC_EXTREMAL_WITNESS=VERIFIED|
FAILED`, `KC_EXTREMAL_NULL_VS_G=CONSISTENT|INCONSISTENT` (with `--kc-gdir`),
`KC_EXTREMAL_LIST=OK` (list mode) and `KC_EXTREMAL=OK|FAIL`. Exit **0** / **1**
(gate failure or refused functional) / **2** (usage, unknown functional, bad
direction, `--kc-c3-max`, or an out-of-core ladder).

`--kc-extremal-selftest` is the reduced-n gate: it builds n=9 f and g ladders
in a scratch dir and cross-checks the DP against exhaustive brute force over
all 26,112 walks. **K1** pins `X(s) == NULL <=> g(s) == 0` over every stored
state of every layer in both directions, plus the byte-identical f-geometry
mirror and the biased-range assert; **K2** checks the C5-forced known answers
against the budget table with no brute force at all; **K3** requires the DP's
`extreme_value` to equal the brute extremum for every invariant functional in
both directions; **K4** requires the witness to be a member re-evaluating to
that value; **K5** requires at least one brute walk to attain it (which is what
catches a witness that is extremal by luck on a wrong DP); **K6** requires the
non-invariant control to be refused with no value emitted; **K7** records, as
evidence rather than as a pass/fail row, what the forced quotient DP returns
for that control versus brute; **K8** requires max and min to bracket all
26,112 values; **K9** checks the `yangcount`/`entryyang` complementarity and
that `yangcount` is genuinely non-constant; **K10**–**K12** exercise the argv
surface, the certificate JSON, `list`, and the refusals. It prints one
`PASS`/`FAIL` line per gate and ends with `KC_EXTREMAL_SELFTEST=PASS|FAIL`;
exit **0** / **1**. It runs in about a second, is argv-dispatched only, and is
**never** reached from `--selftest` (whose output is sha-pinned).

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

`SOLVE_TEMP_DIR` should point to a directory with at least **1.5× the sum of
the input shard bytes** of free space — that is the quantity the pre-merge
pre-flight actually measures (`for (i…) in_bytes += sb.st_size`, then
`need = in_bytes * 1.5` against `statvfs`, solve.c:10875-10886), and it
matches the `SOLVE_SKIP_TEMP_SPACE_CHECK` row in the environment table below.
*(Corrected 2026-09-01: this rule was previously stated against the expected
*output* size. Input bytes exceed output bytes by the dedup ratio — several-fold at canonical
scale — so the old rule under-provisions and the merge aborts before starting.)*

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

> 🔴 **`<run_root>` must be an ABSOLUTE path.** The symlink target is built as
> `<run_root>/<layer>/<shard>` with `<run_root>` taken verbatim from `argv`
> (solve.c:17772-17781), and the link is created inside
> `<run_root>/_merged_/`, so a relative root yields a target that resolves
> relative to `_merged_/` and is therefore dangling. Measured on this tree:
> `solve --merge-layers runs` produced
> `runs/_merged_/sub_10_0_5_1.bin -> runs/layer1/sub_10_0_5_1.bin`, which
> fails `test -e`; the merge that followed printed `No sub_*.bin files found`
> and still **exited 0**, i.e. it silently produced nothing. The identical
> tree under an absolute root merged normally and wrote `solutions.bin`.
> `realpath()`-ing the root inside `solve.c` is an open code change.
> *(Added 2026-09-01.)*

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

Record addressing is O(1) index arithmetic (header offset + index ×
SOL_RECORD_SIZE), but the seek itself is not. `--show` uses `gzseek`
(solve.c:21204), and on the **default** artifact — `SOLVE_COMPRESS` defaults
to gzip, and a default-configuration run writes a `solutions.bin` beginning
`1f 8b`, measured — a forward seek decompresses through everything it skips,
so seek cost is O(offset): for `--mode last` on the 102 GB canonical that is
essentially the whole file. The implementation says so itself
(solve.c:21098-21101: *"forward seeks decompress through; this is a
small-sample inspection tool, not a hot path"*). For true random access use
`SOLVE_COMPRESS=0` artifacts. *(Corrected 2026-09-01: this paragraph asserted
O(N) and O(1) seek cost in one sentence and named the gz canonical as its
O(1) example.)*

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

Cascade determinism. The binary's own banner is `PROOF: Position 2
determines positions 3-19` (solve.c:24503): for each valid branch it
enumerates all 2^17 = 131,072 binary paths across positions 3-19 — at each
position the two candidates being pair *i* (KW) and pair *i-1* (shifted) —
and checks budget feasibility of every path; the cascade is deterministic
iff exactly one survives per branch. Finishes in seconds at small
N; exponential at deeper N. Each config is capped at `PROVE_CONFIG_TIMEOUT` seconds (default 300; `0` = no cap).

### --prove-self-comp

```
solve --prove-self-comp
```

Existence result, not a bound. The binary's own banner is
`PROOF: All self-complementary branches produce valid orderings`
(solve.c:24302): for each self-complementary pair at position 2 it runs a
bounded backtracking search and reports that at least one C1-C5-valid
ordering exists. C3 enters only as a constraint on that walk; nothing here
bounds self-complementary configurations by the C3 ceiling.
*(Corrected 2026-09-01, against the printed banner.)*

### --prove-shift

```
solve --prove-shift
```

Per-position candidate count, not a distributional invariance. The binary's
own banner is `PROOF: Positions 3-19 have exactly 2 budget-feasible
candidates` (solve.c:24369): at each position 3-19 it tests all 30 unused
pairs and reports how many are budget-feasible.
*(Corrected 2026-09-01, against the printed banner.)*

### --regression-test

```
solve --regression-test [budget]        # node budget, default 5600000000000 (5.6T)
```

**Partition-invariance regression, not a recorded-sha matrix.** At a single
budget B (argv[2], `atoll`-parsed; default 5.6T) it runs one full enumeration
and one 56-first-level-branch reconstruction at B/56 each, merges the second,
and compares the two **freshly produced** hashes (`strcmp(sha_full, sha_56)`,
solve.c:20046). There is no scope list and no baseline from
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) anywhere in the block — the
subcommand's own header comment states the property it checks
(solve.c:19861-19864). Note the practical consequence: it cannot catch a
common-mode regression that moves both paths identically. Exits 50 on any
phase failure or sha mismatch.

*(Corrected 2026-09-01. The argument is a budget, not a scope name: measured,
`solve --regression-test 100B` parses as **100 nodes** — it does
not resolve `100B` as a scale. ⚠ **[AMENDED 2026-09-02 — this note said it "proceeds", and that half
is false. Measured on a stock build of `main`: `./solve --regression-test 100B` returns **rc 50** and
prints `[regression-test] FAIL: full-enum phase exit=6400`. It parses the budget as 100 nodes and then
FAILS; it does not proceed. Found by the exec-lane sweep, which executes published commands rather
than reading them — this line had been read and corrected once already without being run.]** This section previously described a multi-scope
matrix compared against recorded hashes.)*

### --double-regression-test

```
solve --double-regression-test [budget]   # node budget, per layer
```

Two-path regression: full-enum at depth-3 vs 56-branch
reconstruction at the same per-sub-branch budget, both merged
globally. Both paths must produce byte-identical sha256. Used to
verify the partition invariance theorem at empirical scales.

Reads/writes test artifacts under a base directory taken **only** from
`SOLVE_REGRESS_DIR`; when that is unset the default is `/mnt/work` if it
exists, else `/tmp` (solve.c:20123-20128). The positional argument is a node
**budget**, not a directory — measured, `solve --double-regression-test
/tmp/somedir` prints `budget must be positive` and exits 2.
*(Corrected 2026-09-01.)*

### --emit-shard-manifest

```
solve --emit-shard-manifest [manifest_path]      # default shard_manifest.txt
```

Scans the **current working directory** for `sub_*.bin`, computes each
shard's logical sha256, and writes `<filename> <size_bytes> <sha256>`
per line. There is **no header**: the writer is a single
`find … | xargs … printf | sort` pipeline (solve.c:3260-3273) that emits
sorted data lines and nothing else — no manifest version, no build sha, no
emission timestamp. *(Corrected 2026-09-01; measured by running
`--emit-shard-manifest` on a 996-shard tree and reading line 1.)*

The optional argument is the manifest's **output path**, not a directory
to walk (solve.c:19810). The scan target is hard-coded `.`
(`find . -maxdepth 1 -name 'sub_*.bin'`, solve.c:3260), so
`--emit-shard-manifest /data/run42` scans the CWD and writes a *file*
named `/data/run42` — it does not scan `/data/run42` and does not
produce `/data/run42/shard_manifest.txt`. To manifest another directory,
`cd` into it first.

The path is interpolated **unquoted** into the emitting shell pipeline
(solve.c:3272) and into the `wc -l` count (solve.c:19817), so a path
containing spaces or shell metacharacters is not handled as a literal
filename: measured on this tree, `--emit-shard-manifest 'x;touch
INJECTED_PROOF'` created a file `INJECTED_PROOF`, printed
`mv: missing destination file operand`, and still returned 0. Pass plain
paths. Quoting these interpolations (and refusing metacharacters) is an
open code change.

Used by the auto-emit gate (default, suppressed via
`SOLVE_SKIP_AUTO_MANIFEST=1`): solve auto-emits a `shard_manifest.txt` at
**two** points only — promotion/startup, after `promote_orphaned_shards`,
and clean completion. Those are the sole call sites of
`auto_emit_shard_manifest_default()` (solve.c:26288 and solve.c:26722); it
does **not** fire on each shard-flush rename, as this paragraph used to say,
so between those two points the manifest can lag the shard set. Operator-invocable for
explicit re-baselining. *(Corrected 2026-09-01.)*

### --verify-shard-manifest

```
solve --verify-shard-manifest [manifest_path]    # default shard_manifest.txt
```

Reads the manifest at `manifest_path` (the argument is the manifest
*file*, not a directory — solve.c:19835), re-computes the sha256 of
every shard named in it **relative to the current working directory**,
and reports MISSING / SHRUNK / DIVERGED / EXTRA entries. Exits 22 on any anomaly. Run at every canonical-enum
startup as the auto-verify gate — catches cross-run shard-set
contamination before the new enumeration begins building on top of
ambiguous prior state.

An unlisted shard (present in the directory but not named in the manifest)
is **fatal**, like MISSING / SHRUNK / DIVERGED: `dir_shards > total` prints
one `UNLISTED: <name>` line per offender and returns 22 (solve.c:3425-3457).
That guard is deliberate — the merge step reads what is *present*, so an
unlisted shard would enter the merged result unverified. Measured on this
tree: dropping one extra `sub_*.bin` into a manifested directory drove
`--verify-shard-manifest` to exit **22**.
*(Corrected 2026-09-01 — this paragraph previously told operators the
condition was survivable and self-healing, which inverts the guard Q-367
added to stop the merge.)*

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

Streaming Gaussian-KDE log-density evaluator for the joint-density analysis
pipeline. **Both ends are float64 vectors, not `solutions.bin` records:**
`--fit-file PATH` holds the fit points as raw `float64`, `n_fit × d`; stdin
carries the **query** points, `d` float64 values per record
(solve.c:20330-20338). Output is **one aggregate line** —
`<n_below> <n_total>`, the count of queries whose log-density is at or below
`--threshold` and the number scored (`solve.c:20448`) — not a per-record
stream. Driven by `solve.py`; piping a packed 32-byte-record artifact into it
reinterprets record bytes as IEEE doubles. Used by
[DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md).

*(Corrected 2026-09-01: this section previously named the packed record
artifact as the stdin format and a per-record index/score stream as the
output; both ends were wrong.)*

## ENVIRONMENT

### Core (DFS / merge / threading)

| Variable | Default | Effect |
|---|---|---|
| `SOLVE_THREADS` | `nproc` (`sysconf(_SC_NPROCESSORS_ONLN)`; 8 if that fails), then clamped to the sub-branch count and to a hard ceiling of **256** | Number of pthreads for enumeration. ⚠ Row corrected 2026-09-01: this cell previously capped the default at 128. That cap lives only in `manifest_thread_count()` (solve.c:3241), a different function; the enumeration path is solve.c:26433-26443 |
| `SOLVE_DEPTH` | **2** | DFS sub-branch depth: 2 (3,030 sub-branches) or 3 (158,364 sub-branches). The **code** default is 2 ("Default 2 for byte-identical behavior with the canonical 10T baseline", solve.c) — but every d3 canonical needs an explicit `SOLVE_DEPTH=3`; it is sha-determining, so omitting it silently enumerates the d2 partition |
| `SOLVE_NODE_LIMIT` | 0 (no limit) | Total node budget across the enumeration |
| `SOLVE_PER_SUB_BRANCH_LIMIT` | derived | Per-sub-branch node cap; overrides auto-divide of `SOLVE_NODE_LIMIT`. Setting this also suppresses the sub-canonical hard-gate (intended for partition-invariance and within-code-state runs). |
| `SOLVE_PER_TASK_NODE_LIMIT` | `0` (off) | Per-task cap (depth-3 sub-branch granularity for parallel `--sub-branch`). ⚠ Row corrected 2026-09-01: read "derived". `static long long per_task_node_limit = 0;` — *"0 = off (preserves prior behavior + canonical shas)"* (solve.c:1511-1515) |
| `SOLVE_DFS_ITERATIVE` | 0 (recursive); **1 if `SOLVE_NODE_LIMIT >= 1T` (canonical-scale default since 2026-05-26)** | `=1`: iterative DFS using explicit stack frames (resume-capable) |
| `SOLVE_DFS_CHECKPOINT` | 0 (off); **1 if `SOLVE_NODE_LIMIT >= 1T` (canonical-scale default since 2026-05-26)** | `=1`: write `.dfs_state` per-sub-branch sidecar + `checkpoint.txt` for resume after interrupt or eviction. Also stamps/enforces the **resume-shape contract** (`resume_contract.txt`, 2026-07-17): resuming over a live `*.dfs_state` frontier with a different thread count or depth than the interrupted run is **FATAL (exit 34)** — kill/resume byte-reproducibility is only asserted for same build + same shape. Legacy dirs without a stamp get a WARN + stamp. |
| `SOLVE_RESUME_SHAPE_OVERRIDE` | 0 | `=1`: downgrade a resume-shape contract violation from FATAL to a loud WARNING and proceed. Byte-reproducibility vs an uninterrupted same-shape run is **voided** for that run dir — never use on a canonical campaign. |
| `SOLVE_CKPT_INTERVAL` | `60` (seconds) | Wall-time interval between checkpoint writes. ⚠ Row corrected 2026-09-01: read 30. `static int sub_ckpt_interval_sec = 60;` (solve.c:1101) — chosen to match Azure spot eviction notice (30-60 s) |
| `SOLVE_TEMP_DIR` | (CWD) | Where `--merge` external sort writes `temp_sorted_*.bin` chunks; needs ~1.5× the **sum of input shard bytes** (⚠ row corrected 2026-09-01: read "output size"; solve.c:10875-10886) |
| `SOLVE_MERGE_MODE` | auto | `external`: force external sort (use chunks). `memory`: force in-memory merge (fail if doesn't fit) |
| `SOLVE_MERGE_CHUNK_GB` | 4 | Per-chunk size for external merge sort |
| `SOLVE_COMPRESS` | 1 (gzip) | `=0`: write shards/outputs raw (uncompressed). Default writes gzip; reads auto-detect via magic bytes, so raw and gz interoperate |
| `SOLVE_GZIP_LEVEL` | 9 | gzip level for shards and the final `solutions.bin` (the durable/archival artifacts) |
| `SOLVE_MERGE_TEMP_GZIP_LEVEL` | 6 | gzip level for **transient** external-merge temp chunks only (`temp_sorted_*.bin`, `temp_merge_records.bin`) — the "knee" of the speed/ratio curve. **The final `solutions.bin` and any cold archive stay `SOLVE_GZIP_LEVEL` (9) regardless of this** — it never touches a durable artifact |
| `SOLVE_MERGE_THREADS` | 1 (serial) | `=N`: parallelize external-merge Phase 1 (sort+gz-write of chunks) across N threads; RAM/nproc-capped. Default 1 = the validated serial path |
| `SOLVE_SKIP_TEMP_SPACE_CHECK` | 0 | `=1`: skip the pre-merge free-space pre-flight (sum of input shard bytes ×1.5 vs `statvfs(SOLVE_TEMP_DIR)`) |
| `SOLVE_MEMORY_FLUSH_COUNT` | unset = **off** | Global records-before-flush threshold, divided across workers (floor 1000/worker). ⚠ Row corrected 2026-09-01: read `200000000`, implying automatic flushing. The Tier-2 memory-relief flush is enabled **only** when the variable is set to a positive value (`if (env_flush && atoll(env_flush) > 0)`, solve.c:25344-25346); unset means no memory-relief flushing at all |
| `SOLVE_DEPTH_PROFILE` | 0 (off) | `=1`: emit per-depth node-count histogram to log |
| `SOLVE_CONCENTRATE_BUDGET` | unset (off) | **`=set` (any value, including `0`) — the code tests presence, not value.** On a checkpoint resume, divides `SOLVE_NODE_LIMIT` by the count of *remaining* sub-branches instead of the full partition. Sha-affecting: the output then depends on how many branches were pre-completed, so it is **not** reproducible. Do not write `SOLVE_CONCENTRATE_BUDGET=0` expecting "off" — leave it unset. *(Row corrected 2026-08-01, solve.c sweep: it previously read default `0` and described "concentrate budget on richest sub-branches", neither of which matches `solve.c`.)* |
| `SOLVE_DEAD_LIMIT` | 0 (no limit) | Parsed into `dead_node_limit` and **never read** — the dead-sub-branch skip it names is not implemented in the current source. Setting it has no effect. *(Row corrected 2026-08-01, solve.c sweep.)* |
| `SOLVE_SUB_BRANCH_PARALLELISM` | unset | Value domain is **`{single, force-parallel}`** only (solve.c:20501-20512): `single` forces the serial path, `force-parallel` forces the parallel path even at one worker. ⚠ Row corrected 2026-09-01: this cell previously advertised a numeric core count as the value; a number matches neither recognised string and changes nothing; worker count comes from `SOLVE_THREADS` / the positional `threads` argument, and the parallel path is taken whenever that is > 1 |
| `SOLVE_REGRESS_DIR` | `/mnt/work` if it exists, else `/tmp` | Directory for `--regression-test` / `--double-regression-test` artifacts (solve.c:19911-19914, :20123-20128). ⚠ Row corrected 2026-09-01: previously `./` |
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
| `SOLVE_KNUTH_BOUNDARY_COND` | `0` (off; set `=1` to enable) | Per-boundary KW-agreement mass accumulators (31; the `--analyze` §[6] predicate on the estimator); conditional on the pin prefix if set. Estimator-only, sha-neutral. ⚠ Row corrected 2026-09-01: this cell read `1`. `static int knuth_bcond = 0;` (solve.c:5241) and the flag is set only by `if (getenv("SOLVE_KNUTH_BOUNDARY_COND") && atoi(...) == 1)` (solve.c:18985), so an `--estimate-knuth` run gets none of the 31 accumulators unless you set it. |
| `SOLVE_KNUTH_C5_BUDGET` | unset | Override the C5 transition-budget multiset for the estimator with an explicit `"d:count,d:count,…"` vector (the FULL 63-transition budget; e.g. the circular subspace `1:1,2:20,3:14,4:19,6:9`) — R6 §4, same mechanism as `SOLVE_KNUTH_RELAX_C5`. Self-gate: KW's standard linear multiset `1:2,2:20,3:13,4:19,6:9` must reproduce N_lin within CI. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SEED` | unset | `=<u64>` (0x… or decimal): override the fixed per-thread RNG seed base for the Knuth walk (R11 Phase-2 independent-seed replicate — a second seed family for CI reproducibility). Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_DEPTH_PROFILE` | 0 | `=1`: emit the R5 §8 Stage-B1 per-DFS-depth W-weighted live-children (offspring) histogram — the truncated-Galton–Watson fit input. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SUBTREE_DEPTH` | unset | `=<td>`: switch `--estimate-knuth` to the R5 §8 Stage-B2 two-stage subtree sampler at prefix depth `td` (bypasses the aggregate estimator). Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SUBTREE_ROOTS` | 10000 | Number of subtree roots for the Stage-B2 sampler (requires `SOLVE_KNUTH_SUBTREE_DEPTH`). Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SUBTREE_PROBES` | 1000 | Probes per root for the Stage-B2 subtree sampler (requires `SOLVE_KNUTH_SUBTREE_DEPTH`). Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SCORE_REG` | `0` (off; set `>=1` to enable) | Score all 31 registry candidate rules ([Schulz 1990](CITATIONS.md#schulz1990-motifs)/[2011](CITATIONS.md#schulz2011)/[2016](CITATIONS.md#schulz2016)/diss, [McKenna-Mair 1979](CITATIONS.md#mckenna-mair1979), [Drasny](CITATIONS.md#drasny2007), [Schöter](CITATIONS.md#schoter1998) — attribution per rule in code) per canonical leaf; ground truth: `solve.py --registry-verify`. Estimator-only, sha-neutral. ⚠ Row corrected 2026-09-01: this cell read `1`. `static int knuth_score_reg = 0;` (solve.c:5291) and the flag is set only by `if (getenv("SOLVE_KNUTH_SCORE_REG") && atoi(...) >= 1)` (solve.c:18937), so registry scoring is silent unless you set it. |
| `SOLVE_KNUTH_SCORE_PERM` | 0 | `=1`: score the 13 FROZEN R3 permutation-cycle functionals per canonical leaf (`perm_ncyc_bot`, `perm_lcyc_bot`, `perm_ord_bot`, … `perm_desc_top`; KW = 7,33,1,1,1320,31,1,3,52,0,1,260,30). Observable axis anchor: [Ge 2026](CITATIONS.md#ge2026) (KW cycle type of the top permutation (52,10,2)). Ground truth / two-language gate: `solve.py --perm-verify`. `=2` + `SOLVE_PERM_TESTVEC`: explicit-sequence cross-verification hook. Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_PERM_HIST` | 0 | `=1` (requires `SOLVE_KNUTH_SCORE_PERM=1`): additionally emit `perm_hist <name> <value> <mass>` per-functional weighted value histograms (the two `ord` functionals are wide-binned into 512 bins, Landau bound g(64)=2,042,040). Estimator-only, sha-neutral. |
| `SOLVE_KNUTH_SCORE` | 0 | `=1`: `--estimate-knuth` additionally reports weighted canonical-mass fractions for externally-attributed candidate rules — R-C1 final-pair anchor + R-C2 first-7 level coverage ([Cook 2006](CITATIONS.md#cook2006)), R-C5 18:18 split (Zhang Xingcheng + Zhu Xi, 12th c. / Hu Yigui 1247 / [Hacker & Moore 2003](CITATIONS.md#hacker-moore2003) / Cook 2006), R-M1 pair-positioning parity ([Moore 2005](CITATIONS.md#moore2005)). Since 2026-07-12 also reports, paired on the same probes as the R-C4 gender/parity line, the R13 two-convention masses **R-C4-B** (exception form: 0 violations OR exactly 2 at adjacent class positions; subset of the published ≤2 relaxation) and **R-C4-C** (2 violations exactly at {25,26}; data-like, report-only) — KW gate `--rc4b-verify`. See CITATIONS.md §Attributed candidate rules. Estimator-only; sha-neutral (2026-07-02). |
| `SOLVE_KNUTH_MOORE_STRICT` | 0 | `=1`: prune the Knuth walk to orderings satisfying BOTH Moore rules strictly (2005 pair-positioning parity 18/18 AND [1989](CITATIONS.md#moore1989) rising/falling 0-breaks) — `leaves_canonical` then estimates the joint-strict space ([TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) §4: ≈1.13×10²⁹, 95% CI [1.09, 1.17]×10²⁹; archived reports/evidence/r11/r11_moore_strict.out — NOT the F11 B/C runs, which report 1.16583e29 and 1.091306e29) ⚠ **[CORRECTED 2026-08-28 — the ±4.7% was a PREREGISTERED ANCHOR TOLERANCE BAND, not an error bar: `reports/evidence/f11/compute_f11_bf.py:85` names its check "Moore-joint size outside the +/-4.7% anchor band". The published 1.13×10²⁹ comes from `reports/evidence/r11/r11_moore_strict.out` (`est=1.131036e+29`, 95%CI [1.0942e+29, 1.1679e+29], relerr 1.66%), NOT from `f11_runB.out`, which reports 1.16583e29. See CORRECTIONS.md]**. Estimator-only, sha-neutral. |
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
| `SOLVE_F1_KEEP_LAYERS` | 0 | `--f1-exact-c1c2c4c5` / `--f1-out-of-core`: when `=1`, retain **every** layer file `0..n` instead of rolling the two-layer window (the default drops layer `k-2` as the window advances). The preserve-all-layers substrate for the knowledge-compiler query tool and a full on-disk ladder for archival. Peak disk becomes the **full** ladder (full-31: ~2.5–2.7 TB **projected** in the v2 zlib-blocked format at level 6 — 1.624 TB was measured on disk at `k = 0..16`, 17 of the 32 layers, on 2026-07-23, and the remainder is a mask-palindrome projection, not a measurement; plan a 4 TB disk), not the ~1×-largest-layer transient. The flag only suppresses the `k-2` unlink; the count and the layer bytes are unchanged → **Sha-neutral**. Emits a `[f1c5] KEEP-LAYERS` stderr banner. |
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
| `SOLVE_D3_GATE_ENGINE` / `_THREADS` / `_PSB` / `_NODE_LIMIT` / `_KILL_NODES` / `_KILLS` / `_TMPBASE` | see `--selftest-resume-d3` | Knobs of the depth-3 hard-kill/resume mini-gate; read only by `--selftest-resume-d3`, never by an enum run. |
| `SOLVE_F1_KILL_AFTER_CHUNK` | unset (`-1`) | `--f1-out-of-core` deterministic kill hook: terminate the layer build after N emitted chunks, to exercise mid-layer `--resume-from-layers` recovery. |
| `SOLVE_F1_FINALIZE_SHA` | `1` | OOC v2 layer finalize (f/g/t builders): compute the decompressed-stream sha256 inline during the finalize concat (same digest as `--f1c5-layer-sha`) and record it in the post-finalize `.finalized` marker + the append-only `<pfx>_layer_sha.ledger`. `=0` degrades the marker to size+identity only (adoption never depends on the digest). |
| `SOLVE_F1_KILL_PRE_CONCAT` | unset | Finalize-durability drill hook (f/g/t OOC v2): `_exit(137)` at finalize entry of layer K (sidecars flushed, concat not started) — exercises intra-layer-checkpoint concat redo. |
| `SOLVE_F1_KILL_IN_FINALIZE` | unset | Finalize-durability drill hook (f/g/t OOC v2): `_exit(137)` mid-concat of layer K after the kblk sidecar is consumed+unlinked — the worst-case in-window kill (layer rebuilt fresh; the accepted residual window). |
| `SOLVE_F1_KILL_BEFORE_MANIFEST` / `SOLVE_KC_G_KILL_BEFORE_MANIFEST` | unset | Finalize-durability drill hooks (f-side / g+t-side): `_exit(137)` after the catalog sidecar of layer K is emitted but before the manifest advances — exercises the post-finalize marker ADOPT path (layer NOT re-swept on restart). |
| `SOLVE_F1_TEST_LAYER_DELAY_MS` | 0 | `--f1-out-of-core` per-layer artificial delay in milliseconds; widens the eviction window in resume drills / timing tests. |
| `SOLVE_F6_TESTVEC` | unset | With `SOLVE_KNUTH_SCORE_F6=2`: evaluate the 7 F6 functionals on an explicit 64-int sequence (`"h0,h1,...,h63"`), print them comma-separated in `f6_names` order, exit. Two-language test vector gating the C port against `solve.py` f6_* ground truth. |
| `SOLVE_REG_TESTVEC` | unset | With `SOLVE_KNUTH_SCORE_REG=2`: evaluate `score_registry` on an explicit 64-int sequence with W=1, print the 31 candidate-rule indicators (0/1, comma-separated, `REGISTRY_KW_EXPECTED` order), exit. Gates the C registry port against `solve.py` reg_* ground truth. |
| `SOLVE_PERM_TESTVEC` | unset | With `SOLVE_KNUTH_SCORE_PERM=2`: evaluate the 13 R3 perm functionals + 2 template-match indicators on an explicit 64-int sequence (`"h0,...,h63"`), print them, exit. Two-language test vector gating the C `perm_*` port against `solve.py` `perm_*` / `--perm-verify` ground truth. |
| `SOLVE_GZ_TEST_SHARDS` | 0 | `=1`: run a paranoid per-shard `gzip -t` CRC integrity test after each shard write (#169). Default OFF — a full decompress per shard roughly doubles compression CPU across ~65K shards, and the gzfwrite return-count + durable-close checks already cover write completeness. |
| `SOLVE_KNUTH_H2` | `0` | `1` enables the H2 near-precursor edit-ball mass accumulator during a Knuth-estimator run (`grep -n SOLVE_KNUTH_H2 solve.c`). Private semi-fitted hypothesis — magnitude only, not promoted to a published claim. Sha-neutral. |
| `SOLVE_KNUTH_H2_DUMP` | unset | Path for the per-leaf H2 dump consumed by `solve.py --h2-verify` / `--h2-mass`. Sha-neutral. |
| `SOLVE_F1U_MAX_LAYER` | unset | Stop the start-unpinned `--f1-exact-c1c2` walk after layer K completes — a memory/timing probe (`grep -n SOLVE_F1U_MAX_LAYER solve.c`). Produces a PARTIAL count; never use for a published figure. Sha-neutral. |

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
| **34** | **Resume-shape contract violation** (2026-07-17) — a live `*.dfs_state` frontier is present and `resume_contract.txt` records a different thread count or depth than this run's. Kill/resume byte-reproducibility is only asserted for same build + same shape. Recovery: rerun with the stamped `SOLVE_THREADS`/`SOLVE_DEPTH`, or `SOLVE_RESUME_SHAPE_OVERRIDE=1` (voids byte-reproducibility for that dir). |
| 50 | **Regression-test / internal-consistency failure** — a phase failure or sha mismatch in `--regression-test` / `--double-regression-test`, or a startup King Wen self-check failure (`solve.c` has 19 `return 50` sites; e.g. :19958, :20038, :20772). ⚠ Row corrected 2026-09-01: this row previously attributed code 50 to a `--selftest` sha mismatch. `--selftest` returns **40** on sha mismatch (`solve.c:18031`), not 50. |

**Subcommand-specific exit codes** (distinct from the enum-path codes above):
- `--validate-canonical`: **33** sha mismatch, **40** enum error (in addition to 0/2/10).
- `--selftest-resume-d3`: **41** sha mismatch (regression signal), **42** vacuous gate (kill never fired / no frontier), **40** leg or merge failure (in addition to 0/10/30).
- `--disk-precheck`: **5** identity mismatch (wrong disk), **6** insufficient capacity, **7** read-write smoke test failed (in addition to 0/1/2).
- `--preflight`: returns the first failing in-process gate's code (24 / 29 / 31), else 0.
- `--canonical-config` / `--validate-launcher-config`: **25** = unknown scale or bad arg count
  (distinct from the enum-path sub-canonical gate that also uses 25; disambiguated by which
  subcommand was invoked and by the stderr message — see those subcommands' sections).
- `--validate-launcher-config`: **34** = known scale that publishes no PSB, so there is nothing
  to validate (not an error; see that subcommand's section).

## EXAMPLES

**Run the canonical 11.2T enumeration (matches sha `0c0fe37c…`):**

```
ulimit -s unlimited
SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=11200000000000 SOLVE_PER_SUB_BRANCH_LIMIT=70723196 \
SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128 \
solve 0 128
```

> ⚠️ **Corrected 2026-09-01 — the `ulimit` line used to sit *after* the assignments,
> which silently discarded all six of them.** An assignment prefix applies only to the
> single command it precedes, and `ulimit` is a *regular* builtin (not one of POSIX's
> special builtins), so the assignments died with it and `solve` on the next line
> inherited none. Measured on this tree, running the old block verbatim:
> `env | grep -c '^SOLVE_'` = **0**, identical under `bash` and under `dash`. The run
> that followed took the built-in defaults — depth **2** (`solve.c:20731`) and no node
> limit — i.e. an unbounded depth-2 enumeration on the wrong lineage, with no error
> raised. With `ulimit` moved above, the same measurement returns **6**.

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
ulimit -s unlimited
SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=2000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=631456644 \
SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128 \
solve --branch 22 0 0 128   # (22,0) is a valid first-level branch (see --list-branches);
                            # ⚠ corrected 2026-08-21: this example named branch (4 0), which is
                            # not in the valid set — the solver prunes it at depth 1 and exits 1.
                            # Found by the execution lane (scripts/exec_lane.sh) running the
                            # documented example verbatim.
```

**Merge shards into a final solutions.bin:**

```
export SOLVE_TEMP_DIR=/mnt/work/merge_scratch
solve --merge
```

**Run the self-test gate before any commit:**

```
solve --selftest
# Expect: sha 403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e
```

**Two-path regression check (5.6T scale):**

```
export SOLVE_REGRESS_DIR=/mnt/work/regress
solve --double-regression-test 5600000000000    # argv is a node BUDGET, not a directory
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
- `shard_manifest.txt` — auto-emitted at promotion/startup (after
  `promote_orphaned_shards`) and at clean completion — those two points
  only, not after every flush (solve.c:26288, solve.c:26722) — unless
  `SOLVE_SKIP_AUTO_MANIFEST=1`.
- `solve.binary.snapshot` — copy of the running solve binary, captured
  at canonical-enum startup (unless `SOLVE_SKIP_BINARY_SNAPSHOT=1`).
  Forensic artifact for cross-build reproduction.
- `temp_sorted_*.bin` — external-sort chunks in `SOLVE_TEMP_DIR`
  during `--merge`.

**Note on temp file hygiene:** failed `--merge` runs may leave
`*.tmp` orphan files. solve.c's `--merge` skips them automatically
on retry — every shard-listing loop drops names containing `.tmp`.
External cleanup is not required but is a disk-hygiene best practice.

## REPRODUCIBILITY

- The default action and `--branch` / `--sub-branch` produce
  byte-identical sha256 across thread count (above a minimum) and merge
  mode (in-memory vs external), given matching solver version and inputs —
  that much is the partition-invariance theorem
  ([PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)), which is about
  partition granularity and says nothing about hardware or region.
  **Across hardware and region the guarantee is scoped, not absolute:** it
  holds *within the tested toolchain class*
  ([SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) §Reproducibility;
  [DEVELOPMENT.md](DEVELOPMENT.md):945), a host-level drift event is on the
  record, and at 1T scale
  [CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md):604-607 notes that
  moving between hosts *in the same SKU class* can change the sha. The
  strongest expectation a third-party reproducer should hold is same SKU
  class, same region, at 11.2T and above
  ([CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md):648-651).
  *(Scope restored 2026-09-01: this bullet asserted byte-identity across
  hardware and region without qualification.)*
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

Approximate wall-clock on D128als_v7 (AMD EPYC 9V45, 128 vCPU spot)
with `SOLVE_DFS_CHECKPOINT=1`:

| Subcommand / scale | Wall | Notes |
|---|---|---|
| `--selftest` | ~5 sec | Runs on 4 threads internally |
| `solve 0 128` at d3 11.2T | ~2.1 h | Tier 1 canonical (campaign-scale tier — see [LARGE_SCALE_CAMPAIGNS.md](LARGE_SCALE_CAMPAIGNS.md); not the `tier-1` scoring axes above) |
| `solve 0 128` at d3 100T | ~11-19 h | 100T canonical; varies with sub-branch yield distribution |
| `solve 0 128` at d3 560T | ~7.1 days (171.5 h incl. eviction defers) | 560T canonical — completed 2026-06, re-verified 2026-06-30 (`9a968fa2…`, 10.525 B records) |
| `--branch p o 0 128` at d3 100T | ~12-15 min | One first-level branch |
| `--verify` on 102 GB solutions.bin | ~30-60 min | I/O bound on Standard HDD |
| `verify.py --jobs 128` on 102 GB | ~25-30 min | Python parallel verify |
| `--merge` on 60K shards (414 GB raw) | ~2-3 h | Standard HDD I/O bound |
| `--analyze` on 102 GB | ~30-60 min | OpenMP-parallelized |

Single-thread `--branch p o 0 1`: ~22M nodes/sec on the AMD EPYC 9V45.
*(Architecture corrected 2026-09-01 in both lines above: the SKU underlying
Azure's `D128als_v7` is AMD EPYC 9V45 (96-core, 128-vCPU), per
[DEPLOYMENT.md](DEPLOYMENT.md):318, which retracts the earlier Zen-5-family
attribution these two lines carried.)*
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
the canonical budgets. D128als_v7 has 256 GB
([DEPLOYMENT.md](DEPLOYMENT.md):180, :1242, :1266) — still ample.
*(Corrected 2026-09-01: this read 384 GB.)*

**Single C source file:** all functionality lives in `solve.c`
per the project's standing rule. No new `.c` files allowed; new
analysis tools become subcommands instead.

**License:** see [LICENSE.md](../LICENSE.md). solve.c links only to
glibc, pthread, m, gomp, and **zlib** (`-lz`); no third-party C dependencies
beyond the system zlib, which the project treats as a native library.
*(Corrected 2026-09-01: the list omitted zlib and so could not provision a
build host. Measured — `gcc -O0 -fopenmp -o solve solve.c -lm -lpthread`
fails with 13 undefined references (`gzopen`, `gzread`, `gzseek`, `crc32`,
`compress2`, `uncompress`, …); adding `-lz` links at rc 0. Confirmed at
solve.c:317 (`#include <zlib.h>`) and in the binary's own printed build line,
solve.c:17517: `gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz`.)*

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

## Knowledge-compiler and verifier flags — derived from `solve.c`, 2026-08-26

Every entry below is derived from the flag's actual `strcmp` site in `solve.c`, with the
line number given so a reader can check it. Where `solve.c` carries its own `Usage:` string
that string is reproduced verbatim and is authoritative; where it does not, the entry states
only what the parse site establishes — kind, arity and value type — and says nothing about
semantics it cannot support. **A confident wrong sentence in a CLI doc is worse than a
missing one**, so unknowns are left explicitly unknown.

### Subcommands

#### `--kc-ar2-selftest`

Dispatched as a subcommand at `solve.c:28886`; takes **none**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-build`

Dispatched as a subcommand at `solve.c:28941`; takes **see code**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-cert-selftest`

Dispatched as a subcommand at `solve.c:28871`; takes **none**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-count`

Dispatched as a subcommand at `solve.c:28952`; takes **see code**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-g-status`

```
Usage: solve --kc-g-status GDIR
```

Reports what ladder artifacts a directory actually holds — which prefix (`g`, `t` or `f1c5`), how
far its manifest reaches, and whether a finalize marker is outstanding. **Read-only; it builds
nothing and writes nothing.** It errors rather than reporting an empty ladder when `GDIR` contains
no manifest at all, because "no artifacts" and "a ladder at layer 0" are different facts and a
status tool that conflates them is worse than no status tool.

Added with the Stage-G build telemetry (#119) so that an interrupted build can be inspected without
inferring its state from file mtimes.

#### `--kc-g-check-layer`

```
Usage: solve --kc-g-check-layer K GDIR FDIR [--kc-ooc] [--kc-cache-mb MB]
```

Verifies a **single** g-layer `K` against the f ladder in `FDIR` rather than re-walking the whole
ladder — the identity gate applied at one layer. Use it to localise a suspected corruption to a
specific layer after `--kc-g-selftest` or a full verify reports a mismatch, and to re-check one
layer after a resume without paying for the whole pass.

#### `--kc-g-build`

```
Usage: solve --kc-g-build GDIR [--f1-pairs N] [--kc-g-ooc] GDIR: the g-ladder directory (g_layer_NN.bin + g_manifest.txt). Full-31 needs its own ~2.5-2.7 TB (hedged) — a second 4 TB disk or a shared 8 TB with the f ladder both work (plan §8.3; decision open). n <= 22 builds in-memory (v1); n >= 24 or --kc-g-ooc streams out-of-core (v2 default; SOLVE_F1_OOC_FORMAT=v1 override) with eviction resume 
```
*Grammar reproduced from `solve.c:28753`.*

**Progress output on stderr (this builder also serves `--kc-t-build`; `pfx` is `g` or `t`).** Two
line kinds carry byte and time accounting, and the distinction between them matters when reading a
long build:

```
[kc-g-seg] SEGMENT_START utc=... seg_bytes_w=0 seg_sec=0
[kc-g-hb]  <utc> layer k=.. pass=1/N masks=../.. (..%) entries_out=.. read=..GB write=..GB
           windows=.. elapsed=..s seg_bytes_w=.. seg_bytes_r=.. seg_sec=.. mono_viol=..
[kc-g-seg] layer k=../N SEGMENT seg_bytes_w=.. seg_bytes_r=.. seg_sec=.. layer_bytes_w=..
           layer_sec=.. adopted=0|1 mono_viol=..
```

* `read=` / `write=` are **per layer** and reset at each layer boundary — `F1C5OocIo io` is declared
  inside the per-layer loop. They are what the layer table consumes; do not difference them across a
  boundary.
* `seg_bytes_w` / `seg_bytes_r` / `seg_sec` are **cumulative since this process started**, in raw
  bytes and seconds. `seg_bytes_w` is monotone: it never decreases within one process, so a fall is
  never a legitimate reading. A restart begins a new segment with a fresh `SEGMENT_START` line and
  `seg_sec` back near zero — an explicit boundary, not a mid-run drop.
* `mono_viol` counts readings that went backwards anyway. It must be `0`. It is printed rather than
  clamped, because silently repairing the symptom would destroy the evidence of an accounting bug.
* `adopted=1` marks a layer already complete on disk and skipped, which correctly contributes zero
  bytes to the segment.

A layer's rate is the sum over its segments, so process downtime drops out — that is the point of
emitting seconds alongside bytes rather than only at layer completion, and it is what separates a
slow layer from an interrupted one. Background and the falsifiable proofs: `roae-private/`
`STAGET_PER_SEGMENT_INSTRUMENTED.md`.

**Environment.** These are read by the ladder builders and were previously undocumented:

| variable | default | effect |
|---|---|---|
| `SOLVE_KC_G_HEARTBEAT_SEC` | `300` | Seconds between `[kc-*-hb]` heartbeats. `<= 0`, or unparsable, disables both the heartbeat and the pass-boundary announcements. stderr-only and sha-neutral. |
| `SOLVE_KC_CACHE_MB` | `2048` | LRU block-cache size for the out-of-core layer reader, when `--kc-cache-mb` is not given. A value `<= 0` falls back to the default rather than disabling the cache. |
| `SOLVE_KC_G_STOP_AT_K` | `0` | Probe hook: stop the **g** ladder build after reaching layer `k`. Clamped to `[0, n]`. A ladder stopped this way is INCOMPLETE and says so on stderr. |
| `SOLVE_KC_T_STOP_AT_K` | `0` | The same hook for the **t** ladder build. |
| `SOLVE_KC_SCRATCH` | `/tmp` | Base directory under which the `kc` selftests `mkdtemp` their scratch dir. |

#### `--kc-g-check`

```
Usage: solve --kc-g-check FDIR GDIR [--kc-ooc] [--kc-cache-mb MB] FDIR: an f (forward) retained-layers dir (--kc-build or Stage F); GDIR: the matching g ladder (--kc-g-build). Verifies, for EVERY layer k, sum over canonical masks of orbit * sum f*g == N, plus g(0,root) == N — 31 independent exact identities at full-31 (V3).
```
*Grammar reproduced from `solve.c:28801`.*

#### `--kc-g-selftest`

Dispatched as a subcommand at `solve.c:28748`; takes **none**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-ladder-selftest`

Dispatched as a subcommand at `solve.c:28869`; takes **none**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-member`

```
Usage: solve --kc-member DIR \
```
*Grammar reproduced from `solve.c:28989`.*

#### `--kc-midn`

```
Usage: solve --kc-midn N [--kc-roundtrips R] [--kc-chi2-samples M]
```
*Grammar reproduced from `solve.c:28720`.*

#### `--kc-o3-selftest`

Dispatched as a subcommand at `solve.c:28769`; takes **none**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-oocverify`

```
Usage: solve --kc-oocverify N [--kc-roundtrips R] [--kc-scratch DIR]
```
*Grammar reproduced from `solve.c:28735`.*

#### `--kc-oracle-selftest`

Dispatched as a subcommand at `solve.c:28867`; takes **none**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-rank`

```
Usage: solve --kc-rank DIR \
```
*Grammar reproduced from `solve.c:28976`.*

#### `--kc-repr`

```
Usage: solve --kc-repr DIR \ [--kc-c3-max T]
```
*Grammar reproduced from `solve.c:29001`.*

#### `--kc-scan-selftest`

Dispatched as a subcommand at `solve.c:28872`; takes **none**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-selftest`

Dispatched as a subcommand at `solve.c:28716`; takes **none**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-t-build`

Dispatched as a subcommand at `solve.c:28832`; takes **see code**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-t-cert`

```
Usage: solve --kc-t-cert OUT.json Emits the t-unit node-accounting convention certificate: pins what the t-ladder counts (valid oriented prefixes; root counted; joint pair+orientation branching; dead ends counted) and verifies it byte-exactly against the independent brute DFS at n=9 (EXHAUSTIVE, every stored state) with n=13 spot totals. The SOLVE_NODE_LIMIT mapping is NOT claimed here (W0-D worke
```
*Grammar reproduced from `solve.c:28821`.*

#### `--kc-t-check`

Dispatched as a subcommand at `solve.c:28832`; takes **see code**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-t-selftest`

Dispatched as a subcommand at `solve.c:28816`; takes **none**.
`solve.c` carries no `Usage:` string for it, so no argument grammar is asserted here.

#### `--kc-unrank`

```
Usage: solve --kc-unrank DIR RANK [--kc-record [--kc-c3-max T]]
```
*Grammar reproduced from `solve.c:28958`.*

### Modifiers

| flag | arity | parsed at | sets |
|---|---|---|---|
| `--kc-bracket` | none (boolean) | `solve.c:28791` | `o3cache` |
| `--kc-cert-out` | 1 string | `solve.c:22265` | `cert_out` |
| `--kc-chi2-samples` | 1 integer | `solve.c:28727` | `M` |
| `--kc-class-uniform` | none (boolean) | `solve.c:28927` | — |
| `--kc-dump` | 1 integer | `solve.c:22264` | `dump_max` |
| `--kc-expect-count` | 1 string | `solve.c:22266` | `expect` |
| `--kc-g-ooc` | none (boolean) | `solve.c:28765` | — |
| `--kc-oracle-repr` | 1 integer | `solve.c:22261` | `cache_mb` |
| `--kc-record` | none (boolean) | `solve.c:28928` | — |
| `--kc-roundtrips` | 1 integer | `solve.c:28726` | `R` |
| `--kc-scratch` | 1 string | `solve.c:28743` | `scratch` |
| `--knuth-dump-prefix` | see code | `solve.c:30578` | — |
| `--r11-verify` | see code | `solve.c:30947` | — |
| `--rc1c-verify` | see code | `solve.c:30920` | — |
