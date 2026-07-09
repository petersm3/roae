# sat.py(1) — SAT / certificate layer for the C1–C5 constraint system

> **CLI references:** this documents **`sat.py`** (SAT / certificate layer). See also the [`solve` C binary](SOLVE_C_CLI.md) (enumerator/verifier) · [`solve.py`](SOLVE_PY_CLI.md) (analysis + ground truth) · [`roae.py`](ROAE_PY_CLI.md) (descriptive analyses).

A command-line reference for `sat.py`, the SAT-encoding and
witness-search tool for the King Wen constraint system. `sat.py`
translates the C1–C5 constraints (and literature-derived composite
rules) into DIMACS CNF, runs an external SAT solver, and decodes /
verifies the result back through `solve.py`.

## NAME

**sat.py** — emit DIMACS CNF for a named constraint target, or search
for a satisfying King Wen–shaped ordering ("witness") via an external
SAT solver, with the answer decoded and re-verified against `solve.py`
ground truth.

## SYNOPSIS

```
python3 sat.py --emit-cnf TARGET OUT.cnf [--with-c3] [--c3-max N]
python3 sat.py --witness  TARGET         [--with-c3] [--c3-max N]
```

With no recognized subcommand, `sat.py` prints its module docstring
(the full target catalogue) and exits.

## DESCRIPTION

`sat.py` is the third canonical source file of the project, alongside
`solve.c` (enumeration, sha-anchored) and `solve.py` (analysis +
ground truth). It was operator-approved 2026-07-02 to add a
SAT/certificate layer.

