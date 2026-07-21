-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  C3Decomposition.lean — machine-checked C3 slot-decomposition theorem (2026-07-04).
  Core Lean 4 only (no mathlib). Formalizes the mini-theorem discovered during the
  native-C3 CNF encoding work (#210) and asserted-at-import in sat.py's "C3 static
  facts" section: for EVERY C1-valid ordering l of the 64 hexagrams,

      c3x64 l  =  Σ_h |pos(h) − pos(h ⊕ 63)|  =  16 + 8 · Σ_{couples} |slot(u) − slot(v)|

  where the sum runs over the 12 cross complement-couples of the canonical pairing
  and slot(h) = pos(h) / 2 is the pair-slot index. Content:
  (a) the canonical 32-pair partition is closed under complement and splits into
      8 self-complement pairs (partner h = h ⊕ 63) and 12 cross-couples of two
      distinct pairs (`pairs_partition`, `selfReps`/`crossReps`);
  (b) each self-complement pair contributes exactly 2 (its two members sit in
      adjacent positions 2s, 2s+1), giving the constant 8 · 2 = 16 (`self_couple_sum`);
  (c) each cross-couple's four hexagram-level distances collapse to 8 · |slot(u) −
      slot(v)| INDEPENDENT of the two pairs' orientations — the orientation bits
      cancel because |2s+e₁ − (2t+e₂)| + |2s+(1−e₁) − (2t+(1−e₂))| = 4|s − t|
      whenever s ≠ t (`quad_collapse`, `cross_couple_sum`).
  Main theorem: `c3_slot_decomposition`. Orientation-independence is manifest in the
  statement (the right side mentions only slots) and is pinned down separately by
  `slot_orientation_free` (a hexagram and its pair-partner share a slot).

  The defs pc6/rev6/partner/c1ok/c3x64/KW are restated verbatim from KingWen.lean
  (the files are standalone; no lake project). This theorem is the soundness core of
  sat.py's --with-c3 CNF encoding: bounding the couple slot-distance sum S bounds
  C3 = 16 + 8·S exactly.

  Added 2026-07-21 — G48 COUPLE-INVARIANCE (final section): the 48-element symmetry
  group (Automorphism.lean's G48, restated verbatim) commutes with complement and
  with the pairing, maps each cross-couple onto a cross-couple (`g48_couple_image`),
  and permutes the 12 canonical couple representatives (`g48_couples_to_couples`) —
  the kernel-checked core of the fact that the couple slot-distance sum (hence C3)
  is invariant under the group, i.e. that TR-11's symmetry quotient carries over to
  the C3/G channel unchanged.
-/

namespace C3Decomposition

/- ------------------ defs restated verbatim from KingWen.lean ------------------ -/

/-- popcount for 6-bit values (total, no recursion needed). -/
def pc6 (n : Nat) : Nat :=
  n % 2 + n / 2 % 2 + n / 4 % 2 + n / 8 % 2 + n / 16 % 2 + n / 32 % 2

/-- 6-bit reversal. -/
def rev6 (n : Nat) : Nat :=
  n % 2 * 32 + n / 2 % 2 * 16 + n / 4 % 2 * 8 + n / 8 % 2 * 4 + n / 16 % 2 * 2 + n / 32 % 2

/-- canonical partner: reversal, or complement for palindromes. -/
def partner (h : Nat) : Nat := if rev6 h = h then h ^^^ 63 else rev6 h

/-- C1: consecutive pairing by partner. -/
def c1ok (l : List Nat) : Bool :=
  ((List.range 32).all fun i => l.getD (2*i+1) 99 == partner (l.getD (2*i) 99))

/-- x64 complement-distance sum: Σ_h |pos(h) − pos(comp h)|. -/
def c3x64 (l : List Nat) : Nat :=
  ((List.range 64).map fun h =>
    let a := l.findIdx (· == h); let b := l.findIdx (· == (h ^^^ 63))
    max a b - min a b).foldl (·+·) 0

def KW : List Nat :=
  [63,  0, 17, 34, 23, 58,  2, 16, 55, 59,  7, 56, 61, 47,  4,  8,
   25, 38,  3, 48, 41, 37, 32,  1, 57, 39, 33, 30, 18, 45, 28, 14,
   60, 15, 40,  5, 53, 43, 20, 10, 35, 49, 31, 62, 24,  6, 26, 22,
   29, 46,  9, 36, 52, 11, 13, 44, 54, 27, 50, 19, 51, 12, 21, 42]

/- ------------------ slot-model definitions ------------------ -/

/-- position of hexagram h in ordering l (first index; unique when l is a permutation). -/
def pos (l : List Nat) (h : Nat) : Nat := l.findIdx (· == h)

/-- pair-slot of hexagram h: positions 2s and 2s+1 form slot s. -/
def slot (l : List Nat) (h : Nat) : Nat := pos l h / 2

/-- |a − b| on Nat. -/
def ndist (a b : Nat) : Nat := max a b - min a b

/-- the C3 term of a single hexagram: |pos(h) − pos(h ⊕ 63)|. -/
def cdist (l : List Nat) (h : Nat) : Nat := ndist (pos l h) (pos l (h ^^^ 63))

/-- slot distance between two hexagrams' pairs. -/
def sdist (l : List Nat) (a b : Nat) : Nat := ndist (slot l a) (slot l b)

/-- the other position inside the same slot: 2s ↔ 2s+1. -/
def flip (j : Nat) : Nat := if j % 2 = 0 then j + 1 else j - 1

/-- representatives (min member) of the 8 self-complement pairs: partner r = r ⊕ 63. -/
def selfReps : List Nat := [0, 7, 11, 12, 18, 21, 25, 30]

/-- representatives (min of the 4-element union) of the 12 cross complement-couples:
    pair {r, partner r} and its complement pair {r ⊕ 63, partner r ⊕ 63} are distinct. -/
def crossReps : List Nat := [1, 2, 3, 4, 5, 6, 9, 10, 13, 14, 17, 22]

/-- the couple slot-distance sum S — the quantity sat.py's CNF bounds with a
    sequential counter. -/
def c3slot (l : List Nat) : Nat := (crossReps.map fun r => sdist l r (r ^^^ 63)).sum

/- ------------------ finite facts (kernel decide) ------------------ -/

theorem partner_lt64 : ∀ h < 64, partner h < 64 := by decide

theorem partner_partner : ∀ h < 64, partner (partner h) = h := by decide

theorem partner_comp_comm : ∀ h < 64, partner (h ^^^ 63) = partner h ^^^ 63 := by decide

theorem comp_lt64 : ∀ h < 64, h ^^^ 63 < 64 := by decide

theorem comp_comp : ∀ h < 64, (h ^^^ 63) ^^^ 63 = h := by decide

theorem comp_ne_self : ∀ h < 64, h ^^^ 63 ≠ h := by decide

/-- (a) THE PARTITION: the 12 cross-couples (4 hexagrams each) and the 8
    self-complement pairs (2 hexagrams each) exactly partition the 64 hexagrams. -/
theorem pairs_partition :
    (List.range 64).Perm
      ((crossReps.flatMap fun r => [r, partner r, r ^^^ 63, partner r ^^^ 63]) ++
       (selfReps.flatMap fun r => [r, partner r])) := by decide

theorem selfReps_spec : ∀ r ∈ selfReps, r < 64 ∧ partner r = r ^^^ 63 := by decide

theorem crossReps_spec : ∀ r ∈ crossReps, r < 64 ∧ partner r ≠ r ^^^ 63 := by decide

theorem selfReps_count : selfReps.length = 8 := rfl
theorem crossReps_count : crossReps.length = 12 := rfl

/-- flip stays inside the slot. -/
theorem flip_half : ∀ j < 64, flip j / 2 = j / 2 := by decide

/-- the two positions of one slot are at distance 1. -/
theorem ndist_flip : ∀ j < 64, ndist j (flip j) = 1 := by decide

/-- same slot + different position forces the flip. -/
theorem same_slot_flip : ∀ j < 64, ∀ k < 64, j / 2 = k / 2 → j ≠ k → k = flip j := by decide

/-- (c) THE ORIENTATION-CANCELLATION IDENTITY: for positions in distinct slots, the
    within-couple pair of hexagram-level distances collapses to 4 · (slot distance),
    independent of which member sits first in each slot. -/
theorem quad_collapse : ∀ j < 64, ∀ k < 64, j / 2 ≠ k / 2 →
    ndist j k + ndist (flip j) (flip k) = 4 * ndist (j / 2) (k / 2) := by decide

theorem ndist_comm (a b : Nat) : ndist a b = ndist b a := by
  simp only [ndist]; omega

/- ------------------ structural lemmas (arbitrary C1-valid permutations) ------------------ -/

/-- foldl-add is sum with an offset (bridges c3x64's foldl to List.sum). -/
theorem foldl_add_eq_sum (L : List Nat) (n : Nat) : L.foldl (·+·) n = n + L.sum := by
  induction L generalizing n with
  | nil => simp
  | cons a t ih => simp only [List.foldl_cons, List.sum_cons, ih]; omega

theorem c3x64_eq_sum (l : List Nat) : c3x64 l = ((List.range 64).map (cdist l)).sum := by
  show ((List.range 64).map (cdist l)).foldl (·+·) 0 = _
  rw [foldl_add_eq_sum]; omega

/-- sum of a map over a flatMap regroups as a sum of block-sums. -/
theorem sum_map_flatMap (g : Nat → List Nat) (f : Nat → Nat) (rs : List Nat) :
    ((rs.flatMap g).map f).sum = (rs.map fun r => ((g r).map f).sum).sum := by
  induction rs with
  | nil => rfl
  | cons a t ih => simp [List.flatMap_cons, List.map_append, List.sum_append, ih]

theorem sum_map_mul_left (c : Nat) (g : Nat → Nat) (rs : List Nat) :
    (rs.map fun r => c * g r).sum = c * (rs.map g).sum := by
  induction rs with
  | nil => rfl
  | cons a t ih => simp [List.sum_cons, ih, Nat.mul_add]

section Structural

variable {l : List Nat}

/-- basic position facts for a permutation of range 64. -/
theorem pos_lt64 (hp : l.Perm (List.range 64)) {h : Nat} (hh : h < 64) : pos l h < 64 := by
  have hm : h ∈ l := hp.mem_iff.mpr (List.mem_range.mpr hh)
  have := List.findIdx_lt_length_of_exists (p := (· == h)) ⟨h, hm, by simp⟩
  simpa [pos, hp.length_eq] using this

/-- the ordering holds h at position pos l h. -/
theorem getD_pos (hp : l.Perm (List.range 64)) {h : Nat} (hh : h < 64) :
    l.getD (pos l h) 0 = h := by
  have hm : h ∈ l := hp.mem_iff.mpr (List.mem_range.mpr hh)
  have hw : l.findIdx (· == h) < l.length :=
    List.findIdx_lt_length_of_exists ⟨h, hm, by simp⟩
  have hbeq := List.findIdx_getElem (w := hw)
  simp only [beq_iff_eq] at hbeq
  simp [pos, List.getD, List.getElem?_eq_getElem hw, hbeq]

/-- positions are unique (l is duplicate-free). -/
theorem pos_unique (hp : l.Perm (List.range 64)) {h i : Nat} (hi : i < 64)
    (hv : l.getD i 0 = h) : pos l h = i := by
  have hlen : l.length = 64 := by simpa using hp.length_eq
  have hil : i < l.length := by omega
  have hgi : l[i] = h := by
    simpa [List.getD, List.getElem?_eq_getElem hil] using hv
  have hh : h < 64 := by
    have hm : l[i] ∈ l := List.getElem_mem hil
    rw [hgi] at hm
    exact List.mem_range.mp (hp.mem_iff.mp hm)
  have hpl : pos l h < l.length := by rw [hlen]; exact pos_lt64 hp hh
  have hgp : l[pos l h] = h := by
    have := getD_pos hp hh
    simpa [List.getD, List.getElem?_eq_getElem hpl] using this
  have hnd : l.Nodup := hp.nodup_iff.mpr (List.nodup_range)
  exact (List.getElem_inj hnd).mp (hgp.trans hgi.symm)

/-- every entry of l is a 6-bit value. -/
theorem getD_lt64 (hp : l.Perm (List.range 64)) {j : Nat} (hj : j < 64) : l.getD j 0 < 64 := by
  have hlen : l.length = 64 := by simpa using hp.length_eq
  have hjl : j < l.length := by omega
  have he : l.getD j 0 = l[j] := by simp [List.getD, List.getElem?_eq_getElem hjl]
  rw [he]
  exact List.mem_range.mp (hp.mem_iff.mp (List.getElem_mem hjl))

/-- C1 digested to positions: the odd position of each slot holds the partner
    of its even position. -/
theorem c1_getD (hp : l.Perm (List.range 64)) (h1 : c1ok l = true) {i : Nat} (hi : i < 32) :
    l.getD (2*i+1) 0 = partner (l.getD (2*i) 0) := by
  have hlen : l.length = 64 := by simpa using hp.length_eq
  simp only [c1ok, List.all_eq_true, beq_iff_eq] at h1
  have h2i : 2*i < l.length := by omega
  have h2i1 : 2*i+1 < l.length := by omega
  have e1 : l.getD (2*i+1) 99 = l.getD (2*i+1) 0 := by
    simp [List.getD, List.getElem?_eq_getElem h2i1]
  have e2 : l.getD (2*i) 99 = l.getD (2*i) 0 := by
    simp [List.getD, List.getElem?_eq_getElem h2i]
  have := h1 i (List.mem_range.mpr hi)
  rw [e1, e2] at this; exact this

/-- THE PAIRING LEMMA: in a C1-valid permutation, a hexagram's pair-partner sits at
    the flipped position of the same slot — whichever orientation the pair took. -/
theorem pos_partner (hp : l.Perm (List.range 64)) (h1 : c1ok l = true) {h : Nat}
    (hh : h < 64) : pos l (partner h) = flip (pos l h) := by
  have hj : pos l h < 64 := pos_lt64 hp hh
  have hgd : l.getD (pos l h) 0 = h := getD_pos hp hh
  by_cases hpar : pos l h % 2 = 0
  · -- h sits first in its slot: partner is one to the right
    have hi : pos l h / 2 < 32 := by omega
    have he : 2 * (pos l h / 2) = pos l h := by omega
    have hc1 := c1_getD hp h1 hi
    rw [he, hgd] at hc1
    have := pos_unique hp (i := pos l h + 1) (by omega) hc1
    rw [this]
    simp [flip, hpar]
  · -- h sits second in its slot: partner is one to the left
    have hi : pos l h / 2 < 32 := by omega
    have he : 2 * (pos l h / 2) + 1 = pos l h := by omega
    have hc1 := c1_getD hp h1 hi
    rw [he, hgd] at hc1
    have hx : l.getD (2 * (pos l h / 2)) 0 < 64 := getD_lt64 hp (by omega)
    have hph := congrArg partner hc1
    rw [partner_partner _ hx] at hph
    have := pos_unique hp (i := 2 * (pos l h / 2)) (by omega) hph.symm
    rw [this]
    simp only [flip, if_neg hpar]
    omega

/-- slots are a pair-level (orientation-free) quantity: h and partner h share a slot. -/
theorem slot_orientation_free (hp : l.Perm (List.range 64)) (h1 : c1ok l = true) {h : Nat}
    (hh : h < 64) : slot l (partner h) = slot l h := by
  simp only [slot]
  rw [pos_partner hp h1 hh]
  exact flip_half _ (pos_lt64 hp hh)

/-- a cross-couple's two pairs occupy distinct slots. -/
theorem slot_ne (hp : l.Perm (List.range 64)) (h1 : c1ok l = true) {h : Nat}
    (hh : h < 64) (hc : partner h ≠ h ^^^ 63) :
    pos l h / 2 ≠ pos l (h ^^^ 63) / 2 := by
  intro heq
  have hcomp : h ^^^ 63 < 64 := comp_lt64 h hh
  have hj := pos_lt64 hp hh
  have hk := pos_lt64 hp hcomp
  have hne : pos l h ≠ pos l (h ^^^ 63) := by
    intro he
    have hd := getD_pos hp hcomp
    rw [← he, getD_pos hp hh] at hd
    exact comp_ne_self h hh hd.symm
  have hkflip : pos l (h ^^^ 63) = flip (pos l h) := same_slot_flip _ hj _ hk heq hne
  apply hc
  have e1 : l.getD (pos l (partner h)) 0 = partner h := getD_pos hp (partner_lt64 h hh)
  rw [pos_partner hp h1 hh, ← hkflip, getD_pos hp hcomp] at e1
  exact e1.symm

/-- (c) for a cross-couple: the four hexagram-level C3 terms of {h, partner h,
    h ⊕ 63, partner h ⊕ 63} collapse to 8 · (slot distance), orientation-free. -/
theorem quad_sum (hp : l.Perm (List.range 64)) (h1 : c1ok l = true) {h : Nat}
    (hh : h < 64) (hc : partner h ≠ h ^^^ 63) :
    cdist l h + cdist l (partner h) + cdist l (h ^^^ 63) + cdist l (partner h ^^^ 63)
      = 8 * sdist l h (h ^^^ 63) := by
  have hcomp : h ^^^ 63 < 64 := comp_lt64 h hh
  have hj := pos_lt64 hp hh
  have hk := pos_lt64 hp hcomp
  have hcol := quad_collapse _ hj _ hk (slot_ne hp h1 hh hc)
  have e1 : cdist l h = ndist (pos l h) (pos l (h ^^^ 63)) := rfl
  have e2 : cdist l (h ^^^ 63) = ndist (pos l h) (pos l (h ^^^ 63)) := by
    simp only [cdist]
    rw [comp_comp h hh]
    exact ndist_comm _ _
  have e3 : cdist l (partner h) = ndist (flip (pos l h)) (flip (pos l (h ^^^ 63))) := by
    simp only [cdist]
    rw [show partner h ^^^ 63 = partner (h ^^^ 63) from (partner_comp_comm h hh).symm,
        pos_partner hp h1 hh, pos_partner hp h1 hcomp]
  have e4 : cdist l (partner h ^^^ 63) = ndist (flip (pos l h)) (flip (pos l (h ^^^ 63))) := by
    simp only [cdist]
    rw [comp_comp _ (partner_lt64 h hh),
        show partner h ^^^ 63 = partner (h ^^^ 63) from (partner_comp_comm h hh).symm,
        pos_partner hp h1 hh, pos_partner hp h1 hcomp]
    exact ndist_comm _ _
  have es : sdist l h (h ^^^ 63) = ndist (pos l h / 2) (pos l (h ^^^ 63) / 2) := rfl
  rw [e1, e2, e3, e4, es]
  omega

/-- (b) for a self-complement pair: the two hexagram-level C3 terms sum to 2
    (the members are mutual complements sitting in adjacent positions). -/
theorem self_sum (hp : l.Perm (List.range 64)) (h1 : c1ok l = true) {h : Nat}
    (hh : h < 64) (hc : partner h = h ^^^ 63) :
    cdist l h + cdist l (partner h) = 2 := by
  have hj := pos_lt64 hp hh
  have e1 : cdist l h = 1 := by
    simp only [cdist]
    rw [← hc, pos_partner hp h1 hh]
    exact ndist_flip _ hj
  have e2 : cdist l (partner h) = 1 := by
    simp only [cdist]
    rw [show partner h ^^^ 63 = h from by rw [hc, comp_comp h hh],
        pos_partner hp h1 hh, ndist_comm]
    exact ndist_flip _ hj
  omega

end Structural

/- ------------------ THE THEOREM ------------------ -/

/-- C3 SLOT DECOMPOSITION: for EVERY C1-valid ordering of the 64 hexagrams, the total
    complement distance Σ_h |pos(h) − pos(h ⊕ 63)| equals 16 + 8 · Σ over the 12 cross
    complement-couples of |slot(u) − slot(v)| — independent of pair orientations and of
    which member of each couple is taken as representative. This is the identity
    asserted-at-import in sat.py (C3 static facts) and the soundness core of its
    --with-c3 CNF encoding. -/
theorem c3_slot_decomposition (l : List Nat) (hp : l.Perm (List.range 64))
    (h1 : c1ok l = true) : c3x64 l = 16 + 8 * c3slot l := by
  have hsum := List.Perm.sum_nat (pairs_partition.map (cdist l))
  rw [c3x64_eq_sum, hsum, List.map_append, List.sum_append, sum_map_flatMap, sum_map_flatMap]
  have hcross : (crossReps.map fun r =>
        (([r, partner r, r ^^^ 63, partner r ^^^ 63]).map (cdist l)).sum)
      = crossReps.map fun r => 8 * sdist l r (r ^^^ 63) := by
    apply List.map_eq_map_iff.mpr
    intro r hr
    obtain ⟨hr64, hrc⟩ := crossReps_spec r hr
    have := quad_sum hp h1 hr64 hrc
    simp only [List.map_cons, List.map_nil, List.sum_cons, List.sum_nil]
    omega
  have hself : (selfReps.map fun r => (([r, partner r]).map (cdist l)).sum)
      = selfReps.map fun _ => 2 := by
    apply List.map_eq_map_iff.mpr
    intro r hr
    obtain ⟨hr64, hrc⟩ := selfReps_spec r hr
    have := self_sum hp h1 hr64 hrc
    simp only [List.map_cons, List.map_nil, List.sum_cons, List.sum_nil]
    omega
  rw [hcross, hself, sum_map_mul_left]
  have hconst : (selfReps.map fun _ => 2).sum = 16 := rfl
  rw [hconst]
  simp only [c3slot]
  omega

/- ------------------ consistency corollaries ------------------ -/

theorem kw_perm : KW.Perm (List.range 64) := by decide

theorem kw_c1 : c1ok KW = true := by decide

/-- King Wen's couple slot-distance sum is 95. -/
theorem kw_slot_sum_95 : c3slot KW = 95 := by decide

/-- cross-check against KingWen.lean's `kw_c3_exactly_776`, now derived from the
    decomposition: 776 = 16 + 8 · 95. -/
theorem kw_c3_776_via_decomposition : c3x64 KW = 776 := by
  rw [c3_slot_decomposition KW kw_perm kw_c1, kw_slot_sum_95]

/- ------------------ G48 couple-invariance (added 2026-07-21) ------------------
   The 48-element symmetry group (the centralizer of bit-reversal among the 720
   bit-position permutations — Automorphism.lean's G48, restated verbatim below;
   the C1–C5 automorphism group of TR-5) maps the 12 cross complement-couples to
   cross complement-couples. This is the finite fact behind the G48-invariance of
   the couple slot-distance sum c3slot: relabeling an ordering by a group element
   permutes hexagram VALUES only — the pair blocks keep their slots — while (by
   `g48_couples_to_couples`) the 12 couples are permuted among themselves, so the
   relabeled ordering sums the same 12 slot gaps and c3slot (hence, via
   `c3_slot_decomposition`, the full C3 sum) is unchanged. Discharges in Lean the
   couples-to-couples check previously done numerically (2026-07-21, all 48
   elements) — the carry-over of TR-11's symmetry quotient to the C3/G channel. -/

/-- all permutations of a list (insertion-based; 720 elements for 6 positions);
    restated verbatim from Automorphism.lean. -/
def inserts (x : Nat) : List Nat → List (List Nat)
  | [] => [[x]]
  | y :: ys => (x :: y :: ys) :: (inserts x ys).map (y :: ·)

def perms : List Nat → List (List Nat)
  | [] => [[]]
  | x :: xs => (perms xs).flatMap (inserts x)

/-- apply a bit-position permutation p (bit i of n goes to position p[i]);
    restated verbatim from Automorphism.lean. -/
def applyPerm (p : List Nat) (n : Nat) : Nat :=
  ((List.range 6).map fun i => n / (2^i) % 2 * 2^(p.getD i 0)).foldl (·+·) 0

/-- the identity bit permutation. -/
def idp : List Nat := [0, 1, 2, 3, 4, 5]

/-- G48 = the centralizer of bit-reversal among the 720 bit permutations (order 48,
    ≅ B₃ ≅ Z₂ ≀ S₃); restated verbatim from Automorphism.lean. -/
def G48 : List (List Nat) :=
  (perms idp).filter fun p =>
    (List.range 64).all fun h => applyPerm p (rev6 h) == rev6 (applyPerm p h)

/-- the complement-couple through h, as a 4-element list: h's pair and its
    complement pair. -/
def coupleOf (h : Nat) : List Nat := [h, partner h, h ^^^ 63, partner h ^^^ 63]

/-- canonical representative of h's couple: its least member. -/
def coupleMin (h : Nat) : Nat :=
  min (min h (partner h)) (min (h ^^^ 63) (partner h ^^^ 63))

theorem g48_length : G48.length = 48 := by decide

/-- crossReps are exactly the canonical representatives of their couples. -/
theorem crossReps_canonical : ∀ r ∈ crossReps, coupleMin r = r := by decide

/-- every group element commutes with complement (a bit-position permutation
    permutes the six ⊕-flipped bits of the all-ones mask). -/
theorem g48_comp_comm :
    ∀ p ∈ G48, ∀ h < 64, applyPerm p (h ^^^ 63) = applyPerm p h ^^^ 63 := by decide

/-- every group element commutes with the canonical pairing. -/
theorem g48_partner_comm :
    ∀ p ∈ G48, ∀ h < 64, applyPerm p (partner h) = partner (applyPerm p h) := by decide

/-- COUPLE IMAGE: each group element maps the couple through r onto the couple
    through r's image — member for member, as an unordered 4-set. -/
theorem g48_couple_image :
    ∀ p ∈ G48, ∀ r ∈ crossReps,
      ((coupleOf r).map (applyPerm p)).Perm (coupleOf (applyPerm p r)) := by decide

/-- G48 COUPLE-INVARIANCE: every one of the 48 group elements maps the 12 cross
    complement-couples to cross complement-couples — the induced map on canonical
    couple representatives is a permutation of crossReps. With `g48_couple_image`
    this is the machine-checked core of the G48-invariance of c3slot (and hence of
    C3 = 16 + 8 · c3slot): a group relabeling permutes the 12 couples while
    preserving every couple's slot gap. -/
theorem g48_couples_to_couples :
    ∀ p ∈ G48, ((crossReps.map fun r => coupleMin (applyPerm p r)).Perm crossReps) := by
  decide

end C3Decomposition
