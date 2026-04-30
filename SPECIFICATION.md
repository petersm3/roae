# Formal Specification of the King Wen Sequence

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is the unique permutation **S** = (s₀, s₁, ..., s₆₃) of the set **H** = {0, 1, ..., 63} satisfying the following constraints.

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

**S** is the unique permutation of **H** satisfying the following constraints. Note: C1 and C2 are structural properties observable in the sequence. C3, C4, and C5 were extracted from King Wen and used to constrain the search — they are confirmatory (consistent with King Wen) rather than predictive (derived independently). C6 and C7 are specific adjacency choices that no aggregate mathematical property can replace.

**Numbering note.** The narrative document [SOLVE.md](SOLVE.md) uses discovery-order labels (Rule 1–6) which include a "Rule 4 (XOR algebraic)" not listed here — that rule is provably redundant (see Theorem (XOR universality) below) and is therefore not part of the formal constraint set. Mapping: Rule 1↔C1, Rule 2↔C2, Rule 3↔C3, Rule 4↔(Theorem 2, redundant), Rule 5↔C4, Rule 6↔C5. The formal minimum independent rule set is **{C1, C3, C4, C5}** (C2 is mathematically implied by C5's histogram but kept in the solver as an O(1) boundary pre-filter); C6 and C7 are additional adjacency constraints needed to single out KW within the C1–C5 family.

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

**Conjecture (Uniqueness):** Constraints C1-C5 plus C6 and C7 significantly narrow the solution space, but their sufficiency for uniqueness is unconfirmed at scale.

**Evidence (from large-scale enumeration, 10 trillion nodes on 64 cores):**
- C1 reduces the search space from 64! (~10⁸⁹) to 32! × 2³² (~10⁴⁵).
- C2 eliminates ~96% of C1 solutions.
- C3 further restricts to ~3.9% of C1+C2 solutions.
- C4 fixes the starting pair and orientation.
- C5 yields billions of unique pair orderings under partial enumeration. Canonical counts (sha-validated, partition-invariant per [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)):
  - **d3 100T partition: 3,432,399,297** canonical orderings (sha `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5`, 2026-04-20). Current deepest partial enumeration.
  - **d3 10T partition: 706,422,987** canonical orderings (sha `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e`).
  - **d2 10T partition: 286,357,503** canonical orderings (sha `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2`).
  
  The count difference is a partition-strategy and node-budget effect; under true exhaustive enumeration all three would converge. Only Position 1 is universally locked. Positions 3-18 are highly constrained. Positions 19-32 are progressively free. (Older figures — 31.6M filename-collision bug, 742M hash-table bug — were both invalidated by forensic analysis; see [HISTORY.md](HISTORY.md).)
- C6+C7 together eliminate 99.995% of solutions but leave thousands of non-KW survivors. **The number of boundary constraints needed for uniqueness grows with partition depth** (SUPERSEDES earlier "4 always suffice" framing):
  - d2 10T: minimum is **4**, structure `{25, 27} ∪ one-of-{2, 3} ∪ one-of-{21, 22}` (4 working 4-subsets).
  - d3 10T: minimum is **4**, structure `{25, 27} ∪ two-of-{1..6}` (8 working 4-subsets).
  - **d3 100T: minimum is 5** — exhaustive test confirms 0 working 4-subsets; greedy-optimal 5-set is `{1, 4, 21, 25, 27}`.
  
  **Partition-stable finding**: boundaries **{25, 27}** appear in every working minimum set at all three partition depths. **Partition-dependent**: the remaining boundaries AND the minimum count itself. Only `{25, 27}` can be cited as generally mandatory; "4 boundaries minimum" is true only at 10T scales, not 100T. The minimum may continue to grow at 1000T+. See [SOLVE.md](SOLVE.md) for the full per-dataset analysis.
- Earlier claims that C5 locked 23 of 32 positions and C6+C7 alone gave uniqueness were based on a 438-solution partial sample from a single branch of the search tree.

**Theorem (Within-pair distance):** For all h ∈ H, d(h, partner(h)) ∈ {0, 2, 4, 6}. *Proof: see SOLVE.md, Theorem 1.*

**Theorem (XOR universality):** For any partition of H into 32 reverse/complement pairs, the set of XOR products {h ⊕ partner(h)} has exactly 7 elements: {12, 18, 30, 33, 45, 51, 63}. *Proof: see SOLVE.md, Theorem 2.*

**Theorem (Forced orientation):** Given C1, C4, and C5, the orientation of the first pair is forced: s₀ = 63, s₁ = 0. *Proof: see SOLVE.md, Theorem 6.*

**Theorem (Partition invariance):** Under exhaustive enumeration of the depth-2 partition of the search space, the final `solutions.bin` is byte-identical regardless of whether the 56 first-level branches are enumerated concurrently in a single invocation or individually across multiple invocations followed by a single merge. More generally, merging any subset of independently-computed exhaustive-enumeration shards produces the same `solutions.bin` bytes as a single-invocation enumeration of the same subset. *Proof: see [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md).*

**Result (Minimum adjacencies, canonical 2026-04-18):** Exactly 4 boundary constraints are needed to uniquely determine King Wen at both the d2 (286M orderings) and d3 (706M orderings) 10T canonical datasets — all 4,495 three-subsets fail at both scales. **Partition-stable**: boundaries `{25, 27}` appear in every working 4-subset at both scales. **Not partition-stable**: the other 2 boundaries. At d2, the 4 working 4-subsets are `{2,21,25,27}`, `{2,22,25,27}`, `{3,21,25,27}`, `{3,22,25,27}` — structure `{25, 27} ∪ one-of-{2, 3} ∪ one-of-{21, 22}`. At d3, there are **8 working 4-subsets** with interchangeable boundaries drawn from `{1..6}` (specifically: {1,3}, {1,4}, {2,3}, {2,4}, {2,5}, {3,4}, {3,5}, {3,6} each combined with `{25, 27}`). The general claim is `{25, 27} mandatory + 2 additional partition-specific boundaries`. Deeper enumeration could in principle require a 5th boundary or further change the interchangeable slot structure. *See SOLVE.md for the full analysis.*

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
- **Position locking revised.** The earlier claim that positions 1-23 are locked has been disproven by large-scale enumeration. Only Position 1 is universally locked. Positions 3-18 admit 2 pairs each. Positions 19-32 are progressively free.
- **Circular threshold.** C3's threshold of 12.125 is King Wen's exact complement distance. The constraint is defined by the answer. The qualitative finding (King Wen has unusually low complement distance) is robust, but the specific threshold is reverse-engineered.
- **Greedy minimum constraints.** C6 and C7 were found by greedy search, which doesn't guarantee the globally minimal constraint set. A different pair of adjacency constraints might also suffice.
- **Partial enumeration.** A 10-trillion-node enumeration on 64 cores (`solve.c`) found at least 742,043,303 unique pair orderings satisfying C1-C5. The search was partial (every sub-branch hit its node budget), so the true count is higher. sha256 of solutions.bin: `aa1415174c914f8ee06821e51f599b196321c69a8c736f26936694d81a56719b`. Reproducible with `SOLVE_NODE_LIMIT=10000000000000` on the bug-fixed solver. (The earlier 31.6M figure from sha256 `c43f251f...d2f2104d` was a ~23x undercount caused by a sub-branch filename collision bug — see [HISTORY.md](HISTORY.md).)
- **Null model caveat.** Applying the same methodology to random pair-constrained sequences (extract diff distribution, complement distance, starting pair, and test for uniqueness) also produces apparent uniqueness in 9/10 cases. The constraint extraction approach inflates apparent specialness. However, King Wen's C2 (no 5-line transitions) is genuinely rare (~4.3% of pair-constrained orderings), while most random sequences have no comparably rare transition constraint. The genuine findings are C1+C2 (pair structure + no-5) and C3 (complement proximity), not the full C1-C7 framework.

For the complete analysis behind this specification, see [SOLVE.md](SOLVE.md) and [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md). For a step-by-step recipe to re-implement an independent verifier from this document plus [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) alone, see [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md).
