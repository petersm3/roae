-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  KingWen.lean — machine-checked core lemmas of the ROAE constraint system (2026-07-02).
  Core Lean 4 only (no mathlib). KERNEL-ONLY since 2026-07-27: every finite claim in
  this file — including the heavy Theorem A trio sigma_kw_valid_48 /
  valid_iff_centralizes_rev / twins_24_records over all 720 bit permutations — is
  proved by kernel `decide`/`decide +kernel` (zero native_decide; `#print axioms`
  reports only standard axioms — ⊆ [propext, Classical.choice, Quot.sound] — on
  every theorem, with the finite facts at [propext] alone: nothing in this file
  trusts Lean's compiler or native code generator); the sequence-level theorems
  (wrap parity, alternation theorem) follow from these lemmas by the short pen-and-paper
  telescoping arguments in SPECIFICATION.md / PARITY_ALTERNATION.md — and the general
  forms are proved structurally below (Tier 2).

  Verifies: Theorem 1 (within-pair distance even, nonzero), Theorem 2 (XOR universality),
  Theorem D lemmas (partner preserves popcount parity; 32/32 parity split; XOR parity
  identity on 6-bit values), and King Wen facts (C1, C4, C5 multiset, C3 = 776 exactly,
  no distance-5 transition, exactly 15 parity-class alternations), plus the finite
  component of Theorem A (exactly 48 of the 720 bit permutations map KW to a valid
  C1–C5 sequence — the centralizer of reversal), the EQUIVARIANCE CEILING
  (2026-07-26): any generator scored purely in G-invariant primitives
  gives KW's record exactly 1/24 of its orbit's mass — it can never single out KW,
  and the COMPLEMENT Z₂ SYMMETRY (2026-07-26, final section): global
  complementation x ↦ x ⊕ 63 is an exact symmetry of C1∩C2∩C3∩C5, broken only
  by the oriented form of C4 — so the opening orientation is a free Z₂, NOT
  forced (this replaces the retracted "Theorem 6"; kernel-only trust base).
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
  decide

/-- Theorem 2 (XOR universality): every XOR product h ⊕ partner(h) lies in the 7-element
    set {12, 18, 30, 33, 45, 51, 63}, and each value is attained. -/
theorem xor_universality :
    ((List.range 64).all fun h => [12,18,30,33,45,51,63].contains (h ^^^ partner h)) = true := by
  decide

theorem xor_all_seven_attained :
    ([12,18,30,33,45,51,63].all fun v => (List.range 64).any fun h => h ^^^ partner h == v) = true := by
  decide

/-- Theorem D, Lemma 1: the partner map preserves popcount parity. -/
theorem partner_preserves_parity :
    ((List.range 64).all fun h => pc6 (partner h) % 2 == pc6 h % 2) = true := by
  decide

/-- Theorem D, Lemma 2 (class split): exactly 32 hexagrams of each popcount parity,
    hence (with Lemma 1) 16 even-class and 16 odd-class pairs. -/
theorem parity_split_32_32 :
    ((List.range 64).filter fun h => pc6 h % 2 == 0).length = 32 := by
  decide

/-- XOR parity identity on 6-bit values (the engine of the wrap-parity theorem and of
    Theorem D, Lemma 3): popcount(a ⊕ b) ≡ popcount(a) + popcount(b) (mod 2). -/
theorem xor_parity_identity :
    ((List.range 64).all fun a => (List.range 64).all fun b =>
      pc6 (a ^^^ b) % 2 == (pc6 a + pc6 b) % 2) = true := by
  decide

/- ------------------ King Wen facts ------------------ -/

theorem kw_valid : validC15 KW = true := by decide +kernel

theorem kw_c3_exactly_776 : c3x64 KW = 776 := by decide +kernel

/-- KW has no distance-5 transition (C2), restated separately for emphasis. -/
theorem kw_no_five : ((transitions KW).filter (· == 5)).length = 0 := by decide

/-- Theorem D at KW: exactly 15 parity-class alternations across the 32-pair sequence. -/
def pairClasses (l : List Nat) : List Nat :=
  (List.range 32).map fun i => pc6 (l.getD (2*i) 0) % 2

theorem kw_alternations_15 :
    (((pairClasses KW).zip (pairClasses KW).tail).filter fun p => p.1 != p.2).length = 15 := by
  decide

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
  decide +kernel

theorem valid_iff_centralizes_rev :
    ((perms [0,1,2,3,4,5]).all fun p =>
      (validC15 (KW.map (applyPerm p)) ==
       ((List.range 64).all fun h => applyPerm p (rev6 h) == rev6 (applyPerm p h)))) = true := by
  decide +kernel

/-- The 48 valid images collapse to exactly 24 distinct pair-sequences (record-level
    group S₄): counted via canonical pair keys (unordered consecutive pairs). -/
def pairKey (l : List Nat) : List Nat :=
  (List.range 32).map fun i =>
    min (l.getD (2*i) 0) (l.getD (2*i+1) 0) * 64 + max (l.getD (2*i) 0) (l.getD (2*i+1) 0)

theorem twins_24_records :
    (((perms [0,1,2,3,4,5]).filter fun p => validC15 (KW.map (applyPerm p))).map
      (fun p => pairKey (KW.map (applyPerm p)))).eraseDups.length = 24 := by
  decide +kernel


/- ------------------ TIER 2 (2026-07-03): structured sequence-level theorems ------------------
   Unlike the finite decide facts above (exhaustive computations), these are structural proofs by
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
        simp
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


/- ------------------ TIER 2c (2026-07-04): THE 30-PARITY-SWITCH COROLLARY ------------------
   switches_30_general: in EVERY C1+C5 sequence of 64 six-bit values, the transition-parity
   sequence (ftr l 0 % 2, …, ftr l 62 % 2) switches parity between consecutive positions
   exactly 30 times. Within-pair transitions (even flat index) are always even (rev-partners
   preserve popcount parity; comp-partners have ham = 6), so a switch at flat index j happens
   iff the adjacent between-pair transition is odd — and each odd between-pair transition is
   flanked by two even within-pair transitions, contributing exactly 2 switches. With 15 odd
   between-pair transitions (alternations_15_general), the count is 2 × 15 = 30. -/

theorem range62_perm :
    (List.range 62).Perm
      (((List.range 31).map (fun i => 2*i)) ++ ((List.range 31).map (fun i => 2*i+1))) := by
  decide

theorem switches_30_general (l : List Nat) (hb : ∀ x ∈ l, x < 64) (hlen : l.length = 64)
    (h1 : c1ok l = true) (h5 : c5ok l = true) :
    ((List.range 62).countP fun j => decide (ftr l j % 2 ≠ ftr l (j+1) % 2)) = 30 := by
  have h15 := alternations_15_general l hb hlen h1 h5
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
  -- step 1: within-pair transitions (even flat index) have even parity
  have hwithin : ∀ k, k < 32 → ftr l (2*k) % 2 = 0 := by
    intro k hk
    simp only [ftr]
    rw [hc1 k hk]
    exact within_even _ (hget (2*k) (by omega))
  -- step 2: between-pair transition parity = parity of the two pair-heads' popcount sum
  have hbetween : ∀ k, k < 31 →
      ftr l (2*k+1) % 2 = (pc6 (l.getD (2*k) 0) + pc6 (l.getD (2*k+2) 0)) % 2 := by
    intro k hk
    simp only [ftr]
    have hpar := ham_parity_lt64 _ (hget (2*k+1) (by omega)) _ (hget (2*k+1+1) (by omega))
    have e22 : 2*k+1+1 = 2*k+2 := by omega
    rw [e22] at hpar
    rw [e22, hpar]
    have hp1 : pc6 (l.getD (2*k+1) 0) % 2 = pc6 (l.getD (2*k) 0) % 2 := by
      rw [hc1 k (by omega)]
      exact partner_parity _ (hget (2*k) (by omega))
    omega
  -- step 3: split the 62 switch positions by flat-index parity
  have hsplit : ((List.range 62).countP fun j => decide (ftr l j % 2 ≠ ftr l (j+1) % 2)) =
      ((List.range 31).countP fun k => decide (ftr l (2*k) % 2 ≠ ftr l (2*k+1) % 2)) +
      ((List.range 31).countP fun k => decide (ftr l (2*k+1) % 2 ≠ ftr l (2*k+1+1) % 2)) := by
    rw [range62_perm.countP_eq, List.countP_append, List.countP_map, List.countP_map]
    rfl
  -- even flat index: within(2k) = 0, so switch ⟺ between-transition k is odd ⟺ alternation at k
  have heven : ((List.range 31).countP fun k => decide (ftr l (2*k) % 2 ≠ ftr l (2*k+1) % 2)) =
      ((List.range 31).countP fun i =>
        decide (pc6 (l.getD (2*i) 0) % 2 ≠ pc6 (l.getD (2*i+2) 0) % 2)) := by
    apply List.countP_congr
    intro k hk
    have hk31 := List.mem_range.mp hk
    have hw := hwithin k (by omega)
    have hbet := hbetween k hk31
    simp only [decide_eq_true_iff]
    rw [hw, hbet]
    omega
  -- odd flat index: within(2k+2) = 0, so switch ⟺ between-transition k is odd ⟺ alternation at k
  have hodd : ((List.range 31).countP fun k => decide (ftr l (2*k+1) % 2 ≠ ftr l (2*k+1+1) % 2)) =
      ((List.range 31).countP fun i =>
        decide (pc6 (l.getD (2*i) 0) % 2 ≠ pc6 (l.getD (2*i+2) 0) % 2)) := by
    apply List.countP_congr
    intro k hk
    have hk31 := List.mem_range.mp hk
    have hbet := hbetween k hk31
    have e2 : 2*k+1+1 = 2*(k+1) := by omega
    have hw : ftr l (2*k+1+1) % 2 = 0 := by
      rw [e2]; exact hwithin (k+1) (by omega)
    simp only [decide_eq_true_iff]
    rw [hw, hbet]
    omega
  rw [hsplit, heven, hodd, h15]


/- ------------------ MICRO-LEMMA BASKET (2026-07-27) ------------------
   Four short corollaries previously carried as prose in the documentation
   (CLAIMS_DECIDED / TR-8 prong 2, CIRCULAR_KING_WEN.md, the minimum-rule-set
   note), now machine-checked on top of the Tier-2 machinery above. All
   structural + kernel `decide`; no native_decide. -/

/-- C2 as a standalone predicate: no distance-5 transition (matches
    Automorphism.lean's c2ok; KingWen.lean did not previously define it
    separately because C5 implies it — which is exactly the lemma below). -/
def c2ok (l : List Nat) : Bool := ((transitions l).filter (· == 5)).length == 0

/-- C5 ⇒ C2 (the definitional glue step of the minimum rule set
    {C1, C3, C4, C5}): C5's difference-wave multiset {1:2, 2:20, 3:13, 4:19,
    6:9} has no 5-class, so every C5 sequence satisfies C2. -/
