# Distributional analysis of the King Wen sequence

Where does the King Wen sequence sit in the joint distribution of observable
statistics computed across the canonical C1-C5 valid orderings?

This document reframes the "is King Wen unique?" question into a rigorous
probabilistic form: compute a k-dimensional observable-statistic vector for
every canonical record, estimate the joint distribution, and report KW's
position as a percentile with bootstrap confidence intervals.

**What the data are, precisely (corrected 2026-08-30).** The partial-enumeration
data are a large, *structured* subsample — not a random sample of the constraint
space. Every one of the 158,364 partition cells contributes its first
budget-limited nodes **in deterministic DFS order**
([CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md) §"Why this works:
prefix-determinism per cell"), and no cell completed
([SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) §"Caveats on these rates": "a partial, **non-uniform**
sample … shallower solutions overrepresented … indicative, not definitive").
No record carries an inclusion probability, so no figure below is a
random-sampling estimate of a full-space quantity. Every percentile, histogram
and tail probability in this document is **exact for the 100 T canonical slice
and scoped to it**; extension to the full C1-C5 space is an open question, not a
result. *(An earlier revision of this paragraph described the data as a random
sample of the constraint space and called the resulting claims "defensible
without requiring full enumeration"; that framing is withdrawn.)*

**Scope of the analysis below:** this analysis was computed on the
**100 T d3 canonical** (3,432,399,297 orderings, sha256 `915abf30…`). The
**560 T canonical** (10,525,271,997 orderings, sha `9a968fa2…`, established
2026-06-08) is the new deepest published enumeration. A re-run of this
distributional analysis at 560 T was previously queued; it is **descoped**
as of 2026-07-26 — the joint-KDE headline it would have re-run is withdrawn
below, and re-running a withdrawn analysis at larger scale has no object.
The 100 T results below remain valid as a strict-subset
analysis (the 100 T solution set is a subset of the 560 T set under the same
partition strategy). **No prediction is offered for how these percentiles move
at 560 T, or at full enumeration** *(corrected 2026-08-30)*. An earlier revision
argued the shift would be small "because the 100 T sample is already a
3.4-billion-record sample with tight CIs"; that argument is withdrawn. Bootstrap
CIs quantify resampling variation *within* the algorithm-selected slice, and
because inclusion in the slice is a deterministic function of DFS position
rather than a random draw, CI width bounds no part of the selection effect. That
effect is measured, not hypothetical: [TR-5](../reports/TR5_SYMMETRY.md) §5
finds King Wen **present** in the 560 T canonical while **all 23 of its exact
record-level twins are absent** — membership in a budgeted slice demonstrably
correlates with structure. The deciding experiment is a leaf sampler with known
inclusion probabilities (a design-weighted CDF over the full space); it has not
been run.

## Observable-statistics vector (10 dimensions)

Each canonical ordering is characterized by the following statistics,
computed over 3.43 billion records using streaming parquet output
([`solve.py --compute-stats`](SOLVE_C_CLI.md#--compute-stats-solvepy-only)). See `roae-private/P2_OBSERVABLES_SCHEMA.md` *(private staging repo — not publicly accessible)*
for the frozen schema.

| # | Dim | Meaning | Family |
|---|---|---|---|
| 1 | `edit_dist_kw` | Positions where this ordering's pair differs from KW's pair (0-32) | KW-relative |
| 2 | `c3_total` | Sum of complement-distances (424-776) | Structural |
| 3 | `c6_c7_count` | Satisfies C6 (pos 27-28) + C7 (pos 25-26) adjacency constraints (0-2) | KW-extracted *(reclassified 2026-07-26; was "Structural" — C6/C7 are KW's own adjacency pins)* |
| 4 | `position_2_pair` | Pair at byte 1 (categorical stratifier, 0-31) | Structural |
| 5 | `mean_transition_hamming` | Mean 6-bit Hamming distance across 63 transitions | Spectral |
| 6 | `max_transition_hamming` | Max of those 63 distances | Spectral |
| 7 | `fft_dominant_freq` | Argmax k of |FFT(hexagram-sequence)[k]| for k ∈ 1..31 (the Nyquist bin k = 32 is **excluded by construction** — see Appendix B) | Spectral |
| 8 | `fft_peak_amplitude` | Amplitude at the dominant frequency | Spectral |
| 9 | `shift_conformant_count` | Positions 3-19 where pair_idx[p] ∈ {p, p-1} (0-17) | KW-extracted *(reclassified 2026-07-26; was "Structural" — scores agreement with KW's own pair numbering)* |
| 10 | `first_position_deviation` | 1-indexed position where first differs from KW (33 = identical) | KW-relative |

**Convention caveat on the two FFT dimensions (added 2026-08-30).**
`fft_dominant_freq` and `fft_peak_amplitude` are computed on the
*orientation-bearing* hexagram-value sequence, so they are **not** functions of
the pair-order key alone. A pair-order key typically admits many C1-C5-valid
orientation completions — `python3 verify.py --check-flips` prints the census for
King Wen's own record: of the 31 candidate single-slot orientation flips
(slot 1 is pinned by C4), **9 remain C1-C5-valid**, all with C3 = 776 and King
Wen's exact C5 transition histogram. Those 9 carry *different* amplitudes:
flipping the slot holding the pair (40, 5) moves `fft_peak_amplitude` from
374.766571 to **403.112885** (+7.6%) while changing nothing the constraints can
see. Across the 9, the amplitude spans **343.237549-403.112885**;
`fft_dominant_freq` stays 16 in all of them.

```bash
python3 -c "
import solve, numpy as np
KW = solve.binary_hexagrams
kw_trans = sorted(solve.bit_diff(KW[i], KW[i+1]) for i in range(63))
def valid(s):
    return (solve.has_pair_structure_c1(s) and (s[0], s[1]) == (63, 0)
            and solve.count_five_line_transitions_c2(s) == 0
            and solve.total_complement_distance_c3(s) <= 776
            and sorted(solve.bit_diff(s[i], s[i+1]) for i in range(63)) == kw_trans)
def feat(q):
    x = np.array(q, dtype=np.float32); x = x - x.mean()
    a = np.abs(np.fft.fft(x)[1:32]); return int(a.argmax()) + 1, round(float(a.max()), 6)
print('KW', feat(KW))
for i in range(32):
    s = list(KW); s[2*i], s[2*i+1] = s[2*i+1], s[2*i]
    if valid(s): print(i, (KW[2*i], KW[2*i+1]), feat(s), solve.total_complement_distance_c3(s))
"
# KW (16, 374.766571) ... slot 17 = pair (40, 5) -> (16, 403.112885), C3 776
```

A canonical class retains **one** representative (`solve.c`: *"Lex-smallest
record wins"*; before normalization the least-among-*visited* variant moves with
the budget — [VERIFY.md](VERIFY.md) §"Direct evidence that a key has many valid
orientations"). This document's population
predates any *declared* representative convention, and King Wen is anchored here
at its **received** orientation, which is not shown to be its class's lex-least.
Every percentile below that consumes `fft_peak_amplitude` — the 95.476th
percentile, the one-sided p ≈ 0.045, the 0.757% joint tail and the ≈ 30%
headline — is therefore **scoped to the retained representatives under that
undeclared retention convention**. Making the statistic well-defined requires
either recomputing both columns under a key-determined normalization (for the
population *and* for King Wen) or replacing them with fiber-averaged
observables; neither has been done, and the direction of the shift is not even
signed — King Wen's own valid re-orientations move the amplitude both up and
down.

## Univariate marginal percentiles

For each of the 9 non-stratifier dimensions, KW's exact percentile in the
marginal was computed by streaming histogram aggregation across all 3.43B
records. (Subcommand: `solve.py --marginals`; full table in
`roae-private/P2_MARGINALS.md`.) *(private staging repo — not publicly accessible)*

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
  *identical transition-Hamming distribution* is enforced by **C5** — the
  budget constraint that requires every valid ordering's per-k transition
  counts to equal King Wen's exact vector (proof: Appendix A, "Immediate
  from C5"). C1 and C2 contribute only *support* restrictions: a permutation
  cannot repeat a value (excludes k = 0), C2's "no-5-line" rule excludes
  k = 5, and 6-bit values cap the distance at 6 (excludes k = 7). That is
  strictly weaker than fixing the multiset — C1 + C2 leave the counts on
  {1, 2, 3, 4, 6} free, and C5 is what pins them. *(Corrected 2026-08-30:
  this bullet previously credited "the C2 'no-5-line' constraint combined
  with the C1 pair structure", contradicting Appendix A's own proof.)*
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
  frequency (mean ~20). The percentile placement reflects the half-bin
  convention over a heavily tied distribution, not rarity: k = 16 is the
  second-largest bin (12.62% of records share it; the mode is k = 30) —
  see Appendix B.

Each marginal-percentile gives a per-dimension view of KW's position.
None is itself dispositive.

## Bivariate structure

Five hexbin heatmaps of the 100T canonical joint distribution (1.7M
uniformly-sampled points, KW marked with gold star) are archived at
`roae-private/viz/`: *(private staging repo — not publicly accessible)*

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

## Joint density — de-circularized re-analysis (2026-07-26)

An adversarial circularity audit (2026-07-26) found that five of the seven KDE
dimensions are KW-referencing: `edit_dist_kw` and `first_position_deviation` are
tautological (only KW itself can score 0 / 33 — any reference ordering is the unique
minimizer of distance-to-itself), `shift_conformant_count` and `c6_c7_count` score
agreement with KW's own pair placement and adjacency pins (KW-extracted, priced
data-like in METHODS), and `c3_total`'s ceiling placement is guaranteed by the
C3 ≤ 776 population filter. The joint-KDE figures previously headlined here
("joint-density rank < 10⁻⁵", "log-density −128,260, ~12,800× lower than any sampled
ordering") are therefore the predicted signature of scoring a sequence against
templates extracted from that sequence — the same diagnosis this project renders for
D-B1 in TR-10 — and are **withdrawn as evidence**. They are retained in
[HISTORY.md](HISTORY.md) only as a record of the error.

Re-run on the two dimensions with KW-independent definitions (`fft_dominant_freq`,
`fft_peak_amplitude`), same population (100T d3 canonical, 3,432,399,297 records),
same pipeline (validated by exact reproduction of both the published marginals table
and the original −128,260.1287 figure before de-circularization): **KW's joint-density
percentile is ≈ 30%** (5 seeds × 2 bandwidth methods: 28.6–32.1%, per-run bootstrap
95% CIs ≤ ±1 pp; exact full-population 2-D histogram cross-check: 31–33% across bin
widths). KW's log-density lies within the sampled range, slightly below the mean.
KW is **distributionally unremarkable on the non-circular dimensions**. Its only mild
deviation is `fft_peak_amplitude` at the exact 95.476th percentile (one-sided
p ≈ 0.045), which does not survive the project's look-elsewhere correction
(battery bars 1.8×10⁻³ / 5.5×10⁻⁴). Exact joint tail:
P(freq = 16 ∧ amp ≥ KW's) = 0.757% — ~26 million valid orderings sit at or beyond KW.
(Both dimensions carry the two scope caveats recorded above: they are computed on
the orientation-bearing sequence under an undeclared retention convention, and on
`k ∈ [1,31]` with the Nyquist bin excluded — see the schema-table caveat and
Appendix B.)

**Reproducing this figure — the public CLI does not reach it (gap recorded
2026-08-30).** The [Reproducibility](#reproducibility) section's
`solve.py --joint-density` runs the **seven-dimensional** analysis whose headline
is withdrawn above; it does not run this two-dimensional re-analysis. The
re-analysis's parameters exist in the code — `p2_joint_density_v2` accepts
`dims=`, `seed=` and `bandwidth_method=` — but `--joint-density-dims` and
`--joint-density-seed` are **not exposed on the command line**, and the CLI
dispatch passes neither. Consequently **no public invocation at this revision
reproduces the ≈ 30% figure, any of its five seeds, or the 2-D histogram
cross-check**, and the figure is published ahead of its public reproduction
command. The outstanding fix is to wire those two parameters through argparse and
document them in [SOLVE_PY_CLI.md](SOLVE_PY_CLI.md); the recipe that becomes
runnable is `solve.py --joint-density-v2 <chunks_dir> <out.md>
--joint-density-dims fft_dominant_freq,fft_peak_amplitude --joint-density-seed
<seed> --joint-density-bandwidth {silverman,cv}`, run once per recorded seed over
the `--compute-stats` parquet chunks of the sha-`915abf30…` 100 T canonical. The
per-run outputs (seeds, bandwidths, bin edges) are archived in
`roae-private/P2_JOINT_DENSITY.md` *(private staging repo — not publicly
accessible)*.

**Independent re-measurement (2026-08-30 — exact, full population, no
sampling).** Both feature columns were regenerated from the same sha-verified
`solutions.bin` and the statistic recomputed as an **exact full-population 2-D
joint histogram** — deterministic, no KDE, no seed, no bandwidth choice, no
subsampling. It reproduces the published values: the joint tail
`P(freq = 16 ∧ amp ≥ KW's) = 0.757%` **exactly**, and KW's percentile at
**29.32 / 31.01 / 33.85%** for amplitude bin widths 0.20 / 0.50 / 0.10 —
bracketing both the ≈ 30% headline and its "31-33% across bin widths"
cross-check. The exact histogram is a better instrument for this statistic than
the 5-seed KDE and is preferred if the figure is restated. Detail and evidence:
`roae-private/FINDING_FFT_NYQUIST_RECOMPUTE_RESULT_2026_08_30.md` *(private
staging repo — not publicly accessible)*.

## What this establishes

*Scope (all three claims below): every figure is a position **within the 100 T d3
canonical** (3,432,399,297 records, sha256 `915abf30…`) — a deterministic
budget-limited slice, not a random sample of the C1-C5 space. Figures derived
from `fft_dominant_freq` / `fft_peak_amplitude` additionally carry the two FFT
caveats recorded above: `k ∈ [1,31]` (Nyquist excluded) and the undeclared
orientation-retention convention.*

1. **KW is distributionally unremarkable on the KW-independent dimensions**
   (corrected 2026-07-26). On the two dimensions with KW-independent
   definitions (`fft_dominant_freq`, `fft_peak_amplitude`), KW's
   joint-density percentile is ≈ 30% — inside the population bulk of the
   3.43 billion C1-C5 valid orderings. The previously claimed joint
   atypicality ("rank < 10⁻⁵") was driven entirely by KW-referencing
   dimensions and is withdrawn (see the re-analysis section above).

2. **The marginals table remains a valid descriptive record.** KW's extreme
   marginal placements are confined to the KW-relative and KW-extracted
   dimensions (where they are guaranteed or near-guaranteed by
   construction); on the KW-independent dimensions KW is near the median
   in `fft_dominant_freq` (29%-ile, a bulk-typical value) and at the
   95.5th percentile in `fft_peak_amplitude` — a mild deviation that fails
   the project's look-elsewhere bars.

3. **Two of the proposed observable dimensions are structurally invariant**
   across all C1-C5 valid orderings: `mean_transition_hamming` and
   `max_transition_hamming`. This is itself a structural finding — **C5**,
   the transition-budget constraint, forces the transition-Hamming
   distribution to be identical across every valid ordering (Appendix A);
   C1 and C2 only restrict the support. *(Corrected 2026-08-30 from
   "the C1+C2 constraint forces …".)*

## What this does not establish

- **Not a uniqueness proof — and the original version of this analysis was
  itself an instance of the extraction problem.** Recall from
  [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md#an-important-caveat): specific "KW-property extraction"
  can make almost any C1+C2 ordering appear uniquely determined. An earlier
  version of this document claimed the analysis "avoids that extraction
  problem by using dimensions chosen for general information content";
  the 2026-07-26 circularity audit found the opposite — five of the seven
  KDE dimensions were KW-referencing, and the withdrawn joint-density
  headline was the predicted signature of that extraction.
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
- **Joint density — the withdrawn 7-dim headline:** `solve.py --joint-density`
  (sklearn KDE + bootstrap). This reproduces the figures **withdrawn as evidence**
  in 2026-07-26 and retained only in [HISTORY.md](HISTORY.md); it does *not*
  reproduce the ≈ 30% de-circularized result.
- **Joint density — the de-circularized 2-dim ≈ 30% headline:** no public
  invocation reproduces it at this revision. `p2_joint_density_v2` accepts
  `dims=`/`seed=`, but neither is wired to a CLI flag. See §"Joint density —
  de-circularized re-analysis" for the recipe and the outstanding fix.
- All four subcommands consolidated into `solve.py` on 2026-04-21 per the
  single-Python-file rule; previously lived as `scripts/compute_stats.py`,
  `scripts/p2_marginals.py`, `scripts/p2_bivariate.py`,
  `scripts/p2_joint_density.py` in the staging repo.
- **Archived outputs:** `P2_MARGINALS.md` and `viz/` in the **private staging repo (not publicly accessible)**,
  `roae-private/P2_JOINT_DENSITY.md` *(private staging repo — not publicly accessible)*

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
counts match this exact vector. (See `init_kw_dist` in `solve.c`, which
populates `kw_dist[]`, and every step of `backtrack`, which
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

The concentration at k=16 means that, **in the received integer encoding of the
hexagrams**, the strongest oscillatory structure in KW's value sequence has a
period of exactly 4 positions — i.e., the signal approximately repeats every
2 pairs (each pair occupies 2 positions).

**Encoding-scoped: this reading is a property of the labels, not of the
ordering (added 2026-08-30).** The FFT is taken over raw integer hexagram IDs,
which are *not* invariant under the order-48 bit-permutation group that
[TR-5](../reports/TR5_SYMMETRY.md) proves leaves C1-C5 exactly invariant.
Applying the bit permutation (2, 0, 4, 1, 5, 3) to every hexagram value carries
King Wen to an **exact structural twin** — still C1-C5-valid, still C3 = 776 —
whose `(fft_dominant_freq, fft_peak_amplitude)` is **(21, 264.9626)** rather
than (16, 374.7666). The twin's dominant period is 64/21, not 4. TR-5 §6 states
the doctrine plainly: *"any statistic not invariant under S₄ record-relabeling
is measuring the labeling."*

```bash
python3 -c "
import solve, numpy as np
KW = solve.binary_hexagrams
P = (2, 0, 4, 1, 5, 3)                 # a member of TR-5's order-48 group
sig = lambda h: sum(((h >> b) & 1) << i for i, b in enumerate(P))
for nm, q in (('KW', KW), ('sigma(KW)', [sig(h) for h in KW])):
    x = np.array(q, dtype=np.float32); x = x - x.mean()
    a = np.abs(np.fft.fft(x)[1:32])
    print(nm, int(a.argmax()) + 1, round(float(a.max()), 4),
          'C3', solve.total_complement_distance_c3(q))
"
# KW 16 374.7666 C3 776   |   sigma(KW) 21 264.9626 C3 776
```

The percentile *arithmetic* is unaffected — the C1-C5 population is closed under
the group, so KW's position within a **fixed** encoding is well defined, and the
≈ 30% / 0.757% / 95.476th-percentile figures stand as encoding-scoped statements.
What does not survive is the mechanistic reading: the period-4 interpretation
below is scoped to the received binary encoding and is **not** a structural
property of the sequence. The invariant alternatives — line-channel spectra with
a permutation-invariant aggregation, or a published orbit-sensitivity census over
all 48 transforms — have not been computed.

**Marginal-distribution comparison (refinement of the earlier marginal result).**

From the 3.43B-record marginal analysis (all counts below are
**`k ∈ [1,31]`-scoped** — see the Nyquist note that follows):

- Records with `fft_dominant_freq < 16`: 776,656,635 (22.6%)
- Records with `fft_dominant_freq = 16`: **433,156,350** (**12.62%** — the
  **second-largest** bin; the mode is **k = 30** with 493,989,408 records,
  14.39% — *corrected 2026-07-26; this line previously called k = 16 the
  "largest single bin"*)
- Records with `fft_dominant_freq > 16`: 2,222,586,312 (64.8%)

So KW's k=16 is a **bulk-typical value** — the second-largest bin of the
fft_dominant_freq distribution, not a rare value (*corrected 2026-07-26
from an earlier claim that k = 16 was itself the mode; the exact full
histogram puts the mode at k = 30*). The "29th percentile"
report for KW reflects the standard convention (half-bin rank among tied
records), not rarity — KW shares its dominant frequency with 433 million
other C1-C5 valid orderings.

**Interpretation.** Period-4 structure is common across valid orderings
because the pair structure (C1) creates a natural length-2 alternation
(the a-then-b within each pair), and the aggregation of 32 such
alternations produces frequency content concentrated at or near the
**Nyquist bin** (k = 32 in a length-64 FFT) and its nearby bins. *(Corrected
2026-08-30: this read "half-Nyquist"; k = 32 **is** Nyquist for a length-64
signal, not half of it.)*

**k = 32 cannot appear in the histogram above — it is excluded by construction,
not absent from the data (added 2026-08-30).** The feature extractor computes
`amp = np.abs(F[:, 1:32])` (`solve.py`, `--compute-stats`), and the upper bound
of a NumPy slice is exclusive, so `fft_dominant_freq` ranges over `k ∈ [1,31]`
only and the Nyquist bin is never a candidate — even though k = 32 is exactly
where C1's within-pair a/b alternation (period 2) lands. An earlier revision of
this paragraph asked why the mass concentrates "at bins like k = 30 and k = 16
rather than exactly at k=32" and answered that it "requires deeper analysis";
the question was malformed — the pipeline forbids the answer it was looking for.
The residual observation still holds for the bins that *are* available: the pair
structure is not strictly periodic (different pairs have different Hamming
distances between their a and b), so period-2 content spreads across nearby bins.

**Measured impact of the exclusion (2026-08-30 — exact, full population).** The
extractor was re-run over the same 3,432,399,297-record 100 T canonical
(sha256 `915abf30…`) with the one-line fix `F[:, 1:33]`, and the two feature
columns compared cell-by-cell against the published ones:

- **3,496,831 records (0.1019%) change cell** — exactly those whose true
  spectral peak sits at Nyquist, which the fix moves to a new `k = 32` row. No
  other record moves. The truncation therefore **re-ranked** those records; it
  was not a uniform relabeling.
- **King Wen is not among them.** KW's Nyquist magnitude is **58.0** against a
  peak of 374.77, so bin 32 never wins for KW and its `(16, 374.766571)` is
  identical under both slices.
- **The published headline does not move:** ≤ **0.10 pp** at every amplitude bin
  width tested (29.32 → 29.41% at width 0.20; 31.01 → 31.10% at 0.50;
  33.85 → 33.84% at 0.10), an order of magnitude inside the published 28.6-32.1%
  seed spread — and the exact joint tail `P(freq = 16 ∧ amp ≥ KW's) = 0.757%` is
  unchanged.

**No published figure in this document requires revision on this account.** The
`k ∈ [1,31]` scope label is kept because the histogram above was computed under
the old slice. The fix `F[:, 1:33]` is correct on its own terms — 3.5 M records
carried a wrong dominant frequency and a wrong peak amplitude — and had not
landed in the public extractor as of 2026-08-30. Detail and evidence:
`roae-private/FINDING_FFT_NYQUIST_RECOMPUTE_RESULT_2026_08_30.md` *(private
staging repo — not publicly accessible)*.

```bash
python3 -c "
import solve, numpy as np
x = np.array(solve.binary_hexagrams, dtype=np.float32); x = x - x.mean()
F = np.abs(np.fft.fft(x))
print('published slice k in [1,31]:', int(F[1:32].argmax()) + 1, round(float(F[1:32].max()), 6))
print('fixed slice     k in [1,32]:', int(F[1:33].argmax()) + 1, round(float(F[1:33].max()), 6))
print('KW Nyquist magnitude |F[32]| =', round(float(F[32]), 1))
"
# published slice 16 374.766571 | fixed slice 16 374.766571 | Nyquist 58.0
```

**The scientific refinement:** the earlier marginal writeup overstated
KW's fft_dominant_freq "distinctiveness." KW is in the distribution
bulk for this dimension (second-largest bin), not the tail. A
bulk-typical value is not distinguishing. This is an important
correction for the joint-density narrative.

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
Chan finds KW at extreme tails of his unconstrained-permutation
baselines (mean Hamming, lag-1 autocorrelation, asymmetry findings);
ROAE's de-circularized re-analysis (2026-07-26, above) finds KW
distributionally unremarkable *within* the constraint-satisfying
population on the KW-independent dimensions — not a contradiction,
since the baselines and questions differ. Where these analyses
overlap on common observables (mean Hamming, alternation), Chan's
prior art is acknowledged — see [CITATIONS.md](CITATIONS.md) and
[SOLVE.md](SOLVE.md) / [CRITIQUE.md](CRITIQUE.md) for inline citations.

## Trigram-level addendum (2026-07-03)

The inferential trigram extension ([`roae.py --trigrams`](ROAE_PY_CLI.md)) places KW's trigram-level statistics against a
**C1-only null**, not against this document's C1-C5 canonical population ⚠ **[CORRECTED 2026-08-30 — this
read "in the same pair-preserving null framework used throughout this document". It is not the same
framework, and two different nulls in fact coexist in this addendum under that one label. `roae.py
--trigrams` builds its 10,000-ordering null by shuffling all 32 King Wen pair blocks and randomizing each
block's orientation — that imposes **C1 and nothing else**: no C2, no C3, no C4, no C5 — whereas every
other analysis in this document is computed over the budgeted C1-C5 canonical. The Classic-ends figure,
separately, conditions on C4 analytically. The canonical-population versions of the figures below are
**unmeasured**.]** Each figure is labelled with the null it was actually computed against.

**`C1-only null`** — upper/lower trigram change rates are
population-typical (47th/27th percentile).

**`C1+C4 null`** — the pure-hexagram Classic-ends concentration is **unremarkable
once its own caveat is computed** (4/6; constrained null **P = 87/465 = 0.187**, exact) ⚠ **[CORRECTED
2026-08-28 — this read "mildly notable (4/6, null P = 0.034, with the C4-fixes-two-positions caveat)".
The caveat named the right baseline and **nothing ever computed it**: the sampler shuffles all 32 pair
blocks, so 0.034 = 43/1240 is the UNCONSTRAINED null. C4 pins the pure block {63,0} into pair slot 1,
which is already an end slot, so the constrained question is whether ≥1 of the remaining 3 pure blocks
falls in slots {15,32} among 31: P = 1 − C(28,2)/C(31,2) = **87/465 = 0.1871**, exact, no simulation
needed. That is **5.40×** the published value and the verdict reverses — "mildly notable" does not
survive its own stated caveat. Verified two algebraic ways and by Monte Carlo (0.1869, 2×10⁶ draws).
The 0.034 is retained above only as the unconstrained comparison.]**

**`C1-only null`** — **no significant monotonic rank correlation was detected** between King Wen's positions
and Jing Fang's palace ordering (Spearman rho = 0.14, C1-only null P = 0.12, n = 64) ⚠ **[CORRECTED
2026-08-30 — this read "KW is statistically independent of Jing Fang's palace ordering … while being
organizationally unrelated". P = 0.12 is a **failure to reject** the no-monotonic-association null. It
establishes neither independence (a null cannot be accepted) nor the absence of non-monotonic dependence
(Spearman's alternative covers monotonic rank association only), and at n = 64 the power against small
effects is limited. The supported statement is the one now given. Claiming the orderings are
organizationally unrelated would require an equivalence test against a declared effect bound; none has been
run.]** The two great classical orderings do share constraint principles (both avoid 5-line transitions;
see the no-5 shared-property analysis).

The nuclear-map terminal set {0, 21, 42, 63} coincides exactly with C4's fixed
pair plus the final alternating pair — a classical fact whose alignment with the sequence's anchors is
noted without a significance claim (it is a property of the hexagram set, not of the ordering).

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*

*Revision 2026-07-22 (C3 scope-consistency sweep): `c3_total`'s 95.04th-percentile marginal is guaranteed by the C3 ≤ 776 population filter (the canonical is truncated at KW's own value), so it is no longer counted as one of the joint-KDE outlier drivers — "4 of 8 extreme dimensions" is restated throughout as "3 of 8, plus one by construction". The only informative content of the `c3_total` marginal is its ceiling-tie share (9.9% at 100T). The KDE itself was not re-run; whether the joint-outlier magnitude changes with `c3_total` excluded is explicitly left open. No numbers in the tables changed.*

*Revision 2026-08-30 (prose-correction batch P08 — scoping and null labels; **no measured value in any table changed**): (1) the opening framing no longer describes the partial-enumeration data as a random sample of the constraint space — every cell contributes a deterministic budget-limited DFS prefix, so the figures are exact-for-the-100 T-slice and scoped to it; (2) the "560 T shifts will be small because the CIs are tight" argument is withdrawn — CI width bounds resampling variation inside the algorithm-selected slice, not selection, and TR-5 §5 measures the selection effect directly (KW present at 560 T, all 23 twins absent); (3) the invariant transition-Hamming distribution is re-attributed from "C1+C2" to **C5**, matching Appendix A's own proof, with C1/C2 credited only for the support restrictions (two sites); (4) the two FFT dimensions are labelled with the two scope caveats they carry — an **undeclared orientation-retention convention** (9 of KW's 31 single-slot orientation flips are C1-C5-valid and span `fft_peak_amplitude` 343.24-403.11) and an **encoding dependence** (the order-48 relabeling group carries KW's (16, 374.7666) to a valid twin's (21, 264.9626), so Appendix B's period-4 mechanism is encoding-scoped, not structural); (5) the Nyquist bin k = 32 is documented as **excluded by construction** by `amp = np.abs(F[:, 1:32])`, the "half-Nyquist" mislabel is corrected, and the malformed "why not exactly k = 32?" question is retired — with the 2026-08-30 exact full-population recompute recorded: 3,496,831 records (0.1019%) change cell, KW is not among them (Nyquist magnitude 58.0 vs peak 374.77), the headline moves ≤ 0.10 pp and the 0.757% joint tail is unchanged; (6) the ≈ 30% headline is flagged as **published ahead of its public reproduction command** — `solve.py --joint-density` runs the withdrawn 7-dim analysis, and `--joint-density-dims`/`--joint-density-seed` are not wired to the CLI; (7) the trigram addendum's figures are relabelled with the nulls actually used (**C1-only** shuffle; **C1+C4** analytic for 87/465), not "the same framework used throughout this document"; (8) "KW is statistically independent of Jing Fang's palace ordering" is corrected to "no significant monotonic rank correlation was detected" (P = 0.12 is a failure to reject). Reproduction commands for the FFT figures in (4) and (5) are inline in the document.*

*Revision 2026-07-26 (de-circularization): the joint-KDE headline ("rank < 10⁻⁵", "log-density −128,260, ~12,800× lower") is **withdrawn as evidence** — an adversarial circularity audit found five of the seven KDE dimensions KW-referencing (two tautological, two KW-extracted, one extreme by population construction). The section is replaced by the honest re-analysis on the two KW-independent FFT dimensions (KW joint-density percentile ≈ 30%, distributionally unremarkable); the schema table's Family column is reclassified accordingly; Appendix B's "k = 16 is the mode" is corrected (the mode is k = 30 at 14.39%; k = 16 is the second-largest bin at 12.62%); and the queued 560 T re-run is descoped. Marginal counts, the invariance theorem, and all shas are unchanged.*
