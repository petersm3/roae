# Figure — TR-7, the cycle (`fig_tr7_circular_cycle`)

← [The capstone's visual showcase](README.md#structure-of-the-sequence) · Report: [TR-7 §Figure: the cycle](../reports/TR7_CIRCULAR_READING.md#figure-the-cycle)

[![The 64 hexagrams as a cycle in King Wen order, with thick red edges at the odd Hamming-distance transitions: 15 internal plus the 64→1 wrap of distance 3, 16 in all.](../reports/figures/fig_tr7_circular_cycle.png)](../reports/figures/fig_tr7_circular_cycle.svg)

*The figure as committed. Click the image for the SVG. The authoritative caption is in [TR-7 §Figure: the cycle](../reports/TR7_CIRCULAR_READING.md#figure-the-cycle).*

## In plain terms

This ring places all 64 hexagrams in King Wen order and joins the last one back to the first. Red
edges mark the steps where an odd number of the six lines change: 15 along the sequence, plus the step
from hexagram 64 back to hexagram 1, which changes three lines. TR-7 proves that this closing step
changes an odd number of lines in every ordering that obeys two of the core rules (C4 and C5), so for
orderings that obey all five, reading the sequence as a circle always adds exactly one odd step.

## What it shows

64 nodes on a circle, #1 to #64 clockwise, #1 just right of the top and #64 just left of it, so the
closing edge 64→1 is the short chord at the top. Thick red edges are odd transitions (an odd Hamming
distance, the number of lines that change); thin pale edges are even ones. One label gives King Wen's
own wrap, d = 3 (3 of the 6 lines change). A separate line under the ring states the wrap-parity
theorem with its premise: for every ordering satisfying C4 and C5, the wrap distance is odd.

## What it establishes, and what it does not

- **Establishes.** Read circularly, King Wen has 16 odd transitions where the linear reading has 15;
  the wrap adds exactly one, always, for an ordering that satisfies C1–C5 as written, because the
  wrap-parity theorem makes the wrap distance odd under C4 and C5
  ([TR-7 §Figure](../reports/TR7_CIRCULAR_READING.md#figure-the-cycle), §2).
- **Does not establish.** That whoever arranged the sequence meant it to be read as a circle: the
  theorem says what a circular reading necessarily contains, not whether anyone read it that way.
  King Wen's particular wrap distance, 3, is King Wen's; only its oddness is forced.

## Provenance

- **Data.** No table. The helper `_tr7_cycle_edges()` computes the Hamming distance of all 64 edges
  from `solve.py`'s King Wen sequence (`binary_hexagrams`). The generator asserts 15 odd internal
  transitions, a wrap distance of 3, and 16 odd transitions around the cycle before drawing. The
  figure's footer names `solve.py binary_hexagrams` and TR-7 as its sources.
- **Generator.** `fig_tr7_circular_cycle()` in [`viz/report_figures.py`](report_figures.py).
- **Regenerate.** The whole set:

  ```bash
  cd reports/figures && python3 ../../viz/report_figures.py
  ```

  or this figure alone:

  ```bash
  cd reports/figures && python3 -c "import sys; sys.path.insert(0, '../../viz'); import report_figures as r; r.fig_tr7_circular_cycle()"
  ```

- **Toolchain.** matplotlib 3.11.0 and numpy 2.4.4. Under that pin the documented command reproduced
  the committed PNG byte for byte on 2026-09-29, with all twelve report figures (CX-233). See
  [Reproduce the figures](README.md#reproduce-the-figures).
- **Checks.** TR-7's [Verification Guide](../reports/TR7_CIRCULAR_READING.md#verification-guide).

## Review history

- **2026-07-04.** Committed as finished artwork, with no renderer.
- **2026-09-26, Codex figure review VIZ1, checked by Fable (F15, F16).** The alt text only named the
  picture, and no renderer existed; the documents were corrected to say so. CX-191.
- **2026-09-27 (Q-858).** The figure is now drawn from the sequence by `fig_tr7_circular_cycle()`,
  with its counts asserted. CX-205.
- **2026-09-28, Codex visualization review, triaged by Fable.** One annotation stated both King Wen's
  wrap and the theorem for every ordering, without the theorem's premise. They are now two labels, and
  the theorem line states C4 and C5. CX-227 (TR-7 revision row v2.10).
- **2026-09-29.** This page added, as part of the capstone's visual showcase (CX-233).

---

*Part of the [capstone's visual showcase](README.md), the companion to
[TR-12](../reports/TR12_QUERY_PROGRAM.md). A cycle drawing of the sequence; nothing is claimed novel.
Developed with AI assistance (Claude, Anthropic); corrections invited.*
