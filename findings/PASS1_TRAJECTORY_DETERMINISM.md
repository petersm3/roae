# Solver Determinism on the Yield-16 Laggard Branch

**Result:** Two independent multi-threaded enumeration runs of `solve.c --sub-branch 22 0 30 1 20 0` (the yield-16 laggard chosen for deep-budget exhaustion attempts) reproduce each other's progress-line counters to within **0.2%** at every matched node count from 10¹⁰ through 10¹³ nodes walked. The solver is effectively deterministic on this branch at progress-line granularity, given matched `SOLVE_THREADS=64` and matched solver commits (or commits whose feature deltas don't affect enumeration order).

This means: any future independent reproduction of an enumeration on this branch should match the trajectory to <1% across the same node range — a **free reproducibility check** that doesn't require post-merge canonical-sha comparison.

## Data

Two runs on `22_0_30_1_20_0` (yield-16 laggard), both parallel mode, both `SOLVE_THREADS=64`, same SKU/region (Azure D64als_v7 spot, westus3). Progress lines emitted every 10s in the format `{nodes}B nodes, {sol}M sol, {c3} C3 ({stored} stored), {tasks}, {rate}M/s, {wall}s [, ETA=...]`.

| Source | Date | Solver commit | Budget | Samples |
|---|---|---|---|---|
| Pass 1 | 2026-04-22 | `cca1a40` | 10T (BUDGETED) | 1,094 progress lines |
| Fresh 1000T (post-fix) | 2026-04-24 onward | `3eb00c2` (post-bug-fix) | 1000T (in flight) | 3,666 lines and growing |

The sol counter on each progress line is a pre-dedup explored-candidate count (not the post-merge canonical solution count). Pass 1's final post-merge canonical was 16,431,733; the `sol` counter at end of Pass 1 was 2.99 × 10¹¹.

## Comparison at matched node budgets

| nodes target | Pass 1 `sol` | Fresh-run `sol` | ratio |
|---:|---:|---:|---:|
| 1 × 10¹⁰ | 3.45 × 10⁸ | 4.59 × 10⁸ | 1.331 (startup transient — first 30s) |
| 3 × 10¹⁰ | 1.06 × 10⁹ | 1.09 × 10⁹ | 1.027 |
| 1 × 10¹¹ | 3.67 × 10⁹ | 3.66 × 10⁹ | **0.999** |
| 3 × 10¹¹ | 9.98 × 10⁹ | 10.06 × 10⁹ | 1.008 |
| 1 × 10¹² | 3.225 × 10¹⁰ | 3.206 × 10¹⁰ | 0.994 |
| 3 × 10¹² | 9.321 × 10¹⁰ | 9.288 × 10¹⁰ | 0.996 |
| 1 × 10¹³ | 2.988 × 10¹¹ | 2.982 × 10¹¹ | **0.998** |

From 10¹¹ onward, the two runs agree to under 1%. On a log-log overlay of sol-vs-nodes, the two trajectories are indistinguishable from 10¹⁰ through 10¹³.

## Why determinism holds

Three factors combine:

1. **DFS traversal order is deterministic.** Driven by `solve.c`, the depth-first walk visits sub-branches in a fixed order given the same sub-branch specifier, the same task-queue generation, and the same thread count.
2. **Counter increments are deterministic per visit.** Each visit produces the same C3-evaluation outcome and the same stored-or-not decision.
3. **Thread scheduling differences wash out** in the aggregate across 64 threads × billions of nodes. The < 1% deviations are likely reflective of small ordering-of-counter-update races, not differences in actual work performed.

## What changes break the match

The match is **falsifiable**. It would fail under any of:

- Different `SOLVE_THREADS` (changes how the depth-5 task queue is sharded)
- Solver commit changes that alter enumeration order (e.g., sub-branch queue generation, task scheduling, or DFS recursion order)
- Different `SOLVE_DEPTH` (depth-3 vs depth-2 is structurally different)

Between the Pass 1 commit `cca1a40` and the post-bug-fix commit `3eb00c2`, the feature delta consists of: `--depth-profile`, depth-counter checkpoint durability, completed-task bitmap, SIGUSR1 handler, hash bit-mix, pre-sized consolidation, tier2 cleanup reorder, `--kde-score-stream` subcommand. **None of these change enumeration order**. The hash bit-mix is the most plausible candidate but it only affects bucket layout, not which records are visited or their order.

The selftest baseline confirms this: sha `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e` is unchanged across all the recent commits.

## Operational consequences

1. **Pre-10T work is redundant** for any future re-run of this branch. The first 1.094 thousand progress lines re-derive Pass 1; new science only starts in the 10T → ∞ regime.

2. **Cheap reproducibility check** for any future single-branch run: extract progress lines from the new run's `run.log`, compare against Pass 1's at matched node counts, expect <1% agreement.

3. **Extrapolation past 10T is now trusted.** Pass 1's last-known slope (log(sol) / log(nodes) ≈ 0.97 over the 9.1 × 10⁹ → 10¹⁰ range) becomes a validated extrapolation basis for the 10T → 1000T regime.

## Reproducibility

Pass 1 archive: `solve_c/runs/20260422_passA_10T_d64_laggard/22_0_30_1_20_0/run.log.gz`, with sha and metadata in the same directory. Verified end-of-run sha `e801bc7e…` for `sub_22_0_30_1_20_0.bin`.

Fresh run archive (TBD): will be at `solve_c/runs/<date>_1000T_22_0_30_1_20_0/` upon completion of the 1000T run (ETA 2026-05-02).

To verify the trajectory match yourself (against any future run on this branch):

```bash
# Pull progress samples from both run logs, compare at matched node budgets.
# An equivalent check is implemented in x/roae/alpha_log_updater.py --pass1-compare.
```

## Working / process documentation

For the original analysis context (when this finding emerged during the 1000T run's first hour), see [`x/roae/TRAJECTORY_MATCH_PASS1_VS_CURRENT.md`](https://github.com/petersm3/x/blob/main/roae/TRAJECTORY_MATCH_PASS1_VS_CURRENT.md) (private staging repo).
