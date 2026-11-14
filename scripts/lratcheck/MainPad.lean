/-
lratcheck_padded — the same checker as `lratcheck` (Main.lean, which stays byte-identical to the
copy that ran), for proofs whose lemmas use variables ABOVE the CNF's maximum variable (solver
extension / factoring variables, as kissat 4.0.1 emits them).

Why a second driver exists: the Lean 4 (v4.31.0) LRAT checker sizes its internal formula from the
CNF alone (`CNF.convertLRAT cnf : DefaultFormula (cnf.numLiterals + 1)`, Internal/Convert.lean) and
`intActionToDefaultClauseAction` turns every proof step naming a variable outside that range into
`none`, which `compactLratChecker.go` skips; the first later hint that names the skipped lemma then
fails, so a valid proof with extension variables is REJECTED. This driver appends ONE tautological
clause `[(v, true), (v, false)]` on `v` = the proof's maximum variable to the parsed CNF, which
raises `numLiterals` to cover the proof. `DefaultClause.ofArray` returns `none` for a clause holding
both polarities of a variable, and `CNF.convertLRAT'` is a `filterMap`, so the tautology is dropped
WITHOUT a placeholder (no LRAT id shifts; it is the LAST clause anyway). The theorem below carries
the checker's verdict back to the ORIGINAL CNF: `unsat_of_padTaut_unsat` is proved here, and
`lratcheck_padded_relies_on` chains it to the library's `LRAT.check_sound`, so the printed verdict
is about the CNF as parsed, not about the padded formula.

Second gap this driver closes (found 2026-11-12 on core_gender_ccn4_unsat, 268 of its 1,298 core
lemmas): drat-trim -L writes a RAT lemma that has NO resolution candidate — a fresh-variable
definition clause, the first clause naming a factoring variable — as `id lits 0 0`. The LRAT text
format cannot say "RAT step with zero candidates" apart from "RUP step with zero hints", and the
library parser (Parser.lean, parseRat: `| _, 0 => return .addRup ...`) reads the line as a RUP step
with no hints, which `performRupAdd` cannot accept. `readVacuousRat` below reads such an action the
way drat-trim meant it: a RAT step on the first literal with no candidates. `performRatAdd` accepts
that iff `ratHintsExhaustive` holds, i.e. iff NO clause of the current formula contains the negated
pivot, and rejects it otherwise, so the rewrite can only turn a rejection of a genuine vacuous RAT
step into an acceptance. It edits the proof object, which `check_sound` quantifies over; it cannot
produce a wrong verdict, only change which valid proofs are accepted.

