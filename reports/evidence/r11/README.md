# R11 evidence bundle — four-class Bayes v2 ingredients + the N_gs stop-flag resolution

This directory holds the ingredient runs for the pre-registered four-class model
comparison (design summarized in [TR-2 §"four-class"](../../TR2_THE_RULES_CONFLICT.md);
the full design is staged privately as a separate **v2** freeze under the operator's
resolve-first / publish-only-if-solid decision — no verdict-space element is published
here). **No Bayes factor has been computed from these files**: per the frozen
ordering-of-operations, calibration and the KW-facing integration are post-freeze
deliverables, and the compute half has not been run. This directory currently holds
instrument outputs and the resolved N_gs stop-flag record only.

## The N_gs stop-flag — RESOLVED 2026-07-13 (verdict re-affirmed)

The first direct N_gs run (`r11_ngs.out`) measured **N_gs = 5.00×10²⁵** and reported
it as **outside** the F11 derived bracket [1.03, 3.57]×10²⁵ — a pre-registered
stop-and-investigate flag (TR-2 v1.10). **That flag is now CLOSED**, and the TR-2 v1.7
corruption-vs-tendency verdict is **re-affirmed** (see [TR-2 v1.12](../../TR2_THE_RULES_CONFLICT.md)
§"Stop-flag resolution"). The investigation found that the "bracket" was never a
confidence interval — it was the span between two point estimates that carried no
propagated uncertainty — so a correct direct measurement landing above it is the
expected signature of the flaw, not a real conflict.

A four-seed direct re-measurement battery (see [PHASE2_README.md](PHASE2_README.md) and
`seed1_1001.out` … `seed4_4013.out`) pools to **N_gs = 4.50×10²⁵** with a conservative
propagated relative error of 6.1% (95% CI [3.96, 5.05]×10²⁵). All three pre-registered
convergence gates pass:

- **χ² seed-consistency** — the four seeds agree at ~1σ (χ²₃ = 1.4, p ≈ 0.7). PASS.
- **Derived-CI cross-path** — a Moore-strict-only re-run with a propagated CI
  (`derived_ci.out`) lands 1.9σ below the direct value (consistent; that path is
  intrinsically noisy). PASS.
- **Repaired stratified cross-check** — the stratified-start estimator was initially
  un-poolable because its instrument mis-composed the strict prunes with fixed-prefix
  starts (naive branch sum 3.35σ high). The composition defect was repaired with an
  estimator-only, self-test-neutral fix (build self-test sha unchanged); the repaired
  run (`stratified_repaired.out`) correctly zeroes the 15 of 56 branches whose fixed
  prefix violates a strict predicate and pools to 4.34×10²⁵ — **0.12σ** from the direct
  value, inside its pre-committed 2σ gate. PASS.

Under the directly measured N_gs the headline Bayes factor becomes ≈ 5.2×10³ (variant U)
/ 6.3×10³ (variant A) — still an order of magnitude above the frozen "strong" band in
every one of the 24 pre-committed sensitivity configurations; the flip threshold is ≈ 52×
the measured value. The correction moves *against* the published winner (the BF got
smaller); what improved is the evidential footing, from a derived ingredient with
unpropagated error to a directly measured one with stated error.

## Ingredient outputs in this directory

- `r11_ngs.out` — the FIRST direct triple-strict count (the instrument F11 documented as
  missing), with its in-walk cross-check line mismatches = 0. **N_gs = 5.00×10²⁵
  (relerr 16.7%)** — the single Phase-1 run that fired the stop-flag; superseded as the
  primary value by the four-seed pooled measurement above (with which it is 1.4σ
  consistent), retained here as the flag's origin record.
- `r11_moore_strict.out` — Moore-joint-strict conditional plane (1,514 cells,
  all g1=g2=0), N_mj = 1.131×10²⁹ — consistent with the published F11 value.
- unconditioned 8-axis joint violation histogram — 150,758 cells; mass sums to 1; seven
  marginals reproduce the run's independent scoreboard lines to <0.3%. The raw dump
  (`r11_hist.out`, 6.5 MB; gzip -9 → 1.7 MB) is **not committed** (over the repository's
  1 MB asset threshold) and is exactly regenerable from the pushed code:
  `SOLVE_KNUTH_SCORE=1 SOLVE_KNUTH_R11_HIST=1 ./solve --estimate-knuth 20000000000`.
  The KW cell (2,2,2,0,0,0,0,0) is absent by rarity, as expected: its estimated mass
  (~10⁻²³ of canonical mass) is ~11 orders below the run's smallest sampled cell
  (5.9×10⁻¹²); scorer correctness is established by the two-language `--r11-verify` gate,
  not by sampling.
- The Phase-2 re-measurement battery (`seed1_1001.out` … `seed4_4013.out`,
  `derived_ci.out`, `stratified.out`, `stratified_repaired.out`, `exact_audit.tsv`,
  `battery.log`, `r11_verify.out`, `smoke.out`, `r11_phase2_battery.sh`) — see
  [PHASE2_README.md](PHASE2_README.md) for the full statistics, gate table, and
  provenance.

## Freeze status of the four-class comparison

The four-class v2 comparison is staged as a **separate private freeze** under the
operator's resolve-first decision: the N_gs ingredient is now solid (all three gates
passed), and the remaining ingredients (a greedy-builder numerator, a completion
simulation, and a synthetic-draw calibration with a pre-registered confusability veto)
and the KW-facing integration have **not** been run. No verdict, Bayes factor, or
posterior for the four-class comparison exists or is published anywhere. When (and if)
a verdict is computed, the full frozen design, every gate outcome, and every marginal
likelihood land in this directory whatever their direction, per the standing
publish-regardless commitment; a gate failure means no verdict exists and the public
status line is updated to say which gate failed.

Developed with AI assistance (Claude, Anthropic); rules and mechanisms credited in the
design doc (Moore, Schulz, Cook, Hacker & Moore, Rutt, McKenna & Mair, Davis,
Van den Berghe). Corrections welcome via [CITATIONS.md](../../../documentation/CITATIONS.md).
