# Shared Methods Appendix — environment, statistics, and artifact access
*Referenced by every technical report's Verification Guide. Addresses the systemic gaps identified by
the adversarial replication reviews (archived alongside this suite).*

## Constraint set (C1–C5, and the identifying C6/C7)

Every report measures the same object. The formal predicates (full statements + theorems:
[SPECIFICATION.md](../documentation/SPECIFICATION.md)):

- **C1 — classical pairing.** The 64 hexagrams form 32 consecutive pairs, each a hexagram and its
  reverse (or, for the 8 self-reverse hexagrams, its complement) — the Yu Fan / Lai Zhide pang-tong/fan-dui
  structure. Radisic (2026) proves this is the unique Hamming-cost-minimizing comp/rev matching.
- **C2 — no distance-5 transition.** No adjacent transition has Hamming distance 5. (Mathematically
  implied by C5's histogram; retained as an O(1) boundary pre-filter.)
- **C3 — complement-proximity ceiling.** For the ×64 integer representation, the complement-distance sum
  `Σ_pairs |Δpos|` **≤ 776** (equivalently mean complement distance cd(S) ≤ 12.125). **The bound is a
  ceiling, not an equality: King Wen attains it exactly (776), and any ordering with a smaller sum also
  satisfies C3** (e.g. the wrap-d5 witness at 752). The threshold 776 is King Wen's own value —
  reverse-engineered, not derived; priced as circular in [TR-9](TR9_PRICING_THE_CONSTRAINTS.md).
- **C4 — fixed opening pair, forced orientation.** The first pair is {Qian(0), Kun(63)}; its orientation
  is a theorem (Theorem 6), not an extracted parameter. Independently attested (Xugua commentary).
- **C5 — transition-distance multiset.** The multiset of the 31 between-pair boundary Hamming distances
  equals King Wen's: {1:2, 2:8, 3:13, 4:7, 6:1}. Extracted from KW (confirmatory, not predictive).
- **C6, C7 — identifying adjacency pins.** Specific slot-24–27 adjacency choices used only to single out
  King Wen within the C1–C5 family (they cut the space by ×2.55×10⁶ but leave ≈5.21×10³¹ orderings —
  [TR-4](TR4_SIZE_OF_THE_SPACE.md) §4). Not part of the enumerated canonical constraint set; data-like,
  priced ≈0 in [TR-9](TR9_PRICING_THE_CONSTRAINTS.md).

The minimum independent rule set is {C1, C3, C4, C5} (SPECIFICATION.md §Numbering note). "The space" in
the reports means the **C1–C5** population unless stated otherwise.

## Canonical quantities (single source of truth)

Every load-bearing integer in the suite, with its status, counting convention, and source report. Where
two numbers differ, they differ by **convention** (orientation-raw vs orientation-deduplicated vs
orbit-quotient), not by disagreement.

| Quantity | Value | Status | Convention | Source |
|---|---|---|---|---|
| C1–C5 space size | 1.3287×10³⁸ (95% CI [1.3283, 1.3292]×10³⁸, 0.02%) | **estimate** (Knuth) | raw (orientation-resolved) | [TR-4] §3 |
| C1–C5 space size | ≈3.3×10³⁷ | **estimate** | orientation-dedup | [TR-4] §Abstract |
| \|C1∩C2∩C4\| | 757,058,601,340,255,440,651,419,713,405,330,315,358,208 ≈ 7.5706×10⁴¹ | **exact** (single-instrument; mod-24 gated) | raw (orientation-explicit, C4 pinned) | [TR-11] §1–4 |
| \|C1∩C2∩C4∩C5\| | 1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097051×10³⁹ | **exact** (single-instrument; mod-24 + ladder-corroborated, not independently recomputed) | raw (orientation-explicit, C4 pinned) | [TR-11] §9 |
| \|C1–C7\| | 5.21×10³¹ (95% CI [5.13, 5.29]×10³¹, 0.78%) | **estimate** | raw | [TR-4] §4 |
| \|C1–C7\|, C3 dropped | 5.18×10³² (0.25%) | **estimate** | raw | [TR-4] §4 |
| Symmetry group (sequence level) | 48 (B₃ ≅ Z₂≀S₃) | **proven** (finite gates + classical closure) | — | [TR-5] |
| Symmetry group (record level) | 24 (S₄); free action | **proven** | orbit | [TR-5] |
| Twins per solution | 23 (orbit size 24) | **proven** | orbit | [TR-5] §4 |
| Orbit count \|C1∩C2∩C4∩C5\|/24 | 45,710,469,949,549,241,251,504,669,632,357,466,112 | **exact** (single-instrument) | orbit | [TR-11] §9 |

*"Single-instrument" exact counts are corroborated by the mod-24 free-action gate and (for the C5 layer)
the 4/4 out-of-core ladder + identical cross-mode layer content (byte-identical in the v1-format
validation runs; under current defaults the two modes' files are content-identical but byte-different —
[TR-11] §10(vi) precision note), but have not been independently recomputed at full scale ([TR-11] §10(vi)).*

## Environment (version pinning)
| Component | Version | Source |
|---|---|---|
| Repository | pin to the release tag stamped at publication (git tag per suite version) | [github.com/petersm3/roae](https://github.com/petersm3/roae) |
| C toolchain | gcc (Ubuntu 22.04 class), flags: `-O2 -pthread -fopenmp` (canonical); `-march=native` allowed for estimator-only runs | — |
| solve.c selftest anchor | sha256 `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e` | every commit gate |
| Python | 3.10+ stdlib-only (solve.py, sat.py, roae.py, verify.py) | — |
| SAT solver | kissat 4.0.4 (build from source) | [github.com/arminbiere/kissat](https://github.com/arminbiere/kissat) |
| Proof checker | drat-trim (2024+ master) | [github.com/marijnheule/drat-trim](https://github.com/marijnheule/drat-trim) |
| Lean | 4.31.0 via elan; core only (no mathlib) | `lean lean/KingWen.lean` exits 0 |

## Data-like vs principled constraints (the circularity firewall) — F-23

Several conclusions in this suite turn on whether a constraint is **principled** (stated independently of
King Wen, so King Wen's compliance is evidence) or **data-like** (a specific configuration read off King
Wen, so its compliance is near-tautological and carries little evidential weight). The distinction has
been applied case-by-case; the operational test it encodes is:

> A constraint is **data-like** if its statement fixes a specific configuration extracted from the
> received order — i.e. it can be written as "positions/values match King Wen's" with **≥1 fitted
> degree of freedom read from KW** and no independent derivation. It is **principled** if it is stated as
> a general rule (an author's design principle, a symmetry, an optimality criterion) whose form does not
> reference King Wen's particular values, so that a different valid ordering could have failed it.

Operationally: count the degrees of freedom the constraint's **stated form** borrows from King Wen —
*not* the KW-level at which a measurement functional happens to be thresholded. (A principled rule such as
Schulz gender is measured against KW's own violation count, but its *statement* — a parity condition on
consolidated units — borrows no KW-specific value; it stays principled. The dof count is on the rule as
its author stated it.) Zero borrowed dof in the statement → principled; each fitted slot, value, or
threshold baked into the rule's definition is one borrowed dof, and a constraint with ≥1 is priced as data (its "rarity" is specification, not discovery — see the dof-matched baseline in
[TR-8](TR8_REORDERING_REVISITED.md) and [CRITIQUE.md](../documentation/CRITIQUE.md) Q1). Borderline cases
(C3's 776 threshold, the S25–28 trigram configuration) are classified data-like precisely because their
defining number or face-set is KW's own. This is the firewall that keeps a fitted description from being
reported as a design finding; where a result depends on the classification, the report states which side
the constraint falls on and why.

## Statistics conventions
- **Knuth estimator CIs**: probes are i.i.d.; for each reported quantity the per-probe weight X and X²
  are accumulated exactly, and the tool prints mean ± 1.96·√(v̂ar/N) with relerr = SE/mean — a standard
  Wald CI on Knuth's (1975) unbiased estimator. Weighted fractions (masses of canonical weight) are
  same-run ratios ΣWX/ΣW; for fractions ≪ 1 the delta-method variance reduces exactly to the numerator's
  own relative variance, so a fraction's honest relerr equals the relerr of its numerator. S(k)-style
  ratios of separate runs add relative variances (the whole-space denominator's 0.02% is negligible).
  Caveats: weights are right-skewed, so CIs at low effective sample size (n_eff = 1/relerr²; e.g. relerr
  10% → n_eff ≈ 100) are approximate and skew toward underestimation — figures at ≥10% relerr should be
  read as ±20% with ~90–93% practical coverage; zero-hit estimates print 0 with a degenerate CI and are
  reported as starvation, not as bounds. PRNG seeds are fixed constants: re-runs at identical (probes,
  threads) reproduce identical output (a reproducibility feature; runs at the same thread count and
  different probe counts share stream prefixes and are not independent draws). CIs degrade visibly at hit
  rates below ~10⁻⁷ per probe; every reported number states its probe count.
- **Permutation-test nulls**: seeded (`random.Random(42)` unless stated); N=10,000 default; the
  pair-preserving null = shuffle the 32 canonical pairs + independent uniform orientation flips, first
  pair fixed by C4 where stated.
- **Population fractions** are ratios of weighted canonical-leaf masses (orientation-resolved unless
  marked canonical); every scorer's rule semantics has a KW-value reproduction gate
  (`solve.py --registry-verify`) run before any measurement is trusted.
- **Global observable ledger (enterprise-wide multiple comparisons).** Bonferroni corrections in this
  suite are applied within each pre-registered family (F5 /11, F4′ /13, Davis /9, Davis follow-up /12,
  permutation /13). Family-wise control does not control the error rate of the whole enterprise. The
  enterprise-wide observable count is **frozen at exactly 91**: the 28 exploratory discovery-phase
  observables (roae.py sweep) + the five pre-registered testing families (F5 /11, F4′ /13, Davis /9,
  Davis follow-up /12, permutation /13 = 58) + the R7 corpus-control battery's five off-home predicates
  = 28 + 58 + 5 = **91** (itemization maintained in [CRITIQUE.md](../documentation/CRITIQUE.md)
  §"Observable-selection accounting"). The exploratory suite **is included** — it is the base of the
  count, not excluded. A per-family "notable" label is therefore a family-scoped claim; against the
  global ledger the corresponding bar is 0.05/91 ≈ **5.5×10⁻⁴**, and each "notable" verdict states in
  place whether it clears that bar. Model comparisons (the TR-2 Bayes factors) are **not** observables
  and do not enter this ledger. This accounting does not touch the suite's headline findings — the
  nulls, and the proven/certified impossibilities, which are deductive.

## Artifact access
- **Certificates (DRAT) and raw run outputs** ship publicly with the suite under `reports/certificates/`
  and `reports/evidence/` at publication (relocated from private staging — the verification story
  requires them public). Each cert pairs with the exact `sat.py --emit-cnf <target>` regeneration
  command; encodings are deterministic, so regenerated CNF + archived proof must check.
- **solutions.bin artifacts** are not distributed (size); they are re-derivable to the byte
  ([CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) per-anchor commands) and their shas are the scientific anchor.

## Independence ladder (what requires trusting project code)
1. **Nothing**: DRAT certificates (drat-trim), Lean theorems (kernel), the two-line parity proofs.
2. **Only the encoder** (validated by KW-value gates + two-way SAT tests): the conflict theorem's rule
   faithfulness.
3. **The instrument stack** (cross-validated two-language + self-check): population fractions, estimator
   counts.
Every report's Verification Guide tags its claims with the rung they sit on.
