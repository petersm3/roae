# TR-12 evidence — the n=31 battery receipt

`VERDICTS_n31_20260922.txt` is the **verbatim verdict set** written by the TR-12 reproduction
battery on its full-31 run of **2026-09-22**, on the L64 query host (since torn down). It is
published here with its failures intact — because
[TR-12](../../TR12_QUERY_PROGRAM.md) publishes conclusions drawn from this run, and withholding
the receipt while publishing its conclusions is the weaker position.

## What it says

118 whole-line `KEY=value` rows over 120 lines: **89 verdict rows** and **29 `_REASON` rows**.

| verdict (value prefix of a non-`_REASON` row) | rows |
|---|---|
| `PASS` | 42 |
| `SKIP` | 32, **of which 6** are `SKIP:doc-only` |
| `PENDING` | 3 |
| `FAIL` | **3** |
| `NO` / `EMPTY` | 2 / 2 |
| numeric or list values, and `TR12_EW1_NULL=typicality-bound` | 5 |

⚠ *(corrected 2026-09-24: this table read `SKIP 32 · DOC-only 6 · PENDING 5`, which double-counted.
The six `DOC-only` rows are the `_REASON` lines of six `SKIP:doc-only` tokens already inside the 32,
not a seventh class; and two of the five `PENDING` were `_REASON` lines whose text begins
`PENDING:`, so there are 3 `PENDING` tokens. Recount:
`grep -E '^[A-Z0-9_]+=' VERDICTS_n31_20260922.txt | grep -v '_REASON=' | cut -d= -f2 | cut -d: -f1 | sort | uniq -c`.)*

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

- `TR12_FSHA` / `TR12_GSHA` / `TR12_TSHA` = `SKIP:banked-pre-scan`. **No battery run took these layer
  digests**, the pre-scan included: the pre-scan run stood the same rows down as `SKIP:cost-gated`,
  and what it pinned is each ladder's identity against the published registry (`TR12_{F,G,T}IDENT`).
  The digests were taken by the standalone 2026-09-17 sweep, 96 of 96 logical
  ([TR-12](../../TR12_QUERY_PROGRAM.md) §R Tier B). ⚠ *(corrected 2026-09-24: this bullet read "the
  pre-scan (`--no-scan`) run already took each ladder's digests under the same binary and the same
  universe", repeating the receipt's reason string as fact. That string is superseded (CX-65), and
  see §"Reason strings superseded after the run" below.)*
- `TR12_GCHECK=SKIP:cost-gated` — `--kc-g-check` at n=31 is a ~24 h single-threaded full-ladder
  pass, not a point query. The published g-check that *was* run is
  [`KC_G_CHECK_n31.txt`](../../KC_G_CHECK_n31.txt) (PASS at every layer 0..31, 0 failing layers).
- `TR12_Q7_WITNESSES=PENDING:kissat` — `kissat` is not on PATH, so no SAT witness is produced and
  no non-KW named sequence receives a rank in TR-12.

Two rows are **measured nulls**, produced by a check that can refuse and did not:
`TR12_Q1C=EMPTY:interval-degenerate-at-n31` and
`TR12_Q10A_KWRANK=EMPTY:class-rank-uncomputable-under-kw-labels`.

## Reason strings superseded after the run

The receipt is kept **verbatim**, so it carries reason strings written by the driver as it stood on
2026-09-22. Four of them are false at HEAD. They are listed here instead of being edited in the receipt:

| row | what the receipt says | what is true |
|---|---|---|
| `TR12_{F,G,T}SHA_REASON` | the pre-scan run "already took this ladder's digests" | no battery run took them (CX-65); the standalone 2026-09-17 sweep did, 96 of 96. The current driver says "NOT TAKEN, here or in the pre-scan" |
| `TR12_TCHECK_REASON` | "no --kc-t-check PASS verdict has EVER been recorded" | one had been, a week before this run: `runs/20260906_kc_ladders_n31/KC_T_CHECK_n31.txt`, PASS, 0 failing layers over k = 0..31 (2026-09-14/15). It constrains the files, not the transition relation |
| `TR12_LS_FORCED8_REASON` | "lean/C1RuleConstants.lean is NOT present in this tree" | it is tracked (`lean/C1RuleConstants.lean`); the current driver branches on its presence |
| `TR12_Q9_REASON` | names a `q9_negatives.md` deliverable under `tr12/` | that file has never existed in this repository (CX-73) |

**`TR12_Q2=PASS` does not meet TR-12's Q2 completion contract.** TR-12 §Q2 defines completion as all
three SUPER probes returning `CERTIFICATE PASS` **and** `TR12_GCHECK` and `TR12_GSHA` both PASS. This
receipt has `TR12_GCHECK=SKIP:cost-gated` and `TR12_GSHA=SKIP:banked-pre-scan`. The `PASS` was printed
by the pre-CX-65 driver, whose `TR12_Q2` took only the probes' own exit status. The current driver
aggregates the two legs (`agg TR12_Q2 TR12_Q2 TR12_GCHECK TR12_GSHA` in `scripts/tr12_repro.sh`), and on
this run's inputs it would print `TR12_Q2=SKIP:leg-TR12_GSHA`. **So by its own contract, Q2 is not
complete at n=31 on this run.** The standalone `reports/KC_G_CHECK_n31.txt` PASS covers the g-check
half of the contract outside the battery. The layer-digest half is covered only by the 2026-09-17 sweep.
*(Added 2026-09-24.)*

## Provenance

- **Run:** 2026-09-22, full-31, against the f/g/t ladders built 2026-09 and registry-checked
  96/96 logical (f, g, t) + 65/65 container (t only; f and g were re-read 130/130 at copy-in)
  ([TR-12](../../TR12_QUERY_PROGRAM.md) §R Tier B). ⚠ *(corrected 2026-09-24: the container count was
  not scoped to t.)*
- **Atlas the consumer rows read:** `runs/20260906_kc_ladders_n31/atlas_n31.json`,
  5,978,126 bytes, sha256 `9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558`.
- **Host:** released after the artifacts were pulled; its OS disk was `deleteOption=Delete`, so
  this file and its siblings are the surviving record of the run.
- **Driver:** `scripts/tr12_repro.sh`; currency gate `scripts/tr12_repro_gate.sh`.

The laptop-scale rehearsal of the same battery — no ladder, no cluster — is
`scripts/tr12_repro.sh --n9`, diffed verbatim against the committed goldens in
`scripts/tr12_expected/n9/`.
