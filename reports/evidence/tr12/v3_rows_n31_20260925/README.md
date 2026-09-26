# TR-12 evidence — the V3 battery rows at n=31, run standalone on 2026-09-25

**What this is.** On 2026-09-25 the TR-12 battery's four V3 rows, **and only those rows**, were run
against the full-31 f ladder, read-only. They reproduced the committed rank grid and the committed
spectrum byte for byte, and all four V3 verdicts came back `PASS`:

    TR12_V3_TSV=PASS
    TR12_V3_FIG=PASS
    TR12_VIZ=PASS
    TR12_V3=PASS

**What this is not.** It is **not a full n=31 battery run.** The full re-run was deferred, and a
small targeted run was done in its place. The published receipt of the last full run,
[`../VERDICTS_n31_20260922.txt`](../VERDICTS_n31_20260922.txt), is unchanged. It still reads
`TR12_V3_FIG=PENDING:viz-v3-spectrum` and `TR12_V3=SKIP:leg-TR12_V3_FIG`, because that is what was
true when that run executed: on 2026-09-22 no battery row ran the V3 join. This directory sits beside
that receipt. It does not replace it.

## What was run

`run_v3_rows.sh` (in this directory) runs the battery's V3 rows in battery order:

1. `a1_v3`: 1000 serial `solve --kc-unrank FDIR R` calls on the grid `R = i·⌊N/1000⌋`, which gives
   the rank grid.
2. `c_v3_join`: `python3 solve.py --v3-spectrum GRID <consumer>/spectrum/v3_spectrum.tsv`.
3. `c_viz`: the battery's render step, `viz/report_figures.py`.
4. `v3_fig_verdict`, then `agg TR12_V3 TR12_V3_TSV TR12_V3_FIG`.

**The row code is not re-implemented.** At run time the driver cuts each piece out of
`scripts/tr12_repro.sh` with awk ranges keyed on literal lines, checks that it parses, and sources
it. The pieces are the battery's own `norm()`, row and token machinery (`row_end` is the golden
diff), knob block, the four rows above, `agg()` and the VERDICTS loop. `VERDICTS.txt` records each
extracted range with a sha256 prefix, as `V3ROWS_EXTRACT_<piece>=lines:a-b:sha256:…`.

What stands in for the rest of the battery (the only differences from a battery run):

- **Ladder.** Only `a1_v3` reads a ladder, and it needs only the f ladder. The driver refuses to
  start unless that ladder is on a read-only mount (`V3ROWS_RO=PASS`). It also checks at the end
  that nothing under it is newer than the start mark (`V3ROWS_LADDER_UNMODIFIED=YES`).
- **Universe.** `N_PAIRS` and `N_TOTAL` come from `solve --kc-count FDIR`, parsed with the
  battery's own sed lines: `n=31`, `N = 1097051278789181790036112071176579186688`, `V3K=1000`.
- **Golden.** The expected block for `a1_v3` is the committed `tr12/v3_rel_grid.tsv`. The
  battery's own `row_end` diffed the fresh grid against it. The other two rows have no n=31
  golden, so they were written, not diffed (`[MINT]` in `run.log`). Their verdicts rest on the
  exit status, `V3_SPECTRUM=PASS`, and the spectrum's sha check below.
- **Consumer inputs.** The consumer directory was seeded from the committed `tr12/scan/` and
  `tr12/q3_profile_kw.tsv`. The atlas consumer was not re-run. **So `TR12_VIZ=PASS` here means
  that the render step drew all five figures from the committed consumer tables; it does not mean
  those tables were recomputed.** Only V3 was recomputed end to end: a fresh ladder grid, then a
  fresh join, then a fresh V3 render.

## On what code

