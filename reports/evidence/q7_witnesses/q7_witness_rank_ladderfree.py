#!/usr/bin/env python3
"""q7_witness_rank_ladderfree.py -- the O3 walk rank of a C1&C2&C4&C5 arrangement, with no ladder.

WHAT IT COMPUTES.  rank_O3(w) = #{u in SUPER : u <_O3 w}, where SUPER is the set of orderings of the
64 hexagrams satisfying C1, C2, C4 and C5 (documentation/SPECIFICATION.md; C3 is NOT applied), and
<_O3 is the order solve.c documents above kc_o3_rank: compare the pair vectors first (each slot's
pair named by its King Wen slot index, slot 0 most significant), then the orientation vectors
(0 = the pair in King Wen's orientation, 0 before 1, slot 0 most significant).  It is the number
`solve --kc-o3-rank FDIR GDIR WALK` prints as `rank3`, reached by a different route: that command
reads completion counts from the n = 31 f and g ladders; this script counts completions itself, by
a memoised search over (unused pairs, last hexagram, remaining C5 budget).

SCOPE.  The search is exact, but it is only fast when the arrangement leaves King Wen's pair order
late: the work grows with the number of pairs still unplaced at the first slot where a smaller pair
could have been chosen.  --max-free (default 12) refuses, by name, an input that would need more.
The pinned Q7 witness (the two .txt files beside this script) first differs from King Wen's pair order at
slot 21, with 10 pairs unplaced, and takes about a second.  King Wen itself ranks 0 (it is the least
ordering by construction of the order), which the script checks on every run.

WHAT THE NUMBER IS.  A coordinate in an order built from King Wen's own pair table.  It is not a
rarity statement about the arrangement (TR-12 section Q7, D5-14).

Pure standard library.  The King Wen sequence is read from solve.py only as data; nothing else is
imported from the repository.  Developed with AI assistance (Claude Fable 5.2, Anthropic).

USAGE
  python3 reports/evidence/q7_witnesses/q7_witness_rank_ladderfree.py                       # both pinned witnesses + KW control
  python3 reports/evidence/q7_witnesses/q7_witness_rank_ladderfree.py --seq 63,0,17,...     # any 64-value arrangement
  python3 reports/evidence/q7_witnesses/q7_witness_rank_ladderfree.py --selftest            # brute-force cross-check, tiny universes
  python3 reports/evidence/q7_witnesses/q7_witness_rank_ladderfree.py --check-g reports/evidence/tr12/atlas_followups_n31_20260925/q8
      # also require this script's completion counts to equal the n = 31 ladder's g at every step >= 19
      # of the 11 committed --kc-profile tables (prints Q7LF_G_EQUALS_LADDER_G=<agree>/<compared>)
Whole-line tokens: Q7LF_KW_RANK3=0, Q7LF_RANK3:<name>=<int>, Q7LF_CLASS_FIRST_RANK3:<name>=<int>,
Q7LF_ORIENT_IDX:<name>=<int>, Q7LF_CLASS_M:<name>=<int>,
Q7LF_PAIR_BLOCKS:<name>=slot<j>:pair<q>:<walks>;..., Q7LF_KW_CLASS_M=<int>, Q7LF_VERDICT=PASS|FAIL:<why>.  Exit 0 only on PASS.
"""
import os
import sys
from functools import lru_cache
from itertools import permutations, product

HERE = os.path.dirname(os.path.abspath(__file__))        # .../reports/evidence/q7_witnesses
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
CLASSES = (1, 2, 3, 4, 6)          # admissible between-pair Hamming distances (5 is C2-forbidden)
CIDX = {d: i for i, d in enumerate(CLASSES)}


def rev6(h):
    return int('{:06b}'.format(h)[::-1], 2)


def partner(h):
    r = rev6(h)
    return r if r != h else h ^ 63


def dist(a, b):
    return bin(a ^ b).count('1')


