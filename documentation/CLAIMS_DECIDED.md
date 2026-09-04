# Claims Decided — the empirical scorecard

> **How to reproduce anything on this page.** This file **adjudicates; it does not measure.**
> Every row carries a link in its last column, and the reproduction command for that row lives in
> the linked report — not here. Stated explicitly because a reviewer landing on a scorecard is
> owed the path to the evidence, and because GATE 25 LEG 2 (2026-08-16) correctly observed that
> this page publishes figures and names no command of its own. Three rows can be re-run directly:
> the parity-alternation row with `python3 verify.py --check-parity-alternation`, the Drasny
> "Rule of Ten" row with the two-language gate named in the row itself — which means **both**
> halves, `python3 solve.py --db1-verify` and `./solve --db1-verify`, each printing
> `DB1 VERIFY: PASS` (TR-10 §Verification Guide); running one half alone exercises a single
> implementation and tests no cross-language agreement — and the exact `|C1∩C2∩C4∩C5|` row with
> `./verify --ie-count` (the independent transfer-walk engine, TR-11 §10(vi)). The remaining rows
> are statistical measurements or proofs whose commands and artifacts are in their reports.


One page for the question "what has ROAE actually settled?" Every entry: the claim, who made it, what
we found, and where the proof lives. "Decided" spans a spectrum — **refuted** (shown false as stated),
**corrected** (true with a different scope/value), **forced** (asserted as design, shown to be a
consequence of the constraints — by proof where marked "proven", otherwise empirically, at zero
violations under large-scale sampling), **withdrawn** (our own claim, retracted under verification), and
**confirmed**. One further class, **declined**, records a claim deliberately left *unmeasured* by a
recorded scope decision — kept on this ledger so the choice not to test something is as public as the
tests. The register throughout is respect: every decidable claim below was concrete and
falsifiable, which is precisely what made it worth testing — vaguer claims survive by being untestable.

**Authority note:** the technical reports are authoritative; this page is an index over them. On any
discrepancy between a row here and its linked report, the report wins — and the discrepancy is a bug
in this page (report it).

