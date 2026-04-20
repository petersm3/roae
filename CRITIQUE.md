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

- **Structured-permutation null models (comprehensively addressed 2026-04-19).** Seven null-model families are now tested via `solve.c --null-debruijn-exact`, `--null-gray`, `--null-latin`, `--null-lex`, `--null-historical`, `--null-random`, `--null-pair-constrained`, plus a sampled counterpart in `solve.py --null-debruijn`:

  | Family | Scope | C1 (pair struct) | C2 (no 5-line) | C3 (comp dist ≤ 776) |
  |---|---|---|---|---|
  | de Bruijn B(2, 6) | Exhaustive, 134,217,728 circuits | **0 (0.00%)** — also proven analytically | 0 (0.00%) — min observed 1 | 247,048 (0.1841%) |
  | 6-bit Gray code orbit | 256 (rot × rev × compl) | **0 (0.00%)** — proven ∀ Gray | 256 (100%) — trivial | 0 (0.00%); range [1792, 2048] |
  | 6-bit Gray codes (random) | 10^5 random Hamiltonian walks in Q_6 | **0 (0.00%)** | 100% (trivial) | **0 (0.00%); range [832, 2048], CI ≤ 3×10⁻⁵** |
  | Latin-square row × column | Exhaustive 8!×8! = 1,625,702,400 | **0 (0.00%)** | **942,243,840 (57.96%)** — see §decomposition below | 108,380,160 (6.67%); range [512, 2048] |
  | Lexicographic (bit-order) | Exhaustive, 6! = 720 | 0 (0%) | 0 (0%) — always 2 five-line | 0 (0%) — always 2048 |
  | Historical (4 orderings) | Fu Xi, KW, Mawangdui, Jing Fang 8 Palaces | KW only | KW + **Mawangdui + Jing Fang** (3 of 4) | KW only |
  | Random 64-permutations | 10^9 uniform samples | **0 / 10^9 (0%)** | 1,827,703 (0.1828%) | 28,356 (0.002836%) |
  | **Pair-constrained (C1 baked in)** | 10^9 samples, C1 guaranteed | 100% (by construction) | 4.29% conditional on C1 | 6.42% conditional on C1 |

  **Theoretical check**: C1 in random 64-permutations has probability $\approx (32! \cdot 2^{32}) / 64! \approx 10^{-44}$. In 10^9 samples we would expect to see 0 — which we do. The ~3/N Wilson upper bound (Hanley & Lippman-Hand 1983) gives 95% CI on the C1 rate of [0, $3 \times 10^{-9}$] from the random 10^9 sample, consistent with the theoretical 10^-44.

  **What this establishes:**

  - **C1 is astronomically KW-specific.** Zero of 1.86 billion permutations sampled across six unconditional families satisfy C1, consistent with the theoretical rate of ~10^-44. For de Bruijn and Gray code families the 0% result is not just empirical — it is provable (see §C1 impossibility below).
  - **C1 is doing most of the structural work.** Given C1 (pair-constrained null), the conditional C2 rate jumps from 0.18% (random) to **4.29% — a ~23.5× multiplier** — and the conditional C3 rate jumps from 0.003% to **6.42% — a ~2,264× multiplier**. The pair structure C1 alone enormously constrains the space toward KW-like adjacency and complement geometry; C2 and C3 are then relatively modest additional filters.
  - **C2 (no 5-line transitions) is mildly structural and may be a classical Chinese design principle.** Rare in random (0.18%), impossible in de Bruijn, automatic in Gray codes (construction tautology), majority-satisfied in Latin-square row×col (**57.96%**, analytically decomposed below). Most strikingly, **3 of 4 tested ancient Chinese hexagram orderings** (King Wen, Mawangdui silk-text, Jing Fang 8 Palaces) satisfy C2 exactly — only Fu Xi's natural-binary ordering does not. Since Fu Xi is a mathematical/Leibnizian construction rather than a traditional divinatory ordering, this suggests **C2 was likely a shared classical design principle** across multiple ancient arrangements, not something McKenna discovered as unique to KW. C2 alone is not especially distinguishing among historical orderings; the pair-constrained null shows C2 | C1 ≈ 4.29%.
  - **C3 concentration varies by family.** Random: 0.003%. de Bruijn: 0.18% (~65× random). Latin-square: 6.67% (~2,350× random). Pair-constrained (C1): 6.42%. Gray: 0%, with the strong additional observation that the minimum Gray-code C3 across 10^5 random samples is 832 — **strictly greater than KW's 776**. No Gray code beats KW on complement distance, empirically. The pair-constrained rate being similar to Latin-square is suggestive — both impose strong structural symmetry on complement placement.
  - **Simultaneous C1+C2+C3 satisfaction is uniquely King Wen across all tested unconditional families.** No family has a nonzero fraction achieving all three, because C1 is 0% in each. Under the pair-constrained null (C1 given), the independence estimate 4.29% × 6.42% ≈ 0.28% gives a rough ceiling on "random pair-permutation that also satisfies C2 and C3"; this aligns with solve.c's canonical enumeration finding (706M orderings under C1+C2+C3 at d3 10T).

  **Remaining gap:** Costas arrays at order 64 (uncertain existence via standard Welch/Lempel–Golomb constructions; full 64! enumeration is infeasible at ~10^89 candidates). Costas at order 64 is the last open "structured permutation" family within reasonable scope; testing it would require either obtaining a published database of order-64 Costas arrays or implementing sporadic constructions. Deferred.

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

