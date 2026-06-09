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
- **560 T canonical (this campaign): TBD-on-completion.** Has no prior
  anchor; the first 560 T run defines its sha. Cross-host stability is an
  empirically open question until a second 560 T witness is run.

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

(Filled in after campaign completion.)

| Field | Value |
|---|---|
| Campaign | #49 — 560 T full-depth-3 canonical |
| Source commit | **TBD** (current main HEAD at launch: 31e58ee or descendant) |
| Compute SKU | D128als_v7 Spot in westus3 (AMD EPYC 9V74 / Bergamo Zen 4c) |
| Per-cell budget | 3,536,157,207 nodes (= 560 T / 158,364 cells) |
| Total budget | 560,000,000,000,000 nodes |
| Launch UTC | 2026-06-01 00:01 UTC (= 2026-05-31 17:01 PT) |
| Final sha256 | **TBD** |
| Records | **TBD** (projected 5–7 billion) |
| Bytes | **TBD** (= records × 32) |
| Final shard count | **TBD** (projected 68–75 k cells with non-empty shards) |
| Enum wall | **TBD** (projected 5–7 days at full quota) |
| Merge wall | **TBD** (projected 12–15 h external-sort) |
| Total cost | **TBD** (projected $150–185 at 2 evictions/day, hard cap $200) |
| Eviction count handled | **TBD** |
| Throttled-host re-provisions | **TBD** (pre-flight retry up to 5 attempts) |
| Cold archive | `solver-data:/canonical-archive/20260601_560T_canonical_<git>/` |

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
  | (table updated as campaign progresses) | | | |

  Five datapoints, all within a **37-minute window (07:12–07:49 PT)** —
  100 % hit rate across the campaign's first M-F sequence. Statistically
  improbable as coincidence.
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
