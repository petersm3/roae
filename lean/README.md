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
- **The symmetry theorem's bit-permutation layer is fully machine-checked** (finite component + the
  sequence-level layer in
  `Automorphism.lean`): the constraint system has exactly 48 **bit-permutation** symmetries, they act
  freely
  at the record level in 24-element orbits, and therefore **24 divides every exact solution count**.
  This is the theorem behind the "divisible by 24" sanity gate applied to the project's exact counts;
  if a count ever failed that gate, the computation — not the mathematics — would be at fault.
  (Completeness over all 64! hexagram relabelings — that NO permutation of the hexagram set outside
  these 48 preserves the predicate family — is prose-proven with machine-checked finite parts,
  not machine-checked end to end: see TR-5 §3 and `SymmetryCompleteness.lean`'s header. Wording
  qualified 2026-07-26; an earlier version of this bullet said "exactly 48 relabeling symmetries …
  fully machine-checked" without the scope qualifier.)
- **The complement Z₂ symmetry is machine-checked, kernel-only** (2026-07-26, `KingWen.lean` final
  section): global complementation (x ↦ x ⊕ 63) is an exact symmetry of C1∩C2∩C3∩C5, broken only by
  the oriented form of C4 — so the opening orientation is definitional, not forced (this is the
  corrected replacement for the retracted "Theorem 6"; see CLAIMS_DECIDED's corrections ledger).
- **The merge's reproducibility mathematics is machine-checked at the model level**
  (`PartitionInvariance.lean`): the abstract merge model is proven invariant to input order,
  partition choice, invocation grouping, and merge hierarchy. Its connection to the actual C
  enumerator runs through stated bridge facts that are NOT machine-checked — this is a model-level
  result, not a proof of the C code; see the Tier 3 section's scope note.
- **The eight "forced" literature rules are proven, not just measured** (`C1RuleConstants.lean`): the
  eight registry rules that measure at rate 1.0 under enumeration (mmt4, p1c4, s1, s6, r3, r4, r5, c2)
  are **constants of the entire C1 space** — each depends only on the unordered pair-partition, which C1
  fixes, *(scope, 2026-08-01: Lean proves constancy of the **countP forms** defined in that file. Identifying
  those forms with the actual registry rules — `reg_*` in solve.py / `score_registry` in solve.c — is a
  NON-Lean step, numerically validated by driving the repo's own `reg_*` over 5,449 structured C1 sequences
  and disclosed in `C1RuleConstants.lean`'s header. So "proven, not just measured" holds of the Lean
  predicates; for the registry rules themselves it is Lean-proven **modulo a validated transcription** — the
  same runtime-carried bridge disclosed at the claim site for PartitionInvariance and PruneExactness, and it
  belongs here too)*, so no valid ordering can violate them. This upgrades the "empirically forced (sampled)" status
  to a theorem; the zero-hit enumeration measurement is now a corollary. (Orientation-invariance of each
  per-pair predicate is `decide`d over all 64 hexagrams; the fixed range-64 counts by kernel `decide`
  since 2026-07-27 — the whole file is now kernel-only, nothing in it trusts the compiler;
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
  the toolchain is pinned in this directory's `lean-toolchain`; the three exceptions to "seconds"
  are `C3Decomposition.lean`, ~2 minutes, which kernel-evaluates the null-law DP;
  `KingWen.lean`, ~50 s, which kernel-evaluates the equivariance-ceiling witness and the
  complement-symmetry section's kernel-decide facts; and `Automorphism.lean`, several minutes,
  whose five heavy `decide +kernel` obligations were measured at 41–72 s **each** on D16 plus
  ~24 s for §3a's `applyPerm_bit` (see that file's header — list corrected 2026-08-01, which
  previously named only two exceptions)).

In short: the deepest structural claims this project relies on do not depend on trusting us.


`KingWen.lean` contains machine-checked proofs of the ROAE constraint system's finite core lemmas —
**core Lean 4 only, no mathlib**; since 2026-07-27 the file is **kernel-only end to end**: every
finite claim (including the Theorem A trio over all 720 bit permutations) is proved by kernel
`decide`/`decide +kernel`, zero `native_decide` — nothing in the file trusts Lean's compiler.

**Trust-base note (what "machine-checked" means here, precisely).** Lean proofs by `decide` are
verified by Lean's small trusted kernel. Proofs by `native_decide` are NOT kernel-only: they
additionally trust Lean's compiler and native code generator (a strictly larger trusted base, which
has had real soundness bugs historically). **2026-07-27 migration (completed 2026-07-31):** the
finite facts under the suite's headline results were migrated to kernel `decide` — `KingWen.lean`
and `C1RuleConstants.lean` carry **zero** `native_decide` since 2026-07-27, and `Automorphism.lean`
since 2026-07-31 (its last obligation, the composition law `applyPerm_pcomp`, whose direct
48·48·64 kernel `decide` exceeds kernel memory, is now proved structurally in its §3a — see the
file header). So the DIV-24 gate, the equivariance
ceiling, the Theorem A trio, the TG-2 boundary-budget family, and the eight literature-rule
constants are kernel-only end to end (`#print axioms` ⊆ `[propext, Classical.choice, Quot.sound]`
— Lean's standard axioms; the compiler-trust axiom `Lean.ofReduceBool` no longer appears in any of
these chains, and the finite facts report `[propext]` alone). `native_decide`
remains only in: `TrigramTheorems.lean` §4a–§6 (the TG-3/TG-4/TG-5 finite subgroup facts and the
§6 sanity instances at King Wen — the TG-2 lead theorems themselves are kernel-only),
`PartitionInvariance.lean` §12 (sanity witnesses, disclosed there), `PruneGInvariance.lean` §1 (`applyPerm_isometry`) and its §8 sanity examples, and `SymmetryCompleteness.lean`
(SC1–SC4/SC7 — the T7 completeness kernels). The structural sequence-level theorems
(`wrap_parity_general`, `alternations_15_general`, the T1–T5 merge theorems in
`PartitionInvariance.lean`, …) are ordinary structural proofs checked by the kernel.

