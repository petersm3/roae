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
python3 sat.py --emit-cnf TARGET OUT.cnf [--with-c3] [--c3-max N] [--f1-pairs N]
python3 sat.py --decode   MODEL.txt [TARGET]        [--with-c3] [--c3-max N] [--f1-pairs N]
python3 sat.py --witness  TARGET                    [--with-c3] [--c3-max N]
python3 sat.py --certify-count TARGET               [--f1-pairs N]
                                                    [--expect N] [--keep DIR]
```

With no recognized subcommand, `sat.py` prints its module docstring
(the full target catalogue) and exits.

## EXTERNAL-BINARY REQUIREMENTS (all optional)

`sat.py` itself is stdlib-only Python: `--emit-cnf` and `--decode` need
**no** third-party binaries. Two subcommands invoke optional external
tools and **exit gracefully with a clear install message** (never a
traceback) if the tool is not on `PATH`:

| Subcommand | Requires on `PATH` | Role |
|---|---|---|
| `--witness` | [`kissat`](https://github.com/arminbiere/kissat) | external SAT solver for the witness-search loop |
| `--certify-count` | [`d4`](https://github.com/crillab/d4) **and** `cpog-gen` + `cpog-check` ([CPOG](https://github.com/rebryant/cpog)) | d-DNNF compilation + certified model counting |

No other part of `sat.py` (or of the project's Python layer) needs any
of these; everything else works without them.

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
the dispatch lives in the `__main__` block at the bottom of the file.

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

### --decode MODEL.txt [TARGET]

```
python3 sat.py --decode model.txt plain
python3 sat.py --decode model.txt --f1-pairs 13
```

Rebuilds the CNF for `TARGET` (default `plain`, or the reduced subset when
`--f1-pairs N` is given) to recover the variable map, parses the model
(`v`-lines, or a bare whitespace/newline-separated list of signed integers),
decodes the true position variables into a hexagram sequence, and re-verifies
it against `solve.py` ground truth. For a full-31 target it prints the
64-hexagram sequence, `verify=…`, and the C3 complement distance; for a
`--f1-pairs N` subset it prints the 2N-hexagram sequence and the per-class
boundary histogram against the derived budget `B0`. This is the standalone
form of the `decode()` helper the `--witness` loop uses internally.

### --emit-cnf … --f1-pairs N

```
python3 sat.py --emit-cnf f1c5 n13.cnf --f1-pairs 13
```

Emits the **reduced** C1∩C2∩C4∩C5 instance for the group-closed N-pair orbit
union (`N ∈ {9,13,16,18,19,24,25,27,28}`) — exactly the object that
`solve --f1-exact-c1c2c4c5 --f1-pairs N` counts. The C5 budget `B0` (the target
boundary distance-class multiset) is derived per subset from `solve.py`
semantics via the deterministic first-completion DFS (a port of `solve.c`'s
`f1c5_derive_b0`/`f1c5_b0_dfs`); the print line reports the pair list,
`start_exit`, and `B0`. This is the small-n certified-count probe instance
(TASK #225 §6.4): a scale at which a proof-emitting `#SAT` counter (D4/CPOG)
can compile a certificate, cross-checked against the exact DP count.

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
prints the UNSAT line and the tail of the solver output. **Requires
`kissat` on `PATH`** (see the requirements table above); if it is
missing, `sat.py` exits with a clear install message.

### --certify-count TARGET

```
python3 sat.py --certify-count f1c5 --f1-pairs 9 --expect 26112
python3 sat.py --certify-count plain --keep certs/plain
```

Produces an **independently certified model count** of the `TARGET`
CNF (or, with `--f1-pairs N`, of the reduced small-n probe instance —
the object `solve --f1-exact-c1c2c4c5 --f1-pairs N` counts).

> **Model-count-safe targets only:** `--certify-count` refuses
> `--with-c3` / `--c3-max` and `*-near-k` targets. The C3 encoding's
> auxiliary `X` variables are deliberately one-directional (an unforced
> `X` may float true, multiplying the model count), and near-k targets
> leave bare at-most/at-least cardinality registers undetermined — the
> tool would certify a count that is valid **for the CNF** but is *not*
> the count of orderings. Plain/exact-k targets (all auxiliary
> variables functionally determined) are safe and accepted.

