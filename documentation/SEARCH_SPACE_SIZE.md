# Search-Space Size: How Many C1–C5 Orderings Exist

**Result:** The total number of hexagram orderings satisfying constraints C1–C5 is **estimated at ≈1.3×10³⁸** (raw), or **≈3×10³⁷ distinct canonical orderings** after orientation-deduplication — the quantity the published enumerations count. This is a **statistical estimate** from an unbiased Monte-Carlo tree-size estimator (Knuth 1975), validated to **<1%** against exact subtree counts; it is **not a proven cardinality** and is **not a canonical result**. Its purpose is to put a hard number on a question the exhaustive enumerations could only bound from below: *the deepest published canonical (d3 560T, 1.05×10¹⁰ distinct orderings) has enumerated ≈1 part in 10²⁷ of the space, and exhaustion is infeasible at any conceivable budget.*

This closes the long-standing "the total count of C1–C5 orderings is not yet known" caveat carried in [`enumeration/LEADERBOARD.md`](../enumeration/LEADERBOARD.md), [`CANONICAL_HASHES.md`](CANONICAL_HASHES.md), and [`SOLVE-SUMMARY.md`](SOLVE-SUMMARY.md) — replacing "not yet known" with "known to ≈1% as an estimate, still astronomically unexhaustible."

## What is being measured

The exhaustive enumerations (`solve.c`) are **budgeted**: each of the 158,364 depth-3 cells receives a fixed node budget, and the reported record count is the number of distinct canonical orderings *found within that budget*. Because no cell is ever exhausted (see [`CRITIQUE.md`](CRITIQUE.md) §"per-branch yield labels" — a single sub-branch budgeted to "yield 16" held ≥664 million orderings on a deeper walk), the canonical counts are **lower bounds**, not the size of the solution space. The three-point scaling trajectory (11.2T → 100T → 560T, α ≈ 0.78, see [`SOLVE-SUMMARY.md`](SOLVE-SUMMARY.md)) shows the counts still growing sublinearly with budget, with no visible asymptote.

This document measures the **total un-budgeted size** of the C1–C5 backtracking tree directly, without enumerating it — the number the budgeted counts are converging toward.

## Method — Knuth's random-probe estimator

Knuth (1975, *Estimating the efficiency of backtrack programs*, Math. Comp. 29). One **probe** is a single random root→dead-end walk of the exact `solve.c` search tree:

- Start at the root with weight `W = 1`.
- At a node with `d` live children (children passing the same C1/C2/C4/C5 prune predicates used by the real `backtrack()`), set `W ← W · d` and descend to one of the `d` children chosen uniformly at random.
- Stop at a dead end or at a completed depth-32 leaf.

Then `E[Σ W over the visited path]` equals the total number of tree nodes, and `E[W at a reached depth-32 leaf]` equals the number of complete orderings; applying the C3 test at the leaf gives the **canonical (C1–C5)** count. Each probe is an *unbiased* estimator of the whole; averaging `N` independent probes reduces variance as `1/√N`. The estimator is pure compute — **it touches no solution data and needs no enumeration artifacts** — and it reuses `solve.c`'s exact prune predicates, so it samples the identical tree the enumerator walks.

Implementation: `solve --estimate-knuth <probes> [prefix…]` (see [`SOLVE_CLI.md`](SOLVE_CLI.md)). Sha-neutral to the enumerator: the subcommand shares the prune predicates but adds no code on the enumeration path (`--selftest` unchanged).

## Validation — the estimator is correct

`solve --estimate-knuth 0 <prefix>` performs an **exact** deterministic subtree count. Comparing the Monte-Carlo estimate against exact ground truth on a King-Wen-following prefix, at increasing subtree depth:

| free positions | exact nodes | Knuth nodes | exact canonical | Knuth canonical |
|---:|---:|---:|---:|---:|
| 5 | 443 | 442.9 | 4 | 4.01 |
| 7 | 62,256 | 62,257 | 2,232 | 2,233 |
| 9 | 9,422,793 | 9,424,649 | 16,504 | 16,422 |

Agreement is **<1% at every depth**. Independent cross-check: the 56 per-branch estimates (below) **sum to 1.33×10³⁸**, matching the independently-estimated whole-tree value **1.32×10³⁸** to <1%.

## Result — the whole C1–C5 tree

5×10⁸ probes (a 100×-probe refinement is in progress and is expected to tighten the interval, not move the central value):

