#!/usr/bin/env python3
"""Definition check for PREREG_C8SCREEN_2026_10_11 -- AMENDMENT 1 (2026-10-11, §9-A1..A4; PREREG_C8SCREEN_AMENDMENT_1_2026_10_11.md).
Identical to the frozen defcheck (sha256 bb017ec5...) on lines 1-163 except line 147, where the four P-CM declared
ranges become (0, 496) = the universal bound sum(1..31) (A1); the normative extract ranges 11,15-25,37-52,55,57-59,
83-158,163 therefore stay valid. Appended blocks G (A1: exact N0 law of P-CM[odd], the breach of 465 as a positive
control, every declared range re-derived as a universal bound, the new MEMBER_LIST_SHA256) and H (A2: the DEFINED
rule for corpus controls, checked on Fu Xi and on a synthetic non-C1 permutation; cardinalities only) follow E11.
It NEVER evaluates any family statistic on King Wen: verify.py is imported for its bit conventions only and its KW
table is never read (asserted at the end by a self-grep). Exit 0 and the last line `DEFCHECK=PASS` are the verdict.
Run:  python3 scripts/prereg_c8screen_defcheck_a1.py"""
import sys, random, hashlib, itertools, re, os
sys.path.insert(0, "/home/claude/github/roae/roae")
import verify as V                     # bit conventions only (_zong/_cuo); KW never indexed

# ----------------------------------------------------------------------------- conventions (§2)
def rev(h):  return int(format(h, '06b')[::-1], 2)        # 綜 reversal, == verify._zong
def comp(h): return h ^ 63                                 # 錯 complement, == verify._cuo
def partner(h):
    r = rev(h); return r if r != h else comp(h)
def y(h):    return bin(h).count('1')                      # yang count
def L(h):    return h & 7                                  # lower trigram (bits 0..2)
def U(h):    return (h >> 3) & 7                           # upper trigram (bits 3..5)
def rev3(t): return ((t & 1) << 2) | (t & 2) | (t >> 2)    # 3-bit reversal
PAIRS = sorted({frozenset((h, partner(h))) for h in range(64)}, key=min)   # 32 C1 pairs, from partner() only
PAL   = frozenset(h for h in range(64) if rev(h) == h)                     # the 8 palindromes

ok = True
def chk(label, cond, detail=""):
    global ok; ok &= bool(cond)
    print(("PASS " if cond else "FAIL ") + label + ("  " + detail if detail else ""))

chk("A1 rev/comp agree with verify._zong/_cuo on all 64", all(rev(h) == V._zong(h) and comp(h) == V._cuo(h) for h in range(64)))
chk("A2 32 C1 pairs; 8 pairs have XOR product 63 (4 palindromic comp pairs + 4 anti-palindromic rev pairs); (0,63) is one", len(PAIRS) == 32 and sum(1 for p in PAIRS if max(p) == min(p) ^ 63) == 8 and frozenset((0, 63)) in PAIRS)
chk("A3 PAL = span{12,18,33} is an XOR subgroup of order 8 containing 0 and 63", len(PAL) == 8 and all((a ^ b) in PAL for a in PAL for b in PAL) and {0, 63} <= PAL)
chk("A4 h XOR partner(h) in PAL for all h (pair XOR products are palindromes)", all((h ^ partner(h)) in PAL for h in range(64)))

# ----------------------------------------------------------------------------- the 651 subgroups (§2.3)
def rref_subspaces(n=6, k=4):
    """All k-dim subspaces of F_2^n via reduced row echelon form: choose pivot columns (C(n,k)),
    free entries right of each pivot in non-pivot columns. Bijective with the Grassmannian."""
    out = []
    for piv in itertools.combinations(range(n), k):
        free = [(r, c) for r, p in enumerate(piv) for c in range(p + 1, n) if c not in piv]
        for bits in range(1 << len(free)):
            rows = [1 << (n - 1 - p) for p in piv]            # column c <-> bit (n-1-c): column 0 = MSB
            for i, (r, c) in enumerate(free):
                if (bits >> i) & 1: rows[r] |= 1 << (n - 1 - c)
            elems = {0}
            for v in rows: elems |= {e ^ v for e in elems}
            out.append(tuple(sorted(elems)))
    return out
