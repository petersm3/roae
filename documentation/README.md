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
- **[DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md)** — Where King Wen sits in the joint distribution of observables across the canonical (0.000%-ile joint density at 100T scope; 560T re-eval queued).
- **[PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)** — Theorem that canonical enumeration counts are invariant under partition strategy (full-enum vs `--branch` reconstruction), with the cross-path validation grid.
- **[BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md)** — Conceptual explainer for "branch / sub-branch / node / budget" terms used throughout.

### Stable scientific findings (paper-citable)

These docs hold **paper-citable scientific findings** that have stabilized beyond working-note status. Each has a clear *Result* sentence, reproduction commands using committed data + `solve.c` (or `roae.py`), and cross-links to working-version analysis. Promoted here only after the result is unlikely to be revised by further work.

(Convention: docs lived in `../findings/` before the 2026-06-11 consolidation; see [`../findings/README.md`](../findings/README.md) for the redirect stub.)

- **[PARTITION_STABILITY_BOUNDARIES.md](PARTITION_STABILITY_BOUNDARIES.md)** — Boundaries {25, 27} are mandatory in every greedy-ordered minimum-boundary set identifying KW across all four canonicals tested (d2 10T, d3 10T, d3 100T, d3 560T). The single most stable structural property of King Wen measured.
- **[BOUNDARY_MINIMUM_NON_MONOTONE.md](BOUNDARY_MINIMUM_NON_MONOTONE.md)** — The number of boundary constraints required to uniquely identify King Wen is non-monotone with scale: greedy-ordered minimum 4 → 5 → 4 across d3 10T → 100T → 560T; unordered working-4-subset count 8 → 0 across d3 10T → 100T (stays at 0 at 560T). Falsifies the 100T-era prediction that the minimum would grow to 6+ at deeper scales.
- **[SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md)** — NEGATIVE result: no bit-position permutation is a symmetry of the C1 ∩ C2 ∩ C3 canonical. All 47 non-trivial candidates falsified at 100T-d3 (subset-preserved at 560T).
- **[PASS1_TRAJECTORY_DETERMINISM.md](PASS1_TRAJECTORY_DETERMINISM.md)** — Two independent multi-threaded runs of `--sub-branch 22 0 30 1 20 0` retrace each other to <0.2% across 10¹⁰ → 10¹³ nodes. Free reproducibility check.

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
- **[CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md)** — Methodology and reproducibility guide for very-large (11.2T+) canonical enumeration campaigns, including the 560T worked example and the milestone-extension recipe. Supersedes the prior `LARGE_SCALE_CAMPAIGNS.md` (now deprecated) as of 2026-06-08.

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
