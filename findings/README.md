# ROAE — Findings

This directory holds **paper-citable scientific findings** that have stabilized
beyond working-note status. Each entry has:

- A clear *Result* sentence at the top
- Reproduction commands using committed data + `solve.c`
- Cross-links to working-version analysis in the staging repo (`petersm3/x/roae`)
  for context, iterative process, and additional intermediate data

When a finding here is referenced, cite the file (e.g. `findings/SYMMETRY_SEARCH.md`)
plus the underlying canonical sha or run-archive path.

## Current findings

| File | Topic | Result |
|---|---|---|
| [`SYMMETRY_SEARCH.md`](SYMMETRY_SEARCH.md) | Hamming-class symmetry search | **NEGATIVE.** No bit-position permutation is a symmetry of the C1 ∩ C2 ∩ C3 canonical. All 47 non-trivial candidates falsified at 100T-d3. |
| [`PASS1_TRAJECTORY_DETERMINISM.md`](PASS1_TRAJECTORY_DETERMINISM.md) | Solver determinism on the yield-16 laggard branch | Two independent runs of `--sub-branch 22 0 30 1 20 0` retrace each other to <0.2% across 10¹⁰ → 10¹³ nodes. Free reproducibility check for any future re-run. |
| [`PARTITION_STABILITY_BOUNDARIES.md`](PARTITION_STABILITY_BOUNDARIES.md) | Boundary {25, 27} stability across partitions | Boundaries 25 and 27 are mandatory in every minimum-boundary set across d2 10T, d3 10T, and d3 100T canonicals. Other minimum components are partition-depth-dependent. |

## Convention going forward

Findings docs are promoted from `petersm3/x/roae` after they:

1. Have a clear, scoped result statement
2. Are unlikely to be revised in light of further work
3. Have reproduction commands that work against committed data or sha-anchored archives
4. Would survive being cited externally (e.g., in a publication)

The staging-repo version is preserved (linked from the promoted version) so the iterative analysis trail remains discoverable.

## Other authoritative scientific records (root of this repo)

- [`SOLVE.md`](../SOLVE.md) — full technical record
- [`SOLVE-SUMMARY.md`](../SOLVE-SUMMARY.md) — plain-language version
- [`CRITIQUE.md`](../CRITIQUE.md) — known limitations and methodological caveats
- [`SPECIFICATION.md`](../SPECIFICATION.md) — formal constraint definitions
- [`PARTITION_INVARIANCE.md`](../PARTITION_INVARIANCE.md) — canonical-sha reproducibility theorem
- [`HISTORY.md`](../HISTORY.md) — iterative project narrative including missteps and corrections
- [`enumeration/LEADERBOARD.md`](../enumeration/LEADERBOARD.md) — canonical run records and shas
- [`CITATIONS.md`](../CITATIONS.md) — prior literature and attribution
