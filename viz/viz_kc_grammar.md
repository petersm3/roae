# Visualization — V5, the transition grammar (what the space is allowed to say next)

**The conditional law of the next move, exactly, at every point in the ordering.** Given that a walk
has reached layer *k*, what is the exact probability — over the whole superspace, not a sample —
that its next transition belongs to each choice class? The grammar is that conditional law rendered
as a heat map over `class × k`, with King Wen's own 31 choices marked on it.

← Back to [README.md](README.md) (index) · V-family: [V1 field](viz_kc_field.md) ·
[V2 river](viz_kc_river.md) · [V3 spectrum](viz_kc_spectrum.md) · [V4 shells](viz_kc_shells.md) ·
**V5**

## Status (2026-08-22)

| Axis | Quantity | Instrument | State |
|---|---|---|---|
| distance class `d ∈ {1,2,3,4,6}` | `P(d \| layer k)` | `solve --kc-scan` → `layers[].by_class` | **EXISTS** |
| × new-pair category | the cross-tab `P(d, category \| layer k)` | — | **PENDING** — proposed `--kc-scan … --kc-grammar-cross`, **and the category itself is unpinned** (below) |
| Full-31 f and g ladders | — | Stage F / Stage G | **NOT YET BUILT** |
| Atlas JSON → figure TSV | — | `python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR` | **EXISTS** (n=9 brute-force gated: `--atlas-selftest`, `ATLAS_CONSUMER=PASS`) |

### Read this before treating V5 as a separate figure from V2

With only the distance-class axis available, **V5 and [V2](viz_kc_river.md) plot the same numbers.**
The layer flow is `N` at every layer (every walk makes exactly one transition per layer — this is an
engine-gated identity), so the conditional and the joint coincide:

```
P(d | layer k) = R[k][d] / flow[k] = R[k][d] / N = share[k][d]
```

V2 renders them as a stacked flow read left-to-right; V5 renders them as a normalized heat map read
column-by-column. That is a legitimate difference of *rhetoric*, not of content. **What makes V5 a
genuinely distinct figure is the second axis, and that axis is PENDING.** Until it lands, publishing
both figures side by side without saying so would overstate the evidence; say it in the caption.

### The unpinned definition

TR-12 §2 specifies V5's choice classes as "distance class d ∈ {1,2,3,4,6} × **new-pair category**"
and does not define "new-pair category" anywhere else. It must be pinned by the operator before the
cross-tab is built. The natural candidate — and the only one that is free, exact and safe in the
quotient DP — is the **within-pair Hamming distance of the newly placed pair**,
`w = popcount(entry XOR exit) ∈ {2, 4, 6}`, whose multiset over the 32 pairs is fixed by C1 to
{2:12, 4:12, 6:8} ([SPECIFICATION.md](../documentation/SPECIFICATION.md), machine-checked in
[`lean/TrigramTheorems.lean`](../lean/TrigramTheorems.lean)). `w` is a function of the chosen pair
alone and is invariant under the order-24 canonicalisation group, so it can be accumulated at the
existing `--kc-scan` transition site as 5 × 3 = 15 counters per layer instead of 5 — **a cheap flag,
not a re-build**. (Contrast [V2](viz_kc_river.md)'s branch split, which the DP state genuinely
cannot support.) Other readings — pair orbit, trigram class — are possible and would need their own
G-invariance argument. This doc does **not** pick one; it records the candidate and the reason.

## The quantity plotted

Let **SUPER** = C1 ∩ C2 ∩ C4 ∩ C5 (C3 is **not** applied), `N = |SUPER|` exact, and let layer
`k = 0 … 30` be the transition from depth *k* to depth *k+1*, filling pair-slot *k+2*. For a
transition, the **distance class** is the between-pair boundary distance

```
d = popcount( exit(previous pair)  XOR  entry(new pair) )        d ∈ {1, 2, 3, 4, 6}
```

(d = 0 impossible, d = 5 killed by C2; C4 fixes the start exit to hexagram 0, so layer 0's `d` is
`popcount(entry)`). The plotted cell is

```
G[k][d] = Σ_{states s at layer k} Σ_{admissible c at s of class d}  orbit(mask(s)) · f(s) · g(s∘c)
P[k][d] = G[k][d] / N                                    ∈ [0,1],   Σ_d P[k][d] = 1 for every k
```

