/-
  KingWen.lean — machine-checked core lemmas of the ROAE constraint system (2026-07-02).
  Core Lean 4 only (no mathlib). All hexagram-level claims are finite and proved by
  native_decide (exhaustive kernel-checked computation); the sequence-level theorems
  (wrap parity, alternation theorem) follow from these lemmas by the short pen-and-paper
  telescoping arguments in SPECIFICATION.md / PARITY_ALTERNATION.md.

  Verifies: Theorem 1 (within-pair distance even, nonzero), Theorem 2 (XOR universality),
  Theorem D lemmas (partner preserves popcount parity; 32/32 parity split; XOR parity
  identity on 6-bit values), and King Wen facts (C1, C4, C5 multiset, C3 = 776 exactly,
  no distance-5 transition, exactly 15 parity-class alternations), plus the finite
  component of Theorem A (exactly 48 of the 720 bit permutations map KW to a valid
  C1–C5 sequence — the centralizer of reversal).
-/

/-- popcount for 6-bit values (total, no recursion needed). -/
def pc6 (n : Nat) : Nat :=
  n % 2 + n / 2 % 2 + n / 4 % 2 + n / 8 % 2 + n / 16 % 2 + n / 32 % 2

/-- 6-bit reversal. -/
def rev6 (n : Nat) : Nat :=
  n % 2 * 32 + n / 2 % 2 * 16 + n / 4 % 2 * 8 + n / 8 % 2 * 4 + n / 16 % 2 * 2 + n / 32 % 2

/-- canonical partner: reversal, or complement for palindromes. -/
def partner (h : Nat) : Nat := if rev6 h = h then h ^^^ 63 else rev6 h

/-- Hamming distance on 6-bit values. -/
def ham (a b : Nat) : Nat := pc6 (a ^^^ b)

def KW : List Nat :=
  [63,  0, 17, 34, 23, 58,  2, 16, 55, 59,  7, 56, 61, 47,  4,  8,
   25, 38,  3, 48, 41, 37, 32,  1, 57, 39, 33, 30, 18, 45, 28, 14,
   60, 15, 40,  5, 53, 43, 20, 10, 35, 49, 31, 62, 24,  6, 26, 22,
   29, 46,  9, 36, 52, 11, 13, 44, 54, 27, 50, 19, 51, 12, 21, 42]

/-- adjacent-transition distances of a sequence. -/
def transitions (l : List Nat) : List Nat :=
  (l.zip l.tail).map (fun p => ham p.1 p.2)

/-- C1: consecutive pairing by partner. -/
def c1ok (l : List Nat) : Bool :=
  ((List.range 32).all fun i => l.getD (2*i+1) 99 == partner (l.getD (2*i) 99))

/-- C4. -/
def c4ok (l : List Nat) : Bool := l.getD 0 99 == 63 && l.getD 1 99 == 0

/-- C5: the difference-wave multiset {1:2, 2:20, 3:13, 4:19, 6:9} (implies C2). -/
def c5ok (l : List Nat) : Bool :=
  let t := transitions l
  ((t.filter (· == 1)).length == 2) && ((t.filter (· == 2)).length == 20) &&
  ((t.filter (· == 3)).length == 13) && ((t.filter (· == 4)).length == 19) &&
  ((t.filter (· == 5)).length == 0)  && ((t.filter (· == 6)).length == 9) &&
  ((t.filter (· == 0)).length == 0)

/-- x64 complement-distance sum: Σ_h |pos(h) − pos(comp h)|. -/
def c3x64 (l : List Nat) : Nat :=
  ((List.range 64).map fun h =>
    let a := l.findIdx (· == h); let b := l.findIdx (· == (h ^^^ 63))
    max a b - min a b).foldl (·+·) 0

def c3ok (l : List Nat) : Bool := c3x64 l ≤ 776

def validC15 (l : List Nat) : Bool := c1ok l && c4ok l && c5ok l && c3ok l

/- ------------------ hexagram-level theorems ------------------ -/

