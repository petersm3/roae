#!/usr/bin/env python3
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
"""Independent constraint verifier AND independent re-counter for the ROAE
King Wen results — a genuine second opinion answering TR-11 §10vi.

This file now independently verifies BOTH kinds of published result:

  (1) the RECORDS in solutions.bin — reads every record, reconstructs the
      64-hexagram sequence, and checks C1 (pair structure), C2 (no hamming-5
      transitions), C3 (complement distance <= 776), C4 (starts with
      Creative/Receptive), C5 (exact distance distribution), plus sorted
      order and duplicates.  [default mode / --enumerate-reference]

  (2) the exact COUNTS — `--recount` independently reproduces the small-n
      structural facts (the 32 pairs, within-pair multiset, XOR-product set,
      C3 = 776, the 48/24 symmetry group + King Wen's 24-record orbit) and the
      reduced-rung C1∩C2∩C4 union counts (U1/U2/U3 from TR-11's Verification
      Guide) by an independent COUNTING RECURRENCE — a plain (mask, last)
      layered subset DP with NO symmetry quotient, so a conceptual bug in
      solve.c's symmetry-quotient DP would NOT be shared. Since 2026-07-21 this
      also covers the **C5 ladder** (C1∩C2∩C4∩C5 — TR-11 §4b rungs n=9/13/16):
      each rung's target budget B0 is re-derived independently by §5's
      first-completion DFS (not taken from the published table) and the rung is
      then counted by a plain budgeted (mask,last,p) DP. The C5 layer — until
      now the only constraint with no independent re-count at all, and the one
      the full-31 integer rests on most heavily — therefore has one.

Different language, different implementation, standard-library only, NO import
of solve.c / solve.py / roae.py / sat.py — every quantity is rebuilt from the
published mathematical definitions (SPECIFICATION.md constraints C1–C5,
rev/comp/partner, the symmetry group; TR-11's reduced-rung tables).

Usage:
    python3 verify.py [solutions.bin]              # verify records
    python3 verify.py [solutions.bin] --jobs N     # parallel record verify
    python3 verify.py --enumerate-reference N       # small-n brute-force (2<=N<=9)
    python3 verify.py --recount                     # independent count reproduction

--jobs N parallelizes via multiprocessing for large files. With N = 1
(default) behavior is identical to the single-threaded original.
N should typically be set to the number of physical cores. The output
must match --jobs 1 byte-for-byte (modulo the header line that prints
the chosen worker count).

Companion write-up (match table, method, corroboration chain, and the
reduced-C5-ladder definitional gap this instrument surfaced):
documentation/VERIFY.md.
"""
import sys, struct, argparse, multiprocessing, gzip, tempfile, atexit, os, shutil

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


# ============================================================================
# INDEPENDENT RE-COUNTING  (--recount)  — answers TR-11 §10vi.
#
# Everything below is rebuilt clean-room from the published mathematical
# definitions. It shares NO code with solve.c/solve.py and imports nothing but
# the standard library. The counting method is deliberately DIFFERENT from
# solve.c's symmetry-quotient DP: a plain (mask, last) layered subset DP that
# stores every mask (no canonicalization), cross-checked at small n against the
# even-more-primitive exhaustive backtracking already in --enumerate-reference.
# All arithmetic is exact Python big integers. Memory is bounded by the number
# of live DP states (tens of MB), never by the astronomically large solution
# set.
# ============================================================================

def _rev6(n):
    """Bit reversal of a 6-bit integer (SPECIFICATION.md rev)."""
    r = 0
    for i in range(6):
        if (n >> i) & 1:
            r |= 1 << (5 - i)
    return r

def _comp6(n):
    """Complement: flip all 6 bits (SPECIFICATION.md comp = n ^ 63)."""
    return n ^ 63

def _partner(h):
    """partner(h) = rev(h) if rev(h) != h else comp(h) (SPECIFICATION.md C1)."""
    r = _rev6(h)
    return r if r != h else _comp6(h)

