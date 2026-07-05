#!/usr/bin/env python3
"""F5 Mode C — exact orientation-fiber analysis (dispositive mode, frozen spec §6).

Enumerates the full valid orientation fiber of KW's pair sequence (frozen spec §3:
1,720,320 vectors under C2+C5, o0 fixed) and scores all 11 frozen functionals
exactly on every fiber element. Emits exact histograms, KW two-sided
atom-inclusive p-values (p = min(1, 2*min(P<=, P>=))), §3 structure gates,
the §6(b) convention control (lex-minimal fiber element), and Mode-U tier-1
p-values parsed from f5_tier1.out for the side-by-side table.

Pre-registration: F5_ORIENTATION_PREREGISTRATION_2026_07_FROZEN.md (§3 fiber
method — exhaustive DFS with exact BPD-multiset pruning; §5+addendum functionals;
§6 protocol). Functional scoring delegates to f5_ground_truth.py (two-language
gated against solve.c SOLVE_KNUTH_SCORE_F5, commit db66657); numpy fast path is
sample-gated against f5_ground_truth.f5_all on random fiber elements.

Attribution: functionals anchored to Cook 2006, Moore 1989, Schulz 1990,
Davis 2012, Shao Yong/Leibniz 1703, Chan 2026, McKenna & McKenna 1975,
Van den Berghe c.1999-2005 (V-8, #11). Fiber method + implementation:
Claude (Fable), 2026-07-05, per the frozen pre-registration. Errors are
Claude's; corrections invited.

Usage: python3 f5_modec_fiber.py > f5_modec_fiber.out
"""
import os
import sys
import re
from collections import Counter
from functools import lru_cache

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
# Public-bundle portability edit (2026-07-05): repo root located relative to this
# file (reports/evidence/f5/ -> repo root) instead of the original absolute path.
# Sole change vs the archived private original; see README.md in this directory.
sys.path.insert(0, os.path.abspath(os.path.join(HERE, "..", "..", "..")))
sys.path.insert(0, HERE)
from solve import binary_hexagrams, vdb_nucorient  # noqa: E402

# f5_ground_truth.py has no __main__ guard (its KW self-check + sys.exit runs on
# import); load its definitions by exec'ing the source truncated at the CLI block.
_gt_src = open(os.path.join(HERE, "f5_ground_truth.py")).read()
_gt_ns = {"__file__": os.path.join(HERE, "f5_ground_truth.py")}
exec(_gt_src.split("\nif len(sys.argv)")[0], _gt_ns)
f5_all, NAMES, SPEC_KW = _gt_ns["f5_all"], _gt_ns["NAMES"], _gt_ns["SPEC_KW"]

hw = lambda h: bin(h).count("1")
d = lambda a, b: hw(a ^ b)

SEQ = list(binary_hexagrams)
MEM = [(SEQ[2 * k], SEQ[2 * k + 1]) for k in range(32)]  # (first, second) as in KW

# ---------------------------------------------------------------- fiber target
# Between-pair distance multiset of KW == T2b universal multiset (frozen spec).
BPD_KW = Counter(d(SEQ[2 * b + 1], SEQ[2 * b + 2]) for b in range(31))
assert BPD_KW == Counter({3: 13, 2: 8, 4: 7, 1: 2, 6: 1}), BPD_KW
DVALS = (1, 2, 3, 4, 6)
DIDX = {v: i for i, v in enumerate(DVALS)}
TARGET = tuple(BPD_KW[v] for v in DVALS)

def first(k, o):
    return MEM[k][o]

def second(k, o):
    return MEM[k][1 - o]

# dist_table[b][oa][ob] = boundary distance between slot b (orient oa) and b+1 (orient ob)
DT = [[[d(second(b, oa), first(b + 1, ob)) for ob in (0, 1)] for oa in (0, 1)]
      for b in range(31)]

@lru_cache(maxsize=None)
def feas(k, o, counts):
    """True iff boundaries k..30 can consume exactly `counts` given slot k orient o."""
    if k == 31:
        return not any(counts)
    for o2 in (0, 1):
        dv = DT[k][o][o2]
        i = DIDX.get(dv)
        if i is None or counts[i] == 0:
            continue
        nc = counts[:i] + (counts[i] - 1,) + counts[i + 1:]
        if feas(k + 1, o2, nc):
            return True
    return False

