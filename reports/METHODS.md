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
  `Σ_{v∈H} |pos(v) − pos(v̄)|` **≤ 776** (the sum runs over all **64** hexagrams — hence mean cd = 776/64 = 12.125; notation corrected 2026-08-01 from `Σ_pairs`, which would halve it) (equivalently mean complement distance cd(S) ≤ 12.125). **The bound is a
  ceiling, not an equality: King Wen attains it exactly (776), and any ordering with a smaller sum also
  satisfies C3** (e.g. the wrap-d5 witness at 752). The threshold 776 is King Wen's own value —
  reverse-engineered, not derived; priced as circular in [TR-9](TR9_PRICING_THE_CONSTRAINTS.md).
- **C4 — fixed opening pair, defined orientation.** The first pair is {Qian(63), Kun(0)}; its orientation
  (Heaven 63 before Earth 0) is **definitional and classically attested** (the Xugua opens
  Heaven-then-Earth). It is NOT forced by the other constraints — complementation (x ↦ x ⊕ 63) is an
  exact symmetry of C1∩C2∩C3∩C5 broken only by oriented C4, machine-checked in
  [lean/KingWen.lean](../lean/KingWen.lean) *(the former "Theorem 6" forced-orientation claim is
  retracted, 2026-07-26 — see CLAIMS_DECIDED's corrections ledger)*. [TR-9](TR9_PRICING_THE_CONSTRAINTS.md)
  already prices C4 at its full 6 bits (pair + orientation), so no ledger value moves.
- **C5 — transition-distance multiset.** The multiset of all **63** consecutive-hexagram Hamming distances
  equals King Wen's: **{1:2, 2:20, 3:13, 4:19, 6:9}** ([SPECIFICATION.md](../documentation/SPECIFICATION.md) §C5).
  Extracted from KW (confirmatory, not predictive). *(Corrected 2026-08-01: this read "the 31 between-pair
  boundary Hamming distances … {1:2, 2:8, 3:13, 4:7, 6:1}". That multiset is **not the definition of C5** —
  it is the machine-checked theorem `boundary_budget_general` (lean/TrigramTheorems.lean), which DERIVES the
  boundary budget from C1 + full C5. Stating the theorem's conclusion as the constraint's definition made the
  theorem vacuous, and broke the very next bullet: C2 is implied by the 63-transition histogram directly, but
  from a boundary-only multiset only via C1's within-pair-evenness theorem. The two are equivalent **given
  C1**; as free-standing predicates they are different constraints.)*
- **C6, C7 — identifying adjacency pins.** Specific slot-24–27 adjacency choices used only to single out
  King Wen within the C1–C5 family (they cut the space by ×2.55×10⁶ but leave ≈5.21×10³¹ orderings —
  [TR-4](TR4_SIZE_OF_THE_SPACE.md) §4). Not part of the enumerated canonical constraint set; data-like,
  priced ≈0 in [TR-9](TR9_PRICING_THE_CONSTRAINTS.md).

The minimum independent rule set is {C1, C3, C4, C5} (SPECIFICATION.md §Numbering note). "The space" in
the reports means the **C1–C5** population unless stated otherwise.

**Legacy shorthand — "C1+C2+C3" means the same thing (note added 2026-08-01).** Several older passages
(and `solve.c`'s own console strings) describe the canonical enumerated population as "C1+C2+C3". That
is **historical naming, not a narrower constraint set**: the enumerator's counter is called `solutions_c3`
but, as its own source comment states, *"C3-valid" = passed ALL constraints (C1-C5), not just C3*
(`solve.c:865`) — and `solve --verify` confirms every canonical record satisfies C1–C5
(CANONICAL_HASHES §"d3 560T", CAMPAIGN_METHODOLOGY §7). Read "the C1+C2+C3 canonical" as
**the C1–C5 canonical** wherever it appears. New text should say C1–C5.

## Canonical quantities (single source of truth)

Every load-bearing integer in the suite, with its status, counting convention, and source report. Where
two numbers differ, they differ by **convention** (orientation-raw vs orientation-deduplicated vs
orbit-quotient), not by disagreement.

| Quantity | Value | Status | Convention | Source |
|---|---|---|---|---|
| C1–C5 space size | 1.3287×10³⁸ (95% CI [1.3283, 1.3292]×10³⁸, 0.02%) | **estimate** (Knuth) | raw (orientation-resolved) | [TR-4] §3 |
| C1–C5 space size | ≈3.3×10³⁷ | **estimate** | orientation-dedup | [TR-4] §Abstract |
| \|C1∩C2∩C4\| | 757,058,601,340,255,440,651,419,713,405,330,315,358,208 ≈ 7.5706×10⁴¹ | **exact** (two-instrument — independently recomputed at full scale 2026-07-25 by `verify.c --ie-count --ie-no-budget`, exact MATCH; mod-24 gated) | raw (orientation-explicit, C4 pinned) | [TR-11] §1–4 |
| \|C1∩C2∩C4∩C5\| | 1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097051×10³⁹ | **exact** (two-instrument: independently recomputed at full scale 2026-07-25 by the verify.c IE transfer-walk engine — exact MATCH; mod-24 + ladder-corroborated) | raw (orientation-explicit, C4 pinned) | [TR-11] §9 |
| \|C1–C7\| | 5.21×10³¹ (95% CI [5.13, 5.29]×10³¹, 0.78%) | **estimate** | raw | [TR-4] §4 |
| \|C1–C7\|, C3 dropped | 516,880,238,445,773,965,371,923,491,676,160 ≈ 5.16880×10³² | **exact** (two-instrument — (i) IE pinned-step recount 2026-07-25, `verify.c --ie-pin-c6c7 --ie-no-quotient`, small-n-validated 52/52, 3-prime-CRT self-consistent; (ii) independent direct mask-DP recount 2026-07-26, `verify.c --dp-count --dp-pin-c6c7` — a different algorithm class (explicit exact-cover subset DP with polynomial budget-coefficient extraction, no inclusion–exclusion, sharing only the problem spec), small-n-validated 44/44 incl. three-way vs brute force, matched the same integer exactly; mod-24 N/A under pins; lands inside the prior 5.18×10³² estimate's 0.25% CI, ~0.22% below the point estimate — a 3rd independent estimator-calibration anchor) | raw | [TR-4] §4 |
| Symmetry group (sequence level) | 48 (B₃ ≅ Z₂≀S₃) | **proven** (finite gates + classical closure) | — | [TR-5] |
| Symmetry group (record level) | 24 (S₄); free action | **proven** | orbit | [TR-5] |
| Twins per solution | 23 (orbit size 24) | **proven** | orbit | [TR-5] §4 |
| Orbit count \|C1∩C2∩C4∩C5\|/24 | 45,710,469,949,549,241,251,504,669,632,357,466,112 | **exact** (= N/24 of the two-instrument count above; the recomputed N is ≡ 0 mod 24, so the division is exact) | orbit | [TR-11] §9 |

*All three exact full-scale quantities — \|C1∩C2∩C4\| (via `--ie-no-budget`), the C5-layer count
\|C1∩C2∩C4∩C5\|, and its orbit count — are **two-instrument** as of 2026-07-25: independently
recomputed at full scale by `verify.c`'s inclusion–exclusion transfer-walk engine (`--ie-count`;
build: `cc -O2 -o verify verify.c -lz -lpthread` — see [VERIFY.md](../documentation/VERIFY.md)
— a different algorithm class sharing no code or machinery with `solve.c`; exact MATCH, mod-24
verified), additionally corroborated by the mod-24 gate and the 4/4 out-of-core ladder +
identical cross-mode layer content (byte-identical in the v1-format validation runs; under
current defaults the two modes' files are content-identical but byte-different — [TR-11]
§10(vi) precision note).*

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
  global ledger the corresponding bar is 0.05/91 ≈ **5.5×10⁻⁴**.
  **Scope disclosure (added 2026-08-01, after an itemised roster was built from the frozen
  pre-registrations).** The 91 counts *tests performed under registered corrections*, not distinct
  observables, and it is **deliberately retained as the conservative choice**. Two offsetting facts:
  (i) the "Davis /9" and "Davis follow-up /12" components are **not disjoint** — the R8 pre-registration
  freezes the /12 as "the full cross-wave Davis family (9 wave-1 + 3 wave-2 maximum)", so the nine are
  re-counted inside the twelve, and the distinct Davis contribution is 12, giving **82 distinct
  observables**; (ii) the ledger omits the **F6 books family** (7 functionals, frozen and measured
  2026-07-05), so a strict "everything examined" reading gives **89**. The two errors nearly cancel.
  **All three candidate bars — 0.05/91 = 5.49×10⁻⁴, 0.05/89 = 5.62×10⁻⁴, 0.05/82 = 6.10×10⁻⁴ — span
  under 11%, and NO published verdict differs between them** (the only value in the gap zone,
  `dav_trigarray` at 6.8×10⁻⁴, fails at all three). The published bar is therefore the strictest
  defensible choice, and no conclusion in the suite depends on the count.
  **Correction-family disclosure (added 2026-08-01, self-reported).** The sentence above is scoped to
  the three *denominators*; it says nothing about the choice of *correction family*, and that choice is
  not neutral. The suite applies **Bonferroni (family-wise error rate)** throughout, and the global-ledger
  layer was added on 2026-07-11 — **after** the measurements it adjudicates. Under **Benjamini–Hochberg
  FDR** at q = 0.05 the same 91-observable ledger would reach a different verdict on exactly one value:
  `dav_trigarray` (6.8×10⁻⁴) would be **declared significant**, and not marginally — the ledger contains
  at least a dozen smaller p-values (`ccn4` 2×10⁻⁸, `ccn8` 2.6×10⁻⁷, `ccn3` 6.6×10⁻⁶, `dav_rotinv`
  6.5×10⁻⁵, …), so its BH rank *i* puts the threshold *i*·0.05/91 an order of magnitude above it. That
  is the *only* verdict in the suite the family choice moves, and it moves the one result most favourable
  to the hypothesis this suite argues against. Two facts keep the published reading defensible, and both
  are stated rather than assumed: (i) FWER is the strictly more conservative family, so **every claim
  that the suite reports as *clearing* the bar clears it under BH as well** — nothing in the positive
  direction depends on this; (ii) the exposure is entirely in the negative direction, on one Davis
  observable, and it is disclosed here rather than left for a reader to discover. A reader who prefers
  FDR control should read `dav_trigarray` as surviving global correction and everything else unchanged.
  **Counting rule going forward:** an observable enters the ledger exactly once, at first registration,
  under a stable id; a family's Bonferroni denominator may span waves and exceed its new-id count; and
  this total must be **derived from the itemised roster**, never stated independently of it; and each
  "notable" verdict states in place whether it clears that bar. Model comparisons (the TR-2 Bayes factors) are **not** observables
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
1. **Nothing**: DRAT certificates (drat-trim), **kernel-checked** Lean theorems, the two-line parity proofs.
   *(Qualified 2026-08-01: this read "Lean theorems (kernel)" without restriction. A disclosed subset of the
   suite's Lean theorems is proved by `native_decide`, which trusts Lean's **compiler** rather than its kernel —
   TrigramTheorems §4a–§6, PartitionInvariance §12, PruneGInvariance §1+§8, and all of SymmetryCompleteness.
   Those belong one rung lower in spirit: they require trusting no project code, but they are not kernel-checked.
   The per-file inventory is in [lean/README.md](../lean/README.md) §Trust base; this was the one place in the
   suite where a distinction maintained everywhere else was flattened.)*
2. **Only the encoder** (validated by KW-value gates + two-way SAT tests): the conflict theorem's rule
   faithfulness.
3. **The instrument stack** (cross-validated two-language + self-check): population fractions, estimator
   counts.
Every report's Verification Guide tags its claims with the rung they sit on.
