#!/usr/bin/env python3
"""free_moves.py: reproducer for the "Free moves" statement of README section 3 (n = 31 fibres).

Python 3, standard library only, one file.  Every leg prints whole-line KEY=value verdict tokens; a
leg that cannot run prints a token that is not PASS, and no leg is skipped silently.

THE STATEMENT CHECKED (the "Free moves" paragraph of README section 3).  For every fibre
Y = F(s., c) of the n = 31 space with King Wen's budget {1: 2, 2: 8, 3: 13, 4: 7, 6: 1} there are at
least 2^(26 - t) translations (moves of the group A+ below) that map Y onto itself, and each one
except the identity moves every walk.  With the free action of S3 on skeletons (Step 6) this gives
2^14 * 3 | N, every N(c) and every V2 cell by counting orbits.  No leg computes an N(c) directly:
that 2^14 * 3 divides each N(c) follows from the per-fibre statement and Step 6.  The proof is a
hand proof; this script checks its finite steps exhaustively and tests its conclusion on named
fibres.  It is not a proof and not a Lean formalisation.

MODEL (6-bit hexagrams, bit i = line i, line pair j = bits j and 5 - j).  support s(h) = the line
pairs with unequal lines; mate(h) = reversal, or complement for a palindrome; p(a) = the palindromic
mask that is 1 on both lines of each line pair in a.  A walk is the anchor pair {63, 0} (exit 0)
and 31 slots; slot k holds entry h_k and leaves by mate(h_k); the 32 pairs are used once each.
Boundary k (k = 0..30) joins slot k to slot k + 1; its class is the Hamming distance from the exit
of slot k to the entry of slot k + 1.  in_fibre() is this definition and nothing else; every direct
test goes through it.

THE MOVES (A+).  Bits o_k (31), v_s for the seven non-empty supports (21), w (1): 53 bits.
h_k -> h_k XOR p(a_k), a_k = o_k * s~_k + v_{s_k} + w * {0,1,2} * [k is a class-6 window slot],
s~ = s for s != 0 and {0,1,2} for s = 0.  On a full n = 31 skeleton 2^7 parameter choices give the
identity (kernel dimension 7); on the small universes of leg E the kernel is 3 per absent support
plus 1 per present non-empty support, so "kernel 7" is claimed only for a full n = 31 skeleton.

LEGS (run from anywhere; data files are looked for beside this script).
  L  local lemma, exhaustive, at the level of the parameters (o, v, w); the touching rows as
     three-slot statements; Fact 1, Fact 2, Fact 3 and Lemma 1 executed; the converse of the
     touching rows (condition not met => class changed); two controls that must fire.
     Enumeration (fixed here so that the counts are reproducible by a second implementation):
       generic rows: every ordered pair (e, h) of the 64 x 64 hexagrams in different pairs, every
         (a, b) in (F_2^3)^2 as the translations of the two sides; "cases" counts those meeting the
         row condition;
       anchor rows: e = 0, every h outside the anchor pair, every b in F_2^3;
       equal supports: every support, every ordered (e, h) of that support in different pairs,
         o_k = o_{k+1} in {0,1}, every v, w on both sides or neither; plus the anchor into support 0;
       Fact 3 / Lemma 1: every window (x, y) (class 6, different pairs), every ordered placement of
         the two remaining pairs (q, q2), every o in F_2^4, v, w;
       Lemma 1 on the two supports that cannot hold the window: support 0 (its three pairs besides
         the anchor, every ordered placement, every o in F_2^3; v_0 = 0) and support {0,1,2} (its
         four pairs, every ordered placement, every o in F_2^4, every v);
       touching rows: every window (x, y), every third hexagram z of the support outside the window
         pairs, both sides, every (o_z, o_window, v, w).
     Only "violations=0" and "control hits > 0" are the claim; the case counts describe this
     enumeration (another enumeration gives other counts).
  E  exhaustive test of the whole theorem on small COMPLETE universes (every support class present
     holds all its pairs): every walk listed from the definition, every fibre with exactly one
     class-6 and no class-5 boundary, every basis move of the proof's group applied to every walk.
     No layered count is used.  Default: universes {0,1}, {0,3} (7 slots) and {1,3} (8 slots)
     (supports written as 3-bit numbers); --full adds seven more (FULL_UNIVERSES below).
  S  self-test of the layered counting code (not of the theorem) against brute force on sampled
     small fibres: F, per-slot domains, every two-slot projection, |T_Y| and the joint count.
  T  per n = 31 fibre: F > 0 and, where a count is recorded, F = that count; witness walk in the
     fibre; conditions <= 20 + t; kernel 7; proof dimension >= 26 - t; exact translation
     stabiliser T_Y from the two-slot projections; proof's group inside T_Y; every T_Y basis
     vector keeps sampled walks inside; direct test of every basis move and one random group
     element on uniformly sampled walks; a negative control; on the t = 13 fibres with a touching
     boundary also the exact joint count |Y n (a + Y)| = |Y| for every basis move a, which does
     not use the projections.  The recorded counts are reported by origin: those of
     fibres_n31.tsv (made by other code) and those a generator wrote into the touching file.
     Default fibres: the recorded fibres with t = 13 or a touching boundary, and every fibre of
     fibres_n31_touching.tsv; --full runs all 52 recorded fibres (not part of the recorded runs:
     --full has not been run from these bytes).
  G  the five recorded fibres of exactly 2^20 * 3^7 walks: every slot-by-slot bijection of the
     fibre listed (column keys, arc consistency, depth-first listing), the number that are
     translations (= 2^dim T_Y), and exact orbit sizes of uniformly SAMPLED walks (the token says
     how many).
  A  the n = 31 atlas (atlas_n31.json, sha256 pinned): 2^14 * 3 divides N and every V2 cell; the V1
     statements of README section 1 item 3 (2^19 every cell; 2^21 for the pairs of two
     self-reverse hexagrams; 2^19 * 3 for the pair {7, 56}) and that the bounds are attained pair
     by pair; a mutated copy must fail.  The atlas holds aggregate counts: it can show consistency
     with the divisibility, not the free action.
  M  mutants and red tests: a wrong table, a broken generator, a non-free element, a dropped
     criterion, an altered recorded F or atlas cell must each turn its leg's verdict to FAIL.
     Before each mutant the same check runs unmutated on the same input and must PASS; a mutant
     whose precondition fails, whose input is missing or whose run raises is ERROR, not CAUGHT.

DATA FILES.  fibres_n31.tsv and fibres_n31_touching.tsv are pinned by sha256; a mismatch or a
missing file makes the final verdict FAIL.

usage:
  free_moves.py [--atlas PATH] [--legs L,E,S,T,G,A,M] [--full | --quick] [--seed N] [--walks N] [--gwalks N]
  --full    not part of the recorded runs (not yet run from these bytes); see leg T above.
  --quick   a documented short profile (a few minutes; tests.py does not run it, it runs legs L and A
            and the error paths only): legs L, E, S, A, M, and leg T on rows 1, 5 and 7
            of fibres_n31_touching.tsv and the recorded fibre check_climb303_1; no leg G (it prints
            FREE_MOVES_GROUP=SKIP_QUICK).  Its verdict is FREE_MOVES_QUICK=PASS; its final token
            stays FREE_MOVES=PARTIAL (it is not the full reproduction).
  free_moves.py --mutant NAME [--quick] [--legs ...]   run the legs with one mutation (its verdict
            must be FAIL; with --quick, on the quick fibres)
  free_moves.py --only-mutants NAME,... --legs M       leg M on a subset of mutants (control
            mutants such as "noop" are reachable only here)
  free_moves.py --list-mutants
Final token: FREE_MOVES=PASS only when every default leg ran and passed; with --legs a subset (or
--quick, or --only-mutants) gives FREE_MOVES=PARTIAL legs=...; any failure gives FREE_MOVES=FAIL
(exit 1).  A --mutant run never prints PARTIAL: FREE_MOVES=FAIL (exit 1) only when a leg the
mutation reaches (its target leg; for a table mutant also leg E) ran and failed and no other
selected leg failed; FREE_MOVES=ERROR (exit 2) if a data file is not as pinned or a leg the mutation
does not reach failed; otherwise FREE_MOVES=MUTANT_NOT_CAUGHT (exit 3).

Developed with AI assistance (Claude, Anthropic).
"""
import hashlib
import itertools
import json
import os
import random
import sys
import time
import traceback

HERE = os.path.dirname(os.path.abspath(__file__))
ATLAS_SHA256 = "9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558"
RECORDED_SHA256 = "9e56d2ae94683f72fee634933890cb8bed92adbfddb83601b72f5d6e90716c42"
TOUCHING_SHA256 = "384ee2d188b5521b1f08512720242a574f6f0e7d299f434b55e207d21d9d0536"
QUICK_TOUCHING_ROWS = (1, 5, 7)   # 1-based data rows: |s*| = 1 left; |s*| = 1 both sides; |s*| = 2
DECISIVE = ["check_climb303_1", "check_climb303_2", "check_climb303_3", "check_tmax202_5", "check_tmax202_6"]
KW_CLASS_MULTISET = sorted([1] * 2 + [2] * 8 + [3] * 13 + [4] * 7 + [6])

SAYPFX = [""]          # set to "[mutant] " while leg M re-runs a leg, so its lines are not tokens
def say(line): print(SAYPFX[0] + line, flush=True)

# ============================================================ model
def rev(h): return sum(((h >> i) & 1) << (5 - i) for i in range(6))
def supp(h): return sum((((h >> j) ^ (h >> (5 - j))) & 1) << j for j in range(3))
def pm(a): return sum(((1 << j) | (1 << (5 - j))) for j in range(3) if (a >> j) & 1)
def mate(h):
    r = rev(h)
    return r if r != h else h ^ 63
