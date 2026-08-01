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

  Added 2026-07-27 — THE C3 ≥ 112 FLOOR (`c3slot_ge_12`, `c3_ge_112`): every
  C1-valid ordering has couple slot-distance sum ≥ 12 (each of the 12 cross
  couples occupies two distinct slots, so each contributes ≥ 1), hence via the
  decomposition C3 ≥ 16 + 8·12 = 112 — the lower-bound half of "min C3 = 112",
  previously an asserted step alongside the SAT certificate; the verified
  witness at C3 = 112 (G = 12) makes the floor exact.

  Added 2026-07-24 — THE C1∩C4 NULL G-LAW (final section): the exact distribution
  of G = c3slot over the 31! equally-weighted C1∩C4 pair-orders, machine-checked by
  the KERNEL end to end (`decide +kernel`; no native_decide): the full 217-bin
  histogram as a literal (`null_law`), total mass = 31! (`null_total`), support
  exactly [12, 228] with closed-form endpoint counts, E[G] = 128 exactly hence
  E[C3] = 1040 (`null_mean_128`, `null_c3_mean_1040`), and P(G ≤ 95) =
  641983711307479/7919632354008375 exactly (`null_p_le_95`) — the exact-null leg
  of the C3 analysis, previously computed (not machine-checked) by
  verify.py --check-null-g. The DP recurrence itself is validated in-kernel
  against brute-force enumeration over all orderings at small sizes.
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

/- ------------------ the C3 ≥ 112 floor (added 2026-07-27) ------------------
   The lower-bound half of "min C3 over the C1 space = 112". The SAT layer
   produced a C1-valid witness attaining C3 = 112 (c3_112_witness.bin, couple
   slot-distance sum G = 12, independently verified); minimality previously
   rested on the asserted step "12 cross couples, each slot distance ≥ 1, so
   G ≥ 12". That step is discharged here from the structural lemmas above:
   `slot_ne` proves each cross couple's two pairs occupy DISTINCT slots (its
   members are distinct elements of a permutation), so each of the 12 terms of
   c3slot is ≥ 1 and c3slot ≥ 12 (`c3slot_ge_12`); via `c3_slot_decomposition`,
   C3 = 16 + 8·c3slot ≥ 16 + 8·12 = 112 (`c3_ge_112`) for EVERY C1-valid
   ordering. Together with the witness, the floor is exact — no SAT UNSAT
   result is needed for the lower bound. -/

/-- a mapped sum with every term ≥ 1 is at least the list's length. -/
theorem length_le_sum_map (f : Nat → Nat) (rs : List Nat)
    (h : ∀ r ∈ rs, 1 ≤ f r) : rs.length ≤ (rs.map f).sum := by
  induction rs with
  | nil => simp
  | cons a t ih =>
    have ha := h a (List.mem_cons.mpr (Or.inl rfl))
    have ht := ih fun r hr => h r (List.mem_cons.mpr (Or.inr hr))
    simp only [List.map_cons, List.sum_cons, List.length_cons]
    omega

/-- THE SLOT-SUM LOWER BOUND: every C1-valid ordering of the 64 hexagrams has
    couple slot-distance sum ≥ 12 — each of the 12 cross complement-couples
    occupies two distinct slots (`slot_ne`), so each term of c3slot is ≥ 1. -/
theorem c3slot_ge_12 (l : List Nat) (hp : l.Perm (List.range 64))
    (h1 : c1ok l = true) : 12 ≤ c3slot l := by
  have hterm : ∀ r ∈ crossReps, 1 ≤ sdist l r (r ^^^ 63) := by
    intro r hr
    obtain ⟨hr64, hrc⟩ := crossReps_spec r hr
    have hne := slot_ne hp h1 hr64 hrc
    simp only [sdist, slot, ndist]
    omega
  have h := length_le_sum_map (fun r => sdist l r (r ^^^ 63)) crossReps hterm
  rw [crossReps_count] at h
  simp only [c3slot]
  exact h

/-- THE C3 FLOOR: C3 ≥ 112 for EVERY C1-valid ordering, via the decomposition
    C3 = 16 + 8·c3slot and c3slot ≥ 12. With the verified C3 = 112 witness,
    min C3 over the C1 space is exactly 112. -/
