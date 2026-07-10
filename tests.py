#!/usr/bin/env python3
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
"""Regression harness for the Python instrument layer (solve.py, roae.py, sat.py).

One command: python3 tests.py
Covers the invariants that protect the two-language ground truth against future
edits — complementing solve.c's --selftest (which anchors the enumerator) and the
per-tool gates (--registry-verify, --f4p-verify) by running them all plus
helper-level checks in a single pass. Stdlib only."""

import subprocess, sys, unittest, importlib.util

def _load(name):
    spec = importlib.util.spec_from_file_location(name, name + ".py")
    m = importlib.util.module_from_spec(spec)
    argv, sys.argv = sys.argv, [name + ".py"]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = argv
    return m

solve = _load("solve")
roae = _load("roae")
sat = _load("sat")

KW = list(solve.binary_hexagrams)

class TestSequenceGround(unittest.TestCase):
    def test_kw_is_permutation(self):
        self.assertEqual(sorted(KW), list(range(64)))

    def test_kw_satisfies_c1(self):
        rev6 = lambda h: int(format(h, "06b")[::-1], 2)
        for i in range(32):
            a, b = KW[2 * i], KW[2 * i + 1]
            self.assertTrue(b == rev6(a) or (rev6(a) == a and b == a ^ 63),
                            f"pair {i + 1}: {a},{b}")

    def test_kw_c2_no_five(self):
        d = [bin(KW[i] ^ KW[i + 1]).count("1") for i in range(63)]
        self.assertNotIn(5, d)

    def test_kw_c4_start(self):
        self.assertEqual(KW[:2], [0b111111, 0b000000])

    def test_kw_c5_multiset(self):
        d = [bin(KW[i] ^ KW[i + 1]).count("1") for i in range(63)]
        self.assertEqual({k: d.count(k) for k in sorted(set(d))},
                         {1: 2, 2: 20, 3: 13, 4: 19, 6: 9})

    def test_kw_c3_total_776(self):
        pos = {h: i for i, h in enumerate(KW)}
        self.assertEqual(sum(abs(pos[h] - pos[h ^ 63]) for h in range(64)), 776)

class TestMawangdui(unittest.TestCase):
    """Primary-source anchors for the Mawangdui corpus-control array.

    Added 2026-07-05 after the array was found wrong (see incident notes /
    TR errata): the original 2026-04-06 array had correct octet membership
    but wrong octet order and wrong within-octet order, and no test asserted
    anything beyond permutation validity. Anchors below are from Shaughnessy,
    *The Origin and Early Development of the Zhou Changes* (Brill, 2022),
    p. 50 + Table 11.2; concordant with Cook 2006 and Shaughnessy 1996.
    RULE: any hardcoded sequence imported from a source gets anchor tests
    asserting positions stated by a PRIMARY source."""
    MD = list(roae.mawangdui_kw_indices)

    def test_md_is_permutation(self):
        self.assertEqual(sorted(self.MD), list(range(64)))

    def test_md_prose_anchors(self):
        # Qian 1st, Kun 33rd, Jiji (#63) 22nd, Weiji (#64) 54th (1-based)
        self.assertEqual(self.MD[0], 0)
        self.assertEqual(self.MD[32], 1)
        self.assertEqual(self.MD[21], 62)
        self.assertEqual(self.MD[53], 63)

    def test_md_generation_rule(self):
        # Octets by upper trigram Qian,Gen,Kan,Zhen,Kun,Dui,Li,Xun; lower
        # cycles Qian,Kun,Gen,Dui,Kan,Li,Zhen,Xun with own trigram promoted
        # to first (each octet opens with the pure doubled hexagram).
        val = {b: i for i, b in enumerate(KW)}
        upper = [0b111, 0b100, 0b010, 0b001, 0b000, 0b011, 0b101, 0b110]
        lower = [0b111, 0b000, 0b100, 0b011, 0b010, 0b101, 0b001, 0b110]
        gen = [val[(u << 3) | l] for u in upper
               for l in [u] + [t for t in lower if t != u]]
        self.assertEqual(self.MD, gen)

    def test_md_single_five_line_transition_at_octet_seam(self):
        # Authentic Mawangdui FAILS C2: exactly one 5-line transition,
        # positions 24->25 (#48 Jing -> #51 Zhen), an octet boundary.
        seq = [KW[i] for i in self.MD]
        fives = [i for i in range(63)
                 if bin(seq[i] ^ seq[i + 1]).count("1") == 5]
        self.assertEqual(fives, [23])
        self.assertEqual((self.MD[23], self.MD[24]), (47, 50))

    def test_md_transition_histogram(self):
        # Linear (63-step) histogram per Shaughnessy-derived sequence.
        seq = [KW[i] for i in self.MD]
        d = [bin(seq[i] ^ seq[i + 1]).count("1") for i in range(63)]
        self.assertEqual({k: d.count(k) for k in sorted(set(d))},
                         {1: 21, 2: 10, 3: 29, 4: 2, 5: 1})

