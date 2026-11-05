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
> * **§6 campaign architecture** — per-VM runner pseudocode (the cross-VM orchestrator pseudocode, §6c, was retired 2026-11-04; the section says why and what to build from instead)
> * **§9b** — merge sizing and the external-merge path for extreme scale
>   (§9c's tiered-merge recipe was withdrawn 2026-09-01 as unrunnable; the
>   section retains the explanation of why)
> * **§13.0 scale honesty** — the disclosure that solve.c is **not empirically validated**
>   at PT scales, only to the 100T pilot (since then also at 560T — §13.0 and CANONICAL_HASHES.md; Codex FV-G4-C7#11)
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

   ("Tier N" in this guide is the 2026-05 **validation-campaign** tier
   numbering recorded in [HISTORY.md](HISTORY.md) — the "Tier 1 — 11.2T
   canonical" entry and the tier table that follows it: Tier 1 = the 11.2T
   canonical, Tier 5 = the (22, 0) asymmetric extension, Tier 9+ = the
   production-scale spot checks. It also covers this guide's test
   rungs Tier 2c and Tier 9a/9b/9c, which are the same series. It is unrelated
   to **five** other senses that reuse the word: the Lean **proof-strength**
   tiers in [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) and
   [`lean/README.md`](../lean/README.md); the **determinism-hardening** tiers in
   [DEVELOPMENT.md](DEVELOPMENT.md) and [CANONICAL_HASHES.md](CANONICAL_HASHES.md);
   the **scoring-axis** `tier-1`/`tier-2` of [CRITIQUE.md](CRITIQUE.md) and
   [SOLVE_C_CLI.md](SOLVE_C_CLI.md); the
   Standard/Premium **disk** tiers used throughout
   [DEPLOYMENT.md](DEPLOYMENT.md) and later in this file; and the reduced-rung
   **"Tier-2 scope"** of [VERIFY.md](VERIFY.md). ⚠ *(This parenthesis named only
   two other senses until 2026-09-03; the corpus carries eight public ones.)*)

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
   the shards and the `.dfs_state` files are unconditional.
   `per_task_stats.csv` is not: only the parallel `--sub-branch` path
   writes it, and a `--branch` run or a full enumeration writes none. What you must do is **transfer and keep them**; see §11 for the list and §12 for the checks. ⚠ [2026-11-04, CX-36N-A (Codex F12-011#7): this item said `per_task_stats.csv` was unconditional too, and pointed to the §6c transfer step, now retired.]

## 2. Sizing: choose VM size, count, and budget

### 2a. Architectural cap: ~64 useful threads per single-branch run

[`solve --branch <p1> <o1>`](SOLVE_C_CLI.md#--branch) parallelizes across the
depth-3 sub-branches of one first-level branch — **~2,828 on average**
(158,364 cells ÷ 56 valid branches, per
[BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md)); the "~2,824" this line used
to give is one branch's count, not the mean.

⚠ **[SCOPED 2026-09-03 — the thread-scaling sentence here was a pre-fix
`--sub-branch` measurement carried as a current causal fact about `--branch`.]**
It read: *"Empirically, per-thread rate **halves past 64 threads** due to NUMA
boundaries (D128 has two sockets) and hash-table contention."* What was
measured: the April 2026 P1 `--sub-branch` scaling runs
([HISTORY.md](HISTORY.md), the "P1 v3: per-CCD counters" entry and the
measurements before it) found single-process throughput on D128 capping near
~1 B nodes/s against a ~1.6 B/s packed-aggregate — roughly a halving — and
traced it to **every thread contending on one shared atomic node counter**,
not to NUMA. The per-CCD counter fix that followed is recorded there as
"mechanism is correct by construction; not re-measured on D128". "Two
sockets" appears in no measurement record in this project, and nothing on
file distinguishes sockets from NUMA nodes or CCDs on those hosts. So: **a
>64-thread single process lost about half its per-thread rate in the pre-fix
`--sub-branch` measurement; whether `--branch` on a current binary still does
is unmeasured.** The sizing advice survives on cost grounds — HISTORY.md
records D64 packing as the measured cost optimum for single-branch work, so
**D64-class VMs remain the right size**, and a D128 should run two concurrent
`--branch` jobs rather than one — but treat the halving as a pre-fix
observation to re-measure, not as a property of the hardware.

### 2b. VM count: cost-equivalent, wall-time-different

Total compute cost for a campaign of fixed size is roughly the
same regardless of VM count (D-als-v7 spot pricing is near-linear
in cores). What VM count buys you is **wall time** and **eviction
redundancy**.

| VMs | Aggregate cores | Wall (560T) | Eviction blast |
|---|---|---|---|
| 1 × D64 | 64 | ~5.6 days | one VM eviction halts campaign |
| **2 × D64** (recommended for 128-vCPU spot quota) | 128 | **~3.4 days** | redundant — one VM evicts, other progresses |
| 4 × D64 (needs 256-vCPU quota) | 256 | ~1.7 days | best |

These rows are the 2026-05 **forecast** for the 560T campaign, kept as the
worked plan; §14 sets them beside what the campaign actually took — 171.5 h of
enum wall on a D128 (~2.1× the mid estimate) and an 18 h 42 m merge the plan
carried at ~2 h. Read them as a sizing method, not as expected outcomes.

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

`SOLVE_NODE_LIMIT` is a **cap**, not a target, and it caps a run only
through the per-cell budget it is divided into (§3a). Without `SOLVE_PER_SUB_BRANCH_LIMIT`, the nodes one run walks total at most the cap, typically less. With it set, the override replaces the derived budget and nothing holds the total to `SOLVE_NODE_LIMIT`: at the published 560 T value `3536157207`, the 2,850 depth-3 cells of branch (3,0) are allotted 10,078,048,039,950 nodes, above a 10 T `SOLVE_NODE_LIMIT`. ⚠ [2026-11-04, CX-36N-A (Codex F12-011#13): this read "Total nodes walked is always ≤ the cap".] Two structural reasons for the shortfall:

### 3a. Per-sub-branch budget is what's binding

For `--branch X Y` mode, solve doesn't enforce the global node
limit directly during enumeration. Instead it computes (or accepts
override of) a **per-sub-branch budget**, and stops each cell when
it hits that. The global cap is not checked during `--branch` enumeration, so it is not a safety ceiling there; the per-sub-branch budget is what bounds the walk.

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
`divisor = total_branches` — the run's real cell count: **158,364** for a full
depth-3 enumeration, and the selected branch's own partition in `--branch` mode
(2,824 cells for branch (2,0), so a 10 T `SOLVE_NODE_LIMIT` gives `3541076487` per cell there) — and overwritten outright by `SOLVE_PER_SUB_BRANCH_LIMIT` when that is set. So there was never a wrong divisor to override. ⚠ **[2026-11-04, CX-36N-A (Codex F12-011#12).]** The paragraph above said the divisor is 158,364 in every mode; in `--branch` mode it is the branch's partition. Its `/3030` sites are also gone: since 2026-09-26 (V3A-134#8) the resume-skip threshold uses the allocator's own divisor, the run's partition, so the quoted "approximation error is irrelevant" comment describes older code. The published PSB values are unaffected: they are set explicitly.

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

⚠ **[CORRECTED 2026-09-25 (Q-758, Codex V3A-032#5) — the mechanism this subsection asserts has never been observed in a published run.** It says "most cells walk fewer than per_cell_budget nodes because they naturally terminate", and that "even on a clean run there's some natural-termination contribution". The measured record says the opposite, at every depth it covers. This guide's own §1 table, from the 100T pilot's `per_task_stats.csv`, records **0 of 975** depth-5 sub-tasks naturally terminated. The tracked 100T canonical analyzer log (`runs/20260419_100T_d3_d128westus3/analyze_output.log.gz` §[27]) prints `Total entries: 4096 (EXHAUSTED/COMPLETE: 0, BUDGETED: 4096, INTERRUPTED: 0)`. At 560T, 158,364 of 158,364 cells checkpointed at budget ([CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md) §7). Natural termination is possible in principle: a cell whose subtree is finite below its budget stops early. No published run has a cell that did. The 0.57 % under-shoot below is therefore the two crashes, not natural termination. §3c's "cannot guarantee total walked ≥ N" still holds as a statement about what the code permits. Just do not read it as a description of what happens.]** Even with the per-cell budget set correctly, **most cells walk
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
  `shards_by_final_status` in `solutions.provenance.json`. That rollup counts **shards**, and a shard (with its provenance sidecar) exists only for a cell that produced at least one record. A zero-yield cell, BUDGETED or EXHAUSTED, is not in it: at 560 T it covers 65,281 of the 158,364 cells. For the per-cell count use the merge's `Checkpoint cross-ref: <E> EXHAUSTED, <B> BUDGETED` line, which reads the checkpoint lines. ⚠ [2026-11-04, CX-36N-A (Codex F12-011#9).]

## 4. Cost estimation methodology

Apply this formula:

```
total_node_budget    = 56_branches × per_branch_budget   (e.g., 56 × 10T = 560T)
aggregate_throughput = num_VMs × 64 × per_thread_rate    (use the rate from §2c)
wall_seconds         = total_node_budget / aggregate_throughput
vm_hours             = num_VMs × wall_hours
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
4. `--branch + depth-3 + SOLVE_THREADS=128` stack-array sizing *(since 2026-10-22, CX-35V-D: it requires a nonempty shard, the log's `ENUM_RUN=FINISHED` line, and exit 0 or the documented -11; until then one matching shard filename passed whatever the exit)*
5. `--branch` multi-budget resume gate ⚠ *(see the CX-134 note on item 9)*
6. Combined partition + resume invariance *(since 2026-10-22, CX-35V-D: `--branch 1 0` and `--branch 2 0` at 50M extended to 100M in one directory and merged, against the same branches single-shot; until then this item repeated item 2's full-enumeration resume and partitioned nothing)*
7. Distributed-merge equivalence (multi-VM shard collection) *(a missing merged sha on either side fails it since 2026-10-22, CX-35V-D; until then the comparison ran only when both were present)*
8. Single-branch eviction-resume invariance (SIGTERM mid-walk) ⚠ *(see the CX-134 note on item 9; and until 2026-10-22, CX-35V-D, the interrupted phase ran without `SOLVE_ALLOW_SUB_CANONICAL` and exited 25 before walking from a clean environment, so the test compared two clean runs; it now requires `ENUM_RUN=STOPPED` in that run's log)*
9. Idempotent re-launch of completed `--branch` ⚠ **[Scoped 2026-09-25 (CX-134): until that fix the per-branch file these three items hash held 0 records, so the sha comparisons of items 5 and 8 compared two copies of one header-only sha (`4cd43b2b…`) and could fail only on an exit code. Item 9's shard filename-and-size check was real; its sha check was not. On the CX-134 binary all three compare real content and PASS. See documentation/CORRECTIONS.md CX-134.]** *(Item 9 fingerprinted its shards by name and size until 2026-10-22, so a same-size content change passed; it hashes their bytes since, CX-35V-D.)*

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
    SOLVE_NODE_LIMIT=100000000,   # 100 M; a suffix such as 100M exits 2 (SOLVE_ENV=REFUSED)
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
([CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"100B and sub-canonical reference
shas", paragraph "Sub-canonical hard-gate (landed 2026-05-25)"). This
block set neither, so it exited **25** and wrote no shards — failing its own
first two assertions — and it had done so since the gate landed. The smoke test
predates the gate and was never updated. `SOLVE_ALLOW_SUB_CANONICAL=1` is the
honest override here: it acknowledges the output sha is code-specific, which is
irrelevant for a plumbing test whose sha nobody reads.

**Run this on each campaign VM before launching the actual
canonical-budget enum.** Wall: ~5 minutes. Cost: trivial. If it
fails, you've caught a deployment / env / disk / binary
issue at trivial cost instead of mid-canonical after hours of wasted compute.

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
   wasted spot time on the validation campaign. Always
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
            # ⚠ 2026-11-04, CX-36N-A (Codex F12-011#7): a line here set
            # SOLVE_DEPTH_PROFILE = 1 and said per_task_stats.csv "is written
            # unconditionally". Both the DEPTH_PROFILE histogram and the CSV
            # are written only by the parallel --sub-branch path; this # --branch launch writes neither, so the line is removed.
            # ⚠ CORRECTED 2026-09-25 (Q-758, Codex V3A-032#3): a line here read `SOLVE_CKPT_INTERVAL = 300,  # 5-min checkpoint cadence`. --branch never reads it: the only getenv("SOLVE_CKPT_INTERVAL") in solve.c sits in the parallel --sub-branch spawn, beside the thread_func_ckpt launch. This runner checkpoints through SOLVE_DFS_CHECKPOINT's per-cell .dfs_state sidecars, which are written when a cell reaches its budget, not on a timer. Setting it is harmless. It is not a 5-minute cadence.
            SOLVE_THREADS                = 64,
         }
         INTO $WORKDIR
         REDIRECT >> "$ROOT/logs/branch_${p1}_${o1}.log"

    rc = $?
    sha_file = "$WORKDIR/solutions_${p1}_${o1}.sha256"

    status = json_field(read("$WORKDIR/results_${p1}_${o1}.json"), "status")
    # ⚠ 2026-11-04, CX-36N-A (Codex F12-011#1): this read solve_results.json, # which --branch never writes (it writes results_<p1>_<o1>.json), so in a # fresh directory no branch could ever be marked done. 
    IF rc == 0 AND sha_file exists AND status == "SEARCH_COMPLETE":
      sha = first_field(read(sha_file))
      atomic_touch(DONE_MARKER)              # only NOW mark complete
      log "DONE $p1/$o1 sha=$sha"   # ⚠ 2026-09-25 (CX-134): before that fix this sha was the same header-only 4cd43b2b… for every branch
    ELSE IF rc == 0 AND status == "TIMED_OUT":
      # SIGTERM or wall-clock stop. solve WRITES ITS SHA AND RETURNS 0 here, # [2026-10-01, Q-888 (1): solve now exits 36 here, with BRANCH_OUTPUT=PARTIAL and its set under solutions_<p1>_<o1>.partial.*, so this arm is reached only with an older binary; the rc != 0 arm below retries it]
      # so an rc-plus-sha test alone marks this branch done forever with as
      # little as 0 of its cells walked. Retry; do NOT touch DONE_MARKER.
      log "$p1/$o1 exit=0 but status=TIMED_OUT; will retry next loop"
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
  files solve wrote and resumes, and the result is the same. Some work is redone: a cell's `.dfs_state` is written when the cell reaches its budget, not during the walk, so a cell that was mid-walk when the process died is walked again from its last saved state (for a cell walked for the first time, from its start). ⚠ [2026-11-04, CX-36N-A (Codex F12-011#31): this bullet ended "No work is rewound."]
- **Eviction-safe.** Same as crash-safe; spot eviction is just a
  particular crash flavor.
- **Restart-safe.** Manually re-launching the script is a no-op
  for completed branches (skipped via DONE_MARKER) and a resume
  for the in-progress branch.
- **A clean exit plus a sha attests the ARTIFACT, not completion.** The
  DONE_MARKER is touched only after a clean exit, a sha file, AND the run's
  own `"status": "SEARCH_COMPLETE"`. Exit status and sha alone are **not**
  a completion test: after a SIGTERM, `--branch` writes its sha, records
  `"status": "TIMED_OUT"`, and **returns 0**. Measured —
  `timeout --preserve-status -s TERM 15 solve --branch 2 0 0 2` gives rc 0,
  a written sha, `Sub-branches: 0/2824 completed`, and zero `.dfs_state`
  files left behind. A runner keying on rc and sha marks that branch done
  **forever**, with none of its 2,824 cells finished. ⚠ **[CORRECTED
  2026-09-19 — this bullet read "Verifies before claiming complete. The
  DONE_MARKER is only touched after BOTH a clean exit AND a sha file
  exists", which is precisely the unsafe test, and the pseudocode above
  implemented it. Note the limit of the repaired version, so it is not read
  as more than it is: `SEARCH_COMPLETE` is a **lifecycle** status — in
  `solve.c` it is simply the `else` of `if (global_timed_out)` at both
  emission sites — so it separates "this process finished normally" from
  "it was stopped", and it does **NOT** assert that the search space was
  exhausted. Every budgeted run reports it; see
  [DEPLOYMENT.md](DEPLOYMENT.md) §"Completion and archival". See
  documentation/CORRECTIONS.md CX-52.]** ⚠ **[Scoped 2026-09-25 (CX-134): before that fix the per-branch file behind this sha held 0 records, so the sha the runner logs was the same header-only `4cd43b2b…` for every branch and attested no records. The lifecycle point above stands. A campaign's data went through the `sub_*` shards and `--merge`, never through this sha.]** ⚠ **[2026-10-01, Q-888 (1): a stopped `--branch` no longer returns 0. It writes its partial set to `solutions_<p1>_<o1>.partial.bin` and `.partial.sha256`, prints `BRANCH_OUTPUT=PARTIAL` and exits 36, so the rc-plus-sha test above no longer marks a stopped branch done; the status check is kept for older binaries. See documentation/CORRECTIONS.md (batch 31c).]** ⚠ **[2026-10-02, Q-317 (5), batch 33: `solve` now also prints a whole line `BUDGET_EXHAUSTED=YES|NO|UNKNOWN` after `ENUM_RUN`. A budgeted branch prints `YES` and is still marked done by the status test above, as it should be: the token says the branch's records are a budget-limited slice, it does not make the branch unfinished. See SOLVE_C_CLI.md.]**

### 6c. Cross-VM orchestrator — RETIRED 2026-11-04

⚠ **[RETIRED 2026-11-04 (CX-36N-A; Codex final review, F12-011).]** A pseudocode "cross-VM orchestrator" stood here: wait for every VM's completion marker, copy the shards and their sidecars onto one merge host, check each VM's shard manifest, run `solve --merge`, extract metadata, and declare the canonical. Codex's final review found that it disagreed with the shipped binary at eight points, so an orchestrator built from it would stall, refuse a healthy collection, or pass a merge it should have failed:

- It checked each VM's manifest in the combined shard directory, and said the other VMs' shards would show as a non-fatal `EXTRA`. `--verify-shard-manifest` names them `UNLISTED` and exits 22 (F12-011#2).
- It needed a manifest per VM, which the §6b runner never produces: `--branch` returns before both of the full enumeration's automatic manifest writes (F12-011#3).
- It put the shard provenance sidecars in per-VM directories, but `--merge` aggregates only the sidecars in its own directory (F12-011#5).
- It copied every VM's `checkpoint_t*.txt` into one directory. Those names carry only a local thread number, so one VM's files overwrite another's (F12-011#6).
- Its metadata step globbed one directory for CSV files it had put in subdirectories (F12-011#8).
- Its restart guard treated an existing `solutions.sha256` as a finished merge. `--merge` writes that file before its automatic `--verify`, and a failed verify (exit 30) leaves it in place, so a re-run skipped the failed merge (F12-011#10).
- It declared the canonical without `python3 verify.py --expect-kw`, which §12 requires (F12-011#11).
- It said `--merge` silently drops a trailing argument. Since 2026-09-04 it refuses one with `MERGE_ARGS=REFUSED` and exit 2 (F12-011#20).

Rather than patch it point by point, the pseudocode is retired; it is kept below, collapsed, as a record only. The published 560 T canonical was not built this way: it ran as one full enumeration on one machine, with the merge on a second ([CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md) §7). Build from these instead:

- [CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md) §8, the step-by-step reproduction recipe (build, selftest anchor, full enumeration, `--merge`, verification), and §7, how the 560 T campaign actually ran.
- §12 below, the reproducibility checklist, rewritten on the same date against the current binary.
- The shipped commands those name: `solve --emit-shard-manifest`, `solve --verify-shard-manifest`, `solve --merge`, `solve --verify` and `python3 verify.py --expect-kw`.
- The project's own campaign scripts (§6e). They are private and can be disclosed to an auditor; they are a record of what ran, not a public recipe.

If you split one campaign across machines anyway, keep each machine's files apart until they are checked. In each machine's work directory run `solve --emit-shard-manifest` yourself (a `--branch` run writes none). On the merge host, put each machine's shards and that manifest in a directory of their own and run `solve --verify-shard-manifest shard_manifest.txt` there, where no other machine's shard can be `UNLISTED`. Do not copy two machines' `checkpoint_t*.txt` files into one directory: the names collide, and the merge's checkpoint cross-check reads `checkpoint.txt` and every `checkpoint_t<digits>.txt` in the merge directory. This guide no longer gives a tested recipe for combining them; one machine per enumeration directory, as the 560 T campaign ran, avoids the problem. Then gate on §12.

<details><summary>The retired pseudocode and its claimed properties, kept for the record. Do not build from it.</summary>

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
- **Decoupled from VMs' interiors.** Polls only for completion markers; doesn't care how a VM got to "complete" (single run, multiple eviction-restarts, manual-resume after crash).
- **Operator-in-the-loop for shard transfer.** Cross-VM shard transfer is the highest-risk step (rsync edge cases, network flakes); have the operator confirm transfer integrity before the orchestrator proceeds. Tier 9c verifies the rsync pattern works byte-correctly at small scale.
- **Side-metadata is captured in the same pass as the shards — but not atomically, and not for free.** This bullet used to claim "all side-metadata captured atomically with the canonical sha." It is a sequence of independent `rsync` invocations against live VMs; nothing makes it atomic, and until 2026-09-01 the transfer list omitted the `.dfs_state` files, the checkpoints, the shard manifests and the provenance JSON that §11 calls required. Treat Phase 2 as the step most likely to lose something irrecoverable, and verify it (§12 item 5a) rather than trusting it. `solutions.bin` and `metadata.json` should be archived together — they reference each other.
- **Re-runnable — only because Phase 3 now carries the guard.** If the orchestrator dies between "merge done" and "metadata.json written," re-invoking it skips the merge on the existing `solutions.sha256` and picks up at Phase 4. That guard was added to the Phase 3 pseudocode on 2026-09-01; this bullet asserted the behaviour before anything implemented it, and Phase 3 was an unconditional `solve --merge`. If you build from an older copy of this pattern, add the guard — the 560T merge took 18 h 42 m, and re-running it also reopens a finished artifact for writing.

</details>

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
| 128-thread `--branch` post-enum per-branch merge SIGSEGV | At `SOLVE_THREADS=128` in `--branch X Y` mode (depth-3), the per-branch in-process merge step can SIGSEGV. The enum's shards are written correctly to disk; only the per-branch summary merge crashes. | Doesn't affect global merge correctness — the shards are intact and the next `solve --merge` produces the right sha. Continue the campaign. (Tracked as a known anomaly; selftest subtest 4 explicitly accepts this exit code — since 2026-10-22 only -11, and only after the log's `ENUM_RUN=FINISHED` line and a nonempty shard; any other exit fails it, CX-35V-D.) |

### 6e. Reference scripts

The project's actual implementation of this pattern lives at:

- `petersm3/roae-private:campaigns/560t_scripts/560t_branch_runner.sh`
- `petersm3/roae-private:campaigns/560t_scripts/560t_orchestrator.sh`
- `petersm3/roae-private:campaigns/560t_scripts/branches_A.txt`
- `petersm3/roae-private:campaigns/560t_scripts/branches_B.txt`

`petersm3/roae-private` is a private repository — these scripts are not publicly
accessible; the listing records that a reference implementation exists and can be
disclosed to an auditor. ⚠ [2026-11-04, CX-36N-A: this paragraph said the
public text of this section fully specifies the pattern and is what to build
from. The §6b runner stands, with its corrections; the §6c orchestrator was retired for the reasons given there. Build the cross-machine steps from CAMPAIGN_METHODOLOGY.md §8 and §12 of this guide.]

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
(simple, fast, what `solve --merge` does when the set fits in RAM) or
**disk-based external merge** (what the same `--merge` falls back to,
or is forced to with `SOLVE_MERGE_MODE=external`, when it would not —
§9b). Pick based on your campaign's expected solution count.

### 9a. In-memory merge (the default)

`solve --merge` reads every shard record into one RAM buffer, heapsorts it in place and drops adjacent duplicates (`solve.c`'s in-memory merge path; `heapsort_records`),
then writes the deduped output. ⚠ *(corrected 2026-09-25: this said the merge builds a hash table of unique solutions. Codex v3 review, V3A-032#6)* RAM
usage therefore scales with the **pre-dedup** shard record count (32 bytes each, auto-switching to external above 80% of RAM), not the unique count; the table below is keyed on unique count, so read it as a lower bound where cross-sub-branch rediscovery is high:

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
| `SOLVE_TEMP_DIR` | CWD | Where the `temp_sorted_*.bin` chunks are written; the merge refuses to start unless it has ~1.5× the input shards' on-disk size free (2026-11-04, CX-36N-A, Codex F12-011#14: this said 1.5× the output) |
| `SOLVE_MERGE_CHUNK_GB` | 4 | Per-chunk size; raise it (16, 32) if you hit the sorted-chunk ceiling or `ulimit -n` |

**And the project has run it at the largest scale it has ever reached.** The
560T merge was "external chunked-sort on Premium scratch, 18 h 42 m" on a
D16als_v7 — 43.88 B pre-merge shard records (per-sub-branch canonical keys, not
raw leaves — see the correction in §9a above) down to 10.525 B unique.
So the disk-based path
is not a follow-on project to scope; it is the path the deepest canonical took.
For anything past ~1 B records, set `SOLVE_MERGE_MODE=external`, point
`SOLVE_TEMP_DIR` at fast scratch sized to ~1.5× the **input** shards'
on-disk size (the merge's own pre-flight check; the sorted chunks hold every input record, duplicates included, beside the de-duplicated stream), and size the **disk**, not the RAM. ⚠ [2026-11-04, CX-36N-A (Codex F12-011#14): this said ~1.5× the output; at 560 T the input records are about four times the output.]

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
| 1 | 1 | 0.632 | 1.2 GiB | ~3.9 B |
| 8 | 6 | 0.0216 | 9.8 GiB | ~227 M |
| 10 | 7 | 0.0082 | 12.3 GiB | ~86 M |
| 16 | 11 | 0.00046 | 19.6 GiB | ~4.8 M |
| 24 | 17 | 0.0000098 | 29.4 GiB | ~104 K |

⚠ [2026-11-04, CX-36N-A (Codex F12-011#16): the last column multiplied the filter's *final* false-positive rate by every record, but the filter starts empty, so early records face a lower rate. For the 1-bit row the exact expectation is `N(1 − 1/N)^N ≈ N/e`, about 3.86 B at N = 10.5 B, not 6.7 B. The other rows use the same final-rate product and are upper bounds. The warning below stands.] 🔴 **The last column is why this is not a canonical path.** A Bloom false
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

- **I small enough that `I × 32 bytes` fits comfortably in your merge host's RAM,
  where I is the pre-merge input record count (duplicates included), not S** → leave `SOLVE_MERGE_MODE` at `auto` and let `--merge` run in memory. The in-memory merge holds every input record, and `auto` switches to external when `I × 32` exceeds 80% of RAM. At 100 T, S = 3.43 B (about 110 GB) but I = 13.83 B (about 443 GB). ⚠ [2026-11-04, CX-36N-A (Codex F12-011#30): this rule was stated on S.] As a
  reference point, the ~750 M-record Tier 1 merge peaked near 90 GB and needs a
  D64als_v7 (128 GB); D32als_v7's 64 GB does not fit it. That 90 GB is an
  estimate carried by this guide, not a recorded measurement — verify it with
  the merge-memory test below before you size on it.
- **Anything larger** → `SOLVE_MERGE_MODE=external`, with `SOLVE_TEMP_DIR` on
  fast scratch sized to ~1.5× the input shards' on-disk size (§9b; this said the expected output until 2026-11-04, CX-36N-A, Codex F12-011#14). Peak RAM is then set
  by `SOLVE_MERGE_CHUNK_GB`, not by S, so the merge VM can stay small: the 560T
  merge did 10.525 B records on a **D16als_v7 (32 GB)**.
- **There is no S at which you need code that does not exist.** External merge
  is not RAM-bounded, so the ceiling is scratch disk and wall time, not SKU. ⚠ **[CORRECTED 2026-11-04, CX-36N-A (Codex F12-011#32): that ceiling is incomplete.]** External merge also has a chunk ceiling: it writes at most 4,096 sorted chunks, so at a fixed `SOLVE_MERGE_CHUNK_GB` the input it can take is finite (about 16 TiB of input records at the default 4 GiB), however much scratch and time you have. Raising the chunk size raises that ceiling and the RAM the merge needs with it, so the ceiling is scratch disk, wall time and chunk count × chunk RAM.

Run **a merge-memory test** in any case where peak RSS is within
2× of available RAM. Better to find out at small scale than at
the end of a multi-day campaign.

## 10. Symmetry shortcuts and other pruning — when defensible

The project's data shows orientation symmetry is **not universal**:
only 16.3% of multi-variant `(p1, p2, p3)` groups have all
orientations equal at 100T budget — and that share compares only the
variants that emitted records (`--yield-report` reads the log's `Wrote`
lines). **585 of those 1,636 groups contain a feasible variant that
emitted nothing**; requiring every feasible variant to have emitted
records leaves 1,051 of 8,072 (13.0%). See
[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) for the definition and its
re-derivation *(definition added 2026-09-24, Q-760)*. Applying an "8× symmetry
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
| `per_task_stats.csv` (one row per **depth-5 task**: `task_idx,p4,o4,p5,o5,nodes,solutions_added,wall_time_ms,worker_id,completed,max_depth,c3_leaves` + 33 per-depth node bins) | **Written unconditionally** by the parallel sub-branch path — no env var needed. Fixed filename in the run's CWD, so give each branch its own directory or it is overwritten. | Worker load-balance and per-task budget analysis. ⚠ This row previously read "per-cell yield + status + nodes-walked + wall … Set `SOLVE_DEPTH_PROFILE=1` during enum" — wrong on both halves. The granularity is per depth-5 task, not per depth-3 cell, and `SOLVE_DEPTH_PROFILE=1` gates a *different* artifact: a per-depth node histogram printed to **stderr** (`DEPTH_PROFILE depth=<d> nodes=<n>` lines). To identify which **cells** are budget-exhausted, use the shard checkpoint state; `shards_by_final_status` in `solutions.provenance.json` counts only cells that produced a shard (§3c; 2026-11-04, CX-36N-A, Codex F12-011#9). | *(2026-10-01, Q-317 (2): a task stopped by `SOLVE_PER_TASK_NODE_LIMIT` is now `completed=0`; before, `completed=1` meant only that no global budget, signal or time limit fired during the task, so a capped task counted as completed.)*
| `checkpoint.txt` | Auto-produced by solve | Records the per-sub-branch budget that was reached. Needed for resume + extension. |
| `branch_yield_report.txt` | `solve.py --branch-yield-report <solutions.bin>` post-merge, **or** the C form `zcat <enum log>.gz \| solve --yield-report` which reads an enumeration **log** on stdin. ⚠ `solve --branch-yield-report` is not a subcommand and never was — the C binary rejects it as an unknown option. [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) documents the C form correctly; this file was the outlier. | Pre-computed per-prefix counts at depths 1, 2, 3 |
| `constraint_definitions.json` | Manual extract from solve.c at locked commit | Future C6 / new-rule work needs to reference the EXACT C1-C5 used |
| All `sub_*.bin` shards + `sub_*.dfs_state` files | Auto during enum | Required for ANY future extension (deeper budget on one or more branches) |
| `metadata.json` (campaign metadata) | Orchestrator writes at end | Binary md5/commit, VM list, runtime, per-VM contribution, eviction events |

"Which cells were budget-exhausted?" is the most-asked future question, and
the answer lives in the `.dfs_state` files and the provenance JSON — **not** in
`SOLVE_DEPTH_PROFILE`, which this paragraph used to warn you against skipping.
Nothing here is opt-in; solve writes it all whether you ask or not. The way you
lose it is by **not transferring it off the enum VMs before teardown** (§12;
the §6c transfer step it pointed to was retired 2026-11-04), and that is unrecoverable in a way a missing env var never was.

### 11a. Pre-record invariants — recompute on demand, don't pre-bake

A natural temptation is to extend `solutions.bin`'s record format
(currently 32 bytes/record) to include pre-computed per-record
invariants (cd, distance-sum, XOR-set, etc.). **Don't.** Two
reasons:

1. **Cache-line-friendly storage matters.** 32-byte records pack
   exactly two per 64-byte cache line. Going to 48 bytes/record
   means every other record straddles a cache line, hurting
   in-memory sort-and-dedup at merge time by an estimated (not benchmarked) ~5–15%. Going to
   64 bytes/record doubles storage. Neither is a great trade.

2. **On-demand recomputation is fast.** cd (mean complement
   distance) for a single 32-byte record is an estimated (not benchmarked) ~100 cycles. For a
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
| Whether near-miss orderings (failed C5 by ≤ N swaps) were captured | C5 is a running transition budget, not a final check: an ordering is pruned at the first transition that exceeds it, so no failed-C5 ordering reaches depth 32, and none is captured. | Full re-enumeration with a "drop C5 final check" mode. |

Decide these before launch — cost of wrong decisions is full
re-runs, not incremental fixes.

## 12. Reproducibility checklist

⚠ **[REWRITTEN 2026-11-04 (CX-36N-A; Codex final review, F12-011#2, #3, #4, #15,
#21, #28).]** The checklist that stood here described the shard manifest and the
merge as they were before several later changes. It said the binary writes a
manifest after every shard flush (it writes one at a full enumeration's start
and after its workers finish, and a `--branch` run writes none); that the
startup check always exits 22 on a mismatch (it is skipped with no manifest and
advisory on a resume); that `--merge` does not consult the manifest (it checks
that every listed shard is present); that the `.dfs_state` count must equal the
cell count (an EXHAUSTED cell's file is deleted, so a complete campaign can
have fewer); and it sized the saved copy at a fixed 250 GB. Each item below was
checked against `solve.c` and `verify.py` on that date.

For any campaign producing a sha you intend to publish:

1. **Lock the binary.** Build once from a tagged commit, with the source
   identity compiled in (`-DGIT_HASH=...`, as in
   [CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md) §8 step 2), and copy the
   same bytes to every machine. Check `./solve --selftest` prints the published
   anchor `403f7202...` on each. The binary guards itself on resume too: a run
   directory records the build in `build.sha`, and a relaunch under a different
   build exits 26 unless `SOLVE_ALLOW_BUILD_MISMATCH=1`.
2. **Record the constraint definitions.** They are the C1–C5 code in `solve.c`
   at the locked commit; the commit id pins them.
3. **Record the build environment.** `bash scripts/capture_build_manifest.sh`
   prints the source identity, toolchain, host CPU and OS. Byte-identical
   output across architectures has been shown once in this project, for an ARM
   rebuild of the 11.2 T canonical ([CANONICAL_HASHES.md](CANONICAL_HASHES.md));
   a new architecture needs its own check.
4. **The merge is order-independent.** `--merge` sorts and de-duplicates every
   input record, so the merged set does not depend on the order shards arrive.
   For an existing canonical the real test is reproducing its published sha.
5. **Check the merged output in two languages, before you publish.**
   - `solve --merge` runs `solve --verify` on its own output (it exits 30 if
     that fails; `SOLVE_SKIP_AUTO_VERIFY=1` turns it off). Gate on the
     **exit status**, not on `solutions.sha256` being there: the merge writes
     the sha file before that check and leaves it in place when the check
     fails.
   - Then run `python3 verify.py --expect-kw solutions.bin` yourself; the merge
     does not. `verify.py` is a separate Python implementation of C1–C5, so it
     catches a bug the C checker shares with the enumerator. `--expect-kw`
     makes King Wen's absence a failure; without it the absence is only
     reported.

   Both checkers test each record. Neither tests completeness: a
   `solutions.bin` missing half its records passes both if every record left is
   valid. For a new canonical with no reference sha, item 5a is the only check
   on completeness.

5a. **Account for every cell and every shard.**

   *What the binary already checks.*
   - A full enumeration writes `shard_manifest.txt` after its startup
     promotion and again after its workers finish
     (`SOLVE_SKIP_AUTO_MANIFEST=1` turns both off). At the next start it
     checks the shards against that manifest. On a fresh start a mismatch
     exits 22. On a resume (any `.dfs_state` present) the check is advisory:
     it prints the counts and `AUTO_MANIFEST_UNEXPLAINED=<n>` and goes on.
     With no manifest it is skipped. A `--branch` run does none of this; run
     `solve --emit-shard-manifest` yourself.
   - `solve --verify-shard-manifest <file>`, run in the shard directory,
     re-hashes every listed shard and exits 22 on a missing, shrunk or
     changed shard, on a shard the manifest does not name (`UNLISTED`), or on
     a duplicate line.
   - `--merge` cross-checks its directory before merging. It refuses an
     enumeration that has not finished (`MERGE_INPUT=INCOMPLETE`, exit 35), a
     cell that was INTERRUPTED and never finished, and a shard that is absent
     or shorter than its checkpoint line claims. If a `shard_manifest.txt` is
     present it also refuses when a listed shard is absent
     (`MERGE_SHARD=MISSING`, exit 20). That is presence only; sizes and hashes
     are the manifest check's job. It does not re-hash shards.

   *What to check yourself, before the merge:*
   - `solve --verify-shard-manifest` against each machine's own manifest, in
     a directory holding only that machine's shards (§6c).
   - The cell count, from the checkpoint lines rather than from `.dfs_state`
     files. A BUDGETED cell keeps its `.dfs_state`; an EXHAUSTED cell's is
     deleted when it finishes. So the number of `.dfs_state` files equals the
     cell count only when every cell was BUDGETED, as at 560 T. The merge
     prints `Checkpoint cross-ref: <E> EXHAUSTED, <B> BUDGETED, 0 INTERRUPTED
     sub-branch(es)`; E + B must equal the expected cell count (158,364 for a
     full depth-3 enumeration).
   - No shard under 32 bytes, and every shard a whole number of records,
     counted on the **decompressed** bytes: shards are gzip-framed by
     default, so test `gzip -dc <shard> | wc -c` modulo 32, not the file size.

   *What to check yourself, after the merge:*
   - `--merge` exit 0 (this includes its own `--verify`) and
     `verify.py --expect-kw` (item 5).
   - The sha against the expected one, when there is one.
   - Optionally, a second merge from the same shards in a fresh directory,
     which must give the same sha. At 560 T that is another 18 h 42 m, so it
     is a decision, not routine overhead.
   - The per-prefix yield report for the record:
     `solve.py --branch-yield-report <solutions.bin>`, or the C form
     `solve --yield-report` reading the enumeration log on stdin.

   No single shipped command runs this list; each item runs on its own with
   `solve`, `verify.py` and coreutils. None of it catches a bug that the C and
   Python checkers share, or a corrupted record that still satisfies C1–C5. An
   independent re-derivation on different hardware is the strongest defence
   against those.
6. **Keep `solutions.bin`, `solutions.sha256`, all side-metadata, all shards,
   all `.dfs_state` files and the locked binary together in a preserved
   copy.** Size it from your own campaign, not from a fixed figure. Measure it
   with `du` before you copy: shards and the merged file are gzip-framed by
   default and take less than their raw size. For scale, the 560 T canonical's
   raw output is 336,808,703,936 bytes (10,525,271,997 records × 32), and its
   43,876,464,466 pre-merge shard records are 1,404,046,862,912 bytes raw,
   about 1.74 TB together before checkpoints and metadata.
7. **Write up the campaign** afterwards: what went wrong, what surprised you,
   and how the resources and wall time compared with the estimate.

## 13. Honest uncertainties

This guide reflects the project's empirical experience, but a few
things are still open:

- Per-thread rate at very large budgets (≥100 T per cell on a
  single first-level branch) is extrapolated from the 100T pilot,
  not directly observed.
- The ~50% per-thread efficiency drop past 64 threads was observed in
  the pre-fix `--sub-branch` scaling runs and traced to one shared
  atomic counter, which was then sharded per CCD and not re-measured
  (§2a). Whether a current binary still shows it, and how much of any
  residue is NUMA versus hash-table contention, is unmeasured.
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
- 100T canonical (first run 2026-04-19/20, ~17h
  wall; since re-derived byte-identically several times, by
  full enumeration and by a 62-branch `--branch` loop plus `--merge` —
  [CANONICAL_HASHES.md](CANONICAL_HASHES.md); "single observed run"
  until 2026-11-04, CX-36N-A, Codex F12-011#18; 158,364 sub-branches at depth=3, full solutions.bin
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

2. **Hash table sizing.** The per-thread `sol_table` uses heuristic
   sizing tuned for 100T-class workloads. At 5.6 PT scale, expected
   solution counts could push toward 5–10 B entries; audit its sizing
   before scaling. There is no global merge-time hash table: the
   in-memory merge reads every record into one buffer, heapsorts it and
   drops adjacent duplicates (§9a), and the external merge sorts chunks
   and merges them. ⚠ [2026-11-04, CX-36N-A (Codex F12-011#29): this item
   also named a "global merge-time hash table" to audit.]

3. **Heap-corruption family at long thread runtimes.** A
   heap-corruption pattern observed at 128 threads × 75+ minutes
   was mitigated (fork-merge isolation, dead-free patch) and then
   root-caused: an AddressSanitizer run on 2026-05-05 found a
   stack-array overflow in the post-enumeration aggregation
   (`all_top[64 * TOP_N]` written by up to 128 threads), fixed by
   sizing it for the 256-thread maximum (HISTORY.md, May 4–5 2026).
   Both current `all_top` arrays hold 256 × TOP_N. No crash at
   longer runtimes is ruled out, but this one has a known cause and
   fix. See §13a #9. ⚠ [2026-11-04, CX-36N-A (Codex F12-011#17): this
   item said the pattern was "mitigated but not eliminated".]

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

5. **Merge memory at PT scale.** ⚠ **[CORRECTED 2026-09-03 — this item
   said the disk-based merge path would need validation "if/when it
   lands"; it shipped before this guide was written and it produced the
   560T canonical (§9b). Sibling of the §9b inversion, which the
   2026-09-01 correction did not reach here.]** What is measured: two
   external merges. At 560 T, 43.88 B pre-merge shard records in 65,281
   non-empty shards down to 10.525 B unique, on a 32 GB VM, 18 h 42 m.
   At 100 T, 13,832,832,979 input records down to 3,432,399,297 unique
   (the tracked 100T enumeration log under `runs/`, its "External merge
   complete" line). ⚠ [2026-11-04, CX-36N-A (Codex
   F12-011#19): this said one external merge and no measured point
   between ~750 M and 10.525 B records.] What is not: anything beyond
   the 560 T merge — chunk counts an order of magnitude past the 560T merge's,
   `ulimit -n` at that count, and scratch sized at ~1.5× a multi-TB
   input are extrapolations from a single measured point.

6. **Long-running fragmentation and OS instability.** Multi-week
   continuous campaigns surface OS-level issues (kernel memory
   fragmentation, driver bugs, transient hardware errors) at rates
   not seen in shorter runs. Reproducible recovery is essential
   and has been exercised beyond the 100T pilot: the 560 T
   re-run resumed through 7 real evictions and reproduced the
   canonical byte for byte ([CANONICAL_HASHES.md](CANONICAL_HASHES.md)).
   Multi-week runs remain unobserved. ⚠ [2026-11-04, CX-36N-A (Codex
   F12-011#18): this said "not yet validated past the 100T-pilot
   eviction-recovery pattern".]

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
3. **Set `SOLVE_PER_SUB_BRANCH_LIMIT` explicitly — but not for the
   reason this item used to give.** ⚠ **[CORRECTED 2026-09-03 —
   sibling of the §3a retraction, which the 2026-09-01 sweep did not
   reach.]** It read: *"solve.c's auto-compute of per-sub-branch budget
   uses divisor 3030 (depth-2 cell count). At depth=3 with ~2,824 cells
   per first-level branch, this means setting `SOLVE_NODE_LIMIT=10T`
   actually allocates ~9.32 T per branch (7% under intent)"*, and sent
   the reader to a §3 "recipe table" that has been retracted. The
   `/3030` sites in `solve.c` set only the resume-skip threshold; the
   enforced per-cell budget is `node_limit / 158,364` for a full depth-3 enumeration and `node_limit /` the branch's own cell count under `--branch` (2026-11-04, CX-36N-A, Codex F12-011#12), and the published 560T value is exactly that quotient —
   see §3a. The advice stands on a different footing: copy the value
   **verbatim** from the recipe table in
   [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Reproducibility
   parameters", so that a future change to the auto-compute cannot move
   a sha and so that nobody re-derives it from a formula — the incident
   that rule cites was exactly such a re-derivation.
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
8. **Per-record cd/distance-sum recompute should be fast.** An
   estimated (not benchmarked) ~30 seconds on one core for a
   1B-record canonical to compute cd values from scratch, from
   the ~100-cycle estimate in §11a; measure it before you rely on
   it. ⚠ [2026-11-04, CX-36N-A (Codex F12-011#22): this item, under
   "tips from observed campaigns", stated the estimate as a
   measurement.] Don't bother adding pre-computed invariants to
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

   ⚠ **[2026-11-04, CX-36N-A (Codex F12-011#17).]** The rest of this item
   is superseded. The AddressSanitizer investigation it calls deferred ran
   on 2026-05-05 and found the cause: `all_top[64 * TOP_N]`, sized for 64
   threads, overflowed at 128 in the post-enumeration aggregation and
   corrupted the stack around it. It was fixed by sizing the array for the
   256-thread maximum (HISTORY.md, May 4–5 2026); both current `all_top`
   arrays are 256 × TOP_N. Do not expect this crash as a standing residual.
   Running `solve --merge` from a fresh process when `solutions.bin` is
   missing remains a sound recovery. The text below is the pre-fix account.

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
| Cost | [cost redacted] | not recorded here; the wall overruns above make the planned range unreliable |

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
