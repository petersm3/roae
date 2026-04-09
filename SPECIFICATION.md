# Formal Specification of the King Wen Sequence

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is the unique permutation **S** = (s₀, s₁, ..., s₆₃) of the set **H** = {0, 1, ..., 63} satisfying the following constraints.

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
cd(S) = (1/|C|) × Σ |pos(h) - pos(comp(h))|
```
where C = {h ∈ H : comp(h) ≠ h} (the 60 non-self-complementary hexagrams, counted once per pair).

## Constraints

**S** is the unique permutation of **H** satisfying the following constraints. Note: C1 and C2 are structural properties observable in the sequence. C3, C4, and C5 were extracted from King Wen and used to constrain the search — they are confirmatory (consistent with King Wen) rather than predictive (derived independently). C6 and C7 are specific adjacency choices that no aggregate mathematical property can replace.

### C1: Pair structure
For all i ∈ {0, 2, 4, ..., 62}: s_{i+1} = partner(sᵢ).

*The 64 hexagrams form 32 consecutive pairs, each a hexagram and its reverse (or complement for the 4 symmetric hexagrams).*

### C2: No 5-line transitions
For all i ∈ {0, 1, ..., 62}: d(sᵢ, s_{i+1}) ≠ 5.

*No two consecutive hexagrams differ by exactly 5 lines. This is automatic within pairs (Theorem 1: within-pair distance is always even) and constrains only the 31 between-pair boundaries.*

### C3: Complement proximity
cd(S) ≤ 12.125.

*The mean distance between complementary hexagrams is unusually small (3.9th percentile among all C1+C2 solutions). Note: the threshold 12.125 is King Wen's exact value — it was extracted from the sequence, not derived independently. A different threshold would change the solution count but the qualitative finding (King Wen has unusually low complement distance) is robust.*

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

**Conjecture (Uniqueness):** Constraints C1–C7 have exactly one solution: the King Wen sequence.

**Evidence (not yet a complete proof):**
- C1 reduces the search space from 64! (~10⁸⁹) to 32! × 2³² (~10⁴⁵).
- C2 eliminates ~96% of C1 solutions.
- C3 further restricts to ~3.9% of C1+C2 solutions.
- C4 fixes the starting pair and orientation.
- C5 empirically locks 23 of 32 pair positions via constraint propagation, leaving 9 free positions with thousands of valid orderings. (Established by partial enumeration, not formal proof.)
- C6 eliminates all but 5 of the remaining orderings.
- C7 eliminates the final 5, leaving exactly 1: King Wen.

**Theorem (Within-pair distance):** For all h ∈ H, d(h, partner(h)) ∈ {0, 2, 4, 6}. *Proof: see SOLVE.md, Theorem 1.*

**Theorem (XOR universality):** For any partition of H into 32 reverse/complement pairs, the set of XOR products {h ⊕ partner(h)} has exactly 7 elements: {12, 18, 30, 33, 45, 51, 63}. *Proof: see SOLVE.md, Theorem 2.*

**Theorem (Forced orientation):** Given C1, C4, and C5, the orientation of the first pair is forced: s₀ = 63, s₁ = 0. *Proof: see SOLVE.md, Theorem 6.*

**Theorem (Minimum adjacencies):** No fewer than 2 adjacency constraints (C6, C7) suffice to make C1–C7 have a unique solution. No single adjacency constraint eliminates all non-King-Wen solutions. *Proof: see SOLVE.md, Theorem 3.*

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

*With all constraints active, this algorithm produces exactly one complete sequence. However, individual steps may have multiple locally valid choices — uniqueness is a global property requiring lookahead or backtracking, not a greedy local property. Run `python3 solve.py --reconstruct` to verify.*

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
- **Empirical, not proven.** The claim that positions 1-23 are locked rests on partial enumeration (no counterexample found in billions of nodes), not formal proof. A complete enumeration or mathematical proof could strengthen or weaken this claim.
- **Circular threshold.** C3's threshold of 12.125 is King Wen's exact complement distance. The constraint is defined by the answer. The qualitative finding (King Wen has unusually low complement distance) is robust, but the specific threshold is reverse-engineered.
- **Greedy minimum constraints.** C6 and C7 were found by greedy search, which doesn't guarantee the globally minimal constraint set. A different pair of adjacency constraints might also suffice.
- **Pending complete enumeration.** The exact number of solutions satisfying C1-C5 is bounded (13,296 ≤ N ≤ 860,160) but not yet known. A 24-hour enumeration is in progress.
- **Null model caveat.** Applying the same methodology to random pair-constrained sequences (extract diff distribution, complement distance, starting pair, and test for uniqueness) also produces apparent uniqueness in 9/10 cases. The constraint extraction approach inflates apparent specialness. However, King Wen's C2 (no 5-line transitions) is genuinely rare (~4.3% of pair-constrained orderings), while most random sequences have no comparably rare transition constraint. The genuine findings are C1+C2 (pair structure + no-5) and C3 (complement proximity), not the full C1-C7 framework.

For the complete analysis behind this specification, see [SOLVE.md](SOLVE.md) and [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md).