class Universe:
    """pairs[i] = (entry, exit) of the reference ordering's slot i; slot 0 is the C4 anchor.
    budget = the reference ordering's multiset of between-pair distances, as counts per CLASSES."""

    def __init__(self, ref):
        assert len(ref) % 2 == 0 and len(set(ref)) == len(ref)
        self.n = len(ref) // 2                      # number of pair slots, anchor included
        self.pairs = [(ref[2 * i], ref[2 * i + 1]) for i in range(self.n)]
        for a, b in self.pairs:
            assert partner(a) == b and partner(b) == a, 'reference ordering violates C1'
        self.pair_of = {}
        for i, (a, b) in enumerate(self.pairs):
            self.pair_of[a] = i
            self.pair_of[b] = i
        bud = [0] * len(CLASSES)
        for i in range(self.n - 1):
            d = dist(ref[2 * i + 1], ref[2 * i + 2])
            assert d in CIDX, 'reference ordering violates C2'
            bud[CIDX[d]] += 1
        self.budget = tuple(bud)
        self.full = (1 << self.n) - 1

        @lru_cache(maxsize=None)
        def completions(mask, last, bud):
            """Number of ways to place every pair not in mask after a walk ending at hexagram `last`
            with remaining between-pair budget `bud`.  Exact; C2 and C5 enforced step by step."""
            if mask == self.full:
                return 1 if not any(bud) else 0
            tot = 0
            for q in range(self.n):
                if mask >> q & 1:
                    continue
                for ent, ext in (self.pairs[q], self.pairs[q][::-1]):
                    c = CIDX.get(dist(last, ent))
                    if c is None or bud[c] == 0:
                        continue
                    nb = bud[:c] + (bud[c] - 1,) + bud[c + 1:]
                    tot += completions(mask | 1 << q, ext, nb)
            return tot
        self.completions = completions

    def decode(self, seq):
        """seq -> (pair vector, orientation vector), or raises ValueError naming the violated rule."""
        if sorted(seq) != sorted(h for p in self.pairs for h in p):
            raise ValueError('not a permutation of the universe')
        pv, ov = [], []
        for i in range(self.n):
            a, b = seq[2 * i], seq[2 * i + 1]
            if partner(a) != b:
                raise ValueError('C1: slot %d is not a pair' % i)
            q = self.pair_of[a]
            pv.append(q)
            ov.append(0 if (a, b) == self.pairs[q] else 1)
        if (pv[0], ov[0]) != (0, 0):
            raise ValueError('C4: the anchor pair is not first in its reference orientation')
        bud = list(self.budget)
        for i in range(self.n - 1):
            c = CIDX.get(dist(seq[2 * i + 1], seq[2 * i + 2]))
            if c is None:
                raise ValueError('C2: a distance-5 step after slot %d' % i)
            bud[c] -= 1
        if any(bud):
            raise ValueError('C5: the between-pair distance multiset differs from the reference')
        return pv, ov

    def _step(self, front, q):
        """Extend an orientation frontier {(last, budget): count} by pair q in both orientations."""
        out = {}
        for (last, bud), cnt in front.items():
            for ent, ext in (self.pairs[q], self.pairs[q][::-1]):
                c = CIDX.get(dist(last, ent))
                if c is None or bud[c] == 0:
                    continue
                key = (ext, bud[:c] + (bud[c] - 1,) + bud[c + 1:])
                out[key] = out.get(key, 0) + cnt
        return out

    def rank(self, seq, max_free=12):
        """-> (rank3, class_first_rank3, orient_idx, class size m).  Raises ValueError on a non-member or when a
        block mass would need more than max_free unplaced pairs."""
        pv, ov = self.decode(seq)
        n = self.n
        self.blocks = []
        # Phase 1: pair-vector blocks.  front = orientation fiber of the pair prefix pv[:j].
        front = {(self.pairs[0][1], self.budget): 1}
        mask = 1
        class_first = 0
        for j in range(1, n):
            lower = [q for q in range(n) if not mask >> q & 1 and q < pv[j]]
            if lower and n - j - 1 > max_free:
                raise ValueError('refused: slot %d has a smaller unused pair with %d pairs still '
                                 'unplaced (> --max-free %d); use solve --kc-o3-rank with the ladders'
                                 % (j, n - j - 1, max_free))
            for q in lower:
                mass = 0
                for (last, bud), cnt in self._step(front, q).items():
                    mass += cnt * self.completions(mask | 1 << q, last, bud)
                class_first += mass
                if mass:
                    self.blocks.append((j, q, mass))   # walks whose pair vector is pv[:j] + [q] + anything
            front = self._step(front, pv[j])
            mask |= 1 << pv[j]
        # Phase 2: orientation tiebreak inside the class (fixed pair vector), plain lex order.
        @lru_cache(maxsize=None)
        def tail(j, last, bud):
            """valid orientation assignments of slots j.. given the walk so far ends at `last`."""
            if j == n:
                return 1 if not any(bud) else 0
            tot = 0
            for ent, ext in (self.pairs[pv[j]], self.pairs[pv[j]][::-1]):
                c = CIDX.get(dist(last, ent))
                if c is not None and bud[c]:
                    tot += tail(j + 1, ext, bud[:c] + (bud[c] - 1,) + bud[c + 1:])
            return tot
        orient_idx = 0
        last, bud = self.pairs[0][1], self.budget
        for j in range(1, n):
            a, b = self.pairs[pv[j]]
            if ov[j] == 1:                       # every valid assignment with orient 0 here precedes
                c = CIDX.get(dist(last, a))
                if c is not None and bud[c]:
                    orient_idx += tail(j + 1, b, bud[:c] + (bud[c] - 1,) + bud[c + 1:])
            ent, ext = (a, b) if ov[j] == 0 else (b, a)
            c = CIDX[dist(last, ent)]
            bud = bud[:c] + (bud[c] - 1,) + bud[c + 1:]
            last = ext
        m = tail(1, self.pairs[0][1], self.budget)   # class size: valid orientations of this pair vector
        if not 0 <= orient_idx < m:
            raise ValueError('internal: orient_idx %d outside the class of size %d' % (orient_idx, m))
        return class_first + orient_idx, class_first, orient_idx, m


