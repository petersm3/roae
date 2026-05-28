#!/usr/bin/env python3
"""Independent constraint verifier for solutions.bin.

Reads every record, reconstructs the 64-hexagram sequence, and checks
C1 (pair structure), C2 (no hamming-5 transitions), C3 (complement
distance <= 776), C4 (starts with Creative/Receptive), C5 (exact
distance distribution). Also checks sorted order and duplicates.
Different language, different implementation, no shared code with
solve.c — a genuine second opinion.

Usage:
    python3 verify.py [solutions.bin]
    python3 verify.py [solutions.bin] --jobs N

--jobs N parallelizes via multiprocessing for large files. With N = 1
(default) behavior is identical to the single-threaded original.
N should typically be set to the number of physical cores. The output
must match --jobs 1 byte-for-byte (modulo the header line that prints
the chosen worker count).
"""
import sys, struct, argparse, multiprocessing

KW = [
    63,  0, 17, 34, 23, 58,  2, 16, 55, 59,  7, 56, 61, 47,  4,  8,
    25, 38,  3, 48, 41, 37, 32,  1, 57, 39, 33, 30, 18, 45, 28, 14,
    60, 15, 40,  5, 53, 43, 20, 10, 35, 49, 31, 62, 24,  6, 26, 22,
    29, 46,  9, 36, 52, 11, 13, 44, 54, 27, 50, 19, 51, 12, 21, 42,
]
PAIRS = [(KW[2*i], KW[2*i+1]) for i in range(32)]
KW_DIST = [0] * 7
for i in range(63):
    KW_DIST[bin(KW[i] ^ KW[i+1]).count('1')] += 1
START_PAIR = 0  # Creative/Receptive

def hamming(a, b):
    return bin(a ^ b).count('1')

def compute_comp_dist(seq):
    """C3: sum of |pos[v] - pos[v^63]| over all v in 0..63.
    Bitwise complement; hexagram i's complement is i^63 (flip all 6 bits).
    Each complement pair contributes its absolute positional distance twice
    (once for each direction). KW's value is exactly 776 (= 12.125 × 64).
    The C3 constraint is total <= 776 (KW sets the ceiling)."""
    pos = [0] * 64
    for i, v in enumerate(seq):
        pos[v] = i
    total = 0
    for v in range(64):
        comp = v ^ 63
        total += abs(pos[v] - pos[comp])
    return total

# Derive the C3 ceiling from KW itself (same source of truth as solve.c)
KW_COMP_DIST = compute_comp_dist(KW)
assert KW_COMP_DIST == 776, f"internal error: KW complement distance is {KW_COMP_DIST}, expected 776"

def decode(record):
    seq = []
    pairs_used = [0] * 32
    for i in range(32):
        pidx = (record[i] >> 2) & 0x3F
        orient = (record[i] >> 1) & 1
        if pidx >= 32:
            return None, None, None
        pairs_used[pidx] += 1
        a, b = PAIRS[pidx]
        if orient == 0:
            seq.extend([a, b])
        else:
            seq.extend([b, a])
    return seq, pairs_used, (record[0] >> 2) & 0x3F

def canonical(record):
    return bytes(b & 0xFC for b in record)

SOL_HEADER_SIZE = 32
SOL_FORMAT_VERSION = 1

def parse_header(data):
    """Returns declared record_count, or raises ValueError on bad header."""
    if len(data) < SOL_HEADER_SIZE:
        raise ValueError(f"file too small ({len(data)} bytes) to contain 32-byte header")
    if data[0:4] != b"ROAE":
        raise ValueError(f"bad magic: got {data[0:4]!r}, expected b'ROAE'")
    (version,) = struct.unpack("<I", data[4:8])
    if version != SOL_FORMAT_VERSION:
        raise ValueError(f"unsupported format version {version} (this reader knows version {SOL_FORMAT_VERSION})")
    (record_count,) = struct.unpack("<Q", data[8:16])
    return record_count

