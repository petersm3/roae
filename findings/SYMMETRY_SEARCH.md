# No Hamming-Class-Preserving Symmetry on the C1 ∩ C2 ∩ C3 Canonical

**Result:** Among the 720 bit-position permutations of the 6-bit hexagram space, 48 preserve the C1 partition. Of those, 47 act non-trivially on the (pair, orientation) space. **All 47 are falsified** as symmetries of the C1 ∩ C2 ∩ C3 canonical orderings: each maps at least 21,000 depth-3 sub-branches to sub-branches with materially different yields (max yield difference > 800,000 records).

The constraint set is rigid against bit-permutation symmetries. No factor-of-2-to-48 enumeration cost reduction is available via this class of would-be symmetries.

This is a clean negative result — paper-citable as a precise quantitative refutation of "King Wen's structure has natural bit-permutation symmetries."

## Hypothesis tested

A permutation σ : {0..63} → {0..63} is **Hamming-class-preserving** if hamming(σ(x), σ(y)) = hamming(x, y) for all x, y. The full group is Aut(Q₆), order 6! · 2⁶ = 46,080.

Bit-flip operations don't generally preserve C1 (the pair-partner relation is not invariant under bit-flip), so the relevant subgroup is the **6! = 720 bit-position permutations** of {0..5}.

**Hypothesis (H₁):** for every Hamming-class-preserving σ that preserves C1, the canonical solution counts at every C1 ∩ C2 ∩ C3 sub-branch are equal under the σ-relabeling, and the records themselves are in bijection via the σ-induced map.

**Null (H₀):** some pair of depth-3 prefixes related by such a σ have different canonical solution counts.

## Method

Three phases (see `solve.c --symmetry-search`):

1. **Enumerate** all 720 bit-permutations of {0..5}.
2. **Filter** to C1-preserving (those σ where {σ(a), σ(b)} ∈ C1-pairs for every C1-pair (a, b)). 48 σ pass (6.7%).
3. **Compute** σ's induced action on the 64-element (pair_idx, orient) space. 47 σ act non-trivially. 1 σ is identity in pair-orient space (it permutes within hexagrams of the same pair, swapping a ↔ b without changing pair identity).
4. **Test** each non-trivial σ against per-sub-branch yields from the 100T-d3 canonical enum log. For each productive sub-branch (60,533 in the 100T data), compute σ-image sub-branch and compare yields.

## Result

All 47 non-trivial σ falsified. Closest near-miss is the full bit-reversal σ = [5, 4, 3, 2, 1, 0]:

| σ | matches | mismatches | missing | max_diff |
|---|---:|---:|---:|---:|
| [5, 4, 3, 2, 1, 0] | 26,158 (43%) | 32,456 (54%) | 1,919 | 811,359 |
| [0, 4, 2, 3, 1, 5] | 8,656 (14%) | 35,666 (59%) | 16,211 | 1,465,373 |
| [0, 1, 3, 2, 4, 5] | 14,850 (25%) | 22,466 (37%) | 23,217 | 1,550,062 |
| ... (44 others) | <30% match | >50% mismatch | varies | typically > 1.5M |

`missing` = σ-image had no entry in the parsed log (typically because that sub-branch was BUDGETED with 0 solutions, so no Wrote-line was emitted). Even treating missing as inconclusive, the mismatch rates are decisive.

Every σ has at least 21,000 mismatched (preimage, σ-image) sub-branch pairs out of ~37,000-58,000 testable pairs.

## Implications

1. **No exploitable orbit symmetry** for the C1 ∩ C2 ∩ C3 canonical via this class. The 158,364 sub-branches of the 100T-d3 enumeration really are 158,364 distinct sub-trees, not 1,649-3,300 orbital representatives.

2. **Constraint set is rigid** against bit-position permutations. The combination C1 ∩ C2 ∩ C3 + canonical sort breaks every non-trivial Hamming-class symmetry. This is a structural property of the constraint system, not of any particular King Wen feature.

3. **Complements Campaign C** — Campaign C (2026-04-22) had falsified the simpler "pair-relabeling" hypothesis via per-prefix histogram comparison on 6 yield-1,110,544 branches. This work generalizes to the broader bit-permutation class on the full 60,533-branch yield set.

4. **Paper §6 (Discussion)** gains a precise quantitative no-symmetry paragraph.

## Reproducibility

Source data: `solve_c/runs/20260419_100T_d3_d128westus3/enum_output.log.gz` (canonical 100T-d3 enum log, sha-anchored archive).

```bash
# Phase 1 + 2 (enumeration + orbit structure; ~2 seconds)
./solve --symmetry-search

# Phase 3 (yield comparison against the 100T canonical)
zcat solve_c/runs/20260419_100T_d3_d128westus3/enum_output.log.gz \
    | ./solve --symmetry-search --validate-counts
```

Validates against the canonical sha `915abf30…` corresponding to the parsed log.

The implementation is in `solve.c` (commit history). `--selftest` sha `403f7202…` is preserved across these additions — the new subcommand is purely analytical.

## Phase 4 — not needed

The original spec described a Phase 4 (bijection sampling against `solutions.bin` records) for any σ that survives Phase 3. **No σ survived**, so Phase 4 has no candidate to test. No additional compute needed.

## Limits and scope

- **Not tested**: bit-flip ⨉ bit-perm combinations (the full 46,080-element Aut(Q₆) group). Restricted to the 720 bit-perm subgroup, which is the subgroup that interacts naturally with C1.
- **Not tested**: weaker symmetries (e.g., σ preserves the *distribution* of yields per orbit but not exact values). A weaker form may hold but isn't useful for cost reduction.
- **Tested at**: 100T-d3 canonical (3.43B records, 158,364 depth-3 sub-branches). Scope is this dataset.

## Working / process documentation

For the original design discussion + iterative context, see [`x/roae/SYMMETRY_SEARCH_SPEC.md`](https://github.com/petersm3/x/blob/main/roae/SYMMETRY_SEARCH_SPEC.md) and [`x/roae/SYMMETRY_SEARCH_FINDINGS.md`](https://github.com/petersm3/x/blob/main/roae/SYMMETRY_SEARCH_FINDINGS.md) (private staging repo).
