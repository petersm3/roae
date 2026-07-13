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
**Update (v1.12, 2026-07-13): the stop-flag is RESOLVED — verdict re-affirmed on a stronger
footing, with a slightly smaller headline number.** The four-class extension's first ingredient
run had measured the rule-perfect population size N_gs **directly** for the first time and found
it outside the derived bracket the v1.7 computation used — a pre-registered stop-and-investigate
flag (v1.10). The investigation is complete: the discrepancy was a defect in the **bracket**, not
in the model, the data, or the new measurement — the "bracket" was the span between two point
estimates that carried no propagated uncertainty, and was never a confidence interval. A four-seed
re-measurement battery puts N_gs = 4.50×10²⁵ (±6% conservative), and all three pre-registered
convergence gates pass; under the measured value the Bayes factor becomes ≈ 5.2×10³–6.3×10³ — still
an order of magnitude above the pre-registered "strong" band in every one of the 24 pre-committed
sensitivity configurations. Details, evidence, and the honest residuals are in the stop-flag
resolution within the Bayesian section.

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
6. **Coda**: the sequence emerges more, not less, coherent: it sits where its own tradition's rules
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
pre-committed 2σ gate. With all three gates green (1σ / 2.0σ / 0.12σ), the pre-registered "all three
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
conventions are reported. The re-measured value is 1.4σ above the Phase-1 single run it re-checks
(5.00×10²⁵) — consistent. No value in the plausible range moves any configuration below "strong";
the resolution changes the headline by a factor of ~0.8 and the evidential footing from a derived,
unquantified-uncertainty ingredient to a directly measured one with stated error.

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
  derived estimates). *This measurement has since been run and its stop-gate episode resolved — the
  direct value is N_gs = 4.50×10²⁵ (±6%); see the stop-flag resolution in the v1.7 section above.*

The axis bundle, numeric priors and grids, the Jeffreys decision bands (as v1.7), a synthetic-draw
calibration that runs BEFORE the KW verdict and can veto an unreliable one, and an adequacy layer
auditing every model against the full published functional battery are all fixed in the frozen design.
The comparison is **report-only, with no promotion path**, and it does not revise the v1.7 two-model
result, which stands as published (if the wider comparison ever dethrones corruption, this section gains
a forward-pointer; it is not rewritten).

**STATUS (v1.12): ingredients collected; verdict not computed.** The instrument wiring and the
ingredient runs — including the direct N_gs measurement, whose stop-gate firing and resolution are
documented in the v1.7 section above — have been executed; the synthetic-draw calibration and the
KW-facing integration have **not** run, and **no Bayes factor, posterior, or verdict exists or is
reported here**. Per the frozen design's own ordering, calibration (with its confusability veto) runs
before any KW-facing verdict, and a set of pre-verdict ingredient gates — hardened after the
stop-flag episode — must pass first; the N_gs solidity gate, including the now-repaired stratified
cross-check, has passed, and the remaining gates and their outcomes will be published with the
results. One ordering-of-operations deviation is disclosed now, in the F11 "honest note" style: the
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
| v1.9 | 2026-07-10 | Pre-registered four-class model comparison (M0 uniform-valid / M_G greedy-builder / M_D global-design / M_C corrupted-precursor) added as a frozen design under F4′/F11 discipline; measurement pending — no Bayes factor, posterior, or verdict reported. Executive summary notes the registration. The v1.7 two-model result stands unchanged. |
| v1.10 | 2026-07-11 | Stop-flag annotation: the direct N_gs measurement ([evidence/r11/](evidence/r11/)) yielded 5.00×10²⁵, outside the v1.7 derived bracket [1.03, 3.57]×10²⁵ — the pre-registered stop-and-investigate gate fired. The v1.7 Bayes verdict is marked UNDER REVIEW pending investigation (neither revised nor re-affirmed). "closes that question as far as data can" tightened to the section's own conditional scope. |
| v1.11 | 2026-07-11 | Process section relocated: the dormant journal-submission checklist moved out of the public report (process content, not findings; now maintained privately). No findings changed |
| v1.8 | 2026-07-04 | Reproducibility completion (TR-audit fixes): F11 bundle completed — `f11_events.json` + generator `f11_events.py` published, so `compute_f11_bf.py` reruns from the bundle alone (verified: reproduces BF 6.6×10³/7.9×10³); F11 instrument (`SOLVE_KNUTH_F11_HIST`, `SOLVE_KNUTH_GENDER_STRICT`) merged into public solve.c (selftest sha unchanged) and documented in SOLVE_C_CLI.md with `SOLVE_KNUTH_MOORE_STRICT`; the v1.6 "fourteen DRAT proofs" fully archived in certificates/ (19 total incl. the three two-rule cores), each mapped in certificates/README.md and covered by verify_all.sh; §Reproduction names every flag explicitly |
| v1.12 | 2026-07-13 | Stop-flag resolution: the v1.10 UNDER REVIEW annotation is closed. Investigation ([evidence/r11/](evidence/r11/)) found the derived bracket [1.03, 3.57]×10²⁵ was never a confidence interval (two point estimates, no propagated uncertainty); a 4-seed direct re-measurement gives N_gs = 4.50×10²⁵ (±6% conservative), with all three pre-registered convergence gates passing (χ² seed-consistency ~1σ; derived-CI cross-path 2.0σ; repaired stratified cross-check 0.12σ — the stratified instrument's strict-prefix composition defect was repaired by an estimator-only, self-test-neutral fix). Under the measured value BF ≈ 5.2×10³ (U) / 6.3×10³ (A) — direction unchanged in all 24 pre-committed configurations; verdict re-affirmed (headline ×0.79 smaller, footing stronger). Weakest-ingredient paragraph updated; four-class section status corrected (ingredients collected, verdict not computed, N_gs solidity gate passed); no theorem or certificate touched |
