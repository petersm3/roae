# TR-9 — Pricing the Constraints: Description-Length Accounting
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

If you had to transmit the King Wen sequence to someone, how many bits would it take — and how many do
the known "design rules" save you? This report prices every rule in bits, the accounting standard of
information theory. The verdict: the classical pairing rule does almost all the work (~146 of ~296
bits) and is provably the *best possible* rule of its kind; the no-distance-5 rule adds a small honest
saving; and the celebrated transition-count recipe turns out to cost more to state than it saves — it
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
measured result: the classical pairing C1 explains 146.3 bits and, post-[Radisic (2026)](../documentation/CITATIONS.md#radisic2026), is essentially free
to state under the derivation convention — the unique Hamming-optimal comp/rev matching; C2 nets a modest
+1.6 bits; C5 nets **−13.9 bits** — its statement costs 2.5× what it explains; the transition histogram is
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
   look-elsewhere accounting for the ~30-observable extraction battery lives in CRITIQUE.md and is not
   double-counted here.
2. **The measured ledger.**

   | Layer | Solution count | log₂ count | Marginal compression | Statement cost | Net |
   |---|---|---|---|---|---|
   | baseline (any ordering) | 64! | 296.0 | — | — | — |
   | + C1 (pairing) + C4 (start) | 31!·2³¹ | 143.7 | **146.3** (C1) + 6.0 (C4)¹ | ~0 (derived²) / ~13 (family³) | **+133 to +146** |
   | + C2 (no-5) | 7.5706×10⁴¹ (**exact**, orbit-quotient DP `solve --f1-exact-c1c2c4`, 2026-07-04; supersedes the 2026-07-03 estimator value 7.571×10⁴¹ ±0.01%, which it confirms) | 139.1 | 4.6 | ~3 (family of per-distance bans) | **+1.6** |
   | + C5 (transition multiset) | 1.0971×10³⁹ | 129.7 | 9.4 | 23.3⁴ | **−13.9 (descriptive, measured)** |
   | + C3 (complement ceiling) | 1.3287×10³⁸ | 126.6 | 3.0 | circular⁵ | ≈ 0 |
   | + C6 + C7 | 5.21×10³¹ | 105.4 | 21.2 | data-like (slot pins: ~20.6)⁶ | ≈ 0 |
   | strongest literature rule ([Schulz](../documentation/CITATIONS.md#schulz1990-motifs) gender) | — | — | 13.5 | rule text ≈ 10–15 | ≈ 0 to small + |

   ¹ C4 fixes the first pair and orientation among 32·2 choices ≈ 6 bits; forced-orientation theorem
   returns 1. ² Radisic 2026: the pairing is the unique Hamming-optimal comp/rev matching — under the
   derivation convention its cost is the optimality principle itself (a one-line statement). ³ Family:
   perfect matchings generated by the K₄ operations (rev-priority, comp-priority, mixed per-orbit choices)
   — ~2¹² comparable members ≈ 12–13 bits. ⁴ Weak-composition bound for the multiset over usable distance
   classes: log₂ C(68,5) = 23.3 bits. ⁵ C3's threshold (776) is KW's own value — circular by construction,
   priced as data (CRITIQUE.md Q1); its marginal 3.0 bits are NOT claimed as explanation. ⁶ C6/C7 pin four
   slots: log₂(choices eliminated) ≈ their own compression — definitionally break-even.
3. **Reading the ledger, row by row.** **C1** is where nearly all the explanation lives: 146.3 bits of
   compression, and its statement cost collapsed in 2026 — Radisic (arXiv:2601.07175, Lean 4 + Mathlib
   verified) proved the pairing is the *unique* Hamming-cost minimizer among comp/rev matchings on {0,1}⁶,
   so under the derivation convention it costs only the optimality principle. That upgrade is Radisic's,
   not ours; it is the first genuine first-principles derivation of any layer of the constraint system.
   **C2** (no 5-line transitions; [McKenna & McKenna 1975](../documentation/CITATIONS.md#mckenna-mckenna1975)) is the one honestly *net-positive* narrow rule:
   4.6 bits of compression against ~3 bits of statement — +1.6 net. **C5** is the ledger's sharpest
   verdict: the transition multiset compresses 9.4 bits but costs 23.3 bits to state (the weak-composition
   bound), netting −13.9 — a *measured* conclusion (the C2 layer count, now **exact** at 7.5706×10⁴¹
   via the orbit-quotient DP `solve --f1-exact-c1c2c4`, pinned the marginal). C5 earns its keep operationally (it is what makes enumeration
   tractable) but explains nothing: it is confirmed description of King Wen, not explanation. **C3** is
   circular: its threshold (776) is KW's own value, so its 3.0 marginal bits are priced as data and not
   claimed. **C6/C7** pin four slots — definitionally break-even. The strongest literature rule (the
   Schulz gender rule, ×11,364 — see [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md)) prices at ~13.5 bits gross against ~10–15 bits of rule text:
   ≈ 0 to small positive.
4. **The residual — the honest thesis.** Knowing everything structural in this table, the sequence retains
   **log₂|C1–C7| = 105.4 bits** of unexplained information; on the defensible subset (dropping circular
   C3, data-like C6/C7), the residual against honestly-explanatory structure is **~126.6 bits**. Roughly
   half the sequence's information is explained — nearly all of it by the classical pairing (now known
   optimal), a further honest 4.6 bits by the no-five rule, and essentially nothing by C5, whose statement
   costs 2.5× what it explains: the transition histogram is confirmed description, not explanation. The
   other half of the sequence is explained by nothing known today. Design hypotheses and emergence
   hypotheses alike must ultimately be judged in this currency: bits predicted per bit of statement.
5. **Conventions and their sensitivity.** This is the most judgment-laden report in the suite; the numbers
   in column 2 are measurements, but several numbers in columns 5–6 are *choices*, and a skeptical reader
   should see how far the conclusions move under different ones. (a) **C1's net spans +133 to +146**
   depending on convention — the widest swing in the ledger — but the conclusion "C1 dominates the
   explanation" is convention-robust: even the maximal family charge (~13 bits) is small against 146.3.
   (b) **C5's family choice**: the weak-composition bound log₂ C(68,5) = 23.3 bits prices C5 as "a multiset
   over usable distance classes"; a coarser family (e.g., "some histogram constraint") would price lower
   and soften the −13.9; a finer one prices higher. The qualitative verdict — statement cost exceeds the
   9.4-bit compression under any family that identifies the actual multiset — is robust; the "2.5×" figure
   is convention-specific. (c) **What counts as derivable** is philosophy-laden: the derivation convention
   credits C1 because Radisic's principle is independently stated and machine-verified; no comparable
   derivation exists for C2 or C5, and admitting looser "principles" would smuggle parameters into free
   statements. (d) **Circularity discipline**: C3/C6/C7 are deliberately zeroed rather than argued over —
   pricing KW's own values as explanation would be self-confirmation (CRITIQUE.md Q1). (e) **Estimator
   precision** is not a sensitivity: ±0.02% on solution counts is ±0.0003 bits. (f) **Look-elsewhere** for
   the observable-extraction battery is accounted in CRITIQUE.md and deliberately not double-counted here;
   a referee preferring it folded in should charge it against the data-like rows, which are already ≈ 0.
   Framework attribution: conventions and framework are ROAE (to our knowledge first applied to this
   object here; corrections welcome via CITATIONS.md); constraint provenance per row: SPECIFICATION.md and
   CITATIONS.md.

## Verification Guide
- The ledger, conventions, and footnotes: documentation/DESCRIPTION_LENGTH.md (this TR preserves its
  numbers exactly)
- Solution counts: exact layers vs documentation/CANONICAL_HASHES.md + enumeration record; estimator
  layers (1.0971×10³⁹ C5 count, 1.3287×10³⁸ full space) via the validated
  weighted-Knuth instrument — documentation/SEARCH_SPACE_SIZE.md (method + 0.03% self-validation);
  C2 layer count **exact**: `solve --f1-exact-c1c2c4` (7.5706×10⁴¹, divisible by 24 per TR-5;
  the estimator path `SOLVE_KNUTH_RELAX_C5=1` reproduces it to ±0.01% — both documented in
  SOLVE_CLI.md)
- C1 optimality (statement-cost collapse): Radisic, arXiv:2601.07175 (Lean 4 + Mathlib); within-pair
  distance cross-check 2×12 + 4×12 + 6×8 = 120 per documentation/CITATIONS.md §Radisic 2026
- Circularity pricing of C3: documentation/CRITIQUE.md Q1
- Schulz gender rule gross bits: ×11,364 ≈ 13.5 bits — companion registry, [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) /
  documentation/LITERATURE_RULES_POPULATION_TESTS.md
- Arithmetic spot-checks: log₂ 64! = 296.0; log₂(31!·2³¹) = 143.7; log₂ C(68,5) = 23.3 (all reproducible
  in three lines of Python)

## Sensitivity table (planned improvement, v1.3): net bits under both statement-cost conventions

All marginals from the published ledger (documentation/DESCRIPTION_LENGTH.md); the two conventions
bracket the honest range:

| Rule | Compression (bits) | Statement cost: derivation-allowed | Statement cost: family-only | Net (bracket) |
|---|---:|---:|---:|---|
| C1 (pairing) | 146.3 | ~0 (derived from a stated optimality principle) | ~13 (choice within the matching family) | **+133 to +146** |
| C2 (no-5) | 4.6 | ~3 | ~3 (per-distance ban family) | **+1.6** |
| C5 (transition multiset) | 9.4 | 23.3 (weak-composition bound) | 23.3 | **−13.9 (descriptive either way)** |

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
(flags and gates documented in SOLVE_CLI.md).

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.5 | 2026-07-04 | Adversarial round 2 corrections: conflict-theorem claims scoped to pairing-preserving orderings; TR-3 weeks-not-months; TR-9 residual dual-convention phrasing |
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
| v1.3 | 2026-07-04 | Pre-registered F4' null result added (residual survives); convention-sensitivity table added |
| v1.6 | 2026-07-04 | Reproducibility completion: C2-layer count adopted as the exact 7.5706×10⁴¹ (`solve --f1-exact-c1c2c4`, replacing the ±0.01% estimator figure it confirms); F4' tier-1 evidence published (evidence/f4p_tier1.out) and cited; instrument flags (`SOLVE_KNUTH_SCORE_F4P`, `SOLVE_KNUTH_RELAX_C5`) now documented in SOLVE_CLI.md |

*Draft-stage corrections (2026-07-04, adversarial replication review): log₂(31!·2³¹) corrected 144.4 →
143.7 (C4 6.0, C2 marginal 4.6, C2 net +1.6 — mirrors the public DESCRIPTION_LENGTH.md correction);
residual parenthetical reworded to match its arithmetic (the 126.6 figure retains C3's cut; dropping C3
too gives 129.7). Statement-cost convention families for the three priced rows were tightened per the review before
v1.0.*