**Header rule (enforced by the file's own docstring):** `sat.py` must
contain **NO hand-written constraint semantics.** Every constraint it
encodes is derived from `solve.py` imports — the single source of
truth for the King Wen ground truth and C1–C5 semantics. A clause that
encodes a C-rule from scratch is "a bug by definition." Every encoding
is round-trip checked (SAT model → `decode()` → `solve.py` constraint
functions) before any UNSAT claim from it is trusted.

External solvers (`kissat` / `CaDiCaL`) run as separate binaries;
their UNSAT answers are only trusted via DRAT/LRAT certificates checked
by an independent verified checker (third-party solver use authorized
by the operator 2026-07-02).

Argument parsing is hand-rolled `sys.argv` inspection (no `argparse`);
the dispatch lives at `sat.py:565–599`.

## SUBCOMMANDS

### --emit-cnf TARGET OUT.cnf

```
python3 sat.py --emit-cnf alt-le-14 f.cnf
```

Builds the CNF for `TARGET` and writes DIMACS to `OUT.cnf` (both
positional arguments required — exactly `--emit-cnf TARGET OUT`).
Prints a `vars=… clauses=… -> OUT.cnf` summary line. The resulting
file is fed to an external `#SAT` / SAT solver (e.g.
`kissat f.cnf`). `TARGET` is one of the named constraint bundles
below.

### --witness TARGET

```
python3 sat.py --witness moore-strict
```

Builds the CNF for `TARGET`, runs `kissat -q` on it, and — if
SATISFIABLE — decodes the solver model's `v`-lines into a 64-hexagram
sequence, re-verifies it via `solve.py` (`verify_seq`), and checks the
C3 complement-distance bound (≤ 776, KW's ceiling). If the witness
fails C3 it adds a blocking clause and iterates (up to 200 attempts)
until a C3-passing witness is found or the solver returns UNSAT. On
success prints `WITNESS: [...]` (the explicit ordering); on UNSAT
prints the UNSAT line and the tail of the solver output. Requires
`kissat` on `PATH`.

## MODIFIERS

| Token | Effect |
|---|---|
| `--with-c3` | Include the C3 complement-distance constraint in the encoding (bounded at KW's C3, 776, unless `--c3-max` overrides). |
| `--c3-max N` | Include C3 and set the maximum total complement distance to `N` (implies `--with-c3`). Consumes the following token as the integer bound. |

Both modifiers may precede or follow the subcommand tokens — they are
stripped from `argv` before the subcommand is dispatched.

## TARGETS

`TARGET` names a constraint bundle over the ordering. All targets
layer on the base C1+C2+C4+C5 system (semantics imported from
`solve.py`). Highlights (see the `sat.py` module docstring for the full
catalogue and the expected SAT/UNSAT verdict of each):

| Target | Meaning (expected verdict) |
|---|---|
| `plain` | C1+C2+C4+C5 only — baseline satisfiability sanity. |
| `alt-le-14` / `alt-ge-16` | Base AND odd between-pair transitions ≤ 14 / ≥ 16 (both UNSAT ⇒ SAT-certified parity-alternation theorem; see [PARITY_ALTERNATION.md](PARITY_ALTERNATION.md)). |
| `moore-strict` | Base AND [Moore 2005](CITATIONS.md#moore2005) parity (all 18) AND [Moore 1989](CITATIONS.md#moore1989) rhythm (0 breaks) — expect SAT → explicit witness. |
| `rc4-strict` | Base AND [Schulz 1990](CITATIONS.md#schulz1990-motifs) gender/position-parity, 0 violations (semantics = `solve.rc4_violations`). |
| `grand-strict` | Moore parity + Moore rhythm + Schulz gender simultaneously ("grand unified precursor" question). |
| `grand-ccn4` / `grander-strict` | The four- / five-rule conflict decisions (#217); UNSAT proves no ordering is perfect under the combined rule set. |
| `wrap-d5` | Base AND wrap distance d(s63, s0) = 5 — the McKenna circular-reading decision (see [CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md)). |
| `*-kwtest` / `*-kwexempt` / `*-kwfail` / `*-kwchain` | Encoding-validation targets that force KW and assert the expected verdict — the two-language gate that the clauses match `solve.py` semantics. |

## EXAMPLES

Emit CNF for the parity-alternation lower branch and solve it directly:

```
python3 sat.py --emit-cnf alt-le-14 f.cnf && kissat f.cnf
```

Search for an explicit ordering satisfying both Moore rules:

```
python3 sat.py --witness moore-strict
```

Reproduce the five-rule conflict decision:

```
python3 sat.py --emit-cnf grand-ccn4 f.cnf && kissat f.cnf
```

Decide the circular (wrap-around) reading:

```
python3 sat.py --witness wrap-d5
```

Reproduce the grand-strict witness:

```
python3 sat.py --witness grand-strict
```

## EXIT STATUS

`sat.py` does not set explicit exit codes for the subcommands; the
scientific verdict is conveyed on stdout (`vars=/clauses=` summary for
`--emit-cnf`; `WITNESS: …` / `UNSAT …` for `--witness`). Trust in an
UNSAT verdict comes from an external DRAT/LRAT certificate checker, not
from `sat.py`'s own exit status.

## NOTES

- The module docstring lists a `--decode MODEL.txt` subcommand and a
  `decode()` helper is present, but the `__main__` dispatch
  (`sat.py:565–599`) only wires `--emit-cnf` and `--witness`; `--decode`
  is used internally by `--witness` rather than exposed as a standalone
  token. (purpose of the standalone form: see `sat.py:565`.)
- `sat.py` imports `solve.py` as `solve`; if you change constraint
  semantics, change them in `solve.py` — never re-encode them here.

## SEE ALSO

- [SOLVE_C_CLI.md](SOLVE_C_CLI.md) — `solve` (C) enumerator/verifier reference
- [SOLVE_PY_CLI.md](SOLVE_PY_CLI.md) — `solve.py` analysis-CLI reference (SAT encoders `--sat-encode`/`--sat-c3/c4/c5` live there too)
- [PARITY_ALTERNATION.md](PARITY_ALTERNATION.md) — parity-alternation theorem (SAT-certified via `alt-le-14`/`alt-ge-16`)
- [CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md) — circular-reading SAT decision (`wrap-d5`)
- [LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md) — literature-rule population tests + the SAT-decided exact results
- [CITATIONS.md](CITATIONS.md) — attribution ledger for the encoded literature rules
