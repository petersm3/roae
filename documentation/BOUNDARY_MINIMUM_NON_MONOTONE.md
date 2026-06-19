# Boundary Minimum Size is Non-Monotone with Enumeration Scale

**Result:** The number of boundary constraints required to uniquely identify King Wen among C1 ∩ C2 ∩ C3 canonical orderings is **non-monotone with enumeration depth**. Greedy-ordered minimum size measured at the d3 partition: **4 at 10T → 5 at 100T → 4 at 560T**. The number of *unordered* working 4-subsets (joint identification by any 4 boundaries) is also non-monotone: **8 at 11.2T → 4 at 742M (pre-bugfix subset) → 0 at 100T and 560T**.

This is a precisely-quantified empirical refutation of the assumption that the boundary-minimum size grows monotonically with deeper enumeration. The 100T-era prediction that the minimum would "continue to grow toward 6 at 1000T+" was falsified by the 560T result. The durable structural claim is **"4 boundaries suffice via greedy-ordered application,"** with boundaries 25 and 27 mandatory in every greedy minimum at every scale tested (see [`PARTITION_STABILITY_BOUNDARIES.md`](PARTITION_STABILITY_BOUNDARIES.md)).

## What is being measured

Two distinct minima of the boundary identification problem are measured:

**(A) Greedy-ordered minimum size (§[6] in `solve --analyze`).** The smallest *ordered* tuple of boundaries `(b_1, b_2, ..., b_k)` such that sequential application reduces survivors to {KW}, where boundary `b_i` is chosen at each step to maximize elimination on the current surviving set. The algorithm is deterministic given the canonical solution set.

**(B) Unordered minimum-set count (§[8] in `solve --analyze`).** The number of *unordered* subsets of size 4 such that the conjunction of "matches KW on every boundary in this set" reduces survivors to ≤ 1. This is the count of "exactly-4-boundary unique identifications" that the popular framing assumes exists.

Measures (A) and (B) coincide when the unordered minimum equals 4 (e.g., at d2/d3 10T). They diverge at deeper scales: (A) can be smaller than (B) because the greedy *order* of elimination matters even if no unordered tuple works.

## Source data

Four sha-anchored canonical enumerations:

| Partition | sha256 | Records | Source archive |
|---|---|---|---|
| d2 10T | `a09280fbf…` | 286,357,503 | `runs/20260418_10T_d2_fresh/` |
| d3 10T | `f7b8c4fbf…` | 706,422,987 | `runs/20260418_10T_d3_fresh/` |
| d3 100T | `915abf30c…` | 3,432,399,298 | `canonical-archive/t9c1/` (T9+c.1 recovery) |
| **d3 560T** | **`9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`** | **10,525,271,997** | **`roaecanonical2026/canonical-archive/20260608_560T_9a968fa2/`** |

The 742M figure cited below is the pre-format-v1 (pre-2026-04-19) hash-table-bug dataset; it is historical-only and is not sha-anchored as a valid canonical. It is included in the unordered-count trajectory for completeness because it was the dataset under which the original "exactly 4 specific boundaries" finding was first reported.

## Result table

| Dataset | Greedy-ordered min size (A) | Greedy set | Unordered working 4-sets (B) | {25, 27} in greedy min? |
|---|---:|---|---:|:---:|
| d2 10T (286M) | **4** | `{25, 27} ∪ one-of-{2,3} ∪ one-of-{21,22}` | 4 | ✓ |
| d3 10T (706M) | **4** | `{25, 27} ∪ two-of-{1..6}` | 8 | ✓ |
| 742M (historical) | — | — | 4 | — |
| d3 100T (3.43B) | **5** | `{1, 4, 21, 25, 27}` | 0 | ✓ |
| **d3 560T (10.5B)** | **4** | **`{4, 27, 25, 21}`** (cumulative survivors 51,404 → 481 → 14 → 1) | **0** | **✓** |

§[7] at d3 560T proves no 3-tuple of boundaries works (best `{4, 25, 27}` leaves 15 survivors), so **4 is a tight greedy-minimum at the deepest published scale**.

The cumulative-survivor curve for d3 560T's greedy set is striking: boundary 4 ALONE eliminates 99.999% of non-KW records (51,404 survive out of 10,525,271,996). Boundaries 25, 27, 21 then sequentially narrow the survivors by ~100× per step.

## What this implies

