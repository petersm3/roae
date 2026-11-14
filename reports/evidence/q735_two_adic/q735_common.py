"""Shared definitions for the Q-735 2-adic reproducers (reports/evidence/q735_two_adic/).

Python 3 standard library only.  Everything is built from the 64 six-bit hexagrams and Hamming
distance; the Z_4^3 coordinates of the proof are derived here and checked against that definition
(`coordinates_check`).

Conventions (README.md, section "Notation").  A hexagram h is six bits, bit 0 the bottom line.
Position-pair j (j = 0, 1, 2) is the bit pair (j, 5 - j).  The odd support of h is
S(h) = sum_j (bit_j ^ bit_{5-j}) << j and its entry part is T(h) = sum_j bit_{5-j} << j, so
h = hexof(S(h), T(h)).  mate(h) is the reversal of h, or its complement when h is a palindrome
(the C1 pairing).  s~ = s for s != 0 and 7 (= 111) for s = 0.  A walk enters slot k (k = 1..31) at
hexagram h_k and leaves it at mate(h_k); slot 0 is the anchor pair {63, 0} with exit 0.  Boundary k
(k = 0..30) joins the exit of slot k to the entry of slot k+1, and its class is the Hamming
distance.  A support-skeleton fibre F(s., c) counts the walks whose slot-k entry has support s_k
and whose boundary classes are exactly c_0..c_30.
"""
import itertools
import os

# The King Wen hexagram table, copied verbatim from solve.py `binary_hexagrams` (King Wen order,
# bit 0 = bottom line).  tests.py compares it with solve.py.
KW_HEXAGRAMS = [
    0b111111, 0b000000, 0b010001, 0b100010, 0b010111, 0b111010, 0b000010, 0b010000,
    0b110111, 0b111011, 0b000111, 0b111000, 0b111101, 0b101111, 0b000100, 0b001000,
    0b011001, 0b100110, 0b000011, 0b110000, 0b101001, 0b100101, 0b100000, 0b000001,
    0b111001, 0b100111, 0b100001, 0b011110, 0b010010, 0b101101, 0b011100, 0b001110,
    0b111100, 0b001111, 0b101000, 0b000101, 0b110101, 0b101011, 0b010100, 0b001010,
    0b100011, 0b110001, 0b011111, 0b111110, 0b011000, 0b000110, 0b011010, 0b010110,
    0b011101, 0b101110, 0b001001, 0b100100, 0b110100, 0b001011, 0b001101, 0b101100,
    0b110110, 0b011011, 0b110010, 0b010011, 0b110011, 0b001100, 0b010101, 0b101010,
]
KW_PAIRS = [(KW_HEXAGRAMS[2 * i], KW_HEXAGRAMS[2 * i + 1]) for i in range(32)]   # pair 0 = anchor (63, 0)
KW_BUDGET = {1: 2, 2: 8, 3: 13, 4: 7, 6: 1}
N_SLOTS = 31


def pc(x):
    return bin(x).count("1")


def v2(x):
    """2-adic valuation of a nonzero integer."""
    x = abs(int(x))
    if x == 0:
        raise ValueError("v2(0)")
    return (x & -x).bit_length() - 1


def vp(x, p):
    x = abs(int(x)); c = 0
    if x == 0:
        raise ValueError("vp(0)")
    while x % p == 0:
        x //= p; c += 1
    return c


def rev6(h):
    return int(format(h, "06b")[::-1], 2)


def mate(h):
    r = rev6(h)
    return r if r != h else h ^ 63


def S(h):
    return sum((((h >> j) ^ (h >> (5 - j))) & 1) << j for j in range(3))


def T(h):
    return sum(((h >> (5 - j)) & 1) << j for j in range(3))


def hexof(s, t):
    h = 0
    for j in range(3):
        sj = (s >> j) & 1; tj = (t >> j) & 1
        h |= (tj << (5 - j)) | ((tj ^ sj) << j)
    return h


def perm3(pi, x):
    """Permute the three bits of x: bit j goes to bit pi[j] (a coordinate permutation of the line pairs)."""
    return sum(((x >> j) & 1) << pi[j] for j in range(3))