Verified statements:

| Theorem | Statement |
|---|---|
| `within_pair_even_nonzero` | Theorem 1: within-pair Hamming distance is even and nonzero for all 64 hexagrams |
| `xor_universality` + `xor_all_seven_attained` | Theorem 2: XOR products {h ⊕ partner(h)} = exactly {12, 18, 30, 33, 45, 51, 63} |
| `partner_preserves_parity`, `parity_split_32_32`, `xor_parity_identity` | The lemmas of the parity-alternation theorem ([PARITY_ALTERNATION.md](../documentation/PARITY_ALTERNATION.md)) |
| `kw_valid`, `kw_c3_exactly_776`, `kw_no_five`, `kw_alternations_15` | King Wen satisfies C1/C4/C5 (hence C2), has complement-distance sum exactly 776, and exactly 15 parity-class alternations |
| `sigma_kw_valid_48`, `valid_iff_centralizes_rev`, `twins_24_records` | The finite component of the symmetry theorem ([SYMMETRY_SEARCH.md](../documentation/SYMMETRY_SEARCH.md)): exactly 48 of the 720 bit permutations map KW to a valid sequence — **exactly** the centralizer of reversal — collapsing to 24 record-level twins |
| `comp_symmetry_c1_c2_c3_c5`, `c4ok_breaks_under_comp`, `orientation_not_forced` (+ `compSeq_involution`, `c1ok_compSeq`, `c5ok_compSeq`, `c3x64_compSeq`, `kw_valid_kernel`, `kw_c3_776_kernel`) | The complement Z₂ symmetry (2026-07-26, kernel-only — see the section below): comp is an exact symmetry of C1∩C2∩C3∩C5; only oriented C4 breaks it; comp∘KW opens (0, 63) with C3 = 776 — the corrected replacement for the retracted "Theorem 6" |

