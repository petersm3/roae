import sys
sys.path.insert(0, __import__('os').path.join(__import__('os').path.dirname(__file__), '..', '..', '..'))
import solve
KW = list(solve.binary_hexagrams)
PAIRS = [(KW[2*i], KW[2*i+1]) for i in range(32)]
# oriented pair objects: (pair_idx, orient) -> (entry_hex, exit_hex); pair 0 fixed, 62 free orienteds
ORI = [(p, o, (PAIRS[p][1] if o else PAIRS[p][0]), (PAIRS[p][0] if o else PAIRS[p][1]))
       for p in range(1, 32) for o in (0, 1)]
def d(a, b): return bin(a ^ b).count("1")
# initial partition: by (within-distance, entry-popcount, exit-popcount) then refine by transition profile
# transition allowed exit->entry iff d != 5 (C2); profile = multiset of (target-class, allowed?) per class
def refine(classes):
    while True:
        idx = {}
        for ci, cl in enumerate(classes):
            for m in cl: idx[m] = ci
        sig = {}
        for m in ORI:
            p, o, e_in, e_out = m
            # profile: for each class, how many members of that class (excluding same pair) are reachable (d!=5)
            prof = []
            for cl in classes:
                cnt = sum(1 for (p2, o2, f2, s2) in cl if p2 != p and d(e_out, f2) != 5)
                rcv = sum(1 for (p2, o2, f2, s2) in cl if p2 != p and d(s2, e_in) != 5)
                prof.append((cnt, rcv))
            sig[m] = (idx[m], tuple(prof))
        groups = {}
        for m in ORI: groups.setdefault(sig[m], []).append(m)
        new = list(groups.values())
        if len(new) == len(classes): return new
        classes = new
# start: single class
classes = refine([list(ORI)])
print("stable partition classes:", len(classes))
from collections import Counter
print("class sizes:", sorted(Counter(len(c) for c in classes).items()))
