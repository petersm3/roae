#!/usr/bin/env python3
"""Direct vdb_nucorient check of the two 30/30 vectors found by
f5_pair_only_fiber.py, on the reversed (o0=1) part of the pair-only-C4 fiber.

The companion instrument to f5_pair_only_fiber.py: that script scores the fiber
through a per-slot decomposition, so the two maximal vectors are re-scored here by
reconstructing each full 64-hexagram sequence and calling public solve.py
vdb_nucorient on it directly -- plus permutation, C5 boundary-distance-multiset and
C3 = 776 checks on each. Named verify30.py in the private original.

Attribution: Claude (Opus, Anthropic), 2026-07-26. Errors are mine; corrections
invited. Published 2026-09-04 with f5_pair_only_fiber.py.

Usage: cd reports/evidence/f5 && python3 f5_pair_only_verify30.py > f5_pair_only_verify30.out
"""
import os, sys
from collections import Counter
HERE = os.path.dirname(os.path.abspath(__file__))
# Public-bundle portability edit (2026-09-04): repo root located relative to this
# file (reports/evidence/f5/ -> repo root) instead of the original machine-absolute
# path. See README.md in this directory for the full list of edits vs the archived
# private original -- the byte-identical rerun recorded there was performed with
# this published copy.
sys.path.insert(0, os.path.abspath(os.path.join(HERE, "..", "..", "..")))
sys.path.insert(0, HERE)
from solve import binary_hexagrams, vdb_nucorient
_gt_src = open(os.path.join(HERE, "f5_ground_truth.py")).read()
_gt_ns = {"__file__": os.path.join(HERE, "f5_ground_truth.py")}
exec(_gt_src.split("\nif len(sys.argv)")[0], _gt_ns)
f5_all = _gt_ns["f5_all"]

hw = lambda h: bin(h).count("1")
d = lambda a, b: hw(a ^ b)
SEQ = list(binary_hexagrams)
MEM = [(SEQ[2*k], SEQ[2*k+1]) for k in range(32)]
first = lambda k,o: MEM[k][o]; second = lambda k,o: MEM[k][1-o]
DT = [[[d(second(b,oa), first(b+1,ob)) for ob in (0,1)] for oa in (0,1)] for b in range(31)]
from functools import lru_cache
DVALS=(1,2,3,4,6); DIDX={v:i for i,v in enumerate(DVALS)}
TARGET=(2,8,13,7,1)
@lru_cache(maxsize=None)
def feas(k,o,counts):
    if k==31: return not any(counts)
    for o2 in (0,1):
        i=DIDX.get(DT[k][o][o2])
        if i is None or counts[i]==0: continue
        nc=counts[:i]+(counts[i]-1,)+counts[i+1:]
        if feas(k+1,o2,nc): return True
    return False
def enum(o0):
    out=[]; stack=[(0,o0,TARGET,o0)]
    while stack:
        k,o,counts,bits=stack.pop()
        if k==31: out.append(bits); continue
        for o2 in (0,1):
            i=DIDX.get(DT[k][o][o2])
            if i is None or counts[i]==0: continue
            nc=counts[:i]+(counts[i]-1,)+counts[i+1:]
            if feas(k+1,o2,nc): stack.append((k+1,o2,nc,bits|(o2<<(k+1))))
    return out
def build(bits):
    s=[]
    for k in range(32):
        o=(bits>>k)&1; s+=[first(k,o), second(k,o)]
    return s
full_mult = Counter(d(SEQ[i],SEQ[i+1]) for i in range(63))
def c3sum(s):
    pos={h:i for i,h in enumerate(s)}
    return sum(abs(pos[h]-pos[h^63]) for h in range(64))
hits=[]
for bits in enum(1):
    s=build(bits)
    v=vdb_nucorient(s)
    if v>=30: hits.append((bits,v,s))
print(f"reversed-part vectors with direct vdb_nucorient >= 30: {len(hits)}")
for bits,v,s in hits:
    ok_perm = sorted(s)==list(range(64))
    ok_c5 = Counter(d(s[i],s[i+1]) for i in range(63))==full_mult
    ok_c3 = c3sum(s)==776
    print(f"bits={bits:#010x} popcount={bin(bits).count('1')} vdb={v} "
          f"perm={ok_perm} c5={ok_c5} c3776={ok_c3} opens=({s[0]},{s[1]})")
    print("  f5_all:", f5_all(s))
    print("  seq:", s)
# also confirm none in forward part reaches 30 by direct scoring of >=29 candidates found via decomposition is skipped; forward max already published =29
