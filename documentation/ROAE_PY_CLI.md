# roae.py(1) — King Wen sequence descriptive analyses

A man-page-style command-line reference for `roae.py`, the Python
analysis tool that runs 28 descriptive statistical analyses against
the King Wen hexagram sequence as a fixed 64-element ordering.

## NAME

**roae.py** — descriptive statistical analyses of the King Wen
sequence: pair structure, difference wave, trigrams, complements,
entropy, autocorrelation, Markov patterns, FFT spectral analysis,
Gray-code comparisons, neighborhood analysis, and 18 more.

## SYNOPSIS

```
python3 roae.py                      # run all 28 analyses (default)
python3 roae.py --quick              # core sections only (fast)
python3 roae.py --<section>          # run a specific analysis
python3 roae.py --help-sections      # list all available sections
python3 roae.py --self-test          # data-integrity invariant checks
python3 roae.py --lookup HEX         # interactive: hexagram by number/name
python3 roae.py --compare A B        # interactive: two-hexagram comparison
python3 roae.py --cast               # interactive: simulate I Ching reading
python3 roae.py --explain N          # interactive: walk one transition (1-63)
python3 roae.py --json|--csv|--svg|--html|--markdown|--midi|--dot
                                     # export various output formats
```

## DESCRIPTION

`roae.py` analyzes the King Wen sequence **as a given 64-hexagram
ordering** — it does NOT enumerate the space of possible orderings
(that's `solve.c`'s job; see [SOLVE_CLI.md](SOLVE_CLI.md)). Instead,
it computes 28 different descriptive measures of the King Wen
sequence's structure and compares each measure to appropriate null
models.

The default action (no flags) runs all 28 analyses. With a single
`--<section>` flag, runs only that section. With `--quick`, runs a
core subset for fast iteration.

Output is human-readable text by default; alternative output formats
(JSON, CSV, SVG, HTML, PDF, MIDI, Graphviz DOT) are available via
output-format flags.

`roae.py` is **deterministic** for analyses without Monte Carlo
content. For Monte Carlo analyses (`--stats`, `--bootstrap`,
`--constraints`), use `--seed` for reproducible results.

## ANALYSIS SECTIONS

The 28 analysis sections, each invoked by a single flag:

### Hexagram structure

| Flag | Description |
|---|---|
| `--table` | Hexagram reference table with binary encoding, trigrams, names, and properties for all 64 hexagrams |
| `--pairs` | Reverse vs. inverse pair analysis — tests whether KW's 32 pairs all satisfy the pairing structure (C1 in [SPECIFICATION.md](SPECIFICATION.md)) |
| `--trigrams` | Trigram (upper/lower 3-line) frequency, transitions, and 8×8 transition matrices |
| `--nuclear` | Nuclear hexagram chains — lines 2-3-4 and 3-4-5 generate inner hexagrams; this analysis traces the nuclear-derivation chains and their cycles |
| `--lines` | Line-change positional analysis — which of the 6 line positions changes most often as you walk the sequence |
| `--complements` | Complement distance — for each hexagram, where its bit-flipped opposite sits in the sequence |
| `--codons` | DNA codon mapping — structural comparison of King Wen with the genetic code, given the natural 64-element correspondence |

### Sequence-as-signal

| Flag | Description |
|---|---|
| `--wave` | First-order difference wave — the core "signal" of the King Wen sequence (line-changes between consecutive hexagrams) |
| `--barchart` | ASCII bar chart visualization of the difference wave |
| `--palindromes` | Palindrome search in the difference wave (sub-sequences that read the same forwards and backwards) |
| `--canons` | Upper Canon (1-30) vs. Lower Canon (31-64) statistical comparison |
| `--hamming` | Full 64×64 Hamming distance matrix between all hexagram pairs |
| `--autocorrelation` | Autocorrelation of the difference wave — tests for hidden periodicity |
| `--entropy` | Shannon entropy of the difference wave — measures structural order vs. randomness |
| `--path` | Graph-theory path analysis — is King Wen an efficient route through hexagram space? |
| `--stats` | Monte Carlo trial — what's the probability of the "no 5-line transitions" property arising by chance? |
| `--fft` | Spectral analysis (DFT) — frequency decomposition of the difference wave |
| `--markov` | Markov chain analysis — do difference values predict the next value? |
| `--graycode` | Gray code comparison — King Wen vs. theoretically smoothest path through hexagram space |
| `--symmetry` | XOR group algebra — algebraic structure of the pairing system |

### Comparative + null-model

| Flag | Description |
|---|---|
| `--sequences` | Compare King Wen vs. Fu Xi vs. Mawangdui orderings on each measure |
| `--constraints` | Constraint satisfaction — how rare is King Wen's combined properties (pair structure + no-5)? |
| `--bootstrap` | Bootstrap confidence intervals for Monte Carlo estimates |

