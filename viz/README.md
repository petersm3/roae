# Visualization — the report figures, centred on the TR-12 capstone

This directory is the figure layer of the technical-report suite. Its centre is the
[TR-12](../reports/TR12_QUERY_PROGRAM.md) capstone: five figures of the compiled superspace (V1–V5)
and the scale figure, drawn by one generator, `report_figures.py` — V1–V5 from committed tables, the scale figure from the cited constants. The
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
| [`fig_tr12_kc_shells`](../reports/figures/fig_tr12_kc_shells.svg) — V4 | King Wen's neighbourhood shells: how the space collapses onto one ordering along King Wen's walk; the line is one walk, not a population, and the shaded bars are the attested range over the admissible alternatives | `tr12/q3_profile_kw.tsv@bbe62f3bc6a3`, and for the attested alternatives band `reports/evidence/tr12/banked_n31_20260922/q3_profile_exact.tsv@ee0b99fde78a` | [viz_kc_shells.md](viz_kc_shells.md) |
| [`fig_tr12_kc_spectrum`](../reports/figures/fig_tr12_kc_spectrum.svg) — V3 | the rank spectrum: whether the REL rank index (not the citable O3 order) orders the space by any of the plotted observables (seven panels), on a 1,000-point lattice | `tr12/v3_spectrum.tsv@22ac482fe8f2` | [viz_kc_spectrum.md](viz_kc_spectrum.md) |
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
python3 -m pip install "numpy==2.4.4" "matplotlib==3.11.0"   # external; not dependencies of roae.py / solve.c
cd reports/figures && python3 ../../viz/report_figures.py
```

The artifact root defaults to the repository's own `tr12/`, resolved from the generator's location,
not from the working directory; pass another root as the first argument. Figures are written to the
working directory, so run from `reports/figures/` to overwrite the committed files in place and
`git diff --stat` to compare. A V figure whose table is absent is skipped with a message.

- **PNG byte-identity requires matplotlib 3.11.0.** Measured 2026-09-27 with matplotlib 3.11.0 and
  numpy 2.4.4: all ten generated PNGs came back byte-identical to the committed ones (twelve of twelve once TR-5 and TR-7 had renderers, Q-858). The same run
  under matplotlib 3.6.3 matched none of the ten (CX-192 in
  [CORRECTIONS.md](../documentation/CORRECTIONS.md)). The committed SVGs record the version in their
  metadata (`Matplotlib v3.11.0`); two renders of the same SVG differ only in `<dc:date>` and element
  ids, so compare SVGs line-wise, never byte-wise.
- **The twelve generated figures** are the six above plus `fig_tr1_rules_tradeoff`,
  `fig_tr3_campaign_timeline`, `fig_tr4_boundary_information`, `fig_tr5_orbit_collapse`,
  `fig_tr6_parity_alternations` and `fig_tr7_circular_cycle` (TR-5's and TR-7's are computed from the
  King Wen sequence in `solve.py` and read no table). The two held narrative figures specified in
  [archive/viz_narrative.md](archive/viz_narrative.md) are not committed; any such file a run leaves
  in the output directory is not part of the comparison.
- **Text floor.** `save()` measures the SVG it is about to write and refuses to write either file if
  any glyph would render below 12 px when the figure's full width is shown at 900 px, the width of a
  rendered Markdown column. That means every placed glyph, nested mathtext included: a superscript's own scale is composed with its text group's, so a `10^n` tick label's 0.7-scaled exponent is measured at its real size (Q-889, 2026-09-28; until then only the outer scale was read, and TR-4 and the scale figure shipped 46 exponent glyphs at 8.8–8.9 px). **Contrast.** Text a renderer sets on a known background is asserted at 4.5:1 or better (WCAG 2) before anything is drawn, and King Wen's outline on V1 and V5 is two-tone — a light core over a black under-stroke — so on any cell one of the two contrasts by at least 3:1 (Q-899/Q-900, 2026-09-28; V2's band labels were set in their band colour at 2.2–2.4:1 on white, TR-6's white O on orange at 2.16:1).
- **Provenance footer.** Every TR-12 figure carries `source: <table>@<sha256[:12]>` in its bottom
  margin, one entry per input, ending `(viz/report_figures.py)`. It has no timestamp, so the same
  table gives the same PNG under the recorded environment (matplotlib 3.11.0, numpy 2.4.4, DejaVu Sans; Q-901) — table identity alone does not fix the pixels. To check a figure against a table, compare the footer with the first 12
  hex of `sha256sum` of that table; a missing input prints as `<name>@ABSENT`. The digest is of the bytes the figure parsed: each table is read once and the parse and the digest come from that one read (Q-890, 2026-09-28). The scale figure's budgets, record counts, sha prefixes and N are the committed table `viz/viz_scale_inputs.tsv`, each row asserted against `documentation/CANONICAL_HASHES.md` (N against `reports/METHODS.md`) at render time, and its footer carries that table's digest.
- **Shape guards.** A table that is present but incomplete is refused, not drawn: each V figure
  checks that its table is a complete, duplicate-free, contiguous grid over the index columns its
  spec names, with the header's field count on every row (a blank or whitespace-only row is refused) and every column its spec lists present, and that the grid is the spec's own inventory rather than whatever the rows happen to span (Q-892, 2026-09-28): layers `k = 0…n−1`, all 32 pair rows, classes `d ∈ {1,2,3,4,6}` (× `w ∈ {2,4,6}` for V5), V4 steps `1…n` ending at `g = 1`, V3 rows `i = 0…K−1` with `rank = i·⌊N/K⌋` and `x = rank/N`. `n` comes from the Q3 table's sidecar or step count when `tr12_figures` runs; a figure rendered on its own without `n` still requires the lowest layer, and only the highest one then rests on the footer digest. A
  violation prints `FIGURE_SHAPE=FAIL` with the file, the line and the reason, and writes no figure.
  V3 also drops constant observable columns (constancy decided on the parsed numbers) and names them; a V3 table that is present and refused fails the run, and only an absent one is skipped (Q-893). V4 names a receipt it was given and could not find as `q3_profile_exact.tsv@ABSENT` in its footer, and uses King Wen's name in its titles only for a table that is King Wen's walk (Q-891). V2 at `n = 31` requires its branch table, whose `prefixes_t_units` must be all integers (drawn) or all `PENDING_T_LADDER(...)` (stated on the panel as unavailable); anything else is refused (Q-894). `bash scripts/doc_gates.sh viz-shape`
  runs `python3 viz/report_figures.py --selftest` and requires `VIZ_SHAPE_SELFTEST=PASS`.

## How the tables are produced

The V1–V5 renderers are **TSV-to-figure**: they read the committed tables and perform no analysis. The other figures draw from cited report constants (TR-1, TR-3, TR-4; the scale figure fits its three-point power law from CANONICAL_HASHES.md constants) or from the King Wen sequence itself (TR-5, TR-6, TR-7).
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
| [`fig_tr12_kc_shells`](../reports/figures/fig_tr12_kc_shells.svg) | V4, King Wen's neighbourhood shells; the line is one walk, not a population, with the attested alternatives band (C1C2C4C5-SUPERSPACE) | [TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5), [viz_kc_shells.md](viz_kc_shells.md) |
| [`fig_tr12_kc_grammar`](../reports/figures/fig_tr12_kc_grammar.svg) | V5, transition grammar (C1C2C4C5-SUPERSPACE) | [TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5), [viz_kc_grammar.md](viz_kc_grammar.md) |
| [`viz_scale`](../reports/figures/viz_scale.svg) | The scale figure: budgeted slices and the compiled superspace, which count different spaces | [TR-12 §"What this document is, and what it is not"](../reports/TR12_QUERY_PROGRAM.md#what-this-document-is-and-what-it-is-not), [viz_scale.md](viz_scale.md) |
| [`fig_tr1_rules_tradeoff`](../reports/figures/fig_tr1_rules_tradeoff.svg) | The conflict theorem's trade-off | [TR-1 §Figure](../reports/TR1_EIGHT_CENTURIES_MEASURED.md#figure), [TR-2 §Figure](../reports/TR2_THE_RULES_CONFLICT.md#figure) |
| [`fig_tr3_campaign_timeline`](../reports/figures/fig_tr3_campaign_timeline.svg) | The first 560T campaign timeline | [TR-3 §Figure](../reports/TR3_REPRODUCIBLE_ENUMERATION.md#figure) |
| [`fig_tr4_boundary_information`](../reports/figures/fig_tr4_boundary_information.svg) | The boundary-information curve S(k) | [TR-4 §Figure](../reports/TR4_SIZE_OF_THE_SPACE.md#figure) |
| [`fig_tr5_orbit_collapse`](../reports/figures/fig_tr5_orbit_collapse.svg) | The symmetry collapse and King Wen's 24-record orbit, computed from the sequence | [TR-5 §Figure: the symmetry collapse](../reports/TR5_SYMMETRY.md#figure-the-symmetry-collapse) |
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
draws the records-vs-budget growth curve from the published canonical record counts, which it reads
from `viz_scale_inputs.tsv`, each row asserted against CANONICAL_HASHES.md, and labels from those rows (Q-898, 2026-09-28; it held them as constants). Their images are archived per run under `runs/<run-id>/viz/`, never inlined into
`viz/` itself, and the pages that describe them are in [archive/](archive/README.md).

```bash
cd runs/<run-id>/viz/
python3 ../../../viz/visualize.py /path/to/solutions.bin    # the 4 PCA plots
python3 ../../../viz/growth_curve.py                        # the growth curve
```

`visualize.py` needs an **uncompressed** `solutions.bin` (none is committed): run `gzip -dk
solutions.bin.gz` first, since a `.gz` input is refused with a `ValueError` that says so. So are a format-v1 header of another version or with a nonzero reserved byte, a record with reserved bit 0 set, a pair index of 32 or more or a repeated pair, and a legacy headerless file of more than `MAX_RECORDS` records; from the command line each prints `ERROR:` and exits 1 (Q-898). PCA on the
32×32 covariance is nearly instant; the bottleneck is reading the file from disk. `--telemetry` reads an optional `telemetry_meta.txt` beside the CSV (`vm=`, `disk=`, `cpu=`, and since Q-898 `cores=` and `cpu_base_mhz=` for the CPU-frequency note); a `VIZ_COMPLETE_HR` completion time is labelled as operator-supplied and recorded in `index.html`.
