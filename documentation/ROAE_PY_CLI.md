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
python3 roae.py --lookup HEX         # interactive: hexagram by number/derived label
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
sequence's structure and, **where a null comparison is meaningful**,
compares the measure to an appropriate null model. Several sections are
descriptive-only and carry no null and no significance test — the
trigram transition matrices (~1 expected observation per cell, so no
goodness-of-fit test has power), windowed entropy, and the Gray-code
ratio; and the 64×64 Hamming matrix is a property of the 6-bit encoding,
identical under any ordering, so no null over orderings applies to it at
all. See [CRITIQUE.md](CRITIQUE.md) and the REPRODUCIBILITY section
below, which also states which sections use randomness.

The default action (no flags) runs all 29 analyses. With a single
`--<section>` flag, runs only that section. With `--quick`, runs a
core subset for fast iteration.

Output is human-readable text by default; alternative output formats
(JSON, CSV, SVG, HTML, MIDI, Graphviz DOT) are available via
output-format flags.

**Twelve of the 29 sections draw random numbers**, not the three that an
earlier version of this page named; a thirteenth (`--trigrams`) runs a
Monte Carlo null under an RNG seeded internally to a fixed constant and
does not read `--seed` at all. Pass `--seed N` to make the twelve
reproducible. The full census, derived from the code, is in
REPRODUCIBILITY below — read it before assuming any section is
closed-form.

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
                   [STALE since 2026-09-02, measured 2026-09-21: solve.py is resolved
                   as roae.py's SIBLING via __file__ (roae.py, run_verify, "resolved
                   from __file__"), so the gate gives the same verdict from any
                   directory — `cd /tmp && python3 <repo>/roae.py --verify` prints
                   `ROAE VERIFY: ALL 11 CHECKS PASS`, rc 0. The fail-closed half is
                   unchanged: a missing or unreadable sibling solve.py still FAILS
                   the cross-file check and exits 1. The three sentences above
                   described the loader as it was before the fix.]
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
--self-test        Run mathematical-invariant data-integrity checks (49 checks).
                   Prints a "N passed, M failed, 49 total" tally. A failing self-test
                   EXITS 1, so it CAN gate CI — see EXIT STATUS.
--help-sections    List all available analysis sections with one-line descriptions
```

## INTERACTIVE QUERIES

```
--lookup HEX                    Look up a hexagram by number (1-64) or by its
                                trigram-derived label (e.g. "Water over Thunder").
                                Traditional and translated titles were removed on
                                2026-08-27 and are NOT accepted: `--lookup Qian`,
                                `--lookup 乾` and `--lookup Zhun` all report
                                "No hexagram found".
--compare A B                   Compare two hexagrams (each by number or
                                trigram-derived label, on the same terms as --lookup)
