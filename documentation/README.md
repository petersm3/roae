# Documentation

All project documentation. The root `README.md` is the GitHub repo landing page; everything else lives here.

Three files stay at the repo root for tooling reasons: `README.md` (GitHub landing page), `CLAUDE.md` (orientation file the Claude Code AI auto-discovers), and `LICENSE.md` (GitHub auto-detects).

## Start here

| If you want… | Read |
|---|---|
| Plain-language explainer (no math background needed) | [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md) |
| A newcomer's guided introduction | [GUIDE.md](GUIDE.md) |
| Conceptual explanation of branches, sub-branches, nodes, budgets | [BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md) |
| The technical scientific record (what holds, what doesn't, why) | [SOLVE.md](SOLVE.md) |
| Formal constraint definitions and theorems | [SPECIFICATION.md](SPECIFICATION.md) |
| Known limitations, methodological caveats, null-model results | [CRITIQUE.md](CRITIQUE.md) |
| Project history — missteps, corrections, the forensic trail | [HISTORY.md](HISTORY.md) |
| How to reproduce results from scratch | [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md) |
| Canonical sha256 registry + reproducibility parameters | [CANONICAL_HASHES.md](CANONICAL_HASHES.md) |

## Topic index

### Scientific record

- **[SOLVE.md](SOLVE.md)** — Technical analysis of all 28 statistical findings, with appropriate null-model caveats. The primary scientific document.
- **[SOLVE-SUMMARY.md](SOLVE-SUMMARY.md)** — Plain-language summary of what `solve.c` + `solve.py` compute and what the enumeration reveals. Audience: scientifically literate but not necessarily mathematicians.
- **[SPECIFICATION.md](SPECIFICATION.md)** — Formal constraint definitions (C1–C5), constraint-extraction methodology, theorems with proofs.
- **[CRITIQUE.md](CRITIQUE.md)** — Honest limitations: the null-model caveat, statistical framing, what the project does NOT prove.
- **[DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md)** — Where King Wen sits in the joint distribution of observables across the 3.43B-ordering canonical (0.000%-ile joint density).
- **[PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)** — Theorem that canonical enumeration counts are invariant under partition strategy (full-enum vs `--branch` reconstruction), with the cross-path validation grid.
- **[BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md)** — Conceptual explainer for "branch / sub-branch / node / budget" terms used throughout.

### Reproducibility & data

- **[CANONICAL_HASHES.md](CANONICAL_HASHES.md)** — The canonical sha256 registry. Every published canonical run with reproducibility env vars, record counts, and validation status. **Single source of truth for canonical anchors.**
- **[SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md)** — Binary format of `solutions.bin` (32-byte records, header, canonical-equivalence mask).
- **[REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md)** — How to reproduce the canonical enumeration from a clean checkout: build, run, sha-verify.

### CLI references

- **[SOLVE_CLI.md](SOLVE_CLI.md)** — Complete `solve.c` command-line reference (subcommands, environment variables, exit codes).
- **[ROAE_PY_CLI.md](ROAE_PY_CLI.md)** — Complete `roae.py` analysis-CLI reference (28 analysis sections, modifiers, export formats).

### Development & deployment

- **[DEVELOPMENT.md](DEVELOPMENT.md)** — Build, self-test, project conventions ("proven" language, dataset-scope, asset preservation, **build reproducibility** + toolchain manifest rules added 2026-05-12).
- **[DEPLOYMENT.md](DEPLOYMENT.md)** — Azure deployment patterns, SKU sizing, Spot-vs-Regular policy, two-phase enum/merge architecture.
- **[LARGE_SCALE_CAMPAIGNS.md](LARGE_SCALE_CAMPAIGNS.md)** — Patterns and lessons for very-large (100T+) enumeration campaigns.

### Narrative & meta

- **[HISTORY.md](HISTORY.md)** — Day-by-day project narrative. The honest record of how the analysis evolved, including bugs found, claims invalidated, and corrections made. Largest single document; the canonical source of "how did we get here."
- **[CITATIONS.md](CITATIONS.md)** — Prior literature, what is classical vs. prior vs. novel vs. methodological in this work.
- **[MCKENNA.md](MCKENNA.md)** — Relationship to Terence McKenna's Timewave Zero theory, where the data does and does not support related claims.

## Cross-references that live outside this directory

- **Root [README.md](../README.md)** — GitHub repo landing page; very brief project overview.
- **Root [CLAUDE.md](../CLAUDE.md)** — AI-orientation file. Pointers and invariants only; everything substantive is in `documentation/`.
- **[enumeration/LEADERBOARD.md](../enumeration/LEADERBOARD.md)** — Current state of the enumeration (newest canonical, scale, sha).
- **[viz/README.md](../viz/README.md)** — Visualization tooling.
- **[scripts/capture_build_manifest.sh](../scripts/capture_build_manifest.sh)** — Emits the per-build environment manifest for canonical archives (gcc/glibc/libgomp/host/image). See [DEVELOPMENT.md](DEVELOPMENT.md) §"Build reproducibility".

## Reading order

For a first-time read of the project:

1. Root [README.md](../README.md) (1–2 min)
2. [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md) (10 min, gives you the scientific shape)
3. [CRITIQUE.md](CRITIQUE.md) (5 min, sets the honest framing)
4. Skim [HISTORY.md](HISTORY.md) (long — read the recent dated sections to see where things currently stand)
5. Then dig into whichever specialty document maps to your interest (technical = [SOLVE.md](SOLVE.md), formal = [SPECIFICATION.md](SPECIFICATION.md), reproducibility = [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md), distribution = [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md))
