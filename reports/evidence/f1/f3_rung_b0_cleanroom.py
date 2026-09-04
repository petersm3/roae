#!/usr/bin/env python3
"""F-3 clean-room re-derivation of the reduced-rung B0 target vectors + counts.

PURPOSE (adversarial-review finding F-3): TR-11 §5 currently tells a third party to retain
final states whose boundary multiset is a "sub-multiset compatible with C5 (KW's {1:2,2:8,3:13,
4:7,6:1})". That is WRONG for the reduced rungs: the engine derives a per-rung budget B0 from a
deterministic first-completion DFS over the rung's own pair subset, and the final multiset must
EQUAL that B0. Following the published recipe reproduces neither the engine nor the published
counts.

This script is written ONLY from what is (or will be) published in TR-11 — the 32-pair table, the
rung pair-index sets, and the DFS convention — deliberately NOT by importing project code. If it
reproduces the engine's printed B0 for all 9 rungs and the published exact counts, the corrected
recipe is independently sufficient. That is the whole point of F-3.

Developed with AI assistance (Claude, Anthropic). Attribution per roae conventions.
"""
import sys
from itertools import product

# King Wen sequence, hexagrams as 6-bit ints, bit 0 = bottom line (OEIS A102241 convention).
KW = [63,0,17,34,23,58,2,16,55,59,7,56,61,47,4,8,25,38,3,48,41,37,32,1,
      57,39,33,30,18,45,28,14,60,15,40,5,53,43,20,10,35,49,31,62,24,6,26,22,
      29,46,9,36,52,11,13,44,54,27,50,19,51,12,21,42]
PAIR = [(KW[2*p], KW[2*p+1]) for p in range(32)]   # pair p = (a, b)

DVAL = [1, 2, 3, 4, 6]                              # distance classes
CLS = {1: 0, 2: 1, 3: 2, 4: 3, 6: 4}                # d -> class index; d=5 is C2-forbidden

# The pair orbits (TR-11 §3 table). Each row is sorted ascending internally.
ORBITS = {
    "3.0": [3, 7, 11],
    "3.1": [4, 6, 21],
    "3.2": [13, 14, 30],
    "4.0": [5, 8, 26, 31],
    "6.0": [1, 9, 17, 19, 22, 25],
    "6.1": [2, 12, 16, 18, 24, 28],
    "6.2": [10, 15, 20, 23, 27, 29],
}
# The 9 C5 ladder rungs as orbit SPECS (TR-11 §4b), all exit @0 = Kun.
#
# ORDER IS LOAD-BEARING (F-3, 2026-07-20): the subset's pair list is the concatenation of the
# spec's orbit rows IN SPEC ORDER — e.g. 3.0,3.1,3.2 -> [3,7,11, 4,6,21, 13,14,30], NOT the
# ascending set [3,4,6,7,11,13,14,21,30]. Because the B0-defining DFS tries pairs in ascending
# SUBSET-INDEX order, a different pair ordering yields a different first-completion witness and
# AS-OF NOTE (added 2026-08-14 on publication): the "currently" below describes TR-11
# BEFORE its v1.8 correction, which addressed the sorted-order issue. TR-11 is authoritative.
# hence a different B0. TR-11 §4b currently publishes the SORTED index sets, which are therefore
# insufficient to reproduce B0 — this is exactly the F-3 defect (verified empirically: sorted
# order gives n=9 B0=(2,2,2,3,0), engine/spec order gives (2,5,0,2,0)).
SPECS = {
    9:  ["3.0", "3.1", "3.2"],
    13: ["3.0", "4.0", "6.2"],
    16: ["4.0", "6.0", "6.1"],
    18: ["6.0", "6.1", "6.2"],
    19: ["3.0", "4.0", "6.0", "6.1"],
    24: ["3.0", "3.1", "6.0", "6.1", "6.2"],
    25: ["3.0", "4.0", "6.0", "6.1", "6.2"],
    27: ["3.0", "3.1", "3.2", "6.0", "6.1", "6.2"],
    28: ["3.0", "3.1", "4.0", "6.0", "6.1", "6.2"],
}
RUNGS = {n: [p for row in spec for p in ORBITS[row]] for n, spec in SPECS.items()}
# Published exact counts (TR-11 §4b). None = "(in-RAM reference)", no published target.
PUBLISHED = {
    9:  None,
    13: 2063395607040,
    16: 267765117419520,
    18: None,
    19: 63244766587981824,
    24: 7477248378538061907099648,
    25: 83855263774549546015506432,
    27: 61666352085618532666071318528,
    28: 2155118806480613893163229118464,
}
START_EXIT = 0   # Kun; all C5 rungs use @0


