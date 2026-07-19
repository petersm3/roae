# Formal Specification of the King Wen Sequence

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is a permutation **S** = (s₀, s₁, ..., s₆₃) of the set **H** = {0, 1, ..., 63} satisfying the following constraints. Within every enumerated dataset to date, constraints C1–C7 plus four greedy-ordered boundary constraints single out King Wen exactly; that uniqueness does NOT extend to the full constraint-satisfying space: the full C1–C7 space is measured at ≈5.2×10³¹ orderings (see the refuted [Conjecture (Uniqueness)](#theorems) below). The space satisfying C1–C5 alone is estimated at ≈10³⁸ orderings ([SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md)).

> Looking for a plain-language version of these constraints and how the solver searches for orderings that satisfy them? See [BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md).

## Definitions

Let **H** = {0, 1, ..., 63} be the set of 6-bit integers (hexagrams).

**Bit reversal:** rev(n) reverses the 6-bit representation of n.
```
rev(n) = (n₀ << 5) | (n₁ << 4) | (n₂ << 3) | (n₃ << 2) | (n₄ << 1) | (n₅ << 0)
where nᵢ = (n >> i) & 1
```

**Hamming distance:** d(a, b) = popcount(a ⊕ b), the number of differing bits.

**Complement:** comp(n) = n ⊕ 63 (= n ⊕ 111111₂), flipping all 6 bits.

**Partner:** For each h ∈ **H**, partner(h) = rev(h) if rev(h) ≠ h, else comp(h).

**Pair canonical form:** pair(h) = {h, partner(h)}.

**Difference wave:** D(S) = (d(s₀,s₁), d(s₁,s₂), ..., d(s₆₂,s₆₃)), a sequence of 63 values.

**Complement distance:** For a permutation S, let pos(h) be the position of h in S. The mean complement distance is:
```
cd(S) = (1 / |H|) × Σ_{h ∈ H} |pos(h) - pos(comp(h))|
```
where |H| = 64. Under `comp(h) = h ⊕ 63`, no hexagram is self-complementary (that would require `63 = 0`), so the sum runs over all 64 hexagrams — each complement-pair contributes its position delta twice (once from each member). The resulting `cd(S)` is therefore `2 × Σ_pairs |Δpos| / 64 = Σ_pairs |Δpos| / 32` — the mean complement-pair distance. For King Wen, `cd(S) = 12.125`, or `776` when expressed as `64 × cd(S)` to stay in integer arithmetic (this is the "x64" representation the solver uses internally).

## Constraints

**S** satisfies the following constraints (unique within every enumerated dataset to date; see the [Conjecture (Uniqueness)](#theorems) for full-space status). Note: C1 and C2 are structural properties observable in the sequence. C3 and C5 were extracted from King Wen and used to constrain the search — they are confirmatory (consistent with King Wen) rather than predictive (derived independently). C4 stands apart: its pair choice (Heaven/Earth first) is independently attested in the classical tradition (the *Xugua* commentary) centuries before any enumeration, and its orientation is a theorem (Theorem 6), not an extracted parameter. C6 and C7 are specific adjacency choices that no aggregate mathematical property can replace.

**Numbering note.** The narrative document [SOLVE.md](SOLVE.md) uses discovery-order labels (Rule 1–6) which include a "Rule 4 (XOR algebraic)" not listed here — that rule is provably redundant (see Theorem (XOR universality) below) and is therefore not part of the formal constraint set. Mapping: Rule 1↔C1, Rule 2↔C2, Rule 3↔C3, Rule 4↔(Theorem 2, redundant), Rule 5↔C4, Rule 6↔C5. The formal minimum independent rule set is **{C1, C3, C4, C5}** (C2 is mathematically implied by C5's histogram but kept in the solver as an O(1) boundary pre-filter); C6 and C7 are additional adjacency constraints needed to single out KW within the C1–C5 family.

### C1: Pair structure
For all i ∈ {0, 2, 4, ..., 62}: s_{i+1} = partner(sᵢ).

*The 64 hexagrams form 32 consecutive pairs, each a hexagram and its reverse (or complement for the 8 self-reverse hexagrams — 4 complement-partnered pairs). [Radisic](CITATIONS.md#radisic2026) (2026, arXiv:2601.07175, Lean-verified) proved this pairing is the unique Hamming-cost-minimizing comp/rev matching on {0,1}⁶ — a first-principles optimality characterization; see [CITATIONS.md](CITATIONS.md).*

### C2: No 5-line transitions
For all i ∈ {0, 1, ..., 62}: d(sᵢ, s_{i+1}) ≠ 5.

*No two consecutive hexagrams differ by exactly 5 lines. This is automatic within pairs (Theorem 1: within-pair distance is always even) and constrains only the 31 between-pair boundaries.*

### C3: Complement proximity
cd(S) ≤ 12.125.

*The mean distance between complementary hexagrams in King Wen is 12.125. **Scope-dependent finding:** at the C1+C2 reference scope, this is the **3.9th percentile** of complement distances — KW is in the lowest 4%. At the C1+C2+C3 canonical scope, KW is at the **C3 ceiling = 12.125 exactly**, with about **1 in 10 (~10%)** of orderings tying at this value — a fraction measured over the enumerated set, not a universal constant (~9.91% over the 3.43B-ordering 100T canonical, ~10.11% over the 10.5B-ordering 560T canonical; both correct at their depth; minimum cd in that population is 6.625, i.e., x64 = 424). The threshold 12.125 is King Wen's exact value — extracted from the sequence, not derived independently. The "low-percentile" and "ceiling cohort" framings are both true at their respective scopes; the threshold itself is reverse-engineered, not a structurally significant value.*

### C4: Starting pair
s₀ = 63 (= 111111₂, The Creative) and s₁ = 0 (= 000000₂, The Receptive).

*The sequence begins with the all-yang hexagram followed by the all-yin hexagram. The orientation is forced by C5 (Theorem 6).*

### C5: Difference wave distribution
The multiset of values in D(S) is exactly {1:2, 2:20, 3:13, 4:19, 6:9}.

*The difference wave contains exactly 2 transitions of distance 1, 20 of distance 2, 13 of distance 3, 19 of distance 4, and 9 of distance 6. No transitions of distance 0 or 5.*

### C6: Adjacency constraint at boundary 27
pair(s₅₂) and pair(s₅₄) are adjacent (s₅₂ and s₅₃ form one pair, s₅₄ and s₅₅ form the next).

*Specifically: {s₅₂, s₅₃} = {001011₂, 110100₂} and {s₅₄, s₅₅} = {001101₂, 101100₂}.*

### C7: Adjacency constraint at boundary 25
pair(s₄₈) and pair(s₅₀) are adjacent.

*Specifically: {s₄₈, s₄₉} = {011101₂, 101110₂} and {s₅₀, s₅₁} = {001001₂, 100100₂}.*

## Theorems

**~~Conjecture (Uniqueness)~~ — REFUTED 2026-07-02 (measured).** Constraints C1–C5 plus C6 and C7 do NOT
single out King Wen over the full space: an unbiased Knuth random-probe estimate with the C6/C7 adjacency
constraints enforced in the walk (5×10¹⁰ probes, `SOLVE_KNUTH_C67=1`) measures the number of C1–C7-satisfying
orderings at **5.21×10³¹ (95% CI [5.13, 5.29]×10³¹, relative error 0.78%)**. C6+C7 cut the ≈1.33×10³⁸ C1–C5
space by ×2.55×10⁶ and leave ≈10³¹·⁷ solutions — about 105 further bits of constraint would be required for
full-space uniqueness (≈15–20 boundary constraints, consistent with the extrapolation in
[SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md)). Every "uniquely determines King Wen" statement in the project
is therefore scoped to the enumerated datasets, where 4 greedy-ordered boundary constraints do suffice.

**Evidence (from large-scale enumeration, 10 trillion nodes on 64 cores):**
- C1 reduces the search space from 64! (~10⁸⁹) to 32! × 2³² (~10⁴⁵).
- C2 eliminates ~96% of C1 solutions.
- C3 further restricts to ~3.9% of C1+C2 solutions.
- C4 fixes the starting pair and orientation.
- C5 yields billions of unique pair orderings under partial enumeration. Canonical counts and the sha256 hashes that anchor them are in [CANONICAL_HASHES.md](CANONICAL_HASHES.md); partition-invariant per [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md). The **current deepest partial enumeration is the d3 560T canonical** (10,525,271,997 orderings, sha `9a968fa2…`, 2026-06-08); the d3 100T canonical (3,432,399,297 orderings, `915abf30…`) is the next-deepest and remains the basis for much of the analysis cited in this document. The count difference between partition strategies is a partition-and-budget effect; under true exhaustive enumeration all canonicals would converge. Only Position 1 is universally locked. Positions 3-18 are highly constrained. Positions 19-32 are progressively free. (Older figures — 31.6M filename-collision bug, 742M hash-table bug — were both invalidated by forensic analysis; see [HISTORY.md](HISTORY.md).)
- C6+C7 together eliminate 99.995% of solutions but leave thousands of non-KW survivors. **The number of boundary constraints needed for uniqueness grows with partition depth** (SUPERSEDES earlier "4 always suffice" framing):
  - d2 10T: greedy minimum = **4**, structure `{25, 27} ∪ one-of-{2, 3} ∪ one-of-{21, 22}` (4 working unordered 4-subsets).
  - d3 10T: greedy minimum = **4**, structure `{25, 27} ∪ two-of-{1..6}` (8 working unordered 4-subsets).
  - **d3 100T: greedy minimum = 5** — exhaustive test confirms 0 working unordered 4-subsets; greedy-optimal 5-set is `{1, 4, 21, 25, 27}`.
  - **d3 560T**: greedy minimum stays **5**, set `{4, 27, 25, 21, 1}` applied in greedy order — identical in membership and order to 100T; cumulative non-KW survivor counts 51,404 → 481 → 14 → 1 → 0. Working-4-set count = 0 (vs 8 at 11.2T, 4 at 742M). §[7] proves no 3-tuple works (best `{4, 25, 27}` leaves 15 survivors); §[8] = 0 proves no 4-set works, so 5 is the true minimum. *(Corrected 2026-07-04: the 2026-06-11 entry claimed "drops back to 4" — a survivor-counting error; see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md).)*
  
  **Partition-stable finding**: boundaries **{25, 27}** appear in every greedy minimum at all four partition depths tested (d2 10T, d3 10T, d3 100T, d3 560T). **Not scale-stable**: the working-4-set count (8 → 4 → 0 across 11.2T → 742M → 560T) and the greedy-minimum count (monotone non-decreasing: 4 → 5 → 5 across 10T → 100T → 560T; corrected 2026-07-04). See [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md) + [SOLVE.md](SOLVE.md) for the full per-dataset analysis.
- Earlier claims that C5 locked 23 of 32 positions and C6+C7 alone gave uniqueness were based on a 438-solution partial sample from a single branch of the search tree.

**Theorem (Within-pair distance):** For all h ∈ H, d(h, partner(h)) ∈ {0, 2, 4, 6}. *Proof: see SOLVE.md, Theorem 1.*

**Theorem (XOR universality):** For any partition of H into 32 reverse/complement pairs, the set of XOR products {h ⊕ partner(h)} has exactly 7 elements: {12, 18, 30, 33, 45, 51, 63}. *Proof: see SOLVE.md, Theorem 2.* (cf. [Goldenberg 1975](CITATIONS.md#goldenberg1975), Lemma 3 / Table VI — a set-level precursor.)

**Theorem (Forced orientation):** Given C1, C4, and C5, the orientation of the first pair is forced: s₀ = 63, s₁ = 0. *Proof: see SOLVE.md, Theorem 6.*

**Theorem (Wrap-around parity is odd):** For any sequence satisfying C4 and C5, the wrap-around Hamming distance d(s₆₃, s₀) is odd.

*Proof.* By the XOR parity identity, popcount(a ⊕ b) ≡ popcount(a) + popcount(b) (mod 2) for any 6-bit values a, b. Summing the 63 linear D(S) transitions:

∑ᵢ₌₀⁶² popcount(sᵢ ⊕ sᵢ₊₁) ≡ ∑ᵢ₌₀⁶² (popcount(sᵢ) + popcount(sᵢ₊₁)) ≡ popcount(s₀) + popcount(s₆₃) (mod 2)

(interior terms cancel mod 2). The LHS equals the sum of the C5 multiset values: `1·2 + 2·20 + 3·13 + 4·19 + 6·9 = 211 ≡ 1 (mod 2)`. C4 fixes s₀ = 63, so popcount(s₀) = 6 ≡ 0 (mod 2). Therefore popcount(s₆₃) ≡ 1 (mod 2), i.e., popcount(s₆₃) is odd. Then d(s₆₃, s₀) = hamming(s₆₃, 63) = 6 − popcount(s₆₃) = (even) − (odd) = odd. ∎

*Empirically confirmed at the full d3 560T canonical (10,525,271,997 records, sha `9a968fa2…`, current deepest, CANONICAL-verified 2026-06-30): 100.000000% of records have odd wrap-around — exactly as the theorem requires. (`solve --verify` enforces C4 + C5 on every record, so the parity is a necessary consequence.) This **empirically corroborates** the proof above at canonical scale — it validates the implementation and that every canonical record satisfies the C4+C5 hypotheses; the theorem itself holds **deductively** for every C4+C5 sequence and is established by the proof, not by the enumeration. Which odd value the wrap-around takes (d=1 vs d=3) is budget-dependent; at the 560T canonical `solve --verify-wrap-parity` measures **91.83% d=3 / 8.17% d=1** (9,665,706,017 vs 859,565,980 of 10,525,271,997 records).*

*Note ([McKenna](CITATIONS.md#mckenna-mckenna1975)'s 25/75 observation).* McKenna and McKenna (1975, *The Invisible Landscape*, Chapter 9) state "a perfect ratio of three to one; three even integers to each odd integer," giving the count as "fourteen threes and two ones constitute sixteen instances of an odd integer occurring out of a possible sixty-four" — i.e., the **circular** reading (64 transitions including the wrap-around s₆₃ → s₀). The 16/64 = 25% odd / 75% even split is exact under the circular reading and follows directly from this theorem combined with C5. The 63 linear transitions give 15/63 = 23.81% odd (approximate but not exact). McKenna's empirical observation is mathematically equivalent to this theorem; he discovered it before its proof was articulated here. See CITATIONS.md for the verified source attribution.

*Future option (not currently part of the spec).* If King Wen were treated as a circular sequence and the wrap-around distance were further constrained to its KW-specific value `d(s₆₃, s₀) = 3`, the search space would be measurably reduced (the d=1 minority would be filtered out). That minority fraction grows with node budget — and at the 560T canonical it is now measured at **8.17%** (859,565,980 of 10,525,271,997 records, `solve --verify-wrap-parity`), so constraining the wrap-around to d=3 would filter ~8.2% of canonical orderings at 560T. This is NOT currently in the formal spec because (a) the weak form (odd parity) is already a theorem and adds no constraint, and (b) the strict form (d=3 specifically) would be reverse-engineered from KW similar to C3/C6/C7, and adopting it would invalidate every existing canonical sha by tightening C5. Documented here as an option for future spec evolution.

**Theorem (Parity-class alternation, 2026-07-02):** Every pair is parity-homogeneous (partner preserves
popcount parity), the canonical pairing splits 16 even-class / 16 odd-class, and every C1–C5-valid ordering
has **exactly 15 parity-class alternations** across its 31 pair boundaries (= C5's odd-distance count; the
wrap-parity theorem above is its total-parity corollary). *Proof and consequences (including an exact O(1)
prefix prune and its sha-lineage caveat): [PARITY_ALTERNATION.md](PARITY_ALTERNATION.md).*

**Theorem (Symmetry group, 2026-07-02; completeness 2026-07-18):** The C1–C5 constraint system is invariant under exactly the 48 bit
permutations commuting with bit-reversal (≅ B₃, the octahedral group; effective group S₄ on canonical
records), and this group is **complete over all 64! hexagram relabelings** — no permutation of the
hexagram set outside the 48 preserves the C1–C5 predicate family (C1+C2+C4 alone force membership;
exhaustive machine gate `solve.py --symmetry-completeness`). King Wen has exactly 23 record-level twin
orderings. *Proof: [SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md) (+ §Completeness).*

**Theorem (Trigram-level structure, 2026-07-11):** In every C1-valid ordering the 32 within-pair distances form exactly the multiset {2:12, 4:12, 6:8}; in every C1+C5-valid ordering the 31 between-pair boundary distances form exactly the multiset **{1:2, 2:8, 3:13, 4:7, 6:1}**. Corollaries holding for every valid ordering: exactly one boundary complements both trigrams simultaneously (the "9th six" — *observed* in King Wen by [McKenna & McKenna 1975](CITATIONS.md#mckenna-mckenna1975), here derived from C1+C5 so the 560T-scale measurement becomes a corollary; its *position* remains ordering-dependent); exactly two boundaries change a single line; and at the unique distance-6 boundary the following pair is the complement (pangtong) image of the preceding pair in reversed order. Separately, exactly **12 of the 48** constraint symmetries (Theorem above) respect the trigram bipartition, forming a subgroup ≅ S₃ × C₂ (S₃, order 6, at record level) — a statement about this project's constraint-symmetry group only, distinct from Hershock 1991's trigram-operation group on the hexagram set. *Machine-checked in core Lean 4: [lean/TrigramTheorems.lean](../lean/TrigramTheorems.lean); prose companion, honest scope, and the binding attribution/novelty ledger: [TRIGRAM_STRUCTURE.md](TRIGRAM_STRUCTURE.md).*

**Theorem (Partition invariance):** Under exhaustive enumeration of the depth-2 partition of the search space, the final `solutions.bin` is byte-identical regardless of whether the 56 first-level branches are enumerated concurrently in a single invocation or individually across multiple invocations followed by a single merge. More generally, merging any subset of independently-computed exhaustive-enumeration shards produces the same `solutions.bin` bytes as a single-invocation enumeration of the same subset. *Proof: see [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md). The mathematical core (invariance of the sort-merge-dedup pipeline under input order, partition choice, invocation grouping, and merge hierarchy) is machine-checked at the model level in core Lean 4 — [lean/PartitionInvariance.lean](../lean/PartitionInvariance.lean) (2026-07-11); the bridge facts connecting the model to `solve.c` are explicit, cited assumptions and are NOT machine-checked — see PARTITION_INVARIANCE.md §2a for the exact scope.*

**Result (Minimum adjacencies, canonical 2026-04-18; updated 2026-06-11; corrected 2026-07-04):** The minimum number of boundary constraints needed to uniquely determine King Wen is **monotone non-decreasing with scale**. At d2 10T and d3 10T the greedy minimum is **4 boundaries**; at d3 100T it grew to **5**; at d3 560T it **stays 5 with the identical set** `{4, 27, 25, 21, 1}` applied in cumulative greedy order — boundary 4 alone eliminates 99.999% of non-KW, and the 5th boundary exists solely for one impostor (rec#330177707, KW with the position-2/3 pair blocks swapped). §[7] proves no 3-tuple works at any scale tested; §[8] = 0 proves no 4-set works at canonical depth. *(An earlier version of this result claimed the minimum "drops back to 4" at 560T — a survivor-counting error; see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md).)* **Partition-stable**: boundaries `{25, 27}` appear in every greedy minimum at every partition tested. **Not stable**: the other boundaries in the minimum AND the working-4-set count (8 at d3 10T; 0 at d3 100T and d3 560T). At d2 10T the 4 working 4-sets are `{2,21,25,27}`, `{2,22,25,27}`, `{3,21,25,27}`, `{3,22,25,27}` — structure `{25, 27} ∪ one-of-{2, 3} ∪ one-of-{21, 22}`. At d3 10T there are 8 working 4-subsets with boundaries from `{1..6}` combined with `{25, 27}`. *See [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md) + SOLVE.md for the full per-dataset analysis.*

## Constructive algorithm

```
function construct_king_wen():
    pairs = canonical_reverse_inverse_pairs(H)    # 32 pairs (C1)
    S = [63, 0]                                    # start with Creative/Receptive (C4)
    budget = {1:2, 2:20, 3:13, 4:19, 6:9}         # difference distribution (C5)
    budget[6] -= 1                                 # within-pair transition consumed
    
    for step in 2..32:
        for each unused pair p, orientation o:
            candidate = S + [p[o], p[1-o]]
            if boundary_distance ∈ budget              # C5: budget check
               and boundary_distance ≠ 5               # C2: no-5 check
               and complement_distance(candidate) is feasible for ≤ 12.125  # C3
               and (step ≠ 26 or adjacency_27_satisfied)  # C6
               and (step ≠ 25 or adjacency_25_satisfied):  # C7
                place pair, update budget
    
    return S
```

*With all constraints active, this algorithm produces exactly one complete sequence in the enumerated datasets to date; full-space uniqueness of C1–C7 is the [Conjecture (Uniqueness)](#theorems) above. However, individual steps may have multiple locally valid choices — uniqueness is a global property requiring lookahead or backtracking, not a greedy local property. Run `python3 solve.py --reconstruct` to verify.*

## Notation summary

| Symbol | Meaning |
|--------|---------|
| **H** | {0, 1, ..., 63}, the 64 hexagrams as 6-bit integers |
| **S** | The King Wen sequence, a permutation of **H** |
| sᵢ | The hexagram at position i in **S** |
| d(a,b) | Hamming distance between hexagrams a and b |
| rev(n) | Bit reversal of n |
| comp(n) | Bitwise complement of n (n ⊕ 63) |
| D(S) | The difference wave of **S** |
| cd(S) | Mean complement distance of **S** |
| ⊕ | Bitwise XOR |

## Methodological limitations

- **Confirmatory, not predictive.** Constraints C1-C5 were extracted from King Wen and then shown to be highly constraining. They were not derived independently. A stronger result would predict the constraints from first principles.
- **Position locking revised.** The earlier claim that positions 1-23 are locked has been disproven by large-scale enumeration. Only Position 1 is universally locked. Positions 3-18 admit 2 pairs each. Positions 19-32 are progressively free.
- **Circular threshold.** C3's threshold of 12.125 is King Wen's exact complement distance. The constraint is defined by the answer. The qualitative finding is **scope-dependent**: at the C1+C2 reference scope, KW's cd is at the 3.9th percentile (lowest 4%) — robust. At the C1+C2+C3 canonical scope, KW is at the C3 ceiling (about 1 in 10 tie at 12.125 — ~9.91% at the 100T canonical, ~10.11% at the deeper 560T; minimum 6.625) — also robust but qualitatively different. Neither claim derives 12.125 from first principles; the threshold itself is reverse-engineered. See [SOLVE.md §Rule 3 Note on the threshold](SOLVE.md) for the publication-defensibility breakdown.
- **Greedy minimum constraints.** C6 and C7 were found by greedy search, which doesn't guarantee the globally minimal constraint set. A different pair of adjacency constraints might also suffice.
- **Partial enumeration (historical figure).** The 742,043,303 unique-pair-orderings count is a **superseded 2026-04 hash-table-bug-era figure** (sha256 of solutions.bin: `aa1415174c914f8ee06821e51f599b196321c69a8c736f26936694d81a56719b`) and does not appear in any current canonical artifact. The current deepest canonical is the d3 560T enumeration (10,525,271,997 records); see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) for current record counts and shas across partition strategies and node budgets. The search was partial (every sub-branch hit its node budget), so the true count is higher. (The earlier 31.6M figure from sha256 `c43f251f...d2f2104d` was a ~23x undercount caused by a sub-branch filename collision bug — see [HISTORY.md](HISTORY.md).)
- **Null model caveat.** Applying the same methodology to random pair-constrained sequences (extract diff distribution, complement distance, starting pair, and test for uniqueness) also produces apparent uniqueness in 9/10 cases. The constraint extraction approach inflates apparent specialness. However, King Wen's C2 (no 5-line transitions) is genuinely rare (~4.3% of pair-constrained orderings; with the start pair additionally pinned the fraction is exact: 1/23.325… = 4.2872%, a ratio of exact counts — TR-9 v1.10), while most random sequences have no comparably rare transition constraint. The genuine findings are C1+C2 (pair structure + no-5) and C3 (complement proximity), not the full C1-C7 framework.

For the complete analysis behind this specification, see [SOLVE.md](SOLVE.md) and [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md). For a step-by-step recipe to re-implement an independent verifier from this document plus [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) alone, see [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md).

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*
