# ROAE — Received Order Analysis Engine

<mark>**[䷀䷁](documentation/SOLVE_SUMMARY.md)**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Corrections to anything on this page are recorded in [CORRECTIONS.md](documentation/CORRECTIONS.md).

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
(copied before 168 BCE) attests a *different* ordering in circulation. Earlier manuscripts exist —
the Shanghai Museum Chu bamboo *Zhouyi* is c. 300 BCE — but their hexagram *order* is not
recoverable. **The full dated record, and which other orderings this project does not study and why,
are in [KING_WEN_PROVENANCE.md](documentation/KING_WEN_PROVENANCE.md).**)

**The finding.** The seven rules we tested do not. This project began from the hypothesis that the
King Wen sequence is *determined* by its published constraints — that the received order could be
**derived** from them. We formalised seven such rules (**C1–C7**), enumerated, and measured, and
**the hypothesis is false**: an estimated 5×10³¹ — fifty nonillion — other orderings satisfy those
same seven. Whatever fixed the received order, these seven rules alone did not. That is a claim
about the rules we tested, not about every rule that could exist — rules nobody has written down
remain entirely possible.

**What this does — and does not — mean.** Three scope notes worth carrying from the start:

- **It does not say the sequence is random, or that nobody designed it.** The test is of the
  literature's rules *as stated*. An arranger may have followed considerations nobody wrote down;
  this project measures only what the stated rules force.
- **Who defined the seven rules is mixed — and that matters.** Two are classical: the pair
  structure (implicit in the early commentaries, stated explicitly by Kong Yingda in the 7th
  century) and the Qian–Kun opening (in the received text itself). One comes from the modern
  literature: the ban on 5-line transitions, first claimed by McKenna & McKenna (1975) and found
  independently by Cook (2006). **The remaining four this project formalised itself — and several
  encode King Wen's own values rather than an independent principle.** The complement-distance
  ceiling is King Wen's own figure, read off the sequence and used as the threshold; the two
  adjacency constraints are its own adjacencies. Rules of that kind describe the target rather than
  predict it, and they are priced as description — not as explanation — everywhere in this
  repository ([METHODS](reports/METHODS.md) §"Data-like vs principled constraints").
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
counting finds **16,504** *oriented* C1–C5 completions of which exactly **8** satisfy C6–C7 — and
**all eight carry King Wen's own pair ordering**, the other seven being orientation variants of it
([TR-4](reports/TR4_SIZE_OF_THE_SPACE.md) §4). So the exact corroboration is at the **oriented**
level — the level the full-space estimate above also counts. Read as *pair orderings*, this one slice
runs the other way: C6–C7 leave King Wen's alone among the 899 distinct pair orderings that those
16,504 oriented leaves represent. King Wen is
unique only within **budgeted enumerated slices**, never in the full space. Read against the
literature, this is **a measured confirmation of prior under-determination claims, and the magnitude
is a single-instrument estimate**: the direction was asserted qualitatively before this project
measured it (see the prior negatives below), and the C1–C7 figure comes from `solve.c`'s estimator
alone — every two-instrument exact quantity in the suite is C3-free
([TR-11](reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)). Neither label doubts the number:
the estimator is externally validated at both full-scale layers where exact ground truth exists,
inside its stated envelope both times ([TR-4](reports/TR4_SIZE_OF_THE_SPACE.md) §"Estimator
calibration"), and the C6–C7 verdict is corroborated exactly at small scope (the 8 oriented
survivors of 16,504 above). What no prior author did is the measurement **at combinatorial scale, over
constraint-defined spaces** — exhaustive searches over small curated families of candidate
orders do exist in the literature, and are not what this sentence excludes.

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
2026-08-04 and passed, together with `python3 tests.py` (64 tests at that date; 76 as of 2026-08-28) and `lean lean/KingWen.lean`
(silent, i.e. all theorems check). Run from the repo root, that command uses elan's *default* toolchain rather than
`lean/lean-toolchain`, so the record attests a kernel check under the host's default Lean of that day, not
specifically the pinned 4.31.0. `cd lean && lean KingWen.lean` checks under the pinned toolchain, and `verify_all.sh` §4 runs
from `lean/` and prints the kernel it used as `LEAN_ID=`. Before 2026-08-04 the recipe had never actually been run, which is itself
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
- **C4** — the sequence starts with the pair ䷀ Qian #1 and ䷁ Kun #2, i.e., Heaven followed by Earth.
- **C5** — the multiset of adjacent-transition sizes matches King Wen's exactly.
- **C6** — a specific pair-adjacency in the second half: the pair at positions 53–54 is immediately
  followed by the pair at 55–56.
- **C7** — the same kind of pin one boundary earlier: the pair at positions 49–50 is immediately
  followed by the pair at 51–52.