theorem c3_ge_112 (l : List Nat) (hp : l.Perm (List.range 64))
    (h1 : c1ok l = true) : 112 ≤ c3x64 l := by
  rw [c3_slot_decomposition l hp h1]
  have h := c3slot_ge_12 l hp h1
  omega

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


/- ------------------ the C1∩C4 null G-law (added 2026-07-24) ------------------
   The EXACT distribution of the couple slot-distance sum G = c3slot under the
   C1∩C4 null: all 31! orderings of the 31 free pair-slots (slot 0 pinned by C4
   with the self-complement pair {63, 0}), counted equally. Within-slot
   orientations never matter: `slot_orientation_free` above proves a hexagram and
   its pair-partner share a slot, so G is a pair-order quantity and the 31!
   pair-order model carries the full C1∩C4 null.

   The law is computed by a 31-layer DP over states (o, c, g) = (couples with one
   pair placed, couples with both pairs placed, running G) — the recurrence
   verify.py --check-null-g runs in Python — restated here over Nat-histograms
   (list index = G value). EVERY fact in this section is checked by the Lean
   kernel (`decide +kernel`); no native_decide, no extended trust base:

   · `nullHist_matches_brute_*` — semantic validation: the same generic
     recurrence, at small parameters, equals brute-force enumeration over ALL
     orderings of distinct pair tokens (120 / 5040 / 5040 orderings enumerated
     inside the kernel), pinning the recurrence to the counting model;
   · `null_law` — the 12-couple/7-self/31-slot histogram equals an explicit
     217-bin literal: the entire law, pinned bin by bin;
   · `null_terminal_closed` — the DP ends with every couple closed;
   · `null_total` — the mass is exactly 31!;
   · support — exactly [12, 228] and contiguous, with closed-form endpoint
     counts 19!·2¹² (all 12 couples slot-adjacent) and (12!)²·2¹²·7! (opens
     occupy slots 1–12, closes 20–31);
   · `null_mean_128` — E[G] = 128 exactly, hence via `c3_slot_decomposition`
     E[C3] = 16 + 8·128 = 1040 (`null_c3_mean_1040`); the DP-free linearity
     closed form 12·E|i−j| = 12·(9920/930) = 128 is pinned in
     `sum_absdiff_31` / `null_mean_linearity` as an independent cross-check;
   · `null_p_le_95` — P(G ≤ 95) · 7919632354008375 = 641983711307479 · (total),
     i.e. P(G ≤ 95) = 641983711307479/7919632354008375 (≈ 8.106231%) exactly, in
     lowest terms (`null_p_le_95_lowest_terms`), with the ≤95 mass as an exact
     integer (`null_mass_le_95`). KW's own slot-distance sum is 95
     (`kw_slot_sum_95` above), so this is the null mass at-or-below King Wen.

   Modeling note (the one non-kernel step): reading the C1∩C4 null as "uniform
   over the 31! free pair-orders" is a modeling choice, made independently by
   verify.py (whose DP also uses a differently-phrased G accumulator, so
   agreement is evidence); the brute-force theorems remove the recurrence
   itself from the trust base at small size, and the 12/7/31 instance runs the
   identical generic definition.

   Nat-subtraction note: stepCell's multipliers use truncated Nat subtraction;
   the only states a truncation could misprice are unreachable ones, whose
   histograms are empty by the scale/shiftG guards — and `null_terminal_closed`
   plus `null_total` (mass exactly 31!) check the instance end-to-end. -/

/-- pointwise sum of two G-histograms (Nat-lists indexed by G value; the longer
    tail carries through). -/
def padd : List Nat → List Nat → List Nat
  | xs, [] => xs
  | [], ys => ys
  | x :: xs, y :: ys => (x + y) :: padd xs ys

/-- scale every weight by k; a zero multiplier contributes nothing (empty), so
    cell histograms never grow trailing zeros. -/
def scale (k : Nat) (xs : List Nat) : List Nat :=
  if k == 0 then [] else xs.map (k * ·)

