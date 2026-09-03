# Deployment notes for long solver runs

This documents infrastructure-agnostic lessons for running `solve` on remote VMs
for multi-hour (or multi-day) enumerations. Cloud-specific examples (Azure spot
VMs) appear at the end as an appendix; the architectural rules earlier in this
doc apply on any provider.

For the full `solve.c` command-line reference (every subcommand, env var, and exit code referenced below), see [SOLVE_C_CLI.md](SOLVE_C_CLI.md).

> **Access boundary.** This document cites operational scripts and runbooks in `roae-private`, the
> project's private staging repository, which is not publicly accessible. Those citations are
> provenance pointers, not material a reader can fetch. The deployment lessons stated here stand on
> their own text; the private files carry the operator-side implementations.

## Architecture: separate orchestrator, solver, and monitor

Three concerns, three processes:

1. **Launcher** — one-shot: provisions VM, syncs source, compiles, starts solver,
   exits. Must not hold state for the duration of the run.
2. **Solver** — `solve` binary running on the remote VM under `nohup`, writing
   `checkpoint.txt`, `progress.txt`, and `sub_*.bin` to a persistent volume.
3. **Monitor** — long-running local loop: periodically syncs output files,
   detects eviction, handles completion, archives results.

If the launcher and monitor are merged, a crash during setup kills monitoring for
the whole run. Keep them independent.

## Rules for the monitor loop

- Use `set -uo pipefail`, not `set -euo pipefail`. A transient ssh/scp failure
  must not kill the loop — log it and retry next tick.
- Guard every remote read with an existence check (`ssh ... 'test -f /data/checkpoint.txt'`)
  before `scp`. Files don't exist at t=0.
- Never redirect orchestrator stderr to `/dev/null`. Silent death is the worst
  failure mode.
- After launching the monitor in the background (`nohup ... &`), verify it is
  actually running with `pgrep -fa monitor_` before moving on. A successful
  fork is not a successful start.
- First checkpoint arrives only after the first sub-branch completes (~10 min
  for a 100T run). Absence before that is not failure.

## Solver invariants the monitor depends on

- **Atomic writes.** `solve.c` writes to `foo.tmp` then renames. A mid-write
  snapshot by the monitor must never read a truncated file.
- **Per-sub-branch node limits.** Thread scheduling varies, but each sub-branch
  has a deterministic node budget, so results are reproducible regardless of
  how threads pick up work.
- **Run ID file.** `/data/run_id.txt` identifies the current run. Before wiping
  the persistent volume at launch, compare to the intended run ID — resume if
  they match, wipe only if they differ.
- **Checkpoint files are append-only — there are no rotated generations.**
  `checkpoint.txt` and the per-thread `checkpoint_t<N>.txt` files are appended,
  never rotated to `.1`/`.2`. The loader's robustness is a different mechanism:
  it tolerates a truncated final line (normal after SIGTERM) and *rejects*
  malformed lines fail-safe — rejected sub-branches are not marked complete and
  are re-walked (Q-368; see `load_sub_checkpoint` in `solve.c`). Recovery depth
  comes from the `sub_*.bin` shards and their `.dfs_state` sidecars, not from
  checkpoint copies.

## Persistent volume

The solver's output volume must survive VM eviction and recreation. On cloud
spot VMs this means a managed disk attached separately from the OS disk, mounted
at a stable path (e.g. `/data`). Device names can change across reboots — the
launcher should scan for the partitionless ext4 volume rather than hardcoding
`/dev/sdX`.

## Eviction recovery (spot/preemptible VMs)

- Exponential backoff on retry: 1h → 2h → 4h (cap). Immediate retry wastes
  spot-market signal and burns quota.
- On recreate, reattach the persistent disk, check `run_id.txt`, and the solver
  resumes from the latest checkpoint.

## Completion and archival

- Completion detection depends on the mode. In **single-VM mode** (bundled
  merge) the solver writes `solve_results.json` with a `SEARCH_COMPLETE` status
  field, and solver exit plus that file is the signal. In **split enum/merge
  mode** (`SOLVE_SKIP_AUTOMERGE=1` — mandatory for canonical runs ≥11.2T) the
  enum process returns *before* the completion report and before the JSON is
  written, so the enum VM never produces `solve_results.json` at all. There the
  signal is solver exit rc=0 **plus** the `SOLVE_SKIP_AUTOMERGE set; skipping
  bundled merge` line in `solve_output.txt` **plus** filesystem truth (shard
  count and `shard_manifest.txt` state) — or, better, the supervisor-written
  `done.marker` / `fail.marker` pair the canonical campaign scripts use.
  Treating an absent `solve_results.json` as failure in split mode is the
  §Lessons item 4 incident (monitor tore down a successful run) re-instructed.
- Copy **all** outputs locally before tearing down the VM: `solutions.bin`,
  `solutions.sha256`, `solve_output.txt`, `solve_results.json` (single-VM mode
  only — see above), `checkpoint.txt` + `checkpoint_t*.txt`, and the
  `sub_*.bin` shards with their `.dfs_state` / `.budget` / `.provenance.json`
  sidecars and `shard_manifest.txt`. Sha-verify before deallocating.
- Archive to `runs/<YYYYMMDD>_<label>/`.

## Checkpoint granularity must match eviction frequency

**Historical lesson (not current state).** The 2026-04-13 100T attempt —
on F64als_v6 spot in westus2, a SKU now retired for this project — exposed
a fundamental mismatch: sub-branch-level checkpointing (committing
`sub_P_O.bin` only when a sub-branch finishes its ~33B node budget) was
too coarse for a spot VM whose eviction frequency exceeded the per-branch
wall time. That run was aborted. **The successful 100T d3 canonical run
(2026-04-19/20) used D128als_v7 westus3 on-demand** — no evictions, 16h 48m
end-to-end — so the following lesson is about spot-VM checkpoint granularity
in general, not about the 100T canonical specifically. If you ever return
to spot for 100T+ enumeration, the granularity analysis below still applies.

Observed behavior:
- ~1 eviction every 2-3 hours under load
- Each eviction killed all 64 in-flight sub-branches mid-run
- `INTERRUPTED` branches restart from node zero on resume (no intra-branch state)
- After ~9h wall time: 47/3030 committed, 12.5T wasted nodes, projected ~30 days

**Rule of thumb:** committed-work granularity should be *smaller* than the mean
time between interruptions, not larger. At 1.3B nodes/sec and ~25s per
sub-branch, 64 threads dropping means losing ~30 minutes of aggregate compute
per eviction — acceptable only if evictions are rare. When they aren't, add
intra-sub-branch checkpointing (periodic state flush within the branch, then
resume from the saved frontier).

## Graceful shutdown is load-bearing

The solver's SIGTERM handler does real work on exit: it reads all committed
`sub_*.bin` files, merges them, deduplicates, sorts, and writes the final
`solutions.bin` + sha256. When aborting a run, always `kill -TERM` the solver
(not SIGKILL) and wait for it to finish — otherwise you lose the merged output
even though the per-sub-branch data is safe on disk.

## Two-phase deployment: enumeration VM vs merge VM

Enumeration and merge have very different resource profiles. Running both on
the same VM forces you to pay for the *union* — many cores *and* lots of RAM
— for the entire wall-clock time. Splitting them cuts spot cost significantly,
and at larger budgets (≥100T) the split becomes architecturally necessary
because no single SKU is cost-effective at both.

**STANDING POLICY (2026-04-20, corrected after a costly misprovisioning; reaffirmed 2026-08-29):**

⚠ **[NOTE 2026-08-29 — `CLAUDE.md` asserted a blanket "all VMs must be Spot" rule claiming to supersede this
section. Corrected: practice never followed it (five of seven non-orchestrator VMs are Regular), and this
split policy is the operative one. See CORRECTIONS.md]**

- **Enumeration → spot, 128 cores** (D128als_v7 westus3). Eviction-resilient (sub-branch checkpoints). Spot gives ~70-85% discount ($5.146/hr on-demand → $0.95/hr spot).
- **Merge → on-demand, RIGHT-SIZED (NOT 128 cores).** Merge is single-threaded heap-sort; 1-2 cores are used, the rest sit idle. **Size the merge VM by RAM and I/O, NOT core count.** On-demand (not spot) because merge is fragile under eviction — a mid-merge eviction costs a full re-run at 100T+ scale (5+ hours).
  - **d3 10T merge** (~89 GB pre-dedup): **D16als_v7** (16 cores, 32 GB RAM) with `SOLVE_MERGE_MODE=external`, or **D32als_v7** (32 cores, 64 GB RAM) which still needs the external path — 89 GB does not fit in 64 GB. On-demand ~$0.50-$1/hr → <$1 for 1h merge. *(This bullet previously read "D32als_v7 (32 GB RAM fits 89 GB external, 64 GB fits in-memory)", attaching two different RAM figures to one SKU and contradicting the 64 GB given for D32als_v7 in the next bullet. Corrected 2026-09-01 against the SKU→RAM table below.)*
  - **d3 100T merge** (~880 GB pre-dedup, external required): **D32als_v7** (32 cores, 64 GB RAM) is plenty — external merge streams in chunks, doesn't need to fit everything in RAM. On-demand ~$1.30/hr → ~$7 for a 5h merge.
  - **d3 1000T+** (if ever): external merge on **D64als_v7** (128 GB RAM) handles chunk sort comfortably, ~$2.50/hr.
  - **NEVER use D128als_v7 for merge.** Paying for 128 cores to run a 1-core workload is ~4× over-spend. The 2026-04-19/20 100T run's merge did exactly this: a D128 billed for a workload a D32 would have served.

**An earlier revision (2026-04-19) briefly moved merges to spot by default on the reasoning that shards persist. That rule is SUPERSEDED** — at 100T+ scale, re-running a 5-hour merge on spot eviction is worse than the on-demand premium. Revert to on-demand for merge; size it correctly instead.

**Mandatory pre-launch verification gate (every workload ≥ 1 hour):**

```bash
az vm show -g "$RG" -n "$VM" --query priority -o tsv
```

