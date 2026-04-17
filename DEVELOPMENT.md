# Development notes

Notes for anyone picking up this project — human or AI — who wants to reproduce
the results, extend the analysis, or continue the engineering work.

This is a *conventions* document, not a *reference*. Concrete technical details
live in:

- [solve.c](solve.c) top-of-file comment — architecture, all run modes, bug
  history, build flags, environment variables.
- [HISTORY.md](HISTORY.md) — day-by-day project narrative, including missteps
  and the forensic trail that led to each correction.
- [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md) — plain-language findings.
- [SPECIFICATION.md](SPECIFICATION.md) — formal constraint definitions.
- [CRITIQUE.md](CRITIQUE.md) — limitations, statistical caveats.
- [DEPLOYMENT.md](DEPLOYMENT.md) — cloud-VM deployment architecture + lessons.
- [enumeration/LEADERBOARD.md](enumeration/LEADERBOARD.md) — current state of
  the enumeration.

---

## Project conventions

### "Proven" language must be universal or explicitly scoped

Any claim calling something "proven" must be a universal/formal proof. If the
proof is scoped (e.g., a computational finite-case check over a specific
dataset), the scope must be stated explicitly in the same sentence.

- Universal: "proven"
- Scoped: "proven for the 742M dataset", "proven at 10T node budget",
  "exhaustively verified for all 4,495 three-subsets against the current
  dataset"
- Acceptable weaker alternatives: "exhaustively verified", "empirically
  confirmed", "no counterexamples found among N tested"

Same rule applies to synonyms: "theorem", "guaranteed", "verified formally".
These imply universality.

This convention emerged from the 2026-04-14 bug discovery: an earlier
"31.6 million unique orderings" figure was a ~23× undercount, but the bug was
deterministic so the sha256 reproduced. Claims couched as "proven" retrospectively
became "proven only under a specific bug." Explicit scoping prevents this.

### A reproducible sha256 is not a proof of correctness

Deterministic code that produces the same output on every run only proves that
the bug (if any) is reproducible. Output *shape* must also be cross-checked
against what the architecture predicts — record counts, file counts, expected
ratios. The sub-branch filename collision bug was invisible to sha-based audits
because the bug was deterministic. It was caught by `ls sub_*.bin | wc -l` (saw
47 files where the architecture predicted ~3030).

Always include at least one "does the output shape match the architecture"
check in any new analysis.

### Dataset-scope any quantitative claim

"742M unique orderings" is a lower bound for the 10T enumeration, not the true
count. Every per-sub-branch enumeration hit the per-sub-branch node budget
rather than completing naturally, so more solutions likely exist beyond the
enumerated space. When citing quantitative results, note the enumeration depth
(10T, 100T, etc.) and whether the budget was saturated.

### Asset preservation

- **Managed data disks are never deleted.** The persistent `solver-data` volume
  holds committed solver work (sub_*.bin files, solutions.bin). Between runs,
  VMs come and go; the data disk stays. On cleanup, delete the VM and its
  orphan OS disk, preserve the data disk.
- **sha256 files are committed but solutions.bin is excluded.** The 23.7 GB
  solutions.bin lives on the managed disk, not in the git repo. `enumeration/
  solutions.sha256` lets anyone verify their own reproduction.
- **Analysis outputs (text, small) are committed.** `enumeration/
  analyze_c_742M.txt`, `analyze_section14_742M.txt`, etc. serve as
  reproducibility references.

### Storage strategy: parallel redundancy and long-term archival

The managed disk is the *working* copy of large artifacts, not the *durable*
copy. Two things motivate a separate backup tier:

1. **Accidental deletion or corruption.** A disk wipe, a rogue `az disk delete`,
   or a mount-point bug can lose the primary copy in seconds. Managed disks
   have Azure's 11-9s durability guarantee, but the operator (me or a future
   session) is the real risk.
