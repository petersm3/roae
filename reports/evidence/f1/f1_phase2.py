import sys
sys.path.insert(0, __import__('os').path.join(__import__('os').path.dirname(__file__), '..', '..', '..'))
import solve, itertools
from functools import lru_cache
KW = list(solve.binary_hexagrams)
PAIRS = [(KW[2*i], KW[2*i+1]) for i in range(32)]
def d(a, b): return bin(a ^ b).count("1")

def count_exact_bruteforce(pair_indices, start_exit):
    """exact count of orderings of the given pairs (both orientations), no d=5 transitions."""
    n = len(pair_indices)
    total = 0
    def rec(used, last, k):
        nonlocal total
        if k == n: total += 1; return
        for p in pair_indices:
            if p in used: continue
            for o in (0, 1):
                f = PAIRS[p][1] if o else PAIRS[p][0]
                s = PAIRS[p][0] if o else PAIRS[p][1]
                if d(last, f) == 5: continue
                rec(used | {p}, s, k + 1)
    rec(frozenset(), start_exit, 0)
    return total

def count_via_membership_dp(pair_indices, start_exit):
    """DP over exact subsets (bitmask) — ground truth for medium n; NOT the lumped DP."""
    n = len(pair_indices)
    from functools import lru_cache
    @lru_cache(maxsize=None)
    def rec(mask, last):
        if mask == (1 << n) - 1: return 1
        tot = 0
        for i, p in enumerate(pair_indices):
            if mask >> i & 1: continue
            for o in (0, 1):
                f = PAIRS[p][1] if o else PAIRS[p][0]
                s = PAIRS[p][0] if o else PAIRS[p][1]
                if d(last, f) == 5: continue
                tot += rec(mask | 1 << i, s)
        return tot
    return rec(0, start_exit)

# sanity: brute == mask-DP on a small instance
sub = [1,2,3,4,5,6,7]
b = count_exact_bruteforce(sub, 0)
m = count_via_membership_dp(sub, 0)
print("7-pair instance: brute =", b, " mask-DP =", m, " agree:", b == m)
# full C1C2C4 exact via mask-DP is 2^31 — infeasible; the lumped DP is the phase-2 question.
# LUMPABILITY TEST: within a class, are members exchangeable? Test: two same-class pairs swapped
# in a random instance must give identical counts. Pick classes from phase 1 signature quickly:
