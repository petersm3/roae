**FROZEN 2026-07-04 by operator approval ('approve F11 defaults') — no further changes to model forms, priors, or bands; see PROOF_PROGRAM UPDATE 32.**

# F11 — Corruption vs. tendency: pre-registered Bayes-factor framework (NOT RUN)

**Status:** framework only, deliberately not executed. Running it post hoc, after seeing every measured
number, would manufacture confirmation — the priors and model forms below must be frozen (operator
sign-off) BEFORE computation, and the sensitivity grid reported in full.

## The question
KW deviates from perfect compliance with the literature's three strongest rules by exactly one 3-edit
event at the historically-flagged locus. Two live readings:
- **M_corr (corruption):** an originally rule-perfect ordering; a small transmission corruption (Rutt's
  bamboo-slat mechanism gives physical plausibility) produced the received sequence.
- **M_tend (tendency):** the arranger followed the rules as soft preferences (strength λ), never exactly;
  the anomaly is an ordinary imperfection.

## Model forms (to freeze)
- M_corr: uniform draw from the grand-strict set (size measured: ~1.1×10²⁹ scale for the Moore-joint form;
  the triple-strict size is measurable) × corruption process = k slot-edits, k ~ geometric(p_c), edit
  location uniform (or bamboo-adjacent-biased — TWO variants, both reported). Likelihood of observing a
  sequence exactly 3 edits from strictness, with all violations co-located: computable from the SAT-exact
  repair geometry + edit-process combinatorics.
- M_tend: Gibbs form P(S) ∝ exp(−λ·violations(S)) over C1–C5 space; λ fit-free (marginalized over a
  declared prior) — likelihood of KW's exact violation profile (2+2+2 across the three rules, co-located)
  via the measured population masses at each violation level.
- Both conditioned on C1–C5 (shared substrate, cancels).

## Data vector (all already measured/decided)
Minimal repair = 3 (SAT-exact); violation co-location at S25/26-slots-21/22; per-rule strict masses
(5×10⁻⁶, 6.3×10⁻⁴, ~<10⁻⁷); KW-level masses (×1362, ×26, ×11364); joint-strict scale ~1.13×10²⁹.

## Pre-registration checklist (operator)
1. Freeze both model forms + the two corruption-location variants. 2. Priors: p_c ∈ {grid}, λ-prior
{grid}; model prior 50:50. 3. Decision bands: BF > 10 substantial, > 100 strong (Jeffreys). 4. Commit to
publishing the full sensitivity table regardless of direction. 5. Only then compute (one afternoon;
everything closed-form or small-simulation).

**Why this design:** the computation is cheap; the credibility cost of running it unfrozen is not.
