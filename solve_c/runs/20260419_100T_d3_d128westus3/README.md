# 100T depth-3 D128als_v7 westus3 canonical enumeration — archive

*Template — will be filled in with concrete values when MERGEDONE fires.
Placeholders marked `[[TBD]]`.*

**Date:** 2026-04-19
**SKU:** Standard_D128als_v7 (spot, westus3)
**Purpose:** First partial enumeration at 10× budget over the canonical
10T d3 run. Establishes a deeper partial sha, supersedes 10T as the
richest partial enumeration dataset.
**Solver commit:** `0a4366b` or later (same enumeration semantics as
`edccb16` — docs-only follow-up; solve.c unchanged).

## Canonical sha (100T partition, 2026-04-19)

- **sha256**: `[[TBD — paste from /data/solutions.sha256 when MERGEDONE]]`
- **Records**: `[[TBD — canonical orderings, paste from meta.json]]`
- **Solutions.bin size**: `[[TBD]]` bytes
- **Distinct from 10T sha** `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` because 100T has a different `SOLVE_NODE_LIMIT` parameter. Both are valid canonical references at their respective budgets (per PARTITION_INVARIANCE.md, sha is a function of solver + inputs).

## Relationship to 10T canonical

100T d3 solution set is a **proper superset** of 10T d3's. Every ordering found in 10T (706,422,987) is also in 100T (because each sub-branch at 100T has 10× the budget and explores strictly more of its tree before hitting the node-budget ceiling). The increment over 10T reflects sub-branch trees that needed >63M but ≤631M nodes to surface their C3-valid configurations.

Expected 100T count: likely 1-2B canonical orderings. Final value TBD from meta.json.

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
| Enumeration (158,364 sub-branches × 631M-node budget each, 128 threads) | `[[TBD]]` | `[[ENUMERATION_WALL_SEC]]` |
| External merge (P40 Premium SSD temp) | `[[TBD]]` | `[[MERGE_WALL_SEC]]` |
| **Total** | `[[TBD]]` | `[[TBD]]` |

Projected at launch (2026-04-19 08:00 UTC): enum ~11h, merge ~2-3h, total ~13-14h.

## What's in this directory

| File | Size | Purpose |
|---|---|---|
| `solutions.sha256` | 80 B | sha256 digest (primary integrity check) |
| `solutions.meta.json` | ~710 B | format version, record count, generator, timestamp |
| `enum_output.log.gz` | ~MB | compressed enumeration stdout |
| `external_merge.log.gz` | ~KB | compressed external-merge stdout with chunk progression |
| `README.md` | this file | run narrative + placeholders filled in |

## What's NOT in this directory (and why)

`solutions.bin` (projected ~30-65 GB at 100T depth) is NOT archived here. It lives on the `solver-data-westus3` managed disk (westus3, 1.5 TB Standard_LRS). The sha is the reproducibility anchor; regenerating the bytes is a 13-hour / ~$30 compute task if ever needed (partition invariance guarantees byte-identical reproduction).

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

- `./solve --merge` internal post-validation: `[[PASS/FAIL from log]]`
- King Wen present: `[[YES from log]]`
- All records C1-C5 valid: `[[YES from log]]`
- Sort order + dedup: `[[OK from log]]`

## 4-corners validation context

This run was generated on D128als_v7 (Zen 5 Turin) westus3 using external-merge mode. The 10T d3 companion run (see `../20260419_10T_d3_d128westus3/`) empirically validated that this hardware + merge-mode combo produces byte-identical output to F64 westus2 via both external and in-memory paths. The 100T sha here is expected to be reproducible via the same 4 corners (Zen 4 F64 + external merge, Zen 4 F64 + heap-sort, Zen 5 D128 + external, Zen 5 D128 + heap-sort — though only the D128-external path has been run at 100T scale so far).
