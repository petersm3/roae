# Large-scale canonical campaigns: methodology and reproducibility

> **WORK IN PROGRESS** — published 2026-05-31 ahead of the 560T canonical
> campaign (#49). This document will eventually **replace**
> [LARGE_SCALE_CAMPAIGNS.md](LARGE_SCALE_CAMPAIGNS.md) as the canonical
> public reference for how this project's enumeration campaigns are
> structured and reproduced. During the transition, both documents
> coexist; the older one remains authoritative for operational topics
> (sizing, cost estimation, branch-distribution patterns, the worked
> 56 × 10 T example) until the relevant content is ported here.
>
> **Section 7 (worked example) is intentionally a TBD skeleton** until the
> 560T campaign completes — the conceptual sections (1–6, 8) are intended
> to be readable and useful as-is; the worked example will be filled in
> once the campaign produces its actual sha, record count, wall time,
> cost, and eviction count. The PORT-TODO checklist at the end of this
> document tracks the remaining cleanup needed before
> `LARGE_SCALE_CAMPAIGNS.md` is retired.

---

## TL;DR / who this document is for

This document explains the **methodology** used to produce the ROAE King Wen
canonical enumerations — and, just as importantly, the **methodology used to
extend** an existing canonical to a deeper search budget without rerunning the
work that produced the previous canonical.

It is aimed at three audiences:

1. **A third party who wants to reproduce one of our canonicals from scratch**
   on independent hardware, and confirm byte-identical output.
2. **A third party who wants to extend our deepest canonical to a deeper
   budget** without our cooperation, given only the artifacts we publish.
3. **Future maintainers of this project** who need to understand why the
   campaign pipeline looks the way it does — what's structural, what's
   operational, what's correctness-load-bearing, and what's a hygiene choice.

The conceptual core is **prefix-determinism per cell** — the property that
makes "enumerate to budget B, archive, later resume to budget B′ > B" produce
byte-identical results to "enumerate to budget B′ in one shot."  Everything
else is operationally derivable from that.

For the formal definition of the constraints C1-C5 and the canonical record
format, see [SOLVE.md](SOLVE.md) and
[SPECIFICATION.md](SPECIFICATION.md). For the partition-invariance theorem
(the work-partition choice is correctness-neutral), see
[PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md). For the reproducibility-
parameter registry (canonical shas, record counts, exact env vars), see
[CANONICAL_HASHES.md](CANONICAL_HASHES.md). For specific past campaigns'
operational details, see [HISTORY.md](HISTORY.md). (Note: the historical
`LARGE_SCALE_CAMPAIGNS.md` is being retired and merged into this document
as of the 560 T campaign port — see the boxed note at the top.)

---

## 1. What "canonical" means here

A **canonical artifact** is a file `solutions.bin` produced by the C
enumerator at a specific search budget that:

1. **Contains every King Wen ordering satisfying constraints C1–C5** that the
   DFS reaches within the per-cell node budget;
2. **Is sorted** by canonical record key (so byte-equality across runs is
   meaningful);
3. **Is deduplicated** (each record appears once);
4. **Is reproducible byte-identically** on independent hardware in the same
   region/microcode class, given the same source commit and search budget;
5. **Has a published sha256** in [CANONICAL_HASHES.md](CANONICAL_HASHES.md)
   that any third party can verify by recomputing it on their own host.

The sha256 is the reproducibility anchor — not the bytes themselves. If you
produce a mismatching sha for the same parameters, the project treats that as
a bug to investigate, not as a new finding. See "Sha stability vs host
environment" at the end of this document for the empirically-documented
limits of that.

### Why budget matters

The full canonical solution space at the lowest credible "exhaust everything"
budget is ≥4,900 T nodes — beyond practical compute. Every realistic
canonical is therefore **budget-limited**: each of the 158,364 depth-3 cells
is given the same per-cell node budget, and the DFS for that cell stops when
the budget is reached. The set of records emitted for a cell depends on which
parts of its search tree fit in that budget.

This makes the canonical sha **a function of (source code, search budget)** —
two campaigns at the same budget on the same source should produce the same
sha; campaigns at different budgets should not (the larger campaign will
include a superset of records up to the smaller campaign's per-cell boundary,
plus more records that the smaller didn't have budget to find).

---

## 2. Per-cell uniform budget

The canonical convention is **uniform per-cell budget** — every cell gets
exactly the same number of nodes. The campaign's "scale" is then a single
scalar — the total budget across all cells — even though the work is
partitioned 158,364 ways:

- 1 T canonical = 6.3 M nodes per cell × 158,364 cells
- 11.2 T canonical = 70.7 M nodes per cell × 158,364 cells
- 100 T canonical = 631 M nodes per cell × 158,364 cells
- 560 T canonical = 3.5 B nodes per cell × 158,364 cells
- 1120 T canonical = 7.1 B nodes per cell × 158,364 cells

The choice of "uniform per-cell" over "heterogeneous, asymmetric" budgets is
deliberate:

- **Comparable across milestones.** A doubling of scale is a doubling of
  per-cell budget — clean for cross-milestone analysis.
- **Audit-simple.** A single scalar describes the campaign; reviewers don't
  need a per-cell budget table to understand what was enumerated.
- **Composable with extension** (next section). Doubling a uniform budget is
  the natural "extend to higher scale" operation.

Heterogeneous budgets are sometimes used for *exploration* (e.g., spending
more compute on a cell suspected of containing a particular pattern), but
those runs are not canonical and are not entered into `CANONICAL_HASHES.md`.

---

## 3. Milestone-based extension (the core idea)

A canonical produced at budget *B* per cell **enables a canonical at any
budget *B′* > B without redoing the original work**. This is the most
important property of the campaign methodology.

### Why this works: prefix-determinism per cell

Each of the 158,364 cells runs a depth-first search that visits its nodes in
a deterministic order — the order is a function of the source code, not of
host environment, not of wall-clock time, not of thread scheduling (the
iterative-DFS + per-cell-budget design guarantees this within the limits
documented in section 7). A "budget of *B* nodes" means "visit the first *B*
nodes of that walk, in canonical DFS order, and emit any that satisfy
C1-C5."

Therefore, for any single cell, the records emitted at budget *B* are an
**initial subset** of the records that would be emitted at any budget
*B′* > B — same records, same order, same byte-for-byte content, plus
additional records found in the (*B*, *B′*] range.

This makes the union-over-cells canonical at budget *B′* literally
extensible from the canonical at budget *B*: each cell's per-cell shard at
budget *B* is a prefix of its shard at budget *B′*. The DFS at budget *B′*
can be **resumed** from the per-cell state saved at the budget-*B*
boundary, walk forward to the *B′* boundary, and emit only the additional
records found.

### Concrete extension recipe (560T → 1120T or any higher scale)

Given the cold-archive directory `solver-data:/canonical-archive/<source-
campaign>/` produced by the source campaign (which contains
`shards.tar.gz`, `dfs_state.tar.gz`, `budget.tar.gz`, `solutions.bin.gz`,
provenance sidecars, and an `EXTENSION_RECIPE.txt`):

1. **Provision a new VM** (D128als_v7 Spot in westus3, same SKU class used
   for the source campaign) with a **new Premium SSD** sized for the larger
   shard set — roughly **2× the source archive's `shards.tar.gz` uncompressed
   size** plus a working margin. Mount both disks by UUID.
2. **Gunzip the three preservation tarballs** from the cold archive onto
   the new Premium's run directory, preserving the per-cell file layout:
   ```bash
   cd /mnt/premium/run_<new_scale>
   tar -xzf /mnt/solver-data/canonical-archive/<source-campaign>/shards.tar.gz
   tar -xzf /mnt/solver-data/canonical-archive/<source-campaign>/dfs_state.tar.gz
   tar -xzf /mnt/solver-data/canonical-archive/<source-campaign>/budget.tar.gz
   ```
   These three sets are what makes extension possible:
   - `sub_<cell>.bin` — the records found within the source budget
   - `<cell>.dfs_state` — the DFS state at the source-budget boundary
   - `<cell>.budget` — the source per-cell budget value (Outlier #5 protection)
3. **Build the C enumerator from the source campaign's git ref** (recorded in
   the archive's `build.sha` / provenance sidecars) — or a sha-equivalent
   descendant verifiable via `./solve --validate-canonical <source-sha> <source-scale>`.
4. **Launch the extension enum** with:
   - `SOLVE_NODE_LIMIT=<new_scale_total_nodes>`
   - `SOLVE_PER_SUB_BRANCH_LIMIT=<new_per_cell_budget>` (strictly greater
     than the source's `.budget` sidecar value)
   - `SOLVE_THREADS=128 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_SKIP_AUTOMERGE=1`
   - `SOLVE_SKIP_IOPS_CHECK=1` (see the note below on the IOPS pre-check
     behavior — this flag bypasses a known issue at eviction-resume and on
     extension launch.)

   The enumerator picks up each cell from its `.dfs_state` checkpoint and
   walks forward to the new per-cell budget, appending only the additional
   records to each `sub_<cell>.bin`.

> **Note on `SOLVE_SKIP_IOPS_CHECK=1` and the I/O pre-check behavior.**
>
> The C enumerator includes an I/O performance pre-check at startup (tasks
> #107 and #115 in the project history) that aims to refuse-fast on a disk
> that's too slow for canonical work — historically, an accidentally-attached
> HDD-class disk where fsync latency would dominate enum wall. The check
> samples concurrent fsync throughput and projects what fraction of the
> estimated enum wall would be spent fsync-waiting; if that fraction exceeds
> 25%, it refuses to start with exit 31.
>
> Empirically, the probe is **noisy on a cold-cache VM** — that is, a VM that
> has just been brought up via `az vm start` (eviction-resume) or is being
> used for the first time (extension launch). The 100-iteration concurrent
> probe runs before any disk warmup, and on a freshly-attached Premium SSD
> can measure 200–300 fsync/sec where the warm disk would steady-state at
> 2000+ fsync/sec. That triggers a false refuse-to-start.
>
> This was first encountered during the 2026-05-31 dress rehearsal:
> the eviction-recovery code path provisioned a new VM, attached the
> existing Premium with the in-flight shards, and re-launched the enum to
> resume from `.dfs_state` checkpoints. The IOPS gate fired with
> "223 fsync/sec, projected 41% fsync-wall-fraction" and refused. The same
> Premium had passed the gate at first launch the same evening — only the
> probe changed (cold caches, no recent activity).
>
> The mitigation in the campaign supervisor is to set
> `SOLVE_SKIP_IOPS_CHECK=1` in every (re)launch's env. Rationale: the
> first-launch gate at campaign initialization is authoritative; the disk
> doesn't change between resumes; the probe is the unreliable component.
> This is **a bypass, not a fix.** The underlying probe design issue
> (cold-cache sensitivity on `az vm start`-type VM lifecycle events) is a
> known item for post-campaign hardening — likely either a longer warmup
> before the probe runs, or a check that detects "fresh-boot VM" and skips
> the gate automatically rather than requiring an env var.
>
> For an extension on a freshly-provisioned VM, the same condition applies:
> the disk is not pathological, but the probe is too quick to know that.
> Pass `SOLVE_SKIP_IOPS_CHECK=1` and proceed. If you are operating on a
> known-good Premium SSD that you provisioned yourself, you have already
> done the work the gate exists to do.
5. **Merge** with `solve --merge` (same pattern as the source campaign) to
   produce the new `solutions.bin` at the higher scale.
6. **Verify** with `./solve --verify` (C verifier) AND `python verify.py`
   (independent Python re-verifier) on the new `solutions.bin`. Both must
   PASS to declare the new canonical valid.
7. **Record** the new canonical's sha256 in
   [CANONICAL_HASHES.md](CANONICAL_HASHES.md). The new canonical has no prior
   anchor (it's a new scale measurement), so the sha is recorded, not gated.

The new canonical contains every record from the source canonical
**byte-identically as a prefix per cell**, plus the additional records
found in the budget-extension range.

### Verification that extension was byte-faithful

To prove that the extended canonical is correctly an extension of the source
(rather than a redo from scratch that happened to land at a similar sha), the
source `solutions.bin` records must appear as an ordered subset of the new
`solutions.bin` records:

```bash
# Diff: every record in the source must appear in the new canonical.
sort -u source_solutions.bin > /tmp/src.sorted
sort -u new_solutions.bin > /tmp/new.sorted
diff <(sort /tmp/src.sorted) <(comm -12 /tmp/src.sorted /tmp/new.sorted)
# (empty diff = every source record is also in the new canonical)
```

This is a **partition-invariance witness** at a different scale — see
[PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md).

---

## 4. What must be preserved for extension

For extension to work, the source campaign's cold archive must contain, in
addition to the merged `solutions.bin`:

| File | Purpose |
|---|---|
| `shards.tar.gz` | Per-cell `sub_<cell>.bin` shard files — the records each cell found within the source budget. Without these, extension cannot reuse the source's prefix work. |
| `dfs_state.tar.gz` | Per-cell DFS resume state at the source-budget boundary. Without these, the resume would have to re-walk each cell's search from scratch — defeating the point of extension. |
| `budget.tar.gz` | Per-cell `.budget` sidecars recording the source per-cell budget. Extension reads these to confirm the new budget is strictly larger. |
| `solutions.bin.gz` (or `.sha256`) | The merged canonical artifact. Used by the verification step that confirms extension was byte-faithful. |
| `solutions.provenance.json` + `canonical-host-fingerprint.json` + `build.sha` | Build provenance — what source ref + compiler + host configuration produced the archived bytes. Needed to identify what to rebuild on the extension VM. |
| `EXTENSION_RECIPE.txt` | The operational version of section 3 of this doc, written by the archive supervisor. Pin to the archive bytes; not maintained over time. |

Crucially: the live "working" Premium SSD from the source campaign is
**redundant with the cold archive** for extension purposes. Either one works.
The cold archive is the durable, infrastructure-failure-resistant path; the
live Premium is a convenience (faster to re-attach + run than to gunzip from
cold archive).

### 4.1 Post-merge artifact preservation: NOT automatic (SPOF caveat)

A subtle, costly trap, surfaced during the 560 T campaign 2026-06-08:

**The merge supervisor copies LOGS, sidecars, and the sha256 sidecar to
solver-data — but does NOT copy `solutions.bin`, the per-cell `.bin` shards,
or the per-cell `.dfs_state` checkpoints.** After the supervisor's
`teardown_vm` step runs, those artifacts exist only on the detached
Premium SSD that hosted the merge. The Premium SSD is by standing pattern
the project's "transient external-merge scratch" — meaning, if anyone
operates on standing-pattern muscle memory and deletes it, the canonical
is gone.

The fix is two-pronged:

1. **Every canonical campaign at ≥ 11.2 T must include an explicit copy
   step** of `solutions.bin` + all shards + all `.dfs_state` checkpoints
   from Premium → solver-data **before** `teardown_vm` fires. The robust
   place for this is inside `phase_b_merge_supervise.sh` (or its
   replacement) — bake it in once and every future campaign inherits it.
2. **Pre-launch disk-space gate** for solver-data: it must be sized to
   hold uncompressed working copy + gzipped warm-tier mirror BEFORE
   launch, not after merge completes. The 560 T campaign's solver-data
   was 2 TB (≈ 800 GB free) at launch, insufficient for the 560 T uncompressed
   plus mirror (≈ 2.4 TB). It was resized 2 TB → 4 TB online 2026-06-08
   to fit, but the right policy is to size it before launch.

Capacity planning table (rough, derived from the 560 T artifact sizes,
power-law-projected for 1120 T):

| Scale | `solutions.bin` | Shards (.bin) | Checkpoints (.dfs_state) | Uncompressed total | Cold mirror (gzip-9 of binary subset) | Required solver-data free |
|---|---|---|---|---|---|---|
| 11.2 T | ~5 GB | ~10 GB | ~50 GB | ~65 GB | + ~30 GB | ~95 GB |
| 100 T | ~115 GB | ~150 GB | ~300 GB | ~565 GB | + ~250 GB | ~815 GB |
| 560 T | ~337 GB | ~870 GB | ~400 GB | ~1.6 TB | + ~800 GB | ~2.4 TB |
| 1120 T (projected) | ~620 GB | ~1.6 TB | ~750 GB | ~3.0 TB | + ~1.5 TB | ~4.5 TB |

This finding is non-obvious from the supervisor's published doc-comments
(which say "solutions.provenance.json copied to solver-data BEFORE teardown",
implying the data file is also copied — it isn't). Future maintainers should
audit any merge supervisor for explicit `cp solutions.bin → solver-data`
before the `teardown_vm` call.

---

## 5. Operations choices are orthogonal to correctness

Many seemingly significant operational choices are **correctness-neutral**
under the partition-invariance theorem
([PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)):

| Choice | Correctness impact |
|---|---|
| Single-VM enum vs partitioned across N VMs | None — merge produces identical bytes either way |
| Spot vs Regular VM | None for enum (eviction is recoverable via DFS-state checkpoints); merge needs Regular because the external sort isn't checkpointable |
| Westus2 vs westus3 (same Microsoft-Datacenter microcode class) | None |
| One Premium SSD for everything vs separate scratch | None — operational choice for IOPS isolation |
| Thread count (128 vs 64 vs 16) | None for enum (per-cell budget pins the work) |
| Reboot mid-campaign | None — checkpoint resume is byte-clean |

These are **operations choices** to optimize cost, wall time, and blast
radius. They do not change the canonical bytes.

The choices that **do** matter for correctness:

- **Source git ref** of `solve.c` at build time (the only "source" the
  canonical depends on)
- **Per-cell node budget** (the scale-defining parameter)
- **Host environment factors at very small scales** — see next section

---

## 6. Sha stability vs host-environment fragility

Empirical finding from the project: **canonical sha stability is a function
of budget-vs-tree-size ratio**.

At very small budgets (e.g., 1 T = 6.3 M nodes per cell), the per-cell tree
is so big that the budget cuts off in the middle of a sub-tree, and the exact
set of records that "fit" before the cutoff is sensitive to subtle host
environment factors (gcc minor-version code generation, glibc allocator
behavior, kernel scheduler quanta, CPU microcode patch level). At 1 T scale,
moving from one Azure host to another in the same SKU class can produce a
*different* sha for the same source code.

At canonical scales used by the project (11.2 T and above), the per-cell
budget is large enough that the budget-cutoff happens at a deeper, more
deterministic point in the search tree, and the host-environment sensitivity
drops away. Empirically:

- **1 T canonical: host-fragile.** Two different Spot D128 hosts in the same
  westus3 SKU pool can produce different 1 T shas. Documented at length in
  [HISTORY.md](HISTORY.md).
- **11.2 T canonical: host-stable across our current host class.** Seven
  independent witnesses (Build A May 14, Build B May 14, cold-storage
  re-checksum May 15, v3 sha-equivalence May 24, c72eada+#108 witness May
  27, t62 dress May 28, and the Tier-1 post-hardening dress May 31) all
  produce the same sha on D128als_v7 Spot westus3. See the 11.2T row in
  [CANONICAL_HASHES.md](CANONICAL_HASHES.md).
- **100 T canonical: host-stable.** Re-validated May 30 on the current
  main lineage; reproduces the historical sha byte-identically.
- **560 T canonical: established 2026-06-08, sha `9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`.** 10,525,271,997 unique canonical solutions, 336,808,703,904 bytes. No prior anchor; the first 560 T run defined the sha. Cross-host stability is an empirically open question until a second 560 T witness is run (cost-prohibitive at single-campaign scale; would require ≈ $150 + ~9 days).

For extension specifically: **extension byte-faithfulness depends on the
extension host being in the same sha-stability class as the source host**.
Within "D128als_v7 Spot westus3 with current Azure microcode" (as of
2026-05-31), 11.2 T+ scales are sha-stable; extension works byte-identically.
Across host classes (e.g., x86 vs ARM Cobalt), sha-stability has been
demonstrated transitively via independent re-verification, not byte-identical
direct reproduction (see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) "ARM
Cobalt witness").

What this means for a third-party reproducer:

- Reproducing a canonical sha on **the same Azure SKU class in the same
  region** is the strongest expectation — should be byte-identical at 11.2 T
  and above.
- Reproducing a canonical sha on **a different cloud provider or
  on-premises** may produce a different sha at the same record-set; the
  appropriate check then is structural verification (`solve --verify` +
  `verify.py`), not byte-identical sha equality.

---

## 7. Worked example — the 560 T canonical campaign (2026-06)

Completed 2026-06-08; this section now records actuals. The campaign launched 2026-06-01 00:03 UTC; enum completed 2026-06-08 03:34 UTC after 7.15 days of wall time; merge completed 2026-06-08 22:24 UTC after 18 h 42 m; the canonical sha `9a968fa2…` was established as the new deepest published canonical.

| Field | Value |
|---|---|
| Campaign | #49 — 560 T full-depth-3 canonical |
| Source commit | git `2b01b15` (current main lineage) |
| Compute SKU (enum) | D128als_v7 Spot in westus3 (AMD EPYC 9V74 / Bergamo Zen 4c) |
| Compute SKU (merge) | D16als_v7 Standard in westus3 |
| Per-cell budget | 3,536,157,207 nodes (= 560 T / 158,364 cells) |
| Total budget | 560,000,000,000,000 nodes |
| Launch UTC | 2026-06-01 00:03 UTC (= 2026-05-31 17:03 PT) |
| **Final sha256** | **`9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`** |
| Records | **10,525,271,997** unique canonical solutions |
| Bytes | **336,808,703,904** (= records × 32) |
| Pre-dedup raw records | **43,876,464,466** (4.17× dedup ratio) |
| Final shard count | **65,281** cells with non-empty shards (41.2 % yield) |
| Cells with zero solutions | 93,083 (58.8 %) — fully scanned, budget exhausted, no records emitted |
| `.dfs_state` checkpoint count | 158,364 (100 % of cells scanned) |
| Enum wall | **171.5 h** (= 7.15 days, including all eviction-recovery defer windows) |
| Merge wall | **18 h 42 m** (single external chunked-sort pass, 250+ sort chunks) |
| `solve --verify` | PASS — all 10,525,271,997 records satisfy C1-C5 + sorted + no duplicates, King Wen sequence found |
| `verify.py --jobs 16` | (in flight on the merge VM at time of writing; PASS expected; will be re-run on D64 Spot post-warm-tier-copy) |
| Total realized cost | (compiled at campaign close-out; projected $150–185 at 2 evictions/day, hard cap $200 — actual will be reported in HISTORY.md) |
| Eviction count handled | **5** — all M-F, all in a 37-min window 07:12-07:49 PT (Mon 07:12, Tue 07:28, Wed 07:25, Thu 07:42, Fri 07:49). **0 weekend evictions** (Sat 2026-06-06 + Sun 2026-06-07) — strong empirical support for M-F-only scheduled reclamation in the westus3 D128als_v7 Spot pool. |
| Throttled-host re-provisions | 0 (no host returned throttled state) |
| Cold archive | `solver-data:/canonical-archive/20260608_560T_9a968fa2/` (gzip warm mirror) + `roaecanonical2026/canonical-archive/20260608_560T_9a968fa2/` (cold blob); uncompressed working copy at `solver-data:/run_560T/` (solutions.bin + 65,281 shards + 158,364 `.dfs_state` checkpoints) |
| Post-merge SPOF discovered + remediated | Per §4.1: the merge supervisor does NOT auto-copy solutions.bin to solver-data; explicit copy was added mid-campaign before teardown. solver-data resized 2 TB → 4 TB online to fit uncompressed + gzip-mirror artifacts. |

### Operations design choices made for this campaign

- **Launch at 17:01 PT (1 minute past UTC June 1)** — earliest clean
  June-billing UTC time + 12 hours of off-hours Spot runway before any M-F
  daytime defer risk.
- **Single-VM enum on a D128 Spot, separate Standard D16 for merge.**
  Eviction-resilient (DFS checkpoints), uncheckpointable phase isolated to a
  small Standard.
- **75-min wait + M-F daytime defer policy.** Off-hours evictions retry
  quickly; M-F daytime evictions defer to 18:01 PT same-day to avoid
  disrupting operator availability windows.
- **Throttle probe on every new VM, including post-eviction `az vm start`
  AND every main-loop poll cycle.** Spot D128 pool occasionally hands back
  thermally-throttled hosts at ~600 MHz vs the expected 2596 MHz base /
  3700 MHz boost. The campaign supervisor runs `solve --cpu-freq <threshold>`
  in three places: (a) after the initial `az vm create` provision; (b) after
  every post-eviction `az vm start` (which may relocate the VM identity to a
  different physical host); (c) inline in the main poll loop every 3 minutes
  against the live VM. The first two probes treat a single THROTTLED reading
  as a vacated host (`az vm deallocate`, re-enter the wait-relaunch-window
  policy, retry — up to 5 attempts before ABORT). The mid-run probe is a
  sustained-throttling gate: `THROTTLE_THRESHOLD` consecutive THROTTLED
  readings (default 20 = ~60 min) before the supervisor self-deallocates the
  VM (main loop then sees a normal eviction and routes through the same
  wait-relaunch-window). Together these three probes catch (i) bad initial
  hosts, (ii) post-eviction relocations to bad hosts, and (iii) hosts that
  pass the provisioning probe but degrade hours later. Probe cost is
  negligible (a 50ms `/proc/cpuinfo` read per cycle); prevents the long-tail
  scenario where a thermally-throttled host runs the enum at ~5× normal wall.
- **Observed eviction pattern: D128 Spot reclaimed daily around 07:15–07:40 PT.**
  Live observation from the in-flight 2026-06 560T campaign. Across the
  first three days every Spot eviction landed within a narrow 27-minute
  window:

  | Day | Eviction time (UTC) | Eviction time (PT) | cells with solutions at eviction |
  |---|---|---|---|
  | Mon 2026-06-01 | 14:12:20 | 07:12:20 PT | 17,433 |
  | Tue 2026-06-02 | 14:39:00 | 07:39:00 PT | 17,694 |
  | Wed 2026-06-03 | 14:33:42 | 07:33:42 PT | 23,553 |
  | Thu 2026-06-04 | 14:42:00 | 07:42:00 PT | 32,139 |
  | Fri 2026-06-05 | 14:49:32 | 07:49:32 PT | 40,396 |
  | Sat 2026-06-06 | (none) | (none) | — |
  | Sun 2026-06-07 | (none) | (none) | — |

  Five datapoints across M-F all within a **37-minute window (07:12–07:49 PT)** —
  100 % hit rate across the campaign's M-F sequence. Statistically
  improbable as coincidence. **Both weekend days produced zero evictions**
  (~54 hours of continuous Spot runway through Sat 00:00 PT → Sun 23:00 PT),
  strong empirical support for the M-F-only scheduled-reclamation hypothesis
  in the westus3 D128als_v7 Spot pool.
  Still can't fully distinguish "the westus3 D128als_v7 Spot pool has
  scheduled reclamation around 07:30 PT" from "this customer of the
  same pool happens to be aggressively renewing in that window."
  But the timing has been tight enough to be operationally
  actionable: the wait-relaunch-window's M-F daytime defer policy
  (defer to 18:01 PT same day) handles these cleanly without operator
  intervention. Wall-time cost per such eviction is ~10h 22min of defer
  (off-hours waits would be 75 min flat instead). Spend impact is
  negligible: the deallocated D128 doesn't bill; the Premium SSD baseline
  continues at $0.18/h.

  *Possible interpretation note* for operators planning future campaigns:
  if the pattern persists, launching a campaign just **after** the
  07:30 PT eviction window (say 08:00 PT) could give nearly 24 hours
  of clean runway before the first eviction; launching just **before**
  (e.g. 06:30 PT) almost guarantees an immediate first eviction. The
  current 560T campaign launched at 17:01 PT Sun, which gave ~14 hours
  of clean runway before the Mon 07:12 PT eviction.

- **CPU-frequency warmup is normal; expect a 3-6h ramp after `az vm start`.**
  Empirical observation from the 2026-06 560T campaign across four
  post-`az vm start` host instantiations (initial provision + 3
  eviction-recoveries): on a fresh post-`az vm start` host, the
  `solve --cpu-freq` probe returns min ≈ 2596 MHz (the EPYC 9V74 base
  clock = 2.6 GHz), avg ≈ 2620–2690 MHz, max ≈ 4540 MHz (a single momentary
  core boost). Over the following **3–10 hours of sustained load**, both
  min and avg climb to **3250–3550 MHz** as Linux DVFS / cpufreq governor
  decisions adapt, AMD Precision Boost grants sustained elevated clocks
  across all 128 cores once the workload pattern is observed, and thermal
  envelopes stabilize. Effective throughput tracks this: ~1,300 M nodes/sec
  at base clock, ~1,400–1,470 M nodes/sec at the elevated steady-state.
  **Implication**: do not treat a "low" cpu-freq reading immediately after
  `az vm start` as a problem — it's the host's cold-cache cold-thermal-
  cold-governor state. The supervisor's `--cpu-freq 2400` HEALTHY threshold
  is below the base clock by design, so freshly-started healthy hosts pass
  cleanly. The warmup is what's worth observing across the next several
  hours of brief-status polling.
- **Live-tunable wait + throttle policy via config file.** The four knobs —
  `DEFER_START_HR`, `DEFER_END_HR`, `OFFHOURS_WAIT_SEC` (the wait policy)
  and `THROTTLE_THRESHOLD` (the mid-run probe sensitivity) — live in a
  config file that the supervisor re-reads on every `wait_relaunch_window`
  call AND every main-loop cycle. The operator can edit the file mid-run
  to shift the daytime-defer boundary (e.g. 18:00 → 19:00 PT if a particular
  hour proves to be a high-eviction bucket) or to tighten/loosen the
  throttle threshold, without restarting the supervisor. Important for
  multi-day campaigns where empirical eviction or throttling patterns may
  diverge from the pre-launch plan and operator intervention needs to be
  cheap.
- **Progress measurement: count `.dfs_state` files (not `.bin`).**
  The C enumerator's stdout (`enum.out`) has two number-bearing patterns
  that look like progress indicators but mislead: (a) per-thread
  `*** Sub-branch NNNNN/158364 BUDGETED ***` announcements are emitted by
  whichever thread happens to exhaust its current cell's per-cell budget,
  and post-eviction-resume the new enum process picks cells out of order
  based on which `.dfs_state` checkpoints exist — so a tail-1 of those
  announcements returns a stale-looking cell index, not the maximum;
  (b) the periodic status line's `XXXX/158364 sub-branches (NN%)` field
  is the count of cells the in-process auto-merger has folded into the
  shared shard table, which stays at 0 throughout any campaign using
  `SOLVE_SKIP_AUTOMERGE=1` (the canonical-pipeline pattern). The reliable
  progress measure is **the filesystem itself**: each scanned cell writes
  a `sub_*.dfs_state` checkpoint regardless of whether it found
  solutions, so:

  ```bash
  CELLS_SCANNED=$(find $RUN_DIR -maxdepth 1 -name 'sub_*.dfs_state' -type f | wc -l)
  ```

  is the authoritative cells-scanned count and the right "% of campaign
  complete" denominator.

  **Important nuance** (empirically established mid-run on the 2026-06
  560T campaign): the `sub_*.bin` shard-file count is **NOT** a valid
  progress measure. solve.c writes a `.bin` only for cells that find
  ≥ 1 solution; cells whose 3.5 B-node budget fully exhausts but
  finds 0 solutions (C3/C5 prunes deeply enough to rule out valid King
  Wen orderings) leave a `.dfs_state` checkpoint but no `.bin`. In the
  2026-06 560T campaign, **63.6 % of fully-scanned cells produced zero
  solutions** — so the `.bin` count is roughly **0.37× the scanned-cells
  count**. Reporting `.bin` count as "cells closed" or "cells complete"
  is misleading. The `.bin` count is the right shard inventory for
  **merge-stage planning** (how many files the merger consumes), but
  not for campaign-progress reporting.

  Use `find ... -name '...' -type f | wc -l` rather than shell glob:
  at canonical scale the glob hits `ARG_MAX` once the file count
  crosses ~ 30 K and silently fails (returns 0). The `find` invocation
  does its matching inside the find process and has no `argv` limit.
- **Cold archive includes shards + dfs_state + budget tarballs.** Cold
  archive itself is extension-ready (you do not need the live Premium to
  extend).
- **Extension recipe written into the archive directory** — see
  `EXTENSION_RECIPE.txt` in the archive.
- **`SOLVE_SKIP_IOPS_CHECK=1` on every (re)launch.** The C enumerator's I/O
  pre-check is noisy on cold-cache fresh-boot VMs (see the boxed note in
  section 3). The first-launch gate at campaign initialization is
  authoritative; subsequent eviction-resume launches bypass the gate via the
  env var. Known-bypass, not a fix — the underlying probe-design issue is a
  post-campaign hardening item.

### Close-out lessons learned (added 2026-06-10 — bake into the next extension's supervisors)

The 560T close-out cascade (warm copy → cold archive → analyze → blob upload)
took ~2 days of operator-attended babysitting because of a chain of small
failures that each required hand-correction. The next extension (1120T or
deeper) must not repeat these patterns. Each rule below ships with the
specific symptom that motivated it.

1. **Separate VMs per disk source for post-merge workloads.**
   On 2026-06-09 we ran solve --analyze + verify.py (64 workers) +
   sha256sum + gzip step 2 of the cold archive **all on a single D64 Spot
   against one Standard SSD**. Aggregate IOPS budget ~5,000 split across
   130+ concurrent readers = ~38 IOPS each. solve --analyze ran 7+ h
   instead of expected ~2 h, the Spot eviction window caught it, ~$4 of
   D64 time + ~8 h of analyze work were lost.
   **Rule:** post-merge workloads (verify.py, solve --analyze, cold-archive
   gzip+azcopy, sha256sum) each get their own VM with their own attached
   disk source. Snapshot the merged solver-data into N independent disks
   if true parallelism is needed. Within a single VM, serialize — never
   run two disk-heavy workloads concurrently against the same SSD.

2. **Use account-key SAS tokens for blob writes; user-delegation SAS does
   not have data-plane permissions on this account.**
   The 2026-06-10 first cold-archive azcopy failed with
   `AuthorizationPermissionMismatch` against 354,220 files. Root cause:
   `az storage container generate-sas --as-user` produces a user-delegation
   SAS bound to the caller's AD identity, which does not have
   `Storage Blob Data Contributor` on the `roaecanonical2026` account
   (open task #87). Account-key SAS via
   `az storage account keys list` + `az storage container generate-sas
   --account-key <key>` worked first try.
   **Rule:** all close-out azcopy scripts generate SAS via account-key,
   never via `--as-user`. Document the SAS source inline.

3. **Bash supervisor scripts must `set -o pipefail`.**
   The original cold-archive script ran
   `azcopy copy ... | tail -30` then checked `$?`. azcopy's non-zero exit
   was masked by the pipeline (tail exits 0). The script proceeded to
   touch `cold_archive.done` despite a 100%-failed upload. The fix used
   `${PIPESTATUS[0]}` to read azcopy's actual exit code; that's correct
   but easy to forget — `set -o pipefail` makes failure detection
   default.
   **Rule:** every supervisor bash script starts with
   `set -euo pipefail`. Done-marker `touch` is conditional on
   `if [ $? -eq 0 ]` of the last actual operation, never bare.

4. **Done-markers must be post-condition-checked, not just post-command-fired.**
   The cold-archive `.done` marker was touched even when the azcopy
   upload reported 0 bytes transferred and `Final Job Status: Failed`.
   The downstream watcher then fired, incorrectly indicating success.
   **Rule:** before `touch done.marker`, run a positive-verification probe
   (count files in blob = count files in staging; or list one
   representative file via `azcopy ls`). Touching the marker is the
   absolute last step after verification PASSes.

5. **Post-upload blob spot-check is mandatory.**
   On the second 560T cold-archive upload (the working one),
   `EXTENSION_RECIPE.txt` was silently skipped despite being in the
   staging dir at upload time. Cause is still unclear — possibly a race
   between the file's creation timestamp and azcopy's `--overwrite=ifSourceNewer`
   logic. A blob audit (`azcopy ls | grep -v 'shards/' | sort`)
   immediately after upload caught the omission within 60 seconds.
   **Rule:** every close-out upload script runs a blob audit at end:
   (a) count files in `<blob>/shards/` matches expected per-file-type;
   (b) listing of `<blob>/` top-level files matches expected manifest.
   Hard-fail the script if either diverges; do NOT touch the done-marker.

6. **Cold-archive's `find` pattern must enumerate ALL sub_* file types
   produced by solve.**
   The original cold-archive script's pattern was
   `\( -name 'sub_*.bin' -o -name 'sub_*.dfs_state' -o -name 'sub_*.budget' \)`.
   At canonical scale solve.c also produces `sub_*.bin.budget` and
   `sub_*.bin.provenance.json` per cell — 65,281 files each, 130,562
   total — silently excluded from the archive. The follow-up pass had to
   re-do them.
   **Rule:** the canonical cold-archive find pattern is
   `\( -name 'sub_*.bin' -o -name 'sub_*.dfs_state' -o
   -name 'sub_*.bin.budget' -o -name 'sub_*.bin.provenance.json' \)`.
   Pre-script: count files of each pattern on source, compare to expected
   total; hard-fail on mismatch.

7. **`.azcopy/plans` directory permission must be writable BEFORE the first
   `azcopy copy`.**
   On 2026-06-10 the cold-archive's first azcopy attempt failed with
   `mkdir /home/azureuser/.azcopy/plans: permission denied`. The
   `.azcopy/plans` dir was mode 000 (created by a prior session's
   `sudo`-prefixed command). The script needed
   `chmod -R 755 ~/.azcopy` to recover.
   **Rule:** any VM that will run azcopy gets a pre-flight
   `mkdir -p ~/.azcopy/plans && chmod 755 ~/.azcopy ~/.azcopy/plans`
   AND/OR `export AZCOPY_JOB_PLAN_LOCATION=/tmp/azcopy_plans` in the
   supervisor. Belt + suspenders.

8. **`solve --analyze` at canonical scale: D64 is both the floor and the
   ceiling.**
   Floor: solve --analyze allocates 31 packed bitmaps × ~1.3 GB = 40.79 GB
   RAM; doesn't fit on D16 (32 GB). Ceiling: the heavy section is §[10]
   pairwise mutual information (O(N × 2016 pairs) over the records), which
   runs at ~120-200 % CPU — i.e. mostly single-threaded with a small SIMD
   parallel fraction. More cores don't help; bitmap-pool RAM is
   N-independent so 1120T won't push memory either.
   **Rule:** size analyze VM at D64 Standard regardless of canonical
   scale (560T or 1120T). Don't waste money on D96 or D128 for analyze.
   Expect ~16-22 h wall at 10.5 B records (560T), ~24-36 h at 18 B
   records (1120T extension).

9. **Extension cost is NOT 2× the source's cost; it's incremental.**
   Initial 1120T-extension cost estimate was $690 (anchored to "2× 560T's
   $360 total"). Real estimate after working through cell-exhaustion
   dynamics is **~$390 incremental** ($90 enum + $120 merge + $80 disk +
   $100 close-out). Reason: cells that exhausted at source budget do zero
   additional work in the extension. Only cells that hit the per-cell
   budget cap continue from their `.dfs_state` checkpoints.
   **Rule:** extension cost = source compute × (fraction of cells that
   hit per-cell cap) + scaled merge + scaled disk. For 560T → 1120T,
   that fraction was empirically ~41-50 %. Document this in the
   cost-estimation section of any pre-launch operator-review doc.

10. **Extension wall time is NOT 2× either; it's incremental.**
    Initial 1120T wall estimate was 14 days enum (anchored to "2× 560T's
    7 days"). Real estimate is ~3-5 days enum (60% of source enum at most,
    since only ~50 % of cells continue past their source budget).
    **Rule:** never describe "extension to scale X" as "extension wall ≈
    source wall × (X / source budget)". The relationship is
    sublinear because of cell exhaustion at source budget.

11. **Cold archive completeness — split into two categories.**
    Original 560T cold archive shipped without `EXTENSION_RECIPE.txt`,
    full analyze log, `merge.full.log`, `verify_c.log`, or per-thread
    checkpoints. Operator audit caught it. The followup pass had to
    re-do all of them.

    **Rule — Category A (load-bearing for extension; MUST be present):**
    - `solutions.bin.gz` + `solutions.sha256` + `solutions.bin.computed.sha256`
    - `sub_*.bin.gz` (per-cell solutions) — **all 4 sub_* types as one set**
    - `sub_*.dfs_state.gz` (per-cell DFS resume state)
    - `sub_*.bin.budget.gz` (per-cell source budget)
    - `sub_*.bin.provenance.json.gz` (per-cell provenance)
    - `solutions.provenance.json`, `canonical-host-fingerprint.json`,
      `build.sha`, `shard_manifest.txt`
    - `EXTENSION_RECIPE.txt` (operational recipe per §3 — frozen at archive
      time; lives in the archive, not just the live repo)

    Without any one of the above, a fresh-VM + fresh-storage extension
    cannot resume byte-faithfully.

    **Rule — Category B (forensic / audit completeness; SHOULD be present):**
    - `merge.full.log` (merge stage trace)
    - `verify_c.log` (`solve --verify` output)
    - `verify_py_*.log` (Python verifier output)
    - `analyze_*.log` (full `solve --analyze` findings)
    - `checkpoint_t*.txt.gz` (per-thread checkpoint files from the
      enum's #108 per-thread-state code path; ~27 MB compressed at
      canonical scale; useful for reconstructing per-thread interleaving
      across eviction-recovery cycles, NOT load-bearing for extension)
    - `preserve_logs/cold_archive.log` + `preserve_logs/azcopy_logs/`
      (supervisor logs from the archive run itself, preserved before VM
      deallocate per rule 12)

    Without Category B, extension still works but forensic audit of how
    the campaign actually ran (eviction-recovery sequence, per-thread
    timing, archive-supervisor failure modes) becomes guesswork.

    A pre-archive checklist that asserts each Category A file is present
    in staging before azcopy fires is the right gate. Category B files
    can be missing without blocking, but the supervisor should log a
    WARN per missing file so it surfaces in the post-archive audit.

12. **Pre-deallocate log preservation: copy /tmp/cold_archive*.log to
    solver-data first.**
    The cold-archive VM's /tmp is tmpfs and is lost on `az vm deallocate`
    (or even on reboot). Almost lost the upload-failure forensic logs
    that caught the AuthorizationPermissionMismatch.
    **Rule:** any VM that ran a supervisor script preserves /tmp/*.log
    + /tmp/azcopy_logs to `solver-data:/canonical-archive/<archive_dir>/preserve_logs/`
    before `az vm deallocate` is issued.

13. **Analyze + cold-archive can run on separate VMs simultaneously
    (with separate disk sources) — and should.**
    On 2026-06-09 attempt 2 (after the Spot eviction): split into
    c560-d64-coldarchive (on solver-data) + c560-d64-analyze2 (on Premium
    SSD). Analyze ran ~3× faster than the contended attempt 1 because no
    I/O competition for the same disk. Cost: one extra D64 hour
    (~$2.50), saved: 4-5 h of analyze wall = ~$10 of D64 + lower
    Spot-eviction risk.
    **Rule:** the canonical post-merge pattern is **two D64 Standard
    VMs**, each with its own disk: cold-archive on solver-data,
    analyze on Premium SSD. Don't try to bundle both on one VM unless
    operator explicitly authorizes for cost reasons.

---

## 8. Reproducing a canonical from scratch (third party, no cooperation)

Given only the public artifacts (`solve.c` at a specific git ref + the
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) entry naming the expected sha + budget),
a third party can reproduce any canonical as follows:

1. Clone the source repository, checkout the git ref named in the canonical's
   row in [CANONICAL_HASHES.md](CANONICAL_HASHES.md).
2. Build with the canonical flags (`gcc -O3 -g -march=native -flto -pthread
   -fopenmp -o solve solve.c -lm`).
3. Confirm the built binary's selftest sha matches the published selftest
   anchor (`./solve --selftest` should emit `403f7202...` — see
   [DEVELOPMENT.md](DEVELOPMENT.md)).
4. Run the canonical at the scale's published per-cell budget:
   ```bash
   SOLVE_NODE_LIMIT=<published_NL> SOLVE_PER_SUB_BRANCH_LIMIT=<published_PSB> \
   SOLVE_THREADS=<your_thread_count> SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 \
     ./solve 0 <your_thread_count>
   ```
5. Merge the resulting shards: `SOLVE_MERGE_MODE=external ./solve --merge`.
6. Compute `sha256sum solutions.bin` and compare to the published sha.

On a host in the same SKU class as the original campaign (D128als_v7 Spot
westus3 for our 11.2T+ canonicals), the sha should match byte-identically.
On a different host class, structural verification (`solve --verify` +
`verify.py`) should PASS even if the sha differs — that's a confirmation
that the *enumeration is correct*, not that the bytes are identical.

---

## 9. What this document does not cover

- The mathematical content of the constraints C1–C5, the partition-
  invariance theorem proof, the King Wen sequence interpretation —
  see [SOLVE.md](SOLVE.md), [SPECIFICATION.md](SPECIFICATION.md),
  and [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md).
- Step-by-step Azure deployment (VM sizing, disk SKU choices, networking) —
  see [DEPLOYMENT.md](DEPLOYMENT.md).
- The full operational runbook for the 560 T pipeline, including supervisor
  scripts, eviction-recovery internals, and pre-flight gates — those live in
  the project's private operational repository.

---

## DRAFT TODO before porting to public

### Port-as-replacement of `LARGE_SCALE_CAMPAIGNS.md` (operator 2026-05-31)

This document REPLACES `documentation/LARGE_SCALE_CAMPAIGNS.md`; that file's
1100 lines are subsumed here during the port. Concrete merge plan:

- [ ] Port section 5 of `LARGE_SCALE_CAMPAIGNS.md` (pre-flight validation
      checklist) → fold into a new appendix or extend section 8 of this doc
      (third-party reproduction). Includes the 8-check pre-flight gate now
      in `LAUNCH_560T_CAMPAIGN.sh` as the operational version.
- [ ] Port section 6 (campaign architecture) → fold into section 5 of this
      doc (operations choices) + section 7 (worked example).
- [ ] Port section 7 (branch distribution) → fold into section 5 of this doc.
- [ ] Port section 8 (eviction recovery) → standalone subsection within
      section 5 of this doc; key content: 75-min/M-F-defer policy,
      DFS-checkpoint resume, IOPS-skip mitigation.
- [ ] Port section 9 (merge VM sizing + disk-based alternative for extreme
      scale) → fold into section 5 of this doc.
- [ ] Port section 11 (side-metadata: what to capture beyond solutions.bin)
      → strengthen section 4 of this doc (extension preservation requirements).
- [ ] Port section 12 (reproducibility checklist) → strengthen section 8 of
      this doc (third-party reproduction).
- [ ] Port section 13 (honest uncertainties) → fold into section 6 of this
      doc (sha stability vs host fragility) AND a new "uncertainties /
      what we don't know" section.
- [ ] Port section 14 (worked example: 56 × 10 T at 2 × D64 spot) → keep
      as a second worked example in section 7, alongside the 560 T entry.
- [ ] After all ports: delete `documentation/LARGE_SCALE_CAMPAIGNS.md`
      with a single redirect commit pointing readers to this doc.

### 560 T-specific TBDs

- [ ] Fill in TBD numbers from completed 560 T campaign (section 7)
- [ ] Final sha + record count + cost match what `CANONICAL_HASHES.md` ends up showing
- [ ] Verify the EXTENSION_RECIPE.txt text described in section 3 matches what the
      archive supervisor actually generates (added in commit 800a8df)

### Pre-publish review

- [ ] Confirm all cross-references to other public docs resolve
- [ ] Operator review of tone/framing for the "third party reproducer" sections
- [ ] Final pre-publish: have a third-party-style reviewer read it cold; check
      whether sections 3 + 4 + 8 are actually sufficient to extend OR reproduce
      without operator handholding