def verify_chunk(args):
    """Verify records [start, end) of `path`. Returns dict of counts plus
    boundary state for inter-chunk stitching.

    All per-record checks (C1-C5, decode, kw_found) are local to the chunk.
    Sort and dup checks within the chunk are local; cross-chunk boundary
    sort/dup is stitched by the parent.
    """
    path, start, end = args
    n_chunk = end - start
    if n_chunk <= 0:
        return {
            'fail_c1': 0, 'fail_c2': 0, 'fail_c3': 0, 'fail_c4': 0, 'fail_c5': 0,
            'fail_decode': 0, 'fail_sort': 0, 'fail_dup': 0,
            'kw_found': False,
            'first_canonical': None, 'first_rec': None,
            'last_canonical': None, 'last_rec': None,
            'count': 0,
        }
    # Stream-read in 1M-record batches (32 MB each) to bound memory.
    # Previously loaded the full chunk (~6.87 GB at --jobs 16 on a 110 GB
    # solutions.bin) which forced N workers × chunk_size = file_size of
    # total memory regardless of N — caused swap-thrash on any VM with
    # RAM < file_size. Streamed batches: total memory ≈ N × 32 MB.
    BATCH_RECORDS = 1024 * 1024  # 1M records = 32 MB per batch
    fail_c1 = fail_c2 = fail_c3 = fail_c4 = fail_c5 = 0
    fail_decode = fail_sort = fail_dup = 0
    kw_found = False
    prev_canonical = None
    prev_rec = None
    first_canonical = None
    first_rec = None

    f = open(path, 'rb')
    try:
        f.seek(SOL_HEADER_SIZE + start * 32)
        records_read = 0
        # Load the first batch as `chunk`; refill in-loop when exhausted.
        chunk = f.read(min(BATCH_RECORDS, n_chunk) * 32)
        chunk_records = len(chunk) // 32
        if chunk_records == 0 or len(chunk) % 32 != 0:
            raise IOError(f"verify_chunk: short or unaligned read at start={start}: got {len(chunk)} bytes")
    except Exception:
        f.close()
        raise

    for r_global in range(n_chunk):
        r_in_batch = r_global - records_read
        if r_in_batch >= chunk_records:
            # Refill the batch: free old chunk, read next batch.
            records_read += chunk_records
            remaining = n_chunk - records_read
            if remaining <= 0:
                break
            chunk = f.read(min(BATCH_RECORDS, remaining) * 32)
            chunk_records = len(chunk) // 32
            if chunk_records == 0 or len(chunk) % 32 != 0:
                f.close()
                raise IOError(f"verify_chunk: short or unaligned read mid-stream at offset {records_read}")
            r_in_batch = 0
        rec = chunk[r_in_batch*32:(r_in_batch+1)*32]
        seq, pairs_used, first_pair = decode(rec)

        if seq is None:
            fail_decode += 1
            continue

        # C1: each pair used exactly once
        if any(c != 1 for c in pairs_used):
            fail_c1 += 1

        # C4: first pair is Creative/Receptive
        if first_pair != START_PAIR:
            fail_c4 += 1

        # C2: no hamming-5 transitions
        if any(hamming(seq[i], seq[i+1]) == 5 for i in range(63)):
            fail_c2 += 1

        # C5: distance distribution matches KW
        dist = [0] * 7
        for i in range(63):
            d = hamming(seq[i], seq[i+1])
            if d <= 6:
                dist[d] += 1
        if dist != KW_DIST:
            fail_c5 += 1

        # C3: complement distance <= KW's value (776)
        if compute_comp_dist(seq) > KW_COMP_DIST:
            fail_c3 += 1

        can = canonical(rec)
        if first_canonical is None:
            first_canonical = can
            first_rec = rec
        if prev_canonical is not None:
            if can < prev_canonical:
                fail_sort += 1
            elif can == prev_canonical and rec < prev_rec:
                fail_sort += 1
            if can == prev_canonical:
                fail_dup += 1
        prev_canonical = can
        prev_rec = rec

        if seq == KW:
            kw_found = True

    f.close()
    return {
        'fail_c1': fail_c1, 'fail_c2': fail_c2, 'fail_c3': fail_c3,
        'fail_c4': fail_c4, 'fail_c5': fail_c5,
        'fail_decode': fail_decode, 'fail_sort': fail_sort, 'fail_dup': fail_dup,
        'kw_found': kw_found,
        'first_canonical': first_canonical, 'first_rec': first_rec,
        'last_canonical': prev_canonical, 'last_rec': prev_rec,
        'count': n_chunk,
    }

def stitch_boundary(prev_chunk, next_chunk):
    """Given two adjacent chunk results, return (sort_inc, dup_inc) for the
    boundary record pair: prev_chunk's last vs next_chunk's first.
    Mirrors the per-record sort+dup logic from verify_chunk."""
    p_can = prev_chunk['last_canonical']
    p_rec = prev_chunk['last_rec']
    n_can = next_chunk['first_canonical']
    n_rec = next_chunk['first_rec']
    if p_can is None or n_can is None:
        return 0, 0
    sort_inc = 0
    dup_inc = 0
    if n_can < p_can:
        sort_inc += 1
    elif n_can == p_can and n_rec < p_rec:
        sort_inc += 1
    if n_can == p_can:
        dup_inc += 1
    return sort_inc, dup_inc

