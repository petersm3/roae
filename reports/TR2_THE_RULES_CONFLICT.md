# TR-2 — The Rules Conflict: Moore's Precursor, Schulz's Exceptions, and a Joint Impossibility Theorem for the King Wen Sequence
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide below.*

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
New in v1.7: within the three graded rules — where perfection **is** achievable — a pre-registered
Bayesian comparison finds the received order far better explained as a corrupted rule-perfect ordering
than as the work of an arranger holding the rules as soft preferences (Bayes factor ≈ 6.6×10³–7.9×10³,
"strong" on the Jeffreys scale); a two-model comparison conditioned on the literature's rules, not proof
of corruption in any absolute sense. A wider four-class comparison (adding a greedy-builder and a
global-design class plus a uniform-valid null) has since been pre-registered under the same discipline;
its measurement is pending and no result is stated in this report.

Verification model: every load-bearing claim is an artifact check (witness verification or UNSAT certificate).

---

## Abstract

Steve Moore ([1989](../documentation/CITATIONS.md#moore1989), 2005) proposed two design rules for the King Wen sequence, observed that the received
order complies with one at sixteen of eighteen testable positions with both exceptions adjacent, and
conjectured an originally compliant order later altered. Larry Schulz ([1990](../documentation/CITATIONS.md#schulz1990-motifs), [2011](../documentation/CITATIONS.md#schulz2011), [2016](../documentation/CITATIONS.md#schulz2016)) independently
formalized a third rule over [Lai Zhide's](../documentation/CITATIONS.md#laizhide) thirty-six consolidated units, with its own exceptions at the
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
6. **Coda**: the sequence emerges more, not less, deliberate: it sits where its own tradition's rules
   force a choice, keeping exactly one perfectly.

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

Certificates: fourteen DRAT proofs — the union (1), its near-2/3/4 repair ladder (3), all five
leave-one-out subsets (5), the three two-rule cores (3), and two encoding-validation gates
(ccn8-kwfail, ccn8-kwchain-not) — **all archived in [certificates/](certificates/)** alongside the
original five conflict certificates (19 total; each mapped to its `sat.py --emit-cnf` regeneration
command in certificates/README.md and checked by verify_all.sh). Every one drat-trim verified, with
the full set re-verified against freshly regenerated encodings on a separate machine.

## A Bayesian comparison: corruption vs. tendency (v1.7)

The conflict theorem settles what cannot exist: no pairing-preserving ordering perfect under all four
rules. The three **graded** rules — Moore's 2005 parity, Moore's 1989 rhythm, Schulz's 1990 gender rule
(its exceptions first noted by Zhu Yuansheng in the 13th century) — are jointly satisfiable: the grand
precursor of §3 achieves all three exactly, and the received order sits exactly three slot-edits from it,
with all six violations (2+2+2 across the three rules) co-located at the historically flagged locus. §5
left the reading of that residual anomaly open: restricted corruption, or tendencies? This section closes
that question as far as data can, by a pre-registered Bayesian comparison of the two readings the
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

**The result.** Both models are full generative models over the canonical C1–C5 space (the shared
substrate, which cancels), evaluated at the exact received sequence.

- **BF(corruption/tendency) ≈ 6.6×10³** (variant U, uniform edit location) and **≈ 7.9×10³** (variant A,
  bamboo-adjacent-biased) at the primary configuration — both exceed the frozen BF > 100 "strong" band
  by well over an order of magnitude.
- Under the frozen 50:50 model prior, **posterior P(corruption | data) ≈ 0.9998**.
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

**The weakest ingredient, honestly.** The size of the triple-strict (rule-perfect) population, N_gs, is
a **derived** quantity, not a directly pruned count — the single least-precise ingredient in the
computation. Its two independent derivations disagree by ×3.5 (3.57×10²⁵ vs 1.03×10²⁵); per the
strictest-reading rule the **larger** value — which weakens the winning corruption model — is primary,
and every configuration is reported under both. Flipping the verdict down to the strong threshold would
require N_gs to be ~66× the larger estimate, far outside any plausible estimator noise.

**What this does NOT say.** Nothing about who altered the sequence, when, or how; no dating, no
attribution, no reconstruction of events. It licenses no claim beyond the model pair compared: conditional
on the literature's three rules being the relevant regularities, the received sequence is far better
explained as a corrupted rule-perfect ordering than as the output of a soft-preference arranger — whether
the rules are the right lens remains open.

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

## Pre-registered extension (v1.9): a four-class model comparison — design frozen, measurement pending

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
  derived estimates).

The axis bundle, numeric priors and grids, the Jeffreys decision bands (as v1.7), a synthetic-draw
calibration that runs BEFORE the KW verdict and can veto an unreliable one, and an adequacy layer
auditing every model against the full published functional battery are all fixed in the frozen design.
The comparison is **report-only, with no promotion path**, and it does not revise the v1.7 two-model
result, which stands as published (if the wider comparison ever dethrones corruption, this section gains
a forward-pointer; it is not rewritten).

**PENDING — measurement not yet run.** The compute half (instrument wiring, the ingredient runs
including the direct N_gs measurement, the synthetic-draw calibration, and the closed-form integration)
has NOT been executed. **No Bayes factor, posterior, or verdict is reported here** — this subsection
registers the design only. Results, when computed, land in `reports/evidence/r11/` under the frozen
verdict template.

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
| v1.9 | 2026-07-10 | Pre-registered four-class model comparison (M0 uniform-valid / M_G greedy-builder / M_D global-design / M_C corrupted-precursor) added as a frozen design under F4′/F11 discipline; measurement pending — no Bayes factor, posterior, or verdict reported. Executive summary notes the registration. The v1.7 two-model result stands unchanged. |
| v1.8 | 2026-07-04 | Reproducibility completion (TR-audit fixes): F11 bundle completed — `f11_events.json` + generator `f11_events.py` published, so `compute_f11_bf.py` reruns from the bundle alone (verified: reproduces BF 6.6×10³/7.9×10³); F11 instrument (`SOLVE_KNUTH_F11_HIST`, `SOLVE_KNUTH_GENDER_STRICT`) merged into public solve.c (selftest sha unchanged) and documented in SOLVE_C_CLI.md with `SOLVE_KNUTH_MOORE_STRICT`; the v1.6 "fourteen DRAT proofs" fully archived in certificates/ (19 total incl. the three two-rule cores), each mapped in certificates/README.md and covered by verify_all.sh; §Reproduction names every flag explicitly |