def kw_sequence():
    sys.path.insert(0, ROOT)
    import solve                                  # data only: the King Wen sequence
    return list(solve._r7_kw())


def read_seq_file(path):
    seqs = [l.strip()[4:] for l in open(path) if l.startswith('SEQ=')]
    if len(seqs) != 1:
        raise ValueError('%s: expected exactly one SEQ= line, found %d' % (path, len(seqs)))
    return [int(x) for x in seqs[0].split(',')]


def selftest():
    """Brute force on tiny universes: enumerate EVERY member, sort by the O3 key, and require
    rank() to return each member's index.  The universes are prefixes-with-closure of King Wen's
    pair table re-budgeted to their own reference ordering, so they exercise the same code path."""
    kw = kw_sequence()
    checked = 0
    for npairs, picks in ((5, (0, 1, 2, 3, 4)), (6, (0, 3, 7, 12, 21, 22)), (7, (0, 5, 6, 9, 17, 22, 30))):
        ref = [h for i in picks for h in kw[2 * i:2 * i + 2]]
        # a reference ordering must itself satisfy C2; skip a pick that does not
        if any(dist(ref[2 * i + 1], ref[2 * i + 2]) == 5 for i in range(npairs - 1)):
            print('Q7LF_SELFTEST_SKIP n=%d (reference has a distance-5 step)' % npairs)
            continue
        U = Universe(ref)
        members = []
        for perm in permutations(range(1, npairs)):
            for bits in product((0, 1), repeat=npairs - 1):
                seq = list(U.pairs[0])
                for q, o in zip(perm, bits):
                    seq += U.pairs[q] if o == 0 else U.pairs[q][::-1]
                try:
                    pv, ov = U.decode(seq)
                except ValueError:
                    continue
                members.append((pv, ov, seq))
        members.sort(key=lambda m: (m[0], m[1]))
        for idx, (pv, ov, seq) in enumerate(members):
            r = U.rank(seq, max_free=npairs)[0]
            if r != idx:
                print('Q7LF_SELFTEST=FAIL n=%d index %d ranked %d' % (npairs, idx, r))
                return 1
        if not members or U.rank(ref, max_free=npairs)[0] != 0:
            print('Q7LF_SELFTEST=FAIL n=%d reference is not rank 0' % npairs)
            return 1
        print('Q7LF_SELFTEST_UNIVERSE n=%d members=%d all ranks equal their sorted index' % (npairs, len(members)))
        checked += len(members)
    if checked < 100:
        print('Q7LF_SELFTEST=FAIL only %d members checked' % checked)
        return 1
    print('Q7LF_SELFTEST=PASS members_checked=%d' % checked)
    return 0


