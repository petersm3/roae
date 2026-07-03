# TR-4 — The Size of the Space: Measurement, the Uniqueness Conjecture, and the Boundary-Information Curve
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Abstract
We measure the total number of hexagram orderings satisfying constraints C1–C5 — the number every budgeted
enumeration has only ever bounded from below — using Knuth's (1975) unbiased random-probe estimator run
over the *exact* production search tree: **1.3287×10³⁸ raw canonical orderings (95% CI [1.3283,
1.3292]×10³⁸, rel. error 0.02%; ≈3.3×10³⁷ after orientation-dedup)**. This is a statistical estimate, not
a proven cardinality, validated to <1% against exact subtree counts on a three-rung ladder plus an
independent 56-branch cross-sum. Three consequences follow. First, the deepest published canonical (560T;
1.05×10¹⁰ distinct orderings) has enumerated ≈1 part in 10²⁷ of the space — exhaustion is infeasible at any
budget. Second, extending the walk with the spec's C6/C7 adjacency constraints **refutes the long-standing
Uniqueness Conjecture**: ≈5.21×10³¹ orderings satisfy C1–C7; King Wen is unique only within budgeted
slices. Third, the boundary-information curve S(k) shows the four boundaries that uniquely identify King
Wen inside the 560T slice still admit **≈8.4×10²⁵ full-space orderings** — the sharpest quantification yet
of the slice-uniqueness vs space-uniqueness distinction. We close with why King Wen's *early* appearance
in the enumeration is an artifact of the search setup, and why that changes no finding.

## Sections
1. **What is being measured.** The exhaustive enumerations are *budgeted*: each of 158,364 depth-3 cells
   gets a fixed node budget, no cell is ever exhausted (one sub-branch budgeted to "yield 16" held ≥664
   million orderings on a deeper walk), so canonical record counts are lower bounds. The three-point
   scaling trajectory (11.2T → 100T → 560T, α ≈ 0.67) shows counts still growing sublinearly with no
   visible asymptote. This report measures the total *un-budgeted* tree — the number those counts converge
   toward — closing the "total count not yet known" caveat carried in LEADERBOARD/CANONICAL_HASHES:
   now "known to ≈1% as an estimate, still astronomically unexhaustible."
2. **The estimator and its validation ladder.** Knuth (1975, *Estimating the efficiency of backtrack
   programs*, Math. Comp. 29): a probe is one random root→dead-end walk multiplying live-child counts into
   an unbiased weight; the estimator reuses solve.c's exact prune predicates, so it samples the identical
   tree the enumerator walks, touches no solution data, and is sha-neutral (--selftest unchanged).
   Validation: `--estimate-knuth 0 <prefix>` gives *exact* deterministic subtree counts; Monte-Carlo agrees
   <1% at every rung (5 free positions: 443 exact vs 442.9; 7: 62,256 vs 62,257; 9: 9,422,793 vs 9,424,649
   nodes, 16,504 vs 16,422 canonical). Independent cross-check: 56 per-branch estimates sum to 1.33×10³⁸ vs
   the independently-estimated whole-tree 1.32×10³⁸ (<1%).
3. **The measurement.** 5×10¹⁰ probes (definitive 100×-probe run, 2026-07-01; the earlier 5×10⁸ run gave the
   same central value at wider CI): canonical C1–C5 raw **1.3287×10³⁸** (0.02%); C1/C2/C4/C5 complete
   orderings 1.0971×10³⁹ (0.01%); total tree nodes 2.0875×10⁴⁰ (0.00%). This supplies the terminal count of
   the reduction funnel (64! ≈ 1.3×10⁸⁹ → C1 skeleton 32!·2³² ≈ 1.1×10⁴⁵ → ~10⁴⁰ → ≈1.3×10³⁸). Structure:
   the 56 first-level branches are roughly uniform (min 1.26×10³⁶, median 2.26×10³⁶, max 3.46×10³⁶, spread
   ≈2.7× — no small or near-exhaustible branch exists); the 65,281 productive depth-3 cells span only 94.6×
   in total size (10³¹·⁸–10³³·⁸) while their *budgeted* yields span ≈5.7 orders (10¹·¹–10⁶·⁸), and the two
   are essentially uncorrelated (Pearson r = 0.17, Spearman ρ = 0.15, full population; confirms the earlier
   605-cell sample, r≈0.15). Budgeted yield is a local-density phenomenon, not a size phenomenon. A prior
   product-of-averages estimate (10¹⁴–10¹⁵ nodes) was a ≈20-order undercount — biased downward for
   heavy-tailed branching; unbiased probe sampling is the correct tool.
