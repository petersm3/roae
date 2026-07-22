# Distributional analysis of the King Wen sequence

Where does the King Wen sequence sit in the joint distribution of observable
statistics computed across the canonical C1-C5 valid orderings?

This document reframes the "is King Wen unique?" question into a rigorous
probabilistic form: compute a k-dimensional observable-statistic vector for
every canonical record, estimate the joint distribution, and report KW's
position as a percentile with bootstrap confidence intervals. The approach
uses the partial-enumeration data as a Monte Carlo sample of the constraint
space and produces quantified claims about KW's statistical distinctiveness
that are defensible without requiring full (infeasible) enumeration.

**Scope of the analysis below:** this analysis was computed on the
**100 T d3 canonical** (3,432,399,297 orderings, sha256 `915abf30…`). The
**560 T canonical** (10,525,271,997 orderings, sha `9a968fa2…`, established
2026-06-08) is the new deepest published enumeration; a re-run of this
distributional analysis at 560 T is queued and will appear as a new section
when complete. The 100 T results below remain valid as a strict-subset
analysis (the 100 T solution set is a subset of the 560 T set under the same
partition strategy). Bootstrap percentile shifts at the 560 T scale are
expected to be small (≤ low single-digit percentile shifts) because the 100 T
sample is already a 3.4-billion-record sample with tight CIs; any 560 T-only
findings would surface as either (a) new tail-features in the joint distribution
that the 100 T sample undersampled, or (b) tighter CIs around the existing
estimates. Both are next-step questions, not invalidations of the analysis below.

## Observable-statistics vector (10 dimensions)

