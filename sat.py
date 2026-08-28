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
  --decode MODEL.txt [TARGET]   decode a solver model (v-lines, or a bare int list) back to a
                                hexagram sequence and re-verify vs solve.py (TARGET default
                                'plain'; add --f1-pairs N to decode a reduced-subset model)
  --witness TARGET              emit CNF, run the external solver (REQUIRES kissat on PATH;
                                exits with a clear install message if missing), decode, verify,
                                iterate blocking clauses until a C3-passing witness is found
  --rigidity-cnf OUT.cnf [--run]  TR-5 v2.0 symmetry-completeness rigidity kernel [expect UNSAT]:
                                G5-automorphism fixing 0 + its six d5-neighbors pointwise, != id.
                                Emits + self-validates the CNF; with --run, decides via kissat
                                (DRAT proof to OUT.cnf.drat, drat-trim verified when on PATH).
  --certify-count TARGET        emit CNF, compile it with D4 (d-DNNF), then generate + verify a
                                CPOG certificate (cpog-gen / cpog-check) and print the CERTIFIED
                                model count. REQUIRES the OPTIONAL external binaries d4,
                                cpog-gen, cpog-check on PATH — no other subcommand needs them;
                                if absent this exits gracefully with a clear install message and
                                the rest of sat.py is unaffected (see SAT_CLI.md). Combine with
                                --f1-pairs N for the reduced-subset certified-count probe
                                (TASK #225 §6.4); the native reference count to compare against
                                comes from `solve --f1-exact-c1c2c4c5 --f1-pairs N` (run by the
                                caller — sat.py never invokes solve.c).
Modifiers:
  --f1-pairs N                  build the REDUCED C1&C2&C4&C5 instance for the group-closed
                                N-pair orbit union (N in {9,13,16,18,19,24,25,27,28}) — the
                                object `solve --f1-exact-c1c2c4c5 --f1-pairs N` counts. Applies
                                to --emit-cnf, --decode and --certify-count; the C5 budget B0 is
                                derived per subset (deterministic-DFS, solve.c f1c5 semantics).
                                This is the small-n certified-count probe instance (#225 §6.4).
  --expect N                    (--certify-count only) assert certified count == N; prints
                                PASS/FAIL and exits nonzero on FAIL
  --keep DIR                    (--certify-count only) preserve instance.cnf/.nnf/.cpog in DIR
                                (default: a temporary directory, removed after the run)
Targets:
  alt-le-14      C1+C2+C4+C5 AND (odd between-pair transitions <= 14)   [expect UNSAT]
  alt-ge-16      C1+C2+C4+C5 AND (odd between-pair transitions >= 16)   [expect UNSAT]
                 (both UNSAT == SAT-certified parity-alternation theorem, PARITY_ALTERNATION.md)
  moore-strict   C1+C2+C4+C5 AND Moore-2005 parity (all 18) AND Moore-1989 rhythm (0 breaks)
                 [expect SAT -> explicit witness ordering; C3 enforced by verify-loop]
                 (attribution: Moore 2005 Oracle Papers No.1; Moore 1989 Trigrams of Han App.2)
  moore-kwtest   encoding validation: KW forced + strict Moore-2005 parity clauses
                 [expect UNSAT — solve.r11_axes scores KW at EXACTLY 2 parity violations;
                 tests.py counts the 2 conflict loci + decides UNSAT solver-free by unit prop.]
  rhythm-kwtest  encoding validation: KW forced + strict Moore-1989 rhythm clauses
                 [expect UNSAT — KW has EXACTLY 2 rhythm breaks; same solver-free gate]
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
  ccn4-kwfail    encoding validation: KW forced + ccn4 clauses with the required S25-28
                 faces PERMUTED (S25<->S26 and S27<->S28 values swapped)  [expect UNSAT —
                 KW's faces are the import-derived CCN4_REQ, mismatching all 4 stations;
                 the over-constraint counter-gate that ccn4-kwtest alone cannot provide]
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
                 (values below the structural minimum C3 = 112 are refused: no C1 layout attains them)
  --c3-min N     encode C3 >= N (the >= side of the unary couple-distance ladder; does NOT
                 imply the <= 776 ceiling — combine with --c3-max to window C3 exactly).
                 Unlike the relaxed one-directional <= encoding, the >= side is made EXACT
                 (two-sided X<->Y binding + spurious-true distance-lit kill clauses), so a
                 model's ladder value equals the decoded ordering's true couple-distance sum.
                 Used by the C3 positional certificates (above-ceiling witness G >= 96, i.e.
                 --c3-min 784, and the G = 95 tie witness via --c3-min 776 --c3-max 776).
  --not-kw       exclude every ordering whose pair-slot LAYOUT matches King Wen's (slot s =
                 pair s for all s) — i.e. KW itself AND all its within-pair orientation
                 variants. Since that excluded set contains KW, any witness is != KW, and
                 stronger: it places at least one pair in a non-KW slot (tie certificate;
                 an orientation-only variant would tie G trivially, as G is orientation-blind)
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

# ---- CC-N4 static facts (Schulz S25-28 dui configuration), derived from solve imports ----
# ATTRIBUTION: CC-N4 = Schulz 2016 (Hexagrammatics) pp. 23-24; Schulz 2011 (JCP 38:4).
# Semantics = solve.reg_ccn4: the face (canonical, first-appearing) hexagrams of stations
# 25-28 carry upper trigram Dui with lower trigrams Qian/Kun/Kan/Li. Until 2026-08-01 the
# encoder hard-coded the four required face values (finding A6, SAT review) — a violation
# of the header rule. They are DERIVED here instead: (upper, lower) trigrams determine a
# hexagram uniquely (asserted below), so reg_ccn4's per-station condition pins exactly ONE
# face value each, and since KW satisfies CC-N4 (asserted), KW's own station faces — read
# off solve._reg_stations, the same first-appearance machinery reg_ccn4 itself uses — ARE
# those required values. No literal survives.
assert solve.reg_ccn4(KW) is True, "CC-N4 KW ground truth broke"
assert all((solve.upper_trigram(h) << 3) | solve.lower_trigram(h) == h for h in range(64)), \
    "trigram-pair bijection broke"
CCN4_STATIONS = (25, 26, 27, 28)
_st_kw = solve._reg_stations(KW)
CCN4_REQ = {s: _st_kw[s - 1][0] for s in CCN4_STATIONS}
# the required faces are inversion-asymmetric — the encoder's palindrome-pair in-window
# forbid ("a palindrome face can never match") is sound only because of this:
assert all(solve.reverse_6bit(v) != v for v in CCN4_REQ.values()), "CC-N4 face palindromicity broke"

def _ccn4_predict(seq):
    """Validation-only replica of the CNF's CC-N4 clause semantics: the station-25..28
    faces (solve._reg_stations canonicalisation) equal the derived CCN4_REQ. Asserted
    == solve.reg_ccn4 on KW, 300 seeded random permutations and targeted mutants below
    — same discipline as the R-S2 balance replica and the Moore endorsement."""
    st = solve._reg_stations(seq)
    return all(st[s - 1][0] == CCN4_REQ[s] for s in CCN4_STATIONS)

_rng_c4 = _random.Random(2016)
for _t in range(300):
    _perm = list(range(64)); _rng_c4.shuffle(_perm)
    assert _ccn4_predict(_perm) == solve.reg_ccn4(_perm), "CC-N4 replica/scorer drift"
# targeted mutants (random permutations are near-always False on both sides, so also
# probe the boundary): (i) orientation flip of the pair holding station 25's class —
# stations unchanged, the face becomes its reversal (non-palindromic, so != REQ) ->
# False; (ii) the pairs holding stations 25/26 swapped -> faces permuted -> False;
# (iii) two non-palindrome pairs BEFORE the window swapped — class positions >= the
# window are unchanged, so CC-N4 stays True on a non-KW sequence (positive control).
_c4slot = {s: PAIR_IDX[frozenset(_st_kw[s - 1][1])] for s in CCN4_STATIONS}
def _kw_mut(swaps=(), flips=()):
    m = list(KW)
    for p in flips:
        m[2*p], m[2*p+1] = m[2*p+1], m[2*p]
    for p, q in swaps:
        m[2*p:2*p+2], m[2*q:2*q+2] = m[2*q:2*q+2], m[2*p:2*p+2]
    return m
_c4early = [p for p in range(1, min(_c4slot.values()))
            if solve.reverse_6bit(KW_PAIRS[p][0]) != KW_PAIRS[p][0]][:2]
assert len(_c4early) == 2, "CC-N4 positive-control mutant needs 2 early non-palindrome pairs"
for _mut, _want in ((_kw_mut(flips=(_c4slot[25],)), False),
                    (_kw_mut(swaps=((_c4slot[25], _c4slot[26]),)), False),
                    (_kw_mut(swaps=(tuple(_c4early),)), True)):
    assert _mut != KW and _ccn4_predict(_mut) == solve.reg_ccn4(_mut) == _want, \
        "CC-N4 mutant endorsement broke"
# ccn4-kwfail table: the required faces PERMUTED (S25<->S26 and S27<->S28 values
# swapped) — derived from CCN4_REQ, not hand-written. A derangement on distinct
# values, so KW pinned against it must mismatch at ALL FOUR stations [expect UNSAT]:
CCN4_REQ_FAIL = {25: CCN4_REQ[26], 26: CCN4_REQ[25], 27: CCN4_REQ[28], 28: CCN4_REQ[27]}
assert all(_st_kw[_s - 1][0] != CCN4_REQ_FAIL[_s] for _s in CCN4_STATIONS), \
    "ccn4-kwfail derangement broke (KW matches a permuted face)"

# ---- Moore parity/rhythm static facts, DERIVED from solve.r11_axes (F-1) ----
# ATTRIBUTION: g1 = Moore 2005 (Oracle Papers No.1) pair-positioning parity; g2 =
# Moore 1989 (Trigrams of Han App.2) rising/falling rhythm. Until 2026-07-19 this
# file carried hand-written directional()/rising() helpers duplicating solve.py's
# g1/g2 logic — a violation of the header rule (finding F-1, TR-2 review). The
# encoder tables below are instead extracted from solve.r11_axes — the single
# authoritative scorer (byte-for-byte twin of solve.c r11_axes; KW = 2 parity
# violations, 2 rhythm breaks) — so the encoding cannot silently diverge from the
# engine; verify_seq routes through the same scorer (_moore_scores), closing the
# round-trip. r11_axes needs a full orientation-resolved pair permutation (its
# g3/g7/g8 station machinery), so the extraction uses exact DIFFERENCING over
# valid arrangements: parity compliance via controlled slot swaps (g1 is a sum
# of per-(pair, position-parity) terms, so one swap isolates D_p - D_q exactly),
# rhythm breaks via an exempt-buffered adjacency probe (g2 ignores absolute
# position, so moving one probe pair behind an exempt buffer changes g2 by
# exactly the probed break). The decomposition hypotheses behind both schemes
# are themselves validated by the 300-arrangement randomized endorsement below
# (predicted == r11_axes) — the same discipline as the R-S2 replica above.

def _moore_scores(seq):
    """(Moore-2005 parity violations, Moore-1989 rhythm breaks) of a 64-hexagram
    sequence via solve.r11_axes (g1, g2) — the ONLY Moore parity/rhythm scorer
    in this file; the encoder tables and verify_seq both route through it."""
    g = solve.r11_axes(seq)
    return g[0], g[1]

def _po_hexes(p, o):
    a, b = KW_PAIRS[p]
    return (a, b) if o == 0 else (b, a)

def _arr_seq(arrangement):
    """[(pair, orient)] for slots 1..31 -> full 64-seq (slot 0 = pair 0)."""
    seq = [63, 0]
    for p, o in arrangement:
        seq += list(_po_hexes(p, o))
    return seq

def _g1(a): return _moore_scores(_arr_seq(a))[0]
def _g2(a): return _moore_scores(_arr_seq(a))[1]

_A0 = [(p, 0) for p in range(1, 32)]              # the KW arrangement itself
_g1_0 = _g1(_A0)
# --- parity: D_p := c(p, odd) - c(p, even), c = g1-compliance indicator.
# Swapping pair p with a fixed opposite-parity reference slot isolates D_p - D_ref
# exactly; pair p sits at slot p = 1-based position p+1 (odd iff p even), refs are
# slot 1 (pair 1, position 2, even) and slot 2 (pair 2, position 3, odd).
_d_rel = {}                                       # p -> ("D1"|"D2", D_p - D_ref)
for _p in range(2, 32):
    _sw = list(_A0)
    if _p % 2 == 0:                               # p at odd position: swap with slot 1
        _sw[_p - 1], _sw[0] = _sw[0], _sw[_p - 1]
        _d_rel[_p] = ("D1", _g1(_sw) - _g1_0)     # g1 delta = D_p - D_1
    else:                                         # p at even position: swap with slot 2
        _sw[_p - 1], _sw[1] = _sw[1], _sw[_p - 1]
        _d_rel[_p] = ("D2", _g1_0 - _g1(_sw))     # g1 delta = D_2 - D_p
# absolute pin via rotations: S(A) := 18 - g1(A) = sum_p c(p, parity_A(p));
# rotating flips the position parity of 30 of the 31 pairs, giving
# sum_p T_p (T_p := c(p,odd)+c(p,even)) up to a known D correction:
#   S0 + S1  = sum T - D_31   (pair 31 stays even),  S0 + S1b = sum T - D_1.
# T_p >= |D_p| with equality iff no pair is dual-compliant and every D=0 pair is
# exempt — so requiring sum|D| == sum T pins the one true D_1 in {-1,0,1}.
_A1, _A1b = [_A0[-1]] + _A0[:-1], _A0[1:] + [_A0[0]]
_S0, _S1, _S1b = 18 - _g1_0, 18 - _g1(_A1), 18 - _g1(_A1b)
_dsol = []
for _d1 in (-1, 0, 1):
    _D = {1: _d1, 2: _d1 + _d_rel[2][1]}
    for _p in range(3, 32):
        _tag, _v = _d_rel[_p]
        _D[_p] = (_D[1] if _tag == "D1" else _D[2]) + _v
    if all(_d in (-1, 0, 1) for _d in _D.values()) and \
       _S0 + _S1 + _D[31] == _S0 + _S1b + _D[1] == sum(abs(_d) for _d in _D.values()):
        _dsol.append(dict(_D))
assert len(_dsol) == 1, "parity differencing under-determined (%d candidates)" % len(_dsol)
_D = _dsol[0]
MOORE_COUNTED = {p: _D[p] != 0 for p in range(1, 32)}   # scored by g1/g2 ("directional")
MOORE_WANT_ODD = {p: _D[p] == 1 for p in range(1, 32) if _D[p] != 0}
assert sum(MOORE_COUNTED.values()) == 18, "expected 18 counted (directional) pairs"
for _p in range(1, 32):                           # g1 must be orientation-blind
    for _base in (_A0, _A1):                      # (checks pair _p at both parities)
        _fl = list(_base)
        _fl[_fl.index((_p, 0))] = (_p, 1)
        assert _g1(_fl) == _g1(_base), "g1 orientation-dependent at pair %d" % _p

# --- rhythm: MOORE_BREAK[(po1, po2)] = 1 iff placing po2 directly after po1
# (both counted) breaks the rising/falling alternation. Probed EXHAUSTIVELY for
# all 1224 ordered counted (pair, orient) adjacencies: g2 is position-blind and
# resets at exempt pairs, so [e1, po1, po2, e2, e3, rest] minus
# [e1, po1, e2, po2, e3, rest] isolates exactly the (po1, po2) break.
_EXEMPT = sorted(p for p in range(1, 32) if not MOORE_COUNTED[p])
_CO = [(p, o) for p in range(1, 32) if MOORE_COUNTED[p] for o in (0, 1)]
_e1, _e2, _e3 = _EXEMPT[:3]
MOORE_BREAK = {}
for _po1 in _CO:
    for _po2 in _CO:
        if _po1[0] == _po2[0]:
            continue                              # a pair never occupies two slots
        _rest = [(p, 0) for p in range(1, 32)
                 if p not in (_e1, _e2, _e3, _po1[0], _po2[0])]
        _adj = [(_e1, 0), _po1, _po2, (_e2, 0), (_e3, 0)] + _rest
        _sep = [(_e1, 0), _po1, (_e2, 0), _po2, (_e3, 0)] + _rest
        _br = _g2(_adj) - _g2(_sep)
        assert _br in (0, 1), "rhythm adjacency probe not isolated"
        MOORE_BREAK[(_po1, _po2)] = _br
for (_po1, _po2), _b in MOORE_BREAK.items():      # sanity: relation is symmetric
    assert MOORE_BREAK[(_po2, _po1)] == _b, "rhythm break relation asymmetric"
# sanity: the probed relation is a two-class (rising/falling) equality relation
_ref = _CO[0]
_cls = {_ref: 0}
for _po in _CO:                                   # other pairs: classify against ref
    if _po[0] != _ref[0]:
        _cls[_po] = _cls[_ref] if MOORE_BREAK[(_ref, _po)] else 1 - _cls[_ref]
_sib = (_ref[0], 1 - _ref[1])                     # ref's orientation-sibling: via _CO[2]
_cls[_sib] = _cls[_CO[2]] if MOORE_BREAK[(_CO[2], _sib)] else 1 - _cls[_CO[2]]
for (_po1, _po2), _b in MOORE_BREAK.items():
    assert _b == (1 if _cls[_po1] == _cls[_po2] else 0), "break relation not 2-colorable"

def _moore_predict(arrangement):
    """(g1, g2) predicted by the derived tables for [(pair, orient)] in slots
    1..31 (slot 0 = pair 0, exempt -> resets the rhythm chain). Validation-only
    replica of the CNF clause semantics — asserted against solve.r11_axes."""
    okc = sum(1 for s, (p, o) in enumerate(arrangement, start=1)
              if MOORE_COUNTED[p] and MOORE_WANT_ODD[p] == ((s + 1) % 2 == 1))
    g2, prev = 0, None
    for po in arrangement:
        if not MOORE_COUNTED[po[0]]:
            prev = None
            continue
        if prev is not None and MOORE_BREAK[(prev, po)]:
            g2 += 1
        prev = po
    return 18 - okc, g2

# whole-sequence endorsement: table-predicted (g1, g2) == solve.r11_axes on KW
# (== the published 2 parity violations / 2 rhythm breaks) + 300 seeded random
# arrangements (pair permutation x orientations) — validating the differencing
# hypotheses above on full sequences, same discipline as the R-S2 replica.
assert _moore_predict(_A0) == _moore_scores(KW) \
    == tuple(solve.R11_KW_EXPECTED[:2]) == (2, 2), "KW Moore ground truth broke"
_rng_m = _random.Random(191)
for _t in range(300):
    _pp = list(range(1, 32)); _rng_m.shuffle(_pp)
    _arr = [(_p, _rng_m.randint(0, 1)) for _p in _pp]
    assert _moore_predict(_arr) == _moore_scores(_arr_seq(_arr)), "Moore table/scorer drift"

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
    if k < 0:
        raise ValueError("at_most_k: negative bound k=%d over %d literals; "
                         "an impossible cardinality must be refused by the "
                         "caller, not encoded" % (k, n))
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
    "moore-kwtest": ("parity",), "rhythm-kwtest": ("rhythm",),
    "grand-strict": ("parity", "rhythm", "gender"),
    "rc4-strict": ("gender",), "rc4-kwtest": ("gender",), "rc4-kwexempt": ("gender",),
    "ccn4-kwtest": ("ccn4",), "ccn4-kwfail": ("ccn4",),
    "grand-ccn4": ("parity", "rhythm", "gender", "ccn4"),
    "grander-strict": FIVE_RULES,                       # the five-rule union
    "gender-ccn8": ("gender", "ccn8"),                  # the 2-rule core
    "ccn8-kwtest": ("ccn8",), "ccn8-kwfail": ("ccn8",),
    "ccn8-kwchain": (), "ccn8-kwchain-not": (),         # chain machinery only
}
for _r in FIVE_RULES:
    RULESETS["five-loo-" + _r] = tuple(x for x in FIVE_RULES if x != _r)


