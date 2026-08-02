# Enumeration Leaderboard

> Canonical sha256 hashes, record counts, and reproducibility parameters are listed in [`CANONICAL_HASHES.md`](../documentation/CANONICAL_HASHES.md). The deepest published partial enumeration is the **d3 560T canonical** (established 2026-06-08): **10,525,271,997 orderings** (`9a968fa2…`, current main lineage at git `2b01b15`). **As of 2026-06-30 the 560T canonical is CANONICAL-verified** — it was SUSPECT from 2026-06-21 (a proven eviction-resume determinism bug + 5 Spot evictions on the pre-fix solver), but a from-scratch re-run on the fixed solver reproduced `9a968fa2` byte-for-byte (identical sha and 10,525,271,997-record count, across 7 fresh evictions that all resumed cleanly), so the original run was complete and the count above stands. See [CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) §d3 560T. The d3 100T canonical at 3,432,399,297 orderings (`915abf30…`) is the next-deepest and remains an active reference anchor for cross-scale stability checks. The v2 100T row (3,663,580,914 orderings, `cc4a5377…`, +6.74 % over v1 100T) is frozen as historical record — see CANONICAL_HASHES.md §"Historical (frozen lineages)". The d3 10T and d2 10T canonicals remain at fully-validated reference counts and serve as drift-detection anchors at smaller scales. Older figures (742M hash-bug, 31.6M filename-collision bug) appear only as historical context. The difference between d2 and d3 counts is a partition-strategy effect, not a constraint difference. The 100T : 10T ratio of 4.86× (v1) and the **560T : 100T ratio of 3.07×** (v1, current main) both reflect diminishing returns in the search tree (linear node budget yields sublinear new-orderings) — the 3-point fit across 11.2 T → 100 T → 560 T gives an empirical power-law exponent α ≈ 0.67 (3-point log-log fit; pairwise legs 0.69 and 0.65). The 2026-06-14 three-point per-cell analysis confirms the trajectory is **strictly nested** — 11.2T ⊆ 100T ⊆ 560T with **0 monotonicity violations** under pair-identity keying (records 759,608,573 → 3,432,399,297 → 10,525,271,997; pair-identity cells yielding 9,799 → 10,062 → 10,618) — and that growth is **deepening of existing productive cells, not new regions** (cells first appearing at a larger scale contribute only ~0.2% then ~0.5% of that scale's records). Every sampled sub-branch remains **BUDGETED (none EXHAUSTED)** at 560T, so the exhaustive enumeration cannot state an exact total — but an unbiased Monte-Carlo estimate (Knuth random-probe, validated <1%) puts the total at **≈10³⁸** (≈3×10³⁷ distinct-canonical), so even 560T's 10.5 B is ≈1 part in 10²⁷ of the space and exhaustion is infeasible at any budget (see [`SEARCH_SPACE_SIZE.md`](../documentation/SEARCH_SPACE_SIZE.md)). Each canonical scale is a reproducible *slice* at a fixed budget. A 1120T extension would have been a discriminating test of the asymptote; it is **not planned** (2026-08-01), so **560T is the deepest canonical this project will publish**. (Orientation-specific keying shows spurious "violations" — an artifact of orientation-collapse dedup, not real non-monotonicity.)
>
> **Novel finding from 100T [`--c3-min`](../documentation/SOLVE_C_CLI.md#--c3-min) analysis (2026-04-20; 560T re-affirmed 2026-06-11):** KW is **not** the C3-minimum under C1+C2+C3. At 100T: minimum complement distance = **424** (221 records); KW sits at C3 = 776 (ceiling of the constraint). At 560T (3.07× the scale), KW's position at the C3 = 776 *ceiling* is reaffirmed. The simple axiom "minimize C3" does not derive KW — this is a confirmed negative result for Open Question #7 Phase A across both scales.
>
> **Second novel finding (2026-04-20 100T baseline; updated 2026-06-11 with full 560T [`--analyze`](../documentation/SOLVE_C_CLI.md#--analyze); corrected 2026-07-04):** the **boundary-minimum is monotone non-decreasing in scale: 4 → 5 → 5 across 10T → 100T → 560T**. At d2 10T and d3 10T, 4-boundary subsets uniquely identify KW. At d3 100T, NO 4-subset worked; greedy-optimal was a 5-set **{1, 4, 21, 25, 27}**. At d3 560T (current deepest), **the greedy minimum stays 5 with the identical set {4, 27, 25, 21, 1}** (boundary 4 alone eliminates 99.999% of non-KW; 27 → 481 survivors; 25 → 14; 21 → 1; boundary 1 eliminates the last impostor, rec#330177707 — KW with the position-2/3 pair blocks swapped). The working-4-subset count (§[8]) drops to **0** at 560T, vs 4 at 742M and 8 at 11.2T — at canonical depth no 4-tuple of boundaries jointly reduces survivors to ≤ 1, consistent with the greedy minimum of 5. *(Cross-era caveats, added 2026-07-04: the "8" is log-verified at d3 10T, and the 11.2T attribution awaits confirmation from the archived 11.2T analyze log; the 742M "4" was computed under the pre-format-v1 "survivors ≤ 4" convention — 4 orientation variants per ordering — vs the canonical-era "≤ 1", so the series is directionally sound but not convention-identical.)* *(The 2026-06-11 version of this note reported "drops back to 4 at 560T, non-monotone" — a survivor-counting error that stopped at 1 remaining non-KW survivor instead of 0; see [BOUNDARY_MINIMUM.md](../documentation/BOUNDARY_MINIMUM.md).)* Boundaries {25, 27} remain in the greedy minimum across every partition tested. §[9] result: `{25, 27}` is one of the most informationally-independent boundary pairs (ratio 0.007) — explaining WHY they keep appearing. §[10] top pairwise MI at 560T: pos 12 ↔ 13 = 1.3417 bits (cascade-region 11–20 dominates the top-10). §[18] boundary 4 alone yields 45.14 bits of conditional-entropy information gain (of 77.81 bits total baseline) — half of total entropy. See [PROJECT_OVERVIEW.md](../documentation/PROJECT_OVERVIEW.md) §"560T canonical results" + [HISTORY.md](../documentation/HISTORY.md) "June 10-11, 2026" entry for the full §[1]–§[28] dump.
>
> **Single-branch deep-walk pilot (2026-04-29):** `22_0_30_1_20_0` at d3 100T per-task-cap = 40 G:
> **664,086,250 canonical orderings** in this *single* depth-3 sub-branch (sha `52c8d308257d3b75041d0743b4b02a37360fe6567fec7c1c07ed49d8d22a29b9`, 20.0 GB). Distinct from the d3 100T full-canonical (`915abf30…`, 3.43 B across all 158,364 branches) — this is *one* branch with a higher per-cell budget. The 100T canonical's per-branch budget reported `22_0_30_1_20_0` as a "yield-16 laggard"; this pilot with 100T concentrated on the single branch found ~50,000,000× more solutions, demonstrating the canonical's per-branch yield labels are scope-bounded by per-branch budget rather than branch yield. 0 of 2,380 walked (p4, o4, p5, o5) cells naturally exhausted under the 40 G per-cell cap. See HISTORY.md §April 28-29 for full details.
>
> **5.6T regression-test verification (2026-04-30):** the [`--double-regression-test`](../documentation/SOLVE_C_CLI.md#--double-regression-test) mode produced sha **`c34390c00a2a871d78f49dd419779c0f649ed8271387c424ac4d36e0f3910dbd`** (467,483,137 canonical orderings, 14.96 GB) across 4 verification paths: full-enum layer 1, full-enum layer 2 (deterministic re-run), `--merge-layers` of both full-enum layers, AND `--merge-layers` of 56 first-level `--branch p1 o1` reconstruction layers. All four shas match. This empirically confirms partition invariance at depth-3 with controlled per-sub-branch budget (`SOLVE_PER_SUB_BRANCH_LIMIT=35361572`, = 5.6T / 158,364 sub-branches), AND verifies layered-merge correctness via `--merge-layers`. The verification surfaced and fixed a depth-2 bug in `--branch` (commit `cdd8575`). Prior 2026-04-29 attempts were INCONCLUSIVE due to that bug. See [PARTITION_INVARIANCE.md](../documentation/PARTITION_INVARIANCE.md) §1 and [HISTORY.md](../documentation/HISTORY.md) §"April 29, 2026" for the full retrospective. *(Note: this `c34390c0…` / 467,483,137 5.6T sha was later deprecated and superseded by the modern-code re-derivation `f66920c1…` / 467,484,167 records (+1,030, likely lost to imperfect resume on pre-fix code); the values here are preserved as recorded — see [CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) §"d3 5.6T".)*

## What this is

Long ago — traditionally about 3,000 years, though the dating of the ordering's
fixation is debated — someone in ancient China, or successive generations of
practitioners, arranged 64 symbols called
[hexagrams](https://en.wikipedia.org/wiki/Hexagram_(I_Ching)) in a specific order —
the [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence).
There are more possible arrangements than atoms in the universe (about 10^89).
But King Wen follows mathematical rules so strict that only a fraction of
arrangements satisfy them all. This project is cataloging every valid arrangement
to understand what makes the historical one special — or whether it is simply
one choice among many.

For the rules themselves, see [SOLVE_SUMMARY.md](../documentation/SOLVE_SUMMARY.md).
For formal definitions, see [SPECIFICATION.md](../documentation/SPECIFICATION.md).

---

# Part 1: What we have learned

## How constrained is each position?

The King Wen sequence arranges 32 hexagram pairs in order. Position 1 (the opening
pair) is mathematically forced — it must be ䷀ The Creative / ䷁ The Receptive.
But how free are the remaining 31 positions? The table below shows what the
enumeration has found so far.

| Position | King Wen pair | KW match % | Pairs observed | Entropy (bits) | Character |
|:--------:|---------------|:----------:|:--------------:|:--------------:|-----------|
| 1 | ䷀䷁ #1 / #2 | 100.0% | 1 | 0.00 | Fully determined |
| 2 | ䷂䷃ #3 / #4 | 0.2% | 16 | — | Branch-dependent (varies widely) |
| 3 | ䷄䷅ #5 / #6 | 0.2% | 31 | 4.12 | Highest freedom |
| 4 | ䷆䷇ #7 / #8 | 0.5% | 3 | 0.28 | Cascade region (heavily constrained) |
| 5 | ䷈䷉ #9 / #10 | 0.9% | 3 | 0.54 | Cascade region |
| 6 | ䷊䷋ #11 / #12 | 0.9% | 3 | 0.54 | Cascade region |
| 7 | ䷌䷍ #13 / #14 | 3.4% | 3 | 0.77 | Cascade region |
| 8 | ䷎䷏ #15 / #16 | 3.4% | 3 | 0.77 | Cascade region |
| 9 | ䷐䷑ #17 / #18 | 4.1% | 3 | 0.87 | Cascade region |
| 10 | ䷒䷓ #19 / #20 | 5.2% | 3 | 0.97 | Cascade region |
| 11 | ䷔䷕ #21 / #22 | 5.2% | 3 | 0.97 | Cascade region |
| 12 | ䷖䷗ #23 / #24 | 5.2% | 3 | 0.97 | Cascade region |
| 13 | ䷘䷙ #25 / #26 | 5.2% | 3 | 0.97 | Cascade region |
| 14 | ䷚䷛ #27 / #28 | 5.2% | 3 | 0.97 | Cascade region |
| 15 | ䷜䷝ #29 / #30 | 7.3% | 3 | 1.15 | Cascade region |
| 16 | ䷞䷟ #31 / #32 | 11.2% | 3 | 1.41 | Cascade region |
| 17 | ䷠䷡ #33 / #34 | 11.2% | 3 | 1.41 | Cascade region |
| 18 | ䷢䷣ #35 / #36 | 12.9% | 3 | 1.50 | Cascade region |
| 19 | ䷤䷥ #37 / #38 | 49.4% | 3 | 1.72 | Cascade region |
| 20 | ䷦䷧ #39 / #40 | 51.8% | 3 | 1.72 | Cascade region |
| 21 | ䷨䷩ #41 / #42 | 16.4% | 14 | 3.45 | Progressively free |
| 22 | ䷪䷫ #43 / #44 | 11.0% | 14 | 3.51 | Progressively free |
| 23 | ䷬䷭ #45 / #46 | 12.5% | 14 | 3.55 | Progressively free |
| 24 | ䷮䷯ #47 / #48 | 10.7% | 14 | 3.55 | Progressively free |
| 25 | ䷰䷱ #49 / #50 | 5.7% | 14 | 3.58 | Progressively free |
| 26 | ䷲䷳ #51 / #52 | 9.4% | 14 | 3.58 | Progressively free |
| 27 | ䷴䷵ #53 / #54 | 7.7% | 14 | 3.58 | Progressively free |
| 28 | ䷶䷷ #55 / #56 | 8.9% | 14 | 3.60 | Progressively free |
| 29 | ䷸䷹ #57 / #58 | 11.3% | 14 | 3.62 | Progressively free |
| 30 | ䷺䷻ #59 / #60 | 9.6% | 14 | 3.62 | Progressively free |
| 31 | ䷼䷽ #61 / #62 | 18.4% | 14 | 3.65 | Progressively free |
| 32 | ䷾䷿ #63 / #64 | 21.3% | 7 | 2.58 | Progressively free |

*KW match % = how often King Wen's pair appears at this position across ALL valid*
*orderings (all branches combined). Pairs observed and entropy values in this table were*
*originally computed from the bug-era 742M dataset; they have NOT been refreshed to the*
*current canonical datasets. For up-to-date per-position entropies see the `--analyze`*
*output archived at `runs/20260419_100T_d3_d128westus3/` (primary, 3.43B records)*
*or `runs/20260418_10T_d3_fresh/` and `20260418_10T_d2_fresh/` (10T baselines),*
*or the `D2_D3_ANALYZE_FINDINGS.md` summary (outside the git repo). The gradient shape*
*(pos 1 locked; pos 3-19 constrained; pos 22-31 free) holds across all three datasets;*
*specific numbers shift with partition depth. Max possible entropy = log2(32) = 5.0 bits.*

**Key insight:** The sequence is not uniformly constrained. Position 1 is fully
determined. Position 2 is a major branching point (16 options). Positions 3-18 are
highly constrained (per-position Shannon entropy 0.28-1.72 bits vs a maximum of 5.0),
though not fully locked — each branch admits 2-29 distinct configurations across
positions 3-19. Positions 19-32 open up dramatically — up to 16 pairs are possible,
and King Wen's choice is one among many. Whoever arranged the sequence had limited
freedom in the first half but considerable freedom in the second half.

## How close are the nearest alternatives?

The closest valid orderings differ from King Wen by just **2 pair positions** —
always in the last third of the sequence (positions 26-32). The top 20 nearest
alternatives all differ at exactly 2 positions. No valid ordering differs by just 1.

The edit distance distribution (number of pair positions differing from King Wen):

| Positions different | Count | Notes |
|:-------------------:|------:|-------|
| 0 | 4 | King Wen itself (orient variants) |
| 1 | 0 | No valid ordering is 1 swap from KW |
| 2 | 44 | Closest alternatives — single pair-swaps in positions 21-32 |
| 3 | 6 | |
| 4+ | ~742,043,249 | Bulk of solutions |

**Note:** The edit-distance distribution above is from the `--analyze` section [24] nearest-neighbor catalog on the 742M dataset. Only distances 0-3 have been exactly counted; the full distribution has not yet been computed at 742M scale. (The earlier table showing counts summing to ~5.9B was from the pre-bugfix 31.6M era and is no longer valid.)

Most valid orderings look **nothing like** King Wen. King Wen is not
"typical" among valid orderings; it sits at one extreme.

## Which pairs can appear at position 2?

Position 2 is the first "free" position — 16 different pairs can validly follow
Creative/Receptive. King Wen's choice (䷂䷃ #3 Difficulty / #4 Folly) appears in only
0.2% of valid orderings. Some choices at position 2 produce millions of downstream
valid orderings; others produce zero.

| Position 2 pair | Valid orderings found | Share | Notes |
|----------------|---------------------:|------:|-------|
| ䷢䷣ #35/#36 | 8,388,608 | 15.8% | Extremely dense |
| ䷰䷱ #49/#50 | 8,388,608 | 15.8% | Extremely dense |
| ䷼䷽ #61/#62 | 7,558,035 | 14.2% |  |
| ䷬䷭ #45/#46 | 7,396,872 | 13.9% |  |
| ䷚䷛ #27/#28 | 4,479,414 | 8.4% |  |
| ䷜䷝ #29/#30 | 4,450,074 | 8.4% |  |
| ䷊䷋ #11/#12 | 3,318,924 | 6.3% |  |
| ䷮䷯ #47/#48 | 2,497,384 | 4.7% |  |
| ䷠䷡ #33/#34 | 2,389,418 | 4.5% |  |
| ䷐䷑ #17/#18 | 1,352,082 | 2.5% |  |
| ䷎䷏ #15/#16 | 886,432 | 1.7% |  |
| ䷴䷵ #53/#54 | 435,124 | 0.8% |  |
| ䷆䷇ #7/#8 | 431,474 | 0.8% |  |
| ䷄䷅ #5/#6 | 392,425 | 0.7% |  |
| ䷂䷃ #3/#4 | 384,788 | 0.7% | **King Wen's choice** |
| ䷾䷿ #63/#64 | 310,641 | 0.6% |  |
| ䷒䷓ #19/#20 | 0 | — | Estimated dead |
| ䷔䷕ #21/#22 | 0 | — | Estimated dead |
| ䷖䷗ #23/#24 | 0 | — | Estimated dead |
| ䷘䷙ #25/#26 | 0 | — | Estimated dead |
| ䷞䷟ #31/#32 | 0 | — | Estimated dead |
| ䷤䷥ #37/#38 | 0 | — | Estimated dead |
| ䷦䷧ #39/#40 | 0 | — | Estimated dead |
| ䷨䷩ #41/#42 | 0 | — | Estimated dead |
| ䷲䷳ #51/#52 | 0 | — | Estimated dead |
| ䷶䷷ #55/#56 | 0 | — | Estimated dead |
| ䷸䷹ #57/#58 | 0 | — | Estimated dead |
| ䷺䷻ #59/#60 | 0 | — | Estimated dead |

*Counts are lower bounds from the pre-bugfix 10T run (which undercounted by ~23x due to the*
*sub-branch filename collision bug). The relative ordering and dead-branch classification*
*are believed correct, but absolute counts should be scaled by ~23x for the 742M dataset.*
*"Estimated dead" means zero valid orderings were found — not proven exhaustively.*

**Key insight:** Nearly half the possible position-2 choices lead to dead branches —
no valid orderings exist (or at least none have been found). The viable choices vary
enormously in how many valid orderings they produce, from hundreds of thousands to
millions. The [complement distance constraint](../documentation/SOLVE_SUMMARY.md#rule-3)
interacts very differently with different position-2 pairs.

## What remains unknown

- **The total count of valid orderings.** At the 10T node budget the canonical counts are
  **706,427,594** at d3 (sha `b85c8871…`) and **286,357,503** at d2. These are lower bounds at
  a fixed budget: every sub-branch hits its per-sub-branch node budget rather than completing
  naturally. An unbiased Monte-Carlo estimate now puts the total number of C1–C5-satisfying
  orderings at **≈10³⁸** (≈3×10³⁷ distinct-canonical) — see
  [`../documentation/SEARCH_SPACE_SIZE.md`](../documentation/SEARCH_SPACE_SIZE.md); no canonical
  scale is exhaustive.
- **Whether the 4-boundary uniqueness result holds at larger scale, and which specific
  boundaries.** Four boundary constraints are the empirical minimum at both d2 and d3 —
  all 4,495 three-subsets fail at each. **What is partition-stable**: boundaries **{25, 27}**
  are mandatory in every working 4-set at both scales. **What is partition-dependent**: the
  other 2 boundaries.
  - d2 has **4** working 4-sets: `{2,21,25,27}`, `{2,22,25,27}`, `{3,21,25,27}`, `{3,22,25,27}` — structure `{25,27} ∪ one-of-{2,3} ∪ one-of-{21,22}`.
  - d3 has **8** working 4-sets, all containing {25, 27} and two of `{1,2,3,4,5,6}` (not
    {21, 22}).
  - **Implication**: the broader "one-of-{2,3} ∪ one-of-{21,22}" phrasing is d2-specific.
    Only {25, 27} mandatory status is stable across partition depths.
- **Whether the "estimated dead" branches are truly dead.** They produced zero valid
  orderings in partial exploration, but exhaustive proof requires completing them. Four branches
  previously classified as dead were reclassified as live in the 10T run.
- **The structure of the cascade and back-half regions.** The earlier framing that "position 2
  determines positions 3-19" was overstated — based on the bug-undercounted 31.6M dataset and an
  analysis ([`--prove-cascade`](../documentation/SOLVE_C_CLI.md#--prove-cascade)) that operated within a shift-pattern subspace containing only 2.93%
  of the corrected 742M valid orderings. Per-position Shannon entropy on 742M shows the cascade
  region (positions 4-20) carries 0.28-1.72 bits each — heavily constrained but not deterministic;
  every reachable first-level branch admits 2-29 distinct pair sequences across positions 3-19.
  Positions 22-31 carry 3.45-3.65 bits each. What patterns govern King Wen's specific choices
  across the full 32 positions remains open.

---

# Part 2: Enumeration progress

This section tracks the computational search. For context on what the search is
doing and why, see [How the search works](#how-the-search-works) below.

## How the search works

The solver (`solve.c`) uses [backtracking search](https://en.wikipedia.org/wiki/Backtracking)
with constraint pruning. It tries placing hexagram pairs at each of 32 positions, checking
the [5 mathematical constraints](../documentation/SPECIFICATION.md#constraints) as it goes. Most paths are
eliminated early ("pruned"), but the tree is still enormous — trillions of states to explore.

The search tree splits into 56 **branches** (which pair at position 2) and ~54 **sub-branches**
each (which pair at position 3), totaling ≈3,030 sub-branches (the d2 canonical decomposition has exactly 3,030). A sub-branch is **complete**
when every path in it has been explored. Completion means the solution count for that
sub-branch is exact, not a lower bound.

The search runs on cloud servers and can be interrupted and resumed. Completed sub-branches
are [checkpointed](https://en.wikipedia.org/wiki/Application_checkpointing) so their work
is never lost.

## Terminology

| Term | Meaning |
|------|---------|
| **Valid ordering** | An arrangement of all 64 hexagrams satisfying constraints [C1-C5](../documentation/SPECIFICATION.md#constraints) |
| **C3-valid solution** | A complete sequence passing all 5 constraints. "C3-valid" because C3 ([complement distance](../documentation/SOLVE_SUMMARY.md#rule-3)) is the last constraint checked. Multiple C3-valid solutions can represent the same valid ordering (different within-pair orientations) |
| **Stored** | Unique valid orderings saved to the hash table (orientation collapsed) |
| **Nodes** | Individual states explored by the search algorithm |
| **Estimated dead** | Produced zero valid orderings in partial exploration. Likely dead, but not proven until fully explored |
| **Partial** | Explored but not completed — solution count is a lower bound |
| **Overflow** | Hash table reached capacity — some valid orderings may have been lost |
| **Complete** | Fully explored — solution count is exact |

## Status

> **Note:** the 10T figures in this table are the **2026-04-18 run** (`f7b8c4fb…`), which the branch/sub-branch breakdowns below derive from. The current **active** d3 10T canonical is `b85c8871…` / **706,427,594** (a 2026-05-13 modern-code re-derivation, +4,607 records vs the 2026-04-18 undercount) — see [`../documentation/CANONICAL_HASHES.md`](../documentation/CANONICAL_HASHES.md).

| Metric | d3 10T canonical (2026-04-18) | d2 10T canonical (2026-04-18) |
|--------|---|---|
| Sub-branches enumerated | 158,364 / 158,364 (all BUDGETED) | 3,030 / 3,030 (all BUDGETED) |
| **Valid orderings found** | **706,422,987** | **286,357,503** |
| sha256 of solutions.bin | `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` | `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2` |
| King Wen present | yes | yes |
| sub_*.bin files produced | 56,404 | 1,344 |
| Format | v1 (32-byte header + 32-byte records) | v1 |
| Cross-validation | Phase B external = Phase C fresh = heap-sort merge (byte-identical) | Phase D + heap-sort merge (byte-identical) |

Older figures (742M hash-table-bug, 31.6M filename-collision-bug) superseded. See [HISTORY.md](../documentation/HISTORY.md) for full forensic history.

**Branch-level table below is from an earlier enumeration era and uses `sub_P2_O2.bin` keying (d2). Per-branch counts are approximate; canonical shard counts differ slightly. Pending refresh at d3 partition.**

## Branch table

| Pair | Or | Position 2 | Nodes (B) | C3-valid | Stored | Status |
|-----:|:--:|------------|----------:|---------:|-------:|:------:|
| [1](#branch-1-0) | 0 | ䷂䷃ #3/#4 **(KW)** | 178.6 | 18.0M | 189,134 | Partial |
| [1](#branch-1-1) | 1 | ䷃䷂ #4/#3 | 178.6 | 8.8M | 195,654 | Partial |
| [2](#branch-2-0) | 0 | ䷄䷅ #5/#6 | 178.6 | 15.6M | 194,687 | Partial |
| [2](#branch-2-1) | 1 | ䷅䷄ #6/#5 | 178.6 | 16.7M | 197,738 | Partial |
| [3](#branch-3-0) | 0 | ䷆䷇ #7/#8 | 178.6 | 26.9M | 197,814 | Partial |
| [3](#branch-3-1) | 1 | ䷇䷆ #8/#7 | 178.6 | 29.6M | 233,660 | Partial |
| [5](#branch-5-0) | 0 | ䷊䷋ #11/#12 | 178.6 | 177.9M | 1,659,462 | Partial |
| [5](#branch-5-1) | 1 | ䷋䷊ #12/#11 | 178.6 | 177.9M | 1,659,462 | Partial |
| [7](#branch-7-0) | 0 | ䷎䷏ #15/#16 | 178.6 | 60.5M | 443,216 | Partial |
| [7](#branch-7-1) | 1 | ䷏䷎ #16/#15 | 178.6 | 60.5M | 443,216 | Partial |
| [8](#branch-8-0) | 0 | ䷐䷑ #17/#18 | 178.6 | 87.6M | 670,407 | Partial |
| [8](#branch-8-1) | 1 | ䷑䷐ #18/#17 | 178.6 | 92.8M | 681,675 | Partial |
| [9](#branch-9-0) | 0 | ䷒䷓ #19/#20 | 178.6 | — | — | Est. dead |
| [9](#branch-9-1) | 1 | ䷓䷒ #20/#19 | 178.6 | — | — | Est. dead |
| [10](#branch-10-0) | 0 | ䷔䷕ #21/#22 | 178.6 | — | — | Est. dead |
| [10](#branch-10-1) | 1 | ䷕䷔ #22/#21 | 178.6 | — | — | Est. dead |
| [11](#branch-11-0) | 0 | ䷖䷗ #23/#24 | 178.6 | — | — | Est. dead |
| [11](#branch-11-1) | 1 | ䷗䷖ #24/#23 | 178.6 | — | — | Est. dead |
| [12](#branch-12-0) | 0 | ䷘䷙ #25/#26 | 178.6 | — | — | Est. dead |
| [12](#branch-12-1) | 1 | ䷙䷘ #26/#25 | 178.6 | — | — | Est. dead |
| [13](#branch-13-0) | 0 | ䷚䷛ #27/#28 | 178.6 | 100.0M | 2,239,707 | Partial |
| [13](#branch-13-1) | 1 | ䷛䷚ #28/#27 | 178.6 | 100.0M | 2,239,707 | Partial |
| [14](#branch-14-0) | 0 | ䷜䷝ #29/#30 | 178.6 | 222.2M | 2,225,037 | Partial |
| [14](#branch-14-1) | 1 | ䷝䷜ #30/#29 | 178.6 | 222.2M | 2,225,037 | Partial |
| [15](#branch-15-0) | 0 | ䷞䷟ #31/#32 | 178.6 | — | — | Est. dead |
| [15](#branch-15-1) | 1 | ䷟䷞ #32/#31 | 178.6 | — | — | Est. dead |
| [16](#branch-16-0) | 0 | ䷠䷡ #33/#34 | 178.6 | 113.3M | 1,194,709 | Partial |
| [16](#branch-16-1) | 1 | ䷡䷠ #34/#33 | 178.6 | 113.3M | 1,194,709 | Partial |
| [17](#branch-17-0) | 0 | ䷢䷣ #35/#36 | 178.6 | 2593.2M | 4,194,304 | Overflow |
| [17](#branch-17-1) | 1 | ䷣䷢ #36/#35 | 178.6 | 2595.0M | 4,194,304 | Overflow |
| [18](#branch-18-0) | 0 | ䷤䷥ #37/#38 | 178.6 | — | — | Est. dead |
| [18](#branch-18-1) | 1 | ䷥䷤ #38/#37 | 178.6 | — | — | Est. dead |
| [19](#branch-19-0) | 0 | ䷦䷧ #39/#40 | 178.6 | — | — | Est. dead |
| [19](#branch-19-1) | 1 | ䷧䷦ #40/#39 | 178.6 | — | — | Est. dead |
| [20](#branch-20-0) | 0 | ䷨䷩ #41/#42 | 178.6 | — | — | Est. dead |
| [20](#branch-20-1) | 1 | ䷩䷨ #42/#41 | 178.6 | — | — | Est. dead |
| [22](#branch-22-0) | 0 | ䷬䷭ #45/#46 | 178.6 | 270.5M | 3,733,761 | Partial |
| [22](#branch-22-1) | 1 | ䷭䷬ #46/#45 | 178.6 | 279.2M | 3,663,111 | Partial |
| [23](#branch-23-0) | 0 | ䷮䷯ #47/#48 | 178.6 | 140.0M | 1,248,692 | Partial |
| [23](#branch-23-1) | 1 | ䷯䷮ #48/#47 | 178.6 | 140.0M | 1,248,692 | Partial |
| [24](#branch-24-0) | 0 | ䷰䷱ #49/#50 | 170.2 | 7172.2M | 4,194,304 | Overflow |
| [24](#branch-24-1) | 1 | ䷱䷰ #50/#49 | 178.6 | 4220.5M | 4,194,304 | Overflow |
| [25](#branch-25-0) | 0 | ䷲䷳ #51/#52 | 178.6 | — | — | Est. dead |
| [25](#branch-25-1) | 1 | ䷳䷲ #52/#51 | 178.6 | — | — | Est. dead |
| [26](#branch-26-0) | 0 | ䷴䷵ #53/#54 | 178.6 | 20.5M | 217,562 | Partial |
| [26](#branch-26-1) | 1 | ䷵䷴ #54/#53 | 178.6 | 20.5M | 217,562 | Partial |
| [27](#branch-27-0) | 0 | ䷶䷷ #55/#56 | 178.6 | — | — | Est. dead |
| [27](#branch-27-1) | 1 | ䷷䷶ #56/#55 | 178.6 | — | — | Est. dead |
| [28](#branch-28-0) | 0 | ䷸䷹ #57/#58 | 178.6 | — | — | Est. dead |
| [28](#branch-28-1) | 1 | ䷹䷸ #58/#57 | 178.6 | — | — | Est. dead |
| [29](#branch-29-0) | 0 | ䷺䷻ #59/#60 | 178.6 | — | — | Est. dead |
| [29](#branch-29-1) | 1 | ䷻䷺ #60/#59 | 178.6 | — | — | Est. dead |
| [30](#branch-30-0) | 0 | ䷼䷽ #61/#62 | 178.6 | 150.6M | 4,149,791 | Partial |
| [30](#branch-30-1) | 1 | ䷽䷼ #62/#61 | 178.6 | 272.5M | 3,408,244 | Partial |
| [31](#branch-31-0) | 0 | ䷾䷿ #63/#64 | 178.6 | 14.1M | 155,326 | Partial |
| [31](#branch-31-1) | 1 | ䷿䷾ #64/#63 | 178.6 | 13.2M | 155,315 | Partial |

## Branch details

<a id="branch-1-0"></a>
### ䷂䷃ #3 Difficulty at the Beginning / #4 Youthful Folly — King Wen's branch

**Pair 1, orient 0** — Partial — at least 189,134 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,312 | 17,987,320 | 189,134 | 0/54 |

This is the subtree containing the actual historical King Wen sequence.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-1-1"></a>
### ䷃䷂ #4 Youthful Folly / #3 Difficulty at the Beginning

**Pair 1, orient 1** — Partial — at least 195,654 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,289 | 8,814,844 | 195,654 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-2-0"></a>
### ䷄䷅ #5 Waiting / #6 Conflict

**Pair 2, orient 0** — Partial — at least 194,687 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,295 | 15,620,712 | 194,687 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-2-1"></a>
### ䷅䷄ #6 Conflict / #5 Waiting

**Pair 2, orient 1** — Partial — at least 197,738 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,302 | 16,662,216 | 197,738 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-3-0"></a>
### ䷆䷇ #7 The Army / #8 Holding Together

**Pair 3, orient 0** — Partial — at least 197,814 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,220 | 26,897,920 | 197,814 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-3-1"></a>
### ䷇䷆ #8 Holding Together / #7 The Army

**Pair 3, orient 1** — Partial — at least 233,660 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,317 | 29,621,664 | 233,660 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-5-0"></a>
### ䷊䷋ #11 Peace / #12 Standstill

**Pair 5, orient 0** — Partial — at least 1,659,462 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,326 | 177,909,348 | 1,659,462 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-5-1"></a>
### ䷋䷊ #12 Standstill / #11 Peace

**Pair 5, orient 1** — Partial — at least 1,659,462 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,326 | 177,909,348 | 1,659,462 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-7-0"></a>
### ䷎䷏ #15 Modesty / #16 Enthusiasm

**Pair 7, orient 0** — Partial — at least 443,216 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,306 | 60,474,416 | 443,216 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-7-1"></a>
### ䷏䷎ #16 Enthusiasm / #15 Modesty

**Pair 7, orient 1** — Partial — at least 443,216 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,306 | 60,474,416 | 443,216 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-8-0"></a>
### ䷐䷑ #17 Following / #18 Work on What Has Been Spoiled

**Pair 8, orient 0** — Partial — at least 670,407 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,317 | 87,637,552 | 670,407 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-8-1"></a>
### ䷑䷐ #18 Work on What Has Been Spoiled / #17 Following

**Pair 8, orient 1** — Partial — at least 681,675 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,306 | 92,811,968 | 681,675 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-9-0"></a>
### ䷒䷓ #19 Approach / #20 Contemplation

**Pair 9, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,300 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-9-1"></a>
### ䷓䷒ #20 Contemplation / #19 Approach

**Pair 9, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,300 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-10-0"></a>
### ䷔䷕ #21 Biting Through / #22 Grace

**Pair 10, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,306 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-10-1"></a>
### ䷕䷔ #22 Grace / #21 Biting Through

**Pair 10, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,306 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-11-0"></a>
### ䷖䷗ #23 Splitting Apart / #24 Return

**Pair 11, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,228 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-11-1"></a>
### ䷗䷖ #24 Return / #23 Splitting Apart

**Pair 11, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,306 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-12-0"></a>
### ䷘䷙ #25 Innocence / #26 The Taming Power of the Great

**Pair 12, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,292 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-12-1"></a>
### ䷙䷘ #26 The Taming Power of the Great / #25 Innocence

**Pair 12, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,295 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-13-0"></a>
### ䷚䷛ #27 Corners of the Mouth / #28 Preponderance of the Great

**Pair 13, orient 0** — Partial — at least 2,239,707 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,291 | 99,951,452 | 2,239,707 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-13-1"></a>
### ䷛䷚ #28 Preponderance of the Great / #27 Corners of the Mouth

**Pair 13, orient 1** — Partial — at least 2,239,707 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,291 | 99,951,452 | 2,239,707 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-14-0"></a>
### ䷜䷝ #29 The Abysmal / #30 The Clinging

**Pair 14, orient 0** — Partial — at least 2,225,037 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,296 | 222,231,696 | 2,225,037 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-14-1"></a>
### ䷝䷜ #30 The Clinging / #29 The Abysmal

**Pair 14, orient 1** — Partial — at least 2,225,037 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,296 | 222,231,696 | 2,225,037 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-15-0"></a>
### ䷞䷟ #31 Influence / #32 Duration

**Pair 15, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,288 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-15-1"></a>
### ䷟䷞ #32 Duration / #31 Influence

**Pair 15, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,311 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-16-0"></a>
### ䷠䷡ #33 Retreat / #34 The Power of the Great

**Pair 16, orient 0** — Partial — at least 1,194,709 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,305 | 113,304,168 | 1,194,709 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-16-1"></a>
### ䷡䷠ #34 The Power of the Great / #33 Retreat

**Pair 16, orient 1** — Partial — at least 1,194,709 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,305 | 113,304,168 | 1,194,709 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-17-0"></a>
### ䷢䷣ #35 Progress / #36 Darkening of the Light

**Pair 17, orient 0** — Overflow — hash table full. At least 4,194,304 unique orderings; true count higher.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,312 | 2,593,230,172 | 4,194,304 | 0/54 |

One of the densest branches — 1.45% of explored nodes produced valid solutions.
Needs `SOLVE_HASH_LOG2=24` for complete enumeration.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-17-1"></a>
### ䷣䷢ #36 Darkening of the Light / #35 Progress

**Pair 17, orient 1** — Overflow — hash table full. At least 4,194,304 unique orderings; true count higher.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,305 | 2,595,024,760 | 4,194,304 | 0/54 |

One of the densest branches — 1.45% of explored nodes produced valid solutions.
Needs `SOLVE_HASH_LOG2=24` for complete enumeration.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-18-0"></a>
### ䷤䷥ #37 The Family / #38 Opposition

**Pair 18, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,293 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-18-1"></a>
### ䷥䷤ #38 Opposition / #37 The Family

**Pair 18, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,291 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-19-0"></a>
### ䷦䷧ #39 Obstruction / #40 Deliverance

**Pair 19, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,306 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-19-1"></a>
### ䷧䷦ #40 Deliverance / #39 Obstruction

**Pair 19, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,321 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-20-0"></a>
### ䷨䷩ #41 Decrease / #42 Increase

**Pair 20, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,316 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-20-1"></a>
### ䷩䷨ #42 Increase / #41 Decrease

**Pair 20, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,299 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-22-0"></a>
### ䷬䷭ #45 Gathering Together / #46 Pushing Upward

**Pair 22, orient 0** — Partial — at least 3,733,761 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,315 | 270,471,092 | 3,733,761 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-22-1"></a>
### ䷭䷬ #46 Pushing Upward / #45 Gathering Together

**Pair 22, orient 1** — Partial — at least 3,663,111 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,293 | 279,166,948 | 3,663,111 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-23-0"></a>
### ䷮䷯ #47 Oppression / #48 The Well

**Pair 23, orient 0** — Partial — at least 1,248,692 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,321 | 139,999,392 | 1,248,692 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-23-1"></a>
### ䷯䷮ #48 The Well / #47 Oppression

**Pair 23, orient 1** — Partial — at least 1,248,692 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,321 | 139,999,392 | 1,248,692 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-24-0"></a>
### ䷰䷱ #49 Revolution / #50 The Cauldron

**Pair 24, orient 0** — Overflow — hash table full. At least 4,194,304 unique orderings; true count higher.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 170,180,026,818 | 7,172,236,093 | 4,194,304 | 0/54 |

One of the densest branches — 4.21% of explored nodes produced valid solutions.
Needs `SOLVE_HASH_LOG2=24` for complete enumeration.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-24-1"></a>
### ䷱䷰ #50 The Cauldron / #49 Revolution

**Pair 24, orient 1** — Overflow — hash table full. At least 4,194,304 unique orderings; true count higher.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,308 | 4,220,486,108 | 4,194,304 | 0/54 |

One of the densest branches — 2.36% of explored nodes produced valid solutions.
Needs `SOLVE_HASH_LOG2=24` for complete enumeration.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-25-0"></a>
### ䷲䷳ #51 The Arousing / #52 Keeping Still

**Pair 25, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,272 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-25-1"></a>
### ䷳䷲ #52 Keeping Still / #51 The Arousing

**Pair 25, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,309 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-26-0"></a>
### ䷴䷵ #53 Development / #54 The Marrying Maiden

**Pair 26, orient 0** — Partial — at least 217,562 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,299 | 20,504,652 | 217,562 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-26-1"></a>
### ䷵䷴ #54 The Marrying Maiden / #53 Development

**Pair 26, orient 1** — Partial — at least 217,562 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,299 | 20,504,652 | 217,562 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-27-0"></a>
### ䷶䷷ #55 Abundance / #56 The Wanderer

**Pair 27, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,321 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-27-1"></a>
### ䷷䷶ #56 The Wanderer / #55 Abundance

**Pair 27, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,303 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-28-0"></a>
### ䷸䷹ #57 The Gentle / #58 The Joyous

**Pair 28, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,308 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-28-1"></a>
### ䷹䷸ #58 The Joyous / #57 The Gentle

**Pair 28, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,312 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-29-0"></a>
### ䷺䷻ #59 Dispersion / #60 Limitation

**Pair 29, orient 0** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,309 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-29-1"></a>
### ䷻䷺ #60 Limitation / #59 Dispersion

**Pair 29, orient 1** — Estimated dead — no valid orderings found in partial exploration. Not proven.

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,314 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-30-0"></a>
### ䷼䷽ #61 Inner Truth / #62 Preponderance of the Small

**Pair 30, orient 0** — Partial — at least 4,149,791 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,287 | 150,566,788 | 4,149,791 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-30-1"></a>
### ䷽䷼ #62 Preponderance of the Small / #61 Inner Truth

**Pair 30, orient 1** — Partial — at least 3,408,244 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,317 | 272,454,548 | 3,408,244 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-31-0"></a>
### ䷾䷿ #63 After Completion / #64 Before Completion

**Pair 31, orient 0** — Partial — at least 155,326 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,320 | 14,057,560 | 155,326 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-31-1"></a>
### ䷿䷾ #64 Before Completion / #63 After Completion

**Pair 31, orient 1** — Partial — at least 155,315 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 178,571,429,288 | 13,185,752 | 155,315 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

## Running the solver

```bash
gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz    # Compile (-lz: #169 native gzip; -lm: math)
./solve --list-branches              # Show all branches
SOLVE_THREADS=64 ./solve --branch 24 0 0  # Run one branch
./solve --merge                       # Combine sub-branch results
./solve --validate solutions_merged.bin  # Verify all constraints
```

See [solve.c](../solve.c) source for full documentation.

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) §d3 100T.*
