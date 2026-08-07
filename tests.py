#!/usr/bin/env python3
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
"""Regression harness for the Python instrument layer (solve.py, roae.py, sat.py,
and the records path of the independent verifier verify.py).

One command: python3 tests.py
Covers the invariants that protect the two-language ground truth against future
edits — complementing solve.c's --selftest (which anchors the enumerator) and the
per-tool gates (--registry-verify, --f4p-verify) by running them all plus
helper-level checks in a single pass. Stdlib only."""

import subprocess, sys, unittest, importlib.util, itertools

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

    def test_pair_null_gender_le2_exact(self):
        # TR-8 §2 null (b): exact P(rc4_violations <= 2) over the pair-only (C1) null.
        from fractions import Fraction
        self.assertEqual(solve.pair_null_gender_le2_exact(), Fraction(47, 445740))
        dist = solve.pair_null_gender_distribution_exact()
        self.assertEqual(sum(dist.values()), 1)
        self.assertEqual(solve.rc4_violations(KW)[0], 2)  # KW sits at the <=2 boundary

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

class TestJingFang(unittest.TestCase):
    """Primary-source anchors for the Jing Fang eight-palace ORDER.

    Added 2026-08-01. The palace order Qian, Zhen, Kan, Gen, Kun, Xun, Li, Dui
    is hardcoded as the trigram literal at five sites — solve.py
    `_f4p_jf_palace`, `books_jf1` (`heads`), `_r7_jingfang`; roae.py
    `--trigrams`; solve.c `--null-historical` — and restated in decimal at two
    more (`_r7_J3`, and the `--r7-verify` anchor). Nothing compared any of them
    to a statement of the order outside the generators. In particular
    `books_jf1`'s "64/64 cells match Nielsen Table 2" subscripts
    `_BOOKS_NIELSEN_T2` **by key**, so it attests palace MEMBERSHIP and
    within-palace world-stage order and is silent on the order of the palaces
    themselves.

    The order is load-bearing for what crosses the seven inter-palace seams:
    only 1,152 of the 8! = 40,320 palace orders reproduce Jing Fang's diff-wave
    multiset {1: 48, 3: 15} (`_r7_J5`), asserted below. It is NOT load-bearing
    everywhere — `f4p_housedisp` is 56 for all 40,320, since the palaces are
    contiguous blocks of 8 in any order. How far the Jing Fang leg of the FC-1
    broken-instrument gate (`solve.py --r7-verify`) would move under a
    different order is UNMEASURED: CRITIQUE §Corpus Control II prices the order
    exactly at P(J2 ∧ J3 | J1) = 1/40,320 and reports Jing Fang EXTREME on 0 of
    11 under the J1-conditioned null, which bounds that exposure without
    settling it.

    Two anchors, both external to the generators:
      (1) Nielsen 2003 Table 2 (p. 3, after Hui Dong 1697-1758) prints the
          palaces as four "Yang Palaces" columns Qian | Zhen | Kan | Gen then
          four "Yin Palaces" columns Kun | Xun | Li | Dui. Transcribed from the
          page image on 2026-07-05 in roae-private/books/nielsen_companion/
          VISION_TRANSCRIPTIONS_2026_07_05.md (page_0591) — the same
          primary-data record `_BOOKS_NIELSEN_T2`'s cell values come from.
      (2) Within each half the order is exactly the Shuogua trigram-family
          scheme: father, then three sons ranked by the position of their
          single yang line; mother, then three daughters ranked by the
          position of their single yin line.
          `test_jf_order_from_trigram_family` derives both halves from the bit
          patterns alone. The yang-half-before-yin-half grouping is NOT from
          Shuogua — whose own enumeration alternates son/daughter — it is the
          table's own "Yang Palaces" / "Yin Palaces" column split, i.e. anchor
          (1), and is what solve.py `_r7_J2` states as a predicate.
    SCOPE: this pins ROAE's order to the order Nielsen prints. It does not
    settle the historical question CITATIONS.md#jingfang leaves open
    ("alternative orderings within the same palaces exist ... historical
    certainty of the full ordering is debated").
    RULE (see TestMawangdui): any hardcoded sequence imported from a source
    gets anchor tests asserting positions stated by a PRIMARY source."""
    # bit0 = bottom line, 1 = yang (solid); see solve.py `_r7_W` header.
    TRIGRAM = {"Qian": 0b111, "Zhen": 0b001, "Kan": 0b010, "Gen": 0b100,
               "Kun": 0b000, "Xun": 0b110, "Li": 0b101, "Dui": 0b011}
    NIELSEN_T2_COLUMNS = ["Qian", "Zhen", "Kan", "Gen",   # "Yang Palaces"
                          "Kun", "Xun", "Li", "Dui"]      # "Yin Palaces"

    @property
    def order(self):
        return [self.TRIGRAM[n] for n in self.NIELSEN_T2_COLUMNS]

    def test_jf_order_from_trigram_family(self):
        # Shuogua family scheme, derived from the bit patterns alone.
        sons = sorted((t for t in range(8) if bin(t).count("1") == 1),
                      key=lambda t: t.bit_length())
        daughters = sorted((t for t in range(8) if bin(t ^ 7).count("1") == 1),
                           key=lambda t: (t ^ 7).bit_length())
        self.assertEqual([0b111] + sons + [0b000] + daughters, self.order)

    def test_jf_generators_use_the_printed_palace_order(self):
        jf = solve._r7_jingfang()
        self.assertEqual(sorted(jf), list(range(64)))
        # Block b of the linear sequence is palace order[b]'s world-stage orbit.
        self.assertEqual(solve._r7_J1(jf), self.order)
        # The F4' palace index and the R7 seniority predicate agree with it.
        self.assertEqual([solve._F4P_PAL[(t << 3) | t] for t in self.order],
                         list(range(8)))
        self.assertTrue(solve._r7_J3(jf))

    def test_palace_order_is_load_bearing_for_the_diff_wave(self):
        # Exhaustive over all 8! palace orders (0.5 s): the order is not free
        # decoration. If this ever prints a different count, the world-stage
        # orbit _r7_W changed, not the order.
        W = {t: solve._r7_W(t) for t in range(8)}
        n = 0
        for p in itertools.permutations(self.order):
            s = []
            for t in p:
                s += W[t]
            if solve._r7_J5(s):
                n += 1
        self.assertEqual(n, 1152)
        self.assertTrue(solve._r7_J5(solve._r7_jingfang()))

    def test_nielsen_table2_key_order_is_the_printed_column_order(self):
        # _BOOKS_NIELSEN_T2 is insertion-ordered (py>=3.7) and its key order
        # already recorded the printed column order — but books_jf1 subscripts
        # the dict and never reads that order, so nothing checked it.
        self.assertEqual(list(solve._BOOKS_NIELSEN_T2), self.order)

    def test_other_language_generators_carry_the_same_literal(self):
        # solve.c --null-historical and roae.py --trigrams each hardcode the
        # order as their own literal; their headers called this a "cross-check"
        # while nothing compared them. Whitespace-insensitive fixed-string
        # match, no regex. If a count below changes, a copy of the palace order
        # was added or removed — anchor it here rather than relaxing the test.
        lit = ",".join("0b{:03b}".format(t) for t in self.order)
        for path, wrapped, n in (("solve.py", "(" + lit + ")", 3),
                                 ("roae.py", "(" + lit + ")", 1),
                                 ("solve.c", "{" + lit + "}", 1)):
            with open(path) as f:
                src = "".join(f.read().split())
            self.assertEqual(src.count(wrapped), n, path)

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
        # Unconditional by design: the previous form was guarded by
        # `if hasattr(roae, "upper_trigram") else None`, so renaming or deleting
        # the function would have turned a real check into a silent no-op rather
        # than a failure. A test that cannot fail when its subject disappears is
        # not a test. If this line ever errors on AttributeError, that is the
        # correct signal.
        self.assertEqual(roae.upper_trigram(0b111000), 0b111)

    def test_nuclear(self):
        h = 0b010111
        self.assertEqual(roae.nuclear_hexagram(h) & 7, (h >> 1) & 7)

