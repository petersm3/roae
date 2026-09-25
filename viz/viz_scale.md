# The scale figure (`viz_scale.png/.svg`) — spec and drafting record

> **Status: DRAWN 2026-09-23.** Accepted 2026-09-04 (Q-308); drafted by `viz/report_figures.py`
> (`fig_viz_scale`). Every constant below is already published; the figure required no new
> computation, no ladder read, and no VM. This page is the spec, per the doc-per-figure convention —
> it exists so that drafting does not improvise the caption, which is where this particular figure
> can most easily mislead. ⚠ *(corrected 2026-09-23: the title carried "PLAN ROW, not yet drawn" and
> this block read "planned, zero-dollar, not drafted" — by that date the figure was on disk, so the
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
   closable by more budget; it computes `N` exactly in 10.3 s from a completed ladder.
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