2. **Cost during long pauses.** At 23.7 GB (10T) or 80-260 GB (1000T), keeping
   a managed disk idle between sessions costs $0.04-0.40/GB/month. For a
   multi-month pause, that adds up fast. Blob Archive tier is ~40× cheaper
   per GB.

**Parallel-backup policy (run immediately after any canonical run):**

For every canonical enumeration (10T, 100T, 1000T, or any run that produces a
sha256 referenced in committed docs):

1. After sha256 verification of `solutions.bin` on the working disk,
   upload to Azure Blob Storage with the Archive access tier:
   ```
   az storage blob upload \
     --account-name <storage-account> \
     --container-name roae-archives \
     --name <run-id>/solutions.bin \
     --file /data/solutions.bin \
     --tier Archive
   ```
2. Alongside `solutions.bin`, upload (Archive tier for all):
   - `solutions.sha256` — validates any future download
   - `solve_results.json` — run metadata
   - The compiled `solve` binary used for the run (~100 KB)
   - `git rev-parse HEAD` written to a `git_hash.txt` (~50 bytes)
   - `checkpoint.txt` — per-sub-branch yield data (needed for saturation
     analysis at any future scale)
   - A README documenting run date, `SOLVE_NODE_LIMIT`, VM SKU, total cost
3. Sha-verify the upload by downloading the blob's sha256 file and comparing.
4. Once verified: the managed disk remains authoritative for active work;
   the blob is the durable backup.

The 10T canonical run (`aa1415174c...b719b`, 23.7 GB) is the first candidate.
At Archive-tier pricing (~$0.00099/GB/month) the 10T backup is ~$0.02/month
— essentially free insurance.

**Validation-first approach for major solver refactors.** When significant
enumeration-path refactoring occurs (e.g., the Option B depth-3 work-unit
rewrite for 100T), re-run the 10T enumeration with the new solve.c *before*
archiving and *before* deploying 100T. If the retooled solve.c produces the
same `solutions.bin` sha256 (`aa1415174c...b719b`), that proves the refactor
did not alter enumeration semantics. Only after this sha-identity check
passes should the 10T output be archived and the 100T run deployed. The
refactor might touch infrastructure (checkpointing granularity, work-unit
partitioning) without changing the enumeration output; the sha-identity
check distinguishes these cases.

**Archive folder taxonomy.** For auditability and retrieval:
- Folder name: `<run-name>_<YYYYMMDD>_<sha8>/` where `sha8` is the first 8 hex
  chars of solutions.bin's sha256. Example: `10T_20260414_aa141517/`.
- The sha8 in the folder name self-describes the run identity without opening
  blobs. Multiple runs with identical sha8 (deterministic re-validation) are
  distinguishable by date.
- Inside each folder: `solutions.bin`, `solutions.sha256`, `solve_results.json`,
  `checkpoint.txt`, `solve` binary, `git_hash.txt`, `README.txt`.

**Long-term pause procedure (when stepping away for weeks-to-months):**

1. Ensure the parallel backup above exists and has been sha-verified.
2. Optionally download a local copy to operator-controlled hardware (external
   SSD, home server) as a third tier of redundancy. Cost: one-time transfer.
3. **Delete the managed disk** (only after both blob backup and, if chosen,
   local backup are verified). Drops ongoing storage cost from
   ~$0.04/GB/month to ~$0.001/GB/month. For 260 GB over 6 months this is
   ~$64 saved.
4. Delete all VMs. Full idle state.

**Rehydration procedure (resuming work):**

1. Request rehydration from Archive to Hot tier:
   ```
   az storage blob set-tier \
     --account-name <storage-account> \
     --container-name roae-archives \
     --name <run-id>/solutions.bin \
     --tier Hot --rehydrate-priority Standard
   ```
   Standard priority: 1-15 hour wait, cheapest. High priority: <1 hour, costs
   a few dollars for multi-GB blobs.
