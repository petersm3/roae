#!/usr/bin/env python3
"""atlas_followups.py -- inputs and summary statistics for the TR-12 section 12.7 follow-up queries.

TR-12 section 12.7 names three follow-ups to the n = 31 atlas that need the f and g ladders: (i) a
calibrated null for section 12.3 (query 1b), (ii) the same profile for King Wen's nearest valid
neighbours (query 8), (iii) which constraint kills a doomed prefix (query 7).  A fourth query (9)
realises one walk through each of the atlas's extreme transitions.  scripts/atlas_followups.sh runs
the four against the ladders; this file, which sits beside the committed outputs, builds their inputs and turns their outputs into the
whole-line tokens the report quotes.  It needs no ladder.

  python3 reports/evidence/tr12/atlas_followups_n31_20260925/atlas_followups.py inputs OUTDIR
      writes OUTDIR/q8_walks.tsv (King Wen's 9 valid single-orientation flips, the distance-2 C15
      witness, King Wen itself) and OUTDIR/q1b_walks.tsv (the 1,000 gallery walks of battery row
      a1_q8_super), each walk re-checked from first principles before it is written.

  python3 reports/evidence/tr12/atlas_followups_n31_20260925/atlas_followups.py summary DIR
      [--atlas ATLAS.json] [--walks q1b_walks.tsv] [--expect TOKENS.txt]
      DIR is an output directory of scripts/atlas_followups.sh, or this directory (the committed
      n = 31 outputs).  Prints AF_* tokens; every gate must
      PASS; with --expect, every line of TOKENS.txt must be printed verbatim.  Last line:
      AF_SUMMARY=PASS | FAIL:<what>.  Exit 0 only on PASS.

WHAT THE NUMBERS ARE.  The 1,000 walks are a SAMPLE, drawn uniformly with replacement from the
C1&C2&C4&C5 superspace (C3 is not applied; this is not a draw from C1-C5).  The statistic is the
mean over the n steps of the walk's transition mass percentile within its distance class at OCTAVE
resolution (the atlas's `hist` table: bucket floor(log2 w), half credit for the walk's own bucket).
The atlas holds exact bins only for King Wen's own transitions, so the exact percentile of
section 12.3 cannot be formed for a sampled walk; the like-for-like comparison is octave against
octave.  The dead-state census (query 7) is an exact count over the layers it names, not a sample.

Pure standard library; counts and percentiles are exact integers or Fractions, floats only when
printing and in the Clopper-Pearson bisection.  Developed with AI assistance (Claude Fable 5.2,
Anthropic; the statistics follow a private analysis of 2026-09-25 by Claude Opus 5.5).
"""
import glob
import gzip
import hashlib
import json
import math
import os
import sys
from collections import Counter, defaultdict
from fractions import Fraction

HERE = os.path.dirname(os.path.abspath(__file__))        # .../reports/evidence/tr12/atlas_followups_n31_20260925
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(HERE))))
DEFAULT_ATLAS = os.path.join(ROOT, 'runs', '20260906_kc_ladders_n31', 'atlas_n31.json')
GALLERY = os.path.join(ROOT, 'reports', 'evidence', 'tr12', 'banked_n31_20260922', 'a1_q8_super.txt')
WITNESS = os.path.join(ROOT, 'reports', 'certificates', 'c3_positional_witnesses.txt')
# The walk lists the 2026-09-25 and 2026-10-26 runs read (sha256 of the files this script writes).
PIN_Q8_WALKS = 'e18d759f3a42909468df3bf84f6945773f01c65d54c7d86ef084d2960d51cf19'
PIN_Q1B_WALKS = 'dd99cbf074dbc92f6a69a40eb6ab1baca31353b875cdad5ace9284eb6b21f792'


def hamming(a, b):
    return bin(a ^ b).count('1')


def _open(path):
    """path or path + '.gz', text mode."""
    if os.path.exists(path):
        return open(path)
    if os.path.exists(path + '.gz'):
        return gzip.open(path + '.gz', 'rt')
    raise FileNotFoundError(path)


def _exists(path):
    return os.path.exists(path) or os.path.exists(path + '.gz')


# ------------------------------------------------------------------------------------------ inputs
def _verify_module():
    sys.path.insert(0, ROOT)
    import verify
    return verify


