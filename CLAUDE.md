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

**Standing policy (2026-04-20, after an ~$73 avoidable overspend on the 100T d3 run):**

- **Enumeration** (`solve.c` running sub-branches, no `--merge`) → **spot priority, 128 cores** (D128als_v7 westus3). Enumeration is eviction-resilient; the orchestrator can resume from checkpoint. Spot pricing is ~70-85% discount ($5.146/hr on-demand → $0.95/hr spot on D128als_v7).
- **Merge** (`solve.c --merge`) → **on-demand priority, RIGHT-SIZED (NOT 128 cores).** Merge is single-threaded heap-sort; 1-2 cores are used, the rest are idle. Pay for what the workload uses.
  - d3 10T merge (~89 GB pre-dedup): **D16als_v7 (16 cores, 32 GB RAM)** on-demand ~$0.50/hr → $0.50 for a 1-hour merge
  - d3 100T merge (~880 GB pre-dedup, external): **D32als_v7 (32 cores, 64 GB RAM)** on-demand ~$1.30/hr → ~$7 for a 5-hour merge (vs ~$28 on D128)
  - Rule: size merge VM by **RAM needed** (pre-dedup size if in-memory, 2× chunk size if external) and **I/O bandwidth** (match to the premium SSD throughput), NOT by core count.
- If one VM will run both phases and you don't want to stop/restart between them: either (a) stop the VM after enum, resize to smaller SKU, restart for merge, OR (b) create two VMs and transfer shards. (b) is preferred for large runs because enum's D128als_v7 spot is 5× cheaper-per-core-hour than merge's D32als_v7 on-demand, but only if you use the cores.

**Mandatory pre-launch verification gate (EVERY time, for any workload >1 hour):**

```
az vm show -g <rg> -n <vm> --query priority -o tsv
```

- Output `Spot` → OK for enumeration.
- Output empty / `null` / `Regular` → OK only for merge or explicit on-demand workload. If the intent was spot for enumeration, STOP. Either recreate the VM as spot (`--priority Spot --eviction-policy Deallocate --max-price -1`) or escalate to the user for approval before launching.

**Creation command templates (must match the workload type):**
- Spot: `az vm create ... --priority Spot --eviction-policy Deallocate --max-price -1`
- On-demand: default (no `--priority` flag)

Failure mode this prevents: on 2026-04-19, d128-westus3 was provisioned without `--priority Spot` by an earlier autonomous session, and the 100T run (16h 48m) was launched on it without verification. Total overspend on the enumeration portion (where spot would have worked): ~$48-73. See HISTORY.md §Missteps for the full retrospective.

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

**Past incidents this rule exists to prevent (see HISTORY.md §Missteps):**

- 2026-04-19 06:09 → 2026-04-20 14:11: solver-d3 F64als_v6 spot ran for ~32 hrs unnoticed, ~$25 spend
- 2026-04-20 18:59 → 2026-04-21 04:35: solver-d3 F64als_v6 spot ran for ~9.5 hrs before operator caught it, ~$7.50 spend
- campaign-westus2 OS disk orphaned for several hours after VM delete until user noticed

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

**Standing rule (2026-04-21):** All C code on this project lives in `solve.c`.
No new `.c` files, not even for analysis tools that don't touch enumeration.

- Need a tool to parse an enumeration log? Add it as a subcommand in
  `solve.c` (e.g., `./solve --yield-report`), not a separate `analyze_yields.c`.
- Need a helper utility? Same — new subcommand inside `solve.c`.
- Python (`scripts/*.py`), shell, markdown, binaries all fine — rule is
  specifically about `.c` files.

Why: single source of truth, one compile target, one test matrix, no
dependency sprawl. `solve.c` is already the canonical C file on this
project; it stays that way.

Past violation: 2026-04-21 created `analyze_yields.c` as a separate file;
user directive "i do not want new c files, i want them in solve.c" /
"if it's written in C, it goes into solve.c, not its own new C file"
established the rule.

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
