# Canonical hashes

The reproducibility anchor for ROAE is the sha256 of `solutions.bin`, not the file itself. Any `solutions.bin` produced with the matching solver version and inputs must reproduce one of the hashes below byte-identically.

A mismatch means a bug was introduced (in the solver, the build toolchain, or the runtime environment), not that a new result was found.

## Active canonicals

| Scale | sha256 | Records | Records (decimal) | Solver | Status |
|---|---|---|---|---|---|
| Selftest baseline (100M nodes) | `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e` | 135,780 | 1.35780 × 10⁵ | v1 | **Active** — reproducible across every binary build tested |
| d3 5.6T | `f66920c10adfc4882cc75fce9aeb2f07a99d36159ecb8b2c58b2d22d13867a21` | 467,484,167 | 4.67484 × 10⁸ | v1 (modern) | **PROVISIONAL** — verified across 6 builds on shared VM toolchain (2026-05-12, including the cascade Build A re-derivation: Spot D128als_v7 enum + Standard D32als_v7 separate merge, sha confirmed at 17:54 UTC); cross-build verification on independent toolchain pending — scheduled per CURRENT_PLAN.md Phase B |
| d3 11.2T | `0c0fe37cf449cbc6e2754583964a60c185a7b387ee522fa43a8aac4fdb055db7` | 759,608,573 | 7.59609 × 10⁸ | v1 | **PENDING REVALIDATION** — last cross-build verified 2026-05-02 (pre-`f42f2ae`); modern code may differ (analogous to d3 5.6T undercount). Re-derive scheduled per CURRENT_PLAN.md cascade |
| d3 100T | `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5` | 3,432,399,297 | 3.43240 × 10⁹ | v1 (modern) | **Active** — generated 2026-05-09 by post-`f42f2ae` code (T9+c.1 + T9+d witnesses); provenance verified 2026-05-12 |
| d3 10T | `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` | 706,422,987 | 7.06423 × 10⁸ | v1 | **PENDING REVALIDATION** — generated 2026-04-18 (pre-everything). Re-derive scheduled |
| d2 10T | `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2` | 286,357,503 | 2.86358 × 10⁸ | v1 | **PENDING REVALIDATION** — generated 2026-04-18 (pre-everything). Re-derive scheduled |

Records are unique canonical orderings; orient variants are collapsed at merge time. File format is documented in [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md).

### Deprecated canonicals

| Scale | sha256 | Records | Reason | Replacement |
|---|---|---|---|---|
| d3 5.6T | `c34390c00a2a871d78f49dd419779c0f649ed8271387c424ac4d36e0f3910dbd` | 467,483,137 | Determined to be irreproducible from any extant git commit by the 2026-05-12 bisect investigation. All v1 code from cdd8575 (Apr 30) through 2cf8771 (May 10) on either DFS path produces `f66920c1…` with 467,484,167 records (+1,030 vs this canonical). The records in c34390c0 are all valid C1-C5 orderings; the canonical is incomplete by 1,030 records that modern code finds within the same budget. See [HISTORY.md](HISTORY.md) §"May 11–12, 2026 PDT — multi-scale v1/v2 pipeline, then canonical c34390c0 (d3 5.6T) found irreproducible from git history" and the operator-facing investigation doc in the `petersm3/x:roae` staging repo. | `f66920c10adfc4882cc75fce9aeb2f07a99d36159ecb8b2c58b2d22d13867a21` (active above) |

## Reproducibility parameters

Each canonical is fully reproduced by the parameter set below. `SOLVE_DEPTH` is the per-thread DFS depth; `SOLVE_NODE_LIMIT` is the global budget; `SOLVE_PER_SUB_BRANCH_LIMIT` is the per-cell budget; thread count must be 128 for byte-identical reproduction at the depth-3 canonicals (the merge dedup step is order-stable so other counts produce the same sha if the enumeration completes, but eviction-recovery and resume paths assume 128).

| Canonical | Env vars |
|---|---|
| Selftest | `solve --selftest` (internal fixed scenario; no env needed) |
| d3 5.6T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=5600000000000 SOLVE_PER_SUB_BRANCH_LIMIT=35361598 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |
| d3 11.2T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=11200000000000 SOLVE_PER_SUB_BRANCH_LIMIT=70723196 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |
| d3 100T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=100000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=631456644 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |
| d3 10T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=10000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=63146557 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |
| d2 10T | `SOLVE_DEPTH=2 SOLVE_NODE_LIMIT=10000000000000 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |

Solver invocation for the multi-trillion-node canonicals: `solve 0 128`.

For the full `solve.c` command-line reference (every subcommand, env var, and exit code referenced in this document), see [SOLVE_CLI.md](SOLVE_CLI.md).

## Solver version

**v1** is the solver lineage anchored at this repo's `main` branch. The current head reproduces every v1 canonical above. Specific commits that established each canonical are recorded in [HISTORY.md](HISTORY.md). v1 binary builds on stock toolchain — no patched glibc, no jemalloc, no profiling instrumentation:

```
gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm
```

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
