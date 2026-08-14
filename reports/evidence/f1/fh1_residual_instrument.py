"""
fh1_residual_instrument.py -- FH-1 step 1: C5-residual dominance instrumentation.

COPY-EXTENSION of f1_orbit_dp.py (exact-validated original left untouched, per
task instruction). Group construction and orbit-DP gather pattern are lifted
verbatim from it; the extension tracks C5 boundary-distance MULTISETS through
the DP instead of counts, in both directions:

  forward  P(mask,last)  = set of prefix boundary-distance multisets p <= B0
                           reaching (mask,last)          (RAW residual count)
  backward M(mask,last)  = set of completion boundary-distance multisets
                           from (mask,last) to the full mask (unbudgeted)

and reports, per layer, at each (canonical-mask, last):
  RAW        = |P|                       (what a naive C5-tracked DP stores)
  BOX-mask   = #residuals inside the mask-level usage box [min,max over M(c,*)]
  BOX-state  = #residuals inside the (c,last)-level usage box
  LIVE(gold) = |{B0 - p : p in P} intersect M|   (perfect dead-state pruning;
               proven-minimal storage for an exact forward DP, see
               FH1_RESIDUAL_DOMINANCE.md theory section)

Multisets are packed SWAR-style: 5 distance classes d in (1,2,3,4,6), 8 bits
each. Exactness cross-checks built in:
  V1: brute-force DFS (all admissible prefixes / memoized completions) vs the
      trivial-group instrument on a 7-pair subset -- set-level equality.
  V2: orbit-invariance: plain-instrument per-layer totals == orbit-size-
      weighted canonical totals on U1 (9 pairs), for RAW and LIVE.
  V3: B0 in M(0,start) and B0 in P(full,*).

Attribution: FH-1 direction, the residual-dominance conjecture and the capping
idea are the operator's (FOOTHOLDS.md); the sum-invariant analysis, live/dead
characterization and this implementation are Claude (Fable 5), 2026-07-04.
Correctness claims scoped to the instances validated below. Not committed
(operator instruction).
"""
import tempfile
import sys, itertools, time, pickle, os
import numpy as np
from collections import defaultdict

sys.path.insert(0, __import__('os').path.join(__import__('os').path.dirname(__file__), '..', '..', '..'))
import solve

KW = list(solve.binary_hexagrams)
PAIRS = [(KW[2 * i], KW[2 * i + 1]) for i in range(32)]
PAIRSETS = [frozenset(p) for p in PAIRS]
SET2PAIR = {s: i for i, s in enumerate(PAIRSETS)}

SPOOL = os.environ.get(
    "FH1_SPOOL",
    os.path.join(tempfile.gettempdir(), "fh1_spool"))
os.makedirs(SPOOL, exist_ok=True)


def d(a, b):
    return bin(a ^ b).count("1")


# --------- SWAR multiset packing: classes d=(1,2,3,4,6) -> bytes 0..4 -------
DCLASSES = (1, 2, 3, 4, 6)
DIDX = {1: 0, 2: 1, 3: 2, 4: 3, 6: 4}
DELTA = {dd: 1 << (8 * DIDX[dd]) for dd in DCLASSES}
HGUARD = sum(0x80 << (8 * i) for i in range(5))
FMASK = {dd: 0xFF << (8 * DIDX[dd]) for dd in DCLASSES}


def pack(vec):  # vec indexed by DIDX order
    return sum(v << (8 * i) for i, v in enumerate(vec))


def unpack(m):
    return tuple((m >> (8 * i)) & 0xFF for i in range(5))


def swar_le(a, b):
    """a <= b componentwise (all fields < 128)."""
    return ((b | HGUARD) - a) & HGUARD == HGUARD


def box_of(mset):
    """(componentwise min, componentwise max) over a set of packed multisets."""
    mn = mx = 0
    for i in range(5):
        sh = 8 * i
        vals = [(m >> sh) & 0xFF for m in mset]
        mn |= min(vals) << sh
        mx |= max(vals) << sh
    return mn, mx


