#!/usr/bin/env python3
"""Definition check for PREREG_QOY1_Q992 — hexagram SET facts + toy brute force only.
NEVER evaluates either statistic on verify.KW's order (the KW array is imported for
its bit conventions and never indexed by position here)."""
import sys, random, itertools, math
from fractions import Fraction
sys.path.insert(0, "/home/claude/github/roae/roae")
import verify as V

def swap(h):  return ((h >> 3) & 0b111) | ((h & 0b111) << 3)        # verify.py:905 _swap
def rev(h):   return V._zong(h)
def comp(h):  return V._cuo(h)
def partner(h):
    r = rev(h); return r if r != h else comp(h)
H16 = frozenset(h for h in range(64) if rev(h) == h or rev(h) == comp(h))
COSETS = sorted({frozenset(h ^ c for c in H16) for h in range(64)}, key=min)
def coset_id(h): return next(i for i, C in enumerate(COSETS) if h in C)
PAIRS = V._canonical_pairs()

ok = True
def chk(label, cond, detail=""):
    global ok; ok &= bool(cond); print(("PASS " if cond else "FAIL ") + label + ("  " + detail if detail else ""))

# A. swap commutes with partner; C1 pairs map to C1 pairs under swap
chk("A1 swap(partner h) == partner(swap h) for all 64", all(swap(partner(h)) == partner(swap(h)) for h in range(64)))
chk("A2 swap is an involution, fixes exactly 8 (upper==lower)", sum(swap(h) == h for h in range(64)) == 8 and all(swap(swap(h)) == h for h in range(64)))
# B. classify the 32 C1 pairs
within = [(a, b) for a, b in PAIRS if swap(a) == b]
fixed  = [(a, b) for a, b in PAIRS if swap(a) == a]
other  = [(a, b) for a, b in PAIRS if swap(a) != b and swap(a) != a]
chk("B1 6 C1 pairs are swap pairs (W is forced = 6 under C1)", len(within) == 6, str(within))
chk("B2 4 C1 pairs are swap-fixed (both pure)", len(fixed) == 4 and all(swap(b) == b for a, b in fixed), str(fixed))
chk("B3 remaining 22 pairs form 11 couples P<->Q with BOTH hexagrams mapping into Q", len(other) == 22 and
    all(frozenset((swap(a), swap(b))) in {frozenset(p) for p in other} for a, b in other))
chk("B4 {63,0} (C4 start pair) is swap-fixed", (0, 63) in fixed or (63, 0) in fixed)
chk("B5 swap-partner Hamming distance is even, in {2,4,6} (C2 never blocks a swap adjacency)",
    {V.hamming(h, swap(h)) for h in range(64) if swap(h) != h} <= {2, 4, 6})
# C. H16 cosets
chk("C1 |H16| = 16, 4 XOR-cosets of 16, coset 0 = H16 (contains 0 and 63)", len(H16) == 16 and len(COSETS) == 4 and COSETS[0] == H16 and 63 in H16)
chk("C2 every C1 pair lies inside one coset; 8 pairs per coset", all(coset_id(a) == coset_id(b) for a, b in PAIRS) and
    sorted(sum(coset_id(a) == i for a, b in PAIRS) for i in range(4)) == [8, 8, 8, 8])
chk("C3 Hamming weights of H16 elements are {0,2,3,4,6}: same-coset transitions never have d=1 or d=5",
    {bin(h).count('1') for h in H16} == {0, 2, 3, 4, 6})
# D. the event model for the exact N0 formula: for a couple (P,Q), adjacency event <=> orientation bits differ
def seqs_of(P, Q):
    out = []
    for oP in (0, 1):
        for oQ in (0, 1):
            p = (P[1], P[0]) if oP else P
            q = (Q[1], Q[0]) if oQ else Q
            out.append((oP, oQ, list(p) + list(q)))
    return out
model_ok = True
seen = set()
for a, b in other:
    P = (a, b); Q = (swap(a), swap(b))
    if frozenset(P) in seen: continue
    seen.add(frozenset(P)); seen.add(frozenset(Q))
    for first, second in ((P, Q), (Q, P)):
        for oP, oQ, s in seqs_of(first, second):
            ev = swap(s[1]) == s[2]
            if ev != (oP != oQ): model_ok = False
chk("D1 for all 11 couples, both orders, all 4 orientations: cross-boundary swap event <=> orientation bits differ", model_ok)
# E. brute-force the inclusion-exclusion law on a toy (n free slots, m couples, fair orientation coins)
def law(n, m):
    tot = math.factorial(n)
    return [sum(Fraction((-1) ** (j - x) * math.comb(j, x) * math.comb(m, j) * math.factorial(n - j), tot)
                for j in range(x, m + 1)) for x in range(m + 1)]
def brute(n, m):
    cnt = [0] * (m + 1); items = list(range(n)); N = 0
    for perm in itertools.permutations(items):
        pos = {v: i for i, v in enumerate(perm)}
        for bits in range(1 << n):
            x = 0
            for c in range(m):
                a, b = 2 * c, 2 * c + 1
                if abs(pos[a] - pos[b]) == 1 and ((bits >> a) & 1) != ((bits >> b) & 1): x += 1
            cnt[x] += 1; N += 1
    return [Fraction(c, N) for c in cnt]
for n, m in ((5, 2), (7, 3)):
    chk(f"E1 toy n={n} m={m}: brute force == inclusion-exclusion law", brute(n, m) == law(n, m), str([str(v) for v in law(n, m)]))
L = law(31, 11)
chk("E2 law(31,11) sums to 1; E[X] = 11/31", sum(L) == 1 and sum(x * p for x, p in enumerate(L)) == Fraction(11, 31))
# F. reference statistics on RANDOM C1∩C4 orderings (never KW): W forced = 6; D and X run
def stats(seq):
    W = sum(swap(seq[i]) == seq[i + 1] for i in range(0, 63, 2))   # i even: within slot (2k,2k+1)
    X = sum(swap(seq[i]) == seq[i + 1] for i in range(1, 63, 2))   # i odd: boundary (2k+1,2k+2)
    cid = [coset_id(seq[2 * k]) for k in range(32)]
    consistent = all(coset_id(seq[2 * k]) == coset_id(seq[2 * k + 1]) for k in range(32))
    slots0 = [k + 1 for k in range(32) if cid[k] == 0]
    gaps = [slots0[i + 1] - slots0[i] for i in range(len(slots0) - 1)] + [32 + slots0[0] - slots0[-1]]
    D = sum((g - 4) ** 2 for g in gaps)
    Nsame = sum(cid[k] == cid[k + 1] for k in range(31))
    return W, X, D, Nsame, consistent, len(slots0)
rng = random.Random(20261009)
others = [p for p in PAIRS if set(p) != {0, 63}]
allW = set(); okD = True
for _ in range(2000):
    rng.shuffle(others)
    seq = [63, 0]
    for a, b in others: seq += [b, a] if rng.random() < 0.5 else [a, b]
    W, X, D, Ns, cons, n0 = stats(seq)
    allW.add(W); okD &= cons and n0 == 8 and D % 1 == 0
chk("F1 on 2000 random C1∩C4 orderings W == 6 always (forced), coset per slot consistent, 8 coset-0 slots", allW == {6} and okD)
print("DEFCHECK=" + ("PASS" if ok else "FAIL"))
