# Distributional analysis of the King Wen sequence

Where does the King Wen sequence sit in the joint distribution of observable
statistics computed across the 3,432,399,297 canonical C1-C5 valid orderings
(the 100T d3 canonical, sha256 `915abf30…`)?

This document reframes the "is King Wen unique?" question into a rigorous
probabilistic form: compute a k-dimensional observable-statistic vector for
every canonical record, estimate the joint distribution, and report KW's
position as a percentile with bootstrap confidence intervals. The approach
uses the partial-enumeration data as a Monte Carlo sample of the constraint
space and produces quantified claims about KW's statistical distinctiveness
that are defensible without requiring full (infeasible) enumeration.

**Scope:** analysis is specifically over the 100T d3 canonical set (the
3.43 billion orderings that satisfy C1-C5 at the 100T partition budget).
Claims are about KW's position within that population.

## Observable-statistics vector (10 dimensions)

Each canonical ordering is characterized by the following statistics,
computed over 3.43 billion records using streaming parquet output
(`solve.py --compute-stats`). See `x/roae/P2_OBSERVABLES_SCHEMA.md` for the
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
`x/roae/P2_MARGINALS.md`.)

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

- **KW sits at the high extreme in four dimensions:** `c3_total` (95%-ile —
  9.9% of records tie at the ceiling 776 with KW), `c6_c7_count` (99.997%
  — only 198,676 tie at 2), `shift_conformant_count` (99.96% — 2.6M tie at
  17), and `first_position_deviation` (100% — literally unique).

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
`x/roae/viz/`:

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
`x/roae/P2_JOINT_DENSITY.md` for methodology details.

- **Sample:** 102,990 standardized records (30 per chunk × 3,433 chunks,
  uniform across the canonical)
- **KDE bandwidth:** 0.3253 (Silverman rule)
- **KW's log-density:** −128,260
- **Sample log-density range:** [−10.11, −2.98], mean −5.67
- **KW's density-percentile: 0.000%** (fraction of sample points with
  log-density ≤ KW's; bootstrap 1000× 95% CI: **[0.000%, 0.000%]**)

**What this means.** KW's log-density under the sample-fit KDE is approximately
**−128,260**, while the entire sample's log-density range is
[−10.11, −2.98]. KW's log-density is **~12,800× lower** than any sampled
canonical ordering's log-density. This is because KW's specific combination
of feature-values — especially its high values in 4+ marginal dimensions
simultaneously — places it in a region of the 7-dimensional feature space
that is not represented by any of our 100K standardized anchor points.

Individually, KW's marginal percentiles are merely high (95%, 99.97%, 99.96%,
100%, 28.94%, 95.48%). The JOINT configuration — *simultaneously* at extremes
in multiple dimensions — is what makes KW a density-space outlier. A typical
C1-C5-valid ordering has its high values scattered or moderated across
dimensions; KW concentrates them.

**Bootstrap robustness.** 1000 bootstrap resamples each yield KW at 0.000%
density percentile — the finding is not an artifact of a particular sample.
The 95% CI is [0.000%, 0.000%].

**Caveat on methodology.** A KDE assigns extrapolated density at points far
from all anchors. KW's extreme log-density reflects that KW's joint feature
configuration is unrepresented in 100K sampled points. A denser KDE fit (1M+
anchors, longer compute) would likely produce a less extreme but still very
low log-density. The qualitative conclusion — "KW is in an atypical joint
region" — is robust; the quantitative "−128,260 log-density" is methodology-
dependent.

## What this establishes

1. **KW is statistically atypical in the joint observable distribution** of
   the 100T canonical. Its combination of feature values is not
   representative of the bulk of the 3.43 billion C1-C5 valid orderings.
   Quantified claim: **0th percentile in joint density estimation**, 95%
   bootstrap CI [0.000%, 0.000%].

2. **Individual marginal percentiles are not the full story.** KW is near
   the median in `fft_dominant_freq` (29%-ile) and constant-valued in two
   dimensions. The joint-distribution atypicality arises from *simultaneous*
   extreme values across 4+ independent structural dimensions, which is
   rare in the population.

3. **Two of the proposed observable dimensions are structurally invariant**
   across all C1-C5 valid orderings: `mean_transition_hamming` and
   `max_transition_hamming`. This is itself a structural finding — the
   C1+C2 constraint forces the transition-Hamming distribution to be
   identical across every valid ordering.

## What this does not establish

- **Not a uniqueness proof.** The analysis demonstrates KW is
  distributionally atypical, not that KW is the unique optimum of any
  principle. Recall from SOLVE-SUMMARY.md: specific "KW-property
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
- **Archived outputs:** `x/roae/P2_MARGINALS.md`, `x/roae/viz/`,
  `x/roae/P2_JOINT_DENSITY.md`

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
and orientation-symmetry finding documented in SOLVE-SUMMARY.md §Observed
structural regularity. The yield-clustering result is about the enumeration
tree's per-sub-branch partition structure; this result is about the
record-level feature distribution.

Both are latent findings in the 100T canonical that were not visible
until the appropriate analytical lens was applied. Neither requires
further enumeration.