class TestGates(unittest.TestCase):
    def test_roae_verify(self):
        # roae.py had 29 analysis sections and NO self-verify gate, while solve.py has five.
        # (29 per main()'s all_sections list / its "29 sections" banner / ROAE_PY_CLI.md;
        # this comment said 37 when written 2026-08-01 — corrected on same-day re-review.)
        # The load-bearing check inside is that roae.py's own King Wen table is identical to
        # solve.py's — they agree, but nothing enforced it, so a drift would have silently
        # diverged every roae analysis from every solve.py analysis.
        r = subprocess.run([sys.executable, "roae.py", "--verify"],
                           capture_output=True, text=True)
        self.assertIn("ROAE VERIFY: ALL", r.stdout)
        self.assertEqual(r.returncode, 0)

    def test_registry_verify(self):
        r = subprocess.run([sys.executable, "solve.py", "--registry-verify"],
                           capture_output=True, text=True)
        self.assertIn("ALL 31 REGISTRY CHECKS PASS", r.stdout)
        # The banner and the exit contract are two conjuncts; assert both
        # (solve.py documents "Returns 0 on full PASS, 1 on any mismatch").
        self.assertEqual(r.returncode, 0)

    def test_f4p_verify(self):
        r = subprocess.run([sys.executable, "solve.py", "--f4p-verify"],
                           capture_output=True, text=True)
        self.assertIn("F4P VERIFY: PASS", r.stdout)
        self.assertEqual(r.returncode, 0)

    def test_books_verify(self):
        r = subprocess.run([sys.executable, "solve.py", "--books-verify"],
                           capture_output=True, text=True)
        self.assertIn("BOOKS VERIFY: ALL 14 CLAIMS PASS", r.stdout)
        self.assertEqual(r.returncode, 0)

    def test_trigram_verify(self):
        # Two-language check of lean/TrigramTheorems.lean (finite facts +
        # KW instances); see documentation/TRIGRAM_STRUCTURE.md.
        r = subprocess.run([sys.executable, "solve.py", "--trigram-verify"],
                           capture_output=True, text=True)
        self.assertIn("TRIGRAM VERIFY: ALL 18 CLAIMS PASS", r.stdout)
        self.assertEqual(r.returncode, 0)

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

    def test_r7_verify(self):
        # R7 cross-tradition corpus-control: frozen anchors (FC-2 construction
        # cross-validation; J1-J5 reproduce Jing Fang; M1-M5 + exact Mawangdui
        # reconstruction; cross-application matrix a-priori cells; FC-1
        # positive-control expectation at pilot N=10^4). See roae-private/
        # R7_CORPUS_CONTROL_DESIGN_FROZEN_2026_07_11.md.
        r = subprocess.run([sys.executable, "solve.py", "--r7-verify"],
                           capture_output=True, text=True)
        self.assertIn("R7 VERIFY: ALL ANCHORS PASS", r.stdout)
        self.assertEqual(r.returncode, 0)

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

    @staticmethod
    def _count_models(clauses, nvars):
        """Exhaustive DPLL TOTAL-model counter (all variables, no projection).
        Unassigned-anywhere variables contribute 2^free once the clause set
        is satisfied, so this is the true #SAT count over nvars variables."""
        def simplify(cls, lit):
            out = []
            for c in cls:
                if lit in c:
                    continue
                if -lit in c:
                    nc = [l for l in c if l != -lit]
                    if not nc:
                        return None  # empty clause: conflict
                    out.append(nc)
                else:
                    out.append(c)
            return out
        def rec(cls, nfree):
            while True:  # unit propagation
                units = [c[0] for c in cls if len(c) == 1]
                if not units:
                    break
                cls = simplify(cls, units[0])
                if cls is None:
                    return 0
                nfree -= 1
            if not cls:
                return 1 << nfree
            v = abs(cls[0][0])
            pos, neg = simplify(cls, v), simplify(cls, -v)
            return ((rec(pos, nfree - 1) if pos is not None else 0) +
                    (rec(neg, nfree - 1) if neg is not None else 0))
        return rec([list(c) for c in clauses], nvars)

    def test_tiny_total_model_count(self):
        # #SAT-safety gate (R2 review §1e): the certified-count cross-check
        # (D4/CPOG) counts TOTAL models over ALL variables — Y, T indicators,
        # AND Sinz counter registers — not projections onto Y. That is safe
        # only because in an exactly_k context the auxiliary variables are
        # functionally determined in every model. Pin the property: exhaustive
        # DPLL total-model count == walk count at N in {2,3}, both start
        # values, so a future encoding change (e.g. swapping the cardinality
        # encoding for a non-count-safe one) cannot silently break #SAT-safety
        # before a model-counter run. NOTE the standing caveat: at_most_k
        # ALONE (as used by --with-c3 / alt-le-14 / -near-) is NOT
        # model-count-safe; this gate covers the exactly_k subset targets.
        for N in (2, 3):
            for start in (0, 63):
                pl = list(range(1, N + 1))
                b0 = self._ref_b0(pl, start)
                cnf, _ = sat.build_subset_pl(pl, start, b0)
                walks = self._ref_count(pl, start, b0)
                self.assertGreater(walks, 0)
                self.assertEqual(self._count_models(cnf.cl, cnf.n), walks,
                                 f"total-model count != walk count at N={N} start={start}")

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


