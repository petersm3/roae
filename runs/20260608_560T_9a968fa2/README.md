# 560T depth-3 canonical enumeration — run record (figures only)

*Added 2026-10-02 (Q-943). Until this date the directory held only `viz/`, with no README, sha or
meta record. This file says what the directory holds and where the run's identity is recorded. It
adds no new measurement.*

## What this run is

The d3 560T canonical, the deepest enumeration the project has published. Its identity is recorded
in [`documentation/CANONICAL_HASHES.md`](../../documentation/CANONICAL_HASHES.md) §"d3 560T — current
deepest", which is the source for the three values below:

- **sha256:** `9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`
- **Records:** 10,525,271,997
- **File size:** 336,808,703,936 bytes (32-byte header + 10,525,271,997 × 32-byte records)

The same section gives the run's parameters, its 2026-06-21 to 2026-06-30 SUSPECT period, and the
from-scratch re-run that reproduced the sha byte for byte.

## What is in this directory

- `viz/` — figures drawn from the run: the four PCA projections of the solution set (`viz_*.png` and
  `.svg`), the growth curve across the canonicals, and the re-run's telemetry plots with their viewer
  page [index.html](viz/index.html). They are explained in [`viz/archive/viz_pca.md`](../../viz/archive/viz_pca.md)
  and [`viz/archive/viz_graphs.md`](../../viz/archive/viz_graphs.md). They are kept as committed and
  are not regenerated.

## What is not in this directory

Unlike the 100T record in [`../20260419_100T_d3_d128westus3/`](../20260419_100T_d3_d128westus3/),
this directory has no `solutions.sha256`, no `solutions.meta.json` and no run logs (enumeration,
`--analyze`, `--c3-min` or verify). The solutions file itself (about 337 GB) is not in this
repository. Any 560T figure cited elsewhere, such as the `--c3-min` counts in
[TR-12](../../reports/TR12_QUERY_PROGRAM.md), is cited and cannot be re-run from this tree.

*Developed with AI assistance (Claude, Anthropic). Errors are Claude's; corrections welcome.*