/-- Theorem 1: within-pair Hamming distance is even and nonzero for all 64 hexagrams. -/
theorem within_pair_even_nonzero :
    ((List.range 64).all fun h => ham h (partner h) % 2 == 0 && ham h (partner h) != 0) = true := by
  native_decide

/-- Theorem 2 (XOR universality): every XOR product h ⊕ partner(h) lies in the 7-element
    set {12, 18, 30, 33, 45, 51, 63}, and each value is attained. -/
theorem xor_universality :
    ((List.range 64).all fun h => [12,18,30,33,45,51,63].contains (h ^^^ partner h)) = true := by
  native_decide

theorem xor_all_seven_attained :
    ([12,18,30,33,45,51,63].all fun v => (List.range 64).any fun h => h ^^^ partner h == v) = true := by
  native_decide

/-- Theorem D, Lemma 1: the partner map preserves popcount parity. -/
theorem partner_preserves_parity :
    ((List.range 64).all fun h => pc6 (partner h) % 2 == pc6 h % 2) = true := by
  native_decide

/-- Theorem D, Lemma 2 (class split): exactly 32 hexagrams of each popcount parity,
    hence (with Lemma 1) 16 even-class and 16 odd-class pairs. -/
theorem parity_split_32_32 :
    ((List.range 64).filter fun h => pc6 h % 2 == 0).length = 32 := by
  native_decide

/-- XOR parity identity on 6-bit values (the engine of the wrap-parity theorem and of
    Theorem D, Lemma 3): popcount(a ⊕ b) ≡ popcount(a) + popcount(b) (mod 2). -/
theorem xor_parity_identity :
    ((List.range 64).all fun a => (List.range 64).all fun b =>
      pc6 (a ^^^ b) % 2 == (pc6 a + pc6 b) % 2) = true := by
  native_decide

/- ------------------ King Wen facts ------------------ -/

theorem kw_valid : validC15 KW = true := by native_decide

theorem kw_c3_exactly_776 : c3x64 KW = 776 := by native_decide

/-- KW has no distance-5 transition (C2), restated separately for emphasis. -/
theorem kw_no_five : ((transitions KW).filter (· == 5)).length = 0 := by native_decide

/-- Theorem D at KW: exactly 15 parity-class alternations across the 32-pair sequence. -/
def pairClasses (l : List Nat) : List Nat :=
  (List.range 32).map fun i => pc6 (l.getD (2*i) 0) % 2

theorem kw_alternations_15 :
    (((pairClasses KW).zip (pairClasses KW).tail).filter fun p => p.1 != p.2).length = 15 := by
  native_decide

/- ------------------ Theorem A, finite component ------------------ -/

/-- all permutations of a list (insertion-based; 720 elements for 6 positions). -/
def inserts (x : Nat) : List Nat → List (List Nat)
  | [] => [[x]]
  | y :: ys => (x :: y :: ys) :: (inserts x ys).map (y :: ·)

def perms : List Nat → List (List Nat)
  | [] => [[]]
  | x :: xs => (perms xs).flatMap (inserts x)

/-- apply a bit-position permutation p (bit i of n goes to position p[i]). -/
def applyPerm (p : List Nat) (n : Nat) : Nat :=
  ((List.range 6).map fun i => n / (2^i) % 2 * 2^(p.getD i 0)).foldl (·+·) 0

/-- Theorem A (finite component): exactly 48 of the 720 bit permutations map King Wen
    to a valid C1–C5 sequence — and they are exactly the permutations commuting with
    reversal (the centralizer of rev, ≅ B₃). -/
theorem sigma_kw_valid_48 :
    ((perms [0,1,2,3,4,5]).filter fun p => validC15 (KW.map (applyPerm p))).length = 48 := by
  native_decide

theorem valid_iff_centralizes_rev :
    ((perms [0,1,2,3,4,5]).all fun p =>
      (validC15 (KW.map (applyPerm p)) ==
       ((List.range 64).all fun h => applyPerm p (rev6 h) == rev6 (applyPerm p h)))) = true := by
  native_decide

