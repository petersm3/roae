# Known Limitations

A review of the program's methodology, assumptions, and interpretive claims from a mathematical perspective.

## Data correctness

- The binary hexagram encodings follow [OEIS A102241](https://oeis.org/A102241) with bit 0 = bottom line. Sensitivity analysis confirms the difference wave, pair structure, and no-5 property are all invariant under bit reversal (since Hamming distance is invariant under bit permutation). Trigram assignments do change under reversal, affecting display labels but not mathematical results.
- The hexagram names are attributed to the [Wilhelm/Baynes translation](https://press.princeton.edu/books/hardcover/9780691097503/the-i-ching-or-book-of-changes) but several are simplified or variant. A rigorous treatment would cite each name individually, not give a blanket attribution.
- The [Mawangdui](https://en.wikipedia.org/wiki/Mawangdui_Silk_Texts) ordering was recomputed from trigram cycling rules, but the actual silk manuscript ordering has scholarly disagreements. The program treats one reconstruction as definitive.

## Statistical methodology

- The entropy percentile comparison uses an unconstrained null model (all 64! permutations). A more relevant null model would condition on the pair constraint, since the pair structure is the dominant structural feature.
- The autocorrelation uses the biased estimator (divides by n rather than n-lag), which attenuates values at higher lags. This is the standard estimator but may understate weak periodicity.
- The DFT significance threshold (2x noise floor) is ad hoc. A proper test would use Fisher's g-statistic or Bonferroni correction across frequency bins.
- The DNA codon mapping uses one of 24 possible bit-to-base assignments. Different mappings produce different results. The comparison is illustrative, not evidence of a biological connection.

## Analytical claims

- The claim that "the designers appear to have been working with a sophisticated understanding of combinatorial structure" is an inference, not a finding. The pair structure could arise from a simple rule ("always place a hexagram next to its mirror or opposite") without any understanding of combinatorics. "Designed" could also mean iterative cultural refinement rather than a single deliberate act.
- The nuclear hexagram analysis is purely descriptive — it shows the chains but never tests whether the chain structure is unusual compared to random orderings. Without a null model, it is not clear if the chains are notable.
- The no-5-line-transition property, while real, is largely explained by the pair structure: ~4% of pair-constrained orderings also avoid 5-line transitions. Within reverse/inverse pairs, 5-line transitions are mathematically impossible (Hamming distances are always even or 6).

## Missing analyses

- No comparison against other structured permutations (de Bruijn sequences, Costas arrays) — only random permutations are used as null models.

## Summary

The program is honest about what it computes and includes explicit statistical caveats where the evidence is thin. The pair structure is the one genuinely extraordinary property — it is vanishingly unlikely by chance. Other findings are either explained by the pair structure (no-5), not significant after Bonferroni correction (entropy), or indistinguishable from pair-constrained random orderings (Markov, path length). The Wald-Wolfowitz runs test detects significant alternation in the difference wave, suggesting the sequence avoids clustering of similar transition sizes.
