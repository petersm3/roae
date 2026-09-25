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
import gzip  # gz-framing equivalence fixture (V2-F48 #4)
import os, random, re, shutil, signal, struct, tempfile, hashlib

def _load(name):
    spec = importlib.util.spec_from_file_location(name, name + ".py")
    m = importlib.util.module_from_spec(spec)
    argv, sys.argv = sys.argv, [name + ".py"]
    try:
        spec.loader.exec_module(m)
    finally:
        sys.argv = argv
    return m

def _emit_token(key, value):
    """Print one `KEY=value` verdict line that OWNS its line.

    C4 (2026-09-02), MEASURED not reasoned: unittest writes each test's name to
    stderr WITHOUT a trailing newline, so under the harness's own
    `python3 tests.py 2>&1` a bare `print("KEY=1")` can be appended to that
    progress line — `PERM_NCYC_P2=0.30386238` was observed glued to the end of
    `test_c3_and_c5_contribute_no_clauses_and_the_header_says_so ... `. The line
    still CONTAINS the token, so every substring grep stays green while
    `grep -qx` — the whole-line form this project requires — silently never
    matches. The leading newline is what makes the whole-line assertion true;
    the flushes keep the two streams from re-interleaving on the next write."""
    sys.stderr.flush()
    sys.stdout.write(f"\n{key}={value}\n")
    sys.stdout.flush()

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


class TestTr8DofSampler(unittest.TestCase):
    """The TR-8 dof-matched KW-fitting-predicate sampler (solve.py --tr8-dof-sampler).

    These are the pre-registration's §4.4 self-test obligations as standing regressions. They
    test the INSTRUMENT; none of them is a measurement of anything, and none of the numbers
    here is citable. The full instrument gate — including determinism and shard/merge
    equivalence at a slightly larger scale — is `python3 solve.py --tr8-dof-selftest`."""

    SEED = "TR8-TESTS-THROWAWAY"

    def test_bank_integrity(self):
        # B_raw is fully determined by the frozen family table; a drift in either direction is
        # a bug, not a new bank. 36+64+32+63+32+15+8+64+5 = 319.
        bank = solve.tr8_clause_bank()
        self.assertEqual(len(bank), 319)
        self.assertEqual(solve.TR8_B_RAW, 319)
        for fam, n in solve._TR8_FAMILY_SIZES:
            self.assertEqual(sum(1 for e in bank if e[0] == fam), n, fam)
        # Bank order is the evaluation order — if these ever diverge every marginal is
        # attributed to the wrong template and nothing downstream would notice.
        self.assertEqual(len(solve.tr8_clause_values(KW)), len(bank))

    def test_h_a_king_wen_satisfies_every_template(self):
        # H-a: every clause is instantiated at King Wen's own value, so King Wen satisfies
        # every predicate drawn from any subset of the bank BY CONSTRUCTION. A single failure
        # is a first-order implementation finding, not a result.
        v = solve.tr8_clause_values(KW)
        self.assertTrue(all(v), [i for i, x in enumerate(v) if not x][:8])

    def test_pair_null_draw_is_c1_preserving(self):
        import random
        pairs = solve.king_wen_pairs()
        rng = random.Random(20260811)
        for _ in range(300):
            s = solve.pair_null_draw(rng, pairs)
            self.assertEqual(sorted(s), list(range(64)))
            for i in range(32):
                a, b = s[2 * i], s[2 * i + 1]
                self.assertTrue((a, b) in pairs or (b, a) in pairs)

    def test_h_b_null_calibration_tail(self):
        # H-b, the pre-registration's named tests.py regression: the sampler's own pair-only
        # null draw generator must reproduce pair_null_gender_le2_exact() = 47/445740 within
        # Poisson error, scored by the UNMODIFIED rc4_violations. At 1e5 draws the expectation
        # is ~10.5 hits, so this tail check is weak on its own — which is exactly why the
        # distribution check below exists beside it.
        import random
        rng = random.Random(20260811)
        pairs = solve.king_wen_pairs()
        n = 100000
        hits = sum(1 for _ in range(n)
                   if solve.rc4_violations(solve.pair_null_draw(rng, pairs))[0] <= 2)
        exp = float(solve.pair_null_gender_le2_exact()) * n
        self.assertLess(abs(hits - exp), 5.0 * exp ** 0.5 + 3.0,
                        "observed %d, expected %.2f" % (hits, exp))

    def test_h_b_violation_distribution_matches_closed_form(self):
        # The strong form of H-b: the whole violation-count distribution, not just its tail.
        # This is what actually proves the pool is the same null the exact DP models.
        import random
        rng = random.Random(7)
        pairs = solve.king_wen_pairs()
        n = 20000
        obs = {}
        for _ in range(n):
            v = solve.rc4_violations(solve.pair_null_draw(rng, pairs))[0]
            obs[v] = obs.get(v, 0) + 1
        worst = 0.0
        checked = 0
        for v, p in solve.pair_null_gender_distribution_exact().items():
            e = float(p) * n
            if e < 25:            # normal approximation is not trustworthy below this
                continue
            checked += 1
            worst = max(worst, abs(obs.get(v, 0) - e) / e ** 0.5)
        self.assertGreater(checked, 5)     # vacuous if the closed form ever returns nothing
        self.assertLess(worst, 5.0, "worst |z| = %.2f" % worst)

    def test_clopper_pearson_matches_closed_form(self):
        # x = 0 and x = n have closed forms: 1 - (alpha/2)^(1/n) and (alpha/2)^(1/n). The
        # interior values are the standard published Clopper-Pearson intervals.
        lo, hi = solve.tr8_clopper_pearson(0, 10)
        self.assertEqual(lo, 0.0)
        self.assertAlmostEqual(hi, 1 - 0.025 ** 0.1, places=9)
        lo, hi = solve.tr8_clopper_pearson(10, 10)
        self.assertAlmostEqual(lo, 0.025 ** 0.1, places=9)
        self.assertEqual(hi, 1.0)
        self.assertEqual([round(x, 4) for x in solve.tr8_clopper_pearson(5, 10)],
                         [0.1871, 0.8129])
        self.assertEqual([round(x, 4) for x in solve.tr8_clopper_pearson(2, 20)],
                         [0.0123, 0.3170])

    def test_median_ci_ranks_are_computed_not_hardcoded(self):
        # n = 10: P(Bin<=1) = 11/1024 = 0.0107 <= 0.025 and P(Bin<=2) = 56/1024 > 0.025, so
        # L = 2; P(Bin<=8) = 1013/1024 = 0.9893 >= 0.975 so U = 9 — the textbook sign-test
        # interval [x(2), x(9)]. n = 1000 is the pre-registered N_pred.
        self.assertEqual(solve.tr8_median_ci_ranks(10), (2, 9))
        self.assertEqual(solve.tr8_median_ci_ranks(1000), (469, 532))

    def test_determinism_and_shard_merge_equivalence(self):
        # Identical seed root => byte-identical header and identical statistics; and running
        # the pool as separate shards then merging must equal the single-process run exactly
        # (hits are additive across shards because every shard scores the same ensemble).
        import json, os, tempfile
        kl = (4, 8)
        with tempfile.TemporaryDirectory() as td:
            a, b, c = (os.path.join(td, x) for x in "abc")
            for d in (a, b):
                solve.tr8_dof_sampler(d, seed_root=self.SEED, n_pool=1024, n_pred=25,
                                      klist=kl, n_shards=2, calib_draws=1500, quiet=True)
            self.assertEqual(open(os.path.join(a, "header.json"), "rb").read(),
                             open(os.path.join(b, "header.json"), "rb").read())
            ra = json.load(open(os.path.join(a, "results.json"), encoding="utf-8"))
            rb = json.load(open(os.path.join(b, "results.json"), encoding="utf-8"))
            self.assertEqual(ra["statistics"], rb["statistics"])
            for i in range(2):
                solve.tr8_dof_sampler(c, seed_root=self.SEED, n_pool=1024, n_pred=25,
                                      klist=kl, n_shards=2, shard=i, calib_draws=1500,
                                      quiet=True)
            solve.tr8_dof_merge(c, quiet=True)
            rc = json.load(open(os.path.join(c, "results.json"), encoding="utf-8"))
            self.assertEqual(rc["statistics"], ra["statistics"])
            # Every admitted marginal lies inside the frozen band, and the admitted set is a
            # subset of the raw bank.
            bank = json.load(open(os.path.join(a, "bank.json"), encoding="utf-8"))
            self.assertEqual(bank["b_raw"], 319)
            adm = [e for e in bank["bank"] if e["admitted"]]
            self.assertEqual(len(adm), bank["b_admitted"])
            self.assertLessEqual(bank["b_admitted"], bank["b_raw"])
            for e in adm:
                self.assertTrue(0.25 <= e["marginal"] <= 0.75, e)

    def test_merge_refuses_a_partial_pool(self):
        # A partial pool is a different pool. Silently reporting one would be the exact
        # failure mode the canonical-sha gates exist to prevent, so the merge must refuse.
        import os, tempfile
        with tempfile.TemporaryDirectory() as td:
            d = os.path.join(td, "p")
            solve.tr8_dof_sampler(d, seed_root=self.SEED, n_pool=1024, n_pred=10,
                                  klist=(4,), n_shards=2, shard=0, calib_draws=1500,
                                  quiet=True)
            with self.assertRaises(SystemExit):
                solve.tr8_dof_merge(d, quiet=True)


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
        # with the clear install message (roae.py Graphviz `dot` idiom), never a
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

    def test_sat_c5_tables_derived_and_guard_rejects_common_mode(self):
        # T6 (2026-09-02): sat.py's two C5 tables were hand-written literals, in breach of its own
        # header rule, and the guard between them passed a common-mode +1 (Codex V2 A08 row 13 /
        # A09 row 17). Pinned by verdict TOKENS (grep -qx semantics), never by output shape.
        r = subprocess.run([sys.executable, "sat.py", "--c5-selfcheck"], capture_output=True, text=True)
        lines = r.stdout.splitlines()
        self.assertIn("C5_LITERALS_DERIVED=1", lines, r.stdout)
        self.assertIn("GUARD_REJECTS_COMMON_MODE=1", lines, r.stdout)
        self.assertIn("GUARD_REJECTS_NON_KW=1", lines, r.stdout)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr[-300:])
        # The red test again, in-process and with the reference recomputed HERE from solve primitives
        # (no sat.py code path reused), so a common-mode edit to both module tables goes red even if
        # the subcommand's own accounting were wrong.
        from collections import Counter
        tot = dict(Counter(solve.bit_diff(KW[i], KW[i + 1]) for i in range(63)))
        between = dict(Counter(solve.bit_diff(KW[2 * i + 1], KW[2 * i + 2]) for i in range(31)))
        self.assertEqual(sat._tot, tot)
        self.assertEqual(sat.BETWEEN_MULTISET, between)
        sat.c5_tables_guard(sat._tot, sat._wp, sat.BETWEEN_MULTISET)       # the true tables pass
        bad_tot, bad_between = dict(tot), dict(between)
        bad_tot[2] += 1; bad_between[2] += 1                               # +1 on BOTH at d=2
        with self.assertRaises(AssertionError):
            sat.c5_tables_guard(bad_tot, sat._wp, bad_between)
        # and the round-trip verifier no longer shares the encoder's table (A09 row 17)
        self.assertTrue(sat.verify_seq(KW)[0])
        self.assertFalse(sat.verify_seq(KW[:2] + KW[4:6] + KW[2:4] + KW[6:])[0])

    def test_rigidity_run_reachable_and_subcommand_token_validated(self):
        # Codex V2 A08 row 18 / A09 row 20: from 2026-08-28 to 2026-09-02 the documented
        # `--rigidity-cnf OUT --run` exited 1 on the stray-flag guard with nothing written, leaving a
        # complete kissat + DRAT + drat-trim implementation unreachable. Now the CNF is written and,
        # with kissat absent, the run leg exits with the install message -- the same graceful-absence
        # contract as --witness. The kissat leg itself is not exercised here (no solver on PATH).
        import os, tempfile
        with tempfile.TemporaryDirectory() as empty:
            out = os.path.join(empty, "rig.cnf")
            env = dict(os.environ, PATH=empty)
            r = subprocess.run([sys.executable, "sat.py", "--rigidity-cnf", out, "--run"],
                               capture_output=True, text=True, env=env)
            self.assertTrue(os.path.exists(out), r.stderr[-300:])
            self.assertNotIn("unrecognised flag", r.stderr)
            self.assertIn("kissat is required for --rigidity-cnf --run", r.stderr)
            self.assertNotIn("Traceback", r.stderr)
            # --run outside --rigidity-cnf is refused, not silently dropped (the Q-309 class)
            r = subprocess.run([sys.executable, "sat.py", "--emit-cnf", "plain",
                                os.path.join(empty, "x.cnf"), "--run"], capture_output=True, text=True)
            self.assertNotEqual(r.returncode, 0)
            self.assertIn("--run applies to --rigidity-cnf only", r.stderr)
            self.assertFalse(os.path.exists(os.path.join(empty, "x.cnf")))
        # sibling (A09 row 20, limb 2): a mistyped SUBCOMMAND is an error, not help banner + rc 0
        r = subprocess.run([sys.executable, "sat.py", "--wittness", "plain"], capture_output=True, text=True)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("unrecognised flag(s): --wittness", r.stderr)


class TestSatInputGuards(unittest.TestCase):
    """Q-311: the sat.py input-surface guards must FAIL LOUDLY, not traceback or
    silently succeed. The code landed 2026-08-28 (db4ac3dc); these are the gates
    the row still owed — `each needs a gate SHOWN able to fail`.

    Each test asserts the SPECIFIC message, never merely that SystemExit was
    raised: `certify_count` can also exit with the missing-tools message
    (_CERTIFY_TOOLS_MSG), so a bare assertRaises would pass on a host without d4
    while proving nothing about the guard. Verified 2026-09-19 that the --keep
    guard fires BEFORE any tool use (sat.py:1834 precedes the d4 call at :1854),
    so these are green on a host with no SAT toolchain installed."""

    def test_keep_dir_uncreatable_is_refused_before_the_work(self):
        # The guard exists because certify_count runs d4/cpog-gen for minutes and
        # writes gigabytes; a bad --keep discovered afterwards discards the run.
        #
        # 🔴 THE ASSERTION NAMES THE SPECIFIC MESSAGE, and that is not pedantry —
        # MEASURED 2026-09-19 by mutation: with `assertIn("--keep", ...)` this test
        # SURVIVED deletion of the cannot-be-created guard, because control fell
        # through to the "exists but is not a directory" guard whose message also
        # contains "--keep". A three-guard block needs an assertion that can tell
        # the three apart, or it proves only that *some* guard fired.
        # The name says "uncreatable", not "unwritable": a read-only parent makes
        # os.makedirs raise PermissionError, which is the cannot-be-created branch.
        import stat
        with tempfile.TemporaryDirectory() as td:
            os.chmod(td, stat.S_IRUSR | stat.S_IXUSR)      # r-x: cannot create within
            try:
                with self.assertRaises(SystemExit) as cm:
                    sat.certify_count(None, "probe", keep_dir=os.path.join(td, "sub"))
                msg = str(cm.exception)
                self.assertIn("cannot be created", msg,
                              "must fail on the cannot-be-created guard specifically")
                self.assertIn("--keep", msg,
                              "and it must be the --keep guard, not the missing-tools message")
            finally:
                os.chmod(td, stat.S_IRWXU)                  # so TemporaryDirectory can clean up

    def test_start_suffix_missing_is_refused(self):
        # F1C5_UNIONS is module-level, so the malformed spec is injected and restored.
        orig = dict(sat.F1C5_UNIONS)
        try:
            sat.F1C5_UNIONS[999] = "3.0,3.1,3.2"           # no @START at all
            with self.assertRaises(SystemExit) as cm:
                sat.subset_pairlist(999)
            self.assertIn("needs an @START suffix", str(cm.exception))
        finally:
            sat.F1C5_UNIONS.clear(); sat.F1C5_UNIONS.update(orig)
        self.assertNotIn(999, sat.F1C5_UNIONS, "fixture must not leak into other tests")

    def test_start_suffix_non_integer_is_refused(self):
        orig = dict(sat.F1C5_UNIONS)
        try:
            sat.F1C5_UNIONS[999] = "3.0,3.1,3.2@x"         # @START present but not an int
            with self.assertRaises(SystemExit) as cm:
                sat.subset_pairlist(999)
            self.assertIn("@START must be an integer", str(cm.exception))
        finally:
            sat.F1C5_UNIONS.clear(); sat.F1C5_UNIONS.update(orig)

    def test_decode_missing_model_file_is_refused(self):
        # --decode is CLI-only (under `if __name__ == "__main__"`), so this one
        # must go through a subprocess; it cannot be reached via the module API.
        with tempfile.TemporaryDirectory() as td:
            missing = os.path.join(td, "no_such_model.txt")
            r = subprocess.run([sys.executable, "sat.py", "--decode", missing],
                               capture_output=True, text=True)
            self.assertNotEqual(r.returncode, 0,
                                "a missing --decode model must not exit 0")
            self.assertIn("no such file", r.stderr + r.stdout)

    def test_decode_subset_of_a_partial_or_foreign_model_is_a_verdict_not_a_traceback(self):
        # Found 2026-09-21 (Q-435) by EXECUTING SAT_CLI.md's `--decode MODEL --f1-pairs N` form
        # with a full-31 model: decode_subset() returns the slots the literals happen to hit --
        # neither empty nor 2N long -- and verify_subset() then walked N boundaries over a shorter
        # list and died with an IndexError traceback where DECODE_VERDICT=FAIL was owed. The empty
        # model was already guarded (`if seq else []`); the PARTIAL one was not. The fixture is the
        # smallest partial model there is: ONE true Y literal of the N=9 subset, so exactly one
        # slot decodes and the boundary walk over-runs at the second. Red against the pre-fix
        # verify_subset (measured at `b61f1cc9`: IndexError at sat.py:1491); green with the length guard.
        cnf, ctx = sat.build_subset(9)
        one = ctx["Y"][(ctx["slots"][0], 0)]
        with tempfile.TemporaryDirectory() as td:
            model = os.path.join(td, "partial.txt")
            with open(model, "w") as fh:
                fh.write("v %d 0\n" % one)
            r = subprocess.run([sys.executable, "sat.py", "--decode", model, "--f1-pairs", "9"],
                               capture_output=True, text=True)
            self.assertNotIn("Traceback", r.stderr + r.stdout,
                             "a model that decodes to a partial sequence must be a verdict, "
                             "not an IndexError")
            self.assertIn("DECODE_VERDICT=FAIL", r.stdout.splitlines(),
                          "a partial decode cannot pass; the verdict line must still be printed")
            self.assertEqual(r.returncode, 1, "DECODE_VERDICT=FAIL exits 1, a traceback exits 1 too "
                             "-- which is why the Traceback assertion above is the load-bearing one")
        # the guard is in verify_subset itself, so the module API shows the same shape
        ok, bnd = sat.verify_subset(sat.decode_subset([one], ctx), ctx)
        self.assertFalse(ok)
        self.assertEqual(bnd, [], "a non-2N sequence has no N-boundary walk to report")

    def test_at_least_k_over_k_is_refused_inside_the_primitive(self):
        # Q-311's fourth fixture, the one routed to the SAT lane: `at_least_k(lits, k)` with
        # k > len(lits) is an impossible cardinality. It is encoded by delegation --
        # at_most_k(-lits, n-k) -- so the bound at_most_k sees is NEGATIVE, and the guard
        # at sat.py:696 is what refuses it. That guard sits in the primitive precisely so
        # every one of the 23 call sites is covered centrally; this test pins that the
        # delegation actually reaches it. Red on a mutant with the guard deleted, MEASURED
        # 2026-09-21: the mutant dies with IndexError (`s[0][0]` over an empty counter row),
        # which is a traceback where a named refusal is owed, and this assertion does not
        # accept it.
        lits = [1, 2, 3]
        with self.assertRaises(ValueError) as cm:
            sat.at_least_k(sat.CNF(), lits, len(lits) + 1)
        self.assertIn("negative bound", str(cm.exception),
                      "the refusal must name the impossible bound, not surface as an IndexError")
        self.assertIn("k=-1", str(cm.exception), "n-k = 3-4 = -1 is the bound the primitive saw")
        # the direct form, same guard, different entry
        with self.assertRaises(ValueError):
            sat.at_most_k(sat.CNF(), lits, -1)
        # exactly_k delegates to both; over-k must be refused there too, not encoded as UNSAT
        with self.assertRaises(ValueError):
            sat.exactly_k(sat.CNF(), lits, len(lits) + 1)

    def test_cardinality_boundaries_are_encoded_not_refused(self):
        # NEGATIVE CONTROL for the guard above: the legal boundaries must pass through and
        # produce the encoding the semantics require, so the guard is shown to refuse ONLY
        # the impossible bound. Each case is asserted on the emitted clauses, not on "no
        # exception", because an encoder that silently emits nothing would also raise nothing.
        lits = [1, 2, 3]
        c = sat.CNF(); sat.at_least_k(c, lits, len(lits))       # k == n: every literal forced
        self.assertEqual(sorted(c.cl), [[1], [2], [3]],
                         "at_least_k(k=n) is at_most_k(-lits, 0): one unit clause per literal")
        c = sat.CNF(); sat.at_least_k(c, lits, 0)               # k == 0: vacuous
        self.assertEqual(c.cl, [], "at_least_k(k=0) constrains nothing")
        c = sat.CNF(); sat.at_most_k(c, lits, len(lits))        # k == n: vacuous
        self.assertEqual(c.cl, [], "at_most_k(k=n) constrains nothing")
        c = sat.CNF(); sat.at_most_k(c, lits, 0)                # k == 0: every literal forbidden
        self.assertEqual(sorted(c.cl), [[-3], [-2], [-1]],
                         "at_most_k(k=0) is one negative unit clause per literal")

    def test_guards_do_not_fire_on_valid_input(self):
        # NEGATIVE CONTROL. A gate that refuses everything is a permanent FALSE
        # dressed as rigour, so prove the guards are silent when input is good.
        self.assertIn(9, sat.F1C5_UNIONS)
        pl, start = sat.subset_pairlist(9)                  # a real, well-formed spec
        self.assertTrue(pl, "a valid union must parse to a non-empty pair list")
        with tempfile.TemporaryDirectory() as td:
            try:
                sat.certify_count(None, "probe", keep_dir=td)   # writable: guard must pass
            except SystemExit as e:
                self.assertNotIn("--keep", str(e),
                                 "a writable --keep must not trip the keep guard")
            except Exception:
                pass                                        # failing later (no d4) is expected

    def test_f1_pairs_refuses_a_target_it_would_otherwise_ignore(self):
        # Found 2026-09-21 (Q-410 description-accuracy sweep) by EXECUTING SAT_CLI.md's
        # `--emit-cnf f1c5 n13.cnf --f1-pairs 13` form with a different TARGET: the handlers call
        # build_subset(npairs) and never read TARGET, so `--emit-cnf alt-le-14 OUT --f1-pairs 13`
        # wrote a CNF byte-identical to the f1c5 one (measured: same sha256) and exited 0 -- the
        # Q-309 silent-drop class on a positional. `f1c5` is the reduced instance's only name and,
        # without --f1-pairs, is `unknown target: f1c5`; so under --f1-pairs any other TARGET is a
        # label the file would not contain. Red on a mutant with the guard deleted (MEASURED
        # 2026-09-21: the mutant emits the CNF, rc 0, no message); green with it. The assertion
        # names the specific message so the missing-tools exit cannot satisfy it by accident.
        with tempfile.TemporaryDirectory() as td:
            out = os.path.join(td, "wrong_target.cnf")
            r = subprocess.run([sys.executable, "sat.py", "--emit-cnf", "alt-le-14", out,
                                "--f1-pairs", "9"], capture_output=True, text=True)
            self.assertNotEqual(r.returncode, 0, "a TARGET that --f1-pairs ignores must not exit 0")
            self.assertIn("has no reduced form", r.stderr,
                          "the refusal must be the --f1-pairs/TARGET guard, not another exit")
            self.assertFalse(os.path.exists(out), "a refused emit must write nothing")
            # --decode's OPTIONAL third token is the same positional
            model = os.path.join(td, "m.txt")
            with open(model, "w") as fh:
                fh.write("v 1 0\n")
            r = subprocess.run([sys.executable, "sat.py", "--decode", model, "plain",
                                "--f1-pairs", "9"], capture_output=True, text=True)
            self.assertNotEqual(r.returncode, 0)
            self.assertIn("has no reduced form", r.stderr)
            # NEGATIVE CONTROL: the documented form still emits (a guard that refuses everything
            # is a permanent FALSE dressed as rigour)
            ok = os.path.join(td, "f1c5.cnf")
            r = subprocess.run([sys.executable, "sat.py", "--emit-cnf", "f1c5", ok,
                                "--f1-pairs", "9"], capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stderr[-400:])
            self.assertTrue(os.path.getsize(ok) > 0)
            self.assertIn("f1-pairs=9 ", r.stdout)


class TestSatC5Subset(unittest.TestCase):
    """Gate for the C5 cardinality/budget encoding + the reduced-subset
    (small-n certified-count probe) instances in sat.py (TASK #225 §6.4).

    Cross-checks sat.py's CNF against an INDEPENDENT reference count computed
    here from solve.py primitives only (no sat.py code path reused):
      * decisive: at tiny N the set of Y-assignments the CNF accepts (decided
        by unit propagation over the emitted clauses — a genuine SAT decision,
        Sinz counters being UP-complete once the Y/T inputs are fixed) equals
        exactly the valid C1&C2&C4&C5 sequences and the reference DP count;
      * pinned: the B0 budget and CNF construction at the group-closed
        N in {9,13,16}. The exact |C1&C2&C4&C5| is asserted LIVE AT N=9 ONLY
        (26,112, recomputed here every run). The N=13 and N=16 counts are
        carried as DOCUMENTATION of the values `verify.py --recount` gates —
        this class does not check them, and a reader should not infer from a
        `"count"` field that it does. `verify.py --recount` reproduces
        2,063,395,607,040 and 267,765,117,419,520 independently with B0
        re-derived (RECOUNT_RESULT=PASS); VERIFY.md tabulates both. Their
        reference DP has a ~10^7-10^9 state space, too heavy for a per-run
        gate, which is why they are gated there and not here.
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
        if not (dfs(0, start, 0)):
            raise AssertionError('guard failed: dfs(0, start, 0)')
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
            13: {"b0": {1: 1, 2: 6, 3: 0, 4: 6, 6: 0}, "count": 2_063_395_607_040, "live": False, "gated_by": "verify.py --recount"},
            16: {"b0": {1: 1, 2: 8, 3: 1, 4: 6, 6: 0}, "count": 267_765_117_419_520, "live": False, "gated_by": "verify.py --recount"},
        }
        # 🔴 A DEAD LITERAL MUST BE IMPOSSIBLE TO ADD SILENTLY. A `"count"` guarded by
        # `"live": False` asserts nothing, but reads exactly like a pinned oracle — this class
        # carried two such values while its own docstring claimed they were matched. So a
        # non-live count is only allowed if it NAMES the instrument that does gate it.
        for N, exp in EXPECT.items():
            if not exp["live"]:
                self.assertIn("gated_by", exp,
                              f"N={N}: a non-live 'count' is a dead literal unless 'gated_by' "
                              f"names the instrument that checks it")
                self.assertIsInstance(exp["gated_by"], str)
                self.assertTrue(exp["gated_by"].strip(), f"N={N}: 'gated_by' must not be empty")
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


class TestAtlasRatioPrecision(unittest.TestCase):
    """Every digit solve.py prints for a derived ratio must be a digit of the RATIONAL.

    The oracle here does pure integer long division: no float, no Fraction, no Decimal.  It
    therefore shares no rounding code with the implementation, which is the only reason it is
    an oracle rather than a second opinion.  Before 2026-08-23 _atlas_ratio returned
    float(Fraction(...)) and _atlas_f printed "%.17g" of it; binary64 carries ~15.95 significant
    decimal digits, so the last one or two digits reconstructed the rounded double rather than
    the rational.  test_old_float_path_would_fail keeps that failure demonstrable -- a check that
    has never been shown able to fail proves nothing.
    """

    SIG = 17

    @staticmethod
    def _oracle(num, den, sig):
        """(mantissa_digits, exponent) of num/den, correctly rounded, integers only."""
        if num == 0:
            return (0, 0)
        e = 0
        while num >= den * 10:
            den *= 10
            e += 1
        while num < den:
            num *= 10
            e -= 1
        q, r = divmod(num * 10 ** (sig - 1), den)
        if 2 * r > den or (2 * r == den and q & 1):
            q += 1
            if q >= 10 ** sig:
                q //= 10
                e += 1
        return (q, e)

    @classmethod
    def _digits(cls, s, sig):
        s = s.strip().lstrip("+-")
        if "e" in s or "E" in s:
            mant, _, ex = s.replace("E", "e").partition("e")
            ex = int(ex)
        else:
            mant, ex = s, 0
        ip, _, fp = mant.partition(".")
        if ip.strip("0"):
            e = len(ip.lstrip("0")) - 1 + ex
        else:
            e = ex - (len(fp) - len(fp.lstrip("0"))) - 1
        digs = (ip + fp).lstrip("0")
        return (int((digs + "0" * sig)[:sig]), e)

    # (numerator, denominator) pairs.  The n=31-scale entry is the project's own
    # 1.3287e38 / 1.097051e39 conditional, at the magnitude it is actually published at.
    CASES = [
        (26112, 2 ** 20),
        (1234567, 26112),
        (1328700000000000000000000000000000000000,
         1097051000000000000000000000000000000000),
        (2 ** 130 + 1, 3 * (2 ** 130)),
        (1, 3),
        (7, 11),
        (10 ** 38 + 7, 3 * 10 ** 38 + 11),
        (1, 10 ** 25 + 3),
    ]

    def test_published_digits_are_exact(self):
        for a, b in self.CASES:
            got = solve._atlas_f(solve._atlas_ratio(a, b))
            self.assertEqual(self._digits(got, self.SIG),
                             self._oracle(a, b, self.SIG),
                             "%d/%d printed as %s" % (a, b, got))

    def test_old_float_path_would_fail(self):
        """The regression this guards must be reachable, or the test above is decorative."""
        from fractions import Fraction
        bad = sum(1 for a, b in self.CASES
                  if self._digits("%.17g" % float(Fraction(a, b)), self.SIG)
                  != self._oracle(a, b, self.SIG))
        self.assertGreater(bad, 0, "the float path no longer fails; this gate is now vacuous")

    def test_zero_denominator_still_nan(self):
        self.assertEqual(solve._atlas_f(solve._atlas_ratio(1, 0)), "nan")


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

    def test_records_verdict_and_kw_scope_are_whole_line_tokens(self):
        # Code batch V-1 (2026-09-02, Codex V2-F25 #8). The verdict and the ONE predicate it
        # does not fold in by default (King Wen's presence) must be whole-line KEY=value
        # tokens, matched the way the project matches every verdict: exact line, never
        # output shape. RED BEFORE (verify.py at 2026-09-02 HEAD): no "VERIFY=" or
        # "KW_" line at all; the only machine-readable verdict was the exit status, and
        # a PASS without King Wen was distinguishable from a PASS of the canonical only
        # by reading prose two lines above the verdict sentence.
        kw = self._encode(self.V.KW)
        # A VALID non-KW record, found rather than guessed: of the 31 single-orientation
        # flips of King Wen's own record, VERIFY.md's census says 9 satisfy C1-C5 (the
        # rest break the C5 budget or C2). Take the first that passes every per-record
        # check, so the only open question on this fixture is the King Wen scope.
        nokw = None
        for i in range(1, 32):
            cand = bytearray(kw); cand[i] ^= 0x02
            c = self._counts(bytes(cand))
            if not c["kw_found"] and all(c[k] == 0 for k in (
                    "fail_c1", "fail_c2", "fail_c3", "fail_c4", "fail_c5",
                    "fail_decode", "fail_fmt")):
                nokw = bytes(cand); break
        self.assertIsNotNone(nokw, "no valid single-flip non-KW record found")
        def lines(r): return r.stdout.splitlines()
        r = self._run_main(self._wrap(kw))
        self.assertEqual(r.returncode, 0)
        self.assertIn("VERIFY=PASS", lines(r)); self.assertIn("KW_PRESENT=YES", lines(r))
        self.assertIn("KW_REQUIRED=NO", lines(r))
        r = self._run_main(self._wrap(nokw))
        self.assertEqual(r.returncode, 0)                  # default: scope-limited PASS
        self.assertIn("VERIFY=PASS", lines(r)); self.assertIn("KW_PRESENT=NO", lines(r))
        self.assertIn("KW_REQUIRED=NO", lines(r))
        self.assertTrue(any(l.startswith("VERIFY PASS") and "King Wen NOT present" in l
                            for l in lines(r)),
                        "a PASS without King Wen must say so in the PASS sentence itself")
        r = self._run_main(self._wrap(nokw), ["--expect-kw"])
        self.assertEqual(r.returncode, 1)
        self.assertIn("VERIFY=FAIL", lines(r)); self.assertIn("KW_PRESENT=NO", lines(r))
        self.assertIn("KW_REQUIRED=YES", lines(r))
        self.assertNotIn("VERIFY=PASS", lines(r))

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


class TestCheckArtifactControls(unittest.TestCase):
    """C1 (2026-09-02): negative controls for the four predicates `--check-artifact`
    was missing, asserted against BOTH shipped implementations at once.

    WHY BOTH IN ONE TEST. verify.py and verify.c are two INDEPENDENT instruments;
    that independence is the deliverable, so nothing here is shared between them
    beyond the fixture bytes and the expected verdict. What is asserted is that
    they agree token for token — `verify.c` already carried the note that "two
    independent instruments that diverge on compound defects are not two
    instruments", and this pins it. A real divergence was measured while these
    controls were being written: on a torn trailing record verify.py returned
    ARTIFACT=PASS rc 0 while verify.c returned ARTIFACT=FAIL_partial_record rc 2.

    WHY EXACT-LINE MATCHING. Verdicts are `KEY=value` matched whole, never
    inferred from output shape or from a regex over a character class. The
    2026-08-15 flips-census error came from a harness grepping
    `^BAD_[A-Z_]+=[1-9]`, whose class excludes DIGITS, so `BAD_HD5=1` never
    matched and 7 failures were silently counted as passes. `BAD_C3` and
    `BAD_HD5` both carry digits.

    EVERY CONTROL HERE WAS RED FIRST. Each fixture was measured against the
    pre-change binaries and observed to be ACCEPTED (`ARTIFACT=PASS` / rc 0,
    `CHECK_REPR=PASS` / rc 0) before the predicate was added. A control written
    after a fix, that has only ever passed, proves nothing about whether it can
    fire."""

    KWREC_HEX = ("0004080c1014181c2024282c3034383c"
                 "4044484c5054585c6064686c7074787c")
    # C3 = 1080 against the 776 ceiling; C1/C2/C4/C5-valid, so ONLY a C3 leg
    # rejects it. From the Codex V2-F20 #1 fixture.
    C3REC_HEX = "0060743e36207a5e10265472644e2a684204520e146e08187e1c303a58464a2c"
    # The lex-least completion of that same key: the stored record IS what the
    # repr oracle returns, so before the C3 pre-filter landed --check-repr
    # reported AGREE=1 INCOMPUTABLE=0 CHECK_REPR=PASS rc 0 on a key the record
    # convention says has no valid completion at all.
    C3REPR_HEX = "0060743c3620785c10245670664c28684204520c146c0a187c1e323a58464a2c"

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="c1_ctl_")
        cls.vbin = os.path.join(cls.tmp, "verify_ctl")
        r = subprocess.run(["gcc", "-O0", "-o", cls.vbin, "verify.c",
                            "-lz", "-lpthread", "-lm"],
                           capture_output=True, text=True)
        cls.have_c = (r.returncode == 0 and os.path.exists(cls.vbin))
        cls.c_build_err = r.stderr[-2000:] if not cls.have_c else ""

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def _artifact(self, name, records, declared=None, version=1,
                  reserved=b"\0" * 16, tail=b""):
        """Build a ROAE artifact. `declared` defaults to len(records) so a caller
        must ASK for a geometry mismatch rather than get one by accident."""
        body = b"".join(records)
        if declared is None:
            declared = len(records)
        blob = (b"ROAE" + struct.pack("<I", version) + struct.pack("<Q", declared)
                + reserved + body + tail)
        path = os.path.join(self.tmp, name)
        with open(path, "wb") as fh:
            fh.write(blob)
        return path

    def _gz_of(self, path):
        """gzip an existing artifact beside itself and return the .gz path."""
        gz = path + ".gz"
        with open(path, "rb") as src, gzip.open(gz, "wb") as dst:
            dst.write(src.read())
        return gz

    def _both(self, path, mode="--check-artifact"):
        """Run the fixture through both instruments. Returns (rc, token_set) per
        side; the token set is the set of whole verdict lines."""
        def toks(out):
            keys = ("ARTIFACT=", "CHECK_REPR=", "RECORDS=", "BAD_", "AGREE=",
                    "DISAGREE=", "INCOMPUTABLE=", "CHECKED=")
            return {ln for ln in out.splitlines()
                    if any(ln.startswith(k) for k in keys)}
        p = subprocess.run([sys.executable, "verify.py", path, mode],
                           capture_output=True, text=True)
        py = (p.returncode, toks(p.stdout))
        if not self.have_c:
            self.fail("verify.c did not build, so nothing was verified: " + self.c_build_err)
        c = subprocess.run([self.vbin, mode, path], capture_output=True, text=True)
        cc = (c.returncode, toks(c.stdout))
        return py, cc

    def _assert_agree(self, path, mode, want_rc, want_tokens):
        py, c = self._both(path, mode)
        self.assertEqual(py[0], want_rc, f"verify.py rc on {os.path.basename(path)}")
        self.assertEqual(c[0], want_rc, f"verify.c rc on {os.path.basename(path)}")
        for t in want_tokens:
            self.assertIn(t, py[1], f"verify.py missing verdict token {t!r}")
            self.assertIn(t, c[1], f"verify.c missing verdict token {t!r}")
        self.assertEqual(py[1], c[1],
                         "the two independent instruments printed DIFFERENT verdict "
                         f"tokens on {os.path.basename(path)}; symmetric difference: "
                         f"{py[1] ^ c[1]}")

    # ---- negative controls: each was ACCEPTED before the fix ----

    def test_gz_framing_changes_no_verdict_token(self):
        """V2-F48 #4: the same artifact, raw and gz-framed, must verify identically.

        The framing is a TRANSPORT detail — `verify.py` states the contract in
        `--check-artifact`'s geometry check ("measured on the logical (post-gunzip)
        stream, so a .gz artifact is checked on its contents, not its compressed
        size"), and `solve` has written `solutions.bin` gzip-framed by default since
        #169 WITHOUT changing the filename. So the two forms are the same artifact by
        every definition that matters, and any instrument that disagreed about them
        would be reading the container instead of the contents.

        This asserts more than the charge asked for. The charge names `RECORDS=`;
        this compares the WHOLE verdict-token set and the exit code, on BOTH
        instruments, because a count that survives while some other token flips is
        not the property anyone actually wants.

        MEASURED 2026-09-04 before writing it: the contract already HOLDS
        (`RECORDS=1 ARTIFACT=PASS` from verify.py and verify.c on both forms), so
        this is a regression test, not a fix — recorded plainly so nobody reads it
        as a bug that was found."""
        raw = self._artifact("gzsame.bin", [bytes.fromhex(self.KWREC_HEX)])
        gz = self._gz_of(raw)
        py_raw, c_raw = self._both(raw, "--check-artifact")
        py_gz, c_gz = self._both(gz, "--check-artifact")
        self.assertIn("RECORDS=1", py_raw[1], "the raw fixture itself did not verify")
        self.assertEqual(py_raw, py_gz,
                         "verify.py gave a different verdict for the gz-framed copy of "
                         "the same artifact; the framing is transport, not content")
        self.assertEqual(c_raw, c_gz,
                         "verify.c gave a different verdict for the gz-framed copy of "
                         "the same artifact; the framing is transport, not content")

    def test_ctl_c3_artifact_is_rejected(self):
        # RED BEFORE: ARTIFACT=PASS rc 0 from both, on a record with cd=1080.
        p = self._artifact("c3bad.bin", [bytes.fromhex(self.C3REC_HEX)])
        self._assert_agree(p, "--check-artifact", 1, {"BAD_C3=1", "ARTIFACT=FAIL"})

    def test_ctl_hdr_version_is_rejected(self):
        # RED BEFORE: ARTIFACT=PASS rc 0. REBUILD_FROM_SPEC.md requires a
        # conformant reader to reject an unknown version.
        p = self._artifact("v2.bin", [bytes.fromhex(self.KWREC_HEX)], version=2)
        self._assert_agree(p, "--check-artifact", 1,
                           {"BAD_HDR_VERSION=1", "ARTIFACT=FAIL"})

    def test_ctl_hdr_reserved_is_rejected(self):
        # RED BEFORE: ARTIFACT=PASS rc 0. SOLUTIONS_FORMAT.md: bytes 16-31 MUST
        # be zero.
        p = self._artifact("resv.bin", [bytes.fromhex(self.KWREC_HEX)],
                           reserved=b"\0" * 4 + b"\x5a" + b"\0" * 11)
        self._assert_agree(p, "--check-artifact", 1,
                           {"BAD_HDR_RESERVED=1", "ARTIFACT=FAIL"})

    def test_ctl_geometry_is_rejected(self):
        # RED BEFORE: ARTIFACT=PASS rc 0 on a header declaring 5 records over a
        # 1-record body. Ignoring the count for loop TERMINATION is what makes
        # the sub-range form work; it never justified not CHECKING it.
        p = self._artifact("geom.bin", [bytes.fromhex(self.KWREC_HEX)], declared=5)
        self._assert_agree(p, "--check-artifact", 1,
                           {"BAD_GEOMETRY=1", "ARTIFACT=FAIL"})

    def test_ctl_partial_record_is_rejected_by_both(self):
        # RED BEFORE, AND A TRUE DIVERGENCE: verify.py ARTIFACT=PASS rc 0 (the
        # torn tail silently dropped by a bare `break`) while verify.c already
        # returned ARTIFACT=FAIL_partial_record rc 2. verify.c was right.
        p = self._artifact("partial.bin", [bytes.fromhex(self.KWREC_HEX)],
                           tail=b"\x11" * 10)
        self._assert_agree(p, "--check-artifact", 2, {"ARTIFACT=FAIL_partial_record"})

    def test_ctl_repr_c3_is_incomputable(self):
        # RED BEFORE: AGREE=1 INCOMPUTABLE=0 CHECK_REPR=PASS rc 0 — the
        # fail-closed leg passing a key the convention says cannot be completed.
        # Note the mode verdict CHECK_REPR=FAIL alone would NOT have caught the
        # bug on the other fixture (a non-minimal variant of the same key already
        # failed, for the wrong reason); INCOMPUTABLE=1 is the load-bearing token.
        p = self._artifact("c3repr.bin", [bytes.fromhex(self.C3REPR_HEX)])
        self._assert_agree(p, "--check-repr", 1,
                           {"INCOMPUTABLE=1", "DISAGREE=0", "CHECK_REPR=FAIL"})

    # ---- positive controls: these must NOT have been broken ----

    def test_ctl_pos_king_wen_still_passes(self):
        p = self._artifact("pos.bin", [bytes.fromhex(self.KWREC_HEX)])
        self._assert_agree(p, "--check-artifact", 0,
                           {"BAD_C3=0", "BAD_HDR_VERSION=0", "BAD_HDR_RESERVED=0",
                            "BAD_GEOMETRY=0", "ARTIFACT=PASS"})

    def test_ctl_subrange_invocation_stays_green(self):
        # The geometry leg must fire ONLY on a whole-file read. A sub-range
        # request deliberately reads fewer records than the header declares and
        # must not be reported as corrupt framing.
        recs = [bytes.fromhex(self.KWREC_HEX)]
        p = self._artifact("sub.bin", recs)
        py = subprocess.run([sys.executable, "verify.py", p, "--check-artifact", "1"],
                            capture_output=True, text=True)
        self.assertEqual(py.returncode, 0)
        self.assertIn("BAD_GEOMETRY=0", py.stdout.splitlines())
        if not self.have_c:
            self.fail("verify.c did not build, so nothing was verified: " + self.c_build_err)
        c = subprocess.run([self.vbin, "--check-artifact", p, "1", "0"],
                           capture_output=True, text=True)
        self.assertEqual(c.returncode, 0)
        self.assertIn("BAD_GEOMETRY=0", c.stdout.splitlines())

    def test_c3_is_orientation_invariant_so_the_prefilter_is_exact(self):
        """The repr C3 pre-filter runs BEFORE the DFS, on the all-zero
        orientation. That is only sound if C3 is a function of the key alone.
        Measured here rather than assumed — it is the load-bearing premise."""
        V = _load("verify")
        random.seed(20260902)
        for _ in range(8):
            key = list(range(32))
            random.shuffle(key)
            seen = set()
            for _t in range(32):
                orient = [random.randint(0, 1) for _ in range(32)]
                seq = []
                for slot in range(32):
                    a, b = V.PAIRS[key[slot]]
                    seq += [b, a] if orient[slot] else [a, b]
                seen.add(V.compute_comp_dist(seq))
            self.assertEqual(len(seen), 1,
                             f"C3 varied with orientation for key {key}: {sorted(seen)}")


class TestNoBareAsserts(unittest.TestCase):
    """Q-373 (2026-08-28): the trust-base guard layer must survive `python3 -O`.

    VERIFY.md records the convention — import-time gates are explicit raises, not
    `assert`, so they survive -O — and solve.py's table gates were converted for
    exactly that reason, but sat.py never was: its entire import-time ground-truth
    layer was ~30 bare asserts, and a corrupted BETWEEN_MULTISET under -O silently
    emitted a syntactically valid WRONG CNF (measured 2026-08-28). This test pins
    the convention by INTENT rather than by phrase: an AST scan of the trust-base
    files for Assert nodes. Zero is the only passing value, so a future bare
    assert anywhere in these files goes red regardless of wording. (unittest
    assertions are method calls, not statements, so this test itself survives -O.)"""

    FILES = ("solve.py", "roae.py", "sat.py", "verify.py", "tests.py",
             "scripts/c2c3_joint_null.py")

    def test_trust_base_has_no_assert_statements(self):
        import ast
        for f in self.FILES:
            with open(f) as fh:
                tree = ast.parse(fh.read(), filename=f)
            hits = [n.lineno for n in ast.walk(tree) if isinstance(n, ast.Assert)]
            self.assertEqual(hits, [], f"{f}: bare assert statement(s) at line(s) "
                             f"{hits} — guards must be explicit raises (Q-373)")

    def test_heredoc_python_has_no_assert_statements(self):
        # 🔴 THE FILE LIST WAS THE BLIND SPOT, NOT THE RULE. The leg above scans a fixed tuple of
        # .py files, so Python embedded in a shell heredoc was never in scope — and that is where
        # the trust base actually broke. verify_all.sh's §3b "independent verify.py-path recheck"
        # is a heredoc carrying seven bare asserts, INCLUDING its `assert n == 42` witness count.
        # Measured 2026-09-03 on the shipped block: default python3 -> AssertionError, exit 1;
        # `python3 -O` -> exit 0, having checked ZERO of 42 witnesses, which verify_all.sh's
        # `check` wrapper reads as PASS. PYTHONOPTIMIZE=1 is an env var a CI image can carry
        # without the caller ever knowing.
        # Scanning heredocs closes this for every future one, not just the file that exposed it.
        import ast, re, subprocess
        sh = [f for f in subprocess.run(["git", "ls-files", "*.sh"],
                                        capture_output=True, text=True).stdout.split() if f]
        self.assertTrue(sh, "git ls-files matched no shell scripts — the scan would be vacuous")
        # `python3 - <<'TAG' ... TAG` / `python3 - <<TAG`. The quoted-tag form is the common one.
        HD = re.compile(r"<<-?\s*'?\"?([A-Za-z_][A-Za-z0-9_]*)'?\"?\s*\n(.*?)\n[ \t]*\1",
                        re.S)
        scanned = 0
        for f in sh:
            try:
                body = open(f, encoding="utf-8", errors="replace").read()
            except OSError:
                continue
            for m in HD.finditer(body):
                block = m.group(2)
                # Only Python blocks: parse and skip anything that is not valid Python.
                try:
                    tree = ast.parse(block)
                except SyntaxError:
                    continue
                if not any(isinstance(n, (ast.Import, ast.ImportFrom, ast.FunctionDef,
                                          ast.Assert, ast.Assign, ast.For, ast.If))
                           for n in ast.walk(tree)):
                    continue
                scanned += 1
                off = body[:m.start(2)].count("\n")
                hits = [n.lineno + off for n in ast.walk(tree) if isinstance(n, ast.Assert)]
                self.assertEqual(hits, [], f"{f}: bare assert statement(s) in an embedded "
                                 f"python heredoc at line(s) {hits} — they vanish under "
                                 f"`python3 -O`, so the block can exit 0 having checked "
                                 f"nothing (Q-373, V2-F63 #2)")
        self.assertGreater(scanned, 0, "no python heredoc was parsed — the extractor has rotted "
                           "and this leg is blind, which is a failure, not a pass")


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


class TestSubtreePairOrderings(unittest.TestCase):
    """C4 (2026-09-02): the ORIENTATION-DEDUPED companion to the subtree
    anchors — `verify.py --recount-subtree`'s new PAIR_ORDERINGS_* tokens.

    WHY THIS EXISTS. _exact_subtree's third counter counts ORIENTED
    completions: the walk tries (a,b) and (b,a) for every pair, so one
    ordering of the 32 pair-BLOCKS is reached once per admissible orientation
    assignment. The corpus has repeatedly used "canonical leaves" for both
    quantities at once (that conflation is the root of the deferred
    `canonical` -> `oriented` relabel). Neither instrument emitted the deduped
    count at all, so nothing could go red on the conflation. It does now:
    2 / 381 / 899 at the 5 / 7 / 9-free KW anchors.

    THE INDEPENDENCE IS THE POINT. `_independent_orderings` below re-walks the
    C1-C5 tree from `solve.binary_hexagrams` — solve.py's table, not
    verify.py's — and rebuilds the pairs, the C5 budget, the C2 boundary rule
    and the C3 sum from SPECIFICATION's statements of them, importing nothing
    from verify beyond the function under test. What is asserted is SET
    EQUALITY, not size equality: two walks that disagree about WHICH orderings
    survive but agree on how many would pass a count check and fail this one.
    A hardcoded set of 381 permutations is not a repair anyone can write.

    THE WRONG REPAIR THIS CATCHES. Print the published constant
    (`PAIR_ORDERINGS_9FREE=899`) while the recomputation drifts: both tokens
    appear verbatim and a grep-only gate stays green. That is the exact shape
    C3's RED 3 caught by exit status alone, so it gets its own leg here —
    `test_token_prints_the_recomputed_set_not_a_constant` substitutes a stub
    walk with a KNOWN-WRONG ordering set and requires the printed token to
    carry the stub's number, which a constant-printing emitter cannot do.

    NOT A SUBSTRING MATCH. The tokens are asserted as whole lines, per the
    explicit-verdict rule.

    COST. ~0.4 s: the 5-free and 7-free anchors only. The 9-free rung (two
    9.4M-node walks, ~55 s) stays where TestSubtreeCrossAnchors left it — in
    `python3 verify.py --recount-subtree`, wired into verify_all.sh SS2."""

    @classmethod
    def setUpClass(cls):
        cls.V = _load("verify")

    @staticmethod
    def _independent_orderings(free):
        """Clean-room re-walk. Returns (set of pair-ordering tuples, oriented
        C3-passing leaf count) below the KW-following prefix with `free` free
        positions. Built from solve.py's KW table and SPECIFICATION's rules;
        verify.py is not consulted."""
        kw = list(solve.binary_hexagrams)
        pairs = [(kw[2 * i], kw[2 * i + 1]) for i in range(32)]
        hd = lambda a, b: bin(a ^ b).count("1")
        budget = [0] * 7
        for i in range(63):
            budget[hd(kw[i], kw[i + 1])] += 1
        if budget != [0, 2, 20, 13, 19, 0, 9]:      # C5, from SPECIFICATION
            raise AssertionError(f"C5 budget rebuilt wrong: {budget}")
        budget[6] -= 1                              # pair 0's within-transition
        seq = [63, 0] + [0] * 62                    # C4 start
        slotp = [0] * 32
        used, last, step = 1, 0, 1
        for p in range(1, 31 - free + 1):           # KW-following prefix
            slotp[step] = p
            f, sc = pairs[p]
            bd = hd(last, f)
            if bd == 5 or budget[bd] <= 0:
                raise AssertionError("prefix infeasible (boundary)")
            budget[bd] -= 1
            wd = hd(f, sc)
            if budget[wd] <= 0:
                raise AssertionError("prefix infeasible (within)")
            budget[wd] -= 1
            seq[2 * step], seq[2 * step + 1] = f, sc
            used |= 1 << p
            last = sc
            step += 1
        orders, oriented = set(), [0]

        def rec(st, lst, usedm):
            if st == 32:
                pos = [0] * 64
                for i, v in enumerate(seq):
                    pos[v] = i
                if sum(abs(pos[v] - pos[v ^ 63]) for v in range(64)) <= 776:
                    oriented[0] += 1
                    orders.add(tuple(slotp))
                return
            for p in range(1, 32):
                if (usedm >> p) & 1:
                    continue
                a, b = pairs[p]
                for f, sc in ((a, b), (b, a)):
                    bd = hd(lst, f)
                    if bd == 5 or budget[bd] == 0:
                        continue
                    budget[bd] -= 1
                    wd = hd(f, sc)
                    if budget[wd] == 0:
                        budget[bd] += 1
                        continue
                    budget[wd] -= 1
                    seq[2 * st], seq[2 * st + 1] = f, sc
                    slotp[st] = p
                    rec(st + 1, sc, usedm | (1 << p))
                    budget[wd] += 1
                    budget[bd] += 1

        rec(step, last, used)
        return orders, oriented[0]

    def test_orderings_agree_setwise_with_an_independent_walk(self):
        V = self.V
        for free, want_nodes, want_canon, want_ord in ((5, 443, 4, 2),
                                                       (7, 62256, 2232, 381)):
            d = 31 - free
            got = set()
            nodes, _l, canon, _x = V._exact_subtree(
                [(i, 0) for i in range(1, d + 1)], orderings=got)
            mine, mine_oriented = self._independent_orderings(free)
            self.assertEqual((nodes, canon), (want_nodes, want_canon), free)
            self.assertEqual(canon, mine_oriented, f"{free}-free oriented")
            # set equality, not size equality
            self.assertEqual(got, mine, f"{free}-free ordering SETS differ")
            self.assertEqual(len(got), want_ord, f"{free}-free count")

    def test_deduped_count_is_strictly_coarser_than_the_oriented_count(self):
        # The relation that makes the two numbers different objects: every
        # ordering is reached by at least one oriented leaf, so
        # 0 < |orderings| <= oriented. An implementation that collected the
        # ORIENTED sequence instead of the pair ordering would satisfy
        # equality here and inequality at the anchors; both legs run.
        V = self.V
        for free, want_ord in ((5, 2), (7, 381)):
            d = 31 - free
            got = set()
            _n, _l, canon, _x = V._exact_subtree(
                [(i, 0) for i in range(1, d + 1)], orderings=got)
            self.assertGreater(len(got), 0, free)
            self.assertLessEqual(len(got), canon, free)
            self.assertLess(len(got), canon, f"{free}-free: dedup did nothing")
            for t in got:
                self.assertEqual(t[0], 0, "slot 0 is C4's pinned pair")
                self.assertEqual(sorted(t), list(range(32)),
                                 "an ordering must be a permutation of the "
                                 "32 pair indices")
            self.assertEqual(len(got), want_ord)

    def test_orderings_argument_does_not_perturb_the_counters(self):
        # The collector must be inert. If passing `orderings` changed any
        # counter, every published anchor would be hostage to a debug knob.
        V = self.V
        pfx = [(i, 0) for i in range(1, 25)]        # 7-free
        self.assertEqual(V._exact_subtree(pfx),
                         V._exact_subtree(pfx, orderings=set()))

    def test_token_prints_the_recomputed_set_not_a_constant(self):
        """THE WRONG-REPAIR LEG. Substitute a stub walk whose ordering set has a
        size no published constant matches; the emitted token must carry the
        stub's size. A `print(f"PAIR_ORDERINGS_{free}FREE={want_ord}")` emitter
        prints 2/381/899 here and fails. The stub also returns wrong counters,
        so recount_subtree must return non-zero: the token leg and the exit-
        status leg are asserted together, because C3 measured a defect that
        only the second one caught."""
        import io, contextlib
        V = self.V
        stub_sizes = {5: 7777, 7: 8888, 9: 9999}
        real = V._exact_subtree

        def stub(prefix, orderings=None):
            free = 31 - len(prefix)
            if orderings is not None and free in stub_sizes:
                for j in range(stub_sizes[free]):
                    orderings.add((j,))
                return (0, 0, 0, 0)
            return (0, 0, 0, 0)

        buf = io.StringIO()
        V._exact_subtree = stub
        try:
            with contextlib.redirect_stdout(buf):
                rc = V.recount_subtree()
        finally:
            V._exact_subtree = real
        out = buf.getvalue()
        self.assertNotEqual(out.strip(), "", "stub run produced no output — "
                            "cannot conclude anything; this is an ERROR")
        lines = out.splitlines()
        for free, n in stub_sizes.items():
            self.assertIn(f"PAIR_ORDERINGS_{free}FREE={n}", lines,
                          f"token did not carry the recomputed size for "
                          f"{free}-free — it is printing a constant")
            self.assertNotIn(f"PAIR_ORDERINGS_{free}FREE="
                             f"{ {5: 2, 7: 381, 9: 899}[free] }", lines)
        self.assertNotEqual(rc, 0, "a walk returning zeros must not report "
                                   "ALL MATCH")
        self.assertNotIn("recount-subtree: ALL MATCH", out)





class TestRevPartnerTwoInstruments(unittest.TestCase):
    """C4 (2026-09-02): the rev/partner leg is now TWO instruments.

    C3 landed `REV_EQUALS_PARTNER_COUNT=56` / `REV_FIXES_ALL_PAIRS=yes` in
    `verify.py --recount-finite` and recorded that it was deliberately not
    mirrored in verify.c — no artifact is read, so the artifact-path
    two-instrument rule does not bind it. What DOES bind is the standing rule
    that a check derived once is one instrument: verify.py's two routes both
    live in verify.py, so a defect common to its rev6/partner/pairs trio moves
    them together and both routes agree on the wrong answer. `verify.c
    --rev-partner` is a separate implementation of the same SPECIFICATION C1
    statements, sharing no code and no header.

    WHAT IS ASSERTED. Both instruments must emit the SAME verdict lines,
    whole-line, and both must exit 0. Set equality alone is not enough — two
    instruments that print nothing also agree — so the expected keys are
    required to be present before the sets are compared. That is the trap this
    class exists to avoid, and it is the same shape as the 2026-08-15
    flips-census error one level up.

    IT MUST BE ABLE TO FAIL. `test_the_c_twin_fails_on_the_retracted_claim`
    rebuilds verify.c with the retracted claim made TRUE in code
    (partner := rev) and requires the C instrument to go red and to stop
    printing the 56. A twin that has only ever passed proves nothing about
    whether it can fire."""

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="c4_revpartner_")
        cls.vbin = os.path.join(cls.tmp, "verify_rp")
        r = subprocess.run(["gcc", "-O1", "-o", cls.vbin, "verify.c",
                            "-lz", "-lpthread", "-lm"],
                           capture_output=True, text=True)
        cls.have_c = (r.returncode == 0 and os.path.exists(cls.vbin))
        cls.c_build_err = r.stderr[-2000:] if not cls.have_c else ""
        with open("verify.c", encoding="utf-8") as fh:
            cls.src = fh.read()

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    KEYS = ("REV_EQUALS_PARTNER_COUNT=", "REV_FIXES_ALL_PAIRS=")

    def _toks(self, out):
        return {ln for ln in out.splitlines()
                if any(ln.startswith(k) for k in self.KEYS)}

    def test_both_instruments_emit_the_same_verdict_lines(self):
        py = subprocess.run([sys.executable, "verify.py", "--recount-finite"],
                            capture_output=True, text=True)
        self.assertEqual(py.returncode, 0, py.stdout[-800:])
        pyt = self._toks(py.stdout)
        # presence FIRST: two silent instruments also "agree"
        self.assertEqual(len(pyt), 2, f"verify.py emitted {pyt} — a missing "
                                      f"verdict line is an ERROR, not a pass")
        if not self.have_c:
            self.fail("verify.c did not build, so nothing was verified: " + self.c_build_err)
        c = subprocess.run([self.vbin, "--rev-partner"],
                           capture_output=True, text=True)
        self.assertEqual(c.returncode, 0, c.stdout[-800:])
        ct = self._toks(c.stdout)
        self.assertEqual(len(ct), 2, f"verify.c emitted {ct} — ERROR")
        self.assertEqual(pyt, ct, "the two instruments disagree")
        self.assertIn("REV_EQUALS_PARTNER_COUNT=56", ct)
        self.assertIn("REV_FIXES_ALL_PAIRS=yes", ct)
        _emit_token("REV_PARTNER_TWO_INSTRUMENT", 1)

    def test_the_c_twin_fails_on_the_retracted_claim(self):
        """Make the retracted sentence true in code — partner(h) := rev(h) —
        and the C instrument must refuse it. The count leg is what moves; the
        conclusion leg does not, which is exactly why both are printed."""
        if not self.have_c:
            self.fail("verify.c did not build, so nothing was verified: " + self.c_build_err)
        bad = self.src.replace(
            "static int partner(int h) { int r = rev6(h); return (r != h) ? r : comp6(h); }",
            "static int partner(int h) { return rev6(h); }")
        self.assertNotEqual(bad, self.src, "the partner() anchor moved")
        src = os.path.join(self.tmp, "verify_bad.c")
        with open(src, "w", encoding="utf-8") as fh:
            fh.write(bad)
        binp = os.path.join(self.tmp, "verify_bad")
        b = subprocess.run(["gcc", "-O1", "-o", binp, src,
                            "-lz", "-lpthread", "-lm"],
                           capture_output=True, text=True)
        self.assertEqual(b.returncode, 0, b.stderr[-800:])
        r = subprocess.run([binp, "--rev-partner"], capture_output=True,
                           text=True)
        self.assertNotEqual(r.stdout.strip(), "", "no output — ERROR")
        self.assertNotEqual(r.returncode, 0,
                            "the C twin accepted partner := rev")
        self.assertNotIn("REV_EQUALS_PARTNER_COUNT=56",
                         r.stdout.splitlines(),
                         "the poisoned build still printed the published count")

    def test_the_c_twin_fails_when_rev_stops_fixing_the_pairs(self):
        """The second token is not decoration. Break rev6 so the conclusion
        fails while leaving a count behind; REV_FIXES_ALL_PAIRS must move."""
        if not self.have_c:
            self.fail("verify.c did not build, so nothing was verified: " + self.c_build_err)
        bad = self.src.replace(
            "static int rev6(int n) {",
            "static int rev6(int n) { if (n >= 0) return (n + 1) & 63;")
        self.assertNotEqual(bad, self.src, "the rev6 anchor moved")
        src = os.path.join(self.tmp, "verify_rev.c")
        with open(src, "w", encoding="utf-8") as fh:
            fh.write(bad)
        binp = os.path.join(self.tmp, "verify_rev")
        b = subprocess.run(["gcc", "-O1", "-o", binp, src,
                            "-lz", "-lpthread", "-lm"],
                           capture_output=True, text=True)
        self.assertEqual(b.returncode, 0, b.stderr[-800:])
        r = subprocess.run([binp, "--rev-partner"], capture_output=True,
                           text=True)
        self.assertNotEqual(r.stdout.strip(), "", "no output — ERROR")
        self.assertNotEqual(r.returncode, 0)
        self.assertNotIn("REV_FIXES_ALL_PAIRS=yes", r.stdout.splitlines())


class TestAlternativeNullExactRationals(unittest.TestCase):
    """C4 (2026-09-02): the four alternative-null figures TR-10 publishes as
    EXACT RATIONALS, recomputed from the shipped predicates — C2's rank-1
    backlog item, carried unimplemented through C2 and C3 under the standing
    warning "do not pin a figure you have not reproduced".

    NOTHING HERE IS A LITERAL. The warning is honoured by having no magic
    number on either side of the comparison. The EXPECTED value is parsed out
    of `reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md`'s own null-sensitivity
    table — `2/C(31,4)`, `2·7/35,960` — and evaluated with math.comb. The
    ACTUAL value is an exhaustive enumeration driven by `solve.dav_rotinv` and
    `solve.dav_pureplace`, the shipped predicates the report says it measured.
    So the report and the instrument are pinned to each other, and a drift in
    EITHER goes red; a "repair" that edits the constant in this file does not
    exist, because this file has no constant to edit.

    THE SAMPLE SPACES ARE THE SUITE'S OWN NULL, executed rather than argued.
    METHODS.md §"Permutation-test nulls" defines the pair-preserving null as
    "shuffle the 32 canonical pairs + independent uniform orientation flips,
    first pair fixed by C4 where stated". Both predicates read only pair-SLOT
    placement (dav_rotinv compares a position set; dav_pureplace reads whole
    slots), so the orientation half drops out — and that is not assumed here
    either: `test_both_predicates_are_orientation_blind` measures it. C1 is
    the free null; C1+C4 pins the {63,0} block to slot 1. Every enumeration
    below is EXHAUSTIVE over its space (35,960 / 31,465 / 863,040 / 26,970
    placements) — no sampling anywhere.

    WHAT OTHER REPAIR WOULD TURN THIS GREEN? A predicate rewritten to accept
    everything gives 35,960/35,960, not 1/35,960 — caught. A predicate
    rewritten to accept nothing gives Fraction(0) — caught, and the
    nonzero-numerator leg names it rather than letting a zero pass as a
    measurement. A report edited to a new rational without touching the
    predicate — caught, in the other direction. The one thing that stays green
    is a change to BOTH, which is exactly the merge that is allowed.

    PERM_NCYC_P2 IS DERIVED TWICE. TR-10's sibling figure lives in
    CRITIQUE.md, whose 2026-09-01 correction turned 0.13 into 0.30386238 by
    applying the family's frozen "two-sided atom-inclusive" convention to
    `reports/evidence/perm_tier1.out`. Both routes are computed here: from the
    summary line's below/at/above, and independently by re-summing the
    `perm_hist` distribution in the same file. They must agree with each other
    AND with the published figure, and the WITHDRAWN 0.12706032 must not have
    come back.

    Cost: ~10 s, dominated by the 863,040-placement pureplace sweep."""

    TR10 = "reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md"
    CRITIQUE = "documentation/CRITIQUE.md"
    EVIDENCE = "reports/evidence/perm_tier1.out"

    @classmethod
    def setUpClass(cls):
        cls.pairs = [(KW[2 * i], KW[2 * i + 1]) for i in range(32)]
        rev6 = lambda h: int(format(h, "06b")[::-1], 2)
        # the three block sets the two predicates read, located from their own
        # stated definitions rather than hard-coded as indices
        cls.rotinv_blocks = cls._blocks(
            cls, [h for h in range(64)
                  if rev6(h) == (h ^ 63) and rev6(h) != h])
        dsym = (0b000, 0b010, 0b101, 0b111)
        cls.sym_blocks = cls._blocks(cls, [(t << 3) | t for t in dsym])
        cls.asym_blocks = cls._blocks(
            cls, [(t << 3) | t for t in range(8) if t not in dsym])
        with open(cls.TR10, encoding="utf-8") as fh:
            cls.tr10 = fh.read()

    def _blocks(self, hexes):
        out = sorted({i for i in range(32)
                      if self.pairs[i][0] in hexes or self.pairs[i][1] in hexes})
        return out

    def _seq(self, assign):
        """A full 64-sequence with `assign` (0-based slot -> block index)
        honoured; every other block fills the remaining slots in index order.
        Both predicates read only the assigned blocks' positions, so the filler
        is irrelevant — `test_filler_does_not_change_the_verdict` measures that
        rather than asserting it."""
        rest = [p for p in range(32) if p not in assign.values()]
        seq, it = [], iter(rest)
        for s in range(32):
            p = assign.get(s)
            if p is None:
                p = next(it)
            seq.extend(self.pairs[p])
        return seq

    # ---- expected values, parsed out of the report -------------------------
    def _tr10_row(self, name):
        for line in self.tr10.splitlines():
            if line.lstrip().startswith("|") and f"`{name}`" in line \
                    and "C(3" not in line.split("|")[1]:
                cells = [c.strip() for c in line.strip().strip("|").split("|")]
                if len(cells) >= 4 and cells[1] == f"`{name}`":
                    return cells
        raise AssertionError(f"no null-sensitivity row for {name} in "
                             f"{self.TR10} — a scan that finds nothing is an "
                             f"ERROR, not agreement")

    @staticmethod
    def _published_rational(cell):
        """Evaluate the two-sided rational a TR-10 cell publishes, e.g.
        '2/C(31,4) = **6.356x10-5**' or '2*14/4,495 = **6.229x10-3**'.
        Returns (Fraction two_sided, decimal_string)."""
        from fractions import Fraction
        import math
        m = re.match(r"2/C\((\d+),(\d+)\)", cell)
        if m:
            val = Fraction(2, math.comb(int(m.group(1)), int(m.group(2))))
        else:
            m = re.match(r"2·([\d,]+)/([\d,]+)", cell)
            if not m:
                raise AssertionError(f"unparsable published rational: {cell!r}")
            val = Fraction(2 * int(m.group(1).replace(",", "")),
                           int(m.group(2).replace(",", "")))
        d = re.search(r"\*\*([\d.]+)×10⁻([⁰¹²³"
                      r"⁴-⁹]+)\*\*", cell)
        if not d:
            raise AssertionError(f"no published decimal in cell: {cell!r}")
        sup = {"⁰": "0", "¹": "1", "²": "2", "³": "3",
               "⁴": "4", "⁵": "5", "⁶": "6", "⁷": "7",
               "⁸": "8", "⁹": "9"}
        exp = int("".join(sup[c] for c in d.group(2)))
        return val, float(d.group(1)) * 10 ** (-exp)

    def _check_row(self, name, one_sided_c1, one_sided_c1c4):
        """Both cells of a TR-10 null-sensitivity row against the enumeration."""
        cells = self._tr10_row(name)
        for cell, mine in ((cells[2], one_sided_c1), (cells[3], one_sided_c1c4)):
            pub, dec = self._published_rational(cell)
            self.assertEqual(pub, 2 * mine,
                             f"{name}: report publishes {pub} two-sided, "
                             f"enumeration gives {2 * mine}")
            self.assertAlmostEqual(float(pub) / dec, 1.0, places=3,
                                   msg=f"{name}: the row's decimal {dec} does "
                                       f"not render its own rational {pub}")

    # ---- the enumerations --------------------------------------------------
    def test_rotinv_exact_masses(self):
        from fractions import Fraction
        import math
        blocks = self.rotinv_blocks
        self.assertEqual(len(blocks), 4,
                         "the rotation-equals-inversion class is not 4 blocks")
        # C1: the 4 distinguishable blocks land on a uniformly random 4-subset
        # of the 32 slots, and the predicate reads only that subset.
        # The passing SUBSETS are collected, not just counted. MEASURED
        # 2026-09-02: shifting dav_rotinv's target set by one pair-slot leaves
        # the mass at 1/35,960 — one subset still passes, just a different one
        # — so a count-only gate is blind to target drift. The subset that
        # passes must be King Wen's own.
        passing = [sl for sl in itertools.combinations(range(32), 4)
                   if solve.dav_rotinv(self._seq(dict(zip(sl, blocks))))]
        hits = len(passing)
        kw_slots = tuple(sorted(b for b in blocks))
        self.assertEqual(passing, [kw_slots],
                         "the passing placement is not the one King Wen "
                         "occupies — the predicate's target set has drifted")
        c1 = Fraction(hits, math.comb(32, 4))
        # C1+C4: block 0 ({63,0}) is pinned to slot 1; it is not in the class,
        # so the class draws from the remaining 31 slots.
        self.assertNotIn(0, blocks)
        hits4 = sum(1 for sl in itertools.combinations(range(1, 32), 4)
                    if solve.dav_rotinv(
                        self._seq({0: 0, **dict(zip(sl, blocks))})))
        c1c4 = Fraction(hits4, math.comb(31, 4))
        self.assertGreater(hits, 0, "zero hits is not a measurement — the "
                                    "predicate accepted nothing; ERROR")
        self.assertGreater(hits4, 0, "zero hits under C1+C4; ERROR")
        self._check_row("rotinv", c1, c1c4)
        self.assertEqual(str(c1c4), "1/31465")
        _emit_token("ROTINV_C1C4", c1c4)

    def test_pureplace_exact_masses(self):
        from fractions import Fraction
        sb, ab = self.sym_blocks, self.asym_blocks
        self.assertEqual((len(sb), len(ab)), (2, 2))
        passing = set()
        def sweep(slots, pinned):
            n = hits = 0
            for s1 in slots:
                for a0 in slots:
                    if a0 == s1:
                        continue
                    for a1 in slots:
                        if a1 in (s1, a0):
                            continue
                        n += 1
                        asg = dict(pinned)
                        asg[s1] = sb[1]; asg[a0] = ab[0]; asg[a1] = ab[1]
                        if solve.dav_pureplace(self._seq(asg)):
                            hits += 1
                            passing.add((s1, a0, a1))
            return hits, n
        # C1: all ordered placements of the four blocks over the 32 slots.
        h = n = 0
        for s0 in range(32):
            hh, nn = sweep([x for x in range(32) if x != s0], {s0: sb[0]})
            h += hh; n += nn
        c1 = Fraction(h, n)
        self.assertEqual(n, 32 * 31 * 30 * 29)
        # C1+C4: sb[0] IS block 0, and C4 pins it to slot 1 — i.e. C4 hands the
        # predicate half of the placement it tests, which is the whole reason
        # this row is null-sensitive.
        self.assertEqual(sb[0], 0, "the {63,0} block is not block 0")
        h4, n4 = sweep(list(range(1, 32)), {0: sb[0]})
        c1c4 = Fraction(h4, n4)
        self.assertEqual(n4, 31 * 30 * 29)
        self.assertGreater(h, 0, "zero hits is not a measurement; ERROR")
        self.assertGreater(h4, 0, "zero hits under C1+C4; ERROR")
        # King Wen's own placement must be one of them — the same
        # target-drift hole the rotinv leg measured.
        self.assertIn((sb[1], ab[0], ab[1]), passing,
                      "King Wen's own placement of the doubled-trigram blocks "
                      "does not satisfy dav_pureplace — the target has drifted")
        self._check_row("pureplace", c1, c1c4)
        self.assertEqual(str(c1), "7/35960")
        self.assertEqual(str(c1c4), "14/4495")
        _emit_token("PUREPLACE_C1", c1)
        _emit_token("PUREPLACE_C1C4", c1c4)

    def test_both_predicates_are_orientation_blind(self):
        """The pair-preserving null flips each pair independently. Both masses
        above are computed over SLOT placements only, which is sound exactly
        because neither predicate can see an orientation. Measured over every
        one of the 2^32 flips? No — over every flip of the blocks the
        predicates actually read, which is the only thing that could matter,
        plus the whole-sequence flip."""
        for pred, blocks in ((solve.dav_rotinv, self.rotinv_blocks),
                             (solve.dav_pureplace,
                              self.sym_blocks + self.asym_blocks)):
            base = list(KW)
            v0 = pred(base)
            for m in range(1 << len(blocks)):
                seq = list(KW)
                for j, b in enumerate(blocks):
                    if (m >> j) & 1:
                        seq[2 * b], seq[2 * b + 1] = seq[2 * b + 1], seq[2 * b]
                self.assertEqual(pred(seq), v0,
                                 f"{pred.__name__} is orientation-SENSITIVE; "
                                 f"the slot-only enumeration is then invalid")
            self.assertEqual(v0, 1, f"{pred.__name__} must fire on KW")

    def test_filler_does_not_change_the_verdict(self):
        """The enumerations fill unassigned slots in block-index order. If the
        filler could change a verdict, every mass above would be an artefact
        of that choice. Reverse the filler and require the same counts."""
        blocks = self.rotinv_blocks
        real = self._seq
        def rev_seq(assign):
            rest = [p for p in reversed(range(32)) if p not in assign.values()]
            seq, it = [], iter(rest)
            for s in range(32):
                p = assign.get(s)
                if p is None:
                    p = next(it)
                seq.extend(self.pairs[p])
            return seq
        a = sum(1 for sl in itertools.combinations(range(32), 4)
                if solve.dav_rotinv(real(dict(zip(sl, blocks)))))
        b = sum(1 for sl in itertools.combinations(range(32), 4)
                if solve.dav_rotinv(rev_seq(dict(zip(sl, blocks)))))
        self.assertEqual(a, b)
        self.assertGreater(a, 0)

    def test_perm_ncyc_two_sided_p_two_ways(self):
        """CRITIQUE.md's 2026-09-01 correction, re-derived from the evidence
        file two independent ways."""
        self.assertTrue(os.path.exists(self.EVIDENCE),
                        f"{self.EVIDENCE} missing — ERROR, not a pass")
        with open(self.EVIDENCE, encoding="utf-8") as fh:
            ev = fh.read()
        m = re.search(r"\[perm 01 perm_ncyc_bot\][^\n]*?kw=(\d+) "
                      r"below=([\d.]+) at=([\d.]+) above=([\d.]+)", ev)
        self.assertIsNotNone(m, "no perm_ncyc_bot summary line — ERROR")
        kw = int(m.group(1))
        below, at, above = (float(m.group(i)) for i in (2, 3, 4))
        # route 1: the summary line, under the family's frozen convention
        # p = min(1, 2*min(P(X<=kw), P(X>=kw))), atom counted on BOTH sides
        p1 = min(1.0, 2 * min(below + at, at + above))
        # route 2: re-sum the histogram in the same file, never touching the
        # summary line's three aggregates
        hist = {int(a): float(b) for a, b in
                re.findall(r"perm_hist perm_ncyc_bot (\d+) ([\d.eE+-]+)", ev)}
        self.assertGreater(len(hist), 1, "no perm_ncyc_bot histogram — ERROR")
        self.assertAlmostEqual(sum(hist.values()), 1.0, places=6)
        p2 = min(1.0, 2 * min(sum(v for k, v in hist.items() if k <= kw),
                              sum(v for k, v in hist.items() if k >= kw)))
        self.assertAlmostEqual(p1, p2, places=7,
                               msg="the summary aggregates and the histogram "
                                   "in the same evidence file disagree")
        with open(self.CRITIQUE, encoding="utf-8") as fh:
            crit = fh.read()
        pub = f"{p1:.8f}"
        self.assertIn(f"**{pub}**", crit,
                      f"CRITIQUE.md does not publish the re-derived {pub}")
        # the WITHDRAWN figure is the strictly-above doubling; it must be
        # present only as the named withdrawal, never as a live claim
        withdrawn = f"{2 * above:.8f}"
        self.assertIn(f"the withdrawn 0.13 is 2 × {above:.8f} = "
                      f"{withdrawn}", crit,
                      "the withdrawal of 0.13 is no longer stated as such")
        self.assertNotEqual(pub, withdrawn)
        _emit_token("PERM_NCYC_P2", pub)


class TestConstraintsTrialCountsPinned(unittest.TestCase):
    """C4 (2026-09-02): `--constraints`' trial count is a PUBLISHED FIGURE, and
    this makes the coupling mechanical.

    THE DEFECT THIS IS NOT. `print_constraints()` took no argument and the CLI
    called it bare, so `--trials` was silently ignored. That is real, and it is
    also DOCUMENTED — ROAE_PY_CLI.md's `--trials` row and its Examples section
    both say the mode uses its own hard-coded counts and that passing --trials
    "has no effect on its output". The hazard is not the behaviour; it is the
    obvious REPAIR. `--trials` defaults to 100,000 and the function ran 10,000,
    so wiring `trials=args.trials` moves the default run 10x and drags the
    rule-of-three bound `1 in 3,333` (= trials/3) with it — while eight corpus
    sites quote the count and four quote the bound, and nothing anywhere would
    have gone red. Batch C2 caught that and refused to implement it.

    SO THE GATE PINS THE COUPLING, NOT THE NUMBER. Nothing here hard-codes
    10,000 or 3,333. The trial count and the bound are read out of the
    PROGRAM'S OWN OUTPUT, the bound is re-derived from the count, and every
    registered corpus site must agree with what the program printed. Wiring
    --trials is still permitted — it just cannot be done silently any more: it
    goes red at every page it would invalidate, which is exactly the merge C2
    said had to happen in one piece.

    WHAT OTHER REPAIR WOULD ALSO TURN THIS GREEN? Accepting a `trials=` keyword
    and ignoring it. That satisfies the no-wiring leg and the corpus leg and
    every published figure, while leaving the function exactly as unwired as
    before. `test_the_parameter_is_actually_honoured` is the leg that refuses
    it, and it is why the no-wiring leg means anything.

    NO SILENT ZEROS. A corpus file that cannot be read, a run that produces no
    output, or a scan that matches nothing is an ERROR here, never a pass; each
    pattern carries a floor measured against the tree, so an empty scan cannot
    be mistaken for agreement."""

    ROAE = os.path.abspath("roae.py")
    DOCS = ("documentation/GUIDE.md", "documentation/MCKENNA.md",
            "documentation/PROJECT_OVERVIEW.md")
    # (regex, minimum number of matches across DOCS, which figure it quotes)
    # `[\d,]*\d` so a trailing comma in the prose is not captured as a digit
    TRIAL_SITES = ((r"[Zz]ero (?:of|out of) ([\d,]*\d)", 5, "trials"),
                   (r"out of ([\d,]*\d) random permutations", 1, "trials"),
                   (r"random permutations out of ([\d,]*\d)", 1, "trials"),
                   (r"0/([\d,]*\d) sample", 1, "trials"),
                   (r"less than 1 in ([\d,]*\d)", 4, "bound"))

    @classmethod
    def setUpClass(cls):
        r = subprocess.run([sys.executable, cls.ROAE, "--constraints",
                            "--seed", "42"], capture_output=True, text=True)
        if r.returncode != 0 or not r.stdout.strip():
            raise RuntimeError("roae.py --constraints produced no usable "
                               f"output (rc={r.returncode}) — ERROR, not a "
                               f"pass: {r.stderr[-400:]}")
        cls.out = r.stdout

    def _figures(self):
        """The two published figures, read out of the program's own output."""
        t = re.search(r"Results from ([\d,]+) random permutations", self.out)
        c = re.search(r"Pair-constrained trials: ([\d,]+)", self.out)
        b = re.search(r"less than ~1 in ([\d,]+)", self.out)
        for name, m in (("trials", t), ("cond_trials", c), ("bound", b)):
            self.assertIsNotNone(m, f"--constraints did not print {name}; a "
                                    f"figure that cannot be read is an ERROR")
        return (int(t.group(1).replace(",", "")),
                int(c.group(1).replace(",", "")),
                int(b.group(1).replace(",", "")))

    def test_runtime_figures_agree_with_the_declared_constants(self):
        trials, cond, bound = self._figures()
        self.assertEqual(trials, roae.CONSTRAINTS_TRIALS)
        self.assertEqual(cond, roae.CONSTRAINTS_COND_TRIALS)
        # the bound is the rule of three over the SAME count, recomputed here
        self.assertEqual(bound, trials // 3,
                         "the printed 95% upper bound is not trials/3")

    def test_trials_flag_does_not_reach_the_constraints_mode(self):
        """ROAE_PY_CLI.md: 'passing --trials alongside --constraints has no
        effect on its output'. Executed, not read. Byte-identical output is the
        assertion, so a wiring that changed ANY line fails, not just the
        headline count."""
        r = subprocess.run([sys.executable, self.ROAE, "--constraints",
                            "--seed", "42", "--trials", "37"],
                           capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr[-400:])
        self.assertNotEqual(r.stdout.strip(), "", "no output — ERROR")
        self.assertEqual(r.stdout, self.out,
                         "--trials changed --constraints' output; if that is "
                         "intended, the corpus sites listed in this class must "
                         "be re-derived in the SAME merge")

    def test_the_parameter_is_actually_honoured(self):
        """THE WRONG-REPAIR LEG. A print_constraints(trials=...) that accepts
        the keyword and ignores it passes every other leg here. Call it
        directly with counts nothing publishes and require them in the
        output."""
        import io, contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            roae.print_constraints(trials=37, cond_trials=41)
        out = buf.getvalue()
        self.assertNotEqual(out.strip(), "", "no output — ERROR")
        self.assertIn("Results from 37 random permutations", out,
                      "the trials parameter is accepted and ignored")
        self.assertIn("Pair-constrained trials: 41", out,
                      "the cond_trials parameter is accepted and ignored")
        self.assertIn("less than ~1 in 12", out,
                      "the rule-of-three bound is not derived from trials")

    def test_every_published_site_agrees_with_the_program(self):
        trials, _cond, bound = self._figures()
        want = {"trials": f"{trials:,}", "bound": f"{bound:,}"}
        texts = {}
        for d in self.DOCS:
            self.assertTrue(os.path.exists(d), f"{d} missing — ERROR")
            with open(d, encoding="utf-8") as fh:
                texts[d] = fh.read()
        total = 0
        for pat, floor, which in self.TRIAL_SITES:
            hits = []
            for d, txt in texts.items():
                for m in re.finditer(pat, txt):
                    hits.append((d, m.group(1)))
            self.assertGreaterEqual(
                len(hits), floor,
                f"pattern {pat!r} matched {len(hits)} sites, floor {floor} — "
                f"a scan that finds nothing is an ERROR, not agreement")
            for d, got in hits:
                self.assertEqual(got, want[which],
                                 f"{d} quotes {got} where the program printed "
                                 f"{want[which]} ({which})")
            total += len(hits)
        self.assertGreaterEqual(total, 12)
        _emit_token("CONSTRAINTS_TRIALS_PINNED", total)


class TestRoaePyDispatchGates(unittest.TestCase):
    """C2 (2026-09-02): two roae.py defects that both lived in DISPATCH, not in
    the mechanism they broke — the class this harness keeps failing to catch,
    because the mechanism tests green in isolation.

    VERDICT TOKENS. Each gate emits one `KEY=value` line on stdout and asserts it
    WHOLE, so an external runner can gate on
    `python3 tests.py 2>&1 | grep -qx CAST_SEED_DETERMINISTIC=1`. Whole-line, not
    a substring and not a character class: the 2026-08-15 flips-census error came
    from `^BAD_[A-Z_]+=[1-9]`, whose class excludes digits, and both tokens here
    end in a digit too.

    NO GATE HERE MAY PRINT A ZERO FOR AN INPUT IT COULD NOT READ. If a subprocess
    dies, or prints nothing, the token emitted is `=ERROR` and the test fails.
    A checker that reports 0 on a missing input is reporting the absence of
    evidence as evidence of absence, which is the defect shape this project has
    now hit three times."""

    ROAE = os.path.abspath("roae.py")

    def _emit(self, key, value):
        """Print the verdict line and return it, so callers assert the exact line
        rather than infer a verdict from output shape."""
        line = f"{key}={value}"
        _emit_token(key, value)      # C4: whole-line, see _emit_token's note
        return line

    def _run(self, args, cwd=None):
        return subprocess.run([sys.executable, self.ROAE, *args],
                              capture_output=True, text=True, cwd=cwd)

    def test_cast_seed_is_deterministic(self):
        """`--cast --seed N` must be reproducible.

        RED BEFORE (MEASURED 2026-09-02, pre-hoist roae.py): three runs of
        `roae.py --cast --seed 42` produced three DISTINCT sha256s —
        1096f6a0.../5631c28f.../be9160f3... . Cause was dispatch order: `--cast`
        returned above the `_global_seed` assignment, so print_casting()'s
        opening _reseed(9) was a no-op and the reading came off the unseeded
        global RNG. The mechanism was never broken; only the order was, which is
        why `--seed 42` alone and `--entropy --seed 42` were both already
        reproducible and neither caught it.

        THE SEED-SENSITIVITY LEG IS WHAT KEEPS THIS FROM PASSING VACUOUSLY. Three
        equal hashes would also be produced by a --cast that ignored the RNG
        entirely, so seed 43 must differ from seed 42. That comparison is itself
        deterministic — both sides are seeded — so this leg cannot flake."""
        runs = [self._run(["--cast", "--seed", "42"]) for _ in range(3)]
        other = self._run(["--cast", "--seed", "43"])
        bad = [r for r in runs + [other] if r.returncode != 0 or not r.stdout]
        if bad:
            line = self._emit("CAST_SEED_DETERMINISTIC", "ERROR")
            self.fail(f"{line}: roae.py --cast did not produce output "
                      f"(rc={[r.returncode for r in bad]}); an unreadable "
                      f"result is an ERROR, not a 0. stderr: {bad[0].stderr[-500:]!r}")
        same = len({r.stdout for r in runs}) == 1
        sensitive = other.stdout != runs[0].stdout
        line = self._emit("CAST_SEED_DETERMINISTIC",
                          "1" if (same and sensitive) else "0")
        self.assertEqual(line, "CAST_SEED_DETERMINISTIC=1",
                         "--cast --seed 42 must be byte-identical across runs "
                         f"(identical={same}) and must differ from --seed 43 "
                         f"(sensitive={sensitive})")

    def test_verify_gate_is_cwd_independent(self):
        """`roae.py --verify` must give the same verdict from any directory.

        RED BEFORE (MEASURED 2026-09-02, pre-fix roae.py): run from `/`, the gate
        printed `[FAIL] KW table identical to solve.py's <- could not load
        solve.py: ... '/solve.py'` and `ROAE VERIFY: 1 FAILURE(S)`, rc 1, with
        nothing whatever wrong — solve.py was resolved CWD-relative. A gate that
        reports a failure that is not there is as useless as one that misses a
        failure that is, and it is worse in CI, which cds.

        FAIL-CLOSED IS ASSERTED, NOT ASSUMED. The companion test below builds the
        two real defects — sibling absent, and sibling present but drifted — and
        requires rc 1 for each. Without that leg this test would pass just as
        happily against a --verify that had been changed to skip the cross-file
        check instead of relocating it, which is exactly how a checker silently
        narrows its own scope while still reporting PASS."""
        here = self._run(["--verify"])
        away = self._run(["--verify"], cwd=os.path.abspath(os.sep))
        if not here.stdout or not away.stdout:
            line = self._emit("ROAE_VERIFY_CWD_INDEPENDENT", "ERROR")
            self.fail(f"{line}: roae.py --verify produced no output from one of "
                      f"the two directories (rc {here.returncode}/{away.returncode})")
        agree = (here.returncode == away.returncode == 0
                 and "ROAE VERIFY: ALL 11 CHECKS PASS" in here.stdout
                 and "ROAE VERIFY: ALL 11 CHECKS PASS" in away.stdout)
        line = self._emit("ROAE_VERIFY_CWD_INDEPENDENT", "1" if agree else "0")
        self.assertEqual(line, "ROAE_VERIFY_CWD_INDEPENDENT=1",
                         "--verify must pass from both the repo directory and "
                         f"/ (rc {here.returncode}/{away.returncode})\n"
                         f"--- from /:\n{away.stdout[-800:]}")

    def test_verify_gate_still_fails_closed_on_a_broken_sibling(self):
        """The negative control for the test above: the relocated lookup must
        still be FALSE when its target is absent or wrong.

        Two constructed defects, in a scratch directory so the real tree is never
        touched: (1) roae.py with NO sibling solve.py; (2) roae.py beside a
        solve.py whose King Wen table has had two entries transposed. Both must
        exit 1. (2) is the leg that proves the check still compares tables rather
        than merely locating a file."""
        tmp = tempfile.mkdtemp(prefix="c2_verify_")
        try:
            alone = os.path.join(tmp, "alone")
            os.makedirs(alone)
            shutil.copy(self.ROAE, alone)
            r1 = subprocess.run([sys.executable, os.path.join(alone, "roae.py"),
                                 "--verify"], capture_output=True, text=True)
            self.assertEqual(r1.returncode, 1,
                             "--verify must FAIL when the sibling solve.py is "
                             "absent; an unreadable input is an ERROR, not a pass")
            self.assertIn("could not load solve.py", r1.stdout)

            drift = os.path.join(tmp, "drift")
            os.makedirs(drift)
            shutil.copy(self.ROAE, drift)
            with open(os.path.abspath("solve.py")) as fh:
                src = fh.read()
            old = "    0b111111, 0b000000, 0b010001, 0b100010,"
            new = "    0b111111, 0b000000, 0b100010, 0b010001,"
            self.assertEqual(src.count(old), 1,
                             "the KW literal this control transposes moved; "
                             "re-anchor it rather than deleting the control")
            with open(os.path.join(drift, "solve.py"), "w") as fh:
                fh.write(src.replace(old, new))
            r2 = subprocess.run([sys.executable, os.path.join(drift, "roae.py"),
                                 "--verify"], capture_output=True, text=True)
            self.assertEqual(r2.returncode, 1,
                             "--verify must FAIL when the sibling solve.py's KW "
                             "table disagrees with roae.py's")
            self.assertIn("disagree on the King Wen sequence", r2.stdout)
        finally:
            shutil.rmtree(tmp, ignore_errors=True)


class TestSeedStreamDisjointness(unittest.TestCase):
    """C2 (2026-09-02): roae.py's four sampling streams are separated by fixed
    seed offsets, and nothing bounded the index that is added on top of them.

    THE DEFECT IS A CIRCULARITY, NOT A SLOWDOWN. The pre-registered H1/H3 test
    draws its thresholds from seed+20000+b and evaluates against seed+30000+b.
    At --gs-batches 20000 those are the SAME stream for 10,000 of the batches,
    so the evaluation re-draws the samples that set the thresholds it is judged
    against, and the run completes and prints verdicts with no error and no
    visible symptom. roae.py's own source comment named the collision and ended
    "Bound it before raising it"; nothing bounded it.

    THIS TEST EXHIBITS THE COLLISION ARITHMETICALLY rather than pinning the
    constant 10000. A test that only asserted "batches >= 10000 exits nonzero"
    would still pass if someone moved the offsets to 5,000 apart and left the
    limit alone, which is the exact way a guard silently stops guarding."""

    ROAE = os.path.abspath("roae.py")

    def test_the_collision_the_guard_defends_against_is_real(self):
        off = roae._SEED_STREAM_OFFSETS
        # The exhibited case from the followups: seed 42, threshold batch 10005,
        # evaluation batch 5. Derived from the offsets, not typed as a constant.
        seed = 42
        thr = seed + off["prereg_threshold"] + 10005
        ev = seed + off["prereg_eval"] + 5
        self.assertEqual(thr, ev,
                         "the offsets no longer produce the collision this guard "
                         "was built for; re-derive the bound before trusting it")
        self.assertEqual(off["prereg_eval"] - off["prereg_threshold"],
                         roae._SEED_STREAM_GAP,
                         "the guard's gap constant no longer equals the real "
                         "offset spacing — the bound is now arbitrary")
        # The worker bound is derived the same way: the probe stream is
        # seed+100+w and the rarity stream is seed+10000+b, so the first
        # colliding worker index is exactly the spacing between them. Assert the
        # guard's behaviour AT that derived index rather than at a typed 9900.
        first_bad_w = off["rarity"] - off["probe"]
        self.assertEqual(seed + off["probe"] + first_bad_w,
                         seed + off["rarity"] + 0,
                         "probe/rarity spacing changed; re-derive the worker bound")
        with self.assertRaises(SystemExit):
            roae._guard_seed_stream_disjointness(1, first_bad_w)
        roae._guard_seed_stream_disjointness(1, first_bad_w - 1)

    def test_guard_refuses_colliding_batch_and_worker_counts(self):
        for batches, workers in ((10000, 1), (10001, 1), (20000, 1), (0, 1),
                                 (100, 9900), (100, 0)):
            with self.subTest(batches=batches, workers=workers):
                with self.assertRaises(SystemExit,
                                       msg=f"batches={batches} workers={workers} "
                                           "was accepted"):
                    roae._guard_seed_stream_disjointness(batches, workers)

    def test_guard_accepts_the_largest_safe_configuration(self):
        # A guard that refuses everything also "passes" the test above. 9999 is
        # the largest batch count with no collision under the guard's own bound,
        # and it must be accepted.
        roae._guard_seed_stream_disjointness(9999, 9899)
        roae._guard_seed_stream_disjointness(1, 1)

    def test_cli_exits_nonzero_before_sampling(self):
        r = subprocess.run([sys.executable, self.ROAE, "--prereg-h1h3",
                            "--gs-batches", "20000", "--gs-samples", "10",
                            "--ph-thr-samples", "10", "--gs-workers", "1"],
                           capture_output=True, text=True)
        out = r.stdout + r.stderr
        if not out:
            _emit_token("SEED_STREAMS_DISJOINT", "ERROR")
            self.fail("SEED_STREAMS_DISJOINT=ERROR: roae.py produced no output; "
                      "an unreadable result is an ERROR, not a 0")
        refused = (r.returncode != 0
                   and "seed-stream" in out
                   # the guard must run BEFORE any sampling: the banner the
                   # sampler prints first must be absent.
                   and "Pre-registered H1/H3 test" not in out)
        _emit_token("SEED_STREAMS_DISJOINT", 1 if refused else 0)
        self.assertTrue(refused,
                        f"rc={r.returncode}; output must refuse before sampling "
                        f"starts:\n{out[:800]}")


class TestRotationsAreNotC3Symmetries(unittest.TestCase):
    """C2 (2026-09-02): the TR-7 6 rotation counterexample, mechanically pinned
    (Codex V2-F09 #1, code half; prose half landed in batch P36).

    WHAT WAS WRONG. TR-7 6 and CIRCULAR_KING_WEN.md said the 32 pair-slot
    rotations act as symmetries of the circular system. Under this repository's
    absolute-position C3 they do not: 21 of the 31 non-identity rotations exceed
    the 776 ceiling. The corrected prose publishes 21 / 888 / 1240 / 1320 / 10,
    but the only reproduction was a `python3 -c` one-liner printed inside the
    report, so a drift in verify.c3_of_ordering would have falsified five
    published figures with nothing red.

    THE THIRD DERIVATION IS THE POINT. verify.py --recount-finite now computes
    the rotation C3s by both of its own routes and gates their agreement. This
    test does NOT take that agreement on the instrument's word: it re-derives
    rotate-4 and the violation count HERE, from SPECIFICATION C3's definition
    over the KW literal, importing nothing from verify. If both of verify.py's
    routes drifted together, this is what stays false.

    RED-TESTED 2026-09-02 against two constructed defects in a scratch copy:
    (i) c3_of_ordering summing 11 of its 12 complement couples -> tokens 20 /
    872 / 1224, rc 1; (ii) c3_of_ordering CIRCULARIZED (min(d, 32-d)), which is
    the very error the retracted prose made -> KW_ROTATIONS_VIOLATING_C3=0,
    every rotation constant at 664, rc 1. Neither defect was caught by the
    existing _c3_couples known-answer anchor, which recomputes G by its own
    plain-abs route and stayed green through both."""

    TOKENS = {"KW_ROT_C3_DERIVATIONS_AGREE=1",
              "KW_ROTATIONS_VIOLATING_C3=21",
              "KW_ROTATIONS_SURVIVING_C3=10",
              "KW_ROT4_C3=888",
              "KW_ROT16_C3=1240",
              "KW_ROT_C3_MAX=1320"}

    @staticmethod
    def _c3_from_spec(seq):
        """SPECIFICATION C3, written out here rather than imported: the sum over
        all 64 values of |pos(v) - pos(v ^ 63)|."""
        pos = {h: i for i, h in enumerate(seq)}
        return sum(abs(pos[v] - pos[v ^ 63]) for v in range(64))

    def _rotated(self, k):
        return [h for slot in range(32)
                for h in (KW[2 * ((slot + k) % 32)], KW[2 * ((slot + k) % 32) + 1])]

    def test_third_derivation_reproduces_the_published_rotation_figures(self):
        c3 = [self._c3_from_spec(self._rotated(k)) for k in range(32)]
        self.assertEqual(c3[0], 776, "rotation 0 must be KW itself")
        self.assertEqual(c3[4], 888)
        self.assertEqual(c3[16], 1240)
        self.assertEqual(max(c3), 1320)
        self.assertEqual(sum(v > 776 for v in c3[1:]), 21)
        self.assertEqual(sum(v <= 776 for v in c3[1:]), 10)

    def test_recount_finite_emits_the_rotation_verdict_tokens(self):
        r = subprocess.run([sys.executable, "verify.py", "--recount-finite"],
                           capture_output=True, text=True)
        if not r.stdout:
            self.fail("verify.py --recount-finite produced no output; an "
                      "unreadable result is an ERROR, not a pass")
        lines = set(r.stdout.splitlines())
        missing = sorted(t for t in self.TOKENS if t not in lines)
        self.assertEqual(missing, [],
                         "verify.py --recount-finite did not emit these verdict "
                         f"lines VERBATIM: {missing}\n"
                         "(whole-line match: a token differing only in its digits "
                         "is a FAILURE, not a near-miss)\n"
                         + "\n".join(l for l in r.stdout.splitlines()
                                      if l.startswith("KW_ROT")))
        self.assertEqual(r.returncode, 0,
                         "--recount-finite must exit 0 when every gate matches")


class TestRevIsNotPartner(unittest.TestCase):
    """C3 (2026-09-02): the rev/partner split, mechanically pinned
    (Codex V2-F53 #4, code half; prose half landed in batch P33).

    WHAT WAS WRONG. SYMMETRY_SEARCH.md's Group-structure paragraph gave
    "rev maps every hexagram to its partner" as the REASON reversal fixes
    every pair-sequence. It is false for exactly 8 of the 64 -- the
    palindromes {0, 12, 18, 30, 33, 45, 51, 63}, which rev fixes and whose C1
    partner is their complement h ^ 63. The phrasing is registered in
    RETRACTED_PHRASES.tsv, but GATE 3's corpus is tracked *.md, and nothing
    anywhere recomputed either half -- so the false reason could have been
    reintroduced with nothing red.

    WHY THE CONCLUSION IS PINNED TOO. The paragraph's conclusion -- rev fixes
    all 32 C1 pairs setwise -- is TRUE and survived the correction. A gate that
    pinned only the 56 would stay green against a rewrite that kept the count
    and dropped the conclusion, which is the scope-narrowing failure this
    project keeps hitting. Both are asserted.

    THE THIRD DERIVATION IS THE POINT. verify.py --recount-finite computes the
    count by two of its own routes and gates their agreement. This test does
    not take that on the instrument's word: it re-derives rev, partner and the
    32 pairs HERE from SPECIFICATION C1's definition, importing nothing from
    verify. If both of verify.py's routes drifted together, this is what stays
    false.

    RED-TESTED 2026-09-02, four ways -- see the private followups entry."""

    TOKENS = {"REV_EQUALS_PARTNER_COUNT=56",
              "REV_FIXES_ALL_PAIRS=yes"}

    @staticmethod
    def _rev(h):
        """SPECIFICATION 6-bit reversal, written out here rather than imported."""
        return sum(((h >> b) & 1) << (5 - b) for b in range(6))

    @classmethod
    def _partner(cls, h):
        """SPECIFICATION C1: partner(h) = rev(h) if rev(h) != h else h ^ 63."""
        r = cls._rev(h)
        return r if r != h else h ^ 63

    def test_third_derivation_reproduces_the_rev_partner_split(self):
        agree = [h for h in range(64) if self._rev(h) == self._partner(h)]
        dissent = sorted(set(range(64)) - set(agree))
        self.assertEqual(len(agree), 56)
        self.assertEqual(dissent, [0, 12, 18, 30, 33, 45, 51, 63])
        self.assertTrue(all(self._rev(h) == h for h in dissent),
                        "the dissenters must be exactly rev's fixed points")
        self.assertTrue(all(self._partner(h) == h ^ 63 for h in dissent),
                        "each dissenter's C1 partner must be its complement")
        seen, pairs = set(), []
        for h in range(64):
            if h in seen:
                continue
            q = self._partner(h)
            seen.update((h, q))
            pairs.append((h, q))
        self.assertEqual(len(pairs), 32)
        self.assertTrue(all({self._rev(a), self._rev(b)} == {a, b}
                            for a, b in pairs),
                        "rev must fix all 32 C1 pairs setwise -- the surviving "
                        "half of the retracted paragraph")

    def test_recount_finite_emits_the_rev_partner_verdict_tokens(self):
        r = subprocess.run([sys.executable, "verify.py", "--recount-finite"],
                           capture_output=True, text=True)
        if not r.stdout:
            self.fail("verify.py --recount-finite produced no output; an "
                      "unreadable result is an ERROR, not a pass")
        lines = set(r.stdout.splitlines())
        missing = sorted(t for t in self.TOKENS if t not in lines)
        self.assertEqual(missing, [],
                         "verify.py --recount-finite did not emit these verdict "
                         f"lines VERBATIM: {missing}\n"
                         "(whole-line match: a token differing only in its digits "
                         "is a FAILURE, not a near-miss)\n"
                         + "\n".join(l for l in r.stdout.splitlines()
                                      if l.startswith("REV_")))
        self.assertEqual(r.returncode, 0,
                         "--recount-finite must exit 0 when every gate matches")


class TestParityAlternationScope(unittest.TestCase):
    """C3 (2026-09-02): check_parity_alternation()'s docstring cited the wrong
    lemma and promised more than it delivers (Codex V2-F42 #2 and #3, code half;
    the two markdown twins were fixed in prose batch P42).

    WHAT WAS WRONG. (i) The docstring attributed pair-parity well-definedness to
    PARITY_ALTERNATION.md's "Lemma 3" and then restated Lemma 1's proof verbatim
    in substance; Lemma 3 is that document's TRANSITION-parity result. (ii) Its
    opening line read "Re-derive every published figure in PARITY_ALTERNATION.md"
    while two of that page's figures -- the 48-element relabeling group and
    Moore 2005's 16/18 King Wen compliance -- are in none of the command's 18
    output lines. Both defects were corrected on the two markdown pages on
    2026-09-02 and left live in the docstring, so until this landed the source
    contradicted the two pages it cites. GATE 3 cannot see it: its corpus is
    tracked *.md plus reports/evidence/**, never *.py.

    WHY THE LEMMA LEG IS DERIVED, NOT PINNED. Asserting the literal string
    "Lemma 1" would stay green if PARITY_ALTERNATION.md renumbered its lemmas --
    the same class of failure as the original slip. Instead the number is READ
    OUT of the page, by finding the lemma whose statement is the popcount
    congruence, and the docstring is required to cite that one. An unreadable or
    unmatchable page is an ERROR here, never a pass.

    WHY THE 18 KEYS ARE PINNED EXACTLY. Both corrected pages now publish the
    sentence "outside that command's 18-line output". That figure had no gate:
    adding one print would have falsified a published sentence with nothing red.
    Pinning the exact key list -- not a line count, and not a "does the output
    mention X" test, which would pass on any line that happened to contain the
    string -- is what makes the scope claim checkable in both directions.

    RED-TESTED 2026-09-02 -- see the private followups entry."""

    MD = "documentation/PARITY_ALTERNATION.md"

    EXPECTED_KEYS = [
        "KW_TRANSITIONS", "KW_DISTANCE_MULTISET",
        "KW_DISTANCE_MULTISET_MATCHES_PUBLISHED", "KW_ODD_TRANSITIONS",
        "PAIR_CLASS_WELL_DEFINED", "PAIR_CLASS_SPLIT",
        "PAIR_CLASS_SPLIT_IS_16_16", "KW_CLASS_ALTERNATIONS",
        "KW_HAS_THE_FORCED_15", "KW_ODD_TRANSITIONS_EQUALS_ALTERNATIONS",
        "C4_PINS_FIRST_PAIR_TO_EVEN_CLASS", "ARRANGEMENTS_15_CHANGES_DP",
        "ARRANGEMENTS_15_CHANGES_CLOSED_FORM", "DP_AGREES_WITH_CLOSED_FORM",
        "TOTAL_ARRANGEMENTS_C32_16", "REDUCTION_FACTOR",
        "PARITY_ALTERNATION", "SCOPE",
    ]

    @staticmethod
    def _slurp(path):
        with open(path, encoding="utf-8") as fh:
            return fh.read()

    def _docstring(self):
        src = self._slurp("verify.py")
        m = re.search(r'def check_parity_alternation\(\):\n    """(.*?)"""',
                      src, re.S)
        if m is None:
            self.fail("could not locate check_parity_alternation()'s docstring "
                      "in verify.py; an unreadable input is an ERROR, not a pass")
        return m.group(1)

    def test_docstring_cites_the_lemma_the_page_actually_states(self):
        md = self._slurp(self.MD)
        cited = [int(n) for n, body in
                 re.findall(r'\*\*Lemma (\d+) \([^)]*\)\.\*\*([^\n]*)', md)
                 if "popcount(partner(h))" in body]
        if len(cited) != 1:
            self.fail(f"{self.MD} does not state exactly one popcount-congruence "
                      f"lemma (found {cited}); an unmatchable input is an ERROR, "
                      "not a pass")
        want = cited[0]
        doc = self._docstring()
        got = re.findall(r'Lemma (\d+) of that document', doc)
        self.assertEqual(got, [str(want)],
                         f"check_parity_alternation() must attribute pair-parity "
                         f"well-definedness to {self.MD}'s Lemma {want} (the "
                         f"popcount congruence); the docstring cites {got}")

    def test_docstring_does_not_promise_every_figure_on_the_page(self):
        doc = self._docstring()
        self.assertNotIn("every published figure", doc,
                         "the docstring must not re-promise every figure on "
                         "PARITY_ALTERNATION.md: two of them are outside this "
                         "command and have their own reproducers")

    def test_the_command_emits_exactly_the_eighteen_published_keys(self):
        r = subprocess.run([sys.executable, "verify.py",
                            "--check-parity-alternation"],
                           capture_output=True, text=True)
        if not r.stdout:
            self.fail("verify.py --check-parity-alternation produced no output; "
                      "an unreadable result is an ERROR, not a pass")
        lines = r.stdout.splitlines()
        self.assertEqual([l.split("=", 1)[0] for l in lines], self.EXPECTED_KEYS,
                         "both PARITY_ALTERNATION.md and VERIFY.md publish the "
                         "sentence \"outside that command's 18-line output\"; "
                         "changing this key list falsifies it")
        self.assertIn("PARITY_ALTERNATION=PASS", lines)
        self.assertEqual(r.returncode, 0)

    def test_the_two_out_of_scope_figures_have_live_reproducers(self):
        r = subprocess.run([sys.executable, "solve.py",
                            "--symmetry-completeness"],
                           capture_output=True, text=True)
        if not r.stdout:
            self.fail("solve.py --symmetry-completeness produced no output; an "
                      "unreadable result is an ERROR, not a pass")
        self.assertIn("[SC-7 partner-commuters among 720 == 48 == C_S6(rev)] PASS",
                      r.stdout.splitlines(),
                      "PARITY_ALTERNATION.md redirects its 48-element group "
                      "figure to leg SC-7; a dead redirect is the same defect "
                      "as a wrong one")
        m = subprocess.run(
            [sys.executable, "-c",
             "import solve; print(18 - "
             "len(solve.h2_parity_slots(list(solve.binary_hexagrams))))"],
            capture_output=True, text=True)
        if not m.stdout.strip():
            self.fail("the Moore 16/18 one-liner produced no output; an "
                      "unreadable result is an ERROR, not a pass")
        self.assertEqual(m.stdout.strip(), "16",
                         "PARITY_ALTERNATION.md publishes this one-liner as the "
                         "reproducer for Moore 2005's 16/18 KW compliance")


class TestSatEncodeHeaderNamesTheFileContents(unittest.TestCase):
    """C3 (2026-09-02): the DIMACS header claimed constraints the file does not
    contain (P07 residue, and its unreported sibling).

    WHAT WAS WRONG. p3_sat_encode() built "c constraints: ..." from the REQUEST
    flags, not from what it emitted. --sat-c3=pb wrote "C1+C2+C3(pb)" although
    the C3 bound goes only to the parallel .opb, so a pure-#SAT counter aimed at
    the .cnf counted C1nC2(nC4) while the header told it C3 was enforced.
    SOLVE_PY_CLI.md carried a standing "do not trust the .cnf's own comment
    header" warning in place of the fix.

    THE SIBLING NOBODY CHARGED. --sat-c5 appended "+C5" the same way, and C5 in
    this encoder is deferred/superseded: it emits NO clause at all, only a
    status entry in the sidecar JSON. --sat-c3=adder is the third instance. The
    charge named C3(pb); the class is "the header echoes the flags".

    WHY THE FIRST LEG IS SEMANTIC, NOT TEXTUAL. Asking whether the header
    "mentions C3" would pass on any wording that happened to contain the string,
    and would pass equally against a header that had simply been deleted. The
    first leg instead MEASURES that C3 and C5 contribute zero clauses: the pb
    encoding's clause list is the none-mode list plus exactly 3 x 262,144
    aux-linking clauses, and the none-mode list is a prefix of it. Only then is
    the header required to name C1+C2(+C4) and nothing else. If C3 or C5 ever
    gain real encoders here, this leg goes red and forces the header to move
    with them -- which is the coupling whose absence caused the defect.

    RED-TESTED 2026-09-02 -- see the private followups entry."""

    AUX_LINK_CLAUSES = 3 * 64 * 64 * 64      # 3 linking clauses per pair[v][i][j]

    @staticmethod
    def _header(path):
        out = []
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                if not line.startswith(("c ", "* ")):
                    break
                out.append(line.rstrip("\n"))
        return out

    def test_c3_and_c5_contribute_no_clauses_and_the_header_says_so(self):
        with tempfile.TemporaryDirectory() as d:
            plain = os.path.join(d, "plain.cnf")
            pb = os.path.join(d, "pb.cnf")
            solve.p3_sat_encode(plain, include_c3="none", include_c4=True,
                                include_c5=False)
            solve.p3_sat_encode(pb, include_c3="pb", include_c4=True,
                                include_c5=True)

            def clauses(path):
                with open(path, encoding="utf-8") as fh:
                    return [l for l in fh if l[0] not in "c*p"]

            a, b = clauses(plain), clauses(pb)
            if not a or not b:
                self.fail("p3_sat_encode wrote no clauses; an empty result is "
                          "an ERROR, not a pass")
            self.assertEqual(len(b) - len(a), self.AUX_LINK_CLAUSES,
                             "the pb encoding must differ from the plain one by "
                             "the aux-linking clauses ALONE: C3's bound lives in "
                             "the .opb and C5 is deferred, so neither may add a "
                             "clause to the DIMACS file")
            self.assertEqual(b[:len(a)], a,
                             "the plain clause list must be a prefix of the pb "
                             "one; if it is not, something other than the aux "
                             "linking changed and the count above is a coincidence")

            hdr = self._header(pb)
            claims = [l.split(":", 1)[1].strip() for l in hdr
                      if l.startswith("c constraints:")]
            self.assertEqual(claims, ["C1+C2+C4"],
                             "the DIMACS header must name what is IN the file. "
                             f"Header was:\n" + "\n".join(hdr))
            absent = " ".join(l for l in hdr if l.startswith("c NOT in this file:"))
            self.assertIn("C3", absent,
                          "the header must say where the C3 bound actually is")
            self.assertIn("C5", absent,
                          "the header must say that C5 is not encoded here")

    def test_the_opb_redirect_is_not_dead(self):
        with tempfile.TemporaryDirectory() as d:
            pb = os.path.join(d, "pb.cnf")
            solve.p3_sat_encode(pb, include_c3="pb", include_c4=True,
                                include_c5=False)
            opb = pb + ".opb"
            self.assertTrue(os.path.exists(opb),
                            "--sat-c3=pb must write the .opb the header points at")
            hdr = self._header(opb)
            self.assertTrue(any(l.startswith("* constraints:") and "C3(pb)" in l
                                for l in hdr),
                            "the .opb header must claim the C3 bound it carries")
            with open(opb, encoding="utf-8") as fh:
                bounds = [l for l in fh if l.rstrip("\n").endswith("<= 776 ;")]
            self.assertEqual(len(bounds), 1,
                             "the .opb must carry exactly one C3 <= 776 PB "
                             "constraint; a header that claims C3 over a file "
                             "without it is the same defect one level up")


class TestReconstructVerdictIsNotRefuted(unittest.TestCase):
    """C3 (2026-09-02): `solve.py --reconstruct` printed a REFUTED claim to
    users on every default run (P06 residue).

    WHAT WAS WRONG. The mode's closing summary read "The specification's
    uniqueness holds globally". Global uniqueness of C1-C7 was refuted on
    2026-07-02 -- about 5.21e31 orderings satisfy C1-C7 over the full space --
    and even inside the enumerated datasets 14 non-KW records survive
    C6+C7+boundary-4 at 560T. SOLVE.md question 4 carried "a correction to
    solve.py is pending" in place of the fix; the docs were honest and the
    shipped tool was not. The same paragraph named a second live overclaim, the
    unqualified "Reconstruction matches King Wen exactly", which is true by
    construction because the routine replays King Wen's own choice; that is now
    scoped in the output too.

    WHY THE FIGURES ARE READ OUT OF THE PAGE. Asserting only that the retracted
    sentence is GONE would pass equally against a repair that deleted the
    summary, or the whole mode, rather than correcting it -- the absent-target
    failure this project keeps hitting. So the two published figures the
    replacement rests on are sourced from SPECIFICATION.md at test time and
    required to appear in the runtime output. If the page's figures move and the
    printout does not, this goes red; if the page stops stating them, that is an
    ERROR here, not a pass.

    RED-TESTED 2026-09-02 -- see the private followups entry."""

    RETRACTED = "The specification's uniqueness holds globally"

    def _spec_figures(self):
        with open("documentation/SPECIFICATION.md", encoding="utf-8") as fh:
            md = fh.read()
        if "14 non-KW records still survive at 560T" not in md and \
           "14 non-KW records survive C6+C7+boundary-4 at 560T" not in md:
            self.fail("SPECIFICATION.md no longer states the 14-survivor figure; "
                      "an unmatchable input is an ERROR, not a pass")
        if "5.21×10³¹" not in md:
            self.fail("SPECIFICATION.md no longer states the 5.21e31 full-space "
                      "survivor count; an unmatchable input is an ERROR, not a pass")
        return ("14", "5.21e31")

    def test_reconstruct_does_not_print_the_refuted_uniqueness_claim(self):
        r = subprocess.run([sys.executable, "solve.py", "--reconstruct"],
                           capture_output=True, text=True)
        if not r.stdout:
            self.fail("solve.py --reconstruct produced no output; an unreadable "
                      "result is an ERROR, not a pass")
        self.assertNotIn(self.RETRACTED, r.stdout,
                         "--reconstruct must not print the claim refuted on "
                         "2026-07-02")
        self.assertIn("✓ Reconstruction matches King Wen exactly.", r.stdout,
                      "the mode itself must still work; a repair that removed "
                      "the summary by removing the mode is not a repair")
        self.assertIn("TRUE BY CONSTRUCTION", r.stdout,
                      "the match is a replay of King Wen's own choices and the "
                      "output must say so")

    def test_the_closing_scope_carries_the_published_refutation_figures(self):
        n_survivors, full_space = self._spec_figures()
        r = subprocess.run([sys.executable, "solve.py", "--reconstruct"],
                           capture_output=True, text=True)
        if not r.stdout:
            self.fail("solve.py --reconstruct produced no output; an unreadable "
                      "result is an ERROR, not a pass")
        tail = r.stdout.split("Reconstruction matches King Wen exactly.", 1)[-1]
        self.assertIn("REFUTED 2026-07-02", tail)
        self.assertIn(full_space, tail,
                      "the closing scope must carry SPECIFICATION.md's full-space "
                      "survivor count")
        self.assertIn(f"{n_survivors} non-KW records", tail,
                      "the closing scope must carry SPECIFICATION.md's "
                      "within-dataset survivor count")


class TestHbBandIsDescribedAsImplemented(unittest.TestCase):
    """C3 (2026-09-02): the TR-8 H-b tolerance was described as "5 sigma" two
    lines above the `+ 3.0` it actually applies (P07 residue, and its sibling in
    the shipped artifact).

    WHAT WAS WRONG. `_tr8_finish` gates the pool's null calibration with
    `abs(hb - exp_hb) <= 5.0 * sigma + 3.0`. Its own comment called 5 sigma "the
    frozen tolerance", and the `h_b_note` field written into every run's
    results.json said "5-sigma Poisson band" -- so the artifact a reader keeps
    understated the band that was actually applied. SOLVE_PY_CLI.md has always
    carried the correct `|observed - expected| <= 5σ + 3`, with a paragraph on
    why the +3 matters at small pool sizes; only the code disagreed with it.

    HOW THE COEFFICIENTS ARE OBTAINED. Not by reading the comment, and not by
    matching the source text -- by EVALUATING the predicate's right-hand side at
    sigma = 0 and sigma = 1. The intercept and slope that come back are the band
    the code applies, whatever it is written as. Those two numbers are then
    required to appear in the prose page and in the shipped note. Change 5.0 or
    3.0 and all three legs go red together; that coupling is what was missing.

    RED-TESTED 2026-09-02 -- see the private followups entry."""

    def _predicate_rhs(self):
        with open("solve.py", encoding="utf-8") as fh:
            src = fh.read()
        m = re.search(r'hb_ok = abs\(hb - exp_hb\) <= (.+)', src)
        if m is None:
            self.fail("could not locate the H-b band predicate in solve.py; an "
                      "unreadable input is an ERROR, not a pass")
        return m.group(1).strip()

    def test_the_band_the_code_applies_is_five_sigma_plus_three(self):
        rhs = self._predicate_rhs()
        f = lambda sig: eval(rhs, {"__builtins__": {}}, {"sigma": sig})
        intercept, slope = f(0.0), f(1.0) - f(0.0)
        self.assertEqual((slope, intercept), (5.0, 3.0),
                         f"H-b band changed: RHS is {rhs!r}. If that is "
                         "intentional, SOLVE_PY_CLI.md and h_b_note must move "
                         "with it -- which is what the next two legs enforce")

    def test_the_published_page_states_the_band_the_code_applies(self):
        with open("documentation/SOLVE_PY_CLI.md", encoding="utf-8") as fh:
            md = fh.read()
        self.assertIn("`|observed − expected| ≤ 5σ + 3`", md,
                      "SOLVE_PY_CLI.md must state the band _tr8_finish applies")

    def test_the_shipped_note_states_the_band_the_code_applies(self):
        with open("solve.py", encoding="utf-8") as fh:
            src = fh.read()
        m = re.search(r'"h_b_note": (.+?)% Fraction', src, re.S)
        if m is None:
            self.fail("could not locate h_b_note in solve.py; an unreadable "
                      "input is an ERROR, not a pass")
        note = m.group(1)
        self.assertIn("5*sigma + 3", note,
                      "results.json's h_b_note is the description a reader keeps "
                      "with the artifact; it must name the band that was applied, "
                      "not the sigma term alone")


class TestInfoContentLeadsWithTheMeasuredLedger(unittest.TestCase):
    """C3 (2026-09-02): `solve.py --info` printed retired figures as its answer
    (P06 residue).

    WHAT WAS WRONG. The command's headline totals were "~176.3 of 296.0 bits
    removed, ~119.7 remaining", from a heuristic ladder whose last rung is an
    explicit guess ("est. ~1 in 50,000"). SOLVE.md retired those numbers on
    2026-08-30 -- they match no published scope and understate the measured
    C1-C5 population by ~100x -- and recorded, in the correction itself, that
    the tool still printed them. It did, for three more days.

    WHY THE FIGURES ARE DERIVED, NOT TYPED. The replacement block computes
    log2 of H2_N_CAN, the same constant solve.py already uses for the C1-C5
    population, so the command cannot drift away from the ledger row it cites.
    This test re-derives both figures HERE from the module constant and from the
    published 5.21e31, and requires the printed report to carry them -- so a
    later hand-edit of the printed text, or a change to H2_N_CAN that does not
    reach the print, is red. It also requires the retired totals to still be
    labelled: keeping the ladder is fine, presenting it as the answer is not.

    RED-TESTED 2026-09-02 -- see the private followups entry."""

    def _info(self):
        r = subprocess.run([sys.executable, "solve.py", "--info"],
                           capture_output=True, text=True)
        if not r.stdout:
            self.fail("solve.py --info produced no output; an unreadable result "
                      "is an ERROR, not a pass")
        self.assertEqual(r.returncode, 0)
        return r.stdout

    def test_the_measured_bits_are_log2_of_the_published_populations(self):
        import math
        out = self._info()
        can = math.log2(solve.H2_N_CAN)
        c67 = math.log2(5.21e31)
        self.assertAlmostEqual(can, 126.6, places=1,
                               msg="H2_N_CAN moved; TR-9's ledger row and this "
                                   "command's report must move together")
        tail = out.split("--- MEASURED", 1)
        self.assertEqual(len(tail), 2,
                         "--info must close on the MEASURED block, not on the "
                         "retired ladder")
        tail = tail[1]
        self.assertIn(f"2^{can:.1f}", tail,
                      "the measured C1-C5 bit figure must be log2(H2_N_CAN)")
        self.assertIn(f"{296.0 - can:.1f}", tail,
                      "the removed-bits figure must be 296.0 - log2(H2_N_CAN)")
        self.assertIn(f"2^{c67:.1f}", tail,
                      "the C1-C7 bit figure must be log2(5.21e31)")

    def test_the_retired_ladder_is_labelled_and_is_not_the_answer(self):
        out = self._info()
        self.assertIn("HISTORICAL ESTIMATE", out,
                      "the 176.3 / 119.7 ladder is retired; keeping it is fine, "
                      "printing it unlabelled is not")
        head, _, tail = out.partition("--- MEASURED")
        self.assertIn("119.7", head,
                      "the ladder itself is preserved as history; if it is gone, "
                      "this test's premise no longer holds and it must be revised, "
                      "not silently passed")
        self.assertNotIn("119.7", tail,
                         "the retired remaining-bits total must not appear in the "
                         "measured verdict")
        self.assertNotIn("176.3", tail,
                         "the retired removed-bits total must not appear in the "
                         "measured verdict")


# ---------------------------------------------------------------------------
# Docs/tests lane, 2026-09-02 (items R-3 / R-4): the C verifier's King Wen scope, pinned
# as shipped, and a guard for the run-time-emitter class.

RETRACTED_REGISTRY = os.path.join("documentation", "RETRACTED_PHRASES.tsv")


def _fold_like_doc_gates(text):
    """Mirror of scripts/doc_gates.sh fold_variants() followed by the GATE 3 / GATE 47
    flatten (newline -> space, runs collapsed). Kept in step BY HAND: the folds are listed
    in the order sed applies them, so a diff against the shell function is a line-by-line
    read. Backtick, ellipsis and the approximation glyphs are deliberately NOT folded,
    matching that function's recorded decision."""
    # Non-ASCII glyphs are spelled as \u escapes, never pasted: an invisible or
    # near-identical character in a fold table is unreviewable (the shell function
    # records the same decision and the reason for it).
    for a, b in (("\u00d7", "x"), ("\u2715", "x"), ("\u2a2f", "x"),        # multiplication glyphs
                 ("\u2013", "-"), ("\u2014", "-"), ("\u2212", "-"),        # en/em dash, minus
                 ("\u2265", ">="), ("\u2264", "<="), ("\uff0b", "+"),
                 ("\u00a0", " "), ("\u2007", " "), ("\u2009", " "), ("\u202f", " "),
                 ("\u2019", "'"), ("\u2018", "'"), ("\u201c", '"'), ("\u201d", '"'),
                 ("*", "")):                                                # markdown bold
        text = text.replace(a, b)
    text = re.sub(r"(\d),(\d)", r"\1\2", text)                                # digit-group commas
    text = text.replace(" +", "+").replace("+ ", "+")
    # the gates' flatten is `tr '\n' ' ' | tr -s ' '`: newlines become spaces and runs of
    # SPACES collapse; tabs are left alone, exactly as there
    return re.sub(" +", " ", text.replace("\n", " "))


def _registered_retracted_phrases(path=None):
    """Column 1 of every non-comment, non-blank registry row, read at CALL time. Never a
    hand-copied list: a copied needle set is a second registry nobody updates, which is
    the defect class this project keeps meeting."""
    path = path or RETRACTED_REGISTRY          # resolved at CALL time, so a runner can redirect it
    phrases = []
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            if not line.strip() or line.startswith("#"):
                continue
            cols = line.rstrip("\n").split("\t")
            if len(cols) >= 2 and cols[0]:
                phrases.append(cols[0])
    return phrases


class TestRulesBannerCarriesNoRetractedPhrase(unittest.TestCase):
    """R-4 (2026-09-02): the run-time-emitter class, two confirmed instances the same
    day — solve.c:19 (a comment restating the Q-353 wording fifteen lines below the block
    that withdrew it) and solve.py:1649-1657 (the `--rules` banner printing the CX-02 framing
    four lines below the docstring that withdraws it). Both sat outside every needle scan
    because GATE 3 reads *.md and reports/evidence/** only. GATE 47 now scans the tracked
    code, but a gate reads SOURCE and this test reads what the program PRINTS: a banner
    assembled at run time from pieces no source grep can see is still caught here.

    The needle set is documentation/RETRACTED_PHRASES.tsv read at test time. An empty
    registry is a test ERROR, never a pass — a check that cannot run must say so.

    RED BEFORE, measured 2026-09-02: with RP-6986cc78 and RP-fe7deb9f registered, this
    test run against a copy of the pre-fix `HEAD:solve.py` (ROAE_TESTS_RULES_EMITTER
    pointed at the copy) fails naming both keys; on the fixed tree it passes. MUTATION: a
    registered phrase planted in the banner path of a scratch copy fails it. The env hook
    exists only so those two runs are reproducible; the default is the shipped solve.py
    and nothing in the harness sets it."""

    def test_rules_output_contains_no_registered_retracted_phrase(self):
        phrases = _registered_retracted_phrases()
        self.assertGreaterEqual(len(phrases), 1,
                                f"{RETRACTED_REGISTRY} parsed to ZERO rows: the needle "
                                "population is empty, so this test can check nothing")
        emitter = os.environ.get("ROAE_TESTS_RULES_EMITTER", "solve.py")
        r = subprocess.run([sys.executable, emitter, "--rules"],
                           capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr[-2000:])
        self.assertIn("Rule 1:", r.stdout, "--rules printed no rule-set; wrong emitter?")
        flat = _fold_like_doc_gates(r.stdout)
        hits = []
        for p in phrases:
            needle = _fold_like_doc_gates(p)
            if needle and needle in flat:
                hits.append("RP-" + hashlib.sha256(p.encode("utf-8")).hexdigest()[:8])
        self.assertEqual(hits, [],
                         "`--rules` prints registered retracted wording at run time; "
                         f"registry keys {hits} (cited by key, never restated, so this "
                         "message cannot itself become a needle hit)")


class TestSolveVerifyKingWenScope(unittest.TestCase):
    """R-3 (2026-09-02): the C binary's `--verify` contract on King Wen's presence, pinned
    AS SHIPPED — the cross-language control for verify.py's
    test_expect_kw_promotes_kw_presence_to_a_failure.

    THE CONTRACT. `solve --verify` computes `King Wen found:` and does NOT gate on it:
    solve.c's `total_fail` sums fail_c1..fail_dup only, so an artifact holding a valid
    record that is not King Wen returns VERIFY=PASS, rc 0, with `King Wen found: No` on
    its own line. That is deliberate. A shard or a budgeted slice legitimately lacks the
    record — the rule requiring one per file was retracted on 2026-09-02 (registry key
    RP-60347080). A test asserting rc != 0 here would
    assert the shipped behaviour is wrong. This one pins what ships, and the C4 control
    shows the same verdict path DOES go red on a real constraint failure, so the PASS on
    the King-Wen-less fixture is a scoped PASS and not a verifier that passes everything.

    FIXTURES. Raw (uncompressed) ROAE artifacts, one record each. The non-King-Wen record
    is King Wen with one pair's orientation flipped, found by verify.py's per-record
    checks rather than guessed; it shares King Wen's CANONICAL key (same pair order), so
    a two-record artifact holding both is a duplicate-records FAIL — measured — which is
    why "the King Wen record deleted" is modelled as the one-record file.

    CORRECTED 2026-09-04, twice, because this docstring's own premises expired under it.
    (1) It said "solve.c has no --expect-kw; verify.py's flag is the only instrument that
    promotes absence to a failure". solve.c GAINED --expect-kw on 2026-09-04 (g_expect_kw,
    folded into the verdict at solve.c:43410 for --verify and :43845 for --validate), so
    both instruments now answer the question and the tests below pin BOTH halves: the
    default is still reported-not-enforced, and --expect-kw makes absence fatal.
    (2) It said "solve.c is behind the MASTER GATE and is not edited". That gate is Q-77,
    the merge of main into v4-query-program; the merge landed (a19682b2 is an ancestor of
    origin/main) and Q-77 is closed. Neither correction changes what this class ASSERTS —
    the shipped default is unchanged — only why it asserts it, which is the part a future
    reader would otherwise trust.

    The binary is built from the tracked source at -O1 (4.5 s measured on the 2-core
    orchestrator) into a temp dir. A build failure is a test FAILURE, not a skip.

    MUTATION, measured 2026-09-02: a scratch copy of solve.c with `+ (kw_found_v ? 0 : 1)`
    added to total_fail, built via ROAE_TESTS_SOLVE_SRC, returns VERIFY=FAIL rc 1 on the
    King-Wen-less fixture and fails test_absent_king_wen_does_not_gate_the_verdict while
    the other two still pass. The env hook exists only for that run; the default is the
    tracked solve.c and nothing in the harness sets it."""

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="kwscope_")
        cls.sbin = os.path.join(cls.tmp, "solve_kwscope")
        src = os.environ.get("ROAE_TESTS_SOLVE_SRC", "solve.c")
        r = subprocess.run(["gcc", "-O1", "-pthread", "-fopenmp", "-o", cls.sbin, src,
                            "-lm", "-lz"], capture_output=True, text=True)
        cls.build_ok = (r.returncode == 0 and os.path.exists(cls.sbin))
        cls.build_err = f"gcc rc {r.returncode}: " + r.stderr[-2000:]
        cls.V = _load("verify")
        cls.PIDX = {frozenset(p): i for i, p in enumerate(cls.V.PAIRS)}

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def _encode(self, seq):
        out = bytearray()
        for i in range(32):
            a, b = seq[2 * i], seq[2 * i + 1]
            p = self.PIDX[frozenset((a, b))]
            out.append((p << 2) | ((0 if self.V.PAIRS[p] == (a, b) else 1) << 1))
        return bytes(out)

    def _artifact(self, name, records):
        blob = (b"ROAE" + struct.pack("<I", 1) + struct.pack("<Q", len(records))
                + b"\0" * 16 + b"".join(records))
        path = os.path.join(self.tmp, name)
        with open(path, "wb") as fh:
            fh.write(blob)
        return path

    def _verify(self, path, *flags):
        """(rc, lines): every stdout line with \\r stripped and runs of whitespace
        collapsed, so `King Wen found:         No` is matched WHOLE as
        `King Wen found: No` and the verdict token is matched whole, never by shape.

        *flags are passed through to the binary (used for --expect-kw)."""
        if not self.build_ok:
            self.fail("solve.c did not build, so nothing was verified: " + self.build_err)
        r = subprocess.run([self.sbin, "--verify", *flags, path], capture_output=True, text=True)
        return r.returncode, [" ".join(l.split()) for l in r.stdout.splitlines()]

    def _validate(self, path, *flags):
        """Same normalisation as _verify, for the --validate subcommand."""
        if not self.build_ok:
            self.fail("solve.c did not build, so nothing was validated: " + self.build_err)
        r = subprocess.run([self.sbin, "--validate", *flags, path], capture_output=True, text=True)
        return r.returncode, [" ".join(l.split()) for l in r.stdout.splitlines()]

    def _valid_non_kw_record(self):
        kw = self._encode(self.V.KW)
        for i in range(1, 32):
            cand = bytearray(kw); cand[i] ^= 0x02
            fd, path = tempfile.mkstemp(dir=self.tmp, suffix=".bin")
            try:
                os.write(fd, b"ROAE" + struct.pack("<I", 1) + struct.pack("<Q", 1)
                         + b"\0" * 16 + bytes(cand))
                os.close(fd)
                c = self.V.verify_chunk((path, 0, 1))
            finally:
                os.unlink(path)
            if not c["kw_found"] and all(c[k] == 0 for k in (
                    "fail_c1", "fail_c2", "fail_c3", "fail_c4", "fail_c5",
                    "fail_decode", "fail_fmt")):
                return bytes(cand)
        self.fail("no valid single-flip non-King-Wen record found; the fixture premise "
                  "no longer holds and this test must be revised, not passed")

    ZERO_FAILURE_LINES = ("C1 failures (pairs): 0", "C2 failures (hamming5): 0",
                          "C3 failures (cd>776): 0", "C4 failures (first pair): 0",
                          "C5 failures (dist): 0", "Decode failures: 0",
                          "Sort order violations: 0", "Duplicate records: 0")

    def test_king_wen_record_passes_and_is_reported_found(self):
        rc, lines = self._verify(self._artifact("kw.bin", [self._encode(self.V.KW)]))
        self.assertEqual(rc, 0)
        self.assertIn("VERIFY=PASS", lines)
        self.assertIn("King Wen found: YES", lines)

    def test_absent_king_wen_does_not_gate_the_verdict(self):
        # THE PIN. Every per-record and per-file count is zero, King Wen is reported
        # absent, and the verdict is PASS rc 0 — the shipped contract, not a defect.
        rc, lines = self._verify(self._artifact("nokw.bin", [self._valid_non_kw_record()]))
        for want in self.ZERO_FAILURE_LINES:
            self.assertIn(want, lines)
        self.assertIn("King Wen found: No", lines)
        self.assertIn("VERIFY=PASS", lines,
                      "solve --verify now gates on King Wen's presence. If that is a "
                      "deliberate contract change, revise this test AND the registry row "
                      "RP-60347080 that retracted the per-file requirement; do not edit "
                      "the test alone.")
        self.assertNotIn("VERIFY=FAIL", lines)
        # The default contract also announces ITSELF, so a log says which one was in force.
        self.assertIn("KW_REQUIRED=NO", lines)

    def test_kw_presence_is_a_machine_readable_token_in_both_modes(self):
        """KW_PRESENT mirrors verify.py:7127 exactly, and pairs with KW_REQUIRED.

        Presence is a FACT about the artifact; KW_REQUIRED is the CONTRACT in force. A log carrying
        only the second cannot answer "was King Wen actually there?" without re-parsing the prose
        line -- which is gating on output shape, the failure this project has already paid for once.
        verify.py prints the two adjacently; the C binary now does too, so the two instruments answer
        the same question in the same vocabulary."""
        rc, lines = self._verify(self._artifact("kwp_yes.bin", [self._encode(self.V.KW)]))
        self.assertEqual(rc, 0)
        self.assertIn("KW_PRESENT=YES", lines)
        rc, lines = self._verify(self._artifact("kwp_no.bin", [self._valid_non_kw_record()]))
        self.assertEqual(rc, 0)
        self.assertIn("KW_PRESENT=NO", lines)
        self.assertNotIn("KW_PRESENT=YES", lines)

    def test_validate_also_reports_kw_presence(self):
        rc, lines = self._validate(self._artifact("kwp_val.bin", [self._encode(self.V.KW)]))
        self.assertEqual(rc, 0)
        self.assertIn("KW_PRESENT=YES", lines)

    # ---- --expect-kw: the opt-in half of the same contract (item 1566) -------------------
    # The explicit-verdict rule asks for whole-line tokens, `grep -qx`, never output shape.
    # assertIn against self._verify's LINE LIST is exactly that: membership in a list of
    # whole lines, not a substring search over the blob.

    def test_expect_kw_promotes_absence_to_a_whole_line_verify_fail(self):
        # THE NEGATIVE. Same King-Wen-less artifact that PASSES by default must FAIL under
        # --expect-kw, and must say so with the token, not with prose. This is the half that
        # could not be written until 2026-09-04: before that solve.c had no such flag, and
        # this class's docstring said so.
        rc, lines = self._verify(
            self._artifact("nokw_expect.bin", [self._valid_non_kw_record()]), "--expect-kw")
        self.assertNotEqual(rc, 0, "--expect-kw did not make King Wen's absence fatal")
        self.assertIn("VERIFY=FAIL", lines,
                      "--expect-kw must fold KW absence into the verdict TOKEN. If it now "
                      "only warns, that is a contract change: revise solve.c's --expect-kw "
                      "note and verify.py's flag of the same name together, not this test.")
        self.assertNotIn("VERIFY=PASS", lines)
        self.assertIn("KW_REQUIRED=YES", lines)
        self.assertIn("King Wen found: No", lines)

    def test_expect_kw_on_the_king_wen_artifact_still_passes(self):
        # THE POSITIVE CONTROL, and it is what stops the test above from being satisfied by a
        # flag that simply fails everything: the SAME flag on an artifact that DOES hold King
        # Wen must still return the PASS token and rc 0.
        rc, lines = self._verify(
            self._artifact("kw_expect.bin", [self._encode(self.V.KW)]), "--expect-kw")
        self.assertEqual(rc, 0)
        self.assertIn("VERIFY=PASS", lines)
        self.assertIn("KW_REQUIRED=YES", lines)
        self.assertIn("King Wen found: YES", lines)

    # ---- --validate: the same contract, and until 2026-09-04 it had NO verdict token ----

    def test_validate_emits_a_whole_line_verdict_token(self):
        # --verify has emitted VERIFY=PASS|FAIL since it was written; --validate emitted only
        # the prose "Result: ALL CONSTRAINTS VERIFIED". A harness gating on that is gating on
        # output SHAPE — the failure that cost this project a run when a monitor grepped
        # "SEARCH COMPLETE" against a solver writing "SEARCH_COMPLETE" (HISTORY.md).
        rc, lines = self._validate(self._artifact("kw_val.bin", [self._encode(self.V.KW)]))
        self.assertEqual(rc, 0)
        self.assertIn("VALIDATE=PASS", lines)
        # The human-readable line is KEPT, not replaced: both audiences are served.
        self.assertIn("Result: ALL CONSTRAINTS VERIFIED", lines)

    def test_validate_expect_kw_fails_with_the_token(self):
        rc, lines = self._validate(
            self._artifact("nokw_val.bin", [self._valid_non_kw_record()]), "--expect-kw")
        self.assertNotEqual(rc, 0)
        self.assertIn("VALIDATE=FAIL", lines)
        self.assertNotIn("VALIDATE=PASS", lines)
        self.assertIn("KW_REQUIRED=YES", lines)

    def test_validate_default_does_not_gate_on_king_wen(self):
        # The default half of the same contract, pinned for --validate as it is for --verify.
        rc, lines = self._validate(self._artifact("nokw_val2.bin", [self._valid_non_kw_record()]))
        self.assertEqual(rc, 0)
        self.assertIn("VALIDATE=PASS", lines)
        self.assertIn("KW_REQUIRED=NO", lines)
        self.assertEqual(rc, 0)

    def test_constraint_failure_does_gate_the_verdict(self):
        # CONTROL: the same verdict path goes red on comp(KW), which C4's oriented
        # opening rejects and nothing else does. Without this a PASS above could be a
        # verifier that never fails.
        comp = self._encode([h ^ 63 for h in self.V.KW])
        rc, lines = self._verify(self._artifact("comp.bin", [comp]))
        self.assertEqual(rc, 1)
        self.assertIn("VERIFY=FAIL", lines)
        self.assertNotIn("VERIFY=PASS", lines)
        self.assertIn("C4 failures (first pair): 1", lines)
        self.assertIn("King Wen found: No", lines)



class TestRoaePathAndCodons(unittest.TestCase):
    """Codex v2 F61 #4 and L17 #1/#2. RED-TEST: MAX_PATH = 378 fails the first two;
    an index-order greedy tie rule fails the third and fourth; a bit-flip-only
    degeneracy count fails the last two."""

    @classmethod
    def setUpClass(cls):
        import importlib.util, io, contextlib, sys
        here = os.path.dirname(os.path.abspath(__file__))
        spec = importlib.util.spec_from_file_location("roae_mod",
                                                      os.path.join(here, "roae.py"))
        cls.R = importlib.util.module_from_spec(spec)
        argv, sys.argv = sys.argv, ["roae.py"]
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                spec.loader.exec_module(cls.R)
        finally:
            sys.argv = argv

    def test_max_path_bound_is_derived_not_asserted(self):
        R = self.R
        self.assertEqual(R.MAX_PATH, 347)
        # every vertex has exactly ONE distance-6 neighbour, so the d6 edges of a
        # Hamiltonian path form a matching: at most 32 of 63 edges
        for v in range(64):
            self.assertEqual(sum(1 for w in range(64) if R.bit_diff(v, w) == 6), 1)

    def test_max_path_bound_is_attained(self):
        R = self.R
        w = R.max_path_witness()
        self.assertEqual(sorted(w), list(range(64)))
        self.assertEqual(sum(R.bit_diff(w[k], w[k + 1]) for k in range(63)), R.MAX_PATH)

    def test_greedy_nn_total_token(self):
        print(f"GREEDY_NN_TOTAL={self.R.greedy_nn_total()[0]}")
        self.assertEqual(self.R.greedy_nn_total()[0], 63)

    def test_greedy_tie_rule_does_not_read_the_ordering(self):
        R = self.R
        saved = R.binary_hexagrams[:]
        try:
            for perm in (list(reversed(saved)), saved[17:] + saved[:17]):
                R.binary_hexagrams[:] = perm
                self.assertEqual(R.greedy_nn_total(saved[0])[0], 63)
        finally:
            R.binary_hexagrams[:] = saved

    def test_codon_degeneracy_tokens(self):
        p, t, bp, bt = self.R.codon_degeneracy()
        print(f"CODON_SINGLE_BASE_PRESERVED={p}")
        print(f"CODON_SINGLE_BASE_TOTAL={t}")
        self.assertEqual((p, t), (138, 576))
        self.assertEqual((bp, bt), (100, 384))   # the bit-flip subset, kept and labelled


class TestPublishedMoorePrecursorWitness(unittest.TestCase):
    """The 64-number Moore-precursor witness is published in exactly ONE place, and TR-2 now
    points at it rather than carrying a second copy (Codex V2-F04 #9, 2026-09-03).

    A pointer is only as good as the thing it points at, so this pins the published copy's
    properties instead of trusting the prose beside it. RED-TEST: perturbing any number in
    LITERATURE_RULES_POPULATION_TESTS.md fails at least one assertion below.
    """

    SRC = "documentation/LITERATURE_RULES_POPULATION_TESTS.md"
    EXPECTED_COPIES = 2   # measured 2026-09-03: lines ~157 and ~249, currently identical

    def _witness(self):
        """Return the published witness, requiring EVERY copy of it to agree.

        🔴 The file carries the literal TWICE (measured 2026-09-03: two occurrences, currently
        identical). Two uncoordinated copies of a 64-number constant is a drift waiting to happen,
        and TR-2 now points here instead of adding a third. So this does not just read the first
        one — it reads them all and fails if they diverge.
        """
        import re, os
        here = os.path.dirname(os.path.abspath(__file__))
        txt = open(os.path.join(here, self.SRC), encoding="utf-8").read()
        # 🔴 DO NOT ANCHOR THE PATTERN ON THE VALUE BEING CHECKED. The first cut matched
        # `63,0,17,...`, so perturbing the FIRST number made that copy invisible to findall
        # instead of making it disagree: one copy found, trivially self-consistent, test green.
        # Measured 2026-09-03 by red-testing this very check. Match any backticked run of >=60
        # comma-separated integers, so a changed digit anywhere still yields a copy that DIFFERS.
        raw = [r for r in re.findall(r"`([0-9]+(?:[,\s]+[0-9]+){59,})`", txt, re.S)]
        self.assertEqual(len(raw), self.EXPECTED_COPIES,
                         f"{self.SRC}: expected {self.EXPECTED_COPIES} copies of the witness, "
                         f"found {len(raw)} — a copy that vanished is as bad as one that drifted, "
                         f"because TR-2 points here for it")
        self.assertTrue(raw, f"{self.SRC}: the published witness literal is GONE — TR-2 points "
                             f"here for it, so its absence is a broken promise, not a missing test")
        seqs = {tuple(int(x) for x in re.split(r"[,\s]+", r.strip()) if x) for r in raw}
        self.assertEqual(len(seqs), 1,
                         f"{self.SRC}: {len(raw)} copies of the witness and they DISAGREE — "
                         f"a reader following TR-2's pointer would get whichever one they found first")
        return list(next(iter(seqs)))

    def test_published_witness_has_the_properties_tr2_claims(self):
        import roae, verify
        w = self._witness()
        self.assertEqual(len(w), 64)
        self.assertEqual(sorted(w), list(range(64)), "witness is not a permutation of 0..63")
        self.assertEqual(w[:2], [63, 0], "witness does not open (63,0) — C4")
        # TR-2 states it sits at the same C3 ceiling as King Wen.
        self.assertEqual(verify.compute_comp_dist(w), 776)
        self.assertEqual(verify.compute_comp_dist(roae.binary_hexagrams), 776)

    def test_published_witness_is_exactly_three_SLOT_edits_from_king_wen(self):
        import roae
        w = self._witness()
        KW = roae.binary_hexagrams
        slots = sorted({i // 2 for i in range(64) if w[i] != KW[i]})
        # 3 slots, NOT 3 adjacent positions: pairs 8, 22, 23 (zero-based slots 7, 21, 22).
        # TR-2 said "three adjacent-position edits" until 2026-09-03; slot 7 is nowhere near 21/22.
        self.assertEqual(slots, [7, 21, 22],
                         f"witness slot-edit footprint moved: {slots}")
        self.assertEqual(len(slots), 3)


class TestOutOfRangePairIndexReportsNotRaises(unittest.TestCase):
    """V2-F48 #5: a record whose pair_index exceeds 31 must be REPORTED, never raised.

    A reference parser that throws on malformed input cannot be pointed at an untrusted
    artifact, which is the only kind worth checking. `decode()` returns (None, None, None)
    for pidx >= 32 and --check-artifact turns that into BAD_KEY with a whole-line verdict.

    The fixture isolates the charged condition: key = [32, 1, 2, ..., 31] is out of range at
    byte 0 and has NO duplicates, so a failure here cannot be blamed on non-distinctness.
    """

    def _artifact(self, key):
        import struct, tempfile, os
        rec = bytes(((k << 2) & 0xFF) for k in key)
        hdr = bytearray(32)
        hdr[0:4] = b"ROAE"
        struct.pack_into("<I", hdr, 4, 1)
        struct.pack_into("<Q", hdr, 8, 1)
        fd, path = tempfile.mkstemp(suffix=".bin")
        with os.fdopen(fd, "wb") as fh:
            fh.write(bytes(hdr) + rec)
        return path

    def test_decode_returns_none_rather_than_raising(self):
        import verify
        rec = bytes(((k << 2) & 0xFF) for k in ([32] + list(range(1, 32))))
        self.assertEqual((32,), ((rec[0] >> 2) & 0x3F,), "fixture does not carry pair_index 32")
        try:
            got = verify.decode(rec)
        except Exception as e:                      # noqa: BLE001 - that is the defect
            self.fail(f"decode() RAISED on an out-of-range pair_index: {e!r}")
        self.assertEqual(got, (None, None, None))

    def test_check_artifact_reports_bad_key_and_exits_nonzero(self):
        import os, subprocess, sys
        path = self._artifact([32] + list(range(1, 32)))
        try:
            r = subprocess.run([sys.executable, "verify.py", path, "--check-artifact", "1"],
                               capture_output=True, text=True,
                               cwd=os.path.dirname(os.path.abspath(__file__)))
        finally:
            os.unlink(path)
        self.assertNotIn("Traceback", r.stdout + r.stderr,
                         "the reference parser raised instead of reporting")
        self.assertIn("BAD_KEY=1", r.stdout)
        self.assertIn("ARTIFACT=FAIL", r.stdout)
        self.assertNotEqual(r.returncode, 0)


class TestGrammarSearchCheckpointIdentity(unittest.TestCase):
    """A checkpoint row must carry the identity of the run that produced it.

    Until 2026-09-03 the loader validated only `ncand`, while each batch draws from
    `seed + 10000 + b`. A resume under a DIFFERENT --seed silently reused rows from a
    different stream whenever the candidate count matched, and the report then described a
    single-seed run that never happened. Proven by execution on both sides: the old code
    printed "4 batches already complete" for rows written under seed=99 while running --seed 7.

    This pins the CONTRACT rather than re-running the search, which is minutes of Monte Carlo:
    the writer must emit every identity field, and the loader must compare all of them.
    """

    IDENT = ("seed", "ncand", "batches", "nsamp")

    def _src(self):
        import os
        here = os.path.dirname(os.path.abspath(__file__))
        return open(os.path.join(here, "roae.py"), encoding="utf-8").read()

    def test_checkpoint_writer_emits_every_identity_field(self):
        import re
        src = self._src()
        m = re.search(r"ck\.write\(json\.dumps\(dict\((.*?)\)\)", src, re.S)
        self.assertIsNotNone(m, "could not locate the checkpoint writer")
        row = m.group(1)
        for k in self.IDENT + ("want",):
            self.assertIn(f"{k}=", row,
                          f"checkpoint row omits '{k}' — a resume cannot then prove the row "
                          f"belongs to this run")

    def test_checkpoint_loader_compares_all_of_them(self):
        src = self._src()
        self.assertIn("_ck_ident", src, "the loader no longer builds an identity dict")
        # the ncand-only test is exactly the defect; it must not come back
        self.assertNotIn('if rec["ncand"] == len(ridx):', src,
                         "loader reverted to validating ncand alone — a row from a different "
                         "seed would be silently reused")
        self.assertIn("IGNORED", src, "mismatched rows must be reported, not dropped in silence")


class TestSatLane12(unittest.TestCase):
    """sat.py gates for Codex V2 A09 rows 14/18/19, the 2026-09-03 verdict-emitter sweep and the
    Q-58 King Wen over-constraint control (lane 12), plus the Fable-review discriminators for
    model_check() / _print_model_check() (2026-09-03).

    Every test but the byte pin is RED on the pre-2026-09-03 sat.py -- measured by running this
    class from INSIDE a pristine tree (FAILED: failures=6, errors=2; a run whose subprocesses
    resolve `sat.py` in an edited cwd while `import sat` comes from elsewhere measures nothing,
    which is how "7 of 9 pass on pristine" was once reported). The four Fable tests are red on
    lane 12's own version of the file: no attribution/contradiction tokens, unit seeding that
    stopped at the first contradicted unit, unknown families excluded silently.
    Subprocess tests run `sat.py` relative to the cwd, like every other sat test in this file."""

    WITNESS_FILE = os.path.join("reports", "certificates", "c3_positional_witnesses.txt")

    @staticmethod
    def _seq_lits(seq):
        """The 31 Y literals of a 64-hexagram sequence in build()'s variable numbering (Y is
        allocated first: var = (s-1)*NJ + j + 1). Computed from ORIENTS, not from a build()."""
        lits = []
        for s in sat.SLOTS:
            a, b = seq[2 * s], seq[2 * s + 1]
            j = next(j for j in range(sat.NJ) if (sat.ORIENTS[j][2], sat.ORIENTS[j][3]) == (a, b))
            lits.append((s - 1) * sat.NJ + j + 1)
        return lits

    def _witness_seq(self, g):
        """SEQ of the `G=<g>` row of the shipped C3 positional witness file."""
        with open(self.WITNESS_FILE) as fh:
            lines = fh.read().splitlines()
        for i, ln in enumerate(lines):
            if ln.startswith("G=%d " % g):
                return [int(x) for x in lines[i + 1].split("=", 1)[1].split()]
        raise AssertionError("no G=%d witness in %s" % (g, self.WITNESS_FILE))

    @staticmethod
    def _full_model(cnf, lits):
        """Extend `lits` by unit propagation over cnf.cl, then set every free variable false.
        A test-side propagator: the test may not borrow the propagator under test."""
        occ = {}
        for ci, c in enumerate(cnf.cl):
            for l in c:
                occ.setdefault(abs(l), []).append(ci)
        val = {abs(l): l > 0 for l in lits}
        q = list(val)
        for c in cnf.cl:
            if len(c) == 1 and abs(c[0]) not in val:
                val[abs(c[0])] = c[0] > 0; q.append(abs(c[0]))
        while q:
            v = q.pop()
            for ci in occ.get(v, ()):
                un, done = [], False
                for l in cnf.cl[ci]:
                    w = val.get(abs(l))
                    if w is None:
                        un.append(l)
                    elif w == (l > 0):
                        done = True; break
                if not done and len(un) == 1:
                    val[abs(un[0])] = un[0] > 0; q.append(abs(un[0]))
        return [v if val.get(v, False) else -v for v in range(1, cnf.n + 1)]

    @staticmethod
    def _direct_eval(cnf, full):
        """Direct evaluation of a FULL assignment: (falsified count, {family: count}). No
        propagation anywhere -- the independent leg model_check() is measured against."""
        tru = set(l for l in full if l > 0)
        fam, n = {}, 0
        for ci, c in enumerate(cnf.cl):
            if not any((l > 0 and l in tru) or (l < 0 and -l not in tru) for l in c):
                n += 1; k = cnf.stage_of(ci); fam[k] = fam.get(k, 0) + 1
        return n, fam

    @staticmethod
    def _sat(args, env=None):
        return subprocess.run([sys.executable, "sat.py"] + args, capture_output=True, text=True, env=env)

    @staticmethod
    def _stub(tmp, body):
        """A `kissat` stub on a private PATH; returns the env to run with."""
        d = os.path.join(tmp, "bin"); os.makedirs(d, exist_ok=True)
        p = os.path.join(d, "kissat")
        with open(p, "w") as fh:
            fh.write("#!/bin/sh\n" + body + "\n")
        os.chmod(p, 0o755)
        return dict(os.environ, PATH=d + os.pathsep + os.environ.get("PATH", ""))

    def _model_file(self, tmp, lits, name="m.txt"):
        p = os.path.join(tmp, name)
        with open(p, "w") as fh:
            fh.write("v " + " ".join(map(str, lits)) + " 0\n")
        return p

    def test_decode_is_target_aware_and_a_verdict_emitter(self):
        # Codex V2 A09 row 14 (+ the verdict sweep): --decode consulted no target and exited 0
        # whatever it found. RED on the shipped file: a KW model under ccn4-kwfail printed
        # `verify=True` with no CC-N4 line and rc 0. Note the FAIL here comes from the MODEL leg
        # alone: solve.reg_ccn4(KW) is True, so TARGET_RULES_VIOLATED is `none` and only the
        # formula (faces permuted) refuses the assignment.
        with tempfile.TemporaryDirectory() as tmp:
            m = self._model_file(tmp, self._seq_lits(KW))
            r = self._sat(["--decode", m, "ccn4-kwfail"])
            lines = r.stdout.splitlines()
            self.assertNotEqual(r.returncode, 0, r.stdout + r.stderr[-300:])
            self.assertIn("DECODE_VERDICT=FAIL", lines)
            self.assertIn("TARGET_RULES_VIOLATED=none", lines)
            self.assertIn("MODEL_CHECK=FALSIFIED", lines)
            fam = [ln for ln in lines if ln.startswith("MODEL_FALSIFIED_BY_FAMILY=")]
            self.assertEqual(len(fam), 1, r.stdout)
            self.assertIn("rule ccn4", fam[0])      # first-conflict attribution on a partial model
            # the same model under the target KW DOES satisfy: PASS, exit 0, model SATISFIED
            r = self._sat(["--decode", m, "ccn4-kwtest"])
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr[-300:])
            self.assertIn("DECODE_VERDICT=PASS", r.stdout.splitlines())
            self.assertIn("MODEL_CHECK=SATISFIED", r.stdout.splitlines())
            # the SAT_CLI.md example: KW under grand-strict is a FAIL with all three named
            r = self._sat(["--decode", m, "grand-strict"])
            self.assertNotEqual(r.returncode, 0)
            self.assertIn("TARGET_RULES_VIOLATED=gender=2,parity=2,rhythm=2", r.stdout.splitlines())

    def test_five_rules_rescored_and_every_target_rule_is_scorable(self):
        # Row 14, second leg: target_rules(t) must be a subset of what the re-score can score,
        # for every target -- goes red the moment a sixth rule is added without a scorer.
        scores = sat.rule_scores(KW)
        self.assertEqual(scores, {"parity": 2, "rhythm": 2, "gender": 2, "ccn4": 0, "ccn8": 0})
        targets = list(sat.RULESETS) + ["five-loo-" + r for r in sat.FIVE_RULES] + \
                  ["five-sub-ccn4+ccn8", "grander-strict-near-2", "alt-le-14-noY"]
        for t in targets:
            self.assertTrue(sat.target_rules(t) <= set(scores), t)
        # the measured gap, decode form: the shipped G=95 witness has solve.reg_ccn4() == False
        g95 = self._witness_seq(95)
        self.assertIs(solve.reg_ccn4(g95), False)
        with tempfile.TemporaryDirectory() as tmp:
            r = self._sat(["--decode", self._model_file(tmp, self._seq_lits(g95)), "five-sub-ccn4"])
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("TARGET_RULES_VIOLATED=ccn4=1", r.stdout.splitlines(), r.stdout)

    def test_witness_solver_error_is_not_reported_as_unsat(self):
        # Codex V2 A09 row 18. RED on the shipped file: a stub exiting 42 with empty stdout
        # printed `UNSAT (or solver error) at attempt 0` and exited 0.
        with tempfile.TemporaryDirectory() as tmp:
            r = self._sat(["--witness", "moore-strict"], env=self._stub(tmp, "exit 42"))
            self.assertNotEqual(r.returncode, 0, r.stdout)
            self.assertFalse(any(ln.startswith("UNSAT") for ln in r.stdout.splitlines()), r.stdout)
            self.assertIn("WITNESS_RESULT=SOLVER_ERROR", r.stdout.splitlines())
            # a genuine UNSAT: whole line AND exit status 20 -> UNSAT, exit 0
            r = self._sat(["--witness", "moore-strict"],
                          env=self._stub(tmp, 'echo "s UNSATISFIABLE"; exit 20'))
            self.assertEqual(r.returncode, 0, r.stdout)
            self.assertIn("WITNESS_RESULT=UNSAT", r.stdout.splitlines())
            # the verdict line without its exit status (and CR-prefixed) is NOT an UNSAT
            r = self._sat(["--witness", "moore-strict"],
                          env=self._stub(tmp, 'printf "\\rs UNSATISFIABLE\\n"; exit 0'))
            self.assertNotEqual(r.returncode, 0, r.stdout)
            self.assertIn("WITNESS_RESULT=SOLVER_ERROR", r.stdout.splitlines())

    def test_decode_honours_c3_max(self):
        # Codex V2 A09 row 19. RED on the shipped file: the G=97 / C3=792 witness under
        # --c3-max 800 printed `fail C3` (literal 776 in the label).
        g97 = self._witness_seq(97)
        with tempfile.TemporaryDirectory() as tmp:
            m = self._model_file(tmp, self._seq_lits(g97))
            r = self._sat(["--decode", m, "plain", "--c3-max", "800"])
            self.assertEqual(r.returncode, 0, r.stdout + r.stderr[-300:])
            self.assertIn("c3<=800 PASS", r.stdout)
            self.assertNotIn("fail C3", r.stdout)
            r = self._sat(["--decode", m, "plain"])              # default window: KW's 776 ceiling
            self.assertNotEqual(r.returncode, 0)
            self.assertIn("DECODE_VERDICT=FAIL", r.stdout.splitlines())
            r = self._sat(["--decode", m, "plain", "--c3-min", "784"])   # the witness file's recipe
            self.assertEqual(r.returncode, 0, r.stdout)

    def test_arity_keep_and_inapplicable_modifiers_are_errors(self):
        # Verdict sweep siblings of A09 row 20 / Q-309 / Q-311. RED on the shipped file:
        # `--emit-cnf plain` printed the help banner and exited 0; `--expect`/`--keep` on
        # --emit-cnf were parsed and dropped; `--keep` as the last argument was an IndexError.
        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, "x.cnf")
            r = self._sat(["--emit-cnf", "plain"])
            self.assertNotEqual(r.returncode, 0)
            self.assertIn("wrong argument count", r.stderr)
            r = self._sat(["--emit-cnf", "plain", out, "--expect", "5", "--keep", tmp])
            self.assertNotEqual(r.returncode, 0)
            self.assertIn("does not apply to --emit-cnf", r.stderr)
            self.assertFalse(os.path.exists(out))
            r = self._sat(["--witness", "plain", "--expect", "5"])
            self.assertNotEqual(r.returncode, 0)
            self.assertIn("does not apply to --witness", r.stderr)
            r = self._sat(["--certify-count", "plain", "--keep"])
            self.assertNotEqual(r.returncode, 0)
            self.assertNotIn("Traceback", r.stderr)
            self.assertIn("--keep needs a directory", r.stderr)
        r = self._sat([])                                        # no arguments: catalogue, exit 0
        self.assertEqual(r.returncode, 0)
        self.assertIn("Subcommands:", r.stdout)

    def test_decode_rejects_empty_and_garbage_models(self):
        # Q-311 residue. RED on the shipped file: an empty model file was a KeyError traceback
        # (verify_seq computed C3 over a 2-element decode) and `v 1 abc 0` a ValueError one.
        with tempfile.TemporaryDirectory() as tmp:
            e = os.path.join(tmp, "empty.txt"); open(e, "w").close()
            g = os.path.join(tmp, "garbage.txt")
            with open(g, "w") as fh:
                fh.write("v 1 abc 0\n")
            for path in (e, g):
                r = self._sat(["--decode", path, "plain"])
                self.assertNotEqual(r.returncode, 0)
                self.assertNotIn("Traceback", r.stderr, path)

    def test_witness_checks_the_solver_model_against_the_formula(self):
        # Verdict sweep: the loop re-verified the decoded SEQUENCE but never the solver's MODEL.
        # RED on the shipped file: a stub returning the same (C3-failing) model after every
        # blocking clause was believed 200 times, then the loop fell out with exit 0 and no
        # verdict line. Now the second answer falsifies the blocking clause -> SOLVER_ERROR.
        cnf, _ = sat.build("plain")
        full = self._full_model(cnf, self._seq_lits(self._witness_seq(97)))   # C3 = 792 > 776
        with tempfile.TemporaryDirectory() as tmp:
            mp = os.path.join(tmp, "model.txt")
            with open(mp, "w") as fh:
                fh.write("s SATISFIABLE\nv " + " ".join(map(str, full)) + " 0\n")
            r = self._sat(["--witness", "plain"], env=self._stub(tmp, "cat %s; exit 10" % mp))
        lines = r.stdout.splitlines()
        self.assertNotEqual(r.returncode, 0, r.stdout[-500:])
        self.assertIn("WITNESS_RESULT=SOLVER_ERROR", lines)
        self.assertFalse(any(ln.startswith("WITNESS:") for ln in lines))
        self.assertLess(sum(1 for ln in lines if ln.startswith("attempt")), 3)

    def test_kw_control_on_certified_unsat_targets(self):
        # Q-58, the over-constraint leg the Lean module does not cover (build() has no Lean
        # model; all shipped certificates are UNSAT proofs, where no witness can be decoded).
        # Executable control at full n=31: the King Wen assignment must falsify ONLY the clause
        # families the target is about (its theorem family, plus the rule families KW is known
        # by solve.py's own scorers to violate) and NOTHING else. This is the exclusion form,
        # which is propagation-order independent (model_check docstring); the family names of
        # the un-excluded run are not, and are deliberately not asserted here. RED on the
        # shipped file: neither model_check() nor clause-family marks exist (AttributeError).
        P, R, G = "rule parity", "rule rhythm", "rule gender"
        cases = [("alt-le-14", {}, {"alternation bound (alt-le-14)"}),
                 ("alt-ge-16", {}, {"alternation bound (alt-ge-16)"}),
                 ("grander-strict", {}, {P, R, G}), ("gender-ccn8", {}, {G}),
                 ("five-loo-ccn8", {}, {P, R, G}),
                 ("ccn8-kwfail", {}, {"rule ccn8 (locus 24,25)"}),
                 ("ccn8-kwchain-not", {}, {"ccn8 chain machinery (ccn8-kwchain-not)"}),
                 ("kw-pin", {"c3_min": 777}, {"C3 >= 777 bound"})]
        for target, kw, expect in cases:
            cnf, Y = sat.build(target, **kw)
            lits = self._seq_lits(KW)
            families = set(name for _, name in cnf.marks)
            self.assertTrue(expect <= families, (target, expect - families))
            full = sat.model_check(cnf, lits)
            self.assertEqual(full["verdict"], "FALSIFIED", (target, full))
            rest = sat.model_check(cnf, lits, exclude_stages=expect)
            self.assertEqual((rest["falsified"], rest["foreign"]), (0, 0), (target, rest))
        # and the SAT-expected controls: KW is a model (every clause determined and satisfied)
        for target in ("plain", "kw-pin", "ccn4-kwtest", "ccn8-kwchain"):
            cnf, Y = sat.build(target)
            self.assertEqual(sat.model_check(cnf, self._seq_lits(KW))["verdict"], "SATISFIED", target)

    def test_model_check_is_a_direct_evaluation_on_a_full_model(self):
        # Fable review 2026-09-03. The witness loop hands model_check() a FULL solver model, so
        # its tallies there must equal a direct clause evaluation with no propagation at all --
        # measured here with an independent evaluator, on the formula's own clause families.
        # For moore-strict the family counts must ALSO equal solve.py's violation scores: the
        # parity/rhythm clauses are one forbid per violation, so the CNF and the scorer agree
        # one-for-one on King Wen (2 + 2) -- an encoding-fidelity check, not a bookkeeping one.
        rng = random.Random(1203)
        for target, kw, seq, want in (("moore-strict", {}, KW, {"rule parity": 2, "rule rhythm": 2}),
                                      ("plain", {"not_kw": True}, KW, {"not-kw layout exclusion": 1}),
                                      ("plain", {}, KW, {})):
            cnf, Y = sat.build(target, **kw)
            full = self._full_model(cnf, self._seq_lits(seq))
            mc = sat.model_check(cnf, full)
            n, fam = self._direct_eval(cnf, full)
            self.assertEqual(mc["attribution"], "exact", target)
            self.assertEqual((mc["falsified"], mc["undetermined"], mc["falsified_by_stage"]),
                             (n, 0, fam), (target, mc))
            self.assertEqual(mc["verdict"], "FALSIFIED" if n else "SATISFIED", target)
            self.assertEqual(fam, want, target)
            if target == "moore-strict":
                rs = sat.rule_scores(KW)
                self.assertEqual((fam["rule parity"], fam["rule rhythm"]), (rs["parity"], rs["rhythm"]))
            for _ in range(3):                      # a single flipped literal, both legs again
                i = rng.randrange(len(full)); fl = list(full); fl[i] = -fl[i]
                mc = sat.model_check(cnf, fl)
                n, fam = self._direct_eval(cnf, fl)
                self.assertEqual((mc["falsified"], mc["undetermined"], mc["falsified_by_stage"],
                                  mc["verdict"]), (n, 0, fam, "FALSIFIED" if n else "SATISFIED"),
                                 (target, i + 1))

    def test_decode_model_check_is_its_own_leg_and_names_its_scope(self):
        # Fable review 2026-09-03: the model leg must be able to FAIL a decode whose sequence
        # leg passes, and the printed family attribution must say which kind it is.
        with tempfile.TemporaryDirectory() as tmp:
            m = self._model_file(tmp, self._seq_lits(KW))
            r = self._sat(["--decode", m, "plain", "--not-kw"])     # KW passes every sequence check
            lines = r.stdout.splitlines()
            self.assertEqual(r.returncode, 1, r.stdout + r.stderr[-300:])
            self.assertIn("TARGET_RULES_VIOLATED=none", lines)
            self.assertIn("c3<=776 PASS", r.stdout)
            self.assertIn("MODEL_CHECK=FALSIFIED", lines)
            self.assertIn("MODEL_FALSIFIED_BY_FAMILY=not-kw layout exclusion:1", lines)
            self.assertIn("MODEL_FAMILY_ATTRIBUTION=first-conflict", lines)
            self.assertIn("MODEL_INPUT_CONTRADICTORY=0", lines)
            self.assertIn("DECODE_VERDICT=FAIL", lines)
            # a literal naming a variable the formula does not have: a model of ANOTHER formula
            r = self._sat(["--decode", self._model_file(tmp, self._seq_lits(KW) + [10 ** 6], "f.txt"),
                           "plain"])
            self.assertEqual(r.returncode, 1)
            self.assertIn("MODEL_FOREIGN_LITERALS=1", r.stdout.splitlines())
            self.assertIn("MODEL_CHECK=FALSIFIED", r.stdout.splitlines())
            # x and -x in one model file: FALSIFIED with no falsified clause -- and it says so
            r = self._sat(["--decode", self._model_file(tmp, [5, -5], "c.txt"), "plain"])
            self.assertEqual(r.returncode, 1)
            self.assertIn("MODEL_INPUT_CONTRADICTORY=1", r.stdout.splitlines())
            self.assertIn("MODEL_CHECK=FALSIFIED", r.stdout.splitlines())
            # a full model is evaluated exactly; the formula can be satisfied while the C3
            # POLICY fails (G=97 has C3 = 792): the two legs disagree the other way round
            cnf, _ = sat.build("plain")
            full = self._full_model(cnf, self._seq_lits(self._witness_seq(97)))
            r = self._sat(["--decode", self._model_file(tmp, full, "full.txt"), "plain"])
            lines = r.stdout.splitlines()
            self.assertEqual(r.returncode, 1)
            self.assertIn("MODEL_CHECK=SATISFIED", lines)
            self.assertIn("MODEL_FAMILY_ATTRIBUTION=exact", lines)
            self.assertIn("DECODE_VERDICT=FAIL", lines)

    def test_model_check_seeds_every_unit_clause(self):
        # Fable review 2026-09-03: seeding stopped at the first contradicted unit clause, so a
        # kw-pin formula given one anti-pin literal assigned 152 variables and left 237,400
        # clauses undetermined. The closure must not depend on whether the pin units arrive as
        # unit clauses of the formula or as input literals.
        cnf, Y = sat.build("kw-pin")
        pins = [Y[(s, next(j for j in range(sat.NJ) if sat.ORIENTS[j][0] == s and sat.ORIENTS[j][1] == 0))]
                for s in sat.SLOTS]
        a = sat.model_check(cnf, [-pins[0]])
        b = sat.model_check(cnf, [-pins[0]] + pins[1:])
        self.assertEqual(a["verdict"], "FALSIFIED")
        self.assertEqual((a["assigned"], a["undetermined"], a["falsified"]),
                         (b["assigned"], b["undetermined"], b["falsified"]), (a, b))
        self.assertLess(a["undetermined"], 1000, a)

    def test_model_check_refuses_an_unknown_family(self):
        # Fable review 2026-09-03: an exclusion naming no family of the formula excluded nothing
        # and reported a control it had not run (verifier closure).
        cnf, Y = sat.build("plain")
        with self.assertRaises(ValueError):
            sat.model_check(cnf, self._seq_lits(KW), exclude_stages={"rule parity"})

    def test_emitted_cnf_bytes_pinned(self):
        # Regression guard, not a red test: the shipped .drat.gz certificates verify only against
        # byte-identical formulas, and the 2026-09-03 clause-family marks must not move a byte.
        # Pins measured 2026-09-03 on sat.py at 12bbb7ac (pre-change) == post-change.
        pins = {"plain": "5d5c3594607ad5c440ee60d42a28c7acc60f06c6a106489b1ab9517b81950c7c",
                "alt-le-14": "0db4b905cc96b3e3c659b68cb170426bc64dc9afca094141b3e70292d4d7b579",
                "alt-ge-16": "892c1eab5ef34700ff42a843905a6f8c8f4ac3c0c16e1a7b03bf62913dd093d7"}
        with tempfile.TemporaryDirectory() as tmp:
            for target, sha in pins.items():
                out = os.path.join(tmp, target + ".cnf")
                r = self._sat(["--emit-cnf", target, out])
                self.assertEqual(r.returncode, 0, r.stderr[-300:])
                with open(out, "rb") as fh:
                    self.assertEqual(hashlib.sha256(fh.read()).hexdigest(), sha, target)

    def test_emit_cnf_refuses_a_c3_max_below_the_structural_minimum(self):
        # Q-687 (2026-09-24), the regression lock for Q-287. build()'s guard refuses a --c3-max
        # below C3's structural floor 2*|C3_SELFC| + 8*|C3_COUPLES| = 112 (every complement
        # couple sits at slot distance >= 1, so no C1 layout can go lower) BEFORE the ladder is
        # emitted. The guard predates this test; it is pinned because a ladder rewrite that
        # drops it turns `--c3-max 0` into a seconds-long build of an unsatisfiable formula
        # (rc 0, `vars=`), which a proof cell would then hand to a solver as if it meant
        # something. RED on a mutant sat.py with the `sbudget < len(C3_COUPLES)` block deleted
        # (measured 2026-09-24: rc 1 but a ValueError TRACEBACK from at_most_k's negative-bound
        # refusal, the second-line guard, for 111); GREEN on the shipped guard. /dev/null is the
        # /tmp-free proof-cell form (Q-688) and needs the 2026-09-24 _out_path: at HEAD 5c296837
        # this test is red on `/dev/null: not writable` before the guard is ever reached.
        self.assertEqual(2 * len(sat.C3_SELFC) + 8 * len(sat.C3_COUPLES), 112)
        for b in (111, 0, -5):
            r = self._sat(["--emit-cnf", "plain", "/dev/null", "--with-c3", "--c3-max", str(b)])
            self.assertEqual(r.returncode, 1, (b, r.stdout, r.stderr[-300:]))
            self.assertNotIn("Traceback", r.stderr, (b, r.stderr))
            self.assertIn("structural minimum C3 = 112", r.stderr, (b, r.stderr))
        r = self._sat(["--emit-cnf", "plain", "/dev/null", "--with-c3", "--c3-max", "112"])
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr[-300:])
        self.assertIn("vars=", r.stdout)

    def test_emit_cnf_out_path_is_judged_on_the_file_it_will_open(self):
        # Q-687 (2026-09-24), the 2026-09-24 `_out_path` rules (Q-311 sibling). RED at HEAD
        # 5c296837 on two legs: `/dev/null` was refused as "not writable" because the DIRECTORY
        # /dev was tested although the file exists and is writable, and a directory handed as
        # OUT.cnf passed the pre-check and was an IsADirectoryError traceback after the build.
        # The missing-directory and read-only-file legs already held at HEAD and are locked.
        r = self._sat(["--emit-cnf", "plain", "/dev/null"])
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr[-300:])
        self.assertIn("vars=", r.stdout)
        with tempfile.TemporaryDirectory() as tmp:
            r = self._sat(["--emit-cnf", "plain", tmp])
            self.assertEqual(r.returncode, 1, r.stdout + r.stderr[-300:])
            self.assertNotIn("Traceback", r.stderr)
            self.assertIn("is a directory, not a file", r.stderr)
            r = self._sat(["--emit-cnf", "plain", os.path.join(tmp, "no_such_dir", "x.cnf")])
            self.assertEqual(r.returncode, 1, r.stdout + r.stderr[-300:])
            self.assertNotIn("Traceback", r.stderr)
            self.assertIn("does not exist", r.stderr)
            if os.geteuid() != 0:            # root ignores mode bits: this leg would be vacuous
                ro = os.path.join(tmp, "ro.cnf")
                open(ro, "w").close()
                os.chmod(ro, 0o444)
                r = self._sat(["--emit-cnf", "plain", ro])
                self.assertEqual(r.returncode, 1, r.stdout + r.stderr[-300:])
                self.assertNotIn("Traceback", r.stderr)
                self.assertIn("not writable", r.stderr)


class TestSolveCliHardeningTokens(unittest.TestCase):
    """Whole-line KEY=value gates for the Codex v2 solve.c CLI/validator fixes landed 2026-09-04.

    Every assertion below was RED on the pre-fix binary and the pre-fix return codes are recorded
    per test, measured rather than asserted from the adjudication text. Each token is matched
    WHOLE-LINE (the harness rule: never by output shape), so a reworded sentence that happens to
    contain the substring cannot satisfy a gate.

    The binary is built from the tracked solve.c at -O1 into a temp dir; ROAE_TESTS_SOLVE_SRC
    overrides the source for mutation runs only, and nothing in the harness sets it. A build
    failure is a test FAILURE, never a skip -- a gate that cannot run must not read as one that
    passed."""

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="clihard_")
        cls.sbin = os.path.join(cls.tmp, "solve_clihard")
        src = os.environ.get("ROAE_TESTS_SOLVE_SRC", "solve.c")
        r = subprocess.run(["gcc", "-O1", "-pthread", "-fopenmp", "-o", cls.sbin, src,
                            "-lm", "-lz"], capture_output=True, text=True)
        cls.build_ok = (r.returncode == 0 and os.path.exists(cls.sbin))
        cls.build_err = f"gcc rc {r.returncode}: " + r.stderr[-2000:]

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def _run(self, args, cwd=None):
        if not self.build_ok:
            self.fail("solve.c did not build, so nothing was verified: " + self.build_err)
        r = subprocess.run([self.sbin] + args, capture_output=True, text=True,
                           cwd=cwd or self.tmp, timeout=600)
        return r

    def _lines(self, r):
        return [" ".join(l.split()) for l in (r.stdout + "\n" + r.stderr).splitlines()]

    # ---- Codex v2 solve.c:17514 -- --merge consumed and silently discarded its arguments (pre-fix rc 0)
    def test_merge_refuses_arguments_it_cannot_honour(self):
        r = self._run(["--merge", "/data/solutions.bin"])
        self.assertNotEqual(r.returncode, 0,
                            "--merge with a path argument must refuse, not silently ignore it")
        self.assertIn("MERGE_ARGS=REFUSED", self._lines(r))

    def test_bare_merge_still_runs(self):
        # Control: the refusal must be scoped to EXTRA arguments. A bare --merge in an empty
        # directory must still reach the merge and report that it found no shards.
        d = tempfile.mkdtemp(dir=self.tmp)
        r = self._run(["--merge"], cwd=d)
        self.assertNotIn("MERGE_ARGS=REFUSED", self._lines(r))
        self.assertTrue(any("No sub_*.bin files found" in l for l in self._lines(r)),
                        "bare --merge should reach the shard scan; got: " +
                        "\n".join(self._lines(r))[-500:])

    # ---- Codex v2 solve.c:18678 -- atoll truncated the budget, and skipped gates read as passing gates
    def test_preflight_refuses_a_non_numeric_budget(self):
        # Pre-fix: atoll("560Q") == 560, and the command printed "all in-process gates PASS" rc 0.
        r = self._run(["--preflight", "560Q"])
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("PREFLIGHT=REFUSED-BAD-ARG", self._lines(r))

    def test_preflight_reports_skipped_gates_as_skipped_not_passed(self):
        # Pre-fix: all three gates return 0 below 1e12 nodes, indistinguishable from PASS, so
        # `--preflight 560` attested a clean bill of health having executed nothing.
        r = self._run(["--preflight", "560"])
        lines = self._lines(r)
        self.assertIn("PREFLIGHT_GATES_SKIPPED=3", lines)
        self.assertIn("PREFLIGHT_GATES_RAN=0", lines)
        self.assertFalse(any("all in-process gates PASS" in l for l in lines),
                         "a preflight that ran nothing must not claim all gates passed")

    # ---- Codex v2 solve.c:18508 -- an uppercase sha was accepted, echoed uppercase, compared lowercase
    def test_validate_canonical_normalises_the_sha_case(self):
        upper = "403F7202A33A9337B781F4EE17E497D5C0773C2656E16FA0DB87EECCD6F3332E"
        if not self.build_ok:
            self.fail("solve.c did not build: " + self.build_err)
        # START A NEW SESSION AND KILL THE GROUP, NOT THE PID (Q-656, 2026-09-19).
        # --validate-canonical system()-launches a 1T enumeration at SOLVE_THREADS=128
        # (solve.c:40618-40632) microseconds after the token this test reads, and solve.c
        # calls no setsid/setpgid/setpgrp -- so pr.kill(), which signals the driver's PID
        # alone, left that enumeration running and reparented on a 2-core box. Measured
        # against a stub reproducing solve.c's stdout order: driver-only kill orphaned the
        # enum in 3/3 reps whenever the harness lost the race (0/3 when it won -- not the
        # arm to design for, since the C side reaches fork before Python is rescheduled);
        # killing the session group is 0/3 in BOTH arms.
        pr = subprocess.Popen([self.sbin, "--validate-canonical", upper, "1T"],
                              stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                              text=True, cwd=self.tmp, start_new_session=True)
        tdir = None
        try:
            # The echo precedes the enum spawn; read only as far as the temp-dir line,
            # which solve.c prints immediately after the token, then kill. The
            # "Running canonical enum" line is the last output until the enum finishes,
            # so it is an unconditional stop and no read here can block on the enum.
            seen, echo = [], None
            for _ in range(400):
                line = pr.stdout.readline()
                if not line:
                    break
                s = line.strip()
                seen.append(s)
                if s.startswith("[--validate-canonical] Temp dir:"):
                    tdir = s.split("Temp dir:", 1)[1].strip()
                if line.startswith("[--validate-canonical] Expected sha:"):
                    self.assertNotIn(upper, line,
                                     "the uppercase input was echoed back verbatim")
                if s == "EXPECTED_SHA_ECHO=lowercase":
                    echo = True
                if echo and tdir:
                    break
                if s.startswith("[--validate-canonical] Running canonical enum"):
                    break
        finally:
            try:
                os.killpg(pr.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass                    # the whole group is already gone
            pr.wait(timeout=60)
            if pr.stdout:
                pr.stdout.close()
            if tdir:
                shutil.rmtree(tdir, ignore_errors=True)   # solve.c mkdtemp's and never removes it
        self.assertTrue(echo, "EXPECTED_SHA_ECHO=lowercase not emitted; saw: " +
                        " | ".join(seen[-8:]))


class TestKnuthEstimatorOutputHonesty(unittest.TestCase):
    """The estimator output-honesty harness (Codex v2 solve.c:8073/:8136/:8137/:8341/:8343).

    These assert what the estimator is ALLOWED TO CLAIM, not what it computes. Each row was
    measured red on the pre-fix binary; the pre-fix behaviour is named per test. Tokens are
    matched whole-line.

    --estimate-knuth needs >= 16 MB of stack and refuses below that, so every run here raises
    RLIMIT_STACK in the child rather than assuming the harness inherited a large one -- otherwise
    these tests would pass vacuously on the refusal message, which is exactly the failure mode the
    suite exists to catch."""

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="knuthhonesty_")
        cls.sbin = os.path.join(cls.tmp, "solve_knuth")
        src = os.environ.get("ROAE_TESTS_SOLVE_SRC", "solve.c")
        r = subprocess.run(["gcc", "-O1", "-pthread", "-fopenmp", "-o", cls.sbin, src,
                            "-lm", "-lz"], capture_output=True, text=True)
        cls.build_ok = (r.returncode == 0 and os.path.exists(cls.sbin))
        cls.build_err = f"gcc rc {r.returncode}: " + r.stderr[-2000:]

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def _run(self, args, env=None, timeout=300):
        if not self.build_ok:
            self.fail("solve.c did not build, so nothing was verified: " + self.build_err)
        def _raise_stack():
            import resource
            resource.setrlimit(resource.RLIMIT_STACK,
                               (resource.RLIM_INFINITY, resource.RLIM_INFINITY))
        e = dict(os.environ)
        if env:
            e.update(env)
        r = subprocess.run([self.sbin] + args, capture_output=True, text=True,
                           cwd=self.tmp, env=e, timeout=timeout, preexec_fn=_raise_stack)
        lines = [" ".join(l.split()) for l in (r.stdout + "\n" + r.stderr).splitlines()]
        self.assertFalse(any("stack limit is" in l for l in lines),
                         "the child refused on stack size, so this assertion would be vacuous")
        return r, lines

    def test_single_probe_reports_no_confidence_interval(self):
        # Pre-fix: printed 95%CI=[x, x] relerr=0.00% -- a zero-width interval reading as
        # infinite precision, from one probe.
        _, lines = self._run(["--estimate-knuth", "1"])
        ci = [l for l in lines if l.startswith("tree_nodes :")]
        self.assertTrue(ci, "no tree_nodes line; got: " + " | ".join(lines[-6:]))
        self.assertIn("CI=UNAVAILABLE", ci[0])
        self.assertNotIn("95%CI", ci[0])

    def test_zero_hit_layers_report_starvation_not_a_bound(self):
        # Pre-fix: est=0 with 95%CI=[0,0] on layers that recorded zero hits, presenting a
        # sampling artifact as a measured bound.
        _, lines = self._run(["--estimate-knuth", "2"])
        leaf = [l for l in lines if l.startswith("leaves_C1C2C4C5 :")]
        self.assertTrue(leaf, "no leaves_C1C2C4C5 line; got: " + " | ".join(lines[-6:]))
        self.assertIn("STARVATION", leaf[0])
        self.assertNotIn("95%CI", leaf[0])

    def test_probe_count_is_the_count_that_ran(self):
        # Pre-fix: the reported probe count was the PLANNED quota and nothing established
        # that those probes executed.
        _, lines = self._run(["--estimate-knuth", "64"])
        self.assertIn("KNUTH_PROBES=EXECUTED-EQ-PLANNED", lines)
        self.assertTrue(any(l.startswith("KNUTH-PROBES planned=64 executed=64") for l in lines),
                        "planned/executed line missing or unequal: " +
                        " | ".join(l for l in lines if "KNUTH-PROBES" in l))

    def test_exact_mode_honours_its_own_dead_prefix_banner(self):
        # Pre-fix: printed "STRICT-PREFIX DEAD ... reporting zero estimates" and then NON-ZERO
        # counts beneath it -- and spent unbounded time enumerating a subtree it had just proven
        # empty (measured 2026-09-04: no completion in 120 s at 11 prefix levels).
        r, lines = self._run(["--estimate-knuth", "0",
                              "3", "0", "5", "0", "7", "0", "9", "0"],
                             env={"SOLVE_KNUTH_MOORE_STRICT": "1"}, timeout=120)
        self.assertTrue(any(l.startswith("EXACT_COUNT=DEAD-PREFIX") for l in lines),
                        "expected the DEAD-PREFIX token; got: " + " | ".join(lines[-8:]))
        for layer in ("tree_nodes", "leaves_C1C2C4C5", "leaves_canonical_C1C5"):
            row = [l for l in lines if l.startswith(layer + " :")]
            self.assertTrue(row, layer + " line missing")
            self.assertEqual(row[0].split(":")[1].strip(), "0",
                             layer + " must be 0 under a dead prefix, not " + row[0])

    def test_fiber_refuses_a_strict_walk_it_cannot_weight(self):
        # The W/m estimator is unbiased only because sum(1/m) over a class's fiber is EXACTLY 1,
        # which requires the walk to reach every fiber member. A strict walk reaches a subset
        # S(P) while m still counts |F(P)|, so each class contributes |S(P)|/|F(P)| < 1 (witness:
        # 3840/2064384 = 5/2688, a 537.6x per-class undercount). Pre-fix this combination RAN
        # with no refusal and printed records_* lines.
        r, lines = self._run(["--estimate-knuth", "50"],
                             env={"SOLVE_KNUTH_FIBER": "1",
                                  "SOLVE_KNUTH_MOORE_STRICT": "1"}, timeout=180)
        self.assertIn("FIBER_MODE=REFUSED-STRICT-WALK", lines)
        self.assertNotEqual(r.returncode, 0)
        self.assertFalse(any(l.startswith("records_") for l in lines),
                         "a refused FIBER run must print no records_* estimate")

    def test_unrestricted_fiber_is_still_accepted(self):
        # Control: the refusal must be scoped to strict walks, not to FIBER itself.
        _, lines = self._run(["--estimate-knuth", "50"],
                             env={"SOLVE_KNUTH_FIBER": "1"}, timeout=180)
        self.assertIn("FIBER_MODE=ACTIVE-UNRESTRICTED", lines)
        self.assertNotIn("FIBER_MODE=REFUSED-STRICT-WALK", lines)

    def test_exact_mode_refuses_strict_flags_it_cannot_apply(self):
        # exact_count() prunes on C1/C2/C5 only. Pre-fix it silently counted the UNRESTRICTED
        # subtree while a strict flag was set, answering a different question than the one asked.
        r, lines = self._run(["--estimate-knuth", "0", "3", "0", "5", "0", "7", "0"],
                             env={"SOLVE_KNUTH_MOORE_STRICT": "1"}, timeout=120)
        self.assertIn("EXACT_COUNT=REFUSED-STRICT-UNSUPPORTED", lines)
        self.assertNotEqual(r.returncode, 0, "a refusal must exit non-zero")
        self.assertFalse(any(l.startswith("tree_nodes :") for l in lines),
                         "a refusal must print no counts")


class TestRequiredSidecarIsAttested(unittest.TestCase):
    """A required reproducibility sidecar that could not be written must not exit 0.

    Codex v2 solve.c:10395-10461/:27118-:27381. write_sha256_with_metadata() was void: a failed
    fopen, a failed hash, and every unchecked fprintf/fclose returned quietly, and the caller
    downgraded an absent or empty sidecar to a WARNING. Reproduced by pre-creating the sidecar
    path as a DIRECTORY, which needs no ENOSPC: pre-fix the run completed, printed a BLANK hash
    in its own report, and exited 0 with the sidecar never written (measured 2026-09-04, rc 0);
    post-fix it exits 31 with SIDECAR=WRITE-FAILED. The control shows the same command writing a
    real sidecar and exiting 0, so the gate measures the failure path and not the build."""

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="sidecar_")
        cls.sbin = os.path.join(cls.tmp, "solve_sidecar")
        src = os.environ.get("ROAE_TESTS_SOLVE_SRC", "solve.c")
        r = subprocess.run(["gcc", "-O1", "-pthread", "-fopenmp", "-o", cls.sbin, src,
                            "-lm", "-lz"], capture_output=True, text=True)
        cls.build_ok = (r.returncode == 0 and os.path.exists(cls.sbin))
        cls.build_err = f"gcc rc {r.returncode}: " + r.stderr[-2000:]

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def _branch(self, block_sidecar):
        if not self.build_ok:
            self.fail("solve.c did not build, so nothing was verified: " + self.build_err)
        d = tempfile.mkdtemp(dir=self.tmp)
        if block_sidecar:
            os.mkdir(os.path.join(d, "solutions_1_0.sha256"))
        r = subprocess.run([self.sbin, "--branch", "1", "0", "6", "2"],
                           capture_output=True, text=True, cwd=d, timeout=900)
        return r, d, [" ".join(l.split()) for l in (r.stdout + "\n" + r.stderr).splitlines()]

    def test_a_sidecar_that_cannot_be_written_is_fatal(self):
        r, _, lines = self._branch(block_sidecar=True)
        self.assertIn("SIDECAR=WRITE-FAILED", lines)
        self.assertNotEqual(r.returncode, 0,
                            "an unwritable REQUIRED sidecar must not exit 0")

    def test_the_normal_path_still_writes_a_sidecar_and_exits_zero(self):
        r, d, _ = self._branch(block_sidecar=False)
        self.assertEqual(r.returncode, 0, r.stderr[-400:])
        sc = os.path.join(d, "solutions_1_0.sha256")
        self.assertTrue(os.path.isfile(sc), "sidecar not written on the clean path")
        with open(sc) as fh:
            first = fh.readline().split()
        self.assertEqual(len(first[0]), 64, "sidecar first line is not a 64-hex sha: " + str(first))


class TestExtractionNull(unittest.TestCase):
    """`solve.py --extraction-null` — the Q-143 decoy sampler, and the mode SPECIFICATION.md's
    null-model caveat names as its outstanding fix.

    The caveat has stood for months as an UNREPRODUCED historical observation ("9 of 10 cases") with
    no command, seed or target list anywhere in the project. These tests pin the properties that make
    a published percentile checkable by a stranger: the draw is DETERMINISTIC under its seed, the
    seed actually matters, and every emitted vector really is a C1&C2 difference-wave multiset."""

    def _run(self, n, seed=None):
        cmd = [sys.executable, "solve.py", "--extraction-null", str(n)]
        if seed is not None:
            cmd += ["--extraction-null-seed", str(seed)]
        r = subprocess.run(cmd, capture_output=True, text=True)
        lines = r.stdout.splitlines()
        vecs = [l for l in lines if l and not l.startswith("EXTRACTION_NULL=")]
        return r.returncode, vecs, lines

    def test_emits_a_whole_line_verdict_token(self):
        rc, vecs, lines = self._run(5)
        self.assertEqual(rc, 0)
        self.assertEqual(len(vecs), 5)
        self.assertTrue(any(l.startswith("EXTRACTION_NULL=OK ") for l in lines),
                        "no whole-line EXTRACTION_NULL=OK token")

    def test_the_draw_is_deterministic_under_its_seed(self):
        # Without this a published percentile is not checkable by anyone, which is the whole
        # complaint SPECIFICATION.md's caveat records against the original 9-in-10 observation.
        _, a, _ = self._run(40, seed=20260904)
        _, b, _ = self._run(40, seed=20260904)
        self.assertEqual(a, b, "same seed produced a different draw")

    def test_the_seed_actually_changes_the_draw(self):
        # A "seeded" sampler that ignores its seed is reproducible and useless.
        _, a, _ = self._run(40, seed=20260904)
        _, b, _ = self._run(40, seed=1)
        self.assertNotEqual(a, b, "changing the seed did not change the draw")

    def test_every_vector_is_a_valid_C1C2_difference_wave(self):
        rc, vecs, _ = self._run(60)
        self.assertEqual(rc, 0)
        for v in vecs:
            counts = {}
            for part in v.split(","):
                d, c = part.split(":")
                counts[int(d)] = int(c)
            self.assertEqual(sum(counts.values()), 63,
                             f"{v!r} does not describe 63 transitions")
            self.assertEqual(counts.get(5, 0), 0, f"{v!r} carries a distance-5 transition (breaks C2)")
            self.assertEqual(counts.get(0, 0), 0, f"{v!r} carries a distance-0 transition")
            self.assertTrue(all(0 <= d <= 6 for d in counts), f"{v!r} has an out-of-range distance")

    def test_king_wens_own_multiset_is_drawable(self):
        # Not a formality: it is the self-consistency anchor of the whole control. If KW's own
        # signature could never be drawn, the null would not contain the object it is a null for.
        _, vecs, _ = self._run(1000, seed=20260904)
        self.assertIn("1:2,2:20,3:13,4:19,6:9", vecs,
                      "King Wen's own difference-wave multiset never appeared in 1000 draws")


class TestQ3IsOnlyNamedKingWenWhenItIsKingWen(unittest.TestCase):
    """A full-31 trace is published as `q3_profile_kw.tsv` only after a row-for-row check
    against `binary_hexagrams` (Q-316 item 1 / Codex A03, 2026-09-04).

    The emitter used to choose that filename on `n == 31` ALONE.  n is a property of the
    UNIVERSE, not of the walk, so any one of the 1.097e39 valid full-31 walks was published
    under a name asserting it was King Wen's — and every downstream reader takes the name at
    its word.  The reader-side gate could not catch it: `prod(p_i) == 1/N` is a walk-generic
    telescoping identity that EVERY valid walk satisfies, which is exactly why a name is not
    evidence."""

    def _kw_steps(self, n=31):
        S = _load("solve")
        bh = S.binary_hexagrams
        return [{"step": i, "pair": i, "entry": bh[2 * i], "exit": bh[2 * i + 1]}
                for i in range(1, len(bh) // 2)]

    def test_king_wens_own_walk_is_recognised_and_earns_the_kw_name(self):
        S = _load("solve")
        ok, why = S.atlas_q3_trace_is_king_wen(self._kw_steps())
        self.assertTrue(ok, why)
        self.assertEqual(S.atlas_q3_name(self._kw_steps(), 31)[0], "q3_profile_kw.tsv")
        self.assertEqual(S.atlas_q3_name(self._kw_steps(), 31)[1], "PASS")

    def test_a_reordered_walk_does_not_get_the_kw_name(self):
        S = _load("solve")
        steps = self._kw_steps()
        steps[4]["pair"], steps[5]["pair"] = steps[5]["pair"], steps[4]["pair"]
        ok, why = S.atlas_q3_trace_is_king_wen(steps)
        self.assertFalse(ok)
        self.assertIn("places pair", why)
        name, status, _ = S.atlas_q3_name(steps, 31)
        self.assertEqual(name, "q3_profile.tsv")
        self.assertEqual(status, "NOT-KW")

    def test_a_reoriented_pair_does_not_get_the_kw_name(self):
        # The subtle one: same pairs, same order, one pair entered from the other end.
        S = _load("solve")
        steps = self._kw_steps()
        steps[9]["entry"], steps[9]["exit"] = steps[9]["exit"], steps[9]["entry"]
        ok, why = S.atlas_q3_trace_is_king_wen(steps)
        self.assertFalse(ok)
        self.assertIn("orients pair", why)
        self.assertEqual(S.atlas_q3_name(steps, 31)[0], "q3_profile.tsv")

    def test_a_short_trace_does_not_get_the_kw_name(self):
        S = _load("solve")
        ok, why = S.atlas_q3_trace_is_king_wen(self._kw_steps()[:-1])
        self.assertFalse(ok)
        self.assertIn("free placements", why)

    def test_below_full_31_the_question_is_skipped_never_passed(self):
        S = _load("solve")
        name, status, why = S.atlas_q3_name(self._kw_steps(), 9)
        self.assertEqual(name, "q3_profile.tsv")
        self.assertEqual(status, "SKIP:n=9")
        self.assertNotEqual(status, "PASS")
        self.assertIn("no King Wen walk", why)


class TestQ3ReaderCheckShellsAreNonIncreasing(unittest.TestCase):
    """`atlas_q3_reader_check` gates the shell sizes, and it gates them as NON-INCREASING
    (Q-316 item 4, 2026-09-04).

    `viz/viz_kc_shells.md` listed this among the reader-side checks while the function did
    not perform it -- a documented gate with no code behind it. The distinction that matters
    is `>` versus `>=`: the shells are nested so `g` can never grow, but a forced placement
    has `p_i = 1` and shrinks nothing, so equality is legal and this repository's own
    committed n=9 trace is flat twice. A strict test would have made the artifact the
    counterexample to its own gate."""

    def _tsv(self, gs, N):
        import tempfile, os
        fd, path = tempfile.mkstemp(suffix=".tsv"); os.close(fd)
        with open(path, "w") as fh:
            fh.write("step\tg\tg_parent\tp_num\tp_den\tf\talts\n")
            parent = N
            for i, g in enumerate(gs, start=1):
                fh.write("%d\t%d\t%d\t%d\t%d\t1\t1\n" % (i, g, parent, g, parent))
                parent = g
        self.addCleanup(os.unlink, path)
        return path

    def test_the_committed_n9_trace_is_flat_twice_and_still_passes(self):
        S = _load("solve")
        path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "scripts", "tr12_expected", "n9", "a2_q3_profile.txt")
        rows = S.atlas_parse_q3_trace(path)
        gs = [int(r["g"]) for r in rows]
        self.assertEqual(gs, [2368, 456, 160, 32, 8, 4, 4, 1, 1])
        self.assertTrue(any(a == b for a, b in zip(gs, gs[1:])),
                        "the fixture that motivates 'non-increasing' is no longer flat")
        self.assertEqual(S.atlas_q3_reader_check(self._tsv(gs, 26112), 26112), [])

    # ---- RCQ01 F2: the producer's own verdict is not optional -------------------------------
    # atlas_parse_q3_trace kept only "#o3-trace\t" rows and discarded everything else, including
    # the emitter's KC_O3_TRACE=FAIL and a "product check FAILED" summary three lines above the
    # data. Measured 2026-09-09 through the real CLI: a trace whose emitter said FAIL, rows
    # unchanged, produced TR12_Q3=PASS and rc 0 -- identical to the OK control. The telescoping
    # check here cannot re-derive the identity the producer failed, so it has to read the verdict.

    def _trace(self, verdict=None, summary="flow_identities=9/9 product(p_i)=1/N EXACT"):
        import tempfile, os
        fd, path = tempfile.mkstemp(suffix=".txt"); os.close(fd)
        with open(path, "w") as fh:
            # the shape the emitter actually writes, taken from scripts/tr12_expected/n9/a2_q3.txt
            fh.write("#o3-trace\tstep=1\tpair=11\tentry=1\texit=32\torient=1\talts=12"
                     "\tmass_below=9472\tf=1\tg=2368\tg_parent=26112\tp=2368/26112"
                     "\tbits=3.462972\n")
            if summary is not None:
                fh.write("#o3-trace-summary\t%s\n" % summary)
            if verdict is not None:
                fh.write("%s\n" % verdict)
        self.addCleanup(os.unlink, path)
        return path

    def test_a_trace_its_own_emitter_rejected_is_refused(self):
        S = _load("solve")
        with self.assertRaises(S.AtlasError) as cm:
            S.atlas_parse_q3_trace(self._trace(verdict="KC_O3_TRACE=FAIL"))
        self.assertIn("KC_O3_TRACE=FAIL", str(cm.exception))

    def test_a_summary_with_no_verdict_token_is_refused_not_assumed_good(self):
        # A summary line means a post-D2 emitter, which always writes the token. A summary with
        # no token is a file whose producer result we cannot read, and unreadable is not OK.
        S = _load("solve")
        with self.assertRaises(S.AtlasError):
            S.atlas_parse_q3_trace(self._trace(verdict=None))

    def test_a_failed_summary_is_refused_even_when_the_token_says_OK(self):
        S = _load("solve")
        with self.assertRaises(S.AtlasError):
            S.atlas_parse_q3_trace(self._trace(verdict="KC_O3_TRACE=OK",
                                               summary="flow_identities=8/9 product check FAILED"))

    def test_an_OK_trace_still_parses(self):
        # Without this the three tests above pass on a parser that refuses everything.
        S = _load("solve")
        rows = S.atlas_parse_q3_trace(self._trace(verdict="KC_O3_TRACE=OK"))
        self.assertEqual(len(rows), 1)
        self.assertEqual(int(rows[0]["g"]), 2368)

    # ---- RCQ02 F3: the TSV grammar read no verdict at all -------------------------------------
    # The profile branch skips every line whose column count differs from the header's -- which is
    # every verdict line. So a `--kc-profile --kc-tsv` table from a run that FAILED its product
    # identity was read as TR12_Q3=PASS. Measured through the real CLI, 2026-09-09. The producer
    # now appends one-column trailers AFTER the verdict is known, and removes the table entirely
    # when the verdict is FAIL.

    def _prof_tsv(self, verdict="OK", product="EXACT", summary_failed=False):
        import tempfile, os
        fd, path = tempfile.mkstemp(suffix=".tsv"); os.close(fd)
        with open(path, "w") as fh:
            if summary_failed:
                fh.write("#profile-summary\tn=9\tg(s_0)=N FAILED\n")
            fh.write("step\tpair\tentry\texit\torient\talts\tmass_below\tf\tg\tg_parent"
                     "\tp_num\tp_den\tbits\n")
            fh.write("1\t11\t1\t32\t1\t12\t9472\t1\t2368\t26112\t2368\t26112\t3.46\n")
            if product is not None:
                fh.write("KC_PROFILE_PRODUCT=%s\n" % product)
            if verdict is not None:
                fh.write("KC_PROFILE=%s\n" % verdict)
        self.addCleanup(os.unlink, path)
        return path

    def test_a_profile_its_own_producer_rejected_is_refused(self):
        S = _load("solve")
        with self.assertRaises(S.AtlasError) as cm:
            S.atlas_parse_q3_trace(self._prof_tsv(verdict="FAIL", product="MISMATCH"))
        self.assertIn("KC_PROFILE=FAIL", str(cm.exception))

    def test_a_profile_with_no_verdict_trailer_is_refused(self):
        # A pre-fix producer wrote the table BEFORE deciding its verdict, leaving no attestation.
        S = _load("solve")
        with self.assertRaises(S.AtlasError):
            S.atlas_parse_q3_trace(self._prof_tsv(verdict=None, product=None))

    def test_a_profile_summary_reporting_FAILED_is_refused(self):
        S = _load("solve")
        with self.assertRaises(S.AtlasError):
            S.atlas_parse_q3_trace(self._prof_tsv(summary_failed=True))

    def test_an_OK_profile_still_parses(self):
        # Without this the three refusals above pass on a parser that refuses every profile.
        S = _load("solve")
        rows = S.atlas_parse_q3_trace(self._prof_tsv())
        self.assertEqual(len(rows), 1)
        self.assertEqual(int(rows[0]["g"]), 2368)

    def test_an_o3_trace_stripped_of_its_token_is_refused(self):
        # Rows only, no summary, no KC_O3_TRACE=. Previously PASSED: the refusal fired only when a
        # summary was present, so deleting the summary too was a way past the attestation check.
        S = _load("solve")
        with self.assertRaises(S.AtlasError) as cm:
            S.atlas_parse_q3_trace(self._trace(verdict=None, summary=None))
        self.assertIn("KC_O3_TRACE", str(cm.exception))

    def test_a_shell_that_grows_is_caught(self):
        S = _load("solve")
        fails = S.atlas_q3_reader_check(self._tsv([8, 16, 1], 32), 32)
        self.assertTrue(any("g grew" in f for f in fails), fails)

    def test_the_gate_is_not_strict_a_flat_pair_alone_is_not_a_failure(self):
        S = _load("solve")
        fails = S.atlas_q3_reader_check(self._tsv([8, 8, 1], 8 * 8), 8 * 8)
        self.assertFalse([f for f in fails if "g grew" in f], fails)


class TestAtlasExternalChecksAreReachableAndCanFail(unittest.TestCase):
    """The ONLY full-31 checks against PUBLISHED numbers now have a call site, and both
    are shown able to FAIL (Q-320 item 4 / Codex R07+R10, 2026-09-04).

    `atlas_a2_slot_check` and `atlas_a3_external_check` were defined, documented, and
    called from NOWHERE -- zero call sites outside their own `def` lines, and absent from
    `_ATLAS_SELECTORS`, so no `--atlas-select` value could reach them either.  Every other
    gate in the atlas consumer is internal arithmetic, which passes happily while the
    G-expansion mis-assigns pair identities; these two compare against figures printed in
    TR-7 *before the scan existed*.  An external check that nothing runs is not a weaker
    check, it is no check -- and it emitted no verdict, so its absence was silent.

    Both rest on C4 fixing slot 0, a full-31 property, so on any real artifact this repo can
    build cheaply they SKIP.  A test that only ever observes a SKIP proves nothing, so the
    fixtures here are SYNTHETIC n=31 atlases: one built to the published fractions, and
    perturbations that each break exactly one thing the check claims to catch."""

    D3 = [5, 8, 10, 15, 20, 23, 26, 27, 29, 31]
    D1 = [4, 6, 21]
    D5 = [3, 7, 11]
    N = 1000000

    def _atlas(self, pert=None, slot2=52000, slot32=78500):
        """An n=31-shaped atlas whose final-layer raw marginal sits on TR-7's published
        wrap-class fractions (0.652 / 0.175 / 0.174) and whose A2 cell sits on the
        published slot anchors (0.0785 at slot 32, 0.0520 at slot 2, summing to R-C1c
        0.1305).  The class membership is not hardcoded here -- it is asserted against
        solve.atlas_a3_wrap_class_map(), which derives it from binary_hexagrams."""
        last = {"pair31": slot32}
        others = [p for p in self.D3 if p != 31]
        q, r = divmod(652000 - slot32, len(others))
        for i, p in enumerate(others):
            last["pair%d" % p] = q + (1 if i < r else 0)
        for grp, tot in ((self.D1, 175000), (self.D5, 173000)):
            q, r = divmod(tot, len(grp))
            for i, p in enumerate(grp):
                last["pair%d" % p] = q + (1 if i < r else 0)
        for k, v in (pert or {}).items():
            last[k] = last.get(k, 0) + v
        # 🔴 THIRTY-ONE layers, and slot 2 on layers[0] -- BOTH are load-bearing, and this
        # fixture had BOTH wrong until 2026-09-06, which is why the test was red on main.
        #   * atlas_a2_slot_check asserts `len(layers) == n` (added 075931f4, 2026-09-05) because
        #     that invariant is what makes layers[-1] slot 32 AT ALL: a short ladder silently
        #     re-points layers[-1] at some other slot and compares it against slot 32's reference.
        #     A 3-layer fixture therefore SKIPped, and a test that only observes a SKIP proves
        #     nothing -- which is the exact failure mode this class's docstring exists to prevent.
        #   * slot 2 is layers[0], NOT layers[1]: "layer k fills pair-slot k+2"
        #     (viz/viz_kc_field.md:34). The check read layers[1] until Codex MQ1 §2a caught it on
        #     2026-09-04; this fixture still encoded the superseded convention, so it would have
        #     gone on agreeing with the bug it was supposed to catch.
        layers = [{"k": i} for i in range(31)]
        layers[0]["marginal_raw"] = {"pair31": str(slot2)}
        layers[30]["marginal_raw"] = {k: str(v) for k, v in last.items()}
        return {"n": 31, "N_total": str(self.N), "layers": layers}

    def test_the_fixtures_class_map_is_the_derived_one_not_a_copy(self):
        S = _load("solve")
        cmap = S.atlas_a3_wrap_class_map()
        got = {}
        for p, d in cmap.items():
            got.setdefault(d, []).append(p)
        self.assertEqual(sorted(got[3]), sorted(self.D3))
        self.assertEqual(sorted(got[1]), sorted(self.D1))
        self.assertEqual(sorted(got[5]), sorted(self.D5))

    def test_both_checks_are_reachable_through_the_selector_tuple(self):
        S = _load("solve")
        self.assertIn("a2", S._ATLAS_SELECTORS)
        self.assertIn("a3", S._ATLAS_SELECTORS)

    def test_a3_references_is_bound_once(self):
        # It was defined TWICE with different key types and different values; the second
        # silently won and the first was unreachable. A grep is the only way to see it,
        # because at runtime the shadowing is invisible.
        with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "solve.py")) as fh:
            src = fh.read()
        self.assertEqual(len(re.findall(r"^_A3_REFERENCES\s*=", src, re.M)), 1)

    def test_the_published_fixture_passes_both(self):
        S = _load("solve")
        A = self._atlas()
        self.assertEqual(S.atlas_a3_external_check(A)[0], "PASS")
        self.assertEqual(S.atlas_a2_slot_check(A)[0], "PASS")

    def test_a3_fails_when_class_mass_moves(self):
        S = _load("solve")
        st, detail = S.atlas_a3_external_check(
            self._atlas(pert={"pair5": -20000, "pair4": 20000}))
        self.assertEqual(st, "FAIL", detail)

    def test_a3_fails_on_a_closer_that_is_not_eligible(self):
        S = _load("solve")
        st, detail = S.atlas_a3_external_check(
            self._atlas(pert={"pair0": 5000, "pair5": -5000}))
        self.assertEqual(st, "FAIL")
        self.assertIn("NOT eligible closers", detail)

    def test_a2_fails_when_the_per_pair_anchor_moves(self):
        # The point of A2 over A3: a swap of A2 with another d=3 pair leaves the d3 CLASS
        # total untouched, so A3 cannot see it and A2 must.
        S = _load("solve")
        st, detail = S.atlas_a2_slot_check(self._atlas(slot32=60000))
        self.assertEqual(st, "FAIL", detail)
        self.assertEqual(S.atlas_a3_external_check(self._atlas(slot32=60000))[0], "PASS",
                         "A3 was expected to be BLIND to a within-d3 move; if it now sees "
                         "it, the comment claiming A2 is the stronger per-pair check is stale")

    def test_below_full_31_both_skip_loudly_and_never_pass(self):
        S = _load("solve")
        for fn in (S.atlas_a2_slot_check, S.atlas_a3_external_check):
            st, why = fn({"n": 9})
            self.assertTrue(st.startswith("SKIP:"), st)
            self.assertNotEqual(st, "PASS")
            self.assertTrue(why)


class TestTr12FixtureRatiosAreRoundedNotTruncated(unittest.TestCase):
    """Every 9-place ratio in the committed n=9 TR-12 fixtures is the correctly ROUNDED
    value of its own two integer columns (Q-316 item 3, 2026-09-04).

    `bc` truncates at `scale`; it does not round.  `scale=9; 2720/26112` is 0.104166666
    where the 9-place value is 0.104166667, and that wrong digit was COMMITTED into
    `scripts/tr12_expected/n9/c_q6.txt` -- into the fixture set that gates the whole
    reproduction battery, so the battery was enforcing the defect rather than catching it.
    Codex A03 named the two cells in `c_q6`; the identical expression at the V5 site had put
    EIGHT more into `c_v5.txt`, which nothing had looked at.  **Ten wrong last digits.**

    This test is a SECOND IMPLEMENTATION, not a re-run: exact `fractions.Fraction` in Python
    against shell `bc`, and it recomputes each ratio from the file's OWN mass and flow columns
    rather than from anything the driver emitted.  It would have caught all ten on the day they
    landed, and it fails if a future edit reintroduces truncation at either site or in a new one.

    Shown able to fail, 2026-09-04: restoring the two pre-fix `c_q6` digits fails with
    `c_q6.txt k=1: shipped 0.104166666, exact 9-place 0.104166667`; restoring the eight `c_v5`
    digits fails naming each."""

    DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "scripts", "tr12_expected", "n9")

    @staticmethod
    def _round9(num, den):
        from fractions import Fraction
        if num == 0:
            return "0"
        # half-up at the ninth place, in exact integer arithmetic -- never a float
        scaled = Fraction(num * 10 ** 9, den)
        q = (2 * scaled.numerator + scaled.denominator) // (2 * scaled.denominator)
        return f"{q // 10 ** 9}.{q % 10 ** 9:09d}"

    def _cells(self):
        """(file, label, numerator, denominator, shipped) for every ratio cell."""
        # 🔴 c_q6.txt IS ELEVEN COLUMNS, NOT NINE, since af95a91f (2026-09-05) rewrote it to the
        # "REDUCED FORM" its own header describes. This parser still tested `len(f) == 9`, so it
        # matched ZERO q6 rows -- which left `flow` empty and made every c_v5.txt lookup raise
        # KeyError, erroring both tests in this class on clean `main`. It is worth naming what the
        # failure mode WOULD have been had v5 not blown up: a silently empty population, i.e. a
        # green test over nothing. `test_the_population_is_not_empty` exists for exactly that and is
        # why this surfaced as an error rather than as a vacuous pass.
        #
        # Columns: 1=k 2=flow 3..7=class masses d1,d2,d3,d4,d6 8=anchor_d 9=anchor_class_mass
        #          10=anchor_p 11=anchor_class_pct   (1-based; header row skipped by isdigit)
        # Both shipped ratios are checkable from the row's own integers, and both are checked --
        # anchor_p = anchor_class_mass/flow, and anchor_class_pct = (sum of class masses <= the
        # anchor's)/flow, which is the header's own definition. Verified against all 18 shipped
        # cells before this parser was written: 18 reproduced, 0 mismatched.
        out = []
        q6 = os.path.join(self.DIR, "c_q6.txt")
        flow = {}
        for line in open(q6):
            f = line.rstrip("\n").split("\t")
            if len(f) != 11 or not f[0].isdigit():
                continue
            flow[f[0]] = int(f[1])
            masses = [int(x) for x in f[2:7]]
            anchor_mass = int(f[8])
            if f[9] not in ("NA", ""):
                out.append((os.path.basename(q6), f"k={f[0]} anchor_p",
                            anchor_mass, int(f[1]), f[9]))
            if f[10] not in ("NA", ""):
                out.append((os.path.basename(q6), f"k={f[0]} anchor_class_pct",
                            sum(m for m in masses if m <= anchor_mass), int(f[1]), f[10]))
        v5 = os.path.join(self.DIR, "c_v5.txt")
        for line in open(v5):
            f = line.rstrip("\n").split("\t")
            if len(f) == 4 and f[0].isdigit():
                out.append((os.path.basename(v5), f"k={f[0]} {f[1]}", int(f[2]), flow[f[0]], f[3]))
        return out

    def test_the_population_is_not_empty(self):
        # A parser that silently matched nothing would make the next test vacuously green,
        # which is the failure mode this project keeps finding in its own gates.
        self.assertGreaterEqual(len(self._cells()), 50,
                                "the fixture parser found almost no ratio cells -- it stopped "
                                "matching, which is a broken test, not a passing one")

    def test_every_committed_ratio_is_the_rounded_value_of_its_own_columns(self):
        bad = []
        for fname, label, num, den, shipped in self._cells():
            want = self._round9(num, den)
            if shipped != want:
                bad.append(f"{fname} {label}: shipped {shipped}, exact 9-place {want} "
                           f"({num}/{den})")
        self.assertEqual(bad, [], "bc truncation has returned:\n  " + "\n  ".join(bad))


class TestSection14OrientCouplingIsDeadOnDedupedInput(unittest.TestCase):
    """`--analyze` section 14 is DEAD on every artifact the pipeline writes (Q-322).

    Codex A02's section-14 remainder: the section groups records by pair-index
    sequence to measure orient-coupling, but the format stores ONE record per
    unique pair-sequence with orient variants collapsed, so every group has size
    one and the analytics can never fire.  Section 14 already carried a runtime
    degeneracy detector; what it did NOT say is that the degeneracy is a property
    of the FORMAT rather than of the file in hand, which is the difference between
    "this input happens to be deduped" and "no input this program produces is
    anything else".  That sentence is now in the code and this test keeps it true.

    The marker must be a MEASUREMENT WITH TWO POSSIBLE VALUES, not a constant --
    a detector that can only print one string attests nothing.  So both arms are
    exercised: the deduped shape (which is what the pipeline emits) and a
    hand-built orientation-EXPLICIT file (which no shipped command produces).

    Fixtures are synthetic 32-byte-per-record ROAE v1 files: byte i is
    `(pair << 2) | (orient << 1)`.  Two records suffice, and the whole class runs
    in about a second on top of the build."""

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="s14dead_")
        cls.sbin = os.path.join(cls.tmp, "solve_s14")
        src = os.environ.get("ROAE_TESTS_SOLVE_SRC", "solve.c")
        r = subprocess.run(["gcc", "-O1", "-pthread", "-fopenmp", "-o", cls.sbin, src,
                            "-lm", "-lz"], capture_output=True, text=True)
        cls.build_ok = (r.returncode == 0 and os.path.exists(cls.sbin))
        cls.build_err = f"gcc rc {r.returncode}: " + r.stderr[-2000:]

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    @staticmethod
    def _rec(perm, orients):
        return bytes(((p << 2) | (o << 1)) for p, o in zip(perm, orients))

    def _analyze(self, name, records):
        if not self.build_ok:
            self.fail("solve.c did not build, so nothing was analysed: " + self.build_err)
        path = os.path.join(self.tmp, name)
        with open(path, "wb") as fh:
            fh.write(b"ROAE" + struct.pack("<I", 1) + struct.pack("<Q", len(records))
                     + b"\0" * 16 + b"".join(records))
        r = subprocess.run([self.sbin, "--analyze", path], capture_output=True, text=True)
        return r.returncode, [" ".join(l.split()) for l in r.stdout.splitlines()]

    def test_one_record_per_pair_sequence_is_reported_degenerate_and_named_as_format(self):
        base = list(range(32))
        swapped = base[:5] + [base[6], base[5]] + base[7:]
        rc, lines = self._analyze("distinct.bin", [self._rec(base, [0] * 32),
                                                   self._rec(swapped, [0] * 32)])
        self.assertEqual(rc, 0)
        self.assertIn("ORIENT_COUPLING=DEGENERATE-DEDUPED-INPUT", lines)
        self.assertFalse([l for l in lines if l.startswith("ORIENT_COUPLING=MEASURABLE")],
                         "both verdicts printed at once")
        # The RULING, not merely the observation: the arm must say the ground is the
        # format.  Without this the section still reads as "this file happens to be
        # deduped", which is the sentence Q-322 was filed against.
        self.assertTrue(any("AND THAT IS THE FORMAT, NOT THIS FILE" in l for l in lines),
                        "the degenerate arm no longer states that the format, not the "
                        "file, is why these analytics are dead")
        self.assertTrue(any("DEAD on all of them" in l for l in lines))

    def test_an_orientation_explicit_file_still_measures_and_says_so(self):
        # The other direction.  No shipped command writes this file; it exists to
        # prove the detector is a measurement and not a hardcoded string.
        base = list(range(32))
        rc, lines = self._analyze("orient.bin", [
            self._rec(base, [0] * 32),
            self._rec(base, [0, 0, 0, 0, 0, 1] + [0] * 26)])
        self.assertEqual(rc, 0)
        self.assertIn("ORIENT_COUPLING=MEASURABLE (largest group 2 variants)", lines)
        self.assertNotIn("ORIENT_COUPLING=DEGENERATE-DEDUPED-INPUT", lines)
        self.assertFalse(any("AND THAT IS THE FORMAT, NOT THIS FILE" in l for l in lines),
                         "the DEAD ruling leaked into the arm where the analytics are live")



class TestKcExtremalTwoLanguageRecheck(unittest.TestCase):
    """The TR-12 §Q5 two-language obligation: solve.py really re-checks --kc-extremal numbers.

    WHAT WENT WRONG. `solve.c`'s --kc-extremal registry cited `solve.py:_dist_multiset`,
    `solve.py:_boundary_distances` and `solve.py:_yang_count` in its `py_ref` column, printed
    them in `--kc-extremal list` and wrote them into every certificate, and the KC-X module
    header made the cross-language re-check a shipping condition -- "no Q5 number ships without
    it". None of the three functions existed (Codex KCQ03 #1, adjudicated TRUE 2026-09-02;
    re-measured as F2 by the Fable review of 2026-09-09). Only the SAME-language half,
    solve.c's `kc_xs_ref_w`, had landed. This class exists so the second language cannot go
    missing again silently.

    THE POINT OF THE CLASS IS THE RED ARM. A reference that has only ever agreed is not a
    check, so the disagreement legs below are the load-bearing ones: they mutate the
    certificate the way a wrong producer would and require KC_X_PYCHECK=FAIL. Every verdict is
    matched WHOLE-LINE (`assertIn` over split lines), never by substring shape.

    Scope, stated because the token must not be over-read: this re-checks that the published
    number is ATTAINED by the published walk. It does NOT re-derive extremality (Fable F4)."""

    # A real n=9 certificate, reduced to the keys the checker reads. Its witness and its
    # extreme_value were produced by `solve --kc-extremal yangcount <f> max --kc-witness`
    # on an n=9 ladder and are pinned here so these legs need no binary and no ladder.
    CERT = {
        "type": "roae-kc-extremal-certificate",
        "version": 1,
        "functional": "yangcount",
        "direction": "max",
        "n": 9,
        "start_exit": 0,
        "g_invariant": True,
        "extreme_value": 30,
        "witness": "16,2,8,4,55,59,47,61,62,31,1,32,33,30,18,45,12,51",
        "witness_value": 30,
        "witness_member": True,
        "witness_verified": True,
    }

    def _walk(self):
        return solve.kc_x_parse_witness(self.CERT["witness"], 9)

    def _recheck(self, *certs):
        """Write certs to a temp dir, run solve.py --kc-x-recheck, return (rc, lines)."""
        import json
        d = tempfile.mkdtemp(prefix="kcxpy_")
        try:
            paths = []
            for i, c in enumerate(certs):
                p = os.path.join(d, "cert_%02d.json" % i)
                with open(p, "w") as fh:
                    if isinstance(c, str):
                        fh.write(c)              # deliberately malformed JSON fixture
                    else:
                        json.dump(c, fh)
                paths.append(p)
            r = subprocess.run([sys.executable, "solve.py", "--kc-x-recheck"] + paths,
                               capture_output=True, text=True, timeout=300)
            return r.returncode, [l.rstrip() for l in
                                  (r.stdout + "\n" + r.stderr).splitlines()]
        finally:
            shutil.rmtree(d, ignore_errors=True)

    # ---- the functions the registry cites EXIST and are what it says they are ---------------

    def test_the_three_cited_functions_exist(self):
        # The whole defect in one assertion: solve.c cites these three by name, so an edit that
        # renames or drops one must break here rather than in a reader's hands.
        for name in ("_dist_multiset", "_boundary_distances", "_yang_count"):
            self.assertTrue(callable(getattr(solve, name, None)),
                            "solve.c's --kc-extremal py_ref column cites solve.py:%s, which "
                            "does not exist" % name)

    def test_solve_c_registry_py_refs_all_resolve(self):
        # Not the three names hardcoded -- the names solve.c ACTUALLY cites today, mined from
        # the registry table, so adding a row with a new py_ref cannot land unaccompanied.
        with open("solve.c", encoding="utf-8") as fh:
            src = fh.read()
        cited = set(re.findall(r'"solve\.py:([A-Za-z_][A-Za-z0-9_]*)"', src))
        self.assertTrue(cited, "no solve.py:<fn> citations found in solve.c -- this test "
                               "measured nothing and must not read as agreement")
        missing = sorted(n for n in cited if not callable(getattr(solve, n, None)))
        self.assertEqual(missing, [], "solve.c cites solve.py functions that do not exist: %s"
                         % missing)

    def test_boundary_distances_counts_n_boundaries_from_start_exit(self):
        w = self._walk()
        d = solve._boundary_distances(w, 0)
        self.assertEqual(len(d), 9)
        # The first boundary is measured from start_exit, not from the first entry.
        self.assertEqual(d[0], solve.bit_diff(0, w[0][0]))
        self.assertNotEqual(solve._boundary_distances(w, 63), d,
                            "start_exit is being ignored; the certificate carries it precisely "
                            "so the convention is not assumed")

    def test_dist_multiset_classes_are_1_2_3_4_6_and_sum_to_n(self):
        ms = solve._dist_multiset(self._walk(), 0)
        self.assertEqual(sorted(ms), [1, 2, 3, 4, 6],
                         "the boundary-distance classes are 1,2,3,4,6 -- distance 5 is "
                         "forbidden by C2 and 0 cannot occur")
        self.assertEqual(sum(ms.values()), 9)
        # linechanges is SUM_c count[c]*c over exactly these classes.
        self.assertEqual(sum(k * v for k, v in ms.items()),
                         solve.kc_x_phi("linechanges", self._walk(), 0))

    def test_graycode_is_the_distance_1_class(self):
        w = self._walk()
        self.assertEqual(solve.kc_x_phi("graycode", w, 0), solve.kc_x_phi("dclass:1", w, 0))

    def test_yang_count_sides_are_complementary(self):
        # popcount(entry)+popcount(exit) is a per-pair constant: a reversal partner has the SAME
        # popcount, a complement partner sums to 6.  So the two sides' total is a property of
        # WHICH pairs the walk places, never of how they are oriented -- computed here from the
        # pair identity rather than by re-running _yang_count on the other side.
        w = self._walk()
        total = sum(6 if entry == (exitx ^ 0b111111) else 2 * bin(exitx).count("1")
                    for entry, exitx in w)
        self.assertEqual(solve._yang_count(w, "exit") + solve._yang_count(w, "entry"), total)
        self.assertEqual(solve.kc_x_phi("yangcount", w, 0), solve._yang_count(w, "exit"))
        self.assertEqual(solve.kc_x_phi("entryyang", w, 0), solve._yang_count(w, "entry"))

    def test_the_registrys_own_number_is_reproduced(self):
        self.assertEqual(solve.kc_x_phi("yangcount", self._walk(), 0), 30)

    # ---- fail-closed on anything it cannot evaluate -----------------------------------------

    def test_posyang0_has_no_python_reference_and_is_refused(self):
        # The registry marks posyang0 "n/a - never publishable". A row nobody wrote a reference
        # for is exactly the row this check must not wave through, so absence is a REFUSAL.
        with self.assertRaises(ValueError):
            solve.kc_x_phi("posyang0", self._walk(), 0)

    def test_an_out_of_class_distance_is_refused_not_absorbed(self):
        # A witness whose first entry sits at Hamming distance 5 from start_exit is not a member
        # of the space; _dist_multiset must say so rather than drop it into a neighbouring class.
        with self.assertRaises(ValueError):
            solve._dist_multiset([(0b011111, 0b111110)], 0)

    def test_a_witness_that_is_not_a_canonical_pair_is_refused(self):
        # Built from solve.py's OWN build_pairs(), so a wrong partner on the C side is visible.
        with self.assertRaises(ValueError):
            solve.kc_x_parse_witness("1,2")

    def test_a_witness_that_repeats_a_pair_is_refused(self):
        w = self.CERT["witness"].split(",")
        with self.assertRaises(ValueError):
            solve.kc_x_parse_witness(",".join(w[:2] + w[:2]))

    # ---- the driver: PASS, and the three ways it must not pass ------------------------------

    def test_a_true_certificate_passes(self):
        rc, lines = self._recheck(self.CERT)
        self.assertEqual(rc, 0)
        self.assertIn("KC_X_PYCHECK=PASS", lines)
        self.assertIn("KC_X_PYCHECK_CHECKED=1", lines)

    def test_a_wrong_extreme_value_is_caught(self):
        # 🔴 THE RED ARM. This is the failure the whole obligation exists for: the producer
        # publishes a number its own witness does not attain.
        bad = dict(self.CERT, extreme_value=39, witness_value=39)
        rc, lines = self._recheck(bad)
        self.assertEqual(rc, 1)
        self.assertIn("KC_X_PYCHECK=FAIL", lines)
        self.assertTrue(any(l.startswith("KC_X_PYCHECK_ROW=") and "CHECKED-DISAGREE" in l
                            for l in lines))

    def test_a_tampered_witness_is_caught(self):
        # The other direction: the number is right, the walk is not the one that attains it.
        # Pair {12,51} swapped for {18,45}'s orientation partner changes popcount(exit).
        bad = dict(self.CERT,
                   witness="16,2,8,4,55,59,47,61,62,31,1,32,33,30,45,18,12,51")
        rc, lines = self._recheck(bad)
        self.assertEqual(rc, 1)
        self.assertIn("KC_X_PYCHECK=FAIL", lines)

    def test_an_exploratory_certificate_cannot_ship(self):
        # No --kc-witness => nothing to re-evaluate => the two-language obligation cannot be
        # discharged for that number, so it FAILS rather than passing vacuously.
        bad = dict(self.CERT, witness=None, witness_value=None,
                   witness_member=False, witness_verified=False)
        rc, lines = self._recheck(bad)
        self.assertEqual(rc, 1)
        self.assertIn("KC_X_PYCHECK=FAIL", lines)

    def test_a_certificate_without_start_exit_fails_rather_than_assuming_it(self):
        bad = dict(self.CERT)
        del bad["start_exit"]
        rc, lines = self._recheck(bad)
        self.assertEqual(rc, 1)
        self.assertIn("KC_X_PYCHECK=FAIL", lines)

    # ---- Q-771's refusals: start_exit range and the null_vs_g cross-gate (Q-775 #3) ----------
    # Each red leg changes ONE field of CERT. The positive controls below first show that CERT
    # with that field at an accepted value is CHECKED-AGREE, so a red verdict can only come from
    # the field under test. Verdicts are read as the row's verdict WORD, not by substring.

    def _verdict(self, cert):
        verdict, _detail = solve._kc_x_check_cert(cert)
        return verdict

    def test_the_refusal_legs_have_a_passing_baseline(self):
        # Precondition for every red leg below. CERT is a yangcount certificate, which never
        # reads start_exit, so start_exit=63 must pass too. A red leg is meaningful only if the
        # base certificate is not already failing for some other reason.
        self.assertEqual(self._verdict(self.CERT), "CHECKED-AGREE")
        self.assertEqual(self._verdict(dict(self.CERT, start_exit=63)), "CHECKED-AGREE")
        self.assertEqual(self._verdict(dict(self.CERT, gdir=None, null_vs_g=None)),
                         "CHECKED-AGREE")
        self.assertEqual(self._verdict(dict(self.CERT, gdir="/g", null_vs_g="CONSISTENT")),
                         "CHECKED-AGREE")

    def test_an_out_of_range_start_exit_is_refused_even_where_phi_ignores_it(self):
        # 🔴 The Q-771 F1 defect: before the fix, yangcount accepted ANY start_exit, because
        # only _boundary_distances validated it and yangcount never calls it.
        for bad in (99, 1, -1, True, "0", 0.0):
            self.assertEqual(self._verdict(dict(self.CERT, start_exit=bad)),
                             "FAIL-bad-start-exit", "start_exit=%r was not refused" % (bad,))

    def test_an_inconsistent_null_vs_g_is_refused(self):
        self.assertEqual(self._verdict(dict(self.CERT, gdir="/g", null_vs_g="INCONSISTENT")),
                         "FAIL-null-vs-g")

    def test_an_unknown_null_vs_g_value_is_refused(self):
        for bad in ("consistent", "PASS", "", 0, True):
            self.assertEqual(self._verdict(dict(self.CERT, gdir="/g", null_vs_g=bad)),
                             "FAIL-bad-null-vs-g", "null_vs_g=%r was not refused" % (bad,))

    def test_a_gdir_without_a_null_vs_g_verdict_is_refused(self):
        # Absent must not read as CONSISTENT: a --kc-gdir run always carries the verdict.
        self.assertEqual(self._verdict(dict(self.CERT, gdir="/g", null_vs_g=None)),
                         "FAIL-no-null-vs-g")
        self.assertEqual(self._verdict(dict(self.CERT, gdir="/g")), "FAIL-no-null-vs-g")

    def test_the_driver_fails_on_each_refusal_and_names_it(self):
        # The same refusals end to end through `solve.py --kc-x-recheck`: each certificate's
        # row carries its token, and the whole run is FAIL with exit 1.
        bads = [dict(self.CERT, start_exit=99),
                dict(self.CERT, gdir="/g", null_vs_g="INCONSISTENT"),
                dict(self.CERT, gdir="/g", null_vs_g="PASS"),
                dict(self.CERT, gdir="/g", null_vs_g=None)]
        want = ["FAIL-bad-start-exit", "FAIL-null-vs-g", "FAIL-bad-null-vs-g",
                "FAIL-no-null-vs-g"]
        rc, lines = self._recheck(self.CERT, *bads)
        self.assertEqual(rc, 1)
        self.assertIn("KC_X_PYCHECK=FAIL", lines)
        self.assertIn("KC_X_PYCHECK_AGREE=1", lines)
        self.assertIn("KC_X_PYCHECK_FAILED=4", lines)
        rows = {l.split()[0][len("KC_X_PYCHECK_ROW="):]: l.split()[1]
                for l in lines if l.startswith("KC_X_PYCHECK_ROW=")}
        self.assertEqual(rows.get("cert_00.json"), "CHECKED-AGREE")
        for i, tok in enumerate(want, start=1):
            self.assertEqual(rows.get("cert_%02d.json" % i), tok)

    def test_a_refused_run_is_reported_but_never_counts_as_a_check(self):
        # posyang0's certificate: g_invariant=false, no value. On its own that is ERROR, not
        # PASS -- a run that re-checked nothing must never read as agreement.
        refused = {"type": "roae-kc-extremal-certificate", "version": 1,
                   "functional": "posyang0", "direction": "max", "n": 9, "start_exit": 0,
                   "g_invariant": False, "witness": None}
        rc, lines = self._recheck(refused)
        self.assertEqual(rc, 2)
        self.assertIn("KC_X_PYCHECK=ERROR", lines)
        self.assertIn("KC_X_PYCHECK_REFUSED=1", lines)
        # Beside a real one it is reported and the real one still decides.
        rc, lines = self._recheck(self.CERT, refused)
        self.assertEqual(rc, 0)
        self.assertIn("KC_X_PYCHECK=PASS", lines)
        self.assertIn("KC_X_PYCHECK_CHECKED=1", lines)
        self.assertIn("KC_X_PYCHECK_REFUSED=1", lines)

    def test_an_unreadable_certificate_is_an_error_not_a_pass(self):
        rc, lines = self._recheck("{ this is not json")
        self.assertEqual(rc, 2)
        self.assertIn("KC_X_PYCHECK=ERROR", lines)

    def test_no_certificates_at_all_is_an_error(self):
        r = subprocess.run([sys.executable, "solve.py", "--kc-x-recheck"],
                           capture_output=True, text=True, timeout=300)
        self.assertNotEqual(r.returncode, 0,
                            "--kc-x-recheck with no arguments must refuse, not report PASS")
        self.assertNotIn("KC_X_PYCHECK=PASS",
                         [l.rstrip() for l in (r.stdout + "\n" + r.stderr).splitlines()])


class TestKcExtremalRecheckKillsACoordinatedCMutant(unittest.TestCase):
    """The two-language check earns its name: it kills a mutant the whole C gate survives.

    MEASURED 2026-09-10, and this is the argument for landing the evaluator rather than
    retiring the rule. solve.c already carries an in-language reference (`kc_xs_ref_w`, K3R/K4R),
    which catches a drifted registry weight. It cannot catch a weight that drifts CONSISTENTLY
    in both C implementations -- a redefinition of the functional, with the in-language
    reference updated to match, which is precisely what a well-meaning edit looks like. This
    class builds that mutant (`popcount(exit)` -> `popcount(exit) + 1` at BOTH C sites),
    confirms `--kc-extremal-selftest` still reports PASS, and requires solve.py to say FAIL.

    Independence of DERIVATION, not of invocation: solve.py's formula comes from the registry's
    documented description of the row, so a coordinated edit of both C sites does not move it.

    The mutant is built in a temp dir from a COPY of solve.c; no tracked file is touched. A
    build failure is a test FAILURE, never a skip."""

    MUT = [
        ('    (void)p; (void)step; (void)last; (void)entry;\n'
         '    return __builtin_popcount((unsigned)exitx);\n',
         '    (void)p; (void)step; (void)last; (void)entry;\n'
         '    return __builtin_popcount((unsigned)exitx) + 1;\n'),
        ('    if (strcmp(name, "yangcount") == 0)   { *w = __builtin_popcount((unsigned)exitx); return 0; }\n',
         '    if (strcmp(name, "yangcount") == 0)   { *w = __builtin_popcount((unsigned)exitx) + 1; return 0; }\n'),
    ]

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="kcxmut_")
        with open(os.environ.get("ROAE_TESTS_SOLVE_SRC", "solve.c"), encoding="utf-8") as fh:
            src = fh.read()
        cls.sites_ok = all(src.count(a) == 1 for a, _ in cls.MUT)
        for a, b in cls.MUT:
            src = src.replace(a, b)
        msrc = os.path.join(cls.tmp, "solve_mutant.c")
        with open(msrc, "w", encoding="utf-8") as fh:
            fh.write(src)
        cls.sbin = os.path.join(cls.tmp, "solve_mutant")
        r = subprocess.run(["gcc", "-O1", "-pthread", "-fopenmp", "-o", cls.sbin, msrc,
                            "-lm", "-lz"], capture_output=True, text=True)
        cls.build_ok = (r.returncode == 0 and os.path.exists(cls.sbin))
        cls.build_err = f"gcc rc {r.returncode}: " + r.stderr[-2000:]

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def setUp(self):
        if not self.sites_ok:
            self.fail("the mutation sites no longer occur exactly once in solve.c; this "
                      "demonstration measured nothing and must not read as agreement")
        if not self.build_ok:
            self.fail("the mutant did not build, so nothing was verified: " + self.build_err)

    def test_the_c_gate_survives_the_mutant_but_solve_py_kills_it(self):
        d = os.path.join(self.tmp, "run")
        fdir, gdir = os.path.join(d, "f"), os.path.join(d, "g")
        os.makedirs(fdir); os.makedirs(gdir)
        for flag, out in (("--kc-build", fdir), ("--kc-g-build", gdir)):
            r = subprocess.run([self.sbin, flag, out, "--f1-pairs", "9"],
                               capture_output=True, text=True, timeout=900)
            self.assertEqual(r.returncode, 0, f"{flag} failed: {r.stderr[-800:]}")

        # 1. The C side's own exhaustive n=9 gate does NOT see this.
        g = subprocess.run([self.sbin, "--kc-extremal-selftest"],
                           capture_output=True, text=True, timeout=900)
        self.assertIn("KC_EXTREMAL_SELFTEST=PASS",
                      [l.rstrip() for l in (g.stdout + "\n" + g.stderr).splitlines()],
                      "the coordinated mutant was expected to survive the C gate; if it no "
                      "longer does, this demonstration needs a new mutant, not deleting")

        # 2. The mutant publishes 39 where the registry's documented formula gives 30.
        cert = os.path.join(d, "y.json")
        r = subprocess.run([self.sbin, "--kc-extremal", "yangcount", fdir, "max",
                            "--kc-witness", "--kc-json", cert],
                           capture_output=True, text=True, timeout=900)
        self.assertEqual(r.returncode, 0)
        self.assertTrue(any(l.startswith("extreme_value=39\t") for l in r.stdout.splitlines()),
                        "expected the mutant to publish extreme_value=39; got:\n" + r.stdout)

        # 3. The second language says no.
        p = subprocess.run([sys.executable, "solve.py", "--kc-x-recheck", cert],
                           capture_output=True, text=True, timeout=300)
        lines = [l.rstrip() for l in (p.stdout + "\n" + p.stderr).splitlines()]
        self.assertEqual(p.returncode, 1)
        self.assertIn("KC_X_PYCHECK=FAIL", lines)
        self.assertTrue(any("CHECKED-DISAGREE" in l and "phi_py=30" in l
                            and "extreme_value=39" in l for l in lines),
                        "expected phi_py=30 against extreme_value=39; got:\n" + "\n".join(lines))


class TestW0DNodeMappingCertificateIsUsedQ772(unittest.TestCase):
    """Q-772: the W0-D certificate is USED, not merely present (the Q-768 ruling, R1-R8).

    WHAT WENT WRONG, FOUR ROUNDS RUNNING. `_xa_node_mapping_cert_defect` guarded the XA-c/d
    pricing path with a PERMISSION BIT. It searched the JSON for `solve_node_limit_mapping`,
    returned None ("authorised") for a string starting "CERTIFIED:" with text after it or for
    an object with "claimed": true, and `atlas_emit_xa` then priced the t-unit count ITSELF as
    production-DFS nodes. Round one never opened the file; round two (RCQ02 F2) let `false`,
    `null`, `""` and "FAIL" through; round three (RCQ04) let the bare prefix through; and the
    RCQ04 adjudication MEASURED that no grammar could close it:

        "CERTIFIED: no mapping has been established"   -> authorised
        {"claimed": true, "mapping": "unrelated"}      -> authorised

    because nothing the certificate said reached the arithmetic. The fix, per the ruling, is a
    fixed schema whose `mapping.nodes_per_t_unit` (an exact "p/q") MULTIPLIES every priced row
    and whose `mapping.kind` limits which call a row may make. Each test names the leg of the
    ruling it implements and the mutant it kills; `scripts/q433_xa_cert_gate.sh` carries the
    mutants themselves. THE POSITIVE ARM IS LOAD-BEARING: a loader that refuses everything is a
    permanent FALSE dressed as rigour, so a full-schema certificate must still PRICE.
    """

    PENDING_TEXT = (
        "**PENDING** -- pricing t-units as production-DFS nodes needs a W0-D t-unit ->\n"
        "`SOLVE_NODE_LIMIT` mapping certificate, supplied with `--xa-node-mapping-cert`.\n"
        "A t-unit is one valid oriented SUPER prefix; `SOLVE_NODE_LIMIT` counts\n"
        "production-DFS nodes, and that DFS prunes on one combined kw_dist budget and\n"
        "applies C3 only as a filter at the full-walk leaf. Nothing here certifies the\n"
        "map, so no EXHAUSTIBLE/INFEASIBLE call is made. The t-unit column above is\n"
        "exact and stands on its own.\n")

    def setUp(self):
        self.S = _load("solve")
        self.d = tempfile.mkdtemp(prefix="q772_")
        self.addCleanup(shutil.rmtree, self.d, True)

    @staticmethod
    def cert_doc(kind="exact", F="1/1", residual=0, **top):
        doc = {"type": "roae-w0d-node-mapping-certificate", "version": 1,
               "mapping": {"kind": kind, "nodes_per_t_unit": F, "residual": residual,
                           "formula": "TEST: production_nodes(b) = F * t(b)",
                           "law": "TEST: fixture for tests.py Q-772"},
               "measured": {"n": [9, 13], "per_n": [],
                            "verdict_line": "W0-D PASS mapping: TEST"},
               "provenance": {"engine_git": "FIXTURE:tests.py", "engine_source_sha": "FIXTURE",
                              "host_fingerprint": "FIXTURE", "produced": "FIXTURE"},
               "semantics": "certificate-not-proof"}
        doc.update(top)
        return doc

    def write(self, name, obj):
        import json
        p = os.path.join(self.d, name)
        with open(p, "w", encoding="utf-8") as fh:
            fh.write(obj if isinstance(obj, str) else json.dumps(obj))
        return p

    def emit(self, cert, t_units=("10",), budget="1", nps="1000", uph="1"):
        """The REAL emitter over a small atlas; returns (TR12_XA_CD value, xa_verdict.md)."""
        S = self.S
        A = {"n": 9, "N_total": str(24 * len(t_units)), "layers": [{"flow": "24"}],
             "branch_atlas": [{"global_pair": i + 1, "entry": 2, "exit": 0, "solutions": "24",
                               "walks": 24, "prefixes_t_units": t}
                              for i, t in enumerate(t_units)]}
        cost = {"nodes_per_sec": S._ExactAnchor(nps), "usd_per_hour": S._ExactAnchor(uph),
                "budget_usd": S._ExactAnchor(budget), "hedge": S._ExactAnchor("1"),
                "work_factor": S._ExactAnchor("1"), "note": "tests.py Q-772",
                "node_mapping_cert": cert}
        out = tempfile.mkdtemp(dir=self.d)
        _tsv, md, verdict, _g = S.atlas_emit_xa(A, out, cost=cost, atlas_path="q772.json")
        with open(md, encoding="utf-8") as fh:
            return verdict, fh.read()

    @staticmethod
    def priced_rows(md):
        """{t-units: (exact $ Fraction, verdict)} parsed from the EXACT column, never the %.4g."""
        from fractions import Fraction
        out = {}
        for line in md.splitlines():
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if len(cells) == 9 and cells[0].isdigit():
                out[cells[2]] = (Fraction(cells[6]), cells[7])
        return out

    def assertRefused(self, cert, label):
        verdict, md = self.emit(cert)
        self.assertEqual(verdict, "PENDING:W0-D-node-mapping", label)
        self.assertNotRegex(md, r"(?m)^\|.*(EXHAUSTIBLE|INFEASIBLE)", label)
        self.assertIn("The certificate supplied was REFUSED: ", md, label)
        return md

    # ---- R1: the RCQ04 inputs, in the legacy key, are REFUSED (kills the permission bit) ----
    def test_R1_the_rcq04_permission_bit_inputs_are_refused(self):
        for i, val in enumerate(["CERTIFIED: no mapping has been established",
                                 {"claimed": True, "mapping": "unrelated"},
                                 # and every value the three earlier rounds were about
                                 "CERTIFIED: 1 t-unit == 1 SOLVE_NODE_LIMIT node", "CERTIFIED:",
                                 None, False, "", "FAIL"]):
            with self.subTest(value=val):
                for shape in ({"solve_node_limit_mapping": val},
                              {"node_convention": {"solve_node_limit_mapping": val}}):
                    md = self.assertRefused(self.write("r1_%d.json" % i, shape), repr(val))
                    self.assertIn("nothing to price with", md)

    # ---- R2: the factor MULTIPLIES every row (kills m1, `* 1`) --------------------------------
    def test_R2_the_factor_scales_every_exact_cost_and_can_flip_a_row(self):
        from fractions import Fraction
        # rate 1000 nodes/s, $1/h: t = 2,400,000 costs exactly $2/3 at F = 1, exactly $1 at 3/2
        # (ON the budget: EXHAUSTIBLE), and t = 3,000,000 costs $5/6 at F = 1 (EXHAUSTIBLE) and
        # $5/4 at F = 3/2 (INFEASIBLE). Anchors identical across the two runs.
        t = ("2400000", "3000000")
        v1, md1 = self.emit(self.write("f1.json", self.cert_doc(F="1/1")), t_units=t)
        v2, md2 = self.emit(self.write("f32.json", self.cert_doc(F="3/2")), t_units=t)
        r1, r2 = self.priced_rows(md1), self.priced_rows(md2)
        self.assertEqual(sorted(r1), sorted(t), md1)
        self.assertEqual(sorted(r2), sorted(t), md2)
        for k in t:
            self.assertEqual(r2[k][0], Fraction(3, 2) * r1[k][0], k)
        self.assertEqual(r1["2400000"][0], Fraction(2, 3))
        self.assertEqual(r2["2400000"], (Fraction(1), "EXHAUSTIBLE"))
        self.assertEqual(r1["3000000"], (Fraction(5, 6), "EXHAUSTIBLE"))
        self.assertEqual(r2["3000000"], (Fraction(5, 4), "INFEASIBLE"))
        self.assertIn("| 1 | 2 | 3000000 | 4500000 |", md2)   # the nodes column is t x F
        self.assertEqual((v1, v2), ("PASS", "PASS"))

    # ---- R3: the kind limits the call (kills m2, every kind treated as exact) -----------------
    def test_R3_a_one_sided_certificate_never_makes_the_call_it_cannot_support(self):
        t = ("600000", "6000000")            # $1/6 (in budget) and $5/3 (over), F = 1
        v, md = self.emit(self.write("ub.json", self.cert_doc(kind="upper-bound", residual=5)),
                          t_units=t)
        rows = self.priced_rows(md)
        self.assertEqual(rows["600000"][1], "EXHAUSTIBLE")
        self.assertEqual(rows["6000000"][1], "UNDECIDED:upper-bound")
        self.assertNotRegex(md, r"(?m)^\|.*INFEASIBLE")
        self.assertEqual(v, "ONE-SIDED:upper-bound")
        v, md = self.emit(self.write("lb.json", self.cert_doc(kind="lower-bound", residual=-5)),
                          t_units=t)
        rows = self.priced_rows(md)
        self.assertEqual(rows["600000"][1], "UNDECIDED:lower-bound")
        self.assertEqual(rows["6000000"][1], "INFEASIBLE")
        self.assertNotRegex(md, r"(?m)^\|.*EXHAUSTIBLE")
        self.assertIn("Call: the argmin branch is **UNDECIDED:lower-bound**", md)
        self.assertEqual(v, "ONE-SIDED:lower-bound")
        # the exact kind is the only one that reads PASS
        v, _md = self.emit(self.write("ex.json", self.cert_doc()), t_units=t)
        self.assertEqual(v, "PASS")

    # ---- R4: a malformed mapping is a REFUSAL with a reason, never an exception (kills m3) ----
    def test_R4_a_malformed_mapping_is_refused_with_a_reason(self):
        bad = {"F_number": dict(F=1.5), "F_int_number": dict(F=1), "F_zero": dict(F="0/1"),
               "F_negative": dict(F="-3/2"), "F_text": dict(F="abc"), "F_div0": dict(F="1/0"),
               "F_decimal": dict(F="1.5"), "F_bare_int": dict(F="3"), "F_null": dict(F=None),
               "exact_with_residual": dict(residual=7), "kind_sideways": dict(kind="sideways"),
               "residual_float": dict(residual=0.0), "residual_bool": dict(residual=False)}
        for name, kw in sorted(bad.items()):
            with self.subTest(case=name):
                # The legacy claim rides along so the PRE-Q-772 consumer would have priced it:
                # this leg is red there on behaviour, not merely on a missing function.
                doc = self.cert_doc(solve_node_limit_mapping="CERTIFIED: legacy claim", **kw)
                p = self.write("r4_%s.json" % name, doc)
                md = self.assertRefused(p, name)
                m, why = self.S._xa_node_mapping_load(p)
                self.assertIsNone(m, name)
                self.assertIsInstance(why, str)
                self.assertIn(why, md)
        for key in ("kind", "nodes_per_t_unit", "residual", "formula", "law"):
            with self.subTest(missing=key):
                doc = self.cert_doc(solve_node_limit_mapping="CERTIFIED: legacy claim")
                del doc["mapping"][key]
                md = self.assertRefused(self.write("r4_no_%s.json" % key, doc), key)
                self.assertIn("lacks `%s`" % key, md)
        for name, top in (("wrong_type", {"type": "roae-something-else"}),
                          ("wrong_version", {"version": 2}), ("version_str", {"version": "1"}),
                          ("no_provenance", {"provenance": {}}), ("no_measured", {"measured": 3})):
            with self.subTest(case=name):
                doc = self.cert_doc(solve_node_limit_mapping="CERTIFIED: legacy claim", **top)
                self.assertRefused(self.write("r4_%s.json" % name, doc), name)

    # ---- R5: refused by TYPE; no recursive search; no RecursionError (kills m4) --------------
    def test_R5_kc_t_cert_output_nested_mapping_and_deep_nesting(self):
        import json
        # (a) the REAL `solve --kc-t-cert` output, refused by its type. A build failure is a
        # FAILURE here, never a skip.
        sbin = os.path.join(self.d, "solve_q772")
        src = os.environ.get("ROAE_TESTS_SOLVE_SRC", "solve.c")
        r = subprocess.run(["gcc", "-O1", "-pthread", "-fopenmp", "-o", sbin, src, "-lm", "-lz"],
                           capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, "gcc: " + r.stderr[-2000:])
        kct = os.path.join(self.d, "kct.json")
        r = subprocess.run([sbin, "--kc-t-cert", kct], capture_output=True, text=True, cwd=self.d)
        self.assertEqual(r.returncode, 0, r.stdout[-2000:] + r.stderr[-2000:])
        with open(kct, encoding="utf-8") as fh:
            self.assertEqual(json.load(fh)["type"], "roae-kc-t-node-convention-certificate")
        md = self.assertRefused(kct, "kc-t-cert")
        self.assertIn("Refused by type", md)
        # (b) a valid mapping, but NESTED: only the top level is this schema.
        doc = self.cert_doc()
        doc["node_convention"] = {"mapping": doc.pop("mapping"),
                                  "solve_node_limit_mapping": "CERTIFIED: nested"}
        md = self.assertRefused(self.write("nested.json", doc), "nested")
        self.assertIn("no top-level `mapping` object", md)
        # (c) a 100,000-deep array: a refusal, not a RecursionError
        p = self.write("deep.json", "[" * 100000 + "]" * 100000)
        try:
            m, why = self.S._xa_node_mapping_load(p)
        except RecursionError:
            self.fail("RecursionError escaped the loader: a crash, not a refusal")
        self.assertIsNone(m)
        self.assertIn("nested too deeply", why)
        # (d) a valid certificate with a deep (but parseable) array BESIDE its mapping still loads
        doc = self.cert_doc()
        p = self.write("deep_ok.json", json.dumps(doc)[:-1] + ', "pad": ' + "[" * 400
                       + "]" * 400 + "}")
        m, why = self.S._xa_node_mapping_load(p)
        self.assertIsNone(why)
        self.assertEqual(str(m["factor"]), "1")

    # ---- R6: the old "good" certificate flips; a full-schema one is ACCEPTED and PRICED -------
    def test_R6_the_string_only_certificate_flips_and_the_positive_arm_prices(self):
        old_good = {"node_convention": {"solve_node_limit_mapping":
                    "CERTIFIED: 1 t-unit == 1 SOLVE_NODE_LIMIT node, certified by the W0-D "
                    "worker run"}}
        self.assertRefused(self.write("old_good.json", old_good), "old L1")
        p = self.write("new_good.json", self.cert_doc())
        m, why = self.S._xa_node_mapping_load(p)
        self.assertIsNone(why)
        self.assertEqual((m["kind"], str(m["factor"]), m["residual"]), ("exact", "1", 0))
        v, md = self.emit(p)
        self.assertEqual(v, "PASS")
        self.assertRegex(md, r"(?m)^\| 0 \| 1 \| 10 \| 10 \|.*\| EXHAUSTIBLE \|")

    # ---- R7: the xa_exact_verdict_gate fixture is full-schema and names itself ----------------
    def test_R7_the_arithmetic_gate_still_reaches_the_priced_branch(self):
        with open(os.path.join("scripts", "xa_exact_verdict_gate.sh"), encoding="utf-8") as fh:
            body = fh.read()
        self.assertIn('"type": "roae-w0d-node-mapping-certificate"', body)
        self.assertIn('"engine_git": "FIXTURE:xa_exact_verdict_gate.sh"', body)
        r = subprocess.run(["bash", "scripts/xa_exact_verdict_gate.sh"], capture_output=True,
                           text=True, timeout=300)
        lines = r.stdout.splitlines()
        self.assertIn("XA_EXACT_VERDICT=OK", lines, r.stdout[-3000:] + r.stderr[-2000:])
        self.assertEqual(r.returncode, 0)
        # and the echo block beside the priced table carries the FIXTURE: provenance
        v, md = self.emit(self.write("fixture_like.json", self.cert_doc()))
        self.assertIn("- provenance.engine_git: `FIXTURE:tests.py`", md)
        self.assertIn("- kind: `exact`; F = nodes_per_t_unit = `1`; residual = 0", md)
        self.assertIn("production-DFS nodes = t-units x F, F = 1 (exact), certificate "
                      "fixture_like.json sha256 ", md)

    # ---- R8: a real run (no W0-D certificate) keeps the historical PENDING, byte for byte ------
    # ⚠ 2026-09-25, Q-787: PENDING_TEXT's fourth line used to describe SOLVE_NODE_LIMIT as counting
    # production-DFS nodes under a C3 prune. Production tests C3 only at the step-32 leaf, so that
    # clause was false and was corrected in solve.py atlas_emit_xa. R8 still pins the paragraph byte for byte; only the
    # wording it pins moved. No n9 golden carries the paragraph (c_consumer.txt does not).
    def test_R8_real_runs_stay_pending_with_the_historical_wording(self):
        with open(os.path.join("scripts", "tr12_expected", "n9", "c_consumer.txt"),
                  encoding="utf-8") as fh:
            self.assertIn("TR12_XA_CD=PENDING:W0-D-node-mapping", fh.read().splitlines())
        v, md = self.emit(None)
        self.assertEqual(v, "PENDING:W0-D-node-mapping")
        self.assertTrue(md.endswith("## Exhaustibility (XA-c/d)\n\n" + self.PENDING_TEXT), md)
        self.assertNotIn("C3 pruning", md)   # Q-787: the retired clause must not come back
        # The certificate a real operator could hold today -- the legacy sentence, or the
        # `--kc-t-cert` convention certificate -- is refused, and the historical wording is
        # still emitted BYTE-IDENTICAL, with only the refusal line after it.
        for name, doc, why in (
                ("legacy", {"solve_node_limit_mapping": "CERTIFIED: W0-D run done"},
                 "nothing to price with"),
                ("kct_shape", {"type": "roae-kc-t-node-convention-certificate", "version": 1,
                               "convention": {"solve_node_limit_mapping": "NOT CLAIMED HERE"}},
                 "Refused by type")):
            with self.subTest(case=name):
                v, md = self.emit(self.write("r8_%s.json" % name, doc))
                self.assertEqual(v, "PENDING:W0-D-node-mapping")
                tail = md.split("## Exhaustibility (XA-c/d)\n\n", 1)[1]
                self.assertTrue(tail.startswith(self.PENDING_TEXT
                                                + "\nThe certificate supplied was REFUSED: "),
                                tail)
                self.assertIn(why, tail)


class TestQ3ReaderChecksTheRootTransition(unittest.TestCase):
    """The FIRST shell must be checked too. It was not, and a p > 1 shipped PASS.

    `atlas_q3_reader_check` seeded `prev_g = None`, so every `prev_g is not None` guard skipped
    the root transition and the first row's shell size was compared to nothing. RCQ04 finding 3
    (2026-09-10, MEASURED): a trace whose first shell GREW past the whole space -- g1 = 26113
    against N = 26112 -- published p = 1.0000382965686275 and bits = -0.000055 with
    TR12_Q3_READER=PASS and the selftest 34/34. A probability above one and a negative
    information content, both signed off, because the only unguarded step was the first.

    Seeding `prev_g = N` states the real precondition: the root shell IS the whole space.
    """

    def _reader(self, g1, n_total=26112):
        import tempfile, os
        mod = _load("solve")
        d = tempfile.mkdtemp()
        path = os.path.join(d, "q3.tsv")
        # bits is display-only here; give each row its exact log2 so only the shell rule is
        # under test and the bits leg cannot mask the result.
        import math
        # 🔴 p MUST equal g/g_parent on every row. RCQ04 finding 4 (landed 2026-09-10) added a
        # cross-multiplication binding the published probability to the published shells, and this
        # fixture predates it: it used p = 1/1 against non-matching shells, so the new leg fired on
        # it and only the "grew" filter below kept the assertions meaningful. A fixture that trips a
        # check it is not testing is a fixture that will one day mask the check it IS testing.
        rows = [("1", "1", str(g1), str(n_total), "%.6f" % 0.0, str(g1), str(n_total)),
                ("2", "2", "1", str(g1), "%.6f" % math.log2(g1), "1", str(g1))]
        with open(path, "w", encoding="utf-8") as fh:
            fh.write("step\tpair\tp_num\tp_den\tbits\tg\tg_parent\tf\talts\n")
            for r in rows:
                fh.write("\t".join(r) + "\t1\t1\n")
        return mod.atlas_q3_reader_check(path, n_total)

    def test_a_first_shell_larger_than_the_space_is_refused(self):
        fails = self._reader(26113)
        self.assertTrue(any("step 1" in f and "grew" in f for f in fails),
                        "the root transition must be checked; got: %r" % fails)

    def test_a_first_shell_equal_to_the_space_is_accepted(self):
        self.assertEqual([], [f for f in self._reader(26112) if "grew" in f])


class TestQ3ReaderBindsTheProbabilityChainToTheCountChain(unittest.TestCase):
    """The p column a reader multiplies must BE the ratio of the g shells printed beside it.

    RCQ04 finding 4 (2026-09-10, ACCEPTED by execution; the binding was absent at 34933bed too,
    so it never existed rather than regressed).  `atlas_q3_reader_check` checked the two chains
    SEPARATELY -- prod(p_i) == 1/N exactly, and the g column non-increasing and telescoping --
    and nothing tied a single row's p to that same row's g/g_parent.  A COMPENSATED pair of
    errors therefore survives the product check by construction.  MEASURED on the real n=9
    profile from `--kc-profile ... --kc-tsv`: halve p at step 1, double it at step 2, recompute
    the display-only `bits` to match and leave g/g_parent untouched --

        reader        -> []                       (no failures)
        atlas_queries -> TR12_Q3=PASS TR12_Q3_READER=PASS, rc 0
        selftest      -> ATLAS_CONSUMER=PASS, 34 gate(s) run, 0 failure(s)

    with step 1 publishing p = 1184/26112 beside g/g_parent = 2368/26112.  Multiply the p column
    and divide the g column and you get different answers; both were attested.

    The invariant is exact and free: p_num == g and p_den == g_parent on every row of the real
    profile AND of the committed golden.  It is checked by cross-multiplication so an
    unreduced-but-equal ratio is still accepted -- the claim is that p IS the shells' ratio, not
    that the producer printed it in lowest terms.
    """

    N = 26112
    # the real n=9 descent (scripts/tr12_expected/n9/a2_q3_profile.txt, and reproduced here from
    # `solve --kc-profile f g <walk> --kc-tsv`): the shell sizes, root first.
    G = [2368, 456, 160, 32, 8, 4, 4, 1, 1]

    def _write(self, rows):
        import math
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d, True)
        path = os.path.join(d, "q3.tsv")
        with open(path, "w", encoding="utf-8") as fh:
            fh.write("step\tp_num\tp_den\tbits\tg\tg_parent\tf\talts\n")
            for step, (pn, pd, g, gp) in enumerate(rows, 1):
                fh.write("%d\t%d\t%d\t%.6f\t%d\t%d\t1\t1\n"
                         % (step, pn, pd, math.log2(pd) - math.log2(pn), g, gp))
        return path

    def _chain(self):
        """The honest trace: every row's p IS its own g/g_parent."""
        out, parent = [], self.N
        for g in self.G:
            out.append((g, parent, g, parent))
            parent = g
        return out

    def test_the_real_descent_is_accepted(self):
        # POSITIVE CONTROL. A check that refuses the producer is not a fix.
        mod = _load("solve")
        self.assertEqual([], mod.atlas_q3_reader_check(self._write(self._chain()), self.N))

    def test_the_committed_n9_golden_is_accepted(self):
        # SECOND POSITIVE CONTROL, on a real artifact rather than a reconstruction: the
        # invariant must never be able to false-fail the producer as it stands.
        mod = _load("solve")
        here = os.path.dirname(os.path.abspath(__file__))
        src = os.path.join(here, "scripts", "tr12_expected", "n9", "a2_q3_profile.txt")
        with open(src, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
        head = [i for i, l in enumerate(lines) if l.startswith("step\t")]
        self.assertEqual(1, len(head), "golden no longer carries exactly one TSV header")
        body = []
        for l in lines[head[0] + 1:]:
            if not l[:1].isdigit():
                break
            body.append(l)
        self.assertTrue(body, "golden carries no profile rows")
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d, True)
        path = os.path.join(d, "golden.tsv")
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(lines[head[0]] + "\n" + "\n".join(body) + "\n")
        self.assertEqual([], mod.atlas_q3_reader_check(path, self.N))

    def test_a_compensated_p_chain_is_refused(self):
        # RED. Halve p at step 1 and double it at step 2: the product is untouched, the g
        # column is untouched, and before the binding existed this returned [].
        mod = _load("solve")
        rows = self._chain()
        rows[0] = (rows[0][0] // 2, rows[0][1], rows[0][2], rows[0][3])
        rows[1] = (rows[1][0] * 2, rows[1][1], rows[1][2], rows[1][3])
        fails = mod.atlas_q3_reader_check(self._write(rows), self.N)
        self.assertTrue(any("step 1" in f and "ratio of the shell sizes" in f for f in fails),
                        "step 1's p no longer describes its shells; got %r" % (fails,))
        self.assertTrue(any("step 2" in f and "ratio of the shell sizes" in f for f in fails),
                        "step 2's p no longer describes its shells; got %r" % (fails,))
        # the product leg is still satisfied -- which is exactly why it could not see this.
        self.assertFalse([f for f in fails if f.startswith("prod(")], fails)

    def test_an_unreduced_but_equal_ratio_is_still_accepted(self):
        # The binding is a cross-multiplication, not an equality of the printed integers:
        # the producer is free to print p unreduced without being called wrong.
        mod = _load("solve")
        rows = self._chain()
        rows[0] = (rows[0][0] * 3, rows[0][1] * 3, rows[0][2], rows[0][3])
        self.assertEqual([], [f for f in mod.atlas_q3_reader_check(self._write(rows), self.N)
                              if "ratio of the shell sizes" in f])


class TestA5RequiresACompleteInventoryAndFailsInvalidPairs(unittest.TestCase):
    """A-5 must know the difference between "this pair is invalid" and "we have no data".

    RCQ04 finding 5 (2026-09-10, ACCEPTED by execution).  Two defects, measured on n=31 dicts:

      * `{pair3, pair7, pair11}` alone -- 3 of the 31 free pairs -- passed BOTH checks:
        `atlas_orbit_columns` returned ok=True and `atlas_orbit_membership` returned
        (True, "3 pair(s): equal-column grouping == G48 pair-orbit partition").  The group-size
        multiset was graded against a POOL, so any sub-collection of whole orbits tiled it, and
        a producer that dropped a pair from every layer would have been signed off.
      * `{pair0, pair3, pair7}` returned (None, "pairs outside the 31 free pairs: ['pair0']"),
        and the dispatch renders None as `TR12_A5_ORBIT_MEMBERSHIP=SKIP:no-raw` -- which
        `atlas_failed_verdicts` correctly treats as NOT a failure.  An invalid key was reported
        as missing data.

    `marginal_raw` is emitted SPARSELY (non-zero cells only, per layer), so the inventory is the
    UNION OVER LAYERS, which at n=31 must be exactly pair1..pair31; pair 0 is pinned by C4,
    identically zero, and never emitted.  At reduced n the free-pair subset is a proper subset by
    construction -- the real n=9 atlas's union is nine pairs, three whole orbits -- so the
    completeness rule fires at n=31 only, or it would be a gate with no producer.
    """

    N = 1000000

    def _mod(self):
        return _load("solve")

    def _atlas(self, keys, n=31):
        """An n-layer atlas whose every layer carries the same raw column values."""
        mod = self._mod()
        layers = [{"k": k, "flow": str(self.N),
                   "by_class": {"d%d" % d: "0" for d in mod._ATLAS_CLASSES},
                   "marginal_raw": {p: str(v) for p, v in keys.items()}}
                  for k in range(n)]
        # `tail_checks` is required of every atlas since 2026-09-12 (Codex KCP5 #1,
        # adjudicated by Fable): the producer REPORTED its five F3-rule tail verdicts and
        # no consumer read them, so atlas_load now refuses an atlas whose tail verdict is
        # absent, not-run, inconsistent or FAIL. Same shape as `gates` above, same reason.
        return {"type": mod._ATLAS_TYPE, "n": n, "N_total": str(self.N),
                "space": "a5-inventory-fixture",
                "semantics": "synthetic fixture for the A-5 inventory gate; not a measurement",
                "gates": {"fails": 0},
                "tail_checks": {"vertical_raw_eq_N": "PASS",
                                "digit_cross_table_eq_cls_prefix": "PASS",
                                "kernel_cross_layer_eq": "PASS",
                                "kernel_rev_column_eq": "PASS",
                                "kernel_g_invariance": "PASS", "fails": 0},
                "branch_atlas": [], "layers": layers}

    def _complete_keys(self):
        """All 31 free pairs, one distinct column value per G48 orbit -- the shape a correct
        full-31 field has.  The partition is DERIVED (pair_orbit_partition), never hardcoded."""
        keys = {}
        for oi, members in enumerate(self._mod().pair_orbit_partition()):
            for p in members:
                keys["pair%d" % p] = (oi + 1) * 1000
        return keys

    def test_a_complete_full_31_field_passes_both(self):
        # POSITIVE CONTROL.
        mod = self._mod()
        A = self._atlas(self._complete_keys())
        self.assertEqual(31, len(self._complete_keys()))
        self.assertTrue(mod.atlas_orbit_columns(A)[2], mod.atlas_orbit_columns(A)[3])
        self.assertIs(True, mod.atlas_orbit_membership(A)[0])

    def test_a_reduced_n_field_is_not_asked_for_31_pairs(self):
        # POSITIVE CONTROL. The real n=9 atlas's raw union is exactly these nine pairs (three
        # whole orbits); requiring a full inventory there would refuse the producer's own output.
        mod = self._mod()
        keys = {"pair3": 1, "pair7": 1, "pair11": 1,
                "pair4": 2, "pair6": 2, "pair21": 2,
                "pair13": 3, "pair14": 3, "pair30": 3}
        A = self._atlas(keys, n=9)
        self.assertTrue(mod.atlas_orbit_columns(A)[2], mod.atlas_orbit_columns(A)[3])
        self.assertIs(True, mod.atlas_orbit_membership(A)[0])

    def test_three_pairs_out_of_thirty_one_are_refused_by_both(self):
        # RED. The reviewer's input, verbatim: before the fix both said PASS.
        mod = self._mod()
        A = self._atlas({"pair3": 1, "pair7": 1, "pair11": 1})
        ncol, sizes, ok, detail = mod.atlas_orbit_columns(A)
        self.assertFalse(ok, detail)
        self.assertIn("incomplete full-31 inventory", detail)
        ok_mem, detail_mem = mod.atlas_orbit_membership(A)
        self.assertIs(False, ok_mem, detail_mem)
        self.assertIn("incomplete full-31 inventory", detail_mem)

    def test_one_missing_pair_is_refused(self):
        # RED, the tighter form: a field that is complete but for a single pair. The size
        # multiset alone can still tile the pool, so only an inventory check sees this.
        mod = self._mod()
        keys = self._complete_keys()
        del keys["pair19"]
        ncol, sizes, ok, detail = mod.atlas_orbit_columns(self._atlas(keys))
        self.assertFalse(ok, detail)
        self.assertIn("pair19", detail)
        self.assertIs(False, mod.atlas_orbit_membership(self._atlas(keys))[0])

    def test_an_invalid_pair_is_a_failure_not_missing_data(self):
        # RED. `pair0` is pinned by C4 and identically zero, so it is never legitimately
        # emitted. Before the fix membership returned None, which the dispatch renders as
        # SKIP:no-raw -- an invalid field reported as an absent one.
        mod = self._mod()
        A = self._atlas({"pair0": 5, "pair3": 7, "pair7": 7})
        ok_mem, detail_mem = mod.atlas_orbit_membership(A)
        self.assertIsNotNone(ok_mem, "an invalid pair must not be reported as missing data")
        self.assertIs(False, ok_mem, detail_mem)
        self.assertIn("pair0", detail_mem)

    def test_a_genuinely_empty_field_still_reports_no_data(self):
        # The other side of the same distinction: with NO raw field at all there is nothing to
        # judge, and None (-> SKIP:no-raw) remains the honest answer. A check that answered FAIL
        # here would make every atlas built without --kc-raw red.
        mod = self._mod()
        A = self._atlas({})
        for L in A["layers"]:
            del L["marginal_raw"]
        self.assertIsNone(mod.atlas_orbit_columns(A)[2])
        self.assertIsNone(mod.atlas_orbit_membership(A)[0])

    def test_the_emitted_verdicts_say_FAIL_not_SKIP(self):
        import json
        # RED, end to end through the artifact a reader actually sees. The misclassification
        # only becomes harmful at the dispatch, where None is rendered SKIP:no-raw and
        # atlas_failed_verdicts then (correctly) declines to call it a failure.
        mod = self._mod()
        d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, d, True)
        path = os.path.join(d, "atlas.json")
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(self._atlas({"pair0": 5, "pair3": 7, "pair7": 7}), fh)
        out = os.path.join(d, "out")
        os.makedirs(out)
        R = mod.atlas_queries(path, out, select=["a5"], quiet=True)
        for k in ("TR12_A5_ORBIT_COLUMNS", "TR12_A5_ORBIT_MEMBERSHIP"):
            self.assertTrue(R["verdicts"][k].startswith("FAIL"), R["verdicts"][k])
        self.assertEqual(1, mod.atlas_verdicts_rc(R["verdicts"]))
        # and the complete field still exits 0
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(self._atlas(self._complete_keys()), fh)
        R = mod.atlas_queries(path, out, select=["a5"], quiet=True)
        self.assertEqual("PASS", R["verdicts"]["TR12_A5_ORBIT_COLUMNS"])
        self.assertEqual("PASS", R["verdicts"]["TR12_A5_ORBIT_MEMBERSHIP"])
        self.assertEqual(0, mod.atlas_verdicts_rc(R["verdicts"]))


class TestA2A3TolerancesAreDecidedInExactArithmetic(unittest.TestCase):
    """A published verdict must not depend on which way a double fell.

    RCQ04 finding 6 (2026-09-10, ACCEPTED by execution).  `atlas_a2_slot_check` and
    `atlas_a3_external_check` read `cell / float(N)` and compared the double against a float
    tolerance, in a file whose own `atlas_emit_xa` states the rule they were breaking -- "at the
    boundary a binary64 round trip is enough to reverse the call" -- and decides XA in exact
    rationals for precisely that reason.

    MEASURED: with N = floor((2^192-1)/(48*2000))*48*2000 and slot 32 placed so the deviation is
    EXACTLY the 0.002 tolerance, the shipped A2 returned FAIL on "max deviation 0.0020 (tol
    0.0020)" -- the double came out 0.0020000000000000018.  Both exact readings PASS.  On real
    data the exact deviation would have to land within ~2e-18 of the tolerance for this to
    matter, so this is measure-zero in practice; it is fixed on PRINCIPLE and because it is free.

    The fixtures below are boundary cases by construction: cell and N are integers chosen so the
    deviation is the tolerance to the last bit.  A test that only used comfortable numbers would
    not distinguish the two implementations at all.
    """

    TOL = 2  # thousandths; the checks' default tol=2e-3

    def _mod(self):
        return _load("solve")

    def _n_boundary(self, unit):
        """The largest multiple of `unit` below 2^192 -- big enough that binary64 cannot hold
        cell/N, which is what makes the boundary observable."""
        return ((2 ** 192 - 1) // unit) * unit

    # ---- A2 ---------------------------------------------------------------
    def _a2_atlas(self, slot32_thousandths_of_pct=None, N=None):
        mod = self._mod()
        N = N or self._n_boundary(48 * 2000)
        # slot 32 sits exactly tol ABOVE its published 0.0785; slot 2 sits exactly on 0.0520.
        # Both the slot32 leg and the R-C1c sum leg are then exactly at the tolerance.
        c32 = N * 161 // 2000 if slot32_thousandths_of_pct is None \
            else N * slot32_thousandths_of_pct // 100000
        c2 = N * 13 // 250
        layers = [{"k": k} for k in range(31)]
        layers[0]["marginal_raw"] = {"pair%d" % mod._A2_PAIR: str(c2)}
        layers[30]["marginal_raw"] = {"pair%d" % mod._A2_PAIR: str(c32)}
        return {"n": 31, "N_total": str(N), "layers": layers}, N, c32, c2

    def test_a2_the_fixture_really_is_on_the_boundary(self):
        # The test is only a test if the deviation is EXACTLY the tolerance in exact arithmetic
        # and STRICTLY GREATER in binary64. Assert both, so a future N cannot quietly move off
        # the boundary and leave a green test that measures nothing.
        from fractions import Fraction
        mod = self._mod()
        _, N, c32, c2 = self._a2_atlas()
        self.assertEqual(Fraction(self.TOL, 1000),
                         abs(Fraction(c32, N) - Fraction("0.0785")))
        self.assertEqual(Fraction(self.TOL, 1000),
                         abs(Fraction(c32, N) + Fraction(c2, N) - Fraction("0.1305")))
        self.assertGreater(abs(c32 / float(N) - 0.0785), 2e-3)
        self.assertEqual(0.0020000000000000018, abs(c32 / float(N) - 0.0785))

    def test_a2_accepts_a_deviation_exactly_at_the_tolerance(self):
        # RED. The shipped float implementation returned FAIL here.
        mod = self._mod()
        A = self._a2_atlas()[0]
        st, detail = mod.atlas_a2_slot_check(A)
        self.assertEqual("PASS", st, detail)
        self.assertIn("max deviation 0.0020 (tol 0.0020)", detail)

    def test_a2_still_fails_a_deviation_past_the_tolerance(self):
        # POSITIVE CONTROL: exactness must not be a way of accepting everything. One
        # ten-thousandth beyond the boundary and the verdict is FAIL again.
        mod = self._mod()
        A = self._a2_atlas(slot32_thousandths_of_pct=8060)[0]     # 0.0806 = 0.0785 + 0.0021
        self.assertEqual("FAIL", mod.atlas_a2_slot_check(A)[0])

    def test_a2_still_passes_the_published_values(self):
        # POSITIVE CONTROL on the numbers TR-7 actually prints.
        mod = self._mod()
        N = 1000000
        layers = [{"k": k} for k in range(31)]
        layers[0]["marginal_raw"] = {"pair%d" % mod._A2_PAIR: "52000"}
        layers[30]["marginal_raw"] = {"pair%d" % mod._A2_PAIR: "78500"}
        st, detail = mod.atlas_a2_slot_check({"n": 31, "N_total": str(N), "layers": layers})
        self.assertEqual("PASS", st, detail)
        self.assertIn("A2 slot32=0.0785", detail)

    # ---- A3 ---------------------------------------------------------------
    def _a3_atlas(self, d3_thousandths=654, N=None):
        """The final layer's raw marginal, distributed over the DERIVED wrap classes so the
        class fractions are d3/d1/d5 = 0.654/0.173/0.173 -- d3 exactly tol above its published
        0.652, d1 exactly tol below its 0.175."""
        mod = self._mod()
        N = N or self._n_boundary(1000)
        cmap = mod.atlas_a3_wrap_class_map()
        by = {}
        for p, d in cmap.items():
            by.setdefault(d, []).append(p)
        want = {3: N * d3_thousandths // 1000, 1: N * 173 // 1000}
        want[5] = N - want[3] - want[1]
        last = {}
        for d, tot in want.items():
            grp = sorted(by[d])
            q, r = divmod(tot, len(grp))
            for i, p in enumerate(grp):
                last["pair%d" % p] = str(q + (1 if i < r else 0))
        layers = [{"k": k} for k in range(31)]
        layers[30]["marginal_raw"] = last
        return {"n": 31, "N_total": str(N), "layers": layers}, N, want

    def test_a3_the_fixture_really_is_on_the_boundary(self):
        from fractions import Fraction
        _, N, want = self._a3_atlas()
        self.assertEqual(N, sum(want.values()))
        self.assertEqual(Fraction(self.TOL, 1000), abs(Fraction(want[3], N) - Fraction("0.652")))
        self.assertGreater(abs(want[3] / float(N) - 0.652), 2e-3)

    def test_a3_accepts_a_deviation_exactly_at_the_tolerance(self):
        # RED. Same class as A2: the shipped float implementation said FAIL.
        mod = self._mod()
        st, detail = mod.atlas_a3_external_check(self._a3_atlas()[0])
        self.assertEqual("PASS", st, detail)

    def test_a3_still_fails_a_deviation_past_the_tolerance(self):
        # POSITIVE CONTROL.
        mod = self._mod()
        self.assertEqual("FAIL", mod.atlas_a3_external_check(self._a3_atlas(d3_thousandths=655)[0])[0])

    # ---- the shared helpers ----------------------------------------------
    def test_the_published_references_are_exact_decimals(self):
        # The comparison can only be exact if BOTH sides are. Held as floats, 0.0785 is
        # 0.07850000000000000033..., which is not the number TR-7 prints.
        from fractions import Fraction
        mod = self._mod()
        self.assertEqual(Fraction(157, 2000), mod._A2_SLOT_REFS["slot32"])
        self.assertEqual(Fraction(13, 250), mod._A2_SLOT_REFS["slot2"])
        self.assertEqual(mod._A2_SLOT_REFS["slot32"] + mod._A2_SLOT_REFS["slot2"],
                         mod._A2_SLOT_REFS["rc1c"])
        self.assertEqual(Fraction(163, 250), mod._A3_REFERENCES[3])
        self.assertEqual(Fraction(7, 40), mod._A3_REFERENCES[1])
        self.assertEqual(Fraction(87, 500), mod._A3_REFERENCES[5])

    def test_a_float_tolerance_is_read_as_the_decimal_it_was_typed_as(self):
        from fractions import Fraction
        mod = self._mod()
        self.assertEqual(Fraction(1, 500), mod._atlas_exact_tol(2e-3))
        self.assertEqual(Fraction(1, 500), mod._atlas_exact_tol(Fraction(2, 1000)))
        self.assertNotEqual(Fraction(2e-3), mod._atlas_exact_tol(2e-3))

    def test_four_decimal_rendering_is_exact_and_half_even(self):
        from fractions import Fraction
        mod = self._mod()
        self.assertEqual("0.0785", mod._atlas_frac_4dp(Fraction("0.0785")))
        self.assertEqual("0.0020", mod._atlas_frac_4dp(Fraction(2, 1000)))
        self.assertEqual("1.0000", mod._atlas_frac_4dp(Fraction(1, 1)))
        # a tie: half-even, decided on the rational, not on whichever double it landed in
        self.assertEqual("0.0002", mod._atlas_frac_4dp(Fraction(25, 100000)))
        self.assertEqual("0.0004", mod._atlas_frac_4dp(Fraction(35, 100000)))



class TestKingWenTableAgreesAcrossBothLanguages(unittest.TestCase):
    """The full-31 anchor of TR-12 Q3/EW-1/V4 is King Wen, and it is materialised
    by TWO independent arms in scripts/tr12_repro.sh: solve.py's `_r7_kw()[2:]`
    (preferred) and, when python3 is absent, an awk reassembly of
    `--kc-profile FDIR GDIR KW`, which resolves the literal through solve.c's own
    `KW[64]`.  Nothing compared the two tables, and the reduced-n rehearsal cannot:
    `kc_h_kw_walk` refuses any ladder with n != 31, so the n=9 run takes the
    O3-midpoint `else` branch and neither arm executes.  A divergence would yield a
    62-value walk that is still a MEMBER of the f ladder, so the driver's
    `--kc-member` row would pass and every Q3 number would be published as King
    Wen's for a walk that is not his.  Ladder-free, laptop-runnable, by design.
    """

    def _kw_from_solve_c(self):
        with open("solve.c") as f:
            src = f.read()
        m = re.search(r"static const int KW\[64\]\s*=\s*\{(.*?)\}\s*;", src, re.S)
        self.assertIsNotNone(m, "solve.c no longer declares `static const int KW[64]`")
        body = re.sub(r"/\*.*?\*/", " ", m.group(1), flags=re.S)
        vals = [int(t) for t in body.replace(",", " ").split()]
        return vals

    def test_solve_c_KW_equals_solve_py_r7_kw(self):
        c = self._kw_from_solve_c()
        p = list(solve._r7_kw())
        self.assertEqual(len(c), 64, "solve.c KW[64] did not yield 64 values")
        self.assertEqual(len(p), 64, "solve.py _r7_kw() did not yield 64 values")
        self.assertEqual(c, p,
                         "solve.c KW[64] and solve.py _r7_kw() disagree: "
                         + str([(i, a, b) for i, (a, b) in enumerate(zip(c, p)) if a != b][:8]))

    def test_the_anchor_slice_is_the_31_free_placements(self):
        # tr12_repro.sh drops index 0..1 -- the C4-anchored pair (63,0), slot 0 and
        # not part of the walk -- and passes 2*31 = 62 values.  kc_h_kw_walk reads
        # exactly KW[2*(j+1)] / KW[2*(j+1)+1] for j in 0..30, i.e. the same slice.
        p = list(solve._r7_kw())
        self.assertEqual(p[0:2], [63, 0], "the dropped prefix is not the C4-anchored pair")
        self.assertEqual(len(p[2:]), 62, "the anchor slice is not 2*31 values")

    def test_kc_profile_column_order_matches_the_shell_fallback(self):
        # The awk fallback reads $3,$4 as (entry, exit) from --kc-profile stdout.
        # Reordering the emitter's columns would silently build a DIFFERENT walk.
        with open("solve.c") as f:
            src = "".join(f.read().split())
        header = '"step' + chr(92) + 'tpair' + chr(92) + 'tentry' + chr(92) + 'texit' + chr(92) + 't'
        # TWO sites carry it: the emitter (fprintf) and solve.c's own header-validating
        # reader.  assertIn alone is satisfied by the reader's copy while the EMITTER is
        # reordered -- the assertion would measure the wrong site.  Pin the count.
        self.assertEqual(src.count(header), 2,
                         "--kc-profile's column header is no longer step/pair/entry/exit... "
                         "at BOTH the emitter and solve.c's header-validating reader; "
                         "scripts/tr12_repro.sh's awk fallback reads $3,$4 as entry,exit "
                         "and would silently reassemble a DIFFERENT walk. If a site was "
                         "added deliberately, re-anchor this count rather than relaxing it.")


# ---------------------------------------------------------------------------
# R5 items 1b and 3a (2026-09-11). Landed from the solve.py lane; the local _load
# shim the lane used was dropped in favour of this file's own loader.
# ---------------------------------------------------------------------------

class TestQ6ExtremesIsCheckedOnThePathThatRunsAtFull31(unittest.TestCase):
    """`q6_layer_extremes.tsv` -- argmax/argmin/ratio and the two PUBLISHED KW columns
    (`kw_p`, `kw_class_pct`) -- was re-derived only inside `atlas_selftest`, which refuses
    n > 13 AND reads the brute-force recount, and whose `kw_d >= 0` half is self-labelled
    "full-31 only; unreachable while n <= 13 here".  R5 item 1b, 2026-09-11.  MEASURED before
    the fix: `--atlas-queries --atlas-fault ratio-zero` on the real n=9 atlas printed
    TR12_Q6=PASS:REDUCED-DISTANCE-CLASS and returned rc 0 with every derived ratio reading 0.
    `atlas_q6_extremes_check` is the atlas-sourced twin, wired into `atlas_queries`, so it runs
    at every n."""

    N = 26112

    def _atlas(self, n, layers):
        import json
        d = tempfile.mkdtemp(); self.addCleanup(shutil.rmtree, d, True)
        # tail_checks: required since 2026-09-12 (Codex KCP5 #1, adjudicated by Fable) --
        # atlas_load refuses an atlas whose F3-rule tail verdict is absent or failing.
        A = {"type": "roae-kc-scan-atlas", "n": n, "N_total": str(self.N),
             "branch_atlas": [], "gates": {"fails": 0},
             "tail_checks": {"vertical_raw_eq_N": "PASS",
                             "digit_cross_table_eq_cls_prefix": "PASS",
                             "kernel_cross_layer_eq": "PASS",
                             "kernel_rev_column_eq": "PASS",
                             "kernel_g_invariance": "PASS", "fails": 0},
             "layers": [{"k": k, "flow": str(self.N),
                         "by_class": {("d%d" % d_): str(m) for d_, m in by.items()}}
                        for k, by in enumerate(layers)]}
        p = os.path.join(d, "atlas.json")
        with open(p, "w") as fh:
            json.dump(A, fh)
        return p, d

    def _n9(self):
        # the real n=9 by_class rows (scripts/tr12_expected/n9/c_q6.txt)
        return [{1: 14208, 2: 9216, 3: 0, 4: 2688, 6: 0},
                {1: 5952, 2: 15552, 3: 0, 4: 4608, 6: 0},
                {1: 5952, 2: 15264, 3: 0, 4: 4896, 6: 0},
                {1: 0, 2: 15168, 3: 0, 4: 10944, 6: 0},
                {1: 0, 2: 18528, 3: 0, 4: 7584, 6: 0},
                {1: 0, 2: 18528, 3: 0, 4: 7584, 6: 0},
                {1: 14208, 2: 8640, 3: 0, 4: 3264, 6: 0},
                {1: 5952, 2: 14688, 3: 0, 4: 5472, 6: 0},
                {1: 5952, 2: 14976, 3: 0, 4: 5184, 6: 0}]

    def _run(self, S, path, out, fault=None):
        old = S._ATLAS_FAULT
        S._ATLAS_FAULT = fault
        try:
            return S.atlas_queries(path, out, select=["q6"], quiet=True)
        finally:
            S._ATLAS_FAULT = old

    def test_the_real_n9_table_passes(self):
        # POSITIVE CONTROL: a gate that cannot accept the producer is not a gate.
        S = _load("solve")
        p, d = self._atlas(9, self._n9())
        R = self._run(S, p, os.path.join(d, "q"))
        self.assertEqual("PASS", R["verdicts"]["TR12_Q6_EXTREMES"])
        self.assertEqual(0, S.atlas_verdicts_rc(R["verdicts"]))

    def test_ratio_zero_flips_the_verdict_and_the_exit_code(self):
        # RED. This is the fault the selftest catches at n<=13 and NOTHING caught on the
        # path that runs at 31: every derived ratio reads 0, every integer is right.
        S = _load("solve")
        p, d = self._atlas(9, self._n9())
        R = self._run(S, p, os.path.join(d, "q"), fault="ratio-zero")
        self.assertEqual("FAIL:9-bad-row(s)", R["verdicts"]["TR12_Q6_EXTREMES"])
        self.assertEqual(1, S.atlas_verdicts_rc(R["verdicts"]))

    def test_a_deleted_table_fails_rather_than_skips(self):
        # VERIFIER CLOSURE: the checker must be FALSE when its subject is absent.
        S = _load("solve")
        p, d = self._atlas(9, self._n9())
        out = os.path.join(d, "q")
        self._run(S, p, out)
        os.unlink(os.path.join(out, "scan", "q6_layer_extremes.tsv"))
        A = S.atlas_load(p)
        fails = S.atlas_q6_extremes_check(A, os.path.join(out, "scan"))
        self.assertEqual(1, len(fails))
        self.assertIn("absent", fails[0])

    def test_a_single_corrupted_cell_and_a_dropped_row_are_caught(self):
        S = _load("solve")
        p, d = self._atlas(9, self._n9())
        out = os.path.join(d, "q")
        self._run(S, p, out)
        A = S.atlas_load(p)
        scan = os.path.join(out, "scan")
        tsv = os.path.join(scan, "q6_layer_extremes.tsv")
        with open(tsv) as fh:
            base = fh.read().splitlines()
        for col, tag in ((3, "argmax"), (5, "argmin"), (6, "ratio")):
            rows = list(base)
            cells = rows[1].split("\t")
            cells[col] = "0" if col == 6 else str(int(cells[col]) + 1)
            rows[1] = "\t".join(cells)
            with open(tsv, "w") as fh:
                fh.write("\n".join(rows) + "\n")
            self.assertTrue(S.atlas_q6_extremes_check(A, scan), tag)
        with open(tsv, "w") as fh:
            fh.write("\n".join(base[:5] + base[6:]) + "\n")
        fails = S.atlas_q6_extremes_check(A, scan)
        self.assertTrue(any("not the atlas's" in f for f in fails), fails)

    def test_the_KW_branch_is_reachable_and_red_at_n31(self):
        # The half of the old gate that was self-labelled unreachable.  No n=31 atlas exists
        # yet, so the INPUT here is synthetic; the emitter, the overlay and the checker are the
        # shipped ones, and the point is that the branch executes and fails when corrupted.
        S = _load("solve")
        by = {1: 14208, 2: 9216, 3: 96, 4: 2496, 6: 96}
        self.assertEqual(self.N, sum(by.values()))
        p, d = self._atlas(31, [dict(by) for _ in range(31)])
        out = os.path.join(d, "q")
        R = self._run(S, p, out)
        self.assertEqual("PASS", R["verdicts"]["TR12_Q6_EXTREMES"])
        A = S.atlas_load(p)
        scan = os.path.join(out, "scan")
        tsv = os.path.join(scan, "q6_layer_extremes.tsv")
        with open(tsv) as fh:
            base = fh.read().splitlines()
        hdr = base[0].split("\t")
        self.assertNotEqual("-1", base[1].split("\t")[hdr.index("kw_d")],
                            "the KW overlay is absent, so this test is not exercising it")
        for col, val, needle in ((hdr.index("kw_p"), "0", "kw_p"),
                                 (hdr.index("kw_class_pct"), "1", "kw_class_pct"),
                                 (hdr.index("kw_class_mass"), "14208", "kw_class_mass"),
                                 (hdr.index("kw_d"), "4", "King Wen overlay")):
            rows = list(base)
            cells = rows[1].split("\t"); cells[col] = val
            rows[1] = "\t".join(cells)
            with open(tsv, "w") as fh:
                fh.write("\n".join(rows) + "\n")
            fails = S.atlas_q6_extremes_check(A, scan)
            self.assertTrue(any(needle in f for f in fails), (needle, fails))


class TestQ3ReaderGatesTheFAndAltsColumns(unittest.TestCase):
    """R5 item 3a, 2026-09-11: `f` and `alts` are published Q3 columns and the reader never
    read either.  MEASURED before the fix on the REAL emitted n=9 profile with step 5's f
    rewritten 80 -> 0: `atlas_q3_reader_check` returned [] and TR12_Q3_READER=PASS.  Both
    bounds are structural: the walk's own prefix reaches every state it visits (f >= 1) and
    the step it took is itself an admissible successor (alts >= 1).  `mass_below` is NOT
    bounded with them -- it is legitimately 0 on the committed golden's step 5."""

    N = 26112
    # the real n=9 descent, from scripts/tr12_expected/n9/a2_q3_profile.txt
    ROWS = [(1, 12, 9472, 1, 2368, 26112), (2, 9, 2720, 2, 456, 2368),
            (3, 7, 1072, 8, 160, 456), (4, 5, 96, 40, 32, 160),
            (5, 4, 0, 80, 8, 32), (6, 2, 0, 320, 4, 8),
            (7, 1, 0, 640, 4, 4), (8, 4, 0, 1728, 1, 4),
            (9, 1, 0, 4736, 1, 1)]

    def _write(self, rows):
        import math
        d = tempfile.mkdtemp(); self.addCleanup(shutil.rmtree, d, True)
        p = os.path.join(d, "q3_profile.tsv")
        with open(p, "w") as fh:
            fh.write("step\talts\tmass_below\tf\tg\tg_parent\tp_num\tp_den\tbits\n")
            for step, alts, mb, f, g, gp in rows:
                fh.write("%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%.6f\n"
                         % (step, alts, mb, f, g, gp, g, gp,
                            math.log2(gp) - math.log2(g)))
        return p

    def test_the_real_descent_is_accepted(self):
        # POSITIVE CONTROL, and the reason the bound is >= 1 and not > 1: this artifact
        # bottoms out at f = 1 and at alts = 1.
        S = _load("solve")
        self.assertEqual([], S.atlas_q3_reader_check(self._write(self.ROWS), self.N))
        self.assertIn(1, [r[1] for r in self.ROWS])
        self.assertIn(1, [r[3] for r in self.ROWS])

    def test_a_visited_step_with_f_zero_is_refused(self):
        # RED: R5's f5_to_0 mutant.  0 failures before this landed.
        S = _load("solve")
        rows = [list(r) for r in self.ROWS]; rows[4][3] = 0
        fails = S.atlas_q3_reader_check(self._write(rows), self.N)
        self.assertTrue(any("step 5" in f and "f = 0" in f for f in fails), fails)

    def test_a_visited_step_with_alts_zero_is_refused(self):
        S = _load("solve")
        rows = [list(r) for r in self.ROWS]; rows[6][1] = 0
        fails = S.atlas_q3_reader_check(self._write(rows), self.N)
        self.assertTrue(any("step 7" in f and "alts = 0" in f for f in fails), fails)

    def test_mass_below_zero_is_still_accepted(self):
        # The control that keeps the new bound from spreading to a column where 0 is honest:
        # the committed golden is 0 from step 5 on, and -1 whenever the source is a
        # --kc-profile table, which carries no mass_below column at all.
        S = _load("solve")
        rows = [list(r) for r in self.ROWS]
        for r in rows:
            r[2] = -1
        self.assertEqual([], S.atlas_q3_reader_check(self._write(rows), self.N))

    def test_the_emitter_always_publishes_f_and_alts(self):
        # The f/alts bounds are presence-guarded (the `bits` precedent), so this pins the
        # premise that makes that guard safe: every table that reaches the reader from
        # atlas_queries / atlas_selftest carries both columns.
        S = _load("solve")
        self.assertIn("f", S._Q3_KEEP)
        self.assertIn("alts", S._Q3_KEEP)


class TestClassSwapDetectorFoldedIntoSolvePy(unittest.TestCase):
    """The whole-row class-mass detector, folded out of scripts/ into solve.py on 2026-09-11.

    It shipped as a separate script that morning because solve.py is inside the reproduction
    stamp's SURFACE; that was a cost argument, not a constraint, and it was folded before the
    production run rather than after so no deferred commitment had to survive the run.

    🔴 THE FOLD HAD A REAL DEFECT, caught by execution and pinned here. The first wiring used
    `parser.add_argument("--kc-class-swap-detect", nargs=argparse.REMAINDER)`. argparse ABBREVIATION
    MATCHING makes the detector's own `--atlas` ambiguous against this module's nine `--atlas-*`
    flags, and REMAINDER does not prevent it: the measured result was
    `error: ambiguous option: --atlas could match --atlas-queries, ...` -- a detector unreachable
    through its own documented interface. argv is now split before argparse ever runs."""

    def _det(self, *argv):
        mod = _load("solve")
        import io, contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
            try:
                rc = mod.kc_class_swap_detect_cli(list(argv))
            except SystemExit as e:
                rc = e.code
        return rc, buf.getvalue()

    def test_the_entry_point_exists_under_its_folded_name(self):
        mod = _load("solve")
        self.assertTrue(callable(getattr(mod, "kc_class_swap_detect_cli", None)),
                        "solve.py must expose the folded detector; the inventory cites "
                        "`solve.py --kc-class-swap-detect` as the reproduction path for a "
                        "PUBLISHED limit, and a citation must not outlive its reproducer")

    def test_a_bad_invocation_emits_the_error_token_not_a_bare_traceback(self):
        rc, out = self._det()
        self.assertIn("KC_CLASS_SWAP_DETECT=ERROR", out,
                      "every exit must carry the whole-line token; ERROR is the "
                      "could-not-measure value and is never agreement")
        self.assertEqual(rc, 2)

    def test_the_argv_intercept_precedes_argparse(self):
        """The regression that the fold actually hit: `--atlas` is ambiguous against this
        module's --atlas-* flags under argparse abbreviation matching."""
        src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "solve.py")).read()
        self.assertIn('if "--kc-class-swap-detect" in sys.argv[1:]:', src,
                      "the detector's argv must be split off BEFORE argparse sees it")
        self.assertNotIn('"--kc-class-swap-detect", nargs=argparse.REMAINDER', src,
                         "REMAINDER does not stop abbreviation matching; that wiring made the "
                         "detector unreachable through its own documented interface")

    def test_limits_and_power_travel_with_every_verdict(self):
        """A CLEAN verdict must never be readable as 'no swap': the measured power is weak
        exactly where the documented undetectability limit bites."""
        mod = _load("solve")
        doc = getattr(mod, "_KC_SWAP_DOC", "")
        for phrase in ("23 of 78", "interior"):
            self.assertIn(phrase, doc,
                          "the measured power must travel with the instrument, not live only "
                          "in a document someone may not read")

class TestGrammarSearchPhaseCIsOrderIndependent(unittest.TestCase):
    """Q-646 (2026-09-20): Phase C picked its min-L representative by ARRIVAL ORDER.

    RED BEFORE, measured 2026-09-20 against the pre-cure blob: `_gs_cand_L` depends only
    on the candidate's FORM and `len(atoms)`, so every candidate sharing a (form, domain)
    pair scores an IDENTICAL L -- six in one class all returned 14.701306. The reduction
    compared L with a strict `<`, so the first-arriving candidate won every tie and
    reversing the arrival order moved the representative from index 0 to index 5. On the
    checkpoint side `_ck_ident` recorded `ncand`, a COUNT, while Phase D merged resumed
    rows BY POSITION: fresh-vs-resume under a different order gave common=247
    mismatched=116, with 4 predicates attributed 0/8 against a true 8/8 or 6/8 while every
    identity check PASSED.

    This test asserts its own precondition first: if no exact L tie exists, the scenario
    this pins cannot occur and a green here would be vacuous."""

    @classmethod
    def setUpClass(cls):
        cls.R = _load("roae")

    def _L(self, c):
        return self.R._gs_cand_L(c)

    def test_ties_are_structural_so_this_test_is_not_vacuous(self):
        self.R._GS["t_atoms"] = list(range(37))
        self.R._GS["p_atoms"] = list(range(41))
        cands = [("d1", "T", 0, 0, a) for a in range(6)]
        vals = {round(self._L(c), 9) for c in cands}
        self.assertEqual(len(vals), 1,
                         "precondition: candidates sharing (form, domain) must tie on L; "
                         "without a tie the arrival-order defect cannot arise and this "
                         "class would pass vacuously")

    def test_representative_does_not_depend_on_arrival_order(self):
        self.R._GS["t_atoms"] = list(range(37))
        self.R._GS["p_atoms"] = list(range(41))
        cands = [("d1", "T", 0, 0, a) for a in range(6)]
        self.R._GS["cands"] = cands

        def reduce_shipped(order):
            best = {}
            for idx in order:
                key = ("KW", 5)
                if key not in best:
                    best[key] = idx
                else:
                    cur = best[key]
                    if ((self._L(cands[idx]), idx) < (self._L(cands[cur]), cur)):
                        best[key] = idx
            return best

        fwd = reduce_shipped(list(range(6)))
        rev = reduce_shipped(list(reversed(range(6))))
        self.assertEqual(fwd, rev,
                         "the min-L representative must not depend on which worker "
                         "returned first")
        self.assertEqual(fwd[("KW", 5)], 0,
                         "on an exact L tie the LOWEST candidate index must win, so the "
                         "choice is a property of the candidate set and not of scheduling")


class TestGrammarSearchUsesNoUnorderedPool(unittest.TestCase):
    """Q-646: pin the call sites, not just the algorithm.

    The tie-break above makes Phase C correct even under an unordered pool, but ordered
    yielding is what makes the CHECKPOINT FILE byte-reproducible, which
    PREREG_H1_H3_TEST_2026_07_26.md:249 requires of U2 output. An AST scan pins intent
    rather than wording, the same way TestNoBareAsserts does."""

    def test_roae_py_has_no_unordered_pool_calls(self):
        import ast
        with open("roae.py", encoding="utf-8") as fh:
            tree = ast.parse(fh.read())
        bad = [n.lineno for n in ast.walk(tree)
               if isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute)
               and n.func.attr == "imap_unordered"]
        self.assertEqual(bad, [],
                         "pool.imap_unordered makes worker arrival order observable; "
                         "roae.py must use pool.imap so results and checkpoint rows are "
                         "emitted deterministically")

    def test_checkpoint_identity_pins_which_candidates_not_just_how_many(self):
        with open("roae.py", encoding="utf-8") as fh:
            src = fh.read()
        self.assertIn("cands=_ck_cands", src,
                      "the checkpoint identity must carry a digest of WHICH candidates "
                      "were tested; ncand is a count, and Phase D merges by position")
        self.assertEqual(src.count("cands=_ck_cands"), 2,
                         "the digest must be both WRITTEN into each row and present in "
                         "_ck_ident; emitting it on only one side would reject every row")


class TestFigureLabelsAreVisibleToTextGates(unittest.TestCase):
    """Q-668 (2026-09-20): text baked into a rendered figure is outside every grep gate.

    matplotlib renders labels to glyph paths, so GATE 3, GATE 6 and every retraction scan
    are blind to them: a figure can assert a withdrawn claim while every documentation
    gate reports clean. Measured -- a superseded band label lived in the published PNG and
    SVG for 49 days (CX-55), and `heuristic floor` was never registered in f1 of
    RETRACTED_PHRASES.tsv (f1=0, f3=1), so GATE 6 could not have caught it even in source.

    FIGURE_LABEL_MANIFEST binds each stem to the STATIC label text it renders. It is
    generated from the source and pinned, so the first test below is a DRIFT check rather
    than a discovery: it goes red when a label is edited without updating the manifest.
    The retraction cross-check is the part that is not circular.

    The manifest is read by AST, never by importing the module: viz/report_figures.py
    needs matplotlib, and an absent dependency must not turn a gate into an error."""

    TEXTARG = {"text": 2, "annotate": 0, "set_title": 0,
               "set_xlabel": 0, "set_ylabel": 0, "suptitle": 0}

    @classmethod
    def setUpClass(cls):
        import ast
        with open("viz/report_figures.py", encoding="utf-8") as fh:
            cls.tree = ast.parse(fh.read())
        cls.manifest = cls._const("FIGURE_LABEL_MANIFEST")
        cls.uncovered = cls._const("FIGURE_LABEL_UNCOVERED")

    @classmethod
    def _const(cls, name):
        import ast
        for n in cls.tree.body:
            if isinstance(n, ast.Assign) and any(
                    isinstance(t, ast.Name) and t.id == name for t in n.targets):
                return ast.literal_eval(n.value)
        return None

    @classmethod
    def _measure(cls):
        import ast
        lits, unc = {}, {}
        for fn in [n for n in cls.tree.body
                   if isinstance(n, ast.FunctionDef) and n.name.startswith("fig_")]:
            stem, got, n_unc = None, [], 0
            for c in ast.walk(fn):
                if (isinstance(c, ast.Call) and isinstance(c.func, ast.Name)
                        and c.func.id == "save" and len(c.args) > 1
                        and isinstance(c.args[1], ast.Constant)):
                    stem = c.args[1].value
                if isinstance(c, ast.Call) and isinstance(c.func, ast.Attribute):
                    i = cls.TEXTARG.get(c.func.attr)
                    if i is None or len(c.args) <= i:
                        continue
                    a = c.args[i]
                    if isinstance(a, ast.Constant) and isinstance(a.value, str):
                        got.append(a.value)
                    else:
                        n_unc += 1
            lits[stem] = tuple(sorted(set(got)))
            unc[stem] = n_unc
        return lits, unc

    def test_manifest_matches_what_the_generator_actually_renders(self):
        self.assertIsNotNone(self.manifest, "FIGURE_LABEL_MANIFEST must exist")
        lits, _ = self._measure()
        self.assertEqual({k: tuple(v) for k, v in self.manifest.items()}, lits,
                         "a label was edited in the generator without updating "
                         "FIGURE_LABEL_MANIFEST; the manifest is what the text gates read, "
                         "so drift here makes figure text invisible again")

    def test_uncovered_computed_labels_are_pinned_as_a_ratchet(self):
        self.assertIsNotNone(self.uncovered, "FIGURE_LABEL_UNCOVERED must exist")
        _, unc = self._measure()
        self.assertEqual(dict(self.uncovered), unc,
                         "the count of COMPUTED label sites moved. f-string, concatenated "
                         "and call-built labels exist as no literal and cannot be "
                         "manifested; pinning the count is what stops new uncovered text "
                         "appearing silently")

    def test_no_figure_label_is_a_registered_retracted_phrase(self):
        phrases = _registered_retracted_phrases()
        self.assertTrue(phrases, "the retraction registry must be readable, or this "
                                 "check would pass vacuously")
        bad = [(stem, lab, p) for stem, labs in self.manifest.items() for lab in labs
               for p in phrases if p.lower() in lab.lower()]
        self.assertEqual(bad, [],
                         "a figure renders text that RETRACTED_PHRASES.tsv registers as "
                         "withdrawn; this is the check that did not exist when a "
                         "superseded label survived 49 days in a published figure")


class TestCliHelpDescribesTheCode(unittest.TestCase):
    """The argparse help strings ARE the reader-facing description surface, and GATE 2
    compares flag NAMES only, so a help string can be present and false with every gate
    green. Q-410 surface sweep, 2026-09-21 (Fable lane): four such strings were false when
    executed -- `--atlas-select` listed 7 selectors while the loader accepted 10;
    `--gs-checkpoint` said "only ncand is validated" three fixes after seed/batches/nsamp/
    cands/want were; `--t3-stats`/`--t3-membership` and the runtime `_T3_GEN` block said the
    --kc-* sampler was "NOT on main" two months after it was; `--lookup` promised "or name"
    for a key the tool stopped accepting on 2026-08-27. Every assertion below is derived
    from the code that the description is about, never from a pinned phrase alone."""

    @staticmethod
    def _help_block(prog, flag):
        r = subprocess.run([sys.executable, prog, "--help"], capture_output=True, text=True)
        text = r.stdout
        i = text.find("  " + flag)
        if i < 0:                       # explicit raise, not `assert`: survives -O (Q-373)
            raise AssertionError("%s --help does not list %s" % (prog, flag))
        j = re.search(r"\n  -", text[i + 2:])
        return text[i:i + 2 + j.start()] if j else text[i:]

    def test_atlas_select_help_names_every_selector_the_loader_accepts(self):
        S = _load("solve")
        sel = S._ATLAS_SELECTORS
        self.assertGreaterEqual(len(sel), 10)          # a2/a3/a5 are in the tuple ...
        self.assertTrue({"a2", "a3", "a5"} <= set(sel))
        block = self._help_block("solve.py", "--atlas-select")
        listed = set(re.findall(r"[a-z0-9]+", block.split("comma list of", 1)[1].split("(")[0]))
        self.assertEqual(set(sel) - listed, set(),
                         "--atlas-select help omits selectors the loader accepts: %s"
                         % sorted(set(sel) - listed))

    def test_gs_checkpoint_help_names_every_field_the_loader_validates(self):
        src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "roae.py"),
                   encoding="utf-8").read()
        # The dict literal spans lines and its values contain calls (`len(ridx)`), so match
        # up to its last keyword rather than to the first ')'.
        m = re.search(r"_ck_ident = dict\((.*?cands=\w+)\)", src, re.S)
        self.assertIsNotNone(m, "the checkpoint identity dict must exist for this test to mean anything")
        keys = set(re.findall(r"(\w+)=", m.group(1)))
        keys |= set(re.findall(r'bad\.append\("(\w+)"\)', src))
        self.assertTrue({"seed", "ncand", "cands", "want"} <= keys)   # the fields Q-646 added
        block = self._help_block("roae.py", "--gs-checkpoint")
        missing = sorted(k for k in keys if k not in block)
        self.assertEqual(missing, [], "--gs-checkpoint help does not name validated field(s) %s" % missing)
        self.assertNotIn("only ncand", block)

    def test_t3_descriptions_agree_with_where_the_sampler_lives(self):
        here = os.path.dirname(os.path.abspath(__file__))
        on_main = '"--kc-sample"' in open(os.path.join(here, "solve.c"), encoding="utf-8").read()
        self.assertTrue(on_main, "positive control: this tree's solve.c dispatches --kc-sample")
        V = _load("verify")
        texts = {"_T3_GEN": V._T3_GEN,
                 "--t3-stats": self._help_block("verify.py", "--t3-stats"),
                 "--t3-membership": self._help_block("verify.py", "--t3-membership")}
        for name, t in texts.items():
            self.assertNotIn("NOT on main", t, name)
            self.assertIn("on main", t, name + " must say where the --kc-* sampler lives")

    def test_lookup_accepts_a_label_and_says_what_it_accepts_on_a_miss(self):
        hit = subprocess.run([sys.executable, "roae.py", "--lookup", "Water over Thunder"],
                             capture_output=True, text=True)
        self.assertEqual(hit.returncode, 0)
        self.assertRegex(hit.stdout, r"\b3\b.*Water over Thunder|Water over Thunder.*\b3\b")
        miss = subprocess.run([sys.executable, "roae.py", "--lookup", "Qian"],
                              capture_output=True, text=True)
        self.assertIn("No hexagram found matching 'Qian'.", miss.stdout)   # the documented line
        self.assertIn("Accepted keys:", miss.stdout)
        self.assertIn("trigram-derived label", self._help_block("roae.py", "--lookup"))
        self.assertNotIn("or name", self._help_block("roae.py", "--lookup"))


class TestP2GzipInputIsTheDocumentedInput(unittest.TestCase):
    """Two modes documented against `solutions.bin` behaved differently on its DEFAULT form
    (gzip-framed, `SOLVE_COMPRESS` on), measured 2026-09-21 on the repo sample:
    `compute_stats.json`'s `solutions_bin` -- documented as "the absolute path of the input"
    -- recorded the mkstemp path the wrapper decompressed to (`/tmp/roae_gz_py_XXXX.bin`,
    gone after the run), and `verify.py --check-t5-c3` opened the file raw and printed
    `T5_C3_AGREE=FAIL bad magic` on an artifact every other mode accepts. Both fixtures here
    are built by the tools themselves from King Wen, so no data file is needed; both tests
    skip when pyarrow is absent because the modes under test cannot run without it."""

    @classmethod
    def setUpClass(cls):
        try:
            import pyarrow  # noqa: F401
        except ImportError:
            raise unittest.SkipTest("pyarrow absent: --compute-stats and --check-t5-c3 need it")
        cls.tmp = tempfile.mkdtemp(prefix="p2gz_")
        S = _load("solve")
        kw = ",".join(str(h) for h in S.binary_hexagrams)
        stream = os.path.join(cls.tmp, "kw.out")
        with open(stream, "w") as fh:
            fh.write("record\tcd=387\t%s\n" % kw)
        raw = os.path.join(cls.tmp, "raw.bin")
        r = subprocess.run([sys.executable, "solve.py", "--encode-solutions", raw, stream],
                           capture_output=True, text=True)
        if "ENCODE_ROUNDTRIP=PASS" not in r.stdout.splitlines():     # explicit raise (Q-373)
            raise AssertionError("--encode-solutions did not PASS: " + r.stdout + r.stderr)
        cls.gz = os.path.join(cls.tmp, "sample.bin")
        with open(raw, "rb") as src, gzip.open(cls.gz, "wb") as dst:
            dst.write(src.read())
        cls.chunks = os.path.join(cls.tmp, "chunks")
        r = subprocess.run([sys.executable, "solve.py", "--compute-stats", cls.gz, cls.chunks,
                            "--compute-stats-workers", "1"], capture_output=True, text=True)
        if r.returncode != 0 or "COMPUTE_STATS=PASS" not in r.stdout:    # explicit raise (Q-373)
            raise AssertionError("--compute-stats did not PASS: " + r.stdout + r.stderr)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def test_sidecar_names_the_gzipped_input_not_the_temp_file(self):
        import json
        side = json.load(open(os.path.join(self.chunks, "compute_stats.json")))
        self.assertEqual(side["solutions_bin"], os.path.abspath(self.gz))
        self.assertNotIn("roae_gz_py_", side["solutions_bin"])
        self.assertIs(side.get("gzip_decompressed"), True)

    def test_check_t5_c3_reads_the_gzipped_artifact(self):
        r = subprocess.run([sys.executable, "verify.py", "--check-t5-c3", self.gz, self.chunks],
                           capture_output=True, text=True)
        self.assertIn("T5_C3_AGREE=PASS", r.stdout.splitlines(), r.stdout + r.stderr)
        self.assertEqual(r.returncode, 0)


class TestMissingInputIsRefusedNotCrashed(unittest.TestCase):
    """A missing, unreadable or wrong-format INPUT is the reader's error, and the answer is a
    one-line refusal naming the path plus the mode's own whole-line token -- never a Python
    traceback. Measured 2026-09-21 (Q-410 finding #9): eleven solve.py input paths and three
    verify.py modes answered a mistyped path with a bare FileNotFoundError traceback, rc 1, no
    token. A traceback prints no `KEY=value` line, so every `grep -qx` gate was blind to it, and
    scripts/exec_lane.sh grades a "No such file" line as SKIP-MISSING-INPUT -- a broken command
    scored as skipped. Every case below was also shown FAILING on a per-site mutant that reverts
    its guard (scratch record in the private sweep note). Each row: argv, expected rc, and a
    regex that must match one whole line of the combined output."""

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="nocrash_")
        cls.missing = os.path.join(cls.tmp, "missing")
        cls.text = os.path.join(cls.tmp, "text.bin")
        with open(cls.text, "w") as fh:
            fh.write("# not a solutions.bin, not JSON, not gzip\n")
        cls.afile = os.path.join(cls.tmp, "afile")          # a FILE where a directory is needed
        with open(cls.afile, "w") as fh:
            fh.write("x\n")
        cls.shards = os.path.join(cls.tmp, "shards")
        os.makedirs(cls.shards)
        with open(os.path.join(cls.shards, "shard_A_0.json"), "w") as fh:
            fh.write('{"x": 1}\n')

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def _check(self, prog, argv, rc, line_re):
        r = subprocess.run([sys.executable, prog] + argv, capture_output=True, text=True,
                           timeout=300)
        out = r.stdout + r.stderr
        self.assertNotIn("Traceback (most recent call last)", out, "%s %s\n%s" % (prog, argv, out))
        self.assertEqual(r.returncode, rc, "%s %s\n%s" % (prog, argv, out))
        self.assertTrue(any(re.match(line_re + r"$", l) for l in out.splitlines()),
                        "no line matches %r in:\n%s" % (line_re, out))

    def test_the_eleven_solvepy_input_paths_refuse(self):
        M, T = self.missing, self.text
        cases = [
            (["--atlas-queries", M + ".json", "--atlas-out", self.tmp], 2,
             r"ERROR: \[atlas\] .*: cannot read the atlas \(No such file or directory\)"),
            (["--atlas-selftest", M + ".json"], 1, r"ATLAS_CONSUMER=FAIL:refused-at-load"),
            (["--compute-stats", M + ".bin", os.path.join(self.tmp, "cs")], 1,
             r"COMPUTE_STATS=FAIL cannot read .*: No such file or directory"),
            (["--branch-yield-report", M + ".bin"], 2,
             r"ERROR: --branch-yield-report: cannot read SOLUTIONS_BIN .*: No such file or directory"),
            (["--branch-yield-report", T, "--branch-yield-manifest", M + ".json"], 2,
             r"ERROR: --branch-yield-report: cannot read (SOLUTIONS_BIN|MANIFEST_JSON) .*"),
            (["--branch-yield-report", T, "--branch-yield-baseline", M + ".bin"], 2,
             r"ERROR: --branch-yield-report: cannot read (SOLUTIONS_BIN|BASELINE_BIN) .*"),
            (["--keystone-analysis", M + ".bin", os.path.join(self.tmp, "ks.md")], 1,
             r"KEYSTONE_ANALYSIS=FAIL cannot read .*: No such file or directory"),
            (["--compare-depth-profile", M + ".a", M + ".b"], 2,
             r"ERROR: cannot read A=.* \(No such file or directory\)"),
            (["--tr8-dof-merge", M], 1, r"cannot read OUT_DIR .* — nothing to merge"),
            (["--h2-verify", M + ".dump"], 1, r"H2 VERIFY: FAIL \(unreadable dump\)"),
            (["--h2-mass", M + ".dump"], 1, r"h2-mass: .*: cannot read the dump \(.*\) — aborting"),
        ]
        for argv, rc, line_re in cases:
            with self.subTest(argv=argv):
                self._check("solve.py", argv, rc, line_re)

    def test_wrong_format_inputs_refuse_in_the_same_vocabulary(self):
        T = self.text
        cases = [
            (["--compute-stats", T, os.path.join(self.tmp, "cs2")], 1,
             r"COMPUTE_STATS=FAIL .*: Not v1 solutions\.bin \(magic=.*\)"),
            (["--keystone-analysis", T, os.path.join(self.tmp, "ks2.md")], 1,
             r"KEYSTONE_ANALYSIS=FAIL .*: Not v1 solutions\.bin \(magic=.*\)"),
            (["--branch-yield-report", T], 2,
             r"ERROR: --branch-yield-report: cannot read SOLUTIONS_BIN .*: bad magic: .*"),
            (["--atlas-queries", T, "--atlas-out", self.tmp], 2,
             r"ERROR: \[atlas\] .*: not a JSON document \(.*\)"),
            (["--atlas-selftest", T], 1, r"ATLAS_CONSUMER=FAIL:refused-at-load"),
            (["--tr8-dof-merge", self.shards], 1,
             r".*shard_A_0\.json is not a --tr8-dof-shard file \(missing field 'header'; .*"),
            (["--h2-verify", T], 1, r"H2 VERIFY: FAIL \(insufficient leaves\)"),
            (["--atlas-queries", os.path.join(self.afile, "atlas.json")], 2,
             # a FILE where the output root must be: makedirs raises FileExistsError here and
             # NotADirectoryError one level deeper -- both OSError, both a refusal
             r"ERROR: \[atlas\] cannot create the output root .* \((Not a directory|File exists)\)"),
            (["--sat-encode", os.path.join(self.afile, "out.cnf")], 2,
             r"ERROR: --sat-encode: cannot write OUT_CNF .*: Not a directory"),
            (["--tr8-dof-sampler", os.path.join(self.tmp, "s"), "--tr8-dof-seed", "T",
              "--tr8-dof-pool-draws", "1001", "--tr8-dof-shards", "4", "--tr8-dof-predicates",
              "5", "--tr8-dof-k", "8", "--tr8-dof-calib-draws", "100"], 1,
             r"--tr8-dof-sampler: n_pool \(1001\) must be a positive multiple of n_shards \(4\).*"),
            (["--h2-verify", T, "abc"], 2, r"solve\.py: error: --h2-verify DUMPFILE \[N\]: N must be an integer, got 'abc'"),
        ]
        for argv, rc, line_re in cases:
            with self.subTest(argv=argv):
                self._check("solve.py", argv, rc, line_re)

    def test_verifypy_modes_refuse(self):
        M, T = self.missing, self.text
        cases = [
            (["--check-atlas-orbit-frames", M + ".json"], 2,
             r"ATLAS_ORBIT_FRAMES=ERROR \(cannot read .*: No such file or directory\)"),
            (["--check-atlas-orbit-frames", T], 2, r"ATLAS_ORBIT_FRAMES=ERROR \(cannot read .*\)"),
            (["--check-t5-c3", M + ".bin", self.tmp], 2,
             r"T5_C3_AGREE=ERROR cannot read .*: No such file or directory"),
            (["--q6-extremes-oracle", M + ".txt"], 1,
             r"Q6_EXTREMES_ORACLE=FAIL \(cannot read .*: No such file or directory\)"),
        ]
        for argv, rc, line_re in cases:
            with self.subTest(argv=argv):
                self._check("verify.py", argv, rc, line_re)

    def test_guard_is_narrow_a_real_bug_still_surfaces(self):
        # The refusal guards catch OSError/ValueError/KeyError around ONE operation each. A
        # defect elsewhere must still be a loud traceback, or the guards would be hiding bugs
        # behind calm sentences. Positive control: an unexpected exception type raised from
        # the same call site is not converted.
        S = _load("solve")
        real = S.h2_parse_dump
        try:
            def boom(path):
                raise RuntimeError("synthetic defect")
            S.h2_parse_dump = boom
            with self.assertRaises(RuntimeError):
                S.h2_mass(["anything"])
            with self.assertRaises(RuntimeError):
                S.h2_verify("anything", 2)
        finally:
            S.h2_parse_dump = real


class TestAtlasProbe(unittest.TestCase):
    """`solve.py --atlas-probe` (TR-12 §12, 2026-09-21): the public reproduction command for
    every figure derived from the n=31 `--kc-scan --kc-raw` atlas.  This class builds a REAL
    n=9 f/g/t ladder and atlas with the tracked solve.c, runs the probe on it, and then proves
    the probe can come out red: a perturbed class mass must turn it FAIL (rc 1), a quotient-only
    atlas (no `kernel`) must be REFUSED (rc 2), and a missing path must be an ERROR line, never a
    traceback.  Every token is matched whole-line.  A build failure is a test FAILURE, never a
    skip -- a gate that cannot run must not read as one that passed."""

    @classmethod
    def setUpClass(cls):
        import tempfile, os
        cls.tmp = tempfile.mkdtemp(prefix="atlasprobe_")
        cls.sbin = os.path.join(cls.tmp, "solve_probe")
        cls.atlas = os.path.join(cls.tmp, "atlas9.json")
        src = os.environ.get("ROAE_TESTS_SOLVE_SRC", "solve.c")
        r = subprocess.run(["gcc", "-O1", "-pthread", "-fopenmp", "-o", cls.sbin, src,
                            "-lm", "-lz"], capture_output=True, text=True)
        cls.build_err = f"gcc rc {r.returncode}: " + r.stderr[-2000:]
        cls.build_ok = (r.returncode == 0 and os.path.exists(cls.sbin))
        if not cls.build_ok:
            return
        f, g, t = (os.path.join(cls.tmp, d) for d in ("f", "g", "t"))
        for argv in ([cls.sbin, "--kc-build", f, "--f1-pairs", "9"],
                     [cls.sbin, "--kc-g-build", g, "--f1-pairs", "9"],
                     [cls.sbin, "--kc-t-build", f, t],
                     [cls.sbin, "--kc-scan", f, g, cls.atlas, "--kc-tdir", t, "--kc-raw"]):
            r = subprocess.run(argv, capture_output=True, text=True)
            if r.returncode != 0:
                cls.build_ok = False
                cls.build_err = "%s: rc %d\n%s" % (" ".join(argv[1:3]), r.returncode, r.stdout[-1500:])
                return
        cls.build_ok = os.path.exists(cls.atlas)

    @classmethod
    def tearDownClass(cls):
        import shutil
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def _probe(self, path):
        r = subprocess.run([sys.executable, "solve.py", "--atlas-probe", path],
                           capture_output=True, text=True)
        out = r.stdout + r.stderr
        self.assertNotIn("Traceback (most recent call last)", out, out)
        return r.returncode, set(r.stdout.splitlines()), out

    def test_a_real_n9_atlas_passes_and_the_reduced_budget_is_read_off_it(self):
        self.assertTrue(self.build_ok, self.build_err)
        rc, lines, out = self._probe(self.atlas)
        self.assertEqual(rc, 0, out)
        for want in ("ATLAS_PROBE=PASS", "ATLAS_PROBE_FAILS=0",
                     # the reduced universe's C5 budget: d3 and d6 are ZERO there because the
                     # deterministic-DFS witness multiset has no d3/d6 component -- the local
                     # fact behind the small-n class zeros (TR-12 §12.1)
                     "B0_FROM_COLUMN_SUMS=2,5,0,2,0", "B0_SUM_EQ_N=PASS",
                     "REF_WALK_SOURCE=O3-MIDPOINT", "REF_WALK_IS_KING_WEN=SKIP:n=9",
                     "KW_PAIR_SHARE_AT_OWN_SLOT_MIN_MAX_INTERIOR=SKIP:n=9",
                     "PAIRS_NEVER_FIRST=4,6,21",
                     "PAIRS_NEVER_FIRST_ARE_EXACTLY_THE_POPCOUNT5_PAIRS=PASS",
                     "RID_DIGIT_SUM_EQ_LAYER_EVERY_CELL=PASS",
                     "REF_WALK_TRANSITIONS_MATCH_KW_CLS=PASS",
                     # the V5 factorisation block (TR-12 review B3/B4, 2026-09-24; Q-692): the
                     # (d, w) cross-tab re-summed from `kernel` must sit in C1's w-classes and
                     # marginalise to `by_class`, and every k = 0 key must carry exit 0 -- the
                     # C4 pin that makes the layer-0 deviation an artefact, gated, not narrated
                     "V5_K0_EXIT_IS_ANCHOR_HEXAGRAM_EVERY_KEY=PASS",
                     "V5_CROSSTAB_W_IN_C1_CLASSES_AND_MARGINALISES_TO_BY_CLASS_EVERY_LAYER=PASS",
                     # the G48 divisibility block and the cross-layer kernel re-sum (Q-734,
                     # 2026-09-24).  At n = 9 every placed pair sits in a size-3 orbit, so the
                     # MOD16 gate coincides with the stabiliser gate here; it is EMPIRICAL only
                     # at n = 31.
                     "N_TOTAL_MOD48_EQ_0=PASS", "LAYER_FLOW_EQ_N_EVERY_LAYER=PASS",
                     "BY_CLASS_EVERY_CELL_MOD48_EQ_0=PASS",
                     "MARGINAL_RAW_EVERY_CELL_MOD_STABILISER_EQ_0=PASS",
                     "MARGINAL_RAW_EVERY_CELL_MOD16_EQ_0_EMPIRICAL=PASS",
                     "KERNEL_ROW_SUMS_EQ_PREVIOUS_LAYER_EXIT_SUMS_EVERY_LAYER=PASS"):
            self.assertIn(want, lines, "%s missing as a whole line in:\n%s" % (want, out))
        # the windowed twin of MARGINAL_RAW_NONZERO_CELL_MIN_MAX (review B4) is printed under
        # its own name; its value is the atlas's, so only its presence is pinned here
        self.assertTrue([l for l in lines if l.startswith("MARGINAL_RAW_NONZERO_CELL_MIN_MAX_INTERIOR=")],
                        "MARGINAL_RAW_NONZERO_CELL_MIN_MAX_INTERIOR= missing in:\n%s" % out)
        self.assertFalse([l for l in lines if l.endswith("=FAIL")], out)

    def test_a_k0_kernel_key_with_a_nonzero_exit_turns_the_v5_gate_red(self):
        """Q-692 red test (mutant A of the V5 block, 2026-09-24): rewrite ONE k = 0 kernel key
        `m0_<y>` to `m5_<y>`, i.e. an exit of 5 where C4 pins it to 0.  The entry `y` is chosen
        so that popcount(5 ^ y) == popcount(y) and (0, y) is not the reference walk's cell, so
        the layer sum, the class marginals, the entry-pair marginals, the V5 cross-tab
        marginalisation and the reference-walk cell all stay green -- the test asserts that,
        so V5_K0_EXIT_IS_ANCHOR_HEXAGRAM_EVERY_KEY is proven to be the only gate OLDER than
        Q-738 that sees the edit, load-bearing rather than shadowed by an older one.  Since
        Q-738 KERNEL_G48_INVARIANT_EVERY_LAYER sees it too (the moved cell's G48 images keep
        exit 0), and the exact FAIL set below pins both."""
        self.assertTrue(self.build_ok, self.build_err)
        import json, os
        pc = lambda v: bin(v).count("1")
        with open(self.atlas) as fh:
            a = json.load(fh)
        L0 = a["layers"][0]
        mate = {}
        for e, x in solve.king_wen_pairs():
            mate[e] = x
            mate[x] = e
        ref_entry = mate[int(L0["kwrank"]["kw_exit"])]      # ref_t[0] = (0, mate[kwx[0]])
        k0_keys = sorted(L0["kernel"])
        # precondition of the claim: every k = 0 key carries exit 0 BEFORE the edit
        self.assertTrue(k0_keys and all(k.startswith("m0_") for k in k0_keys), k0_keys)
        cand = [k for k in k0_keys
                if pc(5 ^ int(k[3:])) == pc(int(k[3:])) and int(k[3:]) != ref_entry]
        self.assertTrue(cand, "no k=0 key with popcount(5^y)==popcount(y) off the ref cell: %r" % k0_keys)
        old_key = cand[0]
        new_key = "m5_" + old_key[3:]
        self.assertNotIn(new_key, L0["kernel"])
        L0["kernel"][new_key] = L0["kernel"].pop(old_key)
        mutant = os.path.join(self.tmp, "atlas9_k0exit.json")
        with open(mutant, "w") as fh:
            json.dump(a, fh)
        # precondition: the mutation actually changed a k = 0 key on disk
        with open(mutant) as fm:
            m = json.load(fm)
        self.assertNotIn(old_key, m["layers"][0]["kernel"])
        self.assertIn(new_key, m["layers"][0]["kernel"])
        self.assertTrue(any(not k.startswith("m0_") for k in m["layers"][0]["kernel"]))
        # precondition: the fixture's own gate is green
        rc0, lines0, out0 = self._probe(self.atlas)
        self.assertEqual(rc0, 0, out0)
        self.assertIn("V5_K0_EXIT_IS_ANCHOR_HEXAGRAM_EVERY_KEY=PASS", lines0, out0)
        rc, lines, out = self._probe(mutant)
        self.assertNotEqual(rc, 0, out)
        self.assertEqual(rc, 1, out)
        self.assertIn("V5_K0_EXIT_IS_ANCHOR_HEXAGRAM_EVERY_KEY=FAIL", lines, out)
        self.assertIn("ATLAS_PROBE=FAIL", lines, out)
        self.assertNotIn("ATLAS_PROBE_FAILS=0", lines, out)
        # the older gates cannot see this edit: of the gates before Q-738, the V5 one alone does
        for still in ("KERNEL_EVERY_LAYER_SUMS_TO_N=PASS",
                      "KERNEL_CLASS_MARGINALS_EQ_BY_CLASS_EVERY_LAYER=PASS",
                      "KERNEL_ENTRY_PAIR_MARGINALS_EQ_MARGINAL_RAW_EVERY_LAYER=PASS",
                      "REF_WALK_KERNEL_CELLS_ALL_NONZERO=PASS",
                      "V5_CROSSTAB_W_IN_C1_CLASSES_AND_MARGINALISES_TO_BY_CLASS_EVERY_LAYER=PASS"):
            self.assertIn(still, lines, "%s missing as a whole line in:\n%s" % (still, out))
        self.assertEqual(sorted(l for l in lines if l.endswith("=FAIL")),
                         ["ATLAS_PROBE=FAIL", "KERNEL_G48_INVARIANT_EVERY_LAYER=FAIL",
                          "V5_K0_EXIT_IS_ANCHOR_HEXAGRAM_EVERY_KEY=FAIL"], out)

    # ------------------------------------------------------------------ Q-734, 2026-09-24
    # Kernel-CONSISTENT mutants (Opus Q, roae-private CODEX_A08_STRONGER_IDENTITIES_GATED.md,
    # control table B).  Each edit balances every linear re-sum the probe did before Q-734, so the
    # pre-Q-734 probe scored all of them ATLAS_PROBE=PASS.  Each test pins the EXACT set of FAIL
    # lines: when that set holds only Q-734/Q-738 tokens plus ATLAS_PROBE, every pre-existing gate
    # printed PASS on the mutant, which is the "old probe PASSes it" half of the claim, asserted
    # rather than narrated.
    _Q734_NEW = ("N_TOTAL_MOD48_EQ_0", "LAYER_FLOW_EQ_N_EVERY_LAYER", "BY_CLASS_EVERY_CELL_MOD48_EQ_0",
                 "MARGINAL_RAW_EVERY_CELL_MOD_STABILISER_EQ_0",
                 "MARGINAL_RAW_EVERY_CELL_MOD16_EQ_0_EMPIRICAL",
                 "KERNEL_ROW_SUMS_EQ_PREVIOUS_LAYER_EXIT_SUMS_EVERY_LAYER")
    # Q-738 (2026-09-24): the producer's remaining tail checks, re-derived.  A mutant that
    # balances every re-sum is now also held to G48 invariance, to rev-symmetric entry-column
    # totals, to V1 column sums of N and to the digits/rid_mass identities.
    _Q738_NEW = ("PAIR_UNIVERSE_IS_G48_CLOSED", "KERNEL_G48_INVARIANT_EVERY_LAYER",
                 "KERNEL_ENTRY_COLUMN_TOTALS_REV_SYMMETRIC", "MARGINAL_RAW_COLUMN_SUMS_EQ_N_EVERY_PAIR",
                 "DIGITS_WEIGHTED_SUM_EQ_CLASS_PREFIX_EVERY_LAYER",
                 "RID_MASS_DIGIT_MARGINALS_EQ_DIGITS_EVERY_LAYER")
    # every gate token added to --atlas-probe since public HEAD 5c296837 (Q-734 + Q-738); a later
    # lane adds its own tuple here rather than widening a Q-numbered one.
    _NEW_SINCE_5c296837 = _Q734_NEW + _Q738_NEW

    def _q734_setup(self):
        """Fixture JSON plus the maps every Q-734 mutant needs, and the reference walk's
        last-layer kernel cell (a mutant must not touch it: zeroing it would fire an OLD gate)."""
        import json
        with open(self.atlas) as fh:
            a = json.load(fh)
        n = int(a["n"])
        pair_of, mate = {}, {}
        for i, (e, x) in enumerate(solve.king_wen_pairs()):
            pair_of[e] = pair_of[x] = i
            mate[e] = x
            mate[x] = e
        L = a["layers"]
        ref_last = (int(L[n - 2]["kwrank"]["kw_exit"]), mate[int(L[n - 1]["kwrank"]["kw_exit"])])
        cells = {tuple(map(int, k[1:].split("_"))): int(v) for k, v in L[n - 1]["kernel"].items()}
        return a, n, pair_of, mate, ref_last, cells

    @staticmethod
    def _bump(d, key, delta):
        old = d[key]
        d[key] = (str if isinstance(old, str) else int)(int(old) + delta)

    def _probe_mutant_run(self, a, name, want_fail):
        """Write the mutant, prove it differs from the fixture and that the fixture is green on
        the gates it targets, then pin the mutant's exact FAIL set."""
        import json, os
        mutant = os.path.join(self.tmp, name)
        with open(mutant, "w") as fh:
            json.dump(a, fh)
        with open(self.atlas) as fa:
            self.assertNotEqual(json.load(fa), a, "precondition: the mutation changed nothing")
        rc0, lines0, out0 = self._probe(self.atlas)
        self.assertEqual(rc0, 0, out0)
        for tok in want_fail:
            self.assertIn(tok + "=PASS", lines0, out0)
        rc, lines, out = self._probe(mutant)
        self.assertEqual(rc, 1, out)
        self.assertNotIn("ATLAS_PROBE_FAILS=0", lines, out)
        fails = sorted(l for l in lines if l.endswith("=FAIL"))
        self.assertEqual(fails, sorted(["ATLAS_PROBE=FAIL"] + [t + "=FAIL" for t in want_fail]), out)
        # every FAIL is a Q-734 or Q-738 token: no gate that existed at 5c296837 sees this edit
        self.assertTrue(all(l[:-5] in self._NEW_SINCE_5c296837 + ("ATLAS_PROBE",)
                            for l in fails), fails)

    def test_a_kernel_consistent_v1_move_is_caught_by_the_stabiliser_and_theorem_gates(self):
        """Q-734 (control B row 4): move 8 units of LAST-layer kernel mass inside one exit row
        between entries of two DIFFERENT orbit-3 pairs with equal class d and equal within-pair w,
        mirrored in marginal_raw.  Kernel, class, entry-pair, V5 and row sums all still balance and
        the last layer has no successor for the cross-layer gate to compare; before Q-738 only
        the G48 stabiliser gates (|Stab| = 16 for an orbit-3 pair) saw it, and since Q-738 the
        G48-invariance and V1 column-sum gates see it too."""
        self.assertTrue(self.build_ok, self.build_err)
        pc = lambda v: bin(v).count("1")
        a, n, pair_of, mate, ref_last, cells = self._q734_setup()
        orb = {p: len(o) for o in solve.pair_orbit_partition() for p in o}
        hit = next(((x, y1, y2) for (x, y1), v in sorted(cells.items())
                    if v >= 8 and (x, y1) != ref_last
                    for y2 in range(64)
                    if (x, y2) in cells and pair_of[y2] != pair_of[y1]
                    and orb.get(pair_of[y1]) == orb.get(pair_of[y2]) == 3
                    and pc(x ^ y1) == pc(x ^ y2) and pc(y1 ^ mate[y1]) == pc(y2 ^ mate[y2])), None)
        self.assertIsNotNone(hit, "precondition: no admissible orbit-3 move in the fixture")
        x, y1, y2 = hit
        Lk = a["layers"][n - 1]
        # precondition: 8 is not a multiple of 16, so the move must break the stabiliser identity
        self.assertEqual(int(Lk["marginal_raw"]["pair%d" % pair_of[y1]]) % 16, 0)
        self._bump(Lk["kernel"], "m%d_%d" % (x, y1), -8)
        self._bump(Lk["kernel"], "m%d_%d" % (x, y2), +8)
        self._bump(Lk["marginal_raw"], "pair%d" % pair_of[y1], -8)
        self._bump(Lk["marginal_raw"], "pair%d" % pair_of[y2], +8)
        # Q-738: the same edit breaks G48 invariance (one cell of a 24-cell orbit moved) and the
        # V1 column sums (pair y1 now places N - 8 times over the walk); the rev-column totals
        # survive because y1 and y2 are each rev-fixed here.
        self._probe_mutant_run(a, "atlas9_q734_v1stab.json",
                       ["MARGINAL_RAW_EVERY_CELL_MOD16_EQ_0_EMPIRICAL",
                        "MARGINAL_RAW_EVERY_CELL_MOD_STABILISER_EQ_0",
                        "KERNEL_G48_INVARIANT_EVERY_LAYER",
                        "MARGINAL_RAW_COLUMN_SUMS_EQ_N_EVERY_PAIR"])

    def test_a_kernel_row_move_is_caught_by_the_cross_layer_and_g48_gates(self):
        """Q-734: the probe took the producer's `kernel_cross_layer_eq` on trust.  Move 48 units at
        the LAST layer from (x1, y) to (x2, y), x1 != x2, popcount(x1^y) == popcount(x2^y): the entry
        y is unchanged, so class, entry-pair, V5 and every divisibility (48 | 48) balance, but the
        row sums of M_{n-1} no longer equal the exit sums of M_{n-2}.  Before Q-738 only that
        re-sum saw it; since Q-738 the G48-invariance gate sees it too."""
        self.assertTrue(self.build_ok, self.build_err)
        pc = lambda v: bin(v).count("1")
        a, n, pair_of, mate, ref_last, cells = self._q734_setup()
        hit = next(((x1, x2, y) for (x1, y), v in sorted(cells.items())
                    if v >= 48 and (x1, y) != ref_last
                    for x2 in range(64)
                    if x2 != x1 and (x2, y) in cells and pc(x1 ^ y) == pc(x2 ^ y)), None)
        self.assertIsNotNone(hit, "precondition: no admissible row move in the fixture")
        x1, x2, y = hit
        K = a["layers"][n - 1]["kernel"]
        self._bump(K, "m%d_%d" % (x1, y), -48)
        self._bump(K, "m%d_%d" % (x2, y), +48)
        self._probe_mutant_run(a, "atlas9_q734_rowmove.json",
                       ["KERNEL_ROW_SUMS_EQ_PREVIOUS_LAYER_EXIT_SUMS_EVERY_LAYER",
                        "KERNEL_G48_INVARIANT_EVERY_LAYER"])          # Q-738: one cell of an orbit

    # ------------------------------------------------------------------ Q-738, 2026-09-24
    def test_a_class_preserving_kernel_rectangle_is_caught_only_by_the_g48_gate(self):
        """Q-738 (Fable T, 2026-09-24): the documented blind spot.  A class-preserving 2x2
        rectangle trade inside one layer's kernel keeps every row, entry-column and class
        marginal, so every re-sum balances and the pre-Q-738 probe scored it PASS.  G48 acts on
        complete walks and carries the cell (x, y) to (g x, g y) at the same layer, so a single
        moved cell breaks M_k[g x][g y] == M_k[x][y]; the producer's own `kernel_g_invariance`
        tail is left at "PASS" here, so only the re-derivation can see it."""
        self.assertTrue(self.build_ok, self.build_err)
        pc = lambda v: bin(v).count("1")
        a, n, pair_of, mate, ref_last, _cells = self._q734_setup()
        found = None
        for k, l in enumerate(a["layers"]):
            cells = {tuple(int(s) for s in key[1:].split("_")): int(v) for key, v in l["kernel"].items()}
            xs = sorted({x for x, _ in cells})
            ys = sorted({y for _, y in cells})
            for i, x1 in enumerate(xs):
                for x2 in xs[i + 1:]:
                    for j, y1 in enumerate(ys):
                        for y2 in ys[j + 1:]:
                            quad = ((x1, y1), (x1, y2), (x2, y1), (x2, y2))
                            if not all(c in cells for c in quad):
                                continue
                            if pc(x1 ^ y1) != pc(x2 ^ y1) or pc(x1 ^ y2) != pc(x2 ^ y2):
                                continue
                            u = min(cells[(x1, y2)], cells[(x2, y1)]) // 2
                            if u >= 1 and (found is None or u > found[1]):
                                found = (k, u, quad)
        self.assertIsNotNone(found, "precondition: no class-preserving rectangle in the fixture")
        k, u, quad = found
        K = a["layers"][k]["kernel"]
        for (x, y), sgn in zip(quad, (1, -1, -1, 1)):
            self._bump(K, "m%d_%d" % (x, y), sgn * u)
        self.assertEqual(a["tail_checks"]["kernel_g_invariance"], "PASS")   # self-report untouched
        self._probe_mutant_run(a, "atlas9_q738_rectangle.json", ["KERNEL_G48_INVARIANT_EVERY_LAYER"])

    def test_a_kernel_consistent_16_unit_v1_move_is_caught_by_the_re_derived_tails(self):
        """Q-738 (the batch 3+4 review's second blind spot): at an INTERIOR layer move 16 units in
        one exit row between entries of two different pairs of the same G48-orbit size with equal
        class and equal w, mirrored in marginal_raw, and move 16 units at the next layer between
        the two partner rows at one entry of equal class.  Kernel, class, entry-pair, V5, row and
        cross-layer sums all balance and 16 | every cell, so every Q-734 gate stays green.  Three
        re-derived tails see it: G48 invariance, the rev-symmetry of the entry-column totals, and
        the V1 column sums (every complete walk places each free pair exactly once)."""
        self.assertTrue(self.build_ok, self.build_err)
        pc = lambda v: bin(v).count("1")
        a, n, pair_of, mate, _ref, _c = self._q734_setup()
        orb = {p: len(o) for o in solve.pair_orbit_partition() for p in o}
        L = a["layers"]
        hit = None
        for k in range(1, n - 1):
            cells = {tuple(map(int, key[1:].split("_"))): int(v) for key, v in L[k]["kernel"].items()}
            nxt = {tuple(map(int, key[1:].split("_"))): int(v) for key, v in L[k + 1]["kernel"].items()}
            for (x, y1), v in sorted(cells.items()):
                if v < 16:
                    continue
                for y2 in range(64):
                    if (x, y2) not in cells or y2 not in pair_of or pair_of[y2] == pair_of[y1]:
                        continue
                    if orb.get(pair_of[y1]) != orb.get(pair_of[y2]):
                        continue
                    if pc(x ^ y1) != pc(x ^ y2) or pc(y1 ^ mate[y1]) != pc(y2 ^ mate[y2]):
                        continue
                    r1, r2 = mate[y1], mate[y2]
                    yp = next((z for z in range(64) if (r1, z) in nxt and (r2, z) in nxt
                               and nxt[(r1, z)] >= 16 and pc(r1 ^ z) == pc(r2 ^ z)), None)
                    if yp is not None:
                        hit = (k, x, y1, y2, r1, r2, yp)
                        break
                if hit:
                    break
            if hit:
                break
        self.assertIsNotNone(hit, "precondition: no admissible interior move in the fixture")
        k, x, y1, y2, r1, r2, yp = hit
        self._bump(L[k]["kernel"], "m%d_%d" % (x, y1), -16)
        self._bump(L[k]["kernel"], "m%d_%d" % (x, y2), +16)
        self._bump(L[k]["marginal_raw"], "pair%d" % pair_of[y1], -16)
        self._bump(L[k]["marginal_raw"], "pair%d" % pair_of[y2], +16)
        self._bump(L[k + 1]["kernel"], "m%d_%d" % (r1, yp), -16)
        self._bump(L[k + 1]["kernel"], "m%d_%d" % (r2, yp), +16)
        for tc in ("kernel_g_invariance", "kernel_rev_column_eq", "vertical_raw_eq_N"):
            self.assertEqual(a["tail_checks"][tc], "PASS")            # self-reports untouched
        self._probe_mutant_run(a, "atlas9_q738_v1move16.json",
                       ["KERNEL_G48_INVARIANT_EVERY_LAYER",
                        "KERNEL_ENTRY_COLUMN_TOTALS_REV_SYMMETRIC",
                        "MARGINAL_RAW_COLUMN_SUMS_EQ_N_EVERY_PAIR"])

    def test_a_digits_cell_move_is_caught_by_the_digit_identities(self):
        """Q-738: `digits` was never read by the probe.  Moving one unit between two j-cells of one
        (layer, class) keeps the row at N; the weighted sum no longer equals the class prefix and
        the rid_mass digit marginal no longer matches.  Nothing else reads the table."""
        self.assertTrue(self.build_ok, self.build_err)
        a, n, _p, _m, _r, _c = self._q734_setup()
        hit = None
        for k in range(1, n):
            for c, dg in a["layers"][k]["digits"].items():
                js = [j for j, v in dg.items() if int(v) >= 1]
                if len(js) >= 2:
                    hit = (k, c, js[0], js[1])
                    break
            if hit:
                break
        self.assertIsNotNone(hit, "precondition: no (layer, class) with two occupied digit cells")
        k, c, j1, j2 = hit
        self._bump(a["layers"][k]["digits"][c], j1, -1)
        self._bump(a["layers"][k]["digits"][c], j2, +1)
        self.assertEqual(a["tail_checks"]["digit_cross_table_eq_cls_prefix"], "PASS")
        self._probe_mutant_run(a, "atlas9_q738_digits.json",
                       ["DIGITS_WEIGHTED_SUM_EQ_CLASS_PREFIX_EVERY_LAYER",
                        "RID_MASS_DIGIT_MARGINALS_EQ_DIGITS_EVERY_LAYER"])

    def test_a_layer_flow_off_n_is_caught_by_its_own_re_sum(self):
        """Q-734: the probe never read `layers[k].flow`; only the producer's self-reported
        `per_layer_flow_eq_N` covered it, and that boolean is left True here.  flow + 48 keeps
        48 | flow, so a mod-48 flow gate would stay green -- which is why the gate is flow == N."""
        self.assertTrue(self.build_ok, self.build_err)
        a, n, _p, _m, _r, _c = self._q734_setup()
        self.assertIs(a["gates"]["per_layer_flow_eq_N"], True)   # precondition: self-report stays True
        self._bump(a["layers"][1], "flow", +48)
        self._probe_mutant_run(a, "atlas9_q734_flow.json", ["LAYER_FLOW_EQ_N_EVERY_LAYER"])

    def test_the_committed_n31_atlas_passes_the_probe(self):
        """Q-734: `solve.py --atlas-probe runs/20260906_kc_ladders_n31/atlas_n31.json` is TR-12
        §12's published reproduction command, and nothing ran it on the published atlas.  No
        build: the atlas is a tracked file and the probe reads only it (~0.5 s measured on the
        worker, 2026-09-24).  The bytes are first tied to the digest TR-12 publishes for them,
        read from the report rather than restated here, so a PASS is a PASS on the published
        atlas and on nothing else."""
        import hashlib, os, re
        path = os.path.join("runs", "20260906_kc_ladders_n31", "atlas_n31.json")
        self.assertTrue(os.path.isfile(path), "the published n=31 atlas is missing: %s" % path)
        with open(os.path.join("reports", "TR12_QUERY_PROGRAM.md"), encoding="utf-8") as fh:
            pins = re.findall(r"The atlas every §12 figure is read from \|[^|\n]*sha256 `([0-9a-f]{64})`",
                              fh.read())
        self.assertEqual(len(pins), 1, "precondition: TR-12 must pin exactly one atlas digest: %r" % pins)
        with open(path, "rb") as fh:
            self.assertEqual(hashlib.sha256(fh.read()).hexdigest(), pins[0])
        rc, lines, out = self._probe(path)
        self.assertEqual(rc, 0, out)
        for want in ("ATLAS_PROBE=PASS", "ATLAS_PROBE_FAILS=0", "ATLAS_N=31",
                     "B0_FROM_COLUMN_SUMS=2,8,13,7,1", "REF_WALK_IS_KING_WEN=PASS") + tuple(
                         t + "=PASS" for t in self._Q734_NEW):
            self.assertIn(want, lines, "%s missing as a whole line in:\n%s" % (want, out))
        self.assertFalse([l for l in lines if l.endswith("=FAIL")], out)

    def test_a_perturbed_class_mass_turns_the_probe_red(self):
        self.assertTrue(self.build_ok, self.build_err)
        import json, os
        with open(self.atlas) as fh:
            a = json.load(fh)
        cell = a["layers"][3]["by_class"]
        old = cell["d1"]
        cell["d1"] = (str if isinstance(old, str) else int)(int(old) + 1)
        mutant = os.path.join(self.tmp, "atlas9_mutant.json")
        with open(mutant, "w") as fh:
            json.dump(a, fh)
        # precondition: the mutant differs from the fixture, and the fixture's gate was green
        with open(self.atlas) as fa, open(mutant) as fm:
            self.assertNotEqual(fa.read(), fm.read())
        rc0, lines0, _ = self._probe(self.atlas)
        self.assertIn("B0_COLUMN_SUMS_EXACT_MULTIPLES_OF_N=PASS", lines0)
        rc, lines, out = self._probe(mutant)
        self.assertEqual(rc, 1, out)
        self.assertIn("ATLAS_PROBE=FAIL", lines, out)
        self.assertIn("B0_COLUMN_SUMS_EXACT_MULTIPLES_OF_N=FAIL", lines, out)
        self.assertNotIn("ATLAS_PROBE_FAILS=0", lines, out)

    def test_a_broken_by_class_row_sum_is_caught_by_its_own_gate(self):
        """Adversarial review 2026-09-21: move N units of class d2 from one layer to another,
        choosing two layers whose reference-walk class is NOT d2.  The column sums (b0) and the
        kwrank bin identity are untouched, so every gate that existed before the review stays
        green -- the test asserts that, so the new row-sum gate is proven load-bearing rather
        than shadowed by an older one."""
        self.assertTrue(self.build_ok, self.build_err)
        import json, os
        with open(self.atlas) as fh:
            a = json.load(fh)
        N = int(a["N_total"])
        ks = [k for k, l in enumerate(a["layers"]) if int(l["kwrank"]["kw_cls"]) != 2]
        self.assertGreaterEqual(len(ks), 2, "need two layers whose kw_cls is not d2: %r" % ks)
        for k, sgn in ((ks[0], 1), (ks[1], -1)):
            cell = a["layers"][k]["by_class"]
            old = cell["d2"]
            cell["d2"] = (str if isinstance(old, str) else int)(int(old) + sgn * N)
        mutant = os.path.join(self.tmp, "atlas9_rowsum.json")
        with open(mutant, "w") as fh:
            json.dump(a, fh)
        rc, lines, out = self._probe(mutant)
        self.assertEqual(rc, 1, out)
        self.assertIn("ATLAS_PROBE=FAIL", lines, out)
        self.assertIn("BY_CLASS_ROW_SUMS_EQ_N_EVERY_LAYER=FAIL", lines, out)
        # precondition of the claim: the pre-review gates cannot see this edit
        self.assertIn("B0_COLUMN_SUMS_EXACT_MULTIPLES_OF_N=PASS", lines, out)
        self.assertIn("KWRANK_BINS_SUM_TO_CLASS_MASS_EVERY_LAYER=PASS", lines, out)

    def test_a_broken_marginal_raw_row_sum_is_caught_by_its_own_gate(self):
        """Adversarial review 2026-09-21: one `marginal_raw` cell raised by N makes that slot's
        row sum 2N.  Before the review this scored ATLAS_PROBE=PASS with a positional TV of
        0.52 printed beside it; now the row-sum gate and the kernel cross-check both go red."""
        self.assertTrue(self.build_ok, self.build_err)
        import json, os
        with open(self.atlas) as fh:
            a = json.load(fh)
        N = int(a["N_total"])
        row = a["layers"][1]["marginal_raw"]
        key = next(iter(row))
        row[key] = (str if isinstance(row[key], str) else int)(int(row[key]) + N)
        mutant = os.path.join(self.tmp, "atlas9_margrow.json")
        with open(mutant, "w") as fh:
            json.dump(a, fh)
        rc, lines, out = self._probe(mutant)
        self.assertEqual(rc, 1, out)
        self.assertIn("ATLAS_PROBE=FAIL", lines, out)
        self.assertIn("MARGINAL_RAW_ROW_SUMS_EQ_N_EVERY_LAYER=FAIL", lines, out)
        self.assertIn("KERNEL_ENTRY_PAIR_MARGINALS_EQ_MARGINAL_RAW_EVERY_LAYER=FAIL", lines, out)
        self.assertIn("KERNEL_EVERY_LAYER_SUMS_TO_N=PASS", lines, out)

    def test_a_quotient_only_atlas_is_refused_not_scored(self):
        self.assertTrue(self.build_ok, self.build_err)
        import json, os
        with open(self.atlas) as fh:
            a = json.load(fh)
        for layer in a["layers"]:
            del layer["kernel"]
        stripped = os.path.join(self.tmp, "atlas9_nokernel.json")
        with open(stripped, "w") as fh:
            json.dump(a, fh)
        rc, lines, out = self._probe(stripped)
        self.assertEqual(rc, 2, out)
        self.assertIn("ATLAS_PROBE=ERROR:malformed-atlas", lines, out)
        self.assertNotIn("ATLAS_PROBE=PASS", lines, out)

    def test_a_missing_atlas_is_an_error_line_not_a_traceback(self):
        rc, lines, out = self._probe("/nonexistent/atlas.json")
        self.assertEqual(rc, 2, out)
        self.assertIn("ATLAS_PROBE=ERROR:cannot-read-atlas", lines, out)

    # ------------------------------------------------------------------ 2026-09-22, Codex KCR1/TRQ1
    def _mutant(self, name, edit):
        import json, os
        with open(self.atlas) as fh:
            a = json.load(fh)
        edit(a)
        p = os.path.join(self.tmp, name)
        with open(p, "w") as fh:
            json.dump(a, fh)
        return p

    def test_a_gate_dict_naming_no_gate_cannot_pass(self):
        """Codex KCR1-4a, executed by TRQ1-F2 (2026-09-22): `gates={"fails": 0}` and
        `tail_checks={"fails": 0}`.  Each verdict was `bool(d) and fails == 0 and all(<generator>)`,
        and `all` over an empty iterable is True, so both verdict lines and ATLAS_PROBE read PASS
        with zero gate witnesses.  MEASURED RED on that probe; the producer's 14-gate / 5-tail
        inventory is now required, both directions."""
        self.assertTrue(self.build_ok, self.build_err)
        # POSITIVE CONTROL: the producer's own atlas carries the full inventory and is green
        rc0, lines0, out0 = self._probe(self.atlas)
        self.assertEqual(rc0, 0, out0)
        for want in ("ATLAS_GATE_INVENTORY_COMPLETE=PASS", "ATLAS_TAIL_CHECK_INVENTORY_COMPLETE=PASS",
                     "ATLAS_GATE_COUNT=14", "ATLAS_TAIL_CHECK_COUNT=5"):
            self.assertIn(want, lines0, out0)

        def strip(a):
            a["gates"] = {"fails": 0}
            a["tail_checks"] = {"fails": 0}
        rc, lines, out = self._probe(self._mutant("atlas9_nogates.json", strip))
        self.assertEqual(rc, 1, out)
        for want in ("ATLAS_PROBE=FAIL", "ATLAS_GATES_ALL_TRUE=FAIL", "ATLAS_TAIL_CHECKS_ALL_PASS=FAIL",
                     "ATLAS_GATE_INVENTORY_COMPLETE=FAIL", "ATLAS_TAIL_CHECK_INVENTORY_COMPLETE=FAIL",
                     "ATLAS_GATE_COUNT=0", "ATLAS_TAIL_CHECK_COUNT=0"):
            self.assertIn(want, lines, "%s missing as a whole line in:\n%s" % (want, out))
        for never in ("ATLAS_PROBE_FAILS=0", "ATLAS_GATES_ALL_TRUE=PASS", "ATLAS_TAIL_CHECKS_ALL_PASS=PASS"):
            self.assertNotIn(never, lines, out)

    def test_a_gate_inventory_is_required_both_directions_and_fails_must_be_an_int(self):
        """Siblings of the empty-dict case (the KCR1-4c residue): one named gate absent, one
        unknown gate present, `fails: False` (which == 0 in Python) beside fourteen `true`s, and
        one tail check absent.  Each must turn its own verdict line and ATLAS_PROBE red."""
        self.assertTrue(self.build_ok, self.build_err)
        cases = (
            ("atlas9_gate_missing.json", lambda a: a["gates"].pop("extrema_relookup"),
             ("ATLAS_GATE_INVENTORY_MISSING=extrema_relookup", "ATLAS_GATE_INVENTORY_COMPLETE=FAIL",
              "ATLAS_GATES_ALL_TRUE=FAIL")),
            ("atlas9_gate_extra.json", lambda a: a["gates"].__setitem__("made_up_gate", True),
             ("ATLAS_GATE_INVENTORY_UNEXPECTED=made_up_gate", "ATLAS_GATE_INVENTORY_COMPLETE=FAIL",
              "ATLAS_GATES_ALL_TRUE=FAIL")),
            ("atlas9_fails_false.json", lambda a: a["gates"].__setitem__("fails", False),
             ("ATLAS_GATE_INVENTORY_COMPLETE=PASS", "ATLAS_GATES_ALL_TRUE=FAIL")),
            ("atlas9_tail_missing.json", lambda a: a["tail_checks"].pop("kernel_g_invariance"),
             ("ATLAS_TAIL_CHECK_INVENTORY_MISSING=kernel_g_invariance",
              "ATLAS_TAIL_CHECK_INVENTORY_COMPLETE=FAIL", "ATLAS_TAIL_CHECKS_ALL_PASS=FAIL")),
        )
        for name, edit, wants in cases:
            rc, lines, out = self._probe(self._mutant(name, edit))
            self.assertEqual(rc, 1, (name, out))
            for want in ("ATLAS_PROBE=FAIL",) + wants:
                self.assertIn(want, lines, "%s: %s missing as a whole line in:\n%s" % (name, want, out))

    def test_a_rid_key_past_the_radix_top_is_caught_not_aliased(self):
        """The probe decodes a rid key modulo (b0[d]+1) per digit, so a key r + rad_top carries the
        SAME digits as r: the digit-sum gate and every mass sum stay green while both null
        comparisons read the aliased cell.  The range gate landed 2026-09-22 with the exact
        omitted-mass identity, whose precondition it is; MEASURED RED on the probe before it."""
        self.assertTrue(self.build_ok, self.build_err)
        import json
        with open(self.atlas) as fh:
            a = json.load(fh)
        N = int(a["N_total"])
        b0 = [sum(int(l["by_class"][c]) for l in a["layers"]) // N for c in ("d1", "d2", "d3", "d4", "d6")]
        rad_top = 1
        for b in b0:
            rad_top *= b + 1

        def alias(a):
            row = a["layers"][2]["rid_mass"]
            key = next(iter(row))
            row["r%d" % (int(key[1:]) + rad_top)] = row.pop(key)
        rc, lines, out = self._probe(self._mutant("atlas9_ridalias.json", alias))
        self.assertEqual(rc, 1, out)
        self.assertIn("ATLAS_PROBE=FAIL", lines, out)
        self.assertIn("RID_KEYS_WITHIN_RADIX_RANGE_EVERY_CELL=FAIL", lines, out)
        # precondition of the claim: the older gates cannot see the alias
        self.assertIn("RID_MASS_EVERY_LAYER_SUMS_TO_N=PASS", lines, out)
        self.assertIn("RID_DIGIT_SUM_EQ_LAYER_EVERY_CELL=PASS", lines, out)

    def test_the_total_variation_tokens_include_the_omitted_null_mass(self):
        """Codex KCR1-2 / TRQ1-F1 (2026-09-22).  The atlas writes no zero-mass rid cell and the
        probe summed |P - Q| over the cells present only, dropping Q(S^c)/2 for BOTH nulls.  On the
        real n=9 atlas the shipped tokens read 0.3554 / 0.2927 / 0.82 (TR-12 v1.7 §12.6, §12.9);
        the definitional values are 0.5686 / 0.5854 / 1.03.  MEASURED RED on the tree that
        published v1.7.  Recomputed here by FULL ENUMERATION of each null's support in exact
        rationals -- a different derivation from the probe's `1 - sum` identity -- and the tokens
        are pinned to that, plus the literal corrected figures by name."""
        self.assertTrue(self.build_ok, self.build_err)
        import json, math
        from fractions import Fraction
        from math import comb
        with open(self.atlas) as fh:
            a = json.load(fh)
        n = int(a["n"]); N = int(a["N_total"]); L = a["layers"]
        b0 = [sum(int(l["by_class"][c]) for l in L) // N for c in ("d1", "d2", "d3", "d4", "d6")]
        rad = [1]
        for d in range(4):
            rad.append(rad[-1] * (b0[d] + 1))
        supp = [dg for dg in itertools.product(*[range(b + 1) for b in b0]) if sum(dg) < n]
        tvh, tvp, zero = [], [], 0
        for k in range(n):
            obs = {}
            for kk, v in L[k]["rid_mass"].items():
                r = int(kk[1:])
                obs[tuple((r // rad[d]) % (b0[d] + 1) for d in range(5))] = Fraction(int(v), N)
            marg = [{} for _ in range(5)]
            for dg, p in obs.items():
                for d in range(5):
                    marg[d][dg[d]] = marg[d].get(dg[d], Fraction(0)) + p
            layer = [dg for dg in supp if sum(dg) == k]
            zero += len([dg for dg in layer if dg not in obs])
            tvh.append(sum(abs(obs.get(dg, Fraction(0))
                               - Fraction(math.prod(comb(b0[d], dg[d]) for d in range(5)), comb(n, k)))
                           for dg in layer) / 2)
            grid = list(itertools.product(*[sorted(m) for m in marg]))
            self.assertTrue(set(obs) <= set(grid))
            tvp.append(sum(abs(obs.get(dg, Fraction(0))
                               - math.prod(marg[d][dg[d]] for d in range(5)))
                           for dg in grid) / 2)
        rc, lines, out = self._probe(self.atlas)
        self.assertEqual(rc, 0, out)
        for want in ("EXCHANGEABLE_NULL_TV_MAX_OVER_LAYERS=%.4f" % max(tvh),
                     "CONTROL_WRONG_NULL_PRODUCT_FORM_TV_MAX=%.4f" % max(tvp),
                     "CONTROL_WRONG_NULL_TV_OVER_EXCHANGEABLE_TV=%.2f" % (max(tvp) / max(tvh)),
                     "EXCHANGEABLE_NULL_TV_BY_LAYER=" + ",".join("%.4f" % x for x in tvh),
                     "RID_SUPPORT_CELLS_TOTAL=%d" % len(supp),
                     "RID_SUPPORT_CELLS_WITH_ZERO_OBSERVED_MASS=%d" % zero,
                     # the literal n=9 corrections, by name
                     "EXCHANGEABLE_NULL_TV_MAX_OVER_LAYERS=0.5686",
                     "CONTROL_WRONG_NULL_PRODUCT_FORM_TV_MAX=0.5854",
                     "CONTROL_WRONG_NULL_TV_OVER_EXCHANGEABLE_TV=1.03",
                     "RID_SUPPORT_CELLS_WITH_ZERO_OBSERVED_MASS=30"):
            self.assertIn(want, lines, "%s missing as a whole line in:\n%s" % (want, out))
        for never in ("EXCHANGEABLE_NULL_TV_MAX_OVER_LAYERS=0.3554",
                      "CONTROL_WRONG_NULL_PRODUCT_FORM_TV_MAX=0.2927",
                      "CONTROL_WRONG_NULL_TV_OVER_EXCHANGEABLE_TV=0.82"):
            self.assertNotIn(never, lines, out)

    def test_the_adjacent_kernel_tv_vector_is_published_at_full_precision(self):
        """Codex TRQ1-F6b (2026-09-22).  TR-12 §12 promises that ONE PUBLIC COMMAND reproduces
        every figure in §12.1-§12.8.  §12.4 published six kernel TV distances -- 0.004979,
        0.001105, 0.001007, 0.001025, 0.000290 and 0.0009874424 -- while
        KERNEL_TV_ADJACENT_LAYERS_K1_TO_KNM1 printed the vector at FOUR decimals, at which 0.00099
        and 0.0010 are indistinguishable: four of those layers could not be told apart from the
        public output at all, and the digits rested on a PRIVATE recomputation.  The figures were
        right; their standing was not.  A figure a reader cannot recompute is asserted, not
        published.

        This test is red in BOTH directions that matter.  (1) On the tree that published v1.8 the
        _FULL token does not exist, so the lookup fails.  (2) If anyone ever reverts the format
        from %.10f to %.4f -- the regression that silently re-opens CX-72 -- the last assertion
        fails, because rounding the vector to four decimals would then lose nothing.  A precision
        token that carries no precision is the vacuous-gate defect in a new costume."""
        self.assertTrue(self.build_ok, self.build_err)
        import json
        with open(self.atlas) as fh:
            a = json.load(fh)
        n = int(a["n"]); N = int(a["N_total"]); L = a["layers"]
        rc, lines, out = self._probe(self.atlas)
        self.assertEqual(rc, 0, out)

        full = [l for l in lines if l.startswith("KERNEL_TV_ADJACENT_LAYERS_K1_TO_KNM1_FULL=")]
        self.assertEqual(1, len(full),
                         "KERNEL_TV_ADJACENT_LAYERS_K1_TO_KNM1_FULL missing (CX-72):\n%s" % out)
        vals = [float(x) for x in full[0].split("=", 1)[1].split(",")]
        self.assertEqual(n - 1, len(vals), "expected one distance per adjacent pair k=1..n-1")

        # Recomputed here from the atlas's own kernel tables, not read back from the probe.
        def kern(k):
            return {key: int(v) for key, v in L[k]["kernel"].items()}
        for k in range(1, n):
            A, B = kern(k), kern(k - 1)
            keys = set(A) | set(B)
            tv = 0.5 * sum(abs(A.get(x, 0) - B.get(x, 0)) for x in keys) / N
            self.assertAlmostEqual(tv, vals[k - 1], places=9,
                                   msg="layer %d: probe %r vs recomputed %r" % (k, vals[k - 1], tv))

        # The 4-dp token must be exactly this vector rounded -- one instrument, two precisions.
        four = [l for l in lines if l.startswith("KERNEL_TV_ADJACENT_LAYERS_K1_TO_KNM1=")]
        self.assertEqual(1, len(four), out)
        self.assertEqual(four[0].split("=", 1)[1],
                         ",".join("%.4f" % x for x in vals),
                         "the 4-dp token is not the full vector rounded")

        # 🔴 THE LOAD-BEARING ASSERTION: the full token must actually carry precision the 4-dp one
        # cannot.  Without this the test would pass against a %.4f revert, i.e. against the very
        # defect it exists to prevent.
        self.assertTrue(any(abs(x - round(x, 4)) > 1e-9 for x in vals),
                        "no value differs from its own 4-dp rounding: the _FULL token adds nothing")

    def test_the_kernel_score_scale_tokens_are_recomputed_and_read_the_data(self):
        """Codex KCR1-7 / TRQ1-F5a (2026-09-22): TR-12 §12.4's -0.102 bits was published with no
        scale.  The independent-step SD and the Minkowski bound are recomputed here from the
        kernel tables with the test's own formula and the tokens pinned to them; then mass is
        traded around a class-preserving 2x2 kernel rectangle (rows, entries, classes and the V5
        cross-tab all preserved; reshaped for Q-734, see below) -- every probe gate stays green --
        and the SD token must move: it reads the data."""
        self.assertTrue(self.build_ok, self.build_err)
        import json, math
        with open(self.atlas) as fh:
            a = json.load(fh)
        n = int(a["n"]); N = int(a["N_total"]); L = a["layers"]
        var_k = []
        for l in L:
            ps = [int(v) / N for v in l["kernel"].values()]
            self.assertAlmostEqual(sum(ps), 1.0, places=9)
            m = sum(p * math.log2(p) for p in ps)
            var_k.append(sum(p * (math.log2(p) - m) ** 2 for p in ps))
        sd_ind = math.sqrt(sum(var_k))
        sd_ub = sum(math.sqrt(v) for v in var_k)
        rc, lines, out = self._probe(self.atlas)
        self.assertEqual(rc, 0, out)
        for want in ("KERNEL_SCORE_INDEPENDENT_STEP_SD_BITS=%.3f" % sd_ind,
                     "KERNEL_SCORE_SD_UPPER_BOUND_ANY_DEPENDENCE_BITS=%.3f" % sd_ub,
                     "KERNEL_SCORE_PER_STEP_SD_MIN_MAX_BITS=%.3f,%.3f"
                     % (min(math.sqrt(v) for v in var_k), max(math.sqrt(v) for v in var_k))):
            self.assertIn(want, lines, "%s missing as a whole line in:\n%s" % (want, out))
        dev = [l for l in lines if l.startswith("REF_WALK_KERNEL_SCORE_MINUS_POPULATION_MEAN_BITS=")]
        z = [l for l in lines if l.startswith("REF_WALK_KERNEL_SCORE_DEVIATION_OVER_INDEPENDENT_STEP_SD=")]
        self.assertEqual(1, len(dev), out)
        self.assertEqual(1, len(z), out)
        self.assertAlmostEqual(float(z[0].split("=")[1]), float(dev[0].split("=")[1]) / sd_ind, places=2)
        # The mutant: a 2x2 RECTANGLE trade inside one layer, +u at (x1,y1) and (x2,y2), -u at
        # (x1,y2) and (x2,y1), with popcount(x1^y1) == popcount(x2^y1) and popcount(x1^y2) ==
        # popcount(x2^y2).  Row sums, entry (column) sums, class marginals and the V5 (d, w) cross-tab
        # are all preserved, so every gate stays green.  Until Q-734 (2026-09-24) this was a
        # same-entry trade between two ROWS; that changes the layer's row sums, which the new
        # KERNEL_ROW_SUMS_EQ_PREVIOUS_LAYER_EXIT_SUMS_EVERY_LAYER re-sum correctly calls a corrupted
        # atlas.  The test had been leaning on the probe's blind spot, and its "every gate stays
        # green" premise was true only because of that blind spot.
        pc = lambda x: bin(x).count("1")
        found = None
        for k, l in enumerate(L):
            cells = {tuple(int(s) for s in key[1:].split("_")): int(v) for key, v in l["kernel"].items()}
            xs = sorted({x for x, _ in cells})
            ys = sorted({y for _, y in cells})
            for i, x1 in enumerate(xs):
                for x2 in xs[i + 1:]:
                    for j, y1 in enumerate(ys):
                        for y2 in ys[j + 1:]:
                            quad = ((x1, y1), (x1, y2), (x2, y1), (x2, y2))
                            if not all(c in cells for c in quad):
                                continue
                            if pc(x1 ^ y1) != pc(x2 ^ y1) or pc(x1 ^ y2) != pc(x2 ^ y2):
                                continue
                            u = min(cells[(x1, y2)], cells[(x2, y1)]) // 2
                            if u >= 1 and (found is None or u > found[1]):
                                found = (k, u, quad)
        self.assertIsNotNone(found, "no class-preserving 2x2 kernel rectangle to trade mass around")
        # Q-738 (2026-09-24): a single rectangle now turns KERNEL_G48_INVARIANT_EVERY_LAYER red, so
        # the trade is SYMMETRISED over G48 (the rectangle's 48 images, summed).  Rows, entry
        # columns, classes and V5 are still preserved and the result is G48-invariant: this is the
        # residual class the probe cannot see from the atlas alone (roae-private
        # Q738_ATLAS_PROBE_BLIND_SPOTS_2026_09_24.md), and the test doubles as its executable form.
        g48 = solve._tg_g48()
        ap = solve._tg_apply_perm
        sym = None
        for k, l in enumerate(L):
            cells = {tuple(int(s) for s in key[1:].split("_")): int(v) for key, v in l["kernel"].items()}
            xs = sorted({x for x, _ in cells})
            ys = sorted({y for _, y in cells})
            for i, x1 in enumerate(xs):
                for x2 in xs[i + 1:]:
                    for j, y1 in enumerate(ys):
                        for y2 in ys[j + 1:]:
                            quad = ((x1, y1), (x1, y2), (x2, y1), (x2, y2))
                            if not all(c in cells for c in quad):
                                continue
                            if pc(x1 ^ y1) != pc(x2 ^ y1) or pc(x1 ^ y2) != pc(x2 ^ y2):
                                continue
                            delta = {}
                            for p in g48:
                                for (x, y), sgn in zip(quad, (1, -1, -1, 1)):
                                    c = (ap(p, x), ap(p, y))
                                    delta[c] = delta.get(c, 0) + sgn
                            delta = {c: s for c, s in delta.items() if s}
                            if not delta or any(c not in cells for c in delta):
                                continue
                            u = min((cells[c] - 1) // (-s) for c, s in delta.items() if s < 0)
                            if u >= 1 and (sym is None or u > sym[1]):
                                sym = (k, u, delta)
        self.assertIsNotNone(sym, "no G48-symmetrised rectangle with u >= 1 in the fixture")
        k, u, delta = sym

        def trade(a):
            row = a["layers"][k]["kernel"]
            for (x, y), s in delta.items():
                key = "m%d_%d" % (x, y)
                t = type(row[key])
                row[key] = t(int(row[key]) + s * u)
        rc, mlines, mout = self._probe(self._mutant("atlas9_kerneltrade.json", trade))
        self.assertEqual(rc, 0, mout)
        self.assertFalse([l for l in mlines if l.endswith("=FAIL")], mout)
        sd0 = [l for l in lines if l.startswith("KERNEL_SCORE_INDEPENDENT_STEP_SD_BITS=")]
        sd1 = [l for l in mlines if l.startswith("KERNEL_SCORE_INDEPENDENT_STEP_SD_BITS=")]
        self.assertEqual(1, len(sd1), mout)
        self.assertNotEqual(sd0, sd1, "the SD token did not move under a %d-unit kernel rectangle trade at layer %d"
                            % (u, k))



def _tr12_figures_under_stubs(root):
    """Run viz/report_figures.py's REAL `tr12_figures` (and `_tr12_q3_table`, when the tree has
    it) with every renderer stubbed. -> (V4 path or None, raised exception or None).

    The functions are lifted out of the file by AST and executed in a namespace holding only
    `os` and the stubs: tests.py is stdlib-only and report_figures imports numpy and matplotlib
    at module level. What runs is the file's own selection code, on either side of a fix, so the
    same test can be red before it and green after."""
    import ast
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "viz",
                           "report_figures.py"), encoding="utf-8") as fh:
        tree = ast.parse(fh.read())
    keep = [n for n in tree.body if isinstance(n, ast.FunctionDef)
            and n.name in ("tr12_figures", "_tr12_q3_table")]
    for n in keep:
        n.decorator_list = []
    if not any(n.name == "tr12_figures" for n in keep):
        raise AssertionError("viz/report_figures.py has no tr12_figures; nothing was exercised")
    got = []
    ns = {"os": os,
          "fig_tr12_kc_field": lambda *a, **k: True,
          "fig_tr12_kc_river": lambda *a, **k: True,
          "fig_tr12_kc_grammar": lambda *a, **k: True,
          "fig_tr12_kc_spectrum": lambda *a, **k: True,
          "fig_tr12_kc_shells": lambda path, *a, **k: got.append(path) or True}
    exec(compile(ast.Module(body=keep, type_ignores=[]), "report_figures.py", "exec"), ns)
    try:
        ns["tr12_figures"](root)
    except RuntimeError as exc:
        return (got[0] if got else None), exc
    return (got[0] if got else None), None


class TestQ766StaleQ3ProfileIsNeverPublished(unittest.TestCase):
    """Q-766 (RCQ02 F5, CONFIRMED 2026-09-09, never fixed until 2026-09-24).

    `atlas_emit_q3` writes q3_profile_kw.tsv (a checked King Wen full-31 walk) OR
    q3_profile.tsv, and never removed the other one; `tr12_figures` drew V4 from the _kw name
    whenever it EXISTED. A reused --atlas-out therefore published the previous universe's profile.
    Seed-then-rerun, both orders: the stale table must be gone, and V4 must draw the current one.
    Red before the fix: order A draws the old King Wen table over an n=9 run; order B leaves the
    old n=9 table in the published directory."""

    HERE = os.path.dirname(os.path.abspath(__file__))

    def _kw31(self):
        import csv
        with open(os.path.join(self.HERE, "tr12", "q3_profile_kw.tsv"), encoding="utf-8") as fh:
            rows = list(csv.DictReader(fh, delimiter="\t"))
        for r in rows:
            r["p_num"], r["p_den"] = int(r["p_num"]), int(r["p_den"])
        return rows

    def _n9(self, S):
        return S.atlas_parse_q3_trace(os.path.join(self.HERE, "scripts", "tr12_expected", "n9",
                                                   "a2_q3.txt"))

    @staticmethod
    def _A(n, N):
        return {"n": n, "N_total": str(N), "space": "C1C2C4C5-SUPERSPACE", "pl_hash": "0" * 16}

    def _emit(self, S, d, which):
        with open(os.devnull, "w") as dn:
            old, sys.stdout = sys.stdout, dn
            try:
                if which == "kw31":
                    steps = self._kw31()
                    return S.atlas_emit_q3(steps, d, 31, A=self._A(31, steps[0]["g_parent"]),
                                           quiet=True)
                return S.atlas_emit_q3(self._n9(S), d, 9, A=self._A(9, 26112), quiet=True)
            finally:
                sys.stdout = old

    def _dir(self):
        d = tempfile.mkdtemp(prefix="q766_")
        self.addCleanup(shutil.rmtree, d, True)
        return d

    def test_precondition_the_kw_fixture_really_earns_the_kw_name(self):
        # Without this the two orders below would test two plain tables.
        S = _load("solve")
        self.assertEqual(S.atlas_q3_name(self._kw31(), 31)[:2], ("q3_profile_kw.tsv", "PASS"))
        self.assertEqual(S.atlas_q3_name(self._n9(S), 9)[:2], ("q3_profile.tsv", "SKIP:n=9"))

    def test_kw31_then_n9_publishes_the_n9_table_only(self):
        S = _load("solve")
        d = self._dir()
        self._emit(S, d, "kw31")
        self.assertTrue(os.path.exists(os.path.join(d, "q3_profile_kw.tsv")))
        path, _, _ = self._emit(S, d, "n9")
        self.assertEqual(os.path.basename(path), "q3_profile.tsv")
        for stale in ("q3_profile_kw.tsv", "q3_profile_kw.tsv.provenance.txt"):
            self.assertFalse(os.path.exists(os.path.join(d, stale)),
                             "%s from the earlier King Wen run survived the n=9 rerun" % stale)
        v4, exc = _tr12_figures_under_stubs(d)
        self.assertIsNone(exc, exc)
        self.assertEqual(v4, os.path.join(d, "q3_profile.tsv"),
                         "V4 drew %s, not this run's n=9 table" % v4)

    def test_n9_then_kw31_publishes_the_kw_table_only(self):
        S = _load("solve")
        d = self._dir()
        self._emit(S, d, "n9")
        path, _, _ = self._emit(S, d, "kw31")
        self.assertEqual(os.path.basename(path), "q3_profile_kw.tsv")
        for stale in ("q3_profile.tsv", "q3_profile.tsv.provenance.txt"):
            self.assertFalse(os.path.exists(os.path.join(d, stale)),
                             "%s from the earlier n=9 run survived the King Wen rerun" % stale)
        v4, exc = _tr12_figures_under_stubs(d)
        self.assertIsNone(exc, exc)
        self.assertEqual(v4, os.path.join(d, "q3_profile_kw.tsv"))

    # ---- the reader on its own: a directory an OLDER emitter left dirty -----------------------
    def _write(self, d, name, sidecar=None):
        with open(os.path.join(d, name), "w") as fh:
            fh.write("step\tg\n1\t1\n")
        if sidecar is not None:
            with open(os.path.join(d, name + ".provenance.txt"), "w") as fh:
                fh.write("q3_table=%s\nq3_is_king_wen=%s\n" % (name, sidecar))

    def test_both_names_present_is_refused_not_guessed(self):
        # RED before: existence picked the _kw table.
        d = self._dir()
        self._write(d, "q3_profile_kw.tsv", "PASS")
        self._write(d, "q3_profile.tsv", "SKIP:n=9")
        v4, exc = _tr12_figures_under_stubs(d)
        self.assertIsNone(v4, "V4 drew %s from a directory holding both names" % v4)
        self.assertIsNotNone(exc)

    def test_a_kw_table_whose_sidecar_is_not_PASS_is_refused(self):
        d = self._dir()
        self._write(d, "q3_profile_kw.tsv", "SKIP:n=9")
        v4, exc = _tr12_figures_under_stubs(d)
        self.assertIsNone(v4)
        self.assertIsNotNone(exc)

    def test_a_kw_table_with_no_sidecar_beside_a_plain_sidecar_is_refused(self):
        d = self._dir()
        self._write(d, "q3_profile_kw.tsv")
        with open(os.path.join(d, "q3_profile.tsv.provenance.txt"), "w") as fh:
            fh.write("q3_table=q3_profile.tsv\nq3_is_king_wen=SKIP:n=9\n")
        v4, exc = _tr12_figures_under_stubs(d)
        self.assertIsNone(v4)
        self.assertIsNotNone(exc)

    def test_positive_controls_the_published_tree_and_a_clean_kw_directory(self):
        # The committed tr12/ ships q3_profile_kw.tsv with NO sidecar and must still draw it.
        self.assertFalse(os.path.exists(os.path.join(self.HERE, "tr12",
                                                     "q3_profile_kw.tsv.provenance.txt")),
                         "tr12/ now carries a sidecar; this control no longer tests the "
                         "no-sidecar branch")
        v4, exc = _tr12_figures_under_stubs(os.path.join(self.HERE, "tr12"))
        self.assertIsNone(exc, exc)
        self.assertEqual(os.path.basename(v4), "q3_profile_kw.tsv")
        d = self._dir()
        self._write(d, "q3_profile_kw.tsv", "PASS")
        v4, exc = _tr12_figures_under_stubs(d)
        self.assertIsNone(exc, exc)
        self.assertEqual(v4, os.path.join(d, "q3_profile_kw.tsv"))


class TestQ767XaCertAndAnchorHardening(unittest.TestCase):
    """Q-767 items (2) and (3), RCQ04 P3 (2026-09-10), fixed 2026-09-24."""

    def _cert(self, text):
        d = tempfile.mkdtemp(prefix="q767_")
        self.addCleanup(shutil.rmtree, d, True)
        p = os.path.join(d, "cert.json")
        with open(p, "w") as fh:
            fh.write(text)
        return p

    def test_a_100000_deep_certificate_is_a_refusal_not_a_crash(self):
        # RED before: RecursionError escaped the function (the adjudication's own reproduction).
        # Q-772: the loader that replaced `_xa_node_mapping_cert_defect` keeps this refusal.
        S = _load("solve")
        p = self._cert("[" * 100000 + "]" * 100000)
        try:
            m, why = S._xa_node_mapping_load(p)
        except RecursionError:
            self.fail("RecursionError escaped _xa_node_mapping_load: a crash, not a refusal")
        self.assertIsNone(m)
        self.assertIsInstance(why, str)
        self.assertIn("nested too deeply", why)

    def test_a_deep_legacy_claim_is_no_longer_walked_to(self):
        # Q-772 (the Q-768 ruling): the iterative walk this test used to guard is GONE, with the
        # permission bit it searched for. A legacy claim at any depth now prices nothing.
        S = _load("solve")
        depth = 500
        p = self._cert("[" * depth + '{"solve_node_limit_mapping": "CERTIFIED: m"}' + "]" * depth)
        m, why = S._xa_node_mapping_load(p)
        self.assertIsNone(m)
        self.assertIn("not a JSON object", why)
        import json
        p = self._cert(json.dumps({"a": [{"solve_node_limit_mapping": {"claimed": True}}],
                                   "solve_node_limit_mapping": "CERTIFIED: x"}))
        m, why = S._xa_node_mapping_load(p)
        self.assertIsNone(m)
        self.assertIn("nothing to price with", why)

    def test_xa_exact_refuses_a_bare_float(self):
        # RED before: _xa_exact(0.1) returned 3602879701896397/36028797018963968.
        S = _load("solve")
        with self.assertRaises(S.AtlasError):
            S._xa_exact(0.1)

    def test_xa_exact_keeps_every_exact_input(self):
        from fractions import Fraction
        from decimal import Decimal
        S = _load("solve")
        self.assertEqual(S._xa_exact(S._ExactAnchor("0.1")), Fraction(1, 10))
        self.assertEqual(S._xa_exact(S._ExactAnchor("2.0")), Fraction(2))
        self.assertEqual(S._xa_exact(Fraction(1, 3)), Fraction(1, 3))
        self.assertEqual(S._xa_exact(Decimal("0.1")), Fraction(1, 10))
        self.assertEqual(S._xa_exact(7), Fraction(7))


class TestW0dLowerBoundCert(unittest.TestCase):
    """The W0-D LOWER-BOUND producer (`--xa-w0d-lb-cert`, Opus SS 2026-09-25).

    Each test names what it kills. The certificate's claim is production_nodes(b) >= t(b); it
    rests on K (t-units) being a subset of P (production) and on X(b) >= T(b) per branch."""

    def test_first_branches_carry_x_ge_t(self):
        # The per-branch inequality on a truncated run (the full run is the end-to-end test).
        S = _load("solve")
        E = S.xa_w0d_lower_bound_enumerate(max_depth=5, only_branches=3)
        self.assertEqual(len(E["branches"]), 3)
        self.assertEqual({d: v for d, v in E["B0"].items() if v},
                         {1: 2, 2: 8, 3: 13, 4: 7, 6: 1})
        self.assertEqual(E["containment_violations"], 0)
        for r in E["branches"]:
            self.assertTrue(r["ok_d2"] and r["ok_d3"], r)
            self.assertGreaterEqual(r["X_found"], r["T_d3"])

    def test_mutant_production_uses_the_t_cap_emits_nothing(self):
        # Kills "P == K": if production pruned with the t-ladder's boundary cap there would be no
        # P-not-K prefix, X == 0 < T, and the lower bound could not be certified without an
        # additive term. The positive twin above must pass on the same branches.
        S = _load("solve")
        E = S.xa_w0d_lower_bound_enumerate(prod_uses_b0=True, max_depth=4, only_branches=2)
        self.assertEqual(len(E["branches"]), 2)
        for r in E["branches"]:
            self.assertEqual(r["X_found"], 0)
            self.assertFalse(r["ok_d3"])

    def test_the_certificate_loads_as_lower_bound_and_prices_one_sided(self):
        # End to end, the real producer (~15 s): the loader accepts it as kind lower-bound,
        # F = 1/1, and the consumer can print INFEASIBLE and never EXHAUSTIBLE.
        import io, contextlib, json
        from fractions import Fraction
        S = _load("solve")
        d = tempfile.mkdtemp(prefix="w0dlb_")
        self.addCleanup(shutil.rmtree, d, True)
        out = os.path.join(d, "cert.json")
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc = S.xa_w0d_lower_bound_cert(out)
        self.assertEqual(rc, 0, buf.getvalue())
        lines = buf.getvalue().splitlines()
        self.assertIn("XA_W0D_LB_CERT=PASS", lines)
        # Positive control on the production mirror: the normal-mode partition counts.
        self.assertIn("W0D_LB_P_PREFIXES_DEPTH_1_2_3=56,3030,158364", lines)
        self.assertIn("W0D_LB_K_SUBSET_P_VIOLATIONS=0", lines)
        m, why = S._xa_node_mapping_load(out)
        self.assertIsNone(why)
        self.assertEqual(m["kind"], "lower-bound")
        self.assertEqual(m["factor"], Fraction(1))
        self.assertEqual(m["measured_n"], [31])
        with open(out) as fh:
            doc = json.load(fh)
        self.assertEqual(doc["scope"]["n"], 31)
        self.assertIn("any reduced-n atlas (n < 31)", doc["scope"]["excluded"])

    def test_a_scoped_certificate_is_refused_on_another_n(self):
        # RED before the scope check: the n=31 lower-bound certificate was ACCEPTED on the n=9
        # atlas and priced its rows (measured 2026-09-25, TR12_XA_CD=ONE-SIDED:lower-bound). The
        # same certificate without `scope` must still price, so the check is not refuse-all.
        import json
        S = _load("solve")
        d = tempfile.mkdtemp(prefix="w0dscope_")
        self.addCleanup(shutil.rmtree, d, True)

        def cert(scope):
            doc = {"type": "roae-w0d-node-mapping-certificate", "version": 1,
                   "mapping": {"kind": "lower-bound", "nodes_per_t_unit": "1/1", "residual": 0,
                               "formula": "TEST", "law": "TEST"},
                   "measured": {"n": [31], "verdict_line": "TEST"},
                   "provenance": {"engine_git": "FIXTURE:tests.py"}}
            if scope is not None:
                doc["scope"] = {"n": scope}
            p = os.path.join(d, "c%s.json" % scope)
            with open(p, "w") as fh:
                json.dump(doc, fh)
            return p
        A = {"n": 9, "N_total": "24", "type": "branch-atlas", "space": "fixture",
             "t_root_t_units": "1001", "layers": [{"k": 0, "flow": "24"}],
             "branch_atlas": [{"global_pair": 1, "entry": 17, "exit": 0, "solutions": "24",
                               "walks": 24, "prefixes_t_units": "1000",
                               "t_source": "t-ladder"}]}
        verdicts = {}
        for scope in (31, 9, None):
            cost = {"nodes_per_sec": S._ExactAnchor("1"), "usd_per_hour": S._ExactAnchor("1"),
                    "budget_usd": S._ExactAnchor("1000"), "hedge": S._ExactAnchor("1"),
                    "work_factor": S._ExactAnchor("1"), "node_mapping_cert": cert(scope),
                    "note": "test"}
            out = os.path.join(d, "o%s" % scope)
            os.makedirs(out)
            _tsv, md, verdict, _g = S.atlas_emit_xa(A, out, cost=cost, atlas_path="a.json")
            verdicts[scope] = verdict
            if scope == 31:
                with open(md) as fh:
                    self.assertIn("scoped to n=31", fh.read())
        self.assertEqual(verdicts[31], "PENDING:W0-D-node-mapping")
        self.assertEqual(verdicts[9], "ONE-SIDED:lower-bound")
        self.assertEqual(verdicts[None], "ONE-SIDED:lower-bound")

    def test_a_reduced_n_atlas_is_refused_as_the_cross_check(self):
        # The producer's optional atlas cross-check refuses anything but the n=31 space, BEFORE
        # enumerating, and writes no certificate.
        import io, contextlib, json
        S = _load("solve")
        d = tempfile.mkdtemp(prefix="w0dlb_")
        self.addCleanup(shutil.rmtree, d, True)
        a = os.path.join(d, "a9.json")
        with open(a, "w") as fh:
            json.dump({"n": 9, "fmass": [1], "branch_atlas": []}, fh)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc = S.xa_w0d_lower_bound_cert(os.path.join(d, "c.json"), a)
        self.assertEqual(rc, 2, buf.getvalue())
        self.assertIn("XA_W0D_LB_CERT=ERROR:atlas-is-not-the-n31-production-space",
                      buf.getvalue().splitlines())
        self.assertFalse(os.path.exists(os.path.join(d, "c.json")))


class TestQ767Q3TokenGateAndChunkFailLine(unittest.TestCase):
    """Q-767 items (1) and (4), on a real n=9 atlas built by solve.c.

    (1) atlas_selftest's "Q3: verdict tokens emitted" gate read only the parent TR12_Q3. With the
    Q3 name forced to the King Wen claim at n=9 (the KW-naming path misfiring), TR12_Q3 and the
    reader both still PASS and the gate stayed green; it must now read the KW leg and fail.
    (4) a chunk-write failure printed KC_SCAN_CHUNK=FAIL twice; exactly one line is the contract.
    A build failure is a test FAILURE, never a skip."""

    HERE = os.path.dirname(os.path.abspath(__file__))
    GATE = "Q3: verdict tokens emitted"

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="q767_")
        cls.sbin = os.path.join(cls.tmp, "solve_q767")
        cls.atlas = os.path.join(cls.tmp, "atlas9.json")
        cls.fdir, cls.gdir, cls.tdir = (os.path.join(cls.tmp, x) for x in ("f", "g", "t"))
        src = os.environ.get("ROAE_TESTS_SOLVE_SRC", "solve.c")
        r = subprocess.run(["gcc", "-O1", "-pthread", "-fopenmp", "-o", cls.sbin, src,
                            "-lm", "-lz"], capture_output=True, text=True)
        cls.build_err = "gcc rc %d: %s" % (r.returncode, r.stderr[-2000:])
        cls.build_ok = r.returncode == 0 and os.path.exists(cls.sbin)
        if not cls.build_ok:
            return
        for argv in ([cls.sbin, "--kc-build", cls.fdir, "--f1-pairs", "9"],
                     [cls.sbin, "--kc-g-build", cls.gdir, "--f1-pairs", "9"],
                     [cls.sbin, "--kc-t-build", cls.fdir, cls.tdir],
                     [cls.sbin, "--kc-scan", cls.fdir, cls.gdir, cls.atlas, "--kc-tdir", cls.tdir,
                      "--kc-raw"]):
            r = subprocess.run(argv, capture_output=True, text=True)
            if r.returncode != 0:
                cls.build_ok = False
                cls.build_err = "%s: rc %d\n%s" % (" ".join(argv[1:3]), r.returncode,
                                                   r.stdout[-1500:])
                return
        cls.build_ok = os.path.exists(cls.atlas)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def setUp(self):
        self.assertTrue(self.build_ok, self.build_err)

    def _selftest(self, S):
        import io, contextlib
        buf = io.StringIO()
        trace = os.path.join(self.HERE, "scripts", "tr12_expected", "n9", "a2_q3.txt")
        with contextlib.redirect_stdout(buf):
            rc = S.atlas_selftest(self.atlas, q3_trace=trace)
        out = buf.getvalue()
        gate = [l for l in out.splitlines() if l.startswith("[atlas-consumer] " + self.GATE)]
        self.assertEqual(1, len(gate), out)
        return rc, gate[0], out

    def test_positive_control_the_real_n9_q3_leg_passes(self):
        S = _load("solve")
        rc, gate, out = self._selftest(S)
        self.assertTrue(gate.rstrip().endswith("PASS"), out)
        # No --atlas-walks here, so the consumer's verdict is SKIP:no-brute-force-walks by design;
        # what this control needs is that every gate that DID run passed.
        self.assertRegex(out, r"(?m)^\[atlas-consumer\] \d+ gate\(s\) run, 0 failure\(s\)$", out)
        self.assertIn("ATLAS_CONSUMER=SKIP:no-brute-force-walks", out.splitlines(), out)

    def test_a_kw_name_forced_at_n9_turns_the_token_gate_red(self):
        # RED before: the gate compared TR12_Q3 (still PASS here) to "PASS" and printed PASS.
        from unittest import mock
        S = _load("solve")
        forced = lambda steps, n: ("q3_profile_kw.tsv", "PASS", "forced by the Q-767 red test")
        with mock.patch.object(S, "atlas_q3_name", forced):
            rc, gate, out = self._selftest(S)
        self.assertIn("FAIL", gate, "the Q3 token gate stayed green with TR12_Q3_KW=PASS at n=9:\n"
                      + out)
        self.assertIn("TR12_Q3_KW=PASS", gate)
        self.assertRegex(out, r"(?m)^\[atlas-consumer\] \d+ gate\(s\) run, [1-9]\d* failure\(s\)$", out)
        self.assertIn("ATLAS_CONSUMER=FAIL", out.splitlines(), out)

    def _chunk(self, outp):
        r = subprocess.run([self.sbin, "--kc-scan", self.fdir, self.gdir, outp,
                            "--kc-layers", "0", "2"], capture_output=True, text=True)
        return r.returncode, r.stdout.splitlines(), r.stdout + r.stderr

    def test_a_failed_chunk_write_prints_the_fail_token_exactly_once(self):
        # RED before: two KC_SCAN_CHUNK=FAIL lines (solve.c write-failure else + the crc == 2 line).
        rc, lines, out = self._chunk(os.path.join(self.tmp, "no", "such", "dir", "chunk.json"))
        self.assertEqual(2, rc, out)
        self.assertEqual(1, lines.count("KC_SCAN_CHUNK=FAIL"), out)
        self.assertFalse([l for l in lines if l.startswith("KC_SCAN_CHUNK=")
                          and l != "KC_SCAN_CHUNK=FAIL"], out)

    def test_positive_control_a_written_chunk_prints_ok_exactly_once(self):
        rc, lines, out = self._chunk(os.path.join(self.tmp, "chunk_ok.json"))
        self.assertEqual(0, rc, out)
        self.assertEqual(1, lines.count("KC_SCAN_CHUNK=OK"), out)
        self.assertFalse([l for l in lines if l.startswith("KC_SCAN_CHUNK=")
                          and l != "KC_SCAN_CHUNK=OK"], out)


class TestQ782LadderShaRowChecksLayerIdentity(unittest.TestCase):
    """Q-782 (found and reproduced by Opus RR, 2026-09-24).

    scripts/tr12_repro.sh's ladder_sha_row checked layer COUNT, not layer IDENTITY: it passed when
    n+1 layers were digested and each matched the sidecar beside it, never asking which indices
    they were. And `solve --f1c5-layer-sha DIR` skipped a layer it could not read with rc 0. So at
    n=9 a ladder with g_layer_09 gone and a stray g_layer_10 (a copy of 08 with its sidecar) got
    LADDER_SHA_CHECK=OK, and so did one with g_layer_05 at mode 000 plus that stray.

    The battery's OWN function is extracted and executed (never a copy), with only row_begin and
    row_end stubbed, on a real n=9 g ladder built by solve.c. Red before the fix: the three
    tampered ladders print OK and the DIR form exits 0. A build failure is a test FAILURE."""

    HERE = os.path.dirname(os.path.abspath(__file__))

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.mkdtemp(prefix="q782_")
        cls.sbin = os.path.join(cls.tmp, "solve_q782")
        cls.gdir = os.path.join(cls.tmp, "g")
        src = os.environ.get("ROAE_TESTS_SOLVE_SRC", "solve.c")
        r = subprocess.run(["gcc", "-O1", "-pthread", "-fopenmp", "-o", cls.sbin, src,
                            "-lm", "-lz"], capture_output=True, text=True)
        cls.build_err = "gcc rc %d: %s" % (r.returncode, r.stderr[-2000:])
        cls.build_ok = r.returncode == 0 and os.path.exists(cls.sbin)
        if not cls.build_ok:
            return
        r = subprocess.run([cls.sbin, "--kc-g-build", cls.gdir, "--f1-pairs", "9"],
                           capture_output=True, text=True)
        cls.build_ok = r.returncode == 0 and all(
            os.path.exists(os.path.join(cls.gdir, "g_layer_%02d.bin" % k)) and
            os.path.exists(os.path.join(cls.gdir, "g_layer_stats_%02d.json" % k))
            for k in range(10))
        cls.build_err = "--kc-g-build rc %d\n%s" % (r.returncode, r.stdout[-1500:])
        with open(os.path.join(cls.HERE, "scripts", "tr12_repro.sh"), encoding="utf-8") as fh:
            m = re.search(r"(?ms)^ladder_sha_row\(\)\{.*?^\}$", fh.read())
        cls.fn = m.group(0) if m else None

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def setUp(self):
        self.assertTrue(self.build_ok, self.build_err)
        self.assertIsNotNone(self.fn, "scripts/tr12_repro.sh has no ladder_sha_row; nothing exercised")

    def _ladder(self, name):
        d = os.path.join(self.tmp, name)
        shutil.copytree(self.gdir, d)
        return d

    def _stray10(self, d):
        # layer 10 = a copy of 08 WITH its sidecar, so it digests and matches like a real layer
        shutil.copy(os.path.join(d, "g_layer_08.bin"), os.path.join(d, "g_layer_10.bin"))
        shutil.copy(os.path.join(d, "g_layer_stats_08.json"), os.path.join(d, "g_layer_stats_10.json"))

    def _drop(self, d, k):
        os.remove(os.path.join(d, "g_layer_%02d.bin" % k))
        os.remove(os.path.join(d, "g_layer_stats_%02d.json" % k))

    def _row(self, d):
        work = tempfile.mkdtemp(dir=self.tmp)
        script = ('row_begin(){ RAW="$WORK/raw.txt"; : > "$RAW"; }\n'
                  'row_end(){ echo "ROW_RC=$2" >> "$RAW"; }\n'
                  'eval "$FN"\n'
                  'ladder_sha_row a2_gsha TR12_GSHA "$LDIR" g_layer\n'
                  'cat "$RAW"\n')
        env = dict(os.environ, FN=self.fn, WORK=work, SOLVE=self.sbin, N_PAIRS="9", LDIR=d)
        r = subprocess.run(["bash", "-c", script], capture_output=True, text=True, env=env)
        lines = r.stdout.splitlines()
        verdict = [l for l in lines if l.startswith("LADDER_SHA_CHECK=")]
        self.assertEqual(1, len(verdict), r.stdout + r.stderr)
        return verdict[0], lines, r.stdout + r.stderr

    def test_positive_control_an_intact_n9_ladder_is_ok(self):
        v, lines, out = self._row(self._ladder("intact"))
        self.assertEqual("LADDER_SHA_CHECK=OK", v, out)
        self.assertIn("ROW_RC=0", lines, out)
        self.assertFalse([l for l in lines if l.startswith("layer ")], out)

    def test_last_layer_replaced_by_a_stray_10_fails(self):
        d = self._ladder("swap09")
        self._drop(d, 9); self._stray10(d)
        v, lines, out = self._row(d)
        self.assertEqual("LADDER_SHA_CHECK=FAIL", v, out)       # RED before: OK
        self.assertIn("layer g_layer_09.bin  MISSING", lines, out)
        self.assertTrue([l for l in lines if l.startswith("layer g_layer_10.bin  STRAY")], out)

    def test_missing_middle_layer_with_a_stray_10_fails(self):
        d = self._ladder("drop05")
        self._drop(d, 5); self._stray10(d)
        v, lines, out = self._row(d)
        self.assertEqual("LADDER_SHA_CHECK=FAIL", v, out)       # RED before: OK
        self.assertIn("layer g_layer_05.bin  MISSING", lines, out)
        self.assertTrue([l for l in lines if l.startswith("layer g_layer_10.bin  STRAY")], out)

    def test_unreadable_layer_with_a_stray_10_fails(self):
        d = self._ladder("chmod05")
        p = os.path.join(d, "g_layer_05.bin")
        self._stray10(d); os.chmod(p, 0)
        try:
            # precondition: mode 000 must actually deny the read (it does not for root)
            self.assertFalse(os.access(p, os.R_OK), "mode 000 is still readable (running as root?); "
                             "this case cannot be exercised here")
            v, lines, out = self._row(d)
        finally:
            os.chmod(p, 0o644)
        self.assertEqual("LADDER_SHA_CHECK=FAIL", v, out)       # RED before: OK
        self.assertIn("layer g_layer_05.bin  UNREADABLE", lines, out)

    def test_dir_form_exits_2_on_an_unreadable_layer_and_prints_the_rest_unchanged(self):
        d = self._ladder("chmoddir")
        ok = subprocess.run([self.sbin, "--f1c5-layer-sha", d], capture_output=True, text=True)
        self.assertEqual(0, ok.returncode, ok.stdout + ok.stderr)
        p = os.path.join(d, "g_layer_05.bin")
        os.chmod(p, 0)
        try:
            self.assertFalse(os.access(p, os.R_OK), "mode 000 is still readable (running as root?)")
            r = subprocess.run([self.sbin, "--f1c5-layer-sha", d], capture_output=True, text=True)
        finally:
            os.chmod(p, 0o644)
        self.assertEqual(2, r.returncode, r.stdout + r.stderr)    # RED before: 0, layer skipped
        self.assertIn("ERROR: cannot open %s" % p, r.stderr)
        want = [l for l in ok.stdout.splitlines() if "/g_layer_05.bin " not in l]
        self.assertEqual(want, r.stdout.splitlines())


if __name__ == "__main__":
    unittest.main(verbosity=2)
