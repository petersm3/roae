#!/usr/bin/env python3
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
"""
sat.py — SAT/certificate layer for the ROAE constraint system (established 2026-07-02).

HARD RULE: this file must contain NO hand-written constraint semantics. Every constraint
encoded here is derived from `solve` (solve.py) imports — the single source of truth for
the King Wen ground truth and C1-C5 semantics. A clause encoding a C-rule from scratch is
a bug by definition. Validation discipline: every encoding is round-trip checked (SAT
model -> decode -> solve.py constraint functions) before any UNSAT claim from it is trusted.

Architecture (operator-approved 2026-07-02): three canonical sources — solve.c (enumeration,
sha-anchored), solve.py (analysis + ground truth), sat.py (this file; imports solve.py).
External solvers (kissat / CaDiCaL) run as separate binaries; their UNSAT answers are only
trusted via DRAT/LRAT certificates checked by an independent verified checker. Third-party
solver use authorized by operator 2026-07-02.

Subcommands:
  --emit-cnf TARGET OUT.cnf     write DIMACS for TARGET
  --decode MODEL.txt            decode a solver model (v-lines) to a 64-hexagram sequence + verify
  --witness TARGET              emit CNF, run solver (kissat on PATH or pysat), decode, verify,
                                iterate blocking clauses until a C3-passing witness is found
Targets:
  alt-le-14      C1+C2+C4+C5 AND (odd between-pair transitions <= 14)   [expect UNSAT]
  alt-ge-16      C1+C2+C4+C5 AND (odd between-pair transitions >= 16)   [expect UNSAT]
                 (both UNSAT == SAT-certified parity-alternation theorem, PARITY_ALTERNATION.md)
  moore-strict   C1+C2+C4+C5 AND Moore-2005 parity (all 18) AND Moore-1989 rhythm (0 breaks)
                 [expect SAT -> explicit witness ordering; C3 enforced by verify-loop]
                 (attribution: Moore 2005 Oracle Papers No.1; Moore 1989 Trigrams of Han App.2)
  plain          C1+C2+C4+C5 only (baseline satisfiability sanity)
  rc4-strict     C1+C2+C4+C5 AND Schulz gender/position-parity with 0 violations
                 (attribution: Schulz 1990 JCP 17:3 motif 2, exception first noticed by Zhu
                 Yuansheng 13th c.; elaborated Cook 2006; semantics = solve.rc4_violations)
  rc4-kwtest     encoding validation: KW forced + strict clauses  [expect UNSAT — KW violates at 25/26]
  rc4-kwexempt   encoding validation: KW forced + clauses exempting class positions 25/26  [expect SAT]
  grand-strict   Moore 2005 parity 18/18 AND Moore 1989 rhythm 0-breaks AND Schulz gender 0-violations
                 (the "grand unified precursor" question: all three literature rules simultaneously)
  grand-ccn4     grand-strict AND CC-N4 (Schulz S25-28 dui-trigram configuration) — the five-rule
                 conflict decision, increment 1: UNSAT proves no ordering is perfect under Moore
                 parity + Moore rhythm + Schulz gender + the trigram champion simultaneously.
  ccn4-kwtest    encoding validation: KW forced + ccn4 clauses  [expect SAT — KW satisfies ccn4]
  grander-strict grand-ccn4 AND CC-N8 (Schulz exception co-location) — the FIVE-rule union
                 (task #217): Moore parity + Moore rhythm + Schulz gender + CC-N4 + CC-N8.
                 NOTE: gender-strict (0 violations) and CC-N8 (violations exactly at class
                 positions 25/26) are incompatible by construction — {gender, ccn8} is a
                 2-rule core; the encoding keeps CC-N8 as stated (solve.reg_ccn8) so the
                 semantic conflict is itself certificate-backed.
  five-loo-RULE  leave-one-out 4-subsets of the five-rule union; RULE names the rule DROPPED,
                 in {parity, rhythm, gender, ccn4, ccn8} (five-loo-ccn8 == grand-ccn4, the
                 published four-rule conflict theorem).
  gender-ccn8    the 2-rule core alone  [expect UNSAT]
  ccn8-kwtest    encoding validation: KW forced + ccn8 clauses  [expect SAT — KW satisfies ccn8]
  ccn8-kwfail    encoding validation: KW forced + ccn8 clauses at shifted locus (24,25)
                 [expect UNSAT — KW's gender-violation set is {25,26}, not {24,25}]
  ccn8-kwchain   encoding validation: KW forced + R-S2 run-parity chain pinned to its
                 solve.py-derived KW value  [expect SAT]; ccn8-kwchain-not pins the negation
                 [expect UNSAT] — two-way gate on the chain recurrence alone
  wrap-d5        C1+C2+C4+C5 AND wrap distance d(s63, s0) == 5 (i.e., popcount(s63) == 1).
                 UNSAT => circular C2 is IMPLIED by the linear system (the McKenna circular reading
                 adds no C2 constraint); SAT => a valid ordering with a 5-line wrap exists.
                 560T empirical: 0 of 10.5e9 records (wrap is 91.83% d=3 / 8.17% d=1).
  kw-pin         encoding validation: KW forced, no extra rule clauses (combine with --with-c3)
Flags (append after the target):
  --with-c3      encode C3 natively in CNF: sum_h |pos(h) - pos(comp(h))| <= 776, comp(h) = h^63
                 (the complement-distance ceiling; ground truth = solve.mean_complement_distance,
                 KW mean 12.125 * 64 hexagrams = 776; see solve.py and CITATIONS.md for lineage).
                 Derivation (asserted at import): in the pair-slot model the pairing is closed
                 under complement, so C3 = 2*|self-complement pairs| + 8 * sum over complement
                 couples of |slot(u) - slot(v)|, independent of orientations. The CNF bounds the
                 couple slot-distance sum with a Sinz sequential counter.
  --c3-max N     override the C3 ceiling (default 776); e.g. 775 for the KW-exactness UNSAT gate
"""

