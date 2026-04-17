#!/usr/bin/env python3
"""Independent constraint verifier for solutions.bin.

Reads every record, reconstructs the 64-hexagram sequence, and checks
C1-C5. Also checks sorted order and duplicates. Different language,
different implementation, no shared code with solve.c.

Usage: python3 verify.py [solutions.bin]
"""
import sys, struct

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

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "solutions.bin"
    with open(path, "rb") as f:
        data = f.read()

    if len(data) % 32 != 0:
        print(f"ERROR: file size {len(data)} not a multiple of 32")
        sys.exit(2)

    n = len(data) // 32
    print(f"Verifying {n:,} records from {path} ({len(data):,} bytes)")

    fail_c1 = fail_c2 = fail_c4 = fail_c5 = 0
    fail_decode = fail_sort = fail_dup = 0
    kw_found = False
    prev_canonical = None
    prev_rec = None

    for r in range(n):
        rec = data[r*32:(r+1)*32]
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

        # Sorted order (canonical primary, full bytes secondary)
        can = canonical(rec)
        if prev_canonical is not None:
            if can < prev_canonical:
                fail_sort += 1
            elif can == prev_canonical and rec < prev_rec:
                fail_sort += 1
        # Duplicates: same canonical form (orient masked)
        if prev_canonical is not None and can == prev_canonical:
            fail_dup += 1
        prev_canonical = can
        prev_rec = rec

        # King Wen check
        if seq == KW:
            kw_found = True

        if r > 0 and r % 10_000_000 == 0:
            print(f"  ... {r:,} / {n:,}")

    print(f"\n--- Results ---")
    print(f"Records:        {n:,}")
    print(f"C1 failures:    {fail_c1}")
    print(f"C2 failures:    {fail_c2}")
    print(f"C4 failures:    {fail_c4}")
    print(f"C5 failures:    {fail_c5}")
    print(f"Decode errors:  {fail_decode}")
    print(f"Sort errors:    {fail_sort}")
    print(f"Duplicates:     {fail_dup}")
    print(f"King Wen:       {'YES' if kw_found else 'No'}")

    total_fail = fail_c1 + fail_c2 + fail_c4 + fail_c5 + fail_decode + fail_sort + fail_dup
    if total_fail == 0:
        print(f"\nVERIFY PASS: all {n:,} records satisfy C1-C5, sorted, no duplicates")
        sys.exit(0)
    else:
        print(f"\nVERIFY FAIL: {total_fail} issues")
        sys.exit(1)

if __name__ == "__main__":
    main()
