# Claim-to-artifact matrix

**What this is for.** Every headline claim in this repository should be checkable against a named
artifact by a named command, without inferring which output supports which sentence. Until 2026-08-29
that mapping lived only in the reader's head, and the cost was measurable: a firstness claim stood on
`main` for four weeks after our own adjudication ruled it false, and a "smallest measured margins"
superlative was published at six sites while the evidence file that refutes it sat in
`reports/evidence/`. Both are the same failure — **a claim and its evidence that nobody had to look
at together.**

**How to read the Status column.**

* **EXACT** — computed to the last digit; a disagreement is a defect, not noise.
* **CERTIFIED** — carries an independently checkable proof object (DRAT / CPOG) that a third-party
  checker replays.
* **KERNEL** — proved in Lean 4 and checked by its kernel.
* **ESTIMATE** — a sampled measurement with a stated confidence interval. **Never quote one without
  its interval**; conflating a tolerance band with an error bar is exactly what went wrong in TR-1.

**Scope, stated honestly.** This covers the **headline** claims — the ones a reader meets in the
README and the technical-report abstracts. It is **not** a complete inventory of every number in the
suite; the per-rule registry (31 rules) and the 91-observable ledger have their own tables, cited
below. A row's absence here is not a claim that the figure is unsupported — it means this matrix does
not yet reach it, and extending coverage is tracked rather than assumed.

| # | Claim | Published in | Artifact | Reproduce | Status |
|---|---|---|---|---|---|
| 1 | The binary's canonical identity | `CANONICAL_HASHES.md` | `--selftest` internal digest | `gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz && ./solve --selftest` | EXACT — `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e` |
| 2 | \|C1∩C2∩C4\| = 7.5706×10⁴¹ | TR-11 | symmetry-quotient DP | `./solve --f1-exact-c1c2c4` | EXACT |
| 3 | \|C1∩C2∩C4∩C5\| = 1.097051×10³⁹ | TR-11 | DP + independent IE transfer-walk | `./solve --f1-exact-c1c2c4c5` ; cross-check `./verify --ie-count` | EXACT — two algorithm classes agree |
| 4 | C1–C5 space ≈1.3287×10³⁸ | TR-4 | Knuth random-probe estimator | `./solve --estimate-knuth <nodes>` | ESTIMATE — quote with its CI |
| 5 | Exactly 15 parity-class alternations | TR-6 | `lean/KingWen.lean` `alternations_15_general` | `cd lean && lean KingWen.lean` | KERNEL — the independent leg; see row 6 |
| 6 | ≤14 and ≥16 alternations are UNSAT | TR-6 | `alt-le-14` / `alt-ge-16` DRAT | `python3 sat.py --emit-cnf alt-le-14 f.cnf && kissat f.cnf` | CERTIFIED — **corroborating, not independent**: refuted by C5 cardinality alone (see CORRECTIONS 2026-08-29) |
| 7 | The four literature rules are jointly unsatisfiable | TR-2 | `grand_ccn4_unsat.drat.gz` | `python3 sat.py --emit-cnf grand-ccn4 f.cnf && kissat f.cnf f.drat && drat-trim f.cnf f.drat` | CERTIFIED — parity + rhythm + gender + CC-N4, at C1∩C2∩C4∩C5 scope (TR-2 §4) |
| 8 | The conflict has **four** minimal two-rule cores | TR-2 | `core_{gender_ccn8,parity_ccn4,rhythm_ccn4,gender_ccn4}_unsat.drat.gz` (the fourth shipped 2026-09-02) | per-pair CNF via `python3 sat.py --emit-cnf five-sub-<a>+<b> f.cnf` + `kissat`, then `drat-trim`; `verify_all.sh` replays all four | CERTIFIED — 4 of 4 archived; three carry drat-trim + cake_lpr (2026-07-27), the fourth ({gender, S25–28}, definitional-by-construction, ruled 2026-09-02) carries **drat-trim only** (`s VERIFIED` off-tree 2026-08-28; cake_lpr chain not yet run) — see CORRECTIONS 2026-09-02 |
| 9 | Joint-strict population ≈1.13×10²⁹ | TR-1 §4 | `reports/evidence/r11/r11_moore_strict.out` | `SOLVE_KNUTH_MOORE_STRICT=1 ./solve --estimate-knuth <nodes>` | ESTIMATE — 95% CI [1.09, 1.17]×10²⁹, relerr 1.66%. **Not** `f11_runB.out` |
| 10 | Nine pre-registered Davis composites: five null, one notable, three data-like | TR-10 | `reports/evidence/dav_tier1.out` | `ulimit -s unlimited`, then `SOLVE_KNUTH_SCORE_DAV=1 SOLVE_KNUTH_DAV_HIST=1 ./solve --estimate-knuth 2000000000` (the masses); `./solve --dav-verify` is the KW-anchor gate only | ESTIMATE — `se=` emission landed 2026-08-28 (METHODS §"Statistics conventions"); the archived 2026-07-04 tier-1 run predates it and carries no `se=`; two verdicts corrected 2026-08-28 |
| 11 | KW's complement-distance sum C3 = 776 | TR-5, Lean | `lean/KingWen.lean` `kw_c3_exactly_776` | `cd lean && lean KingWen.lean` | KERNEL |
| 12 | 22 DRAT certificates verify | `reports/certificates/` | the archived `.drat` set | `bash reports/certificates/verify_all.sh` | CERTIFIED — 21/21 `s VERIFIED` executed 2026-08-28 on the then-complete archive; the 22nd (`core_gender_ccn4`, shipped 2026-09-02) `s VERIFIED` off-tree the same day; a 22/22 replay of the shipped tree has **not** yet been executed |
| 13 | 13 Lean modules are kernel-clean, no `native_decide` | `lean/README.md` | the 13 `.lean` sources | `cd lean && lean <Module>.lean` per module; `#print axioms` | KERNEL — 13/13 executed 2026-08-28; axioms ⊆ `[propext, Classical.choice, Quot.sound]` |
| 14 | n=9 orientation-explicit count = 26,112 (sequence-level; see TR-11 §2 precision note) | TR-11 | CPOG certificate, regenerated per run (`--keep DIR` retains it); not archived in-tree | `python3 sat.py --certify-count f1c5 --f1-pairs 9 --expect 26112` | CERTIFIED — 2026-08-20, reproduced 2026-08-26 on a separate host with the toolchain built from source (SAT_CLI §NOTES); cross-host artifact hashes not yet published |
| 15 | KW satisfies C1/C2/C4/C5 | TR-11, Lean | `lean/KingWen.lean` `kw_valid` | `cd lean && lean KingWen.lean` | KERNEL |
| 16 | The 31-rule literature registry | `LITERATURE_RULES_POPULATION_TESTS.md` | `solve.py` `REGISTRY_KW_EXPECTED` | `python3 solve.py --registry-verify` | MIXED — **27 of 31** reproduce a source-stated KW value; 4 are KW-measured anchors |

## What this matrix does not cover

The 91-observable ledger, the per-rule registry beyond row 16, and the campaign-scale enumeration
counts have their own tables in METHODS.md and CANONICAL_HASHES.md. Rows are added here as claims are
promoted to headline status. **A missing row means uncovered, not unsupported** — and saying so is the
point: the failure this file exists to prevent is a claim whose evidence nobody had to look at.