--cast                          Simulate an I Ching reading using the three-coin method
--explain N                     Walk through transition N (1-63) step by step
```

These are interactive convenience subcommands that print human-readable
output for a single hexagram or transition. Useful for debugging specific
claims in the analyses and for individual reference lookups.

*(Corrected 2026-09-02, adjudicated correction. The three summaries above read
"by name"/"by number/name". The 2026-08-27 removal of traditional and
translated titles corrected the **data** description at §FILES but not the
**interface** description here, so the documented lookup key outlived the key
the tool accepts. Verified by running it, not by reading it: `--lookup Qian`,
`--lookup 乾`, `--lookup Zhun` and `--lookup 屯` each print
`No hexagram found matching '...'`, while `--lookup "Water over Thunder"`
returns hexagram 3 and `--compare Qian Kun` prints
`Could not find hexagram: Qian`. **Residue disclosed rather than left silent:**
`roae.py` itself still says "or name" in four places — its `--help-sections`
menu rows for `--lookup` and `--compare` (`roae.py:2241`, `:2242` at `6c82f0ff`) and the two
matching `argparse` help strings (`roae.py:5088`, `:5090` at `6c82f0ff`) — and the
not-found message still does not say what the tool does accept. Those are code
edits outside this documentation pass, and the retracted-phrase registry cannot
guard them either: GATE 3's corpus is the tracked `*.md` set plus
`reports/evidence/**`, so no needle registered here can reach a Python file.)*

*(Closed 2026-09-21, Q-410 surface sweep. The four residues were, at `8c2ce1f0`, `roae.py:2297`, `:2298`,
`:5319` and `:5321` (all four at `8c2ce1f0`) — the line numbers above had drifted by 56 and 231 lines — and all four
now read "trigram-derived label"; the not-found paths print a second line, `Accepted keys: a King
Wen number (1-64) or a trigram-derived label such as "Water over Thunder"; …`, after the unchanged
`No hexagram found matching '…'.` / `Could not find hexagram: …` line, so anything matching the
documented first line still matches. `tests.py::TestCliHelpDescribesTheCode` pins both the label
lookup and the hint, which is the Python-side guard this paragraph said GATE 3 could not be.)*

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
of a grammar of KW-independent structural terminals at depth ≤ 2. The
grammar is **frozen in code, and its freeze is self-attested**: the
sizes (118 transition atoms, 52 position atoms, 24 gates per domain) are
asserted at startup by `roae.py` itself (`roae.py`, the guard above
Phase A), which constrains the grammar only against the same file that
defines it. Unlike `--prereg-h1h3` below — whose spec is both escrowed
by hash and, since 2026-09-04, published in full as
[`PREREG_H1_H3_TEST_2026_07_26.md`](PREREG_H1_H3_TEST_2026_07_26.md) —
**no external escrow artifact exists for this grammar**: it has no row
in [PREREGISTRATION_ESCROW.md](PREREGISTRATION_ESCROW.md), so an outside
reader cannot check that the grammar predates any particular run. Each
KW-satisfied candidate then runs through a five-phase pipeline:

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
5. **MDL ledger (E)** — bits-explained = −log₂ f, compared against the
   MDL statement cost L(C); prints the survivor list, the zero-hit
   shortlist, closest approaches, a Wilson lower bound for the rarest
   resolved candidate, and the detection floor.

**The printed survivor list is admitted at a LOWER bar than the
detection floor states, and this is the one thing to get right when
reading the output.** Two different bars are in play:

| | bar applied | where it appears |
|---|---|---|
| **Detection floor** (the honest bar) | bits-explained > L(C) **+ selection charge** | the `[E] DETECTION FLOOR:` line, and the circularity audit |
| **Survivor list** (what is printed) | bits-explained > L(C) **alone** | the `SURVIVOR?` lines, the `survivors` count, and the `verdict` field |

A candidate with L(C) < bits-explained ≤ L(C) + selection therefore
appears as a `SURVIVOR?` line and flips the verdict, **without having
cleared the multiple-selection charge**. The direction is
over-flagging, not under-detection: nothing that clears the full bar can
be missed this way, but a `SURVIVOR?` line is a shortlist entry, not a
result. The program says as much in its own output — it labels the
tally `MDL-net-positive (pre-selection)`, ends each candidate line with
a question mark, and heads the margins `closest approaches
(bits-explained - L(C), pre-selection)` — and the trailing `?` is doing
real work.

The verdict line is either `NULL — no survivor within the declared
grammar at depth <= 2` or `ATTENTION — survivor or zero-hit shortlist
present; run the circularity audit before any claim`. `ATTENTION` fires
whenever the pre-selection survivor list **or** the zero-hit shortlist
is non-empty, so it too is a pre-selection signal. The JSON
`verdict` and `survivors` fields carry no pre-selection marker; read
them against this table, not at face value. The result is scoped to this
grammar and depth — never a universal completeness claim. The full design and the
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
| `--gs-checkpoint PATH` | JSONL rarity checkpoint (default `u2_checkpoint.jsonl`). Completed batches are skipped on re-run. Every field that selects the sample is written into each row and checked on load: `batch`/`n`/`trials`/`ncand`/`cands`/`seed`/`batches`/`nsamp`/`want`/`hits`. A row that mismatches any of them is REFUSED and counted in the `IGNORED` report, never silently reused. *(Precision, measured 2026-09-21: the row carries all ten keys, but the ones **compared** on load are the six that select the sample — `seed`, `ncand`, `cands`, `batches`, `nsamp` and `want` (`_ck_ident` plus the per-batch `want` check in `roae.py`); `batch` is the lookup key and `n`/`trials`/`hits` are the payload the resume reuses. A checkpoint with `hits`, `trials` and `n` hand-edited resumed as "3 batches already complete" — nothing on load can validate a payload except by recomputing it. A changed `--seed` is refused as documented: `[D] checkpoint: IGNORED 3 row(s) — mismatched cands,seed`.)* ⚠ **[CORRECTED 2026-09-20 — this read "The candidate count (`ncand`) is the only field validated on load … records no seed, sample count, probe size or batch count … is silently reused". That described a state two fixes ago. `seed`, `batches` and `nsamp` were already written and validated; Q-646 adds `cands`, a digest of WHICH candidates were rarity-tested and in what order, because `ncand` is a COUNT and not an IDENTITY — two runs with equal candidate counts but different candidates were merged BY POSITION, misattributing hits while every identity check passed.]** **Rows written before 2026-09-20 carry no `cands` key and are therefore refused: an existing checkpoint will restart rather than resume, which is the safe outcome, not a fault.** Delete the checkpoint file when changing any run parameter. |

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

**Scope of "the frozen spec" (read before relying on it).** The spec
file **is published**, as
[`PREREG_H1_H3_TEST_2026_07_26.md`](PREREG_H1_H3_TEST_2026_07_26.md)
(disclosed 2026-09-04, operator decision), and it is escrowed by hash in
[PREREGISTRATION_ESCROW.md](PREREGISTRATION_ESCROW.md).

**What you can now check for yourself**, which before 2026-09-04 you
could not:

```bash
sha256sum documentation/PREREG_H1_H3_TEST_2026_07_26.md
# ab09648ce5adc8bcd86255e23fc8eb58004730e7a2998b69469df130c7da3687
wc -c < documentation/PREREG_H1_H3_TEST_2026_07_26.md
# 29896
```

Both are the values
[PREREGISTRATION_ESCROW.md](PREREGISTRATION_ESCROW.md) published on
**2026-08-22**, before the file was disclosed. So the document you are
reading is byte-identical to the escrowed one, and "implements the
frozen spec verbatim" is now a claim you can audit against the spec
itself instead of an operator attestation you have to take on trust.
That conversion — attested to checkable — is the whole of what the
publication buys.

**What it still does not establish**, in the escrow page's own words: it
does not establish that the spec is *correct*, and it does not establish
that the freeze preceded the measurement. For this row the hash was
published 2026-08-22 against a file first committed 2026-07-28, i.e.
after the date the filename carries, and the escrow page's "first
committed" column is a claim rather than a proof. Escrow converts freeze
*timing* only when the hash is published **before** the run, which for
this row it was not.

⚠ **Two sentences inside the published file are no longer true of it,
and are deliberately left unedited.** Its front matter reads *"STAGED /
HELD — roae-private only"* and its §8 decision tree says *"No public
change"*. Both were true of the file when it was frozen on 2026-07-26.
They are part of the escrowed bytes, so correcting them would change the
sha above and destroy exactly the property this publication exists to
create. Read them as of the freeze date, not as of today; the disclosure
decision is recorded here and in [CORRECTIONS.md](CORRECTIONS.md), never
inside the frozen file.

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

⚠ **[CORRECTED 2026-09-25 (Q-758, Codex V3A-042#3; the zero-hit rule was
ruled the same day by a Fable pre-publication review) — a zero-hit test is
graded by its reported Wilson bound, not failed.]** The frozen spec's §4.3
says that a predicate scoring 0 hits gets its one-sided 95% Wilson bound
reported, with no escalation; the grade is still the spec's `iff` (KW
satisfies the predicate ∧ bits-explained > bar). Until this date the grader
tested `hits > 0` inside the pass condition, so a King-Wen-satisfied
predicate with zero evaluation-stream hits — the rarest outcome the run can
produce — printed `FAIL` and counted toward `NULL … 4/4 FAIL -> HELD`. Such
a test is now graded against its reported bound: when the one-sided 95%
Wilson lower bound on bits-explained exceeds the bar it is a `PASS`,
printed as that bound (`be=>= …`), and it counts like any other PASS — the
prediction is NOT HELD and the §8 adversarial re-audit fires. At the
pre-registered N_eval = 10⁶ the bound is 18.49 bits, above every frozen bar
(9.58 / 9.58 / 11.17 / 10.06), so there a zero-hit always passes. Only a
zero-hit at an N too small for the bound to resolve the bar (8.53 bits at
N = 1,000, against T4's 10.06) prints status `ZERO-HIT:STOP`, is not
graded, and makes the run report the prediction as `UNDECIDED (zero-hit
stop)` (JSON `prediction_4of4_fail_held: null`) instead of HELD. A PASS
elsewhere still takes precedence. A KW-unsatisfied predicate still FAILs at
0 hits (`FAIL-KW`), because the criterion's first conjunct is already
false; the review approved that half as written. Every run prints the token
`PREREG_ZERO_HIT_STOP=<tests>|NONE`, which lists only unresolved zero-hits.
No published verdict moves: the one recorded run of this mode (2026-07-26,
see the cross-check note below) stopped at the cross-check gate and issued
no verdicts. Regression tests: `tests.py` `TestPreregZeroHitStops`,
including a case at N_eval = 10⁶ where the two readings of the rule differ.

A validity gate cross-checks the evaluation stream's mass(A ≤ 648)
against the independently measured F4′ `dist_autocorr` figure
0.04789 ± 0.005 — on failure the run hard-stops with **exit code 3**
and issues no verdicts.

⚠ **[SCOPED 2026-09-19 — the two sides of this gate are not drawn from the same
population, and the gate has already fired for that reason.** `0.04789` is a
**C3-conditioned** figure: in `solve.c` the F4′ scorer runs inside the
`compute_comp_dist_x64(seq) <= kw_comp_dist_x64` branch (`solve.c:7995`, with
`score_f4p` called at `:8168` inside that block), so it is measured over
C1∩C2∩C4∩C5 **∩ C3**. The sampler this gate tests is **not** C3-conditioned:
`_gs_one_sample` (`roae.py:4051-4083`) accepts on the exact C5 transition
multiset only. Paired-instrument measurement on one 2×10⁷ probe stream: the
C3-gated build gives mass(A ≤ 648) = **0.04783**, reproducing the published
0.04789, while a one-line mutant that opens the gate gives **0.03789**,
reproducing the executed sampler's **0.037406** to under 1σ. **The ≈0.0105
discrepancy this gate rejects on IS the C3 conditioning — not a defective
sampler.** That is what produced the `GATE FAIL — population/sampler mismatch …
NO verdicts issued` of 2026-07-26. The constant `0.04789` at `roae.py:5077` is a
**frozen pre-registration spec value and is deliberately NOT changed**:
re-registering this gate against an unconditioned reference (≈0.0379) would be a
NEW pre-registration rather than an edit, and the pre-registration document
itself is escrow-frozen (`documentation/PREREGISTRATION_ESCROW.md:67`). Read a
FAIL here as "these two instruments condition differently", not as "the sampler
is wrong". See documentation/CORRECTIONS.md CX-52.]**
*(Line citations measured stale 2026-09-21, two days after the note was written, and re-pinned 2026-09-25 (Q-791), and again the same day (Q-758, after the zero-hit grader helpers were inserted above it, and once more when the Fable zero-hit ruling widened that grader): the `0.04789`
gate constant is at `roae.py:5077`, `_gs_one_sample` is defined at `:4060`; the `solve.c:7995` /
`:8168` citations still hold. Anchor on the symbol names.)*

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

`--seed` applies independently to each analysis that uses randomness —
**twelve** of the 29 sections, not the three most often named; the full
census is under REPRODUCIBILITY below and `--stats`, `--bootstrap` and
`--constraints` are only three of its entries. Re-running with the same
seed produces identical numerical output for all twelve. One section
sits outside that guarantee: **`--trigrams` ignores `--seed`** — its
permutation nulls draw from an RNG pinned to a constant inside the
function, so the flag never reaches them. Note also that `--constraints`
is reproducible but ignores `--trials` (above).

⚠ **[HISTORY — this page previously said `--cast` was not reproducible
under `--seed`.** That was true and measured when written: `--cast`
returned from the dispatch ladder before the global-seed assignment, so
the seed was parsed and never installed. The dispatch order was fixed
2026-09-02 (code batch C2, `3901097b`) and the behaviour re-measured —
three `--cast --seed 42` runs are now byte-identical, `--seed 7` gives a
different casting, and three unseeded runs give three distinct ones. The
`tests.py` gate `CAST_SEED_DETERMINISTIC=1` holds it. The correction
reached [GUIDE.md](GUIDE.md) on the day of the fix and did not reach
this page until 2026-09-02.**]**

## OUTPUT FORMATS

```
--color            Enable ANSI color in terminal output
--json             Export hexagram data to hexagrams.json
--csv              Export hexagram data to hexagrams.csv
--svg              Export hexagram line-diagrams to hexagrams.svg
--html             Export an HTML report to report.html
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

- **PDF: none, and none is invoked.** `--html` wrote `report.html` and then
  shelled out to `wkhtmltopdf` to render `report.pdf` until 2026-09-04, when
  that step was removed: wkhtmltopdf embeds the complete unsubsetted font
  programs it renders with (measured on the artifact that shipped —
  `pdffonts` reported `DejaVuSans`, `DejaVuSans-Bold` and `DejaVuSansMono`,
  all `emb yes sub no`), which made a public-domain repository a
  redistributor of font software under the Bitstream Vera terms. `roae.py`
  now invokes no PDF backend at all and writes no PDF. `report.html` is
  unaffected — naming a font family in CSS is a reference, not
  redistribution — and anyone who wants a PDF can render one from it
  locally, where no obligation travels.
- **`graphviz` (system package)** — for `--dot` → PNG/SVG rendering.
- **MIDI playback** — `--midi` produces `wave.mid` which can be played
  by any MIDI-capable audio system.

## EXIT STATUS

| Code | Meaning |
|---|---|
| 0 | Success, including a `--self-test` run in which every check passed. |
| 1 | `--verify` ground-truth failure — including the "could not load solve.py" failure when `--verify` is run from outside the repository directory *(the working-directory clause is stale since 2026-09-02, when the loader became `__file__`-relative; measured 2026-09-21, `--verify` passes from `/tmp`. "Could not load solve.py" now means the sibling file is missing or unreadable, and it still exits 1 — see META FLAGS)* — **and a `--self-test` run with one or more failures**. 🔴 This table said the opposite until 2026-09-07: it claimed a failing self-test still exits 0 and that `--self-test` "cannot be used as a CI gate", instructing readers to parse stdout instead. The code has carried the opposite behaviour and an explicit comment saying so — `roae.py:5475` is `return 1 if print_self_test() else 0`, directly below the comment "exit non-zero when checks fail, so `roae.py --self-test` can gate CI". Measured, not inferred. Use the exit code: `python3 roae.py --self-test` is a valid gate. Recorded as **CX-40**. *(That line number was re-pinned on 2026-09-21, again on 2026-09-25 (Q-791), and twice more the same day (Q-758, after the zero-hit grader helpers were inserted above it, and after the Fable zero-hit ruling widened that grader); the behaviour was re-measured on 2026-09-21 — 49/49 pass, rc 0 — and the line is the one to grep for.)* |
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

**Generate the full HTML report:**

```
python3 roae.py --html
# writes: report.html   (no PDF — see DEPENDENCIES)
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
- `--verify` additionally reads `solve.py` — the one **beside `roae.py`**,
  resolved from `__file__`, not from the current working directory (the
  CWD form was true until 2026-09-02; corrected here 2026-09-21, see META
  FLAGS).

**Writes** — the output-format flags below write only when requested;
the two analysis modes at the end of the list write their JSON report
and JSONL checkpoint unconditionally whenever the mode is run:

- `hexagrams.json` (`--json`)
- `hexagrams.csv` (`--csv`)
- `hexagrams.svg` (`--svg`)
- `report.html` (`--html`) — and nothing else. Until 2026-09-04 this flag
  also wrote `report.pdf` via `wkhtmltopdf`; that step was removed (see
  DEPENDENCIES) and no PDF is produced under any configuration
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

This census is taken from the code, not from prose: a section draws
random numbers iff its function calls `_reseed()` (or constructs its own
`random.Random`). Reproduce the census yourself — this prints the twelve
randomized sections plus `print_casting` (the `--cast` mode), and
nothing else:

```
awk '/^def /{f=$0} /^ +_reseed\([0-9]+\)/ {print f}' roae.py \
  | sed 's/^def //;s/(.*//' | sort -u
