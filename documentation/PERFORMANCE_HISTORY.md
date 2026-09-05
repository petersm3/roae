# Performance history — solve.c

Empirical log of every perf-relevant change to `solve.c`: improvements AND regressions, with hypothesis, methodology, paired-bench numbers, sha gate, and ship decision. The narrative for the project's "how did solve.c get from v1 to where it is today" presentation lives here.

This log is **append-only**. Older entries are not rewritten to make them correct when later understanding
contradicts the original interpretation — re-evaluations append a new entry referencing the older one, and the
superseded passage carries a dated `⚠ Correction` marker pointing at it. Those markers, this header, and the
occasional relabelling of a figure whose own table contradicts it are the only in-place edits the contract
permits; every one of them is dated and states what it changed and why, so the original reading stays
recoverable. A silent edit is a contract violation.

Entries are **approximately, not strictly, chronological**. They are ordered by when they were written, and one
entry is knowingly out of date order: `2026-05-16 — task #68` sits ahead of `2026-05-11 — task #70` because #68
opens the v2 prune ladder that #70 refines. Read the date in each header, not the file position.

> **Access boundary.** Entries cite per-change writeups, bench scripts, and raw bench data in
> `roae-private`, the project's private staging repository, which is not publicly accessible. Those
> citations are provenance pointers, not evidence a reader can fetch: a perf figure whose only cited
> support is a `roae-private` file is operator-attested (disclosable to an auditor, not checkable
> from this repository alone). The sha gates named in entries are the public leg — they are
> reproducible from this repository per [CANONICAL_HASHES.md](CANONICAL_HASHES.md).

## Why this exists

Through 2026, we accumulated perf data scattered across HISTORY.md sections, per-change markdowns in the private `roae-private` staging repo, monitor logs, ad-hoc benchmarks, and informal session memory. Reconstructing "what was the cumulative speedup from v1 to v2+PGO?" required reading ten places at once.

This file collects the data uniformly so that future presentations, decision audits, and regression hunts can read a single source.

## Schema (use this template for every new entry)

```
## YYYY-MM-DD — task #N: <change name> (commit <short-sha>)

**Category**: prune / optimization / mechanism / regression / build  
**Sha impact**: preserving / forking  
**Decision**: shipped / reverted / deferred / NO-SHIP

### Hypothesis
<what we expected and why>

### Methodology
- Workload: <e.g. 1T enum-only, --branch 24 0, depth-3>
- Hardware: <SKU, region, threads, RAM>
- Build: <gcc flags, commit sha of solve.c source>
- Page-cache flush between paired runs: <yes/no>
- Repetitions: <N runs, median reported>

### Result
- enum_wall: <s>
- merge_wall: <s> (reported separately — not part of speedup metric)
- nodes/sec aggregate: <X>
- records found at budget: <N>
- output sha: <hex>

### Delta vs baseline (commit <hex>)
- enum_wall: <±X%>
- records/budget: <±Y%>
- sha changed: <yes/no>

### Sha gate (1B canonical-level diff vs v1 anchor)
- result: <PASS/FAIL/not-run/N-A>
- v1 anchor used: <sha>

### Notes
<what was learned, edge cases, surprises, follow-up tasks>
```

Required fields: hypothesis, methodology, enum_wall, sha-gate, decision. Optional fields can be `TBD` if not measured at ship time — backfill via a later entry rather than editing the original.

## Standard bench harness

The standardized paired-bench script lives at `scripts/perf_bench.sh`. It captures the schema fields above,
provisions a fresh Spot VM in westus3, runs a pure-CPU preflight throttle probe, flushes the page cache between
paired runs (both verified and both gating — a run without `HEALTHY` and `CONFIRMED` verdicts cannot certify
itself), takes `sha` and `records` over the decompressed stream, and emits a JSON line that pastes directly
into a new entry. Any new perf entry should be produced by `perf_bench.sh` or document why
it deviates from the standard methodology.

**What the harness actually does — corrected 2026-08-30.** The paragraph above previously said the script "runs
on a single fresh D128als_v7 Spot in westus3, page-cache flushes between paired runs". Checked against the
script at this commit, that overstates it on three counts, and the JSON it emits is not self-certifying:

- **The SKU is per scale, not fixed.** 1B runs on `Standard_D8als_v7`; 1T and 11.2T run on
  `Standard_D128als_v7` (`scripts/perf_bench.sh:60-62`). Per-scale SKU selection is fine — but it means a bench
  is comparable only to another bench at the same scale, and no entry below should be read as pairing numbers
  across scales.
- **The page-cache flush is now verified, and was not before 2026-09-02.** *(Fixed 2026-09-02, code lane.)*
  The flush used to end `|| true` with the JSON emitting `"page_cache_flushed": true` as an unconditional
  literal — a bench that never flushed shipped certified-looking JSON. The script now reports what it
  observed: each build emits a whole-line verdict token
  (`PERFBENCH_PAGE_CACHE_FLUSHED_{N,U}=CONFIRMED|FAILED|UNVERIFIED`), the JSON carries
  `"page_cache_flushed"` as that status plus a per-build `page_cache_flush_detail`, and a run whose flush
  is not `CONFIRMED` for **both** builds sets `"methodology_valid": false`, prints a red banner, emits
  `PERF_BENCH_METHODOLOGY=VIOLATED` and exits 3. Absence of a token — an aborted or unreachable run —
  reads as `UNVERIFIED`, not as a pass. **`page_cache_flushed: true` in any entry dated before 2026-09-02
  still asserts nothing**, because those entries were produced by the unconditional-literal version; do not
  read them as evidence the cache was cold.
- ~~**There is no preflight throttle probe or pure-CPU burn-in in the script**~~ **Landed 2026-09-02** *(code lane;
  this bullet previously said the script carried only a comment referring to the rule)*. After the build and
  **before any bench**, the script runs `yes > /dev/null` on every core for `--burn-seconds` (default 60,
  floor 30), samples per-core MHz at the *end* of the burn, and requires the minimum to be
  `>= --throttle-min-mhz` (default 3664, the AVX-512 definitive-bench precedent for D128als_v7; the default
  applies at every `--scale`, including the D8als_v7 1B smoke, unless overridden). The 2026-05-18 entry below
  (§"Important methodological finding — `/proc/cpuinfo` MHz under solve.c load is NOT a throttle indicator")
  is why the burn is pure-CPU and precedes the workload. The verdict is a whole-line token,
  `PERFBENCH_THROTTLE_PROBE=HEALTHY|THROTTLED|UNVERIFIED`, with a `PERFBENCH_THROTTLE_DETAIL=` line carrying
  min/avg/max MHz, sample count and threshold; anything but `HEALTHY` — a throttled host, an unreadable MHz
  source, a burn shorter than the floor, or no token at all — tears the VM down before the bench, emits
  `PERF_BENCH_METHODOLOGY=VIOLATED` and exits 5. The JSON carries `"throttle_probe"` and
  `"throttle_probe_detail"`, and `"methodology_valid"` now requires `HEALTHY` as well as both flushes
  `CONFIRMED`. **Entries dated before 2026-09-02 still carry no throttle evidence from the harness** — only
  those whose operator ran the burn separately and recorded it in the entry do, and several below did.
- **`sha` and `records` are logical since 2026-09-02, and were container-level before.** `solutions.bin` is
  gz-framed by default (SOLUTIONS_FORMAT.md §"On-disk framing"), and the script used to run
  `sha256sum solutions.bin` — the sha of the compressed *container*, which varies with zlib version and level
  and is the substance of every documented phantom-drift false alarm — and to derive `records` from the
  container size, a fictional count. It now sniffs the gzip magic and takes both over the decompressed stream
  (`gzip -dc solutions.bin | sha256sum`, the convention of every anchor in CANONICAL_HASHES.md), reports the
  container sha separately as `container_sha`, prints a `framing` field (`gzip` / `raw` / `absent`), and a
  failed decompression yields `sha=DECOMPRESS-FAILED` rather than a hash of partial bytes. **A harness `sha`
  in any entry dated before 2026-09-02 is a container sha and is not comparable to any anchor.**

All three halves of the 2026-08-30 correction — the flush verdict, the throttle probe, and the logical sha —
landed 2026-09-02. This paragraph previously read "the preflight throttle burn has not"; that is no longer
true of the script, and it remains true of every entry produced before that date, which is why this section
stays: no entry below is to be read as certifying conditions the harness did not check *at the time it ran*.

## Process gate

Per `CLAUDE.md` and `DEVELOPMENT.md`: any commit modifying solve.c hot paths (DFS, prune predicates, hash-table operations, merge inner loops, SIMD-vectorized arithmetic) must add a PERFORMANCE_HISTORY entry before ship. Same way every commit modifying canonical artifacts must update CANONICAL_HASHES.md. Enforcement is process-level (reviewer + this rule); a pre-push gate to block pushes when solve.c hot paths changed without a PERFORMANCE_HISTORY.md entry is planned but not yet shipped.

---

# Entries — chronological

## 2026-05-10 — task #72: bitset domain representation for remaining-pair pool (commit `2cf8771`)

**Category**: optimization (representation change, prune-stack foundation)  
**Sha impact**: preserving  
**Decision**: shipped

### Hypothesis
Convert the DFS hot-loop's "remaining pair pool" from `int used[32]` linear-scan to `pair_mask_t` (uint32_t) bitmask. Removes per-iteration byte-load + branch on `used[p]`. Audit predicted 1.1–1.5× standalone improvement; the big win comes from subsequent prunes (#67/#68/#70/#71) that compound on top of `__builtin_popcount` and AND-with-precomputed-table operations the mask form enables.

### Methodology
- Workload: paired 1B-node bench, single-thread per-thread node rate measurement
- Hardware: westus3, D-family Spot (specific SKU recorded in HISTORY.md May 10 section)
- Build: `-O3 -flto -pthread -fopenmp -march=native`
- Repetitions: N=3, median reported

