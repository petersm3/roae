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
  · `capping_exact` (+ crux `le_eqsum_imp_eq`) — F-53: the C5 dead-state
    capping of count-DP residual vectors is EXACT ("residual dominance",
    FH1 §2 Theorem): F(M, r) = F(M, cap r Bmax) for any valid per-class
    bound Bmax. The DP-reachability facts (sum invariant, Bmax-validity)
    are HYPOTHESES here, mirroring how c5_prune_sound takes demands/
    remaining — see the F-53 section header below.
  · `no_live_lumping` + `cap_never_merges_live` — F-21: the companion
    no-further-collapse Proposition (FH1 §2) after independent review:
    distinct sum-S residuals are future-equivalent IFF both dead, and a
    shared cap image forces both residuals dead — no lumping among live
    states. See the F-21 section header for the reviewed scope (this rules
    out residual equivalence-classing, not every conceivable encoding) and
    for why neither direction is load-bearing for the landed count.

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

/-! ### F-53: exactness of the C5 dead-state capping ("residual dominance")

    Machine-checks the §2 Theorem "capping is exact" of the residual-dominance
    analysis (roae-private FH1_RESIDUAL_DOMINANCE.md, 2026-07-04; adversarial-
    review item F-53): capping the C5 residual vector r pointwise at any valid
    per-class usage bound Bmax leaves the completion count unchanged,
    F(M, r) = F(M, cap r Bmax). Model: per-distance-class vectors as Nat
    lists; `M` is the list of per-completion class-usage vectors from the
    current DP state (the prose's M(mask, last)); `Fcount M r` counts the
    completions whose usage vector is exactly r. The prose's Lemma 2 — on
    sum-matched states "componentwise admissible" collapses to "exactly
    equal" — is `ptle_iff_eq_of_eqsum`, whose hard direction is the crux
    lemma `le_eqsum_imp_eq` (pointwise-≤ ∧ equal-sum ⇒ equality).

    The two DP-reachability facts are HYPOTHESES, deliberately NOT derived
    here (the same discipline as c5_prune_sound above, whose demands/
    remaining are hypotheses):
    · hSr / hMsum — the sum invariant (prose Lemma 1: every forward-reachable
      residual, and every completion's usage vector, sums to the remaining
      transition count S);
    · hMbound — Bmax-validity (Bmax_d bounds every completion's class-d
      usage from this state).
    Deriving either would require the backward reachability set M(mask, last)
    — out of scope by design; like the bridge facts in the file header they
    are carried by the runtime gates (two-language + brute-force validation
    V1–V3 of the instrument) and code review.

    Attribution: the capping conjecture is the operator's (FOOTHOLDS FH-1);
    the prose proof and this machine-checked packaging are Claude's. The
    argument is elementary (as with the sections above, no novelty claimed;
    corrections welcome). -/

/-- pointwise ≤ on Nat vectors (boolean form; `all` over `zipWith`). -/
def ptle (a b : List Nat) : Bool :=
  (List.zipWith (fun p q => decide (p ≤ q)) a b).all (fun x => x)

/-- pointwise cap (per-class min with the residual bound vector). -/
def capv (r Bmax : List Nat) : List Nat := List.zipWith min r Bmax

/-- the counted quantity: multiplicity of the exact residual r among the
    per-completion class-usage vectors M. -/
def Fcount (M : List (List Nat)) (r : List Nat) : Nat :=
  (M.filter (fun mu => decide (mu = r))).length

/-- sum-monotone: pointwise ≤ on equal-length vectors bounds the sums. -/
theorem ptle_sum_le : ∀ (a b : List Nat), a.length = b.length →
    ptle a b = true → a.sum ≤ b.sum := by
  intro a
  induction a with
  | nil => intro b _ _; simp
  | cons x xs ih =>
      intro b hlen hle
      cases b with
      | nil => simp at hlen
      | cons y ys =>
          simp only [List.length_cons, Nat.succ.injEq] at hlen
          simp only [ptle, List.zipWith_cons_cons, List.all_cons, Bool.and_eq_true,
            decide_eq_true_eq] at hle
          have htl := ih ys hlen hle.2
          simp only [List.sum_cons]
          omega

/-- the crux: pointwise-≤ ∧ equal sum ⇒ equal vectors. -/
theorem le_eqsum_imp_eq : ∀ (a b : List Nat), a.length = b.length →
    ptle a b = true → a.sum = b.sum → a = b := by
  intro a
  induction a with
  | nil =>
      intro b hlen _ _
      cases b with
      | nil => rfl
      | cons _ _ => simp at hlen
  | cons x xs ih =>
      intro b hlen hle hsum
      cases b with
      | nil => simp at hlen
      | cons y ys =>
          simp only [List.length_cons, Nat.succ.injEq] at hlen
          simp only [ptle, List.zipWith_cons_cons, List.all_cons, Bool.and_eq_true,
            decide_eq_true_eq] at hle
          have htl : xs.sum ≤ ys.sum := ptle_sum_le xs ys hlen hle.2
          simp only [List.sum_cons] at hsum
          have hxeq : x = y := by omega
          have hteq : xs.sum = ys.sum := by omega
          rw [hxeq, ih ys hlen hle.2 hteq]

/-- pointwise ≤ is reflexive. -/
theorem ptle_refl : ∀ (a : List Nat), ptle a a = true := by
  intro a
  induction a with
  | nil => rfl
  | cons x xs ih =>
      simp only [ptle, List.zipWith_cons_cons, List.all_cons, Bool.and_eq_true,
        decide_eq_true_eq]
      exact ⟨Nat.le_refl x, ih⟩

/-- Lemma 2's collapse: on sum-matched equal-length vectors, "componentwise
    admissible" and "exactly equal" coincide. -/
theorem ptle_iff_eq_of_eqsum {a b : List Nat} (hlen : a.length = b.length)
    (hsum : a.sum = b.sum) : ptle a b = true ↔ a = b := by
  constructor
  · intro h
    exact le_eqsum_imp_eq a b hlen h hsum
  · intro h
    rw [h]
    exact ptle_refl b

/-- capping preserves the length (on equal-length inputs). -/
theorem capv_length {r B : List Nat} (hlen : r.length = B.length) :
    (capv r B).length = r.length := by
  simp [capv, List.length_zipWith, hlen]

/-- the cap is pointwise below the residual. -/
theorem capv_ptle_left : ∀ (r B : List Nat), ptle (capv r B) r = true := by
  intro r
  induction r with
  | nil => intro B; rfl
  | cons x xs ih =>
      intro B
      cases B with
      | nil => rfl
      | cons y ys =>
          simp only [capv, ptle, List.zipWith_cons_cons, List.all_cons,
            Bool.and_eq_true, decide_eq_true_eq]
          exact ⟨Nat.min_le_left x y, by simpa [capv, ptle] using ih ys⟩

/-- a residual within bounds is unchanged by capping (equal-length inputs). -/
theorem capv_eq_self_of_ptle : ∀ (r B : List Nat), r.length = B.length →
    ptle r B = true → capv r B = r := by
  intro r
  induction r with
  | nil =>
      intro B hlen _
      cases B with
      | nil => rfl
      | cons _ _ => simp at hlen
  | cons x xs ih =>
      intro B hlen hle
      cases B with
      | nil => simp at hlen
      | cons y ys =>
          simp only [List.length_cons, Nat.succ.injEq] at hlen
          simp only [ptle, List.zipWith_cons_cons, List.all_cons, Bool.and_eq_true,
            decide_eq_true_eq] at hle
          simp only [capv, List.zipWith_cons_cons]
          rw [Nat.min_eq_left hle.1]
          have htl := ih ys hlen hle.2
          simp only [capv] at htl
          rw [htl]

/-- conversely, a residual unchanged by capping was within bounds
    (equal-length inputs). -/
theorem ptle_of_capv_eq : ∀ (r B : List Nat), r.length = B.length →
    capv r B = r → ptle r B = true := by
  intro r
  induction r with
  | nil =>
      intro B hlen _
      cases B with
      | nil => rfl
      | cons _ _ => simp at hlen
  | cons x xs ih =>
      intro B hlen hcap
      cases B with
      | nil => simp at hlen
      | cons y ys =>
          simp only [List.length_cons, Nat.succ.injEq] at hlen
          simp only [capv, List.zipWith_cons_cons, List.cons.injEq] at hcap
          simp only [ptle, List.zipWith_cons_cons, List.all_cons, Bool.and_eq_true,
            decide_eq_true_eq]
          have hxy : x ≤ y := by
            have hmr := Nat.min_le_right x y
            omega
          refine ⟨hxy, ?_⟩
          simpa [ptle] using ih ys hlen hcap.2

/-- filter of a never-satisfied predicate has no members. -/
theorem count_none_eq_zero {α : Type} (p : α → Bool) :
    ∀ (l : List α), (∀ x ∈ l, p x = false) → (l.filter p).length = 0 := by
  intro l
  induction l with
  | nil => intro _; rfl
  | cons a t ih =>
      intro h
      rw [List.filter_cons_of_neg (by simp [h a (List.mem_cons_self ..)])]
      exact ih (fun x hx => h x (List.mem_cons_of_mem a hx))

/-- over-Bmax ⇒ strict sum drop: if the residual exceeds the bound in some
    class, the capped residual's sum is strictly below the residual's. -/
theorem capv_sum_lt {r B : List Nat} (hlen : r.length = B.length)
    (hover : ptle r B = false) : (capv r B).sum < r.sum := by
  have hle : (capv r B).sum ≤ r.sum :=
    ptle_sum_le (capv r B) r (capv_length hlen) (capv_ptle_left r B)
  rcases Nat.lt_or_ge (capv r B).sum r.sum with h | h
  · exact h
  · exfalso
    have hs : (capv r B).sum = r.sum := Nat.le_antisymm hle h
    have hceq : capv r B = r :=
      le_eqsum_imp_eq (capv r B) r (capv_length hlen) (capv_ptle_left r B) hs
    rw [ptle_of_capv_eq r B hlen hceq] at hover
    cases hover

/-- CAPPING EXACTNESS (F-53): with the sum invariant and Bmax-validity as
    hypotheses, F(M, r) = F(M, cap r Bmax). In-budget r: cap is the identity.
    Over-budget r: no completion equals r (each usage vector is ≤ Bmax
    pointwise, r is not), and no completion equals cap r Bmax (its sum falls
    strictly short of S) — both counts are 0. -/
theorem capping_exact
    (M : List (List Nat)) (r Bmax : List Nat) (S : Nat)
    (hlen : r.length = Bmax.length)
    (hSr : r.sum = S)
    (hMsum : ∀ mu ∈ M, mu.sum = S)
    (hMbound : ∀ mu ∈ M, ptle mu Bmax = true) :
    Fcount M r = Fcount M (capv r Bmax) := by
  by_cases hcase : ptle r Bmax = true
  · rw [capv_eq_self_of_ptle r Bmax hlen hcase]
  · have hover : ptle r Bmax = false := by
      cases hpb : ptle r Bmax with
      | false => rfl
      | true => exact absurd hpb hcase
    have hlt : (capv r Bmax).sum < r.sum := capv_sum_lt hlen hover
    have h1 : Fcount M r = 0 := by
      apply count_none_eq_zero
      intro mu hmu
      simp only [decide_eq_false_iff_not]
      intro heq
      have hb := hMbound mu hmu
      rw [heq] at hb
      rw [hb] at hover
      cases hover
    have h2 : Fcount M (capv r Bmax) = 0 := by
      apply count_none_eq_zero
      intro mu hmu
      simp only [decide_eq_false_iff_not]
      intro heq
      have hms := hMsum mu hmu
      rw [heq] at hms
      omega
    rw [h1, h2]

/-- F-53 sanity: an over-budget residual ([3, 1] under Bmax [2, 5]) against a
    bound-respecting completion set — both counts are 0. -/
example : Fcount [[2, 2], [1, 3]] [3, 1] = Fcount [[2, 2], [1, 3]] (capv [3, 1] [2, 5]) :=
  capping_exact [[2, 2], [1, 3]] [3, 1] [2, 5] 4 (by decide) (by decide)
    (by decide) (by decide)

/-- F-53 sanity: an in-budget residual is untouched by the cap — the counts
    coincide trivially (and are 1 here). -/
example : Fcount [[2, 2], [1, 3]] [1, 3] = Fcount [[2, 2], [1, 3]] (capv [1, 3] [2, 5]) :=
  capping_exact [[2, 2], [1, 3]] [1, 3] [2, 5] 4 (by decide) (by decide)
    (by decide) (by decide)

/-! ### F-21 addendum (2026-07-21): the no-further-collapse companion
    ("complete characterization of future-equivalence", FH1 §2 Proposition +
    Correction 2), machine-checked at the model level after independent
    review.

    Statement reviewed and formalized: for two DISTINCT sum-S residuals
    r1 ≠ r2 at the same (mask, last), "every completion is feasible
    identically under both" (pathwise/trace equivalence — the criterion for
    knowledge-free DP state merging) holds IFF both residuals are dead
    (Fcount M r1 = Fcount M r2 = 0). Hence no residual lumping exists among
    live states — `no_live_lumping` below. Correction 2 — capping never
    merges live states: if the caps of two distinct sum-S residuals
    coincide, both residuals were over-budget, hence dead —
    `cap_never_merges_live` below.

    SCOPE (review finding, F-21): what is proven (prose and here) rules out
    residual equivalence-classing at a fixed (mask, last). It is NOT an
    information-theoretic storage lower bound over arbitrary forward
    schemes (value deduplication, cross-state merging, algebraic
    compression are outside the argument); the prose consequence "the
    minimal exact storage of ANY forward scheme is the live set" should be
    read with that scoping. Neither direction of the Proposition is
    load-bearing for the landed count: the production DP merges no live
    states, and its arithmetic rests on `capping_exact` +
    `ptle_iff_eq_of_eqsum` alone.

    As throughout this file, the DP-reachability facts (sum invariant,
    Bmax-validity) are HYPOTHESES; the bridge to solve.c is carried by the
    runtime gates. Attribution: FH-1 Proposition and prose proof are from
    FH1_RESIDUAL_DOMINANCE.md §2 (Claude, 2026-07-04); this independent
    review and machine-checked packaging, Claude (Fable 5), 2026-07-21. -/

