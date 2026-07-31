-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  C1RuleConstants.lean — the eight "forced-1.0" literature rules are CONSTANTS
  of the C1 space (2026-07-21, TR-12 exactness pass).

  THEOREM (informal): each of the eight registry rules mmt4, p1c4, s1, s6,
  r3, r4, r5, c2 (solve.py reg_* = the SPEC; C port solve.c score_registry)
  depends only on the unordered pair-partition {seq[2k], seq[2k+1]}, which C1
  fixes definitionally (partner is a fixed-point-free involution, so every
  C1-valid ordering carries the SAME 32 unordered pairs). Hence each rule is
  constant over the entire C1 space (all 32!·2³² orderings), equal to its
  King Wen value:
      mmt4 = p1c4 = s1 = s6 = r3 = r5 = true,
      r4 = 120 (threshold ≤120 = true),  c2 = ((2,12),(4,12),(6,8)).

  PROOF ARCHITECTURE (project style; core Lean 4 only, no mathlib, no lake):
  · §0 defs restated verbatim from lean/TrigramTheorems.lean / KingWen.lean.
  · §1 counting machinery copied from TrigramTheorems.lean §2 — in particular
    within_double: for any slot predicate p invariant under the partner
    involution, 2 · (even-slot count over a C1-valid ordering) = the fixed
    countP over List.range 64.
  · §2 per-rule slot predicates: each reg_* aggregates independent per-pair
    terms with permutation-invariant aggregators (all/len/sum/histogram —
    read directly from solve.py:5680-5952 and solve.c:5225-5404), so each
    rule is a Boolean combination of even-slot counts of slot predicates
    g(h) := f(h, partner h). Orientation invariance g(partner h) = g(h) is
    decided over all 64 hexagrams (NOT sampled) — this is the "factors
    through the pair-multiset" step.
  · §3 the fixed range-64 counts, by kernel `decide` (finite evaluation on the
    canonical partition — the single finite evaluation the theorem needs;
    migrated from native_decide 2026-07-27).
  · §4 the sequence-level constancy theorems, each: within_double + omega.

  The ONLY non-Lean steps, stated for the record:
  (a) transcription fidelity reg_* (Python/C) → the countP forms below —
      verified two-language style by driving the repo's own reg_* functions
      over 5,449 structured C1 sequences (all 32 orientation flips + all 31
      adjacent transpositions from KW and 6 random bases + full reversal +
      5,000 random C1 samples): zero deviations from the KW value
      (scratchpad c1_constants_check.py, 2026-07-21);
  (b) for r4/r5's total-cost conjunct: the one-line arithmetic
      2·12 + 4·12 + 6·8 = 120 converting the Lean-checked within-pair
      histogram {2:12, 4:12, 6:8} into the total pairing cost (the histogram
      itself is ALSO already machine-checked at C1 generality by the landed
      lean/TrigramTheorems.lean within_multiset_general).

  *** COMPILES CLEAN on Lean 4.31.0 (2026-07-21, x86_64 linux, core only —
  *** no mathlib, no lake project): `lean C1RuleConstants.lean` exits 0 with
  *** zero errors/warnings; zero `sorry`, zero `axiom`, zero `admit`. The
  *** pinned toolchain is recorded in this directory's `lean-toolchain`
  *** (leanprover/lean4:v4.31.0). Every finite fact below was verified
  *** numerically in Python (all-64 exhaustive checks, 18 exact lemmas, plus a
  *** 5,449-sequence drive of the repo's own reg_* functions with zero
  *** deviations) BEFORE being drafted in Lean — repeatable via the scratchpad
  *** cross-check c1_constants_check.py (TR-12 exactness pass, 2026-07-21).
  *** Trust base: KERNEL-ONLY since 2026-07-27 — every proof in this file is
  *** `decide`/structural (the §3 finite counts were migrated from
  *** native_decide; `#print axioms`: the finite counts report [propext] or no
  *** axioms, the sequence-level constancy theorems [propext, Classical.choice,
  *** Quot.sound] — Lean's standard axioms only; nothing here trusts Lean's
  *** compiler).
-/

namespace C1RuleConstants

/- ────────── §0 defs restated verbatim from TrigramTheorems.lean ────────── -/

