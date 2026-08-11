# solve.py(1) — King Wen constraint analysis and ground-truth tool

> **CLI references:** this documents **`solve.py`** (analysis + ground truth). See also the [`solve` C binary](SOLVE_C_CLI.md) (enumerator/verifier) · [`roae.py`](ROAE_PY_CLI.md) (descriptive analyses) · [`sat.py`](SAT_CLI.md) (SAT / certificate layer).

A man-page-style command-line reference for `solve.py`, the Python
analysis + ground-truth CLI for the King Wen constraint system. Where
`roae.py` characterizes King Wen as a fixed sequence (28 descriptive
analyses; see [ROAE_PY_CLI.md](ROAE_PY_CLI.md)) and `solve.c`
enumerates the C1–C5 ordering space at canonical scale (see
[SOLVE_C_CLI.md](SOLVE_C_CLI.md)), `solve.py` sits between them: it runs
the constraint-structure analyses, the P2 distributional pipeline over
enumerated `solutions.bin`, the P3 SAT encoders, and the two-language
**ground-truth verifiers** that gate `solve.c`'s C ports.

Per the project single-file rule ([CLAUDE.md](../CLAUDE.md)), all
analysis Python lives in this one file (`solve.py`); the SAT layer is
the sibling `sat.py` (see [SAT_CLI.md](SAT_CLI.md)), which imports
`solve.py` for its constraint semantics.

## NAME

**solve.py** — King Wen constraint-structure analyses (pairs, generative
recipe, adjacency graph, boundary features, backtracking enumeration,
trigram/line/neighborhood decompositions, extremality and fingerprint
analyses), the P2 population-distribution pipeline, P3 SAT encoders, and
the ground-truth verification batteries.

## SYNOPSIS

```
python3 solve.py                         # default: --rules + --narrow
python3 solve.py --<analysis>            # run one (or several) analyses
python3 solve.py --local                 # graph + boundaries + construct
python3 solve.py --deep                  # the six deep analyses (see below)

# P2 distributional pipeline (over a solve.c solutions.bin)
python3 solve.py --compute-stats SOLUTIONS_BIN OUT_DIR
python3 solve.py --marginals CHUNKS_DIR OUT_MD
python3 solve.py --joint-density-v2 CHUNKS_DIR OUT_MD [--joint-density-bandwidth cv|silverman]

# P3 SAT encoding
python3 solve.py --sat-encode OUT.cnf [--sat-c3 pb|adder] [--sat-c4] [--sat-c5]

# TR-8 dof-matched KW-fitting-predicate sampler
python3 solve.py --tr8-dof-selftest
python3 solve.py --tr8-dof-emit-bank [--tr8-dof-seed ROOT] [--tr8-dof-calib-draws N]
python3 solve.py --tr8-dof-sampler OUT_DIR [--tr8-dof-pool A|B|calib] [--tr8-dof-pool-draws N]
python3 solve.py --tr8-dof-merge OUT_DIR

# Branch-yield + keystone reporting
python3 solve.py --branch-yield-report SOLUTIONS_BIN [--branch-yield-depth 1|2|3] ...
python3 solve.py --keystone-analysis SOLUTIONS_BIN OUT_MD

# Ground-truth verifiers (details in SOLVE_C_CLI.md)
python3 solve.py --f4p-verify | --f6-verify | --dav-verify | --dav2-verify | --db1-verify | --vdb-verify | --perm-verify [SEQ]
python3 solve.py --rc4b-verify [SEQ] | --rc1c-verify [SEQ] | --r11-verify [SEQ] | --r11-builder-verify
python3 solve.py --books-verify | --trigram-verify | --registry-verify | --extended-selftest SOLVE_BINARY

# H2 instrument (private hypothesis; magnitude only — over solve.c SOLVE_KNUTH_H2 dumps)
python3 solve.py --h2-verify DUMPFILE [N]
python3 solve.py --h2-mass DUMP [DUMP ...]
```

## DESCRIPTION

`solve.py` runs one or more analyses selected by flags. With **no
analysis flag**, it defaults to `--rules` + `--narrow` (the generative
recipe plus constraint-narrowing). Aggregate flags expand to several
analyses: `--local` = `--graph` + `--boundaries` + `--construct`;
`--deep` = `--enumerate` + `--trigram-paths` + `--line-decomp` +
`--pair-neighborhoods` + `--residuals` + `--info`.

Several command families are **terminal**: the verifiers, the P2/P3
pipeline commands, `--branch-yield-report`, and `--keystone-analysis`
each run and exit (they do not combine with the descriptive analyses).

Output is human-readable text to stdout by default; the P2 pipeline and
the report commands write Markdown / CSV / JSON / parquet artifacts to
paths you name.

## ANALYSIS SECTIONS

Each flag runs one analysis over the King Wen sequence and its
constraint structure.

### Constraint structure & recipe

| Flag | Description |
|---|---|
| `--pairs` | Show the 32 canonical pairs with their XOR products. |
| `--rules` | Print the discovered generative recipe (the candidate rule-set that reconstructs KW). *Part of the default run.* |
| `--narrow` | Run constraint-narrowing analysis — progressively adds constraints and reports the surviving-ordering count (Monte Carlo; honors `--trials`/`--seed`/`--verbose`). *Part of the default run.* |

### Local ordering