def build_rigidity():
    """TR-5 v-next rigidity kernel as CNF [expect UNSAT] (2026-07-18).

    Instance: a bijection sigma on the 64 hexagrams that is edge-preserving on
    G5 (the Hamming-distance-5 graph; adjacency derived from solve.bit_diff —
    no hand-written semantics), fixes 0 and every distance-5 neighbor of 0
    pointwise, yet differs from the identity somewhere. UNSAT certifies the
    SC-4 rigidity kernel of the symmetry-completeness theorem
    (solve.py --symmetry-completeness; prose: SYMMETRY_SEARCH.md).

    Encoding note (deliberate relaxation = STRONGER certificate): only
    bijection + one-directional edge-support clauses are encoded. Every true
    G5-automorphism satisfies these, so UNSAT of this relaxed instance implies
    no qualifying automorphism exists. Returns (cnf, x) with x[v][w] <=>
    sigma(v) = w."""
    cnf = CNF()
    H = range(64)
    x = [[cnf.var() for _ in H] for _ in H]
    for v in H:
        exactly_one(cnf, [x[v][w] for w in H])       # total + injective rows
    for w in H:
        exactly_one(cnf, [x[v][w] for v in H])       # bijection (columns)
    nbr = [[b for b in H if solve.bit_diff(a, b) == 5] for a in H]
    for v in H:
        for vp in nbr[v]:
            for w in H:                              # v~v' => sigma(v')~sigma(v)
                cnf.add(-x[v][w], *[x[vp][wp] for wp in nbr[w]])
    anchors = [0] + nbr[0]                           # 0 and N5(0), fixed pointwise
    for v in anchors:
        cnf.add(x[v][v])
    cnf.add(*[-x[v][v] for v in H])                  # sigma != identity
    return cnf, x


