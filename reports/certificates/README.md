# UNSAT certificates (DRAT)

## Executive summary (plain English)

This directory contains **impossibility proofs with independently checkable receipts**. Several
historical claims about the King Wen sequence amount to rules it "should" satisfy. We encoded those
rules as logical formulas and used an industry-standard SAT solver to prove that certain
combinations admit **no possible sequence at all** — most notably the conflict theorem: the five
classical rules cannot all hold together, and specific two-rule pairs are already incompatible.

The point of this directory is that **you do not have to trust our solver, our code, or us**:
each result ships as a DRAT certificate — a step-by-step logical derivation that any third-party
checker (the standard `drat-trim` tool) verifies mechanically. Regenerate the formula with the
documented command, run the checker on the archived certificate, and it prints `s VERIFIED`.
`verify_all.sh` does this for every certificate in one command. The certificates were additionally
re-verified end-to-end on separate hardware before publication.

In short: "these rules cannot coexist" is not our opinion or our program's output — it is a
machine-checkable mathematical fact, and the receipt is in this directory.


Each certificate pairs with a deterministic CNF regeneration command; regenerated CNF + archived proof
must check with drat-trim (`drat-trim <cnf> <proof>` -> `s VERIFIED`). See [reports/METHODS.md](../METHODS.md).
`verify_all.sh` (this directory) checks every certificate below. Full inventory: 19 certificates —
the original 5 (conflict theorem + repair ladder + alternation theorem) plus the 14 of the [TR-2](../TR2_THE_RULES_CONFLICT.md) v1.6
extension (five-rule union, its near-2/3/4 repair ladder, all five leave-one-out subsets, the three
two-rule cores, and two encoding-validation gates).

## Original set (conflict theorem, minimal repairs, alternation theorem)

| Certificate | Regenerate CNF | Establishes |
|---|---|---|
| alt-le-14.drat.gz | `python3 sat.py --emit-cnf alt-le-14 f.cnf` | ≤14 alternations impossible |
| alt-ge-16.drat.gz | `python3 sat.py --emit-cnf alt-ge-16 f.cnf` | ≥16 alternations impossible |
| moore-strict-near-2.drat.gz | `python3 sat.py --emit-cnf moore-strict-near-2 f.cnf` | Moore repair ≥3 edits |
| rc4_near2_unsat.drat.gz | `python3 sat.py --emit-cnf rc4-strict-near-2 f.cnf` | gender-rule repair ≥3 edits |
| grand_ccn4_unsat.drat.gz | `python3 sat.py --emit-cnf grand-ccn4 f.cnf` | THE CONFLICT THEOREM |

## TR-2 v1.6 extension (five-rule union, repair ladder, leave-one-out, two-rule cores, encoding gates)

| Certificate | Regenerate CNF | Establishes |
|---|---|---|
| grander_strict_unsat.drat.gz | `python3 sat.py --emit-cnf grander-strict f.cnf` | five-rule union UNSAT |
| grander_strict_near2_unsat.drat.gz | `python3 sat.py --emit-cnf grander-strict-near-2 f.cnf` | union repair ≥3 edits |
| grander_strict_near3_unsat.drat.gz | `python3 sat.py --emit-cnf grander-strict-near-3 f.cnf` | union repair ≥4 edits |
| grander_strict_near4_unsat.drat.gz | `python3 sat.py --emit-cnf grander-strict-near-4 f.cnf` | union UNSAT at any repair distance tested (≥5) |
| five_loo_parity_unsat.drat.gz | `python3 sat.py --emit-cnf five-loo-parity f.cnf` | union minus [Moore](../../documentation/CITATIONS.md#moore2005) parity: still UNSAT |
| five_loo_rhythm_unsat.drat.gz | `python3 sat.py --emit-cnf five-loo-rhythm f.cnf` | union minus [Moore](../../documentation/CITATIONS.md#moore1989) rhythm: still UNSAT |
| five_loo_gender_unsat.drat.gz | `python3 sat.py --emit-cnf five-loo-gender f.cnf` | union minus [Schulz](../../documentation/CITATIONS.md#schulz1990-motifs) gender: still UNSAT |
| five_loo_ccn4_unsat.drat.gz | `python3 sat.py --emit-cnf five-loo-ccn4 f.cnf` | union minus S25–28 config: still UNSAT |
| five_loo_ccn8_unsat.drat.gz | `python3 sat.py --emit-cnf five-loo-ccn8 f.cnf` | union minus CC-N8 (= grand-ccn4): still UNSAT |
| core_parity_ccn4_unsat.drat.gz | `python3 sat.py --emit-cnf five-sub-parity+ccn4 f.cnf` | two-rule core: {Moore parity, S25–28} |
| core_rhythm_ccn4_unsat.drat.gz | `python3 sat.py --emit-cnf five-sub-rhythm+ccn4 f.cnf` | two-rule core: {Moore rhythm, S25–28} |
| core_gender_ccn8_unsat.drat.gz | `python3 sat.py --emit-cnf gender-ccn8 f.cnf` | two-rule core: {Schulz gender, CC-N8} |
| ccn8_kwfail_unsat.drat.gz | `python3 sat.py --emit-cnf ccn8-kwfail f.cnf` | encoding gate: CC-N8 at shifted locus (24,25) correctly rejects KW |
| ccn8_kwchain_not_unsat.drat.gz | `python3 sat.py --emit-cnf ccn8-kwchain-not f.cnf` | encoding gate: R-S2 run-parity chain pinned against its KW value is UNSAT |

SAT-side encoding validations (no DRAT proof exists for SAT results; re-run directly):
`ccn4-kwtest` SAT, `ccn8-kwtest` SAT, `ccn8-kwchain` SAT, `rc4-kwtest` UNSAT-by-design gate — see
`sat.py --help` and reports/TR2_THE_RULES_CONFLICT.md §Commands.
