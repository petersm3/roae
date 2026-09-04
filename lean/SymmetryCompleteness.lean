-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  SymmetryCompleteness.lean — finite kernel of TR-5 v2.0's completeness theorem
  (2026-07-18). Core Lean 4 only (no mathlib; standalone, no lake project).

  Machine-checks the finite lemmas of documentation/SYMMETRY_SEARCH.md
  §"Completeness over ALL 64! relabelings" — the kernel facts consumed by the
  prose proof that

      among ALL 64! hexagram relabelings, exactly the 48 elements of
      C_S6(rev) preserve the C1–C5 predicate family (C1+C2+C4 force
      membership).

  Checked here (kernel-only since 2026-08-07 — see the trust-base note
  below):

    SC1  psi (the parity-complement map) is an involution on {0..63} and maps
         the Hamming-distance-5 relation to the distance-1 relation: the
         "distance-5 graph" G5 is isomorphic to the 6-cube Q6.
    SC2  psi commutes with every one of the 720 bit-position permutations.
    SC3  every distance-2 pair in Q6 has EXACTLY two common neighbors —
         the mathematical load-bearer of hypercube rigidity.
    SC4  the weight-induction forced extension anchored at the identity on
         {0} ∪ N1(0) is everywhere-forced (unique candidate at every step)
         and equals the identity — the rigidity kernel, computed, not
         searched.
    SC7  the bit-position permutations commuting with the canonical partner
         involution are EXACTLY Automorphism.lean's G48 (the centralizer of
         bit-reversal), and there are exactly 48 of them.

  NOT formalized here (covered exhaustively by `solve.py
  --symmetry-completeness` gates SC-5/SC-6 and by the prose + SAT kernel
  `sat.py --rigidity-cnf`): the explicit 46,080-element Aut(G5) enumeration,
  the fix-0 collapse, and the sequence-level witness arguments (the W2
  family) that lift these finite facts to the preservation statement. The
  forward direction (the 48 preserve C1–C5 on all orderings) is
  Automorphism.lean's validC15_mapP.

  Trust base (updated 2026-08-07, per the standing native_decide → decide
  migration policy in lean/README.md): kernel-only end to end — ZERO
  native_decide anywhere in this file. The finite facts SC1/SC3/SC4/SC7 are
  `decide +kernel` (kernel-evaluated, no compiler trust). SC2
  (psi_comm_perms) — this file's dominant obligation, and its last
  native_decide until 2026-08-07 (the direct 720 × 64 kernel enumeration was
  measured at ~13.7 GB peak RSS on this toolchain and rejected as a hardware
  bar) — is now structural: psi commutes with every bit-position permutation
  POINTWISE, from (i) popcount preservation under bit relocation (§1a/§1b:
  applyPerm p moves bit i of n to position p[i], so the popcount sum merely
  reindexes along p) and (ii) commutation of the 6-bit complement with
  applyPerm, proved bit-by-bit via Nat.eq_of_testBit_eq. Neither leg is
  novel — both are classical bit-manipulation facts; the contribution is the
  machine-checked layer only. Statements are unchanged from the
  native_decide revision, verbatim.

  The defs pc6/rev6/partner/inserts/perms/applyPerm are restated verbatim
  from KingWen.lean / Automorphism.lean (standalone-file convention).
-/

namespace SymmetryCompleteness

/- ------------------ §0 defs restated verbatim ------------------ -/

/-- popcount for 6-bit values (total, no recursion needed). -/
def pc6 (n : Nat) : Nat :=
  n % 2 + n / 2 % 2 + n / 4 % 2 + n / 8 % 2 + n / 16 % 2 + n / 32 % 2

/-- 6-bit reversal. -/
def rev6 (n : Nat) : Nat :=
  n % 2 * 32 + n / 2 % 2 * 16 + n / 4 % 2 * 8 + n / 8 % 2 * 4 + n / 16 % 2 * 2 + n / 32 % 2

/-- canonical partner: reversal, or complement for palindromes. -/
def partner (h : Nat) : Nat := if rev6 h = h then h ^^^ 63 else rev6 h

