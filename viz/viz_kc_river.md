# Visualization — V2, the mass river (how the superspace's mass flows across the ordering)

**Where the whole superspace goes, layer by layer.** At every one of the 31 free placements the
space splits into streams; the river plots the exact width of each stream as it flows left to
right across the ordering, with King Wen's own path drawn on top. A companion panel gives the exact
mass — and the exact exhaustion cost — of each of the 56 first-level branches.

← Back to the [visual capstone](README.md#king-wens-place-in-the-space-tr-12) · V-family: [V1 field](viz_kc_field.md) · **V2** ·
[V3 spectrum](viz_kc_spectrum.md) · [V4 shells](viz_kc_shells.md) · [V5 grammar](viz_kc_grammar.md)

[![Two-panel figure. Upper: a stacked mass river over layers 0 to 30 showing the exact share of the superspace in each boundary-distance class d = 1, 2, 3, 4 and 6, with King Wen's own class at each layer drawn as a black step line. Lower: the 56 top-level branches sorted by solution mass, with log10 exhaustion cost in t-units overlaid as a red line.](../reports/figures/fig_tr12_kc_river.png)](../reports/figures/fig_tr12_kc_river.svg)

*V2 as committed, **C1C2C4C5-SUPERSPACE; C3 not imposed**. Click the image for the SVG; the full caption is in [TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5), and this page is the figure's spec.*

## In plain terms

This picture follows every allowed ordering at once as the sequence is built, one pair at a time.
The top panel shows, at each step, what share of orderings make each size of jump into the next
pair, where a jump's size is how many of the six lines change; the shares stay nearly level from
start to finish, and a black line traces King Wen's own jump at each step. The bottom panel splits
the orderings by their first free choice, 56 possibilities, and shows that a bigger group always
costs at least as much to search in full as a smaller one. "Allowed" here means obeying four of the
five core rules (all but the one called C3).

## What it shows

- **Upper panel, the river.** 31 unit-width layer bins, 0 to 30. Each band is one boundary-distance
  class d = 1, 2, 3, 4 or 6 (the number of lines that differ across the boundary into the new pair),
  and its height is that class's exact share of the superspace at that layer; each column sums to 1.
  King Wen's own class at each layer is the black step line with a white halo. Summed across the 31
  layers, each band's area is that class's budget, `2,8,13,7,1`, which the C1+C5 theorem fixes, so
  only the shape across layers carries information.
- **Lower panel, the branches.** The 56 top-level branches sorted by exact solution mass, each
  labelled pair : entry (the entry hexagram's six-bit code), with log₁₀ exhaustion cost in t-units
  (one t-unit is one valid oriented prefix) as a red line.

The full reading guide is [How to read it](#how-to-read-it) below.

## What it establishes, and what it does not

- **Establishes.** The per-layer class shares stay within 0.18 percentage points of their budget
  share on layers 1–29 ([TR-12 §2](../reports/TR12_QUERY_PROGRAM.md#2-visualization-program-v1v5),
  V2 caption; §12.6). The 56 branches fall into 7 mass levels that map one-to-one onto 7 cost levels,
  and 0 of the 1,540 branch pairs has the smaller mass with the larger cost: no branch is
  small-but-expensive at n=31.
- **Does not establish.** The Exhaustion Atlas's EXHAUSTIBLE/INFEASIBLE verdict, which is withheld
  (TR-12 §3); t-units price no production-search node. This is the **reduced form**
  (`TR12_V2=PASS:REDUCED-NO-BRANCH-CLASS-RIVER`): the river is split by distance class, not by
  top-level branch class as §2 first specified, and the joint split by first branch and distance
  class is carried neither by the atlas nor by the ladders. See
  [What this figure is allowed to claim](#what-this-figure-is-allowed-to-claim) and
  [What it may NOT claim](#what-it-may-not-claim).

## Provenance

- **Data.** [`reports/tr12/scan/v2_river.tsv`](../reports/tr12/scan/v2_river.tsv) (sha256 prefix
  `380111eb002e`) and [`reports/tr12/scan/v2_branches.tsv`](../reports/tr12/scan/v2_branches.tsv)
  (`3d75e6d619ba`), both printed in the figure's footer, written by the atlas consumer from
  `runs/20260906_kc_ladders_n31/atlas_n31.json`; the command is under [Generation](#generation).
- **Generator.** `fig_tr12_kc_river()` in [`viz/report_figures.py`](report_figures.py), called by
  `tr12_figures()`. Table in, figure out; it refuses an incomplete grid, and at n = 31 requires the
  branch table.
- **Regenerate.** The whole set, `cd reports/figures && python3 ../../viz/report_figures.py`, or
  this figure alone:

  ```bash
  cd reports/figures && python3 -c "import sys; sys.path.insert(0, '../../viz'); import report_figures as r; r.fig_tr12_kc_river('../tr12/scan/v2_river.tsv', '../tr12/scan/v2_branches.tsv')"
  ```

- **Toolchain.** matplotlib 3.11.0 and numpy 2.4.4. Under that pin the documented command reproduced
  the committed PNG byte for byte on 2026-09-29, with all twelve report figures (CX-233); see
  [Reproduce the figures](README.md#reproduce-the-figures).
- **Tokens.** `TR12_V2=PASS:REDUCED-NO-BRANCH-CLASS-RIVER` in
  [`reports/tr12/VERDICTS.txt`](../reports/tr12/VERDICTS.txt); `B0_FROM_COLUMN_SUMS=2,8,13,7,1`,
  printed by `python3 solve.py --atlas-probe runs/20260906_kc_ladders_n31/atlas_n31.json`
  (TR-12 §12.9).

## Review history

- **2026-09-23.** First rendered at n=31 (TR-12 §2).
- **2026-09-24.** The caption and the panel's subtitle said a small-but-expensive branch was the
  atlas's point, over a table that contradicts it; corrected (CX-75).
- **2026-09-26, Codex figure review VIZ1, checked by Fable.** The river was drawn as a linear
  interpolation whose band areas summed to 30, not 31 (F03), and the bands were told apart by colour
  only (F19). It is now 31 unit-width steps with labelled bands. CX-191, CX-192.
- **2026-09-27.** The caption said the column sums recover the budget; the band areas do (CX-224,
  item 5). A retracted limitation on the branch split was still asserted at three sites (item 11).
- **2026-09-28, Codex visualization review, triaged by Fable.** The branch cost column is checked
  (Q-894), CX-226. The band labels were set in their band colours at 2.2–2.4:1 on white; they are now
  dark text beside a swatch, and a key defines d, King Wen's line, the branch label and the t-unit,
  CX-227. The caption's correction history moved out of the reading text (Q-901), CX-228.
- **2026-09-29.** The figure is shown at the top of this page, and these summary sections were added
  as part of the [visual capstone](README.md) (CX-233).

*The rest of this page is the figure's specification and drafting record, kept as written, with its
dated corrections in place.*

## Status (2026-08-22)

| Panel | Quantity | Instrument | State |
|---|---|---|---|
| (a) distance-class river | layer-k mass split by the k-th transition's distance class d ∈ {1,2,3,4,6} | `solve --kc-scan` → `layers[].by_class` | **EXISTS** |
| (b) branch mass + exhaustion cost | per-branch total solutions and valid-prefix count | `solve --kc-scan … --kc-tdir TDIR` → `branch_atlas[]` | **EXISTS** (t-units need a `--kc-t-build` ladder) |
| (c) branch-class river | layer-k mass split by *top-level branch* | — | **PENDING, and not a flag** — see below |
| Full-31 f / g / t ladders | — | Stage F / G / T | **BUILT** — the committed `reports/tr12/scan/v2_river.tsv` / `v2_branches.tsv` came from the n=31 atlas, with `t_source = t-ladder` on the branch rows. ⚠ *Updated 2026-09-24: this read "NOT YET BUILT".* |
| Atlas JSON → figure TSV | — | `python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR` | **EXISTS** (n=9 brute-force gated: `--atlas-selftest`, `ATLAS_CONSUMER=PASS`) |

### Why panel (c) is not simply a missing flag

TR-12 §2 specifies V2's primary split as "layer-k mass split by **top-level branch class**". The
compiled DP state is `(canonical-mask, last, C5-residual)` — it carries **no tag for which
first-level branch a prefix descended from**, and two prefixes from different branches merge into
one state the moment their masks, exits and residuals agree. Recovering per-(layer, branch) mass
therefore needs a **branch-tagged forward ladder**: either 56 separate f ladders (one per branch;
the g ladder is backward and branch-independent, so it is shared) or one f ladder carrying a
56-wide value channel. Either way the payload is ≈56× the Stage-F retained ladder, which is
order-TB at full-31 — an order-10² TB artifact [ESTIMATED, hedged]. That is a re-build, not a
`--kc-scan` option, and it is **not priced or proposed here**.

What panel (b) gives instead is exact and cheap: the branch *terminal* widths (each branch's total
solution mass), which is the river's right-hand edge without the interior.

⚠ *Corrected 2026-09-25 (Q-699, V3A-143#1): the two paragraphs above attach the ≈56× ladder to the
wrong quantity.* **Completed-solution mass split by first branch needs no new ladder, because it
does not change with k.** A walk keeps its first branch at every layer, so the layer-k mass of
branch *b* is `solutions(b)` for every *k*, which is a flat band of the width panel (b) already
prints; the "interior" of that river is its right-hand edge repeated. Measured by exhaustive
enumeration at n=9 (26,112 walks, 12 first branches): branch (1, 32) carries 2,368 walks at every
one of the 9 layers. What a plain f ladder cannot give is a **finer** split: the joint of the layer-k
distance class and the first branch (for the same branch at n=9, its d = 2 count by layer is
0, 1824, 1824, 1088, 1824, 1824, 0, 1728, 1728), or the per-layer *prefix* count by branch. Either one
needs the branch-tagged forward ladder, and the ≈56× estimate applies to those. So panel (c) has to
say which of them it means before it is priced; "layer-k mass split by top-level branch", read as
solution mass, is already drawable and is flat.

## The quantity plotted

**Panel (a) — the distance-class river.** Let **SUPER** = C1 ∩ C2 ∩ C4 ∩ C5 (C3 is **not**
applied) with `N = |SUPER|` exact. Layer `k = 0 … 30` is the transition from depth *k* to depth
*k+1*, filling pair-slot *k+2*. The **distance class** of a transition is

```
d = popcount( exit(previous pair)  XOR  entry(new pair) )        d ∈ {1, 2, 3, 4, 6}
```

— the between-pair boundary distance. (d = 0 is impossible between distinct hexagrams; d = 5 is
killed by C2. C4 fixes the walk's starting exit, so layer 0's `d` is measured against hexagram 0.)

```
R[k][d] = # { w ∈ SUPER : the k-th free placement of w has boundary distance d }
        = Σ_{states s at layer k} Σ_{admissible c at s with class d}  orbit(mask(s)) · f(s) · g(s∘c)
share[k][d] = R[k][d] / N
```

The distance class is **G-invariant**, so the orbit-weighted quotient sum *is* the raw-frame total —
this stream is exact without the `--kc-raw` G-expansion (the atlas's `frames.flow` says so).

`Σ_d R[k][d] = N` for every *k*: every walk makes exactly one transition per layer, so the river's
total width is constant. The picture is a **redistribution**, never a growth or decay curve.

**Panel (b) — branch masses.** For each of the 56 admissible first placements *b* (global pair ×
orientation):

```
solutions(b)        = Σ over walks in SUPER starting with b      = branch_atlas[b].solutions
prefixes_t_units(b) = t-units in b's subtree, t(s) = 1 + Σ_c t(s∘c)  = branch_atlas[b].prefixes_t_units
```

with `Σ_b solutions(b) = N` and `1 + Σ_b prefixes_t_units(b) = t(root)` — both engine-gated.

## The King Wen overlay

King Wen's own boundary-distance sequence across the 31 layers is a **published constant**:

```
k :  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30
d :  2  4  3  4  4  2  4  2  3  3  2  3  2  2  3  3  4  2  6  3  4  3  3  3  4  1  2  3  3  1  3
```

reproduced from `solve.py`'s `binary_hexagrams` (single source of truth) as
`d_k = popcount(KW[2k+1] XOR KW[2k+2])`, and available in prose from
`python3 roae.py --wave` (the odd-indexed entries of the 63-value difference wave). It is carried in
the TSV's `kw_d` column so the plotting step never computes it.

**A theorem constrains the overlay and the river alike.** In every C1 + C5-valid ordering the 31
between-pair boundary distances form exactly the multiset **{1:2, 2:8, 3:13, 4:7, 6:1}** — machine
checked in [`lean/TrigramTheorems.lean`](../lean/TrigramTheorems.lean), see
[TRIGRAM_STRUCTURE.md](../documentation/TRIGRAM_STRUCTURE.md) and
[SPECIFICATION.md](../documentation/SPECIFICATION.md). Consequently

```
Σ_k share[k][d] = the multiset multiplicity of d      (2, 8, 13, 7, 1 for d = 1, 2, 3, 4, 6)
```

for **every** stream — the areas under the five bands are fixed by theorem, identically for King Wen
and for the population (the river is drawn as 31 unit-width steps, edges −0.5…30.5, so each band's area is exactly this sum). **Only the shape across k is informative**, never the totals.

## Input TSV

`reports/tr12/scan/v2_river.tsv` — tidy format, `31 × 5 = 155` data rows at full-31:

| Column | Type | Meaning |
|---|---|---|
| `k` | int, 0…30 | ladder layer; fills pair-slot `k + 2` |
| `d` | int ∈ {1,2,3,4,6} | boundary distance class of the k-th transition |
| `mass` | decimal **string** | `R[k][d]`, exact 192-bit integer — parse with `int()` |
| `p` | float | `R[k][d] / N`, the plotted band height |
| `kw_d` | int | King Wen's own class at layer *k* (`-1` when n ≠ 31) |

`reports/tr12/scan/v2_branches.tsv` — one row per branch, 56 rows at full-31:

| Column | Type | Meaning |
|---|---|---|
| `branch` | int | row index in `branch_atlas[]` |
| `pair` | int, 1…31 | global pair index of the first placement |
| `entry`, `exit` | int, 0…63 | the branch's entry / exit hexagram (orientation) |
| `d` | int | the branch's own boundary class (`popcount(entry)`, since C4 fixes the start exit to hexagram 0) |
| `solutions` | decimal **string** | exact walks through this branch |
| `share` | float | `solutions / N` |
| `prefixes_t_units` | decimal string or `PENDING_T_LADDER(...)` | exhaustion cost in valid-prefix units |
| `t_source` | string | `t-ladder` — written by the producer whenever `--kc-tdir` was given — or `ABSENT`, the consumer's placeholder for a branch that carries no such key. `ABSENT` (or any other value) FAILS the XA-b gate: reading `t-ladder` is pre-registered. The consumer does **not** infer a provenance the producer never wrote |
| `kw` | 0/1 | 1 for King Wen's own first placement (pair 1, `entry = KW[2]`, `exit = KW[3]`) |

## Generation

**Rehearsal at n=9 (sub-second, runs today, local)** — note the class multiset at n=9 is
{1:2, 2:5, 4:2}, the reduced-world analogue of {1:2, 2:8, 3:13, 4:7, 6:1}:

```bash
# run from the repository root (solve.c and solve.py live there)
B=/tmp/kcbuild-$$; mkdir -p $B
gcc -O2 -pthread -fopenmp -o $B/solve solve.c -lm -lz
A=$B/n9; mkdir -p $A/f $A/g $A/t
$B/solve --kc-build   $A/f --f1-pairs 9
$B/solve --kc-g-build $A/g --f1-pairs 9
$B/solve --kc-t-build $A/f $A/t
$B/solve --kc-scan    $A/f $A/g $A/atlas.json --kc-tdir $A/t
$B/solve --kc-scan-selftest                              # expect: PASS (0 failures)
```

**Full-31 (run once, 2026-09; repeating it needs the f/g/t ladders mounted — re-rendering does not):**

```bash
solve --kc-scan FDIR GDIR reports/tr12/scan/atlas.json --kc-tdir TDIR [--kc-ooc] [--kc-cache-mb MB]
```

Panel (a) needs **no** `--kc-raw` (the class stream is G-invariant); panel (b)'s
`prefixes_t_units` column needs `--kc-tdir` pointing at a `--kc-t-build` ladder, otherwise the
atlas writes `PENDING_T_LADDER(--kc-t-build; TR12 s8 item 4)` and the panel ships without the
exhaustion series.

**Atlas JSON → TSV** — the atlas consumer:

```bash
python3 solve.py --atlas-queries runs/20260906_kc_ladders_n31/atlas_n31.json --atlas-out reports/tr12 --atlas-select v2
#   writes reports/tr12/scan/v2_river.tsv + reports/tr12/scan/v2_branches.tsv and TR12_V2= in reports/tr12/VERDICTS.txt
```

**The full-31 atlas is in this repository:** `runs/20260906_kc_ladders_n31/atlas_n31.json`
(5,978,126 B, 31 layers, raw sha256 `9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558`),
and the command above reads it. It re-derives `reports/tr12/scan/v2_river.tsv` and `v2_branches.tsv` with no ladder mounted;
`python3 solve.py --atlas-probe runs/20260906_kc_ladders_n31/atlas_n31.json` checks the file first
(`ATLAS_PROBE=PASS`). The output path in the `--kc-scan` line above is where a **rebuild** from the
ladders would write a fresh atlas; the ladders themselves are not distributed.

The `prefixes_t_units` column is passed through verbatim — a decimal string when a t-ladder was
mounted, `PENDING_T_LADDER(...)` when it was not. Gated at n=9 by
`python3 solve.py --atlas-selftest ATLAS.json --atlas-walks WALKS.txt` (`ATLAS_CONSUMER=PASS`),
which additionally checks `Σ_b solutions(b) == N` and `1 + Σ_b prefixes_t_units(b) == t(root)`.


**TSV → figure:** `viz/report_figures.py` (`fig_tr12_kc_river`) — a stepped `matplotlib` stack (31 unit-width layer bins) of the
five `p` bands against `k`, King Wen's `kw_d` drawn as a step line, plus a sorted bar panel of
`v2_branches.tsv`. TSV in, figure out; **no analysis logic in `viz/`**.

## How to read it

- **Band height at column k** = the exact fraction of the superspace whose *k*-th boundary has that
  distance. The total height is 1 at every column, by construction.
- **Band migration** is the content: which distances the constraint system spends early and which it
  is forced to hold in reserve. Each band is a population marginal at that layer. Walks spend their
  budgets at different positions, so these bands do not show an individual walk's budget running out.
  ⚠ *(corrected 2026-09-26, Codex VIZ1 F04: this read "a class's band must go to zero once its budget is spent"; all five bands stay positive at k = 30.)*
- **The d = 6 band is the sharpest signal**: exactly one d = 6 boundary exists in every valid
  ordering (the "9th six" of [MCKENNA.md](../documentation/MCKENNA.md)), so its band across *k* is
  the exact positional distribution of a single forced event. King Wen puts it at k = 18.
- **King Wen's step line** should be read as *which band it is standing in*, not as a height.
- **Panel (b)**: branch bars sorted by mass show how unevenly the space divides at the first
  placement; the paired `prefixes_t_units` series is the exhaustion cost of the same branch, so a
  branch that is small in solutions but large in prefixes is expensive per result. ⚠ *Measured on the committed
  full-31 table (2026-09-24), no such branch exists:* the 56 branches form 7 mass levels mapping
  one-to-one onto 7 cost levels, 0 of 1,540 branch pairs are discordant, and cost per solution spans
  7.65–8.20 t-units. The panel shows mass and cost **co-monotone**; read it that way.

## What this figure is allowed to claim

1. **Exact per-layer class masses over the whole superspace** — population quantities, not samples.
2. **Where in the ordering each C5 distance class is spent**, exactly.
3. **The exact positional distribution of the unique d = 6 boundary**, and King Wen's position
   within it.
4. **Exact per-branch solution mass** (panel b), and — with a t ladder — the exact per-branch
   exhaustion cost in valid-prefix units, which is the input to the exhaustibility verdict.

## What it may NOT claim

- **Nothing about C3 or C15.** Space label `C1C2C4C5-SUPERSPACE` belongs in every caption.
- **The band areas are not results.** `Σ_k share[k][d]` is fixed by the C1 + C5 boundary-distance
  theorem; quoting "13 threes" from this figure as a measurement would be quoting a theorem back at
  itself.
- **No exhaustibility claim from panel (b) alone.** `prefixes_t_units` counts **valid prefixes**;
  its mapping to `solve.c`'s `SOLVE_NODE_LIMIT` node-counter semantics is a *separate* certificate
  (`--kc-t-cert`), and the atlas says so in its own `t_units_note`. No wall-clock or dollar figure
  may be derived until that convention pin is in hand.
- **Per-layer argmin trivia is not a finding.** TR-12 §9 declines "loneliest corridor" claims
  explicitly: a minimum-mass corridor is expected in any large DP and distinguishes nothing.
- **Panel (a) is not the branch river.** Do not describe the class bands as branches; they are
  transition classes. A completed-solution river by first branch is available from `v2_branches.tsv` and is flat (not drawn); the joint branch × class river is PENDING and expensive (above).
- **King Wen's step line is not a percentile.** Per-layer percentile-of-mass is a
  [V5](viz_kc_grammar.md) / Q6 quantity; this figure only shows which band King Wen occupies.

## Verification gates

| Gate | Where |
|---|---|
| per-layer flow == N | `gates.per_layer_flow_eq_N` in the atlas |
| per-layer class row sum == N | `gates.class_row_sums_eq_N` (2026-09-08) |
| per-layer quotient marginal row sum == N | `gates.quotient_marginal_sums_eq_N` (2026-09-08; a frame this figure does not plot) |
| `Σ_k cls[k][d]` == `b0[d] · N` | `gates.class_column_sums_eq_b0_N` (2026-09-08) — the engine-side form of the reader-side `(2, 8, 13, 7, 1)` identity below, and the only gate that sees a `d1`/`d2` swap inside one layer row |
| branch masses sum == N | `gates.branch_masses_sum_eq_N` |
| `1 + Σ_b prefixes_t_units == t(root)` | gated inside `--kc-scan` when `--kc-tdir` is given |
| t-ladder vs direct recursion at small n | `solve --kc-t-selftest`, `solve --kc-scan-selftest` |
| **reader-side:** each column of `p` sums to 1.0 | `awk -F'\t' 'NR>1{s[$1]+=$4} END{for (k in s) print k, s[k]}' reports/tr12/scan/v2_river.tsv` |
| **reader-side:** `Σ_k p[k][d]` == (2, 8, 13, 7, 1) | `awk -F'\t' 'NR>1{t[$2]+=$4} END{for (d in t) print d, t[d]}' reports/tr12/scan/v2_river.tsv` |
| **reader-side:** `share` column of the branch TSV sums to 1.0 | `awk -F'\t' 'NR>1{s+=$7} END{print s}' reports/tr12/scan/v2_branches.tsv` |

Both reader-side identities were exercised against the committed n=9 reference atlas
(`{1:2, 2:5, 4:2}`, per-layer sums 1.0) before this doc was written.

**Named keys are not a count of gate families.** The published atlas is schema version 2: its
`gates` object holds **14** named checks plus `fails`, and `tail_checks` holds **five** named checks
plus `fails` (counted in `atlas_n31.json`; Q-901, 2026-09-28: this said "seven advertised keys"). Those are emitted-field counts, not the engine's internal gate families. A named
`gates` value that ran collapses to `"see fails"` if *any* gate failed, named or not — coarse, but never
a false positive. Read `fails` first. There is deliberately **no** vertical `quotient_marginal`
gate: `kc_flookup` re-canonicalises with `f1_canon` on every lookup, so `q` indexes *this* layer's
canonical mask and is not the same slot at `k+1`; the layer-summed quotient marginal has no closed
form and must not be asserted. Full accounting in
[SOLVE_C_CLI.md](../documentation/SOLVE_C_CLI.md).

## Where the files live

- **This doc:** `viz/viz_kc_river.md`
- **Generator (TSV → figure):** `viz/report_figures.py`
- **Evidence TSVs:** `reports/tr12/scan/v2_river.tsv`, `reports/tr12/scan/v2_branches.tsv`
- **Figures:** `reports/figures/fig_tr12_kc_river.{png,svg}` (committed). The renderer writes to its working directory, and nothing is
  mirrored: no per-run copy under `runs/<run-id>/viz/` exists; render into a scratch directory to compare (Q-901, 2026-09-28).

## Related

- [BRANCHES_EXPLAINED.md](../documentation/BRANCHES_EXPLAINED.md) — the 56 first-level branches.
- [TRIGRAM_STRUCTURE.md](../documentation/TRIGRAM_STRUCTURE.md) /
  [MCKENNA.md](../documentation/MCKENNA.md) — the forced boundary-distance multiset and the
  "9th six".
- [SPECIFICATION.md](../documentation/SPECIFICATION.md) — C5 and the difference-wave budget.

---

*Specification per TR-12 §2 (V2). Nothing novel is claimed: a stacked-area flow plot over a counting
DP's layer masses. Developed with AI assistance (Claude, Anthropic); corrections invited.*
