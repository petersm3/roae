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

# TR-12 atlas consumer (over a `solve --kc-scan` atlas JSON)
python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR [--atlas-select LIST]
                 [--atlas-q3-trace TRACE.txt] [--atlas-verdicts FILE]
                 [--xa-nodes-per-sec F --xa-usd-per-hour F --xa-budget-usd F]
python3 solve.py --atlas-selftest ATLAS.json --atlas-walks WALKS.txt [--atlas-q3-trace TRACE.txt]

# Branch-yield + keystone reporting
python3 solve.py --branch-yield-report SOLUTIONS_BIN [--branch-yield-depth 1|2|3] ...
python3 solve.py --keystone-analysis SOLUTIONS_BIN OUT_MD

# Ground-truth verifiers (details in SOLVE_C_CLI.md)
python3 solve.py --f4p-verify | --f6-verify | --dav-verify | --vdb-verify | --perm-verify [SEQ]
python3 solve.py --rc4b-verify [SEQ]
python3 solve.py --books-verify | --trigram-verify | --registry-verify | --extended-selftest SOLVE_BINARY
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
| `--sat-c4` | Force position 0 = hexagram 0 (the Qian/Kun orientation convention). |
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

## TR-12 ATLAS CONSUMER

`solve --kc-scan` writes an atlas JSON (`"type": "roae-kc-scan-atlas"`) —
one streaming join of the f- and g-ladders, emitted once at the end of the
pass. These two commands are its **only** consumer: they re-shape it into
the tab-separated evidence tables the TR-12 queries and the V-family
figures read, and they gate every table they write.

```
--atlas-queries ATLAS_JSON   Read the atlas; write the query/figure TSVs.
--atlas-out DIR              Output root (default: the atlas's own directory).
--atlas-select LIST          Comma list of q3,q6,v1,v2,v5,xa,q10a (default: all).
--atlas-q3-trace FILE        The Q3 source. EITHER `solve --kc-o3-rank F G WALK
                             --kc-trace` text OR a `solve --kc-profile F G WALK
                             --kc-tsv FILE` table (auto-detected). Supplies Q3/V4
                             and Q6's per-layer percentile column.
--atlas-verdicts FILE        KEY=value verdict file (default <out>/VERDICTS.txt).
--atlas-selftest ATLAS_JSON  Reduced-n (n <= 13) brute-force gate over the whole
                             consumer; prints ATLAS_CONSUMER=PASS|FAIL|SKIP:<reason>.
--atlas-walks FILE           --atlas-selftest: the explicit enumeration
                             (`solve --kc-enum FDIR`, one walk per line) the gate
                             recounts against. Without it the verdict is
                             SKIP:no-brute-force-walks — never PASS.
--atlas-keep DIR             --atlas-selftest: keep the emitted tables in DIR.
--atlas-fault NAME           TEST ONLY. Deliberately corrupt one emitted column so
                             the gate can be shown able to fail. One of
                             v1-drop-pair, v2-class-swap, xa-drop-branch,
                             q3-perturb, q10-mod24. Never on a real run.
--xa-nodes-per-sec F         XA-c/d: measured DFS throughput anchor.
--xa-usd-per-hour F          XA-c/d: worker price anchor.
--xa-budget-usd F            XA-c/d: the ceiling the EXHAUSTIBLE/INFEASIBLE call
                             is made against.
--xa-hedge F                 XA-c/d: throughput hedge for scale (default 2.0).
--xa-work-factor F           XA-c/d: engine work factor to divide the rate by
                             (default 1.0 = none).
--xa-anchor-note TEXT        XA-c/d: provenance string echoed into xa_verdict.md.
```

### What it writes

