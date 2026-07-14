-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  PruneExactness.lean — machine-checked exactness (prune safety) of the v4
  prune stack #67/#68/#70 (2026-07-13, v4-canonical branch).
  Core Lean 4 only (no mathlib). Standalone: `lean PruneExactness.lean`.

  The v4 lineage re-adopts the v2 exact prune stack. "Exact" means: a fired
  prune removes ONLY subtrees that provably contain no valid solution — at
  per-cell exhaustion the found solution set is identical with the prunes on
  or off (and at a fixed node budget the pruned walk finds a superset). The
  red-team review (V4_REVIEW_REDTEAM_2026_07_13 §1.3.5) required these three
  predicates to be Lean-checked because the runtime acceptance gates are
  necessary-but-not-sufficient (a deep-only prune bug would pass all of
  them); the written proofs (TASK_67_MID_WALK_C3_CORRECTNESS_2026_05_05.md
  etc.) carry the safety load, and this file machine-checks their
  mathematical cores.

  The three predicates (see solve.c, search "task #67", "task #68", "task #70"):

  · #67 mid-walk C3: the complement-distance of a full sequence decomposes
    as a sum of per-complement-pair contributions 2·|pos(v) − pos(v⊕63)|.
    Contributions of pairs fully placed in the current prefix are final
    (positions are immutable once assigned). If their partial sum already
    exceeds the threshold (776), no completion can be C3-valid.
  · #70 optimistic completion bound: every not-yet-fully-placed complement
    pair will, in any completion, occupy two DISTINCT positions, so its
    contribution is at least 2. Adding 2 × (number of unfinished pairs) to
    the partial sum is still a lower bound on every completion's total.
  · #68 C5 feasibility: each unplaced pair consumes, at its eventual
    placement, one unit of the remaining distance budget for its fixed
    within-pair distance. If, for some distance class, the number of
    unplaced pairs demanding it exceeds the remaining budget, no completion
    satisfies the exact C5 distribution (pigeonhole).

  What is machine-checked here (model level):
  · `total_ge_partial_plus_bound` — the #67/#70 sum decomposition and lower
    bound, for any decomposition of the total into measured ++ unmeasured
    contributions with a pointwise bound on the unmeasured part.
  · `c3_prune_sound` — if the #67(+#70) predicate fires, every completion's
    total exceeds the threshold (soundness: no C3-valid leaf is pruned).
  · `pair_contrib_ge_two` — the "≥ 2 per unfinished pair" fact from position
    distinctness (feeds #70's bound; with bound 0 the same theorem is #67).
  · `subperm_count_le` — sub-multiset per-class counting (core of #68).
  · `c5_prune_sound` — if some class's unplaced demand exceeds its remaining
    budget, no completion's remaining-transition multiset can contain the
    demanded within-pair transitions (pigeonhole; no completion exists).

  Bridge facts (stated, NOT machine-checked — the PartitionInvariance.lean
  pattern; these connect the model to the C implementation and are covered
  by the runtime gates + code review):
  · solve.c's mw_partial_cd_x64 equals the measured-part sum of the model
    (mw_c3_init / push / pop maintain it incrementally; positions immutable).
  · solve.c's budget[] equals per-class remaining counts of the exact C5
    distribution, and pair_wpd[] the within-pair classes of unplaced pairs.
  · compute_comp_dist_x64 equals the model's total sum.

  Attribution: the arguments are elementary (finite sum decomposition;
  pigeonhole) and standard in exact search pruning; only this machine-checked
  packaging is ours (to our knowledge; corrections welcome).
-/

namespace PruneExactness

/-! ### Generic sum lemmas (core of #67/#70) -/

/-- Pointwise lower bound on a list gives a lower bound on its sum. -/
theorem sum_ge_length_mul_lb (l : List Nat) (lb : Nat)
    (h : ∀ x ∈ l, lb ≤ x) : l.length * lb ≤ l.sum := by
  induction l with
  | nil => simp
  | cons a t ih =>
      have ha : lb ≤ a := h a (List.mem_cons_self ..)
      have ht : t.length * lb ≤ t.sum :=
        ih (fun x hx => h x (List.mem_cons_of_mem a hx))
      simp only [List.length_cons, List.sum_cons]
      rw [Nat.succ_mul]
      calc t.length * lb + lb ≤ t.sum + a := Nat.add_le_add ht ha
        _ = a + t.sum := Nat.add_comm _ _

/-- #67/#70 core: if a total decomposes into measured contributions (final,
    position-immutable) plus unmeasured contributions each at least `lb`,
    the total is at least the measured sum plus `lb` per unmeasured item.
    Instantiate `lb := 2` for #70, `lb := 0` for plain #67. -/
theorem total_ge_partial_plus_bound (measured unmeasured : List Nat) (lb : Nat)
    (h : ∀ x ∈ unmeasured, lb ≤ x) :
    measured.sum + unmeasured.length * lb ≤ (measured ++ unmeasured).sum := by
  have hu : unmeasured.length * lb ≤ unmeasured.sum :=
    sum_ge_length_mul_lb unmeasured lb h
  rw [List.sum_append]
  exact Nat.add_le_add_left hu measured.sum

/-- Soundness of the #67(+#70) prune: when the predicate
    `thresh < partial + lb·unfinished` fires, EVERY completion's total
    complement distance exceeds the threshold — the pruned subtree contains
    no C3-valid leaf. (`measured`/`unmeasured` are the per-complement-pair
    contributions of an arbitrary completion, split by whether the pair was
    already fully placed in the prefix; the bridge facts identify
    `measured.sum` with solve.c's mw_partial_cd_x64 and `lb := 2` with the
    bound of mw_inevitable_remaining_cd_x64.) -/
theorem c3_prune_sound (thresh : Nat) (measured unmeasured : List Nat) (lb : Nat)
    (h : ∀ x ∈ unmeasured, lb ≤ x)
    (fire : thresh < measured.sum + unmeasured.length * lb) :
    thresh < (measured ++ unmeasured).sum :=
  Nat.lt_of_lt_of_le fire (total_ge_partial_plus_bound measured unmeasured lb h)

/-- #70's pointwise bound: a complement pair placed at two DISTINCT
    positions i ≠ j contributes 2·|i − j| ≥ 2. (|i − j| is expressed over ℕ
    as `max i j - min i j`.) -/
theorem pair_contrib_ge_two (i j : Nat) (hne : i ≠ j) :
    2 ≤ 2 * (max i j - min i j) := by
  rcases Nat.lt_or_ge i j with hij | hge
  · have hmax : max i j = j := Nat.max_eq_right (Nat.le_of_lt hij)
    have hmin : min i j = i := Nat.min_eq_left (Nat.le_of_lt hij)
    omega
  · have hji : j < i := Nat.lt_of_le_of_ne hge (fun e => hne e.symm)
    have hmax : max i j = i := Nat.max_eq_left (Nat.le_of_lt hji)
    have hmin : min i j = j := Nat.min_eq_right (Nat.le_of_lt hji)
    omega

/-! ### #68: pigeonhole on the exact C5 distribution -/

/-- Sub-multiset containment: `l₁` is, up to reordering, a sublist of `l₂`.
    (Core Lean has `List.Perm` and `List.Sublist` but no `Subperm`; this is
    the standard definition.) -/
def Subperm {α : Type} (l₁ l₂ : List α) : Prop :=
  ∃ l' : List α, List.Perm l' l₁ ∧ List.Sublist l' l₂

/-- Counting is monotone along sub-multisets: if `l₁` is, up to reordering,
    contained in `l₂`, every element's multiplicity in `l₁` is at most its
    multiplicity in `l₂`. -/
theorem subperm_count_le {α : Type} [DecidableEq α] {l₁ l₂ : List α}
    (h : Subperm l₁ l₂) (a : α) : l₁.count a ≤ l₂.count a := by
  rcases h with ⟨l', hperm, hsub⟩
  calc l₁.count a = l'.count a := (hperm.count_eq a).symm
    _ ≤ l₂.count a := hsub.count_le a

/-- Soundness of the #68 prune. Model: `demands` is the multiset of
    within-pair distance classes of the still-unplaced pairs; `remaining`
    is the multiset of transition distances a completion may still use
    (remaining budget of the exact C5 distribution). ANY valid completion
    places every unplaced pair, consuming its within-pair class — i.e. it
    realizes `Subperm demands remaining` (the completion's remaining
    transitions consist of exactly these within-pair transitions plus the
    between-pair ones). If the predicate fires — some class `d` with more
    demand than budget — no such completion exists. -/
theorem c5_prune_sound {D : Type} [DecidableEq D]
    (demands remaining : List D) (d : D)
    (fire : remaining.count d < demands.count d) :
    ¬ Subperm demands remaining := by
  intro hsub
  exact Nat.lt_irrefl _ (Nat.lt_of_le_of_lt (subperm_count_le hsub d) fire)

/-! ### Sanity instantiations (tiny concrete cases, `decide`-checked inputs) -/

/-- #70 sanity: partial 774 with 2 unfinished pairs ⇒ every completion's
    total is ≥ 778 > 776. -/
example : (776 : Nat) < ([770, 4] ++ [2, 2]).sum :=
  c3_prune_sound 776 [770, 4] [2, 2] 2 (by decide) (by decide)

/-- #68 sanity: two unplaced pairs demand class 6 but only one unit of
    budget remains — no completion. -/
example : ¬ Subperm [6, 6] [6, 2, 2, 1] :=
  c5_prune_sound [6, 6] [6, 2, 2, 1] 6 (by decide)

end PruneExactness