def enumerate_reference(npairs):
    """Independent completeness reference on a REDUCED npairs-pair problem.

    Enumerates the complete set of valid arrangements of the first `npairs`
    KW-derived pairs under the structural constraints that reduce cleanly to a
    truncated sequence — C1 (each pair once), C2 (no hamming-5 transition
    between consecutive hexagrams), C4 (pair 0 = Creative/Receptive placed
    first; either orientation). C3/C5 are GLOBAL (defined over the full
    64-hexagram sequence vs KW's distribution) and do NOT reduce, so they are
    intentionally excluded here.

    Runs the enumeration TWO independent ways and asserts identical result sets:
      A. generate-all-then-filter  (exhaustive ground truth — no pruning)
      B. prune-as-you-go DFS       (C2 checked at each placement — mirrors how
                                    solve.c prunes during its walk)
    If B != A, a pruning step dropped or added a valid sequence — exactly the
    "did an optimization silently drop a real solution" failure class. This is
    independent of solve.c (different language, separate enumerator) and of the
    verify.py per-record checker; it grounds the constraint/pruning SEMANTICS.

    SCOPE LIMIT (honest): this validates the structural-constraint enumeration
    logic on a reduced problem. It does NOT differential-test solve.c's full
    enumeration — that is infeasible (solve.c never exhausts any cell; global
    C3/C5 don't reduce; solve.c has no reduced-pair mode). solve.c prune
    completeness at canonical scale is covered empirically by the K-pilots
    (v1 ⊆ v1+prunes at every tested scale, tasks #80/#85/#86)."""
    import itertools
    if npairs < 2 or npairs > 9:
        print(f"ERROR: --enumerate-reference N requires 2 <= N <= 9 (got {npairs}); "
              f"N>9 is too slow for the exhaustive ground-truth pass")
        return 2
    pairs = PAIRS[:npairs]
    rest = list(range(1, npairs))  # non-start pair indices; pair 0 is fixed first (C4)

    def c2_ok_full(seq):
        return all(hamming(seq[i], seq[i+1]) != 5 for i in range(len(seq) - 1))

    def build(order, orients):
        seq = []
        for slot, pi in enumerate(order):
            a, b = pairs[pi]
            seq.extend((a, b) if orients[slot] == 0 else (b, a))
        return tuple(seq)

    # --- Method A: exhaustive generate-all, then filter by C2 (ground truth) ---
    setA = set()
    candidates_A = 0
    for perm in itertools.permutations(rest):
        order = (0,) + perm
        for ob in range(1 << npairs):
            orients = [(ob >> j) & 1 for j in range(npairs)]
            candidates_A += 1
            seq = build(order, orients)
            if c2_ok_full(seq):
                setA.add(seq)

    # --- Method B: prune-as-you-go DFS (C2 enforced incrementally) ---
    setB = set()
    used = [False] * npairs

    def dfs(seq, placed):
        if placed == npairs:
            setB.add(tuple(seq))
            return
        for pi in range(npairs):
            if used[pi]:
                continue
            a, b = pairs[pi]
            for (h0, h1) in ((a, b), (b, a)):
                # incremental C2: check the new internal + boundary transitions
                if seq and hamming(seq[-1], h0) == 5:
                    continue
                if hamming(h0, h1) == 5:
                    continue
                used[pi] = True
                seq.append(h0); seq.append(h1)
                dfs(seq, placed + 1)
                seq.pop(); seq.pop()
                used[pi] = False

    # C4: pair 0 first, both orientations
    a0, b0 = pairs[0]
    for (h0, h1) in ((a0, b0), (b0, a0)):
        if hamming(h0, h1) == 5:
            continue
        used[0] = True
        dfs([h0, h1], 1)
        used[0] = False

    print(f"=== verify.py --enumerate-reference {npairs} ===")
    print(f"Reduced problem: first {npairs} KW pairs, constraints C1+C2+C4 "
          f"(C3/C5 are global, excluded — see docstring)")
    print(f"Method A (exhaustive generate+filter): {candidates_A:,} candidates -> {len(setA):,} valid")
    print(f"Method B (prune-as-you-go DFS):        {len(setB):,} valid")
    if setA == setB:
        print(f"PASS: both methods produce the IDENTICAL {len(setA):,}-sequence set "
              f"(prune-as-you-go drops/adds nothing vs exhaustive)")
        return 0
    only_a = len(setA - setB)
    only_b = len(setB - setA)
    print(f"FAIL: sets differ — only in A (exhaustive): {only_a}, only in B (pruned): {only_b}")
    print("      A pruning step is unsound/incomplete. Investigate before trusting the predicate.")
    return 1


