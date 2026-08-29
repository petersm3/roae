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
over the *exact* production search tree: **1.3287×10³⁸ raw canonical orderings (95% CI [1.3283,
1.3292]×10³⁸, rel. error 0.02%; ≈3.3×10³⁷ after orientation-dedup ⚠ **[the ORIENTATION-DEDUPLICATED ≈3.3×10³⁷ is WITHDRAWN 2026-08-24 — it exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×. The raw 1.3287×10³⁸ STANDS; see documentation/CORRECTIONS.md]**)**. This is a statistical estimate, not
a proven cardinality, validated to <1% against exact subtree counts on a three-rung ladder. ⚠ **[a
56-branch cross-sum was also run at the time and is NOT offered as evidence here: its per-branch
values were not archived, and it is recorded as untraced — see the T04 row of the untraced-claims
audit. The three-rung ladder validation stands.]** Three consequences follow. First, the deepest published canonical (560T;
1.05×10¹⁰ distinct orderings) has enumerated ≈1 part in 10²⁷ of the space — exhaustion is infeasible at any ⚠ **[the distinct-vs-distinct pairing is WITHDRAWN; stated raw-against-raw it is ≈1 part in 3.03×10²⁷ — see documentation/CORRECTIONS.md]**
budget. Second, extending the walk with the spec's C6/C7 adjacency constraints **refutes the
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
   nodes, 16,504 vs 16,422 canonical). Independent cross-check: 56 per-branch estimates sum to 1.33×10³⁸ vs
   the independently-estimated whole-tree 1.32×10³⁸ (<1%).
3. **The measurement.** 5×10¹⁰ probes (definitive 100×-probe run, 2026-07-01; the earlier 5×10⁸ run gave 1.32×10³⁸
   (rel. err 0.18%), ≈2–3.7σ below the definitive value (the exact figure is rounding-dependent — ~2σ on the
   less-rounded early value, ~3.7σ if 1.32×10³⁸ is taken as exact) — an unremarkable deviation for one early draw from a
   right-skewed weight distribution, in the direction (low) such skew predicts; the 100× run supersedes it):
   canonical C1–C5 raw **1.3287×10³⁸** (0.02%); C1/C2/C4/C5 complete
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
   observed-rate extrapolation (not a bound — see v1.7 update) is unaffected. A
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

## Estimator calibration against exact ground truth (v1.11, 2026-07-20)

The estimator's error bars were, until 2026, self-reported: an internal variance estimate with no
external check at full scale. Two constraint layers have since been computed **exactly** by the
symmetry-quotient DP ([TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)), which turns those layers
into ground truth against which the estimator can be scored. Consolidated here, since the comparison was
previously scattered across two documents:

| Layer | Exact value | Prior Knuth estimate | est/exact | Deviation | Inside stated ±0.01%? |
|---|---|---|---|---|---|
| C1∩C2∩C4 | 757,058,601,340,255,440,651,419,713,405,330,315,358,208 (7.570586×10⁴¹) | 7.571×10⁴¹ ±0.01% | 1.0000547 | **+5.47×10⁻⁵** | yes |
| C1∩C2∩C4∩C5 | 1,097,051,278,789,181,790,036,112,071,176,579,186,688 (1.097051×10³⁹) | 1.0971×10³⁹ ±0.01% | 1.0000444 | **+4.44×10⁻⁵** | yes |
| C1–C5 (adds C3) | *none — no exact value exists* | 1.3287×10³⁸ | — | — | **uncalibrated** |

**Coverage: 2 of 2.** At both layers where ground truth exists, the exact value falls inside the
estimator's stated envelope, with roughly half the claimed error budget to spare. This is the first
external validation of the estimator at full scale, and it is the substantive result of this section.

**What this does NOT establish, stated explicitly because the numbers invite the stronger reading.**
Both deviations happen to be positive and of similar size, which looks like a small systematic upward
bias. **That inference is not available from these figures.** The published estimates are quoted to four
and five significant figures, giving rounding granularities of ≈6.6×10⁻⁵ and ≈4.6×10⁻⁵ — *the same order
as the deviations being measured*. The apparent common sign is therefore not distinguishable from
quoting precision, and no bias direction or magnitude is claimed here. Recovering the unrounded estimator
outputs from the original run records would be required before any bias statement could be made.

**Two points are consistency, not an error model.** With n=2 we can say the estimator's envelope has held
wherever it has been checkable; we cannot fit an error distribution, and nothing here licenses
extrapolating a tightened error bar to the uncalibrated C3 layer. The honest summary is that the
flagship 1.3287×10³⁸ retains its stated CI on the estimator's own terms, now with the reassurance that
the same machinery was accurate to <10⁻⁴ at two independent layers spanning three orders of magnitude.

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

![Log-scale decay curve of S(k), the fraction of the full C1–C5 population agreeing with King Wen on its first k identifying boundaries: four measured points falling from 7.49e-4 at k=1 to 6.34e-13 at k=4, a dashed extrapolation at the ~×1000-per-boundary greedy cut, an orange measured bracket for the weakest remaining boundaries (×15–17 per boundary, k=5–8), and a shaded band at k≈13–20 where extrapolation reaches full-space uniqueness.](figures/fig_tr4_boundary_information.png)

