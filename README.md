# ROAE — Received Order Analysis Engine

Analysis engine for the [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) including observations by [Terence McKenna](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero).

䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇\
䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏\
䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗\
䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟\
䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧\
䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯\
䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷\
䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

## What this is

A single-file Python analysis engine (no external dependencies) that approaches the King Wen sequence from nearly every mathematical angle available. It started as a script verifying a known structural property of the sequence and grew into a comprehensive toolkit for studying the combinatorial structure of an ancient Chinese ordering system.

## What the analyses reveal

The King Wen sequence is not random, but it's also not optimized for any single obvious metric. The evidence stacks up:

- **The pair structure is perfect** — every one of the 32 pairs is a reverse or inverse, and zero random permutations out of 10,000 achieved this.
- **The no-5-line property is real but not astronomically rare** — about 1 in 550 random orderings share it. Notable, not miraculous.
- **Combined constraints are extraordinary** — zero random permutations satisfy both the pair structure AND the no-5 property together (95% upper bound: less than 1 in 3,333).
- **It's more structured than random** — entropy sits at the 13th percentile, meaning it's more ordered than 87% of random permutations.
- **The wave has no detectable periodicity** — autocorrelation drops off immediately, and the FFT shows no dominant frequency, though with only N=63 data points the statistical power to detect weak periodicity is limited.
- **The Markov transition matrix is not unusual** — a permutation test shows King Wen's transition structure is at the 43rd percentile, indistinguishable from random orderings. Apparent patterns (e.g., "6 is always followed by 2") are based on small samples and are not statistically significant.
- **The path length is typical for its structure** — compared against unconstrained random orderings, King Wen appears rough (97th percentile, 3.35x a Gray code). But compared against the correct null model (random orderings that also satisfy the pair constraint), it's at the 29th percentile — completely typical.
- **The XOR algebra is clean** — 32 pairs produce only ~12 unique products, suggesting the pairing system has deeper algebraic regularity.
- **King Wen is unique among known orderings** — neither Fu Xi nor Mawangdui avoids 5-line transitions.

The picture that emerges is of a sequence designed under multiple simultaneous constraints — pair relationships and avoidance of certain transitions — none of which individually are impossible by chance, but which together are vanishingly unlikely. The designers (whoever they were, ~3000 years ago) appear to have been working with combinatorial rules, even if they wouldn't have described them in mathematical terms.

Note: with 33 analyses, some results will appear unusual by chance alone. The strongest findings (pair structure, combined constraints) survive multiple comparison correction. Weaker findings should be interpreted with caution. See [CRITIQUE.md](CRITIQUE.md) for a full mathematical review.

See [MCKENNA.md](MCKENNA.md) for how these findings relate to Terence McKenna's Timewave Zero theory.

## Usage

```
python3 roae.py              # Run all 33 analyses (default)
python3 roae.py --quick      # Run core sections only (fast)
python3 roae.py --table      # Run a specific section
python3 roae.py --help-sections  # List all available sections
python3 roae.py --self-test  # Verify data integrity (20 checks)
```

### Analysis sections (33)

| Flag | Description |
|------|-------------|
| `--table` | Hexagram reference table with binary encoding, trigrams, and names |
| `--pairs` | Reverse vs. inverse pair analysis |
| `--wave` | First-order difference wave (the core "signal") |
| `--barchart` | ASCII bar chart of the difference wave |
| `--trigrams` | Trigram frequency, transitions, and 8x8 transition matrices |
| `--nuclear` | Nuclear hexagram derivation chains |
| `--lines` | Line change positional analysis |
| `--complements` | Complement distance analysis |
| `--palindromes` | Palindrome search in the difference wave |
| `--canons` | Upper Canon (1-30) vs. Lower Canon (31-64) comparison |
| `--hamming` | Full 64x64 Hamming distance matrix |
| `--autocorrelation` | Autocorrelation with 95% confidence bands |
| `--entropy` | Shannon entropy vs. random permutations |
| `--path` | Graph theory path analysis (unconstrained and pair-constrained) |
| `--stats` | Monte Carlo analysis of the no-5-line property |
| `--fft` | Spectral analysis (DFT) with noise floor |
| `--markov` | Markov chain with permutation test |
| `--graycode` | Gray code comparison |
| `--symmetry` | XOR group algebra analysis |
| `--sequences` | King Wen vs. Fu Xi vs. Mawangdui comparison |
| `--constraints` | Combined constraint satisfaction with statistical bounds |
| `--windowed-entropy` | Sliding window entropy across the wave |
| `--mutual-info` | Mutual information between upper/lower trigram changes |
| `--bootstrap` | Bootstrap confidence intervals for Monte Carlo estimates |
| `--yinyang` | Yin-yang balance wave through the sequence |
| `--neighborhoods` | Hamming distance-1 neighborhoods for each hexagram |
| `--recurrence` | Recurrence plot of the difference wave |
| `--codons` | DNA codon mapping and structural comparison |

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
| `--seed N` | Random seed for reproducible results |
| `--color` | Enable ANSI color output |

### Export formats

```
python3 roae.py --json > hexagrams.json   # JSON data
python3 roae.py --csv > hexagrams.csv     # CSV data
python3 roae.py --dot > kw.dot            # Graphviz graph
python3 roae.py --svg > hexagrams.svg     # SVG line diagrams
python3 roae.py --html > report.html      # Self-contained HTML report
python3 roae.py --midi > kw.mid           # Difference wave as MIDI audio
```

### Verification

```
python3 roae.py --self-test  # 20 mathematical invariant checks
```

Verifies data integrity, pair structure, no-5-line property, yin-yang balance, trigram distribution, lookup table consistency, and mathematical function correctness.

## Requirements

Python 3.6+ with no external dependencies (stdlib only).

## References

* https://en.wikipedia.org/wiki/King_Wen_sequence
* https://oeis.org/A102241
* https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero

## License

Public domain ([Unlicense](https://unlicense.org)).
