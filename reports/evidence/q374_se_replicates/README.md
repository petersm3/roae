# Q-374 SE validation — 12 independent-seed replicates at 10⁷ probes (2026-09-02)

**What this is.** The evidence behind [METHODS.md](../../METHODS.md) §"Knuth estimator CIs"
(the 2026-08-28 Q-374 addendum): the delta-method standard errors printed as `se=` on every
Davis (2012) mass line are checked against the between-replicate scatter of 12 runs that
differ ONLY in their RNG seed. Twelve replicates, run **serially** on a 2-core host, ~68 s each.

**Seeds (explicit).** `SOLVE_KNUTH_SEED` = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 — printed by
each artifact as `[knuth] RNG SEED OVERRIDE ACTIVE: base=0x…` (stderr) and
`KNUTH-PROVENANCE seed_base=0x…` (stdout). `SOLVE_KNUTH_SEED=0` is NOT an override (the
binary falls back to the fixed base `0x243F6A8885A308D3`); none of the twelve equals it.
Thread count is part of the sample (per-worker seed = base ^ ((i+1)·0x9E3779B97F4A7C15)):
all twelve ran at `SOLVE_THREADS=2`, recorded on each `KNUTH-ESTIMATE … threads=2` line.

**Reproduce (from the repo root; the estimator needs a ≥16 MB stack):**
```
gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz
ulimit -s unlimited; bash reports/evidence/q374_se_replicates/run_replicates.sh
python3 reports/evidence/q374_se_replicates/analyze.py reports/evidence/q374_se_replicates
```
Each replicate is `SOLVE_THREADS=2 SOLVE_KNUTH_SCORE_DAV=1 SOLVE_KNUTH_SEED=<k> ./solve --estimate-knuth 10000000`
with stdout+stderr captured to `rep<kk>_seed<k>.out`. Output is byte-identical only at identical
(probes, threads, seed) and binary; a different host or compiler may differ in the last digits.

**Build provenance of the archived run.** `solve.c` sha256
`2776543195a15aedce5a8ba04d1f35f76cab4bf107664fd31bb3dd475abccb68` (tree `a4479176`, clean vs HEAD);
binary sha256 `23798b06f5f525dd2fb383abc5bb8aa627e05237d629f1ed09bb3af50c6acd71`;
`gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0`; build flags as above plus `-DGIT_HASH="a4479176"`; Linux x86-64, 2 cores.

## Ratio definition
For each mass m ∈ {below, at, above} of each of the 9 Davis candidates:
**ratio = (mean over the 12 replicates of the printed `se=`) / (sample SD, n−1, of the 12 estimates).**
If the printed SE is correct, SD/SE ~ √(χ²₁₁/11), so the two-sided 95% band on SE/SD is
**[√(11/21.92), √(11/3.816)] = [0.71, 1.70]**. Rows with zero sampled mass in every replicate are
degenerate (SD = SE = 0) and are reported as such, not as ratios.

