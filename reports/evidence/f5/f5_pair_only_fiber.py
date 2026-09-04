#!/usr/bin/env python3
"""F5 re-check on the CORRECTED pair-only-C4 fiber (both slot-0 orientations).

Extends the archived Mode C instrument (reports/evidence/f5/f5_modec_fiber.py,
2026-07-05) to the full pair-only-C4 orientation fiber of KW's pair sequence:
slot-0 forward (o0=0, the C4-oriented fiber, 1,720,320 vectors) PLUS slot-0
reversed (o0=1, opening (0,63)), expected 983,040 vectors per the 2026-07-26
proof audit — total 2,703,360. Scores all 11 frozen functionals exactly on
every vector; reports whether the published exact-fiber verdicts survive.

Attribution: fiber method and the 11 frozen functionals are those of
f5_modec_fiber.py (see this directory's README for the per-functional
literature anchors); this extension to the pair-only-C4 fiber and its
analysis are Claude's (Opus, Anthropic), 2026-07-26. Errors are mine;
corrections invited.

Published 2026-09-04, discharging the follow-up commit TR-1 v1.16 promised.
(The private original carried the line "Scratchpad instrument for the F1
retraction fix; not a repo file." -- true when written, false once shipped.)

Usage: cd reports/evidence/f5 && python3 f5_pair_only_fiber.py > f5_pair_only_fiber.out
"""
import os
import sys
from collections import Counter
from functools import lru_cache

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
# Public-bundle portability edit (2026-09-04): repo root located relative to this
# file (reports/evidence/f5/ -> repo root) instead of the original machine-absolute
# path. See README.md in this directory for the full list of edits vs the archived
# private original -- the byte-identical rerun recorded there was performed with
# this published copy.
sys.path.insert(0, os.path.abspath(os.path.join(HERE, "..", "..", "..")))
sys.path.insert(0, HERE)
from solve import binary_hexagrams, vdb_nucorient  # noqa: E402

_gt_src = open(os.path.join(HERE, "f5_ground_truth.py")).read()
_gt_ns = {"__file__": os.path.join(HERE, "f5_ground_truth.py")}
exec(_gt_src.split("\nif len(sys.argv)")[0], _gt_ns)
f5_all, NAMES, SPEC_KW = _gt_ns["f5_all"], _gt_ns["NAMES"], _gt_ns["SPEC_KW"]

hw = lambda h: bin(h).count("1")
d = lambda a, b: hw(a ^ b)

SEQ = list(binary_hexagrams)
MEM = [(SEQ[2 * k], SEQ[2 * k + 1]) for k in range(32)]

BPD_KW = Counter(d(SEQ[2 * b + 1], SEQ[2 * b + 2]) for b in range(31))
assert BPD_KW == Counter({3: 13, 2: 8, 4: 7, 1: 2, 6: 1}), BPD_KW
DVALS = (1, 2, 3, 4, 6)
DIDX = {v: i for i, v in enumerate(DVALS)}
TARGET = tuple(BPD_KW[v] for v in DVALS)

def first(k, o):
    return MEM[k][o]

def second(k, o):
    return MEM[k][1 - o]

DT = [[[d(second(b, oa), first(b + 1, ob)) for ob in (0, 1)] for oa in (0, 1)]
      for b in range(31)]

@lru_cache(maxsize=None)
def feas(k, o, counts):
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

def enumerate_fiber(o0):
    out = []
    stack = [(0, o0, TARGET, o0)]
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

print("== F5 re-check: pair-only-C4 fiber (both slot-0 orientations) ==")
fwd = enumerate_fiber(0)
rev = enumerate_fiber(1)
print(f"forward  (o0=0, C4-oriented) fiber size = {len(fwd)}")
print(f"reversed (o0=1, opens (0,63)) fiber size = {len(rev)}")
assert len(fwd) == 1_720_320, "GATE FAIL: forward fiber != published 1,720,320"
vecs = fwd + rev
N = len(vecs)
print(f"pair-only-C4 fiber total = {N}")

# audit witness: KW with slot 0 and slots 25-29 orientation-flipped
WITNESS_BITS = (1 << 0) | (1 << 25) | (1 << 26) | (1 << 27) | (1 << 28) | (1 << 29)
vset = set(vecs)
print(f"audit witness bits {WITNESS_BITS:#010x} in fiber: {WITNESS_BITS in vset}")
assert 0 in vset  # KW itself

V = np.array(vecs, dtype=np.uint32)
O = ((V[:, None] >> np.arange(32, dtype=np.uint32)[None, :]) & 1).astype(np.uint8)
assert (V == 0).sum() == 1

# ---------------------------------------------------------------- numpy scoring
NF = len(NAMES)
vals = np.zeros((N, NF), dtype=np.int32)

def add_perslot(fi, table):
    base = sum(t[0] for t in table.values())
    delta = np.zeros(32, dtype=np.int32)
    for k, t in table.items():
        delta[k] = t[1] - t[0]
    vals[:, fi] += base + O.astype(np.int32) @ delta

def add_pairwise(fi, a, b, t):
    Oa = O[:, a].astype(np.int32)
    Ob = O[:, b].astype(np.int32)
    vals[:, fi] += (t[(0, 0)]
                    + (t[(1, 0)] - t[(0, 0)]) * Oa
                    + (t[(0, 1)] - t[(0, 0)]) * Ob
                    + (t[(1, 1)] - t[(1, 0)] - t[(0, 1)] + t[(0, 0)]) * (Oa * Ob))

def correct(h):
    return hw(h & 0b010101) + 3 - hw(h & 0b101010)

add_perslot(0, {k: tuple(int(correct(first(k, o)) > correct(second(k, o)))
                         for o in (0, 1)) for k in range(32)})

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

cslots = [k for k in range(32) if MEM[k][0] ^ MEM[k][1] == 63]
assert len(cslots) == 8
add_perslot(3, {k: tuple(int(hw(first(k, o)) > 3) for o in (0, 1)) for k in cslots})