/-- popcount for 6-bit values. -/
def pc6 (n : Nat) : Nat :=
  n % 2 + n / 2 % 2 + n / 4 % 2 + n / 8 % 2 + n / 16 % 2 + n / 32 % 2

/-- 6-bit reversal. -/
def rev6 (n : Nat) : Nat :=
  n % 2 * 32 + n / 2 % 2 * 16 + n / 4 % 2 * 8 + n / 8 % 2 * 4 + n / 16 % 2 * 2 + n / 32 % 2

/-- canonical partner: reversal, or complement for palindromes. -/
def partner (h : Nat) : Nat := if rev6 h = h then h ^^^ 63 else rev6 h

/-- Hamming distance on 6-bit values. -/
def ham (a b : Nat) : Nat := pc6 (a ^^^ b)

/-- C1: consecutive pairing by partner. -/
def c1ok (l : List Nat) : Bool :=
  ((List.range 32).all fun i => l.getD (2*i+1) 99 == partner (l.getD (2*i) 99))

def KW : List Nat :=
  [63,  0, 17, 34, 23, 58,  2, 16, 55, 59,  7, 56, 61, 47,  4,  8,
   25, 38,  3, 48, 41, 37, 32,  1, 57, 39, 33, 30, 18, 45, 28, 14,
   60, 15, 40,  5, 53, 43, 20, 10, 35, 49, 31, 62, 24,  6, 26, 22,
   29, 46,  9, 36, 52, 11, 13, 44, 54, 27, 50, 19, 51, 12, 21, 42]

/- ────────── §1 counting machinery (verbatim from TrigramTheorems.lean §2) ────────── -/

theorem self_eq_rangeMap (l : List Nat) :
    l = (List.range l.length).map (fun j => l.getD j 0) := by
  induction l with
  | nil => rfl
  | cons a t ih =>
    rw [List.length_cons, List.range_succ_eq_map, List.map_cons, List.map_map]
    congr 1

theorem range64_perm :
    (List.range 64).Perm
      (((List.range 32).map (fun i => 2*i)) ++ ((List.range 32).map (fun i => 2*i+1))) := by
  decide

theorem countP_even_odd_split (l : List Nat) (hlen : l.length = 64) (p : Nat → Bool) :
    l.countP p =
      ((List.range 32).countP fun i => p (l.getD (2*i) 0)) +
      ((List.range 32).countP fun i => p (l.getD (2*i+1) 0)) := by
  conv => lhs; rw [self_eq_rangeMap l, hlen]
  rw [List.countP_map, range64_perm.countP_eq, List.countP_append,
      List.countP_map, List.countP_map]
  rfl

theorem perm_lt64 {l : List Nat} (hp : l.Perm (List.range 64)) : ∀ x ∈ l, x < 64 :=
  fun _ hx => List.mem_range.mp (hp.mem_iff.mp hx)

theorem perm_len64 {l : List Nat} (hp : l.Perm (List.range 64)) : l.length = 64 := by
  simpa using hp.length_eq

theorem getD_lt64 {l : List Nat} (hb : ∀ x ∈ l, x < 64) (hlen : l.length = 64) :
    ∀ j, j < 64 → l.getD j 0 < 64 := by
  intro j hj
  have hjl : j < l.length := by omega
  have : l.getD j 0 = l[j] := by simp [List.getD, List.getElem?_eq_getElem hjl]
  rw [this]; exact hb _ (List.getElem_mem hjl)

theorem c1_getD {l : List Nat} (hlen : l.length = 64) (h1 : c1ok l = true) :
    ∀ i, i < 32 → l.getD (2*i+1) 0 = partner (l.getD (2*i) 0) := by
  intro i hi
  simp only [c1ok, List.all_eq_true, beq_iff_eq] at h1
  have h2i : 2*i < l.length := by omega
  have h2i1 : 2*i+1 < l.length := by omega
  have e1 : l.getD (2*i+1) 99 = l.getD (2*i+1) 0 := by
    simp [List.getD, List.getElem?_eq_getElem h2i1]
  have e2 : l.getD (2*i) 99 = l.getD (2*i) 0 := by
    simp [List.getD, List.getElem?_eq_getElem h2i]
  have := h1 i (List.mem_range.mpr hi)
  rw [e1, e2] at this; exact this