/-- an empty filter result means no member satisfies the predicate
    (converse of `count_none_eq_zero`). -/
theorem no_mem_of_filter_len_zero {α : Type} (p : α → Bool) :
    ∀ (l : List α), (l.filter p).length = 0 → ∀ x ∈ l, p x = false := by
  intro l
  induction l with
  | nil => intro _ x hx; cases hx
  | cons a t ih =>
      intro h x hx
      cases hpa : p a with
      | true =>
          rw [List.filter_cons_of_pos (by simp [hpa])] at h
          simp at h
      | false =>
          rw [List.filter_cons_of_neg (by simp [hpa])] at h
          rcases List.mem_cons.mp hx with rfl | hxt
          · exact hpa
          · exact ih h x hxt

/-- deadness from non-membership: if no completion's usage vector equals r,
    its count is 0. -/
theorem fcount_zero_of_notmem (M : List (List Nat)) (r : List Nat)
    (h : ∀ mu ∈ M, mu ≠ r) : Fcount M r = 0 := by
  apply count_none_eq_zero
  intro mu hmu
  simp only [decide_eq_false_iff_not]
  exact h mu hmu

/-- non-membership from deadness: a zero count means no completion's usage
    vector equals r. -/
theorem notmem_of_fcount_zero (M : List (List Nat)) (r : List Nat)
    (h : Fcount M r = 0) : ∀ mu ∈ M, mu ≠ r := by
  intro mu hmu
  have hf := no_mem_of_filter_len_zero (fun mu => decide (mu = r)) M h mu hmu
  simpa using hf

/-- an over-budget residual is dead (the `h1` step of `capping_exact`,
    extracted): if r exceeds Bmax somewhere and every completion respects
    Bmax, no completion's usage vector equals r. -/
theorem fcount_zero_of_over (M : List (List Nat)) (r Bmax : List Nat)
    (hover : ptle r Bmax = false)
    (hMbound : ∀ mu ∈ M, ptle mu Bmax = true) :
    Fcount M r = 0 := by
  apply fcount_zero_of_notmem
  intro mu hmu heq
  have hb := hMbound mu hmu
  rw [heq] at hb
  rw [hb] at hover
  cases hover

/-- NO-FURTHER-COLLAPSE (FH1 §2 Proposition, F-21): two distinct sum-S
    residuals at the same DP state are future-equivalent — every
    completion's admissibility (`ptle mu r`, which on sum-matched vectors
    is exact-equality by Lemma 2) is identical under both — IFF both are
    dead. Live states allow no lumping. -/