/-- The 48 valid images collapse to exactly 24 distinct pair-sequences (record-level
    group S₄): counted via canonical pair keys (unordered consecutive pairs). -/
def pairKey (l : List Nat) : List Nat :=
  (List.range 32).map fun i =>
    min (l.getD (2*i) 0) (l.getD (2*i+1) 0) * 64 + max (l.getD (2*i) 0) (l.getD (2*i+1) 0)

theorem twins_24_records :
    (((perms [0,1,2,3,4,5]).filter fun p => validC15 (KW.map (applyPerm p))).map
      (fun p => pairKey (KW.map (applyPerm p)))).eraseDups.length = 24 := by
  native_decide


/- ------------------ TIER 2 (2026-07-03): structured sequence-level theorems ------------------
   Unlike the native_decide facts above (finite computations), these are structural proofs by
   induction over arbitrary bounded lists — the wrap-parity theorem is verified for EVERY C4+C5
   sequence, not just King Wen. -/

theorem ham_parity_lt64 : ∀ a < 64, ∀ b < 64, ham a b % 2 = (pc6 a + pc6 b) % 2 := by decide

/-- sum parity flips exactly on odd elements. -/
theorem sum_parity_odd_count (l : List Nat) :
    l.sum % 2 = (l.filter (· % 2 == 1)).length % 2 := by
  induction l with
  | nil => rfl
  | cons h t ih =>
    simp only [List.sum_cons, List.filter_cons]
    by_cases hh : h % 2 = 1
    · simp [hh, List.length_cons, Nat.add_mod, ih.symm]
      omega
    · have h0 : h % 2 = 0 := by omega
      simp [hh, Nat.add_mod, ih.symm]
      omega

/-- telescoping: transition-sum parity = end-point popcount parity (bounded lists). -/
theorem transitions_sum_parity :
    ∀ (l : List Nat), (∀ x ∈ l, x < 64) → l ≠ [] →
      (transitions l).sum % 2 = (pc6 (l.headD 0) + pc6 (l.getLastD 0)) % 2 := by
  intro l
  induction l with
  | nil => intro _ h; exact absurd rfl h
  | cons a t ih =>
    intro hb _
    cases t with
    | nil => simp [transitions]; omega
    | cons b t2 =>
      have hab : ham a b % 2 = (pc6 a + pc6 b) % 2 :=
        ham_parity_lt64 a (hb a (by simp)) b (hb b (by simp))
      have ih2 := ih (fun x hx => hb x (List.mem_cons_of_mem a hx)) (by simp)
      have hexp : transitions (a :: b :: t2) = ham a b :: transitions (b :: t2) := by
        simp [transitions]
      rw [hexp, List.sum_cons]
      have hlast : (a :: b :: t2).getLastD 0 = (b :: t2).getLastD 0 := by
        simp [List.getLastD_cons]
      rw [hlast]
      simp only [List.headD] at ih2 ⊢
      omega

/-- transition values of bounded lists are ≤ 6. -/
theorem ham_le6 : ∀ a < 64, ∀ b < 64, ham a b ≤ 6 := by decide

/-- for x ≤ 6: x is odd iff x ∈ {1, 3, 5}. -/
theorem odd_le6 : ∀ x ≤ 6, (x % 2 == 1) = (x == 1 || x == 3 || x == 5) := by decide

/-- odd-count partition for ≤6-bounded lists. -/
theorem odd_count_partition (l : List Nat) (hb : ∀ x ∈ l, x ≤ 6) :
    (l.filter (· % 2 == 1)).length =
    (l.filter (· == 1)).length + (l.filter (· == 3)).length + (l.filter (· == 5)).length := by
  induction l with
  | nil => rfl
  | cons h t ih =>
    have hh6 : h ≤ 6 := hb h (by simp)
    have ih2 := ih (fun x hx => hb x (List.mem_cons_of_mem h hx))
    simp only [List.filter_cons]
    have hodd := odd_le6 h hh6
    by_cases h1 : h = 1
    · subst h1; simp [ih2]; omega
    · by_cases h3 : h = 3
      · subst h3; simp [ih2]; omega
      · by_cases h5 : h = 5
        · subst h5; simp [ih2]; omega
        · have : (h % 2 == 1) = false := by
            rw [hodd]; simp [h1, h3, h5]
          simp [this, h1, h3, h5, ih2]