slot_of = {h: i // 2 for i, h in enumerate(SEQ)}
cycles = [(j, slot_of[MEM[j][0] ^ 63]) for j in range(32)
          if slot_of[MEM[j][0] ^ 63] > j]
assert len(cycles) == 12
for j, k in cycles:
    add_pairwise(4, j, k, {(oa, ob): int((first(j, oa) ^ 63) == first(k, ob))
                           for oa in (0, 1) for ob in (0, 1)})

lex = {k: (int(first(k, 0) > second(k, 0)), int(first(k, 1) > second(k, 1)))
       for k in range(32)}
add_perslot(5, lex)
for k in range(31):
    add_pairwise(6, k, k + 1, {(oa, ob): int(lex[k][oa] != lex[k + 1][ob])
                               for oa in (0, 1) for ob in (0, 1)})

for k in range(1, 32):
    add_pairwise(7, k - 1, k,
                 {(oa, ob): int(d(second(k - 1, oa), first(k, ob))
                                <= d(second(k - 1, oa), second(k, ob)))
                  for oa in (0, 1) for ob in (0, 1)})

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
    "GATE FAIL: T2b (one 6, two 1s) violated on pair-only fiber"
idx = np.arange(31, dtype=np.int32)
vals[:, 8] = (I6 * idx[None, :]).sum(axis=1)
hi = np.where(I1, idx[None, :], -1).max(axis=1)
lo = np.where(I1, idx[None, :], 99).min(axis=1)
vals[:, 9] = hi - lo

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
assert list(kw_row) == SPEC_KW, f"GATE FAIL: KW scores {list(kw_row)} != {SPEC_KW}"
print(f"KW-in-fiber score gate PASS: {list(kw_row)}")

full_mult = Counter(d(SEQ[i], SEQ[i + 1]) for i in range(63))

def build_seq(bits):
    s2 = []
    for k in range(32):
        o = (bits >> k) & 1
        s2 += [first(k, o), second(k, o)]
    return s2

def c3sum(s2):
    pos = {h: i for i, h in enumerate(s2)}
    return sum(abs(pos[h] - pos[h ^ 63]) for h in range(64))

rng = np.random.default_rng(20260726)
# gate: 200 samples overall + 200 from the NEW reversed part specifically
rev_idx = np.nonzero(V & 1)[0]
assert len(rev_idx) == len(rev)
samples = list(rng.choice(N, size=200, replace=False)) + \
          list(rng.choice(rev_idx, size=200, replace=False))
for si in samples:
    s2 = build_seq(int(V[si]))
    assert sorted(s2) == list(range(64)), "GATE FAIL: not a permutation"
    assert Counter(d(s2[i], s2[i + 1]) for i in range(63)) == full_mult, \
        "GATE FAIL: sampled fiber element violates C5"
    assert c3sum(s2) == 776, "GATE FAIL: sampled fiber element C3 != 776"
    assert f5_all(s2) == list(vals[si]), \
        f"GATE FAIL: numpy vs f5_ground_truth mismatch at index {si}"
print("400-sample cross-implementation + C5 + C3=776 gate PASS "
      "(incl. 200 slot-0-reversed samples)")

# audit witness full verification
w = build_seq(WITNESS_BITS)
print(f"witness opens ({w[0]}, {w[1]}); C3 = {c3sum(w)}")

# ------------------------------------------------------- exact statistics
def two_sided(ple, pge):
    return min(1.0, 2.0 * min(ple, pge))

print(f"\n== Pair-only-C4 fiber exact results (N = {N:,}) vs published "
      f"C4-oriented fiber (N = 1,720,320) ==")
print(f"{'functional':<15} {'kw':>3} {'min':>3} {'max':>3} "
      f"{'P<=kw':>13} {'P>=kw':>13} {'two-sided p':>13} {'support':>7}")
for fi, name in enumerate(NAMES):
    col = vals[:, fi]
    kw = SPEC_KW[fi]
    ple = float((col <= kw).sum()) / N
    pge = float((col >= kw).sum()) / N
    p = two_sided(ple, pge)
    sup = len(np.unique(col))
    tag = "  FORCED-ON-FIBER" if sup == 1 else ""
    print(f"{name:<15} {kw:>3} {col.min():>3} {col.max():>3} "
          f"{ple:>13.6e} {pge:>13.6e} {p:>13.6e} {sup:>7}{tag}")

# per-part breakdown for vdb_nuc + the three forced rows
print("\n== vdb_nuc detail ==")
col = vals[:, 10]
colf = vals[:len(fwd), 10]
colr = vals[len(fwd):, 10]
print(f"full fiber:  max = {col.max()}, min = {col.min()}")
for thr in (28, 29, 30):
    c = int((col >= thr).sum())
    print(f"full fiber:  #vectors with X >= {thr}: {c}  (P = {c / N:.6e})")
print(f"forward part:  max = {colf.max()}, #>=29 = {int((colf >= 29).sum())}")
print(f"reversed part: max = {colr.max()}, #>=29 = {int((colr >= 29).sum())}")
c29 = int((col >= 29).sum())
print(f"one-sided P(X >= 29) full fiber = {c29}/{N} = {c29 / N:.6e} "
      f"(published C4-oriented: 12/1,720,320 = 6.9754e-06)")
ple = float((col <= 29).sum()) / N
pge = float((col >= 29).sum()) / N
print(f"two-sided p at KW=29: {two_sided(ple, pge):.6e} (published 1.3951e-05)")

print("\n== rows 8-10 on the reversed part (published: constant on C4-oriented fiber) ==")
for fi in (7, 8, 9):
    ur = np.unique(vals[len(fwd):, fi])
    uf = np.unique(vals[:len(fwd), fi])
    print(f"{NAMES[fi]:<15} forward support {list(uf)}, reversed support {list(ur)}")
