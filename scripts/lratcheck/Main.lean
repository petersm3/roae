/-
lratcheck — minimal driver around the LRAT checker shipped in the Lean 4 toolchain
(Std.Tactic.BVDecide.LRAT.check, with soundness theorem Std.Tactic.BVDecide.LRAT.check_sound).

usage: lratcheck <piece.cnf> <proof.lrat>
exit 0 + line `LRAT_LEAN=VERIFIED`  iff  LRAT.check proof cnf = true
exit 1 + line `LRAT_LEAN=REJECTED`  otherwise (checker returned false)
exit 2 + line `LRAT_LEAN=ERROR ...`  on a parse/IO error (never a verdict)

Trusted outside the theorem: this DIMACS parser (below), the library LRAT parser
(Std.Tactic.BVDecide.LRAT.parseLRATProof), the Lean compiler + runtime, file I/O.
Variable convention: DIMACS variable v (1-based) is stored as the `CNF Nat` variable v-1,
because `CNF.convertLRAT` (Internal/Convert.lean) lifts every variable by +1 to meet the
1-based literals of the LRAT proof; original clause i (1-based, file order) gets LRAT id i
because `convertLRAT` prepends one `none` clause at index 0.
-/
import Std.Tactic.BVDecide.LRAT.Checker
import Std.Tactic.BVDecide.LRAT.Parser

open Std.Sat
open Std.Tactic.BVDecide

/-- The exact statement relied on, restated here so that `lake build` type-checks the link. -/
theorem lratcheck_relies_on (proof : Array LRAT.IntAction) (cnf : CNF Nat) :
    LRAT.check proof cnf = true → cnf.Unsat :=
  LRAT.check_sound proof cnf

structure Dimacs where
  nvars : Nat
  nclauses : Nat
  cnf : CNF Nat

def isWs (c : Char) : Bool := c == ' ' || c == '\t' || c == '\r' || c == '\n'

/-- Whitespace tokens of a DIMACS file; a line whose first non-blank character is `c` is dropped. -/
def dimacsTokens (s : String) : Array String := Id.run do
  let mut acc : Array String := #[]
  let mut cur : String := ""
  let mut inComment := false
  let mut atLineStart := true
  for c in s.toList do
    if inComment then
      if c == '\n' then
        inComment := false
        atLineStart := true
      continue
    if isWs c then
      if !cur.isEmpty then
        acc := acc.push cur
        cur := ""
      if c == '\n' then atLineStart := true
      continue
    if atLineStart && c == 'c' then
      inComment := true
      continue
    atLineStart := false
    cur := cur.push c
  if !cur.isEmpty then acc := acc.push cur
  return acc

/-- Parse DIMACS text. Rejects (as ERROR, not a verdict): bad header, literal > nvars,
clause count ≠ header, a tautological clause (would be dropped by `convertLRAT` and shift
every later LRAT id), and literals after the last `0`. -/
def parseDimacs (s : String) : Except String Dimacs := do
  let toks := dimacsTokens s
  let mut nvars : Option Nat := none
  let mut ncl : Option Nat := none
  let mut clauses : Array (CNF.Clause Nat) := #[]
  let mut cur : List (Literal Nat) := []
  let mut seen : Array Int := #[]
  let mut i := 0
  while i < toks.size do
    let tok := toks[i]!
    if tok == "p" then
      if i + 3 < toks.size && toks[i+1]! == "cnf" then
        match toks[i+2]!.toNat?, toks[i+3]!.toNat? with
        | some a, some b => nvars := some a; ncl := some b
        | _, _ => throw s!"bad header at token {i}"
      else throw s!"bad header at token {i}"
      i := i + 4
      continue
    i := i + 1
    match tok.toInt? with
    | none => throw s!"bad token: {tok}"
    | some 0 =>
      clauses := clauses.push cur.reverse
      cur := []
      seen := #[]
    | some v =>
      if seen.contains (-v) then
        throw s!"tautological clause #{clauses.size + 1} (unsupported: convertLRAT would drop it and shift LRAT ids)"
      seen := seen.push v
      let var := v.natAbs
      match nvars with
      | none => throw "literal before header"
      | some n => if var > n then throw s!"literal {v} exceeds nvars {n}"
      cur := (var - 1, decide (v > 0)) :: cur
  if !cur.isEmpty then throw "trailing literals without a terminating 0"
  match nvars, ncl with
  | some nv, some nc =>
    if clauses.size != nc then throw s!"clause count {clauses.size} ≠ header {nc}"
    return { nvars := nv, nclauses := nc, cnf := { clauses := clauses } }
  | _, _ => throw "missing header"

