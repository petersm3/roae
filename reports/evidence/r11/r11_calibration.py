# R11 four-class Bayes v2 — §7.2 SYNTHETIC-DRAW CALIBRATION ONLY (confusability gate).
# Frozen design: roae-private/R11_BAYES_V2_DESIGN_2026_07_10.md (§2 models, §4 priors,
# §7.2 calibration, §7.3 ordering). This script computes NO King-Wen-facing verdict:
# KW enters only as (a) the substrate definition (C5 budget, slot-0 gauge), (b) the
# archived-ingredient gates (KW-value reproduction, f11_events.json reproduction).
# Per §7.3 the KW integration is a separate, operator-gated, post-freeze deliverable.
#
# What this does: n=100 synthetic sequences per class {M0, M_G, M_D, M_C} (parameters
# drawn from the frozen §4 grids), each scored under all four models' marginal
# likelihoods (primary configuration: M_G uniform weights + completion-conditioned;
# M_D2 per-axis grid, Z 'aug'; M_C variant U, conditioned, direct pooled N_gs), then
# the 4x4 confusion matrix of true class vs argmax posterior (uniform model prior),
# per-class first-rank rates, median log10 BF(true/best-rival), and the §7.2 / §6.3
# confusability verdict (threshold: fewer than 70/100 draws ranking the true class
# first => veto).
#
# Code reuse (mandated): the M_G machinery is solve.py's r11_children /
# _r11_step_score / r11_builder_numerator / r11_builder_run / r11_builder_pcomplete /
# r11_builder_synthetic, imported, not rewritten. The edit-event geometry mirrors
# reports/evidence/f11/f11_events.py (functions to_base/build/apply_event/blocks/
# swap_sets/valid_c3 carried verbatim or near-verbatim, credited) and is gated by
# exact reproduction of the archived f11_events.json on both bases (KW + GRAND).
#
# Rule ATTRIBUTION (rules are NOT ROAE discoveries): Moore 2005 (pair-positioning
# parity), Moore 1989 (rhythm), Schulz 1990 (gender; exception Zhu Yuansheng 13th c.),
# Cook 2006 (level coverage, final-pair anchor), Zheng Qiao ~1150 / Hu Yigui 1247 /
# Hacker & Moore 2003 (18:18 split), Rutt 1996 via Hacker & Moore 2003 (bamboo-slat
# corruption mechanism). Developed with AI assistance (Claude, Anthropic).
#
# Stdlib only. Runs on the dedicated Standard VM, never on the orchestrator.
import argparse
import json
import math
import os
import random
import re
import sys
import time
from collections import Counter
from itertools import combinations
from multiprocessing import Pool

# ---------------------------------------------------------------------------
# frozen grids (design §4 — numeric, final)
BETA_GRID = [0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0]      # M_G
LAM3 = [0.5, 2.0, 8.0]                                  # M_D2 per-axis (g1..g6)
LAM_D1 = [0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0]           # M_D1 shared (secondary)
PC_GRID = [0.05, 0.1, 0.2, 0.3, 0.5, 0.7, 0.9]          # M_C geometric p_c
KMAX = 6                                                # M_C numerator truncation
N_DRAWS = 100                                           # per class (§7.2)
VETO_THRESHOLD = 70                                     # of 100 (§7.2 frozen)
MASTER_SEED = 20260720
CLASSES = ["M0", "MG", "MD", "MC"]

solve = None            # bound in setup()
KW = None
PAIRS = None            # KW pair inventory (f11_events convention)
KW_TRANS = None         # KW transition multiset (Counter)
SLOTS = set(range(1, 32))


def setup(roae_dir):
    global solve, KW, PAIRS, KW_TRANS
    sys.path.insert(0, roae_dir)
    import solve as _solve
    solve = _solve
    KW = list(solve.binary_hexagrams)
    PAIRS = [(KW[2 * i], KW[2 * i + 1]) for i in range(32)]
    KW_TRANS = Counter(solve.bit_diff(KW[i], KW[i + 1]) for i in range(63))
    assert solve.r11_axes(KW) == [2, 2, 2, 0, 0, 0, 0, 0], "KW r11_axes gate FAILED"


def geom(k, p):
    return (1.0 - p) ** k * p


# ---------------------------------------------------------------------------
# event geometry (mirrors reports/evidence/f11/f11_events.py; credited there)
def to_base(seq):
    idx = {}
    for i, (a, b) in enumerate(PAIRS):
        idx[(a, b)] = (i, 0)
        idx[(b, a)] = (i, 1)
    sp = [0] * 32
    fl = set()
    for s in range(32):
        i, o = idx[(seq[2 * s], seq[2 * s + 1])]
        sp[s] = i
        if o:
            fl.add(s)
    return sp, fl


def build_seq(sp, fl):
    seq = []
    for s in range(32):
        a, b = PAIRS[sp[s]]
        seq += ([b, a] if s in fl else [a, b])
    return seq


def apply_event(base, swaps, flips):
    sp0, fl0 = base
    sig = list(range(32))
    for s in swaps:
        sig[s], sig[s + 1] = sig[s + 1], sig[s]
    sp = [sp0[sig[s]] for s in range(32)]
    fl = set()
    for s in range(32):
        if (sig[s] in fl0) != (s in flips):
            fl.add(s)
    return sp, fl


def blocks(fp):
    fp = sorted(fp)
    return 1 + sum(1 for i in range(1, len(fp)) if fp[i] != fp[i - 1] + 1)


def swap_sets(max_n):
    out = [[]]
    singles = list(range(1, 31))
    for n in range(1, max_n + 1):
        for c in combinations(singles, n):
            if all(c[i + 1] - c[i] >= 2 for i in range(n - 1)):
                out.append(list(c))
    return out


def valid_c3(seq):
    """Verbatim f11_events.py: C2 + C5 (multiset vs KW) + C3 <= 776 (C1 structural)."""
    if not solve.has_no_five(seq):
        return False
    if Counter(solve.bit_diff(seq[i], seq[i + 1]) for i in range(63)) != KW_TRANS:
        return False
    pos = {h: i for i, h in enumerate(seq)}
    return sum(abs(pos[h] - pos[h ^ 63]) for h in range(64)) <= 776


def c3_val(seq):
    pos = {h: i for i, h in enumerate(seq)}
    return sum(abs(pos[h] - pos[h ^ 63]) for h in range(64))


def grand_ok(seq):
    g = solve.r11_axes(seq)
    return g[0] == 0 and g[1] == 0 and g[2] == 0


# ---------------------------------------------------------------------------
# per-sequence violation-locus analyzers (feed the PROVABLY-SAFE event pruning:
# an event's footprint cannot change g1-compliance of a non-footprint slot, cannot
# change the gender-station of a class first-appearing at a non-footprint slot, and
# cannot remove a rhythm break both of whose adjacent slots are non-footprint —
# see the derivation in the run report; each analyzer is count-gated vs r11_axes)
def eligible_pair(f, s):
    return (f ^ s) != 63 and bin(f).count("1") != 3


