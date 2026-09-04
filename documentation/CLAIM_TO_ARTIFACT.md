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
| 6 | ≤14 and ≥16 alternations are UNSAT | TR-6 | `alt-le-14` / `alt-ge-16` DRAT | `python3 sat.py --emit-cnf alt-le-14 f.cnf && kissat f.cnf f.drat && drat-trim f.cnf f.drat` (likewise `alt-ge-16`); `verify_all.sh` replays both archived proofs | CERTIFIED — **corroborating, not independent**: refuted by C5 cardinality alone (see CORRECTIONS 2026-08-29) |
| 7 | The four literature rules are jointly unsatisfiable | TR-2 | `grand_ccn4_unsat.drat.gz` | `python3 sat.py --emit-cnf grand-ccn4 f.cnf && kissat f.cnf f.drat && drat-trim f.cnf f.drat` | CERTIFIED — parity + rhythm + gender + CC-N4, at C1∩C2∩C4∩C5 scope (TR-2 §4) |
| 8 | The conflict has **four** minimal two-rule cores | TR-2 | `core_{gender_ccn8,parity_ccn4,rhythm_ccn4,gender_ccn4}_unsat.drat.gz` (the fourth shipped 2026-09-02) | per-pair CNF via `python3 sat.py --emit-cnf five-sub-<a>+<b> f.cnf` + `kissat`, then `drat-trim`; `verify_all.sh` replays all four | CERTIFIED — 4 of 4 archived, and **all four carry drat-trim + cake_lpr**: three from the 2026-07-27 batch, the fourth ({gender, S25–28}, definitional-by-construction, ruled 2026-09-02) taken through the same chain on 2026-09-02 (`s VERIFIED UNSAT`), on a cake_lpr rebuilt from pin `a36874a8` whose compiled sha is byte-identical to the batch binary — see CORRECTIONS 2026-09-02 |
| 9 | Joint-strict population ≈1.13×10²⁹ | TR-1 §4 | `reports/evidence/r11/r11_moore_strict.out` | `SOLVE_KNUTH_MOORE_STRICT=1 ./solve --estimate-knuth <nodes>` | ESTIMATE — 95% CI [1.09, 1.17]×10²⁹, relerr 1.66%. **Not** `f11_runB.out` |
| 10 | Nine pre-registered Davis composites: five null, one notable, three data-like | TR-10 | `reports/evidence/dav_tier1.out` | `ulimit -s unlimited`, then `SOLVE_KNUTH_SCORE_DAV=1 SOLVE_KNUTH_DAV_HIST=1 ./solve --estimate-knuth 2000000000` (the masses); `./solve --dav-verify` is the KW-anchor gate only | ESTIMATE — `se=` emission landed 2026-08-28 (METHODS §"Statistics conventions"); the archived 2026-07-04 tier-1 run predates it and carries no `se=`; two verdicts corrected 2026-08-28 |
| 11 | KW's complement-distance sum C3 = 776 | TR-5, Lean | `lean/KingWen.lean` `kw_c3_exactly_776` | `cd lean && lean KingWen.lean` | KERNEL |
| 12 | 24 DRAT certificates verify (the 22 of the 2026-09-02 replay + the two cardinality-only `noY` subset proofs, SAT_CLI §`TARGET-noY`) | `reports/certificates/` | the archived `.drat.gz` set — 24 files, all 24 in `verify_all.sh`'s regeneration map | `bash reports/certificates/verify_all.sh` | CERTIFIED — **22/22 `PASS cert`, zero FAIL, executed 2026-09-02 on the shipped tree** (drat-trim `2e3b2dc0`, cake_lpr on all 22); the two `noY` proofs (`alt_le_14_noY_unsat`, `alt_ge_16_noY_unsat`, added 2026-09-02, committed 2026-09-03) are `s VERIFIED` by drat-trim and the 24-entry map replayed `DRAT_CERTS_CHECKED=24`, 24 PASS / 0 FAIL, `ALT_NOY_SUBSET_UNSAT=PASS` on 2026-09-02 (drat-trim only; no cake_lpr leg for those two). Supersedes the 21/21 replay of 2026-08-28. ⚠ `reports/certificates/README.md`'s inventory table still lists 22 and has no `noY` rows (as of 2026-09-03). The stale caveat that the log kept only the PASS line is withdrawn: since the 2026-09-02 CLASS-B sweep `verify_all.sh` captures the checker's own output and requires the whole line `s VERIFIED` (`require_verdict_line`) |
| 13 | 14 Lean modules are kernel-clean, no `native_decide` | `lean/README.md` | the 14 `.lean` sources (`git ls-files 'lean/*.lean'` lists 14 since `SatEncodingFidelity.lean`, 2026-08-31) | `cd lean && lean <Module>.lean` per module (the `cd` is what makes elan honour `lean/lean-toolchain`); `#print axioms` | KERNEL — **14/14 executed 2026-09-03** at `3ef705c9` on `leanprover/lean4:v4.31.0` (D16-class host): 0 FAIL, 123 `#print axioms` lines all ⊆ `[propext, Classical.choice, Quot.sound]`, comment-stripped census 0 `native_decide` / 0 `sorry` / 0 `axiom`. Supersedes the 13/13 run of 2026-08-28, which predated the fourteenth module. `verify_all.sh` §4 FIXED 2026-09-03 (B11a): it now runs each module from inside `lean/` and emits whole-line `LEAN_ID=<pin>/<lean --version>` and `LEAN_PIN_MATCH=PASS\|FAIL` tokens, failing every module line on a mismatch. Plant-tested on a VM with `elan default` planted to 4.30.0 and the pin untouched: the previous root-relative loop reported 12 PASS + 2 FAIL (`RecordConvention`, `TrigramTheorems`: `rw` pattern-not-found, a 4.30→4.31 elaboration difference — both pass under the pin) while `…/v4.30.0/bin/lean` did the checking; the PASS lines named no kernel and the FAIL lines blamed the proofs; so every earlier `verify_all.sh`-only Lean attestation names the host's default kernel of its day, not 4.31.0 — the 14/14 figure above was produced with the `cd lean` command and stands |
| 14 | n=9 orientation-explicit count = 26,112 (sequence-level; see TR-11 §2 precision note) | TR-11 | CPOG certificate, regenerated per run (`--keep DIR` retains it); not archived in-tree | `python3 sat.py --certify-count f1c5 --f1-pairs 9 --expect 26112` | CERTIFIED — 2026-08-20, reproduced 2026-08-26 on a separate host with the toolchain built from source (SAT_CLI §NOTES); the artifact sha256s (`instance.cpog` `b311715f…`, 1,392,854,105 B; `instance.cnf` `800fde57…`; `instance.nnf` `2317b6c2…`) and toolchain pins were published 2026-09-01 in SAT_CLI §`--certify-count`, for one run; a second-host **match** of those hashes is not yet published |
| 15 | KW satisfies C1/C2/C4/C5 | TR-11, Lean | `lean/KingWen.lean` `kw_valid` | `cd lean && lean KingWen.lean` | KERNEL |
| 16 | The 31-rule literature registry | `LITERATURE_RULES_POPULATION_TESTS.md` | `solve.py` `REGISTRY_KW_EXPECTED` | `python3 solve.py --registry-verify` | MIXED — **27 of 31** reproduce a source-stated KW value; 4 are KW-measured anchors |
| 17 | KW's joint-density percentile ≈30% on the two non-circular FFT dimensions (5 seeds × 2 bandwidth methods: 28.6–32.1%; exact full-population 2-D histogram 29.32 / 31.01 / 33.85% at three bin widths) | `DISTRIBUTIONAL_ANALYSIS.md` §Joint density (2026-07-26 re-analysis), `PROJECT_OVERVIEW.md` | **none public** — per-run outputs (seeds, bandwidths, bin edges) are in the private staging repo, not in-tree | **no public invocation at this revision** — `python3 solve.py --joint-density` runs the withdrawn seven-dimensional analysis, and the 2-D `dims=`/`seed=` parameters of `p2_joint_density_v2` are not exposed on the command line (DISTRIBUTIONAL_ANALYSIS §"Reproducing this figure", gap recorded 2026-08-30) | ESTIMATE — per-run bootstrap 95% CI ≤ ±1 pp; **not reproducible from the public tree** until the two parameters are wired through argparse and the per-seed invocations plus an archived output are published. Listed so the gap is visible rather than inferred |

## What this matrix does not cover

The 91-observable ledger, the per-rule registry beyond row 16, and the campaign-scale enumeration
counts have their own tables in METHODS.md and CANONICAL_HASHES.md. Rows are added here as claims are
promoted to headline status. **A missing row means uncovered, not unsupported** — and saying so is the
point: the failure this file exists to prevent is a claim whose evidence nobody had to look at.
