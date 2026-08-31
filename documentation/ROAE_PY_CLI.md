# roae.py(1) — King Wen sequence descriptive analyses

> **CLI references:** this documents **`roae.py`** (descriptive analyses). See also the [`solve` C binary](SOLVE_C_CLI.md) (enumerator/verifier) · [`solve.py`](SOLVE_PY_CLI.md) (analysis + ground truth) · [`sat.py`](SAT_CLI.md) (SAT / certificate layer).

A man-page-style command-line reference for `roae.py`, the Python
analysis tool that runs 29 descriptive statistical analyses against
the King Wen hexagram sequence as a fixed 64-element ordering.

## NAME

**roae.py** — descriptive statistical analyses of the King Wen
sequence: pair structure, difference wave, trigrams, complements,
entropy, autocorrelation, Markov patterns, FFT spectral analysis,
Gray-code comparisons, neighborhood analysis, and 19 more.

## SYNOPSIS

```
python3 roae.py                      # run all 29 analyses (default)
python3 roae.py --quick              # core sections only (fast)
python3 roae.py --<section>          # run a specific analysis
python3 roae.py --help-sections      # list all available sections
python3 roae.py --self-test          # data-integrity invariant checks
python3 roae.py --lookup HEX         # interactive: hexagram by number/name
python3 roae.py --compare A B        # interactive: two-hexagram comparison
python3 roae.py --cast               # interactive: simulate I Ching reading
python3 roae.py --explain N          # interactive: walk one transition (1-63)
python3 roae.py --grammar-search [--gs-* ...] [--seed N]
                                     # U2: MDL-charged constraint search beyond C1-C5
python3 roae.py --prereg-h1h3 [--gs-* ...] [--ph-thr-samples N] [--seed N]
                                     # pre-registered H1/H3 K=4 test (frozen 2026-07-26)
python3 roae.py --json|--csv|--svg|--html|--markdown|--midi|--dot
                                     # export various output formats
```

## DESCRIPTION

`roae.py` analyzes the King Wen sequence **as a given 64-hexagram
ordering** — it does NOT enumerate the space of possible orderings
(that's `solve.c`'s job; see [SOLVE_C_CLI.md](SOLVE_C_CLI.md)). Instead,
it computes 29 different descriptive measures of the King Wen
sequence's structure and compares each measure to appropriate null
models.

The default action (no flags) runs all 29 analyses. With a single
`--<section>` flag, runs only that section. With `--quick`, runs a
core subset for fast iteration.

Output is human-readable text by default; alternative output formats
(JSON, CSV, SVG, HTML, PDF, MIDI, Graphviz DOT) are available via
output-format flags.

`roae.py` is **deterministic** for analyses without Monte Carlo
content. For Monte Carlo analyses (`--stats`, `--bootstrap`,
`--constraints`), use `--seed` for reproducible results.

## ANALYSIS SECTIONS

The 29 analysis sections, each invoked by a single flag:

### Hexagram structure