def b1_slots(seq):
    """Slots (0..31) holding an eligible pair placed parity-non-compliantly."""
    out = []
    for q in range(32):
        h, h2 = seq[2 * q], seq[2 * q + 1]
        if (h ^ h2) == 63:
            continue
        pcq = bin(h).count("1")
        if pcq == 3:
            continue
        if (1 if pcq > 3 else 0) != ((q + 1) & 1):
            out.append(q)
    return out


def break_pairs(seq):
    """List of (u-1, u) adjacent-directional-slot pairs where a rhythm break sits."""
    prev, have, prev_adj, out = 0, False, False, []
    prev_slot = -1
    for q in range(32):
        h, h2 = seq[2 * q], seq[2 * q + 1]
        if (h ^ h2) == 63:
            prev_adj = False
            continue
        pcq = bin(h).count("1")
        if pcq == 3:
            prev_adj = False
            continue
        mb = 0 if pcq > 3 else 1
        sc = sum(5 - 2 * i for i in range(6) if ((h >> i) & 1) == mb)
        rf = 1 if sc > 0 else 0
        if have and prev_adj and rf == prev:
            out.append((prev_slot, q))
        prev, have, prev_adj, prev_slot = rf, True, True, q
    return out


def b3_slots(seq):
    """First-appearance slots of gender-violating inversion classes."""
    seen, ncls, out = set(), 0, []
    for i, h in enumerate(seq):
        key = min(h, solve.reverse_6bit(h))
        if key in seen:
            continue
        seen.add(key)
        ncls += 1
        pck = bin(h).count("1")
        if pck in (0, 3, 6):
            continue
        if (pck < 3) != (ncls % 2 == 1):
            out.append(i // 2)
    return out


def analyzer_gate(seq):
    g = solve.r11_axes(seq)
    assert len(b1_slots(seq)) == g[0], "B1 analyzer disagrees with r11_axes g1"
    assert len(break_pairs(seq)) == g[1], "break analyzer disagrees with r11_axes g2"
    assert len(b3_slots(seq)) == g[2], "B3 analyzer disagrees with r11_axes g3"


# ---------------------------------------------------------------------------
# event-count combinatorics (gate vs archived f11_events.json 'events'/'zA')
def comb(n, k):
    return math.comb(n, k) if 0 <= k <= n else 0


def n_swapsets(n):
    """# of disjoint n-sets of adjacent transpositions from slots 1..30."""
    return comb(31 - n, n)


def event_counts():
    """n_k = total events of footprint k (uniform-U denominator), k=1..KMAX."""
    nk = {k: 0 for k in range(1, KMAX + 1)}
    for n in range(0, KMAX // 2 + 1):
        m2 = 2 * n
        if m2 > KMAX:
            continue
        for nf in range(0, KMAX - m2 + 1):
            k = m2 + nf
            if k < 1:
                continue
            nk[k] += n_swapsets(n) * comb(31 - m2, nf) * (2 ** m2)
    return nk


# ---------------------------------------------------------------------------
# per-draw hit enumeration: hits_k(S) = #{events E, |fp|=k : E(S) valid & grand-strict}
# with the safe pruning (footprint must cover B1∪B3 and hit every break pair) and a
# fast local-boundary C5/C2 filter (between-slot transitions only change at
# boundaries adjacent to the footprint; within-pair transitions are pair-intrinsic).
def hits_for_seq(seq, audit_slow_kmax=0):
    g = solve.r11_axes(seq)
    analyzer_gate(seq)
    R = set(b1_slots(seq)) | set(b3_slots(seq))
    brk = break_pairs(seq)
    hitsU = {k: 0 for k in range(1, KMAX + 1)}
    hitsA = {k: 0.0 for k in range(1, KMAX + 1)}
    if len(R) > KMAX:
        return hitsU, hitsA, g
    sp0, fl0 = to_base(seq)
    tb = [solve.bit_diff(seq[2 * b - 1], seq[2 * b]) for b in range(32)]  # tb[b], b>=1
    pairs = PAIRS

    for swaps in SWAPSETS:
        moved = set()
        for s in swaps:
            moved |= {s, s + 1}
        m2 = len(moved)
        if m2 > KMAX:
            continue
        req = R - moved
        max_ext = KMAX - m2
        if len(req) > max_ext:
            continue
        free = SLOTS - moved
        if not req <= free:
            continue
        free_rest = sorted(free - req)
        sig = list(range(32))
        for s in swaps:
            sig[s], sig[s + 1] = sig[s + 1], sig[s]
        decs = [set(c) for r in range(m2 + 1)
                for c in combinations(sorted(moved), r)]
        base_req = req
        for nf_extra in range(0, max_ext - len(base_req) + 1):
            for ext_rest in combinations(free_rest, nf_extra):
                ext = base_req | set(ext_rest)
                k = m2 + len(ext)
                if k < 1:
                    continue
                fp = moved | ext
                ok_brk = True
                for (u, v) in brk:
                    if u not in fp and v not in fp:
                        ok_brk = False
                        break
                if not ok_brk:
                    continue
                aff = sorted({b for s in fp for b in (s, s + 1) if 1 <= b <= 31})
                old_local = sorted(tb[b] for b in aff)
                wA = 2.0 ** (-blocks(fp))
                for dec in decs:
                    flips = dec | ext
                    # local C5/C2 check without full build
                    new_local = []
                    ok = True
                    for b in aff:
                        sl, sr = b - 1, b
                        pl = pairs[sp0[sig[sl]]]
                        left = pl[0] if ((sig[sl] in fl0) != (sl in flips)) else pl[1]
                        pr = pairs[sp0[sig[sr]]]
                        right = pr[1] if ((sig[sr] in fl0) != (sr in flips)) else pr[0]
                        new_local.append(solve.bit_diff(left, right))
                    new_local.sort()
                    if new_local != old_local:
                        continue
                    sp, fl = apply_event((sp0, fl0), swaps, flips)
                    seq2 = build_seq(sp, fl)
                    if c3_val(seq2) > 776:
                        continue
                    if grand_ok(seq2):
                        hitsU[k] += 1
                        hitsA[k] += wA
    if audit_slow_kmax:
        slowU = hits_slow(seq, audit_slow_kmax)
        for k in range(1, audit_slow_kmax + 1):
            assert slowU[k] == hitsU[k], \
                "fast/slow hit mismatch k=%d (%d vs %d)" % (k, hitsU[k], slowU[k])
    return hitsU, hitsA, g


def hits_slow(seq, kmax):
    """Unpruned, valid_c3-verbatim enumeration (audit path), k<=kmax."""
    base = to_base(seq)
    hu = {k: 0 for k in range(1, kmax + 1)}
    for swaps in swap_sets(kmax // 2):
        moved = set()
        for s in swaps:
            moved |= {s, s + 1}
        m2 = len(moved)
        if m2 > kmax:
            continue
        free = sorted(SLOTS - moved)
        decs = [set(c) for r in range(m2 + 1)
                for c in combinations(sorted(moved), r)]
        for nf in range(0, kmax - m2 + 1):
            k = m2 + nf
            if k < 1:
                continue
            for ext in combinations(free, nf):
                for dec in decs:
                    flips = dec | set(ext)
                    sp, fl = apply_event(base, swaps, flips)
                    seq2 = build_seq(sp, fl)
                    if valid_c3(seq2) and grand_ok(seq2):
                        hu[k] += 1
    return hu


SWAPSETS = None  # populated in worker init (swap_sets(KMAX//2))


# ---------------------------------------------------------------------------
# decode-trick around solve._r11_step_score: one call yields (d1,brk,gnew,d4,d5)
DECODE_W = (1, 4, 16, 64, 256)


def decode_score(s):
    si = int(round(s))
    d5 = 1 if si > 175 else 0
    rem = si - 256 * d5
    d4 = 2 if rem > 78 else (1 if rem > 14 else 0)
    rem2 = rem - 64 * d4
    g = 2 if rem2 <= -31 else (1 if rem2 <= -15 else 0)
    rem3 = rem2 + 16 * g
    b = 1 if rem3 <= -3 else 0
    d1 = 1 if rem3 in (1, -3) else 0
    return d1, b, g, d4, d5


def decode_gate(rng, n_children=3000):
    """Gate the decode trick against per-axis basis calls on random builder states."""
    checked = 0
    while checked < n_children:
        seq, budget, used, seen, ncls, prf, padj, lv7 = _fresh_state()
        for slot in range(1, 32):
            kids = solve.r11_children(seq[-1], used, budget)
            if not kids:
                break
            for (p, o, f, s2, bd, wd) in kids:
                sc, *_ = solve._r11_step_score(slot, f, s2, seen, ncls, prf, padj,
                                               lv7, DECODE_W)
                d = decode_score(sc)
                for ax in range(5):
                    w = [0] * 5
                    w[ax] = 1
                    sax, *_ = solve._r11_step_score(slot, f, s2, seen, ncls, prf,
                                                    padj, lv7, tuple(w))
                    exp = [d[0], -d[1], -d[2], d[3], d[4]][ax]
                    assert int(round(sax)) == exp, \
                        "decode gate FAILED axis %d slot %d" % (ax, slot)
                checked += 1
            # advance along a random child
            (p, o, f, s2, bd, wd) = kids[rng.randrange(len(kids))]
            _, prf, padj, seen, ncls, lv7 = solve._r11_step_score(
                slot, f, s2, seen, ncls, prf, padj, lv7, DECODE_W)
            seq += [f, s2]
            budget[bd] -= 1
            budget[wd] -= 1
            used |= (1 << p)
            if checked >= n_children:
                break
    return checked


def _fresh_state():
    budget = solve._r11_kw_budget()
    seq = [63, 0]
    budget[solve.bit_diff(63, 0)] -= 1
    used = 0
    for p in range(32):
        if {PAIRS[p][0], PAIRS[p][1]} == {63, 0}:
            used |= (1 << p)
            break
    seen, ncls = solve._r11_seen_classes([63, 0])
    lv7 = (1 << 6) | (1 << 0)
    return seq, budget, used, seen, ncls, 0, False, lv7


# ---------------------------------------------------------------------------
# SMC sampler over the C1..C5 substrate.
# target='uniform'  : weight |A_t| per step -> uniform over canonical leaves (M0)
# target='gibbs'    : proposal softmax(s_lam), weight = log-normalizer -> Gibbs
#                     exp(-sum lam_j V_j) over g1..g5, then end-reweight exp(-lam6*V6)
# target='strict'   : children restricted to zero-new-violation (g1,g2,g3) placements,
#                     weight = #allowed -> uniform over the grand-strict set (M_C precursor)
# All prefixes carry an EXACT monotone lower bound on the final C3 total; a
# particle whose bound exceeds 776 can never complete C3-valid, so it is killed
# in-walk (bias-free — it would have received weight 0 at the end). This keeps
# the target = the C3-INCLUDED substrate (design D1/D2: C1-C5 includes C3),
# and fixes the degeneracy where strong-lambda populations collapsed to a few
# unique completions that all failed a C3 end-filter (2026-07-20 crash).
def c3_advance(pos, half, sum_fixed, f, s, base_len):
    """Place hexagrams f, s at positions base_len, base_len+1; return
    (npos, nhalf, nsf, lb). lb is a monotone lower bound on the final C3 total
    (doubled convention, as valid_c3): closed complement-pairs contribute the
    exact 2*|dpos|, half-open pairs at least 2*(cur_len - pos[h]) (the
    complement can only appear later), untouched pairs at least 2. At the final
    slot lb equals the true C3 value."""
    npos = dict(pos)
    nhalf = set(half)
    nsf = sum_fixed
    for h, p in ((f, base_len), (s, base_len + 1)):
        c = h ^ 63
        if c in npos:
            nsf += 2 * (p - npos[c])
            nhalf.discard(c)
        else:
            nhalf.add(h)
        npos[h] = p
    cur = base_len + 2
    open_pairs = 32 - (cur - len(nhalf)) // 2 - len(nhalf)
    lb = nsf + sum(2 * (cur - npos[h]) for h in nhalf) + 2 * open_pairs
    return npos, nhalf, nsf, lb


def smc_draw(target, lam, n_particles, seed):
    rng = random.Random(seed)
    seq0, budget0, used0, seen0, ncls0, prf0, padj0, lv70 = _fresh_state()
    pos0, half0, sf0, lb0 = c3_advance({}, set(), 0, 63, 0, 0)
    assert lb0 <= 776 and sf0 == 2, "C3 seed state broke"
    parts = [(seq0, tuple(budget0), used0, seen0, ncls0, prf0, padj0, lv70,
              (0, 0, 0, 0, 0), pos0, half0, sf0)] * n_particles
    logw = [0.0] * n_particles
    dead_frac = 0.0
    c3_killed = 0
    for slot in range(1, 32):
        new_parts = [None] * len(parts)
        step_lw = [float("-inf")] * len(parts)
        for i, part in enumerate(parts):
            (seq, budget, used, seen, ncls, prf, padj, lv7, acc,
             pos, half, sfix) = part
            bl = list(budget)
            kids = solve.r11_children(seq[-1], used, bl)
            if not kids:
                continue
            if target == "uniform":
                # M0 fast path: no scoring state needed, weight = |A_t|
                (p, o, f, s2, bd, wd) = kids[rng.randrange(len(kids))]
                npos, nhalf, nsf, lb = c3_advance(pos, half, sfix, f, s2,
                                                  len(seq))
                if lb > 776:
                    c3_killed += 1
                    continue
                nb = list(budget)
                nb[bd] -= 1
                nb[wd] -= 1
                new_parts[i] = (seq + [f, s2], tuple(nb), used | (1 << p), seen,
                                ncls, prf, padj, lv7, acc, npos, nhalf, nsf)
                step_lw[i] = logw[i] + math.log(len(kids))
                continue
            infos = []
            for (p, o, f, s2, bd, wd) in kids:
                sc, nrf, nadj, nseen, nncls, nlv = solve._r11_step_score(
                    slot, f, s2, seen, ncls, prf, padj, lv7, DECODE_W)
                d1, b, g, d4, d5 = decode_score(sc)
                infos.append(((p, f, s2, bd, wd), (d1, -b, -g, d4, d5),
                              (nrf, nadj, nseen, nncls, nlv)))
            if target == "strict":
                allowed = []
                for info in infos:
                    (p, f, s2, bd, wd), dd, st = info
                    elig = eligible_pair(f, s2)
                    if (not elig or dd[0] == 1) and dd[1] == 0 and dd[2] == 0:
                        allowed.append(info)
                if not allowed:
                    continue
                pick = allowed[rng.randrange(len(allowed))]
                lw_inc = math.log(len(allowed))
            else:  # gibbs
                svals = [lam[0] * dd[0] + lam[1] * dd[1] + lam[2] * dd[2]
                         + lam[3] * dd[3] + lam[4] * dd[4] for _, dd, _ in infos]
                m = max(svals)
                ws = [math.exp(v - m) for v in svals]
                tot = sum(ws)
                r = rng.random() * tot
                acc_w = 0.0
                pick = infos[-1]
                for info, w in zip(infos, ws):
                    acc_w += w
                    if r <= acc_w:
                        pick = info
                        break
                lw_inc = m + math.log(tot)
            (p, f, s2, bd, wd), dd, (nrf, nadj, nseen, nncls, nlv) = pick
            npos, nhalf, nsf, lb = c3_advance(pos, half, sfix, f, s2, len(seq))
            if lb > 776:
                c3_killed += 1
                continue
            nb = list(budget)
            nb[bd] -= 1
            nb[wd] -= 1
            nacc = tuple(a + d for a, d in zip(acc, dd))
            new_parts[i] = (seq + [f, s2], tuple(nb), used | (1 << p), nseen,
                            nncls, nrf, nadj, nlv, nacc, npos, nhalf, nsf)
            step_lw[i] = logw[i] + lw_inc
        alive = [i for i in range(len(parts)) if new_parts[i] is not None]
        if not alive:
            return None, {"failed": "extinct at slot %d" % slot}
        dead_frac += (len(parts) - len(alive)) / len(parts)
        parts = [new_parts[i] for i in alive]
        logw = [step_lw[i] for i in alive]
        # adaptive systematic resampling
        m = max(logw)
        ws = [math.exp(v - m) for v in logw]
        tot = sum(ws)
        ess = tot * tot / sum(w * w for w in ws)
        if ess < n_particles / 2.0 and slot < 31:
            probs = [w / tot for w in ws]
            u0 = rng.random() / n_particles
            cum, j, idxs = 0.0, 0, []
            for i, pr in enumerate(probs):
                cum += pr
                while j < n_particles and u0 + j / n_particles < cum:
                    idxs.append(i)
                    j += 1
            while j < n_particles:          # float-edge padding
                idxs.append(len(probs) - 1)
                j += 1
            parts = [parts[i] for i in idxs]
            logw = [0.0] * len(parts)
    # end-reweight (g6 factor for gibbs). C3-validity is already guaranteed by
    # the exact in-walk lower-bound prune (asserted below on the selected draw).
    final = []
    for (part, lw) in zip(parts, logw):
        seq = part[0]
        if target == "gibbs":
            g6 = solve.r11_axes(seq)[5]
            lw += -lam[5] * g6
        final.append((part, lw))
    if not final:
        return None, {"failed": "no completion survived"}
    m = max(lw for _, lw in final)
    ws = [math.exp(lw - m) for _, lw in final]
    tot = sum(ws)
    ess = tot * tot / sum(w * w for w in ws)
    r = rng.random() * tot
    acc_w, pick = 0.0, final[-1][0]
    for (part, _), w in zip(final, ws):
        acc_w += w
        if r <= acc_w:
            pick = part
            break
    seq, acc5 = pick[0], pick[8]
    assert pick[11] == c3_val(seq) and pick[11] <= 776, \
        "incremental C3 accounting broke (%s vs %s)" % (pick[11], c3_val(seq))
    # increment-accounting audit vs r11_axes (V1=18-Sd1, V2=-Sd2, V3=-Sd3,
    # V4=5-Sd4 [slot-0 covers levels {0,6}], V5=1-Sd5)
    if target != "uniform":
        g = solve.r11_axes(seq)
        expect = (18 - acc5[0], -acc5[1], -acc5[2], 5 - acc5[3], 1 - acc5[4])
        assert tuple(g[:5]) == expect, \
            "increment audit FAILED: axes %s vs accumulated %s" % (g[:5], expect)
    uniq = len(set(tuple(part[0]) for part, _ in final))
    diag = {"final_ess": round(ess, 1), "final_alive": len(final),
            "unique": uniq, "mean_dead_frac": round(dead_frac / 31, 4),
            "c3_killed": c3_killed}
    return seq, diag


def draw_validity_gate(seq):
    assert len(seq) == 64 and len(set(seq)) == 64, "draw not a permutation"
    assert seq[0] == 63 and seq[1] == 0, "slot-0 gauge broken"
    assert Counter(solve.bit_diff(seq[i], seq[i + 1])
                   for i in range(63)) == KW_TRANS, "C5 multiset broken"
    assert solve.has_no_five(seq), "C2 broken"
    assert c3_val(seq) <= 776, "C3 broken"


# ---------------------------------------------------------------------------
# M_C draw machinery: uniform k-event sampler (variant U), any k
def sample_event(k, rng):
    """Uniform draw over footprint-k events; None if the space is empty."""
    if k > 31:
        return None
    weights = []
    ns = []
    for n in range(0, min(15, k // 2) + 1):
        m2 = 2 * n
        w = n_swapsets(n) * comb(31 - m2, k - m2) * (2 ** m2)
        if w > 0:
            weights.append(w)
            ns.append(n)
    if not weights:
        return None
    tot = sum(weights)
    r = rng.randrange(tot)
    acc = 0
    n = ns[-1]
    for nn, w in zip(ns, weights):
        acc += w
        if r < acc:
            n = nn
            break
    # uniform disjoint n-set of adjacent transpositions from 1..30 (gap>=2),
    # via the standard bijection: q_i = s_i - (i-1), q ascending in [1, 31-n]
    if n:
        qs = sorted(rng.sample(range(1, 32 - n), n))
        swaps = [q + i for i, q in enumerate(qs)]
    else:
        swaps = []
    moved = set()
    for s in swaps:
        moved |= {s, s + 1}
    free = sorted(SLOTS - moved)
    ext = set(rng.sample(free, k - 2 * n))
    dec = set(s for s in moved if rng.random() < 0.5)
    return swaps, dec | ext


def mc_draw(pc, precursor, rng, max_tries=100000):
    """One M_C draw: k~geom(pc) (full tail), uniform k-event (U), conditioned on a
    C1-C5-valid outcome via rejection (which IS the model's conditioning). Returns
    (seq, k_realized, tries)."""
    base = to_base(precursor)
    for t in range(1, max_tries + 1):
        k = 0
        while rng.random() >= pc:
            k += 1
        if k == 0:
            return list(precursor), 0, t
        ev = sample_event(k, rng)
        if ev is None:
            continue
        sp, fl = apply_event(base, ev[0], ev[1])
        seq = build_seq(sp, fl)
        if valid_c3(seq):
            return seq, k, t
    raise RuntimeError("mc_draw: no valid outcome in %d tries" % max_tries)


# ---------------------------------------------------------------------------
# ingredient parsing (archived + fresh run outputs)
def parse_est(path):
    for ln in open(path):
        m = re.match(r"\s+leaves_canonical_C1C5 : est=([0-9.e+-]+)\s+"
                     r"95%CI=\[([0-9.e+-]+), ([0-9.e+-]+)\]", ln)
        if m:
            return float(m.group(1)), float(m.group(2)), float(m.group(3))
    raise RuntimeError("no canonical estimate in %s" % path)


def parse_hist(path):
    cells = {}
    for ln in open(path):
        m = re.match(r"r11_hist (\d+) (\d+) (\d+) (\d+) (\d+) (\d+) (\d+) (\d+) "
                     r"([0-9.e+-]+)", ln)
        if m:
            key = tuple(int(m.group(i)) for i in range(1, 9))
            cells[key] = cells.get(key, 0.0) + float(m.group(9))
    if not cells:
        raise RuntimeError("no r11_hist cells in %s" % path)
    return cells


def build_z_cells(ev_r11_dir, fresh_hist_path, n_can_fresh):
    """6-axis (g1..g6) absolute-mass cells, 'aug' recipe (F11 pattern extended):
    bulk = fresh unconditioned hist (minus the g1=g2=0 plane) x N_can;
    Moore-joint plane = archived r11_moore_strict.out (minus g3=0) x N_mj;
    grand-strict corner = archived pooled seed hists (g1=g2=g3=0 plane) x N_gs."""
    bulk = parse_hist(fresh_hist_path)
    tot = sum(bulk.values())
    assert abs(tot - 1.0) < 2e-3, "fresh hist mass sums to %.6f != 1" % tot
    ms_path = os.path.join(ev_r11_dir, "r11_moore_strict.out")
    plane = parse_hist(ms_path)
    n_mj = parse_est(ms_path)[0]
    assert abs(n_mj / 1.1266e29 - 1) < 0.05, "N_mj off the F11 anchor band"
    assert all(k[0] == 0 and k[1] == 0 for k in plane), "moore plane not strict"
    seeds = ["seed1_1001.out", "seed2_2003.out", "seed3_3011.out", "seed4_4013.out"]
    ests = []
    corner = {}
    for sf in seeds:
        p = os.path.join(ev_r11_dir, sf)
        est = parse_est(p)[0]
        ests.append(est)
        for k, v in parse_hist(p).items():
            assert k[0] == 0 and k[1] == 0 and k[2] == 0, "seed cell not GS"
            corner[k] = corner.get(k, 0.0) + v * est / 4.0
    n_gs = sum(ests) / 4.0
    assert abs(n_gs / 4.503e25 - 1) < 0.005, \
        "pooled N_gs %.4e != PHASE2 published 4.503e25" % n_gs
    cells6 = {}

    def add(key8, mass):
        k6 = key8[:6]
        cells6[k6] = cells6.get(k6, 0.0) + mass

    for k, f in bulk.items():
        if k[0] == 0 and k[1] == 0:
            continue                      # replaced by the strict plane
        add(k, f * n_can_fresh)
    for k, f in plane.items():
        if k[2] == 0:
            continue                      # replaced by the GS corner
        add(k, f * n_mj)
    corner_tot = sum(corner.values())
    for k, m in corner.items():
        add(k, m * n_gs / corner_tot)     # corner pinned to pooled direct N_gs
    hist_only = {}
    for k, f in bulk.items():
        k6 = k[:6]
        hist_only[k6] = hist_only.get(k6, 0.0) + f * n_can_fresh
    return cells6, hist_only, n_gs, n_mj


def z_tables(cells6):
    """Z(lam_vec) for the 729-point M_D2 grid and the 7-point M_D1 grid."""
    items = [(k, m) for k, m in cells6.items()]
    maxv = [max(k[j] for k, _ in items) for j in range(6)]
    vecs = []
    for i in range(729):
        v, idx = [], i
        for _ in range(6):
            v.append(LAM3[idx % 3])
            idx //= 3
        vecs.append(tuple(v))
    z2 = {}
    for vec in vecs:
        tabs = [[math.exp(-vec[j] * v) for v in range(maxv[j] + 1)]
                for j in range(6)]
        z = 0.0
        for k, m in items:
            w = m
            for j in range(6):
                w *= tabs[j][k[j]]
            z += w
        z2[vec] = z
    z1 = {}
    for lam in LAM_D1:
        z1[lam] = sum(m * math.exp(-lam * sum(k)) for k, m in items)
    return vecs, z2, z1


# ---------------------------------------------------------------------------
# marginal likelihoods (primary configuration) + sensitivity variants
def l_zero(n_can):
    return 1.0 / n_can


def l_builder(seq, pcomp):
    """Frozen §2.2: mean over the beta grid of exact numerator / P_complete."""
    vals_c, vals_u = [], []
    for beta in BETA_GRID:
        num = solve.r11_builder_numerator(seq, beta)
        vals_c.append(num / pcomp[str(beta)])
        vals_u.append(num)
    return sum(vals_c) / len(vals_c), sum(vals_u) / len(vals_u)


def l_design(g6vec, vecs, z2, z1):
    tot = 0.0
    for vec in vecs:
        e = sum(vec[j] * g6vec[j] for j in range(6))
        tot += math.exp(-e) / z2[vec]
    ld2 = tot / len(vecs)
    ld1 = sum(math.exp(-lam * sum(g6vec)) / z1[lam] for lam in LAM_D1) / len(LAM_D1)
    return ld2, ld1


def l_corr(hitsU, hitsA, in_gs, nk, zAk, vfU, vfA, n_gs):
    """Frozen §5 / compute_f11_bf.py path, k<=6 numerator truncation, D with the
    vf_6 tail bound, k=0 identity term included (w_num(0)=1[S in GS])."""
    out = {}
    for variant, hits, den_k, vf in (("U", hitsU, nk, vfU), ("A", hitsA, zAk, vfA)):
        ls_c, ls_u = [], []
        for p in PC_GRID:
            num = geom(0, p) * (1.0 if in_gs else 0.0)
            num += sum(geom(k, p) * (hits[k] / den_k[k]) for k in range(1, KMAX + 1))
            den = geom(0, p) + sum(geom(k, p) * vf[k] for k in range(1, KMAX + 1))
            den += (1.0 - p) ** (KMAX + 1) * vf[KMAX]
            ls_c.append(num / (n_gs * den))
            ls_u.append(num / n_gs)
        out[variant] = (sum(ls_c) / len(ls_c), sum(ls_u) / len(ls_u))
    return out


# ---------------------------------------------------------------------------
# phase workers
G = {}


def _init_worker(roae_dir):
    global SWAPSETS
    setup(roae_dir)
    SWAPSETS = swap_sets(KMAX // 2)


def _smc_retry(target, lam, n, seed, tries=6):
    """Retry with geometrically growing particle counts: extinction happens in
    the endgame (slots ~28-31, where the C5 budget and strict/g-constraints
    bind on a genealogy-collapsed population), and survival there scales with
    population diversity, i.e. with N."""
    for t in range(tries):
        seq, diag = smc_draw(target, lam, n + 800 * t * t, seed + 900000 * (t + 1))
        if seq is not None:
            diag["retries"] = t
            return seq, diag
    raise RuntimeError("SMC %s failed %d times: %s" % (target, tries, diag))


def _draw_task(args):
    """One synthetic draw. NEVER raises: individual failures are recorded as
    data (per-class draw-failure rates are themselves reportable), so one
    unlucky seed cannot kill the pool (2026-07-20 lesson)."""
    try:
        return _draw_task_inner(args)
    except Exception as e:
        cls, i, seed = args
        return {"cls": cls, "i": i, "failed": repr(e), "seq": None}


def _draw_task_inner(args):
    cls, i, seed = args
    rng = random.Random(seed)
    t0 = time.time()
    if cls == "M0":
        seq, diag = _smc_retry("uniform", None, 1500, seed)
        params = {}
    elif cls == "MG":
        beta = BETA_GRID[rng.randrange(len(BETA_GRID))]
        params = {"beta": beta}
        rejects = 0
        while True:
            seq = solve.r11_builder_synthetic(beta, seed=rng.randrange(1 << 30))
            if seq is not None and c3_val(seq) <= 776:
                break
            rejects += 1
            assert rejects < 500, "MG draw: no C3-valid completion"
        diag = {"c3_rejects": rejects}
    elif cls == "MD":
        lam = tuple(LAM3[rng.randrange(3)] for _ in range(6))
        params = {"lambda": list(lam)}
        seq, diag = _smc_retry("gibbs", lam, 1200, seed)
    else:  # MC
        pc = PC_GRID[rng.randrange(len(PC_GRID))]
        pre, pdiag = _smc_retry("strict", None, 1000, seed + 7777777)
        gpre = solve.r11_axes(pre)
        assert gpre[0] == 0 and gpre[1] == 0 and gpre[2] == 0, "precursor not GS"
        seq, k_real, tries = mc_draw(pc, pre, rng)
        params = {"p_c": pc, "k_realized": k_real, "tries": tries}
        diag = {"precursor": pdiag}
    assert seq is not None, "%s draw %d failed: %s" % (cls, i, diag)
    draw_validity_gate(seq)
    return {"cls": cls, "i": i, "seq": seq, "params": params, "diag": diag,
            "axes": solve.r11_axes(seq), "wall_s": round(time.time() - t0, 1)}


def _pcomplete_task(args):
    beta, n_runs, seed = args
    phat, hw, n = solve.r11_builder_pcomplete(beta, n_runs=n_runs, seed=seed)
    return str(beta), {"phat": phat, "ci_half": hw, "n": n}


def _hits_task(args):
    draw, audit_kmax = args
    t0 = time.time()
    hitsU, hitsA, g = hits_for_seq(draw["seq"], audit_slow_kmax=audit_kmax)
    return {"cls": draw["cls"], "i": draw["i"],
            "hitsU": {str(k): v for k, v in hitsU.items()},
            "hitsA": {str(k): v for k, v in hitsA.items()},
            "in_gs": bool(g[0] == 0 and g[1] == 0 and g[2] == 0),
            "audited_kmax": audit_kmax, "wall_s": round(time.time() - t0, 1)}


# ---------------------------------------------------------------------------
def phase_gates(a):
    """Fail-loud gates before anything is trusted."""
    global SWAPSETS
    SWAPSETS = swap_sets(KMAX // 2)
    ev = json.load(open(os.path.join(a.f11_dir, "f11_events.json")))
    out = {"kw_axes": solve.r11_axes(KW)}
    # 1. event-count combinatorics == archived exact enumeration
    nk = event_counts()
    for k in range(1, KMAX + 1):
        assert nk[k] == ev["KW"][str(k)]["events"] == ev["GRAND"][str(k)]["events"], \
            "event-count gate FAILED at k=%d" % k
    out["event_counts"] = nk
    # 2. decode trick == per-axis basis calls
    out["decode_children_checked"] = decode_gate(random.Random(MASTER_SEED))
    # 3. analyzers on KW
    analyzer_gate(KW)
    # 4. hit enumerator reproduces the archived exact enumeration on BOTH bases
    #    (KW: pruned path exercised, R nonempty; GRAND: full path, R empty)
    grand = [63, 0, 17, 34, 23, 58, 2, 16, 55, 59, 7, 56, 61, 47, 8, 4, 25, 38, 3,
             48, 41, 37, 32, 1, 57, 39, 33, 30, 18, 45, 28, 14, 60, 15, 40, 5, 53,
             43, 20, 10, 35, 49, 24, 6, 62, 31, 26, 22, 29, 46, 9, 36, 52, 11, 13,
             44, 54, 27, 50, 19, 51, 12, 21, 42]
    assert valid_c3(grand) and grand_ok(grand), "GRAND witness ground truth broke"
    for name, base in (("KW", KW), ("GRAND", grand)):
        t0 = time.time()
        hu, ha, _ = hits_for_seq(base)
        for k in range(1, KMAX + 1):
            exp_h = len(ev[name][str(k)]["hits"])
            assert hu[k] == exp_h, \
                "hits gate FAILED %s k=%d: %d vs archived %d" % (name, k, hu[k], exp_h)
            assert abs(ha[k] - ev[name][str(k)]["zA_hits"]) < 1e-9, \
                "zA_hits gate FAILED %s k=%d" % (name, k)
        out["hits_gate_%s_wall_s" % name] = round(time.time() - t0, 1)
    # 5. event SAMPLER matches the count decomposition (chi^2-free sanity: support)
    rng = random.Random(MASTER_SEED + 1)
    for k in range(1, KMAX + 1):
        for _ in range(50):
            sw, fl = sample_event(k, rng)
            moved = set()
            for s in sw:
                moved |= {s, s + 1}
            assert len(moved | fl) == k, "sampler footprint size mismatch"
    out["builder_verify_exit"] = solve.r11_builder_verify()
    assert out["builder_verify_exit"] == 0, "r11_builder_verify FAILED"
    json.dump(out, open(os.path.join(a.out, "gates.json"), "w"), indent=1)
    print("GATES PASS", json.dumps(out)[:400])


def phase_draws(a):
    tasks = []
    for ci, cls in enumerate(CLASSES):
        for i in range(N_DRAWS):
            tasks.append((cls, i, MASTER_SEED + 1000 * ci + i))
    with Pool(a.procs, initializer=_init_worker, initargs=(a.roae,)) as pool:
        res = pool.map(_draw_task, tasks, chunksize=1)
    json.dump(res, open(os.path.join(a.out, "draws.json"), "w"))
    per = {c: sum(1 for r in res if r["cls"] == c and r.get("seq"))
           for c in CLASSES}
    fails = {c: sum(1 for r in res if r["cls"] == c and not r.get("seq"))
             for c in CLASSES}
    for r in res:
        if not r.get("seq"):
            print("DRAW FAILURE %s #%d: %s" % (r["cls"], r["i"], r["failed"]))
    print("DRAWS DONE ok=%s failures=%s wall max %.1f s"
          % (per, fails, max(r.get("wall_s", 0.0) for r in res)))


def phase_pcomplete(a):
    tasks = []
    for bi, beta in enumerate(BETA_GRID):
        for c in range(a.procs):
            tasks.append((beta, a.pcomplete_n // a.procs,
                          MASTER_SEED + 77000 + 100 * bi + c))
    with Pool(a.procs, initializer=_init_worker, initargs=(a.roae,)) as pool:
        res = pool.map(_pcomplete_task, tasks, chunksize=1)
    agg = {}
    for key, r in res:
        agg.setdefault(key, []).append(r)
    out = {}
    for key, rs in agg.items():
        n = sum(r["n"] for r in rs)
        ph = sum(r["phat"] * r["n"] for r in rs) / n
        out[key] = {"phat": ph, "n": n,
                    "ci_half": 1.96 * math.sqrt(max(ph * (1 - ph), 0.0) / n)}
    json.dump(out, open(os.path.join(a.out, "pcomplete.json"), "w"), indent=1)
    print("PCOMPLETE", json.dumps(out))


def phase_hits(a):
    draws = [d for d in json.load(open(os.path.join(a.out, "draws.json")))
             if d.get("seq")]
    rng = random.Random(MASTER_SEED + 5)
    audit_ids = set(rng.sample(range(len(draws)), 5))   # slow-path audit draws
    tasks = [(d, 3 if j in audit_ids else 0) for j, d in enumerate(draws)]
    with Pool(a.procs, initializer=_init_worker, initargs=(a.roae,)) as pool:
        res = pool.map(_hits_task, tasks, chunksize=1)
    json.dump(res, open(os.path.join(a.out, "hits.json"), "w"))
    slow = [r for r in res if r["audited_kmax"]]
    print("HITS DONE; slow-path audits:", len(slow), "max wall",
          max(r["wall_s"] for r in res), "s")


def phase_score(a):
    global SWAPSETS
    SWAPSETS = swap_sets(KMAX // 2)
    all_draws = json.load(open(os.path.join(a.out, "draws.json")))
    draws = [d for d in all_draws if d.get("seq")]
    n_failed = {c: sum(1 for d in all_draws
                       if d["cls"] == c and not d.get("seq")) for c in CLASSES}
    hits = {(h["cls"], h["i"]): h
            for h in json.load(open(os.path.join(a.out, "hits.json")))}
    pcomp = json.load(open(os.path.join(a.out, "pcomplete.json")))
    ev = json.load(open(os.path.join(a.f11_dir, "f11_events.json")))
    nk = {k: ev["GRAND"][str(k)]["events"] for k in range(1, KMAX + 1)}
    zAk = {k: ev["GRAND"][str(k)]["zA"] for k in range(1, KMAX + 1)}
    vfU = {k: ev["GRAND"][str(k)]["valid"] / ev["GRAND"][str(k)]["events"]
           for k in range(1, KMAX + 1)}
    vfA = {k: ev["GRAND"][str(k)]["zA_valid"] / ev["GRAND"][str(k)]["zA"]
           for k in range(1, KMAX + 1)}
    n_can_fresh, lo, hi = parse_est(a.hist)
    n_can_anchor = parse_est(os.path.join(a.f11_dir, "f11_runA.out"))[0]
    assert abs(n_can_fresh / n_can_anchor - 1) < 0.05, \
        "fresh N_can %.4e outside 5%% of anchor %.4e" % (n_can_fresh, n_can_anchor)
    cells6, hist_only, n_gs, n_mj = build_z_cells(a.r11_dir, a.hist, n_can_fresh)
    vecs, z2, z1 = z_tables(cells6)
    vecs_h, z2_h, z1_h = z_tables(hist_only)
    scores = []
    for d in draws:
        seq = d["seq"]
        h = hits[(d["cls"], d["i"])]
        hU = {int(k): v for k, v in h["hitsU"].items()}
        hA = {int(k): v for k, v in h["hitsA"].items()}
        g = solve.r11_axes(seq)
        lg_c, lg_u = l_builder(seq, {k: v["phat"] for k, v in pcomp.items()})
        ld2, ld1 = l_design(g[:6], vecs, z2, z1)
        ld2_h, _ = l_design(g[:6], vecs_h, z2_h, z1_h)
        lc = l_corr(hU, hA, h["in_gs"], nk, zAk, vfU, vfA, n_gs)
        scores.append({
            "cls": d["cls"], "i": d["i"], "axes": g, "params": d["params"],
            "L0": l_zero(n_can_fresh),
            "LG": lg_c, "LG_uncond": lg_u,
            "LD": ld2, "LD1": ld1, "LD_histZ": ld2_h,
            "LC": lc["U"][0], "LC_A": lc["A"][0], "LC_uncond": lc["U"][1],
            "in_gs": h["in_gs"]})
    meta = {"n_can_fresh": n_can_fresh, "n_can_anchor": n_can_anchor,
            "n_gs_pooled": n_gs, "n_mj": n_mj,
            "z_cells_aug": len(cells6), "z_cells_hist": len(hist_only),
            "draw_failures": n_failed, "pcomplete": pcomp}
    json.dump({"meta": meta, "scores": scores},
              open(os.path.join(a.out, "scores.json"), "w"))
    print("SCORES DONE", json.dumps(meta)[:400])


def rank_of(sc, variant="primary"):
    if variant == "primary":
        ls = {"M0": sc["L0"], "MG": sc["LG"], "MD": sc["LD"], "MC": sc["LC"]}
    elif variant == "corrA":
        ls = {"M0": sc["L0"], "MG": sc["LG"], "MD": sc["LD"], "MC": sc["LC_A"]}
    elif variant == "uncond":
        ls = {"M0": sc["L0"], "MG": sc["LG_uncond"], "MD": sc["LD"],
              "MC": sc["LC_uncond"]}
    elif variant == "histZ":
        ls = {"M0": sc["L0"], "MG": sc["LG"], "MD": sc["LD_histZ"], "MC": sc["LC"]}
    order = sorted(CLASSES, key=lambda c: -ls[c])
    return order, ls


def phase_report(a):
    data = json.load(open(os.path.join(a.out, "scores.json")))
    scores = data["scores"]
    lines = []

    def emit(s=""):
        lines.append(s)
        print(s)

    emit("R11 SS7.2 SYNTHETIC-DRAW CALIBRATION — confusability gate "
         "(NO KW-facing verdict; design R11_BAYES_V2_DESIGN_2026_07_10.md)")
    emit("generated %s UTC; master seed %d; n=%d/class; primary config: "
         "MG uniform-w conditioned, MD2 per-axis Z-aug, MC variant-U conditioned "
         "direct-pooled N_gs" % (time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime()),
                                 MASTER_SEED, N_DRAWS))
    for variant in ("primary", "corrA", "uncond", "histZ"):
        conf = {c: Counter() for c in CLASSES}
        firstrate = {c: 0 for c in CLASSES}
        med_bf = {c: [] for c in CLASSES}
        pair_beats = {c: Counter() for c in CLASSES}   # true beats rival j
        pair_toprival = {c: Counter() for c in CLASSES}
        pair_topwin = {c: Counter() for c in CLASSES}
        for sc in scores:
            order, ls = rank_of(sc, variant)
            t = sc["cls"]
            conf[t][order[0]] += 1
            rivals = [c for c in CLASSES if c != t]
            best_r = max(rivals, key=lambda c: ls[c])
            pair_toprival[t][best_r] += 1
            if order[0] == t:
                firstrate[t] += 1
                pair_topwin[t][best_r] += 1
            for j in rivals:
                if ls[t] > ls[j]:
                    pair_beats[t][j] += 1
            lt, lb = ls[t], ls[best_r]
            if lt > 0 and lb > 0:
                med_bf[t].append(math.log10(lt / lb))
            elif lt > 0:
                med_bf[t].append(float("inf"))
            else:
                med_bf[t].append(float("-inf"))
        emit()
        emit("== variant: %s ==" % variant)
        emit("confusion matrix (rows=true, cols=argmax):")
        emit("        " + "  ".join("%5s" % c for c in CLASSES))
        for c in CLASSES:
            emit("  %4s  " % c + "  ".join("%5d" % conf[c][k] for k in CLASSES))
        emit("first-rank rate: " + "  ".join(
            "%s=%d/%d" % (c, firstrate[c], N_DRAWS) for c in CLASSES))
        for c in CLASSES:
            b = sorted(med_bf[c])
            m = b[len(b) // 2] if len(b) % 2 else 0.5 * (b[len(b) // 2 - 1]
                                                         + b[len(b) // 2])
            emit("  median log10 BF(true/best-rival) %s: %s" %
                 (c, "%.2f" % m if math.isfinite(m) else str(m)))
        emit("pairwise: true-class draws where true beats rival "
             "(and: rival was top rival -> wins/top)")
        for c in CLASSES:
            row = []
            for j in CLASSES:
                if j == c:
                    row.append("  -  ")
                else:
                    row.append("%3d (%d/%d)" % (pair_beats[c][j],
                                                pair_topwin[c][j],
                                                pair_toprival[c][j]))
            emit("  %4s: " % c + " | ".join(row))
        if variant == "primary":
            emit()
            fails = data["meta"].get("draw_failures", {})
            emit("SS7.2 / SS6.3 VETO VERDICT (frozen threshold: <%d/100 true-first "
                 "=> confusable => no publishable verdict for that pair/class; "
                 "failed draws count against their class, out of the frozen 100):"
                 % VETO_THRESHOLD)
            overall = True
            for c in CLASSES:
                ok = firstrate[c] >= VETO_THRESHOLD
                overall = overall and ok
                note = (" [%d draw failures]" % fails.get(c, 0)
                        if fails.get(c) else "")
                emit("  %s: %d/100 -> %s%s" % (c, firstrate[c],
                                               "PASS" if ok else
                                               "FAIL (confusable)", note))
            emit("  OVERALL: %s" % ("PASS — classes separable at the frozen "
                                    "threshold" if overall else
                                    "FAIL — at least one class below 70/100; "
                                    "SS6.3 veto engages for the affected pairs"))
    emit()
    emit("ingredient meta: " + json.dumps(data["meta"], default=str)[:600])
    with open(os.path.join(a.out, "calibration_report.txt"), "w") as f:
        f.write("\n".join(lines) + "\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--roae", default=os.path.expanduser("~/roae"))
    ap.add_argument("--out", default=os.path.expanduser("~/r11_calib"))
    ap.add_argument("--hist", default=os.path.expanduser("~/r11_calib/hist.out"))
    ap.add_argument("--procs", type=int, default=8)
    ap.add_argument("--pcomplete-n", type=int, default=16000)
    ap.add_argument("--phase", required=True,
                    choices=["gates", "draws", "pcomplete", "hits", "score",
                             "report"])
    a = ap.parse_args()
    a.f11_dir = os.path.join(a.roae, "reports", "evidence", "f11")
    a.r11_dir = os.path.join(a.roae, "reports", "evidence", "r11")
    os.makedirs(a.out, exist_ok=True)
    setup(a.roae)
    t0 = time.time()
    {"gates": phase_gates, "draws": phase_draws, "pcomplete": phase_pcomplete,
     "hits": phase_hits, "score": phase_score, "report": phase_report}[a.phase](a)
    print("PHASE %s WALL %.1f s" % (a.phase, time.time() - t0))


if __name__ == "__main__":
    main()
