#!/usr/bin/env python3
"""Q-735 reproducer 2: the Fourier identity of proof Steps 1-3, and the bound of Steps 4-5, against
brute force on small complete skeletons.

A small complete skeleton holds one or two nonzero support classes with all four of their slots
each, and optionally the support-0 class with its three slots, in a random order (7, 8 or 11 slots).
Brute force enumerates every real hexagram walk on it (entries of the given supports, distinct C1
pairs, the anchor pair {63, 0} used with exit 0, classes by Hamming distance) and groups the walks by
class sequence.  For every class sequence that occurs, and for some that do not (F = 0), the exact
character sum of Step 3 must equal the brute-force count, and v2(F) must be at least the bound
sum(mu_s) - sum(e_k) whenever F != 0.

usage: identity_check.py [SEED [NSKEL]]        (defaults 20261113 and 8)
Tokens: Q735_IDENTITY_FIBRES=<n>, Q735_IDENTITY_MISMATCHES=<n>, Q735_BOUND_VIOLATIONS_SMALL=<n>,
Q735_IDENTITY=PASS|FAIL (PASS: no mismatch, no bound violation, and at least one nonempty fibre and
one fibre at which the bound is attained, so the check can discriminate).  Exit 0 on PASS.
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from q735_common import HEX_OF_SUPPORT, MATE, PAIR_ID, analyse, fourier_F, pc, v2  # noqa: E402


def brute_all(sk):
    out = {}; n = len(sk); used = {PAIR_ID[0]}; seq = [0] * n

    def rec(i, ex):
        if i == n:
            k = tuple(seq); out[k] = out.get(k, 0) + 1; return
        for h in HEX_OF_SUPPORT[sk[i]]:
            p = PAIR_ID[h]
            if p in used:
                continue
            used.add(p); seq[i] = pc(ex ^ h); rec(i + 1, MATE[h]); used.discard(p)

    rec(0, 0)
    return out


def main(argv):
    seed = int(argv[0]) if argv else 20261113
    nsk = int(argv[1]) if len(argv) > 1 else 8
    rng = random.Random(seed)
    st = dict(skeletons=0, fibres=0, nonempty=0, mismatches=0, bound_violations=0, tight=0)
    sizes = set()
    for _ in range(nsk):
        nR = rng.choice([1, 2, 2])
        withC = rng.random() < 0.5 if nR == 2 else True
        sup = rng.sample(range(1, 8), nR)
        sk = [s for s in sup for _ in range(4)] + ([0] * 3 if withC else [])
        rng.shuffle(sk); sizes.add(len(sk)); st["skeletons"] += 1
        allc = brute_all(sk)
        tests = list(allc.items())
        for _ in range(20):
            cl = tuple(rng.choice([1, 2, 3, 4, 5, 6]) for _ in sk)
            if cl not in allc:
                tests.append((cl, 0))
        for cl, Fb in tests:
            st["fibres"] += 1
            A = analyse(sk, list(cl))
            Ff = 0 if A is None else fourier_F(A)
            if Ff != Fb:
                st["mismatches"] += 1; print("MISMATCH", sk, cl, Fb, Ff)
            if Fb:
                st["nonempty"] += 1
                slack = v2(Fb) - A["bound"]
                if slack < 0:
                    st["bound_violations"] += 1; print("BOUND VIOLATION", sk, cl, Fb, A["bound"])
                st["tight"] += slack == 0
    print("seed", seed, "slot counts", sorted(sizes), st)
    print("Q735_IDENTITY_FIBRES=%d" % st["fibres"])
    print("Q735_IDENTITY_MISMATCHES=%d" % st["mismatches"])
    print("Q735_BOUND_VIOLATIONS_SMALL=%d" % st["bound_violations"])
    ok = st["mismatches"] == 0 and st["bound_violations"] == 0 and st["nonempty"] > 0 and st["tight"] > 0
    print("Q735_IDENTITY=%s" % ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
