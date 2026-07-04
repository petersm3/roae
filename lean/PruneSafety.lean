/-
  PruneSafety.lean — machine-checked v4 walk-level prune-safety lemma (2026-07-04).
  Core Lean 4 only (no mathlib). Formalizes V4_PRUNE_SAFETY_LEMMA.md in full
  generality: lists over any type α with a strict comparison relation r (instantiate
  r := (· < ·) for the linearly ordered / lex case), a set G of functions acting
  POINTWISE via List.map, and canonical = "no g ∈ G maps the list strictly
  lex-below itself" (the orbit lex-minimum condition).

  Main results:
  · `map_lex_extend`  — if (P.map g) <lex P then (X.map g) <lex X for every
    extension X of the prefix P (the pointwise action fixes the descent slot).
  · `not_canonical_of_pruned_prefix` — soundness: no completion of a pruned
    prefix is canonical.
  · `prefix_of_canonical_not_pruned` — completeness: a depth-first walk pruning
    on this test still visits every canonical element (no prefix of a canonical
    element is ever pruned).
  · `exists_smaller_solution` — the Ω-invariant form: if the solution set Ω is
    closed under the action, the lex-smaller witness g·X is itself a solution,
    so X is not the lex-least member of its orbit within Ω.

  Attribution: this is the correctness core of the standard isomorph-free
  exhaustive generation technique (B. D. McKay, "Isomorph-free exhaustive
  generation", J. Algorithms 26 (1998) 306–324); not claimed as novel — only
  this particular machine-checked formalization is ours (to our knowledge;
  corrections welcome). Mathematical statement and pen-and-paper proof:
  roae-private/V4_PRUNE_SAFETY_LEMMA.md.
-/

namespace PruneSafety

universe u
variable {α : Type u} (r : α → α → Prop)

/-- A strict lex descent between equal-length lists survives appending arbitrary
    tails: the first-difference slot lies inside the common length, so the tails
    are never consulted. (Equal length rules out the `List.Lex.nil` case, which
    is the only way a lex comparison can be decided past the end of a list.) -/
theorem lex_append {l₁ l₂ : List α} (h : List.Lex r l₁ l₂) :
    l₁.length = l₂.length →
    ∀ t₁ t₂ : List α, List.Lex r (l₁ ++ t₁) (l₂ ++ t₂) := by
  induction h with
  | nil =>
      intro hlen
      simp at hlen
  | rel hab =>
      intro _ t₁ t₂
      exact List.Lex.rel hab
  | cons _ ih =>
      intro hlen t₁ t₂
      exact List.Lex.cons
        (ih (by simp only [List.length_cons] at hlen; omega) t₁ t₂)

/-- Key lemma: the action is pointwise (`List.map g`), so a strict lex descent
    already visible on a prefix P propagates to every list X extending P.
    This is the "g·X agrees with g·P on the filled slots" step of the proof. -/
theorem map_lex_extend (g : α → α) {P X : List α}
    (hpre : P <+: X) (h : List.Lex r (P.map g) P) :
    List.Lex r (X.map g) X := by
  obtain ⟨T, rfl⟩ := hpre
  rw [List.map_append]
  exact lex_append r h (by simp) (T.map g) T

variable (G : (α → α) → Prop)

/-- v4-canonical: X is the lex-minimum of its G-orbit — no g ∈ G maps X
    strictly lex-below itself. -/
def Canonical (X : List α) : Prop :=
  ∀ g, G g → ¬ List.Lex r (X.map g) X

/-- The walk-level prune test: some g ∈ G maps the prefix strictly lex-below
    itself (comparing only the filled slots). -/
def Pruned (P : List α) : Prop :=
  ∃ g, G g ∧ List.Lex r (P.map g) P

/-- MAIN THEOREM (prune soundness): no completion X of a pruned prefix P is
    canonical — pruning the subtree below P loses no canonical element. -/
theorem not_canonical_of_pruned_prefix {P X : List α}
    (hpre : P <+: X) (hP : Pruned r G P) : ¬ Canonical r G X := by
  obtain ⟨g, hg, hlex⟩ := hP
  intro hcan
  exact hcan g hg (map_lex_extend r g hpre hlex)

/-- COROLLARY (completeness): prefixes of canonical elements are never pruned,
    so a depth-first walk with this prune reaches every canonical element. -/
theorem prefix_of_canonical_not_pruned {P X : List α}
    (hcan : Canonical r G X) (hpre : P <+: X) : ¬ Pruned r G P :=
  fun hP => not_canonical_of_pruned_prefix r G hpre hP hcan

/-- Ω-invariant form: if the solution set Ω is closed under the action, then a
    completion X ∈ Ω of a pruned prefix has a solution g·X ∈ Ω strictly
    lex-below it — X is not the lex-least member of its orbit within Ω. -/
theorem exists_smaller_solution (Ω : List α → Prop)
    (hΩ : ∀ g, G g → ∀ X, Ω X → Ω (X.map g))
    {P X : List α} (hX : Ω X) (hpre : P <+: X)
    {g : α → α} (hg : G g) (hlex : List.Lex r (P.map g) P) :
    ∃ Y, Ω Y ∧ Y = X.map g ∧ List.Lex r Y X :=
  ⟨X.map g, hΩ g hg X hX, rfl, map_lex_extend r g hpre hlex⟩

/-! ### Sanity checks (linear-order instantiation r := (· < ·) on Nat) -/

/-- A concrete pruned prefix: g = (2 - ·) maps [2, 0] to [0, 2] <lex [2, 0]. -/
example : List.Lex (· < ·) (List.map (2 - ·) [2, 0]) [2, 0] :=
  List.Lex.rel (by decide)

/-- ...and the descent indeed propagates to an extension of that prefix. -/
example : List.Lex (· < ·) (List.map (2 - ·) [2, 0, 1, 7]) [2, 0, 1, 7] :=
  map_lex_extend (· < ·) (2 - ·) (P := [2, 0]) (X := [2, 0, 1, 7])
    ⟨[1, 7], rfl⟩ (List.Lex.rel (by decide))

end PruneSafety