theorem no_live_lumping
    (M : List (List Nat)) (r1 r2 : List Nat) (S : Nat)
    (hne : r1 ≠ r2)
    (h1 : r1.sum = S) (h2 : r2.sum = S)
    (hMsum : ∀ mu ∈ M, mu.sum = S)
    (hMlen1 : ∀ mu ∈ M, mu.length = r1.length)
    (hMlen2 : ∀ mu ∈ M, mu.length = r2.length) :
    (∀ mu ∈ M, ptle mu r1 = ptle mu r2) ↔
      (Fcount M r1 = 0 ∧ Fcount M r2 = 0) := by
  constructor
  · intro heq
    constructor
    · apply fcount_zero_of_notmem
      intro mu hmu hmu1
      have ht1 : ptle mu r1 = true := by rw [hmu1]; exact ptle_refl r1
      have ht2 : ptle mu r2 = true := (heq mu hmu).symm.trans ht1
      have hmu2 : mu = r2 :=
        le_eqsum_imp_eq mu r2 (hMlen2 mu hmu) ht2 (by rw [hMsum mu hmu, h2])
      exact hne (hmu1.symm.trans hmu2)
    · apply fcount_zero_of_notmem
      intro mu hmu hmu2
      have ht2 : ptle mu r2 = true := by rw [hmu2]; exact ptle_refl r2
      have ht1 : ptle mu r1 = true := (heq mu hmu).trans ht2
      have hmu1 : mu = r1 :=
        le_eqsum_imp_eq mu r1 (hMlen1 mu hmu) ht1 (by rw [hMsum mu hmu, h1])
      exact hne (hmu1.symm.trans hmu2)
  · intro hd
    rcases hd with ⟨hd1, hd2⟩
    intro mu hmu
    have hn1 : mu ≠ r1 := notmem_of_fcount_zero M r1 hd1 mu hmu
    have hn2 : mu ≠ r2 := notmem_of_fcount_zero M r2 hd2 mu hmu
    have e1 : ptle mu r1 = false := by
      cases hp : ptle mu r1 with
      | false => rfl
      | true =>
          exact absurd
            (le_eqsum_imp_eq mu r1 (hMlen1 mu hmu) hp (by rw [hMsum mu hmu, h1]))
            hn1
    have e2 : ptle mu r2 = false := by
      cases hp : ptle mu r2 with
      | false => rfl
      | true =>
          exact absurd
            (le_eqsum_imp_eq mu r2 (hMlen2 mu hmu) hp (by rw [hMsum mu hmu, h2]))
            hn2
    rw [e1, e2]

/-- CORRECTION 2 (FH1 §2, F-21): capping never merges live states. If two
    DISTINCT sum-S residuals have the same cap, at least one was strictly
    capped (deficient-sum image), forcing the other over budget too via the
    shared image — so BOTH are over-budget, hence dead. Live residuals are
    fixed points of the cap; capping is dead-state pruning and nothing
    more. -/
theorem cap_never_merges_live
    (M : List (List Nat)) (r1 r2 Bmax : List Nat) (S : Nat)
    (hne : r1 ≠ r2)
    (hlen1 : r1.length = Bmax.length) (hlen2 : r2.length = Bmax.length)
    (h1 : r1.sum = S) (h2 : r2.sum = S)
    (hMbound : ∀ mu ∈ M, ptle mu Bmax = true)
    (hmerge : capv r1 Bmax = capv r2 Bmax) :
    Fcount M r1 = 0 ∧ Fcount M r2 = 0 := by
  have hboth : ptle r1 Bmax = false ∧ ptle r2 Bmax = false := by
    cases hp1 : ptle r1 Bmax with
    | true =>
        cases hp2 : ptle r2 Bmax with
        | true =>
            exfalso
            have e1 := capv_eq_self_of_ptle r1 Bmax hlen1 hp1
            have e2 := capv_eq_self_of_ptle r2 Bmax hlen2 hp2
            exact hne ((e1.symm.trans hmerge).trans e2)
        | false =>
            exfalso
            have hlt := capv_sum_lt hlen2 hp2
            have e1 := capv_eq_self_of_ptle r1 Bmax hlen1 hp1
            rw [← hmerge, e1, h1, h2] at hlt
            exact Nat.lt_irrefl S hlt
    | false =>
        cases hp2 : ptle r2 Bmax with
        | true =>
            exfalso
            have hlt := capv_sum_lt hlen1 hp1
            have e2 := capv_eq_self_of_ptle r2 Bmax hlen2 hp2
            rw [hmerge, e2, h2, h1] at hlt
            exact Nat.lt_irrefl S hlt
        | false => exact ⟨rfl, rfl⟩
  exact ⟨fcount_zero_of_over M r1 Bmax hboth.1 hMbound,
         fcount_zero_of_over M r2 Bmax hboth.2 hMbound⟩

/-- F-21 sanity: two distinct dead residuals ([4,0] and [0,4] against
    completions [[2,2],[1,3]]) are future-equivalent. -/
example : ∀ mu ∈ [[2, 2], [1, 3]], ptle mu [4, 0] = ptle mu [0, 4] :=
  (no_live_lumping [[2, 2], [1, 3]] [4, 0] [0, 4] 4 (by decide) (by decide)
    (by decide) (by decide) (by decide) (by decide)).mpr ⟨by decide, by decide⟩

/-- F-21 sanity (the live side, negatively): two distinct LIVE residuals are
    NOT future-equivalent — each one's own completion distinguishes them. -/
example : ¬ (∀ mu ∈ [[2, 2], [1, 3]], ptle mu [2, 2] = ptle mu [1, 3]) := by
  decide

/-- F-21 sanity for Correction 2: [3,1] and [2,2] share the cap [1,1] under
    Bmax [1,1] — and indeed both are dead against any Bmax-respecting
    completion set. -/
example : Fcount [[1, 1], [1, 0]] [3, 1] = 0 ∧ Fcount [[1, 1], [1, 0]] [2, 2] = 0 :=
  cap_never_merges_live [[1, 1], [1, 0]] [3, 1] [2, 2] [1, 1] 4 (by decide)
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)

