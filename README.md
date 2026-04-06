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
- **Combined constraints are extraordinary** — zero random permutations satisfy both the pair structure AND the no-5 property together.
- **It's deliberately rough** — at 3.35x the Gray code minimum, King Wen is longer than 97% of random paths. It's not trying to be smooth.
- **It's more structured than random** — entropy sits at the 13th percentile, meaning it's more ordered than 87% of random permutations.
- **The wave has no strong periodicity** — autocorrelation drops off immediately, and the FFT shows no dominant frequency. Whatever structure exists isn't periodic.
- **The Markov transitions show patterns** — 1-changes always precede 6-changes, and 6-changes always precede 2-changes. The wave isn't memoryless.
- **The XOR algebra is clean** — 32 pairs produce only ~12 unique products, suggesting the pairing system has deeper algebraic regularity.
- **King Wen is unique among known orderings** — neither Fu Xi nor Mawangdui avoids 5-line transitions.
- **Perfect yin-yang balance** — exactly 192 yang lines and 192 yin lines across all 64 hexagrams.
- **Upper and lower trigrams change independently** — mutual information between them is near zero.

The picture that emerges is of a sequence designed under multiple simultaneous constraints — pair relationships, avoidance of certain transitions, algebraic regularity — none of which individually are impossible by chance, but which together are vanishingly unlikely. The designers (whoever they were, ~3000 years ago) appear to have been working with a sophisticated understanding of combinatorial structure, even if they wouldn't have described it in those terms.

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
| `--autocorrelation` | Autocorrelation (hidden periodicity) |
| `--entropy` | Shannon entropy vs. random permutations |
| `--path` | Graph theory path analysis |
| `--stats` | Monte Carlo analysis of the no-5-line property |
| `--fft` | Spectral analysis (DFT) of the wave |
| `--markov` | Markov chain transition probabilities |
| `--graycode` | Gray code comparison |
| `--symmetry` | XOR group algebra analysis |
| `--sequences` | King Wen vs. Fu Xi vs. Mawangdui comparison |
| `--constraints` | Combined constraint satisfaction testing |
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
