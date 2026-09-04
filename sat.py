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

GUARD RULE (Q-373, 2026-08-28): this file must contain NO `assert` statements. Every
import-time ground-truth gate and runtime guard is an explicit `if not (...): raise`, so
the trust base survives `python3 -O` (which strips asserts — measured before the fix: a
corrupted BETWEEN_MULTISET silently emitted a syntactically valid wrong CNF under -O).
Same convention as solve.py's table gates (VERIFY.md). Enforced by tests.py's AST scan.

Architecture (operator-approved 2026-07-02): three canonical sources — solve.c (enumeration,
sha-anchored), solve.py (analysis + ground truth), sat.py (this file; imports solve.py).
External solvers (kissat / CaDiCaL) run as separate binaries; their UNSAT answers are only
trusted via DRAT/LRAT certificates checked by an independent verified checker. Third-party
solver use authorized by operator 2026-07-02.

Subcommands:
  --emit-cnf TARGET OUT.cnf     write DIMACS for TARGET
  --decode MODEL.txt [TARGET]   decode a solver model (v-lines, or a bare int list) back to a
                                hexagram sequence and re-verify vs solve.py (TARGET default
                                'plain'; add --f1-pairs N to decode a reduced-subset model).
                                Since 2026-09-03 a verdict emitter: checks the model against
                                the formula (MODEL_CHECK=SATISFIED/CONSISTENT/FALSIFIED; the
                                falsified clause FAMILIES are exact for a full model and a
                                first-conflict attribution for a partial one, see
                                model_check), re-scores all five literature rules the target
                                enforces, honours the C3 flags, prints DECODE_VERDICT=PASS/FAIL
                                and exits 0/1 accordingly
  --witness TARGET              emit CNF, run the external solver (REQUIRES kissat on PATH;
                                exits with a clear install message if missing), decode, verify,
                                iterate blocking clauses until a C3-passing witness is found.
                                Ends with WITNESS_RESULT=WITNESS|UNSAT (exit 0) or
                                SOLVER_ERROR (2) | ENCODING_DIVERGENCE (3) | EXHAUSTED (4)
  --rigidity-cnf OUT.cnf [--run]  TR-5 v2.0 symmetry-completeness rigidity kernel [expect UNSAT]:
                                G5-automorphism fixing 0 + its six d5-neighbors pointwise, != id.
                                Emits + self-validates the CNF; with --run, decides via kissat
                                (DRAT proof to OUT.cnf.drat, drat-trim verified when on PATH).
  --c5-selfcheck                behavioural evidence that the C5 tables are DERIVED from solve
                                primitives and that their guard REFUSES a common-mode corruption;
                                prints KEY=value verdict lines (C5_LITERALS_DERIVED,
                                GUARD_REJECTS_COMMON_MODE, ...); exit 0 iff every verdict passes
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
  alt-le-14-noY  the CARDINALITY-ONLY clause subset of the target above (2026-09-02, TR-6 /
  alt-ge-16-noY  Codex V2-F08 #3): exactly the clauses of alt-le-14 / alt-ge-16 in which NO Y
                 (slot -> pair/orientation ordering) variable occurs, variable numbering
                 unchanged, so the output is a syntactic subset of the full CNF. What survives:
                 the per-boundary distance exactly_one, the C5 per-distance exactly_k, the odd
                 definitions and the alternation bound; what is dropped: every C1/C2/C4 clause.
                 [expect UNSAT -- the alternation theorem is decided by C5's cardinalities alone;
                 archived as alt_le_14_noY_unsat / alt_ge_16_noY_unsat, replayed by
                 verify_all.sh which emits ALT_NOY_SUBSET_UNSAT=PASS]. --emit-cnf only: the
                 Y-free formula has no ordering to decode, so --witness/--decode/--certify-count
                 refuse it, as do --with-c3/--c3-max/--c3-min/--not-kw and -near- (each would
                 add Y-touching clauses that the predicate then silently removes).
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
  grand-ccn4     grand-strict AND CC-N4 (Schulz S25-28 dui-trigram configuration) — the FOUR-rule
                 conflict theorem, increment 1 of the #217 five-rule family (RULESETS enforces
                 exactly parity+rhythm+gender+ccn4; grander-strict below is the five-rule union):
                 UNSAT proves no C1+C2+C4+C5-valid ordering is perfect under Moore parity +
                 Moore rhythm + Schulz gender + the trigram champion simultaneously.
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
# ---- C5 tables: DERIVED from solve primitives, never written out (T6, 2026-09-02) ----
# Until 2026-09-02 the two tables _tot and BETWEEN_MULTISET were hand-written dict literals -- a
# direct violation of the header rule above -- and the guard between them (the Q-357 loop of
# 2026-08-28, `_tot[d] - _wp[d] == BETWEEN_MULTISET[d]`) checked only their DIFFERENCE against the
# derived _wp, so a common-mode edit (+1 at d=2 in BOTH literals) passed it: the encoder (build(),
# the T[(s,d)] indicators and their exactly_k budget) and the round-trip verifier (verify_seq) would
# have drifted together, undetected. Measured by the Codex V2 adjudication (A08 row 13, A09 row 17).
# Both literals were correct; the defect was that nothing in this file could have said so.
#
# Now derive_c5_tables() computes all three tables from a sequence with solve.bit_diff, by three
# counts that share no intermediate -- every transition (63), the within-pair transitions (32), and
# the pair-BOUNDARY transitions counted directly (31: exit of pair s -> entry of pair s+1) -- and
# c5_tables_guard() checks the module tables against anchors that a common-mode edit cannot
# satisfy: solve.py's own C5 multiset (solve.h2_kw_multiset), the canonical pairing
# (solve.build_pairs), the cardinalities 63/32/31 (from len(KW), independent of bit_diff), and the
# additive identity tot = wp + between. `sat.py --c5-selfcheck` runs the guard on deliberately
# corrupted copies and prints GUARD_REJECTS_COMMON_MODE=1 only if the +1/+1 corruption is REFUSED
# (tests.py pins the token and repeats the red test in-process).
# Key order is pinned ascending (1,2,3,4,6): build() allocates T[(s,d)] by iterating
# BETWEEN_MULTISET, so the order fixes CNF variable numbering -- emitted CNFs are byte-identical
# to the literal era (checked against ten pre-change emissions when this landed).
_C5_KEYS = (1, 2, 3, 4, 6)   # admissible transition distances: C2 forbids 5, distinct hexagrams forbid 0