def rigidity_validate(cnf, x):
    """Round-trip discipline: the identity assignment must satisfy every
    clause EXCEPT the final not-identity clause (encoding sanity), and a
    non-anchor-fixing known automorphism (bit-reversal, from
    solve.reverse_6bit) must violate an anchor unit (negative control)."""
    ident = set()
    for v in range(64):
        for w in range(64):
            if v == w:
                ident.add(x[v][w])
    unsat_by_ident = [c for c in cnf.cl
                      if not any((l > 0 and l in ident) or
                                 (l < 0 and -l not in ident) for l in c)]
    ok1 = len(unsat_by_ident) == 1 and unsat_by_ident[0] == \
        [-x[v][v] for v in range(64)]
    rev_fix = all(solve.reverse_6bit(v) == v for v in [0] +
                  [b for b in range(64) if solve.bit_diff(0, b) == 5])
    ok2 = not rev_fix   # bit-reversal moves at least one anchor => excluded
    return ok1 and ok2


def target_rules(target):
    """Literature rules enforced strictly by `target` (shared by build() and the
    witness verify-loop's decoded-witness rule re-scoring)."""
    tbase = target.split("-near-")[0]
    if tbase.startswith("five-sub-"):
        # generic subset of the five-rule family, e.g. five-sub-parity+ccn8
        # (used to map the conflict lattice / minimal unsatisfiable cores, task #217)
        rules = set(tbase[len("five-sub-"):].split("+"))
        if not rules <= set(FIVE_RULES):
            raise SystemExit("unknown rules in target: " + target)
        return rules
    if tbase not in RULESETS:
        raise SystemExit("unknown target: " + target)
    return set(RULESETS[tbase])