The sequence-level theorems (wrap parity, the full 15-alternation theorem over all valid orderings,
the symmetry theorem over the full solution set) follow from these lemmas by the short telescoping /
linearity arguments in the corresponding documentation — the machine-checked layer pins down every
finite computation those arguments rest on.

## Verify yourself

```bash
# install elan (Lean version manager); the pinned toolchain is in ./lean-toolchain
# (leanprover/lean4:v4.31.0). Each file is standalone; no lake project:
lean KingWen.lean            # silence = all theorems check (Lean 4, tested with 4.31.0; ~50 s — kernel-evaluates the equivariance-ceiling witness + the complement-symmetry facts)
lean C3Decomposition.lean    # C3 slot-decomposition theorem + the exact C1∩C4 null G-law (see below; ~2 min — kernel-evaluates a 31-layer DP)
lean PruneSafety.lean        # v4 walk-level prune-safety lemma (isomorph-free generation soundness)
lean Automorphism.lean       # the sequence-level symmetry layer (see below)
lean PartitionInvariance.lean  # tier-3 model-level merge/partition-invariance theorems (see below)
lean TrigramTheorems.lean    # trigram-level structure: forced boundary budget, S3xC2 subgroup (see below)
lean SymmetryCompleteness.lean  # TR-5 v2.0 completeness kernel: psi iso, Q6 rigidity, partner-commuters = G48 (2026-07-18)
lean C1RuleConstants.lean    # the eight "forced-1.0" literature rules (mmt4,p1c4,s1,s6,r3,r4,r5,c2) are constants of the C1 space (2026-07-21)
lean HammingOptimalMatching.lean  # C1 is THE unique Hamming-cost-minimizing comp/rev matching (Radisic 2026, re-derived in-repo; kernel-only decide) (2026-07-26)
```

**The prune-exactness proof layer (vendored into this tree 2026-08-01).** Three Lean files
originating on the `v4-canonical` branch (they concern the v4 compiler / f1c5 layer) are now
**included here** so the artifact is self-auditable — each is standalone core Lean 4 (zero imports,
zero `sorry`/`axiom`/`admit`) and checks with `lean <file>` like the others:

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
symmetry group verified here). His artifact was independently rebuilt and audited by this project, and
the optimality theorem is now also machine-checked in-repo — see
§"HammingOptimalMatching.lean" below and CITATIONS.md.

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
solution count. Core Lean 4 only, standalone file, structural proofs over ALL orderings; since
2026-07-31 the file carries **zero** `native_decide` — the finite group facts are kernel `decide`
and the composition law is proved structurally (§3a; see the trust-base note above). Verified
statements:

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
`decide`/`native_decide` (the trust-base note above applies — the §4a–§6 finite facts, i.e. the
TG-3/TG-4/TG-5 subgroup facts and the §6 sanity instances, lean on
`native_decide`); the TG-2 sequence-level theorems are structural proofs over EVERY valid ordering.
**TG-2 trust-base note (updated 2026-07-27; original disclosure 2026-07-26):** the finite
`pairdist_count_0..6` lemmas, the three TG-1 counts, and `selfcomp_pair_count` are now kernel
`decide` (migrated from `native_decide`), so the TG-2 leads `boundary_budget_general` /
`ninth_six_trigram` / `single_line_carry` — and `within_multiset_general` — are **kernel-only**
(`#print axioms` = `[propext, Classical.choice, Quot.sound]`, Lean's standard axioms — the
`native_decide` compiler-trust axiom is gone): all four of the suite's sequence-level theorem
families now share the kernel-only trust base. The TG-3/TG-4/TG-5 finite subgroup facts and the
§6 sanity instances (§4a–§6)
remain `native_decide`.
Verified statements, by family:

| Family | Theorems | One-line honest scope |
|---|---|---|
| **TG-1** trigram factorization | `rev6_trigram_factor`, `comp6_trigram_componentwise`, `ham_trigram_split`, `symmetric_iff_trigram`, `pure_hexagrams_explicit`, `pure_pairs_explicit`, … | Classical facts, formalized ([Goldenberg 1975](../documentation/CITATIONS.md#goldenberg1975) ambient; pure-pair placement Lai Zhide / Wu Deng) — nothing claimed as a discovery; the contribution is the machine-checked lemma layer (the three TG-1 counts — `symmetric_count_8`, `antisymmetric_count_8`, `pure_hexagrams_explicit` — are kernel `decide` since 2026-07-27, migrated from `native_decide`; the 2026-07-26 label correction is thereby resolved in the strong direction) |
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

## HammingOptimalMatching.lean (2026-07-26): C1 is THE unique optimal comp/rev matching

The first-principles optimality of the C1 pairing — previously resting on an external unrefereed
preprint ([Radisic 2026](../documentation/CITATIONS.md#radisic2026), arXiv:2601.07175) — is now
machine-checked **in-repo**. The mathematical result is Radisic's; this file is an independent
re-derivation in this repo's own encoding (core Lean 4, no mathlib, standalone file, the same
`partner` definition as `KingWen.lean` / solve.c's `partner()`), written after his proof was read
and his artifact independently rebuilt. Verified statements:

| Theorem | Statement |
|---|---|
| `partner_is_unique_minimum` (MAIN) | Every pairing of the 64 hexagrams in which each hexagram goes to its complement or reversal (never itself) has total endpoint Hamming cost ≥ 240 (= 2 × 120 per-pair), and any pairing attaining 240 equals `partner` at every hexagram — the C1 rule is THE unique Hamming-cost-minimizing comp/rev matching |
| `partner_involution`, `partner_cost_240`, `comp_only_cost_384` | The optimum is a genuine fixed-point-free involution attaining 240; the complement-only matching costs 384 (= 2 × 192) |
| `kw_realizes_partner` | King Wen realizes exactly this matching: all 32 pairs satisfy KW[2k+1] = partner(KW[2k]), within-pair distances summing to the optimal 120 |
| `full_k4_can_do_192` | SCOPE GUARD: over the full Klein group the bound fails — an explicit involution using comp∘rev achieves 192 endpoint (= 2 × 96 < 2 × 120). The optimality claim is comp/rev-scoped, exactly as SPECIFICATION.md states it |

**Trust base: kernel-only.** Every finite fact in this file is proved by plain `decide` — **no
`native_decide` anywhere**; `#print axioms` on all five headline theorems reports `[propext]` only.
This is a strictly smaller trusted base than Radisic's own artifact (whose weight-conservation /
robustness layers use `native_decide`) and than most files in this directory.

**Independent verification record for Radisic's original artifact (2026-07-26).** Before this
adaptation was written, Radisic's Lean 4 + Mathlib source (the arXiv ancillary files of
2601.07175v3) was rebuilt from source on a clean Ubuntu 24.04 VM: pinned toolchain
`leanprover/lean4:v4.30.0-rc2`, mathlib pinned by `lake-manifest.json` (rev `5450b53e…`);
`lake build` exits 0 with zero warnings on all 13 `IChing/*` modules; zero `sorry`/`admit` and zero
axiom declarations in the source; `#print axioms` on his 13 main theorems reports the standard
`[propext, Classical.choice, Quot.sound]` plus, for the weight-conservation/robustness layers only,
the expected `native_decide` axioms (compiler-trusting). Two findings from the audit, for the
record: (i) the ancillary is missing `IChing/MultiOrthantManifold.lean`, which the root
`IChing.lean` imports — the lakefile's `.submodules` glob excludes the root module so `lake build`
is unaffected, but the root file itself does not elaborate; (ii) his repo-facing uniqueness theorem
(`reversePriority_unique`) is rule-level, with the matching-level cost-uniqueness assembled in the
paper's prose from his per-element lemmas (`priorityPartner_minimizes_distance`,
`weight_three_rev_beats_cr`, …) — `HammingOptimalMatching.lean` closes that assembly formally
(`partner_is_unique_minimum` quantifies over ALL comp/rev pairings). Neither finding affects the
correctness of his result; both are documented so the claim's provenance is exact.

## The equivariance ceiling (2026-07-26): KingWen.lean final section

The "agnostic generator" corollary of the symmetry theorem, machine-checked: any generator whose
scoring/decision function is built purely from G-invariant bit-structural primitives (Hamming
distance, popcount, complement, reversal, the distinguished values 0/63, slot indices, and
aggregates thereof) induces an output distribution taking equal values on King Wen's record and
each of its 23 record-level twins — so the best such a generator can do is spread mass uniformly
over KW's 24-element record orbit, never concentrate it on KW alone. Masses are unnormalized Nat
weights (clear denominators of any rational-probability — in particular any computable —
generator); `total` is the scaled total mass. Verified statements:

| Theorem | Statement |
|---|---|
| `mass_of_invariant_score` | Fully general (any action, any score, any mass): a mass assignment factoring through a G-invariant score is itself G-invariant — the "invariant vocabulary ⇒ equivariant generator" step; **axiom-free** |
| `mass_const_on_kwOrbit` | Under an orbit-invariant score, every record in KW's orbit receives the same mass as KW's record — equal probability on KW and each of its 23 twins |
| `kwOrbit_mass_eq` | Orbit-mass identity: the orbit's total mass is EXACTLY 24 × the mass on KW's record |
| `equivariance_ceiling` | THE CEILING: `24 * mass(KW-record) ≤ total`, i.e. P(KW-record) ≤ 1/24 — concentration on KW's singleton is impossible |
| `no_unique_kw_concentration` | Corollary: a G-invariantly-scored generator putting ALL its mass on KW's record has total mass zero |
| `kwOrbit_length`, `kwOrbit_nodup`, `kw_record_mem_kwOrbit` | The orbit has exactly 24 pairwise-distinct records (length REUSES `twins_24_records` verbatim — the ceiling is a genuine corollary of the existing free-action finite component, not a re-proof) and contains KW's own record |
| `popcount_profile_const_on_kw_images` | Inhabitation witness: a real record-level invariant-primitive score (per-slot pair-popcount profile) satisfies the invariance hypothesis exactly — kernel-checked (`decide +kernel`, no compiler trust) |

**Trust base (`#print axioms`; updated 2026-07-27, previously recorded 2026-07-26).**
`mass_of_invariant_score`: no axioms. Structural lemmas (`nodup_eraseDups`, `sum_map_const`,
`mass_const_on_kwOrbit`): `[propext, Quot.sound]` — kernel-only.
`popcount_profile_const_on_kw_images`: `[propext]` — kernel-only. Since the 2026-07-27
K-migration, `twins_24_records` and `kw_valid` are themselves kernel `decide`, so the ENTIRE
ceiling chain (`kwOrbit_length`, `kwOrbit_mass_eq`, `equivariance_ceiling`,
`no_unique_kw_concentration`, `kw_record_mem_kwOrbit`) is **kernel-only** — the compiler-trusting
finite component this chain previously inherited no longer exists.

**Scope.** This is a statement about generators whose decision functions factor through
G-invariant scores at the record level — the hypothesis `hconst` is G-invariance instantiated at
KW's orbit. It does not (and cannot) rule out generators using non-G-invariant vocabulary:
lexicographic/numeric label conventions or KW-derived constants break the ceiling by
construction, which is precisely the point — unique-KW output requires smuggled labels or
KW-specific data.

**Novelty status.** The mathematical content is the standard invariance/orbit argument — an
invariant score induces an output distribution constant on each orbit, so no such generator can
concentrate on a single orbit element (P ≤ 1/|orbit|). This is Curie's principle (1894), worked
out explicitly in the equivariant-model symmetry-breaking literature — e.g. Smidt et al.,
*Phys. Rev. Research* 3, L012002 (2021); "Symmetry Breaking and Equivariant Neural Networks"
(arXiv:2312.09016); "Improving Equivariant Networks with Probabilistic Symmetry Breaking"
(arXiv:2503.21985) — with the Burnside/orbit machinery already cited in CITATIONS.md. No novelty
is claimed for the argument. What is possibly new, to our knowledge, is only its instantiation
for the King Wen constraint-symmetry group at the record level (the 1/24 constant riding on
`twins_24_records`) and the machine-checked formalization. Corrections welcome — see
CITATIONS.md.

## The complement Z₂ symmetry (2026-07-26): KingWen.lean final section

The corrected replacement for the retracted "Theorem 6 (forced orientation)" (see
[CLAIMS_DECIDED.md](../documentation/CLAIMS_DECIDED.md)'s corrections ledger and
[SPECIFICATION.md](../documentation/SPECIFICATION.md) §Theorems): global complementation
comp : x ↦ x ⊕ 63, applied to every hexagram of a sequence, is an **exact symmetry of
C1 ∩ C2 ∩ C3 ∩ C5**, and an involution; only the **oriented** form of C4 breaks it. In particular
comp∘KW opens (0, 63) — the reversed orientation — and satisfies C1, C5 (hence C2), and C3 with
the sum at exactly 776: the opening orientation is a free Z₂ of the pair-only system, fixed in C4
by definition (classically attested, Xugua Heaven-then-Earth), not by mathematics. Verified
statements:

| Theorem | Statement |
|---|---|
| `c1ok_compSeq` | comp preserves C1 exactly (partner commutes with complement — `partner_comp_comm63`) |
| `c5ok_compSeq` (via `transitions_compSeq`) | comp preserves the transition-distance list, hence C5 and its C2 clauses exactly (Hamming isometry) |
| `c3x64_compSeq`, `c3ok_compSeq` | comp preserves the x64 complement-distance sum exactly (each term is max/min-symmetric in its two position lookups) |
| `comp_symmetry_c1_c2_c3_c5` | THE SYMMETRY: for every 64-element 6-bit sequence, comp∘l satisfies each of C1/C5/C3 iff l does |
| `c4ok_breaks_under_comp` | The one break: any sequence opening at 63 opens at 0 after comp — oriented C4 is what excludes comp, and nothing else is |
| `compSeq_involution` | comp∘comp = id on bounded sequences: a genuine Z₂ action, exchanging the two opening orientations bijectively on the C1∩C2∩C3∩C5 solution set |
| `orientation_not_forced` | The corollary at King Wen: comp∘KW opens (0, 63), satisfies C1/C5/C3 with C3 = 776 exactly, fails oriented C4 — the retracted claim's counterexample, machine-checked |
| `kw_valid_kernel`, `kw_c3_776_kernel` | Kernel-decide re-statements of `kw_valid` / `kw_c3_exactly_776`, so the corollary is kernel-only end to end |

**Trust base (`#print axioms`, recorded 2026-07-26): kernel-only throughout — no
`native_decide`.** `comp_symmetry_c1_c2_c3_c5`, `orientation_not_forced`, `c1ok_compSeq`,
`c3x64_compSeq`, `c4ok_breaks_under_comp`: `[propext, Quot.sound]`. `c5ok_compSeq`,
`compSeq_involution`, `kw_valid_kernel`, `kw_c3_776_kernel`: `[propext]`. The finite lemmas are
plain `decide` (64- and 4096-case) and the KW instances `decide +kernel`; the sequence-level
lemmas are structural inductions. This section adds nothing to the file's trusted base.
