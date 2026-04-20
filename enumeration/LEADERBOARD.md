# Enumeration Leaderboard

> **Note (2026-04-20):** Canonical reference figures have been re-established with the corrected solver (format v1). Authoritative counts:
>
> - **d3 100T partition: 3,432,399,297 canonical orderings** (sha `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5`, 102.3 GB) — **NEW 2026-04-19/20**, deepest partial enumeration to date.
> - **d3 10T partition: 706,422,987 canonical orderings** (sha `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e`)
> - **d2 10T partition: 286,357,503 canonical orderings** (sha `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2`)
>
> All three validated. Older figures (742M hash-bug, 31.6M filename-collision bug) appear only as historical context. The difference between d2 and d3 counts is a partition-strategy effect, not a constraint difference. The 100T : 10T ratio of 4.86× reflects diminishing returns in the search tree (linear node budget yields sublinear new-orderings).
>
> **Novel finding from 100T `--c3-min` analysis (2026-04-20):** KW is **not** the C3-minimum under C1+C2+C3. Minimum complement distance = **424** (221 records); KW sits at C3 = 776 (ceiling of the constraint). The simple axiom "minimize C3" does not derive KW — this is a negative result for Open Question #7 Phase A.
>
> **Second novel finding from 100T `--analyze` (2026-04-20):** the **boundary-minimum increases from 4 to 5** at deeper enumeration. At d2 10T and d3 10T, 4-boundary subsets uniquely identify KW. At d3 100T (the new canonical), **NO 4-subset works** — the deeper enumeration surfaces orderings that are 4-subset-indistinguishable from KW. Greedy-optimal 5-set: **{1, 4, 21, 25, 27}**. Boundaries {25, 27} remain mandatory across all three partitions (d2 10T, d3 10T, d3 100T) — the partition-stability claim holds. This is a MAJOR revision to the 4-boundary narrative and suggests the true boundary-minimum may continue to increase at yet-deeper enumeration (1000T+). See SOLVE.md §Boundary analysis for the updated text and `solve_c/runs/20260419_100T_d3_d128westus3/analyze_output.log.gz` for the raw data.

## What this is

About 3,000 years ago, someone in ancient China arranged 64 symbols called
[hexagrams](https://en.wikipedia.org/wiki/Hexagram_(I_Ching)) in a specific order —
the [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence).
There are more possible arrangements than atoms in the universe (about 10^89).
But King Wen follows mathematical rules so strict that only a fraction of
arrangements satisfy them all. This project is cataloging every valid arrangement
to understand what makes the historical one special — or whether it is simply
one choice among many.

For the rules themselves, see [SOLVE-SUMMARY.md](../SOLVE-SUMMARY.md).
For formal definitions, see [SPECIFICATION.md](../SPECIFICATION.md).

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
*current canonical d3 10T (706M) or d2 10T (286M) datasets. For up-to-date per-position*
*entropies see the `--analyze` output archived at `solve_c/runs/20260418_10T_d3_fresh/`*
*and `20260418_10T_d2_fresh/` or the `D2_D3_ANALYZE_FINDINGS.md` summary (outside the*
*git repo). The gradient shape (pos 1 locked; pos 3-19 constrained; pos 22-31 free) holds*
*across all three datasets; specific numbers shift with partition depth. Max possible*
*entropy = log2(32) = 5.0 bits.*

**Key insight:** The sequence is not uniformly constrained. Position 1 is fully
determined. Position 2 is a major branching point (16 options). Positions 3-18 are
highly constrained (per-position Shannon entropy 0.28-1.72 bits vs a maximum of 5.0),
though not fully locked — each branch admits 2-29 distinct configurations across
positions 3-19. Positions 19-32 open up dramatically — up to 16 pairs are possible,
and King Wen's choice is one among many. The ancient designers had limited freedom
in the first half but considerable choice in the second half.

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
millions. The [complement distance constraint](../SOLVE-SUMMARY.md#rule-3-opposites-kept-unusually-close)
interacts very differently with different position-2 pairs.

## What remains unknown

- **The total count of valid orderings.** At the 10T node budget: **706,422,987** at d3
  partition and **286,357,503** at d2 partition (canonical, 2026-04-18). The true count
  under exhaustive enumeration is unknown and likely larger — every sub-branch hits its
  per-sub-branch node budget rather than completing naturally.
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
  analysis (`--prove-cascade`) that operated within a shift-pattern subspace containing only 2.93%
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
the [5 mathematical constraints](../SPECIFICATION.md#constraints) as it goes. Most paths are
eliminated early ("pruned"), but the tree is still enormous — trillions of states to explore.

The search tree splits into 56 **branches** (which pair at position 2) and ~54 **sub-branches**
each (which pair at position 3), totaling ~3,024 sub-branches. A sub-branch is **complete**
when every path in it has been explored. Completion means the solution count for that
sub-branch is exact, not a lower bound.

The search runs on cloud servers and can be interrupted and resumed. Completed sub-branches
are [checkpointed](https://en.wikipedia.org/wiki/Application_checkpointing) so their work
is never lost.

## Terminology

| Term | Meaning |
|------|---------|
| **Valid ordering** | An arrangement of all 64 hexagrams satisfying constraints [C1-C5](../SPECIFICATION.md#constraints) |
| **C3-valid solution** | A complete sequence passing all 5 constraints. "C3-valid" because C3 ([complement distance](../SOLVE-SUMMARY.md#rule-3-opposites-kept-unusually-close)) is the last constraint checked. Multiple C3-valid solutions can represent the same valid ordering (different within-pair orientations) |
| **Stored** | Unique valid orderings saved to the hash table (orientation collapsed) |
| **Nodes** | Individual states explored by the search algorithm |
| **Estimated dead** | Produced zero valid orderings in partial exploration. Likely dead, but not proven until fully explored |
| **Partial** | Explored but not completed — solution count is a lower bound |
| **Overflow** | Hash table reached capacity — some valid orderings may have been lost |
| **Complete** | Fully explored — solution count is exact |

## Status

| Metric | d3 10T canonical (2026-04-18) | d2 10T canonical (2026-04-18) |
|--------|---|---|
| Sub-branches enumerated | 158,364 / 158,364 (all BUDGETED) | 3,030 / 3,030 (all BUDGETED) |
| **Valid orderings found** | **706,422,987** | **286,357,503** |
| sha256 of solutions.bin | `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` | `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2` |
| King Wen present | yes | yes |
| sub_*.bin files produced | 56,404 | 1,344 |
| Format | v1 (32-byte header + 32-byte records) | v1 |
| Cross-validation | Phase B external = Phase C fresh = heap-sort merge (byte-identical) | Phase D + heap-sort merge (byte-identical) |

Older figures (742M hash-table-bug, 31.6M filename-collision-bug) superseded. See [HISTORY.md](../HISTORY.md) for full forensic history.

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
gcc -O3 -pthread -o solve solve.c    # Compile
./solve --list-branches              # Show all branches
SOLVE_THREADS=64 ./solve --branch 24 0 0  # Run one branch
./solve --merge                       # Combine sub-branch results
./solve --validate solutions_merged.bin  # Verify all constraints
```

See [solve.c](../solve.c) source for full documentation.
