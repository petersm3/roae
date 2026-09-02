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
python3 sat.py --emit-cnf TARGET OUT.cnf [--with-c3] [--c3-max N] [--c3-min N] [--not-kw] | [--f1-pairs N]
python3 sat.py --decode   MODEL.txt [TARGET]        [--with-c3] [--c3-max N] [--c3-min N] [--not-kw] | [--f1-pairs N]
python3 sat.py --witness  TARGET                    [--with-c3] [--c3-max N] [--c3-min N] [--not-kw]
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
| `--certify-count` | [`d4`](https://github.com/crillab/d4) **and** `cpog-gen` + `cpog-check` ([CPOG](https://github.com/rebryant/cpog)) **and**, transitively via `cpog-gen`, `cadical` + `drat-trim` — five binaries | d-DNNF compilation + certified model counting |

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

⚠ **The rule is the file's stated policy, and it currently has two measured
exceptions.** No *clause* is hand-written, but two C5 *parameter* tables are
hard-coded rather than derived: `sat.py:139` `BETWEEN_MULTISET`, which builds
the C5 CNF, and `sat.py:143` `_tot`, the round-trip verifier's acceptance
multiset. Both are **correct today** — re-derived clean-room on 2026-09-01 from
`solve.binary_hexagrams` and `solve.bit_diff` alone, giving exactly
`{1:2, 2:8, 3:13, 4:7, 6:1}` and `{1:2, 2:20, 3:13, 4:19, 6:9}` respectively.
But the in-file guard at `sat.py:152-154` ties only their *difference* to the
derived within-pair multiset, so an equal edit to both passes it: adding 1 to
the `d = 2` entry of each literal was measured on 2026-09-01 to satisfy the
guard. Deriving both from `solve.py` is a three-line change with no interface
impact; until it lands, read the header rule as holding for clauses, and as
guarded-but-not-derived for these two tables. *(Caveat added 2026-09-01.)*

External solvers (`kissat` / `CaDiCaL`) run as separate binaries; their
UNSAT answers are only trusted via DRAT/LRAT certificates checked by an
independent checker. Two are used, and their trust status differs — the
distinction matters, so it is stated rather than blurred:

* **drat-trim** is the checker `verify_all.sh` runs. It is independent of
  the solver but is **not itself formally verified**; it is an ordinary C
  program with a soundness-fix history.
* **cake_lpr** is *formally verified* — its soundness is machine-checked in
  HOL4 down to the machine code. On 2026-07-27 the full 21-certificate
  archive passed `drat-trim → LRAT → cake_lpr` (pinned commit
  `a36874a8b750b43fe4b385b8ddbf5b033e46a3fa`), a chain in which drat-trim
  is an **untrusted elaborator**: cake_lpr checks the LRAT against the
  regenerated CNF directly, so a bad elaboration can only be rejected.

An UNSAT claim resting on drat-trim alone is therefore scoped by an
unverified checker; the archived 21 additionally carry a formally verified
one. (Third-party solver use authorized by the operator 2026-07-02.)

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
it against `solve.py`'s **base** ground truth — C1 (permutation), C2 (no
distance-5 step) and the C5 transition multiset, via `verify_seq`. For a
full-31 target it prints the 64-hexagram sequence, `verify=…`, and the C3
complement distance; for a `--f1-pairs N` subset it prints the 2N-hexagram
sequence and the per-class boundary histogram against the derived budget `B0`.
This is the standalone form of the `decode()` helper the `--witness` loop uses
internally.

⚠ **`verify=True` does not mean the model satisfies `TARGET`.** The target's
literature rules are re-scored and *printed* on the next line, but are **not**
folded into `verify=` or into the exit status. Measured 2026-09-01: a King Wen
model built under `plain` and decoded as `grand-strict` prints
`verify=True  c3=776  c3<=776 PASS` above
`moore-parity-viol=2 rhythm-breaks=2 gender-viol=2`, and exits 0 — although
`grand-strict` requires all three of those scores to be zero. `--witness` does
enforce them (`sat.py:1535-1539`); `--decode` does not. *(Scope added
2026-09-01: the ground-truth claim on the line above was previously
unqualified, immediately after naming `TARGET`.)*

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

### --rigidity-cnf OUT.cnf [--run]

```
python3 sat.py --rigidity-cnf rigidity.cnf
python3 sat.py --rigidity-cnf rigidity.cnf --run   # requires kissat; drat-trim optional
```

⚠ **Measured 2026-09-01: the second form exits 1 and writes nothing.** The
global unrecognised-flag guard added 2026-08-28 (`sat.py:1406-1409`) rejects
`--run` before dispatch, printing `unrecognised flag(s): --run`. The `--run`
implementation is intact but unreached (`sat.py:1557-1578` — `kissat`
preflight, `kissat -q`, an expected-UNSAT assertion, and the optional
`drat-trim` leg). Until the guard is taught this flag, emit the CNF with the
first form and run `kissat` and `drat-trim` yourself. *(Behaviour note added
2026-09-01; the paragraph below describes the intended, currently unreachable
path.)*

