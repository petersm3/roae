-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  Automorphism.lean — machine-checked sequence-level symmetry layer (2026-07-05).
  Core Lean 4 only (no mathlib). Formalizes the passage from the finite symmetry
  lemmas of KingWen.lean (sigma_kw_valid_48 / valid_iff_centralizes_rev /
  twins_24_records) to the sequence-level corollary of SYMMETRY_SEARCH.md:

      the 48-element centralizer of bit-reversal (G ≅ B₃ ≅ Z₂ ≀ S₃) preserves the
      C1–C5 constraint system on ALL orderings; its record-level quotient S₄
      (order 24) acts FREELY on canonical solution records; hence

      theorem twenty_four_dvd_solution_count :
        24 ∣ (number of canonical C1–C5 solution records).

  The count is stated over any duplicate-free complete listing of the RECORD-level
  solution set — records = pair-key sequences after orientation dedup, the level of
  KingWen.lean's twins_24_records and of the enumeration's canonical counts (TR-11
  definitions; COUNT_CASCADE_RUNBOOK §1a's DIV-24 gate). The divisibility is also
  instantiated for the exact-count constraint systems C1∩C2∩C4 and C1∩C2∩C4∩C5
  (`twenty_four_dvd_c1c2c4_count`, `twenty_four_dvd_c1c2c4c5_count`); see the scope
  note there on record-level vs orientation-resolved counts.

  Structure:
  (a) finite facts about G48/G24 — ALL kernel-checked since 2026-07-27 (zero
      native_decide in this file; `#print axioms` reports only standard axioms,
      ⊆ [propext, Classical.choice, Quot.sound] — no compiler trust).
      History: most were kernel `decide` from F-52 (2026-07-19); the seven heavy
      ones (applyPerm_inj, applyPerm_isometry, applyPerm_range_perm,
      applyPerm_pcomp, pcomp_closure, pcomp_inv, pcomp_left_cancel) stayed on
      `native_decide` until the 2026-07-27 K-migration. Five of the seven now go
      through by direct `decide +kernel` (measured 41–72 s each on D16).
      applyPerm_isometry — whose ∀-bounded form is kernel-MEMORY-infeasible
      directly (the nested bounded-quantifier Decidable instances exceed
      24–29 GB) — is proved from a Bool `List.all` companion
      (`applyPerm_isometry_bool`, kernel `decide` in bounded memory — the same
      computation shape as KingWen.lean's sigma_kw_valid_48) plus a short
      structural bridge. applyPerm_pcomp — whose 48·48·64 obligation OOMs the
      kernel even in Bool `List.all` shape, and which therefore remained this
      file's one `native_decide` until 2026-07-31 — is now proved STRUCTURALLY
      (§3a): the group-action law needs no enumeration over (p,q) pairs at all,
      only the 48·64·6 bit-relocation fact `applyPerm_bit` (kernel `decide`,
      ~24 s / 2.8 GB) plus list/fold reasoning. All stated ∀-forms are
      unchanged and kernel-only;
  (b) structural invariance proofs: each constraint C1/C2/C3/C4/C5 is preserved by
      every σ ∈ G48 on EVERY permutation of the 64 hexagrams (not just King Wen);
  (c) the record-level action (relabel pair keys) and its compatibility with
      pairKey: canonical(σ·l) = σ·canonical(l);
  (d) freeness: only the identity coset fixes any solution record (a fixing σ must
      stabilize all 32 partner-pairs setwise; only {id, rev} do);
  (e) the orbit-partition counting argument: a free action of a 24-element group
      partitions any complete duplicate-free listing into orbits of size exactly
      24, so 24 divides its length.

  The defs pc6/rev6/partner/ham/transitions/c1ok/c4ok/c5ok/c3x64/c3ok/validC15/
  inserts/perms/applyPerm/pairKey/KW are restated verbatim from KingWen.lean
  (the files are standalone; no lake project).

  Paper proof: documentation/SYMMETRY_SEARCH.md (theorem + 2026-07-03 free-action
  corollary); derivation notes in roae-private (THEOREM_C15_SYMMETRY_GROUP_2026_07,
  LEAN_AUTOMORPHISM_BLUEPRINT).
-/

namespace Automorphism

/- ------------------ §0 defs restated verbatim from KingWen.lean ------------------ -/

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

/-- canonical pair keys (unordered consecutive pairs) — the record-level object. -/
def pairKey (l : List Nat) : List Nat :=
  (List.range 32).map fun i =>
    min (l.getD (2*i) 0) (l.getD (2*i+1) 0) * 64 + max (l.getD (2*i) 0) (l.getD (2*i+1) 0)

/- ------------------ §1 the symmetry group and its record-level action ------------------ -/

/-- the identity bit permutation. -/
def idp : List Nat := [0, 1, 2, 3, 4, 5]

/-- the bit-reversal permutation: applyPerm rho = rev6; the central element of G48,
    acting trivially at record level (it flips every pair's orientation in place). -/
def rho : List Nat := [5, 4, 3, 2, 1, 0]

/-- G48 = the centralizer of bit-reversal among the 720 bit permutations
    (order 48, ≅ B₃ ≅ Z₂ ≀ S₃ — the symmetry group of SYMMETRY_SEARCH.md). -/
def G48 : List (List Nat) :=
  (perms idp).filter fun p =>
    (List.range 64).all fun h => applyPerm p (rev6 h) == rev6 (applyPerm p h)

/-- coset representatives for the record-level quotient S₄ = G48/{id, rho} (order 24):
    pcomp p rho = p.reverse, so each coset is {p, p.reverse}; keep the member whose
    first entry is smaller (first ≠ last for a permutation). -/
def G24 : List (List Nat) := G48.filter fun p => p.getD 0 0 < p.getD 5 0

/-- composition of bit permutations: applyPerm (pcomp p q) = applyPerm p ∘ applyPerm q
    (bit i goes to position q[i], then to p[q[i]]). -/
def pcomp (p q : List Nat) : List Nat := q.map fun j => p.getD j 0

/-- canonical (unordered) key of the pair containing h. -/
def keyOf (h : Nat) : Nat := min h (partner h) * 64 + max h (partner h)

/-- σ's action on one pair key: relabel both members, re-sort. -/
def relabelKey (p : List Nat) (k : Nat) : Nat :=
  min (applyPerm p (k / 64)) (applyPerm p (k % 64)) * 64 +
    max (applyPerm p (k / 64)) (applyPerm p (k % 64))

/-- the record-level action of σ: relabel each pair key. -/
def act (p : List Nat) (r : List Nat) : List Nat := r.map (relabelKey p)

/-- σ stabilizes the pair {h, partner h} setwise. -/
def stabPair (p : List Nat) (h : Nat) : Prop :=
  (applyPerm p h = h ∧ applyPerm p (partner h) = partner h) ∨
  (applyPerm p h = partner h ∧ applyPerm p (partner h) = h)

instance (p : List Nat) (h : Nat) : Decidable (stabPair p h) := by
  unfold stabPair; infer_instance

/-- C2 (no distance-5 transition), restated as a standalone predicate; KingWen.lean
    does not define it separately because C5 implies it — needed here to state the
    divisibility for the exact-count objects |C1∩C2∩C4| and |C1∩C2∩C4∩C5|. -/
def c2ok (l : List Nat) : Bool := ((transitions l).filter (· == 5)).length == 0

/-- a valid ordering under constraint predicate Q: a permutation of the 64
    hexagrams (as a list) passing Q. -/
def ValidSeq (Q : List Nat → Bool) (l : List Nat) : Prop :=
  l.Perm (List.range 64) ∧ Q l = true

/-- r is the canonical record (pair-key sequence) of some valid ordering — the
    counted object of the enumeration / exact-count pipeline. -/
def SolRec (Q : List Nat → Bool) (r : List Nat) : Prop :=
  ∃ l, ValidSeq Q l ∧ pairKey l = r

/-- well-formed pair key: two 6-bit digits in canonical (sorted) order. -/
def WFkey (k : Nat) : Prop := k < 4096 ∧ k / 64 ≤ k % 64

/- ------- §2 finite group facts (kernel `decide` since 2026-07-27; the two
   memory-infeasible ∀-forms go through Bool `List.all` companions — see the
   header note (a). Nothing in this section trusts the compiler.) ------- -/

theorem G48_length : G48.length = 48 := by decide

theorem G24_length : G24.length = 24 := by decide

theorem G24_nodup : G24.Nodup := by decide

theorem idp_mem_G24 : idp ∈ G24 := by decide

theorem rho_mem_G48 : rho ∈ G48 := by decide

theorem G24_sub_G48 : ∀ p ∈ G24, p ∈ G48 := fun _ hp => (List.mem_filter.mp hp).1

theorem applyPerm_lt64 : ∀ p ∈ G48, ∀ h < 64, applyPerm p h < 64 := by decide

theorem applyPerm_inj :
    ∀ p ∈ G48, ∀ a < 64, ∀ b < 64, (applyPerm p a = applyPerm p b ↔ a = b) := by
  decide +kernel

/-- Bool companion of `applyPerm_isometry`: the same fact as a `List.all` fold,
    the one shape whose kernel evaluation stays in bounded memory (direct kernel
    `decide` on the ∀-bounded form needs > 29 GB — see the §2 header note). -/
theorem applyPerm_isometry_bool :
    (G48.all fun p => (List.range 64).all fun a => (List.range 64).all fun b =>
      ham (applyPerm p a) (applyPerm p b) == ham a b) = true := by
  decide +kernel

theorem applyPerm_isometry :
    ∀ p ∈ G48, ∀ a < 64, ∀ b < 64, ham (applyPerm p a) (applyPerm p b) = ham a b := by
  have hb := applyPerm_isometry_bool
  simp only [List.all_eq_true, beq_iff_eq] at hb
  intro p hp a ha b hbb
  exact hb p hp a (List.mem_range.mpr ha) b (List.mem_range.mpr hbb)

theorem applyPerm_fix_0_63 : ∀ p ∈ G48, applyPerm p 0 = 0 ∧ applyPerm p 63 = 63 := by
  decide

theorem applyPerm_partner :
    ∀ p ∈ G48, ∀ h < 64, applyPerm p (partner h) = partner (applyPerm p h) := by
  decide

theorem applyPerm_comp63 :
    ∀ p ∈ G48, ∀ h < 64, applyPerm p h ^^^ 63 = applyPerm p (h ^^^ 63) := by
  decide

theorem applyPerm_range_perm :
    ∀ p ∈ G48, ((List.range 64).map (applyPerm p)).isPerm (List.range 64) = true := by
  decide +kernel

theorem pcomp_closure : ∀ p ∈ G48, ∀ q ∈ G48, pcomp p q ∈ G48 := by decide +kernel

/- `applyPerm_pcomp_bool` / `applyPerm_pcomp` — this file's last `native_decide`
   until 2026-07-31 (the 48·48·64 obligation OOMs kernel `decide` at >29 GB even
   in Bool `List.all` shape) — are now proved structurally in §3a below, after
   the list utilities they depend on (`getD_map`, `sum_perm`). -/

theorem applyPerm_idp : ∀ h < 64, applyPerm idp h = h := by decide

theorem pcomp_inv : ∀ p ∈ G48, ∃ q ∈ G48, pcomp q p = idp ∧ pcomp p q = idp := by
  decide +kernel

theorem pcomp_left_cancel :
    ∀ a ∈ G48, ∀ p ∈ G48, ∀ q ∈ G48, pcomp a p = pcomp a q → p = q := by
  decide +kernel

theorem pcomp_inv_rho :
    ∀ a ∈ G48, ∀ b ∈ G48, pcomp a b = idp → pcomp a (pcomp b rho) = rho := by
  decide

theorem G24_cover : ∀ p ∈ G48, p ∈ G24 ∨ pcomp p rho ∈ G24 := by decide

theorem G24_rho_disjoint : ∀ q ∈ G24, pcomp q rho ∉ G24 := by decide

/-- the freeness engine: an element of G48 stabilizing all 32 partner-pairs setwise
    is the identity or the central bit-reversal — nothing else. -/
theorem stab_all_id_or_rho :
    ∀ p ∈ G48, (∀ h < 64, stabPair p h) → p = idp ∨ p = rho := by decide

theorem rho_stab : ∀ h < 64, stabPair rho h := by decide

theorem partner_involution : ∀ h < 64, partner (partner h) = h ∧ partner h < 64 := by
  decide

theorem xor63_lt64 : ∀ h < 64, h ^^^ 63 < 64 := by decide

/- ------------------ §3 list utilities (core-Lean, no mathlib) ------------------ -/

theorem getD_eq_getElem (l : List Nat) (d : Nat) {i : Nat} (h : i < l.length) :
    l.getD i d = l[i] := by
  simp [List.getD_eq_getElem?_getD, List.getElem?_eq_getElem h]

theorem getD_map (f : Nat → Nat) {l : List Nat} {i : Nat} (hi : i < l.length)
    (d d' : Nat) : (l.map f).getD i d = f (l.getD i d') := by
  have hi' : i < (l.map f).length := by simpa using hi
  rw [getD_eq_getElem _ _ hi', getD_eq_getElem _ _ hi, List.getElem_map]

theorem getD_mem {l : List Nat} {i : Nat} (hi : i < l.length) (d : Nat) :
    l.getD i d ∈ l := by
  rw [getD_eq_getElem _ _ hi]; exact List.getElem_mem hi

theorem findIdx_congr {l : List Nat} {p q : Nat → Bool}
    (h : ∀ x ∈ l, p x = q x) : l.findIdx p = l.findIdx q := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    rw [List.findIdx_cons, List.findIdx_cons, h a (by simp),
        ih (fun x hx => h x (List.mem_cons_of_mem a hx))]

theorem map_eq_self_of {α : Type} {l : List α} {f : α → α}
    (h : ∀ x ∈ l, f x = x) : l.map f = l := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    simp only [List.map_cons, h a (by simp),
      ih (fun x hx => h x (List.mem_cons_of_mem a hx))]

theorem eq_self_of_map_eq {α : Type} {l : List α} {f : α → α}
    (h : l.map f = l) : ∀ x ∈ l, f x = x := by
  induction l with
  | nil => intro x hx; cases hx
  | cons a t ih =>
    simp only [List.map_cons, List.cons.injEq] at h
    intro x hx
    cases List.mem_cons.mp hx with
    | inl he => rw [he]; exact h.1
    | inr ht => exact ih h.2 x ht

theorem nodup_map_on {α β : Type} {l : List α} {f : α → β}
    (hinj : ∀ a ∈ l, ∀ b ∈ l, f a = f b → a = b) (hnd : l.Nodup) :
    (l.map f).Nodup := by
  induction l with
  | nil => exact List.nodup_nil
  | cons a t ih =>
    have hat := List.nodup_cons.mp hnd
    rw [List.map_cons, List.nodup_cons]
    constructor
    · intro hmem
      obtain ⟨b, hb, hfb⟩ := List.mem_map.mp hmem
      have : b = a := hinj b (List.mem_cons_of_mem a hb) a (by simp) hfb
      exact hat.1 (this ▸ hb)
    · exact ih (fun x hx y hy => hinj x (List.mem_cons_of_mem a hx)
        y (List.mem_cons_of_mem a hy)) hat.2

theorem sum_perm {l₁ l₂ : List Nat} (h : l₁.Perm l₂) : l₁.sum = l₂.sum := by
  induction h with
  | nil => rfl
  | cons x _ ih => simp [ih]
  | swap x y l => simp [List.sum_cons]; omega
  | trans _ _ ih₁ ih₂ => omega

theorem countP_not_add {α : Type} (p : α → Bool) (l : List α) :
    l.countP p + l.countP (fun x => !p x) = l.length := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    by_cases h : p a = true
    · rw [List.countP_cons_of_pos h, List.countP_cons_of_neg (by simp [h])]
      simp [← ih]; omega
    · rw [List.countP_cons_of_neg h,
          List.countP_cons_of_pos (p := fun x => !p x) (by simp [h])]
      simp [← ih]; omega

/-- the number of R-members lying in a duplicate-free O ⊆ R is exactly |O|. -/
theorem countP_mem_eq_length {O R : List (List Nat)} (hOnd : O.Nodup)
    (hRnd : R.Nodup) (hsub : ∀ x ∈ O, x ∈ R) :
    R.countP (fun x => O.contains x) = O.length := by
  induction R generalizing O with
  | nil =>
    cases O with
    | nil => rfl
    | cons a t => exact absurd (hsub a (by simp)) (List.not_mem_nil)
  | cons a R0 ih =>
    have haR := List.nodup_cons.mp hRnd
    by_cases ha : a ∈ O
    · rw [List.countP_cons_of_pos (by simpa [List.contains_iff_mem] using ha)]
      have hO' : (O.erase a).Nodup := hOnd.erase a
      have hsub' : ∀ x ∈ O.erase a, x ∈ R0 := by
        intro x hx
        have hxO : x ∈ O := List.mem_of_mem_erase hx
        have hxa : x ≠ a := by
          intro he
          rw [he] at hx
          exact (hOnd.not_mem_erase) hx
        cases List.mem_cons.mp (hsub x hxO) with
        | inl h => exact absurd h hxa
        | inr h => exact h
      have hcong : R0.countP (fun x => O.contains x) =
          R0.countP (fun x => (O.erase a).contains x) := by
        apply List.countP_congr
        intro x hx
        have hxa : x ≠ a := fun he => haR.1 (he ▸ hx)
        simp [List.mem_erase_of_ne hxa]
      rw [hcong, ih hO' haR.2 hsub', List.length_erase_of_mem ha]
      have : 0 < O.length := List.length_pos_of_mem ha
      omega
    · rw [List.countP_cons_of_neg (by simpa [List.contains_iff_mem] using ha)]
      apply ih hOnd haR.2
      intro x hx
      cases List.mem_cons.mp (hsub x hx) with
      | inl h => exact absurd (h ▸ hx) ha
      | inr h => exact h

/- ------- §3a applyPerm_pcomp, structurally (replaces this file's last
   native_decide, 2026-07-31). The composition law is a group-action identity:
   with m := applyPerm q h, both sides equal the length-6 sum
   Σ_i bit_i(h)·2^(p[q[i]]) — the left by definition of pcomp (getD_map), the
   right because q relocates bit k of h to bit position q[k] of m
   (`applyPerm_bit`, the only finite check needed: 48·64·6 cases, kernel
   `decide`) and q permutes the index list [0..5], so Σ_j bit_j(m)·2^(p[j]) is
   the same sum reindexed (`map_getD_range` + `sum_perm`). No enumeration over
   (p,q) pairs occurs; p needs no hypotheses at all. ------- -/

/-- Bool companion of `applyPerm_bit` (kernel `decide`, 48·64·6 = 18432 cases,
    ~24 s / 2.8 GB peak on D4): applying q sends bit k of h to bit position q[k]. -/
theorem applyPerm_bit_bool :
    (G48.all fun q => (List.range 64).all fun h => (List.range 6).all fun k =>
      applyPerm q h / 2^(q.getD k 0) % 2 == h / 2^k % 2) = true := by
  decide +kernel

theorem applyPerm_bit :
    ∀ q ∈ G48, ∀ h < 64, ∀ k < 6,
      applyPerm q h / 2^(q.getD k 0) % 2 = h / 2^k % 2 := by
  have hb := applyPerm_bit_bool
  simp only [List.all_eq_true, beq_iff_eq] at hb
  intro q hq h hh k hk
  exact hb q hq h (List.mem_range.mpr hh) k (List.mem_range.mpr hk)

theorem G48_length6 : ∀ q ∈ G48, q.length = 6 := by decide

theorem G48_isPerm_idp : (G48.all fun q => q.isPerm idp) = true := by decide

/-- reindexing a map over `range l.length` through `getD` is a map over `l`. -/
theorem map_getD_range (F : Nat → Nat) :
    ∀ (q : List Nat), (List.range q.length).map (fun i => F (q.getD i 0)) = q.map F := by
  intro q
  induction q with
  | nil => rfl
  | cons a t ih =>
    rw [List.length_cons, List.range_succ_eq_map, List.map_cons, List.map_map]
    exact congrArg (F a :: ·) (by rw [← ih]; exact List.map_congr_left fun i _ => rfl)

/-- STRUCTURAL composition law: `applyPerm` is an action along `pcomp`. No
    hypotheses on p are needed; q ∈ G48 is used only for q.length = 6, q being
    an index permutation of [0..5], and the bit-relocation fact `applyPerm_bit`. -/
theorem applyPerm_pcomp_struct (p q : List Nat) (hq : q ∈ G48) (h : Nat) (hh : h < 64) :
    applyPerm (pcomp p q) h = applyPerm p (applyPerm q h) := by
  have hq6 : q.length = 6 := G48_length6 q hq
  have hqperm : q.Perm idp := List.isPerm_iff.mp (by
    have hb := G48_isPerm_idp
    simp only [List.all_eq_true] at hb
    exact hb q hq)
  show ((List.range 6).map fun i => h / 2^i % 2 * 2^((pcomp p q).getD i 0)).foldl (·+·) 0
     = ((List.range 6).map fun j => applyPerm q h / 2^j % 2 * 2^(p.getD j 0)).foldl (·+·) 0
  rw [← List.sum_eq_foldl_nat, ← List.sum_eq_foldl_nat]
  have step1 : ((List.range 6).map fun i => h / 2^i % 2 * 2^((pcomp p q).getD i 0))
      = (List.range 6).map fun i =>
          (fun j => applyPerm q h / 2^j % 2 * 2^(p.getD j 0)) (q.getD i 0) := by
    apply List.map_congr_left
    intro i hi
    have hi6 : i < 6 := List.mem_range.mp hi
    have hilen : i < q.length := by omega
    show h / 2^i % 2 * 2^((q.map fun j => p.getD j 0).getD i 0)
       = applyPerm q h / 2^(q.getD i 0) % 2 * 2^(p.getD (q.getD i 0) 0)
    rw [getD_map (fun j => p.getD j 0) hilen 0 0,
        applyPerm_bit q hq h hh i hi6]
  have step2 : ((List.range 6).map fun i =>
      (fun j => applyPerm q h / 2^j % 2 * 2^(p.getD j 0)) (q.getD i 0))
      = q.map (fun j => applyPerm q h / 2^j % 2 * 2^(p.getD j 0)) := by
    have hm := map_getD_range (fun j => applyPerm q h / 2^j % 2 * 2^(p.getD j 0)) q
    rw [hq6] at hm
    exact hm
  rw [step1, step2]
  have hidp : List.range 6 = idp := rfl
  rw [hidp]
  exact sum_perm (hqperm.map _)

/-- Bool companion of `applyPerm_pcomp` — DERIVED from the structural law
    (this was the file's one remaining `native_decide` until 2026-07-31). -/
theorem applyPerm_pcomp_bool :
    (G48.all fun p => G48.all fun q => (List.range 64).all fun h =>
      applyPerm (pcomp p q) h == applyPerm p (applyPerm q h)) = true := by
  simp only [List.all_eq_true, beq_iff_eq]
  intro p _ q hq h hh
  exact applyPerm_pcomp_struct p q hq h (List.mem_range.mp hh)

theorem applyPerm_pcomp :
    ∀ p ∈ G48, ∀ q ∈ G48, ∀ h < 64,
      applyPerm (pcomp p q) h = applyPerm p (applyPerm q h) := by
  have hb := applyPerm_pcomp_bool
  simp only [List.all_eq_true, beq_iff_eq] at hb
  intro p hp q hq h hh
  exact hb p hp q hq h (List.mem_range.mpr hh)

/- ------------------ §4 constraint invariance under G48 (structural) ------------------ -/

/-- bounds and length from the permutation hypothesis. -/
theorem perm_lt64 {l : List Nat} (hp : l.Perm (List.range 64)) : ∀ x ∈ l, x < 64 :=
  fun _ hx => List.mem_range.mp (hp.mem_iff.mp hx)

theorem perm_len64 {l : List Nat} (hp : l.Perm (List.range 64)) : l.length = 64 := by
  simpa using hp.length_eq

theorem perm_mem {l : List Nat} (hp : l.Perm (List.range 64)) {h : Nat}
    (hh : h < 64) : h ∈ l :=
  hp.mem_iff.mpr (List.mem_range.mpr hh)

/-- σ maps a permutation of the hexagrams to a permutation of the hexagrams. -/
theorem mapP_perm (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hl : l.Perm (List.range 64)) : (l.map (applyPerm p)).Perm (List.range 64) :=
  (hl.map (applyPerm p)).trans (List.isPerm_iff.mp (applyPerm_range_perm p hp))

/-- C1 is invariant: σ commutes with the partner map. -/
theorem c1ok_mapP (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hlen : l.length = 64) (hb : ∀ x ∈ l, x < 64) (h1 : c1ok l = true) :
    c1ok (l.map (applyPerm p)) = true := by
  simp only [c1ok, List.all_eq_true, beq_iff_eq] at h1 ⊢
  intro i hi
  have hi32 := List.mem_range.mp hi
  have h2i : 2*i < l.length := by omega
  have h2i1 : 2*i+1 < l.length := by omega
  rw [getD_map (applyPerm p) h2i1 99 99, getD_map (applyPerm p) h2i 99 99,
      h1 i hi, applyPerm_partner p hp _ (hb _ (getD_mem h2i 99))]

/-- C4 is invariant: σ fixes 0 and 63. -/
theorem c4ok_mapP (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hlen : l.length = 64) (h4 : c4ok l = true) :
    c4ok (l.map (applyPerm p)) = true := by
  simp only [c4ok, Bool.and_eq_true, beq_iff_eq] at h4 ⊢
  have h0 : (0:Nat) < l.length := by omega
  have h1 : (1:Nat) < l.length := by omega
  rw [getD_map (applyPerm p) h0 99 99, getD_map (applyPerm p) h1 99 99,
      h4.1, h4.2]
  exact ⟨(applyPerm_fix_0_63 p hp).2, (applyPerm_fix_0_63 p hp).1⟩

/-- the transition list is unchanged by any σ ∈ G48 (Hamming isometry). -/
theorem transitions_mapP (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hb : ∀ x ∈ l, x < 64) :
    transitions (l.map (applyPerm p)) = transitions l := by
  unfold transitions
  rw [← List.map_tail, List.zip_map, List.map_map]
  apply List.map_congr_left
  intro ab hab
  have hmem := List.of_mem_zip hab
  have ha : ab.1 < 64 := hb _ hmem.1
  have hb2 : ab.2 < 64 := hb _ (List.mem_of_mem_tail hmem.2)
  simp [Prod.map, applyPerm_isometry p hp _ ha _ hb2]

/-- C5 is invariant. -/
theorem c5ok_mapP (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hb : ∀ x ∈ l, x < 64) (h5 : c5ok l = true) :
    c5ok (l.map (applyPerm p)) = true := by
  unfold c5ok
  rw [transitions_mapP p hp hb]
  exact h5

/-- C2 is invariant. -/
theorem c2ok_mapP (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hb : ∀ x ∈ l, x < 64) (h2 : c2ok l = true) :
    c2ok (l.map (applyPerm p)) = true := by
  unfold c2ok
  rw [transitions_mapP p hp hb]
  exact h2

/-- position of σh in σ·l = position of h in l. -/
theorem findIdx_mapP (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hb : ∀ x ∈ l, x < 64) {h : Nat} (hh : h < 64) :
    (l.map (applyPerm p)).findIdx (· == applyPerm p h) = l.findIdx (· == h) := by
  rw [List.findIdx_map]
  apply findIdx_congr
  intro x hx
  have hx64 := hb x hx
  simp only [Function.comp]
  rw [Bool.eq_iff_iff]
  simp only [beq_iff_eq]
  exact applyPerm_inj p hp x hx64 h hh

/-- C3's complement-distance sum is exactly preserved: σ commutes with complement,
    so the 64 distance terms are merely reindexed by the bijection h ↦ σh. -/
theorem c3x64_mapP (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hperm : l.Perm (List.range 64)) :
    c3x64 (l.map (applyPerm p)) = c3x64 l := by
  have hb := perm_lt64 hperm
  unfold c3x64
  rw [← List.sum_eq_foldl_nat, ← List.sum_eq_foldl_nat]
  have hpm : ((List.range 64).map (applyPerm p)).Perm (List.range 64) :=
    List.isPerm_iff.mp (applyPerm_range_perm p hp)
  apply Eq.trans (sum_perm (List.Perm.map _ hpm)).symm
  rw [List.map_map]
  apply congrArg
  apply List.map_congr_left
  intro h hh
  have h64 := List.mem_range.mp hh
  simp only [Function.comp]
  rw [findIdx_mapP p hp hb h64,
      applyPerm_comp63 p hp h h64,
      findIdx_mapP p hp hb (xor63_lt64 h h64)]

/-- C3 is invariant. -/
theorem c3ok_mapP (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hperm : l.Perm (List.range 64)) (h3 : c3ok l = true) :
    c3ok (l.map (applyPerm p)) = true := by
  unfold c3ok
  rw [c3x64_mapP p hp hperm]
  exact h3

/-- THE INVARIANCE THEOREM (sequence-level, structural): every σ ∈ G48 maps every
    valid C1–C5 ordering to a valid C1–C5 ordering — the Lean form of the
    SYMMETRY_SEARCH.md theorem, for ALL sequences (not just King Wen). -/
theorem validC15_mapP (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hperm : l.Perm (List.range 64)) (hv : validC15 l = true) :
    validC15 (l.map (applyPerm p)) = true := by
  have hb := perm_lt64 hperm
  have hlen := perm_len64 hperm
  simp only [validC15, Bool.and_eq_true] at hv ⊢
  exact ⟨⟨⟨c1ok_mapP p hp hlen hb hv.1.1.1, c4ok_mapP p hp hlen hv.1.1.2⟩,
    c5ok_mapP p hp hb hv.1.2⟩, c3ok_mapP p hp hperm hv.2⟩

/- ------------------ §5 the record-level action: structure lemmas ------------------ -/

theorem key_digits {a b : Nat} (hb : b < 64) :
    (a * 64 + b) / 64 = a ∧ (a * 64 + b) % 64 = b := by omega

/-- relabeling a sorted-digit key applies σ to both digits and re-sorts. -/
theorem relabelKey_key (p : List Nat) {a b : Nat} (hb : b < 64) :
    relabelKey p (a * 64 + b) =
    min (applyPerm p a) (applyPerm p b) * 64 + max (applyPerm p a) (applyPerm p b) := by
  unfold relabelKey
  rw [(key_digits hb).1, (key_digits hb).2]

/-- relabeling the key of an (unsorted) pair {x, y} = the key of {σx, σy}. -/
theorem relabelKey_pair (p : List Nat) {x y : Nat} (hx : x < 64) (hy : y < 64) :
    relabelKey p (min x y * 64 + max x y) =
    min (applyPerm p x) (applyPerm p y) * 64 + max (applyPerm p x) (applyPerm p y) := by
  rcases Nat.le_total x y with h | h
  · rw [Nat.min_eq_left h, Nat.max_eq_right h, relabelKey_key p hy]
  · rw [Nat.min_eq_right h, Nat.max_eq_left h, relabelKey_key p hx,
        Nat.min_comm, Nat.max_comm]

/-- COMPATIBILITY: canonicalization commutes with the action —
    pairKey (σ·l) = σ·(pairKey l). -/
theorem pairKey_mapP (p : List Nat) {l : List Nat}
    (hlen : l.length = 64) (hb : ∀ x ∈ l, x < 64) :
    pairKey (l.map (applyPerm p)) = act p (pairKey l) := by
  unfold pairKey act
  rw [List.map_map]
  apply List.map_congr_left
  intro i hi
  have hi32 := List.mem_range.mp hi
  have h2i : 2*i < l.length := by omega
  have h2i1 : 2*i+1 < l.length := by omega
  simp only [Function.comp]
  rw [getD_map (applyPerm p) h2i 0 0, getD_map (applyPerm p) h2i1 0 0,
      relabelKey_pair p (hb _ (getD_mem h2i 0)) (hb _ (getD_mem h2i1 0))]

/-- every key of a canonical record is well-formed. -/
theorem pairKey_wf {l : List Nat} (hlen : l.length = 64) (hb : ∀ x ∈ l, x < 64) :
    ∀ k ∈ pairKey l, WFkey k := by
  intro k hk
  obtain ⟨i, hi, rfl⟩ := List.mem_map.mp hk
  have hi32 := List.mem_range.mp hi
  have h2i : 2*i < l.length := by omega
  have h2i1 : 2*i+1 < l.length := by omega
  have ha := hb _ (getD_mem h2i 0)
  have hb2 := hb _ (getD_mem h2i1 0)
  unfold WFkey
  omega

theorem solrec_wf {Q : List Nat → Bool} {r : List Nat} (h : SolRec Q r) :
    ∀ k ∈ r, WFkey k := by
  obtain ⟨l, ⟨hperm, _⟩, rfl⟩ := h
  exact pairKey_wf (perm_len64 hperm) (perm_lt64 hperm)

/-- under C1, every key of a canonical record is the key of some partner-pair. -/
theorem pairKey_keys {l : List Nat} (hlen : l.length = 64) (hb : ∀ x ∈ l, x < 64)
    (h1 : c1ok l = true) : ∀ k ∈ pairKey l, ∃ g, g < 64 ∧ k = keyOf g := by
  intro k hk
  obtain ⟨i, hi, rfl⟩ := List.mem_map.mp hk
  have hi32 := List.mem_range.mp hi
  have h2i : 2*i < l.length := by omega
  have h2i1 : 2*i+1 < l.length := by omega
  simp only [c1ok, List.all_eq_true, beq_iff_eq] at h1
  have hpair := h1 i hi
  rw [getD_eq_getElem l 99 h2i1, getD_eq_getElem l 99 h2i] at hpair
  refine ⟨l[2*i], hb _ (List.getElem_mem h2i), ?_⟩
  rw [getD_eq_getElem l 0 h2i, getD_eq_getElem l 0 h2i1, hpair]
  rfl

/-- under C1 on a permutation of the 64 hexagrams, EVERY partner-pair key occurs
    in the canonical record. -/
theorem pairKey_complete {l : List Nat} (hperm : l.Perm (List.range 64))
    (h1 : c1ok l = true) : ∀ g, g < 64 → keyOf g ∈ pairKey l := by
  intro g hg
  have hb := perm_lt64 hperm
  have hlen := perm_len64 hperm
  obtain ⟨j, hj, hgj⟩ := List.mem_iff_getElem.mp (perm_mem hperm hg)
  have hj64 : j < 64 := by omega
  have hi32 : j / 2 < 32 := by omega
  have h2i : 2*(j/2) < l.length := by omega
  have h2i1 : 2*(j/2)+1 < l.length := by omega
  simp only [c1ok, List.all_eq_true, beq_iff_eq] at h1
  have hc1 := h1 (j/2) (List.mem_range.mpr hi32)
  have e0 : ∀ i, i < l.length → l.getD i 99 = l.getD i 0 := fun i h => by
    rw [getD_eq_getElem l 99 h, getD_eq_getElem l 0 h]
  rw [e0 _ h2i1, e0 _ h2i] at hc1
  have hgd : l.getD j 0 = g := by rw [getD_eq_getElem l 0 hj, hgj]
  apply List.mem_map.mpr
  refine ⟨j/2, List.mem_range.mpr hi32, ?_⟩
  by_cases hpar : j % 2 = 0
  · -- g sits at the even slot: l.getD (2*(j/2)) 0 = g
    have hjj : 2*(j/2) = j := by omega
    have hag : l.getD (2*(j/2)) 0 = g := by rw [hjj]; exact hgd
    rw [hc1, hag]
    rfl
  · -- g sits at the odd slot: g = partner (l.getD (2*(j/2)) 0)
    have hjj : 2*(j/2)+1 = j := by omega
    have hbg : l.getD (2*(j/2)+1) 0 = g := by rw [hjj]; exact hgd
    have ha64 : l.getD (2*(j/2)) 0 < 64 := hb _ (getD_mem h2i 0)
    have hpg : partner g = l.getD (2*(j/2)) 0 := by
      rw [← hbg, hc1]
      exact (partner_involution _ ha64).1
    rw [hbg, ← hpg]
    unfold keyOf
    omega

/-- WF keys are preserved by relabeling. -/
theorem act_wf (p : List Nat) (hp : p ∈ G48) {r : List Nat}
    (hwf : ∀ k ∈ r, WFkey k) : ∀ k ∈ act p r, WFkey k := by
  intro k hk
  obtain ⟨k', hk', rfl⟩ := List.mem_map.mp hk
  have h := hwf k' hk'
  unfold WFkey at h ⊢
  unfold relabelKey
  have f1 := applyPerm_lt64 p hp (k' / 64) (by omega)
  have f2 := applyPerm_lt64 p hp (k' % 64) (by omega)
  omega

/-- the identity acts trivially on well-formed records. -/
theorem act_idp {r : List Nat} (hwf : ∀ k ∈ r, WFkey k) : act idp r = r := by
  apply map_eq_self_of
  intro k hk
  have h := hwf k hk
  unfold WFkey at h
  unfold relabelKey
  rw [applyPerm_idp (k / 64) (by omega), applyPerm_idp (k % 64) (by omega)]
  omega

/-- the action is compatible with composition on well-formed keys. -/
theorem relabelKey_pcomp (p q : List Nat) (hp : p ∈ G48) (hq : q ∈ G48) {k : Nat}
    (hk : WFkey k) : relabelKey (pcomp p q) k = relabelKey p (relabelKey q k) := by
  unfold WFkey at hk
  have ha : k / 64 < 64 := by omega
  have hb : k % 64 < 64 := by omega
  have hqa := applyPerm_lt64 q hq _ ha
  have hqb := applyPerm_lt64 q hq _ hb
  show min (applyPerm (pcomp p q) (k/64)) (applyPerm (pcomp p q) (k%64)) * 64 +
      max (applyPerm (pcomp p q) (k/64)) (applyPerm (pcomp p q) (k%64)) =
      relabelKey p (min (applyPerm q (k/64)) (applyPerm q (k%64)) * 64 +
        max (applyPerm q (k/64)) (applyPerm q (k%64)))
  rw [relabelKey_pair p hqa hqb,
      applyPerm_pcomp p hp q hq _ ha, applyPerm_pcomp p hp q hq _ hb]

theorem act_pcomp (p q : List Nat) (hp : p ∈ G48) (hq : q ∈ G48) {r : List Nat}
    (hwf : ∀ k ∈ r, WFkey k) : act (pcomp p q) r = act p (act q r) := by
  unfold act
  rw [List.map_map]
  apply List.map_congr_left
  intro k hk
  simp only [Function.comp]
  exact relabelKey_pcomp p q hp hq (hwf k hk)

/-- a pair-stabilizing σ fixes the pair's key. -/
theorem relabelKey_keyOf_fix {p : List Nat} {g : Nat} (hg : g < 64)
    (hs : stabPair p g) : relabelKey p (keyOf g) = keyOf g := by
  have hp64 := (partner_involution g hg).2
  unfold keyOf
  rw [relabelKey_pair p hg hp64]
  unfold stabPair at hs
  rcases hs with ⟨e1, e2⟩ | ⟨e1, e2⟩ <;> rw [e1, e2] <;> omega

/-- conversely, fixing a partner-pair's key forces setwise stabilization. -/
theorem stab_of_relabelKey_fix (p : List Nat) (hp : p ∈ G48) {g : Nat} (hg : g < 64)
    (hfix : relabelKey p (keyOf g) = keyOf g) : stabPair p g := by
  have hp64 := (partner_involution g hg).2
  unfold keyOf at hfix
  rw [relabelKey_pair p hg hp64] at hfix
  have fa := applyPerm_lt64 p hp g hg
  have fb := applyPerm_lt64 p hp (partner g) hp64
  unfold stabPair
  rcases Nat.le_total (applyPerm p g) (applyPerm p (partner g)) with h | h
  · omega
  · omega

/-- a σ stabilizing all partner-pairs fixes every solution record pointwise. -/
theorem act_fix_of_stab {p : List Nat} {r : List Nat}
    (hkeys : ∀ k ∈ r, ∃ g, g < 64 ∧ k = keyOf g)
    (hstab : ∀ g, g < 64 → stabPair p g) : act p r = r := by
  apply map_eq_self_of
  intro k hk
  obtain ⟨g, hg, rfl⟩ := hkeys k hk
  exact relabelKey_keyOf_fix hg (hstab g hg)

/-- the central element rho (bit reversal) acts trivially on every solution record —
    the kernel of the record-level action. -/
theorem act_rho_solrec {Q : List Nat → Bool} (hQ1 : ∀ l, Q l = true → c1ok l = true)
    {r : List Nat} (h : SolRec Q r) : act rho r = r := by
  obtain ⟨l, ⟨hperm, hQ⟩, rfl⟩ := h
  exact act_fix_of_stab
    (pairKey_keys (perm_len64 hperm) (perm_lt64 hperm) (hQ1 l hQ))
    rho_stab

/-- FREENESS (sequence-level): an element of G48 fixing ANY solution record is the
    identity or the central bit-reversal — the free-action corollary of
    SYMMETRY_SEARCH.md, for every solution, via stab_all_id_or_rho. -/
theorem act_fix_id_or_rho {Q : List Nat → Bool}
    (hQ1 : ∀ l, Q l = true → c1ok l = true) (p : List Nat) (hp : p ∈ G48)
    {r : List Nat} (h : SolRec Q r) (hfix : act p r = r) : p = idp ∨ p = rho := by
  apply stab_all_id_or_rho p hp
  intro g hg
  obtain ⟨l, ⟨hperm, hQ⟩, rfl⟩ := h
  exact stab_of_relabelKey_fix p hp hg
    (eq_self_of_map_eq hfix _ (pairKey_complete hperm (hQ1 l hQ) g hg))

/-- record-level invariance: the action preserves the solution set. -/
theorem solrec_act {Q : List Nat → Bool}
    (hQinv : ∀ p ∈ G48, ∀ l, l.Perm (List.range 64) → Q l = true →
      Q (l.map (applyPerm p)) = true)
    (p : List Nat) (hp : p ∈ G48) {r : List Nat} (h : SolRec Q r) :
    SolRec Q (act p r) := by
  obtain ⟨l, ⟨hperm, hQ⟩, rfl⟩ := h
  exact ⟨l.map (applyPerm p), ⟨mapP_perm p hp hperm, hQinv p hp l hperm hQ⟩,
    pairKey_mapP p (perm_len64 hperm) (perm_lt64 hperm)⟩

/-- freeness in orbit form: distinct coset representatives move every solution
    record to distinct images. -/
theorem act_inj_G24 {Q : List Nat → Bool}
    (hQ1 : ∀ l, Q l = true → c1ok l = true) {p q : List Nat}
    (hp : p ∈ G24) (hq : q ∈ G24) {r : List Nat} (h : SolRec Q r)
    (heq : act p r = act q r) : p = q := by
  have hp48 := G24_sub_G48 p hp
  have hq48 := G24_sub_G48 q hq
  have hwf := solrec_wf h
  obtain ⟨q', hq'48, hq'l, hq'r⟩ := pcomp_inv q hq48
  have hfix : act (pcomp q' p) r = r := by
    rw [act_pcomp q' p hq'48 hp48 hwf, heq, ← act_pcomp q' q hq'48 hq48 hwf, hq'l,
        act_idp hwf]
  rcases act_fix_id_or_rho hQ1 (pcomp q' p) (pcomp_closure q' hq'48 p hp48) h hfix
    with hu | hu
  · exact pcomp_left_cancel q' hq'48 p hp48 q hq48 (hu.trans hq'l.symm)
  · exfalso
    have hrho : pcomp q' (pcomp q rho) = rho := pcomp_inv_rho q' hq'48 q hq48 hq'l
    have hpq : p = pcomp q rho :=
      pcomp_left_cancel q' hq'48 p hp48 (pcomp q rho)
        (pcomp_closure q hq48 rho rho_mem_G48) (hu.trans hrho.symm)
    exact G24_rho_disjoint q hq (hpq ▸ hp)

/-- any G48-image of a solution record equals some G24-image (coset reduction). -/
theorem orbit_reduce {Q : List Nat → Bool}
    (hQ1 : ∀ l, Q l = true → c1ok l = true) {r : List Nat} (hr : SolRec Q r)
    (w : List Nat) (hw : w ∈ G48) : ∃ v ∈ G24, act w r = act v r := by
  rcases G24_cover w hw with h | h
  · exact ⟨w, h, rfl⟩
  · have heq : act (pcomp w rho) r = act w r := by
      rw [act_pcomp w rho hw rho_mem_G48 (solrec_wf hr), act_rho_solrec hQ1 hr]
    exact ⟨pcomp w rho, h, heq.symm⟩

/- ------------------ §6 orbit partition and the divisibility theorem ------------------ -/

/-- the G24-orbit of a record. -/
def orbitOf (r : List Nat) : List (List Nat) := G24.map (fun p => act p r)

theorem orbit_length (r : List Nat) : (orbitOf r).length = 24 := by
  unfold orbitOf
  rw [List.length_map, G24_length]

theorem orbit_nodup {Q : List Nat → Bool}
    (hQ1 : ∀ l, Q l = true → c1ok l = true) {r : List Nat} (hr : SolRec Q r) :
    (orbitOf r).Nodup :=
  nodup_map_on (fun _ hp _ hq heq => act_inj_G24 hQ1 hp hq hr heq) G24_nodup

/-- a G24-image of a record outside the orbit of r stays outside (orbits are
    equivalence classes): if act p x lands in orbitOf r, then x was in it. -/
theorem mem_orbit_of_act_mem {Q : List Nat → Bool}
    (hQ1 : ∀ l, Q l = true → c1ok l = true) {r x : List Nat}
    (hr : SolRec Q r) (hx : SolRec Q x) {p : List Nat} (hp : p ∈ G24)
    (hmem : act p x ∈ orbitOf r) : x ∈ orbitOf r := by
  obtain ⟨q, hq, heq⟩ := List.mem_map.mp hmem
  have hp48 := G24_sub_G48 p hp
  have hq48 := G24_sub_G48 q hq
  obtain ⟨p', hp'48, hp'l, hp'r⟩ := pcomp_inv p hp48
  have hwfx := solrec_wf hx
  have hx_eq : x = act (pcomp p' q) r := by
    have h1 : act p' (act p x) = x := by
      rw [← act_pcomp p' p hp'48 hp48 hwfx, hp'l, act_idp hwfx]
    rw [← h1, ← heq, ← act_pcomp p' q hp'48 hq48 (solrec_wf hr)]
  obtain ⟨v, hv, hveq⟩ :=
    orbit_reduce hQ1 hr (pcomp p' q) (pcomp_closure p' hp'48 q hq48)
  exact List.mem_map.mpr ⟨v, hv, (hx_eq.trans hveq).symm⟩

/-- the induction engine: any duplicate-free G24-closed list of solution records
    has length divisible by 24 (peel one orbit of exactly 24 per step). -/
theorem dvd24_aux {Q : List Nat → Bool}
    (hQ1 : ∀ l, Q l = true → c1ok l = true) :
    ∀ (n : Nat) (R : List (List Nat)), R.length ≤ n → R.Nodup →
      (∀ r ∈ R, SolRec Q r) → (∀ r ∈ R, ∀ p ∈ G24, act p r ∈ R) →
      24 ∣ R.length := by
  intro n
  induction n with
  | zero =>
    intro R hlen _ _ _
    have h0 : R.length = 0 := by omega
    simp [h0]
  | succ n ih =>
    intro R hlen hnd hsol hcl
    cases R with
    | nil => simp
    | cons r R0 =>
      have hr : SolRec Q r := hsol r (by simp)
      have hOnd : (orbitOf r).Nodup := orbit_nodup hQ1 hr
      have hOsub : ∀ x ∈ orbitOf r, x ∈ r :: R0 := by
        intro x hx
        obtain ⟨p, hp, hpe⟩ := List.mem_map.mp hx
        exact hpe ▸ hcl r (by simp) p hp
      have hcount : (r :: R0).countP (fun x => (orbitOf r).contains x) = 24 := by
        rw [countP_mem_eq_length hOnd hnd hOsub, orbit_length]
      have hsplit := countP_not_add (fun x => (orbitOf r).contains x) (r :: R0)
      have hcle := List.countP_le_length
        (p := fun x => (orbitOf r).contains x) (l := r :: R0)
      have hR'len : ((r :: R0).filter (fun x => !(orbitOf r).contains x)).length =
          (r :: R0).length - 24 := by
        rw [← List.countP_eq_length_filter]
        omega
      have hR'nd : ((r :: R0).filter (fun x => !(orbitOf r).contains x)).Nodup :=
        List.Sublist.nodup List.filter_sublist hnd
      have hR'mem : ∀ x ∈ (r :: R0).filter (fun x => !(orbitOf r).contains x),
          x ∈ (r :: R0) ∧ x ∉ orbitOf r := by
        intro x hx
        have hm := List.mem_filter.mp hx
        refine ⟨hm.1, ?_⟩
        have := hm.2
        simp only [Bool.not_eq_true'] at this
        intro hcon
        rw [List.contains_iff_mem.mpr hcon] at this
        cases this
      have hR'sol : ∀ x ∈ (r :: R0).filter (fun x => !(orbitOf r).contains x),
          SolRec Q x := fun x hx => hsol x (hR'mem x hx).1
      have hR'cl : ∀ x ∈ (r :: R0).filter (fun x => !(orbitOf r).contains x),
          ∀ p ∈ G24, act p x ∈ (r :: R0).filter (fun x => !(orbitOf r).contains x) := by
        intro x hx p hp
        have hxm := hR'mem x hx
        apply List.mem_filter.mpr
        refine ⟨hcl x hxm.1 p hp, ?_⟩
        have hnot : act p x ∉ orbitOf r := fun hcon =>
          hxm.2 (mem_orbit_of_act_mem hQ1 hr (hsol x hxm.1) hp hcon)
        simp [hnot]
      have hR'le : ((r :: R0).filter (fun x => !(orbitOf r).contains x)).length ≤ n := by
        have hl : (r :: R0).length ≤ n + 1 := hlen
        omega
      obtain ⟨m, hm⟩ := ih _ hR'le hR'nd hR'sol hR'cl
      exact ⟨m + 1, by omega⟩

/-- MAIN COUNTING THEOREM (generic): for any constraint predicate Q that includes
    C1 and is invariant under G48, every duplicate-free complete listing of the
    record-level solution set has length divisible by 24. -/
theorem twenty_four_dvd_count {Q : List Nat → Bool}
    (hQ1 : ∀ l, Q l = true → c1ok l = true)
    (hQinv : ∀ p ∈ G48, ∀ l, l.Perm (List.range 64) → Q l = true →
      Q (l.map (applyPerm p)) = true)
    (R : List (List Nat)) (hnd : R.Nodup)
    (hsound : ∀ r ∈ R, SolRec Q r)
    (hcomplete : ∀ r, SolRec Q r → r ∈ R) :
    24 ∣ R.length :=
  dvd24_aux hQ1 R.length R (Nat.le_refl _) hnd hsound
    (fun r hr p hp => hcomplete _ (solrec_act hQinv p (G24_sub_G48 p hp) (hsound r hr)))

/- ------------------ §7 the divisibility corollaries ------------------ -/

/-- THE SEQUENCE-LEVEL SYMMETRY COROLLARY, machine-checked: 24 divides the number
    of canonical C1–C5 solution records. Stated over any duplicate-free listing R
    that is sound (every member is the canonical record of a valid C1–C5 ordering)
    and complete (every such record is listed) — i.e., |R| = the solution count.
    This is the theorem behind the DIV-24 integrity gate on exact counts. -/
theorem twenty_four_dvd_solution_count (R : List (List Nat)) (hnd : R.Nodup)
    (hsound : ∀ r ∈ R, SolRec validC15 r)
    (hcomplete : ∀ r, SolRec validC15 r → r ∈ R) :
    24 ∣ R.length := by
  refine twenty_four_dvd_count ?h1 ?hinv R hnd hsound hcomplete
  case h1 =>
    intro l hv
    simp only [validC15, Bool.and_eq_true] at hv
    exact hv.1.1.1
  case hinv => exact fun p hp l hperm hv => validC15_mapP p hp hperm hv

/-- the |C1∩C2∩C4| constraint predicate — the system counted exactly by the
    orbit-DP (TR-11's 42-digit integer). -/
def validC124 (l : List Nat) : Bool := c1ok l && c2ok l && c4ok l

theorem validC124_mapP (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hperm : l.Perm (List.range 64)) (hv : validC124 l = true) :
    validC124 (l.map (applyPerm p)) = true := by
  have hb := perm_lt64 hperm
  have hlen := perm_len64 hperm
  simp only [validC124, Bool.and_eq_true] at hv ⊢
  exact ⟨⟨c1ok_mapP p hp hlen hb hv.1.1, c2ok_mapP p hp hb hv.1.2⟩,
    c4ok_mapP p hp hlen hv.2⟩

/-- 24 divides the record-level count of C1∩C2∩C4 solutions. (Scope note: the
    orbit-DP's 42-digit N = 757,058,601,340,255,440,651,419,713,405,330,315,358,208
    counts orientation-resolved sequences of this same system; its own mod-24
    congruence follows from the identical orbit argument applied to the full
    48-element group — freeness there is immediate, since a sequence-fixing σ fixes
    all 64 hexagram values pointwise. That raw-sequence layer is paper-proved in
    SYMMETRY_SEARCH.md and not duplicated here; this theorem pins the record-level
    layer, where the collapse is to 24 (rho acts trivially). -/
theorem twenty_four_dvd_c1c2c4_count (R : List (List Nat)) (hnd : R.Nodup)
    (hsound : ∀ r ∈ R, SolRec validC124 r)
    (hcomplete : ∀ r, SolRec validC124 r → r ∈ R) :
    24 ∣ R.length := by
  refine twenty_four_dvd_count ?h1 ?hinv R hnd hsound hcomplete
  case h1 =>
    intro l hv
    simp only [validC124, Bool.and_eq_true] at hv
    exact hv.1.1
  case hinv => exact fun p hp l hperm hv => validC124_mapP p hp hperm hv

/-- the |C1∩C2∩C4∩C5| constraint predicate — the system of the C5-tracked exact
    count (the DIV-24 integrity gate's target). -/
def validC1245 (l : List Nat) : Bool := c1ok l && c2ok l && c4ok l && c5ok l

theorem validC1245_mapP (p : List Nat) (hp : p ∈ G48) {l : List Nat}
    (hperm : l.Perm (List.range 64)) (hv : validC1245 l = true) :
    validC1245 (l.map (applyPerm p)) = true := by
  have hb := perm_lt64 hperm
  have hlen := perm_len64 hperm
  simp only [validC1245, Bool.and_eq_true] at hv ⊢
  exact ⟨⟨⟨c1ok_mapP p hp hlen hb hv.1.1.1, c2ok_mapP p hp hb hv.1.1.2⟩,
    c4ok_mapP p hp hlen hv.1.2⟩, c5ok_mapP p hp hb hv.2⟩

/-- 24 divides the record-level count of C1∩C2∩C4∩C5 solutions — the DIV-24 gate
    for the C5-tracked exact count (same record/raw scope note as above). -/
theorem twenty_four_dvd_c1c2c4c5_count (R : List (List Nat)) (hnd : R.Nodup)
    (hsound : ∀ r ∈ R, SolRec validC1245 r)
    (hcomplete : ∀ r, SolRec validC1245 r → r ∈ R) :
    24 ∣ R.length := by
  refine twenty_four_dvd_count ?h1 ?hinv R hnd hsound hcomplete
  case h1 =>
    intro l hv
    simp only [validC1245, Bool.and_eq_true] at hv
    exact hv.1.1.1
  case hinv => exact fun p hp l hperm hv => validC1245_mapP p hp hperm hv

/-- sanity witness: the solution set is nonempty — King Wen's canonical record is
    a solution record (so the count is a positive multiple of 24). -/
theorem kw_solution_record : SolRec validC15 (pairKey KW) :=
  ⟨KW, ⟨List.isPerm_iff.mp (by decide), by decide⟩, rfl⟩

end Automorphism

#print axioms Automorphism.applyPerm_bit_bool
#print axioms Automorphism.applyPerm_pcomp_bool
#print axioms Automorphism.applyPerm_pcomp
#print axioms Automorphism.twenty_four_dvd_count
#print axioms Automorphism.twenty_four_dvd_solution_count
#print axioms Automorphism.twenty_four_dvd_c1c2c4_count
#print axioms Automorphism.twenty_four_dvd_c1c2c4c5_count
#print axioms Automorphism.kw_solution_record
