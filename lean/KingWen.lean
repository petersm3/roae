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