Each canonical ordering is characterized by the following statistics,
computed over 3.43 billion records using streaming parquet output
([`solve.py --compute-stats`](SOLVE_C_CLI.md#--compute-stats-solvepy-only)). See `roae-private/P2_OBSERVABLES_SCHEMA.md` for the
frozen schema.

| # | Dim | Meaning | Family |
|---|---|---|---|
| 1 | `edit_dist_kw` | Positions where this ordering's pair differs from KW's pair (0-32) | KW-relative |
| 2 | `c3_total` | Sum of complement-distances (424-776) | Structural |
| 3 | `c6_c7_count` | Satisfies C6 (pos 27-28) + C7 (pos 25-26) adjacency constraints (0-2) | Structural |
| 4 | `position_2_pair` | Pair at byte 1 (categorical stratifier, 0-31) | Structural |
| 5 | `mean_transition_hamming` | Mean 6-bit Hamming distance across 63 transitions | Spectral |
| 6 | `max_transition_hamming` | Max of those 63 distances | Spectral |
| 7 | `fft_dominant_freq` | Argmax k of |FFT(hexagram-sequence)[k]| for k ∈ 1..31 | Spectral |
| 8 | `fft_peak_amplitude` | Amplitude at the dominant frequency | Spectral |
| 9 | `shift_conformant_count` | Positions 3-19 where pair_idx[p] ∈ {p, p-1} (0-17) | Structural |
| 10 | `first_position_deviation` | 1-indexed position where first differs from KW (33 = identical) | KW-relative |

## Univariate marginal percentiles

For each of the 9 non-stratifier dimensions, KW's exact percentile in the
marginal was computed by streaming histogram aggregation across all 3.43B
records. (Subcommand: `solve.py --marginals`; full table in
`roae-private/P2_MARGINALS.md`.)

| Dim | KW value | Records < KW | Records == KW | **KW percentile** |
|---|---|---|---|---|
| `edit_dist_kw` | **0** | 0 | 1 | **0.0000%** (unique to KW) |
| `c3_total` | **776** | 3,092,219,648 | 340,179,649 | **95.04%** |
| `c6_c7_count` | **2** | 3,432,200,621 | 198,676 | **99.997%** |
| `max_transition_hamming` | 6 | 0 | 3,432,399,297 | 50.00% (invariant) |
| `fft_dominant_freq` | **16** | 776,656,635 | 433,156,350 | **28.94%** |
| `shift_conformant_count` | **17** | 3,429,763,541 | 2,635,756 | **99.96%** |
| `first_position_deviation` | **33** | 3,432,399,296 | 1 | **100.00%** (unique) |
| `mean_transition_hamming` | 3.3492 | 0 | 3,432,399,297 | 50.00% (invariant) |
| `fft_peak_amplitude` | ~374.77 | ~3,276,971,650 | ~324,161 | **~95.48%** |

**Interpretation of marginals:**

- **Two dimensions are invariant** across all 3.43B canonical records:
  `mean_transition_hamming = 3.3492` and `max_transition_hamming = 6`. The
  C2 "no-5-line" constraint combined with the C1 pair structure enforces
  an *identical transition-Hamming distribution* in every valid ordering.
  These dimensions carry zero information for distinguishing KW from
  other valid orderings — a structural finding in its own right.

- **KW sits at the high extreme in three dimensions, plus one that is
  extreme by construction:** `c6_c7_count` (99.997% — only 198,676 tie at
  2), `shift_conformant_count` (99.96% — 2.6M tie at 17), and
  `first_position_deviation` (100% — literally unique). `c3_total` (95.04%-ile)
  is at the high extreme **by construction, not as a finding**: the canonical
  population is filtered at C3 ≤ 776 = KW's own value, so KW's top-cohort
  placement on this dimension is guaranteed by the truncation (cf. the
  analogous tautology note in [HISTORY.md](HISTORY.md) §[22]); the only
  informative content of this marginal is the tie share (9.9% of records tie
  at the ceiling 776 with KW). *(Caveat added 2026-07-22.)*

- **KW sits at the low end in `fft_dominant_freq` (28.94%-ile).** The
  dominant frequency of KW's hexagram-value sequence is 16 (a period-4
  oscillation) — lower than the typical canonical ordering's dominant
  frequency (mean ~20). This is mildly surprising given KW's regular
  appearance; it suggests KW has structure at a frequency that is
  *uncommon* among valid orderings.

Each marginal-percentile gives a per-dimension view of KW's position.
None is itself dispositive.

## Bivariate structure

Five hexbin heatmaps of the 100T canonical joint distribution (1.7M
uniformly-sampled points, KW marked with gold star) are archived at
`roae-private/viz/`:

- `viz_edit_dist_kw__c3_total.png`
- `viz_c3_total__shift_conformant_count.png`
- `viz_fft_dominant_freq__fft_peak_amplitude.png`
- `viz_mean_transition_hamming__fft_peak_amplitude.png`
- `viz_position_2_pair__edit_dist_kw.png`

Visual observations:

- In **edit_dist × c3_total**: KW (0, 776) sits at the extreme top-left
  corner — isolated from the main distribution mass which is concentrated
  near (28, 720).
- In **c3_total × shift_conformant_count**: KW (776, 17) is in a
  top-right corner region that holds relatively few records. Both
  dimensions push KW toward their extremes jointly.
- In **fft_dominant_freq × fft_peak_amplitude**: KW (16, ~375) is in a
  modestly-populated region. The density is higher near
  (21, ~300) — "typical" orderings have higher frequency with lower amplitude.

## Joint density — the headline finding

A Gaussian-kernel density estimate was fit over the 7 informative
dimensions (excluding the two invariant transition-Hamming dims and the
categorical stratifier). See `solve.py --joint-density` and
`roae-private/P2_JOINT_DENSITY.md` for methodology details.

- **Sample:** 102,990 standardized records (30 per chunk × 3,433 chunks,
  uniform across the canonical)
- **KDE bandwidth:** 0.3253 (Silverman rule)
- **KW's log-density:** −128,260
- **Sample log-density range:** [−10.11, −2.98], mean −5.67
- **KW's joint-density rank: below the sample's resolution (<10⁻⁵).** No
  ordering in the 100,000-record uniform sample matches KW's joint feature
  profile; a sample of this size cannot resolve percentiles below ~10⁻⁵, so
  the rank is reported as a resolution bound, not a percentile. KW is
  simultaneously ≥95th-percentile extreme on 3 of the 8 discriminating
  dimensions, plus a fourth (`c3_total`) whose ≥95th-percentile placement
  is guaranteed by the C3 ≤ 776 population filter (by construction, not a
  finding — see the marginals caveat above; count restated 2026-07-22,
  previously "4 of 8"). The joint-KDE has not been re-run with `c3_total`
  excluded; the outlier conclusion is expected to survive on the remaining
  drivers (`c6_c7_count`, `first_position_deviation`,
  `shift_conformant_count`) but that re-run has not been performed.

**What this means.** KW's log-density under the sample-fit KDE is approximately
**−128,260**, while the entire sample's log-density range is
[−10.11, −2.98]. KW's log-density is **~12,800× lower** than any sampled
canonical ordering's log-density. This is because KW's specific combination
of feature-values — especially its high values in three marginal dimensions
simultaneously (plus `c3_total`, high by construction under the C3 ≤ 776
filter) — places it in a region of the 7-dimensional feature space
that is not represented by any of our 100K standardized anchor points.

Individually, KW's marginal percentiles are merely high (95% — though that
one is guaranteed by the C3 ≤ 776 filter, see above — 99.97%, 99.96%,
100%, 28.94%, 95.48%). The JOINT configuration — *simultaneously* at extremes
in multiple dimensions — is what makes KW a density-space outlier. A typical
C1-C5-valid ordering has its high values scattered or moderated across
dimensions; KW concentrates them.

