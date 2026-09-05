# Search-Space Size: How Many C1–C5 Orderings Exist

**Result:** The total number of hexagram orderings satisfying constraints C1–C5 is **estimated at ≈1.3×10³⁸** (raw), or **≈3×10³⁷ distinct canonical orderings** after orientation-deduplication — the quantity the published enumerations count. This is a **statistical estimate** from an unbiased Monte-Carlo tree-size estimator (Knuth 1975), validated to **<1%** against exact subtree counts; it is **not a proven cardinality** and is **not a canonical result**. Its purpose is to put a hard number on a question the budgeted enumerations could only bound from below: *the deepest published canonical (d3 560T, 1.05×10¹⁰ distinct orderings) has enumerated ≈1 part in 10²⁷ of the space, and exhaustion is infeasible at any conceivable budget.* ⚠ **[WITHDRAWN 2026-08-24 — the ≈3×10³⁷ distinct-canonical figure on this line exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]**

This closes the long-standing "the total count of C1–C5 orderings is not yet known" caveat carried in [`enumeration/LEADERBOARD.md`](../enumeration/LEADERBOARD.md), [`CANONICAL_HASHES.md`](CANONICAL_HASHES.md), and [`SOLVE_SUMMARY.md`](SOLVE_SUMMARY.md) — replacing "not yet known" with "known to ≈1% as an estimate, still astronomically unexhaustible."

## What is being measured

The enumerations (`solve.c`) are **budgeted**: each of the 158,364 depth-3 cells receives a fixed node budget, and the reported record count is the number of distinct canonical orderings *found within that budget*. Because no cell is ever exhausted (see [`CRITIQUE.md`](CRITIQUE.md) §"per-branch yield labels" — a single sub-branch budgeted to "yield 16" held ≥664 million orderings on a deeper walk), the canonical counts are **lower bounds**, not the size of the solution space. The three-point scaling trajectory (11.2T → 100T → 560T, α ≈ 0.67, see [`SOLVE_SUMMARY.md`](SOLVE_SUMMARY.md)) shows the counts still growing sublinearly with budget, with no visible asymptote.

This document measures the **total un-budgeted size** of the C1–C5 backtracking tree directly, without enumerating it — the number the budgeted counts are converging toward.

## Method — Knuth's random-probe estimator

Knuth (1975, *Estimating the efficiency of backtrack programs*, Math. Comp. 29). One **probe** is a single random root→dead-end walk of the exact `solve.c` search tree:

- Start at the root with weight `W = 1`.
- At a node with `d` live children (children passing the same C1/C2/C4/C5 prune predicates used by the real `backtrack()`), set `W ← W · d` and descend to one of the `d` children chosen uniformly at random.
- Stop at a dead end or at a completed depth-32 leaf.

Then `E[Σ W over the visited path]` equals the total number of tree nodes, and `E[W at a reached depth-32 leaf]` equals the number of complete orderings; applying the C3 test at the leaf gives the **canonical (C1–C5)** count. Each probe is an *unbiased* estimator of the whole; averaging `N` independent probes reduces variance as `1/√N`. The estimator is pure compute — **it touches no solution data and needs no enumeration artifacts** — and it reuses `solve.c`'s exact prune predicates, so it samples the identical tree the enumerator walks.

Implementation: `solve --estimate-knuth <probes> [prefix…]` (see [`SOLVE_C_CLI.md`](SOLVE_C_CLI.md)). Sha-neutral to the enumerator: the subcommand shares the prune predicates but adds no code on the enumeration path (`--selftest` unchanged).

## Validation — the estimator is correct

`solve --estimate-knuth 0 <prefix>` performs an **exact** deterministic subtree count. Comparing the Monte-Carlo estimate against exact ground truth on a King-Wen-following prefix, at increasing subtree depth:

| free positions | exact nodes | Knuth nodes | exact canonical | Knuth canonical |
|---:|---:|---:|---:|---:|
| 5 | 443 | 442.9 | 4 | 4.01 |
| 7 | 62,256 | 62,257 | 2,232 | 2,233 |
| 9 | 9,422,793 | 9,424,649 | 16,504 | 16,422 |

Agreement is **<1% at every depth**. *(A 56-branch cross-sum was run at the same time and is deliberately NOT restated here — scoped out 2026-08-27, TR-4 v1.22, see [CORRECTIONS.md](CORRECTIONS.md). Its per-branch values were never archived; the untraced-claims audit records the claim as NOT FOUND, and the "(below)" the sentence used to point at publishes only three order statistics (min/median/max), from which no sum is recoverable. The ladder agreement above is unaffected and stands on its own.)*

