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

DEPENDENCIES, and why this script carries a second sampler. numpy is used when it is present and
is the fast path. It is NOT required. Codex v2 adjudication row 24 (V2-L10 #3) executed the
advertised command on the clean host that DEVELOPMENT.md's build-prerequisites section describes
-- which installs build-essential, zlib1g-dev and python3 and no third-party Python module -- and
got ModuleNotFoundError. The figure 0.305832% is published in CRITIQUE.md, HISTORY.md, SOLVE.md
and SOLVE_SUMMARY.md with `python3 scripts/c2c3_joint_null.py` named as its reproduction command,
so on the documented environment the published reproduction path did not run at all (and PEP-668
blocks pip there). A published number's reproduction command must work on the environment the
project documents, so the stdlib sampler below is the fix: same null, same predicates, same
tokens, no third-party import. It is about 9x slower and it does NOT reproduce the numpy path
bit-for-bit at a given seed (a different RNG draws a different sample); what makes both runs
trustworthy is the same thing that already did -- the KW anchors and the sigma gate against the
two published EXACT marginals, both of which run on either engine. When numpy IS present the two
predicate implementations are additionally cross-checked against each other on a live batch, so a
divergence between them aborts instead of being reported.

Usage:  python3 scripts/c2c3_joint_null.py [N_TRIALS] [SEED]
        (default 10_000_000, seed 20260828 -- the published run)
        C2C3_FORCE_STDLIB=1 forces the stdlib sampler even where numpy is installed.
Emits C2C3_JOINT_NULL=OK on success, and C2C3_JOINT_NULL_ENGINE=numpy|stdlib naming the sampler
that produced the numbers. Gate with `grep -qx`, never on output shape.
Runtime MEASURED on this orchestrator (2 cores, 2026-09-02): numpy 18-23 s at 1e7; the stdlib
sampler runs at ~49.7k trials/s on one core, so 1e7 is ~3.4 minutes -- pass a smaller N_TRIALS
where that matters. Memory bounded by the 500k chunk (numpy) or by one 64-element list (stdlib).
"""
import os
import random
import sys

try:
    import numpy as np
except ImportError:                      # documented clean host: no third-party modules
    np = None

KW = [63, 0, 17, 34, 23, 58, 2, 16, 55, 59, 7, 56, 61, 47, 4, 8,
      25, 38, 3, 48, 41, 37, 32, 1, 57, 39, 33, 30, 18, 45, 28, 14,
      60, 15, 40, 5, 53, 43, 20, 10, 35, 49, 31, 62, 24, 6, 26, 22,
      29, 46, 9, 36, 52, 11, 13, 44, 54, 27, 50, 19, 51, 12, 21, 42]
PAIR_A = [KW[2 * p] for p in range(32)]
PAIR_B = [KW[2 * p + 1] for p in range(32)]
POPCOUNT = [bin(x).count("1") for x in range(64)]

if np is not None:
    PA = np.array(PAIR_A, dtype=np.int64)
    PB = np.array(PAIR_B, dtype=np.int64)
    POP = np.array(POPCOUNT, dtype=np.int64)
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


def c2_ok_one(seq):
    """C2 for a single 64-element sequence. Stdlib twin of c2_ok, same predicate."""
    pop = POPCOUNT
    for i in range(63):
        if pop[seq[i] ^ seq[i + 1]] == 5:
            return False
    return True


def cd_x64_one(seq):
    """C3 statistic for a single 64-element sequence. Stdlib twin of cd_x64."""
    pos = [0] * 64
    for i in range(64):
        pos[seq[i]] = i
    return sum(abs(pos[v] - pos[v ^ 63]) for v in range(64))


def sample_numpy(n_tot, seed):
    """Vectorised sampler. Returns (n2, n3, n23, done)."""
    rng = np.random.default_rng(seed)
    n2 = n3 = n23 = done = 0
    checked = False
    while done < n_tot:
        n = min(500_000, n_tot - done)
        perm = np.argsort(rng.random((n, 32)), axis=1)     # C1: random pair-block order
        ori = rng.integers(0, 2, size=(n, 32))             #     orientations free
        a, b = PA[perm], PB[perm]
        seq = np.empty((n, 64), dtype=np.int64)
        seq[:, 0::2] = np.where(ori == 0, a, b)
        seq[:, 1::2] = np.where(ori == 0, b, a)
        ok2, ok3v = c2_ok(seq), cd_x64(seq)
        if not checked:
            # The stdlib twins are the documented-clean-host reproduction path, so they may not
            # be allowed to drift from the vectorised predicates unnoticed. Where numpy IS here,
            # both run on the same live records and a disagreement aborts.
            # The sample size is MEASURED, not guessed. A planted `range(60)` in c2_ok_one --
            # an off-by-one that leaves the KW anchor intact -- diverges from the vectorised
            # predicate on 0.449% of draws (200,000 draws), so 64 records would have caught it
            # only 25% of the time; 2000 records catch it with probability 1 - 0.99551**2000,
            # i.e. ~1.000, and cost ~0.15 s once per run. (A planted `range(62)` is NOT a fault
            # and correctly does not fire: index 62 is an INTRA-pair transition, and no King Wen
            # pair has intra-pair Hamming distance 5 -- the 32 distances are all 2, 4 or 6 -- so
            # under this null the last transition can never be a 5.)
            for r in range(min(2000, n)):
                row = [int(x) for x in seq[r]]
                if c2_ok_one(row) != bool(ok2[r]) or cd_x64_one(row) != int(ok3v[r]):
                    raise AssertionError(
                        "PREDICATE DIVERGENCE: the stdlib and numpy C2/C3 implementations "
                        f"disagree on record {r}. One of them is wrong; refusing to report.")
            checked = True
        ok3 = ok3v <= CD_CEILING
        n2 += int(ok2.sum()); n3 += int(ok3.sum()); n23 += int((ok2 & ok3).sum())
        done += n
    return n2, n3, n23, done


def sample_stdlib(n_tot, seed):
    """Standard-library sampler -- same null, no third-party import. (n2, n3, n23, done)."""
    rng = random.Random(seed)
    shuffle, getbits = rng.shuffle, rng.getrandbits
    pa, pb, pop, ceil = PAIR_A, PAIR_B, POPCOUNT, CD_CEILING
    blocks = list(range(32))
    n2 = n3 = n23 = 0
    for _ in range(n_tot):
        shuffle(blocks)                                   # C1: random pair-block order
        ori = getbits(32)                                 #     orientations free
        seq = [0] * 64
        for j in range(32):                               # ori bit j selects (a,b) or (b,a)
            k = blocks[j]
            if (ori >> j) & 1:
                seq[2 * j] = pb[k]; seq[2 * j + 1] = pa[k]
            else:
                seq[2 * j] = pa[k]; seq[2 * j + 1] = pb[k]
        ok2 = True
        for i in range(63):
            if pop[seq[i] ^ seq[i + 1]] == 5:
                ok2 = False
                break
        pos = [0] * 64
        for i in range(64):
            pos[seq[i]] = i
        cd = 0
        for v in range(64):
            cd += abs(pos[v] - pos[v ^ 63])
        ok3 = cd <= ceil
        if ok2: n2 += 1
        if ok3: n3 += 1
        if ok2 and ok3: n23 += 1
    return n2, n3, n23, n_tot


def main():
    n_tot = int(sys.argv[1]) if len(sys.argv) > 1 else 10_000_000
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 20260828
    if n_tot < 1:
        print("N_TRIALS must be >= 1", file=sys.stderr)
        print("C2C3_JOINT_NULL=FAIL")
        return 2

    forced = os.environ.get("C2C3_FORCE_STDLIB", "0") == "1"
    engine = "stdlib" if (np is None or forced) else "numpy"

    # Anchors run on the STDLIB predicates so they hold on either engine and on a host with no
    # numpy at all -- a broken build fails loudly here rather than reporting a number.
    if not c2_ok_one(KW):
        raise AssertionError("ANCHOR FAILED: King Wen must satisfy C2")
    if cd_x64_one(KW) != CD_CEILING:
        raise AssertionError("ANCHOR FAILED: cd(KW) must be exactly 776")
    print(f"anchors ok: KW satisfies C2; cd(KW) = {CD_CEILING}")
    if engine == "stdlib":
        print("engine: standard library only (numpy absent or C2C3_FORCE_STDLIB=1) -- "
              "~9x slower than the numpy path; the seed does not reproduce numpy's sample")

    if engine == "numpy":
        n2, n3, n23, done = sample_numpy(n_tot, seed)
    else:
        n2, n3, n23, done = sample_stdlib(n_tot, seed)

    p2, p3, p23 = n2 / done, n3 / done, n23 / done
    prod = EXACT_C2 * EXACT_C3
    se = (p23 * (1 - p23) / done) ** 0.5

    def sig(p, e):
        s = (e * (1 - e) / done) ** 0.5
        # inf, never nan: abs(nan) > 5 is False, so a nan here would slip past the marginal
        # gate below and print OK. A sigma that cannot be computed must fail the gate, not pass
        # it. (s > 0 for every reachable input -- e is a nonzero constant and done >= 1 -- so
        # this branch is unreachable today and is written fail-closed so it stays that way.)
        return (p - e) / s if s else float("inf")

    print(f"N = {done:,}  seed = {seed}  engine = {engine}")
    print(f"  P(C2|C1)    = {100*p2:.5f}%   exact {100*EXACT_C2:.5f}%   ({sig(p2, EXACT_C2):+.1f} sigma)")
    print(f"  P(C3|C1)    = {100*p3:.5f}%   exact {100*EXACT_C3:.7f}%  ({sig(p3, EXACT_C3):+.1f} sigma)")
    print(f"  product     = {100*prod:.5f}%  (independence estimate, NOT a ceiling)")
    print(f"  P(C2^C3|C1) = {100*p23:.5f}%  ({(p23-prod)/se:+.1f} sigma over the product, "
          f"ratio {p23/prod:.4f})")
    # A marginal off by >5 sigma means a wrong predicate, and then the joint is meaningless.
    print(f"C2C3_JOINT_NULL_ENGINE={engine}")
    if abs(sig(p2, EXACT_C2)) > 5 or abs(sig(p3, EXACT_C3)) > 5:
        print("C2C3_JOINT_NULL=FAIL")
        return 1
    print("C2C3_JOINT_NULL=OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
