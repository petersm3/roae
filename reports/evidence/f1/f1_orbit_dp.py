"""
f1_orbit_dp.py -- S4-orbit-quotient DP prototype for the F1 exact-count route (#215).

Plan + equivariance argument: roae-private/F1_ORBIT_QUOTIENT_2026_07.md
Validated plain DP it must reproduce: F1_PHASE3_RECONSTRUCTION.md / f1_phase3.py
Group source: roae/documentation/SYMMETRY_SEARCH.md (TR-5): the 48 bit-position
permutations commuting with rev = (0 5)(1 4)(2 3), i.e. C_{S6}(rev) ~= B3;
record/pair level group is B3/{+-I} ~= S4 (order 24), pair 0 (Qian,Kun) fixed.

What this script does:
 1. Constructs G48 and verifies: Hamming-isometry (all 64x64), maps the 32-pair
    set to itself, fixes pair 0 setwise, quotient to 24 distinct pair-perms
    (kernel {id, rev}), group closure of the 24.
 2. Builds the action on the 31 free pairs and on hexagrams (per coset lift).
 3. Orbit-DP, layered over mask popcount, storing only canonical masks
    (min image over the 24 pair-perms), values per `last` exit hexagram.
    GATHER formulation: F(n,last) at a canonical mask n is pulled from the
    canonicalized predecessors, so stored values are the EXACT plain-DP forward
    values f(mask,last) at the representative -- no weighting inside values.
    Stabilizer weights (orbit size = 24/|stab|) enter exactly where they must:
    the per-layer total-mass identity  sum_c orbit_size(c)*sum_l F(c,l)
    == plain-DP layer mass, asserted layer by layer; and the final total,
    where the full mask is G-fixed (orbit size 1) so N = sum_l F(full,l)
    equals the plain count with no correction.
 4. Validates on 3 group-CLOSED unions of pair-orbits (arbitrary subsets are
    NOT closed; the 31 free pairs split into orbits of sizes 3,3,3,4,6,6,6):
    plain phase-3 DP (verbatim recursion) vs orbit-DP, exact big-int equality,
    plus layer-by-layer mass equality vs a plain layered forward DP.
 5. Reports the measured orbit-collapse factor and the EXACT full-31-pair
    canonical-mask counts per layer (Burnside on k-subsets from cycle types),
    extrapolating full-run memory.

Attribution: direction and the orbit-quotient idea are the operator's
(F1_ORBIT_QUOTIENT_2026_07.md); implementation by Claude (Fable 5), 2026-07-04.
Correctness claims here are scoped to the instances validated below.
Not committed (operator instruction).
"""
import sys, itertools, time
from collections import defaultdict

sys.path.insert(0, __import__('os').path.join(__import__('os').path.dirname(__file__), '..', '..', '..'))
import solve

KW = list(solve.binary_hexagrams)
PAIRS = [(KW[2 * i], KW[2 * i + 1]) for i in range(32)]
PAIRSETS = [frozenset(p) for p in PAIRS]
SET2PAIR = {s: i for i, s in enumerate(PAIRSETS)}


def d(a, b):
    return bin(a ^ b).count("1")


# ---------------------------------------------------------------- 1. group
REV = (5, 4, 3, 2, 1, 0)  # bit-reversal as a position permutation


def compose(a, b):
    """Permutation composition: (a o b)[i] = a[b[i]] (apply b, then a)."""
    return tuple(a[b[i]] for i in range(6))


def hex_act(perm, h):
    """Bit i of h moves to bit position perm[i]."""
    r = 0
    for i in range(6):
        r |= ((h >> i) & 1) << perm[i]
    return r


G48 = [p for p in itertools.permutations(range(6))
       if compose(p, REV) == compose(REV, p)]
assert len(G48) == 48, "centralizer of rev in S6 must have order 48"

# per-element verification (task requirement 1)
for g in G48:
    himg = [hex_act(g, h) for h in range(64)]
    # Hamming isometry, all 64x64 (implies C2/C5-compatibility of the action)
    assert all(d(himg[a], himg[b]) == d(a, b)
               for a in range(64) for b in range(64)), f"{g}: not an isometry"
    # maps the 32-pair set to itself
    imgsets = {frozenset(himg[h] for h in s) for s in PAIRSETS}
    assert imgsets == set(PAIRSETS), f"{g}: does not permute the 32 pairs"
    # fixes pair 0 = {Qian=63, Kun=0} setwise (bit perms fix 0 and 63)
    assert {himg[63], himg[0]} == {63, 0}, f"{g}: moves pair 0"
    # commutes with rev at hexagram level too (definition check)
    assert all(hex_act(REV, himg[h]) == hex_act(g, hex_act(REV, h))
               for h in range(64)), f"{g}: rev-commutation fails on hexagrams"

