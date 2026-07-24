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
`verify_all.sh` (this directory) checks every certificate below. Full inventory: 21 certificates —
the original 5 (conflict theorem + repair ladder + alternation theorem), the 14 of the [TR-2](../TR2_THE_RULES_CONFLICT.md) v1.6
extension (five-rule union, its near-2/3/4 repair ladder, all five leave-one-out subsets, the three
two-rule cores, and two encoding-validation gates), the [TR-5](../TR5_SYMMETRY.md) SC-4 rigidity kernel, and the
C3 positional KW-exactness gate — plus one SAT-witness artifact (`c3_positional_witnesses.txt`).

## TR-5 SC-4 rigidity kernel

| certificate | regeneration command | claim |
|---|---|---|
| `rigidity_sc4_unsat.drat.gz` | `python3 sat.py --rigidity-cnf <out.cnf>` | No G₅-automorphism fixing `0` and its 5 neighbours `N₅(0)` pointwise differs from the identity — i.e. the two-common-neighbour rigidity step of the symmetry-completeness theorem. UNSAT. |

Note the distinct emitter flag: this kernel regenerates via `--rigidity-cnf` (which self-validates its
own encoding before writing), not via the `--emit-cnf <target>` table used by the 19 conflict-theorem
certificates. `verify_all.sh` special-cases it accordingly. The instance is decided by unit propagation
alone (drat-trim reports 1 lemma in core over 3,054 core clauses) — it is an easy instance for a modern
solver, and the certificate's value is that the step is now *machine-checked* rather than asserted in
prose, not that it was computationally hard.

## C3 positional certificates (TR-12 Q4(b); G = couple-slot-distance sum, C3 = 16 + 8·G, KW at G = 95)

These certify **decision facts about the position of King Wen's C3 value** at the C1∩C2∩C4∩C5 base
(no C3 ceiling in the base). They corroborate "KW's G = 95 is not extremal, not unique, and the C3 ≤ 776
cap truncates a populated region" — they are feasibility facts only and bound **no measure** (they can
never certify a percentile; that is the enumeration/counting layer's job).

| certificate | regeneration command | claim |
|---|---|---|
| `c3_kwpin_ge777_unsat.drat.gz` | `python3 sat.py --emit-cnf kw-pin f.cnf --c3-min 777` | KW forced + C3 ≥ 777 is UNSAT — with the SAT of `kw-pin --c3-min 776` and the ≤-side gate, a machine-check that KW's C3 is **exactly** 776 (G = 95). |

SAT-witness artifact (checkable without any solver — each line is an explicit ordering):

| artifact | contents |
|---|---|
| `c3_positional_witnesses.txt` | 42 verified C1∩C2∩C4∩C5 orderings: one at **every** integer rung G = 12..51 (G = 12 is the structural floor — 12 complement couples in pairwise-distinct slots give G ≥ 12 by counting, and it is **achieved**, so the constraints impose no floor above the trivial minimum; KW sits 83 above it); one at G = 95 whose pair-slot layout differs from KW's (`--not-kw` — the G = 95 tie class is not KW-unique, engine-independently); and one at G = 97 > 95 (the region above the C3 ≤ 776 cap is populated). The 560T-population minimum G = 51 is truncation-biased: SAT reaches G = 12. Regeneration commands are in the file header; `verify_all.sh` §3b rechecks every line through `verify.py`'s independent functions. |

There is deliberately no UNSAT/DRAT below the floor: G < 12 is impossible for *any* pair arrangement by
the two-line counting argument above — it lies below the encoding's expressible range, and a DRAT of an
encoder-arithmetic empty clause would certify nothing a reader could not check faster by hand.

## Original set (conflict theorem, minimal repairs, alternation theorem)

| Certificate | Regenerate CNF | Establishes |
|---|---|---|
| alt-le-14.drat.gz | `python3 sat.py --emit-cnf alt-le-14 f.cnf` | ≤14 alternations impossible |
| alt-ge-16.drat.gz | `python3 sat.py --emit-cnf alt-ge-16 f.cnf` | ≥16 alternations impossible |
| moore-strict-near-2.drat.gz | `python3 sat.py --emit-cnf moore-strict-near-2 f.cnf` | Moore repair ≥3 edits |
| rc4_near2_unsat.drat.gz | `python3 sat.py --emit-cnf rc4-strict-near-2 f.cnf` | gender-rule repair ≥3 edits |
| grand_ccn4_unsat.drat.gz | `python3 sat.py --emit-cnf grand-ccn4 f.cnf` | the conflict theorem |

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
