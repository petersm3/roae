# Mathematical Critique of ROAE

A critical review of the program's methodology, assumptions, and interpretive claims from a mathematical perspective.

## Data correctness

- The binary hexagram encodings claim to follow [OEIS A102241](https://oeis.org/A102241), but the bit ordering convention (bit 0 = bottom line) is one of several in use. Some sources use bit 0 = top line. If the convention is wrong, every analysis built on it (reverse pairs, trigram decomposition, nuclear hexagrams) produces different results. The program should state its convention explicitly and ideally verify against a second independent source.
- The hexagram names are attributed to the "Wilhelm/Baynes translation" but several are simplified or variant. A rigorous treatment would cite each name individually, not give a blanket attribution.
- The Mawangdui ordering was recomputed from trigram cycling rules, but the actual silk manuscript ordering has scholarly disagreements. The program treats one reconstruction as definitive.

## Statistical methodology

- The Monte Carlo analyses use `random.shuffle` (Mersenne Twister PRNG), which is not cryptographically random. For the sample sizes involved this doesn't matter, but it is an unstated assumption.
- The "1 in 550" figure for no-5-transitions varies between runs. The `--bootstrap` gives confidence intervals, but the base Monte Carlo and the bootstrap use the same PRNG — they are not independent. A proper bootstrap would fix the random seed for reproducibility or report the seed used.
- The constraint satisfaction test (`--constraints`) only runs 10,000 trials. Finding 0 hits out of 10,000 means the true rate could be anywhere from 0% to ~0.03% (upper bound of a 95% CI for observing 0 in 10k). The program says "vanishingly unlikely" but cannot distinguish "impossible" from "1 in 50,000."
- The entropy percentile comparison shuffles the binary values of the 64 hexagrams, preserving the set of values but randomizing their order. This is the right null model for "is this ordering special?" but it is not the only possible null model. You could also ask "among all orderings that satisfy the pair constraint, is King Wen's entropy unusual?" — a much harder but more relevant question.

## Analytical claims with insufficient statistical power

- The autocorrelation "shows no periodicity" — but the sequence is only 63 points long. With N=63, you have very limited statistical power to detect periodicity. A lag-2 correlation of -0.01 with N=63 has a standard error of ~0.13, meaning anything between -0.26 and +0.26 is indistinguishable from noise. The program presents these small values as meaningful zeros when they are actually "we can't tell."
- The DFT has the same problem — 63 samples gives 31 frequency bins, each with wide uncertainty. No peak being "dominant" could mean there is no periodicity, or it could mean the sequence is too short to detect it.
- The mutual information calculation uses binary variables (changed/unchanged) which throws away information. Computing MI on the actual trigram identities (8 possible values each) would be more informative.
- "The Markov transitions show patterns" — with only 63 transitions distributed across 5 states, most cells in the transition matrix have counts of 1-6. "1 is always followed by 6" is based on N=2 observations. That is not a pattern; it is an anecdote.
- The path analysis compares King Wen against random paths, but the right comparison would be against random paths that also satisfy the pair constraint. King Wen's path length might be typical or even short among pair-constrained orderings.

## Logical issues

- "Perfect yin-yang balance (192 each)" is presented as a finding but is a necessary consequence of containing all 64 hexagrams. It is a tautology, like noting that all 64 values are distinct.
- The claim that "the designers appear to have been working with a sophisticated understanding of combinatorial structure" is an inference, not a finding. The pair structure could arise from a simple rule ("always place a hexagram next to its mirror or opposite") without any understanding of combinatorics.
- The nuclear hexagram analysis is purely descriptive — it shows the chains but never tests whether the chain structure is unusual compared to random orderings. Without a null model, it is not clear if the chains are notable.

## Missing analyses

- No permutation test for the Markov structure — is the observed transition matrix more structured than what random orderings produce?
- No correction for multiple comparisons — with 33 analyses, some will show "unusual" results by chance even for a random ordering.
- No sensitivity analysis — how do the results change if you use a different bit-ordering convention?

## Summary

The program is honest about what it computes, but the interpretive language — "extraordinary," "vanishingly unlikely," "hidden structure" — sometimes outruns the statistical evidence, particularly where sample sizes are small (N=63) and null models are narrow. The strongest claims (perfect pair structure, combined constraint rarity) are well-supported. The weaker claims (no periodicity, Markov patterns, signal encoding) would benefit from more rigorous null models and explicit acknowledgment of limited statistical power.
