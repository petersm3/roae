# The Symmetry Group of the C1–C5 Constraint System is the Octahedral Group (order 48)

**Result (CORRECTED 2026-07-02; machine-checked in Lean 2026-07-05, supersedes this document's earlier negative claim):** The C1–C5 constraint
system admits an exact symmetry group: the **48 bit-position permutations that commute with bit-reversal**
(the centralizer of `rev` in S₆, isomorphic to **B₃ ≅ Z₂ ≀ S₃**, the octahedral group). For every σ in this
group and every sequence S, **S satisfies C1–C5 if and only if σ(S) does** — proven, not sampled.
**Completeness (2026-07-18): the group is complete over ALL 64! hexagram relabelings** — no
permutation of the hexagram set outside these 48 preserves the C1–C5 predicate family (C1+C2+C4
already force membership; §Completeness below, machine-verified by
`solve.py --symmetry-completeness`). The full
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
> recorded in [CRITIQUE.md](CRITIQUE.md); the original data is preserved in §"What the 2026-04-25 test actually measured."

> Related work: see the [Goldenberg 1975](CITATIONS.md#goldenberg1975) note at the end of this document — the earliest algebraic (GF(2)) formalization of the hexagram set we know of; scoped as set-level, not ordering-level, prior art.

## Theorem and proof

*Novelty status (hedge aligned with CITATIONS 2026-08-06): we are not aware of a prior statement of this
symmetry group for the King Wen constraint system **on orderings**. The ambient hexagram-level algebra it
acts through is prior art and is not claimed: the (Z/2)⁶/XOR framing and hexagram-level group actions
has, on [CITATIONS.md](CITATIONS.md)'s current accounting, **six independent pre-ROAE arrivals**:
[Goldenberg (1975)](CITATIONS.md#goldenberg1975), [Ouyang (1992)](CITATIONS.md#ouyang1992) (the earliest
and fullest, with proofs and subgroup×coset partitions of historical sequences; his
[1990](CITATIONS.md#ouyang1990) already states the group),
[Yuan Zuoxing 袁作兴 (1991)](CITATIONS.md#yuanzuoxing1991),
[Cao Hongjun, Li Shuzhong and Liu Yanan (1995)](CITATIONS.md#caohongjun1995),
[Suenaga (2012)](CITATIONS.md#suenaga2012) and [Radisic (2026)](CITATIONS.md#radisic2026), with
[Schöter (1998)](CITATIONS.md#schoter1998) a further **independent-then-crediting** arrival (he credits
Goldenberg's ⊕ and ⊗ as the direct parallels of his own bit-wise operators and reports that the bulk of
his work predated his awareness of Goldenberg) — and the
classical lineage is older still: [Wu Cheng 吳澄 (c. 1300)](CITATIONS.md#wucheng) gives the **complete
⟨complement, reversal⟩ orbit decomposition of all 64** (「二十對」 = 12×4 + 8×2), with
[Lai Zhide (c. 1600)](CITATIONS.md#laizhide) tabulating both operations across all 64 without composing
them, and [Jiao Xun (c. 1813)](CITATIONS.md#jiaoxun) and [Cui Shu (c. 1800)](CITATIONS.md#cuishu)
reaching parts independently. All of these act on the **hexagram set**; none states a group acting on the
space of admissible orderings, which is this document's object ([CITATIONS.md](CITATIONS.md) §"The (Z/2)⁶ hexagram algebra … — priority ceded").
Prior-art corrections are welcomed via [CITATIONS.md](CITATIONS.md).*

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

**The complement Z₂ — the one flip C4 alone excludes (2026-07-26).** The all-flip element
comp : x ↦ x ⊕ 63 deserves its own note, because only C4's *orientation* stops it: **comp is an
exact symmetry of C1∩C2∩C3∩C5**, machine-checked in [lean/KingWen.lean](../lean/KingWen.lean)
(`comp_symmetry_c1_c2_c3_c5`; kernel-only trust base, no native_decide) — it preserves C1 (partner
commutes with comp), C2/C5 (Hamming isometry), and C3 exactly, and it is an involution. It moves
63 → 0, so it breaks the *oriented* C4 (comp∘KW opens (0, 63)) — which is why it is rightly outside
the C1–C5 group above. Under the **pair-only reading of C4** ({s₀, s₁} = {0, 63}, orientation free)
the preserver group inside Aut(Q₆) doubles to **⟨comp⟩ × G (order 96)**: the flip component must fix
the set {0, 63} (only flips 0 and 63 do), comp commutes with every σ ∈ G (σ is linear with
σ(63) = 63), and the 672 non-centralizer permutations stay excluded by the C1 witness check above
(comp preserves C1, so composing with comp cannot rescue them). This is also the corrected home of
the retracted "Theorem 6": the opening orientation is a free Z₂ of the pair-only system — fixed in
C4 by definition (our convention — the *Xugua* attests that the {Heaven, Earth} pair opens, not the
order within it; narrowed 2026-09-01, [SPECIFICATION.md](SPECIFICATION.md) §Constraints), not forced
by the mathematics (see CLAIMS_DECIDED's corrections ledger, 2026-07-26).

**Group structure.** rev = (0 5)(1 4)(2 3) splits the six bit positions into three pairs; its centralizer
permutes the three pairs (S₃) and swaps within each independently ((Z₂)³): G ≅ Z₂ ≀ S₃ ≅ B₃, order 48,
element orders {1:1, 2:19, 3:8, 4:12, 6:8}. rev itself is the central element −I; it maps each hexagram to
its **reversal**, which is that hexagram's C1 partner for the 56 non-palindromes and which fixes the 8
palindromes {0, 12, 18, 30, 33, 45, 51, 63} (whose C1 partners are their complements, `partner(h) = h ⊕ 63`).
Either way rev fixes each of the 32 C1 pairs setwise, and therefore fixes every pair-sequence — giving the
record-level group B₃/{±I} ≅ S₄. *(Corrected 2026-09-02, prose batch P33, `RP-60226f4a`: this sentence
previously gave the reason as rev sending each hexagram to its partner, which is false for exactly those
eight. EXECUTED against `verify.py`'s `_partner`: rev and partner disagree on 8 of 64 hexagrams — the
palindrome set above, all with partner = complement — and agree on the other 56; rev still fixes all 32
pairs setwise, so the **conclusion** is unchanged. §Theorem's C1 step already carried the careful form.)*

## Completeness over ALL 64! relabelings (2026-07-18)

The maximality result above stops at the hyperoctahedral group Aut(Q₆) (order 46,080). This section
closes the remaining gap — "how do you know you quotiented by everything?" — by extending the
classification to **every permutation of the hexagram set**.

**Definitions.** For σ ∈ Sym(H) (H = {0,…,63}) and a sequence S (a permutation of H), σ∘S is the
sequence with (σ∘S)ᵢ = σ(Sᵢ). σ **preserves** a predicate P if for ALL sequences S: P(S) ⟺ P(σ∘S).
The preservers of any fixed predicate family form a group (closure and inverses are immediate from
the two-sided definition).

**Theorem (symmetry completeness).** Among all 64! permutations of H, exactly the 48 elements of
G = C_{S₆}(rev) (acting by bit-position permutation) preserve each of C1, C2, C3, C4, C5.
Moreover the converse needs only C1, C2 and C4: any σ preserving those three lies in G.

**Proof.** The forward direction (every σ ∈ G preserves all five) is the theorem above (machine-checked
in Lean, `validC15_mapP`). For the converse, let σ preserve C1, C2, C4.

*Step 1 (C4 ⟹ σ fixes 63 and 0).* The sequence W₄ = (63, 0, …) satisfies C4; σ∘W₄ must too, so
σ(63) = 63 and σ(0) = 0.

*Step 2 (C2 ⟹ σ is an automorphism of the distance-5 graph G₅).* Let G₅ be the graph on H with
a ~ b iff the Hamming distance d(a,b) = 5. The witness family **W2** supplies, for every unordered
pair {a,b} with d(a,b) ≠ 5, a full 64-sequence with a,b adjacent and NO distance-5 adjacency anywhere
(1,824 sequences, constructed greedily and verified exhaustively — gate SC-8). If d(a,b) ≠ 5 but
d(σa,σb) = 5: the witness S = W2(a,b) satisfies C2, yet σ∘S contains the adjacent pair (σa,σb) at
distance 5 — contradiction. If d(a,b) = 5 but d(σa,σb) ≠ 5: apply the same argument to σ⁻¹ (a
preserver, since preservers form a group) and the witness W2(σa,σb). So σ preserves distance-5 both
ways: σ ∈ Aut(G₅).

*Step 3 (Aut(G₅) has order 46,080).* The parity-complement involution ψ(x) = x if popcount(x) is
even, else x ⊕ 63, is a graph isomorphism G₅ → Q₆ (the hypercube: adjacency = distance 1): if
d(x,y) = 5 then y differs from comp(x) in one bit, and ψ applies comp to exactly one of x, y per
parity (gate SC-1, all 2,016 pairs). Aut(Q₆) is the hyperoctahedral group: (i) any two vertices at
distance 2 have exactly two common neighbors (gate SC-3); (ii) hence an automorphism fixing 0 and its
six neighbors pointwise is forced to the identity vertex-by-vertex in weight order — a weight-k vertex
x (k ≥ 2) is the unique common neighbor of two of its weight-(k−1) subwords other than their
weight-(k−2) meet (gate SC-4; SAT kernel: `sat.py --rigidity-cnf`); (iii) so an automorphism fixing 0
is determined by its restriction to the six neighbors of 0, giving |Aut(Q₆)| ≤ 64·720; (iv) the
explicit family x ↦ π(x) ⊕ t realizes this bound. Conjugating by ψ: Aut(G₅) = ψ·Aut(Q₆)·ψ, with all
46,080 elements listed explicitly and each verified edge-preserving (gate SC-5).

*Step 4 (fixing 0 collapses to bit-position permutations).* Write σ = ψ∘(t,π)∘ψ with (t,π) ∈ Aut(Q₆).
Then σ(0) = ψ(t), and ψ(t) = 0 iff t = 0 (if popcount(t) is odd, ψ(t) = t ⊕ 63 = 0 forces t = 63,
which has even popcount — contradiction). With t = 0: ψ∘π∘ψ = π, because ψ commutes with every
bit-position permutation (π is linear with π(63) = 63, and popcount is π-invariant — gate SC-2,
all 720). So σ = π, a bit-position permutation; these all fix 63 as well (gate SC-6).

*Step 5 (C1 ⟹ σ ∈ G).* For each h, the pair-block sequence starting (h, partner(h)) satisfies C1,
so σ(partner(h)) = partner(σ(h)): σ commutes with the partner involution. Among the 720 bit-position
permutations, exactly 48 commute with partner, and they are precisely C_{S₆}(rev) (gate SC-7 checks
both equalities exhaustively). ∎

**Machine verification.** Three independent layers. (i) `python3 solve.py --symmetry-completeness`
runs gates SC-1…SC-8 — every finite claim above verified exhaustively, no sampling (psi isomorphism
2,016 pairs; 720 commutations; distance-2 lemma; forced rigidity derivation; all 46,080
automorphisms edge-checked; the fix-0 and partner filters; the 1,824-sequence W2 family).
(ii) **Lean**: [lean/SymmetryCompleteness.lean](../lean/SymmetryCompleteness.lean) machine-checks
the finite kernel (`psi_involution`, `psi_g5_iso`, `psi_comm_perms`, `q6_two_common_neighbors`,
`rigidity_forced_identity`, `partnerCommuters_eq_G48` + card 48) — **kernel-only since
2026-08-07** (`decide +kernel` finite facts plus a structural proof of `psi_comm_perms`; until
that date this sentence disclosed `native_decide`, the repo's then-current extended-trust-base
convention for finite facts); the 46,080-element enumeration, fix-0 collapse and
sequence-level witness lifting are deliberately NOT formalized there (covered by (i) and the prose).
(iii) `sat.py --rigidity-cnf` emits the Step-3(ii) kernel as a self-validated CNF (4,096 vars,
282,760 clauses, UNSAT; deliberately relaxed encoding, so UNSAT is a fortiori sufficient);
the kissat+DRAT certificate **shipped 2026-07-20** —
[reports/certificates/rigidity_sc4_unsat.drat.gz](../reports/certificates/rigidity_sc4_unsat.drat.gz),
drat-trim-checked and re-verified by [reports/certificates/verify_all.sh](../reports/certificates/verify_all.sh)
(see TR-5 v2.1's changelog) — so all three layers are landed artifacts. *(This paragraph previously
said the DRAT leg was "pending a solver-equipped worker" — stale since 2026-07-20; updated 2026-07-26.)*

**Scope, honestly stated.** (1) The theorem classifies **per-predicate preservers** — σ preserving
each Cᵢ as a property of arbitrary sequences. (2) For the group of **solution-set automorphisms**
(σ mapping the C1–C5 solution set onto itself as a whole), this proof gives containment G ⊆ Aut(solset)
plus the necessary conditions from universally-shared structure (σ(63)=63, σ(0)=0 since every solution
starts 63,0; σ maps the 32 canonical pairs to canonical pairs since every solution is a pair-block
sequence); whether Aut(solset) exceeds G is **not decided** — the full solution set (≈10³⁸) is not
enumerated, and witness-based necessity arguments there would require solutions with prescribed local
features rather than free sequences. No claim is made beyond containment. (3) The earlier
"Maximality" paragraph above is subsumed: it bounded the group within Aut(Q₆); this section removes
that restriction entirely.

*Novelty status: we are not aware of a prior completeness classification of this group over the full
symmetric group for the King Wen constraint system; corrections welcome via
[CITATIONS.md](CITATIONS.md). Developed with AI assistance (Claude, Anthropic).*

## Empirical corroboration (three independent levels)

1. **Exhaustive σ(KW) test over all 720 bit permutations:** exactly the 48 σ ∈ G yield valid C1–C5 sequences
   (the other 672 fail C1); the 48 raw sequences are distinct; they collapse to **24 distinct canonical
   pair-orderings** (KW + 23 twins), each with C3 = 776.
2. **Exact tree isomorphism:** for a KW-following 23-pair prefix (9 free positions) and three random σ ∈ G,
   the exact deterministic subtree counts (`solve --estimate-knuth 0 <prefix>`) are **identical to the
   integer**: tree_nodes = 9,422,793 and **16,504 oriented C1–C5 leaves — 899 distinct pair orderings** —
   for all four σ-related prefixes. σ maps entire backtrack subtrees isomorphically. *(Label corrected
   2026-09-02, prose batch P33, `RP-92020fef` / `RP-35480bc8`: the 16,504 were published under a label this document reserves
   for the orientation-deduped object (this document's opening Result statement: "canonical-record level
   (pair-sequences after orientation dedup)"). They are not that object. `solve.c`'s `exact_count` walks both orientations of every pair and
   increments `leaves_canonical_C1C5` once per **oriented** C3-passing completion, so the mislabel
   originates in the instrument's field name and the prose inherited it; [README.md](../README.md) and
   [CORRECTIONS.md](CORRECTIONS.md) already publish these 16,504 as oriented leaves representing 899 pair
   orderings. Recomputed 2026-09-02 by a clean-room walk over `verify.py`'s
   `KW`/`PAIRS`/`hamming` with a pair-ordering dedup added: the KW-following prefix and the σ-related prefix
   below both give 9,422,793 nodes / 690,176 C1+C2+C4+C5 leaves / 16,504 oriented / 899 orderings — so the
   isomorphism holds at the pair-ordering level too. The shallower published rungs are the same object:
   7-free is 62,256 / 5,624 / 2,232 oriented / **381** orderings, 5-free is 443 / 52 / 4 / **2**.)*
3. **Productive-cells orbit test:** the 65,281 *productive* 560T cells meet **4,183 of the 4,382 ambient
   G-orbits** of the 158,364-cell depth-3 space; the classes measured are therefore **intersections of
   ambient orbits with the productive subset, not complete orbits**, and 199 ambient orbits contain no
   productive cell at all. The within-orbit coefficient of variation of the per-cell Knuth size estimates
   (10⁵ probes/cell) is **0.112 (median)** — indistinguishable from the estimator's own noise floor
   (median relerr 0.130) and 6× below the population CV (0.72). True per-cell counts are orbit-equal within
   measurement resolution **on the productive 41.2% of cells** (65,281 of 158,364); the other 93,083 cells
   were not measured. *(Scope corrected 2026-09-02, prose batch P33, `RP-a5c2bc8c` / `RP-78ce5960`: the heading and the closing
   sentence generalised a productive-subset measurement to the whole space. The **ambient** cell space is
   G-closed and the productive subset is not — recomputed 2026-09-02 from the constraint definitions, the
   depth-3 C2/C5-feasible cells number 158,364 and all 48 σ map every one of them to another feasible cell,
   in 4,382 orbits of sizes {6:14, 12:270, 24:1736, 48:2362}; the 4,183 is read from the private per-cell
   table and is not recomputed here. This repository already published the gap:
   [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md) §"What is being measured" gives the 158,364 depth-3 cells
   and §"Result — per-cell distribution + budgeted yield is uncorrelated with cell size" records that the
   remainder "lies in the ~93K cells that produced 0 records", and
   §"What the 2026-04-25 test actually measured" below concedes that orbit-mates of productive cells are
   often unproductive at a given budget.)*

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
solution space's orbit structure **at the ordering level** (and KW's 23 twins) is a new object of study in
its own right — hexagram-level orbit structure is prior art and is ceded above, back to
[Wu Cheng c. 1300](CITATIONS.md#wucheng).

## Reproducibility

⚠ **Every `--estimate-knuth` command below requires a stack limit of at least 16 MB** — `ulimit -s 16384` suffices, and `ulimit -s unlimited` is one way to satisfy it, not the requirement itself. Under the default 8 MB stack the estimator does not start: `main` allocates a ~7.23 MB frame and `estimate_tree_knuth` a further ~1.02 MB, so the 8 MB limit is exceeded the moment the estimator would be entered (since 2026-08-21 the binary preflights `RLIMIT_STACK`, refuses to start with an actionable message naming the >= 16 MB it needs, and exits 1; previously a bare SIGSEGV). This is environmental, not a logic fault — with the limit raised the published figures reproduce. *(Added 2026-08-21: found by a cold external-reviewer pass and independently reproduced; the requirement had been documented only in CANONICAL_HASHES.md's large-scale-enumeration recipe, while these guides state the estimator needs no data disk and costs pennies.)* *(Corrected 2026-09-01: the failure mode was previously described as a segfault before any output, telling an operator to expect exit 139 from a binary that has exited 1 with a diagnostic since 2026-08-21. `solve.c`'s `--estimate-knuth` parse block preflights `RLIMIT_STACK` and, below 16 MB, prints "solve: stack limit is %lu MB, but --estimate-knuth needs >= 16 MB ... Re-run with: ulimit -s unlimited" and returns 1; its own comment records "previously a bare SIGSEGV after the banner". That pass corrected the failure MODE only; the requirement itself is narrowed in the note below.)* *(Narrowed 2026-09-02, Codex V2-F08 #4, prose batch P37: `ulimit -s unlimited` is a **sufficient** setting that had been published as a **necessary** one — and one that a host or container with a hard stack cap cannot even apply, so the published requirement was a false blocker there. `solve.c`'s `--estimate-knuth` preflight tests `rlim_cur != RLIM_INFINITY && rlim_cur < 16UL*1024*1024` and its message names ">= 16 MB". EXECUTED under TR-9 v1.24 on a locally built binary: `ulimit -s 8192` refuses and exits 1, `ulimit -s 16384` runs the estimator to completion. `solve.c`'s own remedy line still prescribes only `unlimited` and is queued to offer both. This is the sibling propagation of the narrowing TR-9 made on 2026-09-02 and reported but did not sweep.)*
```bash
# exact tree-isomorphism check (any sigma in G; prefix = 22 (pair,orient) args after the forced first pair):
./solve --estimate-knuth 0 1 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 20 0 21 0 22 0
./solve --estimate-knuth 0 22 1 28 0 3 1 21 1 26 0 6 1 11 0 5 0 19 0 27 0 7 1 16 1 30 1 14 0 20 0 18 1 25 0 24 1 1 1 15 0 4 0 9 0
# -> both print tree_nodes = 9,422,793 and leaves_canonical_C1C5 = 16,504
#    (that is the binary's own field name; the object it counts is ORIENTED C1-C5 leaves,
#     which are 899 distinct pair orderings -- see the label correction in item 2 above)
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

Productive-cells orbit test (within-orbit CV 0.112): the per-cell estimates are

```bash
SOLVE_THREADS=32 SOLVE_KNUTH_SEED=0x243F6A8885A308D3 \
  ./solve --estimate-knuth 100000 <p1> <o1> <p2> <o2> <p3> <o3>
```

over the 65,281 productive 560T cells (cell list from the 560T shard manifest, reproducible per
[CANONICAL_HASHES.md](CANONICAL_HASHES.md)); the ambient G-orbits are the σ-action on (pair, orient)
prefixes from the snippet above. **Pin both variables.** `solve.c`'s `--estimate-knuth` parse block takes
its worker count from `SOLVE_THREADS` and, when that is unset, from `sysconf(_SC_NPROCESSORS_ONLN)`; the
probe budget is split across workers and each worker is seeded from `knuth_seed_base` (`SOLVE_KNUTH_SEED`,
default `0x243F6A8885A308D3`), so the **thread count selects the sample** and an unpinned command is
machine-dependent — [METHODS.md](../reports/METHODS.md) §"Reproducibility rule for estimator output" guarantees identical output
only at identical (probes, threads). The exact-mode commands above (`--estimate-knuth 0`) are
deterministic and need no pin. *(Added 2026-09-02, prose batch P33: the command shipped with neither
variable pinned.)*

**What of this reproduces publicly.** The σ(KW) validity/orbit-collapse snippet and the exact-subtree
commands above are fully public and self-contained, and the **ambient** G-orbit partition of the
158,364-cell depth-3 space recomputes in about a second from the same snippet's σ-action. Two inputs are
not public: the **productive-cell list** (derived from the 560T shard manifest) and the **per-cell estimate
table** (~65K estimator calls, hours-scale private working data). The 4,183 orbit-class count and the
0.112 median CV rest on those two, and a replicator regenerating the estimates must expect
thread-count-dependent scatter on each cell, so a re-derived CV should be compared against a published
tolerance rather than to the third decimal.

**Ambient G-orbits of the depth-3 cell space** (<1 s, pure python, run from the repo root — verified
output: `158364 depth-3 cells; 4382 ambient G-orbits, sizes {6: 14, 12: 270, 24: 1736, 48: 2362}`).
The `assert` is the G-closure check: no σ-image of a feasible cell leaves the feasible set.

```python
from itertools import permutations
from collections import Counter
import solve
KW = solve.binary_hexagrams
PAIRS = [(KW[2*i], KW[2*i+1]) for i in range(32)]
d = solve.bit_diff
BUD0 = [0]*7
for i in range(63): BUD0[d(KW[i], KW[i+1])] += 1   # C5 multiset
BUD0[6] -= 1                                       # pair 0's own within-pair transition
sig = lambda p, h: sum(((h >> b) & 1) << i for i, b in enumerate(p))
rev = (5, 4, 3, 2, 1, 0)
G = [p for p in permutations(range(6))             # the centralizer of rev, re-derived
     if all(sig(p, sig(rev, h)) == sig(rev, sig(p, h)) for h in range(64))]

def cells(depth):                                  # C2/C5-feasible (pair, orient) prefixes
    out, stack = [], [((), 0, 1, BUD0)]
    while stack:
        pre, last, used, bud = stack.pop()
        if len(pre) == 2*depth: out.append(pre); continue
        for p in range(1, 32):
            if (used >> p) & 1: continue
            a, b = PAIRS[p]
            for o, (f, s) in enumerate(((a, b), (b, a))):
                bd, wd = d(last, f), d(f, s)
                if bd == 5 or bud[bd] == 0: continue
                nb = bud[:]; nb[bd] -= 1
                if nb[wd] == 0: continue
                nb[wd] -= 1
                stack.append((pre + (p, o), s, used | 1 << p, nb))
    return out

slot = {h: (i, j) for i, ab in enumerate(PAIRS) for j, h in enumerate(ab)}
def act(p, c):                                     # sigma's action on a (pair, orient) prefix
    out = []
    for k in range(0, len(c), 2):
        a, b = PAIRS[c[k]]
        f, s = (b, a) if c[k+1] else (a, b)
        i, o = slot[sig(p, f)]
        out += [i, o]
    return tuple(out)

C = cells(3); S = set(C); seen, orb = set(), []
for c in C:
    if c in seen: continue
    im = {act(p, c) for p in G}
    assert im <= S                                 # the ambient space is G-closed
    seen |= im; orb.append(len(im))
print(len(C), "depth-3 cells;", len(orb), "ambient G-orbits, sizes",
      dict(sorted(Counter(orb).items())))
```

**Oriented leaves vs distinct pair orderings** (the label correction in §"Empirical corroboration"
item 2). Continuing from the definitions above, this recomputes the exact subtree anchors and adds the
orientation dedup the published `canonical` label implied but the instruments never performed —
verified output `5-free: tree_nodes=443 leaves_C1C2C4C5=52 oriented_C1C5=4 pair_orderings=2`,
`7-free: … 62256 … 5624 … 2232 … 381`, `9-free: … 9422793 … 690176 … 16504 … 899`. The 5- and 7-free
rungs are instant; 9-free visits ~9.4M nodes and takes a couple of minutes in CPython.

```python
def walk(prefix):                      # exact C1-C5 subtree below a (pair, orient) prefix
    bud = [0]*7
    for i in range(63): bud[d(KW[i], KW[i+1])] += 1
    bud[6] -= 1
    seq, slotp, used, last, step = [63, 0] + [0]*62, [0]*32, 1, 0, 1
    for p, o in prefix:
        a, b = PAIRS[p]; f, s = (b, a) if o else (a, b)
        bud[d(last, f)] -= 1; bud[d(f, s)] -= 1
        seq[2*step], seq[2*step+1] = f, s
        slotp[step] = p; used |= 1 << p; last = s; step += 1
    stat, orders = [0, 0, 0], set()
    def rec(st, lst, um):
        stat[0] += 1
        if st == 32:
            stat[1] += 1
            pos = [0]*64
            for i, v in enumerate(seq): pos[v] = i
            if sum(abs(pos[v] - pos[v ^ 63]) for v in range(64)) <= 776:   # C3
                stat[2] += 1; orders.add(tuple(slotp))                     # drop orientation
            return
        for p in range(1, 32):
            if (um >> p) & 1: continue
            a, b = PAIRS[p]
            for f, s in ((a, b), (b, a)):
                bd = d(lst, f)
                if bd == 5 or bud[bd] == 0: continue
                bud[bd] -= 1; wd = d(f, s)
                if bud[wd] == 0: bud[bd] += 1; continue
                bud[wd] -= 1
                seq[2*st], seq[2*st+1] = f, s; slotp[st] = p
                rec(st + 1, s, um | 1 << p)
                bud[wd] += 1; bud[bd] += 1
    rec(step, last, used)
    return stat, len(orders)

for free in (5, 7):                    # add 9 for the 9,422,793-node anchor (~2 min)
    st, n = walk([(i, 0) for i in range(1, 32 - free)])
    print(f"{free}-free: tree_nodes={st[0]} leaves_C1C2C4C5={st[1]} "
          f"oriented_C1C5={st[2]} pair_orderings={n}")
```

The σ-related prefix of the code block above is checked the same way — pass its 22 `(pair, orient)`
tuples to `walk()` instead of the KW-following list, and it returns the same four integers.

Original 2026-04-25 phases 1–3 ([`./solve --symmetry-search [--validate-counts]`](SOLVE_C_CLI.md#--symmetry-search)) remain reproducible; their
output is correct as *budgeted-yield* data. Full working notes: `roae-private/THEOREM_C15_SYMMETRY_GROUP_2026_07.md` *(private staging repo — not publicly accessible; a provenance pointer, and no claim here rests on it)*. The theorem, its proof and the correction notice are public in this document, and the reruns above are the public verification path for everything except the two private inputs named in §Reproducibility — the productive-cell list and the per-cell estimate table. *(Corrected 2026-09-02, prose batch P33, `RP-11f9daff`: this sentence had asserted that every table needed to verify is public, four lines after §Reproducibility said the per-cell estimate table is private working data; the two could not both hold, and it is this one that was false.)*

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

**Machine-checked (2026-07-05):** this document's sequence-level layer — G-invariance of C1–C5 over all
orderings, freeness of the record-level S₄ action, and the corollary 24 ∣ |canonical solution records| —
is machine-checked in core Lean 4 (no Mathlib): [lean/Automorphism.lean](../lean/Automorphism.lean),
theorems `validC15_mapP`, `act_fix_id_or_rho`, `twenty_four_dvd_solution_count` (finite lemmas:
[lean/KingWen.lean](../lean/KingWen.lean)). Since the 2026-07-27 kernel migration (completed
2026-07-31 for `Automorphism.lean`'s composition law, now proved structurally), both files carry
**zero** `native_decide` — the whole chain is kernel-only (`#print axioms` ⊆
`[propext, Classical.choice, Quot.sound]`; see [lean/README.md](../lean/README.md)).

**Trigram-compatible subgroup (2026-07-11):** exactly **12 of the 48** elements of G respect the trigram
bipartition {lines 1–3}, {lines 4–6} as an unordered block pair; they form a subgroup ≅ **S₃ × C₂** (with
ρ = bit-reversal central), collapsing to S₃ (order 6) at record level. The upper/lower trigram change-count
functionals are invariant under this subgroup but **not** under the full record-level S₄ — so the
relabeling-invariance caveat above bites concretely for trigram-defined statistics. Machine-checked:
[lean/TrigramTheorems.lean](../lean/TrigramTheorems.lean) (TG-3); prose + scope:
[TRIGRAM_STRUCTURE.md](TRIGRAM_STRUCTURE.md). Scope note: this subgroup lives inside G — the
**line-position centralizer acting on orderings** — and is a different group acting on a different object
than [Hershock (1991)](CITATIONS.md#hershock1991)'s group generated by complement, reversal, and trigram
swap **acting on the hexagram set** (his 14 "families of derivation" decomposition). The two are related
only in that both mention trigrams; neither result overlaps, duplicates, or extends the other — see
[TRIGRAM_STRUCTURE.md](TRIGRAM_STRUCTURE.md) §2 for the full distinction table.

## Limits and scope

- The classification now covers all of Sym(H) (§Completeness above), with flips excluded **by C4
  specifically** (they move 0/63) and everything outside the hyperoctahedral group excluded by C2's
  distance-5 graph rigidity. A constraint system without C4 would admit a larger flip-extended
  analysis — not pursued. The completeness theorem is about per-predicate preservation; the
  solution-set automorphism group is bounded below by G and not decided above (see the scope note).
- Whether KW's 23 twins appear in budgeted canonicals is now MEASURED (2026-07-02, direct bisection of the
  560T canonical): **King Wen is present; all 23 twins are absent.** Their membership in the full solution
  set is proven — their absence from the budgeted set is a search-orientation effect: the enumeration's
  variable order is derived from King Wen, so KW lies on the early DFS path of its cell while each
  relabeled twin is a late leaf of its own cell. Presence in a budgeted canonical therefore reflects the
  search's frame of reference, not a mathematical property of the ordering — the strongest concrete
  illustration yet of the caveat in [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md) §"Is finding King Wen
  early then an artifact".
- The orbit-reduction design (enumerate representatives, relabel + re-canonicalize) is specified but not
  implemented; canonical-sha implications make production adoption an explicitly gated decision.

## Related work

Goldenberg (1975, *Journal of Chinese Philosophy* 2:149–79) gave the earliest algebraic
formalization of the hexagram set known to us: the line symbols as a field under mod-2 arithmetic,
the 64 hexagrams as the corresponding commutative ring (equivalently GF(2)⁶, the framing this
project assumes throughout), the inversion mapping as an automorphism, and a "mediating hexagram"
(the XOR difference vector) for every pair. His results concern the hexagram *set*; the theorem
here concerns the automorphism group of the C1–C5 *constraint system on orderings*, which has no
counterpart in Goldenberg. Credit to [Hacker, Moore & Patsco (2002)](CITATIONS.md#hacker-moore2002), entry B:154, whose annotation
surfaced this work to us. **Read in full 2026-07-11** — all repo-encoded claims (G-T1–T4, T7, including
the KW5↔KW63-via-KW7 worked example, p. 170) are verified against the primary text; see
[CITATIONS.md](CITATIONS.md) §"Goldenberg, Daniel S. (1975)". *(Corrected 2026-09-02, prose batch P33,
`RP-efc6640b`: this sentence still reported the acquisition as outstanding, while
[CITATIONS.md](CITATIONS.md) had recorded the interlibrary-loan scan and the claim-by-claim verification
since 2026-07-11.)*

*(Alignment note, 2026-08-06; enumeration re-synced to the ledger 2026-09-02, prose batch P33.)*
Goldenberg is the earliest of the independent arrivals at the hexagram-set-level algebra. The full,
authoritative list is the chain in [CITATIONS.md](CITATIONS.md) §"The (Z/2)⁶ hexagram algebra and
hexagram-level group actions — priority ceded", which makes ROAE the **seventh**: Goldenberg (1975) →
Ouyang (≤1986 framework; [1990](CITATIONS.md#ouyang1990), [1992](CITATIONS.md#ouyang1992)) →
[Yuan Zuoxing (1991)](CITATIONS.md#yuanzuoxing1991) →
[Cao Hongjun, Li Shuzhong and Liu Yanan (1995)](CITATIONS.md#caohongjun1995) →
[Suenaga (2012)](CITATIONS.md#suenaga2012) → [Radisic (2026)](CITATIONS.md#radisic2026) → ROAE, with
[Schöter (1998)](CITATIONS.md#schoter1998) recorded there as a further independent-then-crediting arrival
rather than a numbered link in the chain. *(Corrected 2026-09-02: the enumeration here read "the others
being" and named four, omitting Yuan and Cao, whom the ledger has credited since 2026-08-29; treat
CITATIONS.md, not this note, as the list of record.)* The same scoping applies to each: set-level, not
ordering-level, prior art.
