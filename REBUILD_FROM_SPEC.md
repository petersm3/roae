# Rebuild from specification — independent verifier recipe

A step-by-step recipe for building an independent `solutions.bin` verifier using only this document, [SPECIFICATION.md](SPECIFICATION.md), and [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md). If you can follow the steps below in any programming language and produce a tool that reads a `solutions.bin` file and reports constraint pass/fail, then the specs stand on their own — you did not need to read `solve.c`.

## What this document is

A forcing function for spec completeness and a 20-year resilience artifact. Every question you have to answer from `solve.c` rather than from the authoritative specs is a gap in the specs and should be fixed. The companion implementation that proves this recipe works is `verify.py` in this repository — written in Python, ~130 lines, shares zero code with `solve.c`.

## What this document is NOT

Not an enumerator guide. A full re-implementation of the search (backtracking, hash-table dedup, sharded merge) is a separate, much larger task — the `solve.c` enumeration path is ~6,500 lines and depends on subtle performance and concurrency structures. The verifier, by contrast, is purely declarative: it takes a file and checks whether it satisfies the specification. That's ~150 lines in most languages.

## What a conformant verifier must do

Your verifier reads a `solutions.bin` file and answers: *does every record satisfy the constraints, is the file sorted correctly, are there no duplicates, and is King Wen present?*

Concretely:

1. Parse and validate the 32-byte header (magic, version, record count).
2. For each 32-byte record, decode it into a 64-hexagram sequence.
3. Check each sequence against **C1** (pair structure), **C2** (no Hamming-5 transitions), **C3** (complement distance ≤ 776), **C4** (first pair = Creative/Receptive), **C5** (exact distance distribution).
4. Verify records are in sorted order as defined in `SOLUTIONS_FORMAT.md`.
5. Verify no two records are canonical duplicates (same pair-sequence).
6. Verify the King Wen sequence appears among the records.
7. Report pass/fail with per-constraint counts.

Any verifier that does these nine things correctly IS a conformant implementation. There is no hidden behavior to match.

## Prerequisites

- Any programming language with: fixed-size integer types (at least `uint8`, `uint32`, `uint64`), binary file I/O, arrays, and bitwise operations.
- [`SPECIFICATION.md`](SPECIFICATION.md) — the mathematical definitions of **C1**–**C5**.
- [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) — the binary format (header + records).
- A `solutions.bin` file to verify (produced by `solve --merge` or a normal enumeration run).

## Step 1. Parse the header