| quantity | estimate | 95% CI | rel. error |
|---|---|---|---:|
| **canonical (C1–C5) orderings (raw)** | **1.32×10³⁸** | [1.319, 1.328]×10³⁸ | 0.18% |
| — distinct canonical (after ~4× orientation-dedup) | **≈3×10³⁷** | — | — |
| complete orderings satisfying C1/C2/C4/C5 | 1.10×10³⁹ | — | 0.06% |
| total backtracking-tree nodes | 2.09×10⁴⁰ | — | 0.01% |

For scale: the unconstrained permutation space is 64! ≈ 1.3×10⁸⁹ (with the pairing/orientation structure, the C1 skeleton starts from ≈10⁴¹ arrangements). C1–C5 cut this to ≈10³⁸ — an enormous reduction, yet still astronomically beyond enumeration.

## Result — per first-level branch

The 56 real first-level (position-1 pair, orientation) branches, 10⁸ probes each:

- canonical orderings per branch: **min 1.26×10³⁶, median 2.26×10³⁶, max 3.46×10³⁶ — a spread of only ≈2.7×**.
- **Roughly uniform: there is no small or near-exhaustible branch.** This answers the practical question behind single-branch deep-enumeration ("which branch is cheapest to exhaust, and does its structure extrapolate?"): every branch is comparably enormous (~2×10³⁶), so no single-branch walk can exhaust anything, and extrapolation from one branch to the whole is well-founded. Compare [`PARTITION_INVARIANCE.md`](PARTITION_INVARIANCE.md), which partitions the same tree into these 56 branches for the reproducibility argument.

## Result — budgeted yield is uncorrelated with cell size

A 605-cell sample cross-plotting each cell's **budgeted yield** (distinct orderings found within the 560T per-cell budget, from the campaign shard manifest) against its **total un-budgeted size** (Knuth estimate):

| quantity | spread across cells |
|---|---|
| budgeted yield (records at the 560T per-cell budget) | 10^2.6 – 10^6.8 (≈4 orders, heavy-tailed) |
| total un-budgeted tree size | 10^31.9 – 10^33.7 (≈2 orders, relatively uniform) |
| **log-log correlation** | **Pearson r = 0.15, Spearman ρ = 0.14 → essentially uncorrelated** |

**A cell's budgeted yield is nearly independent of its total tree size.** The cells are all comparably enormous, but how many orderings each surfaces *within a fixed budget* varies by four orders of magnitude and does not track total size. Yield is therefore a **local-density** phenomenon — how record-rich the shallow frontier is — not a size phenomenon. (A full 65,281-cell version of this distribution is in progress and will replace the sample.)

## Why is King Wen found "early" if the space is ≈10³⁸?

A natural objection: if there are ≈10³⁸ valid orderings and King Wen is just one of them, shouldn't reaching it take astronomically long — not surface it in the first few billion nodes? Three points resolve this:

1. **The enumeration is systematic, not random.** It is an exhaustive depth-first traversal in a fixed order, not uniform random sampling. The time to reach a *specific, known* ordering depends on **where that ordering sits in the traversal order**, not on the size of the solution set. King Wen's prefix (its first few pairs) is visited early in the ordered DFS, so its leaf is reached early; reverse the ordering and the same solution would appear near the "end." Drawing orderings *uniformly at random* would indeed require ≈10³⁸ draws to hit King Wen specifically — but that is not what the enumeration does.

2. **King Wen is a known input, not a needle being hunted.** We already have King Wen's exact sequence; verifying it satisfies C1–C5 takes microseconds and needs no enumeration at all. The enumeration's purpose is not to *find* King Wen but to enumerate its **neighbours** — the rest of the valid space — so King Wen's properties (complement-distance percentile, mandatory boundaries, position-1 forcing) can be measured *relative to* everything else that is valid.

3. **The budget is per-cell, and King Wen lives in one cell.** The enumeration splits into 158,364 depth-3 cells, each with its own node budget; King Wen belongs to exactly one cell and is reached within that cell's shallow budgeted region. We never traverse 10²⁷ other solutions before it — the ≈10³⁸ total is spread across all cells and, overwhelmingly, across the **depth beyond every cell's budget**. King Wen is a shallow, early-reachable leaf, not a deep or rare one.

### Is finding King Wen early then an artifact of our setup? (Yes — and it doesn't matter.)

It is worth being fully explicit: **King Wen's early appearance is a property of how we set the search up, not a property of King Wen.** Three setup choices produce it, and a different choice on any of them could make a finite-budget search reach King Wen far more slowly — or leave its particular leaf out of the budgeted slice entirely:

