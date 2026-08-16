# RESULTS — Half B of the two-class confusability gate: **VETO**

> **⚠ Before citing any figure below: this bundle is NOT independently re-runnable.** The Half A/B
> driver was held in orchestrator scratch storage that was cleared by an out-of-memory reboot on
> 2026-08-04; the registrations, the frozen bar, the published seed and the results survive, the code
> that produced them does not. The honest status is **attested, not reproducible** — one rung below
> the rest of `reports/evidence/`. Full disclosure: [README.md §"A reproducibility defect in this
> bundle"](README.md). Pointer added 2026-08-16: the defect was disclosed in the README but a reader
> landing on this file went straight to the numbers without meeting it.

**Run 2026-08-03T13:47-13:51Z on a 16-core Standard cloud VM. Seed `20260802`, n=100,
procs=8, wall 245.5 s.** Driver: `scratchpad/halfb_driver.py` (authored by Fable against the frozen
pre-registration `PREREG_TWO_CLASS_F11_CALIBRATION.md`). Artifacts retrieved before teardown:
`scratchpad/HALFB_RESULTS_20260803.json` (82,031 B), `scratchpad/HALFB_CONSOLE_20260803.log`.

## Verdict

    HALF B PRIMARY (variant U, conditioned) first-rank: 68/100 (frozen bar 70) => VETO (confusable)

| variant | first-rank | bar | verdict |
|---|---|---|---|
| **primary (U, conditioned)** | **68/100** | 70 | **VETO** |
| corrA | 68/100 | 70 | VETO |
| uncond | 69/100 | 70 | VETO |

Draw failures counted against M_tend: **0**. Ties (counted as losses): **0**.

## The failure is structural, not noise — it is entirely at high lambda

| lambda | M_tend wins | n | mean V | win rate |
|---|--:|--:|--:|--:|
| 0.1 | 21 | 21 | 25.2 | 1.00 |
| 0.2 | 9 | 9 | 22.3 | 1.00 |
| 0.5 | 14 | 14 | 17.9 | 1.00 |
| 1.0 | 10 | 10 | 8.2 | 1.00 |
| 2.0 | 11 | 12 | 3.8 | 0.92 |
| **5.0** | **3** | **16** | **0.2** | **0.19** |
| **10.0** | **0** | **18** | **0.0** | **0.00** |

**Mechanism.** As lambda rises the tendency model drives V -> 0, so its own draws land *inside* the
grand-strict set — which is exactly where M_corr places its mass. In that regime a strongly
tendency-generated sequence and a corrupted-perfect one are genuinely indistinguishable. The two
models converge. This is a property of the model pair, not a defect of the instrument.

## Why this is not an instrument artifact

- All **7 wiring gates PASS** (25.5 s), including the two that matter most:
  - **Gate 2** reproduced the published v1.12 headline from the driver's own L_tend machinery:
    **BF(U)=5264, BF(A)=6277** vs published ~5.2e3 / ~6.3e3, inside the pre-registered bands.
  - **Gate 6** — the Half-B-critical bridge — fresh `hits_for_seq(KW)` reproduces the archived exact
    enumeration, and `r11_calibration.l_corr` equals `compute_f11_bf.L_corr` to **<1e-9** for U-cond,
    A-cond and U-uncond. This is what licenses scoring a NEW tendency-drawn sequence under M_corr on
    the published footing.
  - **Gate 7** (GRAND full-path hits, 25.0 s) reproduced; decode trick verified on 3,031 children.
- Zero draw failures, zero ties — nothing was swept into a class by a failure convention.
- All three variants land below the bar, so it does not hinge on the conditioning choice.
- The shape matches the **pre-registered analytic expectation** (lam<=1 ~100%, lam=5 ~39%,
  lam=10 ~0%, expected ~77/100 sd ~4.2). Observed 68 is ~2 sd low, with the shortfall at lam=5 and
  lam=2. The prereg explicitly anticipated "a genuine ~1-in-20 chance of a veto at n=100."

## Consequence under the frozen interpretation rule

The prereg, written before any verdict-bearing number:

> If Half A >= 70/100: the M_corr half passes; the pair is NOT thereby calibrated — Half B
> (M_tend self-recovery) must also clear 70/100 before the published BF can be called calibrated.

and the four-class precedent: **VETO if any class ranks itself first in fewer than 70/100 draws.**

Half A **PASSED** at 93/100 (2026-08-02). Half B **FAILS** at 68/100. Therefore:

**The published F11 pair is NOT calibrated. The BF ~5.2e3-6.3e3 and the 0.9998 posterior lose their
calibration support.** The confusability veto engages for the pair. *(Update 2026-08-07 —
[CORRECTIONS CX-26](../../../documentation/CORRECTIONS.md): the consequence now goes further — the
BF and posterior are **withdrawn as claimed results**, not merely stripped of calibration support;
they stand as the as-computed record only.)*

## What must NOT happen

The seed `20260802` was fixed, published and recorded **before** launch. **This run is not to be
re-seeded or re-run.** Re-running until a pass appears would convert a pre-registered test into a
search, which is precisely the failure mode the pre-registration exists to prevent.

## Propagation required — DONE (CX-25 2026-08-04, CX-26 2026-08-07)

TR-2 described its calibration as **PARTIAL** on the grounds that the tendency half had
never run. That wording was too generous in one direction and too vague in the other: the half
ran, and it failed. Every site that leans on the F11 BF or the 0.9998 posterior as *calibrated* needs
review. This is an operator-gated edit — it changes a published epistemic status, and it should go
through CORRECTIONS.md as an append-only entry rather than a quiet reword. *(Done, in two stages:
CX-25 / TR-2 v1.25 propagated the veto on 2026-08-04; CX-26 / TR-2 v1.27 recorded the full
withdrawal of the BF and posterior as claimed results on 2026-08-07, operator-authorized.)*

## Judgement calls Fable flagged (prereg silent, all recorded before the run)

1. Master seed not specified by the prereg; `20260802` chosen (prereg freeze date), disjoint from the
   four-class seed space.
2. SMC particle count / retry policy mirrored verbatim from the instrument's own MD gibbs class
   (1200 particles, `_smc_retry` 6 growing tries).
3. Failure taxonomy: SMC extinction -> loss for M_tend (per prereg). An *instrument* assertion aborts
   with exit 3 and **no verdict** — scoring a broken instrument either way would be wrong.
4. 5 of 100 draws given the kmax=3 fast/slow hits audit, mirroring `phase_hits`. Strengthening only.
5. L_tend at V outside the mass table: numerator needs no m(V) entry, only Z does.

---

# EXTENSION RESULT — n=1000 estimation (pre-registered 2026-08-03, no bar)

Run per `PREREG_HALFB_EXTENDED_2026_08_03.md`: same master seed **20260802**, `--n 1000 --procs 14`,
wall 1651.9 s. Artifacts: `scratchpad/HALFB_N1000_20260803.{json,log}`.

## The gate verdict is UNCHANGED

**The pre-registered n=100 gate returned 68/100 against a frozen bar of 70. That is still the gate
outcome.** The driver's console prints `=> PASS` against a *scaled* bar of 700, and it emits its own
warning that this is illegitimate:

    WARNING: n=1000 is NON-FROZEN (prereg fixes n=100, bar 70); scaled bar 700 is exploratory only

The pre-registration defines **no bar at n=1000 and cannot produce a PASS**. It is an estimate.

## Nesting verified

**The first 100 draws of the n=1000 run give exactly 68/100 — bit-identical to the gate run.** The
veto is literally embedded inside the larger sample. No seed search, no re-roll, no cherry-picking
was possible by construction.

## The estimate

| | |
|---|---|
| first-rank | **714 / 1000 = 0.714** |
| Wilson 95% CI | **[0.685, 0.741]** |
| is the 0.70 bar inside the CI? | **YES** |
| draw failures | 0 |
| ties | 0 |
| secondary | corrA 714/1000, uncond 717/1000 |

**Even at n=1000 the interval straddles the bar.** So the honest reading of the veto is not "the
method is broken" and not "the method passes" — it is **"the pooled rate sits so close to the
threshold that a 100-draw test is near a coin flip."** 68 vs 71.4 at n=100 is ordinary sampling
noise, not bad luck.

## Where the failure lives — and it is total, not partial

### by lambda

| lambda | wins | n | rate | 95% CI |
|--:|--:|--:|--:|---|
| 0.1 | 151 | 151 | 1.000 | [0.975, 1.000] |
| 0.2 | 146 | 146 | 1.000 | [0.974, 1.000] |
| 0.5 | 151 | 151 | 1.000 | [0.975, 1.000] |
| 1.0 | 113 | 113 | 1.000 | [0.967, 1.000] |
| 2.0 | 132 | 144 | 0.917 | [0.860, 0.952] |
| **5.0** | 21 | 156 | **0.135** | [0.090, 0.197] |
| **10.0** | 0 | 139 | **0.000** | [0.000, 0.027] |

### by V — King Wen has V=6

| V | wins/n | rate | 95% CI |
|---|---|--:|---|
| **0** | **0/277** | **0.000** | **[0.000, 0.014]** |
| 1-2 | 56/63 | 0.889 | [0.788, 0.945] |
| 3-4 | 59/61 | 0.967 | [0.888, 0.991] |
| **5-7** | **51/51** | **1.000** | **[0.930, 1.000]** |
| 8-12 | 77/77 | 1.000 | [0.952, 1.000] |
| 13+ | 471/471 | 1.000 | [0.992, 1.000] |

**At V >= 5, M_tend self-recovers 599/599 — perfectly, with no exceptions.** At V=0 it recovers
**0 of 277**, upper CI bound 0.014. This is not a gradient; it is a step function.

## What this does and does not license

**It does NOT license calling the published BF calibrated.** The pre-registered gate vetoed; the CI
still straddles the bar at n=1000; and the prereg explicitly forbids that inference.

**It does license a sharper and more useful statement than either verdict alone:**

- At V=0 the two models are **provably confusable** — a V=0 tendency draw lands in the grand-strict
  set, which is exactly M_corr's support. 0/277 with an upper bound of 1.4%.
- At V>=5 they are **provably distinguishable** — 599/599.
- The lambda-grid prior places **27.7% of its mass at V=0**. So the pooled statistic is dominated by
  a regime **the observed data does not occupy**, and the pooled veto is substantially a statement
  about the prior's mass distribution rather than about distinguishability at the observed V.

## Recommended published wording

> The pre-registered two-class confusability gate **vetoed** for the F11 pair: M_tend self-recovery
> was 68/100 against a frozen bar of 70/100 (n=1000 estimate 0.714, 95% CI [0.685, 0.741]). The
> failure is confined to the V=0 stratum, where the models are provably confusable (0/277, upper
> bound 1.4%); at the violation level of the observed sequence (V=6) self-recovery is 51/51
> (95% CI [0.930, 1.000]). **The published Bayes factor should therefore not be described as
> calibrated in the pooled sense.**

## The proper next instrument, if one is wanted

A **V-matched gate** — "at V ~= 6, are M_corr and M_tend distinguishable?" — is the question the
published claim actually turns on. It would be a **new instrument** and its bar must be frozen
before it runs. Nothing in this document may be used to argue for a threshold chosen after seeing
these numbers.
