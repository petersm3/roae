# F11 pre-registered Bayes analysis — M_corr edit-event geometry (RUN D).
# Enumerates ALL bamboo-slat edit events of slot-footprint size k = 1..6 around the received
# sequence (King Wen) and around the SAT grand-strict witness, classifying each event's outcome.
#
# Model (frozen, F11_BAYES_PREREGISTRATION_2026_07.md): M_corr = uniform draw from the
# grand-strict set x corruption of k slot-edits, k ~ geometric(p_c), edit location uniform
# (variant U) or bamboo-adjacent-biased (variant A). Elementary physical ops (Rutt 1996
# bamboo-slat mechanism, via Hacker & Moore 2003): adjacent-slat transposition (swap of
# slots s,s+1) and slat inversion (orientation flip of one slot), with optional inversion
# of displaced slats. Slot-edit distance = # slots whose (pair, orientation) differs
# (identical to sat.py's near-k metric). Slot 0 (pair 0 = 63,0) is fixed by canonical form.
#
# Rule ATTRIBUTION: Moore 2005 (Oracle Papers No.1) pair-positioning parity; Moore 1989
# (The Trigrams of Han, App.2) rising/falling rhythm; Schulz 1990 (JCP 17:3) gender/
# position-parity (exception noted by Zhu Yuansheng, 13th c.), elaborated Cook 2006.
# Developed with AI assistance (Claude, Anthropic).
import json, sys
from collections import Counter
from itertools import combinations
import solve

KW = list(solve.binary_hexagrams)
PAIRS = [(KW[2*i], KW[2*i+1]) for i in range(32)]
TOT = Counter(solve.bit_diff(KW[i], KW[i+1]) for i in range(63))

# grand-strict witness (SAT, 2026-07-03; LITERATURE_RULES_POPULATION_TESTS.md result 6)
GRAND = [63,0,17,34,23,58,2,16,55,59,7,56,61,47,8,4,25,38,3,48,41,37,32,1,57,39,33,30,
         18,45,28,14,60,15,40,5,53,43,20,10,35,49,24,6,62,31,26,22,29,46,9,36,52,11,
         13,44,54,27,50,19,51,12,21,42]

def pc(h): return bin(h).count("1")

def parity_viol(seq):
    """Moore 2005: eligible pairs (non-complement, popcount!=3) whose yang/yin
    preponderance mismatches 1-indexed position parity. KW = 2."""
    v = 0
    for q in range(32):
        h, h2 = seq[2*q], seq[2*q+1]
        if h ^ h2 == 63: continue
        p = pc(h)
        if p == 3: continue
        if (p > 3) != bool((q + 1) & 1): v += 1
    return v

def rhythm_breaks(seq):
    """Moore 1989: rising/falling alternation breaks among adjacent directional pairs. KW = 2."""
    prev = 0; have = 0; prev_adj = 0; br = 0
    for q in range(32):
        h, h2 = seq[2*q], seq[2*q+1]
        if h ^ h2 == 63: prev_adj = 0; continue
        p = pc(h)
        if p == 3: prev_adj = 0; continue
        mb = 0 if p > 3 else 1
        sc = sum((5 - 2*i) for i in range(6) if ((h >> i) & 1) == mb)
        rf = 1 if sc > 0 else 0
        if have and prev_adj and rf == prev: br += 1
        prev = rf; have = 1; prev_adj = 1
    return br

def valid_c3(seq):
    """C1 is structural under slot edits; check C2 (no five-line transitions),
    C5 (transition multiset preserved) and C3 (<= 776)."""
    if not solve.has_no_five(seq): return False
    if Counter(solve.bit_diff(seq[i], seq[i+1]) for i in range(63)) != TOT: return False
    pos = {h: i for i, h in enumerate(seq)}
    return sum(abs(pos[h] - pos[h ^ 63]) for h in range(64)) <= 776

def grand_ok(seq):
    return (parity_viol(seq) == 0 and rhythm_breaks(seq) == 0
            and solve.rc4_violations(seq)[0] == 0)

# ---- ground-truth gates (fail loudly before any enumeration is trusted) ----
assert parity_viol(KW) == 2, "KW parity ground truth broke"
assert rhythm_breaks(KW) == 2, "KW rhythm ground truth broke"
assert solve.rc4_violations(KW) == (2, [25, 26]), "KW gender ground truth broke"
assert valid_c3(KW), "KW validity ground truth broke"
assert valid_c3(GRAND) and grand_ok(GRAND), "grand witness ground truth broke"

