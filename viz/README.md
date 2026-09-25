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

### Accepted 2026-09-04 (Q-308 — all three zero-dollar)

| Page | What it covers | Status |
|---|---|---|
| **[viz_scale.md](viz_scale.md)** | **The scale figure** — `N` as one horizontal line on the existing growth curve, ~29 decades above the deepest measured canonical. Carries the enumeration-is-not-a-route negative, the compiler's justification, and the narrative document's N4 overclaim gate in a single image. Every constant already published; no computation, no ladder read, no VM. | **DRAWN 2026-09-23; embedded 2026-09-24** in [TR-12](../reports/TR12_QUERY_PROGRAM.md) §"What this document is, and what it is not" (its one embedding) |
| **[viz_narrative.md](viz_narrative.md)** | **The narrative document's two figures** — §1 the object, §§4–5 the f·g mechanism. Filed as plan rows *before* drafting, because a narrative document with no planned figures does not end up with none, it ends up with improvised ones. | **DRAWN, HELD** — see below |

⚠ *(corrected 2026-09-23: this section was headed "Planned, not yet drawn" and both rows read PLAN
ROW / PLAN ROWS. All three figures have since been drawn, so the heading described the tree as it
stood on 2026-09-04, not as it stands now.)*

**Why the two narrative figures are drawn but HELD.** They illustrate §1 and §§4–5 of the narrative
document, and that document has **no public counterpart** — it lives only in `petersm3/roae-private`,
which a reader of this repository cannot fetch. Landing the figures here would publish two images
whose referent is unobtainable, which is the orphan-figure failure this index exists to prevent. They
land when the document they serve does, and not before. The scale figure has no such dependency: its
referent is the growth curve and TR-11's `N`, both public.

These pages are **specifications first**. They exist so that the caption and the job of each figure
are fixed before anyone draws it — which for the scale figure is the whole risk, since it puts a
budgeted slice and a compiled superspace on one axis and a careless caption would invite exactly the
conflation it was drawn to prevent.

## The V-family — compiled-superspace figures (`viz_kc_*.md`)

A separate family with a **different data source and a different scope**. The pages above visualize
an *enumerated slice* (the 560T canonical, budget-limited, from `solutions.bin`); the five pages
below visualize the **whole compiled walk superspace** — every member of C1 ∩ C2 ∩ C4 ∩ C5, i.e.
the space [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) sizes, taken *before* C3 is applied — via the
f/g/t counting ladders and the `--kc-scan` atlas. Nothing is sampled and nothing is projected: every
plotted value is an exact integer ratio. Its exact cardinality `N` is whatever `solve --kc-count`
reports; no figure quotes a number ahead of the command that produces it.

