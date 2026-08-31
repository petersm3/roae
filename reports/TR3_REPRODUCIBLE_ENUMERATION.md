# TR-3 — Reproducible Combinatorial Enumeration at Scale on Preemptible Cloud Instances
*Technical report — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. One caveat is structural, and it frames all the rest: the same
author wrote the claims, the software that checks them, and this report that grades the check.
Verification here is independent in mechanism, never in authorship; no independent party has yet
audited or reproduced any of it (METHODS.md §"Authorship independence").*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

This is the engineering report: how a computation that visited 560 trillion search states and produced
10.5 billion records became a **reproducible scientific object** — re-derivable byte-for-byte on hardware
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
and an empirical observation of independent interest — in our region/SKU, over the first campaign's
week, Spot reclamation behaved as scheduled (weekday mornings, five-for-five in a 37-minute window,
zero on weekends) rather than stochastic — a five-event single-campaign pattern, not a demonstrated
service property — with direct consequences for launch-window planning.

## Scope of the reproducibility claim (what "byte-for-byte" does and does not promise)

Stated precisely, because the unqualified form would overclaim:

- **What is demonstrated.** The 560T artifact's sha256 was derived twice from scratch, weeks apart, on
  different Spot fleets, through twelve combined evictions, and on independently provisioned hardware —
  byte-identical both times. Independent re-derivation across machines, regions, thread counts, merge
  paths and shard partitions is a *result*, not an aspiration.
- **The toolchain qualifier.** Byte-exactness is claimed within a **matching toolchain class**, not
  across arbitrary compilers, libc versions, or architectures. Be precise about what the registry
  actually records, because it is less than a toolchain pin: the build recipe (gcc flags) is given once,
  globally, in [CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) §"Solver version", and each
  anchor's entry records its solver commit and VM SKU. A per-anchor **gcc version is not recorded** —
  gcc versions appear only on the ARM cross-architecture witness rows. A reader matching "the toolchain
  class" is therefore matching a recipe and a machine type, not a pinned compiler build.
  The qualifier is not hypothetical caution: the project observed one **host-level**
  drift event, in which the same source produced a different artifact on a differently-provisioned host.
  It was documented, bisected, and fenced, and it was shown to be host-environment-level, **not**
  source-level — the affected anchor re-derives byte-identically on a matching host. That conclusion is
  auditable from the public record rather than asserted: the seven hardening commits in the suspect
  range were empirically exonerated, and LTO was empirically ruled out as the mechanism — building with
  `-fno-lto` still produced the drifted 1T sha `74d39760…`, not the pre-drift anchor `5a0f0bc2…`. The
  drift is also scale-sensitive rather than universal: on the very code state that drifted at 1T, the
  11.2T anchor `0c0fe37c…` re-derived byte-identically. See
  [HISTORY.md](../documentation/HISTORY.md) §"May 27/28, 2026 UTC — Task #110 Tier 1
  canonical-determinism hardening" and
  [PERFORMANCE_HISTORY.md](../documentation/PERFORMANCE_HISTORY.md) §"2026-05-27 — task #106/#108"
  (the ⚠ Correction of 2026-08-30 withdrawing the earlier LTO/hardening-commit attribution).
  Host-fingerprint sidecars and a `--validate-canonical` gate were added in response, so a reader who
  reproduces on a different host class gets a **visible** mismatch rather than a silent one — see §2(d)
  for what that gate does and does not tell them.
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
its published launch configuration** — the enumeration depth `SOLVE_DEPTH`, the per-cell budget
`SOLVE_PER_SUB_BRANCH_LIMIT`, and the node budget `SOLVE_NODE_LIMIT` — together with the constraint
system. Fix those and the output is determined: not determined up to ordering, not determined up to a
tolerance, but byte-for-byte. What the reproducer actually chooses is *which anchor* to reproduce;
every value in that anchor's row is then published verbatim in
[CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) §"Reproducibility parameters", and none of
them may be inferred. Depth is the trap worth naming here rather than in an appendix: `SOLVE_DEPTH`
**defaults to 2**, while every depth-3 canonical in the registry — 1T through 560T — requires
`SOLVE_DEPTH=3` alongside its explicit per-cell budget. A reproducer who takes "one number" literally
and sets only the node budget runs a different partition of the search and cannot match the published
sha. Everything else in the
engineering exists to make that claim survive contact with real hardware.