def pc(x): return bin(x).count("1")
def stil(s): return s if s else 7
def v2(x):
    x = abs(int(x))
    return (x & -x).bit_length() - 1
def vp(x, p):
    x = abs(int(x)); c = 0
    while x % p == 0: x //= p; c += 1
    return c

MATE = [mate(h) for h in range(64)]
SUPP = [supp(h) for h in range(64)]
PM = [pm(a) for a in range(8)]
UNPM = {PM[a]: a for a in range(8)}
_reps = sorted(set(min(h, MATE[h]) for h in range(64)))
PAIR = [_reps.index(min(h, MATE[h])) for h in range(64)]
ANCHOR_PAIR = PAIR[0]
BYSUP = [[h for h in range(64) if SUPP[h] == s] for s in range(8)]
DIST = [[pc(a ^ b) for b in range(64)] for a in range(64)]

def model_selfcheck():
    ok = len(_reps) == 32 and PAIR[63] == ANCHOR_PAIR and all(len(b) == 8 for b in BYSUP)
    ok = ok and all(MATE[h] == h ^ PM[stil(SUPP[h])] for h in range(64))
    ok = ok and all(SUPP[h ^ PM[a]] == SUPP[h] for h in range(64) for a in range(8))
    ok = ok and all(MATE[MATE[h]] == h and MATE[h] != h for h in range(64))
    return ok

# King Wen's hexagrams (bit 0 = bottom line), as in reports/evidence/q735_two_adic/q735_common.py.
KW_HEXAGRAMS = [
    0b111111, 0b000000, 0b010001, 0b100010, 0b010111, 0b111010, 0b000010, 0b010000,
    0b110111, 0b111011, 0b000111, 0b111000, 0b111101, 0b101111, 0b000100, 0b001000,
    0b011001, 0b100110, 0b000011, 0b110000, 0b101001, 0b100101, 0b100000, 0b000001,
    0b111001, 0b100111, 0b100001, 0b011110, 0b010010, 0b101101, 0b011100, 0b001110,
    0b111100, 0b001111, 0b101000, 0b000101, 0b110101, 0b101011, 0b010100, 0b001010,
    0b100011, 0b110001, 0b011111, 0b111110, 0b011000, 0b000110, 0b011010, 0b010110,
    0b011101, 0b101110, 0b001001, 0b100100, 0b110100, 0b001011, 0b001101, 0b101100,
    0b110110, 0b011011, 0b110010, 0b010011, 0b110011, 0b001100, 0b010101, 0b101010,
]
KW_PAIRS = [(KW_HEXAGRAMS[2 * i], KW_HEXAGRAMS[2 * i + 1]) for i in range(32)]

def in_fibre(walk, skel, cls):
    """The definition.  walk = entries h_1..h_n; anchor exit 000000."""
    n = len(skel)
    if len(walk) != n or len(cls) != n: return False
    seen = {ANCHOR_PAIR}
    ex = 0
    for k in range(n):
        h = walk[k]
        if not 0 <= h < 64: return False
        if SUPP[h] != skel[k] or DIST[ex][h] != cls[k] or PAIR[h] in seen: return False
        seen.add(PAIR[h])
        ex = MATE[h]
    return True

def translate(walk, a): return [h ^ PM[x] for h, x in zip(walk, a)]
def a_list(a, n): return [(a >> (3 * k)) & 7 for k in range(n)]
def pack6(a): return sum(PM[x] << (6 * k) for k, x in enumerate(a))

class Fibre:
    """Layered count over states (used-pair mask, entry hexagram); slots 1-based, k = 0 the anchor."""
    def __init__(self, skel, cls):
        self.skel, self.cls, self.n = list(skel), list(cls), len(skel)
    def succ(self, k, mask, h):
        ex = MATE[h] if k else 0
        c = self.cls[k]
        out = []
        for h2 in BYSUP[self.skel[k]]:
            if DIST[ex][h2] == c:
                b = 1 << PAIR[h2]
                if not mask & b: out.append((mask | b, h2))
        return out
    def forward(self):
        L = [{(1 << ANCHOR_PAIR, 63): 1}]
        for k in range(self.n):
            nxt = {}
            for (mask, h), cnt in L[-1].items():
                for st in self.succ(k, mask, h):
                    nxt[st] = nxt.get(st, 0) + cnt
            L.append(nxt)
        self.layers = L
        self.F = sum(L[-1].values())
        return self.F
    def backward(self):
        L = self.layers
        B = [None] * (self.n + 1)
        B[self.n] = {st: 1 for st in L[self.n]}
        for k in range(self.n - 1, -1, -1):
            nb = B[k + 1]
            B[k] = {st: sum(nb[s2] for s2 in self.succ(k, *st)) for st in L[k]}
        self.B = B
        if B[0][(1 << ANCHOR_PAIR, 63)] != self.F: raise RuntimeError("forward/backward counts disagree")
    def sample(self, rng):
        st = (1 << ANCHOR_PAIR, 63)
        w = []
        for k in range(self.n):
            ss = self.succ(k, *st)
            wts = [self.B[k + 1][s] for s in ss]
            r = rng.randrange(sum(wts))
            for s, x in zip(ss, wts):
                if r < x: break
                r -= x
            st = s
            w.append(st[1])
        return w
    def domains(self):
        """D[k] (k = 1..n): the entries that occur at slot k in some walk of the fibre."""
        D = [None]
        for k in range(1, self.n + 1):
            D.append(sorted({h for (m, h) in self.layers[k] if self.B[k][(m, h)]}))
        return D
    def projections(self, same_support=True):
        """Exact two-slot projections of Y for consecutive slots and (if same_support) for slots of
        equal support.  dict (k, l) -> set of (h_k, h_l), 1-based, k < l."""
        n, L, B = self.n, self.layers, self.B
        P = {}
        for k in range(1, n):
            R = set()
            for (mask, h) in L[k]:
                if B[k][(mask, h)]:
                    for st in self.succ(k, mask, h):
                        if B[k + 1][st]: R.add((h, st[1]))
            P[(k, k + 1)] = R
        if not same_support: return P
        for k in range(1, n + 1):
            later = [l for l in range(k + 1, n + 1) if self.skel[l - 1] == self.skel[k - 1]]
            if not later: continue
            idx = {h: i for i, h in enumerate(BYSUP[self.skel[k - 1]])}
            O = {st: 1 << idx[st[1]] for st in L[k] if B[k][st]}
            for l in range(k + 1, later[-1] + 1):
                O2 = {}
                Bl = B[l]
                for (mask, h), o in O.items():
                    for st in self.succ(l - 1, mask, h):
                        if Bl[st]: O2[st] = O2.get(st, 0) | o
                O = O2
                if l in later:
                    R = set()
                    hs = BYSUP[self.skel[k - 1]]
                    for (mask, h), o in O.items():
                        for i in range(8):
                            if (o >> i) & 1: R.add((hs[i], h))
                    if (k, l) in P and P[(k, l)] != R:
                        raise RuntimeError("consecutive projection differs when computed two ways")
                    P[(k, l)] = R
        return P
    def count_shift_inside(self, a):
        """Exact |{y in Y : y + a in Y}| by a joint layered count over pairs of walks (no projections)."""
        L = {(1 << ANCHOR_PAIR, 1 << ANCHOR_PAIR, 63): 1}
        for k in range(self.n):
            c = self.cls[k]; pa = PM[a[k - 1]] if k else 0; pb = PM[a[k]]
            nxt = {}
            for (m1, m2, h), cnt in L.items():
                ex = MATE[h] if k else 0
                ex2 = MATE[h ^ pa] if k else 0
                for h2 in BYSUP[self.skel[k]]:
                    if DIST[ex][h2] != c: continue
                    b = 1 << PAIR[h2]
                    if m1 & b: continue
                    g = h2 ^ pb
                    if DIST[ex2][g] != c: continue
                    b2 = 1 << PAIR[g]
                    if m2 & b2: continue
                    key = (m1 | b, m2 | b2, h2)
                    nxt[key] = nxt.get(key, 0) + cnt
            L = nxt
        return sum(L.values())

# ============================================================ F_2 linear algebra (vectors as ints)
def rref(rows):
    piv = {}
    for r in rows:
        while r:
            hb = r.bit_length() - 1
            if hb in piv: r ^= piv[hb]
            else: piv[hb] = r; break
    return piv
def rank(rows): return len(rref(rows))
def in_span(piv, v):
    while v:
        hb = v.bit_length() - 1
        if hb not in piv: return False
        v ^= piv[hb]
    return True
def nullspace(rows, n):
    """A basis of {x in F_2^n : <r, x> = 0 for every row r}."""
    piv = rref(rows)
    keys = sorted(piv)
    for i in keys:
        for j in keys:
            if j > i and (piv[j] >> i) & 1: piv[j] ^= piv[i]
    basis = []
    for f in (i for i in range(n) if i not in piv):
        x = 1 << f
        for p, r in piv.items():
            if (r >> f) & 1: x |= 1 << p
        basis.append(x)
    for b in basis:
        for r in rows:
            if pc(r & b) % 2: raise RuntimeError("nullspace basis fails an equation")
    return basis

def TY_equations(P):
    """Linear equations on a in F_2^(3n) (bit 3(k-1)+j = line pair j of slot k) cutting out the exact
    translation stabiliser T_Y: for each projection, the translations of its two slots fixing it."""
    eqs = []
    for (k, l), R in P.items():
        S = []
        for ab in range(64):
            a, b = PM[ab & 7], PM[ab >> 3]
            if all((h ^ a, g ^ b) in R for (h, g) in R): S.append(ab)
        Sset = set(S)
        if not all((x ^ y) in Sset for x in S for y in S): raise RuntimeError("stabiliser not a group")
        for f in range(1, 64):
            if all(pc(f & x) % 2 == 0 for x in S):
                eqs.append(((f & 7) << (3 * (k - 1))) | ((f >> 3) << (3 * (l - 1))))
    return eqs

# ============================================================ the proof's group (with mutants)
TABLE_MUTANTS = ["touch_free", "touch_swap_rules", "touch_as_ordinary", "class3_free", "six_free",
                 "class1_one", "internal_free", "anchor_free", "cross24_free"]

def tcount(skel, cls):
    return sum(1 for k in range(len(cls)) if cls[k] == 3 and pc((skel[k - 1] if k else 0) ^ skel[k]) == 1)

def proof_group(skel, cls, mut=None):
    """Conditions of Lemma 2 on the 53 (n + 22) parameters, the parameter map, its kernel, and a basis
    of the group of distinct moves.  Parameter bits: o_k = bit k-1; v_s line pair c = bit n+3(s-1)+c;
    w = bit n+21.  mut (one of TABLE_MUTANTS) weakens or alters one row of the table."""
    n = len(skel); NP = n + 22; W = n + 21
    six = [k for k in range(n) if cls[k] == 6]
    if len(six) != 1 or six[0] < 1: raise ValueError("not exactly one class-6 boundary between slots")
    j = six[0]                       # boundary j joins slots j and j+1
    sstar = skel[j - 1]
    if skel[j] != sstar or pc(sstar) not in (1, 2): raise ValueError("Fact 3 fails on this skeleton")
    inwin = lambda k: k in (j, j + 1)
    def aform(k, c):
        if k == 0: return 0
        s = skel[k - 1]; f = 0
        if (stil(s) >> c) & 1: f |= 1 << (k - 1)
        if s: f |= 1 << (n + 3 * (s - 1) + c)
        if inwin(k): f |= 1 << W
        return f
    conds = []; charged = 0; t = 0; ntouch = 0; wzero = False; applicable = False
    touch_side = set()
    for k in range(n):
        s = skel[k - 1] if k else 0; s2 = skel[k]; c = cls[k]
        d = pc(s ^ s2); m = [x for x in range(3) if not ((s ^ s2) >> x) & 1]
        dl = [aform(k, x) ^ aform(k + 1, x) for x in range(3)]
        if (c - d) % 2 or not 0 <= (c - d) // 2 <= 3 - d or c == 5:
            raise ValueError("class %d impossible between supports %d, %d" % (c, s, s2))
        if d == 3:
            pass
        elif d == 2:
            if mut == "cross24_free": applicable = True
            else: conds.append(dl[m[0]]); charged += 1
        elif d == 1:
            if c == 1:
                if mut == "class1_one": conds.append(dl[m[0]]); charged += 1; applicable = True
                else: conds += [dl[m[0]], dl[m[1]]]; charged += 2
            else:
                t += 1
                if mut == "class3_free": applicable = True
                else: conds.append(dl[m[0]] ^ dl[m[1]]); charged += 1
        else:
            if c not in (2, 4, 6): raise ValueError("internal boundary of class %d" % c)
            if k == 0:
                if mut == "anchor_free": applicable = True
                else: conds.append(1 << 0); charged += 1
            elif inwin(k) != inwin(k + 1):
                ntouch += 1
                touch_side.add("left" if k == j - 1 else "right")
                if s != sstar or c not in (2, 4): raise ValueError("touching boundary of unexpected kind")
                ordinary = (1 << (k - 1)) | (1 << k)
                r1 = ordinary | (1 << W); r2 = 1 << W
                right = r1 if pc(sstar) == 1 else r2
                wrong = r2 if pc(sstar) == 1 else r1
                if mut == "touch_free": applicable = True
                elif mut == "touch_swap_rules": conds.append(wrong); charged += 1; applicable = True
                elif mut == "touch_as_ordinary": conds.append(ordinary); charged += 1; applicable = True
                else:
                    conds.append(right)
                    if pc(sstar) == 1 or not wzero: charged += 1
                    if pc(sstar) == 2: wzero = True
            elif c == 6 and mut == "six_free":
                applicable = True
            elif c != 6 and mut == "internal_free":
                applicable = True
            else:
                conds.append((1 << (k - 1)) | (1 << k)); charged += 1
    amap = [aform(k, x) for k in range(1, n + 1) for x in range(3)]
    sol = nullspace(conds, NP)
    ker = nullspace(amap, NP)
    def to_a(p):
        a = 0
        for i, f in enumerate(amap):
            if pc(f & p) & 1: a |= 1 << i
        return a
    img = list(rref([to_a(p) for p in sol]).values())
    return dict(n=n, NP=NP, j=j, sstar=sstar, t=t, ntouch=ntouch, touch_side=touch_side, charged=charged,
                conds=conds, rank=rank(conds), kerdim=len(ker),
                ker_in_sol=all(pc(c & x) % 2 == 0 for c in conds for x in ker),
                img=img, gdim=rank(img), applicable=applicable)

# ============================================================ leg L: the local lemma
def leg_local(mut=None):
    """mut: None, 'local_touch_swap' (exchange the |s*| = 1 and |s*| = 2 touching rules) or
    'local_no_hyp' (drop the hypothesis that the neighbour holds neither window pair)."""
    st = dict(fact_viol=0, gen_cases=0, gen_viol=0, anc_cases=0, anc_viol=0, eq_cases=0, eq_viol=0,
              f3_cases=0, f3_viol=0, l1_cases=0, l1_viol=0, touch_cases=0, touch_viol=0, key_viol=0,
              conv_cases=0, conv_kept=0, six_cases=0, six_viol=0, ctl1_cases=0, ctl1_hits=0,
              ctl2_cases=0, ctl2_hits=0)
    def row_ok(d, c, m, dl):
        dm = dl & m
        if d == 3: return True
        if d == 2: return dm == 0
        if d == 1: return dm == 0 if c in (1, 5) else dm in (0, m)
        return dl == 0
    for e in range(64):
        for h in range(64):
            if PAIR[e] == PAIR[h]: continue
            s, s2 = SUPP[e], SUPP[h]; d = pc(s ^ s2); m = 7 & ~(s ^ s2); c = DIST[e][h]
            x = sum(1 << i for i in range(3) if (m >> i) & 1 and ((e ^ h) >> i) & 1)
            if c != d + 2 * pc(x): st["fact_viol"] += 1                       # Fact 1
            for a in range(8):
                for b in range(8):
                    dl = a ^ b; c2 = DIST[e ^ PM[a]][h ^ PM[b]]
                    if c2 != d + 2 * pc(x ^ (dl & m)): st["fact_viol"] += 1   # Fact 2
                    if row_ok(d, c, m, dl):
                        st["gen_cases"] += 1; st["gen_viol"] += c2 != c
                    if c == 3 and d == 1 and pc(dl) == 1 and dl & m:
                        st["ctl2_cases"] += 1; st["ctl2_hits"] += c2 != c
    for h in range(64):
        if PAIR[h] == ANCHOR_PAIR: continue
        d = pc(SUPP[h]); m = 7 & ~SUPP[h]; c = DIST[0][h]
        for b in range(8):
            if row_ok(d, c, m, b):
                st["anc_cases"] += 1; st["anc_viol"] += DIST[0][h ^ PM[b]] != c
    for s in range(8):
        for e in BYSUP[s]:
            for h in BYSUP[s]:
                if PAIR[e] == PAIR[h]: continue
                c = DIST[e][h]
                for o in (0, 1):
                    for v in range(8):
                        for wb in (0, 1):
                            a = (o * stil(s)) ^ v ^ (7 * wb)
                            st["eq_cases"] += 1; st["eq_viol"] += DIST[e ^ PM[a]][h ^ PM[a]] != c
        if s == 0:
            for h in BYSUP[0]:
                if PAIR[h] == ANCHOR_PAIR: continue
                st["eq_cases"] += 1      # anchor boundary into support 0 under o_1 = 0: delta = 0
                st["eq_viol"] += DIST[0][h] != DIST[0][h ^ PM[0]]
                st["eq_viol"] += DIST[0][h ^ PM[7]] == DIST[0][h]   # o_1 = 1 must break it
    # Fact 3 for supports 0 and {0,1,2}: no class-6 step between different pairs
    for s in (0, 7):
        st["f3_viol"] += sum(1 for x in BYSUP[s] for y in BYSUP[s] if DIST[MATE[x]][y] == 6 and PAIR[x] != PAIR[y])
    # Lemma 1 on supports 0 and {0,1,2} (no window there): every ordered placement of the support's
    # pairs (support 0: the three besides the anchor), every o, every v (v_0 = 0); the moved entries
    # stay in distinct pairs and never enter the anchor pair.
    for s in (0, 7):
        hs = [h for h in BYSUP[s] if PAIR[h] != ANCHOR_PAIR]
        npairs = len({PAIR[h] for h in hs})
        for ent in itertools.permutations(hs, npairs):
            if len({PAIR[h] for h in ent}) != npairs: continue
            for o in range(1 << npairs):
                for v in (range(8) if s else (0,)):
                    a = [(((o >> i) & 1) * stil(s)) ^ v for i in range(npairs)]
                    ps = [PAIR[ent[i] ^ PM[a[i]]] for i in range(npairs)]
                    st["l1_cases"] += 1; st["l1_cases_s%d" % s] = st.get("l1_cases_s%d" % s, 0) + 1
                    st["l1_viol"] += len(set(ps)) != npairs or ANCHOR_PAIR in ps
    for s in range(1, 7):
        hs = BYSUP[s]
        u = s if pc(s) == 2 else 7 ^ s
        win = [(x, y) for x in hs for y in hs if DIST[MATE[x]][y] == 6 and PAIR[x] != PAIR[y]]
        if not win: st["f3_viol"] += 1
        for (x, y) in win:
            if PAIR[y] != PAIR[x ^ 63] or PAIR[x] != PAIR[y ^ 63]: st["f3_viol"] += 1
            rest = [h for h in hs if PAIR[h] not in (PAIR[x], PAIR[y])]
            if len(rest) != 4: st["f3_viol"] += 1
            for q in rest:
                for q2 in rest:
                    if PAIR[q] == PAIR[q2]: continue
                    st["f3_cases"] += 1
                    if PAIR[q2] != PAIR[q ^ 63]: st["f3_viol"] += 1     # the other two hold Q and Q^c
                    ent = [x, y, q, q2]
                    for o in range(16):
                        for v in range(8):
                            for w in (0, 1):
                                a = [(((o >> i) & 1) * s) ^ v ^ (7 * w if i < 2 else 0) for i in range(4)]
                                st["l1_cases"] += 1
                                st["l1_viol"] += len({PAIR[ent[i] ^ PM[a[i]]] for i in range(4)}) != 4
            # the class-6 boundary itself: o_j = o_{j+1}, any v, w
            for o in (0, 1):
                for v in range(8):
                    for w in (0, 1):
                        a = (o * s) ^ v ^ (7 * w)
                        st["six_cases"] += 1; st["six_viol"] += DIST[MATE[x ^ PM[a]]][y ^ PM[a]] != 6
            for z in hs:
                for side in ("after", "before"):
                    e, h = (MATE[y], z) if side == "after" else (MATE[z], x)
                    holds_window_pair = PAIR[z] in (PAIR[x], PAIR[y])
                    if holds_window_pair:
                        if PAIR[e] != PAIR[h]:      # control 1: the hypothesis is needed
                            c = DIST[e][h]
                            for b in (0, 1):
                                for w in (0, 1):
                                    if not ((b == w) if pc(s) == 1 else (w == 0)): continue
                                    st["ctl1_cases"] += 1
                                    st["ctl1_hits"] += DIST[e][h ^ PM[(b * s) ^ (7 * w)]] != c
                        if mut != "local_no_hyp": continue
                        if PAIR[e] == PAIR[h]: continue
                    c = DIST[e][h]
                    xs = sum(1 << i for i in range(3) if ((e ^ h) >> i) & 1)
                    if not holds_window_pair and (c not in (2, 4) or pc(xs & u) != 1): st["key_viol"] += 1
                    for oz in (0, 1):
                        for ow in (0, 1):
                            for v in range(8):
                                for w in (0, 1):
                                    az = (oz * s) ^ v; aw = (ow * s) ^ v ^ (7 * w)
                                    if side == "after": e2, h2 = e ^ PM[aw], h ^ PM[az]
                                    else: e2, h2 = e ^ PM[az], h ^ PM[aw]
                                    one = pc(s) == 1
                                    if mut == "local_touch_swap": one = not one
                                    good = ((oz ^ ow) == w) if one else (w == 0)
                                    kept = DIST[e2][h2] == c
                                    if good:
                                        st["touch_cases"] += 1; st["touch_viol"] += not kept
                                    else:
                                        st["conv_cases"] += 1; st["conv_kept"] += kept
    viol = sum(st[k] for k in ("fact_viol", "gen_viol", "anc_viol", "eq_viol", "f3_viol", "l1_viol",
                               "touch_viol", "key_viol", "six_viol"))
    cases = sum(st[k] for k in ("gen_cases", "anc_cases", "eq_cases", "l1_cases", "touch_cases", "six_cases"))
    ok = (viol == 0 and st["conv_kept"] == 0 and st["ctl1_hits"] > 0 and st["ctl2_hits"] > 0
          and st["touch_cases"] > 0 and st["l1_cases"] > 0)
    say("LOCAL detail %s" % st)
    say("FREE_MOVES_LOCAL=%s cases=%d violations=%d converse_cases=%d converse_kept=%d control1_hits=%d control2_hits=%d"
          % ("PASS" if ok else "FAIL", cases, viol, st["conv_cases"], st["conv_kept"], st["ctl1_hits"], st["ctl2_hits"]))
    return ok

