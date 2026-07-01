# Visualization — King Wen d3 560T canonical

> **The d3 560T canonical (`9a968fa2…`) is CANONICAL-verified** (resolved 2026-06-30). It was SUSPECT
> from 2026-06-21 (a proven eviction-resume defect + 5 Spot evictions on the pre-fix solver); a
> from-scratch re-run on the **fixed** solver reproduced `9a968fa2` byte-for-byte (identical sha,
> identical 10,525,271,997 records, across 7 fresh evictions that all resumed cleanly), so the original
> run was complete and these figures stand unchanged. See
> [`../documentation/CANONICAL_HASHES.md`](../documentation/CANONICAL_HASHES.md) §"d3 560T".

This directory visualizes the **complete d3 560T canonical solution set** — every King Wen ordering
satisfying constraints C1–C5 found within the per-cell node budget (sha `9a968fa2…`, 10,525,271,997
records). The visuals come in two families:

| Page | What it covers |
|---|---|
| **[viz_graphs.md](viz_graphs.md)** | **How the space behaves / how the run executed** — the solution-count-vs-budget growth curve (sublinear, α ≈ 0.67) and (from the 1120T extension onward) campaign telemetry plots. |
| **[viz_pca.md](viz_pca.md)** | **Where each solution sits** — four 2-D PCA scatter projections of the solution set, colored by edit-distance-to-KW, complement-distance (C3), position-2 branch, and C6/C7 adjacency. |

The two pages cross-link each other; start with whichever question you have. This README is the index
and does not re-explain individual plots.

## Data provenance

- **Canonical:** d3 560T, sha256 `9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`
  (decompressed/logical), 10,525,271,997 records, current main lineage.
- **Figures:** committed under [`../runs/20260608_560T_9a968fa2/viz/`](../runs/20260608_560T_9a968fa2/viz/)
  (PNG for inline viewing + SVG vector source). The run-directory is sha-named; the 2026-06-30 re-run is
  byte-identical, so these figures are the canonical's figures regardless of which run produced them.
- The sha is sourced from the `.sha256` sidecar / `CANONICAL_HASHES.md`, never hardcoded from prose.

## Tooling

- **`visualize.py`** — the viz generator. Default mode produces the four PCA projections of a canonical
  `solutions.bin` (axis labels report the % of total variance captured by PC1/PC2). `--telemetry
  <csv>` renders campaign time-course plots.
- **`growth_curve.py`** — the dedicated growth-curve generator (records vs per-cell node budget, log-log,
  across canonical depths, with the power-law fit and the 1120T projection). *Consolidating this into
  `visualize.py --growth` is a tracked follow-up.*

Figures are archived per-run under `runs/<run-id>/viz/`; never inline figures into `viz/` itself.

## Regenerating from a fresh solutions.bin

```bash
pip install numpy matplotlib   # not otherwise project dependencies
# Run from the desired output directory so outputs land there:
cd runs/<run-id>/viz/
python3 ../../../../viz/visualize.py /path/to/solutions.bin     # the 4 PCA plots
python3 ../../../../viz/growth_curve.py                         # the growth curve
```

`visualize.py` scales to billions of solutions in a few minutes — PCA on the 32×32 covariance is nearly
instant; the bottleneck is reading `solutions.bin` from disk (gz-aware). Outputs are 4 PNG + 4 SVG
(~10-15 MB total) plus the growth curve. Per-run directories may carry their own brief, dataset-specific
`README.md`; this file is the stable index across all runs.