**Status at 2026-09-23 — three of the five are rendered, and the other two are blocked on data, not
on code.** The n=31 ladders were built in September and the atlas was scanned from them, so V1, V2
and V5 now exist at `../reports/figures/fig_tr12_kc_{field,river,grammar}.{png,svg}`, generated from
the published atlas (`../runs/20260906_kc_ladders_n31/atlas_n31.json`, sha256 `9d6ba3d2…`) by
`solve.py --atlas-queries … --atlas-select v1,v2,v5` and then `report_figures.py`. ⚠ **V2 is still the REDUCED variant** (`TR12_V2=PASS:REDUCED-NO-BRANCH-CLASS-RIVER`): its river is
split by distance class, not by top-level branch class, because the compiled DP state carries no tag
for which branch a prefix descended from. 🔴 **V5 is NO LONGER reduced as of 2026-09-23.** It read
`TR12_V5=PASS:REDUCED-NO-CROSSTAB` and now reads `TR12_V5=PASS`: the second axis was pinned to
`w = popcount(entry XOR exit) ∈ {2,4,6}` and the `(d,w)` cross-tab is derived **consumer-side from
`layers[k].kernel`, which already ships in the published atlas** — no re-scan, no ladder, no VM. The
table went from 155 rows to 465. ⚠ `w` is CONSTANT on each of the seven pair-orbits and takes only
three distinct values across them, so a row is **3 orbit-classes, never an individual pair**.
What V5 adds over V2 is the per-layer `P(w|k)` marginal, not a measured d–w dependence: on layers
1–30 the joint is within 0.0097 of the product of its marginals (`V5_FACTORISATION_MAX_DEV_K_GE_1`,
`solve.py --atlas-probe`), and the all-layer 0.173 is the C4-forced layer 0 ([viz_kc_grammar.md](viz_kc_grammar.md)).
🔴 **V4 IS RENDERED as of 2026-09-23, and the reason it was missing was not the one this file
used to give.** This paragraph read *"V3 and V4 are NOT rendered and cannot be from the atlas
alone"*, attributing both to a read of the cold 15.05 TB f/g ladders. **That was wrong for V4.**
Its input `<artifact-root>/q3_profile_kw.tsv` was produced by the full-31 run of 2026-09-22 **while
the ladders were mounted on NVMe** — the receipt records `TR12_V4_TSV=PASS` — and the figure failed
to appear for one reason only: `TR12_VIZ=SKIP:matplotlib-absent`, i.e. matplotlib and numpy were not
installed on the query host, which has since been torn down. The TSV was banked, so the figure
renders anywhere those two packages exist, with **no ladder and no VM**. It costs seconds.
🔴 **V3 IS RENDERED TOO, as of 2026-09-23 — all five now exist.** This paragraph read "V3 remains
unrendered, and its blocker is an emitter, not the ladders", which was the *second* wrong blocker
named for this figure in one day. The rank grid was already produced (`v3_rel_grid.tsv`, 1000 grid
points, 31.4 min measured) and the observable battery already existed; the "missing emitter" was a
join between two things that both shipped. It now exists as `solve.py --v3-spectrum GRID OUT`, and
`fig_tr12_kc_spectrum.{png,svg}` renders from its output with **no ladder, no VM and no new figure
code**. ⚠ The proposed convenience flag `--kc-unrank-grid` still does NOT exist and was never the
blocker. ⚠ `TR12_V3_FIG=PENDING:viz-v3-spectrum` **stays pinned** and is not hand-edited:
~~`scripts/tr12_repro.sh` already emits `TR12_V3_FIG=PASS` when the figure is present, so the token
flips on the next full-31 run, by measurement rather than by assertion.~~ *Corrected 2026-09-24: it
will not flip on its own.* The battery records `PASS` only when its own render step draws the
figure, which needs `<consumer>/spectrum/v3_spectrum.tsv` — and no row of `scripts/tr12_repro.sh`
runs `solve.py --v3-spectrum` to write it (row `a1_v3` stops at the grid). The token clears by
measurement once a battery row runs the join. The n=31 receipt
(`reports/evidence/tr12/`) keeps `PENDING` because that is what was true when that run executed.

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

~~**Status: none of the five can be rendered at full-31 yet** — the full-31 f and g ladders (Stage F /
Stage G) have not been built.~~ *Superseded (noted 2026-09-24): all five are rendered at full-31 from
committed TSVs, as the section above records.* The *pipeline* is complete and exercised end to end at n=9: atlas →
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

  **A TSV that is present but INCOMPLETE is refused, not drawn** (Q-307). Until 2026-09-04 the
  reader did no shape check, so a truncated `v1_field.tsv` rendered a perfectly plausible heat map
  over a smaller grid — no error, no clue, and an output that looks like evidence. Each V figure now
  asserts that its tidy table is a complete, duplicate-free, contiguous grid over the index columns
  its own spec page names (`k`×`pair`, `k`×class, `step`, `branch`, `i`), that every data row has the
  header's field count, and that the spec's required columns are present; a violation prints
  `FIGURE_SHAPE=FAIL` naming the file, the line and the reason, and writes no figure. The shape is
  derived from the table's OWN observed ranges, so nothing here knows what full-31 looks like and
  the check works unchanged at every rung. V3 additionally drops constant observable columns and
  names them, per [`viz_kc_spectrum.md`](viz_kc_spectrum.md) rule 1 — a flat `linechanges` panel is
  a statement about the observable, never about the rank index.

  **Every TR-12 figure carries a provenance footer** — `source: <tsv>@<sha256[:12]>` in the margin —
  so a rendered PNG can be tied back to the exact table it came from. It is deliberately
  timestamp-free: same bytes in, same figure out. The four non-TR-12 figures are unstamped and remain
  byte-identical to the committed PNGs.

  Both are gated: `bash scripts/doc_gates.sh viz-shape` runs `python3 viz/report_figures.py
  --selftest` (14 arms: eight synthetic malformed tables, four provenance arms, two constant-column
  arms) and requires `VIZ_SHAPE_SELFTEST=PASS`.

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
instant; the bottleneck is reading `solutions.bin` from disk. The input must be **uncompressed**: run `gzip -dk solutions.bin.gz` first, since a `.gz` is refused with a `ValueError` that says so. ⚠ *Corrected 2026-09-25 (Q-699, V3A-139#4): this said "(gz-aware)", but `visualize.py` has no gzip path. A `.gz` input, and every headerless legacy file, used to crash with `NameError`.* Outputs are 4 PNG + 4 SVG
(~10-15 MB total) plus the growth curve. Per-run directories may carry their own brief, dataset-specific
`README.md`; this file is the stable index across all runs.