def inserts (x : Nat) : List Nat → List (List Nat)
  | [] => [[x]]
  | y :: ys => (x :: y :: ys) :: (inserts x ys).map (y :: ·)

def perms : List Nat → List (List Nat)
  | [] => [[]]
  | x :: xs => (perms xs).flatMap (inserts x)

/-- apply a bit-position permutation p (bit i of n goes to position p[i]). -/
def applyPerm (p : List Nat) (n : Nat) : Nat :=
  ((List.range 6).map fun i => n / (2^i) % 2 * 2^(p.getD i 0)).foldl (·+·) 0

/-- the identity bit permutation. -/
def idp : List Nat := [0, 1, 2, 3, 4, 5]

/-- G48 = the centralizer of bit-reversal among the 720 bit permutations
    (verbatim from Automorphism.lean). -/
def G48 : List (List Nat) :=
  (perms idp).filter fun p =>
    (List.range 64).all fun h => applyPerm p (rev6 h) == rev6 (applyPerm p h)

/- ------------------ §1 new defs for the completeness kernel ------------------ -/

/-- Hamming distance on 6-bit values. -/
def ham (a b : Nat) : Nat := pc6 (a ^^^ b)

/-- the parity-complement map: G5 → Q6 isomorphism. -/
def psi (x : Nat) : Nat := if pc6 x % 2 = 0 then x else x ^^^ 63

def hexes : List Nat := List.range 64

/- ------------------ §1a machinery (adapted from PruneGInvariance §0b) ------------------ -/

theorem sum_perm {l₁ l₂ : List Nat} (h : l₁.Perm l₂) : l₁.sum = l₂.sum := by
  induction h with
  | nil => rfl
  | cons x _ ih => simp [ih]
  | swap x y l => simp [List.sum_cons]; omega
  | trans _ _ ih₁ ih₂ => omega

