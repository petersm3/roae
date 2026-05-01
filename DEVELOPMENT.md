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

### Layered enumeration (extension-friendly run organization)

A "layer" is a single `(scope, per-sub-branch budget)` enumeration result.
Layers compose: a later layer can extend an earlier one with higher budget
(or different scope) without destroying the earlier layer's data. This is
how to organize runs that may need to be extended later.

**Layer = directory.** Each layer lives in its own subdirectory under a
`<run_root>/`. Convention: name layers so lexical sort = intended order.

```
<run_root>/
  01_full_5T_2026_04_29/        # layer 0: full enumeration, 5.6T budget
    sub_*.bin                   #   ~158K shards
    checkpoint.txt
  02_extend_dead_50T_2026_04_30/  # layer 1: extension, higher budget on subset
    sub_*.bin                   #   shards only for the extended sub-branches
    checkpoint.txt
  _merged_/                     # produced by --merge-layers
    sub_*.bin                   #   symlinks to winning layer's shards
    solutions.bin
    MANIFEST.txt                #   records which layer won per shard
```

**Eviction recovery is NOT a new layer.** A spot-VM eviction → restart →
checkpoint resume continues writing into the same layer dir. Same scope,
same budget, same data continuation. New layer only when the operator
intentionally chooses a new `(scope, budget)` pair.

**Merge:** `solve --merge-layers <run_root>` walks the layer subdirs in
sort order; for each sub-branch tuple, the LAST layer to contain a shard
wins. Winners are symlinked into `<run_root>/_merged_/`, the standard
merge runs in that dir, and produces `<run_root>/_merged_/solutions.bin`
plus a `MANIFEST.txt` recording each shard's source layer. The result is
deterministic — given the same set of layers, the merged sha is stable.

**Extending a run:** to raise the per-sub-branch budget on some subset of
sub-branches, create a new layer dir and run `solve --branch <p1> <o1>` (or
the full enum scoped to a subset) with `SOLVE_PER_SUB_BRANCH_LIMIT=<higher>`.
The new layer will only contain shards for the extended sub-branches; the
earlier layer's shards remain authoritative for everything else.

**Rollback** is `rm -rf <new_layer>` (and `_merged_/`); the prior state is
intact. Compared to in-place extension (which would overwrite the earlier
shards), this is non-destructive.

### Storage strategy: parallel redundancy and long-term archival

> **Status: OPTIONAL / ASPIRATIONAL — not currently in use.**
> The entire Azure Blob Archive flow below is a designed-but-undeployed
> backup tier. We are not confident enough in the current `solutions.bin`
> outputs to archive them, and no automated process has been chosen for
> the upload/sha-verify pipeline. The working copy on the `solver-data`
> managed disk is currently the only redundancy tier. Treat this section
> as a reference for a future archival workflow, not current policy.

The managed disk is the *working* copy of large artifacts, not the *durable*
copy. Two things would motivate a separate backup tier:

1. **Accidental deletion or corruption.** A disk wipe, a rogue `az disk delete`,
   or a mount-point bug can lose the primary copy in seconds. Managed disks
   have Azure's 11-9s durability guarantee, but the operator (me or a future
   session) is the real risk.
2. **Cost during long pauses.** At 23.7 GB (10T) or 80-260 GB (1000T), keeping
   a managed disk idle between sessions costs $0.04-0.40/GB/month. For a
   multi-month pause, that adds up fast. Blob Archive tier is ~40× cheaper
   per GB.

**Proposed parallel-backup policy (would run after any canonical run, once
we establish a canonical run and choose an automation mechanism):**

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

The 10T canonical run (`aa1415174c...b719b`, 23.7 GB) was the original
candidate, but that sha is now known to be an undercount (see HISTORY.md Day
8). No run has yet been archived. A future canonical 10T (once the d3 and d2
reference shas land) would be the first candidate. At Archive-tier pricing
(~$0.00099/GB/month) a 10T backup would be ~$0.02/month — essentially free
insurance, once we are confident in the output.

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