class TestMooreKwGates(unittest.TestCase):
    """F-1 (TR-2 review) KW-forced regression gates for the Moore parity and
    rhythm encodings — the two rules carrying the grand-ccn4 UNSAT conflict
    theorem and its minimal cores ({parity,ccn4}, {rhythm,ccn4}). UNSAT has no
    witness to round-trip, so these gates pin the encodings to solve.py the
    other way around: with KW pinned by unit clauses, the strict Moore clauses
    must conflict at EXACTLY the solve.r11_axes-scored loci (g1 = 2 parity
    violations, g2 = 2 rhythm breaks, per R11_KW_EXPECTED), and unit
    propagation alone then decides UNSAT — solver-free, the rc4-kwtest /
    ccn4-kwtest analogue for the Moore axes (DRAT-certified kissat runs remain
    the archive-grade check when a solver is present)."""

    @staticmethod
    def _kw_j(s):
        return next(j for j in range(sat.NJ)
                    if sat.ORIENTS[j][0] == s and sat.ORIENTS[j][1] == 0)

    def test_kw_moore_scores_are_2_2(self):
        # ground truth + the sat.py scorer wrapper agree: KW = 2 parity
        # violations, 2 rhythm breaks (the values the reports claim)
        self.assertEqual(solve.r11_axes(KW)[:2], [2, 2])
        self.assertEqual(sat._moore_scores(KW), (2, 2))

    def test_moore_kwtest_conflicts_at_exactly_2_loci_and_up_unsat(self):
        g1 = solve.r11_axes(KW)[0]
        cnf, Y = sat.build("moore-kwtest")
        cl = set(map(tuple, cnf.cl))
        loci = [s for s in sat.SLOTS
                if (Y[(s, self._kw_j(s))],) in cl        # KW pin unit
                and (-Y[(s, self._kw_j(s))],) in cl]     # parity forbid unit
        self.assertEqual(len(loci), g1, f"parity conflict loci {loci}")
        self.assertFalse(TestSatC5Subset._up_ok(cnf.cl, []))   # UNSAT by UP

    def test_rhythm_kwtest_conflicts_at_exactly_2_loci_and_up_unsat(self):
        g2 = solve.r11_axes(KW)[1]
        cnf, Y = sat.build("rhythm-kwtest")
        cl = set(map(tuple, cnf.cl))
        loci = [s for s in range(1, 31)                  # KW adjacency forbidden
                if (-Y[(s, self._kw_j(s))], -Y[(s + 1, self._kw_j(s + 1))]) in cl]
        self.assertEqual(len(loci), g2, f"rhythm conflict loci {loci}")
        self.assertFalse(TestSatC5Subset._up_ok(cnf.cl, []))   # UNSAT by UP

    def test_derived_tables_match_solve_on_kw(self):
        # encoder-table replica of the clause semantics reproduces solve.r11_axes
        # on the KW arrangement (the tables themselves are probed out of
        # solve.r11_axes at sat import, with 300 randomized endorsements there)
        kw_arrangement = [(p, 0) for p in range(1, 32)]
        self.assertEqual(sat._moore_predict(kw_arrangement), (2, 2))
        self.assertEqual(sum(sat.MOORE_COUNTED.values()), 18)

    def test_sat_c4_pins_the_oriented_form(self):
        # 2026-08-01: --sat-c4 pinned hexagram 0 (Kun) at position 0 — the COMPLEMENT of
        # SPECIFICATION.md C4 (s0 = 63 Qian, s1 = 0 Kun). The decisive test is that the
        # pinned orientation must be one KING WEN ITSELF satisfies; the old pin excluded it.
        partner = solve._sat_partner_map()
        self.assertEqual(partner[63], 0)          # Qian's partner is Kun
        self.assertEqual((KW[0], KW[1]), (63, 0))  # C4's oriented form, from the sequence
        # the unit clauses the encoder emits must be satisfied by KW's own opening
        self.assertEqual(solve._sat_var(0, KW[0]), solve._sat_var(0, 63))
        self.assertEqual(solve._sat_var(1, partner[63]), solve._sat_var(1, KW[1]))

    def test_verify_seq_rescores_literature_rules(self):
        # F-1: the decoded-witness round-trip re-scores Moore parity, Moore
        # rhythm AND Schulz gender via solve.py scorers (not just C1/C2/C3/C5)
        ok, c3, scores = sat.verify_seq(KW)
        self.assertTrue(ok)
        self.assertEqual(c3, 776)
        self.assertEqual(scores, (2, 2, 2))