def stilde(s):
    return s if s else 7


MATE = [mate(h) for h in range(64)]
PAIR_ID = [min(h, MATE[h]) for h in range(64)]
HEX_OF_SUPPORT = {s: [hexof(s, t) for t in range(8)] for s in range(8)}


def coordinates_check():
    """The Z_4^3 class formula and mate rule against the 6-bit definitions.  Returns mismatch counts."""
    bad_class = sum(1 for x in range(64) for y in range(64)
                    if pc(S(x) ^ S(y)) + 2 * pc((T(x) ^ T(y)) & ~(S(x) ^ S(y)) & 7) != pc(x ^ y))
    bad_mate = sum(1 for h in range(64) if MATE[h] != hexof(S(h), T(h) ^ stilde(S(h))))
    bad_round = sum(1 for h in range(64) if hexof(S(h), T(h)) != h)
    return bad_class, bad_mate, bad_round


def kw_fibre():
    """(skeleton, classes) of King Wen's own walk."""
    sk = [S(KW_PAIRS[i][0]) for i in range(1, 32)]
    cl = [pc(KW_PAIRS[i][1] ^ KW_PAIRS[i + 1][0]) for i in range(31)]
    return sk, cl


def walk_fibre(entries):
    """(skeleton, classes) of a walk given as its 31 entry hexagrams."""
    sk = [S(h) for h in entries]
    ex = 0; cl = []
    for h in entries:
        cl.append(pc(ex ^ h)); ex = MATE[h]
    return sk, cl


# ------------------------------------------------------------------ Walsh-Hadamard transform
def fwht(a):
    a = list(a); n = len(a); h = 1
    while h < n:
        for i in range(0, n, 2 * h):
            for j in range(i, i + h):
                x, y = a[j], a[j + h]; a[j], a[j + h] = x + y, x - y
        h *= 2
    return a


# ------------------------------------------------------------------ the support-class factor Phi_s
def phi_hex(s, gaps, anchor=0):
    """0/1 indicator Phi_s on the entry tuples (t_1..t_m) of the m slots of support s (m = 4, or 3 for
    s = 0), built from 6-bit hexagrams: distinct C1 pairs (and, for s = 0, not the anchor pair), and
    every internal boundary of the pattern at its prescribed class.  gaps[i] = 0: slots i, i+1 of this
    support are not adjacent in the walk; gaps[i] = r > 0: they are adjacent with boundary class 2r.
    anchor (s = 0 only): 0 = the first C slot is not slot 1; r > 0 = it is, with anchor boundary 2r."""
    m = 4 if s else 3
    a = [0] * (8 ** m)
    for t in itertools.product(range(8), repeat=m):
        hs = [hexof(s, x) for x in t]
        pids = set(PAIR_ID[h] for h in hs)
        if len(pids) != m or (s == 0 and PAIR_ID[0] in pids):
            continue
        if any(g and pc(MATE[hs[i]] ^ hs[i + 1]) != 2 * g for i, g in enumerate(gaps)):
            continue
        if anchor and pc(hs[0]) != 2 * anchor:
            continue
        idx = 0
        for x in t:
            idx = idx * 8 + x
        a[idx] = 1
    return a


def phi_z4(s, gaps, anchor=0):
    """The same indicator from the proof's Z_4^3 description: the t's lie in distinct cosets of <s~>
    (off the anchor coset {000, 111} for s = 0), and an internal gap r means |t_i + s~ + t_{i+1}| = r."""
    m = 4 if s else 3; st = stilde(s)
    a = [0] * (8 ** m)
    for t in itertools.product(range(8), repeat=m):
        cos = [min(x, x ^ st) for x in t]
        if len(set(cos)) != m or (s == 0 and 0 in cos):
            continue
        if any(g and pc(t[i] ^ st ^ t[i + 1]) != g for i, g in enumerate(gaps)):
            continue
        if anchor and pc(t[0]) != anchor:
            continue
        idx = 0
        for x in t:
            idx = idx * 8 + x
        a[idx] = 1
    return a


