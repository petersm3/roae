# Known Limitations

A review of the program's methodology, assumptions, and interpretive claims from a mathematical perspective.

## Data correctness

- The binary hexagram encodings claim to follow [OEIS A102241](https://oeis.org/A102241), but the bit ordering convention (bit 0 = bottom line) is one of several in use. Some sources use bit 0 = top line. If the convention is wrong, every analysis built on it (reverse pairs, trigram decomposition, nuclear hexagrams) produces different results. The program should state its convention explicitly and ideally verify against a second independent source.
- The hexagram names are attributed to the "Wilhelm/Baynes translation" but several are simplified or variant. A rigorous treatment would cite each name individually, not give a blanket attribution.
- The Mawangdui ordering was recomputed from trigram cycling rules, but the actual silk manuscript ordering has scholarly disagreements. The program treats one reconstruction as definitive.

## Statistical methodology

- The entropy percentile comparison shuffles the binary values of the 64 hexagrams, preserving the set of values but randomizing their order. This is the right null model for "is this ordering special?" but it is not the only possible null model. You could also ask "among all orderings that satisfy the pair constraint, is King Wen's entropy unusual?" — a much harder but more relevant question.

## Analytical claims

- The claim that "the designers appear to have been working with a sophisticated understanding of combinatorial structure" is an inference, not a finding. The pair structure could arise from a simple rule ("always place a hexagram next to its mirror or opposite") without any understanding of combinatorics.
- The nuclear hexagram analysis is purely descriptive — it shows the chains but never tests whether the chain structure is unusual compared to random orderings. Without a null model, it is not clear if the chains are notable.

## Missing analyses

- No correction for multiple comparisons is applied to individual test p-values (e.g., Bonferroni).
- No sensitivity analysis — how do the results change if you use a different bit-ordering convention?

## Summary

The program is honest about what it computes and includes explicit statistical caveats where the evidence is thin. The strongest claims (perfect pair structure, combined constraint rarity) are well-supported and survive scrutiny. The items above are acknowledged limitations rather than errors.