> **External dependency (this subcommand only):** `--certify-count`
> requires the **D4** d-DNNF compiler
> (<https://github.com/crillab/d4>) and the **CPOG** toolchain's
> `cpog-gen` / `cpog-check`
> (<https://github.com/rebryant/cpog>; Bryant, Nawrocki & Avigad,
> SAT 2023) on `PATH`. If any of the three binaries is missing, the
> subcommand exits gracefully with an install message — **the rest of
> `sat.py` works without them**, exactly as `kissat` is required only
> by `--witness`.

Pipeline: (1) emit the DIMACS CNF (the same `build()` /
`build_subset()` machinery as `--emit-cnf`); (2) `d4 -dDNNF … -out=…`
compiles it to Decision-DNNF; (3) `cpog-gen` derives a CPOG
certificate from the CNF + d-DNNF; (4) `cpog-check` verifies the
certificate **against the original CNF** and reports the model count.
The count printed as `CERTIFIED count=…` is `cpog-check`'s — it is
trusted because the certificate is checked independently of the
compiler, the same trust model as the DRAT/LRAT-checked UNSAT
verdicts. D4's own (uncertified) count is cross-checked against it
when parseable; a disagreement is a hard error.

With `--expect N` (the reference count, e.g. from
`solve --f1-exact-c1c2c4c5 --f1-pairs N` — `sat.py` never invokes the
C binary itself) it prints `PASS`/`FAIL` and exits non-zero on `FAIL`.
With `--keep DIR` the `instance.cnf` / `instance.nnf` /
`instance.cpog` artifacts are preserved in `DIR` instead of a deleted
temp directory.

## MODIFIERS

| Token | Effect |
|---|---|
| `--with-c3` | Include the C3 complement-distance constraint in the encoding (bounded at KW's C3, 776, unless `--c3-max` overrides). |
| `--c3-max N` | Include C3 and set the maximum total complement distance to `N` (implies `--with-c3`). Consumes the following token as the integer bound. |
| `--f1-pairs N` | Build the reduced C1∩C2∩C4∩C5 instance for the group-closed N-pair orbit union (`N ∈ {9,13,16,18,19,24,25,27,28}`) instead of the full-31 system — the object `solve --f1-exact-c1c2c4c5 --f1-pairs N` counts. Applies to `--emit-cnf`, `--decode` and `--certify-count`. The C5 budget `B0` is derived per subset. Consumes the following token as the integer `N`. |
| `--expect N` | (`--certify-count` only) Assert the certified count equals `N` (the caller-supplied native reference count); prints `PASS`/`FAIL` and exits non-zero on `FAIL`. Consumes the following token as the integer `N`. |
| `--keep DIR` | (`--certify-count` only) Preserve the `instance.cnf`/`.nnf`/`.cpog` artifacts in `DIR` (created if needed) instead of a removed temporary directory. Consumes the following token as the directory path. |

All modifiers may precede or follow the subcommand tokens — they are
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
| `wrap-d5` | Base AND wrap distance d(s63, s0) = 5 — the [McKenna](CITATIONS.md#mckenna-mckenna1975) circular-reading decision (see [CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md)). |
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

Certified count of the N=9 probe instance, checked against the native
reference count (requires `d4` + `cpog-gen`/`cpog-check` on `PATH`):

```
python3 sat.py --certify-count f1c5 --f1-pairs 9 --expect 26112
```

## EXIT STATUS

`sat.py` does not set explicit exit codes for most subcommands; the
scientific verdict is conveyed on stdout (`vars=/clauses=` summary for
`--emit-cnf`; `WITNESS: …` / `UNSAT …` for `--witness`). Trust in an
UNSAT verdict comes from an external DRAT/LRAT certificate checker, not
from `sat.py`'s own exit status. Exceptions: `--certify-count` exits
non-zero on a `--expect` `FAIL`, on any toolchain failure, and (like
`--witness` with `kissat`) when its required external binaries are not
on `PATH` — the latter with a clear install message.

## NOTES

- `--decode MODEL.txt [TARGET]` is now wired in `__main__` as a standalone
  subcommand (it decodes/re-verifies a solver model; `--witness` uses the same
  `decode()` helper internally).
- `--f1-pairs N` reduced-subset instances derive two *parameters* — the
  group-closed pair-orbit partition and the C5 budget `B0` — from `solve.py`
  primitives, ported from `solve.c`'s `f1c5` path. As with every target, no
  constraint clause is hand-written; the reduced B0 values and reference counts
  are pinned in `tests.py` (`TestSatC5Subset`); `--certify-count` is the
  proof-emitting `#SAT` side of the model-count cross-check at these N
  (the C-binary side is `solve --f1-exact-c1c2c4c5 --f1-pairs N`, run
  separately). The D4/CPOG invocation format is pending run-validation on a
  host with the tools built (the absent-tools graceful path is gated in
  `tests.py`); no certified count from it has been recorded yet.
- `sat.py` imports `solve.py` as `solve`; if you change constraint
  semantics, change them in `solve.py` — never re-encode them here.

## SEE ALSO

- [SOLVE_C_CLI.md](SOLVE_C_CLI.md) — `solve` (C) enumerator/verifier reference
- [SOLVE_PY_CLI.md](SOLVE_PY_CLI.md) — `solve.py` analysis-CLI reference (SAT encoders `--sat-encode`/`--sat-c3/c4/c5` live there too)
- [PARITY_ALTERNATION.md](PARITY_ALTERNATION.md) — parity-alternation theorem (SAT-certified via `alt-le-14`/`alt-ge-16`)
- [CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md) — circular-reading SAT decision (`wrap-d5`)
- [LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md) — literature-rule population tests + the SAT-decided exact results
- [CITATIONS.md](CITATIONS.md) — attribution ledger for the encoded literature rules