- `Spot` → OK for enumeration. Proceed.
- `<empty>` / `null` / `Regular` → OK for merge or explicit on-demand run. NOT OK for enumeration — stop, recreate the VM with `--priority Spot --eviction-policy Deallocate --max-price -1`, or escalate to the user.

**Failure case this prevents:** on 2026-04-19/20, d128-westus3 was provisioned without `--priority Spot` by an earlier autonomous session; the 100T d3 enumeration + merge pipeline (16h 48m) was launched on it without verification. The run billed at on-demand rates throughout; under the corrected policy the enumeration would have been Spot and only the merge on-demand. See [HISTORY.md](HISTORY.md) §Missteps for the full retrospective.

### Memory-budget validation for chunk-based parallel verifiers (added 2026-05-08)

Right-sizing a VM by **core count alone is insufficient** if the workload is chunk-parallel. `verify.py --jobs N` (and any future tool that splits a file into N chunks each loaded into per-worker memory) has a fundamental property: **per-worker chunk = file_size / N, total memory across N workers = file_size, regardless of N**. There's no `--jobs` value that fits in RAM smaller than the file when chunks are loaded fully.

Two consequences:

1. **Streaming reads are the standard for chunk-parallel verifiers.** A worker should bound its memory to a constant (e.g., 32 MB streaming batch) regardless of input size. Loading 6+ GB into a Python `bytes` object via `f.read(chunk_size * 32)` is banned for any workload where the file may exceed RAM.
2. **VM sizing must validate `chunk_size × N_workers ≤ available_RAM × 0.7`.** When choosing a VM for a parallel verifier, this arithmetic check catches the regime where the unpatched verifier will thrash via swap, not just slow down.

Concrete example: `verify.py --jobs 16` on a 110 GB `solutions.bin`:
- Per-worker chunk = 110 / 16 = 6.87 GB
- Total memory = 16 × 6.87 = **110 GB**
- Required VM RAM (with 30% headroom) = ~157 GB
- D16als_v7 has 32 GB → **thrashes** (empirically: 13× re-read multiplier, OOM-killed at 5h 5min)
- D128als_v7 has 256 GB → fits, no thrashing

This bit on 2026-05-08 (T9+c.1 phase 4 on D16). Patched verify.py in this repo uses 32 MB streaming batches and is no longer subject to the memory-vs-N constraint — it just needs cores. But the patched verifier is the floor: any chunk-parallel verifier added later should follow the same streaming pattern.

**Rule of thumb for VM-sizing decisions:**