def patterns(s):
    """Every (gaps, anchor) pattern of support s: 4^3 for s != 0; 4^2 x 4 anchor values for s = 0."""
    m = 4 if s else 3
    for anchor in ((0, 1, 2, 3) if s == 0 else (0,)):
        for gaps in itertools.product(range(4), repeat=m - 1):
            yield gaps, anchor


def pattern_counts(gaps, anchor):
    """(# internal class-2 or class-4 boundaries, # class-6 boundaries) of a pattern."""
    n24 = sum(1 for g in gaps if g in (1, 2)) + (1 if anchor in (1, 2) else 0)
    n6 = sum(1 for g in gaps if g == 3) + (1 if anchor == 3 else 0)
    return n24, n6


_PHIHAT = {}


def phihat(s, gaps, anchor=0):
    """(transform list or None if Phi_s = 0, mu = min v2 over nonzero coefficients, count = sum Phi_s)."""
    key = (s, tuple(gaps), anchor)
    if key not in _PHIHAT:
        a = phi_hex(s, gaps, anchor); tot = sum(a)
        if tot == 0:
            _PHIHAT[key] = (None, None, 0)
        else:
            f = fwht(a)
            _PHIHAT[key] = (f, min(v2(x) for x in f if x), tot)
    return _PHIHAT[key]


def load_mu_table(path):
    """mu_table.tsv -> {(s, gaps, anchor): mu or None}."""
    out = {}
    with open(path) as fh:
        head = fh.readline().rstrip("\n").split("\t")
        for line in fh:
            r = dict(zip(head, line.rstrip("\n").split("\t")))
            gaps = tuple(int(c) for c in r["gaps"])
            out[(int(r["s"]), gaps, int(r["anchor"]))] = None if r["mu"] == "-" else int(r["mu"])
    return out


# ------------------------------------------------------------------ cross boundaries (Step 2)
def submasks(m):
    w = m; out = []
    while True:
        out.append(w)
        if w == 0:
            break
        w = (w - 1) & m
    return out


def ghat(s_left, s_right, c, anchor_side):
    """Cross boundary between supports s_left != s_right with class c.  g(v) = [|(v + s~_left) & m| = r] on
    v = (t_k + t_{k+1}) & m, m = the coordinates where the supports agree, r = (c - |s_left + s_right|)/2
    (the anchor's exit is 000, so no s~ shift there).  Returns (|m|, {w: G(w)}) with ghat(w) = G(w) / 2^|m|,
    or None when no v satisfies it (the fibre is empty)."""
    d = s_left ^ s_right; m = (~d) & 7; j = pc(d)
    if c < j or (c - j) % 2:
        return None
    r = (c - j) // 2
    shift = 0 if anchor_side else stilde(s_left)
    pts = [v for v in submasks(m) if pc((v ^ shift) & m) == r]
    if not pts:
        return None
    G = {}
    for w in submasks(m):
        x = sum((-1) ** pc(w & v) for v in pts)
        if x:
            G[w] = x
    return pc(m), G


def e_of(g):
    """e_k = max over nonzero coefficients of (|m| - v2 G(w)): ghat in 2^-e Z."""
    mm, G = g
    return max(mm - v2(x) for x in G.values())