def _canonical_pairs():
    """The 32 canonical pairs, derived independently from _partner()."""
    seen = set(); out = []
    for h in range(64):
        if h in seen:
            continue
        p = _partner(h)
        seen.add(h); seen.add(p)
        out.append(tuple(sorted((h, p))))
    return out

def _apply_bitperm(g, h):
    """Apply bit-position permutation g to hexagram h: bit i -> position g[i]."""
    r = 0
    for i in range(6):
        if (h >> i) & 1:
            r |= 1 << g[i]
    return r

def _commuting_bitperms():
    """The 48 position-permutations commuting with reversal (i <-> 5-i)."""
    import itertools
    out = []
    for g in itertools.permutations(range(6)):
        if all(g[5 - i] == 5 - g[i] for i in range(6)):
            out.append(g)
    return out

# Pair-orbit partition of the 31 free pairs (TR-11 §3 / F3 draft), published
# membership. Every reduced rung is a union of whole orbits (group-closed).
_ORBITS = {
    "3.0": [3, 7, 11],           "3.1": [4, 6, 21],
    "3.2": [13, 14, 30],         "4.0": [5, 8, 26, 31],
    "6.0": [1, 9, 17, 19, 22, 25], "6.1": [2, 12, 16, 18, 24, 28],
    "6.2": [10, 15, 20, 23, 27, 29],
}

def _spec_to_pairs(spec):
    idxs = []
    for lab in spec.split(","):
        idxs.extend(_ORBITS[lab])
    idxs.sort()
    return [PAIRS[i] for i in idxs]

def _count_c1c2c4(pairs, start):
    """Independent COUNTING RECURRENCE for |C1∩C2∩C4| on a pair-union.

    Plain layered subset DP (NO symmetry quotient). State = (placed-mask,
    last-exit-hexagram) -> exact big-int count. Transition places any unused
    pair in either orientation iff the boundary distance != 5 (C2). Only two
    popcount layers are ever live; memory is bounded by the state count.
    """
    from collections import defaultdict
    orients = [((a, b), (b, a)) for (a, b) in pairs]
    n = len(pairs); full = (1 << n) - 1
    cur = {(0, start): 1}
    for _ in range(n):
        nxt = defaultdict(int)
        for (mask, last), cnt in cur.items():
            for i in range(n):
                bit = 1 << i
                if mask & bit:
                    continue
                for (f, s) in orients[i]:
                    if hamming(last, f) == 5:
                        continue
                    nxt[(mask | bit, s)] += cnt
        cur = nxt
    return sum(c for (m, _l), c in cur.items() if m == full)

def _backtrack_c1c2c4(pairs, start):
    """Even-more-primitive exhaustive backtracking count (no memoization),
    used only at small n to cross-check the DP recurrence."""
    orients = [((a, b), (b, a)) for (a, b) in pairs]
    n = len(pairs)
    total = 0
    def rec(depth, last, used):
        nonlocal total
        if depth == n:
            total += 1
            return
        for i in range(n):
            if used & (1 << i):
                continue
            for (f, s) in orients[i]:
                if hamming(last, f) == 5:
                    continue
                rec(depth + 1, s, used | (1 << i))
    rec(0, start, 0)
    return total


_CLS = (1, 2, 3, 4, 6)          # C5 boundary-distance classes; 5 is C2-forbidden
_CLS_IX = {d: i for i, d in enumerate(_CLS)}

def _spec_to_pairs_ordered(spec):
    """Pair list in SPEC ORDER — orbit rows concatenated in the order the spec
    names them, each row ascending internally (TR-11 §4b/§5).

    NOT the sorted index set: order is load-bearing for the C5 ladder, because
    B0 is defined by a first-completion DFS that scans pairs in subset-index
    order. Sorting the n=9 rung yields B0=(2,2,2,3,0) instead of (2,5,0,2,0).
    """
    idxs = []
    for lab in spec.split(","):
        idxs.extend(_ORBITS[lab])          # rows are already ascending
    return [PAIRS[i] for i in idxs]

