#!/usr/bin/env python3
"""Q-735 reproducer 1: the per-support Fourier table (proof Steps 2 and 4), exhaustively.

For every support s (all eight, no symmetry reduction), every internal pattern and every character u,
computes mu_s = min v2 of the nonzero Fourier coefficients of Phi_s, twice: from 6-bit hexagrams and
Hamming distance (`phi_hex`), and from the proof's Z_4^3 description (`phi_z4`).  Checks the claims
the proof uses:
  * free pattern: mu = 7 (count 384 = 2^7*3) for every s != 0, mu = 4 (count 48) for s = 0;
  * mu >= mu_free - #(internal class-2/4 boundaries) - #(class-6 boundaries) for every pattern
    (each class-6 boundary costs at most ONE factor of 2);
  * class 6 is infeasible inside |s| = 3 and inside s = 0;
  * the cross-boundary table e_k (Step 2) over all 56 ordered support pairs and the 7 anchor cases.
With --pins, also the pinned tables used for V1 (one pair at one slot costs at most 2 more factors
for s != 0 and none for s = 0; one hexagram at most 3 and 1).

usage: fourier_table.py [--pins] [--check DIR] [--write DIR]
  --check DIR   compare with DIR/mu_table.tsv, DIR/ek_table.tsv (and DIR/pin_table.tsv with --pins)
  --write DIR   write those TSV files
Tokens (whole lines): Q735_COORDS, Q735_TABLE, Q735_TABLE_CONSTRUCTIONS_AGREE, Q735_EK_TABLE,
Q735_PIN_TABLE (SKIP without --pins), Q735_TABLE_MATCHES_TSV (SKIP without --check),
Q735_FOURIER_TABLE = PASS | FAIL.  Exit 0 on PASS, 1 on FAIL.
"""
import itertools
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from q735_common import (KW_PAIRS, S, T, coordinates_check, fwht, ghat, e_of, hexof, patterns,  # noqa: E402
                         pattern_counts, pc, perm3, phi_hex, phi_z4, rev6, stilde, v2)


def mu_of(a):
    tot = sum(a)
    if tot == 0:
        return None, 0
    return min(v2(x) for x in fwht(a) if x), tot


def build_mu_table():
    rows = []; agree = True
    for s in range(8):
        for gaps, anchor in patterns(s):
            mh, th = mu_of(phi_hex(s, gaps, anchor))
            mz, tz = mu_of(phi_z4(s, gaps, anchor))
            agree = agree and (mh, th) == (mz, tz)
            rows.append((s, gaps, anchor, th, mh))
    return rows, agree


def summarise(rows):
    free = {s: mu for s, gaps, anchor, tot, mu in rows if not any(gaps) and anchor == 0}
    free_count = {s: tot for s, gaps, anchor, tot, mu in rows if not any(gaps) and anchor == 0}
    worst = {}; viol = []; six_inside = []
    out = []
    for s, gaps, anchor, tot, mu in rows:
        n24, n6 = pattern_counts(gaps, anchor)
        if mu is None:
            out.append((s, gaps, anchor, tot, None, free[s], n24, n6, None))
            continue
        net = mu - free[s] + n24
        key = ("C" if s == 0 else pc(s), n6)
        worst[key] = min(worst.get(key, 99), net)
        if mu < free[s] - n24 - n6:
            viol.append((s, gaps, anchor, mu))
        if n6 and (s == 0 or s == 7):
            six_inside.append((s, gaps, anchor))
        out.append((s, gaps, anchor, tot, mu, free[s], n24, n6, net))
    return free, free_count, worst, viol, six_inside, out


