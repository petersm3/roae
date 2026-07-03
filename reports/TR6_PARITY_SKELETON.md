# [TR-6](TR6_PARITY_SKELETON.md) — The Parity Skeleton: One Theorem, Three Verifications
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Abstract
In every sequence satisfying C1–C5, the 32 pairs are parity-homogeneous, split exactly 16 even / 16 odd,
and the pair ordering exhibits **exactly 15 parity-class alternations** across its 31 pair boundaries —
forced by the constraint system, not a King Wen choice (KW's count is 15, necessarily). The theorem has
been verified in **three independent modalities**: a short prose proof (three lemmas + the C5
odd-distance count); a **Lean 4 kernel-checked general theorem** (`alternations_15_general` — every C1+C5
sequence of 64 six-bit values has exactly 15 alternations, proven by structural argument, not finite
enumeration; core Lean 4, no mathlib); and a **SAT decision** (both "≤14 alternations" and "≥16
alternations" are UNSAT under C1+C2+C4+C5, with DRAT certificates independently verified by drat-trim).
Building the SAT encoding surfaced and corrected a four-cell tabulation error in the published
within/between-pair distance decomposition — formalization is the project's best error detector. The
skeleton sits beneath a genuine literature lineage of empirical parity observations (Zhu Yuansheng, 13th
c. → Schulz 1990 → Moore 2005), which the theorem does not derive from but visibly rhymes with: those are
KW-specific observations; this is a forced property of the constraint system that every valid ordering
inherits.

## Sections
1. **The theorem and its prose proof.** Lemma 1 (pairs are parity-homogeneous): popcount(partner(h)) ≡
   popcount(h) (mod 2) — bit reversal preserves popcount exactly; complement gives 6 − popcount(h). Lemma 2
   (16/16 class split): 32 hexagrams of each popcount parity, pairs lie wholly inside one class (verified
   exhaustively). Lemma 3 (transition parities): within-pair transitions have even Hamming distance
   (reverse-pairs d ∈ {2, 4, 6}; complement-pairs d = 6); a between-pair transition has parity ε(p) ⊕ ε(q),
   independent of orientation choices. Theorem: C5 fixes the 63-transition distance multiset at
   {1:2, 2:20, 3:13, 4:19, 6:9}, containing exactly 2 + 13 = **15 odd distances**; all odd transitions are
   between-pair, and their count equals the number of adjacent class-alternations — hence exactly 15.
   Corollary: summing parities recovers the wrap-around-parity theorem (SPECIFICATION.md). The theorem
   generalizes it and supplies the "novel structural theorem" the earlier C5-tightening investigation
   concluded would be required for any further provable pruning.
2. **The corrected within/between decomposition.** Designing the CNF encoding of C5 required the exact
   within/between-pair distance split — and the recomputation contradicted CRITIQUE's published table.
   True values (machine-checked, summing exactly to C5's multiset): within-pair **{2:12, 4:12, 6:8}** (was
   11/13/8), between-pair **{1:2, 2:8, 3:13, 4:7, 6:1}** (was 2/7/14/7/1). The "14 threes" belongs to the
   circular reading (wrap-around adds one), consistent with McKenna's own circular framing and this
   theorem; the "4×" concentration prose was a delta-misread-as-ratio (true linear excess ≈1.3×). Fixed
   with correction notes. The pattern repeats across the project: every time a claim must be re-derived
   for a machine (Lean, the estimator, now SAT), latent errors surface.
3. **Modality 2 — Lean, kernel-checked.** lean/KingWen.lean (core Lean 4 only, no mathlib) first pins the
   finite lemmas by `native_decide` (`partner_preserves_parity`, `parity_split_32_32`,
   `xor_parity_identity`; plus `kw_alternations_15` — King Wen's own count). Tier 2b (2026-07-03) then
   proves the **general theorem**: `alternations_15_general` — every C1+C5 sequence of 64 six-bit values
   has EXACTLY 15 parity-class alternations, by structural proof (transitions-as-range-map bridge lemma;
   index-parity split via a kernel-decided permutation of range 63; within-pair evenness from C1; the C5
   odd-transition count). With `wrap_parity_general` (Tier 2, same day), both sequence-level theorems of
   the project are kernel-verified for ALL valid sequences — the Lean layer is no longer just "finite
   facts checked."
4. **Modality 3 — SAT, certificate-verified.** The SAT layer (`sat.py`, encoding derived from solve.py's
   constraint definitions, external kissat solver) decides both directions exactly: "≤14 alternations" and
   "≥16 alternations" are **UNSAT under C1+C2+C4+C5** — the theorem's third independent verification.
   Certificates are archived and independently verified: drat-trim (2026-07-03) checks `s VERIFIED` for
   both alt-le-14 and alt-ge-16 (and the two other project UNSAT proofs) against regenerated CNFs. The
   encoder's round-trip validation's first solver model, pleasingly, is King Wen itself. Three modalities,
   three failure surfaces: a prose proof can hide a lemma gap, a Lean proof trusts the formalization of
   the statement, a SAT proof trusts the encoding — their agreement is the point.
5. **Consequences.** (a) A provable, orientation-free skeleton constraint: the class pattern (a string of
   16 E's and 16 O's) must contain exactly 15 changes — only 82,818,450 of C(32,16) = 601,080,390
   arrangements do, a ×7.26 reduction at the arrangement level, and C4 pins the first pair to the even
   class (pair {63, 0}). (b) An O(1) exact prefix prune (two-sided achievable-alternation interval check),
   exact by derivation, firing from the earliest placements. (c) Sha-lineage caveat: an exact prune
   preserves the solution set but changes node-visit ordering and counts, so budgeted canonical outputs —
   and canonical shas — would change; production adoption is a gated lineage decision. Nothing in the
   published canonicals is affected by the theorem itself. (d) Combined with the symmetry theorem (TR-5),
   the solution space has two proven skeletons: a 48-element relabeling group and a rigid 15-alternation
   parity profile — both properties of the constraint system that KW inherits rather than chooses.
6. **The lineage atop the skeleton (attribution).** To our knowledge the theorem as stated (the exact
   15-alternation count as a *forced* property of C1–C5) is first proven here; given how deep this
   literature runs, we state that with humility — corrections and prior-art pointers are welcomed via
   CITATIONS.md. The empirical parity observations sitting atop the skeleton deserve their credits as
   cousins of (not sources for) the theorem: **Zhu Yuansheng (13th century)** first recognized the single
   exception to the gender/position-parity rule (per Schulz 2018, fn. 42); **Schulz (1990, *JCP* 17:3)**
   stated that rule over his 36 consolidated units — the strongest measured literature discriminator, with
   exceptions at stations 25–26 (elaborated by Cook 2006; attribution corrected 2026-07-03 upon first-hand
   reading — Cook had been credited as primary); **Moore (2005, *Oracle Papers* No. 1)** stated the
   yin/yang pair-positioning parity rule over the 32 pair positions (King Wen complies 16/18). Cook (2006)
   separately states a gender/position-valence rule over his 36-class ordering. All are empirical,
   KW-specific, over different partitions; the theorem differs in kind — every valid ordering has exactly
   15 alternations — derived and machine-checked independently of each source, but the family resemblance
   is real and the credits stand.

## Verification Guide
- Theorem statement, lemmas, arrangement count: documentation/PARITY_ALTERNATION.md (lemma claims and KW's
  count verifiable in seconds from SPECIFICATION.md / solve.py; the arrangement count is the elementary
  compositions identity Σ_start C(15, blocks_E−1)·C(15, blocks_O−1); no enumeration data needed)
- Lean general theorem: `lean lean/KingWen.lean` (silence = all theorems check; Lean 4, tested 4.31.0) —
  `alternations_15_general`, `wrap_parity_general`, plus the finite lemmas
- SAT UNSAT both sides: `python3 sat.py --emit-cnf alt-le-14 f.cnf && kissat f.cnf` (and alt-ge-16);
  drat-trim verification record: documentation/LITERATURE_RULES_POPULATION_TESTS.md §SAT-decided
- Corrected decomposition + error narrative: documentation/HISTORY.md 2026-07-02 ("four-cell tabulation
  error"); corrected table in documentation/CRITIQUE.md
- Lineage and full citations: documentation/CITATIONS.md §Attributed candidate rules
- Wrap-parity corollary source theorem: documentation/SPECIFICATION.md

## TODO before review
- [ ] Confirm the corrected within/between table also carries its correction note in CRITIQUE.md itself
      (HISTORY says "fixed with correction notes" — cite the exact section)
- [ ] Decide whether to inline a 5-line excerpt of `alternations_15_general`'s statement from KingWen.lean
- [ ] One figure: the 16E/16O class string of King Wen with its 15 alternations marked
- [ ] Operator voice pass on §6 — attribution density is high; check it reads as credit, not throat-clearing

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
