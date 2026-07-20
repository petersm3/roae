# TR-3 — Reproducible Combinatorial Enumeration at Scale on Preemptible Cloud Instances
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

This is the engineering report: how a computation that visited 560 trillion search states and produced
10.5 billion results became a **reproducible scientific object** — re-derivable byte-for-byte on hardware
the project doesn't control, given a matching toolchain class (see the qualifier below). The proof is
demonstrated, not promised: the entire computation
was run twice from scratch, weeks apart, on rented cloud machines that were forcibly interrupted twelve
times in total, and both runs produced the identical result to the last byte — at roughly 15–20% of normal
cloud cost by using interruptible "Spot" capacity. The methods (checksum anchoring, self-testing gates,
crash-safe checkpoints, re-derive-don't-patch) transfer to any long-running computation, far beyond this
project. The report also documents the failures honestly, including the one that destroyed a data disk.

## Abstract
We describe the engineering that makes a 560-trillion-node combinatorial enumeration a *reproducible
scientific object*: a 10.5-billion-record artifact whose byte-exact sha256 has been derived twice from
scratch, on different preemptible ("Spot") cloud fleets, through a combined twelve evictions — at roughly
15–20% of on-demand compute cost. The methods are general: byte-level anchoring via a partition-invariance
theorem; a self-test gate binding every source change to a canonical baseline; per-thread checkpointing
with deterministic eviction-resume; defect handling by from-scratch re-derivation rather than patching;
and an empirical finding of independent interest — in our region/SKU, Spot reclamation was scheduled
(weekday mornings, five-for-five in a 37-minute window, zero on weekends), not stochastic, with direct
consequences for launch-window planning.

## Scope of the reproducibility claim (what "byte-for-byte" does and does not promise)

Stated precisely, because the unqualified form would overclaim:

- **What is demonstrated.** The 560T artifact's sha256 was derived twice from scratch, weeks apart, on
  different Spot fleets, through twelve combined evictions, and on independently provisioned hardware —
  byte-identical both times. Independent re-derivation across machines, regions, thread counts, merge
  paths and shard partitions is a *result*, not an aspiration.
- **The toolchain qualifier.** Byte-exactness is claimed within a **matching toolchain class** (the gcc
  major-version/optimization-flag combinations recorded with each anchor in
  [CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md)), not across arbitrary compilers, libc
  versions, or architectures. This is not hypothetical caution: the project observed one **host-level**
  drift event, in which the same source produced a different artifact on a differently-provisioned host.
  It was documented, bisected, and fenced, and it was shown to be host-environment-level, **not**
  source-level — the affected anchor re-derives byte-identically on a matching host. Host-fingerprint
  sidecars and a `--validate-canonical` gate were added in response, so a reader who reproduces on a
  different host class gets a diagnosed mismatch rather than a silent one.
- **What the theorem covers.** Partition invariance is proved about the *model* of the computation
  (output independent of thread count, machine, merge path, and shard partition). The bridge from that
  model to the shipped binary is carried by the runtime gates — `--selftest`, the canonical-scale sha
  gates, and two-language cross-checks — not by the proof itself. The theorem is why re-derivation
  *should* be exact; the gates are why we believe the binary honours it.
- **Practical reading.** "Anyone" means anyone with the documented toolchain class and the budget; it
  does not mean the artifact is invariant under every compiler on every host. Where an anchor is known
  to be host-fragile, [CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) says so per anchor.

## Sections

### 1. The reproducibility contract

The claim this report defends is narrow and mechanical: `solutions.bin` is a **mathematical function of
one integer**. Fix the node budget and the constraint system, and the output is determined — not
determined up to ordering, not determined up to a tolerance, but byte-for-byte. Everything else in the
engineering exists to make that claim survive contact with real hardware.

Three things make it hold. First, the **partition-invariance theorem**: the output is independent of
thread count, machine, merge path, and shard partition. The enumeration is a set-valued computation, and
the merge imposes a canonical order on that set, so how the work was divided cannot survive into the
bytes. This is what licenses running on 128 threads today and 64 tomorrow, on a machine in one region
and then another, and expecting identity rather than similarity. Second, the **budget is the only free
parameter**, and it is recorded per canonical: `SOLVE_NODE_LIMIT` with its matching
`SOLVE_PER_SUB_BRANCH_LIMIT`, published verbatim rather than derived. That last word is load-bearing —
the per-cell budget looks like it should be `node_limit / 158,364`, and computing it that way once
produced a wrong budget and a wrong artifact. The published values are the empirical ones that produced
the published shas, and `solve --validate-launcher-config <scale> <PSB>` exists so a launcher can assert
the match before spending money rather than after.

Third, and most important culturally: **the sha registry is the scientific anchor, not the storage**.
Bytes on a disk are a convenience; the hash in the repository is the object. A file that fails to match
is not a new result to be recorded, it is a bug to be found — the registry is never "updated" to match
what a run produced. This inverts the usual relationship between artifact and record, and it is what
made the 2026-05 loss of a data disk survivable: the artifact was destroyed, the anchor was not, and
re-derivation was a cost rather than a catastrophe.

### 2. The gates

Four gates, ordered by how often they run and how much they cost.

**(a) `--selftest`, on every commit.** A fixed micro-enumeration — `SOLVE_THREADS=4`,
`SOLVE_NODE_LIMIT=100000000` — that must reproduce sha `403f7202…`. This is the project's operational
definition of "this change is enumeration-neutral": a refactor, an added subcommand, a new analysis flag
all leave the sha untouched, and anything that moves it must justify itself. It runs in minutes, it runs
constantly, and it has caught more would-be silent behaviour changes than any other mechanism here.
Its cost is not zero — the gate compiles a 25k-line translation unit and runs a four-thread enumeration,
which on a small orchestrator takes ~15 minutes and needs real memory. Placing it in a `pre-push` hook
on an undersized box has produced both false failures under memory pressure and dropped SSH connections
during the hook; the gate is sound, its siting deserves care.

**(b) Canonical-scale sha gates, on Spot D32 (~$0.20).** Any change touching checkpoint formats or hot
paths must additionally reproduce a full canonical at a scale where the behaviour actually exercises —
100 billion nodes, not 100 million. Twenty cents is cheap enough to run without deliberation and large
enough to catch what the micro-enumeration cannot.

**(c) Two-language verification.** The constraint predicates are implemented independently in C
(`solve.c`) and Python (`solve.py`), and cross-checked against each other; a third implementation, the
SAT layer (`sat.py`), is bound to them by round-trip validation rather than being allowed to state the
semantics itself. The purpose is not redundancy for its own sake — it is that a single implementation
cannot distinguish "the constraints are what we think" from "the code does what the code does".

**(d) Host-fingerprint sidecars and `--validate-canonical`.** These were added *after* the fact, in
response to one observed **host-level** drift event: identical source, different host, different
artifact. The investigation established that the drift was environmental rather than in the source —
the affected anchor re-derives byte-identically on a matching host — and the response was to make the
condition visible rather than to relax the claim. A reader reproducing on a different toolchain class
now receives a diagnosed mismatch instead of a silent one. The honest scope this implies is stated in
§Scope of the reproducibility claim above.

### 3. Surviving preemption

Preemptible capacity is cheap because the provider may reclaim it at any moment. For a computation
measured in hundreds of hours, "start again" is not an option, so the checkpoint design is the campaign
design.

Checkpoints are **per-thread and intra-layer**, written durably as the walk proceeds, so a reclaimed
machine resumes near where it stopped rather than at the last completed unit of work. The write ordering
is an invariant, not an implementation detail: a cell's solution shard must become durable *before* the
state record that says the cell is finished, or an eviction landing between the two loses solutions
while claiming completeness. Getting that backwards is precisely the defect described below.

Durability is expensive, and the naive implementation spent most of its time waiting on it. **Batching
the fsyncs took CPU utilisation from ~35% to ~95%** — nearly a threefold improvement in effective
throughput, obtained by changing when data is forced to disk rather than how much work is done.

The defect worth dwelling on is the **eviction-resume bug**. It was found by targeted testing rather
than observed in production, reproduced deterministically with a kill-mid-walk regression test, and
fixed. That is ordinary engineering. What followed is the part we consider the heart of the discipline:
because the defect *could* have corrupted the published 560T artifact, and because "could have" is not a
state a scientific record may rest in, the entire campaign was **re-run from scratch on the fixed
solver** — 171.5 hours of compute — through seven fresh evictions. It reproduced `9a968fa2…`
byte-for-byte, with the identical 10,525,271,997 records. The defect had not corrupted the artifact.
That is now a demonstrated fact rather than an argument, and the cost of demonstrating it was accepted
rather than debated.

### 4. Spot economics and the reclamation pattern

The economics are the reason for all of the above. D-family Spot capacity runs at roughly **15–20% of
on-demand** — a D128als_v7 at ~$0.95/hr against ~$5.15/hr — so a 171-hour campaign costs a few hundred
dollars instead of a few thousand. Checkpoint overhead is the price paid for that discount, and after
fsync batching it is small enough that the trade is not close.

The empirical finding of independent interest is that **reclamation was scheduled, not stochastic**. In
our region and SKU, all five evictions of the first 560T campaign fell on weekday mornings inside a
37-minute window (07:12, 07:39, 07:33, 07:42, 07:49 PT), and the weekend produced none in two days. That
is not the memoryless process the mental model assumes, and it has a direct operational consequence: a
long run launched Friday evening buys an uninterrupted weekend, while one launched Sunday night walks
into five consecutive morning reclamations.

The resulting policy is a **75-minute backoff plus a weekday-morning deferral**: after an eviction, wait,
and if the relaunch would land inside the reclamation window, defer to the far side of it rather than
feeding a restart storm. The deferral is not free — it converts compute time into wall-clock time — and
the campaign timeline figure below shows exactly that trade, with deferred-downtime blocks running to
the 18:01 PT relaunch. It is the right trade when a restart costs more than the wait.

### 5. Operational failure modes, honestly

Every rule in this project's operating discipline exists because something went wrong first. The
catalogue is recorded rather than tidied away, because the rules are only intelligible alongside their
incidents.

**Forgotten VMs.** Instances provisioned for a "brief inspection" outlived the inspection by hours or
days, repeatedly, at $3–25 each time. The structural fix is that every provisioning command must be
paired with a teardown plan in the same sequence, and a session-lifetime VM log is reconciled against
`az vm list` before any session ends. A related and subtler failure: **orphan monitor scripts**. A
watcher written to restart an evicted VM will keep restarting it forever once its originating session is
gone, silently undoing manual deallocation — the resurrection cycle that produced one of the larger
overspends here.

**A device-naming reversal destroyed a data disk.** A setup script ran `mkfs.ext4 -F` against what it
believed was an empty scratch disk; kernel NVMe naming had reversed the LUN order, and the target was
the 3 TB disk holding a canonical artifact and an entire campaign's intermediate state. The `-F` flag
suppressed exactly the refusal that would have prevented it. Three rules followed: `mkfs -F` is banned
outright, pre-existing disks are identified by **UUID** rather than device path, and every mount is
confirmed by a **marker file** before being treated as the expected disk. The artifact was recoverable
only because of §1's inversion — the sha, not the bytes, was the record.

**`ARG_MAX` silently truncating file counts.** Shell globs over shard directories stop working somewhere
past ~30,000 files, and they fail by returning a wrong answer rather than an error. Counting shards with
`find … | wc -l` instead of a glob is not stylistic preference; it is the difference between a correct
and a quietly incorrect completeness check at scale.

**IOPS gates after an fsync-bound campaign.** A campaign run on HDD-backed storage was limited not by
CPU but by durability latency, which the instrumentation at the time did not surface. Pre-flight IOPS
checks were added so the condition is detected before hours are spent rather than inferred afterward.

### 6. What transfers

Little here is specific to hexagram orderings. The transferable pattern, for any long combinatorial
computation on preemptible capacity, is five things in combination:

**Theorem-backed output invariance** — establish that the result does not depend on how the work was
divided, so that heterogeneous, interrupted, re-scheduled execution is sound rather than merely hoped
for. **Cheap continuous gates** — a fast neutrality check on every change and a scaled check on risky
ones, priced low enough that nobody argues about running them. **Deterministic resume** — checkpointing
whose write ordering is treated as an invariant, plus a regression test that kills the process mid-walk,
because resume paths are exactly the code that never runs during ordinary testing. **Re-derive, don't
patch** — when a defect *might* have touched a published artifact, reproduce the artifact from scratch on
the fixed code rather than reasoning about whether the corruption was possible. **Evidence before
teardown** — pull the artifacts and the logs off a machine before deleting it, because the cheapest
moment to preserve evidence is always before the resource disappears.

The economics that motivate the discipline are not exotic either: an 80–85% discount in exchange for
accepting interruption is available to anyone, and the engineering above is what converts that discount
from a hazard into a line item.

## Figure

![Timeline of the first 560T campaign in Pacific Time, 2026-05-31 to 2026-06-08: green enumeration segments interrupted by five red eviction marks (Mon 07:12, Tue 07:39, Wed 07:33, Thu 07:42, Fri 07:49 PT) each followed by a purple deferred-downtime block ending at the 18:01 PT relaunch, then an uninterrupted eviction-free weekend through enumeration completion at 171.5 h wall.](figures/fig_tr3_campaign_timeline.png)

*The first 560T campaign timeline (§4). Launch Sun 2026-05-31 17:03 PT; all five Spot evictions (red)
landed M-F inside a 37-minute window (07:12–07:49 PT), each deferred to the 18:01 PT relaunch under the
M-F-daytime defer policy (purple); both weekend days produced zero evictions (~54 h clean runway) —
the scheduled-reclamation observation. Eviction times are the campaign record in
[documentation/CAMPAIGN_METHODOLOGY.md](../documentation/CAMPAIGN_METHODOLOGY.md). The 2026-06-30 re-run's different 7-eviction pattern is plotted
from its telemetry in [`runs/20260608_560T_9a968fa2/viz/`](../runs/20260608_560T_9a968fa2/viz/index.html)
(eviction-recovery panel); its per-eviction timestamps are not in the public docs, so only the first run
is drawn here. Generated by [`viz/report_figures.py`](../viz/report_figures.py);
[SVG](figures/fig_tr3_campaign_timeline.svg).*

## Verification Guide
- Selftest gate: `gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz && ./solve --selftest` -> PASS,
  sha 403f7202…

**Reproducing the 560T canonical end-to-end.** The full recipe, with the sha-determining parameters
exactly as published (copy them verbatim — do *not* re-derive the per-cell budget from a
`node_limit / 158,364` formula; that shortcut has produced a wrong budget before):

```
# 0. pre-flight: assert your launcher's budget matches the published recipe (exit 0 = match)
./solve --validate-launcher-config 560T 3536157207
./solve --canonical-config 560T --full     # emit the sha-determining env vars

# 1. enumerate (D128als_v7 Spot westus3 was used; 128 threads assumed by the resume paths)
SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=560000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=3536157207 \
SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128 \
SOLVE_SKIP_AUTOMERGE=1 ./solve            # shards to disk; survives eviction via checkpoints

# 2. merge separately, on a Standard (non-preemptible) VM — mid-merge eviction loses the work
./solve --merge

# 3. verify
sha256sum solutions.bin    # -> 9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e
./solve --verify           # C1-C5 + sorted + no duplicates + King Wen present
```

Expected result: **10,525,271,997 records**, **336,808,703,936 bytes**. Expected effort, so nobody starts
this unaware: ~**171.5 h** enumeration wall time on a 128-vCPU Spot instance plus ~**18 h 42 m** for the
merge on a 16-vCPU Standard instance, and ~4 TB of fast scratch for shards. `SOLVE_THREADS` is not
sha-determining (the merge dedup is order-stable), but the eviction-recovery and resume paths assume 128.
Per-anchor parameters for every other canonical: [CANONICAL_HASHES.md §Reproducibility
parameters](../documentation/CANONICAL_HASHES.md#reproducibility-parameters).
- Canonical registry + per-anchor reproduction parameters: [documentation/CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md)
- Partition-invariance statement + evidence: [documentation/PARTITION_INVARIANCE.md](../documentation/PARTITION_INVARIANCE.md)
- 560T twice-derived record: CANONICAL_HASHES §d3 560T (9a968fa2…, 10,525,271,997 records, both runs)
- Eviction-resume regression test + fix lineage: [DEVELOPMENT.md](../documentation/DEVELOPMENT.md) + [HISTORY.md](../documentation/HISTORY.md) 2026-06 entries
- Campaign method + worked example: documentation/CAMPAIGN_METHODOLOGY.md

*Note on cost figures: public figures are rounded by design (the exact ledger contains account-level detail excluded under the project's no-cloud-identifiers policy).*

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
| v1.2 | 2026-07-04 | Figures added |
| v1.5 | 2026-07-04 | Adversarial round 2 correction: enumeration timeline stated as weeks, not months |
| v1.6 | 2026-07-20 | **Reproducibility claim scoped + repro recipe published (adversarial-review items F-9, F-8).** F-9: the executive summary's "re-derivable byte-for-byte by anyone" was unqualified while the body already documented a host-level drift event — an internal inconsistency in the report's strongest sentence. Added §Scope of the reproducibility claim, separating what is *demonstrated* (twice-derived byte-identical across fleets, regions, thread counts, merge paths, twelve evictions) from the **toolchain-class qualifier**, and stating that partition invariance is proved about the MODEL with the bridge to the shipped binary carried by the runtime gates, not by the theorem. F-9 also: the Verification Guide now carries an end-to-end 560T reproduction recipe with the sha-determining parameters verbatim (per the standing rule against re-deriving the per-cell budget from a formula), the expected sha/record-count/byte-count, and the honest effort figure (~171.5 h enum + ~18 h 42 m merge + ~4 TB scratch) so nobody starts it unaware. F-8: "Sections" relabelled "Section summaries" with a note that this report is a structured abstract over documented engineering, not full section bodies. No canonical, sha, or measured value changed |
| v1.7 *(current)* | 2026-07-20 | **Section bodies written (adversarial-review item F-8, operator-directed).** v1.6 honestly relabelled the numbered list as "section summaries" because no bodies existed; the bodies now exist. All six sections expanded from one-paragraph abstracts into prose: the reproducibility contract (output as a function of one integer; why the per-cell budget is published verbatim rather than derived; the sha registry as the anchor rather than the storage), the four gates and their costs (including the honest note that the selftest gate is itself heavy enough to misbehave on an undersized host), preemption survival (per-thread intra-layer checkpoints, the durability write-order invariant, fsync batching 35%->95%, and the eviction-resume defect answered by a full from-scratch re-derivation rather than an argument), Spot economics and the scheduled-reclamation finding with its backoff/deferral policy, the operational failure catalogue with the structural fix each incident produced, and what transfers to any long computation on preemptible capacity. No claim, number, sha or scope statement changed — this is the prose that the summaries stood in for |
