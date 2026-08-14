# Partition Stability of Boundaries {25, 27}

**Result:** Across four independent canonical enumerations of progressively deeper partitions of the C1 ∩ C2 ∩ C3 search space (d2 10T, d3 10T, d3 100T, d3 560T — four different sha-anchored datasets), boundaries **{25, 27} are mandatory in every greedy-ordered minimum-boundary set that uniquely identifies the King Wen ordering**. The greedy-minimum count is **monotone non-decreasing with scale** (4 → 5 → 5 across 10T → 100T → 560T; *corrected 2026-07-04 — an earlier version stated "non-monotone 4 → 5 → 4", a survivor-counting error, see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md)*); {25, 27}'s presence in every greedy minimum is the durable invariant.

This is the **most stable structural property of King Wen we have measured**. The boundary count itself, and the OTHER boundaries that round out the minimum set, both vary with partition and scale; {25, 27} do not.

## What "boundary" means here

The 31 between-pair boundaries of the King Wen sequence each have a specific Hamming distance distribution. A "boundary" in this context refers to a between-pair index k ∈ {1..31} (positions 2k-1, 2k). For each non-KW ordering in the canonical set, we can ask which boundaries it differs from KW on; the **greedy-ordered minimum identifying set** is the smallest ordered tuple of boundaries such that requiring sequential agreement reduces the canonical set to {KW}, with each boundary chosen to maximize elimination on the surviving set after prior boundaries.

A related but distinct question — the **unordered minimum identifying set** — asks for the smallest *unordered* set of boundaries whose joint conjunction reduces survivors to ≤ 1. This is the more common "K boundaries uniquely identify KW" rhetorical framing. We measure both.

## Source data

Four sha-anchored canonical enumerations:

| Partition | sha256 | Records | Source archive |
|---|---|---|---|
| d2 10T | `a09280fb8…` | 286,357,503 | `runs/20260418_10T_d2_fresh/` |
| d3 10T | `f7b8c4fbf…` ¹ | 706,422,987 | `runs/20260418_10T_d3_fresh/` |
| d3 100T | `915abf30c…` | 3,432,399,297 | `canonical-archive/t9c1/` (T9+c.1 recovery; cf. CANONICAL_HASHES.md) |
| **d3 560T** | **`9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`** | **10,525,271,997** | **`canonical-archive/20260608_560T_9a968fa2/`** |

Each was independently enumerated and merged on Azure compute; canonical SHAs reproducible across hardware/region/merge-algorithm via the partition-invariance theorem (see [`PARTITION_INVARIANCE.md`](../documentation/PARTITION_INVARIANCE.md)).

¹ The stability analyses in this document were computed on the 2026-04-18 d3 10T file (`f7b8c4fbf…`). That sha was later deprecated (pre-resume-fix undercount) in favor of `b85c8871…`/706,427,594 — see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Deprecated.

## Method

For each canonical, ran [`./solve --analyze solutions.bin`](SOLVE_C_CLI.md#--analyze):
- §[6] greedy minimum-boundary search — iteratively picks one boundary at a time, each maximizing elimination of non-KW survivors; terminates when only KW remains
- §[7] exhaustive 3-subset test — all C(31, 3) = 4,495 triples; reports the best (minimum-survivors) triple
- §[8] exhaustive 4-subset enumeration — all C(31, 4) = 31,465 quadruples; reports every joint 4-set whose conjunction reduces survivors to ≤ 1

The greedy-ordered minimum (§[6]) and the count of unordered working 4-sets (§[8]) are distinct measures.

## Result table — minimum identifying boundary sets

| Dataset | Greedy-ordered min size | Greedy set | Unordered 4-subsets at survivors ≤ 1 (§[8]) | {25, 27} in greedy min? |
|---|---:|---|---:|:---:|
| d2 10T (286M) | **4** | `{25, 27} ∪ one-of-{2,3} ∪ one-of-{21,22}` | 4 | ✓ |
| d3 10T (706M) | **4** | `{25, 27} ∪ two-of-{1..6}` | 8 | ✓ |
| d3 100T (3.43B) | **5** | `{1, 4, 21, 25, 27}` | 0 | ✓ |
| **d3 560T (10.5B)** | **5** | **`{4, 27, 25, 21, 1}`** (in that order; cumulative non-KW survivors 51,404 → 481 → 14 → 1 → 0) | **0** | **✓** |

The **greedy-ordered minimum is monotone non-decreasing with scale** (4 → 5 → 5 across d3 10T → 100T → 560T; the 560T row was corrected 2026-07-04 from "4 / {4, 27, 25, 21}" — a survivor-counting error, see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md)). The **working-4-set count** collapses with scale (8 → 0 across d3 10T → 100T, then stays at 0 at 560T, with the prior 742M-era figure of 4 being a smaller-budget intermediate). §[7] at 560T proves no 3-tuple of boundaries works (best `{4, 25, 27}` leaves 15 survivors), and §[8] = 0 proves no 4-set works, so 5 is the exact minimum at the deepest published scale.

