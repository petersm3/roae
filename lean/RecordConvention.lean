-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  RecordConvention.lean — machine-checked core of the v4 record/orientation
  convention decision (walk-vs-class, Tier 3.4 of the v4 validation test
  plan; decision doc: roae-private/V4_RECORD_CONVENTION_DECISION_2026_07_14).

  *** COMPILES CLEAN on Lean 4.31.0 (2026-07-14, x86_64 linux, core only —
  *** no mathlib, no lake project): `lean RecordConvention.lean` exits 0
  *** with zero errors/warnings; zero `sorry`, zero `axiom`, zero `admit`.
  *** Standalone file in the PartitionInvariance.lean pattern; toolchain
  *** pinned in this directory's `lean-toolchain` (leanprover/lean4:v4.31.0).
  *** ALL theorems below are fully proved — no statement stubs.

  CONTEXT. A ROAE record (SOLUTIONS_FORMAT.md) is an orientation-masked
  dedup CLASS: the canonical key is the pair order (record bytes & 0xFC),
  and the current (v1/v3) convention retains, per key, the byte-wise least
  record among those the enumeration VISITED ("lex-smallest record wins",
  solve.c `analyze_solution` hash-insert + merge keep-first-after-sort).
  That representative is a function of the visited WALK set, so a deeper
  budget slice can lower it — record bytes are not stable under budget
  extension (empirical witness: PARTITION_INVARIANCE.md §5a, the 3-point
  trajectory's orientation-keyed "violations" that vanish under masking).

  The v4 convention decided in the companion doc replaces the visited-min
  representative with a PURE canonical-form representative:

      repr(k) = the lexicographically least orientation completion of the
                pair-order key k that satisfies the full constraint set
                (slot 0 forced; computed by the orb_recanon DFS shape).

      CORRECTION (2026-08-15, found by verify.py/verify.c --check-repr against
      the 1.78e9-record merge artifact): the prose above and the implementation
      it names DIVERGE. orb_recanon takes fixed_or[4] and forces slots 0..3 --
      its caller orb_expand_record supplies slots 1..3 from the member CELL's
      codes -- re-canonicalizing only slots 4..31. So the stored records are
      CELL-SCOPED canonical (lex-least over the free slots GIVEN the cell
      prefix), not globally lex-least. Both are coherent; the cell-scoped form is
      the right primitive for orbit expansion. What is wrong is this sentence,
      which states a global definition and names a cell-scoped implementation.
      Whether the intended canonical form is global or cell-scoped is a
      SPECIFICATION DECISION and is still open; it must be settled before any
      repr-normalized artifact is published under this wording. The repr(k)
      post-pass does NOT resolve it -- it applies this same orb_recanon. The
      theorems below are unaffected: they are stated about the DFS shape as
      implemented, not about the prose gloss.

  This file machine-checks the four model-level facts that decision rests
  on, plus the correctness of the DFS that computes repr:

  · `mem_artifact_iff`       — characterization: the class artifact of a
    visited-key list contains exactly one record (k, repr k) per distinct
    visited key. Everything below follows from it.
  · `artifact_key_ext` / `artifact_union` / `artifact_idem` — PARTITION
    INVARIANCE at the record level: the artifact is a function of the
    visited-key SET; slices merged in any grouping give the same record
    set as the whole run, and re-normalizing an artifact is a no-op
    (dedup placement irrelevance). Byte-layout determinism of the sorted
    serialization then follows from PartitionInvariance.lean T1/T2 (same
    record set + total-order sort ⇒ same bytes) — composed in prose in
    the decision doc, not re-proved here.
  · `artifact_mono` / `repr_stable` — NESTED EXTENDABILITY: growing the
    visited-key set only ADDS records; every record of the shallower
    artifact appears in the deeper one with IDENTICAL bytes. (This is
    exactly what the visited-min convention lacks.)
  · `visitedMin_not_nested`  — the CRUX, machine-checked as a concrete
    counterexample: under the current visited-min convention there exist
    walk sets W₁ ⊆ W₂ whose artifacts are NOT nested (a record of the
    shallower artifact is absent, byte-wise, from the deeper one). This
    is why v4 cannot keep the v1/v3 representative rule and claim
    record-level monotone slices.
  · `visitedMin_exhaustive_agreement` — FAITHFULNESS: when the visited
    walk set is EXHAUSTIVE (contains every valid variant of every visited
    key), the visited-min representative equals repr. Hence the v4
    convention agrees byte-identically with v1/v3 wherever v1/v3's output
    is theorem-grade (per-cell exhaustion), and re-anchors only budgeted
    bytes.
  · `dfsFirst_*`             — correctness of the computation of repr:
    a first-found depth-first search over orientation bits that tries 0
    before 1 at every slot returns exactly the lex-least satisfying
    completion (soundness, completeness, minimality). This is the
    load-bearing claim in solve.c's `orb_recanon_dfs` comment ("the first
    valid completion IS the lex-min"), machine-checked at the model level.

  Bridge facts — the honest trust boundary (NOT machine-checked; the
  PartitionInvariance.lean B1–B4 pattern, continued numbering):
  · B5 (walk-order monotonicity): solve.c's per-cell DFS visits nodes in
    a fixed budget-independent order, so the visited leaf/key set at
    budget B is a subset of that at budget B' ≥ B (truncation nesting);
    eviction-resume preserves the walk (Tier 5 gates).
  · B6 (repr computability): `orb_recanon`-with-slot-0-only-forcing
    implements the `dfsFirst` model over orientation vectors with P = "the
    completed sequence satisfies C2/C3/C5" (C1/C4 by construction); its
    mid-branch C2/C5 pruning only skips prefixes all of whose completions
    fail P (both predicates are monotone along the walk: a transition
    distance is fixed at the slot that creates it, and an over-spent C5
    budget class stays over-spent), so pruned-DFS first-found equals
    unpruned first-found. Stated, argued in the decision doc §5.3, not
    machine-checked.
  · B7 (nonemptiness): every visited key has at least one valid variant —
    the very walk that visited it — so repr is total on visited keys
    (modeled here by `Valid k` nonempty where used).

  Attribution: developed with AI assistance (Claude, Anthropic). The
  mathematics is elementary and classical — canonical forms as lex-least
  class members and greedy lexicographic DFS are standard (cf. canonical
  representatives in symmetry-reduced search); no novelty is claimed for
  the content, only for this mapping onto the ROAE pipeline (corrections
  welcome).
-/

namespace RecordConvention

set_option linter.unusedSectionVars false

/-! ### §1 The class artifact under a PURE representative -/

variable {κ ρ : Type} [DecidableEq κ] [DecidableEq ρ]

/-- Order-preserving first-occurrence dedup of a key list (self-contained;
    only `List.elem`/`∈` API is used). -/
def dedup [DecidableEq κ] : List κ → List κ
  | [] => []
  | k :: ks => if k ∈ ks then dedup ks else k :: dedup ks

theorem mem_dedup [DecidableEq κ] {k : κ} : ∀ {l : List κ}, k ∈ dedup l ↔ k ∈ l
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
    per distinct visited key. `repr` is an arbitrary PURE function — the
    canonical-form rule instantiates it as the lex-least valid variant
    (§3), but every invariance theorem in this section needs purity only. -/
def artifact (repr : κ → ρ) (visited : List κ) : List (κ × ρ) :=
  (dedup visited).map (fun k => (k, repr k))

/-- Characterization: `(k, r)` is in the artifact iff `k` was visited and
    `r` is THE canonical representative of `k`. -/
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
    record set. -/
theorem artifact_key_ext {repr : κ → ρ} {v₁ v₂ : List κ}
    (h : ∀ k, k ∈ v₁ ↔ k ∈ v₂) :
    ∀ x, x ∈ artifact repr v₁ ↔ x ∈ artifact repr v₂ := by
  intro ⟨k, r⟩
  rw [mem_artifact_iff, mem_artifact_iff, h k]

/-- **Merged-slices == whole-run.** Concatenating slice key lists (the
    merge's input union) yields the same record set as the whole run over
    the union — for any decomposition into slices. With
    PartitionInvariance.lean T1/T2 (total-order sort + one-per-key dedup
    of the SAME set gives the SAME bytes) this is byte-identity of the
    serialized artifact. -/
theorem artifact_union {repr : κ → ρ} (v₁ v₂ : List κ) :
    ∀ x, x ∈ artifact repr (v₁ ++ v₂) ↔
         (x ∈ artifact repr v₁ ∨ x ∈ artifact repr v₂) := by
  intro ⟨k, r⟩
  rw [mem_artifact_iff, mem_artifact_iff, mem_artifact_iff, List.mem_append]
  constructor
  · rintro ⟨h | h, rfl⟩
    · exact Or.inl ⟨h, rfl⟩
    · exact Or.inr ⟨h, rfl⟩
  · rintro (⟨h, rfl⟩ | ⟨h, rfl⟩)
    · exact ⟨Or.inl h, rfl⟩
    · exact ⟨Or.inr h, rfl⟩

/-- **Dedup-placement irrelevance.** Normalizing an already-normalized
    artifact changes nothing: re-merging slice artifacts through the same
    rule is idempotent, so normalization may sit at any interior node of
    any merge tree. (`artifact` over the keys of an artifact reproduces
    the artifact, set-wise.) -/
theorem artifact_idem {repr : κ → ρ} (visited : List κ) :
    ∀ x, x ∈ artifact repr ((artifact repr visited).map Prod.fst) ↔
         x ∈ artifact repr visited := by
  intro ⟨k, r⟩
  rw [mem_artifact_iff, mem_artifact_iff]
  constructor
  · rintro ⟨hk, rfl⟩
    rcases List.mem_map.mp hk with ⟨⟨k', r'⟩, hx, he⟩
    cases he
    exact ⟨(mem_artifact_iff.mp hx).1, rfl⟩
  · rintro ⟨hk, rfl⟩
    exact ⟨List.mem_map.mpr ⟨(k, repr k), mem_artifact_iff.mpr ⟨hk, rfl⟩, rfl⟩, rfl⟩

/-- **Nested extendability.** If the deeper run visits every key the
    shallower run visits (walk-order monotonicity, bridge fact B5), then
    every record of the shallower artifact appears — with identical bytes
    — in the deeper artifact. Record bytes never change under extension;
    deeper slices only ADD records. -/
theorem artifact_mono {repr : κ → ρ} {v₁ v₂ : List κ}
    (h : ∀ k, k ∈ v₁ → k ∈ v₂) :
    ∀ x, x ∈ artifact repr v₁ → x ∈ artifact repr v₂ := by
  intro ⟨k, r⟩ hx
  rcases mem_artifact_iff.mp hx with ⟨hk, rfl⟩
  exact mem_artifact_iff.mpr ⟨h k hk, rfl⟩

/-- Representative stability, stated pointwise: once a key enters the
    artifact its record is `(k, repr k)` at EVERY deeper scope — the
    representative is budget-free by purity. -/
theorem repr_stable {repr : κ → ρ} {v : List κ} {k : κ} (hk : k ∈ v) :
    (k, repr k) ∈ artifact repr v :=
  mem_artifact_iff.mpr ⟨hk, rfl⟩

/-! ### §2 The current (v1/v3) visited-min convention, and why v4 must not
        keep it at budgeted scope -/

/-- Least element of a variant list under a boolean order (min-fold). -/
def listMin (le : ρ → ρ → Bool) : ρ → List ρ → ρ
  | r, [] => r
  | r, x :: xs => listMin le (if le r x then r else x) xs

/-- Variants of key `k` present in a visited WALK list. -/
def variantsOf (k : κ) (walks : List (κ × ρ)) : List ρ :=
  (walks.filter (fun w => w.1 = k)).map Prod.snd

/-- The v1/v3 visited-min representative: byte-least variant among those
    the enumeration actually visited ("lex-smallest record wins"). Total
    only when the key was visited; `default` supplies the (unused)
    base case. -/
def reprVM [Inhabited ρ] (le : ρ → ρ → Bool) (walks : List (κ × ρ)) (k : κ) : ρ :=
  match variantsOf k walks with
  | [] => default
  | r :: rs => listMin le r rs

/-- The visited-min artifact: the v1/v3 dedup semantics over a walk list. -/
def artifactVM [Inhabited ρ] (le : ρ → ρ → Bool) (walks : List (κ × ρ)) : List (κ × ρ) :=
  artifact (reprVM le walks) (walks.map Prod.fst)

/-- **The crux, machine-checked as a counterexample.** The visited-min
    convention is NOT nested-extendable: there are walk lists W₁ ⊆ W₂
    (here `[(0,5)] ⊆ [(0,5),(0,3)]`, one key, two orient variants) such
    that the record `(0,5)` is in the artifact of W₁ but in W₂'s artifact
    the same key's bytes have CHANGED to `(0,3)` — the shallower record is
    absent from the deeper artifact. A deeper budget can lower a class's
    lex-min visited variant; byte-level nesting fails even though the
    class SET is nested. (This is the mechanism behind the 3-point
    trajectory's orientation-keyed pseudo-violations,
    PARTITION_INVARIANCE.md §5a.) -/
theorem visitedMin_not_nested :
    ∃ (w₁ w₂ : List (Nat × Nat)),
      (∀ x, x ∈ w₁ → x ∈ w₂) ∧
      ∃ x, x ∈ artifactVM Nat.ble w₁ ∧ x ∉ artifactVM Nat.ble w₂ := by
  refine ⟨[(0, 5)], [(0, 5), (0, 3)], ?_, (0, 5), ?_, ?_⟩ <;> decide

/-- **Exhaustive agreement.** If the visited walk list is EXHAUSTIVE for
    key `k` — its variant list is exactly the full valid-variant list
    `Valid k` (as a set) — then the visited-min representative equals the
    canonical form `listMin` over `Valid k`. Consequently the v4
    canonical-form artifact agrees with the v1/v3 visited-min artifact,
    key by key, wherever enumeration reached per-cell exhaustion: the v4
    convention preserves v1/v3 record semantics on the theorem-grade
    regime and re-anchors only budgeted bytes.

    Stated with the antisymmetric/total/transitive order hypotheses the
    byte order (lex on fixed-length byte strings) satisfies. -/
theorem visitedMin_exhaustive_agreement
    (le : ρ → ρ → Bool)
    (le_total : ∀ a b, le a b = true ∨ le b a = true)
    (le_trans : ∀ a b c, le a b = true → le b c = true → le a c = true)
    (le_antisymm : ∀ a b, le a b = true → le b a = true → a = b)
    (v₁ v₂ : List ρ) (r₁ : ρ) (r₂ : ρ)
    (hmem : ∀ r, r ∈ r₁ :: v₁ ↔ r ∈ r₂ :: v₂) :
    listMin le r₁ v₁ = listMin le r₂ v₂ := by
  -- min-fold over a list is its le-least member; le-least members of
  -- set-equal nonempty lists coincide by antisymmetry.
  have min_mem : ∀ (r : ρ) (l : List ρ), listMin le r l ∈ r :: l := by
    intro r l
    induction l generalizing r with
    | nil => exact List.mem_cons_self ..
    | cons x xs ih =>
      show listMin le (if le r x then r else x) xs ∈ r :: x :: xs
      by_cases h : le r x = true
      · rw [if_pos h]
        rcases List.mem_cons.mp (ih r) with he | hm
        · rw [he]; exact List.mem_cons_self ..
        · exact List.mem_cons_of_mem r (List.mem_cons_of_mem x hm)
      · rw [if_neg h]
        rcases List.mem_cons.mp (ih x) with he | hm
        · rw [he]; exact List.mem_cons_of_mem r (List.mem_cons_self ..)
        · exact List.mem_cons_of_mem r (List.mem_cons_of_mem x hm)
  have min_le : ∀ (l : List ρ) (r x : ρ), x ∈ r :: l →
      le (listMin le r l) x = true := by
    intro l
    induction l with
    | nil =>
      intro r x hx
      have hxr : x = r := by
        rcases List.mem_cons.mp hx with h | h
        · exact h
        · cases h
      subst hxr
      rcases le_total x x with h' | h' <;> exact h'
    | cons y ys ih =>
      intro r x hx
      show le (listMin le (if le r y then r else y) ys) x = true
      have step : ∀ m : ρ, le m r = true → le m y = true →
          le (listMin le m ys) x = true := by
        intro m hmr hmy
        have hmin_m : le (listMin le m ys) m = true :=
          ih m m (List.mem_cons_self ..)
        rcases List.mem_cons.mp hx with h1 | h1
        · subst h1
          exact le_trans _ m _ hmin_m hmr
        · rcases List.mem_cons.mp h1 with h2 | h2
          · subst h2
            exact le_trans _ m _ hmin_m hmy
          · exact ih m x (List.mem_cons_of_mem m h2)
      by_cases h : le r y = true
      · rw [if_pos h]
        refine step r ?_ h
        rcases le_total r r with h' | h' <;> exact h'
      · rw [if_neg h]
        refine step y ?_ ?_
        · rcases le_total r y with h' | h'
          · exact absurd h' h
          · exact h'
        · rcases le_total y y with h' | h' <;> exact h'
  have m₁ := min_mem r₁ v₁
  have m₂ := min_mem r₂ v₂
  exact le_antisymm _ _
    (min_le v₁ r₁ _ ((hmem _).mpr m₂))
    (min_le v₂ r₂ _ ((hmem _).mp m₁))

/-! ### §3 Computing the canonical form: first-found 0-before-1 DFS is
        the lex-min satisfying completion

    Model: an orientation completion of `n` free slots is a `List Bool`
    of length `n` (`false` = orient 0, `true` = orient 1; earlier
    positions are more significant — record bytes increase with the
    orient bit at fixed pair order, per solve.c `orb_recanon_dfs`).
    `dfsFirst P n` tries `false` before `true` at each slot and returns
    the first completion satisfying `P`. This machine-checks the comment
    claim "returning the first valid completion IS the lex-min"; bridge
    fact B6 connects the pruned C implementation to this model. -/

/-- Lexicographic `≤` on equal-length Bool lists, `false < true`,
    most-significant first. -/
def lexLe : List Bool → List Bool → Bool
  | [], [] => true
  | [], _ :: _ => true          -- unequal lengths never arise in use
  | _ :: _, [] => false
  | a :: as, b :: bs =>
    match a, b with
    | false, true  => true
    | true,  false => false
    | _,     _     => lexLe as bs

/-- First-found DFS over `n` Bool slots, `false` tried before `true`. -/
def dfsFirst (P : List Bool → Bool) : Nat → Option (List Bool)
  | 0 => if P [] then some [] else none
  | n + 1 =>
    match dfsFirst (fun t => P (false :: t)) n with
    | some t => some (false :: t)
    | none => (dfsFirst (fun t => P (true :: t)) n).map (true :: ·)

/-- Soundness: a found completion has the right length and satisfies `P`. -/
theorem dfsFirst_sound (P : List Bool → Bool) :
    ∀ n v, dfsFirst P n = some v → v.length = n ∧ P v = true := by
  intro n
  induction n generalizing P with
  | zero =>
    intro v h
    by_cases hp : P [] = true
    · simp only [dfsFirst, if_pos hp] at h
      cases h; exact ⟨rfl, hp⟩
    · simp only [dfsFirst, if_neg hp] at h
      cases h
  | succ n ih =>
    intro v h
    simp only [dfsFirst] at h
    cases hf : dfsFirst (fun t => P (false :: t)) n with
    | some t =>
      rw [hf] at h; cases h
      rcases ih (fun t => P (false :: t)) t hf with ⟨hl, hp⟩
      exact ⟨by simp [hl], hp⟩
    | none =>
      rw [hf] at h
      cases ht : dfsFirst (fun t => P (true :: t)) n with
      | some t =>
        rw [ht] at h; cases h
        rcases ih (fun t => P (true :: t)) t ht with ⟨hl, hp⟩
        exact ⟨by simp [hl], hp⟩
      | none => rw [ht] at h; cases h

/-- Completeness: `none` means NO completion of length `n` satisfies `P`. -/
theorem dfsFirst_complete (P : List Bool → Bool) :
    ∀ n, dfsFirst P n = none → ∀ v, v.length = n → P v = false := by
  intro n
  induction n generalizing P with
  | zero =>
    intro h v hv
    have : v = [] := List.eq_nil_of_length_eq_zero hv
    subst this
    by_cases hp : P [] = true
    · simp only [dfsFirst, if_pos hp] at h
      cases h
    · exact Bool.eq_false_iff.mpr (fun hc => hp hc)
  | succ n ih =>
    intro h v hv
    simp only [dfsFirst] at h
    cases hf : dfsFirst (fun t => P (false :: t)) n with
    | some t => rw [hf] at h; cases h
    | none =>
      rw [hf] at h
      cases ht : dfsFirst (fun t => P (true :: t)) n with
      | some t => rw [ht] at h; cases h
      | none =>
        cases v with
        | nil => cases hv
        | cons b bs =>
          have hbs : bs.length = n := by
            simpa using hv
          cases b with
          | false => exact ih (fun t => P (false :: t)) hf bs hbs
          | true => exact ih (fun t => P (true :: t)) ht bs hbs

/-- Minimality: the found completion is lex-`≤` EVERY satisfying
    completion of the same length — first-found IS the lex-min. -/
theorem dfsFirst_min (P : List Bool → Bool) :
    ∀ n v, dfsFirst P n = some v →
      ∀ w, w.length = n → P w = true → lexLe v w = true := by
  intro n
  induction n generalizing P with
  | zero =>
    intro v h w hw _
    have : w = [] := List.eq_nil_of_length_eq_zero hw
    subst this
    by_cases hp : P [] = true
    · simp only [dfsFirst, if_pos hp] at h
      cases h; rfl
    · simp only [dfsFirst, if_neg hp] at h
      cases h
  | succ n ih =>
    intro v h w hw hpw
    simp only [dfsFirst] at h
    cases w with
    | nil => cases hw
    | cons b bs =>
      have hbs : bs.length = n := by simpa using hw
      cases hf : dfsFirst (fun t => P (false :: t)) n with
      | some t =>
        rw [hf] at h; cases h
        cases b with
        | false =>
          -- both start with false: recurse
          exact ih (fun t => P (false :: t)) t hf bs hbs hpw
        | true =>
          -- false-headed found value vs true-headed competitor: strictly less
          rfl
      | none =>
        rw [hf] at h
        cases ht : dfsFirst (fun t => P (true :: t)) n with
        | some t =>
          rw [ht] at h; cases h
          cases b with
          | false =>
            -- competitor's false-subtree is empty by completeness: contradiction
            have := dfsFirst_complete (fun t => P (false :: t)) n hf bs hbs
            rw [hpw] at this; cases this
          | true =>
            exact ih (fun t => P (true :: t)) t ht bs hbs hpw
        | none => rw [ht] at h; cases h

end RecordConvention