# ============================================================ legs E and S: small complete universes
DEFAULT_UNIVERSES = [(0, 1), (0, 3), (1, 3)]
FULL_UNIVERSES = DEFAULT_UNIVERSES + [(1, 2), (1, 6), (3, 5), (3, 4), (1, 7), (3, 7), (0, 7)]

def small_universe(U, rng, maxbrute, mut=None):
    pairs = sorted(set(PAIR[h] for s in U for h in BYSUP[s]) - {ANCHOR_PAIR})
    hexes = [h for s in U for h in BYSUP[s] if PAIR[h] != ANCHOR_PAIR]
    n = len(pairs)
    fib = {}
    sys.setrecursionlimit(10000)
    def dfs(k, ex, used, code, skel, cls, six):
        if k == n:
            if six == 1: fib.setdefault((skel, cls), []).append(code)
            return
        for h in hexes:
            b = 1 << PAIR[h]
            if used & b: continue
            c = DIST[ex][h]
            if c == 5 or (c == 6 and six): continue
            dfs(k + 1, MATE[h], used | b, code | (h << (6 * k)), skel + (SUPP[h],), cls + (c,), six + (c == 6))
    dfs(0, 0, 0, 0, (), (), 0)
    E = dict(walks=sum(len(v) for v in fib.values()), fibres=0, cond_ok=0, ker_ok=0, dim_ok=0, inside=0,
             moved=0, touching=0, touch2=0, win_first=0, win_last=0)
    S = dict(brute=0, defn_ok=0, F_ok=0, D_ok=0, P_ok=0, TY_ok=0, cnt_ok=0)
    keys = sorted(fib)
    brute_keys = set(rng.sample(keys, min(maxbrute, len(keys))))
    absent = sum(1 for s in range(1, 8) if s not in U)
    kexp = 3 * absent + sum(1 for s in U if s)
    for key in keys:
        skel, cls = list(key[0]), list(key[1])
        Y = fib[key]; Ys = set(Y)
        E["fibres"] += 1
        g = proof_group(skel, cls, mut)
        b = {c: cls.count(c) for c in (1, 2, 3, 4, 6)}
        budget = 2 * b[1] + b[2] + b[4] + b[6] + g["t"]
        E["cond_ok"] += g["charged"] <= budget
        E["ker_ok"] += g["kerdim"] == kexp and g["ker_in_sol"]
        E["dim_ok"] += g["gdim"] >= g["NP"] - budget - kexp
        E["touching"] += g["ntouch"] > 0; E["touch2"] += g["ntouch"] == 2
        E["win_first"] += g["j"] == 1; E["win_last"] += g["j"] == n - 1
        ok = True; mv = True
        for a in g["img"]:
            A = pack6(a_list(a, n))
            if A == 0: mv = False
            for y in Y:
                if (y ^ A) not in Ys: ok = False; break
            if not ok: break
        E["inside"] += ok; E["moved"] += mv
        if key in brute_keys and len(Y) <= 6000:
            S["brute"] += 1
            walks = [[(y >> (6 * k)) & 63 for k in range(n)] for y in Y]
            S["defn_ok"] += all(in_fibre(w, skel, cls) for w in walks)
            f = Fibre(skel, cls); F = f.forward(); f.backward()
            S["F_ok"] += F == len(Y)
            D = f.domains()
            S["D_ok"] += all(D[k] == sorted({w[k - 1] for w in walks}) for k in range(1, n + 1))
            P = f.projections()
            S["P_ok"] += all(R == {(w[k - 1], w[l - 1]) for w in walks} for (k, l), R in P.items())
            TY = nullspace(TY_equations(P), 3 * n)
            TYb = [y ^ Y[0] for y in Y if all((z ^ y ^ Y[0]) in Ys for z in Y)]
            tb = set(TYb)
            S["TY_ok"] += (1 << len(TY)) == len(TYb) and all(pack6(a_list(a, n)) in tb for a in TY)
            cok = True
            for _ in range(4):
                a = [rng.randrange(8) for _ in range(n)]
                if TY and rng.random() < 0.5: a = a_list(rng.choice(TY), n)
                A = pack6(a)
                cok &= f.count_shift_inside(a) == sum(1 for y in Y if (y ^ A) in Ys)
            S["cnt_ok"] += cok
    okE = (E["fibres"] > 0 or U == (0, 7)) and all(E[k] == E["fibres"] for k in ("cond_ok", "ker_ok", "dim_ok", "inside", "moved"))
    if U == (0, 7): okE = okE and E["fibres"] == 0       # Fact 3: no class-6 window in support 0 or {0,1,2}
    okS = all(S[k] == S["brute"] for k in ("defn_ok", "F_ok", "D_ok", "P_ok", "TY_ok", "cnt_ok"))
    say("SMALL universe %s slots %d kernel expected %d %s %s" % (U, n, kexp, E, S))
    return okE, okS, E, S

def leg_small(full, seed, mut=None):
    rng = random.Random(seed)
    tot = dict(universes=0, walks=0, fibres=0, touching=0, touch2=0, win_first=0, win_last=0)
    stot = dict(brute=0)
    okE = okS = True
    for U in (FULL_UNIVERSES if full else DEFAULT_UNIVERSES):
        e, s, E, S = small_universe(U, rng, 150 if len(U) and (U[0] == 0) else 120, mut)
        okE &= e; okS &= s
        tot["universes"] += 1
        for k in ("walks", "fibres", "touching", "touch2", "win_first", "win_last"): tot[k] += E[k]
        stot["brute"] += S["brute"]
    okE = okE and all(tot[k] > 0 for k in ("touching", "touch2", "win_first", "win_last"))
    okS = okS and stot["brute"] > 0
    print("FREE_MOVES_SMALL=%s universes=%d walks=%d fibres=%d touching=%d touching_twice=%d window_first=%d window_last=%d set=%s"
          % ("PASS" if okE else "FAIL", tot["universes"], tot["walks"], tot["fibres"], tot["touching"], tot["touch2"],
             tot["win_first"], tot["win_last"], "full" if full else "default"))
    print("FREE_MOVES_SELFTEST=%s brute_forced_fibres=%d" % ("PASS" if okS else "FAIL", stot["brute"]))
    return okE, okS