Three things make it hold. First, the **partition-invariance theorem**: the output is independent of
thread count, machine, merge path, and shard partition. The enumeration is a set-valued computation, and
the merge imposes a canonical order on that set, so how the work was divided cannot survive into the
bytes. This is what licenses running on 128 threads today and 64 tomorrow, on a machine in one region
and then another, and expecting identity rather than similarity. Second, the **sha-determining
parameters are few, and every one of them is published rather than derived**: `SOLVE_DEPTH` and
`SOLVE_PER_SUB_BRANCH_LIMIT` always, and `SOLVE_NODE_LIMIT` in the one case where no explicit per-cell
budget is supplied — with an explicit per-cell budget, which every depth-3 canonical here supplies, the
DFS enforces that budget alone and the nominal node budget does not determine the sha
(CANONICAL_HASHES.md §"Sha-determining vs operational env vars"). *Published* is load-bearing —
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

**(a) `--selftest`, at every push from a clone that has installed the git hooks.** Installation is
per-clone and opt-in — one documented command wires the pre-push gate
([DEVELOPMENT.md](../documentation/DEVELOPMENT.md) §"Git hooks — opt-in"); a bare clone runs no hooks,
and the pre-commit gate does not run the selftest. The operator also runs it by hand as standing
practice. *(Corrected 2026-08-06: this heading previously claimed "on every commit", which no commit
gate performs.)* A fixed micro-enumeration — `SOLVE_THREADS=4`,
`SOLVE_NODE_LIMIT=100000000` — that must reproduce sha `403f7202…`. This is the project's operational
definition of "this change is enumeration-neutral": a refactor, an added subcommand, a new analysis flag
all leave the sha untouched, and anything that moves it must justify itself. It runs in minutes, it runs
constantly, and it has caught more would-be silent behaviour changes than any other mechanism here.
Its cost is not zero — the gate compiles a 25k-line translation unit and runs a four-thread enumeration,
which on a small orchestrator takes ~15 minutes and needs real memory. Placing it in a `pre-push` hook
on an undersized box has produced both false failures under memory pressure and dropped SSH connections
during the hook; the gate is sound, its siting deserves care.

