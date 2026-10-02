# Visualization — V4, King Wen's neighbourhood shells (how the space collapses onto one ordering)

**The rarity profile of King Wen, drawn.** Fix King Wen's first *i* pair placements; count — exactly
— how many members of the whole superspace still agree with it. That count is the *i*-th shell. The
figure plots the **31 post-placement shells** on a log axis, from the first shell after the root (the root `Shell_0 = N` is not plotted) down to the
single ordering, together with the surprisal each individual choice contributes. It is TR-12's Q3
table as a picture. *(Corrected 2026-09-04, Q-316 item 4: this read "the 32 shells". There are 32
shells counting `Shell_0 = SUPER`, but the TSV has one row per free PLACEMENT — 31 at full-31 — and
`Shell_0` appears only as step 1's `g_parent`. `fig_tr12_kc_shells` plots the rows.)*

← Back to the [capstone's visual showcase](README.md#king-wens-place-in-the-space-tr-12) · V-family: [V1 field](viz_kc_field.md) ·
[V2 river](viz_kc_river.md) · [V3 spectrum](viz_kc_spectrum.md) · **V4** ·
[V5 grammar](viz_kc_grammar.md)

[![Two-panel figure of King Wen's own walk. Upper: log10 of the exact number of completions remaining after each of its 31 free placements, with a shaded bar at each step for the attested range over the admissible alternatives. Lower: the surprisal of each of King Wen's choices, in bits.](../reports/figures/fig_tr12_kc_shells.png)](../reports/figures/fig_tr12_kc_shells.svg)

*V4 as committed, **C1C2C4C5-SUPERSPACE; C3 not imposed**. Click the image for the SVG; the full caption is in [TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5), and this page is the figure's spec.*

## In plain terms

This picture follows only King Wen's own ordering, not the whole population. After each of its 31
free choices, the top panel shows how many allowed orderings (those obeying four of the five core
rules, all but the one called C3) still begin the same way, a count that falls from a 38-digit number
to exactly one; the shaded bars show the range for the other choices that were open at that step. The
bottom panel shows how surprising each of King Wen's choices is, measured in bits, where one bit is
the surprise of a fair coin toss.

## What it shows

- **Upper panel.** log₁₀ of `g(prefix)`, the exact number of completions remaining after each of King
  Wen's 31 free placements, annotated with the number of admissible alternatives at that step. The
  shaded bar at each step spans the least to greatest `g` over every admissible alternative there,
  King Wen's own included; it is attested from the 2026-09-22 n=31 battery receipts.
- **Lower panel.** The surprisal of each choice, −log₂ p_i in bits, where p_i = g_i / g_(i−1) is the
  share of the previous shell that makes King Wen's choice. A short black tick at each step marks
  log₂ of the number of alternatives, the cost if they all had equal completion counts, so a bar above
  its tick is a choice with fewer completions than the average alternative. The bars sum to log₂ N.

Two checks are visible in the image: `g` reaches exactly 1 at the last placement, and the step with a
single admissible alternative costs 0 bits. The full reading guide is
[How to read it](#how-to-read-it) below.

## What it establishes, and what it does not

- **Establishes.** King Wen's exact rarity profile, TR-12's Q3 table drawn as a figure: the
  completions remaining after each of its placements, and what each choice costs in bits
  ([TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5), V4 caption;
  [§Q3](../reports/TR12_QUERY_PROGRAM.md#q3-kws-rarity-profile--fg-at-each-of-kws-31-prefix-steps)).
- **Does not establish.** Anything about the population. The line is one walk, King Wen's, and unlike
  V1, V2 and V5 it is not an overlay on a population field. The bars are attested, not reproducible
  without the f and g ladders. See
  [What this figure is allowed to claim](#what-this-figure-is-allowed-to-claim) and
  [What it may NOT claim](#what-it-may-not-claim).

## Provenance

- **Data.** [`reports/tr12/q3_profile_kw.tsv`](../reports/tr12/q3_profile_kw.tsv), sha256 prefix
  `bbe62f3bc6a3`, the curve, written by the atlas consumer with `--atlas-q3-trace` from the published
  trace `reports/tr12/q3_trace_kw.txt`; and for the alternatives band
  [`reports/evidence/tr12/banked_n31_20260922/q3_profile_exact.tsv`](../reports/evidence/tr12/banked_n31_20260922/q3_profile_exact.tsv),
  `ee0b99fde78a`. Both digests are printed in the figure's footer. The band is drawn only because every
  step's placement, alternatives count, `g` and `g_parent` match the curve's table exactly. The
  commands are under [Generation](#generation).
- **Generator.** `fig_tr12_kc_shells()` in [`viz/report_figures.py`](report_figures.py), called by
  `tr12_figures()`; it reads the band through `_read_q3_alts()` and `_v4_band()`.
- **Regenerate.** The whole set, `cd reports/figures && python3 ../../viz/report_figures.py`, or
  this figure alone (the band's receipt is found from the generator's own location):

  ```bash
  cd reports/figures && python3 -c "import sys; sys.path.insert(0, '../../viz'); import report_figures as r; r.fig_tr12_kc_shells('../tr12/q3_profile_kw.tsv')"
  ```

- **Toolchain.** matplotlib 3.11.0 and numpy 2.4.4. Under that pin the documented command reproduced
  the committed PNG byte for byte on 2026-09-29, with all twelve report figures (CX-233); see
  [Reproduce the figures](README.md#reproduce-the-figures).
- **Tokens.** `TR12_Q3=PASS`, `TR12_Q3_KW=PASS` and `TR12_Q3_READER=PASS` in
  [`reports/tr12/VERDICTS.txt`](../reports/tr12/VERDICTS.txt); the 2026-09-22 receipt records
  `TR12_V4_TSV=PASS` ([`VERDICTS_n31_20260922.txt`](../reports/evidence/tr12/VERDICTS_n31_20260922.txt)).

## Review history

- **2026-09-23.** Rendered. TR-12 had reported V4 as blocked on the ladders; its input already
  existed, and only matplotlib was missing on the query host (TR-12 §2).
- **2026-09-26, Codex figure review VIZ1, checked by Fable.** The title did not name the space or
  define N (F21), and the alternative counts rendered at 6.8 px (F18); redrawn, CX-191, CX-192.
- **2026-09-27.** The figure now draws the alternatives band, read from the published attested
  receipt, and its title no longer says the whole figure is one walk (CX-204).
- **2026-09-28, Codex visualization review, triaged by Fable.** The band reader and the titles
  accepted tables they should have refused (Q-891), CX-226. p_i was never defined on the figure; the
  subtitle now defines it, and the log₂ ticks and a boxed key were added, CX-227.
- **2026-09-29.** The figure is shown at the top of this page, and these summary sections were added
  as part of the [capstone's visual showcase](README.md) (CX-233).

*The rest of this page is the figure's specification and drafting record, kept as written, with its
dated corrections in place.*

## Status (2026-08-22)

| Piece | Instrument | State |
|---|---|---|
| The 31-row f·g descent trace along King Wen's own path | `solve --kc-o3-rank FDIR GDIR "<walk>" --kc-trace` | **EXISTS** (source + binary, verified) |
| Per-step flow identity, endpoint checks, `Π p_i = 1/N` self-check | printed by the same command as `#o3-trace-summary` | **EXISTS** |
| Optional band: min/max `g` over the *alternatives* at each step | `solve --kc-profile FDIR GDIR "<walk>" --kc-tsv FILE --kc-alts` | **EXISTS** (`g_alt_min` / `g_alt_max`; the consumer carries them through, and `fig_tr12_kc_shells` draws the band from a table's own columns when present and its sidecar reads `q3_alts_status=REPRODUCED` (Q-891; no emitter writes that key yet, so today a table's own columns are never drawn), else from the published attested n=31 receipt; **DRAWN** 2026-09-27, see below) |
| Full-31 f and g ladders | Stage F / Stage G | **BUILT** — the full-31 run of 2026-09-22 produced `reports/tr12/q3_profile_kw.tsv` with them mounted. ⚠ *Updated 2026-09-24: this read "NOT YET BUILT".* |
| Trace text → figure TSV | `python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR --atlas-q3-trace TRACE.txt` | **EXISTS** (n=9 gated: `--atlas-selftest`, `ATLAS_CONSUMER=PASS`) |

Unlike the other four, V4 needs **no new engine work at all**: the main curve and the alternatives band both render from published tables, and
recomputing their counts needs only the f/g ladders (the committed band is the attested n=31 receipt; Q-901, 2026-09-28: this said the band needed engine work).

## The quantity plotted

Let **SUPER** = C1 ∩ C2 ∩ C4 ∩ C5 (C3 is **not** applied) with `N = |SUPER|` exact, and let
`s_0, s_1, …, s_31` be the states along King Wen's own walk: `s_0` is the root (C4 has already
pinned pair 0 at slot 1) and `s_i` is the state after King Wen's *i*-th free placement.

**The shells.** Define

```
Shell_i = { w ∈ SUPER : w agrees with King Wen on free placements 1 … i }
|Shell_i| = g(s_i)
```

so `Shell_0 = SUPER` (`g(s_0) = N`) and `Shell_31 = {King Wen}` (`g(s_31) = 1`). The shells are
**nested** — not strictly: a forced placement leaves a shell equal to the one before it (Q-901: this read "strictly nested") — and their sizes are **non-increasing**, *not* strictly decreasing.

⚠ **Corrected 2026-09-04 (Q-316 item 4), and this repository's own committed trace is the
counterexample.** `scripts/tr12_expected/n9/a2_q3_profile.txt` reads
`g = 26112, 2368, 456, 160, 32, 8, 4, 4, 1, 1` — **flat from step 6 to 7 and from step 8 to 9**.
A step whose placement is forced contributes `p_i = 1` and `bits_i = 0`, and the shell does not
shrink; that is a real feature of the walk, not a defect, and "strictly decreasing" would have made
the artifact contradict the text. The reader-side check below is `non-increasing` for the same
reason — and that leg was **added to `atlas_q3_reader_check` in the same change**, because this
table had been naming a gate the code did not run. It is `>` and not `>=` deliberately: a `>=`
test fails the fixture quoted above, which is the red-test for it.

The main panel plots `g(s_i)` against `i` on a **log₁₀** axis — `fig_tr12_kc_shells` uses
`_log10_bigint` and labels the axis `log10 g(prefix)`, because the exact `g` is a 192-bit integer
that does not survive `float()`. *(This paragraph said **log₂** and no plotter has ever used it.)*
The **log₂** quantity is the SURPRISAL in the lower panel: `bits_i = −log₂ p_i`, whose bars sum to
`log₂N`.

**The per-step conditional and its surprisal.**

```
p_i    = g(s_i) / g(s_{i-1})                 exact rational, the probability that a uniform member
                                             of Shell_{i-1} makes King Wen's i-th choice
bits_i = −log₂ p_i                           the surprisal of that one choice
```

The denominator is `g(s_{i−1})` because the DP recurrence makes it the sum of `g` over **all**
admissible successors — the engine verifies that identity at every step rather than assuming it.
Two exact self-checks follow by telescoping and are printed by the engine:

```
Π_{i=1..31} p_i = 1/N            Σ_{i=1..31} bits_i = log₂ N
```

**The alternatives band (data published 2026-09-27, as attested; drawn 2026-09-27).** At step *i* the trace reports `alts` — the number of admissible
oriented successors with `g > 0` — but not their individual masses. TR-12 §8 item 5 specifies
`--kc-profile FDIR GDIR "e,x,…"|KW`, which prints the per-step `g_alt_min` / `g_alt_max` a min/max band around the
shell curve requires; it has been run on King Wen at n = 31, and its output is published as attested (2026-09-22 battery; not reproducible without the f/g ladders): [`reports/evidence/tr12/banked_n31_20260922/a2_q3_profile.txt`](../reports/evidence/tr12/banked_n31_20260922/a2_q3_profile.txt) carries the per-step `g_alt_min` / `g_alt_max` and all 880 per-alternative `#alt` rows, and [`q3_profile_exact.tsv`](../reports/evidence/tr12/banked_n31_20260922/q3_profile_exact.tsv) beside it is the run's 16-column exact table (the tracked receipt `reports/evidence/tr12/VERDICTS_n31_20260922.txt` records `TR12_Q3_PROFILE=PASS` for that run). The figure may draw the band only from those rows, joined to the curve step by step, and only labelled as attested; without them it ships as the curve plus the `alts` count, and **must not
draw a band**. **Satisfied 2026-09-27 (lane VF):** `fig_tr12_kc_shells` reads `q3_profile_exact.tsv` where it is published, draws one shaded bar per step from `g_alt_min` to `g_alt_max` only when every step's `pair`, `entry`, `exit`, `orient`, `alts`, `g` and `g_parent` equal the curve table's, keys the bars on the figure as ATTESTED from the 2026-09-22 n=31 battery receipts, and names the file and its sha prefix in the footer (`q3_profile_exact.tsv@ee0b99fde78a`). A receipt for another `n` (the n=9 battery) draws no band and prints nothing; a same-`n` receipt that disagrees prints one `V4 band omitted:` line and draws no band. *(Q-891, 2026-09-28: a receipt path that does not exist now also prints one `V4 band omitted: receipt absent …` line and puts `q3_profile_exact.tsv@ABSENT` in the footer; the receipt must also satisfy `g_alt_max ≤ g_parent`, and `g_alt_min = g_alt_max = g` at a one-alternative step; bounds carried in the curve's own table are drawn only when its sidecar reads `q3_alts_status=REPRODUCED` — no emitter writes that key yet, so such a table draws no band and says so.)* ⚠ *(corrected 2026-09-26: the heading read "(PENDING)" and the text implied the per-alternative values had not been computed; they have, and are unpublished.)* *(Updated 2026-09-27, Q-867: they are now published, at the paths above.)*

## Where the numbers come from

Every row is one line of the `--kc-trace` output, whose fields are (verbatim from the KC-O3 module
header in `solve.c`):

```
#o3-trace  step  pair  entry  exit  orient  alts  mass_below  f  g  g_parent  p  bits
```

with `g = g(s_i)`, `g_parent = g(s_{i−1})`, `p` printed as the exact fraction `g/g_parent`, `f` =
`f(s_i)` (the number of valid prefixes reaching that state — King Wen's is one of them), and
`mass_below` = that position's O3 pair-block contribution to the rank (a Q1 quantity, carried
through but not plotted here). A final `#o3-trace-summary` line reports `N`, the endpoint
verifications, `flow_identities=31/31`, `sum_bits` and `log2N`.

## Input TSV

`q3_profile_kw.tsv` in the consumer's `--atlas-out` directory — `<artifact-root>/consumer/q3_profile_kw.tsv`
in a `scripts/tr12_repro.sh` run, committed as `reports/tr12/q3_profile_kw.tsv` — one row per free placement,
31 data rows at full-31. ⚠ *(corrected 2026-09-25, Q-684: this put the table at the artifact root,
where the battery writes no file of that name.)*

⚠ *Added 2026-09-24 (Q-776).* **Which file is read.** The consumer (`solve.py atlas_emit_q3`) names
the table `q3_profile_kw.tsv` only when the trace has been checked to be King Wen's walk at n = 31.
Every other trace, including a full-31 trace that is not King Wen's (`TR12_Q3_KW=NOT-KW`), is
written as `q3_profile.tsv`. Before it writes, the emitter removes the other name, the other name's
`.provenance.txt` sidecar and the old sidecar of the name it is about to write, so one directory
never holds both names from two runs. The renderer
(`viz/report_figures.py` `tr12_figures`, via `_tr12_q3_table`) chooses by the sidecar, not by
which name exists. It draws `q3_profile_kw.tsv` only when that table's own
`q3_profile_kw.tsv.provenance.txt` reads `q3_is_king_wen=PASS` and `q3_table=q3_profile_kw.tsv`. Since 2026-09-28 (lane VR4) that sidecar's `q3_table_sha256=` must also equal the sha256 of the table's bytes: a PASS sidecar without the digest, or with another one, is refused, and a plain table's sidecar that carries a digest must match it too. ⚠ *(added 2026-10-02, Q-776: this paragraph did not state the digest condition, which `SOLVE_PY_CLI.md` already did.)*
It refuses V4 in three cases: both names are present; the KW table's sidecar says anything else;
or the KW table has no sidecar while `q3_profile.tsv.provenance.txt` sits beside it, which marks
the KW table as a leftover of an earlier run. ⚠ *(corrected 2026-09-25, Q-776: this listed the
first two cases only.)*
One exception: a directory with no sidecar for either name, such as the committed `reports/tr12/` tree,
has its KW table taken as written. A consumer run always writes a sidecar, so a reused
`--atlas-out` never reaches that branch.


| Column | Type | Meaning |
|---|---|---|
| `step` | int, 1…31 | the *i*-th free placement (fills pair-slot `step + 1`) |
| `pair` | int, 1…31 | global pair index placed; for King Wen `pair == step` |
| `entry`, `exit` | int, 0…63 | the pair's entry and exit hexagram (its orientation in the walk) |
| `orient` | 0/1 | orientation flag as the engine defines it |
| `alts` | int | admissible oriented successors with `g > 0` at this step |
| `mass_below` | decimal **string** | O3 pair-block mass below this choice (Q1; not plotted) |
| `f` | decimal **string** | `f(s_i)` — valid prefixes reaching this state |
| `g` | decimal **string** | `g(s_i)` = **the shell size**, the main plotted series |
| `g_parent` | decimal **string** | `g(s_{i−1})` |
| `p_num`, `p_den` | decimal **strings** | the exact rational `p_i = p_num / p_den` |
| `p` | float | `p_i` as a float (display precision only) |
| `bits` | float | `−log₂ p_i`, as printed by the engine |

All big integers are decimal **strings** — parse with Python `int()`, never `float()`. The float
columns exist for the axes and must never be the quoted value.

## Generation

**Full-31 — RUN, and the figure is rendered (2026-09-23).** ⚠ *This heading read "PENDING the
ladders" until 2026-09-23, which was stale rather than cautious: the command below was executed on
2026-09-22 with the ladders mounted, the receipt records `TR12_V4_TSV=PASS`, and the resulting
profile is committed at `reports/tr12/q3_profile_kw.tsv`. The figure did not appear at the time only
because matplotlib was absent on the query host (`TR12_VIZ=SKIP:matplotlib-absent`); it renders
from the banked TSV with no ladder. Re-running the command below needs the ladders; re-rendering
the figure does not.* `--kc-o3-rank` takes an explicit walk — it does **not** accept
the literal `KW` (that convenience lives on `--kc-o3-cert` and `--check-arrangement`), so build the
walk string from `solve.py`, the single source of truth for the King Wen sequence:

```bash
KWWALK=$(python3 -c 'from solve import binary_hexagrams as K; print(",".join(str(K[i]) for i in range(2,64)))')
#   62 integers: entry,exit for each of the 31 FREE pairs; the C4-pinned pair 0 is not part of a walk.

solve --kc-o3-rank FDIR GDIR "$KWWALK" --kc-trace [--kc-ooc] [--kc-cache-mb MB] \
      > reports/tr12/q3_trace_kw.txt
```

**Trace text → TSV** — the atlas consumer. Pure re-shaping; the only arithmetic is the float
rendering of an exact fraction the engine already printed:

```bash
python3 solve.py --atlas-queries runs/20260906_kc_ladders_n31/atlas_n31.json --atlas-out reports/tr12 \
                 --atlas-q3-trace reports/tr12/q3_trace_kw.txt --atlas-select q3
#   --atlas-q3-trace also accepts a `--kc-profile ... --kc-tsv` table (auto-detected); that
#   source additionally carries dclass / g_alt_min / g_alt_max / choice_rank, and carries no
#   mass_below (an O3-rank quantity), which the consumer writes as -1 rather than guessing.
#   writes reports/tr12/q3_profile_kw.tsv (reports/tr12/q3_profile.tsv at n != 31 or for a NOT-KW trace) and, in reports/tr12/VERDICTS.txt,
#   BOTH TR12_Q3= and TR12_Q3_READER=.
```

`TR12_Q3_READER` is the separate, reader-side verdict QUERY_INVENTORY §3.2 demands: the consumer
recomputes `Π (p_num/p_den)` from the WRITTEN TSV in exact big-integer rationals and compares it
to `1/N`, rather than trusting the engine's own `#o3-trace-summary` attestation. It also re-checks
`g_parent[i] == g[i−1]`, `g(s_0) == N` and `g(s_n) == 1`.


**Rehearsal at n=9 (sub-second, local):** build the n=9 f and g ladders as in
[viz_kc_field.md](viz_kc_field.md) and run `solve --kc-o3-selftest`, which exercises the trace's
flow identities and the `Π p_i = 1/N` product check exhaustively over all 26,112 walks. The n=9
world has no King Wen, so the *figure* is full-31 only; the n=9 gate covers the machinery.

**TSV → figure:** `viz/report_figures.py` (`fig_tr12_kc_shells`) — a semilog-y step plot of `g`
against `step` (main panel) with a `bits` bar panel beneath and `alts` annotated. TSV in, figure
out; **no analysis logic in `viz/`**. The one other input is the attested alternatives band, read from the published receipt named above and drawn only when it matches the curve step for step.

## How to read it

- **The main curve is `log₁₀ g(s_i)`, the completions left after King Wen's first *i* placements,
  at steps 1–31.** It starts at step 1 (`log₁₀ g(s_1)` = 37.31 on the committed table) and ends at 0
  (`g(s_31)` = 1). The root `g(s_0) = N` (`log₁₀ N` = 39.04) is not a point on it, because the TSV has
  no step-0 row. Its *shape* is the content: steep segments are choices that discard most of the
  remaining space, flat segments are choices that barely narrow it.
- **The bars are the TSV's `bits` column, `−log₂ p_i`.** For i ≥ 2 a bar is the drop in the main
  curve from step i−1 to step i, times log₂10 (to within the column's 6-decimal rounding; measured
  worst case 5.0e-7). `bits_1` = `log₂ N − log₂ g(s_1)` (5.764) is the drop from the unplotted root.
  ⚠ *Corrected 2026-09-25 (Q-699, V3A-144#3): these two bullets read "a descent from `log₂N` bits to
  zero across 31 steps" and "`bits_i` is the same information, differenced". The renderer plots
  `log₁₀ g` from step 1, not bits from the root, and draws the bars from the `bits` column.*
  A tall bar is a rare choice; a short bar is a
  cheap one. Because `Σ bits_i = log₂ N` exactly, the bar panel is a **budget allocation** — it
  shows *where* King Wen's total improbability is spent, and the total is fixed for every member of
  the space, King Wen included.
- **`alts` gives the reference level.** If the `a = alts_i` admissible successors all carried equal
  mass, King Wen's choice would cost exactly `log₂ a` bits. The **signed gap**
  `bits_i − log₂ alts_i` is therefore the readable quantity: negative means King Wen took a
  heavier-than-average alternative, positive means a lighter-than-average one. Read the two series
  together; neither is interpretable alone. **The shaded bars** span the least to greatest `g` over the admissible alternatives at each step, King Wen's own included, so the point's place inside its bar shows where King Wen's choice falls among them by `g` (the receipt's `choice_rank` column is its exact 1-based rank by descending `g`). On this axis they are short: the tallest, at step 19, spans 1.36 decades, and at steps 29–31 every alternative leaves the same `g`, so the bar has zero height.
- **Late steps have few alternatives, but they are not free.** `alts` does fall along the walk
  (56 at step 1; 6, 5, 2, 3, 1, 2 at steps 26–31), yet the last five steps still carry
  **5.700 bits** — 2.379, 0.737, 1.585, 0.000 and 1.000 at steps 27–31 — and step 31 alone carries
  **1.000 bit** (two admissible completions of equal mass, `p = 1/2`). Only step 30 is forced
  (`alts = 1`, `p = 1`, `bits = 0`), and it is the only forced step in the whole trace. Read the
  tail against `log₂ alts`, not against zero: steps 29 and 31 cost exactly `log₂ 3` and `log₂ 2`.
  Numbers from the committed `reports/tr12/q3_profile_kw.tsv`, recomputed from its exact `p_num`/`p_den`
  columns (the 31 surprisals sum to `log₂N` = 129.689).
  ⚠ **Corrected 2026-09-24 (Q-697; Codex V3A-144#2, adjudicated by Fable).** This bullet
  predicted that, as the C5 boundary budget ran out and `alts` collapsed, the late steps would be
  close to forced and the last handful would contribute almost no bits, as a property of the
  constraint system rather than of King Wen. The committed King Wen trace that this page documents
  refutes it: one forced step in the last five, and 5.700 bits spent there.
- **`f(s_i)` is the mirror quantity**: how many *prefixes* reach the same state. `f · g` at any step
  is the mass of walks through that state, and equals the layer flow when summed — the identity V1
  and V2 are built on.

## What this figure is allowed to claim

1. **Exact shell sizes** — `|Shell_i|` is an exact integer for every *i*, computed from the whole
   superspace, not sampled or extrapolated.
2. **The exact per-step conditional probability of King Wen's own choices** under the uniform
   measure on SUPER, and their exact surprisals.
3. **Where along the ordering King Wen's improbability is concentrated** — the one genuinely
   *positional* statement in the Q3 family.
4. **A verified `Π p_i = 1/N`**, printed by the engine and re-derivable by a reader from the
   `p_num`/`p_den` columns with big-integer arithmetic.

## What it may NOT claim

- **`Σ bits_i = log₂ N` is not a measurement of King Wen.** Every walk in SUPER has exactly that
  total. Any "King Wen costs *X* bits" statement made from this figure is a statement about the size
  of the space, not about King Wen. The *distribution* of those bits across steps is the only
  King-Wen-specific content.
- **Nothing about C3 or C15.** `--kc-o3-rank` deliberately has **no** `--kc-c3-max` axis: exact
  ranks and exact `g` values exist only in the C1 ∩ C2 ∩ C4 ∩ C5 superspace. A C15-conditioned
  rarity profile would need per-step C3-pass corrections by rejection sampling, and would be a
  labelled **estimate**, not this figure.
- **"Neighbourhood" means prefix-agreement, not edit distance.** `Shell_i` is the set agreeing with
  King Wen on the first *i* placements; it is not a ball of radius *i* in any metric. Solutions at
  small edit distance from King Wen that differ early are in **no** shell but `Shell_0`.
- **No band without `--kc-profile`.** The alternatives' individual masses are not in the trace; a
  min/max envelope drawn from `alts` alone would be fabricated. The band that IS drawn is a **range**, not a distribution: it says nothing about how the alternatives' `g` spread inside it, and its values are attested from one run: a reader can check them against the 880 `#alt` rows (the receipt directory's `check_receipts.sh` does), but cannot recompute them without the f/g ladders.
- **Circularity caveat carries over.** C3, C6 and C7 were extracted from King Wen; this figure's
  space excludes C3 entirely, but the standing caveats in
  [CRITIQUE.md](../documentation/CRITIQUE.md) apply to any claim that layers them back on.

## Verification gates

| Gate | Where |
|---|---|
| per-step flow identity: `Σ_c g(s∘c) == g(parent)` at every step | verified inside `--kc-trace`; reported as `flow_identities=31/31` |
| endpoints `g(s_0) = N` and `g(s_31) = 1` | `#o3-trace-summary`: `VERIFIED` / `FAILED` |
| `Π p_i = 1/N`, equivalently `sum_bits == log2N` | `#o3-trace-summary` |
| own-path state present in the f ladder at every step | hard assert inside the trace (aborts on a structure defect) |
| n=9 exhaustive rank/unrank + trace battery | `solve --kc-o3-selftest` |
| f·g cut identity at every layer | `solve --kc-g-check FDIR GDIR` |
| **reader-side:** `Π (p_num/p_den) == 1/N` in big integers | `python3 -c` over the TSV |
| **reader-side:** `g` **non-increasing**, `g[31] == 1`, `g_parent[i] == g[i−1]` | `solve.py::atlas_q3_reader_check` over the written TSV (`TR12_Q3_READER`) |

## Where the files live

- **This doc:** `viz/viz_kc_shells.md`
- **Generator (TSV → figure):** `viz/report_figures.py`
- **Evidence:** `<artifact-root>/q3_profile.txt` (raw engine output, row `a2_q3`: the Generation
  block's `--kc-o3-rank --kc-trace` run, with `--kc-bracket` added) and
  `<artifact-root>/consumer/q3_profile_kw.tsv`, committed as `reports/tr12/q3_profile_kw.tsv`; the band reads `reports/evidence/tr12/banked_n31_20260922/q3_profile_exact.tsv` (attested, 2026-09-22). ⚠ *(corrected
  2026-09-25, Q-684: this named a trace file and a table at the artifact root that the battery does
  not write there.)*
- **Figures:** `reports/figures/fig_tr12_kc_shells.{png,svg}` (committed). The renderer writes to its working directory, and nothing is
  mirrored: no per-run copy under `runs/<run-id>/viz/` exists; render into a scratch directory to compare (Q-901, 2026-09-28).

## Related

- [TR4_SIZE_OF_THE_SPACE.md](../reports/TR4_SIZE_OF_THE_SPACE.md) — the boundary-information decay
  curve, the closest published relative of this figure (and an estimator, where this is exact).
- [CRITIQUE.md](../documentation/CRITIQUE.md) — constraint-extraction circularity.
- [SOLVE_C_CLI.md](../documentation/SOLVE_C_CLI.md) — the `--kc-*` family; `--kc-o3-rank`,
  `--kc-trace` and `--kc-bracket` semantics live in the KC-O3 module header in `solve.c`.

---

*Specification per TR-12 §2 (V4) / Q3. Nothing novel is claimed: this is the standard chain-rule
decomposition of a uniform measure along a path in a counting DP, plotted on a log axis. Developed
with AI assistance (Claude, Anthropic); corrections invited.*
