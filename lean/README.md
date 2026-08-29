# Machine-checked proofs (Lean 4)

## Executive summary (plain English)

This directory contains **machine-checked mathematical proofs**. Instead of trusting a human
argument (or this project's own C and Python code), the Lean 4 proof assistant
([de Moura & Ullrich 2021](../documentation/CITATIONS.md#demoura-ullrich2021), CADE-28) re-derives each
statement from first principles and certifies the logic. Since 2026-08-07 **every proof in this
directory is checked by Lean's small kernel alone** — no proof trusts Lean's compiler (see the
trust-base note below for what that means and how it came to hold). What that buys:

- **The constraint system's basic facts are beyond dispute.** Every hexagram pair's distance
  properties, the exact set of XOR products, the parity structure, and King Wen's satisfaction of
  the constraints are proved by exhaustive computation checked by Lean — not by our software, which
  could have bugs. (See the trust-base note below: `decide` proofs are checked by Lean's small
  kernel alone. Until 2026-08-07 a disclosed subset of finite lemmas was instead proved by
  `native_decide`, which additionally trusts Lean's compiler and native code generator; that
  subset is now empty.)
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
- **The eight "forced" literature rules are proven, not just measured** (they state seven distinct facts: `r3_const` and `p1c4_const` prove the same C1 content — both violation predicates are kernel-decidably false on all 64 hexagrams, `p1c4Viol_r3Viol_false`, so each reduces to `pcount l dualPair = 4`) (`C1RuleConstants.lean`): the
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
  each standalone file re-verifies from scratch with `lean <File>.lean` (the toolchain is pinned in
  this directory's `lean-toolchain`). Verification cost is real and is stated here honestly,
  because until 2026-08-07 this bullet claimed each file checks "in seconds **on any machine**"
  with three time exceptions and **no memory exceptions** — and that was false at every revision
  since the kernel migrations landed: kernel evaluation of the heavy finite obligations is
  memory-hungry, peaking at **~9.6 GB resident for `Automorphism.lean` and ~7.9 GB for
  `KingWen.lean`**, so an 8 GB machine cannot verify those two files at all (this is the price of
  their kernel-only trust base, independent of anything else in the tree). Half the files check in
  about a second at under 0.7 GB; the expensive ones are `Automorphism.lean` (~4 min, ~9.6 GB),
  `KingWen.lean` (~2 min, ~8.0 GB), `C3Decomposition.lean` (~1¼ min, ~4.7 GB, the null-law DP),
  `PruneGInvariance.lean` (~1½ min, ~4.1 GB), and — since their 2026-08-07 kernel migration —
  `TrigramTheorems.lean` (~2 min, ~4.8 GB) and `SymmetryCompleteness.lean` (~23 s, ~2.8 GB).

  🔴 **RSS is not the only limit, and the other one is not fixed by a bigger machine (added
  2026-08-28, Q-347).** An **address-space** cap — `ulimit -v`, which containers and CI images
  commonly set — starves Lean's thread-stack reservation long before RSS approaches anything in
  the table above. It surfaces as `lean::exception: failed to create thread`, **not** as an
  allocator error. Measured on a 4 GB `-v`-capped host: all 13 modules failed at **~480 MB RSS**,
  i.e. at 5% of the figure this table would have you provision for. Buying a larger host does
  nothing. **Try this first — it is free:**

  ```sh
  LEAN_NUM_THREADS=1 lake env lean <file>.lean    # or: lean --threads=1 <file>.lean
  ```

  On that same capped host it kernel-verified `C1RuleConstants.lean` and `PruneSafety.lean`. The
  RSS table below governs case (a), genuine memory; this paragraph governs case (b). Check which
  one you hit before provisioning.
  ⚠ **These figures were REVISED UPWARD on 2026-08-21** after a full 13-module re-measurement on a
  Standard_D128als_v7 (`/usr/bin/time -v`, one module at a time on an otherwise-idle box, same
  pinned toolchain). The previous table under-stated four rows — `TrigramTheorems` by **8.9%**
  (4.4 → 4.79), `C3Decomposition` by 4.4%, `PruneGInvariance` by 5.6%, `KingWen` by 1.8%. Sizing a
  host from the old numbers could OOM. Provision headroom above these, not to them.
  Full measured per-file table and host guidance in §"Verify yourself" below — read it before
  running the suite on a small machine.

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
these chains, and the finite facts report `[propext]` alone). After that migration,
`native_decide` remained only in: `TrigramTheorems.lean` §4a–§6 (the TG-3/TG-4/TG-5 finite
subgroup facts and the §6 sanity instances at King Wen — the TG-2 lead theorems themselves are
kernel-only) and `SymmetryCompleteness.lean` (SC1–SC4/SC7 — the T7 completeness kernels).
**2026-08-07 (second migration tranche):** `PruneGInvariance.lean` is now kernel-only end to
end — `applyPerm_isometry`, formerly the suite's one remaining *load-bearing* `native_decide`
(its direct 48×64×64 kernel enumeration was measured out of reach), is now an instantiation of
a structural general lemma (§0b `applyPerm_isometry_perm`: ANY permutation of bit positions is
an isometry of the Hamming metric — classical coding-theory content, no novelty claimed), and
its §8 sanity examples are `decide +kernel`. `PartitionInvariance.lean` likewise carries zero
`native_decide` (§12's sanity witnesses migrated to `decide +kernel`); moreover, a stronger
fact that held at every earlier revision too: all of §12's former `native_decide` uses were
anonymous `example`s, which never enter the environment — so that file's EXPORTED theorem
surface (everything `#print axioms` can be asked about) was kernel-only even before the
migration. The two files still carrying `native_decide` were deliberately NOT migrated:
kernel-decide versions were built and measured (D16, Lean 4.31.0) at **11.5 GB peak RSS for
`TrigramTheorems.lean` and 13.7 GB for `SymmetryCompleteness.lean`** — dominated by one
obligation each (`blockPreserving_iff_blockwise`, `psi_comm_perms`, both 720-permutation
enumerations) — and publishing a corpus that needs a ~16 GB host to verify was judged worse
than the disclosed compiler trust; they stayed on `native_decide` pending structural reproofs of
those two obligations, which landed the same week (next paragraph).
**2026-08-07 (third and final tranche — the corpus is now kernel-only).** The two pending
structural reproofs landed, with both theorem statements kept verbatim:
`SymmetryCompleteness.psi_comm_perms` is now proved pointwise — popcount preservation under bit
relocation (applyPerm p moves bit i to position p[i], so the popcount sum reindexes along p)
plus commutation of the 6-bit complement with applyPerm via `Nat.eq_of_testBit_eq` — reporting
axioms `[propext, Quot.sound]`; and `TrigramTheorems.blockPreserving_iff_blockwise` is proved by
destructuring the permutation to a closed bit-scatter form (carry bounds + `omega` on the
concretized branches forward; explicit single-bit counterexamples reverse), reporting
`[propext, Classical.choice, Quot.sound]`. Every other former `native_decide` site in those two
files migrated to `decide +kernel` (kernel-evaluated, no compiler trust). **Zero `native_decide`
now remains anywhere in the thirteen files: every theorem in this directory is checked by Lean's
kernel alone, with `#print axioms` ⊆ `[propext, Classical.choice, Quot.sound]` — Lean's standard
axioms — suite-wide.** (Thirteen files since 2026-08-15: `PruneReprFC.lean` landed kernel-only —
zero `native_decide`, its in-file `#print axioms` directives execute on every build and report
⊆ the same standard set — so the suite-wide claim is unchanged by the addition.)
The scope of that claim, stated precisely so it cannot be over-read: it
is about the *axiom base* — what a reader must trust for these proofs to be sound (Lean's
kernel plus its standard axioms, and no longer Lean's compiler) — not a claim that the
formalized statements exhaust what the prose documents assert; each file's header and scope
notes still govern what its theorems do and do not say. Measured cost of the two reproofs
(Standard_D8als_v7, Lean 4.31.0, 2026-08-07): ~2.8 GB / ~4.4 GB peak RSS — versus the
~13.7 / ~11.5 GB the rejected enumeration route had cost, and below
`Automorphism.lean`'s pre-existing ~9.6 GB suite ceiling, so the migration adds **zero**
hardware cost (see the hardware table below, re-measured on the shipped tree). Structural
reproofs by Claude (Fable 5, AI assistance per the repo's attribution convention), 2026-08-07,
under the standing migration policy. The structural sequence-level theorems
(`wrap_parity_general`, `alternations_15_general`, the T1–T5 merge theorems in
`PartitionInvariance.lean`, …) are ordinary structural proofs checked by the kernel.

**PROVENANCE OF THE AXIOM SETS ABOVE — added 2026-08-02 (hardening item B1), because the
obvious inference from reading this file is wrong.** The `#print axioms` results quoted in
this section were read from **dated full-file builds** (2026-07-26, 07-27 and 07-31; each
dated at its own claim site below). They were **not** produced by the in-file `#print axioms`
directives you will find in the `.lean` sources: those were added on 2026-08-01 (`d3d6772`)
with bare names for constants declared inside `namespace` blocks, so six of twelve files —
`TrigramTheorems`, `C3Decomposition`, `PruneExactness`, `PartitionInvariance`,
`SymmetryCompleteness`, `PruneGInvariance` — failed with "Unknown constant" and the ~89
directives **never executed**. `03c2a05` (2026-08-02) qualified every name; the re-run that
would make those directives a live witness has not been performed yet.
So: nothing in this section rests on the broken directives — a sweep of the markdown corpus
on 2026-08-02 found no published sentence that cites them as its warrant — but nothing in it
is re-confirmed by the directives either. The exposed claim, named rather than left for a
reader to locate, was the exhaustive negative one above — that `native_decide` remained
**only** in those files (a sentence this section carried in the present tense until the
2026-08-07 third tranche retired it). An executed audit is what would establish an *only*.
**EXECUTED 2026-08-07.** That audit has now been run, on the exact shipped tree (D-series
Azure host, Lean 4.31.0): a module-wide scan (`Lean.collectAxioms` over EVERY non-internal
constant of each compiled module, not just the doc-cited names) reports **zero**
compiler-trust axioms in `PartitionInvariance` (99 constants) and `PruneGInvariance`
(111 constants), and exactly **7** and **35** `Lean.ofReduceBool`-bearing constants in
`SymmetryCompleteness` (24 constants) and `TrigramTheorems` (134 constants) respectively —
precisely their documented `native_decide` sites, and nothing else. The same scan on
`C3Decomposition`, `PruneExactness`, `C1RuleConstants`, `KingWen`, `PruneSafety`, and
`RecordConvention` reports zero native hits, and the (fixed, qualified) in-file directives
of `Automorphism` and `HammingOptimalMatching` executed in the same builds report only
standard axioms. So the *only* above is now observed, module-wide, suite-wide — no longer
statically inferred.
**RE-EXECUTED 2026-08-07, same day, on the tranche-2 tree** (the revision where the last two
files migrated): the identical module-wide scan, run on all twelve compiled modules of the
exact shipped tree, reports **zero** `Lean.ofReduceBool`-bearing constants in every module —
906 non-internal constants scanned suite-wide (SymmetryCompleteness 70, up from 24 at its
`native_decide` revision, and TrigramTheorems 158, up from 134 — the growth is the named
structural lemmas; PartitionInvariance and PruneGInvariance unchanged at 99 and 111), **0
native hits anywhere**. A source-level sweep agrees: every `native_decide` token remaining in
the tree sits inside a comment (the historical trust-base notes), none in proof position. The
exhaustive negative is no longer "only in those files" — it is "nowhere".

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
lean PruneReprFC.lean        # SOLVE_REPR_FC prune safety: repr(k) forward-check + leaf-free memo preserve the first-found leaf (2026-08-15; see below)
lean Automorphism.lean       # the sequence-level symmetry layer (see below)
lean PartitionInvariance.lean  # tier-3 model-level merge/partition-invariance theorems (see below)
lean TrigramTheorems.lean    # trigram-level structure: forced boundary budget, S3xC2 subgroup (see below; ~2 min since the 2026-08-07 kernel migration)
lean SymmetryCompleteness.lean  # TR-5 v2.0 completeness kernel: psi iso, Q6 rigidity, partner-commuters = G48 (2026-07-18; ~22 s since the 2026-08-07 kernel migration)
lean C1RuleConstants.lean    # the eight "forced-1.0" literature rules (mmt4,p1c4,s1,s6,r3,r4,r5,c2) are constants of the C1 space (2026-07-21)
lean HammingOptimalMatching.lean  # C1 is THE unique Hamming-cost-minimizing comp/rev matching (Radisic 2026, re-derived in-repo; kernel-only decide) (2026-07-26)
```

**Hardware requirements (measured, 2026-08-07).** Kernel evaluation trades compiler trust for
time and memory, and the memory is the binding constraint: **a host with ~10 GB of free RAM
verifies every file; 16 GB is comfortable; an 8 GB host cannot verify `Automorphism.lean` or
`KingWen.lean` at all** (the two heaviest single `decide +kernel` obligations exceed its
capacity — no flag changes this; the kernel allocates what the term it is checking needs).
Measured per-file cost — wall clock and peak resident set of a single `lean <File>.lean`, on a
16-core / 31 GB Azure Standard_D16als_v7, Lean 4.31.0 pinned via `./lean-toolchain` (the
`TrigramTheorems` and `SymmetryCompleteness` rows re-measured 2026-08-07 on their kernel-only
revisions, on an 8-core / 16 GB Standard_D8als_v7 — same toolchain; RSS is machine-independent
to first order, and two identical single-obligation workloads re-measured on the D8 host
reproduced their D16 figures to within 0.03 GB):

| file | wall | peak RSS |
|---|---|---|
| `Automorphism.lean` | ~4 min | 9.6 GB |
| `KingWen.lean` | ~1 min 54 s | 7.9 GB |
| `C3Decomposition.lean` | ~1 min 13 s | 4.5 GB |
| `TrigramTheorems.lean` | ~1 min 55 s | 4.4 GB |
| `PruneGInvariance.lean` | ~1 min 24 s | 3.9 GB |
| `SymmetryCompleteness.lean` | ~22 s | 2.8 GB |
| `C1RuleConstants.lean` | ~1 s | 0.7 GB |
| the other five (`PartitionInvariance`, `HammingOptimalMatching`, `PruneExactness`, `PruneSafety`, `RecordConvention`) | <1 s each | <0.6 GB each |
| `PruneReprFC.lean` | ~1.5 s | 0.49 GB |

(The `PruneReprFC.lean` row was measured 2026-08-15 on the 2-core `claude`
orchestrator (D2as_v6), Lean 4.31.0, not the D16 host of the other rows —
wall clock is therefore an upper bound relative to the table's baseline; peak
RSS is machine-independent to first order, same as the rest of the table.
That host caps virtual memory at 4 GB, below Lean's default thread-stack
reservation, so the measurement used `lean -j 1 --tstack=65536`; on an
unrestricted host plain `lean PruneReprFC.lean` is the normal invocation.)

**The headline guidance is unchanged by the 2026-08-07 tranche-2 migration** — this was
confirmed against measurement, not assumed: the two files that migrated peak at ~4.4 GB and
~2.8 GB, both well under `Automorphism.lean`'s ~9.6 GB, so the suite's ceiling, the ~10 GB
free-RAM requirement, and the 8 GB exclusions are exactly what they were before the migration.
(Before 2026-08-07 those two files cost ~9 s / 1.4 GB and <1 s / <0.6 GB respectively on their
`native_decide` trust base — the table rows above are the price of removing their compiler
trust, deliberately paid where it stays under the pre-existing ceiling.)

Files verify independently (no imports between them), so partial verification on a small host is
sound: skip the files your RAM cannot hold and every other file's result stands on its own. Wall
time scales with single-core speed; peak RSS is machine-independent to first order. Nothing here
is tunable — the figures are what kernel evaluation of these terms costs.

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
- `PruneGInvariance.lean` — G-invariance of the prune predicate. Kernel-only since 2026-08-07:
  the Hamming-isometry leg (`applyPerm_isometry`) is an instantiation of §0b's structural proof
  that any coordinate permutation is a Hamming isometry (classical content, credited as such),
  not an enumeration; see the trust-base note above.
- `RecordConvention.lean` — record/orientation convention lemmas.

## PruneReprFC.lean (2026-08-15): SOLVE_REPR_FC prune safety — the repr(k) forward-checked DFS

Machine-checks, at the model level, the correctness comment of the `SOLVE_REPR_FC`
forward-checked repr(k) DFS (task #20 option C, branch `v4-repr-fc-legc-20260813` —
the feature is NOT on main at the time of writing; solve.c `orb_recanon_dfs_fc` /
`orb_fc_build` / the epoch-tagged memo table): the exact-consumption forward check
(prune A) and the leaf-free-state memoization (prune C) remove only subtrees
containing NO leaves at all — leaf = slot-np node reached through the budget edges,
valid or not — hence cannot change which valid leaf the first-found DFS returns,
hence preserve repr(k) bit-identically (SOLVE_REPR_FC=0/1 agree). Core Lean 4 only,
standalone file, zero `sorry`, kernel-only (`#print axioms` on all headline theorems
⊆ `[propext, Classical.choice, Quot.sound]`, printed on every build by the in-file
directives). Verified statements:

| Theorem | Statement |
|---|---|
| `leavesPr_eq` (strong form) + `prune_first_leaf_exact` (headline) | The general reusable lemma: for a DFS over a finitely-branching depth-indexed tree in fixed child order, a prune firing only on provably leaf-free subtrees leaves the ENTIRE ordered leaf stream unchanged — a fortiori the first leaf satisfying any predicate |
| `dfs_eq_find?` | Operational = denotational: the first-found early-exit DFS returns exactly `find?` over the ordered leaf stream |
| `fcCheck_leaf_free` | Prune A is leaf-free-SOUND: in the budgeted model, budget outside [suffix-min, suffix-max] of per-edge class-consumption bounds + the exact-consumption sum guard ⇒ the subtree has no leaf at all (feasibility would force cost = budget pointwise, the F-53-style le+eqsum⇒eq collapse); the suffix tables are DERIVED from per-edge bounds by orb_fc_build's own recurrence (`acc`, via `costs_bounded`/`costs_sum`), not assumed wholesale |
| `dfsM_spec` / `dfsM_eq_unpruned` | Prune C is sound given the above: the memo-threaded first-found DFS (probe before descend; insert only on zero-leaf subtree completion; any leaf-free-sound prune A inside) returns exactly the unpruned first valid leaf from any all-claims-true memo, preserves that invariant, and counts unpruned leaves exactly when nothing is found |
| `leaves_nil_congr` | The projection leg: leaf-freeness transfers between states with equal memo keys when the tree structure factors through the key projection — why a (slot, tail, budget) key is sound for states differing only in the placed sequence |
| `epochMemo` + `etBump_claims_empty` (and `listMemo`) | The memo contract is inhabited by an epoch-tagged bucket table under EVERY collision/placement policy (overwrite or drop — "costs time, never correctness"), and a bumped epoch claims nothing when stored tags are bounded by the old epoch — stale positives cannot resurrect (solve.c's uint32 wrap-clear restores the bound; bridge B9) |
| `fc_memo_first_leaf_exact` | THE CONCLUSION: FC-check + memo composed over the budgeted tree return exactly the unpruned search's leaf, for every key, budget, and leaf test — with RecordConvention.lean §3 (B6) this is "repr(k) preserved bit-identically" |
| `liftSpend_proj` | Witness: the path-blind spend shape (transition arithmetic reads only slot + tail, the placed sequence is payload — the solve.c shape) discharges the projection hypothesis with nothing assumed about paths |
| §5 counterexample suite | THE COMPOSITION HAZARD IS REAL (the C comment's CAUTION, machine-checked): a concrete cd-style prune is answer-sound alone (`find?`-equal, streams differ) yet NOT leaf-free-sound, and composed with the memo it poisons an entry and the search returns `none` where the unpruned answer exists — hypothesis hA is load-bearing, and "no leaf reached" must mean "leaf-free" |

**Scope — read this before citing (model-level result).** What is machine-proven is
the abstract statement about the model DFS. The connection to the shipped binary
runs through stated bridge facts B8–B11 (DFS-shape faithfulness, memo-table
contract incl. `orb_fc_pack` injectivity and the wrap clear, FC-table faithfulness
and the reachable-state budget-sum invariant, top-level call correspondence) —
explicit modeling assumptions, NOT machine-checked, carried by prose + code review
+ the runtime gates (`--orbit-selftest` against the brute-force `orb_brute_repr`;
the SOLVE_REPR_FC=0/1 byte-identity A/B). The per-edge bound/sum facts about
orb_fc_build's tables and the initial budget sum are explicit HYPOTHESES of the
theorems (named in the file header), in the PruneExactness demands/remaining
discipline. Nothing here proves solve.c correct; the lex-min reading of the
returned leaf is RecordConvention.lean's `dfsFirst_min` (B6), composed in prose.

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
kernel-only end to end since 2026-08-07 — the §12 sanity witnesses are `decide +kernel` (migrated
from `native_decide`) and the theorems are structural. (The migration changed less than it
appears to: §12's former `native_decide` uses were all anonymous `example`s, which never enter
the environment, so the file's exported theorem surface was kernel-only at every earlier
revision as well.) Verified
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
(`python3 solve.py --trigram-verify` re-runs the two-language check). **Kernel-only end to end
since 2026-08-07** — finite facts use kernel `decide`/`decide +kernel`, zero `native_decide`
anywhere in the file (see the trust-base note above and the file header for the migration
history); the TG-2 sequence-level theorems are structural proofs over EVERY valid ordering.
**TG-2 trust-base note (updated 2026-07-27; original disclosure 2026-07-26):** the finite
`pairdist_count_0..6` lemmas, the three TG-1 counts, and `selfcomp_pair_count` are now kernel
`decide` (migrated from `native_decide`), so the TG-2 leads `boundary_budget_general` /
`ninth_six_trigram` / `single_line_carry` — and `within_multiset_general` — are **kernel-only**
(`#print axioms` = `[propext, Classical.choice, Quot.sound]`, Lean's standard axioms — the
`native_decide` compiler-trust axiom is gone): all four of the suite's sequence-level theorem
families now share the kernel-only trust base. The TG-3/TG-4/TG-5 finite subgroup facts and the
§6 sanity instances (§4a–§6)
remained `native_decide` until 2026-08-07, when they migrated to `decide +kernel` and the one
obligation too heavy for enumeration (`blockPreserving_iff_blockwise`) was reproved structurally
— the whole file is now kernel-only (third-tranche note above).
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
