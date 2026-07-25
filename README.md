# ROAE — Received Order Analysis Engine

<mark>**[䷀䷁](documentation/SOLVE_SUMMARY.md)**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

**The question:** the King Wen sequence — the ~3,000-year-old received ordering of the 64 I Ching
hexagrams — has attracted structural claims for centuries, almost all asserted by inspection. Can those
claims be tested? Can the sequence be reconstructed from its mathematical constraints? This project
treats the sequence as a combinatorial object: it **enumerates** the space of orderings satisfying the
sequence's constraints, **measures** claimed regularities against that space, and **proves** (with
machine-checked proofs and SAT certificates) what is forced, what is rare, and what is impossible.

New to the I Ching or combinatorics? Start with [GUIDE.md](documentation/GUIDE.md).

## The constraints

The sequence's structural properties, extracted from the received order and its classical commentary,
are treated as axioms defining a space of orderings ([formal definitions](documentation/SPECIFICATION.md) · [plain-language summary](documentation/SOLVE_SUMMARY.md)):

- **C1** — the 64 hexagrams form 32 consecutive pairs, each a hexagram with its reverse (or complement
  when reversal is trivial): the classical pairing, described by [Yu Fan](documentation/CITATIONS.md#yufan) in the 3rd century.
- **C2** — no two adjacent hexagrams differ in exactly five lines ([McKenna & McKenna 1975](documentation/CITATIONS.md#mckenna-mckenna1975)).
- **C3** — complementary hexagrams sit near each other (a positional-distance ceiling at KW's own value).
- **C4** — the sequence starts with the pair ䷀ Qian (The Creative) #1 and ䷁ Kun (The Receptive) #2, i.e., Heaven followed by Earth.
- **C5** — the multiset of adjacent-transition sizes matches King Wen's exactly.

C1–C2 are robust properties; C3–C5 are extracted from the sequence itself — the distinction matters and
is policed throughout ([CRITIQUE.md](documentation/CRITIQUE.md)). Two further extracted constraints
(C6–C7) appear only where marked.

## The instruments

| Tool | Role |
|---|---|
| **[solve.c](solve.c)** | The enumerator. Multi-threaded C; produces byte-reproducible enumeration slices anchored by sha256 ([CANONICAL_HASHES](documentation/CANONICAL_HASHES.md)); also an unbiased estimator of the full space. Deepest artifact: 10.5 billion orderings, derived twice byte-identically on preemptible cloud. |
| **[solve.py](solve.py)** | The independent ground truth. Every constraint implemented a second time, in Python, and cross-checked against the C. |
| **[sat.py](sat.py)** | The decision layer. Encodes exact questions ("does an ordering with property X exist?") for a SAT solver; UNSAT answers carry independently checkable certificates. |
| **[roae.py](roae.py)** | The exploratory analysis suite: 28 statistical analyses of the sequence with honest null models ([example output](example/)). |
| **[lean/](lean/)** | Machine-checked theorems (Lean 4): the core lemmas, four sequence-level theorems, the trigram-level structure ([TRIGRAM_STRUCTURE](documentation/TRIGRAM_STRUCTURE.md)), and the model-level merge/partition-invariance theorems (see [lean/README.md](lean/README.md) for the trust-base and scope notes). |
| **[tests.py](tests.py)** · **[verify.py](verify.py)** · **[verify_all.sh](reports/certificates/verify_all.sh)** | The verification layer — the instrument that checks the other five: Python regression harness, two-language record verifier, and the one-command check of every certificate, gate, and proof. |

## What was found

Headlines only — each links to its full treatment (technical reports in [reports/](reports/)):

- **The constraints do not determine the sequence.** The C1–C5 space holds 1.33×10³⁸ orderings; adding
  C6–C7 still leaves ~5×10³¹. The hypothesis that the constraints pin down King Wen — the strong reading
  of the literature's derivation claims, and this project's own early working assumption
  ([attribution note](documentation/CITATIONS.md#uniqueness-conjecture)) — is false. [TR-4](reports/TR4_SIZE_OF_THE_SPACE.md)
- **The literature's rules conflict.** The four strongest rules asserted across eight centuries are
  jointly unsatisfiable for any ordering preserving the classical pairing — none can be perfect under all of them. King Wen keeps one exactly and
  misses the others minimally: its famous anomalies are a **forced trade-off, not damage** — and a 47-year-old proposal to replace the sequence is decided along the way. [TR-1](reports/TR1_EIGHT_CENTURIES_MEASURED.md), [TR-2](reports/TR2_THE_RULES_CONFLICT.md), [TR-8](reports/TR8_REORDERING_REVISITED.md)
- **Eight rules asserted as design are proven forced** — each a theorem, constant on the entire C1 space (a superset of the measured population, so every valid ordering inherits King Wen's value), machine-checked in Lean 4 ([lean/C1RuleConstants.lean](lean/C1RuleConstants.lean)); the zero-violation 2×10¹⁰-probe measurements now serve as instrument validation. A separate analytic theorem — the no-5 rule's implication chain, behind McKenna's 3:1 ratio — stands in addition. They are consequences of the constraint system, not choices. Others
  are genuinely discriminating (to ~1 in 5×10⁷ — an order-of-magnitude figure at that sampling depth; see METHODS). [TR-1](reports/TR1_EIGHT_CENTURIES_MEASURED.md)
- **Every valid ordering has exactly 23 indistinguishable twins** (the symmetry group acts freely), and
  exactly **15 parity-class alternations** (proven three independent ways). [TR-5](reports/TR5_SYMMETRY.md), [TR-6](reports/TR6_PARITY_SKELETON.md)
- **McKenna's "ninth six" is forced.** The 1975 observation that exactly one adjacent transition flips
  all six lines holds in **every** valid ordering — machine-proven: the between-pair transition budget is
  a theorem of the constraints, turning the 10.5-billion-record measurement into a corollary (the
  *position* of that transition remains ordering-dependent). [TRIGRAM_STRUCTURE](documentation/TRIGRAM_STRUCTURE.md)
- **The pairing is optimal** — the classical pair structure is the unique Hamming-cost-minimizing
  matching ([Radisic 2026](documentation/CITATIONS.md#radisic2026) — preprint, machine-verified). [CITATIONS](documentation/CITATIONS.md)
- **The circular reading has a price.** Read as a cycle (McKenna's construction), the sequence needs one
  more rule — and orderings violating it are 17.4% of the full space yet absent from all 10.5 billion
  enumerated records: the sharpest demonstration that bounded search sees a biased sample. [TR-7](reports/TR7_CIRCULAR_READING.md)
- **Half the sequence is explained; half by nothing known.** In bits: the classical pairing carries
  nearly all the explanatory weight (and is provably optimal); the transition histogram is confirmed
  description, not explanation; ~126 bits remain open. [TR-9](reports/TR9_PRICING_THE_CONSTRAINTS.md)
- **A structural reading, measured.** [Davis's (2012)](documentation/CITATIONS.md#davis2012) flagship compositional units come out
  population-typical; one uniqueness claim is corrected; the ~126-bit residual survives its second
  literature-guided attack. [TR-10](reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)
- **Exact counts at full scale.** |C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688
  (≈1.097×10³⁹; the suite's second exact full-scale count — the first, |C1∩C2∩C4| ≈ 7.5706×10⁴¹, landed
  2026-07-04) — computed to the last digit via the symmetry theorem's 24-fold quotient, divisible by 24
  exactly as that theorem predicts. This exact count currently rests on a **single instrument** (the
  orbit-quotient DP) — mod-24- and out-of-core-ladder-corroborated, but **not independently recomputed at
  full scale** ([TR-11](reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §10(vi); the independent
  second-instrument verifiers are [verify.py/verify.c](documentation/VERIFY.md)). It is reproducible on
  ~64 GB of RAM plus ~4 TB of disk; the statistical
  estimator validated absolutely at 10³⁹ (the exact value lands inside its stated ±0.01% envelope). The
  flagship C1–C5 figure remains an estimate. [TR-11](reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)
- **The record is reproducible**: every published count re-derivable to the byte by one command; the
  deepest run reproduced from scratch through seven fresh Spot evictions (twelve across both runs). [TR-3](reports/TR3_REPRODUCIBLE_ENUMERATION.md)

**Honesty apparatus.** Every caveat lives in [CRITIQUE.md](documentation/CRITIQUE.md) — read it before
quoting anything above. It covers the constraint-extraction circularity, the null-model studies, the
look-elsewhere accounting, and one corrected published result. It also reports the corpus-control test:
the same methodology flags a provably algorithmic ordering ([Jing Fang](documentation/CITATIONS.md#jingfang)) on 9 of 11 axes, and King Wen on
exactly its three documented constraints — the method does not find design wherever it looks (a control
corpus of the two documented historical alternatives available; the small n is stated in CRITIQUE).

## Quick start
```
gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz && ./solve --selftest   # must print PASS
python3 roae.py            # the 28 analyses
python3 solve.py --registry-verify   # the two-language ground-truth gates (31/31 must PASS)
python3 sat.py                       # SAT layer usage + targets
python3 tests.py                     # regression harness (28 tests)
bash reports/certificates/verify_all.sh   # everything above + all DRAT certs + Lean, one command
```
Full CLI references: [SOLVE_C_CLI](documentation/SOLVE_C_CLI.md) · [ROAE_PY_CLI](documentation/ROAE_PY_CLI.md).

## Going deeper
**If you read one thing**: [TR-1](reports/TR1_EIGHT_CENTURIES_MEASURED.md) — the literature's rules, measured and decided.
[reports/](reports/) — the full technical report suite (start at its [index](reports/README.md) for the map and reading paths) · [PROJECT_OVERVIEW](documentation/PROJECT_OVERVIEW.md) — the detailed findings narrative formerly on this page ·
[CLAIMS_DECIDED](documentation/CLAIMS_DECIDED.md) — the empirical scorecard (what's refuted, corrected, forced, confirmed) · [SOLVE_SUMMARY](documentation/SOLVE_SUMMARY.md) — plain-language results · [CITATIONS](documentation/CITATIONS.md) — every source, every attribution, annotated bibliography · [HISTORY](documentation/HISTORY.md) — the project narrative including its mistakes.

## References

> **All scholarly attribution lives in [CITATIONS.md](documentation/CITATIONS.md)** and is deliberately
> not duplicated here — classical sources (Yu Fan, Zhu Yuansheng, Lai Zhide), the modern structural
> literature (Schulz, Moore, Cook, Hacker, McKenna & Mair, Davis, Drasny), the 2026 arXiv treatments
> (Chan; Radisic), methodological citations, and per-finding scoping of what is classical / prior work /
> independently verified / believed novel. CITATIONS.md includes a standing invitation to report prior
> work not yet cited.

The links below are reader orientation only:

* [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) — Wikipedia
* [King Wen of Zhou](https://en.wikipedia.org/wiki/King_Wen_of_Zhou) — Wikipedia (traditional attribution, ~1000 BCE; modern scholarship is divided on the exact origin and dating of the sequence)
* [OEIS A102241](https://oeis.org/A102241) — binary encoding of King Wen hexagrams
* [Bagua (eight trigrams)](https://en.wikipedia.org/wiki/Bagua) — Wikipedia (trigram names and associations)
* [Hexagram (I Ching)](https://en.wikipedia.org/wiki/Hexagram_(I_Ching)) — Wikipedia (hexagram structure, nuclear trigrams)
* [I Ching divination](https://en.wikipedia.org/wiki/I_Ching_divination) — Wikipedia (three-coin method, simulated by `roae.py --cast`)
* [Shao Yong](https://en.wikipedia.org/wiki/Shao_Yong) — Wikipedia (Fu Xi binary ordering)
* [Mawangdui Silk Texts](https://en.wikipedia.org/wiki/Mawangdui_Silk_Texts) — Wikipedia (background on the silk manuscripts; the ordering itself is per Shaughnessy 2022 below, tested by `solve.c --null-historical`)
* [Jing Fang](https://en.wikipedia.org/wiki/Jing_Fang) — Wikipedia (Eight Palaces ordering, also tested by `solve.c --null-historical`)
* [The I Ching or Book of Changes](https://press.princeton.edu/books/hardcover/9780691097503/the-i-ching-or-book-of-changes) — Richard Wilhelm, trans. Cary F. Baynes, Princeton University Press (hexagram names)
* Edward L. Shaughnessy, *I Ching: The Classic of Changes*, Ballantine Books, 1996 (translation of the Mawangdui manuscript); the project's Mawangdui ordering array follows Shaughnessy, *The Origin and Early Development of the Zhou Changes*, Brill, 2022, Table 11.2 (corrected 2026-07-05 — see CITATIONS.md errata)
* [Yijing Dao (biroco.com)](https://www.biroco.com/yijing/) — Steve Moore's archive of Yijing structural-analysis literature (source of several documents examined in CITATIONS.md)
* [Terence McKenna: Novelty theory and Timewave Zero](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero) — Wikipedia (see [MCKENNA.md](documentation/MCKENNA.md); full citation in CITATIONS.md)

## Built with
[Claude Code](https://claude.ai/code) (Anthropic) — see AI-assistance headers in each source file.