/-- WRAP-PARITY THEOREM (general, structured proof): every C4+C5 sequence of 6-bit values
    ends in a hexagram of ODD popcount — hence the wrap distance d(s63, s0) is odd. -/
theorem wrap_parity_general (l : List Nat) (hb : ∀ x ∈ l, x < 64)
    (h4 : c4ok l = true) (h5 : c5ok l = true) (hne : l ≠ []) :
    pc6 (l.getLastD 0) % 2 = 1 := by
  have htele := transitions_sum_parity l hb hne
  have hbound : ∀ x ∈ transitions l, x ≤ 6 := by
    intro x hx
    simp only [transitions, List.mem_map] at hx
    obtain ⟨⟨a, b⟩, hmem, hxab⟩ := hx
    have hab := List.of_mem_zip hmem
    exact hxab ▸ ham_le6 a (hb a hab.1) b (hb b (List.mem_of_mem_tail hab.2))
  have hsump := sum_parity_odd_count (transitions l)
  have hpart := odd_count_partition (transitions l) hbound
  simp only [c5ok, Bool.and_eq_true, beq_iff_eq] at h5
  have hodd15 : (transitions l).sum % 2 = 1 := by
    rw [hsump, hpart, h5.1.1.1.1.1.1, h5.1.1.1.1.2, h5.1.1.2]
  have hhead : l.headD 0 = 63 := by
    simp only [c4ok, Bool.and_eq_true, beq_iff_eq] at h4
    cases l with
    | nil => exact absurd rfl hne
    | cons a t => simpa using h4.1
  rw [htele, hhead] at hodd15
  have : pc6 63 = 6 := by decide
  omega


/- ------------------ TIER 2b (2026-07-03): THE GENERAL 15-ALTERNATION THEOREM ------------------
   alternations_15_general: EVERY C1+C5 sequence of 64 six-bit values has exactly 15 parity-class
   alternations — structural proof (range-map bridge + decidable-permutation index-parity split +
   the finite parity lemmas). The KW instance kw_alternations_15 above is now a corollary. -/

theorem transitions_eq_rangeMap (l : List Nat) :
    transitions l = (List.range (l.length - 1)).map
      (fun j => ham (l.getD j 0) (l.getD (j+1) 0)) := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    cases t with
    | nil => rfl
    | cons b t2 =>
      show ham a b :: transitions (b :: t2) = _
      rw [ih]
      have h1 : (a :: b :: t2).length - 1 = ((b :: t2).length - 1) + 1 := by simp
      rw [h1, List.range_succ_eq_map, List.map_cons, List.map_map]
      simp [Function.comp]

theorem range63_perm :
    (List.range 63).Perm
      (((List.range 32).map (fun i => 2*i)) ++ ((List.range 31).map (fun i => 2*i+1))) := by
  decide

theorem within_even : ∀ h < 64, ham h (partner h) % 2 = 0 := by decide

theorem partner_parity : ∀ h < 64, pc6 (partner h) % 2 = pc6 h % 2 := by decide

/-- boundary-transition value at flat index j. -/
def ftr (l : List Nat) (j : Nat) : Nat := ham (l.getD j 0) (l.getD (j+1) 0)

/-- THE 15-ALTERNATION THEOREM (general): every C1+C5 sequence of 64 six-bit values has exactly
    15 parity-class alternations across its 32 pairs. -/