2. Poll rehydration status: `az storage blob show --query properties.rehydrationStatus`
3. Create a new managed disk sized for the run (see "Running on cloud"
   section for sizing), provision merge VM, attach disk.
4. Download blob to disk inside the VM (free within-region egress, ~10-30 min
   at spot VM network speeds for 260 GB).
5. Sha-verify against the preserved `solutions.sha256`.
6. Resume.

**Cost-tier reference (westus2, April 2026 approximate):**

| Tier | $/GB/month | Min retention | Restore time |
|---|---|---|---|
| Managed Disk (Standard HDD) | $0.041 | none | instant (attach) |
| Blob Hot | $0.018 | none | instant |
| Blob Cool | $0.010 | 30 days | seconds |
| Blob Cold | $0.0036 | 90 days | hours |
| **Blob Archive** | **$0.00099** | **180 days** | **1-15 hours** |

Archive tier's 180-day minimum retention matches the "several months pause"
use case naturally. Shorter pauses may prefer Cold (90-day minimum) or even
keeping the managed disk.

**What we do NOT back up to archive:**

- The `claude` orchestration VM's OS disk (trivially reproducible via
  `git clone` and standard setup).
- Intermediate `sub_*.bin` shards when a merged `solutions.bin` exists. The
  merged bin is the canonical derived artifact; shards can be regenerated
  only by re-running the enumeration, which the sha256 of `solutions.bin`
  still anchors against.
- Analysis output text files (`analyze_*_742M.txt`) — these are committed to
  the git repo and live there.

---

## Known gotchas

### Compile