def derive_b0(pairs, start_exit):
    """Deterministic first-completion DFS defining the rung's boundary budget B0.

    Convention (must be published for this to be reproducible):
      - pairs are tried in ASCENDING SUBSET-INDEX order (position in the rung's sorted list),
      - orientations in order o = 0, 1, where o=0 ENTERS b and EXITS a, o=1 enters a and exits b,
      - a transition is skipped iff its boundary Hamming distance == 5 (C2),
      - B0 = the class multiset of the FIRST complete C2-valid walk found.
    Returns a list of 5 counts over classes (1,2,3,4,6).
    """
    n = len(pairs)
    full = (1 << n) - 1
    cls = [0] * n

    sys.setrecursionlimit(10000)

    def dfs(mask, last, depth):
        if mask == full:
            return True
        for i in range(n):
            if (mask >> i) & 1:
                continue
            a, b = pairs[i]
            for o in (0, 1):
                f, s = (b, a) if o == 0 else (a, b)
                d = bin(last ^ f).count("1")
                if d == 5:
                    continue
                cls[depth] = CLS[d]
                if dfs(mask | (1 << i), s, depth + 1):
                    return True
        return False

    if not dfs(0, start_exit, 0):
        raise SystemExit("no valid completion exists for this subset")
    b0 = [0] * 5
    for i in range(n):
        b0[cls[i]] += 1
    return b0


def count_rung(pairs, start_exit, b0):
    """Layered big-integer DP: |C1 & C2 & C4 & C5| restricted to the rung.

    State = (mask of placed pairs, last = exit hexagram, p = boundary-class usage vector).
    Transition places an unplaced pair in one orientation; allowed iff boundary distance != 5
    (C2) AND the class is still under budget (p_d < B0_d). The answer is the mass on full-mask
    states, which by the sum invariant all carry p == B0 exactly.
    """
    n = len(pairs)
    full = (1 << n) - 1
    rad = []
    R = 1
    for d in range(5):
        rad.append(R)
        R *= b0[d] + 1
    rid_full = R - 1

    def digits(rid):
        return [(rid // rad[d]) % (b0[d] + 1) for d in range(5)]

    layer = {(0, start_exit, 0): 1}
    for _ in range(n):
        nxt = {}
        for (mask, last, rid), v in layer.items():
            dg = digits(rid)
            for i in range(n):
                if (mask >> i) & 1:
                    continue
                a, b = pairs[i]
                for f, s in ((b, a), (a, b)):
                    d = bin(last ^ f).count("1")
                    if d == 5:
                        continue
                    c = CLS[d]
                    if dg[c] >= b0[c]:          # budget-kill (capping at B0)
                        continue
                    k = (mask | (1 << i), s, rid + rad[c])
                    nxt[k] = nxt.get(k, 0) + v
        layer = nxt
    return sum(v for (mask, last, rid), v in layer.items()
               if mask == full and rid == rid_full)


def main():
    do_counts = [int(x) for x in sys.argv[1:]] if len(sys.argv) > 1 else []
    print("rung  B0=(d1,d2,d3,d4,d6)  sum")
    b0s = {}
    for n in sorted(RUNGS):
        b0 = derive_b0([PAIR[p] for p in RUNGS[n]], START_EXIT)
        b0s[n] = b0
        assert sum(b0) == n, f"B0 must sum to n={n}, got {sum(b0)}"
        print(f"{n:>4}  ({b0[0]},{b0[1]},{b0[2]},{b0[3]},{b0[4]})  sum={sum(b0)}")

    for n in do_counts:
        pairs = [PAIR[p] for p in RUNGS[n]]
        got = count_rung(pairs, START_EXIT, b0s[n])
        exp = PUBLISHED.get(n)
        verdict = "PASS" if (exp is not None and got == exp) else \
                  ("no published target" if exp is None else "MISMATCH")
        print(f"count n={n}: {got}   expected={exp}   {verdict}")
        if exp is not None and got != exp:
            raise SystemExit(2)


if __name__ == "__main__":
    main()
