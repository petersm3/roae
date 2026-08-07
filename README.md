# ROAE — Received Order Analysis Engine

<mark>**[䷀䷁](documentation/SOLVE_SUMMARY.md)**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

**The question.** The I Ching is an ancient Chinese divination text — its roots go back roughly
three thousand years — organized into 64 chapters, each marked by a hexagram: a stack of six broken
or unbroken lines. In every received copy the 64 chapters appear in one particular order, the **King
Wen sequence**, and no one knows why that order. For centuries, commentators have proposed
structural rules that are supposed to explain it — patterns in how each hexagram relates to its
neighbours — almost always asserted by inspection and almost never tested. This project treats the
sequence as a combinatorial object and puts the rules to the test: it **enumerates** orderings
satisfying the sequence's constraints, **measures** claimed regularities against that space —
including how rare each one is — and **proves**, with machine-checked proofs and SAT certificates,
what is forced and what is impossible. (Rarity figures are estimates from weighted-Knuth sampling
with stated probe counts, not proofs; the distinction is kept throughout.) The question underneath
it all: do the rules, taken together, actually determine the order?

(How old, precisely: the ordering is traditionally attributed to King Wen of Zhou, ~1000 BCE,
though the dating of its fixation is debated in modern scholarship. Concretely
([Shaughnessy 2022, ch. 11](documentation/CITATIONS.md#shaughnessy2022)): the earliest artifactual
witness of the received sequence is the Xiping Stone Classics (175–183 CE), with the fragmentary
Fuyang *Zhouyi* (tomb dated 165 BCE) an earlier partial witness. The Mawangdui silk manuscript
(copied before 168 BCE) attests a *different* ordering in circulation.)

**The finding.** They do not. This project began from the hypothesis that the King Wen sequence is
*determined* by its published constraints — that the received order could be **derived** from them.
We enumerated, we measured, and **the hypothesis is false**: an estimated 5×10³¹ — fifty nonillion —
other orderings satisfy the same rules. Whatever fixed the received order, the tested rules alone
did not.

**What this does — and does not — mean.** Three scope notes worth carrying from the start:

- **It does not say the sequence is random, or that nobody designed it.** The test is of the
  literature's rules *as stated*. An arranger may have followed considerations nobody wrote down;
  this project measures only what the stated rules force.
- **The enumeration is budgeted, not exhaustive.** The space of valid orderings is far too large to
  list in full; the explicit listings cover defined, reproducible slices of it, and every
  uniqueness statement in this repository is scoped to those slices, never to the full space.
- **The direction is not new — the measurement is.** Earlier scholars had already argued that no
  known rule fixes the sequence; this project's contribution is measuring it (attribution below).

Scope: this is a combinatorial study of the *ordering* alone; it makes no claims — supportive or
dismissive — about the I Ching's text, its divination practice, or its philosophical tradition.

**The finding, precisely.** The plain sentence above compresses a hedged one; here is the full
statement, with every label attached. About **5.21×10³¹** orderings — a raw, orientation-explicit
count ([METHODS](reports/METHODS.md) §"Canonical quantities") — satisfy the full C1–C7
inventory. That figure is a Knuth random-probe **estimate**, 95% CI [5.13, 5.29]×10³¹ — a statistical
estimate, not a proven cardinality — but the verdict needs only that the count is not 1, and the CI's
*lower* bound is 5.13×10³¹, so no plausible estimator error touches it. The conclusion is also
corroborated **exactly, with no estimator involved**: inside King Wen's own 22-pair prefix, exact
counting finds **16,504** C1–C5 completions of which exactly **8** satisfy C6–C7 — King Wen and seven
others in its immediate neighbourhood ([TR-4](reports/TR4_SIZE_OF_THE_SPACE.md) §4). King Wen is
unique only within **budgeted enumerated slices**, never in the full space. Read against the
literature, this is **a measured confirmation of prior under-determination claims, and the magnitude
is a single-instrument estimate**: the direction was asserted qualitatively before this project
measured it (see the prior negatives below), and the C1–C7 figure comes from `solve.c`'s estimator
alone — every two-instrument exact quantity in the suite is C3-free
([TR-11](reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)). Neither label doubts the number:
the estimator is externally validated at both full-scale layers where exact ground truth exists,
inside its stated envelope both times ([TR-4](reports/TR4_SIZE_OF_THE_SPACE.md) §"Estimator
calibration"), and the C6–C7 verdict is corroborated exactly at small scope (the 8 of 16,504
above). What no prior author did is the measurement.

**Whose hypothesis this was.** The name "Uniqueness Conjecture" is **this project's own coinage**. To
our knowledge no author asserted in so many words that the C1–C7 inventory pins down the sequence, and
programs such as [Cook (2006)](documentation/CITATIONS.md#cook2006) invoke principles well beyond the
tested inventory — so **the refutation touches none of those works as stated**
([full attribution note](documentation/CITATIONS.md#uniqueness-conjecture)). What it refutes is the
strong reading of the derivation-flavoured literature, and — squarely — **this project's own early
working assumption**. We are reporting a negative result about our own starting position, which is why
it is stated before anything else this page claims. The other half of the attribution cuts against us
and belongs beside it: the refutation's
**direction was prior art** — Ouyang Weicheng (1990) held that the hexagrams have no intrinsic order,
Zhang Qingyu (1998) conceded his orbit framework could not fix the 48 散卦,
and Suenaga (2012) reported finding no rule that fixes the sequence
([prior negatives](documentation/CITATIONS.md#uniqueness-conjecture)) — so what is new here is the
measurement, not the direction.

**Who checked this — an authorship disclosure.** The verification in this repository is independent
in *mechanism*, not in *authorship*. Two languages implement every constraint and cross-check each
other, an external proof kernel checks the Lean theorems, and the DRAT certificates are verified by a
checker this project did not write — but the same author wrote the claims, the tools that check them,
and the reports that grade the outcome, and **no independent party has yet audited or reproduced any
of it**. "Verified" in this repository never means a third party looked. The machine-checked
mathematics does not weaken under this disclosure *as mathematics* — those derivations hold or fail
regardless of who submitted them to the checker — but the checker verifies a **statement this project
wrote**, and whether the Lean proposition or the CNF says what the surrounding prose says it says is
itself same-author. Everything upstream and downstream of the proofs carries the discount too: whether the
formalized rules and extracted constraints mean what the cited literature meant, and whether the
results are graded fairly, have had no examiner who did not also write them. The full ladder, from
weakest check to the third-party rung this project has not reached, is in
[METHODS](reports/METHODS.md) §"Authorship independence".

**Check it yourself — one command, one expected number.** The fastest way to stop taking this on
trust. On a clean Debian/Ubuntu machine (measured 2026-08-04 on Ubuntu 24.04; see
[DEVELOPMENT](documentation/DEVELOPMENT.md) §Build prerequisites for the package list):

```
git clone https://github.com/petersm3/roae.git && cd roae
gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm -lz
./solve --selftest
```

It must print `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e`. A different digest
is a finding — please report it. This recipe was executed end to end from a fresh clone on
2026-08-04 and passed, together with `python3 tests.py` (64 tests at that date; the harness has since grown to 67) and `lean lean/KingWen.lean`
(silent, i.e. all theorems check); before that date it had never actually been run, which is itself
the kind of gap this disclosure exists to surface.

**Where to start.** Four doors, by reader:

- **Curious, no background** — [GUIDE.md](documentation/GUIDE.md), the from-zero orientation, then
  [SOLVE_SUMMARY.md](documentation/SOLVE_SUMMARY.md), the results in plain language.
- **Mathematician or statistician** — the technical report suite in [reports/](reports/) (map and
  reading paths at its [index](reports/README.md)); definitions, canonical quantities and estimator
  conventions in [METHODS](reports/METHODS.md).
- **Skeptic** — [CRITIQUE.md](documentation/CRITIQUE.md), the project's standing case against its
  own results, plus the authorship disclosure above and the append-only corrections record in
  [CORRECTIONS.md](documentation/CORRECTIONS.md).
- **Replicator** — the one-command check above, then the full replication recipe in
  [TR-3](reports/TR3_REPRODUCIBLE_ENUMERATION.md).

## The constraints

The sequence's structural properties, extracted from the received order and its classical commentary,
are treated as axioms defining a space of orderings ([formal definitions](documentation/SPECIFICATION.md) · [plain-language summary](documentation/SOLVE_SUMMARY.md)):

- **C1** — the 64 hexagrams form 32 consecutive pairs, each a hexagram with its reverse (or complement
  when reversal is trivial): the classical pairing, described explicitly by [Kong Yingda](documentation/CITATIONS.md#kongyingda) in the 7th century, with roots in [Yu Fan](documentation/CITATIONS.md#yufan)'s 3rd-century pair relations.
- **C2** — no two adjacent hexagrams differ in exactly five lines ([McKenna & McKenna 1975](documentation/CITATIONS.md#mckenna-mckenna1975); independently in [Cook 2006](documentation/CITATIONS.md#cook2006)).
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

- **The constraints do not determine the sequence.** The C1–C5 space is **estimated** at 1.33×10³⁸ orderings — a raw, orientation-explicit count; ≈3.3×10³⁷ after orientation-dedup ([METHODS](reports/METHODS.md) §"Canonical quantities") — (Knuth random-probe, 95% CI [1.3283, 1.3292]×10³⁸ — a statistical estimate, not a proven cardinality); adding
  C6–C7 still leaves ~5×10³¹. So the hypothesis that the constraints pin down King Wen is false — that
  was the strong reading of the literature's derivation claims, and this project's own early working
  assumption ([attribution note](documentation/CITATIONS.md#uniqueness-conjecture)). [TR-4](reports/TR4_SIZE_OF_THE_SPACE.md)
- **The literature's rules conflict.** The four strongest rules asserted across eight centuries are
  jointly unsatisfiable — no C1∩C2∩C4∩C5-valid ordering can be perfect under all four. King Wen keeps one exactly and misses the others minimally, so its famous anomalies
  are a **forced trade-off, not damage to an original that was perfect under all four** — no such
  original could exist. (A *three*-rule-perfect precursor does exist; whether the anomalies are an
  arranger's trade-off or damage to that precursor is weighed, not settled, in TR-2's model
  comparison.) A 47-year-old proposal to replace the sequence is decided along the way. [TR-1](reports/TR1_EIGHT_CENTURIES_MEASURED.md), [TR-2](reports/TR2_THE_RULES_CONFLICT.md), [TR-8](reports/TR8_REORDERING_REVISITED.md)
- **Eight rules asserted as design are proven forced.** Each is a theorem, machine-checked in Lean 4
  ([lean/C1RuleConstants.lean](lean/C1RuleConstants.lean)): constant on the entire C1 space — a superset
  of the measured population, so every valid ordering inherits King Wen's value. They are consequences
  of the constraint system, not choices; the zero-violation 2×10¹⁰-probe measurements now serve as
  instrument validation. *(Scope: Lean proves constancy of the `countP` forms defined in that file.
  Identifying those forms with the registry rules as implemented — `reg_*` in solve.py,
  `score_registry` in solve.c — is a **non-Lean transcription step**, numerically validated by driving
  the repo's own `reg_*` over 5,449 structured C1 sequences with zero deviations, and disclosed in the
  Lean file's header and in [lean/README.md](lean/README.md). So the eight are Lean-proven **modulo a
  validated transcription** — the same runtime-carried bridge disclosed for PartitionInvariance and
  PruneExactness. The 5,449-sequence check was run from a scratchpad script that is not in the repo;
  re-deriving it as a tracked artifact is an open item.)* (A separate analytic theorem — the no-5 rule's implication chain, behind
  McKenna's 3:1 ratio — stands in addition.) Other asserted rules are extremely rare as stated, down to
  ~1 in 5×10⁷ — an order-of-magnitude figure at that sampling depth, with the most specific
  configurations rare largely by specification rather than principle; see METHODS and TR-1's data-like
  caveat. [TR-1](reports/TR1_EIGHT_CENTURIES_MEASURED.md)
- **Every valid ordering has exactly 23 record-level indistinguishable twins** (the symmetry group acts
  freely), and exactly **15 parity-class alternations** (proven three independent ways). [TR-5](reports/TR5_SYMMETRY.md), [TR-6](reports/TR6_PARITY_SKELETON.md)
- **No symmetry-respecting generator can single out King Wen.** Any generator that scores orderings
  using only G-invariant structural primitives (Hamming distance, complement, reversal, the values 0/63,
  …) gives King Wen's record and each of its 23 twins equal probability — so it can place at most **1 in
  24** of its mass on King Wen, never more (`equivariance_ceiling`, kernel-checked in
  [lean/KingWen.lean](lean/KingWen.lean)). The bound is Curie's principle (symmetry of causes ⇒ symmetry of
  effects), not new — the contribution is the King-Wen instantiation and its machine-check. [lean/README §The equivariance ceiling](lean/README.md), [lean/KingWen.lean](lean/KingWen.lean)
- **McKenna's "ninth six" is forced.** The 1975 observation that exactly one adjacent transition flips
  all six lines holds in **every** valid ordering — machine-proven: the between-pair transition budget
  is a theorem of the constraints, so the 10.5-billion-record measurement becomes a corollary. (The
  *position* of that transition remains ordering-dependent.) [TRIGRAM_STRUCTURE](documentation/TRIGRAM_STRUCTURE.md)
- **The pairing is optimal.** The classical pair structure is the unique Hamming-cost-minimizing
  complement/reversal (comp/rev) matching ([Radisic 2026](documentation/CITATIONS.md#radisic2026) —
  preprint, machine-verified). Scope guard: comp∘rev matchings can do better — see
  [lean/HammingOptimalMatching.lean](lean/HammingOptimalMatching.lean). [CITATIONS](documentation/CITATIONS.md)
- **The circular reading has a price.** Read as a cycle (McKenna's construction), the sequence needs
  one more rule. Orderings violating that rule are 17.4% of the full space yet absent from all 10.5
  billion enumerated records — a stark demonstration that bounded search sees a biased sample. (The
  17.4% is a 2×10¹⁰-probe sampled estimate, independently reproduced by a second archived run to within 0.05
  percentage points — TR-7 §5.) [TR-7](reports/TR7_CIRCULAR_READING.md)
- **Half the sequence is explained; half by nothing known.** In bits: the classical pairing carries
  nearly all the explanatory weight (and is provably optimal among comp/rev matchings); the transition histogram is confirmed
  description, not explanation; **between about 105 and 139 bits** remain open — the exact figure
  depends on which layers are granted explanatory standing (105.4 bits = log₂|C1–C7|, the most
  conservative reading, resting on the ±0.78% C1–C7 estimate ≈ ±0.01 bits; 139.1 bits =
  log₂|C1∩C2∩C4|, the residual against the claimed-explanatory layers alone — a logarithm of an
  exact count; the intermediate C1–C5 reading ~126.6 rests on the tighter ±0.02%
  estimate). [TR-9](reports/TR9_PRICING_THE_CONSTRAINTS.md)
- **A structural reading, measured.** [Davis's (2012)](documentation/CITATIONS.md#davis2012) flagship compositional units come out
  population-typical; one uniqueness claim is corrected; the ~126-bit (C1–C5-layer) residual survives its second
  literature-guided attack. [TR-10](reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)
- **Exact counts at full scale.** |C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688
  (≈1.097×10³⁹; counting orientation-explicit sequences with C4's pair pinned —
  [METHODS](reports/METHODS.md) §"Canonical quantities") — computed to the last digit via the symmetry theorem's 24-fold quotient, and divisible
  by 24 exactly as that theorem predicts. (It is the suite's second exact full-scale count; the first,
  |C1∩C2∩C4| ≈ 7.5706×10⁴¹, landed 2026-07-04.) The count was **recomputed at full scale** (2026-07-25)
  by a second instrument — `verify.c`'s inclusion–exclusion transfer-walk engine (`--ie-count`), a
  different algorithm class sharing no code or machinery with `solve.c` — and the two integers **match
  exactly**, with the mod-24 free-action gate holding
  ([TR-11](reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §10(vi); the verifiers are
  [verify.py/verify.c](documentation/VERIFY.md)). The honest residual: both instruments are
  project-authored and share the group-theory/constraint specification, so the independence is
  algorithmic, not specificational — no third party has recomputed the count. It is reproducible on
  ~64 GB of RAM plus ~4 TB of disk; the statistical estimator is validated absolutely at 10³⁹ (the
  exact value lands inside its stated ±0.01% envelope). The flagship C1–C5 figure remains an
  estimate. [TR-11](reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)
- **The record is reproducible**: every published count re-derivable to the byte by one command; the
  deepest run reproduced from scratch through seven fresh Spot evictions (twelve across both runs). [TR-3](reports/TR3_REPRODUCIBLE_ENUMERATION.md)

**Honesty apparatus.** Every caveat lives in [CRITIQUE.md](documentation/CRITIQUE.md) — read it before
quoting anything above. It covers the constraint-extraction circularity, the null-model studies, the
look-elsewhere accounting, and the corrected published results (the full never-silent corrections
ledger — including a retracted theorem — is in [CLAIMS_DECIDED.md](documentation/CLAIMS_DECIDED.md)). It also reports the corpus-control test:
the same methodology flags **both** non-KW controls — a provably algorithmic ordering
([Jing Fang](documentation/CITATIONS.md#jingfang)) on 9 of 11 axes **and the trigram-block-sorted
Mawangdui order on 9 of 11** — while King Wen comes out on exactly its three documented constraints
(3 of 11; 0 of 11 against the pair-preserving null). Read honestly, that is a **positive** control:
the battery does detect algorithmic construction where it exists. It is *not* a specificity test —
both available controls lit up, so the only quiet case in the corpus is the object of study itself.
CRITIQUE states the limit in the same terms (n = 2 non-KW historical controls; no negative control
exists in the corpus).

## Quick start
```
gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz && ./solve --selftest  # must print PASS
python3 roae.py                          # the analysis battery (29 sections; 28 statistical + the theorem-backed --parity)
python3 solve.py --registry-verify       # the two-language ground-truth gates (31/31 must PASS)
python3 sat.py                           # SAT layer usage + targets
python3 tests.py                         # regression harness (67 tests)
bash reports/certificates/verify_all.sh  # everything above + all DRAT certs + Lean, one command
```
`verify_all.sh` needs four external tools — **gcc**, **python3**, **drat-trim** and **lean** (elan).
It probes for each up front and reports any dependent check as **SKIP**, not FAIL: a SKIP means the
tool is absent, never that a certificate failed to verify. SKIPs do not pass the run — the exit
status distinguishes them — so a machine without drat-trim and Lean gives a partial, honestly-labelled
result rather than a wall of failures.
Full CLI references: [SOLVE_C_CLI](documentation/SOLVE_C_CLI.md) · [ROAE_PY_CLI](documentation/ROAE_PY_CLI.md).

## Going deeper
**If you read one thing**: [TR-1](reports/TR1_EIGHT_CENTURIES_MEASURED.md) — the literature's rules, measured and decided.
[reports/](reports/) — the full technical report suite (start at its [index](reports/README.md) for the map and reading paths) · [PROJECT_OVERVIEW](documentation/PROJECT_OVERVIEW.md) — the detailed findings narrative formerly on this page ·
[CLAIMS_DECIDED](documentation/CLAIMS_DECIDED.md) — the empirical scorecard (what's refuted, corrected, forced, confirmed) · [SOLVE_SUMMARY](documentation/SOLVE_SUMMARY.md) — plain-language results · [CITATIONS](documentation/CITATIONS.md) — every source, every attribution, annotated bibliography · [HISTORY](documentation/HISTORY.md) — the project narrative including its mistakes. · [CORRECTIONS](documentation/CORRECTIONS.md) — the append-only record of every claim we published and later changed.

## References

> **All scholarly attribution lives in [CITATIONS.md](documentation/CITATIONS.md)** and is deliberately
> not duplicated here — classical sources (Yu Fan, Kong Yingda, Zhu Yuansheng, Lai Zhide), the modern
> structural literature (Schulz, Moore, Cook, Hacker, McKenna & Mair, Davis, Drasny), the
> Chinese/Japanese hexagram-algebra prior-art cluster (Ouyang Weicheng, Zhang Qingyu, Suenaga, Luo
> Jianjin), the 2026 arXiv treatments
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
* [Yijing Dao (biroco.com)](https://www.biroco.com/yijing/) — S. J. Marshall's (Joel Biroco) archive of Yijing structural-analysis literature, host of the Moore and Schulz papers (a different person from Steve Moore — see CITATIONS.md; source of several documents examined there)
* [Terence McKenna: Novelty theory and Timewave Zero](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero) — Wikipedia (see [MCKENNA.md](documentation/MCKENNA.md); full citation in CITATIONS.md)

## Built with
[Claude Code](https://claude.ai/code) (Anthropic) — see AI-assistance headers in each source file.
