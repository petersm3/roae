# PRE-REGISTRATION — Half B extension to n=1000 (estimation, not a second gate)

**Written 2026-08-03, BEFORE the extended run is launched.** This document is written *after* seeing
the n=100 result and says so plainly; that is exactly why its purpose and its reporting rule are
fixed here in advance.

## What already happened, and what is NOT in question

The pre-registered Half B gate ran at n=100, seed 20260802, and returned **68/100 against a frozen
bar of 70 => VETO**. **That verdict stands and is not under review.** Nothing in this extension can
overturn it; the gate was specified in advance, it ran once, and it failed.

## The problem this extension addresses

The n=100 gate is **underpowered for its own bar**:

- Wilson 95% CI on 68/100 = **[0.583, 0.763]**. The bar 0.70 lies **inside** the interval.
- The instrument therefore cannot distinguish a true rate of 68% from 72%.
- Resolving 0.70 vs the pre-registered expectation of 0.77 at 95% confidence needs roughly **n≈700**.

So the veto is a real gate outcome, but the *parameter* it was testing is unmeasured. This extension
measures it.

## Design — deliberately nested, so no cherry-picking is possible

    python3 halfb_driver.py --roae ~/roae --n 1000 --seed 20260802 --procs 14

**Same master seed 20260802.** The driver derives per-draw seeds as `master + i`, so draws 0..99 of
this run are **bit-identical to the original gate run**. The n=100 result is a strict subsample of
the n=1000 result. There is no seed search, no re-roll, and the original outcome remains visible
inside the new one.

## What will be reported — fixed now, before the run

All three, unconditionally, whatever they show:

1. **Pooled first-rank rate at n=1000, with Wilson 95% CI.**
2. **Win rate by V bucket**, each with a CI — the full response curve, not a selected slice.
3. **Win rate by lambda**, each with a CI.

Plus the 2x2 confusion structure against Half A.

## NO NEW BAR IS DEFINED

This is the crux. **This extension defines no pass/fail threshold and cannot produce a "PASS".**
Adding a second bar after seeing the first one fail would be goalpost-moving. The deliverable is an
*estimate with uncertainty*, and the published epistemic status remains **"the pre-registered
calibration gate vetoed."**

## The V-conditional question, and its honest status

The n=100 data showed the failure is entirely concentrated at V=0 (0/30), while at V in 4..8 — the
neighbourhood of King Wen's V=6 — M_tend self-recovered 11/11. Under the lambda-grid prior the V
distribution is strongly **bimodal** (30 draws at V=0, 41 at V>=15, only ~11 near V=6), so the gate
spends most of its power far from the sequence the published inference is about.

**This is reported as a design observation, not as a rescue.** Two things are both true and both get
published:

- **A V=0 tendency draw lands inside the grand-strict set, which is exactly M_corr's support.** At
  V=0 the two models are genuinely confusable. That is a real limitation of the model pair and a
  reader is entitled to know it.
- **King Wen has V=6, not 0.** The limitation does not bite at the observed data — but "the method
  works where our data happens to sit" is a weaker claim than "the method is calibrated", and only
  the weaker claim is supported.

**No V-restricted bar will be defined, and the V-restricted rate will never be quoted as the gate
result.** Reporting the response curve lets a reader locate the confusability themselves without our
choosing a favourable window.

## Explicitly forbidden

- Re-running with fresh seeds until a pass appears.
- Quoting the V-restricted rate (e.g. 11/11) as though it were the gate outcome.
- Retrofitting the lambda grid to drop lambda=5,10.
- Describing the published BF as "calibrated" on the strength of anything in this document.

## Cost

~10x the 245 s n=100 run; ~40 min on 8 procs, less on 14. Under $1 of Standard VM time on
a 16-core Standard VM already provisioned for the campaign.