C1–C2 are robust properties, stated in the literature independently of any one ordering. C3 and C5 are
extracted from the sequence itself — C3's ceiling is King Wen's own value, C5's multiset is King Wen's
own multiset; C4's opening pair is classically attested, not extracted. C6–C7 go furthest still:
they name the specific hexagrams King Wen puts at those slots
([exact values](documentation/SPECIFICATION.md)), so they describe the received order rather than
explain it. That distinction is the difference between a result and a restatement, and it is policed
throughout ([CRITIQUE.md](documentation/CRITIQUE.md)) — which is why headline counts are reported over
C1–C5, with C6–C7 added only where the text says so.

## The instruments

| Tool | Role |
|---|---|
| **[solve.c](solve.c)** | The enumerator. Multi-threaded C; produces byte-reproducible enumeration slices anchored by sha256 ([CANONICAL_HASHES](documentation/CANONICAL_HASHES.md)); also an unbiased estimator of the full space. Deepest artifact: 10.5 billion orderings, derived twice byte-identically on preemptible cloud. |
| **[solve.py](solve.py)** | The independent ground truth. Every constraint implemented a second time, in Python, and cross-checked against the C. |
| **[sat.py](sat.py)** | The decision layer. Encodes exact questions ("does an ordering with property X exist?") for a SAT solver; UNSAT answers carry independently checkable certificates. |
| **[roae.py](roae.py)** | The exploratory analysis suite: 28 analyses of the sequence — most with null-model comparisons, several descriptive-only, and [CRITIQUE.md](documentation/CRITIQUE.md) names which are which ([example output](example/)). |
| **[lean/](lean/)** | Machine-checked theorems (Lean 4): the core lemmas, four sequence-level theorems, the trigram-level structure ([TRIGRAM_STRUCTURE](documentation/TRIGRAM_STRUCTURE.md)), and the model-level merge/partition-invariance theorems (see [lean/README.md](lean/README.md) for the trust-base and scope notes). |
| **[tests.py](tests.py)** · **[verify.py](verify.py)** · **[verify_all.sh](reports/certificates/verify_all.sh)** | The verification layer — the instrument that checks the other five: Python regression harness, two-language record verifier, and the one-command check of the enumerator selftest, the two-language gates, every archived DRAT certificate, the Lean proofs, the regression harness, `roae.py`'s ground-truth self-check and the documentation gates (`scripts/doc_gates.sh` in its `all` mode, whose PASS banner covers the hard gates only). Scope: section 6 runs `roae.py --verify` — the deterministic ground-truth check — and **not** the 28 analyses. |

## What was found

Headlines only — each links to its full treatment (technical reports in [reports/](reports/)):

