# Received Order Analysis Engine (ROAE)

Analysis engine for the [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence)

䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇\
䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏\
䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗\
䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟\
䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧\
䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯\
䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷\
䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

## Summary

A single-file Python analysis engine (no external dependencies) that approaches the King Wen sequence from nearly every mathematical angle available. It started as a script verifying a known structural property of the sequence and grew into a comprehensive toolkit for studying the combinatorial structure of an ancient Chinese ordering system.

Note: this program analyzes the mathematical structure of the ordering only. The [I Ching](https://en.wikipedia.org/wiki/I_Ching) is a foundational text of Chinese philosophy, divination, and cosmology with over three millennia of commentary and practice. This program does not address the philosophical, divinatory, or literary dimensions of the text.

## Guide

New to the I Ching or combinatorics? See [GUIDE.md](GUIDE.md) for a plain-language introduction to the King Wen sequence and how to read this program's output.

## Solver

Can the King Wen sequence be reconstructed from its mathematical constraints? See [SOLVE.md](SOLVE.md) for the generative recipe and constraint narrowing analysis (`solve.py`).

## Example

See [example output](example/README.md) for full program output.

## Observations

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is traditionally attributed to [King Wen of Zhou](https://en.wikipedia.org/wiki/King_Wen_of_Zhou) (~1000 BCE). It is not random, but it's also not optimized for any single obvious metric. The evidence stacks up:

- **The pair structure is perfect** — every one of the 32 pairs is a reverse or inverse, and zero random permutations out of 10,000 achieved this.
- **The no-5-line property is real but not astronomically rare** — about 1 in 550 random orderings share it. Notable, not miraculous.
- **Combined constraints are rare but context matters** — zero unconstrained random permutations satisfy both the pair structure AND the no-5 property together. However, among orderings that already satisfy the pair constraint, ~4% also avoid 5-line transitions (~1 in 23). The pair structure largely explains the no-5 property, since within-pair transitions are always even-distance.
- **It's more structured than random** — entropy sits at the 13th percentile, meaning it's more ordered than 87% of random permutations.
- **The wave has no detectable periodicity** — autocorrelation drops off immediately, and the FFT shows no dominant frequency, though with only N=63 data points the statistical power to detect weak periodicity is limited.
- **The Markov transition matrix is not unusual** — a permutation test shows King Wen's transition structure is at the 43rd percentile, indistinguishable from random orderings. Apparent patterns (e.g., "6 is always followed by 2") are based on small samples and are not statistically significant.
- **The path length is typical for its structure** — compared against unconstrained random orderings, King Wen appears rough (97th percentile, 3.35x a Gray code). But compared against the correct null model (random orderings that also satisfy the pair constraint), it's at the 29th percentile — completely typical.
- **Complements are deliberately close** — King Wen places complementary hexagrams significantly closer than random (0th percentile), suggesting intentional organization around opposition.
- **The XOR algebra is clean** — 32 pairs produce only 7 unique XOR products, suggesting the pairing system has deeper algebraic regularity.
- **Palindromes, canon split, recurrence, and neighborhoods are unremarkable** — under appropriate null models, all are within chance expectations. Palindromes are at the 49th percentile (pair-constrained), the canon split at the 12th, recurrence at the 72nd, and neighborhoods at the 12th.
- **King Wen is unique among known orderings** — neither the [Fu Xi](https://en.wikipedia.org/wiki/Shao_Yong) (binary) ordering nor the [Mawangdui](https://en.wikipedia.org/wiki/Mawangdui_Silk_Texts) silk manuscript ordering avoids 5-line transitions.

The picture that emerges is of a sequence designed under multiple simultaneous constraints — pair relationships and avoidance of certain transitions — none of which individually are impossible by chance, but which together are vanishingly unlikely. The designers (whoever they were, [~3000 years ago](https://en.wikipedia.org/wiki/King_Wen_of_Zhou)) appear to have been working with combinatorial rules.

Note: with 28 analyses, some results will appear unusual by chance alone. The strongest findings (pair structure, combined constraints) survive multiple comparison correction. Weaker findings should be interpreted with caution. See [CRITIQUE.md](CRITIQUE.md) for known limitations.

See [MCKENNA.md](MCKENNA.md) for how these findings relate to [Terence McKenna's Timewave Zero theory](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero).

## Usage

```
python3 roae.py              # Run all 28 analyses (default)
python3 roae.py --quick      # Run core sections only (fast)
python3 roae.py --table      # Run a specific section
python3 roae.py --help-sections  # List all available sections
python3 roae.py --self-test  # Verify data integrity (21 checks)
```

### Analysis sections (28)

| Flag | Description |
|------|-------------|
| `--table` | Hexagram reference table with binary encoding, trigrams, and names |
| `--pairs` | Reverse vs. inverse pair analysis — tests the pairing structure |
| `--wave` | First-order difference wave — the core 'signal' of the King Wen sequence |
| `--trigrams` | Trigram frequency, transitions, and 8x8 transition matrices |
| `--nuclear` | Nuclear hexagram chains — hidden inner hexagram derivations |
| `--lines` | Line change positional analysis — which lines change most often |
| `--complements` | Complement distance — where each hexagram's opposite sits |
| `--palindromes` | Palindrome search in the difference wave |
| `--canons` | Upper Canon (1-30) vs. Lower Canon (31-64) statistical comparison |
| `--hamming` | Full 64x64 Hamming distance matrix |
| `--autocorrelation` | Autocorrelation — tests for hidden periodicity |
| `--entropy` | Shannon entropy — how structured vs. random the wave is |
| `--path` | Graph theory path analysis — is King Wen an efficient route? |
| `--stats` | Monte Carlo — probability of the 'no 5-line transitions' property |
| `--fft` | Spectral analysis (DFT) — frequency decomposition of the wave |
| `--markov` | Markov chain — do difference values predict the next value? |
| `--graycode` | Gray code comparison — King Wen vs. theoretically smoothest path |
| `--symmetry` | XOR group algebra — algebraic structure of the pairing system |
| `--sequences` | Compare King Wen vs. Fu Xi vs. Mawangdui orderings |
| `--constraints` | Constraint satisfaction — how rare is King Wen's combined properties? |
| `--barchart` | ASCII bar chart visualization of the difference wave |
| `--windowed-entropy` | Sliding window entropy — where structure concentrates |
| `--mutual-info` | Mutual information between upper/lower trigram changes |
| `--bootstrap` | Bootstrap confidence intervals for Monte Carlo estimates |
| `--yinyang` | Yin-yang balance wave through the sequence |
| `--neighborhoods` | Hamming distance-1 neighborhoods for each hexagram |
| `--recurrence` | Recurrence plot — where the difference wave repeats |
| `--codons` | DNA codon mapping — structural comparison with genetics |

### Interactive modes

```
python3 roae.py --lookup 1           # Look up by number
python3 roae.py --lookup "creative"  # Look up by name
python3 roae.py --compare 1 2        # Compare two hexagrams
python3 roae.py --cast               # Simulate an I Ching reading (three-coin method)
python3 roae.py --explain 1          # Step-by-step walkthrough of transition 1
```

### Modifiers

| Flag | Description |
|------|-------------|
| `--quick` | Run core sections only (table, pairs, wave, barchart, trigrams, canons, graycode, stats) |
| `--wrap` | Include 64->1 wrap-around transition in wave |
| `--order N` | Compute Nth order of difference (default: 1) |
| `--trials N` | Number of Monte Carlo trials (default: 100000) |
| `--seed N` | Random seed for reproducible results (omit for random). Each analysis section re-seeds independently, so results are identical regardless of which sections run or output format used. |
| `--color` | Enable ANSI color output |

### Export formats

```
python3 roae.py --json      # writes hexagrams.json
python3 roae.py --csv       # writes hexagrams.csv
python3 roae.py --dot       # writes wave.dot (+ wave.dot.png/.svg if Graphviz installed)
python3 roae.py --svg       # writes hexagrams.svg
python3 roae.py --html      # writes report.html (+ report.pdf if wkhtmltopdf installed)
python3 roae.py --markdown  # writes report.md
python3 roae.py --midi      # writes wave.mid
```

### Verification

```
python3 roae.py --self-test  # 21 mathematical invariant checks
```

Verifies data integrity, pair structure, no-5-line property, yin-yang balance, trigram distribution, lookup table consistency, and mathematical function correctness.

## Requirements

Python 3.6+ with no external dependencies (stdlib only).

Reproducibility note: `--seed N` produces deterministic results, but Python's `random` module implementation may vary across Python versions. The example output was generated with Python 3.12. Results with the same seed on different Python versions may differ slightly.

Optional external programs for export formats:
- [Graphviz](https://graphviz.org/) — `--dot` auto-generates PNG and SVG alongside the DOT file (`sudo apt install graphviz`)
- [wkhtmltopdf](https://wkhtmltopdf.org/) — `--html` auto-generates a PDF alongside the HTML report (`sudo apt install wkhtmltopdf`)

## References

* [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) — Wikipedia
* [King Wen of Zhou](https://en.wikipedia.org/wiki/King_Wen_of_Zhou) — Wikipedia (traditional attribution, ~1000 BCE; modern scholarship is divided on the exact origin and dating of the sequence)
* [OEIS A102241](https://oeis.org/A102241) — binary encoding of King Wen hexagrams
* [Bagua (eight trigrams)](https://en.wikipedia.org/wiki/Bagua) — Wikipedia (trigram names and associations)
* [Hexagram (I Ching)](https://en.wikipedia.org/wiki/Hexagram_(I_Ching)) — Wikipedia (hexagram structure, nuclear trigrams)
* [I Ching divination](https://en.wikipedia.org/wiki/I_Ching_divination) — Wikipedia (three-coin method)
* [Shao Yong](https://en.wikipedia.org/wiki/Shao_Yong) — Wikipedia (Fu Xi binary ordering)
* [Mawangdui Silk Texts](https://en.wikipedia.org/wiki/Mawangdui_Silk_Texts) — Wikipedia (alternative hexagram ordering, 168 BCE)
* [The I Ching or Book of Changes](https://press.princeton.edu/books/hardcover/9780691097503/the-i-ching-or-book-of-changes) — Richard Wilhelm, trans. Cary F. Baynes, Princeton University Press (hexagram names)
* Richard A. Kunst, "The Original 'Yijing': A Text, Phonetic Transcription, Translation, and Indexes, with Sample Glosses," Ph.D. dissertation, University of California, Berkeley, 1985
* Edward L. Shaughnessy, *I Ching: The Classic of Changes*, Ballantine Books, 1996 (Mawangdui manuscript translation)
* [Terence McKenna: Novelty theory and Timewave Zero](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero) — Wikipedia
* *The Invisible Landscape* — Terence McKenna and Dennis McKenna, Seabury Press, 1975 (earliest published source for the no-5-line-transition observation)
* [Genetic code](https://en.wikipedia.org/wiki/Genetic_code) — Wikipedia (64 codons, degeneracy)
* [DNA and RNA codon tables](https://en.wikipedia.org/wiki/DNA_and_RNA_codon_tables) — Wikipedia (standard codon table)

## Built with

[Claude Code](https://claude.ai/code) (Anthropic)

## License

Public domain ([Unlicense](https://unlicense.org)).