def check_g(U, directory, min_step=19):
    """Bind the completion counter to ladder values: for every --kc-profile table in `directory`
    (the committed query-8 profiles), the ladder's g at each step >= min_step must equal
    completions() of the same oriented prefix.  -> (agreeing, compared)."""
    import glob
    ok = tot = 0
    for p in sorted(glob.glob(os.path.join(directory, '*.tsv'))):
        hdr, rows = None, []
        for line in open(p):
            q = line.rstrip('\n').split('\t')
            if q[0] == 'step':
                hdr = q
            elif hdr and q[0].isdigit() and len(q) == len(hdr):
                rows.append(dict(zip(hdr, q)))
        mask, last, bud = 1, U.pairs[0][1], U.budget
        for r in rows:
            ent, ext = int(r['entry']), int(r['exit'])
            c = CIDX[dist(last, ent)]
            bud = bud[:c] + (bud[c] - 1,) + bud[c + 1:]
            mask |= 1 << U.pair_of[ent]
            last = ext
            if int(r['step']) >= min_step:
                tot += 1
                ok += U.completions(mask, last, bud) == int(r['g'])
    return ok, tot


def main(argv):
    max_free = 12
    gdir = None
    seqs = []
    args = list(argv)
    while args:
        a = args.pop(0)
        if a == '--selftest':
            return selftest()
        elif a == '--max-free' and args:
            max_free = int(args.pop(0))
        elif a == '--check-g' and args:
            gdir = args.pop(0)
        elif a == '--seq' and args:
            seqs.append(('seq%d' % (len(seqs) + 1), [int(x) for x in args.pop(0).split(',')]))
        elif a == '--seq-file' and args:
            p = args.pop(0)
            seqs.append((os.path.basename(p).rsplit('.', 1)[0], read_seq_file(p)))
        else:
            print('Q7LF_VERDICT=FAIL:usage (unknown or incomplete argument %r)' % a)
            return 2
    kw = kw_sequence()
    U = Universe(kw)
    if U.n != 32 or U.budget != (2, 8, 13, 7, 1):
        print('Q7LF_VERDICT=FAIL:universe (n=%d budget=%r)' % (U.n, U.budget))
        return 1
    if not seqs:
        seqs = [(t, read_seq_file(os.path.join(HERE, t + '.txt'))) for t in ('moore-strict', 'grand-strict')]
    print('#q7lf universe: 31 free pairs + the C4 anchor; between-pair budget d1,d2,d3,d4,d6 = %s; '
          'space SUPER = C1&C2&C4&C5 (C3 not applied); order O3; object WALK rank' % ','.join(map(str, U.budget)))
    kw_rank = U.rank(kw, max_free=max_free)
    print('Q7LF_KW_RANK3=%d' % kw_rank[0])
    print('Q7LF_KW_CLASS_M=%d' % kw_rank[3])
    if kw_rank[:3] != (0, 0, 0):
        print('Q7LF_VERDICT=FAIL:king_wen_not_rank_0')
        return 1
    if gdir is not None:
        ok, tot = check_g(U, gdir)
        print('Q7LF_G_EQUALS_LADDER_G=%d/%d' % (ok, tot))
        if tot == 0 or ok != tot:
            print('Q7LF_VERDICT=FAIL:completion_counts_differ_from_the_ladder_g_values_in_%s' % gdir)
            return 1
    for name, seq in seqs:
        try:
            r, cf, oi, m = U.rank(seq, max_free=max_free)
        except ValueError as e:
            print('Q7LF_VERDICT=FAIL:%s:%s' % (name, e))
            return 1
        if seq == kw:
            print('Q7LF_VERDICT=FAIL:%s:the input is King Wen itself' % name)
            return 1
        print('Q7LF_RANK3:%s=%d' % (name, r))
        print('Q7LF_CLASS_FIRST_RANK3:%s=%d' % (name, cf))
        print('Q7LF_ORIENT_IDX:%s=%d' % (name, oi))
        print('Q7LF_CLASS_M:%s=%d' % (name, m))
        print('Q7LF_PAIR_BLOCKS:%s=%s' % (name, ';'.join('slot%d:pair%d:%d' % t for t in U.blocks) or 'none'))
    print('Q7LF_VERDICT=PASS')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