/-- doubling engine (TrigramTheorems.lean within_double, verbatim): for any
    partner-invariant slot predicate p, the even-slot count over a C1-valid
    ordering doubles to the fixed range-64 count. -/
theorem within_double (l : List Nat) (hperm : l.Perm (List.range 64))
    (h1 : c1ok l = true) (p : Nat → Bool) (hp : ∀ h, h < 64 → p (partner h) = p h) :
    2 * ((List.range 32).countP fun i => p (l.getD (2*i) 0)) =
      (List.range 64).countP p := by
  have hb := perm_lt64 hperm
  have hlen := perm_len64 hperm
  have hget := getD_lt64 hb hlen
  have hc1 := c1_getD hlen h1
  have hsplit := countP_even_odd_split l hlen p
  have hodd : ((List.range 32).countP fun i => p (l.getD (2*i+1) 0)) =
      ((List.range 32).countP fun i => p (l.getD (2*i) 0)) := by
    apply List.countP_congr
    intro i hi
    have hi32 := List.mem_range.mp hi
    rw [hc1 i hi32, hp _ (hget (2*i) (by omega))]
  have hcount : l.countP p = (List.range 64).countP p := hperm.countP_eq p
  omega

/- ────────── §2 per-rule slot predicates ──────────
   Each is g(h) := f(h, partner h) where f is the rule's per-pair term read
   off solve.py reg_* / solve.c score_registry, evaluated on the pair whose
   first (even-slot) element is h. C1 guarantees the odd slot is partner(h),
   so the even-slot value determines the pair; orientation invariance
   (§2b, decided over all 64 h) shows the choice of which member sits in the
   even slot cannot change g — i.e. g factors through the unordered pair. -/

/-- pair classified by its even-slot member being palindromic (the compl/inv
    branch guard of reg_mmt4 and reg_s1). -/
def palFirst (h : Nat) : Bool := rev6 h == h

/-- mmt4 compl-branch violation: palindromic-first pair with HD ≠ 6. -/
def mmt4CompViol (h : Nat) : Bool := palFirst h && !(ham h (partner h) == 6)

/-- mmt4 witness that NOT all inversion pairs are HD 6. -/
def mmt4InvNon6 (h : Nat) : Bool := !(palFirst h) && !(ham h (partner h) == 6)

/-- p1c4/r3 guard: both pair members dual/anti-symmetric (rev = comp). -/
def dualPair (h : Nat) : Bool :=
  (rev6 h == h ^^^ 63) && (rev6 (partner h) == partner h ^^^ 63)

/-- p1c4 violation: a dual pair that is not a non-palindromic Inverse pair. -/
def p1c4Viol (h : Nat) : Bool :=
  dualPair h && (!(rev6 h == partner h) || rev6 h == h || rev6 (partner h) == partner h)

/-- s1 compl-branch violation: palindromic-first pair whose XOR ≠ 63. -/
def s1CompViol (h : Nat) : Bool := palFirst h && !((h ^^^ partner h) == 63)

/-- s1 inv-branch violation: inversion pair whose XOR is not a palindrome. -/
def s1InvViol (h : Nat) : Bool :=
  !(palFirst h) && !(rev6 (h ^^^ partner h) == h ^^^ partner h)

/-- s6 within-orbit violation: pair partner outside the K4 orbit {id, comp,
    rev, comp∘rev} of the even-slot member. -/
def s6WithinViol (h : Nat) : Bool :=
  !(partner h == h || partner h == h ^^^ 63 ||
    partner h == rev6 h || partner h == rev6 h ^^^ 63)

/-- K4 orbit of h has size 4 (h neither palindromic nor anti-symmetric). -/
def size4 (h : Nat) : Bool := !(rev6 h == h) && !(rev6 h == h ^^^ 63)

/-- s6 entry violation: a size-4-orbit pair not entered via the rev partner. -/
def s6RevViol (h : Nat) : Bool := size4 h && !(partner h == rev6 h)

/-- s6's orbit census: canonical (minimal) representatives of size-4 orbits. -/
def orbRep4 (h : Nat) : Bool :=
  size4 h && (h ≤ h ^^^ 63) && (h ≤ rev6 h) && (h ≤ rev6 h ^^^ 63)

/-- r3 violation: a dual pair not satisfying partner = rev = comp with HD 6. -/
def r3Viol (h : Nat) : Bool :=
  dualPair h && (!(partner h == rev6 h) || !(rev6 h == h ^^^ 63) ||
                 !(ham h (partner h) == 6))

