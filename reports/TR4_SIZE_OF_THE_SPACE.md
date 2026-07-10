# TR-4 — The Size of the Space: Measurement, the Uniqueness Conjecture, and the Boundary-Information Curve
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

How special is the King Wen sequence, really? That question needs a denominator: **how many other
arrangements satisfy the same rules?** This report measures it. The answer — about 10³⁸, a hundred
trillion trillion trillion — settles a folk conjecture: the known rules do **not** pin down King Wen;
they leave an astronomical family of valid alternatives, and King Wen is one member. The report also
measures how much *additional* information is needed to single King Wen out (roughly 13–20 carefully
chosen adjacency facts) and explains why earlier, smaller searches wrongly suggested near-uniqueness:
bounded search sees a biased sample. The measurement technique is validated against exact counts at
every scale where exact counts exist.

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
slices. Third, the boundary-information curve S(k) shows the first four boundaries of King Wen's 560T greedy
identifying set (the full set has five; see revision v1.8) still admit **≈8.4×10²⁵ full-space orderings** —
the sharpest quantification yet of the slice-uniqueness vs space-uniqueness distinction. We close with why King Wen's *early* appearance
in the enumeration is an artifact of the search setup, and why that changes no finding.

## Sections
1. **What is being measured.** The exhaustive enumerations are *budgeted*: each of 158,364 depth-3 cells
   gets a fixed node budget, no cell is ever exhausted (one sub-branch budgeted to "yield 16" held ≥664
   million orderings on a deeper walk), so canonical record counts are lower bounds. The three-point
   scaling trajectory (11.2T → 100T → 560T, α ≈ 0.67) shows counts still growing sublinearly with no
   visible asymptote. This report measures the total *un-budgeted* tree — the number those counts converge
   toward — closing the "total count not yet known" caveat carried in LEADERBOARD/[CANONICAL_HASHES](../documentation/CANONICAL_HASHES.md):
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
   agreeing with KW on the first k boundaries of the 560T greedy identifying order {4, 27, 25, 21, 1}
   (first four measured here; flanking-slots predicate of [PARTITION_STABILITY_BOUNDARIES.md](../documentation/PARTITION_STABILITY_BOUNDARIES.md)), measured by
   pinned Knuth walks (2×10⁹
   probes per prefix, rel. error ≤10%): k=1: 7.49×10⁻⁴ (9.95×10³⁴ survivors, ×1,335 cut); k=2: 9.39×10⁻⁷
   (1.25×10³², ×798); k=3: 4.27×10⁻¹⁰ (5.68×10²⁸, ×2,196); k=4: 6.34×10⁻¹³ (**8.42×10²⁵**, ×674).
   Headline: the first four boundaries of KW's identifying set — which inside the 560T slice leave only KW
   plus a single impostor; the full identifying set has 5 boundaries (v1.7.1 correction) — still admit ≈10²⁶
   full-space orderings. Extrapolating the roughly constant ~10³ per-boundary cut initially put full-space
   uniqueness at roughly 13–14 well-chosen boundaries — but the 2026-07-05 S(6)–S(8) measurement (see the
   Update below) shows the per-boundary gains bend downward past k = 5, revising this projection **up to
   ~15–20 boundaries** and superseding the earlier 13–14 figure; the hard information-theoretic floor
   k ≥ 13 is unaffected. A
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
literature: [CITATIONS.md](../documentation/CITATIONS.md).

## Figure

![Log-scale decay curve of S(k), the fraction of the full C1–C5 population agreeing with King Wen on its first k identifying boundaries: four measured points falling from 7.49e-4 at k=1 to 6.34e-13 at k=4, a dashed extrapolation at the ~×1000-per-boundary greedy cut, an orange measured bracket for the weakest remaining boundaries (×15–17 per boundary, k=5–8), and a shaded band at k≈13–20 where extrapolation reaches full-space uniqueness.](figures/fig_tr4_boundary_information.png)

*The boundary-information curve S(k) (§5). Red points are the measured pinned-Knuth values on the first
four boundaries of the 560T greedy identifying order {4, 27, 25, 21, 1}, annotated with the
surviving-orderings counts — those k = 4 boundaries (which inside the 560T slice leave KW plus one
impostor; the full identifying set has 5 boundaries) still admit ≈8.4×10²⁵ full-space
orderings. The dashed line extrapolates the roughly constant ~×10³ per-boundary cut (NOT measured); the
orange band is the measured weakest-remaining-boundary bracket (×15–17 per boundary at k = 5–8),
bounding how much the decay depends on boundary choice. The green band marks where extrapolation
reaches one surviving ordering: ~15–20 boundaries (revised up from an earlier ~13–14 estimate by the
2026-07-05 S(6)–S(8) measurement; wide error; hard information-theoretic floor k ≥ 13).
Generated by [`viz/report_figures.py`](../viz/report_figures.py);
[SVG](figures/fig_tr4_boundary_information.svg).*

