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

    def test_sat_import_assertions(self):
        r = subprocess.run([sys.executable, "-c", "import sat"], capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr[-300:])

if __name__ == "__main__":
    unittest.main(verbosity=2)
