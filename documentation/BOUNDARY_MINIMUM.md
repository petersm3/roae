# Boundary Minimum Size: Monotone 4 → 5, Stable at Canonical Depth

*(revised 2026-07-04; supersedes the "non-monotone 4→5→4" version of 2026-06-11, formerly `BOUNDARY_MINIMUM_NON_MONOTONE.md`)*

**Revision note (2026-07-04).** The 2026-06-11 version of this document reported the greedy boundary minimum as "4 at 10T → 5 at 100T → 4 at 560T (non-monotone)". That was a survivor-counting error, not a property of the data: the "4 at 560T" counted greedy steps until **≤ 1 non-KW survivor** remained, while the "5 at 100T" counted steps until **0** remained — and this document's own definition requires reduction to {KW} (zero non-KW). The canonical 560T analyze log (§[6]) in fact runs five steps, `{4, 27, 25, 21}` leaving one non-KW survivor and boundary 1 eliminating it: `Boundaries chosen: { 1 4 21 25 27 }` — identical to 100T. The previously-published "ordered vs unordered minimum" distinction also dissolves: boundary conjunction is a commutative intersection, so no ordering of 4 boundaries can succeed where the unordered 4-set fails (§[8] = 0 at 100T/560T already implied the minimum exceeds 4). We are correcting rather than silently revising; the prior text remains in git history.

**Result:** The number of boundary constraints required to uniquely identify King Wen among **C1–C5** canonical orderings is **4 at d3 10T and 5 at both d3 100T and d3 560T** — **observed non-decreasing across the three budgets tested**; three datapoints bound no trend — with the set `{1, 4, 21, 25, 27}` (identical membership and greedy order) at both canonical scales. No 3-subset works at any scale (§[7]), and no 4-subset works at ≥100T (§[8] = 0), so 5 is exact at 100T/560T.

**The single hardest-to-kill King Wen impostor is the same *ordering* at every tested depth:** King Wen with the pair blocks at positions 2 and 3 interchanged (hexagrams 3/4 ↔ 5/6, Zhun/Meng ↔ Xu/Song). Its `rec#` index is **not** stable across datasets — a `rec#` is a position in one dataset's own sort order — so the same ordering is `rec#330177707` at d3 560T, `rec#104178045` at d3 100T (§[24] row 12 of the shipped 100T log) and `rec#21262918` at d3 10T (§[24] row 10). Quote the swap, not the index. It survives {4, 21, 25, 27} because it matches KW at every pinned position; only a front-zone boundary (1, 2, or 3) eliminates it. The 5th boundary in the identifying set exists solely for this one twin (§[6] count = 1 + §[24] membership check).

The 100T-era prediction that the minimum would "continue to grow toward 6 at 1000T+" is neither confirmed nor refuted by 560T: the trajectory shows one increment (10T → 100T) then stability (100T → 560T). **This question is now permanently open** — a 1120T extension would have supplied the next datapoint, but it is **not planned** (operator decision, 2026-08-01), and no deeper canonical is scheduled. The reader should treat the 4 → 5 → 5 trajectory as the final measured evidence, not as a partial series awaiting completion. Boundaries **{25, 27} are in every greedy minimum at all four partitions tested** (most stable structural finding — see [`PARTITION_STABILITY_BOUNDARIES.md`](PARTITION_STABILITY_BOUNDARIES.md)).

## What is being measured

Two views of the boundary identification problem are measured:

