# Claims Decided — the empirical scorecard

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
| The constraints uniquely determine King Wen | the strong reading of the literature's derivation claims + this project's own early working hypothesis (no direct assertor known — [attribution note](CITATIONS.md#uniqueness-conjecture)) | **REFUTED** | ~5×10³¹ orderings satisfy all published constraints; ~13 further adjacency facts needed | [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) |
| An uncorrupted, all-rules-perfect precursor existed | implied by [Moore's](CITATIONS.md#moore2005) corruption conjecture ([Schulz 1990](CITATIONS.md#schulz1990-motifs) read the same exceptions as design, not corruption) | **REFUTED** | The four strongest rules are jointly unsatisfiable for any pairing-preserving ordering (DRAT-certified); no such precursor can exist | [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) + [certificates/](../reports/certificates/) |
| Terminal pair #63/64 is uniquely minimal in derivative groups | [Davis 2012](CITATIONS.md#davis2012), p.257 n2 | **REFUTED** | Pairs 21/22 and 51/52 tie or beat it under every fair reading (Davis's own examples verify) | [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| Davis's compositional units are population-distinctive | Davis 2012 (7–16 mirror, terminal contiguity, etc.) | **CORRECTED** | Null after [Bonferroni](CITATIONS.md#bonferroni1936) — typical-to-mildly-uncommon among valid orderings; his #43–50 array is the one notable (family-scoped; below the global ~83-observable ≈6.0×10⁻⁴ bar) | [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| Complement distance is minimized by design | earlier ROAE framing (after classical observations) | **CORRECTED** (self) | 776 is a ceiling KW sits at, not a minimum (min 424; ~10% tie) | [SOLVE-SUMMARY Rule 3](SOLVE-SUMMARY.md), [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) |
| Eight classical/modern "design choices" (incl. 3:1 even:odd, xiaoxi placements) | eight centuries of literature | **FORCED** (empirical; one of eight proven) | Population mass 1.0 to estimator precision — no violating ordering in 2×10¹⁰ weighted probes; one proven analytically, the others zero-hit sampling results, not theorems — consequences of the constraints to that precision, not choices | [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) |
| Exactly 15 parity alternations chosen by the arranger | observed since Zhu Yuansheng (13th c.) | **FORCED** (proven) | A theorem of C1+C5 — three independent proofs incl. Lean kernel | [TR-6](../reports/TR6_PARITY_SKELETON.md), [lean/](../lean/) |
| KW's symmetry search found no nontrivial automorphisms | earlier ROAE publication | **CORRECTED** (self) | The search was wrong: an order-48 group exists; every solution has exactly 23 twins | [TR-5](../reports/TR5_SYMMETRY.md) |
| Boundary-minimum is non-monotone with scale (4 → 5 → 4) | earlier ROAE publication (2026-06-11) | **CORRECTED** (self, 2026-07-04) | A survivor-counting artifact: the "4 at 560T" stopped at 1 remaining non-KW survivor instead of 0. The trajectory is monotone 4 → 5 → 5, with the identical 5-set {1, 4, 21, 25, 27} at 100T and 560T; the lone 4-boundary survivor is rec#330177707 (KW with positions 2–3 pair-swapped) | [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md) |
| Davis's per-trigram rotation quartet has "no further example" | Davis 2012, p.114 | **WITHDRAWN** (our challenge) | Our initial refutation failed hostile verification — under the fairest reading his claim holds; we retracted before publication | [TR-10 methods note](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| The no-5-transition property | [McKenna & McKenna 1975](CITATIONS.md#mckenna-mckenna1975) | **CONFIRMED** + contextualized | Verified at scale; shared by [Jing Fang](CITATIONS.md#jingfang); the authentic Mawangdui order has exactly one 5-line transition, at a trigram-octet seam (corrected 2026-07-05 per [Shaughnessy 2022](CITATIONS.md#shaughnessy2022) Table 11.2 — an earlier erroneous array scored zero; the "classical design norm" framing is withdrawn) | [CRITIQUE](CRITIQUE.md), [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) |
| The pairing is the unique Hamming-optimal matching | [Radisic 2026](CITATIONS.md#radisic2026) (arXiv preprint) | **CONFIRMED** (independent) | Machine-verified independently (the Lean 4 + Mathlib artifact is checkable regardless of refereeing status) | [CITATIONS](CITATIONS.md) |
| Nuclear rule orients 29/30 pairs, one declared exception (pair 3/4) | [Van den Berghe](CITATIONS.md#vandenberghe1999) c. 1999–2002 | **CONFIRMED** + sharpened | His 29/30 verifies exactly; exact fiber enumeration shows 29 is the maximum of all 1,720,320 valid orientations of KW's pair sequence (12 attain it, P = 6.9754×10⁻⁶) and 30/30 is unattainable — his exception is proven forced. A fitted description at the fiber ceiling, not independent confirmation | [TR-1 §7](../reports/TR1_EIGHT_CENTURIES_MEASURED.md), [evidence/f5](../reports/evidence/f5/README.md) |
| The six "big"/"small"-named hexagrams (#9/#14/#26/#28/#34/#62) sit small at the ends, big in the middle by pair-slot | Davis 2012, pp. 94–96 | **DECLINED** (unmeasured, 2026-07-11) | Not tested, by a recorded scope decision: hexagram *names* are tradition/translation-dependent semantic attributes, outside the bit-structure instrument ([TR-10 §5(c)](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)), and the (S,B,B,B,B,S) target is itself a KW-extracted template (the circularity caveat). Not a verdict on Davis's reading; the follow-up Davis-family Bonferroni denominator stays frozen at /12 | [HISTORY 2026-07-11](HISTORY.md) |

Corrections to our own published numbers (the never-silent ledger): the MDL arithmetic (144.4→143.7
cascade), a false theorem in `--verify-wrap-parity`'s output, the TR-1/2/3/9 v1.5 scope corrections,
and the 100T canonical record count (a 2026-05-30 doc-level "correction" to 3,432,399,298 divided the
file size by 32 without subtracting the 32-byte header; re-corrected to 3,432,399,297 on 2026-07-04
against the primary logs, `solutions.meta.json`, and the verify output — the sha256 anchors were never
affected) — each documented in place with a correction note. Self-corrections are listed beside external
ones deliberately: the method is the same, and it has to cut both ways to mean anything.

Every verdict above is reproducible: [reports/certificates/verify_all.sh](../reports/certificates/verify_all.sh)
re-checks the certified impossibilities; per-claim commands live in each report's Verification Guide.
