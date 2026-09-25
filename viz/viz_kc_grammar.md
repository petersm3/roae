# Visualization — V5, the transition grammar (what the space is allowed to say next)

**The conditional law of the next move, exactly, at every point in the ordering.** Given that a walk
has reached layer *k*, what is the exact probability — over the whole superspace, not a sample —
that its next transition belongs to each choice class? The grammar is that conditional law rendered
as a heat map over `class × k`, with King Wen's own 31 choices marked on it.

← Back to [README.md](README.md) (index) · V-family: [V1 field](viz_kc_field.md) ·
[V2 river](viz_kc_river.md) · [V3 spectrum](viz_kc_spectrum.md) · [V4 shells](viz_kc_shells.md) ·
**V5**

## Status (2026-08-22; `w` axis updated 2026-09-24)

| Axis | Quantity | Instrument | State |
|---|---|---|---|
| distance class `d ∈ {1,2,3,4,6}` | `P(d \| layer k)` | `solve --kc-scan` → `layers[].by_class` | **EXISTS** |
| × new-pair category, **pinned as `w` = within-pair distance** (below) | the cross-tab `P(d, w \| layer k)` | consumer-side from `layers[].kernel` (`solve.py` `atlas_emit_v5`); needs an atlas scanned with `--kc-raw` | **EXISTS (2026-09-23)** — `TR12_V5=PASS`; the committed full-31 `tr12/scan/v5_grammar.tsv` carries it (465 rows) |
| Full-31 f and g ladders | — | Stage F / Stage G | **BUILT** — the committed full-31 TSV was emitted from the n=31 atlas (TR-12 §2) |
| Atlas JSON → figure TSV | — | `python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR` | **EXISTS** (n=9 brute-force gated: `--atlas-selftest`, `ATLAS_CONSUMER=PASS`) |

> ⚠ **Also orbit-replicated.** Any per-pair refinement of this grammar inherits the seven-orbit
> structure of [V1](viz_kc_field.md): pairs in one orbit are exchanged by a symmetry of the space, so
> their rows are **equal exactly**. At most **7** distinct pair-rows exist, not 32, and a per-pair
> claim is really a claim about that pair's whole orbit. The pinned `w` axis is **coarser still**:
> `w` is constant on every orbit and takes only three values across the seven
> (`w=2`: orbits [3,7,11], [4,6,21], [10,15,20,23,27,29]; `w=4`: [1,9,17,19,22,25],
> [2,12,16,18,24,28]; `w=6`: [5,8,26,31], [13,14,30] — checked 2026-09-24 against
> `solve.py king_wen_pairs()` and the orbit list in [V1](viz_kc_field.md)), so a `w` row is a
> statement about **3 orbit-classes, never about an individual pair**.

### Read this before treating V5 as a separate figure from V2

🔴 **No longer true as of 2026-09-23 — V5 and [V2](viz_kc_river.md) now plot DIFFERENT numbers.**
This read *"With only the distance-class axis available, V5 and V2 plot the same numbers"*, which was
correct while the `w` axis was absent: the layer flow is N at every layer, so the conditional and the
joint coincided. With the `(d,w)` cross-tab built, they do not. **What V5 adds over V2 is the per-layer `P(w|k)` marginal, not a measured dependence.** On layers
1–30 the joint `P(d,w|k)` is within **0.0097** of `P(d|k)·P(w|k)` (maximum at k=1, d=3, w=4;
`V5_FACTORISATION_MAX_DEV_K_GE_1=0.0097`), so the cross-tab is reconstructible from its two marginals
to within 1 %. The all-layer maximum **0.173** (`V5_FACTORISATION_MAX_DEV_ALL=0.1732`) is a layer-0
artefact: C4 pins the exit to hexagram 0, so only 7 of the 15 `(d,w)` cells are admissible
(`V5_K0_ADMISSIBLE_DW_CELLS=7,15`), and 0.173 is the product of the marginals at a cell whose joint is
identically zero (`V5_K0_MAX_DEV_CELL_JOINT_AND_PRODUCT=0.0000,0.1732`). All four tokens are printed by
`python3 solve.py --atlas-probe runs/20260906_kc_ladders_n31/atlas_n31.json`. The table also
goes from 154 nonzero cells to 422, and King Wen's overlay now matches **one cell per layer** on
`(kw_d, kw_w)`.
*Why they coincided before (kept because it is still true of the `d`-marginal):* the layer flow is
`N` at every layer (every walk makes exactly one transition per layer — this is an engine-gated
identity), so the conditional and the joint coincide:

```
P(d | layer k) = R[k][d] / flow[k] = R[k][d] / N = share[k][d]
```

Summed over `w`, V5's columns are still exactly V2's upper panel. **What makes V5 a genuinely
distinct figure is the second axis** — which, until 2026-09-23, was PENDING; this paragraph then
told the caption to say the two figures shared their numbers. With the axis built, that instruction
is retired (see *What it may NOT claim* below).

### The pinned definition (was: "The unpinned definition")

TR-12 §2 specifies V5's choice classes as "distance class d ∈ {1,2,3,4,6} × **new-pair category**"
and does not define "new-pair category" anywhere else. It must be pinned by the operator before the
cross-tab is built. The natural candidate — and the only one that is free, exact and safe in the
quotient DP — is the **within-pair Hamming distance of the newly placed pair**,
`w = popcount(entry XOR exit) ∈ {2, 4, 6}`, whose multiset over the 32 pairs is fixed by C1 to
{2:12, 4:12, 6:8} ([SPECIFICATION.md](../documentation/SPECIFICATION.md), machine-checked in
[`lean/TrigramTheorems.lean`](../lean/TrigramTheorems.lean)). `w` is a function of the chosen pair
alone and is invariant under the order-24 canonicalisation group. It needs **no scan-side change at
all**: with `--kc-raw` the scan already persists every nonzero raw kernel cell `m<a>_<b>`
(`solve.c:28001-28010`), where `a` is the raw exit hexagram of the previous pair and `b` the raw
entry hexagram of the new one. Both coordinates are therefore functions of the key alone —
`d = popcount(a ^ b)` and `w = popcount(b ^ partner(b))` — so the cross-tab is a **consumer-side
derivation over a frame that already ships, not a flag and not a re-scan**. ⚠ *Corrected 2026-09-12:
this read "a cheap flag, not a re-build" and named a proposed `--kc-scan … --kc-grammar-cross`.
That flag exists nowhere in solve.c or solve.py, and proposing a scan-side change to a pass paid
exactly once — for something already persisted — is the expensive direction to be wrong in.*
(Contrast [V2](viz_kc_river.md)'s branch split, which the DP state genuinely cannot support.) Other readings — pair orbit, trigram class — are possible and would need their own
G-invariance argument. ~~This doc does **not** pick one; it records the candidate and the reason.~~
**PINNED 2026-09-23 by operator ruling:** the category is `w` as above, and `solve.py`
`atlas_emit_v5` implements that reading and no other (it refuses to emit if the pairing in hand does
not reproduce C1's `{2:12, 4:12, 6:8}`). The *choice* of axis is a ruling; every number computed
under it is measured and gated.

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

With the cross-tab (built 2026-09-23) the cell is `P[k][d][w] = G[k][d][w] / N`, and the heat map's
row axis is the 15 `(d, w)` classes, all drawn, zero cells included. One row is **identically zero
by structure**, not by measurement: `(d=6, w=6)`. `d = 6` makes the new entry the complement of the
previous exit, and `w = 6` makes the new exit the complement of the new entry — i.e. the previous
exit itself, a hexagram already placed.

## Input TSV

`tr12/scan/v5_grammar.tsv` — tidy format, `31 × 15 = 465` data rows at full-31 with the cross-tab
(the committed table; 422 of them nonzero), or `31 × 5 = 155` rows with `w = -1` from an atlas that
carries no kernel:

| Column | Type | Meaning |
|---|---|---|
| `k` | int, 0…30 | ladder layer; fills pair-slot `k + 2` |
| `d` | int ∈ {1,2,3,4,6} | boundary distance class of the transition |
| `w` | int ∈ {2,4,6} or `-1` | within-pair distance of the newly placed pair; `-1` = the atlas carries no `layers[].kernel` (scanned without `--kc-raw`), so the cross-tab could not be derived — reduced form, `TR12_V5=PASS:REDUCED-NO-CROSSTAB` |
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

The battery's own n=9 rehearsal scans with `--kc-raw`, so its n=9 atlas carries `layers[].kernel` and
the consumer writes the full `(d, w)` cross-tab: the committed golden
`scripts/tr12_expected/n9/c_consumer.txt` reads `TR12_V5=PASS`, not the reduced form. Add `--kc-raw`
to the `--kc-scan` line above to get the same. *(Added 2026-09-24.)*

**Full-31 (needs the full-31 f/g ladders; the committed TSV came from the published n=31 atlas, so re-rendering the figure needs neither):**

```bash
solve --kc-scan FDIR GDIR tr12/scan/atlas.json [--kc-ooc] [--kc-cache-mb MB]
#   --kc-tdir is NOT needed for this figure. --kc-raw is NOT needed for the
#   distance-class-only form (by_class ships unconditionally), but IS REQUIRED for the
#   (d, w) cross-tab, which derives from layers[].kernel and is absent without it.
```

**Atlas JSON → TSV** — the atlas consumer. It derives the `(d, w)` cross-tab from
`layers[].kernel` when the atlas carries one; when it does not, the `w = -1` placeholder is emitted
honestly rather than guessed, and the verdict token says which form was written.

```bash
python3 solve.py --atlas-queries runs/20260906_kc_ladders_n31/atlas_n31.json --atlas-out tr12 --atlas-select v5
#   writes tr12/scan/v5_grammar.tsv and TR12_V5= in tr12/VERDICTS.txt
```

**The full-31 atlas is in this repository:** `runs/20260906_kc_ladders_n31/atlas_n31.json`
(5,978,126 B, 31 layers, raw sha256 `9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558`),
and the command above reads it. It re-derives `tr12/scan/v5_grammar.tsv` with no ladder mounted;
`python3 solve.py --atlas-probe runs/20260906_kc_ladders_n31/atlas_n31.json` checks the file first
(`ATLAS_PROBE=PASS`). The output path in the `--kc-scan` line above is where a **rebuild** from the
ladders would write a fresh atlas; the ladders themselves are not distributed.

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
- **The d = 6 rows are a single forced event.** Exactly one d = 6 boundary exists in every valid
  ordering, so those three rows, summed over `w`, *are* its exact positional distribution — the population version of the
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
- ~~**It is not independent evidence from V2** while the `w` axis is PENDING — same numbers,
  different rendering. Say so in the caption.~~ 🔴 **RETIRED 2026-09-23 — the `w` axis is built, and
  the factorisation was measured: 0.0097 on layers 1–30, and 0.173 only at the C4-forced layer 0.**
  Nonzero cells 154 → 422. The figure may be presented as carrying `P(w|k)` in addition to V2's
  `P(d|k)`, **not** as evidence of d–w dependence, and it must carry the orbit caveat — `w` is constant on each of the seven pair-orbits and takes three
  distinct values across them, so a row resolves **3 orbit-classes, never an individual pair**.
- **Row totals are theorems, not measurements.** `Σ_k P[k][d]` is the C1 + C5 forced multiset
  (2, 8, 13, 7, 1), and `Σ_k P[k][·][w]` is C1's within-pair multiset less the pinned first pair
  (12, 12, 7); quoting either from this figure quotes a theorem back at itself.
- **A dim King Wen cell is not a finding by itself.** TR-12 §9 declines per-layer argmin
  "loneliest corridor" trivia: extreme cells exist in any large DP. A distinguishing claim needs a
  pre-registered null, not a heat map.
- **Do not plot the quotient marginals here.** `layers[].marginal_quotient` is a different frame
  with non-identity pair labels; it belongs to neither V5 nor [V1](viz_kc_field.md).

## Verification gates

| Gate | Where |
|---|---|
| per-layer orbit-weighted flow == N | `gates.per_layer_flow_eq_N` in the atlas (the denominator of every plotted value) |
| per-layer class row sum == N | `gates.class_row_sums_eq_N` (2026-09-08) |
| per-layer quotient marginal row sum == N | `gates.quotient_marginal_sums_eq_N` (2026-09-08) — the frame this figure is forbidden to plot, above; the gate is a total, so it is blind to mass moved between slots |
| `Σ_k cls[k][d]` == `b0[d] · N` | `gates.class_column_sums_eq_b0_N` (2026-09-08) — the engine-side form of the reader-side `(2, 8, 13, 7, 1)` identity below, and the only gate that sees a `d1`/`d2` swap inside one layer row |
| branch masses sum == N | `gates.branch_masses_sum_eq_N` |
| n=9 exhaustive brute-force cross-check of the extractor | `solve --kc-scan-selftest` |
| f·g cut identity at every layer | `solve --kc-g-check FDIR GDIR` |
| **cross-tab gate** (landed 2026-09-23) | `Σ_w G[k][d][w] == by_class[d]` at every `(k, d)` and `Σ G == flow` per layer — enforced by `atlas_emit_v5`, which **refuses** to write on a mismatch; plus the n=9 exhaustive brute-force leg in `--atlas-selftest --atlas-walks` (cell-by-cell `(d, w)` recount), **shown able to fail** by `--atlas-fault v5-cross-swap`, which moves mass between two `w` cells inside one `(k, d)` and is invisible to every horizontal gate |
| **reader-side:** `Σ_k Σ_d p_cond[k][d][w]` == (12, 12, 7) for `w` = (2, 4, 6) | `awk -F'\t' 'NR>1{t[$3]+=$5} END{for (w in t) print w, t[w]}' tr12/scan/v5_grammar.tsv` — C1's `{2:12, 4:12, 6:8}` less the C4-pinned first pair (`w = 6`); measured 2026-09-24 on the committed full-31 table: 12, 12, 7 |
| **reader-side:** every column of `p_cond` sums to 1.0 | `awk -F'\t' 'NR>1{s[$1]+=$5} END{for (k in s) print k, s[k]}' tr12/scan/v5_grammar.tsv` |
| **reader-side:** `Σ_k p_cond[k][d]` == (2, 8, 13, 7, 1) | `awk -F'\t' 'NR>1{t[$2]+=$5} END{for (d in t) print d, t[d]}' tr12/scan/v5_grammar.tsv` |

Both reader-side identities were exercised against the committed n=9 reference atlas (per-layer sums
1.0; class totals {1:2, 2:5, 4:2}, the reduced-world analogue of {1:2, 2:8, 3:13, 4:7, 6:1}) before
this doc was written.

**Seven advertised keys are not twelve gate families.** `kc_h_scan_tail` runs twelve; the other
five reach the JSON only through `fails`, and three of those five are guarded by a direct t
recursion the tail attempts only when `N <= 2^27`, so they do not run at n=31 at all. Every
advertised field collapses to `"see fails"` if *any* gate failed, named or not — coarse, but never
a false positive. Read `fails` first. There is deliberately **no** vertical `quotient_marginal`
gate: `kc_flookup` re-canonicalises with `f1_canon` on every lookup, so `q` indexes *this* layer's
canonical mask and is not the same slot at `k+1`; the layer-summed quotient marginal has no closed
form and must not be asserted. Full accounting in
[SOLVE_C_CLI.md](../documentation/SOLVE_C_CLI.md).

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