/-- shift a histogram up by o G-units (running G grows by the number of open
    couples spanning the slot). -/
def shiftG (o : Nat) (xs : List Nat) : List Nat :=
  if xs.isEmpty then [] else List.replicate o 0 ++ xs

/-- cell (o, c) of a DP layer: the histogram of running G over assignments
    reaching o open and c closed couples. -/
def cellOf (grid : List (List (List Nat))) (o c : Nat) : List Nat :=
  (grid.getD o []).getD c []

/-- one DP slot step, pull-style: the new (o, c) histogram sums the three
    in-transitions — place a self pair (× remaining selves), open a couple
    (× 2 · unopened couples: which couple, which of its two pairs first), close
    an open couple (× open couples at the source) — then shifts by the o couples
    open AFTER this slot, so G accumulates Σ_s open(s) = Σ_couples |slot(u) −
    slot(v)|. -/
def stepCell (nc ns s : Nat) (prev : List (List (List Nat))) (o c : Nat) : List Nat :=
  let selfIn := scale (ns - ((s - 1) - o - 2*c)) (cellOf prev o c)
  let openIn := if o = 0 then [] else scale (2 * (nc + 1 - o - c)) (cellOf prev (o-1) c)
  let closeIn := if c = 0 then [] else scale (o + 1) (cellOf prev (o+1) (c-1))
  shiftG o (padd (padd selfIn openIn) closeIn)

def stepGrid (nc ns s : Nat) (prev : List (List (List Nat))) : List (List (List Nat)) :=
  (List.range (nc+1)).map fun o => (List.range (nc+1)).map fun c => stepCell nc ns s prev o c

/-- layer 0: one empty assignment, no couples touched, G = 0. -/
def initGrid (nc : Nat) : List (List (List Nat)) :=
  (List.range (nc+1)).map fun o => (List.range (nc+1)).map fun c =>
    if o == 0 && c == 0 then [1] else ([] : List Nat)

def runDP (nc ns : Nat) : Nat → List (List (List Nat))
  | 0 => initGrid nc
  | s + 1 => stepGrid nc ns (s + 1) (runDP nc ns s)

/-- the null G-histogram over nslot slots with nc couples and ns self pairs:
    index g holds the number of pair-orderings with G = g (terminal cell: all
    couples closed). -/
def nullHist (nc ns nslot : Nat) : List Nat := cellOf (runDP nc ns nslot) 0 nc

/-- G of one explicit token ordering: tokens 2i and 2i+1 (i < nc) are the two
    pairs of couple i, all other tokens are self pairs; G sums the couples'
    slot distances. -/
def gOf (nc : Nat) (l : List Nat) : Nat :=
  ((List.range nc).map fun i => ndist (l.findIdx (· == 2*i)) (l.findIdx (· == 2*i+1))).sum

/-- brute-force histogram over ALL nslot! orderings of nslot distinct pair
    tokens (via `perms` above) — the ground truth the DP recurrence must match. -/
def bruteHist (nc nslot : Nat) : List Nat :=
  (perms (List.range nslot)).foldl (fun h l => padd h (shiftG (gOf nc l) [1])) []

/-- Σ (g0 + index) · weight — the histogram's weighted sum with base offset g0. -/
def wsum (g0 : Nat) : List Nat → Nat
  | [] => 0
  | w :: t => g0 * w + wsum (g0 + 1) t

def fact : Nat → Nat
  | 0 => 1
  | n + 1 => (n + 1) * fact n

/-- THE INSTANCE: 12 cross-couples, 7 free self pairs, 31 free slots (slot 0
    pinned by C4 with the eighth self pair {63, 0}). -/
def NullHist : List Nat := nullHist 12 7 31

/-- the full exact law, bin by bin: entry g (for g = 12..228) is the number of
    the 31! pair-orderings with couple slot-distance sum exactly g. Cross-checked
    bin-for-bin against verify.py --check-null-g (an independent Python
    implementation of the DP with a different G-accumulator phrasing). -/