# ============================================================ leg T: n = 31 fibres
def read_tsv(path):
    """Columns: id, source, skeleton, classes, [witness,] F_recorded (empty = none)."""
    out = []
    for line in open(path):
        if not line.strip(): continue
        p = line.rstrip("\n").split("\t")
        if p[0] == "id": continue
        rec = dict(id=p[0], source=p[1], skel=[int(x) for x in p[2].split(",")],
                   cls=[int(x) for x in p[3].split(",")], wit=None, Frec=None)
        rest = p[4:]
        if len(rest) == 2:
            rec["wit"] = [int(x) for x in rest[0].split(",")] if rest[0] else None
            rec["Frec"] = int(rest[1]) if rest[1] else None
        elif len(rest) == 1:
            rec["Frec"] = int(rest[0]) if rest[0] else None
        out.append(rec)
    return out

def prep_fibre(rec, ns, rng, same_support=True):
    f = Fibre(rec["skel"], rec["cls"]); F = f.forward()
    if F == 0: return dict(F=0)
    f.backward()
    P = f.projections(same_support)
    eqs = TY_equations(P)
    TY = nullspace(eqs, 93)
    walks = [f.sample(rng) for _ in range(ns)]
    return dict(f=f, F=F, P=P, eqs=eqs, TY=TY, walks=walks)

def check_fibre(rec, ctx, rng, mut=None, joint=False, quiet=False):
    """All per-fibre checks of leg T; returns (ok, info)."""
    skel, cls = rec["skel"], rec["cls"]; n = 31
    R = dict(budget=len(skel) == 31 and sorted(cls) == KW_CLASS_MULTISET, nonempty=ctx["F"] > 0)
    if not R["nonempty"]: return False, dict(R=R)
    F, eqs, TY, walks, f = ctx["F"], ctx["eqs"], ctx["TY"], ctx["walks"], ctx["f"]
    Frec = rec["Frec"]
    if Frec is not None:
        if mut == "alter_F": Frec += 1 << 20
        R["F_recorded"] = F == Frec
    if rec["wit"] is not None:
        wit = list(rec["wit"])
        if mut == "bad_witness": wit[0] ^= 1
        R["witness"] = in_fibre(wit, skel, cls)
    R["samples_in_fibre"] = all(in_fibre(w, skel, cls) for w in walks)
    g = proof_group(skel, cls, mut if mut in TABLE_MUTANTS else None)
    t = g["t"]
    img = list(g["img"])
    piv = rref(TY)
    outside = [1 << i for i in range(93) if not in_span(piv, 1 << i)]
    if mut == "zero_generator": img.append(0)
    if mut == "outside_generator": img.append(rng.choice(outside))
    R["conditions"] = g["charged"] <= 20 + t
    R["kernel7"] = g["kerdim"] == 7 and g["ker_in_sol"]
    R["dimension"] = g["gdim"] >= 26 - t
    R["inside_TY"] = all(pc(e & a) % 2 == 0 for a in img for e in eqs)
    R["TY_sound"] = all(in_fibre(translate(w, a_list(a, n)), skel, cls) for a in TY for w in walks[:40])
    fail = 0
    for w in walks:
        moves = list(img)
        r = 0
        for a in g["img"]:
            if rng.random() < 0.5: r ^= a
        if r: moves.append(r)
        for a in moves:
            w2 = translate(w, a_list(a, n))
            if w2 == w or not in_fibre(w2, skel, cls): fail += 1
    R["direct"] = fail == 0
    u = rng.choice(outside)
    thrown = sum(1 for w in walks[:20] if not in_fibre(translate(w, a_list(u, n)), skel, cls))
    R["negative_control"] = thrown > 0
    j = g["j"]
    bare = (7 << (3 * (j - 1))) | (7 << (3 * j))
    bare_in = all(pc(e & bare) % 2 == 0 for e in eqs)
    nb = [cls[j - 1]] + ([cls[j + 1]] if j + 1 < 31 else [])
    R["bare_move_prediction"] = bare_in == all(c == 3 for c in nb)
    R["divides"] = F % (1 << g["gdim"]) == 0 and F % (1 << len(TY)) == 0
    jt = ""
    if joint:
        jf = sum(1 for a in img if f.count_shift_inside(a_list(a, n)) != F)
        cneg = f.count_shift_inside(a_list(u, n))
        R["joint"] = jf == 0
        R["joint_control"] = cneg < F
        jt = " | joint count |Y n (a+Y)| = |Y| for %d of %d basis moves; control keeps %d of %d" % (len(img) - jf, len(img), cneg, F)
    ok = all(R.values())
    info = dict(t=t, sstar=pc(g["sstar"]), j=j, ntouch=g["ntouch"], side=g["touch_side"], dTY=len(TY),
                gdim=g["gdim"], charged=g["charged"], F=F, applicable=g["applicable"], joint=joint)
    if not quiet:
        bad = [k for k, v in R.items() if not v]
        print("%s F=%d v2=%d t=%d |s*|=%d window %d,%d touching=%d%s charged=%d proof_dim=%d dim_TY=%d direct_walks=%d failures=%d control_thrown=%d/20%s | %s"
              % (rec["id"], F, v2(F), t, pc(g["sstar"]), j, j + 1, g["ntouch"],
                 ("(" + "+".join(sorted(g["touch_side"])) + ")") if g["ntouch"] else "", g["charged"], g["gdim"],
                 len(TY), len(walks), fail, thrown, jt, "OK" if ok else "FAILED " + ",".join(bad)), flush=True)
    return ok, info

def quick_touching(touching):
    return [touching[i - 1] for i in QUICK_TOUCHING_ROWS if i <= len(touching)]

def leg_fibres(recorded, touching, full, ns, seed, cache, quick=False):
    rng = random.Random(seed)
    sel_rec = []
    if quick:
        recorded = [r for r in recorded if r["id"] == "check_climb303_1"]
        touching = quick_touching(touching)
    for rec in recorded:
        t = tcount(rec["skel"], rec["cls"])
        g = proof_group(rec["skel"], rec["cls"])
        if full or t == 13 or g["ntouch"] > 0: sel_rec.append(rec)
    keep = set(DECISIVE) | {"check_climb303_1", "sixpair_T13_327"} | {r["id"] for r in touching[:10]}
    allok = True; S = dict(fibres=0, min_dTY=99, joint_fibres=0, t13_touch=0, attained=0)
    FR = dict(recorded_file=[0, 0], generator=[0, 0], none=0)   # origin -> [matched, carrying a count]
    cov = dict(s1=0, s2=0, left=0, right=0, both=0, win_first=0, win_last=0, dTY13=0, t=set(), wit=0, wit_ok=0)
    for group, recs in (("recorded", sel_rec), ("touching", touching)):
        for rec in recs:
            try:
                t1 = time.time()
                ctx = prep_fibre(rec, ns, rng)
                if rec["id"] in keep: cache[rec["id"]] = ctx   # only what legs G and M reuse (memory)
                gq = proof_group(rec["skel"], rec["cls"])
                joint = gq["t"] == 13 and gq["ntouch"] > 0
                ok, info = check_fibre(rec, ctx, rng, joint=joint)
                print("TIME fibre %s %.0f s" % (rec["id"], time.time() - t1), flush=True)
                del ctx
            except Exception as ex:
                print("%s ERROR %r" % (rec["id"], ex)); traceback.print_exc(); ok = False; info = None
            allok &= ok
            S["fibres"] += 1
            if info is None: continue
            S["min_dTY"] = min(S["min_dTY"], info["dTY"])
            S["joint_fibres"] += info["joint"]
            S["t13_touch"] += info["t"] == 13 and info["ntouch"] > 0
            S["attained"] += info["dTY"] == 26 - info["t"]
            if rec["Frec"] is None: FR["none"] += 1
            else:
                o = FR["recorded_file" if group == "recorded" else "generator"]
                o[0] += info["F"] == rec["Frec"]; o[1] += 1
            if group == "touching":
                cov["s1"] += info["sstar"] == 1; cov["s2"] += info["sstar"] == 2
                sd = info["side"]
                cov["left"] += sd == {"left"}; cov["right"] += sd == {"right"}; cov["both"] += sd == {"left", "right"}
                cov["win_first"] += info["j"] == 1; cov["win_last"] += info["j"] == 30
                cov["dTY13"] += info["dTY"] == 13; cov["t"].add(info["t"])
                cov["wit"] += rec["wit"] is not None
                cov["wit_ok"] += rec["wit"] is not None and in_fibre(rec["wit"], rec["skel"], rec["cls"])
    print("FREE_MOVES_BOUND=%s fibres=%d recorded=%d touching_file=%d min_dim_TY=%d attained=%d kernel=7 (full n=31 skeleton) set=%s"
          % ("PASS" if allok else "FAIL", S["fibres"], len(sel_rec), len(touching), S["min_dTY"], S["attained"],
             "full" if full else "quick" if quick else "default"))
    rf, gn = FR["recorded_file"], FR["generator"]
    frok = rf[0] == rf[1] > 0 and gn[0] == gn[1]
    print("FREE_MOVES_RECORDED_F=%s recorded_file=%d/%d generator=%d/%d no_count=%d"
          % ("PASS" if frok else "FAIL", rf[0], rf[1], gn[0], gn[1], FR["none"]))
    covok = (all(cov[k] > 0 for k in ("s1", "s2", "left", "right", "both", "win_first", "win_last", "dTY13"))
             and len(cov["t"]) >= 3 and cov["wit"] == cov["wit_ok"] == len(touching) > 0)
    witok = cov["wit"] == cov["wit_ok"] == len(touching) > 0
    if quick: covok = witok
    print("FREE_MOVES_TOUCHING=%s fibres=%d t13_touching=%d joint_fibres=%d witnesses=%d/%d" % (
        "PASS" if allok and covok else "FAIL", len(touching), S["t13_touch"], S["joint_fibres"], cov["wit_ok"], len(touching)))
    print("FREE_MOVES_TOUCHING_COVERAGE=%s s*1=%d s*2=%d left=%d right=%d both=%d window_slots_1_2=%d window_slots_30_31=%d dim_TY_13=%d t_values=%s"
          % ("SKIP_QUICK" if quick else "PASS" if covok else "FAIL", cov["s1"], cov["s2"], cov["left"], cov["right"], cov["both"], cov["win_first"],
             cov["win_last"], cov["dTY13"], ",".join(str(x) for x in sorted(cov["t"]))))
    return allok and covok and frok