/-- r5 hw-preservation failure: pair members of unequal popcount. -/
def hwFail (h : Nat) : Bool := !(pc6 h == pc6 (partner h))

/-- r5 shape violation: an hw-failure pair that is not a
    palindrome–complement pair. -/
def r5Viol (h : Nat) : Bool :=
  hwFail h && !((rev6 h == h) && (partner h == h ^^^ 63))

/-- c2/r4 histogram slots: within-pair Hamming distance = v. -/
def hdIs (v h : Nat) : Bool := ham h (partner h) == v

/- ────────── §2b orientation invariance (the factoring step) ──────────
   Each slot predicate takes the same value on both members of every pair:
   g(partner h) = g(h) for ALL h < 64 — decided, not sampled. With
   within_double this is exactly "the rule factors through the unordered
   pair-multiset". -/

theorem palFirst_inv     : ∀ h, h < 64 → palFirst (partner h) = palFirst h := by decide
theorem mmt4CompViol_inv : ∀ h, h < 64 → mmt4CompViol (partner h) = mmt4CompViol h := by decide
theorem mmt4InvNon6_inv  : ∀ h, h < 64 → mmt4InvNon6 (partner h) = mmt4InvNon6 h := by decide
theorem dualPair_inv     : ∀ h, h < 64 → dualPair (partner h) = dualPair h := by decide
theorem p1c4Viol_inv     : ∀ h, h < 64 → p1c4Viol (partner h) = p1c4Viol h := by decide
theorem s1CompViol_inv   : ∀ h, h < 64 → s1CompViol (partner h) = s1CompViol h := by decide
theorem s1InvViol_inv    : ∀ h, h < 64 → s1InvViol (partner h) = s1InvViol h := by decide
theorem s6WithinViol_inv : ∀ h, h < 64 → s6WithinViol (partner h) = s6WithinViol h := by decide
theorem s6RevViol_inv    : ∀ h, h < 64 → s6RevViol (partner h) = s6RevViol h := by decide
theorem r3Viol_inv       : ∀ h, h < 64 → r3Viol (partner h) = r3Viol h := by decide
theorem hwFail_inv       : ∀ h, h < 64 → hwFail (partner h) = hwFail h := by decide
theorem r5Viol_inv       : ∀ h, h < 64 → r5Viol (partner h) = r5Viol h := by decide
theorem hdIs2_inv        : ∀ h, h < 64 → hdIs 2 (partner h) = hdIs 2 h := by decide
theorem hdIs4_inv        : ∀ h, h < 64 → hdIs 4 (partner h) = hdIs 4 h := by decide
theorem hdIs6_inv        : ∀ h, h < 64 → hdIs 6 (partner h) = hdIs 6 h := by decide
theorem hdIs0_inv        : ∀ h, h < 64 → hdIs 0 (partner h) = hdIs 0 h := by decide
theorem hdIs1_inv        : ∀ h, h < 64 → hdIs 1 (partner h) = hdIs 1 h := by decide
theorem hdIs3_inv        : ∀ h, h < 64 → hdIs 3 (partner h) = hdIs 3 h := by decide
theorem hdIs5_inv        : ∀ h, h < 64 → hdIs 5 (partner h) = hdIs 5 h := by decide

/- ────────── §3 the fixed range-64 counts (the finite evaluation) ────────── -/

