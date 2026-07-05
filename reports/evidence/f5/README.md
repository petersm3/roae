# F5 evidence bundle — the orientation-layer battery (TR-1 §7)

Raw outputs and the exact-fiber instrument behind [TR-1](../../TR1_EIGHT_CENTURIES_MEASURED.md)
§"The orientation layer, measured" (2026-07-05). Instrument: public `solve.c` / `solve.py` @
`db66657` (`SOLVE_KNUTH_SCORE_F5`, `--f5-verify`, `SOLVE_F5_TESTVEC`, `vdb_nucorient` /
`--vdb-verify`).

| File | What it is |
|---|---|
| `f5_modec_fiber.py` | Mode C (dispositive): exact enumeration of the full 1,720,320-vector orientation fiber of King Wen's pair sequence + exact scoring of all 11 frozen functionals |
| `f5_modec_fiber.out` | Archived Mode C output: exact histograms, two-sided p-values, structure gates, convention control |
| `f5_ground_truth.py` | Independent pure-Python implementation of the 11 functionals (two-language gate vs the `solve.c` scorer; #11 delegates to `solve.py vdb_nucorient`, the single implementation) |
| `f5_tier1.out` | Mode U (unconditional population): 2×10⁹ weighted Knuth probes, per-functional below/at/above masses + full `f5_hist` histograms (Spot D64, 2026-07-05) |
| `f5_corpus_gate.out` | Corpus + gauge control values (KW / Mawangdui / Jing Fang / upside-down / back-to-front), on-VM C scorer. Mawangdui row corrected 2026-07-05 (the on-VM run scored an erroneous array; see the in-file note + CITATIONS.md errata) |
| `c230_launch.log` | VM launch/teardown log for the tier-1 run (≈5 min VM life) |

## Reproduce

All commands below were exercised on 2026-07-05 before publication; the Mode C rerun
reproduced `f5_modec_fiber.out` **byte-identically** (~11 s, needs numpy).

```bash
# KW ground-truth gates (repo root):
./solve --f5-verify                 # 11/11 OK
python3 solve.py --vdb-verify       # vdb_nucorient: 29 OK

# Mode C — exact fiber analysis (dispositive; this directory):
cd reports/evidence/f5
python3 f5_modec_fiber.py > /tmp/f5_modec_fiber_rerun.out
diff f5_modec_fiber.out /tmp/f5_modec_fiber_rerun.out   # byte-identical
python3 f5_ground_truth.py                              # 11/11 OK, PASS

# Mode U — tier-1 population run (as archived in f5_tier1.out; 64-core VM, ~4 min):
SOLVE_KNUTH_SCORE_F5=1 SOLVE_KNUTH_F5_HIST=1 SOLVE_THREADS=64 \
  ./solve --estimate-knuth 2000000000

# Corpus/gauge control values (explicit-sequence hook):
SOLVE_KNUTH_SCORE_F5=2 SOLVE_F5_TESTVEC="<h0,...,h63>" ./solve
```

Every number in TR-1 §7 traces to `f5_modec_fiber.out`, `f5_tier1.out`, or
`f5_corpus_gate.out`; two-sided p = min(1, 2·min(P(X≤kw), P(X≥kw))), atom-inclusive.

*Provenance note: the two `.py` files are the archived private originals with one
portability edit each — the `solve.py` import path is located relative to this directory
(repo root = `../../..`) instead of the original machine-absolute path. No other change;
the byte-identical rerun above was performed with the edited (published) copies.*

*Attribution: the 11 functionals are anchored to Cook 2006 (f1), Moore 1989 (f2, f3), the
Dazhuan/Xici yang-precedence reading via Schulz 1990 and Cook 2006 (f4), Davis 2012 (f5),
Shao Yong / Leibniz 1703 (f6), Chan 2026 (f7), McKenna & McKenna 1975 (f8–f10), and Van den
Berghe c. 1999–2002 (f11, the nuclear orientation rule). Operationalizations, fiber method,
and analysis: Claude (Fable), 2026-07-05; errors are Claude's — corrections invited.*
