# R11 evidence bundle — four-class Bayes v2 ingredients + the N_gs stop-flag resolution

This directory holds the ingredient runs for the pre-registered four-class model
comparison (design summarized in [TR-2 §"four-class"](../../TR2_THE_RULES_CONFLICT.md);
the full design is staged privately as a separate **v2** freeze under the operator's
resolve-first / publish-only-if-solid decision — no verdict-space element is published
here). **No Bayes factor has been computed from these files, and none now will be** — see the
calibration outcome below.

**Update 2026-07-20 — the §7.2 calibration has RUN, and it VETOED the verdict.** The frozen
ordering-of-operations put a synthetic-draw confusability gate before any KW-facing integration; that
gate has now been executed and **failed**, so the four-class comparison stops here by its own rule. The
greedy-builder class M_G ranks itself first in only **67 of 100** draws against a frozen threshold of 70,
so M_G is not reliably separable from M0 or M_D at this sample size. Per §6.3 no four-class Bayes factor,
posterior, or verdict is computed or published. Full reporting, including what this does and does not
license, is in [TR-2 §"Outcome (2026-07-20)"](../../TR2_THE_RULES_CONFLICT.md).

**The full sensitivity grid, for every class (added 2026-08-02).** Until this date the four-variant
grid was quoted only for M_G, the class that failed; the passing classes were reported at their
primary number alone. That was selective, so the whole grid is now given. First-rank rate out of 100,
read from `calibration_report.txt`:

| true class | primary | corrA | uncond | histZ |
|---|---:|---:|---:|---:|
| M0 — uniform-valid | 99 | 99 | 99 | 99 |
| **M_G — greedy-builder** | **67** | **67** | **45** | **25** |
| M_D — global-design | 81 | 81 | 86 | 99 |
| M_C — corrupted-precursor | 84 | 84 | 72 | **1** |

Two things a reader needs in order to weigh that table, both checkable from the committed artifacts:

1. **`corrA` is not an independent reading.** It re-scores M_C under the frozen A (bamboo-adjacent)
   corruption-location variant instead of U. The likelihoods do differ, and on some draws by a lot
   (over the 139 draws with L_C > 0: median |ΔL_C/L_C| ≈ 0.3%, maximum ≈ 89%) — but on **0 of 393
   draws does the difference change the arg-max**, so it reproduces
   the primary confusion matrix cell for cell. Four pre-committed variants therefore yield **three**
   distinct outcomes, not four.
2. **The `histZ` column ranks M_D's normalizer, not the other classes' identifiability.** `histZ`
   substitutes `LD_histZ` for `LD` and changes *nothing else* (`r11_calibration.py`, `rank_of`): M0's,
   M_G's and M_C's likelihoods are identical to the primary column. Its Z table is built from the
   unconditioned histogram alone (29,997 cells) rather than the augmented table (30,439 cells) that
   supplies the rare low-violation corners from the strict-pruned conditional runs and the
   grand-strict count — the frozen design records this row as *understating Z, design-favorable*
   before it was run. The measured effect: median log₁₀(L_D^histZ ⁄ L_D) = **5.56**, and every draw
   M_G or M_C loses under `histZ` is lost **to M_D** (42 of 42, 83 of 83). So M_C's 1/100 is a
   statement about an inflated M_D likelihood, not evidence that the corrupted-precursor class is
   unidentifiable — and by the same token M_G's 25 is confounded and should not be read as a fourth
   independent failure.

**What survives.** M_G is below the frozen 70 in every unconfounded reading — 67, 67 and 45 — including
the primary configuration on which the frozen verdict is computed, so the §6.3 veto stands exactly as
stated. What the grid removes is the rhetorical weight of the "never once clearing 70 across four
variants" phrasing, which double-counted `corrA` and leaned on the M_D-confounded `histZ` column. This
correction runs *against* our own emphasis and changes no verdict: no four-class Bayes factor or
posterior exists to move.

Calibration artifacts in this directory (master seed 20260720, deterministic):

| file | contents |
|---|---|
| `r11_calibration.py` | the instrument (stdlib-only; reuses the M_G builder in `solve.py`) |
| `calibration_report.txt` | four variant confusion matrices + the §7.2/§6.3 veto verdict |
| `draws.json` | the 393 synthetic draws (100 per class; M_C 93, with 7 recorded draw failures) |
| `scores.json` | every draw scored under all four models |
| `hits.json`, `pcomplete.json`, `gates.json` | rule-hit tables, greedy completion probabilities, pre-gates |

Reproduce with `python3 r11_calibration.py --phase gates|draws|pcomplete|hits|score|report`. Note the
KW-facing integration script (`compute_r11_bf.py`) **does not exist and is not planned**: the veto means
there is nothing it would be permitted to report.

The remainder of this directory holds the ingredient outputs and the resolved N_gs stop-flag record.

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

**Calibration veto (2026-08-03; note added 2026-08-06 —
[CORRECTIONS CX-25](../../../documentation/CORRECTIONS.md)).** The re-affirmation above is itself
now superseded in one respect: the two-model pair behind the verdict (M_corr vs M_tend) later
failed its own pre-registered confusability gate — Half B (M_tend self-recovery) **FAILED at
68/100** against a bar frozen at 70 (Half A passed 93/100). The BF ≈ 5.2×10³ / 6.3×10³ and the
≈0.9998 posterior are **no longer calibrated in the pooled sense**; the numbers are unchanged and
not withdrawn — what is withdrawn is their *calibration support*. See [../f11halfb/](../f11halfb/)
and [TR-2](../../TR2_THE_RULES_CONFLICT.md) §"The result".

## Ingredient outputs in this directory

- `r11_ngs.out` — the FIRST direct triple-strict count (the instrument F11 documented as
  missing), with its in-walk cross-check line mismatches = 0. **N_gs = 5.00×10²⁵
  (relerr 16.7%)** — the single Phase-1 run that fired the stop-flag; superseded as the
  primary value by the four-seed pooled measurement above (with which it is **0.57σ**
  consistent — this figure read 1.4σ until 2026-08-02; see
  [PHASE2_README.md](PHASE2_README.md) §"Honest residuals" for the σ convention and what
  was wrong with the old number), retained here as the flag's origin record.
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
passed). **Superseded 2026-07-20 (recorded here 2026-08-01):** the synthetic-draw
calibration with its pre-registered confusability veto HAS since been run — see the
update at the top of this file and the artifacts in this directory
(`calibration_report.txt`, `draws.json`, `scores.json`, `hits.json`, `pcomplete.json`,
`gates.json`) — and it **failed its own gate**, so the comparison stops there by rule.
The greedy-builder numerator, the completion simulation, and the KW-facing integration
were and remain **not** run. No verdict, Bayes factor, or
posterior for the four-class comparison exists or is published anywhere. When (and if)
a verdict is computed, the full frozen design, every gate outcome, and every marginal
likelihood land in this directory whatever their direction, per the standing
publish-regardless commitment; a gate failure means no verdict exists and the public
status line is updated to say which gate failed.

Developed with AI assistance (Claude, Anthropic); rules and mechanisms credited in the
design doc (Moore, Schulz, Cook, Hacker & Moore, Rutt, McKenna & Mair, Davis,
Van den Berghe). Corrections welcome via [CITATIONS.md](../../../documentation/CITATIONS.md).
