-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  SatEncodingFidelity.lean — machine-checked model-level fidelity of the reduced-subset
  SAT encoding (sat.py `build_subset_pl`): soundness + model-determinism (injectivity)
  + completeness for the ABSTRACT clause structure, uniform in the instance size n
  (2026-08-31).

  ─────────────────────────────────────────────────────────────────────────
  SCOPE — read this before citing (model-level result, stated bluntly).

  What is machine-checked here is an ABSTRACT MODEL of the CNF that sat.py's
  `build_subset_pl(pl, start_exit, b0)` emits: an inductively defined clause
  family `IsClause E` over abstract parameters E = (n slots/pairs, m orientation
  indices, a pair projection, per-boundary distance-class data, a class budget
  b0), mirroring the Python emitter loop-by-loop (the audit table below maps
  each constructor to its emission site). NOTHING in this file mentions
  hexagrams, bit_diff, King Wen pairs, DIMACS integers, or the Python code
  itself. The bridge from this model to the SHIPPING encoder is NOT
  machine-checked; it is carried by:

  · the side-by-side structural correspondence (audit table below), and
  · the executed n=9 set-level evidence (B1 2026-08-27, re-executed 2026-08-28):
    generic total-model enumeration over all 450 variables of the emitted n=9
    CNF decodes to exactly the clean-room walk set, bijectively.

  A Lean theorem about `IsClause E` becomes a statement about the CNF sat.py
  actually writes only via that unchecked (but auditable and empirically
  exercised) correspondence — exactly the trust posture of
  CompilerCorrectness.lean (model theorems + stated bridges). Nothing in this
  file proves sat.py bug-free; nothing here touches the C enumerator, the
  certified-counting pipeline, or leg (iii) of the B1 §5 argument (the
  independent cardinality identity |models| = |valid|, which stays with
  verify.py's clean-room recurrence and is deliberately NOT attempted here).

  WHAT IS PROVED (all at the abstract level, uniform in n — so in particular
  covering the n=13 instance shape, whose set-level fidelity was previously
  closed by prose argument only):

  · `model_soundness` — leg (i) of B1 §5: every satisfying assignment of the
    clause family decodes to a well-defined slot→orientation walk that is
    pair-complete (each pair exactly once), crosses no forbidden boundary
    (the 0/5-distance exclusions), and realizes the class budget b0 exactly.
  · `model_determinism` / `model_injectivity` — leg (ii): a satisfying
    assignment is determined, on every ALLOCATED variable (Y, T, and both
    Sinz register arrays — the `Used` predicate mirrors sat.py's cnf.var()
    allocation exactly, including the k=0 / k>=n branches that allocate no
    registers), by its decoded walk; hence two models with the same decoded
    walk agree on all allocated variables. This is the "Y one-hot +
    functionally determined auxiliaries" claim, now proved rather than
    argued: the T indicators are forced by the boundary clauses, and the
    Sinz sequential-counter registers (Sinz 2005) are pinned to the exact
    prefix-count semantics r i j = (count of first i+1 column bits > j) BY
    the clauses once the column total equals the budget — the at-most and
    at-least arrays both sit at their extreme value, which kills the
    register freedom that bare at_most_k registers famously have (the S01
    review's observation; it is re-proved here as: determination REQUIRES
    the exactly_k context, base case c(n)=k).
  · `model_completeness` — strictly more than B1 §5 asked for: every valid
    walk arises as the decode of a satisfying assignment (the canonical
    model), so at the abstract level decode is a BIJECTION between models
    (restricted to allocated variables) and valid walks — `decode_bijection`.
    At the model level this subsumes the three-leg argument; the CONCRETE
    n=13 claim still routes through the unchecked bridge above, so the
    operative project argument (i)+(ii)+(iii) is unchanged in structure —
    its legs (i)/(ii) are simply no longer carried by prose.

  NON-VACUITY: `nonvacuity_*` exhibits a concrete instance and walk with a
  satisfying model, so none of the theorems above is vacuously true of an
  unsatisfiable clause family.

  ─────────────────────────────────────────────────────────────────────────
  AUDIT TABLE — constructor ↔ sat.py `build_subset_pl` emission site
  (slots here are 0-based; sat.py slots are 1-based, slot s+1 there = s here;
  distance VALUES {1,2,3,4,6} (_DVAL) are renamed to class INDICES 0..D-1
  (D = 5 in the shipping encoder, kept abstract here); DIMACS variable
  integers from cnf.var() are renamed to the injective constructors of `V` —
  freshness of Python's allocation = constructor injectivity here; clause
  ORDER and intra-clause literal order are irrelevant to satisfaction and
  are not modeled; the pairwise clauses of exactly_one appear here for each
  ORDERED pair of distinct elements where Python emits each unordered pair
  once — a satisfaction-identical set):

  · slotAlo / slotAmo   — `for s in slots: exactly_one(cnf, [Y[(s,j)] ...])`
  · pairAlo / pairAmo   — `for lp in range(n): exactly_one(... orients[j][0]==lp)`
  · tAlo / tAmo         — `for s in range(n): ... exactly_one(cnf, [T[(s,dv)] ...])`
  · anchorBlock/anchorCls — the boundary-0 loop (`dd == 5 or dd == 0` block vs
                          `cnf.add(-Y[(1,j)], T[(0,dd)])`); E.anchor j = none
                          models the blocked case, some d the class-dd case
  · stepBlock/stepCls   — the `for s in range(1, n)` boundary loop (same-pair
                          (j1,j2) combinations are SKIPPED there and are
                          accordingly absent here: hdp)
  · szZero              — at_most_k's `k == 0` branch (all-negative units);
                          reached by exactly_k for a zero budget class (at-most
                          side) and for a full budget b0 d = n (at-least side)
  · szX0/szUnit0/szChain/szDiag/szCap
                        — at_most_k's Sinz register clauses, 0 < k < n branch,
                          rows reindexed i-1,i ↦ i,i+1 and the level-0 chain
                          merged with the level j>=1 chain (identical clause
                          sets): szX0 = `(-lits[i], s[i][0])` for all i (the
                          i=0 seed and the i>=1 row), szUnit0 = `(-s[0][j])`,
                          szChain = `(-s[i-1][j], s[i][j])` for j in [0,k),
                          szDiag = `(-lits[i], -s[i-1][j-1], s[i][j])`,
                          szCap = `(-lits[i], -s[i-1][k-1])`
  · the `k >= n` branch of at_most_k emits nothing and accordingly has no
    constructor; `at_least_k(lits,k) = at_most_k([-x ...], n-k)` is modeled by
    side := false (column literal polarity flipped, bound n - b0 d, register
    array B instead of A)

  The Python emitter's implicit preconditions carried as hypotheses here:
  WF.b0_le (each budget <= n; sat.py's at_most_k raises on a negative bound
  rather than emit, so a b0 d > n instance never emits a CNF), WF.npos
  (n >= 1; every shipping subset instance), WF.pair_lt / WF.anchor_lt /
  WF.step_lt (indices in range; true of the shipping emitter by
  construction). The abstract instantiation intended (NOT in Lean): m = 2n,
  pairOf j = j/2 over the orients list, anchor j = the class of
  bit_diff(start_exit, entry_hex(j)) with none at distance 0/5, step j1 j2
  likewise for bit_diff(exit_hex(j1), entry_hex(j2)), b0 = derive_b0.
  `ValidWalk` then instantiates to exactly sat.py `verify_subset`'s checks
  (pair-completeness = C1 distinctness given the KW pair partition, no
  0/5 boundary = C2 + distinctness across consecutive slots, budget = C5)
  — that identification is again bridge, not Lean.

  Attribution: the sequential-counter encoding is Sinz 2005 (CP 2005, LNCS
  3709); the register-determination-inside-exactly-k observation was raised
  by the S01/S03 external reviews (2026-08) and is proved here. To our
  knowledge this particular machine-checked formalization is ours;
  corrections welcome.

  Core Lean 4 only (no mathlib, no lake); pinned toolchain
  leanprover/lean4:v4.31.0 (`lean-toolchain` in this directory). Gate:
  `lean SatEncodingFidelity.lean` must exit 0 with no output beyond the
  trailing `#print axioms` reports; zero sorry / axiom / admit / native_decide.
-/

namespace SatEncodingFidelity

/-- CNF variables of the abstract reduced-subset encoding. `Y s j` = slot `s`
    holds orientation `j`; `T b d` = boundary `b` has distance class `d`;
    `A d i j` / `B d i j` = the Sinz sequential-counter registers of the
    at-most (`A`) and at-least (`B`) halves of the class-`d` `exactly_k`.
    Injectivity of these constructors models the freshness of `cnf.var()`. -/
inductive V where
  | Y : Nat → Nat → V
  | T : Nat → Nat → V
  | A : Nat → Nat → Nat → V
  | B : Nat → Nat → Nat → V
deriving DecidableEq

/-- A literal: variable plus polarity (`true` = positive). -/
abbrev Lit := V × Bool

abbrev Clause := List Lit

/-- A total assignment. DIMACS models assign only allocated variables; the
    restriction to allocated ones is the `Used` predicate below, and the
    injectivity theorem is stated on `Used` exactly for this reason. -/
abbrev Model := V → Bool

def litSat (v : Model) (l : Lit) : Prop := v l.1 = l.2

def clauseSat (v : Model) (c : Clause) : Prop := ∃ l ∈ c, litSat v l

theorem clauseSat_one {v : Model} {a : V} {p : Bool} :
    clauseSat v [(a, p)] ↔ v a = p := by
  simp [clauseSat, litSat]

theorem clauseSat_two {v : Model} {a b : V} {p q : Bool} :
    clauseSat v [(a, p), (b, q)] ↔ v a = p ∨ v b = q := by
  simp [clauseSat, litSat]

theorem clauseSat_three {v : Model} {a b c : V} {p q s : Bool} :
    clauseSat v [(a, p), (b, q), (c, s)] ↔ v a = p ∨ v b = q ∨ v c = s := by
  simp [clauseSat, litSat]

/-! ### Prefix counts

`cnt f i` = number of `t < i` with `f t = true`. Self-contained replacement
for finset/multiset counting; this is the quantity the Sinz registers track. -/

def cnt (f : Nat → Bool) : Nat → Nat
  | 0 => 0
  | i + 1 => cnt f i + (if f i then 1 else 0)

theorem cnt_succ (f : Nat → Bool) (i : Nat) :
    cnt f (i + 1) = cnt f i + (if f i then 1 else 0) := rfl

theorem cnt_le (f : Nat → Bool) : ∀ i, cnt f i ≤ i
  | 0 => Nat.le_refl 0
  | i + 1 => by
      have h := cnt_le f i
      by_cases hf : f i <;> simp [cnt_succ, hf] <;> omega

theorem cnt_succ_true {f : Nat → Bool} {i : Nat} (h : f i = true) :
    cnt f (i + 1) = cnt f i + 1 := by simp [cnt_succ, h]

theorem cnt_succ_false {f : Nat → Bool} {i : Nat} (h : f i = false) :
    cnt f (i + 1) = cnt f i := by simp [cnt_succ, h]

theorem cnt_mono (f : Nat → Bool) {i j : Nat} (h : i ≤ j) : cnt f i ≤ cnt f j := by
  induction j with
  | zero =>
      have hi : i = 0 := Nat.le_zero.mp h
      subst hi
      exact Nat.le_refl _
  | succ j ih =>
      rcases Nat.lt_or_ge i (j + 1) with hlt | hge
      · have h1 := ih (by omega)
        have h2 : cnt f j ≤ cnt f (j + 1) := by
          rw [cnt_succ]
          omega
        omega
      · have hi : i = j + 1 := by omega
        subst hi
        exact Nat.le_refl _

/-- Pointwise agreement below `i` gives equal prefix counts at `i`. -/
theorem cnt_congr {f g : Nat → Bool} : ∀ {i}, (∀ t, t < i → f t = g t) →
    cnt f i = cnt g i := by
  intro i
  induction i with
  | zero => intro _; rfl
  | succ i ih =>
      intro h
      have hfg : f i = g i := h i (Nat.lt_succ_self i)
      have := ih (fun t ht => h t (Nat.lt_succ_of_lt ht))
      simp [cnt_succ, hfg, this]

/-- Count of the pointwise negation: `cnt (!f) i = i - cnt f i`. -/
theorem cnt_not (f : Nat → Bool) : ∀ i, cnt (fun t => !(f t)) i = i - cnt f i := by
  intro i
  induction i with
  | zero => rfl
  | succ i ih =>
      have hle := cnt_le f i
      by_cases hf : f i <;> simp [cnt_succ, hf, ih] <;> omega

theorem cnt_true_le {f : Nat → Bool} {t i : Nat} (ht : t < i) (hf : f t = true) :
    cnt f t + 1 ≤ cnt f i := by
  have h1 : cnt f (t + 1) = cnt f t + 1 := by simp [cnt_succ, hf]
  have h2 : cnt f (t + 1) ≤ cnt f i := cnt_mono f (by omega)
  omega

/-- A zero total count forces every entry below `i` to be `false`. -/
theorem all_false_of_cnt_zero {f : Nat → Bool} {i : Nat} (h : cnt f i = 0) :
    ∀ t, t < i → f t = false := by
  intro t ht
  by_cases hf : f t
  · have := cnt_true_le ht hf
    omega
  · simpa using hf

/-- A full total count forces every entry below `i` to be `true`. -/
theorem all_true_of_cnt_full {f : Nat → Bool} {i : Nat} (h : cnt f i = i) :
    ∀ t, t < i → f t = true := by
  intro t ht
  by_cases hf : f t
  · exact hf
  · exfalso
    have hnot : (fun u => !(f u)) t = true := by simp [hf]
    have := cnt_true_le (f := fun u => !(f u)) ht hnot
    have hn := cnt_not f i
    have := cnt_le f t
    omega

/-! ### The abstract encoding parameters -/

/-- Abstract parameters of one reduced-subset instance.

    Intended (bridge-level, NOT in Lean) instantiation for
    `build_subset_pl(pl, start_exit, b0)`: `n = len(pl)`, `m = 2n` with
    `pairOf j = j / 2` (the orients list), `anchor j` = `some` of the class of
    `bit_diff(start_exit, entry_hex(j))` or `none` at distance 0/5, `step j1 j2`
    likewise for `bit_diff(exit_hex(j1), entry_hex(j2))`, `b0` = the derived
    boundary budget by class index. -/
structure Enc where
  n : Nat
  m : Nat
  pairOf : Nat → Nat
  D : Nat
  anchor : Nat → Option Nat
  step : Nat → Nat → Option Nat
  b0 : Nat → Nat

/-- Well-formedness facts the Python emitter guarantees by construction
    (see the header audit table). -/
structure WF (E : Enc) : Prop where
  npos : 0 < E.n
  pair_lt : ∀ j, j < E.m → E.pairOf j < E.n
  anchor_lt : ∀ j d, E.anchor j = some d → d < E.D
  step_lt : ∀ j₁ j₂ d, E.step j₁ j₂ = some d → d < E.D
  b0_le : ∀ d, d < E.D → E.b0 d ≤ E.n

/-- Register array selector: `side = true` is the at-most half (array `A`,
    positive column literals, bound `b0 d`); `side = false` is the at-least
    half (array `B`, negated column literals, bound `n - b0 d`) — modeling
    `at_least_k(lits, k) = at_most_k([-x for x in lits], n - k)`. -/
def reg (side : Bool) (d i j : Nat) : V := if side then .A d i j else .B d i j

def bound (E : Enc) (side : Bool) (d : Nat) : Nat :=
  if side then E.b0 d else E.n - E.b0 d

/-- The clause family emitted by `build_subset_pl`, as an inductive predicate
    (set of clauses; order/duplication are satisfaction-irrelevant). Each
    constructor mirrors one Python emission site — see the header audit table. -/
inductive IsClause (E : Enc) : Clause → Prop where
  | slotAlo (s : Nat) (hs : s < E.n) :
      IsClause E ((List.range E.m).map (fun j => ((V.Y s j), true)))
  | slotAmo (s j₁ j₂ : Nat) (hs : s < E.n) (hj₁ : j₁ < E.m) (hj₂ : j₂ < E.m)
      (hne : j₁ ≠ j₂) :
      IsClause E [(V.Y s j₁, false), (V.Y s j₂, false)]
  | pairAlo (p : Nat) (hp : p < E.n) :
      IsClause E ((List.range E.n).flatMap (fun s => (List.range E.m).filterMap
        (fun j => if E.pairOf j = p then some ((V.Y s j), true) else none)))
  | pairAmo (p s₁ j₁ s₂ j₂ : Nat) (hp : p < E.n) (hs₁ : s₁ < E.n) (hj₁ : j₁ < E.m)
      (hs₂ : s₂ < E.n) (hj₂ : j₂ < E.m) (hp₁ : E.pairOf j₁ = p) (hp₂ : E.pairOf j₂ = p)
      (hne : ¬(s₁ = s₂ ∧ j₁ = j₂)) :
      IsClause E [(V.Y s₁ j₁, false), (V.Y s₂ j₂, false)]
  | tAlo (b : Nat) (hb : b < E.n) :
      IsClause E ((List.range E.D).map (fun d => ((V.T b d), true)))
  | tAmo (b d₁ d₂ : Nat) (hb : b < E.n) (hd₁ : d₁ < E.D) (hd₂ : d₂ < E.D)
      (hne : d₁ ≠ d₂) :
      IsClause E [(V.T b d₁, false), (V.T b d₂, false)]
  | anchorBlock (j : Nat) (hn : 0 < E.n) (hj : j < E.m) (hblk : E.anchor j = none) :
      IsClause E [(V.Y 0 j, false)]
  | anchorCls (j d : Nat) (hn : 0 < E.n) (hj : j < E.m) (hcl : E.anchor j = some d) :
      IsClause E [(V.Y 0 j, false), (V.T 0 d, true)]
  | stepBlock (b j₁ j₂ : Nat) (hb : b + 1 < E.n) (hj₁ : j₁ < E.m) (hj₂ : j₂ < E.m)
      (hdp : E.pairOf j₁ ≠ E.pairOf j₂) (hblk : E.step j₁ j₂ = none) :
      IsClause E [(V.Y b j₁, false), (V.Y (b + 1) j₂, false)]
  | stepCls (b j₁ j₂ d : Nat) (hb : b + 1 < E.n) (hj₁ : j₁ < E.m) (hj₂ : j₂ < E.m)
      (hdp : E.pairOf j₁ ≠ E.pairOf j₂) (hcl : E.step j₁ j₂ = some d) :
      IsClause E [(V.Y b j₁, false), (V.Y (b + 1) j₂, false), (V.T (b + 1) d, true)]
  | szZero (side : Bool) (d i : Nat) (hd : d < E.D) (hi : i < E.n)
      (hk : bound E side d = 0) :
      IsClause E [(V.T i d, !side)]
  | szX0 (side : Bool) (d i : Nat) (hd : d < E.D) (h0 : 0 < bound E side d)
      (hkn : bound E side d < E.n) (hi : i < E.n) :
      IsClause E [(V.T i d, !side), (reg side d i 0, true)]
  | szUnit0 (side : Bool) (d j : Nat) (hd : d < E.D) (h0 : 0 < bound E side d)
      (hkn : bound E side d < E.n) (hj : 0 < j) (hjk : j < bound E side d) :
      IsClause E [(reg side d 0 j, false)]
  | szChain (side : Bool) (d i j : Nat) (hd : d < E.D) (h0 : 0 < bound E side d)
      (hkn : bound E side d < E.n) (hi : i + 1 < E.n) (hjk : j < bound E side d) :
      IsClause E [(reg side d i j, false), (reg side d (i + 1) j, true)]
  | szDiag (side : Bool) (d i j : Nat) (hd : d < E.D) (h0 : 0 < bound E side d)
      (hkn : bound E side d < E.n) (hi : i + 1 < E.n) (hjk : j + 1 < bound E side d) :
      IsClause E [(V.T (i + 1) d, !side), (reg side d i j, false),
                  (reg side d (i + 1) (j + 1), true)]
  | szCap (side : Bool) (d i : Nat) (hd : d < E.D) (h0 : 0 < bound E side d)
      (hkn : bound E side d < E.n) (hi : i + 1 < E.n) :
      IsClause E [(V.T (i + 1) d, !side), (reg side d i (bound E side d - 1), false)]

/-- `v` satisfies the whole instance. -/
def Sat (E : Enc) (v : Model) : Prop := ∀ c, IsClause E c → clauseSat v c

/-! ### Elimination: from `Sat` to usable facts -/

section Elim
variable {E : Enc} {v : Model}

/-- The column bit the Sinz half tracks: for the at-most half (`side = true`)
    literal `i` is `T i d` itself; for the at-least half it is its negation. -/
def xcol (v : Model) (side : Bool) (d i : Nat) : Bool := v (V.T i d) == side

theorem xcol_not (v : Model) (d i : Nat) :
    xcol v false d i = !(xcol v true d i) := by
  unfold xcol
  cases v (V.T i d) <;> rfl

/-- A satisfied `[¬T, r]` clause, read as an implication on the column bit. -/
theorem col_imp {side : Bool} {d i : Nat} {w : V}
    (h : clauseSat v [(V.T i d, !side), (w, true)]) :
    xcol v side d i = true → v w = true := by
  intro hx
  rcases clauseSat_two.mp h with hT | hw
  · exfalso
    unfold xcol at hx
    cases side <;> cases hv : v (V.T i d) <;> simp [hv] at hT hx
  · exact hw

theorem sat_slotAlo (hv : Sat E v) {s : Nat} (hs : s < E.n) :
    ∃ j, j < E.m ∧ v (V.Y s j) = true := by
  have h := hv _ (IsClause.slotAlo s hs)
  rcases h with ⟨l, hl, hsat⟩
  rcases List.mem_map.mp hl with ⟨j, hj, rfl⟩
  exact ⟨j, List.mem_range.mp hj, hsat⟩

theorem sat_slotAmo (hv : Sat E v) {s j₁ j₂ : Nat} (hs : s < E.n)
    (hj₁ : j₁ < E.m) (hj₂ : j₂ < E.m) (hne : j₁ ≠ j₂) :
    ¬(v (V.Y s j₁) = true ∧ v (V.Y s j₂) = true) := by
  rintro ⟨h1, h2⟩
  have h := hv _ (IsClause.slotAmo s j₁ j₂ hs hj₁ hj₂ hne)
  rcases clauseSat_two.mp h with hc | hc <;> simp_all

theorem sat_pairAlo (hv : Sat E v) {p : Nat} (hp : p < E.n) :
    ∃ s j, s < E.n ∧ j < E.m ∧ E.pairOf j = p ∧ v (V.Y s j) = true := by
  have h := hv _ (IsClause.pairAlo p hp)
  rcases h with ⟨l, hl, hsat⟩
  rcases List.mem_flatMap.mp hl with ⟨s, hs, hmem⟩
  rcases List.mem_filterMap.mp hmem with ⟨j, hj, hsome⟩
  by_cases hcond : E.pairOf j = p
  · rw [if_pos hcond] at hsome
    cases hsome
    exact ⟨s, j, List.mem_range.mp hs, List.mem_range.mp hj, hcond, hsat⟩
  · simp [hcond] at hsome

theorem sat_pairAmo (hv : Sat E v) {p s₁ j₁ s₂ j₂ : Nat} (hp : p < E.n)
    (hs₁ : s₁ < E.n) (hj₁ : j₁ < E.m) (hs₂ : s₂ < E.n) (hj₂ : j₂ < E.m)
    (hp₁ : E.pairOf j₁ = p) (hp₂ : E.pairOf j₂ = p) (hne : ¬(s₁ = s₂ ∧ j₁ = j₂)) :
    ¬(v (V.Y s₁ j₁) = true ∧ v (V.Y s₂ j₂) = true) := by
  rintro ⟨h1, h2⟩
  have h := hv _ (IsClause.pairAmo p s₁ j₁ s₂ j₂ hp hs₁ hj₁ hs₂ hj₂ hp₁ hp₂ hne)
  rcases clauseSat_two.mp h with hc | hc <;> simp_all

theorem sat_tAlo (hv : Sat E v) {b : Nat} (hb : b < E.n) :
    ∃ d, d < E.D ∧ v (V.T b d) = true := by
  have h := hv _ (IsClause.tAlo b hb)
  rcases h with ⟨l, hl, hsat⟩
  rcases List.mem_map.mp hl with ⟨d, hd, rfl⟩
  exact ⟨d, List.mem_range.mp hd, hsat⟩

theorem sat_tAmo (hv : Sat E v) {b d₁ d₂ : Nat} (hb : b < E.n)
    (hd₁ : d₁ < E.D) (hd₂ : d₂ < E.D) (hne : d₁ ≠ d₂) :
    ¬(v (V.T b d₁) = true ∧ v (V.T b d₂) = true) := by
  rintro ⟨h1, h2⟩
  have h := hv _ (IsClause.tAmo b d₁ d₂ hb hd₁ hd₂ hne)
  rcases clauseSat_two.mp h with hc | hc <;> simp_all

end Elim

/-! ### The Sinz sequential-counter core, abstractly

Everything in this section is about one register array `r` over one column
`x` of length `n` with bound `k`, given exactly the clause facts the `sz*`
constructors provide (0 < k < n branch). `sinz_upper` is the classical
soundness direction (the count never exceeds `k`, and registers are forced
true up to the running count). `sinz_lower` is the determination direction:
ONCE THE COLUMN TOTAL EQUALS `k` — which only the `exactly_k` context
supplies — registers are also forced false above the running count, so they
are pinned to `r i j = decide (j + 1 ≤ cnt x (i+1))` (`sinz_det`). Bare
`at_most_k` registers are NOT functionally determined (the S01 review's
point); the `htot` hypothesis below is precisely where that freedom dies. -/

section SinzCore
variable {x : Nat → Bool} {r : Nat → Nat → Bool} {n k : Nat}

theorem sinz_upper
    (hx0 : ∀ i, i < n → x i = true → r i 0 = true)
    (hdg : ∀ i j, i + 1 < n → j + 1 < k → x (i + 1) = true → r i j = true →
      r (i + 1) (j + 1) = true)
    (hch : ∀ i j, i + 1 < n → j < k → r i j = true → r (i + 1) j = true)
    (hcap : ∀ i, i + 1 < n → x (i + 1) = true → r i (k - 1) = false)
    (hk : 0 < k) :
    ∀ i, i < n → cnt x (i + 1) ≤ k ∧
      (∀ j, j < k → j + 1 ≤ cnt x (i + 1) → r i j = true) := by
  intro i
  induction i with
  | zero =>
      intro _
      have hle1 := cnt_le x (0 + 1)
      constructor
      · omega
      · intro j hj hle
        have hj0 : j = 0 := by omega
        subst hj0
        have hx : x 0 = true := by
          cases hxx : x 0 with
          | true => rfl
          | false =>
              exfalso
              rw [cnt_succ_false hxx] at hle
              have h0 : cnt x 0 = 0 := rfl
              omega
        exact hx0 0 (by omega) hx
  | succ i ih =>
      intro hin
      have hi : i < n := by omega
      obtain ⟨hbnd, hup⟩ := ih hi
      constructor
      · -- the count cannot pass k: the (k+1)-th true would trip the cap clause
        by_cases hx : x (i + 1) = true
        · by_cases hfull : cnt x (i + 1) = k
          · exfalso
            have hreg : r i (k - 1) = true := hup (k - 1) (by omega) (by omega)
            have hno := hcap i hin hx
            rw [hno] at hreg
            exact Bool.false_ne_true hreg
          · rw [cnt_succ_true hx]
            omega
        · have hx' : x (i + 1) = false := by simpa using hx
          rw [cnt_succ_false hx']
          omega
      · intro j hj hle
        by_cases hx : x (i + 1) = true
        · cases j with
          | zero => exact hx0 (i + 1) hin hx
          | succ j' =>
              rw [cnt_succ_true hx] at hle
              have hprev : r i j' = true := hup j' (by omega) (by omega)
              exact hdg i j' hin (by omega) hx hprev
        · have hx' : x (i + 1) = false := by simpa using hx
          rw [cnt_succ_false hx'] at hle
          have hprev : r i j = true := hup j hj (by omega)
          exact hch i j hin hj hprev

/-- The at-most bound at the full column (needs `k < n`, the only branch in
    which these register clauses exist at all). -/
theorem sinz_le
    (hx0 : ∀ i, i < n → x i = true → r i 0 = true)
    (hdg : ∀ i j, i + 1 < n → j + 1 < k → x (i + 1) = true → r i j = true →
      r (i + 1) (j + 1) = true)
    (hch : ∀ i j, i + 1 < n → j < k → r i j = true → r (i + 1) j = true)
    (hcap : ∀ i, i + 1 < n → x (i + 1) = true → r i (k - 1) = false)
    (hk : 0 < k) (hkn : k < n) :
    cnt x n ≤ k := by
  have h := (sinz_upper hx0 hdg hch hcap hk (n - 1) (by omega)).1
  have : n - 1 + 1 = n := by omega
  rwa [this] at h

/-- Downward determination: with the column total pinned to `k`, a register
    true above the running count propagates forward to a cap violation, so it
    cannot be true. Downward induction on the distance to the last row. -/
theorem sinz_lower
    (hdg : ∀ i j, i + 1 < n → j + 1 < k → x (i + 1) = true → r i j = true →
      r (i + 1) (j + 1) = true)
    (hch : ∀ i j, i + 1 < n → j < k → r i j = true → r (i + 1) j = true)
    (hcap : ∀ i, i + 1 < n → x (i + 1) = true → r i (k - 1) = false)
    (htot : cnt x n = k) :
    ∀ t i, i < n → n - 1 - i = t → ∀ j, j < k → r i j = true →
      j + 1 ≤ cnt x (i + 1) := by
  intro t
  induction t with
  | zero =>
      intro i hi hlast j hj _
      have : i + 1 = n := by omega
      rw [this, htot]
      omega
  | succ t ih =>
      intro i hi hdist j hj hr
      have hin : i + 1 < n := by omega
      by_cases hx : x (i + 1) = true
      · by_cases htop : j + 1 = k
        · exfalso
          have hno := hcap i hin hx
          have hjk : j = k - 1 := by omega
          rw [hjk, hno] at hr
          exact Bool.false_ne_true hr
        · have hnext : r (i + 1) (j + 1) = true := hdg i j hin (by omega) hx hr
          have hrec : j + 1 + 1 ≤ cnt x (i + 1 + 1) :=
            ih (i + 1) hin (by omega) (j + 1) (by omega) hnext
          have hcnt : cnt x (i + 1 + 1) = cnt x (i + 1) + 1 := cnt_succ_true hx
          omega
      · have hx' : x (i + 1) = false := by simpa using hx
        have hnext : r (i + 1) j = true := hch i j hin hj hr
        have hrec : j + 1 ≤ cnt x (i + 1 + 1) :=
          ih (i + 1) hin (by omega) j hj hnext
        have hcnt : cnt x (i + 1 + 1) = cnt x (i + 1) := cnt_succ_false hx'
        omega

/-- Full functional determination of a Sinz register array inside `exactly_k`. -/
theorem sinz_det
    (hx0 : ∀ i, i < n → x i = true → r i 0 = true)
    (hdg : ∀ i j, i + 1 < n → j + 1 < k → x (i + 1) = true → r i j = true →
      r (i + 1) (j + 1) = true)
    (hch : ∀ i j, i + 1 < n → j < k → r i j = true → r (i + 1) j = true)
    (hcap : ∀ i, i + 1 < n → x (i + 1) = true → r i (k - 1) = false)
    (hk : 0 < k) (htot : cnt x n = k) :
    ∀ i, i < n → ∀ j, j < k → r i j = decide (j + 1 ≤ cnt x (i + 1)) := by
  intro i hi j hj
  by_cases hle : j + 1 ≤ cnt x (i + 1)
  · have := (sinz_upper hx0 hdg hch hcap hk i hi).2 j hj hle
    simp [this, hle]
  · by_cases hr : r i j = true
    · exact absurd (sinz_lower hdg hch hcap htot (n - 1 - i) i hi rfl j hj hr) hle
    · simp at hr
      simp [hr, hle]

/-! Canonical-register clause closure — the completeness direction: the
pinned values `decide (j + 1 ≤ cnt x (i+1))` themselves satisfy every register
clause shape (given only that the column total does not exceed `k`, for the
cap clause). -/

theorem can_x0 {i : Nat} (hx : x i = true) :
    decide (0 + 1 ≤ cnt x (i + 1)) = true := by
  simp [cnt_succ, hx]

theorem can_unit0 {j : Nat} (hj : 0 < j) :
    decide (j + 1 ≤ cnt x (0 + 1)) = false := by
  have hle := cnt_le x (0 + 1)
  simp only [decide_eq_false_iff_not]
  omega

theorem can_chain {i j : Nat} (h : decide (j + 1 ≤ cnt x (i + 1)) = true) :
    decide (j + 1 ≤ cnt x (i + 1 + 1)) = true := by
  simp only [decide_eq_true_eq] at h ⊢
  have hmono : cnt x (i + 1) ≤ cnt x (i + 1 + 1) := cnt_mono x (Nat.le_succ (i + 1))
  omega

theorem can_diag {i j : Nat} (hx : x (i + 1) = true)
    (h : decide (j + 1 ≤ cnt x (i + 1)) = true) :
    decide (j + 1 + 1 ≤ cnt x (i + 1 + 1)) = true := by
  simp only [decide_eq_true_eq] at h ⊢
  have hs := cnt_succ_true hx
  omega

theorem can_cap {i : Nat} (hk : 0 < k) (hin : i + 1 < n) (htot : cnt x n ≤ k)
    (hx : x (i + 1) = true) :
    decide (k - 1 + 1 ≤ cnt x (i + 1)) = false := by
  simp only [decide_eq_false_iff_not]
  intro hge
  have h1 := cnt_succ_true hx
  have h2 := cnt_mono x (show i + 1 + 1 ≤ n by omega)
  omega

end SinzCore

/-! ### Decoded walks, validity, the canonical model, and the allocated set -/

/-- Distance class of boundary `b` under the slot assignment `σ`:
    boundary 0 is anchor → slot 0 (sat.py's fixed `start_exit` → slot 1);
    boundary `b+1` is slot `b` → slot `b+1`. `none` = a forbidden boundary
    (distance 0 or 5 in the shipping instantiation). -/
def bcls (E : Enc) (σ : Nat → Nat) : Nat → Option Nat
  | 0 => E.anchor (σ 0)
  | b + 1 => E.step (σ b) (σ (b + 1))

/-- Validity of a decoded walk — the abstract counterpart of sat.py
    `verify_subset`: pair-completeness (C1 at pair level), no forbidden
    boundary (C2 + the distance-0 exclusion), exact class budget (C5). -/
structure ValidWalk (E : Enc) (σ : Nat → Nat) : Prop where
  range : ∀ s, s < E.n → σ s < E.m
  inj : ∀ s₁ s₂, s₁ < E.n → s₂ < E.n → E.pairOf (σ s₁) = E.pairOf (σ s₂) → s₁ = s₂
  surj : ∀ p, p < E.n → ∃ s, s < E.n ∧ E.pairOf (σ s) = p
  ok : ∀ b, b < E.n → (bcls E σ b).isSome
  budget : ∀ d, d < E.D →
    cnt (fun b => decide (bcls E σ b = some d)) E.n = E.b0 d

/-- `σ` is THE decode of model `v`: on every slot the unique true `Y`. -/
structure Decodes (E : Enc) (v : Model) (σ : Nat → Nat) : Prop where
  range : ∀ s, s < E.n → σ s < E.m
  hit : ∀ s, s < E.n → v (V.Y s (σ s)) = true
  uniq : ∀ s j, s < E.n → j < E.m → v (V.Y s j) = true → j = σ s

/-- The boundary-class indicator of the canonical model. -/
def canonT (E : Enc) (σ : Nat → Nat) (b d : Nat) : Bool :=
  decide (bcls E σ b = some d)

/-- Prefix count of class-`d` boundaries of the walk. -/
def ccnt (E : Enc) (σ : Nat → Nat) (d i : Nat) : Nat :=
  cnt (fun b => canonT E σ b d) i

/-- The canonical model of a walk: one-hot `Y`, boundary-class `T`, and both
    Sinz register arrays at their pinned prefix-count values. -/
def canon (E : Enc) (σ : Nat → Nat) : Model
  | .Y s j => decide (j = σ s)
  | .T b d => canonT E σ b d
  | .A d i j => decide (j + 1 ≤ ccnt E σ d (i + 1))
  | .B d i j => decide (j + 1 ≤ (i + 1) - ccnt E σ d (i + 1))

/-- The ALLOCATED variables — mirrors `cnf.var()` calls in `build_subset_pl` /
    `exactly_k` exactly: all `Y` and `T` in range; `A`-registers only when the
    at-most half takes the `0 < k < n` branch (`k = b0 d`); `B`-registers only
    when the at-least half does (`k = n - b0 d`). The `k = 0` and `k ≥ n`
    branches of `at_most_k` allocate nothing. Model-count/injectivity claims
    about the emitted DIMACS quantify over exactly this set. -/
def Used (E : Enc) : V → Prop
  | .Y s j => s < E.n ∧ j < E.m
  | .T b d => b < E.n ∧ d < E.D
  | .A d i j => d < E.D ∧ 0 < E.b0 d ∧ E.b0 d < E.n ∧ i < E.n ∧ j < E.b0 d
  | .B d i j => d < E.D ∧ 0 < E.n - E.b0 d ∧ E.n - E.b0 d < E.n ∧ i < E.n ∧
      j < E.n - E.b0 d

/-! ### Column facts: instantiating the Sinz core at a class column -/

section Columns
variable {E : Enc} {v : Model}

theorem xcol_true_iff {side : Bool} {d i : Nat} :
    xcol v side d i = true ↔ v (V.T i d) = side := by
  simp [xcol]

theorem sat_szX0 (hv : Sat E v) {side : Bool} {d : Nat} (hd : d < E.D)
    (h0 : 0 < bound E side d) (hkn : bound E side d < E.n) :
    ∀ i, i < E.n → xcol v side d i = true → v (reg side d i 0) = true := by
  intro i hi
  exact col_imp (hv _ (IsClause.szX0 side d i hd h0 hkn hi))

theorem sat_szUnit0 (hv : Sat E v) {side : Bool} {d : Nat} (hd : d < E.D)
    (h0 : 0 < bound E side d) (hkn : bound E side d < E.n) :
    ∀ j, 0 < j → j < bound E side d → v (reg side d 0 j) = false := by
  intro j hj hjk
  exact clauseSat_one.mp (hv _ (IsClause.szUnit0 side d j hd h0 hkn hj hjk))

theorem sat_szChain (hv : Sat E v) {side : Bool} {d : Nat} (hd : d < E.D)
    (h0 : 0 < bound E side d) (hkn : bound E side d < E.n) :
    ∀ i j, i + 1 < E.n → j < bound E side d →
      v (reg side d i j) = true → v (reg side d (i + 1) j) = true := by
  intro i j hi hjk hr
  rcases clauseSat_two.mp (hv _ (IsClause.szChain side d i j hd h0 hkn hi hjk)) with
    hc | hc
  · rw [hr] at hc
    exact absurd hc (by simp)
  · exact hc

theorem sat_szDiag (hv : Sat E v) {side : Bool} {d : Nat} (hd : d < E.D)
    (h0 : 0 < bound E side d) (hkn : bound E side d < E.n) :
    ∀ i j, i + 1 < E.n → j + 1 < bound E side d → xcol v side d (i + 1) = true →
      v (reg side d i j) = true → v (reg side d (i + 1) (j + 1)) = true := by
  intro i j hi hjk hx hr
  rcases clauseSat_three.mp (hv _ (IsClause.szDiag side d i j hd h0 hkn hi hjk)) with
    hc | hc | hc
  · exfalso
    have hT := xcol_true_iff.mp hx
    rw [hT] at hc
    cases side <;> simp at hc
  · rw [hr] at hc
    exact absurd hc (by simp)
  · exact hc

theorem sat_szCap (hv : Sat E v) {side : Bool} {d : Nat} (hd : d < E.D)
    (h0 : 0 < bound E side d) (hkn : bound E side d < E.n) :
    ∀ i, i + 1 < E.n → xcol v side d (i + 1) = true →
      v (reg side d i (bound E side d - 1)) = false := by
  intro i hi hx
  rcases clauseSat_two.mp (hv _ (IsClause.szCap side d i hd h0 hkn hi)) with hc | hc
  · exfalso
    have hT := xcol_true_iff.mp hx
    rw [hT] at hc
    cases side <;> simp at hc
  · exact hc

theorem cnt_zero_of_all_false {f : Nat → Bool} :
    ∀ {i}, (∀ t, t < i → f t = false) → cnt f i = 0 := by
  intro i
  induction i with
  | zero => intro _; rfl
  | succ i ih =>
      intro h
      have := ih (fun t ht => h t (Nat.lt_succ_of_lt ht))
      simp [cnt_succ, h i (Nat.lt_succ_self i), this]

/-- At-most bound of one column half, ALL branches of `at_most_k`
    (`k ≥ n`: no clauses, bound trivial; `k = 0`: forced-false units;
    `0 < k < n`: the Sinz core). -/
theorem col_le (hv : Sat E v) (side : Bool) {d : Nat} (hd : d < E.D) :
    cnt (xcol v side d) E.n ≤ bound E side d := by
  by_cases hkn : E.n ≤ bound E side d
  · exact Nat.le_trans (cnt_le _ E.n) hkn
  · rw [Nat.not_le] at hkn
    by_cases h0 : bound E side d = 0
    · have hall : ∀ t, t < E.n → xcol v side d t = false := by
        intro t ht
        have hu := clauseSat_one.mp (hv _ (IsClause.szZero side d t hd ht h0))
        unfold xcol
        rw [hu]
        cases side <;> rfl
      rw [cnt_zero_of_all_false hall]
      omega
    · exact sinz_le (sat_szX0 hv hd (by omega) hkn) (sat_szDiag hv hd (by omega) hkn)
        (sat_szChain hv hd (by omega) hkn) (sat_szCap hv hd (by omega) hkn)
        (by omega) hkn

/-- Both halves together: the positive column total EQUALS the budget. -/
theorem col_eq (hw : WF E) (hv : Sat E v) {d : Nat} (hd : d < E.D) :
    cnt (xcol v true d) E.n = E.b0 d := by
  have hle : cnt (xcol v true d) E.n ≤ E.b0 d := col_le hv true hd
  have hge : E.b0 d ≤ cnt (xcol v true d) E.n := by
    have h1 : cnt (xcol v false d) E.n ≤ E.n - E.b0 d := col_le hv false hd
    have h2 : cnt (xcol v false d) E.n = E.n - cnt (xcol v true d) E.n := by
      have hpt : cnt (xcol v false d) E.n =
          cnt (fun t => !(xcol v true d t)) E.n :=
        cnt_congr (fun t _ => xcol_not v d t)
      rw [hpt, cnt_not]
    have h3 := cnt_le (xcol v true d) E.n
    have h4 := hw.b0_le d hd
    omega
  omega

end Columns

/-! ### Leg (i): soundness — every model decodes to a valid walk -/

section Soundness
variable {E : Enc} {v : Model}

/-- One-hot decode: each slot carries exactly one true `Y`. -/
theorem decode_exists (hv : Sat E v) : ∃ σ, Decodes E v σ := by
  classical
  refine ⟨fun s => if h : s < E.n then Classical.choose (sat_slotAlo hv h) else 0,
    ?_, ?_, ?_⟩
  · intro s hs
    simp only [dif_pos hs]
    exact (Classical.choose_spec (sat_slotAlo hv hs)).1
  · intro s hs
    simp only [dif_pos hs]
    exact (Classical.choose_spec (sat_slotAlo hv hs)).2
  · intro s j hs hj hY
    simp only [dif_pos hs]
    apply Classical.byContradiction
    intro hne
    obtain ⟨hjm, hYc⟩ := Classical.choose_spec (sat_slotAlo hv hs)
    exact sat_slotAmo hv hs hj hjm (fun h => hne h) ⟨hY, hYc⟩

/-- Two decodes of the same model agree on all meaningful slots. -/
theorem decode_unique {σ₁ σ₂ : Nat → Nat} (h₁ : Decodes E v σ₁)
    (h₂ : Decodes E v σ₂) : ∀ s, s < E.n → σ₁ s = σ₂ s := by
  intro s hs
  exact h₂.uniq s (σ₁ s) hs (h₁.range s hs) (h₁.hit s hs)

theorem decode_pair_inj (hw : WF E) (hv : Sat E v) {σ : Nat → Nat}
    (hd : Decodes E v σ) : ∀ s₁ s₂, s₁ < E.n → s₂ < E.n →
      E.pairOf (σ s₁) = E.pairOf (σ s₂) → s₁ = s₂ := by
  intro s₁ s₂ hs₁ hs₂ hp
  apply Classical.byContradiction
  intro hne
  exact sat_pairAmo hv (hw.pair_lt _ (hd.range s₁ hs₁)) hs₁ (hd.range s₁ hs₁)
    hs₂ (hd.range s₂ hs₂) rfl hp.symm (fun h => hne h.1)
    ⟨hd.hit s₁ hs₁, hd.hit s₂ hs₂⟩

theorem decode_boundary_ok (hw : WF E) (hv : Sat E v) {σ : Nat → Nat}
    (hd : Decodes E v σ) : ∀ b, b < E.n → (bcls E σ b).isSome := by
  intro b hb
  cases b with
  | zero =>
      cases hcase : E.anchor (σ 0) with
      | none =>
          exfalso
          have hc := clauseSat_one.mp
            (hv _ (IsClause.anchorBlock (σ 0) hw.npos (hd.range 0 hw.npos) hcase))
          have := hd.hit 0 hw.npos
          simp_all
      | some d => simp [bcls, hcase]
  | succ b' =>
      have hb' : b' < E.n := by omega
      have hdp : E.pairOf (σ b') ≠ E.pairOf (σ (b' + 1)) := by
        intro h
        have := decode_pair_inj hw hv hd b' (b' + 1) hb' hb h
        omega
      cases hcase : E.step (σ b') (σ (b' + 1)) with
      | none =>
          exfalso
          have hc := clauseSat_two.mp (hv _ (IsClause.stepBlock b' (σ b') (σ (b' + 1))
            hb (hd.range b' hb') (hd.range (b' + 1) hb) hdp hcase))
          rcases hc with hc | hc
          · have := hd.hit b' hb'; simp_all
          · have := hd.hit (b' + 1) hb; simp_all
      | some d => simp [bcls, hcase]

/-- The class of every boundary is in range. -/
theorem bcls_lt (hw : WF E) {σ : Nat → Nat} {b d : Nat}
    (h : bcls E σ b = some d) : d < E.D := by
  cases b with
  | zero => exact hw.anchor_lt _ _ h
  | succ b' => exact hw.step_lt _ _ _ h

/-- T-indicator determination: the boundary clauses force the class indicator
    of the actual boundary true, and the per-boundary at-most-one kills the
    rest — so every `T` is pinned to `canonT`. -/
theorem T_det (hw : WF E) (hv : Sat E v) {σ : Nat → Nat} (hd : Decodes E v σ) :
    ∀ b dv, b < E.n → dv < E.D → v (V.T b dv) = canonT E σ b dv := by
  intro b dv hb hdv
  obtain ⟨dcls, hdcls⟩ := Option.isSome_iff_exists.mp (decode_boundary_ok hw hv hd b hb)
  have hdcls_lt : dcls < E.D := bcls_lt hw hdcls
  have hforced : v (V.T b dcls) = true := by
    cases b with
    | zero =>
        have hc := clauseSat_two.mp (hv _ (IsClause.anchorCls (σ 0) dcls hw.npos
          (hd.range 0 hw.npos) hdcls))
        rcases hc with hc | hc
        · have := hd.hit 0 hw.npos; simp_all
        · exact hc
    | succ b' =>
        have hb' : b' < E.n := by omega
        have hdp : E.pairOf (σ b') ≠ E.pairOf (σ (b' + 1)) := by
          intro h
          have := decode_pair_inj hw hv hd b' (b' + 1) hb' hb h
          omega
        have hc := clauseSat_three.mp (hv _ (IsClause.stepCls b' (σ b') (σ (b' + 1))
          dcls hb (hd.range b' hb') (hd.range (b' + 1) hb) hdp hdcls))
        rcases hc with hc | hc | hc
        · have := hd.hit b' hb'; simp_all
        · have := hd.hit (b' + 1) hb; simp_all
        · exact hc
  by_cases heq : dv = dcls
  · subst heq
    rw [hforced]
    unfold canonT
    rw [hdcls]
    simp
  · have hfalse : v (V.T b dv) = false := by
      cases hvb : v (V.T b dv) with
      | true => exact absurd ⟨hvb, hforced⟩ (sat_tAmo hv hb hdv hdcls_lt heq)
      | false => rfl
    rw [hfalse]
    unfold canonT
    rw [hdcls]
    have hne : ¬(some dcls = some dv) := fun hcontra => heq (Option.some.inj hcontra).symm
    simp [hne]

/-- The positive class column of a satisfying model IS the walk's class
    column (below `n`). -/
theorem xcol_eq_canonT (hw : WF E) (hv : Sat E v) {σ : Nat → Nat}
    (hd : Decodes E v σ) {dv : Nat} (hdv : dv < E.D) :
    ∀ b, b < E.n → xcol v true dv b = canonT E σ b dv := by
  intro b hb
  unfold xcol
  rw [T_det hw hv hd b dv hb hdv]
  cases canonT E σ b dv <;> rfl

theorem ccnt_eq (hw : WF E) (hv : Sat E v) {σ : Nat → Nat}
    (hd : Decodes E v σ) {dv : Nat} (hdv : dv < E.D) {i : Nat} (hi : i ≤ E.n) :
    cnt (xcol v true dv) i = ccnt E σ dv i :=
  cnt_congr (fun t ht => xcol_eq_canonT hw hv hd hdv t (by omega))

/-- **Leg (i), soundness.** Every satisfying assignment of the clause family
    decodes (one-hot, uniquely on slots) to a valid walk: pair-complete, no
    forbidden boundary, class budget met exactly. -/
theorem model_soundness (hw : WF E) (hv : Sat E v) :
    ∃ σ, Decodes E v σ ∧ ValidWalk E σ := by
  obtain ⟨σ, hd⟩ := decode_exists hv
  refine ⟨σ, hd, hd.range, decode_pair_inj hw hv hd, ?_, decode_boundary_ok hw hv hd, ?_⟩
  · -- pair-surjectivity, from the per-pair at-least-one clause
    intro p hp
    obtain ⟨s, j, hs, hj, hpj, hY⟩ := sat_pairAlo hv hp
    have := hd.uniq s j hs hj hY
    exact ⟨s, hs, by rw [← this]; exact hpj⟩
  · -- budget: both Sinz halves pin the column count to b0
    intro dv hdv
    have h1 := col_eq hw hv hdv
    have h2 := ccnt_eq hw hv hd hdv (Nat.le_refl E.n)
    show ccnt E σ dv E.n = E.b0 dv
    rw [← h2]
    exact h1

end Soundness

/-! ### Leg (ii): determinism and injectivity — a model is pinned by its walk -/

section Injectivity
variable {E : Enc} {v v₁ v₂ : Model}

theorem col_eq_false (hw : WF E) (hv : Sat E v) {dv : Nat} (hdv : dv < E.D) :
    cnt (xcol v false dv) E.n = E.n - E.b0 dv := by
  have hpt : cnt (xcol v false dv) E.n = cnt (fun t => !(xcol v true dv t)) E.n :=
    cnt_congr (fun t _ => xcol_not v dv t)
  rw [hpt, cnt_not, col_eq hw hv hdv]

/-- **Model determinism.** On every ALLOCATED variable, a satisfying
    assignment equals the canonical model of its decoded walk: `Y` is one-hot
    in `σ`, `T` is the boundary-class indicator, and both Sinz register
    arrays are pinned to the prefix-count semantics (`sinz_det` — this is
    where `exactly_k`'s two halves jointly kill the register freedom of a
    bare `at_most_k`). -/
theorem model_determinism (hw : WF E) (hv : Sat E v) {σ : Nat → Nat}
    (hd : Decodes E v σ) : ∀ w, Used E w → v w = canon E σ w := by
  intro w hw'
  cases w with
  | Y s j =>
      obtain ⟨hs, hj⟩ := hw'
      show v (V.Y s j) = decide (j = σ s)
      by_cases heq : j = σ s
      · subst heq
        simp [hd.hit s hs]
      · have hvy : v (V.Y s j) = false := by
          cases hvy : v (V.Y s j) with
          | true => exact absurd (hd.uniq s j hs hj hvy) heq
          | false => rfl
        simp [hvy, heq]
  | T b dv =>
      obtain ⟨hb, hdv⟩ := hw'
      exact T_det hw hv hd b dv hb hdv
  | A dv i j =>
      obtain ⟨hdv, h0, hkn, hi, hj⟩ := hw'
      have hbA : bound E true dv = E.b0 dv := rfl
      have htot : cnt (xcol v true dv) E.n = bound E true dv := by
        rw [hbA]; exact col_eq hw hv hdv
      have hdet := sinz_det (r := fun i j => v (reg true dv i j))
        (sat_szX0 hv hdv (by omega) (by omega))
        (sat_szDiag hv hdv (by omega) (by omega))
        (sat_szChain hv hdv (by omega) (by omega))
        (sat_szCap hv hdv (by omega) (by omega))
        (by omega) htot i hi j (by omega)
      have hcc := ccnt_eq hw hv hd hdv (show i + 1 ≤ E.n by omega)
      show v (V.A dv i j) = decide (j + 1 ≤ ccnt E σ dv (i + 1))
      have hreg : reg true dv i j = V.A dv i j := rfl
      rw [← hcc, ← hreg]
      exact hdet
  | B dv i j =>
      obtain ⟨hdv, h0, hkn, hi, hj⟩ := hw'
      have hbB : bound E false dv = E.n - E.b0 dv := rfl
      have htot : cnt (xcol v false dv) E.n = bound E false dv := by
        rw [hbB]; exact col_eq_false hw hv hdv
      have hdet := sinz_det (r := fun i j => v (reg false dv i j))
        (sat_szX0 hv hdv (by omega) (by omega))
        (sat_szDiag hv hdv (by omega) (by omega))
        (sat_szChain hv hdv (by omega) (by omega))
        (sat_szCap hv hdv (by omega) (by omega))
        (by omega) htot i hi j (by omega)
      have hneg : cnt (xcol v false dv) (i + 1) = (i + 1) - ccnt E σ dv (i + 1) := by
        have hpt : cnt (xcol v false dv) (i + 1) =
            cnt (fun t => !(xcol v true dv t)) (i + 1) :=
          cnt_congr (fun t _ => xcol_not v dv t)
        rw [hpt, cnt_not, ccnt_eq hw hv hd hdv (show i + 1 ≤ E.n by omega)]
      show v (V.B dv i j) = decide (j + 1 ≤ (i + 1) - ccnt E σ dv (i + 1))
      have hreg : reg false dv i j = V.B dv i j := rfl
      rw [← hneg, ← hreg]
      exact hdet

theorem bcls_congr {σ₁ σ₂ : Nat → Nat} (hagree : ∀ s, s < E.n → σ₁ s = σ₂ s)
    {b : Nat} (hb : b < E.n) : bcls E σ₁ b = bcls E σ₂ b := by
  cases b with
  | zero =>
      have h0 : 0 < E.n := hb
      simp [bcls, hagree 0 h0]
  | succ b' =>
      simp [bcls, hagree b' (by omega), hagree (b' + 1) hb]

theorem canon_congr {σ₁ σ₂ : Nat → Nat} (hagree : ∀ s, s < E.n → σ₁ s = σ₂ s) :
    ∀ w, Used E w → canon E σ₁ w = canon E σ₂ w := by
  have hT : ∀ b dv, b < E.n → canonT E σ₁ b dv = canonT E σ₂ b dv := by
    intro b dv hb
    unfold canonT
    rw [bcls_congr hagree hb]
  have hc : ∀ dv i, i ≤ E.n → ccnt E σ₁ dv i = ccnt E σ₂ dv i := by
    intro dv i hi
    exact cnt_congr (fun t ht => hT t dv (by omega))
  intro w hw'
  cases w with
  | Y s j =>
      obtain ⟨hs, _⟩ := hw'
      show decide (j = σ₁ s) = decide (j = σ₂ s)
      rw [hagree s hs]
  | T b dv =>
      obtain ⟨hb, _⟩ := hw'
      exact hT b dv hb
  | A dv i j =>
      obtain ⟨_, _, _, hi, _⟩ := hw'
      show decide (j + 1 ≤ ccnt E σ₁ dv (i + 1)) = decide (j + 1 ≤ ccnt E σ₂ dv (i + 1))
      rw [hc dv (i + 1) (by omega)]
  | B dv i j =>
      obtain ⟨_, _, _, hi, _⟩ := hw'
      show decide (j + 1 ≤ (i + 1) - ccnt E σ₁ dv (i + 1)) =
        decide (j + 1 ≤ (i + 1) - ccnt E σ₂ dv (i + 1))
      rw [hc dv (i + 1) (by omega)]

/-- **Leg (ii), injectivity.** Two satisfying assignments whose decoded walks
    agree (on the meaningful slots) agree on every allocated variable — the
    decode map is injective on models of the emitted variable set. -/
theorem model_injectivity (hw : WF E) (hv₁ : Sat E v₁) (hv₂ : Sat E v₂)
    {σ₁ σ₂ : Nat → Nat} (hd₁ : Decodes E v₁ σ₁) (hd₂ : Decodes E v₂ σ₂)
    (hagree : ∀ s, s < E.n → σ₁ s = σ₂ s) :
    ∀ w, Used E w → v₁ w = v₂ w := by
  intro w hu
  rw [model_determinism hw hv₁ hd₁ w hu, model_determinism hw hv₂ hd₂ w hu]
  exact canon_congr hagree w hu

end Injectivity

/-! ### Completeness: every valid walk has a (canonical) model -/

section Completeness
variable {E : Enc} {v : Model} {σ : Nat → Nat}

theorem beq_false_iff (a b : Bool) : ((a == b) = false) ↔ a = !b := by
  cases a <;> cases b <;> simp

theorem xcol_false_iff {side : Bool} {d i : Nat} :
    xcol v side d i = false ↔ v (V.T i d) = !side := by
  unfold xcol
  exact beq_false_iff _ _

theorem cnt_xcol_canon_true {d : Nat} :
    ∀ i, cnt (xcol (canon E σ) true d) i = ccnt E σ d i := by
  intro i
  exact cnt_congr (fun t _ => by
    show (canonT E σ t d == true) = canonT E σ t d
    cases canonT E σ t d <;> rfl)

theorem cnt_xcol_canon_false {d : Nat} :
    ∀ i, cnt (xcol (canon E σ) false d) i = i - ccnt E σ d i := by
  intro i
  have h1 : cnt (xcol (canon E σ) false d) i =
      cnt (fun t => !(canonT E σ t d)) i :=
    cnt_congr (fun t _ => by
      show (canonT E σ t d == false) = !(canonT E σ t d)
      cases canonT E σ t d <;> rfl)
  rw [h1, cnt_not]
  rfl

theorem canon_reg_eq (side : Bool) (d i j : Nat) :
    canon E σ (reg side d i j) =
      decide (j + 1 ≤ cnt (xcol (canon E σ) side d) (i + 1)) := by
  cases side
  · show decide (j + 1 ≤ (i + 1) - ccnt E σ d (i + 1)) = _
    rw [cnt_xcol_canon_false]
  · show decide (j + 1 ≤ ccnt E σ d (i + 1)) = _
    rw [cnt_xcol_canon_true]

theorem ccnt_budget (hvw : ValidWalk E σ) {d : Nat} (hd : d < E.D) :
    ccnt E σ d E.n = E.b0 d := by
  unfold ccnt canonT
  exact hvw.budget d hd

theorem canon_col_total (hvw : ValidWalk E σ) (side : Bool)
    {d : Nat} (hd : d < E.D) :
    cnt (xcol (canon E σ) side d) E.n = bound E side d := by
  cases side
  · rw [cnt_xcol_canon_false, ccnt_budget hvw hd]
    rfl
  · rw [cnt_xcol_canon_true, ccnt_budget hvw hd]
    rfl

/-- **Completeness.** The canonical model of a valid walk satisfies every
    clause of the family. Together with soundness and injectivity this makes
    decode a bijection (at the abstract level) between satisfying assignments
    of the allocated variables and valid walks. -/
theorem model_completeness (hw : WF E) (hvw : ValidWalk E σ) :
    Sat E (canon E σ) ∧ Decodes E (canon E σ) σ := by
  constructor
  · intro c hc
    cases hc with
    | slotAlo s hs =>
        refine ⟨(V.Y s (σ s), true), ?_, ?_⟩
        · exact List.mem_map.mpr ⟨σ s, List.mem_range.mpr (hvw.range s hs), rfl⟩
        · show canon E σ (V.Y s (σ s)) = true
          simp [canon]
    | slotAmo s j₁ j₂ hs hj₁ hj₂ hne =>
        rw [clauseSat_two]
        by_cases h₁ : j₁ = σ s
        · right
          show decide (j₂ = σ s) = false
          simp
          omega
        · left
          show decide (j₁ = σ s) = false
          simp [h₁]
    | pairAlo p hp =>
        obtain ⟨s, hs, hps⟩ := hvw.surj p hp
        refine ⟨(V.Y s (σ s), true), ?_, ?_⟩
        · refine List.mem_flatMap.mpr ⟨s, List.mem_range.mpr hs, ?_⟩
          refine List.mem_filterMap.mpr ⟨σ s, List.mem_range.mpr (hvw.range s hs), ?_⟩
          rw [if_pos hps]
        · show canon E σ (V.Y s (σ s)) = true
          simp [canon]
    | pairAmo p s₁ j₁ s₂ j₂ hp hs₁ hj₁ hs₂ hj₂ hp₁ hp₂ hne =>
        rw [clauseSat_two]
        by_cases h₁ : j₁ = σ s₁
        · by_cases h₂ : j₂ = σ s₂
          · exfalso
            subst h₁; subst h₂
            have heq : s₁ = s₂ :=
              hvw.inj s₁ s₂ hs₁ hs₂ (by rw [hp₁, hp₂])
            exact hne ⟨heq, by rw [heq]⟩
          · right
            show decide (j₂ = σ s₂) = false
            simp [h₂]
        · left
          show decide (j₁ = σ s₁) = false
          simp [h₁]
    | tAlo b hb =>
        obtain ⟨db, hdb⟩ := Option.isSome_iff_exists.mp (hvw.ok b hb)
        refine ⟨(V.T b db, true), ?_, ?_⟩
        · exact List.mem_map.mpr ⟨db, List.mem_range.mpr (bcls_lt hw hdb), rfl⟩
        · show canonT E σ b db = true
          simp [canonT, hdb]
    | tAmo b d₁ d₂ hb hd₁ hd₂ hne =>
        rw [clauseSat_two]
        by_cases h₁ : canonT E σ b d₁ = true
        · right
          show canonT E σ b d₂ = false
          simp only [canonT, decide_eq_true_eq] at h₁
          simp only [canonT, h₁, decide_eq_false_iff_not]
          intro hcontra
          exact hne (Option.some.inj hcontra)
        · left
          show canonT E σ b d₁ = false
          simpa using h₁
    | anchorBlock j hn hj hblk =>
        rw [clauseSat_one]
        show decide (j = σ 0) = false
        simp only [decide_eq_false_iff_not]
        intro heq
        have hok := hvw.ok 0 hn
        rw [show bcls E σ 0 = E.anchor (σ 0) from rfl, ← heq, hblk] at hok
        simp at hok
    | anchorCls j d hn hj hcl =>
        rw [clauseSat_two]
        by_cases heq : j = σ 0
        · right
          show canonT E σ 0 d = true
          subst heq
          unfold canonT
          have hb : bcls E σ 0 = some d := by
            show E.anchor (σ 0) = some d
            exact hcl
          rw [hb]
          simp
        · left
          show decide (j = σ 0) = false
          simp [heq]
    | stepBlock b j₁ j₂ hb hj₁ hj₂ hdp hblk =>
        rw [clauseSat_two]
        by_cases h₁ : j₁ = σ b
        · right
          show decide (j₂ = σ (b + 1)) = false
          simp only [decide_eq_false_iff_not]
          intro h₂
          have hok := hvw.ok (b + 1) hb
          rw [show bcls E σ (b + 1) = E.step (σ b) (σ (b + 1)) from rfl,
            ← h₁, ← h₂, hblk] at hok
          simp at hok
        · left
          show decide (j₁ = σ b) = false
          simp [h₁]
    | stepCls b j₁ j₂ d hb hj₁ hj₂ hdp hcl =>
        rw [clauseSat_three]
        by_cases h₁ : j₁ = σ b
        · by_cases h₂ : j₂ = σ (b + 1)
          · right; right
            show canonT E σ (b + 1) d = true
            unfold canonT
            have hb2 : bcls E σ (b + 1) = some d := by
              show E.step (σ b) (σ (b + 1)) = some d
              rw [← h₁, ← h₂]
              exact hcl
            rw [hb2]
            simp
          · right; left
            show decide (j₂ = σ (b + 1)) = false
            simp [h₂]
        · left
          show decide (j₁ = σ b) = false
          simp [h₁]
    | szZero side d i hd hi hk =>
        rw [clauseSat_one]
        show canon E σ (V.T i d) = !side
        cases side
        · -- at-least half at bound 0: b0 d = n, so every boundary is class d
          have hb0 : E.b0 d = E.n := by
            have hble := hw.b0_le d hd
            have hk' : E.n - E.b0 d = 0 := hk
            omega
          have hfull : ccnt E σ d E.n = E.n := by
            rw [ccnt_budget hvw hd, hb0]
          have hT : canonT E σ i d = true := all_true_of_cnt_full hfull i hi
          show canonT E σ i d = !false
          rw [hT]
          rfl
        · -- at-most half at bound 0: b0 d = 0, no boundary is class d
          have hb0 : E.b0 d = 0 := hk
          have hzero : ccnt E σ d E.n = 0 := by
            rw [ccnt_budget hvw hd, hb0]
          have hT : canonT E σ i d = false := all_false_of_cnt_zero hzero i hi
          show canonT E σ i d = !true
          rw [hT]
          rfl
    | szX0 side d i hd h0 hkn hi =>
        rw [clauseSat_two]
        by_cases hx : xcol (canon E σ) side d i = true
        · right
          rw [canon_reg_eq]
          exact can_x0 hx
        · left
          exact xcol_false_iff.mp (by simpa using hx)
    | szUnit0 side d j hd h0 hkn hj hjk =>
        rw [clauseSat_one]
        rw [canon_reg_eq]
        exact can_unit0 hj
    | szChain side d i j hd h0 hkn hi hjk =>
        rw [clauseSat_two]
        by_cases hr : canon E σ (reg side d i j) = true
        · right
          rw [canon_reg_eq]
          rw [canon_reg_eq] at hr
          exact can_chain hr
        · left
          simpa using hr
    | szDiag side d i j hd h0 hkn hi hjk =>
        rw [clauseSat_three]
        by_cases hx : xcol (canon E σ) side d (i + 1) = true
        · by_cases hr : canon E σ (reg side d i j) = true
          · right; right
            rw [canon_reg_eq]
            rw [canon_reg_eq] at hr
            exact can_diag hx hr
          · right; left
            simpa using hr
        · left
          exact xcol_false_iff.mp (by simpa using hx)
    | szCap side d i hd h0 hkn hi =>
        rw [clauseSat_two]
        by_cases hx : xcol (canon E σ) side d (i + 1) = true
        · right
          rw [canon_reg_eq]
          exact can_cap h0 hi (Nat.le_of_eq (canon_col_total hvw side hd)) hx
        · left
          exact xcol_false_iff.mp (by simpa using hx)
  · exact ⟨hvw.range,
      fun s hs => by show decide (σ s = σ s) = true; simp,
      fun s j hs hj hY => by
        show j = σ s
        have : decide (j = σ s) = true := hY
        simpa using this⟩

end Completeness

/-! ### Capstone: the abstract model↔walk bijection, in one statement -/

/-- Decode is a bijection between satisfying assignments (up to the allocated
    variables — the only ones a DIMACS model assigns) and valid walks:
    soundness (leg i), completeness, and injectivity (leg ii) packaged
    together. The B1 §5 three-leg argument needs only the first and third
    conjuncts; the second is strictly extra. All of this is about the
    ABSTRACT clause family — see the header SCOPE block for what is and is
    not claimed about the shipping encoder. -/
theorem decode_bijection {E : Enc} (hw : WF E) :
    (∀ v, Sat E v → ∃ σ, Decodes E v σ ∧ ValidWalk E σ) ∧
    (∀ σ, ValidWalk E σ → Sat E (canon E σ) ∧ Decodes E (canon E σ) σ) ∧
    (∀ v₁ v₂ σ₁ σ₂, Sat E v₁ → Sat E v₂ → Decodes E v₁ σ₁ → Decodes E v₂ σ₂ →
      (∀ s, s < E.n → σ₁ s = σ₂ s) → ∀ w, Used E w → v₁ w = v₂ w) :=
  ⟨fun _ hv => model_soundness hw hv,
   fun _ hvw => model_completeness hw hvw,
   fun _ _ _ _ hv₁ hv₂ hd₁ hd₂ hagree => model_injectivity hw hv₁ hv₂ hd₁ hd₂ hagree⟩

/-! ### Non-vacuity

A concrete instance (one pair, one orientation, one class, anchor allowed,
budget 1) with a satisfiable clause family and a valid walk — so nothing
above is a theorem about an empty model set or an empty walk set. -/

section NonVacuity

def E₀ : Enc :=
  { n := 1, m := 1, pairOf := fun _ => 0, D := 1,
    anchor := fun _ => some 0, step := fun _ _ => none, b0 := fun _ => 1 }

theorem WF_E₀ : WF E₀ := by
  refine ⟨Nat.zero_lt_one, ?_, ?_, ?_, ?_⟩
  · intro j _; exact Nat.zero_lt_one
  · intro j d h
    simp only [E₀] at h
    cases h
    exact Nat.zero_lt_one
  · intro j₁ j₂ d h
    simp [E₀] at h
  · intro d _; exact Nat.le_refl 1

theorem ValidWalk_E₀ : ValidWalk E₀ (fun _ => 0) := by
  have hn : E₀.n = 1 := rfl
  have hm : E₀.m = 1 := rfl
  have hD : E₀.D = 1 := rfl
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro s hs
    omega
  · intro s₁ s₂ hs₁ hs₂ _
    omega
  · intro p hp
    refine ⟨0, by omega, ?_⟩
    have hp0 : E₀.pairOf 0 = 0 := rfl
    omega
  · intro b hb
    have hb0 : b = 0 := by omega
    subst hb0
    rfl
  · intro d hd
    have hd0 : d = 0 := by omega
    subst hd0
    rfl

theorem nonvacuity : ∃ (E : Enc) (v : Model) (σ : Nat → Nat),
    WF E ∧ Sat E v ∧ Decodes E v σ ∧ ValidWalk E σ := by
  obtain ⟨hsat, hdec⟩ := model_completeness WF_E₀ ValidWalk_E₀
  exact ⟨E₀, canon E₀ (fun _ => 0), fun _ => 0, WF_E₀, hsat, hdec, ValidWalk_E₀⟩

end NonVacuity

end SatEncodingFidelity

/-
  Axiom audit (house convention): every top-level theorem below must report
  a subset of [propext, Classical.choice, Quot.sound] — kernel-only, no
  `Lean.ofReduceBool` (which would indicate a load-bearing `native_decide`;
  there is none in this file).
  (On leanprover/lean4:v4.31.0 a `native_decide` proof instead surfaces under `#print axioms` as an
  auxiliary axiom named `<decl>._native.native_decide.ax_*`, NOT as `Lean.ofReduceBool` — measured
  2026-09-04. So the ABSENCE of `Lean.ofReduceBool` is not a sufficient tell; the sound check is the
  ALLOWLIST: any axiom token outside [propext, Classical.choice, Quot.sound] fails the audit.)
-/
#print axioms SatEncodingFidelity.model_soundness
#print axioms SatEncodingFidelity.model_determinism
#print axioms SatEncodingFidelity.model_injectivity
#print axioms SatEncodingFidelity.model_completeness
#print axioms SatEncodingFidelity.decode_bijection
#print axioms SatEncodingFidelity.sinz_det
#print axioms SatEncodingFidelity.nonvacuity