theorem alternations_15_general (l : List Nat) (hb : ∀ x ∈ l, x < 64) (hlen : l.length = 64)
    (h1 : c1ok l = true) (h5 : c5ok l = true) :
    ((List.range 31).countP fun i =>
      decide (pc6 (l.getD (2*i) 0) % 2 ≠ pc6 (l.getD (2*i+2) 0) % 2)) = 15 := by
  have hget : ∀ j, j < 64 → l.getD j 0 < 64 := by
    intro j hj
    have hjl : j < l.length := by omega
    have : l.getD j 0 = l[j] := by simp [List.getD, List.getElem?_eq_getElem hjl]
    rw [this]; exact hb _ (List.getElem_mem hjl)
  simp only [c1ok, List.all_eq_true, beq_iff_eq] at h1
  have hc1 : ∀ i, i < 32 → l.getD (2*i+1) 0 = partner (l.getD (2*i) 0) := by
    intro i hi
    have h2i : 2*i < l.length := by omega
    have h2i1 : 2*i+1 < l.length := by omega
    have e1 : l.getD (2*i+1) 99 = l.getD (2*i+1) 0 := by
      simp [List.getD, List.getElem?_eq_getElem h2i1]
    have e2 : l.getD (2*i) 99 = l.getD (2*i) 0 := by
      simp [List.getD, List.getElem?_eq_getElem h2i]
    have := h1 i (List.mem_range.mpr hi)
    rw [e1, e2] at this; exact this
  -- transitions as range-63 map
  have htrans : transitions l = (List.range 63).map (ftr l) := by
    rw [transitions_eq_rangeMap, hlen]; rfl
  -- all transitions ≤ 6
  have hbnd : ∀ x ∈ transitions l, x ≤ 6 := by
    intro x hx
    rw [htrans] at hx
    obtain ⟨j, hj, rfl⟩ := List.mem_map.mp hx
    have hj63 := List.mem_range.mp hj
    exact ham_le6 _ (hget j (by omega)) _ (hget (j+1) (by omega))
  -- odd-transition count = 15 from C5
  simp only [c5ok, Bool.and_eq_true, beq_iff_eq] at h5
  have hodd15 : ((transitions l).filter (· % 2 == 1)).length = 15 := by
    rw [odd_count_partition _ hbnd, h5.1.1.1.1.1.1, h5.1.1.1.1.2, h5.1.1.2]
  -- split by index parity
  have hsplit : ((transitions l).filter (· % 2 == 1)).length =
      ((List.range 32).countP fun i => ftr l (2*i) % 2 == 1) +
      ((List.range 31).countP fun i => ftr l (2*i+1) % 2 == 1) := by
    rw [htrans, ← List.countP_eq_length_filter, List.countP_map,
        range63_perm.countP_eq, List.countP_append, List.countP_map, List.countP_map]
    rfl
  -- within term = 0
  have hwithin : ((List.range 32).countP fun i => ftr l (2*i) % 2 == 1) = 0 := by
    rw [List.countP_eq_zero]
    intro i hi
    have hi32 := List.mem_range.mp hi
    simp only [ftr]
    rw [hc1 i hi32]
    have := within_even _ (hget (2*i) (by omega))
    simpa [List.getD] using this
  -- between predicate ⟺ alternation predicate
  have hcong : ((List.range 31).countP fun i => ftr l (2*i+1) % 2 == 1) =
      ((List.range 31).countP fun i =>
        decide (pc6 (l.getD (2*i) 0) % 2 ≠ pc6 (l.getD (2*i+2) 0) % 2)) := by
    apply List.countP_congr
    intro i hi
    have hi31 := List.mem_range.mp hi
    simp only [ftr]
    have hp1 : pc6 (l.getD (2*i+1) 0) % 2 = pc6 (l.getD (2*i) 0) % 2 := by
      rw [hc1 i (by omega)]
      exact partner_parity _ (hget (2*i) (by omega))
    have hpar := ham_parity_lt64 _ (hget (2*i+1) (by omega)) _ (hget (2*i+1+1) (by omega))
    have e22 : 2*i+1+1 = 2*i+2 := by omega
    rw [e22] at hpar
    constructor
    · intro h
      simp only [beq_iff_eq] at h
      simp only [decide_eq_true_iff]
      intro hcontra
      rw [hpar] at h
      omega
    · intro h
      simp only [decide_eq_true_iff] at h
      simp only [beq_iff_eq]
      rw [hpar]
      omega
  rw [hsplit, hwithin, hcong] at hodd15
  omega
