#!/usr/bin/env python3
"""PREREG_QOY1_Q992_2026_10_09 §4.1 / §7.3: the exact N0 laws of X and D, KW's tails under them,
the seeded N0 sampler cross-check (10^6 draws), the uniform-64 W reference (10^6 draws) and the
corpus-control values. Uses the scorer's own solve.py functions (the pinned instrument).
Usage: n0_exact.py <public worktree>   (prints KEY=value tokens)."""
import sys, itertools, math, random
from fractions import Fraction as F
sys.path.insert(0, sys.argv[1])
import solve

KW = list(solve.binary_hexagrams)
KW_X, KW_D, KW_W = solve.q992_X(KW), solve.qoy1_D(KW), solve.q992_W(KW)

def tails(law, v):
    le = sum((p for x, p in law.items() if x <= v), F(0)); ge = sum((p for x, p in law.items() if x >= v), F(0))
    return le, ge, min(F(1), 2 * min(le, ge))

def fr(q): return "%s|%.12e" % (q, float(q))

# --- X: inclusion-exclusion, n = 31 free slots, m = 11 couples
lawX = {}
for x in range(12):
    lawX[x] = sum((F((-1) ** (j - x) * math.comb(j, x) * math.comb(11, j) * math.factorial(31 - j), math.factorial(31))
                   for j in range(x, 12)), F(0))
assert sum(lawX.values()) == 1
EX = sum(x * p for x, p in lawX.items())
print("Q992_N0_LAW=" + ",".join("%d:%s" % (x, lawX[x]) for x in range(12)))
print("Q992_N0_E=%s" % EX)
print("Q992_N0_E_MATCHES_11_31=%s" % ("YES" if EX == F(11, 31) else "NO"))

# --- D: enumeration of C(31,7) slot sets containing slot 1, and of all C(32,8)
def Dof(a):
    g = [a[i+1] - a[i] for i in range(len(a) - 1)] + [32 + a[0] - a[-1]]
    return sum((x - 4) ** 2 for x in g)
cnt7 = {}
for c in itertools.combinations(range(2, 33), 7):
    d = Dof((1,) + c); cnt7[d] = cnt7.get(d, 0) + 1
cnt8 = {}
for c in itertools.combinations(range(1, 33), 8):
    d = Dof(c); cnt8[d] = cnt8.get(d, 0) + 1
n7, n8 = math.comb(31, 7), math.comb(32, 8)
assert sum(cnt7.values()) == n7 and sum(cnt8.values()) == n8
lawD = {d: F(c, n7) for d, c in sorted(cnt7.items())}
lawD8 = {d: F(c, n8) for d, c in sorted(cnt8.items())}
print("QOY1_N0_LAW=" + ",".join("%d:%d/%d" % (d, cnt7[d], n7) for d in sorted(cnt7)))
print("QOY1_N0_SUPPORT_SIZE=%d" % len(cnt7))
print("QOY1_N0_C32_8_AGREES=%s" % ("YES" if lawD == lawD8 else "NO"))
ED = sum(d * p for d, p in lawD.items())
print("QOY1_N0_E=%s|%.6f" % (ED, float(ED)))

for tag, law, v in (("Q992", lawX, KW_X), ("QOY1", lawD, KW_D)):
    le, ge, two = tails(law, v)
    print("%s_KW_VALUE=%d" % (tag, v))
    print("%s_N0_P_LE=%s" % (tag, fr(le))); print("%s_N0_P_GE=%s" % (tag, fr(ge))); print("%s_N0_P_TWO=%s" % (tag, fr(two)))

# --- seeded N0 sampler cross-check (§4.1): 10^6 draws, 4-sigma binomial band
seed = solve.qoy_seed("ROAE-QOY1-Q992-2026-10-09/pairnull-crosscheck")
assert seed == 4538186694822709970
rng = random.Random(seed)
NDR = 10 ** 6
hx = hd = 0
for _ in range(NDR):
    s = solve.qoy_c1c4_draw(rng)
    if solve.q992_X(s) == KW_X: hx += 1
    if solve.qoy1_D(s) <= KW_D: hd += 1
ok = True
for tag, h, p in (("X_EQ_KW", hx, float(lawX[KW_X])), ("D_LE_KW", hd, float(tails(lawD, KW_D)[0]))):
    mu, sd = NDR * p, math.sqrt(NDR * p * (1 - p))
    inb = abs(h - mu) <= 4 * sd
    ok = ok and inb
    print("N0_SAMPLER_%s count=%d expected=%.1f band=[%.1f,%.1f] inside=%s" % (tag, h, mu, mu - 4*sd, mu + 4*sd, "YES" if inb else "NO"))
print("N0_SAMPLER_SEED=%d" % seed)
print("N0_SAMPLER_CROSSCHECK=%s" % ("PASS" if ok else "FAIL"))

# --- uniform-64 W reference (labelled reference, not a test)
rng = random.Random(solve.qoy_seed("ROAE-QOY1-Q992-2026-10-09/uniform64-W-reference"))
hw = {}
for _ in range(NDR):
    s = list(range(64)); rng.shuffle(s)
    w = solve.q992_W(s); hw[w] = hw.get(w, 0) + 1
print("Q992_W_UNIFORM64_HIST=" + ",".join("%d:%d" % (w, hw[w]) for w in sorted(hw)) + " (REFERENCE, 10^6 uniform-64 draws, seed sha256('ROAE-QOY1-Q992-2026-10-09/uniform64-W-reference'))")

# --- KW descriptives and corpus controls
ids, cons = solve.qoy1_cosets(KW)
print("Q992_KW_W=%d" % KW_W)
print("Q992_KW_T=%d" % solve.q992_T(KW)); print("Q992_KW_A=%d" % solve.q992_A(KW))
print("QOY1_KW_COSETS_CONSISTENT=%s" % ("YES" if cons else "NO"))
print("QOY1_KW_NSAME=%d" % solve.qoy1_NSAME(KW))
cs = "".join(map(str, ids))
print("QOY1_KW_COSET_STRING=%s" % cs)
print("QOY1_COSET_STRING_MATCHES_FINDING=%s" % ("YES" if cs == "03223023033110023211211332012100" else "NO"))
for nm, fn in (("JINGFANG", solve._r7_jingfang), ("MAWANGDUI", solve._r7_mawangdui), ("FUXI", solve._r7_fuxi)):
    s = fn(); assert sorted(s) == list(range(64)), nm
    print("CONTROL_%s %s" % (nm, solve.qoy_line(s)))
