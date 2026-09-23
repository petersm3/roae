# TR-12 evidence — the n=31 battery receipt

`VERDICTS_n31_20260922.txt` is the **verbatim verdict set** written by the TR-12 reproduction
battery on its full-31 run of **2026-09-22**, on the L64 query host (since torn down). It is
published here with its failures intact — because
[TR-12](../../TR12_QUERY_PROGRAM.md) publishes conclusions drawn from this run, and withholding
the receipt while publishing its conclusions is the weaker position.

## What it says

118 whole-line `KEY=value` rows over 120 lines:

| verdict | rows |
|---|---|
| `PASS` | 42 |
| `SKIP` | 32 |
| `DOC-only` | 6 |
| `PENDING` | 5 |
| `FAIL` | **3** |
| `NO` / `EMPTY` | 2 / 2 |

Match tokens whole-line with `grep -Fqx` — **`-F` is load-bearing**; TR-12 §12.9 explains both
directions in which a plain `grep -qx` fails on this document's own tokens.

**Two lines are redacted, and nothing else is altered.** The run host's working directory appeared
as an absolute path carrying the machine's default cloud username; both occurrences — the comment
header on line 2 and the prose of `TR12_VIZ_REASON` — now read `<RUNDIR>`. **No verdict token
changed**: the whole-line `KEY=value` verdict set of this file is identical to the archived
original, checked by diff. Publishing infrastructure identifiers is barred by standing rule, and
a receipt whose verdicts are intact loses nothing by not naming someone's home directory.

## The three FAILs are one fault, and it is a published result

    TR12_ATLAS_CONSUMER=FAIL:nonzero-exit(1)
    TR12_CONSUMER_VERDICTS=FAIL:nonzero-exit(1)
    TR12_REPRO=FAIL

All three descend from the **same** pair of rows, `TR12_A2_SLOT=FAIL` and
`TR12_A3_EXTERNAL=FAIL` — the two checks that compare this compiler against figures published
from a *different* instrument over a *different* population. They disagree by about twelve times
tolerance, and **TR-12 §12.10 publishes that disagreement as the result**: the two sides count
populations differing by exactly C3, and this program has no C3 channel. Exit status 1 is the
documented behaviour when any verdict written is a failure.

**So `TR12_REPRO=FAIL` is not a defect being disclosed here for the first time** — it is the
measurement §12.10 is about. What this file adds is that a reader can now check that claim against
the run's own output rather than against the report's description of it.

## What the SKIPs are, since 32 is most of the file

They are **named** skips with reasons, not silent omissions. The largest classes:

- `TR12_FSHA` / `TR12_GSHA` / `TR12_TSHA` = `SKIP:banked-pre-scan` — the pre-scan (`--no-scan`) run
  already took each ladder's digests under the same binary and the same universe.
- `TR12_GCHECK=SKIP:cost-gated` — `--kc-g-check` at n=31 is a ~24 h single-threaded full-ladder
  pass, not a point query. The published g-check that *was* run is
  [`KC_G_CHECK_n31.txt`](../../KC_G_CHECK_n31.txt) (PASS at every layer 0..31, 0 failing layers).
- `TR12_Q7_WITNESSES=PENDING:kissat` — `kissat` is not on PATH, so no SAT witness is produced and
  no non-KW named sequence receives a rank in TR-12.

Two rows are **measured nulls**, produced by a check that can refuse and did not:
`TR12_Q1C=EMPTY:interval-degenerate-at-n31` and
`TR12_Q10A_KWRANK=EMPTY:class-rank-uncomputable-under-kw-labels`.

## Provenance

- **Run:** 2026-09-22, full-31, against the f/g/t ladders built 2026-09 and registry-checked
  96/96 logical + 65/65 container ([TR-12](../../TR12_QUERY_PROGRAM.md) §R Tier B).
- **Atlas the consumer rows read:** `runs/20260906_kc_ladders_n31/atlas_n31.json`,
  5,978,126 bytes, sha256 `9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558`.
- **Host:** released after the artifacts were pulled; its OS disk was `deleteOption=Delete`, so
  this file and its siblings are the surviving record of the run.
- **Driver:** `scripts/tr12_repro.sh`; currency gate `scripts/tr12_repro_gate.sh`.

The laptop-scale rehearsal of the same battery — no ladder, no cluster — is
`scripts/tr12_repro.sh --n9`, diffed verbatim against the committed goldens in
`scripts/tr12_expected/n9/`.