# ============================================================ leg G: every slot-by-slot bijection
def perms_respecting(blocks, n):
    per_block = [list(itertools.permutations(b)) for b in blocks]
    for choice in itertools.product(*per_block):
        p = [0] * n
        for b, im in zip(blocks, choice):
            for x, y in zip(b, im): p[x] = y
        yield tuple(p)

def group_of_fibre(D, P, limit=1 << 22):
    """Every (sigma_k) with sigma_k in Sym(D_k) preserving every two-slot projection in P (consecutive
    and equal-support slots; this is the criterion for mapping Y onto Y)."""
    n = len(D) - 1
    idx = [None] + [{h: i for i, h in enumerate(D[k])} for k in range(1, n + 1)]
    nb = {k: [] for k in range(1, n + 1)}
    col = {}
    for (k, l), Sx in P.items():
        ckl = [0] * len(D[l]); clk = [0] * len(D[k])
        for (x, y) in Sx:
            ckl[idx[l][y]] |= 1 << idx[k][x]
            clk[idx[k][x]] |= 1 << idx[l][y]
        col[(k, l)] = ckl; col[(l, k)] = clk
        nb[k].append(l); nb[l].append(k)
    def img(p, m):
        r = 0; i = 0
        while m:
            if m & 1: r |= 1 << p[i]
            m >>= 1; i += 1
        return r
    dom = [None]
    for k in range(1, n + 1):
        m = len(D[k]); sig = {}
        for x in range(m):
            s = tuple(tuple(sorted(pc(c) for c in col[(k, l)] if c >> x & 1)) for l in nb[k])
            sig.setdefault(s, []).append(x)
        tests = [(col[(k, l)], sorted(col[(k, l)])) for l in nb[k]]
        good = []
        for p in perms_respecting(list(sig.values()), m):
            if all(sorted(img(p, c) for c in cs) == srt for cs, srt in tests): good.append(p)
        dom.append(good)
    lam = lambda k, l, p: tuple(img(p, c) for c in col[(k, l)])
    def kap(k, l, q):
        c = col[(k, l)]
        return tuple(c[q[y]] for y in range(len(q)))
    changed = True
    while changed:
        changed = False
        for k in range(1, n + 1):
            for l in nb[k]:
                keysl = {kap(k, l, q) for q in dom[l]}
                new = [p for p in dom[k] if lam(k, l, p) in keysl]
                if len(new) != len(dom[k]): dom[k] = new; changed = True
    earlier = {l: [k for k in nb[l] if k < l] for l in range(1, n + 1)}
    index = [None]
    for l in range(1, n + 1):
        d = {}
        for q in dom[l]: d.setdefault(tuple(kap(k, l, q) for k in earlier[l]), []).append(q)
        index.append(d)
    lamc = {}
    sols = []; cur = [None] * (n + 1)
    def dfs(l):
        if l == n + 1:
            sols.append(tuple(cur[1:]))
            if len(sols) > limit: raise RuntimeError("more than %d elements" % limit)
            return
        want = []
        for k in earlier[l]:
            key = (k, l, cur[k])
            v = lamc.get(key)
            if v is None: v = lamc[key] = lam(k, l, cur[k])
            want.append(v)
        for q in index[l].get(tuple(want), ()):
            cur[l] = q
            dfs(l + 1)
    sys.setrecursionlimit(10000)
    dfs(1)
    return sols, idx

def leg_group(recorded, cache, nsamp, seed, mut=None, quick=False):
    rng = random.Random(seed)
    fids = DECISIVE[:1] if quick else DECISIVE
    byid = {r["id"]: r for r in recorded}
    allok = True; orders = set(); trans = set(); orbs = set(); nf = 0
    for fid in fids:
        t0 = time.time()
        try:
            rec = byid[fid]
            ctx = cache.get(fid) or prep_fibre(rec, 0, rng)
            f = ctx["f"]; P = dict(ctx["P"]); TY = ctx["TY"]
            if mut == "group_drop_same_support": P = {kl: R for kl, R in P.items() if kl[1] == kl[0] + 1}
            D = f.domains()
            sols, idx = group_of_fibre(D, P)
            S = set(sols)
            ident = tuple(tuple(range(len(D[k]))) for k in range(1, 32))
            closed = ident in S
            mul = lambda g, h: tuple(tuple(g[k][h[k][i]] for i in range(len(h[k]))) for k in range(31))
            for _ in range(2000):
                if mul(rng.choice(sols), rng.choice(sols)) not in S: closed = False; break
            tvecs = []
            for g in sols:
                a = 0; is_t = True
                for k in range(1, 32):
                    p = g[k - 1]; d = D[k]
                    xs = {d[i] ^ d[p[i]] for i in range(len(d))}
                    if len(xs) != 1 or next(iter(xs)) not in UNPM: is_t = False; break
                    a |= UNPM[next(iter(xs))] << (3 * (k - 1))
                if is_t: tvecs.append(a)
            t_ok = rank(tvecs) == len(TY) and len(tvecs) == 1 << len(TY)
            tperms = [tuple(tuple(idx[k + 1][D[k + 1][i] ^ PM[(a >> (3 * k)) & 7]] for i in range(len(D[k + 1])))
                            for k in range(31)) for a in tvecs]
            reps = []; covered = set()
            for g in sols:
                if g in covered: continue
                reps.append(g)
                for tp in tperms: covered.add(mul(tp, g))
            cos_ok = len(reps) * len(tvecs) == len(sols)
            piv = rref(TY)
            orb = {}
            walk_ok = True
            for _ in range(nsamp):
                y = f.sample(rng)
                seen = []
                for g in reps:
                    z = [D[k + 1][g[k][idx[k + 1][y[k]]]] for k in range(31)]
                    if not in_fibre(z, rec["skel"], rec["cls"]): walk_ok = False
                    found = False
                    for z2 in seen:
                        dv = 0; okp = True
                        for k in range(31):
                            x = z[k] ^ z2[k]
                            if x not in UNPM: okp = False; break
                            dv |= UNPM[x] << (3 * k)
                        if okp and in_span(piv, dv): found = True; break
                    if not found: seen.append(z)
                sz = len(seen) * len(tvecs)
                orb[sz] = orb.get(sz, 0) + 1
            ok = closed and t_ok and cos_ok and walk_ok and len(sols) == 65536 and len(tvecs) == 8192 and set(orb) == {8192}
            orders.add(len(sols)); trans.add(len(tvecs)); orbs |= set(orb)
            print("%s F=%d |G_gen|=%d translations=%d (2^dim T_Y = 2^%d) closed=%s cosets=%d sampled_walks=%d orbit_sizes=%s %.0fs %s"
                  % (fid, ctx["F"], len(sols), len(tvecs), len(TY), closed, len(reps), nsamp, sorted(orb.items()),
                     time.time() - t0, "OK" if ok else "FAILED"), flush=True)
        except Exception as ex:
            print("%s ERROR %r" % (fid, ex)); ok = False
        allok &= ok; nf += 1
    one = lambda s: str(next(iter(s))) if len(s) == 1 else "VARIES"
    print("FREE_MOVES_GROUP=%s fibres=%d order=%s translations=%s orbit=%s orbit_over=sampled_walks sample=%d_per_fibre%s"
          % ("PASS" if allok and nf == len(fids) else "FAIL", nf, one(orders), one(trans), one(orbs), nsamp,
             " set=quick" if quick else ""))
    return allok and nf == len(fids)