| Flag | Description |
|---|---|
| `--graph` | Analyze the pair-adjacency graph. |
| `--boundaries` | Analyze features at the between-pair boundaries. |
| `--construct` | Sequential-construction analysis with placement heuristics. |
| `--local` | Aggregate: runs `--graph` + `--boundaries` + `--construct`. |

### Deep analyses

| Flag | Description |
|---|---|
| `--enumerate` | Backtracking enumeration with all constraints (bounded by `--max-nodes` / `--time-limit`). |
| `--trigram-paths` | Track the upper/lower trigram paths through the sequence. |
| `--line-decomp` | Analyze each of the 6 line positions independently. |
| `--pair-neighborhoods` | Pair clustering and neighborhood structure. |
| `--residuals` | Compare the constraint survivors against King Wen. |
| `--info` | Information-content analysis. |
| `--deep` | Aggregate: runs `--enumerate` + `--trigram-paths` + `--line-decomp` + `--pair-neighborhoods` + `--residuals` + `--info`. |

### Extremality & reconstruction

| Flag | Description |
|---|---|
| `--differential` | Differential analysis: find the features on which King Wen is extremal among the solutions (bounded by `--max-nodes` / `--time-limit`). |
| `--differential-apply-c3` | Modifier for `--differential`: also apply C3 to the differential population. **Circularity note (self-documented in the flag):** King Wen is at the C3 ceiling by construction in that population, so complement-distance extremality there is a *tautology, not a finding*. |
| `--rule7` | Test the "Rule 7" candidates: filter by extremal complement distance and line autocorrelation (bounded by `--max-nodes` / `--time-limit`). |
| `--fingerprint` | Fingerprint analysis: free positions, edit distances, minimum-constraint set (bounded by `--max-nodes` / `--time-limit`). |
| `--reconstruct` | Reconstruct King Wen step by step, verifying uniqueness at each step. |

### Null model

| Flag | Description |
|---|---|
| `--null-debruijn` | Null-model comparison: test C1–C3 against sampled de Bruijn B(2,6) permutations (addresses the [CRITIQUE.md](CRITIQUE.md) structured-permutation gap; honors `--trials`/`--seed`). |

## P2 — DISTRIBUTIONAL PIPELINE

