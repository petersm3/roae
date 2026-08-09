# Boundary Minimum Size: Monotone 4 → 5, Stable at Canonical Depth

*(revised 2026-07-04; supersedes the "non-monotone 4→5→4" version of 2026-06-11, formerly `BOUNDARY_MINIMUM_NON_MONOTONE.md`)*

**Revision note (2026-07-04).** The 2026-06-11 version of this document reported the greedy boundary minimum as "4 at 10T → 5 at 100T → 4 at 560T (non-monotone)". That was a survivor-counting error, not a property of the data: the "4 at 560T" counted greedy steps until **≤ 1 non-KW survivor** remained, while the "5 at 100T" counted steps until **0** remained — and this document's own definition requires reduction to {KW} (zero non-KW). The canonical 560T analyze log (§[6]) in fact runs five steps, `{4, 27, 25, 21}` leaving one non-KW survivor and boundary 1 eliminating it: `Boundaries chosen: { 1 4 21 25 27 }` — identical to 100T. The previously-published "ordered vs unordered minimum" distinction also dissolves: boundary conjunction is a commutative intersection, so no ordering of 4 boundaries can succeed where the unordered 4-set fails (§[8] = 0 at 100T/560T already implied the minimum exceeds 4). We are correcting rather than silently revising; the prior text remains in git history.

**Result:** The number of boundary constraints required to uniquely identify King Wen among C1 ∩ C2 ∩ C3 canonical orderings is **4 at d3 10T and 5 at both d3 100T and d3 560T** — monotone non-decreasing in enumeration depth, with the set `{1, 4, 21, 25, 27}` (identical membership and greedy order) at both canonical scales. No 3-subset works at any scale (§[7]), and no 4-subset works at ≥100T (§[8] = 0), so 5 is exact at 100T/560T.

**The single hardest-to-kill King Wen impostor is the same nameable record at every tested depth:** rec#330177707, King Wen with the pair blocks at positions 2 and 3 interchanged (hexagrams 3/4 ↔ 5/6, Zhun/Meng ↔ Xu/Song). It survives {4, 21, 25, 27} because it matches KW at every pinned position; only a front-zone boundary (1, 2, or 3) eliminates it. The 5th boundary in the identifying set exists solely for this one twin (§[6] count = 1 + §[24] membership check).

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
| d3 100T | `915abf30c…` | 3,432,399,297 | `canonical-archive/t9c1/` (T9+c.1 recovery) |
| **d3 560T** | **`9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`** | **10,525,271,997** | **`roaecanonical2026/canonical-archive/20260608_560T_9a968fa2/`** |

¹ The boundary analyses in this document were computed on the 2026-04-18 d3 10T file (`f7b8c4fbf…`). That sha was later deprecated (pre-resume-fix undercount) in favor of `b85c8871…`/706,427,594 — see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Deprecated; the delta is 4,607 records and does not affect the boundary findings' scope labels.

The 742M figure cited below is the pre-format-v1 (pre-2026-04-19) hash-table-bug dataset; it is historical-only and is not sha-anchored as a valid canonical. It is included in the unordered-count trajectory for completeness because it was the dataset under which the original "exactly 4 specific boundaries" finding was first reported.

## Result table

| Dataset | Greedy-ordered min size (A) | Greedy set | Unordered working 4-sets (B) | {25, 27} in greedy min? |
|---|---:|---|---:|:---:|
| d2 10T (286M) | **4** | `{25, 27} ∪ one-of-{2,3} ∪ one-of-{21,22}` | 4 | ✓ |
| d3 10T (706M) | **4** | `{25, 27} ∪ two-of-{1..6}` | 8 | ✓ |
| 742M (historical) | — | — | 4 | — |
| d3 100T (3.43B) | **5** | `{1, 4, 21, 25, 27}` | 0 | ✓ |
| **d3 560T (10.5B)** | **5** | **`{4, 27, 25, 21, 1}`** (cumulative non-KW survivors 51,404 → 481 → 14 → 1 → 0) | **0** | **✓** |

§[7] at d3 560T proves no 3-tuple of boundaries works (best `{4, 25, 27}` leaves 15 survivors, KW-inclusive), and §[8] = 0 proves no 4-set works, so **5 is the exact minimum at both canonical scales (100T, 560T)**.

The cumulative-survivor curve for d3 560T's greedy set is striking: boundary 4 ALONE eliminates 99.999% of non-KW records (51,404 survive out of 10,525,271,996). Boundaries 27, 25, 21 then sequentially narrow the survivors by ~107×, ~34× and ~14× (51,404 → 481 → 14 → 1), and boundary 1 eliminates the single remaining impostor (rec#330177707).

## What this implies

