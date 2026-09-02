# Large-Scale Enumeration Campaign Guide

> **DEPRECATED (2026-06-08): superseded by [CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md).**
>
> This document was the project's original public guide to large-scale
> enumeration patterns. It has been **replaced** by
> [CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md) as the canonical public
> reference, following completion of the 560 T campaign on 2026-06-08 (the
> trigger event named in CAMPAIGN_METHODOLOGY.md's intro). New readers
> should go to CAMPAIGN_METHODOLOGY.md.
>
> **Scope correction (2026-08-08).** This banner previously said "a small amount of
> operational content" was unported and pointed readers at a port-progress checklist. Both were
> wrong. A section-by-section comparison found the two documents are **complementary, not
> duplicative**: CAMPAIGN_METHODOLOGY.md owns *correctness* (what "canonical" means, per-cell
> budget, extension, preservation, sha stability), while the following remain **available only
> here** and have no counterpart there —
>
> * **§2 sizing** — thread caps, VM-count trade-offs, and per-thread-rate
>   planning, a topic CAMPAIGN_METHODOLOGY.md does not cover at all. (This
>   line used to pin the claim to a phrase count, "8× here, 0× there"; the
>   count changed when §2c was rewritten on 2026-09-01, so the brittle half
>   is dropped and the substantive half kept.)
> * **§6 campaign architecture** — per-VM runner and cross-VM orchestrator pseudocode
> * **§9b** — merge sizing and the external-merge path for extreme scale
>   (§9c's tiered-merge recipe was withdrawn 2026-09-01 as unrunnable; the
>   section retains the explanation of why)
> * **§13.0 scale honesty** — the disclosure that solve.c is **not empirically validated**
>   at PT scales, only to the 100T pilot
> * **§13a** — common gotchas observed across real campaigns
>
> So this file is **not** awaiting deletion. It is the operational guide; CAMPAIGN_METHODOLOGY.md
> is the methodology reference. Read that one first for correctness questions, this one for
> planning and running a campaign. **Do not extend this file** — put new material in
> CAMPAIGN_METHODOLOGY.md unless it belongs to one of the topics listed above.

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

For the full `solve.c` command-line reference (every subcommand and
environment variable referenced in this guide), see
[SOLVE_C_CLI.md](SOLVE_C_CLI.md).

## 1. Decide what you actually want

Before sizing anything, answer these questions:

1. **What scale of solution count do you want?**
   The number of unique solutions found grows sub-linearly with
   per-cell budget. Empirical curve from this project's runs:

   | Per-cell budget | Approximate solutions | Notes |
   |---|---|---|
   | 70 M (Tier 1's depth-3 70M) | 759 M unique | The current canonical |
   | 141 M (Tier 5's 2× on branch 22-0) | +50 % on that branch | Proves *at least one* cell hit Tier 1's 70M cap (otherwise no gain would be possible). Per-cell BUDGETED counts weren't recorded for Tier 1 or Tier 5 so the prevalence isn't directly confirmed; the magnitude is suggestive of a widespread effect but not definitive. |
   | 3.5 G (560T campaign) | **10,525,271,997 — measured, not estimated** | The 560T campaign ran; this row read "1.2–1.5 B (estimated)" until 2026-09-01 and was **7.0–8.8× low**. Count and file size are published in [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §560T (336,808,703,936 bytes). |
   | 35 G (5.6 PT plan) | 4–8 B (estimated) | ⚠ Extrapolated from the same curve that produced the withdrawn 1.2–1.5 B estimate above, which the one campaign that tested it beat by 7–9×. Treat as a lower bound of unknown tightness, not a forecast. |
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
   identify which cells are budget-exhausted) need *side-metadata*,
   most of which solve writes during the run without being asked —
   the shards, the `.dfs_state` files and `per_task_stats.csv` are
   unconditional. What you must do is **transfer and archive them**;
   see §11 for the list and §6c Phase 2 for the transfer.

## 2. Sizing: choose VM size, count, and budget

### 2a. Architectural cap: ~64 useful threads per single-branch run

[`solve --branch <p1> <o1>`](SOLVE_C_CLI.md#--branch) parallelizes across ~2,824 depth-3
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

⚠ **Provenance withdrawal (2026-09-01).** This section used to publish a
three-row table of per-thread rates — ~1.4 M, ~9 M and ~21 M nodes/sec/thread,
keyed to full-enum, small-budget `--branch` and large-budget `--branch`
respectively — and told you to "pick ~15 M for a midpoint". **Those three
numbers carry no provenance anywhere in this project.** A corpus-wide search
for the string `nodes/sec/thread` returns exactly two files: this document, and
one hardcoded `1.0e7` planning constant in `solve.c` (locate by the comment
`est wall = node_limit / (threads * 1.0e7 nodes/sec/thread)`) that is not a
measurement of any of the three workload classes. No run id, commit, command,
host SKU, thread count or timed interval was ever recorded for them, while the
same paragraph warned that choosing the wrong row "gives wrong answers by 10×".
Under the project's standing rule that a published figure ships with the
command that reproduces it, the table is withdrawn rather than restated.

**What is actually measured.** One absolute per-thread rate in this corpus
carries full provenance — [HISTORY.md](HISTORY.md), the 2026-04-20 entry
"Same-SKU physical-host placement creates 2x rate variance". Single-branch
enumeration on **D32als_v7 on-demand** measured **~10 M nodes/sec/thread** on
one physical host and **~20–22 M nodes/sec/thread** on two others of the
identical SKU, region and vCPU count. That is the honest planning input, and
its headline is not a midpoint but a **2× spread across hosts you cannot
distinguish with `lscpu`**.

**So plan like this, not from a table:**

1. Use **10–22 M nodes/sec/thread** as the band for `--branch` work, from the
   measurement above. Quote a range; never a point.
2. **Measure your own host 5–10 minutes into the run** and re-derive the
   estimate from it. The HISTORY entry's own lesson is kill-and-retry when the
   early rate is obviously off — a 2× host penalty is a 2× cost overrun, and it
   is invisible before launch.
3. Treat full-enum (`solve 0 N`, no `--branch`) as **slower per thread** than
   `--branch` at the same budget, because it is overhead-dominated — but this
   guide has no measured figure for it, so do not put a number on it without
   benchmarking your own build.

## 3. Budget semantics — what "10T per branch" actually means

`SOLVE_NODE_LIMIT` is a **cap**, not a target. Total nodes walked
is always ≤ the cap, typically less. Two structural reasons:

### 3a. Per-sub-branch budget is what's binding

For `--branch X Y` mode, solve doesn't enforce the global node
limit directly during enumeration. Instead it computes (or accepts
override of) a **per-sub-branch budget**, and stops each cell when
it hits that. The global cap only acts as a coarse safety ceiling.

⚠ **[CORRECTED 2026-09-01 — this subsection published a wrong divisor story
and, worse, a `SOLVE_PER_SUB_BRANCH_LIMIT` table that does not reproduce any
published canonical. Both are retracted.]** It read: *"solve.c divides by 3030
(the depth-2 cell count). At depth=3 the actual cell count is ~2,824 … **The
auto-compute under-shoots at depth=3**"*, and then prescribed
`SOLVE_PER_SUB_BRANCH_LIMIT=3,541,500,000` for a 10 T-per-branch (= 560 T)
campaign. Neither half survives contact with the source.

**The `/3030` divisor is not the enforced budget.** `node_limit / 3030` appears
twice in `solve.c` and both sites assign only `current_per_branch_budget` —
the **resume-skip threshold**, used to decide whether a checkpointed cell's
stored budget is big enough to skip. The code comment at the second site says so
in as many words: *"Approximation error is irrelevant: the budget-aware resume
just needs a rough threshold, not an exact match."* The budget the DFS actually
enforces is `per_branch_node_limit`, assigned `node_limit / divisor` where
`divisor = total_branches` — the **real depth-3 partition size, 158,364** — and
overwritten outright by `SOLVE_PER_SUB_BRANCH_LIMIT` when that is set. So there
was never a wrong divisor to override.

**And the prescribed number produces a different sha.** The published 560 T
recipe uses `SOLVE_PER_SUB_BRANCH_LIMIT=3536157207`, which is exactly
`560 × 10¹² ÷ 158,364`; the retracted table said 3,541,500,000, larger by
5,342,793. A campaign run from the old table walks a different frontier and
lands on a different `solutions.bin` — the one failure mode a canonical recipe
exists to prevent.

**Do this instead.** Take `SOLVE_PER_SUB_BRANCH_LIMIT` from the recipe table in
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Reproducibility parameters", and
copy it **verbatim**. That document carries a standing instruction not to
re-derive the value from a `floor(NL / 158,364)` formula, citing the incident
that motivated the rule — and the table retracted above was a re-derivation
from a *worse* formula. Note also the extension warning there: copy verbatim to
**re-derive** an existing canonical, never to **extend** one, because an
extension that reuses the parent's PSB reproduces the parent byte-for-byte no
matter what `SOLVE_NODE_LIMIT` it is given.

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
- **For status reporting:** report the per-cell BUDGETED / EXHAUSTED
  breakdown, not the global cap. Note the granularity before you
  quote it: `per_task_stats.csv` has one row per **depth-5 task**
  (`task_idx,p4,o4,p5,o5,nodes,…`), not one row per depth-3 cell, so
  a "cells budgeted" figure taken from it is a task count unless you
  aggregate. The per-cell final status is in the shard checkpoint
  state, and the campaign-level rollup is
  `shards_by_final_status` in `solutions.provenance.json`.

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

**Host stability pre-flight (paired performance benches only).** For LTO / AVX-512 / PGO / huge-pages / other A-vs-B speedup measurements on D128als_v7 — *not* for canonical sha enumeration — run `./solve --cpu-freq [THRESHOLD_MHZ]` BEFORE the bench. (Earlier revisions of this paragraph told you to run an orchestrator-side `scripts/d128_preflight_throttle_probe.sh`. **That script does not exist in this repository, and never did** — the check has always been the `--cpu-freq` subcommand, which is what the project's own campaign launcher calls. Corrected 2026-08-09.) Standard on-demand D128 hosts in westus3 have been observed to hand back the same SKU at radically different effective clocks (3700 MHz healthy vs 602 MHz thermal-throttled, observed 2026-05-16). A throttled host produces unusable paired ratios. ⚠ **[CORRECTED 2026-09-01 — the sentence that stood here described a capability the shipped probe does not have.]** It read: *"the probe provisions, runs a 60-second 128-thread `stress-ng matrixprod` burn, samples `/proc/cpuinfo cpu MHz` mid-load, and reprovisions up to 3 times if the host fails the threshold"*, and then equated that with `--cpu-freq`. The 2026-08-09 correction in the parentheses above retired the *name* of a deleted probe script and left the deleted script's *capability description* attached to the surviving subcommand. **What `--cpu-freq` actually does:** it opens `/proc/cpuinfo` once, parses the `cpu MHz` lines, and prints one line — `[--cpu-freq] cores=… min=… avg=… max=… threshold=… below=…` (default threshold 2000 MHz, overridable as `--cpu-freq 2200`). It generates no load, starts no child process, and provisions nothing. **The operational consequence is the point:** this is an *idle* clock reading, so a host that idles at 3.7 GHz passes it and can still collapse to 602 MHz under 128 threads — which is exactly the 2026-05-16 failure this paragraph cites. Until a loaded sample lands in `--cpu-freq`, treat it as a cheap sanity check that catches an already-throttled host, **not** as a load-throttling detector: for a paired bench, also compare the two arms' own observed node rates, where a throttled arm shows up directly. (Canonical enumeration runs are sha-deterministic regardless of host clock, so they don't need this — only paired wall-clock comparisons do.)

**For larger-scale campaigns (5.6 PT or 56 PT)**, also run
production-scale spot-checks — the project calls these "Tier 9+":

- **Pilot one branch at the chosen per-branch budget** on the
  intended VM size. Validates real wall time, real shard size,
  real disk-write throughput. Cost: 1/N of the campaign cost
  where N is the branch count (e.g., 1/56 of the total).
- **Merge memory-pressure test** — run [`--merge`](SOLVE_C_CLI.md#--merge) on a representative
  shard set, sample peak RSS. Tells you whether your intended
  merge VM has enough RAM. (For ≥5.6 PT campaigns, expect peak
  RSS in the 200–900 GB range; **D64als_v7 has 128 GB**, which will
  not suffice — size from the SKU→RAM table in
  [DEPLOYMENT.md](DEPLOYMENT.md#sku-to-ram-reference).)
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
    SOLVE_ALLOW_SUB_CANONICAL=1,   # REQUIRED — see below
  }
  RUN solve --branch 1 0 0 8  IN /tmp/smoke
  ASSERT exit_code == 0
  ASSERT count(sub_*.bin) >= 1
  ASSERT solutions_1_0.sha256 is non-empty
```

⚠ **`SOLVE_ALLOW_SUB_CANONICAL=1` was added to this block on 2026-09-01, and
without it the recipe fails on every healthy VM.** The sub-canonical hard gate
landed 2026-05-25 and refuses to start a canonical enum at
`SOLVE_NODE_LIMIT < 1 T` unless the operator sets either
`SOLVE_PER_SUB_BRANCH_LIMIT` explicitly or `SOLVE_ALLOW_SUB_CANONICAL=1`
([CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Sub-canonical hard-gate"). This
block set neither, so it exited **25** and wrote no shards — failing its own
first two assertions — and it had done so since the gate landed. The smoke test
predates the gate and was never updated. `SOLVE_ALLOW_SUB_CANONICAL=1` is the
honest override here: it acknowledges the output sha is code-specific, which is
irrelevant for a plumbing test whose sha nobody reads.

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
            SOLVE_DEPTH_PROFILE          = 1,    # per-DEPTH node histogram
                                                 # to stderr. NOT the CSV —
                                                 # per_task_stats.csv is
                                                 # written unconditionally.
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
    ELSE IF rc != 0 AND log_contains("invalid (pruned at depth 1)"):
      # Structurally dead branch — solve exits 1 and will do so forever.
      # Mark it satisfied or the completion test below never fires.
      # See §7: with the shipped prune set, 3 of the 31 non-start pair
      # indices are dead in BOTH orientations.
      atomic_touch(DONE_MARKER)
      log "DEAD $p1/$o1 (pruned at depth 1); counted as complete"
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

  # ---- Phase 2: collect shards AND sidecars centrally ----
  # Merge-host RAM: size from the SKU->RAM table in DEPLOYMENT.md
  # (Dals_v7 is 2 GB per vCPU, so D64als_v7 = 128 GB and
  # D128als_v7 = 256 GB) against the peak-RSS estimate in §9a.
  # This comment previously read "D64 RAM (256 GB) ... D128
  # (512 GB)" -- both doubled; corrected 2026-09-01.

  log "PAUSE: operator must rsync shards from each VM to $MERGE_DIR"
  log "  rsync -av <VM-A>:$ROOT/enum/sub_*.bin $MERGE_DIR/"
  log "  rsync -av <VM-B>:$ROOT/enum/sub_*.bin $MERGE_DIR/"
  # Sidecars. Enumeration writes all of these and the merge does not
  # need them -- but a FUTURE EXTENSION cannot start without them, and
  # they are gone once the enum VMs are torn down. Transfer them in the
  # same pass. (Before 2026-09-01 this list held only the shards and
  # the per-task CSV, while §11 of this same document listed
  # sub_*.dfs_state as "Required for ANY future extension".)
  log "  rsync -av <VM-*>:$ROOT/enum/sub_*.dfs_state      $ROOT/enum/"
  log "  rsync -av <VM-*>:$ROOT/enum/checkpoint_t*.txt    $ROOT/enum/"
  log "  rsync -av <VM-*>:$ROOT/enum/shard_manifest.txt   $ROOT/enum/<vm>/"
  log "  rsync -av <VM-*>:$ROOT/enum/*.provenance.json    $ROOT/enum/<vm>/"
  log "  rsync -av <VM-*>:$ROOT/enum/per_task_stats*.csv  $ROOT/enum/<vm>/"
  # NB per_task_stats.csv is written under a FIXED name in the run's
  # CWD -- solve does not stamp the branch into it. If your runner
  # shares one WORKDIR across branches, each branch overwrites the
  # last. Give each branch its own directory, or rename on completion,
  # before relying on a per_task_stats_*.csv glob.
  log "  Then touch $ROOT/shards_collected and re-run"

  IF NOT exists("$ROOT/shards_collected"):
    EXIT 0      # orchestrator will be re-invoked after operator sync

  # ---- Phase 3: global merge ----
  n_shards = count(files matching "$MERGE_DIR/sub_*.bin")
  log "$n_shards shards in $MERGE_DIR; running --merge"

  # Pre-merge reconciliation. Exact, not a tolerance -- see §12 item 5a.
  # Each VM emitted its own shard_manifest.txt over its own shards, so
  # reconcile once per VM. --verify-shard-manifest re-hashes every shard
  # NAMED IN THE MANIFEST relative to the CURRENT directory, so run it
  # with CWD = $MERGE_DIR and hand it each VM's manifest in turn. Shards
  # contributed by the other VMs show up as EXTRA, which is non-fatal;
  # MISSING / SHRUNK / DIVERGED are fatal and exit 22.
  FOR each vm in VM_NAMES:
    EXEC solve --verify-shard-manifest "$ROOT/enum/${vm}/shard_manifest.txt"
         INTO $MERGE_DIR
    ASSERT exit code == 0

  # The restart point Phase 5 advertises. Without this guard, re-invoking
  # the orchestrator re-runs the whole merge -- 18 h 42 m at 560T -- and
  # reopens a completed artifact for writing. Added 2026-09-01; the
  # "existing solutions.sha256 means Phase 3 is skipped" claim below had
  # been made since this pseudocode was first published, with nothing
  # implementing it.
  IF exists("$MERGE_DIR/solutions.sha256"):
    log "Phase 3 already complete; skipping merge"
  ELSE:
    EXEC solve --merge
         INTO $MERGE_DIR     # --merge takes NO path argument; it reads
                             # and writes the CURRENT DIRECTORY. Any
                             # trailing argument is silently discarded.
         REDIRECT >> "$ROOT/logs/global_merge.log"

  ASSERT exit code == 0
  ASSERT exists("$MERGE_DIR/solutions.sha256")

  sha  = first_field(read("$MERGE_DIR/solutions.sha256"))
  size = stat_size("$MERGE_DIR/solutions.bin")
  log "global merge sha=$sha size=$size bytes"

  # ---- Phase 4: post-merge metadata extraction ----
  META_DIR = "$MERGE_DIR/metadata"
  mkdir(META_DIR)

  # 4a. Per-prefix yield report.
  # `solve --branch-yield-report` does NOT exist and never did -- the C
  # binary rejects it as an unknown option. Two real forms, pick one:
  EXEC solve.py --branch-yield-report "$MERGE_DIR/solutions.bin" \
       > "$META_DIR/branch_yield_report.txt"
  #   ... or, from the enum LOG rather than the merged output:
  #   zcat $ROOT/logs/branch_*.log.gz | solve --yield-report \
  #        > "$META_DIR/branch_yield_report.txt"

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
- **Side-metadata is captured in the same pass as the shards — but
  not atomically, and not for free.** This bullet used to claim "all
  side-metadata captured atomically with the canonical sha." It is a
  sequence of independent `rsync` invocations against live VMs; nothing
  makes it atomic, and until 2026-09-01 the transfer list omitted the
  `.dfs_state` files, the checkpoints, the shard manifests and the
  provenance JSON that §11 calls required. Treat Phase 2 as the step
  most likely to lose something irrecoverable, and verify it (§12 item
  5a) rather than trusting it. `solutions.bin` and `metadata.json`
  should be archived together — they reference each other.
- **Re-runnable — only because Phase 3 now carries the guard.** If the
  orchestrator dies between "merge done" and "metadata.json written,"
  re-invoking it skips the merge on the existing `solutions.sha256` and
  picks up at Phase 4. That guard was added to the Phase 3 pseudocode on
  2026-09-01; this bullet asserted the behaviour before anything
  implemented it, and Phase 3 was an unconditional `solve --merge`. If
  you build from an older copy of this pattern, add the guard — the
  560T merge took 18 h 42 m, and re-running it also reopens a finished
  artifact for writing.

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

- `petersm3/roae-private:campaigns/560t_scripts/560t_branch_runner.sh`
- `petersm3/roae-private:campaigns/560t_scripts/560t_orchestrator.sh`
- `petersm3/roae-private:campaigns/560t_scripts/branches_A.txt`
- `petersm3/roae-private:campaigns/560t_scripts/branches_B.txt`

`petersm3/roae-private` is a private repository — these scripts are not publicly
accessible; the listing records that a reference implementation exists and can be
disclosed to an auditor. The pattern itself is fully specified by the public text
of this section, which is what to build from; adapt VM names, paths, and budgets
to your campaign.

## 7. Branch distribution — balancing wall time across VMs

Tier 1's yield distribution shows orientation-0 branches have
roughly 5–10× more solutions than orientation-1 branches. If you
naively split 56 branches by orientation (one VM gets all o1=0,
other gets all o1=1), wall time is unbalanced.

⚠ **[CORRECTED 2026-09-01 — the split published here listed 62 branches, six of
which cannot run, and a runner fed this list never finishes.]** It read:
*"VM-A: pair indices 1–15 + orientation, plus (16, 0) → 31 branches / VM-B:
(16, 1) + pair indices 17–31 + orientation → 31 branches"*. That enumerates
pairs 1–31 in both orientations. But 62 ≠ 56, and this document already says 56
two paragraphs up — `solve.c` says it too, in the comment *"Enumerate ALL valid
work units across all 56 first-level branches."*

**Where the six go (measured, not reasoned).** Probing all 64 `(pair, orient)`
combinations with a 1-node budget —

```
for p in $(seq 0 31); do for o in 0 1; do
  SOLVE_PER_SUB_BRANCH_LIMIT=1 SOLVE_THREADS=2 ./solve --branch $p $o 0 2
  echo "$p $o rc=$?"
done; done
```

— pair index **0** is rejected outright (`Invalid pair index 0`; it is the fixed
start pair), and of the remaining 62 exactly **six** print
`Branch (pair N orient O) is invalid (pruned at depth 1)` and exit 1:
**(4,0) (4,1) (6,0) (6,1) (21,0) (21,1)**. 62 − 6 = **56**, which is the number
this guide and the binary both already used. Pair indices **4, 6 and 21 are dead
in both orientations.**

**Why it hangs rather than merely wasting a slot.** The runner in §6b touches a
done marker only on a clean exit, and signals `${role}_complete` only when
`n_done == n_total`. A dead branch exits 1 forever, so it never gets a marker,
so the count never reaches the total, so the VM never signals — and the
orchestrator's Phase 1 blocks on a file that cannot be created. The old split
gave VM-A four dead entries and VM-B two, so **both** VMs hung.

**Corrected split.** The 28 live pair indices are 1–31 **minus 4, 6 and 21**;
each runs in both orientations, giving 56 branches. Split them 14 pairs to a VM
so each VM gets both orientations of every pair it owns:

- **VM-A:** pairs 1, 2, 3, 5, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 × orientations 0 and 1 → **28 branches**
- **VM-B:** pairs 17, 18, 19, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31 × orientations 0 and 1 → **28 branches**

This balances pair-index range and orientation mix, as the old split intended.
Pre-partition deterministically (no race) — both VMs read their list from a
shared file, and **check that the two files hold 56 lines between them** before
launch. Do not hand-maintain the exclusions: regenerate the list with the probe
above, which is authoritative against whatever prune set your binary ships,
and make the runner treat `invalid (pruned at depth 1)` as a satisfied entry
(§6b) so a prune-set change cannot re-introduce the hang.

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

⚠ **[RAM figures corrected 2026-09-01.** Every `Dals_v7` size in this table was
doubled: it recommended "D32als_v7 (128 GB)", "D64 (256 GB)" and "D64als_v7
(256 GB)". The `l` in `Dals_v7` is the **low-memory** variant at **2 GB per
vCPU** — D32als_v7 is 64 GB and D64als_v7 is 128 GB. This project learned that
at cost: [HISTORY.md](HISTORY.md)'s 100T-pilot entry records having to move
"from D64als_v7 (128 GB RAM, 'l' = low memory) to **D64as_v7 (256 GB RAM)** …
We had assumed D64als_v7 was 256 GB." The authoritative SKU→RAM figures are in
[DEPLOYMENT.md](DEPLOYMENT.md#sku-to-ram-reference); take them from there, not from
prose. **The correction moves the in-memory/disk-based boundary down by a full
SKU step**, which is the whole point of the table.]

| Solution count | Estimated peak RSS | Recommended merge VM | Strategy |
|---|---|---|---|
| ~750 M (Tier 1) | ~90 GB | D64als_v7 (128 GB) — D32als_v7's 64 GB does **not** fit | in-memory |
| ~10.5 B (560T, measured) | see note below | — | **external merge; this is what the campaign actually did** |
| ~4 B (5.6 PT plan) | ~480 GB | no `Dals_v7` size reaches this; memory-optimized or external | in-memory is tight at best |
| ~8 B | ~960 GB | above any SKU this project has provisioned | **switch to disk-based** |
| ~10 B (56 PT plan) | ~1.2 TB | above any SKU this project has provisioned | **disk-based required** |

**The 560T row is the only one that is not an extrapolation, and it did not use
an in-memory merge at all.** 10.525 B unique records were merged from 43.88 B
pre-merge shard records on a **D16als_v7 (32 GB)** by external chunked-sort on
Premium SSD scratch, 18 h 42 m wall ([CANONICAL_HASHES.md](CANONICAL_HASHES.md)
§560T campaign details). ⚠ **[LABEL CORRECTED 2026-09-02 — this figure was published
here, and at two more sites in this file, as *raw* records. It is not a raw
oriented-leaf count: `solve.c` deduplicates on pair identity with the orient bit
masked and clears the table after each sub-branch, so 43,876,464,466 counts
**per-sub-branch canonical keys** and is a LOWER BOUND on raw leaves visited; the
43.88 B / 10.525 B quotient is cross-sub-branch rediscovery, not an
orientation-dedup ratio. Established by [CORRECTIONS.md](CORRECTIONS.md)
2026-08-28, which named three sites; `CANONICAL_HASHES.md` and `HISTORY.md` were
marked, this file was not reached by that sweep or by the follow-up that closed
those two.]**

At 32 bytes/record an in-memory hash table over 10.5 B records is far
past any of these SKUs, and the campaign never attempted it. Read that as the
practical lesson: past ~1 B records, plan the external path (§9b) and size the
**scratch disk**, not the RAM.

The `E`-series rows that stood in this table (E64ads_v5 at 512 GB, E96ads_v5 at
672 GB) have been removed rather than corrected: those RAM figures appeared
nowhere in this project's records except this table, and no `E`-series VM has
ever been provisioned here, so the project has nothing to attest them with. If
you plan on memory-optimized hardware, size it from your provider's current
spec sheet.

**Threshold:** the measured 560T campaign chose external at ~10.5 B records on
a 32 GB VM, and this guide has no measurement of where in-memory actually stops
being the better choice. The old text put the break at "**5–6 B solutions** …
since the largest practical memory-optimized spot VM is ~672 GB RAM" — an
inference from the unattested `E`-series figures removed above, not an
observation. Use the peak-RSS estimate against the RAM you can actually get,
and run the merge-memory test below.

For >2 B solutions, **always run a merge-memory test on a
representative shard set first** before committing to a merge VM
size. Cheap insurance against running out of RAM at the end of a
multi-day campaign.

### 9b. Disk-based external merge — when and how

⚠ **[CORRECTED 2026-09-01 — this section's premise and its Option 1 were both
backwards. The corrected version is much shorter, because the capability the
section was written to work around already ships.]**

**`solve --merge` already does external sort + dedup.** The old text opened
*"The project's `solve.c` does not currently implement true external sort +
dedup"*. It does, and has since well before this document was written: `--merge`
runs in memory when the set fits and **falls back to external sort otherwise**,
writing `temp_sorted_*.bin` chunks to `SOLVE_TEMP_DIR` and merging them. The
behaviour is documented in [SOLVE_C_CLI.md](SOLVE_C_CLI.md) and controlled by
three environment variables:

| Variable | Default | What it does |
|---|---|---|
| `SOLVE_MERGE_MODE` | `auto` | `external` forces the chunked path; `memory` forces in-memory and fails if it does not fit |
| `SOLVE_TEMP_DIR` | CWD | Where the `temp_sorted_*.bin` chunks are written; needs ~1.5× the output size |
| `SOLVE_MERGE_CHUNK_GB` | 4 | Per-chunk size; raise it (16, 32) if you hit the sorted-chunk ceiling or `ulimit -n` |

**And the project has run it at the largest scale it has ever reached.** The
560T merge was "external chunked-sort on Premium scratch, 18 h 42 m" on a
D16als_v7 — 43.88 B pre-merge shard records (per-sub-branch canonical keys, not
raw leaves — see the correction in §9a above) down to 10.525 B unique.
So the disk-based path
is not a follow-on project to scope; it is the path the deepest canonical took.
For anything past ~1 B records, set `SOLVE_MERGE_MODE=external`, point
`SOLVE_TEMP_DIR` at fast scratch sized to ~1.5× the output, and size the
**disk**, not the RAM.

**Option 1: `--merge-layers` — but it is not what this guide claimed**

⚠ The old text said `--merge-layers` *"partitions shards into layers and merges
each layer separately, then merges the per-layer outputs"*, with "RAM peak
bounded by the largest single layer". **It does the opposite of the part that
mattered.** Per the implementation comment in `solve.c` (locate by
`--merge-layers` in the argv dispatch): layers are **pre-existing sibling
subdirectories** under a root, named so they sort in intended order. For each
sub-branch parameter tuple, the **last** layer containing a shard **wins**; the
winning shards are symlinked into `<root>/_merged_/`, and then **the standard
merge runs over that single directory**.

So `--merge-layers` is **shard selection, not hierarchical merging**. It bounds
nothing: peak cost is one ordinary merge over the whole winning set — the entire
campaign, not one layer. What it is genuinely for is **non-destructive
extension**: run a deeper budget on a subset of sub-branches into a new layer
directory, and the newer shards supersede the older ones per tuple while the
prior layer stays intact, so rolling back is `rm -rf <new_layer>`. That is a
real and useful property. It is just not a RAM-bounding one.

The "~10 layers of ~1 B solutions each, ~120 GB RAM per layer, fits on D32"
recipe that stood here is withdrawn: it followed from the inverted description,
and D32als_v7 has 64 GB in any case.

**Option 2: External sort + linear-scan dedup — this is what `--merge` does**

Standard external-merge-sort applied to the 32-byte solution
records. Two phases:
1. Sort the concatenated shard byte-stream using disk-based
   K-way merge sort. Peak RAM bounded by chunk size
   (`SOLVE_MERGE_CHUNK_GB`, default 4 GB). Disk I/O ~2× the input size.
2. Linear scan of sorted output, emitting only the first occurrence
   of each record. Peak RAM is O(1) (just the last record seen).

Wall scales as O(N log N) disk-bandwidth-limited.

⚠ This block used to end *"This is **NOT in `solve.c` today**. Adding it is a
follow-on project"* — **false, and it is the same error as the section preamble
above.** This is the shipped `SOLVE_MERGE_MODE=external` path, and it is what
produced the 560T canonical. There is nothing to build. The old text also
projected "~6 hours per TB" on a Standard SSD at ~500 MB/sec; the measured
560T merge ran 18 h 42 m over 43.88 B pre-merge shard records (per-sub-branch
canonical keys, not raw leaves — see the correction in §9a above,
~1.4 TB) on **Premium** SSD
scratch. Standard SSD is the wrong medium for this — its throughput collapses
under sustained sequential load — so budget Premium scratch and measure your
own, rather than reading a rate off this paragraph.

**Option 3: Bloom-filter-assisted dedup — restated 2026-09-01, and read the
caveat before building it**

⚠ The recipe printed here could not work. It read: *"First pass: build a Bloom
filter (~1 bit per record) of all shards. Second pass: emit records whose Bloom
filter says 'possibly first occurrence'."* After a first pass that inserts
**every** record, every second-pass probe returns positive — no record is ever
identified as a first occurrence, and the procedure emits nothing. Its sizing
was wrong too: at ~1 bit per record the best achievable false-positive rate is
`1 − e⁻¹ = 0.632`, so the "small per-record exact dedup hash table" for
collisions would hold ~63% of the corpus, and the claimed "~10–50 GB regardless
of solution count" does not follow from it.

The correct shape is **one pass, insert on first sight**: probe the filter; if
absent, the record is certainly new — emit it and insert it; if present, it is
*probably* a duplicate. And size the filter to the false-positive rate you
want. At 10.5 B records (the 560T scale), with the optimal hash count for each
bit budget:

| Bits/record | Hashes | False-positive rate | Filter size | Records falsely called duplicate |
|---:|---:|---:|---:|---:|
| 1 | 1 | 0.632 | 1.2 GiB | ~6.7 B |
| 8 | 6 | 0.0216 | 9.8 GiB | ~227 M |
| 10 | 7 | 0.0082 | 12.3 GiB | ~86 M |
| 16 | 11 | 0.00046 | 19.6 GiB | ~4.8 M |
| 24 | 17 | 0.0000098 | 29.4 GiB | ~104 K |

🔴 **The last column is why this is not a canonical path.** A Bloom false
positive on this scheme does not cost a wasted lookup — it **silently drops a
unique record**, because the record is never emitted and nothing downstream
knows it existed. No bit budget makes that column zero. So a Bloom-deduped
`solutions.bin` is a **lower bound with an unknown deficit**, it will not match
any published sha, and it fails the completeness standard in §10 and §12. It is
usable for a cheap approximate count on a research run, and for nothing that
gets published. If you need exact dedup at a size RAM cannot hold, use the
shipped external merge (Option 2) — which is exact, and already ran at 10.5 B.

This is not in `solve.c`, and given the above there is no reason to add it.

### 9c. Tiered merge — WITHDRAWN 2026-09-01, the recipe cannot work

⚠ A four-step "hybrid" recipe stood here: run the 56 branches, group them into
four merge tiers of 14, `solve --merge` each tier separately into a tier-level
`solutions.bin`, then `solve --merge-layers` to combine the four tier outputs.
**It is unrunnable, and it inherits the inverted `--merge-layers` description
corrected in §9b.**

`--merge-layers` does not consume merged outputs. It selects **shards** — for
each sub-branch tuple it takes the shard from the last layer that has one, and
merges those. It never looks at a tier's `solutions.bin`. So step 4 has two
outcomes and both are failures: delete the raw shards after step 3 to reclaim
the disk the recipe was meant to save, and step 4 has no inputs at all; keep
the shards, and step 4 ignores the four tier merges entirely and re-merges every
original shard — the single global merge the recipe was trying to avoid, plus
the cost of four discarded tier merges.

**Use the external merge instead (§9b).** `SOLVE_MERGE_MODE=external` bounds
peak RAM by `SOLVE_MERGE_CHUNK_GB`, not by the solution count, needs no new
code, and is the path the 560T canonical actually took on a 32 GB VM.

### 9d. Decision recipe

⚠ **[REWRITTEN 2026-09-01.** The ladder here escalated through `Dals_v7` and
`E`-series sizes at doubled or unattested RAM figures, routed large campaigns to
the withdrawn §9c hybrid, and closed by calling true external sort "a follow-on
project worth scoping" — when it ships, and produced the 560T canonical. The
replacement is shorter because the decision is simpler than the old ladder made
it look.]

Given an estimated solution count S:

- **S small enough that `S × 32 bytes` fits comfortably in your merge VM's RAM**
  → leave `SOLVE_MERGE_MODE` at `auto` and let `--merge` run in memory. As a
  reference point, the ~750 M-record Tier 1 merge peaked near 90 GB and needs a
  D64als_v7 (128 GB); D32als_v7's 64 GB does not fit it. That 90 GB is an
  estimate carried by this guide, not a recorded measurement — verify it with
  the merge-memory test below before you size on it.
- **Anything larger** → `SOLVE_MERGE_MODE=external`, with `SOLVE_TEMP_DIR` on
  **Premium** scratch sized to ~1.5× the expected output. Peak RAM is then set
  by `SOLVE_MERGE_CHUNK_GB`, not by S, so the merge VM can stay small: the 560T
  merge did 10.525 B records on a **D16als_v7 (32 GB)**.
- **There is no S at which you need code that does not exist.** External merge
  is not RAM-bounded, so the ceiling is scratch disk and wall time, not SKU.

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

⚠ **[CORRECTED 2026-09-01 — the opening sentence and one of the four bullets
were both refuted by [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md). This file was
missed by the 2026-08-28 completeness sweep that corrected the same claim
there.]** It read *"`solutions.bin` contains all the orderings"*, followed by a
bullet promising you could *"test orientation symmetry empirically"* from it.

**What `solutions.bin` actually holds**, per SOLUTIONS_FORMAT.md at the same
commit, on two independent grounds:

1. **It is budgeted, not complete.** It holds the orderings the producing run
   found *within its node budget* — "an exactly-reproducible *slice*", whose
   record count is "a **lower bound**, never the cardinality of the C1-C5
   space." Every canonical this project publishes is in that state.
2. **Orientation is the dimension dedup removes.** Records are deduplicated by
   **canonical pair ordering with the orientation bit masked out**, and
   "**exactly one record per canonical class is retained**" — the
   lexicographically smallest orient variant.

So, from `solutions.bin` alone you can:

- Apply a new rule that further filters the records present
- Compute per-prefix yield, position frequencies, joint statistics —
  as measured **on this slice**, not on the C1-C5 space
- Cross-check with SAT solver output
- **Not** test orientation symmetry. The orientation bit is masked before
  dedup, so the file retains one variant per class by construction and cannot
  witness whether the others existed. SOLUTIONS_FORMAT.md notes the other
  variants are cheaply *recoverable* by testing orientation combinations
  against C2/C5 — recomputation from the canonical ordering, which is a
  different and weaker thing than an empirical test of the symmetry, since
  every variant it yields is one you derived rather than one the enumeration
  found.

What `solutions.bin` does NOT contain — capture these explicitly:

| Side-metadata | How | Why you might need it |
|---|---|---|
| `per_task_stats.csv` (one row per **depth-5 task**: `task_idx,p4,o4,p5,o5,nodes,solutions_added,wall_time_ms,worker_id,completed,max_depth,c3_leaves` + 33 per-depth node bins) | **Written unconditionally** by the parallel sub-branch path — no env var needed. Fixed filename in the run's CWD, so give each branch its own directory or it is overwritten. | Worker load-balance and per-task budget analysis. ⚠ This row previously read "per-cell yield + status + nodes-walked + wall … Set `SOLVE_DEPTH_PROFILE=1` during enum" — wrong on both halves. The granularity is per depth-5 task, not per depth-3 cell, and `SOLVE_DEPTH_PROFILE=1` gates a *different* artifact: a per-depth node histogram printed to **stderr** (`DEPTH_PROFILE depth=<d> nodes=<n>` lines). To identify which **cells** are budget-exhausted, use the shard checkpoint state and `shards_by_final_status` in `solutions.provenance.json`. |
| `checkpoint.txt` | Auto-produced by solve | Records the per-sub-branch budget that was reached. Needed for resume + extension. |
| `branch_yield_report.txt` | `solve.py --branch-yield-report <solutions.bin>` post-merge, **or** the C form `zcat <enum log>.gz \| solve --yield-report` which reads an enumeration **log** on stdin. ⚠ `solve --branch-yield-report` is not a subcommand and never was — the C binary rejects it as an unknown option. [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) documents the C form correctly; this file was the outlier. | Pre-computed per-prefix counts at depths 1, 2, 3 |
| `constraint_definitions.json` | Manual extract from solve.c at locked commit | Future C6 / new-rule work needs to reference the EXACT C1-C5 used |
| All `sub_*.bin` shards + `sub_*.dfs_state` files | Auto during enum | Required for ANY future extension (deeper budget on one or more branches) |
| `metadata.json` (campaign metadata) | Orchestrator writes at end | Binary md5/commit, VM list, runtime, per-VM contribution, eviction events |

"Which cells were budget-exhausted?" is the most-asked future question, and
the answer lives in the `.dfs_state` files and the provenance JSON — **not** in
`SOLVE_DEPTH_PROFILE`, which this paragraph used to warn you against skipping.
Nothing here is opt-in; solve writes it all whether you ask or not. The way you
lose it is by **not transferring it off the enum VMs before teardown** (§6c
Phase 2), and that is unrecoverable in a way a missing env var never was.

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

   **Underlying gap that the verifiers DO NOT close:** they
   validate per-record correctness, not completeness. A
   50%-missing `solutions.bin` where every present record is
   C1–C5 compliant passes both verifiers cleanly. For new
   canonicals (where there is no reference sha yet),
   incompleteness is undetectable without an explicit audit.
   See item #5a below.

5a. **Pre-merge inventory reconciliation + post-merge audit.**
   ⚠ **[CORRECTED 2026-09-01. This item was headed "closes the
   completeness gap" while prescribing a ±1% tolerance that lets
   1,583 of 158,364 cells vanish undetected — and it asserted the
   absence of a manifest that `solve.c` in fact emits and verifies.]**

   **`--merge` walks the shard directory and merges what it finds,
   and it does not consult the shard manifest.** That much is true,
   and it is the real exposure: a shard lost to disk corruption,
   partial rsync or accidental removal yields silently incomplete
   output, exit 0, and a wrong sha. For an established canonical a
   sha mismatch catches it; for a new canonical there is no
   reference to mismatch against.

   But the old text's flat claim that **"there is no manifest"** was
   false for the enumeration path. `solve.c` ships
   `--emit-shard-manifest` and `--verify-shard-manifest`, auto-emits
   a manifest after every shard flush and after orphan promotion
   (suppressible with `SOLVE_SKIP_AUTO_MANIFEST=1`), and **runs the
   verify unconditionally at canonical-enum startup**, exiting 22 on
   MISSING / SHRUNK / DIVERGED. What is missing is the wiring into
   the **merge** step — not the mechanism.

   **So do not build the ±1% count check.** It is strictly weaker
   than an exact per-shard reconciliation the binary already
   implements, and a count tolerance cannot distinguish "1,583 cells
   never produced solutions" from "1,583 shards were lost in
   transit." Run `solve --verify-shard-manifest` against each
   contributing VM's manifest with the merge directory as CWD
   (§6c Phase 3), and gate the merge on an exact match. `EXTRA` is
   non-fatal, which is what makes this work across a multi-VM
   collection.

   The original `merge_audit_pre.sh` and `merge_audit_post.sh`
   reference scripts were removed 2026-06-11; equivalent
   functionality is planned as native `solve.c` subcommands (project
   task #58). Nothing shipped can act on the checks below today, so
   they are a specification for a future implementer, not a
   procedure you can run:

   *Pre-merge (refuse if anything looks wrong):*
   - **Exact** shard-manifest reconciliation per contributing VM —
     no tolerance
   - `.dfs_state` count **exactly** equal to the expected cell count
     (158,364 at depth-3), counted on the filesystem rather than
     parsed from a log
   - No zero-byte / sub-32-byte shards (truncated writes)
   - All shards record-aligned (no mid-record truncation)

   *Post-merge:*
   - `solve --verify` (C-side per-record correctness)
   - `verify.py` (Python independent per-record correctness)
   - sha match against expected (when available)
   - **Deterministic re-merge from same shards in fresh dir;
     sha must match** — catches non-determinism in solve.c's
     merge (e.g., timing-dependent ordering bugs)
   - Yield-report extraction for forensic record —
     `solve.py --branch-yield-report <solutions.bin>`, or the C
     `solve --yield-report` reading the enum log on stdin. (Not
     `solve --branch-yield-report`; that option does not exist.)

   Both scripts are bash + GNU coreutils + Python. Wire into
   your orchestrator before/after `solve --merge`. Fail-fast on
   any audit failure. Audit overhead: ~5-10 min per merge
   (deterministic re-merge dominates). What it does NOT catch:
   per-cell yield drift within bounds, agreed bugs across
   C and Python implementations, heap-corruption-induced
   silent data corruption that produces records still
   satisfying C1–C5. Independent re-derivation on different
   hardware (Tier 4 cross-arch for established canonicals)
   is the strongest defense against the latter.
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

### 13.0. Scale honesty — where solve.c has been validated, and where it hasn't

This guide references PT-scale campaigns (5.6 PT, 56 PT) as part
of the planning vocabulary, but **the implementation has not been
empirically validated at those scales**. Anyone planning a
campaign substantially larger than the 100T pilot should treat
solve.c as a system that may need audit, hardening, or partial
retooling before it can run reliably at the new scale.

**Empirically validated:**
- 11.2T canonical full enum (Tier 1, byte-identical sha
  reproducibility across multiple paths,
  sha=`0c0fe37cf449cbc6e2754583964a60c185a7b387ee522fa43a8aac4fdb055db7`,
  759 M canonical orderings)
- 100T canonical (single observed run, 2026-04-19/20, ~17h
  wall, 158,364 sub-branches at depth=3, full solutions.bin
  produced, sha=`915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5`,
  3.43 B canonical orderings — this is the *post-bugfix* run;
  earlier 100T attempts in early/mid April 2026 hit a
  filename-collision bug that silently undercounted by ~23×
  and are not part of the validated record)

**Also empirically validated — 560T canonical, completed 2026-06-08.**
⚠ This entry sat under "*Planned but not yet run*" until 2026-09-01, roughly
twelve weeks after the campaign was CANONICAL-verified. 158,364/158,364 cells
scanned; 65,281 produced solutions (41.2% yield); 10,525,271,997 unique records
in 336,808,703,936 bytes; sha
`9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`. Enum on
D128als_v7 Spot across five evictions, 171.5 h wall; merge external
chunked-sort on Premium scratch, 18 h 42 m. Full record in
[CANONICAL_HASHES.md](CANONICAL_HASHES.md).

**Planned but not yet run (as of this doc's revision date):**
- Nothing at present. The scales below are speculative, not planned.

**Speculative — would require investigation/retooling first:**
- 5.6 PT (10× the 560T plan, 56× the 100T pilot)
- 56 PT (100× the 560T plan, 560× the 100T pilot)
- Depth-4 attempts (orders of magnitude beyond current scales)

**Specific concerns that have NOT been validated at PT-scale:**

1. **Integer overflow.** `long long` handles 5.6 × 10^14 nodes
   easily, but specific arithmetic patterns in solve.c (cumulative
   counters, hash-table seed mixing, depth-multiplied budgets)
   may overflow earlier. A code-level audit looking for patterns
   like `count1 * count2`, `nodes * factor`, or any operation that
   could produce a value approaching `LLONG_MAX = 9.2 × 10^18`
   is worth doing before any 5.6 PT or larger run. Not blocking
   for 560T (the budget there is 5.6 × 10^14, leaving 4 orders of
   magnitude of headroom in `long long`).

2. **Hash table sizing.** The current per-thread `sol_table` and
   global merge-time hash table use heuristic sizing tuned for
   100T-class workloads. At 5.6 PT scale, expected solution counts
   could push toward 5–10 B entries; the current sizing may not
   handle this gracefully. Audit the table-resize / load-factor
   logic before scaling.

3. **Heap-corruption family at long thread runtimes.** A
   heap-corruption pattern observed at 128 threads × 75+ minutes
   has been mitigated (fork-merge isolation, dead-free patch) but
   not eliminated. At PT-scale, individual --branch runs are
   longer (multi-day per branch), so the residual crash rate
   could increase even with both mitigations in place. The
   shard-then-fresh-merge recovery pattern still produces correct
   results but adds operator toil. See §13a #9.

4. **File handle / inode limits.** ⚠ **[CORRECTED 2026-09-01 — the count here
   was ~64× too high, from two errors in one sentence.]** It read: *"A 5.6 PT
   campaign with 64 first-level branches × 158k sub-branches each = ~10 M shard
   files."* There are **56** valid first-level branches, not 64 (three pair
   indices are pruned at depth 1 in both orientations, and index 0 is the fixed
   start pair — see §7), and **158,364 is the total depth-3 cell count across
   all of them**, not a per-branch count. Multiplying the two double-counts the
   partition.

   **At depth 3 the ceiling is 158,364 shards, whatever the node budget.**
   Raising the budget makes each cell walk deeper; it does not repartition. The
   measured 560T campaign produced 158,364 `.dfs_state` files and 65,281
   non-empty shards. This matters beyond arithmetic: an inventory gate built to
   the old expectation would reject a **complete** 158,364-cell campaign as 98%
   missing.

   A deeper partition would change the count, but then state the depth and
   derive the count from it rather than multiplying a total by a branch count.
   Even so, plan for headroom: `ulimit -n 16384` or higher for the merge (the
   external path opens many chunks at once — see `SOLVE_MERGE_CHUNK_GB`), and a
   filesystem with inodes to spare.

5. **Merge memory at PT scale.** §9b discusses this — but the
   transition from in-memory to disk-based merge is currently
   based on extrapolation, not measurement. The disk-based merge
   path in solve.c (if/when it lands) needs validation at PT-scale
   shard counts, not just unit-tested.

6. **Long-running fragmentation and OS instability.** Multi-week
   continuous campaigns surface OS-level issues (kernel memory
   fragmentation, driver bugs, transient hardware errors) at rates
   not seen in shorter runs. Reproducible recovery is essential
   but not yet validated past the 100T-pilot eviction-recovery
   pattern.

7. **Per-thread rate degradation at long elapsed times.** The
   100T pilot ran ~17 hours and per-thread rate stayed roughly
   stable. There is no observation past 17 hours per VM. PT-scale
   single-VM runs would extend to weeks; rate degradation patterns
   (allocator fragmentation, page-cache eviction, etc.) are
   unknown.

**Recommendation for any sub-PT-scale-and-up campaign:**

Before launching, do an explicit pre-flight audit of the items
above relevant to your scale. Budget engineering time for
retooling solve.c if any audit item surfaces a real issue. Don't
treat the 100T pilot's success as proof that solve.c handles 5.6
PT or 56 PT — those are extrapolations, not validated patterns.

If you run a sub-PT-scale-and-up campaign that surfaces new
concerns or validates one of the speculative items, contributing
your findings back to this doc is welcome.

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

**This campaign has since run** (completed 2026-06-08), so the plan below is
shown against what actually happened. Read the right-hand column first: the
plan's usefulness as a template is mostly in where it was wrong.

| Field | Planned (2026-05) | Actual |
|---|---|---|
| Budget per first-level branch | 10 T nodes | as planned |
| Total nodes (56 branches) | 560 T | as planned; `SOLVE_PER_SUB_BRANCH_LIMIT=3536157207` |
| VMs | 2 × D64als_v7 spot, westus3 | **D128als_v7 Spot, westus3** |
| Branches per VM | ~~31 (after balanced split)~~ **28** | — |
| Per-thread rate | ~~15 M nodes/sec/thread (mid estimate)~~ **withdrawn — see §2c** | not separately recorded |
| Wall (enum) | ≈ 81 hr ≈ 3.4 days; ~5 days worst case | **171.5 h across 5 Spot evictions** — ~2.1× the mid estimate and past the worst case |
| Merge VM | ~~D64 (likely sufficient with ~180 GB RAM); fallback D128~~ | **D16als_v7 (32 GB), external chunked-sort on Premium scratch** |
| Merge wall | ~~~2 hr~~ | **18 h 42 m** — ~9× the estimate |
| Solutions | ~~1.2–1.5 B (estimated)~~ | **10,525,271,997** — 7–9× the estimate |
| Cost | ~$110 mid, $85–165 range | not recorded here; the wall overruns above make the planned range unreliable |

⚠ Three of these rows were corrected on 2026-09-01 rather than merely updated,
because they were wrong as *planning inputs*, not just as forecasts: "31
branches per VM" enumerated six branches that cannot run and would have hung
both VMs (§7); the 15 M nodes/sec/thread rate had no provenance anywhere in the
project (§2c); and "D64 … ~180 GB RAM" doubled that SKU's memory — D64als_v7
has 128 GB.

**The template's real lesson is the direction of the errors.** Every quantity
that was estimated came in high on cost and low on yield, and the merge — the
step the plan treated as a rounding error at ~2 hr — took 18 h 42 m and drove
the SKU choice in the opposite direction from the plan (down to a 32 GB VM with
fast scratch, not up to a big-RAM one). For larger campaigns, scale the budget
linearly if you must, but size the merge from §9b's external path and treat any
wall estimate here as a lower bound.

## 15. References

- `petersm3/roae`:
  - [`SOLVE.md`](SOLVE.md), [`SOLVE_SUMMARY.md`](SOLVE_SUMMARY.md) — what's been computed and what holds
  - [`SPECIFICATION.md`](SPECIFICATION.md) — formal constraint definitions
  - [`PARTITION_INVARIANCE.md`](PARTITION_INVARIANCE.md) — the theorem this guide's correctness story rests on
  - [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) — `solutions.bin` byte format
  - [`DEVELOPMENT.md`](DEVELOPMENT.md) — `--extended-selftest`, build flags, invariants
  - [`DEPLOYMENT.md`](DEPLOYMENT.md) — Azure VM sizing, region notes
  - [`HISTORY.md`](HISTORY.md) — what's been run, when, how it landed
- `petersm3/roae-private` (private operator log; not publicly accessible — provenance pointers only):
  - `roae-private/CAMPAIGN_2026_05_VALIDATION.md` — the campaign that produced the lessons in this guide
  - `roae-private/CAMPAIGN_560T_PLANNING_2026_05_02.md` — detailed planning for the campaign this guide's worked example refers to
  - `roae-private/campaigns/560t_scripts/` — reference scripts (orchestrator, branch runner, branch lists)