```

`--trigrams` does **not** appear in that list and is still randomized;
it is the one section that builds a private `random.Random` instead
(`grep -n 'Random(' roae.py`).

- **Randomized, and reproducible under `--seed` (12 sections).**
  `--complements`, `--palindromes`, `--canons`, `--entropy`, `--path`,
  `--markov`, `--constraints`, `--mutual-info`, `--neighborhoods`,
  `--recurrence`, `--bootstrap`, `--stats`. Each calls `_reseed(salt)`
  at entry, so a given `--seed` fixes its stream regardless of which
  other sections run or in what order. Their printed values are
  estimates from random draws, **not** functions of the King Wen
  sequence alone.
  - Measured: `--seed 1` vs `--seed 2` gives different output for
    `--palindromes`, `--canons`, `--entropy`, `--path`, `--markov`,
    `--mutual-info`, `--neighborhoods` and `--recurrence`.
  - `--complements` is the exception at present: its 10,000-shuffle
    null concentrates enough that the one-decimal printed summary is
    byte-identical across seeds. That is **empirical concentration at
    the current print precision, not determinism** — one added decimal
    or a smaller trial count would break it silently. Treat it as
    randomized.
- **Monte Carlo under a hard-coded internal seed (1 section).**
  `--trigrams` builds its pair-preserving permutation nulls from
  `random.Random(42)`, a constant private to that function. Its output
  is byte-identical on every run, but it is a sampled null, and
  `--seed` has **no effect on it**.
- **No randomness (16 sections).** `--table`, `--pairs`, `--wave`,
  `--barchart`, `--nuclear`, `--lines`, `--hamming`,
  `--autocorrelation`, `--fft`, `--graycode`, `--symmetry`,
  `--sequences`, `--windowed-entropy`, `--yinyang`, `--parity`,
  `--codons`. These are closed-form: the output is a function of the
  King Wen sequence (which is fixed) and nothing else.
- **`--cast` is a separate mode, not one of the 29 sections**, and
  since 2026-09-02 it *is* reproducible under `--seed` (see the dated
  history note under ANALYSIS MODIFIERS). Unseeded, it varies per run
  by design.
- Floating-point output may vary in the last decimal across
  Python versions / platforms; the qualitative findings (rankings,
  percentile placements) are stable.

### REPRODUCING `example/` BYTE-FOR-BYTE

<a id="reproducing-example-byte-for-byte"></a>

**The eleven tracked artifacts under `example/` are shipped as one fixed
seeded draw**, regenerated 2026-09-04 under `--seed 20260904`. Before that
date they were an *unseeded* draw: every Monte Carlo figure in them was a
fresh sample, and re-running `roae.py` reproduced the prose but never the
numbers.

**The seed, and why that value.** `20260904` is the ISO calendar date of
the regeneration pass. It follows the one seed convention `roae.py`
already has — `--prereg-h1h3` defaults to `20260726`, its pre-registration
freeze date. It was written down before the first seeded run, so it is not
a value selected for the figures it produces, and **no search over seeds
was performed**. If you want a different draw, pass a different `--seed`;
nothing in the analysis privileges this one.

**What that does and does not change.** No *claim* anywhere in this
repository depends on a figure in `example/` — it is an output sample, not
evidence. What changes is the status of the numbers in it: they are now
**one specific draw, frozen**, rather than a fresh sample per run. Read
them as an illustration of the output format, never as converged values.
The three report artifacts say so themselves: `roae.py` prints a
`Seeded run: --seed 20260904` line into `report.txt`, `report.md` (hence
`README.md`) and `report.html`, and prints nothing there when the run was
unseeded.

**The recipe.** Run every export from inside `example/` except `--all`,
which is the only one that writes to stdout — `--markdown`, `--html` and
the data exports open their own files in the working directory:

```
python3 roae.py --all --seed 20260904 > example/report.txt
( cd example && python3 ../roae.py --markdown --seed 20260904 )
cp example/report.md example/README.md
( cd example && python3 ../roae.py --html --seed 20260904 )
for f in csv json svg dot midi; do
  ( cd example && python3 ../roae.py --$f --seed 20260904 )
