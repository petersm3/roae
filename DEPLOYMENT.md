# Deployment notes for long solver runs

This documents infrastructure-agnostic lessons for running `solve` on remote VMs
for multi-hour (or multi-day) enumerations. Cloud-specific examples (Azure spot
VMs) appear at the end as an appendix; the architectural rules earlier in this
doc apply on any provider.

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
- **Checkpoint rotation.** `checkpoint.txt` → `.1` → `.2` on each update, so a
  corrupted latest file still leaves two prior generations for recovery.

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

- Monitor detects completion by solver exit plus presence of `solve_results.json`.
- Copy **all** outputs locally before tearing down the VM: `solutions.bin`,
  `solutions.sha256`, `solve_output.txt`, `solve_results.json`, `checkpoint.txt`,
  and any `sub_*.bin` shards. Sha-verify before deallocating.
- Archive to `solve_c/runs/<YYYYMMDD>_<label>/`.

## Checkpoint granularity must match eviction frequency

The 2026-04-13 100T attempt exposed a fundamental mismatch: sub-branch-level
checkpointing (committing `sub_P_O.bin` only when a sub-branch finishes its
~33B node budget) is too coarse for spot VMs in westus2.

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

**Resource profile by phase:**

| Phase | Bottleneck | Scales with |
|---|---|---|
| Enumeration | cores (64 pthreads, ~21M nodes/thread-sec) | node budget (linear) |
| Merge | RAM (`malloc(total_records × 32)`) | unique solution count |

Enumeration RAM is flat (~10 GB regardless of budget: 64 per-thread hash
tables of ~134 MB each, plus OS). Merge RAM scales with output size.

**Two-phase pattern:**

1. **Enumeration VM** — lean and core-dense. Writes `sub_*.bin` shards and
   `checkpoint.txt` to the managed data disk. Tears down on completion.
   VM choice: F-series at the budget's preferred core count.
2. **Data disk survives** the teardown. Shards are the primary artifact; the
   final `solutions.bin` is derived.
3. **Merge VM** — separate, memory-dense SKU, launched only when shards are
   complete. Runs `./solve --merge /data/solutions.bin`, writes the merged
   output back to the same disk, verifies sha256, tears down.
   VM choice: E- or M-series sized to `unique_records × 32 bytes × 1.3`
   headroom. Or use an external-merge implementation (see future work) and
   stay on a modest SKU.

**Cost illustration (westus2 spot, 2026-04 prices, approximate):**

| Budget | Enum wall | Enum VM | Enum cost | Merge VM | Merge cost | Two-phase total | Single-VM (equiv merge SKU) |
|---|---|---|---|---|---|---|---|
| 10T | ~2.1h | F64 ($0.79/h) | ~$1.70 | F32 or E64 for ~15 min | ~$0.20 | **~$1.90** | ~$3.00 on E64 |
| 100T | ~21h | F64 | ~$17 | E64 ($1.40/h) for ~30 min | ~$0.70 | **~$18** | ~$30 on E64 / ~$46 on M64 |
| 1000T | ~9d | F64 | ~$170 | M128 ($4.50/h) for ~1h | ~$5 | **~$175** | ~$970 on M128 |

Savings scale with wall-clock time; for ≥100T the split is strictly cheaper.
For 1000T, running merge-on-enumeration-VM isn't viable at all (not enough RAM
on F-series).

**Orchestration requirements for the two-phase pattern** (most already exist):

- Enumeration monitor detects `SEARCH_COMPLETE` via `solve_results.json`
  (JSON status field, not stderr regex) and tears down the enumeration VM.
- Managed data disk survives. Run-ID file on disk identifies the run.
- A separate merge script provisions the merge VM, attaches the same disk,
  verifies the run-ID matches, runs `./solve --merge`, copies the resulting
  `solutions.bin` + `solutions.sha256` locally, verifies by re-hashing,
  tears down the merge VM.
- Both scripts share the same lifecycle-event log for eviction telemetry.

**Disk sizing for two-phase:**

The data disk must hold (`sub_*.bin` shards) + (`solutions.bin`) simultaneously
during the merge. Effectively **2× the final output size**, plus overhead.

| Budget | Est. `solutions.bin` | Disk size |
|---|---|---|
| 10T | ~24 GB | 64 GB (current) |
| 100T | ~60–120 GB | resize to 200–300 GB |
| 1000T | ~150–250 GB | resize to 500 GB–1 TB |

Resize is a single `az disk update --size-gb N`, then `resize2fs` inside a
VM after attach. No data loss.

## Lessons from the 2026-04-14 10T bugfix run and recovery