**(A) Greedy-ordered minimum size (§[6] in [`solve --analyze`](SOLVE_C_CLI.md#--analyze)).** The smallest tuple of boundaries `(b_1, b_2, ..., b_k)` such that sequential application **reduces survivors to {KW}** (zero non-KW survivors), where boundary `b_i` is chosen at each step to maximize elimination on the current surviving set. The algorithm is deterministic given the canonical solution set.

**(B) Unordered minimum-set count (§[8] in `solve --analyze`).** The number of *unordered* subsets of size 4 such that the conjunction of "matches KW on every boundary in this set" reduces survivors to ≤ 1. This is the count of "exactly-4-boundary unique identifications" that the popular framing assumes exists.

Because boundary matching is a set intersection (commutative), the greedy "order" is a search heuristic, not a semantic difference: any permutation of the same boundary set eliminates the same records. (A) and (B) are therefore consistent by construction — when §[8] = 0, no 4-set (ordered or not) can reach {KW}, and the greedy §[6] minimum is necessarily ≥ 5. The 2026-06-11 version of this document claimed (A) could be smaller than (B) "because order matters"; that claim was incorrect and is retracted in the revision note above.

## Source data

Four sha-anchored canonical enumerations:

| Partition | sha256 | Records | Source archive |
|---|---|---|---|
| d2 10T | `a09280fb8…` | 286,357,503 | `runs/20260418_10T_d2_fresh/` |
| d3 10T | `f7b8c4fbf…` ¹ | 706,422,987 | `runs/20260418_10T_d3_fresh/` |
| d3 100T | `915abf30c…` | 3,432,399,297 | `canonical-archive/t9c1/` — **operator-held cold blob**, not a public URL (T9+c.1 recovery; cf. [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Access boundary"). Its **analyze log ships**: `runs/20260419_100T_d3_d128westus3/analyze_output.log.gz`. |
| **d3 560T** | **`9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`** | **10,525,271,997** | **`canonical-archive/20260608_560T_9a968fa2/`** — **operator-held cold blob**, not a public URL (same access-boundary note). Its analyze log does **not** ship: `runs/20260608_560T_9a968fa2/` in this repository holds only `viz/`. |

¹ The boundary analyses in this document were computed on the 2026-04-18 d3 10T file (`f7b8c4fbf…`). That sha was later deprecated (pre-resume-fix undercount) in favor of `b85c8871…`/706,427,594 — see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Deprecated; the delta is 4,607 records and does not affect the boundary findings' scope labels.

² The 742M figure cited below is the pre-format-v1 (pre-2026-04-19) hash-table-bug dataset; it is historical-only and is not sha-anchored as a valid canonical. It is included in the unordered-count trajectory for completeness because it was the dataset under which the original "exactly 4 specific boundaries" finding was first reported. **Its (B) value of 4 is not Measure B as defined above.** `enumeration/analyze_c_742M.txt` §[8] is headed *"All 4-subsets that reduce survivors to **<=4**"* and lists four sets each reporting `survivors=4`; §[7] of the same log tests "Triples reaching **<=4** survivors". That **≤4** is the pre-format-v1 convention, and §[4] of the log says why: `KW records found: 4` — that dataset held King Wen as **four un-deduplicated orientation variants** (varying at positions 2, 3, 28, 29, 30), so "survivors ≤ 4" there carries the meaning "survivors ≤ 1" carries on an orientation-deduplicated canonical. Under this document's literal ≤ 1 definition the 742M value would be **0**, because King Wen alone accounts for four survivors in that dataset. The row is retained for trajectory continuity and is **not** convention-identical to the four canonical rows. (§[6] on the same log *is* directly comparable, because it counts *non-KW* survivors: it reaches 0 with `{2, 21, 25, 27}`, a greedy minimum of 4.)

## Result table

| Dataset | Greedy-ordered min size (A) | Greedy set (§[6], in greedy order) | Working 4-sets (§[8], exhaustive over C(31,4)) | (B) count | {25, 27} in greedy set? |
|---|---:|---|---|---:|:---:|
| d2 10T (286M) | **4** | `{2, 27, 25, 21}` | `{25, 27} ∪ one-of-{2,3} ∪ one-of-{21,22}` — exactly 2 × 2 = 4 sets | 4 | ✓ |
| d3 10T (706M) | **4** | `{4, 27, 25, 1}` | exactly these 8: `{2,3,25,27}` `{3,4,25,27}` `{3,5,25,27}` `{3,6,25,27}` `{2,4,25,27}` `{2,5,25,27}` `{1,3,25,27}` `{1,4,25,27}` | 8 | ✓ |
| 742M (historical) ² | — | — | — | 4 ² (≤4-survivor convention — **not** Measure B; see ²) | — |
| d3 100T (3.43B) | **5** | `{4, 27, 25, 21, 1}` | none | 0 | ✓ |
| **d3 560T (10.5B)** | **5** | **`{4, 27, 25, 21, 1}`** (cumulative non-KW survivors 51,404 → 481 → 14 → 1 → 0) | **none** | **0** | **✓** |

⚠ **[CORRECTED 2026-09-02 — column A and column B held two different objects and the "Greedy set" column carried both. §[6] selects a **single** ordered set per dataset; §[8] returns a **family**. The two 10T rows previously showed the §[8] family under the greedy heading: the d2 greedy walk picks `2 → 27 → 25 → 21`, the d3 10T walk `4 → 27 → 25 → 1`. Separately, the d3 10T family was published as a shorthand union of `{25, 27}` with any two of `{1..6}`, admitting C(6,2) = 15 sets and therefore advertising **7 that do not work** (`{1,2}` `{1,5}` `{1,6}` `{2,6}` `{4,5}` `{4,6}` `{5,6}`, each ∪ `{25, 27}`); the 8 that do are listed above verbatim from `runs/20260418_10T_d3_fresh/analyze_output.log.gz` §[8]. The d2 shorthand is exact and unchanged. See [CORRECTIONS.md](CORRECTIONS.md).]**

§[7] at d3 560T proves no 3-tuple of boundaries works (best `{4, 25, 27}` leaves 15 survivors, KW-inclusive), and §[8] = 0 proves no 4-set works, so **5 is the exact minimum at both canonical scales (100T, 560T)**.

The cumulative-survivor curve for d3 560T's greedy set is striking: boundary 4 ALONE eliminates 99.999% of non-KW records (51,404 survive out of 10,525,271,996). Boundaries 27, 25, 21 then sequentially narrow the survivors by ~107×, ~34× and ~14× (51,404 → 481 → 14 → 1), and boundary 1 eliminates the single remaining impostor (rec#330177707).

## What this implies

**The boundary-minimum trajectory is monotone non-decreasing across tested depths: 4 (10T) → 5 (100T) → 5 (560T).** Deeper enumeration surfaced KW look-alikes that pushed the minimum from 4 to 5 between 10T and 100T; a further **5.6× enumeration budget** (100T → 560T: `SOLVE_PER_SUB_BRANCH_LIMIT` 631,456,644 → 3,536,157,207, per [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Reproducibility parameters"), which yielded **3.07× the records** (3,432,399,297 → 10,525,271,997), surfaced no look-alike requiring a 6th boundary. The identifying set is not merely the same *size* at both canonical scales — it is the *same set in the same greedy order*, `{4, 27, 25, 21, 1}` (§[6] prints the chosen set as `{ 1 4 21 25 27 }`).

**The 5th boundary exists for exactly one record.** After `{4, 27, 25, 21}`, the sole surviving non-KW record at both canonical scales is the **position-2/3 block swap** — KW with the pair blocks at positions 2 and 3 interchanged — carried as `rec#330177707` at 560T and `rec#104178045` at 100T (the ordering is the same at both scales; the index is dataset-relative, see the head of this document). It matches KW at every position the 4-set pins; only a front-zone boundary (1, 2, or 3) distinguishes it, and greedy picks boundary 1. The argument runs off §[24] plus §[6] at either scale: the edit-distance-2 catalog shows exactly one dist-2 record avoiding all pinned positions, and §[6]'s step-4 survivor count is exactly 1. At **560T** that catalog holds **14** dist-2 records and the check is a transcription (§Reproducibility); at **100T** it holds **12**, and the check is public — `runs/20260419_100T_d3_d128westus3/analyze_output.log.gz` prints `[ 12] dist=2 rec#104178045: pos2=2 pos3=1` in §[24] and `Step 4: Boundary 21 eliminates 6, 1 remain` in §[6]. The **14** is a 560T-only figure and must not be quoted at 100T.

**The popular "4 specific boundaries uniquely identify King Wen" framing is scale-bounded.** The number of working 4-tuples drops to 0 at d3 100T and d3 560T (§[8]). At canonical depth the true minimum is 5.

**Mandatoriness of {25, 27} is robust to scale.** Across all four sha-anchored partitions tested (10T to 560T), boundaries 25 and 27 appear in every greedy minimum. This is the *single most stable structural property of King Wen* the project has measured.

## Implications for the analysis paper

- §3 (Constraint system and canonical dataset) lists the four canonical SHAs as the empirical anchor.
- §5 (Analytic results): the boundary-minimum trajectory (one increment 10T→100T, then stability at 5 with an identical identifying set at 100T/560T) is a publishable empirical claim with clean cross-scale data; the single-impostor structure of the 5th boundary (the position-2/3 block swap — name the swap, not a dataset-relative `rec#`) is worth reporting in its own right.
- §7 (Discussion): stability of both the count and the set membership across a **5.6× enumeration-budget increase** (3.07× in records — the growth is sublinear) is evidence (not proof) that 5 is the asymptotic minimum for this constraint system. The discriminating test would have been a deeper canonical; **none is planned** (2026-08-01), so this remains **evidence without proof, permanently** — not a claim awaiting a scheduled test.

## Reproducibility

> ⚠ **`solutions.bin` is NOT shipped, at any scale.** It is the canonical enumeration output, and it
> is large: the **v2 100T** artifact is `3,663,580,914 × 32 + 32 = 117,234,589,280` bytes
> (`CORRECTIONS.md` §"A compression ratio assembled from a decimal numerator and a binary
> denominator"), 13,462,264,289 bytes gzipped. It is untracked here (`git ls-files` returns nothing for it;
> a working copy on a developer's disk is not a published artifact). **A reader cannot run the command
> below as written.** What a reader *can* do is read the pre-computed logs listed underneath, which do
> ship for d2 10T, d3 10T and d3 100T, or produce their own `solutions.bin` at a scale they can afford
> and run `--analyze` against that. The command is recorded so the derivation is checkable and so
> anyone reproducing at their own scale runs the same thing; it is not a recipe you can paste.

```bash
# Requires a solutions.bin you produced yourself — see the warning above.
./solve --analyze solutions.bin > analyze_output.log
# Output includes:
#   §[6] greedy minimum-boundary search → greedy minimum (Measure A; runs to 0 non-KW survivors)
#   §[7] exhaustive 3-subset test → no triple works (minimum ≥ 4 at every scale)
#   §[8] exhaustive 4-subset enumeration → count of unordered working 4-tuples (Measure B)
```

Pre-computed analyze logs:
- d2 10T, d3 10T, d3 100T: alongside the canonicals at `runs/{20260418_10T_d2_fresh, 20260418_10T_d3_fresh, 20260419_100T_d3_d128westus3}/analyze_output.log.gz`
- **d3 560T: `canonical-archive/20260608_560T_9a968fa2/analyze_v3_560T.log` — ⚠ NOT PUBLIC.** `canonical-archive/…` is operator-held cold blob storage, not a public URL ([CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Access boundary"), and `runs/20260608_560T_9a968fa2/` in this repository holds only `viz/`. **Every 560T §[6]–§[8] and §[24] figure on this page is a transcription from that operator-held log, not a citation a reader can follow** — including the survivor ladder 51,404 → 481 → 14 → 1 → 0, the `{4, 27, 25, 21, 1}` order, §[8] = 0, and the 14 dist-2 records. They were checked line-by-line against that log in a 2026-07 primary-evidence sweep recorded privately in `roae-private/PRIMARY_EVIDENCE_SWEEP_2026_07.md`: operator-attested, disclosable to an auditor, **not fetchable by a reader**. What *is* public for 560T is the canonical sha `9a968fa2…`, the reproduction recipe ([CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Reproducibility parameters"), and the `./solve --analyze` command that regenerates the log from it. The d2 10T, d3 10T and d3 100T figures on this page carry no such caveat: their `analyze_output.log.gz` files ship in `runs/` and every figure above can be read out of them. (560T analyze: 13,631 s wall on D128 with the algorithmic rewrites in commits `8ac5e8f`, `fe58e71`, `bf8d8a5`, `c0ec4c3`; selftest sha `403f7202…`.)

## Limits and scope

- Four datapoints (d2 10T, d3 10T, d3 100T, d3 560T), and there will be no fifth. The 4 → 5 → 5 trajectory observed across d3 {10T, 100T, 560T} cannot be extrapolated to 1120T+ depths without measurement, and **no such measurement is planned** — the 1120T extension campaign was considered and declined (2026-08-01). This is a standing limitation of the result, not a pending item.
- §[7] / §[8] are exhaustive at their respective subset sizes (all C(31, 3) = 4,495 and C(31, 4) = 31,465). Greedy §[6] is heuristic-ordered; at 100T/560T the greedy 5-set is exactly minimal because §[8] = 0 excludes any 4-set. At 10T the greedy 4-set is exactly minimal because §[7] = 0 excludes any 3-set.
- d4+ partitions have not been tested; partition strategy is held constant at d3 across {10T, 100T, 560T}.
- **What "depth" denotes on this page.** The 10T/100T/560T datasets are **node-budget** variants, not partition-depth variants: all three are `SOLVE_DEPTH=3` runs differing only in `SOLVE_PER_SUB_BRANCH_LIMIT` (63,146,557 → 631,456,644 → 3,536,157,207, [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Reproducibility parameters"), and the only partition-**depth** comparison the project has ever run is d2 vs d3, both at 10T. "Deeper", "canonical depth" and "tested depths" above therefore mean a larger enumeration budget. Two ratios follow and they are different numbers: the 100T → 560T **budget** ratio is **5.6×**, the **record-count** ratio is **3.07×**, and the gap between them is the sublinear growth reported in [`LEADERBOARD.md`](../enumeration/LEADERBOARD.md). A record-count ratio is never a depth.

## Working / process documentation

For the original 100T cross-partition analysis surfacing the boundary-minimum-grew-from-4-to-5 finding, see CITATIONS.md and the original 2026-04-19 analyze log archived at `runs/20260419_100T_d3_d128westus3/`. For the 560T --analyze algorithmic rewrites that made canonical-scale --analyze tractable (~24h → 3h 47m on D128), see [`HISTORY.md`](HISTORY.md) "June 10-11, 2026" entry. For the full §[1]-§[28] 560T findings, see [`SOLVE_SUMMARY.md`](SOLVE_SUMMARY.md) and (private) `roae-private/560T_FINAL_ANALYSIS.md`. The 2026-07-04 verification that surfaced this correction (defense-then-fail adversarial audit of the published headline against the canonical 560T log) is documented privately in `roae-private/BOUNDARY_CONVENTION_VERIFICATION_2026_07.md`. *(The two `roae-private` files are in a private staging repo — not publicly accessible. They are provenance for how the finding was produced and how the correction was caught; the finding itself, its corrected values, and the greedy-recount recipe are public in this document and SOLVE_SUMMARY.md.)*

---

*Revision 2026-09-02 (adjudicated correction batch — three findings, plus one sibling sweep): no count, sha, survivor ladder or greedy-minimum size moves. (1) **Cross-scale identifiers.** `rec#` literals are dataset-relative — an index into one dataset's sort order — so `rec#330177707` was wrong wherever it was qualified as holding "at every tested depth" or "at both canonical scales". The hardest-to-kill impostor is the same *ordering* at every scale (the position-2/3 block swap) and is `rec#330177707` at 560T, `rec#104178045` at 100T, `rec#21262918` at 10T; the count of dist-2 records is likewise per-dataset (10 at d3 10T, 12 at 100T, 14 at 560T), so "14" is a 560T figure and is now labelled as one. (2) **Measure B at 742M.** The historical 742M row's (B) value of 4 was computed under the pre-format-v1 `≤4`-survivor convention against a dataset holding four un-deduplicated King Wen orientation variants, not under this document's `≤ 1` definition, under which it would be 0; footnote ² now says so and the cell is marked. (3) **Budget is not depth.** "3.07×" is the 100T → 560T **record-count** ratio; the budget ratio is **5.6×** (`SOLVE_PER_SUB_BRANCH_LIMIT` 631,456,644 → 3,536,157,207). Two sentences called the record ratio a deepening / a depth increase and now name the budget. §"Limits and scope" gains a bullet defining the axis. (4) **Sourcing (sibling sweep, not charged).** The 560T `analyze_v3_560T.log` was listed beside three logs that ship in `runs/`, though `canonical-archive/` is operator-held cold blob storage and is not in this tree; §Reproducibility and the source table now mark it, and every 560T figure here is labelled a transcription. [PARTITION_STABILITY_BOUNDARIES.md](PARTITION_STABILITY_BOUNDARIES.md) received the identical fix on 2026-09-02 and this file was the un-swept sibling. Full ledger: [CORRECTIONS.md](CORRECTIONS.md).*

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*
