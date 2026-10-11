# Q-OY1 / Q-992 evidence bundle — a pre-registered null result (2026-10-09)

**What this is.** The record of two pre-registered tests of the King Wen (KW) sequence. Both returned
the pre-registered verdict **UNINFORMATIVE**: on these two statistics, King Wen does not stand out
from the populations it was compared with. The write-up is in
[LITERATURE_RULES_POPULATION_TESTS.md](../../../documentation/LITERATURE_RULES_POPULATION_TESTS.md)
§"Addendum (2026-10-09): two pre-registered tests that came back UNINFORMATIVE", and the corrections
entry is [CORRECTIONS.md](../../../documentation/CORRECTIONS.md) CX-331.

- **Q-992** asks about the six adjacent pairs of hexagrams whose upper and lower trigrams are
  exchanged, which 韩仲民 (Han Zhongmin) 1984 counts in King Wen. The registered statistic is `X`, the
  number of such exchanges *across* a pair boundary. King Wen has `X = 0`.
- **Q-OY1** asks about the sixteen hexagrams that 欧阳维诚 (Ouyang Weicheng) 1993 treats as an
  order-16 subgroup. The registered statistic is `D`, a measure of how evenly the eight pair slots
  holding that subgroup are spread around the sequence. King Wen has `D = 94`.

## The pre-registration, and what was changed in the public copy

| item | value |
|---|---|
| frozen file (private) | `review_2026_09_27/PREREG_QOY1_Q992_2026_10_09.md`, 32,650 bytes |
| sha256 of the frozen original | `5e15192fc8e4a5283dddb74c7918e32dca2581e414a8e23e2db5defc0c3651fa` |
| locked | committed privately 2026-10-09 06:51:38 UTC (commit `0a83ac56`); lock-ledger entry 2026-10-09 06:52:17 UTC |
| first King Wen evaluation | 2026-10-09 07:04:39 UTC (§9-A2) |
| first recorded estimator run | started 2026-10-09 07:20 UTC |
| public copy | [PREREGISTRATION.md](PREREGISTRATION.md), 32,350 bytes |
| sha256 of the public copy | `005a0dab66f77f5921e2cad9260a0310874cfc5ebd6e56a27195e67fc8d23fc2` |
| the two §9 annotations, verbatim | [PREREGISTRATION_S9_ANNOTATIONS.md](PREREGISTRATION_S9_ANNOTATIONS.md), sha256 `ecc50dc7a412d3f83bff169904268557b624ed0706b7ecbfdde49bb82ee9979c` |

All four digests (frozen original, public copy, annotations, check script) are also recorded on
[PREREGISTRATION_ESCROW.md](../../../documentation/PREREGISTRATION_ESCROW.md) §"2026-10-09 — the Q-OY1 / Q-992 pre-registration: frozen privately before measurement, published with its result".
They were published there with the result, not before the run.

**The public copy is not byte-identical to the frozen file.** Two passages were removed, and nothing
else was changed:

1. §7.6 ("Where, and cost") is replaced by the single line `### §7.6 [cost section omitted from the public copy]`.
2. The last sentence of the header box pointed to that section and stated a spending limit. It is
   replaced by `[cost sentence omitted from the public copy]`.

Because of these removals the public copy's digest differs from the frozen one, and a reader cannot
recompute `5e15192f…` from this repository. The frozen digest is given so that the file can be checked
if it is ever disclosed. Paths in the copy that point into the private repository are left as written.
`diff` against the frozen file shows exactly two hunks: line 30 and lines 400–404 (five lines become one).

**What the timing evidence is.** As the registration itself says in its header box, freeze timing for a
pre-registration kept in a private repository is **attested, not checkable by an outside reader** (the
same limit [PREREG_CLASSA_QUERY_SET.md](../../../documentation/PREREG_CLASSA_QUERY_SET.md) §0 states).
The commit and ledger times above come from the private repository's history. They are a claim, not a
proof. What a reader *can* check is that every rule applied to the results below is the one written in
the public copy, and that [analyze.py](analyze.py) re-derives every verdict token from the shipped
outputs.

## Contents

