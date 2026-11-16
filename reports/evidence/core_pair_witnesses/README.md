# Pinned SAT witnesses for two rule pairs: {parity, CC-N8} and {rhythm, CC-N8}

**2026-11-15 (Q-1133, Fable).** [CLAIM_TO_ARTIFACT.md](../../../documentation/CLAIM_TO_ARTIFACT.md) row 8
says the five-rule conflict has four minimal two-rule cores. Five rules give ten pairs. Four pairs are
unsatisfiable, each with a DRAT certificate in [reports/certificates/](../../certificates/README.md).
The other six must each be satisfiable for "four" to mean "exactly four". Four of those six were already
covered by archived orderings ([grand-strict.txt](../q7_witnesses/grand-strict.txt) and King Wen itself).
The two files here cover the remaining two.

Each file carries one `SEQ=` line of 64 hexagram values
([SPECIFICATION.md §H](../../../documentation/SPECIFICATION.md)), C4 anchor `63,0` first, in the same
format as [q7_witnesses/](../q7_witnesses/README.md).

**What a witness shows.** A SAT witness is an existence result for that one ordering: this ordering
satisfies C1, C2, C4, C5, C3 ≤ 776 and both rules of its pair. It says nothing about how many such
orderings exist, and nothing here is proved in Lean. The solver only found the ordering; the checks
below do not use a solver.

## Files

| file | sha256 | target | C3 | `sat.rule_scores` (parity, rhythm, gender, ccn4, ccn8) |
|---|---|---|---|---|
| `parity-ccn8.txt` | `5e81e2af688157b55ceebae98e3f47303cce81d1feb162dbe96900bbf224d88b` | `five-sub-parity+ccn8` | 736 | 0, 5, 2, 1, 0 |
| `rhythm-ccn8.txt` | `ccecda3e3ee47fb749456961428900af880b22265914a08a9ab5a37bd6ff77d5` | `five-sub-rhythm+ccn8` | 728 | 1, 0, 2, 1, 0 |

King Wen scores 2, 2, 2, 0, 0. Both orderings differ from King Wen (62 and 56 of 64 positions).

**Which space.** The four UNSAT certificates are statements over the C1∩C2∩C4∩C5-valid space. These
two witnesses also satisfy C3 ≤ 776 (the formula was built with `--with-c3`), so each pair is
satisfiable in that space and in the smaller C1–C5 space.

## The ten pairs

| pair | status | evidence |
|---|---|---|
| parity + rhythm | satisfiable | `grand-strict.txt` |
| parity + gender | satisfiable | `grand-strict.txt` |
| rhythm + gender | satisfiable | `grand-strict.txt` |
| CC-N4 + CC-N8 | satisfiable | King Wen |
| parity + CC-N8 | satisfiable | `parity-ccn8.txt` |
| rhythm + CC-N8 | satisfiable | `rhythm-ccn8.txt` |
| parity + CC-N4 | UNSAT | `core_parity_ccn4_unsat.drat.gz` |
| rhythm + CC-N4 | UNSAT | `core_rhythm_ccn4_unsat.drat.gz` |
| gender + CC-N4 | UNSAT | `core_gender_ccn4_unsat.drat.gz` |
| gender + CC-N8 | UNSAT | `core_gender_ccn8_unsat.drat.gz` |

The six "satisfiable" rows were re-scored together on 2026-11-15 with `sat.target_verdict(seq,
"five-sub-<a>+<b>", with_c3=True)`: each named ordering returns `ok=True` for its pair, and no archived
ordering returns `ok=True` for any of the four UNSAT pairs.

## Provenance: how each witness was produced (once)

Host: an 8-core x86-64 worker (gcc 13.3.0, Python 3.12.3); sources from `git archive` of public
`c6e36d5e`; `sat.py` sha256 `893f50848375305a11f50f182b33d4162eea73b39029817e6b4879bee68667c3`,
`solve.py` `2a8cdcb6db6a6ffd9fe23680b5c1b27e48cbeb109591c30b1eb5ff33d72c8cd7`, `solve.c`
`db33de17b9722d4151ebf9a24cfdc958e14a507e951fc982744283509b0d9be2`. Solver: **kissat 4.0.4** (binary
sha256 `7f4080c46bcdbc06df0dc332fcf813a15c988eec66b7175a7148bd7b95f85891`, the same binary hash as the
Q7 witnesses).

