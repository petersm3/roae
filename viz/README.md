# Visualization — King Wen d3 560T canonical

> **The d3 560T canonical (`9a968fa2…`) is CANONICAL-verified** (resolved 2026-06-30). It was SUSPECT
> from 2026-06-21 (a proven eviction-resume defect + 5 Spot evictions on the pre-fix solver); a
> from-scratch re-run on the **fixed** solver reproduced `9a968fa2` byte-for-byte (identical sha,
> identical 10,525,271,997 records, across 7 fresh evictions that all resumed cleanly), so the original
> run was complete and these figures stand unchanged. See
> [`../documentation/CANONICAL_HASHES.md`](../documentation/CANONICAL_HASHES.md) §"d3 560T".

This directory visualizes the **complete d3 560T canonical solution set** — every King Wen ordering
satisfying constraints C1–C5 found within the per-cell node budget (sha `9a968fa2…`, 10,525,271,997
records) — and, in a third family, the **compiled superspace** the enumeration is a slice of. The
enumeration-derived visuals come in two families:

| Page | What it covers |
|---|---|
| **[viz_graphs.md](viz_graphs.md)** | **How the space behaves / how the run executed** — the solution-count-vs-budget growth curve (sublinear, α ≈ 0.67) and campaign telemetry plots (planned for the 1120T extension, which is not going ahead — 2026-08-01). |
| **[viz_pca.md](viz_pca.md)** | **Where each solution sits** — four 2-D PCA scatter projections of the solution set, colored by edit-distance-to-KW, complement-distance (C3), position-2 branch, and C6/C7 adjacency. |

The two pages cross-link each other; start with whichever question you have. This README is the index
and does not re-explain individual plots.

### Planned, not yet drawn (accepted 2026-09-04, Q-308 — both zero-dollar)

| Page | What it covers | Status |
|---|---|---|
| **[viz_scale.md](viz_scale.md)** | **The scale figure** — `N` as one horizontal line on the existing growth curve, ~29 decades above the deepest measured canonical. Carries the enumeration-is-not-a-route negative, the compiler's justification, and the narrative document's N4 overclaim gate in a single image. Every constant already published; no computation, no ladder read, no VM. | PLAN ROW |
| **[viz_narrative.md](viz_narrative.md)** | **The narrative document's two figures** — §1 the object, §§4–5 the f·g mechanism. Filed as plan rows *before* drafting, because a narrative document with no planned figures does not end up with none, it ends up with improvised ones. | PLAN ROWS |

Both pages are **specifications, not renderings**. They exist so that the caption and the job of each
figure are fixed before anyone draws it — which for the scale figure is the whole risk, since it puts
a budgeted slice and a compiled superspace on one axis and a careless caption would invite exactly the
conflation it was drawn to prevent.

## The V-family — compiled-superspace figures (`viz_kc_*.md`)

A separate family with a **different data source and a different scope**. The pages above visualize
an *enumerated slice* (the 560T canonical, budget-limited, from `solutions.bin`); the five pages
below visualize the **whole compiled walk superspace** — every member of C1 ∩ C2 ∩ C4 ∩ C5, i.e.
the space [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) sizes, taken *before* C3 is applied — via the
f/g/t counting ladders and the `--kc-scan` atlas. Nothing is sampled and nothing is projected: every
plotted value is an exact integer ratio. Its exact cardinality `N` is whatever `solve --kc-count`
reports once Stage F lands; no figure quotes a number ahead of the command that produces it.

**Scope warning that applies to all five: the compiled space is C1 ∩ C2 ∩ C4 ∩ C5 — C3 is NOT
applied.** Every caption must carry the space label `C1C2C4C5-SUPERSPACE`. Specified by TR-12 §2
(V1–V5).

| Page | Figure | What it answers |
|---|---|---|
| **[viz_kc_field.md](viz_kc_field.md)** | V1, positional-marginal field | 32×31 heat matrix: the exact fraction of the superspace placing each pair in each slot, King Wen overlaid |
| **[viz_kc_river.md](viz_kc_river.md)** | V2, mass river | how the superspace's mass redistributes across the 31 placements, by transition distance class, plus exact per-branch mass and exhaustion cost |
| **[viz_kc_spectrum.md](viz_kc_spectrum.md)** | V3, rank spectrum | whether the citable rank index is a structural coordinate at all |
| **[viz_kc_shells.md](viz_kc_shells.md)** | V4, King Wen's neighbourhood shells | how the space collapses onto one ordering, and where King Wen's improbability is spent |
| **[viz_kc_grammar.md](viz_kc_grammar.md)** | V5, transition grammar | the exact conditional law of the next move at every layer |

**Status: none of the five can be rendered at full-31 yet** — the full-31 f and g ladders (Stage F /
Stage G) have not been built. The *pipeline* is complete and exercised end to end at n=9: atlas →
`solve.py --atlas-queries` → TSV → `viz/report_figures.py` → figure. Each page carries its own Status table naming exactly which instruments exist,
which are PENDING and under what flag name, and every page's pipeline is rehearsable today at n=9 in
under a second. The standing rule for this family is **TSV-to-figure only**: the evidence TSV is
committed alongside the figure and the plotting step performs no analysis.

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
- **`report_figures.py`** — the technical-report figures, including the **V-family**
  (`fig_tr12_kc_field` / `_river` / `_spectrum` / `_shells` / `_grammar`). These read the evidence
  TSVs and nothing else; the tables themselves are written by the atlas consumer,
  `python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR` (documented in
  [`../documentation/SOLVE_PY_CLI.md`](../documentation/SOLVE_PY_CLI.md), gated at n=9 by
  `--atlas-selftest` → `ATLAS_CONSUMER=PASS`). Run it as
  `cd reports/figures/ && python3 ../../viz/report_figures.py <tr12-artifact-root>`; each V figure
  is skipped with a message when its TSV is absent.

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