theorem c5_implies_c2 (l : List Nat) (h5 : c5ok l = true) : c2ok l = true := by
  simp only [c5ok, Bool.and_eq_true, beq_iff_eq] at h5
  simp [c2ok, h5.1.1.2]

/-- GRAY-CODE IMPOSSIBILITY (TR-8 prong 2 / CLAIMS_DECIDED "REFUTED" row,
    previously a 2-line prose parity argument): NO C1-paired ordering of the
    64 hexagrams is a Gray code — some transition changes more than one line,
    because every within-pair distance is even and nonzero (hence ≥ 2). A
    circular Gray reading fails a fortiori: its linear part is already not
    all-distance-1. (The refutation of the McKenna–Mair Gray-code replacement
    program rests here; the very first pair already breaks it.) -/
theorem gray_code_impossible (l : List Nat) (hb : ∀ x ∈ l, x < 64)
    (hlen : l.length = 64) (h1 : c1ok l = true) :
    ¬ ((transitions l).all (· == 1) = true) := by
  intro hall
  have hget : l.getD 0 0 < 64 := by
    have h0 : (0 : Nat) < l.length := by omega
    have : l.getD 0 0 = l[0] := by simp [List.getD, List.getElem?_eq_getElem h0]
    rw [this]; exact hb _ (List.getElem_mem h0)
  -- C1 at slot 0: position 1 holds the partner of position 0
  simp only [c1ok, List.all_eq_true, beq_iff_eq] at h1
  have hc1 : l.getD 1 0 = partner (l.getD 0 0) := by
    have h0 : (0 : Nat) < l.length := by omega
    have h1l : (1 : Nat) < l.length := by omega
    have e1 : l.getD 1 99 = l.getD 1 0 := by
      simp [List.getD, List.getElem?_eq_getElem h1l]
    have e2 : l.getD 0 99 = l.getD 0 0 := by
      simp [List.getD, List.getElem?_eq_getElem h0]
    have h10 := h1 0 (List.mem_range.mpr (by omega))
    have h10' : l.getD 1 99 = partner (l.getD 0 99) := h10
    rw [e1, e2] at h10'; exact h10'
  -- the flat-0 transition is a member of the transition list
  have hmem : ftr l 0 ∈ transitions l := by
    rw [transitions_eq_rangeMap, hlen]
    exact List.mem_map.mpr ⟨0, List.mem_range.mpr (by omega), rfl⟩
  have hone := List.all_eq_true.mp hall _ hmem
  simp only [beq_iff_eq] at hone
  -- but the flat-0 transition is within pair 0, hence even
  have heven := within_even _ hget
  simp only [ftr] at hone
  rw [show (0 : Nat) + 1 = 1 from rfl, hc1] at hone
  omega

