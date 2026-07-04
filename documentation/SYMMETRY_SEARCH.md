# The Symmetry Group of the C1–C5 Constraint System is the Octahedral Group (order 48)

**Result (CORRECTED 2026-07-02, supersedes this document's earlier negative claim):** The C1–C5 constraint
system admits an exact symmetry group: the **48 bit-position permutations that commute with bit-reversal**
(the centralizer of `rev` in S₆, isomorphic to **B₃ ≅ Z₂ ≀ S₃**, the octahedral group). For every σ in this
group and every sequence S, **S satisfies C1–C5 if and only if σ(S) does** — proven, not sampled. The full
solution set is therefore a disjoint union of orbits of size dividing 48; per-cell true solution counts and
entire backtrack subtrees are exactly orbit-invariant. At the canonical-record level (pair-sequences after
orientation dedup), bit-reversal itself acts trivially, so the effective group is **B₃/{±I} ≅ S₄ (order 24)**
— and **King Wen has exactly 23 nontrivial record-level "twins"**: distinct canonical orderings that are bit
relabelings of KW, all with complement distance 776 exactly.

> **Correction notice.** The original version of this document (2026-04-25, "reaffirmed" 2026-06-11) concluded
> the opposite: *"All 47 falsified… the constraint set is rigid against bit-position permutations. No
> factor-of-2-to-48 enumeration cost reduction is available."* That conclusion was **wrong**. The empirical
> data behind it (budget-truncated per-cell yields differ across σ-related cells) was and remains correct —
> but it measured **budget/dedup artifacts, not solution-set asymmetry** (mechanism below). The lesson is
> recorded in CRITIQUE.md; the original data is preserved in §"What the 2026-04-25 test actually measured."

## Theorem and proof

*Novelty status: we are not aware of a prior statement of this symmetry group for the King Wen constraint
system; prior-art corrections are welcomed via [CITATIONS.md](CITATIONS.md).*

**Theorem.** Let G = C_{S₆}(rev) act on hexagrams by permuting bit positions (linearly on GF(2)⁶). For every
σ ∈ G: S satisfies C1–C5 ⟺ σ(S) satisfies C1–C5. Moreover G is maximal with this property inside the full
hyperoctahedral group Aut(Q₆) = S₆ ⋉ (Z₂)⁶ (order 46,080).

**Proof.** σ ∈ G is a Hamming isometry, so every adjacent distance d(sᵢ, sᵢ₊₁) is preserved — **C2, C5** ✓
(the difference-wave multiset is unchanged). Coordinate permutations fix 0 = 000000₂ and 63 = 111111₂ —
**C4** ✓. σ is linear with σ(63) = 63, so σ(h ⊕ 63) = σ(h) ⊕ 63: complement pairs map to complement pairs at
unchanged positions, preserving the complement-distance multiset, hence the sum — **C3** ✓. For **C1**:
σ ∘ rev = rev ∘ σ (definition of G) gives σ(partner(h)) = partner(σ(h)) — in the reverse case directly, and
in the symmetric-complement case because σ preserves the palindrome set and commutes with comp — so
consecutive pairs map to consecutive pairs ✓. Since σ⁻¹ ∈ G, the equivalence is two-way. ∎

**Maximality.** Any element of Aut(Q₆) with a nontrivial flip component moves 0 or 63 and violates C4. For the
672 bit permutations outside G, a single witness suffices: applying each to King Wen (a known solution)
produces a sequence that **violates C1** in all 672 cases (exhaustively verified 2026-07-02) — so none
preserves the solution set. Exactly the 48 elements of G map KW to valid C1–C5 sequences. ∎

**Group structure.** rev = (0 5)(1 4)(2 3) splits the six bit positions into three pairs; its centralizer
permutes the three pairs (S₃) and swaps within each independently ((Z₂)³): G ≅ Z₂ ≀ S₃ ≅ B₃, order 48,
element orders {1:1, 2:19, 3:8, 4:12, 6:8}. rev itself is the central element −I; it maps every hexagram to
its partner and therefore fixes every pair-sequence — giving the record-level group B₃/{±I} ≅ S₄.

## Empirical corroboration (three independent levels)

1. **Exhaustive σ(KW) test over all 720 bit permutations:** exactly the 48 σ ∈ G yield valid C1–C5 sequences
   (the other 672 fail C1); the 48 raw sequences are distinct; they collapse to **24 distinct canonical
   pair-orderings** (KW + 23 twins), each with C3 = 776.
2. **Exact tree isomorphism:** for a KW-following 23-pair prefix (9 free positions) and three random σ ∈ G,
   the exact deterministic subtree counts (`solve --estimate-knuth 0 <prefix>`) are **identical to the
   integer**: tree_nodes = 9,422,793 and canonical leaves = 16,504 for all four σ-related prefixes. σ maps
   entire backtrack subtrees isomorphically.
3. **All-cells orbit test:** the 65,281 productive 560T cells partition into 4,183 G-orbits; the within-orbit
   coefficient of variation of the per-cell Knuth size estimates (10⁵ probes/cell) is **0.112 (median)** —
   indistinguishable from the estimator's own noise floor (median relerr 0.130) and 6× below the population
   CV (0.72). True per-cell counts are orbit-equal within measurement resolution across the entire space.

## What the 2026-04-25 test actually measured

The original test compared **per-cell yields from the budget-truncated 100T enumeration log** between cells
and their σ-images, found large mismatches (max >1.5M records; ≥21,000 mismatched cell pairs per σ), and
concluded no symmetry exists. Both mechanisms behind those mismatches are now understood, and neither
concerns the solution set:

- **Frontier ordering.** σ permutes hexagram values and hence DFS child order. A fixed per-cell node budget
  therefore explores a *different region* of the (isomorphic) tree in cell C vs σ(C) — equal totals, different
  budgeted slices. (This also explains why orbit-mates of productive cells are often unproductive at a given
  budget, and connects to the finding that budgeted yield is uncorrelated with total cell size.)
- **Dedup convention.** The canonical lex-smallest-orientation representative is not σ-equivariant, so records
  migrate between orbit-mate cells under relabeling.

Diagnostic confirmation: the old test's closest "near-miss" was σ = [5,4,3,2,1,0] (bit reversal, 43% match) —
precisely the central element that acts *trivially* on pair-sequences, leaving only the artifacts above.

The corrected takeaways replace the old implications: (1) an **orbit-reduction of enumeration cost (÷ up to
48 raw / 24 effective)** is available in principle — adopting it for canonical runs would change the canonical
convention and is a separate, gated decision; (2) KW-structural claims should be checked for relabeling
invariance — any statistic not invariant under S₄ record-relabeling is measuring the labeling; (3) the
solution space's orbit structure (and KW's 23 twins) is a new object of study in its own right.

