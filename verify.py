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
    python3 verify.py [solutions.bin] --expect-kw   # ... and REQUIRE King Wen to be present
    python3 verify.py --enumerate-reference N       # small-n brute-force (2<=N<=9)
    python3 verify.py --recount                     # independent count reproduction
    python3 verify.py --recount-rung N              # C5 ladder rung n=18/19 (worker-sized)
    python3 verify.py --recount-subtree             # TR-5 exact subtree anchors (443/62,256/9,422,793/16,504)
                                                    # + 3 away-from-KW C3 cross-anchors (solve.c-exact expectations)
    python3 verify.py --recount-finite              # TR-5/TR-6 finite record-mode + wrap/parity tallies
    python3 verify.py --recount-fiber               # TR-1 §7 orientation fiber (1,720,320 / 983,040)
    python3 verify.py --recount-gender-null         # TR-8 exact pair-null gender figure (47/445740)
    python3 verify.py [solutions.bin] --fiber-sweep # orientation-fiber factor: records -> sequences

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
            'fail_decode': 0, 'fail_sort': 0, 'fail_dup': 0, 'fail_fmt': 0,
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
    fail_decode = fail_sort = fail_dup = fail_fmt = 0
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

        # Format conformance: bit 0 of every record byte is reserved and MUST
        # be zero (SOLUTIONS_FORMAT.md: "bit 0: unused, always 0"). It is masked
        # out of the canonical sort key (& 0xFC) but DOES participate in the
        # full-byte dedup tie-break, so a set bit 0 silently breaks byte-exact
        # reproducibility between two otherwise-conformant implementations.
        if any(b & 1 for b in rec):
            fail_fmt += 1

        seq, pairs_used, first_pair = decode(rec)

        if seq is None:
            fail_decode += 1
            continue

        # C1: each pair used exactly once
        if any(c != 1 for c in pairs_used):
            fail_c1 += 1

        # C4: s0 = 63 (The Creative) AND s1 = 0 (The Receptive) — both conjuncts.
        # This is the spec form (SPECIFICATION.md C4), not the pair-index proxy.
        # C4 is ORIENTED, and the 2026-07-26 retraction established that the
        # orientation is NOT forced by the other constraints: complementation
        # x -> x^63 is an exact symmetry of C1 n C2 n C3 n C5 (machine-checked,
        # lean/KingWen.lean). So a verifier testing only `first_pair == 0` would
        # accept comp(KW) — which opens (0, 63) — as fully C1-C5 valid. Testing
        # the pair index alone silently relies on the ENUMERATOR's hardcoded
        # seq[0]=63; seq[1]=0, which is exactly the invariant an independent
        # verifier is not entitled to assume. seq[0] == 63 subsumes the index
        # test (63 occurs only in pair 0, and the pairs are disjoint); both are
        # kept so the failure mode stays legible.
        if first_pair != START_PAIR or seq[0] != 63 or seq[1] != 0:
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
        'fail_fmt': fail_fmt,
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

def _verify_tables_against_rules():
    """Import-time gate: the KW table, and everything derived from it, must
    agree with the RULE-derived objects of SPECIFICATION.md — not merely with
    itself.

    Without this the record path is self-verifying: PAIRS, KW_DIST and
    KW_COMP_DIST are all computed from the KW literal at the top of this file,
    so a corrupted KW table would silently redefine C1 and C5 and then check
    every record against the corruption. (Concretely: swapping the last two
    pair-blocks moves both complement partners together, leaving cd = 776
    intact, while changing the C5 multiset — the file would then reject
    spec-compliant records and accept violating ones, against itself.)

    These are explicit raises rather than `assert` so they survive `python3 -O`.
    --recount reports the same facts as table rows; this gate makes them
    unconditional on the default `verify.py solutions.bin` path.
    """
    if sorted(KW) != list(range(64)):
        raise RuntimeError("table check: KW is not a permutation of {0..63}")
    if {frozenset(p) for p in PAIRS} != {frozenset(p) for p in _canonical_pairs()}:
        raise RuntimeError(
            "table check: published PAIRS != partner()-derived canonical pairing (C1)")
    for (a, b) in PAIRS:
        if _partner(a) != b or _partner(b) != a:
            raise RuntimeError(f"table check: pair ({a},{b}) is not a partner() pair (C1)")
    observed = {d: KW_DIST[d] for d in range(7) if KW_DIST[d]}
    if observed != {1: 2, 2: 20, 3: 13, 4: 19, 6: 9}:
        raise RuntimeError(
            f"table check: KW difference-wave multiset {observed} != SPECIFICATION.md C5 literal")
    if KW_COMP_DIST != 776:
        raise RuntimeError(f"table check: KW complement distance {KW_COMP_DIST} != 776 (C3)")

_verify_tables_against_rules()

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

def _derive_pair_orbits():
    """Derive the orbit partition of the 31 free pairs from THIS FILE's own group,
    rather than trusting the table above.

    Each of the 48 bit-position permutations commuting with reversal acts on
    hexagrams; because it commutes with rev and fixes 0 and 63, it maps canonical
    pairs to canonical pairs and so induces a permutation of the 32 pair indices.
    Orbits of the 31 free pairs (pair 0 is C4-pinned and fixed by every element)
    under that induced action are what `_ORBITS` records.

    A9 (2026-08-01): `_ORBITS` was transcribed from TR-11 §3, which made the
    reduced-rung machinery depend on a published table copied by hand — the same
    self-verifying-table weakness the record path had (see
    `_verify_tables_against_rules`). Deriving it closes the last such nick.
    """
    index_of = {frozenset(p): i for i, p in enumerate(PAIRS)}
    orbits, seen = [], set()
    for i in range(1, 32):
        if i in seen:
            continue
        orb, frontier = {i}, [i]
        while frontier:
            j = frontier.pop()
            a, b = PAIRS[j]
            for g in _commuting_bitperms():
                k = index_of.get(frozenset((_apply_bitperm(g, a), _apply_bitperm(g, b))))
                if k is None:
                    raise RuntimeError(
                        "orbit derivation: a group element moved a canonical pair off the pairing")
                if k not in orb:
                    orb.add(k); frontier.append(k)
        seen |= orb
        orbits.append(sorted(orb))
    return orbits

def _verify_orbits_against_group():
    """Gate: the published `_ORBITS` table must equal the derived orbit partition."""
    derived = {tuple(o) for o in _derive_pair_orbits()}
    published = {tuple(sorted(v)) for v in _ORBITS.values()}
    if derived != published:
        raise RuntimeError(
            f"orbit check: published _ORBITS != orbits derived from the 48 commuting "
            f"bit-perms.\n  derived  : {sorted(derived)}\n  published: {sorted(published)}")
    covered = sorted(i for o in derived for i in o)
    if covered != list(range(1, 32)):
        raise RuntimeError(
            f"orbit check: orbits do not partition the 31 free pairs (got {len(covered)} indices)")

_verify_orbits_against_group()

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


# ---------------------------------------------------------------------------
# Verifier-gap closure (2026-07-31): worker-sized C5 rungs (A4), exact
# deterministic subtree anchors (A5), finite record-mode + wrap/parity
# tallies (A6).  Same discipline as the rest of this file: clean-room from
# the published definitions, stdlib only, no solve.c/solve.py import.
# ---------------------------------------------------------------------------

# TR-11 §4b worker-sized rungs.  n=18's integer was unpublished through TR-11
# v1.17 (the table printed "(in-RAM reference)"); v1.18 (2026-08-10) publishes it
# as 3,211,799,156,883,456, and it is GATED here as of the same day.
#
# The gate was deliberately NOT wired at publication time: gating asserts that THIS
# independent DP reproduces the integer, and doing that on faith would let the gate
# inherit its expected value from the engine it exists to check.  So the recount was
# run first, on a throwaway westus2 Spot VM (the orchestrator hosts the live Stage G
# supervisor and an OOM there would kill a 9-day campaign): 2026-08-10, n=16 packed-DP
# self-gate ok, B0 re-derived (0,7,1,10,0) MATCH, count 3,211,799,156,883,456 EXACT,
# 157 s wall / 953 MB peak RSS.  Only then was the value wired in.
# n=18's published B0 column was already gated before this.  n=24/25/27/28 are NOT reachable by this plain
# DP on any single-node RAM budget (peak live states ~4e9 at n=24, ~100 GB per
# layer) — they remain covered by the engine's in-RAM/out-of-core concordance
# and verify.c's IE engine.
_C5_RUNGS_LARGE = {
    18: ("6.0,6.1,6.2",     (0, 7, 1, 10, 0), 3211799156883456),
    19: ("3.0,4.0,6.0,6.1", (2, 11, 0, 6, 0), 63244766587981824),
}