class TestVerifyRecordsPath(unittest.TestCase):
    """A3 (2026-08-01): guard the independent records verifier against the three
    drift defects an adversarial audit found in it. verify.py is deliberately
    independent of solve.py/roae.py/sat.py, so it is loaded here on its own.

    The load itself exercises the new import-time table gate: verify.py refuses
    to import unless PAIRS equals the partner()-derived canonical pairing, KW is
    a permutation, the difference-wave multiset equals SPECIFICATION.md C5's
    literal, and cd(KW) = 776. Without that gate the reference tables would be
    self-verifying (all derived from the same KW literal they check against)."""

    @classmethod
    def setUpClass(cls):
        cls.V = _load("verify")
        cls.PIDX = {frozenset(p): i for i, p in enumerate(cls.V.PAIRS)}

    def _encode(self, seq):
        out = bytearray()
        for i in range(32):
            a, b = seq[2 * i], seq[2 * i + 1]
            p = self.PIDX[frozenset((a, b))]
            out.append((p << 2) | ((0 if self.V.PAIRS[p] == (a, b) else 1) << 1))
        return bytes(out)

    def _counts(self, rec):
        import struct, tempfile, os
        blob = b"ROAE" + struct.pack("<I", 1) + struct.pack("<Q", 1) + b"\0" * 16 + rec
        fd, path = tempfile.mkstemp(suffix=".bin")
        try:
            os.write(fd, blob); os.close(fd)
            return self.V.verify_chunk((path, 0, 1))
        finally:
            os.unlink(path)

    def test_king_wen_passes_every_check(self):
        r = self._counts(self._encode(self.V.KW))
        for k, v in r.items():
            if k.startswith("fail_"):
                self.assertEqual(v, 0, f"KW itself failed {k}")
        self.assertTrue(r["kw_found"])

    def test_complement_of_kw_fails_c4_and_only_c4(self):
        # The 2026-07-26 retraction case. comp(KW) satisfies C1, C2, C3 and C5
        # exactly (complementation x -> x^63 is an exact symmetry of that
        # system, machine-checked in lean/KingWen.lean), so ONLY the oriented
        # form of C4 can reject it. A verifier testing just the pair index would
        # print VERIFY PASS on a spec-violating record.
        r = self._counts(self._encode([h ^ 63 for h in self.V.KW]))
        self.assertEqual(r["fail_c4"], 1, "oriented C4 did not reject comp(KW)")
        for k in ("fail_c1", "fail_c2", "fail_c3", "fail_c5", "fail_decode", "fail_fmt"):
            self.assertEqual(r[k], 0, f"comp(KW) unexpectedly failed {k}")

    def test_reserved_bit0_is_rejected(self):
        # SOLUTIONS_FORMAT.md: "bit 0: unused, always 0". Masked out of the
        # canonical sort key (& 0xFC) but live in the full-byte dedup tie-break,
        # so a set bit 0 breaks byte-exact reproducibility.
        rec = bytearray(self._encode(self.V.KW))
        rec[7] |= 1
        r = self._counts(bytes(rec))
        self.assertEqual(r["fail_fmt"], 1)
        for k in ("fail_c1", "fail_c2", "fail_c3", "fail_c4", "fail_c5"):
            self.assertEqual(r[k], 0)

    def _run_main(self, blob, flags=()):
        import tempfile, os
        fd, path = tempfile.mkstemp(suffix=".bin")
        try:
            os.write(fd, blob); os.close(fd)
            return subprocess.run([sys.executable, "verify.py", path, *flags],
                                  capture_output=True, text=True)
        finally:
            os.unlink(path)

    def _wrap(self, rec, reserved=b"\0" * 16):
        import struct
        return b"ROAE" + struct.pack("<I", 1) + struct.pack("<Q", 1) + reserved + rec

    def test_header_reserved_bytes_must_be_zero(self):
        # SOLUTIONS_FORMAT.md: header bytes 16-31 "MUST be zero". Counted as a
        # format failure rather than a hard exit, so the record-level verdicts
        # are still reported alongside it.
        kw = self._encode(self.V.KW)
        self.assertEqual(self._run_main(self._wrap(kw)).returncode, 0)
        r = self._run_main(self._wrap(kw, b"\0" * 15 + b"\x01"))
        self.assertEqual(r.returncode, 1)
        self.assertIn("header reserved bytes NONZERO", r.stdout)

    def test_expect_kw_promotes_kw_presence_to_a_failure(self):
        # Default stays informational: an individual shard need not contain KW.
        comp = self._encode([h ^ 63 for h in self.V.KW])
        kw = self._encode(self.V.KW)
        self.assertEqual(self._run_main(self._wrap(kw), ["--expect-kw"]).returncode, 0)
        r = self._run_main(self._wrap(comp), ["--expect-kw"])
        self.assertEqual(r.returncode, 1)
        self.assertIn("VERIFY FAIL: 2 issues", r.stdout)   # C4 + missing KW

    def test_orientation_fiber_matches_tr1(self):
        # A7: TR-1 §7's dispositive null. Recomputed by transfer DP over KW's own pair
        # order, with the boundary budget re-derived from KW rather than copied.
        V = self.V
        B0, F, Bk = V._fiber_dp()
        self.assertEqual(B0, (2, 8, 13, 7, 1))
        tot = {}
        for (last, bud, opening), cnt in F[1].items():
            tot[opening] = tot.get(opening, 0) + cnt * Bk[1].get((last, bud), 0)
        self.assertEqual(tot.get(63, 0), 1_720_320)   # C4 as defined
        self.assertEqual(tot.get(0, 0), 983_040)      # pair-only C4, flipped opening
        self.assertEqual(sum(tot.values()), 2_703_360)
        self.assertEqual(3 * 5 * 7 * 2 ** 14, 1_720_320)

    # ---- A1 (2026-08-01): the orientation-fiber factor -------------------
    # fiber_count() generalises the fiber from King Wen's own ordering to an
    # ARBITRARY C1 ordering, which is what converts deduped RECORDS into
    # orientation-explicit SEQUENCES. It is the instrument behind
    # A1_ORIENTATION_FIBER_MEASUREMENT.md, so it is gated four ways: against
    # TR-1 §7's published values, against the pre-existing _fiber_dp
    # instrument, against explicit brute force, and on its own algebra.

    # ---- the anchor and the instrument, written FIRST (2026-08-02) -------
    # The five tests below gate the GATE. They come first deliberately: the
    # 2026-08-02 rewrite exists because a fiber routine returned 2,703,360
    # against TR-1 §7's 1,720,320, and because the attempt before it hung an
    # 8 GB orchestrator on a DP whose state key carried the orientation
    # vector (2^32 keys). Both failures are pinned here as known answers.

    def test_the_fiber_anchor_gate_fires_on_its_own_motivating_example(self):
        # INSTRUMENT GATE. A gate that only asserted "== 1,720,320" would have
        # caught the defect while saying nothing useful about it. The verdict
        # this classifier must produce is "one unpinned bit (C4's opening)",
        # NOT "the constraint set is too loose" — C3 is constant on a fiber, so
        # C3 can only ever multiply a fiber count by 1 or by 0, never by 7/11.
        V = self.V
        verdict, why = V._fiber_diagnose(2_703_360)
        self.assertEqual(verdict, "C4-OPENING-NOT-PINNED")
        self.assertIn("11/7", why)                   # the REASON, not just the verdict
        self.assertIn("pin the opening", why.lower())
        # it must ACCEPT the right answer, or it is a rubber stamp
        self.assertEqual(V._fiber_diagnose(1_720_320)[0], "OK")
        # it must DISCRIMINATE, or the verdict carries no information: three
        # other wrong answers each get their own distinct classification.
        self.assertEqual(
            [V._fiber_diagnose(x)[0] for x in (983_040, 3_440_640, 0, 1_234_567)],
            ["OPENING-PINNED-TO-THE-WRONG-SIDE", "SYMMETRY-DOUBLED",
             "EMPTY-FIBER", "UNCLASSIFIED"])

    def test_fiber_count_refuses_to_answer_when_the_anchor_breaks(self):
        # Proof that the anchor is ON the call path rather than decorative:
        # replace the DP with the historical defect (both openings summed) and
        # the PUBLIC entry point must raise, naming the unpinned opening,
        # before it returns anything at all.
        V = self.V
        saved_raw, saved_memo = V._fiber_count_raw, V._FIBER_ANCHOR
        try:
            V._FIBER_ANCHOR = None
            V._fiber_count_raw = lambda perm, opening=63, fixed=None: 2_703_360
            with self.assertRaises(RuntimeError) as cm:
                V.fiber_count(list(range(32)), 63)
            self.assertIn("C4-OPENING-NOT-PINNED", str(cm.exception))
            self.assertIn("11/7", str(cm.exception))
        finally:
            V._fiber_count_raw, V._FIBER_ANCHOR = saved_raw, saved_memo

    def test_the_11_over_7_signature_is_exact_integer_arithmetic(self):
        # The verdict above rests on two exact identities, checkable by hand and
        # pinned here as integers so no later edit can soften them into
        # approximations. In units of 2**14 the three fibers are 105, 60, 165.
        self.assertEqual(1_720_320, 105 * 2 ** 14)
        self.assertEqual(983_040, 60 * 2 ** 14)
        self.assertEqual(2_703_360, 165 * 2 ** 14)
        self.assertEqual(7 * 983_040, 4 * 1_720_320)       # flipped/oriented =  4/7
        self.assertEqual(7 * 2_703_360, 11 * 1_720_320)    # both/oriented    = 11/7
        # the complement-Z2 "doubling" answer is a DIFFERENT number, so the two
        # failure modes can never be mistaken for one another
        self.assertNotEqual(2 * 1_720_320, 2_703_360)

    def test_the_state_space_arithmetic_in_the_header_is_the_real_one(self):
        # The header's numbers are load-bearing — they are the entire reason
        # this DP is safe to run — so they are pinned against the live tables.
        V = self.V
        B0, _ham, _ci, _add, _fc = V._fiber_tables()
        self.assertEqual(B0, (2, 8, 13, 7, 1))
        # sum(B0) == 31 is what makes 64*6048 bound the WHOLE RUN rather than a
        # single slot: the budget's sum IS the slot index, so slot is not a free
        # dimension of the state. If this ever changes, the header's arithmetic
        # (and the safety argument that rests on it) must be rewritten.
        self.assertEqual(sum(B0), 31)
        code = 1
        for c in B0:
            code *= (c + 1)
        self.assertEqual(code, 6048)                       # 3*9*14*8*2
        self.assertEqual(64 * code, 387_072)               # whole-run state bound
        self.assertLessEqual(code, 1 << V._FIBER_CODE_BITS)
        # the formulation that hung the box, for contrast — never a state count
        self.assertEqual(sum(2 ** i for i in range(32)), 2 ** 32 - 1)

    def test_c3_is_evaluated_without_the_path(self):
        # C3 couples each pair to the pair holding its complement, so it is a
        # GRAPH over pairs, not a chain over slots. It still needs no DP state:
        # the orientation bits cancel, leaving C3 a function of the slot map.
        # Anchor first — King Wen's own ordering is the identity permutation and
        # its C3 is 776 (SPECIFICATION.md §C3: 12.125 x 64).
        V = self.V
        self.assertEqual(V.c3_of_ordering(list(range(32))), 776)
        cross, selfc = V._c3_couples()
        self.assertEqual((len(cross), len(selfc)), (12, 8))
        self.assertEqual(2 * len(cross) + len(selfc), 32)
        # Cross-check against the INDEPENDENT path: compute_comp_dist works only
        # on an assembled 64-hexagram sequence and knows nothing about couples,
        # slots or the 16 + 8*G decomposition. They must agree on shuffled
        # orderings AND under every orientation vector — the latter is what
        # "constant on a fiber" means, and it is the claim the DP depends on.
        import random
        rng = random.Random(20260802)
        for trial in range(12):
            perm = list(range(32))
            rng.shuffle(perm)
            path_free = V.c3_of_ordering(perm)
            for mode in (0, 1, 2):
                seq = []
                for s, p in enumerate(perm):
                    a, b = V.PAIRS[p]
                    flip = (mode == 1) or (mode == 2 and s % 3 == 0)
                    seq += [b, a] if flip else [a, b]
                self.assertEqual(path_free, V.compute_comp_dist(seq),
                                 f"trial {trial} orientation-mode {mode}: the path-free "
                                 f"C3 disagrees with the assembled-sequence value")

    def _brute_subfiber(self, perm, fixed, free_slots, with_c3):
        """Explicit enumeration over `free_slots`, checking C2/C5 (and optionally
        C3) on the assembled 64-hexagram sequence. Shares no machinery with the
        DP: no budget codes, no transfer states, no B0 — it just builds each
        sequence and tests the published constraints on it."""
        V = self.V
        target = tuple(V.KW_DIST)
        good = 0
        for m in range(1 << len(free_slots)):
            o = dict(fixed)
            o[0] = 0                             # C4 as defined: slot 0 opens (63, 0)
            for t, s in enumerate(free_slots):
                o[s] = (m >> t) & 1
            seq = []
            for i in range(32):
                a, b = V.PAIRS[perm[i]]
                seq += [a, b] if o[i] == 0 else [b, a]
            d, bad = [0] * 7, False
            for i in range(63):
                h = bin(seq[i] ^ seq[i + 1]).count("1")
                if h == 5:                       # C2
                    bad = True
                    break
                d[h] += 1
            if bad or tuple(d) != target:        # C5
                continue
            if with_c3 and V.compute_comp_dist(seq) > 776:
                continue
            good += 1
        return good

    def test_fiber_count_reproduces_the_tr1_published_values(self):
        # THE mandated gate: the generalised routine must return exactly
        # 1,720,320 on King Wen's own pair ordering. TR-1 §7 states that value,
        # its 3*5*7*2^14 factorization, and the two companion fiber sizes.
        V = self.V
        ident = list(range(32))
        self.assertEqual(V.fiber_count(ident, 63), 1_720_320)
        self.assertEqual(V.fiber_count(ident, 0), 983_040)
        self.assertEqual(V.fiber_count(ident, 63) + V.fiber_count(ident, 0), 2_703_360)
        self.assertEqual(V.fiber_count(ident, 63), 3 * 5 * 7 * 2 ** 14)

    def test_fiber_count_agrees_with_the_independent_fiber_dp(self):
        # Two implementations, written in different passes: _fiber_dp is a
        # forward+backward transfer DP keyed on (last, budget-tuple) over KW's
        # own order; fiber_count is a forward-only DP on packed mixed-radix
        # budget codes over an arbitrary order. They must land on the same
        # integers for the one ordering both can do.
        V = self.V
        _B0, F, Bk = V._fiber_dp()
        tot = {}
        for (last, bud, opening), cnt in F[1].items():
            tot[opening] = tot.get(opening, 0) + cnt * Bk[1].get((last, bud), 0)
        ident = list(range(32))
        self.assertEqual(V.fiber_count(ident, 63), tot.get(63, 0))
        self.assertEqual(V.fiber_count(ident, 0), tot.get(0, 0))

    def test_fiber_count_matches_explicit_brute_force(self):
        # The DP never assembles a sequence; the brute force never uses a
        # budget. Freeze all but a 10-slot window at King Wen's own orientation
        # and enumerate that window explicitly (1,024 sequences), checking C2 and
        # C5 directly on each assembled 64-hexagram sequence. Three windows —
        # head, middle, tail — so every stretch of the transfer path is covered.
        # Each window admits far fewer than 1,024, so acceptance AND rejection
        # are both exercised rather than a vacuous all-pass.
        V = self.V
        ident = list(range(32))
        for free in (list(range(1, 11)), list(range(11, 21)), list(range(22, 32))):
            fixed = {i: 0 for i in range(1, 32) if i not in free}
            brute = self._brute_subfiber(ident, fixed, free, with_c3=False)
            self.assertGreater(brute, 0,
                               f"window {free[0]}-{free[-1]}: KW's own vector must be in it")
            self.assertLess(brute, 1 << len(free),
                            f"window {free[0]}-{free[-1]}: nothing was rejected, "
                            f"so the test cannot discriminate")
            self.assertEqual(V.fiber_count(ident, 63, fixed=fixed), brute,
                             f"DP and brute force disagree on window {free[0]}-{free[-1]}")

    def test_c3_is_constant_on_a_fiber(self):
        # The load-bearing claim behind "the fiber is a C2+C5 object": C3 is
        # orientation-BLIND (C3 = 16 + 8*G, G a function of slot placement only),
        # so adding the C3 <= 776 filter to the brute force must not remove a
        # single member. If it did, fiber_count would be counting the wrong set.
        V = self.V
        ident = list(range(32))
        fixed = {i: 0 for i in range(1, 22)}
        free = list(range(22, 32))
        self.assertEqual(self._brute_subfiber(ident, fixed, free, with_c3=True),
                         self._brute_subfiber(ident, fixed, free, with_c3=False))
        # ... and directly: C3 is literally constant across orientation vectors
        vals = set()
        for m in range(32):
            seq = []
            for i in range(32):
                a, b = V.PAIRS[i]
                seq += [a, b] if (i == 0 or not (m >> (i % 5)) & 1) else [b, a]
            vals.add(V.compute_comp_dist(seq))
        self.assertEqual(vals, {776}, "C3 moved under an orientation flip")

    def test_fiber_count_partitions_over_a_free_bit(self):
        # Algebraic self-consistency the published values cannot supply: the
        # fiber splits exactly over any one slot's orientation, and slot 30 is
        # the one additionally forced bit TR-1 §7 names (one side must be empty).
        V = self.V
        ident = list(range(32))
        whole = V.fiber_count(ident, 63)
        for slot in (1, 7, 17, 30):
            halves = [V.fiber_count(ident, 63, fixed={slot: o}) for o in (0, 1)]
            self.assertEqual(sum(halves), whole, f"slot {slot} does not partition")
        self.assertEqual(V.fiber_count(ident, 63, fixed={30: 1}), 0,
                         "TR-1 §7 says slot 30 is forced on the C4-oriented fiber")

    def test_the_two_redundancies_in_the_fiber_dp_are_real(self):
        # Mutation testing (2026-08-01) showed two edits to fiber_count that do
        # NOT change any answer. Both are genuine redundancies, not test gaps,
        # and they are pinned here so nobody later "fixes" a passing mutant:
        #
        #  (i) C2 is IMPLIED by C5 at the sequence level. C5 pins the whole
        #      63-distance multiset to King Wen's, which contains no 5, so a
        #      C5-satisfying sequence cannot contain a 5-transition. C2 is a
        #      pruning device for the search, not an extra filter on the fiber.
        #  (ii) the exact-budget landing test at the end of the DP is free: 31
        #      boundaries get placed, each class is capped at B0, and the caps
        #      sum to 31, so any survivor already sits exactly on B0.
        V = self.V
        B0, _ham, clsidx, _add, _fc = V._fiber_tables()
        self.assertEqual(V.KW_DIST[5], 0, "C5 admits a 5-transition; (i) no longer holds")
        self.assertEqual(sum(B0), 31, "caps no longer sum to the boundary count; (ii) fails")
        self.assertEqual(clsidx[5], -1)
        self.assertEqual(clsidx[0], -1)

    def test_fiber_count_rejects_malformed_orderings(self):
        V = self.V
        with self.assertRaises(ValueError):
            V.fiber_count(list(range(31)), 63)            # not 32 slots
        with self.assertRaises(ValueError):
            V.fiber_count([0] * 32, 63)                   # not a permutation
        bad = list(range(32)); bad[0], bad[5] = bad[5], bad[0]
        with self.assertRaises(ValueError):
            V.fiber_count(bad, 63)                        # C4 pair not at slot 0
        with self.assertRaises(ValueError):
            V.fiber_count(list(range(32)), 17)            # opening not in the pair

    def test_every_real_record_has_a_nonempty_fiber(self):
        # A record exists because some orientation vector satisfied C1-C5, so
        # its own stored orientation is a member of its fiber and no record may
        # count 0. This checks fiber_count's SEMANTICS on real orderings, which
        # the King Wen gate alone cannot: KW's ordering is a single point.
        import os
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "solutions.bin")
        if not os.path.exists(path):
            self.skipTest("no solutions.bin sample in the repo")
        V = self.V
        seen = 0
        for i, perm, orient in V._fiber_records(path, limit=400):
            self.assertGreater(V.fiber_count(perm, 63), 0,
                               f"record {i} has an empty fiber but exists")
            # the stored orientation is not merely countable, it is IN the fiber
            self.assertEqual(V.fiber_count(perm, 63,
                                           fixed={s: orient[s] for s in range(1, 32)}), 1)
            seen += 1
        self.assertGreater(seen, 0)

    def test_gender_null_exact_reproduces_tr8(self):
        # A8: TR-8 §Commands' exact pair-null gender figure. Until now both
        # implementations of P(rc4_violations <= 2) = 47/445740 lived in
        # solve.py; verify.py rebuilds the functional from the published
        # definition (SOLVE_C_CLI.md §--rc4b-verify) and solves the 32!·2^32
        # pair-only null exactly (closed form + slot DP, cross-asserted).
        from fractions import Fraction
        import io, contextlib
        V = self.V
        # published KW anchors gate the reading of the definition
        self.assertEqual(V._rc4_violations_indep(V.KW), (2, [25, 26]))
        # ... and the definition must actually discriminate: swapping the
        # adjacent pair-blocks whose classes sit at positions 25/26 (the
        # Zhu Yuansheng/Schulz exception locus; the adjacent-pair swap of the
        # published 3-edit repair) removes BOTH violations — the third edit of
        # that repair (an orientation flip) repairs C-validity, not gender
        repaired = list(V.KW)
        repaired[42:44], repaired[44:46] = V.KW[44:46], V.KW[42:44]
        self.assertEqual(V._rc4_violations_indep(repaired), (0, []))
        dist = V._gender_null_distribution()
        self.assertEqual(sum(dist.values()), 1)
        self.assertEqual(sum(p for v, p in dist.items() if v <= 2),
                         Fraction(47, 445740))
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            self.assertEqual(V.recount_gender_null(), 0)
        self.assertIn("47/445740", buf.getvalue())
        self.assertIn("ALL MATCH", buf.getvalue())

    def test_pair_orbits_are_derived_not_trusted(self):
        # A9: _ORBITS was transcribed from TR-11 §3. It is now cross-checked against
        # the orbit partition derived from verify.py's own 48 commuting bit-perms.
        V = self.V
        derived = {tuple(o) for o in V._derive_pair_orbits()}
        self.assertEqual(derived, {tuple(sorted(v)) for v in V._ORBITS.values()})
        self.assertEqual(sorted(i for o in derived for i in o), list(range(1, 32)))
        # and the gate must actually reject a corrupted table
        saved = V._ORBITS
        try:
            bad = {k: list(v) for k, v in saved.items()}
            bad["3.0"] = [3, 7, 12]           # 11 -> 12: breaks the orbit, keeps the size
            V._ORBITS = bad
            with self.assertRaises(RuntimeError):
                V._verify_orbits_against_group()
        finally:
            V._ORBITS = saved
        V._verify_orbits_against_group()      # real table still passes

    def test_table_gate_catches_a_corrupted_kw_table(self):
        # Fixture chosen so that ONLY the C5-multiset gate can catch it:
        # swapping pair-blocks 1 and 2 leaves cd exactly 776 (so the pre-existing
        # C3 assert is blind), leaves the pairing SET unchanged (so the C1
        # partner gate is blind), and introduces no d=5 transition (so a C2-style
        # check is blind). The difference-wave multiset becomes
        # {1:3, 2:19, 3:12, 4:20, 6:9} != SPECIFICATION.md C5's literal.
        V = self.V
        bad = list(V.KW)
        bad[2:4], bad[4:6] = bad[4:6], bad[2:4]
        saved_kw, saved_pairs, saved_dist = V.KW, V.PAIRS, V.KW_DIST
        try:
            V.KW = bad
            V.PAIRS = [(bad[2 * i], bad[2 * i + 1]) for i in range(32)]
            V.KW_DIST = [0] * 7
            for i in range(63):
                V.KW_DIST[bin(bad[i] ^ bad[i + 1]).count("1")] += 1
            self.assertEqual(V.compute_comp_dist(bad), 776,
                             "fixture invalid: this corruption should preserve cd")
            with self.assertRaises(RuntimeError):
                V._verify_tables_against_rules()
        finally:
            V.KW, V.PAIRS, V.KW_DIST = saved_kw, saved_pairs, saved_dist
        V._verify_tables_against_rules()   # the real tables still pass


