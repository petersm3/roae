-- https://github.com/petersm3/roae
-- Developed with AI assistance (Claude, Anthropic)
/-
  PruneReprFC.lean — machine-checked prune safety of the SOLVE_REPR_FC
  forward-checked repr(k) DFS (task #20 option C, 2026-08-13, branch
  v4-repr-fc-legc-20260813 — NOT on main at the time of writing).
  Core Lean 4 only (no mathlib). Standalone: `lean PruneReprFC.lean`
  (verified 2026-08-15, Lean 4.31.0 pinned via ./lean-toolchain: exit 0,
  ~1.5 s wall / ~0.49 GB peak RSS on the 2-core orchestrator; zero
  `sorry`/`axiom`/`admit`, zero `native_decide` — the in-file
  `#print axioms` directives execute on every build and report
  ⊆ [propext, Classical.choice, Quot.sound], Lean's standard axioms).

  THE CLAIM BEING CHECKED. solve.c's repr(k) forward-checked DFS
  (`orb_recanon_dfs_fc`; the comment block "repr(k) forward-checked DFS")
  asserts that the two prunes it adds to the unpruned `orb_recanon_dfs`
  walk —

    A. the exact-consumption forward check on the per-class C5 budget
       (`orb_fc_build`'s wd/minbnd/maxbnd suffix tables), and
    C. memoization of proven-leaf-free (slot, tail, budget) states
       (`orb_fc_memo_key`/`_ep`: per-thread, epoch-tagged, collisions
       drop entries, epoch wrap clears the table)

  — remove ONLY subtrees containing NO LEAVES AT ALL, where a LEAF is a
  node at slot np reached through the budget-consumption edges, VALID OR
  NOT (the C3 test at the leaf is not consulted). Hence they cannot
  change which valid leaf a first-found DFS in fixed child order returns:
  repr(k) is preserved bit-identically and SOLVE_REPR_FC=0/1 agree. This
  file machine-checks that argument at the MODEL level, and machine-checks
  why the documented composition hazard (the evaluated-and-REJECTED
  C3-lower-bound prune) is a genuine trap, not proof-side caution.

  What is machine-checked here (model level):
  · §1 `leavesPr_eq` / `prune_first_leaf_exact` — THE HEART, stated
    abstractly for reuse: for a DFS over a finitely-branching, depth-
    indexed tree (children in a fixed order; structurally absent edges
    allowed), pruning children whose subtrees provably contain no leaves
    leaves the ENTIRE ordered leaf stream unchanged — a fortiori the
    first leaf satisfying any predicate, i.e. the returned repr. Also
    `dfs_eq_find?`: the operational first-found early-exit DFS equals
    `find?` over the leaf stream (operational = denotational).
  · §2 `fcCheck_leaf_free` — prune A is leaf-free-SOUND, not heuristic:
    in the budgeted instantiation (each edge consumes a per-class cost
    vector, taken iff it fits the remaining budget pointwise), if for
    some class d the remaining budget lies outside
    [lo(n,d), hi(n,d)] = [Σ suffix mins, Σ suffix maxes] of the per-edge
    class-consumption bounds, AND the budget's total equals the total any
    complete path must consume (exact consumption), then NO leaf exists
    below: any feasible completion's cost vector would be pointwise ≤ the
    budget with equal sum, hence EQUAL to it (`eq_on_of_le_sum_eq` — the
    same le+eqsum⇒eq crux as PruneExactness.lean's F-53), hence inside
    the interval — contradiction. The suffix tables lo/hi are DERIVED
    from per-edge bounds by the same recurrence `orb_fc_build` computes
    (`acc`), not assumed wholesale.
  · §3 `dfsM_spec` / `dfsM_eq_unpruned` — prune C is sound given the
    above: the memo-threaded first-found DFS `dfsM` (probe before
    descending; insert a child's key only when its completed subtree
    search reached ZERO leaves; any prune-A predicate that is leaf-free-
    sound may run inside) returns EXACTLY the unpruned search's first
    valid leaf, starting from any memo whose claims are all true (in
    particular an empty/fresh-epoch one). The proof threads the honest
    invariant — every claimed (depth, key) is leaf-free in the UNPRUNED
    tree — through insertion (a zero leaf count under leaf-free-sound
    pruning certifies unpruned leaf-freeness: this is the step a cd
    prune would destroy) and through probe hits. Memo keys are a
    PROJECTION π of the state (solve.c: (slot, tail, budget), while
    leaf VALIDITY needs the whole placed sequence); the projection
    hypothesis `hproj` — leaf-EXISTENCE structure factors through π —
    is exactly what licenses one prefix's leaf-freeness to be reused by
    another (`leaves_nil_congr`). "A recorded state stays leaf-free" is
    purity: `leaves` is a function of (depth, state) alone. Collisions
    and epochs: the abstract `MemoSpec` allows insertion to DROP any
    entries (its spec is one-directional), and §3b's epoch-tagged table
    model proves (i) arbitrary-position overwrite — i.e. ANY hash/probe
    collision policy, including dropping the new entry — satisfies the
    spec, and (ii) a bumped epoch claims NOTHING when all stored tags
    are ≤ the old epoch (`etBump_claims_empty`): stale positives cannot
    resurrect. (In solve.c the tag is a uint32; the wrap that would
    break tag-boundedness is exactly the case the code clears the table
    on. That arithmetic is bridge-level, see B9.)
  · §4 `fc_memo_first_leaf_exact` — THE CONCLUSION: composing §2's
    predicate as prune A inside §3's memoized DFS over the budgeted
    tree, the FC-enabled search and the unpruned search return the same
    leaf. With bridge fact B6 (RecordConvention.lean §3: unpruned
    0-before-1 first-found = the lex-min valid completion), this is the
    C comment's "preserve repr(k) BIT-IDENTICALLY". Witnesses against
    vacuous hypotheses: `listMemo` (the trivial table satisfies
    `MemoSpec`), `epochMemo` (the epoch table does), `liftSpend_proj`
    (a spend that reads only the running tail — the C shape, where the
    placed sequence is payload — satisfies `hproj` automatically).
  · §5 the COMPOSITION HAZARD, machine-checked as a counterexample
    (the crux-as-counterexample pattern of RecordConvention.lean):
    a concrete prune that is answer-sound ALONE (it cuts only subtrees
    with no VALID leaves, and `find?` over its pruned stream provably
    equals the unpruned answer) but is not leaf-free-sound. Composed
    with the memo it poisons an entry and the search MISSES the valid
    leaf: dfsM returns none where the unpruned answer exists. So the
    leaf-free property really is the invariant the memo must store —
    hypothesis hA of §3 is load-bearing, not proof convenience.

  EXPLICIT HYPOTHESES — assumed, not proved (each is a named hypothesis
  of the theorems, never silent):
  · h-edge bounds (`hb` of §2/§4): every edge at depth n consumes, per
    class d, between mn(n,d) and mx(n,d). C side: the within-pair class
    is fixed per slot and the boundary class lies in orb_fc_build's
    4-orientation support set `sup` (nsup==1 forces it) — a superset of
    the classes available at any actual predecessor tail, which is what
    makes maxbnd an upper and minbnd a lower bound. NOT re-derived from
    the pair-table arithmetic here.
  · h-edge sum (`hκ` of §2/§4): every edge's cost vector sums to κ over
    the class list (C: κ = 2 — one boundary + one within-pair transition
    per slot, classes 0..6 distinct).
  · exact consumption at the checked state: `fcCheck` CONJOINS the guard
    sumv(budget) = κ·n. solve.c omits the guard because it holds at
    every reachable state (budget0 is the exact C5 distribution; each
    step consumes total κ — the step case is machine-checked here as
    `sumv_sub_of_vle`, the root case is bridge). The model predicate
    therefore agrees with the C predicate on reachable states and is
    sound on ALL states.
  · `hproj` (§3): leaf-existence structure factors through the memo key
    projection. Discharged for the path-blind spend shape by
    `liftSpend_proj`; that solve.c's spend IS path-blind (transition
    arithmetic reads only slot, key, tail; seq[] is payload) is B8.
  · `MemoSpec` obligations (§3): a positive probe only on a claimed key;
    insertion claims at most its own key. Discharged for the model
    tables (`listMemo`, `epochMemo`); that solve.c's table satisfies
    them is B9 (full 64-bit key compare + epoch-tag compare + pack
    injectivity + wrap clear).
  · `hm₀` (§3/§4): the starting memo claims nothing (C: fresh epoch —
    §3b's `etBump_claims_empty` is the model fact, B9 the bridge).

  Bridge facts (stated, NOT machine-checked — the PartitionInvariance
  B1–B4 / RecordConvention B5–B7 pattern, numbering continued; carried
  by prose, code review, and the runtime gates — --orbit-selftest's
  brute-force repr cross-check and the SOLVE_REPR_FC=0/1 A/B):
  · B8 (DFS shape): orb_recanon_dfs_fc implements §3's dfsM over §2's
    budgeted tree: choices = orientation O ∈ {0,1} in that order;
    step = bstep with spend from the pair table (bd = hamming(tail, f),
    edge absent iff bd == 5, wd = hamming(f, s), cost = e_bd + e_wd);
    depth n = np − slot; P = the C3 leaf test on the completed seq;
    leaf counter `*leaves` = §3's k; insert condition *leaves == lv0 =
    k = 0; and spend is path-blind (seq[] payload) so π = (depth-as-
    slot, tail, budget) satisfies hproj via liftSpend_proj's shape.
  · B9 (memo table): orb_fc_probe/orb_fc_insert satisfy MemoSpec with
    claims = "this exact packed key was inserted in the current epoch":
    probe compares the full 64-bit key AND the epoch tag; orb_fc_pack
    is injective on the reachable domain (slot ≤ 32, tail < 64, each
    budget entry ≤ 63 — 6-bit fields); collision overwrite/drop only
    shrinks claims (§3b model); uint32 epoch wrap is cleared by the
    explicit memset, restoring §3b's tag-boundedness.
  · B10 (FC tables): orb_fc_build's wd_suffix + minbnd_suffix /
    wd_suffix + maxbnd_suffix equal §2's acc mn / acc mx for per-edge
    bounds mn/mx satisfying hb, and budget[] at the check site sums to
    2·(remaining slots) (C5 exact distribution + the just-consumed
    bd/wd decrements).
  · B11 (top level): orb_repr_global's slot-0 preamble, the
    fc.impossible early return (0 — the baseline also finds no
    completion), epoch increment per call, and per-thread table
    isolation preserve the correspondence at the call boundary.

  SCOPE — read this before citing (model-level result). What is
  machine-proven is the abstract statement: leaf-free-sound pruning and
  leaf-free memoization preserve the first-found leaf of the model DFS.
  The connection to the shipped C binary runs through B8–B11 above —
  explicit modeling assumptions that are NOT machine-checked; they are
  carried by prose, code review, and the runtime gates (--orbit-selftest
  against orb_brute_repr; the SOLVE_REPR_FC=0/1 byte-identity A/B).
  Nothing here proves solve.c or the FC implementation correct. The
  lex-min reading of the returned leaf (why "first found" = repr(k)) is
  RecordConvention.lean §3 (`dfsFirst_min`) via bridge fact B6, composed
  in prose — deliberately not re-proved here.

  Attribution: the arguments are elementary and standard — invariance of
  exhaustive search under deletion of provably-empty subtrees, and
  failure memoization as in transposition/no-good tables (cf. memoized
  backtracking; the soundness condition "record only proofs, and only
  facts of the memo key" is folklore in that literature). No novelty is
  claimed for the mathematics; only this machine-checked packaging and
  the counterexample packaging of the composition hazard are ours (to
  our knowledge; corrections welcome). Developed with AI assistance
  (Claude, Anthropic); prose companion: the solve.c comment block and
  roae-private/FABLE_REPR_HEAVY_TAIL_20260813.md.
-/

namespace PruneReprFC

/-! ### §0 Plumbing (hand-rolled, stable-core API only) -/

/-- a Bool that is not true is false. -/
theorem bool_eq_false {b : Bool} (h : ¬ b = true) : b = false := by
  cases b
  · rfl
  · exact absurd rfl h

/-- `find?` distributes over append: first hit in the left list wins. -/
theorem find?_append {α : Type} (p : α → Bool) :
    ∀ l₁ l₂ : List α, (l₁ ++ l₂).find? p =
      match l₁.find? p with
      | some x => some x
      | none => l₂.find? p := by
  intro l₁ l₂
  induction l₁ with
  | nil => rfl
  | cons a t ih =>
      cases hpa : p a with
      | true => simp only [List.cons_append, List.find?, hpa]
      | false => simp only [List.cons_append, List.find?, hpa]; exact ih

/-- append is nil iff both parts are. -/
theorem append_eq_nil' {α : Type} {l₁ l₂ : List α} (h : l₁ ++ l₂ = []) :
    l₁ = [] ∧ l₂ = [] := by
  cases l₁ with
  | nil => exact ⟨rfl, h⟩
  | cons a t => simp at h

/-- membership in a `List.set` result: the old list or the new entry. -/
theorem mem_set_cases {α : Type} {a b : α} :
    ∀ (l : List α) (i : Nat), a ∈ l.set i b → a ∈ l ∨ a = b := by
  intro l
  induction l with
  | nil => intro i h; cases h
  | cons x t ih =>
      intro i h
      cases i with
      | zero =>
          rcases List.mem_cons.mp h with rfl | hmem
          · exact Or.inr rfl
          · exact Or.inl (List.mem_cons_of_mem _ hmem)
      | succ i =>
          rcases List.mem_cons.mp h with rfl | hmem
          · exact Or.inl (List.mem_cons_self ..)
          · rcases ih i hmem with h1 | h2
            · exact Or.inl (List.mem_cons_of_mem _ h1)
            · exact Or.inr h2

/-! ### §1 The abstract search tree, its leaf stream, and prune safety

    Model: a depth-indexed, finitely-branching tree. A node with `n + 1`
    slots remaining expands across a FIXED ordered choice list; the edge
    for choice `c` is `step (n + 1) s c` (`none` = structurally absent —
    solve.c: bd == 5 or a budget class exhausted). A node with 0 slots
    remaining is a LEAF regardless of any validity test — this is the
    load-bearing modeling decision: `leaves` counts exactly what
    orb_recanon_dfs_fc's `(*leaves)++` counts. -/

/-- One node expansion: the children of `s` (a node with `n + 1` slots
    remaining) across a choice list, each child processed by `f`;
    absent edges contribute nothing. -/
def expandKids {S C : Type} (step : Nat → S → C → Option S)
    (f : S → List S) (n : Nat) (s : S) : List C → List S
  | [] => []
  | c :: cs =>
      (match step (n + 1) s c with
       | none => []
       | some s' => f s') ++ expandKids step f n s cs

/-- The UNPRUNED ordered leaf stream below state `s` with `n` slots
    remaining (solve.c: n = np − slot). -/
def leaves {S C : Type} (choices : List C) (step : Nat → S → C → Option S) :
    Nat → S → List S
  | 0, s => [s]
  | n + 1, s => expandKids step (fun t => leaves choices step n t) n s choices

/-- The leaf stream with a PURE prune predicate consulted at each child
    (`prune n t` = cut the subtree of child `t` with `n` slots remaining,
    before descending). -/
def leavesPr {S C : Type} (choices : List C) (step : Nat → S → C → Option S)
    (prune : Nat → S → Bool) : Nat → S → List S
  | 0, s => [s]
  | n + 1, s =>
      expandKids step
        (fun t => if prune n t then [] else leavesPr choices step prune n t)
        n s choices

theorem expandKids_cons_none {S C : Type} {step : Nat → S → C → Option S}
    {f : S → List S} {n : Nat} {s : S} {c : C} {cs : List C}
    (hst : step (n + 1) s c = none) :
    expandKids step f n s (c :: cs) = expandKids step f n s cs := by
  simp only [expandKids, hst, List.nil_append]

theorem expandKids_cons_some {S C : Type} {step : Nat → S → C → Option S}
    {f : S → List S} {n : Nat} {s : S} {c : C} {cs : List C} {s' : S}
    (hst : step (n + 1) s c = some s') :
    expandKids step f n s (c :: cs) = f s' ++ expandKids step f n s cs := by
  simp only [expandKids, hst]

/-- expandKids congruence in the child processor. -/
theorem expandKids_congr {S C : Type} (step : Nat → S → C → Option S)
    (f g : S → List S) (n : Nat) (s : S) (h : ∀ t, f t = g t) :
    ∀ cs : List C, expandKids step f n s cs = expandKids step g n s cs := by
  intro cs
  induction cs with
  | nil => rfl
  | cons c cs ih =>
      cases hst : step (n + 1) s c with
      | none =>
          rw [expandKids_cons_none (f := f) hst,
              expandKids_cons_none (f := g) hst, ih]
      | some s' =>
          rw [expandKids_cons_some (f := f) hst,
              expandKids_cons_some (f := g) hst, h s', ih]

/-- expandKids is nil when every present child processes to nil. -/
theorem expandKids_nil_of {S C : Type} (step : Nat → S → C → Option S)
    (f : S → List S) (n : Nat) (s : S) :
    ∀ cs : List C,
      (∀ c ∈ cs, ∀ s', step (n + 1) s c = some s' → f s' = []) →
      expandKids step f n s cs = [] := by
  intro cs
  induction cs with
  | nil => intro _; rfl
  | cons c cs ih =>
      intro h
      cases hst : step (n + 1) s c with
      | none =>
          rw [expandKids_cons_none hst]
          exact ih (fun c hc => h c (List.mem_cons_of_mem _ hc))
      | some s' =>
          rw [expandKids_cons_some hst, h c (List.mem_cons_self ..) s' hst,
              ih (fun c hc => h c (List.mem_cons_of_mem _ hc))]
          rfl

/-- ...and conversely, a nil expansion means every present child
    processed to nil. -/
theorem nil_of_expandKids_nil {S C : Type} (step : Nat → S → C → Option S)
    (f : S → List S) (n : Nat) (s : S) :
    ∀ cs : List C, expandKids step f n s cs = [] →
      ∀ c ∈ cs, ∀ s', step (n + 1) s c = some s' → f s' = [] := by
  intro cs
  induction cs with
  | nil => intro _ c hc; cases hc
  | cons c cs ih =>
      intro h c₀ hc₀ s' hst
      rcases List.mem_cons.mp hc₀ with rfl | hmem
      · rw [expandKids_cons_some hst] at h
        exact (append_eq_nil' h).1
      · cases hstc : step (n + 1) s c with
        | none =>
            rw [expandKids_cons_none hstc] at h
            exact ih h c₀ hmem s' hst
        | some t' =>
            rw [expandKids_cons_some hstc] at h
            exact ih (append_eq_nil' h).2 c₀ hmem s' hst

/-- ITEM 1, strong form: a prune that fires only on provably LEAF-FREE
    subtrees leaves the ENTIRE ordered leaf stream unchanged — not
    merely the same leaf set: the same leaves in the same order. -/
theorem leavesPr_eq {S C : Type} (choices : List C)
    (step : Nat → S → C → Option S) (prune : Nat → S → Bool)
    (hA : ∀ (k : Nat) (t : S), prune k t = true →
      leaves choices step k t = []) :
    ∀ (n : Nat) (s : S),
      leavesPr choices step prune n s = leaves choices step n s := by
  intro n
  induction n with
  | zero => intro s; rfl
  | succ n ih =>
      intro s
      show expandKids step
          (fun t => if prune n t then [] else leavesPr choices step prune n t)
          n s choices
        = expandKids step (fun t => leaves choices step n t) n s choices
      refine expandKids_congr step _ _ n s (fun t => ?_) choices
      cases hpr : prune n t with
      | true =>
          rw [if_pos rfl]
          exact (hA n t hpr).symm
      | false =>
          rw [if_neg (by decide)]
          exact ih t

/-- ITEM 1, headline form: leaf-free-sound pruning does not change the
    first leaf satisfying ANY predicate — in particular not the returned
    repr. (Abstract and reusable: any state/choice types, any depth,
    any leaf test.) -/
theorem prune_first_leaf_exact {S C : Type} (choices : List C)
    (step : Nat → S → C → Option S) (prune : Nat → S → Bool) (P : S → Bool)
    (hA : ∀ (k : Nat) (t : S), prune k t = true →
      leaves choices step k t = []) (n : Nat) (s : S) :
    (leavesPr choices step prune n s).find? P =
      (leaves choices step n s).find? P := by
  rw [leavesPr_eq choices step prune hA]

/-- The operational first-found DFS (early exit on the first valid leaf),
    child handler form. -/
def firstKids {S C : Type} (step : Nat → S → C → Option S)
    (f : S → Option S) (n : Nat) (s : S) : List C → Option S
  | [] => none
  | c :: cs =>
      match step (n + 1) s c with
      | none => firstKids step f n s cs
      | some s' =>
          match f s' with
          | some x => some x
          | none => firstKids step f n s cs

/-- The unpruned first-found DFS: the model of orb_recanon_dfs (with
    SOLVE_REPR_FC=0), returning the first leaf satisfying `P` in fixed
    child order. -/
def dfs {S C : Type} (choices : List C) (step : Nat → S → C → Option S)
    (P : S → Bool) : Nat → S → Option S
  | 0, s => if P s then some s else none
  | n + 1, s => firstKids step (fun t => dfs choices step P n t) n s choices

theorem firstKids_cons_none {S C : Type} {step : Nat → S → C → Option S}
    {f : S → Option S} {n : Nat} {s : S} {c : C} {cs : List C}
    (hst : step (n + 1) s c = none) :
    firstKids step f n s (c :: cs) = firstKids step f n s cs := by
  simp only [firstKids, hst]

theorem firstKids_cons_found {S C : Type} {step : Nat → S → C → Option S}
    {f : S → Option S} {n : Nat} {s : S} {c : C} {cs : List C} {s' x : S}
    (hst : step (n + 1) s c = some s') (hf : f s' = some x) :
    firstKids step f n s (c :: cs) = some x := by
  simp only [firstKids, hst, hf]

theorem firstKids_cons_next {S C : Type} {step : Nat → S → C → Option S}
    {f : S → Option S} {n : Nat} {s : S} {c : C} {cs : List C} {s' : S}
    (hst : step (n + 1) s c = some s') (hf : f s' = none) :
    firstKids step f n s (c :: cs) = firstKids step f n s cs := by
  simp only [firstKids, hst, hf]

theorem firstKids_eq {S C : Type} (step : Nat → S → C → Option S)
    (P : S → Bool) (f : S → Option S) (g : S → List S) (n : Nat) (s : S)
    (h : ∀ t, f t = (g t).find? P) :
    ∀ cs : List C,
      firstKids step f n s cs = (expandKids step g n s cs).find? P := by
  intro cs
  induction cs with
  | nil => rfl
  | cons c cs ih =>
      cases hst : step (n + 1) s c with
      | none => rw [firstKids_cons_none hst, expandKids_cons_none hst]; exact ih
      | some s' =>
          rw [expandKids_cons_some hst, find?_append]
          cases hf : f s' with
          | some x =>
              rw [firstKids_cons_found hst hf]
              have hg : (g s').find? P = some x := by rw [← h s', hf]
              rw [hg]
          | none =>
              rw [firstKids_cons_next hst hf]
              have hg : (g s').find? P = none := by rw [← h s', hf]
              rw [hg]
              exact ih

/-- Operational = denotational: the first-found DFS returns exactly
    `find? P` over the ordered leaf stream. -/
theorem dfs_eq_find? {S C : Type} (choices : List C)
    (step : Nat → S → C → Option S) (P : S → Bool) :
    ∀ (n : Nat) (s : S),
      dfs choices step P n s = (leaves choices step n s).find? P := by
  intro n
  induction n with
  | zero =>
      intro s
      show (if P s then some s else none) = List.find? P [s]
      by_cases hP : P s = true
      · rw [if_pos hP]
        simp only [List.find?, hP]
      · rw [if_neg hP]
        simp only [List.find?, bool_eq_false hP]
  | succ n ih =>
      intro s
      exact firstKids_eq step P _ _ n s ih choices

/-! ### §2 The budgeted (exact-consumption) instantiation and prune A

    States are (remaining budget, position): the budget is a per-class
    Nat vector over an abstract class list `ds` (solve.c: the 7 distance
    classes), the position is abstract (solve.c: slot key context, tail,
    AND the placed sequence — the position may carry the whole path; §2
    never inspects it). Each structurally-present edge carries a cost
    vector (solve.c: e_bd + e_wd) and is taken iff the cost fits the
    remaining budget pointwise; taking it subtracts the cost. -/

/-- total of a class vector over the class list. -/
def sumv {D : Type} (ds : List D) (v : D → Nat) : Nat := (ds.map v).sum

theorem sumv_cons {D : Type} (ds : List D) (d : D) (v : D → Nat) :
    sumv (d :: ds) v = v d + sumv ds v := by
  simp [sumv]

theorem sumv_zero {D : Type} (ds : List D) : sumv ds (fun _ => 0) = 0 := by
  induction ds with
  | nil => rfl
  | cons d t ih => rw [sumv_cons, ih]

theorem sumv_add {D : Type} (ds : List D) (v w : D → Nat) :
    sumv ds (fun d => v d + w d) = sumv ds v + sumv ds w := by
  induction ds with
  | nil => rfl
  | cons d t ih => rw [sumv_cons, sumv_cons, sumv_cons, ih]; omega

theorem sumv_mono {D : Type} (ds : List D) (v b : D → Nat)
    (h : ∀ d ∈ ds, v d ≤ b d) : sumv ds v ≤ sumv ds b := by
  induction ds with
  | nil => exact Nat.le_refl _
  | cons d t ih =>
      have h1 := h d (List.mem_cons_self ..)
      have h2 := ih (fun x hx => h x (List.mem_cons_of_mem _ hx))
      rw [sumv_cons, sumv_cons]
      omega

/-- THE CRUX (the le+eqsum⇒eq collapse, as in PruneExactness's F-53):
    pointwise ≤ on the class list plus equal totals forces pointwise
    equality — "fits the budget" plus "exact consumption" leaves no
    slack anywhere. Duplicates in `ds` are harmless. -/
theorem eq_on_of_le_sum_eq {D : Type} (ds : List D) (v b : D → Nat)
    (hle : ∀ d ∈ ds, v d ≤ b d) (hsum : sumv ds v = sumv ds b) :
    ∀ d ∈ ds, v d = b d := by
  induction ds with
  | nil => intro d hd; cases hd
  | cons d t ih =>
      have h1 := hle d (List.mem_cons_self ..)
      have ht : ∀ x ∈ t, v x ≤ b x :=
        fun x hx => hle x (List.mem_cons_of_mem _ hx)
      have h2 := sumv_mono t v b ht
      rw [sumv_cons, sumv_cons] at hsum
      intro x hx
      rcases List.mem_cons.mp hx with rfl | hxt
      · omega
      · exact ih ht (by omega) x hxt

/-- pointwise "fits the budget" test (Bool; over the class list). -/
def vleB {D : Type} (ds : List D) (v b : D → Nat) : Bool :=
  ds.all fun d => decide (v d ≤ b d)

theorem vleB_iff {D : Type} {ds : List D} {v b : D → Nat} :
    vleB ds v b = true ↔ ∀ d ∈ ds, v d ≤ b d := by
  simp [vleB, List.all_eq_true]

theorem vleB_zero {D : Type} (ds : List D) (b : D → Nat) :
    vleB ds (fun _ => 0) b = true :=
  vleB_iff.mpr fun _ _ => Nat.zero_le _

/-- The budget-consuming step: solve.c's per-orientation transition —
    edge structurally present iff `spend` yields a cost (bd ≠ 5), taken
    iff the cost fits pointwise (the budget[bd] > 0 / budget[wd] > 0
    checks), consuming it (the decrements). -/
def bstep {C D Pos : Type} (ds : List D)
    (spend : Nat → Pos → C → Option ((D → Nat) × Pos)) :
    Nat → ((D → Nat) × Pos) → C → Option ((D → Nat) × Pos) :=
  fun n bp c =>
    match spend n bp.2 c with
    | none => none
    | some kp =>
        if vleB ds kp.1 bp.1 then some (fun d => bp.1 d - kp.1 d, kp.2)
        else none

/-- All complete-path cost vectors below a position, budget IGNORED
    (child handler form). -/
def costsKids {C D Pos : Type}
    (spend : Nat → Pos → C → Option ((D → Nat) × Pos))
    (f : Pos → List (D → Nat)) (n : Nat) (p : Pos) :
    List C → List (D → Nat)
  | [] => []
  | c :: cs =>
      (match spend (n + 1) p c with
       | none => []
       | some kp => (f kp.2).map fun v => fun d => kp.1 d + v d) ++
      costsKids spend f n p cs

/-- All complete-path cost vectors from position `p` with `n` slots
    remaining, budget ignored: the consumption demands of every
    structurally possible completion. -/
def costs {C D Pos : Type} (choices : List C)
    (spend : Nat → Pos → C → Option ((D → Nat) × Pos)) :
    Nat → Pos → List (D → Nat)
  | 0, _ => [fun _ => 0]
  | n + 1, p => costsKids spend (fun q => costs choices spend n q) n p choices

theorem mem_costsKids {C D Pos : Type}
    (spend : Nat → Pos → C → Option ((D → Nat) × Pos))
    (f : Pos → List (D → Nat)) (n : Nat) (p : Pos) :
    ∀ cs : List C, ∀ c ∈ cs, ∀ (k : D → Nat) (p' : Pos),
      spend (n + 1) p c = some (k, p') →
      ∀ v ∈ f p', (fun d => k d + v d) ∈ costsKids spend f n p cs := by
  intro cs
  induction cs with
  | nil => intro c hc; cases hc
  | cons c₀ cs ih =>
      intro c hc k p' hsp v hv
      rcases List.mem_cons.mp hc with rfl | hmem
      · have hin : (fun d => k d + v d) ∈
            ((match spend (n + 1) p c with
             | none => []
             | some kp =>
                 (f kp.2).map fun (w : D → Nat) => fun d => kp.1 d + w d) :
              List (D → Nat)) := by
          rw [hsp]
          exact List.mem_map.mpr ⟨v, hv, rfl⟩
        exact List.mem_append.mpr (Or.inl hin)
      · exact List.mem_append.mpr (Or.inr (ih c hmem k p' hsp v hv))

theorem costsKids_mem_inv {C D Pos : Type}
    (spend : Nat → Pos → C → Option ((D → Nat) × Pos))
    (f : Pos → List (D → Nat)) (n : Nat) (p : Pos) :
    ∀ cs : List C, ∀ v, v ∈ costsKids spend f n p cs →
      ∃ c ∈ cs, ∃ (k : D → Nat) (p' : Pos),
        spend (n + 1) p c = some (k, p') ∧
        ∃ w ∈ f p', v = fun d => k d + w d := by
  intro cs
  induction cs with
  | nil => intro v hv; cases hv
  | cons c cs ih =>
      intro v hv
      have hv' : v ∈ (match spend (n + 1) p c with
          | none => []
          | some kp => (f kp.2).map fun w => fun d => kp.1 d + w d) ++
          costsKids spend f n p cs := hv
      rcases List.mem_append.mp hv' with h1 | h2
      · cases hsp : spend (n + 1) p c with
        | none =>
            rw [hsp] at h1
            have h1' : v ∈ ([] : List (D → Nat)) := h1
            cases h1'
        | some kp =>
            rw [hsp] at h1
            have h1' : v ∈ (f kp.2).map fun w => fun d => kp.1 d + w d := h1
            rcases List.mem_map.mp h1' with ⟨w, hw, he⟩
            exact ⟨c, List.mem_cons_self .., kp.1, kp.2, hsp, w, hw, he.symm⟩
      · rcases ih v h2 with ⟨c₀, hc₀, rest⟩
        exact ⟨c₀, List.mem_cons_of_mem _ hc₀, rest⟩

/-- Feasibility bridge: if NO structurally-possible completion's demand
    fits the budget, the budgeted subtree is leaf-free. (A path to a
    leaf consumes monotonically, so reaching depth 0 is exactly having
    total demand ≤ the starting budget, class by class.) -/
theorem leaves_nil_of_costs_infeasible {C D Pos : Type} [DecidableEq D]
    (choices : List C) (ds : List D)
    (spend : Nat → Pos → C → Option ((D → Nat) × Pos)) :
    ∀ (n : Nat) (p : Pos) (b : D → Nat),
      (∀ v ∈ costs choices spend n p, vleB ds v b = false) →
      leaves choices (bstep ds spend) n (b, p) = [] := by
  intro n
  induction n with
  | zero =>
      intro p b h
      have h0 := h _ (List.mem_cons_self ..)
      rw [vleB_zero] at h0
      cases h0
  | succ n ih =>
      intro p b h
      show expandKids (bstep ds spend)
          (fun t => leaves choices (bstep ds spend) n t) n (b, p) choices = []
      refine expandKids_nil_of _ _ n (b, p) choices ?_
      intro c hc bp' hst
      have hst' : (match spend (n + 1) p c with
          | none => none
          | some kp =>
              if vleB ds kp.1 b then some (fun d => b d - kp.1 d, kp.2)
              else none) = some bp' := hst
      cases hsp : spend (n + 1) p c with
      | none =>
          rw [hsp] at hst'
          have hno : (none : Option ((D → Nat) × Pos)) = some bp' := hst'
          cases hno
      | some kp =>
          rw [hsp] at hst'
          have hst'' : (if vleB ds kp.1 b then
              some ((fun d => b d - kp.1 d), kp.2) else none) = some bp' := hst'
          by_cases hle : vleB ds kp.1 b = true
          · rw [if_pos hle] at hst''
            have hbp : bp' = ((fun d => b d - kp.1 d), kp.2) :=
              (Option.some.inj hst'').symm
            subst hbp
            show leaves choices (bstep ds spend) n
              ((fun d => b d - kp.1 d), kp.2) = []
            apply ih kp.2 (fun d => b d - kp.1 d)
            intro v hv
            cases hvle : vleB ds v (fun d => b d - kp.1 d) with
            | false => rfl
            | true =>
                exfalso
                have hkb := vleB_iff.mp hle
                have hvbk := vleB_iff.mp hvle
                have hmem : (fun d => kp.1 d + v d) ∈
                    costs choices spend (n + 1) p :=
                  mem_costsKids spend _ n p choices c hc kp.1 kp.2 hsp v hv
                have hfit : vleB ds (fun d => kp.1 d + v d) b = true :=
                  vleB_iff.mpr fun d hd => by
                    have h1 := hkb d hd
                    have h2 := hvbk d hd
                    omega
                have hbad := h _ hmem
                rw [hfit] at hbad
                exact Bool.noConfusion hbad
          · rw [if_neg hle] at hst''
            have hno : (none : Option ((D → Nat) × Pos)) = some bp' := hst''
            cases hno

/-- Suffix accumulation of a per-depth class bound — the model of
    orb_fc_build's suffix-table recurrence (t-th row = per-slot term +
    (t+1)-th row). -/
def acc {D : Type} (m : Nat → D → Nat) : Nat → D → Nat
  | 0, _ => 0
  | n + 1, d => m (n + 1) d + acc m n d

/-- Per-edge class bounds accumulate into path bounds: every complete
    demand lies between the suffix mins and suffix maxes — the content
    of wd_suffix + minbnd_suffix ≤ consumption ≤ wd_suffix +
    maxbnd_suffix. -/
theorem costs_bounded {C D Pos : Type} (choices : List C) (ds : List D)
    (spend : Nat → Pos → C → Option ((D → Nat) × Pos))
    (mn mx : Nat → D → Nat)
    (hb : ∀ (n : Nat) (p : Pos) (c : C) (k : D → Nat) (p' : Pos),
      spend (n + 1) p c = some (k, p') →
      ∀ d ∈ ds, mn (n + 1) d ≤ k d ∧ k d ≤ mx (n + 1) d) :
    ∀ (n : Nat) (p : Pos), ∀ v ∈ costs choices spend n p, ∀ d ∈ ds,
      acc mn n d ≤ v d ∧ v d ≤ acc mx n d := by
  intro n
  induction n with
  | zero =>
      intro p v hv d _
      rcases List.mem_cons.mp hv with rfl | h
      · exact ⟨Nat.le_refl _, Nat.le_refl _⟩
      · cases h
  | succ n ih =>
      intro p v hv d hd
      have hv' : v ∈ costsKids spend
          (fun q => costs choices spend n q) n p choices := hv
      rcases costsKids_mem_inv spend _ n p choices v hv' with
        ⟨c, hc, k, p', hsp, w, hw, rfl⟩
      have hbk := hb n p c k p' hsp d hd
      have hiw := ih p' w hw d hd
      show acc mn (n + 1) d ≤ k d + w d ∧ k d + w d ≤ acc mx (n + 1) d
      simp only [acc]
      omega

/-- Per-edge total κ accumulates into path total κ·n — every complete
    demand consumes the same grand total (solve.c: κ = 2, one boundary
    + one within-pair transition per slot). -/
theorem costs_sum {C D Pos : Type} (choices : List C) (ds : List D)
    (spend : Nat → Pos → C → Option ((D → Nat) × Pos)) (κ : Nat)
    (hκ : ∀ (n : Nat) (p : Pos) (c : C) (k : D → Nat) (p' : Pos),
      spend (n + 1) p c = some (k, p') → sumv ds k = κ) :
    ∀ (n : Nat) (p : Pos), ∀ v ∈ costs choices spend n p,
      sumv ds v = κ * n := by
  intro n
  induction n with
  | zero =>
      intro p v hv
      rcases List.mem_cons.mp hv with rfl | h
      · rw [sumv_zero]; omega
      · cases h
  | succ n ih =>
      intro p v hv
      have hv' : v ∈ costsKids spend
          (fun q => costs choices spend n q) n p choices := hv
      rcases costsKids_mem_inv spend _ n p choices v hv' with
        ⟨c, hc, k, p', hsp, w, hw, rfl⟩
      show sumv ds (fun d => k d + w d) = κ * (n + 1)
      rw [sumv_add, hκ n p c k p' hsp, ih p' w hw, Nat.mul_succ]
      omega

/-- The forward-check predicate (prune A), as a pure predicate of the
    child state: the exact-consumption guard (see the header — implicit
    in solve.c, where it is an invariant of every reachable state)
    conjoined with the interval violation orb_recanon_dfs_fc tests
    (`bad`): some class's remaining budget falls outside
    [suffix-min, suffix-max] of the possible remaining consumption. -/
def fcCheck {D Pos : Type} (ds : List D) (mn mx : Nat → D → Nat) (κ : Nat)
    (n : Nat) (bp : (D → Nat) × Pos) : Bool :=
  (sumv ds bp.1 == κ * n) &&
  ds.any fun d =>
    decide (bp.1 d < acc mn n d) || decide (acc mx n d < bp.1 d)

/-- ITEM 2 — PRUNE A IS LEAF-FREE-SOUND: when fcCheck fires, the subtree
    below the checked state contains NO leaf at all (valid or not).
    Feasibility would force the completion's demand to EQUAL the budget
    (pointwise ≤ + equal totals), hence to lie inside the interval the
    check just found violated. -/
theorem fcCheck_leaf_free {C D Pos : Type} [DecidableEq D]
    (choices : List C) (ds : List D)
    (spend : Nat → Pos → C → Option ((D → Nat) × Pos))
    (mn mx : Nat → D → Nat) (κ : Nat)
    (hb : ∀ (n : Nat) (p : Pos) (c : C) (k : D → Nat) (p' : Pos),
      spend (n + 1) p c = some (k, p') →
      ∀ d ∈ ds, mn (n + 1) d ≤ k d ∧ k d ≤ mx (n + 1) d)
    (hκ : ∀ (n : Nat) (p : Pos) (c : C) (k : D → Nat) (p' : Pos),
      spend (n + 1) p c = some (k, p') → sumv ds k = κ) :
    ∀ (n : Nat) (b : D → Nat) (p : Pos),
      fcCheck ds mn mx κ n (b, p) = true →
      leaves choices (bstep ds spend) n (b, p) = [] := by
  intro n b p hfire
  simp only [fcCheck, Bool.and_eq_true] at hfire
  obtain ⟨hsumb, hany⟩ := hfire
  rw [beq_iff_eq] at hsumb
  have hsumb' : sumv ds b = κ * n := hsumb
  rcases List.any_eq_true.mp hany with ⟨d, hd, hp⟩
  simp only [Bool.or_eq_true, decide_eq_true_eq] at hp
  have hor : b d < acc mn n d ∨ acc mx n d < b d := hp
  apply leaves_nil_of_costs_infeasible
  intro v hv
  cases hvle : vleB ds v b with
  | false => rfl
  | true =>
      exfalso
      have hle := vleB_iff.mp hvle
      have hveq := eq_on_of_le_sum_eq ds v b hle
        (by rw [costs_sum choices ds spend κ hκ n p v hv, hsumb'])
      have hbd := costs_bounded choices ds spend mn mx hb n p v hv d hd
      have hvd := hveq d hd
      omega

/-- The exact-consumption guard is preserved by every taken step: a
    fitting cost of total κ drops the budget total by exactly κ. (The
    step case of solve.c's reachable-state sum invariant; the root case
    — budget0 sums to κ·np at the top call — is bridge fact B10.) -/
theorem sumv_sub_of_vle {D : Type} (ds : List D) (b k : D → Nat)
    (h : ∀ d ∈ ds, k d ≤ b d) :
    sumv ds (fun d => b d - k d) = sumv ds b - sumv ds k := by
  induction ds with
  | nil => rfl
  | cons d t ih =>
      have h1 := h d (List.mem_cons_self ..)
      have ht : ∀ x ∈ t, k x ≤ b x :=
        fun x hx => h x (List.mem_cons_of_mem _ hx)
      have h2 := sumv_mono t k b ht
      have h3 := ih ht
      rw [sumv_cons, sumv_cons, sumv_cons]
      omega

/-! ### §3 The memoized DFS (prune C) and its exactness

    The memo is abstract: any table with a probe, an insert, and a ghost
    `claims` relation — a positive probe only on a claimed key, and an
    insert claiming at most its own key (so collision policies that
    overwrite or drop entries are all covered). Keys are a PROJECTION π
    of the search state (solve.c: (slot, tail, budget), while the state
    proper carries the placed sequence); `hproj` states that the tree
    STRUCTURE below a state factors through π — which is exactly why a
    leaf-freeness fact learned under one prefix transfers to another
    prefix with the same key, and exactly what the rejected cd prune
    would break (validity does NOT factor through π). -/

/-- The memo-table contract. `claims` is the ghost meaning of the table:
    the set of (depth, key) pairs it asserts leaf-free. -/
structure MemoSpec (K M : Type) where
  probe : M → Nat → K → Bool
  ins : M → Nat → K → M
  claims : M → Nat → K → Prop
  probe_claims : ∀ m n k, probe m n k = true → claims m n k
  ins_claims : ∀ m n k n' k',
    claims (ins m n k) n' k' → claims m n' k' ∨ (n' = n ∧ k' = k)

/-- The memo invariant: everything the table claims is REALLY leaf-free
    (in the unpruned tree — the honest invariant; "leaf-free under
    pruning" would not survive composition, see §5). -/
def MemoInv {S C K M : Type} (choices : List C)
    (step : Nat → S → C → Option S) (π : S → K) (ms : MemoSpec K M)
    (m : M) : Prop :=
  ∀ (n : Nat) (t : S), ms.claims m n (π t) → leaves choices step n t = []

/-- Leaf-freeness transfers along the key projection: if the tree
    structure factors through π, π-equal states are leaf-free together.
    (This is what makes a memo keyed on (slot, tail, budget) sound for
    states that differ only in the placed sequence.) -/
theorem leaves_nil_congr {S C K : Type} (choices : List C)
    (step : Nat → S → C → Option S) (π : S → K)
    (hproj : ∀ (k : Nat) (t₁ t₂ : S), π t₁ = π t₂ →
      ∀ c : C, (step k t₁ c).map π = (step k t₂ c).map π) :
    ∀ (n : Nat) (t₁ t₂ : S), π t₁ = π t₂ →
      leaves choices step n t₁ = [] → leaves choices step n t₂ = [] := by
  intro n
  induction n with
  | zero =>
      intro t₁ t₂ _ hnil
      simp [leaves] at hnil
  | succ n ih =>
      intro t₁ t₂ hπ hnil
      have hnil' : expandKids step (fun t => leaves choices step n t)
          n t₁ choices = [] := hnil
      show expandKids step (fun t => leaves choices step n t)
        n t₂ choices = []
      refine expandKids_nil_of _ _ n t₂ choices ?_
      intro c hc t₂' hst₂
      have hmaps := hproj (n + 1) t₁ t₂ hπ c
      rw [hst₂] at hmaps
      cases hst₁ : step (n + 1) t₁ c with
      | none =>
          rw [hst₁] at hmaps
          have hno : (none : Option K) = some (π t₂') := hmaps
          cases hno
      | some t₁' =>
          rw [hst₁] at hmaps
          have hmm : some (π t₁') = some (π t₂') := hmaps
          have hππ : π t₁' = π t₂' := Option.some.inj hmm
          have h₁ := nil_of_expandKids_nil step _ n t₁ choices hnil' c hc t₁' hst₁
          exact ih t₁' t₂' hππ h₁

/-- The memoized, forward-checked, first-found DFS — child iteration.
    `rec` searches one child (threading the memo); `acc` accumulates
    the leaf count (orb_recanon_dfs_fc's *leaves). Per child, in
    solve.c's order: structural absence → prune A → memo probe →
    descend; a child that completes with ZERO leaves reached gets its
    key inserted (the `*leaves == lv0` condition); a found valid leaf
    returns immediately (no insert on the exit path). -/
def searchKids {S C K M : Type} (step : Nat → S → C → Option S)
    (pruneA : Nat → S → Bool) (π : S → K) (ms : MemoSpec K M)
    (rec : S → M → Option S × M × Nat) (n : Nat) (s : S) :
    List C → M → Nat → Option S × M × Nat
  | [], m, acc => (none, m, acc)
  | c :: cs, m, acc =>
      match step (n + 1) s c with
      | none => searchKids step pruneA π ms rec n s cs m acc
      | some s' =>
          if pruneA n s' then searchKids step pruneA π ms rec n s cs m acc
          else if ms.probe m n (π s') then
            searchKids step pruneA π ms rec n s cs m acc
          else
            match rec s' m with
            | (some x, m', k) => (some x, m', acc + k)
            | (none, m', k) =>
                searchKids step pruneA π ms rec n s cs
                  (if k = 0 then ms.ins m' n (π s') else m') (acc + k)

/-- The memoized DFS: the model of orb_recanon_dfs_fc. Returns (first
    valid leaf if any, final memo, leaves reached). -/
def dfsM {S C K M : Type} (choices : List C) (step : Nat → S → C → Option S)
    (P : S → Bool) (pruneA : Nat → S → Bool) (π : S → K)
    (ms : MemoSpec K M) : Nat → S → M → Option S × M × Nat
  | 0, s, m => (if P s then some s else none, m, 1)
  | n + 1, s, m =>
      searchKids step pruneA π ms
        (fun t mm => dfsM choices step P pruneA π ms n t mm) n s choices m 0

theorem sk_none {S C K M : Type} {step : Nat → S → C → Option S}
    {pruneA : Nat → S → Bool} {π : S → K} {ms : MemoSpec K M}
    {rec : S → M → Option S × M × Nat} {n : Nat} {s : S} {c : C}
    {cs : List C} {m : M} {acc : Nat} (hst : step (n + 1) s c = none) :
    searchKids step pruneA π ms rec n s (c :: cs) m acc =
      searchKids step pruneA π ms rec n s cs m acc := by
  simp only [searchKids, hst]

theorem sk_pruned {S C K M : Type} {step : Nat → S → C → Option S}
    {pruneA : Nat → S → Bool} {π : S → K} {ms : MemoSpec K M}
    {rec : S → M → Option S × M × Nat} {n : Nat} {s : S} {c : C}
    {cs : List C} {m : M} {acc : Nat} {s' : S}
    (hst : step (n + 1) s c = some s') (hpA : pruneA n s' = true) :
    searchKids step pruneA π ms rec n s (c :: cs) m acc =
      searchKids step pruneA π ms rec n s cs m acc := by
  simp only [searchKids, hst, hpA, if_true]

theorem sk_probed {S C K M : Type} {step : Nat → S → C → Option S}
    {pruneA : Nat → S → Bool} {π : S → K} {ms : MemoSpec K M}
    {rec : S → M → Option S × M × Nat} {n : Nat} {s : S} {c : C}
    {cs : List C} {m : M} {acc : Nat} {s' : S}
    (hst : step (n + 1) s c = some s') (hpA : pruneA n s' = false)
    (hpr : ms.probe m n (π s') = true) :
    searchKids step pruneA π ms rec n s (c :: cs) m acc =
      searchKids step pruneA π ms rec n s cs m acc := by
  simp only [searchKids, hst, hpA, hpr, if_true, Bool.false_eq_true, if_false]

theorem sk_found {S C K M : Type} {step : Nat → S → C → Option S}
    {pruneA : Nat → S → Bool} {π : S → K} {ms : MemoSpec K M}
    {rec : S → M → Option S × M × Nat} {n : Nat} {s : S} {c : C}
    {cs : List C} {m : M} {acc : Nat} {s' : S} {x : S} {m' : M} {k : Nat}
    (hst : step (n + 1) s c = some s') (hpA : pruneA n s' = false)
    (hpr : ms.probe m n (π s') = false) (hcall : rec s' m = (some x, m', k)) :
    searchKids step pruneA π ms rec n s (c :: cs) m acc =
      (some x, m', acc + k) := by
  simp only [searchKids, hst, hpA, hpr, hcall, Bool.false_eq_true, if_false]

theorem sk_deeper {S C K M : Type} {step : Nat → S → C → Option S}
    {pruneA : Nat → S → Bool} {π : S → K} {ms : MemoSpec K M}
    {rec : S → M → Option S × M × Nat} {n : Nat} {s : S} {c : C}
    {cs : List C} {m : M} {acc : Nat} {s' : S} {m' : M} {k : Nat}
    (hst : step (n + 1) s c = some s') (hpA : pruneA n s' = false)
    (hpr : ms.probe m n (π s') = false) (hcall : rec s' m = (none, m', k)) :
    searchKids step pruneA π ms rec n s (c :: cs) m acc =
      searchKids step pruneA π ms rec n s cs
        (if k = 0 then ms.ins m' n (π s') else m') (acc + k) := by
  simp only [searchKids, hst, hpA, hpr, hcall, Bool.false_eq_true, if_false]

/-- The inductive engine: given a correct one-child searcher, the child
    iteration (i) returns `find?` over the unpruned child leaf streams,
    (ii) preserves the memo invariant — inserts are justified by the
    zero-leaf count, probe hits by the invariant — and (iii) when
    nothing is found, counts exactly the unpruned leaves. -/
theorem searchKids_spec {S C K M : Type} (choices : List C)
    (step : Nat → S → C → Option S) (P : S → Bool)
    (pruneA : Nat → S → Bool) (π : S → K) (ms : MemoSpec K M)
    (hA : ∀ (k : Nat) (t : S), pruneA k t = true →
      leaves choices step k t = [])
    (hproj : ∀ (k : Nat) (t₁ t₂ : S), π t₁ = π t₂ →
      ∀ c : C, (step k t₁ c).map π = (step k t₂ c).map π)
    (n : Nat) (s : S) (rec : S → M → Option S × M × Nat)
    (hrec : ∀ (t : S) (m : M), MemoInv choices step π ms m →
      (rec t m).1 = (leaves choices step n t).find? P ∧
      MemoInv choices step π ms (rec t m).2.1 ∧
      ((rec t m).1 = none →
        (rec t m).2.2 = (leaves choices step n t).length)) :
    ∀ (cs : List C) (m : M) (acc : Nat), MemoInv choices step π ms m →
      (searchKids step pruneA π ms rec n s cs m acc).1 =
        (expandKids step (fun t => leaves choices step n t) n s cs).find? P ∧
      MemoInv choices step π ms
        (searchKids step pruneA π ms rec n s cs m acc).2.1 ∧
      ((searchKids step pruneA π ms rec n s cs m acc).1 = none →
        (searchKids step pruneA π ms rec n s cs m acc).2.2 =
          acc + (expandKids step (fun t => leaves choices step n t) n s cs).length) := by
  intro cs
  induction cs with
  | nil =>
      intro m acc hm
      refine ⟨rfl, hm, fun _ => ?_⟩
      simp [searchKids, expandKids]
  | cons c cs ih =>
      intro m acc hm
      cases hst : step (n + 1) s c with
      | none =>
          simp only [sk_none hst, expandKids_cons_none hst]
          exact ih m acc hm
      | some s' =>
          by_cases hpA : pruneA n s' = true
          · have hnil := hA n s' hpA
            simp only [sk_pruned hst hpA, expandKids_cons_some hst, hnil,
              List.nil_append]
            exact ih m acc hm
          · have hpA' : pruneA n s' = false := bool_eq_false hpA
            by_cases hpr : ms.probe m n (π s') = true
            · have hnil : leaves choices step n s' = [] :=
                hm n s' (ms.probe_claims m n (π s') hpr)
              simp only [sk_probed hst hpA' hpr, expandKids_cons_some hst,
                hnil, List.nil_append]
              exact ih m acc hm
            · have hpr' : ms.probe m n (π s') = false := bool_eq_false hpr
              rcases hcall : rec s' m with ⟨r, m', k⟩
              have hspec := hrec s' m hm
              rw [hcall] at hspec
              have hr : r = (leaves choices step n s').find? P := hspec.1
              have hm' : MemoInv choices step π ms m' := hspec.2.1
              have hk : r = none →
                  k = (leaves choices step n s').length := hspec.2.2
              cases r with
              | some x =>
                  simp only [sk_found hst hpA' hpr' hcall,
                    expandKids_cons_some hst]
                  refine ⟨?_, hm', fun hcontra => by simp at hcontra⟩
                  rw [find?_append, ← hr]
              | none =>
                  have hkl : k = (leaves choices step n s').length := hk rfl
                  have hminv : MemoInv choices step π ms
                      (if k = 0 then ms.ins m' n (π s') else m') := by
                    by_cases hk0 : k = 0
                    · rw [if_pos hk0]
                      have hnil : leaves choices step n s' = [] :=
                        List.eq_nil_of_length_eq_zero (by omega)
                      intro n₀ t hcl
                      rcases ms.ins_claims m' n (π s') n₀ (π t) hcl with
                        hold | ⟨hn, hkey⟩
                      · exact hm' n₀ t hold
                      · subst hn
                        exact leaves_nil_congr choices step π hproj _ s' t
                          hkey.symm hnil
                    · rw [if_neg hk0]
                      exact hm'
                  have htail := ih (if k = 0 then ms.ins m' n (π s') else m')
                    (acc + k) hminv
                  simp only [sk_deeper hst hpA' hpr' hcall,
                    expandKids_cons_some hst]
                  refine ⟨?_, htail.2.1, fun hnone => ?_⟩
                  · rw [find?_append, ← hr]
                    exact htail.1
                  · have hlen := htail.2.2 hnone
                    rw [List.length_append]
                    omega

/-- ITEM 3 — MEMOIZED SEARCH IS EXACT: starting from any memo whose
    claims are all true, the memoized forward-checked first-found DFS
    (with ANY leaf-free-sound prune A inside) returns exactly the
    unpruned search's first valid leaf, ends with a memo whose claims
    are all still true, and — when nothing is found — has counted
    exactly the unpruned leaves. -/
theorem dfsM_spec {S C K M : Type} (choices : List C)
    (step : Nat → S → C → Option S) (P : S → Bool)
    (pruneA : Nat → S → Bool) (π : S → K) (ms : MemoSpec K M)
    (hA : ∀ (k : Nat) (t : S), pruneA k t = true →
      leaves choices step k t = [])
    (hproj : ∀ (k : Nat) (t₁ t₂ : S), π t₁ = π t₂ →
      ∀ c : C, (step k t₁ c).map π = (step k t₂ c).map π) :
    ∀ (n : Nat) (t : S) (m : M), MemoInv choices step π ms m →
      (dfsM choices step P pruneA π ms n t m).1 =
        (leaves choices step n t).find? P ∧
      MemoInv choices step π ms
        (dfsM choices step P pruneA π ms n t m).2.1 ∧
      ((dfsM choices step P pruneA π ms n t m).1 = none →
        (dfsM choices step P pruneA π ms n t m).2.2 =
          (leaves choices step n t).length) := by
  intro n
  induction n with
  | zero =>
      intro t m hm
      refine ⟨?_, hm, fun _ => rfl⟩
      show (if P t then some t else none) = List.find? P [t]
      by_cases hP : P t = true
      · rw [if_pos hP]
        simp only [List.find?, hP]
      · rw [if_neg hP]
        simp only [List.find?, bool_eq_false hP]
  | succ n ih =>
      intro t m hm
      have h := searchKids_spec choices step P pruneA π ms hA hproj n t
        (fun t' m' => dfsM choices step P pruneA π ms n t' m')
        (fun t' m' hm' => ih t' m' hm') choices m 0 hm
      refine ⟨h.1, h.2.1, fun hnone => ?_⟩
      exact (h.2.2 hnone).trans (Nat.zero_add _)

/-- Convenient corollary: from a memo that claims NOTHING (a fresh
    epoch), the memoized search equals `find?` over the unpruned leaf
    stream. -/
theorem dfsM_eq_unpruned {S C K M : Type} (choices : List C)
    (step : Nat → S → C → Option S) (P : S → Bool)
    (pruneA : Nat → S → Bool) (π : S → K) (ms : MemoSpec K M)
    (hA : ∀ (k : Nat) (t : S), pruneA k t = true →
      leaves choices step k t = [])
    (hproj : ∀ (k : Nat) (t₁ t₂ : S), π t₁ = π t₂ →
      ∀ c : C, (step k t₁ c).map π = (step k t₂ c).map π)
    (m₀ : M) (hm₀ : ∀ (n : Nat) (t : S), ¬ ms.claims m₀ n (π t))
    (n : Nat) (s : S) :
    (dfsM choices step P pruneA π ms n s m₀).1 =
      (leaves choices step n s).find? P :=
  (dfsM_spec choices step P pruneA π ms hA hproj n s m₀
    (fun n₀ t hc => absurd hc (hm₀ n₀ t))).1

/-! ### §3b Witness tables: the spec is inhabited, collisions and epochs
    behave as claimed -/

/-- The trivial association-list memo (never drops anything): the
    simplest MemoSpec witness. -/
def listMemo (K : Type) [DecidableEq K] : MemoSpec K (List (Nat × K)) where
  probe := fun m n k => decide ((n, k) ∈ m)
  ins := fun m n k => (n, k) :: m
  claims := fun m n k => (n, k) ∈ m
  probe_claims := fun _ _ _ h => of_decide_eq_true h
  ins_claims := fun _ n k n' k' h => by
    rcases List.mem_cons.mp h with heq | hmem
    · injection heq with h1 h2
      exact Or.inr ⟨h1, h2⟩
    · exact Or.inl hmem

/-- The epoch-tagged fixed-size table: a bucket array of (epoch, depth,
    key) entries and a current epoch — the model of orb_fc_memo_key /
    orb_fc_memo_ep / orb_fc_epoch. -/
structure EpochTable (K : Type) where
  buckets : List (Option (Nat × Nat × K))
  epoch : Nat

/-- what the table claims: this (depth, key), tagged with the CURRENT
    epoch, sits in some bucket. Entries with other tags claim nothing. -/
def etClaims {K : Type} (T : EpochTable K) (n : Nat) (k : K) : Prop :=
  some (T.epoch, n, k) ∈ T.buckets

/-- a probe hit requires full-key AND epoch-tag equality (solve.c
    compares both; pack injectivity is bridge fact B9). -/
def etProbe {K : Type} [DecidableEq K] (T : EpochTable K) (n : Nat)
    (k : K) : Bool :=
  decide (some (T.epoch, n, k) ∈ T.buckets)

/-- insertion overwrites the bucket an ARBITRARY placement policy `pos`
    chooses — any hash + probe sequence is covered, and an out-of-range
    position models "probe window full, new entry dropped" (List.set is
    then the identity). -/
def etIns {K : Type} (pos : EpochTable K → Nat → K → Nat)
    (T : EpochTable K) (n : Nat) (k : K) : EpochTable K :=
  { T with buckets := T.buckets.set (pos T n k) (some (T.epoch, n, k)) }

/-- The epoch table satisfies the memo contract for EVERY placement
    policy: collisions (overwriting a live entry, or dropping the new
    one) only ever SHRINK the claim set beyond the inserted key —
    "costs time, never correctness". -/
def epochMemo {K : Type} [DecidableEq K]
    (pos : EpochTable K → Nat → K → Nat) : MemoSpec K (EpochTable K) where
  probe := etProbe
  ins := etIns pos
  claims := etClaims
  probe_claims := fun T n k h => by
    show some (T.epoch, n, k) ∈ T.buckets
    exact of_decide_eq_true h
  ins_claims := fun T n k n' k' h => by
    rcases mem_set_cases T.buckets (pos T n k) h with hmem | heq
    · exact Or.inl hmem
    · injection heq with h1
      injection h1 with _ h2
      injection h2 with h3 h4
      exact Or.inr ⟨h3, h4⟩

/-- EPOCH SEMANTICS: if every stored tag is at most the current epoch —
    the invariant of monotone epoch increment, which solve.c's explicit
    table clear restores at the uint32 wrap (bridge fact B9) — then a
    bumped epoch claims NOTHING: no stale positive can resurrect, and
    the O(1) "clear" is sound. -/
theorem etBump_claims_empty {K : Type} (T : EpochTable K)
    (htags : ∀ (e n : Nat) (k : K), some (e, n, k) ∈ T.buckets →
      e ≤ T.epoch) :
    ∀ (n : Nat) (k : K),
      ¬ etClaims { T with epoch := T.epoch + 1 } n k := by
  intro n k h
  have := htags (T.epoch + 1) n k h
  omega

/-! ### §4 The conclusion: the FC-enabled search equals the unpruned
    search -/

/-- ITEM 4 — THE COMPOSED THEOREM (the C comment's claim, at the model
    level): over the budgeted tree, the memoized DFS with the
    exact-consumption forward check as prune A, started on a memo that
    claims nothing, returns EXACTLY the unpruned first-found DFS's
    leaf — for every key, every budget, every leaf-validity test P.
    With bridge fact B6 (RecordConvention.lean §3: unpruned first-found
    = lex-min valid completion), the FC-enabled and unpruned searches
    compute the same repr(k), bit-identically. -/
theorem fc_memo_first_leaf_exact {C D Pos K M : Type} [DecidableEq D]
    (choices : List C) (ds : List D)
    (spend : Nat → Pos → C → Option ((D → Nat) × Pos))
    (mn mx : Nat → D → Nat) (κ : Nat)
    (P : ((D → Nat) × Pos) → Bool)
    (π : ((D → Nat) × Pos) → K) (ms : MemoSpec K M)
    (hb : ∀ (n : Nat) (p : Pos) (c : C) (k : D → Nat) (p' : Pos),
      spend (n + 1) p c = some (k, p') →
      ∀ d ∈ ds, mn (n + 1) d ≤ k d ∧ k d ≤ mx (n + 1) d)
    (hκ : ∀ (n : Nat) (p : Pos) (c : C) (k : D → Nat) (p' : Pos),
      spend (n + 1) p c = some (k, p') → sumv ds k = κ)
    (hproj : ∀ (n : Nat) (t₁ t₂ : (D → Nat) × Pos), π t₁ = π t₂ →
      ∀ c : C, ((bstep ds spend) n t₁ c).map π =
        ((bstep ds spend) n t₂ c).map π)
    (m₀ : M)
    (hm₀ : ∀ (n : Nat) (t : (D → Nat) × Pos), ¬ ms.claims m₀ n (π t))
    (n : Nat) (b : D → Nat) (p : Pos) :
    (dfsM choices (bstep ds spend) P (fcCheck ds mn mx κ) π ms
        n (b, p) m₀).1 =
      dfs choices (bstep ds spend) P n (b, p) := by
  rw [dfs_eq_find?]
  exact dfsM_eq_unpruned choices (bstep ds spend) P (fcCheck ds mn mx κ)
    π ms
    (fun k t hf =>
      fcCheck_leaf_free choices ds spend mn mx κ hb hκ k t.1 t.2 hf)
    hproj m₀ hm₀ n (b, p)

/-! ### §4b Witness: the path-blind spend shape discharges `hproj`

    solve.c's transition arithmetic reads only the slot and the running
    tail; the placed sequence seq[] is payload consulted only by the C3
    leaf test. Model that shape — position = (tail, path), spend reading
    the tail component only — and the memo projection (budget, tail)
    satisfies the step-factorization hypothesis automatically. -/

/-- lift a tail-only spend to positions carrying a path payload. -/
def liftSpend {C D Tail Path : Type}
    (spend0 : Nat → Tail → C → Option ((D → Nat) × Tail))
    (upd : Path → Nat → C → Path) :
    Nat → (Tail × Path) → C → Option ((D → Nat) × (Tail × Path)) :=
  fun n tp c =>
    match spend0 n tp.1 c with
    | none => none
    | some kt => some (kt.1, (kt.2, upd tp.2 n c))

/-- the memo key: (budget, tail) — the path payload is projected away
    (solve.c: orb_fc_pack's (slot, tail, budget); slot is the model's
    depth index, carried separately in the memo key by dfsM itself). -/
def projBT {D Tail Path : Type} :
    ((D → Nat) × (Tail × Path)) → ((D → Nat) × Tail) :=
  fun bp => (bp.1, bp.2.1)

/-- For a path-blind spend, the budgeted step structure factors through
    (budget, tail): `hproj` holds — nothing about the paths is
    assumed. -/
theorem liftSpend_proj {C D Tail Path : Type} (ds : List D)
    (spend0 : Nat → Tail → C → Option ((D → Nat) × Tail))
    (upd : Path → Nat → C → Path) :
    ∀ (n : Nat) (t₁ t₂ : (D → Nat) × (Tail × Path)),
      projBT t₁ = projBT t₂ →
      ∀ c : C,
        ((bstep ds (liftSpend spend0 upd)) n t₁ c).map projBT =
        ((bstep ds (liftSpend spend0 upd)) n t₂ c).map projBT := by
  intro n t₁ t₂ hπ c
  have hb0 := congrArg Prod.fst hπ
  have ht0 := congrArg Prod.snd hπ
  have hb : t₁.1 = t₂.1 := hb0
  have ht : t₁.2.1 = t₂.2.1 := ht0
  cases hsp₁ : spend0 n t₁.2.1 c with
  | none =>
      have hsp₂ : spend0 n t₂.2.1 c = none := by rw [← ht]; exact hsp₁
      have e₁ : bstep ds (liftSpend spend0 upd) n t₁ c = none := by
        simp only [bstep, liftSpend, hsp₁]
      have e₂ : bstep ds (liftSpend spend0 upd) n t₂ c = none := by
        simp only [bstep, liftSpend, hsp₂]
      rw [e₁, e₂]
  | some kt =>
      have hsp₂ : spend0 n t₂.2.1 c = some kt := by rw [← ht]; exact hsp₁
      have e₁ : bstep ds (liftSpend spend0 upd) n t₁ c =
          (if vleB ds kt.1 t₁.1 then
            some (fun d => t₁.1 d - kt.1 d, (kt.2, upd t₁.2.2 n c))
          else none) := by
        simp only [bstep, liftSpend, hsp₁]
      have e₂ : bstep ds (liftSpend spend0 upd) n t₂ c =
          (if vleB ds kt.1 t₁.1 then
            some (fun d => t₁.1 d - kt.1 d, (kt.2, upd t₂.2.2 n c))
          else none) := by
        simp only [bstep, liftSpend, hsp₂, ← hb]
      rw [e₁, e₂]
      cases hle : vleB ds kt.1 t₁.1 with
      | true => rfl
      | false => rfl

/-! ### §5 The composition hazard, machine-checked as a counterexample

    The C comment CAUTIONs that a C3-lower-bound prune — sound ALONE —
    is UNSOUND inside the memoized DFS: it cuts subtrees that contain
    (invalid) leaves, so a zero leaf count no longer certifies
    leaf-freeness, and the poisoned entry is consulted by OTHER prefixes
    whose validity context differs. We machine-check that this hazard is
    real on a 3-level binary toy tree: cdPrune cuts exactly the two
    subtrees below the [false] branch (all of whose leaves are invalid),
    the memo keys on path LENGTH (a maximal-collision projection under
    which the tree structure genuinely factors — hproj HOLDS, isolating
    hA as the failing hypothesis), and the one valid leaf lives below
    the [true] branch. -/

def cChoices : List Bool := [false, true]
def cStep : Nat → List Bool → Bool → Option (List Bool) :=
  fun _ s c => some (s ++ [c])
def cP : List Bool → Bool := fun s => s == [true, false, false]
def cdPrune : Nat → List Bool → Bool :=
  fun n s => n == 1 && (s == [false, false] || s == [false, true])
def cπ : List Bool → Nat := List.length

/-- cdPrune is NOT leaf-free-sound: it fires on a subtree that contains
    two (invalid) leaves — hypothesis hA of §3 fails for it. -/
example : cdPrune 1 [false, false] = true ∧
    (leaves cChoices cStep 1 [false, false]).length = 2 := by decide

/-- ALONE, cdPrune is answer-sound: it cuts only invalid leaves, so the
    first VALID leaf — the returned repr — is unchanged... -/
example :
    (leavesPr cChoices cStep cdPrune 3 []).find? cP =
      (leaves cChoices cStep 3 []).find? cP := by decide

/-- ...even though the leaf STREAMS differ (leaves were removed): it is
    answer-preserving without being leaf-free — precisely the profile
    the memo cannot tolerate. -/
example :
    leavesPr cChoices cStep cdPrune 3 [] ≠ leaves cChoices cStep 3 [] := by
  decide

/-- the projection is NOT the failing leg here: the toy tree's structure
    genuinely factors through path length, so hproj holds. -/
theorem cπ_proj : ∀ (n : Nat) (t₁ t₂ : List Bool), cπ t₁ = cπ t₂ →
    ∀ c : Bool, (cStep n t₁ c).map cπ = (cStep n t₂ c).map cπ := by
  intro n t₁ t₂ h c
  have h' : t₁.length = t₂.length := h
  simp [cStep, cπ, h']

/-- THE HAZARD, machine-checked: composed with the leaf-free memo,
    cdPrune poisons the table — the [false] subtree completes with zero
    leaves REACHED (they were cd-cut, not absent), its length-keyed
    entry is inserted, the [true] sibling probes positive on the same
    key and is skipped, and the search returns NONE while the unpruned
    answer exists. "No leaf reached" must mean "leaf-free", or the memo
    lies to other prefixes. -/
example :
    (dfsM cChoices cStep cP cdPrune cπ (listMemo Nat) 3 [] []).1 = none ∧
    (leaves cChoices cStep 3 []).find? cP = some [true, false, false] := by
  decide

/-- control: the memo machinery itself is exact — with the unsound prune
    removed (pruneA ≡ false), the same memoized search on the same tree
    returns the unpruned answer (a concrete instance of dfsM_spec). -/
example :
    (dfsM cChoices cStep cP (fun _ _ => false) cπ (listMemo Nat) 3 [] []).1 =
      (leaves cChoices cStep 3 []).find? cP := by decide

/-- a sound insert-and-hit in action: with dead-ends that DO factor
    through the length key (every length-2 state at depth 1 is barren),
    the memoized search inserts on the first barren subtree, probe-hits
    on its siblings, and still agrees with the unpruned result. -/
def dStep : Nat → List Bool → Bool → Option (List Bool) :=
  fun n s _ => if n == 1 && s.length == 2 then none else some (s ++ [true])

example :
    (dfsM cChoices dStep cP (fun _ _ => false) cπ (listMemo Nat) 3 [] []).1 =
      (leaves cChoices dStep 3 []).find? cP := by decide

/-! ### §6 Sanity instantiations of prune A (tiny concrete cases) -/

/-- toy budget model: two classes, every edge costs one unit of each
    (κ = 2, mn = mx = 1 per class per depth). -/
def eSpend : Nat → Unit → Bool → Option ((Nat → Nat) × Unit) :=
  fun _ _ _ => some (fun _ => 1, ())
def eB : Nat → Nat := fun d => if d == 0 then 3 else 1

/-- the check fires on budget (3,1) at depth 2: the total is right
    (4 = 2·2 — exact consumption holds) but class 0 exceeds its maximal
    possible consumption (3 > 2)... -/
example :
    fcCheck [0, 1] (fun _ _ => 1) (fun _ _ => 1) 2 2 (eB, ()) = true := by
  decide

/-- ...and the subtree it would cut is indeed leaf-free: class 1's
    budget starves one step early (feasibility would need equality). -/
example :
    (leaves cChoices (bstep [0, 1] eSpend) 2 (eB, ())).isEmpty = true := by
  decide

/-- while an exactly-consumable budget (2,2) at depth 2 does reach
    leaves — the check must not (and does not) fire there. -/
example :
    fcCheck [0, 1] (fun _ _ => 1) (fun _ _ => 1) 2 2
        ((fun _ => 2), ()) = false ∧
    (leaves cChoices (bstep [0, 1] eSpend) 2
        ((fun _ => 2), ())).isEmpty = false := by
  decide

end PruneReprFC

-- Axiom audit (kernel-only trust base: expect ⊆ [propext, Classical.choice,
-- Quot.sound]; no `Lean.ofReduceBool` anywhere — zero native_decide).
#print axioms PruneReprFC.leavesPr_eq
#print axioms PruneReprFC.prune_first_leaf_exact
#print axioms PruneReprFC.dfs_eq_find?
#print axioms PruneReprFC.fcCheck_leaf_free
#print axioms PruneReprFC.sumv_sub_of_vle
#print axioms PruneReprFC.leaves_nil_congr
#print axioms PruneReprFC.dfsM_spec
#print axioms PruneReprFC.dfsM_eq_unpruned
#print axioms PruneReprFC.etBump_claims_empty
#print axioms PruneReprFC.fc_memo_first_leaf_exact
#print axioms PruneReprFC.liftSpend_proj
#print axioms PruneReprFC.cπ_proj
