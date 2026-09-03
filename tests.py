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
import os, random, re, shutil, struct, tempfile, hashlib

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
            self.skipTest("verify.c did not build: " + self.c_build_err)
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
            self.skipTest("verify.c did not build")
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
            self.skipTest("verify.c did not build: " + self.c_build_err)
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
            self.skipTest("verify.c did not build")
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
            self.skipTest("verify.c did not build")
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
    that withdrew it) and solve.py:1581 (the `--rules` banner printing the CX-02 framing
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
    RP-60347080) — and solve.c has no --expect-kw; verify.py's flag is the only
    instrument that promotes absence to a failure. A test asserting rc != 0 here would
    assert the shipped behaviour is wrong. This one pins what ships, and the C4 control
    shows the same verdict path DOES go red on a real constraint failure, so the PASS on
    the King-Wen-less fixture is a scoped PASS and not a verifier that passes everything.

    FIXTURES. Raw (uncompressed) ROAE artifacts, one record each. The non-King-Wen record
    is King Wen with one pair's orientation flipped, found by verify.py's per-record
    checks rather than guessed; it shares King Wen's CANONICAL key (same pair order), so
    a two-record artifact holding both is a duplicate-records FAIL — measured — which is
    why "the King Wen record deleted" is modelled as the one-record file.

    solve.c is behind the MASTER GATE and is not edited; the binary is built from the
    tracked source at -O1 (4.5 s measured on the 2-core orchestrator) into a temp dir. A
    build failure is a test FAILURE, not a skip.

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

    def _verify(self, path):
        """(rc, lines): every stdout line with \\r stripped and runs of whitespace
        collapsed, so `King Wen found:         No` is matched WHOLE as
        `King Wen found: No` and the verdict token is matched whole, never by shape."""
        if not self.build_ok:
            self.fail("solve.c did not build, so nothing was verified: " + self.build_err)
        r = subprocess.run([self.sbin, "--verify", path], capture_output=True, text=True)
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


if __name__ == "__main__":
    unittest.main(verbosity=2)