def NullLawLiteral : List Nat :=
  List.replicate 12 0 ++
    [
      498258331274575872000, 2202826306687598592000, 11695958723603202048000,
      38859007854574043136000, 125260679016748154880000, 332475597955446865920000,
      839062402080027181056000, 1892477697908010909696000, 4090022929062734856192000,
      8205029219881545891840000, 15893354780460155142144000, 29175928460768704462848000,
      52055636857623328849920000, 89121663471709480550400000, 149058113422627694444544000,
      241265899072847741976576000, 383013491482689124958208000, 591927441191092214562816000,
      900033304457970582552576000, 1338130860819128984272896000, 1962018239226099718422528000,
      2822451781295263054823424000, 4011862643089182812012544000, 5609508126032441099943936000,
      7762041233811821901643776000, 10587360374467431399161856000, 14310030589711509211840512000,
      19097401233983125900492800000, 25282780392030037560262656000, 33093669965653223191609344000,
      43011604119200068282613760000, 55332600846223945217605632000, 70736047409449798327074816000,
      89590203357150784039944192000, 112834643147158027694505984000,
      140904563127043219846594560000, 175075684500042684076916736000,
      215833692016046777825230848000, 264883135303906158163525632000,
      322723693616549769718530048000, 391601891762675786704748544000,
      471971307024748742531088384000, 566754562636420039883882496000,
      676269242009461125109776384000, 804270669278699643551612928000,
      950814337227352723930742784000, 1120673902330844010938105856000,
      1313468811120640705834254336000, 1535200847142646371204464640000,
      1784840399482932838986153984000, 2069846750592409263679733760000,
      2388273783154247313899126784000, 2749300084403204169595355136000,
      3149734027752527524351967232000, 3600760451301827456494731264000,
      4097551499556174687218171904000, 4653616126061863444697579520000,
      5262027746362166010301120512000, 5938977150047112705651769344000,
      6674901172299358477731495936000, 7489043600925123024481419264000,
      8368624380362651609937739776000, 9336339673952650484558856192000,
      10375519658632243259860058112000, 11512756826994529080044421120000,
      12726779754374656158974607360000, 14048513900386636467756072960000,
      15451340946207768161820868608000, 16970970800906425121378402304000,
      18574630634515928797201563648000, 20303361645748813007016689664000,
      22117379607894642397601071104000, 24063490561797245776057860096000,
      26094160976012309063018741760000, 28262480720288466305361641472000,
      30512293093192025140031913984000, 32903460826062520652188876800000,
      35370472107774090732795592704000, 37980496599974320950755721216000,
      40657870932291408455106822144000, 43477527857861209051128397824000,
      46353116758950159786134470656000, 49367718321043597003516280832000,
      52423839954964277026942353408000, 55612919982389134483418775552000,
      58826053068687760289332985856000, 62163424773993026502852083712000,
      65504508469557066855937474560000, 68958263552286837461483520000000,
      72392617158652452902944112640000, 75925520176224439082082631680000,
      79413701446844809473026949120000, 82983630213592268980145356800000,
      86481323209807842283565875200000, 90042168272125933632639467520000,
      93501887136245860490784276480000, 97003935137626864653969653760000,
      100375130597234995033496616960000, 103766675688566145711907799040000,
      106997419281166483572475822080000, 110225811157999324704748339200000,
      113263348420886592154396262400000, 116275686485134948158186455040000,
      119069121503627629529357352960000, 121814269033871409890281390080000,
      124313560102326839517433036800000, 126743746151210871333637324800000,
      128903479876958579865189089280000, 130973889376573495746704179200000,
      132753420499993386648569118720000, 134425720864864700356519526400000,
      135789763346827822227762708480000, 137032187710018260208912957440000,
      137952730764315992377377423360000, 138740109008199680384701562880000,
      139198281397532087440732323840000, 139514174566674018904760647680000,
      139497244074990506642327470080000, 139334965360651269044258734080000,
      138841396026706013992129658880000, 138201419926977478257121689600000,
      137237927810309291958180249600000, 136131342505592675612649062400000,
      134712986279152322730283499520000, 133160085231535939742985093120000,
      131311265580984943858050662400000, 129338627123584105277470801920000,
      127092765417846018959160115200000, 124736219925898040280895979520000,
      122130701942394912999022264320000, 119433660502840358481879367680000,
      116514754285216121044944814080000, 113522867706172353615243509760000,
      110341095775990560507832565760000, 107106602374072703871552061440000,
      103714061810827879954010603520000, 100292994924706787233722531840000,
      96745295395279122293304852480000, 93191110117249558558927749120000,
      89545364353316607947345756160000, 85914982687526730741558804480000,
      82224021437961307107643883520000, 78572475066505610806186475520000,
      74890348699634885514661724160000, 71266839091597933914536017920000,
      67643475509215878830798929920000, 64096726549227086534745784320000,
      60575023904558452709397626880000, 57148525272435349663996968960000,
      53768693600941564504477532160000, 50497379354022075280958423040000,
      47294389651547639953238261760000, 44209619242477288542877777920000,
      41208134779560635340297338880000, 38334912497421638358647439360000,
      35557079884222158554592706560000, 32911235631974144740153098240000,
      30370939916638424681813114880000, 27964297171311617441267712000000,
      25667732725734859888090152960000, 23505632493882089460486635520000,
      21455320202985749746475335680000, 19535693415109775386120028160000,
      17728178571445765576505425920000, 16045578689864953746539151360000,
      14471289644730443396598988800000, 13015603845924298807931043840000,
      11663351531879673005699235840000, 10420362753334947822604124160000,
      9274232018640561410471362560000, 8227833309228814975578931200000,
      7269984624247145140982906880000, 6401919891702877340439674880000,
      5613217153997227987493191680000, 4903920640692822617358336000000,
      4265065529703765205560852480000, 3694804955107763516646359040000,
      3185418145461016279614750720000, 2734816098977495376262594560000,
      2336042710412161415255162880000, 1986257965316309922128855040000,
      1679684433587931304773550080000, 1413594906616407974215680000000,
      1182714508488793625985024000000, 984305699837469298733875200000,
      814110873924932960727859200000, 669470551573842779701248000000,
      546842312978945257399910400000, 443935162963062135403315200000,
      357660208771097419579392000000, 286247837300308213078425600000,
      227308159430147788347801600000, 179214556384550806408396800000,
      139986673359249327154790400000, 108514752376537746505728000000,
      83294320880679560360755200000, 63324956832083723943936000000, 47668100730479671718707200000,
      35530232741451465228288000000, 26113527053368283470233600000, 19009848792546175824691200000,
      13672123553834314865049600000, 9658665724416123469824000000, 6748829855172328528281600000,
      4621318279585777424793600000, 3114298020663801151488000000, 2056857666119020000051200000,
      1332556415432318464819200000, 833637188801260840550400000, 521023243000788025344000000,
      307877370864102014976000000, 170516697709348808294400000, 94731498727416004608000000,
      47365749363708002304000000, 23682874681854001152000000, 9473149872741600460800000,
      4736574936370800230400000
    ]