`d` is G-invariant, so the orbit-weighted quotient sum is exactly the raw-frame total — no
`--kc-raw` G-expansion is needed for this figure (the atlas's `frames.flow` field states this).

With the cross-tab (PENDING) the cell becomes `P[k][d][w] = G[k][d][w] / N`, and the heat map's row
axis becomes the 15 `(d, w)` classes — of which only the admissible combinations are non-zero.

## Input TSV

`tr12/scan/v5_grammar.tsv` — tidy format, `31 × 5 = 155` data rows at full-31 (`31 × 15 = 465` once
the cross-tab lands):

| Column | Type | Meaning |
|---|---|---|
| `k` | int, 0…30 | ladder layer; fills pair-slot `k + 2` |
| `d` | int ∈ {1,2,3,4,6} | boundary distance class of the transition |
| `w` | int ∈ {2,4,6} or `-1` | within-pair distance of the newly placed pair; `-1` = **PENDING**, cross-tab not emitted |
| `mass` | decimal **string** | `G[k][d]` (or `G[k][d][w]`), exact 192-bit — parse with `int()` |
| `p_cond` | float | `mass / N` = `P(class \| layer k)`, the plotted value |
| `kw_d` | int | King Wen's own boundary class at layer *k* (`-1` when n ≠ 31) |
| `kw_w` | int | within-pair distance of the pair King Wen places at layer *k* (`-1` when n ≠ 31) |

`p_cond` rather than `p` names what the figure is: a **conditional** law. Column sums are 1 by
construction and the column-sum check is the reader's first gate.

## Generation

**Rehearsal at n=9 (sub-second, runs today, $0):**

```bash
# run from the repository root (solve.c and solve.py live there)
B=/tmp/kcbuild-$$; mkdir -p $B
gcc -O2 -pthread -fopenmp -o $B/solve solve.c -lm -lz
A=$B/n9; mkdir -p $A/f $A/g
$B/solve --kc-build   $A/f --f1-pairs 9
$B/solve --kc-g-build $A/g --f1-pairs 9
$B/solve --kc-scan    $A/f $A/g $A/atlas.json
$B/solve --kc-scan-selftest                        # expect: PASS (0 failures)
```

**Full-31 (PENDING the ladders):**

```bash
solve --kc-scan FDIR GDIR tr12/scan/atlas.json [--kc-ooc] [--kc-cache-mb MB]
#   --kc-raw is NOT needed for this figure; --kc-tdir is NOT needed for this figure.
```

**Atlas JSON → TSV** — the atlas consumer. The `w = -1` placeholder is emitted honestly rather
than guessed: the scan does not emit the (distance × within-pair) cross-tab.

```bash
python3 solve.py --atlas-queries tr12/scan/atlas.json --atlas-out tr12 --atlas-select v5
#   writes tr12/scan/v5_grammar.tsv and TR12_V5= in tr12/VERDICTS.txt
```

The consumer refuses to write this table if any layer's `flow` differs from `N_total` — a
conditional law whose conditioning mass is wrong is a gate failure, not a figure. Gated at n=9 by
`--atlas-selftest` (`ATLAS_CONSUMER=PASS`).


**TSV → figure:** `viz/report_figures.py` (`fig_tr12_kc_grammar`) — a `matplotlib` `imshow` of
`p_cond` pivoted to `class × k`, with the `(kw_d, kw_w)` cell of each column outlined. TSV in,
figure out; **no analysis logic in `viz/`**.

## How to read it

- **Each column is a probability distribution over classes**, conditioned on having reached that
  layer. Read the heat map **down**, never across; brightness in different columns is comparable
  only because every column sums to 1.
- **The grammar tightens as the budget is spent.** C5 allots exactly (2, 8, 13, 7, 1) boundaries of
  classes (1, 2, 3, 4, 6) across the 31 transitions
  ([TRIGRAM_STRUCTURE.md](../documentation/TRIGRAM_STRUCTURE.md)); once a class's allotment is
  exhausted along a prefix its probability drops to zero for those walks, so late columns should
  concentrate on the classes with budget left. Rows going dark from the right is the expected
  signature.
- **The d = 6 row is a single forced event.** Exactly one d = 6 boundary exists in every valid
  ordering, so that row *is* its exact positional distribution — the population version of the
  "9th six" ([MCKENNA.md](../documentation/MCKENNA.md)). King Wen puts it at k = 18.
- **The King Wen marks** show which cell King Wen occupied at each layer. The readable question is
  whether those cells are the bright ones (King Wen follows the grammar's mode) or the dim ones
  (King Wen takes low-probability transitions), layer by layer.
- **A near-uniform column** means the constraint system leaves that position genuinely open; a
  near-degenerate column means it is effectively forced.

## What this figure is allowed to claim

1. **Exact conditional transition probabilities** over the entire superspace, per layer — the
   "grammar" of the space in the literal sense, with no estimator anywhere.
2. **Where the C5 budget binds**, positionally and exactly.
3. **The exact positional law of the unique d = 6 boundary**, and King Wen's position in it.
4. **Whether King Wen's individual transitions are modal or marginal** under that grammar — per
   layer, marginally.

## What it may NOT claim

- **Nothing about C3 or C15.** The space is C1 ∩ C2 ∩ C4 ∩ C5; `--kc-scan` has no `--kc-c3-max`
  axis. Every caption carries `C1C2C4C5-SUPERSPACE`.
- **This is not a Markov model, and the columns do not compose.** `P(d | layer k)` is a marginal of
  the exact walk measure, not a transition kernel: multiplying across columns does **not** give the
  probability of a class sequence, because successive choices are strongly dependent through the
  shared C5 residual. Any "the grammar predicts …" phrasing is wrong. The exact chain-rule
  decomposition along a *specific* walk is [V4](viz_kc_shells.md).
- **It is not independent evidence from V2** while the `w` axis is PENDING — same numbers, different
  rendering. Say so in the caption.
- **Row totals are theorems, not measurements.** `Σ_k P[k][d]` is the C1 + C5 forced multiset
  (2, 8, 13, 7, 1); quoting it from this figure quotes a theorem back at itself.
- **A dim King Wen cell is not a finding by itself.** TR-12 §9 declines per-layer argmin
  "loneliest corridor" trivia: extreme cells exist in any large DP. A distinguishing claim needs a
  pre-registered null, not a heat map.
- **Do not plot the quotient marginals here.** `layers[].marginal_quotient` is a different frame
  with non-identity pair labels; it belongs to neither V5 nor [V1](viz_kc_field.md).

## Verification gates

| Gate | Where |
|---|---|
| per-layer orbit-weighted flow == N | `gates.per_layer_flow_eq_N` in the atlas (the denominator of every plotted value) |
| branch masses sum == N | `gates.branch_masses_sum_eq_N` |
| n=9 exhaustive brute-force cross-check of the extractor | `solve --kc-scan-selftest` |
| f·g cut identity at every layer | `solve --kc-g-check FDIR GDIR` |
| **cross-tab gate** (PENDING with the flag) | `Σ_w G[k][d][w] == G[k][d]` at every `(k, d)`, plus an n=9 exhaustive brute-force check **shown able to fail** before any full-31 use |
| **reader-side:** every column of `p_cond` sums to 1.0 | `awk -F'\t' 'NR>1{s[$1]+=$5} END{for (k in s) print k, s[k]}' tr12/scan/v5_grammar.tsv` |
| **reader-side:** `Σ_k p_cond[k][d]` == (2, 8, 13, 7, 1) | `awk -F'\t' 'NR>1{t[$2]+=$5} END{for (d in t) print d, t[d]}' tr12/scan/v5_grammar.tsv` |

Both reader-side identities were exercised against the committed n=9 reference atlas (per-layer sums
1.0; class totals {1:2, 2:5, 4:2}, the reduced-world analogue of {1:2, 2:8, 3:13, 4:7, 6:1}) before
this doc was written.

## Where the files live

- **This doc:** `viz/viz_kc_grammar.md`
- **Generator (TSV → figure):** `viz/report_figures.py`
- **Evidence TSV:** `tr12/scan/v5_grammar.tsv`
- **Figures:** `runs/<run-id>/viz/viz_kc_grammar.{png,svg}` → mirrored to
  `reports/figures/fig_tr12_kc_grammar.{png,svg}`

## Related

- [SPECIFICATION.md](../documentation/SPECIFICATION.md) — C5's difference-wave budget and the forced
  within-pair / between-pair multisets.
- [TRIGRAM_STRUCTURE.md](../documentation/TRIGRAM_STRUCTURE.md) /
  [MCKENNA.md](../documentation/MCKENNA.md) — the boundary-distance theorem and the "9th six".
- [SOLVE_C_CLI.md](../documentation/SOLVE_C_CLI.md) — the `--kc-*` family; `--kc-scan` semantics
  live in the KC-H module header in `solve.c`.

---

*Specification per TR-12 §2 (V5). Nothing novel is claimed: a conditional-probability heat map over
a counting DP's transition masses. Developed with AI assistance (Claude, Anthropic); corrections
invited.*