TR-5 v2.0 symmetry-completeness rigidity kernel **[expect UNSAT]**: a
bijection on the 64 hexagrams that is edge-preserving on the
Hamming-distance-5 graph (adjacency derived from `solve.bit_diff` — no
hand-written semantics), fixes 0 and its six distance-5 neighbors
pointwise, yet differs from the identity. 4,096 vars, 282,760 clauses.
The encoding is deliberately RELAXED (bijection + one-directional
edge-support only) so its UNSAT is a-fortiori sufficient for the
theorem's kernel. Emission self-validates (the identity assignment must
satisfy every clause except the final not-identity clause) and refuses
to write on failure. With `--run` (see the caveat above): kissat
decides (UNSAT expected, DRAT proof written to `OUT.cnf.drat`), then
`drat-trim` verifies the proof if present on PATH (else the proof is
emitted unverified with an explicit message). Prose + the exhaustive non-SAT machine check of the
same kernel: [SYMMETRY_SEARCH.md §Completeness](SYMMETRY_SEARCH.md) and
`solve.py --symmetry-completeness` (gate SC-4).

### --certify-count TARGET

```
python3 sat.py --certify-count f1c5 --f1-pairs 9 --expect 26112
python3 sat.py --certify-count plain --keep certs/plain
```

Produces an **independently certified model count** of the `TARGET`
CNF (or, with `--f1-pairs N`, of the reduced small-n probe instance —
the object `solve --f1-exact-c1c2c4c5 --f1-pairs N` counts).

