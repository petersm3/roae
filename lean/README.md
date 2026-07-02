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
