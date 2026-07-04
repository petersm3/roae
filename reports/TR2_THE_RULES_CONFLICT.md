# PAPER A (draft v1) — "The Rules Conflict: Moore's Precursor, Schulz's Exceptions, and a Joint
# Impossibility Theorem for the King Wen Sequence"
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide (below as "Defense kit", to be retitled). Journal-submission variant preserved as a dormant option per REPORTS_PLAN.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

The King Wen sequence has famous "irregularities" — places where its otherwise elegant patterns break.
For centuries these were read as mistakes, corruption, or lost meaning. This report proves a different
explanation: the four strongest design rules proposed for the sequence (two by Steve Moore, two
traceable through Larry Schulz to a 13th-century commentator) are **mutually contradictory — no
arrangement preserving the classical pairing can satisfy all of them**, a fact established by an exhaustive logic
search with an independently checkable certificate. King Wen keeps one rule perfectly and misses the
others by the smallest margins possible. Its irregularities are the visible seam of a forced trade-off,
not damage. A corollary: the "uncorrupted original" that some scholars hypothesized never existed.

Target: *Journal of Chinese Philosophy* (where Moore 2005-adjacent and Schulz 1990/2011 appeared). ~8pp.
Defense model: every load-bearing claim is an artifact check (witness verification or UNSAT certificate).

---

## Abstract

Steve Moore (1989, 2005) proposed two design rules for the King Wen sequence, observed that the received
order complies with one at sixteen of eighteen testable positions with both exceptions adjacent, and
conjectured an originally compliant order later altered. Larry Schulz (1990, 2011, 2016) independently
formalized a third rule over Lai Zhide's thirty-six consolidated units, with its own exceptions at the
same locus — noted as early as the thirteenth century by Zhu Yuansheng — and a fourth, the trigram
configuration of stations 25–28, which the received order satisfies exactly. Using a Boolean-satisfiability
encoding of these rules over the space of orderings preserving the sequence's classical pair structure, we
resolve the conjectures these authors raised. (1) Moore's conjectured compliant order exists: we exhibit
an ordering perfect under both of his rules, differing from the received order by exactly three
adjacent-position edits — through the very anomaly he identified — and prove three edits is minimal.
(2) The same holds with Schulz's third rule added. (3) Decisively: **no ordering preserving the classical pairing satisfies all
four rules simultaneously** — the rules are jointly unsatisfiable, a fact certified by machine-checkable
proof. The exceptions that Zhu Yuansheng, Moore, and Schulz each recorded are therefore not evidence of
damage to a once-perfect original, for no such original could exist; they are the visible seam of a forced
trade-off among competing regularities — precisely the reading Schulz proposed on interpretive grounds in
2011 ("exceptions that prove rules"), for which we supply the exact combinatorial content.

## Structure (6 sections)
1. **The rules and their authors** (fully attributed narrative: Zhu Yuansheng -> Lai Zhide -> Schulz ->
   Moore; the anomaly locus as an eight-century observation). Humanities register.
2. **Method in one page**: the pair-structure space; what a SAT solver decides; what a certificate is;
   the two-way encoding validation (KW-forced tests) in plain language. Verifiability box.
3. **Moore's precursor exists** (witness, printed in full; 3-edit minimality with certificate).
4. **The conflict theorem** (statement, certificate, what was checked by whom: kissat -> DRAT ->
   drat-trim). One paragraph on the data-like character of the trigram rule, honestly.
5. **Reading the received order** — trade-off, not corruption; Schulz's 2011 principle vindicated in
   exact form; what remains open (restricted corruption; tendencies), WITHOUT statistics beyond one
   rarity sentence per rule (cited to the population-measurement record, not developed).
6. **Coda**: the sequence emerges more, not less, deliberate: it sits where its own tradition's rules
   force a choice, keeping exactly one perfectly.

## Defense kit
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
  precursor; published sequences in LITERATURE_RULES_POPULATION_TESTS.md §SAT-decided).
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

![Grouped bar chart of the four conflicting rules: King Wen misses Moore's 2005 parity rule by 2 (16/18), Moore's 1989 rhythm rule by 2 breaks, and Schulz's 1990 gender rule by 2 violations while satisfying the Schulz S25–28 trigram configuration exactly; the grand unified precursor is perfect (0) on the first three and violates the trigram configuration — no pairing-preserving ordering achieves zero on all four.](figures/fig_tr1_rules_tradeoff.png)

*The forced trade-off (§4–5, shared with [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) §5). King Wen (red)
misses the three graded rules by the minimal margins (2 each) and keeps the S25–28 trigram configuration
exactly; the grand unified precursor (green, 3 slot-edits from KW) perfects those three and breaks the
trigram configuration — a binary configuration rule with no graded miss count. The joint-UNSAT
certificate says no pairing-preserving ordering reaches zero on all four axes: the received order's irregularities are the
visible seam of this forced choice, not damage. Generated by
[`viz/report_figures.py`](../viz/report_figures.py); [SVG](figures/fig_tr1_rules_tradeoff.svg).*

## Journal-submission track (dormant — activates only on an operator decision to submit)
- Full prose (sections 1, 5, 6 need the humanities register — operator voice pass essential).
- Print the witness orderings in hexagram-number notation (1..64), not binary.
- Journal track: JCP guidelines; consider Schulz as reader-before-submission (he is the living author
  engaged).
- Coordinate claims with Paper B + the arXiv record (no double-publication of the same theorem as
  a "new" result — Paper A is the primary home of the conflict theorem).

## Extension (v1.6): the conflict's fine structure — three two-rule cores

Adding the next-strongest discriminating rule from the population scoreboard (Schulz's exception
co-location rule, CC-N8) sharpens the theorem in two ways, both certificate-backed and re-verified on
independent hardware:

1. **The five-rule union is unconditionally unsatisfiable** — not merely "no perfect ordering": no
   pairing-preserving ordering satisfies the five rules at ANY repair distance (the near-2/near-3/near-4
   relaxations are all UNSAT as well).
2. **The conflict decomposes into three minimal two-rule cores**: {Moore parity, Schulz S25–28},
   {Moore rhythm, Schulz S25–28}, and {Schulz gender, CC-N8}. Every leave-one-out four-subset of the
   five rules remains unsatisfiable, and each core is a two-rule contradiction on its own. In
   particular, the four-rule system of the main theorem was not a MINIMAL unsatisfiable set — the
   gender rule is not needed for that instance of the conflict. The main theorem's statement is
   unaffected; its anatomy is now finer: the literature's rules do not fail jointly in one tangle,
   they fail in specific pairs.

Certificates: fourteen DRAT proofs covering the union, the repair ladder, all five leave-one-out
subsets, and the cores (archive alongside the original conflict certificates; every one drat-trim
verified, with the full set re-verified against freshly regenerated encodings on a separate machine).

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.5 | 2026-07-04 | Adversarial round 2 corrections: conflict-theorem claims scoped to pairing-preserving orderings; TR-3 weeks-not-months; TR-9 residual dual-convention phrasing |
| v1.6 | 2026-07-04 | Extension: five-rule union unconditionally UNSAT; conflict decomposes into three two-rule minimal cores (14 new certificates, re-verified on independent hardware) |
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
| v1.2 | 2026-07-04 | Figures added |
