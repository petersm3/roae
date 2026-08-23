# TR-9 — Pricing the Constraints: Description-Length Accounting
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

If you had to transmit the King Wen sequence to someone, how many bits would it take — and how many do
the known "design rules" save you? This report prices every rule in bits, the accounting standard of
information theory. The verdict: the classical pairing rule does almost all the work (~146 of ~296
bits) and is provably the *best possible* rule of its kind; the no-distance-5 rule roughly breaks even
once its own statement cost is charged; and the celebrated transition-count recipe turns out to cost more to state than it saves — it
is **description, not explanation**. After all known rules are applied, **between about 105 and 127 bits of the
sequence remain unexplained (exact figure depends on the stated accounting convention)** — the honest measure of how much structure is still unaccounted for.
This is the most judgment-dependent report in the suite; its accounting conventions are stated
explicitly so a skeptic can re-price everything under their own.

## Abstract
Rarity numbers (×11,364, 10⁻⁴⁴, …) invite over-reading. The disciplined currency is bits: how much of the
King Wen sequence's information does each constraint *explain*, net of what the constraint itself costs to
state? We fix a two-part MDL framework — an arbitrary ordering of 64 hexagrams costs log₂ 64! = 296.0 bits;
a constraint system K explains 296.0 − log₂|solutions(K)| bits at statement cost L(K) — and compute the
ledger under two declared statement-cost conventions (family selection vs derivation from principle). The
measured result: the classical pairing C1 explains 146.3 bits and, post-[Radisic (2026)](../documentation/CITATIONS.md#radisic2026) (preprint,
machine-verified), is essentially free
to state under the derivation convention — the unique Hamming-optimal comp/rev matching; C2 nets ≈ 0
(break-even, sign convention-dependent); C5 nets between **−6.3 and −13.9 bits** — its statement costs
1.7–2.5× what it explains; the transition histogram is
confirmed *description*, not explanation; C3's threshold is circular by construction and its 3.0 marginal
bits are not claimed; C6/C7 are data-like and definitionally break-even. The honest thesis: roughly half
the sequence's information is explained — nearly all of it by the pairing — leaving a residual of 105.4
bits (defensible-subset reading: ~126.6 bits) explained by nothing known today. This is the most
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
   look-elsewhere accounting for the ~30-observable extraction battery lives in [CRITIQUE.md](../documentation/CRITIQUE.md) and is not
   double-counted here.
