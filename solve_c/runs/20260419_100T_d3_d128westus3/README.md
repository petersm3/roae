# 100T depth-3 D128als_v7 westus3 canonical enumeration — archive

*Completed run 2026-04-20 00:45 UTC.*

**Date:** 2026-04-19
**SKU:** Standard_D128als_v7 (spot, westus3)
**Purpose:** First partial enumeration at 10× budget over the canonical
10T d3 run. Establishes a deeper partial sha, supersedes 10T as the
richest partial enumeration dataset.
**Solver commit at enumeration launch:** `edccb16` / `adf1505` (docs-only
follow-ups after; enumeration and merge semantics unchanged since the
10T d3 canonical was established — partition invariance guarantees
the 100T sha depends only on solver + inputs, not subsequent doc edits).

## Canonical sha (100T partition, 2026-04-19)

- **sha256**: `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5`
- **Records (canonical unique orderings)**: **3,432,399,297** (~3.43 billion)
- **Solutions.bin size**: 109,836,777,536 bytes (102.3 GB)
- **Pre-dedup records processed**: 13,832,832,979
- **Merge chunks produced**: 60,533 (external merge via P40 Premium SSD scratch)
- **Distinct from 10T sha** `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` because 100T has a different `SOLVE_NODE_LIMIT` parameter. Both are valid canonical references at their respective budgets (per PARTITION_INVARIANCE.md, sha is a function of solver + inputs).

## Relationship to 10T canonical

100T d3 solution set is a **proper superset** of 10T d3's. Every ordering found in 10T (706,422,987) is also in 100T (because each sub-branch at 100T has 10× the budget and explores strictly more of its tree before hitting the node-budget ceiling). The increment over 10T reflects sub-branch trees that needed >63M but ≤631M nodes to surface their C3-valid configurations.

**Count comparison:**
- 10T d3: 706,422,987 canonical orderings
- 100T d3: **3,432,399,297** canonical orderings
- Ratio: **~4.86×** at 10× the node budget (diminishing-returns scaling — expected, since early sub-branches saturate quickly while deep/hard sub-branches need proportionally more budget to surface more orderings).

Expected count at launch was 1-2B; actual 3.43B exceeded the estimate.

## Run parameters

- Format version: 1
- Header size: 32 bytes
- Record size: 32 bytes
- `SOLVE_DEPTH=3`, 158,364 sub-branches
- `SOLVE_NODE_LIMIT=100000000000000` (100T)
- `SOLVE_THREADS=128` (full D128als_v7)
- External merge: `SOLVE_MERGE_MODE=external SOLVE_TEMP_DIR=/mnt/merge-scratch` (P40 Premium SSD 2 TB attached for merge duration, destroyed after per standing pattern)

## Timings

| Phase | Wall time | Wall seconds |
|---|---|---|
| Enumeration (158,364 sub-branches × 631M-node budget each, 128 threads) | **11h 22m 07s** | **40,927** |
| External merge (P40 Premium SSD temp, 2 TB) | **5h 25m 38s** | **19,538** |
| **Total (enum + merge)** | **16h 47m 45s** | **60,465** |

Projected at launch (2026-04-19 08:00 UTC): enum ~11h (**actual 11h 22m 07s ✓ on target**), merge ~2-3h (**actual 5h 25m** — longer than projected; the 2-3h estimate was a rough guess, not a rigorous projection; 100T pre-dedup input at 13.8B records is ~10× the 10T input so ~10× merge time is realistic in retrospect), total ~13-14h (**actual 16h 48m** — a bit long but within tolerances).

**Enumeration complete (ENUMDONE fired 2026-04-19 ~19:20 UTC)**. Sustained ~2,445 M nodes/s peak rate across 127-128 active threads. Total nodes processed: 100,000,000,000,000 (100 T per parameter). Final sub-branch (158,364/158,364, pair1=31 orient1=1 pair2=30 orient2=0) completed at 40,925s wall. All 158,364 sub-branches BUDGETED (hit per-branch node ceiling rather than exhausted).

## What's in this directory

| File | Size | Purpose |
|---|---|---|
| `solutions.sha256` | 80 B | sha256 digest (primary integrity check) |
| `solutions.meta.json` | ~710 B | format version, record count, generator, timestamp |
| `enum_output.log.gz` | ~MB | compressed enumeration stdout |
| `external_merge.log.gz` | ~KB | compressed external-merge stdout with chunk progression |
| `README.md` | this file | run narrative + placeholders filled in |

## What's NOT in this directory (and why)

`solutions.bin` (actual 102.3 GB at 100T depth — exceeded the 30-65 GB estimate) is NOT archived here. It lives on the `solver-data-westus3` managed disk (westus3, 1.5 TB Standard_LRS). The sha is the reproducibility anchor; regenerating the bytes is a 13-hour / ~$30 compute task if ever needed (partition invariance guarantees byte-identical reproduction).

## How to re-obtain `solutions.bin`

Option 1 — re-enumerate from scratch (~$30, ~13 hrs on D128 spot):
```
ssh solver@<a D128als_v7 westus3 VM with 1.5 TB disk>
SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=100000000000000 SOLVE_THREADS=128 ./solve 0
SOLVE_MERGE_MODE=external SOLVE_TEMP_DIR=/mnt/merge-scratch ./solve --merge
sha256sum solutions.bin  # must equal [[TBD from solutions.sha256]]
```

Option 2 — mount `solver-data-westus3` disk on any westus3 VM and read directly.

## Verification status at archive time

- `./solve --merge` internal post-validation: **PASS** ("ALL CONSTRAINTS VERIFIED" in merge log; 0 errors)
- King Wen present: YES (in merge-stage validation)
- All records C1-C5 valid: YES (0 errors across all 3,432,399,297 records)
- Sort order + dedup: OK (no duplicates, strict sort order)
- Independent `--verify` pass: (pending — launched 2026-04-20 00:47 UTC)
- `--analyze` output: (pending — launched 2026-04-20 00:47 UTC)
- `--c3-min` (Open Question #7 Phase A Day 1 MVP): **COMPLETE** (wall 227s).
  - **Minimum C3 observed: 424** across the 3.43B records
  - **Count at minimum: 221 records** (0.00000644% of records)
  - **KW found at C3 = 776** (ceiling of the constraint C3 ≤ 776)
  - **Histogram of bottom 10**: 424:221, 432:6378, 440:12283, 448:47606, 456:83077, 464:201693, 472:293340, 480:540141, 488:702851, 496:1155122
  - **Finding (negative, Phase A MVP)**: KW is NOT the C3-minimum under C1+C2+C3. Axiom "minimize C3" alone does not uniquely derive KW. The 221 C3=424 records form a "C3-extremal family" structurally distinct from KW. KW sits at the C3 ceiling, not the floor.
  - See `c3_min_output.log` in this directory for the full output and [DERIVABILITY_STRATEGY.md](../../../x/roae/DERIVABILITY_STRATEGY.md) context.

## 4-corners validation context

This run was generated on D128als_v7 (Zen 5 Turin) westus3 using external-merge mode. The 10T d3 companion run (see `../20260419_10T_d3_d128westus3/`) empirically validated that this hardware + merge-mode combo produces byte-identical output to F64 westus2 via both external and in-memory paths. The 100T sha here is expected to be reproducible via the same 4 corners (Zen 4 F64 + external merge, Zen 4 F64 + heap-sort, Zen 5 D128 + external, Zen 5 D128 + heap-sort — though only the D128-external path has been run at 100T scale so far).