## Reproducibility

```bash
# exact tree-isomorphism check (any sigma in G; prefix = 22 (pair,orient) args after the forced first pair):
./solve --estimate-knuth 0 1 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 20 0 21 0 22 0
./solve --estimate-knuth 0 22 1 28 0 3 1 21 1 26 0 6 1 11 0 5 0 19 0 27 0 7 1 16 1 30 1 14 0 20 0 18 1 25 0 24 1 1 1 15 0 4 0 9 0
# -> identical tree_nodes = 9,422,793 and leaves_canonical = 16,504
```

σ(KW) validity over all 720 bit permutations + the orbit collapse (<1 s, pure python, run from the
repo root — verified output: `48 of 720 valid -> 24 distinct canonical records (KW + 23 twins)`):

```python
from itertools import permutations
import solve
KW = solve.binary_hexagrams
kw_trans = sorted(solve.bit_diff(KW[i], KW[i+1]) for i in range(63))       # C5 multiset
def apply_sigma(p, h): return sum(((h >> b) & 1) << i for i, b in enumerate(p))
def valid(s):                                                              # C1..C5
    return (solve.has_pair_structure_c1(s) and (s[0], s[1]) == (63, 0)
            and solve.count_five_line_transitions_c2(s) == 0
            and solve.total_complement_distance_c3(s) <= 776
            and sorted(solve.bit_diff(s[i], s[i+1]) for i in range(63)) == kw_trans)
good = [s for s in ([apply_sigma(p, h) for h in KW] for p in permutations(range(6))) if valid(s)]
recs = {tuple(frozenset(s[2*k:2*k+2]) for k in range(32)) for s in good}   # orientation-dedup
print(len(good), "of 720 valid ->", len(recs), "distinct canonical records (KW + 23 twins)")
```

All-cells orbit test (within-orbit CV 0.112): the per-cell estimates are `./solve --estimate-knuth
100000 <p1> <o1> <p2> <o2> <p3> <o3>` over the 65,281 productive 560T cells (cell list from the 560T
shard manifest, reproducible per CANONICAL_HASHES.md); the G-orbit partition (4,183 orbits) is the
σ-action on (pair, orient) prefixes from the snippet above. The per-cell estimate table itself is
private working data (~65K estimator calls, hours-scale); this rerun spec is the public path.

Original 2026-04-25 phases 1–3 (`./solve --symmetry-search [--validate-counts]`) remain reproducible; their
output is correct as *budgeted-yield* data. Proof + full working notes: `roae-private/THEOREM_C15_SYMMETRY_GROUP_2026_07.md`.

## Corollary (2026-07-03): the action is free — every solution has exactly 23 twins

The S₄ record-action has no fixed points off the identity. *Proof:* every canonical record uses all 32
pairs of the fixed C1 pairing, position-wise; a record equals its σ-image only if σ stabilizes each pair
as a set at its slot; an effective σ ≠ id moves at least one pair (otherwise its record-action is trivial,
putting it in the kernel {id, ρ}); every record contains that pair. ∎

Consequences: **every orbit has size exactly 24** (the action is free), the orbit count is exactly N/24,
and King Wen's 23 twins are not a special property — every valid ordering has exactly 23. The Burnside
census that this project had queued as a measurement (fixed-point counts per conjugacy class) is thereby
settled analytically: all non-identity counts are zero. (To our knowledge first stated here; corrections
welcome via [CITATIONS.md](CITATIONS.md).)

## Limits and scope

- The theorem covers the full hyperoctahedral group: flips are excluded **by C4 specifically** (they move
  0/63). A constraint system without C4 would admit a larger flip-extended analysis — not pursued.
- Whether KW's 23 twins appear in budgeted canonicals is now MEASURED (2026-07-02, direct bisection of the
  560T canonical): **King Wen is present; all 23 twins are absent.** Their membership in the full solution
  set is proven — their absence from the budgeted set is a search-orientation effect: the enumeration's
  variable order is derived from King Wen, so KW lies on the early DFS path of its cell while each
  relabeled twin is a late leaf of its own cell. Presence in a budgeted canonical therefore reflects the
  search's frame of reference, not a mathematical property of the ordering — the strongest concrete
  illustration yet of the caveat in [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md) §"Is finding King Wen
  early an artifact?".
- The orbit-reduction design (enumerate representatives, relabel + re-canonicalize) is specified but not
  implemented; canonical-sha implications make production adoption an explicitly gated decision.
