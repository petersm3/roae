# Figure — TR-1, the conflict theorem's trade-off (`fig_tr1_rules_tradeoff`)

← [Visual capstone](README.md#the-rules-and-the-conflict) · Report: [TR-1 §Figure](../reports/TR1_EIGHT_CENTURIES_MEASURED.md#figure) (also shown in [TR-2 §Figure](../reports/TR2_THE_RULES_CONFLICT.md#figure))

[![Four-row comparison table of four conflicting rules: King Wen has 2 misses, breaks or violations on each of the first three rules and satisfies the fourth, the trigram configuration; the grand unified precursor has 0 on the first three and violates the fourth.](../reports/figures/fig_tr1_rules_tradeoff.png)](../reports/figures/fig_tr1_rules_tradeoff.svg)

*The figure as committed. Click the image for the SVG. The authoritative caption is in [TR-1 §Figure](../reports/TR1_EIGHT_CENTURIES_MEASURED.md#figure).*

## In plain terms

This table compares King Wen's order with the "grand unified precursor", an ordering that differs
from King Wen in three places, on four rules taken from published studies of the sequence. King Wen
misses each of the first three rules by two and keeps the fourth exactly, while the precursor keeps
the first three perfectly and breaks the fourth. A computer-checked proof shows that no ordering
obeying four of the project's five core rules (all but the one called C3) can keep all four of these
rules at once, so some trade-off is forced.

## What it shows

A four-row table with one column for King Wen and one for the precursor. The rows are Moore's 2005
parity rule, Moore's 1989 rhythm rule, Schulz's 1990 gender rule, and Schulz's trigram configuration
of stations 25–28 (a station is one of Lai Zhide's 36 consolidated units; the figure's note says so).
Each cell states its count in its own unit ("2 misses (16/18)", "2 breaks", "2 violations",
"satisfied", "violated"). The cell tint repeats the verdict (green for met, red for missed) and never
carries it alone, so the table reads the same without colour.

## What it establishes, and what it does not

- **Establishes.** On these four rules King Wen sits at one trade-off position and the precursor at
  another, and the joint unsatisfiability result says no C1∩C2∩C4∩C5-valid ordering reaches zero on
  all four axes at once ([TR-1 §Figure](../reports/TR1_EIGHT_CENTURIES_MEASURED.md#figure); the
  conflict theorem is TR-1 §5 and [TR-2](../reports/TR2_THE_RULES_CONFLICT.md)). The unsatisfiability
  is a drat-trim-verified SAT result, scoped to the rules as TR-1 and TR-2 encode them.
- **Does not establish.** That King Wen's misses are the smallest possible: TR-1's caption records
  that "minimal" is unsupported, because no extremal check exists. Nor that the received order was
  ever a damaged copy of a perfect one: TR-2 says the irregularities are *consistent with* the forced
  choice. All four rules are descriptive of King Wen, so scoring well on them is expected rather than
  a measure of design (TR-1 §5).

## Provenance

- **Data.** No table. The counts are the reports' stated numbers, typed into the generator with a
  source comment and asserted before drawing (`assert kw == [2, 2, 2] and gp == [0, 0, 0]`): TR-1 §5
  and TR-2's abstract.
- **Generator.** `fig_tr1_rules_tradeoff()` in [`viz/report_figures.py`](report_figures.py). It
  also asserts that every text colour meets 4.5:1 contrast on every cell tint before drawing.
- **Regenerate.** The whole set, from the repository root:

  ```bash
  cd reports/figures && python3 ../../viz/report_figures.py
  ```

  or this figure alone:

  ```bash
  cd reports/figures && python3 -c "import sys; sys.path.insert(0, '../../viz'); import report_figures as r; r.fig_tr1_rules_tradeoff()"
  ```

- **Toolchain.** matplotlib 3.11.0 and numpy 2.4.4 (external; not dependencies of `roae.py` or
  `solve.c`). Under that pin the documented command reproduced the committed PNG byte for byte on
  2026-09-29, with all twelve report figures (CX-233). SVGs differ between renders in `<dc:date>` and
  element ids, so compare them line-wise. The rules are in
  [Reproduce the figures](README.md#reproduce-the-figures).
- **Tokens and certificates.** The conflict theorem's certificate and its verification command are
  in [TR-1's Verification Guide](../reports/TR1_EIGHT_CENTURIES_MEASURED.md#verification-guide) and
  TR-2.

## Review history

- **2026-09-02.** The drawn string "minimal measured margins" was fixed in the generator and the image
  regenerated, so image and caption agree (TR-1's caption marker; prose batch P73).
- **2026-09-26, Codex figure review VIZ1, checked by Fable.** The legend covered King Wen's first "2",
  and the binary trigram rule was drawn as a bar length with no count behind it (F13). Redrawn, with
  the 12-px text floor (F18). [CORRECTIONS.md](../documentation/CORRECTIONS.md) CX-192.
- **2026-09-28, Codex visualization review (VIZ-H2), triaged by Fable.** King Wen and the precursor
  were told apart by red against green only, and the green labels measured 4.12:1. The figure became
  the four-row table above, with its contrast asserted in code. CX-227 (TR-1 revision row v1.37).
- **2026-09-29.** This page added, as part of the visual capstone (CX-233).

---

*Part of the [visual capstone](README.md), the companion to
[TR-12](../reports/TR12_QUERY_PROGRAM.md). Nothing here is claimed novel: the rules are the cited
authors', and the figure is a table of the reports' numbers. Developed with AI assistance (Claude,
Anthropic); corrections invited.*
