# solutions.bin binary format specification

Format version: **1** (introduced 2026-04-18)
Prior versions: v0 (unstructured record stream, no header) — superseded.

## Overview

`solutions.bin` contains every unique pair ordering of 64 I Ching hexagrams
that satisfies constraints C1-C5. The file layout is:

    [ 32-byte header ] [ N × 32-byte records ]

Records are sorted (by `compare_solutions` — see §Sort order) and
deduplicated (one record per canonical pair-sequence — see §Deduplication).

## File header (32 bytes)

| Offset | Size | Field           | Encoding         | Notes |
|--------|------|-----------------|------------------|-------|
| 0      | 4    | Magic           | ASCII `'ROAE'`   | bytes `0x52 0x4F 0x41 0x45` |
| 4      | 4    | Format version  | uint32 LE        | currently `1` |
| 8      | 8    | Record count    | uint64 LE        | number of records (file minus header, divided by 32) |
| 16     | 16   | Reserved        | zero-filled      | MUST be zero; reserved for format extensions |

**Byte order.** The magic is ASCII (byte-order-independent). The `uint32`
and `uint64` fields are **little-endian**. On a big-endian host a reader
must byte-swap on read (trivial: byte[0] is the least-significant byte).

**Why 32 bytes.** Matches `SOL_RECORD_SIZE` deliberately: record `i` is
located at file offset `32 + i*32`, so alignment and offset arithmetic
are trivial.

**Reproducibility.** The header contains only deterministic-from-input
fields. No timestamps, git hashes, hostnames, or build identifiers live
here — they live in the sidecar `solutions.meta.json`. As a result,
`sha256(solutions.bin)` is a pure function of the enumeration inputs
(node limit, depth, constraints) and is reproducible across runs,
machines, and years.

## Sidecar metadata (`solutions.meta.json`)

Written alongside `solutions.bin` on every successful merge. Contains
provenance and self-describing context — **not** the canonical artifact,
just a human-readable breadcrumb. Example:

    {
      "file": "solutions.bin",
      "magic": "ROAE",
      "format_version": 1,
      "header_size_bytes": 32,
      "record_size_bytes": 32,
      "record_count": 135780,
      "unique_solutions": 135780,
      "sha256": "403f7202a33a9337...",
      "encoding": "byte i = (pair_index<<2) | (orient<<1); bit 0 reserved",
      "dedup_semantics": "canonical — one record per unique pair-sequence; orient variants collapsed",
      "header_byte_order": "little-endian (u32 version, u64 record_count)",
      "record_byte_order": "single-byte records; byte order is a non-concept",
      "constraint_spec": "SPECIFICATION.md",
      "generator": "solve.c git <short-hash>",
      "generated_utc": "2026-04-18T01:45:12Z"
    }

The sidecar contains timestamp and git hash, so **it is NOT byte-
reproducible across runs** — deliberately. The canonical artifacts
(`solutions.bin` and `solutions.sha256`) are.

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
treated as the same canonical ordering.

**Exactly one record per canonical class is retained**, and the
deterministic choice is **the lexicographically smallest orient variant by
full-byte comparison**. This matters for byte-exact reproducibility: two
conformant implementations that both enumerate every valid orient variant
and then dedup MUST keep the same variant, or their `solutions.bin` shas
will differ despite containing equivalent information. A re-implementation
that keeps, say, the lexicographically-largest orient variant would
produce a correct file under C1-C5 but NOT a bit-for-bit match against
the reference.

The output counts **unique pair orderings**, not unique oriented
sequences. Other orientation variants for any canonical ordering are
cheaply recoverable by testing all 2^31 combinations against C2/C5 —
they do not need to be stored.

## Sort order

Records are sorted by the `compare_solutions` function, which defines a
**total strict order** on distinct 32-byte records:

1. **Primary**: pair identity at each position (orient masked via `& 0xFC`),
   lexicographic, left to right.
2. **Secondary**: full byte value (including orient), lexicographic. Used
   only when the primary keys are equal (i.e. when two records are in the
   same canonical class).

Because `compare_solutions` is a total order (no two distinct records
compare equal), the post-sort byte layout is deterministic — it does not
depend on sorting-algorithm stability. This in turn is what gives
reproducible sha256: a stable or unstable sort would produce the same
bytes.

This sort places canonical-equivalent records adjacent, and within a
canonical group the smallest orient variant first — so the
deduplication pass that keeps the first of each canonical group
retains the lex-smallest orient variant described above.

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

- `solutions.sha256` contains the SHA-256 hash of the entire `solutions.bin`
  (header included, since the header is part of the canonical artifact).
- `solutions.meta.json` is the human-readable sidecar (format version,
  record count, embedded sha, generation timestamp, git hash).
- `solve_results.json` contains run parameters, git hash, and analytics.
- `./solve --verify solutions.bin` parses the header (fails loudly on bad
  magic or unknown version), then independently checks every record against
  C1-C5, verifies sort order, and checks for duplicates.

## Reading the file from another language

Minimum sketch for any language:

    1. Open solutions.bin
    2. Read 32 bytes — the header.
    3. Check bytes 0..3 are 'R','O','A','E'. Reject if not.
    4. Read uint32 LE at offset 4 — must equal 1 (current format version).
       A reader that does not understand a newer version MUST refuse
       to interpret the file rather than guess.
    5. Read uint64 LE at offset 8 — the record count.
    6. Validate: (file_size - 32) must equal record_count * 32.
    7. Seek to offset 32 and read records sequentially.

For a full walkthrough — header parse, record decode, per-constraint
checks, sort-order and dedup validation — see
[REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md). It walks a reader from
zero to a conformant verifier in any language. `verify.py` in this
repository is the reference implementation of that recipe (~130 lines
of Python).

## Reproducing from source

    git checkout <commit-hash-from-solve_results.json>
    gcc -O3 -pthread -march=native -o solve solve.c -lm
    SOLVE_NODE_LIMIT=<from-json> SOLVE_DEPTH=<from-json> ./solve 0

For exhaustive enumeration (no node limit):

    SOLVE_THREADS=<cores> ./solve 0