4. **The Uniqueness Conjecture is refuted (2026-07-02).** Extending the probe walk with the spec's C6/C7
   adjacency constraints (slots 24–27 pinned to King Wen's pairs, orientation free) makes the conjecture
   directly measurable: **5.21×10³¹ C1–C7-satisfying orderings** (95% CI [5.13, 5.29]×10³¹, 0.78%; without
   C3: 5.18×10³², 0.25%; pinned tree nodes 1.4539×10³⁵). C6+C7 cut the C1–C5 space by ×2.55×10⁶ — but
   ≈5.2×10³¹ survive. King Wen is not uniquely determined by the published constraint system over the full
   space; uniqueness holds only within enumerated budgeted datasets. Closing the remaining ≈105 bits would
   need roughly 15–20 boundary constraints. Exact small-scope corroboration: in the KW-following 22-pair
   prefix subtree, exact counting finds 16,504 C1–C5 completions of which exactly **8** satisfy C6/C7 — KW
   plus seven others even in its own immediate neighborhood.
5. **The boundary-information curve S(k) (2026-07-03).** S(k) = fraction of the full C1–C5 population
   agreeing with KW on the first k boundaries of the 560T greedy identifying order {4, 27, 25, 21}
   (flanking-slots predicate of PARTITION_STABILITY_BOUNDARIES.md), measured by pinned Knuth walks (2×10⁹
   probes per prefix, rel. error ≤10%): k=1: 7.49×10⁻⁴ (9.95×10³⁴ survivors, ×1,335 cut); k=2: 9.39×10⁻⁷
   (1.25×10³², ×798); k=3: 4.27×10⁻¹⁰ (5.68×10²⁸, ×2,196); k=4: 6.34×10⁻¹³ (**8.42×10²⁵**, ×674).
   Headline: the four boundaries that uniquely identify King Wen inside the 560T slice still admit ≈10²⁶
   full-space orderings. Extrapolating the roughly constant ~10³ per-boundary cut puts full-space
   uniqueness at roughly 13–14 well-chosen boundaries (wide error; prior structural estimate 15–20). A
   bracketing run on the *weakest* remaining boundaries (k = 5–8) still cut ×15–17 per boundary, so the
   decay is robust to boundary choice within an order of magnitude per step. Extending the greedy curve
   past k = 4 needs ~100× the probe budget (conditional masses starve below ~10⁻¹³ hit rates); queued.
6. **Why King Wen is found "early" — an artifact, fully owned.** The enumeration is a systematic DFS, not
   random sampling: time-to-reach a known ordering depends on where it sits in traversal order, not on the
   solution-set size. King Wen's early appearance is produced by three setup choices — the constraints
   (reverse-engineered *from* KW, guaranteeing membership, not early arrival), the per-cell decomposition
   (guaranteeing breadth), and the variable/value ordering (placing KW's one leaf inside its cell's ~3.5
   B-node budgeted frontier, out of ~10³³ leaves) — and an adversarial choice on any of them could delay or
   miss it at a fixed budget. This changes no finding: KW is a known input verified in microseconds; all
   claims are relative comparisons over the enumerated set with KW held known; membership is
   order-invariant. The ≈10³⁸ estimate shows KW is **not special by being rare or hard to find** — its
   distinction is purely structural, which is exactly why the project's claims are about where KW sits in
   the distribution, never about combinatorial uniqueness.

## Status and provenance caveat
All quantities here are Monte-Carlo estimates on the exploration track. They do not change, and are not
gated by, any canonical sha256. No "proven" claim is made about exact cardinality — only that it is ≈10³⁸
to within the stated sampling error. Method attribution: Knuth (1975). Constraint provenance and prior
literature: CITATIONS.md.

## Verification Guide
- Estimator implementation + exact-count mode: `gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz`, then
  `solve --estimate-knuth 500000000` (whole tree; 5×10⁸ probes ≈ 79 s single-machine, pennies of compute);
  `solve --estimate-knuth 100000000 <p1> <o1>` (one branch); `solve --estimate-knuth 0 <prefix>` (exact
  validation ladder). No data disk required.
- Full write-up, tables, per-cell distribution: documentation/SEARCH_SPACE_SIZE.md
- Uniqueness-conjecture refutation: `SOLVE_KNUTH_C67=1 ./solve --estimate-knuth ...` (SEARCH_SPACE_SIZE.md
  §"The C1–C7 space"); run log in roae-private (probe on `c207`, 2026-07-02)
- S(k) curve: `SOLVE_KNUTH_PIN_SLOTS="3,4,26,27,24,25,20,21" SOLVE_KNUTH_BOUNDARY_COND=1 ./solve
  --estimate-knuth 2000000000`
- Budgeted counts as lower bounds: documentation/CRITIQUE.md §"per-branch yield labels"; scaling
  trajectory: documentation/SOLVE-SUMMARY.md
- Boundary predicate: documentation/PARTITION_STABILITY_BOUNDARIES.md

## TODO before review
- [ ] One figure: the S(k) log-decay curve with the greedy vs weakest-boundary bracket
- [ ] Confirm the ~3.5 B per-cell budget figure quoted in §6 against the 560T campaign parameters
- [ ] Cross-check the ≈105-bits arithmetic note (log₂ of 5.21×10³¹) is stated consistently with S(k)'s
      13–14-boundary extrapolation
- [ ] Decide whether the per-cell scatter (yield vs size) plot from viz/ is worth embedding

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
