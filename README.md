# Received Order Analysis Engine (ROAE)

> **Research in progress.** This project is under active development. Findings are preliminary, based on partial enumeration (no branch of the search tree has been fully explored), and subject to revision as the analysis deepens. Earlier versions of this documentation contained claims that were later invalidated by larger-scale computation — see commit history for the evolution of findings. Nothing here should be treated as definitive.

Analysis engine for the [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence)

<mark>**[䷀䷁](SOLVE-SUMMARY.md)**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

## Summary

An analysis engine that approaches the King Wen sequence from nearly every mathematical angle available. It started as a script verifying a known structural property of the sequence and grew into a comprehensive toolkit for studying the combinatorial structure of an ancient Chinese ordering system.

Note: this program analyzes the mathematical structure of the ordering only. The [I Ching](https://en.wikipedia.org/wiki/I_Ching) is a foundational text of Chinese philosophy, divination, and cosmology with over three millennia of commentary and practice. This program does not address the philosophical, divinatory, or literary dimensions of the text.

## Guide

New to the I Ching or combinatorics? See [GUIDE.md](GUIDE.md) for a plain-language introduction to the King Wen sequence and how to read this program's output.

## Solver

Can the King Wen sequence be reconstructed from its mathematical constraints? Five constraints narrow 10^89 possibilities to billions of valid orderings. Canonical counts:
- **d3 100T: 3,432,399,297** (sha `915abf30…`, 2026-04-20, current deepest)
- **d3 10T: 706,422,987** (sha `f7b8c4fb…`)
- **d2 10T: 286,357,503** (sha `a09280fb…`)

All three are partial enumerations at different partition strategies and node budgets; under true exhaustive enumeration they would converge.

The **number of boundary constraints needed to uniquely identify King Wen grows with partition depth**: 4 at 10T (d2 and d3), **5 at 100T d3** (greedy-optimal set {1, 4, 21, 25, 27}). Boundaries **{25, 27}** remain mandatory at all three partitions (most stable structural finding). See [SPECIFICATION.md](SPECIFICATION.md) for the formal definition, [SOLVE.md](SOLVE.md) for the constraint analysis (`solve.py` + `solve.c`), or [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md) for a plain-language version. The binary output format is in [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md); [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md) is a step-by-step recipe for building an independent verifier from those two specs alone. Enumeration results are in `enumeration/`.

**Important methodological note.** Constraints C1–C2 (pair structure, no 5-line transitions) are genuinely rare statistical properties of King Wen — the pair structure does not appear in any random permutation we tested (0 of 1.86 billion across seven null-model families). Constraint C3 (complement distance ≤ 776) is a ceiling constraint using KW's own value; per the 100T d3 analysis, **KW sits AT the C3 ceiling, not the floor** — 340 million records (9.91%) tie with KW at C3=776, and the true minimum is 424 (221 records). Constraints C4–C7 were **extracted from King Wen** (exact starting pair, exact distance distribution, specific boundary adjacencies) and then shown to be highly constraining against King Wen. A null-model test (see [CRITIQUE.md](CRITIQUE.md)) found that applying the same extraction methodology to random pair-constrained sequences also produces apparent "uniqueness" in 9/10 cases. The honest claim is therefore: *pair structure + no-5 are the robust findings against random; the "N boundaries uniquely determine KW" result is partition-depth-dependent (N = 4 at 10T, 5 at 100T, possibly larger at deeper enumeration) and reflects the constraint-extraction methodology rather than evidence of KW's inherent specialness beyond the robust findings.*

## Example

See [example output](example/README.md) for a full run of `roae.py` against the King Wen sequence — hexagram reference tables, 28 statistical analyses, and derived visualizations (`.csv`, `.json`, `.svg`, `.html`, `.pdf`, MIDI wave rendering).

### `roae.py` vs `solve.c` — two different kinds of output

These are easy to confuse; they serve different roles:

| | `roae.py` → `example/` | `solve.c` → `solve_c/runs/<run>/` |
|---|---|---|
| **What it analyzes** | King Wen itself as a given 64-hexagram sequence | The full space of 10^89 possible orderings, filtered to solutions satisfying C1-C5 |
| **Output** | Descriptive statistics about KW (trigrams, pair structure, entropy, complement distances, palindromes, Markov patterns, Gray-code comparisons, 28 analyses total) | Enumeration artifacts: `solutions.bin` (millions of valid orderings), `solutions.sha256` (reproducibility anchor), `analyze_output.log.gz` (statistics across the solution set) |
| **Deterministic?** | Fully — the sequence is fixed, analyses are closed-form | Fully — given fixed solver + inputs, `solutions.bin` is byte-identical (partition invariance) |
| **Scale** | Single sequence, prints instantly | Hundreds of millions of orderings; canonical runs take hours on D128 |
| **Dependencies** | Python 3 stdlib only (optional deps for `.pdf`, `.html`, `.mid`) | `gcc`, `pthread`, `sha256sum` (no library dependencies) |
| **Who reads it** | Anyone curious about KW's internal structure (the "what"); no enumeration insight | Researchers evaluating the uniqueness question ("how special is KW among all C1-C5 orderings?") |

Both are committed in the repo. The `example/` output is generated by running `roae.py`; the `solve_c/runs/<run>/` directories archive summaries (sha, meta, compressed logs) of actual enumeration runs against Azure compute. The binary `solutions.bin` files themselves are too large to commit (~10-65 GB each) and live on persistent Azure managed disks — see [enumeration/SOLUTIONS_BIN_LOCATION.txt](enumeration/SOLUTIONS_BIN_LOCATION.txt).

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
- **The XOR algebra is a theorem** — 32 pairs produce only 7 unique XOR products. This is not a property of King Wen — it is a mathematical consequence of any reverse/inverse pairing of 6-bit values (see [SOLVE.md](SOLVE.md#theorem-2-xor-regularity-is-a-theorem-not-a-constraint)).
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

> **See [CITATIONS.md](CITATIONS.md) for the full, formally scoped reference list** — including prior literature on the mathematical structure of the King Wen sequence (Cook 2006, McKenna 1975), methodological citations (Hierholzer, Fisher-Yates, Marsaglia, Bonferroni, Wilson), and explicit attribution of which observations are classical / prior work vs. independently verified computationally by ROAE vs. believed novel here. CITATIONS.md includes a disclaimer inviting updates from readers aware of prior work not cited.

Selected links (non-exhaustive, see CITATIONS.md for the full list):

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