# ============================================================ leg A: the atlas
def leg_atlas(path, mut=None):
    if not path or not os.path.exists(path):
        say("FREE_MOVES_ATLAS=MISSING path=%s" % path); return False
    h = hashlib.sha256(open(path, "rb").read()).hexdigest()
    a = json.load(open(path))
    N = int(a["N_total"]); L = a["layers"]
    V2 = [[int(l["by_class"][c]) for c in ("d1", "d2", "d3", "d4", "d6")] for l in L]
    V1 = [[int(l["marginal_raw"].get("pair%d" % p, "0")) for p in range(32)] for l in L]
    if mut == "atlas_v2_cell": V2[7][2] += 1 << 13
    if mut == "atlas_v1_cell": V1[3][7] += 1 << 18
    if mut == "atlas_v1_pair5": V1[4][5] += 1 << 19
    unit = 3 << 14
    shape = int(a["n"]) == 31 and len(L) == 31 and a.get("space") == "C1C2C4C5-SUPERSPACE"
    sums = all(sum(r) == N for r in V2) and all(sum(r) == N for r in V1) and all(r[0] == 0 for r in V1)
    v2div = N % unit == 0 and all(x % unit == 0 for r in V2 for x in r)
    selfrev = [p for p in range(32) if all(rev(x) == x for x in KW_PAIRS[p])]
    pair5 = [p for p in range(32) if set(KW_PAIRS[p]) == {7, 56}]
    free = range(1, 32)
    c19 = all(V1[k][p] % (1 << 19) == 0 for k in range(31) for p in free)
    c21 = all(V1[k][p] % (1 << 21) == 0 for k in range(31) for p in selfrev)
    c5 = all(V1[k][p] % (3 << 19) == 0 for k in range(31) for p in pair5)
    nz2 = [x for r in V2 for x in r if x]
    minv2_v2 = min(v2(x) for x in nz2)
    nzR = [V1[k][p] for k in range(31) for p in free if p not in selfrev and V1[k][p]]
    nzC = [V1[k][p] for k in range(31) for p in selfrev if p != 0 and V1[k][p]]
    # the bounds attained pair by pair: every reversible free pair has a cell of valuation exactly 19,
    # every free self-reverse pair one of exactly 21
    minp = {p: min(v2(V1[k][p]) for k in range(31) if V1[k][p]) for p in free if any(V1[k][p] for k in range(31))}
    rev_pairs = [p for p in free if p not in selfrev]; sr_pairs = [p for p in selfrev if p != 0]
    attained = (len(minp) == 31 and all(minp[p] == 19 for p in rev_pairs) and all(minp[p] == 21 for p in sr_pairs))
    ok = (shape and h == ATLAS_SHA256 and sums and v2div and c19 and c21 and c5 and attained
          and selfrev == [0, 13, 14, 30] and pair5 == [5])
    say("ATLAS sha256=%s pinned=%s N v2=%d v3=%d V2 cells=%d nonzero=%d min v2=%d | V1 cells=%d (free pairs) reversible min v2=%d self-reverse min v2=%d pair5 min v3=%d"
          % (h, h == ATLAS_SHA256, v2(N), vp(N, 3), sum(len(r) for r in V2), len(nz2), minv2_v2, 31 * 31,
             min(v2(x) for x in nzR), min(v2(x) for x in nzC), min(vp(V1[k][5], 3) for k in range(31) if V1[k][5])))
    say("FREE_MOVES_ATLAS=%s sha256_pinned=%s N_and_V2_div_2^14*3=%s V1_2^19=%s V1_selfreverse_2^21=%s V1_pair5_2^19*3=%s"
        " V1_min_v2_per_pair=%s"
          % ("PASS" if ok else "FAIL", h == ATLAS_SHA256, v2div, c19, c21, c5,
             ",".join("%dx%d" % (v, list(minp.values()).count(v)) for v in sorted(set(minp.values())))))
    return ok

# ============================================================ leg M: mutants and red tests
MUTANTS = {
    # name: (legs it must turn to FAIL, what it breaks)
    "touch_free": ("T", "touching row charged no condition"),
    "class3_free": ("T", "class-3 one-coordinate row charged 0"),
    "touch_swap_rules": ("T", "the |s*| = 1 and |s*| = 2 touching rules exchanged"),
    "touch_as_ordinary": ("T", "touching boundary charged as an ordinary internal one"),
    "six_free": ("T", "class-6 boundary uncharged"),
    "class1_one": ("T", "class-1 boundary charged once"),
    "internal_free": ("T", "internal class-2/4 boundaries uncharged"),
    "cross24_free": ("T", "cross class-2/4 boundaries uncharged"),
    "zero_generator": ("T", "a non-free element (the identity) offered as a generator"),
    "outside_generator": ("T", "a broken generator: a unit translation outside T_Y"),
    "alter_F": ("T", "one recorded F altered"),
    "bad_witness": ("T", "a witness walk altered"),
    "drop_same_support": ("T", "same-support projections dropped from the T_Y criterion"),
    "anchor_free": ("T", "anchor boundary uncharged (o_1 = 0 dropped); applies when slot 1 has support 0"),
    "group_drop_same_support": ("G", "same-support projections dropped from the bijection criterion"),
    "local_touch_swap": ("L", "local lemma with the two touching rules exchanged"),
    "local_no_hyp": ("L", "local lemma without the three-slot hypothesis"),
    "small_touch_free": ("E", "small-universe test with the touching row uncharged"),
    "atlas_v2_cell": ("A", "one atlas V2 cell + 2^13"),
    "atlas_v1_cell": ("A", "one atlas V1 cell + 2^18"),
    "atlas_v1_pair5": ("A", "one V1 cell of pair {7, 56} + 2^19"),
}

CONTROL_MUTANTS = {
    # reachable only with --only-mutants; a control on leg M itself: it changes nothing, so it must be MISSED
    "noop": ("A", "changes nothing (control: leg M must report MISSED)"),
}
G_OVERFLOW = "more than %d elements" % (1 << 17)

def leg_mutants(touching, recorded, cache, atlas, seed, quick=False, only=None):
    """Each mutant re-runs its leg's check on a small set; the verdict must be FAIL.  Before each
    mutant the same check runs without the mutation on the same input and must PASS (precondition);
    a failed precondition, a missing input or an exception is ERROR, never CAUGHT."""
    rng = random.Random(seed)
    hard = quick_touching(touching) if quick else touching[:10]   # the file starts with ten hard t = 13 touching fibres
    rec_sel = [r for r in recorded if r["id"] in ("check_climb303_1", "sixpair_T13_327")]
    table = dict(MUTANTS); table.update(CONTROL_MUTANTS)
    names = list(only) if only else list(MUTANTS)
    pre = {}                                                       # precondition results, by input
    def ctx_of(r, same_support=True):
        if same_support:
            if r["id"] not in cache: cache[r["id"]] = prep_fibre(r, 40, rng)
            return cache[r["id"]]
        key = ("nosame", r["id"])
        if key not in cache: cache[key] = prep_fibre(r, 40, rng, same_support=False)
        return cache[key]
    def pre_T(rs):
        for r in rs:
            if ("T", r["id"]) not in pre:
                ok, info = check_fibre(r, ctx_of(r), rng, quiet=True)
                pre[("T", r["id"])] = ok
        return all(pre[("T", r["id"])] for r in rs)
    def pre_once(key, fn):
        if key not in pre: pre[key] = bool(fn())
        return pre[key]
    caught = missed = errors = 0
    for name in names:
        leg, what = table[name]
        SAYPFX[0] = "[mutant %s precondition] " % name
        status = None; detail = ""
        try:
            if leg == "T":
                if name == "alter_F": rs = [r for r in rec_sel if r["Frec"] is not None]
                elif name == "bad_witness": rs = [r for r in hard if r["wit"] is not None]
                elif name == "drop_same_support": rs = hard[:2]
                else: rs = hard
                if not rs: status, detail = "ERROR", "input missing (no fibres)"
                elif not pre_T(rs): status, detail = "ERROR", "precondition failed: the unmutated check does not pass"
                else:
                    SAYPFX[0] = "[mutant %s] " % name
                    fails = 0; app = 0
                    for r in rs:
                        if name == "drop_same_support":
                            ok, info = check_fibre(r, ctx_of(r, same_support=False), rng, quiet=True)
                        else:
                            ok, info = check_fibre(r, ctx_of(r), rng, mut=name, quiet=True)
                            if name in TABLE_MUTANTS and not info["applicable"]: continue
                        app += 1; fails += not ok
                    status = "CAUGHT" if fails else "MISSED"
                    detail = "applicable=%d failed=%d precondition=PASS" % (app, fails)
            elif leg == "L":
                if not pre_once(("L",), lambda: leg_local(None)): status, detail = "ERROR", "precondition failed"
                else:
                    SAYPFX[0] = "[mutant %s] " % name
                    status = "MISSED" if leg_local(mut=name) else "CAUGHT"; detail = "precondition=PASS"
            elif leg == "E":
                parts = []
                for U in ((0, 1), (0, 3)):          # |s*| = 1 and |s*| = 2 touching rules
                    if not pre_once(("E", U), lambda: small_universe(U, random.Random(seed), 0)[0]):
                        status, detail = "ERROR", "precondition failed on universe %s" % (U,); break
                    SAYPFX[0] = "[mutant %s] " % name
                    e = small_universe(U, random.Random(seed), 0, mut="touch_free")[0]
                    parts.append((U, not e))
                    SAYPFX[0] = "[mutant %s precondition] " % name
                if status is None:
                    status = "CAUGHT" if all(c for _, c in parts) else "MISSED"
                    detail = "universes %s precondition=PASS" % " ".join("%d%d:%s" % (U[0], U[1], "caught" if c else "missed") for U, c in parts)
            elif leg == "A":
                if not atlas or not os.path.exists(atlas): status, detail = "ERROR", "input missing (atlas %s)" % atlas
                elif not pre_once(("A",), lambda: leg_atlas(atlas)): status, detail = "ERROR", "precondition failed"
                else:
                    SAYPFX[0] = "[mutant %s] " % name
                    status = "MISSED" if leg_atlas(atlas, mut=name) else "CAUGHT"; detail = "precondition=PASS"
            elif leg == "G":
                rid = [r for r in recorded if r["id"] == DECISIVE[0]]
                if not rid: status, detail = "ERROR", "input missing (%s)" % DECISIVE[0]
                else:
                    ctx = ctx_of(rid[0]); f = ctx["f"]; D = f.domains()
                    def g_pre():
                        sols, _ = group_of_fibre(D, ctx["P"], limit=1 << 17)
                        return len(sols) == 65536
                    if not pre_once(("G",), g_pre): status, detail = "ERROR", "precondition failed: unmutated listing is not 65536"
                    else:
                        SAYPFX[0] = "[mutant %s] " % name
                        P = {kl: R for kl, R in ctx["P"].items() if kl[1] == kl[0] + 1}
                        try:
                            sols, idx = group_of_fibre(D, P, limit=1 << 17)
                            # a weaker criterion can only admit more elements; a smaller order is a program fault
                            status = "CAUGHT" if len(sols) > 65536 else "MISSED" if len(sols) == 65536 else "ERROR"
                            detail = "order %d precondition=PASS" % len(sols)
                        except RuntimeError as ex:
                            if str(ex) == G_OVERFLOW: status, detail = "CAUGHT", "%s precondition=PASS" % ex
                            else: status, detail = "ERROR", "raised %r" % ex
            else:
                status, detail = "ERROR", "unknown leg %s" % leg
        except Exception as ex:
            status, detail = "ERROR", "raised %r" % ex
        SAYPFX[0] = ""
        caught += status == "CAUGHT"; missed += status == "MISSED"; errors += status == "ERROR"
        print("FREE_MOVES_MUTANT_%s=%s leg=%s %s (%s)" % (name.upper(), status, leg, detail, what), flush=True)
    total = len(names)
    ok = caught == total > 0
    print("FREE_MOVES_MUTANTS=%s caught=%d/%d missed=%d error=%d set=%s%s"
          % ("PASS" if ok else "FAIL", caught, total, missed, errors, "quick" if quick else "default",
             " subset=" + ",".join(names) if only else ""))
    return ok