| input | sha256 |
|---|---|
| `scripts/tr12_repro.sh` (pinned; the driver refuses any other) | `fdfa94bf009193e04044b1fe15bfa80bad9eea6c9d4f44072900b10f05c0c154` |
| `solve.py` (pinned) | `7b4447177d6709731100ae02f10fd3eac084074ef5ca114acb9741c0232bfc04` |
| `viz/report_figures.py` (recorded, not pinned) | `76a4923372d98cf9f96c25368dda706e68e004a7953ff76260188cf363e53315` |
| `solve` binary (build-host-specific; built from the run host's clone of public main `47f432c2`) | `a5a0ae499b1917e5e7d4db5e9b610d1044778d2bd4b56f8a0090f6ed473bd345` |
| numpy / matplotlib on the run host | 2.2.6 / 3.10.9 |

The pinned `scripts/tr12_repro.sh` and `solve.py` are the 2026-09-25 batch-15 candidate versions.
Their V3 path is what this report publishes: the `c_v3_join` row, and the `--v3-spectrum` join
with its float64 FFT. `--kc-unrank` in the binary comes from main's `solve.c`. Before the run,
main's and the candidate's `--kc-unrank` were compared at n=9 on every rank `0..N` (26,113 calls),
and the stdout was identical. The 2026-09-25 candidate `solve.c` differed from main's only in `--kc-profile`.

## What matched

| check | result |
|---|---|
| fresh n=31 grid vs committed `tr12/v3_rel_grid.tsv` | **byte-identical**: sha256 `38457ee67dcf5cce359b80e2cd93148085394c016e50aa5362f51b8dd17d3a69` both (`V3ROWS_GRID_VS_COMMITTED=MATCH`), 1002 lines, and the battery's own `row_end` diff was empty (`[ok  ] a1_v3`) |
| fresh spectrum vs committed `tr12/v3_spectrum.tsv` | **byte-identical**: sha256 `22ac482fe8f25e3a6db683adda0459b414729fa6e045796b276640b67ec6e6b2` both (`V3ROWS_SPECTRUM_VS_B15_COMMITTED=MATCH`) |
| the join's own gate | `V3_SPECTRUM=PASS` (`c_v3_join.txt`) |
| the render | `fig_tr12_kc_spectrum` drawn from that spectrum (`c_viz.txt`, `src=… v3_spectrum.tsv@22ac482fe8f2`) |
| ladder | mounted read-only, and unmodified at the end |
| wall time | 427 s |

Because the spectrum matched, it was not shipped in the run's bundle. Its sha is the attestation,
and the committed file is the copy. The grid's run copy is byte-identical to `tr12/v3_rel_grid.tsv`
and is not duplicated here. **The published figure `reports/figures/fig_tr12_kc_spectrum.{png,svg}`
is unchanged.** The run rendered a figure, but that image was not compared with the committed
one, and this directory makes no claim about it.

## Re-checked on the current tree (2026-09-26, join only)

The pinned `solve.py` has since changed in the batch-15 candidate tree, and `scripts/tr12_repro.sh` has
not. On that tree the same driver was run with
`JOIN_ONLY=1 ALLOW_DRIFT=1`, which joins the committed grid with no ladder read, under numpy 1.26.4
and matplotlib 3.6.3. It gave the same extracted line ranges and piece hashes,
`V3ROWS_SPECTRUM_VS_B15_COMMITTED=MATCH` (the spectrum is again `22ac482f…`),
`TR12_V3_FIG=PASS`, `TR12_VIZ=PASS` and `TR12_V3=PASS`. This covers only the join and the render.
The grid was not re-derived.

## Files

| file | what | differs from the run's own copy? |
|---|---|---|
| `VERDICTS.txt` | the driver's whole verdict file | 2 lines redacted: the host name in the header comment reads `<HOST>`, and `V3ROWS_RO=PASS:` names `<LADDER_MOUNT>` instead of the mount point |
| `run.log` | the driver's log (it ends with a copy of `VERDICTS.txt`) | the same two redactions, and the run directory reads `<OUT>` |
| `c_v3_join.txt` | stdout of row `c_v3_join` | the output path reads `<OUT>` |
| `c_viz.txt` | stdout of row `c_viz` | no |
| `run_v3_rows.sh` | the driver | one comment line: line 3 named an unpublished sibling script, and now reads "an earlier standalone driver (not published)". No code line differs. The executed copy's sha256 was `b94ffa86eeae0be489df651aa86ccf3dc64050f0c005a2b1ea4f7f4450e22271` |
| `SHA256SUMS` | sha256 of every file above, as published | — |

**No verdict token was changed.** The whole-line `KEY=value` set of `VERDICTS.txt` is identical to
the run's file, apart from the one redacted `V3ROWS_RO` value. The run's own `VERDICTS.txt` had sha256
`4df351e57f47e50dc87d8d0d157c6fedde647df0a2a8a5a157a446aa5b89ed95`. Publishing infrastructure
identifiers is barred by standing rule.

Check the published copies: `cd reports/evidence/tr12/v3_rows_n31_20260925 && sha256sum -c SHA256SUMS`.
These are plain files hashed as raw bytes. None of them is gz-framed, so the #169 framing era does not apply.

## Reproduce

The grid step needs the full-31 f ladder, which this project does not distribute
([TR-12](../../../TR12_QUERY_PROGRAM.md)). The join and render steps need only the tree:

```bash
JOIN_ONLY=1 ALLOW_DRIFT=1 bash reports/evidence/tr12/v3_rows_n31_20260925/run_v3_rows.sh . - - /tmp/v3rows_out
grep -x 'V3ROWS_SPECTRUM_VS_B15_COMMITTED=MATCH' /tmp/v3rows_out/VERDICTS.txt
grep -x 'TR12_V3_FIG=PASS' /tmp/v3rows_out/VERDICTS.txt
```

`ALLOW_DRIFT=1` is needed whenever `scripts/tr12_repro.sh` or `solve.py` differs from the pins
above, and the driver records `V3ROWS_DRIFT=ALLOWED` when it is set. With a ladder, the full form
is `run_v3_rows.sh SRC FDIR SOLVE OUT`, and FDIR must be on a read-only mount. `TEST_N=9` builds a
throwaway n=9 ladder, diffs the grid against `scripts/tr12_expected/n9/a1_v3.txt`, and gives
`TR12_V3_FIG=SKIP:reduced-universe`, the battery's own n<31 skip.
