# Every Valid Ordering Has Exactly 15 Parity-Class Alternations

**Result (Theorem, 2026-07-02):** In every sequence satisfying C1–C5, the 32 pairs — each of which is
*parity-homogeneous* (both members share popcount parity) — form exactly 16 even-parity and 16 odd-parity
pairs, and the pair ordering exhibits **exactly 15 parity-class alternations** across its 31 pair boundaries.
This is forced by C1+C5 rather than chosen; KW satisfies it necessarily (verified: KW's
alternation count is 15). ⚠ **Scope of "forced" (added 2026-09-02, Codex V2-F08 #1, prose batch P37):**
C5 is itself a regularity **read off King Wen** — [reports/METHODS.md](../reports/METHODS.md) grades it
"Extracted from KW (confirmatory, not predictive)" — so "forced" here is relative to KW-derived
constraints, **not** to an unconstrained arranger. This is the same conditional-forcing correction
[TR-7](../reports/TR7_CIRCULAR_READING.md) §3 made on 2026-07-20 (revision v2.1, adversarial-review
F-14a); the prior phrasing smuggled the KW-derived constraints in as premise. The theorem generalizes the wrap-around-parity theorem ([SPECIFICATION.md](SPECIFICATION.md)), which is
recovered as its total-parity corollary, and it supplies the "novel structural theorem" that the earlier
C5-tightening investigation concluded would be required for any further provable pruning.

**Reproduce every figure below:** `python3 verify.py --check-parity-alternation`
(added 2026-08-16). It re-derives the 63 transition distances and their multiset
`{1:2, 2:20, 3:13, 4:19, 6:9}` from the King Wen table, confirms the 15 odd transitions,
confirms that a pair's parity class is **well defined** (rather than assuming Lemma 3)
and that the 32 pairs split **16/16**, measures King Wen's own alternation count, and
counts the 15-change arrangements **twice by routes that share no code** — a dynamic
program over (position, evens used, last class, changes), checked against the closed
form `2·C(15,7)² = 82,818,450` that follows from 15 changes meaning 16 alternating runs.
Verdict `PARITY_ALTERNATION=PASS`, reads no files, runs in about a second.
*It attests the FIGURES. The theorem is a proof and is not re-proven by it.*

## Statement and proof

**Lemma 1 (pairs are parity-homogeneous).** For every h ∈ H, popcount(partner(h)) ≡ popcount(h) (mod 2).
*Proof.* If partner(h) = rev(h): bit reversal permutes bits, preserving popcount exactly. If partner(h) =
comp(h) = h ⊕ 63: popcount(comp h) = 6 − popcount(h) ≡ popcount(h) (mod 2). ∎
Each pair therefore has a well-defined **parity class** ε(p) ∈ {even, odd}, independent of orientation.

**Lemma 2 (16/16 class split).** The canonical pairing of H contains exactly 16 even-class and 16 odd-class
pairs. *Proof.* H has 32 hexagrams of each popcount parity; by Lemma 1 every pair lies wholly inside one
parity class, so the 32 even-parity hexagrams form 16 pairs and likewise the odd. ∎ (Verified exhaustively.)

**Lemma 3 (transition parities).** Within-pair transitions always have even Hamming distance (reverse-pairs:
d(h, rev h) ∈ {2, 4, 6} for non-palindromes; complement-pairs: d = 6). A between-pair transition from pair p
to pair q has parity ε(p) ⊕ ε(q), **independent of the orientation choices**: d(b, a) = popcount(b ⊕ a) ≡
popcount(b) + popcount(a) (mod 2), and both candidate exit/entry hexagrams of a pair share its class. ∎

**Theorem.** C5 fixes the multiset of the 63 transition distances at {1:2, 2:20, 3:13, 4:19, 6:9}, which
contains exactly 2 + 13 = **15 odd distances**. By Lemma 3 all odd transitions are between-pair, and the
number of odd between-pair transitions equals the number of adjacent class-alternations in the 32-pair
ordering. Hence **every C1–C5-valid ordering has exactly 15 parity-class alternations**. ∎

**Corollary (wrap parity).** Summing parities recovers the wrap-around-parity theorem: total odd count 15 ⇒
the linear sequence's endpoint popcounts differ in parity ⇒ odd wrap distance, as previously proven.

## Consequences

1. **A provable, orientation-free skeleton constraint.** Before any orientation or within-class choice is
   made, the *class pattern* of a candidate ordering (a string of 16 E's and 16 O's) must contain exactly 15
   changes. Only **82,818,450 of the C(32,16) = 601,080,390** class arrangements do — a **×7.26 reduction at
   the arrangement level** — and C4 further pins the first pair to the even class (pair {63, 0}).
2. **An O(1) exact prefix prune.** During enumeration, track alternations used and the remaining class
   counts; the prefix is viable only if the remaining sequence can realize exactly the residual alternation
   deficit (a two-sided interval check: with e even and o odd pairs left and current end class known, the
   achievable alternation range is computable in constant time). The prune is *exact* (derived from the
   theorem, no false negatives) and fires from the earliest placements.
3. **Sha-lineage caveat.** An exact prune preserves the full solution set but changes node-visit ordering
   and counts, so per-cell **budgeted** canonical outputs — and therefore canonical shas — would change.
   Adopting the prune in production enumeration is a lineage decision (as with the v2 prune bundle), gated
   and exploration-track first. Nothing in the published canonicals is affected by the theorem itself.
4. **Structure insight.** Combined with the symmetry theorem ([SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md)), the solution space now has
   two proven skeletons: a 48-element relabeling group and a rigid 15-alternation parity profile. Both are
   properties of the *constraint system*; KW inherits them rather than choosing them.

## Novelty status and related prior observations (attribution)

To our knowledge the theorem as stated (the exact 15-alternation count as a *forced* property of C1–C5) is
first proven here; given how deep this literature runs (the parity-rule *exception* below was noticed by
Zhu Yuansheng in the 13th century), we state that with humility — corrections and prior-art pointers are
welcomed via [CITATIONS.md](CITATIONS.md).

Two independent, differently-formulated parity rules for the King Wen sequence exist in prior literature and
deserve credit as cousins of (not sources for) this theorem: **[Cook (2006)](CITATIONS.md#cook2006)** states a gender/position-valence
parity rule over his 36-class ordering, and **[Moore (2005, *Oracle Papers* No. 1)](CITATIONS.md#moore2005)** states a yin/yang
pair-positioning parity rule over the 32 pair positions (King Wen complies 16/18). Both are empirical
KW-specific observations over different partitions; the theorem above differs in kind — it is a *forced*
property of the C1–C5 constraint system (every valid ordering has exactly 15 alternations), derived and
machine-checked independently of either source, but the family resemblance is real and the credits stand.
See [CITATIONS.md](CITATIONS.md) §Attributed candidate rules.

## Verification

All lemma claims and KW's alternation count are verifiable in seconds (popcounts, the canonical pairing, and
the KW sequence are all in SPECIFICATION.md / solve.py); the arrangement count is the elementary
compositions identity Σ_start C(15, blocks_E−1)·C(15, blocks_O−1) over the two starting classes for k = 15
changes. An independent checker needs no enumeration data.
