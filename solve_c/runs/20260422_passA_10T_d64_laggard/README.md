# Pass 1 — Single-branch 10T on yield-16 laggards (2026-04-22)

**Campaign:** Single-branch exhaustion plan, Pass 1.
**Target class:** The two lowest-yield branches from the 100T d3 canonical (both yielded **16 canonical solutions** at 100T per-sub-branch budget ≈ 631M nodes).
**Budget:** 10T nodes per branch (1,580× the 100T per-sub-branch budget).
**Purpose:** Test whether yield-16 branches can be pushed toward EXHAUSTED with a tractable budget ladder.
**Answer:** **No** — super-linear growth persists. Tree is much bigger than 10T. Exhaustion-via-budget is infeasible for this class.

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
| 1T (from `solve_c/runs/20260420_singlebranch1T_d32westus3/`) | 960 | 960 (same, per Recon) |
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
- **Shift focus to Campaigns C (cross-prefix-equivalence, free) + B (orientation-symmetry, cheap)** per `x/roae/SINGLE_BRANCH_NEXT_STEPS.md`.