/-- SEMANTIC VALIDATION of the recurrence, kernel-enumerated: 2 couples, 1 self,
    5 slots — the DP equals brute force over all 5! = 120 token orderings. -/
theorem nullHist_matches_brute_2_1_5 : nullHist 2 1 5 = bruteHist 2 5 := by decide +kernel

/-- 2 couples, 3 selves, 7 slots: DP = brute force over all 7! = 5040 orderings. -/
theorem nullHist_matches_brute_2_3_7 : nullHist 2 3 7 = bruteHist 2 7 := by decide +kernel

/-- 3 couples, 1 self, 7 slots: DP = brute force over all 7! = 5040 orderings. -/
theorem nullHist_matches_brute_3_1_7 : nullHist 3 1 7 = bruteHist 3 7 := by decide +kernel

/-- THE NULL LAW, kernel-evaluated: the 31-layer DP yields exactly the literal
    histogram. Every subsequent theorem reads off this literal. -/
theorem null_law : NullHist = NullLawLiteral := by decide +kernel

/-- the DP terminates with all 12 couples closed: every terminal cell other than
    (o, c) = (0, 12) is empty. -/
theorem null_terminal_closed :
    ((List.range 13).all fun o => (List.range 13).all fun c =>
      (o == 0 && c == 12) || (cellOf (runDP 12 7 31) o c).isEmpty) = true := by
  decide +kernel

