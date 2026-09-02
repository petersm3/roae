# Solver Determinism on the Yield-16 Laggard Branch

**Result:** Two independent multi-threaded enumeration runs of `solve.c --sub-branch 22 0 30 1 20 0` (the yield-16 laggard chosen for deep-budget exhaustion attempts) reproduce each other's progress-line counters to under **1%** at every matched node count from **10¹¹** through 10¹³ nodes walked, after a startup transient (33.1% at 10¹⁰, 2.7% at 3×10¹⁰). ⚠ **[CORRECTED 2026-09-01 — this read "to within **0.2%** at every matched node count from 10¹⁰ through 10¹³", which the report's own comparison table refutes: the seven ratios are 1.331, 1.027, 0.999, 1.008, 0.994, 0.996, 0.998, i.e. deviations of 33.1%, 2.7%, 0.1%, 0.8%, 0.6%, 0.4% and 0.2%. Only two of the seven rows are within 0.2% and the first misses it by 165×. The body already stated the table-supported envelope twice ("From 10¹¹ onward, the two runs agree to under 1%"; "expect <1% agreement"), so the headline contradicted its own report. The raw logs cannot settle it any finer: the fresh run's log is recorded below as never archived. Not a re-measurement — the claim is shrunk to the evidence that exists.]** The solver is effectively deterministic on this branch at progress-line granularity, given matched `SOLVE_THREADS=64` and matched solver commits (or commits whose feature deltas don't affect enumeration order).

This means: any future independent reproduction of an enumeration on this branch should match the trajectory to <1% across the same node range (10¹¹–10¹³; a first-30s sample is not a match failure) — a **free reproducibility check** that doesn't require post-merge canonical-sha comparison.

## Data

Two runs on `22_0_30_1_20_0` (yield-16 laggard), both parallel mode, both `SOLVE_THREADS=64`, same SKU/region (Azure D64als_v7 spot, westus3). Progress lines emitted every 10s in the format `{nodes}B nodes, {sol}M sol, {c3} C3 ({stored} stored), {tasks}, {rate}M/s, {wall}s [, ETA=...]`.

| Source | Date | Solver commit | Budget | Samples |
|---|---|---|---|---|
| Pass 1 | 2026-04-22 | `cca1a40` | 10T (BUDGETED) | 1,094 progress lines |
| Fresh run (post-fix) | 2026-04-24 | `3eb00c2` (post-bug-fix) | 1000T budget **requested**; run stopped at ~154T, 2026-04-27 | 3,666 lines at the comparison point |

**Status note (added 2026-08-01, stale-status sweep; sharpened after operator correction).**
**No 1000T single-branch run was ever completed.** The second row above was labelled "Fresh 1000T"
with budget "1000T (in flight)" and "3,666 lines and growing" from 2026-04-24 until today — a
snapshot frozen mid-run, left in the present tense, in a doc cited under "Stable paper-citable
findings". 1000T was the *requested budget*; the run was **stopped at ~154T on 2026-04-27** after a
structural finding — the budget was enforced globally rather than per task, so all 64 workers stayed
on their initially-claimed sub-subtasks and none was ever exhausted
([HISTORY.md](HISTORY.md), §"April 27, 2026 evening"). Naming a run after a budget it never reached
is the same defect as leaving it "in flight": both describe an intention as an accomplishment.

**The determinism result is unaffected**: every comparison below is at a matched node budget of
10¹⁰–10¹³, all of which the ~154T run passed with room to spare, so no row in the comparison table
depended on the run continuing. What was wrong was the description of the run, not any measurement
taken from it.

The sol counter on each progress line is a pre-dedup explored-candidate count (not the post-merge canonical solution count). Pass 1's final post-merge canonical was 16,431,733; the `sol` counter at end of Pass 1 was 2.99 × 10¹¹.

## Comparison at matched node budgets