## What this implies

**{25, 27} as a stable structural anchor.** No matter the partition depth (10T to 560T tested) and no matter the scale (286M to 10.5B records), boundaries 25 and 27 appear in every greedy-ordered minimum-boundary set. They are the **single most stable structural finding** the project has measured.

**The boundary-minimum size is monotone non-decreasing with scale, and stable at canonical depth.** One increment (4 → 5 across 10T → 100T), then stability: the 560T greedy minimum is 5 with the *identical set in the identical greedy order* as 100T. The 100T-era prediction that the minimum would "continue to grow toward 6 at 1000T+" is neither confirmed nor refuted, and **now cannot be**: the 1120T extension that would have supplied the next datapoint is **not planned** (2026-08-01). This is a permanent limitation, not a pending measurement. *(Corrected 2026-07-04: this paragraph previously reported a "drop back to 4" at 560T and hypothesized a mechanism for it; both rested on a survivor-counting error, see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md).)*

**4-set identification is scale-bounded.** The popular phrasing "exactly 4 specific boundaries uniquely identify KW" was true at 10T scales (when 4 or 8 working 4-tuples existed) but fails at 100T and 560T (where 0 4-tuples reduce survivors to ≤ 1). At canonical depth the minimum identifying set has 5 boundaries.

**Partition-stability claims must be scoped.** A finding "X holds at d2 10T" does not imply "X holds at deeper enumeration." Future ROAE results should always specify the partition depth + scale + sha of the underlying canonical at which a claim was verified.

## Implications for the analysis paper

- **§3 (Constraint system and canonical dataset)** can list the four canonical SHAs and their record counts as the empirical anchor.
- **§4 (Null-model framework results) / §5 (Analytic results)**: the {25, 27} stability across four scales is robust, paper-citable.
- **§7 (Discussion)**: the boundary-minimum trajectory (monotone 4 → 5, then stable at canonical depth with an identical identifying set) warrants a dedicated paragraph, while preserving the {25, 27} mandatoriness as the genuine structural invariant. See [`BOUNDARY_MINIMUM.md`](BOUNDARY_MINIMUM.md) for the detailed cross-scale comparison.

## Reproducibility

```bash
./solve --analyze solutions.bin > analyze_output.log    # reads canonical bin
# Output includes minimum-boundary report (§[6], §[7], §[8]) at the bottom
```

Pre-computed analyze logs:
- d2 10T, d3 10T, d3 100T: alongside the canonicals in `runs/{20260418_10T_d2_fresh, 20260418_10T_d3_fresh, 20260419_100T_d3_d128westus3}/analyze_output.log.gz` (the 100T run archive is the original; T9+c.1 recovery analyze log was not preserved separately)
- **d3 560T: `canonical-archive/20260608_560T_9a968fa2/analyze_v3_560T.log`** (13,631 s wall on D128 with the algorithmic rewrites in `solve.c` commits 8ac5e8f, fe58e71, bf8d8a5, c0ec4c3; selftest sha `403f7202…`)

## Limits and scope

- Four datapoints (d2 10T, d3 10T, d3 100T, d3 560T). The 4 → 5 → 5 trajectory observed across d3 {10T, 100T, 560T} cannot be extrapolated to 1120T+ depths without measurement, and **no such measurement is planned** — the 1120T extension campaign was considered and declined (2026-08-01). There will be no fifth datapoint.
- The §[7] / §[8] passes are exhaustive at the relevant subset sizes (all C(31, 3) and C(31, 4)). The greedy §[6] is heuristic-ordered; however where §[8] = 0 (100T, 560T) the greedy 5-set is exactly minimal (no 4-set can work), and at 10T where §[7] = 0 the greedy 4-set is exactly minimal (no 3-set can work).
- d4+ partitions have not been tested; partition-strategy is held constant at d3 for the 100T/560T datapoints.

## Working / process documentation

For the original 2026-04-19 cross-partition analysis (d2 10T + d3 10T + d3 100T), see the `petersm3/roae-private` staging repo's `D2_D3_ANALYZE_FINDINGS.md` (now `petersm3/roae-private` per the 2026-05-29 rename). For the 560T `--analyze` algorithmic rewrites that made canonical-scale analyze tractable, see `documentation/HISTORY.md` "June 10-11, 2026" entry; for the full §[1]-§[28] 560T findings, see `documentation/PROJECT_OVERVIEW.md` §"560T canonical results" and (private) `roae-private/560T_FINAL_ANALYSIS.md`.

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*