def _checker(verify):
    kw = list(verify.KW)
    assert kw[:2] == [63, 0] and len(kw) == 64
    multiset = Counter(hamming(kw[i], kw[i + 1]) for i in range(63))
    pair_of = {}
    for a, b in verify.PAIRS:
        pair_of[a] = b
        pair_of[b] = a

    def check(seq, label):
        """-> the 62-value walk string; raises AssertionError naming the first violated rule."""
        assert len(seq) == 64 and sorted(seq) == list(range(64)), label + ': not a permutation of 0..63'
        assert seq[0] == 63 and seq[1] == 0, label + ': C4 anchor'
        for i in range(0, 64, 2):
            assert pair_of[seq[i]] == seq[i + 1], label + ': C1 pair adjacency at slot %d' % (i // 2)
        steps = [hamming(seq[i], seq[i + 1]) for i in range(63)]
        assert 5 not in steps, label + ': C2'
        assert Counter(steps) == multiset, label + ': C5 multiset'
        return ','.join(str(h) for h in seq[2:])
    return kw, multiset, check


def gallery_walks(path=GALLERY):
    """[(label, 62-value walk string)] for the rank lines of a --kc-sample --kc-record output."""
    out = []
    for line in open(path):
        parts = line.rstrip('\n').split('\t')
        if len(parts) != 3 or parts[0] == 'record' or not parts[1].startswith('cd='):
            continue
        out.append(('rank%s_%s' % (parts[0], parts[1]), parts[2]))
    return out


def cmd_inputs(outdir):
    verify = _verify_module()
    kw, multiset, check = _checker(verify)

    def record_to_seq(rec):
        seq = []
        for i in range(32):
            a, b = verify.PAIRS[(rec[i] >> 2) & 0x3F]
            seq += [b, a] if (rec[i] >> 1) & 1 else [a, b]
        return seq
    base = verify.repr_of_key(list(range(32)))
    assert base is not None and record_to_seq(base) == kw, 'the King Wen record does not decode to King Wen'
    q8 = []
    for i in range(1, 32):
        t = bytearray(base)
        t[i] ^= 0x02
        seq = record_to_seq(bytes(t))
        steps = [hamming(seq[j], seq[j + 1]) for j in range(63)]
        if 5 in steps or Counter(steps) != multiset:
            continue
        q8.append(('kw_flip_slot%02d' % i, check(seq, 'flip %d' % i)))
    assert len(q8) == 9, 'expected 9 valid flips (verify.py --check-flips PASS=9), got %d' % len(q8)
    wit = None
    for line in open(WITNESS):
        if line.startswith('# WITNESS_SEQ '):
            wit = [int(x) for x in line.split()[2:]]
    assert wit is not None, 'WITNESS_SEQ line not found in ' + WITNESS
    q8.append(('c15_distance2_witness_slots1_13', check(wit, 'distance-2 witness')))
    q8.append(('kw_itself', check(kw, 'KW')))
    q1b = [(lab, check([63, 0] + [int(x) for x in w.split(',')], lab)) for lab, w in gallery_walks()]
    assert len(q1b) == 1000, 'expected 1000 gallery walks, got %d' % len(q1b)
    os.makedirs(outdir, exist_ok=True)
    p8, p1 = os.path.join(outdir, 'q8_walks.tsv'), os.path.join(outdir, 'q1b_walks.tsv')
    with open(p8, 'w') as o:
        o.write('#q8_walks\tsource=verify.py --check-flips PASS flips of the KW record + reports/certificates/'
                'c3_positional_witnesses.txt WITNESS_SEQ\tformat=label<TAB>e,x,...(62)\n')
        for lab, w in q8:
            o.write('%s\t%s\n' % (lab, w))
    with open(p1, 'w') as o:
        o.write('#q1b_walks\tsource=q8_super.tsv rank lines (1,000 exact-uniform SUPER samples)\t'
                'format=label<TAB>e,x,...(62)\n')
        for lab, w in q1b:
            o.write('%s\t%s\n' % (lab, w))
    s8 = hashlib.sha256(open(p8, 'rb').read()).hexdigest()
    s1 = hashlib.sha256(open(p1, 'rb').read()).hexdigest()
    print('AF_Q8_WALKS=%d' % len(q8))
    print('AF_Q1B_WALKS=%d' % len(q1b))
    print('AF_Q8_WALKS_SHA256=%s' % s8)
    print('AF_Q1B_WALKS_SHA256=%s' % s1)
    ok = s8 == PIN_Q8_WALKS and s1 == PIN_Q1B_WALKS
    print('AF_INPUTS=%s' % ('PASS' if ok else 'FAIL:walk_lists_differ_from_the_lists_the_2026-09-25_run_read'))
    return 0 if ok else 1


# ----------------------------------------------------------------------------------------- summary
def _lbinom(nn, k):
    return math.lgamma(nn + 1) - math.lgamma(k + 1) - math.lgamma(nn - k + 1)


def binom_cdf(k, nn, p):
    if k < 0:
        return 0.0
    if k >= nn:
        return 1.0
    if p <= 0:
        return 1.0
    if p >= 1:
        return 0.0
    return min(1.0, sum(math.exp(_lbinom(nn, i) + i * math.log(p) + (nn - i) * math.log1p(-p))
                        for i in range(k + 1)))


def _bisect(f):
    lo, hi = 0.0, 1.0
    for _ in range(200):
        mid = (lo + hi) / 2
        if f(mid):
            hi = mid
        else:
            lo = mid
    return (lo + hi) / 2


def clopper_pearson(x, nn, alpha=0.05):
    lo = 0.0 if x == 0 else _bisect(lambda p: 1 - binom_cdf(x - 1, nn, p) >= alpha / 2)
    hi = 1.0 if x == nn else _bisect(lambda p: binom_cdf(x, nn, p) <= alpha / 2)
    return lo, hi


def order_stat(v, q):
    """TR-12's convention: the ceil(q*n)-th smallest."""
    return v[min(len(v), max(1, math.ceil(q * len(v)))) - 1]


class Summary:
    def __init__(self, d, atlas_path, walks_path):
        self.d = d
        self.A = json.load(open(atlas_path))
        self.L = self.A['layers']
        self.n = self.A['n']
        self.walks_path = walks_path
        self.lines = []
        self.fails = []

    def tok(self, k, v):
        self.lines.append('%s=%s' % (k, v))

    def gate(self, k, ok):
        self.lines.append('AF_GATE_%s=%s' % (k, 'PASS' if ok else 'FAIL'))
        if not ok:
            self.fails.append(k)

    def octave(self, k0, w, d):
        """octave-resolution mass percentile of transition mass w within class d at step k0+1."""
        lay = self.L[k0]
        hb = lay['hist']['hb%d' % d]
        b = w.bit_length() - 1
        below = sum(int(v['hwo']) for kk, v in hb.items() if int(kk[2:]) < b)
        here = int(hb.get('lg%d' % b, {}).get('hwo', '0'))
        tot = int(lay['by_class']['d%d' % d])
        if here == 0 or tot == 0:
            raise ValueError('step %d class d%d: no atlas bucket for w=%d' % (k0 + 1, d, w))
        return Fraction(2 * below + here, 2 * tot)

    def read_profile(self, path):
        hdr, data = None, []
        for line in open(path):
            parts = line.rstrip('\n').split('\t')
            if parts and parts[0] == 'step':
                hdr = parts
                continue
            if hdr and len(parts) == len(hdr) and parts[0].isdigit():
                data.append(dict(zip(hdr, parts)))
        if len(data) != self.n:
            raise ValueError('%s: %d step rows, expected %d' % (path, len(data), self.n))
        f_prev, ws, cls, walk = 1, [], [], []
        for r in data:
            ws.append(f_prev * int(r['g']))
            f_prev = int(r['f'])
            cls.append(int(r['dclass']))
            walk += [int(r['entry']), int(r['exit'])]
        return dict(w=ws, cls=cls, f=[int(r['f']) for r in data], g=[int(r['g']) for r in data], walk=walk)

    @staticmethod
    def read_summary(path):
        rows, toks = {}, {}
        for line in _open(path):
            parts = line.rstrip('\n').split('\t')
            if len(parts) == 7 and parts[1] == 'OK':
                rows[parts[0]] = dict(lt=int(parts[2]), eq=int(parts[3]), gt=int(parts[4]), mean=parts[5],
                                      w=[int(x) for x in parts[6].split()])
            elif len(parts) == 1 and '=' in parts[0] and not parts[0].startswith('#'):
                k, v = parts[0].split('=', 1)
                toks[k] = v
        return rows, toks

    # ---- query 8
    def q8(self):
        n, L = self.n, self.L
        d = os.path.join(self.d, 'q8')
        P = {os.path.basename(p)[:-4]: self.read_profile(p) for p in sorted(glob.glob(os.path.join(d, '*.tsv')))
             if os.path.basename(p) != 'summary.tsv'}
        S, toks = self.read_summary(os.path.join(d, 'summary.tsv'))
        self.tok('AF_Q8_PROFILES', len(P))
        self.gate('Q8_SUMMARY_COVERS_EVERY_PROFILE', bool(P) and set(P) == set(S))
        oct8 = {}
        for lab in sorted(P):
            steps = [self.octave(k, P[lab]['w'][k], P[lab]['cls'][k]) for k in range(n)]
            oct8[lab] = sum(steps) / n
        self.gate('Q8_OCTAVE_MEANS_RECOMPUTED_FROM_PROFILES',
                  all('%.6f' % float(oct8[lab]) == S[lab]['mean'] and P[lab]['w'] == S[lab]['w'] for lab in P if lab in S))
        self.oct8 = oct8
        self.q8_profiles = P
        if 'kw_itself' not in P or n != 31:
            self.tok('AF_Q8_KW_LEGS', 'SKIP:n=%d (King Wen exists only at n=31)' % n)
            return
        kw = P['kw_itself']
        kw_w = [int(L[k]['kwrank']['kw_w']) for k in range(n)]
        kw_cls = [int(L[k]['kwrank']['kw_cls']) for k in range(n)]
        self.gate('Q8_KW_PROFILE_EQUALS_ATLAS_KW_W_ALL_STEPS', kw['w'] == kw_w and kw['cls'] == kw_cls)
        self.gate('Q8_RUN_TOKEN_KW_W_MATCHES_ATLAS', toks.get('KW_W_MATCHES_ATLAS') == 'YES')
        self.tok('AF_Q8_KW_OCTAVE_MEAN', '%.6f' % float(oct8['kw_itself']))
        flips = sorted(l for l in P if l.startswith('kw_flip'))
        same = [l for l in flips if P[l]['w'] == kw['w'] and P[l]['f'] == kw['f'] and P[l]['g'] == kw['g']]
        self.tok('AF_Q8_FLIPS', len(flips))
        self.tok('AF_Q8_FLIPS_F_G_W_IDENTICAL_TO_KW_AT_EVERY_STEP', '%d/%d' % (len(same), len(flips)))
        for lab in sorted(P):
            if lab == 'kw_itself':
                continue
            dw = [k + 1 for k in range(n) if P[lab]['w'][k] != kw['w'][k]]
            dc = [k + 1 for k in range(n) if P[lab]['cls'][k] != kw['cls'][k]]
            self.tok('AF_Q8:%s' % lab, 'octave_mean=%.6f steps_w_differs=%s steps_class_differs=%s'
                     % (float(oct8[lab]), ','.join(map(str, dw)) or 'none', ','.join(map(str, dc)) or 'none'))
        self.tok('AF_Q8_OCTAVE_MEAN_MIN_MAX_OVER_11', '%.6f,%.6f' % (float(min(oct8.values())), float(max(oct8.values()))))

    # ---- query 1b
    def q1b(self):
        n, L = self.n, self.L
        S, _ = self.read_summary(os.path.join(self.d, 'q1b', 'summary.tsv'))
        M = len(S)
        self.tok('AF_Q1B_WALKS', M)
        # the per-step distance class: from the profiles when the directory has them, else from the walks
        cls = {}
        pdir = os.path.join(self.d, 'q1b', 'profiles')
        have_profiles = os.path.isdir(pdir)
        if have_profiles:
            for lab in S:
                p = self.read_profile(os.path.join(pdir, lab + '.tsv'))
                cls[lab] = p['cls']
                if p['w'] != S[lab]['w']:
                    self.fails.append('Q1B_PROFILE_W_NE_SUMMARY_W:' + lab)
        walks = None
        if self.walks_path:
            walks = dict(l.rstrip('\n').split('\t') for l in open(self.walks_path) if not l.startswith('#'))
        elif n == 31 and os.path.exists(GALLERY):
            walks = dict(gallery_walks())
        if walks is not None and n == 31:
            derived = {}
            for lab in S:
                if lab not in walks:
                    self.fails.append('Q1B_LABEL_NOT_IN_WALK_LIST:' + lab)
                    continue
                h = [0] + [int(x) for x in walks[lab].split(',')]      # 0 = the anchor pair's exit
                derived[lab] = [hamming(h[2 * k], h[2 * k + 1]) for k in range(n)]
            if have_profiles:
                self.gate('Q1B_CLASSES_FROM_WALKS_EQUAL_PROFILE_CLASSES', derived == cls)
            else:
                cls = derived
                self.tok('AF_Q1B_CLASS_SOURCE', 'walk-list (no profiles in this directory)')
        self.gate('Q1B_EVERY_WALK_HAS_CLASSES', bool(S) and set(cls) == set(S))
        if set(cls) != set(S):
            return
        steps = {lab: [self.octave(k, S[lab]['w'][k], cls[lab][k]) for k in range(n)] for lab in S}
        means = {lab: sum(v) / n for lab, v in steps.items()}
        self.gate('Q1B_OCTAVE_MEANS_RECOMPUTED_FROM_W', all('%.6f' % float(means[l]) == S[l]['mean'] for l in S))
        band = sorted(means.values())
        fb = [float(x) for x in band]
        mean_b = sum(fb) / M
        sd_b = math.sqrt(sum((x - mean_b) ** 2 for x in fb) / (M - 1))
        self.tok('AF_Q1B_BAND_MIN_P01_P05_P50_P95_P99_MAX', ','.join('%.4f' % float(v) for v in (
            band[0], order_stat(band, Fraction(1, 100)), order_stat(band, Fraction(5, 100)), order_stat(band, Fraction(1, 2)),
            order_stat(band, Fraction(95, 100)), order_stat(band, Fraction(99, 100)), band[-1])))
        self.tok('AF_Q1B_BAND_MEAN_SD', '%.4f,%.4f' % (mean_b, sd_b))
        self.tok('AF_Q1B_BAND_SD_IF_STEPS_WERE_INDEPENDENT_UNIFORM', '%.4f' % math.sqrt(1 / 12 / n))
        allp = [p for v in steps.values() for p in v]
        self.tok('AF_Q1B_SAMPLE_PER_STEP_OCTAVE_PCT_GRAND_MEAN', '%.4f' % float(sum(allp) / len(allp)))
        if n != 31 or 'kw_itself' not in getattr(self, 'oct8', {}):
            self.tok('AF_Q1B_KW_LEGS', 'SKIP:n=%d (King Wen exists only at n=31)' % n)
            return
        kw = self.oct8['kw_itself']
        below = sum(1 for x in band if x < kw)
        tied = sum(1 for x in band if x == kw)
        self.tok('AF_Q1B_KW_OCTAVE_MEAN', '%.6f' % float(kw))
        self.tok('AF_Q1B_SAMPLED_WALKS_BELOW_KW', '%d/%d' % (below, M))
        self.tok('AF_Q1B_SAMPLED_WALKS_TIED_WITH_KW', tied)
        lo, hi = clopper_pearson(below + tied, M)
        self.tok('AF_Q1B_TAIL_FRACTION_CP95', '[%.4f,%.4f]' % (lo, hi))
        p01, p99 = order_stat(band, Fraction(1, 100)), order_stat(band, Fraction(99, 100))
        self.tok('AF_Q1B_KW_INSIDE_P01_P99', 'YES' if p01 <= kw <= p99 else 'NO')
        self.tok('AF_Q1B_KW_SD_FROM_BAND_MEAN', '%.2f' % ((float(kw) - mean_b) / sd_b))
        for lab in sorted(self.oct8):
            if lab != 'kw_itself':
                self.tok('AF_Q1B_SAMPLED_WALKS_AT_OR_BELOW:%s' % lab, sum(1 for x in band if x <= self.oct8[lab]))
        # King Wen's exact percentile from the atlas, lt-only (section 12.3) and mid-rank
        kw_w = [int(L[k]['kwrank']['kw_w']) for k in range(n)]
        kw_cls = [int(L[k]['kwrank']['kw_cls']) for k in range(n)]
        ex_lt, ex_mid = [], []
        for k in range(n):
            r = L[k]['kwrank']['kwr%d' % kw_cls[k]]
            lt, eq, gt = (int(r[b]['rw']) for b in ('lt', 'eq', 'gt'))
            ex_lt.append(Fraction(lt, lt + eq + gt))
            ex_mid.append(Fraction(2 * lt + eq, 2 * (lt + eq + gt)))
        self.tok('AF_KW_EXACT_LT_PERCENTILE_MEAN', '%.3f' % float(sum(ex_lt) / n))
        self.tok('AF_KW_EXACT_MIDRANK_PERCENTILE_MEAN', '%.4f' % float(sum(ex_mid) / n))
        # does the sample reproduce the atlas's exact per-step value?  Conditioned on the step class
        # (the atlas's bins are within-class); the unconditioned comparison is the negative control.
        out_c = out_u = 0
        labs = sorted(S)
        for k in range(n):
            sub = [l for l in labs if cls[l][k] == kw_cls[k]]
            x = sum(1 for l in sub if S[l]['w'][k] < kw_w[k])
            lo, hi = clopper_pearson(x, len(sub))
            out_c += not (lo <= float(ex_lt[k]) <= hi)
            xu = sum(1 for l in labs if S[l]['w'][k] < kw_w[k])
            lo, hi = clopper_pearson(xu, M)
            out_u += not (lo <= float(ex_lt[k]) <= hi)
        self.tok('AF_Q1B_STEPS_WHERE_ATLAS_EXACT_VALUE_IS_OUTSIDE_SAMPLE_CP95', '%d/%d' % (out_c, n))
        self.tok('AF_Q1B_SAME_COUNT_WITHOUT_CLASS_CONDITIONING_NEGATIVE_CONTROL', '%d/%d' % (out_u, n))

    # ---- query 7
    def q7(self):
        n, L = self.n, self.L
        rows, layers, rng = [], {}, {}
        hdr = ''
        path = os.path.join(self.d, 'q7', 'dead_census.tsv')
        for line in _open(path):
            p = line.rstrip('\n').split('\t')
            if p[0] == '#kc-dead-census':
                hdr = line
            if p[0].isdigit() and len(p) == 9:
                rows.append(dict(k=int(p[0]), kill=p[1], c5=p[2], st=int(p[4]), pf=int(p[5]), c2b=int(p[6]), c5b=int(p[7])))
            elif p[0] == '#L':
                layers[int(p[1])] = dict(dead_st=int(p[2]), dead_pf=int(p[3]), live_pf=int(p[5]), fmass=int(p[6]),
                                         fresh=None if p[7] == '-' else int(p[7]))
            elif p[0] == '#range-kill':
                rng[p[1]] = (int(p[2].split('=')[1]), int(p[3].split('=')[1]))
        kills = ('C2', 'C5', 'MIXED', 'DEEP')
        tot = {k: [0, 0] for k in kills}
        per = defaultdict(lambda: [0, 0])
        for r in rows:
            tot[r['kill']][0] += r['st']
            tot[r['kill']][1] += r['pf']
            per[(r['k'], r['kill'])][0] += r['st']
            per[(r['k'], r['kill'])][1] += r['pf']
        ks = sorted(layers)
        self.tok('AF_Q7_LAYERS', '%d..%d' % (ks[0], ks[-1]) if ks else 'NONE')
        self.gate('Q7_ROWS_SUM_TO_THE_CENSUS_RANGE_TOTALS', bool(rows) and all(tuple(tot[k]) == rng.get(k) for k in kills))
        self.gate('Q7_ROWS_SUM_TO_EACH_LAYER_DEAD_TOTAL', all(
            sum(per[(k, kk)][0] for kk in kills) == layers[k]['dead_st'] and
            sum(per[(k, kk)][1] for kk in kills) == layers[k]['dead_pf'] for k in ks))
        self.gate('Q7_DEAD_PLUS_LIVE_EQ_FMASS_EVERY_LAYER', all(v['dead_pf'] + v['live_pf'] == v['fmass'] for v in layers.values()))
        byk = {r['k']: r for r in L}
        self.gate('Q7_LAYER_TOTALS_EQUAL_THE_ATLAS_COUNTS', bool(ks) and all(
            layers[k]['dead_st'] == byk[k]['counts']['st_dead'] and
            str(layers[k]['dead_pf']) == byk[k]['counts']['st_dead_fmass'] and
            str(layers[k]['live_pf']) == byk[k]['counts']['st_live_fmass'] for k in ks))
        gf = os.path.join(self.d, 'q7', 'dead_census_gfree.tsv')
        if _exists(gf):
            def cells(p, lo, hi):
                out = []
                for line in _open(p):
                    q = line.rstrip('\n').split('\t')
                    if (q[0].isdigit() and lo <= int(q[0]) < hi) or (q[0] == '#L' and lo <= int(q[1]) < hi):
                        out.append(tuple(q[:7]))
                return out
            glay = sorted(int(l.split('\t')[1]) for l in _open(gf) if l.startswith('#L\t'))
            lo, hi = glay[0], glay[-1] + 1
            a, b = cells(path, lo, hi), cells(gf, lo, hi)
            self.gate('Q7_GFREE_CENSUS_EQUALS_G_LADDER_CENSUS_CELL_FOR_CELL', bool(a) and a == b)
            self.tok('AF_Q7_GFREE_LAYERS', '%d..%d' % (lo, hi - 1))
        dead_all = sum(int(r['counts']['st_dead_fmass']) for r in L)
        dead_rng = sum(v['dead_pf'] for v in layers.values())
        self.tok('AF_Q7_DOOMED_PREFIXES_ALL_LAYERS_FROM_THE_ATLAS', dead_all)   # TR-12 12.2's DOOMED_PREFIX_NODES at n=31
        self.tok('AF_Q7_DOOMED_PREFIXES_IN_RANGE', dead_rng)
        self.tok('AF_Q7_RANGE_SHARE_OF_ALL_DOOMED_PREFIXES', '%.7f' % (Fraction(dead_rng, dead_all)) if dead_all else 'NA')
        st_all = sum(t[0] for t in tot.values())
        for kk in kills:
            self.tok('AF_Q7_KILL_%s' % kk, 'states=%d prefixes=%d share_of_dead_states=%.5f%% share_of_dead_prefixes=%.2f%%'
                     % (tot[kk][0], tot[kk][1], 100 * Fraction(tot[kk][0], st_all), 100 * Fraction(tot[kk][1], dead_rng)))
        term = sum(tot[kk][1] for kk in ('C2', 'C5', 'MIXED'))
        if term:
            self.tok('AF_Q7_TERMINAL_SHARE_C2_C5_MIXED', ','.join('%.2f%%' % (100 * Fraction(tot[kk][1], term)) for kk in ('C2', 'C5', 'MIXED')))
            self.tok('AF_Q7_TERMINAL_SHARE_WITH_A_C5_EXHAUSTED_CLASS_AMONG_BLOCKERS',
                     '%.2f%%' % (100 * Fraction(tot['C5'][1] + tot['MIXED'][1], term)))
            c2e = sum(r['c2b'] for r in rows if r['kill'] != 'DEEP')
            c5e = sum(r['c5b'] for r in rows if r['kill'] != 'DEEP')
            self.tok('AF_Q7_TERMINAL_BLOCKED_EDGES_C2_SHARE', '%.1f%%' % (100 * Fraction(c2e, c2e + c5e)))
            self.tok('AF_Q7_TERMINAL_SHARE_WITH_A_DISTANCE_5_STEP_AMONG_BLOCKERS',
                     '%.2f%%' % (100 * Fraction(tot['C2'][1] + tot['MIXED'][1], term)))
            tl = {k: sum(per[(k, kk)][1] for kk in ('C2', 'C5', 'MIXED')) for k in ks}
            self.tok('AF_Q7_TERMINAL_PREFIX_SHARE_BY_LAYER',
                     ','.join('%d:%.2f%%' % (k, 100 * Fraction(tl[k], term)) for k in ks))
            self.tok('AF_Q7_TERMINAL_C5_ONLY_SHARE_BY_LAYER',
                     ','.join('%d:%.2f%%' % (k, 100 * Fraction(per[(k, 'C5')][1], tl[k])) for k in ks if tl[k]))
        last = ks[-1] if ks else None
        if last is not None:
            self.tok('AF_Q7_DEEP_STATES_AT_LAST_LAYER', per[(last, 'DEEP')][0])
        fresh = {k: v['fresh'] for k, v in layers.items() if v['fresh'] is not None}
        if fresh and sum(fresh.values()):
            fs = sum(fresh.values())
            kmax = max(fresh, key=lambda k: fresh[k])
            self.tok('AF_Q7_FRESH_DEATHS_PEAK_LAYER', '%d (%.1f%% of the fresh deaths on layers %d..%d)'
                     % (kmax, 100 * Fraction(fresh[kmax], fs), min(fresh), max(fresh)))
        self.q7_header = hdr

    # ---- query 9
    def q9(self):
        n = self.n
        path = os.path.join(self.d, 'q9', 'witness_walks.tsv')
        hdr, rows = None, []
        for line in _open(path):
            p = line.rstrip('\n').split('\t')
            if p[0] == 'idx':
                hdr = p
            elif hdr and p[0].isdigit() and len(p) == len(hdr):
                rows.append(dict(zip(hdr, p)))
        self.tok('AF_Q9_WALKS', len(rows))
        self.gate('Q9_EVERY_ROW_REALISED_VALID_THROUGH_AND_F_G_W_OK', bool(rows) and all(
            all(r[c] == '1' for c in ('realised', 'valid', 'through', 'f_ok', 'g_ok', 'w_ok')) for r in rows))
        self.tok('AF_Q9_DISTINCT_WALKS', len({r['walk'] for r in rows}))
        self.tok('AF_Q9_DISTINCT_TRANSITIONS', len({(r['k'], r['cm'], r['lastc'], r['rid'], r['q'], r['o']) for r in rows}))
        self.tok('AF_Q9_EXTREMA_CELLS_WITH_NO_TRANSITION', n * 5 * 2 - len(rows))
        if n != 31:
            self.tok('AF_Q9_MEMBERSHIP_LEGS', 'SKIP:n=%d (the first-principles checker is the n=31 specification)' % n)
            return
        verify = _verify_module()
        kw, _, check = _checker(verify)
        bad = c15 = eq_kw = 0
        for r in rows:
            seq = [63, 0] + [int(x) for x in r['walk'].split(',')]
            try:
                check(seq, 'walk %s' % r['idx'])
            except AssertionError:
                bad += 1
                continue
            pos = {h: i for i, h in enumerate(seq)}
            if sum(abs(pos[h] - pos[h ^ 63]) for h in range(64)) <= 776:
                c15 += 1
            eq_kw += seq == kw
        self.tok('AF_Q9_WALKS_IN_SUPER_BY_FIRST_PRINCIPLES', '%d/%d' % (len(rows) - bad, len(rows)))
        self.gate('Q9_EVERY_WALK_IS_A_SUPER_MEMBER', bool(rows) and bad == 0)
        self.tok('AF_Q9_WALKS_ALSO_IN_C15', c15)
        self.tok('AF_Q9_WALKS_EQUAL_TO_KING_WEN', eq_kw)


def cmd_summary(args):
    d, atlas, walks, expect = None, DEFAULT_ATLAS, None, None
    while args:
        a = args.pop(0)
        if a == '--atlas' and args:
            atlas = args.pop(0)
        elif a == '--walks' and args:
            walks = args.pop(0)
        elif a == '--expect' and args:
            expect = args.pop(0)
        elif d is None and not a.startswith('--'):
            d = a
        else:
            print('AF_SUMMARY=FAIL:usage (unknown or incomplete argument %r)' % a)
            return 2
    if d is None or not os.path.isdir(d):
        print('AF_SUMMARY=FAIL:usage (summary DIR [--atlas ATLAS.json] [--walks q1b_walks.tsv] [--expect TOKENS.txt])')
        return 2
    s = Summary(d, atlas, walks)
    s.tok('AF_N', s.n)
    s.tok('AF_ATLAS_SHA256', hashlib.sha256(open(atlas, 'rb').read()).hexdigest())
    for name, fn in (('q8', s.q8), ('q1b', s.q1b), ('q7', s.q7), ('q9', s.q9)):
        try:
            fn()
        except (OSError, ValueError, KeyError, IndexError, ZeroDivisionError) as e:
            s.fails.append('%s:%s:%s' % (name, type(e).__name__, e))
    for line in s.lines:
        print(line)
    if expect:
        want = [l.rstrip('\n') for l in open(expect) if l.strip() and not l.startswith('#')]
        have = set(s.lines)
        missing = [l for l in want if l not in have]
        print('AF_EXPECTED_TOKENS=%d AF_EXPECTED_MISSING=%d' % (len(want), len(missing)))
        for l in missing[:10]:
            print('#missing: ' + l)
        if missing or not want:
            s.fails.append('expected_tokens_missing=%d' % len(missing))
    print('AF_SUMMARY=%s' % ('PASS' if not s.fails else 'FAIL:' + ';'.join(str(f) for f in s.fails[:8])))
    return 0 if not s.fails else 1


def main(argv):
    if len(argv) >= 2 and argv[0] == 'inputs':
        return cmd_inputs(argv[1])
    if argv and argv[0] == 'summary':
        return cmd_summary(list(argv[1:]))
    print('usage: atlas_followups.py inputs OUTDIR | summary DIR [--atlas A] [--walks W] [--expect T]')
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