def enumerate_fiber():
    out = []
    stack = [(0, 0, TARGET, 0)]
    while stack:
        k, o, counts, bits = stack.pop()
        if k == 31:
            out.append(bits)
            continue
        for o2 in (0, 1):
            dv = DT[k][o][o2]
            i = DIDX.get(dv)
            if i is None or counts[i] == 0:
                continue
            nc = counts[:i] + (counts[i] - 1,) + counts[i + 1:]
            if feas(k + 1, o2, nc):
                stack.append((k + 1, o2, nc, bits | (o2 << (k + 1))))
    return out

print("== F5 Mode C: exact fiber enumeration (frozen spec section 3 method) ==")
vecs = enumerate_fiber()
N = len(vecs)
print(f"fiber size = {N}")
assert N == 1_720_320, "GATE FAIL: fiber size != frozen spec 1,720,320"
V = np.array(vecs, dtype=np.uint32)
O = ((V[:, None] >> np.arange(32, dtype=np.uint32)[None, :]) & 1).astype(np.uint8)
assert (V == 0).sum() == 1, "GATE FAIL: KW (all-zero orientation) not unique in fiber"

# section 3 gates: marginals + forced slot 30 + single-flip stiffness
marg = O.mean(axis=0)
assert marg[0] == 0.0 and marg[30] == 0.0, "GATE FAIL: slot 0/30 not forced"
assert abs(marg[13] - 0.4) < 1e-9 and abs(marg[14] - 0.5333333333333333) < 1e-9, \
    "GATE FAIL: slot 13/14 marginals != frozen spec"
free = [k for k in range(1, 32) if k not in (13, 14, 30)]
assert all(abs(marg[k] - 0.5) < 1e-9 for k in free), "GATE FAIL: 28 balanced marginals"
vset = set(vecs)
single_ok = sorted(k for k in range(1, 32) if (1 << k) in vset)
print(f"marginals gate PASS (28x0.5, slot13=0.4, slot14=0.5333, slot30 forced)")
print(f"single-flip-valid slots = {single_ok}")
assert single_ok == [3, 5, 9, 10, 11, 12, 17, 21, 31], "GATE FAIL: single-flip stiffness"

# ---------------------------------------------------------------- numpy scoring
NF = len(NAMES)
vals = np.zeros((N, NF), dtype=np.int32)

def add_perslot(fi, table):
    """table[k] = (contribution at o=0, at o=1); accumulate into vals[:, fi]."""
    base = sum(t[0] for t in table.values())
    delta = np.zeros(32, dtype=np.int32)
    for k, t in table.items():
        delta[k] = t[1] - t[0]
    vals[:, fi] += base + O.astype(np.int32) @ delta

def add_pairwise(fi, a, b, t):
    """t[(oa,ob)] contribution for slot pair (a,b)."""
    Oa = O[:, a].astype(np.int32)
    Ob = O[:, b].astype(np.int32)
    vals[:, fi] += (t[(0, 0)]
                    + (t[(1, 0)] - t[(0, 0)]) * Oa
                    + (t[(0, 1)] - t[(0, 0)]) * Ob
                    + (t[(1, 1)] - t[(1, 0)] - t[(0, 1)] + t[(0, 0)]) * (Oa * Ob))

def correct(h):
    return hw(h & 0b010101) + 3 - hw(h & 0b101010)

# 1 correct_lead
add_perslot(0, {k: tuple(int(correct(first(k, o)) > correct(second(k, o)))
                         for o in (0, 1)) for k in range(32)})

# 2 rising + 3 rf_alt (directional pairs, slot order)
def sym(x, y):
    mb = 0 if hw(x) > 3 else 1
    sa = sum(i + 1 for i in range(6) if (x >> i) & 1 == mb)
    sb = sum(i + 1 for i in range(6) if (y >> i) & 1 == mb)
    return "R" if sb > sa else ("F" if sb < sa else "T")

dslots = [k for k in range(32) if MEM[k][0] ^ MEM[k][1] != 63 and hw(MEM[k][0]) != 3]
assert len(dslots) == 18
symt = {k: (sym(first(k, 0), second(k, 0)), sym(first(k, 1), second(k, 1)))
        for k in dslots}
