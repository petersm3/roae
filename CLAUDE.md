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

## Never do without explicit user approval

- Delete managed disks — the exception is **Premium SSD temp disks
  for external merges**, which are temporary by standing pattern
  (attach → use → destroy). All other managed disks, including
  orphaned OS disks from deleted VMs, require explicit approval.
- Force-push or amend published commits.
- Commit changes to `petersm3/roae` when the user has said "no
  commits" for specific paths (currently: `viz/` assets, i.e.
  visualize.py, viz_*.png/svg; the `.claude/` directory).
- Push anything to `petersm3/roae` without the user having had a
  chance to review non-trivial changes. Staging-doc commits to
  `petersm3/x` (private) can proceed without per-commit review for
  routine working-log updates.
- Launch large compute (≥10T enumeration or ≥3 hr external merge)
  without cost confirmation.

## Never commit to this repo

- `.claude/` — local Claude Code metadata
- `viz/visualize.py` and viz PNG/SVG outputs (user directive, pending
  explicit approval to commit)
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
- Compute: D128als_v7 spot in **westus3** (as of 2026-04-19 pivot).
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
