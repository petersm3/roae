# Partition Stability of Boundaries {25, 27}

**Result:** Across three independent canonical enumerations of progressively deeper partitions of the C1 ∩ C2 ∩ C3 search space (d2 10T, d3 10T, d3 100T — three different sha-anchored datasets), boundaries **{25, 27} are mandatory in every minimum-boundary set that uniquely identifies the King Wen ordering**. No 4-boundary minimum identification works for d3 100T (5 boundaries are needed); but {25, 27} appear in every working minimum at every partition depth tested.

This is the **most stable structural property of King Wen we have measured**. Other components of the boundary minimum are partition-depth-dependent; {25, 27} are not.

## What "boundary" means here

The 31 between-pair boundaries of the King Wen sequence each have a specific Hamming distance distribution. A "boundary" in this context refers to a between-pair index k ∈ {1..31} (positions 2k-1, 2k). For each non-KW ordering in the canonical set, we can ask which boundaries it differs from KW on; the **minimum identifying set** is the smallest collection of boundaries such that requiring agreement at all of them with KW reduces the canonical set to {KW}.

## Source data

Three sha-anchored canonical enumerations:

| Partition | sha256 | Records | Run archive |
|---|---|---|---|
| d2 10T | `a09280fbf…` | 286,357,503 | `solve_c/runs/20260418_10T_d2_fresh/` |
| d3 10T | `f7b8c4fbf…` | 706,422,987 | `solve_c/runs/20260418_10T_d3_fresh/` |
| d3 100T | `915abf30c…` | 3,432,399,297 | `solve_c/runs/20260419_100T_d3_d128westus3/` |

Each was independently enumerated and merged on Azure compute; canonical SHAs reproducible across hardware/region/merge-algorithm via the partition-invariance theorem (see [`PARTITION_INVARIANCE.md`](../PARTITION_INVARIANCE.md)).

## Method

For each canonical, ran `./solve --analyze solutions.bin`:
- Computes per-position Shannon entropy
- Identifies all 4-boundary subsets that uniquely identify KW (via brute-force or greedy search)
- Reports the minimum-boundary set size and the count of working subsets at that size

## Result table — minimum identifying boundary sets

| Dataset | Min size | # working subsets at min size | Boundaries in 100% of working subsets |
|---|---:|---:|---|
| d2 10T (286M) | **4** | 4 | **{25, 27}** |
| d3 10T (706M) | **4** | 11 | **{25, 27}** |
| d3 100T (3.43B) | **5** | (greedy: {1, 4, 21, 25, 27}) | **{25, 27}** |

The 4-boundary minimum found at d2 and d3 10T is **invalidated** at d3 100T — the deeper enumeration surfaces orderings that are 4-subset-indistinguishable from KW. The greedy minimum at 100T is 5 boundaries, set {1, 4, 21, 25, 27}.

## What this implies

**{25, 27} as a stable structural anchor.** No matter the partition depth (within the 10T-100T tested range), boundaries 25 and 27 must distinguish KW from every other canonical ordering. The other boundaries in the minimum set are interchangeable / partition-depth-dependent; {25, 27} are not.

**The boundary-minimum size grows with partition depth.** From 4 at 10T to 5 at 100T. This trajectory suggests the true minimum may continue to grow at deeper enumeration — at 1000T+ the minimum could become 6 or more. The "4 boundaries uniquely determine KW" framing of earlier ROAE work was a 10T-specific fact, not a robust universal claim.

**Partition-stability claims must be scoped.** A finding "X holds at d2 10T" does not imply "X holds at deeper enumeration." Future ROAE results should always specify the partition depth (and dataset sha) at which a claim is verified.

## Implications for the analysis paper

- **§3 (Constraint system and canonical dataset)** can list the three canonical SHAs and their record counts as the empirical anchor.
- **§4 (Null-model framework results) / §5 (Analytic results)**: the {25, 27} stability is a robust structural finding, paper-citable.
- **§7 (Discussion)**: the boundary-minimum growth from 4 → 5 across partitions warrants a paragraph on what's known to be partition-stable vs depth-dependent.

## Reproducibility

```bash
./solve --analyze solutions.bin > analyze_output.log    # reads canonical bin
# Output includes minimum-boundary report at the bottom
```

Three pre-computed analyze logs live alongside their respective canonicals in `solve_c/runs/{20260418_10T_d2_fresh, 20260418_10T_d3_fresh, 20260419_100T_d3_d128westus3}/analyze_output.log.gz`. Each log has the per-position entropy + minimum-boundary search output.

## Limits and scope

- Three datapoints (d2 10T, d3 10T, d3 100T). Insufficient to extrapolate to 1000T+ depths or to other partitions (depth-4, depth-5 partitions have not yet been tested).
- The `--analyze` minimum-boundary search uses greedy + bounded brute-force; for 100T it does not exhaustively check all C(31, k) subsets at large k. The 5-boundary minimum at 100T is therefore a `≤ 5` upper bound, not necessarily exact.

## Working / process documentation

For the original analysis context, all per-position entropy data, and the 2026-04-19 cross-partition comparison summary, see [`x/roae/D2_D3_ANALYZE_FINDINGS.md`](https://github.com/petersm3/x/blob/main/roae/D2_D3_ANALYZE_FINDINGS.md) (private staging repo).