## Result — the whole C1–C5 tree

5×10¹⁰ probes (the 100×-probe definitive run, completed 2026-07-01; the earlier 5×10⁸ run gave 1.32×10³⁸ (rel. err 0.18%), ≈2σ below the definitive value — an unremarkable deviation for one early draw from a right-skewed weight distribution, in the direction (low) such skew predicts; the 100× run supersedes it):

| quantity | estimate | 95% CI | rel. error |
|---|---|---|---:|
| **C1–C5 orderings, RAW (orientation-explicit).** ⚠ **[HEADER CORRECTED 2026-08-28 — read "canonical (C1–C5) orderings (raw)", one cell asserting both object conventions at once. That cell is the root of the raw/canonical conflation withdrawn on 2026-08-24 and of the per-branch label defect corrected on 2026-08-28: in this corpus "canonical" means orientation-DEDUPLICATED, ceiling 31!, while this row is orientation-EXPLICIT, ceiling 31!·2³¹.]** | **1.3287×10³⁸** | [1.3283, 1.3292]×10³⁸ | 0.02% |
| — distinct canonical (after ~4× orientation-dedup) | **≈3.3×10³⁷** | — | — | ⚠ **[WITHDRAWN 2026-08-24 — the ≈3×10³⁷ distinct-canonical figure on this line exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]**
| complete orderings satisfying C1/C2/C4/C5 | 1.0971×10³⁹ — now known **exactly**: 1.097051×10³⁹ ([TR-11](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md), 2026-07-16; independently recomputed at full scale 2026-07-25 by verify.c's IE transfer-walk engine — exact match, TR-11 §10(vi); the exact value lands inside the estimate's stated envelope — see §"Absolute validation against an exact count") | — | 0.01% |
| total backtracking-tree nodes | 2.0875×10⁴⁰ | — | 0.00% |

For scale, this sits inside the standard reduction funnel (see [`SOLVE_SUMMARY.md`](SOLVE_SUMMARY.md) "numbers at a glance"): the unconstrained permutation space is 64! ≈ 1.3×10⁸⁹; the **C1 pair-structure skeleton is 32! × 2³² ≈ 1.1×10⁴⁵**; C2/C3/C4 successively cut that to ~10⁴⁰; and **C5 brings the true (un-budgeted) C1–C5 total to ≈1.3×10³⁸** (this estimate). Consistent with the funnel's earlier steps; it supplies the terminal count the funnel could previously give only as a budgeted lower bound (the 706 M found at the 10T budget). Still an enormous reduction, yet astronomically beyond enumeration.

## Result — per first-level branch

The 56 real first-level (position-1 pair, orientation) branches, 10⁸ probes each:

- raw orderings per branch (orientations counted, not deduplicated): **min 1.26×10³⁶, median 2.26×10³⁶, max 3.46×10³⁶ — a spread of only ≈2.7×**. ⚠ **[LABEL CORRECTED 2026-08-28 — these per-branch figures are RAW (orientations counted), not canonical. They sum to 1.33×10³⁸, the raw whole-tree estimate (TR-4 §3), and sit at ≈8×10⁻⁶ of the raw per-branch ceiling 30!·2³⁰ ≈ 2.85×10⁴¹ — the same fraction the raw whole-space estimate sits at of its own ceiling. Labelled "canonical" they would have exceeded the canonical per-branch ceiling 30! ≈ 2.65×10³² by 4,750–13,044×: the per-branch instance of the raw/canonical conflation withdrawn on 2026-08-24, missed by that sweep because it keyed on the whole-space figure. The per-branch *canonical* count is NOT established here — the ≈4× orientation-dedup factor needed to derive it is itself the withdrawn ingredient. See documentation/CORRECTIONS.md.]**
- **Roughly uniform: there is no small or near-exhaustible branch.** This answers the practical question behind single-branch deep-enumeration ("which branch is cheapest to exhaust, and does its structure extrapolate?"): every branch is comparably enormous (~2×10³⁶ **raw**), so no single-branch walk can exhaust anything, and extrapolation from one branch to the whole is well-founded in raw size. **The unexhaustibility conclusion does not depend on the withdrawn orientation-dedup factor.** Orientation-deduplication within a branch can divide by at most 2³⁰ ≈ 1.07×10⁹ (pairs 1 and 2 are already orientation-pinned), so the *canonical* count of even the smallest branch is at least 1.26×10³⁶ / 2³⁰ ≈ 1.2×10²⁷ — still ≈10¹⁷× beyond the 1.05×10¹⁰ orderings of the deepest published canonical. That floor is a worst-case bound on the dedup factor, not an estimate of it. The *uniformity* claim, by contrast, is raw-against-raw and is stated only for raw size: per-branch dedup factors were never measured, so uniformity of the canonical counts is not established. Compare [`PARTITION_INVARIANCE.md`](PARTITION_INVARIANCE.md), which partitions the same tree into these 56 branches for the reproducibility argument.