- Build flags: `gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm`
- `-fopenmp` parallelizes the `--analyze` hot loops. Without it, pragmas are
  no-ops and everything still compiles + runs single-threaded. `libgomp`
  (gcc's OpenMP runtime) ships with gcc under the GCC Runtime Library
  Exception, so no LICENSE.md change is needed.
- `-march=native` enables popcount / AVX intrinsics. Required for the
  `__builtin_popcountll` paths to hit hardware popcount.

### Solver

- **Never assume `fwrite` succeeded without checking.** The 2026-04-14
  `solutions.bin` was silently truncated from 23.7 GB to 8 GB because the disk
  filled up mid-write. The solver's sha256 still matched the truncated file
  (sha was computed post-write from what landed on disk). Every `fwrite`,
  `fopen`, `fclose` should have its return value checked.
- **Preflight disk space**: `free_disk >= estimated_output × 1.5`. At 10T the
  sub_*.bin shards total ~23 GB AND the final solutions.bin is ~24 GB —
  together they exceed a naive 32 GB disk.
- **Per-sub-branch filenames include the full (p1, o1, p2, o2) key**. Earlier
  versions keyed only on (p2, o2), causing silent overwrites. Never narrow the
  file-naming key without proving no collisions can occur.
- **`INTERRUPTED` status conflates external interruption with per-sub-branch
  budget exhaustion.** Resume re-runs both. Budget-exhausted sub-branches
  produce deterministic output and could in principle be safely skipped on
  resume with the same budget — but you'd need a "BUDGETED" tag distinct from
  "INTERRUPTED" and budget comparison logic on resume. Tracked as future work.
- **Hash table insertion has a 64-probe cap.** If a cluster of 64+ consecutive
  slots is occupied, the record is SILENTLY DROPPED (no counter, no warning).
  Mitigated by oversizing the table (4M slots vs typically <1M entries) but
  theoretically possible at higher load. Tracked as future work.
- **solve.c uses pthreads; solve.c's `--analyze`, `--validate`, `--prove-*`
  use OpenMP.** Don't mix both in the same phase of execution — they compete
  for cores. The main enumeration uses pthreads only; OpenMP is confined to
  post-enumeration modes.
- **Enumeration and merge have very different resource profiles — run them
  on separate VMs.** Enumeration is core-bound (64 pthreads, ~10 GB RAM flat);
  merge is RAM-bound (`malloc(unique_records × 32)`). At 100T the merge needs
  ≥128 GB RAM, at 1000T ≥256 GB — far more than the enumeration VM needs.
  Splitting the phases keeps enumeration on a lean F-series SKU and only pays
  for a memory-dense E/M-series VM during the brief merge. See
  [DEPLOYMENT.md §Two-phase deployment](../solve_c/DEPLOYMENT.md#two-phase-deployment-enumeration-vm-vs-merge-vm)
  for the full pattern, cost table, and orchestration requirements.
- **`--analyze` has shared state with lifetime boundaries that bite new
  sections.** `bmask[]` (~2.9 GB per-boundary match bitmaps) is allocated
  before section [3] and freed at the end of analyze_mode. Any new section
  that reads `bmask[]` must be inserted before the free, OR rebuild it
  internally via a fresh streaming pass. A prior edit freed `bmask[]` between
  sections [13] and [14] to make room for [14]'s ~24 GB sort buffer on
  tight-RAM VMs; adding sections [16]-[19] after [15] then silently
  use-after-freed that memory and segfaulted mid-run (output truncated at
  [17]'s header). Fix: keep `bmask[]` alive to the end; the combined working
  set (~27 GB) fits on any VM with ≥ 32 GB RAM, and the F32als_v6 we use
  has 64 GB. Verify with `free -g` remotely during a full run if ever moving
  this boundary. The same pattern may arise with other shared buffers —
  whenever the solver code has a comment asserting a memory constraint,
  verify with `free -g` rather than trust the comment.

### Monitor / orchestrator

- **Separate launcher and monitor processes.** If the launcher script crashes
  during setup, the monitor should survive. Auto-teardown via `trap cleanup
  EXIT INT TERM` is how we guarantee VMs don't linger on error.
- **Use `set -uo pipefail`, NOT `set -euo pipefail`.** A transient scp failure
  should not kill the monitor loop. Guard individual risky commands with
  explicit `if ! cmd; then log; fi` instead of relying on `-e`.
- **Never redirect orchestrator stderr to `/dev/null`.** Silent death is the
  worst failure mode.
- **Monitor completion-detection must match solver's actual output.** Earlier
  the monitor grepped for `"SEARCH COMPLETE"` while the solver writes
  `"SEARCH_COMPLETE"` (underscore) to solve_results.json. Match a stable
  machine-readable marker, not stderr prose whose exact wording evolves.
- **Don't grep-hide SSH host-key warnings.** Use `ssh -o
  UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o StrictHostKeyChecking=no`
  for VMs whose IPs get reused across recreation cycles. Historically we had
  grep chains filtering out WARNING lines; that's hygiene, not a fix.
- **Solver-launch SSH must be belt-and-suspenders detached.** The naive form
  `ssh host "nohup ~/solve > out 2>&1 &"` hangs the local SSH client even
  with `ssh -n` and remote `< /dev/null` — observed empirically 2026-04-16.
  The remote `bash -c` lingered for minutes after backgrounding `nohup`,
  because some fd inheritance path kept the SSH channel open. Solve was
  happily running but the launching monitor never returned from `ssh`,
  stuck in `do_wait`, missing spot evictions. **Required form:**
  `timeout 15 ssh -n … "cd /data && setsid nohup ~/solve … > out 2>&1 < /dev/null &" < /dev/null`.
  - `setsid` puts solve in its own session, fully detached from SSH's
    process group / controlling tty
  - `timeout 15` guarantees the local ssh dies even if the remote shell
    refuses to release the channel; the nohup+setsid'd solve survives
  - The next monitor step probes `pgrep -x solve` via a fresh SSH so a
    forced-killed launch SSH doesn't false-fail launch detection.
- **A stuck monitor is blind to spot eviction.** If the monitor's main
  poll loop never starts (hung in launch SSH, hung in setup), the VM can
  evict undetected. Every long-blocking call in the launch path needs a
  hard timeout for this reason.
- **Supervisor → monitor takeover: kill monitor FIRST, then touch /data.**
  When a supervisor wraps a monitor (e.g., to chain runs or re-archive
  after the monitor finishes), kill the monitor *before* doing any
  `/data` operations or VM teardown. Otherwise the monitor's own
  archive/teardown flow races with the supervisor — observed scenario:
  monitor's `az vm delete` runs while supervisor's `scp solver@host:/data/...`
  is in flight, and the scp dies with no route to host mid-pull.
- **Pattern-based wipes preserve everything outside the patterns.** The
  monitor's stale-data clear is `rm -f /data/sub_*.bin /data/solutions.bin
  /data/checkpoint.txt …` (enumerated patterns), not `rm -rf /data/*`. To
  carry a file across runs on the shared managed disk, give it a name
  outside the pattern set — e.g., `solutions_d3_<sha8>.bin` survives a
  depth-2 wipe because no pattern matches it. (This is also the reason
  we say "clear stale run artifacts," not "wipe the disk" — see
  `Asset preservation` for terminology.)
- **Chained runs: supervisor owns VM teardown, not the inner monitors.**
  When the supervisor takes over completion handling, the monitor
  shouldn't auto-teardown — the supervisor decides when the VM goes away
  (typically: pull metadata via SSH first, then delete VM). The
  managed data disk auto-detaches and survives VM deletion.
- **Chained runs: prefer sequential monitors over a supervisor.** The
  supervisor pattern (kill monitor mid-merge, take over /data) has race
  conditions. The sequential pattern (let each monitor run to natural
  completion, then start the next) is simpler and correct. Between runs,
  a temp VM can rename files on the managed disk if needed.
- **Write run_id.txt BEFORE the wipe, not after.** The monitor's
  `sync_files` function checks `/data/run_id.txt` to detect stale data.
  If `run_id.txt` is written after the wipe, there's a race window where
  a concurrent sync reads the old ID and skips the sync. Writing the new
  ID first closes this window. (Observed 2026-04-17: "Run ID mismatch on
  sync" warnings from this race — cosmetic, but confused diagnostics.)
- **Solver correctness is independent of monitor state.** The monitor's
  sync warnings, log errors, or even crashes don't affect the solver
  process running on the VM. The solver reads no state from the monitor.
  Monitor failures are observability problems, not data problems.

### Infrastructure

- **Spot-VM evictions in westus2 under F64 averaged ~1 per 3 hours during
  April 2026 testing.** Sub-branch-granularity recovery is too coarse at
  large per-sub-branch budgets (100T+). Depth-3 work units (Option B,
  shipped via `SOLVE_DEPTH=3`) make the recovery granularity affordable.
- **Non-zonal managed disks cannot attach to zonal VMs.** If your data disk
  was created without a zone but the VM you want to attach it to is zonal,
  Azure returns `BadRequest`. Provision analysis VMs as non-zonal when they
  need the data disk.
- **Teardown is dependency-ordered.** VM → NIC → public-IP → NSG → vnet,
  sequential. Parallel deletes return spurious exit-1 because dependents
  hold references.

### Solver-VM network topology: private IP only

Solver VMs live on the shared `claude-vnet/default` subnet alongside the
orchestrator (`claude` VM at 10.0.0.4). Each new solver VM is created with
a private IP (e.g., 10.0.0.5) and **no public IP, no NSG rule**. The
orchestrator SSHes to the private IP directly.

**Why:** zero external attack surface (no port 22 reachable from the
internet), no public-IP cost (~$0.005/hr per VM), simpler resource
inventory.

**How `monitor_canonical.sh` does it:**
- `az network nic create --vnet-name claude-vnet --subnet default`
  (no `--public-ip-address`, no `--network-security-group`)
- `get_ip()` queries the NIC's `privateIPAddress` instead of a public-IP
  resource

**Pre-2026-04-16 monitor scripts** created public IPs and NSG rules per
run; their cleanup paths still attempt to delete those resources for
backward compatibility but new runs don't create them.

**Caveat:** since both VMs must share `claude-vnet`, an analyst running
this from a laptop (not from the orchestrator VM) needs a different
SSH path — either keep the public IP, or set up vnet peering / a jump
host. The orchestrator-on-vnet pattern is the simplest local case.

### Dynamic disk expansion (online resize while solver runs)

Azure managed disks support online expansion while attached to a running
Linux VM with ext4. `monitor_canonical.sh` watches `/data` usage every poll
cycle and grows the disk + filesystem if usage crosses a threshold.

**Settings (env vars, defaults shown):**
- `DISK_EXPAND_THRESHOLD_PCT=75` — trigger expansion when /data is 75% full
- `DISK_EXPAND_INCREMENT_GB=100` — grow by 100 GB per trigger
- `MAX_DISK_GB=1024` — hard ceiling (don't grow beyond 1 TB)

**Mechanism:**
1. `df -BG /data` on the solver VM measures usage
2. If pct ≥ threshold and current disk size < `MAX_DISK_GB`:
   - Orchestrator: `az disk update -g RG-CLAUDE -n solver-data --size-gb (cur + INCREMENT)`
   - Inside VM: `sudo resize2fs $(mount | grep /data | cut -d" " -f1)`
3. Telemetry CSV gets a `disk_expanded` row.

The solver continues writing throughout — no unmount, no reboot, no
disruption. Online expansion typically takes ~30 sec (azure provisioning)
+ ~1 sec (resize2fs).

**Why:** for runs whose final size exceeds initial sizing (especially
100T/1000T where the unique-count projection has wide uncertainty), this
prevents disk-full mid-merge — the failure mode that produced the
2026-04-14 8 GB / 23.7 GB truncation incident. Combined with the static
preflight check (in `solve.c` merge mode and the monitor's launch-time
check), this is defense in depth: preflight rejects obviously-undersized
starts; watchdog handles unexpected mid-run growth.

**Disks can grow but not shrink.** If 100T finishes with the disk grown
to 500 GB but only 200 GB used, the disk stays at 500 GB until manually
shrunk via snapshot + recreate. Cost continues at the larger size until
then.

---

## Reproduce from scratch

1. **Build the solver.**
   ```
   gcc -O3 -pthread -fopenmp -march=native \
       -DGIT_HASH=\"$(git rev-parse --short HEAD)\" -o solve solve.c -lm
   ```

2. **Run an enumeration.** On a 64-core machine with ~32 GB free disk:
   ```
   SOLVE_THREADS=64 SOLVE_NODE_LIMIT=10000000000000 ./solve 86400
   ```
   At ~1.3B nodes/sec, 10T nodes takes ~2 hours. Produces ~1344 `sub_*.bin`
   shards, a merged `solutions.bin` (~24 GB), and `solutions.sha256`.

3. **Verify the output.**
   ```
   sha256sum -c enumeration/solutions.sha256        # must match
   ./solve --validate solutions.bin                  # ALL CONSTRAINTS VERIFIED
   ```

4. **Reproduce the scientific analyses.**
   ```
   ./solve --analyze solutions.bin > analyze_output.txt
   diff analyze_output.txt enumeration/analyze_c_742M.txt   # headers/timings differ, numbers don't
   ```

5. **Cross-check downstream doc claims** against `analyze_output.txt`. Every
   numerical claim in HISTORY.md / SOLVE-SUMMARY.md / CRITIQUE.md / LEADERBOARD.md
   has a corresponding section in the analyze output.

The committed `enumeration/` artifacts (`checkpoint.txt`, `solve_output.txt`,
`solve_results.json`, `solutions.sha256`, `analyze_c_742M.txt`,
`analyze_section14_742M.txt`) are the reference against which reproduction is
checked.

## Running on cloud (high-level)

The repo intentionally does not ship cloud-provider-specific scripts. Running
the solver on a cloud VM (Azure, AWS, GCP) follows an architecture-agnostic
recipe; adapt to your provider of choice. The pattern we used in April 2026
(Azure spot F64als_v6) is documented in
[DEPLOYMENT.md](DEPLOYMENT.md) Appendix A as a reference example — translate
to `aws ec2`, `gcloud compute`, etc. as appropriate.

Architecture-agnostic rules (all in [DEPLOYMENT.md](DEPLOYMENT.md)):

- **Persistent data volume separate from the compute VM.** Attach a durable
  disk for solver output; VMs come and go, disk persists across evictions
  and recreates.
- **Orchestrator script provisions VM + disk + networking, launches solver
  under `nohup`, exits.**
- **Separate long-running monitor** periodically syncs state from the VM to
  local / archives, detects eviction, handles restart with exponential
  backoff.
- **Completion detection** on a stable marker (JSON status field, not
  stderr text).
- **Teardown** is trap-guaranteed: the VM dies even if the monitor crashes.
  Never delete the data disk.

A new Claude session (or any new contributor) should read DEPLOYMENT.md to
understand the rules, then write provider-specific scripts matching those
rules. Concrete commands vary by provider; the architecture does not.

## Cost expectations (April 2026 baseline)

- Solver run (10T on Azure F64 spot): ~$1.70 uninterrupted, ~$3-5 with 1-2
  evictions.
- Analysis session (F32 spot, `--analyze` on 742M): ~$0.10-0.15 per session.
- Persistent data disk (64 GB Standard HDD): ~$3/mo.
- User's informal budget cap: ~$50/month for an ongoing project at this scale.

Future 100T: projected ~$50-100 on spot with Option B (depth-3 work units)
reducing eviction recovery cost. Without Option B, spot is infeasible (first
attempt projected 30+ days).

Future 1000T: would need architectural changes — solutions.bin at ~2.2 TB
exceeds single-disk capacity; requires chunked output + sharded analysis,
possibly M-series VM for analysis step. Queued, not scoped.

---

## What's pending / open

Beyond the current committed state, the following work is known to be useful
but not yet done. A fresh session wanting to continue the project should
consider these in rough priority order:

1. **Hash-table silent-drop fix.** Remove the 64-probe cap, add a drop counter,
   abort on load factor >75%. Closes the one known silent-data-loss path
   remaining in solve.c.
2. **Status-label taxonomy.** Split `INTERRUPTED` into `EXHAUSTED` (natural
   completion), `BUDGETED` (hit per-sub-branch node limit), and `INTERRUPTED`
   (true external signal). Add per-sub-branch budget to the checkpoint line
   so resume can detect budget changes. Skip BUDGETED on same-budget resume.
3. **Option B: depth-3 work units.** Split each sub-branch into ~30 sub-sub-
   branches by pre-enumerating `pair3`/`orient3`. Drops eviction loss from
   ~30 min/eviction to ~1 min/eviction. Gates affordable 100T on spot.
4. **100T enumeration** after 1-3 are tested at small scale.
5. **Scientific (analysis) extensions**:
   - Formal proof (not computational) that 4 is the minimum boundary count
     across *all* valid orderings (not just the 742M dataset).
   - Null-model comparison against structured permutations (de Bruijn
     sequences, Costas arrays) — currently only random permutations.
   - Connection of KW's minimum-boundary set `{2, 21, 25, 27}` (or `{25, 27}`
     mandatory) to known combinatorial structures (designs, codes, group
     actions). Would elevate empirical observations to mathematical
     connections. See `INSIGHTS.md` (project-local, not committed) and
     `BREAKTHROUGH_REQUIREMENTS.md` (project-local).

See [HISTORY.md](HISTORY.md) "Current state" for the latest status, and the
missteps table for worked examples of how the project self-corrects.
