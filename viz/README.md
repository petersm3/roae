# Visualization — the report figures, centred on the TR-12 capstone

This directory is the figure layer of the technical-report suite. Its centre is the
[TR-12](../reports/TR12_QUERY_PROGRAM.md) capstone: five figures of the compiled superspace (V1–V5)
and the scale figure, each drawn from a committed table by one generator, `report_figures.py`. The
per-run figures of the enumerated slices (PCA projections, growth curve, campaign telemetry) are
historical; they are indexed at the end of this page and their pages are in [archive/](archive/README.md).

## The TR-12 figures

**The space.** V1–V5 draw on the compiled walk superspace, **SUPERSPACE** = C1 ∧ C2 ∧ C4 ∧ C5: every
constraint except C3, i.e. the space [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) sizes, taken *before*
C3 is applied. Its exact cardinality `N` is whatever `solve --kc-count` reports. Every caption carries
the label `C1C2C4C5-SUPERSPACE; C3 not imposed`. The five figures do not all plot the same kind of
quantity: V1, V2 and V5 plot population quantities over C1C2C4C5-SUPERSPACE. V4 follows King Wen's
single oriented walk; V3 evaluates a systematic 1,000-point REL lattice.

| Figure | What it shows | Committed input (footer `name@sha256[:12]`) | Spec |
|---|---|---|---|
| [`fig_tr12_kc_field`](../reports/figures/fig_tr12_kc_field.svg) — V1 | 32×31 heat matrix: the exact fraction of the superspace placing each pair in each slot, King Wen overlaid | `tr12/scan/v1_field.tsv@67514134add5` | [viz_kc_field.md](viz_kc_field.md) |
| [`fig_tr12_kc_river`](../reports/figures/fig_tr12_kc_river.svg) — V2 | how the superspace's mass redistributes across the 31 placements by transition distance class, with the exact per-branch panel; the REDUCED form (split by distance class, not by top-level branch class) | `tr12/scan/v2_river.tsv@380111eb002e`, `tr12/scan/v2_branches.tsv@3d75e6d619ba` | [viz_kc_river.md](viz_kc_river.md) |
| [`fig_tr12_kc_grammar`](../reports/figures/fig_tr12_kc_grammar.svg) — V5 | the exact conditional law of the next move at every layer, by distance class d and within-pair distance w | `tr12/scan/v5_grammar.tsv@c5e50083ae91` | [viz_kc_grammar.md](viz_kc_grammar.md) |
| [`fig_tr12_kc_shells`](../reports/figures/fig_tr12_kc_shells.svg) — V4 | King Wen's neighbourhood shells: how the space collapses onto one ordering along King Wen's walk; one walk, not a population | `tr12/q3_profile_kw.tsv@bbe62f3bc6a3` | [viz_kc_shells.md](viz_kc_shells.md) |
| [`fig_tr12_kc_spectrum`](../reports/figures/fig_tr12_kc_spectrum.svg) — V3 | the rank spectrum: whether the citable rank index orders the space by any of the plotted observables (seven panels), on a 1,000-point lattice | `tr12/v3_spectrum.tsv@22ac482fe8f2` | [viz_kc_spectrum.md](viz_kc_spectrum.md) |
| [`viz_scale`](../reports/figures/viz_scale.svg) | budgeted slices and the compiled superspace on one axis; the two series count different spaces | constants from [CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) and TR-11 (no table) | [viz_scale.md](viz_scale.md) |