## Result — per-cell distribution + budgeted yield is uncorrelated with cell size

Per-cell Knuth estimate over all **65,281 productive depth-3 cells** (10⁵ probes each). Total un-budgeted canonical tree size per cell: **min 5.9×10³¹, median 8.1×10³², max 5.6×10³³** — a spread of only **94.6×** (log₁₀ span ≈ 2 orders). The productive-cell trees sum to ≈6.8×10³⁷, ~half the whole-tree raw estimate (the rest lies in the ~93K cells that produced 0 records within the 560T budget but still hold enormous un-budgeted trees).

Cross-plotting each cell's **budgeted yield** (distinct orderings found within the 560T per-cell budget, from the campaign shard manifest) against its **total un-budgeted size** (Knuth), across all 65,281 cells:

| quantity | spread across cells |
|---|---|
| budgeted yield (records at the 560T per-cell budget) | 10^1.1 – 10^6.8 (≈5.7 orders, heavy-tailed) |
| total un-budgeted tree size | 10^31.8 – 10^33.8 (≈2 orders, spread 94.6×) |
| **log-log correlation (full population)** | **Pearson r = 0.17, Spearman ρ = 0.15 → essentially uncorrelated** |

**A cell's budgeted yield is nearly independent of its total tree size.** The cells are all comparably enormous, but how many orderings each surfaces *within a fixed budget* varies by nearly six orders of magnitude and does not track total size. Yield is therefore a **local-density** phenomenon — how record-rich the shallow frontier is — not a size phenomenon. (The full-population result confirms the earlier 605-cell sample, r≈0.15.)

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

**Why this changes no finding.** The early appearance is a statement about the *algorithm's convenience*, not King Wen's mathematical status, and each finding is stated at the scope the setup supports: (1) King Wen is a **known input**, verified directly in microseconds — the enumeration never needed to *find* it, only to map its neighbours, and the values read off King Wen itself are order-invariant because they never consult the enumerated set; (2) the claims that are **relative comparisons over the enumerated set** (complement-distance percentile, mandatory boundaries, position-1 forcing) are properties of the canonical record set **under the fixed published regime** — the published depth, per-cell budget, and variable/value ordering — reproducible under that regime, and they are **not** claimed invariant under traversal *reordering*; (3) King Wen's **membership** in the C1–C5 set is order-invariant. What *is* setup-dependent — which slice of the other ~10³⁸ solutions a given budgeted run includes — is what the [partition-invariance](PARTITION_INVARIANCE.md) results pin down as reproducible: that theorem is about re-partitioning **the same traversal** (same constraints, same child order, same per-sub-branch budget) and is silent about changing the order itself. A worse-ordered search that took years to walk up to King Wen would prove nothing new, because King Wen's significance was never "it is hard to find."

⚠ **[SCOPE CORRECTED 2026-09-01 — clause (2) read "computed with King Wen held known, so reordering the
traversal does not move them", under a lead-in asserting "every result is invariant to it". That was
unsupported, and this tree holds a measured counterexample class: a percentile or a boundary-minimum is a
function of the **comparison set**, and reordering demonstrably moves the comparison set. Two measurements in
this repository, both at a fixed budget: [PERFORMANCE_HISTORY.md](PERFORMANCE_HISTORY.md) §"task #69: MRV
variable ordering" — numeric vs `SOLVE_VAR_ORDER=fail-first` on `--branch 24 0` at a canonical-equivalent
100 B budget found 60,519,764 vs 46,569,461 records with `|N∩F| = 0`, "genuinely non-overlapping slices of
the search tree, not refinements of each other"; and [SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md) §"What the
2026-04-25 test actually measured" — σ-induced child reordering at a fixed per-cell budget gave ≥21,000
mismatched cell pairs per σ and per-cell yield differences above 1.5 M, attributed there to "frontier
ordering" for exactly this reason. Clauses (1) and (3) were correct and stand unchanged. Whether each of the
three named statistics happens to survive a reordering is a separate question, and this document does not
settle it: settling it would take a recomputation of those statistics under one predeclared alternative
order, published beside the canonical-order values. Until then they are reported as regime-conditioned —
the same convention [CANONICAL_HASHES.md](CANONICAL_HASHES.md) applies to every other per-dataset figure.]**