/- --- the circular-reading corollaries (CIRCULAR_KING_WEN.md, previously
   prose corollary chains from the wrap-parity + 15-alternation theorems) --- -/

/-- the wrap transition of the circular reading: d(s63, s0). -/
def wrapDist (l : List Nat) : Nat := ham (l.getLastD 0) (l.headD 0)

/-- the last element of a nonempty list is a member (getLastD form). -/
theorem getLastD_mem (l : List Nat) (h : l ≠ []) : l.getLastD 0 ∈ l := by
  induction l with
  | nil => exact absurd rfl h
  | cons a t ih =>
    cases t with
    | nil => simp
    | cons b t2 =>
      have hm := ih (by simp)
      have he : (a :: b :: t2).getLastD 0 = (b :: t2).getLastD 0 := by simp
      rw [he]
      exact List.mem_cons_of_mem a hm

/-- THE WRAP-CLASS COROLLARY: in every C4+C5 sequence the wrap distance is
    odd — d(s63, s0) ∈ {1, 3, 5}. (Circular C2 — excluding the 5-wrap — is
    therefore a genuine extra constraint; SAT witness wrap-d5 shows valid
    orderings with a 5-line wrap exist.) -/
theorem wrap_odd_135 (l : List Nat) (hb : ∀ x ∈ l, x < 64)
    (h4 : c4ok l = true) (h5 : c5ok l = true) (hne : l ≠ []) :
    wrapDist l = 1 ∨ wrapDist l = 3 ∨ wrapDist l = 5 := by
  have hlastp := wrap_parity_general l hb h4 h5 hne
  have hhead : l.headD 0 = 63 := by
    simp only [c4ok, Bool.and_eq_true, beq_iff_eq] at h4
    cases l with
    | nil => exact absurd rfl hne
    | cons a t => simpa using h4.1
  have hlast64 : l.getLastD 0 < 64 := hb _ (getLastD_mem l hne)
  have hpar := ham_parity_lt64 _ hlast64 63 (by omega)
  have hle := ham_le6 _ hlast64 63 (by omega)
  have h63 : pc6 63 = 6 := by decide
  simp only [wrapDist, hhead]
  omega

/-- getLastD is the position-63 entry of a 64-element list. -/
theorem getLastD_eq_getD63 (l : List Nat) (hlen : l.length = 64) :
    l.getLastD 0 = l.getD 63 0 := by
  have h63 : (63 : Nat) < l.length := by omega
  rw [List.getLastD_eq_getLast?, List.getLast?_eq_getElem?, hlen]
  simp [List.getD, List.getElem?_eq_getElem h63]

/-- THE CIRCULAR 16-ALTERNATION COROLLARY: reading the 32 pair classes as a
    CYCLE, every C1+C4+C5 sequence has exactly 16 parity-class alternations —
    the 15 linear alternations (alternations_15_general) plus a FORCED wrap
    alternation: slot 31's class is odd (wrap-parity theorem + partner
    parity-preservation) while slot 0's class is even (pc6 63 = 6). -/