theorem count_palFirst     : ((List.range 64).countP palFirst) = 8      := by decide
theorem count_mmt4CompViol : ((List.range 64).countP mmt4CompViol) = 0  := by decide
theorem count_mmt4InvNon6  : ((List.range 64).countP mmt4InvNon6) = 48  := by decide
theorem count_dualPair     : ((List.range 64).countP dualPair) = 8      := by decide
theorem count_p1c4Viol     : ((List.range 64).countP p1c4Viol) = 0      := by decide
theorem count_s1CompViol   : ((List.range 64).countP s1CompViol) = 0    := by decide
theorem count_s1InvViol    : ((List.range 64).countP s1InvViol) = 0     := by decide
theorem count_s6WithinViol : ((List.range 64).countP s6WithinViol) = 0  := by decide
theorem count_s6RevViol    : ((List.range 64).countP s6RevViol) = 0     := by decide
theorem count_orbRep4      : ((List.range 64).countP orbRep4) = 12      := by decide
theorem count_r3Viol       : ((List.range 64).countP r3Viol) = 0        := by decide
theorem count_hwFail       : ((List.range 64).countP hwFail) = 8        := by decide
theorem count_r5Viol       : ((List.range 64).countP r5Viol) = 0        := by decide
theorem count_hd0          : ((List.range 64).countP (hdIs 0)) = 0      := by decide
theorem count_hd1          : ((List.range 64).countP (hdIs 1)) = 0      := by decide
theorem count_hd2          : ((List.range 64).countP (hdIs 2)) = 24     := by decide
theorem count_hd3          : ((List.range 64).countP (hdIs 3)) = 0      := by decide
theorem count_hd4          : ((List.range 64).countP (hdIs 4)) = 24     := by decide
theorem count_hd5          : ((List.range 64).countP (hdIs 5)) = 0      := by decide
theorem count_hd6          : ((List.range 64).countP (hdIs 6)) = 16     := by decide

/- ────────── §4 the constancy theorems (EVERY C1-valid ordering) ────────── -/

/-- notation shortcut: the even-slot count of a slot predicate. -/
def pcount (l : List Nat) (p : Nat → Bool) : Nat :=
  (List.range 32).countP fun i => p (l.getD (2*i) 0)

/-- MM-T4 (McKenna & Mair 1979): in EVERY C1-valid ordering there are exactly
    4 palindromic-member pairs, all with intra-pair HD 6, while the 28
    inversion pairs are NOT all HD 6 — i.e. reg_mmt4 = true, constant. -/
theorem mmt4_const (l : List Nat) (hperm : l.Perm (List.range 64))
    (h1 : c1ok l = true) :
    pcount l palFirst = 4 ∧ pcount l mmt4CompViol = 0 ∧
    1 ≤ pcount l mmt4InvNon6 := by
  have ha := within_double l hperm h1 palFirst palFirst_inv
  have hb := within_double l hperm h1 mmt4CompViol mmt4CompViol_inv
  have hc := within_double l hperm h1 mmt4InvNon6 mmt4InvNon6_inv
  rw [count_palFirst] at ha; rw [count_mmt4CompViol] at hb
  rw [count_mmt4InvNon6] at hc
  refine ⟨by unfold pcount; omega, by unfold pcount; omega, by unfold pcount; omega⟩

/-- P1-C4 (Schulz 1982 / Lai Zhide 1599): the 8 dual hexagrams (rev = comp)
    form exactly 4 pairs, every one a non-palindromic Inverse pair —
    reg_p1c4 = true, constant. -/
theorem p1c4_const (l : List Nat) (hperm : l.Perm (List.range 64))
    (h1 : c1ok l = true) :
    pcount l dualPair = 4 ∧ pcount l p1c4Viol = 0 := by
  have ha := within_double l hperm h1 dualPair dualPair_inv
  have hb := within_double l hperm h1 p1c4Viol p1c4Viol_inv
  rw [count_dualPair] at ha; rw [count_p1c4Viol] at hb
  exact ⟨by unfold pcount; omega, by unfold pcount; omega⟩

/-- S1 (Schöter 1998, Definition 9): exactly 4 complement pairs, each XORing
    to 63; every inversion pair XORs to a palindrome — reg_s1 = true,
    constant. -/
theorem s1_const (l : List Nat) (hperm : l.Perm (List.range 64))
    (h1 : c1ok l = true) :
    pcount l palFirst = 4 ∧ pcount l s1CompViol = 0 ∧ pcount l s1InvViol = 0 := by
  have ha := within_double l hperm h1 palFirst palFirst_inv
  have hb := within_double l hperm h1 s1CompViol s1CompViol_inv
  have hc := within_double l hperm h1 s1InvViol s1InvViol_inv
  rw [count_palFirst] at ha; rw [count_s1CompViol] at hb; rw [count_s1InvViol] at hc
  refine ⟨by unfold pcount; omega, by unfold pcount; omega, by unfold pcount; omega⟩

/-- S6 (Schöter / Radisic 2026): every pair lies within one K4 orbit; every
    size-4-orbit pair is entered via the rev partner; and there are 12
    size-4 orbits (a sequence-independent census) — reg_s6 = true, constant. -/