**The boundary-minimum trajectory is non-monotone.** A common assumption — that deeper enumeration surfaces ever-more KW look-alikes, requiring an ever-larger minimum identifying set — is falsified at d3 560T. The 5-set required at d3 100T was *not* a permanent escalation from the 4-set required at smaller scales; at d3 560T the minimum drops back to 4.

**Mechanism (hypothesis).** The d3 100T budget surfaced a class of survivors that overlap on boundaries {1, 4, 21, 25, 27} but not on alternative high-info boundaries. At d3 560T, additional records are surfaced that — once the eliminator sequence is re-greedy-chosen — admit a 4-set ordering (`{4, 27, 25, 21}`) whose cumulative cascade reaches {KW} again. Per §[18], boundary 4 alone yields 45.14 bits of conditional-entropy information gain (over half the 77.81-bit total baseline); the depth at which boundary 4 starts to dominate the early-greedy choice is scale-dependent. This is a *hypothesis*, not yet falsified, and is testable at 1120T (where the same phenomenon should either persist or reveal an additional regime shift).

**The popular "4 specific boundaries uniquely identify King Wen" framing is scale-bounded.** The number of *unordered* working 4-tuples drops to 0 at d3 100T and d3 560T. There is no "exactly 4 specific boundaries" that jointly pin KW down without ordering at canonical depth. The durable form is the ordered version — see [`PARTITION_STABILITY_BOUNDARIES.md`](PARTITION_STABILITY_BOUNDARIES.md).

**Mandatoriness of {25, 27} is robust to scale.** Across all four sha-anchored partitions tested (10T to 560T), boundaries 25 and 27 appear in every greedy minimum. This is the *single most stable structural property of King Wen* the project has measured.

## Implications for the analysis paper

- §3 (Constraint system and canonical dataset) lists the four canonical SHAs as the empirical anchor.
- §5 (Analytic results): boundary-minimum non-monotonicity is a publishable empirical claim with clean cross-scale data; the unordered → 0 collapse and the greedy-min recovery to 4 are both worth reporting.
- §7 (Discussion): the trajectory argues against extrapolating any specific minimum-size figure to scales beyond what's been measured. The empirical content of the constraint system's KW-identifying power is the *ordered* result, not the *unordered* one.

## Reproducibility

```bash
./solve --analyze solutions.bin > analyze_output.log
# Output includes:
#   §[6] greedy minimum-boundary search → ordered minimum (Measure A)
#   §[7] exhaustive 3-subset test → tightness of the minimum at 3 vs 4
#   §[8] exhaustive 4-subset enumeration → count of unordered working 4-tuples (Measure B)
```

Pre-computed analyze logs:
- d2 10T, d3 10T, d3 100T: alongside the canonicals at `runs/{20260418_10T_d2_fresh, 20260418_10T_d3_fresh, 20260419_100T_d3_d128westus3}/analyze_output.log.gz`
- **d3 560T: `roaecanonical2026/canonical-archive/20260608_560T_9a968fa2/analyze_v3_560T.log`** (13,631 s wall on D128 with the algorithmic rewrites in commits `8ac5e8f`, `fe58e71`, `bf8d8a5`, `c0ec4c3`; selftest sha `403f7202…`)

## Limits and scope

- Four datapoints (d2 10T, d3 10T, d3 100T, d3 560T). The non-monotone trajectory observed across d3 {10T, 100T, 560T} cannot be extrapolated to 1120T+ depths without measurement; the 1120T extension campaign (queued) will provide a fifth datapoint.
- §[7] / §[8] are exhaustive at their respective subset sizes (all C(31, 3) = 4,495 and C(31, 4) = 31,465). Greedy §[6] is heuristic-ordered; however when §[7] = 0 (true at every dataset tested), the greedy minimum equals the tight minimum because no smaller subset works.
- d4+ partitions have not been tested; partition strategy is held constant at d3 across {10T, 100T, 560T}.

## Working / process documentation

For the original 100T cross-partition analysis surfacing the boundary-minimum-grew-from-4-to-5 finding, see CITATIONS.md and the original 2026-04-19 analyze log archived at `runs/20260419_100T_d3_d128westus3/`. For the 560T --analyze algorithmic rewrites that made canonical-scale --analyze tractable (~24h → 3h 47m on D128), see [`HISTORY.md`](HISTORY.md) "June 10-11, 2026" entry. For the full §[1]-§[28] 560T findings, see [`SOLVE-SUMMARY.md`](SOLVE-SUMMARY.md) §"560T canonical results" and (private) `roae-private/560T_FINAL_ANALYSIS.md`.