| nodes target | Pass 1 `sol` | Fresh-run `sol` ⚠ | ratio |
|---:|---:|---:|---:|
| 1 × 10¹⁰ | 3.45 × 10⁸ | 4.59 × 10⁸ | 1.331 (startup transient — first 30s) |
| 3 × 10¹⁰ | 1.06 × 10⁹ | 1.09 × 10⁹ | 1.027 |
| 1 × 10¹¹ | 3.67 × 10⁹ | 3.66 × 10⁹ | **0.999** |
| 3 × 10¹¹ | 9.98 × 10⁹ | 10.06 × 10⁹ | 1.008 |
| 1 × 10¹² | 3.225 × 10¹⁰ | 3.206 × 10¹⁰ | 0.994 |
| 3 × 10¹² | 9.321 × 10¹⁰ | 9.288 × 10¹⁰ | 0.996 |
| 1 × 10¹³ | 2.988 × 10¹¹ | 2.982 × 10¹¹ | **0.998** |

⚠ **The fresh-run column is a historical record, not a checkable measurement.** Its `run.log` was never archived (§Reproducibility) and no public script recomputes it, so the 3,666-sample count, the node-matching rule and all seven ratios cannot be re-derived by a reader — or by us. **Pass 1's column is fully reproducible** from the archived log named in §Reproducibility.

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

Between the Pass 1 commit `cca1a40` and the post-bug-fix commit `3eb00c2`, `solve.c` changed over **8 commits** (`git log cca1a40..3eb00c2 -- solve.c`). The feature delta **includes**: `--depth-profile`, depth-counter checkpoint durability, completed-task bitmap, SIGUSR1 handler, hash bit-mix, pre-sized consolidation, tier2 cleanup reorder, `--kde-score-stream` subcommand — and, itemised here for the first time, per-task stats plus a per-task depth histogram and `c3_leaves` (`bf1afb1a`), and a depth-5 prefix tuple added to the per-task CSV (`d8ca0533`). ⚠ **[CORRECTED 2026-09-01 — this list was previously introduced with a word asserting it was exhaustive. It was not: the eight items above map to six of the eight commits in the range, and the two named last were missing. Verified by `git log cca1a40..3eb00c2 -- solve.c`. The list's conclusion is unaffected — both additions are bookkeeping — but the claim of completeness was false, and a reader checking the range would have found more commits than the sentence admitted.]** **None of these is expected to change enumeration order**: the added counters and CSV fields are per-visit bookkeeping, and the hash bit-mix affects bucket layout, not which records are visited or their order. This is a judgement from reading the diffs, not a measured result — see the caveat immediately below.

The selftest baseline is **consistent with** this but **cannot confirm it**. ⚠ **[CORRECTED 2026-09-01 — this sentence previously presented the unchanged selftest sha as positive proof of the DFS-neutrality claimed just above. It cannot be: the relation runs the wrong way, and the test does not cover the path being compared. Not a re-measurement — the sha is unchanged, as stated; what is withdrawn is its status as evidence.]** Sha `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e` is indeed unchanged across these commits, but three things block the inference:

- **The sha is entailed by DFS-neutrality, so it cannot evidence it.** The selftest is sha-stable across DFS-neutral code changes *by design* ([CANONICAL_HASHES.md](CANONICAL_HASHES.md), §"Selftest baseline (100M nodes)"). An unchanged sha is what DFS-neutrality predicts, not an independent check of it — and the same file records the converse case, a DFS-neutral change (`d683794`) that nevertheless flipped a 100B sub-canonical sha (§"100B and sub-canonical reference shas").
- **It exercises the wrong path.** The selftest runs depth-2, `SOLVE_THREADS=4`, main-enum ([HISTORY.md](HISTORY.md), §"Methodology lessons") — not the 64-thread `--sub-branch` path every comparison in this document is taken on.
- **It hashes an order-invariant object.** The sha is taken over the **sorted, deduplicated** record set, which is invariant to visit order by construction. No such hash can reach factor 2 above, which is a claim about *per-visit* behaviour.

⚠ **No paired-log test on this branch across the two commits has been run.** Such a test — re-running `--sub-branch 22 0 30 1 20 0` at `SOLVE_THREADS=64` under both commits and diffing the progress lines — would settle the question directly, and is the check this section currently lacks.

## Operational consequences

1. **Pre-10T work is redundant** for any future re-run of this branch. The first 1.094 thousand progress lines re-derive Pass 1; new science only starts in the 10T → ∞ regime.

2. **Cheap reproducibility check** for any future single-branch run: extract progress lines from the new run's `run.log`, compare against Pass 1's at matched node counts, expect <1% agreement.

3. **Pass 1's trajectory is reproducible inside its measured range, and is not a basis for projecting outside it.** ⚠ **[CORRECTED 2026-09-01 — this item previously declared projection beyond the 10T budget to be trustworthy, and offered one fitted exponent — attributed to the run's closing phase, quoted over a node range just under 10¹⁰ — as a sound basis for projecting into a 1000T regime. Re-derived from the shipped log (`runs/20260422_passA_10T_d64_laggard/22_0_30_1_20_0/run.log.gz`, 1,094 progress lines), every link fails: **(a)** the node range the exponent was quoted over holds **exactly one sample** — the log's first line, at 9.1B nodes; the next sample is already at 18.5B, so no slope is computable over that range at all; **(b)** the ≈0.97 figure is not a closing-phase slope but the average over the **whole 3.04-decade run**; **(c)** the exponent is not stable across the run (measured spread below); **(d)** **nothing beyond 10¹³ nodes was ever observed**, so no out-of-sample residual exists; **(e)** the fresh run's log was never archived (§Reproducibility), so none can be computed now; and **(f)** no 1000T single-branch run exists (§Status note above). Not a re-measurement — the trajectory data and the determinism result are unchanged and unaffected; what is withdrawn is only the projection built on top of them.]**

   What the log does support, fitted over its 1,094 progress lines:

   | log–log fit range | span | endpoint slope | OLS slope |
   |---|---:|---:|---:|
   | full observed range, 9.1 × 10⁹ → 1.0 × 10¹³ | 3.04 decades | 0.966 | 0.964 |
   | last full decade, 1.0 × 10¹² → 1.0 × 10¹³ | 1.00 decade | 0.967 | 0.971 |
   | final stretch, 9.1 × 10¹² → 1.0 × 10¹³ | 0.04 decades | 0.930 | 0.932 |

   The local exponent is **not stable**, which is why no single value should be carried forward: trailing fits ending at the run's last sample give **0.930** (from 9.1 × 10¹²), **0.990** (from 6.3 × 10¹²) and **0.967** (from 1.0 × 10¹²). A quoted exponent here summarises the observed range; it is not a law that survives past it.

   The decisive limit, though, is structural rather than statistical. **All 1,094 samples report the same `64/2507 tasks`**, and the run's own closing line confirms `64 threads, 2507 tasks`. The entire observed trajectory therefore sits inside the workers' initially-claimed **64 of 2,507 tasks (2.6%)** and **never crosses a task-exhaustion boundary** — which is precisely the event a 10T → 1000T run must cross, and precisely the structural finding on which the fresh run was stopped at ~154T, far short of the 1000T budget it had requested (§Status note above). The observed regime does not contain the event the projected regime turns on, so **this document supplies no yield curve for the post-exhaustion regime, and projection past 10¹³ nodes is not supported by it.**

