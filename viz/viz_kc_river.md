# Visualization — V2, the mass river (how the superspace's mass flows across the ordering)

**Where the whole superspace goes, layer by layer.** At every one of the 31 free placements the
space splits into streams; the river plots the exact width of each stream as it flows left to
right across the ordering, with King Wen's own path drawn on top. A companion panel gives the exact
mass — and the exact exhaustion cost — of each of the 56 first-level branches.

← Back to [README.md](README.md) (index) · V-family: [V1 field](viz_kc_field.md) · **V2** ·
[V3 spectrum](viz_kc_spectrum.md) · [V4 shells](viz_kc_shells.md) · [V5 grammar](viz_kc_grammar.md)

## Status (2026-08-22)

| Panel | Quantity | Instrument | State |
|---|---|---|---|
| (a) distance-class river | layer-k mass split by the k-th transition's distance class d ∈ {1,2,3,4,6} | `solve --kc-scan` → `layers[].by_class` | **EXISTS** |
| (b) branch mass + exhaustion cost | per-branch total solutions and valid-prefix count | `solve --kc-scan … --kc-tdir TDIR` → `branch_atlas[]` | **EXISTS** (t-units need a `--kc-t-build` ladder) |
| (c) branch-class river | layer-k mass split by *top-level branch* | — | **PENDING, and not a flag** — see below |
| Full-31 f / g / t ladders | — | Stage F / G / T | **NOT YET BUILT** |
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
and for the population. **Only the shape across k is informative**, never the totals.

## Input TSV

`tr12/scan/v2_river.tsv` — tidy format, `31 × 5 = 155` data rows at full-31:

| Column | Type | Meaning |
|---|---|---|
| `k` | int, 0…30 | ladder layer; fills pair-slot `k + 2` |
| `d` | int ∈ {1,2,3,4,6} | boundary distance class of the k-th transition |
| `mass` | decimal **string** | `R[k][d]`, exact 192-bit integer — parse with `int()` |
| `p` | float | `R[k][d] / N`, the plotted band height |
| `kw_d` | int | King Wen's own class at layer *k* (`-1` when n ≠ 31) |

`tr12/scan/v2_branches.tsv` — one row per branch, 56 rows at full-31:

| Column | Type | Meaning |
|---|---|---|
| `branch` | int | row index in `branch_atlas[]` |
| `pair` | int, 1…31 | global pair index of the first placement |
| `entry`, `exit` | int, 0…63 | the branch's entry / exit hexagram (orientation) |
| `d` | int | the branch's own boundary class (`popcount(entry)`, since C4 fixes the start exit to hexagram 0) |
| `solutions` | decimal **string** | exact walks through this branch |
| `share` | float | `solutions / N` |
| `prefixes_t_units` | decimal string or `PENDING_T_LADDER(...)` | exhaustion cost in valid-prefix units |
| `t_source` | string | `t-ladder`, or absent when computed by direct recursion at small n |
| `kw` | 0/1 | 1 for King Wen's own first placement (pair 1, `entry = KW[2]`, `exit = KW[3]`) |

## Generation

**Rehearsal at n=9 (sub-second, runs today, $0)** — note the class multiset at n=9 is
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

**Full-31 (PENDING the ladders):**

```bash
solve --kc-scan FDIR GDIR tr12/scan/atlas.json --kc-tdir TDIR [--kc-ooc] [--kc-cache-mb MB]
```

Panel (a) needs **no** `--kc-raw` (the class stream is G-invariant); panel (b)'s
`prefixes_t_units` column needs `--kc-tdir` pointing at a `--kc-t-build` ladder, otherwise the
atlas writes `PENDING_T_LADDER(--kc-t-build; TR12 s8 item 4)` and the panel ships without the
exhaustion series.

**Atlas JSON → TSV** — the atlas consumer:

```bash
python3 solve.py --atlas-queries tr12/scan/atlas.json --atlas-out tr12 --atlas-select v2
#   writes tr12/scan/v2_river.tsv + tr12/scan/v2_branches.tsv and TR12_V2= in tr12/VERDICTS.txt
```