import sys, subprocess, os
import solve  # single source of truth

KW = list(solve.binary_hexagrams)
PAIRS = solve.build_pairs()                      # [(a, partner)] — canonical pairing
KW_PAIRS = [(KW[2*i], KW[2*i+1]) for i in range(32)]
# pair index convention aligned with solve.c: pairs in KW order of appearance
PAIR_IDX = {frozenset(p): i for i, p in enumerate(KW_PAIRS)}
BETWEEN_MULTISET = {1: 2, 2: 8, 3: 13, 4: 7, 6: 1}   # derived: C5 total minus fixed within-pair
_wp = {}
for a, b in KW_PAIRS:
    _wp[solve.bit_diff(a, b)] = _wp.get(solve.bit_diff(a, b), 0) + 1
_tot = {1: 2, 2: 20, 3: 13, 4: 19, 6: 9}             # C5 (verified vs solve.py constraint funcs below)
for d in (2, 4, 6):
    assert _tot.get(d, 0) - _wp.get(d, 0) == BETWEEN_MULTISET.get(d, 0), "between-multiset derivation broke"

# ---- static per-(pair,orient) facts, all derived from solve imports ----
def pc(n): return bin(n).count("1")
ORIENTS = []   # j -> (pair_index p 1..31, orient, first_hex, second_hex)
for p in range(1, 32):
    a, b = KW_PAIRS[p]
    ORIENTS.append((p, 0, a, b))
    ORIENTS.append((p, 1, b, a))
NJ = len(ORIENTS)                                 # 62
SLOTS = list(range(1, 32))                        # slot 0 fixed: pair 0 as (63, 0) per C4

# ---- C3 static facts (complement-distance ceiling), derived from solve imports ----
# ATTRIBUTION: C3 = complement proximity, one of the C1-C5 registry rules; semantics =
# solve.mean_complement_distance (Rule 3 in solve.py); KW ceiling 776 = 12.125 * 64. CITATIONS.md.
_kwpos = {h: i for i, h in enumerate(KW)}
KW_C3 = sum(abs(_kwpos[h] - _kwpos[h ^ 63]) for h in range(64))
assert KW_C3 == round(solve.mean_complement_distance(KW) * 64) == 776, "C3 ground-truth derivation broke"
# the canonical pairing is closed under complement: comp of pair {a,b} is pair {a^63,b^63}
C3_SELFC = [p for p, (a, b) in enumerate(KW_PAIRS) if a ^ b == 63]     # self-complement pairs
C3_COUPLES = []                                                        # unordered {p,q} complement couples
for _p, (_a, _b) in enumerate(KW_PAIRS):
    if _a ^ _b == 63: continue
    _q = PAIR_IDX[frozenset((_a ^ 63, _b ^ 63))]
    assert _q != _p and _q != 0, "complement couple derivation broke"
    if _p < _q: C3_COUPLES.append((_p, _q))