class TestSubtreeCrossAnchors(unittest.TestCase):
    """Fast tier of verify.py's --recount-subtree gate (wired 2026-08-06).

    verify._exact_subtree is the only independent instrument in the project
    that exercises the C3 predicate in BOTH directions (false-positive and
    false-negative) — every full-scale two-instrument check is C3-free by
    scope — yet until now its driver was manual-only, absent from this
    harness and from verify_all.sh.  This class runs the sub-second anchors
    on every `python3 tests.py`: the KW 5-free/7-free anchors (TR-5 §3
    published values) plus the three away-from-KW cross-anchors whose
    expectation tuples were computed by the OTHER instrument, solve.c
    --estimate-knuth 0 (exact deterministic mode; provenance, prefix-
    convention validation, and the `ulimit -s 9216` requirement for
    reproducing them are documented at verify._CROSS_PREFIXES).  The ~55 s
    anchors — the two 9.4M-node 9-free trees, including TR-4 §4's
    "exactly 8" C6/C7 count — are deliberately NOT run here (they would
    quintuple this 11 s suite); the full set runs as
    `python3 verify.py --recount-subtree`, wired into
    reports/certificates/verify_all.sh §2.  Measured cost here: ~0.8 s."""

    @classmethod
    def setUpClass(cls):
        cls.V = _load("verify")

    def test_kw_anchors_5_and_7_free(self):
        # TR-5 §3 / SEARCH_SPACE_SIZE.md published values (also corroborated
        # by README.md's 16,504-completions paragraph at the 9-free rung,
        # which stays in the verify_all.sh tier).
        V = self.V
        nodes, _l, canon, _x = V._exact_subtree([(i, 0) for i in range(1, 27)])
        self.assertEqual((nodes, canon), (443, 4))
        nodes, _l, canon, _x = V._exact_subtree([(i, 0) for i in range(1, 25)])
        self.assertEqual((nodes, canon), (62256, 2232))

    def test_cross_anchors_match_solve_c_exact(self):
        # The genuine cross-check: verify.py's clean-room walk must land on
        # the 4-tuples solve.c's exact mode produced for the same prefixes.
        # A perturbed expectation (or a drifted walk) fails this directly.
        V = self.V
        self.assertEqual(len(V._CROSS_PREFIXES), 3)
        for name, pfx, want in V._CROSS_PREFIXES:
            self.assertEqual(len(pfx), 24, name)   # depth 24 = 7 free slots
            self.assertEqual(V._exact_subtree(pfx), want, name)

    def test_cross_anchors_cover_c3_both_directions(self):
        # The coverage claim is asserted, not narrated: the anchor set must
        # contain an all-canonical subtree (C3 comfortably below 776 — the
        # false-negative direction), a zero-canonical subtree with nonzero
        # leaves (C3 clearly above — the false-positive direction), and a
        # discriminating subtree (0 < canon < leaves at the threshold).
        # If an anchor is ever swapped out, the replacement must preserve
        # this partition or this test fails.
        kinds = set()
        for name, _pfx, (_n, leaves, canon, _x) in self.V._CROSS_PREFIXES:
            self.assertGreater(leaves, 0, name)
            kinds.add("all-pass" if canon == leaves else
                      "all-fail" if canon == 0 else "straddle")
        self.assertEqual(kinds, {"all-pass", "all-fail", "straddle"})


if __name__ == "__main__":
    unittest.main(verbosity=2)