```
python3 sat.py --emit-cnf five-sub-parity+ccn8 --with-c3 parity-ccn8.cnf   # vars=37225 clauses=319524
kissat -q parity-ccn8.cnf > parity-ccn8.model                              # exit 10, s SATISFIABLE
python3 sat.py --decode parity-ccn8.model five-sub-parity+ccn8 --with-c3   # MODEL_CHECK=SATISFIED, DECODE_VERDICT=PASS

python3 sat.py --emit-cnf five-sub-rhythm+ccn8 --with-c3 rhythm-ccn8.cnf   # vars=37225 clauses=337326
kissat -q rhythm-ccn8.cnf > rhythm-ccn8.model                              # exit 10, s SATISFIABLE
python3 sat.py --decode rhythm-ccn8.model five-sub-rhythm+ccn8 --with-c3   # MODEL_CHECK=SATISFIED, DECODE_VERDICT=PASS
```

| artifact | sha256 |
|---|---|
| `parity-ccn8.cnf` | `1628e08f07d2ee3d37363930f521a90feb86db4c57a8d253f9db20982c877def` |
| `parity-ccn8.model` (239,856 bytes) | `d2f39af21ebea2d632f7fa37632dc4a965f5c3367186c471d55bbd4bc1ef5c96` |
| `rhythm-ccn8.cnf` | `52e6869a8fcf783a294ead99844de8a3666a7b7cae1e103fbd10468b8d2da3b0` |
| `rhythm-ccn8.model` (237,400 bytes) | `fdc430d0f31cad4f80b19b8d929c425d7f758554c60181c8fa5d2857326dd0a4` |

`python3 sat.py --witness five-sub-parity+ccn8 --with-c3` and the same for `rhythm` each returned the
pinned ordering at attempt 0 with `WITNESS_RESULT=WITNESS`. That agreement is an observation about this
build, not a contract: another kissat version or CNF ordering may return a different ordering. The model
files are not committed; their hashes are the record. Controls run in the same session:
`five-sub-gender+ccn8` gave `s UNSATISFIABLE` (exit 20) and `five-sub-parity+rhythm --with-c3` gave
`s SATISFIABLE` and decoded to the `grand-strict.txt` ordering, so the chain can return either answer.

## Verify without a solver

```
gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz
./solve --check-arrangement "$(sed -n 's/^SEQ=//p' reports/evidence/core_pair_witnesses/parity-ccn8.txt)"
#   verdict SUPER (C1&C2&C4&C5): IN ; verdict C15 (C1-C5, C3<=776): IN ; C3 value 736
./solve --check-arrangement "$(sed -n 's/^SEQ=//p' reports/evidence/core_pair_witnesses/rhythm-ccn8.txt)"
#   verdict SUPER (C1&C2&C4&C5): IN ; verdict C15 (C1-C5, C3<=776): IN ; C3 value 728
python3 -c 'import sat
for f,t in (("parity-ccn8","five-sub-parity+ccn8"),("rhythm-ccn8","five-sub-rhythm+ccn8")):
    s=[int(x) for x in open("reports/evidence/core_pair_witnesses/%s.txt"%f).read().split("SEQ=")[-1].split(",")]
    print(sat.target_verdict(s,t,with_c3=True)["ok"], sat.rule_scores(s), s==sat.KW)'
#   True {'parity': 0, 'rhythm': 5, 'gender': 2, 'ccn4': 1, 'ccn8': 0} False
#   True {'parity': 1, 'rhythm': 0, 'gender': 2, 'ccn4': 1, 'ccn8': 0} False
```

Controls that show the checks can fail: King Wen returns `ok=False` for both targets (it violates
strict parity and rhythm), and either ordering with its second pair reversed is `OUT` under
`--check-arrangement`.