The five V figures are embedded in [TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5),
which carries their full captions and is the authority; the scale figure is embedded in
[TR-12 §"What this document is, and what it is not"](../reports/TR12_QUERY_PROGRAM.md#what-this-document-is-and-what-it-is-not).
All six are also shown, with short captions, in the landing [README §Figures](../README.md#figures).
V3's status token: the standalone n=31 V3 rows passed on 2026-09-25 (`TR12_V3_FIG=PASS`,
[evidence](../reports/evidence/tr12/v3_rows_n31_20260925/README.md)); the archived 2026-09-22 full-run
receipt retains its original `PENDING` token.

Each spec page fixes the figure's job, its caption rules and what it may not claim, and carries its
own drafting record and Status table.

## Reproduce the figures

```bash
pip install numpy "matplotlib==3.11.0"   # external; not dependencies of roae.py / solve.c
cd reports/figures && python3 ../../viz/report_figures.py
```

The artifact root defaults to the repository's own `tr12/`, resolved from the generator's location,
not from the working directory; pass another root as the first argument. Figures are written to the
working directory, so run from `reports/figures/` to overwrite the committed files in place and
`git diff --stat` to compare. A V figure whose table is absent is skipped with a message.

- **PNG byte-identity requires matplotlib 3.11.0.** Measured 2026-09-27 with matplotlib 3.11.0 and
  numpy 2.4.4: all ten generated PNGs came back byte-identical to the committed ones. The same run
  under matplotlib 3.6.3 matched none of the ten (CX-192 in
  [CORRECTIONS.md](../documentation/CORRECTIONS.md)). The committed SVGs record the version in their
  metadata (`Matplotlib v3.11.0`); two renders of the same SVG differ only in `<dc:date>` and element
  ids, so compare SVGs line-wise, never byte-wise.
- **The ten generated figures** are the six above plus `fig_tr1_rules_tradeoff`,
  `fig_tr3_campaign_timeline`, `fig_tr4_boundary_information` and `fig_tr6_parity_alternations`.
  `fig_tr5_orbit_collapse` and `fig_tr7_circular_cycle` have **no renderer**: they are legacy artwork
  with no committed regeneration command. The two held narrative figures specified in
  [archive/viz_narrative.md](archive/viz_narrative.md) are not committed; any such file a run leaves
  in the output directory is not part of the comparison.
- **Text floor.** `save()` measures the SVG it is about to write and refuses to write either file if
  any glyph would render below 12 px when the figure's full width is shown at 900 px, the width of a
  rendered Markdown column.
- **Provenance footer.** Every TR-12 figure carries `source: <table>@<sha256[:12]>` in its bottom
  margin, one entry per input, ending `(viz/report_figures.py)`. It has no timestamp, so the same
  table gives the same PNG. To check a figure against a table, compare the footer with the first 12
  hex of `sha256sum` of that table; a missing input prints as `<name>@ABSENT`.
- **Shape guards.** A table that is present but incomplete is refused, not drawn: each V figure
  checks that its table is a complete, duplicate-free, contiguous grid over the index columns its
  spec names, with the header's field count on every row and the spec's required columns present. A
  violation prints `FIGURE_SHAPE=FAIL` with the file, the line and the reason, and writes no figure.
  V3 also drops constant observable columns and names them. `bash scripts/doc_gates.sh viz-shape`
  runs `python3 viz/report_figures.py --selftest` and requires `VIZ_SHAPE_SELFTEST=PASS`.

## How the tables are produced

The generator is **TSV-to-figure only**: it reads the committed tables and performs no analysis.
V1, V2 and V5's tables are written by the atlas consumer, `python3 solve.py --atlas-queries ATLAS.json
--atlas-out DIR` (from the published n=31 atlas, `runs/20260906_kc_ladders_n31/`); V4's needs
`--atlas-q3-trace TRACE` on the same call; V3's is the separate join `solve.py --v3-spectrum GRID OUT`.
Both are documented in [SOLVE_PY_CLI.md](../documentation/SOLVE_PY_CLI.md); the atlas consumer is
gated at n=9 by `--atlas-selftest` → `ATLAS_CONSUMER=PASS`.

## Every committed figure, and where it is shown

This table lists every committed figure image and the pages that show or link it, so that none is
orphaned. Captions live on the linked pages; this is an index. The landing
[README](../README.md#figures) shows the report figures in its §Figures.

| Figure (PNG + SVG unless noted) | What it is | Shown in |
|---|---|---|
| [`fig_tr12_kc_field`](../reports/figures/fig_tr12_kc_field.svg) | V1, positional-marginal field (C1C2C4C5-SUPERSPACE) | [TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5), [viz_kc_field.md](viz_kc_field.md) |
| [`fig_tr12_kc_river`](../reports/figures/fig_tr12_kc_river.svg) | V2, mass river and branch panel; the REDUCED form (C1C2C4C5-SUPERSPACE) | [TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5), [viz_kc_river.md](viz_kc_river.md) |
| [`fig_tr12_kc_spectrum`](../reports/figures/fig_tr12_kc_spectrum.svg) | V3, rank spectrum; the standalone n=31 V3 rows passed on 2026-09-25 (`TR12_V3_FIG=PASS`), and the archived 2026-09-22 full-run receipt retains its original PENDING token (C1C2C4C5-SUPERSPACE) | [TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5), [viz_kc_spectrum.md](viz_kc_spectrum.md) |
| [`fig_tr12_kc_shells`](../reports/figures/fig_tr12_kc_shells.svg) | V4, King Wen's neighbourhood shells; one walk, not a population (C1C2C4C5-SUPERSPACE) | [TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5), [viz_kc_shells.md](viz_kc_shells.md) |
| [`fig_tr12_kc_grammar`](../reports/figures/fig_tr12_kc_grammar.svg) | V5, transition grammar (C1C2C4C5-SUPERSPACE) | [TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5), [viz_kc_grammar.md](viz_kc_grammar.md) |
| [`viz_scale`](../reports/figures/viz_scale.svg) | The scale figure: budgeted slices and the compiled superspace, which count different spaces | [TR-12 §"What this document is, and what it is not"](../reports/TR12_QUERY_PROGRAM.md#what-this-document-is-and-what-it-is-not), [viz_scale.md](viz_scale.md) |
| [`fig_tr1_rules_tradeoff`](../reports/figures/fig_tr1_rules_tradeoff.svg) | The conflict theorem's trade-off | [TR-1 §Figure](../reports/TR1_EIGHT_CENTURIES_MEASURED.md#figure), [TR-2 §Figure](../reports/TR2_THE_RULES_CONFLICT.md#figure) |
| [`fig_tr3_campaign_timeline`](../reports/figures/fig_tr3_campaign_timeline.svg) | The first 560T campaign timeline | [TR-3 §Figure](../reports/TR3_REPRODUCIBLE_ENUMERATION.md#figure) |
| [`fig_tr4_boundary_information`](../reports/figures/fig_tr4_boundary_information.svg) | The boundary-information curve S(k) | [TR-4 §Figure](../reports/TR4_SIZE_OF_THE_SPACE.md#figure) |
| [`fig_tr5_orbit_collapse`](../reports/figures/fig_tr5_orbit_collapse.svg) | The symmetry collapse and one 24-element orbit | [TR-5 §Figure: the symmetry collapse](../reports/TR5_SYMMETRY.md#figure-the-symmetry-collapse) |
| [`fig_tr6_parity_alternations`](../reports/figures/fig_tr6_parity_alternations.svg) | King Wen's parity-class string | [TR-6 §Figure](../reports/TR6_PARITY_SKELETON.md#figure) |
| [`fig_tr7_circular_cycle`](../reports/figures/fig_tr7_circular_cycle.svg) | The King Wen cycle with the wrap edge | [TR-7 §Figure: the cycle](../reports/TR7_CIRCULAR_READING.md#figure-the-cycle) |
| [`viz_growth_curve`](../runs/20260608_560T_9a968fa2/viz/viz_growth_curve.svg) | Growth curve across the canonicals | [archive/viz_graphs.md](archive/viz_graphs.md) |
| `viz_edit_distance`, `viz_complement_dist`, `viz_position2_cluster`, `viz_adjacency` in [`../runs/20260608_560T_9a968fa2/viz/`](../runs/20260608_560T_9a968fa2/viz/) | The four PCA projections of the d3 560T canonical | [archive/viz_pca.md](archive/viz_pca.md) |
| `tc_compute`, `tc_io_system`, `per_resume_whiskers`, `eta_projection`, `throughput_vs_cpufreq`, `eviction_recovery` (PNG only) in [`../runs/20260608_560T_9a968fa2/viz/`](../runs/20260608_560T_9a968fa2/viz/index.html) | Telemetry of the 560T re-run | [archive/viz_graphs.md](archive/viz_graphs.md), [`index.html`](../runs/20260608_560T_9a968fa2/viz/index.html) |
| `viz_edit_distance`, `viz_complement_dist`, `viz_position2_cluster`, `viz_adjacency` in [`../runs/20260419_100T_d3_d128westus3/viz/`](../runs/20260419_100T_d3_d128westus3/viz/) | The same four PCA projections, drawn from the d3 100T canonical | not embedded in any page; described, with their sampling method, in [the 100T run README](../runs/20260419_100T_d3_d128westus3/README.md#visualization) |

## Historical material: the enumerated-slice figures

Before the compiled superspace became the project's centre, the figures described the enumerated
slices, chiefly the d3 560T canonical (sha and record count in
[CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) §"d3 560T"). Two tools made them, and
both stay at their paths. **`visualize.py`** draws the four PCA projections of a canonical
`solutions.bin` and, with `--telemetry <csv>`, the campaign time-course panels. **`growth_curve.py`**
draws the records-vs-budget growth curve from the published canonical record counts, which it holds
as constants. Their images are archived per run under `runs/<run-id>/viz/`, never inlined into
`viz/` itself, and the pages that describe them are in [archive/](archive/README.md).

```bash
cd runs/<run-id>/viz/
python3 ../../../viz/visualize.py /path/to/solutions.bin    # the 4 PCA plots
python3 ../../../viz/growth_curve.py                        # the growth curve
```

`visualize.py` needs an **uncompressed** `solutions.bin` (none is committed): run `gzip -dk
solutions.bin.gz` first, since a `.gz` input is refused with a `ValueError` that says so. PCA on the
32×32 covariance is nearly instant; the bottleneck is reading the file from disk.
