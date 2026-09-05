# Visualization — V1, the positional-marginal field (where every pair can sit, exactly)

**The 32×31 heat matrix of exact placement probabilities.** ⚠ 32 rows **wide**, but only
**seven distinct** — see *"The field has SEVEN distinct rows"* below before reading structure into it.
 For every King Wen pair *j* and every
pair-slot in the ordering, the field gives the **exact fraction of the whole compiled superspace**
that places pair *j* in that slot — not a sample, not a projection: a population marginal computed
from every member at once via the compiled f·g ladders. King Wen's own 31 placements are overlaid.

← Back to [README.md](README.md) (index) · V-family: **V1** · [V2 river](viz_kc_river.md) ·
[V3 spectrum](viz_kc_spectrum.md) · [V4 shells](viz_kc_shells.md) · [V5 grammar](viz_kc_grammar.md) ·
See also [viz_pca.md](viz_pca.md) (the enumerated-slice projections this figure contrasts with)

## Status (2026-08-22)

| Piece | Instrument | State |
|---|---|---|
| Layer-by-layer RAW positional marginals | `solve --kc-scan FDIR GDIR OUT.json --kc-raw` | **EXISTS** (source + binary, verified) |
| Internal gates (per-layer flow = N, raw row sums = N) | inside `--kc-scan` | **EXISTS**, printed as `gates` in the atlas |
| n=9 brute-force cross-check | `solve --kc-scan-selftest` | **EXISTS** (`PASS (0 failures)`) |
| Full-31 f and g ladders | Stage F / Stage G | **NOT YET BUILT** — no full-31 atlas exists |
| Atlas JSON → figure TSV | `python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR` | **EXISTS** (n=9 brute-force gated: `--atlas-selftest`, `ATLAS_CONSUMER=PASS`) |

The full-31 figure cannot be rendered until Stage F **and** Stage G have landed and a
`--kc-scan … --kc-raw` pass has run. Everything below is exercised today at n=9 against the
committed reference atlas.

## The quantity plotted

Let **SUPER** = C1 ∩ C2 ∩ C4 ∩ C5 (the compiled walk superspace; C3 is **not** applied) and let
`N = |SUPER|` be its exact walk count — the `N_total` field of the atlas, equivalently
`solve --kc-count FDIR`.

Index the ordering by its **32 pair-slots** (slot 1 … slot 32). C4 pins pair 0 (King Wen hexagrams
1 and 2) to slot 1, so a walk consists of **31 free placements**, indexed by the ladder layer
`k = 0 … 30`; layer *k* is the transition from depth *k* to depth *k+1* and fills **pair-slot k+2**.

For a global pair index `j ∈ {0,…,31}` (pair *j* = the King Wen pair `(KW[2j], KW[2j+1])`, i.e.
hexagrams 2j+1 and 2j+2 in the traditional 1-based numbering) the plotted cell is

```
M[k][j] = # { w ∈ SUPER : w places pair j at pair-slot k+2 }          (exact, 192-bit integer)
P[k][j] = M[k][j] / N                                                 (the plotted value, in [0,1])
```

`--kc-scan` computes `M[k][j]` as the f·g join over the compiled layers,

```
M[k][j] = Σ_{states s at layer k} Σ_{admissible choices c at s placing raw pair j}  f(s) · g(s∘c)
```

G-expanded to raw pair identities: each canonical mask is expanded over its orbit under the
order-24 canonicalisation group, deduplicated by distinct raw transition image, and the mass
credited to the raw pair the orbit element maps the quotient slot to. `f(s)` = number of valid
prefixes reaching state *s*; `g(s)` = number of completions from *s*; their product is the exact
number of full walks through the edge.

**The matrix is 32 rows × 31 columns.** Row `j = 0` is **identically zero** — pair 0 is placed at
slot 1 by C4, before layer 0 exists. It is kept in the figure so the row index reads as the pair
index, and its zero row is itself a reader-side gate.

**`P` is doubly stochastic.** Every column sums to 1 (each walk makes exactly one placement per
layer) and every non-pinned row sums to 1 (each walk places each pair exactly once). Both are
checkable from the TSV; the per-column identity is additionally gated inside the engine.