add_perslot(1, {k: tuple(int(s == "R") for s in symt[k]) for k in dslots})
for j in range(len(dslots) - 1):
    a, b = dslots[j], dslots[j + 1]
    add_pairwise(2, a, b, {(oa, ob): int(not (symt[a][oa] == symt[b][ob]
                                              and symt[a][oa] != "T"))
                           for oa in (0, 1) for ob in (0, 1)})

# 4 gender_lead — ground-truth condition is xor==63 (8 slots: the 4 weight-
# asymmetric palindrome/complement pairs + 4 hw-3 reversal pairs that are also
# complements; the latter contribute 0 at every orientation since hw(first)=3).
cslots = [k for k in range(32) if MEM[k][0] ^ MEM[k][1] == 63]
assert len(cslots) == 8
assert sum(1 for k in cslots if hw(MEM[k][0]) != 3) == 4  # frozen spec's 4
add_perslot(3, {k: tuple(int(hw(first(k, o)) > 3) for o in (0, 1)) for k in cslots})

# 5 mirror_order (complement-involution two-cycles on slots)
slot_of = {h: i // 2 for i, h in enumerate(SEQ)}
cycles = [(j, slot_of[MEM[j][0] ^ 63]) for j in range(32)
          if slot_of[MEM[j][0] ^ 63] > j]
assert len(cycles) == 12
for j, k in cycles:
    add_pairwise(4, j, k, {(oa, ob): int((first(j, oa) ^ 63) == first(k, ob))
                           for oa in (0, 1) for ob in (0, 1)})

# 6 lex_dev + 7 orient_alt
lex = {k: (int(first(k, 0) > second(k, 0)), int(first(k, 1) > second(k, 1)))
       for k in range(32)}
add_perslot(5, lex)
for k in range(31):
    add_pairwise(6, k, k + 1, {(oa, ob): int(lex[k][oa] != lex[k + 1][ob])
                               for oa in (0, 1) for ob in (0, 1)})

# 8 greedy_entry
for k in range(1, 32):
    add_pairwise(7, k - 1, k,
                 {(oa, ob): int(d(second(k - 1, oa), first(k, ob))
                                <= d(second(k - 1, oa), second(k, ob)))
                  for oa in (0, 1) for ob in (0, 1)})

# 9 bpd_six_pos + 10 bpd_one_span via boundary-distance indicator columns
I6 = np.zeros((N, 31), dtype=bool)
I1 = np.zeros((N, 31), dtype=bool)
for b in range(31):
    Oa = O[:, b].astype(np.int32)
    Ob = O[:, b + 1].astype(np.int32)
    for M, val in ((I6, 6), (I1, 1)):
        t = {(oa, ob): int(DT[b][oa][ob] == val) for oa in (0, 1) for ob in (0, 1)}
        col = (t[(0, 0)] + (t[(1, 0)] - t[(0, 0)]) * Oa + (t[(0, 1)] - t[(0, 0)]) * Ob
               + (t[(1, 1)] - t[(1, 0)] - t[(0, 1)] + t[(0, 0)]) * (Oa * Ob))
        M[:, b] = col.astype(bool)
assert (I6.sum(axis=1) == 1).all() and (I1.sum(axis=1) == 2).all(), \
    "GATE FAIL: T2b (one 6, two 1s) violated on fiber"
idx = np.arange(31, dtype=np.int32)
vals[:, 8] = (I6 * idx[None, :]).sum(axis=1)
hi = np.where(I1, idx[None, :], -1).max(axis=1)
lo = np.where(I1, idx[None, :], 99).min(axis=1)
vals[:, 9] = hi - lo

# 11 vdb_nuc: per-slot flip deltas of vdb_nucorient (fiber decomposition,
# frozen addendum: exactly 1 bit per predicted pair); sample-gated below.
kwv = vdb_nucorient(list(SEQ))
assert kwv == 29
deltas = {}
for k in range(32):
    s2 = list(SEQ)
    s2[2 * k], s2[2 * k + 1] = s2[2 * k + 1], s2[2 * k]
    deltas[k] = vdb_nucorient(s2) - kwv
add_perslot(10, {k: (0, deltas[k]) for k in range(32)})
vals[:, 10] += kwv

# ------------------------------------------------------------------ gates
kw_row = vals[V == 0][0]
assert list(kw_row) == SPEC_KW, f"GATE FAIL: KW fiber scores {list(kw_row)} != {SPEC_KW}"
print(f"KW-in-fiber score gate PASS: {list(kw_row)}")

rng = np.random.default_rng(20260705)
sample = rng.choice(N, size=200, replace=False)
full_mult = Counter(d(SEQ[i], SEQ[i + 1]) for i in range(63))
for si in sample:
    bits = int(V[si])
    s2 = []
    for k in range(32):
        o = (bits >> k) & 1
        s2 += [first(k, o), second(k, o)]
    assert Counter(d(s2[i], s2[i + 1]) for i in range(63)) == full_mult, \
        "GATE FAIL: sampled fiber element violates C5"
    assert f5_all(s2) == list(vals[si]), \
        f"GATE FAIL: numpy vs f5_ground_truth mismatch at fiber index {si}"
print("200-sample cross-implementation + C5-validity gate PASS "
      "(numpy fast path == f5_ground_truth.f5_all; two-language gated vs solve.c)")

# ------------------------------------------------------- Mode C statistics
def two_sided(ple, pge):
    return min(1.0, 2.0 * min(ple, pge))

print("\n== Mode C exact results (dispositive; N = 1,720,320) ==")
print(f"{'functional':<15} {'kw':>3} {'min':>3} {'max':>3} "
      f"{'P<=kw':>13} {'P>=kw':>13} {'two-sided p':>13} {'support':>7}")
modec_p = {}
for fi, name in enumerate(NAMES):
    col = vals[:, fi]
    kw = SPEC_KW[fi]
    ple = float((col <= kw).sum()) / N
    pge = float((col >= kw).sum()) / N
    p = two_sided(ple, pge)
    modec_p[name] = (ple, pge, p)
    sup = len(np.unique(col))
    tag = "  FORCED-ON-FIBER" if sup == 1 else ""
    print(f"{name:<15} {kw:>3} {col.min():>3} {col.max():>3} "
          f"{ple:>13.6e} {pge:>13.6e} {p:>13.6e} {sup:>7}{tag}")

print("\n== Mode C exact fiber histograms (counts / 1,720,320) ==")
for fi, name in enumerate(NAMES):
    cnt = Counter(vals[:, fi].tolist())
    for v in sorted(cnt):
        print(f"modec_hist {name} {v} {cnt[v]}")

# vdb_nuc headline + neighborhood
col = vals[:, 10]
for thr in (28, 29, 30):
    c = int((col >= thr).sum())
    print(f"vdb_nuc: exact #fiber vectors with X >= {thr}: {c}  "
          f"(P = {c / N:.6e})")

# ------------------------------------------- section 6(b) convention control
base_l = np.array([lex[k][0] for k in range(32)], dtype=np.int64)
lbits = np.bitwise_xor(base_l[None, :], O.astype(np.int64))
key = (lbits << np.arange(31, -1, -1, dtype=np.int64)[None, :]).sum(axis=1)
lexmin_i = int(key.argmin())
print(f"\n== Convention control (frozen spec 6b): lex-minimal fiber element ==")
print(f"lexmin orientation bitmask = {int(V[lexmin_i]):#010x} "
      f"(popcount {int(bin(int(V[lexmin_i])).count('1'))})")
print(f"{'functional':<15} {'lexmin':>6} {'ModeC two-sided p':>18}   (KW p for comparison)")
for fi, name in enumerate(NAMES):
    v = int(vals[lexmin_i, fi])
    colf = vals[:, fi]
    p = two_sided(float((colf <= v).sum()) / N, float((colf >= v).sum()) / N)
    print(f"{name:<15} {v:>6} {p:>18.6e}   (KW {modec_p[name][2]:.6e})")

# --------------------------------------- Mode U tier-1 p-values (side table)
print("\n== Mode U tier-1 (2e9 probes) two-sided p, atom-inclusive, from f5_tier1.out ==")
tier1 = open(os.path.join(HERE, "f5_tier1.out")).read()
for name in NAMES:
    short = {"vdb_nuc": "vdb_nuc"}.get(name, name)
    m = re.search(r"\[f5 \d+ %s\s*\] mean=\S+ min=(\d+) max=(\d+) kw=(\d+) "
                  r"below=(\S+) at=(\S+) above=(\S+)" % re.escape(short), tier1)
    lo_, hi_, kw, below, at, above = m.groups()
    ple = float(below) + float(at)
    pge = float(at) + float(above)
    if float(at) == 0.0 and float(above) == 0.0:
        print(f"{name:<15} kw={kw} sampled range [{lo_},{hi_}]: ZERO sampled mass at/above KW "
              f"-> p_hat = 0; report as bound (see results doc)")
    else:
        print(f"{name:<15} kw={kw} P<= {ple:.8f} P>= {pge:.8f} "
              f"two-sided p = {two_sided(ple, pge):.8f}")

# ------------------------------------ corpus/gauge local two-language check
# NOTE (2026-07-05): the MAWANGDUI row was corrected. The original c230 run used
# an erroneous Mawangdui array (see CITATIONS.md errata; corrected order per
# Shaughnessy 2022, Table 11.2). The corrected row below was two-language
# verified locally on 2026-07-05 (SOLVE_KNUTH_SCORE_F5=2 SOLVE_F5_TESTVEC=...
# reproduces the same 11 values). Original erroneous row, for the record:
#   values [63,62,61,57,56,59,58,60,31,30,29,25,24,27,26,28,23,22,21,17,16,19,
#           18,20,15,14,13,9,8,11,10,12,7,6,5,1,0,3,2,4,55,54,53,49,48,51,50,
#           52,47,46,45,41,40,43,42,44,39,38,37,33,32,35,34,36]
#   f5_all -> [16,22,4,0,16,16,15,24,0,1,14]
print("\n== corpus/gauge control re-computation (local python vs on-VM C values) ==")
CG = {
 "KW": SEQ,
 "MAWANGDUI_VALUES": [63,56,60,59,58,61,57,62,36,39,32,35,34,37,33,38,18,23,16,20,19,21,17,22,9,15,8,12,11,10,13,14,0,7,4,3,2,5,1,6,27,31,24,28,26,29,25,30,45,47,40,44,43,42,41,46,54,55,48,52,51,50,53,49],
 "JINGFANG_VALUES": [63,62,60,56,48,32,40,47,9,8,10,14,6,22,30,25,18,19,17,21,29,13,5,2,36,37,39,35,43,59,51,52,0,1,3,7,15,31,23,16,54,55,53,49,57,41,33,38,45,44,46,42,34,50,58,61,27,26,24,28,20,4,12,11],
 "GAUGE_UPDOWN_BITREV6": [63,0,34,17,58,23,16,2,59,55,56,7,47,61,8,4,38,25,48,3,37,41,1,32,39,57,33,30,18,45,14,28,15,60,5,40,43,53,10,20,49,35,62,31,6,24,22,26,46,29,36,9,11,52,44,13,27,54,19,50,51,12,42,21],
 "GAUGE_BACKFRONT": [42,21,12,51,19,50,27,54,44,13,11,52,36,9,46,29,22,26,6,24,62,31,49,35,10,20,43,53,5,40,15,60,14,28,45,18,30,33,39,57,1,32,37,41,48,3,38,25,8,4,47,61,56,7,59,55,16,2,58,23,34,17,0,63],
}
expected = {
 "KW": [15,10,10,2,7,17,13,23,18,4,29],
 "MAWANGDUI_VALUES": [15,19,11,0,4,7,8,12,0,1,1],
 "JINGFANG_VALUES": [16,22,17,0,16,16,18,29,0,1,6],
 "GAUGE_UPDOWN_BITREV6": [7,8,10,2,7,17,12,23,18,4,4],
 "GAUGE_BACKFRONT": [7,8,10,2,7,15,13,23,12,4,5],
}
rev6 = lambda h: int(format(h, "06b")[::-1], 2)
assert CG["GAUGE_UPDOWN_BITREV6"] == [rev6(h) for h in SEQ], "gauge updown vector mismatch"
assert CG["GAUGE_BACKFRONT"] == SEQ[::-1], "gauge backfront vector mismatch"
for nm, sq in CG.items():
    got = f5_all(sq)
    ok = "OK" if got == expected[nm] else f"MISMATCH vs on-VM {expected[nm]}"
    print(f"{nm}: {','.join(map(str, got))} {ok}")
    assert got == expected[nm]
print("corpus/gauge two-language gate PASS")
