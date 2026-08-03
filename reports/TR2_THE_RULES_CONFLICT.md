# TR-2 — The Rules Conflict: Moore's Precursor, Schulz's Exceptions, and a Joint Impossibility Theorem for the King Wen Sequence
*Technical report — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. One caveat is structural, and it frames all the rest: the same
author wrote the claims, the software that checks them, and this report that grades the check.
Verification here is independent in mechanism, never in authorship; no independent party has yet
audited or reproduced any of it (METHODS.md §"Authorship independence").*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

The King Wen sequence has famous "irregularities" — places where its otherwise elegant patterns break.
For centuries these were read as mistakes, corruption, or lost meaning. This report proves a different
explanation: the four strongest design rules proposed for the sequence (two by Steve Moore, two
traceable through Larry Schulz to a 13th-century commentator) are **mutually contradictory — no
C1∩C2∩C4∩C5-valid arrangement (the pairing-preserving space with the base constraints the encoding
fixes; §2) can satisfy all of them**, a fact established by an exhaustive logic
search with an independently checkable certificate. King Wen keeps one rule perfectly and misses the
others by the smallest measured margins (2 each). Its irregularities are the visible seam of a forced trade-off,
not damage to a once-perfect-under-all-four original — none could exist. **How far that may be read is
calibrated in §5:** all four rules are KW-derived, so King Wen sitting near their joint Pareto frontier is
*expected* rather than an efficiency result, and UNSAT means every C1∩C2∩C4∩C5-valid ordering sits at some
such forced choice — the KW-specific residue is the measured margin of 2 and exact satisfaction of the
one rule this report itself calls the most data-like of the four. **These two framings — "not damage" here and the corruption Bayes factor below — are not in
tension: the impossibility theorem rules out an original perfect under all *four* rules, while the
Bayesian comparison concerns only the *three graded* rules, whose joint perfection is achievable.** A
corollary: an "uncorrupted original" perfect under the full four-rule inventory never existed — though
this does not touch Moore's narrower conjecture, whose rule-compliant precursor (§3) does exist and sits
three edits away.
New in v1.7: within the three graded rules — where perfection **is** achievable — a pre-registered
Bayesian comparison finds the received order far better explained as a corrupted rule-perfect ordering
than as the work of an arranger holding the rules as soft preferences (Bayes factor ≈ 6.6×10³–7.9×10³,
"strong" on the Jeffreys scale); a two-model comparison conditioned on the literature's rules, not proof
of corruption in any absolute sense. A wider four-class comparison (adding a greedy-builder and a
global-design class plus a uniform-valid null) has since been pre-registered under the same discipline;
its calibration **has since run and the verdict was VETOED** (v1.14, 2026-07-20): the frozen design placed a
synthetic-draw confusability gate before any verdict, that gate failed, and §6.3 accordingly forbids
publishing any four-class Bayes factor, posterior or verdict — here or elsewhere. No result is stated in
this report and none will be. Because that comparison is permanently withheld rather than merely
outstanding, the Bayes factor above excludes only the soft-preference arranger: it does not exclude a
greedy/local builder, nor the possibility that the three rules are post-hoc regularities of an otherwise
unremarkable ordering. *(Corrected 2026-08-01: this paragraph still said "measurement is pending" twelve
days after the veto landed in the same report.)*
**Update (v1.12, 2026-07-13): the pre-registered N_gs stop-flag fired, was investigated, and is
RESOLVED — the verdict is re-affirmed on a stronger, directly-measured footing with a slightly smaller
headline (BF ≈ 5.2×10³–6.3×10³, still an order of magnitude above the "strong" band in all 24
pre-committed configurations, and conditional on the three graded rules).** The full derivation — why
the derived "bracket" was never a confidence interval, the four-seed re-measurement to
N_gs = 4.50×10²⁵ (±6%), and the three convergence gates — is in the stop-flag resolution within the
Bayesian section.

Verification model: every load-bearing claim is an artifact check (witness verification or UNSAT certificate).

---

## Abstract

