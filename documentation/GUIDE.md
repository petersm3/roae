# Guide to ROAE

A plain-language introduction to the King Wen sequence and what this program does with it.

> **Going deeper:** once you've read this guide and want to understand HOW the solver actually finds valid orderings — what a "branch" is, what a "node" represents, how the search tree is partitioned — see [BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md). Same plain-language style; takes you a layer deeper into the enumeration mechanics.

## What is the King Wen sequence?

The [I Ching](https://en.wikipedia.org/wiki/I_Ching) (Book of Changes) is one of the oldest texts in Chinese civilization, dating back over 3,000 years. At its core are 64 symbols called [hexagrams](https://en.wikipedia.org/wiki/Hexagram_(I_Ching)) — each is a stack of six lines, where each line is either solid ([yang](https://en.wikipedia.org/wiki/Yin_and_yang)) or broken ([yin](https://en.wikipedia.org/wiki/Yin_and_yang)). With two possibilities per line and six lines, there are exactly 2^6 = 64 possible hexagrams.

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is the traditional ordering of these 64 hexagrams. It is not the only possible ordering — there are 64! (approximately 10^89) ways to arrange 64 objects — but it is the one that has been used for millennia and is traditionally attributed to [King Wen of Zhou](https://en.wikipedia.org/wiki/King_Wen_of_Zhou) (~1000 BCE), though modern scholarship is divided on the exact origin.

The ordering is not alphabetical, not sorted by number of solid lines, and not random. It appears to follow rules, but those rules were never written down. This program tries to figure out what those rules are.

## Why should I care?

The King Wen sequence is one of the oldest known objects exhibiting strong combinatorial structure. However it came to be, the result obeys mathematical regularities — pairing, complementation, transition constraints — that were fixed, under any dating, many centuries before the European combinatorial tradition of Pascal and Euler.

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

For the full command-line reference (all 28 analysis sections, interactive modes, modifiers, and export formats), see [ROAE_PY_CLI.md](ROAE_PY_CLI.md).

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

Each line is either solid (⚊ yang, 1) or broken (⚋ yin, 0):

| | ䷀ The Creative #1 | ䷄ Waiting #5 | ䷁ The Receptive #2 |
|---|:---:|:---:|:---:|
| Line 6 (top) | ⚊ **1** | ⚋ **0** | ⚋ **0** |
| Line 5 | ⚊ **1** | ⚊ **1** | ⚋ **0** |
| Line 4 | ⚊ **1** | ⚋ **0** | ⚋ **0** |
| Line 3 | ⚊ **1** | ⚊ **1** | ⚋ **0** |
| Line 2 | ⚊ **1** | ⚊ **1** | ⚋ **0** |
| Line 1 (bottom) | ⚊ **1** | ⚊ **1** | ⚋ **0** |
| Binary | **111111** | **010111** | **000000** |

To get the binary code, read the 1s and 0s from the top of the table downward. For example, ䷀ The Creative #1 is all solid lines: 111111. ䷁ The Receptive #2 is all broken lines: 000000. ䷄ Waiting #5 reads 0, 1, 0, 1, 1, 1 from top to bottom, giving 010111 — a mix of solid and broken.

Each hexagram is also split into two halves called **trigrams** — the bottom three lines (lower trigram) and the top three lines (upper trigram). There are 8 possible trigrams:

| Trigram | Name | Meaning |
|---------|------|---------|
| ☰ | Qian | Heaven |
| ☷ | Kun | Earth |
| ☳ | Zhen | Thunder |
| ☵ | Kan | Water |
| ☶ | Gen | Mountain |
| ☴ | Xun | Wind |
| ☲ | Li | Fire |
| ☱ | Dui | Lake |

With 8 possible trigrams in each position, there are 8 x 8 = 64 possible hexagrams.

## Key concepts

### [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance)

The "distance" between two hexagrams is the number of lines that differ. For example:

```
Hexagram 1 (The Creative):  ䷀  111111  (all solid)
Hexagram 5 (Waiting):       ䷄  010111  (mixed)
Hexagram 2 (The Receptive): ䷁  000000  (all broken)

Distance between #1 and #2: 6 (every line is different)
Distance between #1 and #5: 3 (three lines differ)
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
- **XOR** — Exclusive OR, a bitwise operation. When applied to two hexagrams, it produces a third hexagram representing their "difference." Any reverse/inverse pairing of 6-bit values produces exactly 7 unique XOR products — this is a mathematical theorem, not a property specific to King Wen.

## How to read the key sections

### --pairs (Reverse vs. Inverse pair analysis)

This section checks each of the 32 consecutive pairs and classifies them as reverse, inverse, or neither. The key result: all 32 are one or the other. The program tests how often this happens by chance — the answer is effectively never (0 out of 10,000 random permutations).

**What it means:** In the sequence, every hexagram sits next to its mirror image or its complement, without exception — a property zero of 10,000 random permutations reproduce. This is the strongest finding in the entire program.

### --wave (First order of difference)

This section computes the Hamming distance between each pair of consecutive hexagrams, producing 63 values (for 64 hexagrams). These values range from 1 to 6, but notably, 5 never appears — no two consecutive hexagrams in the King Wen sequence differ by exactly 5 lines.

**What it means:** The absence of 5-line transitions is real but largely explained by the pair structure. Within reverse/inverse pairs, 5-line transitions are mathematically impossible. This observation is attributed to [Terence & Dennis McKenna (*The Invisible Landscape*, 1975)](CITATIONS.md#mckenna-mckenna1975); see [CITATIONS.md](CITATIONS.md). The property is also present in [Jing Fang](CITATIONS.md#jingfang)'s 8 Palaces arrangement. *(Corrected 2026-07-05: earlier text claimed the Mawangdui ordering shared it too and inferred a classical design principle — that was computed on an erroneous Mawangdui array. The authentic Mawangdui order, per [Shaughnessy 2022](CITATIONS.md#shaughnessy2022) Table 11.2, has exactly one 5-line transition, at its Kan→Zhen octet seam; the shared-design-principle inference is withdrawn.)*

### --stats (Monte Carlo analysis)

This section shuffles the 64 hexagrams randomly (typically 100,000 times) and checks how many shuffles also avoid 5-line transitions. The answer is about 1 in 550 — unusual but not miraculous.

**What it means:** The no-5 property by itself is notable (like being dealt a specific two-pair hand in poker) but not extraordinary. The pair structure is what's truly rare.

### --constraints (Constraint satisfaction)

This section tests both constraints together: perfect pair structure AND no 5-line transitions. Zero random permutations satisfy both. But there's a crucial subtlety: among orderings that already have perfect pair structure, about 4% also avoid 5-line transitions. So the no-5 property is mostly a *consequence* of the pair structure, not an independent constraint.

**What it means:** The sequence satisfies mathematical constraints that are vanishingly unlikely by chance — zero random permutations satisfy both together. The pair structure is the primary constraint; the no-5 property follows largely from it.

### --entropy (Shannon entropy)

Entropy measures disorder. High entropy means the difference values are spread evenly (random-looking); low entropy means certain values dominate (structured). King Wen sits at about the 12th percentile against unconstrained random orderings (6th against the pair-constrained null) — more structured than most, but not significant after correcting for multiple comparisons ([CRITIQUE.md](CRITIQUE.md)).

**What it means:** The sequence is somewhat more ordered than random, but this alone doesn't prove intentional design.

### --complements (Complement distance)

Each hexagram has a complement — the hexagram you get by toggling every line. This section measures how far apart each hexagram and its complement are in the sequence. King Wen places complements significantly closer together than random (0th percentile vs all orderings — the figure this section itself computes). Under the exact pair-constrained (C1&C4) null the tail is 8.1% (`verify.py --check-null-g`); the separately measured 3.9th-percentile figure is at the stricter all-other-constraints scope (C1+C2+C4+C5, from the solve.py differential sample — scope label corrected 2026-07-22). *(**Flagged 2026-08-01, lens sweep** — the 3.9th-percentile figure is not supported by the population it is labelled with; the suite's own ledger gives ≈12% at this scope. Do not cite it: see [SOLVE.md](SOLVE.md) §Rule 3.)*

**What it means:** The sequence keeps opposites unusually close. However, the [constraint solver's null model test](SOLVE_SUMMARY.md#an-important-caveat) shows that complement distance, starting pair, and diff distribution narrow *any* sequence to near-uniqueness — so this property, while real, is less distinctive than the pair structure and no-5 property.

## Summary of findings

| Finding | Strength | Survives correction? |
|---------|----------|---------------------|
| Perfect pair structure (all 32 pairs) | Very strong | Yes |
| Complement distance (0th %-ile unconstrained; 8.1% exact C1&C4 null; 3.9th %-ile at C1+C2+C4+C5 — **flagged, see [SOLVE.md](SOLVE.md) §Rule 3**) | Moderate (see [caveat](SOLVE_SUMMARY.md#an-important-caveat)) | Yes |
| XOR algebraic regularity (7 products) | Theorem (universal) | N/A — true for any pairing |
| No 5-line transitions (~1 in 550) | Moderate | Marginal |
| Entropy (≈12th percentile) | Weak | No |
| No detectable periodicity | Null result | N/A |
| Markov transitions (43rd percentile) | Not significant | No |
| Path length, pair-constrained (29th percentile) | Not significant | No |
| Palindromes, pair-constrained (49th percentile) | Not significant | No |
| Canon split (12th percentile) | Not significant | No |
| Recurrence rate (72nd percentile) | Not significant | No |
| Neighborhood clustering (12th percentile) | Not significant | No |

The pair structure is genuinely extraordinary — zero of 1.86 billion permutations tested across 6 structured and unstructured null-model families satisfy C1 (see [CRITIQUE.md](CRITIQUE.md) for details). Complement distance is also uncommon, though far less extreme (roughly the lowest 8-12% depending on the reference population — 8.1% exact under the bare pair-constrained C1&C4 null, and ≈12% by the ledger at the all-other-constraints C1+C2+C4+C5 scope; the long-published "3.9% sampled" figure at that scope is **flagged 2026-08-01**, see [SOLVE.md](SOLVE.md) §Rule 3 — either way not in the same class as C1's 0-in-1.86B); notably, even random 6-bit Gray codes (explicitly optimized for adjacency) cannot beat KW's 776 total complement distance (minimum observed across 10⁵ random Gray codes: 832). The no-5-line-transition property is real and **shared with Jing Fang 8 Palaces** (2 of 4 tested ancient orderings satisfy it; corrected 2026-07-05 — the authentic Mawangdui order has exactly one 5-line transition at a trigram-octet seam, per Shaughnessy 2022 Table 11.2; an earlier erroneous array scored zero and the former "3 of 4 / classical design principle" claim is withdrawn). The genuinely King-Wen-specific property is the combination (C1 + C2 + C3 together); C3's threshold of 776 is KW's own extracted value, so its "specificity" is definitional rather than a finding (wording corrected 2026-07-22).

The constraint solver (`solve.c`) goes further: 5 rules narrow 10^89 possibilities to billions of valid orderings. Canonical counts:
- **d3 560T partition: 10,525,271,997** (sha `9a968fa2…`, 2026-06-08, CANONICAL-verified 2026-06-30, **current deepest**)
- **d3 100T partition: 3,432,399,297** (sha `915abf30…`, 2026-04-20)
- **d3 10T partition: 706,427,594** (sha `b85c8871…`, re-established 2026-05-13; the earlier `f7b8c4fb…`/706,422,987 is deprecated — pre-resume-fix undercount, see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Deprecated)
- **d2 10T partition: 286,357,503** (sha `a09280fb…`)

Only Position 1 is universally locked. The number of boundary constraints needed to uniquely identify KW is **4 at d2/d3 10T and 5 at both d3 100T and d3 560T** — monotone non-decreasing with scale, with the identical greedy set `{1, 4, 21, 25, 27}` at both canonical scales *(corrected 2026-07-04: an earlier version said "4 again at 560T, non-monotone" — a survivor-counting error; see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md))*. The working-4-set count is scale-bounded (8 at 11.2T, 4 at 742M, 0 at 100T/560T) — at canonical depth no 4-tuple of boundaries jointly identifies KW. Boundaries **{25, 27} remain in every greedy minimum at all four partitions tested** — the single most stable structural finding. See [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md) and [SOLVE.md](SOLVE.md) §Boundary analysis for the full story.

## Frequently asked questions

**Does this prove the I Ching is mathematical?**

It shows the *ordering* of the hexagrams satisfies strict mathematical constraints that are vanishingly unlikely by chance, whether or not whoever arranged it would have described them that way. It says nothing about the text, the divination practice, or the philosophical tradition — those are entirely separate from the sequence structure.

**What about Timewave Zero?**

Terence McKenna believed the difference wave encoded a fractal pattern mapping onto human history. This program computes the same difference wave McKenna used but does not implement his fractal expansion step. The program's findings challenge several of McKenna's specific claims — see [MCKENNA.md](MCKENNA.md) for details.

**Why does 5 never appear in the difference wave?**

Because of the pair structure. Within each reverse or inverse pair, the Hamming distance is always even (for reverse pairs) or exactly 6 (for inverse pairs), so a distance of 5 is impossible within pairs. At the 31 between-pair boundaries, 5 *could* appear but doesn't — though 4.29% of pair-constrained orderings also avoid it (from `solve.c --null-pair-constrained`, 10⁹ samples), so it's not as rare as it first appears. Additionally, Jing Fang's 8 Palaces arrangement also avoids 5-line transitions; the authentic Mawangdui silk-text ordering does not quite — it has exactly one, at its Kan→Zhen octet seam (corrected 2026-07-05; see CITATIONS.md errata).

**What is the single most important finding?**

The perfect pair structure. Every one of the 32 consecutive pairs is either a reverse or an inverse — no exceptions. Zero out of 10,000 random permutations achieved this. It's the one finding that is both statistically extraordinary and not explained by any simpler property.

**Is the complement distance finding new?**

The program finds that King Wen places complementary hexagrams closer together than random (0th percentile against unconstrained random orderings; 8.1% under the exact pair-constrained C1&C4 null, `verify.py --check-null-g`; 3.9th percentile — sampled, and **flagged 2026-08-01**: see [SOLVE.md](SOLVE.md) §Rule 3, the ledger gives ≈12% at that scope — at the stricter C1+C2+C4+C5 scope). It appears to be a genuine structural regularity not widely discussed in prior analyses — with one important scope note: within the fully constrained C1+C2+C3 population, KW sits at the complement-distance *maximum* (most valid orderings place complements closer; see [SOLVE.md](SOLVE.md)).

**Can I trust the percentiles?**

The percentiles are Monte Carlo estimates based on 10,000-100,000 random permutations. With `--seed`, they are reproducible. They are precise enough to distinguish "clearly significant" from "clearly not significant" but should not be interpreted to decimal-point precision — a result at the 12th percentile and one at the 14th percentile are functionally the same.

## Where to go deeper

- [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) — Plain-language summary of how the King Wen sequence is structured (start here)
- [SOLVE.md](SOLVE.md) — Full technical details: the constraint solver and generative recipe (`solve.py`)
- [MCKENNA.md](MCKENNA.md) — How these findings relate to Terence McKenna's Timewave Zero theory, what holds up and what doesn't
- [CRITIQUE.md](CRITIQUE.md) — Known limitations of the program's statistical methodology
- [Example output](../example/README.md) — Full program output with all 28 analyses
- Run it yourself: `python3 roae.py --seed 42` for reproducible results, or just `python3 roae.py` for a fresh random run

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*

*Revision 2026-07-22 (C3 scope-consistency sweep): the 3.9th-percentile complement-distance figure was previously labeled "vs pair-constrained orderings"; its measured scope is C1+C2+C4+C5 (every constraint except C3 itself), and the exact pair-constrained (C1&C4) null tail is 8.1% (`verify.py --check-null-g`). "Genuinely unusual" was softened to "uncommon" for C3 (lowest 4-8% is moderate rarity, not C1-class), and "the specific C3 threshold of 776" was removed from the King-Wen-specific list (definitional — the threshold is KW's own extracted value). No counts or shas changed.*

*Revision 2026-08-01 (lens sweep — C3 percentile flag): the 3.9th-percentile complement-distance figure is **flagged and withdrawn from citation**. It is a statistic of the 13,296-ordering `solve.py` differential slice, whose stated range [11.75, 14.5] cannot be the range of C1+C2+C4+C5 — the strictly smaller C1–C5 canonical contains orderings at cd = 6.125 — and the suite's own ledger gives 1.3287×10³⁸ / 1.097051×10³⁹ ≈ **12%** at that scope. The 2026-07-22 scope correction above fixed the figure's *label*, not the figure. Authoritative statement of the flag, and the measurement that would settle it: [SOLVE.md](SOLVE.md) §Rule 3. No canonical count, sha, or theorem changed.*