*The boundary-information curve S(k) (§5). Red points are the measured pinned-Knuth values on the first
four boundaries of the 560T greedy identifying order {4, 27, 25, 21, 1}, annotated with the
surviving-orderings counts — those k = 4 boundaries (which inside the 560T slice leave KW plus one
impostor; the full identifying set has 5 boundaries) still admit ≈8.4×10²⁵ full-space
orderings. The dashed line extrapolates the roughly constant ~×10³ per-boundary cut (NOT measured); the
orange band is the measured weakest-remaining-boundary bracket (×15–17 per boundary at k = 5–8),
bounding how much the decay depends on boundary choice. The green band marks where extrapolation
reaches one surviving ordering: ~15–20 boundaries (revised up from an earlier ~13–14 estimate by the
2026-07-05 S(6)–S(8) measurement; wide error; observed-rate extrapolation ~12, not a bound).
Generated by [`viz/report_figures.py`](../viz/report_figures.py);
[SVG](figures/fig_tr4_boundary_information.svg).*

## Verification Guide
⚠ **`ulimit -s unlimited` is REQUIRED for every `--estimate-knuth` command below.** Under the default 8 MB stack these commands abort with SIGSEGV before producing output: `main` allocates a ~7.23 MB frame and `estimate_tree_knuth` a further ~1.02 MB, so the 8 MB limit is exceeded the moment the estimator is entered. This is environmental, not a logic fault — with the limit raised the published figures reproduce. *(Added 2026-08-21: found by a cold external-reviewer pass and independently reproduced; the requirement had been documented only in CANONICAL_HASHES.md's large-scale-enumeration recipe, while these guides state the estimator needs no data disk and costs pennies.)*
- Estimator implementation + exact-count mode: `gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz`, then
  `solve --estimate-knuth 500000000` (whole tree; 5×10⁸ probes ≈ 79 s on a many-core host, pennies of
  compute — ⚠ **the 79 s figure carries no recorded core count and is not reproducible as stated**: the
  estimator is thread-parallel and prints its thread count in its own `[knuth] N probes, T threads`
  banner, so wall time scales with the host. On a 2-core machine the same command takes tens of
  minutes. Corrected 2026-08-21 — a published timing without its hardware basis);
  `solve --estimate-knuth 100000000 <p1> <o1>` (one branch); `solve --estimate-knuth 0 <prefix>` (exact
  validation ladder). No data disk required.
- Full write-up, tables, per-cell distribution: [documentation/SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md)
- Uniqueness-conjecture refutation: `SOLVE_KNUTH_C67=1 ./solve --estimate-knuth ...` (SEARCH_SPACE_SIZE.md
  §"The C1–C7 space"); run log in roae-private (probe on `c207`, 2026-07-02 — a private repository, not
  publicly accessible; the public check is re-running the published command, this report rests no claim
  on the private log)
- S(k) curve: `SOLVE_KNUTH_PIN_SLOTS="3,4,26,27,24,25,20,21" SOLVE_KNUTH_BOUNDARY_COND=1 ./solve
  --estimate-knuth 2000000000`
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
boundary across all five measured steps, the first being the maximum by construction). Since
identifying King Wen in the C1–C5 space requires 126.6 bits, dividing through gives
an observed-rate extrapolation of **~12 boundaries** (explicitly NOT a lower bound — see v1.15) and a projection of **≈ 13** — tightening this report's earlier
13–20 extrapolation toward its lower end. (Heuristic: unmeasured boundary synergies could beat the
single-boundary maximum, but five steps show none — gains behave as near-independent.) Full arithmetic
in SEARCH_SPACE_SIZE.md; sharpens further when S(6..8) land.


### Update (2026-07-05): the marginal-gain curve bends — S(6)-S(8) measured

Extending the greedy boundary chain three more rounds (2x10^10-probe value runs per round; certified
selection caveat below) gives survivor COUNTS N(6) = 1.879x10^20, N(7) = 7.695x10^17, N(8) = 1.093x10^16 *(notation corrected 2026-08-01: these are absolute survivor counts, not values of S(k) — S(k) is defined in this section as a FRACTION of the C1–C5 population, e.g. S(4) = 6.34x10^-13. Divide by 1.3287x10^38 for the corresponding fractions.)*. The
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
| v1.22 *(current)* | 2026-08-27 | **The 56-branch cross-sum is scoped out of the validation claim (Q-183/Q-65).** The sentence read "validated to <1% against exact subtree counts on a three-rung ladder plus an independent 56-branch cross-sum". The cross-sum's per-branch values were never archived — the untraced-claims audit records it as **NOT FOUND** — so it cannot be offered as evidence, and an unreproducible cross-check strengthens nothing. The three-rung ladder validation is unaffected and stands. No figure changes. |
