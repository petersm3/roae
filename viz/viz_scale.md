# The scale figure (`viz_scale.png/.svg`) — spec and drafting record

← Back to the [capstone's visual showcase](README.md#king-wens-place-in-the-space-tr-12) · Report: [TR-12 §"What this document is, and what it is not"](../reports/TR12_QUERY_PROGRAM.md#what-this-document-is-and-what-it-is-not) · V-family: [V1 field](viz_kc_field.md) · [V2 river](viz_kc_river.md) · [V3 spectrum](viz_kc_spectrum.md) · [V4 shells](viz_kc_shells.md) · [V5 grammar](viz_kc_grammar.md)

[![Log-log plot of count against per-cell node budget: three red points for the 11.2T, 100T and 560T canonical record counts on a power-law fit, and a horizontal line near the top at N, the exact count of the C1C2C4C5 superspace; the points and the line count different spaces.](../reports/figures/viz_scale.png)](../reports/figures/viz_scale.svg)

*The scale figure as committed; the two series count **different spaces**. Click the image for the SVG. Its authoritative caption is in [TR-12 §"What this document is, and what it is not"](../reports/TR12_QUERY_PROGRAM.md#what-this-document-is-and-what-it-is-not); it is also shown on this page since 2026-09-29 (CX-233).*

## In plain terms

This picture puts two different counts on one scale. The three red points are how many orderings three
of the project's large computer searches recorded; each search explored only a budgeted slice of the
possibilities, so each count is a lower bound. The line near the top is the exact size of a larger
space, computed by a counting method rather than by listing, which leaves out one rule (the one called
C3). The two count different spaces in different units, so the gap of about 29 powers of ten is a
distance between the plotted numbers, not a measure of how much the searches missed; what it does show
is that, if the trend of the three searches continues, a bigger search budget is not a way to reach
the whole space.

## What it shows

A log-log plot. The horizontal axis is the per-cell node budget of an enumeration; the vertical axis
is a count. The three red points are the 11.2T, 100T and 560T canonical record counts, each labelled
with its campaign, record count and sha prefix, on a blue three-run power-law fit (α ≈ 0.67). The
purple horizontal line is N, the exact count of the C1C2C4C5 superspace. A vertical arrow marks the
gap from the 560T point to the line. The embedded note has three lines: POINTS, LINE and UNITS. The
axis runs the full 29 decades unbroken, on purpose ([Decided at drafting](#decided-at-drafting--axis-treatment)).

## What it establishes, and what it does not

- **Establishes.** If the power law fitted to these three runs continues, more node budget is not a
  route to the space: the points grow sublinearly in the budget, and the fitted curve would need,
  under that extrapolation, a per-cell budget of roughly 10³⁹ to 10⁴⁵ nodes to reach even the
  like-unit bracket, against 3.5×10⁹ at 560T. That is why TR-12 queries a compiled catalog rather
  than an enumeration ([TR-12 §"What this document is, and what it is not"](../reports/TR12_QUERY_PROGRAM.md#what-this-document-is-and-what-it-is-not)).
- **Does not establish.** How much of the space was found. A record is one canonical pair ordering
  with orientation masked, and N counts orientation-explicit sequences, so between 5.1 and 9.3 of the
  29 decades are a change of unit; in like units the gap is 19.7 to 23.9 decades. N leaves out C3,
  so it does not count C1–C5 either. The negative rests on the three-point extrapolation. The caption
  rules are in [The caption MUST carry BOTH space labels](#-the-caption-must-carry-both-space-labels--this-is-the-failure-mode).

## Provenance

- **Data.** [`viz/viz_scale_inputs.tsv`](viz_scale_inputs.tsv), sha256 prefix `fcd28d197a17`, printed
  in the figure's footer: the budgets, record counts and sha prefixes of the three canonicals, each row
  asserted at render time against
  [CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md), and N, asserted against
  [METHODS.md](../reports/METHODS.md) (TR-11 §9). No new computation.
- **Generator.** `fig_viz_scale()` in [`viz/report_figures.py`](report_figures.py), which reads the
  table through `_scale_inputs()` and asserts `28.5 < decades < 29.5`, so a moved constant fails
  loudly instead of redrawing a smaller gap.
- **Regenerate.** The whole set, `cd reports/figures && python3 ../../viz/report_figures.py`, or
  this figure alone:

  ```bash
  cd reports/figures && python3 -c "import sys; sys.path.insert(0, '../../viz'); import report_figures as r; r.fig_viz_scale()"
  ```

- **Toolchain.** matplotlib 3.11.0 and numpy 2.4.4. Under that pin the documented command reproduced
  the committed PNG byte for byte on 2026-09-29, with all twelve report figures (CX-233); see
  [Reproduce the figures](README.md#reproduce-the-figures).
- **Checks.** Every constant is published, and the unit bracket is one line of Python; see
  [Reader-verifiable without trusting us](#reader-verifiable-without-trusting-us).

## Review history

- **2026-09-04.** Accepted as a plan row (Q-308).
- **2026-09-23 and 2026-09-24.** Drawn, then committed to `reports/figures/` and embedded once, in
  TR-12's scope section. The Codex v3 review (V3A-147), adjudicated by Fable, found that the page
  labelled the two spaces but not the two counting units, and that it called the campaigns
  multi-week and the gap a shortfall; the unit note became mandatory in the caption.
- **2026-09-26, Codex figure review VIZ1, checked by Fable.** The embedded caption did not name the
  units (F11) and drew the extrapolation's conclusion without its premise (F12). CX-191, CX-192.
- **2026-09-27.** The premise was added to TR-12 and to this spec (CX-224, item 6).
- **2026-09-28, Codex visualization review, triaged by Fable.** 21 exponent glyphs rendered at
  8.84 px, below the 12-px floor, and the constants moved into the committed table the footer now
  hashes (Q-889, Q-890), CX-225. The legend entries ran 70–90 characters and the legend box covered
  the arrow; they are short now, and the embedded note is three lines, CX-227.
- **2026-09-29.** The figure is shown at the top of this page, and these summary sections were added
  as part of the [capstone's visual showcase](README.md) (CX-233).

*The rest of this page is the figure's specification and drafting record, kept as written, with its
dated corrections in place.*

> **Status: DRAWN 2026-09-23.** Accepted 2026-09-04 (Q-308); drafted by `viz/report_figures.py`
> (`fig_viz_scale`). Every constant below is already published (the generator reads them from `viz/viz_scale_inputs.tsv` and asserts each against the registry it transcribes, Q-890, 2026-09-28); the figure required no new
> computation, no ladder read, and no VM. This page is the spec, per the doc-per-figure convention —
> it exists so that drafting does not improvise the caption, which is where this particular figure
> can most easily mislead. ⚠ *(corrected 2026-09-23: the title carried "PLAN ROW, not yet drawn" and
> this block read "planned, [cost redacted], not drafted" — by that date the figure was on disk, so the
> page described an undrawn plan for a figure that already existed.)*
> ⚠ *(noted 2026-09-24: "on disk" meant the generator's working directory — no rendered file was in
> the repository tree. It is now rendered to `reports/figures/viz_scale.{png,svg}` (committed
> 2026-09-24, with TR-12 v1.12). **Embedded once**, in TR-12's scope section
> ([`reports/TR12_QUERY_PROGRAM.md`](../reports/TR12_QUERY_PROGRAM.md) §"What this document is, and
> what it is not"), by operator decision on 2026-09-24. Its caption carries both space labels per
> §"The caption MUST carry BOTH space labels" below, and the counting-unit note that section now
> also requires.)*
> ⚠ *(noted 2026-09-24, Codex V3A-147#1 adjudicated by Fable: this page labelled the two SPACES and
> not the two COUNTING UNITS. A record is one canonical pair ordering, orientation masked, of which
> C4 allows at most 31! ≈ 8.2×10³³; N counts orientation-explicit sequences. N/31! = 133,415, so
> between 5.1 and 9.3 of the 29 plotted decades are a change of unit, not a budget shortfall. The
> unit note is now mandatory in the caption — §"The caption MUST carry BOTH space labels" — and the
> embedded TR-12 caption carries it.)*

## What it shows, in one image

The existing growth curve plots canonical solution count against per-cell node budget across the
three canonicals. This figure adds **one horizontal line: `N`**, the exact compiled superspace count,
and lets the reader see the gap.

| series | value | source |
|---|--:|---|
| 11.2T canonical records | 759,608,573 | `CANONICAL_HASHES.md` (`0c0fe37c…`) |
| 100T canonical records | 3,432,399,297 | `CANONICAL_HASHES.md` (`915abf30…`) |
| 560T canonical records | 10,525,271,997 | `CANONICAL_HASHES.md` (`9a968fa2…`) |
| **N** = \|C1∩C2∩C4∩C5\| | 1,097,051,278,789,181,790,036,112,071,176,579,186,688 | [TR-11](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §9 / [METHODS.md](../reports/METHODS.md) §"Canonical quantities" ⚠ *(corrected 2026-09-23: this row cited `CANONICAL_HASHES.md`, which does not contain N in any form — that registry holds enumeration-artifact shas and record counts, and N is not an enumeration artifact. A reader following the old citation would have found nothing.)* |

`N` divided by the deepest measured series is **1.097×10³⁹ / 1.053×10¹⁰ ≈ 1.04×10²⁹** — the line sits
about **29 decades** above the topmost data point. On a log axis that is the whole content of the
figure and it needs no annotation beyond the caption. ⚠ *(noted 2026-09-24: the drawn figure does
carry annotation — each point is labelled with its campaign, record count and sha prefix, and a
vertical arrow marks the gap with its ratio `≈ 1.04×10²⁹ (29.0 decades)`. Both restate numbers in
the table above and add no claim; the sentence is kept as the spec's original intent. The sha labels
rendered with literal markdown backticks until 2026-09-24 and now read `sha 0c0fe37c…`.)*
⚠ *(noted 2026-09-24: the ratio above divides quantities in DIFFERENT UNITS — N counts
orientation-explicit sequences, the series count canonical pair orderings — so it is the distance
between the plotted numbers, not a like-unit shortfall. In like units the C1C2C4C5-superspace holds
between N/2³¹ ≈ 5.1×10²⁹ and 31! ≈ 8.2×10³³ pair orderings, i.e. 19.7 to 23.9 decades above the
560T count; the remaining 5.1 to 9.3 decades of the 29 are the change of unit. Derivation: C4 pins
the opening pair and its orientation, so each pair ordering's orientation fiber has between 1 and
2³¹ members (King Wen's is 1,720,320), and N is the sum of those fibers over the superspace's pair
orderings. The figure's arrow label is a true ratio of the plotted numbers and is left as drawn.)*

## The three things it does at once

1. **The enumeration-is-not-a-route negative.** Three canonicals, the deepest a week-long campaign
   plus merge, and the line sits 29 orders of magnitude above it — 19.7 to 23.9 in like units. No
   feasible extrapolation of the fitted curve reaches the line: the α ≈ 0.67 power law crosses N at
   about 4.7×10⁵² nodes per cell, and even the like-unit bracket at 6×10³⁸ to 1×10⁴⁵, against
   3.5×10⁹ at 560T. This is the honest version of "why we stopped enumerating". ⚠ *(corrected
   2026-09-24, Codex V3A-147#2/#3 adjudicated by Fable: this item read "each a multi-week campaign",
   "29 orders of magnitude short" and "No extrapolation of the fitted curve reaches the line".
   `CANONICAL_HASHES.md` gives 560T as 171.5 h wall plus merge and 100T as 16 h 47 m, so none is
   multi-week; "short" implied a like-unit shortfall the units do not support; and an unbounded
   power law crosses any finite line, so only a *feasible* extrapolation fails.)*
2. **The compiler's justification.** The knowledge compiler exists precisely because the gap is not
   closable by more budget under the three-point extrapolation; it computes `N` exactly in 10.3 s from a completed ladder.
3. **The narrative document's N4 overclaim gate.** A reader who has seen this image cannot mistake a
   record count for a population count, which is the specific overclaim the gate guards.

## 🔴 The caption MUST carry BOTH space labels — this is the failure mode

The plotted series and the line **are not counts of the same space**:

* the three canonicals are **node-budgeted slices of C1–C5**, and their record counts are **lower
  bounds** over a reproducible slice (`SOLUTIONS_FORMAT.md`);
* `N` is the **exact** `|C1∩C2∩C4∩C5|` of the **C1C2C4C5-SUPERSPACE** — C3 is not among its
  constraints, and neither are C6/C7;
* **and the two count in different UNITS** (mandatory since 2026-09-24): a record is one canonical
  **pair ordering** with within-pair orientation masked (`SOLUTIONS_FORMAT.md` §Deduplication), of
  which C4 allows at most 31! ≈ 8.2×10³³; `N` counts **orientation-explicit sequences**, each pair
  ordering contributing its fiber of 1 to 2³¹ of them. N/31! = 133,415, so 5.1 to 9.3 of the 29
  decades are the unit change and the like-unit gap is 19.7 to 23.9 decades. The caption states the
  unit of each series and gives the gap in like units as a bracket, never as a single number.

Putting them on one axis is legitimate and is the point of the figure, but a caption that says only
"solutions" invites exactly the conflation the image was drawn to prevent. **Both labels and the unit
note go in the caption, not in a footnote**, and the gap is described as a gap between a *budgeted
slice* and a *compiled superspace*, never as "how much of the space we found" and never as a
like-unit "shortfall" of 29 decades. ⚠ *(noted 2026-09-24: the third bullet was absent — this
section required the two SPACE labels only, and the figure's rendered arrow label, "N / (deepest
measured slice)", divides sequences by pair orderings. Codex V3A-147#1, adjudicated by Fable. The
image is unchanged; the caption carries the note.)*

## Reader-verifiable without trusting us

Every number above is published, and `N mod 24 == 0` is checkable in one line
(`documentation/VERIFY.md`). A reader can reproduce the ratio with a calculator and the four
constants; nothing here requires access to a ladder or belief in a campaign. The unit bracket is
one more line: `python3 -c "from math import factorial as f; N=1097051278789181790036112071176579186688; print(N//f(31), N/2**31, f(31))"`
→ `133415 5.108…e+29 8222838654177922817725562880000000`.

## Decided at drafting — axis treatment

⚠ *(corrected 2026-09-23: this section was headed "Not decided here" and left the choice open,
asking only that whoever drafted it state the choice in the page rather than the image. The figure
has since been drawn, so the choice is made and recorded below — the rationale previously lived in a
comment in `viz/report_figures.py`, which is the one place this page had said it must not live.)*

**The axis runs the FULL ~29 decades, unbroken.**

Both treatments are honest, and the broken axis is the more readable of the two. It was rejected
anyway, because the quantity this figure exists to convey **is the distance**: an axis break both
shortens that distance visually and implies the two series are commensurable across the break —
the same conflation that §"The caption MUST carry BOTH space labels" exists to prevent. A figure
whose single job is to show a gap should not compress the gap for legibility.

The drafted figure asserts this rather than trusting it: `fig_viz_scale` carries
`assert 28.5 < decades < 29.5`, so if a constant on this page ever moves far enough to change the
story, the generator fails loudly instead of quietly redrawing a smaller gap.

---

*Specification per TR-12 §"What this document is, and what it is not" and Q-308. Nothing here is
claimed novel: this is a log-log plot of published constants. Developed with AI assistance (Claude,
Anthropic); corrections invited.*
