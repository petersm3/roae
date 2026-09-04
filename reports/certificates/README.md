# UNSAT certificates (DRAT)

## Executive summary (plain English)

This directory contains **impossibility proofs with independently checkable receipts**. Several
historical claims about the King Wen sequence amount to rules it "should" satisfy. We encoded those
rules as logical formulas and used an industry-standard SAT solver to prove that certain
combinations admit **no sequence in the base space these proofs range over** — most notably the
conflict theorem: the four literature rules (Moore parity, Moore rhythm, Schulz gender, and the
S25–28 trigram configuration) cannot all hold together; the five-rule union that adds CC-N8 is
likewise UNSAT. **Read the scope carefully:**
every UNSAT result in this directory is a statement over the **C1∩C2∩C4∩C5**-valid space — the CNF
fixes the pair structure, the no-5 rule, the oriented opening pair, and King Wen's own transition
multiset. It is *not* a statement about all 64! orderings, and an arrangement with a different
transition multiset is excluded by no byte of these proofs. *(Scope added 2026-08-01: this summary
read "no possible sequence at all", inviting exactly the universal reading TR-2 v1.18/v1.20
corrected in the reports — and this front page is where a sceptical reader starts.)* Specific
two-rule pairs are already incompatible on their own — the two-rule cores listed below.

The point of this directory is that **you do not have to trust our solver, our code, or us**:
each result ships as a DRAT certificate — a step-by-step logical derivation that any third-party
checker (the standard `drat-trim` tool) verifies mechanically. Regenerate the formula with the
documented command, run the checker on the archived certificate, and it prints `s VERIFIED`.
`verify_all.sh` does this for every certificate in one command. The certificates were additionally
re-verified end-to-end on separate hardware before publication.

In short: "these rules cannot coexist **over the C1∩C2∩C4∩C5-valid space**" is not our opinion or
our program's output — it is a machine-checkable mathematical fact. The base scope is part of the
fact, not a footnote to it, and the receipt is in this directory.


Each certificate pairs with a deterministic CNF regeneration command; regenerated CNF + archived proof
must check with drat-trim (`drat-trim <cnf> <proof>` -> `s VERIFIED`). See [reports/METHODS.md](../METHODS.md).
`verify_all.sh` (this directory) checks every certificate below. Full inventory: 22 certificates —
the original 5 (conflict theorem + repair ladder + alternation theorem), the 14 of the [TR-2](../TR2_THE_RULES_CONFLICT.md) v1.6
extension (five-rule union, its near-2/3/4 repair ladder, all five leave-one-out subsets, three of
the four two-rule cores, and two encoding-validation gates), the fourth two-rule core
(`core_gender_ccn4_unsat.drat.gz`, found 2026-08-28, shipped 2026-09-02 — see §Checker coverage
below: as of 2026-09-02 it has passed both checkers, like the other 21), the [TR-5](../TR5_SYMMETRY.md) SC-4 rigidity kernel, and the
C3 positional KW-exactness gate — plus one SAT-witness artifact (`c3_positional_witnesses.txt`).

## TR-5 SC-4 rigidity kernel

| certificate | regeneration command | claim |
|---|---|---|
| `rigidity_sc4_unsat.drat.gz` | `python3 sat.py --rigidity-cnf <out.cnf>` | No G₅-automorphism fixing `0` and its **six** distance-5 neighbours `N₅(0)` (\|N₅(0)\| = C(6,5) = 6) pointwise differs from the identity — i.e. the two-common-neighbour rigidity step of the symmetry-completeness theorem. UNSAT. |

Note the distinct emitter flag: this kernel regenerates via `--rigidity-cnf` (which self-validates its
own encoding before writing), not via the `--emit-cnf <target>` table used by the 20 conflict-theorem
certificates. `verify_all.sh` special-cases it accordingly. The instance is decided by unit propagation
alone (drat-trim reports 1 lemma in core over 3,054 core clauses) — it is an easy instance for a modern
solver, and the certificate's value is that the step is now *machine-checked* rather than asserted in
prose, not that it was computationally hard.