> **Model-count-safe targets only:** `--certify-count` refuses
> `--with-c3` / `--c3-max` / `--c3-min` / `--not-kw` and `*-near-k` targets. The C3 encoding's
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
> (<https://github.com/rebryant/cpog>; Bryant, Nawrocki, Avigad
> & Heule, SAT 2023) on `PATH` — and, transitively, **`cadical` and `drat-trim`**,
> which `cpog-gen` shells out to. That is **five** binaries, not three:
> measured 2026-08-20, with `drat-trim` absent the n=9 run fails
> (`sh: 1: drat-trim: not found`, rc=1) and no certificate is produced.
> If any of the five is missing, the subcommand exits gracefully with an
> install message — **the rest of `sat.py` works without them**, exactly
> as `kissat` is required only by `--witness`.

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
| `--c3-max N` | Include C3 and set the maximum total complement distance to `N` (implies `--with-c3`). Values below the structural minimum C3 = 112 (2·8 self-complementary pairs + 8·12 complement couples at slot distance ≥ 1) are refused with a non-zero exit: no C1 layout attains them, and the unary ladder cannot represent such a bound. Consumes the following token as the integer bound. ⚠ Measured 2026-09-01: unless `--c3-min` is **also** given, `--c3-max N` bounds the **CNF** only — the `--decode` printer (`sat.py:1456`) and the `--witness` acceptance test (`sat.py:1540`) both fall back to a hard-coded `c3 ≤ 776`, so a model with C3 in 777–`N` is reported `fail C3` and, in `--witness`, blocked out and retried. Supplying `--c3-min` (e.g. `--c3-min 112`) selects the arm that does honour `--c3-max`. |
| `--c3-min N` | Encode C3 ≥ `N` (the ≥ side of the unary couple-distance ladder). Does **not** imply the ≤ 776 ceiling — combine with `--c3-max` to window C3 exactly. Unlike the relaxed one-directional ≤ encoding, the ≥ side is exact (two-sided X↔Y binding plus spurious-true-distance-lit kill clauses), so a model's ladder value equals the decoded ordering's true couple-distance sum. Used by the C3 positional certificates (above-ceiling witness `--c3-min 784`, i.e. G ≥ 96; the G = 95 tie witness via `--c3-min 776 --c3-max 776`; and the `kw-pin --c3-min 777` KW-exactness UNSAT gate). Consumes the following token as the integer bound. |
| `--not-kw` | Exclude every ordering whose pair-slot **layout** matches King Wen's (slot s = pair s for all s) — KW itself and all its within-pair orientation variants. Since the excluded set contains KW, any witness is ≠ KW, and stronger: it places at least one pair in a non-KW slot (G is orientation-blind, so an orientation-only variant would tie G trivially). |
| `--f1-pairs N` | Build the reduced C1∩C2∩C4∩C5 instance for the group-closed N-pair orbit union (`N ∈ {9,13,16,18,19,24,25,27,28}`) instead of the full-31 system — the object `solve --f1-exact-c1c2c4c5 --f1-pairs N` counts. Applies to `--emit-cnf`, `--decode` and `--certify-count` (not `--witness`). The C5 budget `B0` is derived per subset. Refuses combination with `--with-c3`/`--c3-max`/`--c3-min`/`--not-kw`: the subset instances encode C1&C2&C4&C5 only (before 2026-08-27 those flags were silently ignored here). Consumes the following token as the integer `N`. |
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
| `grand-ccn4` / `grander-strict` | The four- / five-rule conflict decisions (#217); UNSAT proves no **C1∩C2∩C4∩C5-valid** ordering is perfect under the combined rule set (the base is stated in the table preamble; repeated here because this row is often quoted alone). |
| `wrap-d5` | Base AND wrap distance d(s63, s0) = 5 — the [McKenna](CITATIONS.md#mckenna-mckenna1975) circular-reading decision (see [CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md)). |
| `ccn4-kwtest` / `ccn4-kwfail` | CC-N4 encoding validation, both KW-forced: `ccn4-kwtest` adds the ccn4 clauses as-is (expect **SAT** — KW satisfies CC-N4); `ccn4-kwfail` permutes the required S25–S28 face hexagrams (S25↔S26 and S27↔S28 values swapped) so KW mismatches all four stations (expect **UNSAT**). The required faces are derived at import from `solve.reg_ccn4`/`solve._reg_stations` (not hand-written), and the negative gate catches an over-constrained ccn4 encoding that a SAT-expected gate alone cannot. |
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
  separately). The D4/CPOG invocation format is
  **run-validated**: 2026-08-20, and independently reproduced 2026-08-26 on a
  separate host with the toolchain rebuilt from source, giving a **certified
  n=9 count of 26,112**, agreeing with the native reference; the `--expect`
  control has been shown able to fail (2026-08-26, `--expect 26113` →
  `expect=26113 certified=26112  FAIL`, exit 1). The certificate itself is
  **not shipped** — the n=9 `instance.cpog` is 1,392,854,105 B — so it is
  identified by hash instead: `instance.cpog` sha256
  `b311715fcc4e225fb7dfc2e444141aa1011739b23b9d017fa94ba4843921a087`,
  `instance.cnf` (71,429 B) sha256
  `800fde577c86e99ed611ebc6088c49a083169b8c6ffeb510df1a965946335f16`, and
  `instance.nnf` (1,834,177 B) sha256
  `2317b6c2bc813c287f07465aa3d0119c46cf4537b7da4cf814d3f8cb03d7ddc8`,
  produced with
  **d4 v1 `333370cc`, CPOG `a97ed854`, cadical `c6073042`, drat-trim
  `2e3b2dc0`** under gcc 13.3.0, `cpog-check` reporting FULL-PROOF SUCCESS.
  Regenerate with `--certify-count f1c5 --f1-pairs 9 --keep DIR` and compare
  the sha. *(Artifact identification added 2026-09-01; the two run dates above
  previously stood without any hash or toolchain pin.)*
  **No certified count exists at n=13** — `d4` v1 (crillab `333370cc`, which
  was upstream v1 HEAD when checked on 2026-08-21, so no upstream fix exists)
  overflows a **signed 32-bit index in its DAG storage**: `idxUnitLit` in
  `DAG/Branch.hh`, which holds the return of `saveUnitLit` in `DAG/DAG.hh`. It
  segfaults after 298,549,248 DAG nodes (13,185 s), before writing the n=13
  d-DNNF; a wrapped node count of -84,627,967 was observed at the crash. So
  2,063,395,607,040 remains an engine/DP result and must not acquire
  "certified" by proximity. (The absent-tools graceful path is gated in
  `tests.py`.) *(Diagnosis attributed to a named source symbol and a pinned
  commit 2026-09-01; it was previously asserted with neither.)*
- `sat.py` imports `solve.py` as `solve`; if you change constraint
  semantics, change them in `solve.py` — never re-encode them here.

## SEE ALSO

- [SOLVE_C_CLI.md](SOLVE_C_CLI.md) — `solve` (C) enumerator/verifier reference
- [SOLVE_PY_CLI.md](SOLVE_PY_CLI.md) — `solve.py` analysis-CLI reference (SAT encoders `--sat-encode`/`--sat-c3/c4/c5` live there too)
- [PARITY_ALTERNATION.md](PARITY_ALTERNATION.md) — parity-alternation theorem (SAT-certified via `alt-le-14`/`alt-ge-16`)
- [CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md) — circular-reading SAT decision (`wrap-d5`)
- [LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md) — literature-rule population tests + the SAT-decided exact results
- [CITATIONS.md](CITATIONS.md) — attribution ledger for the encoded literature rules