def _b0_first_completion(pairs, start):
    """TR-11 §5 Step 1: B0 = boundary-class multiset of the FIRST complete
    C2-respecting walk, scanning unplaced pairs in ascending position within P
    and, for each, orientation o=0 (enter b, exit a) then o=1 (enter a, exit b).

    Returns a 5-tuple over classes (1,2,3,4,6), or None if no walk exists.
    """
    n = len(pairs)
    # o=0 first: (b,a) enters b and exits a, for a pair listed (a,b)
    orients = [((b, a), (a, b)) for (a, b) in pairs]

    def rec(depth, last, used, counts):
        if depth == n:
            return counts
        for i in range(n):
            if used & (1 << i):
                continue
            for (f, s) in orients[i]:
                d = hamming(last, f)
                if d == 5 or d == 0:
                    continue
                nc = list(counts); nc[_CLS_IX[d]] += 1
                got = rec(depth + 1, s, used | (1 << i), tuple(nc))
                if got is not None:
                    return got
        return None

    return rec(0, start, 0, (0,) * 5)

def _count_c1c2c4c5(pairs, start, b0):
    """Independent COUNTING RECURRENCE for |C1∩C2∩C4∩C5| on a reduced rung.

    TR-11 §5 Step 2: plain layered subset DP (NO symmetry quotient), state =
    (placed-mask, last-exit-hexagram, running class-usage vector p). A
    transition is allowed iff the boundary distance d != 5 (C2) AND
    p[class(d)] < B0[class(d)] (the budget cap). The answer is the mass on
    full-mask states; with the cap in place every full state carries p == B0
    exactly (sum invariant), so the equality filter is a no-op — but ONLY with
    the cap in place.

    This is the C5 analogue of _count_c1c2c4 and shares no code with solve.c.
    """
    from collections import defaultdict
    orients = [((a, b), (b, a)) for (a, b) in pairs]
    n = len(pairs); full = (1 << n) - 1
    cur = {(0, start, (0,) * 5): 1}
    for _ in range(n):
        nxt = defaultdict(int)
        for (mask, last, p), cnt in cur.items():
            for i in range(n):
                bit = 1 << i
                if mask & bit:
                    continue
                for (f, s) in orients[i]:
                    d = hamming(last, f)
                    if d == 5 or d == 0:
                        continue
                    ci = _CLS_IX[d]
                    if p[ci] >= b0[ci]:
                        continue
                    np_ = list(p); np_[ci] += 1
                    nxt[(mask | bit, s, tuple(np_))] += cnt
        cur = nxt
    return sum(c for (m, _l, p), c in cur.items() if m == full and p == tuple(b0))

# TR-11 §4b C5 ladder — (n, orbit spec, published B0, published exact count).
# Only the rungs that are cheap enough to recompute in-process are listed; the
# larger rungs in §4b need a worker, not this verifier.
_C5_RUNGS = [
    (9,  "3.0,3.1,3.2", (2, 5, 0, 2, 0), 26112),
    (13, "3.0,4.0,6.2", (1, 6, 0, 6, 0), 2063395607040),
    (16, "4.0,6.0,6.1", (1, 8, 1, 6, 0), 267765117419520),
]


