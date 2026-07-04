# Enumeration directory — results + historical analysis artifacts

This directory holds the project's **enumeration leaderboard** (headline
results table) plus archival analysis artifacts from earlier dataset
eras. Canonical per-run artifacts for 2026-04-18-onward canonical runs
live under `../runs/<run-id>/` instead; this directory is
predominantly historical.

## Headline reference

- **[LEADERBOARD.md](LEADERBOARD.md)** — the authoritative enumeration
  scoreboard. Current canonical counts (**d3 560T: 10,525,271,997, sha
  `9a968fa2…`** — current deepest, established 2026-06-08; d3 100T:
  3,432,399,297, sha `915abf30…`; d3 10T: 706,427,594, sha
  `b85c8871…`; d2 10T: 286,357,503, sha `a09280fb…`),
  per-first-level-branch solution totals, dead-branch classification,
  sub-branch yields. Read this first.

## Current canonical artifacts (pre-format-v1 era — 2026-04-14/15 run)

These files document the `aa1415…` pre-bugfix 742M dataset. The count
(742,043,303) was an undercount caused by a hash-table probe-cap bug,
now invalidated. These files remain as historical reference and
methodological audit trail — they should be read with the awareness
that the counts they describe are superseded.

- **`solve_output.txt`** (532 KB) — full stdout of the April-15 10T
  enumeration run that produced the 742M sha.
- **`solve_results.json`** (17 KB) — machine-readable summary of the
  same run.
- **`checkpoint.txt`** (406 KB) — per-sub-branch completion trail
  from that run.
- **`solutions.sha256`** (80 B) — sha for the superseded 742M
  solutions.bin.

## Historical `--analyze` outputs (742M era)

Full text-mode outputs from `./solve --analyze solutions.bin` on the
invalidated 742M dataset. Superseded by the per-run
`analyze_output.log.gz` files under `../runs/<run-id>/` for
canonical 2026-04-18 datasets.

- **`analyze_c_742M.txt`** (11 KB) — core analyze output (per-position
  entropy, per-boundary survivors, greedy + exhaustive boundary
  analysis).
- **`analyze_sec25fix_742M.txt`** (52 KB) — section-22 revisited output
  after a fix to how KW complement distance was computed.
- **`analyze_section14_742M.txt`** (13 KB) — orient-coupling
  generalization analysis (section 14).

Why keep them: LEADERBOARD.md cross-references specific numbers from
these files, and they document the exact state at which certain bugs
were caught. Deleting them would erase the forensic audit trail.

## Other artifacts

- **`analysis_minimum_constraints.txt`** (5 KB) — a methodological
  memo on the minimum-constraints question that predates the
  solve.c-based enumeration. Historical; superseded by SOLVE.md's
  boundary-minimum treatment (4 at 10T, 5 at canonical depth).
- **`SOLUTIONS_BIN_LOCATION.txt`** — pointer to where the canonical
  solutions.bin actually lives (Azure managed disk, not committed
  to git). Cross-references from other docs point readers here for
  operational questions about physical data location.

## What's NOT in this directory

- `solutions.bin` itself. Too large to commit (22.6 GB for d3 10T;
  will grow with 100T). Lives on Azure managed disks; see
  `SOLUTIONS_BIN_LOCATION.txt` + the per-run README under
  `../runs/<run-id>/` for access instructions.
- Current-canonical analyze outputs for d2 10T and d3 10T. Those
  live at `../runs/20260418_10T_d2_fresh/analyze_output.log.gz`
  and `../runs/20260418_10T_d3_fresh/analyze_output.log.gz`.

## Navigation

For the current state of the project, start at:

- [`../README.md`](../README.md) — project overview
- [`LEADERBOARD.md`](LEADERBOARD.md) — enumeration results headline
- [`../documentation/HISTORY.md`](../documentation/HISTORY.md) — narrative of how we got here
- [`../documentation/SOLVE.md`](../documentation/SOLVE.md) or [`../documentation/SOLVE-SUMMARY.md`](../documentation/SOLVE-SUMMARY.md) —
  constraint analysis (technical or plain-language)

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) §d3 100T.*