def main():
    parser = argparse.ArgumentParser(description="Independent two-language constraint verifier for solutions.bin")
    parser.add_argument('path', nargs='?', default='solutions.bin', help='solutions.bin path')
    parser.add_argument('--jobs', type=int, default=1,
                        help='Parallel workers (default 1 = single-thread, identical to legacy behavior). '
                             'Recommended: number of physical cores.')
    parser.add_argument('--enumerate-reference', type=int, metavar='NPAIRS', default=None,
                        help='Independent completeness reference: brute-force the reduced NPAIRS-pair '
                             'problem (C1+C2+C4) two ways (exhaustive vs prune-as-you-go) and assert '
                             'identical sets. Does NOT read solutions.bin. 2<=NPAIRS<=9.')
    args = parser.parse_args()

    if args.enumerate_reference is not None:
        sys.exit(enumerate_reference(args.enumerate_reference))

    path = args.path
    n_jobs = max(1, args.jobs)

    # Read header from main process to validate format and get record count.
    with open(path, 'rb') as f:
        head = f.read(SOL_HEADER_SIZE)
    try:
        declared_records = parse_header(head)
    except ValueError as e:
        print(f"ERROR: invalid solutions.bin header: {e}")
        sys.exit(2)

    import os
    file_size = os.path.getsize(path)
    record_bytes = file_size - SOL_HEADER_SIZE
    if record_bytes % 32 != 0:
        print(f"ERROR: record stream size {record_bytes} not a multiple of 32")
        sys.exit(2)
    n = record_bytes // 32
    if n != declared_records:
        print(f"ERROR: header declares {declared_records} records but file has {n}")
        sys.exit(2)
    print(f"Header: ROAE v{SOL_FORMAT_VERSION}, {n:,} records")
    print(f"Verifying {n:,} records from {path} ({file_size:,} bytes total, "
          f"{SOL_HEADER_SIZE} header + {record_bytes:,} records)")
    if n_jobs > 1:
        print(f"Parallel: {n_jobs} workers")

    # Split records into n_jobs approximately-equal chunks.
    if n_jobs == 1 or n < n_jobs:
        chunks = [(path, 0, n)]
    else:
        chunk_size = n // n_jobs
        bounds = [(path, i * chunk_size, (i + 1) * chunk_size) for i in range(n_jobs)]
        # Last chunk absorbs the remainder.
        last_path, last_start, _ = bounds[-1]
        bounds[-1] = (last_path, last_start, n)
        chunks = bounds

    # Verify chunks in parallel.
    if n_jobs == 1:
        results = [verify_chunk(chunks[0])]
    else:
        ctx = multiprocessing.get_context('fork')
        with ctx.Pool(processes=n_jobs) as pool:
            # imap preserves order, which we need for boundary stitching.
            results = list(pool.imap(verify_chunk, chunks))

    # Aggregate per-chunk counters.
    fail_c1 = sum(r['fail_c1'] for r in results)
    fail_c2 = sum(r['fail_c2'] for r in results)
    fail_c3 = sum(r['fail_c3'] for r in results)
    fail_c4 = sum(r['fail_c4'] for r in results)
    fail_c5 = sum(r['fail_c5'] for r in results)
    fail_decode = sum(r['fail_decode'] for r in results)
    fail_sort = sum(r['fail_sort'] for r in results)
    fail_dup = sum(r['fail_dup'] for r in results)
    kw_found = any(r['kw_found'] for r in results)
    total_count = sum(r['count'] for r in results)

    # Stitch inter-chunk boundaries: chunk i's LAST vs chunk i+1's FIRST.
    for i in range(len(results) - 1):
        s_inc, d_inc = stitch_boundary(results[i], results[i + 1])
        fail_sort += s_inc
        fail_dup += d_inc

    # Sanity: ensure every record was visited exactly once.
    if total_count != n:
        print(f"INTERNAL ERROR: chunks covered {total_count:,} records, expected {n:,}")
        sys.exit(3)

    print(f"\n--- Results ---")
    print(f"Records:        {n:,}")
    print(f"C1 failures:    {fail_c1}")
    print(f"C2 failures:    {fail_c2}")
    print(f"C3 failures:    {fail_c3}  (ceiling: {KW_COMP_DIST} = KW's complement distance)")
    print(f"C4 failures:    {fail_c4}")
    print(f"C5 failures:    {fail_c5}")
    print(f"Decode errors:  {fail_decode}")
    print(f"Sort errors:    {fail_sort}")
    print(f"Duplicates:     {fail_dup}")
    print(f"King Wen:       {'YES' if kw_found else 'No'}")

    total_fail = fail_c1 + fail_c2 + fail_c3 + fail_c4 + fail_c5 + fail_decode + fail_sort + fail_dup
    if total_fail == 0:
        print(f"\nVERIFY PASS: all {n:,} records satisfy C1-C5, sorted, no duplicates")
        sys.exit(0)
    else:
        print(f"\nVERIFY FAIL: {total_fail} issues")
        sys.exit(1)

if __name__ == "__main__":
    main()