2. **The measured ledger.**

   | Layer | Solution count | log₂ count | Marginal compression | Statement cost | Net |
   |---|---|---|---|---|---|
   | baseline (any ordering) | 64! | 296.0 | — | — | — |
   | + C1 (pairing) + C4 (start) | 31!·2³¹ | 143.7 | **146.3** (C1) + 6.0 (C4)¹ | ~0 (derived²) / ~13 (family³) | **+133 to +146** |
   | + C2 (no-5) | 7.5706×10⁴¹ (**exact**, orbit-quotient DP `solve --f1-exact-c1c2c4`, 2026-07-04; supersedes the 2026-07-03 estimator value 7.571×10⁴¹ ±0.01%, which it confirms) | 139.1 | 4.5 | ~3 (family of per-distance bans) | **≈ 0 (+2.0 selection-only; −0.6 to −4 under explicit-grammar codings)** |
   | + C5 (transition multiset) | 1.0971×10³⁹ | 129.7 | 9.4 | 15.7–23.3⁴ | **−6.3 to −13.9 (descriptive under every convention⁴)** |
   | + C3 (complement ceiling) | 1.3287×10³⁸ | 126.6 | 3.0 | circular⁵ | ≈ 0 |
   | + C6 + C7 | 5.21×10³¹ | 105.4 | 21.3 | data-like (slot pins: ~20.6)⁶ | ≈ 0 |
   | strongest literature rule ([Schulz](../documentation/CITATIONS.md#schulz1990-motifs) gender) | — | — | 13.5 | rule text ≈ 10–15 | ≈ 0 to small + |

   ¹ C4 fixes the first pair and orientation among 32·2 choices ≈ 6 bits; forced-orientation theorem
   returns 1. ² Radisic 2026: the pairing is the unique Hamming-optimal comp/rev matching — under the
   derivation convention its cost is the optimality principle itself (a one-line statement). ³ Family:
   perfect matchings generated by the K₄ operations (rev-priority, comp-priority, mixed per-orbit choices)
   — ~2¹² comparable members ≈ 12–13 bits (exact: 12.0 bits for {rev, comp} matchings, 19.0 if comp∘rev
   pairings are also admitted). ⁴ Statement-cost bracket for the multiset: full 6-class multiset log₂
   C(68,5) = 23.3 bits; conditioned on C2 (5 usable classes) log₂ C(67,4) = 19.5; marginal-consistent
   price of the 31 unimplied boundary transitions given C1+C2 log₂ C(35,4) = 15.7 (the internally
   consistent choice, since the compression column is marginal). Every choice leaves C5 net-negative.
   ⁵ C3's threshold (776) is KW's own value — circular by construction,
   priced as data (CRITIQUE.md Q1); its marginal 3.0 bits are NOT claimed as explanation. ⁶ C6/C7 pin four
   slots: log₂(choices eliminated) ≈ their own compression — definitionally break-even.
3. **Reading the ledger, row by row.** **C1** is where nearly all the explanation lives: 146.3 bits of
   compression, and its statement cost collapsed in 2026 — Radisic (arXiv:2601.07175 — an unrefereed
   preprint whose Lean 4 + Mathlib proof artifact is independently checkable; the ledger leans on the
   machine verification, not on refereeing) proved the pairing is the *unique* Hamming-cost minimizer
   among comp/rev matchings on {0,1}⁶,
   so under the derivation convention it costs only the optimality principle. That upgrade is Radisic's,
   not ours; it is the first genuine first-principles derivation of any layer of the constraint system.
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
   claimed. **C6/C7** pin four slots — definitionally break-even. The strongest literature rule (the
   Schulz gender rule, ×11,364 — see [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md)) prices at ~13.5 bits gross against ~10–15 bits of rule text:
   ≈ 0 to small positive.
4. **The residual — the honest thesis.** Knowing everything structural in this table, the sequence retains
   **log₂|C1–C7| = 105.4 bits** of unexplained information; on the defensible subset (dropping circular
   C3, data-like C6/C7), the residual against honestly-explanatory structure is **~126.6 bits**. Roughly
   half the sequence's information is explained (gross compression; net of explicit statement costs the
   savings are ~100–134 bits, ≈ 35–45%) — nearly all of it by the classical pairing (now known
   optimal), a marginal 4.5 bits (≈ break-even net) by the no-five rule, and essentially nothing by C5,
   whose statement costs 1.7–2.5× what it explains (net −6 to −14 bits depending on the coding convention):
   the transition histogram is confirmed description, not explanation. The
   other half of the sequence is explained by nothing known today. Design hypotheses and emergence
   hypotheses alike must ultimately be judged in this currency: bits predicted per bit of statement.
5. **Conventions and their sensitivity.** This is the most judgment-laden report in the suite; the numbers
   in column 2 are measurements, but several numbers in columns 5–6 are *choices*, and a skeptical reader
   should see how far the conclusions move under different ones. (a) **C1's net spans +133 to +146**
   depending on convention — the widest swing in the ledger — but the conclusion "C1 dominates the
   explanation" is convention-robust: even the maximal family charge is small against 146.3. The family
   size is now exact: 12.0 bits for the {rev, comp} matchings the published "~12–13" refers to, or 19.0
   bits if comp∘rev pairings are also admitted — widening the honest low end to +125, still overwhelmingly
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
   pricing KW's own values as explanation would be self-confirmation (CRITIQUE.md Q1). (e) **Estimator
   precision** is not a sensitivity: ±0.02% on solution counts is ±0.0003 bits. (f) **Look-elsewhere** for
   the observable-extraction battery is accounted in CRITIQUE.md and deliberately not double-counted here;
   a referee preferring it folded in should charge it against the data-like rows, which are already ≈ 0.
   Framework attribution: conventions and framework are ROAE (to our knowledge first applied to this
   object here; corrections welcome via CITATIONS.md); constraint provenance per row: [SPECIFICATION.md](../documentation/SPECIFICATION.md) and
   CITATIONS.md.

## Verification Guide
- The ledger, conventions, and footnotes: [documentation/DESCRIPTION_LENGTH.md](../documentation/DESCRIPTION_LENGTH.md) (this TR preserves its
  numbers exactly)
- Solution counts: exact layers vs [documentation/CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) + enumeration record; estimator
  layers (1.0971×10³⁹ C5 count **(now EXACT: 1,097,051,278,789,181,790,036,112,071,176,579,186,688; see documentation/SEARCH_SPACE_SIZE.md)**, 1.3287×10³⁸ full space, still an estimate) via the validated
  weighted-Knuth instrument — [documentation/SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md) (method + 0.03% self-validation);
  C2 layer count **exact**: `solve --f1-exact-c1c2c4` (7.5706×10⁴¹, divisible by 24 per [TR-5](TR5_SYMMETRY.md);
  the estimator path `SOLVE_KNUTH_RELAX_C5=1` reproduces it to ±0.01% — both documented in
  SOLVE_C_CLI.md)
- C1 optimality (statement-cost collapse): Radisic, arXiv:2601.07175 (Lean 4 + Mathlib); within-pair
  distance cross-check 2×12 + 4×12 + 6×8 = 120 per documentation/CITATIONS.md §Radisic 2026
- Circularity pricing of C3: documentation/CRITIQUE.md Q1
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

Thirteen ordering-layer functionals, each drawn from a literature axis and registered with thresholds
BEFORE measurement (documentation/CRITIQUE.md), were scored against the full population (2×10⁹ probes,
2026-07-04). All thirteen: null. The ~126 unexplained bits therefore survive their first systematic
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
| v1.8 | 2026-07-11 | Radisic status labeled at the load-bearing citations ("preprint, machine-verified" — the ledger leans on the checkable Lean artifact, not refereeing); §5(c) gains the criterion-selection acknowledgment (why Hamming-optimality counts as natural is itself a choice; the dual-convention bracket bounds it). No numbers change |
| v1.7 | 2026-07-10 | Referee-hardening (explicit-coding MDL pass): C2 net restated +1.6 → ≈ 0 (break-even, sign convention-dependent); C5 net widened −13.9 → bracket −6.3 to −13.9 (the marginal-consistent statement cost of the 31 unimplied boundary transitions given C1+C2 is log₂ C(35,4) = 15.7, net −6.3); §5 sensitivity paragraph rewritten with the explicit three-point C5 bracket (15.7/19.5/23.3, literal ~30) + the sign-flip bound and exact C1 family sizes (12.0/19.0 bits); sub-0.1-bit rounding fixes C2 4.6→4.5, C6+C7 21.2→21.3; abstract, executive summary, footnote 4, and sensitivity table made consistent. No conclusion changes (C5 descriptive under every convention; C1 dominant). Mirrors DESCRIPTION_LENGTH.md. |

*Draft-stage corrections (2026-07-04, adversarial replication review): log₂(31!·2³¹) corrected 144.4 →
143.7 (C4 6.0, C2 marginal 4.6, C2 net +1.6 — mirrors the public DESCRIPTION_LENGTH.md correction);
residual parenthetical reworded to match its arithmetic (the 126.6 figure retains C3's cut; dropping C3
too gives 129.7). Statement-cost convention families for the three priced rows were tightened per the review before
v1.0.*