theorem circular_alternations_16 (l : List Nat) (hb : ∀ x ∈ l, x < 64)
    (hlen : l.length = 64) (h1 : c1ok l = true) (h4 : c4ok l = true)
    (h5 : c5ok l = true) :
    ((List.range 32).countP fun i =>
      decide (pc6 (l.getD (2*i) 0) % 2 ≠ pc6 (l.getD ((2*i+2) % 64) 0) % 2)) = 16 := by
  have hne : l ≠ [] := by
    intro h; rw [h] at hlen; simp at hlen
  have hget : ∀ j, j < 64 → l.getD j 0 < 64 := by
    intro j hj
    have hjl : j < l.length := by omega
    have : l.getD j 0 = l[j] := by simp [List.getD, List.getElem?_eq_getElem hjl]
    rw [this]; exact hb _ (List.getElem_mem hjl)
  -- C1 at slot 31: position 63 holds the partner of position 62
  simp only [c1ok, List.all_eq_true, beq_iff_eq] at h1
  have hc1' : l.getD 63 0 = partner (l.getD 62 0) := by
    have h62 : (62 : Nat) < l.length := by omega
    have h63 : (63 : Nat) < l.length := by omega
    have e1 : l.getD 63 99 = l.getD 63 0 := by
      simp [List.getD, List.getElem?_eq_getElem h63]
    have e2 : l.getD 62 99 = l.getD 62 0 := by
      simp [List.getD, List.getElem?_eq_getElem h62]
    have h31 := h1 31 (List.mem_range.mpr (by omega))
    have h31' : l.getD 63 99 = partner (l.getD 62 99) := h31
    rw [e1, e2] at h31'; exact h31'
  -- re-pack c1ok for the linear theorem
  have h1' : c1ok l = true := by
    simp only [c1ok, List.all_eq_true, beq_iff_eq]
    exact h1
  -- slot 31's class is odd (wrap parity + partner parity)
  have hlastp := wrap_parity_general l hb h4 h5 hne
  rw [getLastD_eq_getD63 l hlen, hc1'] at hlastp
  have hp62 : pc6 (l.getD 62 0) % 2 = 1 := by
    have := partner_parity _ (hget 62 (by omega))
    omega
  -- slot 0's class is even (C4: the head is 63)
  have hhead : l.getD 0 0 = 63 := by
    simp only [c4ok, Bool.and_eq_true, beq_iff_eq] at h4
    have h0 : (0 : Nat) < l.length := by omega
    have e2 : l.getD 0 99 = l.getD 0 0 := by
      simp [List.getD, List.getElem?_eq_getElem h0]
    rw [← e2]; exact h4.1
  -- split the cyclic count: 31 linear terms + the wrap term
  have hsplit : List.range 32 = List.range 31 ++ [31] := by decide
  rw [hsplit, List.countP_append]
  -- linear part: the mod-64 is inert for i < 31, then apply the linear theorem
  have hlin : ((List.range 31).countP fun i =>
      decide (pc6 (l.getD (2*i) 0) % 2 ≠ pc6 (l.getD ((2*i+2) % 64) 0) % 2)) =
      ((List.range 31).countP fun i =>
        decide (pc6 (l.getD (2*i) 0) % 2 ≠ pc6 (l.getD (2*i+2) 0) % 2)) := by
    apply List.countP_congr
    intro i hi
    have hi31 := List.mem_range.mp hi
    have hmod : (2*i+2) % 64 = 2*i+2 := Nat.mod_eq_of_lt (by omega)
    rw [hmod]
  rw [hlin, alternations_15_general l hb hlen h1' h5]
  -- wrap term: (2·31+2) % 64 = 0, and classes 1 ≠ 0 force the alternation
  have hwrap : ([31].countP fun i =>
      decide (pc6 (l.getD (2*i) 0) % 2 ≠ pc6 (l.getD ((2*i+2) % 64) 0) % 2)) = 1 := by
    have hp62' : pc6 (l[62]?.getD 0) % 2 = 1 := hp62
    have hhead' : l[0]?.getD 0 = (63 : Nat) := hhead
    have h63 : pc6 63 % 2 = 0 := by decide
    simp [List.countP_nil, hp62', hhead', h63]
  rw [hwrap]

/-- parity partition: even-count + odd-count = length (Nat lists). -/
theorem parity_filter_split (l : List Nat) :
    (l.filter (· % 2 == 1)).length + (l.filter (· % 2 == 0)).length = l.length := by
  induction l with
  | nil => rfl
  | cons h t ih =>
    simp only [List.filter_cons]
    by_cases hh : h % 2 = 1
    · simp only [hh]; simp; omega
    · have h0 : h % 2 = 0 := by omega
      simp only [h0]; simp; omega

/-- McKENNA'S 3:1 RATIO, FORCED: the 64 circular transition distances (the
    63 linear transitions plus the wrap) of every C4+C5 sequence of the 64
    hexagrams split exactly 16 odd : 48 even — the observed 3:1 even:odd
    ratio of the circular reading is a theorem of C4+C5, not a free design
    feature. (15 odd linear transitions forced by C5's multiset, plus the
    forced odd wrap.) -/
theorem circular_ratio_3_to_1 (l : List Nat) (hb : ∀ x ∈ l, x < 64)
    (hlen : l.length = 64) (h4 : c4ok l = true) (h5 : c5ok l = true) :
    ((wrapDist l :: transitions l).filter (· % 2 == 1)).length = 16 ∧
    ((wrapDist l :: transitions l).filter (· % 2 == 0)).length = 48 := by
  have hne : l ≠ [] := by
    intro h; rw [h] at hlen; simp at hlen
  -- odd linear transitions: 2 + 13 + 0 = 15, from C5's multiset
  have hbnd : ∀ x ∈ transitions l, x ≤ 6 := by
    intro x hx
    simp only [transitions, List.mem_map] at hx
    obtain ⟨⟨a, b⟩, hmem, hxab⟩ := hx
    have hab := List.of_mem_zip hmem
    exact hxab ▸ ham_le6 a (hb a hab.1) b (hb b (List.mem_of_mem_tail hab.2))
  simp only [c5ok, Bool.and_eq_true, beq_iff_eq] at h5
  have hodd15 : ((transitions l).filter (· % 2 == 1)).length = 15 := by
    rw [odd_count_partition _ hbnd, h5.1.1.1.1.1.1, h5.1.1.1.1.2, h5.1.1.2]
  -- re-pack c5ok for the wrap lemma
  have h5' : c5ok l = true := by
    simp only [c5ok, Bool.and_eq_true, beq_iff_eq]
    exact h5
  have hwrapodd : wrapDist l % 2 = 1 := by
    rcases wrap_odd_135 l hb h4 h5' hne with h | h | h <;> rw [h]
  -- transition-list length: 63
  have htlen : (transitions l).length = 63 := by
    simp [transitions, hlen]
  constructor
  · simp only [List.filter_cons, hwrapodd]
    simp [hodd15]
  · have hsplit := parity_filter_split (wrapDist l :: transitions l)
    have hclen : (wrapDist l :: transitions l).length = 64 := by
      simp [htlen]
    have hcodd : ((wrapDist l :: transitions l).filter (· % 2 == 1)).length = 16 := by
      simp only [List.filter_cons, hwrapodd]
      simp [hodd15]
    omega


/- ------------------ THE EQUIVARIANCE CEILING (2026-07-26) ------------------
   The "agnostic generator" corollary of the symmetry theorem. Setting: the finite
   component of Theorem A above (sigma_kw_valid_48, valid_iff_centralizes_rev,
   twins_24_records; sequence-level layer in Automorphism.lean) shows the 48
   constraint symmetries collapse KW's images to exactly 24 distinct record-level
   pair-sequences — the record-level group acts freely, so every valid ordering
   has exactly 23 twins.

   CLAIM (the ceiling): any generator whose scoring/decision function is built
   purely from G-invariant bit-structural primitives (Hamming distance, popcount,
   complement, reversal, the distinguished values 0/63, slot indices, and
   aggregates thereof) induces an output distribution taking EQUAL values on KW's
   record and each of its 23 record-level twins. Such a generator can at best
   concentrate mass uniformly on KW's 24-element orbit — never on KW alone: KW's
   record receives exactly 1/24 of whatever mass the orbit receives.

   Formalization notes.
   * Masses are unnormalized Nat weights: a distribution with rational output
     probabilities (any computable generator) becomes a Nat weight function after
     clearing denominators, with `total` the scaled total mass; the conclusion
     `24 * mass(KW-record) ≤ total` then reads P(KW-record) ≤ 1/24.
   * The hypothesis `hconst` (the score takes one value across all valid symmetry
     images of KW) is precisely G-invariance instantiated at KW; the fully
     general lemma `mass_of_invariant_score` shows any mass factoring through a
     G-invariant score satisfies it, and `popcount_profile_const_on_kw_images`
     witnesses that real record-level invariant-primitive scores inhabit the
     hypothesis class.
   * The hypothesis `htotal` (the orbit's mass-sum is at most the total mass) is
     finite subadditivity of any (sub)probability over pairwise-distinct outcomes
     — the 24 orbit records are pairwise distinct (`kwOrbit_nodup`).
   * REUSE: the orbit size comes verbatim from twins_24_records (`kwOrbit_length`
     IS that theorem, not a re-proof) — the ceiling is a genuine corollary of the
     already-verified free-action finite component.

   Novelty status (per the project's attribution rules): the mathematical
   content is the standard invariance/orbit argument — an invariant score
   induces an output distribution constant on each orbit, so no such generator
   can concentrate on a single orbit element (P ≤ 1/|orbit|). This is Curie's
   principle (1894), worked out explicitly in the equivariant-model
   symmetry-breaking literature: Smidt et al., Phys. Rev. Research 3, L012002
   (2021); "Symmetry Breaking and Equivariant Neural Networks"
   (arXiv:2312.09016); "Improving Equivariant Networks with Probabilistic
   Symmetry Breaking" (arXiv:2503.21985); Burnside/orbit machinery per
   CITATIONS.md. NO novelty is claimed for the argument. What is possibly new,
   to our knowledge, is only its instantiation for the King Wen
   constraint-symmetry group at the record level (the 1/24 constant riding on
   twins_24_records) and the machine-checked formalization. Corrections
   welcome — see CITATIONS.md. -/

/-- the 48 valid symmetry permutations (Theorem A's finite component: exactly the
    centralizer of reversal). -/
def validPerms : List (List Nat) :=
  (perms [0,1,2,3,4,5]).filter fun p => validC15 (KW.map (applyPerm p))

/-- KW's record-level orbit: the distinct pair-sequences among the 48 valid images. -/
def kwOrbit : List (List Nat) :=
  (validPerms.map fun p => pairKey (KW.map (applyPerm p))).eraseDups

/-- the orbit has exactly 24 members — definitionally twins_24_records (REUSED,
    not re-proven). -/
theorem kwOrbit_length : kwOrbit.length = 24 := twins_24_records

/-- eraseDups always yields a duplicate-free list. -/
theorem nodup_eraseDups {α : Type} [BEq α] [LawfulBEq α] : ∀ (l : List α), l.eraseDups.Nodup
  | [] => by simp
  | a :: as => by
    rw [List.eraseDups_cons]
    have hlen : (as.filter fun b => !b == a).length < as.length + 1 := by
      have := List.length_filter_le (fun b => !b == a) as; omega
    refine List.nodup_cons.mpr ⟨?_, nodup_eraseDups _⟩
    intro hmem
    have h := (List.mem_filter.mp (List.mem_eraseDups.mp hmem)).2
    simp at h
termination_by l => l.length

/-- the 24 orbit records are pairwise distinct. -/
theorem kwOrbit_nodup : kwOrbit.Nodup := nodup_eraseDups _

/-- sanity: KW's own record is in the orbit (witness: the identity permutation). -/
theorem kw_record_mem_kwOrbit : pairKey KW ∈ kwOrbit := by
  have hid : KW.map (applyPerm [0,1,2,3,4,5]) = KW := by decide
  refine List.mem_eraseDups.mpr (List.mem_map.mpr ⟨[0,1,2,3,4,5], ?_, by rw [hid]⟩)
  refine List.mem_filter.mpr ⟨by decide, ?_⟩
  rw [hid]; exact kw_valid

/-- EQUIVARIANCE, fully general: a mass assignment that factors through a
    G-invariant score is itself G-invariant — for ANY action, ANY score, ANY
    mass. This one-rewrite lemma is the entire content of the step "a generator
    whose decision function uses only G-invariant primitives is G-equivariant". -/
theorem mass_of_invariant_score {α β γ δ : Type} (act : α → β → β)
    (score : β → γ) (mass : γ → δ)
    (hinv : ∀ σ x, score (act σ x) = score x) (σ : α) (x : β) :
    mass (score (act σ x)) = mass (score x) := by rw [hinv]

/-- summing a function that is constant on a list gives length × the constant. -/
theorem sum_map_const {α : Type} {P : α → Nat} {c : Nat} :
    ∀ (l : List α), (∀ x ∈ l, P x = c) → (l.map P).sum = l.length * c
  | [] => fun _ => by simp
  | x :: xs => fun h => by
    have hx : P x = c := h x (by simp)
    have ht := sum_map_const xs (fun y hy => h y (List.mem_cons_of_mem x hy))
    simp only [List.map_cons, List.sum_cons, List.length_cons, hx, ht,
               Nat.add_mul, Nat.one_mul]
    omega

/-- under an orbit-invariant score, every record in KW's orbit receives the same
    mass as KW's own record — equal probability on KW and each of its 23 twins. -/
theorem mass_const_on_kwOrbit {γ δ : Type} (score : List Nat → γ) (mass : γ → δ)
    (hconst : ∀ p ∈ validPerms, score (pairKey (KW.map (applyPerm p))) = score (pairKey KW)) :
    ∀ r ∈ kwOrbit, mass (score r) = mass (score (pairKey KW)) := by
  intro r hr
  obtain ⟨p, hp, he⟩ := List.mem_map.mp (List.mem_eraseDups.mp hr)
  rw [← he, hconst p hp]

/-- ORBIT-MASS IDENTITY: under an orbit-invariant score the total mass on KW's
    24-record orbit is EXACTLY 24 × the mass on KW's record — concentration
    anywhere inside the orbit is impossible; uniform-on-orbit is forced. -/
theorem kwOrbit_mass_eq {γ : Type} (score : List Nat → γ) (mass : γ → Nat)
    (hconst : ∀ p ∈ validPerms, score (pairKey (KW.map (applyPerm p))) = score (pairKey KW)) :
    (kwOrbit.map fun r => mass (score r)).sum = 24 * mass (score (pairKey KW)) := by
  rw [sum_map_const kwOrbit (mass_const_on_kwOrbit score mass hconst), kwOrbit_length]

/-- THE EQUIVARIANCE CEILING: a generator whose score is G-invariant gives KW's
    record at most 1/24 of the total mass (`24 * mass(KW) ≤ total`, in scaled
    Nat weights). Corollary of twins_24_records: the best any agnostic
    bit-structural generator can achieve is the uniform distribution on KW's
    24-element record orbit — never concentration on KW itself. -/
theorem equivariance_ceiling {γ : Type} (score : List Nat → γ) (mass : γ → Nat)
    (total : Nat)
    (hconst : ∀ p ∈ validPerms, score (pairKey (KW.map (applyPerm p))) = score (pairKey KW))
    (htotal : (kwOrbit.map fun r => mass (score r)).sum ≤ total) :
    24 * mass (score (pairKey KW)) ≤ total := by
  rw [← kwOrbit_mass_eq score mass hconst]; exact htotal

/-- COROLLARY (no agnostic unique-KW generator): if a G-invariantly-scored
    generator puts ALL of its mass on KW's record, its total mass is zero — no
    normalized distribution in this class can single out KW. -/
theorem no_unique_kw_concentration {γ : Type} (score : List Nat → γ) (mass : γ → Nat)
    (total : Nat)
    (hconst : ∀ p ∈ validPerms, score (pairKey (KW.map (applyPerm p))) = score (pairKey KW))
    (htotal : (kwOrbit.map fun r => mass (score r)).sum ≤ total)
    (hall : mass (score (pairKey KW)) = total) :
    total = 0 := by
  have h := equivariance_ceiling score mass total hconst htotal
  omega

/-- inhabitation sanity witness: a genuine record-level score built from invariant
    primitives — the per-slot pair-popcount profile — satisfies `hconst` exactly
    (one value across all 48 valid images, hence across the 24-record orbit).
    Kernel-checked (`decide +kernel`, ~25 s of in-kernel evaluation of the 720
    permutations; the C3Decomposition.lean pattern) — no compiler trust. -/
theorem popcount_profile_const_on_kw_images :
    (validPerms.all fun p =>
      ((pairKey (KW.map (applyPerm p))).map fun k => pc6 (k / 64) + pc6 (k % 64))
        == ((pairKey KW).map fun k => pc6 (k / 64) + pc6 (k % 64))) = true := by
  decide +kernel


/- ------------------ THE COMPLEMENT Z₂ SYMMETRY (2026-07-26) ------------------
   Replacement for the RETRACTED "Theorem 6 (forced orientation)". The retracted
   claim asserted that C1+C4(pair)+C5 force the opening orientation s₀ = 63,
   s₁ = 0. That claim is FALSE: global complementation comp : x ↦ x ⊕ 63,
   applied to every hexagram of a sequence, is an EXACT symmetry of
   C1 ∩ C2 ∩ C3 ∩ C5 — it is broken only by the ORIENTED form of C4.
   In particular comp∘KW is a valid C1∩C2∩C3∩C5 sequence that opens (0, 63),
   the reversed orientation, with C3 = 776 exactly. So under the pair-only
   reading of C4 (the first pair is {0, 63}, orientation unspecified) the
   opening orientation is a FREE Z₂, not a theorem; the published oriented C4
   (Heaven 63 before Earth 0) is definitional — classically attested (the
   Xugua's Heaven-then-Earth opening) — and needs no theorem.

   Proof architecture (all structural + kernel `decide`; no native_decide):
   * C1: partner commutes with complement (partner_comp_comm63, finite decide),
     so complementing both members of a pair preserves the pairing predicate.
   * C2/C5: comp is a Hamming isometry (ham_comp_invariant), so the transition
     multiset — and with it c5ok, whose clauses include the C2 conditions
     (no distance-5, no distance-0) — is unchanged (transitions_compSeq).
   * C3: the c3x64 term of h in comp∘l equals the term of h in l with the two
     findIdx arguments swapped, and each term is symmetric (max/min), so the
     sum is unchanged (c3x64_compSeq). This is the same orientation-freeness
     that C3Decomposition.lean's c3_slot_decomposition establishes at the
     slot level.
   * C4: broken — the head becomes 63 ⊕ 63 = 0 (c4ok_breaks_under_comp).
   * comp is an involution on 6-bit sequences (compSeq_involution), so it is a
     genuine Z₂ action exchanging the two orientations of the opening pair
     bijectively on the C1∩C2∩C3∩C5 solution set. -/

/-- global complementation: complement every hexagram (x ↦ x ⊕ 63). -/
def compSeq (l : List Nat) : List Nat := l.map (· ^^^ 63)

/-- complement stays in range. -/
theorem comp_lt64 : ∀ h < 64, h ^^^ 63 < 64 := by decide

/-- complement is an involution on 6-bit values. -/
theorem comp_invol : ∀ h < 64, (h ^^^ 63) ^^^ 63 = h := by decide

/-- the partner map commutes with complement (cf. C3Decomposition.lean's
    partner_comp_comm; re-proved here because the Lean files are standalone). -/
theorem partner_comp_comm63 : ∀ h < 64, partner (h ^^^ 63) = partner h ^^^ 63 := by
  decide

/-- the partner map stays in range. -/
theorem partner_lt64 : ∀ h < 64, partner h < 64 := by decide

/-- comp is a Hamming isometry on 6-bit values. -/
theorem ham_comp_invariant : ∀ a < 64, ∀ b < 64, ham (a ^^^ 63) (b ^^^ 63) = ham a b := by
  decide

/-- Bool-equality transport across comp (used to move a findIdx predicate). -/
theorem beq_comp_swap : ∀ a < 64, ∀ h < 64, ((a ^^^ 63) == h) = (a == (h ^^^ 63)) := by
  decide

/-- comp is injective at the Bool-equality level. -/
theorem comp_beq_congr : ∀ a < 64, ∀ b < 64, ((a ^^^ 63) == (b ^^^ 63)) = (a == b) := by
  decide

/-- congruence for List.all under a pointwise-equal predicate (self-contained). -/
theorem all_congr' {α : Type} (l : List α) (p q : α → Bool)
    (h : ∀ x ∈ l, p x = q x) : l.all p = l.all q := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    simp only [List.all_cons, h a (by simp),
               ih (fun x hx => h x (List.mem_cons_of_mem a hx))]

/-- congruence for List.map under a pointwise-equal function (self-contained). -/
theorem map_congr' {α β : Type} (l : List α) (f g : α → β)
    (h : ∀ x ∈ l, f x = g x) : l.map f = l.map g := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    simp only [List.map_cons, h a (by simp),
               ih (fun x hx => h x (List.mem_cons_of_mem a hx))]

/-- compSeq is an involution on bounded sequences: comp generates a Z₂ action. -/
theorem compSeq_involution (l : List Nat) (hb : ∀ x ∈ l, x < 64) :
    compSeq (compSeq l) = l := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    have ha := hb a (by simp)
    have ih2 := ih (fun x hx => hb x (List.mem_cons_of_mem a hx))
    show ((a ^^^ 63) ^^^ 63) :: compSeq (compSeq t) = a :: t
    rw [comp_invol a ha, ih2]

/-- in-range getD of a complemented sequence. -/
theorem getD_compSeq (l : List Nat) (j : Nat) (hj : j < l.length) :
    (compSeq l).getD j 99 = l.getD j 99 ^^^ 63 := by
  have hj' : j < (compSeq l).length := by simpa [compSeq] using hj
  have h1 : (compSeq l).getD j 99 = (compSeq l)[j] := by
    simp [List.getD, List.getElem?_eq_getElem hj']
  have h2 : l.getD j 99 = l[j] := by
    simp [List.getD, List.getElem?_eq_getElem hj]
  rw [h1, h2]
  simp [compSeq]

/-- comp preserves the transition-distance list exactly (Hamming isometry). -/
theorem transitions_compSeq (l : List Nat) (hb : ∀ x ∈ l, x < 64) :
    transitions (compSeq l) = transitions l := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    cases t with
    | nil => rfl
    | cons b t2 =>
      have ha := hb a (by simp)
      have hbb := hb b (by simp)
      have ih2 := ih (fun x hx => hb x (List.mem_cons_of_mem a hx))
      have hexp : transitions ((a ^^^ 63) :: (b ^^^ 63) :: compSeq t2) =
          ham (a ^^^ 63) (b ^^^ 63) :: transitions ((b ^^^ 63) :: compSeq t2) := by
        simp [transitions]
      have hexp2 : transitions (a :: b :: t2) = ham a b :: transitions (b :: t2) := by
        simp [transitions]
      show transitions ((a ^^^ 63) :: (b ^^^ 63) :: compSeq t2) = transitions (a :: b :: t2)
      rw [hexp, hexp2, ham_comp_invariant a ha b hbb]
      exact congrArg _ ih2

/-- COMP PRESERVES C5 (hence C2, whose conditions are c5ok clauses): the
    difference-wave multiset of comp∘l equals l's. -/
theorem c5ok_compSeq (l : List Nat) (hb : ∀ x ∈ l, x < 64) :
    c5ok (compSeq l) = c5ok l := by
  unfold c5ok
  rw [transitions_compSeq l hb]

/-- COMP PRESERVES C1: complementing both members of every pair preserves the
    partner pairing (partner commutes with comp). -/
theorem c1ok_compSeq (l : List Nat) (hb : ∀ x ∈ l, x < 64) (hlen : l.length = 64) :
    c1ok (compSeq l) = c1ok l := by
  have hget : ∀ j, j < 64 → l.getD j 99 < 64 := by
    intro j hj
    have hjl : j < l.length := by omega
    have : l.getD j 99 = l[j] := by simp [List.getD, List.getElem?_eq_getElem hjl]
    rw [this]; exact hb _ (List.getElem_mem hjl)
  unfold c1ok
  apply all_congr'
  intro i hi
  have hi32 := List.mem_range.mp hi
  have e1 : (compSeq l).getD (2*i+1) 99 = l.getD (2*i+1) 99 ^^^ 63 :=
    getD_compSeq l _ (by omega)
  have e0 : (compSeq l).getD (2*i) 99 = l.getD (2*i) 99 ^^^ 63 :=
    getD_compSeq l _ (by omega)
  have hx := hget (2*i+1) (by omega)
  have hy := hget (2*i) (by omega)
  simp only [e1, e0, partner_comp_comm63 _ hy,
             comp_beq_congr _ hx _ (partner_lt64 _ hy)]

/-- findIdx across comp: looking for h in comp∘l is looking for comp h in l. -/
theorem findIdx_compSeq (l : List Nat) (hb : ∀ x ∈ l, x < 64) (h : Nat) (hh : h < 64) :
    (compSeq l).findIdx (· == h) = l.findIdx (· == (h ^^^ 63)) := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    have ha := hb a (by simp)
    have ih2 := ih (fun x hx => hb x (List.mem_cons_of_mem a hx))
    have hcons : compSeq (a :: t) = (a ^^^ 63) :: compSeq t := rfl
    rw [hcons, List.findIdx_cons, List.findIdx_cons, beq_comp_swap a ha h hh, ih2]

/-- COMP PRESERVES C3 EXACTLY: the x64 complement-distance sum is invariant —
    each h-term of comp∘l is the h-term of l with its two position lookups
    swapped, and every term is max/min-symmetric. (The slot-level counterpart
    is C3Decomposition.lean's orientation-free c3_slot_decomposition.) -/
theorem c3x64_compSeq (l : List Nat) (hb : ∀ x ∈ l, x < 64) :
    c3x64 (compSeq l) = c3x64 l := by
  unfold c3x64
  apply congrArg
  apply map_congr'
  intro h hmem
  have h64 := List.mem_range.mp hmem
  have hc64 : h ^^^ 63 < 64 := comp_lt64 h h64
  have e1 : (compSeq l).findIdx (· == h) = l.findIdx (· == (h ^^^ 63)) :=
    findIdx_compSeq l hb h h64
  have e2 : (compSeq l).findIdx (· == (h ^^^ 63)) = l.findIdx (· == ((h ^^^ 63) ^^^ 63)) :=
    findIdx_compSeq l hb _ hc64
  rw [comp_invol h h64] at e2
  simp only [e1, e2]
  rw [Nat.max_comm, Nat.min_comm]

theorem c3ok_compSeq (l : List Nat) (hb : ∀ x ∈ l, x < 64) :
    c3ok (compSeq l) = c3ok l := by
  unfold c3ok
  rw [c3x64_compSeq l hb]

/-- THE COMPLEMENT SYMMETRY THEOREM: global complementation is an exact
    symmetry of C1 ∩ C2 ∩ C3 ∩ C5 — for every 64-element 6-bit sequence,
    comp∘l satisfies each of C1, C5 (whose clauses include C2), and C3
    exactly iff l does. Only the oriented form of C4 is not preserved. -/
theorem comp_symmetry_c1_c2_c3_c5 (l : List Nat) (hb : ∀ x ∈ l, x < 64)
    (hlen : l.length = 64) :
    c1ok (compSeq l) = c1ok l ∧ c5ok (compSeq l) = c5ok l ∧
    c3ok (compSeq l) = c3ok l :=
  ⟨c1ok_compSeq l hb hlen, c5ok_compSeq l hb, c3ok_compSeq l hb⟩

/-- what breaks — and the ONLY thing that breaks: the oriented C4. Any
    sequence opening at 63 opens at 0 after complementation. -/
theorem c4ok_breaks_under_comp (l : List Nat) (hlen : l.length = 64)
    (h4 : c4ok l = true) : c4ok (compSeq l) = false := by
  simp only [c4ok, Bool.and_eq_true, beq_iff_eq] at h4
  have e0 : (compSeq l).getD 0 99 = l.getD 0 99 ^^^ 63 :=
    getD_compSeq l 0 (by omega)
  have hfalse : ((63 ^^^ 63 : Nat) == 63) = false := by decide
  simp only [c4ok, e0, h4.1, hfalse, Bool.false_and]

theorem kw_all_lt64 : ∀ x ∈ KW, x < 64 := by decide

theorem kw_length_64 : KW.length = 64 := by decide

/-- kernel-decide re-statements of kw_valid / kw_c3_exactly_776, kept for name
    continuity (they predate the 2026-07-27 migration; the originals above are
    themselves kernel `decide` now, so these are plain aliases of the same
    kernel-only facts — [propext, Quot.sound], no native_decide). -/
theorem kw_valid_kernel : validC15 KW = true := kw_valid

theorem kw_c3_776_kernel : c3x64 KW = 776 := kw_c3_exactly_776

/-- ORIENTATION IS NOT FORCED (the corrected statement): comp∘KW opens
    (0, 63) — the REVERSED orientation of the {0, 63} pair — and satisfies
    C1, C5 (hence C2), and C3 with the sum at exactly 776. Direct corollary
    of the symmetry theorem instantiated at King Wen; the finite facts are
    kernel `decide`, no native_decide. Both orientations of the opening pair
    are therefore valid for C1∩C2∩C3∩C5, and the orientation in C4 is a free
    Z₂ fixed by definition (classical Xugua attestation), not by mathematics. -/
theorem orientation_not_forced :
    c1ok (compSeq KW) = true ∧ c5ok (compSeq KW) = true ∧
    c3ok (compSeq KW) = true ∧ c3x64 (compSeq KW) = 776 ∧
    c4ok (compSeq KW) = false ∧
    (compSeq KW).getD 0 99 = 0 ∧ (compSeq KW).getD 1 99 = 63 := by
  obtain ⟨h1, h5, h3⟩ := comp_symmetry_c1_c2_c3_c5 KW kw_all_lt64 kw_length_64
  have hv := kw_valid_kernel
  simp only [validC15, Bool.and_eq_true] at hv
  refine ⟨?_, ?_, ?_, ?_, ?_, by decide, by decide⟩
  · rw [h1]; exact hv.1.1.1
  · rw [h5]; exact hv.1.2
  · rw [h3]; exact hv.2
  · rw [c3x64_compSeq KW kw_all_lt64]; exact kw_c3_776_kernel
  · exact c4ok_breaks_under_comp KW kw_length_64 hv.1.1.2
