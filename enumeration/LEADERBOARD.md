# Enumeration Leaderboard

Tracking progress toward complete enumeration of all valid King Wen sequence orderings.

## What we are doing and why

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is an ancient
arrangement of 64 symbols called [hexagrams](https://en.wikipedia.org/wiki/Hexagram_(I_Ching)),
created roughly 3,000 years ago in China. Each hexagram is a stack of 6 lines, each either
solid or broken — like a 6-digit binary number. There are more ways to arrange 64 things than
there are atoms in the universe (about 10^89).

We discovered that the King Wen sequence follows a set of mathematical rules so strict that
only a small fraction of all possible arrangements can satisfy them. This program finds every
arrangement that satisfies those rules — called **valid orderings**. So far we have found at
least 20 million, but the true count is unknown because the search is incomplete.

**Why this matters:** By cataloging all valid orderings, we can answer a fundamental question:
is the King Wen sequence mathematically unique (the *only* arrangement satisfying some set of
rules), or is it one choice among many? If it is one among many, what distinguishes it from
the others? These questions connect to how ancient civilizations used mathematical structure
in their cultural artifacts — and whether the structure was deliberate or emergent.

## How the search is organized

The first pair (position 1) is always the same: Creative/Receptive (hexagrams #1/#2). The search
splits into 56 **branches** based on which hexagram pair is placed at position 2. Each branch
splits further into ~54 **sub-branches** based on position 3. The total search has about 3,024
sub-branches.

A branch is **complete** when all its sub-branches have been fully explored. When all 56 branches
are complete, the enumeration is finished and we have the exact total count.

Some branches are **dead** — they explore billions of possibilities but produce zero valid
orderings. Every path in their subtree eventually violates the complement distance constraint.
Dead branches still need to be fully explored to *prove* they contain no solutions.

## Current status

| Metric | Value |
|--------|-------|
| Branches surveyed | 56/56 (all partially explored, none complete) |
| Sub-branches completed | 0 / ~3,024 |
| Nodes explored | 4.7 trillion |
| Valid orderings found | at least 20,110,129 |
| Dead branches | 24/56 (zero valid solutions) |
| Live branches | 32/56 (produce solutions) |
| Hash overflows | 4 branches (some solutions lost) |
| King Wen found | Yes |
| Enumeration complete | No |

*Data from a 1-hour partial enumeration on 64 cores, April 11, 2026.*

## Branch table

Each row is one branch. The pair at position 2 is fixed; the solver explores all possible
arrangements for positions 3-32. Orient 0 means the first hexagram of the pair comes first;
orient 1 means the second comes first.

| Pair | Or | Position 2 hexagrams | Nodes (B) | C3-valid | Stored | Status | Sub-br done |
|-----:|:--:|----------------------|----------:|---------:|-------:|:------:|:-----------:|
| 1 | 0 | Difficulty / Folly **(KW)** | 86.2 | 7.1M | 94,890 | Partial | 0/54 |
| 1 | 1 | Folly / Difficulty | 84.9 | 5.1M | 111,697 | Partial | 0/54 |
| 2 | 0 | Waiting / Conflict | 85.7 | 8.5M | 111,675 | Partial | 0/54 |
| 2 | 1 | Conflict / Waiting | 85.7 | 8.9M | 117,243 | Partial | 0/54 |
| 3 | 0 | Army / Holding Together | 89.7 | 14.1M | 131,034 | Partial | 0/54 |
| 3 | 1 | Holding Together / Army | 86.8 | 9.9M | 113,337 | Partial | 0/54 |
| 5 | 0 | Peace / Standstill | 86.3 | 74.1M | 977,895 | Partial | 0/54 |
| 5 | 1 | Standstill / Peace | 86.0 | 74.1M | 975,098 | Partial | 0/54 |
| 7 | 0 | Modesty / Enthusiasm | 86.7 | 21.6M | 221,325 | Partial | 0/54 |
| 7 | 1 | Enthusiasm / Modesty | 87.0 | 21.7M | 221,325 | Partial | 0/54 |
| 8 | 0 | Following / Work on Decayed | 86.4 | 32.4M | 345,016 | Partial | 0/54 |
| 8 | 1 | Work on Decayed / Following | 86.7 | 35.2M | 351,943 | Partial | 0/54 |
| 9 | 0 | Approach / Contemplation | 79.7 | — | — | Dead | 0/54 |
| 9 | 1 | Contemplation / Approach | 79.8 | — | — | Dead | 0/54 |
| 10 | 0 | Biting Through / Grace | 87.1 | — | — | Dead | 0/54 |
| 10 | 1 | Grace / Biting Through | 87.2 | — | — | Dead | 0/54 |
| 11 | 0 | Splitting Apart / Return | 90.5 | — | — | Dead | 0/54 |
| 11 | 1 | Return / Splitting Apart | 87.1 | — | — | Dead | 0/54 |
| 12 | 0 | Innocence / Great Taming | 84.3 | — | — | Dead | 0/54 |
| 12 | 1 | Great Taming / Innocence | 85.8 | — | — | Dead | 0/54 |
| 13 | 0 | Corners of Mouth / Preponderance | 83.8 | 62.0M | 1,507,484 | Partial | 0/54 |
| 13 | 1 | Preponderance / Corners of Mouth | 83.7 | 62.0M | 1,507,484 | Partial | 0/54 |
| 14 | 0 | Abysmal / Clinging | 84.2 | 114.8M | 1,225,361 | Partial | 0/54 |
| 14 | 1 | Clinging / Abysmal | 84.1 | 114.4M | 1,225,361 | Partial | 0/54 |
| 15 | 0 | Influence / Duration | 84.9 | — | — | Dead | 0/54 |
| 15 | 1 | Duration / Influence | 86.4 | — | — | Dead | 0/54 |
| 16 | 0 | Retreat / Great Power | 85.4 | 51.6M | 644,801 | Partial | 0/54 |
| 16 | 1 | Great Power / Retreat | 85.4 | 51.6M | 644,801 | Partial | 0/54 |
| 17 | 0 | Progress / Darkening | 60.7 | 1077.2M | 4,194,304 | Overflow | 0/54 |
| 17 | 1 | Darkening / Progress | 59.7 | 1101.9M | 4,194,304 | Overflow | 0/54 |
| 18 | 0 | Family / Opposition | 84.0 | — | — | Dead | 0/54 |
| 18 | 1 | Opposition / Family | 84.7 | — | — | Dead | 0/54 |
| 19 | 0 | Obstruction / Deliverance | 84.4 | — | — | Dead | 0/54 |
| 19 | 1 | Deliverance / Obstruction | 84.5 | — | — | Dead | 0/54 |
| 20 | 0 | Decrease / Increase | 88.9 | — | — | Dead | 0/54 |
| 20 | 1 | Increase / Decrease | 86.4 | — | — | Dead | 0/54 |
| 22 | 0 | Gathering / Pushing Upward | 80.2 | 64.7M | 1,226,303 | Partial | 0/54 |
| 22 | 1 | Pushing Upward / Gathering | 80.1 | 65.5M | 1,104,590 | Partial | 0/54 |
| 23 | 0 | Oppression / The Well | 86.0 | 68.1M | 615,328 | Partial | 0/54 |
| 23 | 1 | The Well / Oppression | 86.0 | 68.1M | 615,328 | Partial | 0/54 |
| 24 | 0 | Revolution / Cauldron | 45.9 | 1705.6M | 4,194,304 | Overflow | 0/54 |
| 24 | 1 | Cauldron / Revolution | 64.8 | 949.3M | 4,194,304 | Overflow | 0/54 |
| 25 | 0 | Arousing / Keeping Still | 85.9 | — | — | Dead | 0/54 |
| 25 | 1 | Keeping Still / Arousing | 85.9 | — | — | Dead | 0/54 |
| 26 | 0 | Development / Marrying Maiden | 88.9 | 11.8M | 110,459 | Partial | 0/54 |
| 26 | 1 | Marrying Maiden / Development | 88.7 | 11.7M | 110,151 | Partial | 0/54 |
| 27 | 0 | Abundance / Wanderer | 88.0 | — | — | Dead | 0/54 |
| 27 | 1 | Wanderer / Abundance | 88.6 | — | — | Dead | 0/54 |
| 28 | 0 | Gentle / Joyous | 85.9 | — | — | Dead | 0/54 |
| 28 | 1 | Joyous / Gentle | 85.3 | — | — | Dead | 0/54 |
| 29 | 0 | Dispersion / Limitation | 90.9 | — | — | Dead | 0/54 |
| 29 | 1 | Limitation / Dispersion | 88.8 | — | — | Dead | 0/54 |
| 30 | 0 | Inner Truth / Small Preponderance | 79.6 | 47.1M | 1,265,492 | Partial | 0/54 |
| 30 | 1 | Small Preponderance / Inner Truth | 81.2 | 9.0M | 124,238 | Partial | 0/54 |
| 31 | 0 | After Completion / Before Completion | 88.9 | 6.9M | 77,528 | Partial | 0/54 |
| 31 | 1 | Before Completion / After Completion | 89.4 | 6.8M | 77,971 | Partial | 0/54 |

## Observations from the survey

1. **24 of 56 branches are dead** — these produce zero valid orderings despite
   exploring 2.1 trillion nodes.
   Their entire subtrees fail the complement distance constraint.

2. **Branches vary enormously in solution density.** Pair 24 (Revolution/Cauldron, orient 0)
   has a 3.7% hit rate (C3-valid per node), while pair 31 (After Completion/Before Completion)
   has 0.008%. This 400x variation suggests the complement distance constraint interacts very
   differently with different position-2 choices.

3. **Orientation pairs are asymmetric.** Pair 24 orient 0 (45.9B nodes) is 30% smaller than
   pair 24 orient 1 (64.9B nodes). The within-pair orientation at position 2 affects the
   entire downstream tree structure.

4. **4 branches overflowed** the hash table (4,194,304 slots). These are the densest branches
   and need larger hash tables (SOLVE_HASH_LOG2=24) for complete enumeration.

5. **Pair 1 orient 0 is King Wen's branch** — the only branch whose subtree contains the
   actual historical sequence. It has moderate density (7.1M C3-valid in 86.2B nodes).

## Sub-branch details

*This section will be populated as individual branches are explored in single-branch mode.*
*Each completed sub-branch contributes an exact count of valid orderings to its branch total.*

### Template (filled in when data is available)

#### Branch: Pair N, Orient O

| Sub-branch (pair2, orient2) | Nodes | C3-valid | Solutions | Status |
|:---------------------------:|------:|---------:|----------:|:------:|
| (P2, O2) | — | — | — | Pending |

## How to contribute

```bash
# Compile the solver
gcc -O3 -pthread -o solve solve.c

# List all branches with sub-branch counts
./solve --list-branches

# Run a single branch on all available cores
SOLVE_THREADS=64 ./solve --branch 25 0 0

# Resume after interruption (reads checkpoint.txt)
SOLVE_THREADS=64 ./solve --branch 25 0 0

# Merge completed sub-branch files into one output
./solve --merge

# Validate any solution file
./solve --validate solutions_merged.bin
```

## Cost tracking

| Date | Run | Duration | Cost | Cumulative |
|------|-----|----------|------|------------|
| 2026-04-11 | 1-hour 56-branch survey | 1.0h | ~$3.87 | ~$3.87 |
| 2026-04-12 | 10-min checkpoint test (pair 25) | 0.3h | ~$1.16 | ~$5.03 |
| | | | **Budget cap: $250** | |

*On-demand F64: $3.87/hr. Spot F64: $0.79/hr.*