# ------------------------------------------------- 2. action on pairs / quotient
def pair_perm(g):
    return tuple(SET2PAIR[frozenset(hex_act(g, h) for h in PAIRSETS[p])]
                 for p in range(32))


coset = {}  # pair-perm -> list of hexagram-level lifts
for g in sorted(G48):
    coset.setdefault(pair_perm(g), []).append(g)
assert len(coset) == 24, "record-level group must be S4 (order 24)"
assert all(len(v) == 2 for v in coset.values()), "kernel must be {+-I} (2 lifts)"
assert all(pp[0] == 0 for pp in coset)  # pair 0 fixed
# the two lifts of the identity coset are {id, rev}
idc = coset[tuple(range(32))]
assert set(idc) == {tuple(range(6)), REV}

# 24 group elements: (pair-perm on 32 pairs, one deterministic hexagram lift)
G24 = [(pp, lifts[0]) for pp, lifts in sorted(coset.items())]
# closure check: the 24 pair-perms form a group
pp_set = {pp for pp, _ in G24}
for a in pp_set:
    for b in pp_set:
        assert tuple(a[b[i]] for i in range(32)) in pp_set, "closure fails"
print(f"[group] G48 verified elementwise; quotient = 24 pair-perms, "
      f"closed under composition; pair 0 fixed setwise by all.")

# pair-orbits of the 31 free pairs
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
print(f"[group] pair-orbits of the 31 free pairs: "
      f"{[(len(o), o) for o in PAIR_ORBITS]}")


# ------------------------------------------- plain reference DPs (ground truth)
def plain_count(pair_indices, start_exit=0):
    """Verbatim recursion from f1_phase3.py::count (lru_cache rec(mask,last))."""
    from functools import lru_cache
    n = len(pair_indices)
    pl = list(pair_indices)

    @lru_cache(maxsize=None)
    def rec(mask, last):
        if mask == (1 << n) - 1:
            return 1
        t = 0
        for i, p in enumerate(pl):
            if mask >> i & 1:
                continue
            for o in (0, 1):
                f = PAIRS[p][1] if o else PAIRS[p][0]
                s = PAIRS[p][0] if o else PAIRS[p][1]
                if d(last, f) == 5:
                    continue
                t += rec(mask | 1 << i, s)
        return t

    v = rec(0, start_exit)
    rec.cache_clear()
    return v


def plain_layered_forward(pair_indices, start_exit=0):
    """Plain forward DP; returns (total, [layer mass per popcount k])."""
    n = len(pair_indices)
    pl = list(pair_indices)
    trans = [[(PAIRS[p][o ^ 1], PAIRS[p][o]) for o in (0, 1)] for p in pl]
    # trans[i][o] = (entry f, exit s): o=0 -> (KW[2p],KW[2p+1]) received order
    layer = {(0, start_exit): 1}
    masses = [sum(layer.values())]
    for _k in range(n):
        nxt = defaultdict(int)
        for (mask, last), v in layer.items():
            for i in range(n):
                if mask >> i & 1:
                    continue
                for f, s in trans[i]:
                    if d(last, f) != 5:
                        nxt[(mask | 1 << i, s)] += v
        layer = dict(nxt)
        masses.append(sum(layer.values()))
    return sum(layer.values()), masses