| File | Feeds | Content |
|---|---|---|
| `<out>/scan/v1_field.tsv` | **V1**, Q6 | `k slot pair mass p kw` — the positional-marginal field, RAW frame (requires an atlas built with `--kc-raw`; a quotient-only atlas is refused, not plotted). |
| `<out>/scan/v2_river.tsv` | **V2** | `k d mass p kw_d` — per-layer boundary-distance class mass. |
| `<out>/scan/v2_branches.tsv` | **V2** panel (b) | `branch pair entry exit d solutions share prefixes_t_units t_source kw`. |
| `<out>/scan/v5_grammar.tsv` | **V5** | `k d w mass p_cond kw_d kw_w` — `w = -1` where the (distance × within-pair) cross-tab is not emitted by the scan. |
| `<out>/scan/q6_layer_mass.tsv` | **Q6** | `k slot d mass p is_argmax is_argmin_nonzero`. |
| `<out>/scan/q6_layer_extremes.tsv` | **Q6** | per-layer argmax / argmin-nonzero, their ratio, and King Wen's own class + percentile (the last two only with `--atlas-q3-trace`). |
| `<out>/q3_profile_kw.tsv` (`q3_profile.tsv` at n ≠ 31) | **Q3**, **V4**, EW-1 | `step pair entry exit orient alts mass_below f g g_parent p_num p_den p bits`, plus `dclass g_alt_min g_alt_max choice_rank` when the source was `--kc-profile --kc-tsv` (those four are V4's optional alternatives band). `mass_below` is an O3-rank quantity: it reads `-1`, not a guess, when the source was `--kc-profile`. |
| `<out>/q10_orbit_census.tsv` | **Q10(a)**, XA-24 | `scope k flow orbits mod24_ok`. |
| `<out>/xa_branches.tsv` | **XA-a/b** | the branch table plus the `walks` column. |
| `<out>/xa_verdict.md` | **XA-c/d**, XA-24 | the gate table, the branch extremes, and the exhaustibility call. |
| `<out>/VERDICTS.txt` | the harness | one `KEY=value` line per row; an existing key is replaced, not duplicated. |

Verdict tokens emitted: `TR12_Q3`, `TR12_Q3_READER`, `TR12_Q6`, `TR12_V1`,
`TR12_V2`, `TR12_V5`, `TR12_XA_A`, `TR12_XA_B`, `TR12_XA_CD`,
`TR12_XA_MOD24`, `TR12_Q10A` — matched with `grep -qx`, never by output
shape. `TR12_Q3_READER` is deliberately separate from `TR12_Q3`: the
engine's trace asserts `Π p_i = 1/N` itself, and this consumer recomputes
that product independently in exact big-integer rationals from the written
TSV. The engine does not grade its own homework.

### Precision contract

Every count in the atlas is a **decimal string** carrying up to a 192-bit
value. They are parsed with `int()` and only with `int()`; a JSON float
literal anywhere in the atlas is refused with a diagnostic rather than
rounded, and the `mass` columns are written from the exact integer. The
`p` / `p_cond` / `share` columns are correctly-rounded renderings of an
exact `Fraction` and are **display only** — never the quoted value.

### What it will not do

- **It will not invent the XA cost anchors.** Without
  `--xa-nodes-per-sec`, `--xa-usd-per-hour` and `--xa-budget-usd` the
  exhaustibility section of `xa_verdict.md` reads PENDING and the token is
  `TR12_XA_CD=PENDING:xa-throughput-anchors`. The exact t-unit column
  stands on its own.
- **It will not re-derive the t-unit accounting convention.** A t-unit is
  one valid oriented prefix (the empty prefix counts; dead ends count);
  that convention is certified exhaustively at n=9 by `solve --kc-t-cert`
  (TR-12 XA(iii)) and is cited, not re-claimed, here.
- **It will not publish the mod-24 gate outside its scope.** The order-24
  action is free on solutions, so `N_total` and every per-layer flow are
  divisible by 24; per-branch and per-pair counts are **not** expected to
  be and are not gated.
- **It will not pass its own gate without a brute-force recount.**

### The n=9 gate

```bash
B=$(mktemp -d); gcc -O2 -pthread -fopenmp -o $B/solve solve.c -lm -lz
mkdir -p $B/f $B/g $B/t
$B/solve --kc-build   $B/f --f1-pairs 9
$B/solve --kc-g-build $B/g --f1-pairs 9
$B/solve --kc-t-build $B/f $B/t
$B/solve --kc-scan    $B/f $B/g $B/atlas.json --kc-tdir $B/t
$B/solve --kc-enum    $B/f | grep -v '^\[' > $B/walks.txt        # 26,112 walks
python3 solve.py --atlas-selftest $B/atlas.json --atlas-walks $B/walks.txt
# ... 21 gates (23 with --atlas-q3-trace); expect: ATLAS_CONSUMER=PASS
```

Every emitted table is re-derived from that **explicit enumeration** and
diffed cell by cell against the TSV read back off disk — not against the
in-memory atlas. Adding `--atlas-fault v2-class-swap` (or any of the other
four faults) makes the gate print `ATLAS_CONSUMER=FAIL` and exit 1; the
class-swap fault is caught **only** by the brute-force leg, which is the
point of having one.

### Rendering the figures

`viz/report_figures.py` turns these TSVs into V1–V5
(`fig_tr12_kc_field`, `_river`, `_spectrum`, `_shells`, `_grammar`):

```bash
cd reports/figures/ && python3 ../../viz/report_figures.py /path/to/tr12
```

TSV in, figure out — no analysis logic lives in `viz/`. Each figure is
skipped with a message if its TSV is absent. V3 does not ride the atlas
(it comes from a rank grid joined to the `--compute-stats` battery; see
[../viz/viz_kc_spectrum.md](../viz/viz_kc_spectrum.md)).

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
| `--vdb-verify` | Verify the 8 [Van den Berghe](CITATIONS.md#vandenberghe1999) structural candidates on KW. | [SOLVE_C_CLI.md#--vdb-verify-solvepy-only](SOLVE_C_CLI.md#--vdb-verify-solvepy-only) |
| `--f5-verify` | The 11 frozen F5 orientation-layer functionals — a **`solve` C** gate; `solve.py`'s side of #11 (`f5_vdb_nuc`) is `--vdb-verify`'s `vdb_nucorient`. | [SOLVE_C_CLI.md#--f5-verify](SOLVE_C_CLI.md#--f5-verify) |
| `--books-verify` | Verify the machine-checkable structural claims from the audited books (Wu Deng via [Nielsen 2003](CITATIONS.md#nielsen2003), [Lai Zhide](CITATIONS.md#laizhide), [Goldenberg 1975](CITATIONS.md#goldenberg1975), Jing Fang, [Yu Fan](CITATIONS.md#yufan)) on KW. | [SOLVE_C_CLI.md#--books-verify-solvepy-only](SOLVE_C_CLI.md#--books-verify-solvepy-only) |
| `--trigram-verify` | Two-language ground truth for [`lean/TrigramTheorems.lean`](../lean/TrigramTheorems.lean): independently re-compute every finite fact and every KW instance of its machine-checked trigram-level statements (18 claims, TG1-a … TG5-b). No `solve` C equivalent. Sha-neutral. Scope + attribution: [TRIGRAM_STRUCTURE.md](TRIGRAM_STRUCTURE.md). | [TRIGRAM_STRUCTURE.md](TRIGRAM_STRUCTURE.md) |
| `--registry-verify` | Run every `reg_*` candidate-rule ground-truth checker and assert each equals its registry KW-expected value. | [SOLVE_C_CLI.md#--registry-verify-solvepy-only](SOLVE_C_CLI.md#--registry-verify-solvepy-only) |
| `--perm-verify [SEQ]` | Two-language ground truth for the 13 FROZEN R3 permutation-cycle functionals (`perm_ncyc_bot` … `perm_desc_top`; KW = 7,33,1,1,1320,31,1,3,52,0,1,260,30) on KW — or on an explicit `"h0,...,h63"` hexagram-value sequence. Prints one `perm_<name>: <value> OK/FAIL` line each; exit 0 iff all 13 match. This is the authoritative ground truth for the C `SOLVE_KNUTH_SCORE_PERM` population scorer (no `solve` C subcommand equivalent; the C side is the env-var scorer). Observable axis anchor: [Ge 2026](CITATIONS.md#ge2026). Sha-neutral. | [SOLVE_C_CLI.md#environment](SOLVE_C_CLI.md#environment) (`SOLVE_KNUTH_SCORE_PERM`) |
| `--rc4b-verify [SEQ]` | Two-language ground truth for the R13 HEC two-convention parity predicates ([Schulz 1990](CITATIONS.md#schulz1990-motifs) gender/position-parity, elaborated [Cook 2006](CITATIONS.md#cook2006)): asserts the KW anchors — 2 violations at adjacent class positions [25, 26]; R-C4-A (published ≤2 relaxation), R-C4-B (exception form: 0 violations OR 2 adjacent), R-C4-C (exactly {25,26}) and the rc3/rc3w level-3 checks all pass. With a 64-int SEQ prints `viol,vp0,vp1,rc4a,rc4b,rc4c,rc3,rc3w`. Sha-neutral. | [SOLVE_C_CLI.md#--rc4b-verify](SOLVE_C_CLI.md#--rc4b-verify) |
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
| 2 | `--atlas-queries` refused the input (not an atlas, a float where a count belongs, no RAW marginals, an unknown `--atlas-select` value). |
| 1 | A verifier reported at least one mismatch (`--f4p-verify`, `--f6-verify`, `--dav-verify`, `--vdb-verify`, `--perm-verify`, `--rc4b-verify`, `--r7-verify`, `--books-verify`, `--trigram-verify`, `--registry-verify`, `--extended-selftest`), or an invalid argument; or
`--atlas-selftest` did not reach `ATLAS_CONSUMER=PASS`. |

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

## Two-language verifier flags — restored from `origin/main`, 2026-08-26

GATE 2 reported these five present in `solve.py` and absent from this document. **All five are
documented on `origin/main`**, so this is branch staleness, not a missing description — the rows
below are lifted **verbatim from main** rather than re-derived. Re-deriving an upstream description
would produce a second wording that has to be reconciled at merge, which is the mistake already made
once with `.gitignore` and deliberately not repeated.

```
python3 solve.py --f4p-verify | --f6-verify | --dav-verify | --dav2-verify | --db1-verify | --vdb-verify | --perm-verify [SEQ]
python3 solve.py --rc4b-verify [SEQ] | --rc1c-verify [SEQ] | --r11-verify [SEQ] | --r11-builder-verify
```

| flag | description |
|---|---|
| `--dav2-verify` | Verify the 2 pre-registered [Davis (2012)](CITATIONS.md#davis2012) wave-2 candidates (`tquartet` C-D9, `xunslots` C-D10) on KW. | [SOLVE_C_CLI.md#--dav2-verify](SOLVE_C_CLI.md#--dav2-verify) |
| `--db1-verify` | Verify Drasny's "Rule of Ten" D-B1 classifier (== Table 4.1, all 64 hexagrams) and the KW conformity count (X=22) — the two-language SPEC gate for `solve.c --db1-verify`. | [SOLVE_C_CLI.md#--db1-verify](SOLVE_C_CLI.md#--db1-verify) |
| `--r11-builder-verify` | R11 structural smoke-test of the M_G greedy-builder machinery (KW-path softmax numerator, P_complete simulation, synthetic draw) — **not** the four-class Bayes verdict. `solve.py`-only (no `solve` C equivalent). Sha-neutral. | (this doc) |
| `--r11-verify [SEQ]` | Two-language ground truth for the R11 frozen 8-axis violation bundle (g1..g6 T1 + g7, g8 T2); KW expected vector `2,2,2,0,0,0,0,0`. No-arg mode additionally prints a `violation positions` line (parity pair-slots, rhythm adjacent-pairs, gender inversion-class positions) for the three graded rules — an analysis extra beyond the C twin, which emits counts only. With a 64-int SEQ prints just the 8 values (ordering matches `solve.c --r11-verify SEQ`; this machine-output mode is the two-language gate and is unchanged). Sha-neutral. | [SOLVE_C_CLI.md#--r11-verify](SOLVE_C_CLI.md#--r11-verify) |
| `--rc1c-verify [SEQ]` | Two-language ground truth for the R6 circular anchor-adjacency predicate (R-C1c): on KW the A2 anchor pair {21, 42} gives `slot2 = 0, slot32 = 1, adjacent = 1`. With a 64-int SEQ prints `slot2,slot32,adjacent` (ordering matches `solve.c --rc1c-verify SEQ`). Sha-neutral. | [SOLVE_C_CLI.md#--rc1c-verify](SOLVE_C_CLI.md#--rc1c-verify) |