# ------------------------------------------------------------------ Steps 1-5 for one fibre
def analyse(sk, cl, mu_table=None):
    """Decompose fibre (sk, cl) into support classes and cross boundaries.  Returns None when the fibre is
    empty for a structural reason (wrong slot counts, odd or zero internal class, infeasible cross
    boundary or pattern); otherwise a dict with the classes, cross factors, the Fourier bound
    sum(mu_s) - sum(e_k) and t = # class-3 boundaries whose supports differ in exactly one coordinate."""
    n = len(sk); full = [0] + list(sk)
    slots = {}
    for i in range(1, n + 1):
        slots.setdefault(full[i], []).append(i)
    cross = []; E = 0; t = 0
    for k in range(n):
        if full[k] != full[k + 1]:            # cross (the anchor has support 0)
            g = ghat(full[k], full[k + 1], cl[k], k == 0)
            if g is None:
                return None
            cross.append((k, g)); E += e_of(g)
            if cl[k] == 3 and pc(full[k] ^ full[k + 1]) == 1:
                t += 1
    cls = []; MU = 0
    for s, ks in slots.items():
        gaps = []
        for a, b in zip(ks, ks[1:]):
            if b == a + 1:
                if cl[a] % 2 or cl[a] == 0:
                    return None
                gaps.append(cl[a] // 2)
            else:
                gaps.append(0)
        anc = 0
        if s == 0 and ks[0] == 1:
            if cl[0] % 2 or cl[0] == 0:
                return None
            anc = cl[0] // 2
        if mu_table is not None and len(ks) == (4 if s else 3):
            mu = mu_table.get((s, tuple(gaps), anc))
            if mu is None:
                return None
            cls.append((s, ks, None)); MU += mu
            continue
        if len(ks) != (4 if s else 3):
            return None
        f, mu, _ = phihat(s, tuple(gaps), anc)
        if f is None:
            return None
        cls.append((s, ks, f)); MU += mu
    return dict(n=n, cross=cross, E=E, cls=cls, MU=MU, bound=MU - E, t=t)


def fourier_F(A):
    """Exact F by the Step-3 character sum, with each class factor multiplied in as soon as its last
    cross boundary is fixed and branches pruned on a zero factor (sparse at n = 31)."""
    n = A["n"]; cross = A["cross"]; cls = A["cls"]
    scale = sum(g[0] for k, g in cross)
    owner = {}
    for ci, (s, ks, f) in enumerate(cls):
        for k in ks:
            owner[k] = ci
    last = {}
    for i, (k, g) in enumerate(cross):
        if k >= 1:
            last[owner[k]] = i
        last[owner[k + 1]] = i
    finish = {}
    for ci, i in last.items():
        finish.setdefault(i, []).append(ci)
    u = [0] * (n + 2)

    def factor(ci):
        s, ks, f = cls[ci]; idx = 0
        for k in ks:
            idx = idx * 8 + u[k]
        return f[idx]

    base = 1
    for ci in range(len(cls)):
        if ci not in last:
            base *= factor(ci)
    total = 0

    def rec(i, coef):
        nonlocal total
        if i == len(cross):
            total += coef; return
        k, (mm, G) = cross[i]
        for w, x in G.items():
            if k >= 1:
                u[k] ^= w
            u[k + 1] ^= w
            c = coef * x
            for ci in finish.get(i, ()):
                if c == 0:
                    break
                c *= factor(ci)
            if c:
                rec(i + 1, c)
            if k >= 1:
                u[k] ^= w
            u[k + 1] ^= w

    if base:
        rec(0, base)
    assert total % (1 << scale) == 0, (total, scale)
    return total >> scale


def dp_F(sk, cl, pin=None):
    """Exact F by a layered count over (used-pair mask, exit hexagram) on real hexagrams.  pin = (slot,
    allowed entry hexagrams) restricts one slot (1-based).  Independent of the Fourier side."""
    pid_bit = {}
    for h in range(64):
        pid_bit.setdefault(PAIR_ID[h], len(pid_bit))
    bit = [1 << pid_bit[PAIR_ID[h]] for h in range(64)]
    states = {(bit[0], 0): 1}
    for i, (s, c) in enumerate(zip(sk, cl)):
        cand = [h for h in HEX_OF_SUPPORT[s] if pin is None or pin[0] != i + 1 or h in pin[1]]
        nxt = {}
        for (mask, ex), cnt in states.items():
            for h in cand:
                if pc(ex ^ h) != c or mask & bit[h]:
                    continue
                key = (mask | bit[h], MATE[h])
                nxt[key] = nxt.get(key, 0) + cnt
        states = nxt
        if not states:
            return 0
    return sum(states.values())


def default_atlas():
    here = os.path.dirname(os.path.abspath(__file__))
    return os.path.normpath(os.path.join(here, "..", "..", "..", "runs", "20260906_kc_ladders_n31", "atlas_n31.json"))


def here(name):
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), name)
