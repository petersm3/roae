# TR-9 — Pricing the Constraints: Description-Length Accounting
*Technical report — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. One caveat is structural, and it frames all the rest: the same
author wrote the claims, the software that checks them, and this report that grades the check.
Verification here is independent in mechanism, never in authorship; no independent party has yet
audited or reproduced any of it (METHODS.md §"Authorship independence").*

⚠ **Two exceptions to the banner's reproduction-command promise, stated here because the banner is
shared boilerplate and is not this report's to amend** (added 2026-09-02, Codex V2-F11 #2): the
ledger's two **Knuth estimates** — **1.3287×10³⁸** (§2, C3 row) and **5.21×10³¹** (§2, C6+C7 row) —
**had, until 2026-09-02, no published full-scale invocation anywhere in the tracked corpus.** The only published
whole-tree command, `solve --estimate-knuth 500000000`, reproduces the *superseded* 5×10⁸ draw
(1.32×10³⁸ at 0.18%), not the 5×10¹⁰-probe definitive run these figures come from; no 5×10¹⁰
invocation appears in any tracked file and `reports/evidence/` archives estimator stdout at 2×10⁹,
5×10⁹, 2×10¹⁰, 4×10¹⁰ and 5.5×10¹⁰ probes but none at 5×10¹⁰. The C6+C7 recipe published 2026-08-29
(`SOLVE_KNUTH_C67=1 ./solve --estimate-knuth 0 $PREFIX`) reproduces the zero-probe prefix ladder, a
different quantity from the sampled headline. Both gaps are recorded at
[TR-4](TR4_SIZE_OF_THE_SPACE.md) §Verification Guide and
[SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md) §Reproducible (both corrected
2026-09-02). **That open fix closed on 2026-09-02** (TR-4 v1.27): both invocations are published with their
thread count — `SOLVE_THREADS=32 ./solve --estimate-knuth 50000000000` and
`SOLVE_KNUTH_C67=1 SOLVE_THREADS=32 ./solve --estimate-knuth 50000000000` — and their stdout is archived at
`reports/evidence/knuth_whole_tree_5e10.out` and `reports/evidence/c67_probe.out`. Neither figure's *value*
was in question here; its *reproducibility* was, and this paragraph stays as the record of the gap.

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

