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

  Checked here (native_decide; extended trust base per lean/README.md — the
  repo style for finite facts):

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

/- ------------------ §2 SC1: psi is an involution and a G5 ≅ Q6 isomorphism ------------------ -/

theorem psi_involution : hexes.all (fun x => psi (psi x) == x) = true := by native_decide

theorem psi_g5_iso :
    (hexes.all fun x => hexes.all fun y =>
      ((ham x y == 5) == (ham (psi x) (psi y) == 1))) = true := by native_decide

/- ------------------ §3 SC2: psi commutes with all 720 bit-position permutations ------------------ -/

theorem psi_comm_perms :
    ((perms idp).all fun p => hexes.all fun h =>
      psi (applyPerm p h) == applyPerm p (psi h)) = true := by native_decide

/- ------------------ §4 SC3: the two-common-neighbor lemma on Q6 ------------------ -/

theorem q6_two_common_neighbors :
    (hexes.all fun y => hexes.all fun z =>
      (y == z) || (ham y z != 2) ||
      ((hexes.filter fun a => ham a y == 1 && ham a z == 1).length == 2)) = true := by
  native_decide

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
      ((List.range 64).map fun v => v, true) := by native_decide

/- ------------------ §6 SC7: partner-commuters = G48, exactly 48 ------------------ -/

/-- the bit-position permutations commuting with the canonical partner involution. -/
def partnerCommuters : List (List Nat) :=
  (perms idp).filter fun p =>
    hexes.all fun h => applyPerm p (partner h) == partner (applyPerm p h)

theorem partnerCommuters_eq_G48 : partnerCommuters = G48 := by native_decide

theorem partnerCommuters_card : partnerCommuters.length = 48 := by native_decide

end SymmetryCompleteness

/-! ### Axiom audit (added 2026-08-01)
Emits the trust base for every theorem in this file that is CITED BY NAME in the
public documentation, so the suite's `#print axioms` claims are OBSERVED rather than
statically inferred. Expected: `[propext, Classical.choice, Quot.sound]`, or
`[propext]` alone for the finite facts. Any `Lean.ofReduceBool` here means a
`native_decide` (compiler trust) is load-bearing and the docs must say so. -/
#print axioms SymmetryCompleteness.psi_involution
#print axioms SymmetryCompleteness.psi_g5_iso
#print axioms SymmetryCompleteness.psi_comm_perms
#print axioms SymmetryCompleteness.q6_two_common_neighbors
#print axioms SymmetryCompleteness.rigidity_forced_identity
#print axioms SymmetryCompleteness.partnerCommuters_eq_G48