1. **A reproducible sha256 is not a proof of correctness.** The solver's `sub_*.bin` filenames collided — 3030 sub-branches shared only 64 unique filenames, so later writes silently overwrote earlier solutions. Every run produced the same (wrong) sha256 because the bug was deterministic. "It reproduces, so it's right" was exactly the wrong conclusion. Always cross-check output *shape* (record counts, file counts, per-sub-branch yields) against what the architecture predicts, not just sha256 stability.

2. **Silent `fwrite` failures are the worst class of bug.** The 10T run's final `solutions.bin` was truncated from 23.7 GB to 8 GB because the managed disk ran out of space mid-write. The `fwrite` return value was never checked. `solutions.sha256` was computed *after* the truncation so the sha validated the corrupt file against itself — no sign of error until a human noticed the size didn't match the record count in `solve_output.txt`. Audit every `fwrite`/`fopen`/`fclose` return value; end-to-end verification must compare in-memory computation to reread-from-file.

3. **Disk capacity must be sized for inputs *plus* outputs.** 32 GB was adequate for `sub_*.bin` files (~23 GB) but not for the final `solutions.bin` (~23.7 GB) on the same disk. Preflight: free disk ≥ estimated_output × 1.5 before any long run. If the preflight fails, either resize the disk first or abort.

4. **Monitor completion detection must match the solver's actual output format.** The 10T monitor greped for `"SEARCH COMPLETE\|TIMED OUT"` but the solver writes `"SEARCH_COMPLETE"` (underscore, machine-readable) to `solve_results.json`. Monitor concluded the run had failed, tore down the VM, and reported an error — while `solutions.bin` sat safely on the preserved managed disk. Lesson: monitors should consume stable machine-readable markers (status field in JSON) rather than stderr text whose format evolves.

5. **Managed disks preserved = the win condition for every class of failure.** Eviction, truncation, regex bug — all three recovery scenarios in this project were saved by `solver-data` surviving VM teardown. Never delete a data disk. Orphan OS disks from deleted VMs are a separate matter: clean those up.

6. **Azure zones bite.** The `solver-data` disk is non-zonal; the primary `claude` VM is in zone 2. Non-zonal disks cannot attach to zonal VMs (Azure returns `BadRequest`). For recovery VMs that need `solver-data`, provision as regional (no zone specified). Related: `az vm create --ssh-key-values` has a JSON-parser bug; `az rest --method PUT` is the reliable path.

7. **Azure resource teardown is dependency-ordered.** VM → NIC → public-IP → NSG → VNet, sequential. Parallel deletes all return exit 1 because dependents still hold references. Orchestrators must serialize.

## Pre-launch checklist

- [ ] Previous monitor and checkpoint state cleaned or explicitly resumed (run_id guard)
- [ ] Persistent volume mount verified
- [ ] Free disk space ≥ estimated output × 1.5 (inputs + outputs both fit)
- [ ] Free RAM ≥ estimated working set (merge needs ~uniqueN × 32 bytes in memory)
- [ ] `run_id.txt` written before solver start
- [ ] Monitor started **as a separate process** and verified with `pgrep`
- [ ] Monitor completion-detection string matches what the solver actually emits (ideally a JSON status field, not stderr text)
- [ ] Cost estimate presented to user
- [ ] Output-shape sanity checks planned (record count == expected sub-branches × avg_yield, sub-branch file count not capped at a small number)

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

2. **Networking primitives.** vnet, public IP, NSG with SSH allowed, NIC.

   ```bash
   az network vnet create -g "$RG" -n spot-vnet -l "$LOCATION" \
       --address-prefix 10.0.0.0/16 --subnet-name default --subnet-prefix 10.0.0.0/24
   az network public-ip create -g "$RG" -n spot-pip -l "$LOCATION" --sku Standard
   az network nsg create -g "$RG" -n spot-nsg -l "$LOCATION"
   az network nsg rule create -g "$RG" --nsg-name spot-nsg -n AllowSSH \
       --priority 100 --access Allow --protocol Tcp --destination-port-ranges 22
   az network nic create -g "$RG" -n spot-nic --vnet-name spot-vnet \
       --subnet default --public-ip-address spot-pip --network-security-group spot-nsg \
       -l "$LOCATION"
   ```