assert len(C3_SELFC) == 8 and len(C3_COUPLES) == 12 and 0 in C3_SELFC
# a self-complement pair contributes |diff|=1 per member counted twice = 2; a couple with slots
# s,t and orientation offsets e1,e2 contributes 2*(|(2s+e1)-(2t+e2)| + |(2s+1-e1)-(2t+1-e2)|)
# = 8*|s-t| for s != t, orientation-independent (asserted exhaustively):
assert all(2 * (abs((2*s + e1) - (2*t + e2)) + abs((2*s + 1 - e1) - (2*t + 1 - e2))) == 8 * abs(s - t)
           for s in range(31) for t in range(31) if s != t for e1 in (0, 1) for e2 in (0, 1))
# decomposition check on KW itself (KW slot of pair p is p):
assert 2 * len(C3_SELFC) + 8 * sum(abs(u - v) for u, v in C3_COUPLES) == KW_C3, "C3 decomposition broke"

# ---- CC-N8 static facts (Schulz exception co-location), derived from solve imports ----
# ATTRIBUTION: CC-N8 = Schulz 2016 (Hexagrammatics) pp. 14-15, SC-7 double-exception note;
# Schulz 1990 JCP 17:3 for both underlying motifs. Semantics = solve.reg_ccn8: the CC-A2
# (gender) violation set is EXACTLY {25, 26} and both class positions also violate R-S2.
assert solve.reg_ccn8(KW) is True, "CC-N8 KW ground truth broke"
assert solve.rc4_violations(KW) == (2, [25, 26]), "CC-A2 KW ground truth broke"
assert solve._reg_rs2_violations(KW) == [11, 13, 14, 25, 26, 32], "R-S2 KW ground truth broke"

def _rs2_viol_from_bal(bal):
    """solve._reg_rs2_violations' run-segmented pairing, factored over a station-balance
    vector (the solve function takes a hexagram sequence; this exposes the balance step so
    the CNF recurrence below can be validated exhaustively). Asserted == solve on KW and
    300 seeded random permutations at import, composed with solve's own
    _reg_balances/_reg_stations — no independent semantics."""
    viol = []
    def close(run):
        for i in range(0, len(run) - 1, 2):
            if bal[run[i] - 1] != -bal[run[i + 1] - 1]:
                viol.extend([run[i], run[i + 1]])
        if len(run) % 2:
            viol.append(run[-1])
    run = []
    for k in range(1, len(bal) + 1):
        if bal[k - 1] == 0:
            close(run); run = []
        else:
            run.append(k)
    close(run)
    return sorted(viol)

import random as _random, itertools as _itertools
_rng = _random.Random(217)
for _t in range(300):
    _perm = list(range(64)); _rng.shuffle(_perm)
    assert (_rs2_viol_from_bal(solve._reg_balances(solve._reg_stations(_perm)))
            == solve._reg_rs2_violations(_perm)), "R-S2 balance-replica derivation broke"
assert _rs2_viol_from_bal(solve._reg_balances(solve._reg_stations(KW))) == [11, 13, 14, 25, 26, 32]

def _rs2_r_after(bal_prefix):
    """R-S2 run-parity state: True iff the next non-zero station OPENS a pair."""
    r = True
    for b in bal_prefix:
        r = True if b == 0 else (not r)
    return r

# The CNF's R-S2-co-violation case analysis: "{a, a+1} subset of the violation set" depends
# only on (r_{a-1}, b_{a-1}, b_a, b_{a+1}, b_{a+2}). Asserted exhaustively — 2 x 7^4 local
# windows, each embedded in a full 36-vector — against the replica above:
for _rprev in (True, False):
    _prefix = [0] * 23 if _rprev else [0] * 22 + [2]     # positions 1..23 realizing r_23
    assert _rs2_r_after(_prefix) == _rprev
    for _w in _itertools.product((-6, -4, -2, 0, 2, 4, 6), repeat=4):
        _b24, _b25, _b26, _b27 = _w                      # positions 24..27
        _bal = _prefix + list(_w) + [0] * 9
        _r24 = True if _b24 == 0 else (not _rprev)
        if _b25 == 0 or _b26 == 0:
            _pred = False                                # zero-balance stations never violate
        elif _r24:
            _pred = (_b25 + _b26) != 0                   # 25 opens, 26 closes: joint mismatch
        else:                                            # 25 closes 24's pair; 26 opens anew
            _pred = (_b24 + _b25) != 0 and (_b27 == 0 or (_b26 + _b27) != 0)
        assert _pred == ({25, 26} <= set(_rs2_viol_from_bal(_bal))), "R-S2 CNF case analysis broke"

