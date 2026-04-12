# Enumeration Leaderboard

Tracking progress toward complete enumeration of all valid
[King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) orderings.

## What this project is doing

About 3,000 years ago, someone in ancient China arranged 64 symbols called
[hexagrams](https://en.wikipedia.org/wiki/Hexagram_(I_Ching)) in a specific order.
Each hexagram is a stack of 6 lines, where each line is either solid or broken —
like a 6-digit number using only 1s and 0s. The resulting arrangement is called the
[King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence).

There are more possible arrangements of 64 things than atoms in the universe (about
10^89). But the King Wen sequence follows mathematical rules so strict that only a
tiny fraction of arrangements satisfy them all. This project is finding **every single**
arrangement that satisfies those rules. Each valid arrangement is called a **valid ordering**.

**The goal:** determine whether the King Wen sequence is the *only* arrangement
satisfying some discoverable set of rules, or whether it is one choice among many.
If many valid orderings exist, we want to understand what (if anything) makes the
historical choice special.

For the mathematical rules themselves, see [SOLVE-SUMMARY.md](../SOLVE-SUMMARY.md).
For formal definitions, see [SPECIFICATION.md](../SPECIFICATION.md).

## How the search works

The 64 hexagrams are grouped into 32 consecutive pairs (see
[Rule 1](../SOLVE-SUMMARY.md#rule-1-every-hexagram-has-a-partner)). The first pair
(position 1) is always ䷀ The Creative / ䷁ The Receptive — this is mathematically
forced. The search explores all valid arrangements for the remaining 31 positions.

The search tree splits into 56 **branches** based on which pair goes at position 2.
Each branch splits further into ~54 **sub-branches** based on position 3. In total,
there are about 3,024 sub-branches to explore.

A sub-branch is **complete** when the solver has explored every possible arrangement
within it — not just found some solutions, but proven there are no more to find.
A branch is complete when all its sub-branches are complete. The full enumeration
is complete when all 56 branches are complete.

## Terminology

| Term | Meaning |
|------|---------|
| **Valid ordering** | An arrangement of all 64 hexagrams satisfying the 5 mathematical constraints ([C1-C5](../SPECIFICATION.md#constraints)) |
| **C3-valid solution** | A complete 64-hexagram sequence passing all 5 constraints. Called "C3-valid" because C3 (complement distance) is the last constraint checked. Multiple C3-valid solutions can map to the same valid ordering (different [within-pair orientations](../SOLVE-SUMMARY.md#what-the-rules-determine--and-what-remains-open)) |
| **Stored** | Unique valid orderings saved in the hash table (orientation collapsed). Limited by hash table capacity |
| **Nodes** | Individual search states explored by the [backtracking](https://en.wikipedia.org/wiki/Backtracking) algorithm. Billions of nodes produce relatively few valid orderings because most paths are pruned early |
| **Estimated dead** | A branch that produced zero C3-valid solutions in partial exploration. Likely contains no valid orderings, but this is not proven until the branch is fully explored |
| **Partial** | A branch or sub-branch that has been partially explored but not completed |
| **Overflow** | The hash table storing unique orderings reached capacity (4,194,304 entries). Some valid orderings may have been lost. Needs a larger table (`SOLVE_HASH_LOG2=24`) for complete enumeration |
| **Complete** | Fully explored — the solver has exhaustively checked every possible path. Solution count is exact, not a lower bound |

## Current status

| Metric | Value |
|--------|-------|
| Branches surveyed | 56/56 (all partially explored, none complete) |
| Sub-branches completed | 0 / ~3,024 |
| Valid orderings found | at least 20,110,129 (lower bound — true count unknown) |
| Estimated dead branches | 24/56 |
| Live branches | 32/56 |
| Hash overflows | 4 branches |
| King Wen found | Yes |
| Enumeration complete | No |

## All branches

Position 1 is always ䷀䷁ Creative/Receptive. Each branch fixes a different pair at position 2.
Orient 0 = first hexagram of the pair leads; orient 1 = second leads.

| Pair | Or | Position 2 | Nodes (B) | C3-valid | Stored | Status |
|-----:|:--:|------------|----------:|---------:|-------:|:------:|
| [1](#branch-1-0) | 0 | ䷂䷃ #3/#4 **(KW)** | 86.2 | 7.1M | 94,890 | [Partial](#terminology) |
| [1](#branch-1-1) | 1 | ䷃䷂ #4/#3 | 84.9 | 5.1M | 111,697 | [Partial](#terminology) |
| [2](#branch-2-0) | 0 | ䷄䷅ #5/#6 | 85.7 | 8.5M | 111,675 | [Partial](#terminology) |
| [2](#branch-2-1) | 1 | ䷅䷄ #6/#5 | 85.7 | 8.9M | 117,243 | [Partial](#terminology) |
| [3](#branch-3-0) | 0 | ䷆䷇ #7/#8 | 89.7 | 14.1M | 131,034 | [Partial](#terminology) |
| [3](#branch-3-1) | 1 | ䷇䷆ #8/#7 | 86.8 | 9.9M | 113,337 | [Partial](#terminology) |
| [5](#branch-5-0) | 0 | ䷊䷋ #11/#12 | 86.3 | 74.1M | 977,895 | [Partial](#terminology) |
| [5](#branch-5-1) | 1 | ䷋䷊ #12/#11 | 86.0 | 74.1M | 975,098 | [Partial](#terminology) |
| [7](#branch-7-0) | 0 | ䷎䷏ #15/#16 | 86.7 | 21.6M | 221,325 | [Partial](#terminology) |
| [7](#branch-7-1) | 1 | ䷏䷎ #16/#15 | 87.0 | 21.7M | 221,325 | [Partial](#terminology) |
| [8](#branch-8-0) | 0 | ䷐䷑ #17/#18 | 86.4 | 32.4M | 345,016 | [Partial](#terminology) |
| [8](#branch-8-1) | 1 | ䷑䷐ #18/#17 | 86.7 | 35.2M | 351,943 | [Partial](#terminology) |
| [9](#branch-9-0) | 0 | ䷒䷓ #19/#20 | 79.7 | — | — | [Est. dead](#terminology) |
| [9](#branch-9-1) | 1 | ䷓䷒ #20/#19 | 79.8 | — | — | [Est. dead](#terminology) |
| [10](#branch-10-0) | 0 | ䷔䷕ #21/#22 | 87.1 | — | — | [Est. dead](#terminology) |
| [10](#branch-10-1) | 1 | ䷕䷔ #22/#21 | 87.2 | — | — | [Est. dead](#terminology) |
| [11](#branch-11-0) | 0 | ䷖䷗ #23/#24 | 90.5 | — | — | [Est. dead](#terminology) |
| [11](#branch-11-1) | 1 | ䷗䷖ #24/#23 | 87.1 | — | — | [Est. dead](#terminology) |
| [12](#branch-12-0) | 0 | ䷘䷙ #25/#26 | 84.3 | — | — | [Est. dead](#terminology) |
| [12](#branch-12-1) | 1 | ䷙䷘ #26/#25 | 85.8 | — | — | [Est. dead](#terminology) |
| [13](#branch-13-0) | 0 | ䷚䷛ #27/#28 | 83.8 | 62.0M | 1,507,484 | [Partial](#terminology) |
| [13](#branch-13-1) | 1 | ䷛䷚ #28/#27 | 83.7 | 62.0M | 1,507,484 | [Partial](#terminology) |
| [14](#branch-14-0) | 0 | ䷜䷝ #29/#30 | 84.2 | 114.8M | 1,225,361 | [Partial](#terminology) |
| [14](#branch-14-1) | 1 | ䷝䷜ #30/#29 | 84.1 | 114.4M | 1,225,361 | [Partial](#terminology) |
| [15](#branch-15-0) | 0 | ䷞䷟ #31/#32 | 84.9 | — | — | [Est. dead](#terminology) |
| [15](#branch-15-1) | 1 | ䷟䷞ #32/#31 | 86.4 | — | — | [Est. dead](#terminology) |
| [16](#branch-16-0) | 0 | ䷠䷡ #33/#34 | 85.4 | 51.6M | 644,801 | [Partial](#terminology) |
| [16](#branch-16-1) | 1 | ䷡䷠ #34/#33 | 85.4 | 51.6M | 644,801 | [Partial](#terminology) |
| [17](#branch-17-0) | 0 | ䷢䷣ #35/#36 | 60.7 | 1077.2M | 4,194,304 | [Overflow](#terminology) |
| [17](#branch-17-1) | 1 | ䷣䷢ #36/#35 | 59.7 | 1101.9M | 4,194,304 | [Overflow](#terminology) |
| [18](#branch-18-0) | 0 | ䷤䷥ #37/#38 | 84.0 | — | — | [Est. dead](#terminology) |
| [18](#branch-18-1) | 1 | ䷥䷤ #38/#37 | 84.7 | — | — | [Est. dead](#terminology) |
| [19](#branch-19-0) | 0 | ䷦䷧ #39/#40 | 84.4 | — | — | [Est. dead](#terminology) |
| [19](#branch-19-1) | 1 | ䷧䷦ #40/#39 | 84.5 | — | — | [Est. dead](#terminology) |
| [20](#branch-20-0) | 0 | ䷨䷩ #41/#42 | 88.9 | — | — | [Est. dead](#terminology) |
| [20](#branch-20-1) | 1 | ䷩䷨ #42/#41 | 86.4 | — | — | [Est. dead](#terminology) |
| [22](#branch-22-0) | 0 | ䷬䷭ #45/#46 | 80.2 | 64.7M | 1,226,303 | [Partial](#terminology) |
| [22](#branch-22-1) | 1 | ䷭䷬ #46/#45 | 80.1 | 65.5M | 1,104,590 | [Partial](#terminology) |
| [23](#branch-23-0) | 0 | ䷮䷯ #47/#48 | 86.0 | 68.1M | 615,328 | [Partial](#terminology) |
| [23](#branch-23-1) | 1 | ䷯䷮ #48/#47 | 86.0 | 68.1M | 615,328 | [Partial](#terminology) |
| [24](#branch-24-0) | 0 | ䷰䷱ #49/#50 | 45.9 | 1705.6M | 4,194,304 | [Overflow](#terminology) |
| [24](#branch-24-1) | 1 | ䷱䷰ #50/#49 | 64.8 | 949.3M | 4,194,304 | [Overflow](#terminology) |
| [25](#branch-25-0) | 0 | ䷲䷳ #51/#52 | 85.9 | — | — | [Est. dead](#terminology) |
| [25](#branch-25-1) | 1 | ䷳䷲ #52/#51 | 85.9 | — | — | [Est. dead](#terminology) |
| [26](#branch-26-0) | 0 | ䷴䷵ #53/#54 | 88.9 | 11.8M | 110,459 | [Partial](#terminology) |
| [26](#branch-26-1) | 1 | ䷵䷴ #54/#53 | 88.7 | 11.7M | 110,151 | [Partial](#terminology) |
| [27](#branch-27-0) | 0 | ䷶䷷ #55/#56 | 88.0 | — | — | [Est. dead](#terminology) |
| [27](#branch-27-1) | 1 | ䷷䷶ #56/#55 | 88.6 | — | — | [Est. dead](#terminology) |
| [28](#branch-28-0) | 0 | ䷸䷹ #57/#58 | 85.9 | — | — | [Est. dead](#terminology) |
| [28](#branch-28-1) | 1 | ䷹䷸ #58/#57 | 85.3 | — | — | [Est. dead](#terminology) |
| [29](#branch-29-0) | 0 | ䷺䷻ #59/#60 | 90.9 | — | — | [Est. dead](#terminology) |
| [29](#branch-29-1) | 1 | ䷻䷺ #60/#59 | 88.8 | — | — | [Est. dead](#terminology) |
| [30](#branch-30-0) | 0 | ䷼䷽ #61/#62 | 79.6 | 47.1M | 1,265,492 | [Partial](#terminology) |
| [30](#branch-30-1) | 1 | ䷽䷼ #62/#61 | 81.2 | 9.0M | 124,238 | [Partial](#terminology) |
| [31](#branch-31-0) | 0 | ䷾䷿ #63/#64 | 88.9 | 6.9M | 77,528 | [Partial](#terminology) |
| [31](#branch-31-1) | 1 | ䷿䷾ #64/#63 | 89.4 | 6.8M | 77,971 | [Partial](#terminology) |

## Observations

1. **24 of 56 branches are estimated dead** — they produced zero
   [C3-valid solutions](#terminology) despite exploring billions of nodes each. Their entire
   subtrees appear to fail the [complement distance constraint](../SOLVE-SUMMARY.md#rule-3-opposites-kept-unusually-close).
   This is not proven until each branch is fully explored.

2. **Solution density varies 400x across branches.** Pair 24 orient 0 (Revolution/Cauldron)
   produces C3-valid solutions at a 3.7% rate, while pair 31 (After Completion/Before Completion)
   runs at 0.008%. The [complement distance](../SPECIFICATION.md#c3-complement-proximity) constraint
   interacts very differently with different position-2 choices.

3. **Orientation matters.** Pair 24 orient 0 explored 45.9B nodes vs 64.9B for orient 1 — a 30%
   difference from simply reversing which hexagram of the pair comes first at position 2.

4. **4 branches overflowed** the hash table. Their stored counts hit the 4,194,304
   capacity limit, meaning some valid orderings were lost. These branches need a larger table
   for complete enumeration.

5. **Pair 1 orient 0 is King Wen's branch** — the only branch whose subtree contains the
   actual historical sequence.

## Branch details

Each branch section below shows the ~54 sub-branches (position 3 choices) with their status.
Most are unexplored — sub-branch tables will be populated as the enumeration progresses.

<a id="branch-1-0"></a>
### Pair 1, orient 0: ䷂䷃ #3 Difficulty at the Beginning / #4 Youthful Folly (King Wen's branch)

**Status:** Partial — Found 94,890 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 86,244,869,323 (86.2B) |
| C3-valid solutions | 7,082,024 |
| Unique orderings stored | 94,890 |
| Sub-branches completed | 0/54 |

This branch contains the actual King Wen sequence. All valid orderings in this subtree
share King Wen's pair at position 2 (#3 Difficulty at the Beginning / #4 Youthful Folly).

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-1-1"></a>
### Pair 1, orient 1: ䷃䷂ #4 Youthful Folly / #3 Difficulty at the Beginning

**Status:** Partial — Found 111,697 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 84,885,549,546 (84.9B) |
| C3-valid solutions | 5,055,884 |
| Unique orderings stored | 111,697 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-2-0"></a>
### Pair 2, orient 0: ䷄䷅ #5 Waiting / #6 Conflict

**Status:** Partial — Found 111,675 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 85,723,951,614 (85.7B) |
| C3-valid solutions | 8,511,700 |
| Unique orderings stored | 111,675 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-2-1"></a>
### Pair 2, orient 1: ䷅䷄ #6 Conflict / #5 Waiting

**Status:** Partial — Found 117,243 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 85,677,207,548 (85.7B) |
| C3-valid solutions | 8,924,024 |
| Unique orderings stored | 117,243 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-3-0"></a>
### Pair 3, orient 0: ䷆䷇ #7 The Army / #8 Holding Together

**Status:** Partial — Found 131,034 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 89,749,414,548 (89.7B) |
| C3-valid solutions | 14,145,824 |
| Unique orderings stored | 131,034 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-3-1"></a>
### Pair 3, orient 1: ䷇䷆ #8 Holding Together / #7 The Army

**Status:** Partial — Found 113,337 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 86,775,102,418 (86.8B) |
| C3-valid solutions | 9,879,744 |
| Unique orderings stored | 113,337 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-5-0"></a>
### Pair 5, orient 0: ䷊䷋ #11 Peace / #12 Standstill

**Status:** Partial — Found 977,895 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 86,281,305,566 (86.3B) |
| C3-valid solutions | 74,123,872 |
| Unique orderings stored | 977,895 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-5-1"></a>
### Pair 5, orient 1: ䷋䷊ #12 Standstill / #11 Peace

**Status:** Partial — Found 975,098 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 86,024,493,668 (86.0B) |
| C3-valid solutions | 74,066,304 |
| Unique orderings stored | 975,098 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-7-0"></a>
### Pair 7, orient 0: ䷎䷏ #15 Modesty / #16 Enthusiasm

**Status:** Partial — Found 221,325 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 86,740,894,552 (86.7B) |
| C3-valid solutions | 21,626,416 |
| Unique orderings stored | 221,325 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-7-1"></a>
### Pair 7, orient 1: ䷏䷎ #16 Enthusiasm / #15 Modesty

**Status:** Partial — Found 221,325 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 86,963,492,888 (87.0B) |
| C3-valid solutions | 21,654,048 |
| Unique orderings stored | 221,325 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-8-0"></a>
### Pair 8, orient 0: ䷐䷑ #17 Following / #18 Work on What Has Been Spoiled

**Status:** Partial — Found 345,016 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 86,437,827,581 (86.4B) |
| C3-valid solutions | 32,367,440 |
| Unique orderings stored | 345,016 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-8-1"></a>
### Pair 8, orient 1: ䷑䷐ #18 Work on What Has Been Spoiled / #17 Following

**Status:** Partial — Found 351,943 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 86,723,456,533 (86.7B) |
| C3-valid solutions | 35,219,296 |
| Unique orderings stored | 351,943 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-9-0"></a>
### Pair 9, orient 0: ䷒䷓ #19 Approach / #20 Contemplation

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 79,664,556,850 (79.7B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-9-1"></a>
### Pair 9, orient 1: ䷓䷒ #20 Contemplation / #19 Approach

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 79,751,553,645 (79.8B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-10-0"></a>
### Pair 10, orient 0: ䷔䷕ #21 Biting Through / #22 Grace

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 87,147,897,246 (87.1B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-10-1"></a>
### Pair 10, orient 1: ䷕䷔ #22 Grace / #21 Biting Through

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 87,174,562,252 (87.2B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-11-0"></a>
### Pair 11, orient 0: ䷖䷗ #23 Splitting Apart / #24 Return

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 90,452,667,508 (90.5B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-11-1"></a>
### Pair 11, orient 1: ䷗䷖ #24 Return / #23 Splitting Apart

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 87,124,241,397 (87.1B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-12-0"></a>
### Pair 12, orient 0: ䷘䷙ #25 Innocence / #26 The Taming Power of the Great

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 84,340,440,691 (84.3B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-12-1"></a>
### Pair 12, orient 1: ䷙䷘ #26 The Taming Power of the Great / #25 Innocence

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 85,819,980,256 (85.8B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-13-0"></a>
### Pair 13, orient 0: ䷚䷛ #27 Corners of the Mouth / #28 Preponderance of the Great

**Status:** Partial — Found 1,507,484 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 83,774,056,705 (83.8B) |
| C3-valid solutions | 61,968,436 |
| Unique orderings stored | 1,507,484 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-13-1"></a>
### Pair 13, orient 1: ䷛䷚ #28 Preponderance of the Great / #27 Corners of the Mouth

**Status:** Partial — Found 1,507,484 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 83,738,697,145 (83.7B) |
| C3-valid solutions | 61,968,436 |
| Unique orderings stored | 1,507,484 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-14-0"></a>
### Pair 14, orient 0: ䷜䷝ #29 The Abysmal / #30 The Clinging

**Status:** Partial — Found 1,225,361 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 84,221,462,203 (84.2B) |
| C3-valid solutions | 114,790,512 |
| Unique orderings stored | 1,225,361 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-14-1"></a>
### Pair 14, orient 1: ䷝䷜ #30 The Clinging / #29 The Abysmal

**Status:** Partial — Found 1,225,361 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 84,084,203,076 (84.1B) |
| C3-valid solutions | 114,385,352 |
| Unique orderings stored | 1,225,361 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-15-0"></a>
### Pair 15, orient 0: ䷞䷟ #31 Influence / #32 Duration

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 84,884,356,033 (84.9B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-15-1"></a>
### Pair 15, orient 1: ䷟䷞ #32 Duration / #31 Influence

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 86,410,831,579 (86.4B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-16-0"></a>
### Pair 16, orient 0: ䷠䷡ #33 Retreat / #34 The Power of the Great

**Status:** Partial — Found 644,801 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 85,404,865,410 (85.4B) |
| C3-valid solutions | 51,637,740 |
| Unique orderings stored | 644,801 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-16-1"></a>
### Pair 16, orient 1: ䷡䷠ #34 The Power of the Great / #33 Retreat

**Status:** Partial — Found 644,801 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 85,351,937,573 (85.4B) |
| C3-valid solutions | 51,637,740 |
| Unique orderings stored | 644,801 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-17-0"></a>
### Pair 17, orient 0: ䷢䷣ #35 Progress / #36 Darkening of the Light

**Status:** Overflow — Hash table reached capacity — some solutions may be missing.

| Metric | Value |
|--------|-------|
| Nodes explored | 60,702,348,583 (60.7B) |
| C3-valid solutions | 1,077,245,716 |
| Unique orderings stored | 4,194,304 |
| Sub-branches completed | 0/54 |

This is one of the densest branches — 1077M C3-valid solutions from 61B nodes
(1.77% hit rate). The hash table overflowed, so the 4,194,304 stored orderings
are a lower bound. Complete enumeration requires `SOLVE_HASH_LOG2=24` (16M slot table).

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-17-1"></a>
### Pair 17, orient 1: ䷣䷢ #36 Darkening of the Light / #35 Progress

**Status:** Overflow — Hash table reached capacity — some solutions may be missing.

| Metric | Value |
|--------|-------|
| Nodes explored | 59,727,790,744 (59.7B) |
| C3-valid solutions | 1,101,913,060 |
| Unique orderings stored | 4,194,304 |
| Sub-branches completed | 0/54 |

This is one of the densest branches — 1102M C3-valid solutions from 60B nodes
(1.84% hit rate). The hash table overflowed, so the 4,194,304 stored orderings
are a lower bound. Complete enumeration requires `SOLVE_HASH_LOG2=24` (16M slot table).

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-18-0"></a>
### Pair 18, orient 0: ䷤䷥ #37 The Family / #38 Opposition

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 83,972,654,937 (84.0B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-18-1"></a>
### Pair 18, orient 1: ䷥䷤ #38 Opposition / #37 The Family

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 84,689,107,415 (84.7B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-19-0"></a>
### Pair 19, orient 0: ䷦䷧ #39 Obstruction / #40 Deliverance

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 84,371,592,565 (84.4B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-19-1"></a>
### Pair 19, orient 1: ䷧䷦ #40 Deliverance / #39 Obstruction

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 84,486,138,904 (84.5B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-20-0"></a>
### Pair 20, orient 0: ䷨䷩ #41 Decrease / #42 Increase

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 88,860,418,891 (88.9B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-20-1"></a>
### Pair 20, orient 1: ䷩䷨ #42 Increase / #41 Decrease

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 86,362,792,104 (86.4B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-22-0"></a>
### Pair 22, orient 0: ䷬䷭ #45 Gathering Together / #46 Pushing Upward

**Status:** Partial — Found 1,226,303 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 80,174,734,848 (80.2B) |
| C3-valid solutions | 64,743,132 |
| Unique orderings stored | 1,226,303 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-22-1"></a>
### Pair 22, orient 1: ䷭䷬ #46 Pushing Upward / #45 Gathering Together

**Status:** Partial — Found 1,104,590 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 80,103,421,283 (80.1B) |
| C3-valid solutions | 65,482,060 |
| Unique orderings stored | 1,104,590 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-23-0"></a>
### Pair 23, orient 0: ䷮䷯ #47 Oppression / #48 The Well

**Status:** Partial — Found 615,328 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 85,991,466,592 (86.0B) |
| C3-valid solutions | 68,107,008 |
| Unique orderings stored | 615,328 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-23-1"></a>
### Pair 23, orient 1: ䷯䷮ #48 The Well / #47 Oppression

**Status:** Partial — Found 615,328 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 86,034,533,901 (86.0B) |
| C3-valid solutions | 68,107,008 |
| Unique orderings stored | 615,328 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-24-0"></a>
### Pair 24, orient 0: ䷰䷱ #49 Revolution / #50 The Cauldron

**Status:** Overflow — Hash table reached capacity — some solutions may be missing.

| Metric | Value |
|--------|-------|
| Nodes explored | 45,873,775,365 (45.9B) |
| C3-valid solutions | 1,705,555,194 |
| Unique orderings stored | 4,194,304 |
| Sub-branches completed | 0/54 |

This is one of the densest branches — 1706M C3-valid solutions from 46B nodes
(3.72% hit rate). The hash table overflowed, so the 4,194,304 stored orderings
are a lower bound. Complete enumeration requires `SOLVE_HASH_LOG2=24` (16M slot table).

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-24-1"></a>
### Pair 24, orient 1: ䷱䷰ #50 The Cauldron / #49 Revolution

**Status:** Overflow — Hash table reached capacity — some solutions may be missing.

| Metric | Value |
|--------|-------|
| Nodes explored | 64,850,000,000 (64.8B) |
| C3-valid solutions | 949,293,808 |
| Unique orderings stored | 4,194,304 |
| Sub-branches completed | 0/54 |

This is one of the densest branches — 949M C3-valid solutions from 65B nodes
(1.46% hit rate). The hash table overflowed, so the 4,194,304 stored orderings
are a lower bound. Complete enumeration requires `SOLVE_HASH_LOG2=24` (16M slot table).

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-25-0"></a>
### Pair 25, orient 0: ䷲䷳ #51 The Arousing / #52 Keeping Still

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 85,857,970,485 (85.9B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-25-1"></a>
### Pair 25, orient 1: ䷳䷲ #52 Keeping Still / #51 The Arousing

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 85,934,334,612 (85.9B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-26-0"></a>
### Pair 26, orient 0: ䷴䷵ #53 Development / #54 The Marrying Maiden

**Status:** Partial — Found 110,459 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 88,906,950,767 (88.9B) |
| C3-valid solutions | 11,753,552 |
| Unique orderings stored | 110,459 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-26-1"></a>
### Pair 26, orient 1: ䷵䷴ #54 The Marrying Maiden / #53 Development

**Status:** Partial — Found 110,151 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 88,685,870,394 (88.7B) |
| C3-valid solutions | 11,686,180 |
| Unique orderings stored | 110,151 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-27-0"></a>
### Pair 27, orient 0: ䷶䷷ #55 Abundance / #56 The Wanderer

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 88,013,763,938 (88.0B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-27-1"></a>
### Pair 27, orient 1: ䷷䷶ #56 The Wanderer / #55 Abundance

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 88,625,671,882 (88.6B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-28-0"></a>
### Pair 28, orient 0: ䷸䷹ #57 The Gentle / #58 The Joyous

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 85,907,205,032 (85.9B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-28-1"></a>
### Pair 28, orient 1: ䷹䷸ #58 The Joyous / #57 The Gentle

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 85,331,404,586 (85.3B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-29-0"></a>
### Pair 29, orient 0: ䷺䷻ #59 Dispersion / #60 Limitation

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 90,870,762,018 (90.9B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-29-1"></a>
### Pair 29, orient 1: ䷻䷺ #60 Limitation / #59 Dispersion

**Status:** Estimated dead — No valid orderings found in partial exploration.

| Metric | Value |
|--------|-------|
| Nodes explored | 88,793,181,775 (88.8B) |
| C3-valid solutions | 0 |
| Unique orderings stored | 0 |
| Sub-branches completed | 0/54 |

This branch produced zero valid orderings in the partial survey. It is estimated dead —
every explored path eventually violated the complement distance constraint. However, this
is not proven until the branch is fully explored to completion.

<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-30-0"></a>
### Pair 30, orient 0: ䷼䷽ #61 Inner Truth / #62 Preponderance of the Small

**Status:** Partial — Found 1,265,492 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 79,561,020,760 (79.6B) |
| C3-valid solutions | 47,146,844 |
| Unique orderings stored | 1,265,492 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-30-1"></a>
### Pair 30, orient 1: ䷽䷼ #62 Preponderance of the Small / #61 Inner Truth

**Status:** Partial — Found 124,238 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 81,208,216,049 (81.2B) |
| C3-valid solutions | 9,023,372 |
| Unique orderings stored | 124,238 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-31-0"></a>
### Pair 31, orient 0: ䷾䷿ #63 After Completion / #64 Before Completion

**Status:** Partial — Found 77,528 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 88,895,618,528 (88.9B) |
| C3-valid solutions | 6,919,000 |
| Unique orderings stored | 77,528 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

<a id="branch-31-1"></a>
### Pair 31, orient 1: ䷿䷾ #64 Before Completion / #63 After Completion

**Status:** Partial — Found 77,971 unique orderings so far (lower bound).

| Metric | Value |
|--------|-------|
| Nodes explored | 89,412,870,775 (89.4B) |
| C3-valid solutions | 6,784,600 |
| Unique orderings stored | 77,971 |
| Sub-branches completed | 0/54 |


<details><summary>Sub-branch table (click to expand)</summary>

| Sub-branch (pair at position 3) | Nodes | C3-valid | Solutions | Status |
|:-------------------------------|------:|---------:|----------:|:------:|
| *Not yet explored in single-branch mode* | — | — | — | Pending |

</details>

## How to run the solver

```bash
# Compile
gcc -O3 -pthread -o solve solve.c

# List all branches
./solve --list-branches

# Run a single branch on all cores (resumes from checkpoint.txt)
SOLVE_THREADS=64 ./solve --branch 24 0 0

# Merge completed sub-branch files
./solve --merge

# Validate results
./solve --validate solutions_merged.bin
```

For details on the solver, constraints, and methodology, see [SOLVE.md](../SOLVE.md).