# ------------------------- group (verbatim from f1_orbit_dp.py) -------------
REV = (5, 4, 3, 2, 1, 0)


def compose(a, b):
    return tuple(a[b[i]] for i in range(6))


def hex_act(perm, h):
    r = 0
    for i in range(6):
        r |= ((h >> i) & 1) << perm[i]
    return r


G48 = [p for p in itertools.permutations(range(6))
       if compose(p, REV) == compose(REV, p)]
assert len(G48) == 48


def pair_perm(g):
    return tuple(SET2PAIR[frozenset(hex_act(g, h) for h in PAIRSETS[p])]
                 for p in range(32))


coset = {}
for g in sorted(G48):
    coset.setdefault(pair_perm(g), []).append(g)
assert len(coset) == 24 and all(len(v) == 2 for v in coset.values())
G24 = [(pp, lifts[0]) for pp, lifts in sorted(coset.items())]

parent = list(range(32))


def _find(x):
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x


for pp, _ in G24:
    for i in range(32):
        a, b = _find(i), _find(pp[i])
        if a != b:
            parent[a] = b
_orb = defaultdict(list)
for i in range(1, 32):
    _orb[_find(i)].append(i)
PAIR_ORBITS = sorted(_orb.values(), key=lambda o: (len(o), o))


# --------------------------------------------------------------- instrument
class Instrument:
    def __init__(self, pair_indices, start_exit, group=True, tag=""):
        self.pl = list(pair_indices)
        self.n = len(self.pl)
        self.start = start_exit
        self.tag = tag
        pos = {p: i for i, p in enumerate(self.pl)}
        # restricted group elements: (index-perm, hexmap, inv-hexmap)
        self.elems = []
        if group:
            for pp, lift in G24:
                assert all(pp[p] in pos for p in self.pl), "union not closed"
                iperm = tuple(pos[pp[p]] for p in self.pl)
                hmap = tuple(hex_act(lift, h) for h in range(64))
                inv = [0] * 64
                for h in range(64):
                    inv[hmap[h]] = h
                self.elems.append((iperm, hmap, tuple(inv)))
        else:
            ident = tuple(range(self.n))
            hm = tuple(range(64))
            self.elems = [(ident, hm, hm)]
        self.n_eff = len({e[0] for e in self.elems})
        # half-table mask application (n <= 22 -> two 11-bit halves)
        self.h1 = (self.n + 1) // 2
        self.tbls = []
        for iperm, hmap, inv in self.elems:
            lo = [0] * (1 << self.h1)
            hi = [0] * (1 << (self.n - self.h1))
            for m in range(1 << self.h1):
                v = 0
                for i in range(self.h1):
                    if m >> i & 1:
                        v |= 1 << iperm[i]
                lo[m] = v
            for m in range(1 << (self.n - self.h1)):
                v = 0
                for i in range(self.n - self.h1):
                    if m >> i & 1:
                        v |= 1 << iperm[self.h1 + i]
                hi[m] = v
            self.tbls.append((lo, hi, hmap, inv, iperm))
        self.canon_cache = {}
        # trans[i][o] = (entry f, exit s)
        self.trans = [[(PAIRS[p][o ^ 1], PAIRS[p][o]) for o in (0, 1)]
                      for p in self.pl]
        self.full = (1 << self.n) - 1
        self.hmask = (1 << self.h1) - 1
        self._bpaths = None
        self._tbk = 0.0

    def canonical(self, mask):
        hit = self.canon_cache.get(mask)
        if hit is not None:
            return hit
        lo, hi = mask & self.hmask, mask >> self.h1
        best, bt = None, None
        for t in self.tbls:
            m = t[0][lo] | t[1][hi]
            if best is None or m < best:
                best, bt = m, t
        self.canon_cache[mask] = (best, bt)
        return best, bt

    def stab_order(self, cmask):
        lo, hi = cmask & self.hmask, cmask >> self.h1
        return len({t[4] for t in self.tbls if t[0][lo] | t[1][hi] == cmask})

    # ---------------- B0: boundary multiset of the first valid completion
    def find_b0(self, seed=None):
        """Boundary multiset of one valid completion (randomized DFS if
        seed is not None). Any returned B0 is achievable by construction."""
        import random
        rng = random.Random(seed) if seed is not None else None
        n = self.n

        def dfs(mask, last, acc):
            if mask == self.full:
                return acc
            order = list(range(n))
            if rng:
                rng.shuffle(order)
            for i in order:
                if mask >> i & 1:
                    continue
                oo = (0, 1) if not rng or rng.random() < .5 else (1, 0)
                for o in oo:
                    f, s = self.trans[i][o]
                    dd = d(last, f)
                    if dd == 5:
                        continue
                    r = dfs(mask | 1 << i, s, acc + (dd,))
                    if r is not None:
                        return r
            return None

        seq = dfs(0, self.start, ())
        assert seq is not None, "no valid completion exists"
        vec = [0] * 5
        for dd in seq:
            vec[DIDX[dd]] += 1
        return pack(vec)

    # ------------------------------------------------ backward pass (M sets)
    def backward(self):
        """Spool per-layer {c: {last: (frozenset M, bmin, bmax)}} +
        mask-level boxes {c: (bmin,bmax)} to disk. Returns paths."""
        n = self.n
        paths = {}
        # layer n: full mask (canonical: min over group of full = full)
        z = np.zeros(1, dtype=np.int64)
        cur = {self.full: {l: z for l in self._members(self.full)}}
        paths[n] = self._spool(
            n, {self.full: {l: (z, 0, 0) for l in self._members(self.full)}})
        for k in range(n - 1, -1, -1):
            # canonical masks at layer k: remove bits from layer k+1 canonicals
            targets = set()
            for c in cur:
                m = c
                while m:
                    b = m & -m
                    m ^= b
                    targets.add(self.canonical(c ^ b)[0])
            nxt = {}
            for c in targets:
                lasts = self._members(c) if k else [self.start]
                free = [i for i in range(n) if not c >> i & 1]
                # per-last lists of pre-shifted child M-arrays; the shift
                # ms+DELTA[dd] is computed ONCE per (i,o,dd) and shared
                # across all lasts in the same distance class.
                acc = {l: [] for l in lasts}
                for i in free:
                    cm, t = self.canonical(c | 1 << i)
                    row = cur.get(cm)
                    if row is None:
                        continue
                    hmap = t[2]
                    for o in (0, 1):
                        f, s = self.trans[i][o]
                        ms = row.get(hmap[s])
                        if ms is None:
                            continue
                        shifted = {}
                        for l in lasts:
                            dd = d(l, f)
                            if dd == 5:
                                continue
                            sh = shifted.get(dd)
                            if sh is None:
                                sh = ms + DELTA[dd]
                                shifted[dd] = sh
                            acc[l].append(sh)
                per = {}
                for l, lists in acc.items():
                    if lists:
                        u = (np.unique(np.concatenate(lists))
                             if len(lists) > 1 else lists[0])
                        mn = mx = 0
                        for fi in range(5):
                            fv = (u >> (8 * fi)) & 0xFF
                            mn |= int(fv.min()) << (8 * fi)
                            mx |= int(fv.max()) << (8 * fi)
                        per[l] = (u, mn, mx)
                if per:
                    nxt[c] = per
            cur = {c: {l: v[0] for l, v in per.items()}
                   for c, per in nxt.items()}
            paths[k] = self._spool(k, nxt)
        return paths

    def _members(self, cmask):
        out = []
        m = cmask
        while m:
            b = m & -m
            i = b.bit_length() - 1
            m ^= b
            out.extend(PAIRS[self.pl[i]])
        return out

    def _spool(self, k, obj):
        p = os.path.join(SPOOL, f"{self.tag}_bk_{k}.pkl")
        with open(p, "wb") as fh:
            pickle.dump(obj, fh, protocol=4)
        return p

    # ------------------------------------------------- forward pass + metrics
    def run(self, b0):
        t0 = time.time()
        if self._bpaths is None:
            self._bpaths = self.backward()
            self._tbk = time.time() - t0
        bpaths = self._bpaths
        tb = time.time()
        n = self.n
        b0g = b0 | HGUARD
        stats = []
        layer = {0: {self.start: frozenset([0])}}
        for k in range(n + 1):
            # ---- metrics for layer k against backward layer k
            with open(bpaths[k], "rb") as fh:
                bk = pickle.load(fh)
            row_states = row_raw = row_bm = row_bs = row_live = 0
            max_live = 0
            wraw = wlive = 0  # orbit-size-weighted (for invariance checks)
            HG = np.int64(HGUARD)

            def inbox(rs, bmin, bmax):
                ok = (((rs | HG) - bmin) & HG == HG) \
                    & (((np.int64(bmax) | HG) - rs) & HG == HG)
                return int(ok.sum())

            for c, per in layer.items():
                osz = self.n_eff // self.stab_order(c)
                bper = bk.get(c, {})
                # mask-level box over all lasts of c
                if bper:
                    mns, mxs = zip(*[(v[1], v[2]) for v in bper.values()])
                    mbmin = pack([min((x >> (8 * i)) & 0xFF for x in mns)
                                  for i in range(5)])
                    mbmax = pack([max((x >> (8 * i)) & 0xFF for x in mxs)
                                  for i in range(5)])
                for l, ps in per.items():
                    row_states += 1
                    raw = len(ps)
                    row_raw += raw
                    wraw += osz * raw
                    ent = bper.get(l)
                    rs = b0 - np.fromiter(ps, np.int64, raw)
                    if ent is None:
                        live = bs = 0
                        bm = inbox(rs, mbmin, mbmax) if bper else 0
                    else:
                        ms, bmin, bmax = ent
                        idx = np.searchsorted(ms, rs)
                        idx[idx == len(ms)] = 0
                        live = int((ms[idx] == rs).sum())
                        bs = inbox(rs, bmin, bmax)
                        bm = inbox(rs, mbmin, mbmax)
                    row_bs += bs
                    row_bm += bm
                    row_live += live
                    wlive += osz * live
                    if live > max_live:
                        max_live = live
            stats.append(dict(k=k, states=row_states, raw=row_raw,
                              boxmask=row_bm, boxstate=row_bs, live=row_live,
                              maxlive=max_live, wraw=wraw, wlive=wlive))
            if k == n:
                break
            # ---- gather next forward layer
            targets = set()
            for c in layer:
                for i in range(n):
                    if not c >> i & 1:
                        targets.add(self.canonical(c | 1 << i)[0])
            nxt = {}
            for tm in targets:
                acc = defaultdict(set)
                m = tm
                while m:
                    b = m & -m
                    i = b.bit_length() - 1
                    m ^= b
                    cp, te = self.canonical(tm ^ b)
                    per = layer.get(cp)
                    if not per:
                        continue
                    inv = te[3]
                    for lst, ps in per.items():
                        lraw = inv[lst]
                        for o in (0, 1):
                            f, s = self.trans[i][o]
                            dd = d(lraw, f)
                            if dd == 5:
                                continue
                            dl, fm = DELTA[dd], FMASK[dd]
                            cap = b0 & fm
                            acc[s].update(p + dl for p in ps
                                          if p & fm != cap)
                    # (p & fm != cap) <=> p_dd < B0_dd since p <= B0: exact
                    # budget-kill, so P holds prefixes admissible under B0.
                nxt[tm] = {l: frozenset(v) for l, v in acc.items() if v}
            layer = {c: per for c, per in nxt.items() if per}
        tf = time.time()
        return stats, self._tbk, tf - tb


