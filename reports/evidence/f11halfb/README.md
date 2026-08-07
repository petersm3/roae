# Two-class confusability gate (Half A / Half B) — evidence bundle

The pair behind TR-2's published Bayes factor — **M_corr** (corrupted precursor) versus **M_tend**
(soft-preference arranger) — put through the same style of pre-registered synthetic-draw
confusability gate that the four-class extension faced in [../r11/](../r11/).

| half | question | result |
|---|---|---|
| **A** | does M_corr recover itself? | **PASS 93/100** (2026-08-02) |
| **B** | does M_tend recover itself? | **FAIL 68/100** (2026-08-03) → **VETO** |

Bar **frozen at 70/100** before the run; master seed `20260802` **published before launch**, so a
disappointing result could not be quietly re-rolled. It was not re-run and will not be.

A nested **n=1000** extension (same seed — the original 100 draws are bit-identical inside it)
estimates the rate at **0.714, Wilson 95% CI [0.685, 0.741]**, an interval that still straddles the
bar. The failure is a **step function confined to one stratum**: at **V=0** the models are provably
confusable (**0/277**, upper bound 1.4%), because a V=0 tendency draw lands inside the grand-strict
set that is M_corr's own support; at **V≥5** they are provably distinguishable (**599/599**). The
received sequence has **V=6**, where self-recovery is 51/51.

**What this changes**: the published BF and the ≈0.9998 posterior are **not calibrated in the pooled
sense**. They are unchanged and not withdrawn; their *calibration support* is. See
[CORRECTIONS](../../../documentation/CORRECTIONS.md) CX-25 and
[TR-2](../../TR2_THE_RULES_CONFLICT.md) §"The result". *(Superseded 2026-08-07 — CX-26: the
"not withdrawn" half of that sentence no longer holds. The BF and posterior are now **withdrawn as
claimed results** — retained as the as-computed record, recorded, not claimed — pending the
V-matched gate below.)*

**What it does NOT license**: calling the pair calibrated on the strength of the V≥5 stratum. The
extension's registration defines **no bar at n=1000 and cannot produce a PASS**. The question the
published claim actually turns on — *at V≈6, are these two models distinguishable?* — needs a **new**
instrument with its threshold frozen in advance. That registration is published here as
[PREREGISTRATION_VMATCHED](PREREGISTRATION_VMATCHED.md), **filed before the gate has been run**, with
its bar inherited from the project's standing 70/100 rather than chosen after seeing the
V-stratified counts, and with the resulting contamination disclosed in the document itself.

## A reproducibility defect in this bundle, stated plainly

**This bundle is not independently re-runnable, and [../f11/](../f11/) and [../r11/](../r11/) are.**
Those carry their instruments (`compute_f11_bf.py`, `f11_events.py`) so a third party can regenerate
the numbers. **The Half A/B driver does not survive**: it was held in scratch storage on the
orchestrator, which suffered an out-of-memory failure and forced reboot on 2026-08-04 that cleared
that storage. The registrations, the frozen bar, the published seed and the per-half results survive;
the code that produced them does not.

So the honest status of the veto recorded here is **attested, not reproducible** — one rung below
the standard the rest of this directory meets. It is recorded rather than hidden because a veto a
reader cannot re-run is exactly the kind of claim this suite's authorship disclosure
([METHODS](../../METHODS.md) §"Authorship independence") says to flag. Reconstructing the driver
from the frozen registration is possible and would restore parity; until that is done, this notice
stands.
