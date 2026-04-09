# Known Limitations

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
- The full 8-state mutual information between upper and lower trigrams is zero by construction: all 64 combinations appear exactly once (a complete Latin square), so independence is automatic.

## Analytical claims

- The claim that "the designers appear to have been working with a sophisticated understanding of combinatorial structure" is an inference, not a finding. The pair structure could arise from a simple rule ("always place a hexagram next to its mirror or opposite") without any understanding of combinatorics. "Designed" could also mean iterative cultural refinement rather than a single deliberate act.
- The nuclear hexagram chain structure is a fixed function of binary values, independent of the King Wen ordering. The chains, cycle lengths, and frequency distribution are identical for any ordering of the 64 hexagrams. The program now notes this explicitly.
- The no-5-line-transition property, while real, is largely explained by the pair structure: ~4% of pair-constrained orderings also avoid 5-line transitions. Within reverse/inverse pairs, 5-line transitions are mathematically impossible (Hamming distances are always even or 6).
- The complement distance analysis shows King Wen places complements significantly closer together than random (0th percentile), suggesting deliberate organization around opposition. This is a genuine finding. The constraint solver (`solve.py`) further shows that among all orderings satisfying Rules 1-6, King Wen's complement distance is at the **3.9th percentile** — it actively minimizes the distance between opposites, keeping them as close as possible.
- The canon comparison (Upper vs Lower Canon) shows no statistically significant difference in mean line-change differences between the two halves (~12th percentile). The traditional split does not correspond to a structural boundary.
- The recurrence rate is at the 72nd percentile — within the range expected by chance.
- Neighborhood clustering (Hamming-1 neighbors) is at the 12th percentile — closer than average but within chance expectations.
- The Gray code comparison is descriptive only; for significance testing of path length see the path analysis section.

## Missing analyses

- No comparison against other structured permutations (de Bruijn sequences, Costas arrays) — only random permutations are used as null models.

## Summary

The constraint solver (`solve.py`) demonstrates that the King Wen sequence is **97% determined by 7 mathematical rules**, which lock 23 of 32 pair positions. The remaining 3% — two specific pair adjacency choices in positions 25-28 — represents irreducible creative decisions that no measured mathematical property can explain. See [SOLVE.md](SOLVE.md) for details.

The program is honest about what it computes and includes explicit statistical caveats where the evidence is thin. Sensitivity analysis confirms all key mathematical results are invariant under bit-ordering convention (Hamming distance is invariant under bit permutation). The pair structure is the one genuinely extraordinary property — it is vanishingly unlikely by chance. The complement distance is also genuinely unusual (0th percentile). Other findings are either explained by the pair structure (no-5 property, ~4% among pair-constrained orderings), not significant after Bonferroni correction (entropy), indistinguishable from pair-constrained random orderings (Markov, path length, palindromes), or purely descriptive without significance tests (windowed entropy, trigram transitions, Gray code ratio). The Wald-Wolfowitz runs test detects alternation in the difference wave (Z = +2.13, p = 0.033), but this does not survive Bonferroni correction (threshold p < 0.0018). Palindromic subsequences in the wave are unremarkable under pair-constrained null model (49th percentile for count, 14th for longest). The canon split, recurrence rate, and neighborhood clustering are all within chance expectations. Effect sizes (Cohen's d) are reported alongside percentiles for key analyses.
