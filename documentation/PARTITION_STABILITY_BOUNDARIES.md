# Partition Stability of Boundaries {25, 27}

**Result:** Across four independent canonical enumerations of the **C1–C5** search space at progressively larger node budgets and two partition depths (d2 10T; d3 at 10T, 100T and 560T — four different sha-anchored datasets), boundaries **{25, 27} appear in every greedy-ordered minimum-boundary set that uniquely identifies the King Wen ordering, at all four partitions tested**. The greedy-minimum count is **monotone non-decreasing with node budget** (4 → 5 → 5 across 10T → 100T → 560T; *corrected 2026-07-04 — an earlier version stated "non-monotone 4 → 5 → 4", a survivor-counting error, see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md)*); {25, 27}'s presence in every greedy minimum is the durable invariant. *("C1–C5" is the constraint set this document has always described; older text here and in `solve.c`'s console strings called the same population by the legacy shorthand — see [METHODS.md](../reports/METHODS.md) §"Legacy shorthand" and [GUIDE.md](GUIDE.md) §Glossary. Renamed 2026-09-02.)*

**Scope of that claim, stated once for this document.** §[7] and §[8] exhaustively test all C(31, 3) = 4,495 triples and all C(31, 4) = 31,465 quadruples, but §[6] returns **one** greedy path per dataset — deterministic, with ties broken toward the lowest boundary index (`solve.c` §Section 6, the strict `surv < best_remain` comparison in the per-step scan). The C(31, 5) = 169,911 five-subsets **have never been enumerated**, and no tied alternative greedy trajectory was enumerated either, so **no 5-subset lacking 25 or 27 has been tested**. What the searches support is therefore "{25, 27} are in the greedy representative at each of the four partitions" — not "{25, 27} are in every minimum identifying set", which is a strictly stronger statement the searches performed cannot decide. [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) §"How positions relate to one another (mutual information)" has carried the same scope note since 2026-09-01. *(Rescoped 2026-09-02: this document previously stated the claim with the word "mandatory" and without the subset-size scope; see [CORRECTIONS.md](CORRECTIONS.md).)*

This is the **most stable structural property of King Wen we have measured**. The boundary count itself, and the OTHER boundaries that round out the minimum set, both vary with partition and scale; {25, 27} do not.

## What "boundary" means here

The 31 between-pair boundaries of the King Wen sequence each have a specific Hamming distance distribution. A "boundary" in this context refers to a between-pair index k ∈ {1..31} (positions 2k-1, 2k). For each non-KW ordering in the canonical set, we can ask which boundaries it differs from KW on; the **greedy-ordered minimum identifying set** is the smallest ordered tuple of boundaries such that requiring sequential agreement reduces the canonical set to {KW}, with each boundary chosen to maximize elimination on the surviving set after prior boundaries.

A related but distinct question — the **unordered minimum identifying set** — asks for the smallest *unordered* set of boundaries whose joint conjunction reduces survivors to ≤ 1. This is the more common "K boundaries uniquely identify KW" rhetorical framing. We measure both.

## Source data

Four sha-anchored canonical enumerations:

| Partition depth (`SOLVE_DEPTH`) | Node budget | sha256 | Records | Source archive |
|---|---|---|---|---|
| d2 | 10T | `a09280fb8…` | 286,357,503 | `runs/20260418_10T_d2_fresh/` (public) |
| d3 | 10T | `f7b8c4fbf…` ¹ | 706,422,987 | `runs/20260418_10T_d3_fresh/` (public) |
| d3 | 100T | `915abf30c…` | 3,432,399,297 | `canonical-archive/t9c1/` — **operator-held cold blob**, not a public URL (T9+c.1 recovery; cf. [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Access boundary") |
| **d3** | **560T** | **`9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`** | **10,525,271,997** | **`canonical-archive/20260608_560T_9a968fa2/`** — **operator-held cold blob**, not a public URL (same access-boundary note) |

Only the **budget** varies across 10T / 100T / 560T: `SOLVE_DEPTH=3` throughout, with `SOLVE_PER_SUB_BRANCH_LIMIT` — the per-cell budget the DFS actually enforces — stepping 63,146,557 → 631,456,644 → 3,536,157,207 ([CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Reproducibility parameters"; the campaign names 10T/100T/560T are the nominal `SOLVE_NODE_LIMIT` values, which are not themselves sha-determining once an explicit per-cell budget is supplied). The only partition-depth comparison the project has ever run is d2 vs d3, both at 10T. *(Column split 2026-09-02: a single "Partition" column mixed the two axes, which is where this document's depth/budget conflation started — see [CORRECTIONS.md](CORRECTIONS.md).)*

Each was independently enumerated and merged on Azure compute; canonical SHAs reproducible across hardware/region/merge-algorithm via the partition-invariance theorem (see [`PARTITION_INVARIANCE.md`](../documentation/PARTITION_INVARIANCE.md)).

¹ The stability analyses in this document were computed on the 2026-04-18 d3 10T file (`f7b8c4fbf…`). That sha was later deprecated (pre-resume-fix undercount) in favor of `b85c8871…`/706,427,594 — see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Deprecated.

## Method

For each canonical, ran [`./solve --analyze solutions.bin`](SOLVE_C_CLI.md#--analyze):
- §[6] greedy minimum-boundary search — iteratively picks one boundary at a time, each maximizing elimination of non-KW survivors; terminates when only KW remains
- §[7] exhaustive 3-subset test — all C(31, 3) = 4,495 triples; reports the best (minimum-survivors) triple
- §[8] exhaustive 4-subset enumeration — all C(31, 4) = 31,465 quadruples; reports every joint 4-set whose conjunction reduces survivors to ≤ 1

The greedy-ordered minimum (§[6]) and the count of unordered working 4-sets (§[8]) are distinct measures.

## Result table — minimum identifying boundary sets

Two different objects live in this table and were previously merged into one "Greedy set" column: the **single** set §[6]'s greedy walk selects (one per dataset), and the **family** of unordered 4-sets §[8] finds by exhaustion. They are split below, and each is transcribed from the shipped `analyze_output.log.gz` for that run.

| Dataset | Greedy-ordered min size | Greedy set (§[6], in greedy order) | Working 4-sets (§[8], exhaustive over C(31,4)) | §[8] count | {25, 27} in greedy set? |
|---|---:|---|---|---:|:---:|
| d2 10T (286M) | **4** | `{2, 27, 25, 21}` | `{25, 27} ∪ one-of-{2,3} ∪ one-of-{21,22}` — exactly 2 × 2 = 4 sets | 4 | ✓ |
| d3 10T (706M) | **4** | `{4, 27, 25, 1}` | exactly these 8: `{2,3,25,27}` `{3,4,25,27}` `{3,5,25,27}` `{3,6,25,27}` `{2,4,25,27}` `{2,5,25,27}` `{1,3,25,27}` `{1,4,25,27}` | 8 | ✓ |
| d3 100T (3.43B) | **5** | `{4, 27, 25, 21, 1}` | none | 0 | ✓ |
| **d3 560T (10.5B)** | **5** | **`{4, 27, 25, 21, 1}`** (cumulative non-KW survivors 51,404 → 481 → 14 → 1 → 0) | **none** | **0** | **✓** |

⚠ **[CORRECTED 2026-09-02 — the d3 10T working-4-set family was published as a shorthand union of `{25, 27}` with any two of `{1..6}`. That shorthand admits C(6,2) = 15 sets, so it advertised **7 that do not work**: `{1,2}`, `{1,5}`, `{1,6}`, `{2,6}`, `{4,5}`, `{4,6}`, `{5,6}`, each ∪ `{25, 27}`. The 8 that do work are listed above, verbatim from `runs/20260418_10T_d3_fresh/analyze_output.log.gz` §[8]. The d2 shorthand is **not** affected — `one-of-{2,3} ∪ one-of-{21,22}` is exactly 4 sets and exactly the family §[8] reports. Separately, both 10T rows previously carried their §[8] family under a "Greedy set" heading: the d2 greedy walk in fact picks `2 → 27 → 25 → 21` and the d3 10T walk `4 → 27 → 25 → 1`, each a single set, neither a family. See [CORRECTIONS.md](CORRECTIONS.md).]**

The **greedy-ordered minimum is monotone non-decreasing with scale** (4 → 5 → 5 across d3 10T → 100T → 560T; the 560T row was corrected 2026-07-04 from "4 / {4, 27, 25, 21}" — a survivor-counting error, see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md)). The **working-4-set count** collapses with scale (8 → 0 across d3 10T → 100T, then stays at 0 at 560T, with the prior 742M-era figure of 4 being a smaller-budget intermediate computed under the pre-format-v1 "survivors ≤ 4" convention, not the canonical-era "≤ 1" — directionally comparable, not convention-identical; see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md) §Result table). §[7] at 560T proves no 3-tuple of boundaries works (best `{4, 25, 27}` leaves 15 survivors), and §[8] = 0 proves no 4-set works, so 5 is the exact minimum **size** at the deepest published scale. Which 5-sets attain it is a separate, unrun question — see §Result's scope note.

## What this implies

**{25, 27} as a stable structural anchor.** No matter the partition depth (d2 and d3 tested) and no matter the node budget (10T to 560T tested; 286M to 10.5B records), boundaries 25 and 27 appear in the greedy-ordered minimum-boundary set §[6] returns. They are the **single most stable structural finding** the project has measured — at the scope §Result states: greedy representatives at four partitions, not every minimum identifying set.

**The boundary-minimum size is monotone non-decreasing with scale, and stable at canonical depth.** One increment (4 → 5 across 10T → 100T), then stability: the 560T greedy minimum is 5 with the *identical set in the identical greedy order* as 100T. The 100T-era prediction that the minimum would "continue to grow toward 6 at 1000T+" is neither confirmed nor refuted, and **now cannot be**: the 1120T extension that would have supplied the next datapoint is **not planned** (2026-08-01). This is a permanent limitation, not a pending measurement. *(Corrected 2026-07-04: this paragraph previously reported a "drop back to 4" at 560T and hypothesized a mechanism for it; both rested on a survivor-counting error, see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md).)*

**4-set identification is scale-bounded.** The popular phrasing "exactly 4 specific boundaries uniquely identify KW" was true at 10T scales (when 4 or 8 working 4-tuples existed) but fails at 100T and 560T (where 0 4-tuples reduce survivors to ≤ 1). At canonical depth the minimum identifying set size is 5.

**Partition-stability claims must be scoped.** A finding "X holds at d2 10T" does not imply "X holds at deeper enumeration." Future ROAE results should always specify the partition depth + scale + sha of the underlying canonical at which a claim was verified.

## Implications for the analysis paper

- **§3 (Constraint system and canonical dataset)** can list the four canonical SHAs and their record counts as the empirical anchor.
- **§4 (Null-model framework results) / §5 (Analytic results)**: the {25, 27} stability across four scales is robust, paper-citable.
- **§7 (Discussion)**: the boundary-minimum trajectory (monotone 4 → 5, then stable at canonical depth with an identical identifying set) warrants a dedicated paragraph, while preserving {25, 27}'s presence in every greedy-ordered minimum as the genuine structural invariant — stated at that scope, because the C(31, 5) = 169,911 five-subsets were never enumerated (§Result, §"Limits and scope"). See [`BOUNDARY_MINIMUM.md`](BOUNDARY_MINIMUM.md) for the detailed cross-scale comparison.

## Reproducibility

```bash
./solve --analyze solutions.bin > analyze_output.log    # reads canonical bin
# Output includes minimum-boundary report (§[6], §[7], §[8]) at the bottom
```

Pre-computed analyze logs:
- d2 10T, d3 10T, d3 100T: alongside the canonicals in `runs/{20260418_10T_d2_fresh, 20260418_10T_d3_fresh, 20260419_100T_d3_d128westus3}/analyze_output.log.gz` (the 100T run archive is the original; T9+c.1 recovery analyze log was not preserved separately)
- **d3 560T: `canonical-archive/20260608_560T_9a968fa2/analyze_v3_560T.log` — ⚠ NOT PUBLIC.** `canonical-archive/…` is operator-held cold blob storage, not a public URL ([CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Access boundary"); `runs/20260608_560T_9a968fa2/` in this repository holds only `viz/`. Every 560T §[6]–§[8] figure on this page is a **transcription** from that operator-held log, not a citation a reader can follow. (13,631 s wall on D128 with the algorithmic rewrites in `solve.c` commits 8ac5e8f, fe58e71, bf8d8a5, c0ec4c3; selftest sha `403f7202…`)

## Limits and scope

- Four datapoints (d2 10T, d3 10T, d3 100T, d3 560T). The 4 → 5 → 5 trajectory observed across d3 {10T, 100T, 560T} cannot be extrapolated to 1120T+ depths without measurement, and **no such measurement is planned** — the 1120T extension campaign was considered and declined (2026-08-01). There will be no fifth datapoint.
- The §[7] / §[8] passes are exhaustive at the relevant subset sizes (all C(31, 3) = 4,495 and C(31, 4) = 31,465). The greedy §[6] is heuristic-ordered; however where §[8] = 0 (100T, 560T) the greedy 5-set is exactly minimal **in size** (no 4-set can work), and at 10T where §[7] = 0 the greedy 4-set is exactly minimal in size (no 3-set can work).
- **Minimal in size is not the same as unique in membership.** At 100T and 560T the only 5-set ever scored is the one §[6]'s greedy walk produced; the C(31, 5) = 169,911 five-subsets were **not** enumerated, and §[6] emits a single deterministic path (ties resolved toward the lowest boundary index), so tied alternative trajectories were not enumerated either. No 5-subset lacking 25 or 27 has been tested at any scale. At 10T the corresponding claim **is** settled at size 4: §[8] exhausts C(31, 4) and reports 25 and 27 at 100.0% frequency in the working sets (`Boundaries appearing in EVERY working 4-set: { 25 27 }` in both 10T logs).
- d4+ partitions have not been tested; partition-strategy is held constant at d3 for the 100T/560T datapoints.

## Working / process documentation

For the original 2026-04-19 cross-partition analysis (d2 10T + d3 10T + d3 100T), see the `petersm3/roae-private` staging repo's `D2_D3_ANALYZE_FINDINGS.md` (now `petersm3/roae-private` per the 2026-05-29 rename). For the 560T `--analyze` algorithmic rewrites that made canonical-scale analyze tractable, see `documentation/HISTORY.md` "June 10-11, 2026" entry; for the full §[1]-§[28] 560T findings, see `documentation/PROJECT_OVERVIEW.md` §"560T canonical results" and (private) `roae-private/560T_FINAL_ANALYSIS.md`. *(The `roae-private` files named here are in a private staging repo — not publicly accessible; they are working-log provenance.)* ⚠ **Sourcing, stated plainly (2026-09-02).** The d2 10T, d3 10T and d3 100T §[6]–§[8] figures on this page **are** publicly sourced: their `analyze_output.log.gz` files ship in `runs/` in this repository and every figure above can be read out of them. The **560T** figures are not: the primary log is operator-held (§Reproducibility), so the 560T rows are transcriptions. They were checked against that log line-by-line in a 2026-07 primary-evidence sweep recorded privately in `roae-private/PRIMARY_EVIDENCE_SWEEP_2026_07.md` — operator-attested, disclosable to an auditor, not fetchable by a reader. A reader who wants public 560T primary evidence does not have it here; what is public is the canonical sha `9a968fa2…`, the reproduction recipe ([CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Reproducibility parameters"), and the `./solve --analyze` command that regenerates the log from it. *(This sentence previously asserted that everything a reader is asked to accept was sourced publicly above, which was false for the 560T row; see [CORRECTIONS.md](CORRECTIONS.md).)*

---

*Revision 2026-09-02 (adjudicated correction batch — five findings): five defects corrected, none of which moves a count, a sha or a survivor ladder. (1) **Scope.** "{25, 27} are mandatory" is restated as "{25, 27} appear in every greedy-ordered minimum-boundary set at the four partitions tested", with a scope paragraph in §Result: §[7]/§[8] exhaust C(31, 3) and C(31, 4), §[6] emits one deterministic greedy path per dataset, and the C(31, 5) = 169,911 five-subsets were never enumerated, so no 5-subset lacking 25 or 27 has been tested. (2) **Constraint set.** The enumerated population is named **C1–C5**; the legacy "C1+C2+C3" shorthand for the same population is retired here per [METHODS.md](../reports/METHODS.md) §"Legacy shorthand". (3) **The d3 10T working-4-set family** was published as a 15-set shorthand for an 8-set result; the 8 sets are now listed verbatim, and the §[6] greedy set is split into its own column at every row — the two 10T rows previously showed a §[8] family under a "Greedy set" heading. (4) **Sourcing.** The 560T §[6]–§[8] figures are marked as transcriptions from an operator-held log, replacing a claim that everything on the page was publicly sourced; the 10T/100T figures, which do ship in `runs/`, are distinguished from them. (5) **Axes.** Node budget is no longer called partition depth: the source-data table splits "Partition" into depth and budget, and the two "partition depth (10T to 560T)" phrasings are corrected — the only partition-depth comparison ever run is d2 vs d3, both at 10T. Full ledger: [CORRECTIONS.md](CORRECTIONS.md).*

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*