def _count_c1c2c4c5_packed(pairs, start, b0):
    """Memory-lean variant of _count_c1c2c4c5 for the worker-sized rungs.

    Identical recurrence (TR-11 §5 Step 2); states are packed into a single
    int key (mask | last << n | pidx << (n + 6), pidx mixed-radix over B0+1)
    so each live state costs one small-int key + one int value.  Peak live
    states at n=19 are ~4e7 per layer (~8 GB, ~1e9 transitions in CPython —
    a worker, not a laptop).  Cross-checked against _count_c1c2c4c5 at
    n=9/13/16 (identical integers) before first use.
    """
    n = len(pairs); full = (1 << n) - 1
    radix = [c + 1 for c in b0]
    stride = [0] * 5
    acc = 1
    for c in range(5):
        stride[c] = acc; acc *= radix[c]
    shift_last = n; shift_p = n + 6
    orients = [((a, b), (b, a)) for (a, b) in pairs]
    cur = {start << shift_last: 1}
    for _layer in range(n):
        nxt = {}
        get = nxt.get
        for key, cnt in cur.items():
            mask = key & full
            last = (key >> shift_last) & 63
            pidx = key >> shift_p
            for i in range(n):
                bit = 1 << i
                if mask & bit:
                    continue
                for (f, s) in orients[i]:
                    d = hamming(last, f)
                    if d == 5 or d == 0:
                        continue
                    ci = _CLS_IX[d]
                    if (pidx // stride[ci]) % radix[ci] >= b0[ci]:
                        continue
                    nkey = ((mask | bit) | (s << shift_last)
                            | ((pidx + stride[ci]) << shift_p))
                    nxt[nkey] = get(nkey, 0) + cnt
        cur = nxt
    b0idx = sum(b0[c] * stride[c] for c in range(5))
    total = 0
    for key, cnt in cur.items():
        assert key & full == full and key >> shift_p == b0idx, \
            "sum invariant violated — cap logic bug"
        total += cnt
    return total

def recount_rung(n):
    """--recount-rung N: independently recompute a worker-sized TR-11 §4b C5
    rung (N in {18, 19}).  B0 is re-derived by §5's first-completion DFS and
    gated against the published B0 column; the count is gated against the
    published integer where one exists.  Returns 0 iff everything gated
    matched."""
    import time
    if n not in _C5_RUNGS_LARGE:
        if n in (9, 13, 16):
            print(f"n={n} is covered in-process by --recount; use that.")
        else:
            print(f"--recount-rung: n={n} not supported. Supported: 18, 19.")
            print("n=24/25/27/28 exceed any single-node RAM budget for the plain")
            print("DP (peak live states ~4e9 at n=24, ~100 GB/layer); they remain")
            print("covered by the engine's in-RAM/out-of-core concordance and")
            print("verify.c's IE engine (--ie-spec/--ie-expect).")
        return 2
    spec, b0_pub, pub = _C5_RUNGS_LARGE[n]
    pl = _spec_to_pairs_ordered(spec)
    assert len(pl) == n
    t0 = time.time()
    # gate the packed DP against the plain DP on the largest cheap rung first
    xchk_pl = _spec_to_pairs_ordered("4.0,6.0,6.1")
    xchk_b0 = _b0_first_completion(xchk_pl, 0)
    a = _count_c1c2c4c5(xchk_pl, 0, xchk_b0)
    b = _count_c1c2c4c5_packed(xchk_pl, 0, xchk_b0)
    if a != b:
        print(f"*FAIL* packed-DP self-gate at n=16: plain={a:,} packed={b:,}")
        return 1
    print(f"packed-DP self-gate at n=16: {a:,} == {b:,}  [ok]")
    b0 = _b0_first_completion(pl, 0)
    ok_b0 = tuple(b0) == tuple(b0_pub)
    print(f"n={n} {{{spec}}}@0  B0 derived = {tuple(b0)}  published = {tuple(b0_pub)}"
          f"  [{'MATCH' if ok_b0 else '*** MISMATCH ***'}]")
    cnt = _count_c1c2c4c5_packed(pl, 0, tuple(b0))
    dt = time.time() - t0
    if pub is None:
        print(f"count = {cnt:,}   (report-only: this recount is not gated against a")
        print(f"        published integer, so compare it by hand to TR-11 §4b)  [{dt:.0f}s]")
        return 0 if ok_b0 else 1
    ok = (cnt == pub)
    print(f"count = {cnt:,}  published = {pub:,}  "
          f"[{'MATCH' if ok else '*** MISMATCH ***'}]  [{dt:.0f}s]")
    return 0 if (ok and ok_b0) else 1

# TR-5 Verification Guide's sigma-related 23-pair prefix (pair, orient).
_SIGMA_PREFIX = [(22, 1), (28, 0), (3, 1), (21, 1), (26, 0), (6, 1), (11, 0),
                 (5, 0), (19, 0), (27, 0), (7, 1), (16, 1), (30, 1), (14, 0),
                 (20, 0), (18, 1), (25, 0), (24, 1), (1, 1), (15, 0), (4, 0),
                 (9, 0)]

def _exact_subtree(prefix):
    """Exact deterministic count of the C1-C5 backtracking tree below a fixed
    (pair, orient) prefix — returns (tree_nodes, leaves, canonical_leaves,
    canonical_and_C6C7).

    The tree object is the enumerator's: states are pair-sequences from the
    forced (63, 0) start; a placement must pass boundary distance != 5 (C2)
    and keep the running COMBINED 63-transition multiset (within + boundary,
    including pair 0's within d=6) dominated by C5's {1:2,2:20,3:13,4:19,6:9};
    tree_nodes counts every reached state including the prefix root; canonical
    leaves additionally pass C3 (sum |pos(v)-pos(v^63)| <= 776).  The
    internal-node convention is the published instrument's (SEARCH_SPACE_SIZE
    §Method: live-child states of the pruned walk); the implementation here is
    clean-room."""
    budget = [0] * 7
    for i in range(63):
        budget[hamming(KW[i], KW[i + 1])] += 1
    assert budget == [0, 2, 20, 13, 19, 0, 9]
    budget[6] -= 1                              # pair 0's within transition
    seq = [63, 0] + [0] * 62
    slotp = [0] * 32                            # pair index placed at each slot
    used = 1
    last = 0
    step = 1
    for (p, o) in prefix:
        slotp[step] = p
        a, b = PAIRS[p]
        f, s = (b, a) if o else (a, b)
        bd = hamming(last, f)
        assert bd != 5 and budget[bd] > 0, "prefix infeasible (boundary)"
        budget[bd] -= 1
        wd = hamming(f, s)
        assert budget[wd] > 0, "prefix infeasible (within)"
        budget[wd] -= 1
        seq[2 * step], seq[2 * step + 1] = f, s
        used |= 1 << p
        last = s
        step += 1
    stats = [0, 0, 0, 0]                # nodes, leaves, canonical, canon+C6/C7

    def rec(st, lst, usedm):
        stats[0] += 1
        if st == 32:
            stats[1] += 1
            pos = [0] * 64
            for i, v in enumerate(seq):
                pos[v] = i
            if sum(abs(pos[v] - pos[v ^ 63]) for v in range(64)) <= 776:
                stats[2] += 1
                # C6/C7 (SPECIFICATION.md): pairs 24,25 at slots 24,25 (C7)
                # and pairs 26,27 at slots 26,27 (C6), orientation free
                if slotp[24:28] == [24, 25, 26, 27]:
                    stats[3] += 1
            return
        for p in range(1, 32):
            if (usedm >> p) & 1:
                continue
            a, b = PAIRS[p]
            for (f, s) in ((a, b), (b, a)):
                bd = hamming(lst, f)
                if bd == 5 or budget[bd] == 0:
                    continue
                budget[bd] -= 1
                wd = hamming(f, s)
                if budget[wd] == 0:
                    budget[bd] += 1
                    continue
                budget[wd] -= 1
                seq[2 * st], seq[2 * st + 1] = f, s
                slotp[st] = p
                rec(st + 1, s, usedm | (1 << p))
                budget[wd] += 1
                budget[bd] += 1

    rec(step, last, used)
    return tuple(stats)

# Cross-instrument subtree anchors AWAY from King Wen's neighbourhood
# (2026-08-06).  The KW-following anchors in recount_subtree() all sit in
# KW's own corner of the tree, and their leaf C3 values cluster at the 776
# threshold (measured with this file's own walk: 5-free 776..808, 7-free
# 752..816, 9-free 752..928) — so a C3 defect that manifests only far from
# that neighbourhood, in either direction (falsely REJECTING sequences that
# comfortably pass, or falsely ACCEPTING sequences that clearly fail), would
# escape every one of them.  The three prefixes below were drawn at random
# from the C1-C5 tree by `solve --knuth-dump-prefix 24 <seed>` (seeds 43, 9,
# 112; depth 24 = 7 free positions, chosen to keep each anchor sub-second in
# CPython) and land far from KW's prefix.  Each expectation 4-tuple
# (tree_nodes, leaves_C1C2C4C5, canonical_leaves, canonical_and_C6C7) was
# computed by the OTHER instrument, solve.c's exact deterministic mode:
#     ulimit -s 9216      # --estimate-knuth segfaults at the default 8 MB
#                         # stack (main-frame + 1.05 MB KnuthArg arg[256])
#     ./solve --estimate-knuth 0 <p1> <o1> ... <p24> <o24>
# (run 2026-08-06 against the sha-anchored solve.c; <0.5 s each), so these
# gates are a two-instrument cross-check of the C3 predicate in BOTH
# directions, not verify.py grading its own homework.  The instruments'
# prefix conventions were confirmed identical on all three published KW
# anchors AND on the mixed-orientation sigma-related prefix first.  One
# caveat: solve.c's exact mode does not print the C6/C7 tally, so the 0 in
# the fourth slot is definition-forced rather than cross-computed (C7
# requires pair 24 AT slot 24; these prefixes place pairs 10, 31, 20 there)
# — the substantive C6/C7 anchor remains the KW 9-free "exactly 8" (TR-4
# §4).  Measured leaf-C3 ranges (this file's walk, 2026-08-06):
#   PASS-LOW  (seed 43):  C3 528..624  — every leaf canonical, margin >= 152
#   FAIL-HIGH (seed 9):   C3 1024..1104 — zero canonical, margin >= 248
#   STRADDLE  (seed 112): C3 736..840 — 11,984 of 26,672 leaves canonical
# With the KW anchors, the C3 range exercised by this gate is 528..1104.
_CROSS_PREFIXES = (
    ("away-KW PASS-LOW (seed 43)",
     [(26, 0), (11, 0), (27, 0), (2, 1), (3, 0), (5, 0), (21, 1), (14, 1),
      (29, 0), (22, 1), (7, 0), (6, 1), (8, 0), (30, 1), (17, 0), (20, 0),
      (4, 1), (24, 1), (13, 0), (12, 1), (28, 1), (15, 0), (25, 1), (10, 1)],
     (35293, 1600, 1600, 0)),
    ("away-KW FAIL-HIGH (seed 9)",
     [(24, 0), (29, 0), (15, 1), (13, 1), (8, 0), (30, 1), (23, 1), (4, 0),
      (9, 1), (21, 0), (28, 1), (25, 0), (19, 1), (10, 1), (26, 0), (16, 1),
      (1, 0), (20, 1), (3, 1), (5, 0), (27, 1), (2, 0), (6, 0), (31, 1)],
     (22228, 1296, 0, 0)),
    ("away-KW STRADDLE (seed 112)",
     [(18, 0), (16, 1), (25, 1), (22, 0), (11, 1), (12, 1), (29, 0), (8, 1),
      (21, 0), (27, 1), (17, 0), (19, 1), (24, 1), (1, 0), (7, 1), (23, 0),
      (14, 0), (5, 0), (30, 1), (4, 0), (2, 0), (9, 0), (15, 0), (20, 1)],
     (95031, 26672, 11984, 0)),
)

# ===========================================================================
# THE ORIENTATION FIBER — STATE-SPACE ARITHMETIC FIRST  (2026-08-02)
# ===========================================================================
# This arithmetic is written and evaluated BEFORE the DP below, because the
# attempt that skipped it hard-rebooted an 8 GB orchestrator.
#
# (0) THE FORMULATION THAT MUST NEVER BE WRITTEN AGAIN
#     key = (slot i, accumulated orientation prefix o_1..o_i)
#       |keys| = Σ_{i=0..31} 2^i = 2^32 − 1 = 4,294,967,295
#       final layer alone = 2^31 = 2,147,483,648 dict entries
#                        ≈ 215 GB at CPython's ~100 B per small dict entry
#     → OOM, then reboot. The orientation vector is the ANSWER being counted;
#       the moment it enters the key the DP stops being a DP and becomes the
#       2^31 search it was supposed to replace.
#
# (1) THE FORMULATION USED HERE
#     key = (exit hexagram of slot i, budget consumed so far)
#       exit hexagram                    : 64
#       budget n = (n₁,n₂,n₃,n₄,n₆), 0 ≤ n_c ≤ B0_c
#       B0 = C5's 63-multiset − the within-pair multiset
#          = {1:2, 2:20, 3:13, 4:19, 6:9} − {2:12, 4:12, 6:8}
#          = {1:2, 2:8, 3:13, 4:7, 6:1}          Σ = 31   (SPECIFICATION.md §137)
#       |budgets| = Π (B0_c + 1) = 3·9·14·8·2 = 6,048
#       |states|  ≤ 64 × 6,048   = 387,072
#     — and that 387,072 bounds the WHOLE RUN, not one slot: Σ_c n_c = i
#       identically, so the slot index is a FUNCTION of the key rather than an
#       extra dimension. Transitions ≤ 2 per state → ≤ 774,144 edge relaxations.
#       Ratio to (0): 4,294,967,295 / 387,072 ≈ 1.11 × 10⁴ fewer states.
#
# (2) WHY IT IS A C2+C5 OBJECT ONLY
#     Within-pair distances are orientation-invariant (d(a,b) = d(b,a)) and the
#     within-pair multiset {2:12, 4:12, 6:8} is the same for every C1 ordering
#     under every orientation vector, so C5 reduces to the fixed budget B0 on
#     the 31 BETWEEN-pair distances, and C2 is implied by it (B0 has no 5).
#
# (3) C3 WITHOUT CARRYING THE PATH — the deliverable that removes the only
#     reason anyone wanted orientation bits in the key.
#     C3 = 16 + 8·G,  G = Σ over the 12 complement-couples of |slot(P) − slot(P′)|
#     (lean/C3Decomposition.lean; TR-11 §10(ii)). The 8 self-complementary pairs
#     sit at adjacent positions and contribute 1 each way whichever member leads
#     (the 16); inside a couple at slots i<j the two members' cross-distances sum
#     to 4(j−i) with both orientation bits cancelling. So G reads the SLOT MAP
#     alone: C3 is CONSTANT on a fiber, evaluated ONCE before the DP starts as a
#     single admissibility flag on the whole fiber — never as DP state. That is
#     `c3_of_ordering` below, 12 subtractions, no path, no prefix.
#
#     HONEST COUNTERFACTUAL (the question was asked, so it is answered rather
#     than dodged): C3 really is a GRAPH over pairs, not a chain over slots —
#     pair P constrains the pair holding its complement, which may sit at any
#     later slot. Had the orientation bits NOT cancelled, an exact DP would have
#     to carry the orientation bit of every couple left OPEN across the slot cut.
#     24 of the 32 pairs lie in 12 cross-couples, so the cut carries ≤ 12 bits:
#       |states| ≤ 64 × 6,048 × 2¹² = 1,585,446,912 ≈ 1.6 × 10⁹
#     ≈ 160 GB as a CPython dict → an exact DP would be INFEASIBLE in Python and
#     infeasible on this orchestrator in any language. The alternatives would
#     then be (a) a packed-array DP in C on a memory-sized VM (~13 GB at 8 B/cell)
#     under a min-cutwidth slot order, or (b) abandon exactness and report the
#     per-ordering bound as a range. Neither is needed: the identity makes the
#     coupling vanish. The dissolution is the result.
#
# (4) THE ANCHOR, DERIVED BY HAND — checkable without executing anything.
#     TR-1 §7 gives the C4-oriented fiber as 3·5·7·2¹⁴. In units of 2¹⁴:
#         C4-oriented  (opening 63,0) = 105 · 2¹⁴ = 1,720,320
#         flipped      (opening 0,63) =  60 · 2¹⁴ =   983,040   (= 15·2¹⁶)
#         pair-only C4 (both openings)= 165 · 2¹⁴ = 2,703,360
#     so EXACTLY   flipped / oriented =  60/105 =  4/7
#                  both    / oriented = 165/105 = 11/7
#     An 11/7 excess is therefore the arithmetic SIGNATURE of exactly one
#     unpinned bit — C4's opening orientation — and of nothing else. It is NOT
#     evidence of a loose C2/C3/C5: adding C3 multiplies a fiber count by exactly
#     1 or exactly 0 (it is constant on the fiber, (3)), never by 7/11. So a
#     routine returning 2,703,360 is under-CONSTRAINED in one specific place and
#     is fixed by pinning the opening, not by tightening anything else.
#     `_fiber_diagnose` turns that into a machine verdict.
#
#     The two openings are NOT equal (983,040 ≠ 1,720,320) even though
#     complementation is an exact symmetry of C1∩C2∩C3∩C5 (SPECIFICATION.md
#     §Complement Z₂). Complementation moves the PAIR ORDERING as well as the
#     orientations — comp{a,b} = {63−a, 63−b} is a different pair unless the pair
#     is self-complementary — so it does not act inside one ordering's fiber.
#     Reasoning "the symmetry doubles it" yields 3,440,640, a third distinct
#     wrong answer, classified separately below so the two are never conflated.
# ===========================================================================

_FIBER_CLS = (1, 2, 3, 4, 6)      # C2 forbids 5; 0 cannot occur between distinct hexagrams


def _fiber_diagnose(measured, oriented=1_720_320, flipped=983_040):
    """WHY a fiber count missed its anchor — not merely THAT it did.

    Pure integer arithmetic over the three published fiber sizes: no DP, no
    tables, no King Wen. That is deliberate. It lets tests.py drive this
    classifier through the exact historical defect it exists to catch (a
    routine that returned 2,703,360) WITHOUT running the routine it guards,
    which is what "prove the gate fires against its own motivating example"
    requires.

    Returns (verdict, evidence). The evidence always names the observed ratio,
    so a failure report says what the count was off BY and which constraint to
    look at — never just "MISMATCH".
    """
    from math import gcd
    both = oriented + flipped
    if measured == oriented:
        return ("OK", f"{measured:,} == TR-1 §7's C4-oriented fiber")
    if measured == both:
        return ("C4-OPENING-NOT-PINNED",
                f"{measured:,} = {oriented:,} + {flipped:,}: BOTH opening orientations "
                f"were summed, so this is the pair-only-C4 fiber. Ratio to the anchor is "
                f"exactly 11/7 (165·2¹⁴ / 105·2¹⁴) — the signature of one unpinned bit, "
                f"C4's opening. FIX: pin the opening hexagram to 63. Do NOT tighten "
                f"C2/C3/C5: C3 is constant on a fiber, so it cannot contribute a 7/11.")
    if measured == flipped:
        return ("OPENING-PINNED-TO-THE-WRONG-SIDE",
                f"{measured:,} is the opening-(0,63) fiber; ratio to the anchor is exactly "
                f"4/7. The opening WAS pinned — to 0 instead of 63.")
    if measured == 2 * oriented:
        return ("SYMMETRY-DOUBLED",
                f"{measured:,} = 2 × {oriented:,}: the complement-Z₂ trap. Complementation "
                f"permutes the PAIR ORDERING too, so it does not act inside one ordering's "
                f"fiber; the true both-openings total is {both:,}, not {2 * oriented:,}.")
    if measured == 0:
        return ("EMPTY-FIBER",
                "no orientation vector survived. B0, the distance-class set or the opening "
                "is wrong — a real ordering's own stored orientation is a member of its "
                "fiber by construction, so 0 is impossible for a correct routine.")
    g = gcd(abs(measured), oriented) or 1
    return ("UNCLASSIFIED",
            f"{measured:,} vs anchor {oriented:,}; ratio = {measured // g}/{oriented // g}. "
            f"Not 11/7 (unpinned opening), not 4/7 (wrong side), not 2 (symmetry-doubled), "
            f"not 0 — so this is NOT an opening-orientation defect. Check B0 (must be "
            f"(2,8,13,7,1), Σ=31) and the distance-class set (1,2,3,4,6).")


_FIBER_ANCHOR = None


def _fiber_anchor():
    """THE FIRST ASSERTION — King Wen's own fiber, before anything else answers.

    TR-1 §7's C4-oriented fiber is 1,720,320. Every public fiber entry point
    calls this before it returns a number, so a wrong budget table can never
    reach a caller. Memoized: one 31-step DP per process, not one per record.

    Raises RuntimeError carrying `_fiber_diagnose`'s verdict AND its reason.
    """
    global _FIBER_ANCHOR
    if _FIBER_ANCHOR is not None:
        return _FIBER_ANCHOR
    ident = list(range(32))
    oriented = _fiber_count_raw(ident, 63)
    flipped = _fiber_count_raw(ident, 0)
    checks = (
        ("C4-oriented fiber (TR-1 §7)",     oriented,                  1_720_320),
        ("flipped-opening fiber",           flipped,                     983_040),
        ("pair-only-C4 fiber",              oriented + flipped,        2_703_360),
        ("TR-1's 3·5·7·2¹⁴ factorization",  oriented,        3 * 5 * 7 * 2 ** 14),
        ("the exact 4/7 identity",          7 * flipped,          4 * oriented),
        ("the exact 11/7 identity",         7 * (oriented + flipped), 11 * oriented),
    )
    bad = [(n, got, want) for (n, got, want) in checks if got != want]
    if bad:
        verdict, why = _fiber_diagnose(oriented)
        detail = "; ".join(f"{n}: got {got:,}, want {want:,}" for n, got, want in bad)
        raise RuntimeError(f"FIBER ANCHOR FAILED [{verdict}] — {why}  ({detail})")
    _FIBER_ANCHOR = (oriented, flipped)
    return _FIBER_ANCHOR


_C3_COUPLES = None


def _c3_couples():
    """The complement-couple GRAPH on pair indices, plus its known-answer anchor.

    C3 couples each pair to the pair holding its complement, so it is a graph
    over pairs, not a chain along slots — which is exactly why a path-carrying
    DP looked necessary. It is not; see (3) in the header. Building the graph
    once lets `c3_of_ordering` evaluate C3 from the slot map alone.

    Returns (cross, selfc): the 12 two-element couples {p, q} with p < q, and
    the 8 self-complementary pairs (which contribute the constant 16).
    """
    global _C3_COUPLES
    if _C3_COUPLES is not None:
        return _C3_COUPLES
    idx = {frozenset(pr): p for p, pr in enumerate(PAIRS)}
    cross, selfc = [], []
    for p, (a, b) in enumerate(PAIRS):
        key = frozenset((a ^ 63, b ^ 63))
        if key not in idx:
            raise RuntimeError(f"c3: the complement of pair {p} is not a C1 pair — the "
                               f"pair set is not closed under complementation")
        q = idx[key]
        if q == p:
            selfc.append(p)
        elif p < q:
            cross.append((p, q))
    if len(cross) != 12 or len(selfc) != 8 or 2 * len(cross) + len(selfc) != 32:
        raise RuntimeError(f"c3: couple graph is malformed — {len(cross)} cross-couples and "
                           f"{len(selfc)} self-complementary pairs (want 12 and 8, 2·12+8=32)")
    # KNOWN-ANSWER ANCHOR, written before the routine is trusted: the identity
    # permutation IS King Wen's own slot map (PAIRS[i] is KW's pair at slot i),
    # and KW's C3 is 776 (SPECIFICATION.md §C3: 12.125 × 64).
    g = sum(abs(p - q) for p, q in cross)
    if 16 + 8 * g != 776:
        raise RuntimeError(f"c3: KNOWN-ANSWER ANCHOR FAILED — 16 + 8·G = {16 + 8 * g} on "
                           f"King Wen's own ordering, but KW's C3 is 776. G came out "
                           f"{g}, want {(776 - 16) // 8}.")
    _C3_COUPLES = (tuple(cross), tuple(selfc))
    return _C3_COUPLES


def c3_of_ordering(perm):
    """C3 EVALUATED WITHOUT CARRYING THE PATH.

    C3 = 16 + 8·G,  G = Σ over the 12 complement-couples of |slot(P) − slot(P′)|.
    G reads the SLOT MAP only, so:
      * C3 is independent of the orientation vector → CONSTANT on a fiber, and
        enters as one admissibility flag on the whole fiber, computed before the
        DP starts rather than inside it;
      * C3 is independent of the walk order → no prefix, no path, no DP state.
    Cost is 12 subtractions for any ordering. `perm[s]` is the pair index at
    slot s. Returns the integer C3 (King Wen's is 776; C3-valid means ≤ 776).
    """
    cross, _selfc = _c3_couples()
    if sorted(perm) != list(range(32)):
        raise ValueError("c3_of_ordering: perm is not a permutation of the 32 pairs")
    slot = [0] * 32
    for s, p in enumerate(perm):
        slot[p] = s
    return 16 + 8 * sum(abs(slot[p] - slot[q]) for p, q in cross)

def _fiber_dp():
    """Forward/backward transfer DP over King Wen's OWN pair sequence, varying only
    the 32 within-pair orientations.

    Two facts make the orientation fiber a small exact computation rather than a
    2^31 search, and both are re-derived here rather than assumed:
      * within-pair distances do not depend on orientation (a pair's two members are
        fixed; orientation only swaps their order), so constraining C5's full 63-value
        multiset is equivalent to constraining the 31 BETWEEN-pair values;
      * C3 = 16 + 8*G and the orientation bits cancel in G, so C3 is CONSTANT across
        the fiber and imposes nothing on it.
    So the fiber is exactly {orientation vectors : no boundary distance = 5 (C2), and
    the boundary multiset equals King Wen's own}. The budget B0 is recomputed from KW
    here, not copied from any report.

    Returns (B0, F, B) where F[i] maps (entry-hexagram-of-slot-i, budget-consumed) to
    the number of ways to reach it, and B[i] maps the same state to the number of
    completions from slot i through slot 31 landing exactly on B0.
    """
    from collections import Counter, defaultdict
    kwb = Counter(hamming(KW[2 * i + 1], KW[2 * i + 2]) for i in range(31))
    if set(kwb) - set(_FIBER_CLS):
        raise RuntimeError(f"fiber: KW boundary multiset has an out-of-class value: {dict(kwb)}")
    B0 = tuple(kwb.get(c, 0) for c in _FIBER_CLS)

    # backward: completions[i][(last, budget)] = ways to finish slots i..31 on exactly B0
    B = [defaultdict(int) for _ in range(33)]
    # seed at slot 32 (past the end): only the exactly-consumed budget completes
    B[32][None] = 1

    succ = lambda i, last, bud: _fiber_succ(i, last, bud, B0)

    # enumerate reachable states forward first, so the backward pass has a domain
    F = [defaultdict(int) for _ in range(33)]
    a, b = PAIRS[0]
    zero = (0,) * len(_FIBER_CLS)
    for o, (f, s) in enumerate(((a, b), (b, a))):
        F[1][(s, zero, f)] += 1
    for i in range(1, 32):
        for (last, bud, _open), cnt in F[i].items():
            for o, s, nb in succ(i, last, bud):
                F[i + 1][(s, nb, _open)] += cnt

    # backward counts, keyed the same way minus the opening marker
    Bk = [defaultdict(int) for _ in range(33)]
    for (last, bud, _open) in F[32]:
        Bk[32][(last, bud)] = 1 if bud == B0 else 0
    for i in range(31, 0, -1):
        seen = {(l, bd) for (l, bd, _o) in F[i]}
        for (last, bud) in seen:
            t = 0
            for o, s, nb in succ(i, last, bud):
                t += Bk[i + 1].get((s, nb), 0)
            Bk[i][(last, bud)] = t
    return B0, F, Bk

def recount_fiber():
    """A7: independently recount TR-1 §7's orientation fiber — the frozen dispositive
    null for the eleven-functional battery — and the forced/free structure of its bits."""
    B0, F, Bk = _fiber_dp()
    tot = {63: 0, 0: 0}
    for (last, bud, opening), cnt in F[1].items():
        tot[opening] = tot.get(opening, 0) + cnt * Bk[1].get((last, bud), 0)
    oriented = tot.get(63, 0)          # opening (63, 0) — C4 as defined
    flipped = tot.get(0, 0)            # opening (0, 63) — pair-only reading of C4
    both = oriented + flipped

    # which slots are genuinely free (both orientations occur somewhere in the fiber)?
    forced = []
    for i in range(1, 32):
        per = [0, 0]
        for (last, bud, opening), cnt in F[i].items():
            if opening != 63:
                continue               # forced-bit claim is stated on the C4-oriented fiber
            for o, s, nb in _fiber_succ(i, last, bud, B0):
                per[o] += cnt * Bk[i + 1].get((s, nb), 0)
        if per[0] == 0 or per[1] == 0:
            forced.append(i)

    print("=" * 74)
    print("verify.py --recount-fiber : TR-1 §7 orientation fiber, independent recount")
    print("transfer DP over KW's own pair order; B0 recomputed from KW, not copied")
    print("=" * 74)
    print(f"  boundary budget B0 (d=1,2,3,4,6)            : {B0}  (sum {sum(B0)})")
    rows = [
        ("C4-oriented fiber  (opening 63,0)", 1_720_320, oriented),
        ("pair-only C4 fiber (both openings)", 2_703_360, both),
        ("  of which opening (0,63)", 983_040, flipped),
    ]
    ok = True
    for name, pub, mine in rows:
        m = "MATCH" if pub == mine else "*** MISMATCH ***"
        ok &= (pub == mine)
        print(f"  {name:<42} published {pub:>10,}  ours {mine:>10,}  {m}")
    # TR-1 states the fiber size factors as 3*5*7*2^14
    fact = 3 * 5 * 7 * 2 ** 14
    print(f"  factorization 3·5·7·2¹⁴ = {fact:,}"
          f"                     {'MATCH' if fact == oriented else '*** MISMATCH ***'}")
    ok &= (fact == oriented)
    print(f"  forced bits among slots 1..31              : {forced if forced else 'none'}")
    print(f"    -> {31 - len(forced)} of 31 vary somewhere in the fiber"
          f"  (TR-1 says 30, forced slot 30) "
          f"{'MATCH' if forced == [30] else '*** CHECK ***'}")
    ok &= (forced == [30])
    print("=" * 74)
    if ok:
        print("RESULT: ALL MATCH — TR-1 §7's fiber is now two-instrument")
        return 0
    # Say WHY, not just THAT. `_fiber_diagnose` is pure arithmetic on the three
    # published sizes and is unit-tested against the historical 2,703,360 defect,
    # so this verdict is itself gated rather than advisory.
    verdict, why = _fiber_diagnose(oriented)
    print(f"RESULT: *** MISMATCH — verdict [{verdict}]")
    print(f"        {why}")
    return 1

def _fiber_succ(i, last, bud, B0):
    a, b = PAIRS[i]
    for o, (f, s) in enumerate(((a, b), (b, a))):
        if last is None:
            yield o, s, bud
            continue
        d = hamming(last, f)
        if d not in _FIBER_CLS:
            continue
        j = _FIBER_CLS.index(d)
        nb = list(bud); nb[j] += 1
        if nb[j] > B0[j]:
            continue
        yield o, s, tuple(nb)

# ---------------------------------------------------------------------------
# A1 (2026-08-01): the orientation fiber of an ARBITRARY C1 pair ordering.
#
# `_fiber_dp` / `recount_fiber` above answer TR-1 §7's question — the fiber of
# King Wen's OWN ordering, with the forced/free bit structure. The block below
# answers the *counting-convention* question instead. A record in solutions.bin
# is a PAIR ORDERING with orientation collapsed (SOLUTIONS_FORMAT.md §"The
# output counts unique pair orderings, not unique oriented sequences"), while
# the C1–C5 space estimate counts orientation-explicit SEQUENCES. The exact
# conversion between the two levels is the fiber size, ordering by ordering:
#
#     N = Σ over valid pair orderings P of |fiber(P)|      (sequences)
#     R = # of P with |fiber(P)| ≥ 1                       (records)
#     mean fiber = N / R = the orientation-dedup factor
#
# Which constraints see orientation at all:
#   C1 (pair structure)  orientation-BLIND — C1 fixes the SET of 32 pairs, and
#                        a pair is the same pair either way round.
#   C4 (opening)         pins pair {63,0} at slot 0 and, as defined, its
#                        orientation (63 then 0), so exactly 31 bits are free.
#   C2 (no distance 5)   orientation-SENSITIVE, but only across pair boundaries:
#                        d(a,b) = d(b,a), so the 32 within-pair distances are
#                        orientation-invariant — and none of them is 5.
#   C5 (distance multiset) orientation-SENSITIVE in the same place and for the
#                        same reason. The within-pair multiset is {2:12, 4:12,
#                        6:8} for EVERY C1 ordering under EVERY orientation
#                        vector, so C5 reduces to a fixed budget B0 on the 31
#                        BETWEEN-pair distances, identical for every ordering.
#   C3 (complement dist) orientation-BLIND: C3 = 16 + 8·G, G = Σ over the 12
#                        complement-couples of |slot(P) − slot(P′)|
#                        (lean/C3Decomposition.lean; TR-11 §10(ii)). The 8
#                        self-complementary pairs sit at adjacent positions and
#                        contribute 1 each way whichever member leads (the 16);
#                        inside a couple at slots i<j the two members' distances
#                        sum to 4(j−i) with both orientations cancelling. So C3
#                        is CONSTANT on a fiber — it decides WHICH orderings
#                        have a fiber, never which orientations are in it.
#
# The fiber is therefore exactly the set of orientation vectors whose 31
# between-pair distances avoid 5 and realise B0 — a transfer DP over
# (exit hexagram, budget consumed) in 31 steps. Exact, not a sample.
# ---------------------------------------------------------------------------

_FIBER_CODE_BITS = 13     # budget codes occupy 6,048 < 2^13 values
_FIBER_TABLES = None

def _fiber_tables():
    """Build (once) the residual between-pair budget B0 and the mixed-radix
    budget-increment tables the arbitrary-ordering DP runs on.

    B0 is DERIVED, not copied: C5's full 63-value multiset minus the
    orientation- and ordering-invariant within-pair multiset. It is then
    cross-checked against King Wen's own 31 between-pair distances, which must
    agree — two derivations of the same universal budget."""
    global _FIBER_TABLES
    if _FIBER_TABLES is not None:
        return _FIBER_TABLES
    from collections import Counter
    full = Counter(hamming(KW[i], KW[i + 1]) for i in range(63))
    within = Counter(hamming(a, b) for a, b in PAIRS)
    if 5 in within:
        raise RuntimeError("fiber: a within-pair distance is 5 — C1 and C2 would be "
                           "unsatisfiable together; tables are wrong")
    resid = full - within
    if sum(resid.values()) != 31 or (set(resid) - set(_FIBER_CLS)):
        raise RuntimeError(f"fiber: residual between-pair budget is malformed: {dict(resid)}")
    betw = Counter(hamming(KW[2 * i + 1], KW[2 * i + 2]) for i in range(31))
    if resid != betw:
        raise RuntimeError(f"fiber: C5-minus-within budget {dict(resid)} disagrees with "
                           f"KW's own between-pair multiset {dict(betw)}")
    B0 = tuple(resid.get(c, 0) for c in _FIBER_CLS)

    ham = [[bin(x ^ y).count('1') for y in range(64)] for x in range(64)]
    clsidx = [-1] * 7
    for j, c in enumerate(_FIBER_CLS):
        clsidx[c] = j
    pv, r = [], 1
    for c in B0:
        pv.append(r)
        r *= (c + 1)
    ncode = r
    if ncode > (1 << _FIBER_CODE_BITS):
        raise RuntimeError(f"fiber: budget code space {ncode} exceeds the packing width")
    full_code = sum(B0[j] * pv[j] for j in range(len(B0)))
    add = []
    for j in range(len(B0)):
        col = [-1] * ncode
        for code in range(ncode):
            if (code // pv[j]) % (B0[j] + 1) < B0[j]:
                col[code] = code + pv[j]
        add.append(col)
    _FIBER_TABLES = (B0, ham, clsidx, add, full_code)
    return _FIBER_TABLES

def _fiber_count_raw(perm, opening=63, fixed=None):
    """The DP itself, UNANCHORED — call `fiber_count` instead.

    Split out so `_fiber_anchor` can compute King Wen's fiber without calling
    the anchored wrapper and recursing. Nothing else should call this.

    EXACT size of the orientation fiber over the pair ordering `perm`.

    `perm` is a list of 32 pair indices (the record's pair identities, slot by
    slot); `opening` is the hexagram leading slot 0 — 63 for C4 as defined
    (the C4-oriented fiber), 0 for the flipped opening of the pair-only reading.
    `fixed`, if given, maps slot -> orientation bit (0 = PAIRS[p] as stored,
    1 = reversed, matching the record encoding) and counts only the sub-fiber
    agreeing with it — the hook the brute-force cross-check in tests.py drives.

    Returns the number of orientation vectors for the remaining 31 slots that
    satisfy C2 and C5 — which, C3 being constant on the fiber and C1 being
    orientation-blind, is the number of C1–C5 sequences collapsing to this one
    record, provided the record satisfies C3 at all (every record in a
    solutions.bin does, by construction).

    This is a DP over 31 steps, not a search over 2^31 vectors, and not a
    sample. Cost is ~0.2 ms per ordering in CPython."""
    B0, ham, clsidx, add, full_code = _fiber_tables()
    if sorted(perm) != list(range(32)):
        raise ValueError("fiber_count: perm is not a permutation of the 32 pairs")
    a0, b0 = PAIRS[perm[0]]
    if {a0, b0} != {63, 0}:
        raise ValueError("fiber_count: C4 requires pair {63, 0} at slot 0")
    if opening == a0:
        exit0 = b0
    elif opening == b0:
        exit0 = a0
    else:
        raise ValueError("fiber_count: opening must be 63 or 0")
    cur = {(exit0 << _FIBER_CODE_BITS): 1}
    mask = (1 << _FIBER_CODE_BITS) - 1
    for i in range(1, 32):
        a, b = PAIRS[perm[i]]
        opts = ((a, b), (b, a))
        if fixed is not None and i in fixed:
            opts = (opts[fixed[i]],)
        nxt = {}
        get = nxt.get
        for key, cnt in cur.items():
            row = ham[key >> _FIBER_CODE_BITS]
            code = key & mask
            for f, s in opts:
                # C2 (no 5) and "must be a class C5 budgets" are the same test
                # here: B0 has no 5, so C5 already implies C2 — see
                # test_the_two_redundancies_in_the_fiber_dp_are_real.
                j = clsidx[row[f]]              # distance 5 (and 0) -> -1
                if j < 0:
                    continue
                nc = add[j][code]               # C5: class j budget exhausted -> -1
                if nc < 0:
                    continue
                k = (s << _FIBER_CODE_BITS) | nc
                nxt[k] = get(k, 0) + cnt
        cur = nxt
        if not cur:
            return 0
    # 31 boundaries placed and every class capped at B0 => any survivor is exactly on
    # budget; the filter is kept so the exactness is asserted rather than argued.
    return sum(c for k, c in cur.items() if (k & mask) == full_code)


def fiber_count(perm, opening=63, fixed=None):
    """EXACT orientation-fiber size over `perm`, King-Wen-anchored.

    The public entry point. `_fiber_anchor()` runs FIRST — before this call can
    return any number — so King Wen's 1,720,320 is asserted ahead of the answer
    rather than checked after it. The anchor is memoized, so the guarantee costs
    one 31-step DP per process even when sweeping millions of records.

    See `_fiber_count_raw` for the DP and its arguments.
    """
    _fiber_anchor()
    return _fiber_count_raw(perm, opening, fixed)

def _fiber_records(path, limit=None):
    """Yield (index, perm, orient) for each record of a solutions.bin, gzipped or
    raw. Small-file path: the whole file is read into memory, so this is for the
    repo's sample artifact, not for a multi-hundred-GB canonical."""
    with open(path, 'rb') as fh:
        head = fh.read(2)
    blob = gzip.open(path, 'rb').read() if head == b'\x1f\x8b' else open(path, 'rb').read()
    if blob[:4] != b'ROAE':
        raise RuntimeError(f"{path}: not a ROAE solutions.bin (magic {blob[:4]!r})")
    n = struct.unpack('<Q', blob[8:16])[0]
    if 32 + 32 * n != len(blob):
        raise RuntimeError(f"{path}: header says {n} records but the body is "
                           f"{len(blob) - 32} bytes")
    if limit is not None:
        n = min(n, limit)
    for i in range(n):
        rec = blob[32 + 32 * i: 64 + 32 * i]
        yield i, [(x >> 2) & 0x3F for x in rec], [(x >> 1) & 1 for x in rec]

def fiber_sweep(path=None):
    """A1: measure the ORIENTATION-FIBER FACTOR — the exact conversion between
    the two counting levels the suite publishes side by side.

    Gates first (KW's own fiber, three published values, plus agreement with the
    independent `_fiber_dp` instrument), then, if a solutions.bin is present,
    reports the exact fiber-size distribution over its records."""
    import math
    B0, _ham, _ci, _add, _fc = _fiber_tables()
    ident = list(range(32))
    print("=" * 78)
    print("verify.py --fiber-sweep : the orientation-fiber factor, measured")
    print("=" * 78)
    print(f"  residual between-pair budget B0 (d=1,2,3,4,6) : {B0}  (sum {sum(B0)})")
    print("  derived as C5's 63-value multiset minus the within-pair multiset,")
    print("  cross-checked against KW's own 31 between-pair distances.")
    print()
    print("  GATE — King Wen's own pair ordering (TR-1 §7), asserted FIRST:")
    ok = True
    try:
        oriented, flipped = _fiber_anchor()
    except RuntimeError as e:
        print(f"    *** {e}")
        print("\n*** GATE FAILED — the fiber routine is wrong; every number below is void.")
        return 1
    for name, pub, mine in (("C4-oriented fiber  (opening 63,0)", 1_720_320, oriented),
                            ("pair-only C4 fiber (both openings)", 2_703_360, oriented + flipped),
                            ("  of which opening (0,63)", 983_040, flipped),
                            ("factorization 3·5·7·2¹⁴", 3 * 5 * 7 * 2 ** 14, oriented)):
        good = (pub == mine)
        ok &= good
        print(f"    {name:<38} published {pub:>10,}  ours {mine:>10,}  "
              f"{'MATCH' if good else '*** MISMATCH ***'}")
    # cross-instrument: the KW-only transfer DP above must agree slot for slot
    _B0x, Fx, Bkx = _fiber_dp()
    tot = {63: 0, 0: 0}
    for (last, bud, op), cnt in Fx[1].items():
        tot[op] = tot.get(op, 0) + cnt * Bkx[1].get((last, bud), 0)
    agree = (tot.get(63, 0) == oriented and tot.get(0, 0) == flipped)
    ok &= agree
    print(f"    {'vs the independent _fiber_dp instrument':<38} "
          f"{'MATCH' if agree else '*** MISMATCH ***'}")
    if not ok:
        print("\n*** GATE FAILED — the fiber routine is wrong; every number below is void.")
        return 1

    print()
    print("  PROVEN floor on the dedup factor (no compute, no sampling):")
    print("    a record is a permutation of the 31 non-opening pairs, so the number")
    print("    of records R is at most 31! = 8.222839e33. With the EXACT")
    print("    |C1∩C2∩C4∩C5| = 1.097051e39 (TR-11 §9), mean fiber = N/R ≥ N/31! =")
    print("    1.3342e5. The published '~4×' orientation-dedup factor is therefore")
    print("    low by at least four and a half orders of magnitude.")

    if path is None:
        path = 'solutions.bin'
    if not os.path.exists(path):
        print(f"\n  (no {path} present — sample sweep skipped; the gate above is the result)")
        return 0

    print()
    print(f"  SAMPLE SWEEP — exact fiber of every record in {path}:")
    sizes, zero, kw_seen = [], 0, False
    for i, perm, orient in _fiber_records(path):
        if perm == ident:
            kw_seen = True
        f = fiber_count(perm, 63)
        if f == 0:
            zero += 1
        sizes.append(f)
    if zero:
        print(f"    *** {zero} record(s) have an EMPTY fiber — impossible, since the "
              f"record's own stored orientation is in it. The routine is wrong.")
        return 1
    sizes.sort()
    n = len(sizes)
    am = sum(sizes) / n
    gm = math.exp(sum(math.log(s) for s in sizes) / n)
    print(f"    records swept                : {n:,}"
          f"{'  (King Wen included)' if kw_seen else ''}")
    print(f"    empty fibers                 : 0  (every record admits its own orientation)")
    print(f"    min / median / max           : {sizes[0]:,} / {sizes[n // 2]:,} / {sizes[-1]:,}")
    print(f"    ARITHMETIC MEAN (dedup factor over this population) : {am:,.1f}")
    print(f"    geometric mean               : {gm:,.1f}")
    print(f"    King Wen's own fiber         : {oriented:,}"
          f"   (percentile {100.0 * sum(1 for s in sizes if s < oriented) / n:.2f})")
    print()
    print("    SCOPE — this is the mean over ONE budget-truncated sample, not over the")
    print("    C1–C5 space. It is an unbiased estimate of N/R only for the population")
    print("    this file enumerates. See A1_ORIENTATION_FIBER_MEASUREMENT.md for the")
    print("    run that would settle the whole-space value.")
    print("=" * 78)
    return 0

def _gender6(h):
    """Schulz 1990 / Cook 2006 minority-line gender of a 6-bit hexagram
    (published definition: SOLVE_C_CLI.md §--rc4b-verify): popcount < 3 male
    ('M'), popcount > 3 female ('F'); popcounts {0, 3, 6} exempt ('N').
    Inversion (rev) preserves popcount, so gender is inversion-class-invariant."""
    pc = bin(h).count('1')
    return 'N' if pc in (0, 3, 6) else ('M' if pc < 3 else 'F')

def _rc4_violations_indep(seq):
    """Independent implementation of the Schulz-1990 gender/position-parity
    violation count, rebuilt from the PUBLISHED definition (SOLVE_C_CLI.md
    §--rc4b-verify; LITERATURE_RULES_POPULATION_TESTS.md §Schulz gender rule):
    over the 36 inversion-class positions in FIRST-OCCURRENCE order, a male
    class (popcount < 3) belongs at an odd class position and a female class
    (popcount > 3) at an even one; exempt classes ({0,3,6}) never violate.
    Returns (violation_count, sorted list of violating class positions,
    1-based).  KW's published anchors: exactly 2, at class positions 25/26."""
    order, seen = [], set()
    for h in seq:
        cls = min(h, _rev6(h))            # inversion-class representative
        if cls not in seen:
            seen.add(cls)
            order.append(cls)
    viol = []
    for i, cls in enumerate(order):
        p = i + 1                          # 1-based class position
        g = _gender6(cls)
        if (g == 'M' and p % 2 == 0) or (g == 'F' and p % 2 == 1):
            viol.append(p)
    return len(viol), viol

def _gender_null_distribution():
    """Exact distribution of rc4 violations under TR-8's pair-only (C1) null —
    KW's 32 canonical pairs in uniformly random order, each independently in
    either orientation (32!·2^32 members) — computed two structurally different
    exact ways and cross-asserted, returned as {violations: Fraction}.

    Structure (derived here from the C1 primitives, not copied): 28 of the
    pairs are inversion pairs (both members one class); 4 are
    palindrome-complement pairs (two singleton classes each), 28 + 8 = 36
    classes.  A palindrome pair consumes TWO class positions, so it never
    changes the running parity of the class counter; hence the class-position
    parity of the i-th inversion pair (by rank among inversion pairs alone) is
    just the parity of i, and the inversion-pair violations are a
    multivariate-hypergeometric functional of a uniform arrangement of the
    male/female/exempt inversion classes over 14 odd + 14 even alternating
    slots.  Each male+female palindrome pair spans one odd and one even class
    position, so by its own independent orientation bit it contributes 0 or 2
    violations with probability 1/2 each, independently of everything else
    (the exempt+exempt palindrome pair contributes 0).  Method 1 evaluates
    that closed form; method 2 is a slot-by-slot DP over pair types that never
    uses the decomposition.  Both are exact (Fractions throughout; no
    sampling); they must agree term-by-term."""
    from fractions import Fraction
    from math import comb, factorial
    from collections import defaultdict

    # --- classify the 32 canonical pairs from the C1 primitives ---
    inv_genders, pal_pairs = [], []
    for a, b in PAIRS:
        if _rev6(a) == b:                  # inversion pair: one class
            if _gender6(a) != _gender6(b):
                raise RuntimeError("gender not inversion-class-invariant")
            inv_genders.append(_gender6(a))
        else:                              # palindrome-complement pair: two classes
            if not (_rev6(a) == a and _rev6(b) == b and b == _comp6(a)):
                raise RuntimeError(f"pair ({a},{b}) is neither inversion nor "
                                   "palindrome-complement")
            pal_pairs.append(frozenset((_gender6(a), _gender6(b))))
    if len(inv_genders) != 28 or len(pal_pairs) != 4:
        raise RuntimeError("expected 28 inversion + 4 palindrome-complement pairs")
    m = inv_genders.count('M')
    f = inv_genders.count('F')
    e = inv_genders.count('N')
    n_mf = pal_pairs.count(frozenset(('M', 'F')))
    n_ee = pal_pairs.count(frozenset(('N',)))
    if n_mf + n_ee != 4:
        raise RuntimeError("unexpected palindrome-pair gender composition")

    # --- method 1: closed form (hypergeometric arrangement x binomial) ---
    n_odd = (28 + 1) // 2                  # inversion-class slots at odd positions
    n_even = 28 - n_odd
    total = factorial(28) // (factorial(m) * factorial(f) * factorial(e))
    inv_counts = defaultdict(int)          # violations from inversion classes
    for j in range(m + 1):                 # males at even class positions
        for k in range(f + 1):             # females at odd class positions
            if f - k > n_even - j or k > n_odd - (m - j):
                continue
            n = (comb(n_even, j) * comb(n_even - j, f - k)
                 * comb(n_odd, m - j) * comb(n_odd - (m - j), k))
            if n:
                inv_counts[j + k] += n
    if sum(inv_counts.values()) != total:
        raise RuntimeError("hypergeometric arrangement count does not close")
    dist_cf = defaultdict(Fraction)
    for b in range(n_mf + 1):              # MF palindrome pairs each add 0 or 2, p=1/2
        pb = Fraction(comb(n_mf, b), 2 ** n_mf)
        for v, n in inv_counts.items():
            dist_cf[v + 2 * b] += pb * Fraction(n, total)

    # --- method 2: slot-by-slot DP over pair types (no decomposition) ---
    # state: (males, females, exempt-inv, MF-palindrome, EE-palindrome used;
    # violations so far) -> probability.  The next class position is forced by
    # the counts (palindrome pairs consume two class positions).
    states = {(0, 0, 0, 0, 0, 0): Fraction(1)}
    for step in range(32):
        nxt = defaultdict(Fraction)
        rem_total = 32 - step
        for (mu, fu, eu, mfu, eeu, v), p in states.items():
            cpos = mu + fu + eu + 2 * (mfu + eeu) + 1
            odd = (cpos % 2 == 1)
            for t, r in (('M', m - mu), ('F', f - fu), ('N', e - eu),
                         ('MF', n_mf - mfu), ('EE', n_ee - eeu)):
                if not r:
                    continue
                w = p * Fraction(r, rem_total)
                if t == 'M':
                    nxt[(mu + 1, fu, eu, mfu, eeu, v + (0 if odd else 1))] += w
                elif t == 'F':
                    nxt[(mu, fu + 1, eu, mfu, eeu, v + (1 if odd else 0))] += w
                elif t == 'N':
                    nxt[(mu, fu, eu + 1, mfu, eeu, v)] += w
                elif t == 'EE':
                    nxt[(mu, fu, eu, mfu, eeu + 1, v)] += w
                else:                      # MF: one odd + one even class position;
                    half = w / 2           # orientation picks 0 or 2 violations
                    nxt[(mu, fu, eu, mfu + 1, eeu, v)] += half
                    nxt[(mu, fu, eu, mfu + 1, eeu, v + 2)] += half
        states = nxt
    dist_dp = defaultdict(Fraction)
    for (mu, fu, eu, mfu, eeu, v), p in states.items():
        dist_dp[v] += p

    strip = lambda d: {v: p for v, p in d.items() if p}
    if strip(dist_cf) != strip(dist_dp):
        raise RuntimeError("closed form and slot DP disagree — investigate")
    if sum(dist_cf.values()) != 1:
        raise RuntimeError("distribution does not sum to 1")
    return strip(dist_cf)

def recount_gender_null():
    """--recount-gender-null: independently recompute TR-8 §Commands' exact
    pair-null Schulz-gender figure P(rc4_violations <= 2) = 47/445740
    (~1.054426e-04) — the probability that a uniformly random C1-preserving
    ordering (32 canonical pairs permuted uniformly, each pair independently in
    either orientation) matches King Wen's gender-rule compliance level (KW
    sits at exactly 2 violations, class positions 25/26).  The functional is
    rebuilt from the published definition (SOLVE_C_CLI.md §--rc4b-verify;
    Schulz 1990 motif 2, elaborated by Cook 2006), the null distribution is
    computed exactly two ways (closed form + slot DP, cross-asserted — see
    _gender_null_distribution), and KW's published anchors gate the reading of
    the definition.  Instant.  Does NOT read solutions.bin."""
    from fractions import Fraction
    ok = True

    nv, locus = _rc4_violations_indep(KW)
    dist = _gender_null_distribution()
    le2 = sum(p for v, p in dist.items() if v <= 2)

    print("=" * 74)
    print("verify.py --recount-gender-null : TR-8 exact pair-null gender figure")
    print("functional rebuilt from the published definition; 32!*2^32 null solved")
    print("exactly two ways (closed form + slot DP, cross-asserted); no sampling")
    print("=" * 74)
    rows = [
        ("KW rc4 violations (SOLVE_C_CLI anchor)", "2", str(nv)),
        ("KW violation locus (class positions)", "[25, 26]", str(locus)),
        ("P(rc4_violations <= 2), pair-only null", "47/445740", str(le2)),
        ("  same, decimal (TR-8 quotes 1.054426e-04)", "1.054426e-04",
         f"{float(le2):.6e}"),
    ]
    for name, pub, mine in rows:
        match = (pub == mine)
        ok &= match
        print(f"  {name:<44} published {pub:>13}  ours {mine:>13}  "
              f"{'MATCH' if match else '*** MISMATCH ***'}")
    print(f"  full distribution support                    : "
          f"{min(dist)}..{max(dist)} (mass sums to 1 exactly)")
    print(f"  P(= 0) {sum(p for v, p in dist.items() if v == 0)}   "
          f"P(= 1) {sum(p for v, p in dist.items() if v == 1)}   "
          f"P(= 2) {sum(p for v, p in dist.items() if v == 2)}")
    print("=" * 74)
    print("RESULT:", "ALL MATCH — TR-8's pair-null gender figure is now two-instrument"
          if ok else "*** MISMATCH — investigate ***")
    return 0 if ok else 1

def recount_subtree():
    """--recount-subtree: independently recompute the exact deterministic
    subtree anchors of TR-5 §3 / TR-4 §"validated" / SEARCH_SPACE_SIZE.md
    (KW-following prefixes at 5/7/9 free positions) and the sigma-related
    prefix tree-isomorphism check, plus TR-4 §4's uniqueness-refutation
    anchor (exactly 8 of the 16,504 canonical completions satisfy C6/C7),
    plus the three away-from-KW cross-instrument anchors of _CROSS_PREFIXES
    (expectations from solve.c --estimate-knuth exact mode; leaf C3 ranges
    528..624 / 1024..1104 / 736..840, so C3 is exercised well clear of the
    776 threshold in both directions, not only at KW's own neighbourhood).
    ~1-2 min in CPython (the two 9-free runs visit ~9.4M nodes each; the
    cross anchors add < 1 s).  Returns 0 iff every anchor matched.
    The FAST subset of these anchors (everything but the two 9-free trees)
    also runs on every `python3 tests.py` (TestSubtreeCrossAnchors); the full
    driver is wired into reports/certificates/verify_all.sh §2."""
    import time
    t0 = time.time()
    rc = [0]

    def gate(name, got, want, src="published"):
        ok = (want is None) or (got == want)
        if not ok:
            rc[0] = 1
        tag = "  --  " if want is None else (" MATCH" if ok else "*FAIL*")
        pub = "(no public target)" if want is None else f"{want:,}"
        print(f"[{tag}] {name}: recomputed {got:,}  {src} {pub}")

    for free, want_nodes, want_canon in ((5, 443, 4), (7, 62256, 2232),
                                         (9, 9422793, 16504)):
        d = 31 - free                    # KW-following prefix pairs 1..d
        nodes, leaves, canon, c67 = _exact_subtree(
            [(i, 0) for i in range(1, d + 1)])
        gate(f"KW prefix {free}-free tree_nodes", nodes, want_nodes)
        gate(f"KW prefix {free}-free leaves_C1C2C4C5", leaves, None)
        gate(f"KW prefix {free}-free canonical leaves", canon, want_canon)
        if free == 9:
            gate("KW prefix 9-free canonical AND C6/C7 (TR-4 'exactly 8')",
                 c67, 8)
    nodes, leaves, canon, _c67 = _exact_subtree(_SIGMA_PREFIX)
    gate("sigma-related prefix tree_nodes (isomorphism)", nodes, 9422793)
    gate("sigma-related prefix canonical leaves (isomorphism)", canon, 16504)
    for name, pfx, (wn, wl, wc, wx) in _CROSS_PREFIXES:
        nodes, leaves, canon, c67 = _exact_subtree(pfx)
        gate(f"{name} tree_nodes", nodes, wn, src="solve.c-exact")
        gate(f"{name} leaves_C1C2C4C5", leaves, wl, src="solve.c-exact")
        gate(f"{name} canonical leaves (C3)", canon, wc, src="solve.c-exact")
        gate(f"{name} C6/C7 (slot-24 pair != 24 forces 0)", c67, wx,
             src="definition-forced")
    print(f"recount-subtree: {'ALL MATCH' if rc[0] == 0 else '*** MISMATCH ***'}"
          f"  ({time.time() - t0:.0f}s)")
    return rc[0]

def recount_finite():
    """--recount-finite: independently recompute the finite record-mode and
    wrap/parity tallies (TR-5 §3; TR-6; SPECIFICATION wrap-parity theorem;
    CIRCULAR_KING_WEN).  Validity of each sigma(KW) is checked from the
    constraint definitions directly — NOT via group membership — so this is a
    second instrument for the 48-of-720 classification itself, not only for
    the group order.  Seconds.  Returns 0 iff everything matched."""
    import itertools
    from collections import Counter
    from math import comb
    from functools import lru_cache
    rc = [0]

    def gate(name, got, want):
        ok = (got == want)
        if not ok:
            rc[0] = 1
        print(f"[{' MATCH' if ok else '*FAIL*'}] {name}: recomputed {got!r}"
              f"  published {want!r}")

    kw_ms = sorted(hamming(KW[i], KW[i + 1]) for i in range(63))

    def classify(s):
        if any(s[2*i+1] != _partner(s[2*i]) for i in range(32)):
            return "C1"
        if any(hamming(s[i], s[i+1]) == 5 for i in range(63)):
            return "C2"
        if compute_comp_dist(s) > 776:
            return "C3"
        if not (s[0] == 63 and s[1] == 0):
            return "C4"
        if sorted(hamming(s[i], s[i+1]) for i in range(63)) != kw_ms:
            return "C5"
        return None

    valid, first_fail, recs, c3s = [], Counter(), set(), []
    for g in itertools.permutations(range(6)):
        s = [_apply_bitperm(g, h) for h in KW]
        why = classify(s)
        if why is None:
            valid.append(g)
            recs.add(tuple(frozenset((s[2*i], s[2*i+1])) for i in range(32)))
            c3s.append(compute_comp_dist(s))
        else:
            first_fail[why] += 1
    gate("48-of-720 sigma(KW) C1-C5-valid", len(valid), 48)
    gate("all 672 invalid images fail C1 first", first_fail.get("C1", 0), 672)
    gate("distinct canonical records (KW + twins)", len(recs), 24)
    kw_rec = tuple(frozenset((KW[2*i], KW[2*i+1])) for i in range(32))
    gate("KW's own record in the orbit", kw_rec in recs, True)
    gate("record-twin count", len(recs) - 1, 23)
    gate("every valid image's C3 sum", set(c3s), {776})
    cent = {g for g in itertools.permutations(range(6))
            if all(g[5 - i] == 5 - g[i] for i in range(6))}
    gate("valid set == centralizer of rev in S6", set(valid) == cent, True)

    cls = [bin(KW[2*i]).count('1') & 1 for i in range(32)]
    gate("pairs parity-homogeneous", all(
        (bin(KW[2*i]).count('1') & 1) == (bin(KW[2*i+1]).count('1') & 1)
        for i in range(32)), True)
    gate("pair-class split (E, O)", (cls.count(0), cls.count(1)), (16, 16))
    gate("first pair even class (C4 pin)", cls[0], 0)
    gate("linear parity-class alternations",
         sum(cls[i] != cls[i+1] for i in range(31)), 15)
    gate("circular parity-class alternations",
         sum(cls[i] != cls[(i+1) % 32] for i in range(32)), 16)
    lin = [hamming(KW[i], KW[i+1]) for i in range(63)]
    wrap = hamming(KW[63], KW[0])
    gate("linear C5 multiset", dict(Counter(lin)),
         {1: 2, 2: 20, 3: 13, 4: 19, 6: 9})
    gate("linear odd-distance count", sum(d & 1 for d in lin), 15)
    gate("wrap distance d(s63, s0)", wrap, 3)
    gate("wrap parity odd", wrap & 1, 1)
    gate("circular multiset (wrap added)", dict(Counter(lin + [wrap])),
         {1: 2, 2: 20, 3: 14, 4: 19, 6: 9})
    gate("circular odd-of-64 (McKenna 3:1)",
         sum(d & 1 for d in lin + [wrap]), 16)
    tp = [d & 1 for d in lin]
    gate("transition-parity switches", sum(tp[i] != tp[i+1] for i in range(62)), 30)

    @lru_cache(maxsize=None)
    def arr(pos, ones, last, alt):
        if alt > 15 or ones > 16 or pos - ones > 16:
            return 0
        if pos == 32:
            return 1 if (ones == 16 and alt == 15) else 0
        return sum(arr(pos + 1, ones + b, b,
                       alt + (0 if pos == 0 else int(b != last)))
                   for b in (0, 1))
    gate("15-alternation 16/16 arrangement count (DP)", arr(0, 0, 0, 0), 82818450)
    gate("same, closed form 2*C(15,7)^2", 2 * comb(15, 7) ** 2, 82818450)
    print("recount-finite:",
          "ALL MATCH" if rc[0] == 0 else "*** MISMATCH — investigate ***")
    return rc[0]


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

    rows.append(("C5 ladder n=18 {6.0,6.1,6.2}@0", None,
                 "re-countable via --recount-rung 18 (report-only: integer unpublished)",
                 None, "plain budgeted packed-state DP — recount_rung()"))
    rows.append(("C5 ladder n=19 {3.0,4.0,6.0,6.1}@0", 63244766587981824,
                 "re-countable via --recount-rung 19 (worker-sized: ~8 GB)",
                 None, "plain budgeted packed-state DP — recount_rung()"))
    for n, spec, pub in [
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


# ---------------------------------------------------------------------------
# LAYER-SIDECAR IDENTITIES  (--check-layer-sidecars)
#
# The f1c5 per-layer sidecars (f1c5_layer_stats_KK.json, written for resume) are
# already most of a checkable certificate. This validates the identities they must
# satisfy, reading ONLY the small JSON files — no layer-file I/O, so it costs
# nothing and runs anywhere, including long after the campaign VM is gone.
#
# The two load-bearing checks:
#   * marginal_last_mass and marginal_rid_mass are two INDEPENDENT decompositions
#     of the same mass_total (by terminal pair, and by boundary-residue id). Both
#     must sum to mass_total. A transfer/stabilizer bug generically breaks one.
#   * input_sha256_decompressed[k] == own_sha256_decompressed[k-1] chains the
#     layers into a single lineage — proving the retained set is one uninterrupted
#     run, not a mix of runs stitched across Spot evictions.
#
# NOTE (identity that looks right and is WRONG): entries_per_mask's min/max/mean
# and histogram are over NON-EMPTY masks, so they total n_masks - n_empty_masks,
# NOT n_masks. Layers with n_empty_masks == 0 pass the naive form by luck; k=1,2,3
# of the 2026-07-22 full-31 run have n_empty_masks == 1 and do not. Do not "fix" a
# failure here by relaxing to n_masks.
# ---------------------------------------------------------------------------

def check_layer_sidecars(dirpath):
    import json, glob, re
    files = sorted(glob.glob(os.path.join(dirpath, "f1c5_layer_stats_*.json")),
                   key=lambda p: int(re.search(r"_(\d+)\.json$", p).group(1)))
    if not files:
        print(f"no f1c5_layer_stats_*.json in {dirpath}")
        return 1

    man = {}
    mpath = os.path.join(dirpath, "f1c5_manifest.txt")
    if os.path.exists(mpath):
        for line in open(mpath):
            if "=" in line:
                k_, v_ = line.strip().split("=", 1)
                man[k_] = v_

    layers = {}
    for f in files:
        d = json.load(open(f))
        layers[d["k"]] = d

    fails, n = [], [0]
    def ck(cond, label):
        n[0] += 1
        if not cond:
            fails.append(label)

    print("=" * 74)
    print("verify.py --check-layer-sidecars : f1c5 per-layer sidecar identities")
    print(f"  dir      : {dirpath}")
    print(f"  layers   : k={min(layers)}..{max(layers)} ({len(layers)} sidecars)")
    if man:
        print(f"  manifest : n={man.get('n')} b0={man.get('b0')} pl_hash={man.get('pl_hash')}")
    print("=" * 74)

    for k in sorted(layers):
        d = layers[k]
        mt = int(d["mass_total"])
        nonempty = d["n_masks"] - d["n_empty_masks"]

        s_last = sum(int(v) for _, v in d["marginal_last_mass"])
        s_rid = sum(int(v) for _, v in d["marginal_rid_mass"])
        ck(s_last == mt, f"k={k}: sum(marginal_last_mass) != mass_total")
        ck(s_rid == mt, f"k={k}: sum(marginal_rid_mass) != mass_total")

        ck(sum(c for _, c in d["value_hist_log2"]) == d["n_entries"],
           f"k={k}: value_hist_log2 counts != n_entries")
        ck(sum(c for _, c in d["entries_per_mask"]["hist_log2"]) == nonempty,
           f"k={k}: entries_per_mask hist != n_masks - n_empty_masks")
        ck(sum(c for _, c in d["branching"]["hist"]) == d["n_entries"],
           f"k={k}: branching hist != n_entries")

        lo = sum(c * 2 ** b for b, c in d["value_hist_log2"])
        hi = sum(c * 2 ** (b + 1) for b, c in d["value_hist_log2"])
        ck(lo <= mt <= hi, f"k={k}: mass_total outside its own value_hist bounds")

        epm = d["entries_per_mask"]
        ck(epm["min"] * nonempty <= d["n_entries"] <= epm["max"] * nonempty,
           f"k={k}: n_entries outside entries_per_mask min/max envelope")
        ck(abs(epm["mean"] * nonempty - d["n_entries"]) / d["n_entries"] < 1e-6,
           f"k={k}: entries_per_mask mean inconsistent with n_entries/nonempty")

        if man:
            ck(d["n"] == int(man["n"]), f"k={k}: n != manifest n")
            ck(d["pl_hash"] == man["pl_hash"], f"k={k}: pl_hash != manifest pl_hash")
            ck(",".join(str(x) for x in d["b0"]) == man["b0"], f"k={k}: b0 != manifest b0")

        if k - 1 in layers:
            ck(d.get("input_layer_k") == k - 1, f"k={k}: input_layer_k != k-1")
            ck(d.get("input_sha256_decompressed") == layers[k - 1]["own_sha256_decompressed"],
               f"k={k}: BROKEN HASH CHAIN — input sha != k-1's own sha")

        print(f"  k={k:2d}  masks={d['n_masks']:>11,}  entries={d['n_entries']:>15,}  "
              f"mass={mt:>27,}  {'OK' if s_last == mt and s_rid == mt else 'FAIL'}")

    print("=" * 74)
    print(f"{n[0] - len(fails)}/{n[0]} checks passed")
    if fails:
        print("FAILURES:")
        for f in fails:
            print("  " + f)
        print("RESULT: *** SIDECAR IDENTITY CHECK FAILED *** — do not explain away.")
        return 1
    print("RESULT: all sidecar identities hold, and the layer hash chain is unbroken")
    print("        across the retained set. This is NOT a recomputation of the masses —")
    print("        it checks self-consistency and lineage, not the DP's arithmetic.")
    print("=" * 74)
    return 0


# ---------------------------------------------------------------------------
# NULL G-DISTRIBUTION  (--check-null-g)
#
# G is the C3 slot-gap statistic: C3 = 16 + 8*G (Lean `c3_slot_decomposition`), so
# C3 <= 776 <=> G <= 95, and King Wen sits exactly at G = 95.
#
# This computes the EXACT distribution of G under the C1-and-C4 null -- 12 cross-couples
# and 7 self-pairs placed into slots 1..31, uniformly. It is a reference distribution:
# it tells you what G looks like with no C2 and no C5 conditioning at all, which is the
# baseline any "KW's G is unusual" claim has to beat.
#
# INDEPENDENCE (the reason this lives in verify.py and not solve.c): solve.c's G channel
# accumulates g -= s when a couple opens at slot s and g += s when it closes. This does
# not touch slot indices in the accumulator AT ALL. It uses
#
#     G = sum_i (close_i - open_i) = sum_{s=1..30} o_s
#
# where o_s is the number of couples still open after slot s -- because a couple opened
# at a and closed at b is open across exactly the b-a boundaries s in [a, b-1]. Same
# model, different arithmetic. Agreement is therefore evidence, not tautology.
#
# Two checks need no DP at all and are applied as gates below:
#   * total must be 31! exactly
#   * E[G] must be 128 exactly, by linearity: each couple's slot-pair is marginally a
#     uniform 2-subset of {1..31}, and E|i-j| = (n+1)/3 for a uniform 2-subset of
#     {1..n}, so E[G] = 12*(32/3) = 128.
#
# --unpinned VARIANT (C3|C1, start unpinned): the SAME DP with the C4 slot-0 pin
# removed -- 12 cross-couples and all 8 self-pairs placed into slots 1..32,
# uniformly. This is the exact analogue of solve.c --null-pair-constrained's
# sampled C3|C1 figure (6.42% at 10^9 trials): that sampler Fisher-Yates-permutes
# all 32 pairs with random orientations, and orientation bits cancel in G (Lean
# `c3_slot_decomposition`: C3 = 16 + 8*G over all C1-valid orderings), so
# P(C3 <= 776 | C1) = P(G <= 95) over uniform orderings of the 32 pair-slots.
# The same two DP-free gates apply with one more slot: total must be 32! exactly,
# and E[G] = 12*(33/3) = 132 exactly.
# ---------------------------------------------------------------------------

_NULL_G_EXPECT = {
    'total_is_31_factorial': True,
    'support': (12, 228),
    'mean': 128,
    'p_le_95_num': 641983711307479,
    'p_le_95_den': 7919632354008375,
}

# Exact C3|C1 (start unpinned): first computed 2026-07-25 by this DP; cross-checked
# against brute-force enumeration at reduced scopes (NC,NS) in {(1,1),(2,1),(2,2),
# (3,1),(2,3)} and against the 10^9-sample MC (solve.c --null-pair-constrained,
# 6.42%; exact = 6.421137%, inside the MC's ~0.0008pp 1-sigma band).
_NULL_G_UNPINNED_EXPECT = {
    'total_is_32_factorial': True,
    'support': (12, 240),
    'mean': 132,
    'p_le_95_num': 1977618313669549,
    'p_le_95_den': 30798570265588125,
}


def check_null_g(verbose=True, unpinned=False):
    import math
    from fractions import Fraction
    from collections import defaultdict

    if unpinned:
        NC, NS, NSLOT = 12, 8, 32   # no C4 pin: all 8 self-pairs free, 32 slots
        expect = _NULL_G_UNPINNED_EXPECT
    else:
        NC, NS, NSLOT = 12, 7, 31   # C4 pin: pair 0 fixed at slot 0; 31 free slots
        expect = _NULL_G_EXPECT
    cur = {(0, 0, 0): 1}
    for s in range(1, NSLOT + 1):
        nxt = defaultdict(int)
        for (o, c, g), w in cur.items():
            rem_self = NS - ((s - 1) - o - 2 * c)
            if rem_self > 0:
                nxt[(o, c, g + o)] += w * rem_self
            un = NC - o - c
            if un > 0:
                nxt[(o + 1, c, g + o + 1)] += w * 2 * un
            if o > 0:
                nxt[(o - 1, c + 1, g + o - 1)] += w * o
        cur = dict(nxt)

    hist = defaultdict(int)
    for (o, c, g), w in cur.items():
        if o != 0 or c != NC:
            print(f"FAIL: terminal state (o={o}, c={c}) has unclosed couples")
            return 1
        hist[g] += w

    total = sum(hist.values())
    gs = sorted(hist)
    mean = Fraction(sum(g * w for g, w in hist.items()), total)
    ex2 = Fraction(sum(g * g * w for g, w in hist.items()), total)
    var = ex2 - mean * mean
    le95 = sum(w for g, w in hist.items() if g <= 95)
    frac = Fraction(le95, total)

    ok = [True]
    def gate(cond, label, got, want):
        status = "PASS" if cond else "*** FAIL ***"
        if not cond:
            ok[0] = False
        if verbose:
            print(f"  [{status}] {label}")
            if not cond:
                print(f"            got  {got}\n            want {want}")

    if verbose:
        print("=" * 74)
        if unpinned:
            print("verify.py --check-null-g --unpinned : exact G-distribution, bare C1 null")
        else:
            print("verify.py --check-null-g : exact G-distribution under the C1&C4 null")
        print("  method: G = sum_s (couples open after slot s)  -- deliberately NOT")
        print("          solve.c's -/+ slot-index accumulator, so agreement is evidence")
        print("=" * 74)

    gate(total == math.factorial(NSLOT), f"total == {NSLOT}!", total, math.factorial(NSLOT))
    gate((gs[0], gs[-1]) == expect['support'],
         f"support == [{expect['support'][0]}, {expect['support'][1]}]",
         (gs[0], gs[-1]), expect['support'])
    gate(mean == expect['mean'],
         f"E[G] == {expect['mean']} exactly (DP-free: 12*({NSLOT + 1}/3))",
         mean, expect['mean'])
    gate(frac == Fraction(expect['p_le_95_num'], expect['p_le_95_den']),
         f"P(G <= 95) == {expect['p_le_95_num']}/{expect['p_le_95_den']}", frac,
         Fraction(expect['p_le_95_num'], expect['p_le_95_den']))

    if verbose:
        print("-" * 74)
        print(f"  support        [{gs[0]}, {gs[-1]}]   bins {len(gs)}")
        print(f"  E[G]           {mean}")
        print(f"  sd             {math.sqrt(float(var)):.6f}")
        print(f"  P(G <= 95)     {frac}  = {100*float(frac):.6f}%")
        print(f"  P(G == 95)     {100*float(Fraction(hist.get(95,0), total)):.6f}%")
        print(f"  P(G == 95 | G <= 95) = {100*float(Fraction(hist.get(95,0), le95)):.4f}%")
        print("=" * 74)
        if not ok[0]:
            print("RESULT: *** NULL G-DISTRIBUTION CHECK FAILED *** — do not explain away.")
        elif unpinned:
            print("RESULT: unpinned null G-distribution reproduced exactly.")
            print("        SCOPE: this is the bare C1 null with the start UNPINNED — no C4,")
            print("        no C2, no C5, no budget truncation: uniform orderings of all 32")
            print("        pair-slots (orientations cancel in G). P(G <= 95) here is the")
            print("        EXACT value of the C3|C1 rate that solve.c --null-pair-constrained")
            print("        samples (6.42% at 10^9 trials). Same non-comparability caveats as")
            print("        the pinned null apply to C2/C5-conditioned populations.")
        else:
            print("RESULT: null G-distribution reproduced exactly.")
            print("        SCOPE: this is the C1&C4 null ONLY — no C2, no C5, no budget")
            print("        truncation. It is NOT comparable like-for-like to ceiling-tie")
            print("        shares measured over C2/C5-conditioned enumerated populations,")
            print("        and it does not on its own refute or confirm any such figure.")
        print("=" * 74)
    return 0 if ok[0] else 1


# Exact C2-acceptance target: |C1&C2&C4| / |C1&C4| = |C1&C2&C4| / (31! * 2^31).
# |C1&C2&C4| is an EXACT integer (S4-orbit DP, 2026-07-04; DESCRIPTION_LENGTH.md).
_C1C2C4_EXACT = 757058601340255440651419713405330315358208


def check_c2_shift(n_samples=200_000, seed=20260724, verbose=True):
    """DECISION-SUPPORT (Monte-Carlo — NOT a canonical count): measure how conditioning
    on C2 shifts the G-distribution at the C1&C2&C4 scope, i.e. P(G<=95 | C1&C2&C4), by
    importance-weighting the exact C1&C4 null with w(sigma) = the exact number of C2-valid
    orientation assignments of pair-order sigma (a 2x2 transfer product over exit faces).
    Ratio estimator R = E[w 1_{G<=95}] / E[w] with a delta-method CI.

    HARD-GATED on the exact acceptance identity E[w]/2^31 == |C1&C2&C4|/|C1&C4| (within
    Monte-Carlo error): a broken sampler cannot pass it. Reads no files; uses only PAIRS +
    hamming, nothing from solve.c (independence).

    SCOPE / GRADE: this is a MEASURED estimate with a CI, at MC grade. It is decision
    support, NOT a canonical published number. The load-bearing EXACT legs of the C3
    rule-out are --check-null-g (the C1&C4 null) and the exact rung histograms; this
    instrument only pins the small C2 shift between the two, with an error bar."""
    import math, random

    fs = [frozenset(p) for p in PAIRS]
    idx = {f: i for i, f in enumerate(fs)}
    ctab = []  # per pair: complement-couple partner index, or None for a self-complement pair
    for i, (a, b) in enumerate(PAIRS):
        comp = frozenset((a ^ 63, b ^ 63))
        ctab.append(None if comp == fs[i] else idx[comp])
    if sum(1 for c in ctab if c is None) != 8:
        print("FAIL: expected exactly 8 self-complement pairs")
        return 1

    free = list(range(1, 32))          # pinned pair 0 = {63,0} fixed (C4); free pairs 1..31
    rng = random.Random(seed)
    N = int(n_samples)

    sum_w = 0        # Sum w
    sum_wA = 0       # Sum w * 1_{G<=95}
    sum_w_tie = 0    # Sum w * 1_{G==95}
    sum_w2 = 0.0     # Sum w^2      (for w-fluctuation + acceptance SE)
    sum_w2A = 0.0    # Sum w^2 * 1_{G<=95}   (for the ratio delta-method SE)
    gsum_w = 0       # Sum w * G    (for E[G | C2])
    n_wzero = 0
    for _ in range(N):
        rng.shuffle(free)
        # exact G = sum over cross-couples of |slot difference| (self-couples excluded: they are the +16)
        slot = {}
        g = 0
        for s, pi in enumerate(free, start=1):
            pj = ctab[pi]
            if pj is not None:
                if pj in slot:
                    g += s - slot[pj]
                else:
                    slot[pi] = s
        # exact w = number of C2-valid orientation assignments (transfer product over exit faces)
        prev = {0: 1}                  # start exit face = 0 (Kun exit, C4)
        for pi in free:
            a, b = PAIRS[pi]
            nxt = {}
            for exitf, c in prev.items():
                if hamming(exitf, a) != 5:   # enter a, exit b (no 5-line boundary transition)
                    nxt[b] = nxt.get(b, 0) + c
                if hamming(exitf, b) != 5:   # enter b, exit a
                    nxt[a] = nxt.get(a, 0) + c
            prev = nxt
            if not prev:
                break
        w = sum(prev.values())
        wf = float(w)
        if w == 0:
            n_wzero += 1
        sum_w += w
        sum_w2 += wf * wf
        gsum_w += g * w
        if g <= 95:
            sum_wA += w
            sum_w2A += wf * wf
            if g == 95:
                sum_w_tie += w

    if sum_w == 0:
        print("FAIL: all sampled pair-orders had w==0 (impossible unless the sampler is broken)")
        return 2

    Ew = sum_w / N
    E_w2 = sum_w2 / N
    E_w2A = sum_w2A / N
    R = sum_wA / sum_w                                   # P(G<=95 | C1&C2&C4)
    tie = sum_w_tie / sum_w
    relsd = math.sqrt(max(0.0, E_w2 - Ew * Ew)) / Ew     # sd(w)/E[w]
    # delta-method SE of the ratio R: Var(R) ~ E[w^2 (1_A - R)^2] / (N * E[w]^2)
    resid2 = (1.0 - 2.0 * R) * E_w2A + R * R * E_w2
    se_R = math.sqrt(max(0.0, resid2) / (N * Ew * Ew))
    # acceptance estimate + its SE
    acc_hat = Ew / (2 ** 31)
    exact_acc = _C1C2C4_EXACT / (math.factorial(31) * (2 ** 31))
    se_acc = (math.sqrt(max(0.0, E_w2 - Ew * Ew)) / (2 ** 31)) / math.sqrt(N)

    # HARD GATE: the estimated acceptance must agree with the exact identity within 5 sigma.
    gate_ok = abs(acc_hat - exact_acc) <= 5.0 * se_acc

    if verbose:
        print("=" * 74)
        print("verify.py --check-c2-shift : P(G<=95 | C1&C2&C4) by importance-weighted MC")
        print("  DECISION-SUPPORT (Monte-Carlo, CI-labeled) -- NOT a canonical count.")
        print(f"  N = {N:,}   seed = {seed}")
        print("=" * 74)
        status = "PASS" if gate_ok else "*** FAIL ***"
        print(f"  [{status}] acceptance identity  E[w]/2^31 == |C1&C2&C4|/|C1&C4|")
        print(f"            estimate {acc_hat:.6f}  +/- {se_acc:.6f} (1 sigma)")
        print(f"            exact    {exact_acc:.6f}  (= 4.2872%; |C1&C2&C4| S4-orbit DP)")
        print(f"            |diff|   {abs(acc_hat-exact_acc):.6f}  ({abs(acc_hat-exact_acc)/se_acc:.2f} sigma; gate = 5 sigma)")
        print("-" * 74)
        print(f"  P(G<=95 | C1&C2&C4)  = {100*R:.4f}%   95% CI [{100*(R-1.96*se_R):.3f}%, {100*(R+1.96*se_R):.3f}%]")
        print(f"  P(G==95 | C1&C2&C4)  = {100*tie:.4f}%")
        print(f"  E[G   | C1&C2&C4]    = {gsum_w/sum_w:.4f}")
        print(f"  w==0 fraction        = {n_wzero/N:.6f}   sd(w)/E[w] = {relsd:.3f}")
        print("-" * 74)
        print(f"  compare EXACT C1&C4 null P(G<=95)   = 8.106231%   (--check-null-g)")
        print(f"  compare prior MC estimates          ~ 8.9% (c2quant 8.98%; 2026-07-24 review 8.89%)")
        print("  READING: the C2 shift is small and *upward* (tail slightly inflated),")
        print("           so KW's G=95 stays null-generic at the C1&C2&C4 scope. This")
        print("           MEASURES that shift with a CI; it does not (and cannot cheaply)")
        print("           make it exact -- the exact legs are --check-null-g + the rungs.")
        print("=" * 74)
        if gate_ok:
            print("RESULT: acceptance identity reproduced; C2-shift measured (MC grade).")
        else:
            print("RESULT: *** ACCEPTANCE GATE FAILED *** — sampler is broken; estimate not trustworthy.")
        print("=" * 74)

    return 0 if gate_ok else 2


def main():
    parser = argparse.ArgumentParser(description="Independent two-language constraint verifier for solutions.bin")
    parser.add_argument('path', nargs='?', default='solutions.bin', help='solutions.bin path')
    parser.add_argument('--expect-kw', action='store_true',
                        help='require the King Wen sequence to be present in the '
                             'records (default: presence is reported but not '
                             'required, since an individual shard need not '
                             'contain it). Use on a complete canonical.')
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
    parser.add_argument('--recount-rung', type=int, metavar='N', default=None,
                        help='Independently recompute a worker-sized TR-11 §4b C5 rung (N in {18, 19}) '
                             'by the plain budgeted packed-state DP, with B0 re-derived by §5 Step 1 '
                             'and the packed DP self-gated against the plain DP at n=16 first. n=19 '
                             'gates against the published integer; n=18 likewise since 2026-08-10 '
                             '(TR-11 v1.18 publishes its integer and this recount reproduced it '
                             'exactly — 157 s, 953 MB). Worker-sized: n=19 needs ~8 GB '
                             'and tens of minutes in CPython. Does NOT read solutions.bin.')
    parser.add_argument('--recount-fiber', action='store_true',
                        help='Independently recount TR-1 §7\'s orientation fiber — the frozen '
                             'dispositive null for the eleven-functional battery: 1,720,320 '
                             '(C4-oriented) / 2,703,360 (pair-only C4) / 983,040 (opening 0,63), '
                             'its 3·5·7·2¹⁴ factorization, and which orientation bits are forced. '
                             'Transfer DP over KW\'s own pair order with B0 recomputed from KW. '
                             'Instant. Does NOT read solutions.bin.')
    parser.add_argument('--fiber-sweep', action='store_true',
                        help='Measure the ORIENTATION-FIBER FACTOR: the exact conversion '
                             'between the two counting levels the suite publishes side by '
                             'side — deduped RECORDS (pair orderings) vs orientation-explicit '
                             'SEQUENCES. Gates on King Wen\'s own fiber (1,720,320 / 983,040 / '
                             '2,703,360, TR-1 §7) and on agreement with --recount-fiber\'s '
                             'independent DP, then reports the exact fiber-size distribution '
                             'over the records of the solutions.bin at `path` (gzip ok) if one '
                             'is present. ~0.2 ms per record; seconds on the repo sample.')
    parser.add_argument('--recount-subtree', action='store_true',
                        help='Independently recompute the exact deterministic subtree anchors of '
                             'TR-5 §3 / SEARCH_SPACE_SIZE.md (KW-following prefixes at 5/7/9 free '
                             'positions: tree_nodes 443 / 62,256 / 9,422,793 and canonical leaves '
                             '4 / 2,232 / 16,504) plus the sigma-related-prefix tree-isomorphism '
                             'check, plus three away-from-KW anchors whose expectations come from '
                             'solve.c --estimate-knuth exact mode (leaf C3 528..1104 — the C3 '
                             'predicate exercised in both directions away from the 776 threshold; '
                             'see _CROSS_PREFIXES). ~1-2 min. Does NOT read solutions.bin.')
    parser.add_argument('--recount-finite', action='store_true',
                        help='Independently recompute the finite record-mode + wrap/parity tallies: '
                             'TR-5\'s 48-of-720 validity classification / 24 records / 23 twins '
                             '(validity checked from the constraint definitions, not group '
                             'membership), TR-6\'s 15 alternations / 30 switches / wrap-parity / '
                             'circular 16-of-64, and the 82,818,450 arrangement count. Seconds. '
                             'Does NOT read solutions.bin.')
    parser.add_argument('--recount-gender-null', action='store_true',
                        help='Independently recompute TR-8 §Commands\' exact pair-null gender figure '
                             'P(rc4_violations <= 2) = 47/445740 (~1.054426e-04) — the functional '
                             'rebuilt from the published Schulz-1990 definition and the 32!·2^32 '
                             'pair-only null solved exactly two ways (closed form + slot DP, '
                             'cross-asserted; Fractions, no sampling), gated on KW\'s published '
                             'anchors (2 violations at class positions 25/26). Instant. Does NOT '
                             'read solutions.bin.')
    parser.add_argument('--check-certificate', metavar='DIR', default=None,
                        help='Artifact check for a completed f1c5 run directory (TR-11 §10iii): '
                             'validates the per-layer certificate rows, manifest, and preserved '
                             'digests against structural identities and independently-derived '
                             'quantities. Recomputes NOTHING — see check_certificate() for scope.')
    parser.add_argument('--check-layer-sidecars', metavar='DIR', default=None,
                        help='Check the f1c5 per-layer sidecar identities in DIR (two independent '
                             'marginal decompositions each summing to mass_total, histogram totals, '
                             'manifest agreement, and the layer-to-layer sha256 lineage chain). '
                             'Reads ONLY the small JSON sidecars — no layer-file I/O, so it is free '
                             'and works long after the campaign VM is gone. Recomputes no masses.')
    parser.add_argument('--check-null-g', action='store_true',
                        help='Compute the exact G-distribution under the C1&C4 null (12 couples + 7 '
                             'self-pairs into 31 slots) and gate it against total == 31!, support '
                             '[12,228], E[G] == 128, and P(G<=95) == 641983711307479/7919632354008375. '
                             'Uses a different accumulator than solve.c (open-couple counts, not '
                             '+/- slot indices), so agreement is evidence. Reads no files.')
    parser.add_argument('--unpinned', action='store_true',
                        help='With --check-null-g: drop the C4 slot-0 pin — 12 couples + all 8 '
                             'self-pairs into 32 slots (the bare C1 null). Computes the EXACT '
                             'C3|C1 rate P(G<=95) = 1977618313669549/30798570265588125 = 6.421137%%, '
                             'the exact analogue of solve.c --null-pair-constrained\'s sampled '
                             '6.42%%. Gates: total == 32!, support [12,240], E[G] == 132.')
    parser.add_argument('--check-c2-shift', type=int, nargs='?', const=200_000, default=None,
                        metavar='N',
                        help='DECISION-SUPPORT (Monte-Carlo, NOT canonical): estimate '
                             'P(G<=95 | C1&C2&C4) via importance-weighted MC (default N=200000), '
                             'hard-gated on the exact acceptance identity E[w]/2^31 == '
                             '|C1&C2&C4|/|C1&C4|. Reports the small upward C2 shift off the exact '
                             'C1&C4 null with a delta-method CI. Reads no files; imports nothing '
                             'from solve.c. This MEASURES the shift; it is not an exact count.')
    args = parser.parse_args()

    if args.check_null_g:
        sys.exit(check_null_g(unpinned=args.unpinned))
    if args.unpinned:
        parser.error("--unpinned only makes sense with --check-null-g")

    if args.check_c2_shift is not None:
        sys.exit(check_c2_shift(args.check_c2_shift))

    if args.check_layer_sidecars is not None:
        sys.exit(check_layer_sidecars(args.check_layer_sidecars))

    if args.check_certificate is not None:
        sys.exit(check_certificate(args.check_certificate))

    if args.recount:
        sys.exit(recount())

    if args.recount_rung is not None:
        sys.exit(recount_rung(args.recount_rung))

    if args.recount_subtree:
        sys.exit(recount_subtree())

    if args.recount_finite:
        sys.exit(recount_finite())

    if args.recount_fiber:
        sys.exit(recount_fiber())

    if args.fiber_sweep:
        sys.exit(fiber_sweep(args.path))

    if args.recount_gender_null:
        sys.exit(recount_gender_null())


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
    # The 16 reserved header bytes MUST be zero (SOLUTIONS_FORMAT.md). Counted
    # as a format error rather than a hard exit: the file is still readable and
    # every record-level verdict below stays meaningful, so a nonzero reserved
    # field belongs alongside those results, not instead of them.
    header_reserved_bad = 1 if head[16:32] != b"\0" * 16 else 0

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
    fail_fmt = sum(r['fail_fmt'] for r in results)
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
    print(f"C4 failures:    {fail_c4}  (oriented: s0 = 63 AND s1 = 0)")
    print(f"C5 failures:    {fail_c5}")
    print(f"Decode errors:  {fail_decode}")
    print(f"Sort errors:    {fail_sort}")
    print(f"Duplicates:     {fail_dup}")
    print(f"Format errors:  {fail_fmt}  (records with reserved bit 0 set)"
          + ("  + header reserved bytes NONZERO" if header_reserved_bad else ""))
    print(f"King Wen:       {'YES' if kw_found else 'No'}"
          + ("  [--expect-kw: REQUIRED]" if args.expect_kw else ""))

    # KW presence is informational by default — a shard legitimately need not
    # contain King Wen. --expect-kw promotes it to a hard requirement for runs
    # over a complete canonical, where its absence would be a real defect that
    # was previously visible only to an operator reading the line above.
    fail_kw = 1 if (args.expect_kw and not kw_found) else 0

    total_fail = (fail_c1 + fail_c2 + fail_c3 + fail_c4 + fail_c5
                  + fail_decode + fail_sort + fail_dup + fail_fmt
                  + header_reserved_bad + fail_kw)
    if total_fail == 0:
        print(f"\nVERIFY PASS: all {n:,} records satisfy C1-C5, sorted, no duplicates")
        sys.exit(0)
    else:
        print(f"\nVERIFY FAIL: {total_fail} issues")
        sys.exit(1)

if __name__ == "__main__":
    main()