class TestKnownValues(unittest.TestCase):
    def test_rc4_violations(self):
        n, slots = solve.rc4_violations(KW)
        self.assertEqual((n, slots), (2, [25, 26]))

    def test_wrap_distance_is_3(self):
        self.assertEqual(bin(KW[63] ^ KW[0]).count("1"), 3)

    def test_parity_switches_30(self):
        p = [bin(KW[i] ^ KW[i + 1]).count("1") & 1 for i in range(63)]
        self.assertEqual(sum(1 for i in range(62) if p[i] != p[i + 1]), 30)

    def test_alternations_15(self):
        pc = [bin(KW[2 * i]).count("1") % 2 for i in range(32)]
        self.assertEqual(sum(1 for i in range(31) if pc[i] != pc[i + 1]), 15)

class TestHelpers(unittest.TestCase):
    def test_trigram_split(self):
        self.assertEqual(roae.lower_trigram(0b111000), 0b000)
        self.assertEqual(roae.upper_trigram(0b111000), 0b111) if hasattr(roae, "upper_trigram") else None

    def test_nuclear(self):
        h = 0b010111
        self.assertEqual(roae.nuclear_hexagram(h) & 7, (h >> 1) & 7)

class TestGates(unittest.TestCase):
    def test_registry_verify(self):
        r = subprocess.run([sys.executable, "solve.py", "--registry-verify"],
                           capture_output=True, text=True)
        self.assertIn("ALL 31 REGISTRY CHECKS PASS", r.stdout)

    def test_f4p_verify(self):
        r = subprocess.run([sys.executable, "solve.py", "--f4p-verify"],
                           capture_output=True, text=True)
        self.assertIn("F4P VERIFY: PASS", r.stdout)

    def test_books_verify(self):
        r = subprocess.run([sys.executable, "solve.py", "--books-verify"],
                           capture_output=True, text=True)
        self.assertIn("BOOKS VERIFY: ALL 14 CLAIMS PASS", r.stdout)

    def test_perm_verify(self):
        # R3 permutation-cycle family: KW gate (13 frozen functionals) +
        # Fu Xi natural-order identity free-correctness check (prereg §6c).
        r = subprocess.run([sys.executable, "solve.py", "--perm-verify"],
                           capture_output=True, text=True)
        self.assertIn("PERM VERIFY: PASS", r.stdout)
        seq = ",".join(str(i) for i in range(64))
        r2 = subprocess.run([sys.executable, "solve.py", "--perm-verify", seq],
                            capture_output=True, text=True)
        # bit0=bottom identity -> pi_bot=id: ncyc=64,lcyc=1,fix=64,c2=0,ord=1,
        # desc=0,sign=0 (top convention non-trivial); template indicators 0,0.
        self.assertEqual(r2.stdout.strip().split(",")[:7],
                         ["64", "1", "64", "0", "1", "0", "0"])

    def test_sat_import_assertions(self):
        r = subprocess.run([sys.executable, "-c", "import sat"], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr[-300:])

    def test_certify_count_absent_tools(self):
        # sat.py --certify-count depends on OPTIONAL external binaries
        # (d4/cpog-gen/cpog-check). With them absent it must exit gracefully
        # with the clear install message (roae.py wkhtmltopdf idiom), never a
        # traceback. PATH is scrubbed to an empty dir so this gate holds even
        # on hosts that DO have the tools installed. The present-tools path is
        # RUN-validated during the R2-c cross-check campaign (see sat.py's
        # certify-count section header).
        import os, tempfile
        with tempfile.TemporaryDirectory() as empty:
            env = dict(os.environ, PATH=empty)
            r = subprocess.run([sys.executable, "sat.py", "--certify-count", "f1c5",
                                "--f1-pairs", "9", "--expect", "26112"],
                               capture_output=True, text=True, env=env)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("required to run --certify-count", r.stderr)
        self.assertIn("The rest of sat.py works without them.", r.stderr)
        self.assertNotIn("Traceback", r.stderr)

    def test_witness_absent_kissat(self):
        # same graceful-absence contract for --witness's kissat dependency
        import os, tempfile
        with tempfile.TemporaryDirectory() as empty:
            env = dict(os.environ, PATH=empty)
            r = subprocess.run([sys.executable, "sat.py", "--witness", "plain"],
                               capture_output=True, text=True, env=env)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("kissat is required to run --witness", r.stderr)
        self.assertNotIn("Traceback", r.stderr)


