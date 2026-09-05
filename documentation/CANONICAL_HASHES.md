# Canonical hashes

The reproducibility anchor for ROAE is the sha256 of `solutions.bin`, not the file itself. Any `solutions.bin` produced with the matching solver version and inputs must reproduce one of the hashes below byte-identically.

A mismatch means a bug was introduced (in the solver, the build toolchain, or the runtime environment), not that a new result was found.

> **The word "Tier" on this page carries two unrelated senses; read the noun beside it.**
> **"Tier 1 / Tier-1 hardening"** is the *determinism-hardening level* (the host-fingerprint
> sidecar and the build-pinning work of Task #110 — see [HISTORY.md](HISTORY.md)); it qualifies a
> *witness row*, never a budget. **"Cool tier" / "warm tier" / "Archive tier"** is Azure storage
> class and says only where bytes are retained. Neither is the campaign-scale "Tier 1" of
> [LARGE_SCALE_CAMPAIGNS.md](LARGE_SCALE_CAMPAIGNS.md) (= the 11.2T canonical), the Lean
> proof-strength tiers of [`lean/README.md`](../lean/README.md), or the `tier-1` scoring axes of
> [CRITIQUE.md](CRITIQUE.md). A misread here is expensive because these rows carry sha claims, so
> the sense is spelled out at each use below rather than assumed.

> **Access boundary.** This registry cites two kinds of non-public material, and neither is required
> to verify a canonical. (1) Files in `petersm3/roae-private` (incident writeups, audits, launcher
> scripts) — a private staging repository; those citations are provenance for *how* a value was
> established or a defect resolved, and are operator-attested: disclosable to an auditor, not
> fetchable by a reader. (2) Archive locations of the form `solver-data-westus3:/…` (operator-held
> warm disk mirror) and `canonical-archive/…` (operator-held cold blob storage) — these name where
> the artifact *bytes* are retained, not public URLs. The public verification path for every
> canonical is the one this document already states: the published sha256 plus the reproduction
> recipe (solver commit, `SOLVE_NODE_LIMIT`, `SOLVE_PER_SUB_BRANCH_LIMIT`, partition depth). A
> reader who re-derives and matches the sha needs nothing private; the archived bytes exist so the
> operator can re-attest without re-deriving.
>
> **Extension is not on that public path, and this note previously did not say so** (added
> 2026-09-01). *Verifying* a canonical needs nothing private — that is the claim above and it is
> unchanged. *Extending* one to a deeper budget does: the recipe in
> [CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md) §"Concrete extension recipe" consumes
> `shards.tar.gz`, `dfs_state.tar.gz` and `budget.tar.gz` from exactly the operator-held
> `solver-data-westus3:/…` and `canonical-archive/…` locations named above, and those are storage
> locations rather than public URLs. A third party who wants a deeper canonical without operator
> cooperation must therefore re-run the parent campaign from scratch at the deeper budget — which is
> sound and fully specified here, but is not the incremental path the extension methodology
> describes. The distinction between "not required to verify" and "required to extend" is one this
> boundary note did not previously draw.

## Quick reference (deepest first)

| Scale | sha256 (prefix) | Records | Status | Solver lineage |
|---|---|---:|---|---|
| **d3 560T** | `9a968fa2…` | 10,525,271,997 | **CANONICAL-verified** (2026-06-30: from-scratch re-run on the eviction-resume-fixed solver reproduces it byte-for-byte; see §d3 560T) | v1/v3 main |
| d3 100T | `915abf30…` | 3,432,399,297 | Active drift + partition anchor | v1 (modern) |
| d3 11.2T | `0c0fe37c…` | 759,608,573 | Active drift anchor | v1 |
| d3 10T | `b85c8871…` | 706,427,594 | Active drift anchor | v1 (modern) |
| d3 5.6T | `f66920c1…` | 467,484,167 | Active drift anchor | v1 (modern) |
| d2 10T | `a09280fb…` | 286,357,503 | Active d2-partition reference | v1 |
| d3 1T | `5a0f0bc2…` | 134,039,081 | **Active** — the published recipe (`SOLVE_PER_SUB_BRANCH_LIMIT=6315458`); reproduced on current `main` 2026-05-30, 2026-07-01 and 2026-09-04 (×2); archived. ⚠ Relabelled 2026-09-04 — see §d3 1T | v1 / v3 BRANCH `8b1658b` / current `main` |
| d3 1T (auto-divide budget) | `74d39760…` | 134,027,160 | Reference only — what the solver produces when the per-cell budget is **auto-divided** (6,314,566 = ⌊10¹²/158,364⌋) instead of set to the published 6,315,458; reproduced on current `main` 2026-09-04 by setting `SOLVE_PER_SUB_BRANCH_LIMIT=6314566` explicitly. Not a gate target; never archived. See §d3 1T | c72eada+#108 lineage (auto-divide) |
| Selftest | `403f7202…` | 135,780 | Active build gate | v1 |

For each canonical, "Active" means the published sha reproduces byte-identically on current `main` HEAD (the v3 lineage, sha-equivalent to v1 at all canonical scales tested). "Drift anchor" means the canonical is no longer the deepest published, but its sha is still used to detect build-toolchain drift at that scale. The d3 560T row is the project's deepest enumeration; it was **SUSPECT** from 2026-06-21 (a proven eviction-resume defect on the pre-fix solver), and resolved to **CANONICAL-verified** on 2026-06-30 when a from-scratch re-run on the fixed solver reproduced `9a968fa2` byte-for-byte (see §d3 560T).

**If you are replicating and want one anchor, start with d3 11.2T (`0c0fe37c…`).** It is the
most-witnessed canonical in the project — eight independent build/host paths, including a cross-architecture
ARM Neoverse-N2 rebuild and both solver lineages (§d3 11.2T). Do **not** start at the smallest published
number without reading §d3 1T first: **the two 1T rows are two per-cell budgets, not two lineages.** If you
start at 1T, use the published recipe verbatim (`SOLVE_PER_SUB_BRANCH_LIMIT=6315458`) and expect
`5a0f0bc2…`; the second 1T row, `74d39760…`, is what the solver produces when the budget is left to
auto-divide, and it is listed so that a replicator who omits the budget recognises the value rather than
reporting a mismatch (§d3 1T).

⚠ **[CORRECTED 2026-09-04 — this paragraph said the 1T scale is "more sensitive to compiler-layout drift"
than the 11.2T+ scales and that `5a0f0bc2…` was known not to reproduce on current `main`. Both were wrong.
The two 1T rows differ by their per-cell budget, and `5a0f0bc2…` is the value current `main` produces under
the published recipe — measured on 2026-09-04, and produced on current `main` twice before that (2026-05-30,
2026-07-01). This is the **second** correction of this fact; the first, on 2026-08-30, replaced one unmeasured
cause with another. See §d3 1T and [CORRECTIONS.md](CORRECTIONS.md) §"2026-09-04 — the 1T anchor pair was two
per-cell budgets".]**

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
> both runs found solutions in the **same 65,281 cells**, and the old run's pre-merge shard total ⚠ **[LABEL CORRECTED 2026-08-28 — these are per-sub-branch CANONICAL keys, not raw oriented leaves: `solve.c:39-61` deduplicates on pair identity with the orient bit masked and CLEARS the table after each sub-branch, so the total counts cross-sub-branch rediscovery. It is a LOWER BOUND on raw leaves visited. See documentation/CORRECTIONS.md 2026-08-28.]** (43,880,306,393)
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

**Campaign details:** D128als_v7 Spot westus3 enum, 4 TB Premium SSD for shards, 171.5 h wall time across 5 weekday Spot evictions (all in a tight 07:12-07:49 PT window — see [HISTORY.md](HISTORY.md) "June 1-8, 2026" entry). 158,364/158,364 cells scanned (100%), 65,281 cells produced solutions (41.2% yield). Merge: D16als_v7 Standard, external chunked-sort on Premium scratch, 18 h 42 m wall. 43.88 B pre-merge shard records (per-sub-branch canonical) → 10.525 B unique canonical (4.17× cross-sub-branch rediscovery ratio — NOT an orientation-dedup ratio) ⚠ **[LABEL CORRECTED 2026-08-28 — this clause previously called the pre-merge total a count of raw records and its ratio a deduplication ratio. `solve.c:39-61` hashes and dedups on pair identity with the orient bit masked, and CLEARS each thread's table after every sub-branch, so a shard record is a per-sub-branch CANONICAL key rather than a raw oriented leaf. The record total is therefore a LOWER BOUND on raw leaves visited, and the ratio measures cross-sub-branch rediscovery under the depth-3 partition, not orientation multiplicity. Both values are unchanged, and the old-vs-new run comparison above is unaffected because it compares two totals of the same kind. The reasoning is set out at [CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md) §7 ("Worked example — the 560 T canonical campaign"), whose pre-merge shard-record row carries the same marker.]**

**Power-law fit (3-point across 11.2T → 100T → 560T):** records ∝ T^α with α ≈ 0.67 (3-point log-log fit; pairwise legs 0.69 and 0.65). 1120T extension projection ≈ 16.7 B records — a **projection that will not be measured**: the 1120T extension is not planned (2026-08-01). The 2026-06-14 three-point per-cell analysis confirms the record sets are **strictly nested** under pair-identity keying (11.2T ⊆ 100T ⊆ 560T, 0 monotonicity violations; cells yielding 9,799 → 10,062 → 10,618) and grow by **deepening** of existing productive cells (cells first appearing at a larger scale add only ~0.2% → ~0.5% of records — under pair-identity keying, the granularity at which the canonical dedups; under enumeration-cell keying the picture inverts, with 60.4% of 560T's records from cells empty at 11.2T — see [HISTORY.md](HISTORY.md)'s June-11 #126 entry; both keyings are stated there); every sampled sub-branch is BUDGETED, none EXHAUSTED, so the budgeted enumeration cannot state the total count of C1–C5-satisfying orderings — but an unbiased Monte-Carlo estimate now puts it at **≈10³⁸** (≈3×10³⁷ distinct-canonical), meaning even 560T's 10.5 B records is ≈1 part in 10²⁷ of the space. See [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md) and [HISTORY.md](HISTORY.md) §"3-point per-cell scaling trajectory". ⚠ **[WITHDRAWN 2026-08-24 — the ≈3×10³⁷ distinct-canonical figure on this line exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]**

**Verification witnesses:**

| Date | Path | Result |
|---|---|---|
| 2026-06-08 | [`solve --verify`](SOLVE_C_CLI.md#--verify) (C) on all 10,525,271,997 records | PASS — C1-C5 + sorted + no duplicates + King Wen found |
| 2026-06-09 | `verify.py --jobs 64` (Python second-language re-verify) on warm copy, D64als_v7 Spot, solve binary built from main HEAD `74e4140` | PASS — same record set, independent language witness |
| 2026-06-30 | **from-scratch 560T re-run** on the #188 eviction-resume-fixed solver, D128als_v7 Spot westus3, 7 Spot evictions (all clean) | **PASS — reproduces `9a968fa2` byte-for-byte** (3 independent `gzip -dc \| sha256sum` passes; 10,525,271,997 records). Independent same-scale witness on a different binary + different eviction pattern → SUSPECT cleared |

**Post-merge SPOF discovered + remediated mid-campaign** — see [HISTORY.md](HISTORY.md) entry and [CAMPAIGN_METHODOLOGY.md §4.1](CAMPAIGN_METHODOLOGY.md). No Build B cross-build at 560T (cost prohibitive).

**Archive triple-storage:**
- `solver-data-westus3:/canonical-archive/20260608_560T_9a968fa2/` — gzip warm mirror (original campaign)
- `canonical-archive/20260608_560T_9a968fa2/` — cold blob (original campaign, Cool tier)
- `solver-data-westus3:/canonical-archive/20260630_560T_RERUN_fixedbinary_947d547/` — gzip warm mirror (2026-06-30 re-run; solutions.bin.gz + shards.tar.gz + checkpoints, byte-identical canonical)
- `canonical-archive/20260630_560T_RERUN_fixedbinary_947d547/` — cold blob (2026-06-30 re-run; round-trip-verified `9a968fa2`, extendable shards+checkpoints retained per the 11.2T+ cold-shards rule)

---

### d3 100T

- **sha256:** `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5`
- **Records:** 3,432,399,297 (= 3.43240 × 10⁹)
- **File size:** 109,836,777,536 bytes
- **Solver:** v1 (modern); v3 sha-preserves on v1 at this scale
- **Established:** 2026-04-20 by the original 100T campaign (solver commit `edccb16`; run archive [`runs/20260419_100T_d3_d128westus3/`](../runs/20260419_100T_d3_d128westus3/)); bytes destroyed 2026-05-06, re-derived byte-identically 2026-05-09/10 on modern code — see Recovery history below. *(Corrected 2026-07-26: this row previously said "2026-04-29 by post-`f42f2ae` code" — wrong on both date and lineage; the run completed 2026-04-20 00:45 UTC and `f42f2ae` is the May-6 stack-buffer fix, which postdates it. The 04-29 date most plausibly bled in from the Apr-29/30 5.6T timeline.)*
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

**Archive disposition (current state, 2026-07-17):**
- **Bytes preserved on warm tier:** `solver-data-westus3:/canonical_100T/solutions.bin` (109,836,777,536 bytes; sha-verified 2026-06-12). Originate from T9+c.1 recovery May 8-9.
- **Cold blob:** `canonical-archive/20260619_100T_915abf30/` — uploaded 2026-06-19 from the fresh v3 100T re-derive (completed 2026-06-13; consumed by the 3-point trajectory analysis, HISTORY.md 2026-06-14), spec-v1 complete (solutions.bin.gz + sha sidecars + shards.tar + manifest + DONE marker; ~94 GiB). Presence re-verified live 2026-07-17 (blob present at Cool tier, 12,586,020,198 bytes) and by the cold-archive audit index of the same date. A second cold copy, `20260614_100T_v3_rederive_915abf30/` (same decompressed sha), is a known byte-redundant duplicate. *(Historical note: earlier revisions of this section said "NOT uploaded" and referenced `canonical-archive/20260530_100T_revalidation_4e15885/`, which was never populated — accurate as of 2026-06-12, superseded by the 2026-06-19 upload.)*

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
| 2026-05-27 (#108 witness) | c72eada + #108 + #108b (commit `6e853fc`), binary sha `1ce20ff3…` | D128als_v7 Spot westus3, enum 7810s, manual external-merge + 100GB tmpfs scratch | `0c0fe37c…` byte-identical — demonstrates the 1T drift on c72eada (`5a0f0bc2…` → `74d39760…`) does NOT propagate to 11.2T (per-cell budget at 11.2T is 11× larger than at 1T, enough buffer that record-set is stable) ⚠ **[CORRECTED 2026-09-04 — there was no 1T drift to propagate: the 1T pair is two per-cell budgets (§d3 1T). This 11.2T witness set the published 70,723,196 explicitly, as did every other 11.2T witness, which is why 11.2T never showed a pair.]** |
| 2026-05-31 (Tier 1 witness) | git `7ca55e8` (= c72eada + #108 + Tier 1 `b579c1e` + #113/#107-retool/#48/#115b) | D128als_v7 Spot westus3, 128 threads, enum ~145 min, D16als_v7 Standard merge 96 min | `0c0fe37c…` byte-identical — first empirical confirmation that Tier 1 hardening is sha-neutral at 11.2T |
| 2026-05-21 (ARM Cobalt) | v3+v3.1 ARM binary `e5cfc6cd…` | D96ps_v6 + D32ps_v6 Cobalt Neoverse-N2, gcc 13.3.0 `-mcpu=native` | `0c0fe37c…` byte-identical — cross-architecture witness |
| 2026-05-04 (recovery cascade) | v1 modern, post-#45 **patched** binary | fresh full-enum, 2026-05-04 04:21Z | `0c0fe37c…` byte-identical — **the eighth path this heading counts**; the run is recorded in [HISTORY.md](HISTORY.md) §"8-path equivalence at 11.2T proven" and under its "May 4 – May 5, 2026 PDT" entry. ⚠ **[ROW ADDED 2026-09-02 — the heading above has said eight since it was written and this table listed seven, so the registry's own count was not computable from the registry (Codex review V2-F43 #8, ACCEPTED). The missing path is this one, located in the public record by prose batch P43 when the same eight-vs-seven discrepancy was adjudicated in HISTORY.md's method-indexed roster; the fix there was to restore the row rather than renumber the heading down, and the same holds here. It qualifies as a separate build/host path under the criterion stated below: a distinct binary (post-#45 patch) not shared with any other row.]** |

**Independence criterion, and how the count is obtained.** A row above is a separate path only if it differs from every other row in at least one of: source commit, build flags, physical host, CPU architecture, or merge path. No definition was stated here before 2026-09-02, so a reader could not tell what was being counted. **The heading's number is the data-row count of the table above and nothing else** — the two restatements of it elsewhere in this document (§Quick reference, §Validation status) must equal it, and [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) deliberately states no number of its own, naming this table as the witness list of record. Reproduce the count from the file itself:

```
awk '/^\*\*Cross-build \+ cross-architecture witnesses/,/^\*\*Independence criterion/' \
    documentation/CANONICAL_HASHES.md | grep -c '^| 2026'      # -> 8
```

**Archives:**
- `canonical-archive/20260514_modern_v1_11.2T_buildA/` + `…buildB/`
- `canonical-archive/20260524_v3_buildA_11.2T_8b1658b/` (witness-only; no solutions.bin re-upload per operator directive on sha-match)
- `canonical-archive/20260531_dress_rehearsal_11_2T_7ca55e8/` (full archive including shards.tar.gz + dfs_state.tar.gz + budget.tar.gz per the 11.2T+ archive directive)

**Tier 1 incident note:** the 2026-05-31 dress rehearsal supervisor surfaced a phantom drift report from a typo'd hardcoded anchor sha; resolved by independent empirical sha256 against archived bytes — see `petersm3/roae-private:PHANTOM_DRIFT_RESOLUTION_2026_05_31.md`.

A fresh v3 re-derive completed 2026-06-13 and was consumed by the 3-point trajectory analysis ([HISTORY.md](HISTORY.md) 2026-06-14); its per-cell shards were archived per Canonical Archive Spec v1/13 for that analysis. ⚠ **[CORRECTED 2026-09-02 — this sentence also said the run was archived in order to add a further witness beyond the eight above. That claim is withdrawn; the retired form is registered in [RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) and keyed in [CORRECTIONS.md](CORRECTIONS.md) as `RP-8c9b7bd3`. **It was never a result — it was an intention.** Written 2026-06-13 while the run was in flight — the original sentence said the re-derive *was in flight* and named the further witness as its **purpose**, in the infinitive — it was closed to the past tense by a 2026-07-04 consistency sweep on the evidence that the trajectory analysis had consumed the run. That is evidence the run COMPLETED; it is not evidence its sha matched, and the two are different claims. **No sha attestation for this run is published anywhere in the tracked corpus**, and it has no entry in the Archives list above either — checked in both directions before this was written. It is therefore not counted among the eight, and the three counts this section carried for one campaign (a heading of eight, a table of seven, a trailing ninth) are now one. If the run's sha and host tuple are published later, it becomes a table row and the count moves with the table. Found by Codex reviews V2-F25 #12 and V2-F43 #8; V2-F25 #12's prescription — renumber the heading down to seven — is **declined** on the same evidence that declined it in HISTORY.md: the eighth path is real and locatable, and renumbering would delete it from the public record.]**

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

### d3 1T — auto-divided budget (`74d39760…`)

- **sha256:** `74d3976061e015a3120d1ae11992f8662c97b59059ac69c61a5bff5edf146327`
- **Records:** 134,027,160 (= 1.34027 × 10⁸)
- **File size:** 4,288,869,152 bytes
- **Solver:** c72eada (post-#108 bundle, commit `6e853fc`)
- **Established:** 2026-05-27 during #108 validation
- **Per-cell budget:** 6,314,566 — the solver's auto-divide value ⌊10¹²/158,364⌋, **not** the published recipe's 6,315,458
- **Status:** Reference value, reproducible on current `main` by setting `SOLVE_PER_SUB_BRANCH_LIMIT=6314566` explicitly (measured 2026-09-04). **Not a gate target** — the published-recipe anchor is `5a0f0bc2…`, §d3 1T — published recipe. ⚠ Relabelled 2026-09-04; this row read "Active drift-detection anchor on current main lineage".

**Drift-isolation runs:** reproduced byte-identically by unmodified `c72eada` (drift-isolation control) AND by `c72eada + #108 + #108b` bundle AND by `c72eada + #108 + #108b + SOLVE_FSYNC_BATCH_SIZE=16` — all three runs produce the same sha, confirming #108's mutex elimination and #108b's batched-fsync option are sha-neutral at canonical scale.

Differs from the `5a0f0bc2…` v3-BRANCH-lineage 1T anchor (12,000 records fewer). ⚠ **[CORRECTED 2026-08-30 — this read "LTO compiler-layout effects from hardening commits between `9f10f05` (v3 reset) and `c72eada`". That is the May-25 diagnosis, and it was **superseded on May 27** and is retracted here.** The settled Task-#108 result (Q4–Q10) is that the drift is **host-environment-level** — gcc/glibc/kernel patch versions, ASLR seed, CPU microcode revision — **not source-level**: the 7 hardening commits were **empirically exonerated** and **LTO was empirically ruled out** as the mechanism. See [HISTORY.md](HISTORY.md) §"May 27/28, 2026 UTC — Task #110 Tier 1 canonical-determinism hardening shipped + 1T sha-gate PASSED" and [TR-3](../reports/TR3_REPRODUCIBLE_ENUMERATION.md) §"Scope of the reproducibility claim" → *The toolchain qualifier*. **Still NOT a correctness change**, and the anchor **re-derives byte-identically on a matching host**. A reproducer chasing the retracted cause would vary the wrong control variable — source and build flags instead of host and toolchain.]**

> ⚠ **[CORRECTED 2026-09-04 — second correction of this paragraph.** The 2026-08-30 bracket above withdrew the
> LTO/hardening-commit attribution and put "host-environment-level" in its place. That replacement was also
> unmeasured: it never compared the two runs' per-cell budgets, which both provenance files recorded. The
> 2026-05-24 run that established `5a0f0bc2…` set `SOLVE_PER_SUB_BRANCH_LIMIT=6315458` (the published recipe);
> every run that produced `74d39760…` — including the drift-isolation control, the `-fno-lto` build, and the
> byte-identical-source bisect leg — left the budget to auto-divide, ⌊10¹²/158,364⌋ = 6,314,566, 892 nodes per
> cell less. On 2026-09-04 one binary built from unmodified `main` `82f96b6b` produced `5a0f0bc2…` at 6,315,458
> and `74d39760…` at 6,314,566, on the same host, in the same hour, with the per-cell budget as the only
> variable. The record delta is exactly 11,921 records = 381,472 bytes / 32 — the marginal yield of 892 extra
> nodes across 158,364 cells. The 2026-08-30 sentence "re-derives byte-identically on a matching host" is
> withdrawn as evidence of host sensitivity: no run in the record with the published budget has ever produced
> this value, and no run with the auto-divided budget has ever produced the other. **Why this is not new:** the
> same derived-vs-published divergence was found, diagnosed correctly, and fixed at 11.2T on 2026-06-17 —
> `solve.c`'s `CANONICAL_RECIPES` table and `--validate-canonical` now inject the published budget rather than
> deriving it (public commit `d8671550`; the public record of the same defect is [CORRECTIONS.md](CORRECTIONS.md)
> §"2026-09-02 — a wrong division published in three files" and [BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md);
> operator-attested detail in `petersm3/roae-private:INCIDENT_2026_06_17_11_2T_PSB_MISMATCH.md`). The identical
> mechanism at 1T was labelled host drift for three months. The Codex V2-F25 #3 review of 2026-09-02 proposed
> this confound and was ruled refuted; that ruling is withdrawn. See [CORRECTIONS.md](CORRECTIONS.md)
> §"2026-09-04 — the 1T anchor pair was two per-cell budgets".]**

**Note on the 1T-vs-11.2T drift gap:** the c72eada drift at 1T (`5a0f0bc2…` → `74d39760…`) does NOT propagate to 11.2T (where both lineages produce `0c0fe37c…` byte-identically). Mechanism: BUDGETED-cell-density-sensitive — at 11.2T per-cell budget (70.7M nodes) is 11× larger than at 1T (6.3M nodes), enough buffer that record-set is stable across the 7 hardening commits' source-level changes. The 1T scale is more host-fragile and more sensitive to compiler-layout effects than the 11.2T+ canonical scales.

> ⚠ **[CORRECTED 2026-09-04 — the "gap" this note explains does not exist.** 11.2T never showed a pair because
> every 11.2T witness set the published budget explicitly; 1T showed a pair because its witnesses split between
> the published budget (6,315,458) and the auto-divided one (6,314,566). The "BUDGETED-cell-density" mechanism
> and the "more host-fragile" characterisation are withdrawn as explanations of the 1T pair. This note is kept
> in place, under this bracket, because `solve.c`'s `--validate-canonical` FAIL text pointed a reader here until
> 2026-09-04; that pointer has been removed (see [SOLVE_C_CLI.md](SOLVE_C_CLI.md) §`--validate-canonical`).]**

**Three measurements** (2026-05-27): drift control 1679s/1693s wall; pristine c72eada 3430s wall.

**Not archived to cold storage** (validation-only run; the 2026-09-04 explicit-budget artifact is retained on the run host for the record-set subset test — `74d39760…`'s records are predicted to be a strict subset of `5a0f0bc2…`'s, untested).

---

### d3 1T — published recipe (`5a0f0bc2…`)

- **sha256:** `5a0f0bc24eb91b364169a13d0240ee0ff0fcf824dc829754d2254ec101fb8f52`
- **Records:** 134,039,081 (= 1.34039 × 10⁸)
- **Solver:** v1 (modern) and v3 BRANCH `8b1658b` (both produce this sha byte-identically)
- **Established:** 2026-05-24 as a byproduct of the v1-vs-v3 paired speedup bench on Standard D128als_v7 westus3
- **Per-cell budget:** 6,315,458 — the published recipe's `SOLVE_PER_SUB_BRANCH_LIMIT` (§Reproducibility parameters), set explicitly on every run that produced this value
- **Status:** **Active.** This is what current `main` produces under the published recipe. Witnesses: 2026-05-24 v1 `a2ead96` and v3 BRANCH `8b1658b` (Standard D128als_v7, 128 threads); 2026-05-30 `main` `7ca55e8` (Spot D32als_v7, 32 threads); 2026-07-01 `main` post-#196 (Spot D128); 2026-09-04 `main` `82f96b6b` twice (Spot D128 — once with an uncommitted working-tree change, once from unmodified HEAD). Verify with `gzip -dc solutions.bin | sha256sum`, never `sha256sum solutions.bin` (that hashes the gz container). ⚠ Relabelled 2026-09-04; this row read "Historical anchor for v3 BRANCH state (May 2026). Not a replication target".
- **How a replicator gets the other 1T value instead:** omit `SOLVE_PER_SUB_BRANCH_LIMIT` and the solver auto-divides to 6,314,566 → `74d39760…` (§d3 1T — auto-divided budget). The shipped `./solve --validate-canonical <sha> 1T` injects the published budget from `CANONICAL_RECIPES` (since the 2026-06-17 fix, public commit `d8671550`) and therefore validates against **this** row.
- **Sourcing this anchor in a script** (do not hardcode a literal; the quick-reference cell holds only an 8-nibble prefix, so read the full value from this entry):

```
ANCHOR_1T=$(awk '/^### d3 1T . published recipe/{f=1} f&&/^- \*\*sha256:\*\*/{gsub(/[^0-9a-f]/,"",$0); print; exit}' \
              documentation/CANONICAL_HASHES.md)
[ ${#ANCHOR_1T} -eq 64 ] || { echo "ANCHOR_1T_SOURCE=FAIL"; exit 1; }   # failure must be loud
./solve --validate-canonical "$ANCHOR_1T" 1T
```

**NOT REPRODUCIBLE on current main HEAD `c72eada` or later from a differently-provisioned host** — the drift is **host-environment-level** (gcc/glibc/kernel patch versions, ASLR seed, CPU microcode revision), **not source-level**, and it **re-derives byte-identically on a matching host**. ⚠ **[CORRECTED 2026-08-30 — this row read "due to LTO compiler-layout drift from the 7 hardening commits between `9f10f05` (v3 reset) and `c72eada` (same mechanism as #99 100B-bisect's `d683794` sha-flip)". That was the May-25 working diagnosis; Task #108's Q4–Q10 investigation, closed May 27, **empirically exonerated** those 7 commits and **empirically ruled out LTO** as the mechanism. The registry is the first document a reproducer consults, and it was directing them at a refuted cause. See [HISTORY.md](HISTORY.md) §"May 27/28, 2026 UTC — Task #110 Tier 1 canonical-determinism hardening shipped + 1T sha-gate PASSED", [TR-3](../reports/TR3_REPRODUCIBLE_ENUMERATION.md) §"Scope of the reproducibility claim", and `petersm3/roae-private:TASK_108_SUMMARY_FOR_OPERATOR_2026_05_27.md`. The separate #99 100B-bisect speculation in §"100B and sub-canonical reference shas" is left standing — it is hedged there as a *likely* mechanism at a scale HISTORY does not supersede. See also `petersm3/roae-private:V3_RESET_LOST_COMMITS_AUDIT_2026_05_27.md` for the commit inventory, whose facts are unaffected.]** **NOT a correctness change.**

> ⚠ **[CORRECTED 2026-09-04 — this paragraph, already corrected once on 2026-08-30 for its *mechanism*, was
> wrong in its *fact*.** The sha it says is not reproducible on current `main` was reproduced on current `main`
> on 2026-05-30 (`7ca55e8`, Spot D32, 32 threads), 2026-07-01 (post-#196, Spot D128) and twice on 2026-09-04
> (`82f96b6b`, Spot D128) — each time under the published recipe `SOLVE_PER_SUB_BRANCH_LIMIT=6315458`. Each of
> the first three results was recorded at the time as "host-level drift" rather than read as a refutation
> ([HISTORY.md](HISTORY.md) §"May 30-31, 2026 UTC — 560T pipeline dress rehearsal", and the 2026-07-01 run log). The two 1T
> rows differ by per-cell budget, not by host — see the sibling entry under §d3 1T — auto-divided budget. The
> 2026-08-30 bracket's "differently-provisioned host … re-derives byte-identically on a matching host" is
> withdrawn with it, and the row's earlier status wording, quoted here so the retraction is legible, was
> "**Historical — DOES NOT reproduce on current `main`; not a replication target**". Second correction of this
> fact; [CORRECTIONS.md](CORRECTIONS.md) §"2026-09-04 — the 1T anchor pair was two per-cell budgets".]**

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

**v2 100T details:** established 2026-05-23 (campaign `20260521_v2_100T_buildA`). Phase 1 enum ~40h across 3 Spot evictions on D128als_v7 westus3; 61,550 shards, 481 GB raw. Phase 3 merge: Standard D32als_v7 + 1.5 TB Premium SSD scratch, external chunked-sort. +231,181,617 records (+6.74%) vs v1 100T. `solve --verify` PASS. Binary sha `6fdb10da…`. Dual-storage: `solver-data-westus3:/20260521_v2_100T_buildA/final/` + `canonical-archive/20260521_v2_100T_buildA/`. No Build B cross-build (v2 100T was a comparison baseline, not load-bearing). v2 100T shards deleted from managed disk post-archive (~481 GB freed). solutions.bin.gz size 13,462,264,289 bytes (sha `f6b554ea…`, **8.708× compression**). ⚠ **[CORRECTED 2026-09-02 — the compression ratio published here was ~7% too high; the retired form is registered in [RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) and keyed in [CORRECTIONS.md](CORRECTIONS.md) as `RP-9788f906`. **The mechanism was a unit mismatch, and it is exactly reconstructible:** 13,462,264,289 bytes is 12.54 **GiB**, while the logical artifact is 117 **GB** decimal — dividing the one by the other reproduces the retired figure to three digits. Both operands are published, so the true ratio is derivable on this page without any archive access: per the §Format size convention the logical size is `3,663,580,914 × 32 + 32 = 117,234,589,280` bytes, and `117,234,589,280 / 13,462,264,289 = 8.708`. Reproduce with:

```
python3 -c 'print(round((3663580914*32+32)/13462264289, 3))'   # -> 8.708
```

No sha256, record count, file size or archive location changes — this is a derived field only. The direction matters for the one thing the figure is used for: storage or transfer planning at the retired ratio under-allocates compressed capacity by ~7%. The sibling site at [HISTORY.md](HISTORY.md)'s 2026-05-23 v2 100T entry carried the same figure and is corrected in the same pass (the charge named one site; there were two). Found by Codex review V2-F25 #11; measured, reconstructed and landed here.]**

**Lineage notes (corrected 2026-05-25):** The 2026-05-21 merge `3128942` was a v2-bundled merge that brought the v2 prune stack into `main`. v3 BRANCH `origin/v3` (`8b1658b` based on `2cf8771` May 10 pre-v2-prune) is the clean v3-design code — v1 prune set + #72 bitset + v3.1 orphan-promotion, no v2 prune tax. **On 2026-05-25 (afternoon), `main`'s `solve.c` was reset to v3 BRANCH's `solve.c`** so future `main`-based canonicals reproduce v1's sha family at every tested scale. The doc history on `main` (v2 100T canonical, paired bench, PGO retraction, [McKenna](CITATIONS.md#mckenna-mckenna1975) audit, etc.) is preserved as project record. Pre-reset state preserved at tags `v2-merged-2026-05-21` and `v2-with-v3.1-attempt-2026-05-25`.

**v2 vs v1 framing:** v2's "extra" records are NOT mathematically unreachable to v1 or v3. Both v1's and v2's prune predicates are sound (drop no valid leaves); they search the same tree of valid orderings. The difference is rate of convergence per node budget — v2 reaches solutions in fewer node visits because dead-branch pruning is more aggressive. At the limit, v1(∞) = v2(∞) = v3(∞) = the complete set of all C1-C5 canonical orderings.

**Records-per-dollar (UPDATED 2026-05-25 — speedup claim retracted):** v3 is sha-preserving on v1's prune predicates. The earlier "+9.2% faster per node" claim was a multiplicative theoretical composite (LTO 2.53% × PGO 6.5%) that did not replicate when measured as a combined stack at full-enum 1T scale (2026-05-24 paired bench: v3 ~0.5% slower than v1 with PGO applied; ~4.4% faster with LTO+bitset only — both within ~15% host-quality noise floor on Spot Bergamo Zen 4c). See `documentation/PERFORMANCE_HISTORY.md` "2026-05-25 — Methodological audit" entry for the provenance audit. The empirical position: v3 per-node cost is approximately equal to v1 at canonical full-enum scale; v3 wins on correctness + operational robustness (sha-preservation + v3.1 fast-skip recovery validated in task #95), not raw throughput. v2's prune-stack overhead (~3× v1's per-node cost) is independent of the PGO question and still real — so v2 still loses to v3 on records-per-dollar at any fixed budget.

## 100B and sub-canonical reference shas — code-specific, NOT canonical-grade

This section exists because of the 2026-05-25 100B drift bisect (six-enum study on D32 Spot bisect-100b; full report at `petersm3/roae-private:100B_DRIFT_BISECT_RESULTS_2026_05_25.md`). Three findings make sub-1T scales unsuitable as cross-build verification gates:

1. **All realistic canonical scales are BUDGETED at the per-sub-branch level.** Under the uniform per-cell budget every canonical uses, a run can only report EXHAUSTED if the per-cell budget is at least as large as the *largest* cell's search tree — so a measured lower bound on any *one* cell is a lower bound on the per-cell budget, and multiplying by the cell count bounds the total. The one cell measured directly needs **≥31 × 10¹² nodes** (provenance below), so the total budget for a true EXHAUSTED d3 run is **≥ 158,364 × 31 × 10¹² = 4.909 × 10¹⁸ nodes ≈ 4,900,000 T** — infeasible. ⚠ **[CORRECTED 2026-09-01 — this read "exhausting the smallest cell needs ≥31T nodes; 158,364 cells means total budget for true EXHAUSTED is ≥4,900T", printing the wrong product directly beside the two factors it is the product of. `158,364 × 31 × 10¹² = 4.909 × 10¹⁸` — that is ~4,900,000 T, not 4,900 T, and the published threshold understated exhaustion by a factor of ~1,002. The consequence is not cosmetic: at ≥4,900 T the deepest canonical (560 T) reads as 8.75× short of exhaustion, when in fact `4.909 × 10¹⁸ / 560 × 10¹² =` **8,767× short**. The corrected value is the one the source probe itself recorded. [CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md) §"Why budget matters" carried the same understated figure and is corrected in the same pass. The phrase "the smallest cell" is corrected too — the probe measured *a* cell drawn from the smallest first-level *branch*; it never established that any cell is the partition's minimum, and the product above does not need it to, because uniform budgeting keys off the largest cell, not the smallest.]** At 100B (per-cell 631K), 1T (6.3M), 11.2T (70.7M), 100T (631M), 560T (3.5B), every cell hits BUDGETED. Per solve.c's `PARTITION-INVARIANCE UNDER EXHAUSTIVE RUNS` docstring (locate by section title; solve.c:246-263 as of 2026-08-09), the SET of records found before BUDGETED depends on the per-sub-branch budget — change the partition, and so the budget denominator, and the record set and sha change with it. The stronger claim — that a change to the *prune set* also changes which records are found before per-cell budget exhausts — is **not** made by that docstring; the in-document evidence for it is §*v2 lineage — CLOSED 2026-05-24* above, where v2's prune stack produces strictly more records than v1 at the same node budget.

   **Provenance of the ≥31 × 10¹² input — single-cell exhaustion probe, 2026-05-17.** Stated here so
   the product above is auditable from published material rather than resting on a private citation.
   A depth-3 cell was picked from `B[25,1]` — the smallest first-level branch in the v2 11.2T
   canonical, 23,076 records — and specifically one that had hit BUDGETED there having found 0
   solutions, i.e. a *candidate* for being cheap to exhaust. It is addressable directly:

   ```bash
   ./solve --sub-branch 25 1 1 0 3 1     # B[25,1] → (p3=1, o3=0) → (p4=3, o4=1)
   ```

   Run on a v2-bundled build (`1b32270`, same prune lineage as the v2 11.2T canonical commit
   `9d00c48`) with 8 threads, at `SOLVE_NODE_LIMIT` = 1B, then 10B, then 100B. **All three rungs
   returned BUDGETED**, with identical task statistics: the cell decomposes into **2,488** depth-5
   parallel work tasks; the 8 threads each claimed one at startup and, after 12.5 × 10⁹ nodes apiece
   at the 100B rung, **not one had finished its single task**; the remaining 2,480 tasks were never
   started; 0 C3 leaves stored and 0 solutions found at every rung. **Taking the 2,480 untouched
   tasks to be comparable in size to the 8 sampled** — they share the depth-5 prefix structure —
   gives cell tree size ≥ 2,488 × 12.5 × 10⁹ ≈ **31 × 10¹² nodes**. That comparability step is the
   one soft link in the chain, and it is load-bearing: without it the strictly-measured floor is only
   the 8 sampled tasks, > 100 × 10⁹ nodes. **No upper bound was obtained** — none of the 8 sampled
   tasks completed, so the true size may be far larger, and the bound is specific to that build's
   prune set (stronger prunes shrink the same tree). Full writeup:
   `petersm3/roae-private:SINGLE_CELL_PROBE_RESULT_2026_05_17.md` (operator-attested, per the access
   boundary above; every number quoted here is reproducible from the command shown).
2. **Even DFS-neutral code changes can flip sub-canonical sha.** The bisect found commit `d683794` (Phase E.2 + defense-in-depth, May 15) flips 100B sha from `61d2caa5…` (pre-d683794) to `30b52336…` (post-d683794). d683794's diff is 100% resume-gated assertions + new subcommand handlers; none reaches the fresh-enum DFS path. The likely mechanism is LTO compiler-layout effects from added (unreachable-at-runtime) code subtly changing OpenMP thread scheduling or branch-prediction timing. **You cannot predict from source-reading whether a commit will flip 100B sha — only empirically.**
3. **~~Imperfect-resume during long-running generation contaminates the sha.~~ CORRECTED 2026-08-08 — this item was FALSE and is retracted; see [CORRECTIONS.md](CORRECTIONS.md) CX-34.** It read: *"The May-15 100B archive `f1709ab09486ba…` does not reproduce from its own baseline commit `3258f4c` on a clean re-run; same pattern as deprecated `c34390c0` (5.6T) and `f7b8c4fb` (10T)."* **It does reproduce.** `f1709ab0…` was regenerated from `3258f4c` — the very commit named here — and from three further code states across two lineages, all at 12,386,121 records (see §Reinstated below and `HISTORY.md`'s 2026-05-16 re-derivation, which recorded a byte-identical match at the time). The 2026-05-25 non-reproduction ran a **different decomposition** (`SOLVE_DEPTH=3`, `SOLVE_PER_SUB_BRANCH_LIMIT=631545`, ~158K shallow sub-branches, 27,664,734 records) from the engine's auto-divide (3,030 sub-branches × 33,003,300). A configuration difference, not contamination. **The sibling deprecations `c34390c0` and `f7b8c4fb` are NOT affected** — each cites a record-count delta against a named reproducible replacement, and both stand.

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

**Reinstated 2026-08-08 — the `d3 100B` sha `f1709ab0…` was previously listed above as deprecated.**
That deprecation is **retracted**; see [CORRECTIONS.md](CORRECTIONS.md) CX-34. The bytes reproduce
exactly from four code states across two lineages (v1 `3258f4c`, v1 `a2ead96`, v4 `b0221a31`,
v4 `a0542067`), all at **12,386,121 records**, all `f1709ab09486ba912ec5683a4c96211ff31d52b671e898b1b6e3421cc00aa9db`
over the 396,355,904-byte file (32-byte header + 12,386,121 × 32-byte records). It is a valid but
**configuration-specific** reference, produced by the engine auto-divide (**3,030 sub-branches ×
33,003,300 nodes**, `SOLVE_NODE_LIMIT=100000000000`, default depth). A different decomposition
(`SOLVE_DEPTH=3`, `SOLVE_PER_SUB_BRANCH_LIMIT=631545`, ~158K sub-branches) yields `30b52336…` with
27,664,734 records; both are correct at their own configuration. **100B remains unsuitable as a
cross-build verification gate** — see §"100B and sub-canonical reference shas (code-specific)" for why.

## Reproducibility parameters

Each canonical is fully reproduced by the env-var set below. `SOLVE_DEPTH` is the per-thread DFS depth; `SOLVE_PER_SUB_BRANCH_LIMIT` is the per-cell budget — the **only** budget the DFS actually enforces; `SOLVE_NODE_LIMIT` is the nominal global budget, from which the per-cell budget is derived by auto-divide *when no explicit PSB is given* (see §"Sha-determining vs operational env vars" below — with an explicit PSB, which every depth-3 recipe here supplies, `SOLVE_NODE_LIMIT` does not affect the output). Thread count must be 128 for byte-identical reproduction at the depth-3 canonicals (the merge dedup step is order-stable so other counts produce the same sha if the enumeration completes, but eviction-recovery and resume paths assume 128).

> **For any new re-derive launcher, copy the `SOLVE_PER_SUB_BRANCH_LIMIT` value verbatim from this table.** Do not re-derive from a `floor(NL / 158,364)` formula — the published values are the empirical PSBs that produced the canonical shas. See `petersm3/roae-private:LESSONS_LEARNED_2026_06_12_PSB_MATH_ERROR.md` for the incident that motivates this rule.
>
> ⚠ **This rule is for RE-DERIVING an existing canonical, not for EXTENDING one.** An extension that copies the parent PSB verbatim reproduces the parent's frontier byte-for-byte no matter what `SOLVE_NODE_LIMIT` it is given — see the **EXTENSION WARNING** in §"Sha-determining vs operational env vars" below.
>
> **Programmatic access (2026-06-13):** the same recipe lives in `solve.c` and is reachable via:
> ```
> solve --canonical-config 100T            # emit sha-determining env vars
> solve --canonical-config 100T --full     # also emit canonical DFS_ITERATIVE + DFS_CHECKPOINT
> solve --validate-launcher-config 100T <PSB>   # exit 0 if PSB matches recipe, 1 if not
> ```
> Known scales: `1T 5.6T 10T 11.2T 100T 560T`. ⚠ **[CORRECTED 2026-08-28 — this list also named `d2-10T`, which THIS COMMAND rejects — `solve --validate-launcher-config d2-10T <PSB>` returns **rc=25 'unknown scale'** for any PSB, while all six scales above return 0/1 (i.e. recognised, then judged). Verified by running the shipped binary across all seven. The command's own usage text lists it too and is equally wrong. A pre-flight gate that reports 'unknown scale' where a doc promises support fails OPEN for the caller who does not check the exit code — which is the whole point of a pre-flight. ⚠ **[FURTHER CORRECTED 2026-08-28 — the wording above first said the command "does NOT know" the scale, implying d2-10T is not a real configuration. **It is.** `solve --canonical-config d2-10T` resolves it cleanly (rc=0, emitting `SOLVE_DEPTH=2` and `SOLVE_NODE_LIMIT=10000000000000`), so the scale is genuine and only THIS validator refuses it — a `psb`-related fall-through at `solve.c:1397` / `:18858-76`, which is the untouched root cause. Removing the entry from this list treats the symptom. Found by the D2 lens-1 executed review; tracked as Q-345.]** ⚠ **[Q-345 FIXED 2026-08-29 — the root cause is gone. `--validate-launcher-config` now distinguishes the three cases: a known scale with a published PSB is judged (rc 0/1); a known scale with NO published PSB returns the new **rc=34** with a message saying so and pointing at `--canonical-config`; only a genuine typo returns rc=25, and its stderr now lists the PSB-bearing scales **generated from the recipe table** rather than from a hand-maintained literal — the literal is what drifted here in the first place. `--canonical-config` additionally explains on **stderr** why `d2-10T` emits no PSB line (stderr, not stdout, because the documented consumer is `eval $(./solve --canonical-config …)` and word-splitting would let a stdout `#` comment swallow every variable printed after it — measured: under `--full` it drops `SOLVE_DFS_ITERATIVE` and `SOLVE_DFS_CHECKPOINT`). So `d2-10T` is a real, config-only scale: reproducible via `--canonical-config`, and correctly not validatable for a PSB it does not have.]** Tracked as Q-324.]** Launchers should call `--validate-launcher-config` as a pre-flight gate before any compute is spent — see how `petersm3/roae-private:scripts/campaign_*_rederive/LAUNCH_*.sh` use it. Output deliberately omits `SOLVE_THREADS` because thread count is not sha-determining and depends on caller hardware.

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

`SOLVE_DEPTH` and `SOLVE_PER_SUB_BRANCH_LIMIT` are **sha-determining** — change either and the resulting `solutions.bin` sha changes. `SOLVE_NODE_LIMIT` is sha-determining **only when `SOLVE_PER_SUB_BRANCH_LIMIT` is unset**: it is then the auto-divide numerator (`per_branch_node_limit = SOLVE_NODE_LIMIT / total_branches`) and so fixes the walk. The `d2 10T` row is the one recipe in the table above in that state; **every depth-3 canonical above supplies an explicit PSB, and for those `SOLVE_NODE_LIMIT` does not determine the sha.**

⚠ **[CORRECTED 2026-08-30 — this section read "Only `SOLVE_DEPTH`, `SOLVE_NODE_LIMIT`, and `SOLVE_PER_SUB_BRANCH_LIMIT` are sha-determining — change them and the resulting `solutions.bin` sha changes." That is false for `SOLVE_NODE_LIMIT` under every published depth-3 recipe here, and this section exists precisely to tell an operator which knobs matter.** Two independent grounds, both established rather than argued. **(a) Source:** the explicit-PSB path assigns `per_branch_node_limit = per_sub_branch_override` directly, overwriting the `node_limit / divisor` auto-divide value; and DFS termination tests **only** the per-branch budget (`per_branch_node_limit > 0 && ts->branch_nodes >= per_branch_node_limit`). There is no global `nodes >= node_limit` stop anywhere in the walk. **(b) Execution, re-run 2026-08-30 on a scratch build outside the repo tree** (`gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz`), two runs differing only in `SOLVE_NODE_LIMIT`:
> ```
> SOLVE_THREADS=2 SOLVE_DEPTH=2 SOLVE_PER_SUB_BRANCH_LIMIT=50000 \
>   SOLVE_NODE_LIMIT=200000000 ./solve 0 2      # run A
> SOLVE_THREADS=2 SOLVE_DEPTH=2 SOLVE_PER_SUB_BRANCH_LIMIT=50000 \
>   SOLVE_NODE_LIMIT=400000000 ./solve 0 2      # run B
> ```
> Both emit a **byte-identical** `solutions.bin`: file sha256 `b5364c14b50f9e0b8b5ae96ed65b5c1ac35ac82775095b76d8e6883de1c69a58`, and the run's own `solutions.sha256` line reports `63f386032be7101e84e57f0b87b66c0ba1cb551c849bd6934190ec8f2926317e` in both. A 2× change in the variable this section called sha-determining changes nothing.
>
> **What `SOLVE_NODE_LIMIT` still does when a PSB is set** — it is not inert, it is simply not sha-determining: (i) it drives the pre-flight and safety gates, all thresholded at 1T — disk-space and fsync-IOPS pre-checks, the auto-selftest, host-fingerprint capture, and the sub-canonical refusal below 1T (which an explicit PSB is itself one of the two documented suppressors for); (ii) at `SOLVE_NODE_LIMIT >= 1T` it turns on `SOLVE_DFS_ITERATIVE` and `SOLVE_DFS_CHECKPOINT` as canonical-scale defaults unless they are set explicitly — every recipe above sets both explicitly, so that path is inert for them; (iii) it is recorded in the run metadata (`node_limit` in the provenance JSON and the shard-manifest header), which is what makes the failure mode below possible. Reported alongside this correction and **not** fixed here: the auto-divide progress line prints the override value inside the auto-divide arithmetic — `Per-sub-branch node limit: 50000 (400000000 / 3030 total-sub-branches)` — which reads as though 400000000/3030 = 50000. That is a `solve.c` output defect, not a doc defect.]**

⚠ **EXTENSION WARNING (2026-08-30).** The consequence of the above is prospective, and it is the reason this correction is not cosmetic. **An extension run MUST raise `SOLVE_PER_SUB_BRANCH_LIMIT`** — raising `SOLVE_NODE_LIMIT` alone does nothing. A "560T → larger" extension that copies the parent's `SOLVE_PER_SUB_BRANCH_LIMIT=3536157207` walks the **identical frontier** and produces the **identical `solutions.bin`**, while its metadata records the larger `SOLVE_NODE_LIMIT` — so it can be reported as a larger-budget run on the strength of a metadata field, and the sha that attests completion would not change to contradict it. Either raise the PSB, or unset it and accept auto-divide (understanding `SOLVE_CONCENTRATE_BUDGET` semantics on a resumed tree). This qualifies, and does not replace, the "copy the PSB value verbatim" rule in §Reproducibility parameters above: **copy verbatim to re-derive an existing canonical; never copy verbatim to extend one.**

The other variables shown above are **operational** — they affect runtime / scheduling / safety gates but produce byte-identical canonical output:

- `SOLVE_DFS_ITERATIVE=1` + `SOLVE_DFS_CHECKPOINT=1` — enable the iterative-DFS code path with on-disk checkpointing. Required for the multi-trillion-node depth-3 canonicals because the recursive path would blow the stack and there's no resume otherwise; sha-equivalent to the recursive path at scales that fit in memory.
- `SOLVE_THREADS=128` — parallelism degree. Sha-equivalent across `SOLVE_THREADS` values because the merge dedup step is order-stable (also reproduced at `SOLVE_THREADS=64` for the d3 10T canonical).
- `SOLVE_SKIP_AUTOMERGE=1` — skips the post-enum auto-merge step; needed when using the canonical pipeline pattern (separate Standard VM for merge).
- `SOLVE_SKIP_IOPS_CHECK=1` — skips the fsync-throughput pre-flight gate (exit 31). Skip it, or prefer `SOLVE_ALLOW_SLOW_IOPS=1` (probe runs and logs, launch proceeds), when a durable archival disk cannot clear the gate's *aggregate* floor — see the correction below for what that floor actually is.

  ⚠ **[CORRECTED 2026-09-02 — this bullet named a fixed single-thread fsync/sec floor as the gate's criterion. No such floor exists in the shipped binary.** It was the task-#107 design of 2026-05-27 and was retooled away two days later by task #115, *because it was mis-calibrated*: single-thread fsync is latency-bound and no network-attached managed disk reaches that rate, so the gate fired on every durable-disk canonical run and forced a manual override. `solve.c`'s own retool comment records the measurements that killed it — HDD 134/sec, Premium P40 218/sec, single-threaded. The retired figure is registered in [RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) and keyed in [CORRECTIONS.md](CORRECTIONS.md) as `RP-c410da42`.

  **What the gate is instead — a RATIO, not a rate.** It runs a concurrent probe over `min(threads,32)` workers to measure the aggregate fsync throughput the enum will actually see, then projects `expected_fsyncs = SOLVE_NODE_LIMIT / 1.4e7 / SOLVE_FSYNC_BATCH_SIZE` against `est_wall = SOLVE_NODE_LIMIT / (threads × 1e7)` and refuses when `fsync_wait / est_wall > 0.25`.

  **The floor is derivable, and `SOLVE_NODE_LIMIT` cancels out of it.** Solving `fsync_wait / est_wall ≤ 0.25` for the aggregate rate gives `agg ≥ threads / (1.4 × SOLVE_FSYNC_BATCH_SIZE × 0.25)` fsync/sec, so the floor scales with thread count and batch size and is **independent of the node budget**:

  ```
  python3 -c 'import sys; t,b=int(sys.argv[1]),int(sys.argv[2]); print(round(t/(1.4*b*0.25),1))' 128 1   # -> 365.7
  ```

  That is **≈366 aggregate fsync/sec at the canonical 128 threads with batch 1**, not the four-digit single-thread rate this bullet published. **The error was fail-open for the reader**, which is why it is corrected rather than merely restated: a host measuring 500 aggregate fsync/sec passes the real gate at 128 threads, and this bullet told its operator to disable the gate — losing exactly the protection the gate exists for. [SOLVE_C_CLI.md](SOLVE_C_CLI.md)'s exit-code 31 row already documented the ratio form correctly, and a whitespace-flattened corpus sweep for the retired figure found this to be its **last live site**; the two other occurrences ([HISTORY.md](HISTORY.md)'s #115 entry and that exit-31 row) both narrate it as superseded, which is correct. **Deliberately NOT changed: `solve.c`** — the code is right and has been since 2026-05-29; this was a documentation defect only. Found by Codex review V2-F25 #10; the floor formula and its node-budget independence are derived and landed here.]**

- `SOLVE_ALLOW_BUILD_MISMATCH=1` (**NOT in the recipe above** — historical campaign command lines included it as defense against rebuild-induced binary drift across VM teardown-recreate cycles; the current canonical launchers handle this by deleting stale `build.sha` post-rebuild instead, so the override is no longer required and shipping without it surfaces unexpected binary changes loudly). See [DEVELOPMENT.md](DEVELOPMENT.md#buildsha-invariant-outlier-4) for the build.sha invariant guard this flag overrides.

### PSB-formula caveat

The published `SOLVE_PER_SUB_BRANCH_LIMIT` values above are NOT all exactly `floor(SOLVE_NODE_LIMIT / 158,364)` — and where they do coincide, the coincidence is arithmetic luck, not a property of the formula:

| Scale | `SOLVE_NODE_LIMIT` | Recipe PSB | `floor(NL/158,364)` | Off by |
|---|---:|---:|---:|---:|
| 1T | 1000000000000 | 6,315,458 | 6,314,566 | +892 |
| 5.6T | 5600000000000 | 35,361,598 | 35,361,572 | +26 |
| 10T | 10000000000000 | 63,146,557 | 63,145,664 | +893 |
| 11.2T | 11200000000000 | 70,723,196 | 70,723,144 | +52 |
| 100T | 100000000000000 | 631,456,644 | 631,456,644 | 0 |
| 560T | 560000000000000 | 3,536,157,207 | 3,536,157,207 | 0 |

Every cell of that table — formula column and off-by column, all six rows — is reproduced by this one command (`NL`, `PSB` and the scale label are the only inputs; both computed columns are derived):

```
for p in 1T:1000000000000:6315458 5.6T:5600000000000:35361598 10T:10000000000000:63146557 11.2T:11200000000000:70723196 100T:100000000000000:631456644 560T:560000000000000:3536157207; do IFS=: read -r s nl psb <<<"$p"; f=$((nl/158364)); printf '%-6s %12d %12d %+d\n' "$s" "$psb" "$f" "$((psb-f))"; done
```

⚠ **[CORRECTED 2026-09-01 — the `floor(NL/158,364)` column was wrong in three of six rows, and the off-by column wrong in the same three. It read 5.6T `35,361,598` / off by `0`, 10T `63,146,544` / off by `+13`, and 1T `6,315,272` / off by `+186`; the correct floors are `35,361,572`, `63,145,664` and `6,314,566`, off by `+26`, `+893` and `+892`. The 100T, 560T and 11.2T rows were already right and are unchanged. Each corrected value was derived twice independently — shell integer division (the command above) and a bracketing multiplication confirming `158,364 × floor ≤ NL < 158,364 × (floor+1)` — and the two agree on all six rows.**
>
> **Why this mattered more than the digits.** No canonical is at risk: no sha, record count or file size depends on this table, and every published PSB in §Reproducibility parameters is unchanged. The error also pointed the safe way — the real divergence is *larger* than what was printed, which strengthens rather than weakens this section's conclusion, and that is very likely why it survived so long. But the 5.6T row asserted the formula agrees **exactly**, and that is the one failure mode a caveat cannot have. A reader who trusted it was told the shortcut is safe at one scale where it is in fact off by 26 nodes per cell — a different per-cell budget, therefore a different walk, therefore a different sha. A caveat that mis-states its own arithmetic is worse than no caveat, because it converts "do not use this formula" into "the formula is fine here."
>
> **The two exact rows are not an exception to the rule.** 100T and 560T do land exactly on `floor(NL/158,364)`; that is now the only claim of agreement this table makes, and it is verified above. It is not a licence to use the formula at those scales. The formula misses at four of the six published scales, including 11.2T which sits between the two exact ones, so exactness at 100T and 560T predicts nothing about any other scale — including any future one. **Derive nothing from this column. Copy the recipe PSB.**]**

The 1T / 5.6T / 10T / 11.2T published PSBs are the empirically-correct values — they're what the original enum runs used to produce the published canonical shas byte-identically across many independent witnesses. The original solve.c may have used a slightly different per-cell-budget computation (perhaps including per-thread checkpoint overhead, or a different rounding mode), or those rows may be documentation typos that have been faithfully reproduced across builds because everyone uses the published recipe. Either way: **use the published value**.

## Solver version

**v3** is the canonical-producing lineage on `main` HEAD as of 2026-05-25 (post-reset). v3 = v1 prune set + `-flto` + #72 bitset + v3.1 orphan-promotion patch. v3 sha-preserves on v1 byte-identically at every tested scale. The current `main` HEAD reproduces every Active canonical above. Specific commits that established each canonical are recorded in [HISTORY.md](HISTORY.md). v3 binary builds on stock toolchain — no patched glibc, no jemalloc, no PGO (the 2026-05-24 paired-bench re-run confirmed PGO did not replicate the predicted speedup):

```
# Minimum to reproduce canonical sha (the -DGIT_HASH stamp is sha-neutral — measured 2026-09-02:
# selftest 403f7202… with and without it — and is what makes the run's solutions.meta.json /
# solutions.provenance.json record the commit instead of the literal "unknown"):
gcc -O3 -pthread -fopenmp -march=native -DGIT_HASH="\"$(git rev-parse --short HEAD)\"" -o solve solve.c -lm -lz

# Recommended (sha-preserving, with LTO — Phase 1c validated 2026-05-15 on D64 Zen 4):
gcc -O3 -flto -pthread -fopenmp -march=native -DGIT_HASH="\"$(git rev-parse --short HEAD)\"" -o solve solve.c -lm -lz
```

Both commands produce the canonical selftest sha `403f7202…` and reproduce every canonical above byte-identically. `-flto` (link-time optimization) reduces binary size ~1-2% and produces a ~2% wall-time speedup at 100B-node canonical-correlation scale on AMD Zen 4 with tight run-to-run variance (stddev 0.11% across 4 trials). Drop it if your toolchain doesn't support LTO.

**Historical lineages:**
- **v1** (original lineage, pre-2026-05-21) — anchor lineage; v3 reproduces v1's shas byte-identically.
- **v2** (canonical-producing 2026-05-21 → 2026-05-24, then closed) — v2 11.2T `2cc966e4…` and v2 100T `cc4a5377…` are frozen historical canonicals (see §"Historical (frozen lineages)" above). v2 binary reproduces those shas; current `main` HEAD does not. Pre-reset state preserved at tags `v2-merged-2026-05-21` and `v2-with-v3.1-attempt-2026-05-25`.

## How to verify a `solutions.bin`

```
gzip -dc solutions.bin | sha256sum
# Compare to the row above.
# Since #169 solutions.bin is gzip-framed by default and every canonical sha is computed on the
# DECOMPRESSED stream, so plain `sha256sum solutions.bin` hashes the container and false-mismatches.
# Under SOLVE_COMPRESS=0 the file is raw and plain `sha256sum solutions.bin` is the right command.
# Either way the solutions.sha256 sidecar already holds the logical sha — TRUE SINCE 2026-08-28,
# AND NOT BEFORE ON ONE PATH. solve.c had two sidecar writers: the enumeration path used
# sha256_of_logical(), but standalone `--merge` shelled out `sha256sum <file>`, so under the
# default gz framing it recorded the CONTAINER sha (and solutions.meta.json inherited it, being
# parsed back out of the sidecar). If a sidecar was written by a standalone `--merge` before
# 2026-08-28, verify it with `gzip -dc solutions.bin | sha256sum` before trusting a mismatch:
# a container sha false-mismatches an artifact that is byte-identical where it counts.
# Fixed + gated by scripts/sidecar_sha_gate.sh; see CORRECTIONS.md 2026-08-28.
```

For independent constraint-spec verification (slower than sha but cross-checks the binary's enumeration logic):

- C-side: `solve --verify solutions.bin` — checks every record satisfies C1–C5, plus sorted-order and dedup, per [SPECIFICATION.md](SPECIFICATION.md). ⚠ **King Wen's presence is printed, not enforced, by `--verify`** (measured 2026-09-02: the King Wen record deleted from an artifact and the header count patched → `King Wen found: No` … `VERIFY=PASS`, rc 0). Read that line by eye; folding it into the verdict (`--expect-kw`) is a prepared `solve.c` change held behind the solve.c change gate. *(Corrected 2026-09-02 — this line previously listed "KW-present" among the checks.)*
- Python-side: `python3 verify.py --jobs N --expect-kw solutions.bin` — independent re-implementation. `--expect-kw` makes King Wen's absence a FAIL (rc 1), which on a complete canonical it must be; without it the verifier reports `KW_PRESENT=NO` and certifies the records only. The `--jobs` flag parallelizes; `--jobs 128` matches the canonical's enumeration parallelism but any value works for verification.

Both verifiers operate without reference to the canonical sha; they validate the file against the constraint specification directly.

## How to re-derive from scratch

```
git clone https://github.com/petersm3/roae
cd roae
# pin the source: check out the commit named in the canonical's row above before building
gcc -O3 -pthread -fopenmp -march=native -DGIT_HASH="\"$(git rev-parse --short HEAD)\"" -o solve solve.c -lm -lz
./solve --print-config | grep git_hash   # must NOT say "unknown" — that is the provenance stamp the run writes
./solve --selftest                    # must print sha 403f7202
ulimit -s unlimited                   # required at large scales
<env vars from the table above> ./solve 0 128
gzip -dc solutions.bin | sha256sum    # must match the canonical row (gz-framed by default since #169;
                                      # plain sha256sum hashes the container, not the canonical stream)
```

The smallest validation reproduces in seconds (selftest). The d3 10T canonical reproduces in approximately 60-90 minutes on a 128-vCPU machine. The d3 100T reproduces in approximately 11-19 hours. Lower thread counts work; the wall time scales roughly linearly with `1/threads` for d3 enumeration.

## Format

`solutions.bin` is a 32-byte header followed by 32-byte records. Each record encodes a canonical ordering of the 64 hexagrams. See [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) for the byte-level encoding and the dedup semantics.

**Size convention (applies to every entry above):** the **File size** field is always the on-disk size *including* the 32-byte header; the record count is `(size − 32) / 32`. A merge/`--analyze` log line that reports "records × 32" (record-bytes only) is 32 bytes short of the on-disk size — that fence-post is the source of the 2026-06-14 false-corruption alarm and the 2026-07-04 100T count re-correction.

Records are deduplicated at merge time by canonical form (orient-bit-masked); the reported record count equals the number of distinct canonical orderings the enumeration discovered within its budget. The full mathematical search space is much larger than any partial enumeration here (estimated at ≈3×10³⁷ distinct-canonical orderings — see [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md)); canonicals at higher node budgets reveal more of it but cannot approach exhaustion. ⚠ **[WITHDRAWN 2026-08-24 — the ≈3×10³⁷ distinct-canonical figure on this line exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]**

## Validation status

A canonical is listed as Active when at least one of the following holds:
- Single-shot full-enumeration reproduces the sha byte-identically.
- Multi-path equivalence (e.g., 56-branch decomposition merged globally) reproduces the same sha.
- Cross-architecture reproduction (x86 + ARM) yields the same sha.

Each Active canonical above has been validated by at least one of these paths; the d3 11.2T canonical has been validated by all three across eight independent paths. Detailed validation history per canonical is recorded in [HISTORY.md](HISTORY.md) and [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md).
