# F5 evidence bundle — the orientation-layer battery (TR-1 §7)

Raw outputs and the exact-fiber instrument behind [TR-1](../../TR1_EIGHT_CENTURIES_MEASURED.md)
§"The orientation layer, measured" (2026-07-05). Instrument: public `solve.c` / `solve.py` @
`db66657` (`SOLVE_KNUTH_SCORE_F5`, [`--f5-verify`](../../../documentation/SOLVE_C_CLI.md#--f5-verify), `SOLVE_F5_TESTVEC`, `vdb_nucorient` /
`--vdb-verify`).

| File | What it is |
|---|---|
| `f5_modec_fiber.py` | Mode C (dispositive): exact enumeration of the full 1,720,320-vector **C4-oriented** orientation fiber of King Wen's pair sequence (slot-0 orientation fixed per the frozen spec §3) + exact scoring of all 11 frozen functionals. *Scope note 2026-07-26: the pair-only-C4 fiber (both slot-0 orientations) is 2,703,360 vectors; the re-check on it is `f5_pair_only_fiber.py` in this directory (published 2026-09-04) and TR-1 §7 v1.16* |
| `f5_modec_fiber.out` | Archived Mode C output: exact histograms, two-sided p-values, structure gates, convention control |
| `f5_pair_only_fiber.py` | The **two-opening re-check** (2026-07-26): extends the Mode C instrument from the C4-oriented fiber to the **pair-only-C4 fiber** — both slot-0 orientations, 1,720,320 forward + 983,040 reversed = **2,703,360** vectors — and re-scores all 11 frozen functionals exactly on every one. This is the instrument [TR-1](../../TR1_EIGHT_CENTURIES_MEASURED.md) §7 v1.16 promised; published 2026-09-04 |
| `f5_pair_only_fiber.out` | Its archived output: fiber sizes, the 400-sample cross-implementation + C5 + C3=776 gate (200 of them slot-0-reversed), the 11-functional table on the enlarged fiber, and the `vdb_nuc` tail detail |
| `f5_pair_only_verify30.py` | Companion check: the two X=30 vectors are re-scored by reconstructing each full 64-hexagram sequence and calling public `solve.py` `vdb_nucorient` on it **directly** — not through the per-slot decomposition the fiber scan uses — with permutation, C5-multiset and C3=776 checks on each |
| `f5_pair_only_verify30.out` | Its archived output: both maximal vectors, their bit patterns, opening `(0, 63)`, full `f5_all` scores and full sequences |
| `f5_ground_truth.py` | Independent pure-Python implementation of the 11 functionals (two-language gate vs the `solve.c` scorer; #11 delegates to `solve.py vdb_nucorient`, the single implementation) |
| `f5_tier1.out` | Mode U (unconditional population): 2×10⁹ weighted Knuth probes, per-functional below/at/above masses + full `f5_hist` histograms (Spot D64, 2026-07-05) |
| `f5_corpus_gate.out` | Corpus + gauge control values (KW / Mawangdui / [Jing Fang](../../../documentation/CITATIONS.md#jingfang) / upside-down / back-to-front), on-VM C scorer. Mawangdui row corrected 2026-07-05 (the on-VM run scored an erroneous array; see the in-file note + CITATIONS.md errata) |
| `c230_launch.log` | VM launch/teardown log for the tier-1 run (≈5 min VM life) |

## Reproduce

All commands below were exercised on 2026-07-05 before publication; the Mode C rerun
reproduced `f5_modec_fiber.out` **byte-identically** (~11 s, needs numpy).

⚠ **Every `--estimate-knuth` command in this document requires a stack limit of at least 16 MB** — `ulimit -s 16384` suffices, and `ulimit -s unlimited` is one way to satisfy it, not the requirement itself. Under the default 8 MB stack the estimator does not start: `main` allocates a ~7.23 MB frame and `estimate_tree_knuth` a further ~1.02 MB (since 2026-08-21 the binary refuses with an actionable message; previously a bare SIGSEGV). *(Added 2026-08-21, an execution-lane finding — `scripts/exec_lane.sh` executes every documented command on a default environment; the same-day warning propagation (`1e4bd04a`) covered the four estimator guides but missed this file.)* *(Narrowed 2026-09-02, Codex V2-F08 #4, prose batch P37: `ulimit -s unlimited` is a **sufficient** setting that had been published as a **necessary** one — and one that a host or container with a hard stack cap cannot even apply, so the published requirement was a false blocker there. `solve.c`'s `--estimate-knuth` preflight tests `rlim_cur != RLIM_INFINITY && rlim_cur < 16UL*1024*1024` and its message names ">= 16 MB". EXECUTED under TR-9 v1.24 on a locally built binary: `ulimit -s 8192` refuses and exits 1, `ulimit -s 16384` runs the estimator to completion. `solve.c`'s own remedy line still prescribes only `unlimited` and is queued to offer both. This is the sibling propagation of the narrowing TR-9 made on 2026-09-02 and reported but did not sweep.)*

```bash
# KW ground-truth gates (repo root):
./solve --f5-verify                 # 11/11 OK
python3 solve.py --vdb-verify       # vdb_nucorient: 29 OK

# Mode C — exact fiber analysis (dispositive; this directory):
cd reports/evidence/f5
python3 f5_modec_fiber.py > /tmp/f5_modec_fiber_rerun.out
diff f5_modec_fiber.out /tmp/f5_modec_fiber_rerun.out   # byte-identical
python3 f5_ground_truth.py                              # 11/11 OK, PASS

# The 2026-07-26 two-opening re-check (this directory; both exercised 2026-09-04
# from this published copy, byte-identical to the archived output):
python3 f5_pair_only_fiber.py    > /tmp/f5_pair_only_fiber_rerun.out      # ~21 s, needs numpy
diff f5_pair_only_fiber.out    /tmp/f5_pair_only_fiber_rerun.out          # byte-identical
python3 f5_pair_only_verify30.py > /tmp/f5_pair_only_verify30_rerun.out   # ~56 s
diff f5_pair_only_verify30.out /tmp/f5_pair_only_verify30_rerun.out       # byte-identical

# Mode U — tier-1 population run (as archived in f5_tier1.out; 64-core VM, ~4 min):
SOLVE_KNUTH_SCORE_F5=1 SOLVE_KNUTH_F5_HIST=1 SOLVE_THREADS=64 \
  ./solve --estimate-knuth 2000000000

# Corpus/gauge control values (explicit-sequence hook):
SOLVE_KNUTH_SCORE_F5=2 SOLVE_F5_TESTVEC="<h0,...,h63>" ./solve
```

Every number in TR-1 §7 traces to `f5_modec_fiber.out`, `f5_tier1.out`, or
`f5_corpus_gate.out`; two-sided p = min(1, 2·min(P(X≤kw), P(X≥kw))), atom-inclusive.

*Provenance note: all four `.py` files are the archived private originals with a
portability edit — the `solve.py` import path is located relative to this directory
(repo root = `../../..`) instead of the original machine-absolute path. The byte-identical
reruns above were performed with the edited (published) copies. ⚠ The two
`f5_pair_only_*` files carry **one further edit each, in comment text only**: a module
docstring was added to `f5_pair_only_verify30.py` (the private original, named
`verify30.py`, had none) and the docstring of `f5_pair_only_fiber.py` lost the line
"Scratchpad instrument for the F1 retraction fix; not a repo file." — true when written in
July, false the moment the file shipped — and gained the attribution and usage lines. No
executable line differs from the private original in either file, which is why their
archived outputs still reproduce byte-for-byte.*

*Scope of what the two-opening re-check changes, stated plainly: it does **not** revise the
Mode C figures above, which are correct for the fiber they are computed on. It enlarges the
fiber. On the enlarged fiber King Wen's `vdb_nuc` = 29 is **no longer the maximum** — two
vectors reach 30, both in the reversed (o0 = 1) branch, both opening `(0, 63)` — and the
published one-sided P(X ≥ 29) = 6.9754×10⁻⁶ becomes 30/2,703,360 = 1.109730×10⁻⁵ one-sided,
2.219460×10⁻⁵ two-sided. TR-1 §7 and [CLAIMS_DECIDED.md](../../../documentation/CLAIMS_DECIDED.md)
carry that correction; these files are its evidence.*

*Attribution: the 11 functionals are anchored to [Cook 2006](../../../documentation/CITATIONS.md#cook2006) (f1), [Moore 1989](../../../documentation/CITATIONS.md#moore1989) (f2, f3), the
Dazhuan/Xici yang-precedence reading via [Schulz 1990](../../../documentation/CITATIONS.md#schulz1990-motifs) and Cook 2006 (f4), [Davis 2012](../../../documentation/CITATIONS.md#davis2012) (f5),
[Shao Yong](../../../documentation/CITATIONS.md#shaoyong) / [Leibniz 1703](../../../documentation/CITATIONS.md#leibniz1703) (f6), [Chan 2026](../../../documentation/CITATIONS.md#chan2026) (f7), [McKenna & McKenna 1975](../../../documentation/CITATIONS.md#mckenna-mckenna1975) (f8–f10), and [Van den
Berghe](../../../documentation/CITATIONS.md#vandenberghe1999) c. 1999–2002 (f11, the nuclear orientation rule). Operationalizations, fiber method,
and analysis: Claude (Fable), 2026-07-05; errors are Claude's — corrections invited.*
