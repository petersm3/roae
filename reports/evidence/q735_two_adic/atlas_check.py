#!/usr/bin/env python3
"""Q-735 reproducer 4: the n = 31 atlas against the proved statement (atlas format version 2).

Reads only the atlas JSON (integer arithmetic on its decimal strings).  Checks:
  * the atlas is the n = 31 SUPER space with King Wen's budget {1:2, 2:8, 3:13, 4:7, 6:1}
    (from the by_class column sums), every layer summing to N;
  * V2 (layers[k].by_class): 2^21 * 3 divides N and every V2 cell (the theorem); the gcd of the
    nonzero cells is exactly 2^21 * 3 and the minimum v2 is 21 in every layer (read from the atlas,
    not from the proof);
  * V1 (layers[k].marginal_raw): for each pair p with S3-stabiliser H (the coordinate permutations
    of the three line pairs that fix p as a set), every cell is divisible by 2^18 * |H| for a
    reversible pair with |H| even, by 2^19 for the six reversible pairs with |H| = 1 (the half-pin
    argument), and by 2^20 * |H| for a complement pair (the proved floors), hence by 16;
    and the observed minimum v2 per stabiliser class is printed beside the floor.

usage: atlas_check.py ATLAS.json           (the tracked one is runs/20260906_kc_ladders_n31/atlas_n31.json)
Tokens: Q735_ATLAS_IS_N31_KW_BUDGET, Q735_ATLAS_V2_DIVISIBLE, Q735_ATLAS_V2_GCD=<v2>,<v3>,
Q735_ATLAS_V2_MIN_V2_EVERY_LAYER=<m>, Q735_ATLAS_V1_FLOORS, Q735_ATLAS_V1_MOD16, Q735_ATLAS=PASS|FAIL.
"""
import itertools
import json
import os
import sys
from math import gcd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from q735_common import KW_PAIRS, MATE, S, T, hexof, pc, rev6, v2, vp  # noqa: E402

CLS = ("d1", "d2", "d3", "d4", "d6")


def perm_bits(pi, x):
    return sum(((x >> j) & 1) << pi[j] for j in range(3))


def stabiliser(pair):
    a, b = pair; n = 0
    for pi in itertools.permutations(range(3)):
        img = {hexof(perm_bits(pi, S(h)), perm_bits(pi, T(h))) for h in (a, b)}
        n += img == {a, b}
    return n


def main(argv):
    if len(argv) != 1:
        print(__doc__.strip().split("\n\n")[-2]); print("Q735_ATLAS=ERROR"); return 2
    with open(argv[0]) as fh:
        a = json.load(fh)
    ok_all = True

    def verdict(name, ok):
        nonlocal ok_all
        print("%s=%s" % (name, "PASS" if ok else "FAIL")); ok_all = ok_all and ok

    N = int(a["N_total"]); L = a["layers"]; n = int(a["n"])
    col = [sum(int(l["by_class"][c]) for l in L) for c in CLS]
    b0 = [x // N for x in col] if all(x % N == 0 for x in col) else None
    rows_ok = all(sum(int(l["by_class"][c]) for c in CLS) == N for l in L)
    print("n", n, "space", a.get("space"), "layers", len(L), "budget from column sums", b0, "N v2", v2(N), "v3", vp(N, 3))
    verdict("Q735_ATLAS_IS_N31_KW_BUDGET", n == 31 and len(L) == 31 and a.get("space") == "C1C2C4C5-SUPERSPACE"
            and b0 == [2, 8, 13, 7, 1] and rows_ok)

    unit = 3 << 21
    g = 0; div = N % unit == 0; minlayer = []; hist = {}
    for l in L:
        m = None
        for c in CLS:
            x = int(l["by_class"][c])
            div = div and x % unit == 0
            if x == 0:
                continue
            g = gcd(g, x); e = v2(x); hist[e] = hist.get(e, 0) + 1
            m = e if m is None else min(m, e)
        minlayer.append(m)
    print("V2 nonzero cells", sum(hist.values()), "; v2 histogram", sorted(hist.items()))
    print("V2 min v2 per layer", minlayer)
    verdict("Q735_ATLAS_V2_DIVISIBLE", div)
    print("Q735_ATLAS_V2_GCD=%d,%d" % (v2(g), vp(g, 3)))
    print("Q735_ATLAS_V2_MIN_V2_EVERY_LAYER=%s" % (minlayer[0] if len(set(minlayer)) == 1 else "VARIES"))

    floors_ok = mod16 = True; groups = {}
    for p in range(1, 32):
        pr = KW_PAIRS[p]; H = stabiliser(pr)
        is_c = rev6(pr[0]) == pr[0]
        assert MATE[pr[0]] == pr[1]
        # 2^18 * |H| (reversible) or 2^20 * |H| (complement) from one pinned pair; for the six reversible
        # pairs with trivial stabiliser the mirror-pair (half-pin) argument gives 2^19
        floor_v2 = (20 if is_c else 18) + v2(H) + (1 if (not is_c and H == 1) else 0); floor_v3 = vp(H, 3)
        vals = [int(l["marginal_raw"].get("pair%d" % p, "0")) for l in L]   # an absent key is a zero cell
        for x in vals:
            mod16 = mod16 and x % 16 == 0
            floors_ok = floors_ok and x % (2 ** floor_v2 * 3 ** floor_v3) == 0
        nz = [x for x in vals if x]
        key = ("C" if is_c else "R", pc(S(pr[0])), H, floor_v2)
        groups.setdefault(key, []).append((p, min(v2(x) for x in nz), min(vp(x, 3) for x in nz)))
    for (kind, ws, H, fl), ps in sorted(groups.items(), key=str):
        print("V1 %s pairs, |support| %d, |H| %d: proved floor 2^%d%s ; observed min v2 %s ; pairs %s" % (
            kind, ws, H, fl, " * 3" if H == 6 else "", sorted(set(m for _, m, _ in ps)),
            ",".join(str(p) for p, _, _ in ps)))
    verdict("Q735_ATLAS_V1_FLOORS", floors_ok)
    verdict("Q735_ATLAS_V1_MOD16", mod16)
    ok = ok_all and g == unit and len(set(minlayer)) == 1 and minlayer[0] == 21
    print("Q735_ATLAS=%s" % ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