**(b) Canonical-scale sha gates.** Any change touching checkpoint formats or hot paths must
additionally reproduce a sha at a scale where the behaviour actually exercises, and the scale has two
tiers that are easy to conflate. A 100-billion-node run on Spot D32 (~$0.20) is cheap enough to run
without deliberation and catches what the 100-million-node micro-enumeration cannot — but it is a
**smoke and correlation check, not a canonical reproduction**. Sub-1T shas are commit- and
build-recipe-specific, and commits with no reachable effect on the DFS path have been measured to flip
them (CANONICAL_HASHES.md §"100B and sub-canonical reference shas — code-specific, NOT
canonical-grade"), so treating a 100B movement as a scientific regression will produce false alarms.
`solve.c` enforces the distinction rather than leaving it to discipline: a canonical-enum run with
`SOLVE_NODE_LIMIT` below 1T exits 25 unless the operator sets `SOLVE_ALLOW_SUB_CANONICAL=1` or supplies
an explicit `SOLVE_PER_SUB_BRANCH_LIMIT`, both of which are acknowledgements that the resulting sha is
code-specific. Canonical-grade cross-build verification starts at **1T** —
`SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=1000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=6315458` — and costs
accordingly.

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
now receives a **visible** mismatch instead of a silent one. *Visible* is the accurate word, not
*diagnosed*: `--validate-canonical` re-runs the anchor and prints the reader's own host fingerprint
(gcc, glibc, kernel, CPU model, microcode, OS release) either way, and on mismatch adds the expected and
measured shas plus three candidate causes — host environment, source regression, stale anchor — before
exiting 33. It does **not** compare that fingerprint against a stored reference for the anchor: no
reference fingerprint is published per anchor or read back by the gate, so choosing among the three
causes is left to the reader.
The honest scope this implies is stated in §Scope of the reproducibility claim above.

### 3. Surviving preemption

Preemptible capacity is cheap because the provider may reclaim it at any moment. For a computation
measured in hundreds of hours, "start again" is not an option, so the checkpoint design is the campaign
design.

Checkpoints are **per-thread and intra-layer**, written durably as the walk proceeds, so a reclaimed
machine resumes near where it stopped rather than at the last completed unit of work. The write ordering
is an invariant, not an implementation detail: a cell's solution shard must become durable *before* the
state record that says the cell is finished, or an eviction landing between the two loses solutions
while claiming completeness. Getting that backwards is precisely the defect described below.

Durability is expensive, and the naive implementation spent most of its time waiting on it —
serialised behind a single checkpoint mutex. **Giving each thread its own checkpoint file (#108)
took CPU utilisation from ~35% to ~95.3%**, cutting 1T canonical enumeration wall time ~2.0×
(3,430 s → 1,679 s) and raising measured sub-branch throughput ~43% (~28 → 40.05 sub-branches/sec) —
obtained by removing contention rather than by doing less work. The occupancy ratio (~2.7×) is not the
throughput figure: work completed rose by the smaller factors, and quoting the utilisation ratio as
throughput overstates the gain.

⚠ **Corrected 2026-08-24.** This paragraph previously attributed the gain to *fsync batching*. That
is wrong: fsync batching (#108b, `SOLVE_FSYNC_BATCH_SIZE`) is **opt-in and defaults to 1 — legacy
per-write fsync, byte-identical to pre-#108b** — so it cannot produce a default-mode gain. The
mutex elimination is the cause; see `PERFORMANCE_HISTORY.md` §"2026-05-27 — task #106/#108" →
*Notes* item 1, which names #108 "the headline mutex elimination", and `solve.c`'s `checkpoint_mutex`.
**The utilisation measurement was always right; the causal story was wrong.** Two further defects in
this paragraph were fixed at v1.11, both of which this 2026-08-24 pass touched without catching: it
also read the utilisation ratio out as "nearly a threefold improvement in effective throughput", which
no throughput measurement supports; and the citation above was pinned by line number, which had already
gone stale, so it is now given by section.

The defect worth dwelling on is the **eviction-resume bug**. It was found by targeted testing rather
than observed in production, reproduced deterministically with a kill-mid-walk regression test, and
fixed. That is ordinary engineering. What followed is the part we consider the heart of the discipline:
because the defect *could* have corrupted the published 560T artifact, and because "could have" is not a
state a scientific record may rest in, the entire campaign was **re-run from scratch on the fixed
solver** — a full repetition of the ~171.5-enumeration-hour workload — through seven fresh evictions. It reproduced `9a968fa2…`
byte-for-byte, with the identical 10,525,271,997 records. The defect had not corrupted the artifact.
That is now a demonstrated fact rather than an argument, and the cost of demonstrating it was accepted
rather than debated.

### 4. Spot economics and the reclamation pattern

The economics are the reason for all of the above. D-family Spot capacity runs at roughly **15–20% of
on-demand** — a D128als_v7 at ~$0.95/hr against ~$5.15/hr — so the ~171.5-hour enumeration leg costs
roughly **$163 rather than roughly $880**, and adding the ~18 h 42 m merge leg still leaves the
on-demand figure under $1,000 at the same rate. A few hundred dollars instead of most of a thousand: a
real discount, not the order of magnitude the round numbers invite. Checkpoint overhead is the price
paid for it. Per-thread checkpoint files removed most of that overhead in the **default** configuration;
`SOLVE_FSYNC_BATCH_SIZE>1` removes more where the storage is slow, but it is **opt-in and defaults to 1
(batching off)**, so it is not what makes the default trade favourable (see the 2026-08-24 correction in
§3).
Either way the trade is not close.

The empirical observation of independent interest is that **reclamation behaved as scheduled, not
stochastic, over the observed window**. In
our region and SKU, all five evictions of the first 560T campaign fell on weekday mornings inside a
37-minute window (07:12, 07:39, 07:33, 07:42, 07:49 PT), and the weekend produced none in two days.
Five events in one campaign week is a pattern, not proof of a provider scheduling policy (the
2026-06-30 re-run's seven evictions arrived in a different pattern —
[CANONICAL_HASHES](../documentation/CANONICAL_HASHES.md) §d3 560T), and Spot capacity carries no
availability SLA. Within that week it was not the memoryless process the mental model assumes, which is
worth recording — but the operational reading has to stay an observation rather than a schedule. In the
observed region and SKU a Friday-evening launch *may* reduce weekend exposure and a Sunday-night launch
*may* walk into consecutive morning reclamations; the pattern did not replicate in the re-run, so do
not schedule against it and do not plan a campaign that only completes if it holds.

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

# 3. verify — solutions.bin is GZIP-FRAMED under the default SOLVE_COMPRESS=1, and every
#    canonical sha is computed on the DECOMPRESSED bytes (sha256_of_logical() in solve.c). Hashing the
#    container instead is a false mismatch — the 1T gz ladder caught exactly that (it read
#    the container sha f5dfe17f instead of the canonical 74d39760). Under SOLVE_COMPRESS=0
#    the file is raw and plain `sha256sum solutions.bin` is the right command.
gzip -dc solutions.bin | sha256sum   # -> 9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e
./solve --verify           # C1-C5 + sorted + no duplicates + King Wen present (gz-aware: reads raw or gz)
```

Expected result: **10,525,271,997 records**, **336,808,703,936 bytes** — the byte figure is the
**logical (decompressed)** size, 32-byte header + 32 bytes/record; the on-disk gz file is smaller, so
compare it against `gzip -dc solutions.bin | wc -c`, not `ls -l`. Expected effort, so nobody starts
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
| v1.7 | 2026-07-20 | **Section bodies written (adversarial-review item F-8, operator-directed).** v1.6 honestly relabelled the numbered list as "section summaries" because no bodies existed; the bodies now exist. All six sections expanded from one-paragraph abstracts into prose: the reproducibility contract (output as a function of one integer; why the per-cell budget is published verbatim rather than derived; the sha registry as the anchor rather than the storage), the four gates and their costs (including the honest note that the selftest gate is itself heavy enough to misbehave on an undersized host), preemption survival (per-thread intra-layer checkpoints, the durability write-order invariant, fsync batching 35%->95%, and the eviction-resume defect answered by a full from-scratch re-derivation rather than an argument), Spot economics and the scheduled-reclamation finding with its backoff/deferral policy, the operational failure catalogue with the structural fix each incident produced, and what transfers to any long computation on preemptible capacity. No claim, number, sha or scope statement changed — this is the prose that the summaries stood in for |
| v1.8 | 2026-07-31 | **Reclamation-pattern claim hedged + re-run effort figure re-attributed (novelty-gate audit #20, batch 2).** (1) "Reclamation was scheduled, not stochastic" (exec summary + §4) restated as an observed single-campaign pattern — five events in one week, weekday-morning 37-minute window — not a demonstrated provider scheduling policy; the 2026-06-30 re-run's seven evictions arrived in a different pattern (CANONICAL_HASHES §d3 560T). The launch-window policy is unchanged (it needs only the pattern). (2) §3 attributed "171.5 hours of compute" to the re-run; 171.5 h is the FIRST campaign's enumeration wall time (CANONICAL_HASHES §d3 560T) — the sentence now says the re-run repeated that workload rather than claiming its wall time. No sha, count, or verdict changed |
| v1.9 | 2026-08-01 | **Verification Guide's sha step corrected: it hashed the wrong bytes (lens-sweep item T2-1).** Step 3 read `sha256sum solutions.bin`, but `solutions.bin` is gzip-framed under the default `SOLVE_COMPRESS=1` and every canonical sha is computed on the DECOMPRESSED stream (`solve.c:1103-1110`) — so a replicator following the published recipe verbatim would have computed the *container* sha and concluded the flagship canonical does not reproduce. This is the failure the 1T gz ladder already caught internally (container sha `f5dfe17f` read instead of canonical `74d39760`); our own 560T witnesses used `gzip -dc \| sha256sum`, which is why it never surfaced in-house. Step 3 now reads `gzip -dc solutions.bin \| sha256sum`, states the `SOLVE_COMPRESS=0` raw case, and notes `--verify` is gz-aware. The expected **336,808,703,936 bytes** is likewise the *logical* (decompressed) size — the on-disk gz is smaller — so the size cross-check is now stated against `gzip -dc \| wc -c` rather than `ls -l`. No sha, count, or verdict changed; the anchors are exactly as published |
| v1.10 | 2026-08-06 | **Gate (a)'s trigger corrected: the selftest does not run "on every commit" (fix-landing pass).** §2's heading claimed `--selftest` runs at commit time; verified false — no pre-commit gate invokes `--selftest` (grep count zero in both commit-side gate scripts). The real trigger is the pre-push compile gate, which fires only from a clone that has installed the git hooks (installation is per-clone and opt-in, one documented command — DEVELOPMENT.md §"Git hooks"), plus the operator's standing manual practice. Heading and opening rewritten to say exactly that, with a dated correction note; the §2 body's pre-push-siting discussion was already accurate and is unchanged. METHODS.md's environment-table source column ("every commit gate") corrected in the same pass. No sha, count, or verdict changed |
| v1.11 *(current)* | 2026-08-31 | **Eight corrections from the executed prose review (batch P09).** (1) §1's contract read "`solutions.bin` is a mathematical function of **one integer**" and called the budget "the only free parameter". `SOLVE_DEPTH` is sha-determining and **defaults to 2**, while every depth-3 canonical requires `SOLVE_DEPTH=3`; a reproducer taking §1 literally could not match a published sha. §1 now states the contract over the whole published launch configuration and names depth explicitly. (2) §1's "budget is the only free parameter" replaced with the registry's own distinction: `SOLVE_DEPTH` and `SOLVE_PER_SUB_BRANCH_LIMIT` are sha-determining, `SOLVE_NODE_LIMIT` only when no explicit per-cell budget is given. (3) §Scope's toolchain qualifier claimed gcc major-version/flag combinations are "recorded with each anchor"; they are not — the build recipe is global and gcc versions appear only on the ARM witness rows. Restated to what the registry holds. (4) §Scope and §2(d) called a `--validate-canonical` mismatch **diagnosed**; the gate prints the reader's own host fingerprint plus three candidate causes and exits 33, with no stored reference fingerprint to compare against. Restated as *visible*, with the gate's actual output described. (5) §Scope now cites the public evidence for the host-level drift finding (HISTORY.md §Task #110; PERFORMANCE_HISTORY.md §2026-05-27 task #106/#108 and its 2026-08-30 correction) so the conclusion is checkable rather than asserted. (6) §2(b) offered a 100-billion-node run as reproducing "a full canonical"; the registry classes sub-1T shas as code-specific and `solve.c` exits 25 below 1T without an explicit override. Restated as a smoke/correlation check, with canonical-grade verification starting at 1T. (7) §3's "#108 … nearly a threefold improvement in effective throughput" was the occupancy ratio, not throughput: the measured figures are wall ~2.0× (3,430 s → 1,679 s) and sub-branch throughput +43% (~28 → 40.05/s). (8) §4's "a long run launched Friday evening buys an uninterrupted weekend" downgraded from a scheduling guarantee to an observation that did not replicate in the re-run; §4's "a few thousand" on-demand figure corrected to ~$880 for the enumeration leg (under $1,000 including merge) against the report's own published rates; and two stale line pins repinned to stable anchors (`PERFORMANCE_HISTORY.md:1174-1175` → §"2026-05-27 — task #106/#108" *Notes* item 1; `solve.c:1103-1110` → `sha256_of_logical()`). Two siblings swept beyond the charged sites: §2(d) carried the same "diagnosed mismatch" wording as §Scope, and §4 credited the low checkpoint overhead to "after fsync batching" — the same default-mode attribution the 2026-08-24 correction retracted in §3, left un-propagated one section away. Knowingly left unchanged: the v1.7 and v1.9 revision rows above still restate the "function of one integer" framing and the `solve.c:1103-1110` pin, because they are the historical record of what those revisions did, not live claims. No sha, record count, or canonical anchor changed |