| Flag | Description |
|---|---|
| `--table` | Hexagram reference table with binary encoding, trigrams, names, and properties for all 64 hexagrams |
| `--pairs` | Reverse vs. inverse pair analysis — tests whether KW's 32 pairs all satisfy the pairing structure (C1 in [SPECIFICATION.md](SPECIFICATION.md)) |
| `--trigrams` | Trigram (upper/lower 3-line) frequency, transitions, 8×8 matrices — plus (2026-07-03) pair-preserving permutation nulls, pure-hexagram Classic-ends placement ([Lai Zhide](CITATIONS.md#laizhide) via [Schulz 1982](CITATIONS.md#schulz1982)), nuclear-trigram reduction 64→16→4, [Jing Fang](CITATIONS.md#jingfang) palace rank-correlation + null, symmetry-group trigram-split subgroup |
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
| `--parity` | Odd-vs-even transition parity ([McKenna](CITATIONS.md#mckenna-mckenna1975) 25/75 model), linear + circular modes |
| `--neighborhoods` | Hamming-distance-1 neighborhoods for each hexagram |
| `--recurrence` | Recurrence plot — visualization of where the difference wave repeats |

## META FLAGS

```
--verify           Ground-truth self-check: 11 checks, no sampling. It reads exactly
                   one file, solve.py, and resolves it by the CWD-relative path
                   "solve.py", so --verify must be run from the repository directory:
                   from anywhere else it reports "could not load solve.py" and exits 1.
                   No other file I/O; nothing is written.
                   Verifies roae.py's King Wen table is IDENTICAL to solve.py's (this
                   file carries its own copy and nothing enforced that agreement before
                   2026-08-01), that the table is a permutation of 0..63, that
                   binary_to_kw_position inverts it, that reverse_6bit is an involution,
                   that (upper<<3)|lower reconstructs every hexagram, that bit_diff is
                   symmetric and zero iff equal, that KW's 63-transition difference wave
                   equals SPECIFICATION §C5's multiset, that C4 holds in its ORIENTED
                   form (s0=63, s1=0), that the name/unicode tables have 64 entries, and
                   that the Mawangdui control array is a permutation. Exit 0 = all pass.
                   Wired into tests.py.
--all              Run all 29 analyses (default if no flags given)
--quick            Run core subset only (table, pairs, wave, barchart, ...)
--self-test        Run mathematical-invariant data-integrity checks (37 checks).
                   Prints a "N passed, M failed, 37 total" tally. NOTE: a failing
                   self-test still exits 0 — see EXIT STATUS.
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
python3 roae.py --lookup 1                        # by King Wen number
python3 roae.py --lookup "Heaven over Heaven"      # same hexagram, by derived label
python3 roae.py --compare 1 2                     # hexagram 1 vs hexagram 2
python3 roae.py --explain 6               # show how hexagram 6 → 7 transition works
```

## GRAMMAR SEARCH & PRE-REGISTERED TESTS

Two terminal modes that go beyond describing the King Wen sequence: they
measure candidate structural claims against the uniform C1∧C2∧C4∧C5
reference population (exact rejection sampling: uniform over C1∧C4
orderings — 31 free pair slots × 2³¹ orientations, first pair pinned
(63, 0) — accepted iff the transition multiset equals C5's, which implies
C2). Both run and exit (they do not combine with the analysis sections),
fan out across worker processes, and are **much heavier** than the
descriptive analyses at their default sample sizes — size the machine
accordingly. Both are report-only: they produce no sha-anchored
artifacts and change no constraint definitions.

### --grammar-search (U2)

A circularity-safe, MDL-charged search for candidate structural
constraints that KW satisfies but that are *not* implied by the
published constraint set C1–C5. The search enumerates **every** predicate
of a fixed, pre-registered grammar of KW-independent structural
terminals at depth ≤ 2 (frozen sizes, asserted at startup: 118
transition atoms, 52 position atoms, 24 gates per domain), then runs
each KW-satisfied candidate through a five-phase pipeline:

1. **Probe sampling (A)** — a small probe set (`--gs-probe`) drawn from
   a seed stream *disjoint* from the rarity sample;
2. **Candidate enumeration + masks (B)**;
3. **Signature dedup (C)** — probe-trivial classes (true on the whole
   probe set, i.e. common under C1–C5) are absorbed; the **selection
   charge** log₂(#distinct predicate classes) is pinned to this run's
   measure;
4. **Rarity (D)** — population frequency of each surviving candidate on
   `--gs-samples` fresh samples, split into `--gs-batches`
   checkpointable batches (JSONL checkpoint; completed batches are
   skipped on re-run — subject to the validation caveat documented
   under `--gs-checkpoint` below);
5. **MDL ledger (E)** — bits-explained = −log₂ f vs the MDL statement
   cost L(C) plus the selection charge; prints survivors, the zero-hit
   shortlist, closest approaches, a Wilson lower bound for the rarest
   resolved candidate, and the detection floor.

The verdict line is either `NULL — no survivor within the declared
grammar at depth <= 2` or `ATTENTION — ... run the circularity audit
before any claim`. The result is scoped to this grammar and depth —
never a universal completeness claim. The full design and the
circularity firewall (every terminal structural and KW-independent; no
fitted thresholds, no KW-read constants) are documented in the section
banner in `roae.py` above `run_grammar_search`.

Parameters (all shared machinery flags are prefixed `--gs-`):

| Flag | Description |
|---|---|
| `--gs-samples N` | Rarity sample size (default 1,000,000). Reused as N_eval by `--prereg-h1h3`. |
| `--gs-probe N` | Probe-set size for signature dedup (default 256; seed stream disjoint from the rarity sample). |
| `--gs-workers N` | Worker processes (default 0 = all cores). |
| `--gs-batches N` | Number of checkpointable rarity batches (default 100). |
| `--gs-json PATH` | JSON report path (default `u2_report.json`): pre-registration record, per-phase tallies, MDL ledger, verdict. |
| `--gs-checkpoint PATH` | JSONL rarity checkpoint (default `u2_checkpoint.jsonl`). Completed batches are skipped on re-run. **The candidate count (`ncand`) is the only field validated on load**: each row carries `batch`/`n`/`trials`/`ncand`/`hits` and records no seed, sample count, probe size or batch count. A checkpoint written against a different candidate count is ignored — but one written under a different `--seed`, `--gs-samples` or `--gs-batches` that happens to yield the same `ncand` is silently reused, and the report's `preregistration` block then stamps the CURRENT parameters rather than the ones the completed batches were actually computed under. Delete the checkpoint file when changing any run parameter. |

`--seed` sets the base seed; when omitted, this mode (unlike the
Monte-Carlo analysis sections) defaults to the fixed pre-registered seed
20260726. Probe and rarity streams derive from it disjointly
(seed+100+w and seed+10000+b).

### --prereg-h1h3

The pre-registered H1/H3 test: K = 4 pre-declared predicates (T1
H1-median, T2 H1-perm-sign with a closed-form cut, T3 H3-P, T4 H3-Q)
over the same reference population, implementing the frozen 2026-07-26
pre-registration spec verbatim — functionals, threshold rules, seed
streams, L(C) menus, the log₂(4) = 2.00-bit selection charge, and the
pre-registered prediction that all four tests FAIL their bars (an
expected, legitimate null).

Circularity firewall (KW hold-out): the threshold stream (seed+20000+b,
`--ph-thr-samples` samples) is sampled and the medians med\*(A) /
med\*(P) are computed **and persisted to the JSON report before any
FUNCTIONAL is evaluated on the KW array**; KW-functional evaluation
enters exactly twice, both after that freeze point — the KW-satisfaction
bits and the at-KW masses.

The boundary is functional evaluation, not contact. The reference
population itself is constructed from King Wen *before* the thresholds
are drawn: `_gs_setup_population()` reads the KW array to form the 31 C1
pair units and the C5 transition multiset, and it is called first in
`run_prereg_h1h3`. That is disclosed, deliberate conditioning on C1∩C5,
priced as such — not a hold-out violation — but the hold-out claim is
about functionals, and should not be read as "no code path touches KW
before the freeze".

The evaluation stream (seed+30000+b, `--gs-samples` samples) is disjoint
from the threshold stream and from U2's streams **so long as
`--gs-batches` stays below 10,000**, the fixed gap between the two seed
offsets. Separation is an offset convention, not an enforced bound, and
`--gs-batches` has no upper limit: at `--gs-batches 20000`, threshold
batch 10000+k and evaluation batch k are seeded identically and draw the
same samples. Keep `--gs-batches` far below 10,000 (the default is 100).

A validity gate cross-checks the evaluation stream's mass(A ≤ 648)
against the independently measured F4′ `dist_autocorr` figure
0.04789 ± 0.005 — on failure the run hard-stops with **exit code 3**
and issues no verdicts.

Flags: reuses `--gs-samples` (as N_eval), `--gs-workers`,
`--gs-batches`, `--gs-json`, `--gs-checkpoint`, and `--seed` (same
20260726 default), plus one of its own:

| Flag | Description |
|---|---|
| `--ph-thr-samples N` | Threshold-derivation stream sample size (default 100,000; KW held out). |

When `--gs-json` / `--gs-checkpoint` still hold their U2 defaults, this
mode substitutes `prereg_h1h3_report.json` / `prereg_h1h3_ckpt.jsonl`
so U2 artifacts are never clobbered.

## ANALYSIS MODIFIERS

```
--wrap             Include the 64→1 wrap-around transition in the wave
--order N          Compute Nth-order difference of the wave (default: 1)
--trials N         Number of Monte Carlo trials (default: 100,000). Consumed by
                   --stats and --bootstrap ONLY. --constraints does NOT read it:
                   that mode hard-codes 10,000 unconstrained permutation trials
                   and 100,000 pair-constrained trials, so passing --trials
                   alongside --constraints has no effect on its output.
--seed N           Random seed for reproducible Monte Carlo / bootstrap results
```

`--seed` applies independently to each analysis that uses randomness;
re-running with the same seed produces identical numerical output for
`--stats`, `--bootstrap`, and `--constraints`. **`--cast` is NOT
reproducible under `--seed`**: the cast path returns before the global
seed is applied, so repeated `--cast --seed 42` runs differ (measured —
four runs, four distinct hashes). Note also that `--constraints` is
reproducible but ignores `--trials` (above).

## OUTPUT FORMATS

```
--color            Enable ANSI color in terminal output
--json             Export hexagram data to hexagrams.json
--csv              Export hexagram data to hexagrams.csv
--svg              Export hexagram line-diagrams to hexagrams.svg
--html             Export an HTML report to report.html (and report.pdf if wkhtmltopdf installed)
--markdown         Export a Markdown report to report.md
--midi             Export the difference wave as a MIDI file (wave.mid)
--dot              Export Graphviz DOT graph to wave.dot (+ wave.dot.png / wave.dot.svg if Graphviz installed)
```

Output formats are mutually exclusive, and they are not composed with
analysis selection. Each export renders from the hard-coded hexagram
data, not from "whatever analyses ran": requesting an export makes
`roae.py` write that one file and exit before any analysis section is
dispatched. If two or more export flags are given, only the first in
the order `--json`, `--csv`, `--dot`, `--svg`, `--html`, `--markdown`,
`--midi` takes effect. `--lookup`, `--compare`, `--cast` and `--explain`
are tested *before* the export flags and return first, so pairing one
of them with an export flag writes no file. See EXAMPLES.

## DEPENDENCIES

`roae.py` requires:

- **Python 3 standard library** — sufficient for all 29 analyses and
  most output formats. No external packages required for default use.

Optional packages enable richer output:

- **`wkhtmltopdf`** — for `--html` → PDF rendering. It is the only PDF
  backend `roae.py` invokes; if it is absent the PDF step is skipped
  silently and the run still succeeds.
- **`graphviz` (system package)** — for `--dot` → PNG/SVG rendering.
- **MIDI playback** — `--midi` produces `wave.mid` which can be played
  by any MIDI-capable audio system.

## EXIT STATUS

| Code | Meaning |
|---|---|
| 0 | Success. **Also returned when `--self-test` reports failures** — the tally and a `WARNING` line are printed, but the result is not wired to the exit status, so `--self-test` cannot be used as a CI gate. Parse stdout (`N failed`), not the exit code. |
| 1 | `--verify` ground-truth failure — including the "could not load solve.py" failure when `--verify` is run from outside the repository directory |
| 2 | Invalid argument or unrecognised flag (emitted by `argparse`) |
| 3 | `--prereg-h1h3` cross-check-gate failure (hard stop, no verdicts issued) — the only `sys.exit(3)` in `roae.py` |

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

**Reproducible Monte Carlo trials** (`--trials` is consumed by `--stats`
and `--bootstrap`; `--constraints` is seed-reproducible but uses its own
hard-coded trial counts):

```
python3 roae.py --stats --trials 1000000 --seed 42
```

**Generate exportable artifacts — one export per invocation:**

```
python3 roae.py --json     # writes: hexagrams.json
python3 roae.py --csv      # writes: hexagrams.csv
python3 roae.py --svg      # writes: hexagrams.svg
```

Export flags do **not** combine, and they do not compose with analysis
selection. `main()` tests them in a fixed order — `--json`, `--csv`,
`--dot`, `--svg`, `--html`, `--markdown`, `--midi` — and returns after
the first one it finds. So `python3 roae.py --table --json --csv --svg`
writes `hexagrams.json` and nothing else: the `--csv` and `--svg`
exports never run, and the `--table` analysis is never printed. (This
example previously appeared here claiming all three files; it does not
produce them.)

**Generate full HTML/PDF report:**

```
python3 roae.py --html
# writes: report.html (and report.pdf if wkhtmltopdf available)
```

`--html` renders 28 of the 29 analysis sections — the `--hamming`
section is not in the list `export_html()` iterates — and adding
`--all` (or any section flag) has no effect, because the export branch
returns before section dispatch. `--markdown` carries the identical
28-section list.

**Quick lookup:**

```
python3 roae.py --lookup 1                        # hexagram 1
python3 roae.py --compare "Heaven over Heaven" "Earth over Earth"   # 1 vs 2
python3 roae.py --explain 32                      # transition #32 step by step
```

**Self-test (run before any commit that touches roae.py logic):**

```
python3 roae.py --self-test
```

## FILES

**Reads:**

- The hexagram data is hard-coded inside `roae.py` (binary patterns,
  King Wen ordering, and trigram-derived structural labels such as
  "Heaven over Heaven" — **not** traditional or translated titles,
  which were removed on 2026-08-27; see the note at the top of
  `roae.py`). No external input file required.
- `--verify` additionally reads `solve.py` from the current working
  directory (see META FLAGS).

**Writes** — the output-format flags below write only when requested;
the two analysis modes at the end of the list write their JSON report
and JSONL checkpoint unconditionally whenever the mode is run:

- `hexagrams.json` (`--json`)
- `hexagrams.csv` (`--csv`)
- `hexagrams.svg` (`--svg`)
- `report.html` (`--html`); also `report.pdf`, but only if the external
  `wkhtmltopdf` binary is installed — otherwise the PDF is silently skipped
- `report.md` (`--markdown`)
- `wave.mid` (`--midi`)
- `wave.dot` (`--dot`); also `wave.dot.png` / `wave.dot.svg`, but only
  if Graphviz's `dot` binary is installed — the image files append the
  format suffix to the *whole* DOT filename, so they are
  `wave.dot.png` / `wave.dot.svg`, not `wave.png` / `wave.svg`
- `u2_report.json`, `u2_checkpoint.jsonl` (`--grammar-search`; paths
  overridable via `--gs-json` / `--gs-checkpoint`)
- `prereg_h1h3_report.json`, `prereg_h1h3_ckpt.jsonl` (`--prereg-h1h3`
  defaults; same overrides)

Output files are written to the current working directory, except
`--gs-json` / `--gs-checkpoint`, which take an arbitrary path (absolute
paths outside the CWD included).

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

| | `roae.py` | `solve.c` (see [SOLVE_C_CLI.md](SOLVE_C_CLI.md)) |
|---|---|---|
| **Analyzes** | KW as a given fixed sequence | The unconstrained ~10⁸⁹ (64!) permutation space; the C1–C5-satisfying subset is estimated ≈10³⁸ (Knuth estimate, see [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md)) |
| **Output** | Statistics about KW (29 analyses, optional reports) | Enumeration artifacts: `solutions.bin` (millions of valid orderings), sha256 anchors, statistics across the solution set |
| **Scale** | Single sequence, prints instantly | Hundreds of millions of orderings; canonical runs take hours on D128 |
| **Determinism** | Closed-form analyses are deterministic; Monte Carlo sections are reproducible under `--seed` (except `--cast`) | Fully — given fixed solver + inputs, the **decompressed** `solutions.bin` stream is byte-identical (partition invariance). The gzip container is not canonical: raw `sha256sum solutions.bin` hashes the framing, which varies with zlib version and compression level. Verify via the `solutions.sha256` sidecar or `gzip -dc solutions.bin \| sha256sum` (see [CANONICAL_HASHES.md](CANONICAL_HASHES.md)); the raw file is byte-identical only under `SOLVE_COMPRESS=0` |
| **Dependencies** | `roae.py` itself: Python 3 stdlib only. PDF and PNG/SVG side-outputs additionally invoke the external `wkhtmltopdf` / `dot` binaries when present, and are silently skipped when absent. (This row covers `roae.py` only — `solve.py`'s P2 analysis modes are **not** stdlib; see [DEVELOPMENT.md](DEVELOPMENT.md).) | `gcc` with OpenMP, `zlib` (`zlib1g-dev` — `solve.c` includes `<zlib.h>` unconditionally), `libm` (`-lm`), `pthread`, `sha256sum`; canonical build line in [DEVELOPMENT.md](DEVELOPMENT.md) |
| **Audience** | Anyone curious about KW's internal structure | Researchers evaluating uniqueness against C1-C5 |

The example output bundle in `example/` is what you get from running
`python3 roae.py` with various output formats enabled. See
[example/README.md](../example/README.md).

## SEE ALSO

- [SOLVE_C_CLI.md](SOLVE_C_CLI.md) — `solve.c` enumerator/verifier reference
- [SOLVE.md](SOLVE.md) — the constraint analysis with both tools
- [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) — plain-language overview
- [GUIDE.md](GUIDE.md) — newcomer introduction to the King Wen sequence
- [SPECIFICATION.md](SPECIFICATION.md) — formal C1-C5 constraint definitions
- [CRITIQUE.md](CRITIQUE.md) — known methodological limitations
- [example/README.md](../example/README.md) — example output bundle from running roae.py

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
- 2026-03 28-section coverage stabilized (parity added later → 29); output formats expanded
  (HTML, PDF, MIDI, Graphviz)
- Pre-2026 initial 6-round adversarial scientific review surfaced
  the trigram name swap bug, the complement-distance direction
  error ("maximizes" → "minimizes"), the XOR-as-theorem
  realization, and the null-model caveat
