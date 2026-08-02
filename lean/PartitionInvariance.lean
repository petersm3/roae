-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  PartitionInvariance.lean — machine-checked partition-invariance (reproducibility)
  theorem for the enumeration/merge pipeline (2026-07-10).

  *** COMPILES CLEAN on Lean 4.31.0 (2026-07-10, x86_64 linux, core only —
  *** no mathlib, no lake project): `lean PartitionInvariance.lean` exits 0
  *** with zero errors/warnings; zero `sorry`, zero `axiom`, zero `admit`.
  *** The pinned toolchain is recorded in this directory's `lean-toolchain`
  *** (leanprover/lean4:v4.31.0). Written per the private design doc
  *** (roae-private R10_LEAN_PARTITION_DESIGN_2026_07_10); the draft's
  *** `-- CHECK:` API-uncertainty flags are resolved. Promoted from the
  *** private staging draft 2026-07-11 (operator-approved); solve.c cites
  *** below are by FUNCTION NAME, not line number (line numbers drift).

  Core Lean 4 only (no mathlib). Formalizes the mathematical core of
  documentation/PARTITION_INVARIANCE.md: the canonical merge is
  `dedupKeyFirst ∘ sortLe` — sort by a total order whose primary key is the
  canonical-class key, then keep the first record of each class — and under
  the four `MergeOrder` hypotheses its output is invariant to input order,
  partition choice, invocation grouping, and merge hierarchy.

  Main results (numbering follows the design doc §3):
  · T1 `merge_perm`            — merge is a function of the input MULTISET
    (readdir order, shard arrival order, and any-correct-sort-algorithm
    equivalence).
  · T2 `merge_spec`            — the output is sorted, has exactly one record
    per canonical class, each retained record is its class's le-least member
    of the input, and every input class is represented (SOLUTIONS_FORMAT.md's
    dedup semantics as a THEOREM, not an assumption).
  · T3 `partition_invariance`  — for ANY two partitions of a duplicate-free
    solution listing S into cells, merging the concatenated per-cell filters
    yields the same output (both equal merge S). Instantiated at take-d prefix
    cells this is the cross-depth exhaustion conjecture of
    PARTITION_INVARIANCE.md §4 — machine-checked at the model level.
  · T4 `merge_merge_append` (+ `merge_append_merge`, `merge_both`,
    `merge_append_congr`, `merge_map_merge_flatten`) — dedup placement
    irrelevance: pre-merging any shard subset, at any interior node of any
    aggregation tree, leaves the root output unchanged (per-thread hash-table
    dedup, shard-level dedup, Phase-B re-merges, --merge-layers composition).
  · T5 `grouping_invariance`   — the empirically-validated headline theorem
    (1 full-parallel invocation vs 56 single-branch invocations): the same
    cell family, regrouped/reordered arbitrarily, merges identically — for
    ANY deterministic per-cell shard function E (budgeted or exhaustive; this
    is why the 5.6T c34390c0 budgeted double-regression sha-matches, and why
    cross-depth BUDGETED runs are structurally NOT covered — different index
    families admit no common E, reproducing the prose doc's §3 scope
    restriction as a feature of the statement).
  · `dedupAdjacent_eq`         — code-faithfulness bridge: the pipeline's
    actual "collapse adjacent equal-key runs after sort" pass equals
    dedupKeyFirst on sorted input. This is the ONE theorem that consumes the
    `key_blocks` convexity hypothesis ("primary sort key is the masked
    bytes"), exactly as predicted by the design.
  · ROAE instantiation         — records as byte lists, the & 0xFC mask
    (byte = pair_index*4 + orient*2; the record-packing block in solve.c's
    `analyze_solution`), the two-tier comparator
    `recLe` mirroring compare_solutions (primary lex on masked bytes,
    secondary lex on full bytes), a proof that (recLe, mask) satisfies
    MergeOrder, take-d prefix cells `cellsOf` with `cellsOf_isPartition`,
    and the cross-depth corollary `cross_depth_invariance`.

  Bridge facts — the honest trust boundary (NOT machine-checked; they connect
  this abstract spec to solve.c and are cited, explicit modeling assumptions;
  design doc §5):
  · B1 (per-cell exhaustive completeness/determinism): under exhaustion,
    solve.c's enumeration of cell c processes exactly the valid records
    extending c's prefix (PARTITION_INVARIANCE.md §2.1). Tier-4 (verified
    reference enumerator) is the rung that would attack this.
  · B2 (content-addressed shards / union semantics): gathering shards yields
    the union of per-cell outputs, one file per prefix (§2.2).
  · B3 (min-selection at every dedup site): the kept representative per
    canonical class is the byte-wise least record among those processed —
    hash-insert replace-if-smaller (the "Lex-smallest record wins" block in
    solve.c's `analyze_solution`, mirrored in the tier-2 chunk-merge path;
    the enumerator's DFS workers are POSIX threads (pthreads), so insertion
    order depends on thread scheduling and replace-if-smaller is what makes
    the table contents scheduling-independent) and merge keep-first-after-
    sort (`external_merge_sort`'s streaming dedup via `compare_canonical`
    against the last-written record, SOLUTIONS_FORMAT.md). The keep-first-
    after-sort half is PROVED here (T2); the hash-table half is a code fact.
    B3 licenses modeling every dedup site with the same merge/min operator
    (T4).
  · B4 (serialization is a function): header + record stream contain no
    timestamps/build IDs (SOLUTIONS_FORMAT.md), so equal record lists give
    byte-identical solutions.bin files and equal sha256. Stated as narrative
    only — `congrArg sha` would be content-free and SHA-256 is not modeled.

  Given B1–B4 the theorems yield byte-identical canonical artifacts across
  any invocation grouping (T5), any partition/depth under exhaustion (T3),
  any merge hierarchy of the same scope (T4), and any shard order (T1).

  Attribution: developed with AI assistance (Claude, Anthropic). The
  mathematics here (sort determinism, min-per-class deduplication, partition
  counting) is elementary and standard — no novelty is claimed for the
  content; only this abstraction-to-pipeline mapping and the machine-checked
  formalization are the project's own work, to our knowledge (corrections
  welcome). Design: roae-private/R10_LEAN_PARTITION_DESIGN_2026_07_10.md;
  prose theorem: documentation/PARTITION_INVARIANCE.md.
-/

namespace PartitionInvariance

universe u v w

variable {α : Type u} {κ : Type v} [DecidableEq κ]
variable (le : α → α → Bool) (key : α → κ)

/-! ### §1 Sorting: hand-rolled insertion sort (design §4 L1 fallback path).

    The design's preferred path was core `List.mergeSort` + its shipped
    correctness lemmas; since exact lemma names/availability on the pinned
    4.31.0 toolchain could not be verified in this uncompiled pass, the
    self-contained fallback is used — it depends only on ubiquitous
    List.Perm / List.Pairwise API. T1 makes the two choices provably
    interchangeable anyway (any correct sort of the same comparator gives
    the same sorted sequence, by `sorted_perm_eq`). -/

/-- `Sorted le l`: every element is `le` every later element. -/
abbrev Sorted (l : List α) : Prop := l.Pairwise fun a b => le a b = true

/-- Insert `a` before the first element it is `le`. -/
def insertLe (a : α) : List α → List α
  | [] => [a]
  | b :: t => if le a b = true then a :: b :: t else b :: insertLe a t

/-- Insertion sort. -/
def sortLe : List α → List α
  | [] => []
  | a :: t => insertLe le a (sortLe t)

