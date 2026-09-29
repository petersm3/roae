# Figure — TR-4, the boundary-information curve S(k) (`fig_tr4_boundary_information`)

← [Visual capstone](README.md#the-space-and-its-scale) · Report: [TR-4 §Figure](../reports/TR4_SIZE_OF_THE_SPACE.md#figure)

[![Log-scale decay curve of S(k), the fraction of the full C1–C5 population agreeing with King Wen on its first k identifying boundaries: four estimated points, a dashed illustrative early-rate line, an illustrative bracket, and horizontal lines for the reachable floor.](../reports/figures/fig_tr4_boundary_information.png)](../reports/figures/fig_tr4_boundary_information.svg)

*The figure as committed. Click the image for the SVG. The authoritative caption, with its dated correction markers, is in [TR-4 §Figure](../reports/TR4_SIZE_OF_THE_SPACE.md#figure).*

## In plain terms

This curve shows how quickly the share of valid orderings falls when an ordering must match King Wen
at more and more chosen joins between pairs. The four red points are estimates, each within about ten
percent, and each of these first joins cuts the share by roughly a thousand times. The dashed line and
the shaded bracket are illustrations, not measurements, and the vertical line is a marker of scale,
not a limit. Even with every join matched, many orderings still remain, because matching joins fixes
which pairs go where but not which way round each pair is placed.

## What it shows

The vertical axis is S(k), on a log scale: the fraction of the full C1–C5 population that agrees with
King Wen on its first k boundaries, taken in the greedy identifying order {4, 27, 25, 21, 1} of the
560T slice. The horizontal axis is k.

- **Red points:** the four estimated values (pinned Knuth estimates, relative error at most 10%),
  each annotated with its surviving-orderings count.
- **Blue dashed segment:** the rate inferred from k = 1–4 alone, roughly ×10³ per boundary, drawn to
  k = 8 and labelled as superseded by the later measured decline. It is not a measurement.
- **Orange band:** an illustrative bracket for the weakest remaining boundaries (×15–17 per boundary
  at k = 5–8), not reproducible from published material.
- **Green dash-dot line:** the reachable floor, S = 1.29×10⁻³², one surviving pair-ordering class.
- **Grey dotted line:** S = 7.53×10⁻³⁹, one oriented ordering, 20.71 bits below the floor; no k
  reaches it.
- **Green vertical line at k = 14:** the earliest k at which the floor is reached if no later
  boundary gains more than the eighth measured one's 6.14 bits. A scale marker under that assumption,
  not a bound.

## What it establishes, and what it does not

- **Establishes.** Agreement with King Wen at a few boundaries is already very rare: the first four
  still admit about 8.4×10²⁵ full-space orderings, and S falls by roughly ×10³ per boundary over
  k = 1–4 ([TR-4 §Figure](../reports/TR4_SIZE_OF_THE_SPACE.md#figure), §5).
- **Does not establish.** How many boundaries identify King Wen in the full space. The data set no
  far end: under a continued decline the k = 14 marker moves to k ≈ 28 or beyond the 31 pinnable
  boundaries. The boundary pins fix pair identity only, so with all 31 fixed, **1,720,320** orderings
  remain (King Wen's orientation fibre, TR-1 §7); the curve can reach one pair-ordering class, never
  one ordering. A shaded "extrapolated range" at k = 15–20 that this figure used to carry is
  withdrawn (Q-827), because no continuation rule reproduces it.

## Provenance

- **Data.** No table. The four S(k) values, the full-space size 1.3287×10³⁸ (TR-4 §3), the bracket
  and the 6.14-bit gain are TR-4's published numbers, typed into the generator with source comments.
- **Generator.** `fig_tr4_boundary_information()` in [`viz/report_figures.py`](report_figures.py).
  Its comment block records each retired label and why it was retired, paraphrased so that the
  retracted-phrase gate (GATE 6) does not match narration.
- **Regenerate.** The whole set:

  ```bash
  cd reports/figures && python3 ../../viz/report_figures.py
  ```

  or this figure alone:

  ```bash
  cd reports/figures && python3 -c "import sys; sys.path.insert(0, '../../viz'); import report_figures as r; r.fig_tr4_boundary_information()"
  ```

- **Toolchain.** matplotlib 3.11.0 and numpy 2.4.4. Under that pin the documented command reproduced
  the committed PNG byte for byte on 2026-09-29, with all twelve report figures (CX-233). See
  [Reproduce the figures](README.md#reproduce-the-figures).
- **Checks.** The orientation fibre is recomputed by `python3 verify.py --recount-fiber`; TR-4's
  [Verification Guide](../reports/TR4_SIZE_OF_THE_SPACE.md#verification-guide) gives the rest.

## Review history

This figure has been corrected more often than any other. From 2026-09-19 on, each step is marked in
place in TR-4's caption and has a ledger entry in [CORRECTIONS.md](../documentation/CORRECTIONS.md). The
two earlier removals are recorded in the generator's comment block (its notes dated 2026-08-01 and
2026-08-06) and, for the wording they removed, in TR-4's revision rows v1.15–v1.16.

- **2026-08-01 and 2026-08-06.** A withdrawn "floor" label and a withdrawn four-boundary
  identification claim were found still drawn in the image, as glyph paths no text gate could read;
  both were removed from the generator.
- **2026-09-19 (Q-643, Q-658).** The figure labelled 1/N as the point where one ordering survives.
  Boundary pins cannot reach it; the reachable floor is now drawn at 1.29×10⁻³² and 7.53×10⁻³⁹ is
  marked separately. CX-53, CX-55.
- **2026-09-26 (Q-827, Q-842).** The k = 15–20 band was withdrawn and replaced by the k = 14 marker.
  The unmodified generator first reproduced the committed PNG byte for byte, so the change is the
  edit, not renderer drift. CX-178.
- **2026-09-26, Codex figure review VIZ1, checked by Fable (F17).** The dashed line ran to k = 20 at a
  rate that contradicted the k = 14 marker's premise; it now stops at k = 8. CX-191, CX-192.
- **2026-09-28, Codex visualization review, triaged by Fable (Q-889, Q-863).** The `10^n` tick
  exponents rendered at 8.93 px, below the 12-px floor, which the floor check missed; the legend sat
  on the dotted line; the points were called "measured". Redrawn with full-size ticks, the legend
  below the axes, and the points labelled as estimates. No S(k) value, gain, floor or marker moved.
  CX-225.
- **2026-09-29.** This page added, as part of the visual capstone (CX-233).

---

*Part of the [visual capstone](README.md), the companion to
[TR-12](../reports/TR12_QUERY_PROGRAM.md). A log-scale plot of TR-4's published estimates; nothing is
claimed novel. Developed with AI assistance (Claude, Anthropic); corrections invited.*
