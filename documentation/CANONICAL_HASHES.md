# Canonical hashes

The reproducibility anchor for ROAE is the sha256 of `solutions.bin`, not the file itself. Any `solutions.bin` produced with the matching solver version and inputs must reproduce one of the hashes below byte-identically.

A mismatch means a bug was introduced (in the solver, the build toolchain, or the runtime environment), not that a new result was found.

## Quick reference (deepest first)

| Scale | sha256 (prefix) | Records | Status | Solver lineage |
|---|---|---:|---|---|
| **d3 560T** | `9a968fa2…` | 10,525,271,997 | **CANONICAL-verified** (2026-06-30: from-scratch re-run on the eviction-resume-fixed solver reproduces it byte-for-byte; see §d3 560T) | v1/v3 main |
| d3 100T | `915abf30…` | 3,432,399,297 | Active drift + partition anchor | v1 (modern) |
| d3 11.2T | `0c0fe37c…` | 759,608,573 | Active drift anchor | v1 |
| d3 10T | `b85c8871…` | 706,427,594 | Active drift anchor | v1 (modern) |
| d3 5.6T | `f66920c1…` | 467,484,167 | Active drift anchor | v1 (modern) |
| d2 10T | `a09280fb…` | 286,357,503 | Active d2-partition reference | v1 |
| d3 1T (main) | `74d39760…` | 134,027,160 | Active build-state anchor | c72eada+#108 lineage |
| d3 1T (v3 BRANCH) | `5a0f0bc2…` | 134,039,081 | Historical | v1 / v3 BRANCH `8b1658b` |
| Selftest | `403f7202…` | 135,780 | Active build gate | v1 |

For each canonical, "Active" means the published sha reproduces byte-identically on current `main` HEAD (the v3 lineage, sha-equivalent to v1 at all canonical scales tested). "Drift anchor" means the canonical is no longer the deepest published, but its sha is still used to detect build-toolchain drift at that scale. The d3 560T row is the project's deepest enumeration; it was **SUSPECT** from 2026-06-21 (a proven eviction-resume defect on the pre-fix solver), and resolved to **CANONICAL-verified** on 2026-06-30 when a from-scratch re-run on the fixed solver reproduced `9a968fa2` byte-for-byte (see §d3 560T).

