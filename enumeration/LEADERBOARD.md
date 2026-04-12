# Enumeration Leaderboard

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

| Position | King Wen pair | KW match % | Pairs observed | Character |
|:--------:|---------------|:----------:|:--------------:|-----------|
| 1 | ䷀䷁ #1 / #2 | 100.0% | at least 1 | Fully determined |
| 2 | ䷂䷃ #3 / #4 | 0.2% | at least 16 | Branch-dependent (varies widely) |
| 3 | ䷄䷅ #5 / #6 | 0.2% | at least 2 | Highly constrained (2 options) |
| 4 | ䷆䷇ #7 / #8 | 0.5% | at least 2 | Highly constrained (2 options) |
| 5 | ䷈䷉ #9 / #10 | 0.9% | at least 2 | Highly constrained (2 options) |
| 6 | ䷊䷋ #11 / #12 | 0.9% | at least 2 | Highly constrained (2 options) |
| 7 | ䷌䷍ #13 / #14 | 3.4% | at least 2 | Highly constrained (2 options) |
| 8 | ䷎䷏ #15 / #16 | 3.4% | at least 2 | Highly constrained (2 options) |
| 9 | ䷐䷑ #17 / #18 | 4.1% | at least 2 | Highly constrained (2 options) |
| 10 | ䷒䷓ #19 / #20 | 5.2% | at least 2 | Highly constrained (2 options) |
| 11 | ䷔䷕ #21 / #22 | 5.2% | at least 2 | Highly constrained (2 options) |
| 12 | ䷖䷗ #23 / #24 | 5.2% | at least 2 | Highly constrained (2 options) |
| 13 | ䷘䷙ #25 / #26 | 5.2% | at least 2 | Highly constrained (2 options) |
| 14 | ䷚䷛ #27 / #28 | 5.2% | at least 2 | Highly constrained (2 options) |
| 15 | ䷜䷝ #29 / #30 | 7.3% | at least 2 | Highly constrained (2 options) |
| 16 | ䷞䷟ #31 / #32 | 11.2% | at least 2 | Highly constrained (2 options) |
| 17 | ䷠䷡ #33 / #34 | 11.2% | at least 2 | Highly constrained (2 options) |
| 18 | ䷢䷣ #35 / #36 | 12.9% | at least 2 | Highly constrained (2 options) |
| 19 | ䷤䷥ #37 / #38 | 49.4% | at least 2 | Highly constrained (2 options) |
| 20 | ䷦䷧ #39 / #40 | 51.8% | at least 4 | Moderately constrained |
| 21 | ䷨䷩ #41 / #42 | 16.4% | at least 14 | Progressively free |
| 22 | ䷪䷫ #43 / #44 | 11.0% | at least 14 | Progressively free |
| 23 | ䷬䷭ #45 / #46 | 12.5% | at least 14 | Progressively free |
| 24 | ䷮䷯ #47 / #48 | 10.7% | at least 14 | Progressively free |
| 25 | ䷰䷱ #49 / #50 | 5.7% | at least 14 | Progressively free |
| 26 | ䷲䷳ #51 / #52 | 9.4% | at least 14 | Progressively free |
| 27 | ䷴䷵ #53 / #54 | 7.7% | at least 14 | Progressively free |
| 28 | ䷶䷷ #55 / #56 | 8.9% | at least 14 | Progressively free |
| 29 | ䷸䷹ #57 / #58 | 11.3% | at least 14 | Progressively free |
| 30 | ䷺䷻ #59 / #60 | 9.6% | at least 14 | Progressively free |
| 31 | ䷼䷽ #61 / #62 | 18.4% | at least 14 | Progressively free |
| 32 | ䷾䷿ #63 / #64 | 21.3% | at least 7 | Progressively free |

*KW match % = how often King Wen's pair appears at this position across ALL valid*
*orderings (all branches combined). The low percentages at positions 3-18 are because*
*those positions depend on position 2: within any single branch, positions 3-18 are*
*nearly locked (87-99% match), but across all 56 branches the average is diluted.*
*"At least N" because the enumeration is incomplete.*