### Higher-order structure

| Flag | Description |
|---|---|
| `--windowed-entropy` | Sliding window entropy — where structural order concentrates in the sequence |
| `--mutual-info` | Mutual information between upper-trigram and lower-trigram changes |
| `--yinyang` | Yin-yang line-balance wave through the sequence |
| `--parity` | Odd-vs-even transition parity (McKenna 25/75 model), linear + circular modes |
| `--neighborhoods` | Hamming-distance-1 neighborhoods for each hexagram |
| `--recurrence` | Recurrence plot — visualization of where the difference wave repeats |

## META FLAGS

```
--all              Run all 28 analyses (default if no flags given)
--quick            Run core subset only (table, pairs, wave, barchart, ...)
--self-test        Run mathematical-invariant data-integrity checks (~21 checks)
--help-sections    List all available analysis sections with one-line descriptions
```

## INTERACTIVE QUERIES

```
--lookup HEX                    Look up a hexagram by number (1-64) or by name
--compare A B                   Compare two hexagrams (each by number or name)
--cast                          Simulate an I Ching reading using the three-coin method
--explain N                     Walk through transition N (1-63) step by step
```

These are interactive convenience subcommands that print human-readable
output for a single hexagram or transition. Useful for debugging specific
claims in the analyses and for individual reference lookups.

Examples:

```
python3 roae.py --lookup 1                # The Creative
python3 roae.py --lookup "The Creative"   # same; name-based lookup
python3 roae.py --compare 1 2             # Heaven vs Earth
python3 roae.py --explain 6               # show how hexagram 6 → 7 transition works
```

## ANALYSIS MODIFIERS

```
--wrap             Include the 64→1 wrap-around transition in the wave
--order N          Compute Nth-order difference of the wave (default: 1)
--trials N         Number of Monte Carlo trials (default: 100,000)
--seed N           Random seed for reproducible Monte Carlo / bootstrap results
```

`--seed` applies independently to each analysis that uses randomness;
re-running with the same seed should produce identical numerical
output for `--stats`, `--bootstrap`, `--constraints`, and `--cast`.

## OUTPUT FORMATS

```
--color            Enable ANSI color in terminal output
--json             Export hexagram data to hexagrams.json
--csv              Export hexagram data to hexagrams.csv
--svg              Export hexagram line-diagrams to hexagrams.svg
--html             Export an HTML report to report.html (and report.pdf if wkhtmltopdf installed)
--markdown         Export a Markdown report to report.md
--midi             Export the difference wave as a MIDI file (wave.mid)
--dot              Export Graphviz DOT graph to wave.dot (+ .png/.svg if Graphviz installed)
```

Output formats are independent of analysis selection — they render the
data that gets computed by whatever analyses ran.

## DEPENDENCIES

`roae.py` requires:

- **Python 3 standard library** — sufficient for all 28 analyses and
  most output formats. No external packages required for default use.

Optional packages enable richer output:

- **`weasyprint`** or **`wkhtmltopdf`** — for `--html` → PDF rendering.
- **`graphviz` (system package)** — for `--dot` → PNG/SVG rendering.
- **MIDI playback** — `--midi` produces `wave.mid` which can be played
  by any MIDI-capable audio system.

## EXIT STATUS

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Invalid argument or section selection |
| 2 | Self-test failure (data-integrity invariant violated) |
| 3 | Output-format dependency missing (e.g., `--html` requires weasyprint) |

## EXAMPLES

**Run everything (the default):**

```
python3 roae.py
```

**Quick core analyses for first-time exploration:**

```
python3 roae.py --quick
```

**Single analysis — what does the difference wave look like?**

```
python3 roae.py --wave --barchart
```

**Reproducible Monte Carlo trials:**

```
python3 roae.py --constraints --trials 1000000 --seed 42
```

**Generate exportable artifacts:**

```
python3 roae.py --table --json --csv --svg
# writes: hexagrams.json, hexagrams.csv, hexagrams.svg
```

**Generate full HTML/PDF report:**

```
python3 roae.py --all --html
# writes: report.html (and report.pdf if wkhtmltopdf available)
```

**Quick lookup:**

```
python3 roae.py --lookup 1                        # The Creative
python3 roae.py --compare "Heaven" "Earth"        # 1 vs 2
python3 roae.py --explain 32                      # transition #32 step by step
```

**Self-test (run before any commit that touches roae.py logic):**

```
python3 roae.py --self-test
```

## FILES

**Reads:**

- The hexagram data is hard-coded inside `roae.py` (binary patterns,
  King Wen ordering, traditional names). No external input file
  required.

