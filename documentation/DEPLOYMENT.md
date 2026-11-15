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

- **Atomic writes, where they exist.** `solve.c` writes shards to `sub_*.bin.tmp` then renames, but `progress.txt`, `solve_results.json` and (on the in-process merge) `solutions.bin` are written under their final names. A mid-write
  snapshot by the monitor can therefore read an empty or partial file of that kind; retry rather than act on it. *(2026-11-14, Codex final review F12-007#10: this said every write is tmp-then-rename)*
- **Per-sub-branch node limits.** Thread scheduling varies, but each sub-branch
  has a deterministic node budget, so per-cell results are reproducible regardless of
  how threads pick up work; the record set of a parallel `--sub-branch` run under one global budget can vary between runs (solve.c's own note; Codex final review, F12-007#4).
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

> ⚠ **What `SEARCH_COMPLETE` asserts, and what it does not.** It is emitted whenever the run reached
> its own end **without hitting the wall-clock timeout** — in `solve.c` it is simply the `else` branch
> of `if (global_timed_out)`, at both emission sites. It is a **lifecycle** status: *this process
> finished normally*. It is **NOT** a claim that the search space was exhausted.
>
> That distinction matters because **every enumeration this project publishes is budgeted**: each
> cell stops at its node allowance rather than completing, so a budgeted run leaves an unexplored DFS
> suffix under every truncated sub-branch **and still reports `SEARCH_COMPLETE`**. A reader keying on
> the name alone would conclude exhaustion that no run has ever demonstrated. The record count of the
> resulting `solutions.bin` is a **lower bound**, never the cardinality of the space — see
> [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md), whose own unscoped completeness sentence was corrected
> on 2026-08-28 for exactly this reason.
>
> The token itself is deliberately **not** renamed: monitors and supervisors match it as a literal,
> and a completion-detection regex mismatch has already cost this project a run (§Lessons item 4, and
> `HISTORY.md`). The name is a compatibility surface; this paragraph is the semantics. *(2026-10-02, Q-317 (5), batch 33: the machine-readable answer to "did a budget cut this run short" is a separate whole line, `BUDGET_EXHAUSTED=YES` or `NO` (or `UNKNOWN`), printed after `ENUM_RUN`; `SEARCH_COMPLETE` is kept as it is. `NO` is not a claim that the search space was exhausted either: a stopped run prints it too. See SOLVE_C_CLI.md, default mode.)*

- Completion detection depends on the mode. In **single-VM mode** (bundled
  merge) the solver writes `solve_results.json` with a `SEARCH_COMPLETE` status
  field, and solver exit plus that file is the signal. In **split enum/merge
  mode** (`SOLVE_SKIP_AUTOMERGE=1` — mandatory for canonical runs ≥11.2T) the
  enum process returns *before* the completion report and before the JSON is
  written, so the enum VM never produces `solve_results.json` at all. There the
  signal is solver exit rc=0 **plus** the whole-line `ENUM_RUN=FINISHED` printed after the `SOLVE_SKIP_AUTOMERGE set; skipping
  bundled merge` line in `solve_output.txt` (a stopped run exits 0 and prints the same skip line, with `ENUM_RUN=STOPPED`; a relaunch over a directory whose every sub-branch is already checkpointed exits 0 with `All N sub-branches already completed.` and neither line) **plus** filesystem truth (shard
  count; `shard_manifest.txt` records names, sizes and digests, not completion) — or, better, the supervisor-written *(2026-11-14, Codex final review F12-007#1: rc 0 plus the skip line was given as the signal; it does not tell a stopped run from a finished one)*
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
on an older 64-core compute-optimised Spot VM, a size now retired for this project — exposed
a fundamental mismatch: sub-branch-level checkpointing (committing
`sub_P_O.bin` only when a sub-branch finishes its ~33B node budget) was
too coarse for a spot VM whose eviction frequency exceeded the per-branch
wall time. That run was aborted. **The successful 100T d3 canonical run
(2026-04-19/20) used a 128-core VM on regular (non-interruptible) capacity** — no evictions, 16h 48m
end-to-end — so the following lesson is about spot-VM checkpoint granularity
in general, not about the 100T canonical specifically. If you ever return
to spot for 100T+ enumeration, the granularity analysis below still applies.

Observed behavior:
- ~1 eviction every 2-3 hours under load
- Each eviction killed all 64 in-flight sub-branches mid-run
- `INTERRUPTED` branches restart from node zero on resume (no intra-branch state)
- After ~9h wall time: 47/3030 committed, 12.5T wasted nodes, projected ~30 days

**Rule of thumb:** committed-work granularity should be *smaller* than the mean
time between interruptions, not larger. At 1.3B nodes/sec across 64 threads (about 20M nodes/sec each), a ~33B-node
sub-branch takes about 27 min on its thread, so 64 threads dropping means losing up to about 29 core-hours (64 × ~27 min) *(2026-11-14, Codex final review F12-007#13: this read ~25s per sub-branch and ~30 minutes, dividing a branch budget by the aggregate rate)*
per eviction — acceptable only if evictions are rare. When they aren't, add
intra-sub-branch checkpointing (periodic state flush within the branch, then
resume from the saved frontier).

## Graceful shutdown is load-bearing

On SIGTERM the solver stops cleanly: the handler only sets a flag the walk checks. Since Q-881 a stopped run is **not** merged in
any mode: the bundled merge is skipped with a warning and no new `solutions.bin` is written, unless `SOLVE_MERGE_ALLOW_INCOMPLETE=1` asks for a merge of the partial shards (under `SOLVE_SKIP_AUTOMERGE=1` — the split
mode this file prescribes for canonical runs — the enum VM never merges, and `--merge` on the merge VM produces `solutions.bin`). ⚠ *(Scoped 2026-09-25, Q-763: this read as if every mode merged on SIGTERM.)* ⚠ *(Corrected 2026-11-03, Codex final review F12-007#3: this paragraph said that in bundled-merge mode the SIGTERM handler merges the committed shards and writes the final `solutions.bin` and sha256 on exit, and that SIGKILL instead loses the merged output; Q-881 had ended merging a stopped run.)* When aborting a run, always `kill -TERM` the solver
(not SIGKILL) and wait for it to finish, so it stops at a clean point; the per-sub-branch data already committed
is safe on disk either way.

## Two-phase deployment: enumeration VM vs merge VM

Enumeration and merge have very different resource profiles. Running both on
the same VM forces you to provision the *union* — many cores *and* lots of RAM
— for the entire wall-clock time. Splitting them avoids that waste,
and at larger budgets (≥100T) the split becomes architecturally necessary
because no single machine size suits both.

**STANDING POLICY (2026-04-20, corrected after a misprovisioning; reaffirmed 2026-08-29):**

⚠ **[NOTE 2026-08-29 — `CLAUDE.md` asserted a blanket "all VMs must be Spot" rule claiming to supersede this
section. Corrected: practice never followed it (five of seven non-orchestrator VMs are Regular), and this
split policy is the operative one. See CORRECTIONS.md]**

- **Enumeration → spot, 128 cores** (a 128-core VM, 256 GB RAM). Eviction-resilient (sub-branch checkpoints).
- **Merge → regular (non-interruptible) capacity, RIGHT-SIZED (NOT 128 cores).** Merge is single-threaded heap-sort; 1-2 cores are used, the rest sit idle. **Size the merge VM by RAM and I/O, NOT core count.** Regular capacity (not spot) because merge is fragile under eviction — a mid-merge eviction means a full re-run at 100T+ scale (5+ hours).
  - **d3 10T merge** (~89 GB pre-dedup): **a 16-core VM** (32 GB RAM) with `SOLVE_MERGE_MODE=external`, or **a 32-core VM** (64 GB RAM) which still needs the external path — 89 GB does not fit in 64 GB. Regular capacity, about 1 h for the merge. *(This bullet previously read "[the 32-core size] (32 GB RAM fits 89 GB external, 64 GB fits in-memory)", attaching two different RAM figures to one size and contradicting the 64 GB given for the 32-core size in the next bullet. Corrected 2026-09-01 against the size→RAM table below.)*
  - **d3 100T merge** (~443 GB pre-dedup, external required): **a 32-core VM** (64 GB RAM) is plenty — external merge streams in chunks, doesn't need to fit everything in RAM. Regular capacity, about 5 h for the merge (the 2026-04-19/20 merge measured 5h 25m 38s). *(The pre-dedup figure is measured: 13,832,832,979 records × 32 B = 442,650,655,328 B ≈ 443 GB, from `runs/20260419_100T_d3_d128westus3/README.md`. This bullet previously said "~880 GB" — the pre-run projection of ~27.7B records, which was never replaced by the measurement after the run. Corrected 2026-09-03; the same projection also survived as "~830 GB" (the same number in GiB) in §SSD-attach-for-merge, §100T and beyond, §Known scale limits and §Disk sizing, all corrected in the same pass.)*
  - **d3 1000T+** (if ever): external merge on **a 64-core VM** (128 GB RAM) handles chunk sort comfortably.
  - **NEVER use the 128-core VM for merge.** Provisioning 128 cores to run a 1-core workload wastes the other 127. The 2026-04-19/20 100T run's merge did exactly this: a 128-core VM ran a workload a 32-core VM would have served.

**An earlier revision (2026-04-19) briefly moved merges to spot by default on the reasoning that shards persist. That rule is SUPERSEDED** — at 100T+ scale, re-running a 5-hour merge after a spot eviction is worse than running it on regular capacity. Revert to regular (non-interruptible) capacity for merge; size it correctly instead.

**Mandatory pre-launch verification gate (every workload ≥ 1 hour):**

```bash
az vm show -g "$RG" -n "$VM" --query priority -o tsv
```

- `Spot` → OK for enumeration. Proceed.
- `<empty>` / `null` / `Regular` → OK for merge or an explicit regular-capacity run. NOT OK for enumeration — stop, recreate the VM with `--priority Spot --eviction-policy Deallocate --max-price -1`, or escalate to the user.

**Failure case this prevents:** on 2026-04-19/20, the 128-core compute VM was provisioned without `--priority Spot` by an earlier autonomous session; the 100T d3 enumeration + merge pipeline (16h 48m) was launched on it without verification. The whole run used regular capacity; under the corrected policy the enumeration would have been Spot and only the merge on regular capacity. The lesson: check the priority before launch. See [HISTORY.md](HISTORY.md) §Missteps for the full retrospective.

### Memory-budget validation for chunk-based parallel verifiers (added 2026-05-08)

Right-sizing a VM by **core count alone is insufficient** if the workload is chunk-parallel. `verify.py --jobs N` (and any future tool that splits a file into N chunks each loaded into per-worker memory) has a fundamental property: **per-worker chunk = file_size / N, total memory across N workers = file_size, regardless of N**. There's no `--jobs` value that fits in RAM smaller than the file when chunks are loaded fully.

Two consequences:

1. **Streaming reads are the standard for chunk-parallel verifiers.** A worker should bound its memory to a constant (e.g., 32 MB streaming batch) regardless of input size. Loading 6+ GB into a Python `bytes` object via `f.read(chunk_size * 32)` is banned for any workload where the file may exceed RAM.
2. **VM sizing must validate `chunk_size × N_workers ≤ available_RAM × 0.7`.** When choosing a VM for a parallel verifier, this arithmetic check catches the regime where the unpatched verifier will thrash via swap, not just slow down.

Concrete example: `verify.py --jobs 16` on a 110 GB `solutions.bin`:
- Per-worker chunk = 110 / 16 = 6.87 GB
- Total memory = 16 × 6.87 = **110 GB**
- Required VM RAM (with 30% headroom) = ~157 GB
- A 16-core VM with 32 GB → **thrashes** (empirically: 13× re-read multiplier, OOM-killed at 5h 5min)
- A 128-core VM with 256 GB → fits, no thrashing

This bit on 2026-05-08 (T9+c.1 phase 4 on the 16-core VM). Patched verify.py in this repo uses 32 MB streaming batches and is no longer subject to the memory-vs-N constraint — it needs cores and, for a gzip-framed input (the default since #169), free space under `TMPDIR` (default `/tmp`) for the whole decompressed file, which it writes before its workers start: about 110 GB at 100T and 337 GB at 560T, so point `TMPDIR` at the data disk. *(2026-11-14, Codex final review F12-007#8: this said it just needs cores)* But the patched verifier is the floor: any chunk-parallel verifier added later should follow the same streaming pattern.

**Rule of thumb for VM-sizing decisions:**

- Single-thread merge: pick the smallest size that has enough RAM for the merge buffer (`SOLVE_MERGE_CHUNK_GB` × 2). 8- or 16-core sizes are usually right.
- Single-thread [`solve --verify`](SOLVE_C_CLI.md#--verify) (C-side): RAM doesn't matter (a streaming zlib reader that decodes and checks every record; not mmap). Smallest size is fine. ~21 min is the raw read time of a 100T-scale 109.8 GB `solutions.bin` at an HDD-backed disk's ~85 MB/s, a floor: decompression and the per-record checks are not in it, and no wall was measured. *(2026-11-14, Codex final review F12-007#21: this said mmap + sequential read and gave ~21 min as the wall)* This is the fast single-threaded check; `verify.py --jobs 1` is CPU-bound and two orders of magnitude slower (see §Sizing rule for verify.py).
- Parallel `verify.py --jobs N`: with the streaming patch, ~32 MB × N for memory; mostly CPU-bound now. Match N to cores to maximize throughput. **For 100T-scale (3.43B records), expect ~3h on 16 cores at ~19k records/sec/worker; ~12h on 4 cores; ~46 min on 64 cores.** **For 560T-scale (10.525B records, 3.07× 100T), projection at the linear regime: ~9h on 16 cores, ~5h on 32 cores, ~2.4h on 64 cores.** Important caveat: verify.py's per-record decode path is **pure Python at every sha** — the only numpy import in the file is inside `check_t5_c3` (the T5/C3 recompute, unrelated to record verification), so installing numpy does not speed record verification up. The 560T campaign did observe roughly a 3× shortfall against the projected 19k records/sec/worker rate, but that shortfall was **misattributed** to a missing numpy package; disk contention (see §HDD-IOPS contention below) is the leading candidate, and the 19k projection itself may be optimistic. Budget from a measured rate on your own hardware, not from a package install.

Don't reflexively right-size for a single-thread phase and then run a multi-core verify on the same too-small VM. Either re-size for the verify phase, or pick a VM that fits both — the extra compute is usually small over a multi-hour campaign.

### HDD-IOPS contention vs CPU-parallel scaling (added 2026-05-10)

The memory-budget rule above tells you when verify.py won't OOM. It doesn't tell you when verify.py will be slow due to disk contention. These are separate failure modes.

**Empirical finding from T9+d phase 9 (2026-05-10):** scaling `verify.py --jobs N` from 16 (a 16-core VM) to 128 (a 128-core VM) on the SAME HDD-backed disk did NOT yield 8× speedup. Aggregate disk read collapsed from ~9.9 MB/s on the 16-core VM (--jobs 16) to ~15 MB/s on the 128-core VM (--jobs 128) — only 1.5× improvement vs CPU-parallel projection of 8×.

**Root cause:** an HDD-backed disk does ~80 random IOPS. With 128 workers reading from 128 disjoint file offsets simultaneously, the disk spends most of its time seeking. Per-worker read rate degrades from ~0.62 MB/s (at N=16) to ~0.12 MB/s (at N=128) — a 5× per-worker slowdown.

**Sweet spot for parallel verify on an HDD-backed disk: ~16-32 workers.** Past 32, IOPS contention dominates CPU parallelism and additional cores deliver diminishing returns. Past 64, returns are essentially zero.

**To go faster than the ~16-worker plateau:**
- Use SSD-backed scratch (high random IOPS — an SSD-backed managed disk does 5,000+ IOPS, two orders of magnitude better)
- Or restructure verify.py to use single-stream sequential reads with worker-pool processing (reader thread feeds N CPU-bound worker threads from a queue) — would let the reader saturate sequential HDD throughput at ~150 MB/s and CPU workers process from memory

**Impact on this campaign:** a 128-core VM was provisioned for the 8× speedup that didn't materialize; 32 cores was the sweet spot.

**Sizing rule for verify.py (revised):**

100T-scale (3.43B records, on HDD-backed scratch):

- Single-thread (`--jobs 1`) on 2 or 4 cores: **~50 h** for 100T — CPU-bound, not
  disk-bound (3.43B records ÷ ~19k records/sec/worker = ~50 h; measured
  single-worker throughput on a small file is ~27k records/sec, giving ~35 h).
  The ~21 min figure this row used to carry is the *C-side* number
  (109.8 GB ÷ ~85 MB/s of HDD-backed read), a read-time floor for the streaming C
  verifier. For a single-threaded disk-speed check, use
  [`solve --verify`](SOLVE_C_CLI.md#--verify), not `verify.py --jobs 1`.
- `--jobs 16` on 16 cores: ~3h (CPU-bound at ~620 KB/sec per worker after the streaming patch)
- `--jobs 32` on 32 cores: ~1.5h (sweet spot)
- `--jobs 64` on 64 cores: ~75 min (slight IOPS contention)
- `--jobs 128` on 128 cores: ~2-3h (severe IOPS contention — DO NOT USE on an HDD-backed disk)
- `--jobs 128` on 128 cores with SSD-backed scratch: ~25 min (estimated, not yet measured) — would require an upfront copy from the HDD-backed disk to SSD-backed scratch (~25 min for 110 GB)

560T-scale (10.525B records, 3.07× the 100T workload — projection at the linear regime, on mid-tier SSD-backed scratch as in the 2026-06-08 campaign):

- `--jobs 16` on 16 cores: ~9h projected (the in-flight campaign actual on 16 cores ran roughly 3× slower than this projection — see the attribution note above; it is not a numpy effect)
- `--jobs 32` on 32 cores: ~5h projected
- `--jobs 64` on 64 cores: ~2.4h projected (planned post-warm-copy verify run for 560T)
- `--jobs 128` on 128 cores: ~2h projected (still sub-linear above 64 cores per the 100T finding)

For ROAE 100T-scale verify on an HDD-backed disk, **32 cores is the empirical optimum** under the current verify.py design. For ROAE 560T-scale verify on mid-tier SSD, the disk-IOPS contention is less severe than HDD; 64 cores is the recommended sweet spot (1-3h wall on Spot). If verify.py is rewritten to use a reader-thread design, 128 cores becomes optimal again at both scales.

### Quota tracking — deallocated VMs still consume quota (added 2026-05-10)

A deallocated VM stops computing but still holds its vCPU quota; only deleting
it frees the quota (detach the data disks first, and keep them). Before any
large `az vm create`, check the free quota in cores with `az vm list-usage`, and
treat a non-numeric answer as an error, not a pass. The measured incident, the
pre-flight script and the cleanup steps are in the private operations notes.

### Spot host CPU-frequency throttling — silently 5× slower (added 2026-05-12)

**Failure mode:** on 2026-05-12, a freshly-provisioned 128-core Spot VM (host: AMD EPYC 9V45) ran a `solve 0 128` enum at **230 M nodes/s** — 5.6× slower than the established baseline of **1293 M/s** for the same size on a healthy host. The slowdown was scale-emergent (rate looked normal at smaller scales, was glaring at full-throttle 128-thread enum) and would have wasted hours of compute if undetected.

**Root cause:** the host's CPUs were parked at **~600 MHz** (visible via `cat /proc/cpuinfo | grep MHz`), versus the expected **2.5-3.5 GHz** boost frequency. Inside the guest:

- `mpstat` showed **0% steal time** (not a noisy-neighbor problem)
- 100% user CPU + reasonable load average — looked busy
- `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` **did not exist** in this guest kernel — the cpufreq subsystem isn't exposed, so the throttling cannot be diagnosed or fixed from inside the VM
- The frequency was determined by the host hypervisor's power state for this physical host — invisible to the guest, no recourse

The most surprising property: **the slowdown is invisible to all standard busy-VM signals.** Top, mpstat, iostat, vmstat all show "healthy" output. Only `cat /proc/cpuinfo | grep MHz` reveals the true frequency, and only the observed solve.c throughput rate confirms the impact.

**Mandatory pre-launch check for every fresh Azure VM that will run enum work:**

```bash
# Right after SSH succeeds, before launching enum. EVERY core, not the first (Codex final review F12-007#16):
TOTAL=$(grep -c "cpu MHz" /proc/cpuinfo); LOW=$(awk -F: '/cpu MHz/ && $2+0 < 2000 {n++} END {print n+0}' /proc/cpuinfo)
if [ "$TOTAL" -eq 0 ] || [ "$LOW" -gt 0 ]; then
    echo "FAIL: $LOW of $TOTAL CPUs below 2000 MHz (2500-3500 MHz on a healthy host). Re-provision."
    exit 1
fi
echo "OK: all $TOTAL CPUs at or above 2000 MHz"
```

**Resolution when triggered:** there is no in-VM remediation. The fix is:

1. `pkill -9 -f solve` (kill any in-flight work)
2. Detach scratch disk(s): `az vm disk detach`
3. Delete the VM + NIC + PIP (keep data disks): `az vm delete --yes`; cascade NIC + PIP delete
4. Re-provision a fresh Spot VM of the same size — Azure will (probably) place it on a different host
5. Re-attach scratch, re-run the CPU-frequency check

A 2026-05-12 cascade re-provision drew a host running at **3562 MHz boost** (1293 M/s rate, baseline-matching) on the second attempt. Empirically the second-draw success rate is high but not guaranteed; check on every fresh VM regardless.

**Cost of detection vs. cost of not:** a 5-line script run once per provisioned VM is essentially free. Skipping the check on a single 5.6T run on a throttled host wastes wall time; on a 100T run it wastes hours of wall. **Always check before launching long enum work.**

The processor underlying the 128-core VM size is AMD EPYC 9V45 (96-core, 128-vCPU). The vendor's page for that VM family lists the family's processor as AMD EPYC 9005 (Turin), and §Measured scaling below calls it Zen 5c "Turin Dense"; the 9V45 is that generation's cloud part. ⚠ *(Corrected 2026-09-25, Q-763: this sentence called the earlier "Zen 5 Turin" label incorrect; it was right at the family level.)* The 9V45 is a cloud-optimized AMD part; per-core performance at full boost is comparable to (slightly below) Genoa for our DFS-heavy workload, *as long as the host is not throttling*.

### Disk tier matters — more than you might think

The data disk is deliberately **HDD-backed** (the slowest tier). An HDD-backed disk has
IOPS capped at 500 and throughput ~60 MB/s regardless of disk size. That
choice is right for long-term shard *storage* but
wrong for merge-time *compute*. Empirical data point from the 2026-04-18
10T depth-3 external re-merge:

| What | Value |
|---|---|
| Input | 56,404 sub_*.bin shards, 83 GB, 2.77B records |
| Disk | HDD-backed, 300 GB, ~60 MB/s throughput cap |
| Merge mode | `SOLVE_MERGE_MODE=external` (4 GB chunks) |
| Phase 1 (read shards, sort chunks, write temp files) | ~6-7 min per 4 GB chunk × 20+ chunks ≈ 2-3 hours |
| Phase 2 (k-way merge + write solutions.bin) | ~30-45 min |
| Total wall | ~3-4 hours |
| VM | an older 64-core compute-optimised VM, regular capacity |

Compared to the alternatives on various hardware (updated 2026-04-19 with measured 128-core data):

| Strategy | Wall time (10T) | Trade-off |
|---|---|---|
| older 64-core VM + external merge on an HDD-backed disk (above, legacy) | 3-4 h | slowest disk tier, slow merge; that size is retired |
| older 64-core VM + in-memory merge (~89 GB fits in 128 GB RAM) | ~30 min | fast; that size is retired |
| **128-core VM (256 GB RAM) + in-memory heap-sort merge** | **~52 min** | measured 2026-04-19; **superseded** (see note) |
| **128-core VM + external merge on a 512 GB SSD-backed disk** | **~43 min** | measured 2026-04-19; faster than in-memory at 10T; **superseded** (see note) |
| 64-core VM + in-memory merge (128 GB RAM, perfect fit) | ~52 min | half the cores of the 128-core VM, same wall — single-threaded merge ignores core count; Spot **superseded** (see note) |
| An SSD-backed data disk permanently | (same as in-memory) | wasteful; SSD only needed during merge |

*(Scope note, 2026-09-03: the three 64/128-core rows are measurements from 2026-04-19, the
day **before** the §Standing policy of 2026-04-20. The "new default" this table used
to attach to the 128-core spot row was true for one day. Under the standing policy the merge
VM is **on regular capacity and right-sized (16 or 32 cores at 10T–100T) — never 128 cores and never
Spot**. The wall times remain valid planning figures because merge is single-threaded
and ignores core count; the size and priority in these rows are withdrawn.)*

### Recommendations by dataset scale

- **Input < 80% of merge-VM RAM.** Default (auto) selects in-memory. Fastest.
- **Input ≥ 80% of merge-VM RAM, or running on small VM.** Use external merge.
  - On an HDD-backed disk: usable but slow. Budget 3-4 hours for 10T, proportionally
    longer at 100T. Only viable when avoiding a second disk matters more than
    wall time.
  - On SSD-backed scratch (recommended for any merge > 1 hour on HDD): attach a
    temporary SSD-backed data disk (512 GB or 1 TB), point `SOLVE_TEMP_DIR` at
    it, run the merge. Solutions.bin lands on the CWD (which stays on
    the data disk), temp chunks land on the SSD. After the merge completes,
    detach and DELETE the SSD — shards and output are already on
    the data disk. The SSD buys 3-4× throughput for the length of the merge.

### SSD-attach-for-merge — the design pattern

**Architectural idea.** External merge has three kinds of I/O: *shard reads*
(long, sequential, from archival storage), *chunk write/read cycles* (the
external algorithm's temp storage — written in Phase 1, read back in Phase
2), and *output writes* (the final deduped `solutions.bin`). The shards and
final output want to live on durable archival storage (the data disk,
HDD-backed). The chunk cycle wants to live on fast
temp storage that can be destroyed after the merge.

Putting everything on the HDD forces the HDD to interleave all three
streams on one disk head, where seek contention (not raw throughput) is the
bottleneck. Putting chunks on a separate SSD-backed disk collapses the HDD's
role to two linear sequential streams (shard read, then output write) and
gives the chunk cycle its own fast device. On the 10T d3 merge this moved
wall time from ~3 hours to ~30-45 min.

**When the pattern is needed.** Any external merge where wall time on HDD
would exceed ~1 hour. That is any merge where input ≥ 80% of merge-VM RAM
(which forces external mode) at ≥ 10T scale. For smaller runs that fit
in-memory, the pattern is unnecessary — auto mode selects in-memory and
neither the SSD nor external mode is involved.

**When the pattern is strictly necessary.** 100T and beyond. In-memory is
not viable (the measured ~443 GB pre-dedup buffer exceeds the 80%-of-RAM
in-memory rule on every VM size this project uses — the 128-core size has
256 GB — and a memory-optimized size would bring only marginal benefit).
External merge is forced; running external on HDD at that scale projects to
30+ hour wall times. SSD-backed scratch took the 2026-04-19/20 100T merge to
**5h 25m 38s** measured (§100T and beyond).

**Why a temporary disk.** The SSD exists only for the merge: a 512 GB
disk for a 2-hour 10T merge, a 2 TB disk for a 3-hour 100T merge. It is
destroyed the moment the merge completes, so nothing is left
provisioned afterward. That's why this is the right pattern instead
of permanently moving the data disk to an SSD-backed tier, which would
keep a fast disk provisioned for data
that sits cold 99% of the time.

**The rule of thumb.** Shards and output live on the HDD-backed data disk
forever. The SSD-backed scratch disk only exists for the duration of a merge.
`SOLVE_TEMP_DIR=/mnt/scratch` routes chunk I/O to the SSD during the
merge. Both final files (`solutions.bin` + `solutions.sha256` +
`solutions.meta.json`) write to CWD, which should be on the data disk so they
archive automatically.

### Concrete workflow

The pattern: **keep shards and final output on the HDD-backed data disk
for archival; attach an SSD-backed disk only for the duration of the merge
so its temp I/O runs at SSD speed; destroy the SSD afterward.**

```bash
# 1. Provision an SSD-backed disk of 512 GB.
#    For a 10T merge, 512 GB is plenty (~80 GB of temp chunks + slack).
#    For 100T, use 2 TB.
SIZE_GB=512                      # a single parameter for BOTH the create
                                 # and the step-3 selector, so they cannot drift
az disk create -g <resource-group> -n <scratch-disk> -l <region> \
  --size-gb "$SIZE_GB" --sku <ssd-disk-sku> --no-wait

# 2. Attach to the regular-capacity merge VM (after it's up).
az vm disk attach -g <resource-group> --vm-name <merge-vm-name> \
  --name <scratch-disk> --lun 1

# 3. On the VM: identify disk by SIZE + empty-FS state, format,
#    mount, own. NEVER use `mkfs -F` (banned project-wide after the
#    2026-05-06 wipe; see CLAUDE.md §"Disk-handling safety").
#    The pattern below identifies the new SSD-backed disk as the unique empty
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
  sudo mkdir -p /mnt/scratch
  sudo mount "$DEV" /mnt/scratch
  sudo chown solver:solver /mnt/scratch
REMOTE

# 4. Run the merge with SOLVE_TEMP_DIR pointing at the SSD.
#    CWD stays on /data (the data disk) so shards and final output live there.
ssh solver@<vm-private-ip> '
  cd /data
  SOLVE_MERGE_MODE=external SOLVE_TEMP_DIR=/mnt/scratch ~/solve --merge
'

# 5. solutions.bin + .sha256 + .meta.json are now on /data (the data disk).
#    temp_sorted_*.bin files were on the SSD and have been deleted by solve
#    at end of merge. Nothing of value remains on the SSD.

# 6. Detach + delete the SSD.
az vm disk detach -g <resource-group> --vm-name <merge-vm-name> --name <scratch-disk>
az disk delete -g <resource-group> -n <scratch-disk> --yes --no-wait
```

**Lifetime.** Create the scratch disk just before the merge and delete
it as soon as the merge completes (step 6). Nothing of value remains
on it afterward, so a scratch disk left attached past the merge is
waste.

**Why this matters for 100T and beyond.** The 10T merge fits in-memory on
the older 64-core VM; the SSD-attach pattern is optional at that scale. But 100T cannot be
done in-memory on any practical VM size (see below), so the SSD-attach
pattern becomes the path forward, not an optimization.

### 100T and beyond — in-memory is not an option

Measured: the 2026-04-19/20 100T d3 enumeration produced **13,832,832,979
pre-dedup records = 442,650,655,328 B ≈ 443 GB** of merge input
(`runs/20260419_100T_d3_d128westus3/README.md`), against a 109.8 GB
`solutions.bin` (3,432,399,297 unique records). *(This section previously
extrapolated "~27.7B pre-dedup records = ~830 GB" — the pre-run linear
projection from 10T, never replaced by the measurement; the real 10T→100T
pre-dedup growth was 5.0× per 10× budget. Corrected 2026-09-03.)* In-memory
merge would need a memory-optimized size (more than 554 GB RAM under the 80% rule, 443 GB / 0.8 — the threshold `solve.c` applies, Codex final review, F09-H01#8;
the 128-core size has 256 GB) for marginal benefit. The
practical path at 100T is **external merge on SSD-backed scratch**:

- a right-sized merge VM on regular capacity per §Standing policy (32 cores,
  64 GB RAM — the older 64-core size this bullet used to name is retired) + an
  SSD-backed 2 TB disk (250 MB/s) as temp dir
- `SOLVE_TEMP_DIR=/mnt/scratch SOLVE_MERGE_MODE=external`
- ~1.66 TB total I/O in logical bytes (read 443 GB of shards once, write and read back 443 GB
  of sorted chunks, write and read back the 110 GB of deduplicated records in `temp_merge_records.bin`, write the 110 GB output), before hashing and the automatic verify *(2026-11-14, Codex final review F12-007#17: this read ~1.4 TB and left out the deduplicated-record file)*
- **5h 25m 38s wall measured** on the 2026-04-19/20 run (on a 128-core VM the
  standing policy now forbids for merge; the wall does not depend on core
  count) → about 5.5 h of a 32-core VM on regular capacity plus a 2 TB scratch disk for the same span.
  *(Previously "~3 hours wall time, [cost redacted] total" — a pre-run estimate on
  the retired 64-core size.)*

The in-memory path effectively tops out around the 10T-at-our-current-VM-size
combination. Everything larger is external-merge-with-SSD territory.

### Known scale limits of external merge

Two compile-time / runtime limits cap how far external merge can scale:

| Limit | Source | Ceiling at default | Mitigation |
|---|---|---|---|
| `MAX_SORTED_CHUNKS = 4096` | `solve.c` constant | 4096 × 4 GB = **16 TB pre-dedup** (≥ ~3,600T node enumeration at the measured 100T d3 rate of 443 GB per 100T, linear) | Raise `SOLVE_MERGE_CHUNK_GB` (e.g., to 16 or 32) — multiplies ceiling; no code change. Or bump the constant (one-line source change) |
| `ulimit -n` (open FDs) | the **hard** limit: `--merge` raises the soft limit to it at start (`SOLVE_MERGE_NOFILE` pins a target, `SOLVE_SKIP_NOFILE_RAISE=1` turns the raise off) | a hard limit of 1024 → ≥ ~900T before hitting it (1024 × 4 GB chunks = 4 TB pre-dedup, same rate) | raise the hard limit (`ulimit -Hn`, or the host's limits configuration) before running [`./solve --merge`](SOLVE_C_CLI.md#--merge) *(2026-11-14, Codex final review F12-007#20: this named the shell's default soft limit, which `--merge` raises itself)* |

**Implications.** At any enumeration scale we're realistically considering
(10T through 1,000T), both limits have comfortable headroom with default
settings. The first limit we'd hit in practice is `ulimit -n` (around 900T);
that's a one-line shell setting. Actually running into `MAX_SORTED_CHUNKS`
would require ~3,600T enumerations, which are neither cost-practical nor
currently planned. *(The budgets in this table were previously "~500T" and
"~2,000T", derived from the ~830 GB pre-run projection for 100T; re-derived
2026-09-03 from the measured 443 GB. They are linear extrapolations and, since
measured pre-dedup growth is sub-linear in budget — 5.0× for the 10× step from
10T to 100T — they are lower bounds on the budget at which each limit binds.)*

The solver emits a clear error with the mitigation if either limit is hit —
no silent failure. For runs beyond 1,000T, it's good hygiene to both
`ulimit -n 16384` and set `SOLVE_MERGE_CHUNK_GB=16` before the merge; that
combination gives an ~64 TB pre-dedup ceiling and >4096 concurrent FDs.

**Resource profile by phase:**

| Phase | Bottleneck | Scales with |
|---|---|---|
| Enumeration | cores (one pthread per `SOLVE_THREADS`, ~21M nodes/thread-sec) | node budget (linear) |
| Merge | RAM (`malloc(total_records × 32)`) | pre-dedup shard record count (443 GB of input for 110 GB of unique records at d3 100T) |

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
MB/thread). Merge RAM scales with the pre-dedup input, not the output. *(2026-11-14, Codex final review F12-007#11: this and the table row above said unique solution count / output size)*

**Two-phase pattern:**

1. **Enumeration VM** — lean and core-dense. Writes `sub_*.bin` shards and
   `checkpoint.txt` to the managed data disk. Tears down on completion.
   VM choice: a 128-core Spot VM. (The older compute-optimised family is BANNED on this
   project since 2026-04-19 — see §Ad-hoc VM lifecycle rules, rule 1.)
2. **Data disk survives** the teardown. Shards are the primary artifact; the
   final `solutions.bin` is derived.
3. **Merge VM** — separate and right-sized (by RAM and I/O, not cores),
   launched only when shards are complete. Runs `cd /data && ./solve --merge`,
   writes the merged output back to the same disk, verifies sha256, tears down.
   ⚠ **[CORRECTED 2026-09-01 — this read `./solve --merge /data/solutions.bin`,
   which does not do what it looks like.]** `--merge` takes **no arguments**: it
   sets `arg_offset = argc`, so every following argument is consumed and
   silently discarded — no error, no warning *(that was the behaviour on 2026-09-01; since 2026-09-04 any argument after `--merge` is refused with `MERGE_ARGS=REFUSED` and exit 2, before anything is merged — note 2026-11-03, Codex final review F12-007#19)*. It then scans the **current
   working directory** for `sub_*.bin` shards and writes `solutions.bin` and
   `solutions.sha256` there. Run from `~` on a fresh merge VM, the old command
   therefore finds no shards at all, or — worse — merges whatever stale shards
   happen to be in the CWD, and the operator has a path in their shell history
   that appears to say otherwise. **`--merge` is CWD-relative; `cd` to the shard
   directory first.**
   VM choice: a **right-sized regular-capacity** VM per §Standing policy
   — 16 or 32 cores for 10T–100T, 64 cores at 1000T+. Memory-optimized
   sizes are not used here: merge is a single-threaded heap-sort sized
   by RAM and I/O, and external merge (`SOLVE_MERGE_MODE=external`, shipped)
   keeps a modest size sufficient by streaming chunks instead of buffering
   `total_records × 32 bytes` (pre-dedup) in RAM.

**Wall-time illustration (enum on a 128-core Spot VM, merge on regular capacity — 2026-04-19 measured + projected):**

| Budget | Enum wall | Enum VM | Merge VM |
|---|---|---|---|
| 10T | **1h 23m** (measured) | 128-core, spot | 16-core, regular capacity, for ~50 min |
| 100T | **~14h** (projected) | 128-core, spot | 32-core, regular capacity, + 2 TB SSD for ~2-5h (external) |
| 1000T | ~6-7 days | 128-core, spot | 64-core, regular capacity, + 2 TB SSD for ~30h (external, parallel chunks) |

The merge column follows §Standing policy: **regular capacity and right-sized, never
128 cores and never Spot.** An earlier revision of this table prescribed Spot merges
and 128-core merges — both are withdrawn; the merge-VM wall times are unchanged
because merge is single-threaded and ignores core count.

Legacy figures on the older 64-core compute-optimised size (for historical reference): 10T took 6h enum + 30min merge; 100T was projected with split (never run at scale post-pivot). That size is retired 2026-04-19. The full comparison is in a private report outside the repo.

For ≥100T, external merge with SSD-backed scratch is strictly required (data volume exceeds RAM). For 1000T, parallel-chunk external merge on a large SSD-backed disk is the path.

**Orchestration requirements for the two-phase pattern** (most already exist):

- Enumeration monitor detects completion and tears down the enumeration VM.
  In split mode the enum process returns *before* the completion report and
  before `solve_results.json` is written (the `SOLVE_SKIP_AUTOMERGE` early
  return), so that file never appears on the enum VM: key on solver exit rc=0
  **plus** the whole-line `ENUM_RUN=FINISHED` after the `SOLVE_SKIP_AUTOMERGE set; skipping bundled merge` line in
  `solve_output.txt` (not the skip line alone: a stopped run prints it too, with `ENUM_RUN=STOPPED`) **plus** shard/`shard_manifest.txt` filesystem state — or
  on the supervisor-written `done.marker` / `fail.marker` pair. The
  `SEARCH_COMPLETE` status field in `solve_results.json` is the *single-VM*
  (bundled-merge) signal only: a standalone `./solve --merge` on the merge VM writes no `solve_results.json`, so key the merge on its exit status and the
  `solutions.sha256` it writes beside `solutions.bin`. *(2026-11-14, Codex final review F12-007#1, #2: this said the merge VM writes `solve_results.json` when the merge finishes)* Never key on stderr regex (§Lessons item 4).
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
| 100T | 13.83B records, **443 GB measured** (§100T and beyond) | 109.8 GB measured | **~830 GB** |
| 1000T | ~138B records, ~4.4 TB (linear extrapolation from 100T; measured 10T→100T growth was 5.0× per 10×, so this is an upper bound) | ≥337 GB (the 560T canonical already holds 10,525,271,997 records = 337 GB); ~0.5 TB at the α≈0.67 fit in [CANONICAL_HASHES.md](CANONICAL_HASHES.md) | **~7.5 TB** |

*(Rows corrected 2026-09-03: the 100T row previously carried the ~27.7B / ~830 GB
pre-run projection and a ~1.4 TB disk; the 1000T row was extrapolated from that
projection (~277B / ~8.3 TB / ~13 TB) and estimated `solutions.bin` at
~150–250 GB, which the 560T canonical's 337 GB already exceeds. Arithmetic for
the 100T disk: (442.65 GB + 109.84 GB) × 1.5 = 829 GB — by coincidence the same
magnitude as the retired "~830 GB" pre-dedup projection; the two are different
quantities, and a grep for 830 GB now finds the disk figure, not the projection.)*

At 1000T the disk itself, not the VM, becomes the binding constraint — the raw
figure exceeds a single 2 TB managed disk, so plan for gz-framed shards plus a
multi-disk or staged-archive layout rather than one volume.

Failure direction is loud, not silent: running out of space mid-merge is ENOSPC,
the shards survive on disk, and recovery is a single
`az disk update --size-gb N` + `resize2fs` inside a VM after attach, then
re-merge. No data loss. Preferring the raw-safe number up front costs a sliver of
storage against an aborted multi-hour merge.

**Operational runbook for canonical enumerations ≥11.2T:**

The two-phase architecture above is the right *architecture*. The
*operational* pattern — pre-flight checklists, recovery procedures
for the half-dozen failure modes that have actually occurred in
practice, scale-specific guidance for 100T and 560T — lives in the
**`roae-private/CANONICAL_PIPELINE_RUNBOOK.md`** runbook (private staging
repo). That runbook is the single source of truth for canonical
runs and supersedes earlier ad-hoc scripts. The 2026-05-16/17 v2
11.2T saga (four attempts vs the one expected
first-shot) was the forcing function for the runbook's creation;
the failure modes it documents have all been seen, and the
mitigations are tested. Key non-obvious constraints captured there:

- **Enum OS disk: explicit `--storage-sku <mid-ssd-disk-sku>` (a mid-tier SSD).** Azure
  defaults VM sizes that support the fast SSD tier to it, which is wasted on
  CPU-bound enum.
- **Shards belong on the attached managed disk (the project's data disk),
  not the enum VM's OS disk.** Lose-the-VM-lose-the-shards is what
  drove half the saga's overrun.
- **Trap discipline: NEVER `teardown_enum` in the ERR trap.**
  Phase 2 errors should preserve the enum VM (with shards) so
  recovery is a Phase-2-only re-run, not a full enum redo.
- **`curl -T file` streaming PUT for large files.** `curl --data-binary
  @file` OOMs at ~2 GB regardless of VM RAM.
- **Mount logic must handle existing-ext4** (the data disk has empty
  ext4 from the 2026-05-06 incident wipe; subsequent re-population
  filled 120 GB of operator data into top-level dirs). Always write
  canonical outputs to a `$ARCHIVE_PREFIX/` subdirectory.
- **Mandatory small-VM pre-flight** before any 4h+ enum: validate
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

5. **Managed disks preserved = the win condition for every class of failure.** Eviction, truncation, regex bug — all three recovery scenarios in this project were saved by the data disk surviving VM teardown. Never delete a data disk. Orphan OS disks from deleted VMs are a separate matter: clean those up.

6. **Azure zones bite.** The data disk is non-zonal; the orchestrator VM is zonal. Non-zonal disks cannot attach to zonal VMs (Azure returns `BadRequest`). For recovery VMs that need the data disk, provision as regional (no zone specified). Related: `az vm create --ssh-key-values` has a JSON-parser bug; `az rest --method PUT` is the reliable path.

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
    < /dev/null 2>>ssh_launch.err   # keep ssh's own errors (auth, connection); was 2>/dev/null until 2026-11-03, Codex F12-007#24
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
      `checkpoint_t*.txt`, `progress.txt`, `build.sha` (added 2026-11-03), and the `solutions.*` outputs — see
      §Deployment lifecycle step 6. A partial wipe resumes silently and reports
      success.
- [ ] Persistent volume mount verified
- [ ] Free disk space ≥ estimated output × 1.5 (inputs + outputs both fit). On the merge host the
      in-memory merge's own preflight is stricter: it refuses unless free disk ≥ 2 × pre-dedup
      records × 32 bytes. ⚠ *(Added 2026-09-24, Q-762, CX-82: "output" here is the deduplicated file; the
      merge preflight sizes from the pre-dedup input, as the RAM box below now says.)*
- [ ] Free RAM ≥ estimated working set: the **in-memory** merge allocates every **pre-dedup** shard
      record × 32 bytes at once (`malloc(total_records × 32)`; ≈443 GB at d3 100T, whose 13,832,832,979
      input records dedup to 3,432,399,297, ≈110 GB), and auto mode switches to the external merge when that exceeds
      80% of RAM. Enumeration's own floor is the hash tables: `threads × 512 MB` initial (32,768 MB at 64
      threads), growing at 75% load. ⚠ **[CORRECTED 2026-09-24 (Q-762, CX-82) — this box read "merge needs
      ~uniqueN × 32 bytes in memory", which sizes the buffer from the deduplicated count; the solver
      allocates for all input records.]**
- [ ] `run_id.txt` written after the stale-state wipe and before solver start (compare, wipe, then write — the order of the worked example in §Deployment lifecycle). ⚠ *(Corrected 2026-09-25, Q-763: this read "write BEFORE wipe, not after"; an ID written before an interrupted wipe makes the next launch skip the wipe.)*
- [ ] Monitor started **as a separate process** and verified with `pgrep`
- [ ] Monitor completion-detection signal matches what the solver actually emits **in the mode being run**: the `solve_results.json` status field in single-VM (bundled-merge) mode; in split mode (`SOLVE_SKIP_AUTOMERGE=1`) that file is never written on the enum VM — key on rc=0 + the `skipping bundled merge` line + shard/manifest state, or the supervisor's done/fail markers (§Completion and archival)
- [ ] Post-completion gates configured: `--verify` pass + hash-drop count == 0
- [ ] Sub_*.bin integrity check enabled on eviction resume: `gzip -t` passes and the **decompressed**
      length is a multiple of 32 (`gzip -dc sub_X.bin | wc -c`); on a `SOLVE_COMPRESS=0` raw shard, the file
      size itself. ⚠ **[CORRECTED 2026-09-24 (Q-762, CX-82) — this read "size % 32 == 0". Shards are
      gzip-framed by default since #169, so the on-disk size of a valid shard is a compressed length, and a
      rule that deletes on it removes good shards.]**
- [ ] Watchdog merge-phase exemption verified (don't kill solver during merge)
- [ ] Merge VM is on regular capacity (not spot) — merge has no checkpoint
- [ ] **Pre-launch verification: `az vm show --query priority` matches the workload type** (Spot for enum; null/Regular for merge). See §Standing policy. Skipping this gate caused the 2026-04-19/20 misprovisioning incident.
- [ ] `--merge` code path uses canonical dedup (same as normal-mode merge)
- [ ] Cost estimate presented to user
- [ ] Output-shape sanity checks planned (record count, sub-branch file count)

---

## Appendix A: Azure spot-VM provisioning (reference example)

Concrete example of provisioning an Azure spot VM (a 128-core size in step 3) with an
attached persistent managed disk. This appendix was first written for the
older 64-core compute-optimised size, which is **banned** on this project since 2026-04-19 (§Ad-hoc VM
lifecycle rules, rule 1).
Adapt names, regions, and SKUs to your environment. All commands assume
`az login` has been completed and an SSH keypair exists (here at
`~/.ssh/solver_key{,.pub}`).

### One-time setup (per resource group)

1. **Resource group + persistent data disk.** Create the data disk *once*; it
   will outlive every spot VM that mounts it.

   ```bash
   RG=YOUR-RG
   LOCATION=YOUR-REGION
   az group create -n "$RG" -l "$LOCATION"
   az disk create -g "$RG" -n data-disk \
       --size-gb 160 --sku <hdd-disk-sku> -l "$LOCATION"   # 10T d3 raw-safe; see §Disk sizing for two-phase
   ```

   Size depends on workload — size it from the **inputs** per §Disk sizing for
   two-phase: a depth-3 10T enumeration measured **83 GB** of `sub_*.bin` shards
   plus ~24 GB of `solutions.bin` (§Disk tier matters), i.e. ~160 GB raw-safe;
   100T measured 443 GB of shards (~830 GB raw-safe). *(This step previously
   said `--size-gb 64` with "~23 GB" of shards — the 2026-04-14 bugfix-era
   figure from §Lessons, where a filename collision left only 64 shard files;
   corrected 2026-09-03.)* Provision with headroom
   (≥1.5× expected output total) to avoid the silent-truncation failure
   documented in the lessons section above.

### Per-run provisioning (spot VM + networking)

2. **Networking: private IP only.** Solver VMs live on the same vnet as the
   orchestrator — no public IP, no NSG, no external attack surface. The
   orchestrator SSHes to the solver's private IP directly.

   ```bash
   # One-time: create the shared vnet (orchestrator VM also on this vnet)
   az network vnet create -g "$RG" -n <vnet> -l "$LOCATION" \
       --address-prefix 10.0.0.0/24 --subnet-name default --subnet-prefix 10.0.0.0/24

   # Per-run: NIC with private IP only (no --public-ip-address, no --network-security-group)
   az network nic create -g "$RG" -n worker-nic \
       --vnet-name <vnet> --subnet default -l "$LOCATION"
   ```

   The orchestrator queries the private IP via:
   ```bash
   az network nic show -g "$RG" -n worker-nic \
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
   NIC_ID=$(az network nic show -g "$RG" -n worker-nic --query id -o tsv)
   DISK_ID=$(az disk show -g "$RG" -n data-disk --query id -o tsv)
   SSH_PUB="$(cat ~/.ssh/solver_key.pub)"
   SIZE=YOUR-VM-SIZE  # e.g. a 128-core size; the older 64-core pattern was retired 2026-04-19

   az rest --method PUT \
     --url "https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/$RG/providers/Microsoft.Compute/virtualMachines/worker-vm?api-version=2024-07-01" \
     --body "{
       \"location\":\"$LOCATION\",
       \"properties\":{
         \"hardwareProfile\":{\"vmSize\":\"$SIZE\"},
         \"priority\":\"Spot\",\"evictionPolicy\":\"Deallocate\",
         \"billingProfile\":{\"maxPrice\":-1},
         \"storageProfile\":{
           \"imageReference\":{\"publisher\":\"Canonical\",\"offer\":\"ubuntu-24_04-lts\",\"sku\":\"server\",\"version\":\"latest\"},
           \"osDisk\":{\"createOption\":\"FromImage\",\"managedDisk\":{\"storageAccountType\":\"<hdd-disk-sku>\"}},
           \"dataDisks\":[{\"lun\":0,\"createOption\":\"Attach\",\"managedDisk\":{\"id\":\"$DISK_ID\"}}]
         },
         \"osProfile\":{
           \"computerName\":\"worker-vm\",\"adminUsername\":\"solver\",
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
       state=$(az vm get-instance-view -g "$RG" -n worker-vm \
           --query "instanceView.statuses[?starts_with(code,'PowerState')].displayStatus" -o tsv)
       [ "$state" = "VM running" ] && break
   done
   # This example is private-IP-only (step 2) — there is no public IP to query.
   IP=$(az network nic show -g "$RG" -n worker-nic \
       --query "ipConfigurations[0].privateIPAddress" -o tsv)
   for i in $(seq 1 12); do
       sleep 8
       ssh -i ~/.ssh/solver_key -o StrictHostKeyChecking=no \
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
             /data/progress.txt /data/build.sha || exit 1   # 2026-11-03, Codex F12-007#5/#6: a failed wipe must not stamp the id; build.sha is resume state too
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
   scp -i ~/.ssh/solver_key ./solve.c solver@$IP:~/solve.c
   GH=$(git rev-parse --short HEAD)   # provenance stamp — computed HERE, the VM holds solve.c alone, no clone
   GB=$(git rev-parse --abbrev-ref HEAD)   # the BRANCH half; without it GIT_BRANCH falls back to "unknown"
   ssh ... solver@$IP "gcc -O3 -pthread -fopenmp -DGIT_HASH='\"$GH\"' -DGIT_BRANCH='\"$GB\"' -o solve solve.c -lm -lz"
   # Without -DGIT_HASH the run's solutions.meta.json records "git_hash": "unknown" (sha-neutral either way).
   # Use the §Solver-launch SSH detachment "Required form" — a bare
   # `nohup ... &` over ssh does NOT reliably release the channel and hangs
   # the launcher before it can enter its poll loop.
   timeout 15 ssh -n -i ~/.ssh/solver_key -o StrictHostKeyChecking=no "solver@$IP" \
       "cd /data && SOLVE_THREADS=64 SOLVE_NODE_LIMIT=$NODE_LIMIT \
        setsid nohup ~/solve 86400 > solve_output.txt 2>&1 < /dev/null &" \
       < /dev/null 2>>ssh_launch.err   # ssh's own errors are kept (2026-11-03, Codex F12-007#24)
   sleep 5
   ssh ... solver@$IP 'pgrep -x solve >/dev/null && echo started || echo FAILED'
   ```

### Teardown (preserve managed disk!)

8. **Serialized teardown order.** VM → NIC → OS disk. Parallel deletes hit
   dependency-ordering errors. Delete only what *this* run created: the
   per-run VM, its NIC, and its orphan OS disk. Never delete the data disk,
   and **never delete the shared vnet** — it is shared with the orchestrator
   VM, so deleting it is an incident, not a cleanup. (There is no public IP
   and no NSG in this design; see step 2. The general dependency order when
   a run *does* own those resources is VM → NIC → public IP → NSG → vnet.)

   ```bash
   az vm delete -g "$RG" -n worker-vm --yes
   for i in 1 2 3 4 5 6; do
       state=$(az vm show -g "$RG" -n worker-vm --query provisioningState -o tsv 2>/dev/null)
       [ -z "$state" ] && break
       sleep 5
   done
   az network nic delete -g "$RG" -n worker-nic
   # NOT deleted: <vnet> (shared with the orchestrator) and data-disk.
   # Clean orphan OS disks (don't touch data-disk)
   for d in $(az disk list -g "$RG" --query \
       "[?diskState=='Unattached' && starts_with(name,'worker-vm_OsDisk_')].name" -o tsv); do
       az disk delete -g "$RG" -n "$d" --yes --no-wait
   done
   ```

### Ad-hoc VM lifecycle rules (STRICT — prevents leaked VMs)

For any VM provisioned to mount a disk for a one-off inspection or a short task:

1. The older compute-optimised VM family is retired on this project; never provision it.
2. Pair every `az vm create` with its teardown in the same command sequence, registered
   before the work (an EXIT trap, not an `&&` chain, so a failed step cannot skip it).
3. Keep a session VM log, and reconcile it against the live VM list at session start and
   before the session ends.
4. Never delete a data disk without explicit approval; detach it before deleting the VM.

The full rules, the incidents behind them, sizing by task and the command templates are
in the private operations notes.

### Archival pattern for large `--sub-branch` outputs (>100 MB)

P1's depth-5 parallel exploration produces much larger `sub_*.bin` files
than legacy DFS at the same budget (typically ~500 MB at 10T for rich
branches). These are too big for git-native storage but need preservation
for scientific reproducibility. Established pattern (from 2026-04-22 Pass 1):

1. **Big file stays on the project's managed data disk** at
   `/data/archive/<run-label>/<branch>/sub_<branch>.bin`. Attach the disk
   temporarily to the source VM, `cp` the file, `sync && umount`, detach.
2. **Commit only the small artifacts** to the public repo at
   `runs/<YYYYMMDD>_<label>/<branch>/`:
   - `sub_<branch>.sha256` — 1 line, the sha256 of the big file
   - `sub_<branch>.meta.json` — params, yield, wall, rate, solver commit, archive location
   - `run.log.gz` — solver stdout gzipped (~20-30 KB)
   - `checkpoint.txt` — final status line from solve.c
3. **Top-level `README.md`** in the run directory summarizing parameters,
   results, growth analysis and conclusion.

Verification recipe: attach the data disk to any VM with 2 or more cores, then:
```bash
cd /data/archive/<run-label>/<branch>
# The .sha256 sidecar holds the LOGICAL (decompressed) sha, not the sha of the
# bytes on disk — see SOLUTIONS_FORMAT.md §"On-disk framing". Since #169
# (d8671550, 2026-06-17) shards are gz-framed by DEFAULT, so `sha256sum -c`
# hashes the gzip CONTAINER and reports FAILED on a byte-correct artifact.
# Compare against the logical stream instead:
set -o pipefail                           # REQUIRED: without it a gzip failure is
                                          # swallowed and sha256sum hashes an EMPTY
                                          # stream (e3b0c442…) with exit status 0
gzip -dcf sub_<branch>.bin | sha256sum    # -f: non-gzip (raw) input is copied
                                          # through unchanged, so this one line is
                                          # right for BOTH framings
head -1 sub_<branch>.sha256               # the hash above must match this line

# CORRECTED 2026-09-03 (Q-406): this recipe read `gzip -dc … | sha256sum` with no
# `-f` and no pipefail. On a RAW shard (anything written before #169, or under
# SOLVE_COMPRESS=0) gzip exits non-zero and writes nothing, sha256sum hashes the
# empty stream, and the pipeline exits 0 reporting
#   e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
# — a silent false MISMATCH on a byte-correct artifact, the same phantom-drift
# direction that burned ~6 h on 2026-05-31. Measured 2026-09-03 with gzip 1.12:
# `gzip -dc` on raw → e3b0c442… rc=0; `gzip -dcf` → the logical sha on both a raw
# and a gz-framed file; a truncated gz under `-dcf` returns rc=1 only WITH pipefail.
# ERA NOTE. For raw shards — including the 2026-04-22 and 2026-04-23 pass-A/pass-B
# archives — logical and on-disk bytes are the same, so
#     sha256sum -c sub_<branch>.sha256
# is also correct; it is WRONG for gz-framed shards (it hashes the container).
# Sniff the first two bytes to tell them apart: `1f 8b` is gz-framed, anything else is raw (a raw `sub_*.bin` shard has no `ROAE` header, so it starts with a record; `ROAE` marks a header-bearing solutions.bin -- corrected 2026-11-03, Codex final review F12-007#18).

./solve --verify sub_<branch>.bin  # per-record C1-C5 check, framing auto-detected
```

### Zone caveat for analysis VMs

If the data disk was created without a zone (`zones: null`) but a primary VM is
zonal, the disk cannot attach to that VM (Azure returns `BadRequest`). For a
recovery / analysis VM that needs to mount the data disk, **provision without a
zone** (omit `--zone` and don't specify a `zone` in the resource definition
above). Once attached to the new VM, mount as in step 5.

### Quota accounting — deallocated VMs still hold your quota

Interruptible (Spot) and regular capacity draw on separate quota buckets, and each
bucket counts every VM that has not been deleted, running or deallocated. Before
leaving a large VM deallocated "for later", ask whether a different-sized VM will be
needed meanwhile; if so, delete this one instead (the data disks persist). The bucket
table, the worked example and the verification commands are in the private
operations notes.

### Single-branch parallel (`--sub-branch`) — VM sizing

**Applies when:** running one `./solve --sub-branch <p1> <o1> <p2> <o2> <p3> <o3>`
invocation with the P1 parallel code path (auto-on when `SOLVE_THREADS > 1`;
force-off via `SOLVE_SUB_BRANCH_PARALLELISM=single`).

**Task granularity: depth-5** (commit `201d706` onward). Each depth-3 prefix
generates typically 900-3600 tasks at (p4, o4, p5, o5) granularity. The test
branch `22 0 30 1 20 0` produces 2,507 tasks.

**Measured scaling on Zen 5c "Turin Dense" (Spot), 50B-node budget**:

| Threads | Wall | Speedup | Efficiency |
|---|---|---|---|
| 1 | 1,820s | 1× | 100% |
| 32 | 77.7s | 23.4× | 73% |
| 64 | 52.1s | 34.9× | **55%** ← knee of the curve |
| 96 | 51.0s | 35.7× | 37% |
| 128 | 49.9s | 36.5× | 29% |

⚠ **[CORRECTED 2026-09-24 (Q-762, CX-82) — the 1-thread cell read `182s`, a factor of ten below the
baseline its own columns use.** Every speedup and efficiency in the table divides **1,820 s** by the row's
wall: 1820/77.7 = 23.4×, 1820/52.1 = 34.9×, 1820/51.0 = 35.7×, 1820/49.9 = 36.5×, while 182/52.1 would be
only 3.49×. The cell now carries the value the table was computed from. It was not re-measured; no other
cell moves.]**

**Key finding: memory bandwidth saturates at ~N=64.** Going from 64 → 128 cores
gives only 4% additional speedup, for double the cores.

**VM-size recommendations for single-branch (single process per VM):**

| Scenario | Recommended VM | Per-branch wall (50B budget) |
|---|---|---|
| Wall-time critical, one branch | 128-core spot VM, K=1 N=128 | 51s wall *(2026-11-14, Codex final review F12-007#7: the parallel `--sub-branch` path clamps its workers to 64 and has since it was committed on 2026-04-22, so `SOLVE_THREADS=128` or a positional 128 starts 64 workers, as its `Parallel --sub-branch: … worker threads` line says; N=128 cannot be run as written, and this row is the 2026-04-21 measurement only)* |
| **Balanced, one branch** | **64-core spot VM, K=1 N=64** | 72s wall |
| Noisy-neighbor tolerant | 32-core spot VM, K=1 N=32 | ~78s wall, projected |

**Packing (multiple concurrent `--sub-branch` processes on one VM) — for batches:**

A single VM can run K concurrent `--sub-branch` processes, each with N threads
(total K×N threads ≤ VM cores). Each process writes its own output directory.
**Measured 2026-04-21**: packing breaks through the single-process atomic
contention ceiling and produces higher aggregate throughput.

| VM | Best packing | Wall (8 branches × 50B each) |
|---|---|---|
| 128-core (256 GB) | K=8 N=16 (or K=16 N=8) | 257s (K=8) / 501s for 16 branches (K=16) |
| **64-core (128 GB)** | **K=8 N=8** | **491s** ← the recommended packing |
| 32-core (64 GB) | K=8 N=4 | 963s |

**On the 128-core VM, aggregate throughput rises from 980 M/s (K=1 N=128) to 1.60 B/s (K=16 N=8)** — a 60%+ improvement — because each process has its own atomic
counter and cache-resident hash table, breaking through the single-process
atomic-contention ceiling.

**Recommendations by scenario:**

| Scenario | Recommended |
|---|---|
| 1 branch, ASAP | **128-core spot, K=1 N=128** (64 workers on the current build; see the F12-007#7 note above) |
| 1 branch, fewer cores | **64-core spot, K=1 N=64** |
| 8-branch batch, packed | **64-core spot, K=8 N=8 packing** |
| 16-branch batch, balanced | 64-core K=8 × 2 VMs parallel, OR 128-core K=16 N=8 |
| Campaign (100+ branches), packed | **Many 64-core VMs in parallel, each K=8 N=8 packing** |
| Campaign, wall-time-critical | Many 64-core VMs in parallel, each K=8 N=8 (same as above — measured optimum) |

**Never the 128-core VM for a single `--sub-branch` run** unless wall-time dominates —
its no-co-tenant guarantee is valuable, but it uses ~40% more core-seconds per branch
than a 64-core K=1 run for just 20s faster wall.

**Secondary options (if 64/128-core spot quota is tight):** a second region
may have its own spot quota; use it if the first is constrained. Regular (non-interruptible) capacity avoids evictions.
The older compute-optimised family is retired on this project (see §Ad-hoc VM lifecycle rules, rule 1).

**Full measurement data + packing-mechanism analysis + campaign-planning math:**
`roae-private/P1_SCALING_MEASUREMENTS.md` (staging repo).

### Machine size reference (2026-04-19, after the move to the current VM family)

| VM | Cores | RAM | Use case |
|---|---|---|---|
| **Enumeration VM** | 128 | 256 GB | **Enumeration ≥10T (new default)** |
| **Large merge / packing VM** | 64 | 128 GB | 1000T+ external merge (regular capacity, §Standing policy); `--sub-branch` K=8 N=8 packing (Spot) |
| **10T merge VM** | 16 | 32 GB | 10T merge, external (regular capacity, §Standing policy) |
| **Analysis VM** | 4 | 8 GB | Analysis / --analyze / --verify |
| Orchestrator VM | 2 | 8 GB | Orchestrator |
| Older compute-optimised VM | 64 | 128 GB | **RETIRED 2026-04-19** (historical reference only) |
| HDD-backed managed disk | — | — | Persistent `/data` (archival shards + solutions.bin); 300 GB → 2 TB |
| SSD-backed managed disk, 512 GB / 2 TB | — | — | External-merge temp scratch (attached-for-merge only) |

#### Machine size to RAM reference

*(The single size→RAM reference for this project; added 2026-09-01.)*

Every core-count-to-RAM figure for the current VM family published anywhere in this project must match
this table. The table exists because the figures did **not** match: several
sites doubled them, and the project acted on the wrong figure once already.

| Size | vCPU | RAM |
|---|---:|---:|
| 4-core | 4 | 8 GB |
| 16-core | 16 | 32 GB |
| 32-core | 32 | 64 GB |
| 64-core | 64 | **128 GB** |
| 96-core | 96 | 192 GB |
| 128-core | 128 | **256 GB** |

**The rule is 2 GB per vCPU**, because the sizes this project uses are the
**low-memory** variant (one letter in the size name marks it). The standard-memory variant at the same core
count carries twice the RAM — 256 GB at 64 cores, where the low-memory size has 128 GB.

🔴 **This is a lesson learned the hard way, not a spec-sheet transcription.** During the
100T pilot the project had to move a consolidation step from the low-memory 64-core size (128 GB
RAM) to **the standard-memory 64-core size (256 GB RAM)**, having assumed the low-memory size
was 256 GB ([HISTORY.md](HISTORY.md), 100T-pilot entry). The two size names
differ by that one letter and their memory differs by 2×. When sizing a merge by
RAM, read the size name character by character.

Spot capacity can be evicted at any time; set `--max-price` deliberately
(`-1` means no eviction on price alone). Spot evictions on the older 64-core size averaged ~1 per 3 hours during
April 2026 testing — concrete numbers in the lessons section above.

These commands are the manual reproduction of what an orchestrator does
automatically. For a programmatic orchestrator, use the same primitives in your
shell of choice (`bash`, `pwsh`) or Azure SDK; the rules in the architecture and
lessons sections above still apply regardless of language.