**Key insight:** The sequence is not uniformly constrained. Position 1 is fully
determined. Position 2 is a major branching point (16 options). Within each branch,
positions 3-18 admit only 2 pairs each — the sequence is nearly determined here.
But positions 19-32 open up dramatically — up to 16 pairs are possible, and King
Wen's choice is one among many. The ancient designers had almost no freedom in the
first half but considerable choice in the second half.

## How close are the nearest alternatives?

The closest valid orderings differ from King Wen by just **2 pair positions** —
always in the last third of the sequence (positions 26-32). The top 20 nearest
alternatives all differ at exactly 2 positions. No valid ordering differs by just 1.

The edit distance distribution (number of pair positions differing from King Wen):

| Positions different | Count | Notes |
|:-------------------:|------:|-------|
| 0 | 48 | King Wen itself (orientation variants) |
| 1 | 0 | No valid ordering is 1 swap from KW |
| 2 | 732 | Closest alternatives — differ at positions 26-32 |
| 3 | 1,484 | |
| 4-10 | ~37,000 | |
| 11-20 | ~300,000,000 | Bulk of solutions |
| 21-31 | ~5,600,000,000 | Most solutions are very different from KW |

Most valid orderings look **nothing like** King Wen — the distribution peaks at
16 differences (half the sequence) with a secondary peak at 29. King Wen is not
"typical" among valid orderings; it sits at one extreme.

## Which pairs can appear at position 2?

Position 2 is the first "free" position — 16 different pairs can validly follow
Creative/Receptive. King Wen's choice (䷂䷃ #3 Difficulty / #4 Folly) appears in only
0.2% of valid orderings. Some choices at position 2 produce millions of downstream
valid orderings; others produce zero.

| Position 2 pair | Valid orderings found | Share | Notes |
|----------------|---------------------:|------:|-------|
| ䷢䷣ #35/#36 | 8,388,608 | 25.7% | Extremely dense |
| ䷰䷱ #49/#50 | 8,388,608 | 25.7% | Extremely dense |
| ䷚䷛ #27/#28 | 3,014,968 | 9.2% |  |
| ䷜䷝ #29/#30 | 2,450,722 | 7.5% |  |
| ䷬䷭ #45/#46 | 2,330,893 | 7.1% |  |
| ䷊䷋ #11/#12 | 1,952,993 | 6.0% |  |
| ䷼䷽ #61/#62 | 1,389,730 | 4.3% |  |
| ䷠䷡ #33/#34 | 1,289,602 | 4.0% |  |
| ䷮䷯ #47/#48 | 1,230,656 | 3.8% |  |
| ䷐䷑ #17/#18 | 696,959 | 2.1% |  |
| ䷎䷏ #15/#16 | 442,650 | 1.4% |  |
| ䷆䷇ #7/#8 | 244,371 | 0.7% |  |
| ䷄䷅ #5/#6 | 228,918 | 0.7% |  |
| ䷴䷵ #53/#54 | 220,610 | 0.7% |  |
| ䷂䷃ #3/#4 | 206,587 | 0.6% | **King Wen's choice** |
| ䷾䷿ #63/#64 | 155,499 | 0.5% |  |
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

*Counts are lower bounds from a partial enumeration. "Estimated dead" means zero valid*
*orderings were found in partial exploration — this has not been proven exhaustively.*