The full reproducibility-parameters table (env vars per canonical) is at [§Reproducibility parameters](#reproducibility-parameters) below.

## Active canonicals — detailed entries

### d3 560T — current deepest

**Visualization:** [PCA scatter plots](../viz/viz_pca.md) (this 560T canonical solution set projected into 2-D) · [growth curve & campaign telemetry](../viz/viz_graphs.md) (how the space fills and how the run executed).

> **✅ STATUS: CANONICAL-verified (resolved 2026-06-30).** This sha was **SUSPECT** from 2026-06-21 to 2026-06-30.
> The concern: a determinism defect in the solver's eviction-resume path (identified 2026-06-21) — a per-cell
> checkpoint (`.dfs_state`) could be made durable *before* its solutions shard (`.bin`), so a Spot eviction in
> that window could drop a cell's solutions on resume. The original 560T campaign ran across **5 Spot evictions**
> on a solver build predating the fix, so the sha *might* have been incomplete.
>
> **Resolution:** a complete from-scratch 560T re-run on the eviction-resume-**fixed** solver (the #188 fix)
> **reproduced `9a968fa2` byte-for-byte** — identical sha, identical 10,525,271,997 records. The re-run itself
> took **7 real Spot evictions** (all resumed cleanly) and still converged to the exact same canonical, verified
> by three independent `gzip -dc | sha256sum` passes. **Conclusion: the original 560T was complete and correct;
> the eviction-resume defect did not corrupt it.** SUSPECT clears.
>
> *Why byte-identical even though the old run had the bug?* `solutions.bin` is a path-independent object — the
> sorted, canonically-deduped *set* of all C1–C5-satisfying orderings found within the per-cell node budget. The
> final merge is a projection onto that set, provably invariant to thread count, machine, branch-partition order,
> **and eviction/resume provided the resume is correct.** Only two things can change the sha: a genuinely *lost*
> unique solution or a *fabricated* one. The byte-match rules out both. A pre-merge shard comparison quantifies it:
> both runs found solutions in the **same 65,281 cells**, and the old run's raw pre-dedup total (43,880,306,393)
> exceeded the new run's (43,876,464,466) by exactly **+3,841,927 records (0.009%)** — all duplicates the dedup
> erased. So the old run's 5 evictions caused **over-emission, not loss or fabrication**. This also demonstrates
> the #188 fix's eviction-resume determinism **at the deepest (560T) scale**, complementing the 11.2T proof.
>
> The 11.2T (`0c0fe37c`) and 100T (`915abf30`) canonicals were always **unaffected** — each independently
> re-derived by multiple eviction-free witnesses. (Tracking: private `INCIDENT_167_RESUME_SHA_MISMATCH.md`,
> `ANALYSIS_194_CONFIRMED_2026_06_30.md`.)

- **sha256:** `9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`
- **Records:** 10,525,271,997 (= 1.05253 × 10¹⁰)
- **File size:** 336,808,703,936 bytes (32-byte header + 10,525,271,997 × 32-byte records)
- **Solver:** v1/v3 (current main, git `2b01b15`)
- **Established:** 2026-06-08 by the 560T canonical campaign
- **King Wen found:** YES

**Campaign details:** D128als_v7 Spot westus3 enum, 4 TB Premium SSD for shards, 171.5 h wall time across 5 weekday Spot evictions (all in a tight 07:12-07:49 PT window — see [HISTORY.md](HISTORY.md) "June 1-8, 2026" entry). 158,364/158,364 cells scanned (100%), 65,281 cells produced solutions (41.2% yield). Merge: D16als_v7 Standard, external chunked-sort on Premium scratch, 18 h 42 m wall. 43.88 B raw pre-dedup records → 10.525 B unique canonical (4.17× dedup ratio).

**Power-law fit (3-point across 11.2T → 100T → 560T):** records ∝ T^α with α ≈ 0.67 (3-point log-log fit; pairwise legs 0.69 and 0.65). 1120T extension projection ≈ 16.7 B records. The 2026-06-14 three-point per-cell analysis confirms the record sets are **strictly nested** under pair-identity keying (11.2T ⊆ 100T ⊆ 560T, 0 monotonicity violations; cells yielding 9,799 → 10,062 → 10,618) and grow by **deepening** of existing productive cells (cells first appearing at a larger scale add only ~0.2% → ~0.5% of records); every sampled sub-branch is BUDGETED, none EXHAUSTED, so the exhaustive enumeration cannot state the total count of C1–C5-satisfying orderings — but an unbiased Monte-Carlo estimate now puts it at **≈10³⁸** raw (the companion ≈3×10³⁷ distinct-canonical figure is **WITHDRAWN**, 2026-08-23 — see CORRECTIONS.md), meaning raw-against-raw that even 560T's 43.9 B raw records is ≈1 part in 3.03×10²⁷ of the space. See [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md) and [HISTORY.md](HISTORY.md) §"3-point per-cell scaling trajectory".

**Verification witnesses:**

| Date | Path | Result |
|---|---|---|
| 2026-06-08 | [`solve --verify`](SOLVE_C_CLI.md#--verify) (C) on all 10,525,271,997 records | PASS — C1-C5 + sorted + no duplicates + King Wen found |
| 2026-06-09 | `verify.py --jobs 64` (Python second-language re-verify) on warm copy, D64als_v7 Spot, solve binary built from main HEAD `74e4140` | PASS — same record set, independent language witness |
| 2026-06-30 | **from-scratch 560T re-run** on the #188 eviction-resume-fixed solver, D128als_v7 Spot westus3, 7 Spot evictions (all clean) | **PASS — reproduces `9a968fa2` byte-for-byte** (3 independent `gzip -dc \| sha256sum` passes; 10,525,271,997 records). Independent same-scale witness on a different binary + different eviction pattern → SUSPECT cleared |

**Post-merge SPOF discovered + remediated mid-campaign** — see [HISTORY.md](HISTORY.md) entry and [CAMPAIGN_METHODOLOGY.md §4.1](CAMPAIGN_METHODOLOGY.md). No Build B cross-build at 560T (cost prohibitive).

**Archive triple-storage:**
- `solver-data-westus3:/canonical-archive/20260608_560T_9a968fa2/` — gzip warm mirror (original campaign)
- `roaecanonical2026/canonical-archive/20260608_560T_9a968fa2/` — cold blob (original campaign, Cool tier)
- `solver-data-westus3:/canonical-archive/20260630_560T_RERUN_fixedbinary_947d547/` — gzip warm mirror (2026-06-30 re-run; solutions.bin.gz + shards.tar.gz + checkpoints, byte-identical canonical)
- `roaecanonical2026/canonical-archive/20260630_560T_RERUN_fixedbinary_947d547/` — cold blob (2026-06-30 re-run; round-trip-verified `9a968fa2`, extendable shards+checkpoints retained per the 11.2T+ cold-shards rule)

---

### d3 100T

- **sha256:** `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5`
- **Records:** 3,432,399,297 (= 3.43240 × 10⁹)
- **File size:** 109,836,777,536 bytes
- **Solver:** v1 (modern); v3 sha-preserves on v1 at this scale
- **Established:** 2026-04-29 by post-`f42f2ae` code
- **Status:** Active drift anchor + partition-invariance anchor

**Recovery history:** original bytes destroyed 2026-05-06 by the `solver-data-westus3` mkfs -F incident. Re-derived 2026-05-09/10 via two independent paths.

**Re-derivation + cross-build witnesses:**

| Date | Path | Solver | Result |
|---|---|---|---|
| 2026-05-09 | T9+c.1 full-enum `solve 0 128` recovery | v1 modern | `915abf30…` byte-identical |
| 2026-05-10 | T9+d 62-branch loop [`solve --branch p1 o1`](SOLVE_C_CLI.md#--branch) ×62 + [`solve --merge`](SOLVE_C_CLI.md#--merge) | v1 modern | `915abf30…` byte-identical (partition-invariance witness) |
| 2026-05-30 (#114) | Re-validation on current main lineage `4e15885` | c72eada + #108 + Tier-1 hardening | `915abf30…` byte-identical (109,836,777,536 bytes); merge VM = D16als_v7 Standard, external-merge mode with Premium scratch |
| 2026-06-12 | `sha256sum` on warm-tier `/mnt/solver-data/canonical_100T/solutions.bin` | (independent of solve.c) | `915abf30…` byte-identical — 4th witness |

**Note:** v1 100T was NOT cross-built on two different physical hosts in the deliberate Build A + Build B pattern that v1 11.2T and v2 11.2T use; the May 9-10 re-derivations were forced by the wipe-incident recovery, with T9+d incidentally serving as the partition-invariance witness.

**Archive disposition (current state, 2026-06-12):**
- **Bytes preserved on warm tier:** `solver-data-westus3:/canonical_100T/solutions.bin` (109,836,777,536 bytes; sha-verified 2026-06-12). Originate from T9+c.1 recovery May 8-9.
- **Cold blob:** NOT uploaded. The forward-looking archive path `canonical-archive/20260530_100T_revalidation_4e15885/` referenced in earlier doc revisions is empty in actual cold blob state. A fresh v3 100T re-derive is completed 2026-06-13; consumed by the 3-point trajectory analysis (HISTORY.md 2026-06-14); archived per Canonical Archive Spec v1/13 specifically to upload a complete archive (solutions.bin.gz + per-cell shards) to cold blob.

**Record-count correction 2026-07-04 (reverses the erroneous 2026-05-30 note that previously stood here):** the canonical 100T record count is **3,432,399,297**. The 2026-05-30 revision "corrected" the original 3,432,399,297 to 3,432,399,298 by dividing the file size (109,836,777,536 bytes) by 32 — but that quotient **includes the 32-byte file header**. Correct arithmetic: (109,836,777,536 − 32) / 32 = 3,432,399,297, which matches every primary source: `--analyze` §[1] (`records: 3432399297` / `32 header + 109836777504 records`) and §[28], the solver-written `solutions.meta.json` (`"record_count": 3432399297`), and the independent verifier (`VERIFY PASS: all 3432399297 records satisfy C1-C5`). The original 2026-05-12 provenance count was right all along. **The sha256 anchors are UNAFFECTED — only this derived count field was wrong.** The v2/v1 100T delta is consequently +231,181,**617** records (+6.74%). Convention rule going forward: record counts come only from `solutions.meta.json` / analyze §[1] / verify output — never from raw file-size division; if size arithmetic is used as a cross-check, it is (size − 32) / 32.

---

### d3 11.2T

- **sha256:** `0c0fe37cf449cbc6e2754583964a60c185a7b387ee522fa43a8aac4fdb055db7`
- **Records:** 759,608,573 (= 7.59609 × 10⁸)
- **Solver:** v1 (modern); v3 sha-preserves on v1 at this scale
- **Established:** 2026-04-30/05-01 by v1 modern code
- **Status:** Active drift anchor (most-witnessed canonical in the project)

**Cross-build + cross-architecture witnesses (8 independent paths):**

| Date | Lineage / build | Host | Result |
|---|---|---|---|
| 2026-04-30/05-01 | v1 (original modern code) | D128 westus3 | `0c0fe37c…` established |
| 2026-05-14 (Build A) | v1 modern (post-fix `a2ead96`) | Spot D64als_v7 westus3 host α | `0c0fe37c…` byte-identical |
| 2026-05-14 (Build B) | v1 modern (post-fix `a2ead96`), split enum/merge | Spot D64 host β (enum 3.9h) + Standard D64 (merge 62min) | `0c0fe37c…` byte-identical |
| 2026-05-24 (Phase 11 Build A) | v3+v3.1 (commit `8b1658b`, LTO + PGO + bitset + orphan-promotion) | Spot D128als_v7 westus3 | `0c0fe37c…` byte-identical — confirms v3 sha-preserves on v1 |
| 2026-05-27 (#108 witness) | c72eada + #108 + #108b (commit `6e853fc`), binary sha `1ce20ff3…` | D128als_v7 Spot westus3, enum 7810s, manual external-merge + 100GB tmpfs scratch | `0c0fe37c…` byte-identical — demonstrates the 1T drift on c72eada (`5a0f0bc2…` → `74d39760…`) does NOT propagate to 11.2T (per-cell budget at 11.2T is 11× larger than at 1T, enough buffer that record-set is stable) |
| 2026-05-31 (Tier 1 witness) | git `7ca55e8` (= c72eada + #108 + Tier 1 `b579c1e` + #113/#107-retool/#48/#115b) | D128als_v7 Spot westus3, 128 threads, enum ~145 min, D16als_v7 Standard merge 96 min | `0c0fe37c…` byte-identical — first empirical confirmation that Tier 1 hardening is sha-neutral at 11.2T |
| 2026-05-21 (ARM Cobalt) | v3+v3.1 ARM binary `e5cfc6cd…` | D96ps_v6 + D32ps_v6 Cobalt Neoverse-N2, gcc 13.3.0 `-mcpu=native` | `0c0fe37c…` byte-identical — cross-architecture witness |

**Archives:**
- `canonical-archive/20260514_modern_v1_11.2T_buildA/` + `…buildB/`
- `canonical-archive/20260524_v3_buildA_11.2T_8b1658b/` (witness-only; no solutions.bin re-upload per operator directive on sha-match)
- `canonical-archive/20260531_dress_rehearsal_11_2T_7ca55e8/` (full archive including shards.tar.gz + dfs_state.tar.gz + budget.tar.gz per the 11.2T+ archive directive)

**Tier 1 incident note:** the 2026-05-31 dress rehearsal supervisor surfaced a phantom drift report from a typo'd hardcoded anchor sha; resolved by independent empirical sha256 against archived bytes — see `petersm3/roae-private:PHANTOM_DRIFT_RESOLUTION_2026_05_31.md`.

A fresh v3 re-derive is completed 2026-06-13; consumed by the 3-point trajectory analysis (HISTORY.md 2026-06-14); archived per Canonical Archive Spec v1/13 to add a 9th witness + preserve per-cell shards for the 3-point trajectory analysis.

---

### d3 10T

- **sha256:** `b85c887128ce9881229741380a799c4e1608335df438cedc3da9e087fd94dbbc`
- **Records:** 706,427,594 (= 7.06428 × 10⁸)
- **Solver:** v1 (modern)
- **Established:** 2026-05-13 via cascade re-derivation
- **Status:** Active drift anchor

**Cross-build witnesses:**
- Build A on Spot D64 host α (2026-05-13)
- Build B on Spot D64 host β (2026-05-13)

Both produced byte-identical sha. **+4,607 records vs deprecated `f7b8c4fb`** (pre-resume-fix code from 2026-04-18 undercount; deprecation context in §Deprecated below).

**Archives:** `canonical-archive/20260513_modern_v1_10T_buildA/` + `…buildB/`.

---

### d3 5.6T

- **sha256:** `f66920c10adfc4882cc75fce9aeb2f07a99d36159ecb8b2c58b2d22d13867a21`
- **Records:** 467,484,167 (= 4.67484 × 10⁸)
- **Solver:** v1 (modern)
- **Established:** 2026-05-12 cross-build
- **Status:** Active drift anchor (replaces deprecated `c34390c0`)

**Cross-build witnesses:**
- Build A on Spot D128 host α, source commit `2cf8771` (2026-05-12)
- Build B on Spot D128 host β, source commit `a2ead96` post-fix (2026-05-13)

Both produced byte-identical sha. Archives at `canonical-archive/20260512_modern_v1_5.6T_buildA/` + `20260513_modern_v1_5.6T_buildB/`.

---

### d2 10T

- **sha256:** `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2`
- **Records:** 286,357,503 (= 2.86358 × 10⁸)
- **Solver:** v1
- **Established:** 2026-04-18 (depth-2 partition strategy)
- **Status:** Active d2-partition reference (the only d2 canonical; not a "deepest" claim since d2 vs d3 partition is a different strategy axis)

**Cross-build witnesses:**
- Original generation 2026-04-18
- Modern code re-derivation on Spot D64als_v7 westus3 Build A + Build B (2026-05-13) both produced byte-identical sha

Depth-2 enumeration's smaller sub-branch count (3030 vs depth-3's 158,364) makes interruption less likely; the resume-bug interactions that affected the deprecated `c34390c0`/`f7b8c4fb` did not affect this canonical.

**Archives:** `canonical-archive/20260513_modern_v1_10T_d2_buildA/` + `…buildB/`.

---

### d3 1T (current main HEAD `c72eada`+ lineage)

- **sha256:** `74d3976061e015a3120d1ae11992f8662c97b59059ac69c61a5bff5edf146327`
- **Records:** 134,027,160 (= 1.34027 × 10⁸)
- **File size:** 4,288,869,152 bytes
- **Solver:** c72eada (post-#108 bundle, commit `6e853fc`)
- **Established:** 2026-05-27 during #108 validation
- **Status:** Active drift-detection anchor on current main lineage

**Drift-isolation runs:** reproduced byte-identically by unmodified `c72eada` (drift-isolation control) AND by `c72eada + #108 + #108b` bundle AND by `c72eada + #108 + #108b + SOLVE_FSYNC_BATCH_SIZE=16` — all three runs produce the same sha, confirming #108's mutex elimination and #108b's batched-fsync option are sha-neutral at canonical scale.

Differs from the `5a0f0bc2…` v3-BRANCH-lineage 1T anchor (12,000 records fewer; LTO compiler-layout effects from hardening commits between `9f10f05` (v3 reset) and `c72eada`, NOT a correctness change).

**Note on the 1T-vs-11.2T drift gap:** the c72eada drift at 1T (`5a0f0bc2…` → `74d39760…`) does NOT propagate to 11.2T (where both lineages produce `0c0fe37c…` byte-identically). Mechanism: BUDGETED-cell-density-sensitive — at 11.2T per-cell budget (70.7M nodes) is 11× larger than at 1T (6.3M nodes), enough buffer that record-set is stable across the 7 hardening commits' source-level changes. The 1T scale is more host-fragile and more sensitive to compiler-layout effects than the 11.2T+ canonical scales.

**Three measurements** (2026-05-27): drift control 1679s/1693s wall; pristine c72eada 3430s wall.

**Not archived to cold storage** (validation-only run).

---

### d3 1T (v3 BRANCH lineage @ `8b1658b`)

- **sha256:** `5a0f0bc24eb91b364169a13d0240ee0ff0fcf824dc829754d2254ec101fb8f52`
- **Records:** 134,039,081 (= 1.34039 × 10⁸)
- **Solver:** v1 (modern) and v3 BRANCH `8b1658b` (both produce this sha byte-identically)
- **Established:** 2026-05-24 as a byproduct of the v1-vs-v3 paired speedup bench on Standard D128als_v7 westus3
- **Status:** Historical anchor for v3 BRANCH state (May 2026)

**NO LONGER REPRODUCIBLE on current main HEAD `c72eada` or later** due to LTO compiler-layout drift from the 7 hardening commits between `9f10f05` (v3 reset) and `c72eada` (same mechanism as #99 100B-bisect's `d683794` sha-flip; see `petersm3/roae-private:V3_RESET_LOST_COMMITS_AUDIT_2026_05_27.md`).

**Archive:** `canonical-archive/20260524_1T_paired_bench_a2ead96_8b1658b/` (gzip -9 solutions.bin.gz 475 MB) + managed disk `solver-data-westus3:/20260524_1T_paired_bench_a2ead96_8b1658b/`.

---

### Selftest baseline (100M nodes)

- **sha256:** `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e`
- **Records:** 135,780 (= 1.35780 × 10⁵)
- **Status:** Active — reproducible across every binary build tested

Run via `solve --selftest`. The selftest is the project's universal build gate: any binary that produces this sha is "build-correct" at minimum. Sha-stable across DFS-neutral code changes (unlike sub-1T canonicals; see §"100B and sub-canonical reference shas" below).

---

## Historical (frozen lineages)

### v2 lineage — CLOSED 2026-05-24

Frozen by operator directive 2026-05-24 (`feedback_v2_closed_2026_05_24`). v2's prune stack (C5 #68 + mid-walk C3 #67 + C3 optimistic-completion #70) produces strictly more records than v1 at the same node budget — both are sound, v2 just converges faster per node. v3 was chosen over v2 because v3 sha-preserves on v1, simplifying canonical-chain validation. v2 canonicals are NOT deleted from cold storage; they stand as historical record + the empirical "v2 vs v1 uplift" data point at 11.2T (+4.83%) and 100T (+6.74%).

| Scale | sha256 | Records | Solver |
|---|---|---:|---|
| d3 11.2T (v2) | `2cc966e48399841ebb0c9ca67300f15bb578cc5481ed04fca5faffcb38ad6c4d` | 796,357,285 | v2 (commit `9d00c48`, tag `v2-merged-2026-05-21`) |
| d3 100T (v2) | `cc4a5377199f0710c99406c6e82e44f311ef34b2e53b152d67f5d0fcd2ace091` | 3,663,580,914 | v2 (commit `3128942`, tag `v2-merged-2026-05-21`) |

**v2 11.2T details:** established 2026-05-17. +36,748,712 records (+4.83%) vs v1 11.2T. Deterministic across two independent runs. Triple-storage archived: `solver-data-westus3:/20260516_v2bundled_11.2T_buildA_9d00c48/` + `canonical-archive/20260516_v2bundled_11.2T_buildA_9d00c48/` + claude `/tmp` fallback. solutions.bin.gz `4f1cd8b3…`. **Cross-architecture witness (2026-05-21):** ARM Cobalt Neoverse-N2 (D96ps_v6 + D32ps_v6, gcc 13.3.0 `-mcpu=native`, ARM binary sha `e5cfc6cd…`) produces byte-identical sha. G2 proof artifacts at `solver-data-westus3:/20260520_v2bundled_11.2T_armB_9d00c48_attempt2/`.

**v2 100T details:** established 2026-05-23 (campaign `20260521_v2_100T_buildA`). Phase 1 enum ~40h across 3 Spot evictions on D128als_v7 westus3; 61,550 shards, 481 GB raw. Phase 3 merge: Standard D32als_v7 + 1.5 TB Premium SSD scratch, external chunked-sort. +231,181,617 records (+6.74%) vs v1 100T. `solve --verify` PASS. Binary sha `6fdb10da…`. Dual-storage: `solver-data-westus3:/20260521_v2_100T_buildA/final/` + `canonical-archive/20260521_v2_100T_buildA/`. No Build B cross-build (v2 100T was a comparison baseline, not load-bearing). v2 100T shards deleted from managed disk post-archive (~481 GB freed). solutions.bin.gz size 13,462,264,289 bytes (sha `f6b554ea…`, ~9.35× compression).

**Lineage notes (corrected 2026-05-25):** The 2026-05-21 merge `3128942` was a v2-bundled merge that brought the v2 prune stack into `main`. v3 BRANCH `origin/v3` (`8b1658b` based on `2cf8771` May 10 pre-v2-prune) is the clean v3-design code — v1 prune set + #72 bitset + v3.1 orphan-promotion, no v2 prune tax. **On 2026-05-25 (afternoon), `main`'s `solve.c` was reset to v3 BRANCH's `solve.c`** so future `main`-based canonicals reproduce v1's sha family at every tested scale. The doc history on `main` (v2 100T canonical, paired bench, PGO retraction, [McKenna](CITATIONS.md#mckenna-mckenna1975) audit, etc.) is preserved as project record. Pre-reset state preserved at tags `v2-merged-2026-05-21` and `v2-with-v3.1-attempt-2026-05-25`.

**v2 vs v1 framing:** v2's "extra" records are NOT mathematically unreachable to v1 or v3. Both v1's and v2's prune predicates are sound (drop no valid leaves); they search the same tree of valid orderings. The difference is rate of convergence per node budget — v2 reaches solutions in fewer node visits because dead-branch pruning is more aggressive. At the limit, v1(∞) = v2(∞) = v3(∞) = the complete set of all C1-C5 canonical orderings.

**Records-per-dollar (UPDATED 2026-05-25 — speedup claim retracted):** v3 is sha-preserving on v1's prune predicates. The earlier "+9.2% faster per node" claim was a multiplicative theoretical composite (LTO 2.53% × PGO 6.5%) that did not replicate when measured as a combined stack at full-enum 1T scale (2026-05-24 paired bench: v3 ~0.5% slower than v1 with PGO applied; ~4.4% faster with LTO+bitset only — both within ~15% host-quality noise floor on Spot Bergamo Zen 4c). See `documentation/PERFORMANCE_HISTORY.md` "2026-05-25 — Methodological audit" entry for the provenance audit. The empirical position: v3 per-node cost is approximately equal to v1 at canonical full-enum scale; v3 wins on correctness + operational robustness (sha-preservation + v3.1 fast-skip recovery validated in task #95), not raw throughput. v2's prune-stack overhead (~3× v1's per-node cost) is independent of the PGO question and still real — so v2 still loses to v3 on records-per-dollar at any fixed budget.

## 100B and sub-canonical reference shas — code-specific, NOT canonical-grade

This section exists because of the 2026-05-25 100B drift bisect (six-enum study on D32 Spot bisect-100b; full report at `petersm3/roae-private:100B_DRIFT_BISECT_RESULTS_2026_05_25.md`). Three findings make sub-1T scales unsuitable as cross-build verification gates:

1. **All realistic canonical scales are BUDGETED at the per-sub-branch level** (per `petersm3/roae-private` memory `project_single_branch_exhaustion`, exhausting the smallest cell needs ≥31T nodes; 158,364 cells means total budget for true EXHAUSTED is ≥4,900T, infeasible). At 100B (per-cell 631K), 1T (6.3M), 11.2T (70.7M), 100T (631M), 560T (3.5B), every cell hits BUDGETED. Per solve.c:244-253 docstring, the SET of records found at BUDGETED is sensitive to DFS prune order; any DFS-affecting code change can flip which records are found before per-cell budget exhausts.
2. **Even DFS-neutral code changes can flip sub-canonical sha.** The bisect found commit `d683794` (Phase E.2 + defense-in-depth, May 15) flips 100B sha from `61d2caa5…` (pre-d683794) to `30b52336…` (post-d683794). d683794's diff is 100% resume-gated assertions + new subcommand handlers; none reaches the fresh-enum DFS path. The likely mechanism is LTO compiler-layout effects from added (unreachable-at-runtime) code subtly changing OpenMP thread scheduling or branch-prediction timing. **You cannot predict from source-reading whether a commit will flip 100B sha — only empirically.**
3. **Imperfect-resume during long-running generation contaminates the sha.** The May-15 100B archive `f1709ab09486ba…` does not reproduce from its own baseline commit `3258f4c` on a clean re-run; same pattern as deprecated `c34390c0` (5.6T) and `f7b8c4fb` (10T).

**Recommendation:** do not use sub-1T scales as a cross-build sha gate. Use `solve --selftest` for smoke tests, and 1T/11.2T+ canonicals for canonical-grade verification.

**Sub-canonical hard-gate (landed 2026-05-25):** `solve.c` now refuses to start a canonical-enum run when `SOLVE_NODE_LIMIT < 1T` (10¹² nodes) unless one of two intentional overrides is set. Exits with code 25 + a message explaining the override paths. Two suppressors: (a) `SOLVE_PER_SUB_BRANCH_LIMIT=N` set explicitly — intended for partition-invariance tests and within-code-state runs where the operator knows the output sha is code-specific; (b) `SOLVE_ALLOW_SUB_CANONICAL=1` — explicit override with an acknowledgment that the sha is code-specific. Selftest, --merge, --verify, --regression-test, --double-regression-test all bypass the gate (their child forks set the suppressors automatically). See HISTORY.md "May 25, 2026 UTC (late evening)" for the full set of hardening additions.

**Empirical 100B reference shas (record only — not "canonical" in the cross-code-variant sense):**

| Commit / code state | 100B sha | Notes |
|---|---|---|
| Pre-`d683794` v1 lineage (e.g., `a2ead96` May 13) | `61d2caa5c1842d67e75415d1390aa40cab98861e01c2b6149e825f75ffed123c` | Reproduced 2026-05-25 on D32 Spot bisect-100b. Current `main` HEAD (post-2026-05-25-reset to v3 BRANCH solve.c) is structurally pre-d683794 — empirically should produce this sha at 100B if re-tested, though not directly verified. |
| `3258f4c` → pre-2026-05-25-reset `e5a9b79` | `30b523362dc8b0a94e5d0cc11ba5f7429b774e3a06618ef093f11996764d579f` | Stable across 5 consecutive solve.c commits including the pre-reset main HEAD. v2 prunes (#67/#68/#70) do NOT flip 100B sha (don't fire at 631K per-cell budget). This sha family is no longer produced by `main` post-reset. |

Both shas are **build-recipe + commit specific**. solutions.bin size = 885,271,520 bytes for `30b52336…` family (27,664,734 unique records from 108,812,890 raw, 48,162 non-empty shards).

## Deprecated canonicals

| Scale | sha256 | Records | Reason | Replacement |
|---|---|---:|---|---|
| d3 5.6T | `c34390c00a2a871d78f49dd419779c0f649ed8271387c424ac4d36e0f3910dbd` | 467,483,137 | Irreproducible from any extant git commit per the 2026-05-12 bisect investigation. All v1 code from cdd8575 (Apr 30) through 2cf8771 (May 10) on either DFS path produces `f66920c1…` with 467,484,167 records (+1,030 vs this canonical). The +1,030 delta most likely reflects records lost via imperfect resume after the documented Spot eviction at 90% during the Apr 29-30 run. Pre-resume-fix code (pre `1d4dc6e`/`c3ad271`/`d11bc0d`/`c3d3ad6`) is more interruption-vulnerable. See [HISTORY.md](HISTORY.md). | `f66920c10adfc4882cc75fce9aeb2f07a99d36159ecb8b2c58b2d22d13867a21` |
| d3 10T | `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` | 706,422,987 | Generated 2026-04-18 by pre-everything code (predates all the resume bug fixes 1d4dc6e/c3ad271/d11bc0d/c3d3ad6, and predates iterative DFS + checkpoint correctness work). Cascade Phase B re-derivation 2026-05-13 on modern code produces `b85c8871…` with 706,427,594 records — +4,607 records vs this canonical. Like the c34390c0 delta, the records in f7b8c4fb are all valid C1-C5 canonical orderings; this canonical is incomplete by 4,607 records likely lost via imperfect resume during interruptions on pre-resume-fix code. | `b85c887128ce9881229741380a799c4e1608335df438cedc3da9e087fd94dbbc` |
| d3 100B | `f1709ab09486ba912ec5683a4c96211ff31d52b671e898b1b6e3421cc00aa9db` | (not recorded) | Generated 2026-05-15 on v1 commit `3258f4c` as a cold-archive reference. Irreproducible from `3258f4c` re-run 2026-05-25 (six-enum bisect on D32 Spot bisect-100b; clean fresh build produces `30b52336…`, not `f1709ab0…`). Same imperfect-resume artifact pattern as `c34390c0`/`f7b8c4fb`. Deprecated 2026-05-25. NB: 100B is no longer recommended as a cross-build verification gate — see §"100B and sub-canonical reference shas (code-specific)" above for why. | (none — 100B is intrinsically code-specific) |

## Reproducibility parameters

Each canonical is fully reproduced by the env-var set below. `SOLVE_DEPTH` is the per-thread DFS depth; `SOLVE_NODE_LIMIT` is the global budget; `SOLVE_PER_SUB_BRANCH_LIMIT` is the per-cell budget. Thread count must be 128 for byte-identical reproduction at the depth-3 canonicals (the merge dedup step is order-stable so other counts produce the same sha if the enumeration completes, but eviction-recovery and resume paths assume 128).

> **For any new re-derive launcher, copy the `SOLVE_PER_SUB_BRANCH_LIMIT` value verbatim from this table.** Do not re-derive from a `floor(NL / 158,364)` formula — the published values are the empirical PSBs that produced the canonical shas. See `petersm3/roae-private:LESSONS_LEARNED_2026_06_12_PSB_MATH_ERROR.md` for the incident that motivates this rule.
>
> **Programmatic access (2026-06-13):** the same recipe lives in `solve.c` and is reachable via:
> ```
> solve --canonical-config 100T            # emit sha-determining env vars
> solve --canonical-config 100T --full     # also emit canonical DFS_ITERATIVE + DFS_CHECKPOINT
> solve --validate-launcher-config 100T <PSB>   # exit 0 if PSB matches recipe, 1 if not
> ```
> Known scales: `1T 5.6T 10T 11.2T 100T 560T d2-10T`. Launchers should call `--validate-launcher-config` as a pre-flight gate before any compute is spent — see how `petersm3/roae-private:scripts/campaign_*_rederive/LAUNCH_*.sh` use it. Output deliberately omits `SOLVE_THREADS` because thread count is not sha-determining and depends on caller hardware.

| Canonical | Env vars |
|---|---|
| Selftest | `solve --selftest` (internal fixed scenario; no env needed) |
| d3 1T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=1000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=6315458 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |
| d3 5.6T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=5600000000000 SOLVE_PER_SUB_BRANCH_LIMIT=35361598 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |
| d3 10T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=10000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=63146557 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` (also produces same sha at SOLVE_THREADS=64; cascade Build A+B both used 64 due to westus3 D128 Spot capacity issues 2026-05-13) |
| d3 11.2T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=11200000000000 SOLVE_PER_SUB_BRANCH_LIMIT=70723196 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |
| d3 100T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=100000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=631456644 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |
| d3 560T | `SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=560000000000000 SOLVE_PER_SUB_BRANCH_LIMIT=3536157207 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` (plus `SOLVE_SKIP_AUTOMERGE=1 SOLVE_SKIP_IOPS_CHECK=1` operationally; merge separately via `solve --merge` on Standard VM) |
| d2 10T | `SOLVE_DEPTH=2 SOLVE_NODE_LIMIT=10000000000000 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=128` |

Solver invocation for the multi-trillion-node canonicals: `solve 0 128`.

For the full `solve.c` command-line reference (every subcommand, env var, and exit code referenced in this document), see [SOLVE_C_CLI.md](SOLVE_C_CLI.md).

### Sha-determining vs operational env vars

Only `SOLVE_DEPTH`, `SOLVE_NODE_LIMIT`, and `SOLVE_PER_SUB_BRANCH_LIMIT` are **sha-determining** — change them and the resulting `solutions.bin` sha changes. The other variables shown above are **operational** — they affect runtime / scheduling / safety gates but produce byte-identical canonical output:

- `SOLVE_DFS_ITERATIVE=1` + `SOLVE_DFS_CHECKPOINT=1` — enable the iterative-DFS code path with on-disk checkpointing. Required for the multi-trillion-node depth-3 canonicals because the recursive path would blow the stack and there's no resume otherwise; sha-equivalent to the recursive path at scales that fit in memory.
- `SOLVE_THREADS=128` — parallelism degree. Sha-equivalent across `SOLVE_THREADS` values because the merge dedup step is order-stable (also reproduced at `SOLVE_THREADS=64` for the d3 10T canonical).
- `SOLVE_SKIP_AUTOMERGE=1` — skips the post-enum auto-merge step; needed when using the canonical pipeline pattern (separate Standard VM for merge).
- `SOLVE_SKIP_IOPS_CHECK=1` — skips the fsync-throughput pre-flight gate; needed for archival disks that fall below the 1000 fsync/sec threshold (HDD canonical-archive Premium).
- `SOLVE_ALLOW_BUILD_MISMATCH=1` (**NOT in the recipe above** — historical campaign command lines included it as defense against rebuild-induced binary drift across VM teardown-recreate cycles; the current canonical launchers handle this by deleting stale `build.sha` post-rebuild instead, so the override is no longer required and shipping without it surfaces unexpected binary changes loudly). See [DEVELOPMENT.md](DEVELOPMENT.md#buildsha-invariant-outlier-4) for the build.sha invariant guard this flag overrides.

### PSB-formula caveat

The published `SOLVE_PER_SUB_BRANCH_LIMIT` values above are NOT all exactly `floor(SOLVE_NODE_LIMIT / 158,364)`:

| Scale | Recipe PSB | `floor(NL/158,364)` | Off by |
|---|---:|---:|---:|
| 5.6T | 35,361,598 | 35,361,598 | 0 |
| 100T | 631,456,644 | 631,456,644 | 0 |
| 560T | 3,536,157,207 | 3,536,157,207 | 0 |
| 11.2T | 70,723,196 | 70,723,144 | +52 |
| 10T | 63,146,557 | 63,146,544 | +13 |
| 1T | 6,315,458 | 6,315,272 | +186 |

The 11.2T / 10T / 1T published PSBs are the empirically-correct values — they're what the original enum runs used to produce the published canonical shas byte-identically across many independent witnesses. The original solve.c may have used a slightly different per-cell-budget computation (perhaps including per-thread checkpoint overhead, or a different rounding mode), or those rows may be documentation typos that have been faithfully reproduced across builds because everyone uses the published recipe. Either way: **use the published value**.

## Solver version

**v3** is the canonical-producing lineage on `main` HEAD as of 2026-05-25 (post-reset). v3 = v1 prune set + `-flto` + #72 bitset + v3.1 orphan-promotion patch. v3 sha-preserves on v1 byte-identically at every tested scale. The current `main` HEAD reproduces every Active canonical above. Specific commits that established each canonical are recorded in [HISTORY.md](HISTORY.md). v3 binary builds on stock toolchain — no patched glibc, no jemalloc, no PGO (the 2026-05-24 paired-bench re-run confirmed PGO did not replicate the predicted speedup):

```
# Minimum to reproduce canonical sha:
gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm -lz

# Recommended (sha-preserving, with LTO — Phase 1c validated 2026-05-15 on D64 Zen 4):
gcc -O3 -flto -pthread -fopenmp -march=native -o solve solve.c -lm -lz
```

Both commands produce the canonical selftest sha `403f7202…` and reproduce every canonical above byte-identically. `-flto` (link-time optimization) reduces binary size ~1-2% and produces a ~2% wall-time speedup at 100B-node canonical-correlation scale on AMD Zen 4 with tight run-to-run variance (stddev 0.11% across 4 trials). Drop it if your toolchain doesn't support LTO.

**Historical lineages:**
- **v1** (original lineage, pre-2026-05-21) — anchor lineage; v3 reproduces v1's shas byte-identically.
- **v2** (canonical-producing 2026-05-21 → 2026-05-24, then closed) — v2 11.2T `2cc966e4…` and v2 100T `cc4a5377…` are frozen historical canonicals (see §"Historical (frozen lineages)" above). v2 binary reproduces those shas; current `main` HEAD does not. Pre-reset state preserved at tags `v2-merged-2026-05-21` and `v2-with-v3.1-attempt-2026-05-25`.

## How to verify a `solutions.bin`

```
sha256sum solutions.bin
# Compare to the row above.
```

For independent constraint-spec verification (slower than sha but cross-checks the binary's enumeration logic):

- C-side: `solve --verify solutions.bin` — checks every record satisfies C1+C2+C3 per [SPECIFICATION.md](SPECIFICATION.md).
- Python-side: `python3 verify.py --jobs N solutions.bin` — independent re-implementation. The `--jobs` flag parallelizes; `--jobs 128` matches the canonical's enumeration parallelism but any value works for verification.

Both verifiers operate without reference to the canonical sha; they validate the file against the constraint specification directly.

## How to re-derive from scratch

```
git clone https://github.com/petersm3/roae
cd roae
gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm -lz
./solve --selftest                    # must print sha 403f7202
ulimit -s unlimited                   # required at large scales
<env vars from the table above> ./solve 0 128
sha256sum solutions.bin               # must match the canonical row
```

The smallest validation reproduces in seconds (selftest). The d3 10T canonical reproduces in approximately 60-90 minutes on a 128-vCPU machine. The d3 100T reproduces in approximately 11-19 hours. Lower thread counts work; the wall time scales roughly linearly with `1/threads` for d3 enumeration.

## Format

`solutions.bin` is a 32-byte header followed by 32-byte records. Each record encodes a canonical ordering of the 64 hexagrams. See [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) for the byte-level encoding and the dedup semantics.

**Size convention (applies to every entry above):** the **File size** field is always the on-disk size *including* the 32-byte header; the record count is `(size − 32) / 32`. A merge/`--analyze` log line that reports "records × 32" (record-bytes only) is 32 bytes short of the on-disk size — that fence-post is the source of the 2026-06-14 false-corruption alarm and the 2026-07-04 100T count re-correction.

Records are deduplicated at merge time by canonical form (orient-bit-masked); the reported record count equals the number of distinct canonical orderings the enumeration discovered within its budget. The full mathematical search space is much larger than any partial enumeration here (estimated at ≈3×10³⁷ distinct-canonical orderings — see [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md)); canonicals at higher node budgets reveal more of it but cannot approach exhaustion. ⚠ **[WITHDRAWN 2026-08-23 — this figure exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]**

## Validation status

A canonical is listed as Active when at least one of the following holds:
- Single-shot full-enumeration reproduces the sha byte-identically.
- Multi-path equivalence (e.g., 56-branch decomposition merged globally) reproduces the same sha.
- Cross-architecture reproduction (x86 + ARM) yields the same sha.

Each Active canonical above has been validated by at least one of these paths; the d3 11.2T canonical has been validated by all three across eight independent paths. Detailed validation history per canonical is recorded in [HISTORY.md](HISTORY.md) and [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md).