If you had to transmit the King Wen sequence to someone, how many bits would it take — and how many do
the known "design rules" save you? This report prices every rule in bits, the accounting standard of
information theory. The verdict: the classical pairing rule does almost all the work (~146 of ~296
bits) and is provably the *best possible* rule of its kind. That optimality theorem is
[Radisic (2026)](../documentation/CITATIONS.md#radisic2026)'s — still an unrefereed preprint, but no
longer an unverified external dependency: his Lean artifact was **independently rebuilt and
re-verified by this project (2026-07-26), and the theorem is now machine-checked in-repo**
([lean/HammingOptimalMatching.lean](../lean/HammingOptimalMatching.lean), kernel-only `decide`,
axiom base `[propext]` — see [lean/README.md](../lean/README.md)). The optimality
claims — "best possible" and the ~0-bit derivation-convention cost — rest on that machine-checked
uniqueness theorem; **the dominance conclusion does not need even that**: **"C1 dominates the explanation" holds under the family
(selection-cost) convention
regardless**, since even the maximal family charge (~13–19 bits) is small against 146.3. The
no-distance-5 rule roughly breaks even
once its own statement cost is charged; and the celebrated transition-count recipe turns out to cost more to state than it saves — it
is **description, not explanation**. After all known rules are applied, **between about 105 and 139 bits of the
sequence remain unexplained (exact figure depends on which layers are granted explanatory standing: 105.4 = log₂|C1–C7| keeps every cut, even the data-like pins; 139.1 = log₂|C1∩C2∩C4| is the residual against the claimed-explanatory layers alone)** — the honest measure of how much structure is still unaccounted for.
This is the most judgment-dependent report in the suite; its accounting conventions are stated
explicitly so a skeptic can re-price everything under their own.

## Abstract
Rarity numbers (×11,364, 10⁻⁴⁴, …) invite over-reading. The disciplined currency is bits: how much of the
King Wen sequence's information does each constraint *explain*, net of what the constraint itself costs to
state? We fix a two-part MDL framework (two-part minimum description length —
[Rissanen 1978](../documentation/CITATIONS.md#rissanen1978);
[Grünwald 2007](../documentation/CITATIONS.md#grunwald2007)) — an arbitrary ordering of 64 hexagrams costs log₂ 64! = 296.0 bits;
a constraint system K explains 296.0 − log₂|solutions(K)| bits at statement cost L(K) — and compute the
ledger under two declared statement-cost conventions (family selection vs derivation from principle). The
measured result: the classical pairing C1 explains 146.3 bits and, post-[Radisic (2026)](../documentation/CITATIONS.md#radisic2026) (preprint,
machine-verified), is essentially free
to state under the derivation convention — the unique Hamming-optimal comp/rev matching; C2 nets ≈ 0
(**+0.5 to +2.0** — break-even to marginally positive; positive under every coding this corpus states,
corrected 2026-09-02, §2 fn⁷); C5 nets between **−6.3 and −13.9 bits** — its statement costs
1.7–2.5× what it explains; the transition histogram is
confirmed *description*, not explanation; C3's threshold is circular by construction and its 3.0 marginal
bits are not claimed; C6/C7 are data-like and definitionally break-even. The honest thesis: roughly half
the sequence's information is explained — nearly all of it by the pairing — leaving a residual of **105.4
to 139.1 bits** explained by nothing known today (105.4 = log₂|C1–C7|, the most conservative reading; 139.1
= log₂|C1∩C2∩C4|, the residual against the claimed-explanatory layers C1+C2+C4 alone, an exact quantity;
the intermediate C1–C5 reading is ~126.6, which retains the cuts of C3 and C5 — layers this report itself
prices as non-explanatory). This is the most
judgment-laden report in the suite; a dedicated section makes the convention choices and their sensitivity
explicit.

## Sections
1. **The framework (two-part MDL).** Baseline: log₂ 64! = 296.0 bits for an arbitrary ordering. A
   constraint system K explains 296.0 − log₂|solutions(K)| bits, at statement cost L(K); net value =
   compression − statement cost. Conventions, declared up front: solution-set sizes are exact where
   enumerable, otherwise the validated estimator values (the ±0.02% those
   estimates carry is the estimator's relative **standard error**, not a 95% half-width
   — [METHODS.md](METHODS.md) §"Statistics conventions": the tool prints mean ± 1.96·√(v̂ar/N) with
   relerr = SE/mean; the 95% interval is therefore ±1.96·SE ≈ **±0.0006 bits**, still negligible at the
   precision quoted). Statement costs are reported under TWO conventions, because the choice
   is philosophy-laden and a referee should see both: (i) **family convention** — the constraint is
   selected from a declared enumerable family of comparable rules (cost = log₂ of the family size;
   families stated per row); (ii) **derivation convention** — a constraint *derivable* from a stated
   principle costs the principle, not the parameters (post-Radisic, this matters for C1). The
   look-elsewhere accounting for the 28-observable extraction battery (the base of the frozen
   91-observable global ledger — [METHODS.md](METHODS.md) §Global observable ledger) lives in
   [CRITIQUE.md](../documentation/CRITIQUE.md) and is not
   double-counted here.
2. **The measured ledger.**

   | Layer | Solution count | log₂ count | Marginal compression | Statement cost | Net |
   |---|---|---|---|---|---|
   | baseline (any ordering) | 64! | 296.0 | — | — | — |
   | + C1 (pairing) + C4 (start) | 31!·2³¹ | 143.7 | **146.3** (C1) + 6.0 (C4)¹ | ~0 (derived²) / ~13 (family³) | **+133 to +146** |
   | + C2 (no-5) | 7.5706×10⁴¹ (**exact**, orbit-quotient DP `solve --f1-exact-c1c2c4`, 2026-07-04; supersedes the 2026-07-03 estimator value 7.571×10⁴¹ ±0.01%, which it confirms) | 139.1 | 4.5 | ~2.6–4 (family of per-distance bans) | **≈ 0 (+0.5 to +2.0)**⁷ |
   | + C5 (transition multiset) | 1.097051×10³⁹ (**exact, two-instrument** — out-of-core orbit-quotient DP `solve --f1-exact-c1c2c4c5`, 2026-07-16 — [TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md); independently recomputed at full scale 2026-07-25 by `verify.c --ie-count` (inclusion–exclusion transfer-walk — a different algorithm class sharing no code with solve.c): exact MATCH, mod-24 verified ([TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §10(vi)); the mod-24 gate + 4/4 out-of-core ladder further corroborate it; supersedes the estimator value 1.0971×10³⁹ ±0.01%, which it confirms — the exact value lands inside the stated envelope; the 0.0044% figure is the estimate's rounding gap, not a resolved error) | 129.7 | 9.4 | 15.7–23.3⁴ | **−6.3 to −13.9 (descriptive under every convention⁴)** |
   | + C3 (complement ceiling) | 1.3287×10³⁸ (**estimate** — Knuth random-probe, 95% CI [1.3283, 1.3292]×10³⁸, 0.02%) | 126.6 | 3.0 | circular⁵ | ≈ 0 |
   | + C6 + C7 | 5.21×10³¹ (**estimate** — Knuth random-probe, 95% CI [5.13, 5.29]×10³¹, 0.78%; [TR-4](TR4_SIZE_OF_THE_SPACE.md) §4 owns the measurement) | 105.4 | 21.3 | data-like (slot pins: ~20.6 — underived⁶) | ≈ 0 |
   | strongest *principled* literature rule ([Schulz](../documentation/CITATIONS.md#schulz1990-motifs) gender — "strongest" among the rules stated independently of King Wen; the data-like trigram rule scores higher but is descriptive) | — | — | 13.5⁸ | rule text ≈ 10–15⁹ | ≈ 0 to small + |

   **Exact marginals (v1.10, 2026-07-18).** With the analytic cells 64!, 32!·2³², 31!·2³¹ and the
   two DP exacts, every marginal in the C3-free spine is a **ratio of exact integers**: C4 given C1
   = ×64 exactly (6.0000 bits); **C2 given C1∩C4 = ×23.325025987… (4.5438 bits)**; C5 given
   C1∩C2∩C4 = ×690.0850… (9.4306 bits). The rounded Δ-column values above (4.5, 9.4) are these
   exact ratios. Corroboration with a scope caveat: 1/23.325 = **4.2872%** — the long-published
   "~4.3% of pair-constrained orderings" estimate for C2 now lands exactly, *at the C1∩C4
   conditioning*; the C1-only (start-free) fraction is now also exact — **4.29341%**
   (1 in 23.29, start-unpinned; 3-prime CRT over `solve --f1-exact-c1c2 --f1-mod P`, orbit-0 anchored to 2·|C1∩C2∩C4|; 2026-07-25 — the three complete invocations, their residues and the reconstruction are in the Verification Guide below). Corollary (C5's multiset contains no distance-5, so C5 ⟹ C2):
   |C1∩C4∩C5| = |C1∩C2∩C4∩C5| exactly — every C5-containing lattice cell equals its C2-added twin.
   Only the C3 conditional remains sampled (by design; a bounded-state design exists — C3 = 16 + 8·G — but the exact G-channel run is ruled out on cost: TR-11 §10(ii)).

   ¹ C4 fixes the first pair and orientation among 32·2 choices ≈ 6 bits, charged in full — pair AND
   orientation (the orientation bit is definitional — our convention, not a classical attestation: the
   *Xugua* attests that the {Heaven, Earth} pair opens, not the order within it (narrowed 2026-09-01,
   [SPECIFICATION.md](../documentation/SPECIFICATION.md) §Constraints); the former
   "forced-orientation theorem" that would have returned that 1 bit is retracted as false,
   2026-07-26 — see CLAIMS_DECIDED's corrections ledger — so nothing is returned and no ledger
   value changes). ² Radisic 2026: the pairing is the unique Hamming-optimal comp/rev matching — under the
   derivation convention its cost is the optimality principle itself (a one-line statement). ³ Family:
   perfect matchings generated by the K₄ operations (rev-priority, comp-priority, mixed per-orbit choices)
   — ~2¹² comparable members ≈ 12–13 bits (exact: 12.0 bits for {rev, comp} matchings, 19.0 if comp∘rev
   pairings are also admitted). ⁴ Statement-cost bracket for the multiset: full 6-class multiset log₂
   C(68,5) = 23.3 bits; conditioned on C2 (5 usable classes) log₂ C(67,4) = 19.5; marginal-consistent
   price of the 31 unimplied boundary transitions given C1+C2 log₂ C(35,4) = 15.7. **C5 is net-negative
   under all three (15.7 / 19.5 / 23.3) — the verdict is coding-independent**; the ledger reports 15.7
   because the compression column is marginal, a presentational choice rather than a load-bearing one.
   ⁵ C3's threshold (776) is KW's own value — circular by construction,
   priced as data (CRITIQUE.md §"Observable-selection accounting"); its marginal 3.0 bits are NOT claimed
   as explanation. ⁶ C6/C7 pin four
   slots: log₂(choices eliminated) ≈ their own compression — definitionally break-even. The cell's
   parenthetical "~20.6" is **underived**: it is the only cost figure in this ledger with no recorded
   derivation (it is near, but not equal to, the row's 21.3-bit marginal compression, and no
   computation producing 20.6 is on record in the corpus). It is retained, explicitly so labelled,
   because nothing rests on it — the row's verdict is definitional (cost ≈ compression ⇒ net ≈ 0)
   whatever the precise figure. ⁷ ⚠ **[CORRECTED 2026-09-02, prose batch P31]** — this cell read
   "≈ 0 (+2.0 selection-only; **−0.6 to −4** under explicit-grammar codings)" from v1.7 (2026-07-10)
   until today, and the negative endpoints were unreachable from any cost this corpus publishes. Net
   is defined at §1 as compression − statement cost. C2's compression is log₂ 23.325025987… =
   **4.5438** bits (§2, exact marginals). The declared family is the per-distance bans, six members
   ⇒ log₂ 6 = **2.585** ⇒ net **+1.96**, which is the published "+2.0" and is correct. The largest
   statement cost stated anywhere in the corpus is the sensitivity table's "~2.6–**4** (per-distance
   ban family + grammar)" ⇒ net **+0.54**. Reaching −0.6 would need a 5.14-bit cost and −4 a 8.54-bit
   cost; **no explicit-grammar coding producing either is published, or recorded privately** —
   `prior_art_check.sh 'C2 grammar statement cost derivation'` returns `PRIOR_ART=NONE  surfaces
   searched: roae-private *.md, *.tsv, codex_transcripts/; roae *.md; git log --all -S on both repos`.
   The mechanical cause is legible in the sensitivity row itself: its net bracket's lower endpoint was
   the maximum *cost*, sign-flipped, rather than compression minus that cost. The cell now reads the
   bracket its own operands give, **+0.5 to +2.0** — positive under every coding this corpus states.
   The verdict does not move: C2 is break-even to marginally explanatory either way, and remains the
   only narrow rule that reaches break-even. What does move is §4's savings envelope, whose low corner
   consumed the −4; see there. The sibling cells at `documentation/DESCRIPTION_LENGTH.md:36` and
   `:127–129` carry the same defect under a separate adjudication and are not edited here. ⁸ *(Added 2026-09-02, prose lane; mirrors [DESCRIPTION_LENGTH.md](../documentation/DESCRIPTION_LENGTH.md) fn⁸.)* The 13.5 is
   log₂(11,364) = 13.47, and the ×11,364 was measured under **this project's "≤2 violations anywhere" relaxation** of
   the Schulz gender rule, not the form its sources state — parity throughout with at most one exception pair at
   adjacent class positions ([Schulz 1990](../documentation/CITATIONS.md#schulz1990-motifs), elaborated by
   [Cook 2006](../documentation/CITATIONS.md#cook2006)). Re-measured on identical probes, the source-stated form is
   ≈11× rarer (the 2026-07-12 convention-stability note in
   [LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md)), so the rule *as its
   sources state it* compresses log₂(11,364 × 11) ≈ **16.9** bits — about 3.5 bits more than this cell prices. The
   error runs in the direction that makes the literature look weaker: against "rule text ≈ 10–15" the net becomes
   +1.9 to +6.9 rather than ≈ 0 to small +, and the row's verdict does not move. ⁹ The "rule text ≈ 10–15" statement
   cost is **underived** in the same sense as fn⁶'s ~20.6: no computation producing it is on record
   (`prior_art_check.sh 'Schulz rule text statement cost 10-15 bits derivation'` → `PRIOR_ART=NONE`). It is retained,
   so labelled, because the row's verdict is insensitive to it across the whole bracket.
3. **Reading the ledger, row by row.** **C1** is where nearly all the explanation lives: 146.3 bits of
   compression, and its statement cost collapsed in 2026 — Radisic (arXiv:2601.07175 — an unrefereed
   preprint; the ledger leans on the machine verification, not on refereeing — his Lean 4 + Mathlib
   artifact was independently rebuilt and re-verified by this project 2026-07-26, and the theorem is
   machine-checked in-repo: [lean/HammingOptimalMatching.lean](../lean/HammingOptimalMatching.lean))
   proved the pairing is the *unique* Hamming-cost minimizer
   among comp/rev matchings on {0,1}⁶,
   so under the derivation convention it costs only the optimality principle. That upgrade is Radisic's,
   not ours; to our knowledge it is the first *variational* (optimality-principle) first-principles
   derivation of any layer of the constraint system (derivation programs in the Cook tradition derive the
   sequence within richer frameworks — see the
   [uniqueness-conjecture note](../documentation/CITATIONS.md#uniqueness-conjecture); corrections welcome).
   **C2** (no 5-line transitions; [McKenna & McKenna 1975](../documentation/CITATIONS.md#mckenna-mckenna1975)) compresses 4.5 bits
   against a statement cost of the same order (~2.6 bits of selection within the per-distance-ban family,
   rising to ~4 once grammar overhead is charged): net **+0.5 to +2.0** — break-even to marginally
   positive, and positive under every coding this corpus states (fn⁷; the previously published
   negative endpoints were not reachable from any published cost). It is the only narrow
   rule that even *reaches* break-even. **C5** is the ledger's sharpest
   verdict: the transition multiset compresses 9.4 bits but costs 15.7–23.3 bits to state (the
   marginal-consistent price of the 31 unimplied boundary transitions given C1+C2, up to the full 6-class
   weak-composition bound), netting −6.3 to −13.9 — net-negative under every convention, a *measured*
   conclusion (the C2 layer count, now **exact** at 7.5706×10⁴¹
   via the orbit-quotient DP `solve --f1-exact-c1c2c4`, pinned the marginal). C5 earns its keep operationally (it is what makes enumeration
   tractable) but explains nothing: it is confirmed description of King Wen, not explanation. **C3** is
   circular: its threshold (776) is KW's own value, so its 3.0 marginal bits are priced as data and not
   claimed. **C6/C7** pin four slots — definitionally break-even. The strongest *principled* literature rule — strongest among those stated independently of King Wen, since the data-like trigram rule scores higher but describes rather than explains — (the
   Schulz gender rule, ×11,364 — see [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md)) prices at ~13.5 bits gross⁸ against ~10–15 bits of rule text⁹:
   ≈ 0 to small positive.
4. **The residual — the honest thesis.** Knowing everything structural in this table, the sequence retains
   **log₂|C1–C7| = 105.4 bits** of unexplained information — the most conservative reading: unexplained
   by anything known, even the data-like pins. At the other end, the residual against the layers this
   report actually claims as *explanatory* — C1, C2 and C4 only, since the ledger itself prices C3 as
   circular and C5 as confirmed description — is **log₂|C1∩C2∩C4| = 139.1 bits**, an exact quantity
   (the logarithm of the exact 7.5706×10⁴¹ count, ledger §2). The published residual is therefore the
   range **105–139 bits**. The intermediate readings — ~126.6 (C1–C5, retaining the non-explanatory
   cuts of C3 and C5) and 129.7 (dropping C3's cut too) — remain in the table for a reader who grants
   those layers standing; note the direction of the v1.22 correction that produced this range: each
   step toward consistency *enlarges* the residual (126.6 → 129.7 → 139.1), so the claim "explained by
   nothing known today" only strengthens. Roughly half the sequence's information is explained (gross
   compression; net of explicit statement costs, the full envelope over the stated bracket corners is
   **107.2–148.3 bits ≈ 36–50%** — low corner: C1 at the extended-family charge, 146.3 − 19.0 = 127.3,
   plus C2 at its worst published coding (+0.5) and C5 at the literal-coding −20.6; high corner: C1
   derived at
   ~0 cost (+146.3) plus C2 at +2.0, with net-negative C5 simply not transmitted; retaining C5 at its
   best bracket point, −6.3, gives 142.0. ⚠ **[CORRECTED 2026-09-02, prose batch P31]** — the low corner
   was published as **102.7 bits ≈ 35%** from v1.22 (2026-08-06) until today. It was built on the C2
   net endpoint −4, which fn⁷ withdraws as unreachable from any published statement cost; substituting
   the arithmetically supported +0.5 gives 127.3 + 0.5 − 20.6 = **107.2** and 107.2/296.0 = **36.2%**.
   The high corner, 146.3 + 2.0 = 148.3 = 50.1%, is unchanged, as is the 142.0 C5-retaining variant.
   The correction *narrows* the envelope from below; it moves no measurement and no verdict.) — nearly all of it by the classical pairing (now known
   optimal), a marginal 4.5 bits (≈ break-even net) by the no-five rule, and essentially nothing by C5,
   whose statement costs 1.7–2.5× what it explains (net −6 to −14 bits depending on the coding convention):
   the transition histogram is confirmed description, not explanation. The
   rest of the sequence is explained by nothing known today. Design hypotheses and emergence
   hypotheses alike must ultimately be judged in this currency: bits predicted per bit of statement.
5. **Conventions and their sensitivity.** This is the most judgment-laden report in the suite; the numbers
   in column 2 are measurements, but several numbers in columns 5–6 are *choices*, and a skeptical reader
   should see how far the conclusions move under different ones. (a) **C1's net spans +133 to +146**
   under the primary {rev, comp} family (widening to ~+127 if the extended comp∘rev family's 19.0-bit
   charge is taken) — the widest swing in the ledger — but the conclusion "C1 dominates the
   explanation" is convention-robust: even that maximal ~19-bit family charge is small against 146.3. The family
   size is now exact: 12.0 bits for the {rev, comp} matchings the published "~12–13" refers to, or 19.0
   bits if comp∘rev pairings are also admitted — widening the honest low end to +127 (146.3 − 19.0), still overwhelmingly
   positive. (b) **C5's family choice**: the multiset statement cost brackets over three marginal-consistent
   points — log₂ C(35,4) = 15.7 (only the 31 boundary transitions unimplied by C1+C2), log₂ C(67,4) = 19.5
   (5 usable classes), log₂ C(68,5) = 23.3 (full 6-class multiset), up to a literal per-count encoding at
   ~30 — netting C5 between −6.3 and −20.6 across all four points. Two ranges for C5 therefore appear
   in this report and they are not in conflict, so read the scope label on each: the ledger row and the
   sensitivity table publish **−6.3 to −13.9**, the bracket over the three *marginal-consistent*
   codings (15.7 / 19.5 / 23.3); this paragraph and §4's low corner publish **−6.3 to −20.6**, which
   additionally admits the literal per-count encoding at ~30. The ledger's own marginal convention
   picks 15.7 (net −6.3,
   "costs ~1.7×"). Flipping C5's sign would require ≥98.7% of the 52,360 boundary weak-compositions to be
   infeasible — and even then C5 would only reach break-even, never explanatory. The qualitative verdict —
   statement cost exceeds the 9.4-bit compression under every defensible convention — is robust; the "2.5×"
   figure is the full-multiset convention, "1.7×" the marginal one. (c) **What counts as derivable** is philosophy-laden: the derivation convention
   credits C1 because Radisic's principle is independently stated and machine-verified; no comparable
   derivation exists for C2 or C5, and admitting looser "principles" would smuggle parameters into free
   statements. A referee may also ask why Hamming-cost-among-comp/rev-matchings is *the* natural
   optimality criterion, rather than one selected because King Wen's pairing wins it — that
   criterion-selection question is fair, is itself a choice, and is exactly what the dual-convention
   bracket exists to bound: the family convention charges C1 as a selected rule with no appeal to
   naturalness, and the conclusion (C1 dominates) is stable under both readings. (d) **Circularity discipline**: C3/C6/C7 are deliberately zeroed rather than argued over —
   pricing KW's own values as explanation would be self-confirmation
   (CRITIQUE.md §"Observable-selection accounting"). (e) **Estimator
   precision** is not a sensitivity: the ±0.02% quoted on solution counts is the estimator's relative
   **standard error**, and the corresponding 95% interval is ±1.96·SE ≈ ±0.0006 bits. (f) **Look-elsewhere** for
   the observable-extraction battery is accounted in CRITIQUE.md and deliberately not double-counted here;
   a referee preferring it folded in should charge it against the data-like rows, which are already ≈ 0.
   That accounting is denominated in Bonferroni-corrected p-values. A reader who wants the
   meta-selection charge — the cost of selecting the constraint *families themselves* — closed in this
   ledger's own currency does **not** get a closed bound here, and this paragraph previously claimed one
   it could not support. ⚠ **[NARROWED 2026-09-02 — the figure below is CONDITIONAL, not an upper
   bound, and the conditional is on the wrong universe.]** Priced against the corpus's frozen
   *testing-phase* ledger, selecting seven constraints from 91 observables costs log₂ C(91,7) ≈ 32.9
   bits (log₂ C(28,5) ≈ 16.6 for selecting five from the 28-observable discovery battery alone). Three
   things that figure is not. (i) It is **not an upper bound on the quantity it is offered for**: the 91
   is a ledger of *tests performed* — 28 exploratory observables + 58 pre-registered testing-family
   tests + 5 corpus-control predicates — whereas the meta-selection charge is denominated in *candidate
   constraint families*. [METHODS.md](METHODS.md) §"The file drawer — an open gap, stated as such"
   states the gap in terms — "how many constraint families were tested and set aside before the
   published set was fixed? **This suite does not currently publish that denominator**" — and draws
   this exact distinction: the discovery-phase denominator "is a **different quantity** from the
   testing-phase ledger of §'Global observable ledger'", and "reconstructing that testing ledger does
   not close this gap". No tried-and-dropped constraint-family roster exists in the corpus, so the
   charge is not computable from published material and no reader should treat 32.9 as capping it.
   (ii) It is **not an upper bound even on its own denominator**: METHODS.md §"Global observable
   ledger" records (2026-08-30) that the ledger omits the pre-registered H1/H3 family and that
   entering it gives **95**, and log₂ C(95,7) ≈ 33.4 > 32.9. (iii) The "~94 bits to spare" arithmetic
   this paragraph used to bank — 146.3 minus a 19.0-bit extended family charge minus 32.9 — is
   **withdrawn** along with the phrase "maximal joint charge" that introduced it: a subtraction is only
   a margin if the thing subtracted is a maximum, and it is not. What survives, and is all that the
   surrounding argument needs, is the *direction*: every selection charge the corpus can currently
   price is of order tens of bits against C1's 146.3, so no such charge that has been quantified
   overturns C1's dominance — a conditional statement about the charges we can compute, not a proof
   that no larger one exists. Settling it means publishing the tried-and-dropped constraint-family
   roster and its encoding; that is not done, is not queued, and is recorded here as open.
   The charge also largely does not apply row by row:
   C1 and C4's pair choice are classical (attested centuries before any battery existed) and C4's
   orientation is definitional rather than battery-selected, C2 is
   [McKenna & McKenna 1975](../documentation/CITATIONS.md#mckenna-mckenna1975) — prior literature, not
   selected from this project's battery — while the reverse-engineered rows (C3, C5, C6/C7) are
   precisely the ones the ledger already zeroes or prices net-negative.
   (g) **Universality (the additive-constant objection).** A referee versed in Kolmogorov complexity
   will note that any description-length claim is relative to a description language, defined only up
   to an additive machine-dependent constant (Li–Vitányi). The ledger makes **no Kolmogorov claims**:
   every load-bearing quantity in it is a log-cardinality (296.0, 143.7, 139.1, 129.7, 126.6, 105.4)
   or a difference of log-cardinalities (every marginal-compression cell) under **one fixed uniform
   code** over explicitly counted solution sets — machine-independent combinatorial quantities with no
   hidden constant. A cleverer description language could beat this code only by embodying structure
   the uniform code does not know, and whether such structure exists is precisely the report's open
   question, not an accounting artifact: a language that compressed the residual below the stated bits
   would *constitute* the discovery this report says has not happened. Language-dependence is confined
   to the *statement-cost* column, where it is real, acknowledged, and handled by the dual-convention
   bracket (family vs derivation) rather than by any claimed-canonical machine; the single genuinely
   language-dependent cell — the Schulz rule-text estimate at ≈ 10–15 bits — carries a verdict
   ("≈ 0 to small +") that tolerates ±5 bits either way.
   Framework attribution: conventions and framework are ROAE (to our knowledge first applied to this
   object here; corrections welcome via CITATIONS.md); constraint provenance per row: [SPECIFICATION.md](../documentation/SPECIFICATION.md) and
   CITATIONS.md.

## Verification Guide
- The ledger, conventions, and footnotes: [documentation/DESCRIPTION_LENGTH.md](../documentation/DESCRIPTION_LENGTH.md) (this TR preserves its
  numbers exactly)
- Solution counts: exact layers vs [documentation/CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) + enumeration record; estimator
  layer (1.3287×10³⁸ full space) via the validated
  weighted-Knuth instrument — [documentation/SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md) (method + 0.03% self-validation);
  C2 layer count **exact**: `solve --f1-exact-c1c2c4` (7.5706×10⁴¹, divisible by 24 per [TR-5](TR5_SYMMETRY.md);
  the estimator path `SOLVE_KNUTH_RELAX_C5=1` reproduces it to ±0.01% — both documented in
  SOLVE_C_CLI.md); C5 layer count **exact (two-instrument: independently recomputed at full scale 2026-07-25 by `verify.c --ie-count`, exact MATCH; the mod-24 gate, the 4/4 out-of-core ladder and identical cross-mode layer content (byte-identical in the v1-format validation runs) further corroborate it — [TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §10(vi))**: `solve --f1-exact-c1c2c4c5 --f1-out-of-core DIR`
  (1.097051×10³⁹, divisible by 24 — [TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md); the prior
  estimator value 1.0971×10³⁹ ±0.01% matches it to 0.0044%)
- C2 start-free rarity **4.29341%** (1 in 23.29), the exact start-unpinned |C1 ∩ C2|. ⚠ **[REPRODUCTION
  COMMAND PUBLISHED 2026-09-02, prose batch P31]** — this figure shipped from v1.13 (2026-07-25) beside the
  invocation `solve --f1-exact-c1c2`, which is not a command: EXECUTED on a binary built from this
  repository's `solve.c`, it prints `Usage: solve --f1-exact-c1c2 --f1-mod P …` and exits **2**.
  `--f1-mod P` is documented as **required** at
  [SOLVE_C_CLI.md](../documentation/SOLVE_C_CLI.md) §`--f1-exact-c1c2`, and a single run yields only a
  residue, never the count. The complete recipe follows. The engine is the shipped `solve` — the E1
  work used a pre-merge development binary under a different name, and that code is in `solve.c`
  today (`grep -n 'E1 F1U exact' solve.c`). Three runs at distinct 63-bit primes, then offline CRT:

  ```
  ./solve --f1-exact-c1c2 --f1-mod 4611686018427387847 --f1-start-orbit all
  ./solve --f1-exact-c1c2 --f1-mod 4611686018427387817 --f1-start-orbit all
  ./solve --f1-exact-c1c2 --f1-mod 4611686018427387787 --f1-start-orbit all
  ```

  ⚠ Each run peaks at **~13.1 GB** of RAM (SOLVE_C_CLI.md §`--f1-exact-c1c2`) — an 8-core/15 GB host or
  larger; this is not a laptop command. Each prints one `F1U RESULT … residue=<r>` line to stdout. The
  three residues (`--f1-start-orbit all`, 2026-07-25) are

  | modulus P | residue |
  |---|---:|
  | 4611686018427387847 | 4286891890993209602 |
  | 4611686018427387817 | 3462200301019804778 |
  | 4611686018427387787 | 2637508715153043074 |

  and CRT over them reconstructs (rigorously, since |C1 ∩ C2| ≤ |C1| = 32!·2³² ≈ 1.13×10⁴⁵ < p₀p₁p₂ ≈
  9.81×10⁵⁶)

  ```
  python3 -c "
  import math
  N = 48521466573683942822764571590770825624846336     # |C1 & C2|, CRT of the three residues above
  for p, r in [(4611686018427387847, 4286891890993209602),
               (4611686018427387817, 3462200301019804778),
               (4611686018427387787, 2637508715153043074)]:
      assert N % p == r, p                             # each run's residue, recovered from the whole
  print(100 * N / (math.factorial(32) * 2**32))        # 4.2934095 -> the published 4.29341%, 1 in 23.29
  "
  ```

  That check runs in milliseconds and needs neither the binary nor the 13.1 GB: it verifies the
  reconstruction against all three published residues and then divides by |C1| = 32!·2³². The independent
  full-scale gate is the one SOLVE_C_CLI.md specifies — `--f1-start-orbit 0` must return
  2·|C1 ∩ C2 ∩ C4| reduced mod P, with |C1 ∩ C2 ∩ C4| = 757058601340255440651419713405330315358208 from
  the ledger's C2 row; a reader can compute the expected residue without running anything. The full
  per-orbit table (21 residues, seven CRT integers, six orbits plus `all`) lives in the project's
  private run ledger, which is **not publicly accessible**; nothing above depends on it, and the six
  orbit totals sum to the `all` figure published here.
- C1 optimality (statement-cost collapse): Radisic, arXiv:2601.07175 (Lean 4 + Mathlib; independently
  rebuilt + re-verified 2026-07-26) — and machine-checked in-repo: `lean HammingOptimalMatching.lean`
  (kernel-only; `partner_is_unique_minimum`, `kw_realizes_partner`); within-pair
  distance cross-check 2×12 + 4×12 + 6×8 = 120 per documentation/CITATIONS.md §Radisic 2026
- Circularity pricing of C3: documentation/CRITIQUE.md §"Observable-selection accounting" (which grades
  C3's marginal bits as "priced as data, not claimed" and records the threshold's circularity as a
  separate standing limitation)
- Schulz gender rule gross bits: ×11,364 ≈ 13.5 bits (measured under this project's "≤2 violations anywhere" relaxation; the source-stated form is ≈11× rarer ⇒ ≈16.9 bits — §2 fn⁸) — companion registry, [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) /
  [documentation/LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md)
- Arithmetic spot-checks: log₂ 64! = 296.0; log₂(31!·2³¹) = 143.7; log₂ C(68,5) = 23.3 (all reproducible
  in three lines of Python)

## Sensitivity table (planned improvement, v1.3): net bits under both statement-cost conventions

All marginals from the published ledger (documentation/DESCRIPTION_LENGTH.md); the two conventions
bracket the honest range:

| Rule | Compression (bits) | Statement cost: derivation-allowed | Statement cost: family-only | Net (bracket) |
|---|---:|---:|---:|---|
| C1 (pairing) | 146.3 | ~0 (derived from a stated optimality principle) | ~13 (choice within the matching family) | **+133 to +146** |
| C2 (no-5) | 4.5 | ~2.6 (selection only) | ~2.6–4 (per-distance ban family + grammar) | **+0.5 to +2.0** (≈ 0; = 4.5438 − 4 and 4.5438 − 2.585 — corrected 2026-09-02, fn⁷) |
| C5 (transition multiset) | 9.4 | 15.7 (marginal-consistent: 31 boundary transitions) | 23.3 (full 6-class multiset) | **−6.3 to −13.9 (descriptive either way)** |

The verdicts are convention-stable: C1 dominates under both readings, C2 stays marginally explanatory,
and C5's cost exceeds its compression under any defensible statement convention. Every net cell above
is its own row's compression minus its own row's cost, at the precision the cost cell states —
146.3 − 0 / 146.3 − 13, 4.5438 − 2.585 / 4.5438 − 4, 9.4 − 15.7 / 9.4 − 23.3. The C2 row did not obey
that identity between v1.7 and 2026-09-02; see §2 fn⁷.

## Update (v1.3): the residual survives a pre-registered attack

⚠ **Every `--estimate-knuth` command in this document requires a stack limit of at least 16 MB** — `ulimit -s 16384` suffices, and `ulimit -s unlimited` is one way to satisfy it, not the requirement itself. Under the default 8 MB stack the estimator does not start: `main` allocates a ~7.23 MB frame and `estimate_tree_knuth` a further ~1.02 MB (since 2026-08-21 the binary refuses with an actionable message; previously a bare SIGSEGV). *(Added 2026-08-21, an execution-lane finding — `scripts/exec_lane.sh` executes every documented command on a default environment; the same-day warning propagation (`1e4bd04a`) covered the four estimator guides but missed this file.)* *(Narrowed 2026-09-02, prose batch P31: the requirement had been published as `ulimit -s unlimited`, which is a sufficient setting mistaken for a necessary one — and one that a container with a hard 32 MB stack cap cannot even apply. `solve.c`'s preflight tests `rlim_cur != RLIM_INFINITY && rlim_cur < 16UL*1024*1024` and its message names ">= 16 MB". EXECUTED on a locally built binary: under `ulimit -s 8192` it refuses as documented and exits 1; under `ulimit -s 16384` the estimator runs to completion. `solve.c`'s own remedy line still prescribes only `unlimited` and is queued to offer both. Twelve sibling sites outside this report carry the same over-strict wording and are reported, not touched here.)*

Thirteen ordering-layer functionals, each drawn from a literature axis and registered with thresholds
BEFORE measurement (documentation/CRITIQUE.md), were scored against the full population (2×10⁹ probes,
2026-07-04). All thirteen: null. The ~126 unexplained bits (the C1–C5-layer reading of the residual —
the population this battery was scored against; the published range is 105–139, v1.22) therefore survive their first systematic
literature-guided assault — strengthening this report's central claim that no currently known rule
explains the second half of the sequence's information content. Evidence: the archived tier-1 run
output [evidence/f4p_tier1.out](evidence/f4p_tier1.out) (all 13 scoreboard rows + full per-functional
value histograms); rerun via `SOLVE_KNUTH_SCORE_F4P=1 SOLVE_KNUTH_F4P_HIST=1 ./solve --estimate-knuth
2000000000` with the two-language KW gate `./solve --f4p-verify` vs `solve.py --f4p-verify`
(flags and gates documented in SOLVE_C_CLI.md).

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
| v1.3 | 2026-07-04 | Pre-registered F4' null result added (residual survives); convention-sensitivity table added |
| v1.5 | 2026-07-04 | Adversarial round 2 correction: residual dual-convention phrasing |
| v1.6 | 2026-07-04 | Reproducibility completion: C2-layer count adopted as the exact 7.5706×10⁴¹ (`solve --f1-exact-c1c2c4`, replacing the ±0.01% estimator figure it confirms); F4' tier-1 evidence published (evidence/f4p_tier1.out) and cited; instrument flags (`SOLVE_KNUTH_SCORE_F4P`, `SOLVE_KNUTH_RELAX_C5`) now documented in SOLVE_C_CLI.md |
| v1.7 | 2026-07-10 | Referee-hardening (explicit-coding MDL pass): C2 net restated +1.6 → ≈ 0 (break-even, sign convention-dependent); C5 net widened −13.9 → bracket −6.3 to −13.9 (the marginal-consistent statement cost of the 31 unimplied boundary transitions given C1+C2 is log₂ C(35,4) = 15.7, net −6.3); §5 sensitivity paragraph rewritten with the explicit three-point C5 bracket (15.7/19.5/23.3, literal ~30) + the sign-flip bound and exact C1 family sizes (12.0/19.0 bits); sub-0.1-bit rounding fixes C2 4.6→4.5, C6+C7 21.2→21.3; abstract, executive summary, footnote 4, and sensitivity table made consistent. No conclusion changes (C5 descriptive under every convention; C1 dominant). Mirrors DESCRIPTION_LENGTH.md. |
| v1.8 | 2026-07-11 | Radisic status labeled at the load-bearing citations ("preprint, machine-verified" — the ledger leans on the checkable Lean artifact, not refereeing); §5(c) gains the criterion-selection acknowledgment (why Hamming-optimality counts as natural is itself a choice; the dual-convention bracket bounds it). No numbers change |
| v1.9 | 2026-07-16 | C5-layer count adopted as the exact 1.097051×10³⁹ (out-of-core symmetry-quotient DP, [TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md); the prior estimator value 1.0971×10³⁹ ±0.01% matches it to 0.0044%, ratio 0.999956); ledger row and Verification Guide flipped estimate → exact. All bits values unchanged (log₂ = 129.7); C5's net and verdict unchanged (descriptive under every convention); the C3 layer and the flagship 1.3287×10³⁸ remain estimates |
| v1.10 | 2026-07-18 | **Exact-marginals note added to the ledger (§2)**: with the analytic cells (64!, 32!·2³², 31!·2³¹) and the two DP exacts, every C3-free marginal is a ratio of exact integers — C4\|C1 = ×64 (6.0000 bits), C2\|C1∩C4 = ×23.325025987… (4.5437 bits; 1/23.325 = 4.2872%, landing the published ~4.3% estimate exactly AT THIS CONDITIONING — the C1-only fraction stays an estimate), C5\|C1∩C2∩C4 = ×690.0850… (9.4306 bits); plus the C5 ⟹ C2 lattice corollary (\|C1∩C4∩C5\| = \|C1∩C2∩C4∩C5\|). No bits values, nets, or verdicts change (the Δ column already carried these ratios rounded); the C3 layer and the flagship remain estimates. Mirrors DESCRIPTION_LENGTH.md |

*Draft-stage corrections (2026-07-04, adversarial replication review): log₂(31!·2³¹) corrected 144.4 →
143.7 (C4 6.0, C2 marginal 4.6, C2 net +1.6 — mirrors the public DESCRIPTION_LENGTH.md correction;
**both C2 figures are the 2026-07-04 values and were themselves superseded six days later by v1.7
above — marginal 4.6 → 4.5, net +1.6 → ≈ 0 (break-even, sign-convention-dependent). This dated note
preserves what that draft-stage pass produced rather than rewriting it; the live values are the
ledger's in §2**);
residual parenthetical reworded to match its arithmetic (the 126.6 figure retains C3's cut; dropping C3
too gives 129.7). Statement-cost convention families for the three priced rows were tightened per the review before
v1.0.*
| v1.11 | 2026-07-20 | **Dependency and precision disclosures (adversarial-review F-2a, F-2d, F-17, F-10).** F-2a/F-2d: the C5 exact count is tagged **single-instrument** in both the ledger row and the Verification Guide — mod-24 gate, 4/4 out-of-core ladder and byte-identical layer files corroborate it, but it has not been independently recomputed at full scale (TR-11 §10(vi)). F-17: the executive summary now discloses that C1's "essentially free to state" upgrade rests on Radisic (2026), an external, unrefereed preprint whose Lean artifact is not bundled here, and states that the **"C1 dominates" conclusion holds under the family convention regardless** — even the maximal family charge (~13–19 bits) is small against 146.3. F-10: "strongest literature rule" qualified to strongest *principled* rule, since the data-like trigram rule scores higher but describes rather than explains. No bit value changed |
| v1.12 | 2026-07-22 | **Consistency sweep (mirrors TR-11 v1.4/v1.9; no value changed).** The C5 ledger row's "confirms to 0.0044%" replaced with the suite's standard hedge: the exact value lands inside the estimate's stated ±0.01% envelope, and the 0.0044% figure is the estimate's five-sig-fig rounding gap, not a resolved estimator error (TR-11 v1.4 / TR-4 v1.11). The Verification Guide's "byte-identical layer files" corroboration now states the format caveat: byte-identical in the v1-format validation runs; under current defaults the two modes' layer files are content-identical but byte-different (TR-11 §10(vi) precision note). No bit value, count, or conclusion changed |
| v1.13 | 2026-07-25 | **C2 C1-only (start-unpinned) rarity now exact.** §2's "the C1-only fraction remains an estimate" is superseded: the start-unpinned \|C1∩C2\| was computed exactly (3-prime CRT, `solve --f1-exact-c1c2`, orbit-0 anchored to 2·\|C1∩C2∩C4\|), giving **4.29341%** (1 in 23.29) — consistent with the retired ~4.3% MC estimate and 1.0014× above the pinned 4.2872%. Mirrors SPECIFICATION.md + DESCRIPTION_LENGTH.md. No other bit value changed |
| v1.14 | 2026-07-26 | **Radisic dependency downgraded from "external, unbundled" to "independently re-verified + machine-checked in-repo" (hardening item 1).** Radisic's arXiv:2601.07175 Lean 4 + Mathlib artifact (arXiv ancillary source) was rebuilt from scratch on a clean VM: `lake build` exit 0, zero `sorry`/`admit`/axiom declarations, `#print axioms` audited on the 13 main theorems (standard axioms; `native_decide` compiler-trust confined to his weight-conservation/robustness layers). The comp/rev optimality theorem itself is now proved in-repo in lean/HammingOptimalMatching.lean — kernel-only `decide`, axiom base `[propext]`, including the matching-level global uniqueness statement (`partner_is_unique_minimum`), the KW realization (`kw_realizes_partner`), and the full-K₄ scope guard (`full_k4_can_do_192`). The F-17 disclosure language in the executive summary, §3, and the Verification Guide updated accordingly. Result credit remains Radisic's. No bit value changed |
| v1.15 | 2026-07-30 | **Observable-count precision (novelty-gate editorial pass).** §1's "~30-observable extraction battery" replaced with the exact figure: the **28-observable** extraction battery, identified as the base of the frozen **91-observable** global ledger (METHODS.md §Global observable ledger: 28 exploratory + 58 + 5 = 91). A tilde replaced by the frozen exact count; no value, ledger row, or verdict changed |
| v1.16 | 2026-08-01 | **Arithmetic-consistency fix (2026-08-01 in-house calibration review).** §5(a) quoted the comp∘rev-admitted low end as both "~+127" and "+125" two sentences apart; 146.3 − 19.0 = 127.3, so **+127** is correct and the "+125" is corrected. No ledger row, measurement, or conclusion changed |
| v1.17 | 2026-08-01 | **Rounding + ordering nits (2026-08-01 calibration review).** §2's exact marginal for C2 given C1∩C4 reads 4.5438 bits, not 4.5437 (log₂ 23.325025987 = 4.543807; the companion 6.0000 and 9.4306 figures already rounded correctly). Revision History rows re-sorted chronologically — v1.8 had preceded v1.7 and v1.13 had preceded v1.12; for a suite whose versioning policy is an audit trail, row order is load-bearing. No ledger value, measurement, or conclusion changed |
| v1.18 | 2026-08-01 | **Three dangling section pointers retargeted (serialized cross-file pass, unit r70-serialize).** §2 fn⁵, §5(d) and the Verification Guide each cited "CRITIQUE.md Q1" for the circularity pricing of C3. CRITIQUE.md has no Q-numbered sections and never had any — the pointer was unresolvable for every reader who followed it, and GATE 4 could not see it because only the *file* half was a markdown link (the file resolves; the "Q1" is plain prose). All three now name the section that actually carries the material — CRITIQUE.md §"Observable-selection accounting", which grades C3's marginal bits as "priced as data, not claimed" and records the threshold's circularity as a separate standing limitation. The identical pointer in [documentation/DESCRIPTION_LENGTH.md](../documentation/DESCRIPTION_LENGTH.md) (the ledger this TR preserves) and in [TR-2](TR2_THE_RULES_CONFLICT.md) §4 was corrected in the same pass, and `scripts/doc_gates.sh` GATE 4 now checks plain-text section references of the form `FILE.md §"Name"` / `FILE.md Q<n>` so the class cannot recur silently. No ledger row, number, or conclusion changed |
| v1.19 | 2026-08-02 | **The two estimated ledger cells now say so (decision #23 propagation, unit rec-65-23-56).** §2's ledger labels its exact cells emphatically — "(**exact**...)" on C2, "(**exact, two-instrument**...)" on C5 — while the two ESTIMATED cells, 1.3287×10³⁸ (C3) and 5.21×10³¹ (C6+C7), carried a bare number. In a table where siblings are explicitly marked exact, an unmarked cell reads as one more exact count, and 5.21×10³¹ is the headline figure of the suite's central negative result — the one restatement that must never shed its label. Both cells now carry **estimate** with the 95% CI from [METHODS.md](METHODS.md), and the C6+C7 cell points at [TR-4](TR4_SIZE_OF_THE_SPACE.md) §4, which owns the measurement. The identical rows in [documentation/DESCRIPTION_LENGTH.md](../documentation/DESCRIPTION_LENGTH.md) (the ledger this TR preserves) were fixed in the same pass, per the v1.18 precedent. Note GATE 5 of `scripts/doc_gates.sh` could not have caught this: it fires on a status token contradicting METHODS, and these cells carried no status token at all. No bit value, marginal, or conclusion changed |
| v1.20 | 2026-08-02 | **Two superseded C2 figures marked as superseded in the draft-stage note (retracted-figure sweep, unit drain-2).** The dated *Draft-stage corrections (2026-07-04)* paragraph in this Revision History quotes "C2 marginal 4.6" and "C2 net +1.6". Both were restated by **v1.7** (2026-07-10) — 4.5 and ≈ 0 — and the paragraph carried no marker, while sitting BELOW the v1.7 row that supersedes it, so a reader going top-to-bottom met the correction first and the superseded pair second, in an order that reads as though +1.6 were the later value. Nothing is deleted: a dated note is a record and must keep saying what that pass produced. A supersession clause is added instead. This is the same class TR-11 v1.14 fixed when its §4 still asserted TR-9's "+1.6"; the sweep that found it walked every TR revision row that retracts a figure and grepped the corpus for that figure, and this was the only live survivor (the `≈10×`, `1.4σ above` and `Theorem 6` hits are all meta-mentions in retraction narrations). No ledger row, bit value, marginal, or conclusion changed |
| v1.21 | 2026-08-06 | **The MDL framework cited where it is introduced (citation audit, UNASKED-7).** The Abstract introduced "a two-part MDL framework" without naming anyone — [CITATIONS.md](../documentation/CITATIONS.md#rissanen1978) has long called Rissanen 1978 "the methodological foundation of TR-9's bit-ledger", but the pointer ran only in the direction a reader will not travel; this report itself never named him. The Abstract now cites [Rissanen 1978](../documentation/CITATIONS.md#rissanen1978) and [Grünwald 2007](../documentation/CITATIONS.md#grunwald2007) at the framework's introduction, mirrored in [DESCRIPTION_LENGTH.md](../documentation/DESCRIPTION_LENGTH.md) §Framework. No bit value, ledger row, or conclusion changed |
| v1.22 | 2026-08-06 | **The residual's upper endpoint made consistent with the ledger's own verdicts — the range WIDENS to 105–139 (MDL/Kolmogorov-literacy audit).** Four repairs. (1) The published range 105–127 stopped at 126.6, a figure that *retains the bit-cuts of C5 and C3* — the two layers this report itself classifies as non-explanatory (C5 "confirmed description, not explanation"; C3 circular by construction). The strictly consistent endpoint is the residual against the claimed-explanatory layers alone: **log₂\|C1∩C2∩C4\| = 139.1 bits** — a figure that already sat in the ledger (§2, the 139.1 row) and had never been named as a residual endpoint. The range is now **105–139**; 105.4 remains the most-conservative endpoint, and the intermediate readings 126.6 / 129.7 stay in §4 explicitly labelled as retaining non-explanatory cuts. Every step of the correction ENLARGES the residual (126.6 → 129.7 → 139.1) — this strengthens, not weakens, the central claim. Mirrored in DESCRIPTION_LENGTH.md (whose "residual against honestly-explanatory structure" label on the C5-and-C3-retaining 126.6 was wrong and is fixed), reports/README.md, README.md, TR-10, SOLVE_SUMMARY.md. (2) §5(f)'s deferral of the meta-selection cost to CRITIQUE's p-value accounting is closed *in bits*: selecting all 7 constraints from the frozen 91-observable ledger costs at most log₂ C(91,7) ≈ 32.9 bits (discovery battery alone: log₂ C(28,5) ≈ 16.6); dominance survives with ~94 bits to spare. (3) New §5(g): the Li–Vitányi additive-constant objection answered — the ledger makes no Kolmogorov claims; every load-bearing quantity is a log-cardinality under one fixed uniform code. (4) §4's "~100–134 bits, ≈ 35–45%" net-savings endpoints were undocumented corner picks; restated as the full envelope over the stated bracket corners, **102.7–148.3 ≈ 35–50%**, with the corner arithmetic shown. Also: the C6/C7 "~20.6" cost cell — the only cost cell with no derivation on record — is now explicitly labelled underived (fn⁶); nothing rests on it |
| v1.23 | 2026-09-01 | **Footnote ¹'s C4 epithet narrowed to definitional; the 6-bit charge does not move (the 2026-08-30 correction propagated).** [METHODS.md](METHODS.md) §"Constraint set" established on 2026-08-30 that the *Xugua* attests the opening **pair**, not the order within it, so C4's orientation is this project's own convention rather than a classical inheritance; the pedigree the classical record does carry is C1's pairing rule (孔穎達《周易正義·序卦傳疏》, 二二相耦，非覆即變) together with C4's *pair choice*. §2 fn¹ still gave the orientation bit the wider epithet; it now mirrors fn¹ of [DESCRIPTION_LENGTH.md](../documentation/DESCRIPTION_LENGTH.md) — the ledger this report preserves — clause for clause. **The charge is unchanged**: C4 is still priced at its full ≈6 bits, pair AND orientation. A bit that is definitional returns nothing to the ledger for exactly the reason an attested one returns nothing — only the retracted forced-orientation theorem would have returned it, and that theorem is false. §5's meta-selection paragraph was narrowed in the same pass: it called C1 and C4 alike "classical", which over-reaches on the orientation; it now scopes the classical pedigree to C1 and C4's pair choice and records the orientation as definitional rather than battery-selected. The row-by-row argument is untouched — neither is a product of this project's 91-observable battery, which is the only thing that paragraph turns on. No ledger row, bit value, marginal, residual endpoint, or conclusion changed |
| v1.24 | 2026-09-02 | **Six adjudicated defects (Codex V2-F11, prose batch P31); one claimed bound withdrawn, one net-bit row corrected, two commands made runnable.** (1) **§5(f)'s meta-selection bound is withdrawn as a bound.** It priced constraint-family selection against the frozen **91-observable** ledger at "at most log₂ C(91,7) ≈ 32.9 bits" and banked dominance surviving the **maximal joint charge** with **~94 bits to spare**. The 91 counts *tests performed*, not candidate constraint families, and [METHODS.md](METHODS.md) §"The file drawer" states in terms that the constraint-family denominator **is not published** and is "a different quantity" from the testing-phase ledger — so the figure is conditional on the wrong universe and caps nothing. It is not an upper bound on its own denominator either: METHODS.md §"Global observable ledger" recorded on 2026-08-30 that entering the omitted H1/H3 family gives **95**, and log₂ C(95,7) ≈ 33.4 > 32.9. Both phrases are retired and registered; 32.9 stays, relabelled conditional. What survives is the direction, not a margin. (2) **The C2 sensitivity/ledger net bracket is corrected, `−0.6 to −4` → `+0.5 to +2.0`** (§2 fn⁷): net is compression − cost, C2's compression is 4.5438 bits and the largest cost the corpus publishes is 4, so every published coding gives a POSITIVE net; −0.6 would need a 5.14-bit cost and −4 an 8.54-bit one, and no such explicit-grammar coding is published or privately recorded. The verdict is unchanged — C2 remains break-even to marginally explanatory, the only narrow rule that reaches break-even. (3) **§4's savings-envelope low corner moves 102.7 → 107.2 bits, ≈ 35% → 36%**, because it consumed the withdrawn −4: 127.3 + 0.5 − 20.6 = 107.2. The high corner 148.3 ≈ 50% and the C5-retaining 142.0 are unchanged; the envelope narrows from below only. (4) **The two exceptions to the report's opening promise are now disclosed on the page.** The banner's "Every MEASURED result carries a reproduction command" is shared boilerplate, byte-identical across all eleven TRs and enforced as such by `doc_gates.sh` GATE 9, so it is not this report's to amend; the exception is stated in its own paragraph immediately below it instead. The ledger's two Knuth estimates, 1.3287×10³⁸ and 5.21×10³¹, have no published full-scale invocation anywhere in the tracked corpus — the only published whole-tree command reproduces the superseded 5×10⁸ draw (TR-4 §Verification Guide and SEARCH_SPACE_SIZE.md, both corrected 2026-09-02), and the 2026-08-29 `SOLVE_KNUTH_C67` recipe reproduces the zero-probe prefix ladder, not the sampled headline. (5) **The C2 start-free rarity 4.29341% gains a real reproduction command.** It shipped beside `solve --f1-exact-c1c2`, which EXECUTES to `Usage: ...` and **exit 2** — `--f1-mod P` is required and one run yields only a residue. The Verification Guide now publishes the three 63-bit primes, the three complete invocations, their residues, the CRT reconstruction and the arithmetic from it to the percentage, all checkable offline without the ~13.1 GB run. (6) **The stack requirement is narrowed to what the binary enforces**: at least 16 MB (`ulimit -s 16384`), of which `ulimit -s unlimited` is one sufficient setting — EXECUTED both ways on a locally built binary. **No solution count, log-cardinality, marginal compression, residual endpoint or verdict changes.** |
| v1.25 | 2026-09-02 | **The reproduction-command exception narrowed to history (code batch V-1, Codex V2-19 #3; wording only).** The banner-exception note above §1 recorded that the ledger's two Knuth estimates had no published full-scale invocation. TR-4 v1.27 publishes both 5×10¹⁰ invocations with their thread count and archives their stdout under `reports/evidence/`; the note now says so and keeps the gap on record. No figure, bit value or verdict moves |
| v1.26 *(current)* | 2026-09-02 | **The Schulz gender row's two unqualified cells footnoted at all three of their sites (prose lane; Codex V2-F35 #2, the sibling of DESCRIPTION_LENGTH.md fn⁸/fn⁹).** The 13.5-bit gross figure at the §2 ledger cell, the §3 prose and the Verification Guide line is log₂(11,364) measured under this project's ≤2-violations relaxation, not the source-stated rule, which is ≈11× rarer (≈16.9 bits); and the "rule text ≈ 10–15" cost is underived (`PRIOR_ART=NONE`), labelled as fn⁶ labels its ~20.6. The charge's census named two TR-9 sites; measured, there are three — the Verification Guide line is the one a replicator runs. **No count, bound, net-bit bracket or verdict moves**; the error runs against the literature, so the row's ≈ 0 verdict holds a fortiori. |