## Result (`analyze.py` output, verbatim)
```
REPLICATES=12 SEEDS=0x0000000000000001,0x0000000000000002,0x0000000000000003,0x0000000000000004,0x0000000000000005,0x0000000000000006,0x0000000000000007,0x0000000000000008,0x0000000000000009,0x000000000000000a,0x000000000000000b,0x000000000000000c
CHI2_BAND_SE_OVER_SD_95=[0.708, 1.698] (dof=11)
ESTIMATOR_TOTAL leaves_canonical_C1C5(field; oriented count) replicate_relSD=0.91% mean_printed_relerr=1.25% ratio_SE/SD=1.376
candidate     mass       mean_est  replicateSD    mean_se    SE/SD verdict
termruns      below  1.519477e-03    4.552e-04  4.568e-04    1.004 in-band
termruns      at     2.512973e-02    2.552e-03  1.919e-03    0.752 in-band
termruns      above  9.733508e-01    2.542e-03  1.977e-03    0.778 in-band
compmirror    below  9.889025e-01    1.458e-03  1.348e-03    0.924 in-band
compmirror    at     1.108446e-02    1.469e-03  1.347e-03    0.917 in-band
compmirror    above  1.303667e-05    4.260e-05  1.218e-05    0.286 OUT-OF-BAND
trigarray     below  9.992303e-01    3.614e-04  3.315e-04    0.917 in-band
trigarray     at     7.670550e-04    3.626e-04  3.314e-04    0.914 in-band
trigarray     above  2.680833e-06    9.287e-06  2.681e-06    0.289 OUT-OF-BAND
parallel3040  below  1.000000e+00            0          0      n/a DEGENERATE (zero sampled mass in every replicate)
parallel3040  at     0.000000e+00            0          0      n/a DEGENERATE (zero sampled mass in every replicate)
parallel3040  above  0.000000e+00            0          0      n/a DEGENERATE (zero sampled mass in every replicate)
palnbr        below  9.209133e-01    3.503e-03  3.211e-03    0.917 in-band
palnbr        at     5.877592e-02    2.729e-03  2.792e-03    1.023 in-band
palnbr        above  2.031079e-02    1.978e-03  1.668e-03    0.844 in-band
rotinv        below  9.999481e-01    5.831e-05  4.038e-05    0.693 OUT-OF-BAND
rotinv        at     5.186583e-05    5.831e-05  4.038e-05    0.693 OUT-OF-BAND
rotinv        above  0.000000e+00            0          0      n/a DEGENERATE (zero sampled mass in every replicate)
pureplace     below  9.946540e-01    5.678e-04  8.854e-04    1.559 in-band
pureplace     at     5.345955e-03    5.678e-04  8.854e-04    1.559 in-band
pureplace     above  0.000000e+00            0          0      n/a DEGENERATE (zero sampled mass in every replicate)
eccplace      below  1.000000e+00            0          0      n/a DEGENERATE (zero sampled mass in every replicate)
eccplace      at     0.000000e+00            0          0      n/a DEGENERATE (zero sampled mass in every replicate)
eccplace      above  0.000000e+00            0          0      n/a DEGENERATE (zero sampled mass in every replicate)
asymhalf      below  4.762815e-02    2.170e-03  2.546e-03    1.173 in-band
asymhalf      at     1.463820e-01    3.029e-03  4.374e-03    1.444 in-band
asymhalf      above  8.059899e-01    3.387e-03  4.867e-03    1.437 in-band
```

## Reading
* **Every mass with ≳10 hits per replicate is in-band.** The seven `at=` masses the METHODS
  sentence names: termruns 0.75, compmirror 0.92, trigarray 0.91, palnbr 1.02, rotinv 0.69,
  pureplace 1.56, asymhalf 1.44 — six of seven inside [0.71, 1.70]. `leaves_canonical`: printed
  relerr 1.25% vs replicate relSD 0.91%, ratio 1.38, in-band (the field is an oriented total under a
  misleading name — CORRECTIONS.md Q-321/Q-330 — so only its relative scatter is used).
* **The exception is hit starvation, not the formula.** `rotinv` averages ≈1 hit per replicate
  (≈18,000 canonical leaves × 5.2×10⁻⁵): 2 of 12 replicates hit nothing and print `se=0`, the other
  10 are mostly single hits (`se` = the estimate). Its 0.69 sits marginally below the band floor.
  The two rarer tails — `compmirror above` (3 of 12 replicates nonzero) and `trigarray above`
  (1 of 12) — print SE/SD ≈ 0.29. **The delta-method SE understates in the zero/single-hit regime**
  because a replicate with no hit prints `se=0`; that is METHODS' zero-hit/starvation caveat, now
  measured. It affects no published classification (every threshold verdict reads a mass with
  hundreds to thousands of hits at 2×10⁹ probes; `rotinv`'s CI is published with that caveat).
* **Pooled masses reproduce the archived 2×10⁹ run** (`dav_tier1.out`): trigarray at 7.67×10⁻⁴ ±
  1.05×10⁻⁴ (SE of the mean of 12) vs 6.79×10⁻⁴; rotinv 5.19×10⁻⁵ ± 1.7×10⁻⁵ vs 6.53×10⁻⁵;
  pureplace 5.346×10⁻³ ± 0.164×10⁻³ vs 5.5615×10⁻³ — all within ≈1.3 SE.

## What this supersedes
A 12-replicate validation run on 2026-08-28 (ratios reported as 0.73–1.45) recorded neither its seeds
nor its outputs — only "`SOLVE_KNUTH_SEED` varied". It could not be reproduced by anyone, including
its author, and is withdrawn as unreproducible; the numbers above replace it. The two runs agree in
verdict (SEs sound where hits exist; extremes at the rarest masses) but not in the per-mass values,
which is expected at 12 replicates (SD-of-SD ≈ 21%).