KW_BAL = solve._reg_balances(solve._reg_stations(KW))
KW_RS2_R24 = _rs2_r_after(KW_BAL[:24])   # True on KW: position 24 is zero-balance
# gender-violation popcounts by class-position parity (solve.rc4_violations semantics:
# {0,3,6} exempt; violation iff (pc < 3) != (position odd)) — used by the CC-N8 clauses:
assert all(((w < 3) != bool(pos % 2)) == (w in ((4, 5) if pos % 2 else (1, 2)))
           for w in (1, 2, 4, 5) for pos in (24, 25, 26, 27))

def directional(p):
    a, b = KW_PAIRS[p]
    return (a ^ b) != 63 and pc(a) != 3

def rising(first, p):
    """Moore 1989: minority lines of the first hexagram sit low -> they rise under reversal."""
    mb = 0 if pc(KW_PAIRS[p][0]) > 3 else 1
    return sum((5 - 2*i) for i in range(6) if ((first >> i) & 1) == mb) > 0

# ---- CNF builder ----
class CNF:
    def __init__(self): self.n = 0; self.cl = []
    def var(self): self.n += 1; return self.n
    def add(self, *lits): self.cl.append(list(lits))
    def write(self, path, comment):
        with open(path, "w") as f:
            f.write("c %s\nc generated by sat.py from solve.py definitions\n" % comment)
            f.write("p cnf %d %d\n" % (self.n, len(self.cl)))
            for c in self.cl:
                f.write(" ".join(map(str, c)) + " 0\n")

def exactly_one(cnf, lits):
    cnf.add(*lits)
    for i in range(len(lits)):
        for j in range(i+1, len(lits)):
            cnf.add(-lits[i], -lits[j])

def at_most_k(cnf, lits, k):
    """Sinz 2005 sequential counter: at most k of lits are true."""
    n = len(lits)
    if k >= n: return
    if k == 0:
        for x in lits: cnf.add(-x)
        return
    s = [[cnf.var() for _ in range(k)] for _ in range(n)]
    cnf.add(-lits[0], s[0][0])
    for j in range(1, k): cnf.add(-s[0][j])
    for i in range(1, n):
        cnf.add(-lits[i], s[i][0])
        cnf.add(-s[i-1][0], s[i][0])
        for j in range(1, k):
            cnf.add(-lits[i], -s[i-1][j-1], s[i][j])
            cnf.add(-s[i-1][j], s[i][j])
        cnf.add(-lits[i], -s[i-1][k-1])

def at_least_k(cnf, lits, k):
    at_most_k(cnf, [-x for x in lits], len(lits) - k)

def exactly_k(cnf, lits, k):
    at_most_k(cnf, lits, k); at_least_k(cnf, lits, k)

FIVE_RULES = ("parity", "rhythm", "gender", "ccn4", "ccn8")
RULESETS = {   # target base -> literature rules enforced strictly (task #217 5-rule family)
    "plain": (), "kw-pin": (), "wrap-d5": (), "alt-le-14": (), "alt-ge-16": (),
    "moore-strict": ("parity", "rhythm"),
    "grand-strict": ("parity", "rhythm", "gender"),
    "rc4-strict": ("gender",), "rc4-kwtest": ("gender",), "rc4-kwexempt": ("gender",),
    "ccn4-kwtest": ("ccn4",),
    "grand-ccn4": ("parity", "rhythm", "gender", "ccn4"),
    "grander-strict": FIVE_RULES,                       # the five-rule union
    "gender-ccn8": ("gender", "ccn8"),                  # the 2-rule core
    "ccn8-kwtest": ("ccn8",), "ccn8-kwfail": ("ccn8",),
    "ccn8-kwchain": (), "ccn8-kwchain-not": (),         # chain machinery only
}
for _r in FIVE_RULES:
    RULESETS["five-loo-" + _r] = tuple(x for x in FIVE_RULES if x != _r)