The headline holds: the ≈10³⁸ estimate shows King Wen is **not special by being rare or hard to find** — it is an easily-reached member of an astronomically large valid set, and its distinction is purely **structural**. This is exactly why the project's claims are about *where King Wen sits in the distribution*, never about it being combinatorially unique.

## Implications

1. **The space is ≈10³⁸ orderings and cannot be exhausted.** The deepest published canonical (d3 560T) found 1.05×10¹⁰ distinct orderings — ≈1 part in 10²⁷ of the ≈3×10³⁷ distinct-canonical total. Exhausting the space, or even any *single* first-level branch (~2×10³⁶ **raw**; ≥≈10²⁷ canonical under the worst-case 2³⁰ dedup bound — see §"per first-level branch"), is off by 17+ orders of magnitude — infeasible at any budget that could ever be funded. The scientific value of the enumerations is therefore in the **structural invariants** they expose (mandatory boundaries, KW's position-1 forcing, complement-distance percentile), not in "how many" or in approaching completeness. ⚠ **[WITHDRAWN 2026-08-24 — the ≈3×10³⁷ distinct-canonical figure on this line exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]**

2. **The canonicals are reproducible slices, and deeper canonicals stay slices.** Each canonical scale is an exactly-reproducible slice at a fixed budget (see [`CANONICAL_HASHES.md`](CANONICAL_HASHES.md), [`PARTITION_INVARIANCE.md`](PARTITION_INVARIANCE.md)). Because the space is ≈10³⁸, a deeper canonical (e.g. a 1120T extension) is "more of the same slice," never "closer to complete" — its value is as a **discriminating test of the growth asymptote** (α ≈ 0.67), not as progress toward a total.

3. **Earlier crude size estimates were vast undercounts.** A prior product-of-averages estimate put the tree at 10¹⁴–10¹⁵ nodes; the unbiased estimator gives 2.09×10⁴⁰ — a ≈25-order-of-magnitude correction (log₁₀(2.09×10⁴⁰) = 40.3 against 10¹⁴–10¹⁵ is 25.3–26.3 orders; corrected 2026-08-01 from "≈20", which disagreed with TR-4 §3's ≈25). Product-of-per-level-averages is severely biased downward for the heavy-tailed branching this tree exhibits; unbiased random-probe sampling (this method) is the correct tool.

## Provenance and status

- **Estimate, not canonical.** These numbers are Monte-Carlo estimates on the exploration track. They do not change, and are not gated by, any canonical sha256. No "proven" claim is made about the exact cardinality — only that it is ≈10³⁸ to within the stated ≈1% sampling error.
⚠ **Every `--estimate-knuth` command below requires a stack limit of at least 16 MB** — `ulimit -s 16384` suffices, and `ulimit -s unlimited` is one way to satisfy it, not the requirement itself. Under the default 8 MB stack the estimator does not start: `main` allocates a ~7.23 MB frame and `estimate_tree_knuth` a further ~1.02 MB, so the 8 MB limit is exceeded the moment the estimator would be entered (since 2026-08-21 the binary preflights `RLIMIT_STACK`, refuses to start with an actionable message naming the >= 16 MB it needs, and exits 1; previously a bare SIGSEGV). This is environmental, not a logic fault — with the limit raised the published figures reproduce. *(Added 2026-08-21: found by a cold external-reviewer pass and independently reproduced; the requirement had been documented only in CANONICAL_HASHES.md's large-scale-enumeration recipe, while these guides state the estimator needs no data disk and costs pennies.)* *(Corrected 2026-09-01: the failure mode was previously described as a segfault before any output, telling an operator to expect exit 139 from a binary that has exited 1 with a diagnostic since 2026-08-21. `solve.c`'s `--estimate-knuth` parse block preflights `RLIMIT_STACK` and, below 16 MB, prints "solve: stack limit is %lu MB, but --estimate-knuth needs >= 16 MB ... Re-run with: ulimit -s unlimited" and returns 1; its own comment records "previously a bare SIGSEGV after the banner". That pass corrected the failure MODE only; the requirement itself is narrowed in the note below.)* *(Narrowed 2026-09-02, Codex V2-F08 #4, prose batch P37: `ulimit -s unlimited` is a **sufficient** setting that had been published as a **necessary** one — and one that a host or container with a hard stack cap cannot even apply, so the published requirement was a false blocker there. `solve.c`'s `--estimate-knuth` preflight tests `rlim_cur != RLIM_INFINITY && rlim_cur < 16UL*1024*1024` and its message names ">= 16 MB". EXECUTED under TR-9 v1.24 on a locally built binary: `ulimit -s 8192` refuses and exits 1, `ulimit -s 16384` runs the estimator to completion. `solve.c`'s own remedy line still prescribes only `unlimited` and is queued to offer both. This is the sibling propagation of the narrowing TR-9 made on 2026-09-02 and reported but did not sweep.)*
- **Reproducible:** `gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz`, then `solve --estimate-knuth 500000000` (whole tree) or `solve --estimate-knuth 100000000 <p1> <o1>` (one branch). Pure compute; no data disk required. The exact-count validation is `solve --estimate-knuth 0 <prefix>`. **The definitive whole-tree run is `SOLVE_THREADS=32 ./solve --estimate-knuth 50000000000`** (5×10¹⁰ probes, 32 threads, 18,230 s wall; the estimator is deterministic at fixed (probes, threads, seed)) — archived stdout [`reports/evidence/knuth_whole_tree_5e10.out`](../reports/evidence/knuth_whole_tree_5e10.out), the 2026-07-26 same-seed re-run, which reproduces every published figure of the 2026-07-01 run digit-for-digit (published 2026-09-02). ⚠ **[Corrected 2026-09-02: the 5×10⁸ whole-tree command reproduces the SUPERSEDED early run recorded in §"Result — the whole C1–C5 tree" — 1.32×10³⁸ at rel. err 0.18% — not the published 1.3287×10³⁸ / 0.02%, which that same section attributes to the 5×10¹⁰-probe definitive run of 2026-07-01 and records as superseding the 5×10⁸ draw. No 5×10¹⁰ whole-tree invocation appears anywhere in the tracked corpus, and `reports/evidence/` archives KNUTH-ESTIMATE stdout at 2×10⁹, 5×10⁹, 2×10¹⁰, 4×10¹⁰ and 5.5×10¹⁰ probes but none at 5×10¹⁰ — so the headline estimate has no published reproduction command. Publishing the 5×10¹⁰ invocation with its thread count and archived stdout is the open fix.]**
- **Cost:** 5×10⁸ probes ≈ 79 s single-machine; the estimates above cost pennies of compute.
- See also: [`CRITIQUE.md`](CRITIQUE.md) (why budgeted counts are lower bounds), [`SOLVE_SUMMARY.md`](SOLVE_SUMMARY.md) §3-point scaling trajectory, [`BRANCHES_EXPLAINED.md`](BRANCHES_EXPLAINED.md) (what a branch/cell is).

## The C1–C7 space: the Uniqueness Conjecture is refuted (2026-07-02)

Extending the random-probe walk with the spec's C6/C7 adjacency constraints (`SOLVE_KNUTH_C67=1`, slots
24–27 pinned to King Wen's pairs, orientation free) makes the Uniqueness Conjecture — our name for the
strong determinism reading of the literature's derivation claims and this project's own early working
hypothesis ([attribution note](CITATIONS.md#uniqueness-conjecture)) — directly
measurable. Result (5×10¹⁰ probes, D32 — `SOLVE_KNUTH_C67=1 SOLVE_THREADS=32 ./solve --estimate-knuth 50000000000`, ≈2 h 04 min wall; archived stdout [`reports/evidence/c67_probe.out`](../reports/evidence/c67_probe.out), published 2026-09-02):

| Quantity | Estimate | 95% CI | rel. err |
|---|---|---|---|
| C1–C7-satisfying orderings | **5.21×10³¹** | [5.13, 5.29]×10³¹ | 0.78% |
| C1+C2+C4+C5 + C6/C7 pins (no C3) | 5.18×10³² | [5.16, 5.21]×10³² | 0.25% |
| pinned tree nodes | 1.4539×10³⁵ | — | 0.00% |

**Interpretation.** C6+C7 cut the C1–C5 space (≈1.33×10³⁸) by ×2.55×10⁶ — but ≈5.2×10³¹ orderings survive.
King Wen is not uniquely determined by the published constraint system over the full space; uniqueness holds
only within enumerated budgeted datasets (where 5 greedy-ordered boundary constraints isolate it at
canonical depth; corrected 2026-07-04 from "4" — see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md)). Closing
the remaining ≈105 bits would require roughly 15–20 boundary constraints. A first exact corroboration at
small scope: within the KW-following 22-pair prefix subtree, exact counting finds 16,504 **oriented**
C1–C5 completions of which exactly **8** satisfy C6/C7 — **all eight sharing King Wen's pair ordering**.
⚠ **[CORRECTED 2026-08-28 — this read "KW plus seven others even in its own immediate neighborhood", which
invites a pair-ordering reading that is the OPPOSITE of what the enumeration shows. The seven "others" are
orientation variants of King Wen's own pair sequence. The 16,504 are ORIENTED leaves — 899 distinct pair
orderings — and C6/C7 eliminate 898 of the 899, leaving King Wen's alone. Verified with the shipped binary:
pair ordering free, C6/C7 leave 8; every free slot additionally pinned to KW's pairs with only orientation
free gives **also 8** (tree_nodes 1169 → 233, a strict subtree) ⚠ **[RUN DESCRIPTION CORRECTED 2026-08-28 — first published as "tree_nodes 1169 → 233" with the words "every free slot". That run pinned slots 24–32, which leaves position 23 order-free (pins 24–31 give the identical 233, so slot 32 was a no-op); pinning all nine free steps 23–32 gives **75** nodes. The survivor count is **8** in every variant and the conclusion is unchanged — only the description of the run was wrong. Found by the D2 lens-1 executed review, which re-ran it.]** ⚠ **[REPRODUCTION COMMAND PUBLISHED 2026-08-29 (Q-395, settling Q-343) — these two figures shipped with no way to check them, while the provenance note claimed the public verification path was "re-running the published `SOLVE_KNUTH_C67` command", which was published nowhere. Both reproduce in under 10 ms with the shipped binary:

```bash
PREFIX="1 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 20 0 21 0 22 0"
ulimit -s unlimited

SOLVE_KNUTH_C67=1 ./solve --estimate-knuth 0 $PREFIX
#   tree_nodes 1169   leaves_C1C2C4C5 88   leaves_canonical_C1C5 8

SOLVE_KNUTH_C67=1 SOLVE_KNUTH_PIN_SLOTS="24,25,26,27,28,29,30,31" ./solve --estimate-knuth 0 $PREFIX
#   tree_nodes  233   leaves_C1C2C4C5  8   leaves_canonical_C1C5 8

SOLVE_KNUTH_C67=1 SOLVE_KNUTH_PIN_SLOTS="23,24,25,26,27,28,29,30,31" ./solve --estimate-knuth 0 $PREFIX
#   tree_nodes   75   — every free slot pinned
```

`--estimate-knuth 0` means **zero random probes**, i.e. exact enumeration of the subtree. It is bounded here only because the 22-pair prefix makes that subtree small; issued without the prefix the same command is an unbounded full walk, which is what an earlier reproduction attempt hit.

**The slot labels are corrected too.** `SOLVE_KNUTH_PIN_SLOTS` takes **step** numbers and accepts 1–31 (`(knuth_pin_mask >> step) & 1u`, `solve.c`), so a "slot 32" cannot be named at all — the earlier marker's "slots 24–32" is not a range the flag can express, which is why its own author found slot 32 to be "a no-op". Steps are 0-based and **position = step + 1**. After the 22-pair prefix the free steps are **23–31**, i.e. **positions 24–32**. The 233 run pins steps 24–31 = **positions 25–32**, so the slot left order-free is **position 24**, not position 23. Pinning every free step (23–31 = positions 24–32) gives **75**.

The conclusion is untouched by all of this: **8** survivors in every variant, all carrying King Wen's pair ordering.]**, so no survivor departs from KW's pair
sequence. At this scope the check corroborates UNIQUENESS in the canonical frame — the paragraph above
argues non-uniqueness at the ORIENTED level, which is a different object; both can hold, and the sentence
must not be read as evidence for the first. See CORRECTIONS.md 2026-08-28.]**
Provenance: estimator extension in solve.c (`SOLVE_KNUTH_C67`), sha-neutral (selftest-gated); the
2026-07-02 run's stdout is archived at [`reports/evidence/c67_probe.out`](../reports/evidence/c67_probe.out)
(published 2026-09-02 — until then it lived only in the private repository), and the full-scale
invocation is the one printed beside the result table above. The exact-count `SOLVE_KNUTH_C67`
commands in the block above reproduce their counts directly and in milliseconds.

## The boundary-information curve S(k) (2026-07-03)

How fast does knowledge of King Wen's boundary structure shrink the full space? Define S(k) = the fraction
of the full C1–C5 population agreeing with KW on the first k boundaries of the 560T greedy identifying
order {4, 27, 25, 21, 1} (the first four measured here; agreement at boundary b = both flanking slots hold KW's pairs — the
[PARTITION_STABILITY_BOUNDARIES.md](PARTITION_STABILITY_BOUNDARIES.md) predicate). Measured with pinned
Knuth walks (`SOLVE_KNUTH_PIN_SLOTS`; 2×10⁹ probes per prefix; relative error ≤10%):

| k | pins (boundary) | S(k) | absolute survivors (×1.3287×10³⁸) | per-boundary cut |
|---|---|---|---|---|
| 1 | 4 | 7.49×10⁻⁴ | 9.95×10³⁴ | ×1,335 |
| 2 | +27 | 9.39×10⁻⁷ | 1.25×10³² | ×798 |
| 3 | +25 | 4.27×10⁻¹⁰ | 5.68×10²⁸ | ×2,196 |
| 4 | +21 | 6.34×10⁻¹³ | **8.42×10²⁵** | ×674 |

**Headline:** the first four boundaries of the 560T greedy identifying set — which inside the 560T slice
leave only KW plus a single impostor (the full identifying set has 5 boundaries; corrected 2026-07-04,
see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md)) — still admit
≈**10²⁶ orderings in the full space** — the sharpest quantification yet of the slice-uniqueness vs
space-uniqueness distinction this document has always cautioned about. Extrapolating the roughly constant
~10³ per-boundary cut put full-space uniqueness at roughly 13–14 boundaries; the 2026-07-05 S(6)–S(8)
measurement (TR-4 §"the marginal-gain curve bends") shows the gains decline past k=5, revising the
projection to ~15–20 (observed-rate extrapolation ~12; see the note below — it is not a lower bound). A bracketing exploration choosing among the *weakest* remaining boundaries
(k = 5–8) reported roughly ×15–17 per boundary, but ⚠ **that band is not reproducible from published
material and is offered as illustration, not measurement** (restated 2026-09-02; both archived S(k)
artifacts, `reports/evidence/sk/sk5_7_rounds.out` and `sk8_round.out`, are *greedy* chains, no
weakest-remaining chain or command for one is published, and "weakest" is nowhere defined against a
candidate set — round 5's own sweep puts its largest-surviving candidate at a ×14.5 cut, below the
band's floor). The robustness-to-boundary-choice reading rests on it and is correspondingly weak. Extending the *greedy* curve past k = 4 requires ~100× the probe budget (conditional
masses starve below ~10⁻¹³ hit rates); it was completed 2026-07-05 (S(6)–S(8), TR-4). Reproduce:
`SOLVE_KNUTH_PIN_SLOTS="3,4,26,27,24,25,20,21" SOLVE_KNUTH_BOUNDARY_COND=1 ./solve --estimate-knuth 2000000000`. ⚠ **[THREAD PIN MISSING — 2026-09-03 sibling sweep. Per [METHODS](../reports/METHODS.md) §"Reproducibility rule for estimator output", the Knuth estimator's seeds are fixed constants and **the thread count selects the sample**, so a re-run reproduces a published figure only at the identical (probes, threads) pair. This command carries no `SOLVE_THREADS=N`, and the thread count used for the published number is not recorded anywhere in the corpus — so it is **not reproducible exactly as stated**; a reader on a different core count gets a different draw, not this one. The two 5×10¹⁰ invocations were pinned by code batch V-1 (Codex V2-19 #3); these sampled siblings in the same files were not. Note this is a REPRODUCIBILITY defect, not the performance caveat recorded nearby: thread count changes the estimate, not merely the wall time.]**

## Absolute validation against an exact count (2026-07-04)

The estimator now has a full-scale ground-truth anchor: |C1∩C2∩C4| was computed EXACTLY
(757,058,601,340,255,440,651,419,713,405,330,315,358,208, via the S4-orbit-quotient dynamic program — see
[DESCRIPTION_LENGTH.md](DESCRIPTION_LENGTH.md) and [reports/TR5](../reports/TR5_SYMMETRY.md)). The Knuth estimate of the same quantity (7.571×10⁴¹, stated
±0.01%) contains the exact value inside its stated envelope. (The apparent 5.5×10⁻⁵ gap is the distance
to the estimate's four-sig-fig rounding, not a measured estimator error; the true error is unresolved at
the published precision but well within ±0.01% — mirrors TR-11 v1.4 / TR-4's hedge.) Every other
estimate in this document uses the same machinery at comparable or better hit rates; this is direct
evidence the stated envelopes are honest.

**A second full-scale anchor (2026-07-16), at the 10³⁹ scale:** |C1∩C2∩C4∩C5| was computed EXACTLY
(1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097051×10³⁹, via the out-of-core
symmetry-quotient DP — see [reports/TR-11](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)). The
Knuth estimate of the same quantity (1.0971×10³⁹, stated ±0.01%) again contains the exact value inside
its stated envelope (the 4.4×10⁻⁵ / ratio-0.999956 figure is the estimate's five-sig-fig rounding gap,
not a resolved estimator error). (The full C1–C5 count remains an estimate — for **cost**, not
structural, reasons: C3's global complement-position sum collapses to the bounded scalar identity
**C3 = 16 + 8·G** — a machine-checked repo theorem since 2026-07-04, `lean/C3Decomposition.lean`
`c3_slot_decomposition` — so a bounded-state exact design exists; carrying the G-channel alongside C5's
budget state is sized at an estimated ~15–30× the C5 DP's footprint (TR-11 §10(ii); figures
provisional, more likely low than high), outside this project's budget —
see TR-11 §10(ii).)

## An information-rate extrapolation for the uniqueness-boundary count (2026-07-04)

> **Label corrected 2026-08-01:** previously headed "An information floor". No floor is established — see
> the extrapolation bullet below and TR-4 v1.15/v1.16 for why the argument bounds nothing.

Identifying King Wen within the C1–C5 space requires log₂(1.3287×10³⁸) = **126.6 bits**. *(Population context, 2026-09-05: that figure is the size of the extracted space, not a King Wen property — at the C5 layer a random C1∩C2 ordering's own extracted multiset leaves a space of the same size, King Wen at the 65th percentile of 1,000 decoys, [TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md) §2 population context; the C3 cut inside 126.6 and the per-boundary rate below remain King Wen-measured only.)* ⚠ **[SCOPE NOTE added 2026-08-28 — this prices the RAW, orientation-explicit object, which is the right one here because a boundary constraint identifies an oriented ordering. Stated over the orientation-deduplicated object the figure would be log₂(31!) = **112.66 bits** — a ceiling, since the canonical count is at most 31!. The two differ by ~14 bits, so any comparison of this number against a canonical-object count is a units error of about one and a half boundary-steps.]** The measured
greedy boundary chain S(1..5) yields per-step information gains of 10.38, 9.64, 11.10, 9.40, 10.13 bits
— strikingly flat (mean 10.13; corrected 2026-08-01 from "10.07", which is not the mean of the five listed gains), and the first step is the maximum **unconditional** single-boundary gain by construction (greedy picks it first) — **but NOT the maximum over all conditioning contexts: step 3 gains 11.10 bits, exceeding it. Corrected 2026-08-01; the earlier text used 10.38 as a universal per-boundary cap, which its own data falsifies**
(greedy picks the minimum-survivor boundary). Two consequences, honestly labeled:

- **Observed-rate extrapolation: ~12 boundaries — NOT a floor.** Dividing the 126.6 bits by the largest
  gain observed in *any* conditioning context (11.10 bits, at step 3) gives ⌈126.6/11.10⌉ = 12. **This is
  not a lower bound on k and must not be read as one.** A necessity bound would require a supremum over
  all boundaries *and* all conditioning contexts; five samples along a single greedy path bound no such
  supremum. The number is what the measured rate extrapolates to, nothing more. *(Corrected 2026-08-01, second pass: the 2026-08-01 correction above replaced the falsified
  premise — that 10.38 is a universal per-boundary cap — but this bullet was left deriving 13 from it,
  so the paragraph contradicted itself. The divisor must be the maximum over all contexts, not the
  unconditional maximum.)* This is heuristic, not a
  theorem — boundary synergies can exceed the *unconditional* single-boundary maximum, and this chain
  already shows one: step 3's 11.10 bits exceeds step 1's 10.38, which is precisely why 11.10 is the
  divisor above. What the five steps show is flatness (all within ~1 bit, close to the naive
  slot-information value), not the absence of synergy. *(Corrected 2026-09-02, prose batch P34: the retired wording
  denied any synergy across the five steps while this same bullet divided by 11.10 precisely because
  step 3 exceeds step 1. See CORRECTIONS.md, RP-fa6c3b89, and TR-4 v1.15.)*
- **Rate projection: ≈ 13.** At the observed average marginal rate, the chain reaches 126.6 bits at
  k ≈ 13, tightening the earlier 13–20 extrapolation toward its lower end.

Both figures sharpened once S(6..8) had landed: **2026-07-05, revising the projection up to ~15–20** (see the S(k) section above and TR-4 v1.8); the ≈13 figure below predates that measurement. *(Tense corrected 2026-09-02, prose batch P34 — the line had read as a pending condition beside its own answer; RP-11166bb6.)* Derivation: this section's arithmetic
is fully reproducible from the S(k) masses above and the space size; no new measurement was used.
