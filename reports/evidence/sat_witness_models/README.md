# First SAT models for two `sat.py` targets (2026-09-25)

**What this is.** Two statements in the reports name a SAT solver's model without a command.
TR-6 §4 says the encoder's round-trip validation's first solver model is King Wen itself (Codex v3
review, V3B-09#6). TR-7 §"The anchors on the circle" says the R-C1c ground truth and its negative
control, the wrap-d5 SAT witness, were checked in both languages (V3B-10#14). This directory holds
the solver output for both targets.

## Reproduce

Needs `kissat` on PATH. These files came from kissat 4.0.4.

```bash
python3 sat.py --witness plain   > sat_witness_plain.out 2>&1
python3 sat.py --witness wrap-d5 > sat_witness_wrapd5.out 2>&1
```

Each takes about a second.

## Result

- `plain` (C1+C2+C4+C5): `attempt 0` returns a model that decodes to `solve.py`'s
  `binary_hexagrams`, i.e. King Wen, with `c3=776`. Checked by comparing the `WITNESS:` list
  with `solve.binary_hexagrams`: equal, all 64 entries.
- `wrap-d5` (C1+C2+C4+C5 and a 5-line wrap): `attempt 0` returns a C1–C5-valid ordering that ends
  on the pair (32, 1), with `c3=752`. This is the witness TR-7 §5 describes.

Both languages' R-C1c indicator on these two orderings:

```bash
./solve --rc1c-verify                 # King Wen: rc1c_slot2: 0 OK / rc1c_slot32: 1 OK / rc1c_adjacent: 1 OK / RC1C VERIFY: PASS
python3 solve.py --rc1c-verify        # the same four lines
./solve --rc1c-verify "<wrap-d5 WITNESS list>"          # 0,0,0
python3 solve.py --rc1c-verify "<wrap-d5 WITNESS list>" # 0,0,0
```

`<wrap-d5 WITNESS list>` is the 64 integers of the `WITNESS:` line in `sat_witness_wrapd5.out`,
comma-separated.

**Scope.** Which model a SAT solver returns first depends on the solver, its version and its
settings. That King Wen comes first for `plain` is an observation about kissat 4.0.4 on this
encoding, not a property of the encoding.

## Provenance

Run 2026-09-25 on a 16-core x86-64 Linux worker, Python 3.12.3, kissat 4.0.4. `sat.py` sha256
`7d37ecc73286c1036ba18107b962eed3221546e9ab5c040be18af7a256a63be1`, `solve.py` sha256
`73a65852122dbfaf6bf46578607529fb14641199cd41992bfa8fe3e5a93ae94a`. The two `.out` files are the
unedited stdout and stderr of the commands above.
