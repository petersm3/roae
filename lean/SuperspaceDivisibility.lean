-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  SuperspaceDivisibility.lean — PART 1 (§0–§34; this header describes Part 1 only): 2^21 * 3
  divides every layer-by-distance-class count of the C1 ∩ C2 ∩ C4 ∩ C5 superspace and its total
  (2026-11-15), 2^19 every per-pair positional count (§28–§34). PART 2 (§35–§46): see its header.
  Core Lean 4 only (no mathlib). KERNEL-ONLY: every finite claim is proved by kernel
  `decide` / `decide +kernel` (zero native_decide; `#print axioms` reports only
  [propext, Classical.choice, Quot.sound] or a subset on every theorem; nothing in this file
  trusts Lean's compiler or native code generator). Standalone: no imports. The definitions
  pc6 / rev6 / partner / ham / KW / transitions / c1ok / c4ok / c5ok are restated verbatim from
  KingWen.lean (the files are standalone; no lake project).

  WHAT IS PROVED (scope exactly as stated; see "WHAT IS NOT PROVED" below)

  A "superspace sequence" is a list l of 64 numbers below 64 that contains every hexagram
  (so: a permutation) and satisfies C1 (`c1ok`), C4 (`c4ok`) and C5 (`c5ok`; C2 follows from
  C5, `c5_implies_c2` in KingWen.lean). C3 is NOT imposed. `isSuper l` says exactly this.
  Boundary k (k = 0..30) is the transition from the second hexagram of pair k to the first
  hexagram of pair k+1; pair 0 is the opening pair (63, 0). `bclass l k` is the Hamming distance
  across boundary k.

    * `cellV2 k d`   — the number of superspace sequences with distance d at boundary k;
    * `superCount`   — the number of superspace sequences.

    theorem cellV2_dvd      : ∀ k d : Nat, 2 ^ 21 * 3 ∣ cellV2 k d
    theorem superCount_dvd  : 2 ^ 21 * 3 ∣ superCount
    theorem cellV2_card_dvd : for ANY duplicate-free list L whose members are exactly the
                              superspace sequences with distance d at boundary k,
                              2 ^ 21 * 3 ∣ L.length     (no reference to `seqs`)
    theorem fibre_dvd       : ∀ σ c : List Nat, 2 ^ 20 ∣ fibre σ c
                              (sequences with a given support skeleton and class sequence)
    theorem fibreC_dvd_general : the coordinate-model fibre is divisible by 2 ^ (22 - b1) for
                              any class sequence over 1, 2, 3, 4, 6 with b1 boundaries of class 1
    theorem fibreP_dvd_general : the same with a weight on one slot: 2 ^ (22 - b1 + m - 3) (Step 7)

  (2 ^ 21 * 3 = 6,291,456.) The first four are stated as `def … : Prop` in §2 (`CellV2Dvd`,
  `SuperCountDvd`, `CellV2CardDvd`, `FibreDvd`), proved in §24, §26, §27; the others in §19, §30.

  Per-pair positional counts (§28–§34). Slot j (j = 0..31) holds the j-th pair of the
  sequence; slot 0 is the opening pair.

    * `cellV1 k h`   — the number of superspace sequences whose pair in slot k+1 is the pair
                       containing the hexagram h (either orientation).

    theorem cellV1_dvd       : ∀ k h : Nat, k < 31 → h < 64 → 2 ^ 19 ∣ cellV1 k h
    theorem cellV1_compl_dvd : ∀ k h : Nat, k < 31 → h < 64 → supp h = 0 → 2 ^ 21 ∣ cellV1 k h
                               (`supp h = 0`: h is its own reversal, so its pair is {h, 63 - h})
    theorem cellV1_tai_dvd   : ∀ k h : Nat, k < 31 → (h = 7 ∨ h = 56) → 2 ^ 19 * 3 ∣ cellV1 k h
    theorem cellV1_card_dvd  : the first of these for ANY duplicate-free list of a cell's members

  They are stated as `def … : Prop` in §28 (`CellV1Dvd`, `CellV1ComplDvd`, `CellV1TaiDvd`,
  `CellV1CardDvd`) and proved in §33 and §34. Non-vacuity: King Wen lies in the cells
  (0, 17), (13, 18) and (4, 7) (`kw_cellV1_pos`, `kw_cellV1_compl_pos`, `kw_cellV1_tai_pos`).

  Non-vacuity (kernel-checked): King Wen is a superspace sequence (`kw_isSuper`) and lies in
  the cell (k, d) = (0, 2) (`kw_cell_pos`), so that cell and the total are positive
  (`superCount_pos`). `mem_seqs` and `seqs_nodup` show that `seqs 64` lists every length-64
  sequence over 0..63 exactly once, so the filtered lengths are cardinalities.

  WHAT IS NOT PROVED

    * The counts are the ones DEFINED IN THIS FILE. Lean does not read any output of the
      project's solver or knowledge compiler; that a published table holds these counts is not
      a statement of this file.
    * "Divides", not "exactly": nothing here says 2^21 * 3 is the largest common divisor.
    * `∀ k d : Nat` is wider than the 31 x 5 table of boundaries k = 0..30 and distances
      d ∈ {1, 2, 3, 4, 6}. The extra instances are true and uninformative: for k ≤ 30 and d
      outside {1, 2, 3, 4, 6} the cell is empty (C5 admits no other distance); for k ≥ 31
      `bclass` returns its default 0, so `cellV2 k 0 = superCount` and every other such cell
      is empty. Of these remarks only `superCount = cellV2 31 0` is a theorem of this file
      (`superCount_eq`; `superCount_dvd` is proved through it).
    * Only one cell of `cellV2`, (0, 2), three cells of `cellV1` and the total are proved
      positive here.
    * The `cellV1` theorems are stated for k < 31 and h < 64 only. They count a PAIR in a slot,
      whichever of its two hexagrams comes first; nothing is proved about the count of one
      hexagram in one position. Nothing here says that 2^19 (or 2^21, or 2^19 * 3) is the
      largest such divisor.
    * Nothing about other constraint sets (C3 is absent), other sizes, or why King Wen. Other
      boundary budgets: only per fibre, no class 5 (`fibreC_dvd_general`, `fibreP_dvd_general`).

  SHAPE OF THE PROOF (the "Step" numbers used in the comments below)

  Coordinates: a hexagram h has an odd support s = `supp h` (which mirror line pairs differ;
  constant on a C1 pair) and a section coordinate t (three bits), h = `hexof s t`. A sequence
  is then a skeleton σ (the support of each of the 32 pairs) with an assignment t of three bits
  to each of the 31 free pairs.

    Step 1  A count of sequences is a sum, over skeletons σ and class sequences c, of
            coordinate-model fibres `fibreC σ c` = the number of assignments t for which the 32
            pairs are distinct and every boundary has its class (§21–§23, `cell_eq`).
    Step 2  The 0/1 factor of a boundary between two different supports has all its Walsh
            coefficients divisible by 2^(3 - e), e = 2 for class 1, else at most 1
            (§7, §17: `gam_walsh6`, `gam_dvd`, `anc_dvd`).
    Step 3  Character expansion, done as an induction: the invariant `TwDiv K h n` ("every
            character-twisted sum of h over the slots K is divisible by 2^n") multiplies over
            disjoint slot sets and loses 3 - m when a boundary factor with Walsh divisibility
            2^m is multiplied in (§4, §5).
    Step 4  A finite table: for each support s the indicator "the four (three, for s = 0) pairs
            of support s are distinct, with prescribed classes at the boundaries between them"
            has every Walsh coefficient divisible by 2^(7 - #internal) (2^(4 - …) for s = 0).
            512 patterns, each a 4096-point (512-point) transform, by `decide +kernel` on a
            packed encoding whose meaning is proved (§1, §3, §6, §8–§12).
    Step 5  Arithmetic from the boundary budget {1:2, 2:8, 3:13, 4:7, 6:1}: the exponents add up
            to at least 53 - (31 + b1) = 20 (§18, §19: `fibreC_dvd`).
    Step 6  The six permutations of the three coordinates act on skeletons without changing
            `fibreC`. A skeleton over which a cell is non-empty contains the supports 1, 2
            and 4, and exactly one of its six images has their first occurrences in increasing
            order (`rsum_one`); so a cell is 6 times a sum of fibres over such representatives,
            which gives the factor 6 = 2 * 3 (§24).
    Step 7  (per-pair positional counts, §28–§34.) Steps 2–5 give more than a count: every
            character-twisted sum of the fibre indicator is divisible by 2^20. So with a weight on
            the coordinate of one slot whose Walsh coefficients are divisible by 2^m, 2^(17 + m)
            still divides (`fibreP_dvd`). Summing a pinned cell over the six coordinate permutations
            as in Step 6 replaces the pin "this pair" by the orbit weight `gamS`, whose Walsh
            coefficients are all divisible by 4 (`gamS_walsh`): 2^(20 + 2 - 3) = 2^19. For a
            complement pair the orbit weight is the constant 2 on the admissible coordinates
            (`gamS_compl`): 2 * 2^20. No new table is needed.

  CONTENTS
    §0   hexagram-level definitions (from KingWen.lean)
    §1   Step 4, the packed Walsh table: definitions
    §2   THE STATEMENTS, and controls on King Wen
    §3   what the packed computation means (`hat`, `allDivF_sound`)
    §4   finite sums over assignments (Step 3's key lemma)
    §5   Step 3 as an induction (`TwDiv`)
    §6   from Walsh coefficients to `TwDiv`, four slots
    §7   Step 2 at hexagram level
    §8   the table indicator in (s, t) coordinates; pruned transform
    §9   the table check in its fast form, with its meaning proved
    §10  THE 512-ENTRY TABLE (kernel)
    §11  the table as a theorem about Walsh coefficients
    §12  three slots; table rows as `TwDiv` statements
    §13  the cross-boundary factor and the class formula
    §14  the coordinate model of a skeleton fibre
    §15  discrimination controls for the table (must-fail claims)
    §16  discrimination controls for the fast form
    §17  general wrappers around Steps 2-4
    §18  book-keeping for a general skeleton
    §19  THE COORDINATE-MODEL FIBRE THEOREM (Steps 2-5)
    §20  controls for the coordinate-model fibre theorem
    §21  sequences to sums, part 1
    §22  sequences to sums, part 2
    §23  sequences to sums, part 3: a cell as a sum of fibres (Step 1)
    §24  THE FACTOR 6 AND THE MAIN THEOREMS (Step 6)
    §25  controls: non-vacuity
    §26  the cardinality reading
    §27  the skeleton-fibre form, for sequences
    §28  THE PER-PAIR POSITIONAL COUNTS (V1): statements
    §29  V1: a pinned count as a sum of pinned fibres
    §30  V1: the pinned fibre theorem
    §31  V1: the coordinate permutations move the pin
    §32  V1: the orbit weight (finite facts)
    §33  THE V1 THEOREMS
    §34  V1: controls and the cardinality reading
  Cost (wall clock and peak RSS of a single `lean SuperspaceDivisibility.lean`, Lean 4.31.0):
  see lean/README.md.
-/

namespace SuperspaceDivisibility

/-! ## §0  Hexagram-level definitions (restated verbatim from KingWen.lean) -/

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

/-! ## §1  Step 4, the packed Walsh table: definitions -/

/-
  §1 — the finite per-support Fourier table of Step 4, kernel-only.

  For each odd support s (8 values) and each internal pattern (64 per support), the 0/1 indicator
  Phi_s of "distinct pairs, prescribed internal boundary classes" on (entry hexagrams)^m
  (m = 4, or 3 for s = 0) has EVERY Walsh coefficient divisible by 2^(mu_free - #internal), where
  mu_free = 7 (4 for s = 0).  512 patterns, each a 4096-point (512-point) transform.

  Encoding: the whole transform lives in ONE natural number (16-bit fields), so the kernel's GMP
  arithmetic does each butterfly stage in a handful of bignum operations.  Stored field at depth d
  is  c + (2^d - 1)  with c the signed coefficient, so no subtraction ever borrows.
  Hexagram-level definitions (partner, ham, pc6) are KingWen.lean's.
-/


/-- 3-bit reversal. -/
def rev3 (x : Nat) : Nat := x % 2 * 4 + x / 2 % 2 * 2 + x / 4 % 2

/-- The hexagram with odd support `s` and section coordinate `t` (line j = t_j,
    line 5-j = t_j xor s_j), s, t < 8. -/
def hexof (s t : Nat) : Nat := t + 8 * rev3 (t ^^^ s)

/-- odd support of a hexagram: s_j = line j xor line 5-j. -/
def supp (h : Nat) : Nat := (h % 8) ^^^ rev3 (h / 8)

/-- same King Wen pair (C1 pair = {h, partner h}). -/
def samePair (a b : Nat) : Bool := a == b || a == partner b

/-- internal boundary: slot with entry `a` (exit = partner a) directly followed by entry `b`,
    prescribed class g; g = 0 means "not adjacent, no constraint". -/
def gapOk (g a b : Nat) : Bool := g == 0 || ham (partner a) b == g

/-- Phi_s for a reversible support (s = 1..7): four slots. -/
def indR (s g1 g2 g3 t1 t2 t3 t4 : Nat) : Bool :=
  !samePair (hexof s t1) (hexof s t2) && gapOk g1 (hexof s t1) (hexof s t2) &&
  !samePair (hexof s t2) (hexof s t3) && gapOk g2 (hexof s t2) (hexof s t3) &&
  !samePair (hexof s t1) (hexof s t3) &&
  !samePair (hexof s t3) (hexof s t4) && gapOk g3 (hexof s t3) (hexof s t4) &&
  !samePair (hexof s t1) (hexof s t4) && !samePair (hexof s t2) (hexof s t4)

/-- Phi_0 for the complement pairs (s = 0): three slots, none in the anchor pair {63, 0};
    `an` is the class of the anchor boundary (exit 0 -> first entry) or 0 if not adjacent. -/
def indC (an g1 g2 t1 t2 t3 : Nat) : Bool :=
  !samePair (hexof 0 t1) 63 && (an == 0 || ham 0 (hexof 0 t1) == an) &&
  !samePair (hexof 0 t2) 63 && !samePair (hexof 0 t1) (hexof 0 t2) && gapOk g1 (hexof 0 t1) (hexof 0 t2) &&
  !samePair (hexof 0 t3) 63 && !samePair (hexof 0 t2) (hexof 0 t3) && gapOk g2 (hexof 0 t2) (hexof 0 t3) &&
  !samePair (hexof 0 t1) (hexof 0 t3)

/-- 2^d fields of value 1, 16 bits apart. -/
def ones (d : Nat) : Nat := (2 ^ (16 * 2 ^ d) - 1) / 65535

/-- packed, biased Walsh transform of f on the 2^d indices pre*2^d .. pre*2^d + 2^d - 1.
    Field u (big-endian) holds  (sum_t f(t) (-1)^(u.t)) + 2^d - 1. -/
def P (f : Nat → Bool) : Nat → Nat → Nat
  | 0, pre => if f pre then 1 else 0
  | d+1, pre =>
      (P f d (2*pre) + P f d (2*pre+1) + ones d) +
      (P f d (2*pre) + (2 ^ (d+1) - 1) * ones d - P f d (2*pre+1)) * 2 ^ (16 * 2 ^ d)

/-- every one of the 2^d coefficients is divisible by 2^m (m <= d): stored + 1 = c + 2^d. -/
def allDiv (m d R : Nat) : Bool := (R + ones d) &&& ((2 ^ m - 1) * ones d) == 0

def cost (g : Nat) : Nat := if g == 0 then 0 else 1

def patR (s g1 g2 g3 : Nat) : Bool :=
  allDiv (7 - cost g1 - cost g2 - cost g3) 12
    (P (fun i => indR s g1 g2 g3 (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)) 12 0)

def patC (an g1 g2 : Nat) : Bool :=
  allDiv (4 - cost an - cost g1 - cost g2) 9
    (P (fun i => indC an g1 g2 (i / 64 % 8) (i / 8 % 8) (i % 8)) 9 0)

def cls : List Nat := [0, 2, 4, 6]

def rowR (s : Nat) : Bool := cls.all fun g1 => cls.all fun g2 => cls.all fun g3 => patR s g1 g2 g3
def rowC : Bool := cls.all fun an => cls.all fun g1 => cls.all fun g2 => patC an g1 g2

/-! ## §2  THE STATEMENTS, and controls on King Wen -/

/-
  §2 — the theorems STATED over KingWen.lean's definitions (§0).
  This part only states: the four statements below are `def ... : Prop`, and the only theorems
  here are the sanity controls at the end.  The statements are proved elsewhere:

    CellV2Dvd      in §24  (`cellV2_dvd`)
    SuperCountDvd  in §24  (`superCount_dvd`)
    CellV2CardDvd  in §26  (`cellV2_card_dvd`)
    FibreDvd       in §27  (`fibre_dvd`)

  The count is the abstract one: lists of 64 numbers below 64 that contain every hexagram
  (so: permutations), satisfy C1 (`c1ok`), C4 (`c4ok`) and C5 (`c5ok`; C2 follows by
  `c5_implies_c2` in KingWen.lean).  `seqs 64` has 64^64 members and is never evaluated.  The theorems say
  "divides"; they do not say the power of two is exact.
-/

/-- all lists of length n over 0..63. -/
def seqs : Nat → List (List Nat)
  | 0 => [[]]
  | n+1 => (seqs n).flatMap fun l => (List.range 64).map (· :: l)

/-- the n=31 superspace C1 ∩ C2 ∩ C4 ∩ C5 (no C3): a permutation of the 64 hexagrams. -/
def isSuper (l : List Nat) : Bool :=
  ((List.range 64).all fun h => l.contains h) && c1ok l && c4ok l && c5ok l

/-- class of boundary k (between pair k and pair k+1), k = 0..30. -/
def bclass (l : List Nat) (k : Nat) : Nat := (transitions l).getD (2*k+1) 0

/-- the class sequence c_0..c_30. -/
def bseq (l : List Nat) : List Nat := (List.range 31).map (bclass l)

/-- the support skeleton: odd support of the pair in each of the 32 slots. -/
def skel (l : List Nat) : List Nat := (List.range 32).map fun i => supp (l.getD (2*i) 0)

/-- F(s•, c): the skeleton fibre. -/
def fibre (σ c : List Nat) : Nat :=
  ((seqs 64).filter fun l => isSuper l && skel l == σ && bseq l == c).length

/-- V2 cell (k, d): boundary k has class d. -/
def cellV2 (k d : Nat) : Nat := ((seqs 64).filter fun l => isSuper l && bclass l k == d).length

def superCount : Nat := ((seqs 64).filter isSuper).length

/-- every skeleton fibre is divisible by 2^20.  Proved: `fibre_dvd` (§27);
    not used by the V2 theorem. -/
def FibreDvd : Prop := ∀ σ c : List Nat, 2 ^ 20 ∣ fibre σ c

/-- THE V2 THEOREM: every V2 cell is divisible by 2^21 * 3.  Proved: `cellV2_dvd`
    (§24). -/
def CellV2Dvd : Prop := ∀ k d : Nat, 2 ^ 21 * 3 ∣ cellV2 k d

/-- so is the total.  Proved: `superCount_dvd` (§24). -/
def SuperCountDvd : Prop := 2 ^ 21 * 3 ∣ superCount

/-- The cardinality reading, for a reader who distrusts `seqs`: ANY duplicate-free list L whose
    members are exactly the superspace sequences with class d at boundary k has length divisible
    by 2^21 * 3.  Proved: `cellV2_card_dvd` (§26). -/
def CellV2CardDvd : Prop := ∀ (k d : Nat) (L : List (List Nat)), L.Nodup →
  (∀ l, l ∈ L ↔ (l.length = 64 ∧ (∀ x ∈ l, x < 64) ∧ isSuper l = true ∧ bclass l k = d)) →
  2 ^ 21 * 3 ∣ L.length

/- ---- sanity controls: the definitions say what they should on King Wen itself ---- -/
theorem kw_isSuper : isSuper KW = true := by decide +kernel
theorem kw_bseq : bseq KW =
    [2,4,3,4,4,2,4,2,3,3,2,3,2,2,3,3,4,2,6,3,4,3,3,3,4,1,2,3,3,1,3] := by decide +kernel
theorem kw_skel : skel KW = [0,3,5,2,4,7,2,4,7,3,4,1,6,0,0,2,3,5,6,6,2,1,6,4,3,5,7,1,5,1,0,7] := by decide +kernel
theorem seqs_2_length : (seqs 2).length = 4096 := by decide +kernel

/-! ## §3  what the packed computation means (`hat`, `allDivF_sound`) -/

/-
  §3 — what the packed kernel computation of §1 MEANS.

  `hat f d pre u` is the Walsh coefficient  sum_{t < 2^d} [f (pre*2^d + t)] * (-1)^(u.t),
  defined by splitting on the top index bit (no packing, no bias, integers).
  Theorem `allDivF_sound`: if the field-by-field check passes on the packed number `P f d pre`,
  then 2^m divides `hat f d pre u` for EVERY character u < 2^d.
-/

/-- the Walsh coefficient, by recursion on the top bit. -/
def hat (f : Nat → Bool) : Nat → Nat → Nat → Int
  | 0, pre, _ => if f pre then 1 else 0
  | d+1, pre, u =>
      if u < 2 ^ d then hat f d (2*pre) u + hat f d (2*pre+1) u
      else hat f d (2*pre) (u - 2 ^ d) - hat f d (2*pre+1) (u - 2 ^ d)

/-- the biased coefficient the packed number stores (natural numbers). -/
def bh (f : Nat → Bool) : Nat → Nat → Nat → Nat
  | 0, pre, _ => if f pre then 1 else 0
  | d+1, pre, u =>
      if u < 2 ^ d then bh f d (2*pre) u + bh f d (2*pre+1) u + 1
      else bh f d (2*pre) (u - 2 ^ d) + (2 ^ (d+1) - 1) - bh f d (2*pre+1) (u - 2 ^ d)

/-- sum_{u<n} a u * 2^(16 u). -/
def packFn : Nat → (Nat → Nat) → Nat
  | 0, _ => 0
  | n+1, a => packFn n a + a n * 2 ^ (16 * n)

theorem packFn_congr {n : Nat} {a b : Nat → Nat} (h : ∀ u < n, a u = b u) :
    packFn n a = packFn n b := by
  induction n with
  | zero => rfl
  | succ n ih =>
    show packFn n a + a n * _ = packFn n b + b n * _
    rw [ih (fun u hu => h u (Nat.lt_succ_of_lt hu)), h n (Nat.lt_succ_self n)]

theorem packFn_add (n : Nat) (a b : Nat → Nat) :
    packFn n (fun u => a u + b u) = packFn n a + packFn n b := by
  induction n with
  | zero => rfl
  | succ n ih =>
    show packFn n (fun u => a u + b u) + (a n + b n) * _ = (packFn n a + a n * _) + (packFn n b + b n * _)
    rw [ih, Nat.add_mul]; omega

theorem packFn_mul (n c : Nat) (a : Nat → Nat) :
    packFn n (fun u => c * a u) = c * packFn n a := by
  induction n with
  | zero => rfl
  | succ n ih =>
    show packFn n (fun u => c * a u) + (c * a n) * _ = c * (packFn n a + a n * _)
    rw [ih, Nat.mul_add, Nat.mul_assoc]

theorem packFn_mono {n : Nat} {a b : Nat → Nat} (h : ∀ u < n, b u ≤ a u) :
    packFn n b ≤ packFn n a := by
  induction n with
  | zero => exact Nat.le_refl _
  | succ n ih =>
    show packFn n b + b n * _ ≤ packFn n a + a n * _
    exact Nat.add_le_add (ih fun u hu => h u (Nat.lt_succ_of_lt hu))
      (Nat.mul_le_mul_right _ (h n (Nat.lt_succ_self n)))

theorem packFn_sub {n : Nat} {a b : Nat → Nat} (h : ∀ u < n, b u ≤ a u) :
    packFn n (fun u => a u - b u) = packFn n a - packFn n b := by
  induction n with
  | zero => rfl
  | succ n ih =>
    have h' : ∀ u < n, b u ≤ a u := fun u hu => h u (Nat.lt_succ_of_lt hu)
    have hm := packFn_mono h'
    have hn : b n * 2 ^ (16 * n) ≤ a n * 2 ^ (16 * n) :=
      Nat.mul_le_mul_right _ (h n (Nat.lt_succ_self n))
    show packFn n (fun u => a u - b u) + (a n - b n) * _ = (packFn n a + a n * _) - (packFn n b + b n * _)
    rw [ih h', Nat.sub_mul]; omega

theorem packFn_split (n m : Nat) (a : Nat → Nat) :
    packFn (n + m) a = packFn n a + packFn m (fun u => a (n + u)) * 2 ^ (16 * n) := by
  induction m with
  | zero => show packFn n a = packFn n a + 0 * _; omega
  | succ m ih =>
    show packFn (n + m) a + a (n + m) * 2 ^ (16 * (n + m)) =
      packFn n a + (packFn m (fun u => a (n + u)) + a (n + m) * 2 ^ (16 * m)) * 2 ^ (16 * n)
    have e : 2 ^ (16 * (n + m)) = 2 ^ (16 * m) * 2 ^ (16 * n) := by
      rw [← Nat.pow_add]; congr 1; omega
    rw [ih, e, Nat.add_mul, Nat.mul_assoc]; omega

theorem geom_step (c X Y : Nat) (ih : X * c + 1 = Y) : (X + 1 * Y) * c + 1 = Y * (c + 1) := by
  rw [Nat.one_mul, Nat.add_mul, Nat.mul_add, Nat.mul_one, ← ih]
  generalize X * c = A
  generalize (A + 1) * c = B
  omega

theorem packFn_one (n : Nat) : packFn n (fun _ => 1) * 65535 + 1 = 2 ^ (16 * n) := by
  induction n with
  | zero => rfl
  | succ n ih =>
    show (packFn n (fun _ => 1) + 1 * 2 ^ (16 * n)) * 65535 + 1 = 2 ^ (16 * (n + 1))
    have e : 2 ^ (16 * (n + 1)) = 2 ^ (16 * n) * 65536 := by
      rw [Nat.mul_add, Nat.pow_add]
    rw [e]
    exact geom_step 65535 _ _ ih

theorem ones_eq (d : Nat) : ones d = packFn (2 ^ d) (fun _ => 1) := by
  have h := packFn_one (2 ^ d)
  have hpos : 0 < 65535 := by omega
  show (2 ^ (16 * 2 ^ d) - 1) / 65535 = _
  have e : 2 ^ (16 * 2 ^ d) - 1 = packFn (2 ^ d) (fun _ => 1) * 65535 := by omega
  rw [e]
  exact Nat.mul_div_cancel (packFn (2 ^ d) (fun _ => 1)) hpos

/-- the packed number is exactly the pack of the biased coefficients, as long as nothing
    borrows (the bound hypothesis; discharged below). -/
theorem P_eq_pack (f : Nat → Bool)
    (hb : ∀ d pre u, u < 2 ^ d → bh f d pre u ≤ 2 ^ (d+1) - 1) :
    ∀ d pre, P f d pre = packFn (2 ^ d) (bh f d pre) := by
  intro d
  induction d with
  | zero => intro pre; show _ = 0 + _ * 2 ^ (16 * 0); simp [P, bh]
  | succ d ih =>
    intro pre
    have e2 : 2 ^ (d + 1) = 2 ^ d + 2 ^ d := by rw [Nat.pow_succ]; omega
    show (P f d (2*pre) + P f d (2*pre+1) + ones d) +
      (P f d (2*pre) + (2 ^ (d+1) - 1) * ones d - P f d (2*pre+1)) * 2 ^ (16 * 2 ^ d) = _
    rw [ih, ih, ones_eq, e2, packFn_split]
    have lo : packFn (2 ^ d) (bh f (d+1) pre) =
        packFn (2 ^ d) (bh f d (2*pre)) + packFn (2 ^ d) (bh f d (2*pre+1)) + packFn (2 ^ d) (fun _ => 1) := by
      rw [← packFn_add, ← packFn_add]
      exact packFn_congr fun u hu => by simp [bh, hu]
    have hi : packFn (2 ^ d) (fun u => bh f (d+1) pre (2 ^ d + u)) =
        packFn (2 ^ d) (bh f d (2*pre)) + (2 ^ d + 2 ^ d - 1) * packFn (2 ^ d) (fun _ => 1)
          - packFn (2 ^ d) (bh f d (2*pre+1)) := by
      rw [← packFn_mul, ← packFn_add, ← packFn_sub]
      · exact packFn_congr fun u hu => by
          have : ¬ (2 ^ d + u < 2 ^ d) := by omega
          simp [bh, this, e2]
      · intro u hu
        have := hb d (2*pre+1) u hu
        omega
    rw [lo, hi]

theorem packFn_lt {n : Nat} {a : Nat → Nat} (h : ∀ u < n, a u < 65536) :
    packFn n a < 2 ^ (16 * n) := by
  induction n with
  | zero => exact Nat.one_pos
  | succ n ih =>
    have := ih fun u hu => h u (Nat.lt_succ_of_lt hu)
    have hn := h n (Nat.lt_succ_self n)
    have e : 2 ^ (16 * (n + 1)) = 2 ^ (16 * n) * 65536 := by rw [Nat.mul_add, Nat.pow_add]
    show packFn n a + a n * 2 ^ (16 * n) < _
    rw [e]
    have : a n * 2 ^ (16 * n) ≤ 65535 * 2 ^ (16 * n) := Nat.mul_le_mul_right _ (by omega)
    omega

/-- field extraction. -/
theorem packFn_field {n : Nat} {a : Nat → Nat} (h : ∀ u < n, a u < 65536) :
    ∀ u < n, packFn n a / 2 ^ (16 * u) % 65536 = a u := by
  induction n with
  | zero => intro u hu; omega
  | succ n ih =>
    intro u hu
    have h' : ∀ u < n, a u < 65536 := fun u hu => h u (Nat.lt_succ_of_lt hu)
    show (packFn n a + a n * 2 ^ (16 * n)) / 2 ^ (16 * u) % 65536 = a u
    by_cases hun : u = n
    · subst hun
      rw [Nat.add_mul_div_right _ _ (Nat.two_pow_pos _), Nat.div_eq_of_lt (packFn_lt h'), Nat.zero_add]
      exact Nat.mod_eq_of_lt (h u hu)
    · have hlt : u < n := by omega
      have e : a n * 2 ^ (16 * n) = 2 ^ (16 * u) * (a n * 2 ^ (16 * (n - u - 1)) * 65536) := by
        have : 2 ^ (16 * n) = 2 ^ (16 * u) * (2 ^ (16 * (n - u - 1)) * 65536) := by
          rw [show (65536 : Nat) = 2 ^ 16 from rfl, ← Nat.pow_add, ← Nat.pow_add]; congr 1; omega
        rw [this, Nat.mul_left_comm, Nat.mul_assoc]
      rw [e, Nat.add_mul_div_left _ _ (Nat.two_pow_pos _), Nat.add_mul_mod_self_right]
      exact ih h' u hlt

/-- link between the biased naturals and the signed coefficients, with the size bound. -/
theorem bh_hat (f : Nat → Bool) : ∀ d pre u,
    (bh f d pre u : Int) = hat f d pre u + (2 ^ d : Nat) - 1 ∧
    -((2 ^ d : Nat) : Int) ≤ hat f d pre u ∧ hat f d pre u ≤ ((2 ^ d : Nat) : Int) := by
  intro d
  induction d with
  | zero => intro pre u; cases hf : f pre <;> simp [bh, hat, hf]
  | succ d ih =>
    intro pre u
    have e2 : 2 ^ (d + 1) = 2 ^ d + 2 ^ d := by rw [Nat.pow_succ]; omega
    by_cases hu : u < 2 ^ d
    · obtain ⟨a1, a2, a3⟩ := ih (2*pre) u
      obtain ⟨b1, b2, b3⟩ := ih (2*pre+1) u
      simp only [bh, hat, hu, if_true, e2]
      refine ⟨?_, ?_, ?_⟩ <;> omega
    · obtain ⟨a1, a2, a3⟩ := ih (2*pre) (u - 2 ^ d)
      obtain ⟨b1, b2, b3⟩ := ih (2*pre+1) (u - 2 ^ d)
      simp only [bh, hat, hu, if_false, e2]
      refine ⟨?_, ?_, ?_⟩ <;> omega

theorem bh_le (f : Nat → Bool) (d pre u : Nat) : bh f d pre u ≤ 2 ^ (d+1) - 1 := by
  obtain ⟨a1, _, a3⟩ := bh_hat f d pre u
  have e2 : 2 ^ (d + 1) = 2 ^ d + 2 ^ d := by rw [Nat.pow_succ]; omega
  have : 0 < 2 ^ d := Nat.two_pow_pos d
  omega

/-- field-by-field check (the form whose meaning is proved; `allDiv` is the one-mask variant). -/
def allDivF (m d R : Nat) : Bool :=
  (List.range (2 ^ d)).all fun u => (R / 2 ^ (16 * u) % 65536 + 1) % 2 ^ m == 0

/-- SOUNDNESS OF THE TABLE CHECK: a passing packed check means 2^m divides every Walsh
    coefficient of f on the block. -/
theorem allDivF_sound (f : Nat → Bool) (m d pre : Nat) (hd : d ≤ 14) (hm : m ≤ d)
    (h : allDivF m d (P f d pre) = true) :
    ∀ u < 2 ^ d, ((2 ^ m : Nat) : Int) ∣ hat f d pre u := by
  intro u hu
  have hP := P_eq_pack f (fun d pre u _ => bh_le f d pre u) d pre
  have hpow : 2 ^ (d + 1) ≤ 2 ^ 15 := Nat.pow_le_pow_right (by decide) (by omega)
  have hfld := packFn_field (n := 2 ^ d) (a := bh f d pre)
    (fun u _ => by have := bh_le f d pre u; omega) u hu
  have hc := (List.all_eq_true.mp h) u (List.mem_range.mpr hu)
  rw [hP, hfld] at hc
  have hmod : (bh f d pre u + 1) % 2 ^ m = 0 := by simpa using hc
  obtain ⟨a1, _, _⟩ := bh_hat f d pre u
  have hdvd1 : (2 ^ m : Nat) ∣ bh f d pre u + 1 := Nat.dvd_of_mod_eq_zero hmod
  have hdvd2 : (2 ^ m : Nat) ∣ 2 ^ d := Nat.pow_dvd_pow 2 hm
  have i1 : ((2 ^ m : Nat) : Int) ∣ ((bh f d pre u + 1 : Nat) : Int) := Int.natCast_dvd_natCast.mpr hdvd1
  have i2 : ((2 ^ m : Nat) : Int) ∣ ((2 ^ d : Nat) : Int) := Int.natCast_dvd_natCast.mpr hdvd2
  have e : hat f d pre u = ((bh f d pre u + 1 : Nat) : Int) - ((2 ^ d : Nat) : Int) := by omega
  rw [e]; exact Int.dvd_sub i1 i2

/-! ## §4  finite sums over assignments (Step 3's key lemma) -/

/-
  §4 — the key lemma of Step 3, in Lean core (no Mathlib):
  a finite sum over assignments  t : slots -> F_2^3  of a product of factors that depend on
  DISJOINT sets of slots is the product of the separate sums; and the sum does not depend on the
  order in which the slots are summed (so an arbitrary interleaving of the support classes
  K_s along the walk can be sorted class by class).

  This is the "sum over a product set factorises" step.  Everything here is general
  (no hexagrams); the only finite fact is the size 8 of the alphabet.
-/

/-- an assignment of a value (0..7 = an element of F_2^3) to every slot. -/
abbrev Asg := Nat → Nat

def upd (t : Asg) (k v : Nat) : Asg := fun j => if j = k then v else t j

/-- sum over the 8 values of one slot. -/
def sum8 (F : Nat → Int) : Int := F 0 + F 1 + F 2 + F 3 + F 4 + F 5 + F 6 + F 7

/-- sum of F over all assignments to the slots in K (other slots as in t). -/
def sumOver : List Nat → (Asg → Int) → Asg → Int
  | [], F, t => F t
  | k :: K, F, t => sum8 fun v => sumOver K F (upd t k v)

theorem sum8_congr {F G : Nat → Int} (h : ∀ v, F v = G v) : sum8 F = sum8 G := by
  simp only [sum8, h]

theorem sum8_mul_right (F : Nat → Int) (c : Int) : sum8 (fun v => F v * c) = sum8 F * c := by
  simp only [sum8, Int.add_mul]

theorem sum8_mul_left (c : Int) (F : Nat → Int) : sum8 (fun v => c * F v) = c * sum8 F := by
  simp only [sum8, Int.mul_add]

theorem sum8_add (F G : Nat → Int) : sum8 (fun v => F v + G v) = sum8 F + sum8 G := by
  simp only [sum8]; omega

theorem sum8_comm (F : Nat → Nat → Int) :
    sum8 (fun v => sum8 fun w => F v w) = sum8 (fun w => sum8 fun v => F v w) := by
  simp only [sum8]; omega

theorem sum8_dvd (d : Int) (F : Nat → Int) (h : ∀ v, d ∣ F v) : d ∣ sum8 F := by
  simp only [sum8]
  repeat (first | exact h _ | apply Int.dvd_add)

theorem sumOver_congr (K : List Nat) {F G : Asg → Int} (h : ∀ t, F t = G t) (t : Asg) :
    sumOver K F t = sumOver K G t := by
  induction K generalizing t with
  | nil => exact h t
  | cons k K ih => exact sum8_congr fun v => ih _

theorem sumOver_add (K : List Nat) (F G : Asg → Int) (t : Asg) :
    sumOver K (fun t => F t + G t) t = sumOver K F t + sumOver K G t := by
  induction K generalizing t with
  | nil => rfl
  | cons k K ih =>
    show sum8 (fun v => sumOver K (fun t => F t + G t) (upd t k v)) = _
    rw [sum8_congr (fun v => ih (upd t k v)), sum8_add]; rfl

theorem sumOver_dvd (d : Int) (K : List Nat) (F : Asg → Int) (h : ∀ t, d ∣ F t) (t : Asg) :
    d ∣ sumOver K F t := by
  induction K generalizing t with
  | nil => exact h t
  | cons k K ih => exact sum8_dvd d _ fun v => ih _

/-- f ignores slot k. -/
def Indep (f : Asg → Int) (k : Nat) : Prop := ∀ t v, f (upd t k v) = f t

theorem sumOver_mul_left_of_indep (K : List Nat) (f g : Asg → Int)
    (hf : ∀ k ∈ K, Indep f k) (t : Asg) :
    sumOver K (fun t => f t * g t) t = f t * sumOver K g t := by
  induction K generalizing t with
  | nil => rfl
  | cons k K ih =>
    have hK : ∀ j ∈ K, Indep f j := fun j hj => hf j (List.mem_cons_of_mem _ hj)
    show sum8 (fun v => sumOver K (fun t => f t * g t) (upd t k v)) =
         f t * sum8 (fun v => sumOver K g (upd t k v))
    rw [← sum8_mul_left]
    exact sum8_congr fun v => by rw [ih hK, hf k List.mem_cons_self]

theorem upd_comm (t : Asg) {j k : Nat} (h : j ≠ k) (v w : Nat) :
    upd (upd t j v) k w = upd (upd t k w) j v := by
  funext i
  simp only [upd]
  by_cases h1 : i = k
  · by_cases h2 : i = j
    · exact absurd (h2.symm.trans h1) h
    · simp [h1, Ne.symm h]
  · by_cases h2 : i = j
    · simp [h2, h]
    · simp [h1, h2]

theorem sumOver_upd_of_indep (K : List Nat) (g : Asg → Int) (k : Nat) (hk : k ∉ K)
    (hg : Indep g k) (t : Asg) (v : Nat) :
    sumOver K g (upd t k v) = sumOver K g t := by
  induction K generalizing t with
  | nil => exact hg t v
  | cons j K ih =>
    have hjk : k ≠ j := fun e => hk (e ▸ List.mem_cons_self)
    have hK : k ∉ K := fun m => hk (List.mem_cons_of_mem _ m)
    show sum8 (fun w => sumOver K g (upd (upd t k v) j w)) = sum8 (fun w => sumOver K g (upd t j w))
    exact sum8_congr fun w => by rw [upd_comm t hjk, ih hK]

/-- KEY LEMMA (Step 3): factors living on disjoint slot sets sum independently. -/
theorem sumOver_append_mul (K K' : List Nat) (f g : Asg → Int)
    (hf : ∀ k ∈ K', Indep f k) (hg : ∀ k ∈ K, Indep g k) (hd : ∀ k ∈ K, k ∉ K') (t : Asg) :
    sumOver (K ++ K') (fun t => f t * g t) t = sumOver K f t * sumOver K' g t := by
  induction K generalizing t with
  | nil => exact sumOver_mul_left_of_indep K' f g hf t
  | cons k K ih =>
    show sum8 (fun v => sumOver (K ++ K') (fun t => f t * g t) (upd t k v)) =
         sum8 (fun v => sumOver K f (upd t k v)) * sumOver K' g t
    rw [← sum8_mul_right]
    apply sum8_congr; intro v
    rw [ih (fun j hj => hg j (List.mem_cons_of_mem _ hj)) (fun j hj => hd j (List.mem_cons_of_mem _ hj)),
        sumOver_upd_of_indep K' g k (hd k List.mem_cons_self) (hg k List.mem_cons_self)]

theorem sumOver_swap (j k : Nat) (K : List Nat) (F : Asg → Int) (t : Asg) :
    sumOver (j :: k :: K) F t = sumOver (k :: j :: K) F t := by
  by_cases h : j = k
  · subst h; rfl
  · show sum8 (fun v => sum8 fun w => sumOver K F (upd (upd t j v) k w)) =
         sum8 (fun w => sum8 fun v => sumOver K F (upd (upd t k w) j v))
    rw [sum8_comm]
    exact sum8_congr fun w => sum8_congr fun v => by rw [upd_comm t h]

/-- the order of summation over slots is irrelevant (Fubini for finite sums). -/
theorem sumOver_perm {K K' : List Nat} (h : K.Perm K') (F : Asg → Int) (t : Asg) :
    sumOver K F t = sumOver K' F t := by
  induction h generalizing t with
  | nil => rfl
  | cons k _ ih => exact sum8_congr fun v => ih _
  | swap j k K => exact sumOver_swap k j K F t
  | trans _ _ ih1 ih2 => exact (ih1 t).trans (ih2 t)

/-- Interchange with an outer finite sum (the sum over the characters w). -/
theorem sumOver_sum8 (K : List Nat) (F : Nat → Asg → Int) (t : Asg) :
    sumOver K (fun t => sum8 fun w => F w t) t = sum8 fun w => sumOver K (F w) t := by
  induction K generalizing t with
  | nil => rfl
  | cons k K ih =>
    show sum8 (fun v => sumOver K (fun t => sum8 fun w => F w t) (upd t k v)) =
         sum8 (fun w => sum8 fun v => sumOver K (F w) (upd t k v))
    rw [sum8_comm]
    exact sum8_congr fun v => ih _

/-- the characters of F_2^3 on values 0..7. -/
def par3 (x : Nat) : Nat := (x % 2 + x / 2 % 2 + x / 4 % 2) % 2
def chi (u t : Nat) : Int := if par3 (u &&& t) = 0 then 1 else -1

theorem chi_mul_right : ∀ u < 8, ∀ t < 8, ∀ t' < 8, chi u (t ^^^ t') = chi u t * chi u t' := by decide
theorem chi_mul_left : ∀ u < 8, ∀ u' < 8, ∀ t < 8, chi (u ^^^ u') t = chi u t * chi u' t := by decide
/-- orthogonality / Fourier inversion kernel on F_2^3. -/
theorem chi_orth : ∀ t < 8, sum8 (fun u => chi u t) = if t = 0 then 8 else 0 := by decide

/-- Fourier inversion on one slot: 8 * g(t) = sum_w ghat(w) chi_w(t), ghat(w) = sum_v g(v) chi_w(v). -/
theorem fourier_inv8 (g : Nat → Int) : ∀ t < 8,
    8 * g t = sum8 fun w => (sum8 fun v => g v * chi w v) * chi w t := by
  intro t ht
  have : ∀ t < 8, ∀ (a0 a1 a2 a3 a4 a5 a6 a7 : Int),
      8 * (match t with | 0 => a0 | 1 => a1 | 2 => a2 | 3 => a3 | 4 => a4 | 5 => a5 | 6 => a6 | _ => a7) =
      sum8 fun w => (sum8 fun v => (match v with | 0 => a0 | 1 => a1 | 2 => a2 | 3 => a3 | 4 => a4 | 5 => a5 | 6 => a6 | _ => a7) * chi w v) * chi w t := by
    intro t ht a0 a1 a2 a3 a4 a5 a6 a7
    have h8 : t = 0 ∨ t = 1 ∨ t = 2 ∨ t = 3 ∨ t = 4 ∨ t = 5 ∨ t = 6 ∨ t = 7 := by omega
    rcases h8 with h | h | h | h | h | h | h | h <;> subst h <;>
      simp [sum8, chi, par3] <;> omega
  have key := this t ht (g 0) (g 1) (g 2) (g 3) (g 4) (g 5) (g 6) (g 7)
  have h8 : t = 0 ∨ t = 1 ∨ t = 2 ∨ t = 3 ∨ t = 4 ∨ t = 5 ∨ t = 6 ∨ t = 7 := by omega
  rcases h8 with h | h | h | h | h | h | h | h <;> subst h <;> simpa [sum8] using key

/-! ## §5  Step 3 as an induction (`TwDiv`) -/

/-
  §5 — Step 3 as an INDUCTION, in Lean core (no Mathlib).

  Instead of expanding all cross factors at once into a sum over 31-tuples of characters, keep one
  invariant and add the cross boundaries one at a time:

    TwDiv K h n  :=  every character-twisted sum of h over the slots K is divisible by 2^n.

  * `twdiv_append`  : factors on disjoint slot sets multiply, exponents add (the base case:
                      the product of the per-support indicators Phi_s has exponent sum mu_s);
  * `twdiv_cross`   : multiplying by a cross-boundary factor gamma(t_a xor t_b) whose Walsh
                      coefficients are divisible by 2^m lowers the exponent by 3 - m  (= e_k);
  * `twdiv_slot`    : same for a one-slot factor (the anchor boundary);
  * `twdiv_count`   : the untwisted sum (u = 0) is the count, so 2^n divides it.

  Together these are the whole analytic content of Steps 2-3; what is left of the proof is
  combinatorial book-keeping (§18 onwards).
-/

/-- characters and their shift, total on Nat (only the low three bits are read). -/
def chi' (u t : Nat) : Int := chi (u % 8) (t % 8)
def cx (a b : Nat) : Nat := (a % 8) ^^^ (b % 8)

theorem cx_lt (a b : Nat) : cx a b < 8 := by
  have key : ∀ x < 8, ∀ y < 8, x ^^^ y < 8 := by decide
  exact key _ (Nat.mod_lt _ (by omega)) _ (Nat.mod_lt _ (by omega))

theorem chi'_cx_left (u w t : Nat) : chi' (cx u w) t = chi' u t * chi' w t := by
  have key : ∀ a < 8, ∀ b < 8, ∀ c < 8, chi ((a ^^^ b) % 8) c = chi (a % 8) c * chi (b % 8) c := by decide
  have := key (u % 8) (Nat.mod_lt _ (by omega)) (w % 8) (Nat.mod_lt _ (by omega)) (t % 8) (Nat.mod_lt _ (by omega))
  simpa [chi', cx] using this

theorem chi'_cx_right (w t t' : Nat) : chi' w (cx t t') = chi' w t * chi' w t' := by
  have key : ∀ a < 8, ∀ b < 8, ∀ c < 8, chi a ((b ^^^ c) % 8) = chi a (b % 8) * chi a (c % 8) := by decide
  have := key (w % 8) (Nat.mod_lt _ (by omega)) (t % 8) (Nat.mod_lt _ (by omega)) (t' % 8) (Nat.mod_lt _ (by omega))
  simpa [chi', cx] using this

/-- Fourier inversion with the total characters, at a value below 8. -/
theorem fourier_inv8' (g : Nat → Int) (t : Nat) (ht : t < 8) :
    8 * g t = sum8 fun w => (sum8 fun v => g v * chi' w v) * chi' w t := by
  have := fourier_inv8 g t ht
  simpa [sum8, chi', Nat.mod_eq_of_lt ht] using this

/-- product of the slot characters. -/
def chiProd : List Nat → Asg → Asg → Int
  | [], _, _ => 1
  | k :: K, u, t => chi' (u k) (t k) * chiProd K u t

/-- the character-twisted sum of h over the slots K. -/
def tw (K : List Nat) (h : Asg → Int) (u t0 : Asg) : Int :=
  sumOver K (fun t => h t * chiProd K u t) t0

def TwDiv (K : List Nat) (h : Asg → Int) (n : Nat) : Prop :=
  ∀ u t0 : Asg, ((2 ^ n : Nat) : Int) ∣ tw K h u t0

theorem upd_same (t : Asg) (k v : Nat) : upd t k v k = v := by simp [upd]
theorem upd_other (t : Asg) {k j : Nat} (v : Nat) (h : j ≠ k) : upd t k v j = t j := by simp [upd, h]

theorem chiProd_upd_t_notin (K : List Nat) (u t : Asg) (k v : Nat) (hk : k ∉ K) :
    chiProd K u (upd t k v) = chiProd K u t := by
  induction K with
  | nil => rfl
  | cons j K ih =>
    have hjk : j ≠ k := fun e => hk (e ▸ List.mem_cons_self)
    show chi' (u j) (upd t k v j) * chiProd K u (upd t k v) = chi' (u j) (t j) * chiProd K u t
    rw [upd_other t v hjk, ih fun m => hk (List.mem_cons_of_mem _ m)]

theorem chiProd_upd_u_notin (K : List Nat) (u t : Asg) (k x : Nat) (hk : k ∉ K) :
    chiProd K (upd u k x) t = chiProd K u t := by
  induction K with
  | nil => rfl
  | cons j K ih =>
    have hjk : j ≠ k := fun e => hk (e ▸ List.mem_cons_self)
    show chi' (upd u k x j) (t j) * chiProd K (upd u k x) t = chi' (u j) (t j) * chiProd K u t
    rw [upd_other u x hjk, ih fun m => hk (List.mem_cons_of_mem _ m)]

/-- shifting the character at slot a by w multiplies the product by chi_w(t_a). -/
theorem chiProd_shift (K : List Nat) (hK : K.Nodup) (u t : Asg) (a w : Nat) (ha : a ∈ K) :
    chiProd K (upd u a (cx (u a) w)) t = chiProd K u t * chi' w (t a) := by
  induction K with
  | nil => cases ha
  | cons j K ih =>
    have hj : j ∉ K := (List.nodup_cons.mp hK).1
    have hK' : K.Nodup := (List.nodup_cons.mp hK).2
    show chi' (upd u a (cx (u a) w) j) (t j) * chiProd K (upd u a (cx (u a) w)) t =
         chi' (u j) (t j) * chiProd K u t * chi' w (t a)
    by_cases e : j = a
    · subst e
      rw [upd_same, chiProd_upd_u_notin K u t j _ hj, chi'_cx_left]
      ac_rfl
    · have ha' : a ∈ K := by
        rcases List.mem_cons.mp ha with h | h
        · exact absurd h.symm e
        · exact h
      rw [upd_other u _ e, ih hK' ha']
      ac_rfl

theorem chiProd_append (K K' : List Nat) (u t : Asg) :
    chiProd (K ++ K') u t = chiProd K u t * chiProd K' u t := by
  induction K with
  | nil => show chiProd K' u t = 1 * chiProd K' u t; rw [Int.one_mul]
  | cons j K ih =>
    show chi' (u j) (t j) * chiProd (K ++ K') u t = chi' (u j) (t j) * chiProd K u t * chiProd K' u t
    rw [ih, Int.mul_assoc]

theorem sumOver_const_mul (K : List Nat) (c : Int) (F : Asg → Int) (t : Asg) :
    sumOver K (fun t => c * F t) t = c * sumOver K F t :=
  sumOver_mul_left_of_indep K (fun _ => c) F (fun _ _ _ _ => rfl) t

/-- BASE CASE: factors on disjoint slot sets — exponents add. -/
theorem twdiv_append (K K' : List Nat) (f g : Asg → Int) (n n' : Nat)
    (hf : ∀ k ∈ K', Indep f k) (hg : ∀ k ∈ K, Indep g k) (hd : ∀ k ∈ K, k ∉ K')
    (Hf : TwDiv K f n) (Hg : TwDiv K' g n') :
    TwDiv (K ++ K') (fun t => f t * g t) (n + n') := by
  intro u t0
  have e : tw (K ++ K') (fun t => f t * g t) u t0 = tw K f u t0 * tw K' g u t0 := by
    show sumOver (K ++ K') (fun t => f t * g t * chiProd (K ++ K') u t) t0 = _
    rw [sumOver_congr (K ++ K')
      (G := fun t => (f t * chiProd K u t) * (g t * chiProd K' u t))
      (fun t => by rw [chiProd_append]; ac_rfl)]
    exact sumOver_append_mul K K' _ _
      (fun k hk t v => by
        show f (upd t k v) * chiProd K u (upd t k v) = f t * chiProd K u t
        rw [hf k hk, chiProd_upd_t_notin K u t k v (fun m => hd k m hk)])
      (fun k hk t v => by
        show g (upd t k v) * chiProd K' u (upd t k v) = g t * chiProd K' u t
        rw [hg k hk, chiProd_upd_t_notin K' u t k v (hd k hk)])
      hd t0
  rw [e, Nat.pow_add, Int.natCast_mul]
  exact Int.mul_dvd_mul (Hf u t0) (Hg u t0)

theorem cancel8 (N : Nat) (x : Int) (h : ((2 ^ N : Nat) : Int) ∣ 8 * x) :
    ((2 ^ (N - 3) : Nat) : Int) ∣ x := by
  by_cases hN : 3 ≤ N
  · have e : (2 ^ N : Nat) = 8 * 2 ^ (N - 3) := by
      rw [show (8 : Nat) = 2 ^ 3 from rfl, ← Nat.pow_add]; congr 1; omega
    rw [e, Int.natCast_mul] at h
    exact Int.dvd_of_mul_dvd_mul_left (by decide) h
  · have e : N - 3 = 0 := by omega
    rw [e]; exact Int.one_dvd x

/-- INDUCTIVE STEP (cross boundary): h * gamma(t_a xor t_b), with all Walsh coefficients of
    gamma divisible by 2^m, has exponent n + m - 3. -/
theorem twdiv_cross (K : List Nat) (hK : K.Nodup) (a b : Nat) (ha : a ∈ K) (hb : b ∈ K)
    (hab : a ≠ b) (γ : Nat → Int) (m : Nat)
    (hγ : ∀ w, ((2 ^ m : Nat) : Int) ∣ sum8 fun v => γ v * chi' w v)
    (h : Asg → Int) (n : Nat) (H : TwDiv K h n) :
    TwDiv K (fun t => h t * γ (cx (t a) (t b))) (n + m - 3) := by
  intro u t0
  apply cancel8
  let u' : Nat → Asg := fun w => upd (upd u a (cx (u a) w)) b (cx (u b) w)
  have hshift : ∀ w t, chiProd K (u' w) t = chiProd K u t * chi' w (t a) * chi' w (t b) := by
    intro w t
    have e1 : upd u a (cx (u a) w) b = u b := upd_other u _ (Ne.symm hab)
    show chiProd K (upd (upd u a (cx (u a) w)) b (cx (u b) w)) t = _
    rw [← e1, chiProd_shift K hK _ t b w hb, chiProd_shift K hK u t a w ha]
  have e : 8 * tw K (fun t => h t * γ (cx (t a) (t b))) u t0 =
      sum8 fun w => (sum8 fun v => γ v * chi' w v) * tw K h (u' w) t0 := by
    show 8 * sumOver K (fun t => h t * γ (cx (t a) (t b)) * chiProd K u t) t0 = _
    rw [← sumOver_const_mul]
    rw [sumOver_congr K (G := fun t => sum8 fun w =>
        (sum8 fun v => γ v * chi' w v) * (h t * chiProd K (u' w) t)) (fun t => by
      have inv := fourier_inv8' γ (cx (t a) (t b)) (cx_lt _ _)
      have e2 : 8 * (h t * γ (cx (t a) (t b)) * chiProd K u t) =
          (h t * chiProd K u t) * (8 * γ (cx (t a) (t b))) := by ac_rfl
      rw [e2, inv, ← sum8_mul_left]
      exact sum8_congr fun w => by
        rw [hshift, chi'_cx_right]; ac_rfl)]
    rw [sumOver_sum8]
    exact sum8_congr fun w => sumOver_const_mul K _ _ t0
  rw [e, Nat.pow_add, Int.natCast_mul]
  apply sum8_dvd
  intro w
  rw [Int.mul_comm ((2 ^ n : Nat) : Int)]
  exact Int.mul_dvd_mul (hγ w) (H (u' w) t0)

/-- INDUCTIVE STEP (one-slot factor, e.g. the anchor boundary). -/
theorem twdiv_slot (K : List Nat) (hK : K.Nodup) (a : Nat) (ha : a ∈ K)
    (γ : Nat → Int) (m : Nat)
    (hγ : ∀ w, ((2 ^ m : Nat) : Int) ∣ sum8 fun v => γ v * chi' w v)
    (h : Asg → Int) (n : Nat) (H : TwDiv K h n) :
    TwDiv K (fun t => h t * γ (t a % 8)) (n + m - 3) := by
  intro u t0
  apply cancel8
  let u' : Nat → Asg := fun w => upd u a (cx (u a) w)
  have e : 8 * tw K (fun t => h t * γ (t a % 8)) u t0 =
      sum8 fun w => (sum8 fun v => γ v * chi' w v) * tw K h (u' w) t0 := by
    show 8 * sumOver K (fun t => h t * γ (t a % 8) * chiProd K u t) t0 = _
    rw [← sumOver_const_mul]
    rw [sumOver_congr K (G := fun t => sum8 fun w =>
        (sum8 fun v => γ v * chi' w v) * (h t * chiProd K (u' w) t)) (fun t => by
      have inv := fourier_inv8' γ (t a % 8) (Nat.mod_lt _ (by omega))
      have e2 : 8 * (h t * γ (t a % 8) * chiProd K u t) =
          (h t * chiProd K u t) * (8 * γ (t a % 8)) := by ac_rfl
      rw [e2, inv, ← sum8_mul_left]
      exact sum8_congr fun w => by
        have e3 : chi' w (t a % 8) = chi' w (t a) := by simp [chi']
        rw [chiProd_shift K hK u t a w ha, e3]; ac_rfl)]
    rw [sumOver_sum8]
    exact sum8_congr fun w => sumOver_const_mul K _ _ t0
  rw [e, Nat.pow_add, Int.natCast_mul]
  apply sum8_dvd
  intro w
  rw [Int.mul_comm ((2 ^ n : Nat) : Int)]
  exact Int.mul_dvd_mul (hγ w) (H (u' w) t0)

theorem chiProd_zero (K : List Nat) (t : Asg) : chiProd K (fun _ => 0) t = 1 := by
  induction K with
  | nil => rfl
  | cons j K ih =>
    show chi' 0 (t j) * chiProd K (fun _ => 0) t = 1
    have key : ∀ c < 8, chi 0 c = 1 := by decide
    have : chi' 0 (t j) = 1 := key _ (Nat.mod_lt _ (by omega))
    rw [this, ih]; rfl

/-- CONCLUSION: the plain sum (the count, when h is a 0/1 indicator) is divisible by 2^n. -/
theorem twdiv_count (K : List Nat) (h : Asg → Int) (n : Nat) (H : TwDiv K h n) (t0 : Asg) :
    ((2 ^ n : Nat) : Int) ∣ sumOver K h t0 := by
  have := H (fun _ => 0) t0
  have e : tw K h (fun _ => 0) t0 = sumOver K h t0 :=
    sumOver_congr K (fun t => by rw [chiProd_zero, Int.mul_one]) t0
  rwa [e] at this

/-! ## §6  from Walsh coefficients to `TwDiv`, four slots -/

/-
  §6 — connects the kernel table (Walsh coefficients `hat`, binary recursion) to the
  Step-3 invariant `TwDiv` (twisted sums over slots, one base-8 value per slot):

    `twdiv_of_hat4` : if 2^n divides every `hat` coefficient of a four-slot indicator, then the
                      indicator, placed on ANY four distinct slots, satisfies `TwDiv ... n`.

  With `allDivF_sound` (§3) this turns one passing table row into the hypothesis the
  induction of §5 starts from.
-/

theorem sum8_congr_lt {F G : Nat → Int} (h : ∀ v < 8, F v = G v) : sum8 F = sum8 G := by
  simp only [sum8]
  rw [h 0 (by omega), h 1 (by omega), h 2 (by omega), h 3 (by omega), h 4 (by omega),
    h 5 (by omega), h 6 (by omega), h 7 (by omega)]

def sgn (b : Nat) : Int := if b = 0 then 1 else -1

/-- one binary level of `hat`, in "bit * 2^d + rest" form. -/
theorem hat_bit (f : Nat → Bool) (d pre b r : Nat) (hb : b < 2) (hr : r < 2 ^ d) :
    hat f (d+1) pre (b * 2 ^ d + r) = hat f d (2*pre) r + sgn b * hat f d (2*pre+1) r := by
  have hb' : b = 0 ∨ b = 1 := by omega
  rcases hb' with h | h <;> subst h
  · have e : 0 * 2 ^ d + r = r := by omega
    rw [e]; simp only [hat, hr, if_true, sgn]; omega
  · have e : ¬ (1 * 2 ^ d + r < 2 ^ d) := by omega
    have e' : 1 * 2 ^ d + r - 2 ^ d = r := by omega
    have s1 : sgn 1 = -1 := rfl
    simp only [hat, e, if_false]
    rw [e', s1]; omega

/-- three binary levels = one base-8 digit. -/
theorem hat_digit (f : Nat → Bool) (d pre q r : Nat) (hq : q < 8) (hr : r < 2 ^ d) :
    hat f (d+3) pre (q * 2 ^ d + r) = sum8 fun v => chi q v * hat f d (8*pre+v) r := by
  have e1 : 2 ^ (d + 1) = 2 * 2 ^ d := by rw [Nat.pow_succ]; omega
  have e2 : 2 ^ (d + 2) = 4 * 2 ^ d := by rw [Nat.pow_succ, Nat.pow_succ]; omega
  have key : ∀ b2 < 2, ∀ b1 < 2, ∀ b0 < 2,
      hat f (d+3) pre (b2 * 2 ^ (d+2) + (b1 * 2 ^ (d+1) + (b0 * 2 ^ d + r))) =
        ((hat f d (8*pre+0) r + sgn b0 * hat f d (8*pre+1) r) +
          sgn b1 * (hat f d (8*pre+2) r + sgn b0 * hat f d (8*pre+3) r)) +
        sgn b2 * ((hat f d (8*pre+4) r + sgn b0 * hat f d (8*pre+5) r) +
          sgn b1 * (hat f d (8*pre+6) r + sgn b0 * hat f d (8*pre+7) r)) := by
    intro b2 h2 b1 h1 b0 h0
    have r1 : b0 * 2 ^ d + r < 2 ^ (d+1) := by
      rw [e1]; have : b0 * 2 ^ d ≤ 1 * 2 ^ d := Nat.mul_le_mul_right _ (by omega); omega
    have r2 : b1 * 2 ^ (d+1) + (b0 * 2 ^ d + r) < 2 ^ (d+2) := by
      rw [e2]; rw [e1] at r1 ⊢
      have : b1 * (2 * 2 ^ d) ≤ 1 * (2 * 2 ^ d) := Nat.mul_le_mul_right _ (by omega); omega
    rw [hat_bit f (d+2) pre b2 _ h2 r2, hat_bit f (d+1) (2*pre) b1 _ h1 r1,
      hat_bit f (d+1) (2*pre+1) b1 _ h1 r1, hat_bit f d (2*(2*pre)) b0 r h0 hr,
      hat_bit f d (2*(2*pre)+1) b0 r h0 hr, hat_bit f d (2*(2*pre+1)) b0 r h0 hr,
      hat_bit f d (2*(2*pre+1)+1) b0 r h0 hr]
    rw [show 2*(2*(2*pre))+1 = 8*pre+1 by omega, show 2*(2*(2*pre)) = 8*pre+0 by omega,
      show 2*(2*(2*pre)+1)+1 = 8*pre+3 by omega, show 2*(2*(2*pre)+1) = 8*pre+2 by omega,
      show 2*(2*(2*pre+1))+1 = 8*pre+5 by omega, show 2*(2*(2*pre+1)) = 8*pre+4 by omega,
      show 2*(2*(2*pre+1)+1)+1 = 8*pre+7 by omega, show 2*(2*(2*pre+1)+1) = 8*pre+6 by omega]
  have hq8 : q = 0 ∨ q = 1 ∨ q = 2 ∨ q = 3 ∨ q = 4 ∨ q = 5 ∨ q = 6 ∨ q = 7 := by omega
  rcases hq8 with h | h | h | h | h | h | h | h <;> subst h
  · have := key 0 (by omega) 0 (by omega) 0 (by omega)
    rw [show 0 * 2 ^ d + r = 0 * 2 ^ (d+2) + (0 * 2 ^ (d+1) + (0 * 2 ^ d + r)) by omega, this]
    simp [sum8, chi, par3, sgn]; omega
  · have := key 0 (by omega) 0 (by omega) 1 (by omega)
    rw [show 1 * 2 ^ d + r = 0 * 2 ^ (d+2) + (0 * 2 ^ (d+1) + (1 * 2 ^ d + r)) by omega, this]
    simp [sum8, chi, par3, sgn]; omega
  · have := key 0 (by omega) 1 (by omega) 0 (by omega)
    rw [show 2 * 2 ^ d + r = 0 * 2 ^ (d+2) + (1 * 2 ^ (d+1) + (0 * 2 ^ d + r)) by omega, this]
    simp [sum8, chi, par3, sgn]; omega
  · have := key 0 (by omega) 1 (by omega) 1 (by omega)
    rw [show 3 * 2 ^ d + r = 0 * 2 ^ (d+2) + (1 * 2 ^ (d+1) + (1 * 2 ^ d + r)) by omega, this]
    simp [sum8, chi, par3, sgn]; omega
  · have := key 1 (by omega) 0 (by omega) 0 (by omega)
    rw [show 4 * 2 ^ d + r = 1 * 2 ^ (d+2) + (0 * 2 ^ (d+1) + (0 * 2 ^ d + r)) by omega, this]
    simp [sum8, chi, par3, sgn]; omega
  · have := key 1 (by omega) 0 (by omega) 1 (by omega)
    rw [show 5 * 2 ^ d + r = 1 * 2 ^ (d+2) + (0 * 2 ^ (d+1) + (1 * 2 ^ d + r)) by omega, this]
    simp [sum8, chi, par3, sgn]; omega
  · have := key 1 (by omega) 1 (by omega) 0 (by omega)
    rw [show 6 * 2 ^ d + r = 1 * 2 ^ (d+2) + (1 * 2 ^ (d+1) + (0 * 2 ^ d + r)) by omega, this]
    simp [sum8, chi, par3, sgn]; omega
  · have := key 1 (by omega) 1 (by omega) 1 (by omega)
    rw [show 7 * 2 ^ d + r = 1 * 2 ^ (d+2) + (1 * 2 ^ (d+1) + (1 * 2 ^ d + r)) by omega, this]
    simp [sum8, chi, par3, sgn]; omega

/-- GLUE: a four-slot indicator whose Walsh coefficients are all divisible by 2^n satisfies
    TwDiv on any four distinct slots. -/
theorem twdiv_of_hat4 (ind : Nat → Nat → Nat → Nat → Bool) (k1 k2 k3 k4 : Nat)
    (h12 : k1 ≠ k2) (h13 : k1 ≠ k3) (h14 : k1 ≠ k4) (h23 : k2 ≠ k3) (h24 : k2 ≠ k4)
    (h34 : k3 ≠ k4) (n : Nat)
    (H : ∀ U < 4096, ((2 ^ n : Nat) : Int) ∣
      hat (fun i => ind (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)) 12 0 U) :
    TwDiv [k1, k2, k3, k4]
      (fun t => if ind (t k1 % 8) (t k2 % 8) (t k3 % 8) (t k4 % 8) then 1 else 0) n := by
  intro u t0
  have hq : ∀ k, u k % 8 < 8 := fun k => Nat.mod_lt _ (by omega)
  generalize hf : (fun i => ind (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)) = f at H
  have e : tw [k1, k2, k3, k4]
      (fun t => if ind (t k1 % 8) (t k2 % 8) (t k3 % 8) (t k4 % 8) then 1 else 0) u t0 =
      hat f 12 0 (u k1 % 8 * 2 ^ 9 + (u k2 % 8 * 2 ^ 6 + (u k3 % 8 * 2 ^ 3 + (u k4 % 8 * 2 ^ 0 + 0)))) := by
    have r3 : u k4 % 8 * 2 ^ 0 + 0 < 2 ^ 3 := by have := hq k4; omega
    have r6 : u k3 % 8 * 2 ^ 3 + (u k4 % 8 * 2 ^ 0 + 0) < 2 ^ 6 := by have := hq k3; omega
    have r9 : u k2 % 8 * 2 ^ 6 + (u k3 % 8 * 2 ^ 3 + (u k4 % 8 * 2 ^ 0 + 0)) < 2 ^ 9 := by
      have := hq k2; omega
    rw [hat_digit f 9 0 _ _ (hq k1) r9]
    show (sum8 fun v1 => sum8 fun v2 => sum8 fun v3 => sum8 fun v4 =>
        (fun t => (if ind (t k1 % 8) (t k2 % 8) (t k3 % 8) (t k4 % 8) then (1 : Int) else 0) *
          chiProd [k1, k2, k3, k4] u t)
        (upd (upd (upd (upd t0 k1 v1) k2 v2) k3 v3) k4 v4)) = _
    apply sum8_congr_lt; intro v1 hv1
    rw [hat_digit f 6 _ _ _ (hq k2) r6, ← sum8_mul_left]
    apply sum8_congr_lt; intro v2 hv2
    rw [hat_digit f 3 _ _ _ (hq k3) r3, ← sum8_mul_left, ← sum8_mul_left]
    apply sum8_congr_lt; intro v3 hv3
    rw [hat_digit f 0 _ _ _ (hq k4) (by omega), ← sum8_mul_left, ← sum8_mul_left, ← sum8_mul_left]
    apply sum8_congr_lt; intro v4 hv4
    have a1 : upd (upd (upd (upd t0 k1 v1) k2 v2) k3 v3) k4 v4 k1 = v1 := by
      simp [upd, h12, h13, h14]
    have a2 : upd (upd (upd (upd t0 k1 v1) k2 v2) k3 v3) k4 v4 k2 = v2 := by
      simp [upd, h23, h24]
    have a3 : upd (upd (upd (upd t0 k1 v1) k2 v2) k3 v3) k4 v4 k3 = v3 := by
      simp [upd, h34]
    have a4 : upd (upd (upd (upd t0 k1 v1) k2 v2) k3 v3) k4 v4 k4 = v4 := by
      simp [upd]
    have i1 : (8 * (8 * (8 * (8 * 0 + v1) + v2) + v3) + v4) / 512 % 8 = v1 := by omega
    have i2 : (8 * (8 * (8 * (8 * 0 + v1) + v2) + v3) + v4) / 64 % 8 = v2 := by omega
    have i3 : (8 * (8 * (8 * (8 * 0 + v1) + v2) + v3) + v4) / 8 % 8 = v3 := by omega
    have i4 : (8 * (8 * (8 * (8 * 0 + v1) + v2) + v3) + v4) % 8 = v4 := by omega
    have hleaf : hat f 0 (8 * (8 * (8 * (8 * 0 + v1) + v2) + v3) + v4) 0 =
        if ind v1 v2 v3 v4 then 1 else 0 := by
      subst hf; show (if ind _ _ _ _ then (1:Int) else 0) = _
      rw [i1, i2, i3, i4]
    show (if ind _ _ _ _ then (1 : Int) else 0) *
        (chi' (u k1) _ * (chi' (u k2) _ * (chi' (u k3) _ * (chi' (u k4) _ * 1)))) = _
    rw [a1, a2, a3, a4, hleaf, Nat.mod_eq_of_lt hv1, Nat.mod_eq_of_lt hv2, Nat.mod_eq_of_lt hv3,
      Nat.mod_eq_of_lt hv4]
    simp only [chi', Nat.mod_eq_of_lt hv1, Nat.mod_eq_of_lt hv2, Nat.mod_eq_of_lt hv3,
      Nat.mod_eq_of_lt hv4, Int.mul_one]
    ac_rfl
  rw [e]
  exact H _ (by have := hq k1; have := hq k2; have := hq k3; have := hq k4; omega)

/-! ## §7  Step 2 at hexagram level -/

/-
  §7 — Step 2 (the e_k table) at hexagram level, kernel-only.
  For a cross boundary (supports s != s') of class c, the 0/1 function
      g(t, t') = [ ham (partner (hexof s t)) (hexof s' t') = c ]      on F_2^3 x F_2^3
  has every one of its 64 two-variable Walsh coefficients divisible by 2^(6 - e), with
      e = 2 (class 1), 1 (class 2, 4, and class 3 with supports differing in one coordinate),
      e = 0 (class 3, supports differing in all three).
  Same for the anchor boundary (exit 0 -> entry of support s != 0), one variable, 2^(3 - e).
  In integers:  64 * g = sum_{w,w'} G(w,w') chi chi  with 2^(6-e) | G, i.e., with the
  transform normalised by 1/64, "g-hat in 2^(-e) Z".
-/

def pc3 (x : Nat) : Nat := x % 2 + x / 2 % 2 + x / 4 % 2

def eCross (s s' c : Nat) : Nat :=
  if c == 1 then 2 else if c == 3 then (if pc3 (s ^^^ s') == 3 then 0 else 1) else 1

def crossOK (s s' c : Nat) : Bool :=
  allDiv (6 - eCross s s' c) 6
    (P (fun i => ham (partner (hexof s (i / 8))) (hexof s' (i % 8)) == c) 6 0)

def anchorOK (s c : Nat) : Bool :=
  allDiv (3 - eCross 0 s c) 3 (P (fun i => ham 0 (hexof s i) == c) 3 0)

theorem cross_table :
    ((List.range 8).all fun s => (List.range 8).all fun s' =>
      s == s' || [1, 2, 3, 4].all fun c => crossOK s s' c) = true := by decide +kernel

theorem anchor_table :
    ((List.range 8).all fun s => s == 0 || [1, 2, 3, 4].all fun c => anchorOK s c) = true := by
  decide +kernel

/-- control: the table is tight for class 1 (2^5 fails somewhere). -/
theorem cross_mut : allDiv 5 6
    (P (fun i => ham (partner (hexof 1 (i / 8))) (hexof 3 (i % 8)) == 1) 6 0) = false := by
  decide +kernel

/-- across two different supports the class is never 0 or 6. Class 5 can occur here; it is
    excluded by the C5 budget, not by this lemma (so [1,2,3,4] is exhaustive for the tables). -/
theorem cross_classes : ((List.range 64).all fun a => (List.range 64).all fun b =>
    supp a == supp b || [1, 2, 3, 4, 5].contains (ham (partner a) b)) = true := by decide +kernel

/-! ## §8  the table indicator in (s, t) coordinates; pruned transform -/

/-
  §8 — the "smarter encoding" of the table: the indicator in (s, t) coordinates
  (three small pairwise lemmas, kernel-decided, tie it to the hexagram-level one), and a
  transform that prunes dead prefixes.
-/

def st (s : Nat) : Nat := if s == 0 then 7 else s
def sameC (s t t' : Nat) : Bool := t == t' || t == t' ^^^ st s
def gapC (s g t t' : Nat) : Bool := g == 0 || 2 * pc3 (t ^^^ st s ^^^ t') == g

/-- the three coordinate lemmas (hexagram level = coordinate level), exhaustive. -/
theorem samePair_coord : ∀ s < 8, ∀ t < 8, ∀ t' < 8,
    samePair (hexof s t) (hexof s t') = sameC s t t' := by decide +kernel
theorem gapOk_coord : ∀ s < 8, ∀ g ∈ [0, 2, 4, 6], ∀ t < 8, ∀ t' < 8,
    gapOk g (hexof s t) (hexof s t') = gapC s g t t' := by decide +kernel
theorem anchor_coord : ∀ t < 8, ∀ an ∈ [0, 2, 4, 6],
    (samePair (hexof 0 t) 63 = (t == 0 || t == 7)) ∧
    ((an == 0 || ham 0 (hexof 0 t) == an) = (an == 0 || 2 * pc3 t == an)) := by decide +kernel

/-- Phi_s in coordinates, as three nested prefix conditions. -/
def c12 (s g1 t1 t2 : Nat) : Bool := !sameC s t1 t2 && gapC s g1 t1 t2
def c123 (s g2 t1 t2 t3 : Nat) : Bool := !sameC s t2 t3 && gapC s g2 t2 t3 && !sameC s t1 t3
def c1234 (s g3 t1 t2 t3 t4 : Nat) : Bool :=
  !sameC s t3 t4 && gapC s g3 t3 t4 && !sameC s t1 t4 && !sameC s t2 t4

def indRc (s g1 g2 g3 : Nat) (i : Nat) : Bool :=
  c12 s g1 (i / 512 % 8) (i / 64 % 8) && c123 s g2 (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) &&
  c1234 s g3 (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)

/-- pruned transform: `alive d pre = false` promises f is false on the whole block, whose
    transform is then the bias alone. -/
def PR (alive : Nat → Nat → Bool) (f : Nat → Bool) : Nat → Nat → Nat
  | 0, pre => if f pre then 1 else 0
  | d+1, pre =>
      if alive (d+1) pre then
        (PR alive f d (2*pre) + PR alive f d (2*pre+1) + ones d) +
        (PR alive f d (2*pre) + (2 ^ (d+1) - 1) * ones d - PR alive f d (2*pre+1)) * 2 ^ (16 * 2 ^ d)
      else (2 ^ (d+1) - 1) * ones (d+1)

def aliveR (s g1 g2 : Nat) (d pre : Nat) : Bool :=
  if d == 6 then c12 s g1 (pre / 8 % 8) (pre % 8)
  else if d == 3 then c123 s g2 (pre / 64 % 8) (pre / 8 % 8) (pre % 8)
  else true

def patRB (s g1 g2 g3 : Nat) : Bool :=
  allDivF (7 - cost g1 - cost g2 - cost g3) 12 (P (indRc s g1 g2 g3) 12 0)
def patRBm (s g1 g2 g3 : Nat) : Bool :=
  allDiv (7 - cost g1 - cost g2 - cost g3) 12 (P (indRc s g1 g2 g3) 12 0)
def patRC (s g1 g2 g3 : Nat) : Bool :=
  allDivF (7 - cost g1 - cost g2 - cost g3) 12 (PR (aliveR s g1 g2) (indRc s g1 g2 g3) 12 0)
def patRCm (s g1 g2 g3 : Nat) : Bool :=
  allDiv (7 - cost g1 - cost g2 - cost g3) 12 (PR (aliveR s g1 g2) (indRc s g1 g2 g3) 12 0)
/-- baseline indicator with the field-by-field check. -/
def patRF (s g1 g2 g3 : Nat) : Bool :=
  allDivF (7 - cost g1 - cost g2 - cost g3) 12
    (P (fun i => indR s g1 g2 g3 (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)) 12 0)

/-- s = 0 row, hexagram-level indicator, field-by-field check. -/
def patCF (an g1 g2 : Nat) : Bool :=
  allDivF (4 - cost an - cost g1 - cost g2) 9
    (P (fun i => indC an g1 g2 (i / 64 % 8) (i / 8 % 8) (i % 8)) 9 0)

/-! ## §9  the table check in its fast form, with its meaning proved -/

/-
  §9 — the table check in its production form: fast, small in memory,
  and with its meaning PROVED.

    patRP s g1 g2 g3 = chk m 12 (PR (aliveR ..) (indRc ..) 12 0)
      indRc  : indicator in (s,t) coordinates          (= hexagram-level indR, `indR_eq_indRc`)
      PR     : transform that skips dead prefixes      (= P, `PR_eq_P` + `aliveR_sound`)
      chk    : field check by repeated halving         (`chk_sound`)

    `patRP_sound`: a passing row means 2^m divides every Walsh coefficient `hat` of the
    HEXAGRAM-LEVEL indicator (KingWen.lean's partner / ham).
-/

/-- field check by halving the packed number (light on kernel memory). -/
def chk (m : Nat) : Nat → Nat → Bool
  | 0, R => (R + 1) % 2 ^ m == 0
  | d+1, R => chk m d (R % 2 ^ (16 * 2 ^ d)) && chk m d (R / 2 ^ (16 * 2 ^ d))

theorem chk_sound (m : Nat) : ∀ (d : Nat) (a : Nat → Nat), (∀ u < 2 ^ d, a u < 65536) →
    chk m d (packFn (2 ^ d) a) = true → ∀ u < 2 ^ d, (a u + 1) % 2 ^ m = 0 := by
  intro d
  induction d with
  | zero =>
    intro a _ h u hu
    have hu0 : u = 0 := by have : (2:Nat) ^ 0 = 1 := rfl; omega
    subst hu0
    have e : packFn (2 ^ 0) a = a 0 := by show 0 + a 0 * 2 ^ (16 * 0) = a 0; simp
    rw [e] at h
    simpa [chk] using h
  | succ d ih =>
    intro a ha h u hu
    have e2 : 2 ^ (d + 1) = 2 ^ d + 2 ^ d := by rw [Nat.pow_succ]; omega
    have hlo : ∀ u < 2 ^ d, a u < 65536 := fun u hu => ha u (by omega)
    have hhi : ∀ u < 2 ^ d, a (2 ^ d + u) < 65536 := fun u hu => ha _ (by omega)
    have hlt := packFn_lt hlo
    have hs : packFn (2 ^ (d+1)) a =
        packFn (2 ^ d) a + packFn (2 ^ d) (fun u => a (2 ^ d + u)) * 2 ^ (16 * 2 ^ d) := by
      rw [e2, packFn_split]
    have hmod : packFn (2 ^ (d+1)) a % 2 ^ (16 * 2 ^ d) = packFn (2 ^ d) a := by
      rw [hs, Nat.add_mul_mod_self_right, Nat.mod_eq_of_lt hlt]
    have hdiv : packFn (2 ^ (d+1)) a / 2 ^ (16 * 2 ^ d) = packFn (2 ^ d) (fun u => a (2 ^ d + u)) := by
      rw [hs, Nat.add_mul_div_right _ _ (Nat.two_pow_pos _), Nat.div_eq_of_lt hlt, Nat.zero_add]
    have h' : (chk m d (packFn (2 ^ (d+1)) a % 2 ^ (16 * 2 ^ d)) &&
        chk m d (packFn (2 ^ (d+1)) a / 2 ^ (16 * 2 ^ d))) = true := h
    rw [hmod, hdiv, Bool.and_eq_true] at h'
    by_cases hul : u < 2 ^ d
    · exact ih a hlo h'.1 u hul
    · have := ih (fun u => a (2 ^ d + u)) hhi h'.2 (u - 2 ^ d) (by omega)
      have e : 2 ^ d + (u - 2 ^ d) = u := by omega
      rwa [e] at this

theorem ones_succ (d : Nat) : ones (d+1) = ones d + ones d * 2 ^ (16 * 2 ^ d) := by
  have e2 : 2 ^ (d + 1) = 2 ^ d + 2 ^ d := by rw [Nat.pow_succ]; omega
  rw [ones_eq, ones_eq, e2, packFn_split]

/-- a block on which f is false everywhere transforms to the bias alone. -/
theorem P_dead (f : Nat → Bool) : ∀ d pre,
    (∀ i, pre * 2 ^ d ≤ i → i < (pre+1) * 2 ^ d → f i = false) →
    P f d pre = (2 ^ d - 1) * ones d := by
  intro d
  induction d with
  | zero =>
    intro pre h
    have : f pre = false := h pre (by simp) (by simp)
    show (if f pre then 1 else 0) = (2 ^ 0 - 1) * ones 0
    simp [this]
  | succ d ih =>
    intro pre h
    have e1 : 2 ^ (d + 1) = 2 * 2 ^ d := by rw [Nat.pow_succ]; omega
    have m1 : 2 * pre * 2 ^ d = 2 * (pre * 2 ^ d) := Nat.mul_assoc ..
    have m2 : (2 * pre + 1) * 2 ^ d = 2 * (pre * 2 ^ d) + 2 ^ d := by rw [Nat.add_mul, m1]; omega
    have m3 : (2 * pre + 1 + 1) * 2 ^ d = 2 * (pre * 2 ^ d) + 2 ^ d + 2 ^ d := by
      rw [Nat.add_mul, m2]; omega
    have m4 : pre * 2 ^ (d+1) = 2 * (pre * 2 ^ d) := by rw [e1, Nat.mul_left_comm]
    have m5 : (pre + 1) * 2 ^ (d+1) = 2 * (pre * 2 ^ d) + 2 ^ d + 2 ^ d := by
      rw [Nat.add_mul, m4, e1]; omega
    have hA := ih (2*pre) (fun i h1 h2 => h i (by rw [m4]; rw [m1] at h1; exact h1)
      (by rw [m5]; rw [m2] at h2; omega))
    have hB := ih (2*pre+1) (fun i h1 h2 => h i (by rw [m4]; rw [m2] at h1; omega)
      (by rw [m5]; rw [m3] at h2; exact h2))
    show (P f d (2*pre) + P f d (2*pre+1) + ones d) +
      (P f d (2*pre) + (2 ^ (d+1) - 1) * ones d - P f d (2*pre+1)) * 2 ^ (16 * 2 ^ d) = _
    rw [hA, hB, ones_succ, Nat.add_sub_cancel_left]
    have hk : 2 ^ (d+1) - 1 = 2 * (2 ^ d - 1) + 1 := by
      have : 0 < 2 ^ d := Nat.two_pow_pos d
      omega
    rw [hk]
    generalize 2 ^ d - 1 = k
    generalize ones d = o
    generalize 2 ^ (16 * 2 ^ d) = Z
    have e : (2 * k + 1) * o = k * o + k * o + o := by
      rw [Nat.add_mul, Nat.one_mul, Nat.two_mul, Nat.add_mul]
    rw [Nat.mul_add, ← Nat.mul_assoc, e]

theorem PR_eq_P (alive : Nat → Nat → Bool) (f : Nat → Bool)
    (halive : ∀ d pre, alive d pre = false →
      ∀ i, pre * 2 ^ d ≤ i → i < (pre+1) * 2 ^ d → f i = false) :
    ∀ d pre, PR alive f d pre = P f d pre := by
  intro d
  induction d with
  | zero => intro pre; rfl
  | succ d ih =>
    intro pre
    cases h : alive (d+1) pre with
    | true => simp only [PR, h, if_true, ih, P]
    | false =>
      rw [P_dead f (d+1) pre (halive (d+1) pre h)]
      simp only [PR, h]
      rfl

theorem aliveR_sound (s g1 g2 g3 : Nat) : ∀ d pre, aliveR s g1 g2 d pre = false →
    ∀ i, pre * 2 ^ d ≤ i → i < (pre+1) * 2 ^ d → indRc s g1 g2 g3 i = false := by
  intro d pre h i h1 h2
  by_cases h6 : d = 6
  · subst h6
    have hc : c12 s g1 (pre / 8 % 8) (pre % 8) = false := by simpa [aliveR] using h
    have p : (2:Nat) ^ 6 = 64 := rfl
    rw [p] at h1 h2
    have a1 : i / 512 % 8 = pre / 8 % 8 := by omega
    have a2 : i / 64 % 8 = pre % 8 := by omega
    simp [indRc, a1, a2, hc]
  · by_cases h3 : d = 3
    · subst h3
      have hc : c123 s g2 (pre / 64 % 8) (pre / 8 % 8) (pre % 8) = false := by
        simpa [aliveR] using h
      have p : (2:Nat) ^ 3 = 8 := rfl
      rw [p] at h1 h2
      have a1 : i / 512 % 8 = pre / 64 % 8 := by omega
      have a2 : i / 64 % 8 = pre / 8 % 8 := by omega
      have a3 : i / 8 % 8 = pre % 8 := by omega
      simp [indRc, a1, a2, a3, hc]
    · simp [aliveR, h6, h3] at h

theorem indR_eq_indRc (s g1 g2 g3 : Nat) (hs : s < 8) (h1 : g1 ∈ cls) (h2 : g2 ∈ cls)
    (h3 : g3 ∈ cls) :
    (fun i => indR s g1 g2 g3 (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)) = indRc s g1 g2 g3 := by
  funext i
  have b1 : i / 512 % 8 < 8 := Nat.mod_lt _ (by omega)
  have b2 : i / 64 % 8 < 8 := Nat.mod_lt _ (by omega)
  have b3 : i / 8 % 8 < 8 := Nat.mod_lt _ (by omega)
  have b4 : i % 8 < 8 := Nat.mod_lt _ (by omega)
  simp only [indR, indRc, c12, c123, c1234,
    samePair_coord s hs _ b1 _ b2, samePair_coord s hs _ b2 _ b3, samePair_coord s hs _ b1 _ b3,
    samePair_coord s hs _ b3 _ b4, samePair_coord s hs _ b1 _ b4, samePair_coord s hs _ b2 _ b4,
    gapOk_coord s hs g1 h1 _ b1 _ b2, gapOk_coord s hs g2 h2 _ b2 _ b3,
    gapOk_coord s hs g3 h3 _ b3 _ b4]
  generalize sameC s (i / 512 % 8) (i / 64 % 8) = x1
  generalize gapC s g1 (i / 512 % 8) (i / 64 % 8) = x2
  generalize sameC s (i / 64 % 8) (i / 8 % 8) = x3
  generalize gapC s g2 (i / 64 % 8) (i / 8 % 8) = x4
  generalize sameC s (i / 512 % 8) (i / 8 % 8) = x5
  generalize sameC s (i / 8 % 8) (i % 8) = x6
  generalize gapC s g3 (i / 8 % 8) (i % 8) = x7
  generalize sameC s (i / 512 % 8) (i % 8) = x8
  generalize sameC s (i / 64 % 8) (i % 8) = x9
  revert x1 x2 x3 x4 x5 x6 x7 x8 x9
  decide

/-- shared ending: field congruences => divisibility of the signed coefficients. -/
theorem fields_sound (f : Nat → Bool) (m d pre : Nat) (hm : m ≤ d)
    (h : ∀ u < 2 ^ d, (bh f d pre u + 1) % 2 ^ m = 0) :
    ∀ u < 2 ^ d, ((2 ^ m : Nat) : Int) ∣ hat f d pre u := by
  intro u hu
  obtain ⟨a1, _, _⟩ := bh_hat f d pre u
  have hdvd1 : (2 ^ m : Nat) ∣ bh f d pre u + 1 := Nat.dvd_of_mod_eq_zero (h u hu)
  have hdvd2 : (2 ^ m : Nat) ∣ 2 ^ d := Nat.pow_dvd_pow 2 hm
  have i1 : ((2 ^ m : Nat) : Int) ∣ ((bh f d pre u + 1 : Nat) : Int) := Int.natCast_dvd_natCast.mpr hdvd1
  have i2 : ((2 ^ m : Nat) : Int) ∣ ((2 ^ d : Nat) : Int) := Int.natCast_dvd_natCast.mpr hdvd2
  have e : hat f d pre u = ((bh f d pre u + 1 : Nat) : Int) - ((2 ^ d : Nat) : Int) := by omega
  rw [e]; exact Int.dvd_sub i1 i2

theorem chkP_sound (f : Nat → Bool) (m d pre : Nat) (hd : d ≤ 14) (hm : m ≤ d)
    (h : chk m d (P f d pre) = true) : ∀ u < 2 ^ d, ((2 ^ m : Nat) : Int) ∣ hat f d pre u := by
  have hP := P_eq_pack f (fun d pre u _ => bh_le f d pre u) d pre
  have hpow : 2 ^ (d + 1) ≤ 2 ^ 15 := Nat.pow_le_pow_right (by decide) (by omega)
  rw [hP] at h
  exact fields_sound f m d pre hm
    (chk_sound m d (bh f d pre) (fun u _ => by have := bh_le f d pre u; omega) h)

def patRP (s g1 g2 g3 : Nat) : Bool :=
  chk (7 - cost g1 - cost g2 - cost g3) 12 (PR (aliveR s g1 g2) (indRc s g1 g2 g3) 12 0)

def patCP (an g1 g2 : Nat) : Bool :=
  chk (4 - cost an - cost g1 - cost g2) 9
    (P (fun i => indC an g1 g2 (i / 64 % 8) (i / 8 % 8) (i % 8)) 9 0)

/-- MEANING OF A PASSING ROW (reversible supports). -/
theorem patRP_sound (s g1 g2 g3 : Nat) (hs : s < 8) (h1 : g1 ∈ cls) (h2 : g2 ∈ cls)
    (h3 : g3 ∈ cls) (h : patRP s g1 g2 g3 = true) :
    ∀ U < 4096, ((2 ^ (7 - cost g1 - cost g2 - cost g3) : Nat) : Int) ∣
      hat (fun i => indR s g1 g2 g3 (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)) 12 0 U := by
  rw [indR_eq_indRc s g1 g2 g3 hs h1 h2 h3]
  have h' : chk (7 - cost g1 - cost g2 - cost g3) 12 (P (indRc s g1 g2 g3) 12 0) = true := by
    rw [← PR_eq_P (aliveR s g1 g2) (indRc s g1 g2 g3) (aliveR_sound s g1 g2 g3)]; exact h
  exact chkP_sound _ _ 12 0 (by omega) (by omega) h'

/-- MEANING OF A PASSING ROW (complement pairs, s = 0). -/
theorem patCP_sound (an g1 g2 : Nat) (h : patCP an g1 g2 = true) :
    ∀ U < 512, ((2 ^ (4 - cost an - cost g1 - cost g2) : Nat) : Int) ∣
      hat (fun i => indC an g1 g2 (i / 64 % 8) (i / 8 % 8) (i % 8)) 9 0 U :=
  chkP_sound _ _ 9 0 (by omega) (by omega) h

/-! ## §10  THE 512-ENTRY TABLE (kernel) -/

-- GENERATED: the 512-entry table of Step 4 in production form (patRP / patCP),
-- 16 patterns per theorem, kernel `decide +kernel`, no native_decide.
theorem tP_1_0 : (cls.all fun g2 => cls.all fun g3 => patRP 1 0 g2 g3) = true := by decide +kernel
theorem tP_1_2 : (cls.all fun g2 => cls.all fun g3 => patRP 1 2 g2 g3) = true := by decide +kernel
theorem tP_1_4 : (cls.all fun g2 => cls.all fun g3 => patRP 1 4 g2 g3) = true := by decide +kernel
theorem tP_1_6 : (cls.all fun g2 => cls.all fun g3 => patRP 1 6 g2 g3) = true := by decide +kernel
theorem tP_2_0 : (cls.all fun g2 => cls.all fun g3 => patRP 2 0 g2 g3) = true := by decide +kernel
theorem tP_2_2 : (cls.all fun g2 => cls.all fun g3 => patRP 2 2 g2 g3) = true := by decide +kernel
theorem tP_2_4 : (cls.all fun g2 => cls.all fun g3 => patRP 2 4 g2 g3) = true := by decide +kernel
theorem tP_2_6 : (cls.all fun g2 => cls.all fun g3 => patRP 2 6 g2 g3) = true := by decide +kernel
theorem tP_3_0 : (cls.all fun g2 => cls.all fun g3 => patRP 3 0 g2 g3) = true := by decide +kernel
theorem tP_3_2 : (cls.all fun g2 => cls.all fun g3 => patRP 3 2 g2 g3) = true := by decide +kernel
theorem tP_3_4 : (cls.all fun g2 => cls.all fun g3 => patRP 3 4 g2 g3) = true := by decide +kernel
theorem tP_3_6 : (cls.all fun g2 => cls.all fun g3 => patRP 3 6 g2 g3) = true := by decide +kernel
theorem tP_4_0 : (cls.all fun g2 => cls.all fun g3 => patRP 4 0 g2 g3) = true := by decide +kernel
theorem tP_4_2 : (cls.all fun g2 => cls.all fun g3 => patRP 4 2 g2 g3) = true := by decide +kernel
theorem tP_4_4 : (cls.all fun g2 => cls.all fun g3 => patRP 4 4 g2 g3) = true := by decide +kernel
theorem tP_4_6 : (cls.all fun g2 => cls.all fun g3 => patRP 4 6 g2 g3) = true := by decide +kernel
theorem tP_5_0 : (cls.all fun g2 => cls.all fun g3 => patRP 5 0 g2 g3) = true := by decide +kernel
theorem tP_5_2 : (cls.all fun g2 => cls.all fun g3 => patRP 5 2 g2 g3) = true := by decide +kernel
theorem tP_5_4 : (cls.all fun g2 => cls.all fun g3 => patRP 5 4 g2 g3) = true := by decide +kernel
theorem tP_5_6 : (cls.all fun g2 => cls.all fun g3 => patRP 5 6 g2 g3) = true := by decide +kernel
theorem tP_6_0 : (cls.all fun g2 => cls.all fun g3 => patRP 6 0 g2 g3) = true := by decide +kernel
theorem tP_6_2 : (cls.all fun g2 => cls.all fun g3 => patRP 6 2 g2 g3) = true := by decide +kernel
theorem tP_6_4 : (cls.all fun g2 => cls.all fun g3 => patRP 6 4 g2 g3) = true := by decide +kernel
theorem tP_6_6 : (cls.all fun g2 => cls.all fun g3 => patRP 6 6 g2 g3) = true := by decide +kernel
theorem tP_7_0 : (cls.all fun g2 => cls.all fun g3 => patRP 7 0 g2 g3) = true := by decide +kernel
theorem tP_7_2 : (cls.all fun g2 => cls.all fun g3 => patRP 7 2 g2 g3) = true := by decide +kernel
theorem tP_7_4 : (cls.all fun g2 => cls.all fun g3 => patRP 7 4 g2 g3) = true := by decide +kernel
theorem tP_7_6 : (cls.all fun g2 => cls.all fun g3 => patRP 7 6 g2 g3) = true := by decide +kernel
theorem tP_0_0 : (cls.all fun g1 => cls.all fun g2 => patCP 0 g1 g2) = true := by decide +kernel
theorem tP_0_2 : (cls.all fun g1 => cls.all fun g2 => patCP 2 g1 g2) = true := by decide +kernel
theorem tP_0_4 : (cls.all fun g1 => cls.all fun g2 => patCP 4 g1 g2) = true := by decide +kernel
theorem tP_0_6 : (cls.all fun g1 => cls.all fun g2 => patCP 6 g1 g2) = true := by decide +kernel

/-! ## §11  the table as a theorem about Walsh coefficients -/

/-
  §11 — THE TABLE AS A THEOREM ABOUT WALSH COEFFICIENTS (Step 4).
  For every support s, every internal pattern, and EVERY character U, the Walsh coefficient
  `hat` of the hexagram-level indicator (KingWen.lean's partner / ham) is divisible by
  2^(7 - #internal boundaries)  (2^(4 - ...) for s = 0).   512 patterns in all.
-/

theorem table_spec_R (s g1 g2 g3 : Nat) (hs : s ∈ [1, 2, 3, 4, 5, 6, 7]) (h1 : g1 ∈ cls)
    (h2 : g2 ∈ cls) (h3 : g3 ∈ cls) :
    ∀ U < 4096, ((2 ^ (7 - cost g1 - cost g2 - cost g3) : Nat) : Int) ∣
      hat (fun i => indR s g1 g2 g3 (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)) 12 0 U := by
  have hs8 : s < 8 := by
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hs; omega
  have key : (cls.all fun g2 => cls.all fun g3 => patRP s g1 g2 g3) = true := by
    have h1' := h1
    simp only [cls, List.mem_cons, List.not_mem_nil, or_false] at hs h1'
    rcases hs with h | h | h | h | h | h | h <;> rcases h1' with h' | h' | h' | h' <;> subst h <;> subst h'
    · exact tP_1_0
    · exact tP_1_2
    · exact tP_1_4
    · exact tP_1_6
    · exact tP_2_0
    · exact tP_2_2
    · exact tP_2_4
    · exact tP_2_6
    · exact tP_3_0
    · exact tP_3_2
    · exact tP_3_4
    · exact tP_3_6
    · exact tP_4_0
    · exact tP_4_2
    · exact tP_4_4
    · exact tP_4_6
    · exact tP_5_0
    · exact tP_5_2
    · exact tP_5_4
    · exact tP_5_6
    · exact tP_6_0
    · exact tP_6_2
    · exact tP_6_4
    · exact tP_6_6
    · exact tP_7_0
    · exact tP_7_2
    · exact tP_7_4
    · exact tP_7_6
  exact patRP_sound s g1 g2 g3 hs8 h1 h2 h3
    (List.all_eq_true.mp (List.all_eq_true.mp key g2 h2) g3 h3)

theorem table_spec_C (an g1 g2 : Nat) (h0 : an ∈ cls) (h1 : g1 ∈ cls) (h2 : g2 ∈ cls) :
    ∀ U < 512, ((2 ^ (4 - cost an - cost g1 - cost g2) : Nat) : Int) ∣
      hat (fun i => indC an g1 g2 (i / 64 % 8) (i / 8 % 8) (i % 8)) 9 0 U := by
  have key : (cls.all fun g1 => cls.all fun g2 => patCP an g1 g2) = true := by
    have h0' := h0
    simp only [cls, List.mem_cons, List.not_mem_nil, or_false] at h0'
    rcases h0' with h | h | h | h <;> subst h
    · exact tP_0_0
    · exact tP_0_2
    · exact tP_0_4
    · exact tP_0_6
  exact patCP_sound an g1 g2 (List.all_eq_true.mp (List.all_eq_true.mp key g1 h1) g2 h2)

/-! ## §12  three slots; table rows as `TwDiv` statements -/

/- §12 — the three-slot twin of `twdiv_of_hat4` (for the complement pairs, s = 0),
   and the table-to-TwDiv statements for all eight supports. -/

theorem twdiv_of_hat3 (ind : Nat → Nat → Nat → Bool) (k1 k2 k3 : Nat)
    (h12 : k1 ≠ k2) (h13 : k1 ≠ k3) (h23 : k2 ≠ k3) (n : Nat)
    (H : ∀ U < 512, ((2 ^ n : Nat) : Int) ∣
      hat (fun i => ind (i / 64 % 8) (i / 8 % 8) (i % 8)) 9 0 U) :
    TwDiv [k1, k2, k3]
      (fun t => if ind (t k1 % 8) (t k2 % 8) (t k3 % 8) then 1 else 0) n := by
  intro u t0
  have hq : ∀ k, u k % 8 < 8 := fun k => Nat.mod_lt _ (by omega)
  generalize hf : (fun i => ind (i / 64 % 8) (i / 8 % 8) (i % 8)) = f at H
  have e : tw [k1, k2, k3]
      (fun t => if ind (t k1 % 8) (t k2 % 8) (t k3 % 8) then 1 else 0) u t0 =
      hat f 9 0 (u k1 % 8 * 2 ^ 6 + (u k2 % 8 * 2 ^ 3 + (u k3 % 8 * 2 ^ 0 + 0))) := by
    have r3 : u k3 % 8 * 2 ^ 0 + 0 < 2 ^ 3 := by have := hq k3; omega
    have r6 : u k2 % 8 * 2 ^ 3 + (u k3 % 8 * 2 ^ 0 + 0) < 2 ^ 6 := by have := hq k2; omega
    rw [hat_digit f 6 0 _ _ (hq k1) r6]
    show (sum8 fun v1 => sum8 fun v2 => sum8 fun v3 =>
        (fun t => (if ind (t k1 % 8) (t k2 % 8) (t k3 % 8) then (1 : Int) else 0) *
          chiProd [k1, k2, k3] u t)
        (upd (upd (upd t0 k1 v1) k2 v2) k3 v3)) = _
    apply sum8_congr_lt; intro v1 hv1
    rw [hat_digit f 3 _ _ _ (hq k2) r3, ← sum8_mul_left]
    apply sum8_congr_lt; intro v2 hv2
    rw [hat_digit f 0 _ _ _ (hq k3) (by omega), ← sum8_mul_left, ← sum8_mul_left]
    apply sum8_congr_lt; intro v3 hv3
    have a1 : upd (upd (upd t0 k1 v1) k2 v2) k3 v3 k1 = v1 := by simp [upd, h12, h13]
    have a2 : upd (upd (upd t0 k1 v1) k2 v2) k3 v3 k2 = v2 := by simp [upd, h23]
    have a3 : upd (upd (upd t0 k1 v1) k2 v2) k3 v3 k3 = v3 := by simp [upd]
    have i1 : (8 * (8 * (8 * 0 + v1) + v2) + v3) / 64 % 8 = v1 := by omega
    have i2 : (8 * (8 * (8 * 0 + v1) + v2) + v3) / 8 % 8 = v2 := by omega
    have i3 : (8 * (8 * (8 * 0 + v1) + v2) + v3) % 8 = v3 := by omega
    have hleaf : hat f 0 (8 * (8 * (8 * 0 + v1) + v2) + v3) 0 = if ind v1 v2 v3 then 1 else 0 := by
      subst hf; show (if ind _ _ _ then (1:Int) else 0) = _
      rw [i1, i2, i3]
    show (if ind _ _ _ then (1 : Int) else 0) *
        (chi' (u k1) _ * (chi' (u k2) _ * (chi' (u k3) _ * 1))) = _
    rw [a1, a2, a3, hleaf, Nat.mod_eq_of_lt hv1, Nat.mod_eq_of_lt hv2, Nat.mod_eq_of_lt hv3]
    simp only [chi', Nat.mod_eq_of_lt hv1, Nat.mod_eq_of_lt hv2, Nat.mod_eq_of_lt hv3, Int.mul_one]
    ac_rfl
  rw [e]
  exact H _ (by have := hq k1; have := hq k2; have := hq k3; omega)

/-- STEP 4, FINAL FORM (reversible supports): for every support s = 1..7 and every internal
    pattern, Phi_s placed on any four distinct slots has TwDiv exponent 7 - #internal. -/
theorem step4_R (s g1 g2 g3 : Nat) (hs : s ∈ [1, 2, 3, 4, 5, 6, 7]) (h1 : g1 ∈ cls)
    (h2 : g2 ∈ cls) (h3 : g3 ∈ cls) (k1 k2 k3 k4 : Nat)
    (h12 : k1 ≠ k2) (h13 : k1 ≠ k3) (h14 : k1 ≠ k4) (h23 : k2 ≠ k3) (h24 : k2 ≠ k4)
    (h34 : k3 ≠ k4) :
    TwDiv [k1, k2, k3, k4]
      (fun t => if indR s g1 g2 g3 (t k1 % 8) (t k2 % 8) (t k3 % 8) (t k4 % 8) then 1 else 0)
      (7 - cost g1 - cost g2 - cost g3) :=
  twdiv_of_hat4 (indR s g1 g2 g3) k1 k2 k3 k4 h12 h13 h14 h23 h24 h34 _
    (table_spec_R s g1 g2 g3 hs h1 h2 h3)

/-- STEP 4, FINAL FORM (complement pairs): Phi_0 on any three distinct slots. -/
theorem step4_C (an g1 g2 : Nat) (h0 : an ∈ cls) (h1 : g1 ∈ cls) (h2 : g2 ∈ cls)
    (k1 k2 k3 : Nat) (h12 : k1 ≠ k2) (h13 : k1 ≠ k3) (h23 : k2 ≠ k3) :
    TwDiv [k1, k2, k3]
      (fun t => if indC an g1 g2 (t k1 % 8) (t k2 % 8) (t k3 % 8) then 1 else 0)
      (4 - cost an - cost g1 - cost g2) :=
  twdiv_of_hat3 (indC an g1 g2) k1 k2 k3 h12 h13 h23 _ (table_spec_C an g1 g2 h0 h1 h2)

/-! ## §13  the cross-boundary factor and the class formula -/

/-
  §13 — the cross-boundary factor `gam` and the class formula.

    * `gam s s' c v`   — the 0/1 factor of a boundary of class c between supports s and s', as a
                         function of v = t xor t' (the two section coordinates);
    * `class_formula`  — the distance between an exit and the next entry in (support, coordinate)
                         form, all 4096 cases, by kernel `decide`.
  The Walsh divisibility of `gam` (Step 2) is `gam_walsh6` in §17.
-/

/-- the cross-boundary factor as a function of v = t xor t' (the class formula below). -/
def gam (s s' c v : Nat) : Int :=
  if pc3 (s ^^^ s') + 2 * pc3 ((v ^^^ st s) &&& (7 ^^^ (s ^^^ s'))) = c then 1 else 0

/-- the class formula, at hexagram level, all 4096 cases. -/
theorem class_formula : ∀ s < 8, ∀ s' < 8, ∀ t < 8, ∀ t' < 8,
    ham (partner (hexof s t)) (hexof s' t') =
      pc3 (s ^^^ s') + 2 * pc3 (((t ^^^ t') ^^^ st s) &&& (7 ^^^ (s ^^^ s'))) := by decide +kernel

/-! ## §14  the coordinate model of a skeleton fibre -/

/-
  §14 — the coordinate model of a skeleton fibre, in the `sumOver` language the
  Step-3 induction works in.

  A walk with skeleton sigma is the same thing as an assignment t : slots 1..31 -> F_2^3
  (slot k holds the pair whose entry hexagram is `hexof (sigma k) (t k)`); `W` is the 0/1
  indicator of "all 32 pairs distinct, every boundary has its prescribed class".

    FibreCDvd  — 2^20 divides the coordinate-model fibre  (Steps 2-5 of the proof).
                        A `def : Prop`; it is PROVED in §19
                        (`fibreC_dvd`).
  The link from sequences to this model is `cell_eq` (§23).  The model never reads
  sigma 0 (slot 0 is the anchor pair {63, 0}) and does not itself impose the budget on c.
  The controls at the end check on King Wen itself that `W` accepts the real sequence.
-/

/-- entry hexagram of slot k (slot 0 is the anchor, entry 63, exit 0). -/
def entry (σ : Nat → Nat) (t : Asg) (k : Nat) : Nat :=
  if k = 0 then 63 else hexof (σ k) (t k % 8)

/-- class of boundary k (slot k -> slot k+1). -/
def clsAt (σ : Nat → Nat) (t : Asg) (k : Nat) : Nat :=
  ham (partner (entry σ t k)) (entry σ t (k+1))

def distinctOK (σ : Nat → Nat) (t : Asg) : Bool :=
  (List.range 32).all fun i => (List.range 32).all fun j =>
    !(decide (i < j)) || !samePair (entry σ t i) (entry σ t j)

/-- the 0/1 weight of an assignment. -/
def W (σ c : Nat → Nat) (t : Asg) : Int :=
  if distinctOK σ t && (List.range 31).all (fun k => clsAt σ t k == c k) then 1 else 0

/-- the coordinate-model fibre F(sigma, c). -/
def fibreC (σ c : Nat → Nat) : Int := sumOver (List.range' 1 31) (W σ c) (fun _ => 0)

/-- King Wen's boundary budget {1:2, 2:8, 3:13, 4:7, 6:1}. -/
def budgetOK (c : Nat → Nat) : Bool :=
  let l := (List.range 31).map c
  (l.filter (· == 1)).length == 2 && (l.filter (· == 2)).length == 8 &&
  (l.filter (· == 3)).length == 13 && (l.filter (· == 4)).length == 7 &&
  (l.filter (· == 6)).length == 1

/-- Steps 2-5: every coordinate-model fibre is divisible by 2^20.
    Proved as `fibreC_dvd` in §19. -/
def FibreCDvd : Prop :=
  ∀ σ c : Nat → Nat, (∀ k, σ k < 8) → budgetOK c = true → ((2 ^ 20 : Nat) : Int) ∣ fibreC σ c

/-- control: the model accepts King Wen (sigma, c, t read off the sequence itself). -/
theorem kw_in_model :
    W (fun k => (skel KW).getD k 0) (fun k => (bseq KW).getD k 0) (fun k => KW.getD (2*k) 0 % 8) = 1 := by
  decide +kernel
theorem kw_budget : budgetOK (fun k => (bseq KW).getD k 0) = true := by decide +kernel
/-- control: the model rejects a wrong class sequence (boundary 0 set to class 4). -/
theorem kw_model_mut :
    W (fun k => (skel KW).getD k 0) (fun k => if k = 0 then 4 else (bseq KW).getD k 0)
      (fun k => KW.getD (2*k) 0 % 8) = 0 := by decide +kernel

/-! ## §15  discrimination controls for the table (must-fail claims) -/

-- Discrimination controls for the table gate. Each `false` is a claim one notch stronger
-- than the table and must FAIL; so the gate is not vacuous.
-- mu_free is exactly 7 (R) / 4 (C): the next power fails.
theorem mut_free_R : allDiv 8 12 (P (fun i => indR 1 0 0 0 (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)) 12 0) = false := by decide +kernel
theorem mut_free_C : allDiv 5 9 (P (fun i => indC 0 0 0 (i / 64 % 8) (i / 8 % 8) (i % 8)) 9 0) = false := by decide +kernel
-- an internal class-2 boundary really costs a factor: 2^7 fails for pattern (2,0,0) on s=1.
theorem mut_cost : allDiv 7 12 (P (fun i => indR 1 2 0 0 (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)) 12 0) = false := by decide +kernel
-- the count (coefficient at u = 0, the top field) of the free pattern is 384 (R) and 48 (C):
theorem ctl_count_R : P (fun i => indR 1 0 0 0 (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)) 12 0 % 65536 = 384 + 4095 := by decide +kernel
theorem ctl_count_C : P (fun i => indC 0 0 0 (i / 64 % 8) (i / 8 % 8) (i % 8)) 9 0 % 65536 = 48 + 511 := by decide +kernel
-- cross-implementation control: whole packed transform of (s=3; 2,4,0) mod 2^61-1, value computed independently in Python by a direct 4096 x 4096 character sum (no fast transform).
theorem ctl_py : P (fun i => indR 3 2 4 0 (i / 512 % 8) (i / 64 % 8) (i / 8 % 8) (i % 8)) 12 0 % 2305843009213693951 = 960912253840699201 := by decide +kernel
-- hexof / supp are mutually consistent on all 64 hexagrams, and partner keeps the support.
theorem hexof_supp : ((List.range 8).all fun s => (List.range 8).all fun t =>
    supp (hexof s t) == s && hexof s t % 8 == t && hexof s t < 64 &&
    supp (partner (hexof s t)) == s &&
    partner (hexof s t) == hexof s (t ^^^ (if s == 0 then 7 else s))) = true := by decide

/-! ## §16  discrimination controls for the fast form -/

-- Discrimination controls for the fast form of the gate (pruned transform + halving check).
-- Each line is a claim one notch STRONGER than a table row; it must be false.
theorem pm_free_R : chk 8 12 (PR (aliveR 1 0 0) (indRc 1 0 0 0) 12 0) = false := by decide +kernel
theorem pm_cost_2 : chk 7 12 (PR (aliveR 1 2 0) (indRc 1 2 0 0) 12 0) = false := by decide +kernel
theorem pm_cost_6 : chk 7 12 (PR (aliveR 1 6 0) (indRc 1 6 0 0) 12 0) = false := by decide +kernel
theorem pm_free_C : chk 5 9 (P (fun i => indC 0 0 0 (i / 64 % 8) (i / 8 % 8) (i % 8)) 9 0) = false := by decide +kernel
-- the pruned transform is the same NUMBER as the unpruned hexagram-level one (not just same verdict):
theorem pm_same : PR (aliveR 3 2 4) (indRc 3 2 4 0) 12 0 % 2305843009213693951 = 960912253840699201 := by decide +kernel

/-! ## §17  general wrappers around Steps 2-4 -/

/-
  §17 — general wrappers around the Step 2-4 lemmas.

    * `twdiv_zero`, `twdiv_mono`, `twdiv_blocks`  — TwDiv housekeeping (a function that is
      identically 0; a smaller exponent; a product of any number of blocks on disjoint slots);
    * `step4_R'`, `step4_C'`  — Step 4 for ARBITRARY prescribed gap classes (a class outside
      {2,4,6} at an internal boundary makes the indicator identically 0);
    * `gam_dvd`, `anc_dvd`    — Step 2 for every cross boundary (s != s', classes 1,2,3,4,6) and
      for the anchor boundary, in the form `twdiv_cross` / `twdiv_slot` take;
    * `sumN` and the counting lemmas Step 5 uses.
-/

/- ---------- TwDiv housekeeping ---------- -/

theorem twdiv_zero (K : List Nat) (h : Asg → Int) (n : Nat) (h0 : ∀ t, h t = 0) : TwDiv K h n := by
  intro u t0
  have e : tw K h u t0 = 0 := by
    show sumOver K (fun t => h t * chiProd K u t) t0 = 0
    rw [sumOver_congr K (G := fun t => 0 * chiProd K u t) (fun t => by rw [h0 t]),
      sumOver_const_mul, Int.zero_mul]
  rw [e]; exact Int.dvd_zero _

theorem twdiv_mono (K : List Nat) (h : Asg → Int) (m n : Nat) (hmn : m ≤ n) (H : TwDiv K h n) :
    TwDiv K h m := fun u t0 =>
  Int.dvd_trans (Int.natCast_dvd_natCast.mpr (Nat.pow_dvd_pow 2 hmn)) (H u t0)

/-- sum of f over 0..n-1. -/
def sumN (f : Nat → Nat) : Nat → Nat
  | 0 => 0
  | n+1 => sumN f n + f n

def catK (K : Nat → List Nat) : Nat → List Nat
  | 0 => []
  | n+1 => catK K n ++ K n

def prodF (Φ : Nat → Asg → Int) : Nat → Asg → Int
  | 0 => fun _ => 1
  | n+1 => fun t => prodF Φ n t * Φ n t

theorem mem_catK (K : Nat → List Nat) (n k : Nat) : k ∈ catK K n ↔ ∃ s, s < n ∧ k ∈ K s := by
  induction n with
  | zero => simp [catK]
  | succ n ih =>
    simp only [catK, List.mem_append, ih]
    constructor
    · rintro (⟨s, hs, hk⟩ | hk)
      · exact ⟨s, by omega, hk⟩
      · exact ⟨n, by omega, hk⟩
    · rintro ⟨s, hs, hk⟩
      by_cases e : s = n
      · subst e; exact Or.inr hk
      · exact Or.inl ⟨s, by omega, hk⟩

theorem prodF_indep (Φ : Nat → Asg → Int) (n k : Nat) (h : ∀ s, s < n → Indep (Φ s) k) :
    Indep (prodF Φ n) k := by
  induction n with
  | zero => intro t v; rfl
  | succ n ih =>
    intro t v
    show prodF Φ n (upd t k v) * Φ n (upd t k v) = prodF Φ n t * Φ n t
    rw [ih (fun s hs => h s (by omega)) t v, h n (by omega) t v]

/-- any number of factors on pairwise disjoint slot sets: exponents add. -/
theorem twdiv_blocks (K : Nat → List Nat) (Φ : Nat → Asg → Int) (μ : Nat → Nat) (n : Nat)
    (hT : ∀ s, s < n → TwDiv (K s) (Φ s) (μ s))
    (hI : ∀ s, s < n → ∀ k, k ∉ K s → Indep (Φ s) k)
    (hD : ∀ s, s < n → ∀ s', s' < n → ∀ k, k ∈ K s → k ∈ K s' → s = s') :
    TwDiv (catK K n) (prodF Φ n) (sumN μ n) := by
  induction n with
  | zero => intro u t0; exact Int.one_dvd _
  | succ n ih =>
    have IH := ih (fun s hs => hT s (by omega)) (fun s hs => hI s (by omega))
      (fun s hs s' hs' => hD s (by omega) s' (by omega))
    exact twdiv_append (catK K n) (K n) (prodF Φ n) (Φ n) (sumN μ n) (μ n)
      (fun k hk => prodF_indep Φ n k fun s hs =>
        hI s (by omega) k fun hks => by
          have := hD s (by omega) n (by omega) k hks hk; omega)
      (fun k hk => hI n (by omega) k fun hkn => by
        obtain ⟨s, hs, hks⟩ := (mem_catK K n k).mp hk
        have := hD s (by omega) n (by omega) k hks hkn; omega)
      (fun k hk hkn => by
        obtain ⟨s, hs, hks⟩ := (mem_catK K n k).mp hk
        have := hD s (by omega) n (by omega) k hks hkn; omega)
      IH (hT n (by omega))

/-- products of 0/1 indicators are the indicator of the conjunction. -/
theorem ind_mul (a b : Bool) :
    (if a then (1 : Int) else 0) * (if b then 1 else 0) = if (a && b) then 1 else 0 := by
  cases a <;> cases b <;> rfl

theorem prodF_ind (B : Nat → Asg → Bool) (n : Nat) (t : Asg) :
    prodF (fun s t => if B s t then 1 else 0) n t =
      if (List.range n).all (fun s => B s t) then 1 else 0 := by
  induction n with
  | zero => rfl
  | succ n ih =>
    show prodF _ n t * (if B n t then 1 else 0) = _
    rw [ih, ind_mul, List.range_succ, List.all_append]
    simp

/- ---------- Step 4 for arbitrary gap classes ---------- -/

/-- an internal boundary between two different pairs of one support has class 2, 4 or 6. -/
theorem intern_cls : ∀ s < 8, ∀ t < 8, ∀ t' < 8,
    (samePair (hexof s t) (hexof s t') ||
      [2, 4, 6].contains (ham (partner (hexof s t)) (hexof s t'))) = true := by decide +kernel

theorem anchor_cls : ∀ t < 8,
    (samePair (hexof 0 t) 63 || [2, 4, 6].contains (ham 0 (hexof 0 t))) = true := by decide +kernel

theorem gap_bad (s g t t' : Nat) (hs : s < 8) (ht : t < 8) (ht' : t' < 8) (hg : g ∉ cls)
    (hsp : samePair (hexof s t) (hexof s t') = false) :
    gapOk g (hexof s t) (hexof s t') = false := by
  have key := intern_cls s hs t ht t' ht'
  rw [hsp] at key
  simp only [cls, List.mem_cons, List.not_mem_nil, or_false, not_or] at hg
  simp only [Bool.false_or, List.contains_cons, List.contains_nil, Bool.or_false, Bool.or_eq_true,
    beq_iff_eq] at key
  simp only [gapOk, Bool.or_eq_false_iff, beq_eq_false_iff_ne, ne_eq]
  omega

theorem indR_iff (s g1 g2 g3 t1 t2 t3 t4 : Nat) :
    indR s g1 g2 g3 t1 t2 t3 t4 = true ↔
      (samePair (hexof s t1) (hexof s t2) = false ∧ gapOk g1 (hexof s t1) (hexof s t2) = true ∧
       samePair (hexof s t2) (hexof s t3) = false ∧ gapOk g2 (hexof s t2) (hexof s t3) = true ∧
       samePair (hexof s t1) (hexof s t3) = false ∧
       samePair (hexof s t3) (hexof s t4) = false ∧ gapOk g3 (hexof s t3) (hexof s t4) = true ∧
       samePair (hexof s t1) (hexof s t4) = false ∧ samePair (hexof s t2) (hexof s t4) = false) := by
  simp only [indR, Bool.and_eq_true, Bool.not_eq_true', and_assoc]

theorem indC_iff (an g1 g2 t1 t2 t3 : Nat) :
    indC an g1 g2 t1 t2 t3 = true ↔
      (samePair (hexof 0 t1) 63 = false ∧ (an == 0 || ham 0 (hexof 0 t1) == an) = true ∧
       samePair (hexof 0 t2) 63 = false ∧ samePair (hexof 0 t1) (hexof 0 t2) = false ∧
       gapOk g1 (hexof 0 t1) (hexof 0 t2) = true ∧
       samePair (hexof 0 t3) 63 = false ∧ samePair (hexof 0 t2) (hexof 0 t3) = false ∧
       gapOk g2 (hexof 0 t2) (hexof 0 t3) = true ∧
       samePair (hexof 0 t1) (hexof 0 t3) = false) := by
  simp only [indC, Bool.and_eq_true, Bool.not_eq_true', and_assoc]

theorem indR_bad (s g1 g2 g3 t1 t2 t3 t4 : Nat) (hs : s < 8) (h1 : t1 < 8) (h2 : t2 < 8)
    (h3 : t3 < 8) (h4 : t4 < 8) (hbad : ¬ (g1 ∈ cls ∧ g2 ∈ cls ∧ g3 ∈ cls)) :
    indR s g1 g2 g3 t1 t2 t3 t4 = false := by
  cases hv : indR s g1 g2 g3 t1 t2 t3 t4 with
  | false => rfl
  | true =>
    obtain ⟨a1, b1, a2, b2, _, a3, b3, _, _⟩ := (indR_iff ..).mp hv
    exfalso; apply hbad
    refine ⟨?_, ?_, ?_⟩
    · exact Classical.byContradiction fun hg => by
        have := gap_bad s g1 t1 t2 hs h1 h2 hg a1; rw [b1] at this; cases this
    · exact Classical.byContradiction fun hg => by
        have := gap_bad s g2 t2 t3 hs h2 h3 hg a2; rw [b2] at this; cases this
    · exact Classical.byContradiction fun hg => by
        have := gap_bad s g3 t3 t4 hs h3 h4 hg a3; rw [b3] at this; cases this

theorem indC_bad (an g1 g2 t1 t2 t3 : Nat) (h1 : t1 < 8) (h2 : t2 < 8) (h3 : t3 < 8)
    (hbad : ¬ (an ∈ cls ∧ g1 ∈ cls ∧ g2 ∈ cls)) :
    indC an g1 g2 t1 t2 t3 = false := by
  cases hv : indC an g1 g2 t1 t2 t3 with
  | false => rfl
  | true =>
    obtain ⟨a0, b0, _, a1, b1, _, a2, b2, _⟩ := (indC_iff ..).mp hv
    exfalso; apply hbad
    refine ⟨?_, ?_, ?_⟩
    · exact Classical.byContradiction fun hg => by
        have key := anchor_cls t1 h1
        rw [a0] at key
        simp only [cls, List.mem_cons, List.not_mem_nil, or_false, not_or] at hg
        simp only [Bool.false_or, List.contains_cons, List.contains_nil, Bool.or_false,
          Bool.or_eq_true, beq_iff_eq] at key b0
        omega
    · exact Classical.byContradiction fun hg => by
        have := gap_bad 0 g1 t1 t2 (by omega) h1 h2 hg a1; rw [b1] at this; cases this
    · exact Classical.byContradiction fun hg => by
        have := gap_bad 0 g2 t2 t3 (by omega) h2 h3 hg a2; rw [b2] at this; cases this

/-- STEP 4 for arbitrary prescribed gap classes (reversible supports). -/
theorem step4_R' (s g1 g2 g3 : Nat) (hs : s ∈ [1, 2, 3, 4, 5, 6, 7]) (k1 k2 k3 k4 : Nat)
    (h12 : k1 ≠ k2) (h13 : k1 ≠ k3) (h14 : k1 ≠ k4) (h23 : k2 ≠ k3) (h24 : k2 ≠ k4)
    (h34 : k3 ≠ k4) :
    TwDiv [k1, k2, k3, k4]
      (fun t => if indR s g1 g2 g3 (t k1 % 8) (t k2 % 8) (t k3 % 8) (t k4 % 8) then 1 else 0)
      (7 - cost g1 - cost g2 - cost g3) := by
  by_cases hg : g1 ∈ cls ∧ g2 ∈ cls ∧ g3 ∈ cls
  · exact step4_R s g1 g2 g3 hs hg.1 hg.2.1 hg.2.2 k1 k2 k3 k4 h12 h13 h14 h23 h24 h34
  · have hs8 : s < 8 := by
      simp only [List.mem_cons, List.not_mem_nil, or_false] at hs; omega
    apply twdiv_zero
    intro t
    have m : ∀ k, t k % 8 < 8 := fun k => Nat.mod_lt _ (by omega)
    rw [indR_bad s g1 g2 g3 _ _ _ _ hs8 (m k1) (m k2) (m k3) (m k4) hg]; rfl

/-- STEP 4 for arbitrary prescribed classes (complement pairs). -/
theorem step4_C' (an g1 g2 : Nat) (k1 k2 k3 : Nat) (h12 : k1 ≠ k2) (h13 : k1 ≠ k3)
    (h23 : k2 ≠ k3) :
    TwDiv [k1, k2, k3]
      (fun t => if indC an g1 g2 (t k1 % 8) (t k2 % 8) (t k3 % 8) then 1 else 0)
      (4 - cost an - cost g1 - cost g2) := by
  by_cases hg : an ∈ cls ∧ g1 ∈ cls ∧ g2 ∈ cls
  · exact step4_C an g1 g2 hg.1 hg.2.1 hg.2.2 k1 k2 k3 h12 h13 h23
  · apply twdiv_zero
    intro t
    have m : ∀ k, t k % 8 < 8 := fun k => Nat.mod_lt _ (by omega)
    rw [indC_bad an g1 g2 _ _ _ (m k1) (m k2) (m k3) hg]; rfl

/- ---------- Step 2 for every cross boundary and for the anchor ---------- -/

/-- Step 2, classes 1,2,3,4,6 (class 6 never occurs across supports: gamma is then 0). -/
theorem gam_walsh6 : ∀ s < 8, ∀ s' < 8, s ≠ s' → ∀ c ∈ [1, 2, 3, 4, 6], ∀ w < 8,
    (sum8 fun v => gam s s' c v * chi w v) % ((2 ^ (3 - eCross s s' c) : Nat) : Int) = 0 := by
  decide +kernel

theorem gam_dvd (s s' c : Nat) (hs : s < 8) (hs' : s' < 8) (hne : s ≠ s')
    (hc : c ∈ [1, 2, 3, 4, 6]) (w : Nat) :
    ((2 ^ (3 - eCross s s' c) : Nat) : Int) ∣ sum8 fun v => gam s s' c v * chi' w v := by
  have h := gam_walsh6 s hs s' hs' hne c hc (w % 8) (Nat.mod_lt _ (by omega))
  simp only [sum8] at h ⊢
  exact Int.dvd_of_emod_eq_zero h

/-- the anchor-boundary factor: exit 0 of the anchor pair, then the entry of slot 1. -/
def anc (s c v : Nat) : Int := if ham 0 (hexof s v) == c then 1 else 0

theorem anc_walsh : ∀ s < 8, s ≠ 0 → ∀ c ∈ [1, 2, 3, 4, 6], ∀ w < 8,
    (sum8 fun v => anc s c v * chi w v) % ((2 ^ (3 - eCross 0 s c) : Nat) : Int) = 0 := by
  decide +kernel

theorem anc_dvd (s c : Nat) (hs : s < 8) (hne : s ≠ 0) (hc : c ∈ [1, 2, 3, 4, 6]) (w : Nat) :
    ((2 ^ (3 - eCross 0 s c) : Nat) : Int) ∣ sum8 fun v => anc s c v * chi' w v := by
  have h := anc_walsh s hs hne c hc (w % 8) (Nat.mod_lt _ (by omega))
  simp only [sum8] at h ⊢
  exact Int.dvd_of_emod_eq_zero h

/-- controls: the exponents are exact somewhere (class 1 across one coordinate; anchor class 1). -/
theorem gam_mut : ¬ ((sum8 fun v => gam 1 3 1 v * chi 0 v) % ((2 ^ 2 : Nat) : Int) = 0) := by
  decide +kernel
theorem anc_mut : ¬ ((sum8 fun v => anc 1 1 v * chi 0 v) % ((2 ^ 2 : Nat) : Int) = 0) := by
  decide +kernel
/-- control: class 5 across one coordinate would NOT satisfy the table (so excluding it matters). -/
theorem gam_mut5 : ¬ ((sum8 fun v => gam 0 1 5 v * chi 0 v) % ((2 ^ (3 - eCross 0 1 5) : Nat) : Int) = 0) := by
  decide +kernel

theorem eCross_le (s s' c : Nat) : eCross s s' c ≤ (if c == 1 then 2 else 1) := by
  unfold eCross
  split
  · omega
  · split
    · split <;> omega
    · omega

/- ---------- sums over 0..n-1 ---------- -/

theorem sumN_le (f g : Nat → Nat) (n : Nat) (h : ∀ k, k < n → f k ≤ g k) : sumN f n ≤ sumN g n := by
  induction n with
  | zero => exact Nat.le_refl _
  | succ n ih =>
    have := ih (fun k hk => h k (by omega)); have := h n (by omega)
    show sumN f n + f n ≤ sumN g n + g n; omega

theorem sumN_add (f g : Nat → Nat) (n : Nat) : sumN (fun k => f k + g k) n = sumN f n + sumN g n := by
  induction n with
  | zero => rfl
  | succ n ih => show sumN _ n + (f n + g n) = sumN f n + f n + (sumN g n + g n); omega

theorem sumN_mono (f : Nat → Nat) (m n : Nat) (h : m ≤ n) : sumN f m ≤ sumN f n := by
  induction n with
  | zero => have : m = 0 := by omega
            subst this; exact Nat.le_refl _
  | succ n ih =>
    by_cases e : m = n + 1
    · subst e; exact Nat.le_refl _
    · have := ih (by omega); show sumN f m ≤ sumN f n + f n; omega

theorem sumN_term (f : Nat → Nat) (a n : Nat) (h : a < n) : sumN f a + f a ≤ sumN f n :=
  sumN_mono f (a+1) n h

/-- three distinct terms are at most the whole sum. -/
theorem sumN_three (f : Nat → Nat) (a b c n : Nat) (hab : a < b) (hbc : b < c) (hc : c < n) :
    f a + f b + f c ≤ sumN f n := by
  have h1 := sumN_term f a b hab
  have h2 := sumN_term f b c hbc
  have h3 := sumN_term f c n hc
  omega

theorem catK_length (K : Nat → List Nat) (n : Nat) :
    (catK K n).length = sumN (fun s => (K s).length) n := by
  induction n with
  | zero => rfl
  | succ n ih => show (catK K n ++ K n).length = _; rw [List.length_append, ih]; rfl

/-! ## §18  book-keeping for a general skeleton -/

/-
  §18 — book-keeping for a GENERAL skeleton sigma : slots -> supports.

    * `Ks sigma s`     — the slots 1..31 of support s, in increasing order;
    * `catK_perm`      — the eight classes, concatenated, are a permutation of the slots;
    * `Q4_of_len`, `Q3_of_len` — a class of the right size, written as explicit slots a<b<c<d
                         together with "these are exactly the slots of support s";
    * `budget_cls`, `budget_w` — what Step 5 needs from King Wen's budget: every class is one of
                         1,2,3,4,6, and  sum_k w(c_k) = 31 + b1 = 33  (w = 2 for class 1, else 1);
    * `pig5`, `cq`     — five entries of one support cannot lie in four pairs.
-/

def slots : List Nat := List.range' 1 31

theorem mem_slots (k : Nat) : k ∈ slots ↔ (1 ≤ k ∧ k ≤ 31) := by
  unfold slots; rw [List.mem_range'_1]; omega

def Ksl (σ : Nat → Nat) (l : List Nat) (s : Nat) : List Nat := l.filter fun k => σ k == s

theorem mem_Ksl (σ : Nat → Nat) (l : List Nat) (s k : Nat) : k ∈ Ksl σ l s ↔ (k ∈ l ∧ σ k = s) := by
  simp [Ksl]

theorem Ksl_cons_ne (σ : Nat → Nat) (a : Nat) (l : List Nat) (n : Nat) (h : σ a ≠ n) :
    Ksl σ (a :: l) n = Ksl σ l n := by
  have : (σ a == n) = false := by simpa using h
  simp [Ksl, this]

theorem Ksl_cons_eq (σ : Nat → Nat) (a : Nat) (l : List Nat) (n : Nat) (h : σ a = n) :
    Ksl σ (a :: l) n = a :: Ksl σ l n := by
  simp [Ksl, h]

theorem catK_cons_ge (σ : Nat → Nat) (a : Nat) (l : List Nat) (n : Nat) (h : n ≤ σ a) :
    catK (Ksl σ (a :: l)) n = catK (Ksl σ l) n := by
  induction n with
  | zero => rfl
  | succ n ih =>
    show catK (Ksl σ (a :: l)) n ++ Ksl σ (a :: l) n = catK (Ksl σ l) n ++ Ksl σ l n
    rw [ih (by omega), Ksl_cons_ne σ a l n (by omega)]

theorem catK_cons_perm (σ : Nat → Nat) (a : Nat) (l : List Nat) (n : Nat) (h : σ a < n) :
    (catK (Ksl σ (a :: l)) n).Perm (a :: catK (Ksl σ l) n) := by
  induction n with
  | zero => omega
  | succ n ih =>
    show (catK (Ksl σ (a :: l)) n ++ Ksl σ (a :: l) n).Perm (a :: (catK (Ksl σ l) n ++ Ksl σ l n))
    by_cases e : σ a = n
    · rw [catK_cons_ge σ a l n (by omega), Ksl_cons_eq σ a l n e]
      exact List.perm_middle
    · rw [Ksl_cons_ne σ a l n e]
      exact (ih (by omega)).append_right _

theorem catK_nil (σ : Nat → Nat) (n : Nat) : catK (Ksl σ []) n = [] := by
  induction n with
  | zero => rfl
  | succ n ih => show catK (Ksl σ []) n ++ Ksl σ [] n = []; rw [ih]; rfl

/-- the support classes, concatenated, are a permutation of the slots. -/
theorem catK_perm (σ : Nat → Nat) (l : List Nat) (n : Nat) (h : ∀ k, k ∈ l → σ k < n) :
    (catK (Ksl σ l) n).Perm l := by
  induction l with
  | nil => rw [catK_nil]
  | cons a l ih =>
    exact (catK_cons_perm σ a l n (h a List.mem_cons_self)).trans
      (List.Perm.cons a (ih fun k hk => h k (List.mem_cons_of_mem _ hk)))

/-- slots of support s, increasing. -/
def Ks (σ : Nat → Nat) (s : Nat) : List Nat := Ksl σ slots s
/-- the i-th slot of support s. -/
def kk (σ : Nat → Nat) (s i : Nat) : Nat := (Ks σ s).getD i 0

theorem mem_Ks (σ : Nat → Nat) (s k : Nat) : k ∈ Ks σ s ↔ (1 ≤ k ∧ k ≤ 31 ∧ σ k = s) := by
  unfold Ks; rw [mem_Ksl, mem_slots]; exact and_assoc

theorem Ks_sorted (σ : Nat → Nat) (s : Nat) : (Ks σ s).Pairwise (· < ·) :=
  List.Pairwise.filter _ List.pairwise_lt_range'

def Q4 (σ : Nat → Nat) (s a b c d : Nat) : Prop :=
  a < b ∧ b < c ∧ c < d ∧ ∀ k, (1 ≤ k ∧ k ≤ 31 ∧ σ k = s) ↔ (k = a ∨ k = b ∨ k = c ∨ k = d)
def Q3 (σ : Nat → Nat) (a b c : Nat) : Prop :=
  a < b ∧ b < c ∧ ∀ k, (1 ≤ k ∧ k ≤ 31 ∧ σ k = 0) ↔ (k = a ∨ k = b ∨ k = c)

theorem Ks_eq4 (σ : Nat → Nat) (s : Nat) (h : (Ks σ s).length = 4) :
    Ks σ s = [kk σ s 0, kk σ s 1, kk σ s 2, kk σ s 3] := by
  unfold kk
  generalize Ks σ s = l at h ⊢
  match l, h with
  | [a, b, c, d], _ => rfl

theorem Ks_eq3 (σ : Nat → Nat) (s : Nat) (h : (Ks σ s).length = 3) :
    Ks σ s = [kk σ s 0, kk σ s 1, kk σ s 2] := by
  unfold kk
  generalize Ks σ s = l at h ⊢
  match l, h with
  | [a, b, c], _ => rfl

theorem Q4_of_len (σ : Nat → Nat) (s : Nat) (h : (Ks σ s).length = 4) :
    Q4 σ s (kk σ s 0) (kk σ s 1) (kk σ s 2) (kk σ s 3) := by
  have e := Ks_eq4 σ s h
  have hp := Ks_sorted σ s
  have hm := mem_Ks σ s
  generalize kk σ s 0 = a at e
  generalize kk σ s 1 = b at e
  generalize kk σ s 2 = c at e
  generalize kk σ s 3 = d at e
  rw [e] at hp hm
  have h1 := List.pairwise_cons.mp hp
  have h2 := List.pairwise_cons.mp h1.2
  have h3 := List.pairwise_cons.mp h2.2
  refine ⟨h1.1 b (by simp), h2.1 c (by simp), h3.1 d (by simp), fun k => ?_⟩
  rw [← hm k]; simp

theorem Q3_of_len (σ : Nat → Nat) (h : (Ks σ 0).length = 3) :
    Q3 σ (kk σ 0 0) (kk σ 0 1) (kk σ 0 2) := by
  have e := Ks_eq3 σ 0 h
  have hp := Ks_sorted σ 0
  have hm := mem_Ks σ 0
  generalize kk σ 0 0 = a at e
  generalize kk σ 0 1 = b at e
  generalize kk σ 0 2 = c at e
  rw [e] at hp hm
  have h1 := List.pairwise_cons.mp hp
  have h2 := List.pairwise_cons.mp h1.2
  refine ⟨h1.1 b (by simp), h2.1 c (by simp), fun k => ?_⟩
  rw [← hm k]; simp

/-- pick the pair (i, j), i < j, out of four increasing slots. -/
theorem q4_pair (P : Nat → Nat → Prop) (a b c d i j : Nat) (hab : a < b) (hbc : b < c)
    (hcd : c < d) (hi : i = a ∨ i = b ∨ i = c ∨ i = d) (hj : j = a ∨ j = b ∨ j = c ∨ j = d)
    (hij : i < j) (p12 : P a b) (p13 : P a c) (p14 : P a d) (p23 : P b c) (p24 : P b d)
    (p34 : P c d) : P i j := by
  rcases hi with h | h | h | h <;> rcases hj with h' | h' | h' | h' <;> subst h <;> subst h' <;>
    first | assumption | (exfalso; omega)

theorem q3_pair (P : Nat → Nat → Prop) (a b c i j : Nat) (hab : a < b) (hbc : b < c)
    (hi : i = a ∨ i = b ∨ i = c) (hj : j = a ∨ j = b ∨ j = c)
    (hij : i < j) (p12 : P a b) (p13 : P a c) (p23 : P b c) : P i j := by
  rcases hi with h | h | h <;> rcases hj with h' | h' | h' <;> subst h <;> subst h' <;>
    first | assumption | (exfalso; omega)

/- ---------- the budget ---------- -/

/-- cost bound of a boundary of class c: 2 for class 1, else 1. -/
def wcls (c : Nat) : Nat := if c == 1 then 2 else 1

theorem count_cls (l : List Nat) :
    (l.filter (· == 1)).length + (l.filter (· == 2)).length + (l.filter (· == 3)).length +
    (l.filter (· == 4)).length + (l.filter (· == 6)).length +
    (l.filter (fun x => !([1, 2, 3, 4, 6].contains x))).length = l.length := by
  induction l with
  | nil => rfl
  | cons a l ih =>
    have h : a = 1 ∨ a = 2 ∨ a = 3 ∨ a = 4 ∨ a = 6 ∨ (a ≠ 1 ∧ a ≠ 2 ∧ a ≠ 3 ∧ a ≠ 4 ∧ a ≠ 6) := by
      omega
    rcases h with h | h | h | h | h | ⟨h1, h2, h3, h4, h6⟩
    · subst h; simp at ih ⊢; omega
    · subst h; simp at ih ⊢; omega
    · subst h; simp at ih ⊢; omega
    · subst h; simp at ih ⊢; omega
    · subst h; simp at ih ⊢; omega
    · simp [h1, h2, h3, h4, h6] at ih ⊢; omega

theorem budget_cls (c : Nat → Nat) (hb : budgetOK c = true) :
    ∀ k, k < 31 → c k ∈ [1, 2, 3, 4, 6] := by
  intro k hk
  simp only [budgetOK, Bool.and_eq_true, beq_iff_eq] at hb
  obtain ⟨⟨⟨⟨b1, b2⟩, b3⟩, b4⟩, b6⟩ := hb
  have hcnt := count_cls ((List.range 31).map c)
  have hl : ((List.range 31).map c).length = 31 := by simp
  have h0 : (((List.range 31).map c).filter (fun x => !([1, 2, 3, 4, 6].contains x))).length = 0 := by
    omega
  have hnil := List.eq_nil_of_length_eq_zero h0
  have hmem : c k ∈ (List.range 31).map c := List.mem_map_of_mem (List.mem_range.mpr hk)
  have := (List.filter_eq_nil_iff.mp hnil) (c k) hmem
  simp only [List.mem_cons, List.not_mem_nil, or_false]
  simp at this
  omega

theorem sumN_w (c : Nat → Nat) (n : Nat) :
    sumN (fun k => wcls (c k)) n = n + (((List.range n).map c).filter (· == 1)).length := by
  induction n with
  | zero => rfl
  | succ n ih =>
    show sumN (fun k => wcls (c k)) n + wcls (c n) = _
    rw [ih, List.range_succ, List.map_append, List.filter_append, List.length_append]
    by_cases h : c n = 1
    · simp [wcls, h]; omega
    · simp [wcls, h]; omega

theorem budget_w (c : Nat → Nat) (hb : budgetOK c = true) : sumN (fun k => wcls (c k)) 31 = 33 := by
  simp only [budgetOK, Bool.and_eq_true, beq_iff_eq] at hb
  obtain ⟨⟨⟨⟨b1, _⟩, _⟩, _⟩, _⟩ := hb
  rw [sumN_w, b1]

/- ---------- five into four ---------- -/

theorem pig5 (q0 q1 q2 q3 q4 : Nat) (h0 : q0 < 4) (h1 : q1 < 4) (h2 : q2 < 4) (h3 : q3 < 4)
    (h4 : q4 < 4) :
    q0 = q1 ∨ q0 = q2 ∨ q0 = q3 ∨ q0 = q4 ∨ q1 = q2 ∨ q1 = q3 ∨ q1 = q4 ∨ q2 = q3 ∨ q2 = q4 ∨
    q3 = q4 := by omega

/-- index (0..3) of the pair of support s that contains section coordinate v. -/
def cq (s v : Nat) : Nat :=
  ((List.range 8).filter fun w => decide (w < (w ^^^ st s))).idxOf (min v (v ^^^ st s))

theorem cq_lt : ∀ s < 8, ∀ v < 8, cq s v < 4 := by decide +kernel
theorem cq_same : ∀ s < 8, ∀ v < 8, ∀ v' < 8, cq s v = cq s v' →
    samePair (hexof s v) (hexof s v') = true := by decide +kernel
/-- control: `cq` does separate different pairs. -/
theorem cq_sep : ∀ s < 8, ∀ v < 8, ∀ v' < 8, samePair (hexof s v) (hexof s v') = true →
    cq s v = cq s v' := by decide +kernel

/-! ## §19  THE COORDINATE-MODEL FIBRE THEOREM (Steps 2-5) -/

/-
  §19 — THE COORDINATE-MODEL FIBRE THEOREM.

      theorem fibreC_dvd : FibreCDvd
      -- for every skeleton sigma (values < 8) and every class sequence c with King Wen's
      -- boundary budget, 2^20 divides the coordinate-model fibre  fibreC sigma c.

  Shape of the proof (Steps 1-5, with Step 3 as the induction of §5):

    A. a support class with too many slots (> 4, or > 3 for s = 0) puts two entries into one
       pair, so W = 0 and the fibre is 0                              (`over_R`, `over_C`);
    B. otherwise every class has exactly 4 (3) slots, and
       1. W = (prod_s Phi_s) * (prod_k Gamma_k) as 0/1 indicators     (`W_eq`);
       2. prod_s Phi_s has TwDiv exponent sum_s mu_s                  (`twdiv_blocks`, Step 4);
       3. each cross boundary lowers the exponent by e_k              (`fold_twdiv`, Steps 2-3);
       4. sum_s mu_s - sum_k e_k >= 53 - (31 + b1) = 20               (`EE_ge`, Step 5).
-/

/-- support of slot k, with the anchor (slot 0) of support 0. -/
def sg (σ : Nat → Nat) (k : Nat) : Nat := if k = 0 then 0 else σ k

/-- prescribed class of the gap a -> b: c_a if the slots are adjacent, else 0 (no constraint). -/
def gp (c : Nat → Nat) (a b : Nat) : Nat := if b = a + 1 then c a else 0

/-- Phi_s as a Boolean, on the slots of support s. -/
def phiB (σ c : Nat → Nat) (s : Nat) (t : Asg) : Bool :=
  if s = 0 then
    indC (gp c 0 (kk σ 0 0)) (gp c (kk σ 0 0) (kk σ 0 1)) (gp c (kk σ 0 1) (kk σ 0 2))
      (t (kk σ 0 0) % 8) (t (kk σ 0 1) % 8) (t (kk σ 0 2) % 8)
  else
    indR s (gp c (kk σ s 0) (kk σ s 1)) (gp c (kk σ s 1) (kk σ s 2)) (gp c (kk σ s 2) (kk σ s 3))
      (t (kk σ s 0) % 8) (t (kk σ s 1) % 8) (t (kk σ s 2) % 8) (t (kk σ s 3) % 8)

def Phi (σ c : Nat → Nat) : Nat → Asg → Int := fun s t => if phiB σ c s t then 1 else 0

/-- the Step-4 exponent of Phi_s. -/
def mu (σ c : Nat → Nat) (s : Nat) : Nat :=
  if s = 0 then
    4 - cost (gp c 0 (kk σ 0 0)) - cost (gp c (kk σ 0 0) (kk σ 0 1)) - cost (gp c (kk σ 0 1) (kk σ 0 2))
  else
    7 - cost (gp c (kk σ s 0) (kk σ s 1)) - cost (gp c (kk σ s 1) (kk σ s 2)) -
      cost (gp c (kk σ s 2) (kk σ s 3))

/-- the boundary-k factor as a Boolean: internal boundaries are Phi's business. -/
def gamB (σ c : Nat → Nat) (k : Nat) (t : Asg) : Bool :=
  decide (sg σ k = sg σ (k+1)) || clsAt σ t k == c k

/-- the boundary-k factor in the form the induction multiplies in. -/
def Gam (σ c : Nat → Nat) (k : Nat) (t : Asg) : Int :=
  if sg σ k = sg σ (k+1) then 1
  else if k = 0 then anc (σ 1) (c 0) (t 1 % 8)
  else gam (σ k) (σ (k+1)) (c k) (cx (t k) (t (k+1)))

/-- product of the Phi's, then the boundary factors 0..j-1. -/
def GG (σ c : Nat → Nat) : Nat → Asg → Int
  | 0 => prodF (Phi σ c) 8
  | j+1 => fun t => GG σ c j t * Gam σ c j t

/-- e_k of a boundary (0 for an internal one). -/
def ce (σ c : Nat → Nat) (k : Nat) : Nat :=
  if sg σ k = sg σ (k+1) then 0 else eCross (sg σ k) (sg σ (k+1)) (c k)

/-- the exponent after j boundaries. -/
def EE (σ c : Nat → Nat) : Nat → Nat
  | 0 => sumN (mu σ c) 8
  | j+1 => EE σ c j + (3 - ce σ c j) - 3

/-- all slots, class by class. -/
def KA (σ : Nat → Nat) : List Nat := catK (Ks σ) 8

/- ---------- entries ---------- -/

theorem entry_pos (σ : Nat → Nat) (t : Asg) (k : Nat) (hk : k ≠ 0) :
    entry σ t k = hexof (σ k) (t k % 8) := by simp [entry, hk]

theorem entry_zero (σ : Nat → Nat) (t : Asg) : entry σ t 0 = 63 := by simp [entry]

theorem hexof_0_7 : hexof 0 7 = 63 := by decide
theorem partner_63 : partner 63 = 0 := by decide

theorem entry_gen (σ : Nat → Nat) (t : Asg) (k : Nat) :
    entry σ t k = hexof (sg σ k) (if k = 0 then 7 else t k % 8) := by
  by_cases hk : k = 0
  · subst hk; simp [entry, sg, hexof_0_7]
  · simp [entry, sg, hk]

/-- pairs of different supports are different pairs. -/
theorem sp_diff : ∀ s < 8, ∀ s' < 8, ∀ v < 8, ∀ v' < 8, s ≠ s' →
    samePair (hexof s v) (hexof s' v') = false := by decide +kernel

theorem sp63 : ∀ v < 8, samePair 63 (hexof 0 v) = samePair (hexof 0 v) 63 := by decide +kernel

theorem distinct_iff (σ : Nat → Nat) (t : Asg) :
    distinctOK σ t = true ↔
      ∀ i j, i < j → j < 32 → samePair (entry σ t i) (entry σ t j) = false := by
  constructor
  · intro h i j hij hj
    have := List.all_eq_true.mp (List.all_eq_true.mp h i (List.mem_range.mpr (by omega))) j
      (List.mem_range.mpr hj)
    simpa [hij] using this
  · intro h
    apply List.all_eq_true.mpr; intro i _
    apply List.all_eq_true.mpr; intro j hj
    by_cases hij : i < j
    · simp [hij, h i j hij (List.mem_range.mp hj)]
    · simp [hij]

/- ---------- A. oversized classes ---------- -/

theorem clash (σ : Nat → Nat) (t : Asg) (s i j : Nat) (hs : s < 8) (hi : 1 ≤ i) (hij : i < j)
    (hj : j ≤ 31) (hσi : σ i = s) (hσj : σ j = s)
    (D : ∀ i j, i < j → j < 32 → samePair (entry σ t i) (entry σ t j) = false)
    (hq : cq s (t i % 8) = cq s (t j % 8)) : False := by
  have h := D i j hij (by omega)
  rw [entry_pos σ t i (by omega), entry_pos σ t j (by omega), hσi, hσj,
    cq_same s hs _ (Nat.mod_lt _ (by omega)) _ (Nat.mod_lt _ (by omega)) hq] at h
  cases h

theorem clash0 (σ : Nat → Nat) (t : Asg) (j : Nat) (hj1 : 1 ≤ j) (hj : j ≤ 31) (hσj : σ j = 0)
    (D : ∀ i j, i < j → j < 32 → samePair (entry σ t i) (entry σ t j) = false)
    (hq : cq 0 7 = cq 0 (t j % 8)) : False := by
  have h := D 0 j (by omega) (by omega)
  have e := cq_same 0 (by omega) 7 (by omega) _ (Nat.mod_lt _ (by omega)) hq
  rw [hexof_0_7] at e
  rw [entry_zero, entry_pos σ t j (by omega), hσj, e] at h
  cases h

theorem W_zero_of_not_distinct (σ c : Nat → Nat) (t : Asg)
    (h : (∀ i j, i < j → j < 32 → samePair (entry σ t i) (entry σ t j) = false) → False) :
    W σ c t = 0 := by
  have hd : distinctOK σ t = false := by
    cases hv : distinctOK σ t with
    | false => rfl
    | true => exact absurd ((distinct_iff σ t).mp hv) h
  simp [W, hd]

/-- five slots of one reversible support: two entries share a pair. -/
theorem over_R (σ c : Nat → Nat) (s : Nat) (hs : s < 8) (h : 5 ≤ (Ks σ s).length) (t : Asg) :
    W σ c t = 0 := by
  apply W_zero_of_not_distinct
  intro D
  have hp := Ks_sorted σ s
  have hm := mem_Ks σ s
  revert h hp hm
  generalize Ks σ s = l
  intro h hp hm
  match l, h with
  | a :: b :: c' :: d :: e :: rest, _ =>
    have h1 := List.pairwise_cons.mp hp
    have h2 := List.pairwise_cons.mp h1.2
    have h3 := List.pairwise_cons.mp h2.2
    have h4 := List.pairwise_cons.mp h3.2
    have ab := h1.1 b (by simp)
    have bc := h2.1 c' (by simp)
    have cd := h3.1 d (by simp)
    have de := h4.1 e (by simp)
    have ma := (hm a).mp (by simp)
    have mb := (hm b).mp (by simp)
    have mc := (hm c').mp (by simp)
    have md := (hm d).mp (by simp)
    have me := (hm e).mp (by simp)
    have m8 : ∀ k, t k % 8 < 8 := fun k => Nat.mod_lt _ (by omega)
    have P := pig5 _ _ _ _ _ (cq_lt s hs _ (m8 a)) (cq_lt s hs _ (m8 b)) (cq_lt s hs _ (m8 c'))
      (cq_lt s hs _ (m8 d)) (cq_lt s hs _ (m8 e))
    rcases P with q | q | q | q | q | q | q | q | q | q
    · exact clash σ t s a b hs ma.1 (by omega) mb.2.1 ma.2.2 mb.2.2 D q
    · exact clash σ t s a c' hs ma.1 (by omega) mc.2.1 ma.2.2 mc.2.2 D q
    · exact clash σ t s a d hs ma.1 (by omega) md.2.1 ma.2.2 md.2.2 D q
    · exact clash σ t s a e hs ma.1 (by omega) me.2.1 ma.2.2 me.2.2 D q
    · exact clash σ t s b c' hs mb.1 (by omega) mc.2.1 mb.2.2 mc.2.2 D q
    · exact clash σ t s b d hs mb.1 (by omega) md.2.1 mb.2.2 md.2.2 D q
    · exact clash σ t s b e hs mb.1 (by omega) me.2.1 mb.2.2 me.2.2 D q
    · exact clash σ t s c' d hs mc.1 (by omega) md.2.1 mc.2.2 md.2.2 D q
    · exact clash σ t s c' e hs mc.1 (by omega) me.2.1 mc.2.2 me.2.2 D q
    · exact clash σ t s d e hs md.1 (by omega) me.2.1 md.2.2 me.2.2 D q

/-- four slots of support 0, plus the anchor pair: two entries share a pair. -/
theorem over_C (σ c : Nat → Nat) (h : 4 ≤ (Ks σ 0).length) (t : Asg) : W σ c t = 0 := by
  apply W_zero_of_not_distinct
  intro D
  have hp := Ks_sorted σ 0
  have hm := mem_Ks σ 0
  revert h hp hm
  generalize Ks σ 0 = l
  intro h hp hm
  match l, h with
  | a :: b :: c' :: d :: rest, _ =>
    have h1 := List.pairwise_cons.mp hp
    have h2 := List.pairwise_cons.mp h1.2
    have h3 := List.pairwise_cons.mp h2.2
    have ab := h1.1 b (by simp)
    have bc := h2.1 c' (by simp)
    have cd := h3.1 d (by simp)
    have ma := (hm a).mp (by simp)
    have mb := (hm b).mp (by simp)
    have mc := (hm c').mp (by simp)
    have md := (hm d).mp (by simp)
    have m8 : ∀ k, t k % 8 < 8 := fun k => Nat.mod_lt _ (by omega)
    have s0 : (0 : Nat) < 8 := by omega
    have P := pig5 _ _ _ _ _ (cq_lt 0 s0 7 (by omega)) (cq_lt 0 s0 _ (m8 a)) (cq_lt 0 s0 _ (m8 b))
      (cq_lt 0 s0 _ (m8 c')) (cq_lt 0 s0 _ (m8 d))
    rcases P with q | q | q | q | q | q | q | q | q | q
    · exact clash0 σ t a ma.1 ma.2.1 ma.2.2 D q
    · exact clash0 σ t b mb.1 mb.2.1 mb.2.2 D q
    · exact clash0 σ t c' mc.1 mc.2.1 mc.2.2 D q
    · exact clash0 σ t d md.1 md.2.1 md.2.2 D q
    · exact clash σ t 0 a b s0 ma.1 (by omega) mb.2.1 ma.2.2 mb.2.2 D q
    · exact clash σ t 0 a c' s0 ma.1 (by omega) mc.2.1 ma.2.2 mc.2.2 D q
    · exact clash σ t 0 a d s0 ma.1 (by omega) md.2.1 ma.2.2 md.2.2 D q
    · exact clash σ t 0 b c' s0 mb.1 (by omega) mc.2.1 mb.2.2 mc.2.2 D q
    · exact clash σ t 0 b d s0 mb.1 (by omega) md.2.1 mb.2.2 md.2.2 D q
    · exact clash σ t 0 c' d s0 mc.1 (by omega) md.2.1 mc.2.2 md.2.2 D q

/- ---------- B.2 the blocks ---------- -/

theorem phi_twdiv_R (σ c : Nat → Nat) (s : Nat) (hs1 : 1 ≤ s) (hs : s < 8)
    (h : (Ks σ s).length = 4) : TwDiv (Ks σ s) (Phi σ c s) (mu σ c s) := by
  have q := Q4_of_len σ s h
  have hs0 : s ≠ 0 := by omega
  have e1 : Phi σ c s = fun t =>
      if indR s (gp c (kk σ s 0) (kk σ s 1)) (gp c (kk σ s 1) (kk σ s 2)) (gp c (kk σ s 2) (kk σ s 3))
        (t (kk σ s 0) % 8) (t (kk σ s 1) % 8) (t (kk σ s 2) % 8) (t (kk σ s 3) % 8) then 1 else 0 := by
    funext t; simp [Phi, phiB, hs0]
  have e2 : mu σ c s = 7 - cost (gp c (kk σ s 0) (kk σ s 1)) - cost (gp c (kk σ s 1) (kk σ s 2)) -
      cost (gp c (kk σ s 2) (kk σ s 3)) := by simp [mu, hs0]
  rw [Ks_eq4 σ s h, e1, e2]
  obtain ⟨hab, hbc, hcd, _⟩ := q
  exact step4_R' s _ _ _ (by simp; omega) _ _ _ _ (by omega) (by omega) (by omega) (by omega)
    (by omega) (by omega)

theorem phi_twdiv_C (σ c : Nat → Nat) (h : (Ks σ 0).length = 3) :
    TwDiv (Ks σ 0) (Phi σ c 0) (mu σ c 0) := by
  have q := Q3_of_len σ h
  have e1 : Phi σ c 0 = fun t =>
      if indC (gp c 0 (kk σ 0 0)) (gp c (kk σ 0 0) (kk σ 0 1)) (gp c (kk σ 0 1) (kk σ 0 2))
        (t (kk σ 0 0) % 8) (t (kk σ 0 1) % 8) (t (kk σ 0 2) % 8) then 1 else 0 := by
    funext t; simp [Phi, phiB]
  have e2 : mu σ c 0 = 4 - cost (gp c 0 (kk σ 0 0)) - cost (gp c (kk σ 0 0) (kk σ 0 1)) -
      cost (gp c (kk σ 0 1) (kk σ 0 2)) := by simp [mu]
  rw [Ks_eq3 σ 0 h, e1, e2]
  obtain ⟨hab, hbc, _⟩ := q
  exact step4_C' _ _ _ _ _ _ (by omega) (by omega) (by omega)

theorem phi_indep (σ c : Nat → Nat) (s k : Nat)
    (h : (s = 0 ∧ (Ks σ 0).length = 3) ∨ (s ≠ 0 ∧ (Ks σ s).length = 4)) (hk : k ∉ Ks σ s) :
    Indep (Phi σ c s) k := by
  intro t v
  rcases h with ⟨h0, hl⟩ | ⟨h0, hl⟩
  · subst h0
    rw [Ks_eq3 σ 0 hl] at hk
    simp only [List.mem_cons, List.not_mem_nil, or_false, not_or] at hk
    obtain ⟨n0, n1, n2⟩ := hk
    simp [Phi, phiB, upd, Ne.symm n0, Ne.symm n1, Ne.symm n2]
  · rw [Ks_eq4 σ s hl] at hk
    simp only [List.mem_cons, List.not_mem_nil, or_false, not_or] at hk
    obtain ⟨n0, n1, n2, n3⟩ := hk
    simp [Phi, phiB, h0, upd, Ne.symm n0, Ne.symm n1, Ne.symm n2, Ne.symm n3]

/- ---------- B.3 the fold over the boundaries ---------- -/

theorem fold_twdiv (σ c : Nat → Nat) (hσ : ∀ k, σ k < 8) (hc : ∀ k, k < 31 → c k ∈ [1, 2, 3, 4, 6])
    (hN : (KA σ).Nodup) (hmem : ∀ k, 1 ≤ k → k ≤ 31 → k ∈ KA σ)
    (H0 : TwDiv (KA σ) (GG σ c 0) (EE σ c 0)) :
    ∀ j, j ≤ 31 → TwDiv (KA σ) (GG σ c j) (EE σ c j) := by
  intro j
  induction j with
  | zero => intro _; exact H0
  | succ j ih =>
    intro hj
    have H := ih (by omega)
    by_cases hint : sg σ j = sg σ (j+1)
    · have e1 : GG σ c (j+1) = GG σ c j := by
        funext t; show GG σ c j t * Gam σ c j t = _; simp [Gam, hint]
      have e2 : EE σ c (j+1) = EE σ c j := by
        show EE σ c j + (3 - ce σ c j) - 3 = _; simp [ce, hint]
      rw [e1, e2]; exact H
    · by_cases hj0 : j = 0
      · subst hj0
        have hs1 : σ 1 ≠ 0 := by
          intro e; apply hint; simp [sg, e]
        have T := twdiv_slot (KA σ) hN 1 (hmem 1 (by omega) (by omega)) (anc (σ 1) (c 0))
          (3 - eCross 0 (σ 1) (c 0)) (anc_dvd (σ 1) (c 0) (hσ 1) hs1 (hc 0 (by omega)))
          (GG σ c 0) (EE σ c 0) H
        have e1 : GG σ c (0+1) = fun t => GG σ c 0 t * anc (σ 1) (c 0) (t 1 % 8) := by
          funext t; show GG σ c 0 t * Gam σ c 0 t = _
          have : Gam σ c 0 t = anc (σ 1) (c 0) (t 1 % 8) := by
            unfold Gam; rw [if_neg hint, if_pos rfl]
          rw [this]
        have e2 : EE σ c (0+1) = EE σ c 0 + (3 - eCross 0 (σ 1) (c 0)) - 3 := by
          show EE σ c 0 + (3 - ce σ c 0) - 3 = _
          have : ce σ c 0 = eCross 0 (σ 1) (c 0) := by
            unfold ce; rw [if_neg hint]; simp [sg]
          rw [this]
        rw [e1, e2]; exact T
      · have sj : sg σ j = σ j := by simp [sg, hj0]
        have sj1 : sg σ (j+1) = σ (j+1) := by simp [sg]
        have hne : σ j ≠ σ (j+1) := by rw [← sj, ← sj1]; exact hint
        have T := twdiv_cross (KA σ) hN j (j+1) (hmem j (by omega) (by omega))
          (hmem (j+1) (by omega) (by omega)) (by omega) (gam (σ j) (σ (j+1)) (c j))
          (3 - eCross (σ j) (σ (j+1)) (c j))
          (gam_dvd (σ j) (σ (j+1)) (c j) (hσ j) (hσ (j+1)) hne (hc j (by omega)))
          (GG σ c j) (EE σ c j) H
        have e1 : GG σ c (j+1) =
            fun t => GG σ c j t * gam (σ j) (σ (j+1)) (c j) (cx (t j) (t (j+1))) := by
          funext t; show GG σ c j t * Gam σ c j t = _
          have : Gam σ c j t = gam (σ j) (σ (j+1)) (c j) (cx (t j) (t (j+1))) := by
            unfold Gam; rw [if_neg hint, if_neg hj0]
          rw [this]
        have e2 : EE σ c (j+1) = EE σ c j + (3 - eCross (σ j) (σ (j+1)) (c j)) - 3 := by
          show EE σ c j + (3 - ce σ c j) - 3 = _
          have : ce σ c j = eCross (σ j) (σ (j+1)) (c j) := by
            unfold ce; rw [if_neg hint, sj, sj1]
          rw [this]
        rw [e1, e2]; exact T

/- ---------- B.1 W is the product ---------- -/

theorem clsAt_def (σ : Nat → Nat) (t : Asg) (k : Nat) :
    clsAt σ t k = ham (partner (entry σ t k)) (entry σ t (k+1)) := rfl

theorem Gam_eq (σ c : Nat → Nat) (hσ : ∀ k, σ k < 8) (k : Nat) (t : Asg) :
    Gam σ c k t = if gamB σ c k t then 1 else 0 := by
  unfold Gam gamB
  by_cases hint : sg σ k = sg σ (k+1)
  · simp [hint]
  · rw [if_neg hint]
    by_cases hk : k = 0
    · subst hk
      rw [if_pos rfl, clsAt_def, entry_zero, entry_pos σ t (0+1) (by omega), partner_63]
      simp [anc, hint]
    · rw [if_neg hk, clsAt_def, entry_pos σ t k hk, entry_pos σ t (k+1) (by omega),
        class_formula (σ k) (hσ k) (σ (k+1)) (hσ (k+1)) (t k % 8) (Nat.mod_lt _ (by omega))
          (t (k+1) % 8) (Nat.mod_lt _ (by omega))]
      simp [gam, cx, hint]

theorem GG_ind (σ c : Nat → Nat) (hσ : ∀ k, σ k < 8) (j : Nat) (t : Asg) :
    GG σ c j t = if ((List.range 8).all (fun s => phiB σ c s t) &&
      (List.range j).all (fun k => gamB σ c k t)) then 1 else 0 := by
  induction j with
  | zero =>
    show prodF (Phi σ c) 8 t = _
    have := prodF_ind (phiB σ c) 8 t
    simp only [List.range_zero, List.all_nil, Bool.and_true]
    exact this
  | succ j ih =>
    show GG σ c j t * Gam σ c j t = _
    have hr : (List.range (j+1)).all (fun k => gamB σ c k t) =
        ((List.range j).all (fun k => gamB σ c k t) && gamB σ c j t) := by
      rw [List.range_succ, List.all_append]
      simp only [List.all_cons, List.all_nil, Bool.and_true]
    rw [ih, Gam_eq σ c hσ, ind_mul, hr, Bool.and_assoc]

theorem gap_fwd (σ c : Nat → Nat) (t : Asg) (s a b : Nat) (ha : 1 ≤ a) (hb : b ≤ 31)
    (hσa : σ a = s) (hσb : σ b = s) (hC : ∀ k, k < 31 → clsAt σ t k = c k) :
    gapOk (gp c a b) (hexof s (t a % 8)) (hexof s (t b % 8)) = true := by
  unfold gp gapOk
  by_cases hadj : b = a + 1
  · subst hadj
    have h := hC a (by omega)
    rw [clsAt_def, entry_pos σ t a (by omega), entry_pos σ t (a+1) (by omega), hσa, hσb] at h
    simp [h]
  · simp [hadj]

theorem gap_bwd (σ c : Nat → Nat) (t : Asg) (s a b : Nat) (ha : 1 ≤ a)
    (hσa : σ a = s) (hσb : σ b = s) (hc0 : c a ≠ 0)
    (hg : gapOk (gp c a b) (hexof s (t a % 8)) (hexof s (t b % 8)) = true) :
    b = a + 1 → clsAt σ t a = c a := by
  intro hadj
  subst hadj
  rw [clsAt_def, entry_pos σ t a (by omega), entry_pos σ t (a+1) (by omega), hσa, hσb]
  simpa [gp, gapOk, hc0] using hg

/-- (=>) for a reversible support. -/
theorem fwd_R (σ c : Nat → Nat) (t : Asg) (s a b c' d : Nat) (q : Q4 σ s a b c' d)
    (D : ∀ i j, i < j → j < 32 → samePair (entry σ t i) (entry σ t j) = false)
    (hC : ∀ k, k < 31 → clsAt σ t k = c k) :
    indR s (gp c a b) (gp c b c') (gp c c' d) (t a % 8) (t b % 8) (t c' % 8) (t d % 8) = true := by
  obtain ⟨hab, hbc, hcd, hm⟩ := q
  have ma := (hm a).mpr (Or.inl rfl)
  have mb := (hm b).mpr (Or.inr (Or.inl rfl))
  have mc := (hm c').mpr (Or.inr (Or.inr (Or.inl rfl)))
  have md := (hm d).mpr (Or.inr (Or.inr (Or.inr rfl)))
  have sp : ∀ i j, 1 ≤ i → i < j → j ≤ 31 → σ i = s → σ j = s →
      samePair (hexof s (t i % 8)) (hexof s (t j % 8)) = false := by
    intro i j hi hij hj hσi hσj
    have := D i j hij (by omega)
    rwa [entry_pos σ t i (by omega), entry_pos σ t j (by omega), hσi, hσj] at this
  rw [indR_iff]
  exact ⟨sp a b ma.1 hab mb.2.1 ma.2.2 mb.2.2, gap_fwd σ c t s a b ma.1 mb.2.1 ma.2.2 mb.2.2 hC,
    sp b c' mb.1 hbc mc.2.1 mb.2.2 mc.2.2, gap_fwd σ c t s b c' mb.1 mc.2.1 mb.2.2 mc.2.2 hC,
    sp a c' ma.1 (by omega) mc.2.1 ma.2.2 mc.2.2,
    sp c' d mc.1 hcd md.2.1 mc.2.2 md.2.2, gap_fwd σ c t s c' d mc.1 md.2.1 mc.2.2 md.2.2 hC,
    sp a d ma.1 (by omega) md.2.1 ma.2.2 md.2.2, sp b d mb.1 (by omega) md.2.1 mb.2.2 md.2.2⟩

/-- (=>) for the complement pairs. -/
theorem fwd_C (σ c : Nat → Nat) (t : Asg) (a b c' : Nat) (q : Q3 σ a b c')
    (D : ∀ i j, i < j → j < 32 → samePair (entry σ t i) (entry σ t j) = false)
    (hC : ∀ k, k < 31 → clsAt σ t k = c k) :
    indC (gp c 0 a) (gp c a b) (gp c b c') (t a % 8) (t b % 8) (t c' % 8) = true := by
  obtain ⟨hab, hbc, hm⟩ := q
  have ma := (hm a).mpr (Or.inl rfl)
  have mb := (hm b).mpr (Or.inr (Or.inl rfl))
  have mc := (hm c').mpr (Or.inr (Or.inr rfl))
  have m8 : ∀ k, t k % 8 < 8 := fun k => Nat.mod_lt _ (by omega)
  have sp : ∀ i j, 1 ≤ i → i < j → j ≤ 31 → σ i = 0 → σ j = 0 →
      samePair (hexof 0 (t i % 8)) (hexof 0 (t j % 8)) = false := by
    intro i j hi hij hj hσi hσj
    have := D i j hij (by omega)
    rwa [entry_pos σ t i (by omega), entry_pos σ t j (by omega), hσi, hσj] at this
  have sa : ∀ j, 1 ≤ j → j ≤ 31 → σ j = 0 → samePair (hexof 0 (t j % 8)) 63 = false := by
    intro j hj1 hj hσj
    have := D 0 j (by omega) (by omega)
    rwa [entry_zero, entry_pos σ t j (by omega), hσj, sp63 _ (m8 j)] at this
  have an : (gp c 0 a == 0 || ham 0 (hexof 0 (t a % 8)) == gp c 0 a) = true := by
    unfold gp
    by_cases h1 : a = 0 + 1
    · subst h1
      have h := hC 0 (by omega)
      rw [clsAt_def, entry_zero, entry_pos σ t (0+1) (by omega), partner_63, ma.2.2] at h
      simp [h]
    · simp [h1]
  rw [indC_iff]
  exact ⟨sa a ma.1 ma.2.1 ma.2.2, an, sa b mb.1 mb.2.1 mb.2.2,
    sp a b ma.1 hab mb.2.1 ma.2.2 mb.2.2, gap_fwd σ c t 0 a b ma.1 mb.2.1 ma.2.2 mb.2.2 hC,
    sa c' mc.1 mc.2.1 mc.2.2, sp b c' mb.1 hbc mc.2.1 mb.2.2 mc.2.2,
    gap_fwd σ c t 0 b c' mb.1 mc.2.1 mb.2.2 mc.2.2 hC, sp a c' ma.1 (by omega) mc.2.1 ma.2.2 mc.2.2⟩

/-- the hypotheses of case B, packaged. -/
structure Good (σ : Nat → Nat) : Prop where
  lt8 : ∀ k, σ k < 8
  qR : ∀ s, 1 ≤ s → s < 8 → Q4 σ s (kk σ s 0) (kk σ s 1) (kk σ s 2) (kk σ s 3)
  qC : Q3 σ (kk σ 0 0) (kk σ 0 1) (kk σ 0 2)

/-- (<=) distinctness. -/
theorem bwd_D (σ c : Nat → Nat) (t : Asg) (G : Good σ) (hphi : ∀ s, s < 8 → phiB σ c s t = true) :
    ∀ i j, i < j → j < 32 → samePair (entry σ t i) (entry σ t j) = false := by
  intro i j hij hj
  have m8 : ∀ k, t k % 8 < 8 := fun k => Nat.mod_lt _ (by omega)
  have hj0 : j ≠ 0 := by omega
  by_cases hs : sg σ i = sg σ j
  · have sj : sg σ j = σ j := by simp [sg, hj0]
    by_cases h0 : σ j = 0
    · -- support 0
      have ph := hphi 0 (by omega)
      simp only [phiB, if_true] at ph
      obtain ⟨a0, _, b0, ab, _, c0, bc, _, ac⟩ := (indC_iff ..).mp ph
      obtain ⟨hab, hbc, hm⟩ := G.qC
      have mj := (hm j).mp ⟨by omega, by omega, h0⟩
      rw [entry_pos σ t j hj0, h0]
      by_cases hi0 : i = 0
      · subst hi0
        rw [entry_zero, sp63 _ (m8 j)]
        rcases mj with e | e | e <;> subst e <;> assumption
      · have si : σ i = 0 := by rw [sj, h0] at hs; simpa [sg, hi0] using hs
        have mi := (hm i).mp ⟨by omega, by omega, si⟩
        rw [entry_pos σ t i hi0, si]
        exact q3_pair (fun x y => samePair (hexof 0 (t x % 8)) (hexof 0 (t y % 8)) = false)
          _ _ _ i j hab hbc mi mj hij ab ac bc
    · -- a reversible support
      have hi0 : i ≠ 0 := by
        intro e; subst e; rw [sj] at hs; simp [sg] at hs; omega
      have si : σ i = σ j := by rw [sj] at hs; simpa [sg, hi0] using hs
      have ph := hphi (σ j) (G.lt8 j)
      simp only [phiB, if_neg h0] at ph
      obtain ⟨p12, _, p23, _, p13, p34, _, p14, p24⟩ := (indR_iff ..).mp ph
      obtain ⟨hab, hbc, hcd, hm⟩ := G.qR (σ j) (by omega) (G.lt8 j)
      have mj := (hm j).mp ⟨by omega, by omega, rfl⟩
      have mi := (hm i).mp ⟨by omega, by omega, si⟩
      rw [entry_pos σ t j hj0, entry_pos σ t i hi0, si]
      exact q4_pair (fun x y => samePair (hexof (σ j) (t x % 8)) (hexof (σ j) (t y % 8)) = false)
        _ _ _ _ i j hab hbc hcd mi mj hij p12 p13 p14 p23 p24 p34
  · rw [entry_gen σ t i, entry_gen σ t j]
    have b8 : ∀ k, sg σ k < 8 := by
      intro k; unfold sg; split
      · omega
      · exact G.lt8 k
    have v8 : ∀ k, (if k = 0 then 7 else t k % 8) < 8 := by
      intro k; split
      · omega
      · exact m8 k
    exact sp_diff _ (b8 i) _ (b8 j) _ (v8 i) _ (v8 j) hs

/-- (<=) internal boundaries have their prescribed class. -/
theorem bwd_cls (σ c : Nat → Nat) (t : Asg) (G : Good σ) (hc0 : ∀ k, k < 31 → c k ≠ 0)
    (hphi : ∀ s, s < 8 → phiB σ c s t = true) :
    ∀ k, k < 31 → sg σ k = sg σ (k+1) → clsAt σ t k = c k := by
  intro k hk hint
  have sk1 : sg σ (k+1) = σ (k+1) := by simp [sg]
  by_cases h0 : σ (k+1) = 0
  · have ph := hphi 0 (by omega)
    simp only [phiB, if_true] at ph
    obtain ⟨_, an, _, _, g1, _, _, g2, _⟩ := (indC_iff ..).mp ph
    obtain ⟨hab, hbc, hm⟩ := G.qC
    have mk1 := (hm (k+1)).mp ⟨by omega, by omega, h0⟩
    by_cases hk0 : k = 0
    · subst hk0
      have ea : kk σ 0 0 = 0 + 1 := by
        have ma := (hm (kk σ 0 0)).mpr (Or.inl rfl)
        omega
      rw [ea] at an
      rw [clsAt_def, entry_zero, entry_pos σ t (0+1) (by omega), partner_63, h0]
      have := hc0 0 (by omega)
      simpa [gp, this] using an
    · have sk : σ k = 0 := by rw [sk1, h0] at hint; simpa [sg, hk0] using hint
      have mk := (hm k).mp ⟨by omega, by omega, sk⟩
      exact q3_pair (fun x y => y = x + 1 → clsAt σ t x = c x) _ _ _ k (k+1) hab hbc mk mk1
        (by omega)
        (gap_bwd σ c t 0 _ _ ((hm _).mpr (Or.inl rfl)).1 ((hm _).mpr (Or.inl rfl)).2.2
          ((hm _).mpr (Or.inr (Or.inl rfl))).2.2
          (hc0 _ (by have := ((hm (kk σ 0 1)).mpr (Or.inr (Or.inl rfl))).2.1; omega)) g1)
        (fun e => by omega)
        (gap_bwd σ c t 0 _ _ ((hm _).mpr (Or.inr (Or.inl rfl))).1
          ((hm _).mpr (Or.inr (Or.inl rfl))).2.2 ((hm _).mpr (Or.inr (Or.inr rfl))).2.2
          (hc0 _ (by have := ((hm (kk σ 0 2)).mpr (Or.inr (Or.inr rfl))).2.1; omega)) g2)
        rfl
  · have hk0 : k ≠ 0 := by
      intro e; apply h0; rw [← sk1, ← hint, e]; simp [sg]
    have sk : σ k = σ (k+1) := by rw [sk1] at hint; simpa [sg, hk0] using hint
    have ph := hphi (σ (k+1)) (G.lt8 _)
    simp only [phiB, if_neg h0] at ph
    obtain ⟨_, g1, _, g2, _, _, g3, _, _⟩ := (indR_iff ..).mp ph
    obtain ⟨hab, hbc, hcd, hm⟩ := G.qR (σ (k+1)) (by omega) (G.lt8 _)
    have mk1 := (hm (k+1)).mp ⟨by omega, by omega, rfl⟩
    have mk := (hm k).mp ⟨by omega, by omega, sk⟩
    have ma := (hm (kk σ (σ (k+1)) 0)).mpr (Or.inl rfl)
    have mb := (hm (kk σ (σ (k+1)) 1)).mpr (Or.inr (Or.inl rfl))
    have mc := (hm (kk σ (σ (k+1)) 2)).mpr (Or.inr (Or.inr (Or.inl rfl)))
    have md := (hm (kk σ (σ (k+1)) 3)).mpr (Or.inr (Or.inr (Or.inr rfl)))
    exact q4_pair (fun x y => y = x + 1 → clsAt σ t x = c x) _ _ _ _ k (k+1) hab hbc hcd mk mk1
      (by omega)
      (gap_bwd σ c t _ _ _ ma.1 ma.2.2 mb.2.2 (hc0 _ (by omega)) g1)
      (fun e => by omega) (fun e => by omega)
      (gap_bwd σ c t _ _ _ mb.1 mb.2.2 mc.2.2 (hc0 _ (by omega)) g2)
      (fun e => by omega)
      (gap_bwd σ c t _ _ _ mc.1 mc.2.2 md.2.2 (hc0 _ (by omega)) g3)
      rfl

theorem W_iff (σ c : Nat → Nat) (G : Good σ) (hc0 : ∀ k, k < 31 → c k ≠ 0) (t : Asg) :
    ((∀ i j, i < j → j < 32 → samePair (entry σ t i) (entry σ t j) = false) ∧
        ∀ x, x < 31 → clsAt σ t x = c x) ↔
      ((∀ x, x < 8 → phiB σ c x t = true) ∧ ∀ x, x < 31 → gamB σ c x t = true) := by
  constructor
  · rintro ⟨D, hC⟩
    refine ⟨fun s hs => ?_, fun k hk => ?_⟩
    · by_cases h0 : s = 0
      · subst h0
        simp only [phiB, if_true]
        exact fwd_C σ c t _ _ _ G.qC D hC
      · simp only [phiB, if_neg h0]
        exact fwd_R σ c t s _ _ _ _ (G.qR s (by omega) hs) D hC
    · simp [gamB, hC k hk]
  · rintro ⟨hphi, hg⟩
    refine ⟨bwd_D σ c t G hphi, fun k hk => ?_⟩
    by_cases hint : sg σ k = sg σ (k+1)
    · exact bwd_cls σ c t G hc0 hphi k hk hint
    · have := hg k hk
      simpa [gamB, hint] using this


/-- STEP 1 inside the coordinate model: W is the product of the Phi's and the boundary factors. -/
theorem W_eq (σ c : Nat → Nat) (G : Good σ) (hc0 : ∀ k, k < 31 → c k ≠ 0) (t : Asg) :
    W σ c t = GG σ c 31 t := by
  rw [GG_ind σ c G.lt8]
  unfold W
  have hb : (distinctOK σ t && (List.range 31).all fun k => clsAt σ t k == c k) =
      ((List.range 8).all (fun s => phiB σ c s t) &&
        (List.range 31).all (fun k => gamB σ c k t)) := by
    rw [Bool.eq_iff_iff]
    simp only [Bool.and_eq_true, List.all_eq_true, List.mem_range, beq_iff_eq]
    rw [distinct_iff]
    exact W_iff σ c G hc0 t
  rw [hb]

/- ---------- B.4 Step 5: the arithmetic ---------- -/

theorem EE_bound (σ c : Nat → Nat) (j : Nat) : EE σ c 0 ≤ EE σ c j + sumN (ce σ c) j := by
  induction j with
  | zero => exact Nat.le_refl _
  | succ j ih =>
    show EE σ c 0 ≤ (EE σ c j + (3 - ce σ c j) - 3) + (sumN (ce σ c) j + ce σ c j)
    omega

/-- indicator: boundary k is internal to support s. -/
def inb (σ : Nat → Nat) (s k : Nat) : Nat := if sg σ k = s ∧ sg σ (k+1) = s then 1 else 0
/-- indicator: boundary k is internal. -/
def intl (σ : Nat → Nat) (k : Nat) : Nat := if sg σ k = sg σ (k+1) then 1 else 0

theorem inb_sum (σ : Nat → Nat) (k : Nat) :
    inb σ 0 k + inb σ 1 k + inb σ 2 k + inb σ 3 k + inb σ 4 k + inb σ 5 k + inb σ 6 k + inb σ 7 k
      ≤ intl σ k := by
  unfold inb intl
  generalize sg σ k = x
  generalize sg σ (k+1) = y
  by_cases h : x = y
  · subst h
    simp only [and_self, if_true]
    have h8 : x = 0 ∨ x = 1 ∨ x = 2 ∨ x = 3 ∨ x = 4 ∨ x = 5 ∨ x = 6 ∨ x = 7 ∨ 8 ≤ x := by omega
    rcases h8 with e | e | e | e | e | e | e | e | e
    · subst e; simp
    · subst e; simp
    · subst e; simp
    · subst e; simp
    · subst e; simp
    · subst e; simp
    · subst e; simp
    · subst e; simp
    · have n0 : x ≠ 0 := by omega
      have n1 : x ≠ 1 := by omega
      have n2 : x ≠ 2 := by omega
      have n3 : x ≠ 3 := by omega
      have n4 : x ≠ 4 := by omega
      have n5 : x ≠ 5 := by omega
      have n6 : x ≠ 6 := by omega
      have n7 : x ≠ 7 := by omega
      simp [n0, n1, n2, n3, n4, n5, n6, n7]
  · have f : ∀ s, (if x = s ∧ y = s then 1 else 0) = 0 := by
      intro s; rw [if_neg]; intro ⟨e1, e2⟩; exact h (e1.trans e2.symm)
    simp [f]

theorem inb_total (σ : Nat → Nat) (n : Nat) :
    sumN (inb σ 0) n + sumN (inb σ 1) n + sumN (inb σ 2) n + sumN (inb σ 3) n + sumN (inb σ 4) n +
      sumN (inb σ 5) n + sumN (inb σ 6) n + sumN (inb σ 7) n ≤ sumN (intl σ) n := by
  induction n with
  | zero => exact Nat.le_refl _
  | succ n ih =>
    have := inb_sum σ n
    show (sumN (inb σ 0) n + inb σ 0 n) + (sumN (inb σ 1) n + inb σ 1 n) +
      (sumN (inb σ 2) n + inb σ 2 n) + (sumN (inb σ 3) n + inb σ 3 n) +
      (sumN (inb σ 4) n + inb σ 4 n) + (sumN (inb σ 5) n + inb σ 5 n) +
      (sumN (inb σ 6) n + inb σ 6 n) + (sumN (inb σ 7) n + inb σ 7 n) ≤ sumN (intl σ) n + intl σ n
    omega

theorem cost_le_one (g : Nat) : cost g ≤ 1 := by unfold cost; split <;> omega

theorem cost_gp_le (σ c : Nat → Nat) (s a b : Nat) (hσa : sg σ a = s) (hσb : σ b = s) :
    cost (gp c a b) ≤ inb σ s a := by
  unfold gp
  by_cases h : b = a + 1
  · subst h
    have h1 : sg σ (a+1) = s := by simp [sg, hσb]
    have : inb σ s a = 1 := by simp [inb, hσa, h1]
    rw [this]; exact cost_le_one _
  · simp [h, cost]

theorem mu_R (σ c : Nat → Nat) (s : Nat) (hs0 : s ≠ 0)
    (q : Q4 σ s (kk σ s 0) (kk σ s 1) (kk σ s 2) (kk σ s 3)) :
    7 ≤ mu σ c s + sumN (inb σ s) 31 := by
  obtain ⟨hab, hbc, hcd, hm⟩ := q
  have ma := (hm (kk σ s 0)).mpr (Or.inl rfl)
  have mb := (hm (kk σ s 1)).mpr (Or.inr (Or.inl rfl))
  have mc := (hm (kk σ s 2)).mpr (Or.inr (Or.inr (Or.inl rfl)))
  have md := (hm (kk σ s 3)).mpr (Or.inr (Or.inr (Or.inr rfl)))
  have sgp : ∀ k, 1 ≤ k → σ k = s → sg σ k = s := by
    intro k hk e; unfold sg; rw [if_neg (by omega)]; exact e
  have c1 := cost_gp_le σ c s _ _ (sgp _ ma.1 ma.2.2) mb.2.2
  have c2 := cost_gp_le σ c s _ _ (sgp _ mb.1 mb.2.2) mc.2.2
  have c3 := cost_gp_le σ c s _ _ (sgp _ mc.1 mc.2.2) md.2.2
  have h3 := sumN_three (inb σ s) _ _ _ 31 hab hbc (by omega)
  have e : mu σ c s = 7 - cost (gp c (kk σ s 0) (kk σ s 1)) - cost (gp c (kk σ s 1) (kk σ s 2)) -
      cost (gp c (kk σ s 2) (kk σ s 3)) := by simp [mu, hs0]
  omega

theorem mu_C (σ c : Nat → Nat) (q : Q3 σ (kk σ 0 0) (kk σ 0 1) (kk σ 0 2)) :
    4 ≤ mu σ c 0 + sumN (inb σ 0) 31 := by
  obtain ⟨hab, hbc, hm⟩ := q
  have ma := (hm (kk σ 0 0)).mpr (Or.inl rfl)
  have mb := (hm (kk σ 0 1)).mpr (Or.inr (Or.inl rfl))
  have mc := (hm (kk σ 0 2)).mpr (Or.inr (Or.inr rfl))
  have sgp : ∀ k, 1 ≤ k → σ k = 0 → sg σ k = 0 := by
    intro k hk e; unfold sg; rw [if_neg (by omega)]; exact e
  have c0 := cost_gp_le σ c 0 0 _ (by simp [sg]) ma.2.2
  have c1 := cost_gp_le σ c 0 _ _ (sgp _ ma.1 ma.2.2) mb.2.2
  have c2 := cost_gp_le σ c 0 _ _ (sgp _ mb.1 mb.2.2) mc.2.2
  have h3 := sumN_three (inb σ 0) 0 _ _ 31 (by omega) hab (by omega)
  have e : mu σ c 0 = 4 - cost (gp c 0 (kk σ 0 0)) - cost (gp c (kk σ 0 0) (kk σ 0 1)) -
      cost (gp c (kk σ 0 1) (kk σ 0 2)) := by simp [mu]
  omega

theorem bcost_le (σ c : Nat → Nat) (k : Nat) : intl σ k + ce σ c k ≤ wcls (c k) := by
  unfold intl ce
  by_cases h : sg σ k = sg σ (k+1)
  · simp only [h, if_true]; unfold wcls; split <;> omega
  · simp only [h, if_false]
    have := eCross_le (sg σ k) (sg σ (k+1)) (c k)
    unfold wcls; omega

/-- STEP 5: the final exponent is at least 53 - (31 + b1) = 22 - b1  (20 for King Wen's budget). -/
theorem EE_ge (σ c : Nat → Nat) (G : Good σ) (b1 : Nat)
    (hw : sumN (fun k => wcls (c k)) 31 = 31 + b1) : 22 - b1 ≤ EE σ c 31 := by
  have h1 := EE_bound σ c 31
  have e0 : EE σ c 0 = mu σ c 0 + mu σ c 1 + mu σ c 2 + mu σ c 3 + mu σ c 4 + mu σ c 5 +
      mu σ c 6 + mu σ c 7 := by
    show sumN (mu σ c) 8 = _
    simp only [sumN]; omega
  have m0 := mu_C σ c G.qC
  have m1 := mu_R σ c 1 (by omega) (G.qR 1 (by omega) (by omega))
  have m2 := mu_R σ c 2 (by omega) (G.qR 2 (by omega) (by omega))
  have m3 := mu_R σ c 3 (by omega) (G.qR 3 (by omega) (by omega))
  have m4 := mu_R σ c 4 (by omega) (G.qR 4 (by omega) (by omega))
  have m5 := mu_R σ c 5 (by omega) (G.qR 5 (by omega) (by omega))
  have m6 := mu_R σ c 6 (by omega) (G.qR 6 (by omega) (by omega))
  have m7 := mu_R σ c 7 (by omega) (G.qR 7 (by omega) (by omega))
  have h2 := inb_total σ 31
  have h3 : sumN (intl σ) 31 + sumN (ce σ c) 31 ≤ sumN (fun k => wcls (c k)) 31 := by
    rw [← sumN_add]; exact sumN_le _ _ 31 fun k _ => bcost_le σ c k
  omega

/- ---------- the theorem ---------- -/

theorem fibre_main (σ c : Nat → Nat) (hσ : ∀ k, σ k < 8) (hc : ∀ k, k < 31 → c k ∈ [1, 2, 3, 4, 6])
    (b1 : Nat) (hw : sumN (fun k => wcls (c k)) 31 = 31 + b1) (hperm : (KA σ).Perm slots)
    (l0 : (Ks σ 0).length = 3) (l4 : ∀ s, 1 ≤ s → s < 8 → (Ks σ s).length = 4) :
    ((2 ^ (22 - b1) : Nat) : Int) ∣ fibreC σ c := by
  have G : Good σ := ⟨hσ, fun s h1 h8 => Q4_of_len σ s (l4 s h1 h8), Q3_of_len σ l0⟩
  have hc0 : ∀ k, k < 31 → c k ≠ 0 := by
    intro k hk e
    have := hc k hk
    rw [e] at this
    simp at this
  have hN : (KA σ).Nodup := hperm.nodup_iff.mpr List.nodup_range'
  have hmem : ∀ k, 1 ≤ k → k ≤ 31 → k ∈ KA σ := fun k h1 h2 =>
    hperm.mem_iff.mpr ((mem_slots k).mpr ⟨h1, h2⟩)
  have H0 : TwDiv (KA σ) (GG σ c 0) (EE σ c 0) :=
    twdiv_blocks (Ks σ) (Phi σ c) (mu σ c) 8
      (fun s hs => by
        by_cases e : s = 0
        · subst e; exact phi_twdiv_C σ c l0
        · exact phi_twdiv_R σ c s (by omega) hs (l4 s (by omega) hs))
      (fun s hs k hk => by
        by_cases e : s = 0
        · subst e; exact phi_indep σ c 0 k (Or.inl ⟨rfl, l0⟩) hk
        · exact phi_indep σ c s k (Or.inr ⟨e, l4 s (by omega) hs⟩) hk)
      (fun s _ s' _ k hk hk' => by
        have a := ((mem_Ks σ s k).mp hk).2.2
        have b := ((mem_Ks σ s' k).mp hk').2.2
        omega)
  have H := fold_twdiv σ c hσ hc hN hmem H0 31 (Nat.le_refl _)
  have hd := twdiv_count _ _ _ (twdiv_mono _ _ (22 - b1) _ (EE_ge σ c G b1 hw) H) (fun _ => 0)
  rw [sumOver_perm hperm] at hd
  have e : fibreC σ c = sumOver slots (GG σ c 31) (fun _ => 0) :=
    sumOver_congr _ (fun t => W_eq σ c G hc0 t) _
  rw [e]; exact hd

/-- number of class-1 boundaries. -/
def b1of (c : Nat → Nat) : Nat := (((List.range 31).map c).filter (· == 1)).length

/-- **General-budget form (Step 5, "22 - b1").** For every skeleton and every class sequence
    over the classes 1,2,3,4,6, 2^(22 - b1) divides the coordinate-model fibre, b1 = the number of
    class-1 boundaries. -/
theorem fibreC_dvd_general (σ c : Nat → Nat) (hσ : ∀ k, σ k < 8)
    (hc : ∀ k, k < 31 → c k ∈ [1, 2, 3, 4, 6]) :
    ((2 ^ (22 - b1of c) : Nat) : Int) ∣ fibreC σ c := by
  have hw : sumN (fun k => wcls (c k)) 31 = 31 + b1of c := sumN_w c 31
  have hperm : (KA σ).Perm slots := catK_perm σ slots 8 (fun k _ => hσ k)
  have hlen : sumN (fun s => (Ks σ s).length) 8 = 31 := by
    have := hperm.length_eq
    rw [KA, catK_length] at this
    rw [this]; rfl
  simp only [sumN] at hlen
  have Z : (∀ t, W σ c t = 0) → ((2 ^ (22 - b1of c) : Nat) : Int) ∣ fibreC σ c := fun h =>
    sumOver_dvd _ _ _ (fun t => by rw [h t]; exact Int.dvd_zero _) _
  by_cases h0 : 4 ≤ (Ks σ 0).length
  · exact Z (over_C σ c h0)
  by_cases h1 : 5 ≤ (Ks σ 1).length
  · exact Z (over_R σ c 1 (by omega) h1)
  by_cases h2 : 5 ≤ (Ks σ 2).length
  · exact Z (over_R σ c 2 (by omega) h2)
  by_cases h3 : 5 ≤ (Ks σ 3).length
  · exact Z (over_R σ c 3 (by omega) h3)
  by_cases h4 : 5 ≤ (Ks σ 4).length
  · exact Z (over_R σ c 4 (by omega) h4)
  by_cases h5 : 5 ≤ (Ks σ 5).length
  · exact Z (over_R σ c 5 (by omega) h5)
  by_cases h6 : 5 ≤ (Ks σ 6).length
  · exact Z (over_R σ c 6 (by omega) h6)
  by_cases h7 : 5 ≤ (Ks σ 7).length
  · exact Z (over_R σ c 7 (by omega) h7)
  refine fibre_main σ c hσ hc (b1of c) hw hperm (by omega) fun s hs1 hs8 => ?_
  have h8 : s = 1 ∨ s = 2 ∨ s = 3 ∨ s = 4 ∨ s = 5 ∨ s = 6 ∨ s = 7 := by omega
  rcases h8 with e | e | e | e | e | e | e <;> subst e <;> omega

/-- **Steps 2-5, coordinate model.** For every skeleton and every class sequence with
    King Wen's boundary budget {1:2, 2:8, 3:13, 4:7, 6:1}, 2^20 divides the fibre.
    (`FibreCDvd` is the target stated in §14, unchanged.) -/
theorem fibreC_dvd : FibreCDvd := by
  intro σ c hσ hb
  have h := fibreC_dvd_general σ c hσ (budget_cls c hb)
  have e : b1of c = 2 := by
    simp only [budgetOK, Bool.and_eq_true, beq_iff_eq] at hb
    exact hb.1.1.1.1
  rw [e] at h
  exact h

/-- the same theorem with the target unfolded, for a reader who does not want to chase `def`s. -/
theorem fibreC_dvd_explicit (σ c : Nat → Nat) (hσ : ∀ k, σ k < 8)
    (hb : budgetOK c = true) :
    ((2 ^ 20 : Nat) : Int) ∣ sumOver (List.range' 1 31) (W σ c) (fun _ => 0) :=
  fibreC_dvd σ c hσ hb

/-! ## §20  controls for the coordinate-model fibre theorem -/

/-
  §20 — controls for the coordinate-model fibre theorem (all kernel-checked).

    * `kw_fibre_pos`   — the theorem is not vacuous: King Wen's own coordinate-model fibre is
                         positive (so, by the theorem, at least 2^20);
    * `kw_fibre_dvd`   — the theorem applied to King Wen's skeleton and class sequence;
    * `kw_b1`          — King Wen's sequence has two class-1 boundaries (general form gives 2^20);
    * `gam_mut5` (§17) — a class-5 cross boundary would break the Step-2 exponent, so the
                         hypothesis "classes in 1,2,3,4,6" is doing work.
-/

theorem sum8_nonneg (g : Nat → Int) (h : ∀ v, 0 ≤ g v) : 0 ≤ sum8 g := by
  have := h 0; have := h 1; have := h 2; have := h 3; have := h 4; have := h 5; have := h 6
  have := h 7
  simp only [sum8]; omega

theorem sum8_ge (g : Nat → Int) (h : ∀ v, 0 ≤ g v) (v0 : Nat) (hv : v0 < 8) : g v0 ≤ sum8 g := by
  have := h 0; have := h 1; have := h 2; have := h 3; have := h 4; have := h 5; have := h 6
  have := h 7
  have h8 : v0 = 0 ∨ v0 = 1 ∨ v0 = 2 ∨ v0 = 3 ∨ v0 = 4 ∨ v0 = 5 ∨ v0 = 6 ∨ v0 = 7 := by omega
  simp only [sum8]
  rcases h8 with e | e | e | e | e | e | e | e <;> subst e <;> omega

theorem sumOver_nonneg (K : List Nat) (F : Asg → Int) (h : ∀ t, 0 ≤ F t) (t : Asg) :
    0 ≤ sumOver K F t := by
  induction K generalizing t with
  | nil => exact h t
  | cons k K ih => exact sum8_nonneg _ fun v => ih _

/-- write the values `vals` into the slots K. -/
def updAll : List Nat → (Nat → Nat) → Asg → Asg
  | [], _, t => t
  | k :: K, vals, t => updAll K vals (upd t k (vals k))

/-- a sum of non-negative terms is at least any one of its terms. -/
theorem sumOver_ge (K : List Nat) (F : Asg → Int) (h : ∀ t, 0 ≤ F t) (vals : Nat → Nat)
    (hv : ∀ k, vals k < 8) (t : Asg) : F (updAll K vals t) ≤ sumOver K F t := by
  induction K generalizing t with
  | nil => exact Int.le_refl _
  | cons k K ih =>
    exact Int.le_trans (ih (upd t k (vals k)))
      (sum8_ge (fun v => sumOver K F (upd t k v)) (fun v => sumOver_nonneg K F h _) (vals k) (hv k))

theorem W_nonneg (σ c : Nat → Nat) (t : Asg) : 0 ≤ W σ c t := by
  unfold W; split <;> decide

def kwσ : Nat → Nat := fun k => (skel KW).getD k 0
def kwc : Nat → Nat := fun k => (bseq KW).getD k 0
def kwt : Nat → Nat := fun k => KW.getD (2*k) 0 % 8

theorem kw_point : W kwσ kwc (updAll (List.range' 1 31) kwt (fun _ => 0)) = 1 := by decide +kernel

/-- NON-VACUITY: King Wen's coordinate-model fibre is positive. -/
theorem kw_fibre_pos : 0 < fibreC kwσ kwc := by
  have h := sumOver_ge (List.range' 1 31) (W kwσ kwc) (W_nonneg kwσ kwc) kwt
    (fun k => Nat.mod_lt _ (by omega)) (fun _ => 0)
  rw [kw_point] at h
  exact h

theorem kw_skel_lt : ∀ k, kwσ k < 8 := by
  intro k
  by_cases h : k < 32
  · have : ∀ k, k < 32 → kwσ k < 8 := by decide +kernel
    exact this k h
  · have : kwσ k = 0 := by
      unfold kwσ
      have hl : (skel KW).length = 32 := by decide +kernel
      rw [List.getD_eq_getElem?_getD, List.getElem?_eq_none (by omega)]; rfl
    omega

/-- the theorem on King Wen's own skeleton and class sequence. -/
theorem kw_fibre_dvd : ((2 ^ 20 : Nat) : Int) ∣ fibreC kwσ kwc :=
  fibreC_dvd kwσ kwc kw_skel_lt kw_budget

theorem kw_b1 : b1of kwc = 2 := by decide +kernel

/-- so King Wen's coordinate-model fibre is at least 2^20. -/
theorem kw_fibre_ge : (1048576 : Int) ≤ fibreC kwσ kwc :=
  Int.le_of_dvd kw_fibre_pos kw_fibre_dvd

/- ---- a remark on the model.  The coordinate model never reads sigma 0 (slot 0 is the anchor pair),
   so changing sigma 0 leaves the coordinate fibre unchanged, and positive for King Wen's data.
   A fibre of SEQUENCES with skeleton head != 0 is empty, because `c4ok` forces the first hexagram
   to be 63, whose support is 0.  So "sequence fibre = coordinate fibre" is false without a side
   condition on sigma 0 (and on the budget of c, which `c5ok` imposes on sequences and `W` does
   not).  The proof therefore links the two through `cell_eq` (§23), where C4 pins
   slot 0 and the budget is carried by an indicator. ---- -/
def kwσ' : Nat → Nat := fun k => if k = 0 then 1 else kwσ k
theorem kw_point' : W kwσ' kwc (updAll (List.range' 1 31) kwt (fun _ => 0)) = 1 := by decide +kernel
/-- the coordinate fibre with the skeleton head changed from 0 to 1 is still positive. -/
theorem fibreC_head_free : 0 < fibreC kwσ' kwc := by
  have h := sumOver_ge (List.range' 1 31) (W kwσ' kwc) (W_nonneg kwσ' kwc) kwt
    (fun k => Nat.mod_lt _ (by omega)) (fun _ => 0)
  rw [kw_point'] at h
  exact h
/-- and the list model does force the skeleton head to be 0. -/
theorem supp_63 : supp 63 = 0 := by decide

/-! ## §21  sequences to sums, part 1 -/

/-
  §21 — sequences to sums, part 1: from a count of lists to sums over assignments.

    * `lsum`, `filter_length`  — the length of a filtered list is a sum of 0/1 indicators;
    * `C1sum`      — a sum over `seqs (2m)` of a function that vanishes off C1 is a sum over the
                     m entry hexagrams (the exits are the partners);
    * `Ssum`       — a sum over `seqs m` is a double sum over assignments (sigma, t) of the
                     slots j..j+m-1, hexagram = `hexof sigma t`;
    * `sumOver_delta`, `sumOver_congr_bd`, `sumOver_dvd_bd`, `sumOver_comm2`, `sumOver_updout`
                   — the sum calculus the later parts use;
    * `length_eq_sumN_count`, `filter_eq_sumN_count`, `sumN_all_one_*` — counting by values.
-/

def lsum {α : Type} : List α → (α → Int) → Int
  | [], _ => 0
  | a :: l, f => f a + lsum l f

theorem lsum_congr {α : Type} (l : List α) {f g : α → Int} (h : ∀ a, a ∈ l → f a = g a) :
    lsum l f = lsum l g := by
  induction l with
  | nil => rfl
  | cons a l ih =>
    show f a + lsum l f = g a + lsum l g
    rw [h a List.mem_cons_self, ih fun b hb => h b (List.mem_cons_of_mem _ hb)]

theorem lsum_append {α : Type} (l l' : List α) (f : α → Int) :
    lsum (l ++ l') f = lsum l f + lsum l' f := by
  induction l with
  | nil => show lsum l' f = 0 + lsum l' f; omega
  | cons a l ih => show f a + lsum (l ++ l') f = f a + lsum l f + lsum l' f; rw [ih]; omega

theorem lsum_flatMap {α β : Type} (l : List α) (F : α → List β) (f : β → Int) :
    lsum (l.flatMap F) f = lsum l (fun a => lsum (F a) f) := by
  induction l with
  | nil => rfl
  | cons a l ih => rw [List.flatMap_cons, lsum_append, ih]; rfl

theorem lsum_map {α β : Type} (l : List α) (g : α → β) (f : β → Int) :
    lsum (l.map g) f = lsum l (fun a => f (g a)) := by
  induction l with
  | nil => rfl
  | cons a l ih => show f (g a) + lsum (l.map g) f = f (g a) + lsum l _; rw [ih]

theorem lsum_zero {α : Type} (l : List α) : lsum l (fun _ => 0) = 0 := by
  induction l with
  | nil => rfl
  | cons a l ih => show 0 + lsum l (fun _ => 0) = 0; rw [ih]; rfl

theorem lsum_add {α : Type} (l : List α) (f g : α → Int) :
    lsum l (fun a => f a + g a) = lsum l f + lsum l g := by
  induction l with
  | nil => rfl
  | cons a l ih =>
    show f a + g a + lsum l (fun a => f a + g a) = f a + lsum l f + (g a + lsum l g)
    rw [ih]; omega

theorem lsum_comm {α β : Type} (l : List α) (l' : List β) (f : α → β → Int) :
    lsum l (fun a => lsum l' (f a)) = lsum l' (fun b => lsum l (fun a => f a b)) := by
  induction l with
  | nil => show (0 : Int) = lsum l' (fun _ => 0); rw [lsum_zero]
  | cons a l ih =>
    show lsum l' (f a) + lsum l (fun a => lsum l' (f a)) =
      lsum l' (fun b => f a b + lsum l (fun a => f a b))
    rw [ih, lsum_add]

theorem filter_length {α : Type} (l : List α) (p : α → Bool) :
    ((l.filter p).length : Int) = lsum l (fun a => if p a then 1 else 0) := by
  induction l with
  | nil => rfl
  | cons a l ih =>
    show _ = (if p a then 1 else 0) + lsum l _
    rw [← ih, List.filter_cons]
    cases p a
    · simp
    · simp; omega

theorem lsum_delta (l : List Nat) (hl : l.Nodup) (a : Nat) (ha : a ∈ l) (f : Nat → Int) :
    lsum l (fun y => if y = a then f y else 0) = f a := by
  induction l with
  | nil => cases ha
  | cons b l ih =>
    have hb := (List.nodup_cons.mp hl).1
    have hl' := (List.nodup_cons.mp hl).2
    show (if b = a then f b else 0) + lsum l (fun y => if y = a then f y else 0) = f a
    by_cases e : b = a
    · subst e
      rw [if_pos rfl, lsum_congr l (g := fun _ => 0) (fun y hy => by
        rw [if_neg]; intro e; subst e; exact hb hy), lsum_zero]
      omega
    · have ha' : a ∈ l := by
        rcases List.mem_cons.mp ha with h | h
        · exact absurd h.symm e
        · exact h
      rw [if_neg e, ih hl' ha']; omega

/-- a sum over the 64 hexagrams is a sum over (support, section coordinate). -/
theorem lsum_range64 (q : Nat → Int) :
    lsum (List.range 64) q = sum8 fun s => sum8 fun v => q (hexof s v) := by
  have hr : List.range 64 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
      20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42,
      43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63] := by
    decide
  rw [hr]
  simp only [lsum, sum8, hexof, rev3]
  simp
  omega

/- ---------- sums over `seqs` ---------- -/

theorem S_succ (n : Nat) (Q : List Nat → Int) :
    lsum (seqs (n+1)) Q = lsum (seqs n) (fun l => lsum (List.range 64) (fun x => Q (x :: l))) := by
  show lsum ((seqs n).flatMap fun l => (List.range 64).map (· :: l)) Q = _
  rw [lsum_flatMap]
  exact lsum_congr _ fun l _ => lsum_map _ _ _

theorem mem_seqs_len : ∀ n l, l ∈ seqs n → l.length = n := by
  intro n
  induction n with
  | zero => intro l h; simp [seqs] at h; subst h; rfl
  | succ n ih =>
    intro l h
    simp only [seqs, List.mem_flatMap, List.mem_map] at h
    obtain ⟨l', hl', x, _, e⟩ := h
    subst e
    simp [ih l' hl']

/-- C1 as a recursion on the list. -/
def c1L : List Nat → Bool
  | [] => true
  | [_] => false
  | x :: y :: l => y == partner x && c1L l

/-- entry hexagrams -> the full sequence (each entry followed by its partner). -/
def pairs : List Nat → List Nat
  | [] => []
  | x :: e => x :: partner x :: pairs e

theorem partner_lt : ∀ x < 64, partner x < 64 := by decide

/-- a sum over `seqs (2m)` of a function vanishing off C1 is a sum over the entries. -/
theorem C1sum (m : Nat) : ∀ Q : List Nat → Int,
    (∀ l, l.length = 2 * m → c1L l = false → Q l = 0) →
    lsum (seqs (2 * m)) Q = lsum (seqs m) (fun e => Q (pairs e)) := by
  induction m with
  | zero => intro Q _; rfl
  | succ m ih =>
    intro Q hQ
    have e1 : lsum (seqs (2 * (m+1))) Q = lsum (seqs (2 * m)) (fun l =>
        lsum (List.range 64) (fun y => lsum (List.range 64) (fun x => Q (x :: y :: l)))) := by
      show lsum (seqs (2 * m + 1 + 1)) Q = _
      rw [S_succ, S_succ]
    have key : ∀ l, l ∈ seqs (2 * m) →
        lsum (List.range 64) (fun y => lsum (List.range 64) (fun x => Q (x :: y :: l))) =
        lsum (List.range 64) (fun x => Q (x :: partner x :: l)) := by
      intro l hl
      have hlen := mem_seqs_len _ l hl
      rw [lsum_comm]
      apply lsum_congr
      intro x hx
      have hx64 : x < 64 := List.mem_range.mp hx
      rw [lsum_congr (List.range 64) (g := fun y => if y = partner x then Q (x :: y :: l) else 0)
        (fun y _ => by
          by_cases e : y = partner x
          · rw [if_pos e]
          · rw [if_neg e]
            apply hQ
            · simp [hlen]; omega
            · simp [c1L, e])]
      exact lsum_delta _ List.nodup_range _ (List.mem_range.mpr (partner_lt x hx64)) _
    rw [e1, lsum_congr _ key]
    have := ih (fun l => lsum (List.range 64) (fun x => Q (x :: partner x :: l))) (by
      intro l hl hc
      rw [lsum_congr (List.range 64) (g := fun _ => 0) (fun x _ => by
        apply hQ
        · simp [hl]; omega
        · simp [c1L, hc]), lsum_zero])
    rw [this, S_succ]
    rfl

/-- [a j, a (j+1), ..., a (j+m-1)]. -/
def listFrom (a : Nat → Nat) : Nat → Nat → List Nat
  | _, 0 => []
  | j, m+1 => a j :: listFrom a (j+1) m

theorem listFrom_congr (a b : Nat → Nat) : ∀ m j, (∀ i, j ≤ i → i < j + m → a i = b i) →
    listFrom a j m = listFrom b j m := by
  intro m
  induction m with
  | zero => intro j _; rfl
  | succ m ih =>
    intro j h
    show a j :: listFrom a (j+1) m = b j :: listFrom b (j+1) m
    rw [h j (Nat.le_refl _) (by omega), ih (j+1) fun i h1 h2 => h i (by omega) (by omega)]

/-- a fixed value at a slot outside K can be moved inside the summand. -/
theorem sumOver_updout (K : List Nat) (F : Asg → Int) (j x : Nat) (hj : j ∉ K) (t : Asg) :
    sumOver K F (upd t j x) = sumOver K (fun a => F (upd a j x)) t := by
  induction K generalizing t with
  | nil => rfl
  | cons k K ih =>
    have hjk : j ≠ k := fun e => hj (e ▸ List.mem_cons_self)
    show sum8 (fun v => sumOver K F (upd (upd t j x) k v)) =
      sum8 (fun v => sumOver K (fun a => F (upd a j x)) (upd t k v))
    exact sum8_congr fun v => by
      rw [upd_comm t hjk, ih fun m => hj (List.mem_cons_of_mem _ m)]

/-- a sum over `seqs m` is a double sum over the assignments (sigma, t) of slots j..j+m-1. -/
theorem Ssum (m : Nat) : ∀ (j : Nat) (R : List Nat → Int) (σ0 t0 : Asg),
    lsum (seqs m) R = sumOver (List.range' j m) (fun σ => sumOver (List.range' j m)
      (fun t => R (listFrom (fun i => hexof (σ i) (t i)) j m)) t0) σ0 := by
  induction m with
  | zero => intro j R σ0 t0; show R [] + 0 = R []; omega
  | succ m ih =>
    intro j R σ0 t0
    have hj : j ∉ List.range' (j+1) m := by
      intro h; have := List.mem_range'_1.mp h; omega
    rw [S_succ, lsum_congr _ (fun l _ => lsum_range64 _), ih (j+1) _ σ0 t0]
    show _ = sum8 (fun s => sumOver (List.range' (j+1) m) (fun σ =>
      sum8 (fun v => sumOver (List.range' (j+1) m)
        (fun t => R (hexof (σ j) (t j) :: listFrom (fun i => hexof (σ i) (t i)) (j+1) m))
        (upd t0 j v))) (upd σ0 j s))
    have A : ∀ (σ : Asg) (v : Nat), sumOver (List.range' (j+1) m)
        (fun t => R (hexof (σ j) (t j) :: listFrom (fun i => hexof (σ i) (t i)) (j+1) m))
        (upd t0 j v) =
        sumOver (List.range' (j+1) m)
        (fun t => R (hexof (σ j) v :: listFrom (fun i => hexof (σ i) (t i)) (j+1) m)) t0 := by
      intro σ v
      rw [sumOver_updout _ _ j v hj]
      apply sumOver_congr
      intro t
      rw [upd_same, listFrom_congr (fun i => hexof (σ i) (upd t j v i)) (fun i => hexof (σ i) (t i))
        m (j+1) (fun i h1 _ => by
          show hexof (σ i) (upd t j v i) = hexof (σ i) (t i)
          rw [upd_other t v (by omega)])]
    have B : ∀ s : Nat, sumOver (List.range' (j+1) m) (fun σ =>
        sum8 (fun v => sumOver (List.range' (j+1) m)
          (fun t => R (hexof (σ j) (t j) :: listFrom (fun i => hexof (σ i) (t i)) (j+1) m))
          (upd t0 j v))) (upd σ0 j s) =
        sumOver (List.range' (j+1) m) (fun σ => sumOver (List.range' (j+1) m) (fun t =>
          sum8 (fun v => R (hexof s v :: listFrom (fun i => hexof (σ i) (t i)) (j+1) m))) t0) σ0 := by
      intro s
      rw [sumOver_updout _ _ j s hj]
      apply sumOver_congr
      intro σ
      rw [sum8_congr (fun v => A (upd σ j s) v), ← sumOver_sum8]
      apply sumOver_congr
      intro t
      apply sum8_congr
      intro v
      rw [upd_same, listFrom_congr (fun i => hexof (upd σ j s i) (t i)) (fun i => hexof (σ i) (t i))
        m (j+1) (fun i h1 _ => by
          show hexof (upd σ j s i) (t i) = hexof (σ i) (t i)
          rw [upd_other σ s (by omega)])]
    rw [sum8_congr B, ← sumOver_sum8]
    apply sumOver_congr
    intro σ
    rw [← sumOver_sum8]

/- ---------- bounded congruence, divisibility, exchange, delta ---------- -/

theorem sumOver_congr_bd (K : List Nat) (F G : Asg → Int) : ∀ t : Asg,
    (∀ a : Asg, (∀ k, k ∈ K → a k < 8) → (∀ k, k ∉ K → a k = t k) → F a = G a) →
    sumOver K F t = sumOver K G t := by
  induction K with
  | nil => intro t h; exact h t (fun _ hk => by cases hk) (fun _ _ => rfl)
  | cons k K ih =>
    intro t h
    apply sum8_congr_lt
    intro v hv
    apply ih
    intro a ha hoff
    apply h a
    · intro j hj
      by_cases hjK : j ∈ K
      · exact ha j hjK
      · have e : j = k := by
          rcases List.mem_cons.mp hj with e | e
          · exact e
          · exact absurd e hjK
        subst e
        rw [hoff j hjK, upd_same]; exact hv
    · intro j hj
      have hjk : j ≠ k := fun e => hj (e ▸ List.mem_cons_self)
      rw [hoff j (fun m => hj (List.mem_cons_of_mem _ m)), upd_other t v hjk]

theorem sum8_dvd_lt (d : Int) (F : Nat → Int) (h : ∀ v, v < 8 → d ∣ F v) : d ∣ sum8 F := by
  simp only [sum8]
  repeat (first | exact h _ (by omega) | apply Int.dvd_add)

theorem sumOver_dvd_bd (d : Int) (K : List Nat) (F : Asg → Int) : ∀ t : Asg,
    (∀ a : Asg, (∀ k, k ∈ K → a k < 8) → (∀ k, k ∉ K → a k = t k) → d ∣ F a) →
    d ∣ sumOver K F t := by
  induction K with
  | nil => intro t h; exact h t (fun _ hk => by cases hk) (fun _ _ => rfl)
  | cons k K ih =>
    intro t h
    apply sum8_dvd_lt
    intro v hv
    apply ih
    intro a ha hoff
    apply h a
    · intro j hj
      by_cases hjK : j ∈ K
      · exact ha j hjK
      · have e : j = k := by
          rcases List.mem_cons.mp hj with e | e
          · exact e
          · exact absurd e hjK
        subst e
        rw [hoff j hjK, upd_same]; exact hv
    · intro j hj
      have hjk : j ≠ k := fun e => hj (e ▸ List.mem_cons_self)
      rw [hoff j (fun m => hj (List.mem_cons_of_mem _ m)), upd_other t v hjk]

theorem all_congr_mem (l : List Nat) (p q : Nat → Bool) (h : ∀ a, a ∈ l → p a = q a) :
    l.all p = l.all q := by
  induction l with
  | nil => rfl
  | cons a l ih =>
    rw [List.all_cons, List.all_cons, h a List.mem_cons_self,
      ih fun b hb => h b (List.mem_cons_of_mem _ hb)]

theorem sumOver_comm2 (K K' : List Nat) (H : Asg → Asg → Int) (c0 : Asg) : ∀ t0 : Asg,
    sumOver K (fun t => sumOver K' (fun c => H t c) c0) t0 =
    sumOver K' (fun c => sumOver K (fun t => H t c) t0) c0 := by
  induction K with
  | nil => intro t0; rfl
  | cons k K ih =>
    intro t0
    show sum8 (fun v => sumOver K (fun t => sumOver K' (fun c => H t c) c0) (upd t0 k v)) = _
    rw [sum8_congr (fun v => ih (upd t0 k v)), ← sumOver_sum8]
    rfl

theorem sum8_delta (a : Nat) (ha : a < 8) (y : Int) :
    sum8 (fun x => if x = a then y else 0) = y := by
  have h8 : a = 0 ∨ a = 1 ∨ a = 2 ∨ a = 3 ∨ a = 4 ∨ a = 5 ∨ a = 6 ∨ a = 7 := by omega
  rcases h8 with e | e | e | e | e | e | e | e <;> subst e <;> simp [sum8]

theorem sumOver_zero (K : List Nat) (t : Asg) : sumOver K (fun _ => 0) t = 0 := by
  induction K generalizing t with
  | nil => rfl
  | cons k K ih =>
    show sum8 (fun v => sumOver K (fun _ => 0) (upd t k v)) = 0
    rw [sum8_congr (fun v => ih (upd t k v))]; rfl

/-- a sum against the indicator "c = v on K" picks out one value. -/
theorem sumOver_delta (K : List Nat) (hK : K.Nodup) (v : Nat → Nat) (hv : ∀ j, j ∈ K → v j < 8)
    (y : Int) : ∀ (F : Asg → Int), (∀ c : Asg, (∀ j, j ∈ K → c j = v j) → F c = y) → ∀ c0 : Asg,
    sumOver K (fun c => if (K.all fun j => c j == v j) then F c else 0) c0 = y := by
  induction K with
  | nil => intro F hF c0; exact hF c0 (fun _ h => by cases h)
  | cons k K ih =>
    intro F hF c0
    have hk : k ∉ K := (List.nodup_cons.mp hK).1
    have hK' := (List.nodup_cons.mp hK).2
    show sum8 (fun x => sumOver K (fun c => if ((k :: K).all fun j => c j == v j) then F c else 0)
      (upd c0 k x)) = y
    have step : ∀ x, sumOver K (fun c => if ((k :: K).all fun j => c j == v j) then F c else 0)
        (upd c0 k x) = if x = v k then y else 0 := by
      intro x
      rw [sumOver_updout _ _ k x hk]
      have hall : ∀ c : Asg, ((k :: K).all fun j => upd c k x j == v j) =
          (x == v k && K.all fun j => c j == v j) := by
        intro c
        rw [List.all_cons, upd_same]
        congr 1
        apply all_congr_mem
        intro j hj
        rw [upd_other c x (fun e => hk (by rw [← e]; exact hj))]
      by_cases e : x = v k
      · rw [if_pos e]
        rw [sumOver_congr K (G := fun c => if (K.all fun j => c j == v j) then F (upd c k x) else 0)
          (fun c => by rw [hall c]; simp [e])]
        apply ih hK' (fun j hj => hv j (List.mem_cons_of_mem _ hj))
        intro c hc
        apply hF
        intro j hj
        rcases List.mem_cons.mp hj with h | h
        · subst h; rw [upd_same]; exact e
        · rw [upd_other c x (fun e => hk (by rw [← e]; exact h))]; exact hc j h
      · rw [if_neg e]
        rw [sumOver_congr K (G := fun _ => 0) (fun c => by rw [hall c]; simp [e]), sumOver_zero]
    rw [sum8_congr step]
    exact sum8_delta _ (hv k List.mem_cons_self) y

/- ---------- counting by values ---------- -/

theorem sumN_ind (x n : Nat) (hx : x < n) : sumN (fun h => if x = h then 1 else 0) n = 1 := by
  induction n with
  | zero => omega
  | succ n ih =>
    show sumN _ n + (if x = n then 1 else 0) = 1
    by_cases e : x = n
    · subst e
      have : sumN (fun h => if x = h then 1 else 0) x = 0 := by
        have := sumN_le (fun h => if x = h then 1 else 0) (fun _ => 0) x (fun k hk => by
          show (if x = k then 1 else 0) ≤ 0
          rw [if_neg (by omega)]; exact Nat.le_refl _)
        have z : ∀ m, sumN (fun _ => 0) m = 0 := by
          intro m; induction m with
          | zero => rfl
          | succ m ihm => show sumN (fun _ => 0) m + 0 = 0; omega
        rw [z] at this; omega
      rw [this, if_pos rfl]
    · rw [ih (by omega), if_neg e]

theorem filter_eq_sumN_count (l : List Nat) (n : Nat) (hl : ∀ x, x ∈ l → x < n) (q : Nat → Bool) :
    (l.filter q).length = sumN (fun h => l.count h * (if q h then 1 else 0)) n := by
  induction l with
  | nil =>
    show 0 = _
    have z : ∀ m, sumN (fun h => ([] : List Nat).count h * (if q h then 1 else 0)) m = 0 := by
      intro m; induction m with
      | zero => rfl
      | succ m ihm =>
        show sumN _ m + ([] : List Nat).count m * (if q m then 1 else 0) = 0
        rw [ihm]; simp
    rw [z]
  | cons x l ih =>
    have hx := hl x List.mem_cons_self
    have e : sumN (fun h => (x :: l).count h * (if q h then 1 else 0)) n =
        sumN (fun h => l.count h * (if q h then 1 else 0)) n +
        sumN (fun h => if x = h then (if q x then 1 else 0) else 0) n := by
      rw [← sumN_add]
      apply Nat.le_antisymm
      · apply sumN_le; intro k _
        show (x :: l).count k * _ ≤ l.count k * _ + _
        rw [List.count_cons]
        by_cases e : x = k
        · subst e; simp [Nat.add_mul]
        · have : (x == k) = false := by simpa using e
          simp [this, e]
      · apply sumN_le; intro k _
        show l.count k * _ + _ ≤ (x :: l).count k * _
        rw [List.count_cons]
        by_cases e : x = k
        · subst e; simp [Nat.add_mul]
        · have : (x == k) = false := by simpa using e
          simp [this, e]
    have e2 : sumN (fun h => if x = h then (if q x then 1 else 0) else 0) n =
        (if q x then 1 else 0) := by
      cases q x
      · have z : ∀ m, sumN (fun h => if x = h then (if false = true then 1 else 0) else 0) m = 0 := by
          intro m; induction m with
          | zero => rfl
          | succ m ihm => show sumN _ m + _ = 0; rw [ihm]; simp
        rw [z]; rfl
      · simpa using sumN_ind x n hx
    rw [e, e2, ← ih fun y hy => hl y (List.mem_cons_of_mem _ hy), List.filter_cons]
    cases q x <;> simp

theorem length_eq_sumN_count (l : List Nat) (n : Nat) (hl : ∀ x, x ∈ l → x < n) :
    l.length = sumN (fun h => l.count h) n := by
  have h := filter_eq_sumN_count l n hl (fun _ => true)
  have e : l.filter (fun _ => true) = l := List.filter_eq_self.mpr (fun _ _ => rfl)
  rw [e] at h
  simpa using h

theorem count_le_one_of_nodup (l : List Nat) (hl : l.Nodup) (h : Nat) : l.count h ≤ 1 := by
  induction l with
  | nil => simp
  | cons a l ih =>
    have ha := (List.nodup_cons.mp hl).1
    have := ih (List.nodup_cons.mp hl).2
    rw [List.count_cons]
    by_cases e : a = h
    · subst e
      have : l.count a = 0 := by
        have hn : ¬ 0 < l.count a := fun hp => ha (List.count_pos_iff.mp hp)
        omega
      simp [this]
    · have : (a == h) = false := by simpa using e
      simp [this]; omega

theorem nodup_of_count_le_one (l : List Nat) (h : ∀ x, l.count x ≤ 1) : l.Nodup := by
  induction l with
  | nil => exact List.nodup_nil
  | cons a l ih =>
    rw [List.nodup_cons]
    constructor
    · intro ha
      have h1 := h a
      rw [List.count_cons] at h1
      have := (@List.count_pos_iff _ _ _ a l).mpr ha
      simp at h1; omega
    · apply ih
      intro x
      have h1 := h x
      rw [List.count_cons] at h1
      omega

theorem sumN_ge (f : Nat → Nat) (n : Nat) (h : ∀ k, k < n → 1 ≤ f k) : n ≤ sumN f n := by
  induction n with
  | zero => exact Nat.le_refl _
  | succ n ih =>
    have := ih fun k hk => h k (by omega); have := h n (by omega)
    show n + 1 ≤ sumN f n + f n; omega

theorem sumN_le_n (f : Nat → Nat) (n : Nat) (h : ∀ k, k < n → f k ≤ 1) : sumN f n ≤ n := by
  induction n with
  | zero => exact Nat.le_refl _
  | succ n ih =>
    have := ih fun k hk => h k (by omega); have := h n (by omega)
    show sumN f n + f n ≤ n + 1; omega

theorem sumN_all_one_ge (f : Nat → Nat) (n : Nat) (h : ∀ k, k < n → 1 ≤ f k)
    (hs : sumN f n = n) : ∀ k, k < n → f k = 1 := by
  induction n with
  | zero => intro k hk; omega
  | succ n ih =>
    have g := sumN_ge f n fun k hk => h k (by omega)
    have hn := h n (by omega)
    have e : sumN f n + f n = n + 1 := hs
    intro k hk
    by_cases ek : k = n
    · subst ek; omega
    · exact ih (fun k hk => h k (by omega)) (by omega) k (by omega)

theorem sumN_all_one_le (f : Nat → Nat) (n : Nat) (h : ∀ k, k < n → f k ≤ 1)
    (hs : sumN f n = n) : ∀ k, k < n → f k = 1 := by
  induction n with
  | zero => intro k hk; omega
  | succ n ih =>
    have g := sumN_le_n f n fun k hk => h k (by omega)
    have hn := h n (by omega)
    have e : sumN f n + f n = n + 1 := hs
    intro k hk
    by_cases ek : k = n
    · subst ek; omega
    · exact ih (fun k hk => h k (by omega)) (by omega) k (by omega)

/-! ## §22  sequences to sums, part 2 -/

/-
  §22 — sequences to sums, part 2: what `isSuper` says about a sequence built from its 32 entries.

  For L = pairs [e_0 .. e_31] with e_k = `entry sigma t k` (so e_0 = 63):

    `super_char` :  isSuper L && bclass L k == d
                      =  distinctOK sigma t && budgetOK cl && (bk cl k == d),   cl = clsAt sigma t

  Ingredients: C1 and C4 hold by construction; "contains all 64 hexagrams" <=> no repeat
  (`all_iff_nodup`, counting by values) <=> the 32 pairs are distinct (`nodup_pairs`); the 63
  transitions are the 32 within-pair distances interleaved with the 31 boundary classes
  (`tr_filter`), and for a permutation the within-pair distances are {2:12, 4:12, 6:8}
  (`within_counts`), so C5 <=> King Wen's boundary budget (`c5_iff_budget`).
-/

theorem pinv : ∀ x < 64, partner (partner x) = x := by decide
theorem pne : ∀ x < 64, partner x ≠ x := by decide
theorem hamp : ∀ x < 64, ham (partner x) (partner (partner x)) = ham x (partner x) := by decide
theorem hexof_lt : ∀ s < 8, ∀ v < 8, hexof s v < 64 := by decide
theorem ham_lt8 : ∀ a < 64, ∀ b < 64, ham a b < 8 := by decide +kernel

/- ---------- listFrom ---------- -/

theorem length_listFrom (a : Nat → Nat) : ∀ m j, (listFrom a j m).length = m := by
  intro m
  induction m with
  | zero => intro j; rfl
  | succ m ih => intro j; show (listFrom a (j+1) m).length + 1 = m + 1; rw [ih]

theorem mem_listFrom (a : Nat → Nat) (y : Nat) : ∀ m j,
    y ∈ listFrom a j m ↔ ∃ i, j ≤ i ∧ i < j + m ∧ y = a i := by
  intro m
  induction m with
  | zero => intro j; simp [listFrom]; intro x h1 h2; omega
  | succ m ih =>
    intro j
    show y ∈ a j :: listFrom a (j+1) m ↔ _
    rw [List.mem_cons, ih]
    constructor
    · rintro (h | ⟨i, h1, h2, h3⟩)
      · exact ⟨j, Nat.le_refl _, by omega, h⟩
      · exact ⟨i, by omega, by omega, h3⟩
    · rintro ⟨i, h1, h2, h3⟩
      by_cases e : i = j
      · subst e; exact Or.inl h3
      · exact Or.inr ⟨i, by omega, by omega, h3⟩

theorem listFrom_eq_map (a : Nat → Nat) : ∀ m j, listFrom a j m = (List.range' j m).map a := by
  intro m
  induction m with
  | zero => intro j; rfl
  | succ m ih => intro j; show a j :: listFrom a (j+1) m = _; rw [ih]; rfl

theorem pw_listFrom (R : Nat → Nat → Prop) (a : Nat → Nat) : ∀ m j,
    (listFrom a j m).Pairwise R ↔ ∀ i i', j ≤ i → i < i' → i' < j + m → R (a i) (a i') := by
  intro m
  induction m with
  | zero => intro j; simp [listFrom]; intro i i' _ _ _; omega
  | succ m ih =>
    intro j
    show (a j :: listFrom a (j+1) m).Pairwise R ↔ _
    rw [List.pairwise_cons, ih]
    constructor
    · rintro ⟨h1, h2⟩ i i' hi hii hi'
      by_cases e : i = j
      · subst e
        exact h1 _ ((mem_listFrom a _ m (i+1)).mpr ⟨i', by omega, by omega, rfl⟩)
      · exact h2 i i' (by omega) hii (by omega)
    · intro h
      refine ⟨fun y hy => ?_, fun i i' hi hii hi' => h i i' (by omega) hii (by omega)⟩
      obtain ⟨i, h1, h2, h3⟩ := (mem_listFrom a y m (j+1)).mp hy
      subst h3
      exact h j i (Nat.le_refl _) (by omega) (by omega)

/- ---------- pairs ---------- -/

theorem length_pairs : ∀ E : List Nat, (pairs E).length = 2 * E.length
  | [] => rfl
  | x :: e => by
    show (pairs e).length + 1 + 1 = 2 * (e.length + 1)
    rw [length_pairs e]; omega

theorem mem_pairs (y : Nat) : ∀ E : List Nat, y ∈ pairs E ↔ ∃ z, z ∈ E ∧ (y = z ∨ y = partner z)
  | [] => by simp [pairs]
  | x :: e => by
    have ih := mem_pairs y e
    show y ∈ x :: partner x :: pairs e ↔ _
    rw [List.mem_cons, List.mem_cons, ih]
    constructor
    · rintro (h | h | ⟨z, hz, h⟩)
      · exact ⟨x, List.mem_cons_self, Or.inl h⟩
      · exact ⟨x, List.mem_cons_self, Or.inr h⟩
      · exact ⟨z, List.mem_cons_of_mem _ hz, h⟩
    · rintro ⟨z, hz, h⟩
      rcases List.mem_cons.mp hz with e1 | e1
      · subst e1
        rcases h with h | h
        · exact Or.inl h
        · exact Or.inr (Or.inl h)
      · exact Or.inr (Or.inr ⟨z, e1, h⟩)

theorem pairs_lt (E : List Nat) (hE : ∀ x, x ∈ E → x < 64) : ∀ y, y ∈ pairs E → y < 64 := by
  intro y hy
  obtain ⟨z, hz, h⟩ := (mem_pairs y E).mp hy
  rcases h with h | h
  · rw [h]; exact hE z hz
  · rw [h]; exact partner_lt z (hE z hz)

theorem sp_false (a b : Nat) : samePair a b = false ↔ (a ≠ b ∧ a ≠ partner b) := by
  simp only [samePair, Bool.or_eq_false_iff, beq_eq_false_iff_ne, ne_eq]

/-- the full sequence has no repeat iff the pairs are pairwise different. -/
theorem nodup_pairs : ∀ E : List Nat, (∀ x, x ∈ E → x < 64) →
    ((pairs E).Nodup ↔ E.Pairwise (fun a b => samePair a b = false))
  | [] => fun _ => by simp [pairs]
  | x :: e => fun h => by
    have hx := h x List.mem_cons_self
    have he : ∀ z, z ∈ e → z < 64 := fun z hz => h z (List.mem_cons_of_mem _ hz)
    have ih := nodup_pairs e he
    show (x :: partner x :: pairs e).Nodup ↔ _
    rw [List.nodup_cons, List.nodup_cons, List.pairwise_cons, ih]
    constructor
    · rintro ⟨h1, h2, h3⟩
      refine ⟨fun z hz => ?_, h3⟩
      rw [sp_false]
      constructor
      · intro e1
        exact h1 (List.mem_cons_of_mem _ ((mem_pairs x e).mpr ⟨z, hz, Or.inl e1⟩))
      · intro e1
        exact h1 (List.mem_cons_of_mem _ ((mem_pairs x e).mpr ⟨z, hz, Or.inr e1⟩))
    · rintro ⟨h1, h3⟩
      refine ⟨?_, ?_, h3⟩
      · intro hm
        rcases List.mem_cons.mp hm with hm | hm
        · exact pne x hx hm.symm
        · obtain ⟨z, hz, hy⟩ := (mem_pairs x e).mp hm
          have := (sp_false x z).mp (h1 z hz)
          rcases hy with hy | hy
          · exact this.1 hy
          · exact this.2 hy
      · intro hm
        obtain ⟨z, hz, hy⟩ := (mem_pairs _ e).mp hm
        have := (sp_false x z).mp (h1 z hz)
        rcases hy with hy | hy
        · apply this.2; rw [← hy, pinv x hx]
        · apply this.1
          have e2 := congrArg partner hy
          rwa [pinv x hx, pinv z (he z hz)] at e2

theorem pairs_getD (d : Nat) : ∀ (E : List Nat) (i : Nat), i < E.length →
    (pairs E).getD (2 * i) d = E.getD i d ∧ (pairs E).getD (2 * i + 1) d = partner (E.getD i d)
  | [], i, h => by simp at h
  | x :: e, 0, _ => by simp [pairs]
  | x :: e, i+1, h => by
    have ih := pairs_getD d e i (by simpa using h)
    show (x :: partner x :: pairs e).getD (2 * i + 1 + 1) d = (x :: e).getD (i+1) d ∧
      (x :: partner x :: pairs e).getD (2 * i + 1 + 1 + 1) d = partner ((x :: e).getD (i+1) d)
    simp only [List.getD_cons_succ]
    exact ih

theorem c1ok_pairs (E : List Nat) (hE : E.length = 32) : c1ok (pairs E) = true := by
  unfold c1ok
  rw [List.all_eq_true]
  intro i hi
  have h := pairs_getD 99 E i (by rw [hE]; exact List.mem_range.mp hi)
  rw [h.1, h.2]; simp

theorem c1ok_c1L (m : Nat) : ∀ l : List Nat, l.length = 2 * m →
    (∀ i, i < m → l.getD (2 * i + 1) 99 = partner (l.getD (2 * i) 99)) → c1L l = true := by
  induction m with
  | zero =>
    intro l hl _
    have : l = [] := List.eq_nil_of_length_eq_zero hl
    subst this; rfl
  | succ m ih =>
    intro l hl h
    match l, hl with
    | x :: y :: l', hl =>
      have h0 := h 0 (by omega)
      simp only [Nat.mul_zero, Nat.zero_add, List.getD_cons_succ, List.getD_cons_zero] at h0
      have hl' : l'.length = 2 * m := by simp at hl; omega
      have := ih l' hl' (fun i hi => by
        have hi' := h (i+1) (by omega)
        rw [show 2 * (i+1) + 1 = (2 * i + 1) + 1 + 1 from rfl,
          show 2 * (i+1) = 2 * i + 1 + 1 from rfl] at hi'
        simp only [List.getD_cons_succ] at hi'
        exact hi')
      show (y == partner x && c1L l') = true
      rw [this, h0]; simp

/-- C1 (KingWen.lean's `c1ok`) implies the recursive form, for a list of length 64. -/
theorem c1L_of_c1ok (l : List Nat) (hl : l.length = 64) (h : c1ok l = true) : c1L l = true := by
  apply c1ok_c1L 32 l hl
  intro i hi
  unfold c1ok at h
  have := List.all_eq_true.mp h i (List.mem_range.mpr hi)
  simpa using this

/- ---------- transitions of a paired sequence ---------- -/

/-- boundary distances: exit of one pair to the entry of the next. -/
def bl : List Nat → List Nat
  | x :: y :: e => ham (partner x) y :: bl (y :: e)
  | _ => []

/-- within-pair distances. -/
def wl (e : List Nat) : List Nat := e.map fun x => ham x (partner x)

theorem filter_cons_len (q : Nat → Bool) (a : Nat) (l : List Nat) :
    ((a :: l).filter q).length = (if q a then 1 else 0) + (l.filter q).length := by
  rw [List.filter_cons]
  cases q a <;> simp; omega

theorem tr_filter (q : Nat → Bool) : ∀ E : List Nat,
    ((transitions (pairs E)).filter q).length = ((wl E).filter q).length + ((bl E).filter q).length
  | [] => rfl
  | [x] => by
    show ([ham x (partner x)].filter q).length = ([ham x (partner x)].filter q).length + 0
    omega
  | x :: y :: e => by
    have ih := tr_filter q (y :: e)
    show ((ham x (partner x) :: ham (partner x) y :: transitions (pairs (y :: e))).filter q).length =
      ((ham x (partner x) :: wl (y :: e)).filter q).length +
      ((ham (partner x) y :: bl (y :: e)).filter q).length
    rw [filter_cons_len, filter_cons_len, filter_cons_len, filter_cons_len, ih]
    omega

theorem tr_getD : ∀ (E : List Nat) (k : Nat),
    (transitions (pairs E)).getD (2 * k + 1) 0 = (bl E).getD k 0
  | [], k => by simp [pairs, transitions, bl]
  | [x], k => by
    show [ham x (partner x)].getD (2 * k + 1) 0 = ([] : List Nat).getD k 0
    simp
  | x :: y :: e, 0 => rfl
  | x :: y :: e, k+1 => by
    have ih := tr_getD (y :: e) k
    show (ham x (partner x) :: ham (partner x) y :: transitions (pairs (y :: e))).getD
      (2 * k + 1 + 1 + 1) 0 = (ham (partner x) y :: bl (y :: e)).getD (k+1) 0
    simp only [List.getD_cons_succ]
    exact ih

theorem bl_listFrom (a : Nat → Nat) : ∀ m j,
    bl (listFrom a j (m+1)) = listFrom (fun i => ham (partner (a i)) (a (i+1))) j m := by
  intro m
  induction m with
  | zero => intro j; rfl
  | succ m ih =>
    intro j
    show ham (partner (a j)) (a (j+1)) :: bl (listFrom a (j+1) (m+1)) = _
    rw [ih (j+1)]; rfl

/-- both members of a pair have the same within-pair distance. -/
theorem wl_count (g : Nat) : ∀ E : List Nat, (∀ x, x ∈ E → x < 64) →
    ((pairs E).filter (fun x => ham x (partner x) == g)).length =
      2 * ((wl E).filter (· == g)).length
  | [], _ => rfl
  | x :: e, h => by
    have ih := wl_count g e fun z hz => h z (List.mem_cons_of_mem _ hz)
    show ((x :: partner x :: pairs e).filter (fun x => ham x (partner x) == g)).length =
      2 * ((ham x (partner x) :: wl e).filter (· == g)).length
    rw [filter_cons_len, filter_cons_len, filter_cons_len, ih, hamp x (h x List.mem_cons_self)]
    split <;> omega

/- ---------- contains all 64 <=> no repeat ---------- -/

theorem counts_one_of_all (L : List Nat) (hlen : L.length = 64) (hlt : ∀ x, x ∈ L → x < 64)
    (hall : ∀ h, h < 64 → h ∈ L) : ∀ h, h < 64 → L.count h = 1 :=
  sumN_all_one_ge (fun h => L.count h) 64 (fun k hk => List.count_pos_iff.mpr (hall k hk))
    (by rw [← length_eq_sumN_count L 64 hlt, hlen])

theorem counts_one_of_nodup (L : List Nat) (hlen : L.length = 64) (hlt : ∀ x, x ∈ L → x < 64)
    (hnd : L.Nodup) : ∀ h, h < 64 → L.count h = 1 :=
  sumN_all_one_le (fun h => L.count h) 64 (fun k _ => count_le_one_of_nodup L hnd k)
    (by rw [← length_eq_sumN_count L 64 hlt, hlen])

theorem all_iff_nodup (L : List Nat) (hlen : L.length = 64) (hlt : ∀ x, x ∈ L → x < 64) :
    (∀ h, h < 64 → h ∈ L) ↔ L.Nodup := by
  constructor
  · intro hall
    have c1 := counts_one_of_all L hlen hlt hall
    apply nodup_of_count_le_one
    intro x
    by_cases hx : x < 64
    · rw [c1 x hx]; exact Nat.le_refl _
    · have : ¬ 0 < L.count x := fun hp => hx (hlt x (List.count_pos_iff.mp hp))
      omega
  · intro hnd h hh
    have := counts_one_of_nodup L hlen hlt hnd h hh
    exact List.count_pos_iff.mp (by omega)

theorem sumN_congr (f g : Nat → Nat) (n : Nat) (h : ∀ k, k < n → f k = g k) :
    sumN f n = sumN g n :=
  Nat.le_antisymm (sumN_le f g n fun k hk => by rw [h k hk]; exact Nat.le_refl _)
    (sumN_le g f n fun k hk => by rw [h k hk]; exact Nat.le_refl _)

/-- over a permutation of the 64 hexagrams, a count is the count over 0..63. -/
theorem filter_perm64 (L : List Nat) (hlen : L.length = 64) (hlt : ∀ x, x ∈ L → x < 64)
    (hnd : L.Nodup) (q : Nat → Bool) :
    (L.filter q).length = sumN (fun h => if q h then 1 else 0) 64 := by
  rw [filter_eq_sumN_count L 64 hlt q]
  apply sumN_congr
  intro k hk
  rw [counts_one_of_nodup L hlen hlt hnd k hk]; simp

theorem wc0 : sumN (fun h => if (ham h (partner h) == 0) then 1 else 0) 64 = 0 := by decide +kernel
theorem wc1 : sumN (fun h => if (ham h (partner h) == 1) then 1 else 0) 64 = 0 := by decide +kernel
theorem wc2 : sumN (fun h => if (ham h (partner h) == 2) then 1 else 0) 64 = 24 := by decide +kernel
theorem wc3 : sumN (fun h => if (ham h (partner h) == 3) then 1 else 0) 64 = 0 := by decide +kernel
theorem wc4 : sumN (fun h => if (ham h (partner h) == 4) then 1 else 0) 64 = 24 := by decide +kernel
theorem wc5 : sumN (fun h => if (ham h (partner h) == 5) then 1 else 0) 64 = 0 := by decide +kernel
theorem wc6 : sumN (fun h => if (ham h (partner h) == 6) then 1 else 0) 64 = 16 := by decide +kernel

/-- the within-pair distances of a permutation satisfying C1: {2:12, 4:12, 6:8}, nothing else. -/
theorem within_counts (E : List Nat) (hE : ∀ x, x ∈ E → x < 64) (hlen : E.length = 32)
    (hnd : (pairs E).Nodup) :
    ((wl E).filter (· == 0)).length = 0 ∧ ((wl E).filter (· == 1)).length = 0 ∧
    ((wl E).filter (· == 2)).length = 12 ∧ ((wl E).filter (· == 3)).length = 0 ∧
    ((wl E).filter (· == 4)).length = 12 ∧ ((wl E).filter (· == 5)).length = 0 ∧
    ((wl E).filter (· == 6)).length = 8 := by
  have hl : (pairs E).length = 64 := by rw [length_pairs, hlen]
  have hlt := pairs_lt E hE
  have f := fun g => filter_perm64 (pairs E) hl hlt hnd (fun x => ham x (partner x) == g)
  have w := fun g => wl_count g E hE
  have f0 := f 0; have f1 := f 1; have f2 := f 2; have f3 := f 3; have f4 := f 4
  have f5 := f 5; have f6 := f 6
  rw [w 0, wc0] at f0; rw [w 1, wc1] at f1; rw [w 2, wc2] at f2; rw [w 3, wc3] at f3
  rw [w 4, wc4] at f4; rw [w 5, wc5] at f5; rw [w 6, wc6] at f6
  omega

/-- value of the class sequence at boundary k (0 beyond the last boundary). -/
def bk (c : Nat → Nat) (k : Nat) : Nat := if k < 31 then c k else 0

theorem map_range_getD (c : Nat → Nat) (n k : Nat) :
    ((List.range n).map c).getD k 0 = if k < n then c k else 0 := by
  by_cases h : k < n
  · rw [if_pos h, List.getD_eq_getElem?_getD, List.getElem?_map, List.getElem?_range h]; rfl
  · rw [if_neg h, List.getD_eq_getElem?_getD, List.getElem?_eq_none (by simp; omega)]; rfl

/-- C5 <=> King Wen's boundary budget, for a sequence without repeats built from 32 entries. -/
theorem c5_iff_budget (E : List Nat) (hE : ∀ x, x ∈ E → x < 64) (hlen : E.length = 32)
    (hnd : (pairs E).Nodup) (c : Nat → Nat) (hbl : bl E = (List.range 31).map c) :
    c5ok (pairs E) = budgetOK c := by
  obtain ⟨w0, w1, w2, w3, w4, w5, w6⟩ := within_counts E hE hlen hnd
  have t := fun g => tr_filter (· == g) E
  have t0 := t 0; have t1 := t 1; have t2 := t 2; have t3 := t 3; have t4 := t 4
  have t5 := t 5; have t6 := t 6
  rw [hbl] at t0 t1 t2 t3 t4 t5 t6
  rw [w0] at t0; rw [w1] at t1; rw [w2] at t2; rw [w3] at t3; rw [w4] at t4; rw [w5] at t5
  rw [w6] at t6
  have hcnt := count_cls ((List.range 31).map c)
  have hl : ((List.range 31).map c).length = 31 := by simp
  rw [Bool.eq_iff_iff]
  simp only [c5ok, budgetOK, Bool.and_eq_true, beq_iff_eq]
  rw [t0, t1, t2, t3, t4, t5, t6]
  constructor
  · rintro ⟨⟨⟨⟨⟨⟨a1, a2⟩, a3⟩, a4⟩, a5⟩, a6⟩, a0⟩
    refine ⟨⟨⟨⟨?_, ?_⟩, ?_⟩, ?_⟩, ?_⟩ <;> omega
  · intro hb
    have hb' : budgetOK c = true := by
      simp only [budgetOK, Bool.and_eq_true, beq_iff_eq]; exact hb
    have hc := budget_cls c hb'
    have z : ∀ g, g ∉ [1, 2, 3, 4, 6] → (((List.range 31).map c).filter (· == g)).length = 0 := by
      intro g hg
      rw [List.length_eq_zero_iff, List.filter_eq_nil_iff]
      intro x hx
      obtain ⟨k, hk, e⟩ := List.mem_map.mp hx
      have := hc k (List.mem_range.mp hk)
      rw [e] at this
      intro e2
      have e3 : x = g := by simpa using e2
      rw [e3] at this; exact hg this
    have z5 := z 5 (by decide)
    have z0 := z 0 (by decide)
    obtain ⟨⟨⟨⟨b1, b2⟩, b3⟩, b4⟩, b6⟩ := hb
    refine ⟨⟨⟨⟨⟨⟨?_, ?_⟩, ?_⟩, ?_⟩, ?_⟩, ?_⟩, ?_⟩ <;> omega

/- ---------- the characterisation ---------- -/

theorem entry_lt (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (t : Asg) (k : Nat) : entry σ t k < 64 := by
  rw [entry_gen]
  apply hexof_lt
  · unfold sg; split
    · omega
    · exact hσ k
  · split
    · omega
    · exact Nat.mod_lt _ (by omega)

/-- the sequence with entries `entry sigma t 0..31`. -/
def LL (σ : Nat → Nat) (t : Asg) : List Nat := pairs (listFrom (entry σ t) 0 32)

theorem LL_c4 (σ : Nat → Nat) (t : Asg) : c4ok (LL σ t) = true := by
  show c4ok (entry σ t 0 :: partner (entry σ t 0) :: pairs (listFrom (entry σ t) 1 31)) = true
  rw [entry_zero]
  simp [c4ok, partner_63]

theorem LL_nodup (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (t : Asg) :
    (LL σ t).Nodup ↔ distinctOK σ t = true := by
  unfold LL
  rw [nodup_pairs _ (fun x hx => by
    obtain ⟨i, _, _, e⟩ := (mem_listFrom _ x 32 0).mp hx
    rw [e]; exact entry_lt σ hσ t i), pw_listFrom, distinct_iff]
  constructor
  · intro h i j hij hj; exact h i j (Nat.zero_le _) hij (by omega)
  · intro h i j _ hij hj; exact h i j hij (by omega)

/-- STEP 1 at the level of one sequence. -/
theorem super_char (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (t : Asg) (k d : Nat) :
    (isSuper (LL σ t) && bclass (LL σ t) k == d) =
      (distinctOK σ t && budgetOK (clsAt σ t) && (bk (clsAt σ t) k == d)) := by
  have hE : ∀ x, x ∈ listFrom (entry σ t) 0 32 → x < 64 := fun x hx => by
    obtain ⟨i, _, _, e⟩ := (mem_listFrom _ x 32 0).mp hx
    rw [e]; exact entry_lt σ hσ t i
  have hEl : (listFrom (entry σ t) 0 32).length = 32 := length_listFrom _ 32 0
  have hLl : (LL σ t).length = 64 := by unfold LL; rw [length_pairs, hEl]
  have hLt := pairs_lt _ hE
  have hbl : bl (listFrom (entry σ t) 0 32) = (List.range 31).map (clsAt σ t) := by
    rw [bl_listFrom (entry σ t) 31 0, listFrom_eq_map, List.range_eq_range']
    rfl
  have hbc : bclass (LL σ t) k = bk (clsAt σ t) k := by
    unfold bclass LL
    rw [tr_getD, hbl, map_range_getD]; rfl
  rw [hbc]
  congr 1
  unfold isSuper
  rw [c1ok_pairs _ hEl |> fun h => (show c1ok (LL σ t) = true from h), LL_c4]
  cases hd : distinctOK σ t with
  | true =>
    have hnd := (LL_nodup σ hσ t).mpr hd
    have hall := (all_iff_nodup (LL σ t) hLl hLt).mpr hnd
    have e1 : ((List.range 64).all fun h => (LL σ t).contains h) = true := by
      rw [List.all_eq_true]; intro h hh
      exact List.contains_iff_mem.mpr (hall h (List.mem_range.mp hh))
    rw [e1, show c5ok (LL σ t) = budgetOK (clsAt σ t) from
      c5_iff_budget _ hE hEl hnd (clsAt σ t) hbl]
    simp
  | false =>
    have e1 : ((List.range 64).all fun h => (LL σ t).contains h) = false := by
      cases hv : ((List.range 64).all fun h => (LL σ t).contains h) with
      | false => rfl
      | true =>
        exfalso
        have hall : ∀ h, h < 64 → h ∈ LL σ t := fun h hh =>
          List.contains_iff_mem.mp (List.all_eq_true.mp hv h (List.mem_range.mpr hh))
        have hnd := (all_iff_nodup (LL σ t) hLl hLt).mp hall
        have := (LL_nodup σ hσ t).mp hnd
        rw [hd] at this; cases this
    rw [e1]; simp

/-! ## §23  sequences to sums, part 3: a cell as a sum of fibres (Step 1) -/

/-
  §23 — sequences to sums, part 3: THE V2 CELL AS A SUM OF COORDINATE-MODEL FIBRES.

      theorem cell_eq (k d : Nat) :
        ((cellV2 k d : Nat) : Int) = sumOver slots (Gs k d) (fun _ => 0)
      -- Gs k d sigma = sum over class sequences c (boundaries 0..30, values 0..7) of
      --                [budgetOK c and c_k = d] * fibreC sigma c

  A fibre-by-fibre identity "sequence fibre = coordinate fibre" would need side conditions (see
  `fibreC_head_free`, §20); here the budget is carried by the indicator and C4 pins
  slot 0 to the anchor, so no side condition on sigma 0 or on c is needed.
-/

/-- indicator: c has King Wen's budget and class d at boundary k. -/
def Bind (k d : Nat) (c : Asg) : Int := if (budgetOK c && (bk c k == d)) then 1 else 0

/-- the part of the cell (k, d) that lies over the skeleton sigma. -/
def Gs (k d : Nat) (σ : Asg) : Int :=
  sumOver (List.range 31) (fun c => Bind k d c * fibreC σ c) (fun _ => 0)

theorem clsAt_lt (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (t : Asg) (j : Nat) : clsAt σ t j < 8 :=
  ham_lt8 _ (partner_lt _ (entry_lt σ hσ t j)) _ (entry_lt σ hσ t (j+1))

theorem Bind_congr (k d : Nat) (c c' : Asg) (h : ∀ j, j ∈ List.range 31 → c j = c' j) :
    Bind k d c = Bind k d c' := by
  have hm : (List.range 31).map c = (List.range 31).map c' := List.map_congr_left h
  have hb : budgetOK c = budgetOK c' := by simp only [budgetOK, hm]
  have hk : bk c k = bk c' k := by
    unfold bk; split
    · exact h k (List.mem_range.mpr (by assumption))
    · rfl
  unfold Bind; rw [hb, hk]

/-- one sequence: the indicator of the cell is a sum over class sequences of B(c) * W. -/
theorem point_eq (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (t : Asg) (k d : Nat) :
    (if (isSuper (LL σ t) && bclass (LL σ t) k == d) then (1 : Int) else 0) =
      sumOver (List.range 31) (fun c => Bind k d c * W σ c t) (fun _ => 0) := by
  rw [super_char σ hσ t k d]
  have e : ∀ c : Asg, Bind k d c * W σ c t =
      if ((List.range 31).all fun j => c j == clsAt σ t j) then
        Bind k d c * (if distinctOK σ t then 1 else 0) else 0 := by
    intro c
    have ha : ((List.range 31).all fun j => clsAt σ t j == c j) =
        ((List.range 31).all fun j => c j == clsAt σ t j) :=
      all_congr_mem _ _ _ fun j _ => by
        rw [Bool.eq_iff_iff]; simp only [beq_iff_eq]; exact eq_comm
    unfold W
    rw [ha]
    cases distinctOK σ t <;> cases ((List.range 31).all fun j => c j == clsAt σ t j) <;> simp
  rw [sumOver_congr _ e]
  rw [sumOver_delta (List.range 31) List.nodup_range (clsAt σ t) (fun j _ => clsAt_lt σ hσ t j)
    (Bind k d (clsAt σ t) * (if distinctOK σ t then 1 else 0)) _
    (fun c hc => by rw [Bind_congr k d c (clsAt σ t) hc])]
  unfold Bind
  cases distinctOK σ t <;> cases budgetOK (clsAt σ t) <;> cases (bk (clsAt σ t) k == d) <;> rfl

theorem c4_head (x : Nat) (r : List Nat) (h : c4ok (x :: r) = true) : x = 63 := by
  simp only [c4ok, List.getD_cons_zero, Bool.and_eq_true, beq_iff_eq] at h
  exact h.1

/-- **Step 1 for a V2 cell**: the abstract count is a sum of coordinate-model fibres. -/
theorem cell_eq (k d : Nat) :
    ((cellV2 k d : Nat) : Int) = sumOver slots (Gs k d) (fun _ => 0) := by
  -- 1. length of a filtered list = sum of indicators
  have s1 : ((cellV2 k d : Nat) : Int) =
      lsum (seqs (2 * 32)) (fun l => if (isSuper l && bclass l k == d) then 1 else 0) :=
    filter_length _ _
  -- 2. C1: sum over the 32 entries
  have s2 := C1sum 32 (fun l => if (isSuper l && bclass l k == d) then (1 : Int) else 0)
    (fun l hl hc => by
      cases hs : isSuper l with
      | false => simp
      | true =>
        exfalso
        have h1 : c1ok l = true := by
          simp only [isSuper, Bool.and_eq_true] at hs; exact hs.1.1.2
        rw [c1L_of_c1ok l hl h1] at hc; cases hc)
  -- 3. C4: the first entry is 63
  have s3 : lsum (seqs (31+1)) (fun e => if (isSuper (pairs e) && bclass (pairs e) k == d)
        then (1 : Int) else 0) =
      lsum (seqs 31) (fun e => if (isSuper (pairs (63 :: e)) && bclass (pairs (63 :: e)) k == d)
        then (1 : Int) else 0) := by
    rw [S_succ]
    apply lsum_congr
    intro e _
    rw [lsum_congr (List.range 64) (g := fun x => if x = 63 then
        (if (isSuper (pairs (x :: e)) && bclass (pairs (x :: e)) k == d) then (1 : Int) else 0)
        else 0) (fun x _ => by
      by_cases ex : x = 63
      · rw [if_pos ex]
      · rw [if_neg ex]
        cases hs : isSuper (pairs (x :: e)) with
        | false => simp
        | true =>
          exfalso
          have h4 : c4ok (pairs (x :: e)) = true := by
            simp only [isSuper, Bool.and_eq_true] at hs; exact hs.1.2
          exact ex (c4_head x _ h4))]
    exact lsum_delta _ List.nodup_range 63 (List.mem_range.mpr (by omega)) _
  -- 4. entries as (sigma, t)
  have s4 := Ssum 31 1 (fun e => if (isSuper (pairs (63 :: e)) && bclass (pairs (63 :: e)) k == d)
        then (1 : Int) else 0) (fun _ => 0) (fun _ => 0)
  rw [s1, s2]
  show lsum (seqs (31+1)) _ = _
  rw [s3, s4]
  -- 5, 6. pointwise, then exchange the sums over t and c
  show sumOver slots _ _ = _
  apply sumOver_congr_bd
  intro σ hσb hσo
  have hσ : ∀ j, σ j < 8 := by
    intro j
    by_cases hj : j ∈ slots
    · exact hσb j hj
    · rw [hσo j hj]; omega
  show sumOver slots _ _ = sumOver (List.range 31) (fun c => Bind k d c * fibreC σ c) (fun _ => 0)
  have e6 : sumOver (List.range 31) (fun c => Bind k d c * fibreC σ c) (fun _ => 0) =
      sumOver slots (fun t => sumOver (List.range 31) (fun c => Bind k d c * W σ c t) (fun _ => 0))
        (fun _ => 0) := by
    rw [sumOver_comm2]
    apply sumOver_congr
    intro c
    exact (sumOver_const_mul slots (Bind k d c) (W σ c) (fun _ => 0)).symm
  rw [e6]
  apply sumOver_congr_bd
  intro t htb _
  have hL : pairs (63 :: listFrom (fun i => hexof (σ i) (t i)) 1 31) = LL σ t := by
    show _ = pairs (entry σ t 0 :: listFrom (entry σ t) 1 31)
    rw [entry_zero, listFrom_congr (fun i => hexof (σ i) (t i)) (entry σ t) 31 1 (fun i h1 h2 => by
      rw [entry_pos σ t i (by omega),
        Nat.mod_eq_of_lt (htb i ((mem_slots i).mpr ⟨h1, by omega⟩))])]
  rw [hL]
  exact point_eq σ hσ t k d

/-! ## §24  THE FACTOR 6 AND THE MAIN THEOREMS (Step 6) -/

/-
  §24 — THE FACTOR 6 AND THE V2 THEOREM.

      theorem cellV2_dvd : CellV2Dvd        -- forall k d, 2^21 * 3 | cellV2 k d
      theorem superCount_dvd  : SuperCountDvd         -- 2^21 * 3 | superCount

  The six coordinate permutations `pm g` (g = 0..5) act on supports and on section coordinates.
  `fibreC` is invariant (`fibreC_pm`), hence so is the part `Gs` of a cell over a skeleton.
  A skeleton over which the cell is non-empty contains the supports 1, 2 and 4; the six
  permutations put their first occurrences into the six possible orders, exactly one of which is
  increasing (`rsum_one`).  So the sum over all skeletons is 6 times the sum over the skeletons
  whose first occurrences are in increasing order, and every term is divisible by 2^20
  (`fibreC_dvd`, §19).
-/

def ptab (g : Nat) : List Nat :=
  match g with
  | 0 => [0, 1, 2, 3, 4, 5, 6, 7]
  | 1 => [0, 2, 1, 3, 4, 6, 5, 7]
  | 2 => [0, 4, 2, 6, 1, 5, 3, 7]
  | 3 => [0, 1, 4, 5, 2, 3, 6, 7]
  | 4 => [0, 2, 4, 6, 1, 3, 5, 7]
  | _ => [0, 4, 1, 5, 2, 6, 3, 7]

/-- the g-th permutation of the three coordinates, acting on 3-bit vectors. -/
def pm (g x : Nat) : Nat := (ptab g).getD (x % 8) 0

theorem pm_lt : ∀ g < 6, ∀ x < 8, pm g x < 8 := by decide
theorem pm_inj : ∀ g < 6, ∀ x < 8, ∀ y < 8, pm g x = pm g y → x = y := by decide
theorem pm_0 : ∀ g < 6, pm g 0 = 0 := by decide
theorem pm_7 : ∀ g < 6, pm g 7 = 7 := by decide
theorem pm_mod (g x : Nat) : pm g (x % 8) = pm g x := by unfold pm; rw [Nat.mod_mod]

/-- the permutations are isometries that preserve pairs. -/
theorem pm_sp : ∀ g < 6, ∀ s < 8, ∀ v < 8, ∀ s' < 8, ∀ v' < 8,
    samePair (hexof (pm g s) (pm g v)) (hexof (pm g s') (pm g v')) =
      samePair (hexof s v) (hexof s' v') := by decide +kernel
theorem pm_cls : ∀ g < 6, ∀ s < 8, ∀ v < 8, ∀ s' < 8, ∀ v' < 8,
    ham (partner (hexof (pm g s) (pm g v))) (hexof (pm g s') (pm g v')) =
      ham (partner (hexof s v)) (hexof s' v') := by decide +kernel

theorem sum8_pm (g : Nat) (hg : g < 6) (f : Nat → Int) : sum8 (fun v => f (pm g v)) = sum8 f := by
  have h6 : g = 0 ∨ g = 1 ∨ g = 2 ∨ g = 3 ∨ g = 4 ∨ g = 5 := by omega
  rcases h6 with e | e | e | e | e | e <;> subst e
  · show f 0 + f 1 + f 2 + f 3 + f 4 + f 5 + f 6 + f 7 = f 0 + f 1 + f 2 + f 3 + f 4 + f 5 + f 6 + f 7
    rfl
  · show f 0 + f 2 + f 1 + f 3 + f 4 + f 6 + f 5 + f 7 = f 0 + f 1 + f 2 + f 3 + f 4 + f 5 + f 6 + f 7
    omega
  · show f 0 + f 4 + f 2 + f 6 + f 1 + f 5 + f 3 + f 7 = f 0 + f 1 + f 2 + f 3 + f 4 + f 5 + f 6 + f 7
    omega
  · show f 0 + f 1 + f 4 + f 5 + f 2 + f 3 + f 6 + f 7 = f 0 + f 1 + f 2 + f 3 + f 4 + f 5 + f 6 + f 7
    omega
  · show f 0 + f 2 + f 4 + f 6 + f 1 + f 3 + f 5 + f 7 = f 0 + f 1 + f 2 + f 3 + f 4 + f 5 + f 6 + f 7
    omega
  · show f 0 + f 4 + f 1 + f 5 + f 2 + f 6 + f 3 + f 7 = f 0 + f 1 + f 2 + f 3 + f 4 + f 5 + f 6 + f 7
    omega

/-- re-indexing a sum over assignments by a coordinate permutation. -/
theorem sumOver_pm (g : Nat) (hg : g < 6) (K : List Nat) (F : Asg → Int) : ∀ t0 : Asg,
    sumOver K (fun t => F (fun k => pm g (t k))) t0 = sumOver K F (fun k => pm g (t0 k)) := by
  induction K with
  | nil => intro t0; rfl
  | cons k K ih =>
    intro t0
    show sum8 (fun v => sumOver K (fun t => F (fun k => pm g (t k))) (upd t0 k v)) =
      sum8 (fun v => sumOver K F (upd (fun j => pm g (t0 j)) k v))
    have e : ∀ v, (fun j => pm g (upd t0 k v j)) = upd (fun j => pm g (t0 j)) k (pm g v) := by
      intro v; funext j
      by_cases h : j = k
      · subst h; simp [upd]
      · simp [upd, h]
    rw [sum8_congr (fun v => by rw [ih (upd t0 k v), e v])]
    exact sum8_pm g hg (fun v => sumOver K F (upd (fun j => pm g (t0 j)) k v))

/- ---------- invariance of the model ---------- -/

theorem sg_lt (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (k : Nat) : sg σ k < 8 := by
  unfold sg; split
  · omega
  · exact hσ k

theorem entry_pm (g : Nat) (hg : g < 6) (σ : Nat → Nat) (t : Asg) (k : Nat) :
    entry (fun j => pm g (σ j)) (fun j => pm g (t j)) k =
      hexof (pm g (sg σ k)) (pm g (if k = 0 then 7 else t k % 8)) := by
  by_cases hk : k = 0
  · subst hk
    rw [entry_zero]; simp only [sg, if_true]
    rw [pm_0 g hg, pm_7 g hg, hexof_0_7]
  · rw [entry_pos _ _ k hk]
    simp only [sg, if_neg hk]
    have hlt : pm g (t k) < 8 := by
      rw [← pm_mod g (t k)]; exact pm_lt g hg _ (Nat.mod_lt _ (by omega))
    rw [pm_mod, Nat.mod_eq_of_lt hlt]

theorem W_pm (g : Nat) (hg : g < 6) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (c : Nat → Nat) (t : Asg) :
    W (fun j => pm g (σ j)) c (fun j => pm g (t j)) = W σ c t := by
  have v8 : ∀ k, (if k = 0 then 7 else t k % 8) < 8 := by
    intro k; split
    · omega
    · exact Nat.mod_lt _ (by omega)
  have hsp : ∀ i j, samePair (entry (fun j => pm g (σ j)) (fun j => pm g (t j)) i)
      (entry (fun j => pm g (σ j)) (fun j => pm g (t j)) j) =
      samePair (entry σ t i) (entry σ t j) := by
    intro i j
    rw [entry_pm g hg, entry_pm g hg, entry_gen σ t i, entry_gen σ t j]
    exact pm_sp g hg _ (sg_lt σ hσ i) _ (v8 i) _ (sg_lt σ hσ j) _ (v8 j)
  have hcl : ∀ k, clsAt (fun j => pm g (σ j)) (fun j => pm g (t j)) k = clsAt σ t k := by
    intro k
    rw [clsAt_def, clsAt_def, entry_pm g hg, entry_pm g hg, entry_gen σ t k, entry_gen σ t (k+1)]
    exact pm_cls g hg _ (sg_lt σ hσ k) _ (v8 k) _ (sg_lt σ hσ (k+1)) _ (v8 (k+1))
  unfold W distinctOK
  simp only [hsp, hcl]

theorem pm_zero_fun (g : Nat) (hg : g < 6) : (fun _ : Nat => pm g ((fun _ => 0 : Asg) 0)) = fun _ => 0 := by
  funext _; exact pm_0 g hg

theorem fibreC_pm (g : Nat) (hg : g < 6) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (c : Nat → Nat) :
    fibreC (fun j => pm g (σ j)) c = fibreC σ c := by
  unfold fibreC
  have e : sumOver (List.range' 1 31) (W σ c) (fun _ => 0) =
      sumOver (List.range' 1 31)
        (fun t => W (fun j => pm g (σ j)) c (fun j => pm g (t j))) (fun _ => 0) :=
    sumOver_congr _ (fun t => (W_pm g hg σ hσ c t).symm) _
  rw [e, sumOver_pm g hg _ (W (fun j => pm g (σ j)) c) (fun _ => 0)]
  have z : (fun _ : Nat => pm g 0) = fun _ => 0 := by funext _; exact pm_0 g hg
  rw [z]

theorem Gs_pm (g : Nat) (hg : g < 6) (k d : Nat) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) :
    Gs k d (fun j => pm g (σ j)) = Gs k d σ := by
  unfold Gs
  exact sumOver_congr _ (fun c => by rw [fibreC_pm g hg σ hσ c]) _

/-- the coordinate-model fibre theorem, applied to the part of a cell over one skeleton. -/
theorem Gs_dvd (k d : Nat) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) :
    ((2 ^ 20 : Nat) : Int) ∣ Gs k d σ := by
  unfold Gs
  apply sumOver_dvd
  intro c
  unfold Bind
  cases hb : budgetOK c with
  | false => simp
  | true => exact Int.dvd_trans (fibreC_dvd σ c hσ hb) (Int.dvd_mul_left _ _)

/- ---------- a non-empty skeleton contains the supports 1, 2, 4 ---------- -/

theorem W_zero_bad (σ : Nat → Nat) (hσ : ∀ k, σ k < 8)
    (h : ¬ ((Ks σ 1).length = 4 ∧ (Ks σ 2).length = 4 ∧ (Ks σ 4).length = 4)) (c : Nat → Nat)
    (t : Asg) : W σ c t = 0 := by
  have hperm : (KA σ).Perm slots := catK_perm σ slots 8 (fun k _ => hσ k)
  have hlen : sumN (fun s => (Ks σ s).length) 8 = 31 := by
    have := hperm.length_eq
    rw [KA, catK_length] at this
    rw [this]; rfl
  simp only [sumN] at hlen
  by_cases h0 : 4 ≤ (Ks σ 0).length
  · exact over_C σ c h0 t
  by_cases h1 : 5 ≤ (Ks σ 1).length
  · exact over_R σ c 1 (by omega) h1 t
  by_cases h2 : 5 ≤ (Ks σ 2).length
  · exact over_R σ c 2 (by omega) h2 t
  by_cases h3 : 5 ≤ (Ks σ 3).length
  · exact over_R σ c 3 (by omega) h3 t
  by_cases h4 : 5 ≤ (Ks σ 4).length
  · exact over_R σ c 4 (by omega) h4 t
  by_cases h5 : 5 ≤ (Ks σ 5).length
  · exact over_R σ c 5 (by omega) h5 t
  by_cases h6 : 5 ≤ (Ks σ 6).length
  · exact over_R σ c 6 (by omega) h6 t
  by_cases h7 : 5 ≤ (Ks σ 7).length
  · exact over_R σ c 7 (by omega) h7 t
  exfalso; apply h; omega

theorem Gs_zero_bad (k d : Nat) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8)
    (h : ¬ ((Ks σ 1).length = 4 ∧ (Ks σ 2).length = 4 ∧ (Ks σ 4).length = 4)) : Gs k d σ = 0 := by
  unfold Gs
  rw [sumOver_congr (List.range 31) (G := fun _ => 0) (fun c => by
    have : fibreC σ c = 0 := by
      unfold fibreC
      rw [sumOver_congr _ (G := fun _ => 0) (fun t => W_zero_bad σ hσ h c t), sumOver_zero]
    rw [this, Int.mul_zero]), sumOver_zero]

/-- position of the first slot of support v (31 if there is none). -/
def pos (σ : Nat → Nat) (v : Nat) : Nat := (slots.map σ).idxOf v

theorem mem_of_len4 (σ : Nat → Nat) (s : Nat) (h : (Ks σ s).length = 4) : s ∈ slots.map σ := by
  have e := Ks_eq4 σ s h
  have hm := (mem_Ks σ s (kk σ s 0)).mp (by rw [e]; exact List.mem_cons_self)
  exact List.mem_map.mpr ⟨kk σ s 0, (mem_slots _).mpr ⟨hm.1, hm.2.1⟩, hm.2.2⟩

theorem idxOf_ne (a b : Nat) (hab : a ≠ b) : ∀ l : List Nat, a ∈ l → b ∈ l →
    l.idxOf a ≠ l.idxOf b
  | [], ha, _ => by cases ha
  | x :: l, ha, hb => by
    rw [List.idxOf_cons, List.idxOf_cons]
    by_cases ea : x = a
    · subst ea
      have e1 : (x == x) = true := by simp
      have e2 : (x == b) = false := by simpa using hab
      rw [e1, e2]; simp
    · have ea' : (x == a) = false := by simpa using ea
      by_cases eb : x = b
      · subst eb
        have e1 : (x == x) = true := by simp
        rw [ea', e1]; simp
      · have eb' : (x == b) = false := by simpa using eb
        have ha' : a ∈ l := by
          rcases List.mem_cons.mp ha with h | h
          · exact absurd h.symm ea
          · exact h
        have hb' : b ∈ l := by
          rcases List.mem_cons.mp hb with h | h
          · exact absurd h.symm eb
          · exact h
        have := idxOf_ne a b hab l ha' hb'
        rw [ea', eb']
        simp only [cond_false]
        intro h; exact this (by omega)

theorem idxOf_map_pm (g : Nat) (hg : g < 6) (v : Nat) (hv : v < 8) : ∀ l : List Nat,
    (∀ x, x ∈ l → x < 8) → (l.map (pm g)).idxOf (pm g v) = l.idxOf v
  | [], _ => rfl
  | x :: l, h => by
    have ih := idxOf_map_pm g hg v hv l fun y hy => h y (List.mem_cons_of_mem _ hy)
    have hx := h x List.mem_cons_self
    have e : (pm g x == pm g v) = (x == v) := by
      rw [Bool.eq_iff_iff]; simp only [beq_iff_eq]
      exact ⟨pm_inj g hg x hx v hv, fun e => by rw [e]⟩
    show ((pm g x) :: l.map (pm g)).idxOf (pm g v) = _
    rw [List.idxOf_cons, List.idxOf_cons, e, ih]

theorem pos_pm (g : Nat) (hg : g < 6) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (v : Nat) (hv : v < 8) :
    pos (fun j => pm g (σ j)) (pm g v) = pos σ v := by
  unfold pos
  have e : slots.map (fun j => pm g (σ j)) = (slots.map σ).map (pm g) := by
    rw [List.map_map]; rfl
  rw [e]
  exact idxOf_map_pm g hg v hv _ fun x hx => by
    obtain ⟨k, _, e⟩ := List.mem_map.mp hx
    rw [← e]; exact hσ k

/-- representative selector: first occurrences of the supports 1, 2, 4 in increasing order. -/
def rsel (σ : Nat → Nat) : Int := if pos σ 1 < pos σ 2 ∧ pos σ 2 < pos σ 4 then 1 else 0

theorem six_orders (a b c : Nat) (h1 : a ≠ b) (h2 : a ≠ c) (h3 : b ≠ c) :
    (if a < b ∧ b < c then (1 : Int) else 0) +
    (if b < a ∧ a < c then (1 : Int) else 0) +
    (if c < b ∧ b < a then (1 : Int) else 0) +
    (if a < c ∧ c < b then (1 : Int) else 0) +
    (if c < a ∧ a < b then (1 : Int) else 0) +
    (if b < c ∧ c < a then (1 : Int) else 0) = 1 := by
  repeat' split
  all_goals omega

/-- exactly one of the six permuted skeletons is a representative. -/
theorem rsum_one (σ : Nat → Nat) (hσ : ∀ k, σ k < 8)
    (h : (Ks σ 1).length = 4 ∧ (Ks σ 2).length = 4 ∧ (Ks σ 4).length = 4) :
    rsel (fun j => pm 0 (σ j)) + rsel (fun j => pm 1 (σ j)) + rsel (fun j => pm 2 (σ j)) +
    rsel (fun j => pm 3 (σ j)) + rsel (fun j => pm 4 (σ j)) + rsel (fun j => pm 5 (σ j)) = 1 := by
  have m1 := mem_of_len4 σ 1 h.1
  have m2 := mem_of_len4 σ 2 h.2.1
  have m4 := mem_of_len4 σ 4 h.2.2
  have n12 : pos σ 1 ≠ pos σ 2 := idxOf_ne 1 2 (by omega) _ m1 m2
  have n14 : pos σ 1 ≠ pos σ 4 := idxOf_ne 1 4 (by omega) _ m1 m4
  have n24 : pos σ 2 ≠ pos σ 4 := idxOf_ne 2 4 (by omega) _ m2 m4
  have p := fun g hg v hv => pos_pm g hg σ hσ v hv
  have a01 : pos (fun j => pm 0 (σ j)) 1 = pos σ 1 := by
    have h := p 0 (by omega) 1 (by omega)
    rw [show pm 0 1 = 1 from by decide] at h
    exact h
  have a02 : pos (fun j => pm 0 (σ j)) 2 = pos σ 2 := by
    have h := p 0 (by omega) 2 (by omega)
    rw [show pm 0 2 = 2 from by decide] at h
    exact h
  have a04 : pos (fun j => pm 0 (σ j)) 4 = pos σ 4 := by
    have h := p 0 (by omega) 4 (by omega)
    rw [show pm 0 4 = 4 from by decide] at h
    exact h
  have a11 : pos (fun j => pm 1 (σ j)) 1 = pos σ 2 := by
    have h := p 1 (by omega) 2 (by omega)
    rw [show pm 1 2 = 1 from by decide] at h
    exact h
  have a12 : pos (fun j => pm 1 (σ j)) 2 = pos σ 1 := by
    have h := p 1 (by omega) 1 (by omega)
    rw [show pm 1 1 = 2 from by decide] at h
    exact h
  have a14 : pos (fun j => pm 1 (σ j)) 4 = pos σ 4 := by
    have h := p 1 (by omega) 4 (by omega)
    rw [show pm 1 4 = 4 from by decide] at h
    exact h
  have a21 : pos (fun j => pm 2 (σ j)) 1 = pos σ 4 := by
    have h := p 2 (by omega) 4 (by omega)
    rw [show pm 2 4 = 1 from by decide] at h
    exact h
  have a22 : pos (fun j => pm 2 (σ j)) 2 = pos σ 2 := by
    have h := p 2 (by omega) 2 (by omega)
    rw [show pm 2 2 = 2 from by decide] at h
    exact h
  have a24 : pos (fun j => pm 2 (σ j)) 4 = pos σ 1 := by
    have h := p 2 (by omega) 1 (by omega)
    rw [show pm 2 1 = 4 from by decide] at h
    exact h
  have a31 : pos (fun j => pm 3 (σ j)) 1 = pos σ 1 := by
    have h := p 3 (by omega) 1 (by omega)
    rw [show pm 3 1 = 1 from by decide] at h
    exact h
  have a32 : pos (fun j => pm 3 (σ j)) 2 = pos σ 4 := by
    have h := p 3 (by omega) 4 (by omega)
    rw [show pm 3 4 = 2 from by decide] at h
    exact h
  have a34 : pos (fun j => pm 3 (σ j)) 4 = pos σ 2 := by
    have h := p 3 (by omega) 2 (by omega)
    rw [show pm 3 2 = 4 from by decide] at h
    exact h
  have a41 : pos (fun j => pm 4 (σ j)) 1 = pos σ 4 := by
    have h := p 4 (by omega) 4 (by omega)
    rw [show pm 4 4 = 1 from by decide] at h
    exact h
  have a42 : pos (fun j => pm 4 (σ j)) 2 = pos σ 1 := by
    have h := p 4 (by omega) 1 (by omega)
    rw [show pm 4 1 = 2 from by decide] at h
    exact h
  have a44 : pos (fun j => pm 4 (σ j)) 4 = pos σ 2 := by
    have h := p 4 (by omega) 2 (by omega)
    rw [show pm 4 2 = 4 from by decide] at h
    exact h
  have a51 : pos (fun j => pm 5 (σ j)) 1 = pos σ 2 := by
    have h := p 5 (by omega) 2 (by omega)
    rw [show pm 5 2 = 1 from by decide] at h
    exact h
  have a52 : pos (fun j => pm 5 (σ j)) 2 = pos σ 4 := by
    have h := p 5 (by omega) 4 (by omega)
    rw [show pm 5 4 = 2 from by decide] at h
    exact h
  have a54 : pos (fun j => pm 5 (σ j)) 4 = pos σ 1 := by
    have h := p 5 (by omega) 1 (by omega)
    rw [show pm 5 1 = 4 from by decide] at h
    exact h
  unfold rsel
  rw [a01, a02, a04, a11, a12, a14, a21, a22, a24, a31, a32, a34, a41, a42, a44, a51, a52, a54]
  exact six_orders _ _ _ n12 n14 n24

/- ---------- the theorem ---------- -/

theorem cell_six (k d : Nat) :
    ((cellV2 k d : Nat) : Int) =
      6 * sumOver slots (fun σ => Gs k d σ * rsel σ) (fun _ => 0) := by
  rw [cell_eq]
  have hpt : ∀ σ : Asg, (∀ j, σ j < 8) → Gs k d σ =
      Gs k d (fun j => pm 0 (σ j)) * rsel (fun j => pm 0 (σ j)) +
      Gs k d (fun j => pm 1 (σ j)) * rsel (fun j => pm 1 (σ j)) +
      Gs k d (fun j => pm 2 (σ j)) * rsel (fun j => pm 2 (σ j)) +
      Gs k d (fun j => pm 3 (σ j)) * rsel (fun j => pm 3 (σ j)) +
      Gs k d (fun j => pm 4 (σ j)) * rsel (fun j => pm 4 (σ j)) +
      Gs k d (fun j => pm 5 (σ j)) * rsel (fun j => pm 5 (σ j)) := by
    intro σ hσ
    rw [Gs_pm 0 (by omega) k d σ hσ, Gs_pm 1 (by omega) k d σ hσ, Gs_pm 2 (by omega) k d σ hσ,
      Gs_pm 3 (by omega) k d σ hσ, Gs_pm 4 (by omega) k d σ hσ, Gs_pm 5 (by omega) k d σ hσ]
    by_cases h : (Ks σ 1).length = 4 ∧ (Ks σ 2).length = 4 ∧ (Ks σ 4).length = 4
    · have r1 := rsum_one σ hσ h
      rw [← Int.mul_add, ← Int.mul_add, ← Int.mul_add, ← Int.mul_add, ← Int.mul_add, r1,
        Int.mul_one]
    · rw [Gs_zero_bad k d σ hσ h]; simp
  have hone : ∀ g, g < 6 →
      sumOver slots (fun σ => Gs k d (fun j => pm g (σ j)) * rsel (fun j => pm g (σ j)))
        (fun _ => 0) = sumOver slots (fun σ => Gs k d σ * rsel σ) (fun _ => 0) := by
    intro g hg
    rw [sumOver_pm g hg slots (fun σ => Gs k d σ * rsel σ) (fun _ => 0)]
    have z : (fun _ : Nat => pm g 0) = fun _ => 0 := by funext _; exact pm_0 g hg
    rw [z]
  rw [sumOver_congr_bd slots _ _ (fun _ => 0) (fun σ hb ho => hpt σ (fun j => by
    by_cases hj : j ∈ slots
    · exact hb j hj
    · rw [ho j hj]; omega))]
  rw [sumOver_add, sumOver_add, sumOver_add, sumOver_add, sumOver_add,
    hone 0 (by omega), hone 1 (by omega), hone 2 (by omega), hone 3 (by omega), hone 4 (by omega),
    hone 5 (by omega)]
  omega

/-- **The main theorem (abstract count).** Every V2 cell of the n=31 superspace
    C1 ∩ C2 ∩ C4 ∩ C5, as defined in §2 over KingWen.lean's `c1ok`, `c4ok`,
    `c5ok`, `transitions`, is divisible by 2^21 * 3. -/
theorem cellV2_dvd : CellV2Dvd := by
  intro k d
  have h : ((2 ^ 20 : Nat) : Int) ∣ sumOver slots (fun σ => Gs k d σ * rsel σ) (fun _ => 0) := by
    apply sumOver_dvd_bd
    intro σ hb ho
    exact Int.dvd_trans (Gs_dvd k d σ (fun j => by
      by_cases hj : j ∈ slots
      · exact hb j hj
      · rw [ho j hj]; omega)) (Int.dvd_mul_right _ _)
  obtain ⟨q, hq⟩ := h
  apply Int.natCast_dvd_natCast.mp
  rw [cell_six, hq]
  refine ⟨q, ?_⟩
  have e0 : (2 ^ 21 * 3 : Nat) = 6 * 2 ^ 20 := by rw [Nat.pow_succ]
  have e : ((2 ^ 21 * 3 : Nat) : Int) = 6 * ((2 ^ 20 : Nat) : Int) := by
    rw [e0, Int.natCast_mul]; rfl
  rw [e, Int.mul_assoc]

theorem bclass_31 (l : List Nat) (hl : l.length = 64) : bclass l 31 = 0 := by
  unfold bclass transitions
  rw [List.getD_eq_getElem?_getD, List.getElem?_eq_none (by simp [hl])]; rfl

/-- the total is the cell (31, 0): there is no boundary 31, and `bclass` then reads 0. -/
theorem superCount_eq : superCount = cellV2 31 0 := by
  have e : (seqs 64).filter (fun l => isSuper l && bclass l 31 == 0) = (seqs 64).filter isSuper :=
    List.filter_congr (fun l hl => by rw [bclass_31 l (mem_seqs_len 64 l hl)]; simp)
  unfold superCount cellV2
  rw [e]

theorem superCount_dvd : SuperCountDvd := by
  show 2 ^ 21 * 3 ∣ superCount
  rw [superCount_eq]; exact cellV2_dvd 31 0

/-! ## §25  controls: non-vacuity -/

/-
  §25 — controls for the V2 theorem (kernel-checked).

    * `mem_seqs`      — `seqs n` really is "all lists of length n over 0..63";
    * `kw_cell_pos`   — the theorem is not vacuous: King Wen itself lies in the V2 cell (0, 2),
                        so that cell is positive, hence (`kw_cell_ge`) at least 2^21 * 3;
    * `superCount_pos`, `superCount_ge` — the same for the total.
-/

theorem mem_seqs_of : ∀ l : List Nat, (∀ x, x ∈ l → x < 64) → l ∈ seqs l.length
  | [], _ => by simp [seqs]
  | x :: l, h => by
    have ih := mem_seqs_of l fun y hy => h y (List.mem_cons_of_mem _ hy)
    show x :: l ∈ (seqs l.length).flatMap fun l' => (List.range 64).map (· :: l')
    rw [List.mem_flatMap]
    exact ⟨l, ih, List.mem_map.mpr ⟨x, List.mem_range.mpr (h x List.mem_cons_self), rfl⟩⟩

theorem seqs_lt : ∀ n l, l ∈ seqs n → ∀ x, x ∈ l → x < 64 := by
  intro n
  induction n with
  | zero => intro l h x hx; simp [seqs] at h; subst h; cases hx
  | succ n ih =>
    intro l h x hx
    simp only [seqs, List.mem_flatMap, List.mem_map] at h
    obtain ⟨l', hl', y, hy, e⟩ := h
    subst e
    rcases List.mem_cons.mp hx with e | e
    · rw [e]; exact List.mem_range.mp hy
    · exact ih l' hl' x e

/-- `seqs n` is exactly the lists of length n over 0..63. -/
theorem mem_seqs (n : Nat) (l : List Nat) : l ∈ seqs n ↔ (l.length = n ∧ ∀ x, x ∈ l → x < 64) :=
  ⟨fun h => ⟨mem_seqs_len n l h, seqs_lt n l h⟩, fun ⟨h1, h2⟩ => h1 ▸ mem_seqs_of l h2⟩

theorem kw_mem : KW ∈ seqs 64 :=
  (mem_seqs 64 KW).mpr ⟨by decide, by decide⟩

theorem kw_bclass0 : bclass KW 0 = 2 := by decide +kernel

/-- NON-VACUITY: the V2 cell (0, 2) contains King Wen. -/
theorem kw_cell_pos : 0 < cellV2 0 2 := by
  unfold cellV2
  apply List.length_pos_of_mem (a := KW)
  rw [List.mem_filter]
  exact ⟨kw_mem, by rw [kw_isSuper, kw_bclass0]; rfl⟩

theorem kw_cell_ge : 2 ^ 21 * 3 ≤ cellV2 0 2 :=
  Nat.le_of_dvd kw_cell_pos (cellV2_dvd 0 2)

theorem superCount_pos : 0 < superCount := by
  unfold superCount
  apply List.length_pos_of_mem (a := KW)
  rw [List.mem_filter]
  exact ⟨kw_mem, kw_isSuper⟩

theorem superCount_ge : 2 ^ 21 * 3 ≤ superCount :=
  Nat.le_of_dvd superCount_pos superCount_dvd

/-! ## §26  the cardinality reading -/

/-
  §26 — the cardinality reading of the V2 theorem.

    * `seqs_nodup`          — `seqs n` lists every sequence exactly once, so `cellV2 k d` (the
                              length of a filtered `seqs 64`) is the NUMBER of sequences in the cell;
    * `cellV2_card_dvd` — any duplicate-free list whose members are exactly the superspace
                              sequences with class d at boundary k has length divisible by 2^21 * 3.
-/

theorem seqs_nodup : ∀ n, (seqs n).Nodup := by
  intro n
  induction n with
  | zero => simp [seqs]
  | succ n ih =>
    show ((seqs n).flatMap fun l => (List.range 64).map (· :: l)).Pairwise (· ≠ ·)
    rw [List.pairwise_flatMap]
    refine ⟨fun l _ => ?_, ?_⟩
    · exact List.Pairwise.map _ (fun a b hab e => hab (List.cons.inj e).1) List.nodup_range
    · exact List.Pairwise.imp (fun {l1 l2} hne x hx y hy e => by
        obtain ⟨a, _, ea⟩ := List.mem_map.mp hx
        obtain ⟨b, _, eb⟩ := List.mem_map.mp hy
        rw [← ea, ← eb] at e
        exact hne (List.cons.inj e).2) ih

/-- a duplicate-free list contained in another is no longer than it. -/
theorem nodup_len_le : ∀ (A B : List (List Nat)), A.Nodup → (∀ a, a ∈ A → a ∈ B) →
    A.length ≤ B.length
  | [], _, _, _ => Nat.zero_le _
  | a :: A, B, hA, hsub => by
    have ha := (List.nodup_cons.mp hA).1
    have hA' := (List.nodup_cons.mp hA).2
    have haB := hsub a List.mem_cons_self
    have ih := nodup_len_le A (B.erase a) hA' (fun x hx => by
      have hxa : x ≠ a := fun e => ha (e ▸ hx)
      exact (List.mem_erase_of_ne hxa).mpr (hsub x (List.mem_cons_of_mem _ hx)))
    rw [List.length_erase_of_mem haB] at ih
    have : 0 < B.length := List.length_pos_of_mem haB
    show A.length + 1 ≤ B.length
    omega

/-- **the V2 theorem as a statement about cardinalities** (no reference to `seqs`). -/
theorem cellV2_card_dvd : CellV2CardDvd := by
  intro k d L hL hmem
  have hF : ((seqs 64).filter fun l => isSuper l && bclass l k == d).Nodup :=
    List.Pairwise.filter _ (seqs_nodup 64)
  have hm : ∀ l, l ∈ L ↔ l ∈ (seqs 64).filter fun l => isSuper l && bclass l k == d := by
    intro l
    rw [hmem l, List.mem_filter, mem_seqs, Bool.and_eq_true, beq_iff_eq]
    constructor
    · rintro ⟨a, b, c, e⟩; exact ⟨⟨a, b⟩, c, e⟩
    · rintro ⟨⟨a, b⟩, c, e⟩; exact ⟨a, b, c, e⟩
  have e : L.length = cellV2 k d :=
    Nat.le_antisymm (nodup_len_le L _ hL fun a ha => (hm a).mp ha)
      (nodup_len_le _ L hF fun a ha => (hm a).mpr ha)
  rw [e]; exact cellV2_dvd k d

/-! ## §27  the skeleton-fibre form, for sequences -/

/-
  §27 — the skeleton-fibre form of the theorem, for sequences.

      theorem fibre_dvd : FibreDvd       -- forall sigma c : List Nat, 2^20 | fibre sigma c

  `fibre sigma c` counts the superspace sequences with support skeleton sigma and boundary class
  sequence c.  The V2 theorem (§24) does not use this part: it goes through
  `cell_eq`.  The proof here is the same reduction (C1, C4, entries as (support, coordinate)),
  followed by the coordinate-model theorem `fibreC_dvd`.
-/

theorem supp_hexof : ∀ s < 8, ∀ v < 8, supp (hexof s v) = s := by decide

theorem listFrom_getD (a : Nat → Nat) (d : Nat) : ∀ m j i, i < m →
    (listFrom a j m).getD i d = a (j + i) := by
  intro m
  induction m with
  | zero => intro j i h; omega
  | succ m ih =>
    intro j i h
    cases i with
    | zero => rfl
    | succ i =>
      show (a j :: listFrom a (j+1) m).getD (i+1) d = a (j + (i+1))
      rw [List.getD_cons_succ, ih (j+1) i (by omega)]
      congr 1; omega

theorem LL_length (σ : Nat → Nat) (t : Asg) : (LL σ t).length = 64 := by
  unfold LL; rw [length_pairs, length_listFrom]

theorem LL_bclass (σ : Nat → Nat) (t : Asg) (k : Nat) :
    bclass (LL σ t) k = bk (clsAt σ t) k := by
  have hbl : bl (listFrom (entry σ t) 0 32) = (List.range 31).map (clsAt σ t) := by
    rw [bl_listFrom (entry σ t) 31 0, listFrom_eq_map, List.range_eq_range']
    rfl
  unfold bclass LL
  rw [tr_getD, hbl, map_range_getD]; rfl

theorem LL_bseq (σ : Nat → Nat) (t : Asg) : bseq (LL σ t) = (List.range 31).map (clsAt σ t) := by
  unfold bseq
  apply List.map_congr_left
  intro k hk
  rw [LL_bclass, bk, if_pos (List.mem_range.mp hk)]

theorem LL_skel (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (t : Asg) :
    skel (LL σ t) = (List.range 32).map (sg σ) := by
  unfold skel
  apply List.map_congr_left
  intro i hi
  have hi32 : i < 32 := List.mem_range.mp hi
  have h := (pairs_getD 0 (listFrom (entry σ t) 0 32) i (by rw [length_listFrom]; exact hi32)).1
  show supp ((pairs (listFrom (entry σ t) 0 32)).getD (2 * i) 0) = sg σ i
  rw [h, listFrom_getD _ 0 32 0 i hi32, Nat.zero_add, entry_gen]
  apply supp_hexof
  · exact sg_lt σ hσ i
  · split
    · omega
    · exact Nat.mod_lt _ (by omega)

theorem LL_super (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (t : Asg) :
    isSuper (LL σ t) = (distinctOK σ t && budgetOK (clsAt σ t)) := by
  have h := super_char σ hσ t 31 0
  rw [bclass_31 _ (LL_length σ t)] at h
  have e : bk (clsAt σ t) 31 = 0 := by simp [bk]
  rw [e] at h
  simpa using h

theorem list_eq_map_getD (c : List Nat) (n : Nat) (h : c.length = n) :
    c = (List.range n).map (fun j => c.getD j 0) := by
  apply List.ext_getElem
  · simp [h]
  · intro i h1 h2
    simp [List.getD_eq_getElem?_getD, List.getElem?_eq_getElem h1]

/-- one sequence: the indicator of a skeleton fibre is a 0/1 factor (depending on the skeleton
    only) times the coordinate-model weight. -/
theorem fibre_point (σl c : List Nat) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (t : Asg) :
    (if (isSuper (LL σ t) && skel (LL σ t) == σl && bseq (LL σ t) == c) then (1 : Int) else 0) =
      (if ((List.range 32).map (sg σ) == σl && budgetOK (fun j => c.getD j 0) && c.length == 31)
        then 1 else 0) * W σ (fun j => c.getD j 0) t := by
  rw [LL_super σ hσ, LL_skel σ hσ, LL_bseq]
  by_cases hlen : c.length = 31
  · have hc := list_eq_map_getD c 31 hlen
    have hA : ((List.range 31).map (clsAt σ t) == c) =
        ((List.range 31).all fun k => clsAt σ t k == c.getD k 0) := by
      rw [Bool.eq_iff_iff, beq_iff_eq, List.all_eq_true]
      constructor
      · intro e k hk
        have := List.map_inj_left.mp (e.trans hc) k hk
        simpa using this
      · intro h
        rw [hc]
        apply List.map_congr_left
        intro k hk
        have := h k hk
        rw [beq_iff_eq] at this
        rw [this]
    have hl : (c.length == 31) = true := by simpa using hlen
    unfold W
    rw [hA, hl]
    cases hall : ((List.range 31).all fun k => clsAt σ t k == c.getD k 0) with
    | false => cases distinctOK σ t <;> cases budgetOK (clsAt σ t) <;>
        cases ((List.range 32).map (sg σ) == σl) <;> cases budgetOK (fun j => c.getD j 0) <;> rfl
    | true =>
      have hm : (List.range 31).map (clsAt σ t) = (List.range 31).map (fun j => c.getD j 0) :=
        List.map_congr_left fun k hk => by
          have := List.all_eq_true.mp hall k hk
          simpa using this
      have hb : budgetOK (clsAt σ t) = budgetOK (fun j => c.getD j 0) := by
        simp only [budgetOK, hm]
      rw [hb]
      cases distinctOK σ t <;> cases budgetOK (fun j => c.getD j 0) <;>
        cases ((List.range 32).map (sg σ) == σl) <;> rfl
  · have hA : ((List.range 31).map (clsAt σ t) == c) = false := by
      cases hv : ((List.range 31).map (clsAt σ t) == c) with
      | false => rfl
      | true =>
        exfalso; apply hlen
        rw [← beq_iff_eq.mp hv]; simp
    have hl : (c.length == 31) = false := by simpa using hlen
    rw [hA, hl]
    simp

/-- **Skeleton fibres of sequences.** Every fibre of the n=31 superspace over a support skeleton
    and a boundary class sequence has size divisible by 2^20. -/
theorem fibre_dvd : FibreDvd := by
  intro σl c
  apply Int.natCast_dvd_natCast.mp
  have s1 : ((fibre σl c : Nat) : Int) =
      lsum (seqs (2 * 32)) (fun l => if (isSuper l && skel l == σl && bseq l == c) then 1 else 0) :=
    filter_length _ _
  have s2 := C1sum 32 (fun l => if (isSuper l && skel l == σl && bseq l == c) then (1 : Int) else 0)
    (fun l hl hc => by
      cases hs : isSuper l with
      | false => simp
      | true =>
        exfalso
        have h1 : c1ok l = true := by
          simp only [isSuper, Bool.and_eq_true] at hs; exact hs.1.1.2
        rw [c1L_of_c1ok l hl h1] at hc; cases hc)
  have s3 : lsum (seqs (31+1)) (fun e => if (isSuper (pairs e) && skel (pairs e) == σl &&
        bseq (pairs e) == c) then (1 : Int) else 0) =
      lsum (seqs 31) (fun e => if (isSuper (pairs (63 :: e)) && skel (pairs (63 :: e)) == σl &&
        bseq (pairs (63 :: e)) == c) then (1 : Int) else 0) := by
    rw [S_succ]
    apply lsum_congr
    intro e _
    rw [lsum_congr (List.range 64) (g := fun x => if x = 63 then
        (if (isSuper (pairs (x :: e)) && skel (pairs (x :: e)) == σl && bseq (pairs (x :: e)) == c)
          then (1 : Int) else 0) else 0) (fun x _ => by
      by_cases ex : x = 63
      · rw [if_pos ex]
      · rw [if_neg ex]
        cases hs : isSuper (pairs (x :: e)) with
        | false => simp
        | true =>
          exfalso
          have h4 : c4ok (pairs (x :: e)) = true := by
            simp only [isSuper, Bool.and_eq_true] at hs; exact hs.1.2
          exact ex (c4_head x _ h4))]
    exact lsum_delta _ List.nodup_range 63 (List.mem_range.mpr (by omega)) _
  have s4 := Ssum 31 1 (fun e => if (isSuper (pairs (63 :: e)) && skel (pairs (63 :: e)) == σl &&
        bseq (pairs (63 :: e)) == c) then (1 : Int) else 0) (fun _ => 0) (fun _ => 0)
  rw [s1, s2]
  show _ ∣ lsum (seqs (31+1)) _
  rw [s3, s4]
  show _ ∣ sumOver slots _ _
  apply sumOver_dvd_bd
  intro σ hσb hσo
  have hσ : ∀ j, σ j < 8 := by
    intro j
    by_cases hj : j ∈ slots
    · exact hσb j hj
    · rw [hσo j hj]; omega
  have e : sumOver (List.range' 1 31) (fun t => if (isSuper (pairs (63 :: listFrom
        (fun i => hexof (σ i) (t i)) 1 31)) && skel (pairs (63 :: listFrom
        (fun i => hexof (σ i) (t i)) 1 31)) == σl && bseq (pairs (63 :: listFrom
        (fun i => hexof (σ i) (t i)) 1 31)) == c) then (1 : Int) else 0) (fun _ => 0) =
      (if ((List.range 32).map (sg σ) == σl && budgetOK (fun j => c.getD j 0) && c.length == 31)
        then 1 else 0) * fibreC σ (fun j => c.getD j 0) := by
    unfold fibreC
    rw [← sumOver_const_mul]
    apply sumOver_congr_bd
    intro t htb _
    have hL : pairs (63 :: listFrom (fun i => hexof (σ i) (t i)) 1 31) = LL σ t := by
      show _ = pairs (entry σ t 0 :: listFrom (entry σ t) 1 31)
      rw [entry_zero, listFrom_congr (fun i => hexof (σ i) (t i)) (entry σ t) 31 1 (fun i h1 h2 => by
        rw [entry_pos σ t i (by omega),
          Nat.mod_eq_of_lt (htb i ((mem_slots i).mpr ⟨h1, by omega⟩))])]
    rw [hL]
    exact fibre_point σl c σ hσ t
  show _ ∣ sumOver (List.range' 1 31) _ _
  rw [e]
  cases hb : budgetOK (fun j => c.getD j 0) with
  | false => simp
  | true => exact Int.dvd_trans (fibreC_dvd σ _ hσ hb) (Int.dvd_mul_left _ _)

/-- NON-VACUITY: King Wen's own skeleton fibre is not empty, hence has at least 2^20 members. -/
theorem kw_fibre_list_pos : 0 < fibre (skel KW) (bseq KW) := by
  unfold fibre
  apply List.length_pos_of_mem (a := KW)
  rw [List.mem_filter]
  exact ⟨kw_mem, by rw [kw_isSuper]; simp⟩

theorem kw_fibre_list_ge : 2 ^ 20 ≤ fibre (skel KW) (bseq KW) :=
  Nat.le_of_dvd kw_fibre_list_pos (fibre_dvd _ _)

/-! ## §28  THE PER-PAIR POSITIONAL COUNTS (V1): statements -/

/-
  §28 — the per-pair positional counts ("V1"), STATED.

  `cellV1 k h` is the number of superspace sequences whose pair in slot k+1 is the pair that
  contains the hexagram h (in either orientation). Slot 0 is the opening pair (63, 0), so the
  slots that vary are 1..31, i.e. k = 0..30; with 32 pairs that is the 31 x 32 table of
  (position, pair) counts. (The column of the opening pair {63, 0} is identically 0, since that
  pair sits in slot 0; that remark is true but is not a theorem of this file.)

    CellV1Dvd       proved in §33 (`cellV1_dvd`)        2^19      for every pair
    CellV1ComplDvd  proved in §33 (`cellV1_compl_dvd`)  2^21      for the self-reverse (complement) pairs
    CellV1TaiDvd    proved in §33 (`cellV1_tai_dvd`)    2^19 * 3  for the pair {7, 56}
    CellV1CardDvd   proved in §34 (`cellV1_card_dvd`)   the cardinality reading of the first

  As in §2 these are statements about the count DEFINED IN THIS FILE, and they say "divides".
-/

/-- V1 cell (k, h), k = 0..30: the pair in slot k+1 is the pair of hexagram h. -/
def cellV1 (k h : Nat) : Nat :=
  ((seqs 64).filter fun l => isSuper l && samePair (l.getD (2 * (k+1)) 99) h).length

/-- THE V1 THEOREM: every per-pair positional count is divisible by 2^19.
    Proved: `cellV1_dvd` (§33). -/
def CellV1Dvd : Prop := ∀ k h : Nat, k < 31 → h < 64 → 2 ^ 19 ∣ cellV1 k h

/-- for a complement pair (h a palindrome under reversal, i.e. `supp h = 0`) the count is
    divisible by 2^21.  Proved: `cellV1_compl_dvd` (§33). -/
def CellV1ComplDvd : Prop := ∀ k h : Nat, k < 31 → h < 64 → supp h = 0 → 2 ^ 21 ∣ cellV1 k h

/-- for the pair {7, 56} (the one pair besides the opening pair {63, 0} that all six coordinate
    permutations fix) the count is divisible by 2^19 * 3.  Proved: `cellV1_tai_dvd` (§33). -/
def CellV1TaiDvd : Prop := ∀ k h : Nat, k < 31 → (h = 7 ∨ h = 56) → 2 ^ 19 * 3 ∣ cellV1 k h

/-- The cardinality reading: ANY duplicate-free list L whose members are exactly the superspace
    sequences with the pair of h in slot k+1 has length divisible by 2^19.
    Proved: `cellV1_card_dvd` (§34). -/
def CellV1CardDvd : Prop := ∀ (k h : Nat) (L : List (List Nat)), k < 31 → h < 64 → L.Nodup →
  (∀ l, l ∈ L ↔ (l.length = 64 ∧ (∀ x ∈ l, x < 64) ∧ isSuper l = true ∧
    samePair (l.getD (2 * (k+1)) 99) h = true)) →
  2 ^ 19 ∣ L.length

/-! ## §29  V1: a pinned count as a sum of pinned fibres -/

/-
  §29 — Step 1 for a pinned count.

    * `count_eq`    — Step 1 of §23 for an arbitrary extra Boolean condition on the sequence
                      (the same reduction: C1, C4, entries as (support, coordinate));
    * `fibreP γ a`  — the coordinate-model fibre with the weight γ on the coordinate of slot a;
    * `cellV1_eq`   — a V1 cell is the sum over skeletons σ and class sequences c of the fibre
                      pinned by `pinI h (σ (k+1))` at slot k+1.
-/

/-- Step 1 (C1, C4, coordinates) for the superspace sequences that satisfy one more condition. -/
theorem count_eq (Pd : List Nat → Bool) :
    ((((seqs 64).filter fun l => isSuper l && Pd l).length : Nat) : Int) =
      sumOver slots (fun σ => sumOver slots (fun t =>
        if (isSuper (pairs (63 :: listFrom (fun i => hexof (σ i) (t i)) 1 31)) &&
            Pd (pairs (63 :: listFrom (fun i => hexof (σ i) (t i)) 1 31))) then (1 : Int) else 0)
        (fun _ => 0)) (fun _ => 0) := by
  have s1 : ((((seqs 64).filter fun l => isSuper l && Pd l).length : Nat) : Int) =
      lsum (seqs (2 * 32)) (fun l => if (isSuper l && Pd l) then 1 else 0) :=
    filter_length _ _
  have s2 := C1sum 32 (fun l => if (isSuper l && Pd l) then (1 : Int) else 0)
    (fun l hl hc => by
      cases hs : isSuper l with
      | false => simp
      | true =>
        exfalso
        have h1 : c1ok l = true := by
          simp only [isSuper, Bool.and_eq_true] at hs; exact hs.1.1.2
        rw [c1L_of_c1ok l hl h1] at hc; cases hc)
  have s3 : lsum (seqs (31+1)) (fun e => if (isSuper (pairs e) && Pd (pairs e))
        then (1 : Int) else 0) =
      lsum (seqs 31) (fun e => if (isSuper (pairs (63 :: e)) && Pd (pairs (63 :: e)))
        then (1 : Int) else 0) := by
    rw [S_succ]
    apply lsum_congr
    intro e _
    rw [lsum_congr (List.range 64) (g := fun x => if x = 63 then
        (if (isSuper (pairs (x :: e)) && Pd (pairs (x :: e))) then (1 : Int) else 0)
        else 0) (fun x _ => by
      by_cases ex : x = 63
      · rw [if_pos ex]
      · rw [if_neg ex]
        cases hs : isSuper (pairs (x :: e)) with
        | false => simp
        | true =>
          exfalso
          have h4 : c4ok (pairs (x :: e)) = true := by
            simp only [isSuper, Bool.and_eq_true] at hs; exact hs.1.2
          exact ex (c4_head x _ h4))]
    exact lsum_delta _ List.nodup_range 63 (List.mem_range.mpr (by omega)) _
  have s4 := Ssum 31 1 (fun e => if (isSuper (pairs (63 :: e)) && Pd (pairs (63 :: e)))
        then (1 : Int) else 0) (fun _ => 0) (fun _ => 0)
  rw [s1, s2]
  show lsum (seqs (31+1)) _ = _
  rw [s3, s4]
  rfl

/-- the 0/1 pin: the hexagram with coordinates (s, v) lies in the pair of h. -/
def pinI (h s v : Nat) : Int := if samePair (hexof s v) h then 1 else 0

/-- the coordinate-model fibre with a weight γ on the coordinate of slot a. -/
def fibreP (γ : Nat → Int) (a : Nat) (σ c : Nat → Nat) : Int :=
  sumOver slots (fun t => W σ c t * γ (t a % 8)) (fun _ => 0)

/-- the weighted fibres over one skeleton, summed over the class sequences with the budget. -/
def GsG (γ : Nat → Int) (a : Nat) (σ : Asg) : Int :=
  sumOver (List.range 31) (fun c => Bind 31 0 c * fibreP γ a σ c) (fun _ => 0)

/-- the part of the V1 cell (k, h) that lies over the skeleton sigma. -/
def GsP (k h : Nat) (σ : Asg) : Int := GsG (pinI h (σ (k+1))) (k+1) σ

theorem LL_getD (σ : Nat → Nat) (t : Asg) (i : Nat) (hi : i < 32) :
    (LL σ t).getD (2 * i) 99 = entry σ t i := by
  unfold LL
  rw [(pairs_getD 99 _ i (by rw [length_listFrom]; exact hi)).1, listFrom_eq_map,
    List.getD_eq_getElem?_getD, List.getElem?_map, List.getElem?_range' (by omega)]
  simp

/-- one sequence: the indicator of the V1 cell is a sum over class sequences of B(c) * W * pin. -/
theorem point_eq_V1 (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (t : Asg) (k h : Nat) (hk : k < 31) :
    (if (isSuper (LL σ t) && samePair ((LL σ t).getD (2 * (k+1)) 99) h) then (1 : Int) else 0) =
      sumOver (List.range 31)
        (fun c => Bind 31 0 c * (W σ c t * pinI h (σ (k+1)) (t (k+1) % 8))) (fun _ => 0) := by
  have e1 : (LL σ t).getD (2 * (k+1)) 99 = hexof (σ (k+1)) (t (k+1) % 8) := by
    rw [LL_getD σ t (k+1) (by omega), entry_pos σ t (k+1) (by omega)]
  have e2 := point_eq σ hσ t 31 0
  rw [bclass_31 _ (LL_length σ t)] at e2
  have e3 : sumOver (List.range 31)
      (fun c => Bind 31 0 c * (W σ c t * pinI h (σ (k+1)) (t (k+1) % 8))) (fun _ => 0) =
      pinI h (σ (k+1)) (t (k+1) % 8) *
        sumOver (List.range 31) (fun c => Bind 31 0 c * W σ c t) (fun _ => 0) := by
    rw [← sumOver_const_mul]
    exact sumOver_congr _ (fun c => by ac_rfl) _
  rw [e3, ← e2, e1]
  unfold pinI
  cases isSuper (LL σ t) <;> cases samePair (hexof (σ (k+1)) (t (k+1) % 8)) h <;> simp

/-- **Step 1 for a V1 cell**: the abstract count is a sum of pinned coordinate-model fibres. -/
theorem cellV1_eq (k h : Nat) (hk : k < 31) :
    ((cellV1 k h : Nat) : Int) = sumOver slots (GsP k h) (fun _ => 0) := by
  have s : ((cellV1 k h : Nat) : Int) =
      sumOver slots (fun σ => sumOver slots (fun t =>
        if (isSuper (pairs (63 :: listFrom (fun i => hexof (σ i) (t i)) 1 31)) &&
            samePair ((pairs (63 :: listFrom (fun i => hexof (σ i) (t i)) 1 31)).getD
              (2 * (k+1)) 99) h) then (1 : Int) else 0)
        (fun _ => 0)) (fun _ => 0) :=
    count_eq (fun l => samePair (l.getD (2 * (k+1)) 99) h)
  rw [s]
  apply sumOver_congr_bd
  intro σ hσb hσo
  have hσ : ∀ j, σ j < 8 := by
    intro j
    by_cases hj : j ∈ slots
    · exact hσb j hj
    · rw [hσo j hj]; omega
  show sumOver slots _ _ = sumOver (List.range 31)
    (fun c => Bind 31 0 c * fibreP (pinI h (σ (k+1))) (k+1) σ c) (fun _ => 0)
  have e6 : sumOver (List.range 31)
      (fun c => Bind 31 0 c * fibreP (pinI h (σ (k+1))) (k+1) σ c) (fun _ => 0) =
      sumOver slots (fun t => sumOver (List.range 31)
        (fun c => Bind 31 0 c * (W σ c t * pinI h (σ (k+1)) (t (k+1) % 8))) (fun _ => 0))
        (fun _ => 0) := by
    rw [sumOver_comm2]
    apply sumOver_congr
    intro c
    exact (sumOver_const_mul slots (Bind 31 0 c)
      (fun t => W σ c t * pinI h (σ (k+1)) (t (k+1) % 8)) (fun _ => 0)).symm
  rw [e6]
  apply sumOver_congr_bd
  intro t htb _
  have hL : pairs (63 :: listFrom (fun i => hexof (σ i) (t i)) 1 31) = LL σ t := by
    show _ = pairs (entry σ t 0 :: listFrom (entry σ t) 1 31)
    rw [entry_zero, listFrom_congr (fun i => hexof (σ i) (t i)) (entry σ t) 31 1 (fun i h1 h2 => by
      rw [entry_pos σ t i (by omega),
        Nat.mod_eq_of_lt (htb i ((mem_slots i).mpr ⟨h1, by omega⟩))])]
  rw [hL]
  exact point_eq_V1 σ hσ t k h hk

/-! ## §30  V1: the pinned fibre theorem -/

/-
  §30 — the coordinate-model fibre theorem with a one-slot weight.

  §19 proves more than `fibreC_dvd` states: every character-twisted sum of the fibre indicator
  is divisible by 2^(22 - b1) (`TwDiv`). By `twdiv_slot`, a weight γ on one slot whose Walsh
  coefficients are all divisible by 2^m turns a divisor 2^n of these sums into 2^(n + m - 3):

      2^(22 - b1 + m - 3)  divides  fibreP γ a σ c.

  For King Wen's budget (b1 = 2) that is 2^(17 + m). No new table is needed.
-/

theorem fibre_main_pin (σ c : Nat → Nat) (hσ : ∀ k, σ k < 8)
    (hc : ∀ k, k < 31 → c k ∈ [1, 2, 3, 4, 6])
    (b1 : Nat) (hw : sumN (fun k => wcls (c k)) 31 = 31 + b1) (hperm : (KA σ).Perm slots)
    (l0 : (Ks σ 0).length = 3) (l4 : ∀ s, 1 ≤ s → s < 8 → (Ks σ s).length = 4)
    (γ : Nat → Int) (m : Nat) (hγ : ∀ w, ((2 ^ m : Nat) : Int) ∣ sum8 fun v => γ v * chi' w v)
    (a : Nat) (ha1 : 1 ≤ a) (ha : a ≤ 31) :
    ((2 ^ (22 - b1 + m - 3) : Nat) : Int) ∣ fibreP γ a σ c := by
  have G : Good σ := ⟨hσ, fun s h1 h8 => Q4_of_len σ s (l4 s h1 h8), Q3_of_len σ l0⟩
  have hc0 : ∀ k, k < 31 → c k ≠ 0 := by
    intro k hk e
    have := hc k hk
    rw [e] at this
    simp at this
  have hN : (KA σ).Nodup := hperm.nodup_iff.mpr List.nodup_range'
  have hmem : ∀ k, 1 ≤ k → k ≤ 31 → k ∈ KA σ := fun k h1 h2 =>
    hperm.mem_iff.mpr ((mem_slots k).mpr ⟨h1, h2⟩)
  have H0 : TwDiv (KA σ) (GG σ c 0) (EE σ c 0) :=
    twdiv_blocks (Ks σ) (Phi σ c) (mu σ c) 8
      (fun s hs => by
        by_cases e : s = 0
        · subst e; exact phi_twdiv_C σ c l0
        · exact phi_twdiv_R σ c s (by omega) hs (l4 s (by omega) hs))
      (fun s hs k hk => by
        by_cases e : s = 0
        · subst e; exact phi_indep σ c 0 k (Or.inl ⟨rfl, l0⟩) hk
        · exact phi_indep σ c s k (Or.inr ⟨e, l4 s (by omega) hs⟩) hk)
      (fun s _ s' _ k hk hk' => by
        have a := ((mem_Ks σ s k).mp hk).2.2
        have b := ((mem_Ks σ s' k).mp hk').2.2
        omega)
  have H := fold_twdiv σ c hσ hc hN hmem H0 31 (Nat.le_refl _)
  have H' := twdiv_mono _ _ (22 - b1) _ (EE_ge σ c G b1 hw) H
  have T := twdiv_slot (KA σ) hN a (hmem a ha1 ha) γ m hγ (GG σ c 31) (22 - b1) H'
  have hd := twdiv_count _ _ _ T (fun _ => 0)
  rw [sumOver_perm hperm] at hd
  have e : fibreP γ a σ c = sumOver slots (fun t => GG σ c 31 t * γ (t a % 8)) (fun _ => 0) :=
    sumOver_congr _ (fun t => by rw [W_eq σ c G hc0 t]) _
  rw [e]; exact hd

/-- **General-budget form, pinned.** -/
theorem fibreP_dvd_general (σ c : Nat → Nat) (hσ : ∀ k, σ k < 8)
    (hc : ∀ k, k < 31 → c k ∈ [1, 2, 3, 4, 6])
    (γ : Nat → Int) (m : Nat) (hγ : ∀ w, ((2 ^ m : Nat) : Int) ∣ sum8 fun v => γ v * chi' w v)
    (a : Nat) (ha1 : 1 ≤ a) (ha : a ≤ 31) :
    ((2 ^ (22 - b1of c + m - 3) : Nat) : Int) ∣ fibreP γ a σ c := by
  have hw : sumN (fun k => wcls (c k)) 31 = 31 + b1of c := sumN_w c 31
  have hperm : (KA σ).Perm slots := catK_perm σ slots 8 (fun k _ => hσ k)
  have hlen : sumN (fun s => (Ks σ s).length) 8 = 31 := by
    have := hperm.length_eq
    rw [KA, catK_length] at this
    rw [this]; rfl
  simp only [sumN] at hlen
  have Z : (∀ t, W σ c t = 0) →
      ((2 ^ (22 - b1of c + m - 3) : Nat) : Int) ∣ fibreP γ a σ c := fun h =>
    sumOver_dvd _ _ _ (fun t => by rw [h t, Int.zero_mul]; exact Int.dvd_zero _) _
  by_cases h0 : 4 ≤ (Ks σ 0).length
  · exact Z (over_C σ c h0)
  by_cases h1 : 5 ≤ (Ks σ 1).length
  · exact Z (over_R σ c 1 (by omega) h1)
  by_cases h2 : 5 ≤ (Ks σ 2).length
  · exact Z (over_R σ c 2 (by omega) h2)
  by_cases h3 : 5 ≤ (Ks σ 3).length
  · exact Z (over_R σ c 3 (by omega) h3)
  by_cases h4 : 5 ≤ (Ks σ 4).length
  · exact Z (over_R σ c 4 (by omega) h4)
  by_cases h5 : 5 ≤ (Ks σ 5).length
  · exact Z (over_R σ c 5 (by omega) h5)
  by_cases h6 : 5 ≤ (Ks σ 6).length
  · exact Z (over_R σ c 6 (by omega) h6)
  by_cases h7 : 5 ≤ (Ks σ 7).length
  · exact Z (over_R σ c 7 (by omega) h7)
  refine fibre_main_pin σ c hσ hc (b1of c) hw hperm (by omega) (fun s hs1 hs8 => ?_) γ m hγ a ha1 ha
  have h8 : s = 1 ∨ s = 2 ∨ s = 3 ∨ s = 4 ∨ s = 5 ∨ s = 6 ∨ s = 7 := by omega
  rcases h8 with e | e | e | e | e | e | e <;> subst e <;> omega

/-- **The pinned fibre theorem.** For King Wen's budget, a one-slot weight whose Walsh
    coefficients are divisible by 2^m leaves 2^(17 + m). -/
theorem fibreP_dvd (σ c : Nat → Nat) (hσ : ∀ k, σ k < 8) (hb : budgetOK c = true)
    (γ : Nat → Int) (m : Nat) (hγ : ∀ w, ((2 ^ m : Nat) : Int) ∣ sum8 fun v => γ v * chi' w v)
    (a : Nat) (ha1 : 1 ≤ a) (ha : a ≤ 31) :
    ((2 ^ (17 + m) : Nat) : Int) ∣ fibreP γ a σ c := by
  have h := fibreP_dvd_general σ c hσ (budget_cls c hb) γ m hγ a ha1 ha
  have e : b1of c = 2 := by
    simp only [budgetOK, Bool.and_eq_true, beq_iff_eq] at hb
    exact hb.1.1.1.1
  have e2 : 22 - b1of c + m - 3 = 17 + m := by rw [e]; omega
  rw [e2] at h
  exact h

/-! ## §31  V1: the coordinate permutations move the pin -/

/-
  §31 — the six coordinate permutations act on hexagrams (`pmh`), and a pinned fibre over the
  permuted skeleton with the permuted pin is the pinned fibre over the original one
  (`fibreP_pm`). Summing over the six permutations and keeping one skeleton per orbit, as in
  §24, turns a V1 cell into a sum over representative skeletons of the fibre weighted by

      gamS h s v  =  the number of g among the six with (s, v) in the pair of `pmh g h`

  (`cellV1_six`, `HsP_eq`).
-/

/-- the g-th coordinate permutation acting on a hexagram. -/
def pmh (g h : Nat) : Nat := hexof (pm g (supp h)) (pm g (h % 8))

theorem pin_pm : ∀ g < 6, ∀ h < 64, ∀ s < 8, ∀ v < 8,
    samePair (hexof (pm g s) (pm g v)) (pmh g h) = samePair (hexof s v) h := by decide +kernel

theorem fibreP_pm (g : Nat) (hg : g < 6) (h : Nat) (hh : h < 64) (a : Nat) (σ : Nat → Nat)
    (hσ : ∀ k, σ k < 8) (c : Nat → Nat) :
    fibreP (pinI (pmh g h) (pm g (σ a))) a (fun j => pm g (σ j)) c =
      fibreP (pinI h (σ a)) a σ c := by
  unfold fibreP
  have e : sumOver slots (fun t => W σ c t * pinI h (σ a) (t a % 8)) (fun _ => 0) =
      sumOver slots
        (fun t => W (fun j => pm g (σ j)) c (fun j => pm g (t j)) *
          pinI (pmh g h) (pm g (σ a)) (pm g (t a) % 8)) (fun _ => 0) :=
    sumOver_congr _ (fun t => by
      rw [W_pm g hg σ hσ c t]
      have hlt : pm g (t a) < 8 := by
        rw [← pm_mod g (t a)]; exact pm_lt g hg _ (Nat.mod_lt _ (by omega))
      have e2 : pinI (pmh g h) (pm g (σ a)) (pm g (t a) % 8) = pinI h (σ a) (t a % 8) := by
        unfold pinI
        rw [Nat.mod_eq_of_lt hlt, ← pm_mod g (t a),
          pin_pm g hg h hh (σ a) (hσ a) (t a % 8) (Nat.mod_lt _ (by omega))]
      rw [e2]) _
  rw [e]
  have key := sumOver_pm g hg slots
    (fun t => W (fun j => pm g (σ j)) c t * pinI (pmh g h) (pm g (σ a)) (t a % 8)) (fun _ => 0)
  have z : (fun _ : Nat => pm g 0) = fun _ => 0 := by funext _; exact pm_0 g hg
  rw [z] at key
  exact key.symm

theorem GsP_pm (g : Nat) (hg : g < 6) (k h : Nat) (hh : h < 64) (σ : Nat → Nat)
    (hσ : ∀ k, σ k < 8) :
    GsP k (pmh g h) (fun j => pm g (σ j)) = GsP k h σ := by
  show GsG (pinI (pmh g h) (pm g (σ (k+1)))) (k+1) (fun j => pm g (σ j)) =
    GsG (pinI h (σ (k+1))) (k+1) σ
  unfold GsG
  exact sumOver_congr _ (fun c => by rw [fibreP_pm g hg h hh (k+1) σ hσ c]) _

theorem GsG_zero_bad (γ : Nat → Int) (a : Nat) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8)
    (h : ¬ ((Ks σ 1).length = 4 ∧ (Ks σ 2).length = 4 ∧ (Ks σ 4).length = 4)) :
    GsG γ a σ = 0 := by
  unfold GsG
  rw [sumOver_congr (List.range 31) (G := fun _ => 0) (fun c => by
    have : fibreP γ a σ c = 0 := by
      unfold fibreP
      rw [sumOver_congr _ (G := fun _ => 0)
        (fun t => by rw [W_zero_bad σ hσ h c t, Int.zero_mul]), sumOver_zero]
    rw [this, Int.mul_zero]), sumOver_zero]

/-- the parts over one skeleton of the six cells of the six images of the pair of h. -/
def HsP (k h : Nat) (σ : Asg) : Int :=
  GsP k (pmh 0 h) σ + GsP k (pmh 1 h) σ + GsP k (pmh 2 h) σ + GsP k (pmh 3 h) σ +
    GsP k (pmh 4 h) σ + GsP k (pmh 5 h) σ

/-- a V1 cell as a sum over representative skeletons (one per orbit of the six permutations). -/
theorem cellV1_six (k h : Nat) (hk : k < 31) (hh : h < 64) :
    ((cellV1 k h : Nat) : Int) = sumOver slots (fun σ => HsP k h σ * rsel σ) (fun _ => 0) := by
  rw [cellV1_eq k h hk]
  have hpt : ∀ σ : Asg, (∀ j, σ j < 8) → GsP k h σ =
      GsP k (pmh 0 h) (fun j => pm 0 (σ j)) * rsel (fun j => pm 0 (σ j)) +
      GsP k (pmh 1 h) (fun j => pm 1 (σ j)) * rsel (fun j => pm 1 (σ j)) +
      GsP k (pmh 2 h) (fun j => pm 2 (σ j)) * rsel (fun j => pm 2 (σ j)) +
      GsP k (pmh 3 h) (fun j => pm 3 (σ j)) * rsel (fun j => pm 3 (σ j)) +
      GsP k (pmh 4 h) (fun j => pm 4 (σ j)) * rsel (fun j => pm 4 (σ j)) +
      GsP k (pmh 5 h) (fun j => pm 5 (σ j)) * rsel (fun j => pm 5 (σ j)) := by
    intro σ hσ
    rw [GsP_pm 0 (by omega) k h hh σ hσ, GsP_pm 1 (by omega) k h hh σ hσ,
      GsP_pm 2 (by omega) k h hh σ hσ, GsP_pm 3 (by omega) k h hh σ hσ,
      GsP_pm 4 (by omega) k h hh σ hσ, GsP_pm 5 (by omega) k h hh σ hσ]
    by_cases hgood : (Ks σ 1).length = 4 ∧ (Ks σ 2).length = 4 ∧ (Ks σ 4).length = 4
    · have r1 := rsum_one σ hσ hgood
      rw [← Int.mul_add, ← Int.mul_add, ← Int.mul_add, ← Int.mul_add, ← Int.mul_add, r1,
        Int.mul_one]
    · have z : GsP k h σ = 0 := GsG_zero_bad _ _ σ hσ hgood
      rw [z]; simp
  have hone : ∀ g, g < 6 →
      sumOver slots (fun σ => GsP k (pmh g h) (fun j => pm g (σ j)) * rsel (fun j => pm g (σ j)))
        (fun _ => 0) = sumOver slots (fun σ => GsP k (pmh g h) σ * rsel σ) (fun _ => 0) := by
    intro g hg
    rw [sumOver_pm g hg slots (fun σ => GsP k (pmh g h) σ * rsel σ) (fun _ => 0)]
    have z : (fun _ : Nat => pm g 0) = fun _ => 0 := by funext _; exact pm_0 g hg
    rw [z]
  have eR : sumOver slots (fun σ => HsP k h σ * rsel σ) (fun _ => 0) =
      sumOver slots (fun σ => GsP k (pmh 0 h) σ * rsel σ) (fun _ => 0) +
      sumOver slots (fun σ => GsP k (pmh 1 h) σ * rsel σ) (fun _ => 0) +
      sumOver slots (fun σ => GsP k (pmh 2 h) σ * rsel σ) (fun _ => 0) +
      sumOver slots (fun σ => GsP k (pmh 3 h) σ * rsel σ) (fun _ => 0) +
      sumOver slots (fun σ => GsP k (pmh 4 h) σ * rsel σ) (fun _ => 0) +
      sumOver slots (fun σ => GsP k (pmh 5 h) σ * rsel σ) (fun _ => 0) := by
    rw [← sumOver_add, ← sumOver_add, ← sumOver_add, ← sumOver_add, ← sumOver_add]
    exact sumOver_congr _ (fun σ => by unfold HsP; simp only [Int.add_mul]) _
  rw [sumOver_congr_bd slots _ _ (fun _ => 0) (fun σ hb ho => hpt σ (fun j => by
    by_cases hj : j ∈ slots
    · exact hb j hj
    · rw [ho j hj]; omega))]
  rw [sumOver_add, sumOver_add, sumOver_add, sumOver_add, sumOver_add,
    hone 0 (by omega), hone 1 (by omega), hone 2 (by omega), hone 3 (by omega), hone 4 (by omega),
    hone 5 (by omega), eR]

/-- the orbit weight: how many of the six images of the pair of h contain the hexagram (s, v). -/
def gamS (h s v : Nat) : Int :=
  pinI (pmh 0 h) s v + pinI (pmh 1 h) s v + pinI (pmh 2 h) s v + pinI (pmh 3 h) s v +
    pinI (pmh 4 h) s v + pinI (pmh 5 h) s v

theorem fibreP_add (γ1 γ2 : Nat → Int) (a : Nat) (σ c : Nat → Nat) :
    fibreP (fun v => γ1 v + γ2 v) a σ c = fibreP γ1 a σ c + fibreP γ2 a σ c := by
  unfold fibreP
  rw [← sumOver_add]
  exact sumOver_congr _ (fun t => Int.mul_add _ _ _) _

theorem GsG_add (γ1 γ2 : Nat → Int) (a : Nat) (σ : Asg) :
    GsG (fun v => γ1 v + γ2 v) a σ = GsG γ1 a σ + GsG γ2 a σ := by
  unfold GsG
  rw [← sumOver_add]
  exact sumOver_congr _ (fun c => by rw [fibreP_add, Int.mul_add]) _

/-- the six parts together are one fibre sum with the orbit weight. -/
theorem HsP_eq (k h : Nat) (σ : Asg) : HsP k h σ = GsG (gamS h (σ (k+1))) (k+1) σ := by
  have e : gamS h (σ (k+1)) = fun v =>
      pinI (pmh 0 h) (σ (k+1)) v + pinI (pmh 1 h) (σ (k+1)) v + pinI (pmh 2 h) (σ (k+1)) v +
        pinI (pmh 3 h) (σ (k+1)) v + pinI (pmh 4 h) (σ (k+1)) v + pinI (pmh 5 h) (σ (k+1)) v :=
    rfl
  rw [e, GsG_add, GsG_add, GsG_add, GsG_add, GsG_add]
  rfl

/-! ## §32  V1: the orbit weight (finite facts) -/

/-
  §32 — what the orbit weight looks like, by kernel `decide` over all hexagrams.

    * `gamS_walsh`  — every Walsh coefficient of `gamS h s` is divisible by 4, for every h, s.
                      (A single pair has coefficients ±2 only; its orbit sum on one support is
                      twice a pair, or two pairs forming half of the support, or a multiple.)
    * `gamS_compl`  — for a complement pair, off the opening pair the weight is the constant 2
                      on support 0 and 0 elsewhere (the three complement pairs are one orbit);
    * `gamS_tai`    — for the pair {7, 56} the weight is 3 times twice the pin.
-/

theorem gamS_walsh : ∀ h < 64, ∀ s < 8, ∀ w < 8,
    (sum8 fun v => gamS h s v * chi w v) % ((2 ^ 2 : Nat) : Int) = 0 := by decide +kernel

theorem gamS_dvd (h s : Nat) (hh : h < 64) (hs : s < 8) (w : Nat) :
    ((2 ^ 2 : Nat) : Int) ∣ sum8 fun v => gamS h s v * chi' w v := by
  have h' := gamS_walsh h hh s hs (w % 8) (Nat.mod_lt _ (by omega))
  simp only [sum8] at h' ⊢
  exact Int.dvd_of_emod_eq_zero h'

/-- side condition of `gamS_compl`: h is a complement hexagram and (s, v) is not in the
    opening pair. -/
def complSide (h s v : Nat) : Bool := supp h == 0 && !(s == 0 && (v == 0 || v == 7))
/-- the constant the orbit weight of a complement pair takes there. -/
def complVal (h s : Nat) : Int := if s == 0 && h != 0 && h != 63 then 2 else 0

theorem gamS_compl : ∀ h < 64, ∀ s < 8, ∀ v < 8, complSide h s v = true →
    gamS h s v = complVal h s := by decide +kernel

theorem complVal_cases (h s : Nat) : complVal h s = 2 ∨ complVal h s = 0 := by
  unfold complVal; split
  · exact Or.inl rfl
  · exact Or.inr rfl

theorem gamS_tai : ∀ h ∈ [7, 56], ∀ s < 8, ∀ v < 8, gamS h s v = 3 * (2 * pinI h s v) := by
  decide +kernel

theorem tai_walsh : ∀ h ∈ [7, 56], ∀ s < 8, ∀ w < 8,
    (sum8 fun v => (2 * pinI h s v) * chi w v) % ((2 ^ 2 : Nat) : Int) = 0 := by decide +kernel

theorem tai_dvd (h s : Nat) (hh : h ∈ [7, 56]) (hs : s < 8) (w : Nat) :
    ((2 ^ 2 : Nat) : Int) ∣ sum8 fun v => (2 * pinI h s v) * chi' w v := by
  have h' := tai_walsh h hh s hs (w % 8) (Nat.mod_lt _ (by omega))
  simp only [sum8] at h' ⊢
  exact Int.dvd_of_emod_eq_zero h'

/-- controls: the exponents are exact. A single pair costs two factors, not one; the orbit
    weight costs one, not none. -/
theorem pin_mut : ¬ ((sum8 fun v => pinI 17 (supp 17) v * chi 0 v) % ((2 ^ 2 : Nat) : Int) = 0) := by
  decide +kernel
theorem gamS_mut : ¬ ((sum8 fun v => gamS 17 (supp 17) v * chi 0 v) % ((2 ^ 3 : Nat) : Int) = 0) := by
  decide +kernel
/-- control: the weight of a complement pair is NOT constant on the opening pair's coordinates,
    so the side condition of `gamS_compl` is doing work. -/
theorem gamS_compl_mut : gamS 18 0 0 ≠ complVal 18 0 := by decide +kernel

/-! ## §33  THE V1 THEOREMS -/

/-
  §33 — the V1 theorems.

      theorem cellV1_dvd       : CellV1Dvd        -- 2^19 | cellV1 k h         (k < 31, h < 64)
      theorem cellV1_compl_dvd : CellV1ComplDvd   -- 2^21 | cellV1 k h   if supp h = 0
      theorem cellV1_tai_dvd   : CellV1TaiDvd     -- 2^19 * 3 | cellV1 k h   for h = 7, 56

  Each is `cellV1_six` + `HsP_eq` + a bound on the weighted fibre:
    * in general, `fibreP_dvd` with m = 2 (`gamS_dvd`): 2^(17 + 2);
    * for a complement pair the weighted fibre is 2 * `fibreC` or 0 (`fibreP_compl`), because
      a slot of support 0 can never hold the opening pair: 2 * 2^20;
    * for {7, 56} the weight is 3 * (2 * pin) and 2 * pin has m = 2: 3 * 2^19.
-/

theorem HsP_dvd (k h : Nat) (σ : Nat → Nat) (hk : k < 31) (hh : h < 64) (hσ : ∀ k, σ k < 8) :
    ((2 ^ 19 : Nat) : Int) ∣ HsP k h σ := by
  rw [HsP_eq]
  unfold GsG
  apply sumOver_dvd
  intro c
  unfold Bind
  cases hb : budgetOK c with
  | false => simp
  | true =>
    exact Int.dvd_trans (fibreP_dvd σ c hσ hb (gamS h (σ (k+1))) 2
      (gamS_dvd h _ hh (hσ _)) (k+1) (by omega) (by omega)) (Int.dvd_mul_left _ _)

/-- **The V1 theorem (abstract count).** Every per-pair positional count of the superspace
    C1 ∩ C2 ∩ C4 ∩ C5 is divisible by 2^19. -/
theorem cellV1_dvd : CellV1Dvd := by
  intro k h hk hh
  apply Int.natCast_dvd_natCast.mp
  rw [cellV1_six k h hk hh]
  apply sumOver_dvd_bd
  intro σ hb ho
  exact Int.dvd_trans (HsP_dvd k h σ hk hh (fun j => by
    by_cases hj : j ∈ slots
    · exact hb j hj
    · rw [ho j hj]; omega)) (Int.dvd_mul_right _ _)

/-- a slot of support 0 in a valid assignment never holds the opening pair. -/
theorem W_anchor (σ c : Nat → Nat) (t : Asg) (a : Nat) (ha1 : 1 ≤ a) (ha : a ≤ 31)
    (hσa : σ a = 0) (hW : W σ c t ≠ 0) : t a % 8 ≠ 0 ∧ t a % 8 ≠ 7 := by
  have hd : distinctOK σ t = true := by
    cases hv : distinctOK σ t with
    | true => rfl
    | false => exact absurd (by simp [W, hv]) hW
  have h := (distinct_iff σ t).mp hd 0 a (by omega) (by omega)
  rw [entry_zero, entry_pos σ t a (by omega), hσa, sp63 _ (Nat.mod_lt _ (by omega)),
    (anchor_coord _ (Nat.mod_lt _ (by omega)) 0 (by simp)).1] at h
  simp at h
  exact h

/-- for a complement pair the orbit-weighted fibre is twice the plain fibre, or zero. -/
theorem fibreP_compl (h : Nat) (hh : h < 64) (h0 : supp h = 0) (a : Nat) (ha1 : 1 ≤ a)
    (ha : a ≤ 31) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (c : Nat → Nat) :
    fibreP (gamS h (σ a)) a σ c = complVal h (σ a) * fibreC σ c := by
  show sumOver slots (fun t => W σ c t * gamS h (σ a) (t a % 8)) (fun _ => 0) =
    complVal h (σ a) * sumOver slots (W σ c) (fun _ => 0)
  rw [← sumOver_const_mul]
  apply sumOver_congr
  intro t
  by_cases hW : W σ c t = 0
  · rw [hW]; simp
  · have hs : complSide h (σ a) (t a % 8) = true := by
      unfold complSide
      rw [h0]
      by_cases e : σ a = 0
      · have := W_anchor σ c t a ha1 ha e hW
        rw [e]; simp [this.1, this.2]
      · simp [e]
    rw [gamS_compl h hh (σ a) (hσ a) (t a % 8) (Nat.mod_lt _ (by omega)) hs, Int.mul_comm]

theorem two_or_zero_dvd (y x : Int) (hy : y = 2 ∨ y = 0) (hx : ((2 ^ 20 : Nat) : Int) ∣ x) :
    ((2 ^ 21 : Nat) : Int) ∣ y * x := by
  obtain ⟨q, hq⟩ := hx
  rcases hy with e | e
  · refine ⟨q, ?_⟩
    rw [e, hq]
    have e2 : ((2 ^ 21 : Nat) : Int) = 2 * ((2 ^ 20 : Nat) : Int) := by decide
    rw [e2, Int.mul_assoc]
  · rw [e, Int.zero_mul]; exact Int.dvd_zero _

/-- **Complement pairs.** 2^21 divides the positional count of every complement pair. -/
theorem cellV1_compl_dvd : CellV1ComplDvd := by
  intro k h hk hh h0
  apply Int.natCast_dvd_natCast.mp
  rw [cellV1_six k h hk hh]
  apply sumOver_dvd_bd
  intro σ hb ho
  have hσ : ∀ j, σ j < 8 := fun j => by
    by_cases hj : j ∈ slots
    · exact hb j hj
    · rw [ho j hj]; omega
  refine Int.dvd_trans ?_ (Int.dvd_mul_right _ _)
  rw [HsP_eq]
  unfold GsG
  apply sumOver_dvd
  intro c
  unfold Bind
  cases hbud : budgetOK c with
  | false => simp
  | true =>
    rw [fibreP_compl h hh h0 (k+1) (by omega) (by omega) σ hσ c]
    exact Int.dvd_trans (two_or_zero_dvd _ _ (complVal_cases h (σ (k+1))) (fibreC_dvd σ c hσ hbud))
      (Int.dvd_mul_left _ _)

theorem fibreP_tai (h : Nat) (hh : h ∈ [7, 56]) (a : Nat) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8)
    (c : Nat → Nat) :
    fibreP (gamS h (σ a)) a σ c = 3 * fibreP (fun v => 2 * pinI h (σ a) v) a σ c := by
  unfold fibreP
  rw [← sumOver_const_mul]
  apply sumOver_congr
  intro t
  rw [gamS_tai h hh (σ a) (hσ a) (t a % 8) (Nat.mod_lt _ (by omega))]
  exact Int.mul_left_comm _ _ _

theorem three_mul_dvd (x : Int) (hx : ((2 ^ 19 : Nat) : Int) ∣ x) :
    ((2 ^ 19 * 3 : Nat) : Int) ∣ 3 * x := by
  obtain ⟨q, hq⟩ := hx
  refine ⟨q, ?_⟩
  rw [hq]
  have e : ((2 ^ 19 * 3 : Nat) : Int) = 3 * ((2 ^ 19 : Nat) : Int) := by decide
  rw [e, Int.mul_assoc]

/-- **The pair {7, 56}.** Its positional counts are divisible by 2^19 * 3. -/
theorem cellV1_tai_dvd : CellV1TaiDvd := by
  intro k h hk hh
  have hmem : h ∈ [7, 56] := by
    rcases hh with e | e <;> subst e <;> simp
  have h64 : h < 64 := by
    rcases hh with e | e <;> subst e <;> omega
  apply Int.natCast_dvd_natCast.mp
  rw [cellV1_six k h hk h64]
  apply sumOver_dvd_bd
  intro σ hb ho
  have hσ : ∀ j, σ j < 8 := fun j => by
    by_cases hj : j ∈ slots
    · exact hb j hj
    · rw [ho j hj]; omega
  refine Int.dvd_trans ?_ (Int.dvd_mul_right _ _)
  rw [HsP_eq]
  unfold GsG
  apply sumOver_dvd
  intro c
  unfold Bind
  cases hbud : budgetOK c with
  | false => simp
  | true =>
    rw [fibreP_tai h hmem (k+1) σ hσ c]
    exact Int.dvd_trans (three_mul_dvd _ (fibreP_dvd σ c hσ hbud (fun v => 2 * pinI h (σ (k+1)) v) 2
      (tai_dvd h _ hmem (hσ _)) (k+1) (by omega) (by omega))) (Int.dvd_mul_left _ _)

/-! ## §34  V1: controls and the cardinality reading -/

/-
  §34 — controls for the V1 theorems (kernel-checked), and the cardinality reading.

    * `kw_cellV1_pos`   — not vacuous: King Wen has the pair of hexagram 17 in slot 1, so the
                          cell (0, 17) is positive, hence at least 2^19;
    * `kw_cellV1_compl_pos` — King Wen has the complement pair {18, 45} in slot 14, so the cell
                          (13, 18) is positive, hence at least 2^21;
    * `kw_cellV1_tai_pos`   — King Wen has the pair {7, 56} in slot 5;
    * `cellV1_card_dvd` — the statement for any duplicate-free list of a cell's members.
-/

theorem kw_slot1 : samePair (KW.getD (2 * (0+1)) 99) 17 = true := by decide +kernel
theorem kw_slot14 : samePair (KW.getD (2 * (13+1)) 99) 18 = true := by decide +kernel
theorem kw_slot5 : samePair (KW.getD (2 * (4+1)) 99) 7 = true := by decide +kernel
theorem supp_18 : supp 18 = 0 := by decide

/-- NON-VACUITY: the V1 cell (0, 17) contains King Wen. -/
theorem kw_cellV1_pos : 0 < cellV1 0 17 := by
  unfold cellV1
  apply List.length_pos_of_mem (a := KW)
  rw [List.mem_filter]
  exact ⟨kw_mem, by rw [kw_isSuper, kw_slot1]; rfl⟩

theorem kw_cellV1_ge : 2 ^ 19 ≤ cellV1 0 17 :=
  Nat.le_of_dvd kw_cellV1_pos (cellV1_dvd 0 17 (by omega) (by omega))

theorem kw_cellV1_compl_pos : 0 < cellV1 13 18 := by
  unfold cellV1
  apply List.length_pos_of_mem (a := KW)
  rw [List.mem_filter]
  exact ⟨kw_mem, by rw [kw_isSuper, kw_slot14]; rfl⟩

theorem kw_cellV1_compl_ge : 2 ^ 21 ≤ cellV1 13 18 :=
  Nat.le_of_dvd kw_cellV1_compl_pos (cellV1_compl_dvd 13 18 (by omega) (by omega) supp_18)

theorem kw_cellV1_tai_pos : 0 < cellV1 4 7 := by
  unfold cellV1
  apply List.length_pos_of_mem (a := KW)
  rw [List.mem_filter]
  exact ⟨kw_mem, by rw [kw_isSuper, kw_slot5]; rfl⟩

theorem kw_cellV1_tai_ge : 2 ^ 19 * 3 ≤ cellV1 4 7 :=
  Nat.le_of_dvd kw_cellV1_tai_pos (cellV1_tai_dvd 4 7 (by omega) (Or.inl rfl))

/-- **the V1 theorem as a statement about cardinalities** (no reference to `seqs`). -/
theorem cellV1_card_dvd : CellV1CardDvd := by
  intro k h L hk hh hL hmem
  have hF : ((seqs 64).filter fun l => isSuper l && samePair (l.getD (2 * (k+1)) 99) h).Nodup :=
    List.Pairwise.filter _ (seqs_nodup 64)
  have hm : ∀ l, l ∈ L ↔
      l ∈ (seqs 64).filter fun l => isSuper l && samePair (l.getD (2 * (k+1)) 99) h := by
    intro l
    rw [hmem l, List.mem_filter, mem_seqs, Bool.and_eq_true]
    constructor
    · rintro ⟨a, b, c, e⟩; exact ⟨⟨a, b⟩, c, e⟩
    · rintro ⟨⟨a, b⟩, c, e⟩; exact ⟨a, b, c, e⟩
  have e : L.length = cellV1 k h :=
    Nat.le_antisymm (nodup_len_le L _ hL fun a ha => (hm a).mp ha)
      (nodup_len_le _ L hF fun a ha => (hm a).mpr ha)
  rw [e]; exact cellV1_dvd k h hk hh

end SuperspaceDivisibility

-- Axiom reports (each must be a subset of [propext, Classical.choice, Quot.sound]).
-- Every constant of the file, not only the ones listed here, is covered by the module-wide
-- census (lean/AxiomCensus.lean.in). Names containing a prime are not listed.
#print axioms SuperspaceDivisibility.kw_isSuper
#print axioms SuperspaceDivisibility.kw_bseq
#print axioms SuperspaceDivisibility.allDivF_sound
#print axioms SuperspaceDivisibility.sumOver_append_mul
#print axioms SuperspaceDivisibility.sumOver_perm
#print axioms SuperspaceDivisibility.sumOver_sum8
#print axioms SuperspaceDivisibility.fourier_inv8
#print axioms SuperspaceDivisibility.twdiv_append
#print axioms SuperspaceDivisibility.twdiv_cross
#print axioms SuperspaceDivisibility.twdiv_slot
#print axioms SuperspaceDivisibility.twdiv_count
#print axioms SuperspaceDivisibility.hat_digit
#print axioms SuperspaceDivisibility.twdiv_of_hat4
#print axioms SuperspaceDivisibility.cross_table
#print axioms SuperspaceDivisibility.anchor_table
#print axioms SuperspaceDivisibility.patRP_sound
#print axioms SuperspaceDivisibility.patCP_sound
#print axioms SuperspaceDivisibility.tP_7_6
#print axioms SuperspaceDivisibility.table_spec_R
#print axioms SuperspaceDivisibility.table_spec_C
#print axioms SuperspaceDivisibility.step4_R
#print axioms SuperspaceDivisibility.step4_C
#print axioms SuperspaceDivisibility.class_formula
#print axioms SuperspaceDivisibility.kw_in_model
#print axioms SuperspaceDivisibility.ctl_py
#print axioms SuperspaceDivisibility.pm_same
#print axioms SuperspaceDivisibility.twdiv_blocks
#print axioms SuperspaceDivisibility.gam_dvd
#print axioms SuperspaceDivisibility.anc_dvd
#print axioms SuperspaceDivisibility.catK_perm
#print axioms SuperspaceDivisibility.Q4_of_len
#print axioms SuperspaceDivisibility.budget_cls
#print axioms SuperspaceDivisibility.budget_w
#print axioms SuperspaceDivisibility.cq_same
#print axioms SuperspaceDivisibility.W_eq
#print axioms SuperspaceDivisibility.fold_twdiv
#print axioms SuperspaceDivisibility.EE_ge
#print axioms SuperspaceDivisibility.fibreC_dvd_general
#print axioms SuperspaceDivisibility.fibreC_dvd
#print axioms SuperspaceDivisibility.fibreC_dvd_explicit
#print axioms SuperspaceDivisibility.kw_fibre_pos
#print axioms SuperspaceDivisibility.kw_fibre_dvd
#print axioms SuperspaceDivisibility.kw_fibre_ge
#print axioms SuperspaceDivisibility.fibreC_head_free
#print axioms SuperspaceDivisibility.C1sum
#print axioms SuperspaceDivisibility.Ssum
#print axioms SuperspaceDivisibility.sumOver_delta
#print axioms SuperspaceDivisibility.filter_eq_sumN_count
#print axioms SuperspaceDivisibility.nodup_pairs
#print axioms SuperspaceDivisibility.all_iff_nodup
#print axioms SuperspaceDivisibility.c5_iff_budget
#print axioms SuperspaceDivisibility.super_char
#print axioms SuperspaceDivisibility.point_eq
#print axioms SuperspaceDivisibility.cell_eq
#print axioms SuperspaceDivisibility.fibreC_pm
#print axioms SuperspaceDivisibility.rsum_one
#print axioms SuperspaceDivisibility.cell_six
#print axioms SuperspaceDivisibility.cellV2_dvd
#print axioms SuperspaceDivisibility.superCount_dvd
#print axioms SuperspaceDivisibility.mem_seqs
#print axioms SuperspaceDivisibility.kw_cell_pos
#print axioms SuperspaceDivisibility.kw_cell_ge
#print axioms SuperspaceDivisibility.superCount_ge
#print axioms SuperspaceDivisibility.seqs_nodup
#print axioms SuperspaceDivisibility.cellV2_card_dvd
#print axioms SuperspaceDivisibility.fibre_point
#print axioms SuperspaceDivisibility.fibre_dvd
#print axioms SuperspaceDivisibility.kw_fibre_list_ge
-- §28–§34 (per-pair positional counts)
#print axioms SuperspaceDivisibility.count_eq
#print axioms SuperspaceDivisibility.LL_getD
#print axioms SuperspaceDivisibility.point_eq_V1
#print axioms SuperspaceDivisibility.cellV1_eq
#print axioms SuperspaceDivisibility.fibre_main_pin
#print axioms SuperspaceDivisibility.fibreP_dvd_general
#print axioms SuperspaceDivisibility.fibreP_dvd
#print axioms SuperspaceDivisibility.pin_pm
#print axioms SuperspaceDivisibility.fibreP_pm
#print axioms SuperspaceDivisibility.GsP_pm
#print axioms SuperspaceDivisibility.GsG_zero_bad
#print axioms SuperspaceDivisibility.cellV1_six
#print axioms SuperspaceDivisibility.fibreP_add
#print axioms SuperspaceDivisibility.GsG_add
#print axioms SuperspaceDivisibility.HsP_eq
#print axioms SuperspaceDivisibility.gamS_walsh
#print axioms SuperspaceDivisibility.gamS_dvd
#print axioms SuperspaceDivisibility.gamS_compl
#print axioms SuperspaceDivisibility.complVal_cases
#print axioms SuperspaceDivisibility.gamS_tai
#print axioms SuperspaceDivisibility.tai_walsh
#print axioms SuperspaceDivisibility.tai_dvd
#print axioms SuperspaceDivisibility.pin_mut
#print axioms SuperspaceDivisibility.gamS_mut
#print axioms SuperspaceDivisibility.gamS_compl_mut
#print axioms SuperspaceDivisibility.HsP_dvd
#print axioms SuperspaceDivisibility.cellV1_dvd
#print axioms SuperspaceDivisibility.W_anchor
#print axioms SuperspaceDivisibility.fibreP_compl
#print axioms SuperspaceDivisibility.two_or_zero_dvd
#print axioms SuperspaceDivisibility.cellV1_compl_dvd
#print axioms SuperspaceDivisibility.fibreP_tai
#print axioms SuperspaceDivisibility.three_mul_dvd
#print axioms SuperspaceDivisibility.cellV1_tai_dvd
#print axioms SuperspaceDivisibility.kw_slot1
#print axioms SuperspaceDivisibility.kw_slot14
#print axioms SuperspaceDivisibility.kw_slot5
#print axioms SuperspaceDivisibility.supp_18
#print axioms SuperspaceDivisibility.kw_cellV1_pos
#print axioms SuperspaceDivisibility.kw_cellV1_ge
#print axioms SuperspaceDivisibility.kw_cellV1_compl_pos
#print axioms SuperspaceDivisibility.kw_cellV1_compl_ge
#print axioms SuperspaceDivisibility.kw_cellV1_tai_pos
#print axioms SuperspaceDivisibility.kw_cellV1_tai_ge
#print axioms SuperspaceDivisibility.cellV1_card_dvd

/-
  ════════════════════════════════════════════════════════════════════════════════════════════
  PART 2 (§35–§46, appended 2026-11-17): THEOREM G+ BY COUNTING FAMILIES
  ════════════════════════════════════════════════════════════════════════════════════════════
  Developed with AI assistance (Claude, Anthropic).

  Everything above this comment is Part 1 (§0–§34), which was written first; the header at
  the top of the file describes that part only. Part 1 does not need Part 2: nothing below is
  used above. No import is added: the file is still standalone, core Lean 4 only, kernel only
  (no native_decide, no sorry, no axiom; the `#print axioms` lines of §46 and the module-wide
  census cover every theorem of Part 2).

  WHAT IS PROVED IN PART 2 (scope exactly as stated)

  `fibreC σ cl` (§14) is the coordinate-model fibre: the number of assignments of three bits
  to each of the 31 free slots for which the 32 pairs are distinct and every boundary k has the
  class cl k. `budgetOK cl` is King Wen's boundary budget {1:2, 2:8, 3:13, 4:7, 6:1}.
  t = `tcount σ cl` is the number of class-3 boundaries whose two supports differ in exactly
  one coordinate (slot 0, the anchor, has support 0); t ≤ 13 (`tcount_le`).

    theorem gplus_fibre    : (∀ k, σ k < 8) → budgetOK cl = true →
                             2 ^ (26 - tcount σ cl) ∣ fibreC σ cl
    theorem gplus_fibre_13 : the same hypotheses → 2 ^ 13 ∣ fibreC σ cl
    theorem gplus_family   : in a nonempty fibre the translations by moves that meet the
                             conditions number 2^d with d ≥ 26 - t; each maps the fibre onto
                             itself; none but the zero translation fixes a vector
    theorem ident_exact    : in a nonempty fibre exactly 2^7 of the 2^53 parameter choices are
                             the identity, and each of them meets the conditions
    theorem moves_exact    : in a nonempty fibre the moves are exactly 2^46 translations
    theorem cellV2_dvd_families     : ∀ k d : Nat, 2 ^ 14 * 3 ∣ cellV2 k d
    theorem superCount_dvd_families : 2 ^ 14 * 3 ∣ superCount
    theorem censusC_dvd_families    : ∀ c0 : List Nat, 2 ^ 14 * 3 ∣ censusC c0
    theorem censusC_dvd             : ∀ c0 : List Nat, 2 ^ 21 * 3 ∣ censusC c0

  `censusC c0` (§43) is N(c): the number of superspace sequences whose class sequence is c0.
  (2 ^ 14 * 3 = 49,152.) Non-vacuity: King Wen meets every hypothesis and its fibre is not
  empty (`kw_gplus`, `kw_family`, `kw_ident_exact`, `kw_census_pos`).

  The three `…_families` theorems STATE less than Part 1 does (2^21 * 3 for the cells and the
  total; `censusC_dvd`: the same for N(c)). New in them is the PROOF: 2^13 per fibre from the
  families of §41, 6 from the coordinate permutations of Step 6. The proofs use Step 1, Step 6 and
  the book-keeping of §1, §4-§8, §17-§19. A census of what each proof uses, not a theorem, finds
  none of its 29 named Walsh/character definitions of Part 1, nothing of §3, §9-§12 and no Part 1
  definition off its list of 57 (lean/README.md); Part 2's own definitions it does not examine.

  WHAT IS NOT PROVED IN PART 2

    * `gplus_fibre`, `gplus_family`, `ident_exact` and `moves_exact` are about the
      coordinate-model fibre. No fibre-by-fibre statement is proved for sequences here. The
      SUMS are linked to sequences (`cell_eq`, `cell_eqC`), so the cells, the total and N(c)
      are counts of sequences.
    * "Divides", not "exactly": no fibre is shown where 2^(26 - t) is the largest power of two
      dividing its size. For t ≥ 6 the bound is not better than Part 1's 2^20 (`fibreC_dvd`);
      for t ≤ 5 it is.
    * `ident_exact` and `moves_exact` need a walk of the fibre. Without one both halves of
      `ident_exact` are false (`ident_needs_walk`: 2^9 identity choices on a skeleton with an
      absent support; `ident_all_needs_walk`).
    * The conditions of §39 are sufficient for a move to keep the fibre; that they are
      necessary is not proved in general (on King Wen itself: `kw_moves_bad`).
    * As in Part 1: the counts are the ones defined in this file; Lean reads no table.

  NAMES. Part 2 lives in the namespaces `F2Count` (§35, §36) and `Q1150` (§37–§45). Three
  short names occur both there and in `SuperspaceDivisibility`, for different statements:
  `W_eq` (Part 1: W as a product of indicators; `Q1150.W_eq`: W as the indicator of `Fb`),
  `count_eq` (Part 1: Step 1 for an extra condition; `F2Count.count_eq`: the number of
  solutions of a linear system) and `kw_fibre_pos` (Part 1: `fibreC kwσ kwc`;
  `Q1150.kw_fibre_pos`: the same fibre as a count of bit vectors). Inside `Q1150` every use of
  `W_eq` and `kw_fibre_pos` is written with its namespace; `count_eq` is used only inside
  `F2Count`, where `SuperspaceDivisibility` is not open.

  CONTENTS OF PART 2
    §35  LINEAR SYSTEMS OVER F_2 AND ORBIT COUNTING
    §36  controls for §35 (kernel `decide`)
    §37  from sums over assignments to counts of bit vectors
    §38  the finite steps ("the local lemma"), each by kernel `decide` over every case
    §39  THE MOVES AND THE CONDITIONS
    §40  a move that meets the conditions maps the fibre into itself
    §41  THEOREM G+ FOR THE COORDINATE-MODEL FIBRE
    §42  2^13 FOR EVERY FIBRE; THE FAMILY; 2^14 * 3 FOR THE V2 CELLS AND THE TOTAL
    §43  N(c), THE CLASS-SEQUENCE CENSUS
    §44  controls: Theorem G+ on King Wen's fibre and on two recorded fibres
    §45  THE IDENTITY CHOICES, EXACTLY; EXACTLY 2^46 MOVES
    §46  axiom reports for every theorem of Part 2
-/

/-
  §35  LINEAR SYSTEMS OVER F_2 AND ORBIT COUNTING

  A vector is a `List Bool`; `vecs n` lists the 2^n vectors of length n, each once
  (`mem_vecs`, `vecs_length`, `vecs_nodup`), and `cntP n p` is the number of them with `p`.
  A row is (coefficients, right-hand side); a row shorter than the vector is read as padded
  with zeros. `sat S x` says x meets every row of S. `rank n S` is the number of pivots that
  elimination on the first n coordinates finds; it never looks at the right-hand sides.

    count_eq      : cntP n (sat S) = if cons n S then 2 ^ (n - rank n S) else 0
    hom_count     : Hom S → cntP n (sat S) = 2 ^ (n - rank n S)
    orbit_dvd     : Hom S → (every c with sat S c leaves Y unchanged under x ↦ x + M c) →
                    cntP n (sat S) ∣ cntP N Y * cntP n (fun c => sat S c && ker M c)
    family_dvd    : the same, and at most 2^κ solutions c with M c = 0 →
                    2 ^ (n - S.length - κ) ∣ cntP N Y
    img_count     : the distinct translations x ↦ x + M c number (solutions)/(identity choices),
                    stated without division

  No quotient and no freeness hypothesis: the moves that act as the identity are counted, not
  divided out. (The sub-headings "§1" to "§6" inside this section are local to it.)
-/
namespace F2Count

abbrev Vec := List Bool
abbrev Row := Vec × Bool

/-! ## §1  vectors, dot product, counting -/

/-- dot product over F_2; the shorter argument is read as padded with zeros. -/
def dot : Vec → Vec → Bool
  | [], _ => false
  | _ :: _, [] => false
  | a :: as, x :: xs => (a && x) ^^ dot as xs

theorem dot_nil (a : Vec) : dot a [] = false := by cases a <;> rfl

theorem dot_cons (a : Vec) (b : Bool) (x : Vec) :
    dot a (b :: x) = ((a.headD false && b) ^^ dot a.tail x) := by
  cases a with
  | nil => simp [dot]
  | cons a0 as => simp [dot]

/-- all vectors of length n. -/
def vecs : Nat → List Vec
  | 0 => [[]]
  | n+1 => (vecs n).map (false :: ·) ++ (vecs n).map (true :: ·)

/-- the number of vectors of length n with property p. -/
def cntP (n : Nat) (p : Vec → Bool) : Nat := ((vecs n).filter p).length

theorem mem_vecs : ∀ (n : Nat) (x : Vec), x ∈ vecs n ↔ x.length = n
  | 0, x => by cases x <;> simp [vecs]
  | n+1, x => by
    simp only [vecs, List.mem_append, List.mem_map]
    constructor
    · intro h
      rcases h with ⟨y, hy, rfl⟩ | ⟨y, hy, rfl⟩ <;> simp [(mem_vecs n y).mp hy]
    · intro h
      cases x with
      | nil => simp at h
      | cons b y =>
        have hy : y ∈ vecs n := (mem_vecs n y).mpr (by simpa using h)
        cases b
        · exact Or.inl ⟨y, hy, rfl⟩
        · exact Or.inr ⟨y, hy, rfl⟩

theorem vecs_length : ∀ n : Nat, (vecs n).length = 2 ^ n
  | 0 => rfl
  | n+1 => by
    simp only [vecs, List.length_append, List.length_map, vecs_length n, Nat.pow_succ]; omega

theorem nodup_map_cons (b : Bool) : ∀ l : List Vec, l.Nodup → (l.map (b :: ·)).Nodup
  | [], _ => List.nodup_nil
  | a :: l, h => by
    rw [List.nodup_cons] at h
    rw [List.map_cons, List.nodup_cons]
    refine ⟨?_, nodup_map_cons b l h.2⟩
    intro hm
    rcases List.mem_map.mp hm with ⟨y, hy, e⟩
    have : y = a := by injection e
    exact h.1 (this ▸ hy)

theorem vecs_nodup : ∀ n : Nat, (vecs n).Nodup
  | 0 => by simp [vecs]
  | n+1 => by
    simp only [vecs]
    rw [List.nodup_append]
    refine ⟨nodup_map_cons false _ (vecs_nodup n), nodup_map_cons true _ (vecs_nodup n), ?_⟩
    intro a ha b hb e
    rcases List.mem_map.mp ha with ⟨y, _, rfl⟩
    rcases List.mem_map.mp hb with ⟨y', _, rfl⟩
    injection e with e1 _
    cases e1

theorem cntP_succ (n : Nat) (p : Vec → Bool) :
    cntP (n+1) p = cntP n (fun x => p (false :: x)) + cntP n (fun x => p (true :: x)) := by
  simp only [cntP, vecs, List.filter_append, List.length_append, List.filter_map, List.length_map]
  rfl

theorem cntP_congr (n : Nat) (p q : Vec → Bool) (h : ∀ x, x ∈ vecs n → p x = q x) :
    cntP n p = cntP n q := by
  unfold cntP; rw [List.filter_congr h]

theorem filter_split (e q : Vec → Bool) (l : List Vec) :
    (l.filter (fun x => !(e x) && q x)).length + (l.filter (fun x => e x && q x)).length
      = (l.filter q).length := by
  induction l with
  | nil => rfl
  | cons a l ih =>
    simp only [List.filter_cons]
    cases e a <;> cases q a <;> simp <;> omega

theorem cntP_split (n : Nat) (e q : Vec → Bool) :
    cntP n (fun x => !(e x) && q x) + cntP n (fun x => e x && q x) = cntP n q :=
  filter_split e q (vecs n)

/-! ## §2  systems, elimination, rank -/

def hd (r : Row) : Bool := r.1.headD false
def tl (r : Row) : Row := (r.1.tail, r.2)
def rowsat (r : Row) (x : Vec) : Bool := dot r.1 x == r.2
def sat (S : List Row) (x : Vec) : Bool := S.all (fun r => rowsat r x)

theorem sat_cons (r : Row) (S : List Row) (x : Vec) : sat (r :: S) x = (rowsat r x && sat S x) := rfl

theorem sat_map (f : Row → Row) (x y : Vec) : ∀ S : List Row,
    (∀ q, q ∈ S → rowsat q y = rowsat (f q) x) → sat S y = sat (S.map f) x
  | [], _ => rfl
  | r :: S, h => by
    rw [List.map_cons, sat_cons, sat_cons, h r List.mem_cons_self,
      sat_map f x y S (fun q hq => h q (List.mem_cons_of_mem _ hq))]

/-- sum of two coefficient vectors (the shorter one padded with zeros). -/
def vxor : Vec → Vec → Vec
  | [], b => b
  | a :: as, [] => a :: as
  | a :: as, b :: bs => (a ^^ b) :: vxor as bs

theorem dot_vxor : ∀ (a b x : Vec), dot (vxor a b) x = (dot a x ^^ dot b x)
  | [], b, x => by simp [vxor, dot]
  | a :: as, [], x => by simp [vxor, dot]
  | a :: as, b :: bs, [] => by simp [vxor, dot]
  | a :: as, b :: bs, x :: xs => by
    simp only [vxor, dot]
    rw [dot_vxor as bs xs]
    generalize dot as xs = p
    generalize dot bs xs = q
    cases a <;> cases b <;> cases x <;> cases p <;> cases q <;> rfl

theorem headD_vxor (a b : Vec) : (vxor a b).headD false = (a.headD false ^^ b.headD false) := by
  cases a <;> cases b <;> simp [vxor]

/-- reduce q by the pivot row p: if q has the leading coordinate, add p. -/
def red (p q : Row) : Row := if hd q then (vxor q.1 p.1, q.2 ^^ p.2) else q

theorem hd_red (p q : Row) (hp : hd p = true) : hd (red p q) = false := by
  unfold red
  cases hq : hd q with
  | false => simpa using hq
  | true =>
    simp only [if_true]
    unfold hd at hp hq ⊢
    show (vxor q.1 p.1).headD false = false
    rw [headD_vxor, hp, hq]; rfl

theorem rowsat_red (p q : Row) (x : Vec) (hp : rowsat p x = true) :
    rowsat (red p q) x = rowsat q x := by
  unfold red
  cases hq : hd q with
  | false => simp
  | true =>
    simp only [if_true]
    unfold rowsat at hp ⊢
    simp only [dot_vxor]
    have e : dot p.1 x = p.2 := by simpa using hp
    rw [e]
    cases dot q.1 x <;> cases q.2 <;> cases p.2 <;> rfl

theorem rowsat_tl (r : Row) (b : Bool) (x : Vec) (h : hd r = false) :
    rowsat r (b :: x) = rowsat (tl r) x := by
  unfold hd at h
  unfold rowsat tl
  rw [dot_cons, h]
  simp

/-- the first row with the leading coordinate, and the other rows (order kept). -/
def split : List Row → Option (Row × List Row)
  | [] => none
  | r :: S => if hd r then some (r, S) else (split S).map (fun ps => (ps.1, r :: ps.2))

theorem split_none : ∀ (S : List Row), split S = none → ∀ r, r ∈ S → hd r = false
  | [], _, r, hr => by cases hr
  | r0 :: S, h, r, hr => by
    unfold split at h
    cases h0 : hd r0 with
    | true => simp [h0] at h
    | false =>
      simp only [h0] at h
      cases hs : split S with
      | some ps => simp [hs] at h
      | none =>
        rcases List.mem_cons.mp hr with e | hr'
        · rw [e]; exact h0
        · exact split_none S hs r hr'

theorem split_some : ∀ (S : List Row) (ps : Row × List Row), split S = some ps →
    hd ps.1 = true ∧ ps.2.length + 1 = S.length ∧ ps.1 ∈ S ∧ (∀ q, q ∈ ps.2 → q ∈ S) ∧
      ∀ x, sat S x = sat (ps.1 :: ps.2) x
  | [], ps, h => by simp [split] at h
  | r0 :: S, ps, h => by
    unfold split at h
    cases h0 : hd r0 with
    | true =>
      simp only [h0, if_true] at h
      injection h with h
      subst h
      exact ⟨h0, rfl, List.mem_cons_self, fun q hq => List.mem_cons_of_mem _ hq, fun _ => rfl⟩
    | false =>
      simp only [h0] at h
      cases hs : split S with
      | none => simp [hs] at h
      | some ps1 =>
        rw [hs] at h
        simp only [Option.map_some, Bool.false_eq_true, if_false] at h
        injection h with h
        subst h
        obtain ⟨hp, hl, hm, hsub, hsat⟩ := split_some S ps1 hs
        refine ⟨hp, ?_, List.mem_cons_of_mem _ hm, ?_, ?_⟩
        · simp only [List.length_cons]; omega
        · intro q hq
          rcases List.mem_cons.mp hq with e | hq'
          · rw [e]; exact List.mem_cons_self
          · exact List.mem_cons_of_mem _ (hsub q hq')
        · intro x
          rw [sat_cons, hsat x, sat_cons, sat_cons, sat_cons]
          cases rowsat r0 x <;> cases rowsat ps1.1 x <;> cases sat ps1.2 x <;> rfl

/-- the number of pivots found by elimination on the first n coordinates. -/
def rank : Nat → List Row → Nat
  | 0, _ => 0
  | n+1, S => match split S with
    | none => rank n (S.map tl)
    | some ps => rank n (ps.2.map (fun q => tl (red ps.1 q))) + 1

/-- consistency: after elimination on n coordinates no row reads 0 = 1. -/
def cons : Nat → List Row → Bool
  | 0, S => sat S []
  | n+1, S => match split S with
    | none => cons n (S.map tl)
    | some ps => cons n (ps.2.map (fun q => tl (red ps.1 q)))

theorem rank_succ_none (n : Nat) (S : List Row) (h : split S = none) :
    rank (n+1) S = rank n (S.map tl) := by simp only [rank, h]
theorem rank_succ_some (n : Nat) (S : List Row) (ps : Row × List Row) (h : split S = some ps) :
    rank (n+1) S = rank n (ps.2.map (fun q => tl (red ps.1 q))) + 1 := by simp only [rank, h]
theorem cons_succ_none (n : Nat) (S : List Row) (h : split S = none) :
    cons (n+1) S = cons n (S.map tl) := by simp only [cons, h]
theorem cons_succ_some (n : Nat) (S : List Row) (ps : Row × List Row) (h : split S = some ps) :
    cons (n+1) S = cons n (ps.2.map (fun q => tl (red ps.1 q))) := by simp only [cons, h]

theorem rank_le_n : ∀ (n : Nat) (S : List Row), rank n S ≤ n
  | 0, _ => Nat.le_refl 0
  | n+1, S => by
    cases hs : split S with
    | none => rw [rank_succ_none n S hs]; have := rank_le_n n (S.map tl); omega
    | some ps =>
      rw [rank_succ_some n S ps hs]
      have := rank_le_n n (ps.2.map (fun q => tl (red ps.1 q))); omega

theorem rank_le_rows : ∀ (n : Nat) (S : List Row), rank n S ≤ S.length
  | 0, _ => Nat.zero_le _
  | n+1, S => by
    cases hs : split S with
    | none =>
      rw [rank_succ_none n S hs]
      have := rank_le_rows n (S.map tl); rw [List.length_map] at this; exact this
    | some ps =>
      rw [rank_succ_some n S ps hs]
      have := rank_le_rows n (ps.2.map (fun q => tl (red ps.1 q)))
      rw [List.length_map] at this
      have hl := (split_some S ps hs).2.1
      omega

/-! ## §3  the count -/

theorem cnt_zero (S : List Row) : cntP 0 (sat S) = if sat S [] then 1 else 0 := by
  simp only [cntP, vecs, List.filter_cons, List.filter_nil]
  cases sat S [] <;> rfl

/-- no row has the leading coordinate: it is free. -/
theorem cnt_none (n : Nat) (S : List Row) (h : ∀ r, r ∈ S → hd r = false) :
    cntP (n+1) (sat S) = 2 * cntP n (sat (S.map tl)) := by
  rw [cntP_succ]
  have e : ∀ b : Bool, (fun x => sat S (b :: x)) = sat (S.map tl) := fun b =>
    funext fun x => sat_map tl x (b :: x) S (fun q hq => rowsat_tl q b x (h q hq))
  rw [e false, e true]; omega

theorem sat_pivot (p : Row) (S : List Row) (b : Bool) (x : Vec) (hp : hd p = true) :
    sat (p :: S) (b :: x) =
      ((b == (p.2 ^^ dot p.1.tail x)) && sat (S.map (fun q => tl (red p q))) x) := by
  rw [sat_cons]
  have e : rowsat p (b :: x) = (b == (p.2 ^^ dot p.1.tail x)) := by
    unfold hd at hp
    unfold rowsat
    rw [dot_cons, hp]
    cases b <;> cases p.2 <;> cases dot p.1.tail x <;> rfl
  cases hr : rowsat p (b :: x) with
  | false => rw [← e, hr]; rfl
  | true =>
    rw [← e, hr]
    simp only [Bool.true_and]
    exact sat_map _ x (b :: x) S (fun q _ => by
      rw [← rowsat_tl (red p q) b x (hd_red p q hp), rowsat_red p q (b :: x) hr])

/-- a pivot row fixes the leading coordinate. -/
theorem cnt_pivot (n : Nat) (p : Row) (S : List Row) (hp : hd p = true) :
    cntP (n+1) (sat (p :: S)) = cntP n (sat (S.map (fun q => tl (red p q)))) := by
  rw [cntP_succ]
  have e0 : (fun x => sat (p :: S) (false :: x)) =
      (fun x => !(p.2 ^^ dot p.1.tail x) && sat (S.map (fun q => tl (red p q))) x) :=
    funext fun x => by
      rw [sat_pivot p S false x hp]; cases (p.2 ^^ dot p.1.tail x) <;> rfl
  have e1 : (fun x => sat (p :: S) (true :: x)) =
      (fun x => (p.2 ^^ dot p.1.tail x) && sat (S.map (fun q => tl (red p q))) x) :=
    funext fun x => by
      rw [sat_pivot p S true x hp]; cases (p.2 ^^ dot p.1.tail x) <;> rfl
  rw [e0, e1]
  exact cntP_split n (fun x => p.2 ^^ dot p.1.tail x) _

/-- **The count.** The number of solutions of a system over F_2 in n unknowns is 0 if the
    system is inconsistent and 2^(n - rank) otherwise. -/
theorem count_eq : ∀ (n : Nat) (S : List Row),
    cntP n (sat S) = if cons n S then 2 ^ (n - rank n S) else 0
  | 0, S => by rw [cnt_zero]; simp [cons, rank]
  | n+1, S => by
    cases hs : split S with
    | none =>
      rw [cons_succ_none n S hs, rank_succ_none n S hs, cnt_none n S (split_none S hs),
        count_eq n (S.map tl)]
      have hr := rank_le_n n (S.map tl)
      cases cons n (S.map tl) with
      | false => rfl
      | true =>
        simp only [if_true]
        have e : n + 1 - rank n (S.map tl) = (n - rank n (S.map tl)) + 1 := by omega
        rw [e, Nat.pow_succ, Nat.mul_comm]
    | some ps =>
      obtain ⟨hp, _, _, _, hsat⟩ := split_some S ps hs
      rw [cons_succ_some n S ps hs, rank_succ_some n S ps hs,
        show sat S = sat (ps.1 :: ps.2) from funext hsat, cnt_pivot n ps.1 ps.2 hp,
        count_eq n (ps.2.map (fun q => tl (red ps.1 q)))]
      have e : n + 1 - (rank n (ps.2.map (fun q => tl (red ps.1 q))) + 1)
          = n - rank n (ps.2.map (fun q => tl (red ps.1 q))) := by omega
      rw [e]

/-! ## §4  homogeneous systems; the rank ignores right-hand sides -/

/-- homogeneous: every right-hand side is 0. -/
def Hom (S : List Row) : Prop := ∀ r, r ∈ S → r.2 = false

instance (S : List Row) : Decidable (Hom S) := by unfold Hom; exact inferInstance

/-- forget the right-hand side. -/
def z (r : Row) : Row := (r.1, false)

theorem red_snd (p q : Row) (hp : p.2 = false) (hq : q.2 = false) : (red p q).2 = false := by
  unfold red
  cases hd q with
  | false => simpa using hq
  | true => simp [hp, hq]

theorem cons_hom : ∀ (n : Nat) (S : List Row), Hom S → cons n S = true
  | 0, S, h => by
    show sat S [] = true
    unfold sat
    rw [List.all_eq_true]
    intro r hr
    unfold rowsat
    rw [dot_nil, h r hr]; rfl
  | n+1, S, h => by
    cases hs : split S with
    | none =>
      rw [cons_succ_none n S hs]
      apply cons_hom n
      intro r hr
      rcases List.mem_map.mp hr with ⟨q, hq, rfl⟩
      exact h q hq
    | some ps =>
      rw [cons_succ_some n S ps hs]
      obtain ⟨_, _, hm, hsub, _⟩ := split_some S ps hs
      apply cons_hom n
      intro r hr
      rcases List.mem_map.mp hr with ⟨q, hq, rfl⟩
      exact red_snd ps.1 q (h _ hm) (h q (hsub q hq))

theorem red_z (p q : Row) : red (z p) (z q) = z (red p q) := by
  unfold red
  show (if hd q then _ else _) = z (if hd q then _ else _)
  cases hd q <;> simp [z]

theorem split_z : ∀ S : List Row,
    split (S.map z) = (split S).map (fun ps => (z ps.1, ps.2.map z))
  | [] => rfl
  | r :: S => by
    rw [List.map_cons]
    unfold split
    rw [split_z S]
    show (if hd r then _ else _) = _
    cases hd r with
    | true => rfl
    | false =>
      simp only [Bool.false_eq_true, if_false]
      cases split S <;> rfl

theorem rank_z : ∀ (n : Nat) (S : List Row), rank n (S.map z) = rank n S
  | 0, _ => rfl
  | n+1, S => by
    cases hs : split S with
    | none =>
      have h2 : split (S.map z) = none := by rw [split_z, hs]; rfl
      rw [rank_succ_none n S hs, rank_succ_none n _ h2, ← rank_z n (S.map tl)]
      simp only [List.map_map]
      rfl
    | some ps =>
      have h2 : split (S.map z) = some (z ps.1, ps.2.map z) := by rw [split_z, hs]; rfl
      rw [rank_succ_some n S ps hs, rank_succ_some n _ _ h2,
        ← rank_z n (ps.2.map (fun q => tl (red ps.1 q)))]
      simp only [List.map_map]
      have e : ((fun q => tl (red (z ps.1) q)) ∘ z) = (z ∘ fun q => tl (red ps.1 q)) :=
        funext fun q => by
          show tl (red (z ps.1) (z q)) = z (tl (red ps.1 q))
          rw [red_z]; rfl
      rw [e]

theorem hom_z (S : List Row) : Hom (S.map z) := by
  intro r hr
  rcases List.mem_map.mp hr with ⟨q, _, rfl⟩
  rfl

/-- a homogeneous system in n unknowns has exactly 2^(n - rank) solutions. -/
theorem hom_count (n : Nat) (S : List Row) (h : Hom S) :
    cntP n (sat S) = 2 ^ (n - rank n S) := by
  rw [count_eq, cons_hom n S h]; rfl

/-- **Affine systems.** The solutions of a system number 0, or as many as those of the
    homogeneous system with the same coefficients. -/
theorem affine_count (n : Nat) (S : List Row) :
    cntP n (sat S) = 0 ∨ cntP n (sat S) = cntP n (sat (S.map z)) := by
  rw [hom_count n _ (hom_z S), rank_z, count_eq]
  cases cons n S with
  | false => exact Or.inl rfl
  | true => exact Or.inr rfl

/-- m homogeneous conditions on n bits leave at least 2^(n - m) solutions, and the number of
    solutions is a multiple of 2^(n - m). -/
theorem hom_dvd (n : Nat) (S : List Row) (h : Hom S) : 2 ^ (n - S.length) ∣ cntP n (sat S) := by
  rw [hom_count n S h]
  exact Nat.pow_dvd_pow 2 (by have := rank_le_rows n S; omega)

/-! ## §5  translations, and counting orbits -/

/-- x + c, of the length of x (c padded with zeros). -/
def vadd : Vec → Vec → Vec
  | [], _ => []
  | x :: xs, c => (x ^^ c.headD false) :: vadd xs c.tail

theorem dot_vadd : ∀ (a x c : Vec), x.length = c.length →
    dot a (vadd x c) = (dot a x ^^ dot a c)
  | a, [], c, h => by
    have : c = [] := by cases c with
      | nil => rfl
      | cons _ _ => simp at h
    subst this
    simp [vadd, dot_nil]
  | a, x :: xs, [], h => by simp at h
  | a, x :: xs, c :: cs, h => by
    have hl : xs.length = cs.length := by simpa using h
    show dot a ((x ^^ c) :: vadd xs cs) = _
    rw [dot_cons, dot_cons, dot_cons, dot_vadd a.tail xs cs hl]
    generalize dot a.tail xs = p
    generalize dot a.tail cs = q
    cases a.headD false <;> cases x <;> cases c <;> cases p <;> cases q <;> rfl

/-- a translation permutes the vectors of length n, so it does not change a count. -/
theorem cntP_vadd : ∀ (n : Nat) (c : Vec) (q : Vec → Bool),
    cntP n (fun x => q (vadd x c)) = cntP n q
  | 0, _, _ => rfl
  | n+1, c, q => by
    rw [cntP_succ, cntP_succ]
    have h0 : cntP n (fun x => q ((false ^^ c.headD false) :: vadd x c.tail))
        = cntP n (fun y => q ((false ^^ c.headD false) :: y)) :=
      cntP_vadd n c.tail (fun y => q ((false ^^ c.headD false) :: y))
    have h1 : cntP n (fun x => q ((true ^^ c.headD false) :: vadd x c.tail))
        = cntP n (fun y => q ((true ^^ c.headD false) :: y)) :=
      cntP_vadd n c.tail (fun y => q ((true ^^ c.headD false) :: y))
    show cntP n (fun x => q ((false ^^ c.headD false) :: vadd x c.tail))
        + cntP n (fun x => q ((true ^^ c.headD false) :: vadd x c.tail)) = _
    rw [h0, h1]
    cases c.headD false
    · rfl
    · exact Nat.add_comm _ _

/-- the linear map with coefficient rows M. -/
def mulM (M : List Vec) (c : Vec) : Vec := M.map (fun m => dot m c)
/-- c is sent to 0 by M. -/
def ker (M : List Vec) (c : Vec) : Bool := M.all (fun m => !(dot m c))

theorem sat_vadd : ∀ (S : List Row), Hom S → ∀ (c c0 : Vec), c.length = c0.length →
    sat S c0 = true → sat S (vadd c c0) = sat S c
  | [], _, _, _, _, _ => rfl
  | r :: S, hS, c, c0, hl, h0 => by
    rw [sat_cons] at h0
    have h0' := (Bool.and_eq_true _ _).mp h0
    have hr : r.2 = false := hS r List.mem_cons_self
    rw [sat_cons, sat_cons,
      sat_vadd S (fun q hq => hS q (List.mem_cons_of_mem _ hq)) c c0 hl h0'.2]
    have e : rowsat r (vadd c c0) = rowsat r c := by
      have h1 := h0'.1
      unfold rowsat at h1 ⊢
      rw [dot_vadd r.1 c c0 hl]
      rw [hr] at h1 ⊢
      have : dot r.1 c0 = false := by simpa using h1
      rw [this]; simp
    rw [e]

theorem mem_vecs_cons (n : Nat) (b : Bool) (x : Vec) (h : x ∈ vecs n) : (b :: x) ∈ vecs (n+1) :=
  (mem_vecs (n+1) (b :: x)).mpr (by simp [(mem_vecs n x).mp h])

/-- **Orbit counting.** S is a homogeneous system in n unknowns, M a linear map to F_2^N, and Y a
    set of vectors of length N that every translation x ↦ x + M c with c a solution of S maps
    into itself. Then (number of solutions) divides |Y| * (number of solutions c with M c = 0).
    No division and no quotient is used: the solutions with M c = 0 are counted, not divided out. -/
theorem orbit_dvd : ∀ (M : List Vec) (n : Nat) (S : List Row) (Y : Vec → Bool), Hom S →
    (∀ c, c ∈ vecs n → sat S c = true → ∀ x, x ∈ vecs M.length → Y (vadd x (mulM M c)) = Y x) →
    cntP n (sat S) ∣ cntP M.length Y * cntP n (fun c => sat S c && ker M c)
  | [], n, S, Y, _, _ => by
    have e : (fun c => sat S c && ker [] c) = sat S := funext fun c => by simp [ker]
    rw [e]; exact Nat.dvd_mul_left _ _
  | m :: M, n, S, Y, hS, hinv => by
    cases Classical.em (∃ c0, c0 ∈ vecs n ∧ sat S c0 = true ∧ dot m c0 = true) with
    | inr hA =>
      -- every solution has m·c = 0: the first coordinate of the target is never moved
      have hm : ∀ c, c ∈ vecs n → sat S c = true → dot m c = false := fun c hc hs => by
        cases hd : dot m c with
        | false => rfl
        | true => exact absurd ⟨c, hc, hs, hd⟩ hA
      have hK : cntP n (fun c => sat S c && ker (m :: M) c) = cntP n (fun c => sat S c && ker M c) :=
        cntP_congr n _ _ fun c hc => by
          show (sat S c && (!(dot m c) && ker M c)) = (sat S c && ker M c)
          cases hs : sat S c with
          | false => rfl
          | true => rw [hm c hc hs]; rfl
      have ih : ∀ b : Bool, cntP n (sat S) ∣
          cntP M.length (fun x => Y (b :: x)) * cntP n (fun c => sat S c && ker M c) := fun b =>
        orbit_dvd M n S (fun x => Y (b :: x)) hS (fun c hc hs x hx => by
          have h := hinv c hc hs (b :: x) (mem_vecs_cons _ b x hx)
          have e : vadd (b :: x) (mulM (m :: M) c) = (b ^^ dot m c) :: vadd x (mulM M c) := rfl
          rw [e, hm c hc hs] at h
          simpa using h)
      rw [hK]
      show cntP n (sat S) ∣ cntP (M.length + 1) Y * _
      rw [cntP_succ, Nat.add_mul]
      exact Nat.dvd_add (ih false) (ih true)
    | inl hB =>
      -- some solution c0 has m·c0 = 1: it pairs the solutions, and pairs the members of Y
      obtain ⟨c0, hc0, hs0, hd0⟩ := hB
      have hl0 : c0.length = n := (mem_vecs n c0).mp hc0
      have hS1 : Hom ((m, false) :: S) := fun r hr => by
        rcases List.mem_cons.mp hr with e | hr'
        · rw [e]
        · exact hS r hr'
      -- (i) the solutions: twice those with m·c = 0
      have hV : cntP n (sat S) = 2 * cntP n (sat ((m, false) :: S)) := by
        have h1 : cntP n (fun c => !(dot m c) && sat S c) = cntP n (sat ((m, false) :: S)) :=
          cntP_congr n _ _ fun c _ => by
            show (!(dot m c) && sat S c) = ((dot m c == false) && sat S c)
            cases dot m c <;> rfl
        have h2 : cntP n (fun c => dot m c && sat S c) = cntP n (fun c => !(dot m c) && sat S c) := by
          rw [← cntP_vadd n c0 (fun c => dot m c && sat S c)]
          exact cntP_congr n _ _ fun c hc => by
            have hl : c.length = c0.length := by rw [(mem_vecs n c).mp hc, hl0]
            show (dot m (vadd c c0) && sat S (vadd c c0)) = (!(dot m c) && sat S c)
            rw [dot_vadd m c c0 hl, sat_vadd S hS c c0 hl hs0, hd0]
            cases dot m c <;> rfl
        have h3 := cntP_split n (dot m) (sat S)
        rw [h2, h1] at h3
        omega
      -- (ii) Y: twice its members with first coordinate 0
      have hY : cntP (M.length + 1) Y = 2 * cntP M.length (fun x => Y (false :: x)) := by
        rw [cntP_succ]
        have h2 : cntP M.length (fun x => Y (true :: x)) = cntP M.length (fun x => Y (false :: x)) := by
          rw [← cntP_vadd M.length (mulM M c0) (fun y => Y (true :: y))]
          exact cntP_congr _ _ _ fun x hx => by
            have h := hinv c0 hc0 hs0 (false :: x) (mem_vecs_cons _ false x hx)
            have e : vadd (false :: x) (mulM (m :: M) c0)
                = (false ^^ dot m c0) :: vadd x (mulM M c0) := rfl
            rw [e, hd0] at h
            exact h
        rw [h2]; omega
      -- (iii) induction on the rest of M, with the condition m·c = 0 moved into the system
      have ih := orbit_dvd M n ((m, false) :: S) (fun x => Y (false :: x)) hS1
        (fun c hc hs x hx => by
          rw [sat_cons] at hs
          have hs' := (Bool.and_eq_true _ _).mp hs
          have hmc : dot m c = false := by
            have h1 := hs'.1
            unfold rowsat at h1
            simpa using h1
          have h := hinv c hc hs'.2 (false :: x) (mem_vecs_cons _ false x hx)
          have e : vadd (false :: x) (mulM (m :: M) c) = (false ^^ dot m c) :: vadd x (mulM M c) := rfl
          rw [e, hmc] at h
          exact h)
      have hK : (fun c => sat S c && ker (m :: M) c) = (fun c => sat ((m, false) :: S) c && ker M c) :=
        funext fun c => by
          show (sat S c && (!(dot m c) && ker M c)) = (((dot m c == false) && sat S c) && ker M c)
          cases dot m c <;> cases sat S c <;> cases ker M c <;> rfl
      show cntP n (sat S) ∣ cntP (M.length + 1) Y * _
      rw [hV, hY, hK, Nat.mul_assoc]
      exact Nat.mul_dvd_mul_left 2 ih

/-- the conditions "M c = 0" as rows of a system. -/
def rowsOf (M : List Vec) : List Row := M.map (fun m => (m, false))

theorem sat_append : ∀ (S T : List Row) (x : Vec), sat (S ++ T) x = (sat S x && sat T x)
  | [], T, x => rfl
  | r :: S, T, x => by
    rw [List.cons_append, sat_cons, sat_cons, sat_append S T x, Bool.and_assoc]

theorem sat_rowsOf : ∀ (M : List Vec) (c : Vec), sat (rowsOf M) c = ker M c
  | [], _ => rfl
  | m :: M, c => by
    show ((dot m c == false) && sat (rowsOf M) c) = (!(dot m c) && ker M c)
    rw [sat_rowsOf M c]; cases dot m c <;> rfl

theorem hom_append (S T : List Row) (hS : Hom S) (hT : Hom T) : Hom (S ++ T) := by
  intro r hr
  rcases List.mem_append.mp hr with h | h
  · exact hS r h
  · exact hT r h

theorem hom_rowsOf (M : List Vec) : Hom (rowsOf M) := by
  intro r hr
  rcases List.mem_map.mp hr with ⟨q, _, rfl⟩
  rfl

/-- **Families.** n parameter bits; the moves that meet the homogeneous conditions S map Y into
    itself; at most 2^κ of them are the identity (M c = 0). Then 2^(n - #S - κ) divides |Y|. -/
theorem family_dvd (M : List Vec) (n : Nat) (S : List Row) (Y : Vec → Bool) (κ : Nat)
    (hS : Hom S)
    (hinv : ∀ c, c ∈ vecs n → sat S c = true → ∀ x, x ∈ vecs M.length →
      Y (vadd x (mulM M c)) = Y x)
    (hK : cntP n (fun c => sat S c && ker M c) ≤ 2 ^ κ) :
    2 ^ (n - S.length - κ) ∣ cntP M.length Y := by
  have hd := orbit_dvd M n S Y hS hinv
  have hKs : (fun c => sat S c && ker M c) = sat (S ++ rowsOf M) :=
    funext fun c => by rw [sat_append, sat_rowsOf]
  rw [hKs, hom_count n _ (hom_append S _ hS (hom_rowsOf M))] at hK hd
  rw [hom_count n S hS] at hd
  have hb : n - rank n (S ++ rowsOf M) ≤ κ := (Nat.pow_le_pow_iff_right (by decide)).mp hK
  have hr := rank_le_rows n S
  cases Nat.lt_or_ge (n - rank n (S ++ rowsOf M)) (n - rank n S) with
  | inr hab =>
    have e : n - S.length - κ = 0 := by omega
    rw [e, Nat.pow_zero]; exact Nat.one_dvd _
  | inl hab =>
    have e : n - rank n S
        = (n - rank n S - (n - rank n (S ++ rowsOf M))) + (n - rank n (S ++ rowsOf M)) := by omega
    rw [e, Nat.pow_add] at hd
    have h2 := Nat.dvd_of_mul_dvd_mul_right (Nat.two_pow_pos _) hd
    exact Nat.dvd_trans (Nat.pow_dvd_pow 2 (by omega)) h2

/-- **The arithmetic shell of Theorem G+.** 53 parameter bits, at most 20 + t homogeneous
    conditions, at most 2^7 identity choices: 2^(26 - t) divides the size of the invariant set. -/
theorem gplus_shape (M : List Vec) (S : List Row) (Y : Vec → Bool) (t : Nat)
    (hS : Hom S) (hlen : S.length ≤ 20 + t)
    (hinv : ∀ c, c ∈ vecs 53 → sat S c = true → ∀ x, x ∈ vecs M.length →
      Y (vadd x (mulM M c)) = Y x)
    (hK : cntP 53 (fun c => sat S c && ker M c) ≤ 2 ^ 7) :
    2 ^ (26 - t) ∣ cntP M.length Y :=
  Nat.dvd_trans (Nat.pow_dvd_pow 2 (by omega)) (family_dvd M 53 S Y 7 hS hinv hK)

/-- and so 2^13, when t ≤ 13. -/
theorem gplus_shape_13 (M : List Vec) (S : List Row) (Y : Vec → Bool) (t : Nat) (ht : t ≤ 13)
    (hS : Hom S) (hlen : S.length ≤ 20 + t)
    (hinv : ∀ c, c ∈ vecs 53 → sat S c = true → ∀ x, x ∈ vecs M.length →
      Y (vadd x (mulM M c)) = Y x)
    (hK : cntP 53 (fun c => sat S c && ker M c) ≤ 2 ^ 7) :
    2 ^ 13 ∣ cntP M.length Y :=
  Nat.dvd_trans (Nat.pow_dvd_pow 2 (by omega)) (gplus_shape M S Y t hS hlen hinv hK)

/-! ## §6  helpers for the later proof: one-way invariance, the group of translations, the
    bound on the identity choices -/

theorem vadd_length : ∀ (x u : Vec), (vadd x u).length = x.length
  | [], _ => rfl
  | x :: xs, u => by
    show (vadd xs u.tail).length + 1 = xs.length + 1
    rw [vadd_length xs u.tail]

theorem vadd_vadd : ∀ (x u : Vec), x.length = u.length → vadd (vadd x u) u = x
  | [], _, _ => rfl
  | x :: xs, [], h => by simp at h
  | x :: xs, u :: us, h => by
    have hl : xs.length = us.length := by simpa using h
    show ((x ^^ u) ^^ u) :: vadd (vadd xs us) us = x :: xs
    rw [vadd_vadd xs us hl]
    cases x <;> cases u <;> rfl

theorem mulM_length (M : List Vec) (c : Vec) : (mulM M c).length = M.length := by
  unfold mulM; rw [List.length_map]

theorem mulM_vadd : ∀ (M : List Vec) (c c' : Vec), c.length = c'.length →
    mulM M (vadd c c') = vadd (mulM M c) (mulM M c')
  | [], _, _, _ => rfl
  | m :: M, c, c', h => by
    show dot m (vadd c c') :: mulM M (vadd c c')
      = (dot m c ^^ dot m c') :: vadd (mulM M c) (mulM M c')
    rw [dot_vadd m c c' h, mulM_vadd M c c' h]

/-- it is enough to show that the moves map Y INTO itself (a translation is its own inverse). -/
theorem inv_of_imp (M : List Vec) (n : Nat) (S : List Row) (Y : Vec → Bool)
    (h : ∀ c, c ∈ vecs n → sat S c = true → ∀ x, x ∈ vecs M.length → Y x = true →
      Y (vadd x (mulM M c)) = true) :
    ∀ c, c ∈ vecs n → sat S c = true → ∀ x, x ∈ vecs M.length →
      Y (vadd x (mulM M c)) = Y x := by
  intro c hc hs x hx
  have hl : x.length = (mulM M c).length := by rw [mulM_length, (mem_vecs _ x).mp hx]
  cases hY : Y x with
  | true => exact h c hc hs x hx hY
  | false =>
    cases hY' : Y (vadd x (mulM M c)) with
    | false => rfl
    | true =>
      have hx' : vadd x (mulM M c) ∈ vecs M.length :=
        (mem_vecs _ _).mpr (by rw [vadd_length, (mem_vecs _ x).mp hx])
      have h2 := h c hc hs _ hx' hY'
      rw [vadd_vadd x _ hl, hY] at h2
      exact absurd h2 (by decide)

/-- some solution has m·c = 1: exactly half of the solutions have m·c = 0. -/
theorem half_sols (n : Nat) (S : List Row) (m c0 : Vec) (hS : Hom S) (hc0 : c0 ∈ vecs n)
    (hs0 : sat S c0 = true) (hd0 : dot m c0 = true) :
    cntP n (sat S) = 2 * cntP n (sat ((m, false) :: S)) := by
  have hl0 : c0.length = n := (mem_vecs n c0).mp hc0
  have h1 : cntP n (fun c => !(dot m c) && sat S c) = cntP n (sat ((m, false) :: S)) :=
    cntP_congr n _ _ fun c _ => by
      show (!(dot m c) && sat S c) = ((dot m c == false) && sat S c)
      cases dot m c <;> rfl
  have h2 : cntP n (fun c => dot m c && sat S c) = cntP n (fun c => !(dot m c) && sat S c) := by
    rw [← cntP_vadd n c0 (fun c => dot m c && sat S c)]
    exact cntP_congr n _ _ fun c hc => by
      have hl : c.length = c0.length := by rw [(mem_vecs n c).mp hc, hl0]
      show (dot m (vadd c c0) && sat S (vadd c c0)) = (!(dot m c) && sat S c)
      rw [dot_vadd m c c0 hl, sat_vadd S hS c c0 hl hs0, hd0]
      cases dot m c <;> rfl
  have h3 := cntP_split n (dot m) (sat S)
  rw [h2, h1] at h3
  omega

/-- every solution has m·c = 0: the row m changes nothing. -/
theorem all_sols (n : Nat) (S : List Row) (m : Vec)
    (hm : ∀ c, c ∈ vecs n → sat S c = true → dot m c = false) :
    cntP n (sat S) = cntP n (sat ((m, false) :: S)) :=
  cntP_congr n _ _ fun c hc => by
    show sat S c = ((dot m c == false) && sat S c)
    cases hs : sat S c with
    | false => cases dot m c <;> rfl
    | true => rw [hm c hc hs]; rfl

/-- one more homogeneous condition keeps all the solutions or exactly half of them. -/
theorem hom_add_row (n : Nat) (S : List Row) (m : Vec) (hS : Hom S) :
    cntP n (sat S) = cntP n (sat ((m, false) :: S)) ∨
      cntP n (sat S) = 2 * cntP n (sat ((m, false) :: S)) := by
  cases Classical.em (∃ c0, c0 ∈ vecs n ∧ sat S c0 = true ∧ dot m c0 = true) with
  | inl hB =>
    obtain ⟨c0, hc0, hs0, hd0⟩ := hB
    exact Or.inr (half_sols n S m c0 hS hc0 hs0 hd0)
  | inr hA =>
    exact Or.inl (all_sols n S m fun c hc hs => by
      cases hd : dot m c with
      | false => rfl
      | true => exact absurd ⟨c, hc, hs, hd⟩ hA)

/-- κ more conditions cost at most a factor 2^κ. -/
theorem hom_add_rows_le (n : Nat) : ∀ (T S : List Row), Hom T → Hom S →
    cntP n (sat S) ≤ 2 ^ T.length * cntP n (sat (T ++ S))
  | [], S, _, _ => by
    show cntP n (sat S) ≤ 2 ^ 0 * cntP n (sat S)
    rw [Nat.pow_zero, Nat.one_mul]; exact Nat.le_refl _
  | (a, b) :: T, S, hT, hS => by
    have hb : b = false := hT (a, b) List.mem_cons_self
    subst hb
    have hT' : Hom T := fun q hq => hT q (List.mem_cons_of_mem _ hq)
    have ih := hom_add_rows_le n T S hT' hS
    have h1 := hom_add_row n (T ++ S) a (hom_append T S hT' hS)
    have h2 : cntP n (sat (T ++ S)) ≤ 2 * cntP n (sat ((a, false) :: (T ++ S))) := by omega
    show cntP n (sat S) ≤ 2 ^ (T.length + 1) * cntP n (sat ((a, false) :: (T ++ S)))
    rw [Nat.pow_succ, Nat.mul_assoc]
    exact Nat.le_trans ih (Nat.mul_le_mul_left _ h2)

/-- a property that at most one vector has. -/
theorem cntP_le_one (n : Nat) (p : Vec → Bool)
    (h : ∀ c c', c ∈ vecs n → c' ∈ vecs n → p c = true → p c' = true → c = c') :
    cntP n p ≤ 1 := by
  have nd : ((vecs n).filter p).Nodup := List.Nodup.sublist List.filter_sublist (vecs_nodup n)
  have hmem : ∀ a, a ∈ (vecs n).filter p → a ∈ vecs n ∧ p a = true :=
    fun a ha => List.mem_filter.mp ha
  unfold cntP
  generalize (vecs n).filter p = L at nd hmem
  cases L with
  | nil => exact Nat.zero_le _
  | cons a L' =>
    cases L' with
    | nil => exact Nat.le_refl _
    | cons b L'' =>
      have ha := hmem a List.mem_cons_self
      have hb := hmem b (List.mem_cons_of_mem _ List.mem_cons_self)
      have e := h a b ha.1 hb.1 ha.2 hb.2
      subst e
      rw [List.nodup_cons] at nd
      exact absurd List.mem_cons_self nd.1

/-- **Bound on the identity choices.** If κ further homogeneous conditions T leave at most one
    solution of S, then S has at most 2^κ solutions. -/
theorem ker_bound (n : Nat) (S T : List Row) (hS : Hom S) (hT : Hom T)
    (huniq : ∀ c c', c ∈ vecs n → c' ∈ vecs n → sat (T ++ S) c = true → sat (T ++ S) c' = true →
      c = c') :
    cntP n (sat S) ≤ 2 ^ T.length := by
  have h1 := hom_add_rows_le n T S hT hS
  have h2 := cntP_le_one n (sat (T ++ S)) huniq
  exact Nat.le_trans h1 (by
    have := Nat.mul_le_mul_left (2 ^ T.length) h2
    rw [Nat.mul_one] at this; exact this)

/-- the row "bit i". -/
def unit (i : Nat) : Vec := List.replicate i false ++ [true]

theorem dot_unit : ∀ (i : Nat) (c : Vec), dot (unit i) c = c.getD i false
  | 0, [] => rfl
  | 0, b :: x => by
    show ((true && b) ^^ dot [] x) = b
    cases b <;> rfl
  | i+1, [] => rfl
  | i+1, b :: x => by
    show ((false && b) ^^ dot (unit i) x) = x.getD i false
    rw [dot_unit i x]
    cases x.getD i false <;> rfl

/-- the translations x ↦ x + M c, c a solution of S: y is one of them. -/
def img (M : List Vec) (n : Nat) (S : List Row) (y : Vec) : Bool :=
  (vecs n).any (fun c => sat S c && (mulM M c == y))

theorem any_congr_mem {α : Type} (f g : α → Bool) : ∀ l : List α,
    (∀ a, a ∈ l → f a = g a) → l.any f = l.any g
  | [], _ => rfl
  | a :: l, h => by
    rw [List.any_cons, List.any_cons, h a List.mem_cons_self,
      any_congr_mem f g l (fun b hb => h b (List.mem_cons_of_mem _ hb))]

theorem any_false {α : Type} : ∀ l : List α, l.any (fun _ => false) = false
  | [] => rfl
  | _ :: l => any_false l

theorem filter_len_any_false {α : Type} (p : α → Bool) : ∀ l : List α,
    l.any p = false → (l.filter p).length = 0
  | [], _ => rfl
  | a :: l, h => by
    rw [List.any_cons] at h
    cases hp : p a with
    | true => rw [hp] at h; simp at h
    | false =>
      rw [hp] at h
      rw [List.filter_cons, hp]
      simp only [Bool.false_eq_true, if_false]
      exact filter_len_any_false p l (by simpa using h)

theorem img_inv (M : List Vec) (n : Nat) (S : List Row) (hS : Hom S) :
    ∀ c, c ∈ vecs n → sat S c = true → ∀ y, y ∈ vecs M.length →
      img M n S (vadd y (mulM M c)) = img M n S y :=
  inv_of_imp M n S (img M n S) (fun c hc hs y _ hy => by
    unfold img at hy ⊢
    rw [List.any_eq_true] at hy ⊢
    obtain ⟨c1, hc1, h1⟩ := hy
    have h1' := (Bool.and_eq_true _ _).mp h1
    have hl : c1.length = c.length := by rw [(mem_vecs n c1).mp hc1, (mem_vecs n c).mp hc]
    refine ⟨vadd c1 c, (mem_vecs n _).mpr (by rw [vadd_length, (mem_vecs n c1).mp hc1]), ?_⟩
    rw [sat_vadd S hS c1 c hl hs, h1'.1, mulM_vadd M c1 c hl, eq_of_beq h1'.2]
    simp)

/-- **The group of translations has exactly (solutions) / (identity choices) members**,
    stated without division. -/
theorem img_count : ∀ (M : List Vec) (n : Nat) (S : List Row), Hom S →
    cntP n (sat S) = cntP M.length (img M n S) * cntP n (fun c => sat S c && ker M c)
  | [], n, S, _ => by
    have eK : (fun c => sat S c && ker [] c) = sat S := funext fun c => by simp [ker]
    rw [eK]
    show cntP n (sat S) = cntP 0 (img [] n S) * cntP n (sat S)
    have e0 : cntP 0 (img [] n S) = if img [] n S [] then 1 else 0 := by
      simp only [cntP, vecs, List.filter_cons, List.filter_nil]
      cases img [] n S [] <;> rfl
    rw [e0]
    cases hi : img [] n S [] with
    | true => simp
    | false =>
      have h0 : cntP n (sat S) = 0 := filter_len_any_false (sat S) (vecs n) (by
        rw [← hi]; unfold img
        exact any_congr_mem _ _ _ (fun c _ => by simp [mulM]))
      rw [h0]; rfl
  | m :: M, n, S, hS => by
    cases Classical.em (∃ c0, c0 ∈ vecs n ∧ sat S c0 = true ∧ dot m c0 = true) with
    | inr hA =>
      have hm : ∀ c, c ∈ vecs n → sat S c = true → dot m c = false := fun c hc hs => by
        cases hd : dot m c with
        | false => rfl
        | true => exact absurd ⟨c, hc, hs, hd⟩ hA
      have hK : cntP n (fun c => sat S c && ker (m :: M) c) = cntP n (fun c => sat S c && ker M c) :=
        cntP_congr n _ _ fun c hc => by
          show (sat S c && (!(dot m c) && ker M c)) = (sat S c && ker M c)
          cases hs : sat S c with
          | false => rfl
          | true => rw [hm c hc hs]; rfl
      have e0 : cntP M.length (fun y => img (m :: M) n S (false :: y)) = cntP M.length (img M n S) :=
        cntP_congr _ _ _ fun y _ => any_congr_mem _ _ _ fun c hc => by
          show (sat S c && ((dot m c :: mulM M c) == (false :: y))) = (sat S c && (mulM M c == y))
          cases hs : sat S c with
          | false => rfl
          | true => rw [hm c hc hs]; rfl
      have e1 : cntP M.length (fun y => img (m :: M) n S (true :: y)) = 0 := by
        have e : cntP M.length (fun y => img (m :: M) n S (true :: y))
            = cntP M.length (fun _ => false) :=
          cntP_congr _ _ _ fun y _ => by
            show (vecs n).any (fun c => sat S c && ((dot m c :: mulM M c) == (true :: y))) = false
            rw [any_congr_mem _ (fun _ => false) (vecs n) (fun c hc => by
              cases hs : sat S c with
              | false => rfl
              | true => rw [hm c hc hs]; rfl)]
            exact any_false _
        rw [e]
        exact filter_len_any_false _ _ (any_false _)
      show cntP n (sat S) = cntP (M.length + 1) (img (m :: M) n S) * _
      rw [hK, cntP_succ, e0, e1, Nat.add_zero]
      exact img_count M n S hS
    | inl hB =>
      obtain ⟨c0, hc0, hs0, hd0⟩ := hB
      have hS1 : Hom ((m, false) :: S) := fun r hr => by
        rcases List.mem_cons.mp hr with e | hr'
        · rw [e]
        · exact hS r hr'
      have hV := half_sols n S m c0 hS hc0 hs0 hd0
      have hI : cntP (M.length + 1) (img (m :: M) n S)
          = 2 * cntP M.length (fun y => img (m :: M) n S (false :: y)) := by
        rw [cntP_succ]
        have h2 : cntP M.length (fun y => img (m :: M) n S (true :: y))
            = cntP M.length (fun y => img (m :: M) n S (false :: y)) := by
          rw [← cntP_vadd M.length (mulM M c0) (fun y => img (m :: M) n S (true :: y))]
          exact cntP_congr _ _ _ fun y hy => by
            have h := img_inv (m :: M) n S hS c0 hc0 hs0 (false :: y) (mem_vecs_cons _ false y hy)
            have e : vadd (false :: y) (mulM (m :: M) c0)
                = (false ^^ dot m c0) :: vadd y (mulM M c0) := rfl
            rw [e, hd0] at h
            exact h
        rw [h2]; omega
      have e0 : cntP M.length (fun y => img (m :: M) n S (false :: y))
          = cntP M.length (img M n ((m, false) :: S)) :=
        cntP_congr _ _ _ fun y _ => any_congr_mem _ _ _ fun c _ => by
          show (sat S c && ((dot m c :: mulM M c) == (false :: y)))
            = (((dot m c == false) && sat S c) && (mulM M c == y))
          cases dot m c <;> cases sat S c <;> rfl
      have hK : (fun c => sat S c && ker (m :: M) c) = (fun c => sat ((m, false) :: S) c && ker M c) :=
        funext fun c => by
          show (sat S c && (!(dot m c) && ker M c)) = (((dot m c == false) && sat S c) && ker M c)
          cases dot m c <;> cases sat S c <;> cases ker M c <;> rfl
      show cntP n (sat S) = cntP (M.length + 1) (img (m :: M) n S) * _
      rw [hV, hI, e0, hK, img_count M n _ hS1, Nat.mul_assoc]

/-- **The family.** Under the hypotheses of `family_dvd` (the invariance is not needed for the
    count), the translations x ↦ x + M c number exactly 2^d with d ≥ n - #S - κ. -/
theorem family_size (M : List Vec) (n : Nat) (S : List Row) (κ : Nat) (hS : Hom S)
    (hK : cntP n (fun c => sat S c && ker M c) ≤ 2 ^ κ) :
    ∃ d, n - S.length - κ ≤ d ∧ cntP M.length (img M n S) = 2 ^ d := by
  have hc := img_count M n S hS
  have hKs : (fun c => sat S c && ker M c) = sat (S ++ rowsOf M) :=
    funext fun c => by rw [sat_append, sat_rowsOf]
  rw [hKs, hom_count n _ (hom_append S _ hS (hom_rowsOf M))] at hK hc
  rw [hom_count n S hS] at hc
  have hb : n - rank n (S ++ rowsOf M) ≤ κ := (Nat.pow_le_pow_iff_right (by decide)).mp hK
  have hr := rank_le_rows n S
  have hab : n - rank n (S ++ rowsOf M) ≤ n - rank n S := by
    cases Nat.lt_or_ge (n - rank n S) (n - rank n (S ++ rowsOf M)) with
    | inr h => exact h
    | inl h =>
      have h1 : 2 ^ (n - rank n S) < 2 ^ (n - rank n (S ++ rowsOf M)) :=
        Nat.pow_lt_pow_right (by decide) h
      have hI : 0 < cntP M.length (img M n S) := by
        cases Nat.eq_zero_or_pos (cntP M.length (img M n S)) with
        | inr h => exact h
        | inl h0 =>
          rw [h0, Nat.zero_mul] at hc
          exact absurd hc (Nat.ne_of_gt (Nat.two_pow_pos _))
      have h2 : 2 ^ (n - rank n (S ++ rowsOf M))
          ≤ cntP M.length (img M n S) * 2 ^ (n - rank n (S ++ rowsOf M)) :=
        Nat.le_mul_of_pos_left _ hI
      rw [← hc] at h2
      exact absurd h1 (Nat.not_lt.mpr h2)
  refine ⟨n - rank n S - (n - rank n (S ++ rowsOf M)), by omega, ?_⟩
  have e : n - rank n S
      = (n - rank n S - (n - rank n (S ++ rowsOf M))) + (n - rank n (S ++ rowsOf M)) := by omega
  rw [e, Nat.pow_add] at hc
  exact (Nat.eq_of_mul_eq_mul_right (Nat.two_pow_pos _) hc).symm

end F2Count

/-
  §36  controls for §35 (kernel `decide`)

  Every "must fail" claim is stated as a theorem that the claim is FALSE.
-/
namespace F2Count

/-! ### the count on concrete systems (brute force by the kernel against the formula) -/

/-- one row x0 + x1 = 1 in 3 unknowns: 4 solutions. -/
theorem ctl_one_row : cntP 3 (sat [([true, true, false], true)]) = 4 := by decide +kernel

/-- three dependent rows (x0+x1, x1+x2, x0+x2, all = 0): rank 2, not 3. -/
def depS : List Row :=
  [([true, true, false], false), ([false, true, true], false), ([true, false, true], false)]
theorem ctl_dep_rank : rank 3 depS = 2 := by decide +kernel
theorem ctl_dep_count : cntP 3 (sat depS) = 2 := by decide +kernel
/-- must fail: "2^(n - number of rows)" is NOT the count; the rank is needed. -/
theorem ctl_rows_is_not_rank : cntP 3 (sat depS) ≠ 2 ^ (3 - depS.length) := by decide +kernel

/-- the same coefficients with right-hand sides 0, 0, 1: inconsistent, no solution;
    the rank is the same. -/
def badS : List Row :=
  [([true, true, false], false), ([false, true, true], false), ([true, false, true], true)]
theorem ctl_bad_cons : cons 3 badS = false := by decide +kernel
theorem ctl_bad_count : cntP 3 (sat badS) = 0 := by decide +kernel
theorem ctl_bad_rank : rank 3 badS = 2 := by decide +kernel
theorem ctl_bad_z : badS.map z = depS := by decide +kernel
/-- must fail: an inconsistent system does NOT have 2^(n - rank) solutions. -/
theorem ctl_cons_needed : cntP 3 (sat badS) ≠ 2 ^ (3 - rank 3 badS) := by decide +kernel

/-- a consistent affine system (right-hand sides 1, 1, 0): as many solutions as the homogeneous one. -/
def affS : List Row :=
  [([true, true, false], true), ([false, true, true], true), ([true, false, true], false)]
theorem ctl_aff_count : cntP 3 (sat affS) = 2 := by decide +kernel
theorem ctl_aff_cons : cons 3 affS = true := by decide +kernel

/-- a 10-unknown system, 6 rows of which 5 independent (row 6 = row 1 + row 2), rows of mixed
    lengths (short rows are padded): 2^5 solutions, counted by brute force over 1024 vectors. -/
def S10 : List Row :=
  [([true, false, true, true, false, false, true, false, false, true], false),
   ([false, true, true, false, false, true, false, false, true, true], false),
   ([false, false, false, true, true, true], false),
   ([true, true, true, true, true, true, true, true, true, true], false),
   ([false, false, false, false, false, false, false, false, false, true], false),
   ([true, true, false, true, false, true, true, false, true, false], false)]
theorem ctl_S10_rank : rank 10 S10 = 5 := by decide +kernel
theorem ctl_S10_brute : cntP 10 (sat S10) = 32 := by decide +kernel
/-- the theorem applied, against the brute-force count. -/
theorem ctl_S10_thm : cntP 10 (sat S10) = 2 ^ (10 - 5) := by
  have h := hom_count 10 S10 (by decide +kernel)
  rw [ctl_S10_rank] at h; exact h

/-- `vecs n` is the full cube: 2^n members, here n = 10. -/
theorem ctl_vecs10 : (vecs 10).length = 1024 := by decide +kernel
/-- `cntP` of the always-true property is 2^n. -/
theorem ctl_all : cntP 5 (fun _ => true) = 32 := by decide +kernel

/-! ### orbit counting -/

def par : Vec → Bool
  | [] => false
  | b :: x => b ^^ par x
/-- the vectors of even weight. -/
def evenY (x : Vec) : Bool := !(par x)
/-- c ↦ (c0, c0 + c1, c1): the translations by 000, 110, 011, 101. -/
def M32 : List Vec := [[true, false], [true, true], [false, true]]

theorem ctl_inv : ∀ c, c ∈ vecs 2 → sat [] c = true → ∀ x, x ∈ vecs M32.length →
    evenY (vadd x (mulM M32 c)) = evenY x := by decide +kernel
/-- the theorem applied: 4 divides the number of even-weight vectors of length 3. -/
theorem ctl_family : 2 ^ (2 - 0 - 0) ∣ cntP 3 evenY :=
  family_dvd M32 2 [] evenY 0 (by intro r hr; cases hr) ctl_inv (by decide +kernel)
/-- and the bound is attained there: exactly 4. -/
theorem ctl_family_exact : cntP 3 evenY = 4 := by decide +kernel
theorem ctl_img : cntP 3 (img M32 2 []) = 4 := by decide +kernel

/-- must fail: a set that is not invariant. The hypothesis fails ... -/
def oneY (x : Vec) : Bool := x == [false, false, false]
theorem ctl_one_not_inv : ¬ (∀ c, c ∈ vecs 2 → sat [] c = true → ∀ x, x ∈ vecs M32.length →
    oneY (vadd x (mulM M32 c)) = oneY x) := by decide +kernel
/-- ... and so does the conclusion: the invariance hypothesis is doing work. -/
theorem ctl_one_not_dvd : ¬ (2 ^ (2 - 0 - 0) ∣ cntP 3 oneY) := by decide +kernel

/-- must fail: without the count of identity choices the divisibility is FALSE.
    c ↦ c0 + c1 from F_2^2 to F_2^1, Y everything: 4 solutions, |Y| = 2. -/
theorem ctl_kernel_needed : ¬ (cntP 2 (sat []) ∣ cntP 1 (fun _ => true)) := by decide +kernel
theorem ctl_kernel_count : cntP 2 (fun c => sat [] c && ker [[true, true]] c) = 2 := by decide +kernel
theorem ctl_kernel_img : cntP 1 (img [[true, true]] 2 []) = 2 := by decide +kernel
/-- with it, the statement holds with equality: 4 ∣ 2 * 2. -/
theorem ctl_kernel_thm : cntP 2 (sat []) ∣ cntP 1 (fun _ => true) * cntP 2 (fun c => sat [] c && ker [[true, true]] c) :=
  orbit_dvd [[true, true]] 2 [] (fun _ => true) (by intro r hr; cases hr) (fun _ _ _ _ _ => rfl)

/-- a condition in play: S = {c0 + c1 = 0}, M32. The moves are 000 and 101; the set
    {x : x1 = 0} is invariant under them but not under all four translations. -/
def S1 : List Row := [([true, true], false)]
def midY (x : Vec) : Bool := !(x.getD 1 false)
theorem ctl_cond_inv : ∀ c, c ∈ vecs 2 → sat S1 c = true → ∀ x, x ∈ vecs M32.length →
    midY (vadd x (mulM M32 c)) = midY x := by decide +kernel
theorem ctl_cond_not_inv_without : ¬ (∀ c, c ∈ vecs 2 → sat [] c = true → ∀ x, x ∈ vecs M32.length →
    midY (vadd x (mulM M32 c)) = midY x) := by decide +kernel
theorem ctl_cond_family : 2 ^ (2 - 1 - 0) ∣ cntP 3 midY :=
  family_dvd M32 2 S1 midY 0 (by decide +kernel) ctl_cond_inv (by decide +kernel)
theorem ctl_cond_img : cntP 3 (img M32 2 S1) = 2 := by decide +kernel

/-! ### the bound on the identity choices -/

/-- c ↦ c0 + c1 has 2 identity choices; one more condition (bit 0) leaves only 0. -/
theorem ctl_ker_bound : cntP 2 (sat (rowsOf [[true, true]])) ≤ 2 ^ 1 :=
  ker_bound 2 (rowsOf [[true, true]]) [(unit 0, false)] (hom_rowsOf _) (by decide +kernel)
    (fun c c' hc hc' => (show ∀ c, c ∈ vecs 2 → ∀ c', c' ∈ vecs 2 →
        sat ([(unit 0, false)] ++ rowsOf [[true, true]]) c = true →
        sat ([(unit 0, false)] ++ rowsOf [[true, true]]) c' = true → c = c' from by decide +kernel)
      c hc c' hc')

/-! ### the G+ shell is not vacuous at n = 53 -/

/-- the map "first 46 of 53 bits". -/
def M46 : List Vec := (List.range 46).map unit
theorem ctl_M46_rank : rank 53 (rowsOf M46) = 46 := by decide +kernel

/-- the three hypotheses of `gplus_shape` hold together for a 53-bit instance (no conditions,
    Y everything, 2^7 identity choices), so the theorem is not vacuous for n = 53, κ = 7. -/
theorem ctl_gplus_nonvacuous : 2 ^ (26 - 0) ∣ cntP M46.length (fun _ => true) :=
  gplus_shape M46 [] (fun _ => true) 0 (by intro r hr; cases hr) (by decide)
    (fun _ _ _ _ _ => rfl)
    (by
      have e : (fun c => sat [] c && ker M46 c) = sat (rowsOf M46) :=
        funext fun c => by rw [sat_rowsOf]; rfl
      rw [e, hom_count 53 _ (hom_rowsOf M46), ctl_M46_rank]
      exact Nat.le_refl _)

end F2Count

/-
  §37  from sums over assignments to counts of bit vectors

    bridge     : sumOver K (indicator of F) t = cntP (3 * |K|) (fun x => F (wr K x t))
  So the coordinate-model fibre `fibreC σ cl` of §14 is a count of 93-bit vectors (three bits
  for each of the slots 1..31); see `fibre_eq` in §41.
-/
namespace Q1150
open SuperspaceDivisibility F2Count

/-- three bits as a value 0..7 (the first bit is the 4s place). -/
def val3 (b0 b1 b2 : Bool) : Nat :=
  (if b0 then 4 else 0) + (if b1 then 2 else 0) + (if b2 then 1 else 0)

/-- write the bits of x, three at a time, into the slots of K. -/
def wr : List Nat → Vec → Asg → Asg
  | [], _, t => t
  | k :: K, x, t =>
    wr K (x.drop 3) (upd t k (val3 (x.getD 0 false) (x.getD 1 false) (x.getD 2 false)))

theorem cntP3 (n : Nat) (p : Vec → Bool) :
    cntP (n + 3) p =
      cntP n (fun x => p (false :: false :: false :: x)) +
      cntP n (fun x => p (false :: false :: true :: x)) +
      cntP n (fun x => p (false :: true :: false :: x)) +
      cntP n (fun x => p (false :: true :: true :: x)) +
      cntP n (fun x => p (true :: false :: false :: x)) +
      cntP n (fun x => p (true :: false :: true :: x)) +
      cntP n (fun x => p (true :: true :: false :: x)) +
      cntP n (fun x => p (true :: true :: true :: x)) := by
  show cntP (n + 1 + 1 + 1) p = _
  rw [cntP_succ (n + 1 + 1), cntP_succ (n + 1), cntP_succ (n + 1),
    cntP_succ n, cntP_succ n, cntP_succ n, cntP_succ n]
  omega

/-- **The bridge.** A sum of a 0/1 indicator over all assignments to the slots K is a count of
    bit vectors of length 3 * |K|. -/
theorem bridge : ∀ (K : List Nat) (F : Asg → Bool) (t : Asg),
    sumOver K (fun a => if F a then (1 : Int) else 0) t
      = ((cntP (3 * K.length) (fun x => F (wr K x t)) : Nat) : Int)
  | [], F, t => by
    show (if F t then (1 : Int) else 0) = ((cntP 0 (fun _ => F t) : Nat) : Int)
    simp only [cntP, vecs, List.filter_cons, List.filter_nil]
    cases F t <;> rfl
  | k :: K, F, t => by
    show sum8 (fun v => sumOver K (fun a => if F a then (1 : Int) else 0) (upd t k v))
      = ((cntP (3 * K.length + 3) (fun x => F (wr (k :: K) x t)) : Nat) : Int)
    rw [cntP3]
    simp only [sum8, bridge K F, Int.natCast_add]
    rfl

end Q1150

/-
  §38  the finite steps ("the local lemma"), each by kernel `decide` over every case

  A boundary joins a slot with support s and coordinate t to a slot with support s' and
  coordinate t'; its class is `ham (partner (hexof s t)) (hexof s' t')`. A move changes t by d
  and t' by d'. m = 7 xor (s xor s') is the set of compared coordinates.
-/
namespace Q1150
open SuperspaceDivisibility

-- instance search for six nested bounded quantifiers needs more room than the default
section GPLocalOpts
set_option synthInstance.maxSize 4096
set_option synthInstance.maxHeartbeats 0

theorem xor_lt8 : ∀ x < 8, ∀ y < 8, x ^^^ y < 8 := by decide
theorem st_lt : ∀ s < 8, st s < 8 := by decide

/-- the three-bit core of the local lemma: a change that vanishes on m keeps the weight on m. -/
theorem f3 : ∀ m < 8, ∀ x < 8, ∀ δ < 8, δ &&& m = 0 → pc3 ((x ^^^ δ) &&& m) = pc3 (x &&& m) := by
  decide +kernel

/-- class 3 (4,096 cases): a change that is 0 or all of m on m keeps class 3. -/
theorem f3c : ∀ s < 8, ∀ s' < 8, ∀ x < 8, ∀ δ < 8,
    pc3 (s ^^^ s') + 2 * pc3 (x &&& (7 ^^^ (s ^^^ s'))) = 3 →
    (δ &&& (7 ^^^ (s ^^^ s')) = 0 ∨ δ &&& (7 ^^^ (s ^^^ s')) = 7 ^^^ (s ^^^ s')) →
    pc3 (s ^^^ s') + 2 * pc3 ((x ^^^ δ) &&& (7 ^^^ (s ^^^ s'))) = 3 := by decide +kernel

/-- regrouping (32,768 cases). -/
theorem xr : ∀ t < 8, ∀ t' < 8, ∀ d < 8, ∀ d' < 8, ∀ q < 8,
    ((t ^^^ d) ^^^ (t' ^^^ d')) ^^^ q = ((t ^^^ t') ^^^ q) ^^^ (d ^^^ d') := by decide +kernel

/-- a change that vanishes on the compared coordinates keeps the class. Every case, through
    `class_formula` (4,096 cases at hexagram level) and `f3`.
    (Covers: class 1, cross classes 2 and 4, class 3 with three differing coordinates where
    m = 0, and internal boundaries, where it says d = d'.) -/
theorem loc_cross (s : Nat) (hs : s < 8) (s' : Nat) (hs' : s' < 8) (t : Nat) (ht : t < 8)
    (t' : Nat) (ht' : t' < 8) (d : Nat) (hd : d < 8) (d' : Nat) (hd' : d' < 8)
    (h : (d ^^^ d') &&& (7 ^^^ (s ^^^ s')) = 0) :
    ham (partner (hexof s (t ^^^ d))) (hexof s' (t' ^^^ d')) =
      ham (partner (hexof s t)) (hexof s' t') := by
  rw [class_formula s hs s' hs' (t ^^^ d) (xor_lt8 t ht d hd) (t' ^^^ d') (xor_lt8 t' ht' d' hd'),
    class_formula s hs s' hs' t ht t' ht', xr t ht t' ht' d hd d' hd' (st s) (st_lt s hs),
    f3 (7 ^^^ (s ^^^ s')) (xor_lt8 7 (by decide) _ (xor_lt8 s hs s' hs')) ((t ^^^ t') ^^^ st s)
      (xor_lt8 _ (xor_lt8 t ht t' ht') _ (st_lt s hs)) (d ^^^ d') (xor_lt8 d hd d' hd') h]

/-- class 3: a change that is 0 or everything on the compared coordinates keeps class 3. -/
theorem loc_c3 (s : Nat) (hs : s < 8) (s' : Nat) (hs' : s' < 8) (t : Nat) (ht : t < 8)
    (t' : Nat) (ht' : t' < 8) (d : Nat) (hd : d < 8) (d' : Nat) (hd' : d' < 8)
    (h3 : ham (partner (hexof s t)) (hexof s' t') = 3)
    (h : (d ^^^ d') &&& (7 ^^^ (s ^^^ s')) = 0 ∨
      (d ^^^ d') &&& (7 ^^^ (s ^^^ s')) = 7 ^^^ (s ^^^ s')) :
    ham (partner (hexof s (t ^^^ d))) (hexof s' (t' ^^^ d')) = 3 := by
  rw [class_formula s hs s' hs' t ht t' ht'] at h3
  rw [class_formula s hs s' hs' (t ^^^ d) (xor_lt8 t ht d hd) (t' ^^^ d') (xor_lt8 t' ht' d' hd'),
    xr t ht t' ht' d hd d' hd' (st s) (st_lt s hs)]
  exact f3c s hs s' hs' ((t ^^^ t') ^^^ st s) (xor_lt8 _ (xor_lt8 t ht t' ht') _ (st_lt s hs))
    (d ^^^ d') (xor_lt8 d hd d' hd') h3 h

/-- the vector u of the third-slot rule. -/
def uu (s : Nat) : Nat := if pc3 s = 2 then s else 7 ^^^ s

/-- third-slot rule, the third slot first: t' is the coordinate of a class-6 slot, whose partner
    slot holds t' xor st s xor 7; t is in neither pair. A change in {0, u} keeps the class. -/
theorem loc_third_a : ∀ s < 8, ∀ t < 8, ∀ t' < 8, ∀ d < 8, ∀ d' < 8,
    (pc3 s = 1 ∨ pc3 s = 2) →
    samePair (hexof s t) (hexof s t') = false →
    samePair (hexof s t) (hexof s (t' ^^^ st s ^^^ 7)) = false →
    (d ^^^ d' = 0 ∨ d ^^^ d' = uu s) →
    ham (partner (hexof s (t ^^^ d))) (hexof s (t' ^^^ d')) =
      ham (partner (hexof s t)) (hexof s t') := by decide +kernel

/-- third-slot rule, the class-6 slot first. -/
theorem loc_third_b : ∀ s < 8, ∀ t < 8, ∀ t' < 8, ∀ d < 8, ∀ d' < 8,
    (pc3 s = 1 ∨ pc3 s = 2) →
    samePair (hexof s t) (hexof s t') = false →
    samePair (hexof s (t ^^^ st s ^^^ 7)) (hexof s t') = false →
    (d ^^^ d' = 0 ∨ d ^^^ d' = uu s) →
    ham (partner (hexof s (t ^^^ d))) (hexof s (t' ^^^ d')) =
      ham (partner (hexof s t)) (hexof s t') := by decide +kernel

/-- must fail: the third-slot rule is false without "t is in neither pair". -/
theorem loc_third_needs_hyp : ¬ (∀ s < 8, ∀ t < 8, ∀ t' < 8, ∀ d < 8, ∀ d' < 8,
    (pc3 s = 1 ∨ pc3 s = 2) →
    samePair (hexof s t) (hexof s t') = false →
    (d ^^^ d' = 0 ∨ d ^^^ d' = uu s) →
    ham (partner (hexof s (t ^^^ d))) (hexof s (t' ^^^ d')) =
      ham (partner (hexof s t)) (hexof s t')) := by decide +kernel

/-- must fail: an arbitrary change does not keep the weight on m. -/
theorem f3_needs_hyp : ¬ (∀ m < 8, ∀ x < 8, ∀ δ < 8, pc3 ((x ^^^ δ) &&& m) = pc3 (x &&& m)) := by
  decide +kernel

/-- a class-6 step: equal supports, and the two coordinates differ by st s xor 7. -/
theorem loc_c6 : ∀ s < 8, ∀ s' < 8, ∀ t < 8, ∀ t' < 8,
    ham (partner (hexof s t)) (hexof s' t') = 6 →
    s = s' ∧ t' = t ^^^ st s ^^^ 7 ∧ t = t' ^^^ st s ^^^ 7 := by decide +kernel

/-- two different pairs joined by a class-6 step: the support has weight 1 or 2. -/
theorem loc_c6_wt : ∀ s < 8, ∀ t < 8, ∀ t' < 8,
    ham (partner (hexof s t)) (hexof s t') = 6 → samePair (hexof s t) (hexof s t') = false →
    (pc3 s = 1 ∨ pc3 s = 2) := by decide +kernel

/-- same support: a relative change in {0, st s} does not change "same pair". -/
theorem loc_d1 : ∀ s < 8, ∀ t < 8, ∀ t' < 8, ∀ d < 8, ∀ d' < 8,
    (d ^^^ d' = 0 ∨ d ^^^ d' = st s) →
    samePair (hexof s (t ^^^ d)) (hexof s (t' ^^^ d')) = samePair (hexof s t) (hexof s t') := by
  decide +kernel

/-- the complement move: t is a class-6 slot, t' a third slot not holding the other pair. -/
theorem loc_d2a : ∀ s < 8, ∀ t < 8, ∀ t' < 8, ∀ d < 8, ∀ d' < 8,
    (pc3 s = 1 ∨ pc3 s = 2) →
    samePair (hexof s (t ^^^ st s ^^^ 7)) (hexof s t') = false →
    (d ^^^ d' = 7 ∨ d ^^^ d' = 7 ^^^ s) →
    samePair (hexof s (t ^^^ d)) (hexof s (t' ^^^ d')) = false := by decide +kernel

theorem loc_d2b : ∀ s < 8, ∀ t < 8, ∀ t' < 8, ∀ d < 8, ∀ d' < 8,
    (pc3 s = 1 ∨ pc3 s = 2) →
    samePair (hexof s t) (hexof s (t' ^^^ st s ^^^ 7)) = false →
    (d ^^^ d' = 7 ∨ d ^^^ d' = 7 ^^^ s) →
    samePair (hexof s (t ^^^ d)) (hexof s (t' ^^^ d')) = false := by decide +kernel

theorem sp_symm : ∀ x < 64, ∀ y < 64, samePair x y = samePair y x := by decide +kernel
theorem pc3_zero : ∀ s < 8, ∀ s' < 8, pc3 (s ^^^ s') = 0 → s = s' := by decide
theorem m_zero : ∀ s < 8, ∀ s' < 8, pc3 (s ^^^ s') = 3 → 7 ^^^ (s ^^^ s') = 0 := by decide

/-- which classes can occur for which number of differing support coordinates (4,096 cases). -/
theorem feas : ∀ s < 8, ∀ s' < 8, ∀ t < 8, ∀ t' < 8,
    (pc3 (s ^^^ s') = 0 ∧ (ham (partner (hexof s t)) (hexof s' t') = 0 ∨
        ham (partner (hexof s t)) (hexof s' t') = 2 ∨ ham (partner (hexof s t)) (hexof s' t') = 4 ∨
        ham (partner (hexof s t)) (hexof s' t') = 6)) ∨
    (pc3 (s ^^^ s') = 1 ∧ (ham (partner (hexof s t)) (hexof s' t') = 1 ∨
        ham (partner (hexof s t)) (hexof s' t') = 3 ∨ ham (partner (hexof s t)) (hexof s' t') = 5)) ∨
    (pc3 (s ^^^ s') = 2 ∧ (ham (partner (hexof s t)) (hexof s' t') = 2 ∨
        ham (partner (hexof s t)) (hexof s' t') = 4)) ∨
    (pc3 (s ^^^ s') = 3 ∧ ham (partner (hexof s t)) (hexof s' t') = 3) := by decide +kernel

/-- the translation of one slot: flip o (by st s), shift V (supports other than 0), and the
    complement move b. -/
def Mf (s : Nat) (o : Bool) (V : Nat) (b : Bool) : Nat :=
  (if o then st s else 0) ^^^ ((if s != 0 then V else 0) ^^^ (if b then 7 else 0))

theorem Mf_lt : ∀ s < 8, ∀ o : Bool, ∀ V < 8, ∀ b : Bool, Mf s o V b < 8 := by decide

/-- two slots of one support: the relative change. -/
theorem same_delta : ∀ s < 8, ∀ o : Bool, ∀ o' : Bool, ∀ b : Bool, ∀ b' : Bool, ∀ V < 8,
    (b = b' → (Mf s o V b ^^^ Mf s o' V b' = 0 ∨ Mf s o V b ^^^ Mf s o' V b' = st s)) ∧
    (b ≠ b' → (pc3 s = 1 ∨ pc3 s = 2) →
      (Mf s o V b ^^^ Mf s o' V b' = 7 ∨ Mf s o V b ^^^ Mf s o' V b' = 7 ^^^ s)) := by decide

/-- the third-slot conditions give a relative change in {0, u}. -/
theorem third_delta : ∀ s < 8, ∀ o : Bool, ∀ o' : Bool, ∀ w : Bool, ∀ b : Bool, ∀ b' : Bool,
    ∀ V < 8, (pc3 s = 1 ∨ pc3 s = 2) → b ≠ b' →
    (if pc3 s = 1 then (o ^^ (o' ^^ (w ^^ false))) = false else (w ^^ false) = false) →
    (Mf s o V (b && w) ^^^ Mf s o' V (b' && w) = 0 ∨
      Mf s o V (b && w) ^^^ Mf s o' V (b' && w) = uu s) := by decide

/-- must fail: without the third-slot condition the relative change can leave {0, u}. -/
theorem third_delta_needs_hyp : ¬ (∀ s < 8, ∀ o : Bool, ∀ o' : Bool, ∀ w : Bool, ∀ b : Bool,
    ∀ b' : Bool, ∀ V < 8, (pc3 s = 1 ∨ pc3 s = 2) → b ≠ b' →
    (Mf s o V (b && w) ^^^ Mf s o' V (b' && w) = 0 ∨
      Mf s o V (b && w) ^^^ Mf s o' V (b' && w) = uu s)) := by decide

end GPLocalOpts
end Q1150

/-
  §39  THE MOVES AND THE CONDITIONS

  Parameters: 53 bits c. Bit k-1 is the flip o_k of slot k (k = 1..31); bits 31 + 3(s-1) + i
  (i = 0, 1, 2) are the shift v_s of support s (s = 1..7); bit 52 is w, the complement move on
  the two slots joined by the class-6 boundary. `Mrows σ cl` is the 93 x 53 matrix of the
  moves; `Sys σ cl` the linear conditions, at most 20 + t of them (`Sys_length`), where
  t = `tcount σ cl` is the number of class-3 boundaries whose two supports differ in exactly one
  coordinate. (The sub-headings "§1" to "§6" inside this section are local to it.)
-/
namespace Q1150
open SuperspaceDivisibility F2Count

/-! ## §1  rows given by a list of bit positions -/

def ofIdx : List Nat → Vec
  | [] => []
  | i :: L => vxor (unit i) (ofIdx L)

/-- the XOR of the bits of c at the positions L. -/
def xs (c : Vec) : List Nat → Bool
  | [] => false
  | i :: L => c.getD i false ^^ xs c L

theorem dot_ofIdx (c : Vec) : ∀ L : List Nat, dot (ofIdx L) c = xs c L
  | [] => rfl
  | i :: L => by
    show dot (vxor (unit i) (ofIdx L)) c = (c.getD i false ^^ xs c L)
    rw [dot_vxor, dot_unit, dot_ofIdx c L]

theorem xs_append (c : Vec) : ∀ L L' : List Nat, xs c (L ++ L') = (xs c L ^^ xs c L')
  | [], L' => by
    show xs c L' = (false ^^ xs c L')
    cases xs c L' <;> rfl
  | i :: L, L' => by
    show (c.getD i false ^^ xs c (L ++ L')) = ((c.getD i false ^^ xs c L) ^^ xs c L')
    rw [xs_append c L L']
    cases c.getD i false <;> cases xs c L <;> cases xs c L' <;> rfl

theorem xs_if (c : Vec) (b : Bool) (i : Nat) :
    xs c (if b then [i] else []) = (b && c.getD i false) := by
  cases b
  · rfl
  · show (c.getD i false ^^ false) = (true && c.getD i false)
    cases c.getD i false <;> rfl

theorem xs_ifl (c : Vec) (b : Bool) (L : List Nat) :
    xs c (if b then L else []) = (b && xs c L) := by
  cases b <;> rfl

/-- the row "the XOR of the bits L is 0". -/
def rw0 (L : List Nat) : Row := (ofIdx L, false)

theorem rowsat_rw0 (c : Vec) (L : List Nat) : rowsat (rw0 L) c = !(xs c L) := by
  show (dot (ofIdx L) c == false) = !(xs c L)
  rw [dot_ofIdx]; cases xs c L <;> rfl

theorem sat_map_rw0 (c : Vec) (f : Nat → List Nat) : ∀ L : List Nat,
    sat (L.map (fun i => rw0 (f i))) c = true → ∀ i, i ∈ L → xs c (f i) = false
  | [], _, i, hi => by cases hi
  | a :: L, h, i, hi => by
    rw [List.map_cons, sat_cons, rowsat_rw0] at h
    have h' := (Bool.and_eq_true _ _).mp h
    rcases List.mem_cons.mp hi with e | hi'
    · rw [e]
      cases hx : xs c (f a) with
      | false => rfl
      | true => rw [hx] at h'; exact absurd h'.1 (by decide)
    · exact sat_map_rw0 c f L h'.2 i hi'

/-! ## §2  three rows per slot -/

def rows3 (R : Nat → Nat → Vec) : List Nat → List Vec
  | [] => []
  | k :: K => R k 0 :: R k 1 :: R k 2 :: rows3 R K

theorem rows3_length (R : Nat → Nat → Vec) : ∀ K : List Nat, (rows3 R K).length = 3 * K.length
  | [] => rfl
  | k :: K => by
    show (rows3 R K).length + 1 + 1 + 1 = 3 * (K.length + 1)
    rw [rows3_length R K]; omega

theorem wr_rows (c : Vec) (R : Nat → Nat → Vec) : ∀ (K : List Nat) (t : Asg) (j : Nat),
    wr K (mulM (rows3 R K) c) t j =
      if j ∈ K then val3 (dot (R j 0) c) (dot (R j 1) c) (dot (R j 2) c) else t j
  | [], t, j => by simp [wr]
  | k :: K, t, j => by
    show wr K (mulM (rows3 R K) c)
      (upd t k (val3 (dot (R k 0) c) (dot (R k 1) c) (dot (R k 2) c))) j = _
    rw [wr_rows c R K]
    by_cases hj : j ∈ K
    · simp [hj]
    · by_cases hk : j = k
      · subst hk; simp [hj, upd]
      · simp [hj, hk, upd]

theorem ker_rows3 (c : Vec) (R : Nat → Nat → Vec) : ∀ K : List Nat, ker (rows3 R K) c = true →
    ∀ j, j ∈ K → dot (R j 0) c = false ∧ dot (R j 1) c = false ∧ dot (R j 2) c = false
  | [], _, j, hj => by cases hj
  | k :: K, h, j, hj => by
    have h' : ((!(dot (R k 0) c)) && ((!(dot (R k 1) c)) && ((!(dot (R k 2) c)) &&
        ker (rows3 R K) c))) = true := h
    simp only [Bool.and_eq_true, Bool.not_eq_true'] at h'
    rcases List.mem_cons.mp hj with e | hj'
    · rw [e]; exact ⟨h'.1, h'.2.1, h'.2.2.1⟩
    · exact ker_rows3 c R K h'.2.2.2 j hj'

/-! ## §3  translations of assignments -/

/-- slot-by-slot translation. -/
def tr (a d : Asg) : Asg := fun k => a k ^^^ d k

theorem val3_xor : ∀ a0 a1 a2 b0 b1 b2 : Bool,
    val3 (a0 ^^ b0) (a1 ^^ b1) (a2 ^^ b2) = val3 a0 a1 a2 ^^^ val3 b0 b1 b2 := by decide
theorem val3_lt : ∀ a0 a1 a2 : Bool, val3 a0 a1 a2 < 8 := by decide

theorem len3 (x : Vec) (n : Nat) (h : x.length = 3 * (n + 1)) :
    ∃ a b c x', x = a :: b :: c :: x' ∧ x'.length = 3 * n := by
  match x, h with
  | a :: b :: c :: x', h =>
    exact ⟨a, b, c, x', rfl, by simp only [List.length_cons] at h; omega⟩
  | [], h => simp only [List.length_nil] at h; omega
  | [_], h => simp only [List.length_cons, List.length_nil] at h; omega
  | [_, _], h => simp only [List.length_cons, List.length_nil] at h; omega

/-- writing x + u is writing x, translated by writing u. -/
theorem wr_vadd : ∀ (K : List Nat) (x u : Vec) (t d : Asg),
    x.length = 3 * K.length → u.length = 3 * K.length →
    wr K (vadd x u) (tr t d) = tr (wr K x t) (wr K u d)
  | [], _, _, _, _, _, _ => rfl
  | k :: K, x, u, t, d, hx, hu => by
    obtain ⟨a, b, c, x', rfl, hx'⟩ := len3 x K.length hx
    obtain ⟨p, q, r, u', rfl, hu'⟩ := len3 u K.length hu
    show wr K (vadd x' u') (upd (tr t d) k (val3 (a ^^ p) (b ^^ q) (c ^^ r)))
      = tr (wr K x' (upd t k (val3 a b c))) (wr K u' (upd d k (val3 p q r)))
    have e : upd (tr t d) k (val3 (a ^^ p) (b ^^ q) (c ^^ r))
        = tr (upd t k (val3 a b c)) (upd d k (val3 p q r)) := funext fun j => by
      show (if j = k then _ else _) = (if j = k then _ else _) ^^^ (if j = k then _ else _)
      by_cases hj : j = k
      · rw [if_pos hj, if_pos hj, if_pos hj]; exact val3_xor a b c p q r
      · rw [if_neg hj, if_neg hj, if_neg hj]; rfl
    rw [e]; exact wr_vadd K x' u' _ _ hx' hu'

/-- every value written by `wr` is below 8 (given that the start is). -/
theorem wr_lt : ∀ (K : List Nat) (x : Vec) (t : Asg), (∀ k, t k < 8) → ∀ k, wr K x t k < 8
  | [], _, _, h, k => h k
  | j :: K, x, t, h, k => by
    show wr K (x.drop 3) (upd t j _) k < 8
    apply wr_lt K
    intro i
    show (if i = j then _ else _) < 8
    by_cases hi : i = j
    · rw [if_pos hi]; exact val3_lt _ _ _
    · rw [if_neg hi]; exact h i

/-! ## §4  the moves -/

/-- bit i of a value 0..7, in the order of `val3` (i = 0 is the 4s place). -/
def bit3 (v i : Nat) : Bool :=
  if i = 0 then v / 4 % 2 == 1 else if i = 1 then v / 2 % 2 == 1 else v % 2 == 1

/-- the class-6 boundary (the first one; under King Wen's budget there is exactly one). -/
def jOf (cl : Nat → Nat) : Nat := ((List.range 31).filter (fun k => cl k == 6)).headD 99

/-- slot k is one of the two slots joined by the class-6 boundary. -/
def inJ (cl : Nat → Nat) (k : Nat) : Bool := k == jOf cl || k == jOf cl + 1

/-- the parameter bits that move coordinate i of slot k: the flip o_k (where st has bit i), the
    shift bit i of the slot's support (not for support 0), and w for the two class-6 slots.
    Slot 0, the anchor, is not moved. -/
def idx (σ cl : Nat → Nat) (k i : Nat) : List Nat :=
  if k = 0 then [] else
    (if bit3 (st (σ k)) i then [k - 1] else []) ++
    ((if σ k != 0 then [31 + 3 * (σ k - 1) + i] else []) ++
     (if inJ cl k then [52] else []))

/-- the 93 x 53 matrix of the moves: three rows per slot 1..31. -/
def Mrows (σ cl : Nat → Nat) : List Vec := rows3 (fun k i => ofIdx (idx σ cl k i)) slots

/-- the translation of slot k under the move with parameters c. -/
def mvv (σ cl : Nat → Nat) (c : Vec) (k : Nat) : Nat :=
  val3 (xs c (idx σ cl k 0)) (xs c (idx σ cl k 1)) (xs c (idx σ cl k 2))

def ob (c : Vec) (k : Nat) : Bool := c.getD (k - 1) false
def vv (c : Vec) (s : Nat) : Nat :=
  val3 (c.getD (31 + 3 * (s - 1) + 0) false) (c.getD (31 + 3 * (s - 1) + 1) false)
    (c.getD (31 + 3 * (s - 1) + 2) false)
def wb (c : Vec) : Bool := c.getD 52 false

theorem xs_idx (σ cl : Nat → Nat) (c : Vec) (k i : Nat) (hk : k ≠ 0) :
    xs c (idx σ cl k i) =
      ((bit3 (st (σ k)) i && ob c k) ^^
        (((σ k != 0) && c.getD (31 + 3 * (σ k - 1) + i) false) ^^ (inJ cl k && wb c))) := by
  unfold idx
  rw [if_neg hk, xs_append, xs_append, xs_if, xs_if, xs_if]
  rfl

theorem mv_form : ∀ s < 8, ∀ o v0 v1 v2 w : Bool,
    val3 ((bit3 (st s) 0 && o) ^^ (((s != 0) && v0) ^^ w))
         ((bit3 (st s) 1 && o) ^^ (((s != 0) && v1) ^^ w))
         ((bit3 (st s) 2 && o) ^^ (((s != 0) && v2) ^^ w))
      = Mf s o (val3 v0 v1 v2) w := by decide

theorem mvv_zero (σ cl : Nat → Nat) (c : Vec) : mvv σ cl c 0 = 0 := rfl

theorem mvv_lt (σ cl : Nat → Nat) (c : Vec) (k : Nat) : mvv σ cl c k < 8 := val3_lt _ _ _

/-- the translation of a slot in closed form. -/
theorem mvv_eq (σ cl : Nat → Nat) (c : Vec) (k : Nat) (hk : k ≠ 0) (hσ : σ k < 8) :
    mvv σ cl c k = Mf (σ k) (ob c k) (vv c (σ k)) (inJ cl k && wb c) := by
  unfold mvv
  rw [xs_idx σ cl c k 0 hk, xs_idx σ cl c k 1 hk, xs_idx σ cl c k 2 hk]
  exact mv_form (σ k) hσ _ _ _ _ _

/-- what `wr` writes for the move c: the translation `mvv` on the slots 1..31, 0 elsewhere. -/
theorem wr_move (σ cl : Nat → Nat) (c : Vec) (j : Nat) (hj : j ≤ 31) :
    wr slots (mulM (Mrows σ cl) c) (fun _ => 0) j = mvv σ cl c j := by
  unfold Mrows
  rw [wr_rows]
  by_cases h : j ∈ slots
  · rw [if_pos h, dot_ofIdx, dot_ofIdx, dot_ofIdx]; rfl
  · rw [if_neg h]
    have : j = 0 := by rw [mem_slots] at h; omega
    rw [this]; rfl

theorem Mrows_length (σ cl : Nat → Nat) : (Mrows σ cl).length = 93 := by
  unfold Mrows; rw [rows3_length]; rfl

/-! ## §5  the conditions -/

/-- the parameter bits in coordinate i of the change δ_k at boundary k. -/
def dl (σ cl : Nat → Nat) (k i : Nat) : List Nat := idx σ cl k i ++ idx σ cl (k + 1) i

/-- the coordinates in m. -/
def crd (m : Nat) : List Nat := [0, 1, 2].filter (bit3 m)

/-- number of coordinates in which the supports at boundary k differ. -/
def pk (σ : Nat → Nat) (k : Nat) : Nat := pc3 (sg σ k ^^^ σ (k + 1))
/-- the compared coordinates at boundary k. -/
def mk (σ : Nat → Nat) (k : Nat) : Nat := 7 ^^^ (sg σ k ^^^ σ (k + 1))

/-- the linear conditions of boundary k (Block 1 of the proof):
    class 1 (supports differ in one coordinate): δ = 0 on the two compared coordinates;
    cross class 2 or 4: δ = 0 on the one compared coordinate;
    class 3, supports differing in one coordinate: δ is 0 or all of m on m (one condition);
    internal (class 2, 4 or 6), both slots or neither in the class-6 pair: o_k = o_{k+1}
      (o_1 = 0 at the anchor);
    internal, exactly one slot in the class-6 pair: o_k + o_{k+1} = w if the support has weight
      1, and w = 0 otherwise.
    No condition in any other case. -/
def rowsAt (σ cl : Nat → Nat) (k : Nat) : List Row :=
  if pk σ k = 1 ∧ cl k = 1 ∨ pk σ k = 2 ∧ (cl k = 2 ∨ cl k = 4) then
    (crd (mk σ k)).map (fun i => rw0 (dl σ cl k i))
  else if pk σ k = 1 ∧ cl k = 3 then
    [rw0 ((if bit3 (mk σ k) 0 then dl σ cl k 0 else []) ++
      ((if bit3 (mk σ k) 1 then dl σ cl k 1 else []) ++
       (if bit3 (mk σ k) 2 then dl σ cl k 2 else [])))]
  else if pk σ k = 0 ∧ (cl k = 2 ∨ cl k = 4 ∨ cl k = 6) then
    (if inJ cl k == inJ cl (k + 1) then [rw0 (if k = 0 then [0] else [k - 1, k])]
     else if pc3 (sg σ k) = 1 then [rw0 [k - 1, k, 52]] else [rw0 [52]])
  else []

/-! ## §6  the system, and the number of conditions -/

/-- the rows of boundaries 0..n-1. -/
def sysUpTo (f : Nat → List Row) : Nat → List Row
  | 0 => []
  | n+1 => sysUpTo f n ++ f n

/-- the conditions of all 31 boundaries. -/
def Sys (σ cl : Nat → Nat) : List Row := sysUpTo (rowsAt σ cl) 31

theorem sysUpTo_length (f : Nat → List Row) : ∀ n : Nat,
    (sysUpTo f n).length = sumN (fun k => (f k).length) n
  | 0 => rfl
  | n+1 => by
    show (sysUpTo f n ++ f n).length = sumN (fun k => (f k).length) n + (f n).length
    rw [List.length_append, sysUpTo_length f n]

theorem sat_sysUpTo (f : Nat → List Row) (c : Vec) : ∀ n : Nat, sat (sysUpTo f n) c = true →
    ∀ k, k < n → sat (f k) c = true
  | 0, _, k, hk => by omega
  | n+1, h, k, hk => by
    have h' : sat (sysUpTo f n ++ f n) c = true := h
    rw [sat_append] at h'
    have h2 := (Bool.and_eq_true _ _).mp h'
    by_cases e : k = n
    · rw [e]; exact h2.2
    · exact sat_sysUpTo f c n h2.1 k (by omega)

theorem hom_sysUpTo (f : Nat → List Row) (hf : ∀ k, Hom (f k)) : ∀ n : Nat, Hom (sysUpTo f n)
  | 0 => fun r hr => by cases hr
  | n+1 => hom_append _ _ (hom_sysUpTo f hf n) (hf n)

theorem hom_rowsAt (σ cl : Nat → Nat) (k : Nat) : Hom (rowsAt σ cl k) := by
  intro r hr
  unfold rowsAt at hr
  split at hr
  · rcases List.mem_map.mp hr with ⟨i, _, rfl⟩; rfl
  · split at hr
    · rcases List.mem_singleton.mp hr with rfl; rfl
    · split at hr
      · split at hr
        · rcases List.mem_singleton.mp hr with rfl; rfl
        · split at hr
          · rcases List.mem_singleton.mp hr with rfl; rfl
          · rcases List.mem_singleton.mp hr with rfl; rfl
      · cases hr

theorem hom_Sys (σ cl : Nat → Nat) : Hom (Sys σ cl) := hom_sysUpTo _ (hom_rowsAt σ cl) 31

/-- a class-3 boundary whose supports differ in exactly one coordinate. -/
def tp (σ cl : Nat → Nat) (k : Nat) : Bool := cl k == 3 && pk σ k == 1

/-- t(σ, c): the number of such boundaries. -/
def tcount (σ cl : Nat → Nat) : Nat := ((List.range 31).filter (tp σ cl)).length

/-- the charge of boundary k: 2 for class 1, 1 for classes 2, 4, 6, and 1 for a class-3
    boundary counted by t. -/
def wt (σ cl : Nat → Nat) (k : Nat) : Nat :=
  (if cl k == 1 then 2 else 0) + (if cl k == 2 then 1 else 0) + (if cl k == 4 then 1 else 0) +
  (if cl k == 6 then 1 else 0) + (if tp σ cl k then 1 else 0)

theorem crd_len : ∀ s < 8, ∀ s' < 8,
    (pc3 (s ^^^ s') = 1 → (crd (7 ^^^ (s ^^^ s'))).length = 2) ∧
    (pc3 (s ^^^ s') = 2 → (crd (7 ^^^ (s ^^^ s'))).length = 1) := by decide

theorem rowsAt_len (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) (k : Nat) :
    (rowsAt σ cl k).length ≤ wt σ cl k := by
  unfold rowsAt wt tp
  by_cases hA : (pk σ k = 1 ∧ cl k = 1 ∨ pk σ k = 2 ∧ (cl k = 2 ∨ cl k = 4))
  · rw [if_pos hA, List.length_map]
    have hc := crd_len (sg σ k) (sg_lt σ hσ k) (σ (k + 1)) (hσ (k + 1))
    rcases hA with ⟨h1, h2⟩ | ⟨h1, h2 | h2⟩
    · rw [show (crd (mk σ k)).length = 2 from hc.1 h1, h2]; simp
    · rw [show (crd (mk σ k)).length = 1 from hc.2 h1, h2]; simp
    · rw [show (crd (mk σ k)).length = 1 from hc.2 h1, h2]; simp
  · rw [if_neg hA]
    by_cases hB : pk σ k = 1 ∧ cl k = 3
    · rw [if_pos hB, hB.2, hB.1]; simp
    · rw [if_neg hB]
      by_cases hD : pk σ k = 0 ∧ (cl k = 2 ∨ cl k = 4 ∨ cl k = 6)
      · rw [if_pos hD]
        have h1 : (if inJ cl k == inJ cl (k + 1) then [rw0 (if k = 0 then [0] else [k - 1, k])]
            else if pc3 (sg σ k) = 1 then [rw0 [k - 1, k, 52]] else [rw0 [52]]).length = 1 := by
          split
          · rfl
          · split <;> rfl
        rw [h1]
        rcases hD.2 with h | h | h <;> rw [h] <;> simp
      · rw [if_neg hD]; exact Nat.zero_le _

theorem sumN_wt (σ cl : Nat → Nat) (n : Nat) :
    sumN (wt σ cl) n =
      2 * (((List.range n).map cl).filter (· == 1)).length +
      (((List.range n).map cl).filter (· == 2)).length +
      (((List.range n).map cl).filter (· == 4)).length +
      (((List.range n).map cl).filter (· == 6)).length +
      ((List.range n).filter (tp σ cl)).length := by
  induction n with
  | zero => rfl
  | succ n ih =>
    show sumN (wt σ cl) n + wt σ cl n = _
    rw [ih, List.range_succ, List.map_append, List.filter_append, List.filter_append,
      List.filter_append, List.filter_append, List.filter_append, List.length_append,
      List.length_append, List.length_append, List.length_append, List.length_append]
    have h : cl n = 1 ∨ cl n = 2 ∨ cl n = 3 ∨ cl n = 4 ∨ cl n = 6 ∨
        (cl n ≠ 1 ∧ cl n ≠ 2 ∧ cl n ≠ 3 ∧ cl n ≠ 4 ∧ cl n ≠ 6) := by omega
    rcases h with h | h | h | h | h | ⟨h1, h2, h3, h4, h6⟩
    · simp [wt, tp, h] <;> omega
    · simp [wt, tp, h] <;> omega
    · by_cases hp : pk σ n = 1
      · simp [wt, tp, h, hp] <;> omega
      · simp [wt, tp, h, hp] <;> omega
    · simp [wt, tp, h] <;> omega
    · simp [wt, tp, h] <;> omega
    · simp [wt, tp, h1, h2, h3, h4, h6] <;> omega

/-- **The count of conditions.** Under King Wen's budget there are at most 20 + t. -/
theorem Sys_length (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true) :
    (Sys σ cl).length ≤ 20 + tcount σ cl := by
  unfold Sys
  rw [sysUpTo_length]
  have h1 := sumN_le (fun k => (rowsAt σ cl k).length) (wt σ cl) 31
    (fun k _ => rowsAt_len σ cl hσ k)
  rw [sumN_wt] at h1
  simp only [budgetOK, Bool.and_eq_true, beq_iff_eq] at hb
  obtain ⟨⟨⟨⟨b1, b2⟩, _⟩, b4⟩, b6⟩ := hb
  rw [b1, b2, b4, b6] at h1
  unfold tcount
  omega

end Q1150

/-
  §40  a move that meets the conditions maps the fibre into itself

    inv_fibre : for every skeleton σ (values below 8), every class sequence cl with King
                Wen's budget, every c with `sat (Sys σ cl) c`, and every assignment of the
                fibre, the moved assignment is in the fibre.
-/
namespace Q1150
open SuperspaceDivisibility F2Count

section GPInvOpts
set_option synthInstance.maxSize 4096
set_option synthInstance.maxHeartbeats 0

/-- the fibre condition as a Boolean: `W σ cl a = if Fb σ cl a then 1 else 0` by definition. -/
def Fb (σ cl : Nat → Nat) (a : Asg) : Bool :=
  distinctOK σ a && (List.range 31).all (fun k => clsAt σ a k == cl k)

theorem W_eq (σ cl : Nat → Nat) (a : Asg) : W σ cl a = if Fb σ cl a then 1 else 0 := rfl

/-- coordinate of slot k (7 for the anchor, whose entry is hexof 0 7 = 63). -/
def tt (a : Asg) (k : Nat) : Nat := if k = 0 then 7 else a k % 8

theorem entry_tt (σ : Nat → Nat) (a : Asg) (k : Nat) : entry σ a k = hexof (sg σ k) (tt a k) :=
  entry_gen σ a k

theorem tt_lt (a : Asg) (k : Nat) : tt a k < 8 := by
  unfold tt; split
  · decide
  · exact Nat.mod_lt _ (by decide)

theorem sg_succ (σ : Nat → Nat) (k : Nat) : sg σ (k + 1) = σ (k + 1) := if_neg (by omega)
theorem sg_pos (σ : Nat → Nat) (k : Nat) (hk : k ≠ 0) : sg σ k = σ k := if_neg hk

theorem cls_tt (σ : Nat → Nat) (a : Asg) (k : Nat) :
    clsAt σ a k = ham (partner (hexof (sg σ k) (tt a k))) (hexof (σ (k + 1)) (tt a (k + 1))) := by
  unfold clsAt; rw [entry_tt σ a k, entry_tt σ a (k + 1), sg_succ]

theorem tt_tr (a d : Asg) (k : Nat) (ha : a k < 8) (hd : d k < 8) (h0 : d 0 = 0) :
    tt (tr a d) k = tt a k ^^^ d k := by
  unfold tt tr
  by_cases hk : k = 0
  · subst hk
    show 7 = 7 ^^^ d 0
    rw [h0]; rfl
  · rw [if_neg hk, if_neg hk, Nat.mod_eq_of_lt (xor_lt8 _ ha _ hd), Nat.mod_eq_of_lt ha]

theorem Fb_cls {σ cl : Nat → Nat} {a : Asg} (h : Fb σ cl a = true) :
    ∀ k, k < 31 → clsAt σ a k = cl k := by
  unfold Fb at h
  have h2 := ((Bool.and_eq_true _ _).mp h).2
  rw [List.all_eq_true] at h2
  intro k hk
  exact eq_of_beq (h2 k (List.mem_range.mpr hk))

theorem Fb_dist {σ cl : Nat → Nat} {a : Asg} (h : Fb σ cl a = true) :
    ∀ i j, i < j → j ≤ 31 → samePair (entry σ a i) (entry σ a j) = false := by
  unfold Fb distinctOK at h
  have h1 := ((Bool.and_eq_true _ _).mp h).1
  rw [List.all_eq_true] at h1
  intro i j hij hj
  have h2 := h1 i (List.mem_range.mpr (by omega))
  rw [List.all_eq_true] at h2
  have h3 := h2 j (List.mem_range.mpr (by omega))
  simpa [hij] using h3

theorem Fb_intro (σ cl : Nat → Nat) (a : Asg)
    (hd : ∀ i j, i < j → j ≤ 31 → samePair (entry σ a i) (entry σ a j) = false)
    (hc : ∀ k, k < 31 → clsAt σ a k = cl k) : Fb σ cl a = true := by
  unfold Fb distinctOK
  rw [Bool.and_eq_true]
  constructor
  · rw [List.all_eq_true]
    intro i _
    rw [List.all_eq_true]
    intro j hj
    have hj' := List.mem_range.mp hj
    by_cases hij : i < j
    · simp [hij, hd i j hij (by omega)]
    · simp [hij]
  · rw [List.all_eq_true]
    intro k hk
    rw [hc k (List.mem_range.mp hk)]
    exact beq_self_eq_true _

/-- distinctness in either order, in coordinates. -/
theorem dist_any {σ cl : Nat → Nat} {a : Asg} (hσ : ∀ k, σ k < 8) (h : Fb σ cl a = true) :
    ∀ i j, i ≤ 31 → j ≤ 31 → i ≠ j →
      samePair (hexof (sg σ i) (tt a i)) (hexof (sg σ j) (tt a j)) = false := by
  intro i j hi hj hne
  rw [← entry_tt, ← entry_tt]
  by_cases hij : i < j
  · exact Fb_dist h i j hij hj
  · rw [sp_symm _ (entry_lt σ hσ a i) _ (entry_lt σ hσ a j)]
    exact Fb_dist h j i (by omega) hi

/-! ### the class-6 boundary -/

structure JF (σ cl : Nat → Nat) (a : Asg) : Prop where
  j1 : 1 ≤ jOf cl
  j31 : jOf cl < 31
  c6 : cl (jOf cl) = 6
  uniq : ∀ k, k < 31 → cl k = 6 → k = jOf cl
  ss : σ (jOf cl) = σ (jOf cl + 1)
  wt : pc3 (σ (jOf cl)) = 1 ∨ pc3 (σ (jOf cl)) = 2
  t1 : tt a (jOf cl + 1) = tt a (jOf cl) ^^^ st (σ (jOf cl)) ^^^ 7
  t0 : tt a (jOf cl) = tt a (jOf cl + 1) ^^^ st (σ (jOf cl)) ^^^ 7

/-- in a nonempty fibre: exactly one class-6 boundary j, not at the anchor; its two slots have
    the same support, of weight 1 or 2, and hold a pair and the pair of its complements. -/
theorem jfacts (σ cl : Nat → Nat) (a : Asg) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true)
    (hF : Fb σ cl a = true) : JF σ cl a := by
  simp only [budgetOK, Bool.and_eq_true, beq_iff_eq] at hb
  obtain ⟨_, b6⟩ := hb
  have e6 : ((List.range 31).filter (fun k => cl k == 6)).length = 1 := by
    rw [List.filter_map, List.length_map] at b6; exact b6
  generalize hL : (List.range 31).filter (fun k => cl k == 6) = L at e6
  match L, hL, e6 with
  | [], _, e6 => simp at e6
  | _ :: _ :: _, _, e6 => simp at e6
  | [j], hL, _ =>
    have hj : jOf cl = j := by unfold jOf; rw [hL]; rfl
    have hmem : j ∈ (List.range 31).filter (fun k => cl k == 6) := by
      rw [hL]; exact List.mem_cons_self
    have hm := List.mem_filter.mp hmem
    have hj31 : j < 31 := List.mem_range.mp hm.1
    have hc6 : cl j = 6 := eq_of_beq hm.2
    have huniq : ∀ k, k < 31 → cl k = 6 → k = j := fun k hk hc => by
      have hk' : k ∈ (List.range 31).filter (fun k => cl k == 6) :=
        List.mem_filter.mpr ⟨List.mem_range.mpr hk, by rw [hc]; rfl⟩
      rw [hL] at hk'
      exact List.mem_singleton.mp hk'
    have hcls := Fb_cls hF j hj31
    rw [cls_tt, hc6] at hcls
    obtain ⟨hs, ht1, ht0⟩ := loc_c6 (sg σ j) (sg_lt σ hσ j) (σ (j + 1)) (hσ (j + 1))
      (tt a j) (tt_lt a j) (tt a (j + 1)) (tt_lt a (j + 1)) hcls
    have hd := dist_any hσ hF j (j + 1) (by omega) (by omega) (by omega)
    rw [sg_succ, ← hs] at hd
    rw [← hs] at hcls
    have hw := loc_c6_wt (sg σ j) (sg_lt σ hσ j) (tt a j) (tt_lt a j) (tt a (j + 1))
      (tt_lt a (j + 1)) hcls hd
    have hj1 : j ≠ 0 := by
      intro h0
      rw [h0] at hw
      revert hw
      show ¬ (pc3 0 = 1 ∨ pc3 0 = 2)
      decide
    rw [sg_pos σ j hj1] at hs hw ht1 ht0
    subst hj
    exact ⟨by omega, hj31, hc6, huniq, hs, hw, ht1, ht0⟩

theorem inJ_zero {σ cl : Nat → Nat} {a : Asg} (J : JF σ cl a) : inJ cl 0 = false := by
  have h := J.j1
  unfold inJ
  cases h1 : (0 == jOf cl) with
  | true => have := eq_of_beq h1; omega
  | false =>
    cases h2 : (0 == jOf cl + 1) with
    | true => have := eq_of_beq h2; omega
    | false => rfl

theorem inJ_true {cl : Nat → Nat} {k : Nat} (h : inJ cl k = true) :
    k = jOf cl ∨ k = jOf cl + 1 := by
  unfold inJ at h
  rcases (Bool.or_eq_true _ _).mp h with h | h
  · exact Or.inl (eq_of_beq h)
  · exact Or.inr (eq_of_beq h)

theorem inJ_false {cl : Nat → Nat} {k : Nat} (h : inJ cl k = false) :
    k ≠ jOf cl ∧ k ≠ jOf cl + 1 := by
  unfold inJ at h
  constructor
  · intro e; rw [e] at h; simp at h
  · intro e; rw [e] at h; simp at h

/-- a slot of the class-6 support that is not one of the two class-6 slots holds neither of
    their pairs. -/
theorem third_facts {σ cl : Nat → Nat} {a : Asg} (hσ : ∀ k, σ k < 8) (hF : Fb σ cl a = true)
    (J : JF σ cl a) (i : Nat) (hi : i ≤ 31) (h1 : i ≠ jOf cl) (h2 : i ≠ jOf cl + 1)
    (hs : sg σ i = σ (jOf cl)) :
    samePair (hexof (σ (jOf cl)) (tt a i)) (hexof (σ (jOf cl)) (tt a (jOf cl))) = false ∧
    samePair (hexof (σ (jOf cl)) (tt a i)) (hexof (σ (jOf cl)) (tt a (jOf cl + 1))) = false ∧
    samePair (hexof (σ (jOf cl)) (tt a (jOf cl))) (hexof (σ (jOf cl)) (tt a i)) = false ∧
    samePair (hexof (σ (jOf cl)) (tt a (jOf cl + 1))) (hexof (σ (jOf cl)) (tt a i)) = false := by
  have hj1 := J.j1
  have hj31 := J.j31
  have a1 := dist_any hσ hF i (jOf cl) hi (by omega) h1
  have a2 := dist_any hσ hF i (jOf cl + 1) hi (by omega) h2
  have a3 := dist_any hσ hF (jOf cl) i (by omega) hi (fun e => h1 e.symm)
  have a4 := dist_any hσ hF (jOf cl + 1) i (by omega) hi (fun e => h2 e.symm)
  rw [hs, sg_pos σ _ (by omega)] at a1 a3
  rw [hs, sg_succ, ← J.ss] at a2 a4
  exact ⟨a1, a2, a3, a4⟩

/-! ### the change at one boundary, from the rows -/

theorem vv_lt (c : Vec) (s : Nat) : vv c s < 8 := val3_lt _ _ _

theorem dd_eq (σ cl : Nat → Nat) (c : Vec) (k : Nat) :
    mvv σ cl c k ^^^ mvv σ cl c (k + 1) =
      val3 (xs c (dl σ cl k 0)) (xs c (dl σ cl k 1)) (xs c (dl σ cl k 2)) := by
  unfold mvv dl
  rw [xs_append, xs_append, xs_append]
  exact (val3_xor _ _ _ _ _ _).symm

theorem mask0 : ∀ m < 8, ∀ e0 e1 e2 : Bool, (bit3 m 0 = true → e0 = false) →
    (bit3 m 1 = true → e1 = false) → (bit3 m 2 = true → e2 = false) →
    val3 e0 e1 e2 &&& m = 0 := by decide

theorem mask3 : ∀ s < 8, ∀ s' < 8, pc3 (s ^^^ s') = 1 → ∀ e0 e1 e2 : Bool,
    ((bit3 (7 ^^^ (s ^^^ s')) 0 && e0) ^^
      ((bit3 (7 ^^^ (s ^^^ s')) 1 && e1) ^^ (bit3 (7 ^^^ (s ^^^ s')) 2 && e2))) = false →
    (val3 e0 e1 e2 &&& (7 ^^^ (s ^^^ s')) = 0 ∨
      val3 e0 e1 e2 &&& (7 ^^^ (s ^^^ s')) = 7 ^^^ (s ^^^ s')) := by decide

theorem sat_single (c : Vec) (L : List Nat) (h : sat [rw0 L] c = true) : xs c L = false := by
  rw [sat_cons, rowsat_rw0] at h
  cases hx : xs c L with
  | false => rfl
  | true => rw [hx] at h; simp at h

/-- the translation of slot k in closed form, the anchor included. -/
theorem dform {σ cl : Nat → Nat} {a : Asg} (hσ : ∀ k, σ k < 8) (J : JF σ cl a) (c : Vec)
    (k : Nat) :
    mvv σ cl c k =
      Mf (sg σ k) (if k = 0 then false else ob c k) (vv c (sg σ k)) (inJ cl k && wb c) := by
  by_cases hk : k = 0
  · subst hk
    rw [mvv_zero, inJ_zero J]
    simp [Mf, sg]
  · rw [if_neg hk, sg_pos σ k hk]
    exact mvv_eq σ cl c k hk (hσ k)

/-! ### the classes are kept -/

theorem inv_cls (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true) (c : Vec)
    (hs : sat (Sys σ cl) c = true) (a d : Asg) (ha : ∀ k, a k < 8)
    (hd : ∀ k, k ≤ 31 → d k = mvv σ cl c k) (hF : Fb σ cl a = true) (k : Nat) (hk : k < 31) :
    clsAt σ (tr a d) k = cl k := by
  have J := jfacts σ cl a hσ hb hF
  have hd0 : d 0 = 0 := by rw [hd 0 (by omega)]; rfl
  have hdlt : ∀ i, i ≤ 31 → d i < 8 := fun i hi => by rw [hd i hi]; exact mvv_lt σ cl c i
  have hcl := Fb_cls hF k hk
  rw [cls_tt] at hcl
  rw [cls_tt, tt_tr a d k (ha k) (hdlt k (by omega)) hd0,
    tt_tr a d (k + 1) (ha (k + 1)) (hdlt (k + 1) (by omega)) hd0, hd k (by omega),
    hd (k + 1) (by omega)]
  have hrow := sat_sysUpTo (rowsAt σ cl) c 31 hs k hk
  have hbc := budget_cls cl hb k hk
  have hs8 := sg_lt σ hσ k
  have hs8' := hσ (k + 1)
  have ht8 := tt_lt a k
  have ht8' := tt_lt a (k + 1)
  have hD8 := mvv_lt σ cl c k
  have hD8' := mvv_lt σ cl c (k + 1)
  have hfe := feas (sg σ k) hs8 (σ (k + 1)) hs8' (tt a k) ht8 (tt a (k + 1)) ht8'
  rw [hcl] at hfe
  have hcase : (pk σ k = 1 ∧ cl k = 1 ∨ pk σ k = 2 ∧ (cl k = 2 ∨ cl k = 4)) ∨
      (pk σ k = 1 ∧ cl k = 3) ∨ (pk σ k = 3 ∧ cl k = 3) ∨
      (pk σ k = 0 ∧ (cl k = 2 ∨ cl k = 4 ∨ cl k = 6)) := by
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hbc
    unfold pk
    omega
  have hm8 : mk σ k < 8 := xor_lt8 7 (by decide) _ (xor_lt8 _ hs8 _ hs8')
  rcases hcase with hA | hB | hC | hD
  · -- class 1, or cross class 2 or 4: δ = 0 on the compared coordinates
    unfold rowsAt at hrow
    rw [if_pos hA] at hrow
    have hE := sat_map_rw0 c (dl σ cl k) _ hrow
    have h0 : (mvv σ cl c k ^^^ mvv σ cl c (k + 1)) &&& (7 ^^^ (sg σ k ^^^ σ (k + 1))) = 0 := by
      rw [dd_eq]
      exact mask0 (mk σ k) hm8 _ _ _
        (fun h => hE 0 (List.mem_filter.mpr ⟨by decide, h⟩))
        (fun h => hE 1 (List.mem_filter.mpr ⟨by decide, h⟩))
        (fun h => hE 2 (List.mem_filter.mpr ⟨by decide, h⟩))
    exact (loc_cross _ hs8 _ hs8' _ ht8 _ ht8' _ hD8 _ hD8' h0).trans hcl
  · -- class 3, supports differing in one coordinate
    have hnA : ¬ (pk σ k = 1 ∧ cl k = 1 ∨ pk σ k = 2 ∧ (cl k = 2 ∨ cl k = 4)) := by omega
    unfold rowsAt at hrow
    rw [if_neg hnA, if_pos hB] at hrow
    have hx := sat_single c _ hrow
    rw [xs_append, xs_append, xs_ifl, xs_ifl, xs_ifl] at hx
    have h3 := mask3 (sg σ k) hs8 (σ (k + 1)) hs8' hB.1 _ _ _ hx
    rw [← dd_eq] at h3
    rw [hB.2] at hcl ⊢
    exact loc_c3 _ hs8 _ hs8' _ ht8 _ ht8' _ hD8 _ hD8' hcl h3
  · -- class 3, supports differing in three coordinates: nothing is compared
    have hm : 7 ^^^ (sg σ k ^^^ σ (k + 1)) = 0 := m_zero _ hs8 _ hs8' hC.1
    exact (loc_cross _ hs8 _ hs8' _ ht8 _ ht8' _ hD8 _ hD8'
      (by rw [hm]; exact Nat.and_zero _)).trans hcl
  · -- internal boundary
    have hss : sg σ k = σ (k + 1) := pc3_zero _ hs8 _ hs8' hD.1
    have hnA : ¬ (pk σ k = 1 ∧ cl k = 1 ∨ pk σ k = 2 ∧ (cl k = 2 ∨ cl k = 4)) := by omega
    have hnB : ¬ (pk σ k = 1 ∧ cl k = 3) := by omega
    unfold rowsAt at hrow
    rw [if_neg hnA, if_neg hnB, if_pos hD] at hrow
    have e1 := dform hσ J c k
    have e2 := dform hσ J c (k + 1)
    rw [sg_succ, ← hss, if_neg (by omega)] at e2
    by_cases hfl : inJ cl k = inJ cl (k + 1)
    · -- both slots or neither in the class-6 pair: o_k = o_{k+1}, so the change is 0
      rw [if_pos (by rw [hfl]; exact beq_self_eq_true _)] at hrow
      have hx := sat_single c _ hrow
      have ho : (if k = 0 then false else ob c k) = ob c (k + 1) := by
        by_cases hk0 : k = 0
        · subst hk0
          have hx' : (c.getD 0 false ^^ false) = false := hx
          show false = c.getD 0 false
          revert hx'; cases c.getD 0 false <;> intro hx' <;> first | rfl | exact absurd hx' (by decide)
        · rw [if_neg hk0] at hx ⊢
          have hx' : (c.getD (k - 1) false ^^ (c.getD k false ^^ false)) = false := hx
          show c.getD (k - 1) false = c.getD (k + 1 - 1) false
          rw [Nat.add_sub_cancel]
          revert hx'
          cases c.getD (k - 1) false <;> cases c.getD k false <;> intro hx' <;>
            first | rfl | exact absurd hx' (by decide)
      have hDD : mvv σ cl c k = mvv σ cl c (k + 1) := by rw [e1, e2, ho, hfl]
      exact (loc_cross _ hs8 _ hs8' _ ht8 _ ht8' _ hD8 _ hD8'
        (by rw [hDD, Nat.xor_self]; exact Nat.zero_and _)).trans hcl
    · -- exactly one slot in the class-6 pair: the third-slot rule
      rw [if_neg (fun h => hfl (eq_of_beq h))] at hrow
      have hpos : k + 1 = jOf cl ∨ k = jOf cl + 1 := by
        cases h1 : inJ cl k with
        | true =>
          cases h2 : inJ cl (k + 1) with
          | true => exact absurd (h1.trans h2.symm) hfl
          | false =>
            have p1 := inJ_true h1
            have p2 := inJ_false h2
            omega
        | false =>
          cases h2 : inJ cl (k + 1) with
          | false => exact absurd (h1.trans h2.symm) hfl
          | true =>
            have p1 := inJ_false h1
            have p2 := inJ_true h2
            omega
      have hj1 := J.j1
      have hj31 := J.j31
      have hk0 : k ≠ 0 := by
        intro h0
        subst h0
        rcases hpos with h | h
        · have hw := J.wt
          rw [← h, ← hss] at hw
          revert hw
          show ¬ (pc3 0 = 1 ∨ pc3 0 = 2)
          decide
        · omega
      have hsk : sg σ k = σ k := sg_pos σ k hk0
      have hsj : sg σ k = σ (jOf cl) := by
        rcases hpos with h | h
        · rw [← h]; exact hss
        · rw [hsk, h]; exact J.ss.symm
      have hwt : pc3 (sg σ k) = 1 ∨ pc3 (sg σ k) = 2 := by rw [hsj]; exact J.wt
      have hcond : (if pc3 (sg σ k) = 1 then (ob c k ^^ (ob c (k + 1) ^^ (wb c ^^ false))) = false
          else (wb c ^^ false) = false) := by
        by_cases h1 : pc3 (sg σ k) = 1
        · rw [if_pos h1] at hrow ⊢
          have hx : (c.getD (k - 1) false ^^ (c.getD k false ^^ (c.getD 52 false ^^ false))) = false :=
            sat_single c _ hrow
          show (c.getD (k - 1) false ^^ (c.getD (k + 1 - 1) false ^^ (c.getD 52 false ^^ false))) = false
          rw [Nat.add_sub_cancel]; exact hx
        · rw [if_neg h1] at hrow ⊢
          exact sat_single c _ hrow
      rw [if_neg hk0] at e1
      have hdel := third_delta (sg σ k) hs8 (ob c k) (ob c (k + 1)) (wb c) (inJ cl k)
        (inJ cl (k + 1)) (vv c (sg σ k)) (vv_lt c _) hwt hfl hcond
      rw [← e1, ← e2] at hdel
      have hst : st (σ (jOf cl)) = st (sg σ k) := by rw [hsj]
      rcases hpos with h | h
      · -- slot k is the third slot, slot k+1 = j
        have T := third_facts hσ hF J k (by omega) (by omega) (by omega) hsj
        have q1 := T.1
        have q2 := T.2.1
        rw [J.t1, ← hsj, ← h] at q2
        rw [← hsj, ← h] at q1
        rw [← hss] at hcl ⊢
        exact (loc_third_a _ hs8 _ ht8 _ ht8' _ hD8 _ hD8' hwt q1 q2 hdel).trans hcl
      · -- slot k = j+1, slot k+1 is the third slot
        have T := third_facts hσ hF J (k + 1) (by omega) (by omega) (by omega)
          (by rw [sg_succ, ← hss]; exact hsj)
        have q3 := T.2.2.1
        have q4 := T.2.2.2
        rw [J.t0, ← hsj, ← h] at q3
        rw [← hsj, ← h] at q4
        rw [← hss] at hcl ⊢
        exact (loc_third_b _ hs8 _ ht8 _ ht8' _ hD8 _ hD8' hwt q4 q3 hdel).trans hcl

/-! ### the pairs stay distinct -/

theorem inv_dist (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true) (c : Vec)
    (a d : Asg) (ha : ∀ k, a k < 8) (hd : ∀ k, k ≤ 31 → d k = mvv σ cl c k)
    (hF : Fb σ cl a = true) (i j : Nat) (hij : i < j) (hj : j ≤ 31) :
    samePair (entry σ (tr a d) i) (entry σ (tr a d) j) = false := by
  have J := jfacts σ cl a hσ hb hF
  have hd0 : d 0 = 0 := by rw [hd 0 (by omega)]; rfl
  have hdlt : ∀ i, i ≤ 31 → d i < 8 := fun i hi => by rw [hd i hi]; exact mvv_lt σ cl c i
  rw [entry_tt, entry_tt, tt_tr a d i (ha i) (hdlt i (by omega)) hd0,
    tt_tr a d j (ha j) (hdlt j hj) hd0, hd i (by omega), hd j hj]
  have hold := dist_any hσ hF i j (by omega) hj (by omega)
  have hsi8 := sg_lt σ hσ i
  have hsj8 := sg_lt σ hσ j
  have hj1 := J.j1
  have hj31 := J.j31
  by_cases hs : sg σ i = sg σ j
  · rw [dform hσ J c i, dform hσ J c j, hs]
    rw [hs] at hold
    have sd := same_delta (sg σ j) hsj8 (if i = 0 then false else ob c i)
      (if j = 0 then false else ob c j) (inJ cl i && wb c) (inJ cl j && wb c)
      (vv c (sg σ j)) (vv_lt c _)
    by_cases hbb : (inJ cl i && wb c) = (inJ cl j && wb c)
    · rw [loc_d1 _ hsj8 _ (tt_lt a i) _ (tt_lt a j) _ (Mf_lt _ hsj8 _ _ (vv_lt c _) _) _
        (Mf_lt _ hsj8 _ _ (vv_lt c _) _) (sd.1 hbb)]
      exact hold
    · have hfl : inJ cl i ≠ inJ cl j := fun h => hbb (by rw [h])
      cases hi : inJ cl i with
      | true =>
        have hjf : inJ cl j = false := by
          cases h : inJ cl j with
          | false => rfl
          | true => exact absurd (hi.trans h.symm) hfl
        have pi := inJ_true hi
        have pj := inJ_false hjf
        have hi0 : i ≠ 0 := by omega
        have hsup : sg σ j = σ (jOf cl) := by
          rw [← hs, sg_pos σ i hi0]
          rcases pi with e | e
          · rw [e]
          · rw [e]; exact J.ss.symm
        have hwt : pc3 (sg σ j) = 1 ∨ pc3 (sg σ j) = 2 := by rw [hsup]; exact J.wt
        have T := third_facts hσ hF J j hj pj.1 pj.2 hsup
        have hdelta := sd.2 hbb hwt
        rw [hi] at hdelta
        have q : samePair (hexof (sg σ j) (tt a i ^^^ st (sg σ j) ^^^ 7))
            (hexof (sg σ j) (tt a j)) = false := by
          rw [hsup]
          rcases pi with e | e
          · rw [e, ← J.t1]; exact T.2.2.2
          · rw [e, ← J.t0]; exact T.2.2.1
        exact loc_d2a _ hsj8 _ (tt_lt a i) _ (tt_lt a j) _ (Mf_lt _ hsj8 _ _ (vv_lt c _) _) _
          (Mf_lt _ hsj8 _ _ (vv_lt c _) _) hwt q hdelta
      | false =>
        have hjt : inJ cl j = true := by
          cases h : inJ cl j with
          | true => rfl
          | false => exact absurd (hi.trans h.symm) hfl
        have pj := inJ_true hjt
        have pi := inJ_false hi
        have hj0 : j ≠ 0 := by omega
        have hsup : sg σ j = σ (jOf cl) := by
          rw [sg_pos σ j hj0]
          rcases pj with e | e
          · rw [e]
          · rw [e]; exact J.ss.symm
        have hwt : pc3 (sg σ j) = 1 ∨ pc3 (sg σ j) = 2 := by rw [hsup]; exact J.wt
        have T := third_facts hσ hF J i (by omega) pi.1 pi.2 (by rw [hs]; exact hsup)
        have hdelta := sd.2 hbb hwt
        rw [hi] at hdelta
        have q : samePair (hexof (sg σ j) (tt a i))
            (hexof (sg σ j) (tt a j ^^^ st (sg σ j) ^^^ 7)) = false := by
          rw [hsup]
          rcases pj with e | e
          · rw [e, ← J.t1]; exact T.2.1
          · rw [e, ← J.t0]; exact T.1
        exact loc_d2b _ hsj8 _ (tt_lt a i) _ (tt_lt a j) _ (Mf_lt _ hsj8 _ _ (vv_lt c _) _) _
          (Mf_lt _ hsj8 _ _ (vv_lt c _) _) hwt q hdelta
  · exact sp_diff _ hsi8 _ hsj8 _ (xor_lt8 _ (tt_lt a i) _ (mvv_lt σ cl c i)) _
      (xor_lt8 _ (tt_lt a j) _ (mvv_lt σ cl c j)) hs

/-- **Invariance.** For every skeleton σ and every class sequence cl with King Wen's budget: a
    move c that meets the conditions `Sys σ cl` maps every assignment of the fibre to an
    assignment of the fibre. (d is the slot-by-slot translation of the move.) -/
theorem inv_fibre (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true) (c : Vec)
    (hs : sat (Sys σ cl) c = true) (a d : Asg) (ha : ∀ k, a k < 8)
    (hd : ∀ k, k ≤ 31 → d k = mvv σ cl c k) (hF : Fb σ cl a = true) :
    Fb σ cl (tr a d) = true :=
  Fb_intro σ cl (tr a d)
    (fun i j hij hj => inv_dist σ cl hσ hb c a d ha hd hF i j hij hj)
    (fun k hk => inv_cls σ cl hσ hb c hs a d ha hd hF k hk)

end GPInvOpts
end Q1150

/-
  §41  THEOREM G+ FOR THE COORDINATE-MODEL FIBRE

    ident_bound : in a nonempty fibre at most 2^7 moves meeting the conditions are the identity
    gplus_fibre : (∀ k, σ k < 8) → budgetOK cl = true →
                  ((2 ^ (26 - tcount σ cl) : Nat) : Int) ∣ fibreC σ cl
  (The sub-headings "§1" to "§3" inside this section are local to it.)
-/
namespace Q1150
open SuperspaceDivisibility F2Count

section GPMainOpts
set_option synthInstance.maxSize 4096
set_option synthInstance.maxHeartbeats 0

/-! ## §1  small general facts -/

theorem filter_len_mono {α : Type} (p q : α → Bool) (h : ∀ x, p x = true → q x = true) :
    ∀ l : List α, (l.filter p).length ≤ (l.filter q).length
  | [] => Nat.le_refl 0
  | a :: l => by
    have ih := filter_len_mono p q h l
    rw [List.filter_cons, List.filter_cons]
    cases hp : p a with
    | false =>
      cases hq : q a with
      | false => simpa using ih
      | true => simp; omega
    | true => rw [h a hp]; simp; omega

theorem cntP_mono (n : Nat) (p q : Vec → Bool) (h : ∀ x, p x = true → q x = true) :
    cntP n p ≤ cntP n q := filter_len_mono p q h (vecs n)

theorem replicate_of_bits : ∀ (n : Nat) (c : Vec), c.length = n →
    (∀ i, i < n → c.getD i false = false) → c = List.replicate n false
  | 0, c, h, _ => by
    cases c with
    | nil => rfl
    | cons _ _ => simp at h
  | n+1, c, h, hb => by
    cases c with
    | nil => simp at h
    | cons b x =>
      have h0 : b = false := hb 0 (by omega)
      have hx := replicate_of_bits n x (by simpa using h) (fun i hi => hb (i + 1) (by omega))
      rw [h0, hx]; rfl

/-! ## §2  the identity choices -/

theorem Fb_W {σ cl : Nat → Nat} {a : Asg} (h : Fb σ cl a = true) : W σ cl a = 1 := by
  rw [Q1150.W_eq, h]; rfl

/-- in a nonempty fibre every support 1..7 has exactly four slots. -/
theorem four_slots (σ cl : Nat → Nat) (a : Asg) (hσ : ∀ k, σ k < 8) (hF : Fb σ cl a = true)
    (s : Nat) (h1 : 1 ≤ s) (h7 : s ≤ 7) : (Ks σ s).length = 4 := by
  have hW := Fb_W hF
  have hperm : (KA σ).Perm slots := catK_perm σ slots 8 (fun k _ => hσ k)
  have hlen : sumN (fun s => (Ks σ s).length) 8 = 31 := by
    have := hperm.length_eq
    rw [KA, catK_length] at this
    rw [this]; rfl
  simp only [sumN] at hlen
  have h0 : (Ks σ 0).length ≤ 3 := by
    cases Nat.lt_or_ge (Ks σ 0).length 4 with
    | inl h => omega
    | inr h => have := over_C σ cl h a; rw [hW] at this; exact absurd this (by decide)
  have hR : ∀ s, s < 8 → (Ks σ s).length ≤ 4 := fun s hs => by
    cases Nat.lt_or_ge (Ks σ s).length 5 with
    | inl h => omega
    | inr h => have := over_R σ cl s hs h a; rw [hW] at this; exact absurd this (by decide)
  have r1 := hR 1 (by omega)
  have r2 := hR 2 (by omega)
  have r3 := hR 3 (by omega)
  have r4 := hR 4 (by omega)
  have r5 := hR 5 (by omega)
  have r6 := hR 6 (by omega)
  have r7 := hR 7 (by omega)
  have hs : s = 1 ∨ s = 2 ∨ s = 3 ∨ s = 4 ∨ s = 5 ∨ s = 6 ∨ s = 7 := by omega
  rcases hs with e | e | e | e | e | e | e <;> subst e <;> omega

/-- so every support 1..7 has a slot other than two given neighbouring slots. -/
theorem free_slot (σ cl : Nat → Nat) (a : Asg) (hσ : ∀ k, σ k < 8) (hF : Fb σ cl a = true)
    (j s : Nat) (h1 : 1 ≤ s) (h7 : s ≤ 7) :
    ∃ k, 1 ≤ k ∧ k ≤ 31 ∧ σ k = s ∧ k ≠ j ∧ k ≠ j + 1 := by
  obtain ⟨hab, hbc, _, hmem⟩ := Q4_of_len σ s (four_slots σ cl a hσ hF s h1 h7)
  have ma := (hmem (kk σ s 0)).mpr (Or.inl rfl)
  have mc := (hmem (kk σ s 2)).mpr (Or.inr (Or.inr (Or.inl rfl)))
  by_cases ha : kk σ s 0 ≠ j ∧ kk σ s 0 ≠ j + 1
  · exact ⟨_, ma.1, ma.2.1, ma.2.2, ha.1, ha.2⟩
  · by_cases hc : kk σ s 2 ≠ j ∧ kk σ s 2 ≠ j + 1
    · exact ⟨_, mc.1, mc.2.1, mc.2.2, hc.1, hc.2⟩
    · exfalso; omega

/-- a coordinate of s (s ≠ 0). -/
def low (s : Nat) : Nat := if bit3 s 0 then 0 else if bit3 s 1 then 1 else 2

theorem low_cases (s : Nat) : low s = 0 ∨ low s = 1 ∨ low s = 2 := by
  unfold low
  split
  · exact Or.inl rfl
  · split
    · exact Or.inr (Or.inl rfl)
    · exact Or.inr (Or.inr rfl)

/-- one slot of support s outside the class-6 pair is not moved, and one shift bit is 0: the
    whole shift of s is 0. -/
theorem kerV : ∀ s < 8, s ≠ 0 → ∀ o v0 v1 v2 : Bool,
    ((bit3 (st s) 0 && o) ^^ (((s != 0) && v0) ^^ false)) = false →
    ((bit3 (st s) 1 && o) ^^ (((s != 0) && v1) ^^ false)) = false →
    ((bit3 (st s) 2 && o) ^^ (((s != 0) && v2) ^^ false)) = false →
    (if low s = 0 then v0 else if low s = 1 then v1 else v2) = false →
    v0 = false ∧ v1 = false ∧ v2 = false := by decide

/-- a class-6 slot is not moved and its shift is 0: w = 0 (the support has weight 1 or 2). -/
theorem kerW : ∀ s < 8, (pc3 s = 1 ∨ pc3 s = 2) → ∀ o w : Bool,
    ((bit3 (st s) 0 && o) ^^ (((s != 0) && false) ^^ (true && w))) = false →
    ((bit3 (st s) 1 && o) ^^ (((s != 0) && false) ^^ (true && w))) = false →
    ((bit3 (st s) 2 && o) ^^ (((s != 0) && false) ^^ (true && w))) = false →
    w = false := by decide

/-- a slot is not moved, its shift and w are 0: its flip is 0. -/
theorem kerO : ∀ s < 8, ∀ o x0 x1 x2 b : Bool, x0 = false → x1 = false → x2 = false →
    ((bit3 (st s) 0 && o) ^^ (x0 ^^ (b && false))) = false →
    ((bit3 (st s) 1 && o) ^^ (x1 ^^ (b && false))) = false →
    ((bit3 (st s) 2 && o) ^^ (x2 ^^ (b && false))) = false →
    o = false := by decide

/-- seven further conditions: one shift bit of each support 1..7 is 0. -/
def Trows : List Row := [1, 2, 3, 4, 5, 6, 7].map (fun s => rw0 [31 + 3 * (s - 1) + low s])

theorem hom_Trows : Hom Trows := by
  intro r hr
  rcases List.mem_map.mp hr with ⟨s, _, rfl⟩
  rfl

/-- in a nonempty fibre, a move that is the identity and meets the seven conditions is the
    zero vector of parameters. -/
theorem ker_zero (σ cl : Nat → Nat) (a : Asg) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true)
    (hF : Fb σ cl a = true) (c : Vec) (hc : c.length = 53) (hT : sat Trows c = true)
    (hK : ker (Mrows σ cl) c = true) : c = List.replicate 53 false := by
  have J := jfacts σ cl a hσ hb hF
  have hj1 := J.j1
  have hj31 := J.j31
  have hKk : ∀ k, 1 ≤ k → k ≤ 31 → ∀ i, i < 3 →
      ((bit3 (st (σ k)) i && ob c k) ^^
        (((σ k != 0) && c.getD (31 + 3 * (σ k - 1) + i) false) ^^ (inJ cl k && wb c))) = false := by
    intro k h1 h31 i hi
    have h : dot (ofIdx (idx σ cl k 0)) c = false ∧ dot (ofIdx (idx σ cl k 1)) c = false ∧
        dot (ofIdx (idx σ cl k 2)) c = false :=
      ker_rows3 c (fun k i => ofIdx (idx σ cl k i)) slots hK k ((mem_slots k).mpr ⟨h1, h31⟩)
    rw [dot_ofIdx, dot_ofIdx, dot_ofIdx] at h
    rw [← xs_idx σ cl c k i (by omega)]
    have hi3 : i = 0 ∨ i = 1 ∨ i = 2 := by omega
    rcases hi3 with e | e | e <;> subst e
    · exact h.1
    · exact h.2.1
    · exact h.2.2
  -- the shifts
  have hv : ∀ s, 1 ≤ s → s ≤ 7 → ∀ r, r < 3 → c.getD (31 + 3 * (s - 1) + r) false = false := by
    intro s h1 h7 r hr
    obtain ⟨k, k1, k31, hsk, n1, n2⟩ := free_slot σ cl a hσ hF (jOf cl) s h1 h7
    have hin : inJ cl k = false := by
      unfold inJ
      simp [n1, n2]
    have K0 := hKk k k1 k31 0 (by omega)
    have K1 := hKk k k1 k31 1 (by omega)
    have K2 := hKk k k1 k31 2 (by omega)
    rw [hsk, hin] at K0 K1 K2
    have hlow : (if low s = 0 then c.getD (31 + 3 * (s - 1) + 0) false
        else if low s = 1 then c.getD (31 + 3 * (s - 1) + 1) false
        else c.getD (31 + 3 * (s - 1) + 2) false) = false := by
      have hTs : xs c [31 + 3 * (s - 1) + low s] = false :=
        sat_map_rw0 c (fun s => [31 + 3 * (s - 1) + low s]) [1, 2, 3, 4, 5, 6, 7] hT s
          (by simp; omega)
      have hg : c.getD (31 + 3 * (s - 1) + low s) false = false := by
        have h' : (c.getD (31 + 3 * (s - 1) + low s) false ^^ false) = false := hTs
        revert h'
        cases c.getD (31 + 3 * (s - 1) + low s) false <;> intro h' <;>
          first | rfl | exact absurd h' (by decide)
      rcases low_cases s with e | e | e <;> rw [e] at hg ⊢ <;> exact hg
    have r3 := kerV s (by omega) (by omega) (ob c k) _ _ _ K0 K1 K2 hlow
    have hr3 : r = 0 ∨ r = 1 ∨ r = 2 := by omega
    rcases hr3 with e | e | e <;> subst e
    · exact r3.1
    · exact r3.2.1
    · exact r3.2.2
  -- w
  have hw : wb c = false := by
    have K0 := hKk (jOf cl) hj1 (by omega) 0 (by omega)
    have K1 := hKk (jOf cl) hj1 (by omega) 1 (by omega)
    have K2 := hKk (jOf cl) hj1 (by omega) 2 (by omega)
    have hin : inJ cl (jOf cl) = true := by unfold inJ; simp
    have hs0 : σ (jOf cl) ≠ 0 := by
      intro e
      have hw := J.wt
      rw [e] at hw
      revert hw
      show ¬ (pc3 0 = 1 ∨ pc3 0 = 2)
      decide
    have hs8 := hσ (jOf cl)
    rw [hin, hv _ (by omega) (by omega) 0 (by omega)] at K0
    rw [hin, hv _ (by omega) (by omega) 1 (by omega)] at K1
    rw [hin, hv _ (by omega) (by omega) 2 (by omega)] at K2
    exact kerW (σ (jOf cl)) hs8 J.wt (ob c (jOf cl)) (wb c) K0 K1 K2
  -- the flips
  have ho : ∀ k, 1 ≤ k → k ≤ 31 → ob c k = false := by
    intro k k1 k31
    have K0 := hKk k k1 k31 0 (by omega)
    have K1 := hKk k k1 k31 1 (by omega)
    have K2 := hKk k k1 k31 2 (by omega)
    rw [hw] at K0 K1 K2
    have hx : ∀ r, r < 3 → ((σ k != 0) && c.getD (31 + 3 * (σ k - 1) + r) false) = false := by
      intro r hr
      by_cases hs0 : σ k = 0
      · rw [hs0]; rfl
      · have hs8 := hσ k
        rw [hv (σ k) (by omega) (by omega) r hr]
        exact Bool.and_false _
    exact kerO (σ k) (hσ k) (ob c k) _ _ _ (inJ cl k) (hx 0 (by omega)) (hx 1 (by omega))
      (hx 2 (by omega)) K0 K1 K2
  apply replicate_of_bits 53 c hc
  intro i hi
  by_cases h31 : i < 31
  · have h := ho (i + 1) (by omega) (by omega)
    have e : ob c (i + 1) = c.getD i false := by
      show c.getD (i + 1 - 1) false = c.getD i false
      rw [Nat.add_sub_cancel]
    rw [← e]; exact h
  · by_cases h52 : i < 52
    · have h := hv ((i - 31) / 3 + 1) (by omega) (by omega) ((i - 31) % 3) (by omega)
      have e : 31 + 3 * ((i - 31) / 3 + 1 - 1) + (i - 31) % 3 = i := by omega
      rw [e] at h; exact h
    · have e : i = 52 := by omega
      rw [e]; exact hw

/-- **The identity choices.** In a nonempty fibre at most 2^7 moves that meet the conditions
    are the identity. -/
theorem ident_bound (σ cl : Nat → Nat) (a : Asg) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true)
    (hF : Fb σ cl a = true) :
    cntP 53 (fun c => sat (Sys σ cl) c && ker (Mrows σ cl) c) ≤ 2 ^ 7 := by
  have h1 : cntP 53 (fun c => sat (Sys σ cl) c && ker (Mrows σ cl) c)
      ≤ cntP 53 (sat (rowsOf (Mrows σ cl))) :=
    cntP_mono 53 _ _ (fun c h => by
      rw [sat_rowsOf]; exact ((Bool.and_eq_true _ _).mp h).2)
  have z : ∀ c, c ∈ vecs 53 → sat (Trows ++ rowsOf (Mrows σ cl)) c = true →
      c = List.replicate 53 false := fun c hc h => by
    rw [sat_append, sat_rowsOf] at h
    have h' := (Bool.and_eq_true _ _).mp h
    exact ker_zero σ cl a hσ hb hF c ((mem_vecs 53 c).mp hc) h'.1 h'.2
  have h2 : cntP 53 (sat (rowsOf (Mrows σ cl))) ≤ 2 ^ Trows.length :=
    ker_bound 53 _ Trows (hom_rowsOf _) hom_Trows (fun c c' hc hc' h h' => by
      rw [z c hc h, z c' hc' h'])
  exact Nat.le_trans h1 h2

/-! ## §3  THEOREM G+ FOR THE COORDINATE-MODEL FIBRE -/

/-- the fibre as a set of bit vectors of length 93 (three bits per slot 1..31). -/
def Yb (σ cl : Nat → Nat) (x : Vec) : Bool := Fb σ cl (wr slots x (fun _ => 0))

/-- the coordinate-model fibre of SuperspaceDivisibility.lean is the number of these vectors. -/
theorem fibre_eq (σ cl : Nat → Nat) : fibreC σ cl = ((cntP 93 (Yb σ cl) : Nat) : Int) :=
  bridge slots (Fb σ cl) (fun _ => 0)

theorem wr_vadd0 (K : List Nat) (x u : Vec) (hx : x.length = 3 * K.length)
    (hu : u.length = 3 * K.length) :
    wr K (vadd x u) (fun _ => 0) = tr (wr K x (fun _ => 0)) (wr K u (fun _ => 0)) := by
  have h := wr_vadd K x u (fun _ => 0) (fun _ => 0) hx hu
  have e : tr (fun _ => 0) (fun _ => 0) = (fun _ => 0 : Asg) := funext fun _ => Nat.xor_self 0
  rw [e] at h
  exact h

/-- every move that meets the conditions maps the fibre onto itself. -/
theorem gplus_inv (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true) :
    ∀ c, c ∈ vecs 53 → sat (Sys σ cl) c = true → ∀ x, x ∈ vecs (Mrows σ cl).length →
      Yb σ cl (vadd x (mulM (Mrows σ cl) c)) = Yb σ cl x :=
  inv_of_imp (Mrows σ cl) 53 (Sys σ cl) (Yb σ cl) (fun c _ hs x hx hY => by
    have hx93 : x.length = 3 * slots.length := by
      rw [(mem_vecs _ x).mp hx, Mrows_length]; rfl
    have hu93 : (mulM (Mrows σ cl) c).length = 3 * slots.length := by
      rw [mulM_length, Mrows_length]; rfl
    show Fb σ cl (wr slots (vadd x (mulM (Mrows σ cl) c)) (fun _ => 0)) = true
    rw [wr_vadd0 slots x _ hx93 hu93]
    exact inv_fibre σ cl hσ hb c hs (wr slots x (fun _ => 0))
      (wr slots (mulM (Mrows σ cl) c) (fun _ => 0))
      (wr_lt slots x _ (fun _ => by decide)) (fun k hk => wr_move σ cl c k hk) hY)

/-- **Theorem G+, per fibre, by counting families.** For every skeleton σ and every class
    sequence cl with King Wen's budget, 2^(26 - t) divides the coordinate-model fibre, where
    t = `tcount σ cl` is the number of class-3 boundaries whose supports differ in exactly one
    coordinate. The proof uses only: the 53-bit moves, the at most 20 + t conditions
    (`Sys_length`), that a move meeting them maps the fibre into itself (`inv_fibre`), that at
    most 2^7 of them are the identity (`ident_bound`), and orbit counting (`family_dvd`). -/
theorem gplus_fibre (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true) :
    ((2 ^ (26 - tcount σ cl) : Nat) : Int) ∣ fibreC σ cl := by
  rw [fibre_eq]
  apply Int.natCast_dvd_natCast.mpr
  cases Classical.em (∃ x, x ∈ vecs 93 ∧ Yb σ cl x = true) with
  | inl hne =>
    obtain ⟨x, _, hY⟩ := hne
    have hK := ident_bound σ cl (wr slots x (fun _ => 0)) hσ hb hY
    have h := gplus_shape (Mrows σ cl) (Sys σ cl) (Yb σ cl) (tcount σ cl) (hom_Sys σ cl)
      (Sys_length σ cl hσ hb) (gplus_inv σ cl hσ hb) hK
    rw [Mrows_length] at h
    exact h
  | inr hne =>
    have h0 : cntP 93 (Yb σ cl) = 0 := by
      have e : cntP 93 (Yb σ cl) = cntP 93 (fun _ => false) :=
        cntP_congr _ _ _ (fun x hx => by
          cases h : Yb σ cl x with
          | false => rfl
          | true => exact absurd ⟨x, hx, h⟩ hne)
      rw [e]
      exact filter_len_any_false _ _ (any_false _)
    rw [h0]
    exact Nat.dvd_zero _

end GPMainOpts
end Q1150

/-
  §42  2^13 FOR EVERY FIBRE; THE FAMILY; 2^14 * 3 FOR THE V2 CELLS AND THE TOTAL

  The cells and the total use `gplus_fibre_13`, Step 1 and Step 6 of Part 1 (`cell_six`, the
  six coordinate permutations). The closure census (lean/README.md), not this file, checks what
  they do not use: its 29 named Walsh/character definitions of Part 1 and all of §3, §9-§12.
-/
namespace Q1150
open SuperspaceDivisibility F2Count

/-- t ≤ 13: there are 13 class-3 boundaries. -/
theorem tcount_le (σ cl : Nat → Nat) (hb : budgetOK cl = true) : tcount σ cl ≤ 13 := by
  simp only [budgetOK, Bool.and_eq_true, beq_iff_eq] at hb
  obtain ⟨⟨⟨_, b3⟩, _⟩, _⟩ := hb
  rw [List.filter_map, List.length_map] at b3
  have h := filter_len_mono (tp σ cl) (fun k => cl k == 3)
    (fun k hk => by
      unfold tp at hk
      exact ((Bool.and_eq_true _ _).mp hk).1) (List.range 31)
  unfold tcount
  exact Nat.le_trans h (Nat.le_of_eq b3)

/-- **Every fibre, by counting families: 2^13.** -/
theorem gplus_fibre_13 (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true) :
    ((2 ^ 13 : Nat) : Int) ∣ fibreC σ cl :=
  Int.dvd_trans
    (Int.natCast_dvd_natCast.mpr (Nat.pow_dvd_pow 2 (by have := tcount_le σ cl hb; omega)))
    (gplus_fibre σ cl hσ hb)

/-- a translation that fixes a vector is the zero translation. -/
theorem vadd_fix : ∀ (y u : Vec), y.length = u.length → vadd y u = y →
    u = List.replicate u.length false
  | [], u, h, _ => by
    cases u with
    | nil => rfl
    | cons _ _ => simp at h
  | y0 :: y, [], h, _ => by simp at h
  | y0 :: y, u0 :: u, h, e => by
    have hl : y.length = u.length := by simpa using h
    have e' : (y0 ^^ u0) :: vadd y u = y0 :: y := e
    injection e' with e1 e2
    have hu0 : u0 = false := by
      revert e1; cases y0 <;> cases u0 <;> intro e1 <;> first | rfl | exact absurd e1 (by decide)
    have ih := vadd_fix y u hl e2
    show u0 :: u = false :: List.replicate u.length false
    rw [hu0, ← ih]

/-- **The family.** In a nonempty fibre the translations x ↦ x + M c, c a move meeting the
    conditions, are 2^d in number with d ≥ 26 - t; each maps the fibre onto itself; and none
    but the zero translation fixes any vector. So the fibre is a union of orbits of exactly
    2^d ≥ 2^(26 - t) assignments. -/
theorem gplus_family (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true)
    (x : Vec) (hY : Yb σ cl x = true) :
    ∃ d, 26 - tcount σ cl ≤ d ∧
      cntP 93 (img (Mrows σ cl) 53 (Sys σ cl)) = 2 ^ d ∧
      (∀ u, u ∈ vecs 93 → img (Mrows σ cl) 53 (Sys σ cl) u = true →
        ∀ y, y ∈ vecs 93 → Yb σ cl (vadd y u) = Yb σ cl y) ∧
      (∀ u, u ∈ vecs 93 → ∀ y, y ∈ vecs 93 → vadd y u = y → u = List.replicate 93 false) := by
  have hK := ident_bound σ cl (wr slots x (fun _ => 0)) hσ hb hY
  obtain ⟨d, hd, he⟩ := family_size (Mrows σ cl) 53 (Sys σ cl) 7 (hom_Sys σ cl) hK
  rw [Mrows_length] at he
  have hlen := Sys_length σ cl hσ hb
  refine ⟨d, by omega, he, ?_, ?_⟩
  · intro u _ hi y hy
    unfold img at hi
    rw [List.any_eq_true] at hi
    obtain ⟨c, hc, h1⟩ := hi
    have h1' := (Bool.and_eq_true _ _).mp h1
    have hinv := gplus_inv σ cl hσ hb c hc h1'.1 y (by rw [Mrows_length]; exact hy)
    rw [eq_of_beq h1'.2] at hinv
    exact hinv
  · intro u hu y hy e
    have h := vadd_fix y u (by rw [(mem_vecs 93 y).mp hy, (mem_vecs 93 u).mp hu]) e
    rw [(mem_vecs 93 u).mp hu] at h
    exact h

/-! ### the V2 cells and the count, by families and the six coordinate permutations -/

theorem Gs_dvd13 (k d : Nat) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) :
    ((2 ^ 13 : Nat) : Int) ∣ Gs k d σ := by
  unfold Gs
  apply sumOver_dvd
  intro c
  unfold SuperspaceDivisibility.Bind
  cases hb : budgetOK c with
  | false => simp
  | true => exact Int.dvd_trans (gplus_fibre_13 σ c hσ hb) (Int.dvd_mul_left _ _)

/-- **2^14 * 3 divides every V2 cell, by counting families** (2^13 per fibre from the free
    moves, 6 from the coordinate permutations of Step 6; the Fourier argument is not used). -/
theorem cellV2_dvd_families : ∀ k d : Nat, 2 ^ 14 * 3 ∣ cellV2 k d := by
  intro k d
  have h : ((2 ^ 13 : Nat) : Int) ∣ sumOver slots (fun σ => Gs k d σ * rsel σ) (fun _ => 0) := by
    apply sumOver_dvd_bd
    intro σ hb ho
    exact Int.dvd_trans (Gs_dvd13 k d σ (fun j => by
      by_cases hj : j ∈ slots
      · exact hb j hj
      · rw [ho j hj]; omega)) (Int.dvd_mul_right _ _)
  obtain ⟨q, hq⟩ := h
  apply Int.natCast_dvd_natCast.mp
  rw [cell_six, hq]
  refine ⟨q, ?_⟩
  have e0 : (2 ^ 14 * 3 : Nat) = 6 * 2 ^ 13 := by rw [Nat.pow_succ]
  have e : ((2 ^ 14 * 3 : Nat) : Int) = 6 * ((2 ^ 13 : Nat) : Int) := by
    rw [e0, Int.natCast_mul]; rfl
  rw [e, Int.mul_assoc]

/-- **2^14 * 3 divides the number of superspace sequences, by counting families.** -/
theorem superCount_dvd_families : 2 ^ 14 * 3 ∣ superCount := by
  rw [superCount_eq]; exact cellV2_dvd_families 31 0

end Q1150

/-
  §43  N(c), THE CLASS-SEQUENCE CENSUS

  `censusC c0` is the number of superspace sequences whose class sequence `bseq l` is c0.
  This section was generated by a script from Part 1 of this file: the five proofs marked
  "copied" are Part 1's point_eq, cell_eq, Gs_pm, Gs_zero_bad and cell_six with "boundary k
  has class d" replaced by "the class sequence is c0". The script is not in this repository;
  Lean checks the text between the two markers like any other text of the file.
-/
-- BEGIN GENERATED (N(c): copied from Part 1 by a script)
namespace Q1150
open SuperspaceDivisibility F2Count

/-- N(c): the number of superspace sequences whose class sequence (the 31 distances across the
    boundaries between consecutive pairs, `bseq`) is c. -/
def censusC (c0 : List Nat) : Nat := ((seqs 64).filter fun l => isSuper l && bseq l == c0).length

/-- indicator: c has King Wen's budget and is the class sequence c0. -/
def BindC (c0 : List Nat) (c : Asg) : Int :=
  if (budgetOK c && ((List.range 31).map c == c0)) then 1 else 0

/-- the part of N(c0) that lies over the skeleton sigma. -/
def GsC (c0 : List Nat) (σ : Asg) : Int :=
  sumOver (List.range 31) (fun c => BindC c0 c * fibreC σ c) (fun _ => 0)

theorem BindC_congr (c0 : List Nat) (c c' : Asg) (h : ∀ j, j ∈ List.range 31 → c j = c' j) :
    BindC c0 c = BindC c0 c' := by
  have hm : (List.range 31).map c = (List.range 31).map c' := List.map_congr_left h
  have hb : budgetOK c = budgetOK c' := by simp only [budgetOK, hm]
  unfold BindC; rw [hb, hm]

theorem super_charC (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (t : Asg) (c0 : List Nat) :
    (isSuper (LL σ t) && bseq (LL σ t) == c0) =
      (distinctOK σ t && budgetOK (clsAt σ t) && ((List.range 31).map (clsAt σ t) == c0)) := by
  rw [LL_super σ hσ t, LL_bseq]

-- copied: point_eq

theorem point_eqC (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) (t : Asg) (c0 : List Nat) :
    (if (isSuper (LL σ t) && bseq (LL σ t) == c0) then (1 : Int) else 0) =
      sumOver (List.range 31) (fun c => BindC c0 c * W σ c t) (fun _ => 0) := by
  rw [super_charC σ hσ t c0]
  have e : ∀ c : Asg, BindC c0 c * W σ c t =
      if ((List.range 31).all fun j => c j == clsAt σ t j) then
        BindC c0 c * (if distinctOK σ t then 1 else 0) else 0 := by
    intro c
    have ha : ((List.range 31).all fun j => clsAt σ t j == c j) =
        ((List.range 31).all fun j => c j == clsAt σ t j) :=
      all_congr_mem _ _ _ fun j _ => by
        rw [Bool.eq_iff_iff]; simp only [beq_iff_eq]; exact eq_comm
    unfold W
    rw [ha]
    cases distinctOK σ t <;> cases ((List.range 31).all fun j => c j == clsAt σ t j) <;> simp
  rw [sumOver_congr _ e]
  rw [sumOver_delta (List.range 31) List.nodup_range (clsAt σ t) (fun j _ => clsAt_lt σ hσ t j)
    (BindC c0 (clsAt σ t) * (if distinctOK σ t then 1 else 0)) _
    (fun c hc => by rw [BindC_congr c0 c (clsAt σ t) hc])]
  unfold BindC
  cases distinctOK σ t <;> cases budgetOK (clsAt σ t) <;> cases ((List.range 31).map (clsAt σ t) == c0) <;> rfl

-- copied: cell_eq
theorem cell_eqC (c0 : List Nat) :
    ((censusC c0 : Nat) : Int) = sumOver slots (GsC c0) (fun _ => 0) := by
  -- 1. length of a filtered list = sum of indicators
  have s1 : ((censusC c0 : Nat) : Int) =
      lsum (seqs (2 * 32)) (fun l => if (isSuper l && bseq l == c0) then 1 else 0) :=
    filter_length _ _
  -- 2. C1: sum over the 32 entries
  have s2 := C1sum 32 (fun l => if (isSuper l && bseq l == c0) then (1 : Int) else 0)
    (fun l hl hc => by
      cases hs : isSuper l with
      | false => simp
      | true =>
        exfalso
        have h1 : c1ok l = true := by
          simp only [isSuper, Bool.and_eq_true] at hs; exact hs.1.1.2
        rw [c1L_of_c1ok l hl h1] at hc; cases hc)
  -- 3. C4: the first entry is 63
  have s3 : lsum (seqs (31+1)) (fun e => if (isSuper (pairs e) && bseq (pairs e) == c0)
        then (1 : Int) else 0) =
      lsum (seqs 31) (fun e => if (isSuper (pairs (63 :: e)) && bseq (pairs (63 :: e)) == c0)
        then (1 : Int) else 0) := by
    rw [S_succ]
    apply lsum_congr
    intro e _
    rw [lsum_congr (List.range 64) (g := fun x => if x = 63 then
        (if (isSuper (pairs (x :: e)) && bseq (pairs (x :: e)) == c0) then (1 : Int) else 0)
        else 0) (fun x _ => by
      by_cases ex : x = 63
      · rw [if_pos ex]
      · rw [if_neg ex]
        cases hs : isSuper (pairs (x :: e)) with
        | false => simp
        | true =>
          exfalso
          have h4 : c4ok (pairs (x :: e)) = true := by
            simp only [isSuper, Bool.and_eq_true] at hs; exact hs.1.2
          exact ex (c4_head x _ h4))]
    exact lsum_delta _ List.nodup_range 63 (List.mem_range.mpr (by omega)) _
  -- 4. entries as (sigma, t)
  have s4 := Ssum 31 1 (fun e => if (isSuper (pairs (63 :: e)) && bseq (pairs (63 :: e)) == c0)
        then (1 : Int) else 0) (fun _ => 0) (fun _ => 0)
  rw [s1, s2]
  show lsum (seqs (31+1)) _ = _
  rw [s3, s4]
  -- 5, 6. pointwise, then exchange the sums over t and c
  show sumOver slots _ _ = _
  apply sumOver_congr_bd
  intro σ hσb hσo
  have hσ : ∀ j, σ j < 8 := by
    intro j
    by_cases hj : j ∈ slots
    · exact hσb j hj
    · rw [hσo j hj]; omega
  show sumOver slots _ _ = sumOver (List.range 31) (fun c => BindC c0 c * fibreC σ c) (fun _ => 0)
  have e6 : sumOver (List.range 31) (fun c => BindC c0 c * fibreC σ c) (fun _ => 0) =
      sumOver slots (fun t => sumOver (List.range 31) (fun c => BindC c0 c * W σ c t) (fun _ => 0))
        (fun _ => 0) := by
    rw [sumOver_comm2]
    apply sumOver_congr
    intro c
    exact (sumOver_const_mul slots (BindC c0 c) (W σ c) (fun _ => 0)).symm
  rw [e6]
  apply sumOver_congr_bd
  intro t htb _
  have hL : pairs (63 :: listFrom (fun i => hexof (σ i) (t i)) 1 31) = LL σ t := by
    show _ = pairs (entry σ t 0 :: listFrom (entry σ t) 1 31)
    rw [entry_zero, listFrom_congr (fun i => hexof (σ i) (t i)) (entry σ t) 31 1 (fun i h1 h2 => by
      rw [entry_pos σ t i (by omega),
        Nat.mod_eq_of_lt (htb i ((mem_slots i).mpr ⟨h1, by omega⟩))])]
  rw [hL]
  exact point_eqC σ hσ t c0

-- copied: Gs_pm
theorem GsC_pm (g : Nat) (hg : g < 6) (c0 : List Nat) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) :
    GsC c0 (fun j => pm g (σ j)) = GsC c0 σ := by
  unfold GsC
  exact sumOver_congr _ (fun c => by rw [fibreC_pm g hg σ hσ c]) _

-- copied: Gs_zero_bad
theorem GsC_zero_bad (c0 : List Nat) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8)
    (h : ¬ ((Ks σ 1).length = 4 ∧ (Ks σ 2).length = 4 ∧ (Ks σ 4).length = 4)) : GsC c0 σ = 0 := by
  unfold GsC
  rw [sumOver_congr (List.range 31) (G := fun _ => 0) (fun c => by
    have : fibreC σ c = 0 := by
      unfold fibreC
      rw [sumOver_congr _ (G := fun _ => 0) (fun t => W_zero_bad σ hσ h c t), sumOver_zero]
    rw [this, Int.mul_zero]), sumOver_zero]

-- copied: cell_six
theorem cell_sixC (c0 : List Nat) :
    ((censusC c0 : Nat) : Int) =
      6 * sumOver slots (fun σ => GsC c0 σ * rsel σ) (fun _ => 0) := by
  rw [cell_eqC]
  have hpt : ∀ σ : Asg, (∀ j, σ j < 8) → GsC c0 σ =
      GsC c0 (fun j => pm 0 (σ j)) * rsel (fun j => pm 0 (σ j)) +
      GsC c0 (fun j => pm 1 (σ j)) * rsel (fun j => pm 1 (σ j)) +
      GsC c0 (fun j => pm 2 (σ j)) * rsel (fun j => pm 2 (σ j)) +
      GsC c0 (fun j => pm 3 (σ j)) * rsel (fun j => pm 3 (σ j)) +
      GsC c0 (fun j => pm 4 (σ j)) * rsel (fun j => pm 4 (σ j)) +
      GsC c0 (fun j => pm 5 (σ j)) * rsel (fun j => pm 5 (σ j)) := by
    intro σ hσ
    rw [GsC_pm 0 (by omega) c0 σ hσ, GsC_pm 1 (by omega) c0 σ hσ, GsC_pm 2 (by omega) c0 σ hσ,
      GsC_pm 3 (by omega) c0 σ hσ, GsC_pm 4 (by omega) c0 σ hσ, GsC_pm 5 (by omega) c0 σ hσ]
    by_cases h : (Ks σ 1).length = 4 ∧ (Ks σ 2).length = 4 ∧ (Ks σ 4).length = 4
    · have r1 := rsum_one σ hσ h
      rw [← Int.mul_add, ← Int.mul_add, ← Int.mul_add, ← Int.mul_add, ← Int.mul_add, r1,
        Int.mul_one]
    · rw [GsC_zero_bad c0 σ hσ h]; simp
  have hone : ∀ g, g < 6 →
      sumOver slots (fun σ => GsC c0 (fun j => pm g (σ j)) * rsel (fun j => pm g (σ j)))
        (fun _ => 0) = sumOver slots (fun σ => GsC c0 σ * rsel σ) (fun _ => 0) := by
    intro g hg
    rw [sumOver_pm g hg slots (fun σ => GsC c0 σ * rsel σ) (fun _ => 0)]
    have z : (fun _ : Nat => pm g 0) = fun _ => 0 := by funext _; exact pm_0 g hg
    rw [z]
  rw [sumOver_congr_bd slots _ _ (fun _ => 0) (fun σ hb ho => hpt σ (fun j => by
    by_cases hj : j ∈ slots
    · exact hb j hj
    · rw [ho j hj]; omega))]
  rw [sumOver_add, sumOver_add, sumOver_add, sumOver_add, sumOver_add,
    hone 0 (by omega), hone 1 (by omega), hone 2 (by omega), hone 3 (by omega), hone 4 (by omega),
    hone 5 (by omega)]
  omega

/-! ### N(c) by families -/

theorem GsC_dvd13 (c0 : List Nat) (σ : Nat → Nat) (hσ : ∀ k, σ k < 8) :
    ((2 ^ 13 : Nat) : Int) ∣ GsC c0 σ := by
  unfold GsC
  apply sumOver_dvd
  intro c
  unfold BindC
  cases hb : budgetOK c with
  | false => simp
  | true => exact Int.dvd_trans (gplus_fibre_13 σ c hσ hb) (Int.dvd_mul_left _ _)

/-- **2^14 * 3 divides every class-sequence census N(c), by counting families**: 2^13 per fibre
    from the free moves (`gplus_fibre_13`), 6 from the coordinate permutations (Step 6). -/
theorem censusC_dvd_families : ∀ c0 : List Nat, 2 ^ 14 * 3 ∣ censusC c0 := by
  intro c0
  have h : ((2 ^ 13 : Nat) : Int) ∣ sumOver slots (fun σ => GsC c0 σ * rsel σ) (fun _ => 0) := by
    apply sumOver_dvd_bd
    intro σ hb ho
    exact Int.dvd_trans (GsC_dvd13 c0 σ (fun j => by
      by_cases hj : j ∈ slots
      · exact hb j hj
      · rw [ho j hj]; omega)) (Int.dvd_mul_right _ _)
  obtain ⟨q, hq⟩ := h
  apply Int.natCast_dvd_natCast.mp
  rw [cell_sixC, hq]
  refine ⟨q, ?_⟩
  have e0 : (2 ^ 14 * 3 : Nat) = 6 * 2 ^ 13 := by rw [Nat.pow_succ]
  have e : ((2 ^ 14 * 3 : Nat) : Int) = 6 * ((2 ^ 13 : Nat) : Int) := by
    rw [e0, Int.natCast_mul]; rfl
  rw [e, Int.mul_assoc]

/-- the same with the Fourier bound of SuperspaceDivisibility.lean (2^20 per fibre): N(c) is
    divisible by 2^21 * 3. (N(c) was not a statement of that file.) -/
theorem censusC_dvd : ∀ c0 : List Nat, 2 ^ 21 * 3 ∣ censusC c0 := by
  intro c0
  have hG : ∀ σ : Nat → Nat, (∀ k, σ k < 8) → ((2 ^ 20 : Nat) : Int) ∣ GsC c0 σ := by
    intro σ hσ
    unfold GsC
    apply sumOver_dvd
    intro c
    unfold BindC
    cases hb : budgetOK c with
    | false => simp
    | true => exact Int.dvd_trans (fibreC_dvd σ c hσ hb) (Int.dvd_mul_left _ _)
  have h : ((2 ^ 20 : Nat) : Int) ∣ sumOver slots (fun σ => GsC c0 σ * rsel σ) (fun _ => 0) := by
    apply sumOver_dvd_bd
    intro σ hb ho
    exact Int.dvd_trans (hG σ (fun j => by
      by_cases hj : j ∈ slots
      · exact hb j hj
      · rw [ho j hj]; omega)) (Int.dvd_mul_right _ _)
  obtain ⟨q, hq⟩ := h
  apply Int.natCast_dvd_natCast.mp
  rw [cell_sixC, hq]
  refine ⟨q, ?_⟩
  have e0 : (2 ^ 21 * 3 : Nat) = 6 * 2 ^ 20 := by rw [Nat.pow_succ]
  have e : ((2 ^ 21 * 3 : Nat) : Int) = 6 * ((2 ^ 20 : Nat) : Int) := by
    rw [e0, Int.natCast_mul]; rfl
  rw [e, Int.mul_assoc]

/-- non-vacuity: King Wen is counted by N(c) for its own class sequence. -/
theorem kw_census_pos : 0 < censusC (bseq KW) := by
  unfold censusC
  apply List.length_pos_of_mem (a := KW)
  rw [List.mem_filter]
  refine ⟨mem_seqs_of KW (by decide), ?_⟩
  rw [kw_isSuper]; simp

end Q1150
-- END GENERATED (N(c): copied from Part 1 by a script)

/-
  §44  controls: Theorem G+ on King Wen's fibre and on two recorded fibres

  Kernel `decide` only. Every "must fail" claim is a theorem that the claim is FALSE.
-/
namespace Q1150
open SuperspaceDivisibility F2Count

/-- King Wen's skeleton, class sequence and assignment, read off the sequence itself
    (the same three functions as `kw_in_model` in SuperspaceDivisibility.lean). -/
def kσ : Nat → Nat := fun k => (skel SuperspaceDivisibility.KW).getD k 0
def kc : Nat → Nat := fun k => (bseq SuperspaceDivisibility.KW).getD k 0
def ka : Asg := fun k => SuperspaceDivisibility.KW.getD (2 * k) 0 % 8

theorem getD_ge : ∀ (l : List Nat) (k : Nat), l.length ≤ k → l.getD k 0 = 0
  | [], _, _ => rfl
  | _ :: l, 0, h => by simp at h
  | _ :: l, k+1, h => by
    show l.getD k 0 = 0
    exact getD_ge l k (by simpa using h)

theorem kσ_lt : ∀ k, kσ k < 8 := by
  intro k
  by_cases h : k < 32
  · have h32 : ∀ k, k < 32 → kσ k < 8 := by decide +kernel
    exact h32 k h
  · unfold kσ
    rw [getD_ge _ k (by rw [kw_skel]; show 32 ≤ k; omega)]; decide

theorem kw_Fb : Fb kσ kc ka = true := by decide +kernel

/-! ### the numbers of King Wen's fibre (they equal the blind Python check's
    `FIBRE tsv:kw t=7 rows=27 rank=26 log2H=20`) -/

theorem kw_j : jOf kc = 18 := by decide +kernel
theorem kw_tcount : tcount kσ kc = 7 := by decide +kernel
/-- the bound 20 + t on the number of conditions is attained on King Wen's fibre. -/
theorem kw_rows : (Sys kσ kc).length = 20 + 7 := by decide +kernel
/-- the 27 conditions have rank 26. -/
theorem kw_rank : rank 53 (Sys kσ kc) = 26 := by decide +kernel
/-- the moves have exactly 2^7 identity choices there (rank 46 of 53) ... -/
theorem kw_rank_M : rank 53 (rowsOf (Mrows kσ kc)) = 46 := by decide +kernel
/-- ... and all of them meet the conditions. -/
theorem kw_rank_all : rank 53 (Sys kσ kc ++ rowsOf (Mrows kσ kc)) = 46 := by decide +kernel

/-- **King Wen's family has exactly 2^20 members**: the translations by moves that meet the
    conditions of King Wen's fibre number 2^20 (the theorem promises at least 2^(26-7) = 2^19). -/
theorem kw_img : cntP 93 (img (Mrows kσ kc) 53 (Sys kσ kc)) = 2 ^ 20 := by
  have h := img_count (Mrows kσ kc) 53 (Sys kσ kc) (hom_Sys kσ kc)
  have hKs : (fun c => sat (Sys kσ kc) c && ker (Mrows kσ kc) c)
      = sat (Sys kσ kc ++ rowsOf (Mrows kσ kc)) :=
    funext fun c => by rw [sat_append, sat_rowsOf]
  rw [hKs, hom_count 53 _ (hom_append _ _ (hom_Sys kσ kc) (hom_rowsOf _)), kw_rank_all,
    hom_count 53 _ (hom_Sys kσ kc), kw_rank, Mrows_length] at h
  have e : (2 : Nat) ^ (53 - 26) = 2 ^ 20 * 2 ^ (53 - 46) := by rw [← Nat.pow_add]
  exact Nat.eq_of_mul_eq_mul_right (Nat.two_pow_pos _) (h.symm.trans e)

/-! ### single moves on King Wen itself -/

/-- the move that sets parameter bit i only. -/
def ub (i : Nat) : Vec := (List.range 53).map (fun j => j == i)

/-- seven single-bit moves meet the conditions; each really moves King Wen (the translation is
    not zero) and the image is again in King Wen's fibre. -/
theorem kw_moves_ok : ∀ i ∈ [2, 8, 9, 10, 11, 20, 30],
    sat (Sys kσ kc) (ub i) = true ∧
    ((List.range 32).any fun k => mvv kσ kc (ub i) k != 0) = true ∧
    Fb kσ kc (fun k => ka k ^^^ mvv kσ kc (ub i) k) = true := by decide +kernel

/-- must fail: each of the other 46 single-bit moves violates a condition, and each of them
    takes King Wen OUT of the fibre. So the conditions discriminate. -/
theorem kw_moves_bad : ∀ i ∈ [0, 1, 3, 4, 5, 6, 7, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23,
      24, 25, 26, 27, 28, 29, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46,
      47, 48, 49, 50, 51, 52],
    sat (Sys kσ kc) (ub i) = false ∧
    Fb kσ kc (fun k => ka k ^^^ mvv kσ kc (ub i) k) = false := by decide +kernel

/-- a move of two flips (slots 1 and 2) meets the conditions although neither flip alone does,
    and keeps King Wen in the fibre. -/
theorem kw_move_pair :
    sat (Sys kσ kc) ((List.range 53).map (fun j => j == 0 || j == 1)) = true ∧
    Fb kσ kc (fun k => ka k ^^^ mvv kσ kc ((List.range 53).map (fun j => j == 0 || j == 1)) k)
      = true := by decide +kernel

/-! ### the theorems applied to King Wen's fibre -/

/-- King Wen as a vector of 93 bits. -/
def kx : Vec := (List.range' 1 31).flatMap (fun k => [bit3 (ka k) 0, bit3 (ka k) 1, bit3 (ka k) 2])

theorem kx_mem : kx ∈ vecs 93 := (mem_vecs 93 kx).mpr (by decide +kernel)
theorem kw_Yb : Yb kσ kc kx = true := by decide +kernel

/-- King Wen's fibre is not empty in the coordinate model. -/
theorem kw_fibre_pos : 0 < cntP 93 (Yb kσ kc) := by
  unfold cntP
  exact List.length_pos_of_mem (List.mem_filter.mpr ⟨kx_mem, kw_Yb⟩)

/-- Theorem G+ on King Wen's fibre: 2^19 divides it (t = 7), and it is not zero. -/
theorem kw_gplus : ((2 ^ 19 : Nat) : Int) ∣ fibreC kσ kc ∧ fibreC kσ kc ≠ 0 := by
  constructor
  · have h := gplus_fibre kσ kc kσ_lt kw_budget
    rw [kw_tcount] at h
    exact h
  · rw [fibre_eq]
    have := Q1150.kw_fibre_pos
    omega

/-- the family statement on King Wen's fibre. -/
theorem kw_family : ∃ d, 26 - tcount kσ kc ≤ d ∧
    cntP 93 (img (Mrows kσ kc) 53 (Sys kσ kc)) = 2 ^ d ∧
    (∀ u, u ∈ vecs 93 → img (Mrows kσ kc) 53 (Sys kσ kc) u = true →
      ∀ y, y ∈ vecs 93 → Yb kσ kc (vadd y u) = Yb kσ kc y) ∧
    (∀ u, u ∈ vecs 93 → ∀ y, y ∈ vecs 93 → vadd y u = y → u = List.replicate 93 false) :=
  gplus_family kσ kc kσ_lt kw_budget kx kw_Yb

/-- with King Wen's 27 conditions and the 2^7 identity choices the arithmetic shell gives exactly
    2^(53 - 27 - 7) = 2^19; the true family size 2^20 (`kw_img`) comes from the rank 26. -/
theorem kw_shell_exponent : 53 - (Sys kσ kc).length - 7 = 19 := by rw [kw_rows]

/-- must fail: a wrong class sequence (boundary 0 set to class 4) is not King Wen's fibre. -/
theorem kw_Fb_mut : Fb kσ (fun k => if k = 0 then 4 else kc k) ka = false := by decide +kernel

/-! ### tightness: a recorded fibre where the families give exactly 2^13

    `check_climb303_1` of `fibres_n31.tsv` (public, reports/evidence/q735_two_adic): t = 13,
    recorded size 2,293,235,712 = 2^20 * 3^7. The blind Python check has
    `FIBRE tsv:check_climb303_1 t=13 rows=33 rank=33 log2H=13`. -/

def cσ : Nat → Nat := fun k =>
  [0, 1,3,5,5,0,4,6,7,4,7,1,3,5,1,5,4,2,7,2,6,3,1,4,6,6,2,3,0,0,2,7].getD k 0
def cc : Nat → Nat := fun k =>
  [3,1,2,2,2,3,3,1,2,2,4,3,4,3,3,3,4,2,2,3,4,3,2,3,6,3,3,4,4,3,4].getD k 0

theorem climb_budget : budgetOK cc = true := by decide +kernel
theorem climb_tcount : tcount cσ cc = 13 := by decide +kernel
theorem climb_rows : (Sys cσ cc).length = 20 + 13 := by decide +kernel
/-- here the 33 conditions are independent ... -/
theorem climb_rank : rank 53 (Sys cσ cc) = 33 := by decide +kernel
theorem climb_rank_all : rank 53 (Sys cσ cc ++ rowsOf (Mrows cσ cc)) = 46 := by decide +kernel

/-- ... so the group of moves of this fibre has exactly 2^13 members: the families of
    Theorem G+ give 2^13 for this fibre and no more. (That the fibre has 2^20 * 3^7 walks is
    the recorded count, not a statement of this file.) -/
theorem climb_img : cntP 93 (img (Mrows cσ cc) 53 (Sys cσ cc)) = 2 ^ 13 := by
  have h := img_count (Mrows cσ cc) 53 (Sys cσ cc) (hom_Sys cσ cc)
  have hKs : (fun c => sat (Sys cσ cc) c && ker (Mrows cσ cc) c)
      = sat (Sys cσ cc ++ rowsOf (Mrows cσ cc)) :=
    funext fun c => by rw [sat_append, sat_rowsOf]
  rw [hKs, hom_count 53 _ (hom_append _ _ (hom_Sys cσ cc) (hom_rowsOf _)), climb_rank_all,
    hom_count 53 _ (hom_Sys cσ cc), climb_rank, Mrows_length] at h
  have e : (2 : Nat) ^ (53 - 33) = 2 ^ 13 * 2 ^ (53 - 46) := by rw [← Nat.pow_add]
  exact Nat.eq_of_mul_eq_mul_right (Nat.two_pow_pos _) (h.symm.trans e)

/-! ### a third recorded fibre, where the rank is below the number of conditions

    `r2b_min_seed13` of `fibres_n31.tsv`. The blind Python check has
    `FIBRE tsv:r2b_min_seed13 t=13 rows=33 rank=32 log2H=14`. -/

def rσ : Nat → Nat := fun k =>
  [0, 4,5,1,4,4,6,6,0,3,6,5,1,0,6,7,5,0,2,4,7,7,2,3,3,2,2,1,5,1,3,7].getD k 0
def rc : Nat → Nat := fun k =>
  [3,3,3,2,2,3,6,2,2,4,2,3,1,4,3,3,4,3,2,4,2,4,1,2,3,4,4,3,3,3,3].getD k 0

theorem r2b_budget : budgetOK rc = true := by decide +kernel
theorem r2b_tcount : tcount rσ rc = 13 := by decide +kernel
theorem r2b_rows : (Sys rσ rc).length = 33 := by decide +kernel
theorem r2b_rank : rank 53 (Sys rσ rc) = 32 := by decide +kernel
theorem r2b_rank_all : rank 53 (Sys rσ rc ++ rowsOf (Mrows rσ rc)) = 46 := by decide +kernel

end Q1150

/-
  §45  THE IDENTITY CHOICES, EXACTLY; EXACTLY 2^46 MOVES

    ident_exact  : in a nonempty fibre (a is a walk of it) the moves have exactly 2^7
                   identity choices, and every one of them meets the conditions
    moves_exact  : so the 2^53 parameter choices give exactly 2^46 distinct translations
    family_exact : and the family of the fibre has exactly 2^(46 - r) members, r the rank of
                   the conditions (stated without subtraction or division)
  Both halves of `ident_exact` are false without a walk of the fibre (`ident_needs_walk`,
  `ident_all_needs_walk`).
    piece_dvd    : a part of a fibre that the moves meeting the conditions map to itself has a
                   size divisible by 2^(26 - t) as well
  (The sub-headings "§1" to "§7" inside this section are local.)
-/
namespace Q1150
open SuperspaceDivisibility F2Count

section GPExactOpts
set_option synthInstance.maxSize 4096
set_option synthInstance.maxHeartbeats 0

/-! ## §1  exact halving -/

/-- every row of T is violated by some solution of the rows after it and of S. -/
def Wit (n : Nat) (S : List Row) : List Row → Prop
  | [] => True
  | r :: T => (∃ c0, c0 ∈ vecs n ∧ sat (T ++ S) c0 = true ∧ dot r.1 c0 = true) ∧ Wit n S T

theorem Wit_cons (n : Nat) (S : List Row) (r : Row) (T : List Row) :
    Wit n S (r :: T) =
      ((∃ c0, c0 ∈ vecs n ∧ sat (T ++ S) c0 = true ∧ dot r.1 c0 = true) ∧ Wit n S T) := rfl

/-- if each further homogeneous condition is violated by a solution of the ones after it, each
    of them halves the number of solutions exactly. -/
theorem hom_add_rows_eq (n : Nat) : ∀ (T S : List Row), Hom T → Hom S → Wit n S T →
    cntP n (sat S) = 2 ^ T.length * cntP n (sat (T ++ S))
  | [], S, _, _, _ => by
    show cntP n (sat S) = 2 ^ 0 * cntP n (sat S)
    rw [Nat.pow_zero, Nat.one_mul]
  | (a, b) :: T, S, hT, hS, hw => by
    have hb : b = false := hT (a, b) List.mem_cons_self
    subst hb
    rw [Wit_cons] at hw
    obtain ⟨⟨c0, hc0, hs0, hd0⟩, hw'⟩ := hw
    have hT' : Hom T := fun q hq => hT q (List.mem_cons_of_mem _ hq)
    have ih := hom_add_rows_eq n T S hT' hS hw'
    have h2 := half_sols n (T ++ S) a c0 (hom_append T S hT' hS) hc0 hs0 hd0
    show cntP n (sat S) = 2 ^ (T.length + 1) * cntP n (sat ((a, false) :: (T ++ S)))
    rw [Nat.pow_succ, Nat.mul_assoc, ← h2]
    exact ih

/-! ## §2  seven identity choices -/

theorem getD_map_range (f : Nat → Bool) (n i : Nat) :
    ((List.range n).map f).getD i false = if i < n then f i else false := by
  by_cases h : i < n <;> simp [h]

/-- the identity choice of support s: flip every slot of support s and shift the support by
    st s (= s for s ≠ 0). -/
def ev (σ : Nat → Nat) (s : Nat) : Vec :=
  (List.range 53).map (fun i =>
    if i < 31 then σ (i + 1) == s
    else if i < 52 then ((i - 31) / 3 + 1 == s) && bit3 (st s) ((i - 31) % 3)
    else false)

theorem ev_len (σ : Nat → Nat) (s : Nat) : (ev σ s).length = 53 := by
  unfold ev; rw [List.length_map, List.length_range]

theorem ev_ob (σ : Nat → Nat) (s k : Nat) (h1 : 1 ≤ k) (h31 : k ≤ 31) :
    ob (ev σ s) k = (σ k == s) := by
  show (ev σ s).getD (k - 1) false = (σ k == s)
  unfold ev
  rw [getD_map_range, if_pos (by omega), if_pos (by omega)]
  have e : k - 1 + 1 = k := by omega
  rw [e]

theorem ev_shift (σ : Nat → Nat) (s q i : Nat) (h1 : 1 ≤ q) (h7 : q ≤ 7) (hi : i < 3) :
    (ev σ s).getD (31 + 3 * (q - 1) + i) false = ((q == s) && bit3 (st s) i) := by
  unfold ev
  rw [getD_map_range, if_pos (by omega), if_neg (by omega), if_pos (by omega)]
  have e1 : (31 + 3 * (q - 1) + i - 31) / 3 + 1 = q := by omega
  have e2 : (31 + 3 * (q - 1) + i - 31) % 3 = i := by omega
  rw [e1, e2]

theorem ev_wb (σ : Nat → Nat) (s : Nat) : wb (ev σ s) = false := by
  show (ev σ s).getD 52 false = false
  unfold ev
  rw [getD_map_range, if_pos (by omega), if_neg (by omega), if_neg (by omega)]

theorem ker_rows3_intro (c : Vec) (R : Nat → Nat → Vec) : ∀ K : List Nat,
    (∀ j, j ∈ K → dot (R j 0) c = false ∧ dot (R j 1) c = false ∧ dot (R j 2) c = false) →
    ker (rows3 R K) c = true
  | [], _ => rfl
  | k :: K, h => by
    have hk := h k List.mem_cons_self
    have ih := ker_rows3_intro c R K (fun j hj => h j (List.mem_cons_of_mem _ hj))
    show ((!(dot (R k 0) c)) && ((!(dot (R k 1) c)) && ((!(dot (R k 2) c)) &&
        ker (rows3 R K) c))) = true
    simp only [hk.1, hk.2.1, hk.2.2, ih, Bool.not_false, Bool.and_self]

/-- one slot under the identity choice of support s: not moved. -/
theorem ev_slot : ∀ s' < 8, ∀ s < 8, s ≠ 0 → ∀ i < 3, ∀ b X : Bool,
    (s' ≠ 0 → X = ((s' == s) && bit3 (st s) i)) →
    ((bit3 (st s') i && (s' == s)) ^^ (((s' != 0) && X) ^^ (b && false))) = false := by decide

/-- the identity choice of support s is sent to 0 by the matrix of the moves (for every
    skeleton: no walk is needed for this half). -/
theorem ev_ker (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) (s : Nat) (h1 : 1 ≤ s) (h7 : s ≤ 7) :
    ker (Mrows σ cl) (ev σ s) = true := by
  unfold Mrows
  apply ker_rows3_intro
  intro k hk
  have hk' := (mem_slots k).mp hk
  have key : ∀ i, i < 3 → dot (ofIdx (idx σ cl k i)) (ev σ s) = false := by
    intro i hi
    rw [dot_ofIdx, xs_idx σ cl (ev σ s) k i (by omega), ev_ob σ s k hk'.1 hk'.2, ev_wb]
    have h8 := hσ k
    exact ev_slot (σ k) h8 s (by omega) (by omega) i hi _ _
      (fun h0 => ev_shift σ s (σ k) i (by omega) (by omega) hi)
  exact ⟨key 0 (by omega), key 1 (by omega), key 2 (by omega)⟩

theorem low_lt (s : Nat) : low s < 3 := by
  rcases low_cases s with e | e | e <;> omega

theorem st_low : ∀ s < 8, s ≠ 0 → bit3 (st s) (low s) = true := by decide

theorem sat_map_intro {α : Type} (c : Vec) (f : α → Row) : ∀ L : List α,
    (∀ i, i ∈ L → rowsat (f i) c = true) → sat (L.map f) c = true
  | [], _ => rfl
  | a :: L, h => by
    rw [List.map_cons, sat_cons]
    exact (Bool.and_eq_true _ _).mpr
      ⟨h a List.mem_cons_self, sat_map_intro c f L (fun i hi => h i (List.mem_cons_of_mem _ hi))⟩

/-- each of the seven conditions of `Trows` is violated by an identity choice that meets the
    conditions after it. -/
theorem wit_T (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) : ∀ L : List Nat,
    (∀ s, s ∈ L → 1 ≤ s ∧ s ≤ 7) → L.Nodup →
    Wit 53 (rowsOf (Mrows σ cl)) (L.map (fun s => rw0 [31 + 3 * (s - 1) + low s]))
  | [], _, _ => trivial
  | s :: L, h, nd => by
    have hs := h s List.mem_cons_self
    rw [List.nodup_cons] at nd
    rw [List.map_cons, Wit_cons]
    refine ⟨⟨ev σ s, (mem_vecs 53 _).mpr (ev_len σ s), ?_, ?_⟩,
      wit_T σ cl hσ L (fun q hq => h q (List.mem_cons_of_mem _ hq)) nd.2⟩
    · rw [sat_append, sat_rowsOf, ev_ker σ cl hσ s hs.1 hs.2]
      apply (Bool.and_eq_true _ _).mpr
      refine ⟨?_, rfl⟩
      apply sat_map_intro
      intro q hq
      have hq' := h q (List.mem_cons_of_mem _ hq)
      have hne : (q == s) = false := by
        cases hqs : q == s with
        | false => rfl
        | true => exact absurd (eq_of_beq hqs ▸ hq) nd.1
      rw [rowsat_rw0]
      show (!((ev σ s).getD (31 + 3 * (q - 1) + low q) false ^^ false)) = true
      rw [ev_shift σ s q (low q) hq'.1 hq'.2 (low_lt q), hne]
      rfl
    · show dot (ofIdx [31 + 3 * (s - 1) + low s]) (ev σ s) = true
      rw [dot_ofIdx]
      show ((ev σ s).getD (31 + 3 * (s - 1) + low s) false ^^ false) = true
      rw [ev_shift σ s s (low s) hs.1 hs.2 (low_lt s), st_low s (by omega) (by omega)]
      simp

/-! ## §3  exactly 2^7 identity choices -/

/-- in a nonempty fibre the moves have exactly 2^7 identity choices. -/
theorem ident_count (σ cl : Nat → Nat) (a : Asg) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true)
    (hF : Fb σ cl a = true) : cntP 53 (sat (rowsOf (Mrows σ cl))) = 2 ^ 7 := by
  have z : ∀ c, c ∈ vecs 53 → sat (Trows ++ rowsOf (Mrows σ cl)) c = true →
      c = List.replicate 53 false := fun c hc h => by
    rw [sat_append, sat_rowsOf] at h
    have h' := (Bool.and_eq_true _ _).mp h
    exact ker_zero σ cl a hσ hb hF c ((mem_vecs 53 c).mp hc) h'.1 h'.2
  have hle : cntP 53 (sat (Trows ++ rowsOf (Mrows σ cl))) ≤ 1 :=
    cntP_le_one 53 _ (fun c c' hc hc' h h' => by rw [z c hc h, z c' hc' h'])
  have hH : Hom (Trows ++ rowsOf (Mrows σ cl)) := hom_append _ _ hom_Trows (hom_rowsOf _)
  have hpos : 0 < cntP 53 (sat (Trows ++ rowsOf (Mrows σ cl))) := by
    rw [hom_count 53 _ hH]; exact Nat.two_pow_pos _
  have h1 : cntP 53 (sat (Trows ++ rowsOf (Mrows σ cl))) = 1 := by omega
  have h := hom_add_rows_eq 53 Trows (rowsOf (Mrows σ cl)) hom_Trows (hom_rowsOf _)
    (wit_T σ cl hσ [1, 2, 3, 4, 5, 6, 7] (by decide) (by decide))
  rw [h, h1]
  rfl

/-! ## §4  every identity choice meets the conditions -/

/-- the flip that an identity choice with w = 0 has on a slot of support s. -/
def gsel (s : Nat) (v0 v1 v2 : Bool) : Bool :=
  (s != 0) && (if low s = 0 then v0 else if low s = 1 then v1 else v2)

/-- the same, read off the parameter bits c. -/
def gs (c : Vec) (s : Nat) : Bool :=
  gsel s (c.getD (31 + 3 * (s - 1) + 0) false) (c.getD (31 + 3 * (s - 1) + 1) false)
    (c.getD (31 + 3 * (s - 1) + 2) false)

/-- a slot is not moved and w = 0: its flip is determined by the shift of its support. -/
theorem kerOv : ∀ s < 8, ∀ o v0 v1 v2 b : Bool,
    ((bit3 (st s) 0 && o) ^^ (((s != 0) && v0) ^^ (b && false))) = false →
    ((bit3 (st s) 1 && o) ^^ (((s != 0) && v1) ^^ (b && false))) = false →
    ((bit3 (st s) 2 && o) ^^ (((s != 0) && v2) ^^ (b && false))) = false →
    o = gsel s v0 v1 v2 := by decide

/-- two slots of one support of weight 1 or 2, one of them a class-6 slot, neither moved:
    w = 0. -/
theorem kerW2 : ∀ s < 8, (pc3 s = 1 ∨ pc3 s = 2) → ∀ o o' v0 v1 v2 w : Bool,
    ((bit3 (st s) 0 && o') ^^ (((s != 0) && v0) ^^ (false && w))) = false →
    ((bit3 (st s) 1 && o') ^^ (((s != 0) && v1) ^^ (false && w))) = false →
    ((bit3 (st s) 2 && o') ^^ (((s != 0) && v2) ^^ (false && w))) = false →
    ((bit3 (st s) 0 && o) ^^ (((s != 0) && v0) ^^ (true && w))) = false →
    ((bit3 (st s) 1 && o) ^^ (((s != 0) && v1) ^^ (true && w))) = false →
    ((bit3 (st s) 2 && o) ^^ (((s != 0) && v2) ^^ (true && w))) = false →
    w = false := by decide

theorem sat_one (r : Row) (x : Vec) : sat [r] x = rowsat r x := Bool.and_true _

theorem sat_sysUpTo_intro (f : Nat → List Row) (c : Vec) : ∀ n : Nat,
    (∀ k, k < n → sat (f k) c = true) → sat (sysUpTo f n) c = true
  | 0, _ => rfl
  | n+1, h => by
    show sat (sysUpTo f n ++ f n) c = true
    rw [sat_append]
    exact (Bool.and_eq_true _ _).mpr
      ⟨sat_sysUpTo_intro f c n (fun k hk => h k (by omega)), h n (by omega)⟩

theorem crd_lt (m i : Nat) (h : i ∈ crd m) : i < 3 := by
  have h1 : i ∈ [0, 1, 2] := (List.mem_filter.mp h).1
  simp at h1
  omega

/-- in a nonempty fibre every identity choice of the moves meets every condition. -/
theorem ident_all (σ cl : Nat → Nat) (a : Asg) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true)
    (hF : Fb σ cl a = true) (c : Vec) (hK : ker (Mrows σ cl) c = true) :
    sat (Sys σ cl) c = true := by
  have J := jfacts σ cl a hσ hb hF
  have hj1 := J.j1
  have hj31 := J.j31
  have hKk : ∀ k, 1 ≤ k → k ≤ 31 → ∀ i, i < 3 →
      ((bit3 (st (σ k)) i && ob c k) ^^
        (((σ k != 0) && c.getD (31 + 3 * (σ k - 1) + i) false) ^^ (inJ cl k && wb c))) = false := by
    intro k h1 h31 i hi
    have h : dot (ofIdx (idx σ cl k 0)) c = false ∧ dot (ofIdx (idx σ cl k 1)) c = false ∧
        dot (ofIdx (idx σ cl k 2)) c = false :=
      ker_rows3 c (fun k i => ofIdx (idx σ cl k i)) slots hK k ((mem_slots k).mpr ⟨h1, h31⟩)
    rw [dot_ofIdx, dot_ofIdx, dot_ofIdx] at h
    rw [← xs_idx σ cl c k i (by omega)]
    have hi3 : i = 0 ∨ i = 1 ∨ i = 2 := by omega
    rcases hi3 with e | e | e <;> subst e
    · exact h.1
    · exact h.2.1
    · exact h.2.2
  have hx : ∀ k, k ≤ 31 → ∀ i, i < 3 → xs c (idx σ cl k i) = false := by
    intro k hk i hi
    by_cases h0 : k = 0
    · subst h0; rfl
    · rw [xs_idx σ cl c k i h0]; exact hKk k (by omega) hk i hi
  -- w = 0
  have hw : wb c = false := by
    have hs0 : σ (jOf cl) ≠ 0 := by
      intro e
      have hw := J.wt
      rw [e] at hw
      revert hw
      show ¬ (pc3 0 = 1 ∨ pc3 0 = 2)
      decide
    have hs8 := hσ (jOf cl)
    obtain ⟨k, k1, k31, hsk, n1, n2⟩ :=
      free_slot σ cl a hσ hF (jOf cl) (σ (jOf cl)) (by omega) (by omega)
    have hin : inJ cl k = false := by
      unfold inJ
      simp [n1, n2]
    have hinj : inJ cl (jOf cl) = true := by unfold inJ; simp
    have A0 := hKk k k1 k31 0 (by omega)
    have A1 := hKk k k1 k31 1 (by omega)
    have A2 := hKk k k1 k31 2 (by omega)
    have B0 := hKk (jOf cl) hj1 (by omega) 0 (by omega)
    have B1 := hKk (jOf cl) hj1 (by omega) 1 (by omega)
    have B2 := hKk (jOf cl) hj1 (by omega) 2 (by omega)
    rw [hsk, hin] at A0 A1 A2
    rw [hinj] at B0 B1 B2
    exact kerW2 (σ (jOf cl)) hs8 J.wt (ob c (jOf cl)) (ob c k) _ _ _ (wb c) A0 A1 A2 B0 B1 B2
  have hw' : c.getD 52 false = false := hw
  -- the flips
  have ho : ∀ k, 1 ≤ k → k ≤ 31 → ob c k = gs c (σ k) := by
    intro k k1 k31
    have K0 := hKk k k1 k31 0 (by omega)
    have K1 := hKk k k1 k31 1 (by omega)
    have K2 := hKk k k1 k31 2 (by omega)
    rw [hw] at K0 K1 K2
    exact kerOv (σ k) (hσ k) (ob c k) _ _ _ (inJ cl k) K0 K1 K2
  have ho1 : ∀ k, 1 ≤ k → k ≤ 31 → c.getD (k - 1) false = gs c (σ k) := ho
  have ho2 : ∀ k, k ≤ 30 → c.getD k false = gs c (σ (k + 1)) := by
    intro k hk
    have h := ho (k + 1) (by omega) (by omega)
    have e : ob c (k + 1) = c.getD k false := by
      show c.getD (k + 1 - 1) false = c.getD k false
      rw [Nat.add_sub_cancel]
    rw [← e]; exact h
  unfold Sys
  apply sat_sysUpTo_intro
  intro k hk
  have hd : ∀ i, i < 3 → xs c (dl σ cl k i) = false := by
    intro i hi
    unfold dl
    rw [xs_append, hx k (by omega) i hi, hx (k + 1) (by omega) i hi]
    rfl
  unfold rowsAt
  by_cases hA : (pk σ k = 1 ∧ cl k = 1 ∨ pk σ k = 2 ∧ (cl k = 2 ∨ cl k = 4))
  · rw [if_pos hA]
    apply sat_map_intro
    intro i hi
    rw [rowsat_rw0, hd i (crd_lt _ i hi)]
    rfl
  · rw [if_neg hA]
    by_cases hB : pk σ k = 1 ∧ cl k = 3
    · rw [if_pos hB, sat_one, rowsat_rw0, xs_append, xs_append, xs_ifl, xs_ifl, xs_ifl,
        hd 0 (by omega), hd 1 (by omega), hd 2 (by omega)]
      simp
    · rw [if_neg hB]
      by_cases hD : pk σ k = 0 ∧ (cl k = 2 ∨ cl k = 4 ∨ cl k = 6)
      · rw [if_pos hD]
        have hpk : sg σ k = σ (k + 1) :=
          pc3_zero (sg σ k) (sg_lt σ hσ k) (σ (k + 1)) (hσ (k + 1)) hD.1
        split
        · rw [sat_one, rowsat_rw0]
          by_cases h0 : k = 0
          · subst h0
            rw [if_pos rfl]
            have e : σ 1 = 0 := hpk.symm
            have h1 := ho2 0 (by omega)
            rw [e] at h1
            show (!(c.getD 0 false ^^ false)) = true
            rw [h1]
            rfl
          · rw [if_neg h0]
            rw [sg_pos σ k h0] at hpk
            show (!(c.getD (k - 1) false ^^ (c.getD k false ^^ false))) = true
            rw [ho1 k (by omega) (by omega), ho2 k (by omega), ← hpk]
            cases gs c (σ k) <;> rfl
        · split
          · rw [sat_one, rowsat_rw0]
            show (!(c.getD (k - 1) false ^^ (c.getD k false ^^ (c.getD 52 false ^^ false))))
              = true
            rw [hw']
            by_cases h0 : k = 0
            · subst h0
              show (!(c.getD 0 false ^^ (c.getD 0 false ^^ (false ^^ false)))) = true
              cases c.getD 0 false <;> rfl
            · rw [sg_pos σ k h0] at hpk
              rw [ho1 k (by omega) (by omega), ho2 k (by omega), ← hpk]
              cases gs c (σ k) <;> rfl
          · rw [sat_one, rowsat_rw0]
            show (!(c.getD 52 false ^^ false)) = true
            rw [hw']
            rfl
      · rw [if_neg hD]
        rfl

/-! ## §5  the statements -/

/-- **The identity choices, exactly.** In a nonempty fibre (a is a walk of it) the 53-bit
    moves have exactly 2^7 identity choices, and every identity choice meets the conditions. -/
theorem ident_exact (σ cl : Nat → Nat) (a : Asg) (hσ : ∀ k, σ k < 8)
    (hb : budgetOK cl = true) (hF : Fb σ cl a = true) :
    cntP 53 (sat (rowsOf (Mrows σ cl))) = 2 ^ 7 ∧
    ∀ c, c ∈ vecs 53 → ker (Mrows σ cl) c = true → sat (Sys σ cl) c = true :=
  ⟨ident_count σ cl a hσ hb hF, fun c _ hK => ident_all σ cl a hσ hb hF c hK⟩

/-- so the identity choices among the moves that meet the conditions are also exactly 2^7. -/
theorem ident_exact_cond (σ cl : Nat → Nat) (a : Asg) (hσ : ∀ k, σ k < 8)
    (hb : budgetOK cl = true) (hF : Fb σ cl a = true) :
    cntP 53 (fun c => sat (Sys σ cl) c && ker (Mrows σ cl) c) = 2 ^ 7 := by
  rw [← ident_count σ cl a hσ hb hF]
  apply cntP_congr
  intro c _
  rw [sat_rowsOf]
  cases hk : ker (Mrows σ cl) c with
  | false => exact Bool.and_false _
  | true => rw [ident_all σ cl a hσ hb hF c hk]; rfl

theorem rank_nil : ∀ n : Nat, rank n [] = 0
  | 0 => rfl
  | n+1 => by rw [rank_succ_none n [] rfl]; exact rank_nil n

/-- **Exactly 2^46 moves.** In a nonempty fibre the 2^53 parameter choices give exactly 2^46
    distinct translations. -/
theorem moves_exact (σ cl : Nat → Nat) (a : Asg) (hσ : ∀ k, σ k < 8)
    (hb : budgetOK cl = true) (hF : Fb σ cl a = true) :
    cntP 93 (img (Mrows σ cl) 53 []) = 2 ^ 46 := by
  have hn : Hom ([] : List Row) := fun r hr => by cases hr
  have h := img_count (Mrows σ cl) 53 [] hn
  have hk : (fun c => sat [] c && ker (Mrows σ cl) c) = sat (rowsOf (Mrows σ cl)) :=
    funext fun c => by
      show (true && ker (Mrows σ cl) c) = sat (rowsOf (Mrows σ cl)) c
      rw [sat_rowsOf, Bool.true_and]
  rw [hk, ident_count σ cl a hσ hb hF, hom_count 53 [] hn, rank_nil, Mrows_length] at h
  have e : (2 : Nat) ^ (53 - 0) = 2 ^ 46 * 2 ^ 7 := by rw [← Nat.pow_add]
  exact Nat.eq_of_mul_eq_mul_right (Nat.two_pow_pos _) (h.symm.trans e)

/-- **The family of a nonempty fibre has exactly 2^(46 - r) members**, r the rank of the
    conditions: the moves that meet them are 2^(53 - r) parameter choices, 2^7 to each
    translation. -/
theorem family_exact (σ cl : Nat → Nat) (a : Asg) (hσ : ∀ k, σ k < 8)
    (hb : budgetOK cl = true) (hF : Fb σ cl a = true) :
    cntP 93 (img (Mrows σ cl) 53 (Sys σ cl)) * 2 ^ 7 = 2 ^ (53 - rank 53 (Sys σ cl)) := by
  have h := img_count (Mrows σ cl) 53 (Sys σ cl) (hom_Sys σ cl)
  rw [ident_exact_cond σ cl a hσ hb hF, hom_count 53 _ (hom_Sys σ cl), Mrows_length] at h
  exact h.symm

/-! ## §6  controls -/

/-- the statements on King Wen's fibre. -/
theorem kw_ident_exact : cntP 53 (sat (rowsOf (Mrows kσ kc))) = 2 ^ 7 ∧
    ∀ c, c ∈ vecs 53 → ker (Mrows kσ kc) c = true → sat (Sys kσ kc) c = true :=
  ident_exact kσ kc ka kσ_lt kw_budget kw_Fb

theorem kw_moves_exact : cntP 93 (img (Mrows kσ kc) 53 []) = 2 ^ 46 :=
  moves_exact kσ kc ka kσ_lt kw_budget kw_Fb

/-- the general theorem and the kernel's own elimination agree on King Wen's fibre
    (`kw_rank_M`: rank 46 of 53, by `decide`). -/
theorem kw_ident_agree : 2 ^ (53 - rank 53 (rowsOf (Mrows kσ kc))) = 2 ^ 7 := by
  rw [kw_rank_M]

/-- a skeleton with support 7 absent (the skeleton of the recorded fibre `r2_sample_01` with
    support 7 replaced by 6) and that fibre's class sequence, which has King Wen's budget. -/
def xσ : Nat → Nat := fun k =>
  [0, 5, 2, 0, 0, 6, 6, 4, 1, 1, 6, 6, 4, 3, 1, 5, 2, 5, 3, 5, 6, 6, 3, 4, 3, 1, 2, 2, 4, 6, 0, 6].getD k 0
def xc : Nat → Nat := fun k =>
  [2, 3, 3, 2, 2, 3, 2, 4, 4, 3, 1, 4, 3, 3, 1, 3, 3, 4, 2, 4, 6, 4, 3, 3, 3, 2, 2, 4, 2, 3, 3].getD k 0

theorem xσ_lt : ∀ k, xσ k < 8 := by
  intro k
  by_cases h : k < 32
  · have h32 : ∀ k, k < 32 → xσ k < 8 := by decide +kernel
    exact h32 k h
  · unfold xσ
    rw [getD_ge _ k (by show 32 ≤ k; omega)]; decide

theorem x_budget : budgetOK xc = true := by decide +kernel
theorem x_rank : rank 53 (rowsOf (Mrows xσ xc)) = 44 := by decide +kernel

/-- must fail: without a walk of the fibre "exactly 2^7 identity choices" is false. Here the
    other two hypotheses of `ident_exact` hold (`xσ_lt`, `x_budget`) and the moves have 2^9
    identity choices. -/
theorem ident_needs_walk : cntP 53 (sat (rowsOf (Mrows xσ xc))) = 2 ^ 9 ∧
    ¬ (cntP 53 (sat (rowsOf (Mrows xσ xc))) = 2 ^ 7) := by
  have h : cntP 53 (sat (rowsOf (Mrows xσ xc))) = 2 ^ 9 := by
    rw [hom_count 53 _ (hom_rowsOf _), x_rank]
  exact ⟨h, by rw [h]; decide⟩

/-- a skeleton whose two class-6 slots (20 and 21) and the slot after them have support 7, of
    weight 3 (in a nonempty fibre the class-6 slots have a support of weight 1 or 2, `jfacts`). -/
def yσ : Nat → Nat := fun k =>
  [0, 5, 2, 0, 0, 6, 6, 4, 1, 1, 6, 6, 4, 3, 1, 5, 2, 5, 3, 5, 7, 7, 7, 4, 3, 1, 2, 2, 4, 6, 0, 6].getD k 0

theorem yσ_lt : ∀ k, yσ k < 8 := by
  intro k
  by_cases h : k < 32
  · have h32 : ∀ k, k < 32 → yσ k < 8 := by decide +kernel
    exact h32 k h
  · unfold yσ
    rw [getD_ge _ k (by show 32 ≤ k; omega)]; decide

/-- must fail: without a walk of the fibre "every identity choice meets the conditions" is
    false. Here the other two hypotheses hold (`yσ_lt`, `x_budget`); the move "flip slots 20
    and 21 and apply the complement move" is an identity choice and violates a condition. -/
theorem ident_all_needs_walk :
    (List.range 53).map (fun i => i == 19 || i == 20 || i == 52) ∈ vecs 53 ∧
    ker (Mrows yσ xc) ((List.range 53).map (fun i => i == 19 || i == 20 || i == 52)) = true ∧
    sat (Sys yσ xc) ((List.range 53).map (fun i => i == 19 || i == 20 || i == 52)) = false :=
  ⟨(mem_vecs 53 _).mpr (by decide +kernel), by decide +kernel, by decide +kernel⟩

/-! ## §7  a piece of a fibre that the fibre's own moves keep

    (From the second read of this development.) The orbit count applies to any part of a
    fibre that the moves meeting the conditions map to itself, with the same exponent 26 - t.
    It gives no more than 26 - t, and it says nothing about a part that those moves do not
    keep. -/

theorem piece_dvd (σ cl : Nat → Nat) (hσ : ∀ k, σ k < 8) (hb : budgetOK cl = true)
    (O : Vec → Bool)
    (hO : ∀ c, c ∈ vecs 53 → sat (Sys σ cl) c = true → ∀ x, x ∈ vecs 93 →
      O (vadd x (mulM (Mrows σ cl) c)) = O x) :
    2 ^ (26 - tcount σ cl) ∣ cntP 93 (fun x => Yb σ cl x && O x) := by
  cases Classical.em (∃ x, x ∈ vecs 93 ∧ Yb σ cl x = true) with
  | inl hne =>
    obtain ⟨x, _, hY⟩ := hne
    have hK := ident_bound σ cl (wr slots x (fun _ => 0)) hσ hb hY
    have hinv : ∀ c, c ∈ vecs 53 → sat (Sys σ cl) c = true → ∀ x, x ∈ vecs (Mrows σ cl).length →
        (fun x => Yb σ cl x && O x) (vadd x (mulM (Mrows σ cl) c)) =
          (fun x => Yb σ cl x && O x) x := by
      intro c hc hs x hx
      show (Yb σ cl (vadd x (mulM (Mrows σ cl) c)) && O (vadd x (mulM (Mrows σ cl) c))) =
        (Yb σ cl x && O x)
      rw [gplus_inv σ cl hσ hb c hc hs x hx,
        hO c hc hs x (by rw [Mrows_length] at hx; exact hx)]
    have h := gplus_shape (Mrows σ cl) (Sys σ cl) (fun x => Yb σ cl x && O x) (tcount σ cl)
      (hom_Sys σ cl) (Sys_length σ cl hσ hb) hinv hK
    rw [Mrows_length] at h
    exact h
  | inr hne =>
    have h0 : cntP 93 (fun x => Yb σ cl x && O x) = 0 := by
      have e : cntP 93 (fun x => Yb σ cl x && O x) = cntP 93 (fun _ => false) :=
        cntP_congr _ _ _ (fun x hx => by
          cases h : Yb σ cl x with
          | false => rfl
          | true => exact absurd ⟨x, hx, h⟩ hne)
      rw [e]
      exact filter_len_any_false _ _ (any_false _)
    rw [h0]
    exact Nat.dvd_zero _

end GPExactOpts
end Q1150

-- §46  Axiom reports for every theorem of Part 2 (each must be a subset of
-- [propext, Classical.choice, Quot.sound]).
#print axioms F2Count.dot_nil
#print axioms F2Count.dot_cons
#print axioms F2Count.mem_vecs
#print axioms F2Count.vecs_length
#print axioms F2Count.nodup_map_cons
#print axioms F2Count.vecs_nodup
#print axioms F2Count.cntP_succ
#print axioms F2Count.cntP_congr
#print axioms F2Count.filter_split
#print axioms F2Count.cntP_split
#print axioms F2Count.sat_cons
#print axioms F2Count.sat_map
#print axioms F2Count.dot_vxor
#print axioms F2Count.headD_vxor
#print axioms F2Count.hd_red
#print axioms F2Count.rowsat_red
#print axioms F2Count.rowsat_tl
#print axioms F2Count.split_none
#print axioms F2Count.split_some
#print axioms F2Count.rank_succ_none
#print axioms F2Count.rank_succ_some
#print axioms F2Count.cons_succ_none
#print axioms F2Count.cons_succ_some
#print axioms F2Count.rank_le_n
#print axioms F2Count.rank_le_rows
#print axioms F2Count.cnt_zero
#print axioms F2Count.cnt_none
#print axioms F2Count.sat_pivot
#print axioms F2Count.cnt_pivot
#print axioms F2Count.count_eq
#print axioms F2Count.red_snd
#print axioms F2Count.cons_hom
#print axioms F2Count.red_z
#print axioms F2Count.split_z
#print axioms F2Count.rank_z
#print axioms F2Count.hom_z
#print axioms F2Count.hom_count
#print axioms F2Count.affine_count
#print axioms F2Count.hom_dvd
#print axioms F2Count.dot_vadd
#print axioms F2Count.cntP_vadd
#print axioms F2Count.sat_vadd
#print axioms F2Count.mem_vecs_cons
#print axioms F2Count.orbit_dvd
#print axioms F2Count.sat_append
#print axioms F2Count.sat_rowsOf
#print axioms F2Count.hom_append
#print axioms F2Count.hom_rowsOf
#print axioms F2Count.family_dvd
#print axioms F2Count.gplus_shape
#print axioms F2Count.gplus_shape_13
#print axioms F2Count.vadd_length
#print axioms F2Count.vadd_vadd
#print axioms F2Count.mulM_length
#print axioms F2Count.mulM_vadd
#print axioms F2Count.inv_of_imp
#print axioms F2Count.half_sols
#print axioms F2Count.all_sols
#print axioms F2Count.hom_add_row
#print axioms F2Count.hom_add_rows_le
#print axioms F2Count.cntP_le_one
#print axioms F2Count.ker_bound
#print axioms F2Count.dot_unit
#print axioms F2Count.any_congr_mem
#print axioms F2Count.any_false
#print axioms F2Count.filter_len_any_false
#print axioms F2Count.img_inv
#print axioms F2Count.img_count
#print axioms F2Count.family_size
#print axioms F2Count.ctl_one_row
#print axioms F2Count.ctl_dep_rank
#print axioms F2Count.ctl_dep_count
#print axioms F2Count.ctl_rows_is_not_rank
#print axioms F2Count.ctl_bad_cons
#print axioms F2Count.ctl_bad_count
#print axioms F2Count.ctl_bad_rank
#print axioms F2Count.ctl_bad_z
#print axioms F2Count.ctl_cons_needed
#print axioms F2Count.ctl_aff_count
#print axioms F2Count.ctl_aff_cons
#print axioms F2Count.ctl_S10_rank
#print axioms F2Count.ctl_S10_brute
#print axioms F2Count.ctl_S10_thm
#print axioms F2Count.ctl_vecs10
#print axioms F2Count.ctl_all
#print axioms F2Count.ctl_inv
#print axioms F2Count.ctl_family
#print axioms F2Count.ctl_family_exact
#print axioms F2Count.ctl_img
#print axioms F2Count.ctl_one_not_inv
#print axioms F2Count.ctl_one_not_dvd
#print axioms F2Count.ctl_kernel_needed
#print axioms F2Count.ctl_kernel_count
#print axioms F2Count.ctl_kernel_img
#print axioms F2Count.ctl_kernel_thm
#print axioms F2Count.ctl_cond_inv
#print axioms F2Count.ctl_cond_not_inv_without
#print axioms F2Count.ctl_cond_family
#print axioms F2Count.ctl_cond_img
#print axioms F2Count.ctl_ker_bound
#print axioms F2Count.ctl_M46_rank
#print axioms F2Count.ctl_gplus_nonvacuous
#print axioms Q1150.cntP3
#print axioms Q1150.bridge
#print axioms Q1150.xor_lt8
#print axioms Q1150.st_lt
#print axioms Q1150.f3
#print axioms Q1150.f3c
#print axioms Q1150.xr
#print axioms Q1150.loc_cross
#print axioms Q1150.loc_c3
#print axioms Q1150.loc_third_a
#print axioms Q1150.loc_third_b
#print axioms Q1150.loc_third_needs_hyp
#print axioms Q1150.f3_needs_hyp
#print axioms Q1150.loc_c6
#print axioms Q1150.loc_c6_wt
#print axioms Q1150.loc_d1
#print axioms Q1150.loc_d2a
#print axioms Q1150.loc_d2b
#print axioms Q1150.sp_symm
#print axioms Q1150.pc3_zero
#print axioms Q1150.m_zero
#print axioms Q1150.feas
#print axioms Q1150.Mf_lt
#print axioms Q1150.same_delta
#print axioms Q1150.third_delta
#print axioms Q1150.third_delta_needs_hyp
#print axioms Q1150.dot_ofIdx
#print axioms Q1150.xs_append
#print axioms Q1150.xs_if
#print axioms Q1150.xs_ifl
#print axioms Q1150.rowsat_rw0
#print axioms Q1150.sat_map_rw0
#print axioms Q1150.rows3_length
#print axioms Q1150.wr_rows
#print axioms Q1150.ker_rows3
#print axioms Q1150.val3_xor
#print axioms Q1150.val3_lt
#print axioms Q1150.len3
#print axioms Q1150.wr_vadd
#print axioms Q1150.wr_lt
#print axioms Q1150.xs_idx
#print axioms Q1150.mv_form
#print axioms Q1150.mvv_zero
#print axioms Q1150.mvv_lt
#print axioms Q1150.mvv_eq
#print axioms Q1150.wr_move
#print axioms Q1150.Mrows_length
#print axioms Q1150.sysUpTo_length
#print axioms Q1150.sat_sysUpTo
#print axioms Q1150.hom_sysUpTo
#print axioms Q1150.hom_rowsAt
#print axioms Q1150.hom_Sys
#print axioms Q1150.crd_len
#print axioms Q1150.rowsAt_len
#print axioms Q1150.sumN_wt
#print axioms Q1150.Sys_length
#print axioms Q1150.W_eq
#print axioms Q1150.entry_tt
#print axioms Q1150.tt_lt
#print axioms Q1150.sg_succ
#print axioms Q1150.sg_pos
#print axioms Q1150.cls_tt
#print axioms Q1150.tt_tr
#print axioms Q1150.Fb_cls
#print axioms Q1150.Fb_dist
#print axioms Q1150.Fb_intro
#print axioms Q1150.dist_any
#print axioms Q1150.jfacts
#print axioms Q1150.inJ_zero
#print axioms Q1150.inJ_true
#print axioms Q1150.inJ_false
#print axioms Q1150.third_facts
#print axioms Q1150.vv_lt
#print axioms Q1150.dd_eq
#print axioms Q1150.mask0
#print axioms Q1150.mask3
#print axioms Q1150.sat_single
#print axioms Q1150.dform
#print axioms Q1150.inv_cls
#print axioms Q1150.inv_dist
#print axioms Q1150.inv_fibre
#print axioms Q1150.filter_len_mono
#print axioms Q1150.cntP_mono
#print axioms Q1150.replicate_of_bits
#print axioms Q1150.Fb_W
#print axioms Q1150.four_slots
#print axioms Q1150.free_slot
#print axioms Q1150.low_cases
#print axioms Q1150.kerV
#print axioms Q1150.kerW
#print axioms Q1150.kerO
#print axioms Q1150.hom_Trows
#print axioms Q1150.ker_zero
#print axioms Q1150.ident_bound
#print axioms Q1150.fibre_eq
#print axioms Q1150.wr_vadd0
#print axioms Q1150.gplus_inv
#print axioms Q1150.gplus_fibre
#print axioms Q1150.tcount_le
#print axioms Q1150.gplus_fibre_13
#print axioms Q1150.vadd_fix
#print axioms Q1150.gplus_family
#print axioms Q1150.Gs_dvd13
#print axioms Q1150.cellV2_dvd_families
#print axioms Q1150.superCount_dvd_families
#print axioms Q1150.BindC_congr
#print axioms Q1150.super_charC
#print axioms Q1150.point_eqC
#print axioms Q1150.cell_eqC
#print axioms Q1150.GsC_pm
#print axioms Q1150.GsC_zero_bad
#print axioms Q1150.cell_sixC
#print axioms Q1150.GsC_dvd13
#print axioms Q1150.censusC_dvd_families
#print axioms Q1150.censusC_dvd
#print axioms Q1150.kw_census_pos
#print axioms Q1150.getD_ge
#print axioms Q1150.kσ_lt
#print axioms Q1150.kw_Fb
#print axioms Q1150.kw_j
#print axioms Q1150.kw_tcount
#print axioms Q1150.kw_rows
#print axioms Q1150.kw_rank
#print axioms Q1150.kw_rank_M
#print axioms Q1150.kw_rank_all
#print axioms Q1150.kw_img
#print axioms Q1150.kw_moves_ok
#print axioms Q1150.kw_moves_bad
#print axioms Q1150.kw_move_pair
#print axioms Q1150.kx_mem
#print axioms Q1150.kw_Yb
#print axioms Q1150.kw_fibre_pos
#print axioms Q1150.kw_gplus
#print axioms Q1150.kw_family
#print axioms Q1150.kw_shell_exponent
#print axioms Q1150.kw_Fb_mut
#print axioms Q1150.climb_budget
#print axioms Q1150.climb_tcount
#print axioms Q1150.climb_rows
#print axioms Q1150.climb_rank
#print axioms Q1150.climb_rank_all
#print axioms Q1150.climb_img
#print axioms Q1150.r2b_budget
#print axioms Q1150.r2b_tcount
#print axioms Q1150.r2b_rows
#print axioms Q1150.r2b_rank
#print axioms Q1150.r2b_rank_all
#print axioms Q1150.Wit_cons
#print axioms Q1150.hom_add_rows_eq
#print axioms Q1150.getD_map_range
#print axioms Q1150.ev_len
#print axioms Q1150.ev_ob
#print axioms Q1150.ev_shift
#print axioms Q1150.ev_wb
#print axioms Q1150.ker_rows3_intro
#print axioms Q1150.ev_slot
#print axioms Q1150.ev_ker
#print axioms Q1150.low_lt
#print axioms Q1150.st_low
#print axioms Q1150.sat_map_intro
#print axioms Q1150.wit_T
#print axioms Q1150.ident_count
#print axioms Q1150.kerOv
#print axioms Q1150.kerW2
#print axioms Q1150.sat_one
#print axioms Q1150.sat_sysUpTo_intro
#print axioms Q1150.crd_lt
#print axioms Q1150.ident_all
#print axioms Q1150.ident_exact
#print axioms Q1150.ident_exact_cond
#print axioms Q1150.rank_nil
#print axioms Q1150.moves_exact
#print axioms Q1150.family_exact
#print axioms Q1150.kw_ident_exact
#print axioms Q1150.kw_moves_exact
#print axioms Q1150.kw_ident_agree
#print axioms Q1150.xσ_lt
#print axioms Q1150.x_budget
#print axioms Q1150.x_rank
#print axioms Q1150.ident_needs_walk
#print axioms Q1150.yσ_lt
#print axioms Q1150.ident_all_needs_walk
#print axioms Q1150.piece_dvd