The `prefixes_t_units` column is passed through verbatim — a decimal string when a t-ladder was
mounted, `PENDING_T_LADDER(...)` when it was not. Gated at n=9 by
`python3 solve.py --atlas-selftest ATLAS.json --atlas-walks WALKS.txt` (`ATLAS_CONSUMER=PASS`),
which additionally checks `Σ_b solutions(b) == N` and `1 + Σ_b prefixes_t_units(b) == t(root)`.


**TSV → figure:** `viz/report_figures.py` (`fig_tr12_kc_river`) — a `matplotlib` `stackplot` of the
five `p` bands against `k`, King Wen's `kw_d` drawn as a step line, plus a sorted bar panel of
`v2_branches.tsv`. TSV in, figure out; **no analysis logic in `viz/`**.

## How to read it

- **Band height at column k** = the exact fraction of the superspace whose *k*-th boundary has that
  distance. The total height is 1 at every column, by construction.
- **Band migration** is the content: which distances the constraint system spends early and which it
  is forced to hold in reserve. The C5 budget (2, 8, 13, 7, 1 boundaries of each class) is consumed
  as the walk proceeds, so a class's band must go to zero once its budget is spent — look for where
  each band's *last* mass sits.
- **The d = 6 band is the sharpest signal**: exactly one d = 6 boundary exists in every valid
  ordering (the "9th six" of [MCKENNA.md](../documentation/MCKENNA.md)), so its band across *k* is
  the exact positional distribution of a single forced event. King Wen puts it at k = 18.
- **King Wen's step line** should be read as *which band it is standing in*, not as a height.
- **Panel (b)**: branch bars sorted by mass show how unevenly the space divides at the first
  placement; the paired `prefixes_t_units` series is the exhaustion cost of the same branch, so a
  branch that is small in solutions but large in prefixes is expensive per result.

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
  transition classes. The branch river is PENDING and expensive (above).
- **King Wen's step line is not a percentile.** Per-layer percentile-of-mass is a
  [V5](viz_kc_grammar.md) / Q6 quantity; this figure only shows which band King Wen occupies.

## Verification gates

| Gate | Where |
|---|---|
| per-layer flow == N | `gates.per_layer_flow_eq_N` in the atlas |
| branch masses sum == N | `gates.branch_masses_sum_eq_N` |
| `1 + Σ_b prefixes_t_units == t(root)` | gated inside `--kc-scan` when `--kc-tdir` is given |
| t-ladder vs direct recursion at small n | `solve --kc-t-selftest`, `solve --kc-scan-selftest` |
| **reader-side:** each column of `p` sums to 1.0 | `awk -F'\t' 'NR>1{s[$1]+=$4} END{for (k in s) print k, s[k]}' tr12/scan/v2_river.tsv` |
| **reader-side:** `Σ_k p[k][d]` == (2, 8, 13, 7, 1) | `awk -F'\t' 'NR>1{t[$2]+=$4} END{for (d in t) print d, t[d]}' tr12/scan/v2_river.tsv` |
| **reader-side:** `share` column of the branch TSV sums to 1.0 | `awk -F'\t' 'NR>1{s+=$7} END{print s}' tr12/scan/v2_branches.tsv` |

Both reader-side identities were exercised against the committed n=9 reference atlas
(`{1:2, 2:5, 4:2}`, per-layer sums 1.0) before this doc was written.

## Where the files live

- **This doc:** `viz/viz_kc_river.md`
- **Generator (TSV → figure):** `viz/report_figures.py`
- **Evidence TSVs:** `tr12/scan/v2_river.tsv`, `tr12/scan/v2_branches.tsv`
- **Figures:** `runs/<run-id>/viz/viz_kc_river.{png,svg}` → mirrored to
  `reports/figures/fig_tr12_kc_river.{png,svg}`

## Related

- [BRANCHES_EXPLAINED.md](../documentation/BRANCHES_EXPLAINED.md) — the 56 first-level branches.
- [TRIGRAM_STRUCTURE.md](../documentation/TRIGRAM_STRUCTURE.md) /
  [MCKENNA.md](../documentation/MCKENNA.md) — the forced boundary-distance multiset and the
  "9th six".
- [SPECIFICATION.md](../documentation/SPECIFICATION.md) — C5 and the difference-wave budget.

---

*Specification per TR-12 §2 (V2). Nothing novel is claimed: a stacked-area flow plot over a counting
DP's layer masses. Developed with AI assistance (Claude, Anthropic); corrections invited.*