| file | what it is |
|---|---|
| [TOKENS.txt](TOKENS.txt) | every result token (139 `KEY=value` lines); the verdicts are `Q992_VERDICT` and `QOY1_VERDICT` |
| `N1_A.out`, `N1_B.out` | unfiltered stdout+stderr of the two C1–C5 runs (10¹⁰ weighted-Knuth probes each) |
| `N1P_A.out`, `N1P_B.out` | the same for the two runs with the C6/C7 slot pins (5×10⁹ probes each) |
| [n0_exact.py](n0_exact.py), `n0_exact.out` | the exact pair-only null laws (§4.1), the sampler cross-check, the uniform-64 reference, the corpus controls |
| [analyze.py](analyze.py) | applies the frozen §5 rules to the files above; its stdout is `TOKENS.txt` |
| `gates.txt` | the pre-run gates (§7.2) |
| [prereg_qoy1_q992_defcheck.py](prereg_qoy1_q992_defcheck.py), `defcheck.out` | the freeze-time check of the hexagram-set facts in §3 (it never reads King Wen's order) |
| `qoy_gate_full.out`, `qoy_gate_mutant.out` | the two-language gate (`solve.py` against `solve.c`) and its parity mutant, which must fail |
| [instrument_pin_4b590dfc.patch](instrument_pin_4b590dfc.patch) | the exact instrument the runs used (see below); sha256 `e4dd40aeb61258d02e9897da4d2f5af0dc7b82673c9f91c827314e7896588519` |

**Scrubbed.** These files were copied from the private record unchanged. Before copying, every file
was checked for network addresses, machine and resource names, account identifiers and costs, and none
was found. Left out of this bundle: the machine-lifecycle log and the per-machine driver files (they
name the temporary machine), and the two calibration runs, which measured probe speed and computed no
Q-OY1/Q-992 statistic (deviation D4 of the measurement). `gates.txt` records the compiler, the CPU
model and the thread count. `prereg_qoy1_q992_defcheck.py` is the frozen script, unchanged. It is
covered by the same lock-ledger entry (sha256
`1540879aa119724f380d5bd191652bea46dc330e85cdf5556c4b9a86c89b7bf7`), and its line 7 hard-codes the
author's local checkout path. Change that path to your own checkout before running it.

## The instrument, and why the shipped code is arranged differently

The runs used a staged, uncommitted instrument: tree `4b590dfcbd0024beefd2bf354949e66ef95c951b` on
public commit `11003eddd3a9453b24c68c8b0c773930b45467f4`, with `solve.c` sha256 `60937db1…`,
`solve.py` `a0ed4150…` and `tests.py` `f91b3e11…` (§9-A2; deviation D1: the pin is a tree and file
digests, not a commit). `instrument_pin_4b590dfc.patch` reproduces those three files exactly:

```bash
git worktree add --detach /tmp/qoy-pin 11003eddd3a9453b24c68c8b0c773930b45467f4
cd /tmp/qoy-pin && git apply /path/to/reports/evidence/qoy1_q992/instrument_pin_4b590dfc.patch
sha256sum solve.c solve.py tests.py   # 60937db1…  a0ed4150…  f91b3e11…
```

The committed code carries the same scorer, moved so that no line that a document cites by number
changes. In `solve.c` the scorer functions sit just before `solve_env_preflight`, and the hooks into
the estimator, the environment switch and the `--qoy-verify` dispatch are added to existing lines. In
`solve.py` the block sits just before `def main()`, byte-identical except that its `import verify` falls
back to a restatement of `verify.py`'s `_cuo` and `_zong` when `solve.py` is imported without `verify.py` beside it, and except that `qoy_c1c4_draw`'s precondition on pair 1 is an explicit `ValueError` where the pinned block has an `assert` (CX-331 item 8) (see the corrections entry). The only behavioural difference is
the order of two independent accumulators inside one probe. The equivalence check is in the
corrections entry: both builds print byte-identical `--qoy-verify` output on King Wen plus the 10⁵
gate orderings, and byte-identical `QOY_*`, `qoy_hist` and `qoy_occ` lines on a seeded estimator run.

## Reproduce

**The exact pair-only null, on a laptop** (Python 3, standard library only; it imports this
repository's `solve.py`). From the repository root:

```bash
python3 reports/evidence/qoy1_q992/n0_exact.py . > n0_exact.mine
diff n0_exact.mine reports/evidence/qoy1_q992/n0_exact.out && echo N0_EXACT=REPRODUCED
```

It takes about seven minutes (419 s measured) on one core of the project's small orchestrator machine. It enumerates all C(31, 7) and C(32, 8) coset-0 slot sets, evaluates the inclusion–exclusion law of
`X`, and runs the two seeded 10⁶-draw checks. The exact laws, `E[X] = 11/31`, `E[D] = 224/3` and the
King Wen tails `p_two(X) = 1` and `p_two(D) = 438976/876525` are in its first lines.

**The verdicts from the shipped outputs** (about a second):

```bash
cd reports/evidence/qoy1_q992 && python3 analyze.py | diff - TOKENS.txt && echo TOKENS=REPRODUCED
```

**The two-language gate:** build with `gcc -O2 -fopenmp -o solve solve.c -lm -lpthread -lz`, then run
`python3 solve.py --qoy-gate ./solve` (it should print `QOY_VERIFY=PASS`), and both output digests should be
`52a83cac2fcf357779db1988a725dadedc20c2695e4697b4735d1600a65e00be`, the value in `qoy_gate_full.out`). The
pre-pin self-test quoted in §9-A1 as `e379e154…` is the same command with `--qoy-gate-skip-kw`; it prints
`QOY_GATE_PY_SHA256=e379e154fd762569765b64765f6ed23c5b444db46bf3e06e2a4d67e8ce991a9c` (re-run 2026-10-09).

**The population runs.** These need a multi-core machine for hours; the recorded runs took about
2 hours (N1) and 55 minutes (N1′) each, on 16 threads. Each needs `ulimit -s unlimited` and
`SOLVE_KNUTH_SCORE=1 SOLVE_KNUTH_SCORE_QOY=1`:

```bash
./solve --estimate-knuth 10000000000                                        # N1 half A (default seed)
SOLVE_KNUTH_SEED=8087609961813646905  ./solve --estimate-knuth 10000000000  # N1 half B
SOLVE_KNUTH_C67=1 SOLVE_KNUTH_SEED=7944743365876395449  ./solve --estimate-knuth 5000000000   # N1' half A
SOLVE_KNUTH_C67=1 SOLVE_KNUTH_SEED=15064022667821298811 ./solve --estimate-knuth 5000000000   # N1' half B
```

The estimator is multi-threaded, so a run's histogram is not bit-for-bit repeatable. A re-run should
agree with the shipped one within the printed standard errors.