- **The constraints** set the ambient *density* of solutions (they shrink ~10⁸⁹ → ~10³⁸, so the constrained tree is nearly all-solutions and any traversal trips over them immediately). Because C1–C5 were reverse-engineered *from* King Wen, King Wen is a member of the solution set by construction and can never be pruned — but that guarantees *membership*, not *early arrival*.
- **The decomposition** (158,364 per-cell budgets) guarantees *breadth*: every cell, King Wen's included, is serviced regardless of branch order. A single global-budget DFS could instead spend its whole budget deep in another region and never reach King Wen's prefix.
- **The variable/value ordering** decides where King Wen's one leaf falls relative to its cell's ~3.5 B-node budgeted frontier (out of ~10³³ leaves in that cell). Under the natural ordering it lands inside and is found; an adversarial ordering could push it outside, so a same-budget run would not surface that specific leaf.

So yes — swap the ordering, or use a global budget instead of per-cell breadth, and a finite run could take vastly longer to reach King Wen, or miss its leaf at a given budget.

**Why this changes no finding.** The early appearance is a statement about the *algorithm's convenience*, not King Wen's mathematical status, and every result is invariant to it: (1) King Wen is a **known input**, verified directly in microseconds — the enumeration never needed to *find* it, only to map its neighbours; (2) the claims are **relative comparisons over the whole enumerated set** (complement-distance percentile, mandatory boundaries, position-1 forcing), computed with King Wen held known, so reordering the traversal does not move them; (3) King Wen's **membership** in the C1–C5 set is order-invariant. What *is* setup-dependent — which slice of the other ~10³⁸ solutions a given budgeted run includes — is exactly what the [partition-invariance](PARTITION_INVARIANCE.md) results pin down as reproducible under a fixed budget regime. A worse-ordered search that took years to walk up to King Wen would prove nothing new, because King Wen's significance was never "it is hard to find."

The headline holds: the ≈10³⁸ estimate shows King Wen is **not special by being rare or hard to find** — it is an easily-reached member of an astronomically large valid set, and its distinction is purely **structural**. This is exactly why the project's claims are about *where King Wen sits in the distribution*, never about it being combinatorially unique.

## Implications

1. **The space is ≈10³⁸ orderings and cannot be exhausted.** The deepest published canonical (d3 560T) found 1.05×10¹⁰ distinct orderings — ≈1 part in 10²⁷ of the ≈3×10³⁷ distinct-canonical total. Exhausting the space, or even any *single* first-level branch (~2×10³⁶), is off by 24+ orders of magnitude — infeasible at any budget that could ever be funded. The scientific value of the enumerations is therefore in the **structural invariants** they expose (mandatory boundaries, KW's position-1 forcing, complement-distance percentile), not in "how many" or in approaching completeness.

2. **The canonicals are reproducible slices, and deeper canonicals stay slices.** Each canonical scale is an exactly-reproducible slice at a fixed budget (see [`CANONICAL_HASHES.md`](CANONICAL_HASHES.md), [`PARTITION_INVARIANCE.md`](PARTITION_INVARIANCE.md)). Because the space is ≈10³⁸, a deeper canonical (e.g. a 1120T extension) is "more of the same slice," never "closer to complete" — its value is as a **discriminating test of the growth asymptote** (α ≈ 0.78), not as progress toward a total.

3. **Earlier crude size estimates were vast undercounts.** A prior product-of-averages estimate put the tree at 10¹⁴–10¹⁵ nodes; the unbiased estimator gives 2.09×10⁴⁰ — a ≈20-order-of-magnitude correction. Product-of-per-level-averages is severely biased downward for the heavy-tailed branching this tree exhibits; unbiased random-probe sampling (this method) is the correct tool.

## Provenance and status

- **Estimate, not canonical.** These numbers are Monte-Carlo estimates on the exploration track. They do not change, and are not gated by, any canonical sha256. No "proven" claim is made about the exact cardinality — only that it is ≈10³⁸ to within the stated ≈1% sampling error.
- **Reproducible:** `gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz`, then `solve --estimate-knuth 500000000` (whole tree) or `solve --estimate-knuth 100000000 <p1> <o1>` (one branch). Pure compute; no data disk required. The exact-count validation is `solve --estimate-knuth 0 <prefix>`.
- **Cost:** 5×10⁸ probes ≈ 79 s single-machine; the estimates above cost pennies of compute.
- See also: [`CRITIQUE.md`](CRITIQUE.md) (why budgeted counts are lower bounds), [`SOLVE-SUMMARY.md`](SOLVE-SUMMARY.md) §3-point scaling trajectory, [`BRANCHES_EXPLAINED.md`](BRANCHES_EXPLAINED.md) (what a branch/cell is).
