# Rebuild from specification — independent verifier recipe

A step-by-step recipe for building an independent `solutions.bin` verifier using only this document, [SPECIFICATION.md](SPECIFICATION.md), and [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md). If you can follow the steps below in any programming language and produce a tool that reads a `solutions.bin` file and reports constraint pass/fail, then the specs stand on their own — you did not need to read `solve.c`.

## What this document is

A forcing function for spec completeness and a 20-year resilience artifact. Every question you have to answer from `solve.c` rather than from the authoritative specs is a gap in the specs and should be fixed. The companion implementation that proves this recipe works is `verify.py` in this repository — written in Python and sharing zero code with `solve.c`. What this recipe describes is its record-verification core; the file as a whole is far larger and still growing — **5,475 lines** measured 2026-09-02 by `wc -l verify.py` — because it also carries independent recount/certificate/null-law instruments (see [VERIFY.md](VERIFY.md)). This document publishes no line range for the core alone, and deliberately: an unanchored line figure for a subset of a file that grows is not checkable by a reader. (For the canonical reference C-side verifier, see `solve --verify` documented in [SOLVE_C_CLI.md](SOLVE_C_CLI.md).)

## What this document is NOT

Not an enumerator guide. A full re-implementation of the search (backtracking, hash-table dedup, sharded merge) is a separate, much larger task — the enumeration path is the bulk of `solve.c`, which measured **27,394 lines** on 2026-09-02 (`wc -l solve.c`), and it depends on subtle performance and concurrency structures. As with `verify.py` above, this document publishes no line range for the path alone. The verifier, by contrast, is purely declarative: it takes a file and checks whether it satisfies the specification. That's ~150 lines in most languages.

## What a conformant verifier must do

Your verifier reads a `solutions.bin` file and answers: *does every record satisfy the constraints, is the file sorted correctly, are there no duplicates, and is King Wen present?*

Concretely:

1. Parse and validate the 32-byte header (magic, version, record count).
2. For each 32-byte record, decode it into a 64-hexagram sequence.
3. Check each sequence against **C1** (pair structure), **C2** (no Hamming-5 transitions), **C3** (complement distance ≤ 776), **C4** (first pair = Creative/Receptive), **C5** (exact distance distribution).
4. Verify records are in sorted order as defined in `SOLUTIONS_FORMAT.md`.
5. Verify no two records are canonical duplicates (same pair-sequence).
6. Report whether the King Wen sequence appears among the records. This is **informational by default** — a budgeted slice or a merged subset legitimately need not contain King Wen — and becomes a hard requirement only when you are verifying a file that is supposed to contain it (`verify.py` promotes it under `--expect-kw` and not otherwise).
7. Report pass/fail with per-constraint counts.

Any verifier that does these seven things correctly IS a conformant implementation. There is no hidden behavior to match.

## Prerequisites

