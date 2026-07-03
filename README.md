# Received Order Analysis Engine (ROAE)

> **Research in progress.** This project is under active development. Findings are preliminary, based on partial enumeration (no branch of the search tree has been fully explored), and subject to revision as the analysis deepens. Earlier versions of this documentation contained claims that were later invalidated by larger-scale computation — see commit history for the evolution of findings. Nothing here should be treated as definitive.

Analysis engine for the [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence)

<mark>**[䷀䷁](documentation/SOLVE-SUMMARY.md)**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

## Summary

An analysis engine that approaches the King Wen sequence from nearly every mathematical angle available. It started as a script verifying a known structural property of the sequence and grew into a comprehensive toolkit for studying the combinatorial structure of an ancient Chinese ordering system.

Note: this program analyzes the mathematical structure of the ordering only. The [I Ching](https://en.wikipedia.org/wiki/I_Ching) is a foundational text of Chinese philosophy, divination, and cosmology with over three millennia of commentary and practice. This program does not address the philosophical, divinatory, or literary dimensions of the text.

## Guide

New to the I Ching or combinatorics? See [GUIDE.md](documentation/GUIDE.md) for a plain-language introduction to the King Wen sequence and how to read this program's output. For a step-by-step walkthrough of what the solver actually does — what a "branch," "sub-branch," and "node" mean, what all-branch vs single-branch enumeration is doing, and what the open questions are — see [BRANCHES_EXPLAINED.md](documentation/BRANCHES_EXPLAINED.md).

## Solver

Can the King Wen sequence be reconstructed from its mathematical constraints? Five constraints narrow 10^89 possibilities to billions of valid orderings. The deepest published partial enumeration finds **10,525,271,997 canonical orderings** at the d3 560T budget (sha `9a968fa2…`, established 2026-06-08; CANONICAL-verified 2026-06-30). Canonical counts and the sha256 hashes that anchor them — across multiple partition strategies and node budgets — are listed in [CANONICAL_HASHES.md](documentation/CANONICAL_HASHES.md). All listed canonicals are partial enumerations; under true exhaustive enumeration they would converge. Across the three deepest canonicals the per-cell record sets are strictly nested (11.2T ⊆ 100T ⊆ 560T, 0 monotonicity violations under pair-identity keying) and grow sublinearly (×50 budget → ×13.86 records), driven by deepening of existing productive cells rather than new regions — and remain unsaturated (every sampled sub-branch is still budget-limited), so each is a reproducible *slice* at a fixed budget rather than a final count.

The **number of boundary constraints needed to uniquely identify King Wen is partition + scale-dependent and non-monotone with scale**: greedy-ordered minimum is 4 at d2/d3 10T, 5 at d3 100T, and 4 again at d3 560T (greedy set `{4, 27, 25, 21}` applied in order). Boundaries **{25, 27}** are in every greedy minimum at all four partitions tested (most stable structural finding). See [SPECIFICATION.md](documentation/SPECIFICATION.md) for the formal definition, [SOLVE.md](documentation/SOLVE.md) for the constraint analysis (`solve.py` + `solve.c`), [SOLVE-SUMMARY.md](documentation/SOLVE-SUMMARY.md) for a plain-language version, or [PARTITION_STABILITY_BOUNDARIES.md](documentation/PARTITION_STABILITY_BOUNDARIES.md) + [BOUNDARY_MINIMUM_NON_MONOTONE.md](documentation/BOUNDARY_MINIMUM_NON_MONOTONE.md) for the paper-citable stable findings. The binary output format is in [SOLUTIONS_FORMAT.md](documentation/SOLUTIONS_FORMAT.md); [REBUILD_FROM_SPEC.md](documentation/REBUILD_FROM_SPEC.md) is a step-by-step recipe for building an independent verifier from those two specs alone. Enumeration results are in `enumeration/`. Full `solve.c` command-line reference (subcommands, env vars, exit codes) is in [SOLVE_CLI.md](documentation/SOLVE_CLI.md).

**Important methodological note.** Constraints C1–C2 (pair structure, no 5-line transitions) are genuinely rare statistical properties of King Wen — the pair structure does not appear in any random permutation we tested (0 of 1.86 billion across seven null-model families). Constraint C3 (complement distance ≤ 776) is a ceiling constraint using KW's own value; per the 100T and 560T d3 analyses, **KW sits AT the C3 ceiling, not the floor** — a large fraction of records tie with KW at C3=776, and the minimum C3 is 424 (221 records at 100T). Constraints C4–C7 were **extracted from King Wen** (exact starting pair, exact distance distribution, specific boundary adjacencies) and then shown to be highly constraining against King Wen. A null-model test (see [CRITIQUE.md](documentation/CRITIQUE.md)) found that applying the same extraction methodology to random pair-constrained sequences also produces apparent "uniqueness" in 9/10 cases. The honest claim is therefore: *pair structure + no-5 are the robust findings against random; the "4 boundaries uniquely determine KW" result holds in its greedy-ordered form at every scale tested (10T → 560T), but the *unordered* "exactly 4 specific boundaries" framing is scale-bounded (0 unordered working 4-tuples at d3 100T and d3 560T). This reflects the constraint-extraction methodology rather than evidence of KW's inherent specialness beyond the robust pair-structure + no-5 findings.*

## Example

See [example output](example/README.md) for a full run of `roae.py` against the King Wen sequence — hexagram reference tables, 28 statistical analyses, and derived visualizations (`.csv`, `.json`, `.svg`, `.html`, `.pdf`, MIDI wave rendering).

### `roae.py` vs `solve.c` — two different kinds of output

These are easy to confuse; they serve different roles:

| | `roae.py` → `example/` | `solve.c` → `runs/<run>/` |
|---|---|---|
| **What it analyzes** | King Wen itself as a given 64-hexagram sequence | The full space of 10^89 possible orderings, filtered to solutions satisfying C1-C5 |
| **Output** | Descriptive statistics about KW (trigrams, pair structure, entropy, complement distances, palindromes, Markov patterns, Gray-code comparisons, 28 analyses total) | Enumeration artifacts: `solutions.bin` (millions of valid orderings), `solutions.sha256` (reproducibility anchor), `analyze_output.log.gz` (statistics across the solution set) |
| **Deterministic?** | Fully — the sequence is fixed, analyses are closed-form | Fully — given fixed solver + inputs, `solutions.bin` is byte-identical (partition invariance) |
| **Scale** | Single sequence, prints instantly | Hundreds of millions of orderings; canonical runs take hours on D128 |
| **Dependencies** | Python 3 stdlib only (optional deps for `.pdf`, `.html`, `.mid`) | `gcc`, `pthread`, `sha256sum` (no library dependencies) |
| **Who reads it** | Anyone curious about KW's internal structure (the "what"); no enumeration insight | Researchers evaluating the uniqueness question ("how special is KW among all C1-C5 orderings?") |

Both are committed in the repo. The `example/` output is generated by running `roae.py`; the `runs/<run>/` directories archive summaries (sha, meta, compressed logs) of actual enumeration runs against Azure compute. The binary `solutions.bin` files themselves are too large to commit (~10-65 GB each) and live on persistent Azure managed disks — see [enumeration/SOLUTIONS_BIN_LOCATION.txt](enumeration/SOLUTIONS_BIN_LOCATION.txt).

## Observations

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is traditionally attributed to [King Wen of Zhou](https://en.wikipedia.org/wiki/King_Wen_of_Zhou) (~1000 BCE). It is not random, but it's also not optimized for any single obvious metric. The evidence stacks up:

- **The pair structure is perfect** — every one of the 32 pairs is a reverse or inverse, and zero random permutations out of 10,000 achieved this. (The pair structure itself is a classical observation — described by Yu Fan, 220–265 AD; Radisic 2026 proved it is the unique Hamming-cost-optimal pairing — see [CITATIONS.md](documentation/CITATIONS.md). The rarity measurement is ROAE's.)
- **The no-5-line property is real but not astronomically rare** — about 1 in 550 random orderings share it. Notable, not miraculous.
- **Combined constraints are rare but context matters** — zero unconstrained random permutations satisfy both the pair structure AND the no-5 property together. However, among orderings that already satisfy the pair constraint, ~4% also avoid 5-line transitions (~1 in 23). The pair structure largely explains the no-5 property, since within-pair transitions are always even-distance.
- **It's more structured than random** — entropy sits at the 13th percentile, meaning it's more ordered than 87% of random permutations.
- **The wave has no detectable periodicity** — (the difference-wave construction is McKenna & McKenna 1975's) — autocorrelation drops off immediately, and the FFT shows no dominant frequency, though with only N=63 data points the statistical power to detect weak periodicity is limited.
- **The Markov transition matrix is not unusual** — a permutation test shows King Wen's transition structure is at the 43rd percentile, indistinguishable from random orderings. Apparent patterns (e.g., "6 is always followed by 2") are based on small samples and are not statistically significant.
- **The path length is typical for its structure** — compared against unconstrained random orderings, King Wen appears rough (97th percentile, 3.35x a Gray code). But compared against the correct null model (random orderings that also satisfy the pair constraint), it's at the 29th percentile — completely typical.
- **Complements are deliberately close** — King Wen places complementary hexagrams significantly closer than random (0th percentile), suggesting intentional organization around opposition.
- **The XOR algebra is a theorem** — 32 pairs produce only 7 unique XOR products. This is not a property of King Wen — it is a mathematical consequence of any reverse/inverse pairing of 6-bit values (see [SOLVE.md](documentation/SOLVE.md#theorem-2-xor-regularity-is-a-theorem-not-a-constraint)).
- **Palindromes, canon split, recurrence, and neighborhoods are unremarkable** — under appropriate null models, all are within chance expectations. Palindromes are at the 49th percentile (pair-constrained), the canon split at the 12th (the split itself is classically attested — Zheng Qiao ~1150, Hu Yigui 1247; see CITATIONS.md), recurrence at the 72nd, and neighborhoods at the 12th.
- **The no-5-line property is shared, not KW-unique** — `solve.c --null-historical` tests four documented orderings: **King Wen, the [Mawangdui](https://en.wikipedia.org/wiki/Mawangdui_Silk_Texts) silk-text ordering, and Jing Fang's 8 Palaces all avoid 5-line transitions** (3 of 4); only the [Fu Xi](https://en.wikipedia.org/wiki/Shao_Yong) natural-binary ordering does not — suggesting C2 was a shared classical Chinese design principle, not a King-Wen fingerprint. What *is* King-Wen-specific within the tested historical set is the **combination** (C1 + C2 + C3 together) and the specific complement-distance threshold of 776.

The picture that emerges is of a sequence designed under multiple simultaneous constraints — pair relationships and avoidance of certain transitions — none of which individually are impossible by chance, but which together are vanishingly unlikely. The designers (whoever they were, [~3000 years ago](https://en.wikipedia.org/wiki/King_Wen_of_Zhou)) appear to have been working with combinatorial rules.

Note: with 28 analyses, some results will appear unusual by chance alone. The strongest findings (pair structure, combined constraints) survive multiple comparison correction. Weaker findings should be interpreted with caution. See [CRITIQUE.md](documentation/CRITIQUE.md) for known limitations.

See [MCKENNA.md](documentation/MCKENNA.md) for how these findings relate to [Terence McKenna's Timewave Zero theory](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero).

## Usage

```
python3 roae.py                 # run all 28 analyses (default)
python3 roae.py --quick         # core sections only (fast)
python3 roae.py --<section>     # run one analysis (e.g., --wave, --pairs, --complements)
python3 roae.py --help-sections # list all available analysis sections
python3 roae.py --self-test     # data-integrity invariant checks
python3 roae.py --lookup 1      # look up a hexagram (by number or name)
python3 roae.py --html          # export full HTML report (also --json --csv --svg --markdown --midi --dot)
```

Full command-line reference for `roae.py` — all 28 analysis sections, interactive queries, modifiers, output formats, and dependencies — is in [ROAE_PY_CLI.md](documentation/ROAE_PY_CLI.md).

For `solve.c` (the enumerator that produces the canonical `solutions.bin` artifacts referenced above): see [SOLVE_CLI.md](documentation/SOLVE_CLI.md).

## Requirements

Python 3.6+ with no external dependencies (stdlib only).

Reproducibility note: `--seed N` produces deterministic results, but Python's `random` module implementation may vary across Python versions. The example output was generated with Python 3.12. Results with the same seed on different Python versions may differ slightly.

Optional external programs for export formats:
- [Graphviz](https://graphviz.org/) — `--dot` auto-generates PNG and SVG alongside the DOT file (`sudo apt install graphviz`)
- [wkhtmltopdf](https://wkhtmltopdf.org/) — `--html` auto-generates a PDF alongside the HTML report (`sudo apt install wkhtmltopdf`)

## References

> **See [CITATIONS.md](documentation/CITATIONS.md) for the full, formally scoped reference list** — including prior literature on the mathematical structure of the King Wen sequence (Cook 2006, McKenna 1975), methodological citations (Hierholzer, Fisher-Yates, Marsaglia, Bonferroni, Wilson), and explicit attribution of which observations are classical / prior work vs. independently verified computationally by ROAE vs. believed novel here. CITATIONS.md includes a disclaimer inviting updates from readers aware of prior work not cited.

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
* [arXiv:2604.09234](https://arxiv.org/abs/2604.09234) — Augustin Chan, *Statistical Properties of the King Wen Sequence: An Anti-Habituation Structure That Does Not Improve Neural Network Training* (2026). Independent Monte Carlo statistical analysis of KW vs 100,000 random permutation baselines; predates ROAE. Several findings overlap with ROAE's via different methodology (statistical-vs-random framing vs constraint enumeration). See [CITATIONS.md](documentation/CITATIONS.md) for per-finding overlap analysis.

## Built with

[Claude Code](https://claude.ai/code) (Anthropic)

## License

Public domain ([Unlicense](https://unlicense.org)).