**The boundary-minimum trajectory is monotone non-decreasing across tested depths: 4 (10T) → 5 (100T) → 5 (560T).** Deeper enumeration surfaced KW look-alikes that pushed the minimum from 4 to 5 between 10T and 100T; a further 3.07× deepening (100T → 560T) surfaced no look-alike requiring a 6th boundary. The identifying set is not merely the same *size* at both canonical scales — it is the *same set in the same greedy order*, `{4, 27, 25, 21, 1}` (§[6] prints the chosen set as `{ 1 4 21 25 27 }`).

**The 5th boundary exists for exactly one record.** After `{4, 27, 25, 21}`, the sole surviving non-KW record at both canonical scales is rec#330177707 — KW with the pair blocks at positions 2 and 3 interchanged. It matches KW at every position the 4-set pins; only a front-zone boundary (1, 2, or 3) distinguishes it, and greedy picks boundary 1. This is verifiable from the 560T log alone: §[24]'s edit-distance-2 catalog shows exactly one of the 14 dist-2 records avoids all pinned positions, and §[6]'s step-4 survivor count is exactly 1.

**The popular "4 specific boundaries uniquely identify King Wen" framing is scale-bounded.** The number of working 4-tuples drops to 0 at d3 100T and d3 560T (§[8]). At canonical depth the true minimum is 5.

**Mandatoriness of {25, 27} is robust to scale.** Across all four sha-anchored partitions tested (10T to 560T), boundaries 25 and 27 appear in every greedy minimum. This is the *single most stable structural property of King Wen* the project has measured.

## Implications for the analysis paper

- §3 (Constraint system and canonical dataset) lists the four canonical SHAs as the empirical anchor.
- §5 (Analytic results): the boundary-minimum trajectory (one increment 10T→100T, then stability at 5 with an identical identifying set at 100T/560T) is a publishable empirical claim with clean cross-scale data; the single-impostor structure of the 5th boundary (rec#330177707) is worth reporting in its own right.
- §7 (Discussion): stability of both the count and the set membership across a 3.07× depth increase is evidence (not proof) that 5 is the asymptotic minimum for this constraint system. The discriminating test would have been a deeper canonical; **none is planned** (2026-08-01), so this remains **evidence without proof, permanently** — not a claim awaiting a scheduled test.

## Reproducibility

```bash
./solve --analyze solutions.bin > analyze_output.log
# Output includes:
#   §[6] greedy minimum-boundary search → greedy minimum (Measure A; runs to 0 non-KW survivors)
#   §[7] exhaustive 3-subset test → no triple works (minimum ≥ 4 at every scale)
#   §[8] exhaustive 4-subset enumeration → count of unordered working 4-tuples (Measure B)
```

Pre-computed analyze logs:
- d2 10T, d3 10T, d3 100T: alongside the canonicals at `runs/{20260418_10T_d2_fresh, 20260418_10T_d3_fresh, 20260419_100T_d3_d128westus3}/analyze_output.log.gz`
- **d3 560T: `roaecanonical2026/canonical-archive/20260608_560T_9a968fa2/analyze_v3_560T.log`** (13,631 s wall on D128 with the algorithmic rewrites in commits `8ac5e8f`, `fe58e71`, `bf8d8a5`, `c0ec4c3`; selftest sha `403f7202…`)

## Limits and scope

- Four datapoints (d2 10T, d3 10T, d3 100T, d3 560T), and there will be no fifth. The 4 → 5 → 5 trajectory observed across d3 {10T, 100T, 560T} cannot be extrapolated to 1120T+ depths without measurement, and **no such measurement is planned** — the 1120T extension campaign was considered and declined (2026-08-01). This is a standing limitation of the result, not a pending item.
- §[7] / §[8] are exhaustive at their respective subset sizes (all C(31, 3) = 4,495 and C(31, 4) = 31,465). Greedy §[6] is heuristic-ordered; at 100T/560T the greedy 5-set is exactly minimal because §[8] = 0 excludes any 4-set. At 10T the greedy 4-set is exactly minimal because §[7] = 0 excludes any 3-set.
- d4+ partitions have not been tested; partition strategy is held constant at d3 across {10T, 100T, 560T}.

## Working / process documentation

For the original 100T cross-partition analysis surfacing the boundary-minimum-grew-from-4-to-5 finding, see CITATIONS.md and the original 2026-04-19 analyze log archived at `runs/20260419_100T_d3_d128westus3/`. For the 560T --analyze algorithmic rewrites that made canonical-scale --analyze tractable (~24h → 3h 47m on D128), see [`HISTORY.md`](HISTORY.md) "June 10-11, 2026" entry. For the full §[1]-§[28] 560T findings, see [`SOLVE_SUMMARY.md`](SOLVE_SUMMARY.md) and (private) `roae-private/560T_FINAL_ANALYSIS.md`. The 2026-07-04 verification that surfaced this correction (defense-then-fail adversarial audit of the published headline against the canonical 560T log) is documented privately in `roae-private/BOUNDARY_CONVENTION_VERIFICATION_2026_07.md`.

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*
