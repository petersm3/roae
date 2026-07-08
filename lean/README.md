# Machine-checked proofs (Lean 4)

## Executive summary (plain English)

This directory contains **machine-checked mathematical proofs**. Instead of trusting a human
argument (or this project's own C and Python code), the Lean 4 proof assistant re-derives each
statement from first principles and its small trusted kernel certifies the logic. What that buys:

- **The constraint system's basic facts are beyond dispute.** Every hexagram pair's distance
  properties, the exact set of XOR products, the parity structure, and King Wen's satisfaction of
  the constraints are proved by exhaustive kernel-verified computation — not by our software, which
  could have bugs, but by a checker whose only trusted component is Lean's core.
- **The symmetry theorem is fully machine-checked** (finite component + the sequence-level layer in
  `Automorphism.lean`): the constraint system has exactly 48 relabeling symmetries, they act freely
  at the record level in 24-element orbits, and therefore **24 divides every exact solution count**.
  This is the theorem behind the "divisible by 24" sanity gate applied to the project's exact counts;
  if a count ever failed that gate, the computation — not the mathematics — would be at fault.
- **No proof gaps**: the files contain zero `sorry` placeholders; everything stated is proved, and
  `lake build` re-verifies the whole suite from scratch in seconds on any machine.

In short: the deepest structural claims this project relies on do not depend on trusting us.


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
# install elan (Lean version manager), then (each file is standalone; no lake project):
lean KingWen.lean          # silence = all theorems check (Lean 4, tested with 4.31.0)
lean C3Decomposition.lean  # C3 slot-decomposition theorem (sat.py's C3-encoding soundness core)
lean PruneSafety.lean      # v4 walk-level prune-safety lemma (isomorph-free generation soundness)
lean Automorphism.lean     # the sequence-level symmetry layer (see below)
```

**Related formal work:** [Radisic 2026](../documentation/CITATIONS.md#radisic2026) (arXiv:2601.07175) independently formalized King Wen pairing
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

## Automorphism.lean (2026-07-05): the sequence-level symmetry layer
Formalizes the [SYMMETRY_SEARCH.md](../documentation/SYMMETRY_SEARCH.md) theorem and its 2026-07-03
free-action corollary end-to-end — from the finite centralizer facts to the divisibility of the
solution count. Core Lean 4 only, standalone file, structural proofs over ALL orderings (native_decide
carries only the finite group facts). Verified statements:

| Theorem | Statement |
|---|---|
| `c1ok_mapP` … `c4ok_mapP`, `transitions_mapP`, `c3x64_mapP`, `validC15_mapP` | **Invariance**: every σ in the 48-element centralizer of bit-reversal maps every valid C1–C5 ordering (any permutation of the 64 hexagrams, not just King Wen) to a valid C1–C5 ordering; the transition list and the C3 sum are exactly preserved |
| `pairKey_mapP` | **Compatibility**: canonicalization commutes with the action — pairKey(σ·l) = σ·pairKey(l) (record-level action = relabel pair keys) |
| `act_rho_solrec`, `act_fix_id_or_rho` | **Kernel + freeness**: bit-reversal acts trivially on every solution record; any element of G₄₈ fixing ANY solution record is the identity or bit-reversal — so the record-level S₄ (order 24) acts freely ("every solution has exactly 23 twins", now for all solutions) |
| `twenty_four_dvd_count` | **Orbit partition** (generic engine): for any G-invariant constraint predicate containing C1, every duplicate-free complete listing of the record-level solution set has length divisible by 24 |
| `twenty_four_dvd_solution_count` | **The corollary**: 24 ∣ number of canonical C1–C5 solution records — the theorem behind the DIV-24 integrity gate on exact counts |
| `twenty_four_dvd_c1c2c4_count`, `twenty_four_dvd_c1c2c4c5_count` | The same divisibility for the exact-count constraint systems C1∩C2∩C4 and C1∩C2∩C4∩C5 (record level; see the file's scope note on record-level vs orientation-resolved counts) |
| `kw_solution_record` | Sanity witness: King Wen's canonical record is a solution record (the count is a positive multiple of 24) |

The count statement is exact-matching by construction: `SolRec Q r` says r = pairKey(l) for some
permutation l of the 64 hexagrams with Q(l), the same record-level object (pair-sequences after
orientation dedup) counted by the enumeration pipeline and `twins_24_records`.
