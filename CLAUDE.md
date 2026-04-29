# CLAUDE.md

Orientation file for Claude (the AI assistant) working on this repo.
Humans: you probably want [README.md](README.md) or
[GUIDE.md](GUIDE.md). This file is terse by design — pointers and
invariants, not content.

## Project

ROAE = a mathematical analysis of the King Wen sequence (I Ching). Core
deliverable is `solve.c` — a multi-threaded C enumerator that finds all
orderings of 64 hexagrams satisfying constraints C1-C5, plus the
scientific record documenting what those enumerations reveal about
King Wen's uniqueness vs. combinatorial structure.

## Authoritative sources

| Topic | Read |
|---|---|
| Public scientific record (what holds, what doesn't) | [SOLVE.md](SOLVE.md), [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md), [CRITIQUE.md](CRITIQUE.md) |
| Distributional analysis of KW's position in the observable-space joint distribution | [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md) |
| Prior literature + what is classical / prior / novel / methodological citations | [CITATIONS.md](CITATIONS.md) |
| Formal constraint definitions + theorems | [SPECIFICATION.md](SPECIFICATION.md) |
| Binary output format + verifier recipe | [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md), [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md), [verify.py](verify.py) |
| Partition invariance theorem | [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) |
| Project narrative + why-decisions-were-made | [HISTORY.md](HISTORY.md) |
| Enumeration leaderboard | [enumeration/LEADERBOARD.md](enumeration/LEADERBOARD.md) |
| Build / self-test / developer invariants | [DEVELOPMENT.md](DEVELOPMENT.md) |
| Azure deployment / SKU sizing | [DEPLOYMENT.md](DEPLOYMENT.md) |
| Visualization tooling + how-to-read | [viz/README.md](viz/README.md) |
| **Live operational state** (current run, schedule, in-flight work) | `~/github/x/roae/CURRENT_PLAN.md` (**private repo, `petersm3/x`** — not in this repo) |
| Operator memory (user preferences, feedback rules, infra notes) | `~/.claude/projects/*/memory/MEMORY.md` |

## Canonical shas — INVARIANT

Any `solutions.bin` produced with matching input parameters **must**
reproduce one of these shas byte-identically. A mismatch is a bug, not
a new result.

- **d3 100T** (`SOLVE_DEPTH=3`, `SOLVE_NODE_LIMIT=100000000000000`):
  `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5` — 3,432,399,297 canonical orderings (2026-04-20).
- **d3 10T** (`SOLVE_DEPTH=3`, `SOLVE_NODE_LIMIT=10000000000000`):
  `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` — 706,422,987 canonical orderings.
- **d2 10T** (`SOLVE_DEPTH=2`, same node limit):
  `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2` — 286,357,503 canonical orderings.

Partition invariance (see PARTITION_INVARIANCE.md) guarantees these
are reproducible across hardware, region, merge algorithm, and
enumeration vs. independent-shard-merge paths. If you produce a
mismatching sha, stop and investigate — don't silently "update" the
canonical.

Older figures in project history (31.6M filename-collision bug, 742M
hash-table bug) are invalidated forensic references only.

## Cost control — VM purchase type (STRICT, mandatory gate)

**Current standing policy (2026-04-29, supersedes the prior split rule):**

> **All VMs other than the 2-core 8GB `claude` orchestrator MUST be Spot priority.** No exceptions for merge VMs, no exceptions for "brief inspection" VMs, no exceptions for analysis VMs. If a workload genuinely cannot tolerate eviction, design for checkpoint/resume, or escalate to the operator before launching.

This supersedes the 2026-04-20 split policy (enumeration=Spot, merge=on-demand). The split policy was correct in theory (eviction-fragile workloads should be Regular) but in practice the on-demand merge VMs accumulated forgotten-VM cost at the same rate as the prior overspend events — so the rule is now blanket Spot-only.

Spot pricing references (D-als-v7 family, westus3):
- D128als_v7: ~$5.146/hr on-demand → ~$0.95/hr Spot (~85% discount)
- D64als_v7: ~$2.59/hr on-demand → ~$0.50/hr Spot
- D32als_v7: ~$1.30/hr on-demand → ~$0.30/hr Spot
- D16als_v7: ~$0.50/hr on-demand → ~$0.12/hr Spot

**Mandatory pre-launch verification gate (EVERY time, for any workload >1 hour):**

```
az vm show -g <rg> -n <vm> --query priority -o tsv
```

- Output `Spot` → OK to launch.
- Output empty / `null` / `Regular` → STOP. Either recreate the VM with `--priority Spot --eviction-policy Deallocate --max-price -1`, or escalate to the operator. Do NOT proceed with a workload on a Regular-priority VM.

**Creation command template (only allowed form for new VMs other than `claude`):**
```
az vm create ... --priority Spot --eviction-policy Deallocate --max-price -1
```

Failure modes this rule prevents:
- 2026-04-19: d128-westus3 was provisioned without `--priority Spot` by an earlier autonomous session, and the 100T run (16h 48m) was launched on it without verification. Overspend on enumeration: ~$48-73.
- 2026-04-26 → 2026-04-29: deep-calib-westus3 was recreated as Regular D64als_v7 (intentionally, to avoid eviction during a calibration run) and then forgotten across multiple sessions. Idle Regular billing for ~3 days, kept alive by orphan monitor scripts. Estimated cost: ~$70-100.

The new rule also implicitly supersedes the merge-VM-on-demand guidance previously in this section: even merge VMs are now Spot. If a merge gets evicted mid-run, restart it; the marginal cost of a re-run is much smaller than the systemic cost of forgotten Regular VMs.

## Cost control — SKU family restrictions (STRICT)

**Standing rule (repeated by user 2026-04-19 and 2026-04-20):**

- **NEVER provision F-series (Falsv6, Fadsv6, etc.) VMs for any purpose.** F-series was retired from this project on 2026-04-19 when the D-als-v7 Turin family landed. Despite the retirement, F64als_v6 was accidentally spun up AT LEAST THREE TIMES (2026-04-19 06:09, 2026-04-20 ~00:32 — from solver-d3 recreations after deletions). Each cost ~$3-25 in avoidable spend before being caught.
- **Use D-als-v7 family exclusively**: D2als_v7 (analysis), D4als_v7 (data inspection), D16als_v7 (merge), D32als_v7 (merge / single-branch), D64als_v7 (parallel single-branch future), D128als_v7 (full enumeration).
- **Right-size by workload**. Don't use F64 or D128 for a 10-minute data-mount task. Use D2 or D4.

**If any past command in a session or autonomous wake prompt references F-series provisioning: STOP, redact, use D-als-v7.**

## Session-lifecycle VM discipline (STRICT, applies to any `az vm create`)

**Problem addressed:** "mount a disk briefly for inspection" has repeatedly
left VMs running long after the inspection ended. Each cleanup gap costs
$3-25 and accumulates across sessions.

**Rules, applied to every Claude-initiated VM:**

1. **Every `az vm create` must be paired with a concrete teardown plan
   in the SAME command sequence or the SAME scheduled wakeup prompt.**
   Acceptable patterns:
   - "provision → run task → deallocate" in one bash command, OR
   - Provision, then set a scheduled wakeup that includes the full
     teardown sequence (detach managed-data-disks, delete VM, clean
     orphan NIC/pip/OS-disk) — NEVER leave teardown to "next human
     interaction."
2. **Maintain a session-lifetime VM log.** When creating a new VM,
   append to `/tmp/claude_session_vms.txt` (timestamp + name + purpose).
   Before ending any autonomous wakeup chain, `az vm list` and reconcile
   against this file; tear down anything still present unless the user
   has specifically authorized keeping it.
3. **Prefer ephemeral OS disks** (`--ephemeral-os-disk true`) for VMs
   that will be deleted at session end — halves cleanup work and
   guarantees OS disk doesn't leak.
4. **Data disks (like `solver-data`, `solver-data-westus3`) are NEVER
   deleted by Claude.** Detach before VM delete. User explicit approval
   needed to touch data-disk contents or delete the disk itself.
5. **On any session crash / interrupt, the first thing the next wakeup
   does is reconcile VM state against the session-lifetime log.**
6. **First action of every Azure-touching session: reconcile both VMs AND
   long-running scripts.** Run `az vm list -d` and account for every
   running VM. ALSO run:
   ```
   ps -ef | grep -E "\.sh$|monitor|watcher|loop" | grep -v grep
   ```
   Any bash script alive longer than the current session is a candidate
   orphan from a prior session. `pkill -f` is unreliable; use
   `kill -9 <pid>` and verify with a re-`ps`. Orphan scripts will
   silently undo VM cleanup — e.g., a monitor designed to auto-restart
   a VM after Spot eviction will keep restarting it forever once the
   originating session ends.

**Past incidents this rule exists to prevent (see HISTORY.md §Missteps):**

- 2026-04-19 06:09 → 2026-04-20 14:11: solver-d3 F64als_v6 spot ran for ~32 hrs unnoticed, ~$25 spend
- 2026-04-20 18:59 → 2026-04-21 04:35: solver-d3 F64als_v6 spot ran for ~9.5 hrs before operator caught it, ~$7.50 spend
- campaign-westus2 OS disk orphaned for several hours after VM delete until user noticed
- 2026-04-26 → 2026-04-29: deep-calib-westus3 (recreated as Regular D64als_v7) was kept alive by 3 orphan bash scripts left running on the `claude` orchestrator from sessions ending Apr 25-26 (`deep_calib_monitor.sh`, `deep_calib_milestone_watcher.sh`, `alpha_log_updater_loop.sh` — plus 2 stale `monitor_canonical.sh` from Apr 17). The monitor's auto-restart-on-eviction logic kept undoing manual `az vm deallocate` commands. The 2026-04-28 ~$70 idle-VM incident was fixed by deallocating, but the monitor kept resurrecting the VM until 2026-04-29 14:30 when the orphan scripts were SIGKILL'd and the VM (along with `campaign-westus3` and `stats-westus3`) was deleted entirely. Estimated total cost of the resurrection cycle: ~$70-100 over 3 days.

## Never do without explicit user approval

- Delete managed disks — the exception is **Premium SSD temp disks
  for external merges**, which are temporary by standing pattern
  (attach → use → destroy). All other managed disks, including
  orphaned OS disks from deleted VMs, require explicit approval.
- Force-push or amend published commits.
- Commit changes to `petersm3/roae` when the user has said "no
  commits" for specific paths (currently: the `.claude/` directory).
- Push anything to `petersm3/roae` without the user having had a
  chance to review non-trivial changes. Staging-doc commits to
  `petersm3/x` (private) can proceed without per-commit review for
  routine working-log updates.
- Launch large compute (≥10T enumeration or ≥3 hr external merge)
  without cost confirmation AND without running the VM-priority
  verification gate above.

## Single C source file — `solve.c` — no new `.c` files

**Standing rule (2026-04-21):** All C code on this
project lives in `solve.c`. All Python lives in `solve.py`. The only
exception to the Python rule is `viz/visualize.py` (PCA plots — separate
because its dependency footprint is heavy and it's run independently).
No new `.c` or `.py` files elsewhere, not even for analysis tools.

- Need a tool to parse an enumeration log? Add it as a subcommand in
  `solve.c` (e.g., `./solve --yield-report`), not a separate `analyze_yields.c`.
- Need a Python analysis utility? Add it as a subcommand in `solve.py`
  (e.g., `solve.py --compute-stats`, `solve.py --marginals`,
  `solve.py --bivariate`, `solve.py --joint-density`) — not a separate
  `scripts/compute_stats.py` or similar.
- Shell, markdown, binaries outside the two consolidated files are fine.

Why: single source of truth, one compile target, one test matrix, no
dependency sprawl. `solve.c` and `solve.py` are the two canonical source
files on this project; they stay that way.

Past violations:
- 2026-04-21: `analyze_yields.c` created as a separate file; user directive
  "i do not want new c files, i want them in solve.c" established the rule
  for C.
- 2026-04-21: `scripts/compute_stats.py`, `scripts/p2_marginals.py`,
  `scripts/p2_bivariate.py`, `scripts/p2_joint_density.py` developed as
  separate files during the P2 distributional-analysis sprint. Consolidated
  into `solve.py` on 2026-04-21 per user directive "consolidate all except
  viz/visualize.py"; `scripts/` subdirectory removed.

## Never commit to this repo

- `.claude/` — local Claude Code metadata
- `solutions.bin` itself — too large; the sha256 is the reproducibility
  anchor, not the bytes
- Outside-repo staging docs — those live in `petersm3/x/roae/` (a
  separate private repo). If an operator-planning doc is in the
  working tree here, move it to `x/roae/`.

## In-flight state

For "what am I currently doing / what's running / what's next," read
**`~/github/x/roae/CURRENT_PLAN.md`** first. That doc is refreshed as
operational state changes; this CLAUDE.md is stable.

Also check scheduled wake-ups (the runtime fires these automatically
when 100T/analysis/validation jobs hit milestones — the wake prompt
itself contains the decision tree).

## Bi-region architecture

- Orchestrator: `claude` VM (D2as_v6) in **westus2**.
- Compute: D128als_v7 in **westus3** (as of 2026-04-19 pivot). **Spot** for enumeration workloads (eviction-resilient); on-demand for merge phases (eviction-fragile). See §Cost control above for the mandatory pre-launch verification gate. Note: the specific 100T d3 run on 2026-04-19/20 was inadvertently provisioned as on-demand by an earlier autonomous session; this is corrected-forward by the verification gate now documented here.
- F64als_v6 westus2 is **retired**. New large-scale enumeration uses
  Dalsv7 westus3 exclusively.
- Managed disks are region-locked — cross-region needs snapshot+copy.
  Bi-region archival is handled by `solver-data-westus3` (new
  canonical holder) + legacy `solver-validate-d3` (westus2, d3 10T
  canonical artifacts).

## One-line rule of thumb

Changes to this file should themselves be rare. If you're tempted to
add something, first check if it belongs in a more topic-specific doc
— this file only earns entries for things that no other doc already
says, AND that Claude specifically needs loaded in context to do the
right thing.
