# Pass 1 — Single-branch 10T on yield-16 laggards (2026-04-22)

**Campaign:** Single-branch exhaustion plan, Pass 1.
**Target class:** The two lowest-yield branches from the 100T d3 canonical (both yielded **16 canonical solutions** at 100T per-sub-branch budget ≈ 631M nodes). **Scope (added 2026-09-19):** "yield-16" is a property of *that budgeted sample*, not of the branch. The 16 is what a ≈631M-node per-sub-branch slice returned; it is a **lower bound** on the branch's C1–C5 population, not a measure of tree size. The same "yield = k is a budget artifact, not a structural class" result was recorded for the yield-1,116 cohort in `documentation/HISTORY.md` (2026-04-23).
**Budget:** 10T nodes per branch (**15,836×** the 100T per-sub-branch budget — corrected 2026-09-19 from "1,580×", an order-of-magnitude slip: 10¹³ ÷ (10¹⁴ ÷ 158,364) = 15,836.4).
**Purpose:** Test whether yield-16 branches can be pushed toward EXHAUSTED with a tractable budget ladder.
**Answer:** **No** — super-linear growth persists. Tree is much bigger than 10T. Exhaustion-via-budget is infeasible for this class.

> **⚠ CORRECTION — 2026-09-19. THE GROWTH RATE AND THE "ANSWER" ABOVE ARE SUPERSEDED, AND THE
> CONCLUSION IS INVERTED.** The measured tables below are untouched and still stand; what was wrong
> is the *comparison* built on top of them.
>
> This page was corrected **the next day**, 2026-04-23, by `documentation/HISTORY.md` (commit
> `3812cf8e`) — but the correction was never propagated here, including through a later edit to this
> file on 2026-09-05.
>
> **What was wrong.** The 1T baseline of **960** in the Growth-analysis table below came from a
> *legacy single-threaded* 1T probe, and is not comparable with this run, which is P1-parallel at
> depth-5 task granularity. A fresh **P1-parallel** 1T run on `22_0_30_1_20_0` yields
> **4,899,772** canonical solutions, not 960: at equal budget the parallel solver spreads the work
> across 2,507 simultaneous tasks and finds roughly 5,000× more canonical solutions than legacy DFS.
>
> **The corrected, like-for-like comparison** — 1T P1-parallel **4,899,772** → 10T P1-parallel
> **16,431,733** — is a ratio of **3.354×** for a **10×** budget increase, i.e.
> **α ≈ 0.53 — SUB-linear**, not super-linear.
>
> **This inverts the conclusion.** Sub-linear growth means the branch is *approaching* exhaustion
> rather than running away from it. The tree-size estimate for the yield-16 laggards drops from
> 10¹⁶⁺ to **10¹⁴–10¹⁵**, and exhaustion becomes feasible at **100T–1000T on Azure D64 Spot
> (~$5–$50)**. The following statements on this page are therefore **superseded and should not be
> cited**: the **Answer** line above ("super-linear growth persists … Exhaustion-via-budget is
> infeasible for this class"); the "**~1,700× super-linear**" growth figure; the Pass-2/Pass-3
> yield projections in *Implication for single-branch exhaustion*; and "Pass 2 … is **NOT
> recommended**" under *Next steps*.
>
> **"A very tight lower bound" is also wrong — but not in the direction of a withdrawal.** The
> 16.4M figure remains a **valid** lower bound; a lower bound is not falsified by the truth turning
> out larger. It is simply not a *tight* one: the same branch went on to yield **664,086,250**
> canonical orderings at 100T (`documentation/HISTORY.md`, 2026-04-29 pilot), **40.4×** the number
> described here as "very tight".
>
> **Provenance note on the 960.** The access-boundary paragraph at the foot of this page (added
> 2026-09-05) states that "every number above comes from the run artifacts in this directory". That
> is **not true of the 960**: its cited source `runs/20260420_singlebranch1T_d32westus3/` has **no
> tracked files** in this repo, so that figure cannot be checked from here. Its replacement,
> 4,899,772, is recorded in `documentation/HISTORY.md` as cited above.
>
> *Correction authored 2026-09-19 (backlog row Q-647). The measured tables in "Results summary" and
> "Growth analysis" are deliberately left verbatim — this is a run record, and its measurements are
> not in dispute. Developed with AI assistance (Claude, Anthropic); errors are Claude's, corrections
> invited.*

## Results summary

| Branch | p1 o1 p2 o2 p3 o3 | Status | Canonical solutions | Wall | Output bytes | sha256 |
|---|---|---|---|---|---|---|
| `22_0_30_1_20_0` | 22 0 30 1 20 0 | BUDGETED | **16,431,733** | 3h 02m 27s | 525,815,456 (502 MB) | `e801bc7e4789...` |
| `22_1_30_1_20_0` | 22 1 30 1 20 0 | BUDGETED | **16,433,267** | 2h 52m 37s | 525,864,544 (502 MB) | `7a58a8688...` |

Both branches remained BUDGETED at 10T; neither EXHAUSTED. The per-branch node-count actually run (per checkpoint meta) was 10,000,002,145,312 / 10,000,002,204,300 — budget was enforced within ~0.00002% of the 10T target.

## Growth analysis

| Budget | Yield (branch 22_0_30_1_20_0) | Yield (branch 22_1_30_1_20_0) |
|---|---|---|
| 631M (100T/158,364 — the 100T per-sub-branch budget) | 16 | (same, per 100T canonical) |
| 1T (from `runs/20260420_singlebranch1T_d32westus3/`) | 960 | 960 (same, per Recon) |
| **10T** (this run) | **16,431,733** | **16,433,267** |

Growth from 1T → 10T: **17,118× yield / 10× budget = ~1,700× super-linear.** That's vastly above the √(budget) rule-of-thumb extrapolation and shows these trees are enormous (far larger than 10T nodes).

**Implication for single-branch exhaustion:** this class of "low 100T yield" branches does NOT exhaust at 10T. Pass 2 at 100T is projected to produce yields of ~170M-1.7B solutions per branch (still BUDGETED), and Pass 3 at 300T would produce even more. None of these will EXHAUST at feasible budgets.

**Scientific takeaway:** "yield-at-100T is a poor proxy for tree size" (already noted in 2026-04-20 Recon) is now **quantitatively confirmed at 10T scale**. The yield-16 laggards aren't small trees that are hard to exhaust; they're trees where most paths get pruned late by C1-C5 constraints, producing few canonical solutions per billion nodes explored. The trees themselves are vast.

## Binary output location

Both `sub_*.bin` files (502 MB each) are archived on the `solver-data-westus3`
managed disk at `/data/archive/passA_10T_d64_laggard/<branch>/sub_<branch>.bin`.
They are NOT committed to this public repo (too large for git comfort).
sha256 + metadata + log (gzipped) are in each branch subdirectory.

Verification recipe:
```bash
# Attach solver-data-westus3 to any VM, then:
cd /data/archive/passA_10T_d64_laggard/22_0_30_1_20_0
sha256sum -c sub_22_0_30_1_20_0.sha256  # (after copying .sha256 from this repo)
#
# This plain form is correct FOR THIS RUN because it predates #169 (d8671550,
# 2026-06-17): both archived shards are raw, headerless bytes, confirmed by the
# sidecars' own arithmetic — 525,815,456 = 16,431,733 x 32 and
# 525,864,544 = 16,433,267 x 32, exact, with no framing overhead. So the sha256
# sidecar (which since #169 holds the LOGICAL, decompressed sha) and the on-disk
# bytes coincide here.
#
# Do NOT carry this recipe to a post-#169 archive. Shards are gz-framed by
# default now, and `sha256sum -c` would hash the gzip container and report
# FAILED on a byte-correct artifact. There the command is:
#     gzip -dc sub_<branch>.bin | sha256sum   # compare to line 1 of the .sha256
# See documentation/SOLUTIONS_FORMAT.md §"On-disk framing".
```

## Compute summary

- 2 × D64als_v7 spot in westus3, ~3 hrs each
- Cost: ~$2.82 on successful runs (D64 spot ≈ $0.47/hr × 6 VM-hours)
- Plus ~$0.70 wasted on a mid-run IP/name-mixup recovery (see operator log)
- Checkpoint interval: 60s; no actual evictions hit during the run

Commit of solver used: `cca1a40` (P1 v3 with per-CCD counters + intra-sub-branch checkpointing).

## Next steps

Pass 2 (100T × this pair) is **NOT recommended** — growth rate says it still won't exhaust, and compute is 10× more.

Better path forward for the single-branch exhaustion thread:
- **Take 10T yields (16.4M per branch) as a very tight lower bound** on the true C1-C5-valid count from each prefix. This is a publishable result in itself.
- **Abandon the "exhaust a specific branch" approach** for this low-100T-yield class. The trees are too large.
- **Shift focus to Campaigns C (cross-prefix-equivalence, free) + B (orientation-symmetry, cheap)** per `roae-private/SINGLE_BRANCH_NEXT_STEPS.md` (private repo).

> **Access boundary.** `SINGLE_BRANCH_NEXT_STEPS.md` lives in `petersm3/roae-private`, which is
> **not publicly accessible**; a reader cannot fetch it. It is cited only as the planning record for
> where effort went next. It carries no evidence for any measurement on this page — every number
> above comes from the run artifacts in this directory.