theorem s6_const (l : List Nat) (hperm : l.Perm (List.range 64))
    (h1 : c1ok l = true) :
    pcount l s6WithinViol = 0 ∧ pcount l s6RevViol = 0 ∧
    ((List.range 64).countP orbRep4) = 12 := by
  have ha := within_double l hperm h1 s6WithinViol s6WithinViol_inv
  have hb := within_double l hperm h1 s6RevViol s6RevViol_inv
  rw [count_s6WithinViol] at ha; rw [count_s6RevViol] at hb
  exact ⟨by unfold pcount; omega, by unfold pcount; omega, count_orbRep4⟩

/-- R3 (Radisic 2026, Thm 3.3): exactly 4 anti-symmetric pairs, each with
    partner = rev = comp and intra-pair HD 6 — reg_r3 = true, constant. -/
theorem r3_const (l : List Nat) (hperm : l.Perm (List.range 64))
    (h1 : c1ok l = true) :
    pcount l dualPair = 4 ∧ pcount l r3Viol = 0 := by
  have ha := within_double l hperm h1 dualPair dualPair_inv
  have hb := within_double l hperm h1 r3Viol r3Viol_inv
  rw [count_dualPair] at ha; rw [count_r3Viol] at hb
  exact ⟨by unfold pcount; omega, by unfold pcount; omega⟩

/-- C2-histogram / R4-multiset (Chan 2026 Table 2 proxy; Radisic 2026
    Cor 4.12): in EVERY C1-valid ordering the within-pair HD histogram is
    exactly {2:12, 4:12, 6:8} (all other distances 0) — reg_c2 constant at
    ((2,12),(4,12),(6,8)); hence the total pairing cost reg_r4 is constant
    at 2·12 + 4·12 + 6·8 = 120 and the threshold form total ≤ 120 holds.
    (Independently machine-checked as TrigramTheorems.lean
    within_multiset_general.) -/
theorem c2_hist_const (l : List Nat) (hperm : l.Perm (List.range 64))
    (h1 : c1ok l = true) :
    pcount l (hdIs 0) = 0 ∧ pcount l (hdIs 1) = 0 ∧ pcount l (hdIs 2) = 12 ∧
    pcount l (hdIs 3) = 0 ∧ pcount l (hdIs 4) = 12 ∧ pcount l (hdIs 5) = 0 ∧
    pcount l (hdIs 6) = 8 := by
  have h0 := within_double l hperm h1 (hdIs 0) hdIs0_inv
  have h1' := within_double l hperm h1 (hdIs 1) hdIs1_inv
  have h2 := within_double l hperm h1 (hdIs 2) hdIs2_inv
  have h3 := within_double l hperm h1 (hdIs 3) hdIs3_inv
  have h4 := within_double l hperm h1 (hdIs 4) hdIs4_inv
  have h5 := within_double l hperm h1 (hdIs 5) hdIs5_inv
  have h6 := within_double l hperm h1 (hdIs 6) hdIs6_inv
  rw [count_hd0] at h0; rw [count_hd1] at h1'; rw [count_hd2] at h2
  rw [count_hd3] at h3; rw [count_hd4] at h4; rw [count_hd5] at h5
  rw [count_hd6] at h6
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> unfold pcount <;> omega

/-- R5 (Radisic 2026, Thms 1.1/4.8 witness form): the hw-preservation
    failures are exactly 4, all palindrome–complement pairs — together with
    the histogram theorem (total cost 120), reg_r5 = true, constant. -/
theorem r5_const (l : List Nat) (hperm : l.Perm (List.range 64))
    (h1 : c1ok l = true) :
    pcount l hwFail = 4 ∧ pcount l r5Viol = 0 := by
  have ha := within_double l hperm h1 hwFail hwFail_inv
  have hb := within_double l hperm h1 r5Viol r5Viol_inv
  rw [count_hwFail] at ha; rw [count_r5Viol] at hb
  exact ⟨by unfold pcount; omega, by unfold pcount; omega⟩

/- ────────── §5 sanity anchors ────────── -/

/-- KW itself is C1-valid (guards against a vacuous hypothesis). -/
theorem kw_c1ok : c1ok KW = true := by decide

theorem kw_perm : KW.Perm (List.range 64) := by decide

end C1RuleConstants