open Std.Tactic.BVDecide.LRAT.Internal in
/-- Debug replay of `compactLratChecker.go` that reports the index of the first failing action. -/
partial def debugRun {n : Nat} (f : DefaultFormula n) (proof : Array LRAT.IntAction) (idx : Nat) : IO Unit := do
  if h : idx < proof.size then
    match intActionToDefaultClauseAction n proof[idx] with
    | none =>
      IO.println s!"idx {idx}: dropped by intActionToDefaultClauseAction: {proof[idx]}"
      debugRun f proof (idx + 1)
    | some (.addEmpty _ hints) =>
      let (_, ok) := Formula.performRupAdd f Clause.empty hints
      IO.println s!"idx {idx}: addEmpty -> {ok} action={proof[idx]}"
    | some (.addRup _ c hints) =>
      let (f', ok) := Formula.performRupAdd f c hints
      if ok then debugRun f' proof (idx + 1)
      else IO.println s!"idx {idx}: addRup FAILED action={proof[idx]}"
    | some (.addRat _ c pivot rh rath) =>
      if pivot ∈ Clause.toList c then
        let (f', ok) := Formula.performRatAdd f c pivot rh rath
        if ok then debugRun f' proof (idx + 1)
        else IO.println s!"idx {idx}: addRat FAILED action={proof[idx]}"
      else
        IO.println s!"idx {idx}: addRat pivot not in clause, skipped"
        debugRun f proof (idx + 1)
    | some (.del ids) => debugRun (Formula.delete f ids) proof (idx + 1)
  else
    IO.println s!"out of proof at idx {idx}"

def main (args : List String) : IO UInt32 := do
  match args with
  | ["--debug", cnfPath, lratPath] =>
    let txt ← IO.FS.readFile cnfPath
    match parseDimacs txt with
    | .error e => IO.println s!"LRAT_LEAN=ERROR dimacs: {e}"; return 2
    | .ok d =>
      let bytes ← IO.FS.readBinFile lratPath
      match LRAT.parseLRATProof bytes with
      | .error e => IO.println s!"LRAT_LEAN=ERROR lrat: {e}"; return 2
      | .ok proof =>
        debugRun (Std.Tactic.BVDecide.LRAT.Internal.CNF.convertLRAT d.cnf) proof 0
        return 3
  | [cnfPath, lratPath] =>
    let txt ← IO.FS.readFile cnfPath
    match parseDimacs txt with
    | .error e =>
      IO.println s!"LRAT_LEAN=ERROR dimacs: {e}"
      return 2
    | .ok d =>
      let bytes ← IO.FS.readBinFile lratPath
      match LRAT.parseLRATProof bytes with
      | .error e =>
        IO.println s!"LRAT_LEAN=ERROR lrat: {e}"
        return 2
      | .ok proof =>
        let ok := LRAT.check proof d.cnf
        IO.println s!"c vars={d.nvars} clauses={d.nclauses} lrat_actions={proof.size}"
        if ok then
          IO.println "LRAT_LEAN=VERIFIED"
          return 0
        else
          IO.println "LRAT_LEAN=REJECTED"
          return 1
  | _ =>
    IO.eprintln "usage: lratcheck <cnf> <lrat>"
    return 2
