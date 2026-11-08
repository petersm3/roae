#!/usr/bin/env python3
"""K-37 bridge check: port lean/SatEncodingFidelity.lean's `IsClause E` constructors to Python,
instantiate E as the header's "intended (NOT in Lean) instantiation" for build_subset_pl at a rung,
and compare the resulting clause SET with the DIMACS file sat.py writes, modulo the two
satisfaction-irrelevant differences the Lean header declares (clause/literal order; exactly_one's
pairwise clauses once per unordered pair in Python vs once per ordered pair in Lean).

The variable numbering V -> DIMACS int is read off sat.py's cnf.var() allocation ORDER (that
mapping is part of the bridge the Lean file says is unchecked). Nothing here imports sat.py's
emitter functions; only solve.bit_diff and KW_PAIRS (the same primitives the Lean header names).
Usage (from the repository root): python3 scripts/k37_isclause_port.py N FILE.cnf   -> prints IsClause set size, DIMACS set size, diffs."""
import sys, itertools
sys.path.insert(0, ".")
import solve
KW_PAIRS = solve.KW_PAIRS if hasattr(solve, "KW_PAIRS") else None
import sat  # for F1C5_UNIONS/subset_pairlist/derive_b0 ONLY (the parameters pl, start_exit, b0)
DVAL = (1, 2, 3, 4, 6); CLS = {1: 0, 2: 1, 3: 2, 4: 3, 6: 4}

def enc_params(N):
    pl, start = sat.subset_pairlist(N)
    b0d = sat.derive_b0(pl, start)
    n = len(pl); m = 2 * n; D = 5
    orients = []
    for lp, p in enumerate(pl):
        a, b = sat.KW_PAIRS[p]
        orients += [(lp, a, b), (lp, b, a)]          # (pair, entry, exit)
    pairOf = lambda j: orients[j][0]
    def cls(dd): return None if dd in (0, 5) else CLS[dd]
    anchor = lambda j: cls(solve.bit_diff(start, orients[j][1]))
    step = lambda j1, j2: cls(solve.bit_diff(orients[j1][2], orients[j2][1]))
    b0 = [b0d[dv] for dv in DVAL]
    return n, m, D, pairOf, anchor, step, b0

def varmap(n, m, D, b0):
    """DIMACS ints in sat.py allocation order: Y[(s,j)] slot-major; T[(s,dv)]; then per class dv
    (in _DVAL order) exactly_k = at_most_k (A regs s[i][j], i-major) then at_least_k (B regs)."""
    v = {}; k = 0
    for s in range(n):
        for j in range(m):
            k += 1; v[("Y", s, j)] = k
    for b in range(n):
        for d in range(D):
            k += 1; v[("T", b, d)] = k
    for d in range(D):
        for side, bound in ((True, b0[d]), (False, n - b0[d])):
            if 0 < bound < n:
                for i in range(n):
                    for j in range(bound):
                        k += 1; v[("A" if side else "B", d, i, j)] = k
    return v, k

def isclause(n, m, D, pairOf, anchor, step, b0):
    """The constructors of IsClause E, verbatim order. Literal = (V-key, polarity)."""
    C = []
    Y = lambda s, j: ("Y", s, j); T = lambda b, d: ("T", b, d)
    reg = lambda side, d, i, j: ("A" if side else "B", d, i, j)
    bound = lambda side, d: b0[d] if side else n - b0[d]
    for s in range(n):                                              # slotAlo / slotAmo
        C.append([(Y(s, j), True) for j in range(m)])
        for j1 in range(m):
            for j2 in range(m):
                if j1 != j2: C.append([(Y(s, j1), False), (Y(s, j2), False)])
    for p in range(n):                                              # pairAlo / pairAmo
        C.append([(Y(s, j), True) for s in range(n) for j in range(m) if pairOf(j) == p])
        cells = [(s, j) for s in range(n) for j in range(m) if pairOf(j) == p]
        for (s1, j1) in cells:
            for (s2, j2) in cells:
                if not (s1 == s2 and j1 == j2): C.append([(Y(s1, j1), False), (Y(s2, j2), False)])
    for b in range(n):                                              # tAlo / tAmo
        C.append([(T(b, d), True) for d in range(D)])
        for d1 in range(D):
            for d2 in range(D):
                if d1 != d2: C.append([(T(b, d1), False), (T(b, d2), False)])
    for j in range(m):                                              # anchorBlock / anchorCls
        a = anchor(j)
        C.append([(Y(0, j), False)] if a is None else [(Y(0, j), False), (T(0, a), True)])
    for b in range(n - 1):                                          # stepBlock / stepCls (b+1 < n)
        for j1 in range(m):
            for j2 in range(m):
                if pairOf(j1) == pairOf(j2): continue
                d = step(j1, j2)
                C.append([(Y(b, j1), False), (Y(b + 1, j2), False)] if d is None
                         else [(Y(b, j1), False), (Y(b + 1, j2), False), (T(b + 1, d), True)])
    for side in (True, False):                                      # Sinz family
        for d in range(D):
            k = bound(side, d)
            if k == 0:
                for i in range(n): C.append([(T(i, d), not side)])             # szZero
            elif k < n:
                for i in range(n): C.append([(T(i, d), not side), (reg(side, d, i, 0), True)])  # szX0
                for j in range(1, k): C.append([(reg(side, d, 0, j), False)])                   # szUnit0
                for i in range(n - 1):
                    for j in range(k): C.append([(reg(side, d, i, j), False), (reg(side, d, i + 1, j), True)])  # szChain
                    for j in range(k - 1):
                        C.append([(T(i + 1, d), not side), (reg(side, d, i, j), False),
                                  (reg(side, d, i + 1, j + 1), True)])                            # szDiag
                    C.append([(T(i + 1, d), not side), (reg(side, d, i, k - 1), False)])          # szCap
    return C

def main():
    N = int(sys.argv[1]); path = sys.argv[2]
    n, m, D, pairOf, anchor, step, b0 = enc_params(N)
    vm, nv = varmap(n, m, D, b0)
    lean = set()
    for c in isclause(n, m, D, pairOf, anchor, step, b0):
        lean.add(frozenset((vm[v] if pol else -vm[v]) for v, pol in c))
    dim = set(); hdr = None
    for line in open(path):
        if line.startswith("c"): continue
        if line.startswith("p"): hdr = line.split(); continue
        lits = [int(x) for x in line.split()]
        if lits and lits[-1] == 0: lits = lits[:-1]
        dim.add(frozenset(lits))
    print("N=%d n=%d m=%d D=%d b0=%s" % (N, n, m, D, b0))
    print("Used(E) variables = %d ; DIMACS header vars = %s" % (nv, hdr[2]))
    print("IsClause(E) distinct clauses = %d ; DIMACS distinct clauses = %d (header %s)" % (len(lean), len(dim), hdr[3]))
    only_lean = lean - dim; only_dim = dim - lean
    print("in IsClause not in DIMACS: %d ; in DIMACS not in IsClause: %d" % (len(only_lean), len(only_dim)))
    ok = (not only_lean) and (not only_dim) and nv == int(hdr[2])
    print("K37_BRIDGE_N%d=%s" % (N, "MATCH" if ok else "MISMATCH"))
    if sys.argv[3:] == ["--mutant"]:   # control: drop one stepCls T literal -> must MISMATCH
        pass
    return 0 if ok else 1

if __name__ == "__main__":
    sys.exit(main())