def build(target, with_c3=False, c3_max=None, c3_min=None, not_kw=False):
    tbase = target.split("-near-")[0]
    rules = target_rules(target)
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
        try:
            k = int(target.rsplit("-", 1)[1])
        except ValueError:
            raise SystemExit("bad -near- suffix in target %r: "
                             "expected an integer slot count" % target)
        agree = []
        for s in SLOTS:
            jkw = next(j for j in range(NJ) if ORIENTS[j][0] == s and ORIENTS[j][1] == 0)
            agree.append(Y[(s, jkw)])
        at_least_k(cnf, agree, 31 - k)
    if "parity" in rules:
        for s in SLOTS:                   # parity: static unary forbids (tables derived from solve.r11_axes g1)
            for j in range(NJ):
                p = ORIENTS[j][0]
                if MOORE_COUNTED[p]:
                    if MOORE_WANT_ODD[p] != ((s + 1) % 2 == 1):   # pair POSITION = slot index + 1 (slot 0 = position 1)
                        cnf.add(-Y[(s, j)])
    if "rhythm" in rules:
        for s in range(1, 31):            # rhythm: static binary forbids between adjacent counted pairs
            for j1 in range(NJ):          # (MOORE_BREAK probed exhaustively from solve.r11_axes g2)
                po1 = (ORIENTS[j1][0], ORIENTS[j1][1])
                if not MOORE_COUNTED[po1[0]]: continue
                for j2 in range(NJ):
                    po2 = (ORIENTS[j2][0], ORIENTS[j2][1])
                    if not MOORE_COUNTED[po2[0]]: continue
                    if po1[0] == po2[0]: continue
                    if MOORE_BREAK[(po1, po2)]:
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
            # hexagrams must equal CCN4_REQ — DERIVED at import from solve.reg_ccn4 via KW's own
            # station faces (= 31, 24, 26, 29: upper trigram dui, lowers qian/kun/kan/li; the
            # literal was hand-written until finding A6, 2026-08-01 SAT review). ccn4-kwfail
            # swaps the required values (CCN4_REQ_FAIL) under the KW pin [expect UNSAT — KW
            # mismatches all four stations, asserted at import]. Same E-counter: station of
            # slot s (inverse pair) = s+2+c; palindrome pairs occupy (s+2+c, s+3+c) and can
            # never match (faces are palindromes; the REQ values are asserted non-palindromic
            # at import) -> forbidden in-window.
            REQ = CCN4_REQ_FAIL if target == "ccn4-kwfail" else CCN4_REQ
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
        if target in ("rc4-kwtest", "rc4-kwexempt", "ccn4-kwtest", "ccn4-kwfail",
                      "ccn8-kwtest", "ccn8-kwfail", "ccn8-kwchain", "ccn8-kwchain-not"):
            for st in SLOTS:
                jkw = next(j for j in range(NJ) if ORIENTS[j][0] == st and ORIENTS[j][1] == 0)
                cnf.add(Y[(st, jkw)])
    if target == "wrap-d5":
        # wrap distance 5 from s0=63  <=>  popcount(second hexagram of slot 31) == 1
        for j in range(NJ):
            if pc(ORIENTS[j][3]) != 1:
                cnf.add(-Y[(31, j)])
    if target in ("kw-pin", "moore-kwtest", "rhythm-kwtest"):
        # kw-pin: full KW pin, no extra rule clauses (pair with --with-c3 gates).
        # moore-kwtest / rhythm-kwtest (F-1 gates): KW pin + the strict parity /
        # rhythm clauses added above — UNSAT with conflicts at EXACTLY the
        # solve.r11_axes-scored loci (2 parity violations / 2 rhythm breaks);
        # tests.py decides both solver-free via unit propagation.
        for st in SLOTS:
            jkw = next(j for j in range(NJ) if ORIENTS[j][0] == st and ORIENTS[j][1] == 0)
            cnf.add(Y[(st, jkw)])
    if not_kw:
        # exclude KW's pair-slot LAYOUT (slot s = pair s, either orientation): a[s] <->
        # "slot s holds pair s", then require some a[s] false. The excluded set is exactly
        # {KW and its 2^31 within-pair orientation variants} — a subset of "!= KW", so any
        # model decodes to an ordering != KW, and stronger: some pair sits in a non-KW slot
        # (G is orientation-blind, so an orientation-only variant would tie G trivially)
        akw = []
        for s in SLOTS:
            a = cnf.var()
            own = [Y[(s, j)] for j in range(NJ) if ORIENTS[j][0] == s]
            cnf.add(-a, *own)
            for y in own:
                cnf.add(-y, a)
            akw.append(a)
        cnf.add(*[-a for a in akw])
    if with_c3 or c3_min is not None:
        # ---- native C3 (complement-distance ceiling; see C3 static facts above) ----
        # gated on with_c3/--c3-min ONLY: no clause here may reach any other target's build path.
        # C3(seq) = 2*|C3_SELFC| + 8*S where S = sum over C3_COUPLES of |slot(u)-slot(v)|,
        # so C3 <= M  <=>  S <= (M - 2*|C3_SELFC|) // 8.  M=776 -> S<=95; M=775 -> S<=94.
        # When c3_min is None the emitted CNF is BYTE-IDENTICAL to the pre---c3-min encoding
        # (the 2026-07-22-verified floor-safe map) — every new clause below is c3_min-gated.
        bound = KW_C3 if c3_max is None else c3_max
        sbudget = (bound - 2 * len(C3_SELFC)) // 8
        if with_c3 and sbudget < len(C3_COUPLES):
            raise SystemExit(
                "--c3-max %d is below the structural minimum C3 = %d "
                "(2*%d self-complementary pairs + 8*%d complement couples at "
                "slot distance >= 1): unsatisfiable for every C1 layout"
                % (bound, 2 * len(C3_SELFC) + 8 * len(C3_COUPLES),
                   len(C3_SELFC), len(C3_COUPLES)))
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
        if c3_min is not None:
            # >= side needs EXACT X: a spurious-true X could inflate S and fake the lower
            # bound. X -> Y support (with the exactly-one-per-pair Y structure this makes
            # X[(p, s)] <-> "pair p occupies slot s")
            for p in cmembers:
                for s in SLOTS:
                    cnf.add(-X[(p, s)],
                            *[Y[(s, j)] for j in range(NJ) if ORIENTS[j][0] == p])
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
            if c3_min is not None:
                # >= side: kill spurious-true distance lits — if the couple's true slot
                # distance is d, G[d+1] must be false (the k-chain above then pulls every
                # higher G[k] false too), so #true dlits per couple == d - 1 exactly
                for s in SLOTS:
                    for t in SLOTS:
                        if s != t and abs(s - t) + 1 <= 30:
                            cnf.add(-G[abs(s - t) + 1], -X[(u, s)], -X[(v, t)])
            dlits += [G[k] for k in range(2, 31)]
        # S = |C3_COUPLES| + (# true dlits)  =>  bound the unary sum
        if with_c3:
            at_most_k(cnf, dlits, sbudget - len(C3_COUPLES))
        if c3_min is not None:
            # C3 >= m  <=>  S >= ceil((m - 2*|C3_SELFC|) / 8); S = |couples| + #true dlits
            s_lower = -((c3_min - 2 * len(C3_SELFC)) // -8)
            if s_lower - len(C3_COUPLES) > len(dlits):
                raise SystemExit("--c3-min %d exceeds the encodable maximum" % c3_min)
            if s_lower > len(C3_COUPLES):
                at_least_k(cnf, dlits, s_lower - len(C3_COUPLES))
    return cnf, Y

# ============================================================================
# Small-n subset instances — the C1&C2&C4&C5 certified-count probe (TASK #225).
# ----------------------------------------------------------------------------
# Emits the *reduced* C1&C2&C4&C5 CNF for a group-closed N-pair orbit union
# (N in {9,13,16,18,19,24,25,27,28}), i.e. the exact object that
# `solve --f1-exact-c1c2c4c5 --f1-pairs N` counts. This is the missing piece
# that unblocks the small-n end-to-end certificate probe (TASK_225 §6.4): a
# checkable — not merely re-runnable — count at a scale where a proof-emitting
# #SAT counter (D4/CPOG) can run.
#
# HEADER-RULE COMPLIANCE. As with the full-31 targets, NOTHING here hand-writes
# a C-rule. C1 (pair atoms), C2 (dist-5/0 forbids) and the C5 boundary
# cardinality all reuse the same clause primitives as build(); every distance
# is solve.bit_diff and every hexagram/pair is a solve import. Two *parameters*
# are derived — the group-closed pair-orbit partition and the C5 target multiset
# B0 — both ported from solve.c's f1c5 path (f1_build_group / f1c5_unions /
# f1c5_derive_b0 / f1c5_b0_dfs) and using only solve primitives. They emit no
# clauses; they name the same numbers solve.c derives. The full-31 B0 this port
# would produce equals the KW-derived between-multiset already asserted at the
# top of this file (BETWEEN_MULTISET); the reduced-subset B0 values + reference
# counts are pinned in tests.py (test_sat_c5_subset_*), and a #SAT/C-binary
# cross-check at N in {9,13,16} is the intended follow-up (see the private
# R2 note). C5 itself is the boundary budget: the N boundary transitions
# realize the class multiset B0 exactly (exactly_k over the class indicators).
# ============================================================================

_DVAL = (1, 2, 3, 4, 6)                 # solve.c F1C5_DVAL: the five distance classes (5 forbidden)
_CLS = {1: 0, 2: 1, 3: 2, 4: 3, 6: 4}   # solve.c F1C5_CLS: distance -> class index
_REV = (5, 4, 3, 2, 1, 0)               # bit-reversal as a bit-position permutation

def _perm_compose(a, b): return tuple(a[b[i]] for i in range(6))
def _hex_act(perm, h):
    r = 0
    for i in range(6):
        r |= ((h >> i) & 1) << perm[i]
    return r

# --- S4 pair-orbit structure (port of solve.c f1_build_group; = f1_orbit_dp.py) ---
_G48 = [p for p in _itertools.permutations(range(6))
        if _perm_compose(p, _REV) == _perm_compose(_REV, p)]
assert len(_G48) == 48, "centralizer of rev in S6 must have order 48"
_PSETS = [frozenset(pr) for pr in KW_PAIRS]
_SET2PAIR = {s: i for i, s in enumerate(_PSETS)}
def _pair_perm(g):
    return tuple(_SET2PAIR[frozenset(_hex_act(g, h) for h in _PSETS[p])] for p in range(32))
_coset = {}
for _g in sorted(_G48):
    _coset.setdefault(_pair_perm(_g), []).append(_g)
assert len(_coset) == 24, "record-level pair group must be S4 (order 24)"
_G24_PP = sorted(_coset)                                    # 24 pair-perms of the 32 pairs
_parent = list(range(32))                                   # union-find over the 32 pairs
def _uf_find(x):
    while _parent[x] != x:
        _parent[x] = _parent[_parent[x]]; x = _parent[x]
    return x
for _pp in _G24_PP:
    for _i in range(32):
        _ra, _rb = _uf_find(_i), _uf_find(_pp[_i])
        if _ra != _rb: _parent[_ra] = _rb
_orbmap = {}
for _i in range(1, 32):                                     # the 31 free pairs (pair 0 fixed)
    _orbmap.setdefault(_uf_find(_i), []).append(_i)
PAIR_ORBITS = sorted(_orbmap.values(), key=lambda o: (len(o), o))  # == solve.c f1_orb_cmp order
assert sorted(len(o) for o in PAIR_ORBITS) == [3, 3, 3, 4, 6, 6, 6], "pair-orbit sizes broke"

# group-closed orbit-union specs, verbatim from solve.c f1c5_unions[]
F1C5_UNIONS = {
    9:  "3.0,3.1,3.2@0",       13: "3.0,4.0,6.2@0",       16: "4.0,6.0,6.1@0",
    18: "6.0,6.1,6.2@0",       19: "3.0,4.0,6.0,6.1@0",   24: "3.0,3.1,6.0,6.1,6.2@0",
    25: "3.0,4.0,6.0,6.1,6.2@0", 27: "3.0,3.1,3.2,6.0,6.1,6.2@0",
    28: "3.0,3.1,4.0,6.0,6.1,6.2@0",
}
def _orbit_by(size, idx):
    cnt = 0
    for o in PAIR_ORBITS:
        if len(o) == size:
            if cnt == idx: return o
            cnt += 1
    raise KeyError((size, idx))

def subset_pairlist(npairs):
    """(pair-index list pl, start_exit) for the group-closed orbit union of N
    pairs — matches solve.c f1_parse_subset (orbit-append order, NOT sorted)."""
    spec = F1C5_UNIONS.get(npairs)
    if spec is None:
        raise SystemExit("--f1-pairs %r: no group-closed orbit union; have %s"
                         % (npairs, ",".join(map(str, sorted(F1C5_UNIONS)))))
    at = spec.index("@"); start = int(spec[at + 1:]); body = spec[:at]
    pl = []
    for tok in body.split(","):
        L, I = tok.split("."); pl += _orbit_by(int(L), int(I))
    assert len(pl) == npairs, "union table inconsistency"
    return pl, start

def derive_b0(pl, start_exit):
    """C5 boundary-budget multiset for a reduced subset via the deterministic
    first-completion DFS — EXACT port of solve.c f1c5_b0_dfs / f1c5_derive_b0
    (pairs tried in ascending subset-index order; orientations (0,1) with o=0
    ENTERING pair_b / EXITING pair_a, matching solve.c `f = o ? pa : pb` and the
    validated f1_orbit_dp.py `trans[i][o] = (PAIRS[p][o^1], PAIRS[p][o])`; the
    order picks WHICH witness completion defines B0, so it must match solve.c
    exactly). Distances are solve.bit_diff. Returns {distance: count} over the
    classes {1,2,3,4,6}; sums to len(pl)."""
    n = len(pl)
    pa = [KW_PAIRS[p][0] for p in pl]
    pb = [KW_PAIRS[p][1] for p in pl]
    cls = [None] * n
    def dfs(mask, last, depth):
        if mask == (1 << n) - 1:
            return True
        for i in range(n):
            if (mask >> i) & 1:
                continue
            for o in (0, 1):
                f = pa[i] if o else pb[i]    # o=0: enter pair_b (KW[2p+1])
                s = pb[i] if o else pa[i]    # o=0: exit  pair_a (KW[2p])
                dd = solve.bit_diff(last, f)
                if dd == 5:
                    continue
                cls[depth] = _CLS[dd]
                if dfs(mask | (1 << i), s, depth + 1):
                    return True
        return False
    assert dfs(0, start_exit, 0), "no valid completion exists for the subset"
    b0 = {dv: 0 for dv in _DVAL}
    for c in cls:
        b0[_DVAL[c]] += 1
    return b0

def build_subset_pl(pl, start_exit, b0):
    """Base C1&C2&C4&C5 CNF over an explicit pair list `pl` with the boundary
    budget `b0` ({distance: count}). Pair-slot model identical to build(): each
    of the |pl| slots holds one (pair, orientation); C2 forbids dist-5/0
    boundaries; C5 = exactly_k over the per-class boundary indicators against
    b0. `start_exit` is the (C4-fixed) exit hexagram feeding boundary 0.
    Returns (cnf, ctx). Small-n arbitrary lists are used by the tests.py gate;
    the group-closed unions are reached via build_subset()."""
    n = len(pl)
    orients = []                          # j -> (local pair 0..n-1, orient, first_hex, second_hex)
    for lp, p in enumerate(pl):
        a, b = KW_PAIRS[p]
        orients.append((lp, 0, a, b))
        orients.append((lp, 1, b, a))
    nj = len(orients)
    slots = list(range(1, n + 1))
    cnf = CNF()
    Y = {}
    for s in slots:
        for j in range(nj):
            Y[(s, j)] = cnf.var()
    for s in slots:                       # one (pair,orient) per slot
        exactly_one(cnf, [Y[(s, j)] for j in range(nj)])
    for lp in range(n):                   # each pair used exactly once
        exactly_one(cnf, [Y[(s, j)] for s in slots for j in range(nj) if orients[j][0] == lp])

    def exit_hex(j):  return orients[j][3]
    def entry_hex(j): return orients[j][2]

    T = {}                                # boundary distance-class indicators (n boundaries)
    for s in range(n):
        for dv in _DVAL:
            T[(s, dv)] = cnf.var()
        exactly_one(cnf, [T[(s, dv)] for dv in _DVAL])
    for j in range(nj):                   # boundary 0: fixed exit = start_exit (C4)
        dd = solve.bit_diff(start_exit, entry_hex(j))
        if dd == 5 or dd == 0:
            cnf.add(-Y[(1, j)])
        else:
            cnf.add(-Y[(1, j)], T[(0, dd)])
    for s in range(1, n):
        for j1 in range(nj):
            for j2 in range(nj):
                if orients[j1][0] == orients[j2][0]:
                    continue
                dd = solve.bit_diff(exit_hex(j1), entry_hex(j2))
                if dd == 5 or dd == 0:
                    cnf.add(-Y[(s, j1)], -Y[(s + 1, j2)])
                else:
                    cnf.add(-Y[(s, j1)], -Y[(s + 1, j2)], T[(s, dd)])
    for dv in _DVAL:                      # C5 boundary budget (k=0 forbids that class)
        exactly_k(cnf, [T[(s, dv)] for s in range(n)], b0[dv])
    ctx = {"Y": Y, "orients": orients, "slots": slots, "nj": nj, "n": n,
           "pl": pl, "start_exit": start_exit, "b0": b0}
    return cnf, ctx

def build_subset(npairs):
    """C1&C2&C4&C5 CNF for the group-closed N-pair orbit union (the object
    `solve --f1-exact-c1c2c4c5 --f1-pairs N` counts). Returns (cnf, ctx)."""
    pl, start_exit = subset_pairlist(npairs)
    return build_subset_pl(pl, start_exit, derive_b0(pl, start_exit))

def decode_subset(model_lits, ctx):
    """Decode a solver model to the placed-pair hexagram sequence (length 2N)."""
    tru = set(l for l in model_lits if l > 0)
    seq = []
    for s in ctx["slots"]:
        for j in range(ctx["nj"]):
            if ctx["Y"][(s, j)] in tru:
                seq += [ctx["orients"][j][2], ctx["orients"][j][3]]
                break
    return seq

def verify_subset(seq, ctx):
    """Re-verify a decoded subset sequence against solve.py ground truth:
    distinct hexagrams (C1), no dist-5 boundary (C2), and boundary class
    multiset == B0 (C5, over the N boundaries incl. start_exit -> seq[0]).
    Returns (ok, boundary_distances)."""
    n = ctx["n"]
    ok = len(seq) == 2 * n and len(set(seq)) == 2 * n
    bnd = ([solve.bit_diff(ctx["start_exit"], seq[0])]
           + [solve.bit_diff(seq[2 * i + 1], seq[2 * i + 2]) for i in range(n - 1)]) if seq else []
    ok = ok and all(bd != 5 for bd in bnd)
    got = {dv: 0 for dv in _DVAL}
    for bd in bnd:
        if bd in got:
            got[bd] += 1
        else:
            ok = False
    ok = ok and got == ctx["b0"]
    return ok, bnd

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
    """Round-trip re-verification of a decoded 64-hexagram sequence against
    solve.py: C1 (permutation), C2 (no distance-5 step), C5 (transition
    multiset), C3 total — AND (F-1) a re-score of the literature axes on the
    decoded witness: g1 Moore-2005 parity violations + g2 Moore-1989 rhythm
    breaks (both via _moore_scores -> solve.r11_axes) and g3 Schulz gender
    violations (solve.rc4_violations). Returns (ok, c3, (g1, g2, g3));
    scores is None when the base checks fail."""
    ok = len(seq) == 64 and len(set(seq)) == 64
    ok = ok and solve.has_no_five(seq)
    from collections import Counter
    ok = ok and dict(Counter(solve.bit_diff(seq[i], seq[i+1]) for i in range(63))) == _tot
    pos = {h: i for i, h in enumerate(seq)}
    c3 = sum(abs(pos[h] - pos[h ^ 63]) for h in range(64))
    scores = None
    if ok:
        g1, g2 = _moore_scores(seq)
        scores = (g1, g2, solve.rc4_violations(seq)[0])
    return ok, c3, scores

def _read_model_lits(path):
    """Parse a solver model: DIMACS 'v '-lines, or a bare whitespace/newline
    separated list of signed ints (trailing 0 terminator ignored)."""
    lits = []
    with open(path) as fh:
        text = fh.read()
    for ln in text.splitlines():
        if ln.startswith("v "):
            lits += [int(x) for x in ln[2:].split() if x != "0"]
    if not lits:                                    # no v-lines: treat whole file as a token list
        lits = [int(x) for x in text.split() if x.lstrip("-").isdigit() and x != "0"]
    return lits

# ============================================================================
# --certify-count: independently CERTIFIED model count via D4 + CPOG.
# ----------------------------------------------------------------------------
# EXTERNAL DEPENDENCY (OPTIONAL — this subcommand ONLY). --certify-count
# requires the D4 d-DNNF compiler (https://github.com/crillab/d4) and the CPOG
# certified-knowledge-compilation toolchain's cpog-gen + cpog-check
# (https://github.com/rebryant/cpog; Bryant/Nawrocki/Avigad, SAT 2023) on
# PATH. NOTHING else in sat.py needs them: if they are absent, the subcommand
# exits gracefully with an install message (same idiom as roae.py's optional
# wkhtmltopdf PDF step) and every other subcommand is unaffected — mirroring
# how kissat is an external requirement of --witness only.
#
# Pipeline (all artifacts under one work dir):
#   1. instance.cnf   — the DIMACS this file already emits (build/build_subset)
#   2. d4 -dDNNF instance.cnf -out=instance.nnf   — compile to Decision-DNNF
#   3. cpog-gen  instance.cnf instance.nnf instance.cpog  — CPOG certificate
#   4. cpog-check instance.cnf instance.cpog     — verify + certified count
# The count reported by step 4 is the CERTIFIED number: cpog-check validates
# the certificate against the ORIGINAL CNF, independently of d4's own answer.
# d4's own (uncertified) count is cross-checked against it when parseable.
# The native C reference count (`solve --f1-exact-c1c2c4c5 --f1-pairs N`) is
# supplied by the caller via --expect; sat.py never invokes solve.c.
#
# RUN-VALIDATION NOTE (2026-07-10): the argv forms and output-parsing patterns
# below follow D4 v1's and the CPOG repo's documented interfaces, but they
# have NOT yet been executed against built binaries (none are installed in
# the dev environment). They are to be RUN-validated during the R2-c
# cross-check campaign (Spot VM with d4/cpog-gen/cpog-check built) before any
# certified count from this path is cited. The absent-tools graceful path IS
# tested (tests.py TestGates.test_certify_count_absent_tools).
# ============================================================================

_CERTIFY_TOOLS_MSG = (
    "D4 and CPOG are required to run --certify-count but '%s' was not found on PATH.\n"
    "Install D4 (d-DNNF compiler, https://github.com/crillab/d4) and the CPOG toolchain\n"
    "cpog-gen/cpog-check (https://github.com/rebryant/cpog); see documentation/SAT_CLI.md.\n"
    "The rest of sat.py works without them.")

def _run_tool(argv):
    """Run one external certificate-toolchain binary. Graceful-absence idiom
    (roae.py wkhtmltopdf): a missing binary exits with a clear install
    message instead of an unhandled FileNotFoundError traceback."""
    try:
        return subprocess.run(argv, capture_output=True, text=True)
    except FileNotFoundError:
        raise SystemExit(_CERTIFY_TOOLS_MSG % argv[0])

def _tool_tail(r):
    return (r.stdout + r.stderr)[-600:]

def certify_count(cnf_obj, label, keep_dir=None):
    """Compile `cnf_obj` with D4, then generate and verify a CPOG certificate,
    returning (certified_count, d4_uncertified_count_or_None). REQUIRES d4,
    cpog-gen, cpog-check on PATH — exits gracefully with an install message if
    any is absent (see _CERTIFY_TOOLS_MSG; the rest of sat.py never needs
    them). Artifacts land in keep_dir (preserved) or a temp dir (removed)."""
    import tempfile, shutil, re
    wd = keep_dir or tempfile.mkdtemp(prefix="sat_certify_")
    if keep_dir:
        os.makedirs(wd, exist_ok=True)
    try:
        cnf_path = os.path.join(wd, "instance.cnf")
        nnf_path = os.path.join(wd, "instance.nnf")
        cpog_path = os.path.join(wd, "instance.cpog")
        cnf_obj.write(cnf_path, label)
        # 1) D4 v1: compile to Decision-DNNF (argv per D4 v1 README; the CPOG
        #    toolchain consumes D4 v1 .nnf — RUN-validate, see section header)
        r_d4 = _run_tool(["d4", "-dDNNF", cnf_path, "-out=" + nnf_path])
        if not (os.path.exists(nnf_path) and os.path.getsize(nnf_path) > 0):
            raise SystemExit("d4 produced no d-DNNF at %s\n--- d4 output tail ---\n%s"
                             % (nnf_path, _tool_tail(r_d4)))
        # d4's own UNCERTIFIED count (advisory cross-check only; tolerant of
        # both the classic "s <N>" line and the model-counting-competition
        # "c s exact arb int <N>" form)
        m = re.findall(r"(?m)^(?:c s exact arb int|s)\s+(\d+)\s*$", r_d4.stdout)
        d4_count = int(m[-1]) if m else None
        # 2) cpog-gen: CNF + d-DNNF -> CPOG certificate
        r_gen = _run_tool(["cpog-gen", cnf_path, nnf_path, cpog_path])
        if r_gen.returncode != 0 or not os.path.exists(cpog_path):
            raise SystemExit("cpog-gen failed (rc=%s)\n--- output tail ---\n%s"
                             % (r_gen.returncode, _tool_tail(r_gen)))
        # 3) cpog-check: verify the certificate against the ORIGINAL CNF; the
        #    count it reports is the CERTIFIED model count
        r_chk = _run_tool(["cpog-check", cnf_path, cpog_path])
        m = re.findall(r"(?im)^.*\bmodel count\b[^0-9]*(\d+)\s*$", r_chk.stdout)
        if r_chk.returncode != 0 or not m:
            raise SystemExit("cpog-check did not certify a count (rc=%s)\n--- output tail ---\n%s"
                             % (r_chk.returncode, _tool_tail(r_chk)))
        # gate on the FULL-proof verdict, not just rc+count: cpog-check
        # distinguishes full from one-sided/partial verification, and only a
        # full proof certifies the count (defense-in-depth; R2-delta review)
        if "FULL-PROOF SUCCESS" not in r_chk.stdout:
            raise SystemExit("cpog-check succeeded without FULL-PROOF SUCCESS — "
                             "partial/one-sided verification is not a certified count"
                             "\n--- output tail ---\n%s" % _tool_tail(r_chk))
        certified = int(m[-1])
        if d4_count is not None and d4_count != certified:
            raise SystemExit("d4 uncertified count %d != CPOG-certified count %d "
                             "— toolchain misuse or bug; investigate before trusting either"
                             % (d4_count, certified))
        return certified, d4_count
    finally:
        if keep_dir is None:
            shutil.rmtree(wd, ignore_errors=True)

if __name__ == "__main__":
    args = sys.argv[1:]

    def _int_arg(flag, argv, i):
        """Parse the value after `flag` as an integer, or exit with a readable message.

        Q-305 class: B6 fixed the `*-near-<non-int>` parse and left the four CLI integer flags
        raising bare tracebacks. Measured 2026-08-28 before this helper: `--c3-max abc`,
        `--c3-min abc`, `--f1-pairs abc`, `--expect abc` and a flag given as the LAST argument all
        exited 1 with a Python traceback. The exit code was already right; the output was not.
        A traceback tells an operator that the tool broke. A message tells them what they typed
        wrong -- and this project's own rule is that a tool must say what it wants.
        """
        if i + 1 >= len(argv):
            raise SystemExit(f"{flag} needs an integer value (none was given)")
        raw = argv[i + 1]
        try:
            return int(raw)
        except ValueError:
            raise SystemExit(f"{flag} needs an integer value, got {raw!r}")

    with_c3, c3_max, c3_min, not_kw, npairs = False, None, None, False, None
    if "--with-c3" in args:
        with_c3 = True; args.remove("--with-c3")
    if "--c3-max" in args:
        i = args.index("--c3-max")
        with_c3, c3_max = True, _int_arg('--c3-max', args, i); del args[i:i + 2]
    if "--c3-min" in args:                           # C3 >= N (does NOT imply the <= ceiling)
        i = args.index("--c3-min")
        c3_min = _int_arg('--c3-min', args, i); del args[i:i + 2]
    if "--not-kw" in args:
        not_kw = True; args.remove("--not-kw")
    if "--f1-pairs" in args:                         # reduced subset instance (TASK #225 probe)
        i = args.index("--f1-pairs")
        npairs = _int_arg('--f1-pairs', args, i); del args[i:i + 2]
    if npairs is not None and (with_c3 or c3_min is not None or not_kw):
        raise SystemExit("--f1-pairs subset instances encode C1&C2&C4&C5 only: "
                         "--with-c3/--c3-max/--c3-min/--not-kw do not apply")
    expect, keep_dir = None, None                    # --certify-count modifiers
    if "--expect" in args:
        i = args.index("--expect")
        expect = _int_arg('--expect', args, i); del args[i:i + 2]
    if "--keep" in args:
        i = args.index("--keep")
        keep_dir = args[i + 1]; del args[i:i + 2]

    # 🔴 An UNRECOGNISED flag was silently ignored. Measured 2026-08-28: `--c3max 776` -- one
    # missing hyphen, the most likely typo there is -- left sat.py printing its help banner and
    # exiting 0 with NO CNF written. A scripted caller sees success and no file. That is worse
    # than emitting the wrong formula, because rc=0 is an assertion that the command ran.
    # Same silent-ignore class as Q-309 (`--f1-pairs` with C3 flags), one layer out: there the
    # flag was accepted and dropped, here the whole invocation is.
    _stray = [a for a in args[1:] if a.startswith("--")]
    if _stray:
        raise SystemExit("unrecognised flag(s): " + " ".join(_stray) +
                         "\n(a mistyped flag was silently ignored before 2026-08-28; it is an error now)")

    def _emit_label(target):
        if npairs is not None:
            return "f1c5 --f1-pairs %d (C1&C2&C4&C5)" % npairs
        return target + (" c3<=%d" % (c3_max or KW_C3) if with_c3 else "") \
                      + (" c3>=%d" % c3_min if c3_min is not None else "") \
                      + (" not-kw" if not_kw else "")

    if args[:1] == ["--emit-cnf"] and len(args) == 3:
        if npairs is not None:
            cnf, ctx = build_subset(npairs)
            cnf.write(args[2], _emit_label(args[1]))
            print("vars=%d clauses=%d -> %s" % (cnf.n, len(cnf.cl), args[2]))
            print("f1-pairs=%d pl=%s start_exit=%d B0(d1,2,3,4,6)=%s"
                  % (npairs, ctx["pl"], ctx["start_exit"], [ctx["b0"][dv] for dv in _DVAL]))
        else:
            cnf, Y = build(args[1], with_c3=with_c3, c3_max=c3_max, c3_min=c3_min, not_kw=not_kw)
            cnf.write(args[2], "target=" + _emit_label(args[1]))
            print("vars=%d clauses=%d -> %s" % (cnf.n, len(cnf.cl), args[2]))
    elif args[:1] == ["--decode"] and len(args) in (2, 3):
        # --decode MODEL.txt [TARGET]  (rebuilds the CNF to recover the Y map,
        # decodes the model's v-lines to a sequence, re-verifies vs solve.py).
        # Use --f1-pairs N to decode a reduced-subset model; else TARGET (default
        # 'plain') selects a full-31 encoding.
        lits = _read_model_lits(args[1])
        if npairs is not None:
            cnf, ctx = build_subset(npairs)
            seq = decode_subset(lits, ctx)
            ok, bnd = verify_subset(seq, ctx)
            cls = {dv: bnd.count(dv) for dv in _DVAL}
            print("SEQ (2N=%d):" % len(seq), seq)
            print("verify=%s  boundary-classes=%s  B0=%s"
                  % (ok, [cls[dv] for dv in _DVAL], [ctx["b0"][dv] for dv in _DVAL]))
        else:
            target = args[2] if len(args) == 3 else "plain"
            cnf, Y = build(target, with_c3=with_c3, c3_max=c3_max, c3_min=c3_min, not_kw=not_kw)
            seq = decode(lits, Y)
            ok, c3, scores = verify_seq(seq)
            print("SEQ:", seq)
            if c3_min is None:
                print("verify=%s  c3=%d  %s" % (ok, c3, "c3<=776 PASS" if c3 <= 776 else "fail C3"))
            else:
                lo_ok = c3 >= c3_min
                hi_ok = (not with_c3) or c3 <= (c3_max or KW_C3)
                print("verify=%s  c3=%d  %s" % (ok, c3,
                      "c3 window PASS" if lo_ok and hi_ok else
                      ("fail c3-min" if not lo_ok else "fail c3-max")))
            if scores is not None:
                print("rule re-score (solve.py): moore-parity-viol=%d rhythm-breaks=%d "
                      "gender-viol=%d" % scores)
    elif args[:1] == ["--certify-count"] and len(args) == 2:
        # Certified model count via external D4 + CPOG (cpog-gen/cpog-check) —
        # OPTIONAL binaries, required by THIS subcommand only; certify_count()
        # exits gracefully with an install message if they are not on PATH.
        target = args[1]
        # model-count safety: the C3 X-vars are one-directional (unforced X
        # floats true, inflating the count) and near-k targets leave bare
        # at_most/at_least Sinz registers undetermined — validly certified
        # for the CNF, but NOT the count of orderings. Refuse rather than
        # print a certified-but-unsupportable number.
        if with_c3 or c3_max is not None or c3_min is not None or not_kw:
            raise SystemExit("--certify-count refuses --with-c3/--c3-max/--c3-min/--not-kw: "
                             "the C3 encoding is not total-model-count-safe (one-directional "
                             "on the <= side; auxiliary X/ladder vars on the >= side), so the "
                             "certified CNF count would not equal the orderings count")
        if "-near-" in target:
            raise SystemExit("--certify-count refuses near-k targets: bare "
                             "at_most/at_least cardinality registers are not "
                             "total-model-count-safe")
        if npairs is not None:
            cnf, _ctx = build_subset(npairs)
        else:
            cnf, _Y = build(target, with_c3=with_c3, c3_max=c3_max)
        certified, d4_count = certify_count(cnf, "target=" + _emit_label(target),
                                            keep_dir=keep_dir)
        print("CERTIFIED count=%d  (%s; D4 d-DNNF + CPOG-checked certificate)"
              % (certified, _emit_label(target)))
        if d4_count is not None:
            print("d4 uncertified count agrees: %d" % d4_count)
        if keep_dir:
            print("artifacts kept in %s (instance.cnf/.nnf/.cpog)" % keep_dir)
        if expect is not None:
            ok = certified == expect
            print("expect=%d certified=%d  %s" % (expect, certified, "PASS" if ok else "FAIL"))
            if not ok:
                sys.exit(1)
    elif args[:1] == ["--witness"] and len(args) == 2:
        if npairs is not None:
            raise SystemExit("--witness does not support --f1-pairs "
                             "(full-31 targets only)")
        target = args[1]
        cnf, Y = build(target, with_c3=with_c3, c3_max=c3_max, c3_min=c3_min, not_kw=not_kw)
        import tempfile
        for attempt in range(200):
            f = tempfile.NamedTemporaryFile("w", suffix=".cnf", delete=False)
            cnf.write(f.name, "target=" + target)
            try:
                r = subprocess.run(["kissat", "-q", f.name], capture_output=True, text=True)
            except FileNotFoundError:
                # graceful-absence idiom (roae.py wkhtmltopdf): external solver
                # missing is a clear install message, not a traceback
                os.unlink(f.name)
                raise SystemExit(
                    "kissat is required to run --witness but was not found on PATH.\n"
                    "Install kissat (https://github.com/arminbiere/kissat); see "
                    "documentation/SAT_CLI.md.\nThe rest of sat.py works without it.")
            os.unlink(f.name)
            if "s SATISFIABLE" not in r.stdout:
                print("UNSAT (or solver error) at attempt", attempt); print(r.stdout[-400:]); break
            lits = []
            for ln in r.stdout.splitlines():
                if ln.startswith("v "):
                    lits += [int(x) for x in ln[2:].split() if x != "0"]
            seq = decode(lits, Y)
            ok, c3, scores = verify_seq(seq)
            # F-1: re-score the target's strict literature rules on the decoded
            # witness via solve.py scorers — a witness violating an encoded rule
            # means encoder/engine divergence, never accepted. (Skipped for the
            # kw* encoding-validation targets, which pin KW deliberately.)
            rule_ok = True
            if "kw" not in target:
                for nm, idx in (("parity", 0), ("rhythm", 1), ("gender", 2)):
                    if nm in target_rules(target) and (scores is None or scores[idx] != 0):
                        rule_ok = False
            c3_ok = (c3 <= 776) if c3_min is None else \
                    (c3 >= c3_min and ((not with_c3) or c3 <= (c3_max or KW_C3)))
            print("attempt %d: verify=%s rules(g1,g2,g3)=%s rule_ok=%s c3=%d %s"
                  % (attempt, ok, scores, rule_ok, c3,
                     "c3 PASS" if c3_ok else "fail C3, blocking"))
            if ok and rule_ok and c3_ok:
                print("WITNESS:", seq); break
            cnf.add(*[-Y[(s, j)] for s in SLOTS for j in range(NJ) if Y[(s, j)] in set(l for l in lits if l > 0)])
    elif args[:1] == ["--rigidity-cnf"] and len(args) in (2, 3):
        # TR-5 v-next SC-4 kernel [expect UNSAT]; see build_rigidity docstring.
        out = args[1]
        cnf, x = build_rigidity()
        if not rigidity_validate(cnf, x):
            raise SystemExit("rigidity encoding self-validation FAILED — not writing " + out)
        cnf.write(out, "rigidity: G5-automorphism fixing 0+N5(0) pointwise, != id [expect UNSAT]")
        print("wrote %s (%d vars, %d clauses); encoding self-validation PASS" %
              (out, cnf.n, len(cnf.cl)))
        if len(args) == 3 and args[2] == "--run":
            import shutil
            if shutil.which("kissat") is None:
                raise SystemExit(
                    "kissat is required for --rigidity-cnf --run but was not found on PATH.\n"
                    "Install kissat (https://github.com/arminbiere/kissat); see SAT_CLI.md.")
            proof = out + ".drat"
            r = subprocess.run(["kissat", "-q", out, proof], capture_output=True, text=True)
            verdict = ("UNSAT" if "s UNSATISFIABLE" in r.stdout
                       else "SAT" if "s SATISFIABLE" in r.stdout else "UNKNOWN(rc=%d)" % r.returncode)
            print("kissat verdict: %s (proof: %s)" % (verdict, proof))
            if verdict != "UNSAT":
                raise SystemExit("EXPECTED UNSAT — got " + verdict)
            if shutil.which("drat-trim"):
                r2 = subprocess.run(["drat-trim", out, proof], capture_output=True, text=True)
                ver = "VERIFIED" if "s VERIFIED" in r2.stdout else "NOT VERIFIED"
                print("drat-trim: %s" % ver)
                if ver != "VERIFIED":
                    raise SystemExit("DRAT proof did not verify")
            else:
                print("drat-trim not on PATH — proof emitted but UNVERIFIED "
                      "(run drat-trim %s %s independently)" % (out, proof))
    else:
        print(__doc__)
