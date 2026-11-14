#!/usr/bin/env python3
"""Q-735 reproducer 3: the bound at n = 31 on recorded sample fibres.

fibres_n31.tsv lists 52 n = 31 fibres (King Wen's own, 40 from the author's local-move sample, the
author's three v2(F) = 20 minima, six distinct v2(F) = 20 fibres from the checker's searches and the
third reader's two six-pair witnesses), each
with the exact F that the run which found it recorded with its own C counter.  For each fibre this
script
  * recomputes F exactly by the Step-3 character sum (pruned; fractions of a second per fibre) and
    compares it with the recorded value;
  * computes the Fourier bound sum(mu_s) - sum(e_k) from the committed mu_table.tsv and checks
    bound >= 33 - t >= 20 and v2(F) >= bound;
  * with --dp K, also recomputes the first K fibres by a layered count over real hexagrams, which
    shares no code with the Fourier side (seconds to half a minute per fibre).
The fibre with F = 2,293,235,712 = 2^20 * 3^7 is exhibited: the per-fibre bound 2^20 is attained.
For the six reversible pairs with trivial stabiliser, two witness fibres show, by the layered count, a
single pinned pair at exactly 2^18 whose sum with its mirror pair (the half pin) is divisible by 2^19.

usage: n31_bound.py [--fibres TSV] [--mu-table TSV] [--dp K]
Tokens: Q735_N31_FIBRES=<n>, Q735_N31_EXACT_MATCH, Q735_N31_BOUND, Q735_N31_MIN_V2=<m>,
Q735_N31_EXHIBITED_2POW20_3POW7, Q735_N31_SIX_PAIR_SINGLE_2POW18_HALF_2POW19, Q735_N31_DP (SKIP without --dp), Q735_N31=PASS|FAIL.  Exit 0 on PASS.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from q735_common import KW_BUDGET, KW_PAIRS, analyse, dp_F, fourier_F, here, load_mu_table, vp, v2  # noqa: E402

# Six-pair witnesses (the third reader's fibres): at this slot each of a trivial-stabiliser pair p and its
# mirror p' alone gives a pinned count with v2 exactly 18, and their sum, the half-pinned count, is divisible
# by 2^19.  (fibre id, slot, p, p', F_p, F_p' as that reader recorded them.)
SIX_PAIR_WITNESSES = (("sixpair_T13_327", 3, 10, 23, 573308928, 573308928),
                      ("sixpair_T13_176", 19, 27, 29, 389283840, 375128064))


def main(argv):
    fib = here("fibres_n31.tsv"); mut = here("mu_table.tsv"); ndp = 0
    if "--fibres" in argv:
        fib = argv[argv.index("--fibres") + 1]
    if "--mu-table" in argv:
        mut = argv[argv.index("--mu-table") + 1]
    if "--dp" in argv:
        ndp = int(argv[argv.index("--dp") + 1])
    table = load_mu_table(mut)
    rows = []
    with open(fib) as fh:
        head = fh.readline().rstrip("\n").split("\t")
        for line in fh:
            r = dict(zip(head, line.rstrip("\n").split("\t")))
            rows.append((r["id"], [int(x) for x in r["skeleton"].split(",")],
                         [int(x) for x in r["classes"].split(",")], int(r["F_recorded"])))
    match = bound_ok = budget_ok = True; minv = 99; exhibited = False; dp_ok = True
    for i, (fid, sk, cl, Frec) in enumerate(rows):
        budget_ok = budget_ok and len(sk) == 31 and all(cl.count(d) == b for d, b in KW_BUDGET.items())
        A = analyse(sk, cl)
        Ab = analyse(sk, cl, mu_table=table)
        F = fourier_F(A)
        b, t = Ab["bound"], Ab["t"]
        ok_b = b == A["bound"] and b >= 33 - t >= 20 and v2(F) >= b
        match = match and F == Frec
        bound_ok = bound_ok and ok_b
        minv = min(minv, v2(F))
        exhibited = exhibited or (F == 2293235712 and F == 2 ** 20 * 3 ** 7)
        line = "%-18s F=%d v2=%d v3=%d t=%d bound=%d 33-t=%d %s" % (fid, F, v2(F), vp(F, 3), t, b, 33 - t,
                                                                 "ok" if (F == Frec and ok_b) else "FAIL")
        if i < ndp:
            Fd = dp_F(sk, cl); dp_ok = dp_ok and Fd == F
            line += " dp=%s" % ("equal" if Fd == F else "DIFFERS %d" % Fd)
        print(line)
    byid = {r[0]: r for r in rows}; six_ok = True
    for fid, slot, p, q, Fp_rec, Fq_rec in SIX_PAIR_WITNESSES:
        _, sk, cl, F = byid[fid]
        Fp = dp_F(sk, cl, pin=(slot, set(KW_PAIRS[p]))); Fq = dp_F(sk, cl, pin=(slot, set(KW_PAIRS[q])))
        Fu = dp_F(sk, cl, pin=(slot, set(KW_PAIRS[p]) | set(KW_PAIRS[q])))
        good = (Fp, Fq) == (Fp_rec, Fq_rec) and v2(Fp) == 18 and v2(Fq) == 18 and Fu == Fp + Fq and v2(Fu) >= 19
        six_ok = six_ok and good
        print("%s slot %d: F_pair%d=%d (v2 %d) F_pair%d=%d (v2 %d) half pin=%d (v2 %d) %s" % (
            fid, slot, p, Fp, v2(Fp), q, Fq, v2(Fq), Fu, v2(Fu), "ok" if good else "FAIL"))
    print("Q735_N31_SIX_PAIR_SINGLE_2POW18_HALF_2POW19=%s" % ("PASS" if six_ok else "FAIL"))
    ok = match and bound_ok and budget_ok and exhibited and minv == 20 and dp_ok and six_ok
    print("Q735_N31_FIBRES=%d" % len(rows))
    print("Q735_N31_EXACT_MATCH=%s" % ("PASS" if match else "FAIL"))
    print("Q735_N31_BOUND=%s" % ("PASS" if bound_ok and budget_ok else "FAIL"))
    print("Q735_N31_MIN_V2=%d" % minv)
    print("Q735_N31_EXHIBITED_2POW20_3POW7=%s" % ("PASS" if exhibited else "FAIL"))
    print("Q735_N31_DP=%s" % (("PASS" if dp_ok else "FAIL") if ndp else "SKIP"))
    print("Q735_N31=%s" % ("PASS" if ok else "FAIL"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