3. **Spot VM with managed-disk attached.** `az vm create` has a JSON parser bug
   when used with `--ssh-key-values` in some CLI versions; using `az rest` with
   the raw VM resource definition is the reliable path:

   ```bash
   SUB_ID=$(az account show --query id -o tsv)
   NIC_ID=$(az network nic show -g "$RG" -n spot-nic --query id -o tsv)
   DISK_ID=$(az disk show -g "$RG" -n solver-data --query id -o tsv)
   SSH_PUB="$(cat ~/.ssh/f64_key.pub)"
   SIZE=Standard_F64als_v6  # or F32als_v6 for analysis-only sessions

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
   IP=$(az network public-ip show -g "$RG" -n spot-pip --query ipAddress -o tsv)
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
   ssh ... solver@$IP '
   sudo mkdir -p /data
   for dev in /dev/nvme0n1 /dev/nvme0n2 /dev/sdc /dev/sdd; do
       [ -b "$dev" ] || continue
       ls ${dev}p1 2>/dev/null && continue   # has a partition table → OS disk
       sudo mount "$dev" /data 2>/dev/null && break
       sudo mkfs.ext4 -F "$dev" 2>/dev/null && sudo mount "$dev" /data && break
   done
   sudo chown solver:solver /data
   '
   ```

### Deployment lifecycle (do not delete the data disk)

6. **Run-ID guard before solver start.** Compare the disk's `run_id.txt` to the
   intended run ID and only wipe stale data if they differ; resume otherwise.

   ```bash
   ssh ... solver@$IP "
   if [ \"\$(cat /data/run_id.txt 2>/dev/null)\" != \"$RUN_ID\" ]; then
       rm -f /data/sub_*.bin /data/solutions.bin /data/solutions.sha256 \
             /data/solve_output.txt /data/solve_results.json \
             /data/checkpoint.txt /data/checkpoint.txt.* /data/progress.txt
   fi
   echo '$RUN_ID' > /data/run_id.txt
   "
   ```

7. **Compile and launch the solver.** The solver binary stays on the OS disk
   under `~/solve`; output goes to `/data` (managed disk).

   ```bash
   scp -i ~/.ssh/f64_key ./solve.c solver@$IP:~/solve.c
   ssh ... solver@$IP 'gcc -O3 -pthread -o solve solve.c'
   ssh ... solver@$IP "cd /data && SOLVE_THREADS=64 SOLVE_NODE_LIMIT=$NODE_LIMIT \
       nohup ~/solve 86400 > solve_output.txt 2>&1 &"
   sleep 5
   ssh ... solver@$IP 'pgrep -x solve >/dev/null && echo started || echo FAILED'
   ```

### Teardown (preserve managed disk!)

8. **Serialized teardown order.** VM → NIC → public IP → NSG → vnet. Parallel
   deletes hit dependency-ordering errors. Never delete `solver-data`.

   ```bash
   az vm delete -g "$RG" -n solver-vm --yes
   for i in 1 2 3 4 5 6; do
       state=$(az vm show -g "$RG" -n solver-vm --query provisioningState -o tsv 2>/dev/null)
       [ -z "$state" ] && break
       sleep 5
   done
   az network nic delete -g "$RG" -n spot-nic
   az network public-ip delete -g "$RG" -n spot-pip
   az network nsg delete -g "$RG" -n spot-nsg
   az network vnet delete -g "$RG" -n spot-vnet
   # Clean orphan OS disks (don't touch solver-data)
   for d in $(az disk list -g "$RG" --query \
       "[?diskState=='Unattached' && starts_with(name,'solver-vm_OsDisk_')].name" -o tsv); do
       az disk delete -g "$RG" -n "$d" --yes --no-wait
   done
   ```

### Zone caveat for analysis VMs

If the data disk was created without a zone (`zones: null`) but a primary VM is
zonal, the disk cannot attach to that VM (Azure returns `BadRequest`). For a
recovery / analysis VM that needs to mount `solver-data`, **provision without a
zone** (omit `--zone` and don't specify a `zone` in the resource definition
above). Once attached to the new VM, mount as in step 5.

### Cost reference (westus2, 2026-04 spot prices)

| SKU | RAM | Use case | Spot price | On-demand |
|---|---|---|---|---|
| F64als_v6 | 128 GB | Solver runs (64 cores) | ~$0.79/hr | ~$3.16/hr |
| F32als_v6 | 64 GB | Analysis sessions | ~$0.20-0.30/hr | ~$1.58/hr |
| D2as_v6 | 8 GB | Orchestrator / claude VM | ~$0.09/hr | ~$0.36/hr |
| Standard HDD 64 GB managed disk | — | Persistent `/data` | — | ~$3/mo |

Spot prices fluctuate; check the Azure spot pricing page or set `--max-price`
defensively. Spot evictions in westus2 under F64 averaged ~1 per 3 hours during
April 2026 testing — concrete numbers in the lessons section above.

These commands are the manual reproduction of what an orchestrator does
automatically. For a programmatic orchestrator, use the same primitives in your
shell of choice (`bash`, `pwsh`) or Azure SDK; the rules in the architecture and
lessons sections above still apply regardless of language.
