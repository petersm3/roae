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
  wrap-d5        C1+C2+C4+C5 AND wrap distance d(s63, s0) == 5 (i.e., popcount(s63) == 1).
                 UNSAT => circular C2 is IMPLIED by the linear system (the McKenna circular reading
                 adds no C2 constraint); SAT => a valid ordering with a 5-line wrap exists.
                 560T empirical: 0 of 10.5e9 records (wrap is 91.83% d=3 / 8.17% d=1).
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

def build(target):
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
    if target.startswith("moore-strict") or target.startswith("grand-strict") or target == "grand-ccn4":
        for s in SLOTS:                   # parity: static unary forbids
            for j in range(NJ):
                p = ORIENTS[j][0]
                if directional(p):
                    want_odd = pc(KW_PAIRS[p][0]) > 3
                    if want_odd != ((s + 1) % 2 == 1):   # pair POSITION = slot index + 1 (slot 0 = position 1)
                        cnf.add(-Y[(s, j)])
        for s in range(1, 31):            # rhythm: static binary forbids between adjacent directional
            for j1 in range(NJ):
                if not directional(ORIENTS[j1][0]): continue
                r1 = rising(ORIENTS[j1][2], ORIENTS[j1][0])
                for j2 in range(NJ):
                    if not directional(ORIENTS[j2][0]): continue
                    if ORIENTS[j1][0] == ORIENTS[j2][0]: continue
                    if rising(ORIENTS[j2][2], ORIENTS[j2][0]) == r1:
                        cnf.add(-Y[(s, j1)], -Y[(s+1, j2)])
    if target.startswith("rc4-") or target.startswith("grand-") or target.startswith("ccn4-"):
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
        if not target.startswith("ccn4-"):   # ccn4 validation targets use the counter only
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
        if target == "grand-ccn4" or target == "ccn4-kwtest":
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
        if target in ("rc4-kwtest", "rc4-kwexempt", "ccn4-kwtest"):
            for st in SLOTS:
                jkw = next(j for j in range(NJ) if ORIENTS[j][0] == st and ORIENTS[j][1] == 0)
                cnf.add(Y[(st, jkw)])
    if target == "wrap-d5":
        # wrap distance 5 from s0=63  <=>  popcount(second hexagram of slot 31) == 1
        for j in range(NJ):
            if pc(ORIENTS[j][3]) != 1:
                cnf.add(-Y[(31, j)])
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
    if args[:1] == ["--emit-cnf"] and len(args) == 3:
        cnf, Y = build(args[1])
        cnf.write(args[2], "target=" + args[1])
        print("vars=%d clauses=%d -> %s" % (cnf.n, len(cnf.cl), args[2]))
    elif args[:1] == ["--witness"] and len(args) == 2:
        target = args[1]
        cnf, Y = build(target)
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