theorem fact_31 : fact 31 = 8222838654177922817725562880000000 := by decide +kernel

/-- TOTAL MASS = 31!: the DP counts every pair-ordering exactly once. -/
theorem null_total : NullHist.sum = fact 31 := by rw [null_law]; decide +kernel

/-- SUPPORT, lower end: no mass below G = 12 (each of the 12 couples has slot
    distance ≥ 1). -/
theorem null_support_below_12 : (NullHist.take 12).sum = 0 := by
  rw [null_law]; decide +kernel

/-- G = 12 is attained, with closed-form count 19! · 2¹²: all 12 couples
    slot-adjacent — 19 objects (12 adjacent-couple blocks + 7 selves) in order,
    × 2 orientations per couple. -/
theorem null_support_min : NullHist.getD 12 0 = fact 19 * 2^12 := by
  rw [null_law]; decide +kernel

/-- G = 228 is attained, with closed-form count (12!)² · 2¹² · 7!: the maximum
    forces opens = slots 1..12 and closes = slots 20..31 (Σcloses − Σopens =
    306 − 78 = 228), any open/close slot assignments, selves in 13..19. -/
theorem null_support_max : NullHist.getD 228 0 = fact 12 * fact 12 * 2^12 * fact 7 := by
  rw [null_law]; decide +kernel

/-- no mass above G = 228: the histogram has exactly 229 bins (indices 0..228). -/
theorem null_support_bins : NullHist.length = 229 := by rw [null_law]; decide +kernel

/-- the support is CONTIGUOUS: every G in [12, 228] has nonzero mass. -/
theorem null_support_contiguous : ((NullHist.drop 12).all (· != 0)) = true := by
  rw [null_law]; decide +kernel

/-- E[G] = 128 EXACTLY: the weighted sum equals 128 · 31!. -/
theorem null_mean_128 : wsum 0 NullHist = 128 * fact 31 := by
  rw [null_law]; decide +kernel

/-- hence E[C3] = 16 + 8·128 = 1040 under the null, via `c3_slot_decomposition`
    (C3 = 16 + 8·G pointwise, so the identity holds in histogram arithmetic). -/
theorem null_c3_mean_1040 :
    16 * NullHist.sum + 8 * wsum 0 NullHist = 1040 * NullHist.sum := by
  rw [null_law]; decide +kernel

/-- DP-free linearity cross-check, part 1: Σ_{i,j ∈ 31 slots} |i − j| = 9920,
    so a uniformly random ordered pair of distinct slots has E|i − j| =
    9920/(31·30) = 32/3. -/
theorem sum_absdiff_31 :
    ((List.range 31).map fun i => ((List.range 31).map (ndist i)).sum).sum = 9920 := by
  decide +kernel

/-- part 2: 12 couples × E|i−j| = 12 · 9920/930 = 128 — the closed form
    E[G] = 12·(32/3) = 128, in cleared-denominator form. Matches
    `null_mean_128`, derived independently of the DP. -/
theorem null_mean_linearity : 12 * 9920 = 128 * (31 * 30) := by decide