def build(target, with_c3=False, c3_max=None):
    tbase = target.split("-near-")[0]
    if tbase.startswith("five-sub-"):
        # generic subset of the five-rule family, e.g. five-sub-parity+ccn8
        # (used to map the conflict lattice / minimal unsatisfiable cores, task #217)
        rules = set(tbase[len("five-sub-"):].split("+"))
        if not rules <= set(FIVE_RULES):
            raise SystemExit("unknown rules in target: " + target)
    elif tbase in RULESETS:
        rules = set(RULESETS[tbase])
    else:
        raise SystemExit("unknown target: " + target)
    cnf = CNF()
    Y = {}
    for s in SLOTS:
        for j in range(NJ):
            Y[(s, j)] = cnf.var()
    for s in SLOTS:                       # one (pair,orient) per slot
        exactly_one(cnf, [Y[(s, j)] for j in range(NJ)])
    for p in range(1, 32):                # each pair used exactly once (across slots+orients)
        lits = [Y[(s, j)] for s in SLOTS for j in range(NJ) if ORIENTS[j][0] == p]
        exactly_one(cnf, lits)

    # transition structure: exit(slot s) -> entry(slot s+1); slot0 exit is hexagram 0
    def exit_hex(j):  return ORIENTS[j][3]
    def entry_hex(j): return ORIENTS[j][2]

    # C2 + distance indicators for C5
    T = {}
    for s in range(0, 31):                # boundary s between slot s and s+1
        for d in BETWEEN_MULTISET:
            T[(s, d)] = cnf.var()
        exactly_one(cnf, [T[(s, d)] for d in BETWEEN_MULTISET])
    # boundary 0: fixed exit 0
    for j in range(NJ):
        d = solve.bit_diff(0, entry_hex(j))
        if d == 5 or d == 0:
            cnf.add(-Y[(1, j)])
        else:
            cnf.add(-Y[(1, j)], T[(0, d)])
    for s in range(1, 31):
        for j1 in range(NJ):
            for j2 in range(NJ):
                if ORIENTS[j1][0] == ORIENTS[j2][0]:
                    continue
                d = solve.bit_diff(exit_hex(j1), entry_hex(j2))
                if d == 5 or d == 0:
                    cnf.add(-Y[(s, j1)], -Y[(s+1, j2)])
                else:
                    cnf.add(-Y[(s, j1)], -Y[(s+1, j2)], T[(s, d)])
    # C5 between-pair multiset
    for d, k in BETWEEN_MULTISET.items():
        exactly_k(cnf, [T[(s, d)] for s in range(31)], k)

    if target in ("alt-le-14", "alt-ge-16"):
        odd = []
        for s2 in range(31):
            o = cnf.var()
            cnf.add(-T[(s2, 1)], o); cnf.add(-T[(s2, 3)], o)
            cnf.add(-o, T[(s2, 1)], T[(s2, 3)])
            odd.append(o)
        if target == "alt-le-14":
            at_most_k(cnf, odd, 14)
        else:
            at_least_k(cnf, odd, 16)
    if "-near-" in target:
        # differs from KW in at most k slots (KW slot s = pair s, orient 0 by construction)
        k = int(target.rsplit("-", 1)[1])
        agree = []
        for s in SLOTS:
            jkw = next(j for j in range(NJ) if ORIENTS[j][0] == s and ORIENTS[j][1] == 0)
            agree.append(Y[(s, jkw)])
        at_least_k(cnf, agree, 31 - k)
    if "parity" in rules:
        for s in SLOTS:                   # parity: static unary forbids
            for j in range(NJ):
                p = ORIENTS[j][0]
                if directional(p):
                    want_odd = pc(KW_PAIRS[p][0]) > 3
                    if want_odd != ((s + 1) % 2 == 1):   # pair POSITION = slot index + 1 (slot 0 = position 1)
                        cnf.add(-Y[(s, j)])
    if "rhythm" in rules:
        for s in range(1, 31):            # rhythm: static binary forbids between adjacent directional
            for j1 in range(NJ):
                if not directional(ORIENTS[j1][0]): continue
                r1 = rising(ORIENTS[j1][2], ORIENTS[j1][0])
                for j2 in range(NJ):
                    if not directional(ORIENTS[j2][0]): continue
                    if ORIENTS[j1][0] == ORIENTS[j2][0]: continue
                    if rising(ORIENTS[j2][2], ORIENTS[j2][0]) == r1:
                        cnf.add(-Y[(s, j1)], -Y[(s+1, j2)])
    if rules & {"gender", "ccn4", "ccn8"} or tbase.startswith("ccn8-kwchain"):
        # Schulz gender/position-parity over the 36 inversion-class positions (solve.rc4_violations).
        # Class position of slot s's pair = s + 2 + c, where c = # palindrome-pairs among slots 1..s-1
        # (slot 0 = pair 0 = palindromes 63,0 = classes 1,2, pure-exempt). Palindrome pairs occupy two
        # positions (first hexagram lower, orientation-dependent); gender from popcount.
        # ATTRIBUTION: Schulz 1990 JCP 17:3 motif 2 (exception: Zhu Yuansheng 13th c.); Cook 2006 elab.
        exempt_pos = {25, 26} if target == "rc4-kwexempt" else set()
        def _rev6(h):
            r = 0
            for b in range(6): r |= ((h >> b) & 1) << (5 - b)
            return r
        # only true palindrome pairs (rev(h)==h members, paired by complement) occupy TWO inversion
        # classes; anti-symmetric pairs (rev(h)==comp(h)) also XOR to 63 but form ONE class.
        PALPAIRS = [p for p in range(1, 32) if _rev6(KW_PAIRS[p][0]) == KW_PAIRS[p][0]]
        NP = len(PALPAIRS)
        comp_slot = {}
        for t in SLOTS:
            v = cnf.var(); comp_slot[t] = v
            pal_lits = [Y[(t, j)] for j in range(NJ) if ORIENTS[j][0] in PALPAIRS]
            for x in pal_lits: cnf.add(-x, v)
            cnf.add(-v, *pal_lits)
        # E[t][c] = "exactly c palindrome pairs among slots 1..t"; forward implications + exactly-one
        E = {}
        e00 = cnf.var(); cnf.add(e00)
        E[0] = {0: e00}
        for t in SLOTS:
            E[t] = {c: cnf.var() for c in range(0, min(t, NP) + 1)}
            for c in E[t]:
                if c in E[t-1]:
                    cnf.add(-E[t-1][c], comp_slot[t], E[t][c])
                if c - 1 in E[t-1]:
                    cnf.add(-E[t-1][c-1], -comp_slot[t], E[t][c])
            exactly_one(cnf, list(E[t].values()))
        def viol_hex(h, pos):
            pck = bin(h).count("1")
            if pck in (0, 3, 6) or pos in exempt_pos: return False
            return (pck < 3) != (pos % 2 == 1)
        if "gender" in rules:             # ccn4-/ccn8- validation targets use the counter only
            for st in SLOTS:
                for j in range(NJ):
                    p, o, first, second = ORIENTS[j]
                    for c in E[st - 1]:
                        base = st + 2 + c
                        if p in PALPAIRS:
                            bad = viol_hex(first, base) or viol_hex(second, base + 1)
                        else:
                            bad = viol_hex(first, base)
                        if bad:
                            cnf.add(-Y[(st, j)], -E[st - 1][c])
        if "ccn4" in rules:
            # CC-N4 (Schulz 2016 pp.23-24 / 2011; convention per registry): stations 25-28 face
            # hexagrams must be 31, 24, 26, 29 (upper trigram dui; lowers qian/kun/kan/li).
            # Same E-counter: station of slot s (inverse pair) = s+2+c; palindrome pairs occupy
            # (s+2+c, s+3+c) and can never match (faces are palindromes) -> forbidden in-window.
            REQ = {25: 31, 26: 24, 27: 26, 28: 29}
            for st2 in SLOTS:
                for j in range(NJ):
                    p2, o2, first2, second2 = ORIENTS[j]
                    for c in E[st2 - 1]:
                        base = st2 + 2 + c
                        bad = False
                        if p2 in PALPAIRS:
                            if base in REQ or base + 1 in REQ:
                                bad = True    # palindrome faces can't be 31/24/26/29
                        else:
                            if base in REQ and first2 != REQ[base]:
                                bad = True
                        if bad:
                            cnf.add(-Y[(st2, j)], -E[st2 - 1][c])
        if "ccn8" in rules or tbase.startswith("ccn8-kwchain"):
            # CC-N8 (Schulz 2016 pp. 14-15 SC-7 double-exception note; Schulz 1990 for both
            # motifs; semantics = solve.reg_ccn8, KW-asserted at import): the CC-A2 gender
            # violation set is EXACTLY {A, A+1} AND both class positions also violate R-S2
            # (run-segmented adjacent pairing, solve._reg_rs2_violations). Locus (A, A+1) =
            # (25, 26); the ccn8-kwfail gate shifts it to (24, 25), which KW fails both ways.
            A = 24 if target == "ccn8-kwfail" else 25
            PMAX = A + 2
            # P[p][w]: the inversion class at class position p has popcount w (station
            # balance = 2w - 6, class-invariant since reversal preserves popcount — see
            # solve._reg_balances). Every position 1..36 is occupied exactly once in any
            # assignment satisfying the Y/E structure, so the (Y, E) -> P implications
            # force the true value and exactly-one kills the rest.
            P = {}
            for pp in range(1, PMAX + 1):
                P[pp] = {w: cnf.var() for w in range(7)}
                exactly_one(cnf, list(P[pp].values()))
            cnf.add(P[1][6]); cnf.add(P[2][0])   # slot 0 fixed by C4: Qian at 1, Kun at 2
            for st3 in SLOTS:
                for j in range(NJ):
                    p3, o3, first3, second3 = ORIENTS[j]
                    for c in E[st3 - 1]:
                        occ = [(st3 + 2 + c, pc(first3))]
                        if p3 in PALPAIRS:
                            occ.append((st3 + 3 + c, pc(second3)))
                        for ppos, w in occ:
                            if ppos <= PMAX:
                                cnf.add(-Y[(st3, j)], -E[st3 - 1][c], P[ppos][w])
            # R-S2 run-parity chain (recurrence asserted vs the solve-derived replica at
            # import): R[p] = "the next non-zero station opens a pair" after position p;
            # zero balance (popcount 3) closes the current run and resets.
            R = {0: cnf.var()}
            cnf.add(R[0])
            for ppos in range(1, A):
                R[ppos] = cnf.var()
                z = P[ppos][3]
                cnf.add(-z, R[ppos])                    # zero balance -> reset to opener
                cnf.add(z, R[ppos - 1], R[ppos])        # non-zero -> R[p] = NOT R[p-1]
                cnf.add(z, -R[ppos - 1], -R[ppos])
            ropen = R[A - 1]                            # position A opens a pair iff R[A-1]
            if tbase.startswith("ccn8-kwchain"):
                # two-way chain gate: pin r_24 to (kwchain) / against (kwchain-not) its
                # solve.py-derived KW value — validates the chain recurrence end-to-end
                want = KW_RS2_R24 if tbase == "ccn8-kwchain" else not KW_RS2_R24
                cnf.add(R[24] if want else -R[24])
            else:
                # (i) gender violations REQUIRED at A and A+1 (odd position: violating
                # popcounts {4,5}; even: {1,2} — parity table asserted at import)
                for ppos in (A, A + 1):
                    cnf.add(*[P[ppos][w] for w in ((4, 5) if ppos % 2 else (1, 2))])
                # (ii) ... and FORBIDDEN everywhere else (locus-exempt forbids)
                def viol_ex(h, pos5):
                    pck = bin(h).count("1")
                    if pck in (0, 3, 6) or pos5 in (A, A + 1): return False
                    return (pck < 3) != (pos5 % 2 == 1)
                for st5 in SLOTS:
                    for j in range(NJ):
                        p5, o5, first5, second5 = ORIENTS[j]
                        for c in E[st5 - 1]:
                            b5 = st5 + 2 + c
                            if p5 in PALPAIRS:
                                bad5 = viol_ex(first5, b5) or viol_ex(second5, b5 + 1)
                            else:
                                bad5 = viol_ex(first5, b5)
                            if bad5:
                                cnf.add(-Y[(st5, j)], -E[st5 - 1][c])
                # (iii) R-S2 violation at BOTH A and A+1 — exhaustive case analysis
                # asserted at import; (i) already forces A, A+1 non-zero (balances are
                # opposite iff popcounts sum to 6: (2w1-6)+(2w2-6) == 0 <=> w1+w2 == 6)
                for w1 in range(7):     # A opens: its closer A+1 must MISMATCH
                    cnf.add(-ropen, -P[A][w1], -P[A + 1][6 - w1])
                for w1 in range(7):     # A closes the pair opened at A-1: mismatch required
                    cnf.add(ropen, -P[A - 1][w1], -P[A][6 - w1])
                for w1 in range(7):     # then A+1 opens: orphan (zero at A+2) or mismatch
                    if 6 - w1 != 3:
                        cnf.add(ropen, -P[A + 1][w1], -P[A + 2][6 - w1])
        if target in ("rc4-kwtest", "rc4-kwexempt", "ccn4-kwtest",
                      "ccn8-kwtest", "ccn8-kwfail", "ccn8-kwchain", "ccn8-kwchain-not"):
            for st in SLOTS:
                jkw = next(j for j in range(NJ) if ORIENTS[j][0] == st and ORIENTS[j][1] == 0)
                cnf.add(Y[(st, jkw)])
    if target == "wrap-d5":
        # wrap distance 5 from s0=63  <=>  popcount(second hexagram of slot 31) == 1
        for j in range(NJ):
            if pc(ORIENTS[j][3]) != 1:
                cnf.add(-Y[(31, j)])
    if target == "kw-pin":
        # encoding validation: full KW pin, no extra rule clauses (pair with --with-c3 gates)
        for st in SLOTS:
            jkw = next(j for j in range(NJ) if ORIENTS[j][0] == st and ORIENTS[j][1] == 0)
            cnf.add(Y[(st, jkw)])
    if with_c3:
        # ---- native C3 (complement-distance ceiling; see C3 static facts above) ----
        # gated on with_c3 ONLY: no clause here may reach any other target's build path.
        # C3(seq) = 2*|C3_SELFC| + 8*S where S = sum over C3_COUPLES of |slot(u)-slot(v)|,
        # so C3 <= M  <=>  S <= (M - 2*|C3_SELFC|) // 8.  M=776 -> S<=95; M=775 -> S<=94.
        bound = KW_C3 if c3_max is None else c3_max
        sbudget = (bound - 2 * len(C3_SELFC)) // 8
        # X[p][s] = "pair p occupies slot s" (one-directional Y -> X suffices: spurious-true X
        # only over-approximates S, so the <= bound stays sound; solver sets non-forced X false)
        cmembers = sorted(set(u for u, v in C3_COUPLES) | set(v for u, v in C3_COUPLES))
        X = {}
        for p in cmembers:
            for s in SLOTS:
                X[(p, s)] = cnf.var()
            for j in range(NJ):
                if ORIENTS[j][0] == p:
                    for s in SLOTS:
                        cnf.add(-Y[(s, j)], X[(p, s)])
        # per-couple unary distance lits G[c][k] = "|slot(u)-slot(v)| >= k", k = 2..30
        # (k=1 always holds: two pairs never share a slot), forced by slot-pair clauses + chain
        dlits = []
        for (u, v) in C3_COUPLES:
            G = {k: cnf.var() for k in range(2, 31)}
            for s in SLOTS:
                for t in SLOTS:
                    if abs(s - t) >= 2:
                        cnf.add(-X[(u, s)], -X[(v, t)], G[abs(s - t)])
            for k in range(3, 31):
                cnf.add(-G[k], G[k - 1])
            dlits += [G[k] for k in range(2, 31)]
        # S = |C3_COUPLES| + (# true dlits)  =>  bound the unary sum
        at_most_k(cnf, dlits, sbudget - len(C3_COUPLES))
    return cnf, Y

