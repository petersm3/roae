# Known Limitations

> **Note (2026-04-19):** Canonical reference counts re-established: d3 10T = **706,422,987** (sha `f7b8c4fb…`), d2 10T = **286,357,503** (sha `a09280fb…`). Older 742M figure (hash-table bug) superseded. **New partition-stability finding** from the 2026-04-19 analyze runs: boundaries {25, 27} are mandatory at BOTH d2 and d3 scales (stable), but the broader 4-boundary structure (`one-of-{2,3} ∪ one-of-{21,22}`) is **d2-specific**; at d3 the interchangeable boundaries are in the {1..6} range. Any claim involving specific boundaries beyond {25, 27} must be scoped to the partition depth. See updated sections below.

A review of the program's methodology, assumptions, and interpretive claims from a mathematical perspective.

## Data correctness

- The binary hexagram encodings follow [OEIS A102241](https://oeis.org/A102241) with bit 0 = bottom line. Sensitivity analysis confirms the difference wave, pair structure, and no-5 property are all invariant under bit reversal (since Hamming distance is invariant under bit permutation). Trigram assignments do change under reversal, affecting display labels but not mathematical results.
- The hexagram names are attributed to the [Wilhelm/Baynes translation](https://press.princeton.edu/books/hardcover/9780691097503/the-i-ching-or-book-of-changes) but several are simplified or variant. A rigorous treatment would cite each name individually, not give a blanket attribution.
- The [Mawangdui](https://en.wikipedia.org/wiki/Mawangdui_Silk_Texts) ordering was recomputed from trigram cycling rules, but the actual silk manuscript ordering has scholarly disagreements. The program treats one reconstruction as definitive.
- The sequence is traditionally attributed to [King Wen of Zhou](https://en.wikipedia.org/wiki/King_Wen_of_Zhou) (~1000 BCE), but modern scholarship is divided on the exact origin, authorship, and dating. The program uses the traditional attribution as a label without taking a position on historicity.

## Statistical methodology

- The entropy analysis now includes both unconstrained and pair-constrained null models. King Wen remains more structured than random under both (12th and 6th percentile respectively), but neither survives Bonferroni correction (p > 0.0018).
- The autocorrelation uses the biased estimator (divides by n rather than n-lag), which attenuates values at higher lags. This is the standard estimator but may understate weak periodicity.
- The DFT significance threshold (2x noise floor) is ad hoc. A proper test would use Fisher's g-statistic or Bonferroni correction across frequency bins.
- The DNA codon mapping uses one of 24 possible bit-to-base assignments. Different mappings produce different results. The comparison is illustrative, not evidence of a biological connection.
- The bootstrap confidence intervals measure Monte Carlo estimation precision (how much the estimate would vary if you re-ran the simulation), not fundamental uncertainty about the true proportion. Increasing `--trials` narrows the CIs because the estimate becomes more precise, not because the underlying truth is better known.
- The palindrome analysis now includes both unconstrained and pair-constrained null models. Under pair-constrained comparison, King Wen's palindrome count is at the 49th percentile (completely typical) and longest palindrome at the 14th percentile (somewhat low but not significant).
- The Hamming distance matrix is a fixed property of the 6-bit binary system, identical for any ordering of the 64 hexagrams. Only which hexagrams are adjacent depends on the ordering.
- Trigram transition matrices have ~1 expected observation per cell, so no goodness-of-fit test (chi-square, etc.) has sufficient power to detect deviations. The matrices are descriptive only.
- Windowed entropy is exploratory visualization without a null model or significance test. Apparent patterns in the curve are expected from random variation.
- The full 8-state mutual information between upper and lower trigrams is zero by construction: all 64 hexagrams span every possible (upper, lower) trigram combination exactly once, forming a complete [Latin square](https://en.wikipedia.org/wiki/Latin_square) (an 8×8 grid where each of the 8 trigrams appears exactly once in each row and column). Independence is automatic for any set containing all 64 distinct 6-bit values — it is a property of the binary encoding, not of King Wen's ordering.

## Analytical claims

- The claim that "the designers appear to have been working with a sophisticated understanding of combinatorial structure" is an inference, not a finding. The pair structure could arise from a simple rule ("always place a hexagram next to its mirror or opposite") without any understanding of combinatorics. "Designed" could also mean iterative cultural refinement rather than a single deliberate act.
- The nuclear hexagram chain structure is a fixed function of binary values, independent of the King Wen ordering. The chains, cycle lengths, and frequency distribution are identical for any ordering of the 64 hexagrams. The program now notes this explicitly.
- The no-5-line-transition property, while real, is largely explained by the pair structure: ~4% of pair-constrained orderings also avoid 5-line transitions. Within reverse/inverse pairs, 5-line transitions are mathematically impossible (Hamming distances are always even or 6).
- The complement distance analysis shows King Wen places complements significantly closer together than random (0th percentile), suggesting deliberate organization around opposition. This is a genuine finding. The constraint solver (`solve.py`) further shows that among all orderings satisfying Rules 1-6, King Wen's complement distance is at the **3.9th percentile** — it actively minimizes the distance between opposites, keeping them as close as possible.
- The canon comparison (Upper vs Lower Canon) shows no statistically significant difference in mean line-change differences between the two halves (~12th percentile). The traditional split does not correspond to a structural boundary.
- The recurrence rate is at the 72nd percentile — within the range expected by chance.
- Neighborhood clustering (Hamming-1 neighbors) is at the 12th percentile — closer than average but within chance expectations.
- The Gray code comparison is descriptive only; for significance testing of path length see the path analysis section.

## Computational methodology and self-correction

- **Earlier "31.6M" and "742M" lower bounds were both wrong** — 31.6M was a ~23× undercount from a sub-branch filename collision bug (fixed commit 585880f); 742M was a further undercount from a hash-table probe-cap bug (fixed commit b598067). Both deterministic bugs produced stable sha256s across runs, illustrating the methodological point: **a reproducible sha256 is not a proof of correctness; it only proves the bug, if any, is reproducible**. Both caught only by output-shape sanity checks. The current canonical figures (706M d3, 286M d2) come from the fully-fixed solver with format v1 and have been cross-validated across 3 independent merge paths. See [HISTORY.md](HISTORY.md) for the forensic narrative.
- **The "shift pattern observed universally" claim is scope-sensitive.** At the d2 10T canonical dataset, 2.69% of valid orderings are fully shift-conforming. At d3 10T, that drops to **0.062%** — 43× rarer at deeper partition sampling. The pattern is a local property satisfied by a small and shrinking fraction of the broader space. Anything in `--prove-cascade` that depended on shift-pattern universality should be read as scoped to that subspace, not the full solution space.
- **Boundary constraint claims must be scoped to the partition depth.** The claim "2 adjacency constraints suffice" (early sample) was undersampling. The claim "4 boundaries minimum, specifically `{25,27} ∪ one-of-{2,3} ∪ one-of-{21,22}`" was d2-specific. The d3 canonical analyze reveals **8 working 4-subsets at d3** with different interchangeable boundaries (from the 1-6 range, not 21-22). **What is stable across d2 and d3**: boundaries {25, 27} are mandatory in every working 4-set. **What is NOT stable**: the rest of the 4-set structure. This means the headline "mandatory boundaries {25, 27}" finding IS robust; the broader "minimal working structure" phrasing is partition-scoped and may continue to change at deeper enumeration.
- **`--prove-cascade` proves a narrower claim than its earlier framing implied.** The "16 of 31 branches budget-deterministic" result is correct *within* a 2-candidate-per-position shift-pattern subspace. Across the full canonical solution spaces (d2 and d3), every reachable first-level branch admits multiple distinct configurations at positions 3-19; none have exactly 1.
- **Complement is NOT closed in either canonical dataset.** At both d2 and d3, 0 of the records have their complement partner in the set — specifically, KW's complement does NOT satisfy C1-C5. This is a structural property of the constraints, not a contingent observation. Any "self-dual" framing of King Wen under complement is incorrect.

## Missing analyses

- **Structured-permutation null models (partially addressed 2026-04-19).** Three families are now tested via `solve.c --null-debruijn-exact`, `--null-gray`, and `--null-latin`, plus a sampled counterpart in `solve.py --null-debruijn`:

  - **de Bruijn B(2, 6) — exhaustive, 134,217,728 circuits (2^27 Eulerian circuits of B(2, 5) starting at vertex 0, representing all 2^26 cyclic sequences ×2 starting-rotation).** Exact counts: **0 satisfy C1** (pair structure), **0 satisfy C2** (no 5-line transitions; minimum observed is 1), **247,048 = 0.184% satisfy C3** (total comp distance ≤ 776). C3 range [480, 2048], mean 1445.87. KW's C3 is at the 0.1841-th percentile of the null pool. The 0-satisfiers for C1 is also provable analytically — see §C1 impossibility in the de Bruijn and Gray code families below.
  - **6-bit Gray code orbit (256 members: 64 rotations × 2 reverse × 2 complement).** 0 satisfy C1 (analytically impossible), 256 trivially satisfy C2 (Hamming-1 adjacency precludes Hamming-5), 0 satisfy C3 (range [1792, 2048], mean 1912). Gray codes place complements FARTHER apart than KW, not closer.
  - **Latin-square row-traversals, 8! = 40,320 row orderings (natural column order within rows).** 0 satisfy C1, **1,152 = 2.86% satisfy C2**, **2,688 = 6.67% satisfy C3** (range [512, 2048]). This is the one family where a nontrivial fraction matches KW on C2 and C3 — though *no* Latin-square row-traversal matches KW on C1.
  - **Costas arrays of order 64** — not tested. Order-64 Costas arrays may or may not exist (standard constructions like Welch and Lempel–Golomb give adjacent orders 62, 66 but not 64); enumeration is infeasible (~64! candidates). Deferred.

  Across all three tested families, **0/134M + 0/256 + 0/40,320 permutations satisfy C1**. C2 and C3 vary. The strengthened conclusion: C1 (pair structure) is structurally orthogonal to de Bruijn, Gray, AND Latin-square row-traversal families — three independent structured-permutation families all rule out C1. Caveats: Costas remains untested; Latin-square enumeration is row-order-only (8! of the full 8!×8!=1.6B space); these are three specific families, not exhaustive of all structured permutations.

### C1 impossibility in the de Bruijn and Gray code families

Two short analytic proofs formalize what the exhaustive enumeration observes empirically.

**Claim 1: No B(2, 6) de Bruijn permutation satisfies C1.**

Let the underlying binary sequence be $s_0 s_1 \ldots s_{63}$ (cyclic). Each hexagram is a 6-bit window: $\mathrm{hex}_i = s_i s_{i+1} s_{i+2} s_{i+3} s_{i+4} s_{i+5}$ (bit 0 = $s_i$). C1 requires, at each pair position $(2i, 2i+1)$, one of:

- (Reverse case) $\mathrm{hex}_{2i+1} = \mathrm{reverse}_6(\mathrm{hex}_{2i})$, i.e., bit $j$ of $\mathrm{hex}_{2i+1}$ equals bit $5-j$ of $\mathrm{hex}_{2i}$ for all $j$.
- (Symmetric-complement case, when both hexagrams are palindromic) $\mathrm{hex}_{2i+1} = \mathrm{hex}_{2i} \oplus 0b111111$.

**Reverse case.** Equating $\mathrm{hex}_{2i+1}$ to $\mathrm{reverse}_6(\mathrm{hex}_{2i})$ bit-by-bit gives three independent constraints on the underlying sequence: $s_{2i+1} = s_{2i+5}$, $s_{2i+2} = s_{2i+4}$, $s_{2i+6} = s_{2i}$. Applied across all 32 pair positions $i = 0, 1, \ldots, 31$, the constraints cascade: every even-indexed bit equals $s_0$, every bit at position $\equiv 1 \pmod 4$ equals $s_1$, every bit at position $\equiv 3 \pmod 4$ equals $s_3$. The sequence must be periodic with period 4: $(s_0, s_1, s_0, s_3, s_0, s_1, s_0, s_3, \ldots)$.

A period-4 sequence produces at most 4 distinct 6-bit windows, contradicting the B(2, 6) requirement that all 64 windows be distinct.

**Symmetric-complement case.** The hexagram $\mathrm{hex}_{2i}$ being palindromic imposes $s_{2i+2} = s_{2i+3}$ (middle bits must match). The complement equation then requires $s_{2i+3} = \overline{s_{2i+2}}$. But if $s_{2i+2} = s_{2i+3}$ AND $s_{2i+3} = \overline{s_{2i+2}}$, then $s_{2i+2} = \overline{s_{2i+2}}$, a contradiction.

Both cases are impossible, so no pair can satisfy C1, and therefore no B(2, 6) de Bruijn permutation satisfies C1 as a whole. ∎

**Claim 2: No 6-bit Gray code satisfies C1.**

In any Gray code, adjacent positions differ by Hamming distance exactly 1. C1 requires each pair to have Hamming distance in $\{0, 2, 4, 6\}$: the reverse case produces $2 \cdot k$ for $k$ mismatched bit-pairs ($0, 2, 4, 6$), and the symmetric-complement case produces exactly 6 (all bits flipped). Hamming distance 1 is never among these. Therefore no Gray code satisfies the C1 pair-structure constraint at any pair position. ∎

These two results, combined with the computationally exhaustive Latin-square row-traversal test showing 0/40,320, give three independent structured-permutation families where C1 is ruled out (two analytically, one computationally exhaustively). **C1 is not an "accidentally satisfied" property of common structured permutation families**; it is a specific constraint that King Wen happens to satisfy.
- No formal proof that 4 boundaries are minimum across *all* valid orderings. Only computational verification across the d2 (286M) and d3 (706M) canonical datasets. A deeper enumeration could in principle reveal a working 3-subset (lowering minimum), require a 5th boundary (raising it), or further change the structure of which specific boundaries work.
- No independent derivation of the constraints from first principles. The 5 rules (C1-C5) were extracted from KW and then verified against KW; a stronger result would derive them from external mathematical or coding-theoretic principles. The null-model analysis confirms the constraint-extraction methodology produces apparent uniqueness for many random pair-constrained sequences, so the constraints are KW-specific rather than universal.

## Summary

The constraint solver (`solve.c`) finds that 5 rules extracted from King Wen narrow 10^89 possible orderings to hundreds of millions — 706,422,987 at d3 10T partition (canonical, sha `f7b8c4fb…`), 286,357,503 at d2 10T. Both are partial enumerations (each sub-branch hits its per-sub-branch node budget rather than completing naturally); the true count under exhaustive enumeration is higher. Only Position 1 is universally locked (forced by Rule 4). The current state is: **4 boundary constraints minimum (proven at both d2 and d3 scales)**, with boundaries **{25, 27} appearing in every working 4-subset at BOTH partitions** (the stable mandatory-boundary finding). The other 2 boundaries in the 4-set are partition-dependent — d2 uses {2,3} and {21,22}; d3 uses combinations from {1..6}. The rules are confirmatory (extracted from King Wen, then shown to be highly constraining) rather than predictive (derived independently). See [SOLVE.md](SOLVE.md), [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md), [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) (formal theorem guaranteeing the canonical shas are partition-invariant), and [HISTORY.md](HISTORY.md) for details.

The program is honest about what it computes and includes explicit statistical caveats where the evidence is thin. Sensitivity analysis confirms all key mathematical results are invariant under bit-ordering convention (Hamming distance is invariant under bit permutation). The pair structure is the one genuinely extraordinary property — it is vanishingly unlikely by chance. The complement distance is also genuinely unusual (0th percentile). Other findings are either explained by the pair structure (no-5 property, ~4% among pair-constrained orderings), not significant after Bonferroni correction (entropy), indistinguishable from pair-constrained random orderings (Markov, path length, palindromes), or purely descriptive without significance tests (windowed entropy, trigram transitions, Gray code ratio). The Wald-Wolfowitz runs test detects alternation in the difference wave (Z = +2.13, p = 0.033), but this does not survive Bonferroni correction (threshold p < 0.0018). Palindromic subsequences in the wave are unremarkable under pair-constrained null model (49th percentile for count, 14th for longest). The canon split, recurrence rate, and neighborhood clustering are all within chance expectations. Effect sizes (Cohen's d) are reported alongside percentiles for key analyses.
