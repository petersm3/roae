# PRE-REGISTRATION — the V-matched confusability gate (a NEW instrument)

**Written 2026-08-04, BEFORE any V-matched draw is generated or scored.** Operator authorised the run
("do the recommendations including optional compute"); this document exists so that authorisation
buys a *test* and not a *search*.

## The question, and why it is not the question Half B answered

Half B asked: **pooled over the λ-grid prior, does M_tend recover itself?** It vetoed at 68/100
against a frozen bar of 70, and an n=1000 nested extension put the rate at 0.714, Wilson 95% CI
[0.685, 0.741] — an interval that still straddles the bar.

That pooled statistic is dominated by a regime the observed data does not occupy: the λ-grid places
**27.7% of its mass at V=0**, where the two models are provably confusable (0/277). The received
sequence has **V=6**.

So the question the published Bayes factor actually turns on is narrower:

> **At V ≈ 6 — the violation level of the received sequence — are M_corr and M_tend distinguishable?**

**This is a new instrument, not a re-run of Half B, and it cannot overturn Half B's verdict.** Half B
vetoed; that stands, is already propagated into the public record (CORRECTIONS CX-25, TR-2 v1.25),
and nothing here withdraws it.

## THE CONTAMINATION DISCLOSURE — read this before the bar

**I have already seen V-stratified results from the n=1000 extension**: at V=5–7 self-recovery was
51/51, and at V≥5 it was 599/599. Any threshold I invent now is chosen with that knowledge. That is
precisely the goalpost-moving this project's process rules forbid, and it is the reason the operator
was first offered the choice of setting the bar personally or declining the test.

**Resolution: no new number is invented. The bar is inherited.**

## THE FROZEN BAR — 70/100, per class, ties count as losses

**70/100** is this project's standing confusability threshold. It was fixed before any V-stratified
data existed and has governed every prior gate of this kind:

- the four-class gate (M_G failed at 67/100 → permanent withholding, TR-2 v1.14),
- Half A (M_corr, PASSED 93/100),
- Half B (M_tend, FAILED 68/100).

Adopting the pre-existing project-standard threshold is **inheriting** a number, not **choosing**
one. No other value was considered, and had the V-stratified counts pointed the other way the bar
would be the same, because it is not mine to move.

**VETO if either class ranks itself first in fewer than 70/100 V-matched draws.** Ties are losses.
Draw failures count against the class that failed. Both classes must clear the bar; a pass by one is
not a pass.

## Design — fixed now

- **n = 100 per class**, V-matched to the received sequence's violation level.
- **V band: V ∈ {5, 6, 7}.** Chosen because exact V=6 conditioning may not admit enough M_corr draws
  without rejection-sampling bias; the band is the narrowest symmetric window around 6 that keeps
  both generators in their natural support. **This band is frozen here and will not be widened,
  narrowed, or re-centred after seeing any result.**
- **Master seed: `20260804`** — published here, before launch, disjoint from `20260802` (Half A/B)
  and from the four-class seed space.
- Scoring, conditioning variants (U-cond primary, A-cond and U-uncond secondary), SMC particle
  count and retry policy: **identical to the Half A/B driver**, unchanged, so this gate differs from
  Half B in exactly one respect — the V-conditioning.
- The same seven wiring gates must PASS before any verdict is read. A wiring-gate failure is exit 1
  and yields **no verdict**; an instrument assertion is exit 3 and yields **no verdict**. Neither is
  scored as a pass or a fail.

## What will be reported — fixed now, whatever it shows

1. Per-class first-rank counts against the 70 bar, with Wilson 95% CIs.
2. The realised V distribution of the accepted draws, so a reader can confirm the matching worked.
3. The rejection rate of the V-conditioning, per class — if one class needs far more rejection than
   the other, that asymmetry is itself reportable and will be reported.
4. Draw failures and ties, explicitly, even at zero.

## Explicitly forbidden

- Re-running with a fresh seed until a pass appears.
- Moving, widening or re-centring the V band after seeing any count.
- Reporting this gate's result as though it lifted Half B's veto. **It cannot.** At most it
  establishes that the confusability Half B found is confined to a stratum the received sequence
  does not occupy — which is a *narrower and weaker* claim than "the pair is calibrated", and only
  the narrower claim may be published.
- Describing the published BF as "calibrated" on the strength of anything in this document.

## If it passes

The publishable statement is bounded in advance: *"the pooled confusability gate vetoed; a
V-matched gate at the received sequence's violation level, pre-registered at the same inherited
threshold, did not."* Both halves of that sentence ship together or neither does.

## If it fails

It ships too, in the same place and with the same prominence, and the two-model result loses its
last calibration support. This is stated here so that publishing a failure requires no further
decision.

## Cost

~100 draws × 2 classes on an existing D16; well under $1 of VM time. No new infrastructure.