def v_per_layer(b0, n):
    """max over s of #vectors <= b0 with sum s (theoretical residuals/layer)."""
    bv = unpack(b0)
    cnt = defaultdict(int)
    cnt[0] = 1
    for i in range(5):
        new = defaultdict(int)
        for s, c in cnt.items():
            for v in range(bv[i] + 1):
                new[s + v] += c
        cnt = new
    return max(cnt.values()), cnt


# --------------------------------------------------------------- validation
def brute_reference(pair_indices, start_exit, b0):
    """All-prefix DFS (P) + memoized completion multisets (M); raw states."""
    n = len(pair_indices)
    pl = list(pair_indices)
    trans = [[(PAIRS[p][o ^ 1], PAIRS[p][o]) for o in (0, 1)] for p in pl]
    P = defaultdict(set)
    P[(0, start_exit)].add(0)
    stack = [(0, start_exit, 0)]
    while stack:
        mask, last, p = stack.pop()
        for i in range(n):
            if mask >> i & 1:
                continue
            for o in (0, 1):
                f, s = trans[i][o]
                dd = d(last, f)
                if dd == 5:
                    continue
                fm = FMASK[dd]
                if p & fm == b0 & fm:
                    continue  # budget kill
                q = p + DELTA[dd]
                key = (mask | 1 << i, s)
                if q not in P[key]:
                    P[key].add(q)
                    stack.append((key[0], key[1], q))
    from functools import lru_cache
    full = (1 << n) - 1

    @lru_cache(maxsize=None)
    def M(mask, last):
        if mask == full:
            return frozenset([0])
        acc = set()
        for i in range(n):
            if mask >> i & 1:
                continue
            for o in (0, 1):
                f, s = trans[i][o]
                dd = d(last, f)
                if dd == 5:
                    continue
                acc.update(m + DELTA[dd] for m in M(mask | 1 << i, s))
        return frozenset(acc)

    per_layer = defaultdict(lambda: [0, 0, 0])  # states, raw, live
    for (mask, last), ps in P.items():
        k = bin(mask).count("1")
        ms = M(mask, last)
        live = sum(1 for p in ps if (b0 - p) in ms)
        per_layer[k][0] += 1
        per_layer[k][1] += len(ps)
        per_layer[k][2] += live
    return dict(per_layer)


