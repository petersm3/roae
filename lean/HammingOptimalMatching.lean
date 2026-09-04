-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  HammingOptimalMatching.lean — the C1 pairing is the unique Hamming-cost-minimizing
  comp/rev matching on {0,1}⁶ (2026-07-26).

  RESULT CREDIT: this theorem is due to Radisic (2026), "Optimal Equivariant Matchings
  on the 6-Cube, With an Application to the King Wen Sequence", arXiv:2601.07175
  (documentation/CITATIONS.md#radisic2026). This file is an independent re-derivation
  in this repository's own encoding (core Lean 4, no mathlib, standalone — same
  conventions and the same `partner` definition as lean/KingWen.lean), so that the
  claim is machine-checkable in-repo without external dependencies. Radisic's original
  Lean 4 + Mathlib artifact (arXiv ancillary files) was independently rebuilt and
  audited before this adaptation was written; see lean/README.md for the verification
  record. Any error of adaptation is ours, not Radisic's; corrections invited.

  WHAT IS PROVED (scope exactly as stated — see the honesty notes at the bottom):

  * `partner_is_unique_minimum` (MAIN): for EVERY pairing m on the 64 hexagrams in
    which each element is sent to its complement or its reversal and never to itself,
    the total endpoint cost Σ_{h<64} d(h, m h) is at least 240, and any m attaining
    240 equals the C1 `partner` function at every hexagram. Since `partner` attains
    240 (`partner_cost_240`) and is an involution (`partner_involution`), the C1
    pairing is THE unique Hamming-cost-minimizing comp/rev matching. Endpoint sums
    count each pair twice: 240 = 2 × 120 pair cost (matching Radisic's 120), versus
    the complement-only matching's 384 = 2 × 192 (`comp_only_cost_384`).

  * `kw_realizes_partner`: the King Wen sequence realizes exactly this optimal
    matching — its 32 consecutive pairs all satisfy KW[2k+1] = partner(KW[2k]).

  * SCOPE GUARD `full_k4_can_do_192`: optimality is claimed among comp/rev matchings
    ONLY. Over the full Klein group (allowing comp∘rev partners) strictly cheaper
    matchings exist: an explicit involution `mCR` using comp∘rev where profitable is
    exhibited with endpoint cost 192 = 2 × 96 (Radisic's 96). This file therefore
    also machine-checks the honest boundary of the claim.

  The structural glue (arbitrary-m reasoning, sum comparison) is ordinary Lean;
  the finite hexagram-level facts are all proved by kernel `decide` — this file
  contains no `native_decide` (trust base: kernel-only; see lean/README.md's
  trust-base note).
-/

/-- popcount for 6-bit values (same definition as lean/KingWen.lean). -/
def pc6 (n : Nat) : Nat :=
  n % 2 + n / 2 % 2 + n / 4 % 2 + n / 8 % 2 + n / 16 % 2 + n / 32 % 2

/-- 6-bit reversal (same definition as lean/KingWen.lean). -/
def rev6 (n : Nat) : Nat :=
  n % 2 * 32 + n / 2 % 2 * 16 + n / 4 % 2 * 8 + n / 8 % 2 * 4 + n / 16 % 2 * 2 + n / 32 % 2

/-- 6-bit complement. -/
def comp6 (n : Nat) : Nat := n ^^^ 63

/-- Hamming distance on 6-bit values. -/
def ham (a b : Nat) : Nat := pc6 (a ^^^ b)

/-- canonical partner: reversal, or complement for palindromes
    (identical to `partner` in lean/KingWen.lean and to solve.c's partner()). -/
def partner (h : Nat) : Nat := if rev6 h = h then comp6 h else rev6 h

/-- Σ_{h<n} f h. -/
def sumTo (f : Nat → Nat) : Nat → Nat
  | 0 => 0
  | n + 1 => sumTo f n + f n

/-- A comp/rev pairing: every hexagram is sent to its complement or its reversal,
    and never to itself. (Involutivity is NOT assumed — the optimality theorem below
    is proved for this strictly larger class, and the unique optimum `partner` then
    turns out to be an involution, i.e. a genuine perfect matching.) -/
def IsCompRevPairing (m : Nat → Nat) : Prop :=
  ∀ h, h < 64 → (m h = comp6 h ∨ m h = rev6 h) ∧ m h ≠ h

/- ------------------ finite hexagram-level facts ------------------ -/

/-- partner never beats-itself bookkeeping: partner stays in range, is never the
    identity, always uses comp or rev, and is an involution. -/
theorem partner_involution :
    ∀ h, h < 64 → (partner h = comp6 h ∨ partner h = rev6 h) ∧ partner h ≠ h ∧
      partner (partner h) = h ∧ partner h < 64 := by decide

/-- partner is never costlier than complement. -/
theorem partner_le_comp : ∀ h, h < 64 → ham h (partner h) ≤ ham h (comp6 h) := by decide

/-- partner is never costlier than reversal, whenever reversal is a legal partner
    (i.e. h is not a palindrome). -/
theorem partner_le_rev : ∀ h, h < 64 → rev6 h ≠ h → ham h (partner h) ≤ ham h (rev6 h) := by
  decide

/-- STRICTNESS vs complement: whenever complement differs from partner, partner is
    strictly cheaper. (These are exactly the non-palindromic, non-antisymmetric
    hexagrams: d(h, rev h) ∈ {2,4} < 6 = d(h, comp h).) -/
theorem partner_lt_comp : ∀ h, h < 64 → comp6 h ≠ partner h →
    ham h (partner h) < ham h (comp6 h) := by decide

/-- STRICTNESS vs reversal: for non-palindromes, partner IS the reversal, so a
    reversal choice differing from partner is impossible (vacuous — kept as the
    exact case split the main proof needs). -/
theorem partner_lt_rev : ∀ h, h < 64 → rev6 h ≠ h → rev6 h ≠ partner h →
    ham h (partner h) < ham h (rev6 h) := by decide

/-- The C1 matching's total endpoint cost is 240 (= 2 × 120 over the 32 pairs:
    12 pairs at distance 2, 12 at distance 4, 8 at distance 6). -/
theorem partner_cost_240 : sumTo (fun h => ham h (partner h)) 64 = 240 := by decide

/-- The complement-only matching costs 384 endpoint (= 2 × 192). -/
theorem comp_only_cost_384 : sumTo (fun h => ham h (comp6 h)) 64 = 384 := by decide

/- ------------------ sum comparison lemmas ------------------ -/

theorem sumTo_le {f g : Nat → Nat} : ∀ n, (∀ h, h < n → f h ≤ g h) →
    sumTo f n ≤ sumTo g n
  | 0, _ => Nat.le_refl 0
  | n + 1, H => by
    have h1 := sumTo_le n (fun h hh => H h (Nat.lt_succ_of_lt hh))
    have h2 := H n (Nat.lt_succ_self n)
    exact Nat.add_le_add h1 h2

theorem sumTo_lt {f g : Nat → Nat} : ∀ n, (∀ h, h < n → f h ≤ g h) →
    ∀ k, k < n → f k < g k → sumTo f n < sumTo g n
  | 0, _, _, hk, _ => absurd hk (Nat.not_lt_zero _)
  | n + 1, H, k, hk, hs => by
    have Hn : ∀ h, h < n → f h ≤ g h := fun h hh => H h (Nat.lt_succ_of_lt hh)
    cases Nat.lt_succ_iff_lt_or_eq.mp hk with
    | inl hlt =>
      have h1 := sumTo_lt n Hn k hlt hs
      have h2 := H n (Nat.lt_succ_self n)
      exact Nat.add_lt_add_of_lt_of_le h1 h2
    | inr heq =>
      have h1 := sumTo_le n Hn
      have h2 : f n < g n := heq ▸ hs
      exact Nat.add_lt_add_of_le_of_lt h1 h2

/- ------------------ pointwise dominance ------------------ -/

/-- Pointwise: partner is never costlier than ANY legal comp/rev choice. -/
theorem partner_pointwise_min (m : Nat → Nat) (hm : IsCompRevPairing m) :
    ∀ h, h < 64 → ham h (partner h) ≤ ham h (m h) := by
  intro h hh
  rcases hm h hh with ⟨hopt, hne⟩
  cases hopt with
  | inl hc =>
    rw [hc]; exact partner_le_comp h hh
  | inr hr =>
    have hrev_ne : rev6 h ≠ h := fun hfix => hne (hr.trans hfix)
    rw [hr]; exact partner_le_rev h hh hrev_ne

/-- Pointwise strictness: any legal comp/rev choice that differs from partner is
    strictly costlier. -/
theorem partner_pointwise_forced (m : Nat → Nat) (hm : IsCompRevPairing m) :
    ∀ h, h < 64 → m h ≠ partner h → ham h (partner h) < ham h (m h) := by
  intro h hh hdiff
  rcases hm h hh with ⟨hopt, hne⟩
  cases hopt with
  | inl hc =>
    have : comp6 h ≠ partner h := fun he => hdiff (hc.trans he)
    rw [hc]; exact partner_lt_comp h hh this
  | inr hr =>
    have hrev_ne : rev6 h ≠ h := fun hfix => hne (hr.trans hfix)
    have : rev6 h ≠ partner h := fun he => hdiff (hr.trans he)
    rw [hr]; exact partner_lt_rev h hh hrev_ne this

/- ------------------ MAIN THEOREM ------------------ -/

/-- MAIN (Radisic 2026, re-derived): among ALL comp/rev pairings on the 64 hexagrams,
    the C1 `partner` function is the unique total-Hamming-cost minimizer.
    Every comp/rev pairing costs at least 240 endpoint (2 × 120), and any pairing
    attaining 240 agrees with `partner` at every hexagram. -/
theorem partner_is_unique_minimum (m : Nat → Nat) (hm : IsCompRevPairing m) :
    240 ≤ sumTo (fun h => ham h (m h)) 64 ∧
    (sumTo (fun h => ham h (m h)) 64 = 240 → ∀ h, h < 64 → m h = partner h) := by
  have hle : sumTo (fun h => ham h (partner h)) 64 ≤ sumTo (fun h => ham h (m h)) 64 :=
    sumTo_le 64 (partner_pointwise_min m hm)
  constructor
  · calc 240 = sumTo (fun h => ham h (partner h)) 64 := partner_cost_240.symm
      _ ≤ _ := hle
  · intro htot h hh
    cases Nat.decEq (m h) (partner h) with
    | isTrue heq => exact heq
    | isFalse hdiff =>
      exfalso
      have hstrict : sumTo (fun h => ham h (partner h)) 64 < sumTo (fun h => ham h (m h)) 64 :=
        sumTo_lt 64 (partner_pointwise_min m hm) h hh (partner_pointwise_forced m hm h hh hdiff)
      rw [partner_cost_240, htot] at hstrict
      exact Nat.lt_irrefl 240 hstrict

/- ------------------ King Wen realizes the optimum ------------------ -/

def KW : List Nat :=
  [63,  0, 17, 34, 23, 58,  2, 16, 55, 59,  7, 56, 61, 47,  4,  8,
   25, 38,  3, 48, 41, 37, 32,  1, 57, 39, 33, 30, 18, 45, 28, 14,
   60, 15, 40,  5, 53, 43, 20, 10, 35, 49, 31, 62, 24,  6, 26, 22,
   29, 46,  9, 36, 52, 11, 13, 44, 54, 27, 50, 19, 51, 12, 21, 42]

/-- The King Wen sequence realizes exactly the unique optimal matching: each of its
    32 consecutive pairs satisfies KW[2k+1] = partner(KW[2k]) (this is C1), and the
    within-pair distances sum to the optimal 120. -/
theorem kw_realizes_partner :
    (∀ k, k < 32 → KW.getD (2 * k + 1) 99 = partner (KW.getD (2 * k) 99)) ∧
    sumTo (fun k => ham (KW.getD (2 * k) 99) (KW.getD (2 * k + 1) 99)) 32 = 120 := by
  decide

/- ------------------ scope guard: the full-K₄ relaxation ------------------ -/

/-- comp ∘ rev. -/
def crev6 (h : Nat) : Nat := comp6 (rev6 h)

/-- An explicit full-K₄ matching: use comp∘rev where it is strictly cheaper than
    reversal (and a legal partner), otherwise fall back to the C1 rule. -/
def mCR (h : Nat) : Nat :=
  if rev6 h = h then comp6 h
  else if crev6 h ≠ h ∧ ham h (crev6 h) < ham h (rev6 h) then crev6 h
  else rev6 h

/-- SCOPE GUARD (Radisic 2026): the optimality of C1 is claimed among comp/rev
    matchings ONLY. Over the full Klein group the bound 240 fails: `mCR` is a genuine
    fixed-point-free involution taking each hexagram to a K₄-orbit mate, with endpoint
    cost 192 (= 2 × 96 < 2 × 120). -/
theorem full_k4_can_do_192 :
    (∀ h, h < 64 →
      (mCR h = comp6 h ∨ mCR h = rev6 h ∨ mCR h = crev6 h) ∧ mCR h ≠ h ∧
        mCR (mCR h) = h) ∧
    sumTo (fun h => ham h (mCR h)) 64 = 192 := by decide

/- ------------------ honesty notes ------------------

  1. RESULT PROVENANCE. The mathematical result (statement and the case analysis it
     rests on) is Radisic's (arXiv:2601.07175); this file re-proves it independently
     in the repo's encoding so the repo does not need to trust — or fetch — an
     external artifact. It was written AFTER reading Radisic's proof and is not an
     independent discovery.

  2. WHAT "UNIQUE" QUANTIFIES OVER. `IsCompRevPairing` does not assume involutivity,
     so uniqueness is proved over a class strictly LARGER than perfect matchings;
     uniqueness among perfect comp/rev matchings is an immediate corollary
     (`partner_involution` shows the optimum is one).

  3. ENDPOINT VS PAIR COSTS. Sums over all 64 endpoints count each pair twice:
     240/384/192 endpoint = 120/192/96 per-pair, the numbers in Radisic's abstract.

  4. SCOPE. Nothing here claims C1 is optimal over the full K₄ action — the opposite
     is machine-checked (`full_k4_can_do_192`). Radisic further characterizes the C1
     rule as the unique lexicographic/weighted optimum when Hamming-weight
     preservation is prioritized (his §weight-conservation); that stronger
     characterization is NOT re-proved here and, where cited, rests on his artifact.
-/

/-! ### Axiom audit (added 2026-08-01)
Emits the trust base for every theorem in this file that is CITED BY NAME in the
public documentation, so the suite's `#print axioms` claims are OBSERVED rather than
statically inferred. Expected: `[propext, Classical.choice, Quot.sound]`, or
`[propext]` alone for the finite facts. Any `Lean.ofReduceBool` here means a
`native_decide` (compiler trust) is load-bearing and the docs must say so.
(On leanprover/lean4:v4.31.0 a `native_decide` proof instead surfaces under `#print axioms` as an
auxiliary axiom named `<decl>._native.native_decide.ax_*`, NOT as `Lean.ofReduceBool` — measured
2026-09-04. So the ABSENCE of `Lean.ofReduceBool` is not a sufficient tell; the sound check is the
ALLOWLIST: any axiom token outside [propext, Classical.choice, Quot.sound] fails the audit.) -/
#print axioms partner_involution
#print axioms partner_cost_240
#print axioms comp_only_cost_384
#print axioms partner_is_unique_minimum
#print axioms kw_realizes_partner
#print axioms full_k4_can_do_192