Steve Moore ([1989](../documentation/CITATIONS.md#moore1989), [2005](../documentation/CITATIONS.md#moore2005)) proposed two design rules for the King Wen sequence, observed that the received
order complies with one at sixteen of eighteen testable positions with both exceptions adjacent, and
conjectured an originally compliant order later altered. Larry Schulz ([1990](../documentation/CITATIONS.md#schulz1990-motifs), [2011](../documentation/CITATIONS.md#schulz2011), [2016](../documentation/CITATIONS.md#schulz2016)) independently
formalized a third rule over [Lai Zhide's](../documentation/CITATIONS.md#laizhide) thirty-six consolidated units, with its own exceptions at the
same locus — noted as early as the thirteenth century by Zhu Yuansheng — and a fourth, the trigram
configuration of stations 25–28, which the received order satisfies exactly. Using a Boolean-satisfiability
encoding of these rules over the space of orderings preserving the sequence's classical pair structure, we
resolve the conjectures these authors raised. (1) Moore's conjectured compliant order exists: we exhibit
an ordering perfect under both of his rules, differing from the received order by exactly three
adjacent-position edits — through the very anomaly he identified — and prove three edits is minimal.
(2) The same holds with Schulz's third rule added. (3) Decisively: **no C1∩C2∩C4∩C5-valid ordering satisfies all
four rules simultaneously** — the rules are jointly unsatisfiable, a fact certified by machine-checkable
proof. The exceptions that Zhu Yuansheng, Moore, and Schulz each recorded are therefore not evidence of
damage to an original perfect under the full four-rule inventory, for no such original could exist —
damage relative to the three-graded-rule precursor (which does exist) is a separate question, weighed in
the Bayesian section; they are the visible seam of a forced
trade-off among competing regularities — precisely the reading Schulz proposed on interpretive grounds in
2011 ("exceptions that prove rules"), for which we supply the exact combinatorial content.

## Structure — section summaries (6)

**Note on this report's form (F-8; bodies added 2026-07-20):** the numbered list below is the
overview; **§2, §3 and §4 — the method and the two theorems — are written out in full beneath it.**
Items 1, 5 and 6 deliberately remain summaries: §1 is the attribution narrative and §5 the interpretive
reading, both in a humanities register where every added sentence is a further claim about what a named
scholar said. This suite has already shipped one misattribution, and the constraint results below do not
depend on that prose. Their sources are given in full in [CITATIONS.md](../documentation/CITATIONS.md).
The report's other fully-written material is the v1.6 two-rule cores extension, the v1.7 Bayesian
comparison with its v1.12 stop-flag resolution, and the v1.14 four-class veto.
1. **The rules and their authors** (fully attributed narrative: Zhu Yuansheng -> Lai Zhide -> Schulz ->
   Moore; the anomaly locus as an eight-century observation). Humanities register. **Precision (per the
   2026-07-08 first-hand "Structural Motifs" audit): make the Schulz year-split explicit — the *gender
   rule* is Schulz 1990; the *S25–28 dui-trigram configuration* (CC-N4) and *exception co-location*
   (CC-N8) are Schulz 2011/2016. The four conflicting rules span three Schulz publications; the 1990
   paper is internally consistent (its three motifs are compatible tendencies), so the reader must not
   infer the conflict lives inside any single paper.**
2. **Method in one page**: the pair-structure space; what a SAT solver decides; what a certificate is;
   the two-way encoding validation (KW-forced tests) in plain language. Verifiability box.
3. **Moore's precursor exists** (witness, printed in full; 3-edit minimality with certificate).
4. **The conflict theorem** (statement, certificate, what was checked by whom: kissat -> DRAT ->
   drat-trim). One paragraph on the data-like character of the trigram rule, honestly.
5. **Reading the received order** — trade-off, not corruption; Schulz's 2011 principle vindicated in
   exact form; what remains open (restricted corruption; tendencies), WITHOUT statistics beyond one
   rarity sentence per rule (cited to the population-measurement record, not developed).
6. **Coda**: the sequence emerges more, not less, coherent: it sits where its own tradition's rules
   force a choice, keeping exactly one perfectly — read with §5's baseline calibration, since *every*
   valid ordering sits at such a choice point and the rules are KW-derived.

### 2. Method in one page

The search space is not "all orderings of 64 hexagrams". It is the space of orderings that preserve the
sequence's **classical pair structure** — the 32 traditional pairs, each placed as a unit in one of two
orientations. That restriction is not an analytic convenience adopted to make the problem tractable; it
is the structure every author in this literature already assumes, and abandoning it would test a claim
none of them made. Within it, an ordering is a placement of 32 pair-units, which is what the encoding
below quantifies over. One further scope fact the reader needs (made explicit 2026-07-30): the CNF
base shared by every target in this report additionally fixes **C2** (no distance-5 boundary), **C4**
(the fixed opening pair), and King Wen's **C5** transition multiset — so every UNSAT verdict below is
a statement over the **C1∩C2∩C4∩C5-valid space**, not over all pairing-preserving (C1-only)
orderings.

**What a SAT solver decides.** Each rule is expressed as constraints over Boolean variables that encode
which pair sits at which position in which orientation. The solver answers exactly one question: does
*any* assignment satisfy all the constraints simultaneously? A "yes" comes with a **witness** — an
explicit ordering you can print and check by hand. A "no" is the stronger and more interesting answer:
it asserts that no ordering exists anywhere in the space, which is a claim about roughly **1.097×10³⁹** candidate
objects that no enumeration could establish. *(Corrected 2026-08-01 from 10³⁸ — that is the C1–C5,
C3-included figure, but §2 fixes this report's base as C1∩C2∩C4∩C5, whose size
[METHODS.md](METHODS.md) gives EXACTLY as 1,097,051,278,789,181,790,036,112,071,176,579,186,688.
Quoting the C3-included number here contradicted the very scope the v1.18 correction established.)*

**What a certificate is, and why it matters here.** An unsatisfiability answer is only as trustworthy as
the solver that produced it, and modern SAT solvers are large, heavily optimised programs. So the solver
is required to emit a **DRAT proof**: a step-by-step derivation that an independent checker (`drat-trim`)
replays mechanically, printing `s VERIFIED`. The reader does not have to trust our solver, our encoding
pipeline, or us — they regenerate the formula with the documented command, run the standard checker on
the archived proof, and watch it verify. Every impossibility claim in this report ships that way; the
certificates are in [certificates/](certificates/) and `verify_all.sh` checks all of them in one command.

**Two-way encoding validation, in plain language.** The obvious failure mode is not a solver bug but a
translation error: encoding a *slightly different* rule than the author stated and then proving something
true about the wrong rule. Guarding against this requires testing the encoding in both directions against
the authors' own published numbers for King Wen. Concretely: `rc4-kwtest` → **UNSAT**, confirming the
encoded gender rule genuinely fails on King Wen at class positions 25/26, exactly where Schulz says it
does; `rc4-kwexempt` → **SAT**, confirming it succeeds once those two positions are exempted, so the
encoding is not simply unsatisfiable for some unrelated reason; and `ccn4-kwtest` → **SAT**, confirming
the encoded trigram configuration is satisfied by King Wen exactly, as reported. The encodings also
reproduce each author's stated tallies before anything else was trusted — 16 of 18 for Moore's parity
rule with both exceptions at 22–23, two rhythm breaks at (7,8) and (22,23), two gender violations at
25/26, and the trigram faces 31/24/26/29. Those are the authors' numbers, not ours, and an encoding that
failed to reproduce them would have been discarded rather than published. **These counts and their exact
positions are emitted by `python3 solve.py --r11-verify` (the `violation positions` line), so a reader
reproduces both the (2,2,2) vector and the pair-slot / inversion-class loci from the shipped code — no
re-instrumentation required.**

### 3. Moore's precursor exists — and three edits is minimal

Moore observed that King Wen complies with his rules at sixteen of eighteen testable positions, with both
exceptions adjacent, and conjectured that an originally compliant ordering had been altered. That
conjecture is decidable, and it is true.

**The witness.** `python3 sat.py --witness grand-strict` returns an explicit C1–C5-valid ordering that is
**perfect** on all three graded rules simultaneously: Moore's 2005 parity rule 18/18, Moore's 1989 rhythm
rule with 0 breaks, Schulz's 1990 gender rule with 0 violations, and complement-distance sum C3 = 776.
(`--witness moore-strict` gives the Moore-only precursor.) The sequences are published in
[LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md) §SAT-decided,
so a reader can check the rule tallies by hand rather than trusting the solver. This settles the
existence half of Moore's conjecture affirmatively: the ordering he hypothesised is not merely plausible,
it is exhibitable.

**The distance is exactly three.** The more informative result is *how far* that precursor sits from the
received order. Two SAT calls bracket it: `moore-strict-near-2` → **UNSAT**, so no jointly compliant
ordering exists within two slot-edits of King Wen; `moore-strict-near-3` → **SAT**, so three suffice.
Three adjacent-position edits, and they run through the very anomaly Moore identified. The UNSAT half is
the load-bearing one and carries its certificate (`moore-strict-near-2.drat.gz`); the SAT half is
self-evidencing, since it produces the ordering.

This is what the report means by making a historical conjecture exact. "The received order looks like a
slightly corrupted version of a rule-perfect original" becomes a measured quantity: minimum edit distance
three, established in both directions, machine-checkable in seconds.

### 4. The conflict theorem

The decisive result is negative, and it is the reason the rest of this report exists.

**Statement.** No C1∩C2∩C4∩C5-valid ordering satisfies all four rules simultaneously.
Moore's parity rule, Moore's rhythm rule, Schulz's gender rule and the Schulz S25–28 trigram
configuration are **jointly unsatisfiable** over the C1∩C2∩C4∩C5 space — the pair-structure space
with the base constraints every encoding in this report fixes (§2). Not rare, not
computationally out of reach — impossible. *(Scope corrected 2026-07-30: earlier versions stated
this at pairing-preserving — C1-only — scope, which the certificate does not establish; the base
CNF fixes C2, C4, and King Wen's C5 multiset for every target. **Correction 2026-08-01:** an earlier
version of this parenthetical asserted that "TR-1's statement of the same theorem was already correctly
scoped." That was false — TR-1 v1.19 (2026-08-01) records that TR-1 carried the mis-scoped statement and
that "v1.18 recorded a propagation that had not happened." TR-1 has since been corrected; this sentence
had not been, so the retraction's own account of its reach was wrong in two reports at once.)*

**How it was checked, and by whom.** The chain is deliberately three-party.
`python3 sat.py --emit-cnf grand-ccn4 f.cnf` generates the formula from the same constraint definitions
the rest of the project uses. **kissat** — an independent, widely used solver we did not write — decides
it UNSAT and emits a DRAT proof. **drat-trim**, an independent checker we also did not write, replays
that proof against the regenerated formula and prints `s VERIFIED`. Our contribution is the encoding,
and that encoding is separately validated against the authors' own King Wen numbers per §2. A reader who
distrusts every piece of our software can still reproduce the formula and re-verify the certificate.

**The result is robust, not brittle.** The v1.6 extension pushed on it from several directions and it
held: the five-rule union is UNSAT; *every* leave-one-out subset of that union is still UNSAT
(`five_loo_parity`, `five_loo_rhythm`, `five_loo_gender`, `five_loo_ccn4`, `five_loo_ccn8`); the
conflict decomposes into three minimal **two-rule cores**, so it is not an artifact of piling on
constraints; and the union admits no repair at any tested edit distance (`grander-strict-near-2/3/4` all
UNSAT). A single fragile encoding choice cannot produce that pattern.

**One honest qualification about the trigram rule.** Of the four, the S25–28 trigram configuration is the
most **data-like**: it is a description of a specific local feature of the received sequence, and King
Wen satisfies it exactly, by construction of how it was stated. A rule read off the object it then
"explains" carries less evidential weight than one stated independently, and this is priced accordingly
elsewhere in the suite ([CRITIQUE.md](../documentation/CRITIQUE.md) §"Observable-selection accounting";
[TR-9](TR9_PRICING_THE_CONSTRAINTS.md)). It matters here because the conflict theorem is a statement
about the rules *as their authors stated them*, and a reader is entitled to know that one of the four is
more descriptive than explanatory. The theorem survives its removal — that is exactly what the
leave-one-out certificates establish — so the conclusion does not rest on it.

**What follows.** The exceptions that Zhu Yuansheng, Moore and Schulz each recorded independently are not
evidence of damage to an original perfect under the full four-rule inventory, because no such original
could exist (damage relative to the three-graded-rule precursor, which does exist, is the separate
question weighed in the Bayesian section). They are the visible
seam of a forced trade-off among competing regularities. King Wen keeps one rule exactly and misses the
other three by the minimal measured margins of two each.

**Baseline calibration — how far that may be read (added 2026-08-01).** It is tempting to read the
preceding sentence as saying King Wen is a *good solution* to the unsatisfiable problem, and this report
did read it that way until now. That inference does not survive its own baseline. **All four rules are
KW-derived** — each was selected because King Wen exhibits it, even where its stated form is general — so
King Wen sitting near their joint Pareto frontier is **expected rather than an efficiency result**, and no
arbitrary-rule-bundle baseline exists to price it against. The same calibration is carried by
[TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) §5 and
[LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md); TR-1 v1.14
restated its own §5 headline from an *optimum* to a **trade-off position** on exactly this ground. Note also
that UNSAT is a statement about *every* C1∩C2∩C4∩C5-valid ordering: all of them sit where the rules force
a choice, so being at a trade-off point is not by itself KW-specific. What is specific to King Wen is
narrower — the miss margin of 2 (**measured**, not certified: no certificate excludes a miss of 1, see
v1.17) and exact satisfaction of `ccn4`, the most data-like of the four by this report's own §4
qualification.

## Verification Guide
- Every theorem: a command + a certificate. Encodings: validated two ways in-repo; the encodings' rule
  semantics were verified to reproduce each author's stated KW values before anything else was trusted.
- "Did you interpret the rules correctly?" -> the KW-value reproduction gates (16/18 at 22-23; 2 breaks
  at (7,8),(22,23); 2 violations at 25/26; the trigram faces 31/24/26/29) — the authors' own numbers.
- Scope honesty: theorem is about the rules AS STATED; no claim about the arranger's intent.
- AI disclosure per policy; results independent of provenance.

### Commands
All targets are in the public repo's `sat.py` (encoding derived from solve.py's constraint
definitions; [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md)'s Verification Guide carries the full kit; environment/versions per METHODS.md).
Every verdict below was re-verified 2026-07-03 on a 2-core box; each command completes in seconds
(kissat on PATH required for `--witness`).
- **Grand precursor exists (abstract claims 1–2; §3):** `python3 sat.py --witness grand-strict` →
  explicit C1–C5-valid ordering with Moore 2005 parity 18/18, Moore 1989 rhythm 0 breaks, Schulz
  gender 0 violations, C3 = 776 (`python3 sat.py --witness moore-strict` for the Moore-only
  precursor; published sequences in [LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md) §SAT-decided).
- **Three edits is minimal (§3):**
  `python3 sat.py --emit-cnf moore-strict-near-2 f.cnf && kissat f.cnf` → UNSAT (no jointly
  compliant ordering within 2 slot-edits of KW; a fortiori under C3);
  `python3 sat.py --emit-cnf moore-strict-near-3 f.cnf && kissat f.cnf` → SAT (3 suffices).
- **The conflict theorem (§4):**
  `python3 sat.py --emit-cnf grand-ccn4 f.cnf && kissat f.cnf f.drat` → UNSAT;
  `drat-trim f.cnf f.drat` → `s VERIFIED`.
- **Encoding gates (§2 — two-way validation against the authors' own KW values), each via
  `python3 sat.py --emit-cnf <target> f.cnf && kissat f.cnf`:** `rc4-kwtest` → UNSAT (KW violates
  the gender rule at class positions 25/26); `rc4-kwexempt` → SAT (KW satisfies it with positions
  25/26 exempt); `ccn4-kwtest` → SAT (KW satisfies the trigram configuration exactly).

## Figure

![Grouped bar chart of the four conflicting rules: King Wen misses Moore's 2005 parity rule by 2 (16/18), Moore's 1989 rhythm rule by 2 breaks, and Schulz's 1990 gender rule by 2 violations while satisfying the Schulz S25–28 trigram configuration exactly; the grand unified precursor is perfect (0) on the first three and violates the trigram configuration — no C1∩C2∩C4∩C5-valid ordering achieves zero on all four.](figures/fig_tr1_rules_tradeoff.png)

*The forced trade-off (§4–5, shared with [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) §5). King Wen (red)
misses the three graded rules by the minimal measured margins (2 each) and keeps the S25–28 trigram configuration
exactly; the grand unified precursor (green, 3 slot-edits from KW) perfects those three and breaks the
trigram configuration — a binary configuration rule with no graded miss count. The joint-UNSAT
certificate says no C1∩C2∩C4∩C5-valid ordering reaches zero on all four axes: the received order's irregularities are the
visible seam of this forced choice, not damage to a once-perfect-under-all-four original (none could exist). Generated by
[`viz/report_figures.py`](../viz/report_figures.py); [SVG](figures/fig_tr1_rules_tradeoff.svg).*

## Extension (v1.6): the conflict's fine structure — three two-rule cores

Adding the next-strongest discriminating rule from the population scoreboard (Schulz's exception
co-location rule, CC-N8) sharpens the theorem in two ways, both certificate-backed and re-verified on
independent hardware:

1. **The five-rule union is unconditionally unsatisfiable** — not merely "no perfect ordering": no
   C1∩C2∩C4∩C5-valid ordering satisfies the five rules at ANY repair distance (the near-2/near-3/near-4
   relaxations are all UNSAT as well).
2. **The conflict decomposes into three minimal two-rule cores**: {Moore parity, Schulz S25–28},
   {Moore rhythm, Schulz S25–28}, and {Schulz gender, CC-N8}. Every leave-one-out four-subset of the
   five rules remains unsatisfiable, and each core is a two-rule contradiction on its own. In
   particular, the four-rule system of the main theorem was not a MINIMAL unsatisfiable set — the
   gender rule is not needed for that instance of the conflict. The main theorem's statement is
   unaffected; its anatomy is now finer: the literature's rules do not fail jointly in one tangle,
   they fail in specific pairs. One disclosure the uniform presentation of the three cores previously
   omitted (added 2026-07-30): the third core, **{Schulz gender, CC-N8}, is incompatible by
   construction** — CC-N8 requires the gender rule's violations to sit exactly at class positions
   25/26 while the strict gender rule demands zero violations, so that core is a definitional
   triviality rather than a discovered combinatorial fact (the encoding keeps CC-N8 as stated so the
   semantic conflict is itself certificate-backed). The other two cores are genuine discoveries, and
   the four-rule conflict theorem of §4 does not involve CC-N8 at all.

Certificates: fourteen DRAT proofs — the union (1), its near-2/3/4 repair ladder (3), all five
leave-one-out subsets (5), the three two-rule cores (3), and two encoding-validation gates
(ccn8-kwfail, ccn8-kwchain-not) — **all archived in [certificates/](certificates/)** alongside the
original five conflict certificates (21 in the directory today — see certificates/README; each mapped to its `sat.py --emit-cnf` regeneration
command in certificates/README.md and checked by verify_all.sh). Every one drat-trim verified, with
the full set re-verified against freshly regenerated encodings on a separate machine.

## A Bayesian comparison: corruption vs. tendency (v1.7)

The conflict theorem settles what cannot exist: no C1∩C2∩C4∩C5-valid ordering perfect under all four
rules. The three **graded** rules — Moore's 2005 parity, Moore's 1989 rhythm, Schulz's 1990 gender rule
(its exceptions first noted by Zhu Yuansheng in the 13th century) — are jointly satisfiable: the grand
precursor of §3 achieves all three exactly, and the received order sits exactly three slot-edits from it.
Its six rule-violations are **not** all at one locus (an earlier version of this report said they were;
corrected 2026-07-20 by direct computation against the scorers; reproduce via `python3 solve.py --r11-verify`). Exactly: the two Moore-parity breaks and
one of the two Moore-rhythm breaks fall at **pair-slots 22–23** — the anomaly Moore identified — while the
second rhythm break is at **pair-slots (7,8)** and the two Schulz-gender violations are at
**inversion-class positions 25–26** (a different coordinate system from the pair-slots). Four of the six
cluster at the flagged locus; two do not.
**A definitional caution (F-46):** the *clustering* at 22–23 is less surprising than it first reads. Moore
and Schulz each described their rules' exceptions *with reference to* that anomaly, so parity and one
rhythm break landing there is partly a property of how the rules were stated, not solely a discovered
coincidence — and, as the positions above show, the fit is partial rather than total. The certificate-backed
content (that three edits suffice, and that all four rules cannot hold at once) does not depend on the
co-location being surprising. §5
left the reading of that residual anomaly open: restricted corruption, or tendencies? This section weighs
that question — within a two-model comparison conditioned on the literature's rules, the strongest reading
the data support and no more — by a pre-registered Bayesian comparison of the two readings the
literature itself supplies:

- **M_corr (corruption):** an originally rule-perfect ordering (under the three graded rules) was hit by
  a small physical transmission accident. Moore (1989, 2005) conjectured a compliant original later
  altered; Schulz's exceptions sit at the same locus; [Rutt (1996)](../documentation/CITATIONS.md#rutt1996) supplies the physical mechanism
  (re-strung bamboo-slat cords, allowing adjacent transpositions and slat inversions), as discussed by
  [Hacker & Moore (2003)](../documentation/CITATIONS.md#hacker-moore2003). This work quantifies the conjecture Moore and Schulz raised on interpretive
  grounds.
- **M_tend (tendency):** the arranger held the three rules as soft preferences (a Gibbs strength λ),
  never exactly; the anomaly is ordinary imperfection, with no corruption event at all.

**Scope caveat, stated before the result.** This is a comparison of exactly **two** models, conditioned
on the literature's three rules being the relevant regularities. A Bayes factor between them says which
of the two the data favor — it is **not proof of corruption in any absolute sense**, and it does not
test whether the rules themselves are the right lens (e.g., against the rules being post-hoc
pattern-noise on a sequence arranged by entirely other principles — a separate question, outside this
test's scope). It also does not conflict with this report's headline: the theorem rules out an
all-four-rule original; this comparison concerns only the three graded rules, whose joint perfection is
achievable.

**Pre-registration discipline.** The model forms, the two corruption-location variants (uniform edit
location; bamboo-adjacent-biased), the 50:50 model prior, and the Jeffreys decision bands (BF > 10
substantial, BF > 100 strong) were frozen by operator sign-off on 2026-07-04, **before** the runs were
executed, with a pre-committed publish-whatever-it-says clause: the full sensitivity table would be
published regardless of direction. Nothing was altered after seeing the numbers except the numbers
themselves. One disclosed gap: the frozen document left the parameter-prior grids symbolic; they were
declared wide at computation time (each spanning ~2 orders of magnitude, uniform weights), and the full
per-gridpoint likelihood tables are published so any reader can re-weight them.

**What is publicly verifiable about the freeze — and what is not (disclosure added 2026-07-26, mirroring
the standard TR-10 v1.7 set for its own pre-registrations).** The freeze-before-measurement claim above
is **operator-attested, not publicly verifiable**: the first public commit carrying the frozen design
([`reports/evidence/f11/PREREGISTRATION.md`](evidence/f11/PREREGISTRATION.md), commit `c0b0ef6`,
2026-07-04 22:10 UTC) also carries the results bundle — registration and measurement landed the same
day, and no earlier public commit contains the frozen text alone, so an external reviewer cannot
distinguish freeze-before-measure from batch-landing from the git record. Because this section reports
a **positive** result, that distinction is load-bearing, and readers who discount unverifiable freezes
should weight instead the features that hold regardless of freeze timing: the pre-committed
publish-whatever-it-says clause was honored; the full 24-configuration sensitivity grid is published and
its direction never flips (worst gridpoint BF = 3.3, still > 1); the symbolic-parameter-grid gap is
disclosed above with the per-gridpoint likelihood tables published for reader re-weighting; and the
subsequent stop-flag episode (v1.10–v1.12) shows the pre-registered gates were enforced against the
result's favor. (Contrast the four-class comparison below, whose frozen design was publicly committed
in v1.9 on 2026-07-10, ten days before its calibration measurement — the publicly-anchored form of the
discipline.)

**The result.** Both models are full generative models over the canonical C1–C5 space (the shared
substrate, which cancels), evaluated at the exact received sequence.

- **BF(corruption/tendency) ≈ 6.6×10³** (variant U, uniform edit location) and **≈ 7.9×10³** (variant A,
  bamboo-adjacent-biased) at the primary configuration — both exceed the frozen BF > 100 "strong" band
  by well over an order of magnitude.
- Under the frozen 50:50 model prior, **posterior P(corruption | data) ≈ 0.9998**.
- **Scope of these figures.** The Bayes factor and posterior are *pairwise*: corruption versus
  soft-preference arranger, and nothing else. They exclude neither a **greedy/local builder** (M_G) nor a
  **uniform-valid null** in which the three rules are post-hoc regularities rather than generative ones
  (M0). Both are pre-registered in the four-class comparison below, whose measurement has not run; until
  it does, no figure in this section bears on either rival. A posterior of 0.9998 *within a two-model
  pair* is not a 0.9998 posterior that the sequence was corrupted.
- **Sensitivity:** across every one of the 24 pre-committed configurations, the BF ranges
  **1.4×10³ – 2.7×10⁴**; the direction never flips anywhere in the sensitivity space. Even a reader free
  to concentrate all prior mass on the single most tendency-favorable gridpoint of both parameter grids
  cannot push the evidence below the substantial band except marginally at that one corner (worst
  gridpoint BF = 3.3, still above 1; 46 of 49 gridpoints give BF > 100).

Why so one-sided, in one sentence: the tendency model must pay for the enormous near-compliant
population its soft preference admits, while the corruption model concentrates its mass on sequences a
few edits from strictness — and the received order is one of very few such sequences (2 of the 7,975
possible 3-edit events land in the rule-perfect set, a fact established by exact enumeration, and the
SAT-certified minimal repair distance of 3 is reproduced by that same enumeration).

**The weakest ingredient, honestly.** The size of the triple-strict (rule-perfect) population,
N_gs, was at publication time a **derived** quantity — the single least-precise ingredient in the
computation, its two derivations disagreeing by ×3.5 (3.57×10²⁵ vs 1.03×10²⁵); per the
strictest-reading rule the larger (corruption-weakening) value was primary. It has since been
measured **directly** at N_gs = 4.50×10²⁵ (±6%, four independent seeds) — see the stop-flag
resolution below, which this paragraph's original wording triggered: the pre-registered gate on the
derived bracket fired, was investigated, and is closed. Under the measured value the headline
weakens by ×0.79 and no configuration leaves the strong band; the flip threshold is 52× away.

**Stop-flag resolution (v1.12, 2026-07-13): the pre-registered gate fired, was investigated, and
is CLOSED — verdict re-affirmed.** The v1.10 annotation recorded that the four-class extension's
ingredient run measured N_gs **directly** for the first time (5.00×10²⁵, relative error 16.7%)
and that this fell outside the derived bracket [1.03, 3.57]×10²⁵, triggering the pre-registered
stop-and-investigate rule. The investigation ran in stages, all archived in
[evidence/r11/](evidence/r11/):

*Diagnosis.* The "bracket" was never a confidence interval. Its endpoints are two **point
estimates** of the same derived quantity — a rare conditional fraction times a population size —
and neither carried propagated uncertainty: one multiplies a three-significant-figure scoreboard
fraction whose sampling error was unknown; the other is a single sparse histogram cell with no
interval at all. Empirically, independent draws of that derived estimator at comparable budgets
span 1.03–3.57×10²⁵ with a higher-budget draw between them at 1.73×10²⁵ — a per-draw scatter of
roughly ×2–4. Weighted rare-event estimators of this kind are also right-skewed (typical draws land
below the mean), so a span of typical draws is predictably centered low, and a correct direct
measurement landing **above** it is the expected signature of the flaw. The stop rule itself worked
exactly as designed — it halted integration and forced this investigation; the defective part was
the reference interval it compared against.

*Re-measurement.* Four independent-seed direct runs (5.5×10¹⁰ probes each, composed in-walk
triple-strict prune) give 4.15, 4.99, 4.34, 4.53 ×10²⁵ — mutually consistent (χ²₃ = 1.4,
p ≈ 0.7) — pooling to **N_gs = 4.50×10²⁵** with a conservative propagated relative error of 6.1%
(95% CI [3.96, 5.05]×10²⁵; the empirical between-seed scatter gives 4.0%, and the larger figure is
adopted). Correctness evidence: every run reproduces the build's self-test sha and the two-language
KW axis-reproduction gate; an independent in-walk full-scan re-scorer reports zero mismatches on
every reached leaf in all four runs; and exact brute-force counts of three non-empty deep subtrees
are reproduced by the estimator machinery to within 0.11%.

*The three convergence gates.* The pre-registered convergence rule required three cross-checks, and
all three now pass. (1) The four-seed χ² consistency check agrees at ~1σ. (2) A Moore-strict-only
derived re-run — now instrumented with a propagated CI, closing the gap that made the original
bracket unsound — lands 1.9σ below the direct value (consistent; that path is intrinsically noisy).
(3) A stratified-start cross-check was at first un-poolable: its estimator was found to mis-compose
the strict prunes with fixed-prefix starts, biasing the naive branch sum upward (3.35σ high). That
composition defect was repaired with an estimator-only, self-test-neutral fix (the build's self-test
sha is unchanged), and the repaired run — which correctly zeroes the 15 of 56 branches whose fixed
prefix violates a strict predicate — pools to 4.34×10²⁵, **0.12σ** from the direct value, inside its
pre-committed 2σ gate. With all three gates green (1σ / 1.9σ / 0.12σ), the pre-registered "all three
gates pass" criterion is literally satisfied.

*Resolution.* Under the directly measured N_gs, the headline Bayes factors become
**≈ 5.2×10³ (variant U) / ≈ 6.3×10³ (variant A)** — modestly smaller than the v1.7 values, as
expected, since the direct count exceeds the derived value the v1.7 computation used and the
corruption likelihood scales as 1/N_gs. The direction is unchanged in **every one** of the 24
pre-committed sensitivity configurations, whose floor rescales to ≈ 1.1×10³ (≈ 9.9×10² even at the
conservative CI's upper endpoint) — an order of magnitude above the frozen "strong" band. Flipping
the primary configuration down to that band would require N_gs ≈ 52× the measured value. Notably,
the direct measurement **excludes** the smaller derived endpoint (1.03×10²⁵) — the value that most
flattered the corruption model — vindicating in direction the v1.7 strictest-reading choice of the
larger endpoint as primary. The v1.7 numbers above stand as the as-computed 2026-07-04 record; the
primary N_gs for any future computation is the pooled direct measurement, with the two derived
values retained as sensitivity rows.

*Honest residuals.* The direct estimator's CI rests on ~300 effective samples pooled, so its far
tails are not guaranteed — which is why the conservative error convention is adopted and both
conventions are reported. The re-measured value (N_gs = 4.50×10²⁵) is **0.57σ below** the Phase-1 single
run it re-checks (5.00×10²⁵ ± 16.7%) — consistent. (v1.19 dropped the σ here as "not reconstructible
from the stated errors". It is reconstructible: the convention is |Δ| ⁄ √(SE₁² + SE₂²) on the adopted
conservative SE, which reproduces all three gate figures above to the digit, and the retracted 1.4
came from dividing by the raw between-seed SD instead — see
[evidence/r11/PHASE2_README.md](evidence/r11/PHASE2_README.md) §"Honest residuals".) No value in the
plausible range moves any configuration below "strong";
the resolution changes the headline by a factor of ~0.8 and the evidential footing from a derived,
unquantified-uncertainty ingredient to a directly measured one with stated error.

**What this does NOT say.** Nothing about who altered the sequence, when, or how; no dating, no
attribution, no reconstruction of events. It licenses no claim beyond the model pair compared: conditional
on the literature's three rules being the relevant regularities, the received sequence is far better
explained as a corrupted rule-perfect ordering than as the output of a soft-preference arranger — whether
the rules are the right lens remains open. In particular it does **not** exclude the two mundane rivals
that a skeptic should reach for first: a **greedy or otherwise local builder**, which was never in the
compared pair, and the **rules-epiphenomenal** case in which the three regularities are artefacts read
off an ordering produced by some unrelated process. Excluding those requires the four-class comparison
registered below, which has not been run. A reader who wants a single sentence: this result narrows the
field by one rival, it does not establish corruption.

**Reproduction.** The complete evidence bundle is PUBLIC at [evidence/f11/](evidence/f11/): the frozen
pre-registration, the full results document (model forms, priors grids, sensitivity table), the
closed-form integration script (`compute_f11_bf.py` — rerun it on the bundled raw outputs to
reproduce every Bayes factor; `cd reports/evidence/f11 && python3 compute_f11_bf.py`, ~1 s,
stdlib-only), and all five raw run outputs plus the exact edit-event enumeration
(`f11_events.json`, regenerable by the bundled `f11_events.py`). The underlying population runs are
reproducible from `solve.c`'s `--estimate-knuth` estimator at the stated probe counts (2×10¹⁰, 5×10⁹,
5×10⁹, 2×10⁹) with the documented environment flags — `SOLVE_KNUTH_SCORE=1` (scoreboard, all runs),
`SOLVE_KNUTH_F11_HIST=1` (joint violation histogram, run A), `SOLVE_KNUTH_MOORE_STRICT=1`
(Moore-joint-strict walks, runs B/C), `SOLVE_KNUTH_GENDER_STRICT=1` (triple-strict prune, available
for re-derivation) — all in the public `solve.c` and documented in [SOLVE_C_CLI.md](../documentation/SOLVE_C_CLI.md) §ENVIRONMENT; the
edit-event geometry (k ≤ 6) is an exact enumeration, not sampled.

## Pre-registered extension (v1.9): a four-class model comparison — calibration run, verdict VETOED (v1.14)

The v1.7 Bayesian comparison above is deliberately a **two-model** test (M_corr vs M_tend), and its own
scope note names the gap: it cannot weigh "the rules are real" against models outside that pair. A wider
**four-class** comparison has now been pre-registered — its design frozen BEFORE any measurement, in the
same F4′/F11 discipline (publish-whatever-it-says; primary configuration designated before any number
exists). The four classes:

- **M0 — uniform-valid:** KW is an unremarkable member of the C1–C5 space; every rule-compliance is
  coincidence at its measured population rate.
- **M_G — greedy-builder:** a sequential softmax arranger placing pairs one slot at a time under local
  preferences, never optimizing globally — the natural generator of "near-miss on every axis" profiles,
  and the rival F11 never tested.
- **M_D — global-design:** a Gibbs arranger weighing the frozen rule bundle globally with per-axis
  strengths (generalizes M_tend).
- **M_C — corrupted-precursor:** F11's M_corr, carried unchanged, with the grand-strict population size
  N_gs measured directly this time (closing F11's weakest ingredient — the ×3.5 spread between its two
  derived estimates). *This measurement has since been run and its stop-gate episode resolved — the
  direct value is N_gs = 4.50×10²⁵ (±6%); see the stop-flag resolution in the v1.7 section above.*

The axis bundle, numeric priors and grids, the Jeffreys decision bands (as v1.7), a synthetic-draw
calibration that runs BEFORE the KW verdict and can veto an unreliable one, and an adequacy layer
auditing every model against the full published functional battery are all fixed in the frozen design.

### Outcome (2026-07-20): the calibration vetoed the verdict — no four-class result will be published

That calibration has now run, and **it failed.** Under the frozen procedure — 100 synthetic draws per
class, each scored under all four models, the true class required to rank first in at least 70 of its
100 draws — one class falls below the bar, and it is the decisive one:

| true class | first-rank rate | verdict |
|---|---|---|
| M0 — uniform-valid | 99/100 | pass |
| **M_G — greedy-builder** | **67/100** | **FAIL (confusable)** |
| M_D — global-design | 81/100 | pass |
| M_C — corrupted-precursor | 84/100 | pass (7 draw failures counted against it) |

**M_G is exactly the rival this extension existed to test.** Its failure is not marginal and not an
artifact of one configuration: it clears 70 in none of the pre-committed sensitivity readings, scoring
67 (primary), 67 (`corrA`) and 45 (`uncond`). Its median log₁₀ Bayes factor against the best rival is
1.12 in the primary configuration and turns **negative** under `uncond` (−0.65), meaning a sequence
genuinely produced by a greedy builder typically scores *better* under a rival model than under the
truth. The misclassifications scatter into M0 (19) and M_D (14): greedy-built orderings simply look
like uniform-valid or globally-designed ones once the shared C1–C5 substrate is factored out.

*The full grid, for every class (v1.23 correction).* Until 2026-08-02 the four-variant grid was quoted
only for the class that failed, and the three passing classes were reported at their primary number
alone — a selective use of a pre-committed sensitivity set. First-rank rate out of 100, all four
classes, all four variants:

| true class | primary | corrA | uncond | histZ |
|---|---:|---:|---:|---:|
| M0 — uniform-valid | 99 | 99 | 99 | 99 |
| **M_G — greedy-builder** | **67** | **67** | **45** | **25** |
| M_D — global-design | 81 | 81 | 86 | 99 |
| M_C — corrupted-precursor | 84 | 84 | 72 | **1** |

Two qualifications belong with that table, and they cut against this report's earlier phrasing rather
than for it. **`corrA` is not an independent reading:** it re-scores M_C under the frozen A
corruption-location variant, and although the likelihoods do differ — over the 139 draws with L_C > 0,
by a median of 0.3% and a maximum of 89% — the difference changes the arg-max on
**0 of 393 draws**, reproducing the primary confusion matrix cell for cell — so four variants yield
three distinct outcomes. **The `histZ` column ranks M_D's normalizer, not the other classes:** it
substitutes M_D's histogram-only Z table (29,997 cells) for the augmented one (30,439 cells, which
supplies the rare low-violation corners) and changes no other likelihood, inflating L_D by a median
factor of 10^5.56; every draw M_G or M_C loses under `histZ` is lost to M_D (42/42 and 83/83). M_C's
1/100 is therefore a property of that inflated M_D likelihood, not evidence against the
corrupted-precursor class — the two-model corruption result of §v1.7/v1.12 is untouched by it, since
M_D is not a party to that comparison — and by the same token M_G's 25 is confounded and is not a
fourth independent failure. What survives unchanged is the veto itself: M_G is below 70 in the primary
configuration, on which the frozen verdict is computed, and in both unconfounded variants.
Derivation and per-draw checks in [evidence/r11/README.md](evidence/r11/README.md).

**Consequence, per the frozen design's own §6.3 veto: no four-class Bayes factor, posterior, or verdict
is computed or published — here or elsewhere.** The gate was frozen before any of these numbers existed,
it fired, and we abide by it. Running the comparison against King Wen would have produced a
confident-looking number that our own pre-registered criterion says we may not believe.

**What this does and does not license.** It does *not* say the greedy-builder explanation is correct, nor
that the v1.7 corruption result is wrong; the v1.7 two-model comparison and its v1.12 re-affirmation are
untouched, and their scope statements above already say they exclude only the soft-preference arranger.
What it says is narrower and more useful: **at this sample size these four explanations are not reliably
distinguishable by this method**, so the honest position on the greedy-local and rules-epiphenomenal
rivals is that they remain open — not defeated, and now demonstrably not defeatable by this instrument as
specified. That is a limit of the inference, not a property of the sequence.

*Honest residuals.* M_C incurred 7 draw failures out of 100 (the class draws a rule-perfect precursor,
whose support is ~10¹² times thinner than the other classes', so its sampler dead-ends more often); those
failures are counted against M_C's own 100 rather than discarded, the conservative convention. They are
not load-bearing for the verdict: the failing class, M_G, had zero draw failures, so no attrition
question can rescue it. Sampling is sequential Monte Carlo with an exact monotone C3 lower-bound prune
(bias-free: a pruned particle would carry weight zero at completion, and at the final slot the bound
equals the true C3 value, runtime-asserted). The calibration is a statement about discriminability at
n = 100 per class under the frozen bundle; a larger n or a different functional bundle could in principle
separate M_G, and the design permits revisiting under a fresh pre-registration.

*Evidence.* Instrument, per-class draws, per-draw scores, the four variant confusion matrices, and the
veto report are in [evidence/r11/](evidence/r11/) (`r11_calibration.py`, `calibration_report.txt`,
`draws.json`, `scores.json`, `hits.json`, `pcomplete.json`, `gates.json`; master seed 20260720,
deterministic). Two pre-gates worth noting as independent cross-checks that the instrument was wired to
the right object: the exact 3-edit event count reproduces the published 7,975, and the greedy builder's
measured completion probability is 0.8–1.4% across the β grid (n = 32,000 per point) — an independent
sighting of how thin the C1–C5 space is.
The comparison is **report-only, with no promotion path**, and it does not revise the v1.7 two-model
result, which stands as published (if the wider comparison ever dethrones corruption, this section gains
a forward-pointer; it is not rewritten).

**STATUS (v1.14, 2026-07-20): calibration RUN; verdict VETOED; nothing further will be published.**
*(This block previously read "STATUS (v1.12): ingredients collected; verdict not computed" and stated
that the synthetic-draw calibration "has **not** run". That was superseded by the veto recorded in the
Outcome subsection of this same section, and left standing for twelve days — corrected 2026-08-01.)*
The instrument wiring and the ingredient runs — including the direct N_gs measurement, whose stop-gate
firing and resolution are documented in the v1.7 section above — were executed. The synthetic-draw
calibration then **ran and FAILED its confusability gate**, which the frozen design placed before any
KW-facing verdict; §6.3 therefore forbids computing or publishing a four-class Bayes factor, posterior
or verdict, here or elsewhere. **No such result exists, and none will.** The N_gs solidity gate,
including the now-repaired stratified cross-check, had passed; the veto is a failure of the calibration
gate specifically, not of the ingredients. One ordering-of-operations deviation is disclosed now, in the F11 "honest note" style: the
ingredient runs (population measurements, blind to any KW-facing verdict) were executed before the
design's formal operator freeze stamp; the design summarized here was committed publicly (v1.9,
2026-07-10) before any of those measurements, which is the tamper-evident witness that no
verdict-relevant element moved in response. Results, when computed, land in
`reports/evidence/r11/` under the frozen verdict template, whatever their direction.

*Attribution: the modeled rules belong to their authors (Moore, Schulz, Cook; the corruption mechanism
to Rutt via Hacker & Moore); the greedy-builder formalization and the four-class design are ROAE,
developed with AI assistance (Claude, Anthropic). Corrections welcome via
[CITATIONS.md](../documentation/CITATIONS.md).*

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
| v1.2 | 2026-07-04 | Figures added |
| v1.5 | 2026-07-04 | Adversarial round 2 correction: conflict-theorem claims scoped to pairing-preserving orderings |
| v1.6 | 2026-07-04 | Extension: five-rule union unconditionally UNSAT; conflict decomposes into three two-rule minimal cores (14 new certificates, re-verified on independent hardware) |
| v1.7 | 2026-07-04 | Bayesian comparison section added: pre-registered corruption-vs-tendency Bayes factor (BF ≈ 6.6×10³ / 7.9×10³, strong; sensitivity 1.4×10³–2.7×10⁴, direction never flips); executive summary updated |
| v1.8 | 2026-07-04 | Reproducibility completion (TR-audit fixes): F11 bundle completed — `f11_events.json` + generator `f11_events.py` published, so `compute_f11_bf.py` reruns from the bundle alone (verified: reproduces BF 6.6×10³/7.9×10³); F11 instrument (`SOLVE_KNUTH_F11_HIST`, `SOLVE_KNUTH_GENDER_STRICT`) merged into public solve.c (selftest sha unchanged) and documented in SOLVE_C_CLI.md with `SOLVE_KNUTH_MOORE_STRICT`; the v1.6 "fourteen DRAT proofs" fully archived in certificates/ (19 total incl. the three two-rule cores), each mapped in certificates/README.md and covered by verify_all.sh; §Reproduction names every flag explicitly |
| v1.9 | 2026-07-10 | Pre-registered four-class model comparison (M0 uniform-valid / M_G greedy-builder / M_D global-design / M_C corrupted-precursor) added as a frozen design under F4′/F11 discipline; measurement pending — no Bayes factor, posterior, or verdict reported. Executive summary notes the registration. The v1.7 two-model result stands unchanged. |
| v1.10 | 2026-07-11 | Stop-flag annotation: the direct N_gs measurement ([evidence/r11/](evidence/r11/)) yielded 5.00×10²⁵, outside the v1.7 derived bracket [1.03, 3.57]×10²⁵ — the pre-registered stop-and-investigate gate fired. The v1.7 Bayes verdict is marked UNDER REVIEW pending investigation (neither revised nor re-affirmed). "closes that question as far as data can" tightened to the section's own conditional scope. |
| v1.11 | 2026-07-11 | Process section relocated: the dormant journal-submission checklist moved out of the public report (process content, not findings; now maintained privately). No findings changed |
| v1.12 | 2026-07-13 | Stop-flag resolution: the v1.10 UNDER REVIEW annotation is closed. Investigation ([evidence/r11/](evidence/r11/)) found the derived bracket [1.03, 3.57]×10²⁵ was never a confidence interval (two point estimates, no propagated uncertainty); a 4-seed direct re-measurement gives N_gs = 4.50×10²⁵ (±6% conservative), with all three pre-registered convergence gates passing (χ² seed-consistency ~1σ; derived-CI cross-path 2.0σ; repaired stratified cross-check 0.12σ — the stratified instrument's strict-prefix composition defect was repaired by an estimator-only, self-test-neutral fix; **the middle figure was superseded by v1.19 below — the body reported that gate at 1.9σ throughout and v1.23's stated convention reproduces it as 1.92σ. Against the pre-committed 2σ gate the retracted 2.0σ read as sitting AT the gate rather than inside it. This dated row preserves what that pass wrote; the live figure is v1.23's**). Under the measured value BF ≈ 5.2×10³ (U) / 6.3×10³ (A) — direction unchanged in all 24 pre-committed configurations; verdict re-affirmed (headline ×0.79 smaller, footing stronger). Weakest-ingredient paragraph updated; four-class section status corrected (ingredients collected, verdict not computed, N_gs solidity gate passed); no theorem or certificate touched |
| v1.13 | 2026-07-20 | **Corruption-result scope + form labelling (adversarial-review items F-43, F-8).** F-43: the 0.9998 posterior and the BF figures are a *pairwise* verdict — corruption vs soft-preference arranger — but nothing adjacent to them said so. Scope statements added at all three points a reader meets the numbers (executive summary, the findings bullet list, and "What this does NOT say"), stating explicitly that they exclude neither a greedy/local builder (M_G) nor the rules-epiphenomenal uniform null (M0), both of which remain un-run, and that a 0.9998 posterior *within a model pair* is not a 0.9998 posterior that the sequence was corrupted. The four-class comparison's calibration gate is separately in progress; no verdict is claimed. F-8: "Structure (6 sections)" relabelled to note that items 1-6 are section summaries, with the report's fully-written material being the v1.6/v1.7/v1.9/v1.12 sections. No theorem, certificate, or computed value changed |
| v1.14 | 2026-07-20 | **Four-class comparison: calibration run, verdict VETOED — no result will be published.** The frozen design placed a synthetic-draw confusability gate before any KW-facing integration; it has now been executed and failed. The greedy-builder class M_G ranks itself first in 67/100 draws against a pre-registered threshold of 70 (67/67/45/25 across the four sensitivity variants; median log10 BF vs best rival 1.12 primary, negative in two variants), so M_G is not reliably separable from M0 or M_D at n=100 — and M_G is precisely the rival this extension existed to test. Per the design's §6.3 veto, no four-class Bayes factor, posterior, or verdict is computed or published, here or elsewhere; `compute_r11_bf.py` is not written and not planned. Section retitled from "measurement pending" to "calibration run, verdict VETOED" and an Outcome subsection added stating what the result does and does not license: the v1.7/v1.12 two-model corruption result is untouched, the greedy-local and rules-epiphenomenal rivals remain OPEN rather than defeated, and the finding is a limit of the inference at this sample size, not a property of the sequence. Honest residuals recorded (7 M_C draw failures counted conservatively against its own 100, not load-bearing since the failing class M_G had zero; SMC uses an exact bias-free monotone C3 lower-bound prune, runtime-asserted). Full instrument and per-draw evidence published to evidence/r11/. No theorem, certificate, or previously published number changed |
| v1.15 | 2026-07-20 | **Section bodies for §2-4 written (F-8, operator-directed).** §2 Method: the pair-structure space and why it is the literature's own assumption rather than a tractability convenience; what a SAT solver decides and why UNSAT is the stronger answer; what a DRAT certificate is and why it removes us from the trust chain; and the two-way encoding validation stated in plain language (rc4-kwtest UNSAT / rc4-kwexempt SAT / ccn4-kwtest SAT, plus reproduction of each author's own KW tallies before anything was trusted). §3 Moore's precursor: the witness with its rule tallies (parity 18/18, rhythm 0 breaks, gender 0 violations, C3=776) and the two-sided bracket establishing edit distance exactly three (near-2 UNSAT with certificate, near-3 SAT) — a historical conjecture rendered as a measured quantity. §4 The conflict theorem: the statement, the deliberately three-party verification chain (our encoding, kissat's decision, drat-trim's independent replay), the robustness evidence (five-rule union UNSAT, every leave-one-out subset still UNSAT, three minimal two-rule cores, no repair at any tested distance), and an explicit qualification that the S25-28 trigram rule is the most data-like of the four — with the note that the leave-one-out certificates show the theorem survives its removal. §1 and §5 deliberately REMAIN summaries: both are humanities-register prose where each added sentence is a further claim about what a named scholar said, this suite has already shipped one misattribution (F-15), and no constraint result depends on that prose. No theorem, certificate, number, or scope statement changed |
| v1.16 | 2026-07-20 | **Framing pass (adversarial-review F-42, F-40a, F-46).** F-42: a reconciliation clause added to the executive summary so "not damage" and the corruption Bayes factor are not read as contradictory — the impossibility theorem rules out an original perfect under all *four* rules, while the Bayesian comparison concerns only the *three graded* rules, whose joint perfection is achievable. F-40a: the v1.12 stop-flag block compressed from a mechanics-dense paragraph to one sentence, with the derivation left in the body section that already carries it. F-46 + factual correction: the report had claimed "all six violations co-located at the historically flagged locus" — **this was wrong**, found during the framing review and confirmed by direct computation against the byte-for-byte scorers (Moore parity at pair-slots 22–23, Moore rhythm at (7,8) and (22,23), Schulz gender at inversion-class positions 25–26; four of six cluster at 22–23, two do not, and gender uses a different coordinate system). The passage now states the exact positions; the F-46 definitional caution is retained but scoped to the *partial* clustering. No theorem, certificate, or count changed — g1,g2,g3 remain 2,2,2 — only the false co-location claim is corrected |
| v1.17 | 2026-07-26 | **Headline scoping + freeze-anchoring disclosure (round-2 audit, inference loop 4b F-1/F-3/F-4 + completeness loop 4e G3).** The executive summary, abstract, §5 "What follows" and the figure caption now scope "not damage" to *a once-perfect-under-all-four original* (the only damage hypothesis the conflict theorem addresses — damage relative to the three-graded-rule precursor remains the open question the Bayesian section weighs); "smallest margins possible" corrected to "smallest measured margins (2 each)" (zero-miss is certificate-excluded, but no certificate excludes a miss of 1, so the modal claim was unearned); and a public-anchoring disclosure paragraph added to the Bayesian section stating plainly that the F11 freeze-before-measurement is operator-attested, not publicly verifiable (prereg + results landed in the same public commit `c0b0ef6`), with the freeze-independent features enumerated. No number, certificate, or verdict changed |
| v1.18 | 2026-07-30 | **Conflict-theorem scope correction (novelty-gate SAT self-audit #10 — SUBSTANTIVE).** The four-rule conflict theorem (and the v1.6 five-rule union) had been stated at pairing-preserving (C1-only) scope — "no ordering preserving the classical pairing…" — but the certificate establishes it at **C1∩C2∩C4∩C5** scope: the CNF base shared by every target fixes C2, C4, and King Wen's C5 transition multiset (sat.py's base clauses), and the literature's rules do not imply C5, so the C1-only reading was unearned. All statements of the theorem (executive summary, abstract, §4 Statement, v1.6 union, figure caption/alt text) now read "no C1∩C2∩C4∩C5-valid ordering…", and §2 states explicitly what the base space fixes. TR-1 and LITERATURE_RULES already carried the correct "C1–C5-valid" wording — this closes an internal inconsistency. Also added: the disclosure that the {Schulz gender, CC-N8} two-rule core is incompatible **by construction** (CC-N8 pins the gender violations to positions 25/26; strict gender demands zero) — a definitional triviality previously presented uniformly with the two genuine cores. No certificate, count, or verdict changed |
| v1.19 | 2026-08-01 | **Three internal-consistency corrections (2026-08-01 cross-model calibration review).** (i) §Honest residuals stated the re-measured N_gs as "1.4σ **above**" the Phase-1 single run (5.00×10²⁵) — the pooled value is 4.50×10²⁵, i.e. **below** it; the direction was inverted and the 1.4σ magnitude was not reconstructible from the stated errors, so the sentence now reports the comparison without an unsupported σ figure. (ii) The convergence-gate summary quoted "1σ / **2.0σ** / 0.12σ" while the body reports the Moore-strict-only re-run at **1.9σ**; since the pre-committed gate is 2σ, the summary read as sitting *at* the gate rather than inside it — now 1.9σ, matching the body. (iii) §Extension said the certificate directory holds "19 total"; it holds **21** (certificates/README; TR-5 v2.1 records the intermediate 19→20 step). No measurement, model comparison, or verdict changed |
| v1.20 | 2026-08-01 | **Three silent edits recorded, and v1.18's own propagation claim retracted (2026-08-01 cross-model sweep).** The 2026-08-01 pass made three body corrections here without a revision entry — exactly the silent-edit pattern this suite's process rules forbid. Recorded now: **(1)** the executive summary still called the four-class comparison "pending" twelve days after §Outcome recorded that its calibration RAN and was VETOED; **(2)** the §Extension STATUS block still read "STATUS (v1.12): ingredients collected; verdict not computed" and asserted the synthetic-draw calibration "has **not** run" — superseded by the veto in the same section; **(3)** §4's parenthetical asserted "TR-1's statement of the same theorem was already correctly scoped", which TR-1 v1.19 records as false in as many words ("v1.18 recorded a propagation that had not happened"). **Consequently the v1.18 row below is itself wrong** where it states "TR-1 and LITERATURE_RULES already carried the correct 'C1–C5-valid' wording": TR-1 did not (fixed 2026-08-01), and LITERATURE_RULES did not either — its §"jointly unsatisfiable" statement was still at the under-scoped C1–C5 form until 2026-08-01. Both are now at the certified C1∩C2∩C4∩C5 scope. Also this cycle: TR-1's figure alt-text and its caption six lines apart stated two DIFFERENT theorems for the same PNG — the very defect `fb565a7`/`fb356a9` were written to eliminate — now both at the certified scope. No certificate, count, or verdict changed. |
| v1.21 | 2026-08-01 | **Baseline calibration imported, and the last unearned modal caption fixed (lens sweep unit q-tr1-tr2-tr8-tr10).** **(i)** This report — the primary report for the conflict theorem — carried *none* of the baseline calibration [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) §5 and LITERATURE_RULES have carried since TR-1 v1.14 (2026-07-20): a grep for `Pareto` / `KW-derived` / `KW-descriptive` / `efficiency result` over TR-2 returned zero hits. §5 "What follows" instead closed on "which is what a good solution to an unsatisfiable problem looks like" — the efficiency reading v1.14 retracted — so a reader of TR-2 alone received the retracted inference as the report's conclusion. That clause is withdrawn and replaced by an explicit calibration block: all four rules are KW-derived, so a position near their joint Pareto frontier is expected rather than an efficiency result; and UNSAT means *every* C1∩C2∩C4∩C5-valid ordering sits at a forced choice, so the KW-specific residue is only the **measured** margin of 2 (no certificate excludes a miss of 1 — v1.17) and exact satisfaction of `ccn4`, which §4 already calls the most data-like of the four. Pointers to the calibration added to the executive summary and the §6 coda. **(ii)** v1.17 recorded "the figure caption" among the locations where "smallest margins possible" was corrected to "smallest **measured** margins (2 each)"; the caption still read "the minimal margins (2 each)", while the identical PNG's caption in TR-1 read "minimal measured margins" — the same image carried two different modal strengths across two reports. Caption corrected. No theorem, certificate, count or verdict changed |
| v1.22 | 2026-08-01 | **Dangling section pointer retargeted (serialized cross-file pass, unit r70-serialize).** §4's trigram-rule qualification priced the data-like reading against "[CRITIQUE.md] Q1" — a section that does not exist in CRITIQUE.md and never has; the file half was a resolving markdown link, so GATE 4 saw nothing wrong. Now points at CRITIQUE.md §"Observable-selection accounting", the section that actually prices data-like constraints. Five instances of the same dead pointer across [TR-9](TR9_PRICING_THE_CONSTRAINTS.md) and DESCRIPTION_LENGTH.md were corrected in the same pass, and GATE 4 was extended to check plain-text section references. No theorem, certificate, count or verdict changed |
| v1.23 | 2026-08-02 | **Sensitivity grid published for every class, and the Phase-1 σ restored under a stated convention (unit d74-runs; recovered wkmoa12se items RUNS-03 / RUNS-04).** **(i)** §Outcome quoted the four pre-committed sensitivity variants only for M_G, the class that failed (67/67/45/25), and reported the three passing classes at their primary number alone. The full 4×4 grid is now published, together with two qualifications that cut against this report's earlier phrasing: `corrA` changes the arg-max on **0 of 393 draws** and so reproduces the primary confusion matrix exactly (four variants, three distinct outcomes), and the `histZ` column substitutes M_D's histogram-only Z table (29,997 cells vs the augmented 30,439) while changing no other likelihood — inflating L_D by a median factor of 10^5.56, with every draw M_G or M_C loses under it lost to M_D (42/42, 83/83). M_C's 1/100 under `histZ` is therefore a property of that inflated M_D likelihood and carries no implication for the v1.7/v1.12 two-model corruption result, to which M_D is not a party; M_G's 25 is confounded by the same factor and is not a fourth independent failure. The §6.3 veto is unchanged: M_G is below 70 in the primary configuration, on which the frozen verdict is computed, and in both unconfounded variants. **(ii)** v1.19 removed the σ from the N_gs/Phase-1 comparison as "not reconstructible from the stated errors"; it is reconstructible. The file's convention is |Δ| ⁄ √(SE₁²+SE₂²) on the adopted conservative CLT SE, which reproduces all three convergence-gate figures to the digit (1.06 / 0.12 / 1.92); applied here it gives **0.57σ below**, and the retracted 1.4 came from dividing by the raw between-seed SD (0.359×10²⁵) while omitting the Phase-1 run's own ±16.7%. The σ is restored with its convention named, and evidence/r11/PHASE2_README.md — which still carried the uncorrected "1.4σ above" — is fixed with it. No Bayes factor, gate verdict, count, certificate or sha changed |
| v1.24 *(current)* | 2026-08-02 | **The v1.12 row kept the superseded convergence-gate figure (retracted-figure sweep, unit drain-3).** The v1.12 row (2026-07-13) summarised the three pre-registered convergence gates as "~1σ / 2.0σ / 0.12σ". **v1.19** (2026-08-01) recorded that the middle figure is **1.9σ** in the body, and **v1.23** reproduces it as 1.92σ under the convention it states — so 2.0σ has been superseded for a day, while the row carrying it sits ABOVE both corrections with no marker, exactly the reading order TR-9 v1.20 fixed in its own draft-stage note. The distance is not cosmetic: the pre-committed gate is 2σ, so the retracted figure reads as sitting *at* the gate and the live one as inside it. Nothing is deleted — a dated row is a record — and a supersession clause is added in place. Found by GATE 3b (`scripts/doc_gates.sh retract-figures`), which is the C7 sweep made permanent; of the nine figures that registry currently carries, this is the only occurrence the sweep's quoted-span method could not have seen, because the figure is not in quotes. The registry is hand-seeded, so that is a statement about nine figures, not about every figure in the suite. No measurement, gate verdict, Bayes factor, certificate or sha changed |
