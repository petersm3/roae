# Visualization plan — the scale figure (`viz_scale.png/.svg`) · **PLAN ROW, not yet drawn**

> **Status: planned, zero-dollar, not drafted.** Accepted 2026-09-04 (Q-308). Every constant below is
> already published; the figure requires no new computation, no ladder read, and no VM. This page is
> the spec, per the doc-per-figure convention — it exists so that drafting does not improvise the
> caption, which is where this particular figure can most easily mislead.

## What it shows, in one image

The existing growth curve plots canonical solution count against per-cell node budget across the
three canonicals. This figure adds **one horizontal line: `N`**, the exact compiled superspace count,
and lets the reader see the gap.

| series | value | source |
|---|--:|---|
| 11.2T canonical records | 759,608,573 | `CANONICAL_HASHES.md` (`0c0fe37c…`) |
| 100T canonical records | 3,432,399,297 | `CANONICAL_HASHES.md` (`915abf30…`) |
| 560T canonical records | 10,525,271,997 | `CANONICAL_HASHES.md` (`9a968fa2…`) |
| **N** = \|C1∩C2∩C4∩C5\| | 1,097,051,278,789,181,790,036,112,071,176,579,186,688 | TR-11 / `CANONICAL_HASHES.md` |

`N` divided by the deepest measured series is **1.097×10³⁹ / 1.053×10¹⁰ ≈ 1.04×10²⁹** — the line sits
about **29 decades** above the topmost data point. On a log axis that is the whole content of the
figure and it needs no annotation beyond the caption.

## The three things it does at once

1. **The enumeration-is-not-a-route negative.** Three canonicals, each a multi-week campaign, and the
   deepest of them is 29 orders of magnitude short. No extrapolation of the fitted curve reaches the
   line. This is the honest version of "why we stopped enumerating".
2. **The compiler's justification.** The knowledge compiler exists precisely because the gap is not
   closable by more budget; it computes `N` exactly in 10.3 s from a completed ladder.
3. **The narrative document's N4 overclaim gate.** A reader who has seen this image cannot mistake a
   record count for a population count, which is the specific overclaim the gate guards.

## 🔴 The caption MUST carry BOTH space labels — this is the failure mode

The plotted series and the line **are not counts of the same space**:

* the three canonicals are **node-budgeted slices of C1–C5**, and their record counts are **lower
  bounds** over a reproducible slice (`SOLUTIONS_FORMAT.md`);
* `N` is the **exact** `|C1∩C2∩C4∩C5|` of the **C1C2C4C5-SUPERSPACE** — C3 is not among its
  constraints, and neither are C6/C7.

Putting them on one axis is legitimate and is the point of the figure, but a caption that says only
"solutions" invites exactly the conflation the image was drawn to prevent. **Both labels go in the
caption, not in a footnote**, and the gap is described as a gap between a *budgeted slice* and a
*compiled superspace*, never as "how much of the space we found".

## Reader-verifiable without trusting us

Every number above is published, and `N mod 24 == 0` is checkable in one line
(`documentation/VERIFY.md`). A reader can reproduce the ratio with a calculator and the four
constants; nothing here requires access to a ladder or belief in a campaign.

## Not decided here

Axis treatment (whether the line is drawn at the top of a broken axis or the axis is allowed to run
the full 29 decades) is a drafting choice. Both are honest; the broken axis is more readable and the
full axis is more visceral. Whoever drafts it should pick one and say why in the page, not in the
image.