- **The constraints do not determine the sequence.** The C1–C5 space is **estimated** at 1.33×10³⁸ orderings — a raw, orientation-explicit count ([METHODS](reports/METHODS.md) §"Canonical quantities") — (Knuth random-probe, 95% CI [1.3283, 1.3292]×10³⁸ — a statistical estimate, not a proven cardinality); adding
  C6–C7 still leaves ~5×10³¹. So the hypothesis that the constraints pin down King Wen is false — that
  was the strong reading of the literature's derivation claims, and this project's own early working
  assumption ([attribution note](documentation/CITATIONS.md#uniqueness-conjecture)). [TR-4](reports/TR4_SIZE_OF_THE_SPACE.md)
- **The literature's rules conflict.** The four strongest rules asserted across eight centuries are
  jointly unsatisfiable — no C1∩C2∩C4∩C5-valid ordering can be perfect under all four. King Wen keeps one exactly and misses the others by two each, so its famous anomalies
  are **consistent with** a forced trade-off. What the incompatibility establishes is narrower than it
  may read: it **rules out one explanation** — damage to an original that was perfect under all four —
  because **no such original could exist.** (A *three*-rule-perfect precursor does exist; whether the anomalies are an
  arranger's trade-off or damage to that precursor is weighed, not settled, in TR-2's model
  comparison.) A 47-year-old proposal to replace the sequence is re-examined along the way: its premise is
  measured, and a *fully smooth* variant is proven impossible. The hybrid ordering its authors actually
  published is feasible, and nothing here refutes it. [TR-1](reports/TR1_EIGHT_CENTURIES_MEASURED.md), [TR-2](reports/TR2_THE_RULES_CONFLICT.md), [TR-8](reports/TR8_REORDERING_REVISITED.md)
- **Eight rules asserted as design are proven forced.** Each is a theorem, machine-checked in Lean 4
  ([lean/C1RuleConstants.lean](lean/C1RuleConstants.lean)): constant on the entire C1 space — a superset
  of the measured population, so every valid ordering inherits King Wen's value. They are consequences
  of the constraint system, not choices; the zero-violation 2×10¹⁰-probe measurements now serve as
  instrument validation. *(Scope: Lean proves constancy of the `countP` forms defined in that file.
  Identifying those forms with the registry rules as implemented — `reg_*` in solve.py,
  `score_registry` in solve.c — is a **non-Lean transcription step**. A check that drove the repo's own
  `reg_*` over 5,449 structured C1 sequences with zero deviations is **attested, not reproducible**: it
  was run from a scratchpad script that is not in the repo. It is disclosed in the Lean file's header and
  in [lean/README.md](lean/README.md). So the eight are Lean-proven **modulo a transcription step whose
  numerical check is a shipped command** — a bridge carried outside Lean, like those disclosed for
  PartitionInvariance and PruneExactness; the 2026-07-21 check itself stays unarchived. Its re-derivation is now tracked:
  `python3 solve.py --c1-constants-check` drives the same design over 5,455 C1 orderings with 0 deviations, a non-C1 control and a cross-pair r4 mutant *(updated 2026-10-02, Q-944: this read "whose only numerical check is attested" and "Re-deriving it as a tracked artifact is an open item")*.)* (A separate analytic theorem — the no-5 rule's implication chain, behind
  McKenna's 3:1 ratio — stands in addition.) Other asserted rules are extremely rare as stated, down to
  ~1 in 5×10⁷ — an order-of-magnitude figure at that sampling depth, with the most specific
  configurations rare largely by specification rather than principle; see METHODS and TR-1's data-like
  caveat. [TR-1](reports/TR1_EIGHT_CENTURIES_MEASURED.md)
- **Every valid ordering has exactly 23 record-level indistinguishable twins** (the symmetry group acts
  freely), and exactly **15 parity-class alternations** (proven two independent ways — the
  prose argument and the Lean 4 kernel — with a SAT/DRAT corroboration that mechanizes the counting
  step under the alternation–distance bridge). [TR-5](reports/TR5_SYMMETRY.md), [TR-6](reports/TR6_PARITY_SKELETON.md)
- **No symmetry-respecting generator can single out King Wen.** Any generator that scores orderings
  using only G-invariant structural primitives (Hamming distance, complement, reversal, the values 0/63,
  …) gives King Wen's record and each of its 23 twins equal probability — so it can place at most **1 in
  24** of its mass on King Wen, never more (`equivariance_ceiling`, kernel-checked in
  [lean/KingWen.lean](lean/KingWen.lean)). The bound is Curie's principle (symmetry of causes ⇒ symmetry of
  effects), not new — the contribution is the King-Wen instantiation and its machine-check. [lean/README §The equivariance ceiling](lean/README.md), [lean/KingWen.lean](lean/KingWen.lean)
- **McKenna's "ninth six" is forced.** The 1975 observation that exactly one **between-pair** transition flips
  all six lines holds in **every** valid ordering — machine-proven: the between-pair transition budget
  is a theorem of the constraints, so the 10.5-billion-record measurement becomes a corollary. (The
  *position* of that transition remains ordering-dependent.) [TRIGRAM_STRUCTURE](documentation/TRIGRAM_STRUCTURE.md)
- **The pairing is optimal among comp/rev matchings.** The classical pair structure is the unique Hamming-cost-minimizing
  complement/reversal (comp/rev) matching ([Radisic 2026](documentation/CITATIONS.md#radisic2026) —
  preprint, machine-verified). Scope guard: comp∘rev matchings can do better — see
  [lean/HammingOptimalMatching.lean](lean/HammingOptimalMatching.lean). [CITATIONS](documentation/CITATIONS.md)
- **The circular reading has a price.** Read as a cycle (McKenna's construction), the sequence needs
  one more rule. Orderings violating that rule are 17.4% of the full space yet absent from all 10.5
  billion enumerated records — a stark demonstration that bounded search sees a biased sample. (The
  17.4% is a 2×10¹⁰-probe sampled estimate, which a second archived run matches to within 0.05 percentage
  points. That run is a partially overlapping replicate that shares half its probes, not an independent
  draw — TR-7 §5.) [TR-7](reports/TR7_CIRCULAR_READING.md)
- **In bits, half the sequence's description length is accounted for by known structure; half is not.**
  *("Accounted for", not "explained": which layers are **granted** explanatory standing is a choice made
  below.)* The classical pairing carries
  nearly all the explanatory weight (and is provably optimal among comp/rev matchings); the transition histogram is confirmed
  description, not explanation; **between about 105 and 139 bits** remain open — the exact figure
  depends on which layers are granted explanatory standing (105.4 bits = log₂|C1–C7|, the most
  conservative reading, resting on the C1–C7 estimate — whose published 0.78% is the estimator's
  relative **standard error**, not a 95% half-width, so the 95% interval is ±1.96·SE ≈ **±0.022
  bits**, which the published [5.13, 5.29]×10³¹ bracket independently gives as −0.0223/+0.0220; 139.1 bits =
  log₂|C1∩C2∩C4|, the residual against the claimed-explanatory layers alone — a logarithm of an
  exact count; the intermediate C1–C5 reading ~126.6 rests on an estimate with a smaller relative
  standard error, 0.02%, i.e. ±1.96·SE ≈ ±0.0006 bits at 95% — a tighter *estimate*, which is a
  comparison of two standard errors and not of two published precision bands).
  [TR-9](reports/TR9_PRICING_THE_CONSTRAINTS.md)
- **A structural reading, measured.** [Davis's (2012)](documentation/CITATIONS.md#davis2012) flagship compositional units come out
  typical-to-mildly-uncommon (TR-10's own phrase; the #43–50 array is its lone Bonferroni-notable
  exception); one uniqueness claim is corrected; the ~126-bit (C1–C5-layer) residual survives its second
  literature-guided attack. [TR-10](reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)
- **Exact counts at full scale.** |C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688
  (≈1.097×10³⁹; counting orientation-explicit sequences with C4's pair pinned —
  [METHODS](reports/METHODS.md) §"Canonical quantities") — computed to the last digit by a dynamic program that keeps one
  representative per orbit of the symmetry group on *partial* states ([TR-11](reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md);
  the group's invariance of C1–C5 is what makes the DP fit in memory). The integer is divisible by 24, and by 48, as the
  free action of that group on *complete* sequences requires ([TR-5](reports/TR5_SYMMETRY.md) §4). The divisibility is not
  a restatement of the method: the DP computes each partial state's stabiliser and never assumes the free action, so a wrong
  integer would pass the check one time in 48 — a necessary-condition gate, not a confirmation. The confirmation is the
  independent recount below. (Until 2026-10-02 this sentence offered "divisible by 24 exactly as that theorem predicts" as if it
  confirmed the theorem the count was computed with; the engine reading above replaces it.) (It is the suite's second exact full-scale count; the first,
  |C1∩C2∩C4| ≈ 7.5706×10⁴¹, landed 2026-07-04.) The count was **recomputed at full scale** (2026-07-25)
  by a second instrument — `verify.c`'s inclusion–exclusion transfer-walk engine (`--ie-count`), a
  different algorithm class sharing no code with `solve.c` (the one shared mathematical premise is orbit–stabiliser weighting under the same 24-element group, as `verify.c`'s own header states) — and the two integers **match
  exactly**, with the free-action divisibility gate holding (mod 24 in the 2026-07-25 run; both instruments gate mod 48 since 2026-10-02, the strength TR-5 §4 states)
  ([TR-11](reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §10(vi); the verifiers are
  [verify.py/verify.c](documentation/VERIFY.md)). The honest residual: both instruments are
  project-authored and share the group-theory/constraint specification, so the independence is
  algorithmic, not specificational — no third party has recomputed the count. It is reproducible on
  ~64 GB of RAM plus ~4 TB of disk; the statistical estimator is validated absolutely at 10³⁹ (the
  exact value lands inside its stated ±0.01% envelope). The flagship C1–C5 figure remains an
  estimate. [TR-11](reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)
- **The enumeration record is reproducible**: every canonical count re-derivable to the byte from its
  published recipe — the sha-determining parameters verbatim; one `solve` invocation with the merge
  bundled through 100T, and enumerate-then-`--merge` as two steps for the 560T canonical
  ([CANONICAL_HASHES](documentation/CANONICAL_HASHES.md) §"Reproducibility parameters"; TR-3
  §"Verification Guide"); the deepest run reproduced from scratch through seven fresh Spot evictions (twelve across
  both runs). Three legacy figures are attested-not-reproducible and say so where they appear: the
  5,449-sequence check above, TR-1's ~1-in-25-million, and the
  [f11halfb](reports/evidence/f11halfb/RESULTS.md) bundle. [TR-3](reports/TR3_REPRODUCIBLE_ENUMERATION.md)

**Honesty apparatus.** Every caveat lives in [CRITIQUE.md](documentation/CRITIQUE.md) — read it before
quoting anything above. It covers the constraint-extraction circularity, the null-model studies, the
look-elsewhere accounting, and the corrected published results (the scorecard is
[CLAIMS_DECIDED.md](documentation/CLAIMS_DECIDED.md); the full never-silent corrections ledger — including a
retracted theorem — is [CORRECTIONS.md](documentation/CORRECTIONS.md)). It also reports the corpus-control test:
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
python3 roae.py                          # the analysis battery (29 sections; 28 analyses, most with null models — see CRITIQUE.md — plus the theorem-backed --parity)
python3 solve.py --registry-verify       # the two-language ground-truth gates (31/31 must PASS)
python3 sat.py                           # SAT layer usage + targets
python3 tests.py                         # regression harness (133 tests as of 2026-09-02)
bash reports/certificates/verify_all.sh  # one command: selftest, two-language gates, all DRAT certs, Lean, tests.py, roae.py --verify, doc gates
```
`verify_all.sh` needs five external tools — **gcc**, **python3**, **drat-trim**, **lean** (elan) and
**git** (section 7 only: the documentation gates enumerate the corpus with `git ls-files`, so an
exported tarball with no work tree cannot run them).
It probes for each up front and reports any dependent check as **SKIP**, not FAIL: a SKIP means the
tool is absent, never that a certificate failed to verify. SKIPs do not pass the run — the exit
status distinguishes them — so a machine without drat-trim and Lean gives a partial, honestly-labelled
result rather than a wall of failures.
Full CLI references: [SOLVE_C_CLI](documentation/SOLVE_C_CLI.md) · [ROAE_PY_CLI](documentation/ROAE_PY_CLI.md).

## Going deeper
**If you read one thing**: [TR-1](reports/TR1_EIGHT_CENTURIES_MEASURED.md) — the literature's rules, measured and decided.
[reports/](reports/) — the full technical report suite (start at its [index](reports/README.md) for the map and reading paths) · [PROJECT_OVERVIEW](documentation/PROJECT_OVERVIEW.md) — the detailed findings narrative formerly on this page ·
[CLAIMS_DECIDED](documentation/CLAIMS_DECIDED.md) — the empirical scorecard (what's refuted, corrected, forced, confirmed) · [SOLVE_SUMMARY](documentation/SOLVE_SUMMARY.md) — plain-language results · [CITATIONS](documentation/CITATIONS.md) — every source, every attribution, annotated bibliography · [HISTORY](documentation/HISTORY.md) — the project narrative including its mistakes. · [CORRECTIONS](documentation/CORRECTIONS.md) — the append-only record of every claim we published and later changed.

### Which branch to read — `main`, and only `main`

**`main` is the published corpus.** Corrections land here and nowhere else: when a claim is
withdrawn or restated, [CORRECTIONS.md](documentation/CORRECTIONS.md) records it and the affected
text on `main` is updated.

**The other published branches are frozen working snapshots, and they are not publications.** Each
stops at the commit where that line of work paused, so a branch **can still contain claims this
project has since corrected** — including figures later found to be wrong. They predate
`CORRECTIONS.md` itself, so a branch offers no way to discover what changed. They are kept public
for provenance, not for reading: cite `main`.

Every published branch, with its status and freeze date, is declared in
[BRANCH_REGISTRY.tsv](documentation/BRANCH_REGISTRY.tsv). `doc_gates.sh branch-registry` (GATE 19)
fails if a branch is published without being declared there — a hole this suite could not previously
see, because every other gate reads the working tree and none reads another branch's content.

## Figures

The project's committed figures, each shown as PNG with its SVG source linked. The short caption under
each one is an excerpt; **the report section it links to carries the full caption and is the
authority.** All eleven figures shown below, and the TR-3 timeline linked at the end, are drawn by [`viz/report_figures.py`](viz/report_figures.py). The complete
index, including the enumeration-slice plots (growth curve, PCA projections, campaign telemetry), is
[viz/README.md](viz/README.md).

### The compiled superspace: TR-12's five figures (V1–V5)

Drawn from the n=31 outputs TR-12 cites: V1, V2 and V5 from the n=31 atlas, V4 from King Wen's
profile, V3 from the rank grid. Space label **C1C2C4C5-SUPERSPACE**: C3 is **not** among the
constraints. V1, V2 and V5 are computed over the whole superspace; V4's line is **one walk** (King Wen's; its shaded bars are the attested range over the admissible alternatives),
and V3 is a 1000-point **lattice** on the index, not a sample of the space.

![Heat matrix of the exact positional-marginal field over the C1C2C4C5 superspace: 32 rows, one per pair j (King Wen hexagrams 2j+1 and 2j+2), against pair-slots s = 2 to 32, with King Wen's own 31 placements (pair j in slot j+1) outlined in cyan over a black under-stroke along the diagonal; a note beneath says the 31 free pairs share seven distinct rows, their symmetry orbits.](reports/figures/fig_tr12_kc_field.png)

**V1, the positional-marginal field.** **C1C2C4C5-SUPERSPACE; C3 not imposed.** P(pair j in slot s), exact over SUPER, where layer k fills slot s = k+2. The 31 free pairs share seven distinct rows by symmetry; pair 0 is pinned to slot 1. At interior slots 3–31, the distribution over the 31 non-pinned pairs is within 0.0329 total-variation distance of uniform.
King Wen's own interior placement probabilities range from 0.02985 to 0.03371. The outlined
diagonal follows from the pair labels.
[TR-12 §2](reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5) ·
[SVG](reports/figures/fig_tr12_kc_field.svg) · [spec](viz/viz_kc_field.md)

![Two-panel figure. Upper panel: a stepped stacked mass river of 31 unit-width layer bins, 0 to 30, showing the exact share of the superspace in each boundary-distance class d = 1, 2, 3, 4 and 6, each band labelled with its class, with King Wen's own class at each layer drawn as a black step line with a white halo; thin dark rules separate the bands, each labelled in dark text beside a swatch of its colour. Lower panel: a bar chart of the 56 top-level branches sorted by solution mass, each labelled pair : entry hexagram code, with log10 exhaustion cost in t-units overlaid as a red line. A key beneath defines d, how to read King Wen's line, the branch label and the t-unit (one valid oriented prefix).](reports/figures/fig_tr12_kc_river.png)

**V2, the mass river, and the branch panel.** **C1C2C4C5-SUPERSPACE; C3 not imposed.** Upper: exact per-layer mass by boundary-distance
class; only the shape across k carries information; it is nearly flat. Lower: each top-level
branch's exact solution mass against its exact exhaustion cost; no branch is small-but-expensive at
n=31. ⚠ This is the **REDUCED** form (`TR12_V2=PASS:REDUCED-NO-BRANCH-CLASS-RIVER`): the river is
split by distance class, not by top-level branch class. The EXHAUSTIBLE/INFEASIBLE verdict is not
drawn from this panel and remains withheld. This figure draws distance classes. A completed-solution river split by first branch would be flat across layers — each branch's band is its `solutions(b)` from the lower panel at every k — so it adds nothing. A joint split by first branch and current distance class is carried neither by the atlas nor by the f/g/t ladders: it would need a branch-tagged forward ladder, a new build of order 10² TB, which is not proposed.
[TR-12 §2](reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5) ·
[SVG](reports/figures/fig_tr12_kc_river.svg) · [spec](viz/viz_kc_river.md)

![Heat map of the exact transition grammar: fifteen rows, one per pair of boundary-distance class d = 1, 2, 3, 4, 6 and within-pair distance w = 2, 4, 6, against layers 0 to 30, each column summing to 1. King Wen's own (d, w) cell at each layer is marked by a white outline over a black under-stroke, one per column, and a note beneath says each column averages over the whole superspace.](reports/figures/fig_tr12_kc_grammar.png)

**V5, the transition grammar.** **C1C2C4C5-SUPERSPACE; C3 not imposed.** P(d, w | layer k), exact over SUPER, read down each column (layer k places the new pair in pair-slot k+2; each column averages over the whole superspace and is not conditioned on King Wen's preceding choices);
`TR12_V5` reads `PASS`. What V5 adds over V2 is the per-layer `P(w|k)` marginal, not a measured
dependence. The seven pair-orbits are grouped into three within-pair-distance categories; each row
fixes one (d,w) combination and does not identify an individual pair.
[TR-12 §2](reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5) ·
[SVG](reports/figures/fig_tr12_kc_grammar.svg) · [spec](viz/viz_kc_grammar.md)

![Two-panel figure of King Wen's own trajectory. Upper panel: log10 of g(prefix), the exact number of completions remaining after each of King Wen's 31 free placements, each step annotated with the number of admissible alternatives at that point, and a shaded bar at each step spanning the least to greatest g over all admissible alternatives there, King Wen's own included, labelled as attested from the 2026-09-22 n=31 battery receipts. Lower panel: the surprisal of King Wen's next choice, bars of minus log2 p_i in bits per step with p_i = g_i / g_(i−1), the bars summing to log2 N, and a short black tick at each step at log2 of its number of admissible alternatives.](reports/figures/fig_tr12_kc_shells.png)

**V4, King Wen's neighbourhood shells** — Q3's rarity profile drawn as a figure. **C1C2C4C5-SUPERSPACE; C3 not imposed.** The lower panel's `p_i = g_i / g_(i−1)`; a bar above its `log₂ a_i` tick is a choice with fewer completions than the average alternative. Unlike V1, V2 and
V5 this figure's line plots one walk, not a population: every point is King Wen's own. Its input was
produced by the full-31 run of 2026-09-22 and is committed as `reports/tr12/q3_profile_kw.tsv`. The shaded bars (least to greatest `g` over the admissible alternatives at each step) are read from that run's published receipt [`q3_profile_exact.tsv`](reports/evidence/tr12/banked_n31_20260922/q3_profile_exact.tsv): **attested**, not reproducible without the f/g ladders.
[TR-12 §2](reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5) ·
[SVG](reports/figures/fig_tr12_kc_shells.svg) · [spec](viz/viz_kc_shells.md)

![Seven scatter panels of observable values against normalised rank from 0 to 1 in REL order, evaluated on a 1,000-point systematic REL lattice, none showing a clear monotone trend across it. Three panels carry a dashed red King Wen reference line; four deliberately carry none because those observables measure similarity to King Wen. Each panel is titled with a plain-language label over its column name, and a reading key in the two empty cells defines every observable drawn.](reports/figures/fig_tr12_kc_spectrum.png)

**V3, the rank spectrum — and the reading is negative.** **C1C2C4C5-SUPERSPACE; C3 not imposed.** On this 1,000-point REL lattice, none of the seven plotted observables shows a clear monotone trend; all absolute Pearson correlations are below 0.073.
This does not exclude nonlinear structure or structure missed by the lattice. The standalone n=31 V3
rows passed on 2026-09-25 (`TR12_V3_FIG=PASS`); the archived 2026-09-22 full-run receipt retains its
original PENDING token (TR-12 §Open Problems, item 5).
[TR-12 §2](reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5) ·
[SVG](reports/figures/fig_tr12_kc_spectrum.svg) · [spec](viz/viz_kc_spectrum.md)

### Why a compiled space: the scale figure

![Log-log plot of count against per-cell node budget: three red points near the bottom for the 11.2T, 100T and 560T canonical record counts on a shallow blue power-law fit, and a purple horizontal line near the top marking N, the exact count of the C1C2C4C5 superspace. The vertical-axis label states that the points and the line count different spaces, and a three-line note beneath the plot states the units: points count canonical pair orderings with orientation masked; N counts orientation-explicit sequences in the C1C2C4C5 superspace, C3 not imposed. The plotted ratio is 29.0 decades; comparing pair orderings with pair orderings gives a gap of 19.7–23.9 decades.](reports/figures/viz_scale.png)

**The scale figure.** The two series count **different spaces**, and neither is a fraction of the
other: each point is a node-budgeted slice of C1–C5 whose record count is a lower bound, and the line
is the exact cardinality of the C1C2C4C5-SUPERSPACE. Points count canonical pair orderings with orientation masked; N counts orientation-explicit sequences. The plotted ratio is 29.0 decades; comparing pair orderings with pair orderings gives a gap of 19.7–23.9 decades.
If the power law fitted to these three runs continues, reaching even the like-unit bracket would require approximately 6.4×10³⁸–1.1×10⁴⁵ nodes per cell, making enumeration infeasible under that extrapolation.
[TR-12 §"What this document is, and what it is not"](reports/TR12_QUERY_PROGRAM.md#what-this-document-is-and-what-it-is-not) ·
[SVG](reports/figures/viz_scale.svg) · [spec](viz/viz_scale.md)

### Other report figures

![Four-row comparison table of the four conflicting rules, with a King Wen column and a precursor column: King Wen has 2 misses (16/18) on Moore's 2005 parity rule, 2 breaks of Moore's 1989 rhythm rule and 2 violations of Schulz's 1990 gender rule, and satisfies Schulz's trigram configuration of stations 25–28 exactly; the grand unified precursor, 3 slot-edits from King Wen, has 0 on the first three and violates the trigram configuration. A note defines a station as one of Lai Zhide's 36 consolidated units.](reports/figures/fig_tr1_rules_tradeoff.png)

**The conflict theorem's trade-off.** The jointly UNSAT result (drat-trim-verified) says no
C1∩C2∩C4∩C5-valid ordering can reach zero on all four axes at once.
[TR-1 §Figure](reports/TR1_EIGHT_CENTURIES_MEASURED.md#figure) ·
[SVG](reports/figures/fig_tr1_rules_tradeoff.svg)

![King Wen's 32-pair parity-class string: 32 colored squares (blue E = even popcount parity, orange O = odd), 16 of each class, with red marks at each of the exactly 15 class alternations across the 31 pair boundaries; the letters are white on blue and near-black on orange, and a dashed connector labelled 16→17: O→E carries the alternation at the end of the first row to the start of the second.](reports/figures/fig_tr6_parity_alternations.png)

**King Wen's parity-class string.** The red marks count exactly 15 alternations — the theorem's
forced value, which every C1–C5-valid ordering shares.
[TR-6 §Figure](reports/TR6_PARITY_SKELETON.md#figure) ·
[SVG](reports/figures/fig_tr6_parity_alternations.svg)

![64 nodes in King Wen order, arranged as a cycle. Thick red edges mark odd Hamming-distance transitions: 15 internally, plus the highlighted 64→1 wrap of distance 3, giving 16 around the cycle. One label gives King Wen's own wrap, d = 3 (3 of the 6 lines change); a separate line under the ring states the wrap-parity theorem, that the wrap distance is odd for every ordering satisfying C4 and C5.](reports/figures/fig_tr7_circular_cycle.png)

**The cycle.** The 64 hexagrams as a cycle in King Wen order; King Wen's highlighted wrap edge 64→1 jumps
d = 3, and the wrap-parity theorem makes the wrap odd for every ordering satisfying C4 and C5. The circular reading has 16 odd transitions where
the linear reading has 15: the wrap adds exactly one, always, for an ordering that satisfies C1–C5 as
written.
[TR-7 §Figure: the cycle](reports/TR7_CIRCULAR_READING.md#figure-the-cycle) ·
[SVG](reports/figures/fig_tr7_circular_cycle.svg)

![Diagram of B₃, order 48, quotienting by {±I} to a free S₄ action of order 24 on canonical pair-order records. A ring shows King Wen's record and 23 other records in its orbit. The quotient step explains that −I turns each hexagram upside down, mapping every pair onto itself, so it moves no record; the theorem step states R/24 for an S₄-closed set of R records.](reports/figures/fig_tr5_orbit_collapse.png)

**The symmetry collapse.** The order-48 group B₃ of C1–C5-preserving signed line-permutations
collapses to a faithful S₄ (order 24) on solution records. Every valid canonical pair-order record,
King Wen's included, has an orbit of 24 records, indistinguishable by any criterion invariant under S₄.
[TR-5 §Figure: the symmetry collapse](reports/TR5_SYMMETRY.md#figure-the-symmetry-collapse) ·
[SVG](reports/figures/fig_tr5_orbit_collapse.svg)

![Log-scale decay curve of S(k), the fraction of the full C1–C5 population agreeing with King Wen on its first k identifying boundaries: four estimated points (pinned Knuth, ≤10%), a dashed early-rate illustration from k = 1–4 that ends at k = 8 and is labelled as superseded by the later measured decline, an orange illustrative bracket, a green dash-dot line marking the reachable floor of one surviving pair-ordering class, a grey dotted line below it marking one oriented ordering that pair-level pins never reach, and a green vertical line at k = 14 marking the earliest the floor is reached if no later boundary gains more than the eighth measured one's 6.14 bits.](reports/figures/fig_tr4_boundary_information.png)

**The boundary-information curve S(k).** Red points are estimated (pinned Knuth, ≤10%). The blue dashed segment illustrates the rate inferred from k=1–4 only and ends at k = 8; it is NOT measured,
and the orange band is **illustrative** and not reproducible from published
material. The boundaries pin pair identity only, so the floor is one surviving pair-ordering class, never a unique ordering; the green line at k = 14 is the earliest
that floor is reached if no later boundary gains more than the eighth measured one's 6.14 bits — a scale marker, not a bound. The k=14 marker uses the reported eight-step total and assumes that no subsequent gain exceeds 6.14 bits; it is an earliest possible count under that assumption, with no unconditional bound asserted.
[TR-4 §Figure](reports/TR4_SIZE_OF_THE_SPACE.md#figure) ·
[SVG](reports/figures/fig_tr4_boundary_information.svg)

The first 560T campaign's timeline is in [TR-3 §Figure](reports/TR3_REPRODUCIBLE_ENUMERATION.md#figure)
([SVG](reports/figures/fig_tr3_campaign_timeline.svg)).

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
* [The I Ching or Book of Changes](https://press.princeton.edu/books/hardcover/9780691097503/the-i-ching-or-book-of-changes) — Richard Wilhelm, trans. Cary F. Baynes, Princeton University Press (the standard English translation; its hexagram names are not used here — labels are trigram-derived; see [CRITIQUE](documentation/CRITIQUE.md))
* Edward L. Shaughnessy, *I Ching: The Classic of Changes*, Ballantine Books, 1996 (translation of the Mawangdui manuscript); the project's Mawangdui ordering array follows Shaughnessy, *The Origin and Early Development of the Zhou Changes*, Brill, 2022, Table 11.2
* [Yijing Dao (biroco.com)](https://www.biroco.com/yijing/) — S. J. Marshall's (Joel Biroco) archive of Yijing structural-analysis literature, host of the Moore and Schulz papers (a different person from Steve Moore — see CITATIONS.md; source of several documents examined there)
* [Terence McKenna: Novelty theory and Timewave Zero](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero) — Wikipedia (see [MCKENNA.md](documentation/MCKENNA.md); full citation in CITATIONS.md)

## Built with
[Claude Code](https://claude.ai/code) (Anthropic) — see AI-assistance headers in each source file.
