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
`verify_all.sh` (this directory) checks every certificate below. Full inventory: 24 certificates —
the original 5 (conflict theorem + repair ladder + alternation theorem), the 14 of the [TR-2](../TR2_THE_RULES_CONFLICT.md) v1.6
extension (five-rule union, its near-2/3/4 repair ladder, all five leave-one-out subsets, three of
the four two-rule cores, and two encoding-validation gates), the fourth two-rule core
(`core_gender_ccn4_unsat.drat.gz`, found 2026-08-28, shipped 2026-09-02 — see §Checker coverage
below: as of 2026-09-02 it has passed both checkers, like the other 21), the [TR-5](../TR5_SYMMETRY.md) SC-4 rigidity kernel, the
C3 positional KW-exactness gate, and the two cardinality-only alternation subsets
(`alt_le_14_noY_unsat.drat.gz`, `alt_ge_16_noY_unsat.drat.gz`, shipped 2026-09-03 — §TR-6
alternation subset below) — plus one SAT-witness artifact (`c3_positional_witnesses.txt`).
*(Count corrected 2026-09-19: this line stated 22, and named neither of the two subset proofs
archived 2026-09-03, while `verify_all.sh` had already been corrected on 2026-09-10 to
`CERT_FLOOR=24` and checks 24. The drift was possible because nothing compared this sentence against
the directory; `scripts/doc_gates.sh cert-inventory` (GATE 77) now fails when the two disagree. That
gate requires this page to carry EXACTLY ONE sentence of the live "Full inventory: N certificates"
form — a retired count is quoted here as a bare number on purpose, because a pattern that can match
a correction note as well as the claim is not a measurement of the claim.)*

**Files and proofs are counted separately, because they differ.** The 24 archived files carry
**23 distinct proofs**: `grand_ccn4_unsat.drat.gz` and `five_loo_ccn8_unsat.drat.gz` decompress to
the same DRAT byte for byte (sha256 of the decompressed proof,
`718555676dbf207c744a6e93700c280ef275a735c4f738ec866bf10b3f14f2ef` — quoted in full here so the
abbreviated `71855567…` used elsewhere resolves to something a reader can reach), because the
five-rule union (`grander-strict`) minus CC-N8 *is* the
four-rule conflict set — their regenerated CNFs differ only in the `c target=` comment line
(measured 2026-09-21: `diff` of the non-comment lines is empty). One formula legitimately carries
two target names, and both files stay so that each name remains checkable; but "24 certificates"
is a count of files, and the corpus supplies 23 independent refutations, not 24. Do not read
"24/24 verified" as 24 independent results. `scripts/doc_gates.sh cert-inventory` (GATE 77 leg 4)
recomputes the distinct-proof count by decompressing every archived proof and fails when this
sentence's number disagrees with it, so the two counts cannot drift apart silently either (Q-640).

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

## TR-6 alternation subset (cardinality-only `noY` proofs, archived 2026-09-03)

These two are the CARDINALITY-ONLY clause subset of the two alternation targets — exactly the clauses
of `alt-le-14` / `alt-ge-16` in which no ordering (Y) variable occurs — shown UNSAT on their own. The
subset is emitted by the documented target suffix `-noY`
([SAT_CLI.md](../../documentation/SAT_CLI.md) §`TARGET-noY`).

| Certificate | Regenerate CNF | Establishes |
|---|---|---|
| alt_le_14_noY_unsat.drat.gz | `python3 sat.py --emit-cnf alt-le-14-noY f.cnf` | the ordering-variable-free subset of `alt-le-14` (11,073 of 240,039 clauses) is UNSAT on its own |
| alt_ge_16_noY_unsat.drat.gz | `python3 sat.py --emit-cnf alt-ge-16-noY f.cnf` | the ordering-variable-free subset of `alt-ge-16` (11,134 of 240,100 clauses) is UNSAT on its own |

Both archived files are the **core-trimmed** proofs (`drat-trim -l` on the raw kissat 4.0.1 output,
then re-verified from the trimmed file: ~36.4k / ~11.7k lemmas in core, so neither is decided by unit
propagation, and a half-truncated copy is `s NOT VERIFIED`). `verify_all.sh` regenerates each subset
CNF and re-checks the archived proof against it, emitting the whole-line verdict
`ALT_NOY_SUBSET_UNSAT=PASS|FAIL|NOT_RUN`.

⚠ **Scope, which is narrower than the file names suggest.** They certify the *semantic* claim behind
[TR-6](../TR6_PARITY_SKELETON.md)'s "corroborating, not independent" verdict — the alternation
theorem follows from C5's cardinalities before any ordering variable is consulted. They do **not**
certify that no ordering variable appears in the *full* proofs: the archived `alt-le-14` core
contains 356 of them, cores being proof-relative.

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
| `alt_le_14_noY_unsat.drat.gz`, `alt_ge_16_noY_unsat.drat.gz` (archived 2026-09-03) | `s VERIFIED` — kissat 4.0.1, core-trimmed and re-verified 2026-09-02, and replayed through `verify_all.sh`'s 24-entry map (`DRAT_CERTS_CHECKED=24`, 24 PASS / 0 FAIL, `ALT_NOY_SUBSET_UNSAT=PASS`) | `s VERIFIED UNSAT` — executed **2026-09-19**, closing the two-certificate gap; `CAKE_LPR_ID=98c1649d…` (⚠ **[UPDATED 2026-09-19** — this cell read "**NOT RUN** — no cake_lpr leg has been executed for these two … Not a failure and not a pass: an unrun check", which was accurate from 2026-09-03 until the leg ran**]**) |