The P2 pipeline measures where King Wen sits in the joint distribution
of observables across an enumerated population. Its stage-1/2/3 entry
points (`--compute-stats`, `--marginals`, `--bivariate`,
`--joint-density`) are documented in
[SOLVE_C_CLI.md](SOLVE_C_CLI.md#--compute-stats-solvepy-only); see also
[DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md). The refined
**v2** analyses and the pipeline modifiers below have no other CLI home:

### Refined (v2) analyses

| Flag | Description |
|---|---|
| `--joint-density-v2 CHUNKS_DIR OUT_MD` | Joint density with an automatic variance filter and CV bandwidth selection; sampled by default (`--joint-density-exhaustive` for exact). Documented alongside `--joint-density` in [SOLVE_C_CLI.md](SOLVE_C_CLI.md#--joint-density-solvepy-only). |
| `--joint-density-bandwidth cv\|silverman` | v2 bandwidth method (default `cv`). |
| `--joint-density-exhaustive` | v2: stream every record through the fitted KDE (slow in pure Python; ~10× faster with `--native-solve-binary`). |
| `--stratified-by-position-2-pair CHUNKS_DIR OUT_MD` | v2: per-stratum (`position_2_pair`) recomputation of KW's percentile (sampled by default). |
| `--stratified-exhaustive` | v2: exhaustive per-stratum scoring (very slow at full canonical scale). |
| `--joint-permutation-test CHUNKS_DIR OUT_MD` | v2: per-dimension [Bonferroni](CITATIONS.md#bonferroni1936) + joint multi-test extremity table. |
| `--native-solve-binary PATH` | Path to a compiled `solve` binary that supports `--kde-score-stream`; enables fast native exhaustive scoring for the v2 exhaustive/stratified modes. |

### Pipeline modifiers

| Flag | Default | Applies to | Effect |
|---|---|---|---|
| `--compute-stats-workers N` | `cpu_count()` | `--compute-stats` | Worker-process count for the parquet stat pass. |
| `--compute-stats-chunk-size N` | 1,000,000 | `--compute-stats` | Records per parquet chunk. |
| `--compute-stats-max-records N` | (all) | `--compute-stats` | Cap total records processed (testing). |
| `--joint-density-samples-per-chunk N` | 30 | `--joint-density*`, `--stratified-*`, `--joint-permutation-test` | Samples drawn per chunk. |
| `--joint-density-bootstrap-n N` | 1000 | `--joint-density`, `--joint-density-v2` | Bootstrap resamples for the CI on KW's percentile. |

## P3 — SAT ENCODING

`solve.py` can emit a DIMACS CNF of the constraint system for external
`#SAT` model counting or SAT solving. (The witness-search / certificate
workflow lives in the sibling `sat.py`; see [SAT_CLI.md](SAT_CLI.md).)

| Flag | Description |
|---|---|
| `--sat-encode OUT_CNF` | Emit DIMACS CNF for C1+C2 over the King Wen sequence to `OUT_CNF`. |
| `--sat-c3 none\|pb\|adder` | Include C3 in the encoding as a pseudo-Boolean (`pb`) constraint (default `none`). `adder` is **deferred/superseded** — see the note below. |
| `--sat-c4` | Force C4 in its **oriented** form: position 0 = Qian (hexagram **63**), position 1 = Kun (0), per [SPECIFICATION.md](SPECIFICATION.md) §C4. *(Corrected 2026-08-01: previously pinned hexagram 0 first — Kun — the complement of the spec. Isomorphic under this encoder's C1∩C2 scope, and the certification path is `sat.py`, which has no `--sat-c4`, so no published result moved.)* |
| `--sat-c5` | C5 cardinality constraints — **deferred/superseded**; see the note below. |

**Deferred/superseded flags — `--sat-c3 adder` and `--sat-c5` (honest
status, operator decision 2026-07-10).** Neither encoder is built: both
flags emit a `status: deferred_superseded_by_pairslot_model` entry in the
JSON sidecar instead of clauses. They are not on any live path — C3 (Sinz
sequential counters) and C5 are **native in `sat.py`'s pair-slot model**,
which is the only certification-path model (see
[SAT_CLI.md](SAT_CLI.md)). This legacy position-hexagram `x[i][p]` encoder
gets those constraints only if a future **variable-pairing analysis** ever
needs an instance the pair-slot model cannot express (e.g. relaxing the
fixed pairing). Effort on record if that day comes: C5 is heavy (31
per-boundary distance-class indicator families, each boundary touching
64×64 (p,q) tuples, plus `exactly_k` cardinality); C3 needs a DIMACS
adder summing network (large, and likely not faster than the PB route).

## TR-8 — DOF-MATCHED KW-FITTING-PREDICATE SAMPLER

`--tr8-dof-sampler` is the instrument
[TR-8](../reports/TR8_REORDERING_REVISITED.md) names as the fix for its own
withdrawn dof-matched median
([CORRECTIONS.md](CORRECTIONS.md) CX-27): *"a `solve.py` sampler over the
≈16-clause KW-fitting predicate space, published with its seed and probe
count, reporting the median rarity with a CI."*

**Read this before running it.** These flags are an **instrument**, not a
result. A *recorded* run — one whose output may be cited anywhere — is gated
on a **frozen pre-registration** (`roae-private`
`PREREG_TR8_DOF_MATCHED_SAMPLER_*`), which fixes the clause bank, the
admission band, the K ladder, the sample sizes, the seed strings and the
decision rule **before** any data exists. Nothing this sampler produces
reinstates the withdrawn figure: that registration pre-commits that the
withdrawn number is either **replaced** by a new, artifact-backed measurement
or **stays withdrawn**. Runs made before the freeze (including the smoke run
in EXAMPLES below) are instrument tests and are not results.

**What it measures.** A *KW-fitting predicate of order K* is a conjunction of
K distinct clauses drawn without replacement from a bank of cheap structural
templates, each **instantiated at the value King Wen exhibits** — so King Wen
satisfies every drawn predicate by construction (sanity gate **H-a**). The
rarity of a predicate is its probability under the **pair-only (C1) null**
(TR-8 §2 null (b): a uniform permutation of the 32 traditional pairs into the
32 pair-slots with an independent fair orientation coin per pair), estimated
by direct sampling. The comparator is King Wen's own exact Schulz-gender
rarity over that same null, `pair_null_gender_le2_exact()` = 47/445740. The
sampler reports, per K, the **fraction of predicates at least as rare as King
Wen** (Clopper–Pearson 95% CI — the primary statistic, because it is immune to
censoring) and the **median rarity** (distribution-free order-statistic 95%
CI — the statistic CX-27 names).

**The clause bank.** Nine families, `B_raw` = 36 + 64 + 32 + 63 + 32 + 15 + 8
+ 64 + 5 = **319** instances: **A** gender label per inversion-class position,
**B** popcount parity per position, **C** within-pair Hamming distance per
slot, **D** seam-distance parity per seam, **E** within-slot orientation
relation, **F** sign of the running yang balance, **G** per-block yang mass,
**H** lower-trigram yang-majority class per position, **I** five global
statistics (shared-trigram adjacencies, `par_switch`, lag-1 distance
autocorrelation, five-line transitions, distinct within-pair XOR products). No
template names a hexagram's *identity* at a position. Each instance is
**admitted** only if its measured marginal under the null lies in the band
**[0.25, 0.75]**; the band is stated without reference to King Wen's rarity,
deliberately. Templates outside the band are dropped, and the drop is data —
family **E** is admitted in **zero** instances because both readings of "the
ordered popcount relation, ties exempt" are degenerate under this null (the 28
reversal pairs have equal popcounts by construction), and the
distinct-within-pair-XOR clause is constant for the same reason. `B_admitted`
is therefore a **measured** quantity of each calibration draw, not a constant.

| Flag | Description |
|---|---|
| `--tr8-dof-sampler OUT_DIR` | Run the sampler; write `header.json`, `env.json`, `bank.json`, `results.json` and `RESULTS.md` to `OUT_DIR` (terminal command). |
| `--tr8-dof-emit-bank` | Measure and print the admitted clause bank with its marginals, then exit — the pre-registration's bank-freeze step. Combine with `--tr8-dof-sampler OUT_DIR` to also write `bank.json` there (the bank is emitted and the pool is **not** run). |
| `--tr8-dof-merge OUT_DIR` | Merge the per-shard hit files in `OUT_DIR` and compute the statistics (terminal command). Refuses to merge a partial pool or shards whose run headers disagree. |
| `--tr8-dof-selftest` | Run the instrument self-tests — bank integrity, H-a, the H-b null calibration, determinism, and shard/merge equivalence — then exit. Exit 0 = all passed. These are also standing regressions in `tests.py`. |
| `--tr8-dof-seed ROOT` | Seed **root** string. Every seed is `uint64(sha256("ROOT/<purpose>")[:8], big-endian)` over the purposes `bank-calibration`, `pool-<A\|B>/shard-<i>`, `predicates/K-<K>`, `timing-probe`. Echoed verbatim in `header.json` together with every derived seed as a decimal integer. Default: the pre-registration namespace. |
| `--tr8-dof-pool A\|B\|calib` | Which seed family the pool draws from (default `A`). The registration's pool-B replication gate re-runs the identical measurement on `B`. |
| `--tr8-dof-pool-draws N` | `N_pool` — total pair-only-null draws, the **probe count** (default 10000000). Split equally across the shards. |
| `--tr8-dof-predicates N` | `N_pred` — predicates drawn per K (default 1000). |
| `--tr8-dof-k LIST` | Comma-separated K ladder (default `8,12,16,20,24`). The headline verdict is read at K = 16; the ladder ships because K = 16 is inherited from TR-8's own "≈16 clauses" and has no derivation anywhere. |
| `--tr8-dof-shards N` | Number of equal-size pool shards (default 8). `N_pool` must be divisible by it. |
| `--tr8-dof-shard I` | Run **only** shard `I` and write its per-predicate hit file for a later `--tr8-dof-merge`. Hits are additive across shards because every shard scores the identical predicate ensemble, so a merged run equals the single-process run exactly (asserted by `--tr8-dof-selftest`). Default: run every shard in this process. |
| `--tr8-dof-calib-draws N` | Draws in the dedicated bank-calibration pool, which has its own seed and is never merged into a measurement pool (default 100000). |

**Output.** `header.json` is **deterministic** — the seed root, every derived
seed, `N_pool`, `N_pred`, the K ladder, the admission band, `B_raw`,
`B_admitted`, the admitted-bank sha256 and the `solve.py` sha256 — so
"same seed root ⇒ byte-identical header" is a testable property. Wall time,
host and interpreter version live in `env.json` for exactly that reason.
`RESULTS.md` restates the seed and probe count at the top, because that is
what TR-8 requires published alongside the number.

**Sanity gates, both blocking.** **H-a**: King Wen must satisfy every raw
template; a single failure is an implementation finding, not a result, and the
run aborts. **H-b**: the pool's own rate of `rc4_violations(seq)[0] <= 2`,
scored by the **unmodified** `rc4_violations`, must reproduce
`pair_null_gender_le2_exact()` within a 5σ Poisson band — this is the evidence
that the pool is the same null the comparator was computed over. H-b failure
forces the verdict to `INCONCLUSIVE`.

**Cost.** Measured on the 2-core orchestrator, 2026-08-11: ~10,000 draws/s per
core for the full per-draw scoring path (draw + 319 templates + the H-b
`rc4_violations` pass). `--tr8-dof-selftest` runs in ~6 s. Memory scales as
`B_admitted` × `N_pool` / 8 bytes for the bit-column layout, so the default
`N_pool` = 10⁷ needs a few hundred MB and **must not** be run on the 2-core /
8 GB orchestrator. A timing probe is a short run into a throwaway `OUT_DIR`
with a small `--tr8-dof-pool-draws`; its output is **timing evidence only** and
is never merged into a measurement pool. The `timing-probe` seed is derived and
recorded in `header.json` so that the probe is pinned even though it produces
no statistic.

## BRANCH-YIELD REPORTING

`--branch-yield-report` reads a `solutions.bin` and reports the yield
(record count) per partition-prefix — useful for analyzing asymmetric
milestone extensions where some sub-branches were walked at a higher
per-sub-branch budget. (Design notes: `roae-private` BRANCH_YIELD_REPORT_DESIGN.md.)

| Flag | Description |
|---|---|
| `--branch-yield-report SOLUTIONS_BIN` | Per-partition-prefix yield count from `SOLUTIONS_BIN` (terminal command). |
| `--branch-yield-baseline BASELINE_BIN` | Diff the yields against this baseline `solutions.bin`. |
| `--branch-yield-manifest MANIFEST_JSON` | Annotate with a `manifest.json` per-sub-branch budget map. |
| `--branch-yield-depth 1\|2\|3` | Granularity: 1 = first-level (default), 2 = depth-2, 3 = depth-3. |
| `--branch-yield-csv OUT_CSV` | Also write the report as CSV. |
| `--branch-yield-json OUT_JSON` | Also write the report as JSON. |

## KEYSTONE ANALYSIS

`--keystone-analysis` is a counterfactual study of the `{1,4,21,25,27}`
minimum boundary set (see
[BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md)): it builds a per-record
5-bit match-mask histogram and does a drop-one analysis to identify the
specific record families each keystone boundary uniquely eliminates.

| Flag | Description |
|---|---|
| `--keystone-analysis SOLUTIONS_BIN OUT_MD` | Run the keystone counterfactual; write the Markdown report to `OUT_MD` (terminal command). |
| `--keystone-dump-dir DIR` | Optional output directory for record dumps from the interesting masks (drop-25, drop-27, all-5). |
| `--keystone-dump-limit N` | Cap on records dumped per interesting mask (default 10,000). |

## ANALYSIS MODIFIERS

```
--max-nodes N      Max nodes for backtracking enumeration (default 10,000,000)
                   — applies to --enumerate, --differential, --rule7, --fingerprint
--time-limit N     Time limit in seconds for enumeration (default 60)
                   — same four analyses
--trials N         Number of random samples (default 100,000)
                   — applies to --narrow and --null-debruijn
--seed N           Random seed for reproducible Monte Carlo results
                   — applies to --narrow and --null-debruijn
--verbose          Print progress during the search (--narrow)
```

## VERIFICATION & COMPANION COMMANDS

These commands run and exit; each is **already documented in full** in
[SOLVE_C_CLI.md](SOLVE_C_CLI.md) (they are the two-language ground-truth
gates and the P2 pipeline stage entry points). Listed here for
discovery — follow the link for the authoritative description:

| Command | One-liner | Reference |
|---|---|---|
| `--f4p-verify` | Verify the 13 pre-registered F4′ ordering-layer functionals on KW. | [SOLVE_C_CLI.md#--f4p-verify](SOLVE_C_CLI.md#--f4p-verify) |
| `--f6-verify` | Verify the 7 frozen F6 Nielsen-audit functionals ([Wu Deng](CITATIONS.md#wudeng) warp/weft + [Jing Fang](CITATIONS.md#jingfang) bagong) on KW. | [SOLVE_C_CLI.md#--f6-verify](SOLVE_C_CLI.md#--f6-verify) |
| `--dav-verify` | Verify the 9 pre-registered [Davis (2012)](CITATIONS.md#davis2012) composite candidates on KW. | [SOLVE_C_CLI.md#--dav-verify](SOLVE_C_CLI.md#--dav-verify) |
| `--dav2-verify` | Verify the 2 pre-registered [Davis (2012)](CITATIONS.md#davis2012) wave-2 candidates (`tquartet` C-D9, `xunslots` C-D10) on KW. | [SOLVE_C_CLI.md#--dav2-verify](SOLVE_C_CLI.md#--dav2-verify) |
| `--db1-verify` | Verify Drasny's "Rule of Ten" D-B1 classifier (== Table 4.1, all 64 hexagrams) and the KW conformity count (X=22) — the two-language SPEC gate for `solve.c --db1-verify`. | [SOLVE_C_CLI.md#--db1-verify](SOLVE_C_CLI.md#--db1-verify) |
| `--vdb-verify` | Verify the 8 [Van den Berghe](CITATIONS.md#vandenberghe1999) structural candidates on KW. | [SOLVE_C_CLI.md#--vdb-verify-solvepy-only](SOLVE_C_CLI.md#--vdb-verify-solvepy-only) |
| `--f5-verify` | The 11 frozen F5 orientation-layer functionals — a **`solve` C** gate; `solve.py`'s side of #11 (`f5_vdb_nuc`) is `--vdb-verify`'s `vdb_nucorient`. | [SOLVE_C_CLI.md#--f5-verify](SOLVE_C_CLI.md#--f5-verify) |
| `--books-verify` | Verify the machine-checkable structural claims from the audited books (Wu Deng via [Nielsen 2003](CITATIONS.md#nielsen2003), [Lai Zhide](CITATIONS.md#laizhide), [Goldenberg 1975](CITATIONS.md#goldenberg1975), Jing Fang, [Yu Fan](CITATIONS.md#yufan)) on KW. | [SOLVE_C_CLI.md#--books-verify-solvepy-only](SOLVE_C_CLI.md#--books-verify-solvepy-only) |
| `--symmetry-completeness` | TR-5 v2.0 completeness certificate: exhaustively verify (gates SC-1…SC-8, no sampling) that the order-48 symmetry group is complete over ALL 64! hexagram relabelings — ψ-isomorphism of the distance-5 graph to Q₆, hypercube two-common-neighbor rigidity, the explicit 46,080-element Aut(G₅), the fix-0 and partner-commuting filters, and the 1,824-sequence C2 witness family. Exit 0 iff certified. Companion SAT kernel: `sat.py --rigidity-cnf`. Sha-neutral. | [SYMMETRY_SEARCH.md §Completeness](SYMMETRY_SEARCH.md) |
| `--trigram-verify` | Two-language ground truth for [`lean/TrigramTheorems.lean`](../lean/TrigramTheorems.lean): independently re-compute every finite fact and every KW instance of its machine-checked trigram-level statements (18 claims, TG1-a … TG5-b). No `solve` C equivalent. Sha-neutral. Scope + attribution: [TRIGRAM_STRUCTURE.md](TRIGRAM_STRUCTURE.md). | [TRIGRAM_STRUCTURE.md](TRIGRAM_STRUCTURE.md) |
| `--registry-verify` | Run every `reg_*` candidate-rule ground-truth checker and assert each equals its registry KW-expected value. | [SOLVE_C_CLI.md#--registry-verify-solvepy-only](SOLVE_C_CLI.md#--registry-verify-solvepy-only) |
| `--perm-verify [SEQ]` | Two-language ground truth for the 13 FROZEN R3 permutation-cycle functionals (`perm_ncyc_bot` … `perm_desc_top`; KW = 7,33,1,1,1320,31,1,3,52,0,1,260,30) on KW — or on an explicit `"h0,...,h63"` hexagram-value sequence. Prints one `perm_<name>: <value> OK/FAIL` line each; exit 0 iff all 13 match. This is the authoritative ground truth for the C `SOLVE_KNUTH_SCORE_PERM` population scorer (no `solve` C subcommand equivalent; the C side is the env-var scorer). Observable axis anchor: [Ge 2026](CITATIONS.md#ge2026). Sha-neutral. | [SOLVE_C_CLI.md#environment](SOLVE_C_CLI.md#environment) (`SOLVE_KNUTH_SCORE_PERM`) |
| `--rc4b-verify [SEQ]` | Two-language ground truth for the R13 HEC two-convention parity predicates ([Schulz 1990](CITATIONS.md#schulz1990-motifs) gender/position-parity, elaborated [Cook 2006](CITATIONS.md#cook2006)): asserts the KW anchors — 2 violations at adjacent class positions [25, 26]; R-C4-A (published ≤2 relaxation), R-C4-B (exception form: 0 violations OR 2 adjacent), R-C4-C (exactly {25,26}) and the rc3/rc3w level-3 checks all pass. With a 64-int SEQ prints `viol,vp0,vp1,rc4a,rc4b,rc4c,rc3,rc3w`. Sha-neutral. | [SOLVE_C_CLI.md#--rc4b-verify](SOLVE_C_CLI.md#--rc4b-verify) |
| `--rc1c-verify [SEQ]` | Two-language ground truth for the R6 circular anchor-adjacency predicate (R-C1c): on KW the A2 anchor pair {21, 42} gives `slot2 = 0, slot32 = 1, adjacent = 1`. With a 64-int SEQ prints `slot2,slot32,adjacent` (ordering matches `solve.c --rc1c-verify SEQ`). Sha-neutral. | [SOLVE_C_CLI.md#--rc1c-verify](SOLVE_C_CLI.md#--rc1c-verify) |
| `--r11-verify [SEQ]` | Two-language ground truth for the R11 frozen 8-axis violation bundle (g1..g6 T1 + g7, g8 T2); KW expected vector `2,2,2,0,0,0,0,0`. No-arg mode additionally prints a `violation positions` line (parity pair-slots, rhythm adjacent-pairs, gender inversion-class positions) for the three graded rules — an analysis extra beyond the C twin, which emits counts only. With a 64-int SEQ prints just the 8 values (ordering matches `solve.c --r11-verify SEQ`; this machine-output mode is the two-language gate and is unchanged). Sha-neutral. | [SOLVE_C_CLI.md#--r11-verify](SOLVE_C_CLI.md#--r11-verify) |
| `--r11-builder-verify` | R11 structural smoke-test of the M_G greedy-builder machinery (KW-path softmax numerator, P_complete simulation, synthetic draw) — **not** the four-class Bayes verdict. `solve.py`-only (no `solve` C equivalent). Sha-neutral. | (this doc) |
| `--h2-verify DUMPFILE [N]` | H2 near-precursor instrument (a **private hypothesis** classified SEMI-FITTED — this command verifies the instrument, it promotes nothing): independently recompute `N` (default 2) randomly-selected GS leaves from a `solve.c` `SOLVE_KNUTH_H2=1` audit dump (`SOLVE_KNUTH_H2_DUMP=<path>`), re-deriving each leaf's exact radius-3 slot-edit-ball tallies (`nvp`, `nvc`, `fp`, `fc`) with `solve.py`'s own scorers (structurally distinct enumeration from `solve.c`'s) — counts must match exactly, masses to 1e-9 relative. Also asserts fixed KW / grand-witness ground-truth gates before touching the dump (KW strict-axes (2,2,2), C3 x64 total 776, population membership; the TR-2 grand witness valid, triple-strict, C3 776, slot-distance 3 from KW). Leaf selection is seeded (20260726) and deterministic. Exit 0 iff all gates and leaves PASS. `solve.py`-only (the C side is the env-var-driven Knuth scorer). Sha-neutral. | (this doc) |
| `--h2-mass DUMP [DUMP ...]` | H2 near-precursor instrument, final pooled estimate: one `SOLVE_KNUTH_H2` dump per independent-seed run. Computes the self-normalized importance ratio E[f] = ΣW·f / ΣW pooled across runs, a stratified bootstrap 95% CI (B = 20,000; leaves resampled within runs), per-run seed spread, and folds the N_gs measurement uncertainty in quadrature (lognormal); prints the mass `m` and `bits = -log2(m)` for both denominators (flagship C1∩C2∩C4∩C5, exact; canonical C1–C5, estimate). Aborts (exit 1) on an empty dump or any leaf that failed its in-dump brute cross-check; exit 0 otherwise. **Magnitude only** — H2 remains a private SEMI-FITTED hypothesis (C3/C5-class, MDL-net-negative); no promotion, no spec change, no sha touched. | (this doc) |
| `--r7-verify` | R7 cross-tradition corpus-control: assert the frozen anchors deterministically — FC-2 construction cross-validation (roae.py Mawangdui == solve.c `--null-historical`; each ordering a permutation of 0..63); the Jing Fang family J1–J5 reproduces its tradition; the Mawangdui family M1–M5 + the exact M1∧M3∧M4 reconstruction of the corrected silk-text array; the two diff-wave signatures ({1:48,3:15} / {1:21,2:10,3:29,4:2,5:1}); the cross-application matrix a-priori/theorem cells; the FC-1 positive-control expectation at the pilot N=10⁴ (Jing Fang & Mawangdui ≥8/11 EXTREME, KW extremes == {a,b,f}); and the Amendment-1 (2026-07-12) corrected FC-4 anchor counts over the exact J1 space (comp-sum-1024 attainers 9,216/40,320 ≈ 22.86%, mid-percentile 88.57; P(J4\|J1) numerator 384; P(J2∧J3\|J1) numerator 1 — counts-only fast path). No N=10⁶ measurement. Sha-neutral. Frozen design: `roae-private/R7_CORPUS_CONTROL_DESIGN_FROZEN_2026_07_11.md` + its Amendment 1. | [SOLVE_C_CLI.md#--r7-verify-solvepy-only](SOLVE_C_CLI.md#--r7-verify-solvepy-only) |
| `--r7-corpus [--r7-n N] [--r7-seed S]` | R7 battery (the operator-gated measurement): each historical ordering's own constraint family in its own representation (KW C1–C5; Jing Fang J1–J5, palace-orbit repn; Mawangdui M1–M5, trigram-octet repn; Fu Xi B1, identity) vs matched nulls. Emits the L0 uniform-null scoreboard (11 F8 observables × 4 orderings, plus the P(comp-sum=1024\|L0) rate, the TG-3 S₃-relabel-invariance note on the c1/c2 columns, and the §7 pilot-vs-rerun EXTREME-boundary halt-rule diff), the KW pair-preserving second null, the cross-application matrix (the manufacture alarm), the Jing Fang L1 **exact** 8!=40,320 null (full 11-observable battery + P(J1\|L0) analytic, P(J2∧J3\|J1), P(J4\|J1), and the Amendment-1-corrected comp-sum anchor), the Mawangdui L1 sampled ladder ×2 (full 11-observable battery + exact P(M4\|M1)=1/8! with sampled cross-check), the Mawangdui L2 null (M1∧M3-conditioned, both conventions free; sampled per the frozen <2 h exact-grid-else-sampled decision rule, deviation logged), the MDL pricing row, and the FC-1..FC-4 verdicts (FC-4 per the corrected Amendment-1 anchor) — markdown to stdout, report-only. **Heavy** at the frozen defaults (N=10⁶, seed 42): run on a Spot D4/D8 worker, NOT the orchestrator. `--r7-n`/`--r7-seed` override only for smoke tests. Sha-neutral. | [SOLVE_C_CLI.md#--r7-corpus-solvepy-only](SOLVE_C_CLI.md#--r7-corpus-solvepy-only) |
| `--extended-selftest SOLVE_BINARY` | Small-scale path-invariance + resume regression suite against a compiled `solve` binary (CI gate; wall ~10 min). | [SOLVE_C_CLI.md#--extended-selftest-solvepy-not-a-solve-c-subcommand](SOLVE_C_CLI.md#--extended-selftest-solvepy-not-a-solve-c-subcommand) |
| `--compare-depth-profile RUN_A_LOG RUN_B_LOG` | Tree-walk validator (#48): compare `DEPTH_PROFILE` node counts from two run logs; PASS if divergence < `--compare-depth-profile-threshold` (default 0.005). | [SOLVE_C_CLI.md#--compare-depth-profile-solvepy-only](SOLVE_C_CLI.md#--compare-depth-profile-solvepy-only) |
| `--compute-stats SOLUTIONS_BIN OUT_DIR` | P2 stage 1: stream `solutions.bin`, emit per-chunk parquet stats. | [SOLVE_C_CLI.md#--compute-stats-solvepy-only](SOLVE_C_CLI.md#--compute-stats-solvepy-only) |
| `--marginals CHUNKS_DIR OUT_MD` | P2 stage 2: per-dimension marginal percentiles with KW marked. | [SOLVE_C_CLI.md#--marginals-solvepy-only](SOLVE_C_CLI.md#--marginals-solvepy-only) |
| `--bivariate CHUNKS_DIR OUT_DIR` | P2 stage 2: hexbin heatmaps for 5 observable pairs with KW marked. | [SOLVE_C_CLI.md#--bivariate-solvepy-only](SOLVE_C_CLI.md#--bivariate-solvepy-only) |
| `--joint-density CHUNKS_DIR OUT_MD` | P2 stage 3: KDE joint density over the 7 informative dims + bootstrap CI on KW's percentile. | [SOLVE_C_CLI.md#--joint-density-solvepy-only](SOLVE_C_CLI.md#--joint-density-solvepy-only) |

## DEFAULT BEHAVIOR

With no analysis flag, `solve.py` runs `--rules` + `--narrow`. Passing
any one of the descriptive analysis flags overrides that default and
runs only what you asked for (aggregates `--local` / `--deep` expand as
above). The verifier, P2/P3, branch-yield, and keystone commands are
terminal and take precedence.

## EXIT STATUS

| Code | Meaning |
|---|---|
| 0 | Success (or, for a verifier, all checks PASS). |
| 1 | A verifier reported at least one mismatch (`--f4p-verify`, `--f6-verify`, `--dav-verify`, `--dav2-verify`, `--db1-verify`, `--vdb-verify`, `--perm-verify`, `--rc4b-verify`, `--rc1c-verify`, `--r11-verify`, `--r11-builder-verify`, `--r7-verify`, `--books-verify`, `--trigram-verify`, `--registry-verify`, `--extended-selftest`, `--h2-verify`, `--h2-mass`), or an invalid argument. |

The descriptive analyses print to stdout and exit 0; they do not encode
findings in the exit status.

## EXAMPLES

**Default run (recipe + constraint narrowing):**

```
python3 solve.py
```

**Reproducible constraint narrowing:**

```
python3 solve.py --narrow --trials 1000000 --seed 42
```

**All the deep analyses at once:**

```
python3 solve.py --deep
```

**Bounded backtracking enumeration:**

```
python3 solve.py --enumerate --max-nodes 50000000 --time-limit 120
```

**P2 pipeline end-to-end (from a `solve.c` solutions.bin):**

```
python3 solve.py --compute-stats solutions.bin chunks/ --compute-stats-workers 32
python3 solve.py --marginals chunks/ marginals.md
python3 solve.py --joint-density-v2 chunks/ joint.md --joint-density-bandwidth cv
```

**Emit a CNF with C3 as a pseudo-Boolean constraint:**

```
python3 solve.py --sat-encode kw.cnf --sat-c3 pb --sat-c4
```

**Per-branch yield diff against a baseline, with CSV out:**

```
python3 solve.py --branch-yield-report solutions.bin \
    --branch-yield-baseline baseline.bin --branch-yield-depth 2 \
    --branch-yield-csv yields.csv
```

**Ground-truth gate before shipping a `solve.c` port change:**

```
python3 solve.py --f6-verify && python3 solve.py --registry-verify
```

**TR-8 sampler — instrument check, then a smoke run that is NOT a result:**

```
python3 solve.py --tr8-dof-selftest
python3 solve.py --tr8-dof-sampler /tmp/tr8smoke \
    --tr8-dof-seed SMOKE-THROWAWAY-DO-NOT-CITE \
    --tr8-dof-pool-draws 200000 --tr8-dof-predicates 200 \
    --tr8-dof-k 8,12,16 --tr8-dof-shards 4 --tr8-dof-calib-draws 20000
```

The explicit throwaway seed root is the point: it marks the output as an
instrument test rather than a measurement. A recorded run uses the frozen
pre-registration's seed root and its frozen `N_pool` / `N_pred`, and does not
happen before that registration is frozen.

**TR-8 sampler — sharded across cores, then merged:**

```
for i in 0 1 2 3 4 5 6 7; do
  python3 solve.py --tr8-dof-sampler out/ --tr8-dof-shard $i &
done; wait
python3 solve.py --tr8-dof-merge out/
```

## FILES

**Reads:**

- Hexagram data and the King Wen ordering are hard-coded in `solve.py`
  (shared ground truth). The P2, branch-yield, and keystone commands
  additionally read a `solve.c`-produced `solutions.bin` (or its
  per-chunk parquet directory).

**Writes (only for the pipeline / report commands):**

- Parquet chunks (`--compute-stats`), Markdown reports (`--marginals`,
  `--joint-density*`, `--stratified-*`, `--joint-permutation-test`,
  `--keystone-analysis`), heatmap images (`--bivariate`), DIMACS CNF
  (`--sat-encode`), CSV/JSON (`--branch-yield-*`), and optional record
  dumps (`--keystone-dump-dir`).

## SCIENTIFIC SCOPE — the three CLIs

| | `roae.py` | `solve.py` | `solve` (C, from `solve.c`) |
|---|---|---|---|
| **Role** | KW as a fixed sequence (28 descriptive analyses) | Constraint-structure analyses, ground truth, P2/P3 pipelines | Canonical enumeration of the C1–C5 space |
| **Reference** | [ROAE_PY_CLI.md](ROAE_PY_CLI.md) | this doc | [SOLVE_C_CLI.md](SOLVE_C_CLI.md) |
| **Scale** | single sequence | single sequence + population post-processing | up to 560T-node canonical runs |
| **Deps** | Python 3 stdlib (+ optional export deps) | Python 3 (+ pandas/pyarrow/scipy for P2) | gcc, pthread, sha256sum |

`solve.py` is the **ground-truth authority**: every `solve.c` port of a
functional (F4′, F5, F6, the registry rules, the Davis / Van den Berghe
candidates) is gated two-language against the matching `solve.py`
verifier, and `sat.py` imports `solve.py` rather than re-encoding any
constraint (see [SAT_CLI.md](SAT_CLI.md)).

## SEE ALSO

- [SOLVE_C_CLI.md](SOLVE_C_CLI.md) — `solve` (C) enumerator/verifier reference (also documents the verify + P2 commands in full)
- [ROAE_PY_CLI.md](ROAE_PY_CLI.md) — `roae.py` descriptive-analysis reference
- [SAT_CLI.md](SAT_CLI.md) — `sat.py` SAT/certificate-layer reference
- [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md) — the P2 distributional results and interpretation
- [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md) — the minimum boundary set behind `--keystone-analysis`
- [SPECIFICATION.md](SPECIFICATION.md) — formal C1–C5 definitions
- [CRITIQUE.md](CRITIQUE.md) — methodological caveats (incl. the null-model gap `--null-debruijn` addresses)
