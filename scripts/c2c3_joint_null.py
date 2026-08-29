#!/usr/bin/env python3
"""Measure P(C2 ^ C3 | C1) under the pair-constrained null, and validate itself first.

WHY THIS EXISTS. CRITIQUE.md published `4.29341% x 6.42114% ~ 0.28%` as a "rough ceiling" on the
joint. A product of marginals is an INDEPENDENCE ESTIMATE; it bounds the joint from above only if
C2 and C3 are non-positively correlated, which is the open question rather than a given. This
measures the joint directly. Result (2026-08-28): the joint EXCEEDS the product by ~11%, so C2 and
C3 are positively correlated given C1 and no ceiling holds.

THE NULL, stated exactly, because "pair-constrained" is ambiguous on two axes:
  * C1 given  -> a uniform random permutation of the 32 King Wen pair blocks,
  * start-FREE -> orientations uniform and the (Qian, Kun) start NOT pinned (no C4).
That is the conditioning both published exact marginals use; pinning the start would be a
different population and must not be compared against them.

SELF-VALIDATION, which is the load-bearing part. Two published EXACT marginals exist:
    P(C2 | C1) = 4.29341%          (`solve --f1-exact-c1c2`, 3-prime CRT)
    P(C3 | C1) = 6.4211367496%     (`verify.py --check-null-g --unpinned`)
This script reproduces both from its own predicates before reporting the joint. An implementation
that misses either marginal has a wrong C2 or C3 and its joint means nothing -- so the marginals
are checked and printed with their sigma, not assumed. The predicates are additionally anchored on
King Wen itself: KW satisfies C2, and cd(KW) = 776 exactly, which is the C3 ceiling by construction.
Both anchors are ASSERTED, so a broken build fails loudly instead of reporting a number.

WHAT THE SELF-VALIDATION DOES NOT CATCH, stated so it is not over-read. The KW anchors catch a
wrong C2 or C3 predicate (verified: flipping the C2 distance to 4, or the C3 ceiling to 800, both
abort at the assert). The marginal sigma-gate catches gross sampler errors. Neither can discriminate
the two CONDITIONINGS: C2 given C1&C4 is 4.2872% against 4.29341% start-free, ~0.006pp apart, far
inside the noise at any N this runs at. So pinning the start would pass every check here and still
be the wrong population. The conditioning is correct BY CONSTRUCTION -- perm and ori are both fully
free above -- and that is the reason it is spelled out rather than left to the reader.

Usage:  python3 scripts/c2c3_joint_null.py [N_TRIALS] [SEED]
        (default 10_000_000, seed 20260828 -- the published run)
Emits C2C3_JOINT_NULL=OK on success. Gate with `grep -qx`, never on output shape.
Runtime ~19 s at 1e7 on two cores; memory bounded by the 500k chunk.
"""
import sys
import numpy as np

KW = [63, 0, 17, 34, 23, 58, 2, 16, 55, 59, 7, 56, 61, 47, 4, 8,
      25, 38, 3, 48, 41, 37, 32, 1, 57, 39, 33, 30, 18, 45, 28, 14,
      60, 15, 40, 5, 53, 43, 20, 10, 35, 49, 31, 62, 24, 6, 26, 22,
      29, 46, 9, 36, 52, 11, 13, 44, 54, 27, 50, 19, 51, 12, 21, 42]
PA = np.array([KW[2 * p] for p in range(32)], dtype=np.int64)
PB = np.array([KW[2 * p + 1] for p in range(32)], dtype=np.int64)
POP = np.array([bin(x).count("1") for x in range(64)], dtype=np.int64)
COMP = np.arange(64) ^ 63

EXACT_C2 = 0.0429341          # published exact, C1-given start-free
EXACT_C3 = 0.064211367496     # published exact, C1-given start-free
CD_CEILING = 776              # C3: cd(S) <= 12.125 mean == 776 summed over 64 hexagrams


def c2_ok(seq):
    """C2: no two consecutive hexagrams differ by exactly 5 lines (spec SPECIFICATION.md)."""
    return (POP[seq[:, :-1] ^ seq[:, 1:]] != 5).all(axis=1)


def cd_x64(seq):
    """C3 statistic: sum over all 64 hexagrams of |pos(v) - pos(v ^ 63)|."""
    n = seq.shape[0]
    pos = np.empty_like(seq)
    pos[np.arange(n)[:, None], seq] = np.arange(64)[None, :]
    return np.abs(pos - pos[:, COMP]).sum(axis=1)


def main():
    n_tot = int(sys.argv[1]) if len(sys.argv) > 1 else 10_000_000
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 20260828

    kw = np.array(KW, dtype=np.int64)[None, :]
    if not (bool(c2_ok(kw)[0])):
        raise AssertionError("ANCHOR FAILED: King Wen must satisfy C2")
    if not (int(cd_x64(kw)[0]) == CD_CEILING):
        raise AssertionError("ANCHOR FAILED: cd(KW) must be exactly 776")
    print(f"anchors ok: KW satisfies C2; cd(KW) = {CD_CEILING}")

    rng = np.random.default_rng(seed)
    n2 = n3 = n23 = done = 0
    while done < n_tot:
        n = min(500_000, n_tot - done)
        perm = np.argsort(rng.random((n, 32)), axis=1)     # C1: random pair-block order
        ori = rng.integers(0, 2, size=(n, 32))             #     orientations free
        a, b = PA[perm], PB[perm]
        seq = np.empty((n, 64), dtype=np.int64)
        seq[:, 0::2] = np.where(ori == 0, a, b)
        seq[:, 1::2] = np.where(ori == 0, b, a)
        ok2, ok3 = c2_ok(seq), cd_x64(seq) <= CD_CEILING
        n2 += int(ok2.sum()); n3 += int(ok3.sum()); n23 += int((ok2 & ok3).sum())
        done += n

    p2, p3, p23 = n2 / done, n3 / done, n23 / done
    prod = EXACT_C2 * EXACT_C3
    se = (p23 * (1 - p23) / done) ** 0.5

    def sig(p, e):
        s = (e * (1 - e) / done) ** 0.5
        return (p - e) / s if s else float("nan")

    print(f"N = {done:,}  seed = {seed}")
    print(f"  P(C2|C1)    = {100*p2:.5f}%   exact {100*EXACT_C2:.5f}%   ({sig(p2, EXACT_C2):+.1f} sigma)")
    print(f"  P(C3|C1)    = {100*p3:.5f}%   exact {100*EXACT_C3:.7f}%  ({sig(p3, EXACT_C3):+.1f} sigma)")
    print(f"  product     = {100*prod:.5f}%  (independence estimate, NOT a ceiling)")
    print(f"  P(C2^C3|C1) = {100*p23:.5f}%  ({(p23-prod)/se:+.1f} sigma over the product, "
          f"ratio {p23/prod:.4f})")
    # A marginal off by >5 sigma means a wrong predicate, and then the joint is meaningless.
    if abs(sig(p2, EXACT_C2)) > 5 or abs(sig(p3, EXACT_C3)) > 5:
        print("C2C3_JOINT_NULL=FAIL")
        return 1
    print("C2C3_JOINT_NULL=OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