def recount():
    """Independently reproduce the published ROAE exact counts (TR-11 §10vi).

    Prints a match table. Returns 0 iff every quantity with a published target
    reproduced exactly; a mismatch is a SERIOUS finding and is reported loudly.
    """
    import itertools, time
    from collections import Counter
    _t0 = time.time()
    rows = []        # (name, published, independent, matched|None, method)
    all_match = [True]

    def check(name, pub, ind, method):
        matched = None if pub is None else (pub == ind)
        if matched is False:
            all_match[0] = False
        rows.append((name, pub, ind, matched, method))

    print("=" * 74)
    print("verify.py --recount : independent reproduction of the ROAE exact counts")
    print("clean-room from published definitions; different method than the")
    print("symmetry-quotient DP; stdlib only; no solve.c/solve.py import.")
    print("=" * 74)

    # ---------------- TARGET 1 : small-n structural facts ----------------
    mine = {frozenset(p) for p in _canonical_pairs()}
    pub_pairs = {frozenset(p) for p in PAIRS}
    check("Canonical partner-pairing == published 32 KW pairs (as sets)",
          True, (mine == pub_pairs), "derive partner() orbits, compare")

    check("KW is a permutation of {0..63}", True, sorted(KW) == list(range(64)),
          "flatten published pair table")

    check("C1: every KW pair is {h, partner(h)}", True,
          all(_partner(a) == b and _partner(b) == a for (a, b) in PAIRS),
          "recompute partner() on each pair")

    within = dict(Counter(hamming(a, b) for (a, b) in _canonical_pairs()))
    check("Within-pair distance multiset (32 pairs)", {2: 12, 4: 12, 6: 8},
          within, "popcount within each canonical pair")

    xorset = sorted({a ^ b for (a, b) in _canonical_pairs()})
    check("XOR-product set {h ^ partner(h)}",
          [12, 18, 30, 33, 45, 51, 63], xorset, "XOR within each pair, dedup")

    fullms = dict(Counter(hamming(KW[i], KW[i + 1]) for i in range(63)))
    check("KW difference-wave multiset D(S) (all 63 transitions, C5)",
          {1: 2, 2: 20, 3: 13, 4: 19, 6: 9}, fullms, "popcount along KW")

    between = dict(Counter(hamming(KW[2 * i + 1], KW[2 * i + 2]) for i in range(31)))
    check("KW between-pair boundary multiset (31 boundaries) [reduced-C5 B0]",
          {1: 2, 2: 8, 3: 13, 4: 7, 6: 1}, between, "popcount at 31 boundaries")

    pos = {h: i for i, h in enumerate(KW)}
    cd_sum = sum(abs(pos[h] - pos[h ^ 63]) for h in range(64))
    check("KW C3 complement-distance sum (x64 integer form)", 776, cd_sum,
          "sum |pos(h)-pos(comp(h))| over all 64 hexagrams")

    check("C2: no distance-5 adjacency in KW", True,
          all(hamming(KW[i], KW[i + 1]) != 5 for i in range(63)), "popcount")
    check("C4: KW starts (63, 0)", True, (KW[0] == 63 and KW[1] == 0), "read s0,s1")

    G = _commuting_bitperms()
    check("|symmetry group C_S6(rev)| (bit-position perms)", 48, len(G),
          "enumerate 720 perms, keep those commuting with reversal")

    check("group elements fix {0,63} and preserve Hamming distance",
          True,
          all(_apply_bitperm(g, 0) == 0 and _apply_bitperm(g, 63) == 63 for g in G)
          and all(hamming(_apply_bitperm(g, a), _apply_bitperm(g, b)) == hamming(a, b)
                  for g in G[:4] for a in range(64) for b in range(a, 64)),
          "verify fix of all-0/all-1 + isometry (subset)")

    cps = _canonical_pairs()
    pidx = {frozenset(p): i for i, p in enumerate(cps)}
    induced = {tuple(pidx[frozenset((_apply_bitperm(g, a), _apply_bitperm(g, b)))]
                     for (a, b) in cps) for g in G}
    check("distinct induced pair-permutations (record group, S4)", 24, len(induced),
          "induce each g on the 32 pairs, dedup")

    def rec_canon(seq):
        return tuple(frozenset((seq[2 * i], seq[2 * i + 1])) for i in range(32))
    orbit = {rec_canon([_apply_bitperm(g, h) for h in KW]) for g in G}
    check("King Wen orbit size at record level (KW + twins)", 24, len(orbit),
          "apply 48 bit-perms to KW, canonicalize, dedup")
    check("King Wen record-level twin count (orbit - KW)", 23, len(orbit) - 1,
          "orbit size - 1")

    # ------- cross-method independence check (DP == raw backtracking) -------
    print("\nCross-method check  plain DP  ==  raw backtracking  (small prefixes):")
    base = _spec_to_pairs("3.0,3.1,3.2")
    cross_ok = True
    for k in (3, 4, 5, 6, 7):
        a = _count_c1c2c4(base[:k], 0)
        b = _backtrack_c1c2c4(base[:k], 0)
        if a != b:
            cross_ok = False; all_match[0] = False
        print(f"   k={k}: DP={a:,}  backtrack={b:,}  "
              f"{'AGREE' if a == b else '*** DISAGREE ***'}")
    check("plain-DP recurrence == exhaustive backtracking (k=3..7)",
          True, cross_ok, "two independent methods agree")

    # ---------------- TARGET 2 : reduced-rung C1∩C2∩C4 unions ----------------
    check("U1  = |C1∩C2∩C4|, 9 pairs {3.0,3.1,3.2}@0",
          63366144, _count_c1c2c4(_spec_to_pairs("3.0,3.1,3.2"), 0),
          "plain (mask,last) counting recurrence")
    # U1 also reproduced by fully-independent raw backtracking (63M leaves) —
    # cheap enough to include as a second method.
    check("U1  (same) via raw exhaustive backtracking (independent of any DP)",
          63366144, _backtrack_c1c2c4(_spec_to_pairs("3.0,3.1,3.2"), 0),
          "exhaustive backtracking, no memoization")
    check("U2  = |C1∩C2∩C4|, 12 pairs {6.0,6.1}@0",
          1961990553600, _count_c1c2c4(_spec_to_pairs("6.0,6.1"), 0),
          "plain (mask,last) counting recurrence")
    import math as _math
    check("U2  closed form 12! * 2^12 (no d=5 boundary occurs in this union)",
          1961990553600, _math.factorial(12) * (2 ** 12), "closed form")
    check("U3  = |C1∩C2∩C4|, 13 pairs {3.0,4.0,6.2}@63",
          39239811072000, _count_c1c2c4(_spec_to_pairs("3.0,4.0,6.2"), 63),
          "plain (mask,last) counting recurrence")

    # -------------- TARGET 3 : reduced-rung C1∩C2∩C4∩C5 (C5 ladder) --------------
    # GAP NOW CLOSED (2026-07-21). Earlier revisions of this file recorded these
    # rungs as NOT independently re-countable: the published Verification Guide
    # then said "retain states whose boundary multiset is a SUB-multiset of KW's
    # {1:2,2:8,3:13,4:7,6:1}", which at the 13-pair rung yields
    # 38,492,859,594,240 rather than the published 2,063,395,607,040 — because
    # the true rule is an EXACT match against that rung's own target B0, and the
    # per-rung B0 was not in any public document. That defect (surfaced by this
    # instrument) was fixed in TR-11 v1.2 / adversarial-review item F-3, which
    # published both the spec-ORDER pair lists and the per-rung B0 targets.
    #
    # So the ladder is now reproducible from public definitions alone, and this
    # block does so — deriving B0 INDEPENDENTLY via TR-11 §5's first-completion
    # DFS rather than trusting the published B0, then counting with a plain
    # budgeted (mask,last,p) DP that shares no code with solve.c. Two things are
    # therefore checked per rung: the derived B0 and the resulting count.
    #
    # Rungs n>=19 exceed this host's pure-Python memory/time budget and are
    # honestly recorded as not re-counted here (they need a worker, not a laptop).
    for n, spec, b0_pub, pub in _C5_RUNGS:
        pl = _spec_to_pairs_ordered(spec)
        b0_ind = _b0_first_completion(pl, 0)
        check(f"C5 ladder n={n} {{{spec}}}@0 — B0 derived independently",
              tuple(b0_pub), tuple(b0_ind) if b0_ind else None,
              "TR-11 §5 first-completion DFS (spec order, o=0 then o=1)")
        check(f"C5 ladder n={n} {{{spec}}}@0 — |C1∩C2∩C4∩C5|",
              pub, _count_c1c2c4c5(pl, 0, b0_pub),
              "plain budgeted (mask,last,p) counting recurrence")

    for n, spec, pub in [
        (19, "3.0,4.0,6.0,6.1", 63244766587981824),
        (24, "3.0,3.1,6.0,6.1,6.2", 7477248378538061907099648),
        (25, "3.0,4.0,6.0,6.1,6.2", 83855263774549546015506432),
        (27, "3.0,3.1,3.2,6.0,6.1,6.2", 61666352085618532666071318528),
        (28, "3.0,3.1,4.0,6.0,6.1,6.2", 2155118806480613893163229118464),
    ]:
        rows.append((f"C5 ladder n={n} {{{spec}}}@0", pub,
                     "not re-counted here (exceeds this host; needs a worker)",
                     None, "recipe now public — TR-11 §4b/§5"))

    # ------------------------------ match table ------------------------------
    print("\n" + "=" * 74)
    print("MATCH TABLE  (quantity | published | independent | match)")
    print("=" * 74)
    def _fmt(v):
        if v is None:
            return "(no public target)"
        return format(v, ",") if isinstance(v, int) else str(v)
    for name, pub, ind, matched, method in rows:
        mark = "  --  " if matched is None and pub is None else \
               " n/a  " if matched is None else \
               " MATCH" if matched else "*FAIL*"
        print(f"[{mark}] {name}")
        print(f"          published:   {_fmt(pub)}")
        print(f"          independent: {_fmt(ind)}")
        print(f"          method:      {method}")
    print("=" * 74)
    n_ok = sum(1 for r in rows if r[3] is True)
    n_fail = sum(1 for r in rows if r[3] is False)
    n_na = sum(1 for r in rows if r[3] is None)
    print(f"summary: {n_ok} reproduced, {n_fail} MISMATCH, {n_na} not re-counted "
          f"(total wall time {time.time() - _t0:.1f}s)")
    if all_match[0]:
        print("RESULT: every quantity with a published target reproduced EXACTLY.")
        print("        (C5 ladder n=9/13/16 re-counted here, B0 re-derived independently;")
        print("        the larger C5 rungs exceed this host and are recorded as not")
        print("        re-counted — they remain corroborated by the project's own two")
        print("        engines (in-RAM + out-of-core agree digit-for-digit) + estimator.)")
    else:
        print("RESULT: *** MISMATCH DETECTED *** — a bug in one instrument or the")
        print("        other. See the *FAIL* row(s) above. Do NOT paper over this.")
    print("=" * 74)
    return 0 if all_match[0] else 1