done
```

`scripts/doc_gates.sh generated` (GATE 8) regenerates under the same seed
and compares all eleven artifacts **byte-exact**, digits included. It was
digit-stripped until 2026-09-04, because an unseeded generator made a byte
comparison fail on correct artifacts every time.

**What is and is not seed-dependent, measured rather than assumed.** Two
independent generations at `--seed 20260904` were byte-identical on all
eleven artifacts. A third at a different seed differed on all four report
artifacts (`report.txt`, `report.md`, `README.md`, `report.html`) and on
**none** of the other seven — `hexagrams.{csv,json,svg}`, `wave.dot`,
`wave.dot.png`, `wave.dot.svg`, `wave.mid` are closed-form functions of
the 64-hexagram table and carry no random draws at all. The seed is passed
to them in the recipe above only so that one command covers every artifact.

**Caveats.** `wave.dot.png` and `wave.dot.svg` are rendered by the
external Graphviz `dot` binary, so their bytes depend on the installed
renderer as well as on `roae.py`; they reproduce byte-for-byte on the
same `dot` (2.43.0 here) and may not across a renderer upgrade.
Floating-point output may vary in the last decimal across Python versions
and platforms, as noted above.

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
| **Determinism** | 16 sections are closed-form; 12 are randomized and reproducible under `--seed`; `--trigrams` samples a null under an internally pinned seed and ignores `--seed`. See REPRODUCIBILITY | Fully — given fixed solver + inputs, the **decompressed** `solutions.bin` stream is byte-identical (partition invariance). The gzip container is not canonical: raw `sha256sum solutions.bin` hashes the framing, which varies with zlib version and compression level. Verify via the `solutions.sha256` sidecar or `gzip -dc solutions.bin \| sha256sum` (see [CANONICAL_HASHES.md](CANONICAL_HASHES.md)); the raw file is byte-identical only under `SOLVE_COMPRESS=0` |
| **Dependencies** | `roae.py` itself: Python 3 stdlib only. The PNG/SVG side-outputs additionally invoke the external `dot` binary when present, and are silently skipped when absent. (There is no PDF side-output: the `wkhtmltopdf` step was removed 2026-09-04 — see DEPENDENCIES.) (This row covers `roae.py` only — `solve.py`'s P2 analysis modes are **not** stdlib; see [DEVELOPMENT.md](DEVELOPMENT.md).) | `gcc` with OpenMP, `zlib` (`zlib1g-dev` — `solve.c` includes `<zlib.h>` unconditionally), `libm` (`-lm`), `pthread`, `sha256sum`; canonical build line in [DEVELOPMENT.md](DEVELOPMENT.md) |
| **Audience** | Anyone curious about KW's internal structure | Researchers evaluating uniqueness against C1-C5 |

The example output bundle in `example/` is what you get from running
`python3 roae.py` with various output formats enabled. See
[example/README.md](../example/README.md), and
[REPRODUCING `example/` BYTE-FOR-BYTE](#reproducing-example-byte-for-byte)
below for the seed it is shipped under.

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

**Single Python source file:** `roae.py` is one file, and the project's
single-file rule (modeled on the single-C-file rule for `solve.c`) is about
**one file per role**, not one Python file in the repo.

⚠ **[CORRECTED 2026-09-03 — this read *"`roae.py` and `solve.py` are the only Python
files, plus `viz/visualize.py` … No `scripts/` subdirectory; no separate analysis
scripts"* (Codex V2-F49 #13). Measured against `git ls-files '*.py'`: **21 tracked
Python files**, and `scripts/c2c3_joint_null.py` exists, so both halves were false.]**

The rule's actual scope — one file per role:

| role | file |
|---|---|
| C solver / enumerator | `solve.c` |
| Python solver + ground-truth authority | `solve.py` |
| SAT encoder | `sat.py` |
| analysis battery | `roae.py` |
| independent verifier | `verify.py` (plus `verify.c`) |
| regression harness | `tests.py` |

Outside those roles the repo also tracks `scripts/c2c3_joint_null.py`, three `viz/`
plotting scripts (`visualize.py`, `growth_curve.py`, `report_figures.py` — heavy
dependencies, not part of any gate), and **12** one-shot instruments under
`reports/evidence/` that are archived beside the results they produced. Those are
evidence, not solver surface; the rule constrains the six files above.

## HISTORY

Recent material changes (full record in [HISTORY.md](HISTORY.md)):

- 2026-04-15+ multiple analysis-section additions and corrections
  (XOR algebra reframed as a theorem; null-model framings added
  for constraints, palindromes, canon split, recurrence,
  neighborhoods)
- 2026-04 the analysis-section buildout — the multi-section coverage
  this page documents begins at `37065808` (2026-04-06, "Add hexagram
  names, trigram analysis, spark lines, Monte Carlo, and CLI flags");
  output formats (HTML, PDF, MIDI, Graphviz) expanded over the weeks
  following (the PDF export was removed again on 2026-09-04 — see
  DEPENDENCIES; this line records what the buildout added, not what
  `roae.py` writes today). The 29th section, `--parity`, was added 2026-05-19
  (`7d84ffe5`)
- 2026-04 (early) the initial six-round adversarial scientific review
  surfaced the trigram name swap bug (fixed 2026-04-07, `dc489e8c`),
  the complement-distance direction error ("maximizes" → "minimizes",
  corrected 2026-04-09, `5494ebac`), the XOR-as-theorem realization
  (`32bf7bf5` 2026-04-08, `d149bb70` 2026-04-09), and the null-model
  caveat. [HISTORY.md](HISTORY.md) frames this whole phase as its
  "Prelude — Before April 10, 2026"