These two results, combined with the computationally exhaustive Latin-square row × column test showing 0/1.6B, give three independent structured-permutation families where C1 is ruled out (two analytically, one computationally exhaustively). **C1 is not an "accidentally satisfied" property of common structured permutation families**; it is a specific constraint that King Wen happens to satisfy.

### Latin-square C2-rate decomposition

The empirical observation that **57.96% of 8! × 8! Latin-square row × column traversals satisfy C2** (zero 5-line transitions) is analytically explained by the adjacency structure of the Latin-square grid. Verified by `solve.c --null-latin-explain`, which reproduces the count 942,243,840 exactly from first principles.

**Theorem (C2-rate decomposition).** In a Latin-square row × column traversal of the 64 hexagrams, the row-permutation class determines the C2 rate. Of 63 adjacent transitions, 56 are within-row (share upper trigram, so Hamming ≤ 3, and cannot be 5) and only the 7 between-row boundaries can be Hamming-5. At boundary $i$, the transition Hamming distance is $p_i + d$ where $p_i = \mathrm{popcount}(\mathrm{row}[i] \oplus \mathrm{row}[i+1]) \in \{1, 2, 3\}$ and $d = \mathrm{popcount}(c[0] \oplus c[7]) \in \{1, 2, 3\}$. The transition is Hamming-5 iff $(p_i, d) \in \{(2, 3), (3, 2)\}$. Since $d$ is a property of the column permutation, we get:

| Row-perm class | # row perms (of 8! = 40,320) | Good column perms (of 8! = 40,320) | C2 rate |
|---|---|---|---|
| All $p_i = 1$ (Hamiltonian path in $Q_3$) | 144 (0.36%) | 40,320 (all) | 100% |
| Some $p_i = 2$, no $p_i = 3$ | 13,680 (33.93%) | 34,560 (= 48/56 × 40,320) | 85.71% |
| Some $p_i = 3$, no $p_i = 2$ | 1,008 (2.50%) | 23,040 (= 32/56 × 40,320) | 57.14% |
| Both $p_i = 2$ and $p_i = 3$ | 25,488 (63.21%) | 17,280 (= 24/56 × 40,320) | 42.86% |

The weighted sum $144 \cdot 40{,}320 + 13{,}680 \cdot 34{,}560 + 1{,}008 \cdot 23{,}040 + 25{,}488 \cdot 17{,}280 = 942{,}243{,}840$ exactly matches the empirical `--null-latin` count. The 57.96% rate is thus a direct consequence of: (a) only 7 of 63 transitions can be 5-line in any Latin-square row×col traversal, and (b) the distribution of row-adjacency Hamming profiles among Hamiltonian paths in the 3-cube.

