# Machine-checked proofs (Lean 4)

`KingWen.lean` contains kernel-checked proofs of the ROAE constraint system's finite core lemmas —
**core Lean 4 only, no mathlib**; every hexagram-level claim is proved by `native_decide`
(exhaustive, kernel-verified computation). Verified statements:

| Theorem | Statement |
|---|---|
| `within_pair_even_nonzero` | Theorem 1: within-pair Hamming distance is even and nonzero for all 64 hexagrams |
| `xor_universality` + `xor_all_seven_attained` | Theorem 2: XOR products {h ⊕ partner(h)} = exactly {12, 18, 30, 33, 45, 51, 63} |
| `partner_preserves_parity`, `parity_split_32_32`, `xor_parity_identity` | The lemmas of the parity-alternation theorem ([PARITY_ALTERNATION.md](../documentation/PARITY_ALTERNATION.md)) |
| `kw_valid`, `kw_c3_exactly_776`, `kw_no_five`, `kw_alternations_15` | King Wen satisfies C1/C4/C5 (hence C2), has complement-distance sum exactly 776, and exactly 15 parity-class alternations |
| `sigma_kw_valid_48`, `valid_iff_centralizes_rev`, `twins_24_records` | The finite component of the symmetry theorem ([SYMMETRY_SEARCH.md](../documentation/SYMMETRY_SEARCH.md)): exactly 48 of the 720 bit permutations map KW to a valid sequence — **exactly** the centralizer of reversal — collapsing to 24 record-level twins |

The sequence-level theorems (wrap parity, the full 15-alternation theorem over all valid orderings,
the symmetry theorem over the full solution set) follow from these lemmas by the short telescoping /
linearity arguments in the corresponding documentation — the machine-checked layer pins down every
finite computation those arguments rest on.

## Verify yourself

```bash
# install elan (Lean version manager), then:
lean KingWen.lean   # silence = all theorems check (Lean 4, tested with 4.31.0)
```

**Related formal work:** Radisic 2026 (arXiv:2601.07175) independently formalized King Wen pairing
optimality in Lean 4 + Mathlib (K₄-equivariant matching; different object from the constraint-system
symmetry group verified here). See CITATIONS.md.

## Tier 2 (2026-07-03): structured sequence-level proofs
`wrap_parity_general` — the wrap-parity theorem verified for EVERY C4+C5 sequence of 6-bit values by
structural induction (telescoping transition-parity lemma + sum-parity/odd-count machinery), not by
finite enumeration. Supporting lemmas: `transitions_sum_parity`, `sum_parity_odd_count`,
`odd_count_partition`, bounded pointwise facts by kernel `decide`. This upgrades the formal core from
"finite facts checked" to "sequence-level theorem proven" for the wrap-parity result; the 15-alternation
general theorem is the next tier-2 target (ingredients present: within-pair evenness, the C5 odd-count,
the parity identity).

## Tier 2b (2026-07-03): the general 15-alternation theorem
`alternations_15_general` — every C1+C5 sequence of 64 six-bit values has EXACTLY 15 parity-class
alternations, machine-checked by structural proof (transitions-as-range-map bridge lemma; index-parity
split via a kernel-decided permutation of range 63; within-pair evenness from C1; the C5 odd-transition
count). Both sequence-level theorems of the project (wrap parity + 15 alternations) are now
kernel-verified for ALL valid sequences, completing the Lean tier-2 program.

## switches_30_general (2026-07-04)
Third sequence-level theorem: every C1+C5-valid ordering's transition-parity string switches exactly 30
times. Kernel-checked corollary of `alternations_15_general` + the within-pair-even lemma; discovered as
a pre-registered F4' population functional that measured CONSTANT before being proved (reports/TR6,
v1.3-v1.4).