## Verification Guide
- Estimator implementation + exact-count mode: `gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz`, then
  `solve --estimate-knuth 500000000` (whole tree; 5×10⁸ probes ≈ 79 s single-machine, pennies of compute);
  `solve --estimate-knuth 100000000 <p1> <o1>` (one branch); `solve --estimate-knuth 0 <prefix>` (exact
  validation ladder). No data disk required.
- Full write-up, tables, per-cell distribution: [documentation/SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md)
- Uniqueness-conjecture refutation: `SOLVE_KNUTH_C67=1 ./solve --estimate-knuth ...` (SEARCH_SPACE_SIZE.md
  §"The C1–C7 space"); run log in roae-private (probe on `c207`, 2026-07-02)
- S(k) curve: `SOLVE_KNUTH_PIN_SLOTS="3,4,26,27,24,25,20,21" SOLVE_KNUTH_BOUNDARY_COND=1 ./solve
  --estimate-knuth 2000000000`
- Budgeted counts as lower bounds: [documentation/CRITIQUE.md](../documentation/CRITIQUE.md) §"per-branch yield labels"; scaling
  trajectory: [documentation/SOLVE-SUMMARY.md](../documentation/SOLVE-SUMMARY.md)
- Boundary predicate: documentation/PARTITION_STABILITY_BOUNDARIES.md

*Per-cell budget figure confirmed against campaign parameters (3.536×10⁹ nodes/cell at 560T); the per-cell yield scatter was evaluated and not embedded (adds nothing to the size argument).*

## Update (v1.7): an information floor sharpens the uniqueness projection

The measured greedy chain's per-boundary information gains are strikingly flat (~10.1 bits per
boundary across all five measured steps, the first being the maximum by construction). Since
identifying King Wen in the C1–C5 space requires 126.6 bits, this gives a heuristic floor of
**k ≥ 13 boundaries** and an observed-rate projection of **≈ 13** — tightening this report's earlier
13–20 extrapolation toward its lower end. (Heuristic: unmeasured boundary synergies could beat the
single-boundary maximum, but five steps show none — gains behave as near-independent.) Full arithmetic
in SEARCH_SPACE_SIZE.md; sharpens further when S(6..8) land.


### Update (2026-07-05): the marginal-gain curve bends — S(6)-S(8) measured

Extending the greedy boundary chain three more rounds (2x10^10-probe value runs per round; certified
selection caveat below) gives S(6) = 1.879x10^20, S(7) = 7.695x10^17, S(8) = 1.093x10^16. The
per-boundary information gains are now, for k = 1..8: 10.38, 9.64, 11.10, 9.40, 10.13, 8.64, 7.93,
6.14 bits. The "flat ~10.1 bits/boundary" pattern reported in v1.7 holds through k = 5 and then
enters a clear declining tail. Consequences: (1) the heuristic PROJECTION for the number of
boundary-adjacency facts needed to isolate King Wen moves UP from ~13 to roughly 15-20; (2) the hard
floor k >= 13 (information-theoretic, from the space size) is unaffected; (3) the synergy caveat of
v1.7 resolves in the anti-synergy direction — later boundaries overlap more with what earlier ones
already say. Honesty caveats: at k >= 7 the 2x10^9-probe SELECTION sweeps are starvation-limited
(several candidates sample zero mass), so greedy CHOICE optimality is soft — each S(k) is an honest
measurement of its chosen boundary set but possibly not the minimal one, making these values upper
bounds on the greedy-optimal masses (and the bit-gains correspondingly conservative); and estimator
relative error grows with depth at fixed probe count. Evidence: reports/evidence/ (sk8 outputs) and
the private working log.

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
| v1.2 | 2026-07-04 | Figures added |
| v1.7 | 2026-07-04 | Information floor k>=13 + flat-gains observation (tightens the 13-20 projection) |
| v1.7.1 | 2026-07-04 | Correction: the 560T slice-identifying boundary set has 5 boundaries ({4, 27, 25, 21, 1}), not 4 — the earlier "4" was a survivor-counting error in the source finding (see [documentation/BOUNDARY_MINIMUM.md](../documentation/BOUNDARY_MINIMUM.md)); S(k) measurements unchanged (they condition on the first four pins as pins) |
| v1.8 | 2026-07-05 | S(6)-S(8) measured; flat-gains law bends at k=6; projection 13 -> 15-20; floor k>=13 unchanged |