theorem insertLe_perm (a : α) (l : List α) : (insertLe le a l).Perm (a :: l) := by
  induction l with
  | nil => exact List.Perm.refl _
  | cons b t ih =>
    unfold insertLe
    by_cases h : le a b = true
    · rw [if_pos h]
    · rw [if_neg h]
      exact (ih.cons b).trans (List.Perm.swap a b t)

theorem mem_insertLe {a x : α} {l : List α} :
    x ∈ insertLe le a l ↔ x = a ∨ x ∈ l := by
  rw [(insertLe_perm le a l).mem_iff, List.mem_cons]

theorem sortLe_perm (l : List α) : (sortLe le l).Perm l := by
  induction l with
  | nil => exact List.Perm.refl _
  | cons a t ih => exact (insertLe_perm le a (sortLe le t)).trans (ih.cons a)

theorem le_refl_of_total (htot : ∀ a b, le a b = true ∨ le b a = true) (a : α) :
    le a a = true := by
  rcases htot a a with h | h <;> exact h

theorem sorted_insertLe
    (htot : ∀ a b, le a b = true ∨ le b a = true)
    (htrans : ∀ a b c, le a b = true → le b c = true → le a c = true)
    (a : α) {l : List α} (hs : Sorted le l) : Sorted le (insertLe le a l) := by
  induction l with
  | nil => simp [insertLe]
  | cons b t ih =>
    have hs' := List.pairwise_cons.mp hs
    unfold insertLe
    by_cases h : le a b = true
    · rw [if_pos h]
      refine List.pairwise_cons.mpr ⟨?_, hs⟩
      intro x hx
      rcases List.mem_cons.mp hx with rfl | hxt
      · exact h
      · exact htrans a b x h (hs'.1 x hxt)
    · rw [if_neg h]
      refine List.pairwise_cons.mpr ⟨?_, ih hs'.2⟩
      intro x hx
      rcases (mem_insertLe le).mp hx with rfl | hxt
      · rcases htot x b with h' | h'
        · exact absurd h' h
        · exact h'
      · exact hs'.1 x hxt

theorem sorted_sortLe
    (htot : ∀ a b, le a b = true ∨ le b a = true)
    (htrans : ∀ a b c, le a b = true → le b c = true → le a c = true)
    (l : List α) : Sorted le (sortLe le l) := by
  induction l with
  | nil => exact List.Pairwise.nil
  | cons a t ih => exact sorted_insertLe le htot htrans a ih

/-- Sorted filtering stays sorted (Pairwise restricted along a sublist). -/
theorem sorted_filter (p : α → Bool) {l : List α} (hs : Sorted le l) :
    Sorted le (l.filter p) :=
  -- CHECK(resolved 4.31.0): `List.Pairwise.sublist` exists; `List.filter_sublist`
  -- is a term with implicit args (not a function) — pass it unapplied.
  hs.sublist List.filter_sublist

/-- L2 of the design: two `le`-sorted lists that are permutations of each
    other are EQUAL (totality + antisymmetry-on-distinct; duplicates are
    fine — no Nodup hypothesis, robustness the design calls out). This is
    the "any correct sort algorithm produces the same sorted sequence" step
    of PARTITION_INVARIANCE.md §2.3. -/
theorem sorted_perm_eq
    (_ : ∀ a b, le a b = true ∨ le b a = true)
    (hanti : ∀ a b, le a b = true → le b a = true → a = b) :
    ∀ {l₁ l₂ : List α}, Sorted le l₁ → Sorted le l₂ → l₁.Perm l₂ → l₁ = l₂ := by
  intro l₁
  induction l₁ with
  | nil =>
    intro l₂ _ _ hp
    -- CHECK: core name `List.Perm.eq_nil : l ~ [] → l = []`.
    exact (hp.symm.eq_nil).symm
  | cons a t ih =>
    intro l₂ hs₁ hs₂ hp
    cases l₂ with
    | nil => exact absurd hp.eq_nil (by simp)
    | cons b t₂ =>
      have hab : a = b := by
        have ha2 : a ∈ b :: t₂ := hp.mem_iff.mp (by simp)
        have hb1 : b ∈ a :: t := hp.symm.mem_iff.mp (by simp)
        rcases List.mem_cons.mp ha2 with h | ha2t
        · exact h
        · rcases List.mem_cons.mp hb1 with h | hb1t
          · exact h.symm
          · exact hanti a b ((List.pairwise_cons.mp hs₁).1 b hb1t)
              ((List.pairwise_cons.mp hs₂).1 a ha2t)
      subst hab
      rw [ih (List.pairwise_cons.mp hs₁).2 (List.pairwise_cons.mp hs₂).2
        hp.cons_inv]

/-- Two duplicate-free lists with the same members are permutations.
    (Needed by T4 and the partition layer; hand-rolled — the mathlib name
    would be perm-of-nodup + set-ext, absent from core.) -/
theorem perm_of_nodup_same_mem [DecidableEq α] :
    ∀ {u v : List α}, u.Nodup → v.Nodup → (∀ x, x ∈ u ↔ x ∈ v) → u.Perm v := by
  intro u
  induction u with
  | nil =>
    intro v _ _ hm
    cases v with
    | nil => exact List.Perm.refl _
    | cons b t => exact absurd ((hm b).mpr (by simp)) (List.not_mem_nil)
  | cons a t ih =>
    intro v hu hv hm
    have hav : a ∈ v := (hm a).mp (by simp)
    -- CHECK: core name `List.perm_cons_erase : a ∈ l → l ~ a :: l.erase a`.
    -- If absent, hand-roll by induction on v (~20 lines).
    have hperm : v.Perm (a :: v.erase a) := List.perm_cons_erase hav
    have hnd := List.nodup_cons.mp hu
    have hve : (v.erase a).Nodup := hv.erase a
    have hmm : ∀ x, x ∈ t ↔ x ∈ v.erase a := by
      intro x
      constructor
      · intro hxt
        have hxa : x ≠ a := fun e => hnd.1 (e ▸ hxt)
        exact (List.mem_erase_of_ne hxa).mpr ((hm x).mp (List.mem_cons_of_mem a hxt))
      · intro hxe
        rcases List.mem_cons.mp ((hm x).mpr (List.mem_of_mem_erase hxe)) with rfl | hxt
        · exact absurd hxe hv.not_mem_erase
        · exact hxt
    exact ((ih hnd.2 hve hmm).cons a).trans hperm.symm

/-! ### §2 The trusted interface: the MergeOrder hypothesis bundle.

    Exactly the four properties argued in solve.c's "Record comparators:
    correctness proof" comment block (above `compare_solutions`) and
    SOLUTIONS_FORMAT.md §Sort order. Nothing about
    hexagrams, constraints, or 32-byte layouts appears here — those live
    only in the ROAE instantiation below. -/

/-- The comparator/key contract of the pipeline's compare_solutions /
    compare_canonical pair. `le` is the Boolean total-preorder test; `key`
    is the canonical-class key (concretely the & 0xFC byte mask). -/
structure MergeOrder (le : α → α → Bool) (key : α → κ) : Prop where
  /-- totality (in the ≤ sense). -/
  total : ∀ a b, le a b = true ∨ le b a = true
  /-- ≤ both ways forces byte-identity: the secondary key is the full record. -/
  antisymm_distinct : ∀ a b, le a b = true → le b a = true → a = b
  /-- transitivity. -/
  trans : ∀ a b c, le a b = true → le b c = true → le a c = true
  /-- canonical classes are CONVEX in the order (primary key = masked bytes):
      anything sandwiched between two class members is in the class. Consumed
      by `dedupAdjacent_eq` (code-faithfulness of adjacent-run dedup); the
      abstract T1–T5 hold without it. -/
  key_blocks : ∀ a b c, le a b = true → le b c = true → key a = key c →
    key a = key b

/-! ### §3 Dedup and merge. -/

/-- Keep the FIRST record of each key class, preserving order (on sorted
    input this is the pipeline's per-class representative; T2 proves it is
    the class's le-minimum). The recursion filters the head's whole class
    out of the tail, so it is well-defined on unsorted input too. -/
def dedupKeyFirst : List α → List α
  | [] => []
  | a :: t => a :: dedupKeyFirst (t.filter fun x => decide (key x ≠ key a))
  termination_by l => l.length
  decreasing_by
    -- the WF preprocessor auto-attaches the filter argument, so the goal is
    -- stated over (t.attach.filter …).unattach; flatten the lengths first.
    simp only [List.length_cons, List.length_unattach]
    exact Nat.lt_succ_of_le (Nat.le_trans (List.length_filter_le _ _)
      (Nat.le_of_eq List.length_attach))

/-- THE pipeline merge: sort by the two-tier comparator, keep the first
    (= least) record of each canonical class. A pure function of its input
    list — every theorem below is about which inputs it identifies. -/
def merge (l : List α) : List α := dedupKeyFirst key (sortLe le l)

/-- dedup output is a sublist (hence subset, hence order-preserving). -/
theorem dedup_sublist : ∀ l : List α, (dedupKeyFirst key l).Sublist l
  | [] => by simp [dedupKeyFirst]
  | a :: t => by
    simp only [dedupKeyFirst]
    exact (((dedup_sublist (t.filter fun x => decide (key x ≠ key a))).trans
      List.filter_sublist)).cons_cons a
  termination_by l => l.length
  decreasing_by
    simp only [List.length_cons]
    exact Nat.lt_succ_of_le (List.length_filter_le _ t)

theorem dedup_subset {l : List α} : ∀ x ∈ dedupKeyFirst key l, x ∈ l :=
  fun _ hx => (dedup_sublist key l).subset hx

theorem sorted_dedup {l : List α} (hs : Sorted le l) :
    Sorted le (dedupKeyFirst key l) :=
  hs.sublist (dedup_sublist key l)

/-- one representative per class: all retained keys are pairwise distinct. -/
theorem dedup_pairwise_keyNe :
    ∀ l : List α, (dedupKeyFirst key l).Pairwise fun a b => key a ≠ key b
  | [] => by simp [dedupKeyFirst]
  | a :: t => by
    simp only [dedupKeyFirst]
    refine List.pairwise_cons.mpr
      ⟨?_, dedup_pairwise_keyNe (t.filter fun x => decide (key x ≠ key a))⟩
    intro b hb
    have hbf : b ∈ t.filter fun x => decide (key x ≠ key a) :=
      dedup_subset key b hb
    have hne : key b ≠ key a := of_decide_eq_true (List.mem_filter.mp hbf).2
    exact fun e => hne e.symm
  termination_by l => l.length
  decreasing_by
    simp only [List.length_cons]
    exact Nat.lt_succ_of_le (List.length_filter_le _ t)

theorem dedup_nodup (l : List α) : (dedupKeyFirst key l).Nodup :=
  (dedup_pairwise_keyNe key l).imp fun hne he => hne (congrArg key he)

/-- On SORTED input every retained record is the le-least member of its
    class among the input (first-of-class in sorted order = class min;
    needs only sortedness + totality — the head case is the head bound,
    the tail case recurses into the filtered tail, where the whole class
    survives because the filter only removes the head's class). -/
theorem dedup_min (htot : ∀ a b, le a b = true ∨ le b a = true)
    (l : List α) :
    Sorted le l →
      ∀ a ∈ dedupKeyFirst key l, ∀ b ∈ l, key b = key a → le a b = true := by
  match l with
  | [] => intro _ a ha; simp [dedupKeyFirst] at ha
  | c :: t =>
    intro hs a ha b hb hk
    simp only [dedupKeyFirst] at ha
    have hs' := List.pairwise_cons.mp hs
    rcases List.mem_cons.mp ha with rfl | hat
    · -- a is the head: le a a by refl, le a b for b ∈ t by the head bound
      rcases List.mem_cons.mp hb with rfl | hbt
      · exact le_refl_of_total le htot b
      · exact hs'.1 b hbt
    · -- a lives in the deduped filtered tail
      have haf : a ∈ t.filter fun x => decide (key x ≠ key c) :=
        dedup_subset key a hat
      have hka : key a ≠ key c := of_decide_eq_true (List.mem_filter.mp haf).2
      rcases List.mem_cons.mp hb with rfl | hbt
      · exact absurd hk.symm hka
      · have hbf : b ∈ t.filter fun x => decide (key x ≠ key c) :=
          List.mem_filter.mpr ⟨hbt, decide_eq_true fun e => hka (hk.symm.trans e)⟩
        exact dedup_min htot (t.filter fun x => decide (key x ≠ key c))
          (sorted_filter le _ hs'.2) a hat b hbf hk
  termination_by l.length
  decreasing_by
    simp only [List.length_cons]
    exact Nat.lt_succ_of_le (List.length_filter_le _ t)

/-- every input class is represented in the dedup output. -/
theorem dedup_covers (l : List α) :
    ∀ b ∈ l, ∃ a ∈ dedupKeyFirst key l, key a = key b := by
  match l with
  | [] => intro b hb; cases hb
  | c :: t =>
    intro b hb
    by_cases hk : key b = key c
    · exact ⟨c, by simp [dedupKeyFirst], hk.symm⟩
    · rcases List.mem_cons.mp hb with rfl | hbt
      · exact absurd rfl hk
      · have hbf : b ∈ t.filter fun x => decide (key x ≠ key c) :=
          List.mem_filter.mpr ⟨hbt, decide_eq_true hk⟩
        obtain ⟨a, ha, hka⟩ :=
          dedup_covers (t.filter fun x => decide (key x ≠ key c)) b hbf
        refine ⟨a, ?_, hka⟩
        simp only [dedupKeyFirst]
        exact List.mem_cons_of_mem c ha
  termination_by l.length
  decreasing_by
    simp only [List.length_cons]
    exact Nat.lt_succ_of_le (List.length_filter_le _ t)

/-! ### §4 T1 — merge is a multiset invariant (input-order irrelevance). -/

/-- **T1.** Permuted inputs merge identically: readdir-order insensitivity,
    shard gathering in any order, and (via `sorted_perm_eq`) equivalence of
    any correct sort algorithm over the same comparator — in-memory qsort vs
    external merge-sort vs heapsort (PARTITION_INVARIANCE.md §2.3). -/
theorem merge_perm (h : MergeOrder le key) {l₁ l₂ : List α} (hp : l₁.Perm l₂) :
    merge le key l₁ = merge le key l₂ := by
  unfold merge
  exact congrArg (dedupKeyFirst key) <| sorted_perm_eq le h.total h.antisymm_distinct
    (sorted_sortLe le h.total h.trans l₁) (sorted_sortLe le h.total h.trans l₂)
    (((sortLe_perm le l₁).trans hp).trans (sortLe_perm le l₂).symm)

/-! ### §5 T2 — content characterization: what the canonical file IS. -/

theorem merge_sorted (h : MergeOrder le key) (l : List α) :
    Sorted le (merge le key l) :=
  sorted_dedup le key (sorted_sortLe le h.total h.trans l)

theorem merge_pairwise_keyNe (l : List α) :
    (merge le key l).Pairwise fun a b => key a ≠ key b :=
  dedup_pairwise_keyNe key (sortLe le l)

theorem merge_nodup (l : List α) : (merge le key l).Nodup :=
  dedup_nodup key (sortLe le l)

theorem merge_subset {l : List α} : ∀ a ∈ merge le key l, a ∈ l :=
  fun a ha => (sortLe_perm le l).mem_iff.mp (dedup_subset key a ha)

/-- each retained record is the le-least member of its class in the input. -/
theorem merge_min (h : MergeOrder le key) {l : List α} :
    ∀ a ∈ merge le key l, ∀ b ∈ l, key b = key a → le a b = true :=
  fun a ha b hb hk =>
    dedup_min le key h.total (sortLe le l)
      (sorted_sortLe le h.total h.trans l) a ha b
      ((sortLe_perm le l).mem_iff.mpr hb) hk

/-- every input class is represented in the output. -/
theorem merge_covers {l : List α} :
    ∀ b ∈ l, ∃ a ∈ merge le key l, key a = key b :=
  fun b hb => dedup_covers key (sortLe le l) b ((sortLe_perm le l).mem_iff.mpr hb)

/-- **T2** (bundled form of the design doc). SOLUTIONS_FORMAT.md's dedup
    semantics — "exactly one record per canonical class, the
    lexicographically smallest orient variant" — as a machine-checked
    consequence of sort + keep-first. Closes the "does keep-first really
    give lex-min?" gap: yes, because the secondary sort key is the full
    record (`antisymm_distinct`). -/
theorem merge_spec (h : MergeOrder le key) (l : List α) :
    Sorted le (merge le key l)
      ∧ ((merge le key l).Pairwise fun a b => key a ≠ key b)
      ∧ (∀ a ∈ merge le key l, a ∈ l ∧ ∀ b ∈ l, key b = key a → le a b = true)
      ∧ (∀ b ∈ l, ∃ a ∈ merge le key l, key a = key b) :=
  ⟨merge_sorted le key h l, merge_pairwise_keyNe le key l,
    fun a ha => ⟨merge_subset le key a ha, merge_min le key h a ha⟩,
    merge_covers le key⟩

/-- exact membership characterization: the merge output contains precisely
    the inputs that are le-minimal within their class. (The converse
    direction pins the retained representative down via antisymmetry.) -/
theorem mem_merge_iff (h : MergeOrder le key) {l : List α} {x : α} :
    x ∈ merge le key l ↔
      x ∈ l ∧ ∀ b ∈ l, key b = key x → le x b = true := by
  constructor
  · intro hx
    exact ⟨merge_subset le key x hx, merge_min le key h x hx⟩
  · rintro ⟨hxl, hmin⟩
    obtain ⟨a, ha, hka⟩ := merge_covers le key x hxl
    have h1 : le x a = true := hmin a (merge_subset le key a ha) hka
    have h2 : le a x = true := merge_min le key h a ha x hxl hka.symm
    have e : x = a := h.antisymm_distinct x a h1 h2
    rw [e]
    exact ha

/-! ### §6 T4 — merge-hierarchy invariance (dedup placement irrelevance).

    Min-selection is an idempotent, commutative, associative aggregation
    (design §1, bridge fact B3): dedup may happen at any intermediate point
    — per-thread hash table, per-cell shard, final merge, Phase-B re-merge
    of archived shards, --merge-layers composition — without changing the
    final bytes. -/

/-- being class-minimal over `merge A ++ B` transfers down to `A ++ B`
    (route the class through A's retained representative + transitivity). -/
theorem min_transfer_down (h : MergeOrder le key)
    {A B : List α} {x : α}
    (hmin : ∀ b ∈ merge le key A ++ B, key b = key x → le x b = true) :
    ∀ b ∈ A ++ B, key b = key x → le x b = true := by
  intro b hb hk
  rcases List.mem_append.mp hb with hbA | hbB
  · obtain ⟨a, ha, hka⟩ := merge_covers le key b hbA
    have hab : le a b = true := merge_min le key h a ha b hbA hka.symm
    have hxa : le x a = true :=
      hmin a (List.mem_append.mpr (Or.inl ha)) (hka.trans hk)
    exact h.trans x a b hxa hab
  · exact hmin b (List.mem_append.mpr (Or.inr hbB)) hk

/-- ...and transfers back up (merge A's members are members of A). -/
theorem min_transfer_up (_ : MergeOrder le key) {A B : List α} {x : α}
    (hmin : ∀ b ∈ A ++ B, key b = key x → le x b = true) :
    ∀ b ∈ merge le key A ++ B, key b = key x → le x b = true := by
  intro b hb hk
  rcases List.mem_append.mp hb with hbM | hbB
  · exact hmin b (List.mem_append.mpr (Or.inl (merge_subset le key b hbM))) hk
  · exact hmin b (List.mem_append.mpr (Or.inr hbB)) hk

/-- **T4.** Pre-merging the left shard block changes nothing: the formal
    content of solve.c's comparator-correctness proof sketch steps (1)–(3),
    made true by bridge fact B3 ("Lex-smallest record wins"). -/
theorem merge_merge_append [DecidableEq α] (h : MergeOrder le key)
    (A B : List α) :
    merge le key (merge le key A ++ B) = merge le key (A ++ B) := by
  have hmem : ∀ x, x ∈ merge le key (merge le key A ++ B) ↔
      x ∈ merge le key (A ++ B) := by
    intro x
    rw [mem_merge_iff le key h, mem_merge_iff le key h]
    constructor
    · rintro ⟨hx, hmin⟩
      have hmin' := min_transfer_down le key h hmin
      rcases List.mem_append.mp hx with hxM | hxB
      · exact ⟨List.mem_append.mpr (Or.inl (merge_subset le key x hxM)), hmin'⟩
      · exact ⟨List.mem_append.mpr (Or.inr hxB), hmin'⟩
    · rintro ⟨hx, hmin⟩
      refine ⟨?_, min_transfer_up le key h hmin⟩
      rcases List.mem_append.mp hx with hxA | hxB
      · -- x is class-minimal over A ++ B, hence over A, hence retained in merge A
        have hxM : x ∈ merge le key A := by
          rw [mem_merge_iff le key h]
          exact ⟨hxA, fun b hb hk => hmin b (List.mem_append.mpr (Or.inl hb)) hk⟩
        exact List.mem_append.mpr (Or.inl hxM)
      · exact List.mem_append.mpr (Or.inr hxB)
  exact sorted_perm_eq le h.total h.antisymm_distinct
    (merge_sorted le key h _) (merge_sorted le key h _)
    (perm_of_nodup_same_mem (merge_nodup le key _) (merge_nodup le key _) hmem)

/-- T4, right-hand version (free via T1 + append commutation). -/
theorem merge_append_merge [DecidableEq α] (h : MergeOrder le key)
    (A B : List α) :
    merge le key (A ++ merge le key B) = merge le key (A ++ B) := by
  -- CHECK: core name `List.perm_append_comm : l₁ ++ l₂ ~ l₂ ++ l₁`.
  rw [merge_perm le key h (List.perm_append_comm),
    merge_merge_append le key h B A,
    merge_perm le key h (List.perm_append_comm)]

/-- T4, both sides pre-merged. -/
theorem merge_both [DecidableEq α] (h : MergeOrder le key) (A B : List α) :
    merge le key (merge le key A ++ merge le key B) = merge le key (A ++ B) := by
  rw [merge_merge_append le key h, merge_append_merge le key h]

/-- merge-equal shard blocks are interchangeable under any common prefix —
    the congruence that powers the aggregation-tree corollary. -/
theorem merge_append_congr [DecidableEq α] (h : MergeOrder le key)
    {A B₁ B₂ : List α} (e : merge le key B₁ = merge le key B₂) :
    merge le key (A ++ B₁) = merge le key (A ++ B₂) := by
  rw [← merge_append_merge le key h A B₁, e, merge_append_merge le key h A B₂]

/-- **T4 corollary** (aggregation trees): pre-merging every shard before the
    final merge — hence, by iteration, interposing merge at ANY interior
    node of any merge hierarchy — leaves the root output unchanged. -/
theorem merge_map_merge_flatten [DecidableEq α] (h : MergeOrder le key)
    (shards : List (List α)) :
    merge le key ((shards.map (merge le key)).flatten) =
      merge le key shards.flatten := by
  induction shards with
  | nil => rfl
  | cons s ss ih =>
    simp only [List.map_cons, List.flatten_cons]
    rw [merge_merge_append le key h, merge_append_congr le key h ih]

/-! ### §7 Code-faithfulness bridge: adjacent-run dedup = first-per-class.

    The C merge dedups by collapsing ADJACENT equal-key runs after the sort
    (`external_merge_sort`'s dedup via `compare_canonical` against the
    last-written record). `dedupKeyFirst` filters the head's class globally.
    On sorted input under `key_blocks` (classes are convex in the order, so
    key-runs are contiguous) the two coincide — this is the one theorem that
    consumes the convexity hypothesis, and it is what licenses modeling the
    pipeline's pass with `dedupKeyFirst` in the first place. -/

/-- Collapse adjacent equal-key records, keeping the earlier one. -/
def dedupAdjacent : List α → List α
  | [] => []
  | [a] => [a]
  | a :: b :: t =>
    if key a = key b then dedupAdjacent (a :: t) else a :: dedupAdjacent (b :: t)
  termination_by l => l.length
  decreasing_by
    all_goals simp only [List.length_cons]
    all_goals omega

theorem dedupAdjacent_eq (h : MergeOrder le key) (l : List α) :
    Sorted le l → dedupAdjacent key l = dedupKeyFirst key l := by
  match l with
  | [] => intro _; simp [dedupAdjacent, dedupKeyFirst]
  | [a] => intro _; simp [dedupAdjacent, dedupKeyFirst]
  | a :: b :: t =>
    intro hs
    have hs' := List.pairwise_cons.mp hs
    by_cases hk : key a = key b
    · -- b is a's class-mate: both sides drop b
      simp only [dedupAdjacent]
      rw [if_pos hk]
      have hsat : Sorted le (a :: t) := by
        refine List.pairwise_cons.mpr ⟨?_, (List.pairwise_cons.mp hs'.2).2⟩
        intro x hx
        exact hs'.1 x (List.mem_cons_of_mem b hx)
      rw [dedupAdjacent_eq h (a :: t) hsat]
      simp only [dedupKeyFirst]
      congr 1
      -- (b :: t).filter (key · ≠ key a) = t.filter (key · ≠ key a): b is dropped
      -- CHECK(resolved 4.31.0): plain `simp [hk.symm]` reduces the filter cons
      -- step itself; the explicit List.filter_cons argument was unused.
      simp [hk.symm]
    · -- class boundary: key_blocks says NOTHING later shares a's class,
      -- so the global filter is the identity on b :: t
      simp only [dedupAdjacent]
      rw [if_neg hk]
      have hfid : ((b :: t).filter fun x => decide (key x ≠ key a)) = b :: t := by
        -- CHECK: core name `List.filter_eq_self : l.filter p = l ↔ ∀ a ∈ l, p a = true`.
        apply List.filter_eq_self.mpr
        intro x hx
        apply decide_eq_true
        rcases List.mem_cons.mp hx with rfl | hxt
        · exact fun e => hk e.symm
        · intro e
          -- e : key x = key a; sandwich a ≤ b ≤ x with key a = key x
          exact hk (h.key_blocks a b x (hs'.1 b (by simp))
            ((List.pairwise_cons.mp hs'.2).1 x hxt) e.symm)
      rw [dedupAdjacent_eq h (b :: t) hs'.2]
      simp only [dedupKeyFirst, hfid]
  termination_by l.length
  decreasing_by
    all_goals simp only [List.length_cons]
    all_goals omega

/-! ### §8 Partitions (design §2.3, §4 L7–L8).

    A partition is a list of Boolean cell predicates such that every solution
    lands in EXACTLY one cell (countP = 1). Exhaustive per-cell enumeration
    of cell c is modeled as `S.filter c` over a fixed duplicate-free solution
    listing S (bridge fact B1 supplies the connection to solve.c). -/

/-- every member of S satisfies exactly one cell predicate. -/
def IsPartition (C : List (α → Bool)) (S : List α) : Prop :=
  ∀ x ∈ S, C.countP (fun c => c x) = 1

/-- a positive countP has a witness (hand-rolled; keeps the file free of
    uncertain core countP-existence names). -/
theorem exists_of_countP_pos {β : Type v} {p : β → Bool} :
    ∀ {l : List β}, 0 < l.countP p → ∃ c ∈ l, p c = true := by
  intro l
  induction l with
  | nil => intro hpos; simp [List.countP_nil] at hpos
  | cons c t ih =>
    intro hpos
    by_cases hc : p c = true
    · exact ⟨c, by simp, hc⟩
    · rw [List.countP_cons_of_neg hc] at hpos
      obtain ⟨d, hd, hpd⟩ := ih hpos
      exact ⟨d, List.mem_cons_of_mem c hd, hpd⟩

/-- a witness forces countP ≥ 1. -/
theorem one_le_countP_of_mem {β : Type v} {p : β → Bool} {c : β} :
    ∀ {l : List β}, c ∈ l → p c = true → 1 ≤ l.countP p := by
  intro l
  induction l with
  | nil => intro h; cases h
  | cons d t ih =>
    intro hc hpc
    rcases List.mem_cons.mp hc with rfl | hct
    · rw [List.countP_cons_of_pos hpc]; omega
    · by_cases hd : p d = true
      · rw [List.countP_cons_of_pos hd]; omega
      · rw [List.countP_cons_of_neg hd]; exact ih hct hpc

/-- disjoint duplicate-free lists concatenate duplicate-free (hand-rolled;
    avoids relying on a core `List.nodup_append` iff shape). -/
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

/-- at-most-one-cell membership makes the concatenated per-cell filters
    duplicate-free (cells contribute disjoint slices of a Nodup S). -/
theorem nodup_flatMap_filter {S : List α} (hS : S.Nodup) :
    ∀ {C : List (α → Bool)}, (∀ x ∈ S, C.countP (fun c => c x) ≤ 1) →
      (C.flatMap fun c => S.filter c).Nodup := by
  intro C
  induction C with
  | nil => intro _; simp
  | cons c C' ih =>
    intro hle
    simp only [List.flatMap_cons]
    apply nodup_append_of_disjoint
    · -- CHECK: core name `List.Nodup.filter (p) : l.Nodup → (l.filter p).Nodup`.
      exact hS.filter c
    · exact ih fun x hx => by
        have := hle x hx
        by_cases hcx : c x = true
        · rw [List.countP_cons_of_pos (p := fun c : α → Bool => c x) hcx] at this
          omega
        · rw [List.countP_cons_of_neg (p := fun c : α → Bool => c x) hcx] at this
          omega
    · -- disjointness: two containing cells would give countP ≥ 2 > 1
      intro x hxc hxC'
      have hcx : c x = true := (List.mem_filter.mp hxc).2
      have hxS : x ∈ S := (List.mem_filter.mp hxc).1
      -- CHECK: core name `List.mem_flatMap : a ∈ l.flatMap f ↔ ∃ b ∈ l, a ∈ f b`.
      obtain ⟨c', hc', hxc'⟩ := List.mem_flatMap.mp hxC'
      have hc'x : c' x = true := (List.mem_filter.mp hxc').2
      have h1 : 1 ≤ C'.countP (fun c => c x) :=
        one_le_countP_of_mem hc' hc'x
      have h2 := hle x hxS
      rw [List.countP_cons_of_pos (p := fun c : α → Bool => c x) hcx] at h2
      omega

/-- **L7.** For a partition of a duplicate-free listing S, the concatenated
    per-cell filters are a PERMUTATION of S — the union-of-shards input to
    the final merge is, up to order (which T1 erases), the solution set
    itself. -/
theorem partition_flatMap_perm [DecidableEq α] {C : List (α → Bool)}
    {S : List α} (hC : IsPartition C S) (hS : S.Nodup) :
    (C.flatMap fun c => S.filter c).Perm S := by
  apply perm_of_nodup_same_mem
  · exact nodup_flatMap_filter hS fun x hx => Nat.le_of_eq (hC x hx)
  · exact hS
  · intro x
    rw [List.mem_flatMap]
    constructor
    · rintro ⟨c, _, hxf⟩
      exact (List.mem_filter.mp hxf).1
    · intro hxS
      have hcount := hC x hxS
      obtain ⟨c, hc, hcx⟩ := exists_of_countP_pos (p := fun c : α → Bool => c x)
        (by rw [hcount]; exact Nat.zero_lt_one)
      exact ⟨c, hc, List.mem_filter.mpr ⟨hxS, hcx⟩⟩

/-- sharper form of T3: any partition's gathered shards merge to merge S. -/
theorem partition_merge_eq [DecidableEq α] (h : MergeOrder le key)
    {C : List (α → Bool)} {S : List α} (hC : IsPartition C S) (hS : S.Nodup) :
    merge le key (C.flatMap fun c => S.filter c) = merge le key S :=
  merge_perm le key h (partition_flatMap_perm hC hS)

/-- **T3 — partition invariance proper** (the §1/§4 theorem of
    PARTITION_INVARIANCE.md, exhaustive scope). Two genuinely different cell
    families over the same duplicate-free solution listing produce the same
    merged canonical output. Instantiated at prefix-cell families of two
    different depths (see `cross_depth_invariance` below) this is exactly
    the cross-depth exhaustion conjecture — "not empirically verified …
    remains a conjecture" in the prose doc — machine-checked at the model
    level. Budgeted runs break the `IsPartition`/filter hypothesis (a
    budgeted cell shard is NOT `S.filter c`), reproducing the prose §3
    scope restriction. -/
theorem partition_invariance [DecidableEq α] (h : MergeOrder le key)
    (S : List α) (hS : S.Nodup) (C₁ C₂ : List (α → Bool))
    (h₁ : IsPartition C₁ S) (h₂ : IsPartition C₂ S) :
    merge le key (C₁.flatMap fun c => S.filter c) =
      merge le key (C₂.flatMap fun c => S.filter c) := by
  rw [partition_merge_eq le key h h₁ hS, partition_merge_eq le key h h₂ hS]

/-! ### §9 T5 — grouping invariance (the empirically-validated headline). -/

/-- Perm congruence for flatMap (hand-rolled by induction on the Perm
    derivation; design §4 L5 fallback). -/
theorem perm_flatMap {ι : Type w} (E : ι → List α) :
    ∀ {G₁ G₂ : List ι}, G₁.Perm G₂ → (G₁.flatMap E).Perm (G₂.flatMap E) := by
  intro G₁ G₂ hp
  induction hp with
  | nil => exact List.Perm.refl _
  | cons x _ ih =>
    simp only [List.flatMap_cons]
    -- CHECK: core name `List.Perm.append_left (l) : l₁ ~ l₂ → l ++ l₁ ~ l ++ l₂`.
    exact ih.append_left (E x)
  | swap x y l =>
    simp only [List.flatMap_cons]
    rw [← List.append_assoc, ← List.append_assoc]
    -- CHECK: core name `List.Perm.append_right (l) : l₁ ~ l₂ → l₁ ++ l ~ l₂ ++ l`.
    exact List.perm_append_comm.append_right _
  | trans _ _ ih₁ ih₂ => exact ih₁.trans ih₂

/-- **T5.** The SAME family of per-cell shards, regrouped into invocations
    in any order, merges identically. `E` is an ARBITRARY function from cell
    indices to shard contents — no exhaustion, no relation to a global S —
    which is why this covers fixed-per-sub-branch-budget runs
    (SOLVE_PER_SUB_BRANCH_LIMIT; the 5.6T c34390c0 double-regression) as
    well as exhaustive ones, and why it does NOT cover cross-depth budgeted
    runs (different index families share no E). Combined with T4, any
    partition of the index list into invocation groups with per-group
    pre-merges is also covered. -/
theorem grouping_invariance (h : MergeOrder le key) {ι : Type w}
    (E : ι → List α) {G₁ G₂ : List ι} (hp : G₁.Perm G₂) :
    merge le key (G₁.flatMap E) = merge le key (G₂.flatMap E) :=
  merge_perm le key h (perm_flatMap E hp)

/-! ### §10 ROAE instantiation (design §4 L9–L11).

    Records are byte lists (concretely 32 bytes: byte = pair_index*4 +
    orient*2; the record-packing block in solve.c's `analyze_solution`).
    The canonical-class key is the & 0xFC mask;
    the comparator is compare_solutions' TWO-TIER order — primary lex on
    masked bytes, secondary lex on full bytes. This is NOT plain lex on
    full bytes (see the [6,0] vs [4,8] guard example below), which is why
    the instantiation must encode the real comparator. -/

/-- byte-wise lexicographic ≤ on Nat lists (shorter-prefix-first). -/
def lexLe : List Nat → List Nat → Bool
  | [], _ => true
  | _ :: _, [] => false
  | a :: s, b :: t => if a = b then lexLe s t else decide (a < b)

/-- the & 0xFC canonical mask on a byte list (b / 4 * 4 clears the two
    orient bits of pair_index*4 + orient*2). -/
def mask (r : List Nat) : List Nat := r.map fun b => b / 4 * 4

/-- compare_solutions: primary lex on masked bytes, secondary (within a
    canonical class) lex on full bytes. -/
def recLe (a b : List Nat) : Bool :=
  if mask a = mask b then lexLe a b else lexLe (mask a) (mask b)

theorem recLe_of_mask_eq {a b : List Nat} (h : mask a = mask b) :
    recLe a b = lexLe a b := by simp [recLe, h]

theorem recLe_of_mask_ne {a b : List Nat} (h : ¬mask a = mask b) :
    recLe a b = lexLe (mask a) (mask b) := by simp [recLe, h]

theorem lexLe_total : ∀ x y : List Nat, lexLe x y = true ∨ lexLe y x = true := by
  intro x
  induction x with
  | nil => intro y; exact Or.inl rfl
  | cons a s ih =>
    intro y
    cases y with
    | nil => exact Or.inr rfl
    | cons b t =>
      by_cases hab : a = b
      · subst hab
        simp only [lexLe]
        exact ih t
      · rcases Nat.lt_or_ge a b with h | h
        · left; simp [lexLe, hab, h]
        · have hba : ¬b = a := fun e => hab e.symm
          have hlt : b < a := by omega
          right; simp [lexLe, hba, hlt]

theorem lexLe_antisymm :
    ∀ x y : List Nat, lexLe x y = true → lexLe y x = true → x = y := by
  intro x
  induction x with
  | nil =>
    intro y _ hyx
    cases y with
    | nil => rfl
    | cons b t => simp [lexLe] at hyx
  | cons a s ih =>
    intro y hxy hyx
    cases y with
    | nil => simp [lexLe] at hxy
    | cons b t =>
      by_cases hab : a = b
      · subst hab
        simp only [lexLe] at hxy hyx
        rw [ih t hxy hyx]
      · have hba : ¬b = a := fun e => hab e.symm
        simp only [lexLe, if_neg hab] at hxy
        simp only [lexLe, if_neg hba] at hyx
        have h1 : a < b := of_decide_eq_true hxy
        have h2 : b < a := of_decide_eq_true hyx
        exact absurd h1 (by omega)

theorem lexLe_trans : ∀ x y z : List Nat,
    lexLe x y = true → lexLe y z = true → lexLe x z = true := by
  intro x
  induction x with
  | nil => intro y z _ _; rfl
  | cons a s ih =>
    intro y z hxy hyz
    cases y with
    | nil => simp [lexLe] at hxy
    | cons b t =>
      cases z with
      | nil => simp [lexLe] at hyz
      | cons c u =>
        by_cases hab : a = b <;> by_cases hbc : b = c
        · subst hab; subst hbc
          simp only [lexLe] at hxy hyz ⊢
          exact ih t u hxy hyz
        · subst hab
          simp only [lexLe, if_neg hbc] at hyz ⊢
          exact hyz
        · subst hbc
          simp only [lexLe, if_neg hab] at hxy ⊢
          exact hxy
        · simp only [lexLe, if_neg hab] at hxy
          simp only [lexLe, if_neg hbc] at hyz
          have h1 : a < b := of_decide_eq_true hxy
          have h2 : b < c := of_decide_eq_true hyz
          have hac : ¬a = c := by omega
          have h3 : a < c := by omega
          simp [lexLe, hac, h3]

/-- **The instantiation theorem**: the real pipeline comparator/key pair
    satisfies the trusted interface. The four fields are exactly the
    properties argued in solve.c's "Record comparators: correctness proof"
    block (above `compare_solutions`). -/
theorem recMergeOrder : MergeOrder recLe mask := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · -- totality
    intro a b
    by_cases h : mask a = mask b
    · rw [recLe_of_mask_eq h, recLe_of_mask_eq h.symm]
      exact lexLe_total a b
    · have h' : ¬mask b = mask a := fun e => h e.symm
      rw [recLe_of_mask_ne h, recLe_of_mask_ne h']
      exact lexLe_total (mask a) (mask b)
  · -- antisymmetry on distinct records (secondary key = full bytes)
    intro a b hab hba
    by_cases h : mask a = mask b
    · rw [recLe_of_mask_eq h] at hab
      rw [recLe_of_mask_eq h.symm] at hba
      exact lexLe_antisymm a b hab hba
    · have h' : ¬mask b = mask a := fun e => h e.symm
      rw [recLe_of_mask_ne h] at hab
      rw [recLe_of_mask_ne h'] at hba
      exact absurd (lexLe_antisymm _ _ hab hba) h
  · -- transitivity
    intro a b c hab hbc
    by_cases h1 : mask a = mask b <;> by_cases h2 : mask b = mask c
    · rw [recLe_of_mask_eq h1] at hab
      rw [recLe_of_mask_eq h2] at hbc
      rw [recLe_of_mask_eq (h1.trans h2)]
      exact lexLe_trans a b c hab hbc
    · have h3 : ¬mask a = mask c := fun e => h2 (h1.symm.trans e)
      rw [recLe_of_mask_ne h3]
      rw [recLe_of_mask_ne h2] at hbc
      rw [h1]
      exact hbc
    · have h3 : ¬mask a = mask c := fun e => h1 (e.trans h2.symm)
      rw [recLe_of_mask_ne h3]
      rw [recLe_of_mask_ne h1] at hab
      rw [← h2]
      exact hab
    · by_cases h3 : mask a = mask c
      · -- impossible: masks would collapse by lex antisymmetry
        rw [recLe_of_mask_ne h1] at hab
        rw [recLe_of_mask_ne h2] at hbc
        rw [← h3] at hbc
        exact absurd (lexLe_antisymm _ _ hab hbc) h1
      · rw [recLe_of_mask_ne h1] at hab
        rw [recLe_of_mask_ne h2] at hbc
        rw [recLe_of_mask_ne h3]
        exact lexLe_trans _ _ _ hab hbc
  · -- key convexity ("primary key is the masked bytes")
    intro a b c hab hbc hac
    by_cases hkb : mask a = mask b
    · exact hkb
    · exfalso
      rw [recLe_of_mask_ne hkb] at hab
      have h2 : ¬mask b = mask c := fun e => hkb (hac.trans e.symm)
      rw [recLe_of_mask_ne h2] at hbc
      rw [← hac] at hbc
      exact hkb (lexLe_antisymm _ _ hab hbc)

/-! ### §11 take-d prefix cells (design §4 L11): depth-d sharding.

    Depth-2 vs depth-3 pipeline partitions correspond to take-2 vs take-3
    prefixes of the pair/orient byte string. Cells key on RAW bytes, not
    masked bytes — orientation bits are part of the prefix — so canonical
    classes genuinely straddle cells, which is what makes T3/T4 non-trivial
    rather than per-cell-local. -/

/-- countP through a map (hand-rolled; small). -/
theorem countP_map' {β : Type v} {γ : Type w} (f : β → γ) (p : γ → Bool) :
    ∀ l : List β, (l.map f).countP p = l.countP fun b => p (f b) := by
  intro l
  induction l with
  | nil => rfl
  | cons a t ih =>
    simp only [List.map_cons]
    by_cases h : p (f a) = true
    · rw [List.countP_cons_of_pos h,
        List.countP_cons_of_pos (p := fun b => p (f b)) h, ih]
    · rw [List.countP_cons_of_neg h,
        List.countP_cons_of_neg (p := fun b => p (f b)) h, ih]

/-- a duplicate-free list hits each of its members exactly once. -/
theorem countP_eq_one_of_nodup_mem {β : Type v} [DecidableEq β] {a : β} :
    ∀ {l : List β}, l.Nodup → a ∈ l → l.countP (fun b => decide (a = b)) = 1 := by
  intro l
  induction l with
  | nil => intro _ h; cases h
  | cons b t ih =>
    intro hnd ha
    have h' := List.nodup_cons.mp hnd
    rcases List.mem_cons.mp ha with rfl | hat
    · rw [List.countP_cons_of_pos (p := fun x => decide (a = x)) (by simp)]
      have hz : t.countP (fun x => decide (a = x)) = 0 := by
        -- CHECK: core name `List.countP_eq_zero : l.countP p = 0 ↔ ∀ a ∈ l, ¬p a`.
        apply List.countP_eq_zero.mpr
        intro x hx
        simp only [decide_eq_true_eq]
        intro e
        rw [← e] at hx
        exact h'.1 hx
      rw [hz]
    · have hne : ¬((fun x => decide (a = x)) b = true) := by
        simp only [decide_eq_true_eq]
        intro e
        rw [e] at hat
        exact h'.1 hat
      rw [List.countP_cons_of_neg (p := fun x => decide (a = x)) hne]
      exact ih h'.2 hat

/-- the depth-d prefix cells of a listing S: one Boolean cell per distinct
    take-d prefix occurring in S (prefix dedup reuses `dedupKeyFirst` with
    the identity key, so its Nodup/coverage lemmas apply verbatim). -/
def cellsOf (S : List (List Nat)) (d : Nat) : List (List Nat → Bool) :=
  (dedupKeyFirst (fun p : List Nat => p) (S.map fun r => r.take d)).map
    fun p => fun x => decide (x.take d = p)

/-- every record satisfies exactly the cell of its own take-d prefix. -/
theorem cellsOf_isPartition (S : List (List Nat)) (d : Nat) :
    IsPartition (cellsOf S d) S := by
  unfold IsPartition cellsOf
  intro x hx
  rw [countP_map']
  -- CHECK: after the rw the countP predicate is the beta-redex
  -- `fun p => (fun p x' => decide (x'.take d = p)) p x`; `apply` should
  -- unify it with `fun p => decide (x.take d = p)` up to beta. If not,
  -- insert `show (dedupKeyFirst _ _).countP (fun p => decide (x.take d = p)) = 1`.
  apply countP_eq_one_of_nodup_mem
  · exact dedup_nodup (fun p : List Nat => p) (S.map fun r => r.take d)
  · have hmem : x.take d ∈ S.map fun r => r.take d :=
      List.mem_map.mpr ⟨x, hx, rfl⟩
    obtain ⟨a, ha, hae⟩ :=
      dedup_covers (fun p : List Nat => p) (S.map fun r => r.take d)
        (x.take d) hmem
    have hae' : a = x.take d := hae
    rw [← hae']
    exact ha

/-- **The cross-depth corollary** — PARTITION_INVARIANCE.md §4,
    machine-checked at the model level: exhaustive enumeration sharded at
    ANY two depths d₁, d₂ merges to identical canonical output. No
    sub-branch has ever been exhausted at two depths empirically; this is
    the statement the prose doc explicitly labels a conjecture. -/
theorem cross_depth_invariance (S : List (List Nat)) (hS : S.Nodup)
    (d₁ d₂ : Nat) :
    merge recLe mask ((cellsOf S d₁).flatMap fun c => S.filter c) =
      merge recLe mask ((cellsOf S d₂).flatMap fun c => S.filter c) :=
  partition_invariance recLe mask recMergeOrder S hS _ _
    (cellsOf_isPartition S d₁) (cellsOf_isPartition S d₂)

/-! ### §12 Sanity witnesses (design §4 L12).

    `decide` suffices for the structural comparator facts; the merge
    examples need `native_decide` because `dedupKeyFirst` is defined by
    well-founded recursion (kernel reduction does not unfold WF fixpoints). -/

/-- The design's mandated two-tier guard pair: under the REAL comparator
    [6,0] precedes [4,8] (masked primary [4,0] <lex [4,8]) even though
    plain full-byte lex says the opposite — any shortcut encoding of the
    comparator as plain lex would flip this and fail here. -/
example : recLe [6, 0] [4, 8] = true := by decide
example : lexLe [6, 0] [4, 8] = false := by decide
example : lexLe [4, 8] [6, 0] = true := by decide

/-- class-min selection: [6,0], [4,1], [4,3] are ONE canonical class
    (all mask to [4,0]); the retained representative is the byte-least. -/
example : merge recLe mask [[6, 0], [4, 1], [4, 3]] = [[4, 1]] := by
  native_decide

/-- toy solution listing; the first two records echo King Wen's opening
    bytes (63, 0, 17, 34 — hexagrams 1, 2 and the pair at positions 3-4).
    The class {[6,0,2], [4,0,2]} (both mask to [4,0,0]) STRADDLES the
    depth-1 cells with heads 6 and 4 — partition choice could plausibly
    matter, and provably doesn't. -/
def toyS : List (List Nat) :=
  [[63, 0, 17], [63, 0, 34], [6, 0, 2], [4, 0, 2], [4, 8, 1]]

example : merge recLe mask toyS =
    [[4, 0, 2], [4, 8, 1], [63, 0, 17], [63, 0, 34]] := by native_decide

/-- §1 headline shape: one full invocation (depth-0 = a single cell) vs
    per-head sharding (depth-1) — identical canonical output. -/
example :
    merge recLe mask ((cellsOf toyS 0).flatMap fun c => toyS.filter c) =
      merge recLe mask ((cellsOf toyS 1).flatMap fun c => toyS.filter c) := by
  native_decide

/-- §4 cross-depth shape: depth-1 vs depth-2 sharding — identical output. -/
example :
    merge recLe mask ((cellsOf toyS 1).flatMap fun c => toyS.filter c) =
      merge recLe mask ((cellsOf toyS 2).flatMap fun c => toyS.filter c) := by
  native_decide

/-- ...and the same fact as an instance of the THEOREM (not computation).
    CHECK: relies on core Decidable instance for `List.Nodup` (Pairwise over
    a DecidableRel); if absent, replace the `by native_decide` with a short
    `by simp`/`by decide`-free Nodup derivation. -/
example :
    merge recLe mask ((cellsOf toyS 1).flatMap fun c => toyS.filter c) =
      merge recLe mask ((cellsOf toyS 2).flatMap fun c => toyS.filter c) :=
  cross_depth_invariance toyS (by native_decide) 1 2

/-- dedup placement irrelevance on concrete shards (T4 witness). -/
example :
    merge recLe mask (merge recLe mask [[6, 0], [4, 3]] ++ [[4, 1], [63, 0]]) =
      merge recLe mask [[6, 0], [4, 3], [4, 1], [63, 0]] := by native_decide

end PartitionInvariance

/-! ### Axiom audit (added 2026-08-01)
Emits the trust base for every theorem in this file that is CITED BY NAME in the
public documentation, so the suite's `#print axioms` claims are OBSERVED rather than
statically inferred. Expected: `[propext, Classical.choice, Quot.sound]`, or
`[propext]` alone for the finite facts. Any `Lean.ofReduceBool` here means a
`native_decide` (compiler trust) is load-bearing and the docs must say so. -/
#print axioms PartitionInvariance.merge_perm
#print axioms PartitionInvariance.merge_spec
#print axioms PartitionInvariance.merge_map_merge_flatten
#print axioms PartitionInvariance.dedupAdjacent_eq
#print axioms PartitionInvariance.partition_invariance
#print axioms PartitionInvariance.grouping_invariance
#print axioms PartitionInvariance.recMergeOrder
#print axioms PartitionInvariance.cross_depth_invariance
