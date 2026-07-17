-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  CompilerCorrectness.lean — machine-checked core of the v4 knowledge-compiler
  correctness proofs (2026-07-16; §A–§E ALL COMPLETE — §A/§D/§E first pass,
  §B rank/unrank second pass, §C equivariance/quotient final pass, all
  same-day 2026-07-16; §C sits LAST in the file, after §E).

  ─────────────────────────────────────────────────────────────────────────
  *** COMPLETION: CompilerCorrectness.lean machine-check core COMPLETE
  *** (K1a/K1c, K2a, K2c, K3, L3/L4 model level; bridge facts KB1–KB7
  *** runtime-carried), 2026-07-16.
  ***
  *** C-7 LANGUAGE NOTE: the frozen corpus wording "paper-proven;
  *** machine-checked core PENDING" may now be updated corpus-wide to
  *** "machine-checked core LANDED (model level; bridge facts
  *** runtime-carried)" ONLY after an INDEPENDENT RE-COMPILE of this file
  *** confirms the claim — a fresh session/host running
  *** `lean CompilerCorrectness.lean` on the pinned toolchain
  *** (leanprover/lean4:v4.31.0) with empty output and exit 0. Do not
  *** cascade the wording on this file's own transcript alone.
  ─────────────────────────────────────────────────────────────────────────

  *** COMPILES CLEAN on Lean 4.31.0 (2026-07-16, x86_64 linux, core only —
  *** no mathlib, no lake project): `lean CompilerCorrectness.lean` exits 0
  *** with zero errors/warnings; zero `sorry`, zero `axiom`, zero `admit`.
  *** The pinned toolchain is recorded in this directory's `lean-toolchain`
  *** (leanprover/lean4:v4.31.0). Written per the private proofs+design doc
  *** (roae-private V4_COMPILER_CORRECTNESS_PROOFS_2026_07_14, §6); solve.c
  *** cites below are by FUNCTION NAME, not line number (line numbers drift).

  ─────────────────────────────────────────────────────────────────────────
  SCOPE — read this before citing (model-level result, stated bluntly).

  What is machine-checked here is the ABSTRACT LAYERED-DP MODEL: an ordered
  successor structure over opaque states, its path lists, its counting
  recurrence, the cap-forces-full sum argument, slice-assembly determinism,
  and record-artifact composition. NOTHING in this file mentions hexagrams,
  masks, rids, 192-bit integers, or bytes on disk. The bridge from this
  model to the actual `solve.c` code (the f1c5 DP substrate and the KC query
  layer) is carried by the bridge facts KB1–KB7 below — each stated
  explicitly, each RUNTIME-VERIFIED by the named executable witness, and
  each NOT machine-checked. Nothing in this file proves `solve.c` bug-free.
  This is exactly the trust posture of PartitionInvariance.lean's B1–B4 and
  the lean/README "Tier 3" scope note: model theorems + stated bridges.
  ─────────────────────────────────────────────────────────────────────────

  Bridge facts KB1–KB7 (verbatim from the proofs doc §5; the honest trust
  boundary — witnessed, not machine-checked):

  · KB1 (kernel-implements-recurrence). `f1c5_gather_entries` +
    `f1c5_emit_target` compute the DP recurrence (★) with the L4 frame
    mapping. Witness: n=9 exhaustive byte-equality vs an independent forward
    brute force (gates A1–A3); M1 count equality vs the PRODUCTION
    rolling-window path (different code path, different process) at
    n=13/16/18/19/21/22; the count substrate's two-language Python/C
    per-layer gates.
  · KB2 (exact arithmetic). 192-bit add/sub/compare are exact; overflow
    hard-aborts (`f1_overflow_abort`) — no completed run ever wrapped.
    Witness: code inspection + the same gates.
  · KB3 (serialization determinism). The v1 writer emits only
    deterministic-from-input fields; atomic tmp+rename; loader validates
    header vs context. Witness: A8 round-trip; production-writer
    byte-equality at n=13.
  · KB4 (OOC == in-RAM). The #221 out-of-core builder produces the same
    logical layer content as the in-RAM path (shared per-entry kernel;
    different storage). Witness today: shared-kernel construction + n=13
    producer-integration gate. Required before full-31 claims: V1 gates
    rerun against the REAL v2-OOC reader, n=24/27/28 on a worker
    (fullbuild plan).
  · KB5 (group tables). The startup asserts (finite, exhaustive) actually
    run on every build/query host — they do (unconditional `F1_CHECK`s;
    failure aborts). Witness: `f1_build_group` hard-abort asserts, every
    run.
  · KB6 (v2-gz layer). Per-block gzip decompresses to the v1 logical
    stream; shas anchor decompressed bytes only (gzip is storage, never
    identity — standing policy). Witness: decompressed-stream sha gates.
  · KB7 (full-31 C3 constant). T = 387 per the proofs doc §2.6, gated vs
    solve.py before use. Witness: the specified two-language gate
    (derived-but-unverified until that gate lands).

  ─────────────────────────────────────────────────────────────────────────
  Contents of THIS file (design §6, sections A/B/D/E in that order, then
  §C — the final pass — as the file's LAST section, after §E):

  §A  Layered-path model — the K1(a)/K1(c) core.
      `LDP` (ordered nodup successors), `paths` (root-anchored path lists,
      list order = reverse-choice lex, the O1 analogue), `count` (the DP
      recurrence), and the theorems
      · `count_eq_paths_length` — count k s = (paths k s).length: the DP
        recurrence counts exactly the valid paths (K1(a) model core).
      · `paths_nodup` — no path is enumerated twice (K1(c) "each exactly
        once").
      · `paths_complete` — p ∈ paths D k s ↔ IsValidPath D p k s: the
        enumeration emits exactly the valid paths (K1(c) "exactly the
        elements of W").
      · `cap_forces_full` — the L2(ii) capping argument: componentwise
        d ≤ b0 with equal totals forces d = b0 (why every full-length
        capped prefix is a walk; rid_full forced at the final layer).
  §B  Rank/unrank — the K3 core (COMPLETE, 2026-07-16 second pass).
      `blockOffset`/`rank` (per-level earlier-block-mass partial sums,
      the model of `kc_rank`), `unrankScan`/`unrank` (inverse block
      scan, the model of `kc_unrank`), and the theorems
      · `unrank_eq_getElem?` (M1) — unrank r = (paths D k s)[r]?: unrank
        IS lookup-by-position in the §A enumeration.
      · `rank_getElem?` (M2) — (paths D k s)[rank w]? = some w for valid
        w, with `rank_eq_position` (uniqueness via `paths_nodup`): rank
        IS the list position.
      · `unrank_mem`/`unrank_valid`, `unrank_none_iff` (rejects exactly
        r ≥ count), `rank_lt_count` (range), `unrank_rank` and
        `rank_unrank` (both K3 round-trips, whole range).
      · `rank_strictMono` — earlier list position ↔ smaller rank
        (list-position form of the order isomorphism), and the
        STANDALONE lex order `O1Lt` (the doc's <_{O1}, defined with no
        reference to paths/rank) with `O1Lt_iff_rank_lt` (via
        `O1Lt_trichotomy`) and `O1Lt_iff_position_lt` — §A's "list
        order = reverse-choice lex" design decision, now a theorem.
      K3(d) sampling-uniformity is NOT formalized (it is a statement
      about an external uniform RNG, outside this model; the bijection
      clauses above are its mathematical content).
  §D  Build invariance — the K2(a) core.
      `assemble` (per-target emission concatenated in target-index order)
      and the theorems
      · `assemble_append` — binary slice split.
      · `assemble_slices_merged` — ANY decomposition of the target list
        into contiguous slices, built separately and merged by target
        index, yields byte-for-byte the whole-run assembly. Processing
        ORDER invariance is the observation that no processing order
        appears anywhere in `assemble`'s definition: the assembled list is
        a pure function of (emit, targets). Pair with KB1 (the per-target
        emission the model's `emit` stands for is `f1c5_gather_target` +
        `f1c5_emit_target`) and KB3 (`f1c5_write_layer` serializes only
        deterministic fields around this concatenation).
  §E  Record composition — the K2(c) core.
      Restated `dedup`/`artifact`/`artifact_key_ext`/`artifact_mono` (from
      RecordConvention.lean on the v4-canonical branch, proven there;
      re-proven from scratch here for standalone composition — see the
      per-declaration attribution comments), plus the fresh ingredient
      K2(c) needs from this side:
      · `rankPrefix_mono` — rank-prefix visited families are monotone:
        N ≤ N' → (paths … ).take N ⊆ (paths …).take N' (definitional
        from the take-prefix formulation).
      · `artifact_rankPrefix_mono` — the composition: the record artifact
        of a rank-prefix slice only GROWS as the prefix extends; record
        bytes never change (purity of repr).
  §C  Equivariance/quotient — the L3/L4 core (COMPLETE, 2026-07-16 final
      pass; the file's LAST section). Abstract state maps φ with explicit
      equivariance HYPOTHESES (the Automorphism.lean discipline; the
      2³¹-mask-level facts stay RUNTIME-VERIFIED, KB5), in TWO forms:
      · ORDER-PRESERVING (`OrdEquivariant`: succs k (φ s) =
        (succs k s).map φ): master lemma `paths_equivariant`
        (enumeration transports elementwise, same order; one
        k-induction), corollaries `count_invariant` (L3 model core),
        `mem_paths_equivariant`, `rank_equivariant`,
        `unrank_equivariant` (positions transport via `getElem?_map`).
        No injectivity of φ is assumed anywhere.
      · PERM-ONLY (`PermEquivariant`: succs k (φ s) ~ (succs k s).map φ):
        `count_invariant_perm` (its own k-induction; sums are
        Perm-invariant via the hand-rolled `perm_sum`). Rank
        equivariance is GENUINELY FALSE under perm-only — witnessed by a
        kernel `decide` counterexample (`flip` on `toyD`), not merely
        left unproven. THE RUNTIME'S MASK-LEVEL ACTION IS THIS FORM: the
        24-coset action (KB5) permutes candidate exits but the descent
        re-scans lc = 0..63 ascending, so scan order is not transported;
        the compiler pulls only COUNTS through canonicalization
        (`f1c5_gather_target`/`kc_flookup`) and never a rank — L3/L4
        consume exactly the perm-only theorems.
      · L4 quotient-lookup soundness: `quotient_lookup_sound` (+
        `quotient_lookup_sound_perm`, the form the runtime
        instantiates) — count at `canon m` = count at `m`, for an
        abstract canonicalizer landing in the orbit of an equivariant
        family (a `List (σ → σ)` of maps each carrying its hypothesis;
        `canon` idempotence is runtime-carried, KB5, and NOT consumed).
      Kernel witnesses: the 2-state `boolD` with the bit-flip `not`
      (order-preserving; full suite incl. an L4 quotient instance) and
      `toyD` with `flip` (perm-only; count invariant, rank
      counterexample).

  ─────────────────────────────────────────────────────────────────────────
  Design notes for the §C pass (equivariance/quotient), recorded by the
  §B author while the induction structure was fresh — CONSUMED by the
  final pass, 2026-07-16 (kept verbatim for the record; §C followed them,
  including the Perm-only fork of the second note — BOTH forms are
  stated, with the modeling decision documented in the §C intro):

  · Route the whole section through `paths`, not through separate
    `count`/`rank` inductions. For a state map φ, the useful hypothesis
    is the LIST EQUALITY `succs k (φ s) = (succs k s).map φ` (order-
    preserving equivariance of the candidate scan) — one k-induction
    with `List.map_flatMap`/`List.flatMap_map`/`List.map_map` then gives
    `paths D k (φ s) = (paths D k s).map (List.map φ)`, and count
    invariance is a corollary via `count_eq_paths_length` +
    `List.length_map` (no separate count induction), exactly as every §B
    theorem fell out of M1/M2. rank/unrank equivariance are then free
    too: `List.getElem?_map` transports positions, so
    rank(φ·w) = rank(w) and unrank commutes with the relabeling.
  · If the group action does NOT preserve the candidate-scan order,
    weaken the hypothesis to a permutation `succs k (φ s) ~
    (succs k s).map φ`: count invariance survives (sums are Perm-
    invariant), but the ORDER theorems do not — rank is genuinely not
    equivariant then. Decide which hypothesis models the C3/orbit
    action BEFORE writing; do not try to salvage rank equivariance
    under the Perm-only hypothesis.
  · Injectivity plumbing already here and reusable: `nodup_map_of_injective`,
    `nodup_flatMap`, `nodup_getElem?_inj`. Core-4.31.0 gaps discovered
    (hand-roll, don't hunt): no `getElem?_flatMap` (the §B block-scan
    lemmas are the substitute — reuse them), no `Nodup.map`, no
    `Nodup.filter` (use `List.Sublist.nodup List.filter_sublist`);
    `omit [DecidableEq σ] in` must precede the docstring, not follow it.
  ─────────────────────────────────────────────────────────────────────────

  Attribution: developed with AI assistance (Claude, Anthropic). The
  mathematics here (path counting in a layered DAG, digit-cap sum
  arguments, concatenation associativity, first-occurrence dedup) is
  elementary and standard — the rank/unrank layer in §B is the
  classical Nijenhuis–Wilf / Knuth TAOCP 4A §7.2.1 unranking scheme, and
  no novelty is claimed for any content here; only the mapping of this
  abstraction onto the v4 compiler pipeline and the machine-checked
  formalization are the project's own work, to our knowledge (corrections
  welcome). Paper proofs: roae-private
  V4_COMPILER_CORRECTNESS_PROOFS_2026_07_14.md (L1–L7, K1/K2/K3, KB1–KB7);
  record-layer precedent: RecordConvention.lean (v4-canonical branch);
  merge-model precedent: PartitionInvariance.lean (this directory).
-/

namespace CompilerCorrectness

universe u v w

/-! ### §A Layered-path model (K1a/K1c core)

    The abstract shape of the f1c5 layered DP: opaque states σ, and for
    each level an ORDERED, duplicate-free list of successor candidates.
    `succs k s` = the ordered candidate next-states from state `s` when,
    after taking one of them, `k` further choices remain (so a `paths D k s`
    recursion consumes `succs (k-1)`, …, `succs 0`). In the concrete
    instantiation (§C, the file's final section, keeps it abstract per
    the KB5 bridge) σ = (mask, last-exit, rid) and `succs`
    is the budget-killed transition list of `f1c5_gather_target` read in
    the descent's fixed candidate order (lc = 0..63 ascending, K1(c));
    that connection is bridge material (KB1), not proven here.

    Design note consumed by the §B (rank/unrank) section below — these
    definitions are the contract: `paths` lists are BLOCK-STRUCTURED — for each state, one
    block per successor, blocks concatenated in `succs` order, each block
    = the successor's own path list with the successor consed on. Block
    masses are therefore `count D k t` (by `count_eq_paths_length`), and
    the list position of a path IS its rank in reverse-choice lex order —
    the O1 analogue (the first recorded choice is the walk's LAST exit
    x_n, exactly as `kc_enum` resolves x_n first). Both definitions are
    plain structural recursion, so small instances reduce in the kernel
    (`rfl`/`decide` witnesses below). -/

/-- Layered DP structure: per-level ordered successor candidates, carried
    duplicate-freeness. `DecidableEq σ` is consumed by §B's rank/unrank
    layer (`blockOffset`/`idxIn` block search); §A's theorems don't use
    it. -/
structure LDP (σ : Type u) [DecidableEq σ] where
  /-- ordered successor candidates of state `s` when `k` further choices
      remain after this one. -/
  succs : Nat → σ → List σ
  /-- candidate lists are duplicate-free (the descent's lc = 0..63 scan
      visits each candidate exit once). -/
  succs_nodup : ∀ k s, (succs k s).Nodup

variable {σ : Type u} [DecidableEq σ]

/-- Root-anchored path lists: `paths D k s` = all length-`k` choice
    sequences from `s`, grouped by first choice in `succs` order (block
    structure; list order = reverse-choice lex = the O1 analogue). -/
def paths (D : LDP σ) : Nat → σ → List (List σ)
  | 0, _ => [[]]
  | k + 1, s => (D.succs k s).flatMap fun t => (paths D k t).map (t :: ·)

/-- The DP counting recurrence (the model of `f(k, ·)` and the pull-form
    gather (★): layer-(k+1) mass at `s` = sum of layer-k masses over the
    valid successors). -/
def count (D : LDP σ) : Nat → σ → Nat
  | 0, _ => 1
  | k + 1, s => ((D.succs k s).map fun t => count D k t).sum

/-- **K1(a) model core.** The DP recurrence counts exactly the paths:
    `count D k s = (paths D k s).length`. With KB1 (the C kernel computes
    this recurrence) and KB2 (exactly), this is "total = |W|" at the model
    level. -/
theorem count_eq_paths_length (D : LDP σ) :
    ∀ (k : Nat) (s : σ), count D k s = (paths D k s).length := by
  intro k
  induction k with
  | zero => intro _; rfl
  | succ k ih =>
    intro s
    simp only [count, paths, List.length_flatMap, List.length_map]
    rw [funext ih]

/-- mapping through an injective function preserves duplicate-freeness
    (hand-rolled on `Pairwise.map`; core 4.31.0 has no `List.Nodup.map`). -/
theorem nodup_map_of_injective {α : Type u} {β : Type v} {f : α → β}
    (hf : ∀ a b, f a = f b → a = b) {l : List α} (h : l.Nodup) :
    (l.map f).Nodup :=
  List.Pairwise.map f (fun a b hne he => hne (hf a b he)) h

/-- disjoint duplicate-free lists concatenate duplicate-free (hand-rolled;
    same statement as PartitionInvariance.lean's helper — reproved here to
    keep the file standalone). -/
theorem nodup_append_of_disjoint {β : Type v} {v' : List β} :
    ∀ {u : List β}, u.Nodup → v'.Nodup → (∀ x ∈ u, x ∉ v') → (u ++ v').Nodup := by
  intro u
  induction u with
  | nil => intro _ hv _; simpa using hv
  | cons a t ih =>
    intro hu hv hd
    have h' := List.nodup_cons.mp hu
    rw [List.cons_append, List.nodup_cons]
    refine ⟨?_, ih h'.2 hv fun x hx => hd x (List.mem_cons_of_mem a hx)⟩
    intro hmem
    rcases List.mem_append.mp hmem with h1 | h2
    · exact h'.1 h1
    · exact hd a (by simp) h2

/-- flatMap over a duplicate-free list with duplicate-free, pairwise
    disjoint images is duplicate-free. -/
theorem nodup_flatMap {α : Type u} {β : Type v} {f : α → List β} :
    ∀ {l : List α}, l.Nodup → (∀ a ∈ l, (f a).Nodup) →
      (∀ a ∈ l, ∀ b ∈ l, a ≠ b → ∀ x ∈ f a, x ∉ f b) →
      (l.flatMap f).Nodup := by
  intro l
  induction l with
  | nil => intro _ _ _; simp
  | cons a t ih =>
    intro hnd hf hdisj
    rw [List.flatMap_cons]
    have h' := List.nodup_cons.mp hnd
    apply nodup_append_of_disjoint
    · exact hf a (by simp)
    · exact ih h'.2 (fun b hb => hf b (List.mem_cons_of_mem a hb))
        (fun b hb c hc => hdisj b (List.mem_cons_of_mem a hb) c
          (List.mem_cons_of_mem a hc))
    · intro x hxa hxt
      obtain ⟨b, hb, hxb⟩ := List.mem_flatMap.mp hxt
      have hab : a ≠ b := fun e => h'.1 (e ▸ hb)
      exact hdisj a (by simp) b (List.mem_cons_of_mem a hb) hab x hxa hxb

/-- **K1(c) "each exactly once" (model core).** No path appears twice in
    the enumeration: distinct successors head distinct blocks, and within
    a block the tails are distinct by induction. -/
theorem paths_nodup (D : LDP σ) : ∀ (k : Nat) (s : σ), (paths D k s).Nodup := by
  intro k
  induction k with
  | zero => intro s; simp [paths]
  | succ k ih =>
    intro s
    simp only [paths]
    apply nodup_flatMap
    · exact D.succs_nodup k s
    · intro t _
      exact nodup_map_of_injective
        (fun p q e => by injection e) (ih t)
    · intro t _ t' _ hne x hx hx'
      obtain ⟨p, _, rfl⟩ := List.mem_map.mp hx
      obtain ⟨q, _, he⟩ := List.mem_map.mp hx'
      injection he with h1 _
      exact hne h1.symm

/-- A valid length-`k` choice sequence from `s`: each recorded choice is a
    `succs`-candidate of the state it was taken from (the model of D2/D3
    validity — state-local, exactly the "validity depends only on the
    state, never the identity" step of L4/L5). -/
inductive IsValidPath (D : LDP σ) : List σ → Nat → σ → Prop where
  | nil (s : σ) : IsValidPath D [] 0 s
  | cons {k : Nat} {s t : σ} {p : List σ} :
      t ∈ D.succs k s → IsValidPath D p k t → IsValidPath D (t :: p) (k + 1) s

/-- **K1(c) "exactly the elements of W" (model core).** The enumeration
    emits precisely the valid paths: membership in `paths D k s` IS
    validity. With `paths_nodup` this is K1(c) minus the order clause; the
    order-isomorphism (rank = list position) is §B's `rank_eq_position` /
    `rank_strictMono` / `O1Lt_iff_rank_lt`. -/
theorem paths_complete (D : LDP σ) :
    ∀ (k : Nat) (s : σ) (p : List σ), p ∈ paths D k s ↔ IsValidPath D p k s := by
  intro k
  induction k with
  | zero =>
    intro s p
    constructor
    · intro hp
      have hpn : p = [] := by simpa [paths] using hp
      exact hpn ▸ IsValidPath.nil s
    · intro hv
      cases hv
      simp [paths]
  | succ k ih =>
    intro s p
    constructor
    · intro hp
      simp only [paths] at hp
      obtain ⟨t, ht, hp'⟩ := List.mem_flatMap.mp hp
      obtain ⟨q, hq, rfl⟩ := List.mem_map.mp hp'
      exact IsValidPath.cons ht ((ih t q).mp hq)
    · intro hv
      cases hv with
      | cons ht hv' =>
        simp only [paths]
        exact List.mem_flatMap.mpr
          ⟨_, ht, List.mem_map.mpr ⟨_, (ih _ _).mpr hv', rfl⟩⟩

/-! #### The capping argument (L2(ii)): componentwise-capped digits with a
    full total are forced to the cap.

    In the concrete DP the index is the 5 boundary classes {1,2,3,4,6},
    `b0` is the run's class budget (full-31: (2,8,13,7,1), Σ = 31 = n), and
    `d` a full-length prefix's class counts (one boundary per placement, so
    Σ_c d_c = n). The cap `d_c ≤ b0_c` is the DP's budget-kill; this lemma
    is why every n-element capped prefix has d = b0 exactly — i.e. IS a
    walk, and why every final-layer entry has rid = rid_full (the corollary
    `kc_total_from_final` hard-checks at runtime). Finite sum over `Fin n`
    hand-rolled (no mathlib). -/

/-- sum of `f` over `Fin n` (hand-rolled finite sum). -/
def finSum : (n : Nat) → (Fin n → Nat) → Nat
  | 0, _ => 0
  | n + 1, f => f ⟨0, Nat.succ_pos n⟩ + finSum n (fun i => f i.succ)

/-- pointwise ≤ sums to ≤. -/
theorem finSum_le_finSum : ∀ (n : Nat) {f g : Fin n → Nat},
    (∀ i, f i ≤ g i) → finSum n f ≤ finSum n g
  | 0, _, _, _ => Nat.le_refl 0
  | n + 1, _, _, h =>
    Nat.add_le_add (h ⟨0, Nat.succ_pos n⟩)
      (finSum_le_finSum n fun i => h i.succ)

/-- pointwise form of the capping argument, by induction on the width:
    the head is forced because the tails compare, the tails recurse. -/
theorem cap_forces_full_pointwise : ∀ (n : Nat) (d b0 : Fin n → Nat),
    (∀ c, d c ≤ b0 c) → finSum n d = finSum n b0 → ∀ c, d c = b0 c := by
  intro n
  induction n with
  | zero => intro _ _ _ _ c; exact c.elim0
  | succ n ih =>
    intro d b0 hle hsum
    simp only [finSum] at hsum
    have hhead := hle ⟨0, Nat.succ_pos n⟩
    have htail := finSum_le_finSum n (fun i => hle i.succ)
    have hS : finSum n (fun i => d i.succ) = finSum n (fun i => b0 i.succ) := by
      omega
    intro c
    match c with
    | ⟨0, _⟩ => omega
    | ⟨j + 1, hj⟩ =>
      exact ih (fun i => d i.succ) (fun i => b0 i.succ)
        (fun i => hle i.succ) hS ⟨j, Nat.lt_of_succ_lt_succ hj⟩

/-- **L2(ii) as arithmetic (cap-forces-full).** If every class count is
    capped by its budget and the totals agree, the counts EQUAL the budget:
    `d = b0`. -/
theorem cap_forces_full {n : Nat} {d b0 : Fin n → Nat}
    (hle : ∀ c, d c ≤ b0 c) (hsum : finSum n d = finSum n b0) : d = b0 :=
  funext (cap_forces_full_pointwise n d b0 hle hsum)

/-! #### §A sanity witnesses (kernel-reduced: `rfl`/`decide` only — both
    definitions are structural recursion, so the small instance evaluates
    inside the kernel; nothing here relies on `native_decide`). -/

/-- toy layered DP: from every state, candidates [0, 1] in that order. -/
def toyD : LDP Nat where
  succs := fun _ _ => [0, 1]
  succs_nodup := fun _ _ => by decide

/-- the DP recurrence value... -/
example : count toyD 2 0 = 4 := rfl

/-- ...counts exactly the enumerated paths, which appear in
    reverse-choice lex order (first recorded choice most significant —
    the O1 analogue): block [0,·] before block [1,·]. -/
example : paths toyD 2 0 = [[0, 0], [0, 1], [1, 0], [1, 1]] := rfl

/-- the theorem instance agrees with the computation. -/
example : count toyD 2 0 = (paths toyD 2 0).length :=
  count_eq_paths_length toyD 2 0

/-- the full-31 class budget B0 = (2, 8, 13, 7, 1) over the 5 boundary
    classes {1, 2, 3, 4, 6} (`f1c5_derive_b0`). -/
def fullB0 : Fin 5 → Nat := fun c => [2, 8, 13, 7, 1].getD c.val 0

/-- cap-forces-full at the concrete full-31 budget: ANY budget-capped
    class-count vector totalling 31 IS the budget (Σ fullB0 = 31 by
    kernel `decide`) — the reason every final-layer entry has
    rid = rid_full. -/
example (d : Fin 5 → Nat) (hle : ∀ c, d c ≤ fullB0 c)
    (hsum : finSum 5 d = 31) : d = fullB0 :=
  cap_forces_full hle (hsum.trans (by decide))

/-! ### §B Rank / unrank — the order isomorphism (K3 core)

    The classical unranking-from-a-counting-DP scheme (Nijenhuis–Wilf;
    Knuth TAOCP 4A §7.2.1 — method credit as in the header; no novelty
    claimed): `rank` accumulates, at each level, the masses of the blocks
    BEFORE the chosen successor (partial sums of `count D k ·` along
    `succs`), and `unrank` performs the inverse block scan, subtracting
    block masses until the residual index falls inside a block, then
    descending. In the concrete instantiation these are `kc_rank` /
    `kc_unrank` (bridge KB1/KB2, not proven here).

    Proof architecture (the master-lemma route): both operations are
    proven against LIST-POSITION semantics on `paths` —
    · `unrank_eq_getElem?` : unrank r  =  (paths D k s)[r]?   (M1)
    · `rank_getElem?`      : (paths D k s)[rank w]? = some w  (M2)
    and every K3 clause (round-trips, membership, rejection, strict
    monotonicity) is a corollary of M1 + M2 + `paths_nodup` (position
    uniqueness). The single combinatorial ingredient is the BLOCK-SCAN
    lemma pair on the `paths` flatMap structure: position of `t :: p`
    in `paths D (k+1) s` = (mass of blocks before `t`) + (position of
    `p` in `paths D k t`) — `blockScan_getElem?` below; `unrankScan`'s
    correctness is the same scan read in the other direction.

    ORDER FORMULATION — read this before citing `rank_strictMono` /
    `O1Lt_iff_rank_lt`. §A fixed (design decision 1) that the `paths`
    LIST ORDER is the reverse-choice lex order — the O1 analogue (first
    recorded choice = the walk's last exit, most significant). So "rank
    is an O1 order isomorphism" is stated in BOTH available forms:
    (i) the list-position form `rank_strictMono` (earlier list position
    ↔ smaller rank — definitional once rank = position is proven), and
    (ii) a STANDALONE inductive lexicographic order `O1Lt` (heads
    compared by first-occurrence position in `succs`, ties recurse into
    the tail) with the full equivalence `O1Lt_iff_rank_lt` proven via
    trichotomy. (ii) is the doc's ≤_{O1} at the model level; nothing
    below assumes the two coincide — that IS the theorem. -/

/-- Mass of the successor blocks strictly BEFORE the first occurrence of
    `t` in a candidate list, block masses given by `f` (instantiated at
    `count D k`): the per-level partial sum of `kc_rank`. This is where
    §A's carried `DecidableEq σ` is finally consumed. -/
def blockOffset (f : σ → Nat) (t : σ) : List σ → Nat
  | [] => 0
  | u :: us => if u = t then 0 else f u + blockOffset f t us

/-- Rank of a choice sequence: at each level, the mass of the earlier
    blocks plus the rank within the chosen block (the model of
    `kc_rank`). On sequences that are not valid paths the value is
    meaningless-but-total (`0` padding); every theorem below assumes
    `IsValidPath` / `∈ paths`. -/
def rank (D : LDP σ) : Nat → σ → List σ → Nat
  | 0, _, _ => 0
  | _ + 1, _, [] => 0
  | k + 1, s, t :: p => blockOffset (count D k) t (D.succs k s) + rank D k t p

/-- One-level block scan for `unrank`: walk the candidate blocks in
    `succs` order, subtracting each block's mass `f t` until the residual
    index `r` falls inside a block, then descend via `g` (instantiated at
    `unrank D k`) and cons the block's head choice. Rejects (`none`) when
    `r` runs off the end — the model of `kc_unrank`'s scan. -/
def unrankScan (f : σ → Nat) (g : σ → Nat → Option (List σ)) :
    List σ → Nat → Option (List σ)
  | [], _ => none
  | t :: ts, r =>
    if r < f t then (g t r).map (t :: ·)
    else unrankScan f g ts (r - f t)

/-- Unrank: the inverse block scan (the model of `kc_unrank`); total via
    `Option`, `none` exactly on out-of-range indices (`unrank_none_iff`). -/
def unrank (D : LDP σ) : Nat → σ → Nat → Option (List σ)
  | 0, _, r => if r = 0 then some [] else none
  | k + 1, s, r => unrankScan (count D k) (unrank D k) (D.succs k s) r

omit [DecidableEq σ] in
/-- One-level scan correctness, abstracted over the level-k data: if `f`
    gives the block lengths and `g` is level-k lookup-by-position, the
    scan is lookup-by-position on the assembled flatMap. The induction is
    on the candidate list; `getElem?_append_left/right` split the index
    at each block boundary. -/
theorem unrankScan_eq_getElem? (f : σ → Nat) (g : σ → Nat → Option (List σ))
    (F : σ → List (List σ)) (hlen : ∀ t, f t = (F t).length)
    (hg : ∀ t r, g t r = (F t)[r]?) :
    ∀ (l : List σ) (r : Nat),
      unrankScan f g l r = (l.flatMap fun t => (F t).map (t :: ·))[r]? := by
  intro l
  induction l with
  | nil => intro r; rw [List.flatMap_nil, unrankScan, List.getElem?_nil]
  | cons t ts ih =>
    intro r
    rw [List.flatMap_cons, unrankScan]
    by_cases h : r < f t
    · rw [if_pos h, hg,
        List.getElem?_append_left (by rw [List.length_map, ← hlen]; exact h),
        List.getElem?_map]
    · rw [if_neg h,
        List.getElem?_append_right
          (by rw [List.length_map, ← hlen]; omega),
        List.length_map, ← hlen, ih]

/-- **M1 (master lemma, unrank side).** `unrank` IS lookup-by-position in
    the §A enumeration: `unrank D k s r = (paths D k s)[r]?`. Everything
    `kc_unrank`-shaped below is a corollary of this equation. -/
theorem unrank_eq_getElem? (D : LDP σ) :
    ∀ (k : Nat) (s : σ) (r : Nat), unrank D k s r = (paths D k s)[r]? := by
  intro k
  induction k with
  | zero =>
    intro s r
    match r with
    | 0 => rfl
    | _ + 1 => rfl
  | succ k ih =>
    intro s r
    rw [unrank, paths]
    exact unrankScan_eq_getElem? (count D k) (unrank D k) (paths D k)
      (fun t => count_eq_paths_length D k t) (fun t r => ih t r)
      (D.succs k s) r

/-- **K3 rejection clause.** `unrank` returns `none` exactly on
    out-of-range indices: `unrank D k s r = none ↔ count D k s ≤ r`
    (with M1 this is `getElem?`'s out-of-range semantics plus K1(a)). -/
theorem unrank_none_iff (D : LDP σ) (k : Nat) (s : σ) (r : Nat) :
    unrank D k s r = none ↔ count D k s ≤ r := by
  rw [unrank_eq_getElem?, List.getElem?_eq_none_iff, count_eq_paths_length]

/-- **K3 membership clause.** Every `unrank` output is an enumerated
    (hence, by `paths_complete`, valid) path. -/
theorem unrank_mem (D : LDP σ) {k : Nat} {s : σ} {r : Nat} {w : List σ}
    (h : unrank D k s r = some w) : w ∈ paths D k s :=
  List.mem_of_getElem? (unrank_eq_getElem? D k s r ▸ h)

/-- `unrank_mem` restated through §A's `paths_complete`: `unrank` outputs
    are valid paths. -/
theorem unrank_valid (D : LDP σ) {k : Nat} {s : σ} {r : Nat} {w : List σ}
    (h : unrank D k s r = some w) : IsValidPath D w k s :=
  (paths_complete D k s w).mp (unrank_mem D h)

/-- **The block-scan lemma (rank side).** In the assembled flatMap, the
    element at position (mass of the blocks before `t`) + `j` is the
    `j`-th element of `t`'s own block, consed — for any in-block index
    `j < f t`. The offset addresses the FIRST occurrence of `t`, so no
    duplicate-freeness of the candidate list is needed here (it is
    consumed later, for position UNIQUENESS via `paths_nodup`). -/
theorem blockScan_getElem? (f : σ → Nat) (F : σ → List (List σ))
    (hlen : ∀ t, f t = (F t).length) (t : σ) :
    ∀ (l : List σ), t ∈ l → ∀ (j : Nat), j < f t →
      (l.flatMap fun u => (F u).map (u :: ·))[blockOffset f t l + j]?
        = ((F t)[j]?).map (t :: ·) := by
  intro l
  induction l with
  | nil => intro h; cases h
  | cons u us ih =>
    intro hmem j hj
    rw [List.flatMap_cons]
    by_cases h : u = t
    · subst h
      rw [blockOffset, if_pos rfl, Nat.zero_add,
        List.getElem?_append_left (by rw [List.length_map, ← hlen]; exact hj),
        List.getElem?_map]
    · have hmem' : t ∈ us := by
        rcases List.mem_cons.mp hmem with rfl | h'
        · exact absurd rfl h
        · exact h'
      rw [blockOffset, if_neg h, Nat.add_assoc,
        List.getElem?_append_right
          (by rw [List.length_map, ← hlen]; exact Nat.le_add_right ..),
        List.length_map, ← hlen, Nat.add_sub_cancel_left]
      exact ih hmem' j hj

/-- **M2 (master lemma, rank side).** For every valid path `w`, position
    `rank D k s w` of the enumeration holds exactly `w`:
    `(paths D k s)[rank D k s w]? = some w`. Induction on the validity
    derivation; each level is one application of `blockScan_getElem?`,
    with the in-block index bounded by the inductive hypothesis. -/
theorem rank_getElem? (D : LDP σ) {w : List σ} {k : Nat} {s : σ}
    (hv : IsValidPath D w k s) :
    (paths D k s)[rank D k s w]? = some w := by
  induction hv with
  | nil s => rfl
  | @cons k s t p ht _ ih =>
    have hj : rank D k t p < count D k t := by
      rw [count_eq_paths_length]
      exact (List.getElem?_eq_some_iff.mp ih).1
    rw [paths, rank,
      blockScan_getElem? (count D k) (paths D k)
        (fun u => count_eq_paths_length D k u) t (D.succs k s) ht
        (rank D k t p) hj,
      ih, Option.map_some]

/-- **K3 range clause.** Valid paths rank inside `{0, …, count − 1}`. -/
theorem rank_lt_count (D : LDP σ) {w : List σ} {k : Nat} {s : σ}
    (hv : IsValidPath D w k s) : rank D k s w < count D k s := by
  rw [count_eq_paths_length]
  exact (List.getElem?_eq_some_iff.mp (rank_getElem? D hv)).1

omit [DecidableEq σ] in
/-- in a duplicate-free list, positions holding the same element are
    equal (hand-rolled; core 4.31.0 has no `getElem?` form of nodup
    injectivity). This is where K1(c)'s `paths_nodup` pays off: it makes
    "THE position of `w`" well-defined. -/
theorem nodup_getElem?_inj {α : Type u} :
    ∀ {l : List α}, l.Nodup → ∀ {i j : Nat} {a : α},
      l[i]? = some a → l[j]? = some a → i = j := by
  intro l
  induction l with
  | nil => intro _ i j a hi; rw [List.getElem?_nil] at hi; cases hi
  | cons b t ih =>
    intro hnd i j a hi hj
    have h' := List.nodup_cons.mp hnd
    match i, j with
    | 0, 0 => rfl
    | 0, j + 1 =>
      rw [List.getElem?_cons_zero] at hi
      rw [List.getElem?_cons_succ] at hj
      injection hi with hb
      exact absurd (hb ▸ List.mem_of_getElem? hj) h'.1
    | i + 1, 0 =>
      rw [List.getElem?_cons_succ] at hi
      rw [List.getElem?_cons_zero] at hj
      injection hj with hb
      exact absurd (hb ▸ List.mem_of_getElem? hi) h'.1
    | i + 1, j + 1 =>
      rw [List.getElem?_cons_succ] at hi hj
      exact congrArg Nat.succ (ih h'.2 hi hj)

/-- rank recovers the (unique, by `paths_nodup`) list position: if `w`
    sits at position `i` of the enumeration, `rank D k s w = i`. With M2
    this says rank IS the list position — the file's "rank = index"
    bridge, and the sense in which §E's take-`N` prefix is literally
    "the ranks < N". -/
theorem rank_eq_position (D : LDP σ) {k : Nat} {s : σ} {w : List σ}
    {i : Nat} (h : (paths D k s)[i]? = some w) : rank D k s w = i :=
  nodup_getElem?_inj (paths_nodup D k s)
    (rank_getElem? D ((paths_complete D k s w).mp (List.mem_of_getElem? h)))
    h

/-- **K3 round-trip, walk side.** `unrank (rank w) = w` for every
    enumerated (= valid) path `w`. -/
theorem unrank_rank (D : LDP σ) {k : Nat} {s : σ} {w : List σ}
    (hw : w ∈ paths D k s) : unrank D k s (rank D k s w) = some w := by
  rw [unrank_eq_getElem?]
  exact rank_getElem? D ((paths_complete D k s w).mp hw)

/-- **K3 round-trip, index side.** On the whole range `r < count`,
    `rank (unrank r) = r` (stated through `Option.map`; `unrank` is
    `some` on the range by `unrank_none_iff`). -/
theorem rank_unrank (D : LDP σ) {k : Nat} {s : σ} {r : Nat}
    (h : r < count D k s) :
    (unrank D k s r).map (rank D k s) = some r := by
  have hr : r < (paths D k s).length := by
    rw [← count_eq_paths_length]; exact h
  have hw : (paths D k s)[r]? = some (paths D k s)[r] :=
    List.getElem?_eq_getElem hr
  rw [unrank_eq_getElem?, hw, Option.map_some, rank_eq_position D hw]

/-- **K3 order isomorphism, list-position form.** Between enumerated
    paths, "earlier list position" and "smaller rank" coincide — by §A
    design decision 1 the list order IS the reverse-choice lex order
    (the O1 analogue), so this is already the order-isomorphism clause;
    the standalone lexicographic form is `O1Lt_iff_rank_lt` below. -/
theorem rank_strictMono (D : LDP σ) {k : Nat} {s : σ} {u v : List σ}
    {i j : Nat} (hu : (paths D k s)[i]? = some u)
    (hv : (paths D k s)[j]? = some v) :
    i < j ↔ rank D k s u < rank D k s v := by
  rw [rank_eq_position D hu, rank_eq_position D hv]

/-! #### The standalone lexicographic order (the doc's ≤_{O1}) and its
    equivalence with rank.

    `O1Lt` is reverse-choice lex stated WITHOUT reference to `paths` or
    `rank`: compare the first (most-significant) choice by its
    first-occurrence position in the candidate list, ties recurse into
    the tail at the successor state. This is the model-level transcription
    of D5's ≤_{O1} ("largest differing index" reads as "first recorded
    choice" here because `paths` records the most-significant choice
    first — §A design decision 1). The equivalence with rank is proven
    via trichotomy, not assumed. -/

/-- first-occurrence position of `t` in a candidate list (hand-rolled
    `idxOf`; core's is `BEq`-based, this stays on `DecidableEq`).
    Meaningful only when `t ∈ l` — all consumers below carry membership. -/
def idxIn (t : σ) : List σ → Nat
  | [] => 0
  | u :: us => if u = t then 0 else idxIn t us + 1

/-- Reverse-choice lex order between length-`k` choice sequences from
    `s` (the O1 analogue, standalone form): either the heads differ and
    the earlier-listed candidate wins, or the heads agree and the tails
    compare at the successor state. -/
inductive O1Lt (D : LDP σ) : Nat → σ → List σ → List σ → Prop where
  | head {k : Nat} {s t t' : σ} {p q : List σ} :
      idxIn t (D.succs k s) < idxIn t' (D.succs k s) →
      O1Lt D (k + 1) s (t :: p) (t' :: q)
  | tail {k : Nat} {s t : σ} {p q : List σ} :
      O1Lt D k t p q → O1Lt D (k + 1) s (t :: p) (t :: q)

/-- distinct elements of a list have distinct first-occurrence positions
    (no duplicate-freeness needed: FIRST occurrences). -/
theorem idxIn_ne {t t' : σ} (hne : t ≠ t') :
    ∀ {l : List σ}, t ∈ l → t' ∈ l → idxIn t l ≠ idxIn t' l := by
  intro l
  induction l with
  | nil => intro h; cases h
  | cons u us ih =>
    intro ht ht'
    by_cases h1 : u = t
    · have h2 : ¬u = t' := fun e => hne (h1 ▸ e ▸ rfl)
      rw [idxIn, if_pos h1, idxIn, if_neg h2]
      omega
    · by_cases h2 : u = t'
      · rw [idxIn, if_neg h1, idxIn, if_pos h2]
        omega
      · rw [idxIn, if_neg h1, idxIn, if_neg h2]
        have ht2 : t ∈ us := by
          rcases List.mem_cons.mp ht with rfl | h; exact absurd rfl h1; exact h
        have ht2' : t' ∈ us := by
          rcases List.mem_cons.mp ht' with rfl | h; exact absurd rfl h2; exact h
        have := ih ht2 ht2'
        omega

/-- an earlier first occurrence means the whole earlier block (offset PLUS
    mass) fits before the later block's offset — the arithmetic heart of
    "head order decides rank order". -/
theorem blockOffset_le_of_idxIn_lt (f : σ → Nat) {t t' : σ} :
    ∀ {l : List σ}, t ∈ l → idxIn t l < idxIn t' l →
      blockOffset f t l + f t ≤ blockOffset f t' l := by
  intro l
  induction l with
  | nil => intro h; cases h
  | cons u us ih =>
    intro hmem hlt
    by_cases h1 : u = t
    · by_cases h2 : u = t'
      · subst h1; subst h2
        exact absurd hlt (Nat.lt_irrefl _)
      · rw [blockOffset, if_pos h1, blockOffset, if_neg h2, Nat.zero_add,
          ← h1]
        exact Nat.le_add_right ..
    · by_cases h2 : u = t'
      · rw [idxIn, if_neg h1, idxIn, if_pos h2] at hlt
        omega
      · have hmem' : t ∈ us := by
          rcases List.mem_cons.mp hmem with rfl | h; exact absurd rfl h1; exact h
        rw [idxIn, if_neg h1, idxIn, if_neg h2] at hlt
        rw [blockOffset, if_neg h1, blockOffset, if_neg h2]
        have := ih hmem' (by omega)
        omega

/-- forward direction: lex-smaller valid paths rank strictly smaller.
    Head case: the whole earlier block precedes the later block's offset
    (`blockOffset_le_of_idxIn_lt`) and the in-block rank is bounded by
    the block mass (`rank_lt_count`); tail case: common offset cancels. -/
theorem rank_lt_of_O1Lt (D : LDP σ) {k : Nat} {s : σ} {u v : List σ}
    (hlt : O1Lt D k s u v) :
    IsValidPath D u k s → IsValidPath D v k s →
      rank D k s u < rank D k s v := by
  induction hlt with
  | @head k s t t' p q hidx =>
    intro hu hv
    cases hu with
    | cons ht hp =>
      cases hv with
      | cons ht' hq =>
        simp only [rank]
        have h1 : rank D k t p < count D k t := rank_lt_count D hp
        have h2 := blockOffset_le_of_idxIn_lt (count D k) ht hidx
        omega
  | tail _ ih =>
    intro hu hv
    cases hu with
    | cons ht hp =>
      cases hv with
      | cons ht' hq =>
        simp only [rank]
        have := ih hp hq
        omega

/-- `O1Lt` is total on valid paths of a common (length, root): trichotomy.
    Distinct heads are ordered because distinct candidates have distinct
    first-occurrence positions (`idxIn_ne`); equal heads recurse. -/
theorem O1Lt_trichotomy (D : LDP σ) :
    ∀ {k : Nat} {s : σ} {u v : List σ},
      IsValidPath D u k s → IsValidPath D v k s →
      O1Lt D k s u v ∨ u = v ∨ O1Lt D k s v u := by
  intro k
  induction k with
  | zero =>
    intro s u v hu hv
    cases hu; cases hv
    exact Or.inr (Or.inl rfl)
  | succ k ih =>
    intro s u v hu hv
    cases hu with
    | @cons _ _ t p ht hp =>
      cases hv with
      | @cons _ _ t' q ht' hq =>
        by_cases htt : t = t'
        · subst htt
          rcases ih hp hq with h | h | h
          · exact Or.inl (O1Lt.tail h)
          · exact Or.inr (Or.inl (h ▸ rfl))
          · exact Or.inr (Or.inr (O1Lt.tail h))
        · rcases Nat.lt_trichotomy (idxIn t (D.succs k s))
            (idxIn t' (D.succs k s)) with h | h | h
          · exact Or.inl (O1Lt.head h)
          · exact absurd h (idxIn_ne htt ht ht')
          · exact Or.inr (Or.inr (O1Lt.head h))

/-- **K3 order isomorphism, standalone-lex form.** Between valid paths,
    the reverse-choice lex order `O1Lt` (the doc's <_{O1}, stated with no
    reference to `paths`/`rank`) holds exactly when the rank is strictly
    smaller. Forward is `rank_lt_of_O1Lt`; backward is trichotomy plus
    the forward direction (a strict total order embeds, hence reflects). -/
theorem O1Lt_iff_rank_lt (D : LDP σ) {k : Nat} {s : σ} {u v : List σ}
    (hu : IsValidPath D u k s) (hv : IsValidPath D v k s) :
    O1Lt D k s u v ↔ rank D k s u < rank D k s v := by
  constructor
  · intro h; exact rank_lt_of_O1Lt D h hu hv
  · intro h
    rcases O1Lt_trichotomy D hu hv with hlt | rfl | hgt
    · exact hlt
    · exact absurd h (Nat.lt_irrefl _)
    · exact absurd (Nat.lt_trans h (rank_lt_of_O1Lt D hgt hv hu))
        (Nat.lt_irrefl _)

/-- the two order formulations agree: lex order between enumerated paths
    IS "earlier list position" (`O1Lt_iff_rank_lt` composed with
    `rank_strictMono`) — §A design decision 1, now a theorem. -/
theorem O1Lt_iff_position_lt (D : LDP σ) {k : Nat} {s : σ} {u v : List σ}
    {i j : Nat} (hu : (paths D k s)[i]? = some u)
    (hv : (paths D k s)[j]? = some v) :
    O1Lt D k s u v ↔ i < j := by
  rw [rank_strictMono D hu hv]
  exact O1Lt_iff_rank_lt D
    ((paths_complete D k s u).mp (List.mem_of_getElem? hu))
    ((paths_complete D k s v).mp (List.mem_of_getElem? hv))

/-! #### §B sanity witnesses (kernel-reduced: `rfl`/`decide` only — like
    §A's, these evaluate inside the kernel; nothing here relies on
    `native_decide`). Three instance scales: the §A toy (uniform blocks),
    a miniature with EMPTY blocks (a successor whose block mass is 0 —
    the budget-kill shape: `unrank` must scan past it, `rank` must charge
    it 0), and an n=9-scale-shaped instance (64-wide candidate list with
    a state-dependent kill, depth 2, 3,969 paths). -/

/-- unrank walks the enumeration in order... -/
example : unrank toyD 2 0 0 = some [0, 0] := rfl
example : unrank toyD 2 0 3 = some [1, 1] := rfl
/-- ...rejects exactly at `count` (`unrank_none_iff` instance)... -/
example : unrank toyD 2 0 4 = none := rfl
/-- ...and `rank` inverts it (round-trip instances, whole range). -/
example : rank toyD 2 0 [1, 0] = 2 := rfl
example : (List.range (count toyD 2 0)).map (unrank toyD 2 0)
    = (paths toyD 2 0).map some := rfl
example : (paths toyD 2 0).map (rank toyD 2 0) = List.range 4 := rfl
/-- lex-order instance: `[0,1] <_O1 [1,0]` (head decides), and rank
    agrees (`O1Lt_iff_rank_lt` instance). -/
example : O1Lt toyD 2 0 [0, 1] [1, 0] := O1Lt.head (by decide)
example : rank toyD 2 0 [0, 1] < rank toyD 2 0 [1, 0] := by decide

/-- empty-block miniature: `succs _ s = List.range s`, so from state 3 the
    successor 0 contributes an EMPTY block (`count _ 0 = 0` at depth 1) —
    the enumeration skips it, and rank/unrank must agree with that skip. -/
def miniD : LDP Nat where
  succs := fun _ s => List.range s
  succs_nodup := fun _ _ => List.nodup_range

example : paths miniD 2 3 = [[1, 0], [2, 0], [2, 1]] := rfl
example : count miniD 2 3 = 3 := rfl
example : (List.range 3).map (unrank miniD 2 3) = (paths miniD 2 3).map some := rfl
example : (paths miniD 2 3).map (rank miniD 2 3) = List.range 3 := rfl
example : unrank miniD 2 3 3 = none := rfl

/-- n=9-scale-shaped miniature: 64 candidates per level (the concrete
    DP's lc = 0..63 scan) with a state-dependent budget kill (candidates
    ≠ current state), depth 2: count = 63 × 63 = 3,969. -/
def wideD : LDP Nat where
  succs := fun _ s => (List.range 64).filter (· ≠ s)
  succs_nodup := fun _ _ => List.Sublist.nodup List.filter_sublist List.nodup_range

set_option maxRecDepth 8192 in
example : count wideD 2 0 = 63 * 63 := by decide
set_option maxRecDepth 8192 in
example : (unrank wideD 2 0 0).map (rank wideD 2 0) = some 0 := by decide
set_option maxRecDepth 8192 in
example : (unrank wideD 2 0 3968).map (rank wideD 2 0) = some 3968 := by decide
set_option maxRecDepth 8192 in
example : unrank wideD 2 0 (63 * 63) = none := by decide

/-! ### §D Build invariance (K2a core)

    The layer-assembly model (L6 + L7): each canonical target `t`
    contributes an entry block `emit t` that is a pure function of
    (previous layer, t) — per-target purity is L6, carried by KB1/KB2 —
    and the layer is those blocks concatenated in target-index order
    (offset table = prefix sums; `f1c5_write_layer`, L7). PROCESSING-ORDER
    invariance is the observation that no processing order appears in
    `assemble`'s definition at all: threads, scheduling, and serial-vs-
    parallel choose only WHICH worker computes each block and WHEN — the
    assembled list is a pure function of (emit, targets), so there is no
    order to be invariant TO. What deserves (and gets) a theorem is the
    flagship K2(a) clause: building any contiguous SLICES of the target
    list separately and merging them by target index reproduces the
    whole-run assembly byte-for-byte (`assemble_slices_merged`). KB3
    carries this from entry lists to serialized layer bytes. -/

variable {τ : Type v} {β : Type w}

/-- Layer assembly: per-target emissions concatenated in target-index
    order (the model of L7's two-pass offsets-then-write). -/
def assemble (emit : τ → List β) (targets : List τ) : List β :=
  targets.flatMap emit

/-- binary slice split: assembling a split target list = concatenating the
    two slice assemblies. -/
theorem assemble_append (emit : τ → List β) (ts us : List τ) :
    assemble emit (ts ++ us) = assemble emit ts ++ assemble emit us :=
  List.flatMap_append

/-- **K2(a) model core (merged-slices == whole-build).** For ANY
    decomposition of the target list into consecutive slices
    (`slices.flatten = targets`), building each slice separately and
    merging by target index yields exactly the whole-run assembly. -/
theorem assemble_slices_merged (emit : τ → List β) :
    ∀ {slices : List (List τ)} {targets : List τ},
      slices.flatten = targets →
      (slices.map (assemble emit)).flatten = assemble emit targets := by
  intro slices
  induction slices with
  | nil => intro targets h; rw [← h]; rfl
  | cons ts rest ih =>
    intro targets h
    rw [← h]
    simp only [List.map_cons, List.flatten_cons, assemble_append]
    rw [ih rfl]

/-- §D sanity witness (kernel `rfl`): a 2-slice split of a 3-target build. -/
example : ([[1], [2, 3]].map (assemble fun t => [t, 10 * t])).flatten
    = assemble (fun t => [t, 10 * t]) [1, 2, 3] := rfl

/-! ### §E Record composition (K2c core)

    K2(c) composes two machine-checked layers: (i) the record artifact is
    a pure, monotone function of the visited-key set — proven in
    `RecordConvention.lean` (v4-canonical branch); (ii) rank-prefix
    visited families are monotone in the prefix length — the ONE fresh
    ingredient the proofs doc §3.3 identifies as needed from this side,
    definitional from the take-prefix formulation, proven fresh below.

    `RecordConvention.lean` does not exist on this (v4-compiler) branch,
    and house convention keeps proof files standalone (no imports), so the
    needed definitions and the two needed theorems are RESTATED here
    verbatim and re-proven from scratch (they are short); attribution on
    each. -/

variable {κ : Type v} {ρ : Type w} [DecidableEq κ]

/-- One-copy-per-distinct-key dedup of a key list (set-preserving —
    `mem_dedup` is the only property any theorem below consumes).
    Restated from RecordConvention.lean (v4-canonical branch), proven
    there; restated here for composition. -/
def dedup : List κ → List κ
  | [] => []
  | k :: ks => if k ∈ ks then dedup ks else k :: dedup ks

/-- Restated from RecordConvention.lean (v4-canonical branch), proven
    there; restated here for composition. -/
theorem mem_dedup {k : κ} : ∀ {l : List κ}, k ∈ dedup l ↔ k ∈ l
  | [] => Iff.rfl
  | a :: ks => by
    by_cases h : a ∈ ks
    · simp only [dedup, if_pos h]
      constructor
      · intro hm; exact List.mem_cons_of_mem a (mem_dedup.mp hm)
      · intro hm
        rcases List.mem_cons.mp hm with rfl | hm
        · exact mem_dedup.mpr h
        · exact mem_dedup.mpr hm
    · simp only [dedup, if_neg h]
      constructor
      · intro hm
        rcases List.mem_cons.mp hm with rfl | hm
        · exact List.mem_cons_self ..
        · exact List.mem_cons_of_mem a (mem_dedup.mp hm)
      · intro hm
        rcases List.mem_cons.mp hm with rfl | hm
        · exact List.mem_cons_self ..
        · exact List.mem_cons_of_mem a (mem_dedup.mpr hm)

/-- The v4 record artifact of a visited-key list: one record `(k, repr k)`
    per distinct visited key, `repr` an arbitrary PURE function.
    Restated from RecordConvention.lean (v4-canonical branch), proven
    there; restated here for composition. -/
def artifact (repr : κ → ρ) (visited : List κ) : List (κ × ρ) :=
  (dedup visited).map (fun k => (k, repr k))

/-- Restated from RecordConvention.lean (v4-canonical branch), proven
    there; restated here for composition. -/
theorem mem_artifact_iff {repr : κ → ρ} {visited : List κ} {k : κ} {r : ρ} :
    (k, r) ∈ artifact repr visited ↔ k ∈ visited ∧ r = repr k := by
  constructor
  · intro h
    rcases List.mem_map.mp h with ⟨k', hk', he⟩
    cases he
    exact ⟨mem_dedup.mp hk', rfl⟩
  · rintro ⟨hv, rfl⟩
    exact List.mem_map.mpr ⟨k, mem_dedup.mpr hv, rfl⟩

/-- **Record-level partition invariance (set form).** The artifact is a
    function of the visited-key SET: two slices/runs that visited the same
    keys — in any order, any multiplicity, any grouping — have the same
    record set.
    Restated from RecordConvention.lean (v4-canonical branch), proven
    there; restated here for composition. -/
theorem artifact_key_ext {repr : κ → ρ} {v₁ v₂ : List κ}
    (h : ∀ k, k ∈ v₁ ↔ k ∈ v₂) :
    ∀ x, x ∈ artifact repr v₁ ↔ x ∈ artifact repr v₂ := by
  intro ⟨k, r⟩
  rw [mem_artifact_iff, mem_artifact_iff, h k]

/-- **Nested extendability.** If the deeper run visits every key the
    shallower run visits, every record of the shallower artifact appears —
    with identical bytes — in the deeper artifact; deeper slices only ADD
    records.
    Restated from RecordConvention.lean (v4-canonical branch), proven
    there; restated here for composition. -/
theorem artifact_mono {repr : κ → ρ} {v₁ v₂ : List κ}
    (h : ∀ k, k ∈ v₁ → k ∈ v₂) :
    ∀ x, x ∈ artifact repr v₁ → x ∈ artifact repr v₂ := by
  intro ⟨k, r⟩ hx
  rcases mem_artifact_iff.mp hx with ⟨hk, rfl⟩
  exact mem_artifact_iff.mpr ⟨h k hk, rfl⟩

/-- take-prefixes of one list are ⊆-monotone in the prefix length
    (fresh helper, hand-rolled — core 4.31.0 has no `List.mem_take`). -/
theorem take_subset_take {α : Type u} :
    ∀ (l : List α) (N N' : Nat), N ≤ N' → ∀ x ∈ l.take N, x ∈ l.take N' := by
  intro l
  induction l with
  | nil => intro N N' _ x hx; rw [List.take_nil] at hx; cases hx
  | cons a t ih =>
    intro N N' hNN x hx
    cases N with
    | zero => rw [List.take_zero] at hx; cases hx
    | succ N =>
      cases N' with
      | zero => exact absurd hNN (Nat.not_succ_le_zero N)
      | succ N' =>
        rw [List.take_succ_cons] at hx ⊢
        rcases List.mem_cons.mp hx with rfl | hx'
        · exact List.mem_cons_self ..
        · exact List.mem_cons_of_mem a
            (ih N N' (Nat.le_of_succ_le_succ hNN) x hx')

/-- **Rank-prefix families are monotone (fresh, the K2(c) ingredient).**
    S_N := the first N paths in enumeration order — LITERALLY the paths
    of rank < N, by §B's `rank_eq_position` (rank = list position). Then
    N ≤ N' implies S_N ⊆ S_{N'} — definitional from the take-prefix
    formulation. -/
theorem rankPrefix_mono (D : LDP σ) (k : Nat) (s : σ) {N N' : Nat}
    (h : N ≤ N') :
    ∀ p ∈ (paths D k s).take N, p ∈ (paths D k s).take N' :=
  take_subset_take (paths D k s) N N' h

/-- **K2(c), composed.** The record artifact of a rank-prefix slice —
    visited keys = the keys of the first N emissions, for ANY pure key map
    `keyOf` (the orientation-mask adapter) and ANY pure representative
    `repr` — only grows as the prefix extends, with every already-present
    record byte-identical: `artifact_mono` (RecordConvention.lean, restated
    above) composed with `rankPrefix_mono`. -/
theorem artifact_rankPrefix_mono (repr : κ → ρ) (keyOf : List σ → κ)
    (D : LDP σ) (k : Nat) (s : σ) {N N' : Nat} (h : N ≤ N') :
    ∀ x, x ∈ artifact repr (((paths D k s).take N).map keyOf) →
         x ∈ artifact repr (((paths D k s).take N').map keyOf) :=
  artifact_mono (fun key hkey => by
    obtain ⟨p, hp, rfl⟩ := List.mem_map.mp hkey
    exact List.mem_map.mpr ⟨p, rankPrefix_mono D k s h p hp, rfl⟩)

/-! #### §E sanity witnesses (kernel-reduced). -/

/-- one record per distinct visited key, bytes = (k, repr k). -/
example : artifact (fun k => 100 + k) ([1, 2, 1] : List Nat)
    = [(2, 102), (1, 101)] := rfl

/-- a concrete rank-prefix monotonicity instance on the §A toy DP. -/
example : ∀ p ∈ (paths toyD 2 0).take 1, p ∈ (paths toyD 2 0).take 3 :=
  rankPrefix_mono toyD 2 0 (by decide)

/-! ### §C Equivariance / quotient — the L3/L4 core (final pass, 2026-07-16)

    The model of the proofs doc's L3 (G-equivariance of prefix counting)
    and L4 (orbit-quotient storage is lossless), in the Automorphism.lean
    discipline: abstract state maps `φ` carrying explicit equivariance
    HYPOTHESES; the concrete 2³¹-mask-level facts (the 24-coset action,
    64×64 isometry, pair closure) are far too large for kernel `decide`
    and stay RUNTIME-VERIFIED (KB5, `f1_build_group` hard-abort asserts on
    every build/query host), entering as section hypotheses exactly like
    the DFS B-facts.

    TWO HYPOTHESIS FORMS — the modeling decision, stated bluntly:

    (a) ORDER-PRESERVING (`OrdEquivariant`): the candidate scan at `φ s`
        is the φ-image of the scan at `s` AS A LIST — same order. This
        yields the strong results: `paths_equivariant` (one k-induction),
        and as corollaries `count_invariant` (the L3 model core),
        `rank_equivariant`, `unrank_equivariant` (positions transport
        through `getElem?_map`). Note the hypothesis does ALL the work:
        no injectivity of `φ` is assumed anywhere in (a).
    (b) PERM-ONLY (`PermEquivariant`): the scan at `φ s` is only a
        PERMUTATION of the φ-image. Count invariance survives
        (`count_invariant_perm`, sums are Perm-invariant), but rank
        equivariance is GENUINELY FALSE — witnessed below by a kernel
        counterexample (`flip` on `toyD`), not just left unproven.

    WHICH FORM THE RUNTIME WITNESSES CORRESPOND TO (load-bearing for the
    bridge): the mask-level G-action (KB5) is form (b). A group element
    ĝ maps the valid exits of a state to the valid exits of the mapped
    state (L3's bijection), but the descent re-scans candidates in its
    own fixed lc = 0..63 ascending order — ĝ-images are NOT scanned in
    ĝ-image order, so the scan is only Perm-equivariant. That is exactly
    enough: the compiler pulls only COUNTS through canonicalization
    (`f1c5_gather_target` maps stored λ back via ĝ⁻¹ and SUMS;
    `kc_flookup` reads a count at the canonical state) — `kc_rank` /
    `kc_unrank` always run in the query's own frame and never transport
    a rank through a group element. So L3/L4 consume precisely
    `count_invariant_perm` / `quotient_lookup_sound_perm`; the (a)-form
    theorems are the stronger model-level statements, available should a
    scan-order-preserving action ever be used. -/

/-- Order-preserving equivariance of a state map `φ` (form (a)): the
    candidate scan at `φ s` IS the φ-image of the scan at `s`, in the
    same order. -/
def OrdEquivariant (D : LDP σ) (φ : σ → σ) : Prop :=
  ∀ (k : Nat) (s : σ), D.succs k (φ s) = (D.succs k s).map φ

/-- **§C master lemma.** Under order-preserving equivariance the whole
    enumeration transports: `paths D k (φ s)` is the (elementwise)
    φ-image of `paths D k s` — same list, same order. One k-induction;
    every other (a)-form theorem is a corollary (the same architecture
    as §B's M1/M2). -/
theorem paths_equivariant (D : LDP σ) {φ : σ → σ} (hφ : OrdEquivariant D φ) :
    ∀ (k : Nat) (s : σ), paths D k (φ s) = (paths D k s).map (List.map φ) := by
  intro k
  induction k with
  | zero => intro _; rfl
  | succ k ih =>
    intro s
    calc paths D (k + 1) (φ s)
        = ((D.succs k s).map φ).flatMap (fun t => (paths D k t).map (t :: ·)) := by
          rw [paths, hφ k s]
      _ = (D.succs k s).flatMap (fun u => (paths D k (φ u)).map (φ u :: ·)) :=
          List.flatMap_map ..
      _ = (D.succs k s).flatMap
            (fun u => ((paths D k u).map (u :: ·)).map (List.map φ)) := by
          refine congrArg (List.flatMap · (D.succs k s)) (funext fun u => ?_)
          rw [ih u, List.map_map, List.map_map]
          rfl
      _ = ((D.succs k s).flatMap fun t => (paths D k t).map (t :: ·)).map
            (List.map φ) := List.map_flatMap.symm
      _ = (paths D (k + 1) s).map (List.map φ) := by rw [paths]

/-- **L3 model core (order-preserving form).** Count is invariant under
    an order-equivariant state map — corollary of `paths_equivariant`
    via K1(a) (`count_eq_paths_length`), no separate count induction. -/
theorem count_invariant (D : LDP σ) {φ : σ → σ} (hφ : OrdEquivariant D φ)
    (k : Nat) (s : σ) : count D k s = count D k (φ s) := by
  rw [count_eq_paths_length, count_eq_paths_length, paths_equivariant D hφ,
    List.length_map]

/-- membership transports: the φ-image of an enumerated path is
    enumerated at the mapped root. -/
theorem mem_paths_equivariant (D : LDP σ) {φ : σ → σ}
    (hφ : OrdEquivariant D φ) {k : Nat} {s : σ} {w : List σ}
    (hw : w ∈ paths D k s) : w.map φ ∈ paths D k (φ s) := by
  rw [paths_equivariant D hφ]
  exact List.mem_map.mpr ⟨w, hw, rfl⟩

/-- **K3 × L3 (rank equivariance, order-preserving form).** Relabeling
    the walk and the root leaves the rank unchanged — free from
    `paths_equivariant` + `getElem?_map` (positions transport), as the
    §C design notes predicted. FALSE under form (b); see the kernel
    counterexample below. -/
theorem rank_equivariant (D : LDP σ) {φ : σ → σ} (hφ : OrdEquivariant D φ)
    {k : Nat} {s : σ} {w : List σ} (hw : w ∈ paths D k s) :
    rank D k (φ s) (w.map φ) = rank D k s w := by
  apply rank_eq_position D
  rw [paths_equivariant D hφ, List.getElem?_map,
    rank_getElem? D ((paths_complete D k s w).mp hw), Option.map_some]

/-- **K3 × L3 (unrank equivariance, order-preserving form).** Unrank
    commutes with the relabeling on the WHOLE index range (including the
    out-of-range `none`s) — free from M1 + `paths_equivariant`. -/
theorem unrank_equivariant (D : LDP σ) {φ : σ → σ} (hφ : OrdEquivariant D φ)
    (k : Nat) (s : σ) (r : Nat) :
    unrank D k (φ s) r = (unrank D k s r).map (List.map φ) := by
  rw [unrank_eq_getElem?, unrank_eq_getElem?, paths_equivariant D hφ,
    List.getElem?_map]

/-! #### The perm-only form (form (b)) — the form the runtime's mask-level
    action actually satisfies (see the §C intro note). Count invariance
    survives; rank equivariance does not (counterexample in the witness
    block below). -/

/-- Perm-only equivariance (form (b)): the candidate scan at `φ s` is a
    PERMUTATION of the φ-image of the scan at `s` — same candidates, any
    order. This is what the mask-level 24-coset action satisfies (the
    descent re-scans lc = 0..63 ascending at the mapped state). -/
def PermEquivariant (D : LDP σ) (φ : σ → σ) : Prop :=
  ∀ (k : Nat) (s : σ), (D.succs k (φ s)).Perm ((D.succs k s).map φ)

/-- permuted `Nat` lists have equal sums (hand-rolled induction on the
    `Perm` derivation; core 4.31.0 has no `List.Perm.sum`). -/
theorem perm_sum : ∀ {l₁ l₂ : List Nat}, l₁.Perm l₂ → l₁.sum = l₂.sum := by
  intro l₁ l₂ h
  induction h with
  | nil => rfl
  | cons x _ ih => rw [List.sum_cons, List.sum_cons, ih]
  | swap x y l =>
    rw [List.sum_cons, List.sum_cons, List.sum_cons, List.sum_cons]
    omega
  | trans _ _ ih₁ ih₂ => exact ih₁.trans ih₂

/-- **L3 model core (perm-only form — the form the runtime instantiates,
    KB5).** Count is invariant under a perm-only equivariant state map:
    the recurrence's sum is Perm-invariant at each level. This one needs
    its own k-induction (no `paths` route: the enumerations at `s` and
    `φ s` genuinely differ as LISTS under form (b)). Rank equivariance is
    deliberately NOT stated here — it is false; see the counterexample. -/
theorem count_invariant_perm (D : LDP σ) {φ : σ → σ}
    (hφ : PermEquivariant D φ) :
    ∀ (k : Nat) (s : σ), count D k s = count D k (φ s) := by
  intro k
  induction k with
  | zero => intro _; rfl
  | succ k ih =>
    intro s
    simp only [count]
    rw [perm_sum ((hφ k s).map (count D k)), List.map_map]
    exact congrArg List.sum (List.map_congr_left fun t _ => ih t)

/-! #### L4: quotient-lookup soundness.

    The model of "orbit-quotient storage is lossless": the compiler
    stores per-canonical-representative data and answers arbitrary-state
    queries by canonicalizing first (`f1_canon` + `kc_flookup`). The
    canonicalizer enters ABSTRACTLY: a map `canon` together with the
    hypothesis that `canon m` always lies in the orbit of `m` under a
    family `G` of equivariant maps (ANY orbit element works — the doc's
    L4 remark that `f1_canon`'s deterministic first-min is one valid
    choice among many, by L3). The family is a `List (σ → σ)` of maps,
    each carrying its equivariance hypothesis — the 24-coset mask-level
    instantiation stays runtime-verified (KB5). `canon` idempotence
    (representative stability) is also runtime-carried (`f1_canon`
    F1_CHECKs) and is NOT consumed by the model theorem — the orbit
    hypothesis alone suffices. -/

/-- **L4 model core (order-preserving family).** Looking up the count at
    the canonical representative answers the query at `m` exactly. -/
theorem quotient_lookup_sound (D : LDP σ) {G : List (σ → σ)}
    (hG : ∀ φ ∈ G, OrdEquivariant D φ) {canon : σ → σ}
    (hcanon : ∀ m, ∃ φ ∈ G, canon m = φ m) (k : Nat) (m : σ) :
    count D k (canon m) = count D k m := by
  obtain ⟨φ, hφ, he⟩ := hcanon m
  rw [he]
  exact (count_invariant D (hG φ hφ) k m).symm

/-- **L4 model core (perm-only family — the form the runtime
    instantiates).** Same statement under the weaker (and
    runtime-accurate, KB5) perm-only hypothesis: quotient-lookup
    soundness needs only count invariance, never rank equivariance —
    which is exactly why the mask-level action's failure to preserve
    scan order costs the compiler nothing. -/
theorem quotient_lookup_sound_perm (D : LDP σ) {G : List (σ → σ)}
    (hG : ∀ φ ∈ G, PermEquivariant D φ) {canon : σ → σ}
    (hcanon : ∀ m, ∃ φ ∈ G, canon m = φ m) (k : Nat) (m : σ) :
    count D k (canon m) = count D k m := by
  obtain ⟨φ, hφ, he⟩ := hcanon m
  rw [he]
  exact (count_invariant_perm D (hG φ hφ) k m).symm

/-! #### §C sanity witnesses (kernel-reduced: `rfl`/`decide` only — like
    §A/§B's, nothing here relies on `native_decide`).

    Two instances: (1) a genuinely 2-state DP (`σ = Bool`) whose
    candidate order TRACKS the state (`[s, !s]`), so the bit-flip `not`
    is a nontrivial ORDER-PRESERVING bijection — the full (a)-form suite
    (paths/count/rank/unrank/quotient) checks in the kernel; (2) the §A
    toy (`toyD`, fixed candidate order `[0, 1]`) under the flip
    `fun s => 1 - s`, which is PERM-ONLY equivariant — count invariance
    holds by the (b)-form theorem, and rank equivariance FAILS by kernel
    `decide`: the counterexample the §C design notes demanded before
    anyone tries to salvage rank under a Perm hypothesis. -/

/-- 2-state toy DP with state-tracking candidate order: from `s` the
    scan is `[s, !s]` — "stay" listed before "flip". The bit-flip `not`
    maps the scan at `s` to the scan at `!s` IN ORDER. -/
def boolD : LDP Bool where
  succs := fun _ s => [s, !s]
  succs_nodup := fun _ s => by cases s <;> decide

/-- `not` is order-preserving equivariant for `boolD` — definitionally
    (`succs k (!s) = [!s, !!s] = [s, !s].map not`). -/
theorem boolD_not_ordEquivariant : OrdEquivariant boolD Bool.not :=
  fun _ _ => rfl

/-- the enumeration at `true`, explicitly... -/
example : paths boolD 2 true =
    [[true, true], [true, false], [false, false], [false, true]] := rfl
/-- ...and the enumeration at `false` IS its elementwise bit-flip, in
    the same order (`paths_equivariant` instance, kernel-checked). -/
example : paths boolD 2 false = (paths boolD 2 true).map (List.map Bool.not) :=
  paths_equivariant boolD boolD_not_ordEquivariant 2 true
/-- count invariance instance (`count_invariant`), and the value. -/
example : count boolD 3 true = count boolD 3 (!true) :=
  count_invariant boolD boolD_not_ordEquivariant 3 true
example : count boolD 3 true = 8 := rfl
/-- rank equivariance instance (`rank_equivariant`): flipping walk and
    root preserves the rank... -/
example : rank boolD 2 false ([true, false].map Bool.not)
    = rank boolD 2 true [true, false] :=
  rank_equivariant boolD boolD_not_ordEquivariant
    (show [true, false] ∈ paths boolD 2 true by decide)
example : rank boolD 2 true [true, false] = 1 := rfl
/-- ...and unrank commutes with the relabeling (`unrank_equivariant`),
    including out-of-range rejection. -/
example : unrank boolD 2 false 2 = (unrank boolD 2 true 2).map (List.map Bool.not) :=
  unrank_equivariant boolD boolD_not_ordEquivariant 2 true 2
example : unrank boolD 2 false 4 = none := rfl

/-- toy canonicalizer: every state's representative is `true` (each
    orbit of the family `[id, not]` is all of `Bool`). -/
def canonB : Bool → Bool := fun _ => true

/-- the whole family `[id, not]` is order-preserving equivariant for
    `boolD` (both members definitionally). -/
theorem boolG_ordEquivariant :
    ∀ φ ∈ [(id : Bool → Bool), Bool.not], OrdEquivariant boolD φ := by
  intro φ hφ
  rcases List.mem_cons.mp hφ with rfl | hφ
  · exact fun _ _ => rfl
  · rcases List.mem_cons.mp hφ with rfl | hφ
    · exact boolD_not_ordEquivariant
    · cases hφ

/-- `canonB` lands in the `[id, not]`-orbit of every state. -/
theorem canonB_in_orbit :
    ∀ m, ∃ φ ∈ [(id : Bool → Bool), Bool.not], canonB m = φ m := by
  intro m
  cases m
  · exact ⟨Bool.not, List.mem_cons_of_mem _ List.mem_cons_self, rfl⟩
  · exact ⟨id, List.mem_cons_self, rfl⟩

/-- `canonB` is idempotent — the representative-stability the runtime
    F1_CHECKs for `f1_canon` (KB5); NOT consumed by
    `quotient_lookup_sound` (the orbit hypothesis suffices), witnessed
    here only to mirror the runtime contract. -/
example : ∀ m, canonB (canonB m) = canonB m := fun _ => rfl

/-- **L4 witness**: looking up at the canonical representative answers
    the query at the non-canonical state (`quotient_lookup_sound`
    instance, kernel-checked)... -/
example : count boolD 3 (canonB false) = count boolD 3 false :=
  quotient_lookup_sound boolD boolG_ordEquivariant canonB_in_orbit 3 false
/-- ...concretely: both sides are 8. -/
example : count boolD 3 (canonB false) = 8 := rfl

/-- the §A toy under the flip `s ↦ 1 - s`: the scan at `flip s` is
    `[0, 1]` while the flipped scan is `[1, 0]` — equal as SETS, not as
    lists. Perm-only (form (b)). -/
def flip : Nat → Nat := fun s => 1 - s

/-- `flip` is perm-only equivariant for `toyD` (one transposition). -/
theorem toyD_flip_permEquivariant : PermEquivariant toyD flip :=
  fun _ _ => (List.Perm.swap 0 1 []).symm

/-- count invariance survives perm-only equivariance
    (`count_invariant_perm` instance)... -/
example : count toyD 2 0 = count toyD 2 (flip 0) :=
  count_invariant_perm toyD toyD_flip_permEquivariant 2 0

/-- ...but rank equivariance is GENUINELY FALSE under perm-only
    equivariance (kernel counterexample): the walk `[0]` from root `0`
    has rank 0, while its flip `[1]` from root `flip 0 = 1` has rank 1
    (`[1]` sits in the SECOND scan block at the mapped root, because the
    mapped scan is re-ordered). This is the §C design-note warning made
    checkable — and why the runtime never transports ranks through the
    (perm-only, KB5) mask-level action. -/
example : rank toyD 1 (flip 0) ([0].map flip) ≠ rank toyD 1 0 [0] := by decide

end CompilerCorrectness