**Both outstanding items are now closed, and the parity is real rather than asserted.** On 2026-09-02
the shipped directory was replayed end to end — `verify_all.sh` reported **22/22 `PASS cert` lines,
zero FAIL** — and the fourth core was taken through the full `drat-trim … -L <lrat>` → `cake_lpr`
chain to `s VERIFIED UNSAT`. The cake_lpr binary was rebuilt from the same pin `a36874a8` and its
compiled sha is **byte-identical to the binary used for the 2026-07-27 batch**, so all 22 certificates
have now been checked by provably the same verified checker, not merely by one bearing the same name.
The proof's maximum variable (13,015) exceeds the CNF's variable count (7,035); this is ordinary
solver factoring and both checkers were confirmed to accept it rather than assumed to.

*(Coverage scope re-stated 2026-09-19, and the paragraph above is deliberately left as written: it
is a dated record of the 2026-09-02 replay over a 22-certificate corpus, and was true of that
corpus. The corpus is 24, and **as of 2026-09-19 all 24 carry both checkers** — the two `noY` subset
proofs archived 2026-09-03 went through the cake_lpr chain that day, third row of the table above.
So "all 22 certificates have now been checked by provably the same verified checker" remains a
statement about those 22 and about 2026-09-02; the 24-certificate statement is the section below.
An earlier draft of this note closed "the gap is an unrun check, not a failed one, and closing it
means running the cake_lpr leg on the two, not editing this page" — the leg was run, and that is
what closed it.)*

### The 2026-09-19 full-archive run, and the binary that produced it

All 24 were taken through the verified checker in a single pass of the **shipped** harness
(`verify_all.sh`, unmodified, from a clean clone of the public tree): **24/24 `s VERIFIED UNSAT`,
0 FAIL**, with `DRAT_CERTS_CHECKED=24` and `ALT_NOY_SUBSET_UNSAT=PASS` on the drat-trim leg beneath
it.

🔴 **A verdict line alone names nothing, which is why this table exists.** `cake_lpr` prints
`s VERIFIED UNSAT` and exits 0 — and so would a 59-byte script that printed the same line. The only
thing separating a genuine pass from that is the identity of the binary that produced it, so it is
published here rather than described.

| item | measured value |
|---|---|
| cake_lpr pin | `a36874a8b750b43fe4b385b8ddbf5b033e46a3fa` ([Tan, Heule & Myreen 2021](../../documentation/CITATIONS.md#cakelpr2021)) |
| `cake_lpr.S` sha256 — **the durable anchor** | `2f3af32d55083839b3fa0e693afd817679c0b8944bef41def05a8b0ec72b7d4a` |
| run binary sha256 (`CAKE_LPR_ID`) | `98c1649dc01f6ba38e4424beeff1b4681069b6175d90047b8c2c73316cd9ef2f` |
| `basis_ffi.c` sha256, **as measured at that pin** | `8e30d84fdcb2177aa5571d7fa6661a2fae5ecfd56baa0ce49c65f9233a9f87cb` |
| build | `gcc -O2 basis_ffi.c cake_lpr.S -o cake_lpr -std=c99` (the upstream repo's own default target), gcc 11.4.0 |
| drat-trim (untrusted elaborator) | pin `2e3b2dc0ecf938addbd779d42877b6ed69d9a985`, binary sha256 `b535cc5334e97fba5b5db6013625c5a0b16ce348a98d59ff91b45a83fa56b39e` |

⚠ **The compiled sha is compiler-dependent, so it is NOT the portable identity.** This run's binary
(`98c1649d…`, gcc 11.4.0) differs from the 2026-07-27 / 2026-09-02 batch binary
(`1822ca1e5d0f925e8f3b73047941a8261bee65eef6ccb0e33bb49f92821a09ca`, gcc 13.3.0). The `.S` input is
byte-identical across all three runs, which is exactly why **`cake_lpr.S` sha256 `2f3af32d…` is the
value a replicator should pin**; a binary sha names which build produced a given verdict and nothing
more. The two numbers are recorded as measured, with no attempt to reconcile them.

⚠ **The upstream pin's own provenance file disagrees with the upstream pin's own source file.**
`cake_lpr.sha256` at `a36874a8` names `basis_ffi.c` =
`3fbd8f31c380e7fb40fede74496ff8b7fb63043645b1afff1e5f26aacdccfa69`, while the actual `basis_ffi.c` at
that pin hashes to `8e30d84f…`. The `.S` rows in that file *do* match. The table above carries what
was measured; the upstream row is stale for that one file.

⚠ **What 24/24 does NOT establish.** cake_lpr's `machine_code_sound` theorem is about the CNF the
checker is handed: it certifies that each archived proof refutes the CNF `sat.py --emit-cnf`
regenerates — **never that the CNF means what the prose says it means**
([TR-2](../TR2_THE_RULES_CONFLICT.md) §2 states the same scope, and
[METHODS](../METHODS.md) §"Independence ladder" puts the two on different rungs). "24/24 verified"
is a statement about the proofs, not about the mathematics; the encoding-fidelity gap is closed by
the two-way encoding validation, not by any checker. Three assumptions are inherited rather than
proved: `basis_ffi.c`, gcc, the linker and the OS are unverified C and unverified toolchain; and the
theorem is about **stdout**, while the harness greps merged `2>&1`.

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