def report(name, stats, vpeak):
    print(f"\n[{name}] per-layer: k states raw box-mask box-state live(gold) "
          f"raw/live maxlive")
    peak = max(stats, key=lambda r: r["live"])
    for r in stats:
        ratio = (r["raw"] / r["live"]) if r["live"] else float("inf")
        print(f"  k={r['k']:>2} {r['states']:>8} {r['raw']:>10} "
              f"{r['boxmask']:>10} {r['boxstate']:>10} {r['live']:>10} "
              f"{ratio:>7.2f} {r['maxlive']:>5}")
    eff = peak["live"] / peak["states"] if peak["states"] else 0
    rpeak = max(stats, key=lambda r: r["raw"])
    reff = rpeak["raw"] / rpeak["states"]
    print(f"  PEAK live layer k={peak['k']}: live/state avg={eff:.2f} "
          f"max={peak['maxlive']}  V_layer(theory)={vpeak}  "
          f"live-fraction avg/V={eff / vpeak:.4f} max/V={peak['maxlive'] / vpeak:.4f}")
    print(f"  PEAK raw layer k={rpeak['k']}: raw/state avg={reff:.2f} "
          f"raw-fraction avg/V={reff / vpeak:.4f}; "
          f"box-state/state={rpeak['boxstate'] / rpeak['states']:.2f} "
          f"(fraction of V={rpeak['boxstate'] / rpeak['states'] / vpeak:.4f})")
    tot_raw = sum(r["raw"] for r in stats)
    tot_live = sum(r["live"] for r in stats)
    tot_bs = sum(r["boxstate"] for r in stats)
    tot_bm = sum(r["boxmask"] for r in stats)
    print(f"  TOTALS raw={tot_raw} box-mask={tot_bm} box-state={tot_bs} "
          f"live={tot_live}; collapse raw/box-state={tot_raw / max(tot_bs, 1):.2f}x "
          f"raw/live={tot_raw / max(tot_live, 1):.2f}x")
    return peak


