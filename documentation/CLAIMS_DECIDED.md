# Claims Decided — the empirical scorecard

One page for the question "what has ROAE actually settled?" Every entry: the claim, who made it, what
we found, and where the proof lives. "Decided" spans a spectrum — **refuted** (shown false as stated),
**corrected** (true with a different scope/value), **forced** (asserted as design, shown to be a
mathematical consequence), **withdrawn** (our own claim, retracted under verification), and
**confirmed**. The register throughout is respect: every decidable claim below was concrete and
falsifiable, which is precisely what made it worth testing — vaguer claims survive by being untestable.

**Authority note:** the technical reports are authoritative; this page is an index over them. On any
discrepancy between a row here and its linked report, the report wins — and the discrepancy is a bug
in this page (report it).

| Claim | Source | Verdict | Finding | Proof |
|---|---|---|---|---|
| A better King Wen exists via reordering | McKenna & Mair 1979 | **REFUTED** (both prongs) | The "defects" are among the sequence's rarest features; the required Gray-code construction is impossible under the pairing (2-line parity proof) | [TR-8](../reports/TR8_REORDERING_REVISITED.md) |
| The constraints uniquely determine King Wen | folk conjecture (multiple authors) | **REFUTED** | ~5×10³¹ orderings satisfy all published constraints; ~13 further adjacency facts needed | [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) |
| An uncorrupted, all-rules-perfect precursor existed | implied by Moore/Schulz corruption readings | **REFUTED** | The four strongest rules are jointly unsatisfiable for any pairing-preserving ordering (DRAT-certified); no such precursor can exist | [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) + [certificates/](../reports/certificates/) |
| Terminal pair #63/64 is uniquely minimal in derivative groups | Davis 2012, p.257 n2 | **REFUTED** | Pairs 21/22 and 51/52 tie or beat it under every fair reading (Davis's own examples verify) | [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| Davis's compositional units are population-distinctive | Davis 2012 (7–16 mirror, terminal contiguity, etc.) | **CORRECTED** | Null after Bonferroni — typical-to-mildly-uncommon among valid orderings; his #43–50 array is the one notable | [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| Complement distance is minimized by design | earlier ROAE framing (after classical observations) | **CORRECTED** (self) | 776 is a ceiling KW sits at, not a minimum (min 424; ~10% tie) | [SOLVE-SUMMARY Rule 3](SOLVE-SUMMARY.md), [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) |
| Eight classical/modern "design choices" (incl. 3:1 even:odd, xiaoxi placements) | eight centuries of literature | **FORCED** | Population mass exactly 1.0 at 2×10¹⁰ probes (one proven analytically) — consequences of the constraints, not choices | [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) |
| Exactly 15 parity alternations chosen by the arranger | observed since Zhu Yuansheng (13th c.) | **FORCED** (proven) | A theorem of C1+C5 — three independent proofs incl. Lean kernel | [TR-6](../reports/TR6_PARITY_SKELETON.md), [lean/](../lean/) |
| KW's symmetry search found no nontrivial automorphisms | earlier ROAE publication | **CORRECTED** (self) | The search was wrong: an order-48 group exists; every solution has exactly 23 twins | [TR-5](../reports/TR5_SYMMETRY.md) |
| Davis's per-trigram rotation quartet has "no further example" | Davis 2012, p.114 | **WITHDRAWN** (our challenge) | Our initial refutation failed hostile verification — under the fairest reading his claim holds; we retracted before publication | [TR-10 methods note](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) |
| The no-5-transition property | McKenna & McKenna 1975 | **CONFIRMED** + contextualized | Verified at scale; shared by Mawangdui and Jing Fang (a classical design norm, not KW-specific) | [CRITIQUE](CRITIQUE.md), [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) |
| The pairing is the unique Hamming-optimal matching | Radisic 2026 | **CONFIRMED** (independent) | Machine-verified independently | [CITATIONS](CITATIONS.md) |

Corrections to our own published numbers (the never-silent ledger): the MDL arithmetic (144.4→143.7
cascade), a false theorem in `--verify-wrap-parity`'s output, and the TR-1/2/3/9 v1.5 scope corrections
— each documented in place with a correction note. Self-corrections are listed beside external ones
deliberately: the method is the same, and it has to cut both ways to mean anything.

Every verdict above is reproducible: [reports/certificates/verify_all.sh](../reports/certificates/verify_all.sh)
re-checks the certified impossibilities; per-claim commands live in each report's Verification Guide.