**Writes (only when output-format flags requested):**

- `hexagrams.json` (`--json`)
- `hexagrams.csv` (`--csv`)
- `hexagrams.svg` (`--svg`)
- `report.html` and `report.pdf` (`--html`)
- `report.md` (`--markdown`)
- `wave.mid` (`--midi`)
- `wave.dot`, `wave.png`, `wave.svg` (`--dot`)

All output files are written to CWD.

## REPRODUCIBILITY

- Analyses without randomness (`--table`, `--pairs`, `--wave`,
  `--trigrams`, `--nuclear`, `--complements`, `--symmetry`,
  `--graycode`, `--codons`, etc.) are fully deterministic — output
  depends only on the King Wen sequence (which is fixed).
- Monte Carlo analyses (`--stats`, `--bootstrap`, `--constraints`)
  use Python's `random` module; pass `--seed N` to make their
  output reproducible.
- Floating-point output may vary in the last decimal across
  Python versions / platforms; the qualitative findings (rankings,
  percentile placements) are stable.

## SCIENTIFIC SCOPE — what roae.py is and isn't

**roae.py characterizes the King Wen sequence** — what does it look
like? what's its statistical structure? how does it compare to
random orderings, Gray code, Fu Xi, Mawangdui?

**solve.c (compiled from `solve.c`) enumerates the constraint
space** — how many orderings satisfy C1-C5? where does King Wen
sit within that space?

The two tools are complementary:

| | `roae.py` | `solve.c` (see [SOLVE_CLI.md](SOLVE_CLI.md)) |
|---|---|---|
| **Analyzes** | KW as a given fixed sequence | The unconstrained ~10⁸⁹ (64!) permutation space; the C1–C5-satisfying subset is estimated ≈10³⁸ (Knuth estimate, see [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md)) |
| **Output** | Statistics about KW (28 analyses, optional reports) | Enumeration artifacts: `solutions.bin` (millions of valid orderings), sha256 anchors, statistics across the solution set |
| **Scale** | Single sequence, prints instantly | Hundreds of millions of orderings; canonical runs take hours on D128 |
| **Determinism** | Closed-form analyses; deterministic | Fully — given fixed solver + inputs, `solutions.bin` is byte-identical (partition invariance) |
| **Dependencies** | Python 3 stdlib only (optional output deps) | `gcc`, `pthread`, `sha256sum` |
| **Audience** | Anyone curious about KW's internal structure | Researchers evaluating uniqueness against C1-C5 |

The example output bundle in `example/` is what you get from running
`python3 roae.py` with various output formats enabled. See
[example/README.md](example/README.md).

## SEE ALSO

- [SOLVE_CLI.md](SOLVE_CLI.md) — `solve.c` enumerator/verifier reference
- [SOLVE.md](SOLVE.md) — the constraint analysis with both tools
- [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md) — plain-language overview
- [GUIDE.md](GUIDE.md) — newcomer introduction to the King Wen sequence
- [SPECIFICATION.md](SPECIFICATION.md) — formal C1-C5 constraint definitions
- [CRITIQUE.md](CRITIQUE.md) — known methodological limitations
- [example/README.md](example/README.md) — example output bundle from running roae.py

## NOTES

**`roae.py` does not produce sha-anchored canonical artifacts.** It
generates analysis output, not enumeration results. The
canonical-sha invariants in [CANONICAL_HASHES.md](CANONICAL_HASHES.md)
apply to `solve.c` output, not `roae.py` output.

**Some analyses include null-model framing** (e.g., `--stats`,
`--constraints`, `--canons`) that compares King Wen's measure to
distributions of random or pair-constrained random orderings. The
choice of null model matters; see [CRITIQUE.md](CRITIQUE.md) for
methodological caveats.

**Single Python source file:** `roae.py` is one file. The project's
single-Python-file rule (modeled on the single-C-file rule for
solve.c) means `roae.py` and `solve.py` are the only Python files,
plus `viz/visualize.py` (PCA plots, an exception with heavy
dependencies). No `scripts/` subdirectory; no separate analysis
scripts.

## HISTORY

Recent material changes (full record in [HISTORY.md](HISTORY.md)):

- 2026-04-15+ multiple analysis-section additions and corrections
  (XOR algebra reframed as a theorem; null-model framings added
  for constraints, palindromes, canon split, recurrence,
  neighborhoods)
- 2026-03 28-section coverage stabilized; output formats expanded
  (HTML, PDF, MIDI, Graphviz)
- Pre-2026 initial 6-round adversarial scientific review surfaced
  the trigram name swap bug, the complement-distance direction
  error ("maximizes" → "minimizes"), the XOR-as-theorem
  realization, and the null-model caveat
