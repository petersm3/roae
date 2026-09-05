# TR-4 — The Size of the Space: Measurement, the Uniqueness Conjecture, and the Boundary-Information Curve
*Technical report — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. One caveat is structural, and it frames all the rest: the same
author wrote the claims, the software that checks them, and this report that grades the check.
Verification here is independent in mechanism, never in authorship; no independent party has yet
audited or reproduced any of it (METHODS.md §"Authorship independence").*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

How special is the King Wen sequence, really? That question needs a denominator: **how many other
arrangements satisfy the same rules?** This report measures it. The answer — about 10³⁸, a hundred
trillion trillion trillion — settles a determinism hypothesis this suite calls the Uniqueness Conjecture
(the name is ours; who held it, and in what form, is scoped honestly in
[CITATIONS.md](../documentation/CITATIONS.md#uniqueness-conjecture)) — and which was **this project's own
early working hypothesis**, so what follows is a negative result about our own starting position, not a
refutation aimed at someone else's stated claim: the known rules do **not** pin down King Wen;
they leave an astronomical family of valid alternatives, and King Wen is one member. The report also
measures how much *additional* information is needed to single King Wen out (roughly 13–20 carefully
chosen adjacency facts) and explains why earlier, smaller searches wrongly suggested near-uniqueness:
bounded search sees a biased sample. The measurement technique is validated against exact counts at
every scale where exact counts exist.

## Abstract
We measure the total number of hexagram orderings satisfying constraints C1–C5 — the number every budgeted
enumeration has only ever bounded from below — using Knuth's (1975) unbiased random-probe estimator run
over the *exact* production search tree: **1.3287×10³⁸ raw C1–C5 orderings (95% CI [1.3283,
1.3292]×10³⁸, rel. error 0.02%; ≈3.3×10³⁷ after orientation-dedup)**. ⚠ **[LABEL CORRECTED 2026-09-03 — this read "raw canonical orderings", which is self-contradictory in this corpus's own vocabulary: [SOLUTIONS_FORMAT.md](../documentation/SOLUTIONS_FORMAT.md) §Deduplication reserves *canonical* for the orientation-DEDUPLICATED object, and 1.3287×10³⁸ is the orientation-EXPLICIT (raw) count — which is why the dedup figure in the same sentence is smaller and was withdrawn separately. The estimate is unchanged; only the noun is. Same class as the TR-10 relabel (Q-321) and charged by Codex T04, tracked as Q-330(2).]** ⚠ **[WITHDRAWN 2026-08-24 — the ≈3.3×10³⁷ orientation-dedup figure in the sentence just above exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; the raw 1.3287×10³⁸ estimate is not affected and STANDS; see documentation/CORRECTIONS.md]** This is a statistical estimate, not
a proven cardinality, validated to <1% against exact subtree counts on a three-rung ladder. ⚠ **[a
56-branch cross-sum was also run at the time and is NOT offered as evidence here: its per-branch
values were not archived, and it is recorded as untraced — see the T04 row of the untraced-claims
audit. The three-rung ladder validation stands.]** Three consequences follow. First, the deepest published canonical (560T;
1.05×10¹⁰ distinct orderings) has enumerated ≈1 part in 10²⁷ of the space — exhaustion is infeasible at any
budget. ⚠ **[WITHDRAWN — the distinct-vs-distinct pairing in the sentence just above; stated raw-against-raw it is at least 1 part in 3.03×10²⁷ — see documentation/CORRECTIONS.md]** Second, extending the walk with the spec's C6/C7 adjacency constraints **refutes the
Uniqueness Conjecture** — our name for the strong determinism reading of the literature's
derivation-flavored claims, and this project's own early working hypothesis; to our knowledge no author
asserted it in exactly this form (attribution note:
[CITATIONS.md](../documentation/CITATIONS.md#uniqueness-conjecture)): ≈5.21×10³¹ orderings satisfy C1–C7; King Wen is unique only within budgeted
slices. Third, the boundary-information curve S(k) shows the first four boundaries of King Wen's 560T greedy
identifying set (the full set has five; see revision v1.8) still admit **≈8.4×10²⁵ full-space orderings** —
to our knowledge the sharpest quantification yet of the slice-uniqueness vs space-uniqueness distinction. We close with why King Wen's *early* appearance
in the enumeration is an artifact of the search setup, and why that changes no finding.

## Sections
1. **What is being measured.** The enumerations are *budgeted*: each of 158,364 depth-3 cells
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
   nodes, 16,504 vs 16,422 canonical). *(A 56-branch cross-sum was run at the same time and is deliberately
   NOT restated here: its per-branch values were never archived, so no reader can recompute it — scoped
   out 2026-08-27, see the abstract's marker, v1.22 and [CORRECTIONS.md](../documentation/CORRECTIONS.md).
   The three-rung ladder above is unaffected and is the whole of the validation claim.)*
3. **The measurement.** 5×10¹⁰ probes (definitive 100×-probe run, 2026-07-01; the earlier 5×10⁸ run gave 1.32×10³⁸
   (rel. err 0.18%), ≈2–3.7σ below the definitive value (the exact figure is rounding-dependent — ~2σ on the
   less-rounded early value, ~3.7σ if 1.32×10³⁸ is taken as exact) — an unremarkable deviation for one early draw from a
   right-skewed weight distribution, in the direction (low) such skew predicts; the 100× run supersedes it):
   C1–C5 raw (orientation-explicit) **1.3287×10³⁸** (0.02%); C1/C2/C4/C5 complete
   orderings 1.0971×10³⁹ (0.01%) — subsequently computed **exactly** at 1.097051×10³⁹ (two-instrument since 2026-07-25: independently recomputed at full scale by verify.c's IE transfer-walk engine, exact match — TR-11 §10(vi))
   ([TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md), 2026-07-16): the estimate deviated by
   0.0044%, well inside its stated envelope — the estimator's second absolute full-scale validation
   (the C1–C5 raw figure itself remains an estimate); total tree nodes 2.0875×10⁴⁰ (0.00%). This supplies the terminal count of
   the reduction funnel (64! ≈ 1.3×10⁸⁹ → C1 skeleton 32!·2³² ≈ 1.1×10⁴⁵ → ~10⁴⁰ → ≈1.3×10³⁸). Structure:
   the 56 first-level branches are roughly uniform in RAW size (min 1.26×10³⁶, median 2.26×10³⁶, max 3.46×10³⁶ raw, spread
   ≈2.7× — no small or near-exhaustible branch exists) ⚠ **[LABEL CORRECTED 2026-08-28 — published as "canonical" per-branch counts; they are raw. See SEARCH_SPACE_SIZE.md §"Result — per first-level branch" and documentation/CORRECTIONS.md]**; the 65,281 productive depth-3 cells span only 94.6×
   in total size (10³¹·⁸–10³³·⁸) while their *budgeted* yields span ≈5.7 orders (10¹·¹–10⁶·⁸), and the two
   are essentially uncorrelated (Pearson r = 0.17, Spearman ρ = 0.15, full population; confirms the earlier
   605-cell sample, r≈0.15). Budgeted yield is a local-density phenomenon, not a size phenomenon. A prior
   product-of-averages estimate (10¹⁴–10¹⁵ nodes) was a ≈25-order undercount — biased downward for
   heavy-tailed branching; unbiased probe sampling is the correct tool.
4. **The Uniqueness Conjecture is refuted (2026-07-02).** Extending the probe walk with the spec's C6/C7
   adjacency constraints (slots 24–27 pinned to King Wen's pairs, orientation free) makes the conjecture
   directly measurable: **5.21×10³¹ C1–C7-satisfying orderings** (95% CI [5.13, 5.29]×10³¹, 0.78%; without
   C3: 5.18×10³², 0.25%; pinned tree nodes 1.4539×10³⁵). C6+C7 cut the C1–C5 space by ×2.55×10⁶ — but
   ≈5.2×10³¹ survive. King Wen is not uniquely determined by the published constraint system over the full
   space; uniqueness holds only within enumerated budgeted datasets. Prior art for this direction (per
   [CITATIONS.md](../documentation/CITATIONS.md#ouyang1990) and the prior-negatives note under
   [#uniqueness-conjecture](../documentation/CITATIONS.md#uniqueness-conjecture)): the under-determination
   position itself is [Ouyang Weicheng (1990)](../documentation/CITATIONS.md#ouyang1990)'s — the sharpest
   published statement that the hexagrams have no intrinsic order and that an ordering must be imposed by
   added conditions — and [Luo Jianjin (2015)](../documentation/CITATIONS.md#luojianjin2015) posed the
   companion how-many-orderings question in a mathematics journal, expecting an answer far smaller than
   64!. Both are qualitative — neither formalized constraints nor computed a count; this measurement is
   the quantitative form of the position Ouyang articulated and, together with this report's ≈10³⁸
   estimate and [TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)'s exact integers, is, we believe,
   the first quantitative answer to Luo's question. Closing the remaining ≈105 bits would
   need roughly 15–20 boundary constraints. Exact small-scope corroboration: in the KW-following 22-pair
   prefix subtree, exact counting finds 16,504 oriented C1–C5 completions of which exactly **8** satisfy
   C6/C7 — **all eight sharing King Wen's pair ordering**. ⚠ **[CORRECTED 2026-08-28 — "plus seven others" invites a pair-ordering reading that is the OPPOSITE of what the enumeration shows. All **eight** survivors carry **King Wen's own pair ordering**; the seven "others" are orientation variants of it. The 16,504 figure is ORIENTED — it is 899 distinct pair orderings — and C6/C7 eliminate 898 of those 899, leaving King Wen's alone. Verified with the shipped binary: with the pair ordering free, C6/C7 leave 8 survivors; with every free slot additionally pinned to KW's pairs and only orientation free, the count is **also 8** (tree_nodes 1169 → 233 ⚠ **[RUN DESCRIPTION CORRECTED 2026-08-28 — first published as "tree_nodes 1169 → 233" with the words "every free slot". That run pinned slots 24–32, which leaves position 23 order-free (pins 24–31 give the identical 233, so slot 32 was a no-op); pinning all nine free steps 23–32 gives **75** nodes. The survivor count is **8** in every variant and the conclusion is unchanged — only the description of the run was wrong. Found by the D2 lens-1 executed review, which re-ran it.]** ⚠ **[REPRODUCTION COMMAND PUBLISHED 2026-08-29 (Q-395, settling Q-343) — these two figures shipped with no way to check them, while the provenance note claimed the public verification path was "re-running the published `SOLVE_KNUTH_C67` command", which was published nowhere. Both reproduce in under 10 ms with the shipped binary:

```bash
PREFIX="1 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 20 0 21 0 22 0"
ulimit -s unlimited

SOLVE_KNUTH_C67=1 ./solve --estimate-knuth 0 $PREFIX
#   tree_nodes 1169   leaves_C1C2C4C5 88   leaves_canonical_C1C5 8

SOLVE_KNUTH_C67=1 SOLVE_KNUTH_PIN_SLOTS="24,25,26,27,28,29,30,31" ./solve --estimate-knuth 0 $PREFIX
#   tree_nodes  233   leaves_C1C2C4C5  8   leaves_canonical_C1C5 8

SOLVE_KNUTH_C67=1 SOLVE_KNUTH_PIN_SLOTS="23,24,25,26,27,28,29,30,31" ./solve --estimate-knuth 0 $PREFIX
#   tree_nodes   75   — every free slot pinned
```

`--estimate-knuth 0` means **zero random probes**, i.e. exact enumeration of the subtree. It is bounded here only because the 22-pair prefix makes that subtree small; issued without the prefix the same command is an unbounded full walk, which is what an earlier reproduction attempt hit.

**The slot labels are corrected too.** `SOLVE_KNUTH_PIN_SLOTS` takes **step** numbers and accepts 1–31 (`(knuth_pin_mask >> step) & 1u`, `solve.c`), so a "slot 32" cannot be named at all — the earlier marker's "slots 24–32" is not a range the flag can express, which is why its own author found slot 32 to be "a no-op". Steps are 0-based and **position = step + 1**. After the 22-pair prefix the free steps are **23–31**, i.e. **positions 24–32**. The 233 run pins steps 24–31 = **positions 25–32**, so the slot left order-free is **position 24**, not position 23. Pinning every free step (23–31 = positions 24–32) gives **75**.

The conclusion is untouched by all of this: **8** survivors in every variant, all carrying King Wen's pair ordering.]**, a strict subtree), so no survivor departs from KW's pair sequence. At small scope this corroborates UNIQUENESS in the canonical frame, not the non-uniqueness the surrounding paragraph argues at the oriented level.]**
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
   ~15–20 boundaries** and superseding the earlier 13–14 figure; the ~12-boundary
   observed-rate extrapolation (not a bound — see v1.7 update) is unaffected. A bracketing exploration
   over the *weakest* remaining boundaries (k = 5–8) reported roughly ×15–17 per boundary — but ⚠ **that
   band is not reproducible from published material and is offered as illustration, not measurement**
   (restated 2026-09-02, v1.25). The tree ships exactly two S(k) artifacts,
   [`reports/evidence/sk/sk5_7_rounds.out`](evidence/sk/sk5_7_rounds.out) and
   [`sk8_round.out`](evidence/sk/sk8_round.out), and both are **greedy** chains (`round 5 PICK=2`,
   `round 8 PICK=5`); no weakest-remaining chain is archived, no command for one is published, and
   "the weakest remaining boundaries" is nowhere defined against a candidate set. The one public datum
   that bears on it is round 5's own selection sweep in `sk5_7_rounds.out`, whose largest-surviving
   candidate (`cand 22: est=5.797785e+24`) is a ×14.5 cut against N(4) = S(4)·1.3287×10³⁸ = 8.42×10²⁵ —
   *below* the band's floor, while its second-largest (`cand 28: est=5.123237e+24`) is ×16.4, inside it.
   Read the band as an order-of-magnitude illustration; the claim that the decay is robust to boundary
   choice rests on it and is correspondingly weak. Extending the greedy curve
   past k = 4 needs ~100× the probe budget (conditional masses starve below ~10⁻¹³ hit rates); **done
   2026-07-05, see the Update below**.
6. **Why King Wen is found "early" — an artifact, fully owned.** The enumeration is a systematic DFS, not
   random sampling: time-to-reach a known ordering depends on where it sits in traversal order, not on the
   solution-set size. King Wen's early appearance is produced by three setup choices — the constraints
   (reverse-engineered *from* KW, guaranteeing membership, not early arrival), the per-cell decomposition
   (guaranteeing breadth), and the variable/value ordering (placing KW's one leaf inside its cell's ~3.5
   B-node budgeted frontier, out of ~10³³ leaves) — and an adversarial choice on any of them could delay or
   miss it at a fixed budget. This changes no finding: KW is a known input verified in microseconds (**measured 2026-08-24: median 19.6 µs**, min 18.9, p95 21.4, over 2,000 runs of the full C1 + C2/C5-multiset + C3 check in `verify.py` on a 2-vCPU D2as_v6); all
   claims are relative comparisons over the enumerated set with KW held known; membership is
   order-invariant. The ≈10³⁸ estimate shows KW is **not special by being rare or hard to find** — its
   distinction is purely structural, which is exactly why the project's claims are about where KW sits in
   the distribution, never about combinatorial uniqueness.

## Estimator calibration against exact ground truth (v1.11, 2026-07-20; third anchor added v1.25, 2026-09-02)

The estimator's error bars were, until 2026, self-reported: an internal variance estimate with no
external check at full scale. Two constraint layers have since been computed **exactly** by the
symmetry-quotient DP ([TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)), which turns those layers
into ground truth against which the estimator can be scored. Consolidated here, since the comparison was
previously scattered across two documents:

| Layer | Exact value | Prior Knuth estimate | est/exact | Deviation | Inside its stated envelope? |
|---|---|---|---|---|---|
| C1∩C2∩C4 | 757,058,601,340,255,440,651,419,713,405,330,315,358,208 (7.570586×10⁴¹) | 7.571×10⁴¹ ±0.01% | 1.0000547 | **+5.47×10⁻⁵** | yes |
| C1∩C2∩C4∩C5 | 1,097,051,278,789,181,790,036,112,071,176,579,186,688 (1.097051×10³⁹) | 1.0971×10³⁹ ±0.01% | 1.0000444 | **+4.44×10⁻⁵** | yes |
| C1∩C2∩C4∩C5∩C6∩C7 (C3 dropped; C6/C7 pinned; raw, orientation-explicit like the two rows above) | 516,880,238,445,773,965,371,923,491,676,160 (5.16880×10³²) | 5.18×10³² ±0.25% (§4) | 1.002166 | **+2.166×10⁻³** | yes |
| C1–C5 (adds C3) | *none — no exact value exists* | 1.3287×10³⁸ | — | — | **uncalibrated** |

**Coverage: 3 of 3.** At all three layers where ground truth exists, the exact value falls inside the
estimator's stated envelope — with roughly half the claimed error budget to spare at the two ±0.01%
layers, and about 87% of it consumed at the ±0.25% pinned layer. This is the first
external validation of the estimator at full scale, and it is the substantive result of this section.

**The third row, added 2026-09-02 (v1.25).** The C6/C7-pinned, C3-free layer was computed **exactly**
on 2026-07-25/26 and is recorded at [METHODS.md](METHODS.md) §"Canonical quantities (single source of
truth)" as a *3rd independent estimator-calibration anchor*; this section had not been updated and still said 2 of 2. It is
two-instrument: an inclusion–exclusion pinned-step recount and an independent mask-DP recount of a
different algorithm class, which agree on the integer. **Reproduce:**
`gcc -O3 -pthread -o verify verify.c -lm -lz`, then
`./verify --ie-count --ie-spec full31@0 --ie-pin-c6c7 --ie-no-quotient` (Route B) and
`./verify --dp-count --dp-spec full31@0 --dp-pin-c6c7` (Route D); the estimate it scores,
5.18×10³² ±0.25%, is §4's. This is the **only** calibration point on the C6/C7-pinned estimator
path — the path carrying the ≈5.21×10³¹ uniqueness-refutation figure, and the one with the fewest
cross-checks.

**What this does NOT establish, stated explicitly because the numbers invite the stronger reading.**
All three deviations happen to be positive, which looks like a small systematic upward
bias. **That inference is not available from these figures.** For the two ±0.01% layers the published
estimates are quoted to four and five significant figures, giving rounding granularities of ≈6.6×10⁻⁵
and ≈4.6×10⁻⁵ — *the same order as the deviations being measured* — so their apparent common sign is
not distinguishable from quoting precision. The third anchor is a different case and is stated as one:
5.18×10³² is quoted to three significant figures, a granularity of ≈9.7×10⁻⁴, and its +2.17×10⁻³
deviation is about 2.2× that, so it survives rounding and is a real signed deviation — but it is a
single point in that regime, still inside its stated envelope, and one point is not a bias estimate.
No bias direction or magnitude is claimed here. Recovering the unrounded estimator
outputs from the original run records would be required before any bias statement could be made.

**Three points are consistency, not an error model.** With n=3 we can say the estimator's envelope has held
wherever it has been checkable; we cannot fit an error distribution, and nothing here licenses
extrapolating a tightened error bar to the uncalibrated C3 layer — a point the third anchor **sharpens
rather than softens**, because it too is C3-free, so all three anchors leave C3's conditional ratio the
one full-scale factor with no exact cross-check (the same gap the clean-room
`./verify --knuth-probe` estimator was built to attack — see
[VERIFY.md](../documentation/VERIFY.md), which states it in as many words: "every existing full-scale
cross-check is C3-free by scope"). The honest summary is that the
flagship 1.3287×10³⁸ retains its stated CI on the estimator's own terms, now with the reassurance that
the same machinery was accurate to <10⁻⁴ at two independent layers and to 2.2×10⁻³ at a third, the
three spanning nine orders of magnitude (10⁴¹ → 10³²).

**What would upgrade this to a genuine error model.** More calibration points, which means exact counts
at more layers or at reduced instances. The reduced-rung ladder published in
[TR-11 §4b](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) supplies nine additional exact values, but they
are not usable as calibration points today: `--estimate-knuth` scopes to a *prefix* of the full 31-pair
tree, not to a group-closed pair subset, and it targets C1–C5 (C3 included) whereas the exact rungs are
C1∩C2∩C4∩C5. Closing that gap needs both a subset-capable estimator path and a resolution of the
constraint-scope mismatch; it is recorded as a future task rather than attempted here.

## Status and provenance caveat
All quantities here are Monte-Carlo estimates on the exploration track. They do not change, and are not
gated by, any canonical sha256. No "proven" claim is made about exact cardinality — only that it is ≈10³⁸
to within the stated sampling error. Method attribution: Knuth (1975). Constraint provenance and prior
literature: [CITATIONS.md](../documentation/CITATIONS.md).

## Figure

![Log-scale decay curve of S(k), the fraction of the full C1–C5 population agreeing with King Wen on its first k identifying boundaries: four measured points falling from 7.49e-4 at k=1 to 6.34e-13 at k=4, a dashed extrapolation at the ~×1000-per-boundary greedy cut, an orange illustrative bracket for the weakest remaining boundaries (×15–17 per boundary, k=5–8; not reproducible from published material), and a shaded band at k≈13–20 where extrapolation reaches full-space uniqueness.](figures/fig_tr4_boundary_information.png)

*The boundary-information curve S(k) (§5). Red points are the measured pinned-Knuth values on the first
four boundaries of the 560T greedy identifying order {4, 27, 25, 21, 1}, annotated with the
surviving-orderings counts — those k = 4 boundaries (which inside the 560T slice leave KW plus one
impostor; the full identifying set has 5 boundaries) still admit ≈8.4×10²⁵ full-space
orderings. The dashed line extrapolates the roughly constant ~×10³ per-boundary cut (NOT measured); the
orange band is an **illustrative** weakest-remaining-boundary bracket (×15–17 per boundary at k = 5–8)
whose chain outputs are not archived and which is not reproducible from published material — see §5;
it indicates rather than bounds how much the decay depends on boundary choice. The green band marks where extrapolation
reaches one surviving ordering: ~15–20 boundaries (revised up from an earlier ~13–14 estimate by the
2026-07-05 S(6)–S(8) measurement; wide error; observed-rate extrapolation ~12, not a bound).
Generated by [`viz/report_figures.py`](../viz/report_figures.py);
[SVG](figures/fig_tr4_boundary_information.svg).*

## Verification Guide
⚠ **Every `--estimate-knuth` command below requires a stack limit of at least 16 MB** — `ulimit -s 16384` suffices, and `ulimit -s unlimited` is one way to satisfy it, not the requirement itself. Under the default 8 MB stack the estimator does not start: `main` allocates a ~7.23 MB frame and `estimate_tree_knuth` a further ~1.02 MB, so the 8 MB limit is exceeded the moment the estimator would be entered (since 2026-08-21 the binary preflights `RLIMIT_STACK`, refuses to start with an actionable message naming the >= 16 MB it needs, and exits 1; previously a bare SIGSEGV). This is environmental, not a logic fault — with the limit raised the published figures reproduce. *(Added 2026-08-21: found by a cold external-reviewer pass and independently reproduced; the requirement had been documented only in CANONICAL_HASHES.md's large-scale-enumeration recipe, while these guides state the estimator needs no data disk and costs pennies.)* *(Corrected 2026-09-01: the failure mode was previously described as a segfault before any output, telling an operator to expect exit 139 from a binary that has exited 1 with a diagnostic since 2026-08-21. `solve.c`'s `--estimate-knuth` parse block preflights `RLIMIT_STACK` and, below 16 MB, prints "solve: stack limit is %lu MB, but --estimate-knuth needs >= 16 MB ... Re-run with: ulimit -s unlimited" and returns 1; its own comment records "previously a bare SIGSEGV after the banner". That pass corrected the failure MODE only; the requirement itself is narrowed in the note below.)* *(Narrowed 2026-09-02, Codex V2-F08 #4, prose batch P37: `ulimit -s unlimited` is a **sufficient** setting that had been published as a **necessary** one — and one that a host or container with a hard stack cap cannot even apply, so the published requirement was a false blocker there. `solve.c`'s `--estimate-knuth` preflight tests `rlim_cur != RLIM_INFINITY && rlim_cur < 16UL*1024*1024` and its message names ">= 16 MB". EXECUTED under TR-9 v1.24 on a locally built binary: `ulimit -s 8192` refuses and exits 1, `ulimit -s 16384` runs the estimator to completion. `solve.c`'s own remedy line still prescribes only `unlimited` and is queued to offer both. This is the sibling propagation of the narrowing TR-9 made on 2026-09-02 and reported but did not sweep.)*
- Estimator implementation + exact-count mode: `gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz`, then
  `solve --estimate-knuth 500000000` (whole tree; 5×10⁸ probes ≈ 79 s on a many-core host, pennies of
  compute — ⚠ **the 79 s figure carries no recorded core count and is not reproducible as stated**: the
  estimator is thread-parallel and prints its thread count in its own `[knuth] N probes, T threads`
  banner, so wall time scales with the host. On a 2-core machine the same command takes tens of
  minutes. Corrected 2026-08-21 — a published timing without its hardware basis);
  `solve --estimate-knuth 100000000 <p1> <o1>` (one branch); `solve --estimate-knuth 0 <prefix>` (exact
  validation ladder). No data disk required. ⚠ **[Corrected 2026-09-02: the 5×10⁸ whole-tree command
  reproduces the SUPERSEDED early run — 1.32×10³⁸ at rel. err 0.18% — not this report's headline
  1.3287×10³⁸ / 0.02%, which
  [SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md) §"Result — the whole C1–C5 tree"
  attributes to the 5×10¹⁰-probe definitive run of 2026-07-01 and records as superseding the 5×10⁸ draw.
  No 5×10¹⁰ whole-tree invocation appears anywhere in the tracked corpus and `reports/evidence/` holds no
  stdout at that probe count, so the headline estimate has no published reproduction command; publishing
  the 5×10¹⁰ invocation with its thread count and archived stdout is the open fix.]** ⚠ **[CLOSED 2026-09-02
  (code batch V-1, Codex V2-19 #3): the whole-tree headline invocation is `SOLVE_THREADS=32 ./solve
  --estimate-knuth 50000000000` — 5×10¹⁰ probes, 32 threads (the estimator is deterministic at fixed
  (probes, threads, seed)); archived stdout [evidence/knuth_whole_tree_5e10.out](evidence/knuth_whole_tree_5e10.out)
  reproduces the headline digit-for-digit (1.328729×10³⁸, 95% CI [1.3283, 1.3292]×10³⁸, rel. err 0.02%;
  18,230 s wall on 32 threads). That stdout is the 2026-07-26 same-seed re-run: the 2026-07-01 original's
  stdout was never archived, and the re-run is byte-identical in every reported figure.]**
- Full write-up, tables, per-cell distribution: [documentation/SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md)
- Uniqueness-conjecture refutation: `SOLVE_KNUTH_C67=1 SOLVE_THREADS=32 ./solve --estimate-knuth 50000000000`
  (5×10¹⁰ probes, 32 threads, ≈2 h 04 min wall on a 32-vCPU host; SEARCH_SPACE_SIZE.md §"The C1–C7
  space"); archived stdout [evidence/c67_probe.out](evidence/c67_probe.out) (2026-07-02; 5×10⁸ pilot then
  the 5×10¹⁰ run — matches the published table digit-for-digit). ⚠ **[CORRECTED 2026-09-02 (Codex V2-19
  #3): this bullet previously printed the command with an ellipsis where the probe count belongs, and
  pointed at a private run log. Executed as printed, the ellipsis parses to zero probes, which selects
  whole-tree EXACT enumeration — an unbounded walk that produced no output in 25 s of wall time (rc 124
  under `timeout`), while the real command prints its banner at once.]**
- S(k) curve: `SOLVE_KNUTH_PIN_SLOTS="3,4,26,27,24,25,20,21" SOLVE_KNUTH_BOUNDARY_COND=1 ./solve
  --estimate-knuth 2000000000` ⚠ **[THREAD PIN MISSING — 2026-09-03 sibling sweep. Per [METHODS](METHODS.md) §"Reproducibility rule for estimator output", the Knuth estimator's seeds are fixed constants and **the thread count selects the sample**, so a re-run reproduces a published figure only at the identical (probes, threads) pair. This command carries no `SOLVE_THREADS=N`, and the thread count used for the published number is not recorded anywhere in the corpus — so it is **not reproducible exactly as stated**; a reader on a different core count gets a different draw, not this one. The two 5×10¹⁰ invocations were pinned by code batch V-1 (Codex V2-19 #3); these sampled siblings in the same files were not. Note this is a REPRODUCIBILITY defect, not the performance caveat recorded nearby: thread count changes the estimate, not merely the wall time.]**
- Budgeted counts as lower bounds: [documentation/CRITIQUE.md](../documentation/CRITIQUE.md) §"per-branch yield labels"; scaling
  trajectory: [documentation/SOLVE_SUMMARY.md](../documentation/SOLVE_SUMMARY.md)
- Boundary predicate: documentation/PARTITION_STABILITY_BOUNDARIES.md

*Per-cell budget figure confirmed against campaign parameters (3.536×10⁹ nodes/cell at 560T); the per-cell yield scatter was evaluated and not embedded (adds nothing to the size argument).*

## Update (v1.7): an information-rate extrapolation sharpens the uniqueness projection

> **Label corrected 2026-08-01.** This section was headed "an information floor" and its result was
> stated as a floor (first "hard", then "heuristic"). **It is neither.** A floor is a lower bound on k;
> deriving one requires the maximum single-boundary information gain over *all* boundaries and *all*
> conditioning contexts, and five samples along one greedy path bound no such supremum. What follows is
> an **extrapolation from the observed rate** — informative about scale, binding on nothing. The word
> "floor" has been removed rather than qualified, because a caveated bound still reads as a bound.

The measured greedy chain's per-boundary information gains are strikingly flat (~10.1 bits per
boundary across all five measured steps, the first being the maximum of the **unconditional** gain by
construction — greedy picks it first — and nothing more: the greedy construction bounds no *conditional*
gain, and the k = 3 step's 11.10 bits exceeds it). Since
identifying King Wen in the C1–C5 space requires 126.6 bits, dividing through gives
an observed-rate extrapolation of **~12 boundaries** (explicitly NOT a lower bound — see v1.15) and a projection of **≈ 13** — tightening this report's earlier
13–20 extrapolation toward its lower end. (Heuristic: boundary synergies can beat the *unconditional*
single-boundary maximum, and the measured chain already does — the k = 3 gain of 11.10 bits exceeds the
k = 1 gain of 10.38, which is exactly why 11.10 is the divisor above. What the five steps show is that
the gains stay within about 1 bit of each other, not that no synergy exists.) Full arithmetic
in SEARCH_SPACE_SIZE.md; sharpened by the 2026-07-05 S(6)–S(8) measurement below.

*Population context (added 2026-09-05).* That 126.6-bit numerator is the size of the extracted space, not a property of King Wen: at the C5 layer a random C1∩C2 ordering's own extracted multiset leaves a space of the same size — King Wen's exact |C1∩C2∩C4∩C5| sits at the 65th percentile of 1,000 decoys, each counted under its own multiset ([TR-9](TR9_PRICING_THE_CONSTRAINTS.md) §2 population context and its Verification Guide, which carry the command and the raw output) — so the boundary count prices what it costs to identify *any* member of such a space. Two parts of the arithmetic remain King Wen-measured only: the 3.0-bit C3 cut inside 126.6 has no decoy measurement, and the per-boundary rate in the denominator is King Wen's own greedy chain, never measured for another target.


### Update (2026-07-05): the marginal-gain curve bends — S(6)-S(8) measured

Extending the greedy boundary chain three more rounds (2x10^10-probe value runs per round; certified
selection caveat below) gives survivor COUNTS N(6) = 1.879x10^20, N(7) = 7.695x10^17, N(8) = 1.093x10^16 *(notation corrected 2026-08-01: these are absolute survivor counts, not values of S(k) — S(k) is defined in this section as a FRACTION of the C1–C5 population, e.g. S(4) = 6.34x10^-13. Divide by 1.3287x10^38 for the corresponding fractions.)* ⚠ **[EVIDENCE GAP STATED 2026-09-03 — two of these three counts are recoverable from committed logs and N(7) is not.** `reports/evidence/sk/sk5_7_rounds.out` stops at round 6; its last line is `S(6)=1.879066e20 PICK=30 marginal=8.64bits`. `sk8_round.out` carries the round-8 selection sweep and `round 8 PICK=5 VALUE est=1.092786e+16 pins=3,4,26,27,24,25,20,21,1,2,29,30,11,12,4,5`, whose 16-entry pin list makes the round-7 PICK (pair 11,12) recoverable. **But no committed artifact carries the round-7 VALUE run:** `grep -l 7.695 reports/evidence/sk/*.out` returns nothing, and `grep -oh 'round [0-9]' reports/evidence/sk/*.out | sort -u` yields rounds 5, 6 and 8 only (those two files are the whole of `reports/evidence/sk/`). So N(7) = 7.695x10^17 is reported here without a public artifact behind it, and the k = 7 and k = 8 per-boundary gains below (7.93 and 6.14 bits) are BOTH computed from it — they are the only two entries in that list that are not independently checkable against a shipped log. The value is not withdrawn: N(6) and N(8) are archived, the chain that produced N(7) is identified, and nothing else in this report depends on it. Charged by Codex T04, tracked as Q-330(3). Measured 2026-09-03.]**. The
per-boundary information gains are now, for k = 1..8: 10.38, 9.64, 11.10, 9.40, 10.13, 8.64, 7.93,
6.14 bits. The "flat ~10.1 bits/boundary" pattern reported in v1.7 holds through k = 5 and then
enters a clear declining tail. Consequences: (1) the heuristic PROJECTION for the number of
boundary-adjacency facts needed to isolate King Wen moves UP from ~13 to roughly 15-20; (2) the
observed-rate extrapolation of ~12 boundaries is unaffected *(wording corrected 2026-08-09: this
read "the heuristic floor k >= 12", a survivor of the pre-v1.16 label. The v1.16 note 19 lines
above states the result was stated as a floor "first 'hard', then 'heuristic'" and that **it is
neither**, and that the word was removed rather than qualified — so this line contradicted its own
document)*; (3) the synergy caveat of
v1.7 resolves in the anti-synergy direction — later boundaries overlap more with what earlier ones
already say. Honesty caveats: at k >= 7 the 2x10^9-probe SELECTION sweeps are starvation-limited
(several candidates sample zero mass), so greedy CHOICE optimality is soft — each S(k) is an honest
measurement of its chosen boundary set but possibly not the minimal one, making these values upper
bounds on the greedy-optimal masses (and the bit-gains correspondingly conservative); and estimator
relative error grows with depth at fixed probe count. Evidence: reports/evidence/ (sk8 outputs) and
the private working log (not publicly accessible — the public evidence is the `reports/evidence/`
outputs; the private log adds working narrative, and this report rests no claim on it).

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
| v1.2 | 2026-07-04 | Figures added |
| v1.7 | 2026-07-04 | Information floor k>=13 + flat-gains observation (tightens the 13-20 projection) |
| v1.7.1 | 2026-07-04 | Correction: the 560T slice-identifying boundary set has 5 boundaries ({4, 27, 25, 21, 1}), not 4 — the earlier "4" was a survivor-counting error in the source finding (see [documentation/BOUNDARY_MINIMUM.md](../documentation/BOUNDARY_MINIMUM.md)); S(k) measurements unchanged (they condition on the first four pins as pins) |
| v1.8 | 2026-07-05 | S(6)-S(8) measured; flat-gains law bends at k=6; projection 13 -> 15-20; floor k>=13 unchanged |
| v1.9 | 2026-07-11 | Attribution honesty on the "Uniqueness Conjecture": named as ours — the strong determinism reading of the literature's derivation-flavored claims plus this project's own early working hypothesis; "long-standing"/"folk conjecture (multiple authors)" framing retired; anchored attribution note added to CITATIONS.md. The refutation's content (≈5.21×10³¹ C1–C7 survivors) unchanged |
| v1.10 | 2026-07-16 | The C1/C2/C4/C5 layer figure (1.0971×10³⁹, stated ±0.01%) validated absolutely: [TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)'s exact count 1.097051×10³⁹ shows a 0.0044% deviation, well inside the stated envelope (§3 annotated). The headline C1–C5 figure 1.3287×10³⁸ remains a statistical estimate; no other numbers change |
| v1.11 | 2026-07-20 | **Estimator calibrated against exact ground truth (foothold F14).** The two constraint layers now computed exactly by the TR-11 symmetry-quotient DP are consolidated into a per-layer exact-vs-estimate table: |C1∩C2∩C4| (est/exact 1.0000547, +5.47e-5) and |C1∩C2∩C4∩C5| (1.0000444, +4.44e-5). Coverage 2/2 — at both layers where ground truth exists the exact value falls inside the stated ±0.01% envelope with about half the error budget unused, the estimator's first external validation at full scale. Explicitly NOT claimed: the two deviations share a sign, but the published estimates are quoted to 4-5 significant figures whose rounding granularity (~6.6e-5, ~4.6e-5) is the same order as the deviations, so no bias direction or magnitude is inferable without the unrounded run outputs; and n=2 is consistency, not an error model, so no tightened bar is extrapolated to the uncalibrated C3 layer. Records why the nine exact reduced rungs of TR-11 §4b are not yet usable as extra calibration points (--estimate-knuth scopes to a prefix of the full tree, not a group-closed pair subset, and targets C1-C5 rather than C1∩C2∩C4∩C5). No estimate, CI, or published figure changed |
| v1.12 | 2026-07-20 | **Single-instrument tag (adversarial-review F-2c).** §3's "subsequently computed **exactly**" for the C5 layer now reads "exactly (single-instrument)": the count is mod-24- and ladder-corroborated but has not been independently recomputed at full scale, per TR-11 §10(vi). Downstream labels should not read stronger than TR-11's own hedge. No value changed |
| v1.13 | 2026-07-30 | **Revision-history repair — a silent body edit given its missing row (novelty-gate audit #11).** After v1.12, §3's C5-layer tag was updated in place from "exactly (single-instrument)" to "exactly … (two-instrument since 2026-07-25: independent full-scale recomputation by `verify.c`'s IE transfer-walk engine, exact match — TR-11 §10(vi))" without a revision-history entry, violating this suite's no-silent-edit rule. This row records that edit after the fact: the v1.12 single-instrument caveat is superseded by the 2026-07-25 measurement (TR-11 v1.11/v1.12); the body text was already correct and is unchanged today. No value changed |
| v1.14 | 2026-08-01 | **Notation correction (cross-model calibration review).** The 2026-07-05 update quoted "S(6) = 1.879×10²⁰, S(7) = 7.695×10¹⁷, S(8) = 1.093×10¹⁶" under a symbol §5 defines as a **fraction** of the C1–C5 population (S(4) = 6.34×10⁻¹³) — values greater than 1 by twenty orders of magnitude. They are absolute **survivor counts**, and are re-labelled N(k); the reader is pointed at the division by 1.3287×10³⁸ for the corresponding fractions. Verified against the section's own per-boundary bit-gains (126.64 − Σgains(1..8) = 53.28 bits ⇒ 2⁵³·²⁸ = 1.09×10¹⁶, matching N(8)). No measurement or conclusion changed — the numbers were right, the symbol was wrong |
| v1.15 | 2026-08-01 | **The k≥13 boundary floor is relabelled HEURISTIC — the "hard information-theoretic" claim is withdrawn.** Two defects, both established from already-published data (no new computation). (i) The derivation divides 126.6 bits by 10.38, asserting that is "the maximum single-boundary gain **by construction**" — true only of the FIRST, UNCONDITIONAL gain (greedy maximises it over the whole space). The section's own k=3 datum is **11.10 bits**, conditional on boundaries {4,27}: conditioning can increase information, and the greedy construction bounds no conditional gain. Using the actual observed maximum gives ⌈126.6/11.10⌉ = **12**. (ii) More fundamentally, **no necessity bound follows from this argument at all**: the quantity required is a supremum over all boundaries AND all conditioning contexts, which five samples along one greedy path cannot bound; and no counting/pigeonhole argument rescues it, because isolating King Wen requires only **KW's own cell** to be a singleton, not a separating system. The claim is therefore an **observed-rate extrapolation**, and is now labelled as such in all sites here and in SEARCH_SPACE_SIZE (which previously called it "heuristic, not a theorem" — the two labels had been applied to the same number). The slice-scale boundary-minimum results (4→5) are unaffected. Found by the 2026-08-01 cross-model calibration review |
| v1.16 | 2026-08-01 | **The "floor" label is removed, not re-qualified — the argument bounds nothing.** v1.15 relabelled the k≥13 "hard information-theoretic floor" as heuristic and corrected the divisor to 11.10 (giving 12). A second adversarial pass found that insufficient in two ways. (i) **Incomplete propagation:** §5's own body still read "the hard floor k >= 13 (information-theoretic, from the space size) is unaffected", and `CLAIMS_DECIDED.md` still published "hard floor >=13" — while v1.15's entry asserted the relabel had reached "all sites here". That assertion was false, making this the fifth instance of the recorded-but-unperformed-propagation defect, and the first one committed *inside* a batch fixing that very class. (ii) **The relabel did not go far enough:** v1.15's own point (ii) states that no necessity bound follows from the argument at all — the required quantity is a supremum over all boundaries AND all conditioning contexts, which five samples along one greedy path cannot bound — yet the body still asserted "at least N boundaries are needed" and the section was still titled "an information floor". A bound with a caveat still reads as a bound. The word **floor is now removed** from the section heading, the body and every cross-reference; the quantity is stated as an **observed-rate extrapolation (~12)**, explicitly binding nothing. Establishing a genuine floor would require measuring conditional gains across many boundary subsets — a measurement programme, not an editorial fix, and not currently warranted. No count, certificate or canonical value is affected. |
| v1.17 | 2026-08-02 | **Revision-table order repaired (doc_gates GATE 12, hardening item A4).** v1.16 was added by replacing the v1.15 line and re-adding v1.15 underneath (`7f83437`), so the newest row sat ABOVE the row it superseded and `*(current)*` was not the last row of the table. The two rows are restored to chronological order with their text unchanged; no claim, figure, date or scope was altered. The date leg of the new gate could not see this one — both rows read 2026-08-01, because `a15c6dd` had already corrected v1.16's future-dated 2026-08-02 stamp — so it was caught by the version-order and current-is-last legs instead. The same prepend mistake was live in TR-8 (repaired there as v1.12) |
| v1.18 | 2026-08-06 | **Naming fix (GATE 18 alias-reach, task #146; "exhaustive" corrected to "budgeted" per the 2026-08-01 ruling, CITATIONS.md §"What is original to ROAE" item 3).** §1's "The exhaustive enumerations are *budgeted*" now reads "The enumerations are *budgeted*" — the actual runs are budgeted, not exhaustive, and the old sentence stated both at once (same self-contradiction as SEARCH_SPACE_SIZE.md §"What is being measured", fixed in the same pass). No measurement, estimate, or conclusion changed |
| v1.19 | 2026-08-06 | **Prior-art credits added + one unhedged superlative hedged (UNASKED-1 under-citation batch; no number changed).** (1) §4 now credits the two prior-art sources for the under-determination direction this report measures, per CITATIONS.md's prior-negatives note (#uniqueness-conjecture) and its priority-ceded section: [Ouyang Weicheng (1990)](../documentation/CITATIONS.md#ouyang1990) — the sharpest published under-determination position (no intrinsic order; an ordering must be imposed by added conditions), of which the ≈5.2×10³¹ C1–C7 survivor measurement is the quantitative form — and [Luo Jianjin (2015)](../documentation/CITATIONS.md#luojianjin2015), who posed the how-many-orderings question this report's ≈10³⁸ estimate (with TR-11's exact integers) is, we believe, the first quantitative answer to. TR-11's novelty note had carried the Luo credit since its v1.13; this report, which owns the measurements, had cited neither source. (2) The abstract's "the sharpest quantification yet of the slice-uniqueness vs space-uniqueness distinction" — an unhedged cross-literature superlative in a corpus whose CITATIONS grades every originality claim tentative — now reads "to our knowledge the sharpest quantification yet". No measurement, estimate, CI, or conclusion changed — citations and hedging only |
| v1.20 | 2026-08-21 | **Access boundary stated at the two private-material citations (Q28 access-boundary pass; wording only).** The Verification Guide's uniqueness-refutation bullet and §5's evidence note both cited roae-private working logs without saying the repository is not publicly accessible; both now state the boundary and that this report rests no claim on the private material (the public path is the published command / the `reports/evidence/` outputs). Follows the precedent of VERIFY.md `e4f3d1c7`. No measurement, estimate, CI, or conclusion changed |
| v1.21 | 2026-08-27 | **The 2026-08-24 withdrawal marker now NAMES ITS TARGET and sits beside it (Q-140).** It stood immediately after the word "not" in "This is a statistical estimate, not … a proven cardinality", splicing that sentence and leading every reader to attach the retraction to the headline **1.3287×10³⁸**. Arithmetic settles which figure it retracts: 3.3×10³⁷ ÷ 8.2228×10³³ = **4,013**, exactly the factor the marker cites, while raw ÷ ceiling = 16,159. The withdrawn quantity is the **orientation-deduplicated ≈3.3×10³⁷**; the raw estimate stands, and CORRECTIONS.md already said so. Wording and placement only — no figure changes. |
| v1.22 | 2026-08-27 | **The 56-branch cross-sum is scoped out of the validation claim (Q-183/Q-65).** The sentence read "validated to <1% against exact subtree counts on a three-rung ladder plus an independent 56-branch cross-sum". The cross-sum's per-branch values were never archived — the untraced-claims audit records it as **NOT FOUND** — so it cannot be offered as evidence, and an unreproducible cross-check strengthens nothing. The three-rung ladder validation is unaffected and stands. No figure changes. |
| v1.23 | 2026-09-01 | **Stale `--estimate-knuth` stack-failure mode corrected (prose batch P48; wording only).** The stack warning preceding the reproduction commands described the default-8 MB-stack failure as a segfault before any output. That has been false since 2026-08-21: `solve.c`'s `--estimate-knuth` parse block preflights `RLIMIT_STACK` and, below 16 MB, prints the required stack size with a `ulimit -s unlimited` remedy and returns 1. An operator told to expect a segfault would read the clean exit 1 as a different fault entirely. The clause now matches the nine sibling documents that already carried the corrected wording, and keeps the segfault as dated past behaviour rather than deleting it. The `ulimit -s unlimited` requirement and the >= 16 MB figure are unchanged and remain mandatory; no claim, figure, count, date or scope altered |
| v1.24 | 2026-09-02 | **Two claims narrowed to what the evidence supports (prose batch P67; wording only, no figure recomputed).** (i) *The coverage figure is a bound, not an approximate equality.* §Abstract's raw-against-raw correction marker stated the 560T canonical's coverage as an approximate equality rather than as a bound. Its numerator, 43,876,464,466, counts per-sub-branch **canonical** keys, which [CORRECTIONS.md](../documentation/CORRECTIONS.md) records is a **lower bound** on raw oriented leaves and "never the quantity itself"; a lower-bounded numerator over the raw estimate yields a lower-bounded fraction. Re-derived here: 43,876,464,466 ÷ 1.3287×10³⁸ = 3.3022×10⁻²⁸ = 1 part in 3.0283×10²⁷, and the estimate's own 95% CI moves that only across 3.0274–3.0294×10²⁷ — all rounding to 3.03, so the stated three figures survive the change of claim. Now reads **at least** 1 part in 3.03×10²⁷. Four sibling sites outside this report's scope carry the same wording and are reported, not touched. (ii) *The reproduction command does not reproduce the headline.* §Verification Guide published `--estimate-knuth 500000000` beside a report whose headline is the 5×10¹⁰-probe definitive run; SEARCH_SPACE_SIZE.md's own results section records the 5×10⁸ draw as **superseded** by it. Verified here that no 5×10¹⁰ whole-tree invocation exists anywhere in the tracked corpus and that `reports/evidence/` archives KNUTH-ESTIMATE stdout at 2×10⁹, 5×10⁹, 2×10¹⁰, 4×10¹⁰ and 5.5×10¹⁰ probes but **none** at 5×10¹⁰. The command is now labelled as reproducing the superseded figure, with the missing invocation named as the open fix. The command itself, the 1.3287×10³⁸ estimate, its CI and every count are unchanged |
| v1.25 | 2026-09-02 | **Five claims corrected against their own evidence (prose batch P34, Codex V2-F06; no measurement re-run).** (i) *The withdrawn 56-branch cross-sum was still live in the body.* §Sections item 2 published it as an "independent cross-check" three lines after the abstract's own marker scoped it out (v1.22) for having no archived per-branch values. Removed here, and at the two sibling sites the withdrawal had not reached — [SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md) §Validation (whose "(below)" points at three order statistics from which no sum is recoverable) and [HISTORY.md](../documentation/HISTORY.md), where the dated narrative keeps the sentence under a scope-out marker. Registered as RP-3338fb66. (ii) *A premise the section's own data falsifies.* §5's information-gain paragraph called the k = 1 gain "the maximum by construction" and said "five steps show none" of the synergy that could beat it; the k = 1..8 gains printed twelve lines below include **11.10 bits at k = 3**, exceeding k = 1's 10.38. Greedy maximises the UNCONDITIONAL gain only and bounds no conditional one — exactly v1.15's finding, whose propagation stopped short of these two sentences. Both restated; the identical claim in SEARCH_SPACE_SIZE.md's extrapolation bullet, which contradicted its own 11.10 divisor, is corrected in the same pass. Registered as RP-7ec28c39 / RP-0fa05509 / RP-fa6c3b89. (iii) *A "measured" band with no measurement behind it.* The ×15–17 weakest-remaining-boundary bracket was published as measured at three sites here, one in SEARCH_SPACE_SIZE.md and two literals in `viz/report_figures.py`. The tree ships two S(k) artifacts, `reports/evidence/sk/sk5_7_rounds.out` and `sk8_round.out`, and **both are greedy chains**; no weakest-remaining chain, no command for one, and no definition of "weakest" is published. All five sites now read *illustrative, not reproducible from published material*, the figure legend with them (regenerated; PNG otherwise byte-identical), and §5 now names the one public datum that bears on the band — round 5's own sweep, whose largest-surviving candidate is a ×14.5 cut, below the band's floor. The band's numbers are unchanged; only their status is. Registered as RP-77441d0d / RP-540f6cab / RP-51313d1a. (iv) *Stale calibration coverage.* "Coverage: 2 of 2" and "With n=2" predate the C1–C7-minus-C3 layer becoming exact on 2026-07-25/26, which [METHODS.md](METHODS.md) already labels a 3rd independent estimator-calibration anchor. Added as a fourth table row with its exact integer, est/exact = 1.002166 against this report's own §4 estimate of 5.18×10³² ±0.25% (inside, at ~87% of the budget) and both `verify` reproduction commands; coverage is now 3 of 3, n = 3, and the table's envelope column is per-row rather than a blanket ±0.01%. Stated with it: the new anchor is the ONLY calibration on the C6/C7-pinned path, and being itself C3-free it sharpens rather than softens the C3 caveat. The section's rounding-granularity paragraph, which argued the deviations' common sign was indistinguishable from quoting precision, is rescoped in the same edit: that argument holds for the two ±0.01% layers and NOT for the third, whose +2.17×10⁻³ deviation is ~2.2× the ≈9.7×10⁻⁴ granularity of a three-significant-figure quote. It is a real signed deviation, inside its envelope, and n = 1 in that regime — so still no bias claim. (v) *Completed work described as pending.* "queued" and "sharpens further when S(6..8) land" both sat within twenty lines of the 2026-07-05 Update that reports S(6)–S(8) measured; both now point at it. Registered as RP-b1c1f805 / RP-11166bb6. No count, estimate, CI or canonical value changed by any of the five. |
| v1.26 | 2026-09-02 | **Stack requirement narrowed to what the binary enforces (prose batch P37, Codex V2-F08 #4; wording only).** The `--estimate-knuth` warning published `ulimit -s unlimited` as REQUIRED. It is a **sufficient** setting, not a necessary one, and on a host or container whose hard limit forbids `unlimited` the published requirement was a false blocker. `solve.c`'s preflight tests `rlim_cur != RLIM_INFINITY && rlim_cur < 16UL*1024*1024` and its message names ">= 16 MB"; executed under TR-9 v1.24, `ulimit -s 8192` refuses and exits 1 while `ulimit -s 16384` runs the estimator to completion. The banner now states "at least 16 MB (`ulimit -s 16384` suffices)" with `unlimited` named as one sufficient setting. This is the sibling sweep TR-9 v1.24 reported but did not perform. No figure, count, command, claim or scope changes; the 2026-09-01 tail asserting the requirement "is unchanged and remains mandatory" was true of the failure-MODE correction it belonged to and false of this one, and is rescoped rather than deleted |
| v1.27 | 2026-09-02 | **The two 5×10¹⁰ Knuth invocations published with thread count and archived stdout; the ellipsis command retired (code batch V-1, Codex V2-19 #3; no figure recomputed).** (1) §Verification Guide's uniqueness-refutation bullet printed `SOLVE_KNUTH_C67=1 ./solve --estimate-knuth` followed by an ellipsis in place of the probe count, and pointed at a private run log. Executed literally on a stock build of `main`, the ellipsis parses to zero probes and selects whole-tree exact enumeration — 25 s with no output, rc 124 under `timeout` — while the control `--estimate-knuth 1000` prints its banner immediately. The bullet now carries the full invocation (`SOLVE_KNUTH_C67=1 SOLVE_THREADS=32 ./solve --estimate-knuth 50000000000`) and the run's stdout is archived at `evidence/c67_probe.out`, which matches the published C1–C7 table digit-for-digit. (2) The whole-tree headline's own 5×10¹⁰ invocation, which v1.25's marker recorded as absent from the tracked corpus, is now published beside it (`SOLVE_THREADS=32 ./solve --estimate-knuth 50000000000`) with archived stdout `evidence/knuth_whole_tree_5e10.out` — the 2026-07-26 same-seed re-run, byte-identical in every reported figure to the published headline, the 2026-07-01 original's stdout never having been archived. The ellipsis form is registered in `RETRACTED_PHRASES.tsv` so it cannot be reintroduced unseen. No value in this report moves |
| v1.28 | 2026-09-03 | **One label corrected and one provenance gap stated (hardening lane, Q-330 items 2 and 3; wording only, no figure recomputed).** (i) *The raw C1–C5 estimate was labelled* canonical *at two sites.* The abstract read "1.3287×10³⁸ raw canonical orderings" and §Sections item 3 read "canonical C1–C5 raw" — self-contradictory in this corpus's own vocabulary, since [SOLUTIONS_FORMAT.md](../documentation/SOLUTIONS_FORMAT.md) §Deduplication reserves *canonical* for the orientation-DEDUPLICATED object while 1.3287×10³⁸ is orientation-explicit. Now "raw C1–C5 orderings" and "C1–C5 raw (orientation-explicit)". Same class as the TR-10 relabel landed the same day under Q-321; **the bare *canonical* on the "16,504 vs 16,422 canonical" ORIENTED leaf counts (§Sections item 2) is deliberately NOT touched** — it is one of the ten sites [CORRECTIONS.md](../documentation/CORRECTIONS.md) defers pending the `solve.c` `leaves_canonical_C1C5` → `leaves_oriented_C1C5` rename, and so are the two `leaves_canonical_C1C5` lines in the §Sections item 4 reproduction transcript, which are verbatim program output. (ii) *N(7) has no committed log.* The 2026-07-05 update publishes N(6), N(7) and N(8); measured this session, `reports/evidence/sk/sk5_7_rounds.out` stops at round 6 and `sk8_round.out` carries round 8, so N(7) = 7.695×10¹⁷ — and with it the k = 7 and k = 8 bit gains, which are both computed from it — is reported without a public artifact. Stated inline rather than withdrawn: the round-7 PICK is recoverable from `sk8_round.out`'s pin list and nothing else in the report depends on the value. Both charges raised by the Codex T04 review pass; reviewers are acknowledged, not credited as authors. |
| v1.29 *(current)* | 2026-09-05 | **§Update v1.7's 126.6-bit numerator given its population context (Fable lane, Q-131/Q-143; wording only — no count, CI or projection changes).** The decoy control of 2026-09-04 ([TR-9](TR9_PRICING_THE_CONSTRAINTS.md) v1.28) measured King Wen's exact C5-layer count at the 65th percentile of 1,000 random C1∩C2 targets each counted under its own extracted multiset, so the numerator of the boundary-count arithmetic is the size of an extracted space that a random target reproduces, and the count prices identifying *any* member of such a space — which §6 already said ("not special by being rare or hard to find"). Stated in place, with the two King Wen-only parts named: the C3 cut inside 126.6 and the per-boundary rate, neither measured for any other target |