- Any programming language with: fixed-size integer types (at least `uint8`, `uint32`, `uint64`), binary file I/O, arrays, and bitwise operations.
- [`SPECIFICATION.md`](SPECIFICATION.md) — the mathematical definitions of **C1**–**C5**.
- [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) — the binary format (header + records).
- A `solutions.bin` file to verify (produced by [`solve --merge`](SOLVE_C_CLI.md#--merge) or a normal enumeration run). ⚠ **Both paths write the file gzip-framed by default** — `SOLVE_COMPRESS` is ON unless you set it to `0` (`solve.c`), and it gates the writer on the merge path and the enumeration path alike — so the default artifact begins `1f 8b`, not `ROAE`. Everything below describes the **logical (decompressed)** stream, exactly as [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §"On-disk framing" does; Step 1 sniffs for the gzip magic so that both framings parse.

## Step 1. Parse the header

Read the first 32 bytes of the file. Per [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §File header:

| Offset | Size | Field           | Must satisfy                                |
|--------|------|-----------------|---------------------------------------------|
| 0      | 4    | Magic           | ASCII `'R','O','A','E'` (`0x52 0x4F 0x41 0x45`) |
| 4      | 4    | Format version  | uint32 little-endian, must equal `1`        |
| 8      | 8    | Record count    | uint64 little-endian                        |
| 16     | 16   | Reserved        | zero-filled — **MUST be zero; reject nonzero** |

**Reject** the file if magic ≠ `'ROAE'`, if version is not a version you know, or if any of the 16 reserved bytes is nonzero. ⚠ **[CORRECTED 2026-09-01 — the header table's Reserved row read "zero-filled (advisory — tolerate nonzero)" and the Python below performed no check. Both shipped readers reject: [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §File header is normative ("MUST be zero"), and since 2026-08-28 all three C readers plus `verify.py` enforce it. Executed on a 135,780-record artifact with byte 20 set to `0x5A`: `verify.py` returns **rc=1** ("header reserved bytes NONZERO … VERIFY FAIL") and `./solve --verify` returns **rc=20** ("ERROR: header reserved byte 20 is 0x5A, must be zero (SOLUTIONS_FORMAT.md)"); the same artifact unmodified gives rc=0 from both. A verifier built from the old wording would have accepted a file both shipped verifiers reject — which defeats the point of the independence cross-check, since a disagreement is supposed to indicate a defective artifact, not a defective recipe.]** A conformant reader that does not understand a future version MUST refuse rather than guess, because the format may change in ways that would silently corrupt interpretation.

⚠ **Scope of that cross-check, measured 2026-09-02.** "Both shipped verifiers" above means `verify.py` and `solve --verify`; it does **not** extend to `verify.c --check-artifact`, the independent C instrument documented in [VERIFY.md](VERIFY.md). That mode reads the 32-byte header, checks the magic, and then reports `SCOPE=validity_sortedness_dedup_only_NOT_completeness` — header conformance is outside what it attests, and it holds no version, reserved-byte or file-geometry test. Executed on one-record artifacts built from King Wen: with `header[20]=0x5A`, with a declared format version of `2`, and with a header declaring 5 records over a 1-record body, `verify.py` returns rc=1, rc=2 and rc=2 with a named error in each case, while `verify.c --check-artifact` returns `ARTIFACT=PASS` on all three. Until that is closed in `verify.c` (queued as a code change), do not read a `verify.c` pass as agreement about the header — use `verify.py` or `solve --verify` for the header, and read `verify.c` for what its `SCOPE=` line says it checks.

After header parse, assert `file_size == 32 + record_count × 32`. If the declared count and the actual file geometry disagree, the file is corrupt — reject.

Python:

```python
import gzip

# Sniff the framing FIRST. The default artifact is gz-framed (SOLVE_COMPRESS is
# ON unless set to 0), so a reader that goes straight to the magic check rejects
# the generator's own default output. verify.py does exactly this (_is_gzip).
with open(path, 'rb') as probe:
    opener = gzip.open if probe.read(2) == b'\x1f\x8b' else open

# From here on `f` is the LOGICAL stream: the 32-byte header, the 32 + i*32
# record offsets and the file-size arithmetic below are all defined over it.
with opener(path, 'rb') as f:
    hdr = f.read(32)
    if len(hdr) < 32:
        raise ValueError("file too small for header")
    if hdr[0:4] != b'ROAE':
        raise ValueError(f"bad magic: {hdr[0:4]!r}")
    version = int.from_bytes(hdr[4:8], 'little')
    if version != 1:
        raise ValueError(f"unknown format version {version}")
    record_count = int.from_bytes(hdr[8:16], 'little')
    if hdr[16:32] != b'\x00' * 16:
        raise ValueError("header reserved bytes must be zero")
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

where `pair_index` is 0-31 and `orient` is 0 or 1. Bit 0 is reserved and **MUST be zero — validate
it, do not merely mask it away**:

    if byte[i] & 0x01:
        reject("record byte has reserved bit 0 set")
    pair_index = (byte[i] >> 2) & 0x3F
    orient     = (byte[i] >> 1) & 0x01
    if pair_index >= 32:
        reject("C1 FAIL: pair_index out of range")

⚠ **[ADDED 2026-09-01 — this step previously said only "Bit 0 is reserved (always 0)" and the
decode masked it without checking, so a rebuilt verifier accepted records both shipped readers
reject. Executed on the same 135,780-record artifact with bit 0 of record 0 byte 0 set:
`verify.py` returns **rc=1** ("Format errors: 1 (records with reserved bit 0 set)") and
`./solve --verify` returns **rc=30** ("ERROR: record 0 byte 0 = 0x01 has reserved bit 0 set; MUST
be zero per SOLUTIONS_FORMAT.md"). The bit matters beyond conformance: it is masked out of the
canonical sort key (`& 0xFC`) but participates in the full-byte dedup tie-break, so a set bit 0
silently breaks byte-exact reproducibility between two otherwise-conformant implementations
(`verify.py`, comment above the check).]**

The range test belongs **here**, before the table lookup, not in Step 4. The field is 6 bits wide, so `pair_index` decodes to 0..63, while the Step 2 table has 32 entries; a malformed byte such as `0x80` would otherwise index a 32-entry table with 32..63 and turn a reportable C1 failure into an `IndexError` or an out-of-bounds read. Step 4's permutation check (each index used exactly once) is unchanged and still needed — it is a different test, and it runs after every byte has been decoded.

⚠ **[CORRECTED 2026-09-02 — this step previously decoded `pair_index` and went straight to `pairs[pair_index]`, and the only range guard in the document sat inside Step 4's C1 snippet, one step later. A literal sequential implementation therefore dereferenced the pair table before validating the index. The defect is ordering, not arithmetic: no verdict changes for a well-formed record, but a hostile or corrupt one crashed the verifier instead of being reported.]**

Then expand to positions `2i` and `2i+1` of the full sequence. Let `(a, b) = pairs[pair_index]`:

- If `orient == 0`: `seq[2i] = a`, `seq[2i+1] = b`
- If `orient == 1`: `seq[2i] = b`, `seq[2i+1] = a`

A valid record expands to a 64-element sequence of hexagram numbers, each in 0-63, containing every integer from 0 to 63 exactly once.

### Worked sanity check (the first byte)

The first byte of every record is at position `i=0`, which by **C4** must be pair 0 = (63, 0) = Creative/Receptive. So `pair_index == 0`. Then `byte[0]` must be exactly `0x00` — pair 0 in its **natural orientation**, giving s₀ = 63 and
s₁ = 0 in that order. `0x02` (orient 1) decodes to s₀ = 0, s₁ = 63, which **fails C4**:
[`SPECIFICATION.md`](SPECIFICATION.md) §C4 fixes the anchor's *order*, not merely its pair.
Any record with `byte[0]` != `0x00` fails C4.

> ⚠ **Corrected 2026-08-27 (Q-293).** This paragraph previously said `byte[0]` could be
> `0x00` **or** `0x02`, contradicting this document's own Step 7, which states the rule correctly
> as `(record[0] >> 2) & 0x3F == 0` **AND** `(record[0] >> 1) & 1 == 0`. The permissive reading
> matched a real defect in the shipped checkers: `solve --verify` and `--validate` tested the pair
> index alone, so comp(King Wen) — which opens (0, 63) — verified clean. Both were fixed
> under Q-293; a rebuilder following the old paragraph would have reproduced the defect.

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

Compare each decoded sequence against the `KW` array from Step 2. If any record decodes to `KW` exactly, report "King Wen found".

A file holds **at most one** canonical King Wen record. In the v1 format every C4-oriented valid orient-variant of King Wen's pair sequence collapses to that single record, and there are **1,720,320** of them — `3·5·7·2^14`, recomputed independently by the 31-step transfer DP behind `python3 verify.py --recount-fiber` and cross-checked against [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Deduplication semantics.

**Absence is not a failure.** A `solutions.bin` is the slice its producing run reached within its node budget, and a shard or a merged subset legitimately need not contain King Wen. Treat the check as informational and let the caller demand it: `verify.py` reports the line either way and only `--expect-kw` promotes a miss to a nonzero exit.

⚠ **[CORRECTED 2026-09-02 — this step previously told a rebuilder to expect a King Wen record in every file, and put the size of King Wen's collapsed orientation class at 4. Both are wrong. The count is off by a factor of 430,080 against the recount instrument above; and requiring presence contradicts `verify.py`, whose own comment on the check reads that a shard "legitimately need not contain King Wen". A verifier built from the old wording would have failed valid shards and would have carried a cardinality no instrument in this repository supports.]**

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

[`verify.py`](../verify.py) in this repository implements the above in a ~130-line record-verification core (the file as a whole is now ~1,500 lines — it has since grown independent recount/certificate/null-law instruments, see [VERIFY.md](VERIFY.md)). You can read it as a worked example — but its existence does NOT let you skip steps. The spirit of this exercise is that you could discard `solve.c` AND `verify.py` and rebuild a verifier from `SPECIFICATION.md` + `SOLUTIONS_FORMAT.md` + this document alone. If your implementation passes a canonical `solutions.bin` and `verify.py` also passes the same file, you have cross-validated two independent implementations against the same spec.

## A note on partition invariance

A verifier built from this recipe does not need to know how the `solutions.bin` was produced — whether by a single full-parallel invocation of the enumerator, by 56 independent single-branch runs merged together, or by any other split of the work. Under exhaustive enumeration of the same partition, all such paths produce byte-identical output. This is formalized as the Partition Invariance theorem — see [`PARTITION_INVARIANCE.md`](PARTITION_INVARIANCE.md) for the proof. Your verifier's correctness does not depend on the enumeration strategy, only on the sort and dedup semantics specified in [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md).

## Expected output on the canonical selftest file

A `solutions.bin` produced by `./solve --selftest` has:

- Header: `ROAE v1`, 135,780 records declared
- File size: 32 (header) + 135,780 × 32 = 4,344,992 bytes
- sha256 of the **logical** (decompressed) stream:
  `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e`

To reach that anchor from a shell instead of through `--selftest`, you have to reproduce the child
**environment** that `--selftest` builds, not two settings out of it. `solve.c` forks its selftest
child with a wildcard scrub of every inherited `SOLVE_*` variable followed by nine explicit
settings; without the scrub the command inherits whatever `SOLVE_*` the caller had exported, and a
single leaked variable can change the output or suppress the auto-merge that writes
`solutions.bin` at all. The standalone equivalent is:

```sh
cd "$(mktemp -d)" && \
for v in $(env | grep '^SOLVE_' | cut -d= -f1); do unset "$v"; done && \
SOLVE_THREADS=4 SOLVE_NODE_LIMIT=100000000 \
SOLVE_ALLOW_SUB_CANONICAL=1 SOLVE_SKIP_CANONICAL_LOCK=1 \
SOLVE_SKIP_AUTO_SELFTEST=1 SOLVE_SKIP_DISK_CHECK=1 \
SOLVE_SKIP_BINARY_SNAPSHOT=1 SOLVE_SKIP_AUTO_MANIFEST=1 \
SOLVE_SKIP_IOPS_CHECK=1 \
/path/to/solve 0 && \
{ gzip -dc solutions.bin 2>/dev/null || cat solutions.bin; } | sha256sum
```

What the nine settings are for:

- `SOLVE_THREADS=4` and `SOLVE_NODE_LIMIT=100000000` fix the shape of the run. The budget is a
  per-sub-branch node limit rather than a wall-clock limit precisely so the result is byte-exact
  across thread counts and machines.
- `SOLVE_ALLOW_SUB_CANONICAL=1` — the 100M-node budget is below the 1 T sub-canonical hard-gate
  (see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"100B and sub-canonical reference shas", the
  "Sub-canonical hard-gate" paragraph); without this override the run exits 25 and writes nothing.
- The six `SOLVE_SKIP_*` settings disable hardening preflights — the recursive auto-selftest, the
  canonical lock, the disk and IOPS checks, the binary snapshot and the auto-manifest — that belong
  to a production enumeration and not to a 100M-node conformance run.

`SOLVE_COMPRESS` is deliberately **absent** from that command. `--selftest` never sets it: the fork
leaves compression at its default (ON since #169, magic `1f 8b`) and hashes
`gzip -dc solutions.bin || cat solutions.bin`, which is exactly the pipeline above. If you would
rather have raw bytes on disk — so that `sha256sum solutions.bin` matches the anchor directly and
the file carries the `ROAE` magic without the Step-1 gzip sniff — add `SOLVE_COMPRESS=0`. That is a
convenience for the on-disk form, an **addition** to what `--selftest` does rather than part of it,
and it changes neither the logical stream nor its sha.

⚠ **[CORRECTED 2026-09-02 — this section presented a four-variable one-liner as "equivalently"
reproducing `./solve --selftest`, and said that "two settings" were required. Measured against the
`snprintf` in `solve.c` that builds the child command: the fork applies a wildcard `SOLVE_*` scrub
plus nine settings, of which the published command carried three, and it *added* `SOLVE_COMPRESS=0`,
which the fork never sets. The old command reproduces the anchor only from an environment that
happens to export no other `SOLVE_*` — the condition the word "equivalently" concealed, and the
condition its 2026-07-26 "verified on a clean build" note silently assumed. The anchor
`403f7202…` itself is unchanged and was not re-derived for this correction.]**

Every constraint should pass with 0 failures, and King Wen should appear among the records. If your verifier reports anything else on this file, either your implementation has a bug or the file is corrupted.

## Gaps and limitations of this recipe

Notes on what this verifier recipe does NOT cover, so a future maintainer extending it knows what else exists:

- **Enumeration.** This recipe produces a verifier, not an enumerator. Re-implementing the search (backtracking with C5 budget pruning, the per-key **2^31** orientation search — C4 pins slot 0's orientation, leaving 31 of the 32 orientation bits free, the figure [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Deduplication semantics states — and the sharded merge) is a substantially larger task not addressed here. *(The exponent read 2^32 until 2026-09-02, double the recoverable space the authoritative format document names.)*
- **The C6/C7 boundary adjacencies** (from [`SPECIFICATION.md`](SPECIFICATION.md) §C6, §C7) are NOT required in `solutions.bin` — the file holds the C1–C5 solutions its producing run reached **within that run's node budget**, an exactly-reproducible *slice* whose record count is a **lower bound** on the C1–C5 space and never its cardinality ([`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Overview) — and C6/C7 are additional constraints used to narrow the C1–C5 solution set toward King Wen specifically. Your verifier should NOT reject a record that fails C6 or C7; the file intentionally contains many such records. (For concrete scale, each figure a per-artifact record count and therefore a lower bound rather than a population size: the d3 100T canonical contains 3,432,399,297 records, d3 10T contains 706,427,594, d2 10T contains 286,357,503; C6/C7 narrow from whichever canonical you are verifying against.) ⚠ **[CORRECTED 2026-09-02 — this bullet described the artifact as holding the complete C1–C5 population. [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Overview retired exactly that reading on 2026-08-28, and the correction did not reach this recipe: every enumeration this project publishes is budgeted, so the file is a slice and its count a floor. No record count changes; what changes is what a count means.]**
- **Analysis outputs** ([`--analyze`](SOLVE_C_CLI.md#--analyze) with its 24+ sections on entropy, boundary scoring, structural families, etc.) are not part of the verifier. Those are downstream interpretations of a valid `solutions.bin` and live in `solve.c`'s analysis code path.
- **Format versioning.** This recipe is written for format v1. If v2 ever exists, it will change the header layout and may change the record layout; a v1 verifier should reject v2 files loudly rather than attempt to parse them.

## Spec gaps found while writing this document

Part of the value of this exercise is surfacing places where the authoritative specs are incomplete. Three potential gaps came up while drafting; all three are now resolved:

- **C3 divisor clarity** (`|C| = 64`). [`SPECIFICATION.md`](SPECIFICATION.md) §Complement distance previously said `|C| = 60`, which was a documentation error — no hexagram is self-complementary under `comp`, so all 64 contribute to the sum. Fixed 2026-04-18 in the `docs: content fixes` commit. The formula in this document uses the correct divisor.
- **Total-order claim on `compare_solutions`**. [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Sort order previously defined the comparator but did not explicitly state it produces a total strict order on distinct records. That property is what makes sha256 reproducibility independent of sort-algorithm stability. Added 2026-04-18.
- **Which orient variant survives dedup**. [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Deduplication states the rule, and states it *conditionally*: `solve.c` keeps a running byte-wise minimum over the orient variants a run actually inserts, which is **not** the class-global minimum, because every enumeration this project publishes is budgeted and therefore visits only part of each class. A re-implementation that keeps a different variant would produce a valid-under-C1-C5 file with a different sha256. Added 2026-04-18; **restated 2026-09-02** — this bullet had reported the rule as an unconditional class-global lexicographic minimum over full bytes, the form [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) itself withdrew on 2026-09-01 and this document did not follow.

No further gaps identified as of 2026-04-18.

A verifier built from the current specs + this document will be **correct**: it accepts exactly the files that satisfy C1-C5, the sort order and the dedup rule, and rejects the rest. It does **not** thereby establish byte-reproducibility, and Steps 1-11 cannot. Step 10 tests strict ordering on the masked key and canonical-duplicate adjacency; nothing in the file lets it test *which* orient variant of a canonical class was retained, because the competing variants are precisely what dedup removed. Byte-reproducibility is a property of the **producer**, and the bullet immediately above says so.

The repository does ship an instrument for the representative question — `python3 verify.py --check-repr` and `verify.c --check-repr`, which recompute the lexicographically least valid orientation completion of a record's pair key from the definition rather than from `solve.c`. It is deliberately **not** part of `--check-artifact`, and folding it in there would be wrong rather than merely expensive: `solutions.bin` is a pre-normalization artifact, so a raw merge output disagrees with the global representative on a regionally varying 1.06%-42.2% of records (measured 2026-08-15 over 1,776,347,935 records, INCOMPUTABLE=0 throughout), and the normalizing post-pass that would make agreement the right expectation is on no published ref in this tree — see [VERIFY.md](VERIFY.md), its `--check-repr` row and its "NOT AVAILABLE IN THIS TREE" box. Read `--check-repr` as the acceptance test for that post-pass's output, not as a conformance step this recipe owes a rebuilder.

⚠ **[CORRECTED 2026-09-02 — the sentence opening this block used to run on and pair correctness with an unconditional byte-reproducibility guarantee (the retired wording is registered in [`RETRACTED_PHRASES.tsv`](RETRACTED_PHRASES.tsv), not requoted here). It contradicted this section's own preceding bullet two lines earlier. Executed on this tree: a two-record artifact holding natural King Wen plus a C1-C5-valid but non-minimal orient variant of a second pair key returns `VERIFY PASS` from `verify.py` even under `--expect-kw`, and `ARTIFACT=PASS` from `verify.c --check-artifact` — both correctly, since neither mode claims the representative property; `verify.py --check-repr` on the same file reports `AGREE=1 DISAGREE=1` and `CHECK_REPR=FAIL`, which is the instrument that does. The claim was not merely stale: byte-reproducibility was never the verifier's to certify.]**

> ⚠ **Updated 2026-09-01 — a fourth gap, and this claim is only as fresh as its last audit.** The
> two reserved fields (header bytes 16-31, and bit 0 of every record byte) were described here as
> advisory while [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) called them normative, and the 2026-08-28
> hardening pass that made all three C readers plus `verify.py` enforce them did not reach this
> document. A verifier built from the pre-correction recipe accepted artifacts both shipped verifiers
> reject — the failure mode this recipe exists to prevent, since independent verification only works
> if a disagreement means a defective artifact rather than a defective recipe. Both are fixed above,
> with the executed rc values recorded. The correctness claim at the head of this section is
> therefore scoped: it holds against the specs as audited on the dates listed here, and re-earning it
> after any change to the normative spec is part of that change, not a separate task.
>
> **2026-09-02 addendum.** "All three C readers" above means the three inside `solve.c`, and "both
> shipped verifiers" means `verify.py` and `solve --verify`. It does not extend to
> `verify.c --check-artifact`, which enforces neither reserved field nor the version nor the file
> geometry — measured 2026-09-02, with the executed verdicts recorded under the
> Step-1 header table. The recipe is fixed; the `verify.c` divergence is disclosed and open, and is
> queued as a code change.

## Changelog

- **2026-04-18**: Initial version. Scope: verifier only. Companion artifact: `verify.py` (Python, independently implements this recipe).
- **2026-09-01**: Reserved-field conformance brought into line with the normative spec and the shipped readers (propagation of the 2026-08-28 hardening, which had not reached this document). Header bytes 16-31 and record bit 0 both change from "advisory / tolerate" to "MUST be zero — reject", in the prose, in the header table, and in the supplied Python. Verified by execution against both shipped readers on a clean and on a corrupted copy of the same 135,780-record artifact. No change to the pair table, the constraint checks, the sort order, or the dedup rule.
- **2026-09-02**: Eight corrections from the Codex V2-F48 review pass, seven of them applied as charged and one applied against its own prescription. (1) The recipe described `solutions.bin` as the complete C1-C5 population in two places; it is the slice a budgeted run reached, and its record count is a floor — the 2026-08-28 correction in `SOLUTIONS_FORMAT.md` §Overview had not propagated here. (2) King Wen presence changed from required to informational, matching `verify.py`, and King Wen's collapsed orientation class corrected from 4 to 1,720,320 against `verify.py --recount-fiber`. (3) The enumerator's per-key orientation space corrected 2^32 → 2^31. (4) Step 1 now sniffs the gzip magic, because the generator's default output is gz-framed and the old Step 1 rejected it. (5) The `pair_index` range test moved from Step 4 into Step 3, ahead of the pair-table lookup it guards. (6) The standalone `--selftest` command replaced with the environment `solve.c` actually builds: a wildcard `SOLVE_*` scrub plus nine settings, with `SOLVE_COMPRESS=0` relabelled an addition rather than a requirement. (7) The closing claim of this document's §Spec gaps section split: correctness stands, byte-reproducibility is the producer's property and is not testable by Steps 1-11 — and the review's prescribed fix, wiring the repr oracle into `--check-artifact`, is **not** adopted, because `solutions.bin` is a pre-normalization artifact against which that check is expected to disagree. (8) Stale size figures for `verify.py` and `solve.c` replaced with dated measurements. Also disclosed, and new: `verify.c --check-artifact` does not enforce the header conformance that `verify.py` and `solve --verify` do; the `verify.c` fix is queued to the code lane. No change to the pair table, the constraint checks, the sort order, the dedup rule, or the `403f7202…` anchor.

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*