/-! ### TR-11 §10(vi) / §2–3: orbit-transfer exactness of the symmetry-quotient DP
    (2026-07-21)

    Machine-checks, at the model level, the mathematical core of TR-11's
    orbit-quotient layered DP (`solve --f1-exact-c1c2c4[c5]`): that the
    quotient ("gather") formulation computes the SAME counts as the plain
    non-quotient layered DP. Until now this argument was prose (TR-11 §2–3)
    plus empirical plain-vs-quotient agreement on group-closed subsets to
    n = 28 pairs; this section closes the mathematical half of TR-11
    §10(vi)'s single-instrument caveat. Two independent claims:

    1. VALUE TRANSFER (`dp_orbit_invariant`, `orbit_transfer_exact`):
       plain-DP forward values are constant on orbits, and the gather
       recursion — each new-layer target pulls from CANONICALIZED
       predecessors, reading each raw predecessor state s through an
       arbitrary within-orbit redirection Γ s (concretely: canonicalize the
       predecessor mask by g, look up the stored entry, map the stored
       `last` key through g⁻¹ — solve.c's `ginv[]` in f1_gather_layer /
       f1c5_gather_entries) — reproduces the EXACT plain-DP value at every
       state. No stabilizer weight ever enters the values, which is
       precisely why the NON-free mask action (TR-11 §2's caution) is
       harmless here; freeness is never assumed.

    2. STABILIZER BOOKKEEPING (`mass_partition`, `orbit_stabilizer_mult`,
       `stabilizer_weighted_mass`): the per-layer total-mass identity used
       as the runtime plain-vs-quotient gate. For a G-closed layer of
       masks, summing an orbit-constant mass over canonical representatives
       weighted by orbit size reproduces the plain layer mass, where the
       weight the code uses (|G| / |stab|, solve.c f1_orbit_size) is
       correct EXACTLY when orbit-stabilizer holds — proved here in the
       division-free form  multiplicity(c) × |stab(c)| = |G|  (so the
       code's runtime divisibility F1_CHECK is also explained, not just
       assumed). `mask_marginal_orbit_const` supplies the glue: the
       mask-marginal Σ_l f(m, l) is orbit-constant BECAUSE the sum over
       `last` reindexes under the hexagram bijection — the value-level
       equivariance f(g·m, g·l) = f(m, l) does NOT give pointwise
       f(g·m, l) = f(m, l), a spot where prose could slip.

    Model: states form a list; the plain DP `dp` and the gather DP `dpq`
    share the recursion  F(k+1, t) = Σ_s w(s, t) · F(k, s)  over that list,
    with `dpq` reading F(k, ·) at Γ s instead of s. The group is a list of
    self-maps with hypotheses (they permute the state list; w and init are
    equivariant); for the counting theorems the group is an abstract
    carrier with mul/inv and the group laws taken as hypotheses in
    action form. As everywhere in this file, the bridge facts to solve.c
    are prose + runtime gates, NOT machine-checked; the instantiation is:
    · states = (used-pair-mask, last-exit-hexagram[, C5 residual]) tuples;
      w s t = number of admissible single-pair placements from s to t
      (0/1 here; includes the C2 Hamming-5 check and, in the C5-tracked
      DP, the budget-kill p_d < B0_d — whose exactness is `capping_exact`
      above); init = the C4 pinned start (mass 1 at the empty mask,
      last = Kun's exit).
    · the group is TR-5's 24 pair-permutations with their hexagram lifts;
      w-equivariance is the prose fact that each element is a Hamming
      isometry mapping pair i (and its two orientations) to pair σ(i);
      init-equivariance is start_exit ∈ {0, 63} being G-fixed (checked at
      runtime by F1_CHECK). In the C5-tracked DP the residual coordinate
      is G-FIXED because an isometry preserves distance classes — which is
      why f1c5_gather_entries maps only `last` through ginv and copies the
      residual key unchanged; that bridge fact is carried by the runtime
      per-layer mass gates, not proved here.
    · Γ s = (canonicalizing element of s's mask) applied to s — the model's
      hypothesis (∃ g ∈ G, Γ s = g s) covers f1_canon's specific min-image
      tie-break and any other choice.
    What is NOT covered (unchanged status): the C implementation bridge
    (layer files, sparse absent-=-zero storage, canonical-mask table
    lookup, 192-bit arithmetic) — prose + the runtime gates + the
    empirical n ≤ 28 plain-vs-quotient agreement; and TR-11 §10(vi)'s
    independent-engine recomputation, which this section does not replace.

    Attribution: the orbit-quotient design is TR-11's (operator direction,
    Claude implementation); the mathematics here is standard finite group
    theory (equivariant dynamic programming; orbit-stabilizer) — no
    novelty is claimed for the arguments, only this machine-checked
    packaging (Claude, Fable 5, 2026-07-21; corrections welcome). -/

namespace OrbitTransfer

/-! #### List plumbing (hand-rolled to stay within stable core API) -/

/-- sums are invariant under list permutation. -/
theorem sum_perm : ∀ {l₁ l₂ : List Nat}, l₁.Perm l₂ → l₁.sum = l₂.sum := by
  intro l₁ l₂ h
  induction h with
  | nil => rfl
  | cons x _ ih => simp only [List.sum_cons, ih]
  | swap x y l => simp only [List.sum_cons]; omega
  | trans _ _ ih₁ ih₂ => exact ih₁.trans ih₂

/-- mapped sums agree when the functions agree on members. -/
theorem map_congr_mem {α β : Type} : ∀ {l : List α} {f g : α → β},
    (∀ a ∈ l, f a = g a) → l.map f = l.map g := by
  intro l
  induction l with
  | nil => intro f g _; rfl
  | cons a t ih =>
      intro f g h
      simp only [List.map_cons]
      rw [h a (List.mem_cons_self ..), ih (fun x hx => h x (List.mem_cons_of_mem a hx))]

/-- reindexing a sum over a list by a self-map that permutes the list. -/
theorem sum_reindex {α : Type} (l : List α) (g : α → α)
    (hperm : (l.map g).Perm l) (F : α → Nat) :
    (l.map fun s => F (g s)).sum = (l.map F).sum := by
  have h := sum_perm (hperm.map F)
  rw [List.map_map] at h
  exact h

/-- sum of a pointwise Nat sum splits. -/
theorem sum_map_add {α : Type} (l : List α) (f g : α → Nat) :
    (l.map fun x => f x + g x).sum = (l.map f).sum + (l.map g).sum := by
  induction l with
  | nil => rfl
  | cons a t ih => simp only [List.map_cons, List.sum_cons, ih]; omega

/-- sum of zeros is zero. -/
theorem sum_map_zero {α : Type} (l : List α) : (l.map fun _ => (0 : Nat)).sum = 0 := by
  induction l with
  | nil => rfl
  | cons a t ih => simp only [List.map_cons, List.sum_cons, ih]

/-- a delta-sum over a list missing the support point vanishes. -/
theorem sum_delta_notmem {α : Type} [DecidableEq α] (x : α) (f : α → Nat) :
    ∀ (l : List α), x ∉ l → (l.map fun m => if x = m then f m else 0).sum = 0 := by
  intro l
  induction l with
  | nil => intro _; rfl
  | cons a t ih =>
      intro hx
      simp only [List.mem_cons, not_or] at hx
      simp only [List.map_cons, List.sum_cons, if_neg hx.1, ih hx.2]

/-- delta-sum over a duplicate-free list containing the support point. -/
theorem sum_delta {α : Type} [DecidableEq α] (x : α) (f : α → Nat) :
    ∀ (l : List α), l.Nodup → x ∈ l →
      (l.map fun m => if x = m then f m else 0).sum = f x := by
  intro l
  induction l with
  | nil => intro _ hx; cases hx
  | cons a t ih =>
      intro hnd hx
      rw [List.nodup_cons] at hnd
      simp only [List.map_cons, List.sum_cons]
      rcases List.mem_cons.mp hx with rfl | hxt
      · rw [if_pos rfl, sum_delta_notmem x f t hnd.1]
        omega
      · have hne : x ≠ a := fun e => hnd.1 (e ▸ hxt)
        rw [if_neg hne, ih hnd.2 hxt]
        omega

/-- countP is invariant under list permutation. -/
theorem perm_countP {α : Type} (p : α → Bool) :
    ∀ {l₁ l₂ : List α}, l₁.Perm l₂ → l₁.countP p = l₂.countP p := by
  intro l₁ l₂ h
  induction h with
  | nil => rfl
  | cons x _ ih => simp only [List.countP_cons, ih]
  | swap x y l => simp only [List.countP_cons]; omega
  | trans _ _ ih₁ ih₂ => exact ih₁.trans ih₂

/-- countP over a mapped list is countP of the composition. -/
theorem countP_map' {α β : Type} (p : β → Bool) (f : α → β) :
    ∀ (l : List α), (l.map f).countP p = l.countP fun a => p (f a) := by
  intro l
  induction l with
  | nil => rfl
  | cons a t ih => simp only [List.map_cons, List.countP_cons, ih]

/-- countP agrees for predicates equal on members. -/
theorem countP_congr_mem {α : Type} {p q : α → Bool} :
    ∀ {l : List α}, (∀ a ∈ l, p a = q a) → l.countP p = l.countP q := by
  intro l
  induction l with
  | nil => intro _; rfl
  | cons a t ih =>
      intro h
      simp only [List.countP_cons, h a (List.mem_cons_self ..),
        ih (fun x hx => h x (List.mem_cons_of_mem a hx))]

/-- a predicate false on every member counts zero. -/
theorem countP_eq_zero_of_none {α : Type} (p : α → Bool) :
    ∀ (l : List α), (∀ a ∈ l, p a = false) → l.countP p = 0 := by
  intro l
  induction l with
  | nil => intro _; rfl
  | cons a t ih =>
      intro h
      simp [h a (List.mem_cons_self ..),
        ih (fun x hx => h x (List.mem_cons_of_mem a hx))]

/-- a member satisfying the predicate makes the count positive. -/
theorem countP_pos_of_mem {α : Type} (p : α → Bool) (l : List α) (b : α)
    (hb : b ∈ l) (hp : p b = true) : 0 < l.countP p :=
  List.countP_pos_iff.mpr ⟨b, hb, hp⟩

/-- an indicator-weighted constant sums to countP × the constant. -/
theorem sum_if_countP {α : Type} (p : α → Bool) (k : Nat) :
    ∀ (l : List α), (l.map fun b => if p b then k else 0).sum = l.countP p * k := by
  intro l
  induction l with
  | nil => simp
  | cons a t ih =>
      simp only [List.map_cons, List.sum_cons, List.countP_cons, ih]
      cases hpa : p a <;> simp [Nat.add_mul] <;> omega

/-! #### Part 1 — value transfer: the gather DP computes exact plain-DP values -/

/-- the plain layered forward DP: `dp k t` = mass at state t after k transfer
    steps (solve.c's f(mask, last): k = mask popcount, t ranges over states,
    w s t = admissible-placement multiplicity, init = the C4-pinned start). -/
def dp {S : Type} (states : List S) (w : S → S → Nat) (init : S → Nat) :
    Nat → S → Nat
  | 0, t => init t
  | k + 1, t => (states.map fun s => w s t * dp states w init k s).sum

/-- the gather (orbit-quotient) DP: the SAME recursion, but every fetch of the
    previous layer is redirected through Γ — concretely, canonicalize the
    predecessor's mask by the group element g and read the stored `last` key
    through g⁻¹ (f1_gather_layer / f1c5_gather_entries), i.e. read the entry
    at Γ s = g·s instead of s. -/
def dpq {S : Type} (states : List S) (w : S → S → Nat) (init : S → Nat)
    (Γ : S → S) : Nat → S → Nat
  | 0, t => init t
  | k + 1, t => (states.map fun s => w s t * dpq states w init Γ k (Γ s)).sum

/-- DP EQUIVARIANCE: if a self-map g permutes the state list and leaves the
    transfer weights and the initial condition invariant, plain-DP values are
    constant along g: f(k, g·t) = f(k, t). Freeness is NOT assumed — the
    statement is indifferent to fixed points of g. -/
theorem dp_orbit_invariant {S : Type} (states : List S) (w : S → S → Nat)
    (init : S → Nat) (g : S → S)
    (hperm : (states.map g).Perm states)
    (hw : ∀ s ∈ states, ∀ t : S, w (g s) (g t) = w s t)
    (hinit : ∀ t : S, init (g t) = init t) :
    ∀ (k : Nat) (t : S), dp states w init k (g t) = dp states w init k t := by
  intro k
  induction k with
  | zero => intro t; exact hinit t
  | succ k ih =>
      intro t
      show (states.map fun s => w s (g t) * dp states w init k s).sum
         = (states.map fun s => w s t * dp states w init k s).sum
      rw [← sum_reindex states g hperm (fun s => w s (g t) * dp states w init k s)]
      exact congrArg List.sum (map_congr_mem fun s hs => by rw [hw s hs t, ih s])

/-- ORBIT-TRANSFER EXACTNESS (TR-11 §3's gather formulation): if every group
    element permutes the states and preserves w and init, and the redirection
    Γ moves each state within its group orbit (∃ g ∈ G, Γ s = g s — solve.c:
    canonicalize the mask, map `last` through the inverse lift), then the
    gather DP equals the plain DP at EVERY state and layer — in particular at
    every canonical representative, and at the G-fixed full mask whose stored
    row is the final exact total. No orbit weights enter, so non-trivial
    prefix stabilizers cannot corrupt the values. -/
theorem orbit_transfer_exact {S : Type} (states : List S) (w : S → S → Nat)
    (init : S → Nat) (G : List (S → S)) (Γ : S → S)
    (hperm : ∀ g ∈ G, (states.map g).Perm states)
    (hw : ∀ g ∈ G, ∀ s ∈ states, ∀ t : S, w (g s) (g t) = w s t)
    (hinit : ∀ g ∈ G, ∀ t : S, init (g t) = init t)
    (hΓ : ∀ s ∈ states, ∃ g ∈ G, Γ s = g s) :
    ∀ (k : Nat) (t : S), dpq states w init Γ k t = dp states w init k t := by
  intro k
  induction k with
  | zero => intro t; rfl
  | succ k ih =>
      intro t
      show (states.map fun s => w s t * dpq states w init Γ k (Γ s)).sum
         = (states.map fun s => w s t * dp states w init k s).sum
      refine congrArg List.sum (map_congr_mem fun s hs => ?_)
      rcases hΓ s hs with ⟨g, hgG, hΓs⟩
      rw [ih (Γ s), hΓs,
          dp_orbit_invariant states w init g (hperm g hgG) (hw g hgG) (hinit g hgG) k s]

/-- glue for Part 2: the MASK-MARGINAL Σ_l f(m, l) is orbit-constant. Note the
    subtlety this encodes: value-level equivariance gives f(g·m, g·l) = f(m, l),
    NOT f(g·m, l) = f(m, l); the marginal is invariant only because the sum
    over `last` reindexes under the hexagram bijection gH. (`emb m l` builds
    the state (m, l); `hcompat` says g acts componentwise.) -/
theorem mask_marginal_orbit_const {S M H : Type} (states : List S)
    (w : S → S → Nat) (init : S → Nat) (lasts : List H)
    (emb : M → H → S) (g : S → S) (gM : M → M) (gH : H → H)
    (hcompat : ∀ (m : M) (l : H), g (emb m l) = emb (gM m) (gH l))
    (hlperm : (lasts.map gH).Perm lasts)
    (hperm : (states.map g).Perm states)
    (hw : ∀ s ∈ states, ∀ t : S, w (g s) (g t) = w s t)
    (hinit : ∀ t : S, init (g t) = init t) (k : Nat) (m : M) :
    (lasts.map fun l => dp states w init k (emb (gM m) l)).sum
      = (lasts.map fun l => dp states w init k (emb m l)).sum := by
  rw [← sum_reindex lasts gH hlperm (fun l => dp states w init k (emb (gM m) l))]
  refine congrArg List.sum (map_congr_mem fun l _ => ?_)
  rw [← hcompat m l, dp_orbit_invariant states w init g hperm hw hinit k (emb m l)]

/-! #### Part 2 — stabilizer bookkeeping: the weighted per-layer mass identity
    (the runtime plain-vs-quotient gate), correct WITHOUT freeness. -/

/-- MASS PARTITION: for an orbit-constant mass v and a canonicalization that
    moves masks within their orbits, the plain layer mass equals the sum over
    representatives weighted by CANONICALIZATION MULTIPLICITY (the number of
    layer masks canonicalizing to each representative). Pure counting — no
    group structure beyond the witness. -/
theorem mass_partition {α M : Type} [DecidableEq M]
    (G : List α) (act : α → M → M) (L R : List M) (canQ : M → M) (v : M → Nat)
    (hv : ∀ g ∈ G, ∀ m : M, v (act g m) = v m)
    (hwit : ∀ m ∈ L, ∃ g ∈ G, canQ m = act g m)
    (hRnd : R.Nodup) (hRcomp : ∀ m ∈ L, canQ m ∈ R) :
    (L.map v).sum
      = (R.map fun c => L.countP (fun m => decide (canQ m = c)) * v c).sum := by
  induction L with
  | nil =>
      rw [map_congr_mem (l := R) (f := fun c => List.countP _ [] * v c)
            (g := fun _ => 0) (fun c _ => by simp), sum_map_zero]
      rfl
  | cons m t ih =>
      have hwt : ∀ x ∈ t, ∃ g ∈ G, canQ x = act g x :=
        fun x hx => hwit x (List.mem_cons_of_mem m hx)
      have hRt : ∀ x ∈ t, canQ x ∈ R :=
        fun x hx => hRcomp x (List.mem_cons_of_mem m hx)
      have hsplit : (R.map fun c => (m :: t).countP (fun x => decide (canQ x = c)) * v c)
          = R.map fun c => t.countP (fun x => decide (canQ x = c)) * v c
              + (if canQ m = c then v c else 0) := by
        refine map_congr_mem fun c _ => ?_
        rw [List.countP_cons]
        by_cases hmc : canQ m = c
        · simp [hmc, Nat.add_mul]
        · simp [hmc]
      rw [List.map_cons, List.sum_cons, hsplit, sum_map_add, ih hwt hRt,
          sum_delta (canQ m) v R hRnd (hRcomp m (List.mem_cons_self ..))]
      rcases hwit m (List.mem_cons_self ..) with ⟨g, hgG, hg⟩
      rw [hg, hv g hgG m]
      omega

/-- all fibers of g ↦ g·c over one orbit have stabilizer size: left
    translation by g₁ permutes the group list and carries the stabilizer of c
    onto the fiber over g₁·c. This is the orbit-stabilizer engine. -/
theorem stab_fiber_eq {α M : Type} [DecidableEq M] (G : List α)
    (act : α → M → M) (mul : α → α → α) (inv : α → α) (c : M) (g₁ : α)
    (htrans : (G.map (mul g₁)).Perm G)
    (hact_mul : ∀ g h m, act (mul g h) m = act g (act h m))
    (hact_inv : ∀ g m, act (inv g) (act g m) = m) :
    G.countP (fun g => decide (act g c = act g₁ c))
      = G.countP fun g => decide (act g c = c) := by
  rw [← perm_countP (fun g => decide (act g c = act g₁ c)) htrans, countP_map']
  refine countP_congr_mem fun g _ => ?_
  simp only [hact_mul, decide_eq_decide]
  constructor
  · intro h
    have h2 := congrArg (act (inv g₁)) h
    rwa [hact_inv, hact_inv] at h2
  · intro h; rw [h]

/-- each group element lands its image of c somewhere in the (Nodup, closed)
    layer list, so |G| decomposes as the sum of fiber sizes over the layer. -/
theorem fiber_partition {α M : Type} [DecidableEq M] (act : α → M → M) (c : M)
    (L : List M) (hLnd : L.Nodup) :
    ∀ (G : List α), (∀ g ∈ G, act g c ∈ L) →
      G.length = (L.map fun m => G.countP fun g => decide (act g c = m)).sum := by
  intro G
  induction G with
  | nil =>
      intro _
      rw [map_congr_mem (f := fun m => ([] : List α).countP fun g => decide (act g c = m))
            (g := fun _ => 0) (fun m _ => by simp), sum_map_zero]
      rfl
  | cons g₀ Gs ih =>
      intro hmem
      have hstep : (L.map fun m => (g₀ :: Gs).countP fun g => decide (act g c = m))
          = L.map fun m => (Gs.countP fun g => decide (act g c = m))
              + (if act g₀ c = m then 1 else 0) := by
        refine map_congr_mem fun m _ => ?_
        rw [List.countP_cons]
        by_cases h : act g₀ c = m
        · simp [h]
        · simp [h]
      rw [hstep, sum_map_add, ← ih (fun g hg => hmem g (List.mem_cons_of_mem g₀ hg)),
          sum_delta (act g₀ c) (fun _ => 1) L hLnd (hmem g₀ (List.mem_cons_self ..))]
      rfl

/-- ORBIT-STABILIZER, division-free (TR-11 §2's "standard orbit-DP
    bookkeeping" for the NON-free mask action): for a canonical
    representative c in a Nodup, G-closed layer list,
    multiplicity(c) × |stab(c)| = |G| — the code's orbit size |G|/|stab|
    (solve.c f1_orbit_size, with its runtime divisibility F1_CHECK) is
    exactly the number of layer masks canonicalizing to c. Group laws enter
    as action-level hypotheses (left-translation permutes the group list;
    composition and inverses act as expected). -/
theorem orbit_stabilizer_mult {α M : Type} [DecidableEq M]
    (G : List α) (act : α → M → M) (mul : α → α → α) (inv : α → α)
    (L : List M) (canQ : M → M) (c : M)
    (hLnd : L.Nodup) (hcc : canQ c = c)
    (hGc : ∀ g ∈ G, act g c ∈ L)
    (hwit : ∀ m ∈ L, ∃ g ∈ G, canQ m = act g m)
    (hconst : ∀ g ∈ G, ∀ m : M, canQ (act g m) = canQ m)
    (htrans : ∀ g ∈ G, (G.map (mul g)).Perm G)
    (hact_mul : ∀ g h m, act (mul g h) m = act g (act h m))
    (hact_inv : ∀ g m, act (inv g) (act g m) = m)
    (hGinv : ∀ g ∈ G, inv g ∈ G) :
    L.countP (fun m => decide (canQ m = c))
        * G.countP (fun g => decide (act g c = c)) = G.length := by
  rw [fiber_partition act c L hLnd G hGc]
  have hclass : (L.map fun m => G.countP fun g => decide (act g c = m))
      = L.map fun m => if decide (canQ m = c)
          then G.countP fun g => decide (act g c = c) else 0 := by
    refine map_congr_mem fun m hm => ?_
    by_cases hmc : canQ m = c
    · rcases hwit m hm with ⟨gw, hgw, hcanm⟩
      have hgm : act gw m = c := by rw [← hcanm, hmc]
      have hminv : m = act (inv gw) c := by rw [← hgm, hact_inv]
      have hfib := stab_fiber_eq G act mul inv c (inv gw)
        (htrans (inv gw) (hGinv gw hgw)) hact_mul hact_inv
      rw [← hminv] at hfib
      simp only [hmc, decide_true, if_true]
      exact hfib
    · simp only [hmc, decide_false, Bool.false_eq_true, if_false]
      refine countP_eq_zero_of_none _ G fun g hg => ?_
      simp only [decide_eq_false_iff_not]
      intro heq
      exact hmc (by rw [← heq, hconst g hg, hcc])
  rw [hclass, sum_if_countP]

/-- STABILIZER-WEIGHTED MASS IDENTITY (TR-11 §3: "Σ_orbits orbit_size ×
    quotient value = plain layer mass"): given orbit sizes satisfying
    orbit-stabilizer (osize c × |stab c| = |G| — what f1_orbit_size computes
    and F1_CHECKs), the weighted sum over canonical representatives equals
    the plain sum over the whole G-closed layer. Combines `mass_partition`
    with `orbit_stabilizer_mult` by cancelling the (positive) stabilizer
    count. This is the identity behind the per-layer runtime mass gate; the
    final total needs none of it (the full mask's row is exact by
    `orbit_transfer_exact` alone). -/
theorem stabilizer_weighted_mass {α M : Type} [DecidableEq M]
    (G : List α) (act : α → M → M) (mul : α → α → α) (inv : α → α)
    (L R : List M) (canQ : M → M) (v osize : M → Nat)
    (hLnd : L.Nodup) (hRnd : R.Nodup)
    (hv : ∀ g ∈ G, ∀ m : M, v (act g m) = v m)
    (hwit : ∀ m ∈ L, ∃ g ∈ G, canQ m = act g m)
    (hRcomp : ∀ m ∈ L, canQ m ∈ R)
    (hRL : ∀ c ∈ R, c ∈ L) (hRfix : ∀ c ∈ R, canQ c = c)
    (hLclosed : ∀ g ∈ G, ∀ m ∈ L, act g m ∈ L)
    (hconst : ∀ g ∈ G, ∀ m : M, canQ (act g m) = canQ m)
    (htrans : ∀ g ∈ G, (G.map (mul g)).Perm G)
    (hact_mul : ∀ g h m, act (mul g h) m = act g (act h m))
    (hact_inv : ∀ g m, act (inv g) (act g m) = m)
    (hGinv : ∀ g ∈ G, inv g ∈ G)
    (hid : ∃ g ∈ G, ∀ m : M, act g m = m)
    (hosize : ∀ c ∈ R,
      osize c * G.countP (fun g => decide (act g c = c)) = G.length) :
    (L.map v).sum = (R.map fun c => osize c * v c).sum := by
  rw [mass_partition G act L R canQ v hv hwit hRnd hRcomp]
  refine congrArg List.sum (map_congr_mem fun c hc => ?_)
  have hmult := orbit_stabilizer_mult G act mul inv L canQ c hLnd
    (hRfix c hc) (fun g hg => hLclosed g hg c (hRL c hc)) hwit hconst htrans
    hact_mul hact_inv hGinv
  rcases hid with ⟨g₀, hg₀G, hg₀⟩
  have hpos : 0 < G.countP fun g => decide (act g c = c) :=
    countP_pos_of_mem _ G g₀ hg₀G (by simp [hg₀ c])
  rw [Nat.eq_of_mul_eq_mul_right hpos (hmult.trans (hosize c hc).symm)]

/-! #### Sanity instantiations (tiny concrete cases; hypotheses discharged by
    `decide`/explicit permutations — witnesses that the hypothesis sets are
    satisfiable and correctly shaped, in the style of the sections above). -/

/-- transfer sanity: a 2-state system with the swap symmetry, quotiented onto
    the single representative 0 (Γ = const 0: every fetch is redirected to
    the stored representative). The gather DP reproduces the plain DP. -/
example :
    dpq [(0 : Fin 2), 1] (fun s t => if s = t then 2 else 3) (fun _ => 1)
        (fun _ => 0) 2 1
      = dp [(0 : Fin 2), 1] (fun s t => if s = t then 2 else 3) (fun _ => 1) 2 1 := by
  refine orbit_transfer_exact _ _ _ [id, fun s => if s = 0 then 1 else 0] _
    ?_ ?_ ?_ ?_ 2 1
  · intro g hg
    rcases List.mem_cons.mp hg with rfl | hg'
    · exact List.Perm.refl _
    · rcases List.mem_cons.mp hg' with rfl | h
      · exact (List.Perm.swap 1 0 []).symm
      · cases h
  · intro g hg
    rcases List.mem_cons.mp hg with rfl | hg'
    · intro s _ t; rfl
    · rcases List.mem_cons.mp hg' with rfl | h
      · intro s _ t; revert s t; decide
      · cases h
  · intro g hg
    rcases List.mem_cons.mp hg with rfl | hg'
    · intro t; rfl
    · rcases List.mem_cons.mp hg' with rfl | h
      · intro t; rfl
      · cases h
  · intro s hs
    rcases List.mem_cons.mp hs with rfl | hs'
    · exact ⟨id, List.mem_cons_self .., rfl⟩
    · rcases List.mem_cons.mp hs' with rfl | h
      · exact ⟨fun s => if s = 0 then 1 else 0, List.mem_cons_of_mem _ (List.mem_cons_self ..), rfl⟩
      · cases h

/-- stabilizer sanity — a genuinely NON-free action: Z/2 acts on masks
    {0, 1, 2} fixing 0 (stabilizer 2, orbit size 1) and swapping 1 ↔ 2
    (stabilizer 1, orbit size 2). Representatives R = [0, 1] with the code's
    weights osize = [1, 2]: weighted mass 1·7 + 2·5 = plain mass 7 + 5 + 5. -/
example :
    (([0, 1, 2] : List (Fin 3)).map fun m => if m = 0 then 7 else 5).sum
      = (([0, 1] : List (Fin 3)).map fun c =>
          (if c = 0 then 1 else 2) * (if c = 0 then 7 else 5)).sum := by
  refine stabilizer_weighted_mass [(0 : Fin 2), 1]
    (fun g m => if g = 0 then m else (if m = 1 then 2 else if m = 2 then 1 else m))
    (fun a b => a + b) (fun a => a) [0, 1, 2] [0, 1]
    (fun m => if m = 2 then 1 else m) _ (fun c => if c = 0 then 1 else 2)
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)
    (by decide) ?_ (by decide) ?_ (by decide) (by decide) (by decide) ?_ (by decide)
  · intro g hg
    rcases List.mem_cons.mp hg with rfl | hg'
    · intro m hm; simpa using hm
    · rcases List.mem_cons.mp hg' with rfl | h
      · intro m hm; revert hm; revert m; decide
      · cases h
  · intro g hg
    rcases List.mem_cons.mp hg with rfl | hg'
    · exact List.Perm.refl _
    · rcases List.mem_cons.mp hg' with rfl | h
      · exact (List.Perm.swap 1 0 []).symm
      · cases h
  · exact ⟨0, List.mem_cons_self .., by decide⟩

end OrbitTransfer

/-! ### C3 G-channel: capping soundness of the slot-weighted lower-bound prune
    (BACKLOG-2 prerequisite, 2026-07-22)

    Machine-checks the §2 obligation of the C3 G-channel design
    (roae-private DESIGN_C3_GCHANNEL_2026_07_21.md): the exact-counting DP
    augmented with running-G (C3 = 16 + 8·G on C1-valid orderings,
    `C3Decomposition.lean`; C3 ≤ 776 ⟺ G ≤ 95) may DROP any state whose
    running-G plus the admissible lower bound
        LB(m, o, u) = o·m + o(o+1)/2 + u
    exceeds the threshold — where, after m placements (slots 1..m used,
    remaining slots exactly {m+1..31}), o couples are open (one member
    placed) and u couples are fully unplaced. This is a dead-state drop in
    the mold of `c3_prune_sound` above (an admissible lower bound), NOT a
    cap-collapse in the mold of `capping_exact`; exactness needs only that
    LB be a TRUE lower bound on every completion's remaining G increment —
    achievability affects savings, never correctness.

    Model (the completion's contribution, re-derived from the running-G
    accumulation rule: open at slot s does G −= s, close at slot t does
    G += t):
        finalG = runningG + Σ_{open couples} closeSlot + Σ_{unplaced} diff
    · `closes` — the o close slots of the currently-open couples: DISTINCT
      (slot assignment is injective) and each > m (remaining slots are
      {m+1..31}; the DP fills slots in order, so contiguity holds on every
      reachable state — carried as the hypotheses `hnd`/`hcl`);
    · `diffs` — each unplaced couple's |slot(P) − slot(P′)|: ≥ 1 (two
      distinct slots — hypothesis `hdf`).
    These hypotheses quantify over a SUPERSET of the DP's legal completions
    (C2/C4/C5/orbit constraints only shrink the completion set), so the
    bound holds a fortiori for every legal completion. The o distinct
    close slots each > m sum to at least (m+1)+⋯+(m+o) = o·m + tri o —
    `sum_distinct_min_slots`, the load-bearing lemma.

    What is machine-checked here (model level):
    · `sum_distinct_min_slots` — LB VALIDITY core: o distinct naturals,
      each > m, sum to ≥ o·m + tri o (min-extraction induction).
    · `g_prune_sound` — a fired prune (thresh < runningG + LB) forces
      EVERY completion's final G past the threshold (running-G is signed,
      so the statement is over Int).
    · `g_prune_exact` — the counting form: at a fired state, the number of
      completions with final G ≤ thresh is 0 — dropping the state changes
      no G ≤ thresh count (with the prune off, the final filter counts the
      same completions; runtime gate G5 cross-checks this empirically).
    · `gLB_step_self` / `gLB_step_open` / `gLB_step_close` — MONOTONICITY:
      along any transition (place a self-pair / open a couple / close a
      couple at slot m+1), runningG + LB rises by exactly o / 2o / 0.
      A pruned state's descendants would all be pruned, so the predicate
      may be applied at entry creation only.

    Bridge facts (stated, NOT machine-checked — same discipline as the
    F-53 section): solve.c's running-g accumulator equals the model's
    (open/close from one partner_pair mask test), o/u are correctly
    recomputed from the mask, and reachable states have remaining slots
    exactly {m+1..31}. These are carried by the runtime gates
    (G1–G7 of the design, esp. G5 capped ≡ uncapped-then-filter) and code
    review.

    Attribution: the capping direction is the operator's (FH-1); the LB
    derivation and this machine-checked packaging are Claude's (Fable 5,
    design 2026-07-21, formalization 2026-07-22). The argument is standard
    branch-and-bound admissible-bound pruning (no novelty claimed;
    corrections welcome). -/

namespace GPrune

/-- triangle numbers: `tri o` = 1 + 2 + ⋯ + o. -/
def tri : Nat → Nat
  | 0 => 0
  | n + 1 => tri n + (n + 1)

/-- `tri` is the prose's o(o+1)/2, in division-free form. -/
theorem tri_spec : ∀ o : Nat, 2 * tri o = o * (o + 1)
  | 0 => rfl
  | n + 1 => by
      show 2 * (tri n + (n + 1)) = (n + 1) * (n + 2)
      calc 2 * (tri n + (n + 1))
          = 2 * tri n + 2 * (n + 1) := by rw [Nat.mul_add]
        _ = n * (n + 1) + 2 * (n + 1) := by rw [tri_spec n]
        _ = (n + 2) * (n + 1) := by rw [← Nat.add_mul]
        _ = (n + 1) * (n + 2) := Nat.mul_comm ..

/-- the admissible completion lower bound of design §2.2:
    LB(m, o, u) = o·m + o(o+1)/2 + u. -/
def LB (m o u : Nat) : Nat := o * m + tri o + u

/-- every nonempty list of naturals has a minimal element. -/
theorem exists_min : ∀ (l : List Nat), l ≠ [] → ∃ a, a ∈ l ∧ ∀ x ∈ l, a ≤ x := by
  intro l
  induction l with
  | nil => intro h; exact absurd rfl h
  | cons a t ih =>
      intro _
      cases t with
      | nil =>
          refine ⟨a, List.mem_cons_self .., fun x hx => ?_⟩
          rcases List.mem_cons.mp hx with rfl | h
          · exact Nat.le_refl _
          · cases h
      | cons b u =>
          rcases ih (by simp) with ⟨c, hc, hcmin⟩
          rcases Nat.le_total a c with hac | hca
          · refine ⟨a, List.mem_cons_self .., fun x hx => ?_⟩
            rcases List.mem_cons.mp hx with rfl | hxt
            · exact Nat.le_refl _
            · exact Nat.le_trans hac (hcmin x hxt)
          · refine ⟨c, List.mem_cons_of_mem a hc, fun x hx => ?_⟩
            rcases List.mem_cons.mp hx with rfl | hxt
            · exact hca
            · exact hcmin x hxt

/-- LB VALIDITY core (the load-bearing lemma): the sum of o DISTINCT
    naturals, each > m, is at least (m+1) + (m+2) + ⋯ + (m+o)
    = o·m + tri o. Induction on o, extracting the minimum: the min is
    ≥ m+1, and the remaining o−1 elements are distinct and > m+1. -/
theorem sum_distinct_min_slots : ∀ (o m : Nat) (l : List Nat),
    l.length = o → l.Nodup → (∀ x ∈ l, m < x) →
    o * m + tri o ≤ l.sum := by
  intro o
  induction o with
  | zero =>
      intro m l _ _ _
      show 0 * m + tri 0 ≤ l.sum
      simp [tri]
  | succ n ih =>
      intro m l hlen hnd hlb
      have hne : l ≠ [] := by
        intro h; rw [h] at hlen; cases hlen
      rcases exists_min l hne with ⟨a, haml, hamin⟩
      rcases List.append_of_mem haml with ⟨s, t, rfl⟩
      have hperm : (s ++ a :: t).Perm (a :: (s ++ t)) := List.perm_middle
      have hnd' : (a :: (s ++ t)).Nodup := hperm.nodup hnd
      rw [List.nodup_cons] at hnd'
      have hlen' : (s ++ t).length = n := by
        simp only [List.length_append, List.length_cons] at hlen ⊢
        omega
      have hlb' : ∀ x ∈ s ++ t, m + 1 < x := by
        intro x hx
        have hxl : x ∈ s ++ a :: t := hperm.mem_iff.mpr (List.mem_cons_of_mem a hx)
        have hax : a ≤ x := hamin x hxl
        have hxa : x ≠ a := fun e => hnd'.1 (e ▸ hx)
        have hma : m < a := hlb a haml
        omega
      have hrest := ih (m + 1) (s ++ t) hlen' hnd'.2 hlb'
      have hsum : (s ++ a :: t).sum = a + (s ++ t).sum := by
        have h := OrbitTransfer.sum_perm hperm
        simpa [List.sum_cons] using h
      have hma : m < a := hlb a haml
      rw [hsum, Nat.succ_mul]
      rw [Nat.mul_succ] at hrest
      show n * m + m + (tri n + (n + 1)) ≤ a + (s ++ t).sum
      generalize n * m = p at hrest ⊢
      generalize tri n = q at hrest ⊢
      omega

/-- G-PRUNE SOUNDNESS (design §2.2): running-G is SIGNED, so the statement
    is over Int with the (nonnegative) completion increments cast in. If
    the predicate  thresh < runningG + LB(m, o, u)  fires, EVERY completion
    — its o distinct close slots all > m, its u unplaced-couple spreads all
    ≥ 1 — has final G strictly above the threshold: the pruned state
    contains no G ≤ thresh completion. Instantiate thresh := 95 for the
    production C3 ≤ 776 cap. -/
theorem g_prune_sound (thresh runningG : Int) (m : Nat)
    (closes diffs : List Nat)
    (hnd : closes.Nodup)
    (hcl : ∀ s ∈ closes, m < s)
    (hdf : ∀ d ∈ diffs, 1 ≤ d)
    (hfire : thresh < runningG + ((LB m closes.length diffs.length : Nat) : Int)) :
    thresh < runningG + ((closes.sum + diffs.sum : Nat) : Int) := by
  have h1 : closes.length * m + tri closes.length ≤ closes.sum :=
    sum_distinct_min_slots closes.length m closes rfl hnd hcl
  have h2 : diffs.length ≤ diffs.sum := by
    have h := sum_ge_length_mul_lb diffs 1 hdf
    simpa using h
  have hnat : LB m closes.length diffs.length ≤ closes.sum + diffs.sum := by
    show closes.length * m + tri closes.length + diffs.length ≤ closes.sum + diffs.sum
    exact Nat.add_le_add h1 h2
  have hcast : ((LB m closes.length diffs.length : Nat) : Int)
      ≤ ((closes.sum + diffs.sum : Nat) : Int) := Int.ofNat_le.mpr hnat
  exact Int.lt_of_lt_of_le hfire (Int.add_le_add_left hcast runningG)

/-- a completion's final G: running-G plus its close-slot and unplaced-
    spread increments (model of design §2.2's finalG decomposition). -/
def finalG (runningG : Int) (cd : List Nat × List Nat) : Int :=
  runningG + ((cd.1.sum + cd.2.sum : Nat) : Int)

/-- G-PRUNE EXACTNESS (the counting form, design §2.3): at a state where
    the prune fires, the count of completions with final G ≤ thresh is 0 —
    so dropping the state changes no G ≤ thresh count, i.e. capped-DP
    ≡ uncapped-DP-then-filter (runtime gate G5). `C` is the state's
    completion list, each recorded as (close slots, unplaced spreads);
    all completions of one state share o (open couples) and u (unplaced
    couples), which the mask determines. -/
theorem g_prune_exact (thresh runningG : Int) (m o u : Nat)
    (C : List (List Nat × List Nat))
    (hnd : ∀ cd ∈ C, (cd.1 : List Nat).Nodup)
    (hcl : ∀ cd ∈ C, ∀ s ∈ (cd.1 : List Nat), m < s)
    (hdf : ∀ cd ∈ C, ∀ d ∈ (cd.2 : List Nat), 1 ≤ d)
    (ho : ∀ cd ∈ C, (cd.1 : List Nat).length = o)
    (hu : ∀ cd ∈ C, (cd.2 : List Nat).length = u)
    (hfire : thresh < runningG + ((LB m o u : Nat) : Int)) :
    (C.filter (fun cd => decide (finalG runningG cd ≤ thresh))).length = 0 := by
  apply count_none_eq_zero
  intro cd hmem
  simp only [decide_eq_false_iff_not, Int.not_le]
  show thresh < finalG runningG cd
  have hfire' : thresh < runningG + ((LB m cd.1.length cd.2.length : Nat) : Int) := by
    rw [ho cd hmem, hu cd hmem]
    exact hfire
  exact g_prune_sound thresh runningG m cd.1 cd.2
    (hnd cd hmem) (hcl cd hmem) (hdf cd hmem) hfire'

/-! #### Monotonicity (design §2.2): runningG + LB never decreases along a
    transition — self-pair +o, open +2o, close exactly 0 — so pruning at
    entry creation only is complete: a fired state's descendants would all
    fire. Stated as exact deltas (sharper than ≤). -/

/-- self-pair at slot m+1: g unchanged, (o, u) unchanged — delta exactly o. -/
theorem gLB_step_self (g : Int) (m o u : Nat) :
    g + ((LB (m + 1) o u : Nat) : Int) = g + ((LB m o u : Nat) : Int) + (o : Nat) := by
  show g + ((o * (m + 1) + tri o + u : Nat) : Int)
     = g + ((o * m + tri o + u : Nat) : Int) + (o : Nat)
  rw [Nat.mul_succ]
  generalize o * m = p
  generalize tri o = q
  omega

/-- opening a couple at slot m+1: g ← g − (m+1), o ← o+1, u+1 ← u —
    delta exactly 2o. -/
theorem gLB_step_open (g : Int) (m o u : Nat) :
    (g - ((m + 1 : Nat) : Int)) + ((LB (m + 1) (o + 1) u : Nat) : Int)
      = g + ((LB m o (u + 1) : Nat) : Int) + (2 * o : Nat) := by
  show (g - ((m + 1 : Nat) : Int)) + (((o + 1) * (m + 1) + (tri o + (o + 1)) + u : Nat) : Int)
     = g + ((o * m + tri o + (u + 1) : Nat) : Int) + (2 * o : Nat)
  rw [Nat.succ_mul, Nat.mul_succ]
  generalize o * m = p
  generalize tri o = q
  omega

/-- closing a couple at slot m+1: g ← g + (m+1), o+1 ← o — delta exactly 0. -/
theorem gLB_step_close (g : Int) (m o u : Nat) :
    (g + ((m + 1 : Nat) : Int)) + ((LB (m + 1) o u : Nat) : Int)
      = g + ((LB m (o + 1) u : Nat) : Int) := by
  show (g + ((m + 1 : Nat) : Int)) + ((o * (m + 1) + tri o + u : Nat) : Int)
     = g + (((o + 1) * m + (tri o + (o + 1)) + u : Nat) : Int)
  rw [Nat.succ_mul, Nat.mul_succ]
  generalize o * m = p
  generalize tri o = q
  omega

/-! #### Sanity instantiations (tiny concrete cases, `decide`-checked, in
    the style of the sections above). -/

/-- LB sanity (design §2.3's spot value): m = 16, o = 6, u = 3 →
    LB = 6·16 + 21 + 3 = 120. -/
example : LB 16 6 3 = 120 := by decide

/-- tri sanity: 2·tri 12 = 12·13 (the 12-couple full-problem scale). -/
example : 2 * tri 12 = 12 * 13 := tri_spec 12

/-- fired-prune sanity: runningG = −24 at m = 16 with (o, u) = (6, 3):
    −24 + LB = 96 > 95 fires, and the cheapest completion (close slots
    17–22, unit spreads) indeed lands at G = 96 > 95. -/
example : (95 : Int) < (-24) +
    ((([17, 18, 19, 20, 21, 22] : List Nat).sum + ([1, 1, 1] : List Nat).sum : Nat) : Int) :=
  g_prune_sound 95 (-24) 16 [17, 18, 19, 20, 21, 22] [1, 1, 1]
    (by decide) (by decide) (by decide) (by decide)

/-- exactness sanity: at that fired state, a two-completion set has ZERO
    completions with final G ≤ 95 — the dropped state contributes nothing
    to the capped count. -/
example : (([([17, 18, 19, 20, 21, 22], [1, 1, 1]),
             ([20, 19, 25, 22, 17, 18], [2, 1, 3])] :
      List (List Nat × List Nat)).filter
        (fun cd => decide (finalG (-24) cd ≤ 95))).length = 0 :=
  g_prune_exact 95 (-24) 16 6 3 _
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)

end GPrune

end PruneExactness

/-! ### Axiom audit (added 2026-08-01)
Emits the trust base for every theorem in this file that is CITED BY NAME in the
public documentation, so the suite's `#print axioms` claims are OBSERVED rather than
statically inferred. Expected: `[propext, Classical.choice, Quot.sound]`, or
`[propext]` alone for the finite facts. Any `Lean.ofReduceBool` here means a
`native_decide` (compiler trust) is load-bearing and the docs must say so. -/
#print axioms capping_exact
#print axioms no_live_lumping
#print axioms cap_never_merges_live
#print axioms sum_perm
#print axioms orbit_transfer_exact
#print axioms orbit_stabilizer_mult
#print axioms stabilizer_weighted_mass
#print axioms g_prune_sound
#print axioms g_prune_exact