def to_base(seq):
    """Express seq as (slotpair, flipset) relative to KW pair inventory."""
    idx = {}
    for i, (a, b) in enumerate(PAIRS):
        idx[(a, b)] = (i, 0); idx[(b, a)] = (i, 1)
    sp = [0]*32; fl = set()
    for s in range(32):
        i, o = idx[(seq[2*s], seq[2*s+1])]
        sp[s] = i
        if o: fl.add(s)
    return sp, fl

KW_BASE = (list(range(32)), set())
GRAND_BASE = to_base(GRAND)
gd = sum(1 for s in range(32) if (GRAND_BASE[0][s], s in GRAND_BASE[1]) != (s, False))
assert gd == 3, "grand witness slot-distance from KW != 3 (%d)" % gd

def build(sp, fl):
    seq = []
    for s in range(32):
        a, b = PAIRS[sp[s]]
        seq += ([b, a] if s in fl else [a, b])
    return seq

def apply_event(base, swaps, flips):
    """Apply swap set (adjacent transpositions, disjoint) + flip set to base (sp0, fl0)."""
    sp0, fl0 = base
    sig = list(range(32))
    for s in swaps:
        sig[s], sig[s+1] = sig[s+1], sig[s]
    sp = [sp0[sig[s]] for s in range(32)]
    fl = set()
    for s in range(32):
        if (sig[s] in fl0) != (s in flips): fl.add(s)
    return sp, fl

def blocks(fp):
    fp = sorted(fp)
    return 1 + sum(1 for i in range(1, len(fp)) if fp[i] != fp[i-1] + 1)

def swap_sets(max_n):
    """All disjoint sets of adjacent transpositions s in 1..30 (slot 0 fixed), size <= max_n."""
    out = [[]]
    singles = list(range(1, 31))
    for n in range(1, max_n + 1):
        for c in combinations(singles, n):
            if all(c[i+1] - c[i] >= 2 for i in range(n - 1)):
                out.append(list(c))
    return out

KMAX = 6
SLOTS = set(range(1, 32))
results = {}
for name, base in (("KW", KW_BASE), ("GRAND", GRAND_BASE)):
    per_k = {k: {"events": 0, "valid": 0, "hits": [],
                 "zA": 0.0, "zA_valid": 0.0, "zA_hits": 0.0} for k in range(1, KMAX + 1)}
    for swaps in swap_sets(KMAX // 2):
        moved = set()
        for s in swaps: moved |= {s, s + 1}
        m2 = len(moved)
        if m2 > KMAX: continue
        free = sorted(SLOTS - moved)
        # decorations: flips on moved slots (footprint unchanged)
        decs = [set(c) for r in range(m2 + 1) for c in combinations(sorted(moved), r)]
        for next_flips in range(0, KMAX - m2 + 1):
            k = m2 + next_flips
            if k < 1: continue
            for ext in combinations(free, next_flips):
                fpb = blocks(moved | set(ext))
                wA = 2.0 ** (-fpb)
                for dec in decs:
                    flips = dec | set(ext)
                    per_k[k]["events"] += 1
                    per_k[k]["zA"] += wA
                    sp, fl = apply_event(base, swaps, flips)
                    seq = build(sp, fl)
                    if not valid_c3(seq): continue
                    per_k[k]["valid"] += 1
                    per_k[k]["zA_valid"] += wA
                    if grand_ok(seq):
                        per_k[k]["hits"].append({"swaps": list(swaps),
                                                 "flips": sorted(flips),
                                                 "blocks": fpb})
                        per_k[k]["zA_hits"] += wA
    results[name] = per_k

json.dump(results, open("f11_events.json", "w"), indent=1)
for name in results:
    for k in range(1, KMAX + 1):
        r = results[name][k]
        print("base=%s k=%d events=%d valid=%d hits=%d zA=%.6f zA_valid=%.6f zA_hits=%.8g"
              % (name, k, r["events"], r["valid"], len(r["hits"]), r["zA"],
                 r["zA_valid"], r["zA_hits"]))
print("F11_EVENTS_DONE")