# ------------------------------------------------------------- 3. orbit-DP
def orbit_dp(pair_indices, start_exit=0):
    """
    S4-orbit-quotient layered DP over a group-CLOSED pair subset.
    Returns (total, layer_masses, layer_stats) where layer_stats[k] =
    (n_canonical_masks, n_total_masks=C(n,k), n_value_entries).
    Exactness: stored F(c,last) == plain forward f(c,last) at the canonical
    representative c, by induction via the gather step (see module docstring).
    """
    n = len(pair_indices)
    pl = list(pair_indices)
    pos = {p: i for i, p in enumerate(pl)}
    assert start_exit in (0, 63), "start_exit must be G-fixed (Kun or Qian)"

    # restrict each group element to the subset: index-perm + hexagram maps
    elems = []
    seen = set()
    for pp, lift in G24:
        assert all(pp[p] in pos for p in pl), \
            "pair_indices not closed under the group action"
        iperm = tuple(pos[pp[p]] for p in pl)          # subset-index perm
        hmap = tuple(hex_act(lift, h) for h in range(64))
        inv = [0] * 64
        for h in range(64):
            inv[hmap[h]] = h
        elems.append((iperm, hmap, tuple(inv)))
        seen.add(iperm)
    n_eff = len(seen)  # faithful size of the restricted index-perm action

    def apply_mask(iperm, mask):
        m = 0
        i = 0
        while mask >> i:
            if mask >> i & 1:
                m |= 1 << iperm[i]
            i += 1
        return m

    canon_cache = {}

    def canonical(mask):
        """(canonical mask, one group element g with g*mask == canonical)."""
        hit = canon_cache.get(mask)
        if hit is not None:
            return hit
        best, bg = mask, elems[0]
        for e in elems:
            m = apply_mask(e[0], mask)
            if m < best:
                best, bg = m, e
        canon_cache[mask] = (best, bg)
        return best, bg

    def stab_order(cmask):
        """|stab| within the faithful restricted index-perm group (n_eff)."""
        return len({e[0] for e in elems if apply_mask(e[0], cmask) == cmask})

    trans = [[(PAIRS[p][o ^ 1], PAIRS[p][o]) for o in (0, 1)] for p in pl]

    from math import comb
    full = (1 << n) - 1
    layer = {0: {start_exit: 1}}                       # cmask -> {last: value}
    masses = [1]
    stats = [(1, 1, 1)]
    for k in range(n):
        # enumerate canonical masks of layer k+1 by pushing bits (targets only)
        targets = set()
        for c in layer:
            for i in range(n):
                if not c >> i & 1:
                    targets.add(canonical(c | 1 << i)[0])
        nxt = {}
        for tmask in targets:
            acc = defaultdict(int)
            for i in range(n):
                if not tmask >> i & 1:
                    continue
                pred = tmask ^ (1 << i)
                cpred, g = canonical(pred)
                vals = layer.get(cpred)
                if not vals:
                    continue
                ginv_hex = g[2]  # inverse hexagram map: stored key -> raw last
                for lstored, v in vals.items():
                    last_prev = ginv_hex[lstored]
                    for f, s in trans[i]:
                        if d(last_prev, f) != 5:
                            acc[s] += v
            if acc:
                nxt[tmask] = dict(acc)
        layer = nxt
        # stabilizer-weighted layer mass (orbit size = 24/|stab|, restricted:
        # n_eff/|stab| under the faithful restricted action)
        mass = 0
        entries = 0
        for c, vals in layer.items():
            osz = n_eff // stab_order(c)   # orbit size, faithful restricted grp
            mass += osz * sum(vals.values())
            entries += len(vals)
        masses.append(mass)
        stats.append((len(layer), comb(n, k + 1), entries))
    total = sum(sum(v.values()) for c, v in layer.items())
    assert list(layer.keys()) in ([full], []), "final layer must be the full mask"
    return total, masses, stats


# ------------------------------------------------------------- 4. validation
def validate(name, pair_indices, start_exit):
    t0 = time.time()
    ref = plain_count(pair_indices, start_exit)
    t1 = time.time()
    ptotal, pmasses = plain_layered_forward(pair_indices, start_exit)
    t2 = time.time()
    ototal, omasses, ostats = orbit_dp(pair_indices, start_exit)
    t3 = time.time()
    ok_total = (ref == ptotal == ototal)
    ok_layers = (pmasses == omasses)
    print(f"\n[validate] {name}: pairs={sorted(pair_indices)} "
          f"start_exit={start_exit}")
    print(f"  phase-3 rec (verbatim) = {ref}   [{t1-t0:.1f}s]")
    print(f"  plain layered forward  = {ptotal}   [{t2-t1:.1f}s]")
    print(f"  orbit-quotient DP      = {ototal}   [{t3-t2:.1f}s]")
    print(f"  totals match exactly: {'PASS' if ok_total else 'FAIL'}; "
          f"layer-by-layer mass equality: {'PASS' if ok_layers else 'FAIL'}")
    n = len(pair_indices)
    mid = [(k, s[0], s[1], s[1] / s[0]) for k, s in enumerate(ostats)
           if 2 <= k <= n - 2]
    peak = max(mid, key=lambda r: r[2])
    print(f"  collapse at peak layer k={peak[0]}: {peak[1]} canonical / "
          f"{peak[2]} total masks = factor {peak[3]:.2f}x")
    tot_canon = sum(s[0] for s in ostats)
    tot_masks = sum(s[1] for s in ostats)
    print(f"  whole-run masks: {tot_canon} canonical / {tot_masks} total "
          f"= factor {tot_masks/tot_canon:.2f}x")
    return ok_total and ok_layers, ostats