**Direction invariance** (verified 2026-04-19 via `solve.c --null-latin-col`). Reading the Latin-square grid COLUMN-first (reverse nesting: column ordering outer, row ordering inner) produces **identical** aggregate statistics: n = 1,625,702,400, C2 pass = 942,243,840 (57.959184%), C3 pass = 108,380,160 (6.667%), C3 range [512, 2048] mean 1536.0. Every figure matches the row-first traversal to the digit. By the symmetry of the upper/lower-trigram axes in the abstract 8×8 grid, this was expected — but the empirical confirmation shows the 57.96% C2 rate is a property of the Latin-square family as a whole, not an artifact of which axis is read first.

**Connection to KW.** King Wen is **not** a Latin-square row×col traversal (`./solve --null-historical` confirms Fu Xi fails C1). But the Latin-square result suggests a diagnostic question for KW: does KW have its own adjacency decomposition that analogously pushes 5-line transitions into a small subset of positions? KW has 32 pairs, each with within-pair transitions fixed to Hamming {2, 4, 6} by C1's reverse/complement construction — which also mechanically excludes Hamming-5. So KW's 32 within-pair transitions trivially avoid 5-line, leaving C2's constraint work entirely to the 31 between-pair boundaries. This is structurally analogous to Latin-square's within-row/between-row split. (The within-pair Hamming-even property has long been known in I Ching scholarship; see [CITATIONS.md](CITATIONS.md) — McKenna 1975 and Cook 2006 both discuss the even-transition artifact of the pairing rule. ROAE's contribution here is the analogous decomposition for the Latin-square family.)

### King Wen's own adjacency decomposition

Following from the Latin-square analysis, we can characterize KW's 63 transitions explicitly. KW's 32 pairs partition the transitions into 32 within-pair and 31 between-pair.

**Within-pair transitions** (KW's 32, all Hamming-even by C1 construction):

| Hamming distance | Count |
|---|---|
| 2 | 11 |
| 4 | 13 |
| 6 | 8 |

The within-pair sum is $11 + 13 + 8 = 32$, all 32 pairs. Zero odd distances by construction.

**Between-pair transitions** (KW's 31, where all the "constraint work" happens):

| Hamming distance | KW count | Expected (uniform random adjacency, ×31) | Delta |
|---|---|---|---|
| 1 | 2 | 2.95 | −0.95 |
| 2 | 7 | 7.38 | −0.38 |
| 3 | **14** | 9.84 | **+4.16** |
| 4 | 7 | 7.38 | −0.38 |
| 5 | **0** | 2.95 | **−2.95** |
| 6 | 1 | 0.49 | +0.51 |

The empirical 14:2 ratio of 3-line to 1-line odd transitions (with zero 5-line) matches the feature documented by **McKenna 1975** (*The Invisible Landscape*) and discussed by **Cook 2006** and Wikipedia's [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) article. King Wen's between-pair transitions concentrate on Hamming-3 **4×** the uniform expected rate, and drop the Hamming-5 count to zero. No Hamming-0 transitions (all 64 hexagrams distinct, trivially); minimal Hamming-1 count (just 2 occurrences).

**Structural interpretation.** Like Latin-square's within-row/between-row decomposition, KW cleanly splits its 63 transitions into: (a) 32 within-pair transitions, trivially {2, 4, 6} by pair-reflection geometry; (b) 31 between-pair transitions, where C2 (no 5-line) and the 14:2 odd-concentration are the substantive structural signals. Prior literature (McKenna 1975, Cook 2006) documents these between-pair features as observed empirical properties of the KW sequence; ROAE's contribution here is to place them alongside the Latin-square decomposition as structurally parallel (different families, same within-group trivialization pattern) and to quantify the deviation from uniform-random between-pair adjacency.

- No formal proof that 4 boundaries are minimum across *all* valid orderings. Only computational verification across the d2 (286M) and d3 (706M) canonical datasets. A deeper enumeration could in principle reveal a working 3-subset (lowering minimum), require a 5th boundary (raising it), or further change the structure of which specific boundaries work.
- No independent derivation of the constraints from first principles. The 5 rules (C1-C5) were extracted from KW and then verified against KW; a stronger result would derive them from external mathematical or coding-theoretic principles. The null-model analysis confirms the constraint-extraction methodology produces apparent uniqueness for many random pair-constrained sequences, so the constraints are KW-specific rather than universal. See [CITATIONS.md](CITATIONS.md) for prior literature — C1 (pair structure) is classical; C2 (no-5-line) is McKenna 1975 / Cook 2006; C3 (complement distance as a quantified threshold) is believed ROAE-original.

## Open questions

Falsifiable follow-ups surfaced by the current analysis. These are not claims; they are candidate hypotheses testable with the tools already built.

### About the null-model framework

1. **Costas arrays at order 64.** Standard Welch/Lempel–Golomb constructions give adjacent orders 62 and 66; a direct order-64 family is not known to the author. Concrete follow-up: (a) survey the published literature (the Naval Postgraduate School maintains a database of known Costas arrays) for any order-64 examples; (b) test each against C1/C2/C3; (c) if a family of order-64 Costas arrays can be constructed (e.g., via sporadic constructions, or computer search from known order-62/66 seeds), run the full null-model test.

2. **Gray code C3 exhaustive.** The total count of 6-bit Gray codes (Hamiltonian cycles in Q_6) is estimated at ~10²² — exhaustive enumeration is infeasible at any practical compute budget. But the conditional C3 rate could be tightly bounded via biased random Hamiltonian sampling (10⁹ samples in a few hours); would give a firm upper bound on the Gray-code C3 rate rather than the current 0/256 from the restricted orbit.

3. **Analytic C2 impossibility for de Bruijn B(2, 6).** The empirical result is that 0 of 134,217,728 sequences have zero 5-line transitions; minimum observed is 1. An analytic proof complementary to the C1 proof would formalize why. Conjectured approach: the Hamming-distance sequence of a B(2, 6) permutation is determined by adjacent-bit-equality patterns in the underlying binary sequence; pigeonhole + counting may show at least one Hamming-5 transition is forced.

### About the Latin-square decomposition

4. **Does King Wen have an analogous adjacency decomposition?** Latin-square row×col traversals split 63 transitions into 56 within-row (Hamming ≤ 3, cannot be 5) and 7 between-row (can be 5). KW has 32 pairs with 32 within-pair transitions (Hamming 2/4/6 by C1 construction, cannot be 5) and 31 between-pair boundaries (where all the C2 work happens). Concrete follow-up: (a) characterize the 31 between-pair boundary Hamming distances in KW; (b) compare to random permutations satisfying C1 to measure how much additional structure the between-pair distribution has.

5. **Why does Mawangdui satisfy C2?** The ancient silk-text ordering has zero 5-line transitions despite a completely different pair geometry than KW. Is there a trigram-cycling argument analogous to KW's pair-Hamming-even property that explains it? Concrete follow-up: analyze Mawangdui's adjacency Hamming distribution and see if it decomposes like KW's (pair-interior = even) or like Latin-square (row-interior = small), or something else entirely.

### About the constraint system

6. **What combinatorial family does KW belong to?** KW is not in any of the seven structured families tested (de Bruijn, Gray, Latin-square row×col, lex, historical, pair-constrained-random-orientation, random). This is consistent with KW being sporadic / hand-constructed. But falsifiable: is there a structured family (yet-untested) that KW IS in? Candidates include necklace/bracelet enumeration orders, hex-based error-correcting codes, group-theoretic orbit constructions, or specific Hamiltonian cycles in graphs with hexagram-meaningful structure (e.g., the pair graph).

7. **Are C1, C2, C3 actually sufficient?** ROAE reports 706M distinct orderings at d3 10T under C1+C2+C3. Under EXHAUSTIVE enumeration (not partial) the count may differ. The current enumeration is node-budget-limited; a true exhaustive enumeration would require much larger compute (100T d3 in progress as of 2026-04-19). The 100T run will not make the enumeration exhaustive but will reduce the gap between partial and exhaustive counts.

8. **Minimum boundary-adjacency set exhaustive minimum.** Currently: "4 boundaries minimum" is proven for both d2 and d3 10T canonical datasets, with {25, 27} mandatory in every working 4-set at both partitions. Deeper enumeration could in principle reveal a 3-subset that works at a higher depth. If a 3-subset ever works at exhaustive enumeration, the "4-minimum" claim is falsified.

### About methodology

9. **Formal machine-checked proof of Theorem 6.** The forced-orientation theorem (see SPECIFICATION.md) has a prose proof. A Lean or Rocq machine-checked proof would remove any residual ambiguity. Listed in LONG_TERM_PLAN.md. Level 1 (prose tightening) and Level 2 (Lean / Rocq) both deferred.

10. **Bootstrap confidence intervals for all percentiles in CRITIQUE.md.** The current framing uses point estimates from finite samples. Bootstrap (or Wilson score intervals for proportions) would put explicit error bars on every rate claim. Partially done in the null-model table (Wilson / 3/N rule mentioned); not yet exhaustively applied.

### About specific numerical values

11. **~~Is King Wen's C3 = 776 mathematically significant?~~ — RESOLVED 2026-04-20 (partial).** Via `solve.c --c3-min` on the 100T d3 canonical (3.43B records):
    - **Minimum C3 observed: 424** (across 221 records)
    - **Maximum C3 observed: 776** (ceiling of the constraint C3 ≤ 776)
    - **KW's C3 = 776** — KW sits at the **CEILING**, not the floor. KW is the **least** C3-optimal among C1+C2+C3 solutions.
    - The earlier "3.9th percentile" claim was among C1-only orderings (pre-C3-filter). Within C1+C2+C3, KW is at the C3-maximum.
    - **Implication for Open Question #7**: the simple axiom "minimize C3" does not uniquely derive KW — it picks out 221 "C3-extremal" records at C3 = 424. **Negative result for Phase A Day 1 MVP.**
    - Remaining: characterize the 221 C3=424 records. What else distinguishes them? Is there a structured family? Do they share boundary features with KW? (Follow-up post-analyze.)

## Summary

The constraint solver (`solve.c`) finds that 5 rules extracted from King Wen narrow 10^89 possible orderings to hundreds of millions — 706,422,987 at d3 10T partition (canonical, sha `f7b8c4fb…`), 286,357,503 at d2 10T. Both are partial enumerations (each sub-branch hits its per-sub-branch node budget rather than completing naturally); the true count under exhaustive enumeration is higher. Only Position 1 is universally locked (forced by Rule 4). The current state is: **4 boundary constraints minimum (proven at both d2 and d3 scales)**, with boundaries **{25, 27} appearing in every working 4-subset at BOTH partitions** (the stable mandatory-boundary finding). The other 2 boundaries in the 4-set are partition-dependent — d2 uses {2,3} and {21,22}; d3 uses combinations from {1..6}. The rules are confirmatory (extracted from King Wen, then shown to be highly constraining) rather than predictive (derived independently). See [SOLVE.md](SOLVE.md), [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md), [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) (formal theorem guaranteeing the canonical shas are partition-invariant), and [HISTORY.md](HISTORY.md) for details.

The program is honest about what it computes and includes explicit statistical caveats where the evidence is thin. Sensitivity analysis confirms all key mathematical results are invariant under bit-ordering convention (Hamming distance is invariant under bit permutation). The pair structure is the one genuinely extraordinary property — it is vanishingly unlikely by chance. The complement distance is also genuinely unusual (0th percentile). Other findings are either explained by the pair structure (no-5 property, ~4% among pair-constrained orderings), not significant after Bonferroni correction (entropy), indistinguishable from pair-constrained random orderings (Markov, path length, palindromes), or purely descriptive without significance tests (windowed entropy, trigram transitions, Gray code ratio). The Wald-Wolfowitz runs test detects alternation in the difference wave (Z = +2.13, p = 0.033), but this does not survive Bonferroni correction (threshold p < 0.0018). Palindromic subsequences in the wave are unremarkable under pair-constrained null model (49th percentile for count, 14th for longest). The canon split, recurrence rate, and neighborhood clustering are all within chance expectations. Effect sizes (Cohen's d) are reported alongside percentiles for key analyses.
