# TR-9 — Pricing the Constraints: Description-Length Accounting
*Technical report — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. One caveat is structural, and it frames all the rest: the same
author wrote the claims, the software that checks them, and this report that grades the check.
Verification here is independent in mechanism, never in authorship; no independent party has yet
audited or reproduced any of it (METHODS.md §"Authorship independence").*

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
(break-even, sign convention-dependent); C5 nets between **−6.3 and −13.9 bits** — its statement costs
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
   enumerable, otherwise the validated estimator values (±CI in bits is negligible at the precision
   quoted: ±0.02% ≈ ±0.0003 bits). Statement costs are reported under TWO conventions, because the choice
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
   | + C2 (no-5) | 7.5706×10⁴¹ (**exact**, orbit-quotient DP `solve --f1-exact-c1c2c4`, 2026-07-04; supersedes the 2026-07-03 estimator value 7.571×10⁴¹ ±0.01%, which it confirms) | 139.1 | 4.5 | ~3 (family of per-distance bans) | **≈ 0 (+2.0 selection-only; −0.6 to −4 under explicit-grammar codings)** |
   | + C5 (transition multiset) | 1.097051×10³⁹ (**exact, two-instrument** — out-of-core orbit-quotient DP `solve --f1-exact-c1c2c4c5`, 2026-07-16 — [TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md); independently recomputed at full scale 2026-07-25 by `verify.c --ie-count` (inclusion–exclusion transfer-walk — a different algorithm class sharing no code with solve.c): exact MATCH, mod-24 verified ([TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §10(vi)); the mod-24 gate + 4/4 out-of-core ladder further corroborate it; supersedes the estimator value 1.0971×10³⁹ ±0.01%, which it confirms — the exact value lands inside the stated envelope; the 0.0044% figure is the estimate's rounding gap, not a resolved error) | 129.7 | 9.4 | 15.7–23.3⁴ | **−6.3 to −13.9 (descriptive under every convention⁴)** |
   | + C3 (complement ceiling) | 1.3287×10³⁸ (**estimate** — Knuth random-probe, 95% CI [1.3283, 1.3292]×10³⁸, 0.02%) | 126.6 | 3.0 | circular⁵ | ≈ 0 |
   | + C6 + C7 | 5.21×10³¹ (**estimate** — Knuth random-probe, 95% CI [5.13, 5.29]×10³¹, 0.78%; [TR-4](TR4_SIZE_OF_THE_SPACE.md) §4 owns the measurement) | 105.4 | 21.3 | data-like (slot pins: ~20.6 — underived⁶) | ≈ 0 |
   | strongest *principled* literature rule ([Schulz](../documentation/CITATIONS.md#schulz1990-motifs) gender — "strongest" among the rules stated independently of King Wen; the data-like trigram rule scores higher but is descriptive) | — | — | 13.5 | rule text ≈ 10–15 | ≈ 0 to small + |

   **Exact marginals (v1.10, 2026-07-18).** With the analytic cells 64!, 32!·2³², 31!·2³¹ and the
   two DP exacts, every marginal in the C3-free spine is a **ratio of exact integers**: C4 given C1
   = ×64 exactly (6.0000 bits); **C2 given C1∩C4 = ×23.325025987… (4.5438 bits)**; C5 given
   C1∩C2∩C4 = ×690.0850… (9.4306 bits). The rounded Δ-column values above (4.5, 9.4) are these
   exact ratios. Corroboration with a scope caveat: 1/23.325 = **4.2872%** — the long-published
   "~4.3% of pair-constrained orderings" estimate for C2 now lands exactly, *at the C1∩C4
   conditioning*; the C1-only (start-free) fraction is now also exact — **4.29341%**
   (1 in 23.29, start-unpinned; `solve --f1-exact-c1c2`, 3-prime CRT, orbit-0 anchored to 2·|C1∩C2∩C4|; 2026-07-25). Corollary (C5's multiset contains no distance-5, so C5 ⟹ C2):
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
   whatever the precise figure.
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
   before any grammar overhead): net ≈ 0, sign dependent on the coding convention. It is the only narrow
   rule that even *reaches* break-even. **C5** is the ledger's sharpest
   verdict: the transition multiset compresses 9.4 bits but costs 15.7–23.3 bits to state (the
   marginal-consistent price of the 31 unimplied boundary transitions given C1+C2, up to the full 6-class
   weak-composition bound), netting −6.3 to −13.9 — net-negative under every convention, a *measured*
   conclusion (the C2 layer count, now **exact** at 7.5706×10⁴¹
   via the orbit-quotient DP `solve --f1-exact-c1c2c4`, pinned the marginal). C5 earns its keep operationally (it is what makes enumeration
   tractable) but explains nothing: it is confirmed description of King Wen, not explanation. **C3** is
   circular: its threshold (776) is KW's own value, so its 3.0 marginal bits are priced as data and not
   claimed. **C6/C7** pin four slots — definitionally break-even. The strongest *principled* literature rule — strongest among those stated independently of King Wen, since the data-like trigram rule scores higher but describes rather than explains — (the
   Schulz gender rule, ×11,364 — see [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md)) prices at ~13.5 bits gross against ~10–15 bits of rule text:
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
   **102.7–148.3 bits ≈ 35–50%** — low corner: C1 at the extended-family charge, 146.3 − 19.0 = 127.3,
   plus C2 at the explicit-grammar −4 and C5 at the literal-coding −20.6; high corner: C1 derived at
   ~0 cost (+146.3) plus C2 at +2.0, with net-negative C5 simply not transmitted; retaining C5 at its
   best bracket point, −6.3, gives 142.0) — nearly all of it by the classical pairing (now known
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
   ~30 — netting C5 between −6.3 and −20.6; the ledger's own marginal convention picks 15.7 (net −6.3,
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
   precision** is not a sensitivity: ±0.02% on solution counts is ±0.0003 bits. (f) **Look-elsewhere** for
   the observable-extraction battery is accounted in CRITIQUE.md and deliberately not double-counted here;
   a referee preferring it folded in should charge it against the data-like rows, which are already ≈ 0.
   That accounting is denominated in Bonferroni-corrected p-values; for a reader who wants the
   meta-selection charge — the cost of selecting the constraint *families themselves* — closed in this
   ledger's own currency, an upper bound follows from the corpus's frozen counts: selecting all seven
   constraints from the frozen 91-observable global ledger costs at most log₂ C(91,7) ≈ 32.9 bits
   (log₂ C(28,5) ≈ 16.6 for selecting C1–C5 from the 28-observable discovery battery alone), and
   against C1's 146.3 bits, dominance survives even the maximal joint charge (19.0-bit extended family
   + 32.9-bit selection) with ~94 bits to spare. The charge also largely does not apply row by row:
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
- C1 optimality (statement-cost collapse): Radisic, arXiv:2601.07175 (Lean 4 + Mathlib; independently
  rebuilt + re-verified 2026-07-26) — and machine-checked in-repo: `lean HammingOptimalMatching.lean`
  (kernel-only; `partner_is_unique_minimum`, `kw_realizes_partner`); within-pair
  distance cross-check 2×12 + 4×12 + 6×8 = 120 per documentation/CITATIONS.md §Radisic 2026
- Circularity pricing of C3: documentation/CRITIQUE.md §"Observable-selection accounting" (which grades
  C3's marginal bits as "priced as data, not claimed" and records the threshold's circularity as a
  separate standing limitation)
- Schulz gender rule gross bits: ×11,364 ≈ 13.5 bits — companion registry, [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) /
  [documentation/LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md)
- Arithmetic spot-checks: log₂ 64! = 296.0; log₂(31!·2³¹) = 143.7; log₂ C(68,5) = 23.3 (all reproducible
  in three lines of Python)

## Sensitivity table (planned improvement, v1.3): net bits under both statement-cost conventions

All marginals from the published ledger (documentation/DESCRIPTION_LENGTH.md); the two conventions
bracket the honest range:

| Rule | Compression (bits) | Statement cost: derivation-allowed | Statement cost: family-only | Net (bracket) |
|---|---:|---:|---:|---|
| C1 (pairing) | 146.3 | ~0 (derived from a stated optimality principle) | ~13 (choice within the matching family) | **+133 to +146** |
| C2 (no-5) | 4.5 | ~2.6 (selection only) | ~2.6–4 (per-distance ban family + grammar) | **≈ 0 (+2.0 to −4)** |
| C5 (transition multiset) | 9.4 | 15.7 (marginal-consistent: 31 boundary transitions) | 23.3 (full 6-class multiset) | **−6.3 to −13.9 (descriptive either way)** |

The verdicts are convention-stable: C1 dominates under both readings, C2 stays marginally explanatory,
and C5's cost exceeds its compression under any defensible statement convention.

## Update (v1.3): the residual survives a pre-registered attack

⚠ **`ulimit -s unlimited` is REQUIRED for every `--estimate-knuth` command in this document.** Under the default 8 MB stack the estimator does not start: `main` allocates a ~7.23 MB frame and `estimate_tree_knuth` a further ~1.02 MB (since 2026-08-21 the binary refuses with an actionable message; previously a bare SIGSEGV). *(Added 2026-08-21, an execution-lane finding — `scripts/exec_lane.sh` executes every documented command on a default environment; the same-day warning propagation (`1e4bd04a`) covered the four estimator guides but missed this file.)*

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
| v1.23 *(current)* | 2026-09-01 | **Footnote ¹'s C4 epithet narrowed to definitional; the 6-bit charge does not move (the 2026-08-30 correction propagated).** [METHODS.md](METHODS.md) §"Constraint set" established on 2026-08-30 that the *Xugua* attests the opening **pair**, not the order within it, so C4's orientation is this project's own convention rather than a classical inheritance; the pedigree the classical record does carry is C1's pairing rule (孔穎達《周易正義·序卦傳疏》, 二二相耦，非覆即變) together with C4's *pair choice*. §2 fn¹ still gave the orientation bit the wider epithet; it now mirrors fn¹ of [DESCRIPTION_LENGTH.md](../documentation/DESCRIPTION_LENGTH.md) — the ledger this report preserves — clause for clause. **The charge is unchanged**: C4 is still priced at its full ≈6 bits, pair AND orientation. A bit that is definitional returns nothing to the ledger for exactly the reason an attested one returns nothing — only the retracted forced-orientation theorem would have returned it, and that theorem is false. §5's meta-selection paragraph was narrowed in the same pass: it called C1 and C4 alike "classical", which over-reaches on the orientation; it now scopes the classical pedigree to C1 and C4's pair choice and records the orientation as definitional rather than battery-selected. The row-by-row argument is untouched — neither is a product of this project's 91-observable battery, which is the only thing that paragraph turns on. No ledger row, bit value, marginal, residual endpoint, or conclusion changed |