# ----------------------------------- 5. exact full-run sizing via Burnside
def full_run_extrapolation():
    """Exact canonical-mask counts per layer for the FULL 31-pair action:
    #orbits of k-subsets = (1/24) sum_g #k-subsets fixed by g, from cycle
    types of each pair-perm restricted to pairs 1..31 (Burnside; exact)."""
    from math import comb
    polys = []
    for pp, _ in G24:
        # cycle lengths of pp on {1..31}
        seen = set()
        lens = []
        for s in range(1, 32):
            if s in seen:
                continue
            c, x = 0, s
            while True:
                seen.add(x)
                c += 1
                x = pp[x]
                if x == s:
                    break
            lens.append(c)
        poly = [1]  # generating function prod (1 + x^len)
        for L in lens:
            new = poly + [0] * L
            for i, v in enumerate(poly):
                new[i + L] += v
            poly = new
        poly += [0] * (32 - len(poly))
        polys.append(poly)
    assert all(sum(p[k] for p in polys) % 24 == 0 for k in range(32)), \
        "Burnside fixed-subset sums must be divisible by |G|=24"
    orbit_counts = [sum(p[k] for p in polys) // 24 for k in range(32)]
    total_masks = [comb(31, k) for k in range(32)]
    print("\n[full-run extrapolation] exact canonical-mask counts (Burnside):")
    print(f"  total masks 2^31 = {sum(total_masks)}; canonical = "
          f"{sum(orbit_counts)}; overall collapse = "
          f"{sum(total_masks)/sum(orbit_counts):.3f}x")
    # value entries: mask with k pairs admits 2k last values (k>=1), 1 at k=0
    ent_can = 1 + sum(orbit_counts[k] * 2 * k for k in range(1, 32))
    ent_all = 1 + sum(total_masks[k] * 2 * k for k in range(1, 32))
    peak_k = max(range(1, 31), key=lambda k: orbit_counts[k] * 2 * k
                 + orbit_counts[k + 1] * 2 * (k + 1))
    peak_entries = (orbit_counts[peak_k] * 2 * peak_k
                    + orbit_counts[peak_k + 1] * 2 * (peak_k + 1))
    plain_peak = (total_masks[peak_k] * 2 * peak_k
                  + total_masks[peak_k + 1] * 2 * (peak_k + 1))
    print(f"  state entries: {ent_all:.3e} plain -> {ent_can:.3e} canonical "
          f"({ent_all/ent_can:.2f}x)")
    print(f"  peak two-live-layers k={peak_k},{peak_k+1}: {plain_peak:.3e} -> "
          f"{peak_entries:.3e} entries")
    for label, bytes_per in (("24 B/value (~150-bit ints, single pass)", 24),
                             ("8 B/value (3x 64-bit CRT passes)", 8)):
        gb = peak_entries * bytes_per / 1e9
        pgb = plain_peak * bytes_per / 1e9
        print(f"    @{label}: {pgb:.0f} GB plain -> {gb:.1f} GB quotient")
    return orbit_counts


if __name__ == "__main__":
    O = {tuple(o): o for o in PAIR_ORBITS}
    orbs = PAIR_ORBITS  # sizes 3,3,3,4,6,6,6
    by_size = defaultdict(list)
    for o in orbs:
        by_size[len(o)].append(o)
    # three group-closed unions of pair-orbits, 9 / 12 / 13 pairs
    U1 = by_size[3][0] + by_size[3][1] + by_size[3][2]          # 9 pairs
    U2 = by_size[6][0] + by_size[6][1]                          # 12 pairs
    U3 = by_size[3][0] + by_size[4][0] + by_size[6][2]          # 13 pairs
    results = []
    results.append(validate("U1 (3+3+3 = 9 pairs)", U1, 0))
    results.append(validate("U2 (6+6 = 12 pairs)", U2, 0))
    results.append(validate("U3 (3+4+6 = 13 pairs)", U3, 63))
    all_ok = all(r[0] for r in results)
    print(f"\n=== VALIDATION {'PASS 3/3' if all_ok else 'FAIL'} ===")
    full_run_extrapolation()
