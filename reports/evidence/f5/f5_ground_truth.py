#!/usr/bin/env python3
"""F5 two-language gate: independent Python evaluation of the 11 frozen
orientation functionals (F5_ORIENTATION_PREREGISTRATION_2026_07_FROZEN.md §5 +
addendum #11), implemented directly from the frozen spec text. #11 delegates to
solve.py vdb_nucorient (single implementation, per spec). Used ONLY as the
verification side of the solve.c SOLVE_KNUTH_SCORE_F5 port — scratchpad, not
repo. Usage:
  f5_ground_truth.py            -> evaluate on KW, check spec KW values
  f5_ground_truth.py h0,..,h63  -> evaluate on explicit sequence, print CSV
"""
import os
import sys
# Public-bundle portability edit (2026-07-05): repo root located relative to this
# file (reports/evidence/f5/ -> repo root) instead of the original absolute path.
# Sole change vs the archived private original; see README.md in this directory.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..")))
from solve import binary_hexagrams, vdb_nucorient  # noqa: E402

SPEC_KW = [15, 10, 10, 2, 7, 17, 13, 23, 18, 4, 29]
NAMES = ["correct_lead", "rising", "rf_alt", "gender_lead", "mirror_order",
         "lex_dev", "orient_alt", "greedy_entry", "bpd_six_pos",
         "bpd_one_span", "vdb_nuc"]

hw = lambda h: bin(h).count("1")
d = lambda a, b: hw(a ^ b)


def correct(h):
    # line n correct iff yang at odd n in {1,3,5} (bits 0,2,4) / yin at even (bits 1,3,5)
    return hw(h & 0b010101) + 3 - hw(h & 0b101010)


def f5_all(seq):
    v = []
    # 1. f5_correct_lead
    v.append(sum(1 for k in range(32)
                 if correct(seq[2*k]) > correct(seq[2*k+1])))
    # 2+3. f5_rising / f5_rf_alt over the 18 directional pairs in slot order
    syms = []
    for k in range(32):
        a, b = seq[2*k], seq[2*k+1]
        if a ^ b == 63:
            continue                       # complement pair
        if hw(a) == 3:
            continue                       # non-directional
        mb = 0 if hw(a) > 3 else 1         # minority line value
        sa = sum(i+1 for i in range(6) if (a >> i) & 1 == mb)
        sb = sum(i+1 for i in range(6) if (b >> i) & 1 == mb)
        syms.append("R" if sb > sa else ("F" if sb < sa else "T"))
    v.append(syms.count("R"))
    alt = sum(1 for i in range(len(syms)-1)
              if not (syms[i] == syms[i+1] and syms[i] != "T"))
    v.append(alt)
    # 4. f5_gender_lead: 4 weight-asymmetric (complement, hw!=3) pairs; yang-heavier leads
    v.append(sum(1 for k in range(32)
                 if seq[2*k] ^ seq[2*k+1] == 63 and hw(seq[2*k]) > 3))
    # 5. f5_mirror_order: 12 comp-involution slot two-cycles; order-true iff comp(first_j)==first_k
    pos = {h: i for i, h in enumerate(seq)}
    n5 = 0
    for k in range(32):
        cs = pos[seq[2*k] ^ 63] // 2
        if cs > k and (seq[2*k] ^ 63) == seq[2*cs]:
            n5 += 1
    v.append(n5)
    # 6. f5_lex_dev: slots where the numerically larger member leads
    ol = [1 if seq[2*k] > seq[2*k+1] else 0 for k in range(32)]
    v.append(sum(ol))
    # 7. f5_orient_alt: alternations of the o_lex string (31 adjacencies)
    v.append(sum(1 for k in range(31) if ol[k] != ol[k+1]))
    # 8. f5_greedy_entry: entering member closer-or-equal to previous hexagram
    v.append(sum(1 for k in range(1, 32)
                 if d(seq[2*k-1], seq[2*k]) <= d(seq[2*k-1], seq[2*k+1])))
    # 9+10. between-pair distance structure (T2b)
    bpd = [d(seq[2*b+1], seq[2*b+2]) for b in range(31)]
    sixes = [b for b in range(31) if bpd[b] == 6]
    ones = [b for b in range(31) if bpd[b] == 1]
    v.append(sixes[0] if sixes else 0)
    v.append(ones[1] - ones[0] if len(ones) >= 2 else 0)
    # 11. f5_vdb_nuc == solve.py vdb_nucorient (single implementation)
    v.append(vdb_nucorient(list(seq)))
    return v


if len(sys.argv) > 1:
    seq = [int(x) for x in sys.argv[1].replace(",", " ").split()]
    assert len(seq) == 64
    print(",".join(str(x) for x in f5_all(seq)))
else:
    got = f5_all(list(binary_hexagrams))
    ok = True
    for n, g, e in zip(NAMES, got, SPEC_KW):
        tag = "OK" if g == e else f"FAIL (expected {e})"
        ok &= (g == e)
        print(f"f5_{n}: {g} {tag}")
    print("F5 GROUND TRUTH:", "PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)
