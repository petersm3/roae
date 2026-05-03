# Large-Scale Enumeration Campaign Guide

This document is for anyone who wants to run their own large-scale
enumeration of orderings satisfying the King Wen constraints
(C1–C5) at high node-budget. It captures lessons learned from the
project's actual campaigns (10T canonical, 100T pilot, 11.2T
validation, 560T plan) and gives you a framework for scaling up to
560T, 5,600T (= 5.6 PT), 56,000T (= 56 PT), or beyond.

If you're producing a *new canonical sha* (intended as a
publishable reference), follow this guide carefully — the
correctness story depends on disciplined VM sizing, validation,
and reproducibility-evidence capture, not just compute throughput.

## 1. Decide what you actually want

Before sizing anything, answer these questions:

1. **What scale of solution count do you want?**
   The number of unique solutions found grows sub-linearly with
   per-cell budget. Empirical curve from this project's runs:

   | Per-cell budget | Approximate solutions | Notes |
   |---|---|---|
   | 70 M (Tier 1's depth-3 70M) | 759 M unique | The current canonical |
   | 141 M (Tier 5's 2× on branch 22-0) | +50 % on that branch | Proves *at least one* cell hit Tier 1's 70M cap (otherwise no gain would be possible). Per-cell BUDGETED counts weren't recorded for Tier 1 or Tier 5 so the prevalence isn't directly confirmed; the magnitude is suggestive of a widespread effect but not definitive. |
   | 3.5 G (560T plan) | 1.2–1.5 B (estimated) | Modest gain over Tier 1 |
   | 35 G (5.6 PT plan) | 4–8 B (estimated) | 5–10× Tier 1 |
   | 100 T (per single cell) | ~664 M (one cell only) | 100T pilot — directly observed: 0 of 975 walked depth-5 sub-tasks naturally terminated; all hit per-task cap. This IS confirmed (per_task_stats.csv was captured). |

2. **Are you trying to prove a theorem (cell exhausts → no
   solutions exist with prefix X)?**
   The project's 100T pilot ran a single depth-3 cell at 100 T
   per cell and naturally exhausted **zero of 975** depth-5
   sub-tasks. Search trees at depth 4-5 are deeper than 40 G
   nodes per task. Theorem-level results require **>>100 T per
   cell**, possibly 1000 T+ — and even then no guarantee any cell
   exhausts.

3. **Is this a research run or a published canonical?**
   - **Research:** lower budgets are fine; flexibility on
     methodology.
   - **Canonical:** every record must be *enumerated*, not
     inferred. Symmetry shortcuts are okay only if proven as
     theorems first. See §10.

4. **What do you intend to do with the data?**
   Most analytical questions (apply a new constraint as filter,
   compute statistics, find symmetries, SAT-cross-check) need
   only `solutions.bin`. A few questions (extend the run,
   identify which cells are budget-exhausted) need
   *side-metadata*, captured during the run via `SOLVE_DEPTH_PROFILE=1`.
   See §11.

## 2. Sizing: choose VM size, count, and budget

### 2a. Architectural cap: ~64 useful threads per single-branch run

`solve --branch <p1> <o1>` parallelizes across ~2,824 depth-3
sub-branches per first-level branch. Empirically, per-thread rate
**halves past 64 threads** due to NUMA boundaries (D128 has two
sockets) and hash-table contention. **D64-class VMs are the right
size** for single-branch enumeration. D128 wastes half its cores
unless you run two concurrent `--branch` jobs on it.

### 2b. VM count: cost-equivalent, wall-time-different

Total compute cost for a campaign of fixed size is roughly the
same regardless of VM count (D-als-v7 spot pricing is near-linear
in cores). What VM count buys you is **wall time** and **eviction
redundancy**.

| VMs | Aggregate cores | Wall (560T) | Cost | Eviction blast |
|---|---|---|---|---|
| 1 × D64 | 64 | ~5.6 days | ~$60 | one VM eviction halts campaign |
| **2 × D64** (recommended for 128-vCPU spot quota) | 128 | **~3.4 days** | ~$80 mid | redundant — one VM evicts, other progresses |
| 4 × D64 (needs 256-vCPU quota) | 256 | ~1.7 days | ~$80 mid | best |

For 5.6 PT or 56 PT campaigns, scale up VM count proportionally
to keep wall under ~10 days; cost scales linearly with budget.

### 2c. Per-thread rate by workload

| Workload | Per-thread rate | Use this rate when... |
|---|---|---|
| Tier 1's full-enum (`solve 0 N`, no `--branch`) | ~1.4 M nodes/sec/thread | Estimating wall for full-enum-style runs at very low per-cell budget (overhead-dominated) |
| `--branch X Y` at small budget per cell (~35 M) | ~9 M nodes/sec/thread | Estimating wall for `--branch` mode where most cells naturally terminate |
| `--sub-branch ...` or `--branch X Y` at large budget per cell (≥3 G) | ~21 M nodes/sec/thread | Estimating wall for budget-bound work (most cells hit per-task cap) |

**Pick the rate that matches your workload type before estimating
cost.** Mixing them gives wrong answers by 10×. The 560T plan uses
the 9–21 M range; pick ~15 M for a midpoint estimate.

## 3. Budget semantics — what "10T per branch" actually means

`SOLVE_NODE_LIMIT` is a **cap**, not a target. Total nodes walked
is always ≤ the cap, typically less. Two structural reasons:

### 3a. Per-sub-branch budget is what's binding

For `--branch X Y` mode, solve doesn't enforce the global node
limit directly during enumeration. Instead it computes (or accepts
override of) a **per-sub-branch budget**, and stops each cell when
it hits that. The global cap only acts as a coarse safety ceiling.

If you let the per-sub-branch budget auto-compute from
`SOLVE_NODE_LIMIT`, solve.c divides by 3030 (the depth-2 cell
count). At depth=3 the actual cell count is ~2,824, so:

| You set `SOLVE_NODE_LIMIT` to: | Auto-computed per-cell budget | Effective total at depth=3 (× 2,824 cells) |
|---|---|---|
| 10 T (intending "10T per branch") | 10T / 3030 = 3.30 B | **9.32 T per branch** (7% under) |
| 11.2 T (Tier 1's actual setting) | 11.2T / 3030 = 3.70 B | 10.43 T per branch |

**The auto-compute under-shoots at depth=3.** To target a precise
per-branch budget, **set `SOLVE_PER_SUB_BRANCH_LIMIT` explicitly**
to override the wrong divisor:

| Intended per-branch budget | Set `SOLVE_PER_SUB_BRANCH_LIMIT` to: | Effective per-branch (× 2,824) |
|---|---|---|
| 5.6 T | 1,982,000,000 | 5.60 T (exact, modulo int rounding) |
| 10 T | 3,541,500,000 | 10.00 T |
| 11.2 T | 3,966,000,000 | 11.20 T |
| 100 T | 35,410,400,000 | 100.0 T |

### 3b. Natural termination always leaves you under

Even with the per-cell budget set correctly, **most cells walk
fewer than per_cell_budget nodes** because they naturally terminate
(C2 / C3 / C5 pruning kills the branch, or the search tree is
genuinely finite at this depth). Total walked per first-level
branch = sum of per-cell walks, which is ≤ N_cells × per_cell_cap.

Empirical example: the 100T pilot targeted 100T per single
depth-3 cell, walked 99.43T (0.57% under). Two crashes contributed
to that under-shoot, but even on a clean run there's some natural-
termination contribution.

### 3c. Implications

- **You CANNOT guarantee total walked ≥ N nodes** (natural
  termination always permits less). If you need this property for
  some reason, you've designed wrong; reformulate.
- **You CAN guarantee per-cell-cap = K** (every BUDGETED cell
  walked exactly K). For canonicity (the SHA depends on which
  cells were budget-exhausted), this is the correct invariant.
- **For sha reproducibility:** lock `SOLVE_PER_SUB_BRANCH_LIMIT`
  explicitly, not via `SOLVE_NODE_LIMIT` auto-compute. Future
  changes to the auto-compute divisor would silently change shas.
- **For status reporting:** the per-cell BUDGETED count from
  `per_task_stats.csv` is the true measure of "how much budget
  did this campaign use." Report THAT, not the global cap.

## 4. Cost estimation methodology

Apply this formula:

```
total_node_budget    = 56_branches × per_branch_budget   (e.g., 56 × 10T = 560T)
aggregate_throughput = num_VMs × 64 × per_thread_rate    (use the rate from §2c)
wall_seconds         = total_node_budget / aggregate_throughput
cost                 = num_VMs × wall_hours × spot_$/hr   (D64 spot ~$0.50/hr in westus3 as of 2026-05)
```

Always **quote a range, not a point**: per-thread rate varies
substantially across workloads, and giving a single number creates
false precision. Express ranges as `(pessimistic, mid, optimistic)`
based on the §2c rate band that matches your workload.

## 5. Pre-flight validation — required before any campaign launch

The `solve.py --extended-selftest` test suite (9 subtests) is the
canonical pre-flight gate. It exercises:

1. Single-shot 3-way path equivalence at 100M nodes (recursive,
   iterative, iterative+v2)
2. v2 mid-walk resume invariance (50M → 200M)
3. v1 resume invariance (50M → 200M)
4. `--branch + depth-3 + SOLVE_THREADS=128` stack-array sizing
5. `--branch` multi-budget resume gate
6. Combined partition + resume invariance
7. Distributed-merge equivalence (multi-VM shard collection)
8. Single-branch eviction-resume invariance (SIGTERM mid-walk)
9. Idempotent re-launch of completed `--branch`

Run on the **exact campaign binary**, on each campaign VM, before
launch. Wall: ~17 min on a 4-core VM, ~5 min on a 64-core VM.

**For larger-scale campaigns (5.6 PT or 56 PT)**, also run
production-scale spot-checks — the project calls these "Tier 9+":

- **Pilot one branch at the chosen per-branch budget** on the
  intended VM size. Validates real wall time, real shard size,
  real disk-write throughput. Cost: 1/N of the campaign cost
  where N is the branch count (e.g., 1/56 of the total).
- **Merge memory-pressure test** — run `--merge` on a representative
  shard set, sample peak RSS. Tells you whether your intended
  merge VM has enough RAM. (For ≥5.6 PT campaigns, expect peak
  RSS in the 200–900 GB range; D64's 256 GB may not suffice.)
- **Cross-VM rsync integrity** — verify byte-identical transfer of
  shards across VMs.

### 5+. Operational pre-launch smoke test (right before launching the canonical run)

After all selftest + scale-validation tests have passed and
you're about to launch the actual canonical run, do a final
5-minute smoke test on each campaign VM. This isn't a correctness
test — selftest already covered that. It's an operational test:
verifies the locked binary runs, env vars are picked up, scripts
deploy, the data disk is writable, and shards write correctly.

```pseudocode
SCRIPT smoke_test():
  # Tiny budget; not a correctness test, just plumbing.
  ENV {
    SOLVE_DEPTH=2,
    SOLVE_NODE_LIMIT=100M,
    SOLVE_DFS_ITERATIVE=1,
    SOLVE_DFS_CHECKPOINT=1,
    SOLVE_THREADS=8,
  }
  RUN solve --branch 1 0 0 8  IN /tmp/smoke
  ASSERT exit_code == 0
  ASSERT count(sub_*.bin) >= 1
  ASSERT solutions_1_0.sha256 is non-empty
```

**Run this on each campaign VM before launching the actual
canonical-budget enum.** Wall: ~5 minutes. Cost: trivial. If it
fails, you've caught a deployment / env / disk / binary
issue at $0 cost instead of mid-canonical at $30+ wasted.

The smoke test is intentionally tiny (depth-2, 100M nodes, 8
threads) so it runs in minutes regardless of VM size.

## 6. Campaign architecture

The canonical pattern for a multi-VM single-branch campaign uses
two roles: a **per-VM branch runner** that iterates the VM's
assigned branches, and a **cross-VM orchestrator** that coordinates
the global merge once all VMs report completion.

### 6a. Design rules (apply to every script)

1. **Idempotent on relaunch.** No destructive `mv` or `rm` of
   in-progress data. Re-running a runner script after eviction
   must pick up where it left off via done-marker files + solve's
   own mid-walk checkpoint. The project's first `recovery.sh`
   had a destructive-`mv` bug that wiped partial work on
   restart — costly mistake; don't repeat it.
2. **Eviction-tolerant.** Spot evictions are certain over multi-day
   campaigns. No single point of failure: each VM operates
   independently from the others; the orchestrator only joins them
   at merge time.
3. **Verify the binary at every entry.** Stale binary on the VM
   cost the validation campaign ~$8 of wasted spot time. Always
   md5-check the binary before doing any work.
4. **Append-only logs, atomic markers.** Done markers are
   `touch`-ed only after the work succeeds AND the sha file is
   present. Never trust an exit code alone.
5. **No race conditions.** Pre-partition branch assignments (no
   dynamic claiming). Two VMs reading the same shared list of
   "available branches" is a race waiting to happen — instead,
   write `branches_A.txt` and `branches_B.txt` once before launch.

### 6b. Per-VM branch runner — pseudocode

```pseudocode
SCRIPT branch_runner(role):           # role is "A", "B", "C", ...
  ROOT       = "/mnt/work/campaign_..."
  SOLVE      = "$ROOT/bin/solve"
  WORKDIR    = "$ROOT/enum"
  LOG        = "$ROOT/logs/runner_${role}.log"
  BRANCHLIST = "$ROOT/branches_${role}.txt"

  # ---- Entry validation: don't start with bad state ----
  ASSERT BRANCHLIST exists                               (else: fatal)
  ASSERT SOLVE is executable                             (else: fatal)
  ASSERT md5(SOLVE) == cat("$ROOT/bin/solve.md5")        (else: fatal,
                                                          "binary stale")

  log "starting role=$role pid=$$"
  log "binary commit=" + cat("$ROOT/bin/solve.commit")

  # ---- Per-branch iteration: idempotent ----
  FOR each (p1, o1) in BRANCHLIST:
    DONE_MARKER = "$WORKDIR/done_${p1}_${o1}"
    IF DONE_MARKER exists:
      log "skip $p1/$o1 (done)"
      CONTINUE                    # already complete from a prior run

    log "launching --branch $p1 $o1"

    EXEC solve --branch $p1 $o1 0 64
         WITH ENV {
            SOLVE_DEPTH                  = 3,
            SOLVE_NODE_LIMIT             = $per_branch_budget,
            SOLVE_PER_SUB_BRANCH_LIMIT   = $per_sub_branch_budget,
            SOLVE_DFS_ITERATIVE          = 1,    # mid-walk resume
            SOLVE_DFS_CHECKPOINT         = 1,    # write checkpoint state
            SOLVE_DEPTH_PROFILE          = 1,    # per-cell stats CSV
            SOLVE_CKPT_INTERVAL          = 300,  # 5-min checkpoint cadence
            SOLVE_THREADS                = 64,
         }
         INTO $WORKDIR
         REDIRECT >> "$ROOT/logs/branch_${p1}_${o1}.log"

    rc = $?
    sha_file = "$WORKDIR/solutions_${p1}_${o1}.sha256"

    IF rc == 0 AND sha_file exists:
      sha = first_field(read(sha_file))
      atomic_touch(DONE_MARKER)              # only NOW mark complete
      log "DONE $p1/$o1 sha=$sha"
    ELSE IF rc != 0:
      log "$p1/$o1 exit=$rc; will retry next loop"
      # NB: DON'T touch DONE_MARKER. Solve's mid-walk checkpoint will
      # let the next iteration resume from where this attempt stopped
      # (or where the eviction killed it).
    ELSE:
      log "WARN $p1/$o1 exit=0 but no sha; not marking done"

  # ---- Completion signal ----
  n_done  = count(files matching "$WORKDIR/done_*")
  n_total = count(non-comment lines in BRANCHLIST)
  log "$n_done / $n_total branches complete"

  IF n_done == n_total:
    atomic_touch("$ROOT/${role}_complete")    # signal to orchestrator
    log "$role complete"
```

**Key correctness properties of this design:**

- **Crash-safe.** If the script (or the entire VM) dies anywhere
  during a branch's enum, the next launch reads the checkpoint
  files solve wrote and resumes. No work is rewound.
- **Eviction-safe.** Same as crash-safe; spot eviction is just a
  particular crash flavor.
- **Restart-safe.** Manually re-launching the script is a no-op
  for completed branches (skipped via DONE_MARKER) and a resume
  for the in-progress branch.
- **Verifies before claiming complete.** The DONE_MARKER is only
  touched after BOTH a clean exit AND a sha file exists. If solve
  exits 0 but failed to write the sha (e.g., disk-full mid-merge),
  it's not falsely marked done.

### 6c. Cross-VM orchestrator — pseudocode

```pseudocode
SCRIPT orchestrator():
  ROOT       = "/mnt/work/campaign_..."
  SOLVE      = "$ROOT/bin/solve"
  MERGE_DIR  = "$ROOT/merged"
  VM_NAMES   = list of campaign VMs (e.g., ["VM-A", "VM-B"])
  RG         = Azure resource group

  log "orchestrator starting"

  # ---- Phase 1: wait for all VMs to signal complete ----
  WAIT_LOOP:
    FOR each vm in VM_NAMES:
      complete[vm] = (
        run_remote_check(vm, "ls $ROOT/${vm.role}_complete 2>/dev/null && echo YES")
        contains "YES"
      )
    log "complete status: " + complete
    IF all(complete):
      BREAK
    sleep 30 minutes

  # ---- Phase 2: collect shards centrally ----
  # The choice of merge host depends on shard count and expected
  # solution count: D64 RAM (256 GB) suffices up to ~1.5 B
  # solutions; D128 (512 GB) up to ~4 B; E64ads_v5 (512 GB) or
  # larger memory-optimized for bigger.

  log "PAUSE: operator must rsync shards from each VM to $MERGE_DIR"
  log "  rsync -av <VM-A>:$ROOT/enum/sub_*.bin $MERGE_DIR/"
  log "  rsync -av <VM-B>:$ROOT/enum/sub_*.bin $MERGE_DIR/"
  log "  rsync -av <VM-A>:$ROOT/enum/per_task_stats_*.csv $ROOT/enum/"
  log "  rsync -av <VM-B>:$ROOT/enum/per_task_stats_*.csv $ROOT/enum/"
  log "  Then touch $ROOT/shards_collected and re-run"

  IF NOT exists("$ROOT/shards_collected"):
    EXIT 0      # orchestrator will be re-invoked after operator sync

  # ---- Phase 3: global merge ----
  n_shards = count(files matching "$MERGE_DIR/sub_*.bin")
  log "$n_shards shards in $MERGE_DIR; running --merge"

  EXEC solve --merge
       INTO $MERGE_DIR
       REDIRECT >> "$ROOT/logs/global_merge.log"

  ASSERT exit code == 0
  ASSERT exists("$MERGE_DIR/solutions.sha256")

  sha  = first_field(read("$MERGE_DIR/solutions.sha256"))
  size = stat_size("$MERGE_DIR/solutions.bin")
  log "global merge sha=$sha size=$size bytes"

  # ---- Phase 4: post-merge metadata extraction ----
  META_DIR = "$MERGE_DIR/metadata"
  mkdir(META_DIR)

  # 4a. Per-prefix yield report
  EXEC solve --branch-yield-report > "$META_DIR/branch_yield_report.txt"

  # 4b. Aggregate per_task_stats.csv from all branches
  WRITE header to "$META_DIR/per_task_stats_all.csv"
  FOR each f in glob("$ROOT/enum/per_task_stats_*.csv"):
    APPEND tail(f) to "$META_DIR/per_task_stats_all.csv"  # skip header

  # 4c. Constraint definitions snapshot
  EXEC solve --constraint-spec > "$META_DIR/constraint_definitions.json"
       OR fall back to a hand-extracted JSON from solve.c at locked commit

  # 4d. Concatenated per-branch run logs
  CAT $ROOT/logs/branch_*.log > "$META_DIR/all_branch_runs.log"

  # ---- Phase 5: write campaign metadata.json ----
  WRITE "$MERGE_DIR/metadata.json" with:
    campaign_name, completion_utc, sha256, solutions_bin_bytes,
    binary_md5, binary_commit, vms, vm_size, spot_priority,
    node_limit_per_branch, depth, threads_per_vm,
    side_metadata: { paths to all META_DIR files }

  atomic_touch("$ROOT/campaign_done")
  log "ORCHESTRATOR DONE; canonical at $MERGE_DIR/solutions.sha256"
```

**Key correctness properties of the orchestrator:**

- **Decoupled from VMs' interiors.** Polls only for completion
  markers; doesn't care how a VM got to "complete" (single run,
  multiple eviction-restarts, manual-resume after crash).
- **Operator-in-the-loop for shard transfer.** Cross-VM shard
  transfer is the highest-risk step (rsync edge cases, network
  flakes); have the operator confirm transfer integrity before
  the orchestrator proceeds. Tier 9c verifies the rsync pattern
  works byte-correctly at small scale.
- **All side-metadata captured atomically with the canonical sha.**
  `solutions.bin` and `metadata.json` should be archived together
  — they reference each other.
- **Re-runnable.** If the orchestrator dies between "merge done"
  and "metadata.json written," re-invoking it picks up at Phase
  4 (existing solutions.sha256 means Phase 3 is skipped).

### 6d. Failure modes and recovery

| Failure | What it looks like | Recovery |
|---|---|---|
| Spot eviction during enum | VM deallocates mid-`solve --branch X Y`. Solve was killed by the kernel. | After VM restart, re-launch branch_runner. The DONE_MARKER for the in-progress branch isn't there, so it re-runs `solve --branch X Y` — solve resumes from its mid-walk checkpoint. |
| Disk full during enum | Solve exits non-zero; partial shards may be on disk. | branch_runner doesn't touch DONE_MARKER (rc != 0). Operator clears space, re-launches branch_runner. Solve resumes from checkpoint. |
| Spot eviction during merge | Merge process killed mid-write. Partial solutions.bin or no solutions.sha256. | Restart merge from clean: `rm` partial outputs, re-run `solve --merge`. Shards are unchanged; merge is deterministic. Tier 9c validates this works. |
| Network partition during rsync | Some shards transferred, others not. | Re-run rsync with `--checksum` to verify byte-identity; rsync re-fetches missing/changed files. Tier 9c validates rsync correctness. |
| Two VMs accidentally claim same branch | Should not occur with pre-partition; if it does, two `sub_<p1>_<o1>_*` files are created and one overwrites the other. | Pre-partition correctly via `branches_A.txt` and `branches_B.txt` written once before launch. Don't use shared dynamic claim mechanisms. |
| Stale binary on a VM | Enum produces results that don't match the canonical workflow's expected behavior. May silently produce wrong shas. | Always md5-check the binary at branch_runner entry; abort if mismatch. The validation campaign caught this exact issue (Apr 30 binary on May 2 VMs). |
| Auto-merge sanity gate trips at high thread counts | At depth-3 with `SOLVE_THREADS=128` (and especially with the recursive DFS path, no `SOLVE_DFS_ITERATIVE=1`), the in-process auto-merge can emit "SANITY-WARN" lines and fail to write `solutions.sha256`. The enum completes correctly (all shards on disk); only the auto-merge step trips. | Run `solve --merge` manually in the affected dir. Shards are unchanged; the merge is deterministic and produces the correct sha. This is what Tier 6d / Tier 7a / Tier 7b small/128 hit during the 2026-05 validation campaign and was the planned recovery path. |
| Disk device numbering reshuffles after VM restart | After `az vm start`, the data disk that was `/dev/nvme0n3` may now be `/dev/nvme0n2` (or a different device entirely). Mount via the old path fails. | Use `lsblk` and/or `blkid` to identify the correct device by size/label/UUID. Mount by UUID where possible (e.g., `/etc/fstab` entries should use UUID, not `/dev/nvmeNnM`). Spot-restart resilience matters; this is observed every time. |
| Spot eviction during multi-day campaign | Eviction is **certain** over a 3+ day campaign. Multiple per VM is normal. | branch_runner is idempotent; re-launch after `az vm start` and disk re-mount. If eviction hits during the final merge, the solutions.bin may be partial — `rm` it and restart `solve --merge`. The 2026-05 validation campaign experienced 3+ evictions across its multi-day runtime. |
| 128-thread `--branch` post-enum per-branch merge SIGSEGV | At `SOLVE_THREADS=128` in `--branch X Y` mode (depth-3), the per-branch in-process merge step can SIGSEGV. The enum's shards are written correctly to disk; only the per-branch summary merge crashes. | Doesn't affect global merge correctness — the shards are intact and the next `solve --merge` produces the right sha. Continue the campaign. (Tracked as a known anomaly; selftest subtest 4 explicitly accepts this exit code.) |

### 6e. Reference scripts

The project's actual implementation of this pattern lives at:

- `petersm3/x:roae/560t_scripts/560t_branch_runner.sh`
- `petersm3/x:roae/560t_scripts/560t_orchestrator.sh`
- `petersm3/x:roae/560t_scripts/branches_A.txt`
- `petersm3/x:roae/560t_scripts/branches_B.txt`

Use them as a starting point; adapt VM names, paths, and budgets
to your campaign.

## 7. Branch distribution — balancing wall time across VMs

Tier 1's yield distribution shows orientation-0 branches have
roughly 5–10× more solutions than orientation-1 branches. If you
naively split 56 branches by orientation (one VM gets all o1=0,
other gets all o1=1), wall time is unbalanced.

**Balanced split:** mix orientations across VMs. For 2 VMs,
something like:

- VM-A: pair indices 1–15 + orientation, plus (16, 0) → 31 branches
- VM-B: (16, 1) + pair indices 17–31 + orientation → 31 branches

This balances both pair-index range AND orientation mix.
Pre-partition deterministically (no race) — both VMs read their
list from a shared file.

If a VM finishes early and the other has many branches left,
**don't** try to dynamically rebalance — let the slower VM finish.
Dynamic claim mechanisms add complexity for marginal speedup.

## 8. Eviction recovery

For each VM, on spot eviction:

1. Azure deallocates the VM (with `--eviction-policy Deallocate`).
2. Operator manually `az vm start <vm>` after capacity returns
   (typically minutes-to-hours).
3. VM boots, data disk re-mounts (the NVMe device numbering may
   reshuffle — handle generically).
4. Re-launch the branch runner script. It finds existing done
   markers and skips completed branches; for the in-progress
   branch (if any), solve resumes from its mid-walk checkpoint.

**Spot eviction during merge** is more delicate. Merges aren't
trivially resumable (unlike enumeration with checkpointing). If
merge is interrupted, restart it from clean — the shards are
unchanged. Tier 9c (mid-merge interruption recovery) verifies this
works correctly.

## 9. Merge VM sizing — and disk-based alternative for extreme scale

You have two strategies for the global merge: **in-memory dedup**
(simple, fast, what `solve --merge` currently does) or **disk-based
external merge** (needed when in-memory dedup would exceed available
RAM). Pick based on your campaign's expected solution count.

### 9a. In-memory merge (the default)

`solve --merge` builds a hash table of unique solutions in RAM,
streams shards through it, then writes the deduped output. RAM
usage is roughly proportional to unique-solution count:

| Solution count | Estimated peak RSS | Recommended merge VM | Strategy |
|---|---|---|---|
| ~750 M (Tier 1) | ~90 GB | D32als_v7 (128 GB) or D64 (256 GB) | in-memory |
| ~1.5 B (560T plan) | ~180 GB | D64als_v7 (256 GB) | in-memory |
| ~4 B (5.6 PT plan) | ~480 GB | E64ads_v5 (512 GB) — memory-optimized | in-memory, tight |
| ~8 B | ~960 GB | E96ads_v5 (672 GB) won't fit | **switch to disk-based** |
| ~10 B (56 PT plan) | ~1.2 TB | no Azure VM has this much RAM | **disk-based required** |

**Threshold:** in-memory merge starts to break around **5–6 B
solutions** in Azure (since the largest practical memory-optimized
spot VM is ~672 GB RAM and the price gets bad past that). Below
that, in-memory is faster and simpler.

For >2 B solutions, **always run a merge-memory test on a
representative shard set first** before committing to a merge VM
size. Cheap insurance against running out of RAM at the end of a
multi-day campaign.

### 9b. Disk-based external merge — when and how

When solution count exceeds practical RAM, the merge has to use
disk as the working set instead of the in-memory hash table. The
project's `solve.c` does not currently implement true external
sort + dedup, but you have three viable paths:

**Option 1: Layered merge (chunked dedup, available now)**

`solve --merge-layers <dir>` partitions shards into layers and
merges each layer separately, then merges the per-layer outputs.
RAM peak is bounded by the largest single layer, not the full
campaign.

For a 56 PT campaign at ~10 B solutions:
- Partition shards into ~10 layers of ~1 B solutions each
- Each layer's merge needs ~120 GB RAM → fits on D32
- Final inter-layer merge needs ~120 GB RAM
- Wall: ~10 × per-layer-merge + 1 × final-merge ≈ slow but feasible
- Trade-off: more total CPU and I/O, but bounded RAM

This is exactly the pattern Tier 6D used in the validation campaign.

**Option 2: External sort + linear-scan dedup (requires solve.c extension)**

Standard external-merge-sort applied to the 32-byte solution
records. Two phases:
1. Sort the concatenated shard byte-stream using disk-based
   K-way merge sort. Peak RAM bounded by chunk size (e.g., 8 GB
   per chunk). Disk I/O ~2× the input size.
2. Linear scan of sorted output, emitting only the first occurrence
   of each record. Peak RAM is O(1) (just the last record seen).

Wall scales as O(N log N) disk-bandwidth-limited, which on a
Standard SSD at ~500 MB/sec is ~6 hours per TB. Feasible for any
size, never bounded by RAM.

This is **NOT in `solve.c` today**. Adding it is a follow-on
project (would fit naturally with Tier 8 compression retooling —
both are I/O-pipeline work).

**Option 3: Bloom-filter-assisted multi-pass dedup**

For approximate dedup with high-probability correctness:
1. First pass: build a Bloom filter (~1 bit per record) of all
   shards. Peak RAM ~1.25 GB per 10 B records.
2. Second pass: emit records whose Bloom filter says "possibly
   first occurrence"; collisions get sent to a small per-record
   exact dedup hash table that's much smaller than the full set.

Net peak RAM ~10–50 GB regardless of solution count. Trade-off:
1–2 extra passes vs the in-memory case.

This is also **not in `solve.c` today**.

### 9c. Hybrid: split campaign into tiers, merge separately

Even simpler than the above for some workloads: don't try to merge
all 56 branches at once. Instead:

1. Run 56 branches as planned.
2. Group branches into "merge tiers" (e.g., 4 tiers of 14 branches each).
3. Run `solve --merge` on each tier's shards separately. Each
   produces a deduped tier-level `solutions.bin` (smaller).
4. `solve --merge-layers` combines the 4 tier outputs into a final
   global output.

This is an in-memory-only path that scales to RAM-limited hardware
without needing new code. Each step's peak RAM is bounded by
1/Ntiers of the full set.

Trade-off: each tier's merge re-deduplicates within-tier
duplicates that would have been deduped against another tier's
records. So total work is slightly more than a single global
merge, but RAM is bounded.

### 9d. Decision recipe

Given an estimated solution count S:

- S ≤ 2 B → in-memory merge on D64 (256 GB).
- 2 B < S ≤ 4 B → in-memory merge on E64ads_v5 (512 GB), confirm
  with merge-memory-test first.
- 4 B < S ≤ 8 B → in-memory merge on E96 (672 GB) is borderline;
  **prefer hybrid (§9c)** for safety, or accept the risk and
  run merge-memory-test first.
- S > 8 B → use hybrid (§9c) or disk-based external merge (§9b
  Option 1 with `--merge-layers`).
- S > 10 B → disk-based via `--merge-layers` is the only practical
  path with current `solve.c`. Adding Option 2 (true external
  sort) is a follow-on project worth scoping.

Run **a merge-memory test** in any case where peak RSS is within
2× of available RAM. Better to find out at small scale than at
the end of a multi-day campaign.

## 10. Symmetry shortcuts and other pruning — when defensible

The project's data shows orientation symmetry is **not universal**:
only 16.3% of multi-variant `(p1, p2, p3)` groups have all
orientations equal at 100T budget. Applying an "8× symmetry
speedup" blanket-everywhere is **not defensible** for a published
canonical — most prefixes don't have the symmetry, and the
empirical observation at one budget doesn't prove it at higher
budgets.

Three defensibility levels for using symmetry:

1. **Theorem-based** (defensible): prove the symmetry holds under
   C1–C5 for some structural property of prefixes; exploit only
   where proven. Probably weeks of math work.
2. **Empirical-verify per-prefix** (defensible but no speedup):
   enumerate all variants and check; using verification IS the
   work.
3. **Heuristic blanket-application** (NOT defensible): assume
   100T-symmetric implies higher-budget-symmetric without proof.
   Don't use this for a canonical sha.

For a research run that's not a canonical, level 3 is fine.

## 11. Side-metadata — what to capture beyond `solutions.bin`

`solutions.bin` contains all the orderings. From it alone you can:

- Apply a new rule that further filters existing solutions
- Compute per-prefix yield, position frequencies, joint statistics
- Test orientation symmetry empirically
- Cross-check with SAT solver output

What `solutions.bin` does NOT contain — capture these explicitly:

| Side-metadata | How | Why you might need it |
|---|---|---|
| `per_task_stats.csv` (per-cell yield + status + nodes-walked + wall) | Set `SOLVE_DEPTH_PROFILE=1` during enum | Identify which cells are budget-exhausted vs naturally-terminated. Essential for future asymmetric extension or theorem hunts. |
| `checkpoint.txt` | Auto-produced by solve | Records the per-sub-branch budget that was reached. Needed for resume + extension. |
| `branch_yield_report.txt` | Run `solve --branch-yield-report` post-merge | Pre-computed per-prefix counts at depths 1, 2, 3 |
| `constraint_definitions.json` | Manual extract from solve.c at locked commit | Future C6 / new-rule work needs to reference the EXACT C1-C5 used |
| All `sub_*.bin` shards + `sub_*.dfs_state` files | Auto during enum | Required for ANY future extension (deeper budget on one or more branches) |
| `metadata.json` (campaign metadata) | Orchestrator writes at end | Binary md5/commit, VM list, runtime, per-VM contribution, eviction events |

If you skip `SOLVE_DEPTH_PROFILE=1` to "save 1% of cycles", you
can never tell after the fact which cells were budget-exhausted.
That's the most-asked future question.

### 11a. Pre-record invariants — recompute on demand, don't pre-bake

A natural temptation is to extend `solutions.bin`'s record format
(currently 32 bytes/record) to include pre-computed per-record
invariants (cd, distance-sum, XOR-set, etc.). **Don't.** Two
reasons:

1. **Cache-line-friendly storage matters.** 32-byte records pack
   exactly two per 64-byte cache line. Going to 48 bytes/record
   means every other record straddles a cache line, hurting
   in-memory hash-table dedup at merge time by ~5–15%. Going to
   64 bytes/record doubles storage. Neither is a great trade.

2. **On-demand recomputation is fast.** cd (mean complement
   distance) for a single 32-byte record is ~100 cycles. For a
   billion-record canonical, that's ~30 seconds on one core, a
   few seconds parallelized. Pre-baking saves seconds, not hours.

If you want pre-computed invariants for repeated analyses, write
them to a **sidecar file** (`solutions.invariants` parallel to
`solutions.bin`), 1:1 indexed by row. Doesn't change
`solutions.bin`'s sha lineage and is opt-in for readers that
need it.

### 11b. "Do-or-lose-forever" decisions

A small number of decisions cannot be undone after the campaign
finishes without a full re-enumeration:

| Decision | Why it's irreversible | Cost to recover |
|---|---|---|
| Constraint set used during the walk | Walk pruning eliminated orderings excluded by the original constraints; you cannot recover them from solutions.bin. | Full re-enumeration with the new constraint set. |
| Per-sub-branch budget | Cells that hit BUDGETED status weren't fully explored. | Asymmetric extension on those cells with higher budget. |
| Whether near-miss orderings (failed C5 by ≤ N swaps) were captured | Failed-C5 orderings reach depth 32, get rejected by C5's final check, and are discarded if not captured. | Full re-enumeration with a "drop C5 final check" mode (~$200-500 at moderate scale). |

Decide these before launch — cost of wrong decisions is full
re-runs, not incremental fixes.

## 12. Reproducibility checklist

For any campaign producing a sha you intend to publish:

1. **Lock the binary.** Tag the commit; build once on a "build
   helper" VM; copy bytewise-identical binary to every campaign
   VM; verify md5 on each.
2. **Record the constraint definitions** from `solve.c` at that
   commit. Future contributors need to know the exact C1–C5
   active when this canonical was produced.
3. **Save the build environment** (gcc version, host CPU `-march`
   flag, OS version). Bytewise reproduction across architectures
   has been validated in this project for ARM Cobalt vs x86; new
   architectures may need re-validation.
4. **Verify the merged sha matches the per-branch shas would
   imply** — i.e., the global `--merge` is deterministic and
   independent of shard arrival order. Tier 9a in the test suite
   checks this.
5. **Two-language constraint verification on the merged output,
   pre-publication.** Run `solve --verify solutions.bin` AND
   `python3 verify.py solutions.bin` before declaring the sha
   canonical. Both must pass. The two checkers share no code —
   `solve --verify` is C in the same binary that produced the
   file (catches bit-flip, disk corruption, merge bugs);
   `verify.py` is an independent Python reimplementation of
   C1–C5 (catches shared-codepath bugs in solve.c that
   `solve --verify` would miss). Skipping either reduces the
   verification to one-language and weakens the chain. Wire
   both into the orchestrator post-merge step so the gate is
   automatic, not relying on operator memory. For tiers in a
   validation chain that produce a *new* sha (asymmetric
   extension, multi-stage chain final phase, etc.) this is the
   only constraint check available — sha-equivalence transitive
   verification doesn't apply when the sha is new.
6. **Archive `solutions.bin` + `solutions.sha256` + all side-
   metadata + all shards + all `dfs_state` files + the locked
   binary** to cold storage (Azure Standard_LRS HDD is fine).
   Cost: ~$0.045/GB-mo. For a 200 GB shard pile + 50 GB output
   = ~$11/mo.
7. **Document the campaign** with a follow-up post-mortem (or
   methodology doc) describing what went wrong, what surprised
   you, and what cost-and-wall actually came in vs estimate.

## 13. Honest uncertainties

This guide reflects the project's empirical experience, but a few
things are still open:

- Per-thread rate at very large budgets (≥100 T per cell on a
  single first-level branch) is extrapolated from the 100T pilot,
  not directly observed.
- Hash-table contention behavior beyond 64 threads is observed but
  not architecturally analyzed; the 50% efficiency drop past 64 may
  be NUMA, may be lock contention, may be both.
- Spot eviction frequency in westus3 is highly variable; budget
  for at least 1–2 evictions per VM per multi-day campaign.
- Storage fragmentation effects across very long campaigns
  (10+ days continuous I/O) haven't been characterized.

If you run a campaign that produces new data on any of these,
contributing a follow-up to this doc is welcome.

### 13a. Common gotchas (tips from observed campaigns)

These are gotchas surfaced during real campaigns — not bugs in
solve.c, just operational patterns worth knowing about:

1. **Auto-merge sanity gate fragility at high thread counts.**
   At depth-3 with `SOLVE_THREADS=128` (especially with the
   recursive DFS path, no `SOLVE_DFS_ITERATIVE=1`), the in-process
   auto-merge can emit "SANITY-WARN" lines and fail to write
   `solutions.sha256` even though the enum completed correctly.
   The shards on disk are intact. **Recovery: run `solve --merge`
   manually in the affected dir.** It's deterministic; produces
   the correct sha. Plan for this when running in `--branch + 128t`
   or recursive-DFS modes.
2. **`solutions.bin` sha changes when per-cell budget changes.**
   Two enumerations at the same depth but different
   `SOLVE_PER_SUB_BRANCH_LIMIT` will produce different shas. This
   is expected — different per-cell budgets find different solutions
   (cells that hit budget at the lower setting find more solutions
   at the higher setting). Don't compare shas across runs unless
   the per-cell budget matches exactly.
3. **`SOLVE_NODE_LIMIT / 3030` auto-compute at depth=3 under-shoots.**
   solve.c's auto-compute of per-sub-branch budget uses divisor
   3030 (depth-2 cell count). At depth=3 with ~2,824 cells per
   first-level branch, this means setting `SOLVE_NODE_LIMIT=10T`
   actually allocates ~9.32 T per branch (7% under intent). Always
   set `SOLVE_PER_SUB_BRANCH_LIMIT` explicitly at depth=3. (See §3
   for the math and recipe table.)
4. **Disk device numbering reshuffles after VM restart.** Every
   spot-eviction recovery may surface the data disk at a different
   `/dev/nvmeNnM` than before. Use `lsblk`/`blkid`/UUID-mount, not
   the device path directly.
5. **Stale binary problem.** A `git pull` on the VM source dir
   does not rebuild the binary. After any solve.c change, the
   binary must be explicitly rebuilt; otherwise the campaign
   continues with the old binary. Always md5-check the binary
   against the locked reference at every campaign-script entry.
6. **2-byte slot encoding.** `solutions.bin` records use 32 bytes,
   one per pair-orient slot. The byte format is
   `(pair_index << 2) | (orient << 1)`; bit 0 is reserved. Don't
   write parsers that assume the byte == hexagram value directly.
7. **`solutions_total` vs `solutions_c3` semantics.** solve.c's
   internal counters: `solutions_total` is depth-32-arrival count
   (= satisfies C1+C2+C4+C5); `solutions_c3` is the C3-passing
   subset (= what's in `solutions.bin`). The diff is the count of
   orderings that satisfy C5 but fail C3. This data is in the
   run log; useful for some Category B questions.
8. **Per-record cd/distance-sum recompute is fast.** ~30 seconds
   on one core for a 1B-record canonical to compute cd values
   from scratch. Don't bother adding pre-computed invariants to
   the record format (the perf tradeoff with cache lines is
   worse than the ~30 sec saving). Sidecar files or on-demand
   recompute are cleaner.
9. **Long-running 128-thread enumerations may crash the parent
   process at the post-enum cleanup boundary.** Symptom: solve
   exits with `Segmentation fault (core dumped)` after the
   enumeration walk has fully completed (all `*** Sub-branch N/N
   BUDGETED ***` messages emitted, all shards written to disk).
   Most commonly observed with `SOLVE_THREADS=128`,
   `SOLVE_DFS_ITERATIVE=1`, depth-3, and elapsed walks of ~75
   minutes or more. Root cause: the 128-thread iterative+v2 path
   accumulates heap-state corruption that surfaces in
   glibc's allocator routines (free / malloc / heap consolidation)
   at the post-enum cleanup boundary. The enumeration output
   (the per-thread shards) is unaffected — those are written
   incrementally via plain `fwrite` and reach disk well before
   the crash.

   **Universal mitigation (do this every time):** the shards on
   disk are the durable artifact. Run `solve --merge` in the
   affected directory **from a fresh shell**. A fresh process
   has a clean heap; reads only the shards; produces a
   deterministic, correct `solutions.bin` and `solutions.sha256`.
   This recovery has been observed to reproduce the canonical
   sha byte-identically across many independent occurrences.

   **What `solve.c` does to reduce frequency:** the `--merge`
   step itself runs in a fork()-isolated child process precisely
   because of this heap-corruption family (added 2026-04-30
   after Test A). A subsequent fix removed the most-frequent
   crash trigger — three pre-fork `free()` calls in the parent
   that ran in the corrupt heap before the fork could isolate.
   With both mitigations in place, this crash is rare; without
   them, it was nearly deterministic at 128t / depth-3 / 75+ min.

   **What is still unfixed:** the underlying heap corruption.
   The two mitigations route around it; they do not eliminate
   it. **History note worth absorbing:** the 2026-04-30
   fork-merge fix (Test A) didn't make the crash go away — it
   *relocated* the crash from the in-process merge step to a
   different allocator touch (the three pre-fork free()s). Once
   the dead-free patch lands, the crash could similarly relocate
   to another allocator touch in the parent process (fopen,
   printf, glibc cleanup at process exit). Each fix has reduced
   crash frequency by addressing the most heavily-used allocator
   path remaining; none has eliminated the corruption itself.
   Future contributors planning a 128-thread campaign should
   expect a non-zero residual crash rate at this boundary
   indefinitely, and should design scripts to **always** run
   `solve --merge` from a fresh process if `solutions.bin` is
   missing or `solutions.sha256` is empty after a normal-looking
   enum completion. A Valgrind/AddressSanitizer-based root-cause
   investigation is on the deferred backlog; until that lands,
   the shard-then-merge-from-fresh-shell pattern is the
   guarantee of correctness, not the absence of crashes.

   **Why this isn't a correctness risk:** the canonical sha
   produced by a fresh-shell `solve --merge` from intact shards
   has been independently verified across multiple campaigns
   (sha-equivalence to Tier 1 reference at 11.2T, two-language
   constraint verification per §12 item 5). A crash at the
   post-enum cleanup boundary cannot corrupt the on-disk shards
   — by the time the cleanup phase runs, the enumeration
   threads have already written their shards via `fwrite` +
   `fclose`, and any pending kernel writes complete independent
   of parent-process state. If `solutions.bin` exists but is
   somehow truncated or unsorted (e.g. a crash mid-merge in a
   pathological recovery), `solve --verify` (auto-detects
   shard vs full-file mode) will catch it before publication.
10. **Spot evictions during merge are recoverable.** Merge isn't
    incrementally checkpointed, but it's deterministic. If
    eviction hits mid-merge: `rm` partial outputs, restart
    `solve --merge`. Same input shards, same output sha.

## 14. Worked example: 56 × 10T at 2 × D64 spot

Concrete recipe for the project's planned 2026-05 campaign:

| Field | Value |
|---|---|
| Budget per first-level branch | 10 T nodes |
| Total nodes (56 branches) | 560 T |
| VMs | 2 × D64als_v7 spot, westus3 |
| Branches per VM | 31 (after balanced split) |
| Per-thread rate (mid estimate) | 15 M nodes/sec/thread |
| Per-VM throughput | ~960 M nodes/sec |
| Aggregate throughput | ~1.92 B nodes/sec |
| Wall (mid) | 560T / 1.92B/sec ≈ 81 hr ≈ 3.4 days |
| Wall (worst, with evictions) | ~5 days |
| Cost (mid) | 2 × 81 hr × $0.50/hr ≈ $81 |
| Cost range | $60–135 |
| Pre-flight validation cost | ~$25 (Tier 9 + Tier 9+ tests) |
| Merge VM | D64 (likely sufficient with ~180 GB RAM); fallback D128 |
| Merge wall | ~2 hr |
| Total time-to-canonical | ~4 days enum + ~6 hr validation + ~2 hr merge ≈ ~5 days |
| Total cost | ~$110 mid, $85–165 range |

That's the template. For larger-scale campaigns (5.6 PT, 56 PT),
multiply budget linearly, scale VM count to keep wall under ~10
days, and re-check merge VM RAM requirement.

## 15. References

- `petersm3/roae`:
  - [`SOLVE.md`](SOLVE.md), [`SOLVE-SUMMARY.md`](SOLVE-SUMMARY.md) — what's been computed and what holds
  - [`SPECIFICATION.md`](SPECIFICATION.md) — formal constraint definitions
  - [`PARTITION_INVARIANCE.md`](PARTITION_INVARIANCE.md) — the theorem this guide's correctness story rests on
  - [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) — `solutions.bin` byte format
  - [`DEVELOPMENT.md`](DEVELOPMENT.md) — `--extended-selftest`, build flags, invariants
  - [`DEPLOYMENT.md`](DEPLOYMENT.md) — Azure VM sizing, region notes
  - [`HISTORY.md`](HISTORY.md) — what's been run, when, how it landed
- `petersm3/x` (private operator log; not public):
  - `roae/CAMPAIGN_2026_05_VALIDATION.md` — the campaign that produced the lessons in this guide
  - `roae/CAMPAIGN_560T_PLANNING_2026_05_02.md` — detailed planning for the campaign this guide's worked example refers to
  - `roae/560t_scripts/` — reference scripts (orchestrator, branch runner, branch lists)
