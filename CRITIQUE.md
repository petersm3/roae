# Mathematical Critique of ROAE

A critical review of the program's methodology, assumptions, and interpretive claims from a mathematical perspective. Items marked [ADDRESSED] have been fixed in the program; items marked [OPEN] remain as known limitations.

## Data correctness

- [OPEN] The binary hexagram encodings claim to follow [OEIS A102241](https://oeis.org/A102241), but the bit ordering convention (bit 0 = bottom line) is one of several in use. Some sources use bit 0 = top line. If the convention is wrong, every analysis built on it (reverse pairs, trigram decomposition, nuclear hexagrams) produces different results. The program should state its convention explicitly and ideally verify against a second independent source.
- [OPEN] The hexagram names are attributed to the "Wilhelm/Baynes translation" but several are simplified or variant. A rigorous treatment would cite each name individually, not give a blanket attribution.
- [OPEN] The Mawangdui ordering was recomputed from trigram cycling rules, but the actual silk manuscript ordering has scholarly disagreements. The program treats one reconstruction as definitive.

## Statistical methodology

- [ADDRESSED] The Monte Carlo analyses use `random.shuffle` (Mersenne Twister PRNG). The `--seed` flag now allows reproducible results.
- [ADDRESSED] The `--bootstrap` gives confidence intervals with labeled progress bars for both sampling and resampling phases.
- [ADDRESSED] The constraint satisfaction test now reports the rule-of-three statistical upper bound when 0 hits are observed (e.g., "95% upper bound: less than 1 in 3,333"), explicitly acknowledging it cannot distinguish "impossible" from "extremely rare."
- [OPEN] The entropy percentile comparison shuffles the binary values of the 64 hexagrams, preserving the set of values but randomizing their order. This is the right null model for "is this ordering special?" but it is not the only possible null model. You could also ask "among all orderings that satisfy the pair constraint, is King Wen's entropy unusual?" — a much harder but more relevant question.

## Analytical claims with insufficient statistical power

- [ADDRESSED] The autocorrelation now shows 95% confidence bands (+/-1.96/sqrt(N)), marks significant lags with `*`, and explicitly notes that N=63 provides limited statistical power. Values within the noise band are labeled as not significant.
- [ADDRESSED] The DFT now shows the white noise floor and marks frequencies above 2x noise floor as significant.
- [ADDRESSED] The mutual information section now includes full 8-state trigram MI (which confirms 0.0 — a tautology for a complete set of 64 hexagrams) alongside the binary version.
- [ADDRESSED] The Markov section now includes a permutation test for matrix concentration (result: 43rd percentile — not unusual) and small-N caveats on all transition patterns with fewer than 5 observations.
- [ADDRESSED] The path analysis now compares against pair-constrained random orderings (the correct null model), revealing that King Wen is at the ~29th percentile — completely typical given its pair structure.

## Logical issues

- [ADDRESSED] The yin-yang balance section now explicitly notes that 192/192 is a necessary consequence of containing all 64 hexagrams, not a finding. The section focuses on local balance instead.
- [OPEN] The claim that "the designers appear to have been working with a sophisticated understanding of combinatorial structure" is an inference, not a finding. The pair structure could arise from a simple rule ("always place a hexagram next to its mirror or opposite") without any understanding of combinatorics.
- [OPEN] The nuclear hexagram analysis is purely descriptive — it shows the chains but never tests whether the chain structure is unusual compared to random orderings. Without a null model, it is not clear if the chains are notable.

## Missing analyses

- [ADDRESSED] Permutation test for Markov structure — added; result shows it is not unusual.
- [ADDRESSED] Multiple comparison note — appended to `--all` output, noting that ~1.7 of 33 tests will appear significant by chance.
- [OPEN] No correction for multiple comparisons is applied to individual test p-values (e.g., Bonferroni).
- [OPEN] No sensitivity analysis — how do the results change if you use a different bit-ordering convention?

## Summary

The program is honest about what it computes and now includes explicit statistical caveats where the evidence is thin. The strongest claims (perfect pair structure, combined constraint rarity) are well-supported and survive scrutiny. Several initially reported "findings" (Markov patterns, unusual path length, yin-yang balance) have been corrected or properly contextualized as either not significant or tautological. The remaining open items are acknowledged limitations rather than errors.
