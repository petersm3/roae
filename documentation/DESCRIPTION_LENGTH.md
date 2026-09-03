# Pricing the Constraint System: Description-Length Accounting

**Question:** rarity numbers (×11,364, 10⁻⁴⁴, …) invite over-reading. The disciplined currency is bits:
how much of the King Wen sequence's information does each constraint *explain*, net of what the
constraint itself costs to state? This document fixes the conventions and computes the ledger.

## Framework (two-part MDL)

The framework is the two-part minimum-description-length principle
([Rissanen 1978](CITATIONS.md#rissanen1978); [Grünwald 2007](CITATIONS.md#grunwald2007));
ROAE applies it to the King Wen object. An arbitrary ordering of 64 hexagrams costs **log₂ 64! = 296.0 bits**. A constraint system K explains
`296.0 − log₂|solutions(K)|` bits of the sequence, at a statement cost L(K). Net value =
compression − statement cost. Conventions, declared up front:

- **Solution-set sizes** are exact where enumerable, otherwise the validated estimator values. The CI
  in bits is negligible at the precision quoted, but it must be stated in the right currency: the
  ±0.02% those estimates carry is the estimator's relative **standard error**, not a 95% half-width
  ([METHODS](../reports/METHODS.md) §"Statistics conventions": the tool prints mean ± 1.96·√(v̂ar/N) with
  relerr = SE/mean), so the 95% interval is ±1.96·SE ≈ **±0.0006 bits** — the same conversion
  [TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md) §1 carries. This bullet published the 1-SE
  conversion, understating the 95% interval by 1.96×, until 2026-09-02 (see the correction note below).
- **Statement costs** are reported under TWO conventions, because the choice is philosophy-laden and a
  referee should see both: (i) **family convention** — the constraint is selected from a declared
  enumerable family of comparable rules (cost = log₂ of the family size; families stated per row);
  (ii) **derivation convention** — a constraint that is *derivable* from a stated principle costs the
  principle, not the parameters (post-[Radisic](CITATIONS.md#radisic2026) — preprint, independently
  re-verified + machine-checked in-repo, [lean/HammingOptimalMatching.lean](../lean/HammingOptimalMatching.lean) — this matters for C1).
- The look-elsewhere accounting for the 28-observable extraction battery (the base of the frozen
  91-observable global ledger — [METHODS](../reports/METHODS.md) §"Global observable ledger") lives in
  [CRITIQUE.md](CRITIQUE.md) and is not double-counted here. In this ledger's own currency the
  meta-selection charge — the cost of selecting the constraint *families themselves* — has **no closed
  bound**, and this bullet claimed one until 2026-09-02. Priced against that testing-phase ledger,
  selecting seven constraints from 91 observables costs log₂ C(91,7) ≈ 32.9 bits (log₂ C(28,5) ≈ 16.6
  for selecting C1–C5 from the 28-observable discovery battery alone). Both figures are
  **conditional, and conditional on the wrong universe**: the 91 is a ledger of *tests performed*,
  whereas the meta-selection charge is denominated in *candidate constraint families*, and
  [METHODS](../reports/METHODS.md) §"The file drawer — an open gap, stated as such" states in terms
  that this suite does not publish that denominator and that reconstructing the testing ledger does
  not close the gap. Nor is 32.9 a bound even on its own denominator: METHODS §"Global observable
  ledger" records (2026-08-30) that the ledger omits the pre-registered H1/H3 family and that
  entering it gives **95**, whence log₂ C(95,7) ≈ 33.4 > 32.9 — the published 91 is retained there
  "as a disclosure, not as a defence". What survives is the *direction*, not a margin: every
  selection charge this corpus can currently price is of order tens of bits against C1's 146.3.
  The withdrawal follows [TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md) §5(f), where the same
  bound was withdrawn on 2026-09-02; the universality (additive-constant) discussion is at
  TR-9 §5(g).

## The ledger

| Layer | Solution count | log₂ count | Marginal compression | Statement cost | Net |
|---|---|---|---|---|---|
| baseline (any ordering) | 64! | 296.0 | — | — | — |
| + C1 (pairing) + C4 (start) | 31!·2³¹ | 143.7 | **146.3** (C1) + 6.0 (C4)¹ | ~0 (derived²) / ~13 (family³) | **+133 to +146** |
| + C2 (no-5) | **7.5706×10⁴¹ — EXACT** (757,058,601,340,255,440,651,419,713,405,330,315,358,208; S4-orbit dynamic program, 2026-07-04) | 139.12 | 4.5 | ~2.6–4 (family of per-distance bans) | **≈ 0 (+0.5 to +2.0)**⁷ |
| + C5 (transition multiset) | **1.097051×10³⁹ — EXACT, two-instrument** (1,097,051,278,789,181,790,036,112,071,176,579,186,688; out-of-core S4-orbit dynamic program, 2026-07-16; independently recomputed at full scale 2026-07-25 by verify.c's IE transfer-walk engine — exact match, mod-24 verified, [TR-11](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §10(vi)) | 129.7 | 9.4 | 15.7–23.3⁴ | **−6.3 to −13.9 (descriptive under every convention⁴)** |
| + C3 (complement ceiling) | **1.3287×10³⁸ — ESTIMATE** (Knuth random-probe, 95% CI [1.3283, 1.3292]×10³⁸, 0.02%) | 126.6 | 3.0 | circular⁵ | ≈ 0 |
| + C6 + C7 | **5.21×10³¹ — ESTIMATE** (Knuth random-probe, 95% CI [5.13, 5.29]×10³¹, 0.78%; [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) §4 owns the measurement) | 105.4 | 21.3 | data-like (slot pins: ~20.6 — underived⁶) | ≈ 0 |
| strongest *principled* literature rule ([Schulz](CITATIONS.md#schulz1990-motifs) gender — "strongest" among rules stated independently of King Wen; the data-like trigram rule scores higher but is descriptive) | — | — | 13.5⁸ | rule text ≈ 10–15 — underived⁹ | ≈ 0 to small + |

¹ C4 fixes the first pair and orientation among 32·2 choices ≈ 6 bits, charged in full — pair AND
orientation (the orientation bit is definitional — our convention, not a classical attestation: the
*Xugua* attests that the {Heaven, Earth} pair opens, not the order within it (narrowed 2026-09-01,
[SPECIFICATION.md](SPECIFICATION.md) §Constraints); the former
"forced-orientation theorem" that would have returned that 1 bit is retracted as false, 2026-07-26 —
see [CLAIMS_DECIDED.md](CLAIMS_DECIDED.md) — so nothing is returned and no ledger value changes).
² Radisic 2026 (arXiv preprint; his Lean 4 + Mathlib artifact was independently rebuilt and
re-verified 2026-07-26, and the theorem is machine-checked in-repo —
[lean/HammingOptimalMatching.lean](../lean/HammingOptimalMatching.lean), kernel-only): the pairing is
the unique Hamming-optimal comp/rev matching — under the derivation
convention its cost is the optimality principle itself (a one-line statement).
³ Family: perfect matchings generated by the K₄ operations (rev-priority, comp-priority, mixed per-orbit
choices) — ~2¹² comparable members ≈ 12–13 bits.
**Exact marginals (2026-07-18, mirrors TR-9 v1.10):** every C3-free marginal is now a ratio of
exact integers — C4|C1 = ×64 exactly (6.0000 bits); C2|C1∩C4 = ×23.325025987… (4.5438 bits;
1/23.325 = 4.2872%, the published ~4.3% C2-rarity estimate landing exactly at this conditioning —
the C1-only (start-unpinned) fraction is now also exact — 4.29341%, 3-prime CRT over `solve --f1-exact-c1c2 --f1-mod P`, 2026-07-25; the bare `solve --f1-exact-c1c2` published here until 2026-09-02 is a usage error, exit 2 — the three complete invocations, their residues and the CRT reconstruction are published at [TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md) §Verification Guide); C5|C1∩C2∩C4 = ×690.0850… (9.4306 bits). Corollary
(C5 ⟹ C2): |C1∩C4∩C5| = |C1∩C2∩C4∩C5| exactly. The C3 conditional remains sampled by design.

⁴ Statement-cost bracket for the multiset. Full 63-transition multiset over all 6 distance classes: log₂ C(68,5) = 23.3 bits; conditioning on C2 (5 usable classes): log₂ C(67,4) = 19.5; marginal-consistent price given C1+C2 (only the 31 boundary transitions are unimplied): log₂ C(35,4) = 15.7. The ledger's compression column is marginal, so the marginal price 15.7 is the internally consistent choice; every choice leaves C5 net-negative.
⁵ C3's threshold (776) is KW's own value — circular by construction, priced as data
([CRITIQUE.md](CRITIQUE.md) §"Observable-selection accounting"); its marginal 3.0 bits are NOT claimed as
explanation.
⁶ C6/C7 pin four slots: log₂(choices eliminated) ≈ their own compression — definitionally break-even.
The cell's parenthetical "~20.6" is **underived**: it is the only cost figure in this ledger with no
recorded derivation (it is near, but not equal to, the row's 21.3-bit marginal compression, and no
computation producing 20.6 is on record in the corpus). It is retained, explicitly so labelled, because
nothing rests on it — the row's verdict is definitional (cost ≈ compression ⇒ net ≈ 0) whatever the
precise figure.
⁷ ⚠ **[CORRECTED 2026-09-02, prose batch P40 — registry key `RF-e2b24ea8`]** — from 2026-07-10 until
today this cell published a *negative* lower endpoint for C2's net "under explicit-grammar codings",
and no cost stated anywhere in this corpus can reach it. Net is defined in the Framework section above as
compression − statement cost. C2's compression is log₂ 23.325025987… = **4.5438** bits (exact
marginals, above); the declared per-distance-ban family has six members ⇒ log₂ 6 = **2.585** ⇒ net
**+1.96**, which is the published +2.0 and is correct. The largest statement cost stated anywhere in
the corpus is [TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md)'s sensitivity table —
"~2.6–4 (per-distance ban family + grammar)" ⇒ net **+0.54**. Every published coding therefore gives
C2 a **positive** net; the retired endpoints would require 5.14-bit and 8.54-bit explicit grammars,
and none is published here or recorded privately — `prior_art_check.sh 'C2 explicit-grammar coding
statement cost 5.14 8.54 bits'` returns `PRIOR_ART=NONE  surfaces searched: roae-private *.md, *.tsv,
codex_transcripts/; roae *.md; git log --all -S on both repos`. The mechanical cause is legible in the
row itself: the bracket's lower endpoint was the maximum *cost*, sign-flipped, rather than compression
minus that cost. **The verdict does not move** — C2 is break-even to marginally explanatory either
way, and remains the only narrow rule that reaches break-even — but the low corner of the
savings envelope below, which consumed the retired endpoint, does move; see there. Ruling:
[TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md) §2 fn⁷ and [CORRECTIONS.md](CORRECTIONS.md).
⁸ The 13.5 is log₂(×11,364), and the ×11,364 was measured under **this project's "≤2 violations
anywhere" relaxation** of the rule, not under the form Schulz's sources state — parity throughout with
at most one exception pair at adjacent class positions
([Schulz 1990](CITATIONS.md#schulz1990-motifs), elaborated by [Cook 2006](CITATIONS.md#cook2006); the
exception first recognized by Zhu Yuansheng, 13th c.). Re-measured on identical probes, the
source-stated form is **≈11× rarer**
(the 2026-07-12 convention-stability note in
[LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md)), so the rule *as its sources state it* compresses
log₂(11,364 × 11) ≈ **16.9** bits — about 3.5 bits more than this row prices. The error runs in the
direction that makes the literature look weaker, so the row's verdict does not move (at 16.9 against
"rule text ≈ 10–15" the net becomes +1.9 to +6.9 rather than ≈ 0 to small +, and either is negligible
against a 105–139-bit residual); what moves is what the number is *about*. Labelled 2026-09-02
(prose batch P40).
⁹ The "rule text ≈ 10–15" cost cell is **underived** in the same sense as the C6/C7 "~20.6" at fn⁶: no
codebook, computation or working note producing 10–15 is on record. `prior_art_check.sh 'Schulz rule
text statement cost 10-15 bits derivation'` returns `PRIOR_ART=NONE  surfaces searched: roae-private
*.md, *.tsv, codex_transcripts/; roae *.md; git log --all -S on both repos`; every occurrence of the
figure in the corpus is this cell, its TR-9 mirror, or a review transcript quoting one of them.
Independently, the code-resident-predicates block in
[LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md) records that no document states these literature rules formally enough
for an independent team to re-encode them, so no rule-text length here is reproducible from a
published source. It is retained, so labelled, because nothing rests on it: the row's verdict holds
across the whole band, and holds at 16.9 as well (fn⁸).

## The residual — the honest thesis

Knowing everything structural in this table, the sequence retains **log₂|C1–C7| = 105.4 bits** of
unexplained information — the most conservative reading: unexplained by anything known, even the
data-like pins. At the other end, the residual against the layers this ledger actually claims as
*explanatory* — C1, C2 and C4 only, since the ledger itself prices C3 as circular and C5 as confirmed
description — is **log₂|C1∩C2∩C4| = 139.1 bits**, an exact quantity (the logarithm of the exact
7.5706×10⁴¹ count above). The published residual is therefore the range **105–139 bits**; the
intermediate readings — ~126.6 (C1–C5, retaining the non-explanatory cuts of C3 and C5) and 129.7
(dropping C3's cut too) — remain available to a reader who grants those layers standing, and each step
toward consistency *enlarges* the residual (126.6 → 129.7 → 139.1). The literature's strongest independent rule
prices at ~13.5 bits gross **under this ledger's relaxation of it** (≈ 16.9 bits under the form its own
sources state — fn⁸). **Roughly half the sequence's information is explained (gross compression; net
of explicit statement costs the savings envelope over the stated bracket corners is 107.2–148.3 bits,
≈ 36–50% — corner arithmetic in [TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md) §4; the low corner
was corrected on 2026-09-02 with the C2 net bracket that feeds it, fn⁷ — 127.3 + 0.5 − 20.6 = 107.2
and 107.2 ÷ 296.0 = 36.2%, the high corner 146.3 + 2.0 = 148.3 ≈ 50% and the C5-retaining 142.0
variant unchanged, so the envelope narrows from below only) — nearly all of it by the classical
pairing (now known optimal), a marginal 4.5 bits (≈ break-even once its statement cost is charged) by the
no-five rule, and essentially nothing by C5, whose statement costs 1.7–2.5× what it explains (net −6 to −14
bits depending on the stated coding convention; measured 2026-07-03, bracket derived 2026-07-10): the
transition histogram is confirmed description, not explanation. The rest of the sequence is explained
by nothing known today.**

**This residual is quantified to ±0.02 bits, not a gap in the analysis** (the 105.4 endpoint rests on
the C1–C7 estimate, whose published 0.78% is the estimator's relative **standard error**, not a 95%
half-width — so the 95% interval is ±1.96·SE ≈ **±0.022 bits**, which the published
[5.13, 5.29]×10³¹ bracket independently gives as −0.0223/+0.0220; this sentence published the 1-SE
conversion, understating the interval by 1.96×, until 2026-09-02. The 139.1 endpoint is a logarithm of
an exact integer and carries no interval at all). Whether it can be
compressed by any principled, KW-independent structural rule is a precisely-posed question of
*irreducibility* — one that can only be settled by exhausting a declared class of candidate rules, never
by recovering the sequence's "true" generator: against ~105–139 free bits a rule can always be *fitted* to
single out King Wen, so only a pre-declared, KW-independent class of rules carries evidential weight.
Design hypotheses and emergence hypotheses alike must ultimately be judged in this currency: bits
predicted per bit of statement.

*Conventions and framework: ROAE (to our knowledge first applied to this object here; corrections welcome
via [CITATIONS.md](CITATIONS.md)). Constraint provenance per row: see [SPECIFICATION.md](SPECIFICATION.md)
and [CITATIONS.md](CITATIONS.md).*

*Correction (2026-07-04): an arithmetic error in the first published version of this table — log₂(31!·2³¹)
stated as 144.4 rather than the correct 143.7 — propagated to C4's marginal (5.3 → 6.0) and C2's marginal
and net (5.3/+2.3 → 4.6/+1.6). Caught by adversarial replication review; no conclusion changes (C2 remains
modestly explanatory, C5 remains descriptive).*

*Exactness note (2026-07-04): the |C1∩C2∩C4| cell is now an EXACT integer — computed by the
symmetry-quotient dynamic program (`solve --f1-exact-c1c2c4`, ~4 minutes on 64 cores), exactly divisible
by 24 as the free-action theorem requires. The prior Knuth estimate (7.571×10⁴¹ ±0.01%) contains
the exact value inside its stated envelope — the estimator's first validation against full-scale ground
truth. (The apparent 5.5×10⁻⁵ gap is the distance to the estimate's four-sig-fig rounding, not a measured
estimator error; the true error is unresolved at the published precision but well within ±0.01%.)*

*Exactness note (2026-07-16): the |C1∩C2∩C4∩C5| cell is now an EXACT integer too — computed by the
out-of-core symmetry-quotient dynamic program (`solve --f1-exact-c1c2c4c5 --f1-out-of-core DIR`,
reproducible on ~64 GB RAM + ~4 TB disk), exactly divisible by 24 as the free-action theorem requires.
The prior Knuth estimate (1.0971×10³⁹ ±0.01%) contains the exact value inside its stated envelope — the
estimator's second full-scale validation (the 4.4×10⁻⁵ / ratio 0.999956 figure is the five-sig-fig
rounding gap, not a measured error). All bits values are unchanged
(log₂ = 129.7). The C3 layer (1.3287×10³⁸) remains an estimate. Full report:
[reports/TR-11](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md).*

*Refinement (2026-07-10, referee-hardening pass): C2's net is restated from +1.6 to ≈ 0 — its 4.5-bit
compression is of the same order as any defensible statement cost, so the row is break-even under
every coding this corpus states (+2.0 on the selection-only reading, +0.5 at the largest published
cost). ⚠ This note originally reached that conclusion by way of *negative* endpoints and inferred
from them that C2's sign is a coding-convention choice; both the endpoints and the inference were
withdrawn on 2026-09-02 — see fn⁷, which shows the arithmetic. C2 remains the only
narrow rule that even reaches break-even. C5's net is widened to a bracket −6.3 to −13.9: the published
23.3-bit statement cost prices the full 6-class transition multiset, but the ledger's compression column
is marginal, and the marginal-consistent price of only the 31 unimplied boundary transitions given C1+C2
is log₂ C(35,4) = 15.7 bits (net −6.3, "costs ~1.7×"); C5 is net-negative under every convention, so the
"descriptive, not explanation" verdict is unchanged. Two sub-0.1-bit rounding fixes from unrounded
operands: C2 marginal 4.6 → 4.5, C6+C7 marginal 21.2 → 21.3. No conclusion moves.*

*Refinement (2026-08-06, MDL audit — mirrors TR-9 v1.22): the residual range WIDENS from 105–127 to
**105–139**. The former upper endpoint 126.6 was labelled "the residual against honestly-explanatory
structure" while retaining the bit-cuts of C5 and C3 — the two layers this very ledger prices as
non-explanatory (C5 confirmed description; C3 circular). The consistent endpoint is log₂|C1∩C2∩C4| =
139.1 bits, a figure that already sat in the table and had never been named as a residual endpoint;
126.6 and 129.7 remain as explicitly-labelled intermediate readings. Every step of the correction
enlarges the residual (126.6 → 129.7 → 139.1) — the central claim strengthens. Same pass: the net-savings
figure "~100–134 bits, ≈ 35–45%" (undocumented corner picks) restated as the full envelope 102.7–148.3
≈ 35–50%; "exactly-quantified" restated as "quantified to ±0.01 bits" (the 105.4 endpoint rests on the
±0.78% estimate ≈ ±0.011 bits); the C6/C7 "~20.6" cost cell labelled underived; the meta-selection
bound in bits (log₂ C(91,7) ≈ 32.9) added to the Framework conventions. No measured count changed.
⚠ **Three of those four items no longer stand as written — the envelope, the ±0.01-bit precision
figure and the meta-selection bound were all corrected or withdrawn on 2026-09-02; see the note
below. The "~20.6 underived" label stands.***

*Correction (2026-09-02, prose batch P40 — four defects raised by the Codex V2-F35 review pass, all
upheld; **no solution count, log-cardinality, marginal compression, residual endpoint or verdict
changes**). (1) The Framework's meta-selection charge was published as **bounded** — a closed answer
in bits against the frozen 91-observable ledger. The 91 counts *tests performed*, not candidate
constraint families, and [METHODS](../reports/METHODS.md) §"The file drawer — an open gap, stated as
such" says the constraint-family denominator is not published and that reconstructing the testing
ledger does not close the gap; the figure is also not a bound on its own denominator, since METHODS
§"Global observable ledger" records **95** as of 2026-08-30 and log₂ C(95,7) ≈ 33.4 > 32.9. The
bound is withdrawn (registry key `RP-fe502239`), 32.9 and 16.6 stay as conditional figures, and what
survives is the direction rather than a margin — mirroring the same withdrawal at
[TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md) §5(f) (2026-09-02, prose batch P31). The
28-observable battery is now named as the *base of* the 91-observable ledger rather than as the
ledger. (2) The Schulz row's 13.5-bit compression prices **this project's own "≤2 violations
anywhere" relaxation**, not the rule as its sources state it, which is ≈11× rarer and compresses
≈ 16.9 bits; the cell and the residual paragraph now say so (fn⁸), and the row's "rule text ≈ 10–15"
cost is labelled **underived** in the same style as the C6/C7 "~20.6" (fn⁹). No verdict moves — the
error ran in the direction that makes the literature look weaker. (3) The C2 ledger row's net
bracket carried a negative lower endpoint that no cost published anywhere in this corpus can produce:
net is compression − cost, C2's compression is 4.5438 bits and the largest published statement cost
is 4, so every published coding gives a **positive** net. The bracket is corrected to **+0.5 to
+2.0** (registry key `RF-e2b24ea8`), the 2026-07-10 refinement note's inference that C2's sign is a
coding-convention choice is withdrawn with it, and the savings envelope's low corner — which consumed
the retired endpoint — moves to **107.2 bits ≈ 36%** (registry key `RF-455570a2`; 127.3 + 0.5 − 20.6
= 107.2, 107.2 ÷ 296.0 = 36.2%). The high corner 148.3 ≈ 50% and the C5-retaining 142.0 variant are
unchanged, so the envelope narrows from below only, and C2's verdict — break-even to marginally
explanatory, the only narrow rule that reaches break-even — is untouched. (4) The residual's stated
precision converted a relative **standard error** into a ± band: the published 0.78% is SE/mean, not
a 95% half-width, so the 95% interval is ±1.96·SE ≈ ±0.022 bits, not ±0.01 — understated by 1.96×.
Both this file's sites are corrected (the residual sentence to **±0.02 bits**, the Framework bullet
to **±0.0006 bits**), completing on this page the 2026-08-28 ruling recorded in
[CORRECTIONS.md](CORRECTIONS.md) and matching TR-9 §1. **Known sibling left uncorrected:** the same
1-SE-as-±-band conversion is still published on `README.md`'s residual bullet; it is out of this
batch's file scope and is registered in the prose lane's backlog rather than swept here.*