**Bootstrap robustness.** 1000 bootstrap resamples each place KW below every
sampled point's density — the finding is not an artifact of a particular
sample. Note that bootstrap resampling of a 100K sample cannot resolve
percentiles below ~10⁻⁵, so no confidence interval tighter than that
resolution is quoted.

**Caveat on methodology.** A KDE assigns extrapolated density at points far
from all anchors. KW's extreme log-density reflects that KW's joint feature
configuration is unrepresented in 100K sampled points. A denser KDE fit (1M+
anchors, longer compute) would likely produce a less extreme but still very
low log-density. The qualitative conclusion — "KW is in an atypical joint
region" — is robust; the quantitative "−128,260 log-density" is methodology-
dependent. High-dimensional KDE is additionally bandwidth-sensitive (the
curse of dimensionality): with 100K anchors in 7 dimensions, density
estimates far from the anchor cloud depend strongly on the bandwidth choice
(here Silverman's rule), so the magnitude of KW's density deficit should not
be over-interpreted.

## What this establishes

1. **KW is statistically atypical in the joint observable distribution** of
   the 100T canonical. Its combination of feature values is not
   representative of the bulk of the 3.43 billion C1-C5 valid orderings.
   Quantified claim: no ordering in a 100,000-record uniform sample matches
   KW's joint feature profile — KW's joint-density rank is **below the
   sample's resolution (<10⁻⁵)**, and KW is simultaneously ≥95th-percentile
   extreme on 3 of the 8 discriminating dimensions — plus `c3_total`, whose
   ≥95th-percentile placement is guaranteed by the C3 ≤ 776 population
   filter (by construction, not a finding; count restated 2026-07-22).

2. **Individual marginal percentiles are not the full story.** KW is near
   the median in `fft_dominant_freq` (29%-ile) and constant-valued in two
   dimensions. The joint-distribution atypicality arises from *simultaneous*
   extreme values across three independent structural dimensions (plus the
   by-construction `c3_total` extreme), which is
   rare in the population.

3. **Two of the proposed observable dimensions are structurally invariant**
   across all C1-C5 valid orderings: `mean_transition_hamming` and
   `max_transition_hamming`. This is itself a structural finding — the
   C1+C2 constraint forces the transition-Hamming distribution to be
   identical across every valid ordering.

## What this does not establish

- **Not a uniqueness proof.** The analysis demonstrates KW is
  distributionally atypical, not that KW is the unique optimum of any
  principle. Recall from [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md): specific "KW-property
  extraction" can make almost any C1+C2 ordering appear uniquely determined;
  this analysis avoids that extraction problem by using dimensions chosen
  for general information content.
- **Not a claim about the designers' intent.** Statistical atypicality
  in observable features does not reveal whether this was deliberate
  mathematical design or the accumulation of practice-based aesthetic
  choices over generations. As elsewhere in the ROAE record: the sequence
  is the same either way; only the history differs.

## Reproducibility

All scripts and intermediate data are preserved:

- **Input:** `solutions.bin` on `solver-data-westus3` managed disk (sha256
  `915abf30…`, 3,432,399,297 records)
- **Stat computation:** `solve.py --compute-stats` — per-record 10-dim
  vector, output as per-chunk parquet directory
- **Marginal analysis:** `solve.py --marginals` (streaming histograms)
- **Bivariate plots:** `solve.py --bivariate` (matplotlib hexbin +
  uniform subsample)
- **Joint density:** `solve.py --joint-density` (sklearn KDE + bootstrap)
- All four subcommands consolidated into `solve.py` on 2026-04-21 per the
  single-Python-file rule; previously lived as `scripts/compute_stats.py`,
  `scripts/p2_marginals.py`, `scripts/p2_bivariate.py`,
  `scripts/p2_joint_density.py` in the staging repo.
- **Archived outputs:** `roae-private/P2_MARGINALS.md`, `roae-private/viz/`,
  `roae-private/P2_JOINT_DENSITY.md`

## Appendix A: Theorem of invariant transition-Hamming distribution

**Claim.** For every ordering `S = (s₀, s₁, …, s₆₃)` satisfying C1-C5,
the multiset of 63 consecutive-hexagram Hamming distances
`{popcount(sᵢ ⊕ sᵢ₊₁) : 0 ≤ i < 63}` is identical to King Wen's:

```
{ Hamming distance : count }
     k=1 : 2
     k=2 : 20
     k=3 : 13
     k=4 : 19
     k=5 : 0      (forbidden by C2)
     k=6 : 9
     k=0 : 0      (impossible: a permutation cannot repeat values)
     k=7 : 0      (impossible: 6-bit values have max Hamming distance 6)
   ─────────
     total 63
```

**Proof.** Immediate from C5. C5 is defined as a "budget" constraint:
`budget[k] = |{i : popcount(KW[i] ⊕ KW[i+1]) = k}|` for each `k ∈ {0,…,6}`,
and the enumerator requires that any valid ordering's per-k transition
counts match this exact vector. (See `solve.c` lines 701–706 where
`init_kw_dist` populates `kw_dist[]`, and every step of `backtrack`
decrements `budget[]` on transition placement.) QED.

**Consequences.**

1. **Any real-valued statistic of the 63-transition multiset is constant
   across all C1-C5 valid orderings.** This includes the mean (3.3492…),
   median (3), max (6), min (1), variance, skew, etc. These are not
   observable properties that distinguish KW from other valid orderings —
   they are shared-by-construction.

2. **`mean_transition_hamming` and `max_transition_hamming` should not
   have been included in the original observable-statistics schema**
   (P2_OBSERVABLES_SCHEMA.md). This is a schema bug, now documented as
   a finding: these two dimensions carry zero discriminative information
   and contribute only noise to joint-distribution estimates.

3. **The 32 within-pair Hamming distances are additionally invariant**,
   determined purely by which 32 pairs (the C1 pair classes derived
   from KW) are used. Each pair `{a,b}` contributes `popcount(a ⊕ b)`,
   a property of the pair itself, not its position. Since any valid
   ordering uses each of the 32 pair classes exactly once, the multiset
   of within-pair distances is the same across all orderings.

4. **The 31 between-pair Hamming distances therefore also have the same
   multiset across all orderings** (derivable as full multiset minus
   within-pair multiset). But individual between-pair distances at
   specific positions vary — this is where inter-ordering differentiation
   actually lives in the Hamming-distance family of observables.

A strengthened observable schema would drop mean and max in favor of
*position-conditional* transition features (e.g., "Hamming distance at
position 5-6") which can distinguish orderings.

## Appendix B: Mechanistic interpretation of KW's FFT dominant frequency

KW's hexagram-value sequence `(s₀, s₁, …, s₆₃)` has a length-64 FFT with
a clear dominant frequency at **k = 16** (period = 64/16 = 4), amplitude
374.77. The top-5 FFT amplitudes are:

| k | Period | Amplitude | Note |
|---|---|---|---|
| **16** | **4.0** | **374.77** | Dominant |
| 15 | 4.267 | 267.38 | Neighbor of k=16 |
| 30 | 2.133 | 259.94 | Near-Nyquist |
| 22 | 2.909 | 257.88 | |
| 26 | 2.462 | 182.48 | |

The concentration at k=16 means that the strongest oscillatory structure
in KW's sequence has a period of exactly 4 positions — i.e., the signal
approximately repeats every 2 pairs (each pair occupies 2 positions).

**Marginal-distribution comparison (refinement of the earlier marginal result).**

From the 3.43B-record marginal analysis:

- Records with `fft_dominant_freq < 16`: 776,656,635 (22.6%)
- Records with `fft_dominant_freq = 16`: **433,156,350** (**12.6%** — largest single bin)
- Records with `fft_dominant_freq > 16`: 2,222,586,312 (64.8%)

So KW's k=16 is actually **the mode** (most common value) of the
fft_dominant_freq distribution, not a rare value. The "29th percentile"
report for KW reflects the standard convention (half-bin rank among tied
records), not rarity — KW shares its dominant frequency with 433 million
other C1-C5 valid orderings.

**Interpretation.** Period-4 structure is common across valid orderings
because the pair structure (C1) creates a natural length-2 alternation
(the a-then-b within each pair), and the aggregation of 32 such
alternations produces frequency content concentrated at or near
half-Nyquist (k=32 in length-64 FFT) and its nearby bins. Why k=16
specifically is the mode rather than k=32 requires deeper analysis —
likely because the pair structure is not strictly periodic (different
pairs have different Hamming distances between their a and b), so the
pure-period-2 content gets split across nearby bins.

**The scientific refinement:** the earlier marginal writeup overstated
KW's fft_dominant_freq "distinctiveness." KW is in the distribution
mode for this dimension, not the tail. A population-mode value is
typical, not distinguishing. This is an important correction for the
joint-density narrative.

## Relationship to other claims

This analysis is distinct from, and complementary to, the yield-clustering
and orientation-symmetry finding documented in SOLVE_SUMMARY.md §Observed
structural regularity. The yield-clustering result is about the enumeration
tree's per-sub-branch partition structure; this result is about the
record-level feature distribution.

Both are latent findings in the 100T canonical that were not visible
until the appropriate analytical lens was applied. Neither requires
further enumeration.

**Relationship to [Chan 2026](CITATIONS.md#chan2026) (arXiv:2604.09234).** Chan's independent
work analyzes King Wen against 100,000 random permutations of all
64 hexagrams (no constraint pre-filter). ROAE's framing is different
— we measure KW's position within the C1+C2+C3+C4+C5-constrained
solution space (~759M orderings at 11.2T, ~3.4B at 100T). The two
analyses use different baselines and address different questions:
Chan asks "is KW distinctive vs arbitrary permutations?", ROAE asks
"is KW distinctive vs other constraint-satisfying orderings?".
Both find KW at extreme tails of their respective distributions
(Chan's mean Hamming, lag-1 autocorrelation, asymmetry findings;
ROAE's below-sample-resolution joint-density rank). Where these analyses
overlap on common observables (mean Hamming, alternation), Chan's
prior art is acknowledged — see [CITATIONS.md](CITATIONS.md) and
[SOLVE.md](SOLVE.md) / [CRITIQUE.md](CRITIQUE.md) for inline citations.

## Trigram-level addendum (2026-07-03)

The inferential trigram extension ([`roae.py --trigrams`](ROAE_PY_CLI.md)) places KW's trigram-level statistics in the same
pair-preserving null framework used throughout this document: upper/lower trigram change rates are
population-typical (47th/27th percentile); the pure-hexagram Classic-ends concentration is mildly notable
(4/6, null P = 0.034, with the C4-fixes-two-positions caveat); KW is statistically independent of Jing
Fang's palace ordering (Spearman rho = 0.14, null P = 0.12) — the two great classical orderings share
constraint principles (both avoid 5-line transitions; see the no-5 shared-property analysis) while being
organizationally unrelated. The nuclear-map terminal set {0, 21, 42, 63} coincides exactly with C4's fixed
pair plus the final alternating pair — a classical fact whose alignment with the sequence's anchors is
noted without a significance claim (it is a property of the hexagram set, not of the ordering).

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*

*Revision 2026-07-22 (C3 scope-consistency sweep): `c3_total`'s 95.04th-percentile marginal is guaranteed by the C3 ≤ 776 population filter (the canonical is truncated at KW's own value), so it is no longer counted as one of the joint-KDE outlier drivers — "4 of 8 extreme dimensions" is restated throughout as "3 of 8, plus one by construction". The only informative content of the `c3_total` marginal is its ceiling-tie share (9.9% at 100T). The KDE itself was not re-run; whether the joint-outlier magnitude changes with `c3_total` excluded is explicitly left open. No numbers in the tables changed.*
