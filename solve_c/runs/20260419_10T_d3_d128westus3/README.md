# 10T depth-3 D128als_v7 westus3 validation — archive

**Date:** 2026-04-19
**SKU:** Standard_D128als_v7 (spot, westus3)
**Purpose:** Cross-region + cross-SKU + cross-generation empirical
validation of the Partition Invariance theorem (see
[PARTITION_INVARIANCE.md](../../PARTITION_INVARIANCE.md)).
**Solver commit:** (pending — this run uses the uncommitted working tree
containing in-place heapsort, --sub-branch CLI, auto-threshold fix, and
SOLVE_CONCENTRATE_BUDGET). The solve.c used here is **semantically
identical** to the F64 canonical in enumeration path; changes affect
merge path + new CLI mode only. Matching sha proves this.

## Canonical sha confirmation

- **sha256**: `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e`
- **Matches canonical**: YES (byte-identical to F64 westus2 Phase B / Phase C / heap-sort merge)
- **Records**: 706,422,987 canonical pair orderings
- **Solutions.bin size**: 22,605,535,616 bytes (22.6 GB)

## What's in this directory

| File | Size | Purpose |
|---|---|---|
| `solutions.sha256` | 80 B | sha256 digest (from the external-merge run, per standing canonical) |
| `solutions.meta.json` | 710 B | format version, record count, generator, timestamp (external merge) |
| `solutions_inmem.sha256` | 80 B | in-memory-merge sha (same sha — both merge modes produced identical output) |
| `solutions_inmem.meta.json` | 710 B | in-memory-merge meta |
| `enum_output.log.gz` | ~1.5 MB | full stdout of the 10T enumeration (158,364 sub-branches BUDGETED) |
| `external_merge.log.gz` | ~1.3 KB | external-merge phase log with chunk-sort progression |

## What's NOT in this directory (and why)

`solutions.bin` (22.6 GB) is NOT archived here. It lives on
`solver-data-westus3` managed disk (westus3, 300 GB Standard_LRS) and is
byte-identical to the canonical on `solver-data` / `solver-validate-d3`
(westus2). Storing a third copy adds no information.

## Timings

| Phase | Wall time | Wall seconds |
|---|---|---|
| Enumeration (158,364 sub-branches × 63M-node budget each, 128 threads) | **82m 57s** | 4977 |
| In-memory heap-sort merge (2.77B pre-dedup → 706M canonical) | **51m 47s** | 3107 |
| External merge (same shards, P20 Premium SSD temp via SOLVE_TEMP_DIR) | **42m 59s** | 2579 |
| **Total (enum + both merge passes)** | **2h 57m 43s** | 10663 |

**Cost (D128als_v7 spot + P20 Premium SSD prorated for external merge):
~$5.05.**

## 4-corners validation grid — complete

| | External merge | In-memory heap-sort |
|---|---|---|
| F64 Zen 4 westus2 | ✅ Phase B canonical | ✅ heap-validate-vm (2026-04-19) |
| **D128 Zen 5 westus3** | **✅ this run, sha match** | **✅ this run, sha match** |

All 4 combinations of {CPU generation, merge algorithm} produce
byte-identical canonical output. Empirical confirmation of
PARTITION_INVARIANCE.md Theorem.

## Run parameters

- Format version: 1
- Header size: 32 bytes
- Record size: 32 bytes
- `SOLVE_DEPTH=3`, 158,364 sub-branches
- `SOLVE_NODE_LIMIT=10000000000000` (10T)
- `SOLVE_THREADS=128` (full D128als_v7)
- External merge: `SOLVE_MERGE_MODE=external SOLVE_TEMP_DIR=/mnt/merge-scratch` (P20 Premium SSD 512 GB)

## Verification status at archive time

- `./solve --merge` internal post-validation: PASS (both in-memory and external runs)
- sha256 match: PASS against canonical
- External-merge self-validation: "ALL CONSTRAINTS VERIFIED" emitted by solver
