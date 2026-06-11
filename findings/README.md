# findings/ — consolidated into ../documentation/ (2026-06-11)

The three findings docs that previously lived here have been moved into the
top-level `documentation/` directory, alongside the other authoritative
scientific records. This consolidation reduces directory sprawl and
eliminates a "second tier" hierarchy that was easy to miss during repo-wide
review passes.

**File-location map (2026-06-11 → present):**

| Old (this directory) | New |
|---|---|
| `findings/PARTITION_STABILITY_BOUNDARIES.md` | [`../documentation/PARTITION_STABILITY_BOUNDARIES.md`](../documentation/PARTITION_STABILITY_BOUNDARIES.md) |
| `findings/SYMMETRY_SEARCH.md` | [`../documentation/SYMMETRY_SEARCH.md`](../documentation/SYMMETRY_SEARCH.md) |
| `findings/PASS1_TRAJECTORY_DETERMINISM.md` | [`../documentation/PASS1_TRAJECTORY_DETERMINISM.md`](../documentation/PASS1_TRAJECTORY_DETERMINISM.md) |

A fourth stable-finding doc was added directly at the new location:

- [`../documentation/BOUNDARY_MINIMUM_NON_MONOTONE.md`](../documentation/BOUNDARY_MINIMUM_NON_MONOTONE.md) — 560T result showing the boundary-minimum trajectory is non-monotone with scale (added 2026-06-11).

This redirect stub is preserved (rather than the entire directory being
git-removed) so that any external incoming links to `findings/...` paths
get a sensible 404 → redirect experience rather than a hard 404.

**See [`../documentation/README.md`](../documentation/README.md) §"Stable scientific findings"** for the consolidated index.