usage: lratcheck_padded <piece.cnf> <proof.lrat>
exit 0 + line `LRAT_LEAN=VERIFIED`  iff  LRAT.check proof (padTaut cnf v) = true, v = proof's max var
exit 1 + line `LRAT_LEAN=REJECTED`  otherwise (checker returned false)
exit 2 + line `LRAT_LEAN=ERROR ...`  on a parse/IO error (never a verdict)
Also prints `c pad: cnf_maxvar=<DIMACS> proof_maxvar=<DIMACS> padded=yes|no` (padded=yes iff the
proof's maximum variable exceeds the CNF's; when it does not, the padded formula converts to the
same internal formula as the plain one and the two drivers compute the same thing).
usage: lratcheck_padded --dump-dimacs <piece.cnf>
  Parses the CNF with the same parser and prints it back as DIMACS (`p cnf <nvars> <nclauses>`,
  then each clause's literals in file order, single spaces, `0`-terminated, no comments): the
  parser round-trip control, so a test can byte-compare the re-emitted text with the source CNF
  minus its comment lines. Exit 0, or exit 2 with `LRAT_LEAN=ERROR dimacs: ...` on a parse error.
  This mode never prints a verdict line and never runs the checker.

Trusted outside the theorem (a defect here CAN make the printed verdict wrong about the file; only
the library LRAT parser is harmless, since `check_sound` holds for every proof): the DIMACS parser (copied byte for byte from Main.lean lines 28-103 —
the block between `structure Dimacs` and the end of `parseDimacs`; Main.lean cannot be imported
because both files must define `main`), the library LRAT parser
(Std.Tactic.BVDecide.LRAT.parseLRATProof), the Lean compiler + runtime, file I/O.
Variable convention as in Main.lean: DIMACS variable v (1-based) is the `CNF Nat` variable v-1.
-/
import Std.Tactic.BVDecide.LRAT.Checker
import Std.Tactic.BVDecide.LRAT.Parser

open Std.Sat
open Std.Tactic.BVDecide

/-- `cnf` with one tautological clause on variable `v` appended (as the LAST clause). -/
def padTaut (cnf : CNF Nat) (v : Nat) : CNF Nat := cnf ++ { clauses := #[[(v, true), (v, false)]] }

/-- The padding lemma: a tautology is true under every assignment, so if the padded formula is
unsatisfiable the original one is. Proved, not assumed. -/
theorem unsat_of_padTaut_unsat (cnf : CNF Nat) (v : Nat) : (padTaut cnf v).Unsat → cnf.Unsat := by
  intro h a
  have h1 := h a
  simp only [padTaut, CNF.eval_append, Bool.and_eq_false_iff] at h1
  rcases h1 with h1 | h1
  · exact h1
  · exfalso
    simp [CNF.eval, CNF.Clause.eval] at h1

/-- The exact statement relied on: the library's `check_sound` on the padded formula, chained to
the padding lemma, so the conclusion is about the ORIGINAL `cnf`. -/
theorem lratcheck_padded_relies_on (proof : Array LRAT.IntAction) (cnf : CNF Nat) (v : Nat) :
    LRAT.check proof (padTaut cnf v) = true → cnf.Unsat :=
  fun h => unsat_of_padTaut_unsat cnf v (LRAT.check_sound proof (padTaut cnf v) h)

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

/-- The proof's maximum variable (DIMACS, 1-based), over every literal and pivot of every action;
0 for a proof that names no variable. -/
def proofMaxVar (proof : Array LRAT.IntAction) : Nat :=
  proof.foldl (init := 0) fun acc a =>
    match a with
    | .addEmpty _ _ => acc
    | .addRup _ c _ => c.foldl (fun m l => max m l.natAbs) acc
    | .addRat _ c pivot _ _ => c.foldl (fun m l => max m l.natAbs) (max acc pivot.1)
    | .del _ => acc

/-- drat-trim's `id lits 0 0` (a RAT step with no resolution candidate) parses as `addRup` with no
hints; read it as `addRat` with no RAT hints (pivot = first literal, as the LRAT format fixes it).
See the header. Actions with hints, deletions and the empty clause are untouched. -/
def readVacuousRat (a : LRAT.IntAction) : LRAT.IntAction :=
  match a with
  | .addRup id c hints =>
    if h : hints.isEmpty ∧ 0 < c.size then
      let p := c[0]'h.2
      .addRat id c (p.natAbs, decide (p > 0)) #[] #[]
    else a
  | a => a

/-- The CNF's maximum variable (DIMACS, 1-based) over its clauses; 0 for an empty formula. -/
def cnfMaxVar (cnf : CNF Nat) : Nat :=
  cnf.clauses.foldl (init := 0) fun acc c => c.foldl (fun m l => max m (l.1 + 1)) acc

def main (args : List String) : IO UInt32 := do
  match args with
  | ["--dump-dimacs", cnfPath] =>
    let txt ← IO.FS.readFile cnfPath
    match parseDimacs txt with
    | .error e =>
      IO.println s!"LRAT_LEAN=ERROR dimacs: {e}"
      return 2
    | .ok d =>
      let h ← IO.getStdout
      h.putStrLn s!"p cnf {d.nvars} {d.nclauses}"
      for c in d.cnf.clauses do
        let lits := c.map fun l => if l.2 then s!"{l.1 + 1}" else s!"-{l.1 + 1}"
        h.putStrLn (" ".intercalate (lits ++ ["0"]))
      return 0
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
      | .ok proof0 =>
        let proof := proof0.map readVacuousRat
        let nVac := proof0.foldl (init := 0) fun k a => match a with
          | .addRup _ c hints => if hints.isEmpty && 0 < c.size then k + 1 else k
          | _ => k
        let pm := proofMaxVar proof
        let cm := cnfMaxVar d.cnf
        -- DIMACS variable pm is `CNF Nat` variable pm - 1 (pm = 0 pads on variable 0: harmless).
        let padded := padTaut d.cnf (pm - 1)
        let ok := LRAT.check proof padded
        IO.println s!"c vars={d.nvars} clauses={d.nclauses} lrat_actions={proof.size}"
        IO.println s!"c pad: cnf_maxvar={cm} proof_maxvar={pm} padded={if pm > cm then "yes" else "no"} vacuous_rat_steps={nVac}"
        if ok then
          IO.println "LRAT_LEAN=VERIFIED"
          return 0
        else
          IO.println "LRAT_LEAN=REJECTED"
          return 1
  | _ =>
    IO.eprintln "usage: lratcheck_padded <cnf> <lrat>"
    return 2
