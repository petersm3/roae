# Documentation

All project documentation except the technical-report suite, which lives in [reports/](../reports/README.md). The root `README.md` is the GitHub repo landing page.

Three files stay at the repo root for tooling reasons: `README.md` (GitHub landing page), `CLAUDE.md` (orientation file the Claude Code AI auto-discovers), and `LICENSE.md` (GitHub auto-detects).

## Start here

| If you want… | Read |
|---|---|
| Plain-language explainer (no math background needed) | [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) |
| A newcomer's guided introduction | [GUIDE.md](GUIDE.md) |
| Conceptual explanation of branches, sub-branches, nodes, budgets | [BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md) |
| The technical scientific record (what holds, what doesn't, why) | [SOLVE.md](SOLVE.md) |
| The findings in depth — the technical-report suite (authoritative over SOLVE.md where they disagree) | [reports/README.md](../reports/README.md) |
| Formal constraint definitions and theorems | [SPECIFICATION.md](SPECIFICATION.md) |
| Known limitations, methodological caveats, null-model results | [CRITIQUE.md](CRITIQUE.md) |
| Project history — missteps, corrections, the forensic trail | [HISTORY.md](HISTORY.md) |
| Registered corrections to published claims (append-only) — C4 qualifiers and unregistered edits are in [CORRECTIONS_INVENTORY.tsv](CORRECTIONS_INVENTORY.tsv), not in this file; see CORRECTIONS.md §"What this record does not contain" | [CORRECTIONS.md](CORRECTIONS.md) |
| How to reproduce results from scratch | [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md) |
| Canonical sha256 registry + reproducibility parameters | [CANONICAL_HASHES.md](CANONICAL_HASHES.md) |

## Topic index

### Scientific record

- **[SOLVE.md](SOLVE.md)** — Technical analysis of all 28 statistical findings, with appropriate null-model caveats. The project's working scientific record; by its own authority note it is a legacy narrative that predates the [technical reports](../reports/README.md), and where the two disagree **the reports win**.
- **[SOLVE_SUMMARY.md](SOLVE_SUMMARY.md)** — Plain-language summary of what `solve.c` + `solve.py` compute and what the enumeration reveals. Audience: scientifically literate but not necessarily mathematicians.
- **[SPECIFICATION.md](SPECIFICATION.md)** — Formal constraint definitions (C1–C5), constraint-extraction methodology, theorems with proofs.
- **[CRITIQUE.md](CRITIQUE.md)** — Honest limitations: the null-model caveat, statistical framing, what the project does NOT prove.
- **[DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md)** — Where King Wen sits in the joint distribution of observables across the canonical (the former "rank < 10⁻⁵" headline was withdrawn 2026-07-26 as circular; de-circularized result: ≈30th percentile on the KW-independent dimensions — distributionally unremarkable. That ≈30% figure is **published ahead of its public reproduction command** — `--joint-density-dims` / `--joint-density-seed` are not wired to the CLI; see the source document's "Reproducing this figure" note, gap recorded 2026-08-30).
- **[SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md)** — Total C1–C5 search-space size (Monte-Carlo estimate ≈10³⁸; why King Wen is found early in enumeration).
- **[PARITY_ALTERNATION.md](PARITY_ALTERNATION.md)** — Theorem: every valid ordering has exactly 15 parity-class alternations (proven skeleton constraint; ×7.26 arrangement-level reduction; exact O(1) prefix prune).
- **[LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md)** — Prior literature's structural rules ([Moore](CITATIONS.md#moore2005), [Cook](CITATIONS.md#cook2006), classical) measured against the full ≈10³⁸ population; Moore's parity rule = strongest of the population-measured rules in the scoreboard (×1,362 at KW's level; joint ×54,000), while [Schulz](CITATIONS.md#schulz1990-motifs)'s gender/position-parity rule is the strongest *principled* literature rule at ×11,364; the data-like S25–28 configuration measures ×5×10⁷ — see "A new strongest discriminator").
- **[PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)** — Theorem that canonical enumeration counts are invariant under partition strategy (full-enum vs `--branch` reconstruction), under exhaustive enumeration or with `SOLVE_PER_SUB_BRANCH_LIMIT` set to the same value in both modes — budgeted runs left to the auto-divide give the two modes different per-sub-branch budgets and a different sha256. With the cross-path validation grid.
- **[TRIGRAM_STRUCTURE.md](TRIGRAM_STRUCTURE.md)** — Machine-checked trigram-level theorems: the forced between-pair transition budget (McKenna's "9th six" derived from C1+C5), the trigram-compatible symmetry subgroup (S₃ × C₂), nuclear-map naturality, and two vacuity guards — with the attribution ledger and the scope distinction from [Hershock 1991](CITATIONS.md#hershock1991).
- **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)** — The detailed findings narrative that formerly lived on the repository front page. Carries the same authority note as SOLVE.md: it predates the technical reports, and where they disagree the reports win.
- **[CLAIMS_DECIDED.md](CLAIMS_DECIDED.md)** — The empirical scorecard: which claims are decided, which are open, and what settled each. It adjudicates rather than measures — every row links to the report that owns the measurement.
- **[DESCRIPTION_LENGTH.md](DESCRIPTION_LENGTH.md)** — Bit-level constraint pricing: a two-part MDL ledger of what each constraint explains net of what it costs to state, and the unexplained residual.
- **[CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md)** — The sequence read as a cycle (position 64 wrapping to 1), as McKenna & McKenna (1975) did: which theorems and measurements carry over, plus the SAT decision.
- **[BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md)** — Conceptual explainer for "branch / sub-branch / node / budget" terms used throughout.

### Stable scientific findings (paper-citable)

These docs hold **paper-citable scientific findings** that have stabilized beyond working-note status. Each has a clear *Result* sentence, reproduction commands for `solve.c` (or `roae.py`), and cross-links to working-version analysis. Inputs are committed for the 10T and 100T canonicals (`runs/*/analyze_output.log.gz`); the 560T analyze log and PASS1's second run are operator-held and are **not** in the checkout. Promoted here only after the result is unlikely to be revised by further work.

(Convention: docs lived in a top-level `findings/` directory before the 2026-06-11 consolidation into `documentation/`; that directory no longer exists.)

- **[PARTITION_STABILITY_BOUNDARIES.md](PARTITION_STABILITY_BOUNDARIES.md)** — Boundaries {25, 27} are mandatory in every greedy-ordered minimum-boundary set identifying KW across all four canonicals tested (d2 10T, d3 10T, d3 100T, d3 560T). The single most stable structural property of King Wen measured.
- **[BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md)** — The number of boundary constraints required to uniquely identify King Wen is monotone non-decreasing with scale: greedy minimum 4 → 5 → 5 across d3 10T → 100T → 560T, with the identical set {1, 4, 21, 25, 27} at both canonical scales; working-4-subset count 8 → 0 across d3 10T → 100T (stays at 0 at 560T). *(Renamed from BOUNDARY_MINIMUM_NON_MONOTONE.md on 2026-07-04 when its "non-monotone 4→5→4" headline was found to be a survivor-counting error.)*
- **[SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md)** — POSITIVE result: the C1–C5 constraint system admits an exact symmetry group — the 48 bit-position permutations commuting with bit-reversal (B₃, the octahedral group; effective group on canonical records S₄, order 24) — proven, and complete over all 64! hexagram relabelings *that preserve each constraint predicate*; the finite kernel is machine-checked in Lean, the 46,080-automorphism enumeration by `solve.py --symmetry-completeness`. (For solution-set automorphisms the proof gives containment G ⊆ Aut(solset) only; whether Aut(solset) exceeds G is not decided.) King Wen has exactly 23 record-level twin orderings. *(The target document was corrected 2026-07-02, REVERSING its earlier "NEGATIVE result: all 47 non-trivial candidates falsified" — that conclusion compared budget-truncated per-cell yields, which measure budget/dedup artifacts, not solution-set asymmetry. This index line kept the superseded negative until 2026-08-06; see the correction notice in the document and CRITIQUE.md item 12.)*
- **[PASS1_TRAJECTORY_DETERMINISM.md](PASS1_TRAJECTORY_DETERMINISM.md)** — Two independent multi-threaded runs of `--sub-branch 22 0 30 1 20 0` agree to under 1% from 10¹¹ to 10¹³ nodes (33% at 10¹⁰, a startup transient). Free reproducibility check.

### Reproducibility & data

- **[CANONICAL_HASHES.md](CANONICAL_HASHES.md)** — The canonical sha256 registry. Every published canonical run with reproducibility env vars, record counts, and validation status. **Single source of truth for canonical anchors.**
- **[SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md)** — Binary format of `solutions.bin` (32-byte records, header, canonical-equivalence mask).
- **[REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md)** — How to reproduce the canonical enumeration from a clean checkout: build, run, sha-verify.

- **[VERIFY.md](VERIFY.md)** — The independent second instruments (`verify.py`, `verify.c`): what each recomputes, and why derivation-independence rather than re-execution is what makes them independent.
- **[CLAIM_TO_ARTIFACT.md](CLAIM_TO_ARTIFACT.md)** — The claim-to-artifact matrix: for each headline claim, the named artifact and the named command that check it.
- **[PREREGISTRATION_ESCROW.md](PREREGISTRATION_ESCROW.md)** — sha256 escrow of the frozen pre-registration files, so a pre-registered observable, family size and decision rule can be shown to predate its result.
- **[F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md)** — On-disk format specification for the `--f1-exact-c1c2c4c5` out-of-core layer files, run manifests and build checkpoints.
- **[GT_LADDER_FORMAT.md](GT_LADDER_FORMAT.md)** — On-disk format specification for the g-ladder and t-ladder artifacts (`--kc-g-build` / `--kc-t-build`); companion to F1C5_LAYER_FORMAT.md, which defines the shared container.

### CLI references

- **[SOLVE_C_CLI.md](SOLVE_C_CLI.md)** — Complete `solve.c` command-line reference (subcommands, environment variables, exit codes).
- **[SOLVE_PY_CLI.md](SOLVE_PY_CLI.md)** — Complete `solve.py` analysis + ground-truth CLI reference (constraint-structure analyses, P2 distributional pipeline, P3 SAT encoders, verification batteries, modifiers).
- **[ROAE_PY_CLI.md](ROAE_PY_CLI.md)** — Complete `roae.py` analysis-CLI reference (29 analysis sections — 28 statistical plus the theorem-backed `--parity` — modifiers, export formats).
- **[SAT_CLI.md](SAT_CLI.md)** — Complete `sat.py` SAT/certificate-layer reference (`--emit-cnf` / `--witness`, constraint targets, `--with-c3` / `--c3-max`).

### Development & deployment

- **[DEVELOPMENT.md](DEVELOPMENT.md)** — Build, self-test, project conventions ("proven" language, dataset-scope, asset preservation, **build reproducibility** + toolchain manifest rules added 2026-05-12).
- **[DEPLOYMENT.md](DEPLOYMENT.md)** — Azure deployment patterns, SKU sizing, Spot-vs-Regular policy, two-phase enum/merge architecture.
- **[CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md)** — Methodology and reproducibility guide for very-large (11.2T+) canonical enumeration campaigns, including the 560T worked example and the milestone-extension recipe. Supersedes [LARGE_SCALE_CAMPAIGNS.md](LARGE_SCALE_CAMPAIGNS.md) as of 2026-06-08 — deprecated as the *entry point*, retained as the operations reference (next entry).

- **[LARGE_SCALE_CAMPAIGNS.md](LARGE_SCALE_CAMPAIGNS.md)** — The operations guide. Deprecated as the *entry point* (2026-06-08) but **not superseded in content**: the 2026-08-08 section-by-section comparison found the two documents complementary, and §2 sizing (thread caps, VM-count trade-offs, per-thread rates), §6 per-VM runner and cross-VM orchestrator pseudocode, §9b/9c disk-based external and tiered merge, §13.0 scale honesty (`solve.c` is **not** empirically validated above the 100T pilot) and §13a campaign gotchas have no counterpart in CAMPAIGN_METHODOLOGY.md. Read that one for correctness questions, this one for planning and running a campaign.
- **[PERFORMANCE_HISTORY.md](PERFORMANCE_HISTORY.md)** — Append-only log of every perf-relevant change to `solve.c`, improvements and regressions alike, each with hypothesis, paired-bench numbers, sha gate and ship decision.

### Narrative & meta

- **[HISTORY.md](HISTORY.md)** — Day-by-day project narrative. The honest record of how the analysis evolved, including bugs found, claims invalidated, and corrections made. Largest single document; the canonical source of "how did we get here."
- **[CITATIONS.md](CITATIONS.md)** — Prior literature, what is classical vs. prior vs. novel vs. methodological in this work.
- **[KING_WEN_PROVENANCE.md](KING_WEN_PROVENANCE.md)** — Where the received sequence comes from, and which orderings this project does **not** study. Orientation, not a finding; written for a reader who has never opened an *I Ching*.
- **[MCKENNA.md](MCKENNA.md)** — Relationship to [Terence McKenna's](CITATIONS.md#mckenna-mckenna1975) Timewave Zero theory, where the data does and does not support related claims.

## Cross-references that live outside this directory

- **Root [README.md](../README.md)** — GitHub repo landing page; very brief project overview.
- **[reports/README.md](../reports/README.md)** — The technical-report suite: the findings in depth, living-versioned, with `METHODS.md` and the `certificates/` verification bundle. Named an authoritative source in root `CLAUDE.md`; where a report and [SOLVE.md](SOLVE.md) or [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) disagree, the report wins.
- **Root [CLAUDE.md](../CLAUDE.md)** — AI-orientation file. Pointers and invariants only; everything substantive is in `documentation/` and `reports/`.
- **[enumeration/LEADERBOARD.md](../enumeration/LEADERBOARD.md)** — Current state of the enumeration (newest canonical, scale, sha).
- **[viz/README.md](../viz/README.md)** — Visualization tooling.
- **[scripts/capture_build_manifest.sh](../scripts/capture_build_manifest.sh)** — Emits the per-build environment manifest for canonical archives (gcc/glibc/libgomp/host/image). See [DEVELOPMENT.md](DEVELOPMENT.md) §"Build reproducibility".

## Reading order

For a first-time read of the project (times are `wc -w` ÷ 250 words/minute, measured 2026-09-01):

1. Root [README.md](../README.md) (~17 min; 4,202 words)
2. [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) (~33 min; 8,313 words — gives you the scientific shape)
3. [CRITIQUE.md](CRITIQUE.md) (~58 min; 14,527 words — sets the honest framing)
4. Skim [HISTORY.md](HISTORY.md) (long — read the recent dated sections to see where things currently stand)
5. Then dig into whichever specialty document maps to your interest (technical = [SOLVE.md](SOLVE.md), formal = [SPECIFICATION.md](SPECIFICATION.md), reproducibility = [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md), distribution = [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md))
