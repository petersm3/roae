# Figure — TR-5, the symmetry collapse (`fig_tr5_orbit_collapse`)

← [The capstone's visual showcase](README.md#the-space-and-its-scale) · Report: [TR-5 §Figure: the symmetry collapse](../reports/TR5_SYMMETRY.md#figure-the-symmetry-collapse)

[![Diagram of the order-48 group B₃ quotienting by {±I} to a free order-24 S₄ action on canonical pair-order records, with a ring showing King Wen's record and the 23 other records in its orbit.](../reports/figures/fig_tr5_orbit_collapse.png)](../reports/figures/fig_tr5_orbit_collapse.svg)

*The figure as committed. Click the image for the SVG. The authoritative caption is in [TR-5 §Figure: the symmetry collapse](../reports/TR5_SYMMETRY.md#figure-the-symmetry-collapse).*

## In plain terms

There are 48 ways to reshuffle and flip the six lines of every hexagram at once that keep the
project's rules true. One of them, turning every hexagram upside down, changes nothing in a record (a
record lists the order of the 32 pairs, not which member of each pair comes first), so only 24
different changes are left. The picture shows that these 24 turn King Wen's record into 24 different
records, and TR-5 proves the same holds for every valid record. Any test that gives the same answer
under these 24 changes cannot tell such a group of records apart.

## What it shows

- **Left:** three boxes and two arrows. B₃, the order-48 group of signed line-permutations that
  preserve C1–C5, collapses by its centre {±I} to S₄ (order 24), which acts faithfully and freely on
  canonical pair-order records. The quotient note explains why −I is invisible to a record: it turns
  each hexagram upside down, which maps every C1 pair onto itself, and a record ignores the order
  within a pair.
- **Right:** a ring of 24 records, King Wen's among them. The theorem note states the count for an
  S₄-closed set of R records: R/24 record-orbits, exactly.

## What it establishes, and what it does not

- **Establishes.** Every valid canonical pair-order record, King Wen's included, has an orbit of 24
  records under S₄, and these are indistinguishable by any criterion invariant under S₄; for the full,
  S₄-closed set of valid records the count R is divisible by 24 and the orbit count is R/24
  ([TR-5 §Figure](../reports/TR5_SYMMETRY.md#figure-the-symmetry-collapse), §1, §4).
- **Does not establish.** That the 24 cannot be told apart by *any* test: a criterion that is not
  S₄-invariant, such as slot-by-slot agreement with King Wen's record, does separate them. At the
  level of orientation-explicit orderings the orbit has 48 members, not 24. A budgeted slice of the
  space is not S₄-closed (the 560T canonical's 10,525,271,997 records are 21 mod 24), so R/24 applies
  to the full set, not to a slice. Whether some map on the solution set that no hexagram relabelling
  induces could separate twins is open (TR-5 executive summary).

## Provenance

- **Data.** No table and no enumeration output. The generator builds the 48 permutations, their
  centre {±I} and King Wen's orbit (48 oriented sequences, 24 records) from `solve.py`'s King Wen
  sequence (`binary_hexagrams`, `reverse_6bit`), and asserts every number the drawing states before
  drawing: the group order 48, the centre, the quotient's element orders, 48 oriented sequences and
  24 records. The figure's footer reads `source: solve.py binary_hexagrams + reverse_6bit`.
- **Generator.** `fig_tr5_orbit_collapse()` and its helper `_tr5_kw_orbit()` in
  [`viz/report_figures.py`](report_figures.py).
- **Regenerate.** The whole set:

  ```bash
  cd reports/figures && python3 ../../viz/report_figures.py
  ```

  or this figure alone:

  ```bash
  cd reports/figures && python3 -c "import sys; sys.path.insert(0, '../../viz'); import report_figures as r; r.fig_tr5_orbit_collapse()"
  ```

- **Toolchain.** matplotlib 3.11.0 and numpy 2.4.4. Under that pin the documented command reproduced
  the committed PNG byte for byte on 2026-09-29, with all twelve report figures (CX-233). See
  [Reproduce the figures](README.md#reproduce-the-figures).
- **Checks.** TR-5's [Verification Guide](../reports/TR5_SYMMETRY.md#verification-guide) and its
  [numerical instantiation](../reports/TR5_SYMMETRY.md#numerical-instantiation-v16-the-theorem-checked-against-an-exact-count)
  check the theorem against an exact count.

## Review history

- **2026-07-04.** Committed as finished artwork, with no renderer.
- **2026-09-26, Codex figure review VIZ1, checked by Fable (F14, F15).** The caption said every valid
  ordering sits in an orbit of exactly 24 mutually indistinguishable orderings. The 24 are records,
  not orderings, and they are alike only under S₄-invariant criteria; the caption was corrected.
  CX-191.
- **2026-09-27 (Q-858).** No renderer had ever been committed, the smallest text was 11.1 px at a
  900-px display, and the drawing still carried the retired wording. The figure is now drawn from the
  sequence by `fig_tr5_orbit_collapse()`. CX-205.
- **2026-09-28, Codex visualization review, triaged by Fable.** The R/24 statement carried no premise,
  and "±I acts trivially" did not say what −I is. Both notes now state them. CX-227 (TR-5 revision
  row v2.21).
- **2026-09-29.** This page added, as part of the capstone's visual showcase (CX-233).

---

*Part of the [capstone's visual showcase](README.md), the companion to
[TR-12](../reports/TR12_QUERY_PROGRAM.md). A diagram of TR-5's group-theoretic result; the group
theory is standard. Developed with AI assistance (Claude, Anthropic); corrections invited.*
