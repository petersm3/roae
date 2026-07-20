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

## Section summaries

**Note on this report's form (adversarial-review item F-8, 2026-07-20):** what follows is a set of
*section summaries*, not full section bodies — this report is a structured abstract over engineering
work whose detailed treatment lives in the linked documentation, not a self-contained narrative like
TR-5 or TR-11. It is labelled that way here so no reader expects prose that was never written. Each
summary names where the full treatment lives; the claims themselves are load-bearing and verifiable
through the Verification Guide below.

1. **The reproducibility contract.** What "canonical" means here: solutions.bin as a mathematical function
   of one integer (the node budget); the partition-invariance theorem (output independent of thread/
   machine/merge-path/shard-partition); the sha registry as the scientific anchor (bytes re-derivable,
   never trusted from storage).
2. **The gates.** (a) --selftest: every commit must reproduce sha 403f7202… on a fixed micro-enumeration —
   the project's unit of "this change is enumeration-neutral"; (b) canonical-scale sha gates on Spot D32
   (~$0.20) for any change touching checkpoint formats or hot paths; (c) two-language verification
   (independent C and Python constraint implementations, cross-checked; later a third source, the SAT
   layer, bound by round-trip validation); (d) host-fingerprint sidecars + a validate-canonical gate,
   after one observed host-level (not source-level) drift event — documented, bisected, and fenced.
3. **Surviving preemption.** Per-thread checkpoint design; fsync batching (35% -> 95% CPU utilization);
   the eviction-resume defect: found by targeted testing, reproduced deterministically (kill-mid-walk
   regression test), fixed, and then — the step we consider the heart of the discipline — the entire 560T
   campaign re-run from scratch on the fixed solver, reproducing the original artifact byte-for-byte
   through seven fresh evictions. The defect had not corrupted the artifact; now that is a *demonstrated*
   fact, not a hope.
4. **Spot economics and the reclamation pattern.** Cost table (D-family Spot at ~15–20% of on-demand);
   checkpoint-overhead accounting; the M-F-morning scheduled-reclamation observation (5/5 weekday
   evictions 07:12-07:49 local; 0/2 weekend days) and the resulting launch-window heuristic; deferral
   policy for restart storms.
5. **Operational failure modes, honestly.** The catalogue that produced these rules: forgotten-VM
   overspends; orphan monitor scripts resurrecting deallocated VMs; a device-naming reversal that
   destroyed a data disk (mkfs -F banned; identify-by-UUID; marker-file mounts); ARG_MAX silently
   truncating file counts at scale; IOPS gates after an fsync-bound HDD campaign. Each with its
   structural fix.
6. **What transfers.** The pattern for any long combinatorial computation on preemptible capacity:
   theorem-backed output invariance + cheap continuous gates + deterministic resume + re-derive-don't-
   patch + evidence-before-teardown.

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
| v1.6 *(current)* | 2026-07-20 | **Reproducibility claim scoped + repro recipe published (adversarial-review items F-9, F-8).** F-9: the executive summary's "re-derivable byte-for-byte by anyone" was unqualified while the body already documented a host-level drift event — an internal inconsistency in the report's strongest sentence. Added §Scope of the reproducibility claim, separating what is *demonstrated* (twice-derived byte-identical across fleets, regions, thread counts, merge paths, twelve evictions) from the **toolchain-class qualifier**, and stating that partition invariance is proved about the MODEL with the bridge to the shipped binary carried by the runtime gates, not by the theorem. F-9 also: the Verification Guide now carries an end-to-end 560T reproduction recipe with the sha-determining parameters verbatim (per the standing rule against re-deriving the per-cell budget from a formula), the expected sha/record-count/byte-count, and the honest effort figure (~171.5 h enum + ~18 h 42 m merge + ~4 TB scratch) so nobody starts it unaware. F-8: "Sections" relabelled "Section summaries" with a note that this report is a structured abstract over documented engineering, not full section bodies. No canonical, sha, or measured value changed |