if __name__ == "__main__":
    by_size = defaultdict(list)
    for o in PAIR_ORBITS:
        by_size[len(o)].append(o)

    # ---- V1: brute-force cross-check, 7 arbitrary pairs, trivial group
    sub7 = [1, 4, 5, 8, 9, 21, 24]
    inst = Instrument(sub7, 0, group=False, tag="v1")
    b0 = inst.find_b0()
    stats, tbk, tfw = inst.run(b0)
    ref = brute_reference(sub7, 0, b0)
    ok = all(ref.get(r["k"], [0, 0, 0]) == [r["states"], r["raw"], r["live"]]
             for r in stats)
    print(f"[V1] brute-force vs instrument (7 pairs, trivial group, "
          f"B0={unpack(b0)}): {'PASS' if ok else 'FAIL'}")
    assert ok

    # ---- V2: orbit invariance on U1 (9 pairs): weighted == plain
    U1 = by_size[3][0] + by_size[3][1] + by_size[3][2]
    ip = Instrument(U1, 0, group=False, tag="v2p")
    b0 = ip.find_b0()
    sp, _, _ = ip.run(b0)
    io = Instrument(U1, 0, group=True, tag="v2o")
    so, _, _ = io.run(b0)
    ok = all(a["raw"] == b["wraw"] and a["live"] == b["wlive"]
             for a, b in zip(sp, so))
    print(f"[V2] orbit-invariance U1 (9 pairs, B0={unpack(b0)}): "
          f"{'PASS' if ok else 'FAIL'} "
          f"(plain raw/live == orbit-weighted raw/live, all layers)")
    assert ok

    # ---- main instrumented runs (group-closed unions)
    RUNS = {
        "13": ("U13 (3+4+6)", by_size[3][0] + by_size[4][0] + by_size[6][2], 0),
        "16": ("U16 (4+6+6)", by_size[4][0] + by_size[6][0] + by_size[6][1], 0),
        "18": ("U18 (6+6+6)", by_size[6][0] + by_size[6][1] + by_size[6][2], 0),
        "19": ("U19 (3+4+6+6)",
               by_size[3][0] + by_size[4][0] + by_size[6][0] + by_size[6][1], 0),
    }
    wanted = sys.argv[1:] or ["16", "18"]
    for name, union, start in [RUNS[w] for w in wanted]:
        t0 = time.time()
        inst = Instrument(union, start, group=True, tag=name.split()[0])
        # B0 sweep: dedupe budgets from randomized valid completions,
        # keep the min-V / median-V / max-V representatives.
        cands = {inst.find_b0()}
        for seed in range(24):
            cands.add(inst.find_b0(seed))
        ranked = sorted(cands, key=lambda b: v_per_layer(b, inst.n)[0])
        chosen = sorted({ranked[0], ranked[len(ranked) // 2], ranked[-1]},
                        key=lambda b: v_per_layer(b, inst.n)[0])
        print(f"\n=== {name}: n={inst.n}; {len(cands)} distinct achievable "
              f"B0 sampled, V_peak range "
              f"{v_per_layer(ranked[0], inst.n)[0]}"
              f"..{v_per_layer(ranked[-1], inst.n)[0]} ===")
        for b0 in chosen:
            vpeak, _ = v_per_layer(b0, inst.n)
            stats, tbk, tfw = inst.run(b0)
            assert stats[0]["live"] >= 1, "B0 not completable from start"
            assert stats[-1]["live"] >= 1, "B0 not reached at full mask"
            print(f"\n--- {name} B0={unpack(b0)} V_peak={vpeak} "
                  f"(backward {tbk:.1f}s reused; forward+metrics {tfw:.1f}s) ---")
            report(f"{name} B0={unpack(b0)}", stats, vpeak)
        print(f"[{name}] total wall {time.time() - t0:.1f}s")