- **Independent verifier**: `roae/verify.py` is a ~160-line pure-Python
  implementation of the verifier recipe in
  [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md). Reads any format-v1
  `solutions.bin`, reconstructs each 64-hexagram sequence, and checks
  **C1 (pair structure), C2 (no 5-line transitions), C3 (complement
  distance ≤ 776, added 2026-04-19), C4 (starts with
  Creative/Receptive), C5 (exact distance distribution)** plus sort
  order and dedup. No shared code with solve.c — genuine second opinion.
  Usage: `python3 verify.py /path/to/solutions.bin`. Exit 0 on PASS, 1
  on constraint failures, 2 on header/format errors. Runs in ~1-5
  minutes on a 10T solutions.bin.

- **Two-tier solver selftest**:
  - `./solve --selftest` (~5 sec on 4 threads): runs a bounded
    enumeration with a fixed budget and checks the resulting
    `solutions.bin` sha256 against the canonical baseline `403f7202…`.
    Catches gross regressions in the constraint logic, partition
    structure, or merge code. Use as a build smoke-test.
  - `python3 solve.py --extended-selftest <path-to-solve-binary>`
    (~10 min on 4 threads, added 2026-04-30): a CI-grade regression
    suite that drives the supplied binary through three subtests +
    a cross-check:
      1. Single-shot 3-way @ 100M nodes (recursive vs iterative vs
         iterative+v2). Catches regressions in the iterative DFS,
         v2 capture, or fork-merge dispatch.
      2. v2 resume @ 50M → 200M (PHASE_A captures, PHASE_B resumes,
         resumed sha must match single-shot 200M sha `e43f2905…`).
         Catches regressions in the off-by-one capture-frame fix
         and the resume gate.
      3. v1 resume @ 50M → 200M (recursive path with the "walk-fresh
         on resume + load_prior_shard" policy). Same sha check.
      Cross-check: recursive single-shot 200M sha == iterative
      single-shot 200M sha (DFS-engine independence).
    Returns 0 on full PASS, 1 on any failure. Suitable as a CI gate
    before commits that touch `backtrack`, the v2 capture/resume
    fields, the bitmap key encoding, or the merge dispatch.

- **Never assume `fwrite` succeeded without checking.** The 2026-04-14
  `solutions.bin` was silently truncated from 23.7 GB to 8 GB because the disk
  filled up mid-write. The solver's sha256 still matched the truncated file
  (sha was computed post-write from what landed on disk). Every `fwrite`,
  `fopen`, `fclose`, `fflush`, `fsync`, `rename`, `fseek`, `ftell`, and
  `fread` now has its return checked at every call site (enumeration flush,
  external-sort chunks, both merge paths). Short reads are hard errors, not
  warnings. Post-write `stat()` verifies size at every file write.
- **Preflight disk space**: `free_disk >= estimated_output × 1.5`. At 10T the
  sub_*.bin shards total ~23 GB AND the final solutions.bin is ~24 GB —
  together they exceed a naive 32 GB disk.
- **Preflight sha256 tool.** `solve.c` shells to `sha256sum` (GNU coreutils)
  or `shasum -a 256` (BSD/macOS) for output digests. The solver walks `$PATH`
  at startup and exits 10 with install hints if neither is available —
  prevents a successful multi-hour enumeration from producing an empty
  `.sha256` file at the end. Modes that don't write digests
  (`--verify`, `--validate`, `--analyze`, `--prove-*`, `--list-branches`)
  skip the preflight.
- **time_limit and reproducibility are incompatible.** For any canonical
  run whose sha256 needs to be reproducible across machines or
  re-enumerations, set `SOLVE_NODE_LIMIT` only and pass `0` for the
  CLI time_limit arg. Per-sub-branch node budgets are deterministic;
  wall-clock interrupts are not. If time_limit fires first, whatever
  sub-branches happened to be running at the N-second mark are tagged
  INTERRUPTED with their partial solutions preserved — and which
  sub-branches those are depends on thread scheduling. Two identical
  invocations of `./solve 60` on the same inputs will produce different
  solutions.bin sha256 under load. The solver prints a WARNING at
  startup when both limits are set together.
  Use time_limit alone for "run N minutes, take what we got"
  exploratory workflows only. The --selftest harness previously passed
  a 60-second time_limit as a safety net; under load, that caused
  spurious sha-mismatch failures. Fixed 2026-04-18 — selftest now uses
  node_limit only.
- **Per-sub-branch filenames include the full (p1, o1, p2, o2) key**. Earlier
  versions keyed only on (p2, o2), causing silent overwrites. Never narrow the
  file-naming key without proving no collisions can occur.
- **Status taxonomy: EXHAUSTED / BUDGETED / INTERRUPTED.** Each sub-branch
  records one of three end states. EXHAUSTED means the search completed
  naturally (no more solutions possible). BUDGETED means the per-sub-branch
  node budget was hit (deterministic under the same budget; re-run at a
  higher budget may find more solutions). INTERRUPTED means a signal or
  process kill cut it short. Resume: always re-run INTERRUPTED, re-run
  BUDGETED only if the new budget exceeds the stored one, skip EXHAUSTED.
- **Hash table auto-resizes; zero silent drops.** Per-thread tables start
  at 2^24 slots (configurable via `SOLVE_HASH_LOG2`) and double when load
  exceeds 75%. Probe is over the full table with no cap. OOM during resize
  triggers FATAL abort. The earlier 64-probe cap that silently dropped 241M
  records at 10T depth-2 no longer exists.
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
- **Post-completion gate: --verify + hash-drop check.** After solver
  writes solutions.bin, the monitor runs `./solve --verify solutions.bin`
  on the VM (independent C1-C5 check on every record) and greps
  solve_output.txt for nonzero hash-table drops. Either failure aborts
  before archiving — no invalid output is ever accepted as a completed run.
- **Progress-stall watchdog must exempt the merge phase.** The watchdog
  checks `progress.txt` staleness to detect hung solvers. But the merge
  phase (reading 158K files, sorting billions of records, writing
  solutions.bin) legitimately takes 15-30+ minutes without updating
  progress.txt. The watchdog must check `solve_output.txt` for merge
  indicators ("Reading sub-branch", "Sorting", "Writing", "Computing
  sha256") before declaring a stall. Observed 2026-04-17: watchdog killed
  a healthy solver mid-merge on a 10T depth-3 run, losing the merge
  output while all sub_*.bin files were intact on disk.
- **Merge is not checkpoint-protected — use on-demand VMs.** The merge
  phase (malloc + qsort + write) is a single uninterruptible operation.
  If spot-evicted mid-sort, all work is lost and must restart from the
  sub_*.bin files. For production merges, use an on-demand VM (~$2 for
  30 min on F64). This is the two-phase pattern: spot for enumeration
  (checkpoint-protected), on-demand for merge (must complete in one shot).
- **Progress rate + ETA in sync logs.** Each checkpoint sync computes
  sub-branches/hour and estimated time remaining. Essential for overnight
  100T+ runs where "is it still progressing?" can't be answered by a
  single checkpoint count.
- **Disk usage per poll cycle.** Logged as "Disk: 45% (54GB / 121GB)"
  at each sync. Shows growth rate and predicts whether the dynamic
  expansion watchdog will trigger before completion.
- **Sub_*.bin integrity check on eviction resume.** After spot eviction
  and redeploy, the monitor checks every existing sub_*.bin for
  `size % 32 == 0`. Truncated files (eviction killed the flush mid-write
  before fsync) are removed so the solver re-runs those sub-branches
  from checkpoint rather than merging corrupt data.
- **All merge code paths must use canonical dedup.** The solver's normal-
  mode merge and the standalone `--merge` flag must both use
  `compare_canonical` (orient bits masked) for dedup — not
  `compare_solutions` (full-byte). A mismatch means `--merge` on the
  same sub_*.bin files produces a different sha than the solver would
  have. This was a bug through commit 872a861; fixed afterward.
- **External merge-sort for memory-independent merging.** At 10T depth-3,
  the merge buffer is 82 GB (2.77B records × 32 bytes). For larger runs
  or smaller VMs, `SOLVE_MERGE_MODE=external` uses disk-based sorted
  chunks + k-way heap merge. Produces identical output to in-memory merge.
  Default (`auto`) selects external when needed RAM exceeds 70% of
  physical. `SOLVE_MERGE_CHUNK_GB` controls chunk size (default 4 GB).
- **Disk tier dominates external merge time.** Lesson from the 2026-04-18
  10T depth-3 production-scale external merge test on Standard_LRS
  (HDD-tier): rate was ~6-7 min per 4 GB chunk × 20+ chunks in phase 1,
  projecting to ~3-4 hours total wall and ~$12-15 at F64 on-demand. That
  is **~6× the time and ~6× the cost** of the same merge in-memory on the
  same F64 (fits in 128 GB RAM comfortably). The HDD is the bottleneck,
  not the code. Implication: never do an external merge on Standard HDD
  at > 10T scale without a very good reason. At 100T the numbers become
  untenable (extrapolated 30+ hours on HDD vs ~3 hours on Premium SSD).
- **Use `SOLVE_TEMP_DIR` to keep temp chunks on Premium SSD while keeping
  shards and final output on cheap archival storage.** External merge
  does ~2× chunk-size worth of I/O to the temp directory
  (write chunks in phase 1, read chunks in phase 2). Pointing
  `SOLVE_TEMP_DIR` at a Premium SSD attached only for the merge runs
  that I/O at SSD speeds (~200 MB/s on P20/P30, ~3-4× HDD). The SSD gets
  destroyed after the merge — no long-term Premium-storage cost, only
  the prorated hourly rate during the merge (pennies). Shards stay on
  `solver-data` (Standard HDD, ~$3/month). Final `solutions.bin` also
  lands on `solver-data` since CWD during merge is unchanged. See
  [DEPLOYMENT.md §Premium-SSD-attach-for-merge](../solve_c/DEPLOYMENT.md)
  for the concrete az CLI workflow.
- **Standing rule: never provision `solver-data` as Premium SSD.** It
  holds cold shards 99% of the time. Standard_LRS ($3/month for 300 GB,
  $10/month for 1 TB) is the right tier for archival. The factor-10
  cost jump to Premium is only justified during active merges, and those
  are better served by attach-a-temp-Premium-SSD-just-for-the-merge.
- **External merge has a hard pre-dedup size ceiling.** `MAX_SORTED_CHUNKS
  = 4096` in solve.c × default `SOLVE_MERGE_CHUNK_GB=4` = **16 TB of
  pre-dedup input**. At observed d3 rates (~8.3 GB per 1T nodes) that's
  ~2,000T of enumeration. Comfortable for 10T-1,000T; restrictive only
  at ~1,500T+. Mitigation is env-var (`SOLVE_MERGE_CHUNK_GB=16` buys 4×
  headroom, 32 buys 8×) with no code change; or bump the constant as a
  one-line source change. Solver emits a clear error with the mitigation
  if the limit is hit. Before this bites: `ulimit -n` default of 1024
  open FDs is hit around 500T (the k-way merge opens every chunk
  simultaneously). `ulimit -n 16384` before running fixes it.

### Accumulating ground truth — single-branch exhaustion workflow

Long-horizon enumeration strategy: exhaust individual first-level branches
over time, accumulate their shards on a shared archive disk, and concentrate
new-run compute budgets on the remaining un-exhausted branches. This is
formally justified by the partition-invariance theorem — see
[PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) for the proof that
merging shards from independent single-branch runs produces identical
output to a full-parallel run (under exhaustive enumeration).

Operational procedure:

1. Run `./solve --branch P O 0` (no node limit → exhaustive) for a
   targeted first-level branch. Sub-branches within that branch complete
   as EXHAUSTED; shards land in the CWD as `sub_P_O_*.bin`.
2. Archive those shards + the branch's checkpoint entries onto a
   shared disk (e.g., `solver-data` or a dedicated `solver-ground-truth`
   disk). Retain the checkpoint lines marking EXHAUSTED status.
3. Next full run: `cp` (or symlink) the archived shards + concatenated
   checkpoint into the working directory before launching. `solve.c`
   reads the checkpoint on startup, sees EXHAUSTED entries, skips those
   sub-branches entirely. Enumeration only runs on the remaining branches.
4. Merge at end reads all shards in CWD — pre-existing and freshly-written
   alike — producing a `solutions.bin` that combines exhausted-ground-truth
   with budgeted-partial for the remainder.

**Budget distribution option**: by default, the per-sub-branch node limit
is `SOLVE_NODE_LIMIT / total_partition_size`, which preserves reproducibility
across fresh vs. resumed runs at the same node limit. For the accumulation
workflow where you want the remaining node budget concentrated on
un-exhausted branches, opt-in via `SOLVE_CONCENTRATE_BUDGET=1`. This
divides by the *remaining* sub-branch count instead. Trade-off: output
sha256 depends on how many branches were pre-completed; NOT reproducible
by `SOLVE_NODE_LIMIT` alone. The solver prints a WARNING when this
env var is active.

**Workaround without the env var**: if you want concentration semantics
under the default reproducible path, compute the target total manually:

```bash
TARGET_PER_BRANCH=$(( 10000000000000 / TOTAL_SUB_BRANCHES ))
SCALED_TOTAL=$(( TARGET_PER_BRANCH * REMAINING_SUB_BRANCHES ))
SOLVE_NODE_LIMIT=$SCALED_TOTAL ./solve 0
```

Same effective per-sub-branch depth on remaining, full reproducibility
of the pass.

### `--sub-branch` CLI mode (targeted depth-3 sub-branch exhaustion)

Added 2026-04-19. Runs a single depth-3 sub-branch `(p1, o1, p2, o2, p3, o3)`
to exhaustion (or node-limit budget). Usage:

```bash
SOLVE_NODE_LIMIT=0 ./solve --sub-branch <p1> <o1> <p2> <o2> <p3> <o3>
```

Writes a single `sub_P1_O1_P2_O2.bin` shard and a single checkpoint line
with status EXHAUSTED (if the tree finishes) or BUDGETED (if a node limit
is set and hit first). Designed for the stratified-sample exhaustion study
— each run produces one data point of (wall time, node count, solution
count, status) for cost-extrapolation analysis.

Unlike `--branch` (which runs ALL sub-branches of a first-level branch),
`--sub-branch` targets exactly one. It bypasses checkpoint.txt loading so
that a fresh run is a fresh run — no accidental resume from stale state.

Pair this mode with small parallel VMs (D2als_v7 or D4als_v7 spot, one
per sub-branch). The workload is single-threaded inside a sub-branch, so
D128 is 99% wasted. See `DSERIES_ROI_REPORT.md` (outside repo) for SKU
sizing rationale.

Validation guarantee: if you later exhaust a sub-branch via `--sub-branch`
AND separately compute a full `--merge`'d canonical from independent
whole-partition enumeration, merging the single-exhausted-sub-branch
shard into a fuller dataset (following the accumulation workflow above)
is byte-identical to running everything in one invocation, per
partition invariance.

### `--kde-score-stream` CLI mode (native KDE scorer for distributional analysis)

Added 2026-04-24 alongside the consolidation-hang postmortem and bug fix.
Companion subcommand for the `solve.py --joint-density-v2` distributional
analysis pipeline. Reads fit points from a binary file, streams query
points from stdin (float64 packed), writes count-below-threshold to stdout.
Implements Gaussian kernel KDE log-density via log-sum-exp, parallelized
via OpenMP.

```bash
./solve --kde-score-stream --fit-file FIT.bin --d N --bandwidth BW --threshold T
```

~10× faster than sklearn's pure-Python `KernelDensity.score_samples` on
typical inputs (validated bit-identical on a 500-point synthetic test).
Makes exhaustive distributional analysis on the 100T canonical (3.43B
records) tractable in ~2 hours on D64 (vs ~9 days pure-Python).

See [`x/roae/DISTRIBUTIONAL_V2_SPEC.md`](../../x/roae/DISTRIBUTIONAL_V2_SPEC.md)
for the analysis pipeline + Python integration.

### `solve.py --sat-encode` (DIMACS / OPB encoder for #SAT model counting)

Added 2026-04-24. Emits propositional encoding of C1+C2 (optionally +C3
as Pseudo-Boolean linear constraint, +C4 unit) for input to exact #SAT
solvers (`ganak`, `d4`, `sharpSAT-TD`).

```bash
solve.py --sat-encode kw.cnf [--sat-c3 pb] [--sat-c4]
```

Produces:
- `kw.cnf` — DIMACS CNF (4,096 vars / 272,128 clauses for C1+C2)
- `kw.cnf.opb` — Pseudo-Boolean OPB format with C3 PB constraint added
  (266,240 vars / 1,058,560 clauses; C3 sum has 258,048 terms)
- `kw.cnf.meta.json` — variable/clause counts, sha256 of clauses for
  reproducibility

See [`x/roae/SAT_EXPERIMENT_SPEC.md`](../../x/roae/SAT_EXPERIMENT_SPEC.md)
for the experimental protocol and validation strategy.

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

2. **Run a canonical enumeration.** On a machine with ≥64 cores and ≥64 GB
   free disk (128 cores and 1.5 TB for 100T):
   ```
   SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=10000000000000 ./solve 0    # 10T d3 canonical
   ```
   Pass `0` as the wall-clock argument for the reproducibility rule — each
   sub-branch runs to its full per-branch node budget, producing byte-identical
   output regardless of thread count or hardware. Empirical timing: 10T d3
   completes in ~83 min on D128als_v7 (Zen 5) or ~5 h on F64als_v6 (Zen 4).
   Produces 158,364 `sub_*.bin` shards, a merged `solutions.bin` (~22.6 GB),
   and `solutions.sha256`.

3. **Verify the output.** The expected sha is the current canonical, not
   any legacy file in `enumeration/`:
   ```
   sha256sum solutions.bin
   # must equal f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e  (10T d3)
   # or        a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2  (10T d2)
   ./solve --validate solutions.bin            # ALL CONSTRAINTS VERIFIED
   ```

4. **Reproduce the scientific analyses.**
   ```
   ./solve --analyze solutions.bin > analyze_output.txt
   zcat solve_c/runs/20260418_10T_d3_fresh/analyze_output.log.gz > expected.txt
   diff analyze_output.txt expected.txt        # headers/timings differ, numbers don't
   ```

5. **Cross-check downstream doc claims** against `analyze_output.txt`. Every
   numerical claim in HISTORY.md / SOLVE-SUMMARY.md / CRITIQUE.md / LEADERBOARD.md
   has a corresponding section in the analyze output.

The canonical archival artifacts live under `solve_c/runs/<date>_<scale>_<depth>_<runtag>/`
(e.g., `solve_c/runs/20260418_10T_d3_fresh/` for the 10T d3 canonical). Each
per-run directory contains `solutions.sha256`, `solutions.meta.json`, compressed
enum + merge logs, and a compressed `analyze_output.log.gz` — these are the
reference against which reproduction is checked.

The older `enumeration/solutions.sha256` and `enumeration/analyze_c_742M.txt`
files hold the invalidated 742M-era sha and analyze outputs (see HISTORY.md
for forensics). They are kept for audit trail only and should NOT be used as
a reproduction reference.

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
consider these in rough priority order. This section was last refreshed
2026-04-19; see [HISTORY.md](HISTORY.md) "Current state" for the canonical
up-to-date status.

### Operational (in-flight or near-term)

1. **100T d3 enumeration on D128als_v7 westus3.** Launched 2026-04-19
   ~08:00 UTC; at the time of this doc refresh, enumeration is in flight.
   Expected outcome: a 100T-budget canonical sha that supersedes the 10T d3
   sha as the deepest partial dataset. Per PARTITION_INVARIANCE.md the
   100T sha is distinct from 10T (different `SOLVE_NODE_LIMIT`) but still
   reproducible. Post-run: update LEADERBOARD.md with the new sha +
   canonical count, refresh `--analyze` outputs for the deeper dataset,
   reassess {25, 27} interchangeable-pairs structure at 10× budget.
2. **4-corners validation at 100T.** The 10T d3 canonical has been
   validated across {F64 Zen 4 westus2, D128 Zen 5 westus3} × {external,
   heap-sort merge} (all four produce byte-identical output, see
   HISTORY.md). 100T has only been run via the D128+external corner so
   far; running the other three corners at 100T would tighten the
   partition-invariance empirical claim — but is not required for the
   canonical sha, which is theorem-guaranteed reproducible.

### Scientific / analysis extensions (longer horizon)

Tracked in detail in `LONG_TERM_PLAN.md` (project-local staging in
`~/github/x/roae/`, not committed to this repo). Highlights:

3. **Formal proof of forced-orientation (Theorem 6).** `SPECIFICATION.md`
   cites the theorem with a prose proof reference. Level 1: tighten the
   prose to publication-grade. Level 2: machine-check in Lean or Rocq.
4. **Bootstrap confidence intervals** on percentile claims (complement
   distance at 3.9th percentile, shift pattern percentages on the current
   canonical datasets, per-position entropies). Report `X% [Y%, Z%]`
   instead of point estimates.
5. **Null-model comparison against structured permutations** (de Bruijn
   sequences, Costas arrays). Currently CRITIQUE.md compares only to
   random permutations and to pair-constrained random permutations —
   structured-permutation nulls are absent.
6. **Partition-stability re-check on 100T data.** The 4-boundary
   structure `{25, 27} ∪ one-of-{2,3} ∪ one-of-{21,22}` is established on
   the d3 10T canonical; the mandatory-{25, 27} sub-claim is partition-
   stable (holds on both d2 and d3 10T). A 100T dataset will either
   confirm the full 4-boundary structure or refine it — partition
   dependence is expected for the 2 non-stable boundaries.
7. **Connection to known combinatorial structures** (block designs, error-
   correcting codes, group actions). Would elevate empirical findings
   to mathematical connections. Exploratory notes in `INSIGHTS.md` and
   `BREAKTHROUGH_REQUIREMENTS.md` (operator staging in
   `~/github/x/roae/`, not committed to this repo).

### Infrastructure / archival (deferred)

Not planned at this time per operator direction (2026-04-18), but worth
noting so a future session understands the scope they were declined from:

- CI/CD automation (GitHub Actions) for buildability over time.
- Linux-path portability (`/proc/self/exe` fallback for non-Linux).
- Archival deposits (Zenodo + Software Heritage) for 20-year preservation.

All three are discussed in `SCIENTIFIC_REVIEW.md` (project-local).

See [HISTORY.md](HISTORY.md) "Current state" for the latest status, and the
missteps table for worked examples of how the project self-corrects. Items
that were previously in this list and are now complete:

- Hash-table silent-drop fix → commit `585880f` (auto-resizing hash table, zero silent drops).
- Status-label taxonomy → commit `3f0167f` (EXHAUSTED/BUDGETED/INTERRUPTED).
- Option B depth-3 work units → commit `ac5a9ba`; 10T d3 enumeration completed 2026-04-17 with all 158,364 sub-branches processed.