/-- the exact mass at G ≤ 95 (KW's value: `kw_slot_sum_95`). -/
theorem null_mass_le_95 :
    (NullHist.take 96).sum = 666562315107961675963674132480000 := by
  rw [null_law]; decide +kernel

/-- P(G ≤ 95) = 641983711307479/7919632354008375 EXACTLY (≈ 8.106231%), in
    cleared-denominator form over the histogram: (mass at G ≤ 95) · denominator
    = numerator · (total mass). -/
theorem null_p_le_95 :
    (NullHist.take 96).sum * 7919632354008375 = 641983711307479 * NullHist.sum := by
  rw [null_law]; decide +kernel

/-- and that fraction is in lowest terms. -/
theorem null_p_le_95_lowest_terms : Nat.gcd 641983711307479 7919632354008375 = 1 := by
  decide +kernel

/- ------------------ THE WALK-UNITS IDENTITY, T = 387 (added 2026-07-27) ------------------
   The v4 compiler's walk complement-distance functional cd* counts each of
   the 32 complement-couples ONCE and excludes the C4-anchored couple {0, 63};
   SPECIFICATION's C3 = c3x64 counts every couple TWICE (once per member).
   This section machine-checks the units conversion — previously a prose
   derivation (the arithmetic content of compiler bridge fact KB7):

       c3x64 l = 2 · (walkCd l + 1)      for every C4-anchored permutation l,

   hence  c3x64 l ≤ 776  ⟺  walkCd l ≤ 387  — the full-31 in-path threshold
   T = 776/2 − 1 = 387 — and at King Wen walkCd KW = 387 exactly, with the
   slot form T = 7 + 4·G (G = c3slot, KW: G = 95). Kernel-only: decide +
   structural, no native_decide.

   SCOPE (stated bluntly, per the project's bridge-fact discipline): this
   proves the MATHEMATICAL identity between the two functionals as defined
   here. That solve.c's cd* accumulator implements this walk functional
   remains bridge fact KB7, runtime-carried (the two-language gate vs
   solve.py), exactly as documented — nothing here machine-checks C code. -/

/-- C4 (restated verbatim from KingWen.lean): the ordering opens 63, 0. -/
def c4ok (l : List Nat) : Bool := l.getD 0 99 == 63 && l.getD 1 99 == 0

/-- couples-once complement-distance sum: each of the 32 complement-couples
    {h, h ⊕ 63} (representatives h < 32) counted once. -/
def cdOnce (l : List Nat) : Nat := ((List.range 32).map (cdist l)).sum

/-- the walk functional: couples-once, EXCLUDING the anchor couple {0, 63}
    (representatives 1..31) — the v4 compiler's cd* in model form. -/
def walkCd (l : List Nat) : Nat := ((List.range 31).map fun i => cdist l (i+1)).sum

/-- the 64 hexagrams split into the 32 couple representatives and their
    complements. -/
theorem couples_partition :
    (List.range 64).Perm ((List.range 32) ++ (List.range 32).map (· ^^^ 63)) := by
  decide

/-- each couple's two members carry the same C3 term. -/
theorem cdist_comp (l : List Nat) (h : Nat) (hh : h < 64) :
    cdist l (h ^^^ 63) = cdist l h := by
  simp only [cdist]
  rw [comp_comp h hh]
  exact ndist_comm _ _

/-- DOUBLING (fully general — no constraint hypotheses needed): c3x64 counts
    every couple twice, so it is exactly twice the couples-once sum. -/
theorem c3x64_eq_double (l : List Nat) : c3x64 l = 2 * cdOnce l := by
  have hsum := List.Perm.sum_nat (couples_partition.map (cdist l))
  rw [c3x64_eq_sum, hsum, List.map_append, List.sum_append, List.map_map]
  have hcomp : ((List.range 32).map (cdist l ∘ (· ^^^ 63))) =
      (List.range 32).map (cdist l) := by
    apply List.map_eq_map_iff.mpr
    intro h hmem
    have hh : h < 64 := by
      have := List.mem_range.mp hmem
      omega
    exact cdist_comp l h hh
  rw [hcomp]
  simp only [cdOnce]
  omega

/-- peeling the anchor representative 0: couples-once = anchor term + walk sum. -/
theorem cdOnce_split (l : List Nat) : cdOnce l = cdist l 0 + walkCd l := by
  have hr : List.range 32 = 0 :: (List.range 31).map (· + 1) := by decide
  simp only [cdOnce, walkCd, hr, List.map_cons, List.sum_cons, List.map_map]
  rfl

/-- under C4, the anchor couple contributes exactly 1: 63 and 0 sit in
    positions 0 and 1. -/
theorem anchor_cdist_one (l : List Nat) (hp : l.Perm (List.range 64))
    (h4 : c4ok l = true) : cdist l 0 = 1 := by
  have hlen : l.length = 64 := by simpa using hp.length_eq
  simp only [c4ok, Bool.and_eq_true, beq_iff_eq] at h4
  have h0l : (0 : Nat) < l.length := by omega
  have h1l : (1 : Nat) < l.length := by omega
  have e0 : l.getD 0 0 = 63 := by
    have he : l.getD 0 99 = l.getD 0 0 := by
      simp [List.getD, List.getElem?_eq_getElem h0l]
    rw [← he]; exact h4.1
  have e1 : l.getD 1 0 = 0 := by
    have he : l.getD 1 99 = l.getD 1 0 := by
      simp [List.getD, List.getElem?_eq_getElem h1l]
    rw [← he]; exact h4.2
  have p63 : pos l 63 = 0 := pos_unique hp (by omega) e0
  have p0 : pos l 0 = 1 := pos_unique hp (by omega) e1
  simp only [cdist, show (0 : Nat) ^^^ 63 = 63 from by decide, p0, p63]
  decide

/-- THE WALK-UNITS IDENTITY (KB7's arithmetic content, machine-checked): for
    every C4-anchored permutation of the 64 hexagrams,
    c3x64 = 2 · (walkCd + 1) — the affine identity cd_true = 2 · (cd* + 1).
    Note C1 is NOT needed: doubling is general, the anchor term needs C4 only. -/
theorem walk_units_identity (l : List Nat) (hp : l.Perm (List.range 64))
    (h4 : c4ok l = true) : c3x64 l = 2 * (walkCd l + 1) := by
  have hd := c3x64_eq_double l
  have hs := cdOnce_split l
  have ha := anchor_cdist_one l hp h4
  omega

/-- THE FULL-31 THRESHOLD CONSTANT T = 387: the C3 bound in x64 units (≤ 776)
    is EXACTLY the walk bound ≤ 387, i.e. T = 776/2 − 1 = 387. -/
theorem walk_threshold_387 (l : List Nat) (hp : l.Perm (List.range 64))
    (h4 : c4ok l = true) : (c3x64 l ≤ 776) ↔ (walkCd l ≤ 387) := by
  rw [walk_units_identity l hp h4]
  omega

/-- with C1 as well, the walk functional in slot units: walkCd = 7 + 4·G
    (via the slot decomposition; at KW: 387 = 7 + 4·95). -/
theorem walkCd_eq_slot (l : List Nat) (hp : l.Perm (List.range 64))
    (h1 : c1ok l = true) (h4 : c4ok l = true) :
    walkCd l = 7 + 4 * c3slot l := by
  have hid := walk_units_identity l hp h4
  have hdec := c3_slot_decomposition l hp h1
  omega

theorem kw_c4 : c4ok KW = true := by decide

/-- King Wen's walk value is exactly the threshold: cd*(KW) = 387. -/
theorem kw_walkCd_387 : walkCd KW = 387 := by decide

/-- cross-check: the identity instantiated at KW reproduces 776 = 2·(387+1). -/
theorem kw_units_check : c3x64 KW = 2 * (walkCd KW + 1) :=
  walk_units_identity KW kw_perm kw_c4

end C3Decomposition

/-! ### Axiom audit (added 2026-08-01)
Emits the trust base for every theorem in this file that is CITED BY NAME in the
public documentation, so the suite's `#print axioms` claims are OBSERVED rather than
statically inferred. Expected: `[propext, Classical.choice, Quot.sound]`, or
`[propext]` alone for the finite facts. Any `Lean.ofReduceBool` here means a
`native_decide` (compiler trust) is load-bearing and the docs must say so. -/
#print axioms partner_comp_comm
#print axioms slot_orientation_free
#print axioms c3_slot_decomposition
#print axioms kw_slot_sum_95
#print axioms g48_couple_image
#print axioms g48_couples_to_couples
#print axioms nullHist_matches_brute_2_1_5
#print axioms null_law
#print axioms null_terminal_closed
#print axioms null_total
#print axioms null_support_below_12
#print axioms null_support_min
#print axioms null_support_max
#print axioms null_support_bins
#print axioms null_support_contiguous
#print axioms null_mean_128
#print axioms null_c3_mean_1040
#print axioms sum_absdiff_31
#print axioms null_mean_linearity
#print axioms null_mass_le_95
#print axioms null_p_le_95
#print axioms null_p_le_95_lowest_terms
