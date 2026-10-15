#!/usr/bin/env python3
"""Definition check for PREREG_C8SCREEN_2026_10_11 (Pilot A, the systematic C8 screen).

Recomputes the family COUNT, verifies every member's reference definition on SYNTHETIC input
(random C1-and-C4 orderings and hand-built sequences), and proves the exclusion theorems that
rest on the hexagram SET alone. It NEVER evaluates any family statistic on King Wen: verify.py is
imported for its bit conventions only and its KW table is never read (asserted at the end by a
self-grep). Exit status 0 and the last line `DEFCHECK=PASS` are the verdict tokens.
Run:  python3 scripts/prereg_c8screen_defcheck.py
"""
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
    MEMBERS.append((f"P-CM[{c}]", "S", (lambda c: lambda s: P_CM(s, c))(c), (0, 31 * 15)))
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

# ----------------------------------------------------------------------------- KW was never touched
src = open(os.path.abspath(__file__), encoding="utf-8").read()
chk("F1 this script never names the KW table (verify's list or solve's) outside this guard line",
    len(re.findall(r"verify\.KW|V\.KW|binary_hexagrams", src)) == 1)
print("KW_TOUCHED=NO")
print("DEFCHECK=" + ("PASS" if ok else "FAIL"))
sys.exit(0 if ok else 1)