### Result
- Per-thread node rate before (commit `61db6be`, pre-#72): 263 M/sec
- Per-thread node rate after (commit `2cf8771`, ships): 286 M/sec

> **⚠ Correction (2026-08-30):** the two node rates above are **aggregate** rates across **128 threads**, not
> per-thread rates, and the bench was a **90-second timed run**, not the "paired 1B-node bench, single-thread"
> measurement described under Methodology above. The same 263 / 286 M/sec appear in `HISTORY.md` §"Measured speedup: 1.09× over v1" explicitly labelled "Aggregate
> node-rate at 90s", measured under `SOLVE_THREADS=128 SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=11200000000000` on
> D128als_v7 Spot. The labels are irreconcilable and the aggregate reading is the correct one: read as
> per-thread, 128 × 263 M/sec = 33.7 B nodes/sec would finish the 11.2T canonical in ~5.5 minutes, which no run
> record in this project supports; read as aggregate it is ~2.05 M/sec/thread and ~11.8 h at 11.2T, which the
> run records do support. **The 1.09× ratio and the +8.7% below are unaffected** — the defect is in the units,
> not in the comparison, and both figures were taken the same way. Later entries that cite "+8.7% per-thread"
> for #72 (the summary table, the 1T retrospective, the keep-it recommendation) inherit the wrong label but
> quote the correct percentage. See the 2026-08-30 re-evaluation entry at the end of this file.

- Ratio: **1.09×** (at low end of audit's 1.1–1.5× prediction)
- output sha: unchanged (sha-preserving)

### Delta vs baseline
- per-thread rate: **+8.7%**
- enum_wall (canonical scale): TBD — at canonical 11.2T scale storage I/O (.dfs_state sidecar writes on Standard SSD) dominates, so the CPU win is masked unless I/O is on Premium SSD or in-memory checkpoint.
- sha changed: no

### Sha gate
- result: PASS — selftest sha preserved at `403f7202…` (v1 lineage)

### Notes
Foundation entry. The headline gain isn't the 9% — it's that #69 MRV variable ordering, #71 C2 lookahead, and #68 C5 feasibility predicates all use mask operations efficiently. Without #72 these would be per-iteration byte-array scans and the standalone improvements would be 30–50% smaller. See HISTORY.md §"task #72 bitset domain representation shipped" for the detailed audit + the by-value-detour write-up.

---

## 2026-05-11 — task #67: mid-walk C3 pruning shipped, v2 prune stack opens (commit `133e296`)

**Category**: prune  
**Sha impact**: forking (v1 → v2 lineage starts here)  
**Decision**: shipped

### Hypothesis
Track complement-distance partial sum during the DFS walk, prune subtrees whose partial-cd already exceeds the required total (776). Lemma-2 monotonicity proof: never drops a valid leaf. Predicted budget-efficiency win at fixed node budget (more records found per billion nodes).

### Methodology
- Validation: 3 layers — Lemma-2 mathematical proof, gold-standard recompute test (0 mismatches), 100M selftest + 100B-d3-checkpoint gate empirical comparison vs v1 canonical
- Comparison: canonical-level diff (`byte & 0xFC` mask) NOT raw bytes — v1 and v2 emit different lex-winning orient representations per canonical under pruning

### Result
- 100M selftest: 0 v1-canon-only records, 2,526 v2-extra records (+1.86%)
- 100B-d3-checkpoint: 0 v1-canon-only records, 692,226 v2-extra records (+2.58%)
- output sha: changed (v2 selftest now `9ab1cd08…`; v1 was `403f7202…`)

### Delta vs baseline (v1, commit pre-#67)
- records found at fixed budget: **+1.86% at 100M, +2.58% at 100B** (more records per unit budget — what #67 actually buys)
- per-thread node rate: TBD — separately measured contribution to nodes/sec wasn't isolated; the gain is record-throughput not pure speed
- sha changed: yes (v2 lineage forks)

### Sha gate (canonical-level)
- result: PASS — L_v1 ⊆ L_v2 verified at both 100M and 100B scales; zero v1-canon records absent from v2 output

### Notes
This is the first v2 entry. The "perf number" for #67 is best understood as **budget efficiency** (records per billion nodes), not wall-time speedup. At canonical scales, #67 mostly shifts the cost curve so each canonical run finds more of the underlying record set in the same budget; combined with #68/#70 the effect compounds. Detailed write-up in HISTORY.md §"May 11, 2026 PDT — task #67". L_v1 ⊆ L_v2 methodology in `roae-private/V1_V2_SEARCH_SPACE_RELATIONSHIP_2026_05_06.md`.

---

## 2026-05-16 — task #68: C5 feasibility prune (always-on) (commit `bf58c65`)

**Category**: prune  
**Sha impact**: forking  
**Decision**: shipped (v2 lineage begins here)

### Hypothesis
For each within-pair distance d, remaining `budget[d]` must be ≥ count of unplaced pairs whose within-pair distance equals d. Otherwise the current state is dead (no completion exists). Cheap necessary-condition check at `backtrack()` entry; cuts dead subtrees immediately instead of via lazy budget-exhaustion catches downstream.

### Methodology
- 100M-node selftest scenario, same input as `--selftest`
- Build: `gcc -O3 -flto -pthread -fopenmp -march=native`

### Result (verified from commit `bf58c65` body)
- **records found at 100M budget: 135,780 (v1) → 228,990 (v1+C5) = +68.6%**
- output sha: forked from `403f7202…` (v1) to `47dac6cb0783f04dfd98cf15a793e85603b0ceb4a53cd272d97f1def11e3c0c6` (v1+C5)
- All v2 records pass `solve --verify` (C1–C5 clean); King Wen present; sort/dedup integrity preserved

### Delta vs baseline (v1, same 100M budget, same hardware)
- records/budget: **+68.6%** (the C5 prune frees up node budget that finds more records in cells that would otherwise terminate early)
- sha changed: yes (v2 lineage forks at this commit)

### Sha gate
- result: solution-set inclusion validated via `solve --verify-superset` (no v1 records absent from v2 output at 100M)
- canonical-level 1B K-pilot (task #80a in tracker): not yet run as a separate validation

### Notes
**Methodology pivot landed with this commit**: sha-match-vs-v1 is structurally incompatible with any feasibility prune at budgeted runs — the prune frees up node budget that gets spent finding more solutions → different sha. Replaced by (1) solution-set inclusion via `solve --verify-superset`, (2) independent C1–C5 verification via `solve --verify`, (3) v2 canonical shas at stabilization (task #81). See `roae-private/SEARCH_TREE_PRUNING_BUDGET_INCOMPATIBILITY_2026_05_06.md` (private staging) for the underlying argument.

**The +68.6% at 100M does NOT extrapolate linearly to canonical budgets.** Most cells naturally terminate at large per-cell budgets, so the prune's marginal gain tapers. Task #81's 11.2T re-baseline shows the canonical-scale K-ratio: only +4.83% records vs v1 at 11.2T (vs +68.6% at 100M). Empirical scale-dependence captured.

---

## 2026-05-11 — task #70: C3 optimistic-completion bound (commit `7b5ff6d`)

**Category**: prune (refinement of #67)  
**Sha impact**: forking  
**Decision**: shipped

### Hypothesis
Sharpen #67's predicate: `partial_cd + 2 × count_of_unfinished_complement_pairs > 776`. Each unplaced complement-pair `(v, v⊕63)` contributes ≥ 2 to cd_x64 (positions are distinct, doubled by cd_x64 convention). Strict lower bound on future cd, so never prunes a valid leaf. Predicted incremental budget-efficiency gain on top of #67.

### Methodology
- 100M-node selftest scenario, layered ladder showing each prune's marginal contribution
- Build: `gcc -O3 -flto -pthread -fopenmp -march=native`

### Result (verified from commit `7b5ff6d` body)
- 100M layered ladder (records found at 100M budget):
  | Stack | Records | Sha |
  |---|---|---|
  | v1 alone | 135,780 | `403f7202…` |
  | v1 + C5 (#68) | 228,990 (+68.6%) | `47dac6cb…` |
  | v1 + C5 + #67 | 234,252 (+72.5%) | `98b8c0ef…` |
  | **v1 + C5 + #67 + #70** | **235,083 (+73.1%)** | `56487ab5…` ← current v2 selftest |
- **#70 marginal contribution at 100M: +831 records over v1+C5+#67 (+0.35%)**

### Delta vs baseline (v1 + C5 + #67, same 100M budget)
- records/budget: **+0.35%** marginal at 100M, measured on top of the full v1+C5+#67 stack
- sha forked again: `98b8c0ef…` → `56487ab5…`

> **⚠ Correction (2026-08-30):** the three lines above originally named the baseline "#67 alone". Relabelled in
> place as a disclosed correction, because the ladder table directly above makes the arithmetic explicit:
> 235,083 − 234,252 = 831 is (v1+C5+#67+#70) − (v1+C5+#67), i.e. **#70 measured on top of C5**, not on top of
> #67 by itself. Recomputed here: 831 / 234,252 = 0.355%. The configuration the old label described —
> `v1+#67+#70`, #70 *without* C5 — appears nowhere in this entry or anywhere else in this log: **it was never
> run.** Do not bank +0.35% as #70's standalone contribution; it is a marginal gain on top of an already-pruned
> stack, and marginal gains on a prune ladder do not carry over to a different stack. See the 2026-08-30
> re-evaluation entry at the end of this file.

### Sha gate
- result: PASS via L_v1 ⊆ L_v2 (0 v1-missing records in v2+#67+#70 output)

### Notes
The small marginal at 100M is because most #70-only-prunable states are already cut by #67's check at this scale. Larger per-cell budgets where `partial_cd` lingers just below 776 are where #70 contributes more — the 11.2T canonical's cumulative-v2 record advantage (+4.83% vs v1) reflects compounded contributions of #67/#68/#70 at scale. Per-prune isolation at canonical scale would require K-pilot runs per prune (#85 v1+C3 only, #86 v1+C5+C3 stacked in task tracker).

---

## 2026-05-13 — LTO (build flag) (build variant v6d)

**Category**: build / optimization  
**Sha impact**: preserving  
**Decision**: shipped (added to canonical build recipe)

### Hypothesis
Link-Time Optimization enables cross-translation-unit inlining and dead-code elimination. solve.c is single-file but LTO can still help when linking against libm + libpthread + libgomp.

### Methodology
- Paired bench: v6c (no LTO) vs v6d (LTO) at unspecified scale
- Hardware: D128als_v7 Spot

### Result
- Per-thread node rate delta: **+2.53%**
- output sha: unchanged byte-identical

### Delta vs baseline (no-LTO at same commit)
- per-thread rate: +2.53%
- sha: no change (pure compiler optimization)

### Sha gate
- result: PASS (measured — output sha byte-identical between the no-LTO and LTO builds, as recorded under
  Result above; the scale and exact bench parameters were not recorded — see Notes)

> **⚠ Correction (2026-08-30):** this line originally recorded the gate as passing *by definition*, on the rationale that a compiler
> optimization makes no semantic change. **That rationale is withdrawn**; the line now cites the measured
> equality it should always have cited. Budgeted shas in this solver are demonstrably sensitive to non-semantic
> layers: `CANONICAL_HASHES.md` §"100B and sub-canonical reference shas" records commit `d683794` — a diff that
> is 100% resume-gated assertions plus new subcommand handlers, none of it reachable from the fresh-enum DFS
> path — flipping the 100B sha, and concludes "You cannot predict from source-reading whether a commit will flip
> 100B sha — only empirically"; `HISTORY.md` §"Task #110" records the 1T anchor drift as host-environment-level
> and budgeted-cell-density-sensitive. ⚠ **[2026-09-04: that HISTORY record is corrected — the 1T pair is two
> per-cell budgets (published 6,315,458 vs auto-divided 6,314,566), measured on one binary and one host
> 2026-09-04; see `CANONICAL_HASHES.md` §d3 1T. The 100B `d683794` flip discussed here is budget-controlled
> and commit-level, and is unaffected: it remains this bullet's supporting example.]** **The +2.53% and the byte-identical sha stand exactly as measured** — only
> the epistemics are corrected. Every optimization-flag change measured in this log to date has in fact
> preserved the sha; that is an empirical record, not a definitional guarantee, and it is why a sha gate is run
> rather than reasoned. See the 2026-08-30 re-evaluation entry at the end of this file.

### Notes
Modest but free win. Added to the canonical build recipe: `gcc -O3 -flto -pthread -fopenmp -march=native`. Backfilled from operator memory entry `feedback_canonical_pipeline_pattern`; exact bench parameters not recorded in HISTORY.md.

---

## 2026-05-16 — task #46: AVX-512 retool — **NULL RESULT** (commits `cd4e61c` → `b26cd9b` REVERT → `0783d52` definitive bench)

**Category**: optimization (SIMD vectorization)  
**Sha impact**: preserving (byte-identical scalar vs AVX-512)  
**Decision**: **CLOSED via REVERT + null result** — task originally planned as pre-560T gating; now closed because no speedup exists to ship

### Hypothesis (originally)
Three sites in the DFS hot path are vectorizable to AVX-512: complement-distance partial-sum (cd-sum), C2 hamming check, C5 difference-distribution tallying. Predicted **1.4–2.0× total-runtime speedup** on Zen 4/5c. The April 2026 plan considered AVX-512 a major contributor and built ARM-buy-decision-support (#83) around the assumption that SVE2 parity would be needed for ARM performance.

### Methodology
- **Phase 1a (commit `cd4e61c`)**: explicit AVX-512 dispatch via `__builtin_cpu_supports` + intrinsics for cd_sum_avx512
- **Phase 1a REVERT (commit `b26cd9b`)**: post-bench disassembly under canonical build flags (`-O3 -march=native`) revealed gcc 13.3 already auto-vectorizes `compute_comp_dist_x64` to AVX-512: 5× `vmovdqa32`, 4× `vpermd`, 4× `vpabsd`, 4× `vpsubd`, 7× `vpaddd`. The "scalar" code was already SIMD'd by the compiler. The hand-written dispatch added overhead (loss of inlining + per-call dispatcher branch) with no algorithmic gain.
- **v8 retry definitive bench (commit `0783d52`)**: 5 paired interleaved trials of `solve_avx2` (`-mno-avx512f -mno-avx512bw -mno-avx512vpopcntdq`) vs `solve_avx512` (`-march=native`, autovec emits AVX-512) at 1T enum-only, D128 healthy host (preflight probe confirmed min 3664 MHz under 60s 128-thread burn — no throttle).

> **⚠ Correction (2026-08-30):** the three commits this entry rests on — `cd4e61c`, `b26cd9b`, `0783d52` — are **not present in the shipped
> repository**: `git cat-file -t` fails on each with "Not a valid object name". Per the Access boundary at the
> top of this file, everything below sourced from those commit bodies is therefore **operator-attested**:
> disclosable to an auditor from the private staging record, not checkable by a reader of the public repository.
> "Verified from commits … bodies" describes how the operator verified these figures, not a check a reader can
> repeat here. The v8 retry's paired timings and the null result itself are unaffected by this — only their
> public checkability is.

### Result (verified from commits `b26cd9b` and `0783d52` bodies)
- **Phase 1a dispatch**: 2.7% **SLOWER** than baseline scalar (loss-of-inlining + dispatcher overhead)
- **v8 retry 1T paired bench**: AVX2 mean 433.0s, AVX-512 mean 434.6s → **0.9963× ≈ statistically zero**
  - 95% CI [−4.05, +0.85]s crosses zero
  - Welch t = −1.281, |t| < 2.3 threshold → null hypothesis NOT rejected
- output sha: byte-identical (sha-preservation gate trivially passed since both builds run the same vectorized code; the only differences are register-allocation noise)

### Delta vs baseline (scalar / AVX2-only at same commit, 1T)
- enum_wall: **−0.37% (statistically zero, well within noise)**
- sha changed: no

### Sha gate
- result: PASS — `solve --selftest` byte-identical on both builds

### Notes
**The instructive zero entry.** The original projection of 1.4–2.0× was structurally wrong: gcc already auto-vectorizes the only loop that benefits (one vectorizable loop in the enum hot path per `-fopt-info-vec`; the other 112 "control flow in loop" misses in `backtrack` are inherently un-vectorizable — DFS with data-dependent `budget[wd]<=0` early-exits cannot be SIMD'd).

**ARM implication (refutes the original SVE2-parity-required framing)**: with AVX-512 confirmed as ~zero contributor, the SIMD-width gap between x86 (512-bit) and ARM Neoverse (NEON 128-bit / SVE2 256-bit) is NOT a performance concern for this workload. ARM-vs-x86 reduces to scalar IPC + branch prediction + memory subsystem. NEON-only pilot is sufficient; SVE2 parity is not required. #83 (ARM pilot) scope reduced accordingly.

**Stale references corrected**: HISTORY.md April 2026 plan section now carries a `[REFUTED 2026-05-16]` callout against the 1.4–2.0× projection.

> **⚠ Correction (2026-08-30):** **that callout is not there.** Checked at this commit: `grep -n "REFUTED 2026-05-16" documentation/HISTORY.md`
> returns exactly one line — `HISTORY.md:3310` — and that line is this same *claim* that the callout is "already
> in place", not a callout. The unqualified 1.4–2.0× projections still stand unmarked at `HISTORY.md:1510-1514`
> ("Speedup ceiling revised upward to **1.4–2.0× total runtime**") and at `HISTORY.md:2610` ("Plan expects
> 1.4-2.0× per the implementation doc"). Searching for the bare token "REFUTED" near both sites finds nothing
> either. This is the failure mode of a document asserting a marker it never supplied — a reader who trusts the
> sentence above never goes looking.
>
> **✅ RESOLVED 2026-09-02 (prose batch P64).** Both callouts now exist. The line numbers had drifted —
> the figures are at `HISTORY.md:1521` and `:2628`, not `:1510-1514` and `:2610` — and were located by
> content rather than by number. A third occurrence sits inside the refutation narrative itself and
> correctly needs no callout. **The correction above is left standing, not rewritten:** it was true when
> written, and deleting it would erase the 3.5-month interval during which this file asserted a marker
> that did not exist. That interval is the finding. Adding the two callouts edits `HISTORY.md` and is tracked outside this
> document; **until they land, treat the sentence above as not yet true.** The null result it points at is
> sound — it is the cross-reference that is missing. See the 2026-08-30 re-evaluation entry at the end of this file. Task #82 ("HARDWARE_CPU_COMPARISON.md doesn't exist") was marked stale because the AVX-512 numbers actually live across commits `b26cd9b` and `0783d52` rather than the conjectured doc.

Cost of the bench: ~$10 (preflight + 5 paired trials on D128 Standard on-demand, ~80 min total).
Archive: `canonical-archive/20260516_modern_v1_1T_AVX512_quant_ENUM_ONLY_RETRY_3258f4c/`.

---

## 2026-05-17 — task #71: one-step C2 lookahead — shipped + benched + reverted (commits `438d297`, `9d00c48`)

**Category**: prune (NO-SHIP)  
**Sha impact**: would have been preserving (semantic equivalence to without-lookahead)  
**Decision**: **NO-SHIP — REVERTED**

### Hypothesis
Precompute a 64-entry `c2_compat[hex]` mask. After placing hex h, AND the remaining-pairs mask with `c2_compat[h]` to eliminate any pair whose first hexagram is C2-incompatible with h. One register AND, sub-cycle cost. Predicted standalone 5–15% per-thread rate improvement via early pruning of C2-doomed iterations.

### Methodology
- Paired bench at 1T node budget, D128als_v7 Spot westus3
- 10 alternating reps, median compared

### Result
- per-thread node rate: **-10.7% regression** vs without-lookahead
- output sha: byte-identical (semantically correct)

### Delta vs baseline (commit `7b5ff6d` = v2 without #71)
- per-thread rate: **-10.7%**
- sha changed: no

### Sha gate
- result: PASS (this was the consolation prize — the prune was correct, just slow)

### Notes
**The instructive loss entry.** Hypothesis was that the cheap AND-with-mask op would dominate; reality was that the precomputed `c2_compat[hex]` table thrashed the L1d cache (64 × 32 = 2,048 bytes table competing with the hash table on every inner iteration), and the branch predictor was already optimally handling the without-lookahead case via the C2-failed-and-iterate pattern. Lesson: micro-architectural simulation isn't a substitute for paired bench at scale.

Commit `9d00c48` reverts `438d297`. Both commits are kept in the lineage so the bench can be reproduced. Task #71 is marked `[NO-SHIP]`.

---

## 2026-05-17 — task #81: v2-bundled 11.2T canonical re-baseline (commit `9d00c48` for solve.c, archive `9d00c48`)

**Category**: re-baseline (not a perf change — establishes new canonical sha)  
**Sha impact**: forking (new v2 canonical anchor)  
**Decision**: shipped after 4-attempt $13 saga; details in canonical pipeline runbook

### Hypothesis
With v2 prune stack (#67 + #68 + #70 + #72) shipped and #71 reverted, re-run the 11.2T canonical to establish a new v2 anchor sha for downstream comparisons.

### Methodology
- D128als_v7 Spot, westus3, full enum + cross-build pair (Build A)
- 11.2 trillion total node budget, 158,364 depth-3 sub-branches
- Canonical pipeline runbook: shards-on-solver-data, Premium SSD only for merge temp, never auto-tear-down on Phase 2 error, curl -T not --data-binary, $0.02 D2 pre-flight, triple storage redundancy

### Result
- v2 11.2T canonical sha: `2cc966e48399841ebb0c9ca67300f15bb578cc5481ed04fca5faffcb38ad6c4d`
- records: **796,357,285** (vs v1 11.2T canonical `0c0fe37c…` at 759.6M — **+4.83%**)
- enum_wall: TBD (saga's runtime breakdown in HISTORY.md)
- merge_wall: TBD

### Delta vs baseline (v1 11.2T canonical `0c0fe37c…`)
- records found: **+4.83%** (the cumulative effect of v2's bundled prunes at 11.2T scale)
- sha: forked (new v2 anchor)

### Sha gate
- v1-vs-v2 record-set inclusion verified at canonical level (`byte & 0xFC` mask); zero v1 records absent from v2 output

### Notes
This is the cumulative-v2 anchor. Per-prune contribution to the +4.83% isn't isolated by this run — it's the bundled effect. The +4.83% at 11.2T is much smaller than the +104% at 100B observed for #68 alone — diminishing returns at scale, predicted in the v2 design docs and confirmed empirically. v2 advantage at 100T+ is expected to be ~1-2% (well below the v1 baseline difference at small scales).

> **⚠ Correction (2026-08-30):** **that expectation was measured and falsified.** The v2 100T canonical
> (`cc4a5377199f0710c99406c6e82e44f311ef34b2e53b152d67f5d0fcd2ace091`, 3,663,580,914 records) came in at
> **+231,181,617 records = +6.74%** over v1 100T's 3,432,399,297 — recomputed here: 231,181,617 / 3,432,399,297
> = 6.735%. See `CANONICAL_HASHES.md` §"v2 lineage — CLOSED 2026-05-24" (v2 100T details) and `HISTORY.md`'s v2
> 100T result, which says outright that the figure is "much larger than the '~1-2% diminishing returns'
> extrapolation … had predicted. The v2 prune stack retains substantive uplift at 100T depth, not saturation."
> The measured scaling is +4.83% at 11.2T → **+6.74% at 100T**: the advantage **grew** with depth, it did not
> decay. `CANONICAL_HASHES.md` was corrected at the time; this log was not, until now — which is exactly the gap
> the append-only contract's re-evaluation rule exists to close. **The +4.83% at 11.2T and the +104% at 100B
> above are measured and stand**; only the forward extrapolation was wrong. See the 2026-08-30 re-evaluation entry at the end of this file.

Detailed writeup in `roae-private/V2_11_2T_LESSONS_LEARNED_2026_05_17.md` and HISTORY.md.

---

## 2026-05-18 — task #78: PGO (profile-guided optimization) sha-preservation pilot

**Category**: build / optimization  
**Sha impact**: preserving (the gate)  
**Decision**: shipped (pending operator review of full 1T bench results)

### Hypothesis
gcc's `-fprofile-generate` / `-fprofile-use` enables hot-path-specific code-layout and inline-decision optimization. Predicted 5–20% per-thread rate improvement on Zen 5c. Must be sha-preserving (no semantic change) — that's the gate.

### Methodology
- Paired bench (Build N control vs Build U PGO-use) at three commit reference points:
  - 1B-node smoke test (D8als_v7 Spot westus3, --branch 25 1, depth-3, iterative, 8 threads) — captured in `/tmp/pgo_pilot_results/`
  - 1T enum-only (D128als_v7 Spot westus3, --branch 24 0, depth-3, iterative, 128 threads, page-cache flush between paired runs, SOLVE_SKIP_AUTOMERGE=1) — completed; final accounting under "Result — 1T enum-only (D128als_v7), final accounting" below
- Build N: `-O3 -flto -pthread -fopenmp -march=native`
- Build U: `... -fprofile-use=$PROFDIR -fprofile-correction` (profile data from selftest + 200M-node `--branch 25 1`)
- Page-cache flushed between paired 1T runs via `sync && echo 3 | sudo tee /proc/sys/vm/drop_caches`

### Result — 1B-node smoke test (D8als_v7)
- sha_N == sha_U == `3e6d1060fdf8c53a64a69d76a5a97616f285ad7811c6d5694fb343a406077222` (byte-identical)
- wall_N: 26s, wall_U: 25s → **+4% speedup** at small scale (warmup-noisy)
- output sha: byte-identical → **sha-preservation confirmed**

### Result — 1T enum-only (D128als_v7), final accounting
- Build B (v2 no-PGO): enum_wall=1046s, sha=`f3a3e68cb554fff58ef2a25f56362b2ddcc0398adae4c7b307ac2020f1ac4916`, records=305,975,483
- Build C (v2 + PGO): enum_wall=996s, sha=**LOST** (Build C merge failed twice on 64 GB OS disk; external-mode merge launched but did not finish before bench script's STEP 7 tore down the VM), records=presumed ~306M but unverified
- **PGO enum-only speedup at 1T: +4.8%** (1046s → 996s)
- merge_wall: not standardized in this run (Build B's auto-merge completed; Build C's required intervention)
- Build A v1 baseline at 1T: enum_wall=1037s (depth-2 + iterative) / **enum_wall=703s (depth-2 + recursive — recursive 32% faster than iterative for v1 at this depth)**, sha=`548c2de4311c1abc1457d3d9acb4e45b39de3a85e945d35af1e39c59555e8d54`, records=162,576,690

### Delta vs baseline (Build B, v2 same source commit)
- enum_wall: **−4.8% (PGO faster)**
- sha changed: not directly verified at 1T (Build C sha lost); 1B sha-equality already PASS on D8 smoke test as independent evidence

### Sha gate
- 1B byte-equality: **PASS** (D8 smoke test, both shas `3e6d1060fdf8c53a64a69d76a5a97616f285ad7811c6d5694fb343a406077222`)
- 1T byte-equality: **NOT VERIFIED** (Build C sha lost to teardown race)

### Methodology caveats (important — read before relying on these numbers)
1. **No preflight throttle probe was run.** Per the standing `feedback_preflight_throttle_probe` and the AVX-512 definitive bench (commit `0783d52`) precedent, paired 1T benches should validate the host with a 60s 128-thread burn-in measuring per-core MHz ≥ 3664. We did not. Mid-bench sampling showed average CPU MHz at 2717 across 128 cores — could be normal-under-load (memory-bound DFS, cores waiting on RAM) or could be TDP-cap throttle. Cannot distinguish without the preflight burn-in.
2. **The 4.8% PGO speedup is a paired comparison on the same VM with page-cache flush between runs.** If throttling was symmetric across Build B and Build C, the speedup is valid. If throttling was asymmetric (B unthrottled / C throttled, or vice versa), the speedup is biased. We have no monitoring data to rule asymmetric throttle out.
3. **The 4.8% at 1T agrees with the 4% at 1B on a different VM (D8 Spot)** — independent corroboration that PGO speedup is real and roughly in this range, even if absolute scale at 1T is uncertain.
4. **v1 baseline at depth-2** uses different work-unit granularity than v2 at depth-3; wall comparisons between Builds A and B are not apples-to-apples for "per-unit" speed. Records/budget is the cleaner cross-build comparison: v1 found 162.6M records at 1T budget; v2 found 305.9M = **1.87× more records per unit budget**.

### Follow-up needed (for cleanup of this entry)
- Re-run PGO 1T bench with: (a) preflight throttle probe, (b) larger OS disk to avoid the merge-disk-pressure race, (c) bench script that waits for merge before STEP 7 teardown. Cost ~$2-3 on D128 Spot. Would verify Build C sha and tighten the speedup confidence interval.

### Notes
This is the **first entry produced by the standardized `scripts/perf_bench.sh` harness** (or its prototype: `/tmp/pgo_1T_retry.sh`). Page-cache flush between paired runs is now the standard methodology — applied here for the first time. Compose +2.53% (LTO) + +4.8% (PGO) on top of v2's prune stack: total LTO+PGO marginal contribution ~7.4% on v2-bundled. AVX-512 contribution still TBD pending the backfill (see #46 entry).

Lessons captured during this run:
1. **OS disk sizing**: 64 GB filled when both Build B and Build C shards co-resident on the merge phase; needed manual intervention. For future paired benches, plan for 128 GB OS disk or external data disk for shard scratch.
2. **Merge time should be excluded from speedup**: the script captures enum-only wall in the `WALL` variable; `--merge` runs separately after.
3. **v1 baseline (commit `1d4dc6e`) crashed at depth-3 + 128 threads**: hypothesis is buffer-overflow detection in v1's pre-#72 array-domain code under high thread count. Diagnostic re-attempt at depth-2 in progress (Build A in current bench).

Full results to be appended once 1T bench completes.

---

## 2026-05-18 — task #78 v3 rerun: PGO 1T paired bench — confirmed sha-preserving, **6.5% speedup**

**Category**: build / optimization  
**Sha impact**: preserving (CONFIRMED at 1T)  
**Decision**: ship — supersedes the v2 retry entry's caveats above

### Hypothesis (refined)
The v2 retry (entry above) hit two methodology gaps: no preflight throttle probe, and Build C's 1T sha was lost to a teardown race. This v3 rerun closes both gaps and produces the definitive PGO 1T number.

### Methodology (definitive)
- D128als_v7 Spot, westus3, 128 GB OS disk (vs 64 in v2 retry — eliminates merge-disk-pressure race)
- **Preflight 60s 128-thread `yes`-burn throttle probe**: required min CPU MHz ≥ 3664 per the AVX-512 definitive bench precedent. Abort + teardown if below.
  - Measured: **min 3868 MHz, avg ~3868** at 60s burn → HEALTHY HOST confirmed
- Build N (control): `gcc -O3 -flto -pthread -fopenmp -march=native` at v2-bundled commit `1b32270`
- Build U (treatment, "Build C"): same flags + `-fprofile-use=$profdir -fprofile-correction`; profile gathered from selftest + 200M-node `--branch 25 1` workload
- Both at 1T: `SOLVE_NODE_LIMIT=1000000000000 SOLVE_DEPTH=3 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128 SOLVE_SKIP_AUTOMERGE=1 --branch 24 0`
- Merge: `SOLVE_MERGE_MODE=external` from start (avoids in-memory disk-pressure race)
- Page-cache flush via `sync && echo 3 | sudo tee /proc/sys/vm/drop_caches` between paired runs
- Each run measured: `start_MHz`, `end_MHz`, `enum_wall`, `merge_wall` (separately), `records`, `sha256(solutions.bin)`

### Result — 1T paired (CONFIRMED)
| Build | enum_wall | merge_wall | start_MHz | end_MHz | records | sha256(solutions.bin) |
|---|---|---|---|---|---|---|
| B (v2 no-PGO) | **1067 s** | 809 s | 2611 | 2685 | 305,975,483 | `f3a3e68cb554fff58ef2a25f56362b2ddcc0398adae4c7b307ac2020f1ac4916` |
| C (v2 + PGO) | **997 s** | 853 s | 2717 | 2717 | 305,975,483 | `f3a3e68cb554fff58ef2a25f56362b2ddcc0398adae4c7b307ac2020f1ac4916` |
| A (v1, depth-2 recursive) | 708 s | 396 s | 2672 | 2718 | 162,576,690 | (different solver — not directly comparable for sha equality) |

### Delta vs baseline (Build B, v2 same source commit, same VM, same workload)
- **PGO enum-only speedup at 1T: 6.5%** (1067 → 997 s, +70 s saved)
- **sha changed: NO — byte-identical** (`f3a3e68c…` matches across B and C)
- Records: identical to the byte (305,975,483)

### Sha gate
- 1T byte-equality: **PASS** ✓
- 1B byte-equality: **PASS** ✓ (previous D8 smoke test, both shas `3e6d1060…`)
- Multi-scale + multi-host confirmation: PGO is sha-preserving on this codebase.

### Resolved caveats from v2 retry entry
- ✅ **Preflight throttle probe ran and PASSED** (min 3868 MHz ≥ 3664). The host was healthy.
- ✅ **Build C sha captured** (`f3a3e68c…`, byte-identical to Build B).
- ✅ **Disk-pressure race eliminated** (128 GB OS disk, external merge, no intervention needed).
- ✅ **Reproducibility cross-host**: Build B's sha `f3a3e68c…` here matches Build B's sha from the v2 retry on a different host — the v2-bundled 1T output for `--branch 24 0` is byte-stable across independent runs on different VMs.

### Important methodological finding — `/proc/cpuinfo` MHz under solve.c load is NOT a throttle indicator
- This confirmed-healthy host (preflight min 3868 MHz at pure-CPU burn) measured **2611–2717 MHz during solve.c enum** — almost identical to the v2 retry's "suspected-throttle" 2717 MHz reading.
- Conclusion: **solve.c is memory-bound** and runs cores at natural base-clock duty cycle regardless of host health. Mid-bench `/proc/cpuinfo` sampling cannot distinguish throttle from memory-bound saturation.
- **The correct throttle signal is the preflight pure-CPU burn** (`yes > /dev/null` × N threads, sample MHz after 30s+ stabilization). The post-bench reading at 03:34Z showed min 2596 / avg 2627 / max 4552 — again, base-clock duty cycle, not throttle.
- This finding updates `feedback_preflight_throttle_probe`: the burn-in is mandatory because workload-time MHz is uninformative for this codebase.

### Notes
The v2 retry's reported 4.8% was a LOWER bound — the v3 rerun on a strictly-validated healthy host gives 6.5%. The 4.8% wasn't wrong per se; both runs measured the same underlying PGO contribution, and the difference (4.8 vs 6.5) is within paired-bench noise across different VM instantiations. The v3 number is the better one to cite going forward because it has the preflight validation.

**Composes with LTO**: net PGO+LTO marginal contribution on v2-bundled is approximately 2.53% (LTO) + 6.5% (PGO) ≈ **9% cumulative speedup from compile-flag optimizations alone**, sha-preserving.

Cost of v3 rerun: ~$1.51 (D128als_v7 Spot @ ~$0.95/hr × 1h 35m). Bench script at `/tmp/pgo_1T_v3.sh`.

---

## 2026-05-18 — task #92: resume regression fix (mw_delta added to v2 frame format) (commit `b684cca`)

**Category**: correctness fix (NOT a perf change — sha-preserving for non-resume runs by design)  
**Sha impact**: preserving for single-shot; resume now produces byte-identical output to single-shot (was diverging since `9f4b630`)  
**Decision**: shipped (commit `b684cca` 2026-05-18, pushed to v2-bundled)

### Hypothesis
Bisect (filed in `roae-private/RESUME_REGRESSION_RCA_2026_05_18.md`) localized the resume divergence to commit `9f4b630` (#67 mid-walk C3 reship): `BacktrackFrame.mw_delta` is required for the RETRY phase's `ts->mw_partial_cd_x64 -= fr->mw_delta;` undo, but was not serialized in `DFSStackFrame_v2`. On resume, every restored frame's `mw_delta` was uninitialized (effectively 0), so the undo subtracted 0 → `mw_partial_cd_x64` drifted from live-path value → prune predicate fired differently → resume sha diverged. Fix: extend the on-disk format to carry `mw_delta`, bump version.

### Methodology (multi-scale validation)
1. **Bisect gate** (claude orchestrator, ~$0): three commits tested via `--selftest-resume`
   - `bf58c65` (#68 alone, pre-bug): **PASS** resume sha `e43f2905…` = single-shot
   - `9f4b630` (#67 reship, breaking commit): **FAIL** resume sha `e353086e…` ≠ single-shot `86a74da5…`
   - `1b32270` (HEAD, pre-fix): **FAIL** resume sha `2954b271…` ≠ single-shot `1f6a3b4a…`

2. **Post-fix selftest gate** (claude, ~$0):
   - `--selftest`: sha `56487ab5…` UNCHANGED ✓ (confirms no behavior change at single-shot)
   - `--selftest-resume`: resume sha `1f6a3b4a…` = single-shot sha `1f6a3b4a…` ✓

3. **1B-scale resume validation** (D8als_v7 Spot, $0.05 / 8 min wall):
   - BASELINE: fresh dir, 1B single-shot, 128 threads, `--branch 24 0`
   - PHASE_A: fresh dir, 500M (triggers per-cell budget, writes 2,824 `.dfs_state` checkpoints across 2,824 sub-branches)
   - PHASE_B: same dir as PHASE_A, 1B (resumes from all 2,824 checkpoints, continues to 1B)
   - Merge each, compare shas
   - **Result**: BASELINE sha `e4934b87c6fbbbc28cab70a8c55d260fe5e5c4639f5da2035a8657cc7f7e3ace` = PHASE_B sha (byte-identical). Both at 1,631,512 records. **PASS 1B-resume-validation across 2,824 simultaneous resume cycles.**

### Result
- `--selftest` sha: `56487ab5…` unchanged (compile-gate enforced at every push)
- `--selftest-resume`: PASS, resume sha = single-shot sha (the canonical defense item 1 from Phase E.2)
- 1B paired resume test: PASS across 2,824 resume cycles, byte-identical solutions.bin between resumed and from-scratch
- Code change: 11 lines (struct extension + version bump + capture-loop + resume-loop save/restore)
- Format version: `DFS_STATE_VERSION_V2` bumped 2 → 3 (old checkpoints rejected with clean error)

### Delta vs baseline
- Single-shot wall: identical (no observable change at single-shot scale; the `mw_delta` plumbing is invisible unless a checkpoint is read back)
- Per-frame on-disk size: 8 → 12 bytes (struct grows by 4 bytes per frame; 34 frames per checkpoint × 4 bytes = 136 bytes per `.dfs_state` file growth — trivial)
- Total `DFSCheckpointState_v2` size: 438 → 574 bytes, well under the 2048-byte static assertion

### Audit of existing canonicals (pre-fix runs)
Confirmed in `roae-private/RESUME_REGRESSION_RCA_2026_05_18.md`. **Zero existing canonical artifacts are corrupted by the original bug** — all v1 canonicals predate the `mw_delta` field; v2 11.2T canonical `2cc966e4…` had checkpoint mechanism enabled but the resume code path was never exercised (158,364 WROTE markers, 0 READ markers in enum_solve.log); v2 100B canonical `de28fea6…` at commit `bf58c65` (pre-bug) ran without checkpoint mechanism enabled at all.

### Notes
The instructive moral: when adding state to `BacktrackFrame`, the checkpoint format must extend simultaneously. The on-disk format is part of the state-machine contract, not separate from it. Today's `feedback_*` operator-memory entries don't capture this lesson yet — worth adding.

Closes Phase E.2 defense item 1 (selftest-resume gating) and the gating gap for the 560T canonical campaign with eviction-recovery.

---

## 2026-05-18 — task #69: MRV variable ordering (fail-first pair iteration) — **SHELVED after K-pilot**

**Category**: prune (search-order — turned out NOT to produce a superset relation)  
**Sha impact**: would be forking in `fail-first` mode (byte-level AND canonical-level, at every scale tested)  
**Decision**: **SHELVE** — K-pilot at canonical-equivalent scale shows fail-first finds 23% FEWER records than numeric AND the two orderings explore completely disjoint canonical-level record sets

### Hypothesis (original)
Iterate available pairs at each DFS step in fail-first order (pairs with rarest within-pair-distance first) rather than fixed numeric order 0..31. CSP literature suggests 2–10× tree-size reduction. Implementation: existing dead-code `pair_order[]` sorted table (already present in solve.c since some prior unfinished attempt) wired into the DFS hot loop, gated by `SOLVE_VAR_ORDER=fail-first` env (default `numeric` is sha-preserving).

### Hypothesis
Iterate available pairs at each DFS step in fail-first order (pairs with rarest within-pair-distance first) rather than fixed numeric order 0..31. CSP literature suggests 2–10× tree-size reduction. Implementation: existing dead-code `pair_order[]` sorted table (already present in solve.c since some prior unfinished attempt) wired into the DFS hot loop, gated by `SOLVE_VAR_ORDER=fail-first` env (default `numeric` is sha-preserving).

### Methodology (planned)
- 3-rung sha-preservation: numeric default, explicit `SOLVE_VAR_ORDER=numeric`, fail-first
- 1B K-pilot: numeric vs fail-first canonical-level diff at 1B nodes; K = R_ff / R_num is the perf-equivalent metric (records found per budget)
- 11.2T re-baseline if K threshold met

### Result — selftest scale (100M, single-thread per-thread bench TBD)
- Selftest (default = numeric): sha `56487ab581f13497a1725b5cc069c65f450ab3b29a0ef6a00360452ccded6edc` (matches canonical baseline)
- Selftest (`SOLVE_VAR_ORDER=numeric`, explicit): same sha — PASS
- Selftest (`SOLVE_VAR_ORDER=fail-first`): same sha — PASS (selftest's 100M budget + sorted-merge dedup makes orderings equivalent at this scale)
- Fail-first reproducibility (re-run): same sha — PASS

### Delta vs baseline
- 1B K-pilot: not yet run; pending
- 11.2T paired bench: not yet run

### Sha gate
- Numeric mode: PASS (byte-identical to pre-patch sha)
- Fail-first mode: PASS at selftest scale (canonical-level diff = zero at 100M)
- 1B K-pilot: pending

### Result — K-pilot empirical data (2026-05-18, ~$2 total)

Paired numeric-vs-fail-first runs on `--branch 24 0` (largest first-level branch, 2,488 depth-3 cells), same VM, page-cache flush between modes, preflight throttle probe at canonical scale:

| Scale | Per-cell | K = R_ff/R_num | Numeric records | Fail-first records | Set relationship |
|---|---|---|---|---|---|
| 1B | 402K | **1.342** | 1,631,512 | 2,189,610 | byte-shas differ |
| 10B | 4M | **0.980** | 9,762,700 | 9,568,717 | canonical-shas differ |
| 100B | 40M (≈ canonical) | **0.770** | 60,519,764 | 46,569,461 | **\|N∩F\|=0 — DISJOINT** |
| 1T | 402M (5.7× canonical) | **0.922** | 305,975,483 | 282,009,708 | shas differ; intersection size computation killed |

### Why SHELVE
1. The 1B K=1.342 was a small-budget artifact — both orderings find their own "easy" subset; the 34% advantage doesn't replicate at larger scales.
2. **At canonical-equivalent scale (100B), fail-first underperforms by 23%.**
3. **At canonical scale, the canonical-level set intersection is EMPTY** — numeric finds 60.5M records, fail-first finds 46.6M records, and they share ZERO records at the pair-sequence level. The two orderings are exploring genuinely non-overlapping slices of the search tree, not refinements of each other.
4. The 1T K=0.922 shows partial convergence at larger scale but fail-first never exceeds numeric.
5. Neither set is a superset of the other → re-baselining the canonical on fail-first would produce a different, smaller artifact that isn't comparable to v2 `2cc966e4…` by sha-preservation criteria.

### Sha gate
- Numeric mode: PASS (selftest sha `56487ab5…` byte-identical to current v2 canonical baseline)
- Fail-first mode: at every scale tested, both byte-level shas AND canonical-level shas differ from numeric; canonical-set intersection at 100B is empty
- 1T numeric reproducibility: sha `f3a3e68c…` byte-identical to today's PGO 1T v3 bench (cross-host reproducibility confirmed)

### Decision
**SHELVE the current `fail-first` implementation.** The patch in working tree (`solve.c` with `pair_order[]` wired into the DFS hot loop) stays uncommitted. Either drop via `git checkout HEAD -- solve.c` or leave as documentation of "what was tried."

This does NOT close out variable-ordering as a research direction. The disjoint-set finding suggests that variable ordering DOES matter — different orderings genuinely explore different regions. A future per-step MRV scheme (count valid options per remaining slot, sort by ascending constrainedness — not the static WPD-rarity heuristic tested here) might find a different region that's larger than numeric's. That's a spiritual successor task, not this implementation.

### Notes
- 22 GB of K-pilot solutions.bin files archived to `solver-data-westus3:/kpilot_69_mrv_20260518_*/` for post-hoc analysis if needed.
- Detailed K-pilot writeup: `roae-private/MRV_KPILOT_RESULTS_2026_05_18.md`.
- Design doc that motivated the K-pilot: `roae-private/MRV_VARIABLE_ORDERING_DESIGN_2026_05_17.md`.

### Bug found and fixed during this K-pilot
The first K-pilot bench attempt hit a silent SIGSEGV on `solve --merge` with `SOLVE_MERGE_MODE=external` on default 8 MB stack. Fixed in commit `dc01860` — `--merge` now hard-exits with a clear error if RLIMIT_STACK ≠ unlimited. See separate entry below.

---

## 2026-05-18 — tasks #80a / #85 / #86: per-prune isolation K-pilot — multi-scale attribution

**Category**: empirical attribution (no code change)
**Sha impact**: none (re-builds at historical commits)
**Decision**: ship the attribution data into the perf narrative; closes #80, #85, #86 in one pilot

### Hypothesis
The v2 prune stack (#67 mid-walk C3, #68 C5 feasibility, #70 C3 optimistic-completion) ships bundled in the canonical 11.2T v2 build (+4.83% records vs v1). Until now, no per-prune attribution: we don't know whether #68 dominates or contributions are roughly equal. Need K-pilot data per prune at canonical-relevant scales to inform #88 (tighter C5) vs #89 (C2 space prune) design priority.

### Methodology
- **5 build variants** from natural commits on v2-bundled lineage (no env-var toggles):
  - `v1_baseline` = 72fdfdf (v1 + #72 bitset, sha-preserving)
  - `v1_C3_only` = 133e296 (v1 + #67 alone, cherry-pick provenance)
  - `v1_C5_only` = bf58c65 (v1 + #68 alone)
  - `v1_C5_C3` = 9f4b630 (v1 + #68 + #67)
  - `v1_C5_C3_C3opt` = 7b5ff6d (v1 + #68 + #67 + #70 = current v2 stack)
- **4 scales**: 100M (local), 1B + 10B (D8 Spot), 100B (D128 Spot with throttle preflight HEALTHY 3048 MHz min)
- **Workload**: full enumeration, default depth-2, page-cache flush between variants. Same scenario as `--selftest` scaled up.
- **Capture**: records, sha256, canonical-level sha (byte & 0xFC mask). For 1B + 10B, solutions.bin retained for canonical-set intersection analysis.

### Result — per-prune Δ records vs v1 baseline across scales

| Scale | v1 baseline | +C3 (#67) | +C5 (#68) | +C5+C3 | +C5+C3+C3opt (v2) |
|---|---:|---:|---:|---:|---:|
| 100M | 135,780 | +1.86% | **+68.6%** | +72.5% | +73.1% |
| 1B | 607,998 | +3.36% | **+80.4%** | +88.9% | +90.6% |
| 10B | 2,644,608 | +3.39% | **+90.2%** | +99.1% | +101.1% |
| 100B | 12,386,121 | +7.22% | **+104.4%** | +120.0% | +121.6% |
| 11.2T canonical | 759,608,573 | — | — | — | +4.83% |

### Per-prune attribution — three findings

1. **#68 (C5 feasibility) is the workhorse — ≈14-37× more impactful than #67 depending on scale (24-27× at
   1B-10B).** Dominant at every scale; same ranking at every scale, consistent across 1000× budget variation.

   > **⚠ Correction (2026-08-30):** this finding originally read "24-27× … across all scales", which the table directly above it
   > contradicts. Recomputed from that table: 68.6/1.86 = **36.9×** (100M), 80.4/3.36 = **23.9×** (1B),
   > 90.2/3.39 = **26.6×** (10B), 104.4/7.22 = **14.5×** (100B) — a ≈14.5-36.9× spread, more than 2.5× wide,
   > with only the two middle scales falling inside 24-27×. The range is relabelled in place as a disclosed
   > correction because a claim its own table refutes cannot be left standing as the reader's takeaway.
   > **"Same ranking at every scale" was and remains true**, and the table itself is untouched. See the 2026-08-30 re-evaluation entry at the end of this file.
2. **#67 (mid-walk C3) is 86-95% redundant with #68.** Canonical-set intersection analysis at 1B and 10B:
   - At 1B: C3 adds 20,399 records, of which 17,575 (86%) are also added by C5 alone. C3 uniquely contributes 2,824 records.
   - At 10B: C3 adds 89,743 records, of which 85,373 (95%) are also added by C5 alone. C3 uniquely contributes 4,370 records.
3. **#70 (C3 optimistic-completion) is marginal** — +0.35% (100M) → +0.9% (1B) → +1.0% (10B) → +0.7% (100B) on top of v1+C5+C3.

### Sha gate (solution-preservation)

**v1 ⊆ every variant at 100% inclusion** at every scale measured (1B + 10B set-intersection analyses; structural at 100M + 100B per record counts). Every v2 prune is solution-preserving — no records lost, only added. Monotone subset chain: v1 ⊂ v1+C3 ⊂ v1+C5+C3 ⊂ v1+C5+C3+C3opt and v1 ⊂ v1+C5 ⊂ v1+C5+C3 ⊂ v1+C5+C3+C3opt.

### Sha reproduction sanity (built-in cross-checks)

Multiple variants reproduced previously-registered shas, validating methodology:
- 100M v1_baseline: `403f7202…` ✓ matches in-source documented selftest sha
- 100M v1_C5_only: `47dac6cb…` ✓ matches in-source documented
- 100M v1_C5_C3: `98b8c0ef…` ✓ matches in-source documented
- 100M v2 (current): `56487ab5…` ✓ matches current selftest baseline
- 100B v1_baseline: `f1709ab0…` ✓ matches commit 906f33b registered 100B canonical
- 100B v1_C5_only: `de28fea6…` ✓ matches commit 2ec4c30 registered 100B v2 sanity sha

### Why the gap grows sub-canonical, then collapses

- v2's record-count advantage over v1 GROWS with budget at sub-canonical scales (+73% at 100M → +122% at 100B), then COLLAPSES to +4.83% at 11.2T canonical.
- Interpretation: both v1's and v2's prune predicates are **sound** — neither drops a valid leaf — so both
  search the same tree of valid orderings and reach the same set at the limit: **v1(∞) = v2(∞) = v3(∞)** = the
  complete set of C1-C5 canonical orderings. What differs is **rate of convergence per node**: v2's more
  aggressive dead-branch pruning reaches records in fewer node visits. Every column in the table above,
  including the 11.2T "canonical" one, is a **budgeted** slice of that one shared limit set, so +4.83% at 11.2T
  is the budgeted-slice delta at 11.2T — not a larger solution space. At sub-canonical budgets v1 has explored a
  much smaller fraction of the shared tree, so v2's earlier budget-freeing yields proportionally MORE records;
  the gap narrows as budgets grow because both lineages converge on the same limit.

  > **⚠ Correction (2026-08-30):** this bullet originally reversed the repository's own semantics: it read the unlimited-budget regime as v1
  > and v2 exhausting *different* predicates, and called the 11.2T +4.83% v2's "real" extra solutions. That is
  > wrong on three counts and is contradicted by `CANONICAL_HASHES.md` §"v2 lineage — CLOSED 2026-05-24":
  > "v2's 'extra' records are NOT mathematically unreachable to v1 or v3 … At the limit,
  > v1(∞) = v2(∞) = v3(∞) = the complete set of all C1-C5 canonical orderings." (i) v2's additions come from
  > **sound prunes** (#68/#67/#70, per this entry's own ladder), and a sound *tighter* prune cannot enlarge the
  > exhaustion-limit set — it can only reach the same set sooner; (ii) the 11.2T "canonical" is itself BUDGETED
  > in every cell (`CANONICAL_HASHES.md` §"100B and sub-canonical reference shas": every realistic scale, 100B
  > through 560T, hits BUDGETED per cell), so +4.83% is the same finite-budget convergence-rate effect the
  > original text assigned to the unlimited-budget regime; (iii) this entry's own sha gate verifies record-set
  > **inclusion** — zero v1 records absent from v2 — which is a convergence-rate result, not a difference in what
  > either lineage accepts. Rewritten in place as a disclosed correction: left standing, it would have a reader
  > choose a lineage on a "larger solution space" premise the project's canonical doc explicitly denies.
  > **The measured table above is untouched** — only its interpretation was wrong. Read the "crossover budget"
  > bullet below in the same corrected light: there is no change of regime, only a gap that narrows as both
  > lineages converge. See the 2026-08-30 re-evaluation entry at the end of this file.
- The crossover budget (where v2's advantage drops from the sub-canonical regime into the unlimited-budget regime) sits between 100B and 11.2T. We did not measure intermediate points — would have required 1T+ benches, blocked by single-threaded in-memory merge bottleneck at 70M+ records.

### Implications for next prune candidates

- **#88 (tighter C5 predicate, post-#69)**: HIGH priority. C5 is the dominant prune; tightening it likely yields the largest incremental gain.
- **#89 (C2 as space prune, post-#69)**: orthogonal to C5 — different constraint dimension. Targets records OUTSIDE C5's reach, not refinement of C5's existing gains. Valuable for unlocking the next batch beyond what tighter-C5 can do.

### Cost

~$0.59 total compute (D8 Spot 1B + 10B + D128 Spot 100B; local 100M used claude orchestrator).

### Notes
- The chained D128 sweep was designed to include 1T scale, but the v1_C5_C3_C3opt variant's single-threaded in-memory merge of 70M pre-dedup records bottlenecked the run. 100B sweep completed in time; 1T phase pre-emptively killed to free schedule. The 4-scale data (100M → 100B) already establishes the convergence trajectory decisively.
- Detailed writeup with set-intersection numbers + cost breakdown + lineage diagrams: `roae-private/PER_PRUNE_ISOLATION_KPILOT_2026_05_18.md`.

---

## 2026-05-19 — task #47 huge pages: THP=always wins at canonical scale, hurts at small scale (no code change)

**Category**: env / OS knob (no code change)
**Sha impact**: none (sha-preserving across all 12 measured iters; same binary)
**Decision**: **THP=always (Ubuntu default) is correct for canonical-scale builds on D128.** Empirically validates that the existing default is right for the workload we ship on. No change required.

### Hypothesis
Transparent huge pages (THP) reduce TLB pressure on memory-bandwidth-bound workloads with large heap allocations. ROAE's per-thread hash table is 512 MB; at 128 threads on D128 that's 64 GB of randomly-accessed memory. Expected benefit at canonical scale: +3-10% wall.

### Methodology
- Same binary (v2-bundled HEAD, commit `25cbd06`), `cc -O2 -pthread -DNDEBUG`.
- Two-condition paired bench: `THP=always` vs `THP=never` via `/sys/kernel/mm/transparent_hugepage/enabled`.
- **Alternated condition ordering** (a-n-a-n-a-n) to factor out host-noise drift.
- Page-cache flush (`echo 3 > /proc/sys/vm/drop_caches`) between every iter.
- Two scales:
  - **D8 Spot, 1B full-enum depth-2, 5 iters per condition** (small workload).
  - **D128 Spot, 100B full-enum depth-2, 3 iters per condition** (canonical-equivalent). Preflight throttle probe HEALTHY 2718 MHz min.

### Result — D8 1B (small workload, 8-core, 4 GB total hash)

| Mode | n | median ms | mean ms | stdev ms | min | max |
|---|---|---:|---:|---:|---:|---:|
| THP=always | 5 | 56,431 | 58,691 | 13,415 | 43,601 | 80,531 |
| THP=never | 5 | 43,819 | 46,299 | 4,377 | 42,816 | 51,916 |

**Median Δ = +22.3% (THP=never faster).** THP=always has 3× higher variance with an 80s outlier — classic THP defragmentation noise on a small memory footprint with limited slack.

### Result — D128 100B (canonical-equivalent, 128-core, 64 GB total hash)

| Mode | n | median ms | mean ms | min | max |
|---|---|---:|---:|---:|---:|
| THP=always | 3 | 215,028 | 220,496 | 214,679 | 231,782 |
| THP=never | 3 | 263,170 | 257,936 | 246,914 | 263,723 |

**Median Δ = -22.4% (THP=never SLOWER).** THP=always wins decisively at canonical-equivalent scale; clean low-variance signal.

### Sha gate
- All 6 iters at D128 100B produced solutions.bin sha `8c35a854…` (matches the per-prune isolation pilot's `100B v1_C5_C3_C3opt` registration). Sha-preserving across THP toggle confirmed at canonical-equivalent scale.
- All 10 iters at D8 1B produced solutions.bin sha `fe98e58a…` (matches the per-prune isolation pilot's `1B v1_C5_C3_C3opt` registration). Sha-preserving at small scale confirmed.

### Interpretation
The scale-dependent reversal is real and explains why the small-scale measurement was misleading:
- At **small workload** (4 GB hash, 8 cores, 16 GB host RAM), THP allocation triggers compaction that costs more than its TLB benefit at this footprint. Memory slack is limited; fragmentation kicks in.
- At **canonical workload** (64 GB hash, 128 cores, 256 GB host RAM), TLB pressure on random hash-table accesses dominates. THP's 2 MB pages cut TLB miss rate massively; compaction cost amortizes across hours of work.

The empirical lesson: **always measure perf knobs at canonical-relevant scale.** A D8/1B pilot would have led to the WRONG operational decision (turn off THP for canonical, costing +22% wall).

### Cost
~$0.45 total: $0.05 D8 1B + $0.40 D128 100B. ~35 min wall.

### Notes
- No code change required. The Ubuntu 24.04 default (`THP=always`) is correct for v2-bundled canonical builds.
- Documenting this entry serves a future-reader purpose: when someone tries to "optimize" by disabling THP based on a small-scale microbenchmark, this entry stands as a warning.
- Bench scripts: `/tmp/hugepages_bench.sh` (D8), `/tmp/hugepages_d128_bench.sh` (D128). Logs in `/tmp/hugepages_*.log`.
- **Open follow-ups in the #47 CPU bundle**: jemalloc test (allocator swap, perf-only), NUMA-local allocation (matters more on dual-socket; D128als_v7 EPYC 9V45 is single-socket per VM topology so likely no-op). Both are sequel investigations.

---

## 2026-05-19 — task #47 jemalloc: NULL RESULT (allocator swap, no dependency added)

**Category**: env / allocator (no code or build change)
**Sha impact**: none (sha-preserving across all 6 measured iters)
**Decision**: **DO NOT ship libjemalloc dependency.** Empirically no significant speedup; jemalloc slightly slower than stock glibc on this workload.

### Hypothesis
jemalloc's per-arena isolation and lower fragmentation might benefit ROAE's 128-thread allocation pattern at canonical scale. Realistic prior: small or null effect — ROAE's allocation pattern is "few big stable mmaps" (512 MB hash table per thread, allocated once at thread start), not the "millions of small allocs" workload that jemalloc is engineered to win on.

### Methodology
- Same binary (v2-bundled HEAD `7ffe5d8`), `cc -O2 -pthread -DNDEBUG`.
- D128als_v7 Spot, throttle-probe HEALTHY (3077 MHz min).
- Two conditions paired and ALTERNATED (s-j-s-j-s-j) to factor out host-noise:
  - `stock` = unmodified launch (glibc ptmalloc2 default)
  - `jemalloc` = `LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2 ./solve ...`
- 100B full-enum depth-2, 3 iters per condition, page-cache flush between every iter.
- THP=always (Ubuntu default) for both conditions.

### Result

| Mode | n | median ms | mean ms | min | max |
|---|---|---:|---:|---:|---:|
| stock | 3 | 198,576 | 201,872 | 196,944 | 210,096 |
| jemalloc | 3 | 202,434 | 202,821 | 198,237 | 207,792 |

**Median Δ = +1.9% (jemalloc slower).** Ranges overlap; the difference is within run-to-run noise. No significant speedup.

### Sha gate
All 6 iters produced solutions.bin sha `8c35a854…` (matches the per-prune isolation pilot's `100B v1_C5_C3_C3opt` registration and the huge-pages bench's reproduction). Sha-preserving across allocator swap confirmed.

### Decision rationale
1. **No significant speedup** — even if positive, the operator standing rule requires "significant speedup AND no other path"; a 1.9% slowdown trivially fails both gates.
2. **Workload mismatch with jemalloc's strengths** — ROAE allocates a few large fixed regions once at startup; jemalloc's arena isolation and small-alloc fast paths offer nothing here.
3. **`LD_PRELOAD` is a workaround pattern** per operator memory `feedback_fix_root_cause_not_workaround` — canonical artifacts must ship on the stock toolchain, not on a preload shim. Even a positive result wouldn't be shippable in this form without a separate build-time integration task.

### Cost
~$0.40 D128 Spot Spot (~25 min wall).

### Notes
- This entry exists to bank the empirical null result so the question doesn't get re-litigated in a future "what about jemalloc?" thread. The workload pattern doesn't match jemalloc's design strengths; the bench confirms.
- Task #50 (Pre-AVX-512 jemalloc heap-corruption diagnostic LD_PRELOAD test) was a DIFFERENT investigation — diagnostic for correctness, not perf. That task completed; this one closes the perf question.
- **#47 CPU bundle remaining**: NUMA-local allocation check. D128als_v7 underlying EPYC 9V45 is exposed as a single NUMA node per VM (single-socket topology); the bench would likely confirm null. Lower priority.

---

## 2026-05-19 — task #47 NUMA: NULL RESULT (Linux first-touch already NUMA-local)

**Category**: env / NUMA policy (no code or build change)
**Sha impact**: none (sha-preserving across all 6 measured iters)
**Decision**: **No `numactl` wrapper required for canonical builds.** Linux default first-touch NUMA policy already achieves NUMA-local allocation for the solve.c workload pattern.

### Hypothesis
D128als_v7's underlying topology: hypothesis was "single NUMA node per VM (single-socket Azure exposure)." If true, NUMA-aware allocation would be a structural no-op. If multi-node, `numactl --interleave=all` might help by balancing 128-thread allocations across nodes vs Linux's default first-touch policy.

### Topology discovered
D128als_v7 actually exposes **2 NUMA nodes** under Ubuntu 24.04:
- node 0: cpus 0-63, 128.9 GB RAM
- node 1: cpus 64-127, 129.0 GB RAM
- node distances: 10/11 (typical local/remote ratio)

So the test was genuinely interesting — not the no-op the original hypothesis predicted.

### Methodology
- Same binary (v2-bundled HEAD `c78d1f3`), `cc -O2 -pthread -DNDEBUG`.
- D128als_v7 Spot, throttle preflight HEALTHY (3243 MHz min).
- Two-condition paired bench, alternated d-i-d-i-d-i:
  - `default` = unmodified launch (Linux first-touch policy)
  - `interleave` = `numactl --interleave=all ./solve` (round-robin allocations across both nodes)
- 100B full-enum depth-2, 3 iters per condition, page-cache flush between every iter.
- THP=always (Ubuntu default) for both conditions.

### Result

| Mode | n | median ms | mean ms | min | max |
|---|---|---:|---:|---:|---:|
| default | 3 | 193,823 | 193,885 | 192,810 | 195,021 |
| interleave | 3 | 194,922 | 195,151 | 192,298 | 198,232 |

**Median Δ = +0.6% (interleave slightly slower).** Within noise; ranges overlap. No significant speedup.

### Sha gate
All 6 iters produced solutions.bin sha `8c35a854…` (matches the per-prune isolation pilot's `100B v1_C5_C3_C3opt` registration and the huge-pages + jemalloc bench reproductions). Sha-preserving across NUMA policy change confirmed.

### Why null despite multi-node topology
solve.c's allocation pattern is "thread-per-core, allocate one large hash table per thread, never free." Linux's default first-touch policy gives:

1. Each thread is scheduled to a specific core (eventually pinned by OS load balancer).
2. The thread allocates its 512 MB hash table via `malloc/mmap`. Memory is reserved but not yet faulted-in.
3. On first write to a page, the kernel allocates the physical page on the NUMA node of the CURRENT thread.
4. Since the thread is on (typically) one node throughout its lifetime, all of its memory ends up on that local node.

With 128 threads spread evenly across 64+64 cores, the default-policy distribution is essentially 64 GB hash on node 0 + 64 GB on node 1 — the same balanced distribution that `--interleave=all` would force. So explicit interleaving has no benefit; the default is already NUMA-local.

**Workloads where `--interleave=all` would help** typically have:
- Frequent thread migration across NUMA nodes (e.g., dynamic work queues), OR
- A single large allocation accessed by all threads (which first-touches on one node and becomes "remote" for the rest)

solve.c has neither pattern. Each thread's hash table is private; threads don't share large data.

### Decision rationale
1. **No significant speedup** — operator standing rule requires significant + no-other-path; trivially fails.
2. **Adding numactl wrapper is a workaround pattern** (matches `feedback_fix_root_cause_not_workaround`) and shouldn't ship even if measurable.
3. **The structural reason is informative**: solve.c's design choices (per-thread private allocations, thread-per-core) already exploit NUMA locality implicitly. No further work needed.

### Cost
~$0.35 D128 Spot (~25 min wall, including topology probe and throttle preflight).

### Closes #47 entirely
With NUMA-local now measured, the CPU optimization bundle (task #47) is fully closed:

| Sub-item | Status | Engineered Δ |
|---|---|---|
| LTO (build flag) | DONE 2026-05-13 | **+2.53%** |
| PGO (build flag) | DONE 2026-05-18 | **+6.5%** |
| AVX-512 retool (#46) | CLOSED 2026-05-16 (NULL) | 0% (gcc autovec sufficient) |
| Huge pages (THP) | DONE 2026-05-19 (default validated) | 0% (default correct at canonical) |
| jemalloc | DONE 2026-05-19 (NULL, no dep) | 0% (workload mismatch) |
| NUMA-local | DONE 2026-05-19 (NULL, this entry) | 0% (Linux first-touch already NUMA-local) |

**Cumulative engineered speedup banked from the #47 bundle: ~+9.2% sha-preserving at canonical scale** (LTO ×1.0253 × PGO ×1.065 = ×1.092). All other items contributed zero. The CPU optimization surface for the canonical workload is fully explored at this point. *(Spoiler from 2026-05-25: this multiplicative composite did NOT replicate — measured ~0% over vanilla v1 at full-enum 1T. See "The +9.2% headline was multiplicative theory" below; the number is retracted as a forward-looking claim.)*

---

# Cumulative narrative — v1 → v2 → v2+PGO

The table below summarizes what's measured so far. Numbers in brackets are the entries above where the data comes from.

| Change | Perf delta | Sha impact | Decision |
|---|---|---|---|
| #72 bitset domain | +8.7% per-thread (1.09×) at 1B [#72] | preserving | shipped |
| #68 C5 feasibility | **+68.6% records at 100M** [#68] | forking (v2 lineage starts) | shipped |
| #67 mid-walk C3 | +1.86% records at 100M / +2.58% at 100B [#67] | forking | shipped |
| #70 C3 optimistic-completion | +0.35% records at 100M (over #67) [#70] | forking | shipped |
| #46 AVX-512 | **0.9963× ≈ zero (statistically null)** [#46] | preserving | **CLOSED — null result** |
| #71 C2 lookahead | **−10.7% — REVERTED** [#71] | preserving | NO-SHIP |
| LTO (v6d) | +2.53% per-thread [LTO] | preserving | shipped |
| #81 v2 11.2T re-baseline | +4.83% records at 11.2T [#81] | forking | shipped (new anchor) |
| #78 PGO | **+6.5% enum-only at 1T (v3 confirmed)** [#78 v3] | preserving (byte-identical sha verified at 1T + 1B) | shipped |
| #92 resume regression fix | correctness fix (no perf delta) [#92] | preserving for single-shot; resume now byte-identical | shipped commit `b684cca`; 2,824-cycle 1B validation PASS |
| #69 MRV fail-first | **K=0.770 at canonical-equivalent scale (100B); SHELVED** [#69] | forking (canonical-set disjoint at 100B) | **SHELVED** |

**Resolved gaps (this section was 5 TBDs before re-evaluation 2026-05-18; all closed by EOD):**
- AVX-512 (#46): closed at zero via commits `b26cd9b` (REVERT) and `0783d52` (definitive 1T bench).
- #68 perf delta: +68.6% records at 100M (from commit `bf58c65` body).
- #70 perf delta: +0.35% over #67 at 100M (from commit `7b5ff6d` body).
- Selftest sha ladder: verified directly against current build, matches the published canonical.
- **PGO 1T (#78)**: v3 rerun on confirmed-healthy host gives **6.5% speedup, byte-identical sha at 1T** (Build B and Build C both `f3a3e68c…`). PGO is sha-preserving and shippable. The 4.8% from the v2 retry was a lower bound on a less-validated host; 6.5% is the definitive number.

**Updated methodology rule (from v3 rerun)**:
- Mid-bench `/proc/cpuinfo` MHz is NOT a throttle indicator for solve.c (workload is memory-bound, runs cores at base-clock duty cycle regardless of host health). The only valid throttle probe is the 60s pure-CPU burn-in before bench start.

**Remaining known gaps:**
- #67 per-thread rate isolated from records-found delta — only records/budget measured.
- Merge-step wall times — captured during canonical runs but not standardized in PERFORMANCE_HISTORY format (the v3 PGO entry does capture them: 809s for Build B merge, 853s for Build C merge — comparable, no PGO impact on merge wall).
- 1T paired v1 vs v2-bundled wall comparison — Build A 1T (depth-2 recursive) gives 708s/162.6M; Build B 1T (v2 depth-3 iterative) gives 1067s/305.9M. Different depths confound clean wall comparison. Records-per-budget is the cleaner cross-build comparison: **1.88× more records per node-budget for v2**.

**Validated cumulative claim (v1 11.2T → v2 11.2T, same hardware):**
- Records found at 11.2T budget: 759.6M → 796.4M (**+4.83%**)
- Output sha: forked (`0c0fe37c…` → `2cc966e48399841ebb0c9ca67300f15bb578cc5481ed04fca5faffcb38ad6c4d`)
- Both shas reproducible at byte level; v1 ⊆ v2 inclusion verified at canonical level

**Speedup vs ship-decision matrix:**
- Pure speed (sha-preserving): #72 (+9%), AVX-512 (TBD), LTO (+2.5%), PGO (+4.8%) — all shippable, compose multiplicatively
- Budget efficiency (sha-forking): #67 (+2.6% records/budget), #68 + #70 (bundled in v2 +4.8% records/budget) — required new canonical anchor
- Rejected: #71 (-10.7% — instructive loss, kept in lineage as cautionary tale)

---

## 2026-05-24 — v1 vs v3 paired bench 1T — **PGO WAS NOT OPERATING** (entry under-measures v3's true advantage)

### Headline

**v3 measured 4.38% faster than v1 at 1T enum-only**, well below the +9.2% prediction. **The cause is NOT a regression in v3's speed claims — PGO did not apply during the v3 Pass 2 build.** Under `-flto`, GCC keys the `.gcda` profile-data lookup on the output binary's name; Pass 1 built to `solve_v3_instr` and Pass 2 built to `solve_v3` → different output names → Pass 2 missed the profile data → silent fallback to no-PGO with a single `-Wmissing-profile` warning. **The measured 4.38% therefore reflects LTO + bitset only, not LTO + PGO + bitset.** Sha-equivalence at 1T was preserved (both `5a0f0bc2…`); only the *speed* number is under-measured.

**Treat this entry as a known-under-measurement.** The +9.2% prediction from #47 closure still stands — it has not been falsified by this bench because PGO simply wasn't operating. Re-run with the fixed `scripts/build_pgo.sh` (shipped same day, commit `bab4be6`) is required for the true v3-vs-v1 speedup measurement. *(Spoiler from 2026-05-25: the +9.2% prediction was subsequently retracted — the combined stack measured ~0% over vanilla v1 at 1T. See "The +9.2% headline was multiplicative theory" below.)*

### Setup

- Standard D128als_v7 westus3 (operator-authorized exception to spot-only rule, for paired-measurement integrity)
- v1: commit `a2ead96`, `-O3 -pthread -fopenmp -march=native` (vanilla — no LTO, no PGO, no bitset)
- v3: commit `8b1658b`, `-O3 -flto -pthread -fopenmp -march=native + bitset (#72)` (PGO *intended* but did not apply — see below)
- 1T enum-only, 3 reps each binary, interleaved (v1, v3, v1, v3, v1, v3)
- Page cache cleared between reps (`sync` + `echo 3 > /proc/sys/vm/drop_caches`)
- `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=1000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=6315458 SOLVE_THREADS=128 SOLVE_SKIP_AUTOMERGE=1`

### Wall times (seconds)

| Rep | v1 | v3 (no PGO applied) | v3/v1 |
|---:|---:|---:|---:|
| 1 | 2770 | 2650 | 0.957 |
| 2 | 2717 | 2455 | 0.904 |
| 3 | 2766 | 2661 | 0.962 |
| **median** | **2766** | **2650** | **0.958 (v3 4.38% faster)** |

### Sha gate

```
v1 1T: 5a0f0bc24eb91b364169a13d0240ee0ff0fcf824dc829754d2254ec101fb8f52
v3 1T: 5a0f0bc24eb91b364169a13d0240ee0ff0fcf824dc829754d2254ec101fb8f52
```

**Byte-identical match.** Second empirical sha-preservation data point after Phase 11 Build A's 11.2T
`0c0fe37c…` match. PGO not applying did not change the sha here — the v1 and v3 1T shas printed above are
byte-identical. Every optimization-flag change measured in this log to date has preserved the sha; that is an
empirical record, not a guarantee that optimizer decisions cannot reach the sha.

> **⚠ Correction (2026-08-30):** this sentence originally read "sha is determined by prune predicates, not optimizer branch hints", which is
> an unsupportable universal in a solver whose canonical runs are BUDGETED in every cell. `CANONICAL_HASHES.md`
> §"100B and sub-canonical reference shas" documents a DFS-neutral commit (`d683794`) flipping the 100B sha via
> exactly this route — compiler layout perturbing OpenMP scheduling — and states the rule: "You cannot predict
> from source-reading whether a commit will flip 100B sha — only empirically." Reworded to the measured claim.
> **The byte-identical 1T match above stands as measured**, and it remains a genuine sha-preservation data
> point; what is withdrawn is the reasoning that made such a gate look unnecessary. See also the 2026-05-13 LTO
> entry's correction marker, and see the 2026-08-30 re-evaluation entry at the end of this file.

### PGO did NOT operate — direct evidence

The Pass 2 build emitted:

```
solve.c:13150:1: warning: '/home/solver/bench/pgo//home/solver/bench/solve_v3-solve.gcda' profile count data file not found [-Wmissing-profile]
```

That is the GCC diagnostic for "I looked for the profile-guided optimization data file at the expected path; it wasn't there; I compiled this translation unit without profile feedback." Combined with `-flto`, this means the entire program was built without PGO. The compiler produced a binary, completed the build successfully (no -Werror at the time), and selftest passed — but the binary has LTO + bitset only, not LTO + PGO + bitset.

### Why the path lookup missed

Under `-flto`, the GCC LTO recompile step embeds the output binary's basename in the `.gcda` lookup path. Pass 1 wrote profile data keyed on `solve_v3_instr`. Pass 2 looked up profile data keyed on `solve_v3`. Names differed → miss → silent no-PGO fallback.

### Fix shipped same day (`bab4be6`)

Three-part hardening landed to make this class of bug structurally impossible:

1. **`scripts/build_pgo.sh`** — canonical PGO build helper. Builds both passes to the SAME output name (renames after Pass 1), so the `.gcda` lookup key matches. Asserts `.gcda` file count > 0 between passes. Adds `-Werror=missing-profile` on Pass 2.

   > **⚠ Correction (2026-08-30):** **as of 2026-08-30 this helper can no longer build `solve.c`.** Both of its link lines — Pass 1 at
   > `scripts/build_pgo.sh:77-78` and Pass 2 at `:128-130` — end in `-lm` with no `-lz`, but `solve.c:317` has
   > included `<zlib.h>` since #169, and its own comment there says "link with `-lz`" (`DEVELOPMENT.md` marks
   > `-lz` mandatory in the canonical recipe too). Running the script's exact Pass-1 command against `solve.c`
   > at this commit fails at link: rc=1, undefined references to `gzclose`, `gzfread` and friends. The
   > `-Werror=missing-profile` safety described above is real and remains the right design — the helper simply
   > was not kept in step with `solve.c`'s dependencies. Adding `-lz` to both link lines edits
   > `scripts/build_pgo.sh` and is tracked outside this document; **until it lands, this entry is not a working
   > reusable PGO recipe.** See the 2026-08-30 re-evaluation entry at the end of this file.
2. **`scripts/perf_bench.sh`** — same discipline applied inline (runs over SSH so can't easily source the helper).
3. **`documentation/DEVELOPMENT.md`** — PGO bullet now points at `scripts/build_pgo.sh` as the build invariant.

The load-bearing safety is `-Werror=missing-profile`: any future change that breaks PGO path resolution now fails the build LOUD instead of degrading silently. A silent no-PGO build is now structurally impossible without someone explicitly removing the `-Werror=` flag.

### Reconciliation with the earlier #78 PGO entry

The earlier #78 entry (above) reports +6.5% from PGO at 1T on a clean LTO-only baseline. Current entry's 4.38% from v3 vs v1 with broken PGO is consistent with that decomposition:

- LTO contribution (#47 closure): +2.53%
- Bitset (#72) contribution at 1T: near-zero standalone perf delta (the +8.7% per-thread at 1B from #72 was at a smaller scale with different memory pressure; at 1T the per-thread rate gains are mostly absorbed by hash-table and merge bottlenecks)
- PGO contribution **at this bench**: **0%** (build bug)

So this bench's v3-vs-v1 delta of 4.38% ≈ LTO 2.53% + small residual gains from bitset + statistical variance. **Re-run with the fixed `build_pgo.sh` is needed to validate the predicted +9.2% LTO+PGO+bitset stack.**

### Cost

- Bench: ~$30 (Standard D128als_v7 × ~6.5h wall, including PGO Pass 1 instrumented run + Pass 2 build)
- 1T canonical archive bytes: 475 MB gzip -9 (cold + managed + local)

### 1T canonical established as a byproduct (5a0f0bc2…)

The bench produced the first 1T canonical entry in the cold archive (sha `5a0f0bc24eb91b364169a13d0240ee0ff0fcf824dc829754d2254ec101fb8f52`, 134,039,081 records). Bridges the gap between the 100B and 5.6T entries that previously bracketed the d3 lineage. Reproducible from either v1 or v3 binary at `SOLVE_PER_SUB_BRANCH_LIMIT=6315458` (see [CANONICAL_HASHES.md](CANONICAL_HASHES.md)).

---

## 2026-05-24 — v3.1 fast-skip eviction-recovery wall (task #95)

Not a perf entry in the traditional sense (no sha-changing optimization), but a wall-time measurement of the eviction-recovery code path that the 560T campaign will depend on. Logged here for the perf-narrative reader who wants the full operational picture.

**Headline:** v3.1's `promote_orphaned_shards` + `checkpoint.txt`-based resume restored a 100B-scale enum from administrative deallocate (Spot-eviction-equivalent) in **~2:14 wall time**, dominated by VM restart overhead (1:44). The fast-skip claim itself is effectively instant (sub-second). Architectural prediction was ~15 min; measured is well under.

**Decisive log evidence** (resume after deallocate):
```
Resuming: 83476 sub-branches already completed (from checkpoint.txt)
Sub-branches: 74888 remaining (83476 completed from checkpoint) of 158364 total
...
Sub-branch 83477/158364 BUDGETED ... 0s
```

**Recovery breakdown:**
- `az vm deallocate` → done: 62s
- `az vm start` → "running": 42s
- workload re-invocation → solve startup: ~10s
- solve fast-skip claim from `checkpoint.txt`: ~0s
- First post-eviction sub-branch enumerated: ~2s

**What this validates:**
- `promote_orphaned_shards()` (v3.1 patch) correctly identifies completed shards.
- `checkpoint.txt` (12 MB at 100B scale, ~100 MB at 100T projected) is the sole resume input — no slow shard-file scan needed.
- Recovery is scale-invariant — wall time scales with checkpoint parse, not shard count.
- Graceful SIGTERM gives solve enough time to flush in-flight shards (27,008 → 29,588 between deallocate and process exit).

**What this does NOT test:**
- Real Azure Spot eviction (the 30s eviction-notice path is similar but not identical to administrative deallocate).
- Mid-walk resume via `DFSStackFrame_v2 + mw_delta` (#92) — this test caught all in-flight sub-branches in the graceful drain.

**Cost:** ~$0.10 (~30 min on D32als_v7 Spot).

---

## 2026-05-24 (re-run) — v1 vs v3 paired bench 1T with PGO ACTUALLY APPLIED — speedup did NOT replicate

### Headline

After fixing the silent no-PGO build bug in the prior 2026-05-24 bench (see `scripts/build_pgo.sh` shipped in commit `bab4be6` + `-Werror=missing-profile` discipline), a re-run on Standard D128als_v7 westus3 measured **v3 0.5% SLOWER than v1** (median wall, 3 reps each interleaved). The **+9.2% prediction from task #47 closure does NOT replicate at 1T canonical scale on Bergamo Zen 4c.** Sha-equivalence preserved.

This entry is a course-correction on the earlier `#78 PGO` entry (+6.5%) and the broken-PGO entry's interpretation: those measurements were on the 2-core `claude` orchestrator (Skylake) at small workload — they do not generalize to canonical-scale workloads on 128-core Bergamo.

### Build provenance (confirms PGO applied this time)

| Aspect | First bench (broken PGO) | This re-run (PGO applied) |
|---|---|---|
| v3 binary sha256 | `0d10944dda…` | `4ad70a0fb9…` (different — different optimizer decisions) |
| v3 binary size | 305 KB (no PGO data) | **254 KB** (smaller — PGO inlining + cold-path elimination) |
| `-Werror=missing-profile` set? | No | Yes (build would have failed if PGO data missing) |
| Build outcome | `-Wmissing-profile` WARNING (silent fallback) | Built cleanly, PGO data found |
| Selftest sha | `403f7202…` PASS | `403f7202…` PASS |

### Wall times (seconds, enum-only)

| Rep | v1 (vanilla -O3) | v3 (LTO + PGO + bitset) | v3/v1 |
|---:|---:|---:|---:|
| 1 | 2265 | 2587 | 1.142 (v3 14.2% slower) |
| 2 | 2370 | 2247 | 0.948 (v3 5.2% faster) |
| 3 | 2298 | 2310 | 1.005 (v3 0.5% slower) |
| **median** | **2298** | **2310** | **1.005 (v3 0.5% slower)** |

### Within-bench variance

- v1: spread 105s (4.6%)
- v3: spread **340s (15.1%)** — much noisier; PGO-optimized inner loops appear more sensitive to neighbor-induced cache pressure on shared Spot hosts

### Sha gate

v3 PGO build at 1T sha256: `5a0f0bc24eb91b364169a13d0240ee0ff0fcf824dc829754d2254ec101fb8f52`
Expected: `5a0f0bc24eb91b364169a13d0240ee0ff0fcf824dc829754d2254ec101fb8f52`
**MATCH** — PGO is correctness-preserving as expected. PGO affects optimizer branch hints, not algorithmic output.

### Why the prediction didn't replicate

1. **Task #47's +6.5% was on a 2-core Skylake at microbench scale.** Branch-prediction wins from PGO are largest when single-thread instruction throughput is the bottleneck. At 128-thread Bergamo on a memory-bandwidth-bound 1T workload, that bottleneck is gone — memory subsystem dominates.

2. **PGO trained on a 1B-node workload with 6315 nodes/sub-branch** hot-paths the budget-bound exit code. The 1T canonical workload has 6,315,458 nodes/sub-branch — 1000× more time in the actual DFS enumeration loop, which the profile-gen didn't exercise.

3. **The puzzle**: yesterday's broken-PGO bench (LTO + bitset only, no PGO data applied) showed v3 +4.4% faster than v1. Today's working-PGO bench shows v3 0.5% slower. **Adding actual PGO data appears to have slightly hurt rather than helped vs LTO + bitset alone.** Two possible reads: (a) PGO at the wrong scale optimizes the wrong hot paths and produces marginally worse code; (b) host-to-host variance (~15% within v3 reps) dominates the signal and the difference is in the noise.

### Implications for shipping decisions

| Build flavor | Measured at canonical | Decision |
|---|---|---|
| Vanilla `-O3 -march=native` (v1) | baseline | reference |
| LTO + bitset (yesterday's bench, broken PGO) | +4.4% faster | **measurable improvement** |
| LTO + PGO + bitset (this bench) | 0.5% SLOWER | no improvement; PGO is net-zero-or-negative at this scale |

**Recommendation for 560T**: build with **LTO + bitset, no PGO**. Saves ~100 min of PGO build wall per VM provisioning, simpler build, and the +4.4% LTO+bitset advantage is the actual measurable win. The earlier "v3 ~9.2% faster" claim was a microbench artifact; the real canonical-scale speedup is +4.4%.

### Cost

- This re-run: ~$30 (Standard D128als_v7 × 5.8h wall, including PGO Pass 1 instrumented profile-gen run)
- Combined PGO investigation across both benches: ~$60
- Real finding: build-recipe hardening (`scripts/build_pgo.sh` + `-Werror=missing-profile`) is shipped and tested, even if PGO itself turns out net-zero — the hardening prevents future silent no-PGO regressions.

### Open questions for follow-up

1. Would a 1T-scale profile-gen workload (instead of 1B) train PGO closer to canonical hot paths and recover the predicted speedup? Cost to test: ~2× the current bench (~$60). Defer until needed.
2. Does PGO show net-positive at intermediate scales (10B-100B)? Untested at full-enum scale; the #78 v3 rerun was at `--branch 24 0`, not full-enum `0 128`.
3. What's the within-bench variance ceiling on Bergamo Spot? The 15% spread observed here suggests any future ~5% perf claim needs 6+ reps to be statistically defensible.

---

## 2026-05-25 — Methodological audit: the +9.2% headline was a computed product, never directly measured

This entry is a course-correction prompted by operator question "where did the 9.2% come from" after the 2026-05-24 (re-run) bench showed v3 ~0% over v1. It's not a new bench — it's a provenance audit of the prior claim.

### The +9.2% headline was multiplicative theory

From the `Closes #47 entirely` section above:

```
Cumulative engineered speedup banked from the #47 bundle: ~+9.2% sha-preserving at canonical scale
(LTO ×1.0253 × PGO ×1.065 = ×1.092)
```

The +9.2% was **never directly measured** as a combined stack. It was the product of two independent measurements taken on different workloads at different times. The assumption was that LTO and PGO compose multiplicatively with no overlap or diminishing returns. **That assumption was not empirically validated until the 2026-05-24 re-run bench**, which found the combined stack measures ~0% over vanilla v1 at full-enum 1T scale.

### Provenance of the two inputs

**LTO +2.53% (2026-05-13 entry above):**
- Methodology field says "Paired bench: v6c (no LTO) vs v6d (LTO) **at unspecified scale**"
- Notes field admits: "Backfilled from operator memory entry `feedback_canonical_pipeline_pattern`; **exact bench parameters not recorded in HISTORY.md**"
- **Weak provenance.** We don't know if the +2.53% was measured at 1B, 1T, single-branch, or full-enum. The "added to canonical build recipe" decision was likely correct (LTO is essentially free); the specific +2.53% number is not robustly anchored.

**PGO +6.5% (2026-05-18 #78 v3 rerun entry above):**
- Methodology was rigorous: page-cache flush between paired runs, pre-flight throttle probe required 3664+ MHz (verified 3868 MHz on a healthy host), paired enum-only walls captured separately from merge.
- **Scope**: Build N (LTO control, no PGO) vs Build U (LTO + PGO). Workload: `--branch 24 0` at 1T budget. Single first-level branch, NOT full enum.
- **What the +6.5% actually means**: "PGO contributes +6.5% on top of LTO at single-branch 1T on a verified-healthy Bergamo host."
- **What it does NOT mean**: that PGO contributes +6.5% to a full-enum canonical workload, or that the host quality is reproducible across Spot allocations.

### What the 2026-05-24 (re-run) bench actually tested

Different experiment from #78:

| Aspect | #78 PGO bench (+6.5%) | 2026-05-24 re-run (~0%) |
|---|---|---|
| Baseline | `-O3 -flto -march=native` (LTO control) | `-O3 -march=native` (vanilla, **no LTO**) |
| Treatment | LTO + PGO | LTO + PGO + bitset (#72) |
| Workload | `--branch 24 0` (single branch at 1T) | `0 128` (full enum, all 158k sub-branches at 1T) |
| Pre-flight throttle probe | Required 3664+ MHz; verified 3868 | **None done** |
| Reps | Paired 1 vs 1 with page-cache flush | 3 vs 3 interleaved with page-cache flush |
| Within-bench variance | Not characterized (single pair) | v1: 4.6%; v3: 15.1% |

The two benches answer different questions. They are not strictly contradictory; they cover non-overlapping experimental setups.

### Most likely reasons the +9.2% didn't replicate

In rough order of explanatory power:

1. **No throttle probe.** The #78 bench *explicitly aborted* if host MHz fell below 3664. The 2026-05-24 re-run skipped this gate. The 15.1% within-bench v3 variance is consistent with a noisy or throttled host. PGO's instruction-cache-tuning hints don't pay off on hardware that's already constrained.
2. **Workload mismatch.** PGO trained on a 1B-node workload with `SOLVE_PER_SUB_BRANCH_LIMIT=6315` (hot-paths the budget-bound exit code). The 1T canonical workload has `SOLVE_PER_SUB_BRANCH_LIMIT=6,315,458` — 1000× more time in the actual DFS hot path that PGO didn't train on.
3. **Combined-vs-isolated baseline.** #78 measured PGO vs LTO-alone. The 2026-05-24 re-run measured (LTO + PGO + bitset) vs vanilla `-O3`. These tell us about different things; the latter is what 560T cost predictions actually need.
4. **LTO baseline overstated.** If the published LTO +2.53% was measured at a different scale than full-enum 1T, the canonical-scale LTO contribution may be smaller (or zero), and the +9.2% stack would collapse correspondingly.

### Lessons for future perf claims

1. **A measured A vs A+X delta is not transitively a measured A vs A+X+Y delta.** Always test the combined stack directly before claiming the headline number. (Or label the claim as "predicted multiplicative composite" and don't bank on it.)
2. **Record bench scale + parameters in every PERFORMANCE_HISTORY entry.** "At unspecified scale" is not adequate. The LTO entry's missing parameters made the +2.53% impossible to re-validate without re-running.
3. **Pre-flight throttle probe is load-bearing.** When #78 included it, the result was clean. When the 2026-05-24 re-run skipped it, the 15% variance made the signal indecipherable from noise.
4. **3 reps is underpowered for ~5% effects on Spot Bergamo.** Variance is ~15% in some conditions. Future paired benches that need ≤10% precision should plan 6+ reps or use Standard pricing on a verified-healthy host.

### What this means for the canonical build recipe

- **LTO**: keep it. It's free at build time, no measured downside, and even if the +2.53% was overstated, the canonical pipeline pattern (`feedback_canonical_pipeline_pattern`) bakes it in as default.
- **bitset (#72)**: keep it. Measured +8.7% per-thread at 1B; even if that doesn't fully transfer to 1T, the broken-PGO bench yesterday (LTO + bitset only) measured +4.4% over vanilla v1 — that's the closest direct measurement of the LTO+bitset stack.
- **PGO**: **drop from the 560T build** unless a future bench with throttle probe + 6+ reps + canonical-scale profile-gen demonstrates a measurable advantage. Saves ~100 min profile-gen wall per VM provisioning at no measurable cost.
- **The build-recipe hardening (`scripts/build_pgo.sh` + `-Werror=missing-profile`) remains shipped.** It prevents future silent no-PGO regressions if/when PGO is re-enabled.

### Decision

The +9.2% headline is retracted as a forward-looking claim. The records-per-dollar analysis and any 560T cost projections that depended on +9.2% should be updated to reflect:

- Empirical: v3 (LTO + bitset, no PGO) measures ~+4.4% over vanilla v1 at full-enum 1T (broken-PGO bench result, which incidentally measured exactly that stack).
- Empirical: v3 (LTO + PGO + bitset) measures ~0% over vanilla v1 at full-enum 1T (working-PGO bench result).
- Theoretical with caveats: the +6.5% PGO and +2.53% LTO numbers from prior benches stand for their specific experimental setups (single-branch + LTO-baseline + healthy host). They do not generalize to the canonical full-enum workload.

---

## 2026-05-27 — task #106/#108: per-thread checkpoint files eliminate checkpoint_mutex contention (~2× canonical wall reduction)

**Category**: mechanism (synchronization elimination, hot-path mutex removal)
**Sha impact**: preserving (at the c72eada 1T anchor; see drift note below for the v3-BRANCH→c72eada layout drift)
**Decision**: shipped

### Hypothesis

`checkpoint_mutex` serializes per-sub-branch metadata write at depth-3 canonical scale. Profile #106 (5-min perf record + iostat + thread-state samples, D128als_v7 Spot 2026-05-26) found 96+ of 128 threads in `futex_do_wait` per snapshot at ~35% CPU utilization with the solver-data Standard HDD at 64–69% util (not I/O-bound; mutex-bound). Hypothesis: replace the shared `checkpoint.txt` append + mutex with per-thread `checkpoint_t<tid>.txt` files + atomic counter for `total_sub_complete` + rate-limited progress write. Expected ~2× wall reduction at canonical scale by eliminating the serialization tax.

### Methodology
- Workload (perf bench): Phase-B-equivalent enum, SOLVE_PER_SUB_BRANCH_LIMIT=35,361,598 (matches 5.6T canonical per-cell budget), 128 threads, 5-min steady-state throughput measurement
- Workload (1T canonical sha gate): SOLVE_NODE_LIMIT=1,000,000,000,000, SOLVE_THREADS=128, default checkpoint flags
- Hardware: D128als_v7 Spot westus3 (`bench-per-thread` 2026-05-26 perf bench; `t108-validation` 2026-05-27 sha gate)
- Build: `-O3 -g -march=native -flto -pthread -fopenmp` (LTO + bitset, no PGO)
- Repetitions: 1 (perf bench at canonical scale; sha gate is deterministic by design)
- See `roae-private/scripts/bench_per_thread_checkpoint/` (perf bench), `roae-private/scripts/t108_validation/` (sha gate)

### Result (perf at canonical scale)
- CPU utilization (5 top samples avg): **35% → ~95.3%** (12200/12800 cores active vs 35% baseline pre-#108)
- Load avg (1-min): **128.17** (full saturation)
- Sub-branch throughput: **~28 → 40.05 sub-branches/sec** (+43% direct measurement)
- Per-thread checkpoint files written: 128 (one per worker thread; mechanism confirmed)

### Result (1T canonical sha gate)
- 1T enum wall on c72eada + #108 bundle: 1679s (default mode) / 1693s (SOLVE_FSYNC_BATCH_SIZE=16)
- 1T enum wall on unmodified c72eada (drift isolation control): 3430s
- Bundle's 1T sha: `74d3976061e015a3120d1ae11992f8662c97b59059ac69c61a5bff5edf146327`
- Unmodified c72eada's 1T sha: `74d3976061e015a3120d1ae11992f8662c97b59059ac69c61a5bff5edf146327` (IDENTICAL — #108 confirmed sha-equivalent to current main HEAD at 1T)
- Note on anchor drift: this `74d39760…` is NOT the 2026-05-24 v3 BRANCH 1T anchor `5a0f0bc24eb9…`. The drift was introduced by one or more of the 7 hardening commits between `9f10f05` (v3 reset) and `c72eada` (current main HEAD), via the same LTO-layout mechanism #99 100B bisect identified for `d683794`. #108 is innocent of this drift; the drift is in `c72eada` itself. See `project_1T_anchor_drifted_c72eada` (private memory) + `V3_RESET_LOST_COMMITS_AUDIT_2026_05_27.md` (private docs).

  > **⚠ Correction (2026-08-30):** **the attribution in the bullet above was refuted by the project's own follow-up and is withdrawn.** Task
  > #108's drift investigation, recorded in `HISTORY.md` §"May 27/28, 2026 UTC — Task #110 Tier 1
  > canonical-determinism hardening" (and in private memory `project_1T_anchor_drifted_c72eada`), established
  > that the 1T drift `5a0f0bc2…` → `74d39760…` is **host-environment-level** — gcc/glibc/kernel patch
  > versions, ASLR seed, CPU microcode revision — **not source-level**. Two specific legs of the bullet above
  > are dead: **the 7 hardening commits between `9f10f05` and `c72eada` were empirically exonerated**, and
  > **LTO was empirically ruled out as the mechanism** (`-fno-lto` reproduced `74d39760…` exactly, and
  > byte-identical source re-drifted across host-days). The drift is BUDGETED-cell-density-sensitive: it fires
  > at 1T's 6.3M nodes/cell and is absorbed at 11.2T's 70.7M, where anchor `0c0fe37c…` reproduced
  > byte-identically on `c72eada`+#108. Because the mechanism cannot be eliminated at compile time, #110 shipped
  > operational drift management instead — a host-fingerprint sidecar plus `./solve --validate-canonical`.
  > **What still stands:** the bundle's 1T sha is identical to unmodified `c72eada`'s, so #108 really is
  > sha-equivalent at 1T, and this `74d39760…` really is not the v3 BRANCH anchor. What is withdrawn is *why*.
  > See the 2026-08-30 re-evaluation entry at the end of this file.

  > **⚠ Second correction (2026-09-04):** *the correction above is itself withdrawn in its mechanism.* It
  > replaced "LTO layout" with "host-environment-level" without comparing the two runs' per-cell budgets, both
  > of which had been recorded since 2026-05-27: the #108 bundle and the unmodified-`c72eada` control both ran
  > with the budget **auto-divided** to 6,314,566 (`final_budget_distribution {"6314566": 51578}` in both
  > provenance files), while the 2026-05-24 run that set `5a0f0bc2…` used the published
  > `SOLVE_PER_SUB_BRANCH_LIMIT=6315458`. On 2026-09-04 one binary built from unmodified `main` `82f96b6b`
  > reproduced each value at its own budget, on one host, in one hour — 892 nodes per cell, 11,921 records,
  > 381,472 bytes. **What still stands from both earlier versions:** the bundle's 1T sha equals the control's,
  > so #108 really is sha-equivalent at 1T — that comparison used the same budget on both sides and is sound.
  > **Withdrawn:** "host-environment-level", "BUDGETED-cell-density-sensitive", and "the mechanism cannot be
  > eliminated at compile time" as statements about the 1T pair. This is the **second** correction of this
  > fact, not a discovery. See the 2026-09-04 re-evaluation entry at the end of this file and
  > `CORRECTIONS.md` §"2026-09-04 — the 1T anchor pair was two per-cell budgets".

### Delta vs baseline
- Per-thread CPU-on-DFS at canonical scale: **~+170%** (35% → 95%)
- 1T enum wall: **3430s → 1679s** = **2.04× faster** (matches the hypothesis prediction)
- enum_wall (5.6T canonical, predicted): 11.4d → ~5.6d on D128 Spot per 35→95% util ratio. Confirmed by 1T extrapolation. **560T projection: ~$577 saved per run.**
- sha changed: no (sha-equivalent to current c72eada main HEAD at 1T)

### Sha gate
- result: PASS
- --selftest sha `403f7202…` preserved (4 separate builds: locally + on VM, post-each-bundle-step, all 4 parts together)
- --selftest-resume PASS on bundle (resume sha = single-shot sha = `e43f2905…`, matches historical reference)
- 1T canonical default mode sha = `74d39760…` (matches c72eada baseline) — ⚠ [2026-09-04: "canonical" here means the **auto-divided** per-cell budget 6,314,566, not the published recipe 6,315,458; the published-recipe 1T anchor is `5a0f0bc2…`. See the second correction above.]
- 1T canonical SOLVE_FSYNC_BATCH_SIZE=16 sha = `74d39760…` (matches; #108b batched fsync sha-neutral at canonical scale) — ⚠ [2026-09-04: same auto-divided budget as the line above; the sha-neutrality result is unaffected, both sides used 6,314,566.]

### Notes
This commit bundles four pieces, all sha-neutral relative to unmodified `c72eada`:

1. **#108 (per-thread checkpoint files)** — the headline mutex elimination, hot-path change.
2. **#108b (opt-in fsync batching)** — `SOLVE_FSYNC_BATCH_SIZE` env var (default 1 = legacy per-write fsync, byte-identical to pre-#108b; >1 = per-thread `syncfs()` once per N sub-branches). Reduces canonical fsync count ~16× when enabled. Recommended for 560T (~50h saved on HDD).
3. **Restore SOLVE_SKIP_AUTOMERGE** (was `52cac4a` 2026-05-13, lost in 9f10f05 v3 reset) — env var for the canonical pipeline split-enum-merge pattern. Critical for any ≥11.2T canonical per `feedback_canonical_pipeline_no_exceptions`. Was silently no-op'd for 2 weeks until #108 validation surfaced the gap.
4. **Restore --selftest-resume** (was `d683794` 2026-05-15, lost in 9f10f05 v3 reset) — CI gate per `feedback_checkpoint_format_merge_gate`. PHASE_A 50M → PHASE_B 200M (resume) vs single-shot 200M sha-compare. The `#92` `mw_delta` fix is NOT restored because that fix was for #67 mid-walk C3 pruning which was intentionally dropped in v3 reset.

Also restores two diagnostic subcommands (sha-neutral by construction; not bench-relevant):
- `--cpu-features` (was `11ba190` 2026-05-15, lost in v3 reset)
- `--cpu-freq` (was `324318b` 2026-05-16, lost in v3 reset)

See:
- `roae-private/TASK_106_PROFILE_DEPTH3_BOTTLENECK_2026_05_26.md` — profile that motivated the work
- `roae-private/TASK_108_BENCH_RESULTS_2026_05_26.md` — perf bench results
- `roae-private/TASK_108_FINAL_REPORT_2026_05_27.md` — bundle composition, validation, drift finding
- `roae-private/V3_RESET_LOST_COMMITS_AUDIT_2026_05_27.md` — audit of what 9f10f05 dropped

## 2026-06-21 — #167: eviction-resume write-order fix + resume guard + #165 kill hook (commit pending)

**Category**: regression (correctness) / mechanism
**Sha impact**: preserving
**Decision**: shipped (WORK-IN-PROGRESS — canonical sign-off pending)

### Hypothesis
A correctness fix for eviction-resume data loss (the `.dfs_state` checkpoint was made durable before its `.bin`
shard). Expected to be **performance-neutral and sha-neutral**: the write-order reorder and the resume-side
guard are per-cell finalization / resume-path code (not the DFS inner loop), and the only inner-loop touch is a
single guarded compare (`SOLVE_KILL_AFTER_NODES` test hook) that is always-false (no-op) when the env var is
unset, which it always is in production.

### Methodology
- Workload: `--selftest` (full small enum+merge); full clean enum at PSB=50000 / 16-thread (46,344 shards);
  multi-thread kill+resume reproduction.
- Hardware: D16als_v7 Spot westus2 (gcc 11.4) for validation; D128als_v7 westus3 (gcc 13.3) selftest.
- Build: `gcc -O3 -flto -pthread -fopenmp -march=native -o solve solve.c -lm -lz`, solve.c with the fix.
- Repetitions: selftest + a full clean run (paired vs stock).

### Result / Delta vs baseline
- **Sha: UNCHANGED.** `--selftest` = `403f7202…` on both stock and fixed (two toolchains). Full clean run
  reproduced the stock clean sha byte-identically (`95c2f8f0…`, 46,344 shards). → **sha-preserving confirmed.**
- enum_wall: no measurable change (formal `perf_bench.sh` paired timing **deferred to the canonical sign-off**;
  the inner-loop delta is one predictable always-false compare, perf-neutral by construction).
- Eviction-resume correctness: stock lost cells (1/3 kill trials); fixed = 0/N; deterministic CASE-D recovery PASS.

### Sha gate
- selftest `403f7202…` PASS (stock == fixed). Canonical-scale gate = 11.2T eviction-resume → `0c0fe37c`
  **IN PROGRESS** (Phase 1 of the 560T diagnosis campaign).

> **⚠ Status re-evaluation (2026-08-30):** the canonical gate marked IN PROGRESS above has since **completed, PASS**. `HISTORY.md` §"June 22-23, 2026 —
> 560T re-run launched on the fixed solver (eviction-resume bug)" records the #167 fix's canonical-scale
> validation ahead of that relaunch: 11.2T single- and multi-eviction reproductions of `0c0fe37c`, a 1T launcher
> smoke, and an **eviction-injected 11.2T dress rehearsal that reproduced `0c0fe37c` byte-for-byte through 2 real
> Spot evictions on the production engine**. The "WIP entry" framing in the Notes below is therefore stale for
> the sha gate. The formal `perf_bench.sh` paired timing that the entry also defers was **not** verified as
> having run by this 2026-08-30 pass — treat it as still outstanding.

### Notes
WIP entry — pushed as work-in-progress per operator direction. Formal `perf_bench.sh` paired benchmark + the
11.2T canonical sign-off are the remaining gates; this entry will be finalized when they complete. Full detail:
`roae-private/INCIDENT_167_RESUME_SHA_MISMATCH.md`, `PATCH_167_eviction_resume_fix.diff`.

## 2026-07-09 — #223: f1c5 OOC per-block-gzip layer format + intra-layer checkpoint (merge of `f1c5-gzip-retool`)

**Category**: mechanism (out-of-core **f1c5 exact-count** path — NOT the enumeration DFS/merge hot path)
**Sha impact**: preserving
**Decision**: shipped (merged `f1c5-gzip-retool` → `main`)

### Hypothesis
The f1c5 exact-count out-of-core DP (`--f1-exact-c1c2c4c5 --f1-out-of-core`) wrote raw per-layer files that
dominate disk (~8 TB at n=31) and could not survive a Spot eviction mid-layer. Adding (a) a **per-block gzip
layer format (v2)** with a kidx/vidx seek index and (b) an **intra-layer chunk-boundary checkpoint**
(`f1c5_build.ckpt`, CRC32-guarded, ~5-min cadence) should shrink disk + I/O and make the multi-day count
eviction-resilient — **without changing the computed count** (the DP is deterministic).

### Methodology
- Workload: f1c5 exact count at n=24/27/28 (byte-identical v1-raw vs v2-gzip) + the live n=31 canonical run.

> **⚠ Status re-evaluation (2026-08-30):** the "live n=31 canonical run" referenced here and again under Result **completed on 2026-07-16**. See
> `runs/20260716_f1c5_c1c2c4c5_d128westus3/README.md` — "Completed run 2026-07-16 (landed ~06:18 UTC)" — the
> reproducibility record for the flagship exact count reported in TR-11 §9. Read "live" in this entry as "in
> flight at the time of writing", not as a currently-running job.
- Hardware: D16/D64als_v7 Spot westus3.
- Build: `gcc -O3 -g -march=native -flto -pthread -fopenmp`; merged solve.c.
- gzip level A/B: single-instance real-scale, n=27 layer 11 (~789 MB) at levels 1 / 6 / 9.
- Kill-resume: 60+ clean chunk-boundary kills + **15/15 real-random-timing SIGKILLs**, all byte-identical resume.

### Result / f1c5-specific perf (enumeration metrics N/A — separate subsystem)
- gzip level: **L1 = 953 s / 881 MB · L6 = 1002 s / 789 MB · L9 = 2071 s / 767 MB** → L9 is ~2× slower for ~3%
  smaller. **Embedded default = 6** (a −9 default was tried, commit `6465418`, then reversed, `c810600`).
- Compression (live n=31): ~12–16× on the layer data; disk footprint projecting **< 1 TB** vs ~8 TB raw.
- The count DP is **compute-bound** (layer wall ≈ count time; gzip/I-O negligible) → this is a
  disk/cost/eviction-resilience win, **not a speed change** to the count.
- **Level-invariant**: identical count at gzip levels 1 / 6 / 9.

### Sha gate — PRESERVING
- `--selftest` sha prefix `403f7202`: **UNCHANGED** (the f1c5 OOC path is separate from enumeration; the retool
  is sha-neutral for `solutions.bin`).
- f1c5 count **byte-identical v1(raw) == v2(gzip)** at n=24 / 27 / 28.
- Merge with main's `--c3-dist`: **non-overlapping** solve.c regions, auto-merged clean.

### Notes
*Naming note (added 2026-07-22): "gzip" throughout this entry — the branch name, the env names, and the
level A/B — is project shorthand. The v2 layer codec is per-block RFC-1950 **zlib** (`compress2`/
`uncompress`), not gzip-framed `.gz`; see documentation/F1C5_LAYER_FORMAT.md. Identifiers keep their
historical names; measurements are unaffected.*
New env/CLI surface (see SOLVE_C_CLI.md): `SOLVE_F1_OOC_FORMAT=v2`, `SOLVE_F1_OOC_GZIP_LEVEL` (default 6),
`SOLVE_F1_OOC_SCRATCH_MB`, `SOLVE_F1_OOC_READ_MB`, `SOLVE_F1_CKPT_SEC` (default 300 s), `--resume-from-layers`.
Full validation + measurement detail: `roae-private/RETOOL_DESIGN_2026_07_07.md`,
`OVERNIGHT_SUMMARY_2026_07_08.md`.

---

## 2026-08-30 — re-evaluation: eleven corrections to earlier entries (no code change, no new measurement)

**Category**: re-evaluation (append-only correction entry — see the contract at the top of this file)
**Sha impact**: none — no code, build recipe, or canonical artifact changes here
**Decision**: corrections landed as dated `⚠ Correction` markers against the entries below; two script defects
and one cross-document gap are recorded here but must be fixed in their own files

### Why this entry exists

A review of this log against `CANONICAL_HASHES.md`, `HISTORY.md`, and the shipped scripts found eleven defects,
and **five of them share one shape**: a claim in this log was corrected elsewhere in the repository at the time
and the correction was never propagated back here. `CANONICAL_HASHES.md` and `HISTORY.md` are living documents
that get edited when understanding changes; this log is append-only, so it only stays true if someone appends.
Nobody did. That is the failure mode this entry closes, and it is the reason the append-only contract carries a
re-evaluation rule at all: **a log whose corrections live only in other files is not a record of what was known
when — it is a record of what was believed once, presented as current.**

Every correction is marked at its own site, so a reader who lands mid-file sees the marker without needing this
entry. Nothing measured was changed. Where a figure was relabelled in place — three of the eleven — the marker
says so explicitly and states what the original text read.

### The eleven, by entry

| # | Entry | What was wrong | What is true |
|---|---|---|---|
| 1 | 2026-05-10 #72 (bitset) | The 263 / 286 M/sec pair published as a single-thread, one-worker measurement | Those are **aggregate** rates over **128 threads** from a **90-s timed bench** (`HISTORY.md` labels the same numbers "Aggregate node-rate at 90s" under `SOLVE_THREADS=128`). The **1.09× ratio and +8.7% are unaffected** |
| 2 | 2026-05-11 #70 (C3 optimistic bound) | Baseline labelled "#67 alone" | The 831-record delta is over **v1+C5+#67**. A `v1+#67+#70` run does not exist anywhere in this log |
| 3 | 2026-05-13 LTO | Sha gate recorded as passing *by definition* | Reworded to the **measured** byte-identical result. Sha gates in this solver settle only empirically |
| 4 | 2026-05-16 #46 (AVX-512 null) | "verified from commits `cd4e61c`/`b26cd9b`/`0783d52`" | Those objects are **absent from the shipped repo** (`git cat-file -t` fails on each) → the figures are operator-attested, per this file's Access boundary |
| 5 | 2026-05-16 #46 (AVX-512 null) | "HISTORY.md … now carries a `[REFUTED 2026-05-16]` callout" | **The callout is not there.** The one match in `HISTORY.md` is that sentence's twin claiming it is "already in place"; the 1.4–2.0× projections stand unmarked at `HISTORY.md:1510-1514` and `:2610`. **✅ Discharged 2026-09-02 (P64): both callouts written, at the drifted lines `:1521` / `:2628`; the third site in `DEVELOPMENT.md:586` marked the same day.** |
| 6 | 2026-05-17 v2 11.2T anchor | A "~1-2%" v2 advantage projected for 100T+ | Measured **+6.74%** at 100T (+231,181,617 records). The advantage **grew** with depth: +4.83% at 11.2T → +6.74% at 100T |
| 7 | 2026-05-18 per-prune ladder | #68 called 24-27× more impactful than #67 at every scale | **≈14.5-36.9×** across the four scales in its own table; 24-27× holds only at 1B-10B. The *ranking* claim stands |
| 8 | 2026-05-18 per-prune ladder | Unlimited budget framed as v1 and v2 exhausting different predicates; +4.83% called v2's "real" extra solutions | Both prune sets are sound: **v1(∞) = v2(∞) = v3(∞)**. +4.83% is a **budgeted-slice** delta at 11.2T — a convergence-rate effect, not a larger solution space |
| 9 | 2026-05-24 PGO retraction | "sha is determined by prune predicates, not optimizer branch hints" | An unsupportable universal: a 100%-DFS-neutral commit (`d683794`) flips the 100B sha. The byte-identical 1T match itself stands |
| 10 | 2026-05-27 #106/#108 | 1T anchor drift attributed to the 7 hardening commits, via an LTO-layout mechanism | Task #108 found the drift **host-environment-level**; the 7 commits were **exonerated** and **LTO empirically ruled out** (`-fno-lto` reproduced `74d39760…` exactly). #108's sha-equivalence at 1T is unaffected |
| 11 | 2026-06-21 #167 / 2026-07-09 #223 | Two statuses left stale: #167's canonical gate unresolved, #223's n=31 run described as still running | #167's 11.2T eviction-resume gate **PASSED** before the June 22-23 560T relaunch; #223's n=31 run **completed 2026-07-16** |

Corrections 1, 5, 6, 9 and 10 are the propagation-failure class: each was already right in `CANONICAL_HASHES.md`
or `HISTORY.md` (or, for 5, was *supposed* to be) while this log kept the superseded reading.

### Arithmetic checks, so a reader need not take these on trust

- **#70 baseline (2):** `235,083 − 234,252 = 831`; `831 / 234,252 = 0.355%` — matches the entry's +0.35%, and the
  minuend/subtrahend are the table's `v1+C5+#67+#70` and `v1+C5+#67` rows.
- **100T uplift (6):** `3,663,580,914 − 3,432,399,297 = 231,181,617`; `231,181,617 / 3,432,399,297 = 6.735%`.
- **#68 vs #67 range (7):** from the ladder table's own percentages — `68.6/1.86 = 36.9×` (100M),
  `80.4/3.36 = 23.9×` (1B), `90.2/3.39 = 26.6×` (10B), `104.4/7.22 = 14.5×` (100B).
- **Per-thread plausibility (1):** at 128 threads, `128 × 263 M/sec = 33.7 B nodes/sec` would exhaust the 11.2T
  budget in ~5.5 minutes; read as aggregate the same figure is ~2.05 M/sec/thread and ~11.8 h at 11.2T, which
  is what the run records show.

### Three defects this entry can only record, not fix

They live in other files and must be fixed there; each is marked at its site above so a reader is warned in the
meantime.

1. **`scripts/build_pgo.sh` cannot build `solve.c`.** Both link lines (`:77-78` Pass 1, `:128-130` Pass 2) end
   in `-lm` with no `-lz`, while `solve.c:317` has included `<zlib.h>` since #169. Running the script's exact
   Pass-1 command against `solve.c` at this commit fails at link (rc=1, undefined `gzclose`/`gzfread`/…). The
   2026-05-24 entry advertises this script as the canonical reusable PGO recipe; it is not one until `-lz`
   lands, and a repo self-check should assert its Pass-1 link against HEAD `solve.c`.
2. **`scripts/perf_bench.sh` can certify a run whose stated conditions did not hold.** The page-cache flush ends
   `|| true` (`:176`) so a failed flush proceeds, while the JSON emits `"page_cache_flushed": true` as an
   unconditional literal (`:254`) — a bench that never flushed ships certified-looking JSON. The script also has
   no preflight throttle burn, though this log's own 2026-05-18 methodological finding makes that burn
   mandatory. The field must carry the flush's real status, and the burn must run or the JSON must say
   `throttle_probe: absent`. The "Standard bench harness" section at the top of this file has been corrected to
   describe what the script does rather than what it was said to do.
   **➤ [UPDATE 2026-09-02] The flush half is FIXED.** The field now carries `CONFIRMED` / `FAILED` /
   `UNVERIFIED` from a whole-line verdict token emitted by each build, a non-`CONFIRMED` result sets
   `"methodology_valid": false` and exits 3, and a run that produced no token at all reads `UNVERIFIED`
   rather than passing. Red-tested by running the harness on a host with no passwordless sudo: the
   pre-fix script emitted `"page_cache_flushed": true` and exit 0; the fixed script emits
   `UNVERIFIED (no-passwordless-sudo)` and exit 3. ~~**The throttle-burn half is still open.**~~
   **➤ [UPDATE 2026-09-02, later the same day] The throttle-burn half landed too** — a pure-CPU burn on every
   core before the bench, `PERFBENCH_THROTTLE_PROBE=HEALTHY|THROTTLED|UNVERIFIED`, teardown and exit 5 on
   anything but `HEALTHY`; and `sha`/`records` moved from the container to the decompressed stream. See
   §"Standard bench harness" above.
3. **The `[REFUTED 2026-05-16]` callouts promised for `HISTORY.md:1510-1514` and `:2610` do not exist** and need
   to be written, alongside a check that any sentence asserting a marker is "already in place" resolves to an
   actual marker at the named location.

### Notes

**Scope.** No measurement in this log was re-run for this entry and no figure was recomputed from raw data —
every check above is arithmetic against numbers already published here, or a comparison against
`CANONICAL_HASHES.md` / `HISTORY.md` / the shipped scripts at this commit. Where those documents disagreed with
this one, the corroborated reading won; where a claim could not be checked from the public repository
(correction 4), it is now labelled operator-attested rather than silently trusted.

**In-place edits made, and why they are not contract violations.** Three figures were relabelled at their sites
(corrections 2, 7, 8) rather than only marked, because each was contradicted by a table printed immediately
above it — leaving the wrong label standing would have handed a reader a number its own evidence refutes. Each
carries a marker stating the original wording. Two front-matter sections were edited directly (the append-only
contract, which did not match practice, and the bench-harness description, which did not match the script);
neither is a dated entry. Everything else is annotation.

**One header claim was corrected, not just annotated:** this file previously asserted "Entries are
chronological". They are not — `2026-05-16 — task #68` precedes `2026-05-11 — task #70`. Exactly one entry is
out of date order, and the header now says so and explains why, rather than asserting an invariant the file does
not hold.

---

## 2026-09-04 — re-evaluation: correction 10 is itself corrected (no code change; two new measurements)

**Category**: re-evaluation (append-only correction entry — see the contract at the top of this file)
**Sha impact**: none — no code, build recipe, or canonical artifact changes here
**Decision**: a second correction blockquote appended under the 2026-05-27 #106/#108 entry; the two 1T
sha-gate lines in that entry annotated; the 100B-flip bullet in the §"2026-05-13 — LTO (build flag)" entry annotated

### Why this entry exists

The 2026-08-30 re-evaluation above withdrew the 1T anchor pair's attribution to LTO layout effects from the
seven hardening commits and put **host-environment-level** in its place. That replacement was as unmeasured as
the attribution it replaced. Neither pass compared the two runs' per-cell budgets, and both provenance files
had recorded them since 2026-05-27. On 2026-09-04 the comparison was finally made, as a controlled experiment
rather than an inference: one binary, built from unmodified public `main` `82f96b6b`, on one Spot D128als_v7
host, with the per-cell budget as the only variable.

| arm | `SOLVE_PER_SUB_BRANCH_LIMIT` | sha256 (decompressed stream) | Records |
|---|---:|---|---:|
| published recipe | 6,315,458 | `5a0f0bc2…` | 134,039,081 |
| solver auto-divide | 6,314,566 | `74d39760…` | 134,027,160 |

892 nodes per cell × 158,364 cells; 11,921 records; 381,472 bytes = 11,921 × 32. Arm 2's sha and record count
were both *predicted in writing before the run* and matched exactly.

### The twelfth, by entry

| # | Entry | What was wrong | What is true |
|---|---|---|---|
| 12 | 2026-08-30 re-evaluation, correction row 10 | Row 10's "what is true" column — that Task #108 found the 1T pair **host-environment-level** — was as unmeasured as the attribution it replaced. Neither the 2026-05-27 investigation nor the 2026-08-30 correction compared the recorded per-cell budgets | The pair is two per-cell budgets: published 6,315,458 → `5a0f0bc2…`, auto-divided 6,314,566 → `74d39760…`, both reproduced from one binary on one host on 2026-09-04. Row 10's exoneration of the seven commits and its LTO ruling **stand** — both of those comparisons put auto-divide against auto-divide and are sound. The same derived-vs-published mechanism was found and fixed at 11.2T on 2026-06-17 (public commit `d8671550`), three months before it was recognised at 1T |

**Row 10 is not edited.** It stays exactly as written; this row corrects it, and both stay — the same contract
the 2026-08-30 entry applied to the entries it corrected.

### Notes

**Scope.** No measurement in this log was re-run for this entry, and no figure was recomputed, except the two
1T arms tabulated above, which are new measurements taken for it. `CANONICAL_HASHES.md` §d3 1T is the registry
of record for both values; `CORRECTIONS.md` §"2026-09-04 — the 1T anchor pair was two per-cell budgets" is the
ledger entry.

**What is still open.** The 1T sha gate named `74d39760…` as its expected value while the shipped
`--validate-canonical` injected 6,315,458 and could only produce `5a0f0bc2…`, so from 2026-06-17 to 2026-09-04
that gate could not pass; no 1T sha-bearing run exists in the record between 2026-07-02 and 2026-09-04. The
2026-09-04 control run establishes retroactively that current `main` still reproduces the 2026-05-24 value, so
across that window the 1T enumeration output did not change. That is reassurance about the output. It is not a
dismissal of the process failure, which stands on its own.

**Credit.** Codex review V2-F25 #3 (2026-09-02) proposed the per-cell-budget confound for exactly this pair and
was wrongly ruled refuted by this project's own adjudication; the ruling is withdrawn.
