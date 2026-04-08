# Guide to ROAE

A plain-language introduction to the King Wen sequence and what this program does with it.

## What is the King Wen sequence?

The [I Ching](https://en.wikipedia.org/wiki/I_Ching) (Book of Changes) is one of the oldest texts in Chinese civilization, dating back over 3,000 years. At its core are 64 symbols called [hexagrams](https://en.wikipedia.org/wiki/Hexagram_(I_Ching)) — each is a stack of six lines, where each line is either solid (yang) or broken (yin). With two possibilities per line and six lines, there are exactly 2^6 = 64 possible hexagrams.

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is the traditional ordering of these 64 hexagrams. It is not the only possible ordering — there are 64! (approximately 10^89) ways to arrange 64 objects — but it is the one that has been used for millennia and is traditionally attributed to [King Wen of Zhou](https://en.wikipedia.org/wiki/King_Wen_of_Zhou) (~1000 BCE), though modern scholarship is divided on the exact origin.

The ordering is not alphabetical, not sorted by number of solid lines, and not random. It appears to follow rules, but those rules were never written down. This program tries to figure out what those rules are.

## Why should I care?

The King Wen sequence is one of the oldest known examples of deliberate combinatorial design. Whoever created it was working with mathematical rules — pairing, complementation, transition constraints — roughly 2,500 years before the formal study of combinatorics began in Europe. The sequence predates Euler, Pascal, and even Euclid.

This doesn't mean the creators thought of it as "mathematics." They may have understood the structure through divination practice, cosmological principles, or aesthetic intuition. But the result is a permutation of 64 objects that satisfies constraints which are vanishingly unlikely by chance. Understanding what those constraints are — and which apparent patterns are real versus illusory — is the point of this program.

## What is this program doing?

Think of it this way: you have 64 unique tiles and someone arranged them in a specific order thousands of years ago. You want to know:

1. **Is this arrangement special?** Or could it have happened by chance?
2. **What rules does it follow?** Are there patterns in which tiles are placed next to each other?
3. **How special is it?** If you shuffled the tiles randomly 10,000 times, how often would you get something with the same properties?

The program answers these questions by treating each hexagram as a 6-digit binary number and analyzing the mathematical relationships between consecutive hexagrams in the sequence.

## Quick start

```
python3 roae.py --quick          # 8 core analyses, runs in seconds
python3 roae.py                  # All 28 analyses (a minute or two)
python3 roae.py --seed 42        # Same as above, but reproducible
python3 roae.py --lookup 1       # Look up a specific hexagram
python3 roae.py --cast           # Simulate a traditional I Ching reading
```

### What --cast looks like

The `--cast` flag simulates a traditional [three-coin method](https://en.wikipedia.org/wiki/I_Ching_divination) reading. Three coins are tossed six times to build a hexagram line by line:

```
  Line 1: coins=3+3+3=9  ----o---- old yang (changing)
  Line 2: coins=3+3+2=8  ---   --- young yin
  Line 3: coins=2+3+2=7  --------- young yang
  Line 4: coins=3+3+3=9  ----o---- old yang (changing)
  Line 5: coins=2+3+3=8  ---   --- young yin
  Line 6: coins=3+3+3=9  ----o---- old yang (changing)

  Primary hexagram: 30 ䷝ The Clinging
  Changing lines: 1, 4, 6
  Relating hexagram: 15 ䷎ Modesty
```

"Changing" lines (marked with `o` or `x`) transform to produce a second hexagram. In traditional practice, the primary hexagram describes the current situation and the relating hexagram shows its trajectory. Each run produces a different result (unless you use `--seed`).

## What a hexagram looks like

A hexagram is read bottom to top. Each line is either solid (yang, 1) or broken (yin, 0):

```
Line 6 (top):    -------   1       Hexagram 1        Hexagram 2
Line 5:          -------   1       The Creative ䷀    The Receptive ䷁
Line 4:          -------   1
Line 3:          -------   1       -------            --- ---
Line 2:          -------   1       -------            --- ---
Line 1 (bottom): -------   1       -------            --- ---
                                   -------            --- ---
                 Binary: 111111    -------            --- ---
                                   -------            --- ---

                                   111111             000000
```

The binary encoding reads bottom to top: line 1 is the rightmost bit, line 6 is the leftmost. So `010001` means lines 1 and 5 are solid, the rest broken.

Each hexagram is also split into two halves called **trigrams** — the bottom three lines (lower trigram) and the top three lines (upper trigram). There are 8 possible trigrams, giving 8 x 8 = 64 possible hexagrams.

## Key concepts

### Hamming distance

The "distance" between two hexagrams is the number of lines that differ. For example:

```
Hexagram 1 (The Creative):  ䷀  111111  (all solid)
Hexagram 2 (The Receptive): ䷁  000000  (all broken)
Distance: 6 (every line is different)
```

When you go from one hexagram to the next in the King Wen sequence, some number of lines change (1 through 6). This number is the **Hamming distance**, and the sequence of these distances is called the **difference wave** — it's the core "signal" the program analyzes.

### Pairs

The 64 hexagrams in the King Wen sequence are grouped into 32 consecutive pairs (1-2, 3-4, ..., 63-64). Every single pair has one of two relationships:

- **Reverse**: flip the hexagram upside down and you get its partner (28 pairs)
- **Inverse**: toggle every line (solid becomes broken, broken becomes solid) and you get its partner (4 pairs)

This is a *perfect* pairing — no exceptions across all 32 pairs. The program tests how likely this is by chance.

### Percentile

Many analyses compare King Wen against thousands of random orderings of the same 64 hexagrams. The **percentile** tells you where King Wen falls in that distribution:

- **5th percentile** means 95% of random orderings scored higher — King Wen is unusually low
- **50th percentile** means King Wen is right in the middle — typical, unremarkable
- **95th percentile** means only 5% of random orderings scored higher — King Wen is unusually high

Whether "low" or "high" is interesting depends on the metric. For entropy (disorder), low means more structured. For path length (total distance), high means rougher transitions.

### Multiple comparisons

The program runs 28 different analyses. Even with purely random data, you'd expect about 1.4 of those to appear "significant" at the 5% level just by chance. The program uses [Bonferroni correction](https://en.wikipedia.org/wiki/Bonferroni_correction) to account for this: a finding must reach p < 0.0018 (not just p < 0.05) to be considered significant after correction.

### Glossary

Terms used in the program output:

- **Bonferroni correction** — A method for adjusting significance thresholds when running multiple tests. Divides the significance level (0.05) by the number of tests (28), giving a stricter threshold of 0.0018.
- **Cohen's d** — A measure of effect size. Values of 0.2, 0.5, and 0.8 are conventionally considered small, medium, and large effects. Reported alongside percentiles to show how far King Wen deviates from random, not just whether it deviates.
- **DFT / FFT** — Discrete Fourier Transform. Decomposes the difference wave into frequency components to check for hidden periodicity (repeating patterns at regular intervals).
- **Gray code** — An ordering where consecutive items differ by exactly one bit — the theoretically smoothest possible path through all 64 hexagrams. Used as a baseline to measure how "rough" King Wen's transitions are.
- **Monte Carlo** — A method that uses repeated random sampling to estimate probabilities. The program shuffles the 64 hexagrams thousands of times and counts how often the shuffled orderings share a property with King Wen.
- **Nuclear hexagram** — A derived hexagram formed by taking the inner four lines (2-5) of a hexagram and splitting them into new upper and lower trigrams. A fixed property of the binary encoding, not of the ordering.
- **Shannon entropy** — A measure of disorder or unpredictability. Maximum entropy means all values are equally likely (random); low entropy means some values dominate (structured).
- **XOR** — Exclusive OR, a bitwise operation. When applied to two hexagrams, it produces a third hexagram representing their "difference." The XOR products of King Wen's pairs show algebraic regularity.

## How to read the key sections

### --pairs (Reverse vs. Inverse pair analysis)

This section checks each of the 32 consecutive pairs and classifies them as reverse, inverse, or neither. The key result: all 32 are one or the other. The program tests how often this happens by chance — the answer is effectively never (0 out of 10,000 random permutations).

**What it means:** Whoever arranged the sequence deliberately placed each hexagram next to its mirror image or its opposite. This is the strongest finding in the entire program.

### --wave (First order of difference)

This section computes the Hamming distance between each pair of consecutive hexagrams, producing 63 values (for 64 hexagrams). These values range from 1 to 6, but notably, 5 never appears — no two consecutive hexagrams in the King Wen sequence differ by exactly 5 lines.

**What it means:** The absence of 5-line transitions is real but largely explained by the pair structure. Within reverse/inverse pairs, 5-line transitions are mathematically impossible.

### --stats (Monte Carlo analysis)

This section shuffles the 64 hexagrams randomly (typically 100,000 times) and checks how many shuffles also avoid 5-line transitions. The answer is about 1 in 550 — unusual but not miraculous.

**What it means:** The no-5 property by itself is notable (like being dealt a specific two-pair hand in poker) but not extraordinary. The pair structure is what's truly rare.

### --constraints (Constraint satisfaction)

This section tests both constraints together: perfect pair structure AND no 5-line transitions. Zero random permutations satisfy both. But there's a crucial subtlety: among orderings that already have perfect pair structure, about 4% also avoid 5-line transitions. So the no-5 property is mostly a *consequence* of the pair structure, not an independent constraint.

**What it means:** The sequence was designed under deliberate mathematical rules. The pair structure is the primary constraint; the no-5 property follows largely from it.

### --entropy (Shannon entropy)

Entropy measures disorder. High entropy means the difference values are spread evenly (random-looking); low entropy means certain values dominate (structured). King Wen sits at about the 13th percentile — more structured than 87% of random orderings, but not significant after correcting for multiple comparisons.

**What it means:** The sequence is somewhat more ordered than random, but this alone doesn't prove intentional design.

### --complements (Complement distance)

Each hexagram has a complement — the hexagram you get by toggling every line. This section measures how far apart each hexagram and its complement are in the sequence. King Wen places complements significantly closer together than random (0th percentile).

**What it means:** The sequence was deliberately organized around opposition — complementary hexagrams are placed near each other. This is a genuine finding.

## Summary of findings

| Finding | Strength | Survives correction? |
|---------|----------|---------------------|
| Perfect pair structure (all 32 pairs) | Very strong | Yes |
| Complement distance (0th percentile) | Strong | Yes |
| XOR algebraic regularity (7 products) | Notable | Not tested |
| No 5-line transitions (~1 in 550) | Moderate | Marginal |
| Entropy (13th percentile) | Weak | No |
| No detectable periodicity | Null result | N/A |
| Markov transitions (43rd percentile) | Not significant | No |
| Path length, pair-constrained (29th percentile) | Not significant | No |
| Palindromes, pair-constrained (49th percentile) | Not significant | No |
| Canon split (12th percentile) | Not significant | No |
| Recurrence rate (72nd percentile) | Not significant | No |
| Neighborhood clustering (12th percentile) | Not significant | No |

The pair structure and complement distance are genuinely extraordinary. Everything else is either explained by the pair structure, not statistically significant, or both.

## Frequently asked questions

**Does this prove the I Ching is mathematical?**

It proves the *ordering* of the hexagrams was constructed under mathematical constraints, whether or not the creators would have described it that way. It says nothing about the text, the divination practice, or the philosophical tradition — those are entirely separate from the sequence structure.

**What about Timewave Zero?**

Terence McKenna believed the difference wave encoded a fractal pattern mapping onto human history. This program computes the same difference wave McKenna used but does not implement his fractal expansion step. The program's findings challenge several of McKenna's specific claims — see [MCKENNA.md](MCKENNA.md) for details.

**Why does 5 never appear in the difference wave?**

Because of the pair structure. Within each reverse or inverse pair, the Hamming distance is always even (for reverse pairs) or exactly 6 (for inverse pairs), so a distance of 5 is impossible within pairs. At the 31 between-pair boundaries, 5 *could* appear but doesn't — though about 4% of pair-constrained orderings also avoid it, so it's not as rare as it first appears.

**What is the single most important finding?**

The perfect pair structure. Every one of the 32 consecutive pairs is either a reverse or an inverse — no exceptions. Zero out of 10,000 random permutations achieved this. It's the one finding that is both statistically extraordinary and not explained by any simpler property.

**Is the complement distance finding new?**

The program discovers that King Wen places complementary hexagrams significantly closer together than random (0th percentile). This appears to be a genuine design constraint that hasn't been widely discussed in prior analyses.

**Can I trust the percentiles?**

The percentiles are Monte Carlo estimates based on 10,000-100,000 random permutations. With `--seed`, they are reproducible. They are precise enough to distinguish "clearly significant" from "clearly not significant" but should not be interpreted to decimal-point precision — a result at the 12th percentile and one at the 14th percentile are functionally the same.

## Where to go deeper

- [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md) — Plain-language summary of how the King Wen sequence was built (start here)
- [SOLVE.md](SOLVE.md) — Full technical details: the constraint solver and generative recipe (`solve.py`)
- [MCKENNA.md](MCKENNA.md) — How these findings relate to Terence McKenna's Timewave Zero theory, what holds up and what doesn't
- [CRITIQUE.md](CRITIQUE.md) — Known limitations of the program's statistical methodology
- [Example output](example/README.md) — Full program output with all 28 analyses
- Run it yourself: `python3 roae.py --seed 42` for reproducible results, or just `python3 roae.py` for a fresh random run