**Key insight:** Nearly half the possible position-2 choices lead to dead branches —
no valid orderings exist (or at least none have been found). The viable choices vary
enormously in how many valid orderings they produce, from hundreds of thousands to
millions. The [complement distance constraint](../SOLVE-SUMMARY.md#rule-3-opposites-kept-unusually-close)
interacts very differently with different position-2 pairs.

## What remains unknown

- **The total count of valid orderings.** At least 20 million have been found; the true count
  is unknown and likely significantly larger. No branch has been fully explored.
- **Whether King Wen is mathematically unique.** It may be the only ordering satisfying
  some undiscovered additional rule, or it may be one arbitrary choice among millions.
- **Whether the "estimated dead" branches are truly dead.** They produced zero valid
  orderings in partial exploration, but exhaustive proof requires completing them.
- **The structure of the free region (positions 19-32).** What patterns, if any, govern
  King Wen's choices in the unconstrained second half of the sequence?

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

| Metric | Value |
|--------|-------|
| Branches | 56/56 surveyed, 0/56 complete |
| Sub-branches | 0/~3,024 complete |
| Valid orderings found | at least 20,110,129 |
| Estimated dead branches | 24/56 |
| Live branches | 32/56 |
| Hash overflows | 4 branches |

## Branch table

| Pair | Or | Position 2 | Nodes (B) | C3-valid | Stored | Status |
|-----:|:--:|------------|----------:|---------:|-------:|:------:|
| [1](#branch-1-0) | 0 | ䷂䷃ #3/#4 **(KW)** | 86.2 | 7.1M | 94,890 | Partial |
| [1](#branch-1-1) | 1 | ䷃䷂ #4/#3 | 84.9 | 5.1M | 111,697 | Partial |
| [2](#branch-2-0) | 0 | ䷄䷅ #5/#6 | 85.7 | 8.5M | 111,675 | Partial |
| [2](#branch-2-1) | 1 | ䷅䷄ #6/#5 | 85.7 | 8.9M | 117,243 | Partial |
| [3](#branch-3-0) | 0 | ䷆䷇ #7/#8 | 89.7 | 14.1M | 131,034 | Partial |
| [3](#branch-3-1) | 1 | ䷇䷆ #8/#7 | 86.8 | 9.9M | 113,337 | Partial |
| [5](#branch-5-0) | 0 | ䷊䷋ #11/#12 | 86.3 | 74.1M | 977,895 | Partial |
| [5](#branch-5-1) | 1 | ䷋䷊ #12/#11 | 86.0 | 74.1M | 975,098 | Partial |
| [7](#branch-7-0) | 0 | ䷎䷏ #15/#16 | 86.7 | 21.6M | 221,325 | Partial |
| [7](#branch-7-1) | 1 | ䷏䷎ #16/#15 | 87.0 | 21.7M | 221,325 | Partial |
| [8](#branch-8-0) | 0 | ䷐䷑ #17/#18 | 86.4 | 32.4M | 345,016 | Partial |
| [8](#branch-8-1) | 1 | ䷑䷐ #18/#17 | 86.7 | 35.2M | 351,943 | Partial |
| [9](#branch-9-0) | 0 | ䷒䷓ #19/#20 | 79.7 | — | — | Est. dead |
| [9](#branch-9-1) | 1 | ䷓䷒ #20/#19 | 79.8 | — | — | Est. dead |
| [10](#branch-10-0) | 0 | ䷔䷕ #21/#22 | 87.1 | — | — | Est. dead |
| [10](#branch-10-1) | 1 | ䷕䷔ #22/#21 | 87.2 | — | — | Est. dead |
| [11](#branch-11-0) | 0 | ䷖䷗ #23/#24 | 90.5 | — | — | Est. dead |
| [11](#branch-11-1) | 1 | ䷗䷖ #24/#23 | 87.1 | — | — | Est. dead |
| [12](#branch-12-0) | 0 | ䷘䷙ #25/#26 | 84.3 | — | — | Est. dead |
| [12](#branch-12-1) | 1 | ䷙䷘ #26/#25 | 85.8 | — | — | Est. dead |
| [13](#branch-13-0) | 0 | ䷚䷛ #27/#28 | 83.8 | 62.0M | 1,507,484 | Partial |
| [13](#branch-13-1) | 1 | ䷛䷚ #28/#27 | 83.7 | 62.0M | 1,507,484 | Partial |
| [14](#branch-14-0) | 0 | ䷜䷝ #29/#30 | 84.2 | 114.8M | 1,225,361 | Partial |
| [14](#branch-14-1) | 1 | ䷝䷜ #30/#29 | 84.1 | 114.4M | 1,225,361 | Partial |
| [15](#branch-15-0) | 0 | ䷞䷟ #31/#32 | 84.9 | — | — | Est. dead |
| [15](#branch-15-1) | 1 | ䷟䷞ #32/#31 | 86.4 | — | — | Est. dead |
| [16](#branch-16-0) | 0 | ䷠䷡ #33/#34 | 85.4 | 51.6M | 644,801 | Partial |
| [16](#branch-16-1) | 1 | ䷡䷠ #34/#33 | 85.4 | 51.6M | 644,801 | Partial |
| [17](#branch-17-0) | 0 | ䷢䷣ #35/#36 | 60.7 | 1077.2M | 4,194,304 | Overflow |
| [17](#branch-17-1) | 1 | ䷣䷢ #36/#35 | 59.7 | 1101.9M | 4,194,304 | Overflow |
| [18](#branch-18-0) | 0 | ䷤䷥ #37/#38 | 84.0 | — | — | Est. dead |
| [18](#branch-18-1) | 1 | ䷥䷤ #38/#37 | 84.7 | — | — | Est. dead |
| [19](#branch-19-0) | 0 | ䷦䷧ #39/#40 | 84.4 | — | — | Est. dead |
| [19](#branch-19-1) | 1 | ䷧䷦ #40/#39 | 84.5 | — | — | Est. dead |
| [20](#branch-20-0) | 0 | ䷨䷩ #41/#42 | 88.9 | — | — | Est. dead |
| [20](#branch-20-1) | 1 | ䷩䷨ #42/#41 | 86.4 | — | — | Est. dead |
| [22](#branch-22-0) | 0 | ䷬䷭ #45/#46 | 80.2 | 64.7M | 1,226,303 | Partial |
| [22](#branch-22-1) | 1 | ䷭䷬ #46/#45 | 80.1 | 65.5M | 1,104,590 | Partial |
| [23](#branch-23-0) | 0 | ䷮䷯ #47/#48 | 86.0 | 68.1M | 615,328 | Partial |
| [23](#branch-23-1) | 1 | ䷯䷮ #48/#47 | 86.0 | 68.1M | 615,328 | Partial |
| [24](#branch-24-0) | 0 | ䷰䷱ #49/#50 | 45.9 | 1705.6M | 4,194,304 | Overflow |
| [24](#branch-24-1) | 1 | ䷱䷰ #50/#49 | 64.8 | 949.3M | 4,194,304 | Overflow |
| [25](#branch-25-0) | 0 | ䷲䷳ #51/#52 | 85.9 | — | — | Est. dead |
| [25](#branch-25-1) | 1 | ䷳䷲ #52/#51 | 85.9 | — | — | Est. dead |
| [26](#branch-26-0) | 0 | ䷴䷵ #53/#54 | 88.9 | 11.8M | 110,459 | Partial |
| [26](#branch-26-1) | 1 | ䷵䷴ #54/#53 | 88.7 | 11.7M | 110,151 | Partial |
| [27](#branch-27-0) | 0 | ䷶䷷ #55/#56 | 88.0 | — | — | Est. dead |
| [27](#branch-27-1) | 1 | ䷷䷶ #56/#55 | 88.6 | — | — | Est. dead |
| [28](#branch-28-0) | 0 | ䷸䷹ #57/#58 | 85.9 | — | — | Est. dead |
| [28](#branch-28-1) | 1 | ䷹䷸ #58/#57 | 85.3 | — | — | Est. dead |
| [29](#branch-29-0) | 0 | ䷺䷻ #59/#60 | 90.9 | — | — | Est. dead |
| [29](#branch-29-1) | 1 | ䷻䷺ #60/#59 | 88.8 | — | — | Est. dead |
| [30](#branch-30-0) | 0 | ䷼䷽ #61/#62 | 79.6 | 47.1M | 1,265,492 | Partial |
| [30](#branch-30-1) | 1 | ䷽䷼ #62/#61 | 81.2 | 9.0M | 124,238 | Partial |
| [31](#branch-31-0) | 0 | ䷾䷿ #63/#64 | 88.9 | 6.9M | 77,528 | Partial |
| [31](#branch-31-1) | 1 | ䷿䷾ #64/#63 | 89.4 | 6.8M | 77,971 | Partial |

## Branch details

<a id="branch-1-0"></a>
### ䷂䷃ #3 Difficulty at the Beginning / #4 Youthful Folly — King Wen's branch

**Pair 1, orient 0** — Partial — at least 94,890 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 86,244,869,323 | 7,082,024 | 94,890 | 0/54 |

This is the subtree containing the actual historical King Wen sequence.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-1-1"></a>
### ䷃䷂ #4 Youthful Folly / #3 Difficulty at the Beginning

**Pair 1, orient 1** — Partial — at least 111,697 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 84,885,549,546 | 5,055,884 | 111,697 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-2-0"></a>
### ䷄䷅ #5 Waiting / #6 Conflict

**Pair 2, orient 0** — Partial — at least 111,675 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 85,723,951,614 | 8,511,700 | 111,675 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-2-1"></a>
### ䷅䷄ #6 Conflict / #5 Waiting

**Pair 2, orient 1** — Partial — at least 117,243 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 85,677,207,548 | 8,924,024 | 117,243 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-3-0"></a>
### ䷆䷇ #7 The Army / #8 Holding Together

**Pair 3, orient 0** — Partial — at least 131,034 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 89,749,414,548 | 14,145,824 | 131,034 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-3-1"></a>
### ䷇䷆ #8 Holding Together / #7 The Army

**Pair 3, orient 1** — Partial — at least 113,337 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 86,775,102,418 | 9,879,744 | 113,337 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-5-0"></a>
### ䷊䷋ #11 Peace / #12 Standstill

**Pair 5, orient 0** — Partial — at least 977,895 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 86,281,305,566 | 74,123,872 | 977,895 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-5-1"></a>
### ䷋䷊ #12 Standstill / #11 Peace

**Pair 5, orient 1** — Partial — at least 975,098 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 86,024,493,668 | 74,066,304 | 975,098 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-7-0"></a>
### ䷎䷏ #15 Modesty / #16 Enthusiasm

**Pair 7, orient 0** — Partial — at least 221,325 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 86,740,894,552 | 21,626,416 | 221,325 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-7-1"></a>
### ䷏䷎ #16 Enthusiasm / #15 Modesty

**Pair 7, orient 1** — Partial — at least 221,325 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 86,963,492,888 | 21,654,048 | 221,325 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-8-0"></a>
### ䷐䷑ #17 Following / #18 Work on What Has Been Spoiled

**Pair 8, orient 0** — Partial — at least 345,016 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 86,437,827,581 | 32,367,440 | 345,016 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-8-1"></a>
### ䷑䷐ #18 Work on What Has Been Spoiled / #17 Following

**Pair 8, orient 1** — Partial — at least 351,943 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 86,723,456,533 | 35,219,296 | 351,943 | 0/54 |

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
| 79,664,556,850 | 0 | 0 | 0/54 |

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
| 79,751,553,645 | 0 | 0 | 0/54 |

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
| 87,147,897,246 | 0 | 0 | 0/54 |

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
| 87,174,562,252 | 0 | 0 | 0/54 |

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
| 90,452,667,508 | 0 | 0 | 0/54 |

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
| 87,124,241,397 | 0 | 0 | 0/54 |

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
| 84,340,440,691 | 0 | 0 | 0/54 |

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
| 85,819,980,256 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-13-0"></a>
### ䷚䷛ #27 Corners of the Mouth / #28 Preponderance of the Great

**Pair 13, orient 0** — Partial — at least 1,507,484 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 83,774,056,705 | 61,968,436 | 1,507,484 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-13-1"></a>
### ䷛䷚ #28 Preponderance of the Great / #27 Corners of the Mouth

**Pair 13, orient 1** — Partial — at least 1,507,484 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 83,738,697,145 | 61,968,436 | 1,507,484 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-14-0"></a>
### ䷜䷝ #29 The Abysmal / #30 The Clinging

**Pair 14, orient 0** — Partial — at least 1,225,361 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 84,221,462,203 | 114,790,512 | 1,225,361 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-14-1"></a>
### ䷝䷜ #30 The Clinging / #29 The Abysmal

**Pair 14, orient 1** — Partial — at least 1,225,361 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 84,084,203,076 | 114,385,352 | 1,225,361 | 0/54 |

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
| 84,884,356,033 | 0 | 0 | 0/54 |

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
| 86,410,831,579 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-16-0"></a>
### ䷠䷡ #33 Retreat / #34 The Power of the Great

**Pair 16, orient 0** — Partial — at least 644,801 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 85,404,865,410 | 51,637,740 | 644,801 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-16-1"></a>
### ䷡䷠ #34 The Power of the Great / #33 Retreat

**Pair 16, orient 1** — Partial — at least 644,801 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 85,351,937,573 | 51,637,740 | 644,801 | 0/54 |

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
| 60,702,348,583 | 1,077,245,716 | 4,194,304 | 0/54 |

One of the densest branches — 1.77% of explored nodes produced valid solutions.
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
| 59,727,790,744 | 1,101,913,060 | 4,194,304 | 0/54 |

One of the densest branches — 1.84% of explored nodes produced valid solutions.
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
| 83,972,654,937 | 0 | 0 | 0/54 |

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
| 84,689,107,415 | 0 | 0 | 0/54 |

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
| 84,371,592,565 | 0 | 0 | 0/54 |

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
| 84,486,138,904 | 0 | 0 | 0/54 |

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
| 88,860,418,891 | 0 | 0 | 0/54 |

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
| 86,362,792,104 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-22-0"></a>
### ䷬䷭ #45 Gathering Together / #46 Pushing Upward

**Pair 22, orient 0** — Partial — at least 1,226,303 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 80,174,734,848 | 64,743,132 | 1,226,303 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-22-1"></a>
### ䷭䷬ #46 Pushing Upward / #45 Gathering Together

**Pair 22, orient 1** — Partial — at least 1,104,590 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 80,103,421,283 | 65,482,060 | 1,104,590 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-23-0"></a>
### ䷮䷯ #47 Oppression / #48 The Well

**Pair 23, orient 0** — Partial — at least 615,328 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 85,991,466,592 | 68,107,008 | 615,328 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-23-1"></a>
### ䷯䷮ #48 The Well / #47 Oppression

**Pair 23, orient 1** — Partial — at least 615,328 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 86,034,533,901 | 68,107,008 | 615,328 | 0/54 |

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
| 45,873,775,365 | 1,705,555,194 | 4,194,304 | 0/54 |

One of the densest branches — 3.72% of explored nodes produced valid solutions.
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
| 64,850,000,000 | 949,293,808 | 4,194,304 | 0/54 |

One of the densest branches — 1.46% of explored nodes produced valid solutions.
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
| 85,857,970,485 | 0 | 0 | 0/54 |

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
| 85,934,334,612 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-26-0"></a>
### ䷴䷵ #53 Development / #54 The Marrying Maiden

**Pair 26, orient 0** — Partial — at least 110,459 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 88,906,950,767 | 11,753,552 | 110,459 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-26-1"></a>
### ䷵䷴ #54 The Marrying Maiden / #53 Development

**Pair 26, orient 1** — Partial — at least 110,151 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 88,685,870,394 | 11,686,180 | 110,151 | 0/54 |

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
| 88,013,763,938 | 0 | 0 | 0/54 |

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
| 88,625,671,882 | 0 | 0 | 0/54 |

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
| 85,907,205,032 | 0 | 0 | 0/54 |

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
| 85,331,404,586 | 0 | 0 | 0/54 |

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
| 90,870,762,018 | 0 | 0 | 0/54 |

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
| 88,793,181,775 | 0 | 0 | 0/54 |

Every explored path in this subtree violated the complement distance constraint.

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-30-0"></a>
### ䷼䷽ #61 Inner Truth / #62 Preponderance of the Small

**Pair 30, orient 0** — Partial — at least 1,265,492 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 79,561,020,760 | 47,146,844 | 1,265,492 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-30-1"></a>
### ䷽䷼ #62 Preponderance of the Small / #61 Inner Truth

**Pair 30, orient 1** — Partial — at least 124,238 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 81,208,216,049 | 9,023,372 | 124,238 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-31-0"></a>
### ䷾䷿ #63 After Completion / #64 Before Completion

**Pair 31, orient 0** — Partial — at least 77,528 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 88,895,618,528 | 6,919,000 | 77,528 | 0/54 |

<details><summary>Sub-branches (click to expand)</summary>

| Position 3 pair | Nodes | C3-valid | Solutions | Status |
|:---------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-31-1"></a>
### ䷿䷾ #64 Before Completion / #63 After Completion

**Pair 31, orient 1** — Partial — at least 77,971 unique orderings found (lower bound).

| Nodes explored | C3-valid solutions | Unique orderings stored | Sub-branches complete |
|---------------:|-------------------:|------------------------:|:---------------------:|
| 89,412,870,775 | 6,784,600 | 77,971 | 0/54 |

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