def decode(model_lits, Y):
    seq = [63, 0]
    tru = set(l for l in model_lits if l > 0)
    for s in SLOTS:
        for j in range(NJ):
            if Y[(s, j)] in tru:
                seq += [ORIENTS[j][2], ORIENTS[j][3]]
                break
    return seq

def verify_seq(seq):
    ok = len(seq) == 64 and len(set(seq)) == 64
    ok = ok and solve.has_no_five(seq)
    from collections import Counter
    ok = ok and dict(Counter(solve.bit_diff(seq[i], seq[i+1]) for i in range(63))) == _tot
    pos = {h: i for i, h in enumerate(seq)}
    c3 = sum(abs(pos[h] - pos[h ^ 63]) for h in range(64))
    return ok, c3

if __name__ == "__main__":
    args = sys.argv[1:]
    with_c3, c3_max = False, None
    if "--with-c3" in args:
        with_c3 = True; args.remove("--with-c3")
    if "--c3-max" in args:
        i = args.index("--c3-max")
        with_c3, c3_max = True, int(args[i + 1]); del args[i:i + 2]
    if args[:1] == ["--emit-cnf"] and len(args) == 3:
        cnf, Y = build(args[1], with_c3=with_c3, c3_max=c3_max)
        cnf.write(args[2], "target=" + args[1] + (" c3<=%d" % (c3_max or KW_C3) if with_c3 else ""))
        print("vars=%d clauses=%d -> %s" % (cnf.n, len(cnf.cl), args[2]))
    elif args[:1] == ["--witness"] and len(args) == 2:
        target = args[1]
        cnf, Y = build(target, with_c3=with_c3, c3_max=c3_max)
        import tempfile
        for attempt in range(200):
            f = tempfile.NamedTemporaryFile("w", suffix=".cnf", delete=False)
            cnf.write(f.name, "target=" + target)
            r = subprocess.run(["kissat", "-q", f.name], capture_output=True, text=True)
            os.unlink(f.name)
            if "s SATISFIABLE" not in r.stdout:
                print("UNSAT (or solver error) at attempt", attempt); print(r.stdout[-400:]); break
            lits = []
            for ln in r.stdout.splitlines():
                if ln.startswith("v "):
                    lits += [int(x) for x in ln[2:].split() if x != "0"]
            seq = decode(lits, Y)
            ok, c3 = verify_seq(seq)
            print("attempt %d: verify=%s c3=%d %s" % (attempt, ok, c3, "<=776 PASS" if c3 <= 776 else "fail C3, blocking"))
            if ok and c3 <= 776:
                print("WITNESS:", seq); break
            cnf.add(*[-Y[(s, j)] for s in SLOTS for j in range(NJ) if Y[(s, j)] in set(l for l in lits if l > 0)])
    else:
        print(__doc__)
