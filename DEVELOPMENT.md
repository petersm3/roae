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

### Infrastructure

- **Spot-VM evictions in westus2 under F64 averaged ~1 per 3 hours during
  April 2026 testing.** Sub-branch-granularity recovery is too coarse at
  large per-sub-branch budgets (100T+). Depth-3 work units (Option B in the
  future-work list) make the recovery granularity affordable.
- **Non-zonal managed disks cannot attach to zonal VMs.** If your data disk
  was created without a zone but the VM you want to attach it to is zonal,
  Azure returns `BadRequest`. Provision analysis VMs as non-zonal when they
  need the data disk.
- **Teardown is dependency-ordered.** VM → NIC → public-IP → NSG → vnet,
  sequential. Parallel deletes return spurious exit-1 because dependents
  hold references.

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