Read the first 32 bytes of the file. Per [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §File header:

| Offset | Size | Field           | Must satisfy                                |
|--------|------|-----------------|---------------------------------------------|
| 0      | 4    | Magic           | ASCII `'R','O','A','E'` (`0x52 0x4F 0x41 0x45`) |
| 4      | 4    | Format version  | uint32 little-endian, must equal `1`        |
| 8      | 8    | Record count    | uint64 little-endian                        |
| 16     | 16   | Reserved        | zero-filled (advisory — tolerate nonzero)   |

**Reject** the file if magic ≠ `'ROAE'` or version is not a version you know. A conformant reader that does not understand a future version MUST refuse rather than guess, because the format may change in ways that would silently corrupt interpretation.

After header parse, assert `file_size == 32 + record_count × 32`. If the declared count and the actual file geometry disagree, the file is corrupt — reject.

Python:

```python
with open(path, 'rb') as f:
    hdr = f.read(32)
    if len(hdr) < 32:
        raise ValueError("file too small for header")
    if hdr[0:4] != b'ROAE':
        raise ValueError(f"bad magic: {hdr[0:4]!r}")
    version = int.from_bytes(hdr[4:8], 'little')
    if version != 1:
        raise ValueError(f"unknown format version {version}")
    record_count = int.from_bytes(hdr[8:16], 'little')
    records_blob = f.read()
    if len(records_blob) != record_count * 32:
        raise ValueError(
            f"file has {len(records_blob)} bytes of records, "
            f"header declares {record_count * 32}")
```

## Step 2. Build the pair table

The solver works over 32 pairs of hexagrams. The pair table is fixed and derivable two ways — both equivalent. Pick either.

### Option A: Copy it from SOLUTIONS_FORMAT.md

The authoritative list appears in [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Pair table. Each entry is a tuple `(a, b)`:

```
pairs = [
    (63,  0), (17, 34), (23, 58), ( 2, 16), (55, 59), ( 7, 56), (61, 47), ( 4,  8),
    (25, 38), ( 3, 48), (41, 37), (32,  1), (57, 39), (33, 30), (18, 45), (28, 14),
    (60, 15), (40,  5), (53, 43), (20, 10), (35, 49), (31, 62), (24,  6), (26, 22),
    (29, 46), ( 9, 36), (52, 11), (13, 44), (54, 27), (50, 19), (51, 12), (21, 42),
]
```

### Option B: Derive it from the King Wen sequence and the partner function

The King Wen sequence (from [`SPECIFICATION.md`](SPECIFICATION.md)):

```
KW = [63, 0, 17, 34, 23, 58, 2, 16, 55, 59, 7, 56, 61, 47, 4, 8,
      25, 38, 3, 48, 41, 37, 32, 1, 57, 39, 33, 30, 18, 45, 28, 14,
      60, 15, 40, 5, 53, 43, 20, 10, 35, 49, 31, 62, 24, 6, 26, 22,
      29, 46, 9, 36, 52, 11, 13, 44, 54, 27, 50, 19, 51, 12, 21, 42]
```

Pair `i` (for `i` in 0..31) is `(KW[2i], KW[2i+1])`.

Per [`SPECIFICATION.md`](SPECIFICATION.md) Definitions, the partner function is:

- `rev(n)` = bit-reverse of `n`'s 6-bit representation
- `comp(n)` = `n XOR 63`
- `partner(h)` = `rev(h)` if `rev(h) ≠ h`, else `comp(h)`

For every pair `(a, b)` in the table, `b == partner(a)` (and by symmetry `a == partner(b)`). If you want to sanity-check your pair table, assert this for all 32 pairs.

## Step 3. Decode one record to a 64-hexagram sequence

A record is 32 bytes. Byte `i` (for `i` in 0..31) encodes the pair at position `i`:

    byte[i] = (pair_index << 2) | (orient << 1)

where `pair_index` is 0-31 and `orient` is 0 or 1. Bit 0 is reserved (always 0).

To decode byte `i`:

    pair_index = (byte[i] >> 2) & 0x3F
    orient     = (byte[i] >> 1) & 0x01

Then expand to positions `2i` and `2i+1` of the full sequence. Let `(a, b) = pairs[pair_index]`:

- If `orient == 0`: `seq[2i] = a`, `seq[2i+1] = b`
- If `orient == 1`: `seq[2i] = b`, `seq[2i+1] = a`

A valid record expands to a 64-element sequence of hexagram numbers, each in 0-63, containing every integer from 0 to 63 exactly once.

### Worked sanity check (the first byte)

The first byte of every record is at position `i=0`, which by **C4** must be pair 0 = (63, 0) = Creative/Receptive. So `pair_index == 0`. Then `byte[0]` is either `0x00` (orient 0) or `0x02` (orient 1). No other values for `byte[0]` should appear in a valid file; any record with `byte[0]` not in `{0, 2}` fails C4.

## Step 4. Check C1 — pair structure

Per [`SPECIFICATION.md`](SPECIFICATION.md) §C1: for all `i` in `{0, 2, 4, ..., 62}`, `seq[i+1] == partner(seq[i])`.

Equivalent check using decoded pair indices: each pair index `0..31` must appear exactly once across the 32 positions `i=0..31`. Since the decoding in Step 3 places `(a, b)` or `(b, a)` from `pairs[pair_index]` at positions `2i, 2i+1`, and your pair table is authoritative, you automatically satisfy the structural form of C1 as soon as each pair index is used exactly once.

Check:

```python
used = [0] * 32
for i in range(32):
    pi = (record[i] >> 2) & 0x3F
    if pi >= 32:
        return "C1 FAIL: pair_index out of range"
    used[pi] += 1
if any(u != 1 for u in used):
    return "C1 FAIL: pair used zero or multiple times"
```

## Step 5. Check C2 — no 5-line transitions

Per [`SPECIFICATION.md`](SPECIFICATION.md) §C2: for all `i` in `{0, 1, ..., 62}`, the Hamming distance `d(seq[i], seq[i+1]) ≠ 5`.

Hamming distance is `popcount(a XOR b)` — the number of differing bits.

```python
def hamming(a, b):
    return bin(a ^ b).count('1')

for i in range(63):
    if hamming(seq[i], seq[i+1]) == 5:
        return "C2 FAIL: 5-line transition"
```

Note: within-pair transitions (at positions `2i, 2i+1`) are provably even (see [`SPECIFICATION.md`](SPECIFICATION.md) Theorem 1 on within-pair distance), so Hamming-5 can only occur at the 31 between-pair boundaries. Your implementation can check all 63 consecutive pairs or only the between-pair ones; both are correct, the first is simpler.

## Step 6. Check C3 — complement distance

Per [`SPECIFICATION.md`](SPECIFICATION.md) §C3: `cd(S) ≤ 12.125`, where:

    cd(S) = (1/64) × Σ over h in {0..63} of |pos(h) − pos(comp(h))|

Work in integers. Let `pos[h]` be the position of hexagram `h` in `seq` (the inverse permutation). Compute:

    total = Σ over h in {0..63} of |pos[h] − pos[h ^ 63]|

The threshold `cd(S) ≤ 12.125` is exactly `total ≤ 776` (since `776 / 64 = 12.125`). Check the integer form:

```python
pos = [0] * 64
for i, h in enumerate(seq):
    pos[h] = i
total = 0
for h in range(64):
    total += abs(pos[h] - pos[h ^ 63])
if total > 776:
    return "C3 FAIL: complement distance above threshold"
```

Rationale for the `/64` divisor: every complement-pair `{h, h^63}` contributes its position delta twice (once indexed by `h`, once by `h^63`). There are 32 complement-pairs covering all 64 hexagrams (no hexagram is self-complementary under `comp`). So `total = 2 × sum_over_32_pairs(|Δpos|) = 64 × mean_per_pair`, hence divide by 64.

## Step 7. Check C4 — first pair

Per [`SPECIFICATION.md`](SPECIFICATION.md) §C4: `seq[0] == 63` and `seq[1] == 0`.

Equivalently at the record level: `(record[0] >> 2) & 0x3F == 0` (pair 0) AND `(record[0] >> 1) & 1 == 0` (natural orient). Any other value for `record[0]` violates C4.

```python
if seq[0] != 63 or seq[1] != 0:
    return "C4 FAIL: first pair not Creative/Receptive"
```

## Step 8. Check C5 — distance distribution

Per [`SPECIFICATION.md`](SPECIFICATION.md) §C5: the multiset of Hamming distances across the 63 consecutive transitions must equal exactly `{1:2, 2:20, 3:13, 4:19, 6:9}`.

Note: distances `0` and `5` do not appear. Total: `2 + 20 + 13 + 19 + 9 = 63` — one distance per transition, which matches the 63 transitions in a 64-element sequence.

```python
expected = {0: 0, 1: 2, 2: 20, 3: 13, 4: 19, 5: 0, 6: 9}
dist = {d: 0 for d in range(7)}
for i in range(63):
    d = hamming(seq[i], seq[i+1])
    if d > 6:
        return f"C5 FAIL: distance {d} exceeds 6"
    dist[d] += 1
if dist != expected:
    return f"C5 FAIL: distribution {dist} != expected {expected}"
```

## Step 9. Check King Wen presence

Compare each decoded sequence against the `KW` array from Step 2. If any record decodes to `KW` exactly, report "King Wen found". Expect exactly one canonical KW record per file (the 4 orient-variants of KW collapse to a single canonical record in the v1 format).

## Step 10. Check sort order and deduplication

Per [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Sort order, records are sorted by `compare_solutions`:

1. **Primary**: byte-by-byte lexicographic comparison with the orient bit masked out, i.e. compare `record[i] & 0xFC` for `i = 0, 1, 2, ...` until a difference is found.
2. **Secondary**: byte-by-byte lexicographic comparison of the full bytes (including orient), used only when the primary keys are equal.

This gives a total strict order on distinct records.

Per [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Deduplication semantics, the file contains **one record per canonical pair-sequence** — orient variants are collapsed. To check this, verify that no two adjacent records in the sorted stream have identical canonical form (i.e., `record[i] & 0xFC` identical for all `i`).

```python
def canonical(rec):
    return bytes(b & 0xFC for b in rec)

def compare_solutions(a, b):
    ca, cb = canonical(a), canonical(b)
    if ca < cb: return -1
    if ca > cb: return 1
    if a < b:   return -1
    if a > b:   return 1
    return 0

prev = None
prev_canonical = None
for rec in records:
    if prev is not None:
        if compare_solutions(rec, prev) <= 0:
            return "SORT FAIL: records out of order"
        if canonical(rec) == prev_canonical:
            return "DEDUP FAIL: canonical duplicate"
    prev = rec
    prev_canonical = canonical(rec)
```

## Step 11. Report results

Accumulate per-constraint failure counts and a King Wen boolean. Print a summary like:

```
Header:            ROAE v1, 135780 records
C1 failures:       0
C2 failures:       0
C3 failures:       0
C4 failures:       0
C5 failures:       0
Sort violations:   0
Duplicates:        0
King Wen found:    YES

VERIFY PASS
```

Exit 0 on pass, nonzero on any failure.

## A complete reference implementation exists

[`verify.py`](verify.py) in this repository implements the above in ~130 lines of Python. You can read it as a worked example — but its existence does NOT let you skip steps. The spirit of this exercise is that you could discard `solve.c` AND `verify.py` and rebuild a verifier from `SPECIFICATION.md` + `SOLUTIONS_FORMAT.md` + this document alone. If your implementation passes a canonical `solutions.bin` and `verify.py` also passes the same file, you have cross-validated two independent implementations against the same spec.

## A note on partition invariance

A verifier built from this recipe does not need to know how the `solutions.bin` was produced — whether by a single full-parallel invocation of the enumerator, by 56 independent single-branch runs merged together, or by any other split of the work. Under exhaustive enumeration of the same partition, all such paths produce byte-identical output. This is formalized as the Partition Invariance theorem — see [`PARTITION_INVARIANCE.md`](PARTITION_INVARIANCE.md) for the proof. Your verifier's correctness does not depend on the enumeration strategy, only on the sort and dedup semantics specified in [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md).

## Expected output on the canonical selftest file

A `solutions.bin` produced by `./solve --selftest` (or by running `SOLVE_THREADS=4 SOLVE_NODE_LIMIT=100000000 ./solve 0` in a clean directory) has:

- Header: `ROAE v1`, 135,780 records declared
- File size: 32 (header) + 135,780 × 32 = 4,344,992 bytes
- sha256: `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e`

Every constraint should pass with 0 failures, and King Wen should appear among the records. If your verifier reports anything else on this file, either your implementation has a bug or the file is corrupted.

## Gaps and limitations of this recipe

Notes on what this verifier recipe does NOT cover, so a future maintainer extending it knows what else exists:

- **Enumeration.** This recipe produces a verifier, not an enumerator. Re-implementing the search (backtracking with C5 budget pruning, the 2^32 orientation search, the sharded merge) is a substantially larger task not addressed here.
- **The C6/C7 boundary adjacencies** (from [`SPECIFICATION.md`](SPECIFICATION.md) §C6, §C7) are NOT required in `solutions.bin` — the file contains all C1–C5 solutions, and C6/C7 are additional constraints used to narrow the C1–C5 solution set toward King Wen specifically. Your verifier should NOT reject a record that fails C6 or C7; the file intentionally contains many such records. (For concrete scale: the d3 100T canonical contains 3,432,399,297 records, d3 10T contains 706,422,987, d2 10T contains 286,357,503; C6/C7 narrow from whichever canonical you are verifying against.)
- **Analysis outputs** (`--analyze` with its 24+ sections on entropy, boundary scoring, structural families, etc.) are not part of the verifier. Those are downstream interpretations of a valid `solutions.bin` and live in `solve.c`'s analysis code path.
- **Format versioning.** This recipe is written for format v1. If v2 ever exists, it will change the header layout and may change the record layout; a v1 verifier should reject v2 files loudly rather than attempt to parse them.

## Spec gaps found while writing this document

Part of the value of this exercise is surfacing places where the authoritative specs are incomplete. Three potential gaps came up while drafting; all three are now resolved:

- **C3 divisor clarity** (`|C| = 64`). [`SPECIFICATION.md`](SPECIFICATION.md) §Complement distance previously said `|C| = 60`, which was a documentation error — no hexagram is self-complementary under `comp`, so all 64 contribute to the sum. Fixed 2026-04-18 in the `docs: content fixes` commit. The formula in this document uses the correct divisor.
- **Total-order claim on `compare_solutions`**. [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Sort order previously defined the comparator but did not explicitly state it produces a total strict order on distinct records. That property is what makes sha256 reproducibility independent of sort-algorithm stability. Added 2026-04-18.
- **Lex-smallest orient variant wins dedup**. [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Deduplication now states explicitly that the deterministic choice within a canonical class is the lex-smallest orient variant by full-byte comparison. A re-implementation that keeps a different variant would produce a valid-under-C1-C5 file with a different sha256. Added 2026-04-18.

No further gaps identified. A verifier built from the current specs + this document will be correct and byte-reproducible.

## Changelog

- **2026-04-18**: Initial version. Scope: verifier only. Companion artifact: `verify.py` (Python, independently implements this recipe).
