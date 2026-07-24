# Machine-checked proofs (Lean 4)

## Executive summary (plain English)

This directory contains **machine-checked mathematical proofs**. Instead of trusting a human
argument (or this project's own C and Python code), the Lean 4 proof assistant re-derives each
statement from first principles and certifies the logic (see the trust-base note below for
exactly which proofs are checked by Lean's small kernel alone and which additionally trust
Lean's compiler). What that buys:

- **The constraint system's basic facts are beyond dispute.** Every hexagram pair's distance
  properties, the exact set of XOR products, the parity structure, and King Wen's satisfaction of
  the constraints are proved by exhaustive computation checked by Lean — not by our software, which
  could have bugs. (See the trust-base note below: `decide` proofs are checked by Lean's small
  kernel alone; the finite lemmas proved by `native_decide` additionally trust Lean's compiler and
  native code generator.)
- **The symmetry theorem is fully machine-checked** (finite component + the sequence-level layer in
  `Automorphism.lean`): the constraint system has exactly 48 relabeling symmetries, they act freely
  at the record level in 24-element orbits, and therefore **24 divides every exact solution count**.
  This is the theorem behind the "divisible by 24" sanity gate applied to the project's exact counts;
  if a count ever failed that gate, the computation — not the mathematics — would be at fault.
- **The merge's reproducibility mathematics is machine-checked at the model level**
  (`PartitionInvariance.lean`): the abstract merge model is proven invariant to input order,
  partition choice, invocation grouping, and merge hierarchy. Its connection to the actual C
  enumerator runs through stated bridge facts that are NOT machine-checked — this is a model-level
  result, not a proof of the C code; see the Tier 3 section's scope note.
- **The eight "forced" literature rules are proven, not just measured** (`C1RuleConstants.lean`): the
  eight registry rules that measure at rate 1.0 under enumeration (mmt4, p1c4, s1, s6, r3, r4, r5, c2)
  are **constants of the entire C1 space** — each depends only on the unordered pair-partition, which C1
  fixes, so no valid ordering can violate them. This upgrades the "empirically forced (sampled)" status
  to a theorem; the zero-hit enumeration measurement is now a corollary. (Orientation-invariance of each
  per-pair predicate is `decide`d over all 64 hexagrams; the fixed range-64 counts by `native_decide`;
  the sequence-level constancy in the landed `within_double` style.)
- **The exact C1∩C4 null law of the C3/G channel is kernel-checked end to end** (2026-07-24,
  `C3Decomposition.lean` final section): the full exact distribution of the couple slot-distance
  sum G over the 31! equally-weighted C1∩C4 pair-orders — total mass 31!, support exactly
  [12, 228], E[G] = 128 exactly (hence E[C3] = 1040), and P(G ≤ 95) =
  641983711307479/7919632354008375 exactly (≈ 8.106%; 95 is King Wen's own value) — every fact by
  kernel `decide`, no `native_decide`, with the DP recurrence itself validated in-kernel against
  brute-force enumeration over all orderings at small sizes. This upgrades the exact-null leg
  previously carried by `verify.py --check-null-g` from exact-by-computation to machine-checked.
- **No proof gaps**: the files contain zero `sorry` placeholders; everything stated is proved, and
  each standalone file re-verifies from scratch in seconds on any machine (`lean <File>.lean`;
  the toolchain is pinned in this directory's `lean-toolchain`; the one exception to "seconds" is
  `C3Decomposition.lean`, ~2 minutes, which kernel-evaluates the null-law DP).

In short: the deepest structural claims this project relies on do not depend on trusting us.


`KingWen.lean` contains machine-checked proofs of the ROAE constraint system's finite core lemmas —
**core Lean 4 only, no mathlib**; every hexagram-level claim is proved by `native_decide`
(exhaustive computation over the finite domain).

**Trust-base note (what "machine-checked" means here, precisely).** Lean proofs by `decide` are
verified by Lean's small trusted kernel. Proofs by `native_decide` are NOT kernel-only: they
additionally trust Lean's compiler and native code generator (a strictly larger trusted base, which
has had real soundness bugs historically). In this suite, `native_decide` carries only finite
exhaustive computations (hexagram-level lemmas, group facts, sanity witnesses); the structural
sequence-level theorems (`wrap_parity_general`, `alternations_15_general`, the T1–T5 merge theorems
in `PartitionInvariance.lean`, …) are ordinary structural proofs checked by the kernel. Where a
finite lemma is small enough, migrating `native_decide` → `decide` is a standing opportunistic
cleanup.

Verified statements:

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
# install elan (Lean version manager); the pinned toolchain is in ./lean-toolchain
# (leanprover/lean4:v4.31.0). Each file is standalone; no lake project:
lean KingWen.lean            # silence = all theorems check (Lean 4, tested with 4.31.0)
lean C3Decomposition.lean    # C3 slot-decomposition theorem + the exact C1∩C4 null G-law (see below; ~2 min — kernel-evaluates a 31-layer DP)
lean PruneSafety.lean        # v4 walk-level prune-safety lemma (isomorph-free generation soundness)
lean Automorphism.lean       # the sequence-level symmetry layer (see below)
lean PartitionInvariance.lean  # tier-3 model-level merge/partition-invariance theorems (see below)
lean TrigramTheorems.lean    # trigram-level structure: forced boundary budget, S3xC2 subgroup (see below)
lean SymmetryCompleteness.lean  # TR-5 v2.0 completeness kernel: psi iso, Q6 rigidity, partner-commuters = G48 (2026-07-18)
lean C1RuleConstants.lean    # the eight "forced-1.0" literature rules (mmt4,p1c4,s1,s6,r3,r4,r5,c2) are constants of the C1 space (2026-07-21)
```

**Files on the `v4-canonical` branch, not here.** Three Lean files live on the public
`v4-canonical` branch rather than `main`, because they concern the v4 compiler/f1c5 layer.
Reports link to them with that qualifier; if a link looks broken from `main`, check that branch:

- `PruneExactness.lean` — f1c5 model-level exactness. `capping_exact` (dead-state pruning is
  exact), `no_live_lumping` + `cap_never_merges_live` (the FH-1 §2 no-further-collapse
  companion), the `OrbitTransfer` section (`orbit_transfer_exact`, `orbit_stabilizer_mult`,
  `stabilizer_weighted_mass` — the orbit-DP transfer and prefix-stabilizer bookkeeping behind
  TR-11 §2/§10(vi)), and the C3 G-channel capping-soundness theorems (`g_prune_sound`,
  `g_prune_exact`).
- `PruneGInvariance.lean` — G-invariance of the prune predicate.
- `RecordConvention.lean` — record/orientation convention lemmas.

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
a pre-registered F4' population functional that measured CONSTANT before being proved ([reports/TR6](../reports/TR6_PARITY_SKELETON.md),
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

## Tier 3 (2026-07-11): PartitionInvariance.lean — model-level merge/partition invariance

Formalizes the mathematical core of
[PARTITION_INVARIANCE.md](../documentation/PARTITION_INVARIANCE.md): the canonical merge modeled as
`dedupKeyFirst ∘ sortLe` (sort by the two-tier comparator, keep the first record of each canonical
class) under the four `MergeOrder` hypotheses. Core Lean 4 only, standalone file, zero `sorry`;
`native_decide` carries only the §12 sanity witnesses — the theorems are structural. Verified
statements:

| Theorem | Statement |
|---|---|
| `merge_perm` (T1) | The merge is a function of the input multiset: shard/readdir order and choice of (correct) sort algorithm are irrelevant |
| `merge_spec` (T2) | The output is sorted, one record per canonical class, each retained record the byte-least member of its class, every input class represented — SOLUTIONS_FORMAT.md's dedup semantics as a theorem |
| `partition_invariance` (T3) + `cross_depth_invariance` | ANY two partitions of a duplicate-free solution listing into cells merge identically — including take-d prefix cells at any two depths (the cross-depth exhaustion conjecture of PARTITION_INVARIANCE.md §4, at the model level) |
| `merge_map_merge_flatten` (T4 family) | Dedup placement irrelevance: pre-merging at any interior node of any merge hierarchy leaves the root output unchanged |
| `grouping_invariance` (T5) | The same per-cell shard family, regrouped/reordered into invocations arbitrarily, merges identically (the empirically-validated 1-invocation-vs-56-invocations headline) |
| `dedupAdjacent_eq` | Code-faithfulness bridge: the pipeline's collapse-adjacent-equal-key-runs pass equals `dedupKeyFirst` on sorted input |
| `recMergeOrder` | The real comparator/key pair (two-tier `compare_solutions` order, `& 0xFC` mask) satisfies all four `MergeOrder` hypotheses |

**Scope — read this before citing (model-level result).** What is machine-proven is the abstract
merge MODEL: order-, partition-, grouping-, and hierarchy-invariance of `dedupKeyFirst ∘ sortLe`.
The connection between that model and the actual C enumerator (`solve.c`) runs through four stated
bridge facts B1–B4 (per-cell exhaustive completeness, shard union semantics, min-selection at every
dedup site, serialization determinism) — explicit modeling assumptions, cited in the file header by
function name, that are **NOT themselves machine-checked**. Nothing here proves the C pipeline or
`solve.c` correct. The end-to-end evidence for the pipeline remains the empirical cross-hardware /
cross-mode / cross-depth sha-reproduction record (PARTITION_INVARIANCE.md §5a); this file and that
record are complements, not substitutes.

## TrigramTheorems.lean (2026-07-11): trigram-level structure

Formalizes the trigram layer of the constraint system — prose companion with the full scope and
attribution discussion in [TRIGRAM_STRUCTURE.md](../documentation/TRIGRAM_STRUCTURE.md) (**read its
scope notes before citing anything below**, in particular the distinction from
[Hershock 1991](../documentation/CITATIONS.md#hershock1991)'s hexagram-set group). Core Lean 4 only,
standalone file, zero `sorry`; every statement was verified numerically in Python before drafting
(`python3 solve.py --trigram-verify` re-runs the two-language check). Finite facts use
`decide`/`native_decide` (the trust-base note above applies — this file's group facts lean on
`native_decide`); the TG-2 sequence-level theorems are structural proofs over EVERY valid ordering.
Verified statements, by family:

| Family | Theorems | One-line honest scope |
|---|---|---|
| **TG-1** trigram factorization | `rev6_trigram_factor`, `comp6_trigram_componentwise`, `ham_trigram_split`, `symmetric_iff_trigram`, `pure_hexagrams_explicit`, `pure_pairs_explicit`, … | Classical facts, formalized ([Goldenberg 1975](../documentation/CITATIONS.md#goldenberg1975) ambient; pure-pair placement Lai Zhide / Wu Deng) — nothing claimed as a discovery; the contribution is the kernel-checked lemma layer |
| **TG-2** forced boundary budget | `within_multiset_general`, **`boundary_budget_general`** (lead), `ninth_six_trigram`, `single_line_carry`, `c2_trigram_reading`, `pangtong_successor`, `flanking_exclusion` | The project's fourth sequence-level theorem: in EVERY C1+C5-valid ordering the 31 between-pair distances form exactly {1:2, 2:8, 3:13, 4:7, 6:1} — so the "9th six" ([McKenna & McKenna 1975](../documentation/CITATIONS.md#mckenna-mckenna1975)'s observation, credited) is forced, exactly once, in every valid ordering |
| **TG-3** trigram-compatible symmetry subgroup | `G12_length`, `G6_length`, `G12_decomposition_covers`/`_nodup`, `mirrorDouble_hom`/`_inj`, `blockPreserving_iff_blockwise`, `uChange_mapP`, `lChange_mapP`, `trigram_functional_not_orbit_invariant` | About the TR-5 **line-position** constraint-symmetry group G₄₈ ONLY (exactly 12 of 48 respect the trigram bipartition, ≅ S₃ × C₂; order 6 at record level) — a different group and object from Hershock 1991's complement/reverse/trigram-swap group on the hexagram set; see TRIGRAM_STRUCTURE.md §"What TG-3 is not" |
| **TG-4** nuclear naturality | `nuc_comm_rev`, `nuc_comm_comp`, `nuc_partner_descent`, `nuc_image_16`, `nuc_nuc_image_terminal`, `nuc_terminal_closed` | Presumably classical/implicit facts (the 64→16→4 chain is commentary-tradition), formalized to certify the nuclear-battery substrate; no discovery claimed, corrections invited |
| **TG-5** vacuity guards | `trigram_balance_invariant`, `pure_pairslot_couple`, `pure_pairslot_count` | Guards, not results: trigram balance holds in ANY permutation (so it says nothing about King Wen), and pure-hexagram adjacency is forced by C1, not a design choice |

## The C1∩C4 null G-law (2026-07-24): C3Decomposition.lean final section

The exact finite probability law of the couple slot-distance sum G = `c3slot` under the C1∩C4
null (all 31! orderings of the 31 free pair-slots, slot 0 pinned by C4; orientations are
irrelevant by `slot_orientation_free`), machine-checked by the Lean **kernel** end to end —
`decide +kernel` only, **no `native_decide` anywhere in the section**, so nothing here trusts
the compiler. The 31-layer DP (the same recurrence as `verify.py --check-null-g`) is restated
over Nat-histograms and evaluated inside the kernel. Verified statements:

| Theorem | Statement |
|---|---|
| `nullHist_matches_brute_2_1_5` / `_2_3_7` / `_3_1_7` | The generic DP recurrence equals brute-force enumeration over ALL orderings of distinct pair tokens at small sizes (120 / 5040 / 5040 orderings enumerated in-kernel) — the recurrence itself is validated, not assumed |
| `null_law` | The 12-couple/7-self/31-slot histogram equals an explicit 217-bin literal: the entire law, bin by bin |
| `null_terminal_closed`, `null_total` | The DP terminates with every couple closed and total mass exactly 31! |
| `null_support_below_12`, `null_support_min`, `null_support_max`, `null_support_bins`, `null_support_contiguous` | Support exactly [12, 228], contiguous, with closed-form endpoint counts 19!·2¹² and (12!)²·2¹²·7! |
| `null_mean_128`, `null_c3_mean_1040` | E[G] = 128 exactly, hence E[C3] = 16 + 8·128 = 1040 via `c3_slot_decomposition` |
| `sum_absdiff_31`, `null_mean_linearity` | DP-free cross-check: the linearity closed form 12·E\|i−j\| = 12·(9920/930) = 128 |
| `null_mass_le_95`, `null_p_le_95`, `null_p_le_95_lowest_terms` | P(G ≤ 95) = 641983711307479/7919632354008375 exactly (≈ 8.106231%), in lowest terms, with the ≤95 mass as an exact integer — 95 is King Wen's own slot-distance sum (`kw_slot_sum_95`) |

**Scope / trust note.** What is kernel-checked is the law of the DP-defined distribution and its
agreement with brute-force enumeration at small parameters; the single modeling step — reading
the C1∩C4 null as "uniform over the 31! free pair-orders" — is stated in the file header and is
the same reading `verify.py --check-null-g` implements independently (with a differently-phrased
G accumulator). This is the C1∩C4 null ONLY — no C2, no C5, no budget truncation; it is not
comparable like-for-like to ceiling-tie shares measured over C2/C5-conditioned enumerated
populations (same scope warning `verify.py` prints).