SUBS = sorted(rref_subspaces())
chk("B1 651 distinct order-16 XOR subgroups (Gaussian binomial [6,2]_2 = 63*31/3 = 651)", len(SUBS) == 651 == len(set(SUBS)) == (63 * 31) // 3)
chk("B2 every listed set is closed under XOR, has 16 elements, contains 0", all(len(S) == 16 and 0 in S and all((a ^ b) in set(S) for a in S for b in S) for S in SUBS))
LIST_SHA = hashlib.sha256("\n".join(",".join(map(str, S)) for S in SUBS).encode()).hexdigest()
print("SUBGROUP_LIST_SHA256=" + LIST_SHA)
HP  = [i for i, S in enumerate(SUBS) if PAL <= set(S)]                     # PAL-containing: every pair lies in ONE coset (coset string well defined)
HPC = [i for i, S in enumerate(SUBS) if all(partner(h) in set(S) for h in S)]   # pair-closed: H is a union of 8 C1 pairs (C-M forced = 8)
H16 = tuple(sorted(h for h in range(64) if rev(h) == h or rev(h) == comp(h)))   # Ouyang 1993
chk("B3 exactly 7 subgroups contain PAL (= (64-8)/(16-8)); Ouyang's H16 is one of them", len(HP) == 7 and H16 in SUBS and SUBS.index(H16) in HP, "HP indices " + str(HP) + " H16 index " + str(SUBS.index(H16)))
chk("B4 for H containing PAL: a C1 pair is inside H or disjoint from H (C-M forced = 8 pairs)",
    all(all(((a in set(SUBS[i])) == (b in set(SUBS[i]))) for a, b in (tuple(p) for p in PAIRS)) and sum(1 for p in PAIRS if p <= set(SUBS[i])) == 8 for i in HP))
chk("B5 exactly 19 pair-closed subgroups (unions of 8 C1 pairs); the 7 PAL-containing ones are among them; the other 12 do not contain PAL",
    len(HPC) == 19 and set(HP) <= set(HPC), "HPC indices " + str(HPC))
chk("B6 for every H NOT pair-closed: some C1 pair has exactly one member in H (C-M is orientation-driven there)",
    all(any((a in set(SUBS[i])) != (b in set(SUBS[i])) for a, b in (tuple(p) for p in PAIRS)) for i in range(651) if i not in HPC))
chk("B7 for every pair-closed H, exactly 8 C1 pairs lie inside H",
    all(sum(1 for p in PAIRS if p <= set(SUBS[i])) == 8 for i in HPC))

# ----------------------------------------------------------------------------- SET facts behind the exclusions (§3)
WPD = sorted(y(a ^ b) for a, b in (tuple(p) for p in PAIRS))
chk("C1 within-pair distances form {2:12, 4:12, 6:8} (so the boundary-distance multiset is C1&C5-forced, TrigramTheorems.lean)", WPD.count(2) == 12 and WPD.count(4) == 12 and WPD.count(6) == 8)
TSIZE = {t: sum(1 for p in PAIRS if any(t in (L(h), U(h)) for h in p)) for t in range(8)}
chk("C2 the number of C1 pairs containing trigram t is a constant of the pair set (position-free trigram counts are forced)", all(v > 0 for v in TSIZE.values()), str(TSIZE))
PSUM = sorted(y(a) + y(b) for a, b in (tuple(p) for p in PAIRS))
chk("C3 pair yang-sum multiset is forced by C1", True, "{" + ", ".join(f"{v}:{PSUM.count(v)}" for v in sorted(set(PSUM))) + "}")
PURE = [p for p in PAIRS if all(L(h) == U(h) for h in p)]
chk("C4 exactly 4 pure (upper==lower) pairs; (0,63) is one", len(PURE) == 4 and frozenset((0, 63)) in PURE)
chk("C5 slot 1 is pinned by C4 and belongs to every H containing PAL (63 in PAL)", all(63 in SUBS[i] for i in HP))
# W (within-slot swap count) = 6 forced -- cited from PREREG_QOY1 §3.1 / the W=6 theorem; re-checked:
def swap(h): return (L(h) << 3) | U(h)
chk("C6 W = 6 forced: exactly 6 C1 pairs are swap pairs (Q-992 premise, cited not registered)", sum(1 for a, b in (tuple(p) for p in PAIRS) if swap(a) == b) == 6)

# ----------------------------------------------------------------------------- reference implementations (§2 code, normative)
def slots(s):     return [(s[2*k], s[2*k+1]) for k in range(32)]           # (entry e_k, exit x_k), k = 0..31 (1-based k+1 in prose)
def bwords(s):    return [s[2*b+1] ^ s[2*b+2] for b in range(31)]           # t_b = x_b XOR e_{b+1}, b = 0..30 (1-based b+1)
def circ_disp(K, n=32):                                                     # K: sorted 1-based positions on an n-cycle; sum of squared circular gaps
    g = [K[i+1] - K[i] for i in range(len(K)-1)] + [n + K[0] - K[-1]]
    return sum(x * x for x in g)
def lin_disp(K):                                                            # K: sorted positions on a line; sum of squared linear gaps
    return sum((K[i+1] - K[i]) ** 2 for i in range(len(K)-1))
def qoy_D(K):                                                               # K: 8 sorted 1-based slots; Q-OY1's D = sum (g-4)^2
    g = [K[i+1] - K[i] for i in range(7)] + [32 + K[0] - K[-1]]
    return sum((x - 4) ** 2 for x in g)

def C_N(s, H):  Hs = set(H); return sum(1 for t in bwords(s) if t in Hs)                       # boundary words in H
def C_M(s, H):  Hs = set(H); return sum(1 for e, x in slots(s) if e in Hs)                     # entry hexagrams in H
def C_D(s, H):  Hs = set(H); return qoy_D([k+1 for k, (e, x) in enumerate(slots(s)) if e in Hs and x in Hs])
def B_rel(s, which):
    n = 0
    for b in range(31):
        x, e = s[2*b+1], s[2*b+2]
        n += {"SL": L(x) == L(e), "SU": U(x) == U(e), "CL": L(x) == L(e) ^ 7, "CU": U(x) == U(e) ^ 7,
              "RL": L(e) == rev3(L(x)), "RU": U(e) == rev3(U(x)), "XL": L(e) == U(x), "XU": U(e) == L(x)}[which]
    return n
def P_set(s, c):
    d = [y(t) for t in bwords(s)]
    return [b+1 for b in range(31) if (d[b] % 2 == 1 if c == "odd" else d[b] == c)]
def P_CM(s, c):   return sum(P_set(s, c))
def P_DISP(s, c): return lin_disp(P_set(s, c))
def P_MAXRUN(s):                                                            # longest run of equal pair-parity class over slots 1..32
    par = [y(e) % 2 for e, x in slots(s)]
    best = cur = 1
    for k in range(1, 32):
        cur = cur + 1 if par[k] == par[k-1] else 1; best = max(best, cur)
    return best
def Y_AC(s):   return sum((y(s[2*b+1]) - 3) * (y(s[2*b+2]) - 3) for b in range(31))
def Y_TV(s):   return sum(abs(y(s[2*b+2]) - y(s[2*b+1])) for b in range(31))
def _sgn(v):   return (v > 3) - (v < 3)
def Y_RUNS(s):
    sg = [_sgn(y(h)) for h in s]; return 1 + sum(1 for i in range(63) if sg[i] != sg[i+1])
def Y_MAXRUN(s):
    sg = [_sgn(y(h)) for h in s]; best = cur = 1
    for i in range(1, 64):
        cur = cur + 1 if sg[i] == sg[i-1] else 1; best = max(best, cur)
    return best
def Y_set(s, v):  return [k+1 for k, (e, x) in enumerate(slots(s)) if y(e) + y(x) == v]
def Y_CM(s, v):   return sum(Y_set(s, v))
def Y_DISP(s, v): return circ_disp(Y_set(s, v))
def T_set(s, t):  return [k+1 for k, (e, x) in enumerate(slots(s)) if t in (L(e), U(e), L(x), U(x))]
def T_CM(s, t):   return sum(T_set(s, t))
def T_DISP(s, t): return circ_disp(T_set(s, t))
def PURE_set(s):  return [k+1 for k, (e, x) in enumerate(slots(s)) if L(e) == U(e)]
def T_CM_pure(s):   return sum(PURE_set(s))
def T_DISP_pure(s): return circ_disp(PURE_set(s))

# ----------------------------------------------------------------------------- the family, member by member (§2.4) and its COUNT
H16_IDX = SUBS.index(H16)
MEMBERS = []                                                                # (id, stratum, callable, (lo, hi) declared range)
for i, H in enumerate(SUBS):
    if i != H16_IDX:        MEMBERS.append((f"C-N[{i:03d}]", "C", (lambda H: lambda s: C_N(s, H))(H), (0, 31)))
    if i not in HPC:        MEMBERS.append((f"C-M[{i:03d}]", "C", (lambda H: lambda s: C_M(s, H))(H), (0, 32)))
    if i in HPC and i != H16_IDX: MEMBERS.append((f"C-D[{i:03d}]", "C", (lambda H: lambda s: C_D(s, H))(H), (0, 504)))
for w in ("SL", "SU", "CL", "CU", "RL", "RU", "XL", "XU"):
    MEMBERS.append((f"B-{w}", "S", (lambda w: lambda s: B_rel(s, w))(w), (0, 31)))
for c in (2, 3, 4, "odd"):
    MEMBERS.append((f"P-CM[{c}]", "S", (lambda c: lambda s: P_CM(s, c))(c), (0, 496)))   # A1: 496 = sum(1..31), universal; frozen 31*15 = 465 was N1-only
    MEMBERS.append((f"P-DISP[{c}]", "S", (lambda c: lambda s: P_DISP(s, c))(c), (0, 30 * 30)))
MEMBERS.append(("P-MAXRUN", "S", P_MAXRUN, (1, 32)))
MEMBERS += [("Y-AC", "S", Y_AC, (-279, 279)), ("Y-TV", "S", Y_TV, (0, 186)), ("Y-RUNS", "S", Y_RUNS, (1, 64)), ("Y-MAXRUN", "S", Y_MAXRUN, (1, 64))]
for v in (2, 4, 6, 8, 10):
    MEMBERS.append((f"Y-CM[{v}]", "S", (lambda v: lambda s: Y_CM(s, v))(v), (0, 528)))
    MEMBERS.append((f"Y-DISP[{v}]", "S", (lambda v: lambda s: Y_DISP(s, v))(v), (0, 1024)))
for t in range(8):
    MEMBERS.append((f"T-CM[{t}]", "S", (lambda t: lambda s: T_CM(s, t))(t), (0, 528)))
    MEMBERS.append((f"T-DISP[{t}]", "S", (lambda t: lambda s: T_DISP(s, t))(t), (0, 1024)))
MEMBERS += [("T-CM[pure]", "S", T_CM_pure, (0, 528)), ("T-DISP[pure]", "S", T_DISP_pure, (0, 1024))]
K_C = sum(1 for m in MEMBERS if m[1] == "C"); K_S = sum(1 for m in MEMBERS if m[1] == "S"); K = len(MEMBERS)
chk("D1 family count K = 1349 = K_C 1300 (650 C-N + 632 C-M + 18 C-D) + K_S 49 (8 B + 9 P + 14 Y + 18 T)",
    K == 1349 and K_C == 1300 and K_S == 49 and sum(m[0].startswith("C-N") for m in MEMBERS) == 650
    and sum(m[0].startswith("C-M") for m in MEMBERS) == 632 and sum(m[0].startswith("C-D") for m in MEMBERS) == 18)
chk("D2 member ids are unique", len({m[0] for m in MEMBERS}) == K)
MEMBER_SHA = hashlib.sha256("\n".join(f"{m[0]}\t{m[1]}\t{m[3][0]}\t{m[3][1]}" for m in MEMBERS).encode()).hexdigest()
print(f"FAMILY_K={K}\nFAMILY_K_C={K_C}\nFAMILY_K_S={K_S}\nMEMBER_LIST_SHA256={MEMBER_SHA}")
print("ALPHA=0.01\nALPHA_C=0.005\nALPHA_S=0.005\nBAR_C=%.6e\nBAR_S=%.6e" % (0.005 / K_C, 0.005 / K_S))

# ----------------------------------------------------------------------------- synthetic checks (random C1&C4 orderings; NEVER KW)
rng = random.Random(20261011)
others = [tuple(p) for p in PAIRS if p != frozenset((0, 63))]
def random_c1c4():
    rng.shuffle(others); s = [63, 0]
    for a, b in others: s += [b, a] if rng.random() < 0.5 else [a, b]
    return s
SAMP = [random_c1c4() for _ in range(300)]
chk("E1 every member stays inside its declared range on 300 random C1&C4 orderings",
    all(m[3][0] <= m[2](s) <= m[3][1] for s in SAMP for m in MEMBERS))
chk("E2 forced members are NOT in the family: C-M(H) == 8 on every sample for all 19 pair-closed H",
    all(C_M(s, SUBS[i]) == 8 for s in SAMP for i in HPC))
chk("E3 |T_t| and |S_v| are constant over the samples (position-free counts forced; CM/DISP are the positional members)",
    all(len(T_set(s, t)) == TSIZE[t] for s in SAMP for t in range(8)) and all(len(Y_set(s, v)) == PSUM.count(v) for s in SAMP for v in (2, 4, 6, 8, 10)) and all(len(PURE_set(s)) == 4 and PURE_set(s)[0] == 1 for s in SAMP))
chk("E4 sum identities: sum_v Y-CM[v] = 528; |B_2|,|B_3|,|B_4|,|B_odd| vary WITHOUT C5 (C5 is what fixes them; N0 does not impose it)",
    all(sum(Y_CM(s, v) for v in (2, 4, 6, 8, 10)) == 528 for s in SAMP) and len({len(P_set(s, "odd")) for s in SAMP}) > 1)
chk("E5 for H containing PAL, C-N(H) equals the coset-equality count of consecutive slots (QOY's NSAME definition) on every sample",
    all(C_N(s, SUBS[i]) == sum(1 for k in range(31) if ((s[2*k] ^ s[2*k+2]) in set(SUBS[i]))) for s in SAMP for i in HP))
chk("E6 C-D(H16) equals PREREG_QOY1's qoy1_D (coset-0 slot dispersion) on every sample",
    all(C_D(s, H16) == qoy_D([k+1 for k in range(32) if s[2*k] in set(H16)]) for s in SAMP))
chk("E7 B-XL and B-XU jointly: #{b: XL and XU} equals PREREG_QOY1's q992_X on every sample (X itself is measured and excluded)",
    all(sum(1 for b in range(31) if L(s[2*b+2]) == U(s[2*b+1]) and U(s[2*b+2]) == L(s[2*b+1])) == sum(swap(s[i]) == s[i+1] for i in range(1, 63, 2)) for s in SAMP))
chk("E8 no non-excluded member is constant over the samples (nothing registered is vacuous on N0)",
    all(len({m[2](s) for s in SAMP}) > 1 for m in MEMBERS), ",".join(m[0] for m in MEMBERS if len({m[2](s) for s in SAMP}) <= 1))
# E9 hand-built known answers on a designed sequence: pairs sorted by min element, min first (slot 1 = (63,0) forced)
DES = [63, 0] + [h for p in sorted(others) for h in p]
chk("E9 designed sequence is a C1&C4 ordering", all(DES[2*k+1] == partner(DES[2*k]) for k in range(32)) and DES[:2] == [63, 0] and sorted(DES) == list(range(64)))
chk("E10 known answers on the designed sequence: Y-RUNS/Y-MAXRUN/T-CM[pure]/T-DISP[pure] agree with an independent inline computation",
    Y_RUNS(DES) == 1 + sum(1 for i in range(63) if _sgn(y(DES[i])) != _sgn(y(DES[i+1])))
    and T_CM_pure(DES) == sum(k+1 for k in range(32) if DES[2*k] & 7 == DES[2*k] >> 3)
    and T_DISP_pure(DES) == circ_disp(sorted(k+1 for k in range(32) if DES[2*k] & 7 == DES[2*k] >> 3)))
# E11 mutant sensitivity: a single orientation flip changes C-M for some H not containing PAL, and C-N for some H
MUT = list(SAMP[0]); MUT[2], MUT[3] = MUT[3], MUT[2]
chk("E11 one orientation flip changes some C-M and some C-N value (members see orientation and boundary words)",
    any(C_M(SAMP[0], SUBS[i]) != C_M(MUT, SUBS[i]) for i in range(651) if i not in HP) and any(C_N(SAMP[0], SUBS[i]) != C_N(MUT, SUBS[i]) for i in range(651)))

# ----------------------------------------------------------------------------- AMENDMENT 1 (2026-10-11) A1: the P-CM declared ranges
# The frozen (0, 31*15) = 0..465 held only under C1&C5, where |B_c| is forced (8, 13, 7, 15 -> max P-CM = 360). N0 imposes
# no C5 (E4), and there P-CM[odd] reaches 496 = 1+...+31 (all 31 boundaries odd = perfect parity alternation of the slots).
from math import comb
PAIR_PAR = [y(min(p)) % 2 for p in PAIRS]                                   # rev preserves y; comp maps y to 6-y: parity is a PAIR property
chk("G1 pair parity is a pair property; 16 even and 16 odd pairs; the pinned pair (63,0) is even",
    all(y(a) % 2 == y(b) % 2 for a, b in (tuple(p) for p in PAIRS)) and PAIR_PAR.count(0) == 16 and PAIR_PAR.count(1) == 16 and y(63) % 2 == 0)
def pcm_odd_law_n0():
    """Exact N0 law of P-CM[odd] = sum of the odd-boundary indices. Under N0 the 31 free pairs are a uniform
    permutation, so the parity word of slots 2..32 is a uniformly random arrangement of 15 even and 16 odd; boundary b
    (joining slots b, b+1) is odd iff the parities differ. DP over (slot, parity, evens used, running sum)."""
    S = {(1, 0, 0, 0): 1}
    for slot in range(2, 33):
        T = {}
        for (i, par, ev, tot), c in S.items():
            for p in (0, 1):
                ev2 = ev + (p == 0)
                if ev2 > 15 or (slot - 1 - ev2) > 16: continue
                k = (slot, p, ev2, tot + (slot - 1 if p != par else 0)); T[k] = T.get(k, 0) + c
        S = T
    law = {}
    for (i, par, ev, tot), c in S.items():
        assert ev == 15; law[tot] = law.get(tot, 0) + c
    return law
LAW = pcm_odd_law_n0(); NLAW = sum(LAW.values())
chk("G2 exact N0 law of P-CM[odd]: C(31,15) arrangements; max 496 attained by exactly one; P(>465) = 684/300540195 (22.8 expected clamps in 1e7 draws); P(>496) = 0",
    NLAW == comb(31, 15) == 300540195 and max(LAW) == 496 and LAW[496] == 1
    and sum(c for v, c in LAW.items() if v > 465) == 684 and sum(c for v, c in LAW.items() if v > 496) == 0,
    "P_EXCEED_465=%.6e" % (684 / NLAW))
ALT = [63, 0]                                                                # G3: the alternating construction, odd/even/odd/... from slot 2
_odd = [tuple(p) for p, q in zip(PAIRS, PAIR_PAR) if q == 1]; _even = [tuple(p) for p, q in zip(PAIRS, PAIR_PAR) if q == 0 and p != frozenset((0, 63))]
for i in range(31): ALT += list(_odd[i // 2] if i % 2 == 0 else _even[i // 2])
chk("G3 POSITIVE CONTROL: a C1&C4 ordering (alternating parity) has P-CM[odd] = 496 > 465, so the frozen range IS breached by a legal N0 draw; no member exceeds 496 on 20000 random C1&C4 draws",
    all(ALT[2*k+1] == partner(ALT[2*k]) for k in range(32)) and sorted(ALT) == list(range(64)) and P_CM(ALT, "odd") == 496
    and all(P_CM(s, c) <= 496 for s in (random_c1c4() for _ in range(20000)) for c in (2, 3, 4, "odd")))
def _ham_path(c, budget=200000):                                              # G4: all 31 boundaries at distance c? (DFS, bounded)
    free = [tuple(sorted(p)) for p in PAIRS if p != frozenset((0, 63))]; found = []; n = [0]
    def dfs(x, used, path):
        n[0] += 1
        if n[0] > budget: return False
        if len(path) == 31: found.extend(path); return True
        for i, (a, b) in enumerate(free):
            if used >> i & 1: continue
            for e, xx in ((a, b), (b, a)):
                if y(x ^ e) == c and dfs(xx, used | (1 << i), path + [(e, xx)]): return True
        return False
    return [63, 0] + [h for e, x in found for h in (e, x)] if dfs(0, 0, []) else None
H3 = _ham_path(3)
chk("G4 P-CM[3] also attains 496: a C1&C4 ordering with all 31 boundaries at distance 3 exists (2 and 4: not searched to exhaustion, not claimed, not needed: 496 bounds them)",
    H3 is not None and all(y(t) == 3 for t in bwords(H3)) and P_CM(H3, 3) == 496)
def _bound(mid):                                                             # G5: the universal (sequence-independent) bound of each member class
    if mid.startswith(("C-N", "B-")):   return (0, 31)                       # a count over 31 boundaries
    if mid.startswith("C-M"):           return (0, 32)                       # a count over 32 slots
    if mid.startswith("C-D"):           return (0, 7 * 9 + 21 ** 2)          # 8 gaps >= 1 summing to 32: (1,..,1,25)
    if mid.startswith("P-CM"):          return (0, 31 * 32 // 2)             # a subset of {1..31} sums to <= 496
    if mid.startswith("P-DISP"):        return (0, 30 ** 2)                   # linear gaps sum to <= 30
    if mid == "P-MAXRUN":               return (1, 32)
    if mid == "Y-AC":                   return (-31 * 9, 31 * 9)
    if mid == "Y-TV":                   return (0, 31 * 6)
    if mid in ("Y-RUNS", "Y-MAXRUN"):   return (1, 64)
    if "-CM[" in mid:                   return (0, 32 * 33 // 2)             # a subset of {1..32} sums to <= 528
    if "-DISP[" in mid:                 return (0, 32 ** 2)                   # circular gaps sum to 32 (non-empty set)
    raise KeyError(mid)
chk("G5 every declared range equals the universal bound of its member class (no range is population-dependent any more)",
    all(m[3] == _bound(m[0]) for m in MEMBERS), ",".join(m[0] for m in MEMBERS if m[3] != _bound(m[0])))
FROZEN_PRE = "\n".join(f"{m[0]}\t{m[1]}\t{m[3][0]}\t{(465 if m[0].startswith('P-CM') else m[3][1])}" for m in MEMBERS)
chk("G6 the amended preimage differs from the frozen one in exactly the four P-CM rows: re-substituting 465 reproduces MEMBER_LIST_SHA256 = 486cac40...",
    hashlib.sha256(FROZEN_PRE.encode()).hexdigest() == "486cac40f85c1639bd4e05915541525e48b05a5097c589121ac28962a82db06c" and MEMBER_SHA != "486cac40f85c1639bd4e05915541525e48b05a5097c589121ac28962a82db06c"
    and sum(1 for a, b in zip(FROZEN_PRE.split("\n"), "\n".join(f"{m[0]}\t{m[1]}\t{m[3][0]}\t{m[3][1]}" for m in MEMBERS).split("\n")) if a != b) == 4)
print("MEMBER_LIST_SHA256_FROZEN=486cac40f85c1639bd4e05915541525e48b05a5097c589121ac28962a82db06c")
print("MEMBER_LIST_SHA256_AMENDED=" + MEMBER_SHA)

# ----------------------------------------------------------------------------- AMENDMENT 1 (2026-10-11) A2: corpus controls on non-C1 orderings
# §4.4 evaluates every member on three NON-C1 orderings. Count members are defined on any sequence of 64 distinct words.
# A positional member (CM / DISP / D of a slot or boundary set) is DEFINED on a control iff that set has the cardinality
# every N1 leaf forces (B7: |K_H| = 8; the C1&C5 theorem: |B_2|,|B_3|,|B_4|,|B_odd| = 8,13,7,15; C3: |S_v|; C2: |T_t|; C4:
# |S_pure| = 4); otherwise it is NA, and an NA control can never defeat §5.4(c). On every C1 input the rule is vacuous.
P_FORCED = {2: 8, 3: 13, 4: 7, "odd": 15}; Y_FORCED = {v: PSUM.count(v) for v in (2, 4, 6, 8, 10)}
def c8_defined(s, mid):
    m = re.match(r"^(C-D|P-CM|P-DISP|Y-CM|Y-DISP|T-CM|T-DISP)\[(\w+)\]$", mid)
    if not m: return True
    cls, arg = m.groups()
    if cls == "C-D":        Hs = set(SUBS[int(arg)]); return sum(1 for e, x in slots(s) if e in Hs and x in Hs) == 8
    if cls.startswith("P"): c = "odd" if arg == "odd" else int(arg); return len(P_set(s, c)) == P_FORCED[c]
    if cls.startswith("Y"): return len(Y_set(s, int(arg))) == Y_FORCED[int(arg)]
    if arg == "pure":       return len(PURE_set(s)) == 4
    return len(T_set(s, int(arg))) == TSIZE[int(arg)]
def c8_control_value(s, mid, fn):
    """The §4.4 value of member mid on a (possibly non-C1) sequence s: the frozen callable where DEFINED, else 'NA'."""
    return fn(s) if c8_defined(s, mid) else "NA"
chk("H1 on C1&C4 samples every positional set has its C1-forced cardinality except the class-P sets (C5-forced; N0 lacks C5): the DEFINED rule is total on every C1&C5 leaf and changes nothing for KW or N1",
    all(c8_defined(s, m[0]) for s in SAMP for m in MEMBERS if not m[0].startswith("P-")))
FUXI = list(range(64))                                                       # Fu Xi: s[i] = i (a formula, not a table)
FUXI_NA = [m[0] for m in MEMBERS if not c8_defined(FUXI, m[0])]
chk("H2 Fu Xi is not C1; every v_k is odd so all five S_v are empty; the rule marks exactly 49 members NA on it (15 C-D + all 8 P + all 10 Y-positional + 16 T-positional; T-*[pure] and C-D[083/115/127] are defined); the 1295 count members evaluate without raising",
    not all(FUXI[2*k+1] == partner(FUXI[2*k]) for k in range(32)) and all(len(Y_set(FUXI, v)) == 0 for v in (2, 4, 6, 8, 10))
    and len(FUXI_NA) == 49 and sum(x.startswith("C-D") for x in FUXI_NA) == 15 and "T-CM[pure]" not in FUXI_NA and "C-D[083]" not in FUXI_NA
    and all(isinstance(m[2](FUXI), int) for m in MEMBERS if c8_defined(FUXI, m[0])), "FUXI_NA=" + ",".join(FUXI_NA))
def _raises(fn, s):
    try: fn(s); return False
    except Exception: return True
chk("H3 POSITIVE CONTROL: the frozen callables themselves raise on Fu Xi for all five Y-DISP members (the undefinedness the scorer lane reported), which the DEFINED rule turns into NA rather than a number",
    all(_raises(m[2], FUXI) for m in MEMBERS if m[0].startswith("Y-DISP")) and all(c8_control_value(FUXI, m[0], m[2]) == "NA" for m in MEMBERS if m[0].startswith("Y-DISP")))
SYN = list(range(64)); rng.shuffle(SYN)                                      # a synthetic non-C1 permutation
chk("H4 on a synthetic random permutation (non-C1) the rule yields a value or NA for every member and never raises",
    all(c8_control_value(SYN, m[0], m[2]) == "NA" or isinstance(c8_control_value(SYN, m[0], m[2]), int) for m in MEMBERS))
print("AMENDMENT=1 (A1 ranges, A2 DEFINED rule; A3/A4 are analyze-side, see PREREG_C8SCREEN_AMENDMENT_1_2026_10_11.md)")

# ----------------------------------------------------------------------------- KW was never touched
src = open(os.path.abspath(__file__), encoding="utf-8").read()
chk("F1 this script never names the KW table (verify's list or solve's) outside this guard line",
    len(re.findall(r"verify\.KW|V\.KW|binary_hexagrams", src)) == 1)
print("KW_TOUCHED=NO")
print("DEFCHECK=" + ("PASS" if ok else "FAIL"))
sys.exit(0 if ok else 1)
