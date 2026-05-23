# Canonical hashes

The reproducibility anchor for ROAE is the sha256 of `solutions.bin`, not the file itself. Any `solutions.bin` produced with the matching solver version and inputs must reproduce one of the hashes below byte-identically.

A mismatch means a bug was introduced (in the solver, the build toolchain, or the runtime environment), not that a new result was found.

## Active canonicals

| Scale | sha256 | Records | Records (decimal) | Solver | Status |
|---|---|---|---|---|---|
| Selftest baseline (100M nodes) | `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e` | 135,780 | 1.35780 × 10⁵ | v1 | **Active** — reproducible across every binary build tested |
| d3 5.6T | `f66920c10adfc4882cc75fce9aeb2f07a99d36159ecb8b2c58b2d22d13867a21` | 467,484,167 | 4.67484 × 10⁸ | v1 (modern) | **Active** — cross-build verified 2026-05-12/13: Build A (Spot D128 host α, source commit 2cf8771) + Build B (Spot D128 host β, source commit a2ead96 post-fix) produced byte-identical sha. Both archived to `canonical-archive/20260512_modern_v1_5.6T_buildA/` and `20260513_modern_v1_5.6T_buildB/`. Replaces deprecated `c34390c0` (see below) |
| d3 10T | `b85c887128ce9881229741380a799c4e1608335df438cedc3da9e087fd94dbbc` | 706,427,594 | 7.06428 × 10⁸ | v1 (modern) | **Active** — established 2026-05-13 via cascade re-derivation; Build A + Build B on different Spot D64 hosts both produced byte-identical sha. **+4,607 records vs deprecated `f7b8c4fb`** (pre-resume-fix code from 2026-04-18 undercount). Archived to `canonical-archive/20260513_modern_v1_10T_buildA/` + `20260513_modern_v1_10T_buildB/` |
| d3 11.2T | `0c0fe37cf449cbc6e2754583964a60c185a7b387ee522fa43a8aac4fdb055db7` | 759,608,573 | 7.59609 × 10⁸ | v1 | **Active** — cross-build verified 2026-05-14: modern code (post-fix HEAD a2ead96) re-derivation across two independent Spot D64als_v7 westus3 hosts (Build A + Build B) both produced **byte-identical sha** to the historical 2026-04-30/05-01 generation. Build B used split enum/merge — enum on Spot D64 (SOLVE_THREADS=64, SOLVE_SKIP_AUTOMERGE=1) finished in 3.9 hours, with `solve --merge` then run on a separate Standard D64als_v7 (in-memory merge, 62 min). Confirms the 7-path validation that originally established this canonical. Archived to `canonical-archive/20260514_modern_v1_11.2T_buildA/` and `canonical-archive/20260514_modern_v1_11.2T_buildB/` |
| d3 100T | `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5` | 3,432,399,297 | 3.43240 × 10⁹ | v1 (modern) | **Active** — produced first ~2026-04-29 by post-`f42f2ae` code; original bytes destroyed 2026-05-06 by the `solver-data-westus3` mkfs -F incident; re-derived 2026-05-09/10 via two independent paths that both produced byte-identical `915abf30…`: **T9+c.1** (full-enum `solve 0 128` recovery, 2026-05-09) restored the canonical bytes; **T9+d** (per-branch loop `solve --branch p1 o1` × 62 + `solve --merge`, 2026-05-10) is a partition-invariance witness — same sha via a DIFFERENT execution path, empirically confirming the partition-invariance theorem at 100T scale. **Note:** v1 100T was NOT cross-built on two different physical hosts in the deliberate Build A + Build B pattern that v1 11.2T and v2 11.2T use; the two re-derivations were forced by the wipe-incident recovery, with T9+d incidentally serving as the partition-invariance witness. Provenance verified 2026-05-12. Archived `canonical-archive/t9c1/` |
| d2 10T | `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2` | 286,357,503 | 2.86358 × 10⁸ | v1 | **Active** — cross-build verified 2026-05-13: modern code re-derivation on Spot D64als_v7 westus3 (Build A) + second independent Spot D64 (Build B) both produced **byte-identical sha** to the historical 2026-04-18 generation. Depth-2 enumeration's smaller sub-branch count (3030 vs depth-3's 158k) makes interruption less likely; the resume-bug interactions that affected `c34390c0`/`f7b8c4fb` did not affect this canonical. Archived `canonical-archive/20260513_modern_v1_10T_d2_buildA/` + `20260513_modern_v1_10T_d2_buildB/` |
| d3 11.2T (v2) | `2cc966e48399841ebb0c9ca67300f15bb578cc5481ed04fca5faffcb38ad6c4d` | 796,357,285 | 7.96357 × 10⁸ | **v2** (commit `9d00c48`, merged to main 2026-05-21 in `v2-merged-2026-05-21` tag) | **Active — current canonical lineage on main** — established 2026-05-17 (C5 prune #68 + mid-walk C3 #67 + C3 optimistic-completion bound #70; #71 reverted). **+36,748,712 records (+4.83%) vs v1 11.2T** — the v2 prunes free dead-branch budget for live solutions at the same total budget. Deterministic across two independent runs same-day (attempt 1 transient bytes + Phase 2 recovery). Triple-storage archived: managed disk `solver-data-westus3:/20260516_v2bundled_11.2T_buildA_9d00c48/` + cold `canonical-archive/20260516_v2bundled_11.2T_buildA_9d00c48/` + claude `/tmp` fallback. solutions.bin.gz size 2,929,400,458 bytes (sha `4f1cd8b377dd4c7f6bc0e2358f7ce3a4c83f84ae04d798712b30c3fe57398cdd`). **Cross-architecture witness (2026-05-21):** ARM Cobalt Neoverse-N2 (D96ps_v6 Spot enum + D32ps_v6 Standard merge, westus3, gcc 13.3.0 `-O3 -pthread -fopenmp -mcpu=native`, source commit `9d00c48`, ARM binary sha `e5cfc6cd8f81058df1f72d61b705e500ab305a13643355d40156f384cb93dfa8`) produces byte-identical solutions.bin sha `2cc966e4…`. Confirms enum + merge are architecture-independent for the v2 prune stack. G2 proof artifacts at `solver-data-westus3:/20260520_v2bundled_11.2T_armB_9d00c48_attempt2/` (G2_SUCCESS.txt, RUN_METADATA.txt, merge.log, verify.log, solutions.sha256). v1 sha `0c0fe37c…` remains the v1 anchor; both are valid for their respective solver lineages |
| d3 100T (v2) | `cc4a5377199f0710c99406c6e82e44f311ef34b2e53b152d67f5d0fcd2ace091` | 3,663,580,914 | 3.66358 × 10⁹ | **v2** (commit `3128942`, tag `v2-merged-2026-05-21`) | **Active — v2 100T comparison baseline** — established 2026-05-23 (campaign `20260521_v2_100T_buildA`). Phase 1 enum: ~40h cumulative wall across 3 Spot evictions on D128als_v7 westus3 (`SOLVE_THREADS=128`, `SOLVE_DFS_ITERATIVE=1`, `SOLVE_DFS_CHECKPOINT=1`); 61,550 shards, 481 GB raw output. Phase 3 merge: Standard D32als_v7 (32 vCPU, 64 GB RAM — D32als_v7 is the AMD low-memory variant) + 1.5 TB Premium SSD scratch, external chunked-sort mode (~5h, in-memory mode infeasible at 100T scale on 64 GB), producing 15,035,483,184 raw records → 3,663,580,914 unique canonical orderings. **+231,181,617 records (+6.74%) vs v1 100T `915abf30…`** — substantially larger delta than the "~1-2% saturation" extrapolation in the lineage note below had predicted; the v2 prune stack retains meaningful uplift at 100T depth, not negligible diminishing returns. `solve --verify` PASS (sort-order violations 0, duplicates 0, King Wen found). Solver binary sha `6fdb10daaa1fc019d4f3409e71dced4e1bedc14586f11f83d8f674f382cdb220`. Dual-storage archived: managed disk `solver-data-westus3:/20260521_v2_100T_buildA/final/` + cold `canonical-archive/20260521_v2_100T_buildA/`. **No Build B cross-build** — v2 100T is a comparison baseline against v1 (and a reference point for the v3 100T Phase 12 bench), not a load-bearing canonical for 560T extension. Per operator directive 2026-05-23, v2 100T shards were deleted from managed disk post-archive (~481 GB freed); v3 100T at Phase 12 WILL preserve shards. solutions.bin.gz size 13,462,264,289 bytes (sha `f6b554eaa201a4ef5ccd03b353aa5bbbda11647eed8ebfe0d78c4a783e97e206`, ~9.35× compression). |

Records are unique canonical orderings; orient variants are collapsed at merge time. File format is documented in [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md).

**Note on v1/v2 lineage (post-2026-05-21 merge):** As of the v2 merge into `main` (commit tagged `v2-merged-2026-05-21`), v2 IS the current canonical-producing lineage on `main`. The v1 11.2T sha `0c0fe37c…` remains a valid canonical for runs of the v1-era code (preserved by the `v2-pre-merge` tag's ancestor commits). The pre-v2 history is captured in main's commit history; the `v2-pre-merge` tag points at the v2-bundled tip immediately before the merge. v1 produced the `0c0fe37c…` family at all canonical scales — its results are stable across the project lifetime, and the partition-invariance theorem chains the 11.2T canonical up to 100T. v2 produces strictly more records at the same budget (because dead-branch pruning is more aggressive). **Empirical scaling (updated 2026-05-23 by v2 100T):** the v2/v1 record uplift is +4.83% at 11.2T and **+6.74% at 100T** — the prior extrapolation that the ratio would approach 1.00 at ≥100T was wrong, and v2's prune stack retains substantive uplift at deeper budgets. Whether this trend continues at 560T+ is unknown; the v3 lineage (Phase 9-14 roadmap, post-v2 100T) is designed to produce a sha-preserving but cheaper canonical pipeline and will inform the 560T solver decision.

### Deprecated canonicals

| Scale | sha256 | Records | Reason | Replacement |
|---|---|---|---|---|
| d3 5.6T | `c34390c00a2a871d78f49dd419779c0f649ed8271387c424ac4d36e0f3910dbd` | 467,483,137 | Determined to be irreproducible from any extant git commit by the 2026-05-12 bisect investigation. All v1 code from cdd8575 (Apr 30) through 2cf8771 (May 10) on either DFS path produces `f66920c1…` with 467,484,167 records (+1,030 vs this canonical). The records in c34390c0 are all valid C1-C5 orderings; the canonical is incomplete by 1,030 records that modern code finds within the same budget. **Updated 2026-05-14 explanation:** the +1,030 delta most likely reflects records lost via imperfect resume after the documented Spot eviction at 90% during the Apr 29-30 run (per investigation doc, 8 "missing branches" were re-run and merged in). Pre-resume-fix code (pre `1d4dc6e`/`c3ad271`/`d11bc0d`/`c3d3ad6`) is more interruption-vulnerable. The earlier `f42f2ae` OOB hypothesis is now considered an incidental coincident bug, not the cause — the OOB lives in post-enum stats code that doesn't affect solutions.bin per the investigation. See [HISTORY.md](HISTORY.md) and `petersm3/x:roae` investigation doc. | `f66920c10adfc4882cc75fce9aeb2f07a99d36159ecb8b2c58b2d22d13867a21` (active above) |
| d3 10T | `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` | 706,422,987 | Generated 2026-04-18 by pre-everything code (predates all the resume bug fixes 1d4dc6e/c3ad271/d11bc0d/c3d3ad6, and predates iterative DFS + checkpoint correctness work). Cascade Phase B re-derivation 2026-05-13 on modern code (post-fix HEAD a2ead96, cross-build verified Build A + Build B) produces `b85c8871…` with 706,427,594 records — **+4,607 records vs this canonical**. Like the c34390c0 delta, the records in f7b8c4fb are all valid C1-C5 canonical orderings; this canonical is incomplete by 4,607 records likely lost via imperfect resume during interruptions in the 2026-04-18 run on pre-resume-fix code. Deprecated 2026-05-14. | `b85c887128ce9881229741380a799c4e1608335df438cedc3da9e087fd94dbbc` (active above) |

## Reproducibility parameters

Each canonical is fully reproduced by the parameter set below. `SOLVE_DEPTH` is the per-thread DFS depth; `SOLVE_NODE_LIMIT` is the global budget; `SOLVE_PER_SUB_BRANCH_LIMIT` is the per-cell budget; thread count must be 128 for byte-identical reproduction at the depth-3 canonicals (the merge dedup step is order-stable so other counts produce the same sha if the enumeration completes, but eviction-recovery and resume paths assume 128).

| Canonical | Env vars |
|---|---|
| Selftest | `solve --selftest` (internal fixed scenario; no env needed) |
| d3 5.6T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=5600000000000 SOLVE_PER_SUB_BRANCH_LIMIT=35361598 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |
| d3 11.2T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=11200000000000 SOLVE_PER_SUB_BRANCH_LIMIT=70723196 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |
| d3 100T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=100000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=631456644 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |
| d3 10T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=10000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=63146557 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` (also produces same sha at SOLVE_THREADS=64; cascade Build A+B both used 64 due to westus3 D128 Spot capacity issues 2026-05-13) |
| d2 10T | `SOLVE_DEPTH=2 SOLVE_NODE_LIMIT=10000000000000 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |

Solver invocation for the multi-trillion-node canonicals: `solve 0 128`.

For the full `solve.c` command-line reference (every subcommand, env var, and exit code referenced in this document), see [SOLVE_CLI.md](SOLVE_CLI.md).

## Solver version

**v1** is the solver lineage anchored at this repo's `main` branch. The current head reproduces every v1 canonical above. Specific commits that established each canonical are recorded in [HISTORY.md](HISTORY.md). v1 binary builds on stock toolchain — no patched glibc, no jemalloc, no profiling instrumentation:

```
# Minimum to reproduce canonical sha:
gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm

# Recommended (sha-preserving, ~2% faster — Phase 1c LTO validated 2026-05-15 on D64 Zen 4):
gcc -O3 -flto -pthread -fopenmp -march=native -o solve solve.c -lm
```

Both commands produce the canonical selftest sha `403f7202…` and reproduce every canonical above byte-identically. `-flto` (link-time optimization) reduces binary size ~1-2% and produces a ~2% wall-time speedup at 100B-node canonical-correlation scale on AMD Zen 4 with tight run-to-run variance (stddev 0.11% across 4 trials). Drop it if your toolchain doesn't support LTO.

A future **v2** lineage will introduce search-tree pruning optimizations that change the per-cell coverage shape under truncation; v2 will produce a different canonical sha at each scale. v2 retires v1 only when v2's bundled re-baseline establishes new shas and they are recorded in this file with status changes.

## How to verify a `solutions.bin`

```
sha256sum solutions.bin
# Compare to the row above.
```

For independent constraint-spec verification (slower than sha but cross-checks the binary's enumeration logic):

- C-side: `solve --verify solutions.bin` — checks every record satisfies C1+C2+C3 per [SPECIFICATION.md](SPECIFICATION.md).
- Python-side: `python3 verify.py --jobs N solutions.bin` — independent re-implementation. The `--jobs` flag parallelizes; `--jobs 128` matches the canonical's enumeration parallelism but any value works for verification.

Both verifiers operate without reference to the canonical sha; they validate the file against the constraint specification directly.

## How to re-derive from scratch

```
git clone https://github.com/petersm3/roae
cd roae
gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm
./solve --selftest                    # must print sha 403f7202
ulimit -s unlimited                   # required at large scales
<env vars from the table above> ./solve 0 128
sha256sum solutions.bin               # must match the canonical row
```

The smallest validation reproduces in seconds (selftest). The d3 10T canonical reproduces in approximately 60-90 minutes on a 128-vCPU machine. The d3 100T reproduces in approximately 11-19 hours. Lower thread counts work; the wall time scales roughly linearly with `1/threads` for d3 enumeration.

## Format

`solutions.bin` is a 32-byte header followed by 32-byte records. Each record encodes a canonical ordering of the 64 hexagrams. See [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) for the byte-level encoding and the dedup semantics.

Records are deduplicated at merge time by canonical form (orient-bit-masked); the reported record count equals the number of distinct canonical orderings the enumeration discovered within its budget. The full mathematical search space is much larger than any partial enumeration here; canonicals at higher node budgets reveal more of it.

## Validation status

A canonical is listed as Active when at least one of the following holds:
- Single-shot full-enumeration reproduces the sha byte-identically.
- Multi-path equivalence (e.g., 56-branch decomposition merged globally) reproduces the same sha.
- Cross-architecture reproduction (x86 + ARM) yields the same sha.

Each canonical above has been validated by at least one of these paths; the d3 11.2T canonical has been validated by all three across eight independent paths. Detailed validation history per canonical is recorded in [HISTORY.md](HISTORY.md) and [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md).

## Recent re-derivation witnesses (post-2026-05-06 wipe recovery)

The 2026-05-06 self-inflicted wipe of solver-data-westus3 destroyed the original 100T canonical solutions.bin bytes (the sha was preserved in this file). Two independent re-derivations completed on 2026-05-09/10:

- **T9+c.1 (full-enum, `solve 0 128`) — 2026-05-09 05:55 UTC** — produced sha `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5` byte-identically. Phase 2 sha PASS, phase 3 `solve --verify` PASS, phase 4 `verify.py --jobs 16` PASS. Run on D16als_v7 Regular westus3.
- **T9+d (62-branch loop, `solve --branch p1 o1` × 62 + `solve --merge`) — 2026-05-10 06:07 UTC** — produced sha `915abf30…` byte-identically; phase 7 sha PASS, phase 8 `solve --verify` PASS, phase 9 `verify.py --jobs 128` PASS. Run on D64als_v7 Spot (phase 5) → D16als_v7 Regular (phase 6-8) → D128als_v7 Regular (phase 9).

T9+d's match constitutes the empirical partition-invariance witness at 100T scale: the canonical sha is byte-stable across both the full-enum execution path and the per-branch-loop execution path. Operational-detail logs for both runs are archived in private `petersm3/x:roae/canonical_runs/` (small text-format witness files only — solutions.bin bytes are warm on solver-data-westus3 + cold-stored as solutions.bin.gz in `roaecanonical2026/canonical-archive/t9c1/`).