class TestSatC5Subset(unittest.TestCase):
    """Gate for the C5 cardinality/budget encoding + the reduced-subset
    (small-n certified-count probe) instances in sat.py (TASK #225 §6.4).

    Cross-checks sat.py's CNF against an INDEPENDENT reference count computed
    here from solve.py primitives only (no sat.py code path reused):
      * decisive: at tiny N the set of Y-assignments the CNF accepts (decided
        by unit propagation over the emitted clauses — a genuine SAT decision,
        Sinz counters being UP-complete once the Y/T inputs are fixed) equals
        exactly the valid C1&C2&C4&C5 sequences and the reference DP count;
      * pinned: the B0 budget and exact |C1&C2&C4&C5| at the group-closed
        N in {9,13,16} match the values a #SAT/C-binary cross-check must also
        reproduce (that heavier cross-check is the noted follow-up).
    Python-only, stdlib-only, <1 s."""
    DVAL = (1, 2, 3, 4, 6)
    CLS = {1: 0, 2: 1, 3: 2, 4: 3, 6: 4}

    @classmethod
    def _pairs(cls):
        return [(KW[2 * i], KW[2 * i + 1]) for i in range(32)]

    @classmethod
    def _ref_b0(cls, pl, start):
        # independent port of solve.c f1c5_b0_dfs (deterministic first completion)
        P = cls._pairs(); n = len(pl)
        pa = [P[p][0] for p in pl]; pb = [P[p][1] for p in pl]; out = [None] * n
        def dfs(mask, last, dep):
            if mask == (1 << n) - 1:
                return True
            for i in range(n):
                if (mask >> i) & 1:
                    continue
                for o in (0, 1):   # o=0: enter pair_b / exit pair_a (solve.c f1c5_b0_dfs)
                    f = pa[i] if o else pb[i]; s = pb[i] if o else pa[i]
                    if bin(last ^ f).count("1") == 5:
                        continue
                    out[dep] = cls.CLS[bin(last ^ f).count("1")]
                    if dfs(mask | (1 << i), s, dep + 1):
                        return True
            return False
        assert dfs(0, start, 0)
        b = {d: 0 for d in cls.DVAL}
        for c in out:
            b[cls.DVAL[c]] += 1
        return b

    @classmethod
    def _ref_count(cls, pl, start, b0):
        from functools import lru_cache
        P = cls._pairs(); n = len(pl)
        trans = [[(P[p][o ^ 1], P[p][o]) for o in (0, 1)] for p in pl]
        b0t = tuple(b0[d] for d in cls.DVAL)
        @lru_cache(maxsize=None)
        def rec(mask, last, res):
            if mask == (1 << n) - 1:
                return 1 if res == b0t else 0
            t = 0
            for i in range(n):
                if (mask >> i) & 1:
                    continue
                for f, s in trans[i]:
                    dd = bin(last ^ f).count("1")
                    if dd == 5:
                        continue
                    c = cls.CLS[dd]
                    if res[c] >= b0t[c]:
                        continue
                    nr = list(res); nr[c] += 1
                    t += rec(mask | (1 << i), s, tuple(nr))
            return t
        return rec(0, start, (0, 0, 0, 0, 0))

    @staticmethod
    def _up_ok(clauses, units):
        """Unit-propagation SAT decision: False iff the units force a conflict."""
        val = {}
        for l in units:
            v = abs(l); s = l > 0
            if val.get(v, s) != s:
                return False
            val[v] = s
        changed = True
        while changed:
            changed = False
            for cl in clauses:
                un = []; done = False
                for l in cl:
                    v = abs(l); w = l > 0
                    if v in val:
                        if val[v] == w:
                            done = True; break
                    else:
                        un.append(l)
                if done:
                    continue
                if not un:
                    return False
                if len(un) == 1:
                    l = un[0]; v = abs(l); s = l > 0
                    if val.get(v, s) != s:
                        return False
                    if v not in val:
                        val[v] = s; changed = True
        return True

    def test_tiny_encoding_equivalence(self):
        # exhaustive: CNF-accepts(arrangement) == valid(arrangement) == ref count
        import itertools
        P = self._pairs()
        for N in (2, 3, 4):
            for start in (0, 63):
                pl = list(range(1, N + 1))
                b0 = self._ref_b0(pl, start)
                self.assertEqual(b0, sat.derive_b0(pl, start))  # port agrees with sat.py
                cnf, ctx = sat.build_subset_pl(pl, start, b0)
                Y = ctx["Y"]; nj = ctx["nj"]; slots = ctx["slots"]; ors = ctx["orients"]
                accepted = 0; valid = 0
                for perm in itertools.permutations(range(N)):
                    for oc in itertools.product((0, 1), repeat=N):
                        units = []; seq = []
                        for si, s in enumerate(slots):
                            j = perm[si] * 2 + oc[si]
                            for jj in range(nj):
                                units.append(Y[(s, jj)] if jj == j else -Y[(s, jj)])
                            seq += [ors[j][2], ors[j][3]]
                        bnd = [bin(start ^ seq[0]).count("1")] + \
                              [bin(seq[2 * i + 1] ^ seq[2 * i + 2]).count("1") for i in range(N - 1)]
                        got = {d: 0 for d in self.DVAL}; ok = len(set(seq)) == 2 * N
                        for bd in bnd:
                            if bd in got:
                                got[bd] += 1
                            else:
                                ok = False
                        is_valid = ok and got == b0
                        is_acc = self._up_ok(cnf.cl, units)
                        self.assertEqual(is_acc, is_valid,
                                         f"N={N} start={start} perm={perm} oc={oc}")
                        accepted += is_acc; valid += is_valid
                self.assertEqual(accepted, self._ref_count(pl, start, b0))
                self.assertEqual(accepted, valid)

    def test_subset_probe_pins(self):
        # group-closed certified-count-probe instances: B0 + exact |C1&C2&C4&C5|.
        # Pinned oracle values; a proof-emitting #SAT / C-binary model-count
        # cross-check at these N is the intended follow-up (see R2 private note).
        # N=9's exact count is recomputed live here (cheap); N=13/16 counts are
        # pinned literals (their reference DP has a ~10^7-10^9 state space — too
        # heavy for a per-run gate; verified once out-of-band, see the R2 note).
        EXPECT = {
            9:  {"b0": {1: 2, 2: 5, 3: 0, 4: 2, 6: 0}, "count": 26_112, "live": True},
            13: {"b0": {1: 1, 2: 6, 3: 0, 4: 6, 6: 0}, "count": 2_063_395_607_040, "live": False},
            16: {"b0": {1: 1, 2: 8, 3: 1, 4: 6, 6: 0}, "count": 267_765_117_419_520, "live": False},
        }
        for N, exp in EXPECT.items():
            pl, start = sat.subset_pairlist(N)
            self.assertEqual(len(pl), N)
            b0 = sat.derive_b0(pl, start)
            self.assertEqual(b0, exp["b0"], f"B0 mismatch at N={N}")
            if exp["live"]:
                self.assertEqual(self._ref_count(pl, start, b0), exp["count"], f"count N={N}")
            # sanity: the emitted CNF builds and its recorded budget matches
            cnf, ctx = sat.build_subset(N)
            self.assertGreater(len(cnf.cl), 0)
            self.assertEqual(ctx["b0"], exp["b0"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