def derive_c5_tables(seq):
    """Return (tot, wp, between) for a sequence with an even number of hexagrams, using only
    solve.bit_diff: tot = every adjacent transition; wp = the transition inside each (2i, 2i+1)
    pair; between = the transition across each pair boundary (2i+1, 2i+2). Plain dicts, keys
    ascending. Nothing here reads a constant: derive_c5_tables(KW) is this module's C5 ground
    truth, and for any other sequence it is THAT sequence's tables (the selfcheck proves the
    function is input-sensitive, so it cannot silently degrade into a literal)."""
    from collections import Counter
    n = len(seq)
    tot = Counter(solve.bit_diff(seq[i], seq[i + 1]) for i in range(n - 1))
    wp = Counter(solve.bit_diff(seq[2 * i], seq[2 * i + 1]) for i in range(n // 2))
    between = Counter(solve.bit_diff(seq[2 * i + 1], seq[2 * i + 2]) for i in range(n // 2 - 1))
    return tuple({d: c[d] for d in sorted(c)} for c in (tot, wp, between))

def c5_tables_guard(tot, wp, between):
    """Raise AssertionError unless (tot, wp, between) are exactly King Wen's C5 tables; else None.
    Every anchor is computed WITHOUT the table it checks, so the guard cannot agree with a
    corrupted table by construction (the verifier-closure invariant):
      G1  tot   == solve.h2_kw_multiset()                 solve.py's own derivation (ground truth)
      G2  wp    == distances over solve.build_pairs()     the canonical pairing, not KW adjacency
      G3  sums  == (len(KW)-1, len(KW)//2, len(KW)//2-1)  structural; independent of bit_diff
      G4  tot   == wp + between, key-wise                 the pre-2026-09-02 guard, kept as ONE leg
      G5  keys  within _C5_KEYS                           C2 (no 5) and C1 (no 0)
    A common-mode +1 on tot and between passes G4 alone -- that was the defect -- and fails G1 and G3."""
    from collections import Counter
    n = len(KW)
    ref_tot = dict(solve.h2_kw_multiset())
    ref_wp = dict(Counter(solve.bit_diff(a, b) for a, b in solve.build_pairs()))
    keys = set(tot) | set(wp) | set(between)
    checks = (
        ("G1 tot != solve.h2_kw_multiset()", dict(tot) == ref_tot),
        ("G2 wp != solve.build_pairs() distances", dict(wp) == ref_wp),
        ("G3 cardinalities != (%d, %d, %d)" % (n - 1, n // 2, n // 2 - 1),
         (sum(tot.values()), sum(wp.values()), sum(between.values())) == (n - 1, n // 2, n // 2 - 1)),
        ("G4 tot != wp + between", all(tot.get(d, 0) == wp.get(d, 0) + between.get(d, 0) for d in keys)),
        ("G5 key outside admissible distances", keys <= set(_C5_KEYS)),
    )
    failed = [name for name, ok in checks if not ok]
    if failed:
        raise AssertionError("C5 table guard failed: " + "; ".join(failed))

_tot, _wp, BETWEEN_MULTISET = derive_c5_tables(KW)
c5_tables_guard(_tot, _wp, BETWEEN_MULTISET)

def c5_selfcheck(out=print):
    """`--c5-selfcheck`: behavioural evidence for the C5 derivation and its guard (T6, 2026-09-02).
    Prints KEY=value verdict lines -- gate on them with `grep -qx`, never on output shape:
      C5_LITERALS_DERIVED=1         the module tables equal derive_c5_tables(KW); the derivation is
                                    input-SENSITIVE (a non-KW sequence yields different tables, so it
                                    is not a constant wearing a function's name); and no dict literal
                                    equal to either KW table exists in this file's AST
      GUARD_ACCEPTS_TRUE_TABLES=1   c5_tables_guard accepts the real tables (a guard that always
                                    raises is not a guard either)
      GUARD_REJECTS_COMMON_MODE=1   c5_tables_guard REFUSES copies with +1 applied to BOTH _tot and
                                    BETWEEN_MULTISET at d=2 -- the corruption the pre-2026-09-02
                                    guard accepted (Codex V2 A08 row 13). This is THE red test.
      GUARD_REJECTS_CORRUPTIONS=k/n the wider battery: common-mode +1 at every admissible d, +1 on
                                    all three tables, a sum-preserving 2<->4 transposition in both,
                                    and each single-table +1
      GUARD_REJECTS_NON_KW=1        the guard refuses the (different) tables of a non-KW sequence:
                                    it is anchored to KW, not to whatever it is handed
    Returns 0 iff every verdict is its passing value; every line is printed even on failure."""
    import ast
    tot, wp, between = _tot, _wp, BETWEEN_MULTISET
    # --- derived, not written out
    fresh = derive_c5_tables(KW)
    same = (tot, wp, between) == fresh
    other = list(KW)
    other[2:4], other[4:6] = KW[4:6], KW[2:4]            # KW with pair slots 1 and 2 swapped
    other_tabs = derive_c5_tables(other)
    sensitive = other_tabs != fresh
    with open(__file__) as fh:
        tree = ast.parse(fh.read(), filename=__file__)
    lits = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Dict):
            try:
                v = ast.literal_eval(node)
            except (ValueError, TypeError, SyntaxError):
                continue
            if v == tot or v == between:
                lits.append(node.lineno)
    derived = same and sensitive and not lits
    out("C5_LITERALS_DERIVED=%d" % derived)
    out("  tables == derive_c5_tables(KW): %s; input-sensitive: %s; literal dict equal to a table at "
        "line(s): %s" % (same, sensitive, lits or "none"))

    def refuses(t, w, b):
        try:
            c5_tables_guard(t, w, b)
        except AssertionError as e:
            return str(e)
        return None
    accepts = refuses(tot, wp, between) is None
    out("GUARD_ACCEPTS_TRUE_TABLES=%d" % accepts)
    # --- THE red test: +1 on both formerly hand-written tables at d=2
    t2, b2 = dict(tot), dict(between)
    t2[2] += 1; b2[2] += 1
    why_cm = refuses(t2, wp, b2)
    out("GUARD_REJECTS_COMMON_MODE=%d" % (why_cm is not None))
    out("  common-mode +1 at d=2 in _tot and BETWEEN_MULTISET -> %s" % (why_cm or "ACCEPTED (defect)"))
    # --- the battery
    cases = []
    for d in _C5_KEYS:
        t, b = dict(tot), dict(between)
        t[d] = t.get(d, 0) + 1; b[d] = b.get(d, 0) + 1
        cases.append(("common-mode +1 at d=%d" % d, t, wp, b))
    t, w, b = dict(tot), dict(wp), dict(between)
    t[2] += 1; w[2] += 1; b[2] += 1
    cases.append(("common-mode +1 at d=2 on all three tables", t, w, b))
    t, b = dict(tot), dict(between)
    t[2], t[4] = t[4], t[2]; b[2], b[4] = b[4], b[2]
    cases.append(("sum-preserving 2<->4 transposition in both", t, wp, b))
    t = dict(tot); t[2] += 1; cases.append(("+1 in tot only", t, wp, between))
    b = dict(between); b[2] += 1; cases.append(("+1 in between only", tot, wp, b))
    w = dict(wp); w[2] += 1; cases.append(("+1 in wp only", tot, w, between))
    k = 0
    for name, t, w, b in cases:
        why = refuses(t, w, b)
        k += why is not None
        out("  %-44s -> %s" % (name, why or "ACCEPTED (defect)"))
    out("GUARD_REJECTS_CORRUPTIONS=%d/%d" % (k, len(cases)))
    # --- verifier closure: the guard must be FALSE when the target (KW's tables) is absent
    non_kw = sensitive and refuses(*other_tabs) is not None
    out("GUARD_REJECTS_NON_KW=%d" % non_kw)
    ok = derived and accepts and why_cm is not None and k == len(cases) and non_kw
    return 0 if ok else 1

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
if not (KW_C3 == round(solve.mean_complement_distance(KW) * 64) == 776):
    raise AssertionError("C3 ground-truth derivation broke")
# the canonical pairing is closed under complement: comp of pair {a,b} is pair {a^63,b^63}
C3_SELFC = [p for p, (a, b) in enumerate(KW_PAIRS) if a ^ b == 63]     # self-complement pairs
C3_COUPLES = []                                                        # unordered {p,q} complement couples
for _p, (_a, _b) in enumerate(KW_PAIRS):
    if _a ^ _b == 63: continue
    _q = PAIR_IDX[frozenset((_a ^ 63, _b ^ 63))]
    if not (_q != _p and _q != 0):
        raise AssertionError("complement couple derivation broke")
    if _p < _q: C3_COUPLES.append((_p, _q))
if not (len(C3_SELFC) == 8 and len(C3_COUPLES) == 12 and 0 in C3_SELFC):
    raise AssertionError('guard failed: len(C3_SELFC) == 8 and len(C3_COUPLES) == 12 and 0 in C3_SELFC')
# a self-complement pair contributes |diff|=1 per member counted twice = 2; a couple with slots
# s,t and orientation offsets e1,e2 contributes 2*(|(2s+e1)-(2t+e2)| + |(2s+1-e1)-(2t+1-e2)|)
# = 8*|s-t| for s != t, orientation-independent (asserted exhaustively):
if not (all(2 * (abs((2*s + e1) - (2*t + e2)) + abs((2*s + 1 - e1) - (2*t + 1 - e2))) == 8 * abs(s - t)
           for s in range(31) for t in range(31) if s != t for e1 in (0, 1) for e2 in (0, 1))):
    raise AssertionError('guard failed: all(2 * (abs((2*s + e1) - (2*t + e2)) + abs((2*s + 1 - e1) - (2*t + 1 - e2))) == 8 * ab...')
# decomposition check on KW itself (KW slot of pair p is p):
if not (2 * len(C3_SELFC) + 8 * sum(abs(u - v) for u, v in C3_COUPLES) == KW_C3):
    raise AssertionError("C3 decomposition broke")

# ---- CC-N8 static facts (Schulz exception co-location), derived from solve imports ----
# ATTRIBUTION: CC-N8 = Schulz 2016 (Hexagrammatics) pp. 14-15, SC-7 double-exception note;
# Schulz 1990 JCP 17:3 for both underlying motifs. Semantics = solve.reg_ccn8: the CC-A2
# (gender) violation set is EXACTLY {25, 26} and both class positions also violate R-S2.
if not (solve.reg_ccn8(KW) is True):
    raise AssertionError("CC-N8 KW ground truth broke")
if not (solve.rc4_violations(KW) == (2, [25, 26])):
    raise AssertionError("CC-A2 KW ground truth broke")
if not (solve._reg_rs2_violations(KW) == [11, 13, 14, 25, 26, 32]):
    raise AssertionError("R-S2 KW ground truth broke")

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
    if not (_rs2_viol_from_bal(solve._reg_balances(solve._reg_stations(_perm)))
            == solve._reg_rs2_violations(_perm)):
        raise AssertionError("R-S2 balance-replica derivation broke")
if not (_rs2_viol_from_bal(solve._reg_balances(solve._reg_stations(KW))) == [11, 13, 14, 25, 26, 32]):
    raise AssertionError('guard failed: _rs2_viol_from_bal(solve._reg_balances(solve._reg_stations(KW))) == [11, 13, 14, 25, 26...')

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
    if not (_rs2_r_after(_prefix) == _rprev):
        raise AssertionError('guard failed: _rs2_r_after(_prefix) == _rprev')
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
        if not (_pred == ({25, 26} <= set(_rs2_viol_from_bal(_bal)))):
            raise AssertionError("R-S2 CNF case analysis broke")

KW_BAL = solve._reg_balances(solve._reg_stations(KW))
KW_RS2_R24 = _rs2_r_after(KW_BAL[:24])   # True on KW: position 24 is zero-balance
# gender-violation popcounts by class-position parity (solve.rc4_violations semantics:
# {0,3,6} exempt; violation iff (pc < 3) != (position odd)) — used by the CC-N8 clauses:
if not (all(((w < 3) != bool(pos % 2)) == (w in ((4, 5) if pos % 2 else (1, 2)))
           for w in (1, 2, 4, 5) for pos in (24, 25, 26, 27))):
    raise AssertionError('guard failed: all(((w < 3) != bool(pos % 2)) == (w in ((4, 5) if pos % 2 else (1, 2))) for w in (1, 2...')

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
if not (solve.reg_ccn4(KW) is True):
    raise AssertionError("CC-N4 KW ground truth broke")
if not (all((solve.upper_trigram(h) << 3) | solve.lower_trigram(h) == h for h in range(64))):
    raise AssertionError("trigram-pair bijection broke")
CCN4_STATIONS = (25, 26, 27, 28)
_st_kw = solve._reg_stations(KW)
CCN4_REQ = {s: _st_kw[s - 1][0] for s in CCN4_STATIONS}
# the required faces are inversion-asymmetric — the encoder's palindrome-pair in-window
# forbid ("a palindrome face can never match") is sound only because of this:
if not (all(solve.reverse_6bit(v) != v for v in CCN4_REQ.values())):
    raise AssertionError("CC-N4 face palindromicity broke")

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
    if not (_ccn4_predict(_perm) == solve.reg_ccn4(_perm)):
        raise AssertionError("CC-N4 replica/scorer drift")
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
if not (len(_c4early) == 2):
    raise AssertionError("CC-N4 positive-control mutant needs 2 early non-palindrome pairs")
for _mut, _want in ((_kw_mut(flips=(_c4slot[25],)), False),
                    (_kw_mut(swaps=((_c4slot[25], _c4slot[26]),)), False),
                    (_kw_mut(swaps=(tuple(_c4early),)), True)):
    if not (_mut != KW and _ccn4_predict(_mut) == solve.reg_ccn4(_mut) == _want):
        raise AssertionError("CC-N4 mutant endorsement broke")
# ccn4-kwfail table: the required faces PERMUTED (S25<->S26 and S27<->S28 values
# swapped) — derived from CCN4_REQ, not hand-written. A derangement on distinct
# values, so KW pinned against it must mismatch at ALL FOUR stations [expect UNSAT]:
CCN4_REQ_FAIL = {25: CCN4_REQ[26], 26: CCN4_REQ[25], 27: CCN4_REQ[28], 28: CCN4_REQ[27]}
if not (all(_st_kw[_s - 1][0] != CCN4_REQ_FAIL[_s] for _s in CCN4_STATIONS)):
    raise AssertionError("ccn4-kwfail derangement broke (KW matches a permuted face)")

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
if not (len(_dsol) == 1):
    raise AssertionError("parity differencing under-determined (%d candidates)" % len(_dsol))
_D = _dsol[0]
MOORE_COUNTED = {p: _D[p] != 0 for p in range(1, 32)}   # scored by g1/g2 ("directional")
MOORE_WANT_ODD = {p: _D[p] == 1 for p in range(1, 32) if _D[p] != 0}
if not (sum(MOORE_COUNTED.values()) == 18):
    raise AssertionError("expected 18 counted (directional) pairs")
for _p in range(1, 32):                           # g1 must be orientation-blind
    for _base in (_A0, _A1):                      # (checks pair _p at both parities)
        _fl = list(_base)
        _fl[_fl.index((_p, 0))] = (_p, 1)
        if not (_g1(_fl) == _g1(_base)):
            raise AssertionError("g1 orientation-dependent at pair %d" % _p)

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
        if not (_br in (0, 1)):
            raise AssertionError("rhythm adjacency probe not isolated")
        MOORE_BREAK[(_po1, _po2)] = _br
for (_po1, _po2), _b in MOORE_BREAK.items():      # sanity: relation is symmetric
    if not (MOORE_BREAK[(_po2, _po1)] == _b):
        raise AssertionError("rhythm break relation asymmetric")
# sanity: the probed relation is a two-class (rising/falling) equality relation
_ref = _CO[0]
_cls = {_ref: 0}
for _po in _CO:                                   # other pairs: classify against ref
    if _po[0] != _ref[0]:
        _cls[_po] = _cls[_ref] if MOORE_BREAK[(_ref, _po)] else 1 - _cls[_ref]
_sib = (_ref[0], 1 - _ref[1])                     # ref's orientation-sibling: via _CO[2]
_cls[_sib] = _cls[_CO[2]] if MOORE_BREAK[(_CO[2], _sib)] else 1 - _cls[_CO[2]]
for (_po1, _po2), _b in MOORE_BREAK.items():
    if not (_b == (1 if _cls[_po1] == _cls[_po2] else 0)):
        raise AssertionError("break relation not 2-colorable")

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
if not (_moore_predict(_A0) == _moore_scores(KW) \
    == tuple(solve.R11_KW_EXPECTED[:2]) == (2, 2)):
    raise AssertionError("KW Moore ground truth broke")
_rng_m = _random.Random(191)
for _t in range(300):
    _pp = list(range(1, 32)); _rng_m.shuffle(_pp)
    _arr = [(_p, _rng_m.randint(0, 1)) for _p in _pp]
    if not (_moore_predict(_arr) == _moore_scores(_arr_seq(_arr))):
        raise AssertionError("Moore table/scorer drift")

# ---- CNF builder ----
class CNF:
    def __init__(self): self.n = 0; self.cl = []; self.marks = []
    def var(self): self.n += 1; return self.n
    def add(self, *lits): self.cl.append(list(lits))
    def mark(self, stage):
        """Name the clause family that starts at the next clause (2026-09-03). Marks are
        bookkeeping beside `cl`, never inside it -- write() ignores them, so emitted CNFs are
        byte-identical to the unmarked era. They exist so that model_check() can say WHICH family
        a falsified clause belongs to: for the King Wen assignment under an UNSAT target, that is
        the over-constraint control Q-58 lacks for build() (KW must falsify the theorem's own
        clauses and nothing else)."""
        self.marks.append((len(self.cl), stage))
    def stage_of(self, ci):
        stage = "(unmarked)"
        for start, name in self.marks:
            if start <= ci:
                stage = name
            else:
                break
        return stage
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

# ---- cardinality-only subset targets (2026-09-02; TR-6 abstract, Codex V2-F08 #3) ----
# `<target>-noY` emits exactly the clauses of <target> in which no Y variable occurs. The
# selection rule is that one predicate and nothing else: the Y variables are allocated FIRST in
# build() (1..NY, NY = len(SLOTS)*NJ = 1922), so "no Y variable" is "every |literal| > NY", and
# the emitted formula is a syntactic subset of the full CNF with numbering unchanged. Scope is
# the two alternation targets only: the private record of the 2026-08-29 run (le-14 11,073 of
# 240,039 clauses, ge-16 11,134 of 240,100, both UNSAT, both DRAT `s VERIFIED`) was the
# justification for TR-6's "corroborating, not independent" retraction, and this flag exists so
# that record is reproducible from the public tree. Other targets are refused, not extrapolated.
NOY_SUFFIX = "-noY"
NOY_TARGETS = ("alt-le-14", "alt-ge-16")

def split_noy(target):
    """(base_target, is_noy) for `target`; refuses -noY on any base but NOY_TARGETS."""
    if not target.endswith(NOY_SUFFIX):
        return target, False
    base = target[:-len(NOY_SUFFIX)]
    if base not in NOY_TARGETS:
        raise SystemExit("%s: the -noY subset is defined for %s only, not %r"
                         % (target, "/".join(NOY_TARGETS), base))
    return base, True

def noy_subset(cnf, ny):
    """The clauses of `cnf` mentioning no variable in 1..ny, as a new CNF with the SAME
    variable count. Returns (subset, dropped). Verifier-closure: the result is re-scanned, and
    a surviving Y literal raises -- the function may not vouch for its own filter."""
    if ny != len(SLOTS) * NJ:              # anchor independent of the allocator's bookkeeping
        raise SystemExit("noy_subset: Y range %d != len(SLOTS)*NJ = %d; something was allocated "
                         "before the Y block, so the predicate would misname a variable"
                         % (ny, len(SLOTS) * NJ))
    sub = CNF(); sub.n = cnf.n
    keep, drop = [], []
    for c in cnf.cl:
        (keep if all(abs(l) > ny for l in c) else drop).append(c)
    # both directions, re-scanned from the partition, not from the predicate that built it:
    # every kept clause is Y-free AND every dropped clause names a Y variable
    leaked = sum(1 for c in keep for l in c if abs(l) <= ny)
    wrongly_dropped = sum(1 for c in drop if not any(abs(l) <= ny for l in c))
    if leaked != 0 or wrongly_dropped != 0:
        raise SystemExit("noy_subset: partition check failed (%d Y literal(s) kept, %d Y-free "
                         "clause(s) dropped)" % (leaked, wrongly_dropped))
    if len(keep) + len(drop) != len(cnf.cl) or not (0 < len(keep) < len(cnf.cl)):
        raise SystemExit("noy_subset: implausible subset %d of %d clauses (an empty or total "
                         "subset means the Y range %d is wrong)" % (len(keep), len(cnf.cl), ny))
    sub.cl = keep
    return sub, len(drop)


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
    target, _ = split_noy(target)
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
    target, noy = split_noy(target)
    if noy and (with_c3 or c3_max is not None or c3_min is not None or not_kw
                or "-near-" in target):
        raise SystemExit("%s%s refuses --with-c3/--c3-max/--c3-min/--not-kw and -near-: each "
                         "adds Y-touching clauses that the -noY predicate would then silently "
                         "drop, so the label would name a formula the file does not contain"
                         % (target, NOY_SUFFIX))
    tbase = target.split("-near-")[0]
    rules = target_rules(target)
    cnf = CNF()
    Y = {}
    for s in SLOTS:
        for j in range(NJ):
            Y[(s, j)] = cnf.var()
    ny = cnf.n                            # Y vars are exactly 1..ny (allocated first, nothing before)
    cnf.mark("C1 one (pair,orient) per slot")
    for s in SLOTS:                       # one (pair,orient) per slot
        exactly_one(cnf, [Y[(s, j)] for j in range(NJ)])
    cnf.mark("C1 each pair exactly once")
    for p in range(1, 32):                # each pair used exactly once (across slots+orients)
        lits = [Y[(s, j)] for s in SLOTS for j in range(NJ) if ORIENTS[j][0] == p]
        exactly_one(cnf, lits)

    # transition structure: exit(slot s) -> entry(slot s+1); slot0 exit is hexagram 0
    def exit_hex(j):  return ORIENTS[j][3]
    def entry_hex(j): return ORIENTS[j][2]

    # C2 + distance indicators for C5
    cnf.mark("C2 + boundary distance indicators")
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
    cnf.mark("C5 boundary multiset budget")
    for d, k in BETWEEN_MULTISET.items():
        exactly_k(cnf, [T[(s, d)] for s in range(31)], k)

    if target in ("alt-le-14", "alt-ge-16"):
        cnf.mark("alternation bound (%s)" % target)
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
            k = int(target.split("-near-", 1)[1])
        except ValueError:
            raise SystemExit("bad -near- suffix in target %r: "
                             "expected an integer slot count" % target)
        # Q-311 (2026-09-03): `rsplit("-", 1)` read `-near--1` as k=1 (the sign was the split
        # point) and k > 31 encoded nothing (at_least_k with a negative bound is vacuous), both
        # silently. The count is a slot count: 0..len(SLOTS).
        if not (0 <= k <= len(SLOTS)):
            raise SystemExit("bad -near- suffix in target %r: slot count must be 0..%d, got %d"
                             % (target, len(SLOTS), k))
        cnf.mark("near-%d slot agreement with KW" % k)
        agree = []
        for s in SLOTS:
            jkw = next(j for j in range(NJ) if ORIENTS[j][0] == s and ORIENTS[j][1] == 0)
            agree.append(Y[(s, jkw)])
        at_least_k(cnf, agree, 31 - k)
    if "parity" in rules:
        cnf.mark("rule parity")
        for s in SLOTS:                   # parity: static unary forbids (tables derived from solve.r11_axes g1)
            for j in range(NJ):
                p = ORIENTS[j][0]
                if MOORE_COUNTED[p]:
                    if MOORE_WANT_ODD[p] != ((s + 1) % 2 == 1):   # pair POSITION = slot index + 1 (slot 0 = position 1)
                        cnf.add(-Y[(s, j)])
    if "rhythm" in rules:
        cnf.mark("rule rhythm")
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
        cnf.mark("inversion-class position counter")
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
            cnf.mark("rule gender")
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
            cnf.mark("rule ccn4" + (" (faces permuted)" if target == "ccn4-kwfail" else ""))
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
            cnf.mark("rule ccn8 (locus %d,%d)" % (A, A + 1) if "ccn8" in rules
                     else "ccn8 chain machinery (%s)" % tbase)
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
            cnf.mark("KW pin (validation target)")
            for st in SLOTS:
                jkw = next(j for j in range(NJ) if ORIENTS[j][0] == st and ORIENTS[j][1] == 0)
                cnf.add(Y[(st, jkw)])
    if target == "wrap-d5":
        # wrap distance 5 from s0=63  <=>  popcount(second hexagram of slot 31) == 1
        cnf.mark("wrap-d5")
        for j in range(NJ):
            if pc(ORIENTS[j][3]) != 1:
                cnf.add(-Y[(31, j)])
    if target in ("kw-pin", "moore-kwtest", "rhythm-kwtest"):
        # kw-pin: full KW pin, no extra rule clauses (pair with --with-c3 gates).
        # moore-kwtest / rhythm-kwtest (F-1 gates): KW pin + the strict parity /
        # rhythm clauses added above — UNSAT with conflicts at EXACTLY the
        # solve.r11_axes-scored loci (2 parity violations / 2 rhythm breaks);
        # tests.py decides both solver-free via unit propagation.
        cnf.mark("KW pin (%s)" % target)
        for st in SLOTS:
            jkw = next(j for j in range(NJ) if ORIENTS[j][0] == st and ORIENTS[j][1] == 0)
            cnf.add(Y[(st, jkw)])
    if not_kw:
        cnf.mark("not-kw layout exclusion")
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
        cnf.mark("C3 slot/distance ladder")
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
            cnf.mark("C3 <= %d bound" % bound)
            at_most_k(cnf, dlits, sbudget - len(C3_COUPLES))
        if c3_min is not None:
            # C3 >= m  <=>  S >= ceil((m - 2*|C3_SELFC|) / 8); S = |couples| + #true dlits
            s_lower = -((c3_min - 2 * len(C3_SELFC)) // -8)
            if s_lower - len(C3_COUPLES) > len(dlits):
                raise SystemExit("--c3-min %d exceeds the encodable maximum" % c3_min)
            if s_lower > len(C3_COUPLES):
                cnf.mark("C3 >= %d bound" % c3_min)
                at_least_k(cnf, dlits, s_lower - len(C3_COUPLES))
    if noy:
        sub, dropped = noy_subset(cnf, ny)
        # whole-line verdict tokens (grep -qx); the population a caller must see before trusting
        # a subset UNSAT -- an extractor that quietly kept 0 or all clauses would still be "UNSAT"
        print("NOY_Y_VARS=%d" % ny)
        print("NOY_TOTAL_CLAUSES=%d" % len(cnf.cl))
        print("NOY_KEPT_CLAUSES=%d" % len(sub.cl))
        print("NOY_DROPPED_CLAUSES=%d" % dropped)
        # re-COUNTED from the object being returned, not asserted from noy_subset's contract:
        # a token that is printed as a constant is a claim, not a measurement (2026-09-03)
        y_left = sum(1 for c in sub.cl for l in c if abs(l) <= ny)
        print("NOY_Y_LITERALS_IN_OUTPUT=%d" % y_left)
        if y_left:
            raise SystemExit("noy_subset returned %d Y literal(s); refusing to emit" % y_left)
        return sub, Y
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
if not (len(_G48) == 48):
    raise AssertionError("centralizer of rev in S6 must have order 48")
_PSETS = [frozenset(pr) for pr in KW_PAIRS]
_SET2PAIR = {s: i for i, s in enumerate(_PSETS)}
def _pair_perm(g):
    return tuple(_SET2PAIR[frozenset(_hex_act(g, h) for h in _PSETS[p])] for p in range(32))
_coset = {}
for _g in sorted(_G48):
    _coset.setdefault(_pair_perm(_g), []).append(_g)
if not (len(_coset) == 24):
    raise AssertionError("record-level pair group must be S4 (order 24)")
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
if not (sorted(len(o) for o in PAIR_ORBITS) == [3, 3, 3, 4, 6, 6, 6]):
    raise AssertionError("pair-orbit sizes broke")

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
    # Q-311: `spec.index("@")` raises ValueError and `int(...)` raises on a non-numeric
    # suffix -- both bare tracebacks, the same shape as the four CLI integer flags fixed
    # earlier today. A spec is operator-typed, so it gets the same courtesy.
    if "@" not in spec:
        raise SystemExit("spec %r needs an @START suffix, e.g. '3.0,3.1,3.2@0'" % spec)
    at = spec.index("@")
    try:
        start = int(spec[at + 1:])
    except ValueError:
        raise SystemExit("spec %r: @START must be an integer, got %r" % (spec, spec[at + 1:]))
    body = spec[:at]
    pl = []
    for tok in body.split(","):
        L, I = tok.split("."); pl += _orbit_by(int(L), int(I))
    if not (len(pl) == npairs):
        raise AssertionError("union table inconsistency")
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
    if not (dfs(0, start_exit, 0)):
        raise AssertionError("no valid completion exists for the subset")
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
    cnf.mark("C1 one (pair,orient) per slot")
    for s in slots:                       # one (pair,orient) per slot
        exactly_one(cnf, [Y[(s, j)] for j in range(nj)])
    cnf.mark("C1 each pair exactly once")
    for lp in range(n):                   # each pair used exactly once
        exactly_one(cnf, [Y[(s, j)] for s in slots for j in range(nj) if orients[j][0] == lp])

    def exit_hex(j):  return orients[j][3]
    def entry_hex(j): return orients[j][2]

    cnf.mark("C2 + boundary distance indicators")
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
    cnf.mark("C5 boundary budget B0")
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

def rule_scores(seq):
    """Violation count of EVERY rule in FIVE_RULES on a 64-hexagram sequence, each through the
    solve.py scorer that defines the rule: parity/rhythm = solve.r11_axes g1/g2 (via
    _moore_scores), gender = solve.rc4_violations, ccn4/ccn8 = solve.reg_ccn4/reg_ccn8 (True is
    0 violations; anything else counts 1). Until 2026-09-03 the witness loop re-scored THREE of
    the five (Codex V2 A09 row 14): target_rules("five-sub-ccn4") named a rule nothing re-scored,
    so an ordering with solve.reg_ccn4() == False was printed as `WITNESS:` (measured on the
    shipped file with a stub solver). The key set is asserted == FIVE_RULES at import, so a sixth
    rule added without a scorer here fails the import, not the witness."""
    g1, g2 = _moore_scores(seq)
    return {"parity": g1, "rhythm": g2, "gender": solve.rc4_violations(seq)[0],
            "ccn4": 0 if solve.reg_ccn4(seq) is True else 1,
            "ccn8": 0 if solve.reg_ccn8(seq) is True else 1}

if not (set(rule_scores(KW)) == set(FIVE_RULES)):
    raise AssertionError("rule_scores() must score exactly FIVE_RULES; a target could name a "
                         "rule the witness loop cannot re-score")
if not (rule_scores(KW) == {"parity": 2, "rhythm": 2, "gender": 2, "ccn4": 0, "ccn8": 0}):
    raise AssertionError("KW five-rule ground truth broke: %r" % rule_scores(KW))

def verify_seq(seq):
    """Round-trip re-verification of a decoded 64-hexagram sequence against
    solve.py: C1 (permutation), C2 (no distance-5 step), C5 (transition
    multiset), C3 total — AND (F-1) a re-score of the literature axes on the
    decoded witness: g1 Moore-2005 parity violations + g2 Moore-1989 rhythm
    breaks (both via _moore_scores -> solve.r11_axes) and g3 Schulz gender
    violations (solve.rc4_violations). Returns (ok, c3, (g1, g2, g3));
    scores is None when the base checks fail, and c3 is None when the sequence
    is not a permutation of 0..63 (until 2026-09-03 that case was a KeyError
    traceback: an empty model decoded to [63, 0] and crashed here). The three
    scores are the first three of rule_scores(); target_verdict() is the
    five-rule form."""
    perm = len(seq) == 64 and set(seq) == set(range(64))
    ok = perm and solve.has_no_five(seq)
    # C5 against solve.py's OWN multiset (solve.h2_pop_valid -> solve.h2_kw_multiset), not the
    # module table the encoder shares: until 2026-09-02 this compared against `_tot`, so a wrong
    # `_tot` would have been confirmed by the round trip meant to catch it (Codex V2 A09 row 17).
    ok = ok and solve.h2_pop_valid(seq)
    c3 = None
    if perm:
        pos = {h: i for i, h in enumerate(seq)}
        c3 = sum(abs(pos[h] - pos[h ^ 63]) for h in range(64))
    scores = None
    if ok:
        rs = rule_scores(seq)
        scores = (rs["parity"], rs["rhythm"], rs["gender"])
    return ok, c3, scores

def target_verdict(seq, target, with_c3=False, c3_max=None, c3_min=None, skip_rules=False):
    """ONE verdict for a decoded 64-hexagram sequence against `target` and the C3 flags, shared
    by --decode and --witness so the two cannot disagree (2026-09-03, Codex V2 A09 rows 14/19:
    --decode never consulted the target, both paths re-scored 3 of 5 rules, and both carried a
    literal 776 where `(c3_max or KW_C3)` sat one line away). Fields:
      base       verify_seq() ok: C1, C2, C5 via solve.py
      c3         complement-distance total, or None if not a permutation
      scores     rule_scores() dict, or None when base fails
      rules      the rules `target` enforces strictly (target_rules), or set() if skip_rules
      rule_viol  {rule: violations} over `rules` with a non-zero score (None when base fails)
      c3_encoded True iff C3 is natively in the formula (--with-c3 / --c3-max / --c3-min)
      c3_ok      C3 inside the requested window; with no C3 flag the window is the default
                 witness policy c3 <= KW_C3 (776)
      c3_label   the human-readable C3 verdict
      ok         base and no rule violation and c3_ok"""
    base, c3, _ = verify_seq(seq)
    rules = set() if skip_rules else target_rules(target)
    scores = rule_scores(seq) if base else None
    rule_viol = ({r: scores[r] for r in sorted(rules) if scores[r] != 0}
                 if scores is not None else None)
    rules_ok = base and not rule_viol
    hi = c3_max if c3_max is not None else KW_C3
    if c3 is None:
        c3_ok, label = False, "fail C3 (not a permutation)"
    elif c3_min is None:
        c3_ok = c3 <= hi
        label = ("c3<=%d PASS" % hi) if c3_ok else "fail C3 (c3=%d > %d)" % (c3, hi)
    else:
        lo_ok = c3 >= c3_min
        hi_ok = (not with_c3) or c3 <= hi
        c3_ok = lo_ok and hi_ok
        label = ("c3 window PASS" if c3_ok else
                 ("fail c3-min (c3=%d < %d)" % (c3, c3_min) if not lo_ok
                  else "fail c3-max (c3=%d > %d)" % (c3, hi)))
    return {"base": base, "c3": c3, "scores": scores, "rules": rules, "rule_viol": rule_viol,
            "c3_encoded": bool(with_c3 or c3_min is not None), "c3_ok": c3_ok,
            "c3_label": label, "ok": bool(rules_ok and c3_ok)}

def model_check(cnf, lits, exclude_stages=()):
    """Does the literal list `lits` satisfy `cnf`? Unit-propagates from `lits` (queue-based,
    occurrence-indexed, so it costs one pass over the literal occurrences) and tallies every
    clause as satisfied / falsified / undetermined. Returns a dict:
      falsified     clauses with every literal false -- any non-zero count is a refutation
      undetermined  clauses with no true literal and >= 1 unassigned variable (a PARTIAL model,
                    e.g. the 31 Y literals of a sequence, leaves counter registers open)
      satisfied     the rest
      conflict      index of the first falsified clause met during propagation, or None
      foreign       literals naming a variable > cnf.n (a model of a DIFFERENT formula --
                    other flags or target -- which the variable map would still "decode")
      assigned      variables fixed after propagation
      verdict       SATISFIED (0 falsified, 0 undetermined) / CONSISTENT (0 falsified, some
                    undetermined) / FALSIFIED
      attribution   "exact" when `lits` assign every variable (nothing is propagated; the tally
                    is a direct evaluation) or "first-conflict" for a PARTIAL model
    WHAT IS ORDER-INDEPENDENT AND WHAT IS NOT (Fable review 2026-09-03). The verdict is: a unit
    propagation conflict is reachable under one propagation order iff under every order, and
    when no conflict exists the closure is unique, so SATISFIED / CONSISTENT / FALSIFIED and
    the conflict-free tallies do not depend on the queue. The falsified COUNT and the FAMILY
    names under FALSIFIED on a partial model do: when two clauses force opposite values, the
    one that fires first wins and the other is what ends up falsified. Measured on the 31 Y
    literals of King Wen under alt-le-14: this tally names "C2 + boundary distance indicators"
    beside the alternation bound, although KW satisfies C2; a clause-order sweep names the
    bound alone. So `falsified_by_stage` is a first-conflict attribution for a partial model
    and exact only for a full one (the witness loop's case). The exclusion form below
    (`exclude_stages`) is the sound family-level control: "falsified == 0 on the formula minus
    these families" is order-independent by the argument above.
    Until 2026-09-03 nothing in this file checked that the literals handed to decode() were a
    model of the formula whose variable map decodes them: --decode took any integer list, and
    --witness re-verified the decoded SEQUENCE against solve.py but never the solver's claimed
    MODEL against the CNF -- so a solver that answered `s SATISFIABLE` with a stale assignment
    (measured with a stub that ignored the blocking clauses) was never contradicted. The
    sequence-level round trip catches an UNDER-constrained formula; this is the leg that
    catches a solver or a model file, and -- run on the King Wen assignment under an UNSAT
    target -- the OVER-constraint control Q-58 has no other executable form of for build()."""
    clauses = cnf.cl
    if exclude_stages:
        # the family-exclusion control: the same literals against the formula MINUS the named
        # families. An UNSAT target's theorem family and the rule families KW is known (by
        # solve.py's own scorers) to violate are excluded, and KW must then falsify NOTHING --
        # attribution by "which clause ended up falsified" is propagation-order dependent (a
        # gender forbid and the counter implication it contradicts blame each other), exclusion
        # is not.
        known = set(name for _, name in cnf.marks)
        unknown = sorted(set(exclude_stages) - known)
        if unknown:
            # a misspelt family would silently exclude nothing, and the control would then be
            # measuring one formula while reporting another
            raise ValueError("model_check: exclude_stages names no clause family of this "
                             "formula: %s (families: %s)" % (unknown, sorted(known)))
        keep = [ci for ci in range(len(cnf.cl)) if cnf.stage_of(ci) not in exclude_stages]
        sub = CNF(); sub.n = cnf.n; sub.cl = [cnf.cl[ci] for ci in keep]
        sub.marks = [(k, cnf.stage_of(ci)) for k, ci in enumerate(keep)
                     if k == 0 or cnf.stage_of(ci) != cnf.stage_of(keep[k - 1])]
        return model_check(sub, lits)
    occ = {}
    for ci, c in enumerate(clauses):
        for l in c:
            occ.setdefault(abs(l), []).append(ci)
    val, queue, conflict = {}, [], None
    foreign = sum(1 for l in lits if abs(l) > cnf.n or l == 0)
    for l in lits:
        v, s = abs(l), l > 0
        if l == 0 or v > cnf.n:
            continue
        if val.get(v, s) != s:
            conflict = -1                     # contradictory input literals
            break
        if v not in val:
            val[v] = s; queue.append(v)
    # the formula's OWN unit clauses (E[0][0], R[0], the C4 P pins, a KW pin) seed propagation
    # too; without this the inversion-class counter never starts and a KW-pinned UNSAT target
    # (ccn8-kwchain-not) read CONSISTENT with 1,091 undetermined clauses (measured 2026-09-03)
    # Every unit seeds, whatever was met before it (Fable review 2026-09-03: this loop stopped
    # seeding at the first contradicted unit, so a kw-pin formula handed one anti-pin literal
    # assigned 152 variables and left 237,400 clauses undetermined where the closure assigns
    # 6,820 and leaves 60 -- the verdict was right, the tallies were not)
    for ci, c in enumerate(clauses):
        if len(c) == 1:
            v, s = abs(c[0]), c[0] > 0
            if v not in val:
                val[v] = s; queue.append(v)
            elif val[v] != s and conflict is None:
                conflict = ci
    # Propagation CONTINUES past a falsified clause (the first is remembered): every unit
    # consequence of the input literals is still drawn. On a FULL model nothing propagates and
    # the tally is exact; on a partial one it is a first-conflict attribution (docstring) --
    # the KW control's "nothing else fails" claim is made through exclude_stages, not here.
    while queue and conflict != -1:
        v = queue.pop()
        for ci in occ.get(v, ()):
            c = clauses[ci]
            n_un, last_un, sat_ = 0, None, False
            for l in c:
                w = val.get(abs(l))
                if w is None:
                    n_un += 1; last_un = l
                elif w == (l > 0):
                    sat_ = True; break
            if sat_:
                continue
            if n_un == 0:
                if conflict is None:
                    conflict = ci
            elif n_un == 1:
                val[abs(last_un)] = last_un > 0; queue.append(abs(last_un))
    falsified = undetermined = satisfied = 0
    false_stages, undet_stages = {}, {}
    for ci, c in enumerate(clauses):
        state = "F"
        for l in c:
            w = val.get(abs(l))
            if w is None:
                state = "U"
            elif w == (l > 0):
                state = "S"; break
        if state == "S":
            satisfied += 1
        elif state == "U":
            undetermined += 1
            st = cnf.stage_of(ci)
            undet_stages[st] = undet_stages.get(st, 0) + 1
        else:
            falsified += 1
            st = cnf.stage_of(ci)
            false_stages[st] = false_stages.get(st, 0) + 1
    verdict = ("FALSIFIED" if falsified or conflict is not None or foreign else
               "SATISFIED" if undetermined == 0 else "CONSISTENT")
    full_input = len(set(abs(l) for l in lits if l != 0 and abs(l) <= cnf.n)) == cnf.n
    return {"falsified": falsified, "undetermined": undetermined, "satisfied": satisfied,
            "conflict": conflict, "foreign": foreign, "assigned": len(val),
            "attribution": "exact" if full_input else "first-conflict",
            "falsified_stages": sorted(false_stages), "falsified_by_stage": false_stages,
            "undetermined_by_stage": undet_stages, "verdict": verdict}

def _print_model_check(mc, cnf):
    """The model_check() result as whole-line KEY=value tokens (grep -qx)."""
    print("MODEL_CHECK=%s" % mc["verdict"])
    print("MODEL_FALSIFIED_CLAUSES=%d" % mc["falsified"])
    print("MODEL_UNDETERMINED_CLAUSES=%d" % mc["undetermined"])
    print("MODEL_FOREIGN_LITERALS=%d" % mc["foreign"])
    print("MODEL_FALSIFIED_BY_FAMILY=%s" % (
        ";".join("%s:%d" % kv for kv in sorted(mc["falsified_by_stage"].items())) or "none"))
    print("MODEL_FAMILY_ATTRIBUTION=%s" % mc["attribution"])       # exact | first-conflict
    # a model file asserting both x and -x is FALSIFIED with 0 falsified clauses; say why
    print("MODEL_INPUT_CONTRADICTORY=%d" % (mc["conflict"] == -1))
    print("  satisfied=%d assigned=%d/%d vars" % (mc["satisfied"], mc["assigned"], cnf.n))

def _read_model_lits(path):
    """Parse a solver model: DIMACS 'v '-lines, or a bare whitespace/newline
    separated list of signed ints (trailing 0 terminator ignored). Exits with a
    message on a token that is not an integer and on a file with no literals
    (both were tracebacks -- ValueError / KeyError -- until 2026-09-03; Q-311)."""
    lits = []
    with open(path) as fh:
        text = fh.read()
    vlines = [ln for ln in text.splitlines() if ln.startswith("v ")]
    tokens = ([x for ln in vlines for x in ln[2:].split()] if vlines
              else [x for ln in text.splitlines() if not ln.startswith(("c", "s "))
                    for x in ln.split()])
    for x in tokens:
        try:
            l = int(x)
        except ValueError:
            raise SystemExit("%s: model token %r is not an integer literal" % (path, x))
        if l != 0:
            lits.append(l)
    if not lits:
        raise SystemExit("%s: no literals found (expected DIMACS 'v' lines or a bare integer "
                         "list); nothing to decode" % path)
    return lits

# ============================================================================
# --certify-count: independently CERTIFIED model count via D4 + CPOG.
# ----------------------------------------------------------------------------
# EXTERNAL DEPENDENCY (OPTIONAL — this subcommand ONLY). --certify-count
# requires the D4 d-DNNF compiler (https://github.com/crillab/d4) and the CPOG
# certified-knowledge-compilation toolchain's cpog-gen + cpog-check
# (https://github.com/rebryant/cpog; Bryant/Nawrocki/Avigad, SAT 2023) on
# PATH. NOTHING else in sat.py needs them: if they are absent, the subcommand
# exits gracefully with an install message (the same graceful-absence idiom as
# roae.py's optional Graphviz `dot` step) and every other subcommand is unaffected — mirroring
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
    (roae.py Graphviz `dot`): a missing binary exits with a clear install
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
    # Q-311: validate --keep BEFORE the work, not at the end. certify_count runs d4 and
    # cpog-gen for minutes and writes gigabytes; discovering an unwritable directory after
    # that discards the run. Fail in the first millisecond instead.
    wd = keep_dir or tempfile.mkdtemp(prefix="sat_certify_")
    if keep_dir:
        try:
            os.makedirs(wd, exist_ok=True)
        except OSError as e:
            raise SystemExit("--keep %r cannot be created: %s" % (keep_dir, e))
        if not os.path.isdir(wd):
            raise SystemExit("--keep %r exists but is not a directory" % keep_dir)
        if not os.access(wd, os.W_OK):
            raise SystemExit("--keep %r is not writable" % keep_dir)
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

    given = set()                                    # modifiers seen, for the applicability check
    with_c3, c3_max, c3_min, not_kw, npairs = False, None, None, False, None
    if "--with-c3" in args:
        with_c3 = True; args.remove("--with-c3"); given.add("--with-c3")
    if "--c3-max" in args:
        i = args.index("--c3-max")
        with_c3, c3_max = True, _int_arg('--c3-max', args, i); del args[i:i + 2]; given.add("--c3-max")
    if "--c3-min" in args:                           # C3 >= N (does NOT imply the <= ceiling)
        i = args.index("--c3-min")
        c3_min = _int_arg('--c3-min', args, i); del args[i:i + 2]; given.add("--c3-min")
    if "--not-kw" in args:
        not_kw = True; args.remove("--not-kw"); given.add("--not-kw")
    if "--f1-pairs" in args:                         # reduced subset instance (TASK #225 probe)
        i = args.index("--f1-pairs")
        npairs = _int_arg('--f1-pairs', args, i); del args[i:i + 2]; given.add("--f1-pairs")
    if npairs is not None and (with_c3 or c3_min is not None or not_kw):
        raise SystemExit("--f1-pairs subset instances encode C1&C2&C4&C5 only: "
                         "--with-c3/--c3-max/--c3-min/--not-kw do not apply")
    expect, keep_dir = None, None                    # --certify-count modifiers
    if "--expect" in args:
        i = args.index("--expect")
        expect = _int_arg('--expect', args, i); del args[i:i + 2]; given.add("--expect")
    if "--keep" in args:
        i = args.index("--keep")
        if i + 1 >= len(args):                       # Q-311: was an IndexError traceback
            raise SystemExit("--keep needs a directory (none was given)")
        keep_dir = args[i + 1]; del args[i:i + 2]; given.add("--keep")

    # 🔴 An UNRECOGNISED flag was silently ignored. Measured 2026-08-28: `--c3max 776` -- one
    # missing hyphen, the most likely typo there is -- left sat.py printing its help banner and
    # exiting 0 with NO CNF written. A scripted caller sees success and no file. That is worse
    # than emitting the wrong formula, because rc=0 is an assertion that the command ran.
    # Same silent-ignore class as Q-309 (`--f1-pairs` with C3 flags), one layer out: there the
    # flag was accepted and dropped, here the whole invocation is.
    run = False                                      # --rigidity-cnf only: decide via kissat (+ drat-trim)
    if "--run" in args:
        run = True; args.remove("--run")
    if run and args[:1] != ["--rigidity-cnf"]:
        raise SystemExit("--run applies to --rigidity-cnf only")
    # 2026-09-02 (Codex V2 A08 row 18 / A09 row 20): this guard, installed 2026-08-28, rejected the
    # documented `--rigidity-cnf OUT --run` (rc=1, nothing written) because `--run` was consumed
    # AFTER it -- the complete kissat + DRAT + drat-trim path below was unreachable for five days --
    # and it scanned from index 1, so a mistyped SUBCOMMAND (`--wittness plain`) still printed the
    # help banner and exited 0, the very failure its comment says it closed. `--run` is now consumed
    # first, and args[0] is validated against the closed subcommand list.
    _SUBCOMMANDS = ("--emit-cnf", "--decode", "--witness", "--rigidity-cnf", "--certify-count",
                    "--c5-selfcheck")
    _stray = ([args[0]] if args and args[0] not in _SUBCOMMANDS else []) \
           + [a for a in args[1:] if a.startswith("--")]
    if _stray:
        raise SystemExit("unrecognised flag(s): " + " ".join(_stray) +
                         "\n(a mistyped flag was silently ignored before 2026-08-28; it is an error now)")
    # 2026-09-03 (sibling of A09 row 20 / the Q-309 class): a RECOGNISED modifier on a subcommand
    # it does not apply to was parsed and dropped -- `--emit-cnf plain OUT --expect 5 --keep DIR`
    # wrote the CNF and exited 0 with both modifiers ignored (measured). The subcommand-specific
    # refusals inside the handlers keep their messages; this table catches the rest.
    _APPLIES = {"--emit-cnf": {"--with-c3", "--c3-max", "--c3-min", "--not-kw", "--f1-pairs"},
                "--decode": {"--with-c3", "--c3-max", "--c3-min", "--not-kw", "--f1-pairs"},
                "--witness": {"--with-c3", "--c3-max", "--c3-min", "--not-kw", "--f1-pairs"},
                "--certify-count": {"--with-c3", "--c3-max", "--c3-min", "--not-kw", "--f1-pairs",
                                    "--expect", "--keep"},
                "--rigidity-cnf": set(), "--c5-selfcheck": set()}
    if args:
        _na = sorted(given - _APPLIES[args[0]])
        if _na:
            raise SystemExit("%s does not apply to %s (it was silently dropped before 2026-09-03; "
                             "it is an error now)" % (" ".join(_na), args[0]))
    # Arity: every handler below matches an exact argument count, and until 2026-09-03 a count
    # that matched none fell through to the help banner with exit 0 -- `--emit-cnf plain` (OUT
    # missing) printed the docstring and reported success (measured). Same class as the
    # mistyped-subcommand fall-through the row-20 fix closed one line above.
    _USAGE = {"--emit-cnf": "TARGET OUT.cnf", "--decode": "MODEL.txt [TARGET]",
              "--witness": "TARGET", "--rigidity-cnf": "OUT.cnf [--run]",
              "--certify-count": "TARGET", "--c5-selfcheck": ""}

    def _out_path(path):
        """Q-311 (2026-09-03): an OUT.cnf whose directory does not exist or is not writable was
        a FileNotFoundError traceback AFTER the (seconds-long) build. Check first."""
        d = os.path.dirname(os.path.abspath(path))
        if not os.path.isdir(d):
            raise SystemExit("%s: directory %s does not exist" % (path, d))
        if not os.access(d, os.W_OK) or (os.path.exists(path) and not os.access(path, os.W_OK)):
            raise SystemExit("%s: not writable" % path)
        return path

    def _emit_label(target):
        if npairs is not None:
            return "f1c5 --f1-pairs %d (C1&C2&C4&C5)" % npairs
        return target + (" c3<=%d" % (c3_max or KW_C3) if with_c3 else "") \
                      + (" c3>=%d" % c3_min if c3_min is not None else "") \
                      + (" not-kw" if not_kw else "")

    if args[:1] == ["--emit-cnf"] and len(args) == 3:
        _out_path(args[2])
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
        # Q-311: rebuilding the CNF to recover the Y map costs real time; a missing or
        # unreadable model file should be reported before that, not as a traceback after.
        if not os.path.isfile(args[1]):
            raise SystemExit("--decode %r: no such file" % args[1])
        if not os.access(args[1], os.R_OK):
            raise SystemExit("--decode %r: not readable" % args[1])
        # --decode MODEL.txt [TARGET]  (rebuilds the CNF to recover the Y map,
        # decodes the model's v-lines to a sequence, re-verifies vs solve.py).
        # Use --f1-pairs N to decode a reduced-subset model; else TARGET (default
        # 'plain') selects a full-31 encoding.
        lits = _read_model_lits(args[1])
        # 2026-09-03: --decode is a VERDICT emitter now (DECODE_VERDICT=PASS/FAIL, exit 0/1). Until
        # today it printed `verify=` and exited 0 whatever it found, consulted no target (a KW model
        # under ccn4-kwfail printed `verify=True` with no CC-N4 line -- Codex V2 A09 row 14), and
        # never checked that the literals are a model of the formula it decoded them with.
        if npairs is not None:
            cnf, ctx = build_subset(npairs)
            mc = model_check(cnf, lits)
            seq = decode_subset(lits, ctx)
            ok, bnd = verify_subset(seq, ctx)
            cls = {dv: bnd.count(dv) for dv in _DVAL}
            print("SEQ (2N=%d):" % len(seq), seq)
            print("verify=%s  boundary-classes=%s  B0=%s"
                  % (ok, [cls[dv] for dv in _DVAL], [ctx["b0"][dv] for dv in _DVAL]))
            _print_model_check(mc, cnf)
            verdict = ok and mc["verdict"] != "FALSIFIED"
        else:
            target = args[2] if len(args) == 3 else "plain"
            if split_noy(target)[1]:
                raise SystemExit("--decode refuses %s: the Y-free subset has no ordering to decode"
                                 % target)
            cnf, Y = build(target, with_c3=with_c3, c3_max=c3_max, c3_min=c3_min, not_kw=not_kw)
            mc = model_check(cnf, lits)
            seq = decode(lits, Y)
            v = target_verdict(seq, target, with_c3=with_c3, c3_max=c3_max, c3_min=c3_min)
            print("SEQ:", seq)
            print("verify=%s  c3=%s  %s" % (v["base"], v["c3"], v["c3_label"]))
            if v["scores"] is not None:
                print("rule re-score (solve.py): " + " ".join(
                    "%s-viol=%d" % (r, v["scores"][r]) for r in FIVE_RULES))
            print("TARGET_RULES=%s" % (",".join(sorted(v["rules"])) or "none"))
            print("TARGET_RULES_VIOLATED=%s" % (
                "n/a (base checks failed)" if v["rule_viol"] is None else
                ",".join("%s=%d" % kv for kv in sorted(v["rule_viol"].items())) or "none"))
            _print_model_check(mc, cnf)
            verdict = v["ok"] and mc["verdict"] != "FALSIFIED"
        print("DECODE_VERDICT=%s" % ("PASS" if verdict else "FAIL"))
        sys.exit(0 if verdict else 1)
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
        if split_noy(target)[1]:
            raise SystemExit("--certify-count refuses %s: the Y-free subset counts no orderings "
                             "(its models assign only distance indicators and counters)" % target)
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
        if split_noy(target)[1]:
            raise SystemExit("--witness refuses %s: the Y-free subset has no ordering to decode"
                             % target)
        cnf, Y = build(target, with_c3=with_c3, c3_max=c3_max, c3_min=c3_min, not_kw=not_kw)
        import tempfile
        # 2026-09-03 -- the loop is a verdict emitter (WITNESS_RESULT=<token>, exit status):
        #   WITNESS             a witness passed base + every target rule + the C3 window  (exit 0)
        #   UNSAT               kissat said `s UNSATISFIABLE` AND exited 20                 (exit 0)
        #   SOLVER_ERROR        anything else from the solver, or a claimed model that
        #                       does not satisfy the formula (model_check)                 (exit 2)
        #   ENCODING_DIVERGENCE a genuine model decodes to something the formula was meant
        #                       to exclude: base C1/C2/C5 fails, an ENCODED rule is violated,
        #                       or C3 is outside a NATIVELY encoded window                 (exit 3)
        #   EXHAUSTED           200 blocking rounds without a verdict                      (exit 4)
        # Until today (Codex V2 A09 row 18, measured on the shipped file): a stub `kissat` exiting
        # 42 with empty stdout printed `UNSAT (or solver error) at attempt 0` and exited 0 -- the
        # same first token and the same exit status as a real UNSAT; 200 exhausted rounds printed
        # no verdict line at all and exited 0; a model violating base or an encoded rule was
        # silently BLOCKED AND RETRIED, which is the Q-58 signal (the formula admits an object it
        # was meant to exclude) treated as a nuisance; and the solver's model was never checked
        # against the CNF, so a stub returning the same assignment after every blocking clause
        # was believed 200 times.
        result = None
        cnf.mark("witness blocking clauses")
        for attempt in range(200):
            f = tempfile.NamedTemporaryFile("w", suffix=".cnf", delete=False)
            cnf.write(f.name, "target=" + target)
            try:
                r = subprocess.run(["kissat", "-q", f.name], capture_output=True, text=True)
            except FileNotFoundError:
                # graceful-absence idiom (roae.py Graphviz `dot`): external solver
                # missing is a clear install message, not a traceback
                os.unlink(f.name)
                raise SystemExit(
                    "kissat is required to run --witness but was not found on PATH.\n"
                    "Install kissat (https://github.com/arminbiere/kissat); see "
                    "documentation/SAT_CLI.md.\nThe rest of sat.py works without it.")
            os.unlink(f.name)
            # WHOLE line + exit status, two legs, CR-normalised (the drat-trim rule, applied to
            # the solver too): kissat exits 10 on SAT, 20 on UNSAT, anything else is not a verdict
            lines = [ln.rstrip("\r") for ln in r.stdout.splitlines()]
            if "s UNSATISFIABLE" in lines and r.returncode == 20:
                print("UNSAT at attempt %d" % attempt)
                print("WITNESS_RESULT=UNSAT"); result = 0; break
            if "s SATISFIABLE" not in lines or r.returncode != 10:
                print("SOLVER_ERROR at attempt %d (rc=%d): no whole-line `s SATISFIABLE` (rc 10) "
                      "or `s UNSATISFIABLE` (rc 20) verdict" % (attempt, r.returncode))
                print(r.stdout[-400:]); print(r.stderr[-400:])
                print("WITNESS_RESULT=SOLVER_ERROR"); result = 2; break
            lits = []
            for ln in lines:
                if ln.startswith("v "):
                    lits += [int(x) for x in ln[2:].split() if x != "0"]
            mc = model_check(cnf, lits)
            if mc["verdict"] != "SATISFIED":
                print("SOLVER_ERROR at attempt %d: the claimed model does not satisfy the formula "
                      "(%s: %d falsified, %d undetermined, %d foreign; families %s)"
                      % (attempt, mc["verdict"], mc["falsified"], mc["undetermined"],
                         mc["foreign"], mc["falsified_stages"] or "none"))
                print("WITNESS_RESULT=SOLVER_ERROR"); result = 2; break
            seq = decode(lits, Y)
            # F-1: re-score EVERY rule the target enforces on the decoded witness via solve.py
            # scorers (five since 2026-09-03; three before -- A09 row 14). A witness violating an
            # encoded rule means encoder/engine divergence, never accepted and, since today,
            # never silently retried either. (Skipped for the kw* encoding-validation targets,
            # which pin KW deliberately and are UNSAT-expected or KW-only by construction.)
            v = target_verdict(seq, target, with_c3=with_c3, c3_max=c3_max, c3_min=c3_min,
                               skip_rules=("kw" in target))
            print("attempt %d: verify=%s rules=%s violated=%s c3=%s %s"
                  % (attempt, v["base"],
                     v["scores"] and " ".join("%s=%d" % (r, v["scores"][r]) for r in FIVE_RULES),
                     v["rule_viol"], v["c3"],
                     v["c3_label"] if v["c3_ok"] else v["c3_label"] + ", blocking"))
            if v["ok"]:
                print("WITNESS:", seq)
                print("WITNESS_RESULT=WITNESS"); result = 0; break
            if not v["base"] or v["rule_viol"] or (not v["c3_ok"] and v["c3_encoded"]):
                print("ENCODING_DIVERGENCE at attempt %d: a model of the formula decodes to an "
                      "ordering the formula was meant to exclude (base=%s rule violations=%s "
                      "c3=%s natively encoded=%s)" % (attempt, v["base"], v["rule_viol"],
                                                       v["c3_label"], v["c3_encoded"]))
                print("WITNESS_RESULT=ENCODING_DIVERGENCE"); result = 3; break
            # the only remaining reason is C3 outside the DEFAULT window with C3 not in the
            # formula -- the documented iterate-until-C3-passes policy: block this Y-layout, retry
            cnf.add(*[-Y[(s, j)] for s in SLOTS for j in range(NJ) if Y[(s, j)] in set(l for l in lits if l > 0)])
        else:
            print("EXHAUSTED: 200 blocking rounds without a witness or an UNSAT")
            print("WITNESS_RESULT=EXHAUSTED"); result = 4
        sys.exit(result)
    elif args[:1] == ["--rigidity-cnf"] and len(args) == 2:
        # TR-5 v-next SC-4 kernel [expect UNSAT]; see build_rigidity docstring.
        out = _out_path(args[1])
        cnf, x = build_rigidity()
        if not rigidity_validate(cnf, x):
            raise SystemExit("rigidity encoding self-validation FAILED — not writing " + out)
        cnf.write(out, "rigidity: G5-automorphism fixing 0+N5(0) pointwise, != id [expect UNSAT]")
        print("wrote %s (%d vars, %d clauses); encoding self-validation PASS" %
              (out, cnf.n, len(cnf.cl)))
        if run:
            import shutil
            if shutil.which("kissat") is None:
                raise SystemExit(
                    "kissat is required for --rigidity-cnf --run but was not found on PATH.\n"
                    "Install kissat (https://github.com/arminbiere/kissat); see SAT_CLI.md.")
            proof = out + ".drat"
            r = subprocess.run(["kissat", "-q", out, proof], capture_output=True, text=True)
            # whole line + exit status, CR-normalised (2026-09-03; was a substring test on stdout
            # with the exit status unread -- the same two-leg rule the drat-trim leg below applies)
            klines = [ln.rstrip("\r") for ln in r.stdout.splitlines()]
            verdict = ("UNSAT" if "s UNSATISFIABLE" in klines and r.returncode == 20
                       else "SAT" if "s SATISFIABLE" in klines and r.returncode == 10
                       else "UNKNOWN(rc=%d)" % r.returncode)
            print("kissat verdict: %s (proof: %s)" % (verdict, proof))
            if verdict != "UNSAT":
                raise SystemExit("EXPECTED UNSAT — got " + verdict)
            if shutil.which("drat-trim"):
                r2 = subprocess.run(["drat-trim", out, proof], capture_output=True, text=True)
                # WHOLE line + rc, two legs (2026-09-02, same rule as verify_all.sh): drat-trim
                # prefixes each line with a bare CR and exits 0 on some runs that checked nothing.
                lines = [ln.strip("\r") for ln in r2.stdout.splitlines()]
                ver = "VERIFIED" if (r2.returncode == 0 and "s VERIFIED" in lines) else "NOT VERIFIED"
                print("drat-trim: %s (rc=%d)" % (ver, r2.returncode))
                if ver != "VERIFIED":
                    raise SystemExit("DRAT proof did not verify")
            else:
                print("drat-trim not on PATH — proof emitted but UNVERIFIED "
                      "(run drat-trim %s %s independently)" % (out, proof))
    elif args == ["--c5-selfcheck"]:
        sys.exit(c5_selfcheck())
    elif not args:
        print(__doc__)                               # no arguments: the catalogue, exit 0 (SAT_CLI.md)
    else:
        raise SystemExit("%s: wrong argument count -- usage: %s %s\n(before 2026-09-03 this "
                         "printed the help banner and exited 0 with nothing written)"
                         % (args[0], args[0], _USAGE[args[0]]))