### 🔴 The field has SEVEN distinct rows, not 32 — read the shape accordingly

A 32×31 heat map invites the reading that there are 32 independently-behaving pairs. There are not.
**SUPER is G-closed**, so two pairs in the same orbit are exchanged by a group element that maps
solutions to solutions — their positional marginals are therefore **equal at every slot, exactly,
not approximately**. The engine prints the decomposition itself in its own group self-check:

```
pair-orbits of the 31 free pairs:  3:[3,7,11]  3:[4,6,21]  3:[13,14,30]  4:[5,8,26,31]
                                   6:[1,9,17,19,22,25]  6:[2,12,16,18,24,28]  6:[10,15,20,23,27,29]
```

**Seven orbits, sizes {3,3,3,4,6,6,6}.** So the field's 992 cells carry **7 rows** of population
information, replicated into 32. Measured on real atlases: **n=9 → 3 distinct rows** (sizes
`[3,3,3]`), **n=13 → 3** (`[3,4,6]`), each a union of whole orbits.

⚠ **Two consequences for how this figure is read and captioned.**
1. **Bands of identical rows are forced by symmetry, not discovered.** A viewer who reads
   clustering into them is reading the group, not the data.
2. **Any "pair *j* behaves unusually" claim is really a claim about *j*'s ORBIT** — and applies
   identically to every other member of it. There are at most 7 such statements available, not 32.

Gated, not merely asserted: `solve.py:atlas_orbit_columns()` fails the atlas if the number of
distinct rows is not a union of whole published orbit sizes. It catches what the internal
sum-to-N gate cannot — a **sum-preserving** move of one unit between two pairs of the same orbit
leaves every layer summing to N exactly, and the orbit check still FAILs.

🔴 **Two corrections to that sentence, 2026-09-04** (Codex review MQ1 §2b):

1. **It did not run at full-31 until now.** Its only call site was inside `--atlas-selftest`,
   which refuses `n > 13` ("brute force is a reduced-n gate") and returns *before* reaching it,
   and `--atlas-queries` never called it. So the guard this page cites ran at every size except
   the one where the field is published. It is now emitted by `--atlas-queries` at n = 31 as
   `TR12_A5_ORBIT_COLUMNS` (`--atlas-select a5`).
2. **It checks group SIZES, not membership.** The multiset of equal-column group sizes must be a
   union of whole published orbit sizes; *which* pairs sit in which group is not examined. A
   swap of two pairs drawn from two **different orbits of the same size** leaves that multiset
   unchanged and passes. So this is a guard against orbit-equality being *broken*, not against
   pair identities being *permuted* among equal-sized orbits. Checking membership needs the
   orbit partition itself, which lives in `solve.c` and is not re-derived on the consumer side;
   it is owed.

### The King Wen overlay — and the labelling artifact it hides

King Wen's own placements are marked on the field. **They lie on the main diagonal, and that is a
labelling artifact, not a finding**: the global pair index is *defined* by King Wen's own pairing
order, so King Wen places pair `k+1` at slot `k+2` for every *k*. The diagonal shape carries no
information. What carries information is the **value of the field on that diagonal** — how much of
the superspace agrees with King Wen at each slot — read against the rest of that column.

## Input TSV

`tr12/scan/v1_field.tsv` — tidy (long) format, `31 × 32 = 992` data rows at full-31, tab-separated:

| Column | Type | Meaning |
|---|---|---|
| `k` | int, 0…30 | ladder layer (the atlas's `layers[].k`) |
| `slot` | int, 2…32 | pair-slot filled at this layer = `k + 2` |
| `pair` | int, 0…31 | global pair index; pair *j* = `(KW[2j], KW[2j+1])` |
| `mass` | decimal **string** | `M[k][j]`, exact 192-bit integer — parse with Python `int()`, never `float()` |
| `p` | float | `M[k][j] / N`, the plotted value (display precision only) |
| `kw` | 0/1 | 1 iff this cell is King Wen's own placement (`pair == k + 1` at full-31) |

Long format is deliberate: the masses are 192-bit decimal strings and do not survive a dense
numeric matrix. The plotting step pivots `p` into a 32×31 array and never re-derives anything.

## Generation

**Rehearsal at n=9 (sub-second, runs today, $0):**

```bash
# run from the repository root (solve.c and solve.py live there)
B=/tmp/kcbuild-$$; mkdir -p $B
gcc -O2 -pthread -fopenmp -o $B/solve solve.c -lm -lz
A=$B/n9; mkdir -p $A/f $A/g
$B/solve --kc-build   $A/f --f1-pairs 9
$B/solve --kc-g-build $A/g --f1-pairs 9
$B/solve --kc-scan    $A/f $A/g $A/atlas.json         # RAW marginals are automatic at n ≤ 13
$B/solve --kc-scan-selftest                           # expect: PASS (0 failures)
```

**Full-31 (PENDING the ladders):**

```bash
solve --kc-scan FDIR GDIR tr12/scan/atlas.json --kc-raw --kc-tdir TDIR [--kc-ooc] [--kc-cache-mb MB]
```

`--kc-raw` is **required at full-31** — RAW-frame marginals are emitted automatically only at
n ≤ 13, and at full-31 the G-expansion is the priced part of the pass. Without it the atlas
carries only `marginal_quotient`, which **must not** be plotted as this field (see Limitations).

**Atlas JSON → TSV** — the atlas consumer (`solve.py`, the single-file rule's Python home).
Pure re-shaping; the only arithmetic is the division by `N` that the figure plots, and it is done
on exact 192-bit integers, never on floats:

```bash
python3 solve.py --atlas-queries tr12/scan/atlas.json --atlas-out tr12 --atlas-select v1
#   writes tr12/scan/v1_field.tsv and the TR12_V1= line in tr12/VERDICTS.txt
```

Gated at n=9 against the committed reference atlas by
`python3 solve.py --atlas-selftest ATLAS.json --atlas-walks WALKS.txt`, which re-derives every
cell of this TSV from the explicit 26,112-walk enumeration and prints `ATLAS_CONSUMER=PASS`.


**TSV → figure:** `viz/report_figures.py` (`fig_tr12_kc_field`), a `matplotlib` `imshow` of the
pivoted `p` column with the `kw == 1` cells marked. Per the standing rule the plotting step reads
the TSV and does nothing else — **no analysis logic in `viz/`**.

Outputs follow the TR pattern: `runs/<run-id>/viz/viz_kc_field.{png,svg}`, mirrored to
`reports/figures/fig_tr12_kc_field.{png,svg}`; the TSV is committed alongside as evidence.

## How to read it

- **A bright cell** = a large share of the entire superspace puts that pair in that slot.
- **Read down a column** (fixed slot): the distribution over which pair occupies that slot. A flat
  column means the slot is nearly unconstrained; a peaked column means the constraint system
  concentrates that slot on a few pairs.
- **Read along a row** (fixed pair): where in the ordering that pair can live. Rows are also
  probability distributions (they sum to 1), so a tight row means a pair is positionally pinned by
  C1/C2/C5 alone.
- **Read the King Wen diagonal against its own column**: is King Wen's choice at slot *k+2* a
  high-mass or a low-mass cell of that column? This is the only comparison the figure supports —
  and it is a *marginal* one, position by position, not a joint statement about the ordering.
- **Left-to-right structure**: earlier slots are more constrained (fewer pairs remain admissible
  under the C5 boundary budget); the field should broaden and then re-narrow as the budget is
  exhausted near the end.

## What this figure is allowed to claim

1. **Exact positional marginals over the whole superspace.** Every number is an exact integer
   divided by an exact integer — no sampling, no enumeration slice, no estimator. This is precisely
   what the [PCA figures](viz_pca.md) *cannot* do: those project an enumerated budget-limited slice
   (the d3 560T canonical), this one is the population.
2. **Per-slot and per-pair positional freedom** under C1 ∩ C2 ∩ C4 ∩ C5, stated as exact
   probabilities.
3. **Where King Wen's individual placements sit within their own columns**, marginally.

## What it may NOT claim

- **Nothing about C3, and nothing about C15.** The compiled space is C1 ∩ C2 ∩ C4 ∩ C5. `--kc-scan`
  has no `--kc-c3-max` axis. Every caption must carry the space label
  `C1C2C4C5-SUPERSPACE`; "the space of valid King Wen orderings" is the wrong label for this figure.
- **No joint statement.** Marginals do not multiply. A King Wen diagonal sitting in high-mass cells
  at every slot says nothing about how much mass the *combination* has — that quantity is
  `1/N`, and its step-by-step decomposition is [V4](viz_kc_shells.md), not this figure.
- **The diagonal is not evidence.** Pair indices are King Wen's own; a diagonal overlay is forced by
  the labelling. Do not describe it as structure.
- **No claim about the quotient marginals.** `marginal_quotient` in the atlas is orbit-weighted in
  the canonical frame; its `q*` labels are **not** pair identities and are meaningless as a
  pair × slot field. The atlas's own `frames` field says so; honour it.
- **No "King Wen is unusual/typical" verdict from this figure alone.** Every column sums to 1 over
  32 pairs, so a "typical" cell sits near 1/31 by construction; distinguishing claims need a
  pre-registered null, not a heat map.

## Verification gates

Printed by the engine into `gates` in the atlas, and re-checkable from the TSV:

| Gate | Where |
|---|---|
| per-layer orbit-weighted flow == N (all layers) | `gates.per_layer_flow_eq_N` |
| raw marginal row sums == N (all layers) | `gates.raw_marginal_sums_eq_N` (`"not-emitted"` without `--kc-raw`) |
| branch masses sum == N | `gates.branch_masses_sum_eq_N` |
| n=9 exhaustive brute-force cross-check of the whole extractor | `solve --kc-scan-selftest` |
| **reader-side:** every column of `p` sums to 1.0 | `awk -F'\t' 'NR>1{s[$1]+=$5} END{for (k in s) print k, s[k]}' tr12/scan/v1_field.tsv` |
| **reader-side:** every non-pinned row of `p` sums to 1.0 | same with `$3` as the key |
| **reader-side:** row `pair == 0` is identically zero | `awk -F'\t' '$3==0 && $4!="0"' tr12/scan/v1_field.tsv` (must print nothing) |

A figure whose TSV fails any of these is not publishable — the gate failure, not the picture, is
the result.

## Where the files live

- **This doc:** `viz/viz_kc_field.md`
- **Generator (TSV → figure):** `viz/report_figures.py`
- **Evidence TSV:** `tr12/scan/v1_field.tsv` (committed with the figure)
- **Atlas JSON:** `tr12/scan/atlas.json`, schema `roae-kc-scan-atlas` v1
- **Figures:** `runs/<run-id>/viz/viz_kc_field.{png,svg}` → mirrored to
  `reports/figures/fig_tr12_kc_field.{png,svg}`

Figures are never inlined into `viz/` itself — see [README.md](README.md).

## Related

- [SPECIFICATION.md](../documentation/SPECIFICATION.md) — C1–C5, the pair construction, and the
  forced within-pair / between-pair distance multisets.
- [BRANCHES_EXPLAINED.md](../documentation/BRANCHES_EXPLAINED.md) — first-level branches (the
  56 admissible first placements that make up layer 0 of this field).
- [SOLVE_C_CLI.md](../documentation/SOLVE_C_CLI.md) — the `--kc-*` family; full semantics for
  `--kc-scan` live in the KC/KC-H module headers in `solve.c`, per the `--kc-*` convention.

---

*Specification per TR-12 §2 (V1). Nothing here is claimed novel: this is a marginal-probability heat
map over a counting DP — standard knowledge-compilation practice (cf. Darwiche & Marquis's query
taxonomy) rendered with `matplotlib`. The contribution is exactness and the space labelling.
Developed with AI assistance (Claude, Anthropic); corrections invited.*