theorem mem_inserts_perm {x : Nat} : ∀ {l q : List Nat}, q ∈ inserts x l → q.Perm (x :: l)
  | [], q, hq => by
      simp only [inserts, List.mem_cons, List.not_mem_nil, or_false] at hq
      subst hq; exact List.Perm.refl _
  | y :: ys, q, hq => by
      simp only [inserts, List.mem_cons, List.mem_map] at hq
      rcases hq with rfl | ⟨q', hq', rfl⟩
      · exact List.Perm.refl _
      · exact (List.Perm.cons y (mem_inserts_perm hq')).trans (List.Perm.swap x y ys)

theorem mem_perms_perm : ∀ {l q : List Nat}, q ∈ perms l → q.Perm l
  | [], q, hq => by
      simp only [perms, List.mem_cons, List.not_mem_nil, or_false] at hq
      subst hq; exact List.Perm.refl _
  | x :: xs, q, hq => by
      simp only [perms, List.mem_flatMap] at hq
      obtain ⟨r, hr, hq2⟩ := hq
      exact (mem_inserts_perm hq2).trans (List.Perm.cons x (mem_perms_perm hr))

theorem foldl_add_eq_sum : ∀ (l : List Nat) (a : Nat), l.foldl (·+·) a = a + l.sum
  | [], a => by simp
  | x :: xs, a => by
      rw [List.foldl_cons, foldl_add_eq_sum xs (a + x), List.sum_cons]
      omega

theorem getD_mem : ∀ (l : List Nat) (k : Nat), k < l.length → l.getD k 0 ∈ l
  | [], _, h => by simp at h
  | x :: xs, 0, _ => by simp
  | x :: xs, k+1, h => by
      rw [List.getD_cons_succ]
      exact List.mem_cons_of_mem x (getD_mem xs k (by simpa using h))

theorem map_getD_comp (l : List Nat) (f : Nat → Nat) :
    l.map f = (List.range l.length).map (fun i => f (l.getD i 0)) := by
  induction l with
  | nil => rfl
  | cons x xs _ =>
      rw [List.length_cons, List.range_succ_eq_map, List.map_cons, List.map_cons,
        List.map_map]
      congr 1

def bitsum : List Nat → Nat → Nat
  | [], _ => 0
  | x :: xs, n => n % 2 * 2^x + bitsum xs (n / 2)

theorem range_map_bits (q : List Nat) : ∀ n : Nat,
    ((List.range q.length).map fun i => n / 2^i % 2 * 2^(q.getD i 0)).sum = bitsum q n := by
  induction q with
  | nil => intro n; rfl
  | cons x xs ih =>
      intro n
      rw [List.length_cons, List.range_succ_eq_map, List.map_cons, List.map_map, List.sum_cons]
      have hhead : n / 2^0 % 2 * 2^((x :: xs).getD 0 0) = n % 2 * 2^x := by
        simp
      have htail : ((List.range xs.length).map
          ((fun i => n / 2^i % 2 * 2^((x :: xs).getD i 0)) ∘ Nat.succ)).sum
          = bitsum xs (n / 2) := by
        rw [← ih (n / 2)]
        apply congrArg
        apply List.map_congr_left
        intro i _
        simp only [Function.comp, Nat.succ_eq_add_one, List.getD_cons_succ]
        have hdiv : n / 2 ^ (i + 1) = n / 2 / 2 ^ i := by
          rw [Nat.div_div_eq_div_mul, ← Nat.pow_succ']
        rw [hdiv]
      rw [hhead, htail]
      rfl

theorem applyPerm_eq_bitsum (p : List Nat) (hlen : p.length = 6) (n : Nat) :
    applyPerm p n = bitsum p n := by
  unfold applyPerm
  rw [foldl_add_eq_sum, Nat.zero_add, ← hlen, range_map_bits]

theorem bit_add_high {c T x j : Nat} (hc : c < 2) (hT : T / 2^x % 2 = 0) (hj : x < j) :
    (c * 2^x + T) / 2^j % 2 = T / 2^j % 2 := by
  have hqe : T / 2^x = 2 * (T / 2^(x+1)) := by
    have h1 := Nat.div_add_mod (T / 2^x) 2
    have h2 : T / 2^x / 2 = T / 2^(x+1) := by
      rw [Nat.div_div_eq_div_mul, ← Nat.pow_succ]
    rw [h2] at h1
    omega
  have hmul : 2^x * (2 * (T / 2^(x+1))) = 2^(x+1) * (T / 2^(x+1)) := by
    rw [Nat.pow_succ, Nat.mul_assoc]
  have hTdecomp : T = 2^(x+1) * (T / 2^(x+1)) + T % 2^x := by
    have h3 := Nat.div_add_mod T (2^x)
    rw [hqe, hmul] at h3
    exact h3.symm
  have hr : T % 2^x < 2^x := Nat.mod_lt _ (Nat.two_pow_pos x)
  have hcr : c * 2^x + T % 2^x < 2^(x+1) := by
    have h4 : c * 2^x ≤ 1 * 2^x := Nat.mul_le_mul_right _ (by omega)
    rw [Nat.one_mul] at h4
    rw [Nat.pow_succ]
    omega
  have hN : (c * 2^x + T) / 2^(x+1) = T / 2^(x+1) := by
    generalize hhi : T / 2^(x+1) = hi at hTdecomp ⊢
    generalize hrr : T % 2^x = r at hTdecomp hcr
    rw [hTdecomp]
    rw [← Nat.add_assoc, Nat.add_comm (c * 2^x) (2^(x+1) * hi), Nat.add_assoc,
        Nat.mul_add_div (Nat.two_pow_pos (x+1)), Nat.div_eq_of_lt hcr, Nat.add_zero]
  have hdd : ∀ N : Nat, N / 2^j = N / 2^(x+1) / 2^(j-x-1) := by
    intro N
    rw [Nat.div_div_eq_div_mul, ← Nat.pow_add]
    congr 2
    omega
  rw [hdd (c * 2^x + T), hdd T, hN]

theorem bit_add_disjoint {c T x : Nat} (j : Nat) (hc : c < 2) (hT : T / 2^x % 2 = 0) :
    (c * 2^x + T) / 2^j % 2 = if j = x then c else T / 2^j % 2 := by
  rcases Nat.lt_trichotomy j x with hlt | heq | hgt
  · rw [if_neg (Nat.ne_of_lt hlt)]
    have hx : (2:Nat)^x = 2^(x-j) * 2^j := by
      rw [← Nat.pow_add]; congr 1; omega
    rw [hx, ← Nat.mul_assoc, Nat.add_comm, Nat.mul_comm (c * 2^(x-j)) (2^j)]
    rw [Nat.add_mul_div_left _ _ (Nat.two_pow_pos j)]
    have heven : c * 2^(x-j) = 2 * (c * 2^(x-j-1)) := by
      have h2p : (2:Nat)^(x-j) = 2 * 2^(x-j-1) := by
        rw [← Nat.pow_succ']
        congr 1
        omega
      rw [h2p, ← Nat.mul_assoc, Nat.mul_comm c 2, Nat.mul_assoc]
    rw [heven]
    generalize T / 2^j = u
    omega
  · subst heq
    rw [if_pos rfl, Nat.add_comm, Nat.mul_comm c (2^j)]
    rw [Nat.add_mul_div_left _ _ (Nat.two_pow_pos j)]
    generalize hu : T / 2^j = u
    rw [hu] at hT
    omega
  · rw [if_neg (Nat.ne_of_gt hgt)]
    exact bit_add_high hc hT hgt

theorem bitsum_bit_notmem : ∀ (q : List Nat), q.Nodup → ∀ (n j : Nat), j ∉ q →
    bitsum q n / 2^j % 2 = 0
  | [], _, n, j, _ => by simp [bitsum]
  | x :: xs, hnd, n, j, hj => by
      have hx : x ∉ xs := (List.nodup_cons.mp hnd).1
      have hxs : xs.Nodup := (List.nodup_cons.mp hnd).2
      have hjx : j ≠ x := fun h => hj (h ▸ List.mem_cons_self ..)
      have hjxs : j ∉ xs := fun h => hj (List.mem_cons_of_mem x h)
      have hm2 : n % 2 < 2 := Nat.mod_lt n (by decide)
      have hT : bitsum xs (n/2) / 2^x % 2 = 0 := bitsum_bit_notmem xs hxs (n/2) x hx
      rw [show bitsum (x :: xs) n = n % 2 * 2^x + bitsum xs (n/2) from rfl]
      rw [bit_add_disjoint j hm2 hT, if_neg hjx]
      exact bitsum_bit_notmem xs hxs (n/2) j hjxs

theorem bitsum_bit_getD : ∀ (q : List Nat), q.Nodup → ∀ (n k : Nat), k < q.length →
    bitsum q n / 2^(q.getD k 0) % 2 = n / 2^k % 2
  | [], _, _, k, h => by simp at h
  | x :: xs, hnd, n, 0, _ => by
      have hx : x ∉ xs := (List.nodup_cons.mp hnd).1
      have hm2 : n % 2 < 2 := Nat.mod_lt n (by decide)
      have hT : bitsum xs (n/2) / 2^x % 2 = 0 :=
        bitsum_bit_notmem xs (List.nodup_cons.mp hnd).2 (n/2) x hx
      rw [List.getD_cons_zero,
          show bitsum (x :: xs) n = n % 2 * 2^x + bitsum xs (n/2) from rfl,
          bit_add_disjoint x hm2 hT, if_pos rfl]
      simp
  | x :: xs, hnd, n, k+1, hk => by
      have hx : x ∉ xs := (List.nodup_cons.mp hnd).1
      have hxs : xs.Nodup := (List.nodup_cons.mp hnd).2
      have hklen : k < xs.length := by simpa using hk
      have hne : xs.getD k 0 ≠ x := fun h => hx (h ▸ getD_mem xs k hklen)
      have hm2 : n % 2 < 2 := Nat.mod_lt n (by decide)
      have hT : bitsum xs (n/2) / 2^x % 2 = 0 := bitsum_bit_notmem xs hxs (n/2) x hx
      rw [List.getD_cons_succ,
          show bitsum (x :: xs) n = n % 2 * 2^x + bitsum xs (n/2) from rfl,
          bit_add_disjoint (xs.getD k 0) hm2 hT, if_neg hne,
          bitsum_bit_getD xs hxs (n/2) k hklen]
      rw [Nat.div_div_eq_div_mul, ← Nat.pow_succ']

theorem pc6_eq_bits (m : Nat) :
    pc6 m = ((List.range 6).map fun i => m / 2^i % 2).sum := by
  rw [show List.range 6 = [0,1,2,3,4,5] from rfl]
  simp only [List.map_cons, List.map_nil, List.sum_cons, List.sum_nil]
  unfold pc6
  simp only [show (2:Nat)^0 = 1 from rfl, show (2:Nat)^1 = 2 from rfl,
    show (2:Nat)^2 = 4 from rfl, show (2:Nat)^3 = 8 from rfl,
    show (2:Nat)^4 = 16 from rfl, show (2:Nat)^5 = 32 from rfl, Nat.div_one]
  omega

/- ------------------ §1b the structural lemmas for SC2 ------------------ -/

/-- per-bit xor: the xor'd bit is the disagreement indicator (verbatim from
    PruneGInvariance §0b). -/
theorem xor_bit (a b i : Nat) :
    (a ^^^ b) / 2^i % 2 = if a / 2^i % 2 = b / 2^i % 2 then 0 else 1 := by
  have hxor := Nat.testBit_xor a b i
  rw [Nat.testBit_eq_decide_div_mod_eq, Nat.testBit_eq_decide_div_mod_eq,
      Nat.testBit_eq_decide_div_mod_eq] at hxor
  have ha := Nat.mod_two_eq_zero_or_one (a / 2^i)
  have hb := Nat.mod_two_eq_zero_or_one (b / 2^i)
  have hab := Nat.mod_two_eq_zero_or_one ((a ^^^ b) / 2^i)
  rcases ha with ha | ha <;> rcases hb with hb | hb <;>
    rw [ha, hb] at hxor ⊢ <;> simp at hxor ⊢ <;> omega

/-- bitsum is bounded by the sum of its scatter powers (each bit contributes
    at most its target power). -/
theorem bitsum_le : ∀ (q : List Nat) (n : Nat), bitsum q n ≤ (q.map (2^·)).sum
  | [], _ => Nat.le_refl 0
  | x :: xs, n => by
      rw [show bitsum (x :: xs) n = n % 2 * 2^x + bitsum xs (n / 2) from rfl,
          List.map_cons, List.sum_cons]
      have h4 : n % 2 * 2^x ≤ 1 * 2^x := Nat.mul_le_mul_right _ (by omega)
      rw [Nat.one_mul] at h4
      exact Nat.add_le_add h4 (bitsum_le xs (n / 2))

/-- a bit-position permutation scatters into positions 0..5, so its image is
    a 6-bit value: applyPerm p n ≤ 63 < 64 for every n. -/
theorem applyPerm_lt64_perm (p : List Nat) (hp : p.Perm idp) (n : Nat) :
    applyPerm p n < 64 := by
  have hlen : p.length = 6 := hp.length_eq
  rw [applyPerm_eq_bitsum p hlen n]
  have h1 : bitsum p n ≤ (p.map (2^·)).sum := bitsum_le p n
  have h2 : (p.map (2^·)).sum = (idp.map (2^·)).sum := sum_perm (hp.map _)
  have h3 : (idp.map (2^·)).sum = 63 := by decide
  omega

/-- members of a permutation of idp are < 6. -/
theorem mem_perm_idp_lt6 {p : List Nat} (hp : p.Perm idp) {j : Nat} (hj : j ∈ p) :
    j < 6 := by
  have : j ∈ idp := hp.mem_iff.mp hj
  simp only [idp, List.mem_cons, List.not_mem_nil, or_false] at this
  omega

/-- bit-position permutations preserve the 6-bit popcount (reindex the bit
    sum along p; classical, the weight-preservation half of the isometry). -/
theorem pc6_applyPerm (p : List Nat) (hp : p.Perm idp) (n : Nat) :
    pc6 (applyPerm p n) = pc6 n := by
  have hlen : p.length = 6 := hp.length_eq
  have hnd : p.Nodup := hp.nodup_iff.mpr (by decide)
  have hp6 : p.Perm (List.range 6) := by
    rw [show List.range 6 = idp from rfl]; exact hp
  rw [pc6_eq_bits, pc6_eq_bits n]
  have h1 : ((List.range 6).map fun j => applyPerm p n / 2^j % 2).sum
      = (p.map fun j => applyPerm p n / 2^j % 2).sum :=
    (sum_perm (hp6.map _)).symm
  have h2 : (p.map fun j => applyPerm p n / 2^j % 2)
      = (List.range 6).map (fun i => applyPerm p n / 2^(p.getD i 0) % 2) := by
    rw [map_getD_comp p, hlen]
  have h3 : ((List.range 6).map (fun i => applyPerm p n / 2^(p.getD i 0) % 2))
      = (List.range 6).map (fun i => n / 2^i % 2) := by
    apply List.map_congr_left
    intro i hi
    have hip : i < p.length := by
      have := List.mem_range.mp hi; omega
    rw [applyPerm_eq_bitsum p hlen n, bitsum_bit_getD p hnd n i hip]
  rw [h1, h2, h3]

/-- bit j of the constant 63 is 1 exactly on the six low positions. -/
theorem bit63 (j : Nat) (hj : j < 6) : 63 / 2^j % 2 = 1 := by
  match j, hj with
  | 0, _ => decide
  | 1, _ => decide
  | 2, _ => decide
  | 3, _ => decide
  | 4, _ => decide
  | 5, _ => decide

/-- getD agrees with getElem in bounds (own induction; core-name-agnostic). -/
theorem getD_eq_getElem' : ∀ (l : List Nat) (k : Nat) (h : k < l.length), l.getD k 0 = l[k]
  | [], _, h => by simp at h
  | x :: xs, 0, _ => by simp
  | x :: xs, k+1, h => by
      rw [List.getD_cons_succ, List.getElem_cons_succ]
      exact getD_eq_getElem' xs k (by simpa using h)

/-- xor with 63 flips each of the six low bits. -/
theorem xor63_bit (m k : Nat) (hk : k < 6) :
    (m ^^^ 63) / 2^k % 2 = 1 - m / 2^k % 2 := by
  rw [xor_bit m 63 k, bit63 k hk]
  rcases Nat.mod_two_eq_zero_or_one (m / 2^k) with h | h <;> rw [h] <;> simp

/-- testBit in the div/mod formulation (bridge used throughout). -/
theorem testBit_dm (a i : Nat) : a.testBit i = decide (a / 2^i % 2 = 1) :=
  Nat.testBit_eq_decide_div_mod_eq

/-- high bits of a 6-bit value are clear. -/
theorem testBit_ge6_of_lt64 {a : Nat} (ha : a < 64) {j : Nat} (hj : 6 ≤ j) :
    a.testBit j = false := by
  rw [testBit_dm]
  have h64 : (64:Nat) ≤ 2^j := by
    have h6 : (2:Nat)^6 ≤ 2^j := Nat.pow_le_pow_right (by omega) hj
    have he : (64:Nat) = 2^6 := rfl
    omega
  have hz : a / 2^j = 0 := Nat.div_eq_of_lt (by omega)
  simp [hz]

/-- THE COMMUTATION with the 6-bit complement: applyPerm p (n ^^^ 63) =
    applyPerm p n ^^^ 63 for every permutation p of the bit positions and
    every n (both sides only ever read/write the six low bits). Structural:
    equality is checked bit-by-bit via Nat.eq_of_testBit_eq — p relocates
    the complemented bit k to position p[k] on the left, while the right
    complements the already-relocated bit at the same position. -/
theorem applyPerm_comp63 (p : List Nat) (hp : p.Perm idp) (n : Nat) :
    applyPerm p (n ^^^ 63) = applyPerm p n ^^^ 63 := by
  have hlen : p.length = 6 := hp.length_eq
  have hnd : p.Nodup := hp.nodup_iff.mpr (by decide)
  apply Nat.eq_of_testBit_eq
  intro j
  by_cases hj6 : j < 6
  · -- j is in the image of p: j = p[k] for some k < 6
    have hjp : j ∈ p := by
      apply hp.mem_iff.mpr
      simp only [idp, List.mem_cons, List.not_mem_nil, or_false]
      omega
    obtain ⟨k, hk, hpk⟩ := List.getElem_of_mem hjp
    have hgetD : p.getD k 0 = j := by
      rw [getD_eq_getElem' p k hk]
      exact hpk
    -- left side: bit j of applyPerm p (n ^^^ 63) = bit k of (n ^^^ 63) = flipped bit k of n
    have hL : applyPerm p (n ^^^ 63) / 2^j % 2 = (n ^^^ 63) / 2^k % 2 := by
      rw [applyPerm_eq_bitsum p hlen, ← hgetD, bitsum_bit_getD p hnd _ k hk]
    -- right side: bit j of applyPerm p n = bit k of n
    have hR : applyPerm p n / 2^j % 2 = n / 2^k % 2 := by
      rw [applyPerm_eq_bitsum p hlen, ← hgetD, bitsum_bit_getD p hnd n k hk]
    have hk6 : k < 6 := by omega
    rw [testBit_dm, testBit_dm, hL, xor63_bit n k hk6,
        xor63_bit (applyPerm p n) j hj6, hR]
  · -- j ≥ 6: both sides read 0 there
    have hj6' : 6 ≤ j := Nat.le_of_not_lt hj6
    have hL : (applyPerm p (n ^^^ 63)).testBit j = false :=
      testBit_ge6_of_lt64 (applyPerm_lt64_perm p hp _) hj6'
    have hR : (applyPerm p n ^^^ 63).testBit j = false := by
      rw [Nat.testBit_xor,
          testBit_ge6_of_lt64 (applyPerm_lt64_perm p hp n) hj6',
          testBit_ge6_of_lt64 (by omega : (63:Nat) < 64) hj6']
      rfl
    rw [hL, hR]

/-- POINTWISE commutation of psi with any bit-position permutation: the
    parity branch is stable (pc6_applyPerm) and the complement branch
    commutes (applyPerm_comp63). -/
theorem psi_comm_pointwise (p : List Nat) (hp : p.Perm idp) (h : Nat) :
    psi (applyPerm p h) = applyPerm p (psi h) := by
  unfold psi
  rw [pc6_applyPerm p hp h]
  by_cases hpar : pc6 h % 2 = 0
  · rw [if_pos hpar, if_pos hpar]
  · rw [if_neg hpar, if_neg hpar, applyPerm_comp63 p hp h]

/- ------------------ §2 SC1: psi is an involution and a G5 ≅ Q6 isomorphism ------------------ -/

theorem psi_involution : hexes.all (fun x => psi (psi x) == x) = true := by decide +kernel

theorem psi_g5_iso :
    (hexes.all fun x => hexes.all fun y =>
      ((ham x y == 5) == (ham (psi x) (psi y) == 1))) = true := by decide +kernel

/- ------------------ §3 SC2: psi commutes with all 720 bit-position permutations ------------------ -/

theorem psi_comm_perms :
    ((perms idp).all fun p => hexes.all fun h =>
      psi (applyPerm p h) == applyPerm p (psi h)) = true := by
  rw [List.all_eq_true]
  intro p hp
  rw [List.all_eq_true]
  intro h _
  exact beq_iff_eq.mpr (psi_comm_pointwise p (mem_perms_perm hp) h)

/- ------------------ §4 SC3: the two-common-neighbor lemma on Q6 ------------------ -/

theorem q6_two_common_neighbors :
    (hexes.all fun y => hexes.all fun z =>
      (y == z) || (ham y z != 2) ||
      ((hexes.filter fun a => ham a y == 1 && ham a z == 1).length == 2)) = true := by
  decide +kernel

/- ------------------ §5 SC4: the rigidity kernel (forced identity extension) ------------------ -/

/-- lowest set bit of a 6-bit value (total; 0 for x = 0, unused there). -/
def lowBit (x : Nat) : Nat :=
  if x % 2 = 1 then 1
  else if x % 4 = 2 then 2
  else if x % 8 = 4 then 4
  else if x % 16 = 8 then 8
  else if x % 32 = 16 then 16
  else if x % 64 = 32 then 32
  else 0

/-- one propagation step: given the partial table `tbl` (index = vertex, value =
    image; identity pre-seeded on weights 0 and 1) and a vertex x of weight ≥ 2,
    the candidate images are the common Q6-neighbors of the images of two of x's
    weight-(k−1) subwords, excluding the image of their weight-(k−2) meet. The
    fold records whether the candidate was UNIQUE at every step (`ok`). -/
def rigStep (st : List Nat × Bool) (x : Nat) : List Nat × Bool :=
  let tbl := st.1
  let y  := x ^^^ lowBit x            -- drop the lowest set bit
  let z  := x ^^^ lowBit y            -- drop the second-lowest instead
  let m  := y &&& z
  let cn := hexes.filter fun a =>
    ham a (tbl.getD y 99) == 1 && ham a (tbl.getD z 99) == 1 && a != tbl.getD m 99
  ((List.range 64).map fun v => if v == x then cn.getD 0 99 else tbl.getD v 99,
   st.2 && (cn.length == 1))

/-- weight-ordered vertices of weight ≥ 2. -/
def wOrder : List Nat :=
  ((List.range 5).flatMap fun w => hexes.filter fun x => pc6 x == w + 2)

/-- seed: identity on 0 and the six weight-1 vertices; 99 (sentinel) elsewhere. -/
def rigSeed : List Nat :=
  (List.range 64).map fun v => if pc6 v ≤ 1 then v else 99

/-- the forced extension: every step has a UNIQUE candidate and the final
    table is the identity — rigidity, computed rather than searched. -/
theorem rigidity_forced_identity :
    (wOrder.foldl rigStep (rigSeed, true)) =
      ((List.range 64).map fun v => v, true) := by decide +kernel

/- ------------------ §6 SC7: partner-commuters = G48, exactly 48 ------------------ -/

/-- the bit-position permutations commuting with the canonical partner involution. -/
def partnerCommuters : List (List Nat) :=
  (perms idp).filter fun p =>
    hexes.all fun h => applyPerm p (partner h) == partner (applyPerm p h)

theorem partnerCommuters_eq_G48 : partnerCommuters = G48 := by decide +kernel

theorem partnerCommuters_card : partnerCommuters.length = 48 := by decide +kernel

end SymmetryCompleteness

/-! ### Axiom audit (added 2026-08-01; expectation updated 2026-08-07)
Emits the trust base for every theorem in this file that is CITED BY NAME in the
public documentation, so the suite's `#print axioms` claims are OBSERVED rather than
statically inferred. Expected: `[propext]` alone for the `decide +kernel` finite
facts, `[propext, Quot.sound]` for the structural psi_comm_perms — Lean's standard
axioms only. Any `Lean.ofReduceBool` here means a `native_decide` (compiler trust)
has crept back in and the docs must say so; since 2026-08-07 this file carries
none. -/
#print axioms SymmetryCompleteness.psi_involution
#print axioms SymmetryCompleteness.psi_g5_iso
#print axioms SymmetryCompleteness.psi_comm_perms
#print axioms SymmetryCompleteness.q6_two_common_neighbors
#print axioms SymmetryCompleteness.rigidity_forced_identity
#print axioms SymmetryCompleteness.partnerCommuters_eq_G48