| Claim | Source | Verdict | Finding | Proof |
|---|---|---|---|---|
| A better King Wen exists via reordering | [McKenna & Mair 1979](CITATIONS.md#mckenna-mair1979) | **ANSWERED** (prong 1, measured) · **REFUTED** (prong 2, proven) | The "defects" are among the sequence's rarest features (a measured-values judgment, not an impossibility); the required Gray-code construction is impossible under the pairing (2-line parity proof) | [TR-8](../reports/TR8_REORDERING_REVISITED.md) |
| The constraints uniquely determine King Wen | the strong reading of the literature's derivation claims + this project's own early working hypothesis (closest direct assertor: Li Shangxin 2007, for his own principle inventory — [attribution note](CITATIONS.md#uniqueness-conjecture); updated 2026-08-29 from "no direct assertor known") | **REFUTED** | ~5×10³¹ orderings satisfy all published constraints; ~15–20 further adjacency facts needed (an observed-rate extrapolation of ~12 boundaries — NOT a floor of any kind; TR-4 v1.16 states the result is neither a hard nor a heuristic floor and removed the word rather than qualifying it) | [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) |
| An uncorrupted, all-rules-perfect precursor existed | the strong composite reading of the corruption trope over the assembled four-rule inventory — the assembly is ROAE's; no single author asserted it ([Moore's](CITATIONS.md#moore2005) narrower conjecture, a precursor perfect under *his* rules, is CONFIRMED — [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) §3; [Schulz 1990](CITATIONS.md#schulz1990-motifs) read the same exceptions as design, not corruption) | **REFUTED** | The four strongest rules are jointly unsatisfiable for any C1∩C2∩C4∩C5-valid ordering (DRAT-certified); no such precursor can exist | [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) + [certificates/](../reports/certificates/) |
| Terminal pair #63/64 is uniquely minimal in derivative groups | [Davis 2012](CITATIONS.md#davis2012), p.257 n2 | **REFUTED** | Under the literal reading (fewest distinct derivatives) twelve of the 32 pairs beat #63/64's 12, attaining the minimum of 10 — among them his own worked example #23/24 (10 in 5 runs); under Davis's contiguous-group metric #51/52 ties #63/64 at 3 runs. The claim fails at "no other case" under every reading we could construct (Davis's own worked examples verify individually) | [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| Davis's compositional units are population-distinctive | Davis 2012 (7–16 mirror, terminal contiguity, etc.) | **CORRECTED** | Null after [Bonferroni](CITATIONS.md#bonferroni1936) — typical-to-mildly-uncommon among valid orderings; his #43–50 array is the one notable (family-scoped; below the global 91-observable ≈5.5×10⁻⁴ bar) | [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| Complement distance is minimized by design | earlier ROAE framing (after classical observations) | **CORRECTED** (self) | 776 is a ceiling KW sits at, not a minimum — the *minimum seen* is 424 at the 100T canonical and 392 at the 560T canonical (search-depth minima, not the constraint-space floor), and ties at exactly 776 run ≈10% **at those depths** (9.91% at 100T, 10.11% at 560T; the full-space rate is unmeasured). The constraint-space floor is far lower: a SAT witness attains C3 = 112 ([certificates/c3_positional_witnesses.txt](../reports/certificates/c3_positional_witnesses.txt), G = 12) | [SOLVE_SUMMARY Rule 3](SOLVE_SUMMARY.md), [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) |
| Eight classical/modern "design choices" — seven distinct predicates; r3 and p1c4 are extensionally the same one under two citations (TR-1 §3(2)) — (registry rules mmt4, p1c4, s1, s6, r3, r4, r5, c2 — incl. McKenna & Mair's complement-pair HD-6 rule, Schöter's XOR and Klein-orbit structures, Radisic's pairing-cost 120) | eight centuries of literature | **FORCED** (all eight proven, 2026-07-21) | Each of the eight is a theorem: constant on the entire C1 space (a superset of the measured population), hence equal to KW's value on every C1–C5 ordering — machine-checked in Lean 4 (lean/C1RuleConstants.lean); the zero-violation 1.0 readings in 2×10¹⁰ weighted probes now serve as instrument validation, not the basis of the claim. The separately-proven no-5 implication chain (behind McKenna's 3:1 even:odd ratio) is an additional theorem, not one of the eight. Consequences of the constraints, not choices | [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md), [lean/](../lean/README.md) |
| Exactly 15 parity alternations chosen by the arranger | parity-rule observations since Zhu Yuansheng (13th c.), who recognized the single exception to the gender/position-parity rule; the exact-15 count is, to our knowledge, first proven here (TR-6 §6) | **FORCED** (proven) | A theorem of C1+C5 — proven two independent ways (prose; Lean 4 kernel), with a SAT/DRAT check that corroborates by mechanizing the counting step rather than standing alone (independence retracted 2026-08-29) | [TR-6](../reports/TR6_PARITY_SKELETON.md), [lean/](../lean/) |
| KW's symmetry search found no nontrivial automorphisms | earlier ROAE publication | **CORRECTED** (self) | The search was wrong: an order-48 group exists; every canonical **record** has exactly 23 record-level twins (orientation-explicit *sequence* orbits have size 48 — TR-5 §4 level precision) | [TR-5](../reports/TR5_SYMMETRY.md) |
| Boundary-minimum is non-monotone with scale (4 → 5 → 4) | earlier ROAE publication (2026-06-11) | **CORRECTED** (self, 2026-07-04) | A survivor-counting artifact: the "4 at 560T" stopped at 1 remaining non-KW survivor instead of 0. The trajectory is monotone 4 → 5 → 5, with the identical 5-set {1, 4, 21, 25, 27} at 100T and 560T; the lone 4-boundary survivor is the same ordering at both scales — KW with positions 2–3 pair-swapped — indexed rec#330177707 in the 560T canonical's own sort order (rec#104178045 at 100T, rec#21262918 at 10T d3; a rec# is a position in one dataset, not a cross-scale identifier — [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md)). *Reproduction inputs: the 10T/100T analyze logs ship under `runs/`; the 560T leg reads `analyze_v3_560T.log` from the archived 560T canonical, which is not in this repository* | [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md) |
| Davis's per-trigram rotation quartet has "no further example" | Davis 2012, p.114 | **WITHDRAWN** (our challenge) | Our initial refutation failed hostile verification — under the fairest reading his claim holds; we retracted before publication | [TR-10 methods note](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| Davis's surviving rotation-quartet uniqueness marks a population-distinctive configuration | Davis 2012, pp. 113–114 (design reading; the in-KW uniqueness itself stands — row above) | **ANSWERED** (measured NULL, 2026-07-11) | Pre-registered **privately** (git-timestamped private-repo commit, not a public registration — see [TR-10 §3b](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)) before measurement at his own instance's compactness: a Davis-compact quartet is population-**common** — ~88% of valid orderings contain at least one (mean 1.86; KW's single instance is *below* the mean; two-sided p = 0.849 against a 0.05/12 gate). True in KW, unremarkable across the population; nothing promotes | [TR-10 §3b](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| Winds (Xun) recur at the decade 7/8 slots by design | Davis 2012, p. 114 | **ANSWERED** (measured NULL, 2026-07-11) | KW carries Xun at 5 of the 12 x7/x8 slots (his list of four was incomplete — #28 also qualifies; TR-10 §4). Population mean 2.90, P(≥5) = 7.4×10⁻², two-sided p = 0.148 — mildly above expectation, far from the frozen 0.05/12 gate. Registered at low prior (audit-flagged selective); reported for completeness, per the publish-all-registered pre-commitment | [TR-10 §3b](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| The no-5-transition property | [McKenna & McKenna 1975](CITATIONS.md#mckenna-mckenna1975) | **CONFIRMED** + contextualized | Verified at scale; shared by [Jing Fang](CITATIONS.md#jingfang); the authentic Mawangdui order has exactly one 5-line transition, at a trigram-octet seam (corrected 2026-07-05 per [Shaughnessy 2022](CITATIONS.md#shaughnessy2022) Table 11.2 — an earlier erroneous array scored zero; the "classical design norm" framing is withdrawn) | [CRITIQUE](CRITIQUE.md), [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) |
| The pairing is the unique Hamming-optimal comp/rev matching | [Radisic 2026](CITATIONS.md#radisic2026) (arXiv preprint) | **CONFIRMED** (independent) | His Lean 4 + Mathlib artifact independently rebuilt + re-verified 2026-07-26; the theorem is also machine-checked in-repo with a kernel-only proof, including the full-K₄ scope guard (comp∘rev matchings can do better, so the comp/rev scoping is load-bearing) — [lean/HammingOptimalMatching.lean](../lean/HammingOptimalMatching.lean) | [CITATIONS](CITATIONS.md), [lean/](../lean/README.md) |
| Nuclear rule orients 29/30 pairs, one declared exception (pair 3/4) | [Van den Berghe](CITATIONS.md#vandenberghe1999) c. 1999–2002 | **CONFIRMED** + sharpened (scope corrected 2026-07-26) | His 29/30 verifies exactly; exact fiber enumeration shows 29 is the maximum of the **C4-oriented fiber** — the 1,720,320 valid orientations of KW's pair sequence keeping the received (63, 0) opening — definitional, not classically attested (narrowed 2026-09-01) — (12 attain it, P = 6.9754×10⁻⁶) — where 30/30 is unattainable, so his exception is forced *given the received opening orientation*. On the pair-only-C4 fiber (2,703,360 vectors, both openings; re-checked 2026-07-26 after the "Theorem 6" retraction) exactly **2 vectors attain 30/30, both opening (0, 63)** — the minimal one reverses precisely the opening pair and his own declared exception pair 3/4 — so the exception is forced by the classical opening, not by pair geometry alone (fiber-wide P(X ≥ 29) = 1.1097×10⁻⁵). A fitted description at the (C4-oriented) fiber ceiling, not independent confirmation. *Reproduction inputs: `reports/evidence/f5/` ships **both** instruments — the fixed-(63, 0) Mode C scan (`f5_modec_fiber.py`) and, since 2026-09-04, the two-opening pair-only-C4 re-check (`f5_pair_only_fiber.py`) with the direct `vdb_nucorient` re-scoring of the two 30/30 vectors (`f5_pair_only_verify30.py`), each beside its archived output and each rerunning byte-identically from a clone (TR-1 §7 v1.33)* | [TR-1 §7](../reports/TR1_EIGHT_CENTURIES_MEASURED.md), [evidence/f5](../reports/evidence/f5/README.md) |
| The six "big"/"small"-named hexagrams (#9/#14/#26/#28/#34/#62) sit small at the ends, big in the middle by pair-slot | Davis 2012, pp. 94–96 | **DECLINED** (unmeasured, 2026-07-11) | Not tested, by a recorded scope decision: hexagram *names* are tradition/translation-dependent semantic attributes, outside the bit-structure instrument ([TR-10 §5(c)](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)), and the (S,B,B,B,B,S) target is itself a KW-extracted template (the circularity caveat). Not a verdict on Davis's reading; the follow-up Davis-family Bonferroni denominator stays frozen at /12; a landing-time analytic power note additionally shows the test was uninformative by construction — under the pair-exchangeable (C1) null, every predicate of its class has minimum attainable p exactly 1/15 ≈ 0.067, above the unadjusted 0.05 gate and 16× above the 0.05/12 family gate it would have faced ([TR-10 §3b](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)) | [HISTORY 2026-07-11](HISTORY.md), [TR-10 §3b](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| Drasny's "Rule of Ten": the eight trigram-defined groups occupy decade-arithmetic "rooms" (ten deviant pairs) | [Drasny c. 2007](CITATIONS.md#drasny2007), *The Yi-globe*, ch. IV | **CONFIRMED** (as a fitted description; data-like as a design test, 2026-07-11) | True and verified: his group classifier reduces to pure bit predicates (Table 4.1 reproduced 64/64, two-language `--db1-verify` gate) and KW's conformity is X = 22/32, his ten deviant pairs reproducing exactly. But each "room" is verifiably the maximum-coverage decade window for its own group's KW positions (plus a residue room), so the fitted coverages sum to 22 by construction — the count scores KW against a template extracted from KW. No p-value attached, no design inference (extraction-circularity policy); separate Drasny family, not the Davis /12 | [TR-10 §3b](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md), [CRITIQUE](CRITIQUE.md) |
| The C5-layer population size is ≈1.0971×10³⁹ (estimator, ±0.01%) | earlier ROAE measurement ([TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) §3, 2026-07-01) | **CONFIRMED** (self, computed exactly 2026-07-16) | \|C1∩C2∩C4∩C5\| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688 exactly — the suite's second exact full-scale count (the first: \|C1∩C2∩C4\|, 2026-07-04), two-instrument as of 2026-07-25 (independently recomputed at full scale by verify.c's IE transfer-walk engine, exact match — TR-11 §10(vi)), divisible by **48**, as the free-action theorem requires of an orientation-explicit sequence count (divisibility by 24 is the weaker record-level corollary — TR-5 §4 level precision, 2026-08-01); the exact value falls inside the estimate's stated ±0.01% envelope (the 0.0044% figure is the estimate's rounding gap, not a resolved error). The flagship C1–C5 count (1.3287×10³⁸) and the C3 layer remain estimates | [TR-11](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) |

Most corrections to our own published numbers are itemised one-per-entry in
[CORRECTIONS.md](CORRECTIONS.md) — the append-only record, which for each entry states what was
claimed before, what is claimed now, and how it was found; a `Commits` field is carried by some
entries (5 of the 35 CX entries at this writing) but is not yet part of every entry, and backfilling
it is open. That record is also not exhaustive over the digest below: the MDL arithmetic cascade is
recorded in place, in [DESCRIPTION_LENGTH.md](DESCRIPTION_LENGTH.md)'s dated correction note and
TR-9's draft-stage corrections note, and the TR-1/2/3/9 v1.5 scope corrections in those four
reports' own Revision-history rows — and the `--verify-wrap-parity` false theorem in
[TR7_CIRCULAR_READING.md](../reports/TR7_CIRCULAR_READING.md)'s Verification Guide, which names the
public fix commit `0c24637` (2026-07-03). None of these three has a CORRECTIONS.md entry: all three
predate that ledger's creation on 2026-08-02 and were never back-filled into it. The summary
paragraph that follows is therefore a digest of the self-correction practice as a whole, not of that
one file, and not a substitute for either.

Corrections to our own published numbers (the never-silent ledger): the MDL arithmetic (144.4→143.7
cascade), a false theorem in `--verify-wrap-parity`'s output, the TR-1/2/3/9 v1.5 scope corrections,
the 100T canonical record count (a 2026-05-30 doc-level "correction" to 3,432,399,298 divided the
file size by 32 without subtracting the 32-byte header; re-corrected to 3,432,399,297 on 2026-07-04
against the primary logs, `solutions.meta.json`, and the verify output — the sha256 anchors were never
affected), and — the most serious to date — **the retracted "Theorem 6 (forced orientation)"
(2026-07-26)**: SPECIFICATION/METHODS/SOLVE/CRITIQUE/SOLVE_SUMMARY and TR-1 §7 asserted, with
mutually contradictory statuses (theorem / prose proof / "not yet analytically proven"), that
C1+C4(pair)+C5 force the opening orientation s₀ = 63, s₁ = 0. The claim is **false** —
complementation (x ↦ x ⊕ 63) is an exact symmetry of C1∩C2∩C3∩C5 broken only by oriented C4, now
machine-checked in [lean/KingWen.lean](../lean/KingWen.lean) (kernel-only trust base), and the
claim's cited enumeration evidence was circular (the solver hardcodes the orientation it was cited
as evidence for). C4's orientation is definitional — our convention, not an inheritance from the
classical record ⚠ **[CORRECTED 2026-09-01 — this clause previously described the orientation as
classically attested on the strength of the *Xugua*. The *Xugua* does not attest the WITHIN-PAIR
order: 有天地，然後萬物生焉 sequences *the pair* before the myriad things, and 天地 is a compound, not an
ordering of Heaven over Earth. C4's *pair choice* is the classical part and is unaffected; the
pairing rule C1 is the classically attested one (孔穎達, 7th c.). Narrowed in
[METHODS.md](../reports/METHODS.md) §"Constraint set" 2026-08-30 and in
[SPECIFICATION.md](SPECIFICATION.md) §Constraints 2026-09-01.]**; TR-9's ledger
already priced C4 at its full 6 bits, so no bit value moves; all counts/shas count the defined
(oriented) system and are unaffected. TR-1 §7's fiber numbers are re-scoped to the C4-oriented
fiber, with the pair-only fiber (2,703,360) re-checked — see the Van den Berghe row above —
each documented in place with a correction note. Self-corrections are listed beside external
ones deliberately: the method is the same, and it has to cut both ways to mean anything.

Every verdict above is reproducible from the artifacts its report names — but not every one is
reproducible *from this repository alone*.
[reports/certificates/verify_all.sh](../reports/certificates/verify_all.sh) re-checks the certified
impossibilities, and per-claim commands live in each report's Verification Guide; two rows, however,
need inputs that do not ship here — the boundary-minimum row's 560T leg (its analyze log lives in the
archived 560T canonical) and the Van den Berghe row's two-opening 30/30 result (its instrument and
raw output are a promised follow-up commit). Both are annotated in place above. Rows whose inputs are
archived canonicals are reproducible against those archives, not against a fresh clone.
⚠ **[CORRECTED 2026-09-04 — this sentence named TWO such rows and now names ONE.** The Van den
Berghe row's two-opening instrument and raw output **shipped on 2026-09-04** as
`reports/evidence/f5/f5_pair_only_fiber.py` / `.out` and
`reports/evidence/f5/f5_pair_only_verify30.py` / `.out`, discharging the follow-up commit TR-1 §7
promised on 2026-07-26 (TR-1 v1.33). That row is now reproducible from a fresh clone like the rest.
The boundary-minimum row's 560T leg is unaffected and remains the one row here whose input does not
ship.]**