## C3 positional certificates (the exactness pass, Q4(b); G = couple-slot-distance sum, C3 = 16 + 8·G, KW at G = 95)

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
| core_gender_ccn4_unsat.drat.gz | `python3 sat.py --emit-cnf five-sub-gender+ccn4 f.cnf` | two-rule core: {Schulz gender, S25–28} — the fourth core (found 2026-08-28, shipped 2026-09-02; not part of v1.6). Definitional-by-construction: S25–28 pins stations 25/26 to popcounts 5 and 2, each violating strict gender at its own parity (TR-2 §Extension). drat-trim **and** cake_lpr, 2026-09-02 — see §Checker coverage |
| ccn8_kwfail_unsat.drat.gz | `python3 sat.py --emit-cnf ccn8-kwfail f.cnf` | encoding gate: CC-N8 at shifted locus (24,25) correctly rejects KW |
| ccn8_kwchain_not_unsat.drat.gz | `python3 sat.py --emit-cnf ccn8-kwchain-not f.cnf` | encoding gate: R-S2 run-parity chain pinned against its KW value is UNSAT |

SAT-side encoding validations (no DRAT proof exists for SAT results; re-run directly):
`ccn4-kwtest` SAT, `ccn8-kwtest` SAT, `ccn8-kwchain` SAT, `rc4-kwtest` UNSAT-by-design gate — see
`sat.py --help` and reports/TR2_THE_RULES_CONFLICT.md §Commands.

## Checker coverage — which checker each certificate has passed

Two external checkers are used, and their trust status differs ([SAT_CLI.md](../../documentation/SAT_CLI.md)):
**drat-trim**, independent of the solver but not itself formally verified, is what `verify_all.sh`
runs; **cake_lpr** is the CakeML *formally verified* LRAT checker (pinned commit
`a36874a8b750b43fe4b385b8ddbf5b033e46a3fa`), run per certificate as
`drat-trim <cnf> <drat> -L <lrat>` then `cake_lpr <cnf> <lrat>` → `s VERIFIED UNSAT`, a chain in which
drat-trim is an untrusted elaborator.

| certificates | drat-trim | cake_lpr |
|---|---|---|
| the 21 archived before 2026-09-02 (every file above except `core_gender_ccn4_unsat.drat.gz`) | `s VERIFIED` — 21/21 replay executed 2026-08-28 | `s VERIFIED UNSAT`, all 21, executed 2026-07-27 |
| `core_gender_ccn4_unsat.drat.gz` | `s VERIFIED` — produced with kissat 4.0.1, checked off-tree 2026-08-28, and **replayed in the 22/22 run of 2026-09-02**; sha256 `bcfc72a1a9ce5ef7c4703f4fb0f321033ed6eb7f8d593007c136d449fb78fe61` | `s VERIFIED UNSAT` — executed **2026-09-02** on the same pinned checker |

**Both outstanding items are now closed, and the parity is real rather than asserted.** On 2026-09-02
the shipped directory was replayed end to end — `verify_all.sh` reported **22/22 `PASS cert` lines,
zero FAIL** — and the fourth core was taken through the full `drat-trim … -L <lrat>` → `cake_lpr`
chain to `s VERIFIED UNSAT`. The cake_lpr binary was rebuilt from the same pin `a36874a8` and its
compiled sha is **byte-identical to the binary used for the 2026-07-27 batch**, so all 22 certificates
have now been checked by provably the same verified checker, not merely by one bearing the same name.
The proof's maximum variable (13,015) exceeds the CNF's variable count (7,035); this is ordinary
solver factoring and both checkers were confirmed to accept it rather than assumed to.

⚠ **Two operational facts, recorded because each can produce a false PASS.** `cake_lpr` **exits 0 on
both success and failure** — the verdict is the `s VERIFIED UNSAT` line and nothing else; and its
default heap and stack (4096 + 4096 MB) exceed an 8 GB host, where it aborts with "failed to allocate
sufficient CakeML heap and stack space". The 2026-09-02 run used `--CML_HEAP_SIZE=2048
--CML_STACK_SIZE=1024`, which are runtime sizing flags of the same verified binary. The checker was
red-tested before its pass was trusted: seven mutations — a removed empty-clause step, a satisfiable
CNF, a truncated LRAT, a bogus hint id, a mutated core clause, a deleted first clause, a negated
literal — were each rejected with a reason line, and the control then re-verified.

The fourth core's *content* — that S25–28 entails the
gender rule's exceptions at stations 25/26 — is also checkable by hand in constant time
([TR-2](../TR2_THE_RULES_CONFLICT.md) §Extension), which is why it is classified as definitional rather
than discovered; the certificate makes that entailment machine-checked.