# ============================================================ main
def main(argv):
    args = dict(atlas=None, legs=None, full=False, quick=False, seed=20261116, walks=200, gwalks=1000, mutant=None,
                only_mutants=None)
    i = 0
    while i < len(argv):
        x = argv[i]
        if x == "--full": args["full"] = True
        elif x == "--quick": args["quick"] = True
        elif x == "--list-mutants":
            for k, (leg, what) in MUTANTS.items(): print(k, leg, what)
            for k, (leg, what) in CONTROL_MUTANTS.items(): print(k, leg, what, "[control, --only-mutants only]")
            return 0
        elif x in ("--atlas", "--legs", "--seed", "--walks", "--gwalks", "--mutant", "--only-mutants"):
            if i + 1 >= len(argv) or argv[i + 1].startswith("--"):
                print("%s needs a value" % x); print("FREE_MOVES=ERROR"); return 2
            i += 1; args[x[2:].replace("-", "_")] = argv[i]
        else:
            print(__doc__.split("usage:")[1].split("Final token")[0]); print("FREE_MOVES=ERROR"); return 2
        i += 1
    try:
        seed = int(args["seed"]); ns = int(args["walks"]); gw = int(args["gwalks"])
    except ValueError:
        print("--seed, --walks and --gwalks take integers"); print("FREE_MOVES=ERROR"); return 2
    default_legs = ["L", "E", "S", "T", "G", "A", "M"]
    quick_legs = ["L", "E", "S", "T", "A", "M"]
    if args["full"] and args["quick"]:
        print("--full and --quick exclude each other"); print("FREE_MOVES=ERROR"); return 2
    legs = args["legs"].split(",") if args["legs"] else (list(quick_legs) if args["quick"] else list(default_legs))
    if any(l not in default_legs for l in legs):
        print("unknown leg in --legs %s" % args["legs"]); print("FREE_MOVES=ERROR"); return 2
    mut = args["mutant"]
    if mut is not None and mut not in MUTANTS:
        print("unknown mutant"); print("FREE_MOVES=ERROR"); return 2
    only = args["only_mutants"].split(",") if args["only_mutants"] else None
    if only is not None:
        bad = [m for m in only if m not in MUTANTS and m not in CONTROL_MUTANTS]
        if bad or mut is not None:
            print("unknown mutant in --only-mutants" if bad else "--only-mutants and --mutant exclude each other")
            print("FREE_MOVES=ERROR"); return 2
    atlas = args["atlas"]
    if atlas is None:
        for cand in (os.path.join(HERE, "atlas_n31.json"),
                     os.path.join(HERE, "..", "..", "..", "runs", "20260906_kc_ladders_n31", "atlas_n31.json")):
            if os.path.exists(cand): atlas = cand; break
    t0 = time.time()
    print("free_moves.py seed=%d walks=%d gwalks=%d legs=%s profile=%s" % (seed, ns, gw, ",".join(legs),
          "full" if args["full"] else "quick" if args["quick"] else "default"))
    if not model_selfcheck():
        print("FREE_MOVES_MODEL=FAIL"); print("FREE_MOVES=FAIL"); return 1
    print("FREE_MOVES_MODEL=PASS")
    # the two data files: pinned; a mismatch or a missing file fails the final verdict
    rec_path = os.path.join(HERE, "fibres_n31.tsv"); tch_path = os.path.join(HERE, "fibres_n31_touching.tsv")
    def sha(p): return hashlib.sha256(open(p, "rb").read()).hexdigest() if os.path.exists(p) else None
    rec_sha, tch_sha = sha(rec_path), sha(tch_path)
    files_ok = rec_sha == RECORDED_SHA256 and tch_sha == TOUCHING_SHA256
    print("FREE_MOVES_RECORDED_FILE=%s sha256=%s" % ("MISSING" if rec_sha is None else "PASS" if rec_sha == RECORDED_SHA256 else "FAIL", rec_sha))
    print("FREE_MOVES_TOUCHING_FILE=%s sha256=%s" % ("MISSING" if tch_sha is None else "PASS" if tch_sha == TOUCHING_SHA256 else "FAIL", tch_sha))
    def load(path, present, name):
        if not present: return []
        try:
            return read_tsv(path)
        except Exception as ex:
            print("FREE_MOVES_%s_FILE=ERROR unreadable %r" % (name, ex)); return []
    recorded = load(rec_path, rec_sha, "RECORDED")
    touching = load(tch_path, tch_sha, "TOUCHING")
    results = {}
    cache = {}
    def run(name, fn):
        t1 = time.time()
        try:
            results[name] = bool(fn())
        except Exception as ex:
            traceback.print_exc(); print("FREE_MOVES_LEG_%s=FAIL raised %r" % (name, ex)); results[name] = False
        print("TIME leg %s %.0f s" % (name, time.time() - t1), flush=True)
    tm = mut if mut in TABLE_MUTANTS else None
    if mut is not None and MUTANTS[mut][0] not in legs and not (MUTANTS[mut][0] in "ES" and ("E" in legs or "S" in legs)):
        print("FREE_MOVES_MUTANT_LEG=NOT_SELECTED mutant=%s target_leg=%s" % (mut, MUTANTS[mut][0]))
    if "L" in legs: run("L", lambda: leg_local(mut if mut in ("local_touch_swap", "local_no_hyp") else None))
    if "E" in legs or "S" in legs:
        res = {}
        def es():
            e, s = leg_small(args["full"], seed + 1, "touch_free" if mut == "small_touch_free" else tm)
            res["E"], res["S"] = e, s
            return e and s
        run("ES", es)
        results.pop("ES", None)
        for k in ("E", "S"):
            if k in legs: results[k] = res.get(k, False)
    if "T" in legs:
        def lt():
            if mut is None: return leg_fibres(recorded, touching, args["full"], ns, seed + 2, cache, args["quick"])
            rng = random.Random(seed + 2); allok = True
            if args["quick"]: sel = quick_touching(touching) + [r for r in recorded if r["id"] == "check_climb303_1"]
            else: sel = touching[:10] + [r for r in recorded if r["id"] in DECISIVE]
            if not sel: print("FREE_MOVES_BOUND=ERROR no fibres mutant=%s" % mut); return False
            for r in sel:
                ctx = prep_fibre(r, 40, rng, same_support=(mut != "drop_same_support"))
                cache[r["id"]] = ctx
                ok, info = check_fibre(r, ctx, rng, mut=mut)
                allok &= ok
            print("FREE_MOVES_BOUND=%s fibres=%d mutant=%s set=%s" % ("PASS" if allok else "FAIL", len(sel), mut,
                  "quick" if args["quick"] else "default"))
            return allok
        run("T", lt)
    if "G" in legs: run("G", lambda: leg_group(recorded, cache, gw, seed + 3, mut, args["quick"]))
    elif args["quick"]: print("FREE_MOVES_GROUP=SKIP_QUICK (leg G is not in the quick profile)")
    if "A" in legs: run("A", lambda: leg_atlas(atlas, mut))
    if "M" in legs:
        if mut is not None: print("FREE_MOVES_MUTANTS=NOT_RUN (a mutant run does not run the mutant leg)")
        else: run("M", lambda: leg_mutants(touching, recorded, cache, atlas, seed + 4, args["quick"], only))
    ran = [k for k in default_legs if k in results]
    allpass = all(results.values()) and bool(results) and files_ok
    print("TIME total %.0f s" % (time.time() - t0))
    tail = (" mutant=" + mut) if mut else (" only_mutants=" + ",".join(only)) if only else ""
    if mut is not None:
        # a mutant run is a red test: FAIL only when a leg the mutation reaches ran and failed and
        # nothing else went wrong; a bad data file or a failure elsewhere is ERROR; never PARTIAL
        reach = {MUTANTS[mut][0]} | ({"E"} if mut in TABLE_MUTANTS else set())
        failed = [k for k in ran if not results[k]]
        if not files_ok:
            print("FREE_MOVES=ERROR data file not as pinned legs=%s%s" % (",".join(ran), tail)); return 2
        if any(k not in reach for k in failed):
            print("FREE_MOVES=ERROR a leg the mutation does not reach failed (%s) legs=%s%s"
                  % (",".join(k for k in failed if k not in reach), ",".join(ran), tail)); return 2
        if failed:
            print("FREE_MOVES=FAIL legs=%s%s" % (",".join(ran), tail)); return 1
        print("FREE_MOVES=MUTANT_NOT_CAUGHT legs=%s%s" % (",".join(ran), tail)); return 3
    if args["quick"]:
        qv = "FAIL" if not allpass else "PASS" if ran == quick_legs and only is None else "PARTIAL"
        print("FREE_MOVES_QUICK=%s legs=%s%s" % (qv, ",".join(ran), tail))
    if not allpass: verdict = "FAIL"
    elif ran == default_legs and not args["quick"] and only is None: verdict = "PASS"
    else: verdict = "PARTIAL"
    print("FREE_MOVES=%s legs=%s%s" % (verdict, ",".join(ran), tail))
    return 0 if verdict in ("PASS", "PARTIAL") else 1

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
