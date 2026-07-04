# [TR-3](TR3_REPRODUCIBLE_ENUMERATION.md) — Reproducible Combinatorial Enumeration at Scale on Preemptible Cloud Instances
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

This is the engineering report: how a computation that visited 560 trillion search states and produced
10.5 billion results became a **reproducible scientific object** — re-derivable byte-for-byte by anyone,
on hardware the project doesn't control. The proof is demonstrated, not promised: the entire computation
was run twice from scratch, months apart, on rented cloud machines that were forcibly interrupted twelve
times in total, and both runs produced the identical result to the last byte — at roughly 15% of normal
cloud cost by using interruptible "Spot" capacity. The methods (checksum anchoring, self-testing gates,
crash-safe checkpoints, re-derive-don't-patch) transfer to any long-running computation, far beyond this
project. The report also documents the failures honestly, including the one that destroyed a data disk.

## Abstract
We describe the engineering that makes a 560-trillion-node combinatorial enumeration a *reproducible
scientific object*: a 10.5-billion-record artifact whose byte-exact sha256 has been derived twice from
scratch, on different preemptible ("Spot") cloud fleets, through a combined twelve evictions — at roughly
15% of on-demand compute cost. The methods are general: byte-level anchoring via a partition-invariance
theorem; a self-test gate binding every source change to a canonical baseline; per-thread checkpointing
with deterministic eviction-resume; defect handling by from-scratch re-derivation rather than patching;
and an empirical finding of independent interest — in our region/SKU, Spot reclamation was scheduled
(weekday mornings, five-for-five in a 37-minute window, zero on weekends), not stochastic, with direct
consequences for launch-window planning.

## Sections
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
4. **Spot economics and the reclamation pattern.** Cost table (D-family Spot at ~15-23% of on-demand);
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

## Verification Guide
- Selftest gate: `gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz && ./solve --selftest` -> PASS,
  sha 403f7202…
- Canonical registry + per-anchor reproduction parameters: documentation/CANONICAL_HASHES.md
- Partition-invariance statement + evidence: documentation/PARTITION_INVARIANCE.md
- 560T twice-derived record: CANONICAL_HASHES §d3 560T (9a968fa2…, 10,525,271,997 records, both runs)
- Eviction-resume regression test + fix lineage: DEVELOPMENT.md + HISTORY.md 2026-06 entries
- Campaign method + worked example: documentation/CAMPAIGN_METHODOLOGY.md

## Planned improvements (v1.1+)
- Fill exact cost figures from the private ledger (public version uses rounded figures, no cloud IDs)
- One diagram: campaign timeline with eviction marks (viz assets exist)

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