- Single-thread merge: pick the smallest SKU that has enough RAM for the merge buffer (`SOLVE_MERGE_CHUNK_GB` × 2). D8/D16 are usually right.
- Single-thread [`solve --verify`](SOLVE_C_CLI.md#--verify) (C-side): RAM doesn't matter (mmap + sequential read). Smallest SKU is fine. Disk speed (Standard HDD ~85 MB/s) dominates wall time — ~21 min for a 100T-scale 109.8 GB `solutions.bin`. This is the fast single-threaded check; `verify.py --jobs 1` is CPU-bound and two orders of magnitude slower (see §Sizing rule for verify.py).
- Parallel `verify.py --jobs N`: with the streaming patch, ~32 MB × N for memory; mostly CPU-bound now. Match N to cores to maximize throughput. **For 100T-scale (3.43B records), expect ~3h on 16 cores at ~19k records/sec/worker; ~12h on 4 cores; ~46 min on 64 cores.** **For 560T-scale (10.525B records, 3.07× 100T), projection at the linear regime: ~9h on 16 cores, ~5h on 32 cores, ~2.4h on 64 cores.** Important caveat: verify.py's per-record decode path is **pure Python at every sha** — the only numpy import in the file is inside `check_t5_c3` (the T5/C3 recompute, unrelated to record verification), so installing numpy does not speed record verification up. The 560T campaign did observe roughly a 3× shortfall against the projected 19k records/sec/worker rate, but that shortfall was **misattributed** to a missing numpy package; disk contention (see §HDD-IOPS contention below) is the leading candidate, and the 19k projection itself may be optimistic. Budget from a measured rate on your own hardware, not from a package install.

Don't reflexively right-size for a single-thread phase and then run a multi-core verify on the same too-small VM. Either re-size for the verify phase, or pick a VM that fits both — the cost delta is usually <$3 over a multi-hour campaign.

### HDD-IOPS contention vs CPU-parallel scaling (added 2026-05-10)

The memory-budget rule above tells you when verify.py won't OOM. It doesn't tell you when verify.py will be slow due to disk contention. These are separate failure modes.

**Empirical finding from T9+d phase 9 (2026-05-10):** scaling `verify.py --jobs N` from 16 (D16) to 128 (D128) on the SAME Standard HDD did NOT yield 8× speedup. Aggregate disk read collapsed from ~9.9 MB/s on D16 (--jobs 16) to ~15 MB/s on D128 (--jobs 128) — only 1.5× improvement vs CPU-parallel projection of 8×.

**Root cause:** Standard HDD does ~80 random IOPS. With 128 workers reading from 128 disjoint file offsets simultaneously, the disk spends most of its time seeking. Per-worker read rate degrades from ~0.62 MB/s (at N=16) to ~0.12 MB/s (at N=128) — a 5× per-worker slowdown.

**Sweet spot for parallel verify on Standard HDD: ~16-32 workers.** Past 32, IOPS contention dominates CPU parallelism and additional cores deliver diminishing returns. Past 64, returns are essentially zero.

**To go faster than the ~16-worker plateau:**
- Use Premium SSD scratch (high random IOPS — Premium SSD does 5,000+ IOPS, two orders of magnitude better)
- Or restructure verify.py to use single-stream sequential reads with worker-pool processing (reader thread feeds N CPU-bound worker threads from a queue) — would let the reader saturate sequential HDD throughput at ~150 MB/s and CPU workers process from memory

**Cost impact this campaign:** D128 was provisioned for the 8× speedup that didn't materialize. Overspend versus the D32 sweet spot.

**Sizing rule for verify.py (revised):**

100T-scale (3.43B records, on Standard HDD scratch):

- Single-thread (`--jobs 1`) on D2/D4: **~50 h** for 100T — CPU-bound, not
  disk-bound (3.43B records ÷ ~19k records/sec/worker = ~50 h; measured
  single-worker throughput on a small file is ~27k records/sec, giving ~35 h).
  The ~21 min figure this row used to carry is the *C-side* number
  (109.8 GB ÷ ~85 MB/s of Standard HDD read) and belongs to the mmap'd C
  verifier. For a single-threaded disk-speed check, use
  [`solve --verify`](SOLVE_C_CLI.md#--verify), not `verify.py --jobs 1`.
- `--jobs 16` on D16: ~3h (CPU-bound at ~620 KB/sec per worker after the streaming patch)
- `--jobs 32` on D32: ~1.5h (sweet spot)
- `--jobs 64` on D64: ~75 min (slight IOPS contention)
- `--jobs 128` on D128: ~2-3h (severe IOPS contention — DO NOT USE on Standard HDD)
- `--jobs 128` on D128 with Premium SSD scratch: ~25 min (estimated, not yet measured) — would require an upfront copy from Standard HDD to Premium SSD scratch (~25 min for 110 GB)

560T-scale (10.525B records, 3.07× the 100T workload — projection at the linear regime, on Standard SSD scratch as in the 2026-06-08 campaign):

- `--jobs 16` on D16: ~9h projected (the in-flight campaign actual on D16 ran roughly 3× slower than this projection — see the attribution note above; it is not a numpy effect)
- `--jobs 32` on D32: ~5h projected
- `--jobs 64` on D64: ~2.4h projected (planned post-warm-copy verify run for 560T)
- `--jobs 128` on D128: ~2h projected (still sub-linear above D64 per the 100T finding)

For ROAE 100T-scale verify on Standard HDD, **D32 is the empirical optimum** under the current verify.py design. For ROAE 560T-scale verify on Standard SSD, the disk-IOPS contention is less severe than HDD; D64 is the recommended sweet spot (1-3h wall, ~$0.50-1.50 Spot cost). If verify.py is rewritten to use a reader-thread design, D128 becomes optimal again at both scales.

### Quota tracking — deallocated VMs still consume quota (added 2026-05-10)

**Standing rule:** Azure VM `deallocate` stops compute billing but does NOT release the vCPU quota allocation. The VM must be DELETED (with disk preservation by detach-before-delete) to free quota.

**Failure mode this prevents:** during T9+d phase 9 provisioning (2026-05-10 02:36 UTC), `az vm create --size Standard_D128als_v7` failed with `QuotaExceeded`: Current Limit 130 vCPU, Current Usage 16 vCPU, Required 144. The 16 came from `v1-recovery-d16-westus3` — the T9+c.1 D16 that had been deallocated 18+ hours earlier when its work completed. Deallocation freed compute billing but NOT quota.

**Pre-flight before any large `az vm create`:**

```bash
# Free quota for the new VM. Quota is accounted in CORES, so `USED` must be a
# core count — do NOT count VM rows (`az vm list | wc -l`), which under-counts
# by the per-VM core count and makes the check fail OPEN. `currentValue` from
# `az vm list-usage` is the reserved-core figure and already includes
# deallocated VMs, which is exactly what this pre-flight is about.
REGION=<region>
NEED=<new-VM cores>
BUCKET=standardDalsv7Family        # on-demand/Regular bucket for the Dals_v7 family
# For a Spot create, use the low-priority bucket instead — they are separate
# quotas (see §Quota accounting below):
#   BUCKET=$(az vm list-usage -l "$REGION" \
#     --query "[?contains(name.value,'lowPriority')].name.value | [0]" -o tsv)
USED=$(az vm list-usage -l "$REGION" \
  --query "[?name.value=='$BUCKET'].currentValue | [0]" -o tsv)
LIMIT=$(az vm list-usage -l "$REGION" \
  --query "[?name.value=='$BUCKET'].limit | [0]" -o tsv)
# az renders a null result as the string "None"; a broken query must ERROR, not pass.
case "$USED$LIMIT" in
  ''|*[!0-9]*) echo "QUOTA_PREFLIGHT=ERROR (non-numeric: USED='$USED' LIMIT='$LIMIT')"; exit 1;;
esac
if [ $((USED + NEED)) -le "$LIMIT" ]; then
    echo "QUOTA_PREFLIGHT=OK ($USED + $NEED <= $LIMIT cores)"
else
    echo "QUOTA_PREFLIGHT=FAIL ($USED + $NEED > $LIMIT cores) — delete deallocated VMs first"
    exit 1
fi
```

**Deallocated-VM cleanup workflow (when freeing quota):**
1. Confirm the VM is no longer needed (no open work, archive complete)
2. Detach data disks (preserves them as Unattached)
3. Capture VM cleanup metadata (NIC, OS disk ID) for cascade
4. `az vm delete --yes`
5. Cascade: delete NIC, public IP, OS disk
6. Verify: `az vm list-usage` shows freed quota

The `feedback_keep_managed_disk.md` rule still holds — never delete data disks. Only delete the VM and its OS disk (which contains nothing campaign-related).

### Spot host CPU-frequency throttling — silently 5× slower (added 2026-05-12)

**Failure mode:** on 2026-05-12, a freshly-provisioned `Standard_D128als_v7` Spot VM in westus3 (host: AMD EPYC 9V45) ran a `solve 0 128` enum at **230 M nodes/s** — 5.6× slower than the established baseline of **1293 M/s** for the same SKU on a healthy host. The slowdown was scale-emergent (rate looked normal at smaller scales, was glaring at full-throttle 128-thread enum) and would have caused a cascade overspend if undetected.

**Root cause:** the host's CPUs were parked at **~600 MHz** (visible via `cat /proc/cpuinfo | grep MHz`), versus the expected **2.5-3.5 GHz** boost frequency. Inside the guest:

- `mpstat` showed **0% steal time** (not a noisy-neighbor problem)
- 100% user CPU + reasonable load average — looked busy
- `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` **did not exist** in this guest kernel — the cpufreq subsystem isn't exposed, so the throttling cannot be diagnosed or fixed from inside the VM
- The frequency was determined by the host hypervisor's power state for this physical host — invisible to the guest, no recourse

The most surprising property: **the slowdown is invisible to all standard busy-VM signals.** Top, mpstat, iostat, vmstat all show "healthy" output. Only `cat /proc/cpuinfo | grep MHz` reveals the true frequency, and only the observed solve.c throughput rate confirms the impact.

**Mandatory pre-launch check for every fresh Azure VM that will run enum work:**

```bash
# Right after SSH succeeds, before launching enum:
FREQ=$(grep "cpu MHz" /proc/cpuinfo | head -1 | awk -F: '{print $2}' | xargs printf '%.0f')
if [ "$FREQ" -lt 2000 ]; then
    echo "FAIL: CPU at ${FREQ} MHz; D128als_v7 should be 2500-3500 MHz on healthy host. Re-provision."
    exit 1
fi
echo "OK: CPU at ${FREQ} MHz"
```

**Resolution when triggered:** there is no in-VM remediation. The fix is:

1. `pkill -9 -f solve` (kill any in-flight work)
2. Detach scratch disk(s): `az vm disk detach`
3. Delete the VM + NIC + PIP (keep data disks): `az vm delete --yes`; cascade NIC + PIP delete
4. Re-provision a fresh Spot D128als_v7 — Azure will (probably) place it on a different host
5. Re-attach scratch, re-run the CPU-frequency check

A 2026-05-12 cascade re-provision drew a host running at **3562 MHz boost** (1293 M/s rate, baseline-matching) on the second attempt. Empirically the second-draw success rate is high but not guaranteed; check on every fresh VM regardless.

**Cost of detection vs. cost of not:** a 5-line script run once per provisioned VM is essentially free. Skipping the check on a single 5.6T run on a throttled host wastes ~$5; on a 100T run it wastes hours of wall and $30+. **Always check before launching long enum work.**

The actual SKU underlying Azure's `D128als_v7` is AMD EPYC 9V45 (96-core, 128-vCPU). Project memory previously claimed "Zen 5 Turin" for this family — that was incorrect. The 9V45 is a cloud-optimized AMD SKU; per-core performance at full boost is comparable to (slightly below) Genoa for our DFS-heavy workload, *as long as the host is not throttling*.

### Disk tier matters — more than you might think

`solver-data` is deliberately **Standard_LRS** (HDD-tier). Standard HDD has
IOPS capped at 500 and throughput ~60 MB/s regardless of disk size. That
choice is right for long-term shard *storage* (~$3/month for 300 GB) but
wrong for merge-time *compute*. Empirical data point from the 2026-04-18
10T depth-3 external re-merge:

| What | Value |
|---|---|
| Input | 56,404 sub_*.bin shards, 83 GB, 2.77B records |
| Disk | Standard_LRS 300 GB, ~60 MB/s throughput cap |
| Merge mode | `SOLVE_MERGE_MODE=external` (4 GB chunks) |
| Phase 1 (read shards, sort chunks, write temp files) | ~6-7 min per 4 GB chunk × 20+ chunks ≈ 2-3 hours |
| Phase 2 (k-way merge + write solutions.bin) | ~30-45 min |
| Total wall | ~3-4 hours |
| F64 on-demand cost at $3.87/hr | ~$12-15 |

Compared to the alternatives on various hardware (updated 2026-04-19 with measured D128 data):

| Strategy | Wall time (10T) | Cost | Trade-off |
|---|---|---|---|
| F64als_v6 + external merge on Standard_LRS HDD (above, legacy) | 3-4 h | $12-15 on-demand | cheapest disk, slow merge; F64 retired |
| F64als_v6 + in-memory merge (~89 GB fits in 128 GB RAM) | ~30 min | ~$2 on-demand | fast; F64 retired |
| **D128als_v7 westus3 + in-memory heap-sort merge** | **~52 min** | **~$1.46 spot** | measured 2026-04-19; new default |
| **D128als_v7 westus3 + external merge on Premium SSD (P20)** | **~43 min** | **~$1.26 spot + $0.05 SSD** | measured 2026-04-19; faster than in-memory at 10T |
| D64als_v7 westus3 + in-memory merge (128 GB RAM, perfect fit) | ~52 min | ~$0.43 spot | cheaper than D128 — single-threaded merge ignores core count |
| Premium SSD for `solver-data` permanently | (same as in-memory) | $3/month → $40/month | wasteful; SSD only needed during merge |

### Recommendations by dataset scale

- **Input < 70% of merge-VM RAM.** Default (auto) selects in-memory. Fastest.
- **Input ≥ 70% of merge-VM RAM, or running on small VM.** Use external merge.
  - On Standard HDD: usable but slow. Budget 3-4 hours for 10T, proportionally
    longer at 100T. Only viable when cost-minimizing is the priority over
    wall time.
  - On Premium SSD (recommended for any merge > 1 hour on HDD): attach a
    temporary Premium-tier data disk (P20 or P30), point `SOLVE_TEMP_DIR` at
    it, run the merge. Solutions.bin lands on the CWD (which stays on
    solver-data), temp chunks land on the SSD. After the merge completes,
    detach and DELETE the SSD — shards and output are already on
    solver-data. Pennies in prorated Premium cost for 3-4× throughput.

### Premium-SSD-attach-for-merge — the design pattern

**Architectural idea.** External merge has three kinds of I/O: *shard reads*
(long, sequential, from archival storage), *chunk write/read cycles* (the
external algorithm's temp storage — written in Phase 1, read back in Phase
2), and *output writes* (the final deduped `solutions.bin`). The shards and
final output want to live on cheap durable archival storage (solver-data,
Standard HDD, ~$3/mo for 300 GB). The chunk cycle wants to live on fast
temp storage that can be destroyed after the merge.

Putting everything on the HDD forces the HDD to interleave all three
streams on one disk head, where seek contention (not raw throughput) is the
bottleneck. Putting chunks on a separate Premium SSD collapses the HDD's
role to two linear sequential streams (shard read, then output write) and
gives the chunk cycle its own fast device. On the 10T d3 merge this moved
wall time from ~3 hours to ~30-45 min at roughly the same total cost.

**When the pattern is needed.** Any external merge where wall time on HDD
would exceed ~1 hour. That is any merge where input ≥ 70% of merge-VM RAM
(which forces external mode) at ≥ 10T scale. For smaller runs that fit
in-memory, the pattern is unnecessary — auto mode selects in-memory and
neither the SSD nor external mode is involved.

**When the pattern is strictly necessary.** 100T and beyond. In-memory is
not viable (~830 GB buffer requires M-series VMs at $15-30/hr — 10× the
cost for marginal benefit). External merge is forced; running external on
HDD at that scale projects to 30+ hour wall times. Premium SSD takes it to
~3 hours.

**The cost economics.** SSD is billed by capacity per hour. A 2-hour P20
(512 GB) attached to a 10T merge costs ~$0.22 in disk. A P40 (2 TB) for a
3-hour 100T merge costs ~$1.25 in disk. Negligible against VM cost, and
the SSD is destroyed the moment the merge completes — no ongoing storage
bill. That's why this is the right pattern instead of permanently
upgrading solver-data to Premium (which would cost ~$40/month for a disk
that sits cold 99% of the time).

**The rule of thumb.** Shards and output live on Standard-tier `solver-data`
forever. Premium SSD only exists for the duration of a merge.
`SOLVE_TEMP_DIR=/mnt/merge-scratch` routes chunk I/O to the SSD during the
merge. Both final files (`solutions.bin` + `solutions.sha256` +
`solutions.meta.json`) write to CWD, which should be `solver-data` so they
archive automatically.

### Concrete workflow

The pattern: **keep shards and final output on Standard-tier `solver-data`
for cheap archival; attach a Premium SSD only for the duration of the merge
so its temp I/O runs at SSD speed; destroy the SSD afterward.**

```bash
# 1. Provision a Premium SSD. P20 = 512 GB ($76/month base, ~$0.11/hour).
#    For a 10T merge, P20 is plenty (~80 GB of temp chunks + slack).
#    For 100T, use P40 (2 TB). Cost scales with size, NOT with I/O.
SIZE_GB=512                      # P20; a single parameter for BOTH the create
                                 # and the step-3 selector, so they cannot drift
az disk create -g RG-CLAUDE -n merge-scratch -l westus2 \
  --size-gb "$SIZE_GB" --sku Premium_LRS --no-wait

# 2. Attach to the on-demand merge VM (after it's up).
az vm disk attach -g RG-CLAUDE --vm-name <merge-vm-name> \
  --name merge-scratch --lun 1

# 3. On the VM: identify disk by SIZE + empty-FS state, format,
#    mount, own. NEVER use `mkfs -F` (banned project-wide after the
#    2026-05-06 wipe; see CLAUDE.md §"Disk-handling safety").
#    The pattern below identifies the new Premium SSD as the unique empty
#    disk of exactly $SIZE_GB. If 0 or 2+ match → hard-fail. $SIZE_GB is
#    passed to the remote shell so the size predicate can never disagree
#    with the `--size-gb` used in step 1.
ssh solver@<vm-private-ip> "SIZE_GB=$SIZE_GB bash -s" <<'REMOTE'
  set -euo pipefail
  EXPECTED_BYTES=$(( SIZE_GB * 1024**3 ))
  DEV=$(lsblk -bno NAME,SIZE,FSTYPE | \
        awk -v sz="$EXPECTED_BYTES" '$2==sz && $3=="" {print "/dev/" $1}')
  COUNT=$(echo "$DEV" | grep -c .)
  [ "$COUNT" -eq 1 ] || { echo "FATAL: expected 1 empty ${SIZE_GB} GB disk, found $COUNT"; exit 1; }
  # Belt-and-suspenders: refuse if any blkid output (existing FS).
  blkid "$DEV" >/dev/null 2>&1 && { echo "FATAL: $DEV has existing filesystem"; exit 1; }
  sudo mkfs.ext4 -q "$DEV"          # NO -F flag
  sudo mkdir -p /mnt/merge-scratch
  sudo mount "$DEV" /mnt/merge-scratch
  sudo chown solver:solver /mnt/merge-scratch
REMOTE

# 4. Run the merge with SOLVE_TEMP_DIR pointing at the SSD.
#    CWD stays on /data (solver-data) so shards and final output live there.
ssh solver@<vm-private-ip> '
  cd /data
  SOLVE_MERGE_MODE=external SOLVE_TEMP_DIR=/mnt/merge-scratch ~/solve --merge
'

# 5. solutions.bin + .sha256 + .meta.json are now on /data (solver-data).
#    temp_sorted_*.bin files were on the SSD and have been deleted by solve
#    at end of merge. Nothing of value remains on the SSD.

# 6. Detach + delete the SSD.
az vm disk detach -g RG-CLAUDE --vm-name <merge-vm-name> --name merge-scratch
az disk delete -g RG-CLAUDE -n merge-scratch --yes --no-wait
```

**Cost accounting.** Premium SSD is billed per-hour, but Azure bills at a
minimum of one hour of usage per disk lifetime. A 2-hour merge on a P20:
~$0.22 in disk cost. A P40 (2 TB) for a 100T merge: ~$1-2 for the disk.
Negligible against the VM cost.

**Why this matters for 100T and beyond.** The 10T merge fits in-memory on
F64; the Premium-SSD pattern is optional at that scale. But 100T cannot be
done in-memory on any cost-practical VM (see below), so the Premium-SSD
pattern becomes the path forward, not an optimization.

### 100T and beyond — in-memory is not an option

Extrapolating: 100T enumeration produces ~27.7B pre-dedup records = ~830 GB
of input. In-memory merge would need an **M-series VM (2-4 TB RAM, ~$15-30/hr)**
— technically possible but 10× the cost for marginal benefit. The practical
path at 100T is **external merge on Premium SSD**:

- F64als_v6 (128 GB RAM) + Premium SSD P40 (2 TB, 250 MB/s) as temp dir
- `SOLVE_TEMP_DIR=/mnt/merge-scratch SOLVE_MERGE_MODE=external`
- ~2.7 TB total I/O (read shards once, write chunks, read chunks, write output)
- ~3 hours wall time, ~$13-15 total (VM + prorated disk)

The in-memory path effectively tops out around the 10T-at-our-current-VM-size
combination. Everything larger is external-merge-with-SSD territory.

### Known scale limits of external merge

Two compile-time / runtime limits cap how far external merge can scale:

| Limit | Source | Ceiling at default | Mitigation |
|---|---|---|---|
| `MAX_SORTED_CHUNKS = 4096` | `solve.c` constant | 4096 × 4 GB = **16 TB pre-dedup** (~2,000T node enumeration at d3 rates) | Raise `SOLVE_MERGE_CHUNK_GB` (e.g., to 16 or 32) — multiplies ceiling; no code change. Or bump the constant (one-line source change) |
| `ulimit -n` (open FDs) | OS per-shell default | Linux default 1024 → ~500T before hitting it | `ulimit -n 16384` before running [`./solve --merge`](SOLVE_C_CLI.md#--merge) |

**Implications.** At any enumeration scale we're realistically considering
(10T through 1,000T), both limits have comfortable headroom with default
settings. The first limit we'd hit in practice is `ulimit -n` (around 500T);
that's a one-line shell setting. Actually running into `MAX_SORTED_CHUNKS`
would require ~2,000T enumerations, which are neither cost-practical nor
currently planned.

The solver emits a clear error with the mitigation if either limit is hit —
no silent failure. For runs beyond 1,000T, it's good hygiene to both
`ulimit -n 16384` and set `SOLVE_MERGE_CHUNK_GB=16` before the merge; that
combination gives an ~64 TB pre-dedup ceiling and >4096 concurrent FDs.

**Resource profile by phase:**

| Phase | Bottleneck | Scales with |
|---|---|---|
| Enumeration | cores (one pthread per `SOLVE_THREADS`, ~21M nodes/thread-sec) | node budget (linear) |
| Merge | RAM (`malloc(total_records × 32)`) | unique solution count |

Enumeration RAM is flat *in the node budget*, but it scales with thread count
and hash-table size: `threads × 2^SOLVE_HASH_LOG2 × 32 B` is committed at
start-up, and the tables auto-resize upward at 75% load. At current defaults
(`SOLVE_HASH_LOG2=24` → 512 MB/thread; see §Hash table sizing) a 128-thread
enumeration commits **64 GiB** before it walks a node — the 2026-04-19 100T d3
run's own log records `Initial hash memory: 65536 MB (128 threads x 512 MB,
auto-resize at 75%)`
(`runs/20260419_100T_d3_d128westus3/enum_output.log.gz`). Do not provision a
"lean" enumeration VM off a fixed RAM figure: compute it from the thread count
you intend to run, or lower `SOLVE_HASH_LOG2` (22 → 128 MB/thread, 20 → 32
MB/thread). Merge RAM scales with output size.

**Two-phase pattern:**

1. **Enumeration VM** — lean and core-dense. Writes `sub_*.bin` shards and
   `checkpoint.txt` to the managed data disk. Tears down on completion.
   VM choice: D128als_v7 Spot in westus3. (F-series is BANNED on this
   project since 2026-04-19 — see §Ad-hoc VM lifecycle rules, rule 1.)
2. **Data disk survives** the teardown. Shards are the primary artifact; the
   final `solutions.bin` is derived.
3. **Merge VM** — separate and right-sized (by RAM and I/O, not cores),
   launched only when shards are complete. Runs `cd /data && ./solve --merge`,
   writes the merged output back to the same disk, verifies sha256, tears down.
   ⚠ **[CORRECTED 2026-09-01 — this read `./solve --merge /data/solutions.bin`,
   which does not do what it looks like.]** `--merge` takes **no arguments**: it
   sets `arg_offset = argc`, so every following argument is consumed and
   silently discarded — no error, no warning. It then scans the **current
   working directory** for `sub_*.bin` shards and writes `solutions.bin` and
   `solutions.sha256` there. Run from `~` on a fresh merge VM, the old command
   therefore finds no shards at all, or — worse — merges whatever stale shards
   happen to be in the CWD, and the operator has a path in their shell history
   that appears to say otherwise. **`--merge` is CWD-relative; `cd` to the shard
   directory first.**
   VM choice: a **right-sized on-demand D-series** VM per §Standing policy
   — D16/D32als_v7 for 10T–100T, D64als_v7 at 1000T+. Memory-optimized
   E-/M-series are not used here: merge is a single-threaded heap-sort sized
   by RAM and I/O, and external merge (`SOLVE_MERGE_MODE=external`, shipped)
   keeps a modest SKU sufficient by streaming chunks instead of buffering
   `unique_records × 32 bytes` in RAM.

**Cost illustration (westus3 D-series; enum on Spot, merge on-demand — 2026-04-19 measured + projected):**

| Budget | Enum wall | Enum VM | Enum cost | Merge VM | Merge cost | Two-phase total |
|---|---|---|---|---|---|---|
| 10T | **1h 23m** (measured) | D128als_v7 spot ($1.70/h) | **~$2.35** | D16als_v7 on-demand (~$0.50/h) for ~50 min | ~$0.42 | **~$2.77** |
| 100T | **~14h** (projected) | D128als_v7 spot | ~$24 | D32als_v7 on-demand (~$1.30/h) + P40 SSD for ~2-5h (external) | ~$5-9 | **~$29-33** |
| 1000T | ~6-7 days | D128als_v7 spot | ~$250 | D64als_v7 on-demand (~$2.00-2.50/h) + P40 SSD for ~30h (external, parallel chunks) | ~$75-90 | **~$325-340** |

The merge column follows §Standing policy: **on-demand and right-sized, never
D128 and never Spot.** An earlier revision of this table prescribed Spot merges
and D128 merges — both are withdrawn; the merge-VM wall times are unchanged
because merge is single-threaded and ignores core count.

Legacy F64als_v6 westus2 figures (for historical reference): 10T ~$9 (6h enum + 30min merge), 100T was projected ~$175 with split (never run at scale post-pivot). F64 is retired 2026-04-19. See `DSERIES_ROI_REPORT.md` (outside repo) for full comparison.

Savings scale with wall-clock time; for ≥100T external merge with Premium SSD is strictly required (data volume exceeds RAM). For 1000T, parallel-chunk external merge on large Premium SSD is the path.

**Orchestration requirements for the two-phase pattern** (most already exist):

- Enumeration monitor detects completion and tears down the enumeration VM.
  In split mode the enum process returns *before* the completion report and
  before `solve_results.json` is written (the `SOLVE_SKIP_AUTOMERGE` early
  return), so that file never appears on the enum VM: key on solver exit rc=0
  **plus** the `SOLVE_SKIP_AUTOMERGE set; skipping bundled merge` line in
  `solve_output.txt` **plus** shard/`shard_manifest.txt` filesystem state — or
  on the supervisor-written `done.marker` / `fail.marker` pair. The
  `SEARCH_COMPLETE` status field in `solve_results.json` is the *single-VM*
  (bundled-merge) signal, and in split mode it is written by the merge VM when
  the merge finishes. Never key on stderr regex (§Lessons item 4).
- Managed data disk survives. Run-ID file on disk identifies the run.
- A separate merge script provisions the merge VM, attaches the same disk,
  verifies the run-ID matches, runs `./solve --merge`, copies the resulting
  `solutions.bin` + `solutions.sha256` locally, verifies by re-hashing,
  tears down the merge VM.
- Both scripts share the same lifecycle-event log for eviction telemetry.

**Disk sizing for two-phase:**

The data disk must hold (`sub_*.bin` shards) + (`solutions.bin`) simultaneously
during the merge. Size it from the **inputs**, not from the output:

```
disk ≥ (pre_dedup_records × 32 B × framing_factor + final_output_size) × 1.5
```

`framing_factor` is 1.0 for raw shards (`SOLVE_COMPRESS=0`, and everything
written before #169); gz-framing is the default since #169 and shrinks the shard
term, but by a ratio you should *measure* on a pilot run rather than assume.

An earlier revision of this rule said "effectively 2× the final output size".
That is wrong at d3 scale and this document's own measurements refute it: the
2026-04-18 10T d3 re-merge (§Disk tier matters) read **56,404 shards, 83 GB,
2.77B pre-dedup records** against a ~24 GB `solutions.bin` — the shards alone
are ~3.5× the output, so the shard term dominates and "2× output" under-sizes
the disk before the merge writes a byte.

| Budget | Pre-dedup input (raw) | Est. `solutions.bin` | Disk size (raw-safe) |
|---|---|---|---|
| 10T | 2.77B records, **83 GB measured** | ~24 GB | **~160 GB** |
| 100T | ~27.7B records, ~830 GB (§100T and beyond) | ~60–120 GB | **~1.4 TB** |
| 1000T | ~277B records, ~8.3 TB (linear extrapolation) | ~150–250 GB | **~13 TB** |

At 1000T the disk itself, not the VM, becomes the binding constraint — the raw
figure exceeds a single 2 TB managed disk, so plan for gz-framed shards plus a
multi-disk or staged-archive layout rather than one volume.

Failure direction is loud, not silent: running out of space mid-merge is ENOSPC,
the shards survive on disk, and recovery is a single
`az disk update --size-gb N` + `resize2fs` inside a VM after attach, then
re-merge. No data loss. Preferring the raw-safe number up front costs pennies of
storage against an aborted multi-hour merge.

**Operational runbook for canonical enumerations ≥11.2T:**

The two-phase architecture above is the right *architecture*. The
*operational* pattern — pre-flight checklists, recovery procedures
for the half-dozen failure modes that have actually occurred in
practice, scale-specific guidance for 100T and 560T — lives in the
**`roae-private/CANONICAL_PIPELINE_RUNBOOK.md`** runbook (private staging
repo). That runbook is the single source of truth for canonical
runs and supersedes earlier ad-hoc scripts. The 2026-05-16/17 v2
11.2T saga (~$18 spent across four attempts vs ~$5 expected
first-shot) was the forcing function for the runbook's creation;
the failure modes it documents have all been seen, and the
mitigations are tested. Key non-obvious constraints captured there:

- **Enum OS disk: explicit `--storage-sku StandardSSD_LRS`.** Azure
  defaults `s`-suffix VM sizes to Premium_LRS, which is wasted on
  CPU-bound enum.
- **Shards belong on the attached managed disk (solver-data-westus3),
  not the enum VM's OS disk.** Lose-the-VM-lose-the-shards is what
  drove half the saga's overrun.
- **Trap discipline: NEVER `teardown_enum` in the ERR trap.**
  Phase 2 errors should preserve the enum VM (with shards) so
  recovery costs ~$0.50 not ~$4.
- **`curl -T file` streaming PUT for large blobs.** `curl --data-binary
  @file` OOMs at ~2 GB regardless of VM RAM.
- **Mount logic must handle existing-ext4** (solver-data has empty
  ext4 from the 2026-05-06 incident wipe; subsequent re-population
  filled 120 GB of operator data into top-level dirs). Always write
  canonical outputs to a `$ARCHIVE_PREFIX/` subdirectory.
- **Mandatory $0.02 D2 pre-flight** before any 4h+ enum: validate
  the disk-attach + mount + upload syntax on a throwaway VM with
  the actual managed disk before committing to the critical path.

The runbook also documents `safe_disk_setup.sh` usage and includes
the post-incident disk-handling rules (`feedback_disk_safety.md`,
banned `mkfs -F`, UUID-based disk identification).

## Lessons from the 2026-04-14 10T bugfix run and recovery

1. **A reproducible sha256 is not a proof of correctness.** The solver's `sub_*.bin` filenames collided — 3030 sub-branches shared only 64 unique filenames, so later writes silently overwrote earlier solutions. Every run produced the same (wrong) sha256 because the bug was deterministic. "It reproduces, so it's right" was exactly the wrong conclusion. Always cross-check output *shape* (record counts, file counts, per-sub-branch yields) against what the architecture predicts, not just sha256 stability.

2. **Silent `fwrite` failures are the worst class of bug.** The 10T run's final `solutions.bin` was truncated from 23.7 GB to 8 GB because the managed disk ran out of space mid-write. The `fwrite` return value was never checked. `solutions.sha256` was computed *after* the truncation so the sha validated the corrupt file against itself — no sign of error until a human noticed the size didn't match the record count in `solve_output.txt`. Audit every `fwrite`/`fopen`/`fclose` return value; end-to-end verification must compare in-memory computation to reread-from-file.

3. **Disk capacity must be sized for inputs *plus* outputs.** 32 GB was adequate for `sub_*.bin` files (~23 GB) but not for the final `solutions.bin` (~23.7 GB) on the same disk. Preflight: free disk ≥ estimated_output × 1.5 before any long run. If the preflight fails, either resize the disk first or abort.

4. **Monitor completion detection must match the solver's actual output format.** The 10T monitor greped for `"SEARCH COMPLETE\|TIMED OUT"` but the solver writes `"SEARCH_COMPLETE"` (underscore, machine-readable) to `solve_results.json`. Monitor concluded the run had failed, tore down the VM, and reported an error — while `solutions.bin` sat safely on the preserved managed disk. Lesson: monitors should consume stable machine-readable markers (status field in JSON) rather than stderr text whose format evolves.

5. **Managed disks preserved = the win condition for every class of failure.** Eviction, truncation, regex bug — all three recovery scenarios in this project were saved by `solver-data` surviving VM teardown. Never delete a data disk. Orphan OS disks from deleted VMs are a separate matter: clean those up.

6. **Azure zones bite.** The `solver-data` disk is non-zonal; the primary `claude` VM is in zone 2. Non-zonal disks cannot attach to zonal VMs (Azure returns `BadRequest`). For recovery VMs that need `solver-data`, provision as regional (no zone specified). Related: `az vm create --ssh-key-values` has a JSON-parser bug; `az rest --method PUT` is the reliable path.

7. **Azure resource teardown is dependency-ordered.** VM → NIC → public-IP → NSG → VNet, sequential. Parallel deletes all return exit 1 because dependents still hold references. Orchestrators must serialize.

## Chaining multiple runs on the same managed disk

When running depth-3 followed by depth-2 (or any sequence of runs that should
coexist on the same disk), use the **sequential monitor pattern**: let each
monitor run to natural completion (merge, archive, teardown), then start the
next. Do NOT use a supervisor that kills monitors mid-merge — this causes race
conditions (observed: supervisor killed monitor during merge, solutions.bin
was empty, sha was hash of empty file).

Between runs, rename any output you want to preserve:
1. Let run A's monitor complete (writes `solutions.bin`, archives, tears down VM)
2. Create a temp VM, attach the managed disk, rename `solutions.bin` to
   `solutions_A_<sha8>.bin` (the next run's wipe pattern won't match this name)
3. Tear down temp VM
4. Launch run B's monitor (provisions new VM, attaches same disk, wipes stale
   run artifacts, runs solver)

The `rm -f /data/sub_*.bin /data/solutions.bin ...` wipe is pattern-based —
files with names outside the patterns survive.

## Solver-launch SSH detachment

The remote `nohup ~/solve ... &` does NOT reliably release the SSH channel.
The launching SSH hangs indefinitely, blocking the monitor from entering its
poll loop. **Required form:**

```bash
timeout 15 ssh -n -i $KEY -o StrictHostKeyChecking=no "solver@$IP" \
    "cd /data && setsid nohup ~/solve $TIMEOUT > solve_output.txt 2>&1 < /dev/null &" \
    < /dev/null 2>/dev/null
```

- `setsid` puts solve in its own session (detached from SSH's process group)
- `timeout 15` kills the local ssh if the remote shell won't release the channel
- The next monitor step probes `pgrep -x solve` via a fresh SSH

## Hash table sizing

`SOLVE_HASH_LOG2` controls the initial per-thread hash table size (default
2^24 = 16M slots, 512 MB/thread). Tables auto-resize at 75% load — the
initial size is a starting point, not a ceiling. For most runs the default is
fine. For VMs with limited RAM, reduce to 22 or 20.

The hash table guarantees zero silent drops at any scale. If a resize fails
(OOM), the solver aborts with a clear error — never silent data loss.

## Pre-launch checklist

- [ ] Previous run state cleaned or explicitly resumed (run_id guard). "Cleaned"
      means the **whole** resume surface: `sub_*.bin`, `sub_*.dfs_state`,
      `sub_*.bin.budget`, `sub_*.bin.provenance.json`, `sub_ckpt_*`,
      `sub_flush_chunk_*`, `shard_manifest.txt`, `checkpoint.txt`,
      `checkpoint_t*.txt`, `progress.txt`, and the `solutions.*` outputs — see
      §Deployment lifecycle step 6. A partial wipe resumes silently and reports
      success.
- [ ] Persistent volume mount verified
- [ ] Free disk space ≥ estimated output × 1.5 (inputs + outputs both fit)
- [ ] Free RAM ≥ estimated working set (merge needs ~uniqueN × 32 bytes in memory)
- [ ] `run_id.txt` written before solver start (write BEFORE wipe, not after)
- [ ] Monitor started **as a separate process** and verified with `pgrep`
- [ ] Monitor completion-detection string matches what the solver actually emits (JSON status field)
- [ ] Post-completion gates configured: `--verify` pass + hash-drop count == 0
- [ ] Sub_*.bin integrity check enabled on eviction resume (size % 32 == 0)
- [ ] Watchdog merge-phase exemption verified (don't kill solver during merge)
- [ ] Merge VM is on-demand (not spot) — merge has no checkpoint
- [ ] **Pre-launch verification: `az vm show --query priority` matches the workload type** (Spot for enum; null/Regular for merge). See §Standing policy. Skipping this gate caused the 2026-04-19/20 overspend incident.
- [ ] `--merge` code path uses canonical dedup (same as normal-mode merge)
- [ ] Cost estimate presented to user
- [ ] Output-shape sanity checks planned (record count, sub-branch file count)

---

## Appendix A: Azure spot-VM provisioning (reference example)

Concrete example of provisioning an Azure F-series spot VM with an attached
persistent managed disk. Adapt names, regions, and SKUs to your environment. All
commands assume `az login` has been completed and an SSH keypair exists (here at
`~/.ssh/f64_key{,.pub}`).

### One-time setup (per resource group)

1. **Resource group + persistent data disk.** Create the data disk *once*; it
   will outlive every spot VM that mounts it.

   ```bash
   RG=YOUR-RG
   LOCATION=westus2
   az group create -n "$RG" -l "$LOCATION"
   az disk create -g "$RG" -n solver-data \
       --size-gb 64 --sku Standard_LRS -l "$LOCATION"
   ```

   Size depends on workload: for a 10T enumeration the `sub_*.bin` files total
   ~23 GB and `solutions.bin` adds another ~24 GB. Provision with headroom
   (≥1.5× expected output total) to avoid the silent-truncation failure
   documented in the lessons section above.

### Per-run provisioning (spot VM + networking)

2. **Networking: private IP only.** Solver VMs live on the same vnet as the
   orchestrator — no public IP, no NSG, no external attack surface. The
   orchestrator SSHes to the solver's private IP directly.

   ```bash
   # One-time: create the shared vnet (orchestrator VM also on this vnet)
   az network vnet create -g "$RG" -n claude-vnet -l "$LOCATION" \
       --address-prefix 10.0.0.0/24 --subnet-name default --subnet-prefix 10.0.0.0/24

   # Per-run: NIC with private IP only (no --public-ip-address, no --network-security-group)
   az network nic create -g "$RG" -n solver-nic \
       --vnet-name claude-vnet --subnet default -l "$LOCATION"
   ```

   The orchestrator queries the private IP via:
   ```bash
   az network nic show -g "$RG" -n solver-nic \
       --query "ipConfigurations[0].privateIPAddress" -o tsv
   ```

   **Caveat:** Both VMs must share the vnet. Running from a laptop (not the
   orchestrator VM) requires either keeping a public IP or setting up vnet
   peering / jump host.

3. **Spot VM with managed-disk attached.** `az vm create` has a JSON parser bug
   when used with `--ssh-key-values` in some CLI versions; using `az rest` with
   the raw VM resource definition is the reliable path:

   ```bash
   SUB_ID=$(az account show --query id -o tsv)
   NIC_ID=$(az network nic show -g "$RG" -n solver-nic --query id -o tsv)
   DISK_ID=$(az disk show -g "$RG" -n solver-data --query id -o tsv)
   SSH_PUB="$(cat ~/.ssh/f64_key.pub)"
   SIZE=Standard_D128als_v7  # westus3; F64als_v6 legacy westus2 pattern retired 2026-04-19

   az rest --method PUT \
     --url "https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/$RG/providers/Microsoft.Compute/virtualMachines/solver-vm?api-version=2024-07-01" \
     --body "{
       \"location\":\"$LOCATION\",
       \"properties\":{
         \"hardwareProfile\":{\"vmSize\":\"$SIZE\"},
         \"priority\":\"Spot\",\"evictionPolicy\":\"Deallocate\",
         \"billingProfile\":{\"maxPrice\":0.80},
         \"storageProfile\":{
           \"imageReference\":{\"publisher\":\"Canonical\",\"offer\":\"ubuntu-24_04-lts\",\"sku\":\"server\",\"version\":\"latest\"},
           \"osDisk\":{\"createOption\":\"FromImage\",\"managedDisk\":{\"storageAccountType\":\"Standard_LRS\"}},
           \"dataDisks\":[{\"lun\":0,\"createOption\":\"Attach\",\"managedDisk\":{\"id\":\"$DISK_ID\"}}]
         },
         \"osProfile\":{
           \"computerName\":\"solver-vm\",\"adminUsername\":\"solver\",
           \"linuxConfiguration\":{\"disablePasswordAuthentication\":true,
             \"ssh\":{\"publicKeys\":[{\"path\":\"/home/solver/.ssh/authorized_keys\",\"keyData\":\"$SSH_PUB\"}]}}
         },
         \"networkProfile\":{\"networkInterfaces\":[{\"id\":\"$NIC_ID\"}]}
       }
     }"
   ```

4. **Wait for VM running, then SSH-ready.** Poll the power state, then test SSH:

   ```bash
   for i in $(seq 1 24); do
       sleep 10
       state=$(az vm get-instance-view -g "$RG" -n solver-vm \
           --query "instanceView.statuses[?starts_with(code,'PowerState')].displayStatus" -o tsv)
       [ "$state" = "VM running" ] && break
   done
   # This example is private-IP-only (step 2) — there is no public IP to query.
   IP=$(az network nic show -g "$RG" -n solver-nic \
       --query "ipConfigurations[0].privateIPAddress" -o tsv)
   for i in $(seq 1 12); do
       sleep 8
       ssh -i ~/.ssh/f64_key -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
           solver@$IP 'echo ok' 2>/dev/null && break
   done
   ```

5. **Mount the persistent disk on the VM.** The data disk's device name varies
   across reboots; scan for the partitionless ext4 volume:

   ```bash
   # OBSOLETE PATTERN — this loop violated the disk-handling safety
   # rules (CLAUDE.md §"Disk-handling safety"); preserved here as a
   # historical example of what NOT to do. The "try mount, then mkfs
   # if mount fails, on every block device that doesn't have a
   # partition table" approach uses -F to silently force-format any
   # device that isn't already mountable — which would happily wipe
   # an existing-filesystem disk if the mount step failed for
   # transient reasons (busy device, kernel state mismatch, etc.).
   #
   # Instead, use the canonical pattern in
   # `petersm3/roae-private:safe_disk_setup.sh`:
   #   - existing data disk: identify by UUID, mount-by-UUID, verify
   #     marker file (e.g., solutions.sha256)
   #   - new empty disk: identify by exact size + empty-FS state,
   #     refuse to format if blkid finds existing FS, then `mkfs.ext4`
   #     (no -F).
   ```

### Deployment lifecycle (do not delete the data disk)

6. **Run-ID guard before solver start.** Compare the disk's `run_id.txt` to the
   intended run ID and only wipe stale data if they differ; resume otherwise.

   The wipe list must cover the solver's **entire resume surface**, not just
   its shards. Anything left behind that the solver knows how to resume from
   makes a "fresh" run silently inherit prior work: it will report
   `*** SEARCH COMPLETE ***`, exit 0, and write a self-consistent sha over an
   incomplete solution set. The resume surface has grown over time
   (`.dfs_state` sidecars 2026-04-30, per-thread `checkpoint_t<N>.txt`
   2026-05-26, `.budget` / `.provenance.json` / manifest sidecars since), so
   **re-derive this list against `solve.c` whenever the solver's on-disk state
   changes** — an out-of-date list fails open, not closed.

   ```bash
   ssh ... solver@$IP "
   if [ \"\$(cat /data/run_id.txt 2>/dev/null)\" != \"$RUN_ID\" ]; then
       rm -f /data/sub_*.bin /data/sub_*.dfs_state \
             /data/sub_*.bin.budget /data/sub_*.bin.provenance.json \
             /data/sub_ckpt_* /data/sub_flush_chunk_* \
             /data/shard_manifest.txt \
             /data/solutions.bin /data/solutions.sha256 \
             /data/solutions.meta.json /data/solutions.provenance.json \
             /data/solve_output.txt /data/solve_results.json \
             /data/checkpoint.txt /data/checkpoint.txt.* /data/checkpoint_t*.txt \
             /data/progress.txt
   fi
   echo '$RUN_ID' > /data/run_id.txt
   "
   ```

   Note that `solutions.bin` is matched by **exact name only** — that is what
   lets §Chaining preserve a prior run's output by renaming it to
   `solutions_A_<sha8>.bin`. None of the added patterns match that name either.
   Verification after the wipe: the run's first log lines should report zero
   resumed sub-branches; a `Resuming:` line with a non-zero count on a run you
   believe is fresh means the wipe missed something.

7. **Compile and launch the solver.** The solver binary stays on the OS disk
   under `~/solve`; output goes to `/data` (managed disk).

   ```bash
   scp -i ~/.ssh/f64_key ./solve.c solver@$IP:~/solve.c
   GH=$(git rev-parse --short HEAD)   # provenance stamp — computed HERE, the VM holds solve.c alone, no clone
   ssh ... solver@$IP "gcc -O3 -pthread -fopenmp -DGIT_HASH='\"$GH\"' -o solve solve.c -lm -lz"
   # Without -DGIT_HASH the run's solutions.meta.json records "git_hash": "unknown" (sha-neutral either way).
   # Use the §Solver-launch SSH detachment "Required form" — a bare
   # `nohup ... &` over ssh does NOT reliably release the channel and hangs
   # the launcher before it can enter its poll loop.
   timeout 15 ssh -n -i ~/.ssh/f64_key -o StrictHostKeyChecking=no "solver@$IP" \
       "cd /data && SOLVE_THREADS=64 SOLVE_NODE_LIMIT=$NODE_LIMIT \
        setsid nohup ~/solve 86400 > solve_output.txt 2>&1 < /dev/null &" \
       < /dev/null 2>/dev/null
   sleep 5
   ssh ... solver@$IP 'pgrep -x solve >/dev/null && echo started || echo FAILED'
   ```

### Teardown (preserve managed disk!)

8. **Serialized teardown order.** VM → NIC → OS disk. Parallel deletes hit
   dependency-ordering errors. Delete only what *this* run created: the
   per-run VM, its NIC, and its orphan OS disk. Never delete `solver-data`,
   and **never delete `claude-vnet`** — it is shared with the orchestrator
   VM, so deleting it is an incident, not a cleanup. (There is no public IP
   and no NSG in this design; see step 2. The general dependency order when
   a run *does* own those resources is VM → NIC → public IP → NSG → vnet.)

   ```bash
   az vm delete -g "$RG" -n solver-vm --yes
   for i in 1 2 3 4 5 6; do
       state=$(az vm show -g "$RG" -n solver-vm --query provisioningState -o tsv 2>/dev/null)
       [ -z "$state" ] && break
       sleep 5
   done
   az network nic delete -g "$RG" -n solver-nic
   # NOT deleted: claude-vnet (shared with the orchestrator) and solver-data.
   # Clean orphan OS disks (don't touch solver-data)
   for d in $(az disk list -g "$RG" --query \
       "[?diskState=='Unattached' && starts_with(name,'solver-vm_OsDisk_')].name" -o tsv); do
       az disk delete -g "$RG" -n "$d" --yes --no-wait
   done
   ```

### Ad-hoc VM lifecycle rules (STRICT — prevents leaked VMs)

Applies any time a VM is provisioned to mount a managed disk for a one-off
inspection or a short-lived compute task.

**Incidents that motivated this section:**

- **2026-04-19** (F64als_v6 spot recreated): a `solver-d3` F64 was spun up on
  2026-04-19 06:09 UTC to mount `solver-data`, then left running for ~32 hrs
  before being caught and deleted on 2026-04-20 14:11 UTC. Accumulated ~$25 in
  avoidable spot charges.
- **2026-04-20** (same SKU, same disk, recreated again): a new `solver-d3` F64
  spot was provisioned on 2026-04-20 18:59 UTC with `solver-data` attached,
  then left running for ~9.5 hrs until the operator noticed at 04:30 UTC Tue.
  Accumulated ~$7.50. Same anti-pattern, different session.
- Both incidents violated the standing rule against F-series VMs.

**The rules:**

1. **F-series VMs are BANNED.** Project standardized on D-als-v7 family
   2026-04-19. If you're about to run `az vm create --size Standard_F*`, STOP.
2. **Right-size for the task.** Mounting a 300GB data disk for a 10-minute
   inspection does not need 64 cores. Use:
   - D2als_v7 (2 vCPU, $0.08/hr on-demand, $0.025/hr spot) — for simple `ls`,
     `cat`, copy-small-files tasks
   - D4als_v7 (4 vCPU, $0.16/hr on-demand) — for 1-thread Python analysis
   - D8als_v7 and up only if the task is actually multi-threaded CPU-bound
3. **Every `az vm create` must pair with teardown in the same command
   sequence.** Register the teardown **before** doing the work, so it runs on every exit
   path. An `&&` chain is the wrong shape here: it is nothing but skip-branches,
   and the ordinary failure this section exists to prevent — a transient ssh
   failure, `rc=255` — stops the chain *before* the delete and leaks the VM with
   the data disk still attached. Both incidents above are exactly that.

   ```bash
   # GOOD: teardown is a trap, so it fires on success, failure, and Ctrl-C
   RG=rg-claude
   teardown() {
     az vm disk detach -g "$RG" --vm-name temp-vm --name solver-data || true
     az vm delete -g "$RG" -n temp-vm --yes || true
     # `az disk delete` takes EXACT names — a literal `temp-vm_OsDisk_*` glob
     # never matches anything locally and errors. Resolve the name first.
     for d in $(az disk list -g "$RG" --query \
         "[?diskState=='Unattached' && starts_with(name,'temp-vm_OsDisk_')].name" -o tsv); do
       az disk delete -g "$RG" -n "$d" --yes --no-wait
     done
   }
   az vm create ... -g "$RG" -n temp-vm
   trap teardown EXIT
   az vm disk attach -g "$RG" --vm-name temp-vm --name solver-data
   ssh solver@<ip> '<inspection commands>'
   ```

   ```bash
   # BAD: any non-zero rc short-circuits the chain and the VM leaks
   az vm create ... -n temp-vm && ssh solver@<ip> '...' && az vm delete ... --yes
   ```

   Rule 6's `--ephemeral-os-disk true` removes the orphan-OS-disk loop entirely
   for VMs that will live < 1 hour. If the task is too complex to script in one
   sequence, build teardown into an immediately-scheduled follow-up wakeup with
   no branches that skip it.
4. **Maintain a session-lifetime log of created VMs.** When creating a new
   VM, append to `/tmp/claude_session_vms.txt`:
   ```
   2026-04-20T18:59Z solver-d3 F64als_v6 westus2 purpose:mount-solver-data ttl:1hr
   ```
   Before the session ends (or every 6 hours of autonomous work), reconcile
   this list against `az vm list -g rg-claude`. Any VM in the list still
   present must be either (a) still serving its documented purpose OR (b)
   torn down now.
5. **Data disks are NEVER deleted.** Detach before VM delete. User explicit
   approval required for anything touching a data disk's contents.
6. **Default to `--ephemeral-os-disk true`** for VMs that will live < 1 hour.
   Ephemeral OS disks are destroyed with the VM automatically, eliminating
   orphan-cleanup steps.
7. **Parallel `az vm create` returns IPs in completion order, not submission
   order — bind IP-to-name via `az vm show` after create (lesson from
   2026-04-22 Pass 1 launch mixup).** If you launch multiple VMs with
   `az vm create ... & az vm create ... & wait`, the stdout line that appears
   first is the VM that *finished creating* first, not the one whose command
   was submitted first. Using stdout ordering to decide "this IP is VM A,
   that IP is VM B" has a 50% chance of being wrong. Always follow up with:

   ```bash
   az vm show -g <rg> -n <vmA> --query publicIpAddress -o tsv  # the truth
   az vm show -g <rg> -n <vmB> --query publicIpAddress -o tsv
   ```

   Past incident: at Pass 1 launch on 2026-04-22 I misassigned which IP
   went to which VM name, then when I "killed the slow VM" I actually
   deleted the fast one. Recovery cost ~$0.70 + 1.5 hrs wall. The fix is
   cheap (query by name post-create); the failure mode is expensive.

### Archival pattern for large `--sub-branch` outputs (>100 MB)

P1's depth-5 parallel exploration produces much larger `sub_*.bin` files
than legacy DFS at the same budget (typically ~500 MB at 10T for rich
branches). These are too big for git-native storage but need preservation
for scientific reproducibility. Established pattern (from 2026-04-22 Pass 1):

1. **Big file stays on `solver-data-westus3` managed disk** at
   `/data/archive/<run-label>/<branch>/sub_<branch>.bin`. Attach the disk
   temporarily to the source VM, `cp` the file, `sync && umount`, detach.
2. **Commit only the small artifacts** to the public repo at
   `runs/<YYYYMMDD>_<label>/<branch>/`:
   - `sub_<branch>.sha256` — 1 line, the sha256 of the big file
   - `sub_<branch>.meta.json` — params, yield, wall, rate, solver commit, archive location
   - `run.log.gz` — solver stdout gzipped (~20-30 KB)
   - `checkpoint.txt` — final status line from solve.c
3. **Top-level `README.md`** in the run directory summarizing parameters,
   results, growth analysis, conclusion, cost.

Verification recipe: attach `solver-data-westus3` to any D2als_v7+, then:
```bash
cd /data/archive/<run-label>/<branch>
# The .sha256 sidecar holds the LOGICAL (decompressed) sha, not the sha of the
# bytes on disk — see SOLUTIONS_FORMAT.md §"On-disk framing". Since #169
# (d8671550, 2026-06-17) shards are gz-framed by DEFAULT, so `sha256sum -c`
# hashes the gzip CONTAINER and reports FAILED on a byte-correct artifact.
# Compare against the logical stream instead:
gzip -dc sub_<branch>.bin | sha256sum   # gz-framed (the default since #169)
head -1 sub_<branch>.sha256             # the hash above must match this line

# ERA EXCEPTION. Archives written BEFORE #169 hold RAW bytes, as does anything
# produced under SOLVE_COMPRESS=0. For those — including the 2026-04-22 and
# 2026-04-23 pass-A/pass-B archives — logical and on-disk bytes are the same and
#     sha256sum -c sub_<branch>.sha256
# is the correct command. Sniff the first two bytes to tell them apart: `1f 8b`
# is gz-framed, `ROAE` is raw.

./solve --verify sub_<branch>.bin  # per-record C1-C5 check, framing auto-detected
```

### Zone caveat for analysis VMs

If the data disk was created without a zone (`zones: null`) but a primary VM is
zonal, the disk cannot attach to that VM (Azure returns `BadRequest`). For a
recovery / analysis VM that needs to mount `solver-data`, **provision without a
zone** (omit `--zone` and don't specify a `zone` in the resource definition
above). Once attached to the new VM, mount as in step 5.

### Quota accounting — deallocated VMs still hold your quota

**Key gotcha that bit us on 2026-04-20:** An Azure VM in the `Deallocated` state is
not computing (no hourly charge) but **still holds a quota reservation equal to its
full vCPU count**. Only **deletion** frees quota. This applies to both
on-demand (Regular) VMs and spot (Low-priority) VMs, and is per-quota-bucket:

| Quota bucket | Scope | What counts |
|---|---|---|
| `Standard <SKU-family> Family vCPUs` (e.g., `Standard Dalsv7 Family vCPUs`) | Regular/on-demand only, per family, per region | Every non-deleted VM in that family, whether running or deallocated |
| `Total Regional Low-priority vCPUs` | All spot VMs combined, per region | Every non-deleted spot VM, whether running or deallocated |

These are **two separate buckets** — a spot VM does not consume on-demand family
quota and vice versa, even for the same SKU.

**Practical consequence.** If you have a deallocated D128als_v7 (128 cores)
sitting around in westus3 where your Dalsv7 family quota is 130, you have **only
2 cores of usable headroom**. You cannot create a D32 on-demand in that family
until you either:

1. **Delete the deallocated VM** (frees quota; loses the OS disk unless its
   `deleteOption` is `Detach` — data disks are typically `Detach`, OS disks
   default to `Delete`).
2. **Request a quota increase** (hours-to-days turnaround; not guaranteed).
3. **Use a different family** (if you have quota in another family).
4. **Move to a different region** (if the disk isn't region-locked; managed
   disks ARE region-locked, so this usually requires a snapshot+copy).

**When this matters for this project.** We frequently keep a large VM
deallocated for rapid re-use (the "cheap to restart" pattern). This is fine
*until* you want to provision a different-sized VM in parallel. Typical
scenario: the enumeration VM (D128als_v7) is deallocated after a run, and you
want to spin up a smaller D32als_v7 for follow-up single-branch work. If
D128's 128 cores already consume most of your quota, the smaller VM creation
will fail with `QuotaExceeded`.

**Rule of thumb.** Before leaving a large VM deallocated "for later," ask:

- Will I want to run a *different-sized* VM in the same region + family while
  this one is deallocated? If yes, delete this one instead (keep the data
  disks; they're separate resources and persist independently).
- If you plan to resume the same VM at the same size, deallocation is fine —
  you're not using additional quota when you restart it.
- Spot and on-demand are separate quotas, so a deallocated spot VM does not
  block on-demand provisioning in the same family and vice versa.

**Verification commands:**

```bash
# See all quotas and current usage for a region
az vm list-usage -l <region> -o table

# Spot-specific
az vm list-usage -l <region> --query "[?contains(name.value,'lowPriority')]" -o table

# Per-family on-demand
az vm list-usage -l <region> --query "[?contains(name.value,'Dalsv7')]" -o table
```

"Current" in the output reflects **reserved** cores — which includes deallocated
VMs. If it equals your limit, you have zero headroom even if nothing is actually
running.

### Single-branch parallel (`--sub-branch`) — SKU sizing

**Applies when:** running one `./solve --sub-branch <p1> <o1> <p2> <o2> <p3> <o3>`
invocation with the P1 parallel code path (auto-on when `SOLVE_THREADS > 1`;
force-off via `SOLVE_SUB_BRANCH_PARALLELISM=single`).

**Task granularity: depth-5** (commit `201d706` onward). Each depth-3 prefix
generates typically 900-3600 tasks at (p4, o4, p5, o5) granularity. The test
branch `22 0 30 1 20 0` produces 2,507 tasks.

**Measured scaling on Zen 5c "Turin Dense" (westus3 spot), 50B-node budget**:

| Threads | Wall | Speedup | Efficiency |
|---|---|---|---|
| 1 | 182s | 1× | 100% |
| 32 | 77.7s | 23.4× | 73% |
| 64 | 52.1s | 34.9× | **55%** ← knee of the curve |
| 96 | 51.0s | 35.7× | 37% |
| 128 | 49.9s | 36.5× | 29% |

**Key finding: memory bandwidth saturates at ~N=64.** Going from 64 → 128 cores
gives only 4% additional speedup, at double the VM cost.

**SKU recommendations for single-branch (single process per VM):**

| Scenario | Recommended VM | Per-branch cost (50B budget) |
|---|---|---|
| Wall-time critical, one branch | D128als_v7 spot (~$0.95/hr), K=1 N=128 | $0.0135 (51s wall) |
| **Cost optimized, one branch** | **D64als_v7 spot (~$0.47/hr), K=1 N=64** | $0.0094 (72s wall) |
| Noisy-neighbor tolerant | D32als_v7 spot (~$0.32/hr), K=1 N=32 | $0.0069 (~78s wall, projected) |

**Packing (multiple concurrent `--sub-branch` processes on one VM) — for batches:**

A single VM can run K concurrent `--sub-branch` processes, each with N threads
(total K×N threads ≤ VM cores). Each process writes its own output directory.
**Measured 2026-04-21**: packing breaks through the single-process atomic
contention ceiling and produces higher aggregate throughput.

| VM | Best packing | Wall (8 branches × 50B each) | $/branch |
|---|---|---|---|
| D128als_v7 | K=8 N=16 (or K=16 N=8) | 257s (K=8) / 501s for 16 branches (K=16) | $0.0085 / $0.0083 |
| **D64als_v7** | **K=8 N=8** | **491s** | **$0.0080** ← cheapest measured |
| D32als_v7 | K=8 N=4 | 963s | $0.0086 |

**On D128, aggregate throughput rises from 980 M/s (K=1 N=128) to 1.60 B/s (K=16 N=8)** — a 60%+ improvement — because each process has its own atomic
counter and cache-resident hash table, breaking through the single-process
atomic-contention ceiling.

**Recommendations by scenario:**

| Scenario | Recommended |
|---|---|
| 1 branch, ASAP | **D128 spot, K=1 N=128** |
| 1 branch, cheap | **D64 spot, K=1 N=64** |
| 8-branch batch, cheapest | **D64 spot, K=8 N=8 packing** |
| 16-branch batch, balanced | D64 K=8 × 2 VMs parallel, OR D128 K=16 N=8 |
| Campaign (100+ branches), cheapest | **Many D64 VMs in parallel, each K=8 N=8 packing** |
| Campaign, wall-time-critical | Many D64 VMs in parallel, each K=8 N=8 (same as above — measured optimum) |

**Never D128 for a single `--sub-branch` run** unless wall-time dominates —
D128's no-co-tenant guarantee is valuable, but you pay ~40% more per branch
vs D64 K=1 for just 20s faster wall.

**Secondary options (if D64/D128 spot quota tight):** westus2 spot quota is
128 cores (same as westus3); use there if westus3 constrained. On-demand D-series is 4× spot price — only worth it if budget allows no evictions.
F-series retired on this project (see §Cost control).

**Full measurement data + packing-mechanism analysis + campaign-planning math:**
`roae-private/P1_SCALING_MEASUREMENTS.md` (staging repo).

### Cost reference (2026-04-19 pricing, post-Dalsv7-pivot)

| SKU | Region | RAM | Use case | Spot price | On-demand |
|---|---|---|---|---|---|
| **D128als_v7** | westus3 | 256 GB | **Enumeration ≥10T (new default)** | ~$1.70/hr | ~$6.80/hr |
| **D64als_v7** | westus3 | 128 GB | d3 10T merge | ~$0.50/hr | ~$2.00/hr |
| **D16als_v7** | westus3 | 32 GB | d2 10T merge | ~$0.13/hr | ~$0.50/hr |
| **D4als_v7** | westus3 | 8 GB | Analysis / --analyze / --verify | ~$0.03/hr | ~$0.13/hr |
| D2as_v6 | westus2 | 8 GB | Orchestrator / claude VM | ~$0.09/hr (on-demand) | — |
| F64als_v6 | westus2 | 128 GB | **RETIRED 2026-04-19** (historical reference only) | ~$0.79/hr | ~$3.87/hr |
| Standard HDD managed disk | any | — | Persistent `/data` (archival shards + solutions.bin) | — | ~$21-82/mo depending on tier (S15 300GB → S40 2TB) |
| Premium SSD P20/P40 | any | — | External-merge temp scratch (attached-for-merge only) | — | ~$0.05-0.42/hr prorated |

#### SKU to RAM reference

*(The single SKU→RAM reference for this project; added 2026-09-01.)*

Every `D<N>als_v7 (<RAM>)` figure published anywhere in this project must match
this table. The table exists because the figures did **not** match: several
sites doubled them, and the project paid for the assumption once already.

| SKU | vCPU | RAM |
|---|---:|---:|
| D4als_v7 | 4 | 8 GB |
| D16als_v7 | 16 | 32 GB |
| D32als_v7 | 32 | 64 GB |
| D64als_v7 | 64 | **128 GB** |
| D96als_v7 | 96 | 192 GB |
| D128als_v7 | 128 | **256 GB** |

**The rule is 2 GB per vCPU**, and the reason is the `l`: `Dals_v7` is the
**low-memory** variant of the `Das_v7` family. The same core count without the
`l` carries twice the RAM — `D64as_v7` is 256 GB where `D64als_v7` is 128 GB.

🔴 **This is a paid-for lesson, not a spec-sheet transcription.** During the
100T pilot the project had to move a consolidation step "from D64als_v7 (128 GB
RAM, 'l' = low memory) to **D64as_v7 (256 GB RAM)** … We had assumed D64als_v7
was 256 GB" ([HISTORY.md](HISTORY.md), 100T-pilot entry). The two SKU names
differ by one character and their memory differs by 2×. When sizing a merge by
RAM, read the SKU name character by character.

Spot prices fluctuate; check the Azure spot pricing page or set `--max-price`
defensively. Spot evictions in westus2 under F64 averaged ~1 per 3 hours during
April 2026 testing — concrete numbers in the lessons section above.

These commands are the manual reproduction of what an orchestrator does
automatically. For a programmatic orchestrator, use the same primitives in your
shell of choice (`bash`, `pwsh`) or Azure SDK; the rules in the architecture and
lessons sections above still apply regardless of language.