_PUBLISHED_F1C5 = 1097051278789181790036112071176579186688   # TR-11 §9, |C1∩C2∩C4∩C5|

def _parse_layer_certificate(run_out):
    """Extract the per-layer certificate rows a completed f1c5 run leaves in run.out.

    Returns [(k, canonical_masks, C(31,k), states, entries, V_k, mass)]. These are the
    engine's own published per-layer figures — this function only READS them; every
    identity checked against them lives in check_certificate() below."""
    import re
    pat = (r"\[f1c5\] layer k=\s*(\d+)/31: canonical_masks=(\d+) \(of C\(31,(\d+)\)=(\d+)\) "
           r"states=(\d+) entries=(\d+) V_k=(\d+).*?mass=(\d+)")
    out = []
    with open(run_out, encoding='utf-8', errors='replace') as fh:
        txt = fh.read()
    for m in re.finditer(pat, txt):
        k, cm, _kk, cbin, st, en, vk, mass = (int(x) for x in m.groups())
        out.append((k, cm, cbin, st, en, vk, mass))
    return out

def check_certificate(dirpath):
    """Validate a completed f1c5 run's ARTIFACTS without re-running the DP (TR-11 §10iii).

    This is the "check the artifact, don't trust the code" half of the verification
    story: the engine's per-layer figures + manifest + preserved digests are checked
    against structural identities and against quantities this file derives on its own
    (King Wen's boundary multiset; the mod-24 gate; the published integer).

    IMPORTANT — what this does and does NOT establish. It does NOT recompute the DP, so
    it cannot certify that the per-layer masses are *correct*; it certifies that the
    published artifact is internally consistent, structurally admissible, digest-intact,
    and terminates at the published integer. Row-level recomputation is the companion
    step and is deliberately not done here.

    Identities were validated against the landed 2026-07-16 run (31/31 layers) before
    being encoded; two plausible-looking candidates were REJECTED as false and are
    recorded here so they are not re-added: `states == masks*2k` (fails at small k —
    C2 forbids some exits, so only <= holds) and `mass strictly increasing across
    layers` (simply untrue of the DP masses).
    """
    import os
    rows = []
    run_out = os.path.join(dirpath, 'run.out')
    man = os.path.join(dirpath, 'f1c5_manifest.txt')
    shas = os.path.join(dirpath, 'PRESERVE_SHA256.txt')
    ok = [True]

    def chk(name, cond, detail=""):
        rows.append((name, bool(cond), detail))
        if not cond:
            ok[0] = False

    print("=" * 74)
    print("verify.py --check-certificate : artifact check for a completed f1c5 run")
    print("reads the run's own artifacts; recomputes nothing. See docstring for scope.")
    print("=" * 74)

    if not os.path.isfile(run_out):
        print(f"FATAL: no run.out under {dirpath}")
        return 1
    lay = _parse_layer_certificate(run_out)
    chk("run.out carries all 31 layer certificate rows", len(lay) == 31, f"got {len(lay)}")

    if lay:
        chk("every layer: canonical_masks <= C(31,k)",
            all(cm <= cb for _k, cm, cb, _s, _e, _v, _m in lay), "combinatorial bound")
        chk("every layer: states <= canonical_masks * 2k",
            all(st <= cm * 2 * k for k, cm, _cb, st, _e, _v, _m in lay),
            "each placed pair offers <=2 exits; C2 removes some (equality FAILS at small k)")
        chk("every layer: states <= entries <= states * V_k",
            all(st <= en <= st * vk for _k, _cm, _cb, st, en, vk, _m in lay),
            "budget-vector fan-out bound")
        chk("every layer: mass > 0", all(m > 0 for *_r, m in lay))
        term = lay[-1]
        chk("terminal layer k=31 is a single canonical mask",
            term[0] == 31 and term[1] == 1, f"k={term[0]} masks={term[1]}")
        chk("terminal mass == published |C1∩C2∩C4∩C5| (TR-11 §9)",
            term[6] == _PUBLISHED_F1C5, f"{term[6]}")
        chk("terminal mass ≡ 0 (mod 24)  [free-action theorem gate]",
            term[6] % 24 == 0, f"mod24={term[6] % 24}")

    # manifest b0 vs King Wen's boundary multiset, derived HERE (not read from solve.c)
    if os.path.isfile(man):
        mtxt = open(man, encoding='utf-8').read()
        got = None
        for line in mtxt.splitlines():
            if line.startswith('b0='):
                got = tuple(int(x) for x in line[3:].split(','))
        from collections import Counter
        between = Counter(hamming(KW[2 * i + 1], KW[2 * i + 2]) for i in range(31))
        mine = tuple(between.get(d, 0) for d in (1, 2, 3, 4, 6))
        chk("manifest b0 == KW between-pair boundary multiset (derived independently)",
            got == mine, f"manifest={got} derived={mine}")
        chk("manifest reports last_complete_k=31", 'last_complete_k=31' in mtxt)
    else:
        rows.append(("manifest present", None, "no f1c5_manifest.txt"))

    # preserved digests
    if os.path.isfile(shas):
        import hashlib
        bad = []
        for line in open(shas, encoding='utf-8'):
            parts = line.split()
            if len(parts) != 2:
                continue
            want, fn = parts
            p = os.path.join(dirpath, fn)
            if not os.path.isfile(p):
                bad.append(f"{fn}:missing"); continue
            h = hashlib.sha256()
            with open(p, 'rb') as fh:
                for blk in iter(lambda: fh.read(1 << 20), b''):
                    h.update(blk)
            if h.hexdigest() != want:
                bad.append(f"{fn}:MISMATCH")
        chk("preserved artifact digests match PRESERVE_SHA256.txt", not bad, ",".join(bad) or "all match")
    else:
        rows.append(("PRESERVE_SHA256.txt present", None, "absent"))

    print()
    for name, res, detail in rows:
        tag = "[ MATCH]" if res is True else ("[ n/a  ]" if res is None else "[*FAIL*]")
        print(f"{tag} {name}")
        if detail:
            print(f"          {detail}")
    print("=" * 74)
    if ok[0]:
        print("RESULT: artifact is internally consistent, digest-intact, and terminates")
        print("        at the published integer. This is NOT a recomputation — the")
        print("        per-layer masses are taken as given; row-level recomputation is")
        print("        the companion check and was not performed here.")
    else:
        print("RESULT: *** ARTIFACT CHECK FAILED *** — see FAIL row(s). Do not explain away.")
    print("=" * 74)
    return 0 if ok[0] else 1


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
    parser.add_argument('--recount', action='store_true',
                        help='Independently reproduce the published exact COUNTS (small-n structural '
                             'facts + reduced-rung C1∩C2∩C4 union counts) by a counting recurrence — '
                             'a different method than solve.c\'s symmetry-quotient DP. Prints a match '
                             'table. Does NOT read solutions.bin. Answers TR-11 §10vi.')
    parser.add_argument('--check-certificate', metavar='DIR', default=None,
                        help='Artifact check for a completed f1c5 run directory (TR-11 §10iii): '
                             'validates the per-layer certificate rows, manifest, and preserved '
                             'digests against structural identities and independently-derived '
                             'quantities. Recomputes NOTHING — see check_certificate() for scope.')
    args = parser.parse_args()

    if args.check_certificate is not None:
        sys.exit(check_certificate(args.check_certificate))

    if args.recount:
        sys.exit(recount())

    if args.enumerate_reference is not None:
        sys.exit(enumerate_reference(args.enumerate_reference))

    path = args.path
    n_jobs = max(1, args.jobs)

    # #169: solutions.bin may be gzip-compressed (SOLVE_COMPRESS default on). verify.py uses
    # byte-offset parallel chunking which gzip cannot seek, so transparently decompress a gz file
    # to a temp raw file and verify that — the logical (decompressed) content is byte-identical to
    # a raw solutions.bin, so all constraint/sort/dup checks are unchanged. Temp removed at exit.
    with open(path, 'rb') as _fh:
        _is_gz = _fh.read(2) == b'\x1f\x8b'
    if _is_gz:
        _fd, _tmp = tempfile.mkstemp(prefix='verify_solbin_', suffix='.bin')
        os.close(_fd)
        atexit.register(lambda p=_tmp: os.path.exists(p) and os.remove(p))
        print(f"Detected gzip-compressed solutions.bin; decompressing to {_tmp} for verification...")
        with gzip.open(path, 'rb') as _fin, open(_tmp, 'wb') as _fout:
            shutil.copyfileobj(_fin, _fout, length=1 << 24)
        path = _tmp
        print(f"  decompressed: {os.path.getsize(path):,} bytes (logical content)")

    # Read header from main process to validate format and get record count.
    with open(path, 'rb') as f:
        head = f.read(SOL_HEADER_SIZE)
    try:
        declared_records = parse_header(head)
    except ValueError as e:
        print(f"ERROR: invalid solutions.bin header: {e}")
        sys.exit(2)

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