def build_ek_table():
    tab = {}
    for anchor_side in (False, True):
        for a in range(8):
            if anchor_side and a:
                continue
            for b in range(8):
                if a == b:
                    continue
                for c in range(1, 7):
                    g = ghat(a, b, c, anchor_side)
                    if g is None:
                        continue
                    key = (c, pc(a ^ b), g[0], (c - pc(a ^ b)) // 2)
                    tab.setdefault(key, set()).add(e_of(g))
    return {k: sorted(v) for k, v in tab.items()}


# class, #coordinates the supports differ in, |m|, r  ->  e_k   (README, Step 2; class 5 never occurs
# in the King Wen budget, its row is listed because the reproducer covers every class)
EK_EXPECTED = {(1, 1, 2, 0): [2], (2, 2, 1, 0): [1], (3, 1, 2, 1): [1], (3, 3, 0, 0): [0],
               (4, 2, 1, 1): [1], (5, 1, 2, 2): [2]}


def _wht_levels(a, levels):
    """In-place Walsh-Hadamard butterflies on the given bit levels only."""
    n = len(a)
    for lv in levels:
        h = 1 << lv
        for i in range(0, n, 2 * h):
            for k in range(i, i + h):
                x, y = a[k], a[k + h]; a[k], a[k + h] = x + y, x - y
    return a


def halves(s):
    """The index-2 cosets {t : lam.t = b} that are unions of cosets of <s~> (lam.s~ even), lam != 0, b = 0, 1."""
    st = stilde(s)
    return [(lam, b) for lam in range(1, 8) if pc(lam & st) % 2 == 0 for b in (0, 1)]


def pin_costs(s, gaps, anchor):
    """(max extra cost of a one-pair pin, of a one-hexagram pin, of a half pin) over every slot position of
    this pattern, relative to mu_free - #2/4 - #6 (the free mu is subtracted by the caller); None when the
    pattern is infeasible.  For slot `pos`, R[x][u_other] = the transform over every other slot of Phi_s
    restricted to t_pos = x; a hexagram pin is one row, a pair pin {q, q + s~} is R[q] +- R[q + s~], and a
    half pin {lam.t = b} is (f(u) + (-1)^b f(u + lam at pos)) / 2 with f the full transform."""
    a = phi_hex(s, gaps, anchor)
    if not sum(a):
        return None
    m = 4 if s else 3; st = stilde(s); N = 8 ** m
    best = [None, None, None]

    def upd(i, vals):
        mv = min(v2(y) for y in vals if y) if any(vals) else None
        if mv is not None:
            best[i] = mv if best[i] is None else min(best[i], mv)

    for pos in range(m):
        sh = 3 * (m - 1 - pos)
        R = _wht_levels(list(a), [lv for lv in range(3 * m) if not sh <= lv < sh + 3])
        rows = [[R[k] for k in range(N) if (k >> sh) & 7 == x] for x in range(8)]
        for q in range(8):
            upd(1, rows[q])
            q2 = q ^ st
            if q2 > q:
                upd(0, [y for u, w in zip(rows[q], rows[q2]) for y in (u + w, u - w)])
        f = _wht_levels(list(R), range(sh, sh + 3))
        for lam, b in halves(s):
            sg = -1 if b else 1
            vals = [(f[k] + sg * f[k ^ (lam << sh)]) for k in range(N)]
            assert all(y % 2 == 0 for y in vals)
            upd(2, [y // 2 for y in vals])
    return tuple(best)


def build_pin_table(free):
    rows = []
    for s in range(8):
        for gaps, anchor in patterns(s):
            r = pin_costs(s, gaps, anchor)
            if r is None:
                continue
            n24, n6 = pattern_counts(gaps, anchor)
            base = free[s] - n24 - n6
            rows.append((s, gaps, anchor) + tuple(base - x for x in r))
    return rows


def six_pair_unions():
    """For each reversible pair p with trivial stabiliser in the coordinate permutations, its mirror p' = tau p
    (tau = the transposition of the two coordinates outside the support) and the entry set T(p u p').
    Returns [(p, p', s, lam, b)] with T(p u p') = {t : lam.t = b}, or raises if a union is not a half."""
    out = []
    for p in range(1, 32):
        a, b0 = KW_PAIRS[p]
        if rev6(a) == a:
            continue
        s = S(a)
        stab = [pi for pi in itertools.permutations(range(3))
                if {hexof(perm3(pi, S(h)), perm3(pi, T(h))) for h in (a, b0)} == {a, b0}]
        if len(stab) != 1:
            continue
        j = [x for x in range(3) if not (s >> x) & 1]
        tau = [0, 1, 2]; tau[j[0]], tau[j[1]] = j[1], j[0]
        img = {hexof(perm3(tau, S(h)), perm3(tau, T(h))) for h in (a, b0)}
        p2 = [q for q in range(1, 32) if set(KW_PAIRS[q]) == img][0]
        ts = {T(h) for h in (a, b0) + KW_PAIRS[p2]}
        hit = [(lam, bb) for lam, bb in halves(s) if ts == {x for x in range(8) if pc(lam & x) % 2 == bb}]
        assert len(hit) == 1, (p, p2, ts)
        out.append((p, p2, s) + hit[0])
    return out


def fmt_gaps(g):
    return "".join(str(x) for x in g)


def tsv_mu(out):
    lines = ["s\t|s|\tgaps\tanchor\tcount\tmu\tmu_free\tn_class24\tn_class6\tnet_nu"]
    for s, gaps, anchor, tot, mu, fr, n24, n6, net in out:
        lines.append("%d\t%d\t%s\t%d\t%d\t%s\t%d\t%d\t%d\t%s" % (s, pc(s), fmt_gaps(gaps), anchor, tot,
                     "-" if mu is None else mu, fr, n24, n6, "-" if net is None else net))
    return "\n".join(lines) + "\n"


def tsv_ek(ek):
    lines = ["class\tsupports_differ_in\tm_size\tr\te_k"]
    for k in sorted(ek):
        lines.append("%d\t%d\t%d\t%d\t%s" % (k + (",".join(map(str, ek[k])),)))
    return "\n".join(lines) + "\n"


def tsv_pin(rows):
    lines = ["s\t|s|\tgaps\tanchor\tpair_pin_extra_cost\thexagram_pin_extra_cost\thalf_pin_extra_cost"]
    for s, gaps, anchor, cp, ch, chalf in rows:
        lines.append("%d\t%d\t%s\t%d\t%d\t%d\t%d" % (s, pc(s), fmt_gaps(gaps), anchor, cp, ch, chalf))
    return "\n".join(lines) + "\n"


def main(argv):
    pins = "--pins" in argv
    check = write = None
    if "--check" in argv:
        check = argv[argv.index("--check") + 1]
    if "--write" in argv:
        write = argv[argv.index("--write") + 1]
    ok_all = True

    def verdict(name, ok, skip=False):
        nonlocal ok_all
        print("%s=%s" % (name, "SKIP" if skip else ("PASS" if ok else "FAIL")))
        if not skip and not ok:
            ok_all = False

    cc = coordinates_check()
    print("class formula / mate rule / round-trip mismatches over 4096 / 64 / 64:", *cc)
    verdict("Q735_COORDS", cc == (0, 0, 0))

    rows, agree = build_mu_table()
    free, free_count, worst, viol, six_inside, out = summarise(rows)
    feas = sum(1 for r in out if r[4] is not None)
    for s in range(8):
        print("s=%d |s|=%d: free mu=%d count=%d ; feasible patterns %d of %d" % (
            s, pc(s), free[s], free_count[s], sum(1 for r in out if r[0] == s and r[4] is not None),
            sum(1 for r in out if r[0] == s)))
    print("min net nu = mu - mu_free + #(internal class 2/4), by (|s|, #class-6):",
          " ".join("%s:%d" % ("(%s,%d)" % k, worst[k]) for k in sorted(worst, key=str)))
    print("patterns compared", len(rows), "feasible", feas, "violations of mu >= mu_free - #2/4 - #6:", len(viol),
          "; class-6 patterns inside |s|=3 or s=0 that are feasible:", len(six_inside))
    free_ok = all(free[s] == 7 and free_count[s] == 384 for s in range(1, 8)) and free[0] == 4 and free_count[0] == 48
    worst_ok = all(v == -n6 for (k, n6), v in worst.items()) and not viol and not six_inside
    verdict("Q735_TABLE", free_ok and worst_ok)
    verdict("Q735_TABLE_CONSTRUCTIONS_AGREE", agree)

    ek = build_ek_table()
    for k in sorted(ek):
        print("e_k: (class %d, supports differ in %d, |m| %d, r %d) -> %s" % (k + (ek[k],)))
    verdict("Q735_EK_TABLE", ek == EK_EXPECTED)

    pin_rows = None
    if pins:
        pin_rows = build_pin_table(free)
        for s in range(8):
            mine = [r for r in pin_rows if r[0] == s]
            print("pin s=%d |s|=%d: max extra cost one PAIR %d ; one HEXAGRAM %d ; HALF (any lam.t = b) %d" % (
                s, pc(s), max(r[3] for r in mine), max(r[4] for r in mine), max(r[5] for r in mine)))
        pin_ok = all(max(r[3] for r in pin_rows if r[0] == s) == (2 if s else 0) and
                     max(r[4] for r in pin_rows if r[0] == s) == (3 if s else 1) for s in range(8))
        verdict("Q735_PIN_TABLE", pin_ok)
        six = six_pair_unions()
        for p, p2, s, lam, b in six:
            print("six-pair union: pair %d + mirror %d, support %d: entries {t : lam.t = %d}, lam = %d" % (p, p2, s, b, lam))
        half_ok = (all(max(r[5] for r in pin_rows if r[0] == s) == (1 if s else 0) for s in range(8))
                   and len(six) == 6 and sorted(x for r in six for x in r[:2]) == sorted([10, 15, 20, 23, 27, 29] * 2))
        verdict("Q735_HALF_PIN_TABLE", half_ok)
    else:
        verdict("Q735_PIN_TABLE", True, skip=True)
        verdict("Q735_HALF_PIN_TABLE", True, skip=True)

    texts = {"mu_table.tsv": tsv_mu(out), "ek_table.tsv": tsv_ek(ek)}
    if pin_rows is not None:
        texts["pin_table.tsv"] = tsv_pin(pin_rows)
    if write:
        for name, txt in texts.items():
            with open(os.path.join(write, name), "w") as fh:
                fh.write(txt)
    if check:
        same = True
        for name, txt in texts.items():
            with open(os.path.join(check, name)) as fh:
                if fh.read() != txt:
                    print("differs from the committed table:", name); same = False
        verdict("Q735_TABLE_MATCHES_TSV", same)
    else:
        verdict("Q735_TABLE_MATCHES_TSV", True, skip=True)
    print("Q735_FOURIER_TABLE=%s" % ("PASS" if ok_all else "FAIL"))
    return 0 if ok_all else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
