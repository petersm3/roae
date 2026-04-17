# solutions.bin binary format specification

Version: 1.0
Date: 2026-04-17
Producer: solve.c (commit 8bad127+)

## Overview

`solutions.bin` contains every unique pair ordering of 64 I Ching hexagrams
that satisfies constraints C1-C5. Each record is a 32-byte packed
representation of one valid ordering. Records are sorted and deduplicated.

## Record format

Each record is exactly **32 bytes**. Byte `i` (0-indexed, i = 0..31)
encodes the pair at position `i` of the sequence:

    byte[i] = (pair_index << 2) | (orient << 1)

- **pair_index** (bits 7-2): index into the pair table (0-31)
- **orient** (bit 1): 0 = natural order (a, b), 1 = reversed (b, a)
- **bit 0**: unused, always 0

To decode byte `i`:

    pair_index = (byte[i] >> 2) & 0x3F
    orient     = (byte[i] >> 1) & 0x01

## Pair table

The 32 pairs are derived from the King Wen sequence. Each pair consists of
two hexagrams that appear at consecutive positions (0-1, 2-3, 4-5, ...,
62-63) in King Wen. Hexagrams are represented as 6-bit integers (0-63)
where each bit is one line (0 = yin, 1 = yang), bottom to top.

    Pair  0: (63,  0)    Pair  8: (25, 38)    Pair 16: (60, 15)    Pair 24: (29, 46)
    Pair  1: (17, 34)    Pair  9: ( 3, 48)    Pair 17: (40,  5)    Pair 25: ( 9, 36)
    Pair  2: (23, 58)    Pair 10: (41, 37)    Pair 18: (53, 43)    Pair 26: (52, 11)
    Pair  3: ( 2, 16)    Pair 11: (32,  1)    Pair 19: (20, 10)    Pair 27: (13, 44)
    Pair  4: (55, 59)    Pair 12: (57, 39)    Pair 20: (35, 49)    Pair 28: (54, 27)
    Pair  5: ( 7, 56)    Pair 13: (33, 30)    Pair 21: (31, 62)    Pair 29: (50, 19)
    Pair  6: (61, 47)    Pair 14: (18, 45)    Pair 22: (24,  6)    Pair 30: (51, 12)
    Pair  7: ( 4,  8)    Pair 15: (28, 14)    Pair 23: (26, 22)    Pair 31: (21, 42)

The authoritative pair table is generated programmatically by pairing
consecutive positions in the King Wen sequence:

    pairs[i] = (KW[2*i], KW[2*i + 1])    for i = 0..31

where KW is:

    63  0 17 34 23 58  2 16 55 59  7 56 61 47  4  8
    25 38  3 48 41 37 32  1 57 39 33 30 18 45 28 14
    60 15 40  5 53 43 20 10 35 49 31 62 24  6 26 22
    29 46  9 36 52 11 13 44 54 27 50 19 51 12 21 42

## Reconstructing the full 64-hexagram sequence

Given a 32-byte record:

    for position i in 0..31:
        pair_index = (record[i] >> 2) & 0x3F
        orient     = (record[i] >> 1) & 1
        (a, b)     = pairs[pair_index]
        if orient == 0:
            hexagram[2*i]     = a
            hexagram[2*i + 1] = b
        else:
            hexagram[2*i]     = b
            hexagram[2*i + 1] = a

The result is a 64-element sequence of hexagram numbers (0-63).

## Deduplication semantics

Records are deduplicated by **canonical pair ordering**: orientation bits
(bit 1) are masked out during comparison. Two records that place the same
32 pairs at the same 32 positions but differ in within-pair orientation are
treated as the same canonical ordering. Only one orientation variant is
retained (the lexicographically smallest by full byte comparison).

The output counts **unique pair orderings**, not unique oriented sequences.
Exactly one record per canonical ordering is retained (the lexicographically
smallest by full byte comparison). Valid orientation variants for any
canonical ordering are cheaply recoverable by testing all 2^31 combinations
against C2/C5 — they do not need to be stored.

## Sort order

Records are sorted by the `compare_solutions` function:
1. Primary: pair identity at each position (orient masked via `& 0xFC`),
   lexicographic, left to right
2. Secondary: full byte value (including orient), lexicographic

This means canonical-equivalent records are adjacent, and within a
canonical group, the smallest orient variant comes first.

## Constraints

Each record in solutions.bin satisfies:

- **C1 (pair structure):** all 32 pairs used exactly once
- **C2 (no hamming-5):** no consecutive hexagrams have Hamming distance 5
- **C3 (complement distance):** implied by C1+C2+C5 for these specific pairs
- **C4 (first pair):** position 0 is always pair 0 (Creative/Receptive, 63→0)
- **C5 (distance distribution):** the multiset of Hamming distances across
  all 63 consecutive transitions exactly matches King Wen's distribution:
  {distance 1: 2, distance 2: 20, distance 3: 13, distance 4: 19, distance 6: 9}

## File integrity

- `solutions.sha256` contains the SHA-256 hash of solutions.bin
- `solve_results.json` contains run parameters, git hash, and analytics
- `./solve --verify solutions.bin` independently checks every record
  against C1-C5, verifies sort order, and checks for duplicates

## Reproducing from source

    git checkout <commit-hash-from-solve_results.json>
    gcc -O3 -pthread -march=native -o solve solve.c -lm
    SOLVE_NODE_LIMIT=<from-json> SOLVE_DEPTH=<from-json> ./solve 0

For exhaustive enumeration (no node limit):

    SOLVE_THREADS=<cores> ./solve 0