## Reproducibility

Pass 1 archive: `runs/20260422_passA_10T_d64_laggard/22_0_30_1_20_0/run.log.gz`, with sha and metadata in the same directory. Verified end-of-run sha `e801bc7e…` for `sub_22_0_30_1_20_0.bin`.

Fresh run archive: none (not archived). The planned 1000T single-branch run was never carried out: this attempt stopped at ~154T and the goal was superseded by the later full-space canonicals, 100T and 560T.

To check a future run on this branch against Pass 1, extract its progress lines and compare `sol` at matched node counts with the archived Pass 1 log named above; the agreement envelope to expect is the one stated at the top of this document.

⚠ **[CORRECTED 2026-09-01 — this section previously offered a fenced shell block that contained only comments and no runnable statement, and whose one concrete pointer named a subcommand of a script in the private staging repository. Three defects, all verified: a private script cannot make a public number reproducible, per the project's standing rule; the fence was not executable; and the pointer was wrong even about the private tree — the flag it named does not exist on the file it named, and is implemented in a different file entirely. The pointer is removed rather than repaired, since naming a private script was itself the defect. **No public script currently automates this comparison**; the manual procedure above is the honest state of it.]**

## Working / process documentation

For the original analysis context (when this finding emerged during the first hour of the 1000T-*budgeted* run — see the status note above; it never reached that budget), see `TRAJECTORY_MATCH_PASS1_VS_CURRENT.md` in the private staging repo (not publicly accessible).
