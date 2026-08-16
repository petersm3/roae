# R11 Phase-2 — N_gs re-measurement battery (stop-flag resolution evidence)

> **Reproduce:** `bash r11_phase2_battery.sh` from this directory (calibration leg:
> `python3 r11_calibration.py`). Raw outputs preserved beside them — `battery.log`,
> `calibration_report.txt`, `derived_ci.out`, `exact_audit.tsv`, `gates.json`, `hits.json`.

This bundle is the measurement that closes the N_gs stop-flag (TR-2 v1.10 → v1.12) and
re-affirms the corruption-vs-tendency verdict. It re-measures the triple-strict
(rule-perfect) population size N_gs directly, four times with independent seeds, and runs
the three pre-registered convergence cross-checks. See
[../../TR2_THE_RULES_CONFLICT.md](../../TR2_THE_RULES_CONFLICT.md) §"Stop-flag resolution"
for the narrative and [README.md](README.md) for the bundle index.

**Calibration veto (2026-08-03; note added 2026-08-06 —
[CORRECTIONS CX-25](../../../documentation/CORRECTIONS.md)).** The verdict this bundle re-affirms
has since lost its calibration support: the two-model pair (M_corr vs M_tend) failed its own
pre-registered confusability gate — Half B (M_tend self-recovery) **FAILED at 68/100** against a
bar frozen at 70 (Half A passed 93/100). The published BF and ≈0.9998 posterior are **no longer
calibrated in the pooled sense**; the numbers are unchanged and not withdrawn — what is withdrawn
is their *calibration support*. The N_gs measurement in this bundle is unaffected as a measurement.
See [../f11halfb/](../f11halfb/) and [TR-2](../../TR2_THE_RULES_CONFLICT.md) §"The result".
*(Superseded 2026-08-07 — [CORRECTIONS CX-26](../../../documentation/CORRECTIONS.md): the BF and
posterior are now **withdrawn as claimed results**, retained only as the as-computed record; this
bundle's measurements still stand as measurements.)*

## Primary measurement — four independent direct seeds

Each run: 5.5×10¹⁰ probes, 64 threads, composed in-walk triple-strict prune
(`SOLVE_KNUTH_MOORE_STRICT=1 SOLVE_KNUTH_GENDER_STRICT=1 SOLVE_KNUTH_SCORE=1
SOLVE_KNUTH_R11_HIST=1`), full-tree start (no prefix). The reported quantity is the
`R-C4 0-viol DERIVED-N_gs abs` scoreboard line.

| seed (base) | N_gs | printed 95% CI | relerr (SE/est) | hits | file |
|---|---|---|---|---|---|
| 1001 (`0x3e9`) | 4.152915×10²⁵ | [3.3819, 4.9239]×10²⁵ | 9.47% | 3000 | `seed1_1001.out` |
| 2003 (`0x7d3`) | 4.990590×10²⁵ | [3.6391, 6.3420]×10²⁵ | 13.82% | 2957 | `seed2_2003.out` |
| 3011 (`0xbc3`) | 4.343774×10²⁵ | [3.1595, 5.5280]×10²⁵ | 13.91% | 2909 | `seed3_3011.out` |
| 4013 (`0xfad`) | 4.525281×10²⁵ | [3.5888, 5.4618]×10²⁵ | 10.56% | 2939 | `seed4_4013.out` |

**Pooled central value (unweighted mean of the four equal-probe seeds): N_gs = 4.503×10²⁵.**

**Two reported error conventions** (the larger is adopted for all verdict arithmetic):
- Empirical between-seed scatter: SD 0.359×10²⁵ / √4 = SE 0.179×10²⁵ → **relerr 4.0%**.
- Conservative CLT-propagated SE from the four per-seed CIs: 2.77×10²⁴ →
  **relerr 6.14%**, 95% CI **[3.96, 5.05]×10²⁵**. Adopted. (It grazes the pre-registered
  ≤6% target; disclosed honestly. An empirical SD at n=4 is itself ~40%-noisy, so quoting
  the smaller SE would be the move a hostile reviewer punishes; the larger is adopted, and
  the verdict is insensitive to the difference — all BF arithmetic is run at the
  conservative CI endpoints.)

An inverse-variance-weighted mean (4.40×10²⁵) is carried as a sensitivity value only:
weighting by *estimated* variances of a right-skewed estimator systematically over-weights
low draws, so the equal-probe unweighted mean is the principled primary.

## The three convergence gates — all PASS

| Gate | Criterion (pre-registered) | Result | Verdict |
|---|---|---|---|
| 1 — seed consistency | χ² across the 4 seeds, reject at p < 0.01 | χ²₃ = 1.36, p ≈ 0.71 (max pairwise ≈ 1.06σ) | **PASS** |
| 2 — repaired stratified | pooled stratified within 2σ (combined) of the pooled direct | 4.34×10²⁵, **0.12σ** from direct | **PASS** |
| 3 — derived-CI cross-path | CI'd derived path within 2.5σ | DERIVED-N_gs = 1.977×10²⁵ (±65%, 14 hits), **1.9σ** below | **PASS** |

With all three gates green, the pre-registered "all three gates pass" convergence
criterion is literally satisfied.

### Gate 2 detail — the stratified instrument defect and its repair

The stratified-start estimator (56 branches, `stratified.out`) was **initially
un-poolable**: a naive sum of its 56 per-branch estimates came to 1.088×10²⁶ — 2.4× the
pooled direct value, 3.35σ high. The cause was a composition defect in the estimator: with
a fixed branch prefix, the Moore-strict walk state was not replayed from the prefix and the
prefix placements themselves were not validated against the strict predicates, so branches
whose fixed prefix already violates a strict rule were walked and counted rather than
pruned — an upward bias. The defect never touched the four-seed primary runs (no prefix;
slot 0 is the rhythm-exempt pure pair, so the zero-initialized Moore state is correct
there).

The defect was repaired with an **estimator-only, self-test-neutral** fix: the repaired
estimator replays the Moore-strict walk state from the fixed prefix and refuses to run on a
strict-violating prefix (reporting an exact-zero subtree count instead). The build's
self-test sha is unchanged. The repaired run (`stratified_repaired.out`) correctly zeroes
the **15 of 56 branches** whose fixed prefix violates a strict predicate and pools to
**4.34×10²⁵ ± 1.31×10²⁵ (30.2% relerr)** — 0.12σ from the pooled direct value.

## Additional correctness evidence (in every run)

- **Self-test / axis gates** (`battery.log`, `r11_verify.out`, `smoke.out`): the build
  self-test sha `403f7202…` reproduces (×4); the two-language `--r11-verify` KW
  axis-reproduction gate returns "R11 VERIFY: PASS" (all 8 axes OK); a 2×10⁹-probe
  instrument smoke run passes.
- **In-walk full-scan re-scorer** (all four seed files): "gender-strict leaf cross-check
  mismatches (must be 0): 0" — an independent re-scorer agrees at every reached leaf.
- **Exact-count audits** (`exact_audit.tsv`, `battery.log`): 24 deep-prefix subtrees
  (depths 20/22/24 × 8 seeds), Knuth estimate vs brute-force `exact_count`. Three subtrees
  are non-empty and reproduced by the estimator machinery to ≤0.11%: 253,232
  (est 2.5297×10⁵, +0.11%, 0.7σ); 75,971,424 (est 7.5958×10⁷, −0.02%, 1.0σ); 1,106,032
  (est 1.1063×10⁶, +0.03%, 2.4σ). **Scope precision:** the audits ran *without* the strict
  prunes (they validate the estimator machinery — probe weighting, CI construction, prefix
  handling, the canonical/C3 filter — against brute force, not the Moore/gender strict
  composition; the strict-composition evidence is the in-walk mismatches=0 line and the
  scoreboard strictness-saturation lines). The 21 empty audit subtrees are uninformative by
  construction (the estimator cannot invent leaves where none exist); the three non-empty
  cells carry the signal.

## Honest residuals

The direct estimator's CI rests on ~300 effective samples pooled, so its far tails are not
guaranteed — hence the conservative error convention. The pooled value 4.50×10²⁵ is **0.57σ
below** the single Phase-1 run it re-checks (5.00×10²⁵ ± 16.7%, from `r11_ngs.out`) —
consistent. No value across the conservative CI moves any of the 24 pre-committed BF
configurations below the "strong" band; the flip threshold is ≈ 52× the measured value.

**σ convention in this file, stated explicitly (corrected 2026-08-02).** Every σ quoted here is
|Δ| ⁄ √(SE₁² + SE₂²), using the *adopted* conservative CLT SE of the pooled value (2.77×10²⁴)
and the other quantity's own stated SE. That formula reproduces all three gate figures in the
table above to the digit — gate 1 max pairwise **1.06**, gate 2 **0.12**, gate 3 **1.92** — which
is why it is the house convention rather than an assumption. Applied to the Phase-1 comparison it
gives |5.003 − 4.503| ⁄ √(0.277² + 0.833²) = **0.57σ**.

This sentence read "**1.4σ above**" until 2026-08-02. Two defects, both now fixed: (a) the
direction was inverted — 4.50×10²⁵ is *below* 5.00×10²⁵; (b) 1.4 is |Δ| divided by the raw
between-seed **SD** (0.359×10²⁵ — the scatter of the individual seeds, stated two sections above
only as the input to SE = SD/√4), with the Phase-1 run's own ±16.7% omitted entirely. The SD is
neither of the two error conventions this file declares, and it is the *larger* divisor's
opposite: using it overstated the disagreement. Nothing depends on the figure in either
direction — the comparison is "consistent" at 1.4σ and at 0.57σ alike — and no Bayes factor,
gate verdict, count, or sha changes. TR-2 v1.19 removed the σ from its own copy of this sentence
on the ground that it was "not reconstructible from the stated errors"; it *is* reconstructible,
as shown above, and TR-2 v1.23 restores it under this convention.

## Provenance

- Phase-2 four-seed battery: worker `c237-r11p2` (Spot D64als_v7), 4 seeds ×
  ~9,600–9,700 s each; `r11_phase2_battery.sh` archived here; battery complete
  2026-07-12T15:26:52Z, rc=0; VM and all resources deleted, zero orphans; cost ≈ $6–7.
- Repaired stratified run: worker `r11-strat` (Spot D32als_v7),
  `r11_stratified_repair.sh` archived here; 56 branches × 3.57×10⁸ probes, wall ≈ 4,634 s;
  complete 2026-07-13T07:03:03Z, rc=0; VM deleted, zero orphans; cost ≈ $3.

Developed with AI assistance (Claude, Anthropic). The Knuth (1975) random-probe estimator
is standard prior art; nothing in the measurement methodology is claimed as novel. The
modeled rules belong to their authors (Moore, Schulz, Cook, Hacker & Moore, Rutt). All
population runs are reproducible from the public `solve.c` at the stated probe counts,
seeds, and environment flags.
