# Visualization — V3, the rank spectrum (does the index order the space by anything?)

**A systematic walk down the whole superspace index.** Take the ranks
`r = 0, ⌊N/K⌋, 2⌊N/K⌋, …` for a grid of `K` points, unrank each one to the walk it names, evaluate
a fixed battery of structural observables on it, and plot each observable against `r`. The question
is blunt: **is the rank index a structural coordinate, or is it arbitrary?** A flat, noisy spectrum
is the informative answer, and it is the one this figure most likely gives.

← Back to [README.md](README.md) (index) · V-family: [V1 field](viz_kc_field.md) ·
[V2 river](viz_kc_river.md) · **V3** · [V4 shells](viz_kc_shells.md) ·
[V5 grammar](viz_kc_grammar.md) · See also [viz_pca.md](viz_pca.md)


### 🔴 A flat spectrum may mean the OBSERVABLE is constant, not that the index is arbitrary

V3's stated question is *"is the rank index a structural coordinate, or is it arbitrary?"*, answered
by whether the spectrum is flat. **That inference is only valid for observables that actually vary
on the space.** Several of the battery's do not:

Measured over the complete n=9 superspace, all **26,112** walks:

| observable | distinct values over the WHOLE space |
|---|---|
| `linechanges` | **1** — constant, forced by the C5 budget |
| `yangcount` | **4** (multiplicities 8448 / 8448 / 6528 / 2688) |

So a flat `linechanges` spectrum says **nothing whatever about the rank index** — the observable is
the same number for every member of the space, and would be flat under *any* ordering, including a
perfectly structural one. Reporting that as *"the index is arbitrary"* is a **false negative dressed
as a finding**. The `dclass:*` observables are C5-forced in the same way.

⚠ **Two rules for reading this figure.**
1. **Establish each observable's range on the space FIRST.** An observable with one value carries no
   spectrum; drop it or label it CONSTANT rather than plotting a flat line. **What exists for this:**
   `solve --kc-extremal FUNC DIR max|min` prints `constant_on_space=yes|no`, but only for its registry
   (`solve --kc-extremal list`: `dclass:1…6`, `linechanges`, `graycode`, `yangcount`, `entryyang`,
   and the `posyang0` control), and only in memory (n ≤ 22), so not at full-31. **None of the nine
   V3 battery observables is registered, and none has a range producer.** For them, the Range
   column below gives a documented bound, not a computed extreme. Two of the nine are constant on the
   space by construction and must be labelled CONSTANT. `max_transition_hamming` is 6 because C5
   allots exactly one d = 6 boundary. `mean_transition_hamming` is 211/63 ≈ 3.3492064, because pair
   identity fixes every within-pair distance and C5 fixes the between-pair multiset. Both hold on all
   1,000 rows of `tr12/v3_spectrum.tsv`.
   ⚠ *Corrected 2026-09-25 (Q-698, V3A-145#4): this rule read "(`--kc-extremal FUNC DIR max` and
   `min`; `constant_on_space=yes` is printed for exactly the forced ones)", a step no command could
   perform for this figure. Executed at n=9: `--kc-extremal fft_peak_amplitude|c3_total|edit_dist_kw|mean_transition_hamming DIR max`
   each exit 2 (unknown functional), and `--kc-extremal linechanges DIR max` prints
   `constant_on_space=yes`.*
2. **Values are orbit-replicated.** G-invariant observables are constant on a whole orbit, so a
   K-point rank grid samples far fewer independent values than K. The step structure that results
   is symmetry, not signal — the same caveat V1 carries.


## Status (2026-08-22; updated 2026-09-24)

| Piece | Instrument | State |
|---|---|---|
| Unrank at an arbitrary rank, REL order | `solve --kc-unrank DIR RANK` (f ladder only) | **EXISTS** |
| Unrank at an arbitrary rank, **O3 citable order** | `solve --kc-o3-unrank FDIR GDIR RANK` (both ladders) | **EXISTS** |
| The observable battery over a record file | `python3 solve.py --compute-stats SOLUTIONS_BIN OUT_DIR` | **EXISTS** |
| Grid emitter: unranked walks → a `solutions.bin` the battery can read | — | **PENDING** — proposed `--kc-unrank-grid` (below); **no longer on the critical path** |
| The REL rank grid, K = 1000 | the `--kc-unrank` K-loop, row `a1_v3` of `scripts/tr12_repro.sh` → `tr12/v3_rel_grid.tsv` | **EXISTS** (31.4 min measured) |
| The join: grid → battery → spectrum TSV | `python3 solve.py --v3-spectrum GRID_TSV OUT_TSV [--v3-spectrum-order REL\|O3]` | **EXISTS (2026-09-23)** → committed `tr12/v3_spectrum.tsv`, `V3_SPECTRUM=PASS` |
| The figure | `viz/report_figures.py` `fig_tr12_kc_spectrum` | **RENDERED** → `reports/figures/fig_tr12_kc_spectrum.{png,svg}`, embedded in TR-12 §2 |
| Full-31 f / g ladders | Stage F / Stage G | **BUILT** (the grid above was unranked from them) |
| Battery driver runs the join | `scripts/tr12_repro.sh` | ⚠ **NOT WIRED** — no row invokes `--v3-spectrum`, so inside the battery `TR12_V3_FIG` stays `PENDING:viz-v3-spectrum` even though the committed figure exists |

🔴 **RESOLVED 2026-09-23 — and the "missing instrument" was forty lines, not a flag.** This
paragraph read *"This figure is the one V-family member with a real missing instrument… nothing
joins them"*, and that sentence outlived its truth: it described a gap between two components that
both already existed. The join now exists as `solve.py --v3-spectrum GRID_TSV OUT_TSV`, it reads the
grid the `--kc-unrank` K-loop already produced (`tr12/v3_rel_grid.tsv`), it evaluates the frozen
battery per walk, and the figure renders from its output. **No ladder, no VM, no new figure code.**
⚠ The proposed `--kc-unrank-grid` below is still UNBUILT and was never the blocker — the row below
stands as written. What follows is kept for the record of what was believed at the time:
*Both unrankers exist and
the observable battery exists, but nothing joins them: `--kc-o3-unrank` prints a walk as an
`entry,exit,…` line, while `solve.py --compute-stats` consumes a 32-byte-record `solutions.bin`
([SOLUTIONS_FORMAT.md](../documentation/SOLUTIONS_FORMAT.md)). The walk → record adapter (prepend
the C4-pinned pair, pack `byte i = (pair_index << 2) | (orient << 1)`, write the `ROAE` header)
belongs in `solve.c` next to the unranker that already owns those conventions — **not** in `viz/`,
where the standing rule is TSV-to-figure only.*

⚠ **Where that superseded text was right, and where it was wrong.** It was right that the adapter
does not belong in `viz/`, and the shipped join honours that: `--v3-spectrum` lives in `solve.py`,
beside the frozen battery, and `viz/` still does no analysis. It was wrong that the gap was an
*instrument*. The walk → record adapter it specifies was the hard reading of the problem; the join
that shipped packs each walk through the battery's own decoder and verifies every record back out
again, which is the same work described without needing a new flag to exist first.

### PENDING flag (proposed name — TR-12 §8 should pin it before it is built)

```
solve --kc-unrank-grid FDIR [GDIR] K OUT.bin [--kc-order REL|O3] [--kc-ooc] [--kc-cache-mb MB]
```

Emits the `K` walks at ranks `r_i = i · ⌊N/K⌋`, `i = 0 … K−1`, as a valid `solutions.bin`
(v1 header, 32-byte records) plus a sidecar `OUT.ranks.tsv` giving `i`, `rank` and the walk, so the
join back to the rank axis is by row index and never by re-ranking. `--kc-order O3` requires GDIR;
`--kc-order REL` (the default) needs only the f ladder. Like every other `--kc-*` subcommand it is
argv-dispatched, sha-neutral, never inside `--selftest`, and must ship with an **n=9 exhaustive
brute-force gate** (at n=9 the whole space is 26,112 walks, so the grid can be checked against the
independently sorted brute enumeration for every `K`, and `--kc-order O3` cross-checked against
`--kc-o3-rank` round-tripping every emitted walk) that has been **shown able to fail** before any
full-31 use.

~~Until it lands, V3 has no TSV and therefore no figure.~~ *Withdrawn 2026-09-24: V3 has had a TSV
and a figure since 2026-09-23 without this flag — see the status table.* The shell-loop alternative
(`for i in $(seq 0 K); do solve --kc-o3-unrank …; done`) produces the walks but still leaves the
adapter and the battery unjoined, and at `K = 10³–10⁴` pays process startup and ladder open per
point.

## The quantity plotted

Let **SUPER** = C1 ∩ C2 ∩ C4 ∩ C5 with `N = |SUPER|` exact, and fix a total order on SUPER:

- **O3** — the ratified `compare_solutions` record comparator lifted to walks (pair-vector lex
  primary, orientation-vector lex tiebreak). This is the **citable** order. `--kc-o3-unrank` needs
  both the f and g ladders.
- **REL** — reverse-exit lexicographic, the compiler's native descent order
  (`(exit_n, exit_{n-1}, …, exit_1)`). `--kc-unrank` implements it from the f ladder alone. It is
  **not** O3 and must never be quoted as if it were; every `#provenance` trailer says which.

For a grid size `K` and `i = 0 … K−1`:

```
r_i = i · ⌊N/K⌋                              (exact 192-bit integers)
w_i = unrank_<order>(r_i)                    (the walk at that rank)
y_i = F(w_i)                                 for each observable F in the battery
```

and the figure plots `y_i` against `r_i / N ∈ [0,1)` — one panel (or one series) per observable.

### The observable battery

The battery is the existing, frozen `solve.py --compute-stats` set — **`_P2_INT_COLS` /
`_P2_FLOAT_COLS` must not be widened** (see `solve.py`):

| Observable | Range | King Wen |
|---|---|---|
| `edit_dist_kw` | 0…32 | 0 |
| `c3_total` | ⚠ **see the note below — the old `424…776` was wrong in both directions** | 776 |
| `c6_c7_count` | 0…2 | 2 |
| `max_transition_hamming` | 1…6 | 6 |
| `fft_dominant_freq` | 1…31 | 16 |
| `shift_conformant_count` | 0…17 | 17 |
| `first_position_deviation` | 1…33 | 33 — ⚠ **O3-axis panel is a THEOREM, see below** |
| `mean_transition_hamming` | 2.0…4.0 | 3.3492064 |
| `fft_peak_amplitude` | ⚠ **no tight range is known — proven envelope 75.05…835.99, see the note below** (was `0.0…500.0`) | 374.77 |

Note `c3_total` is an *observable* here, not a filter: the compiled space is C1 ∩ C2 ∩ C4 ∩ C5, so
grid points may and will carry C3 values above King Wen's 776. That is a property of the space, not
a defect.

🔴 **`first_position_deviation` must not be plotted as an observable on the O3 axis (QSET-2 finding
4, 2026-09-06).** Its trend there is **forced by the order, not measured**: O3 is lexicographic on the
pair vector with King Wen's numbering as the identity, and first-deviation-from-identity is
**monotone non-increasing** under lex order. The argument is two lines — at a permutation's first
departure from the identity, the chosen label must exceed the identity label, because every smaller
label is already used — and it was brute-forced at n = 5, 6 and 7, monotone in every case. So the
panel cannot come out flat, and a downward trend in it is a property of the axis rather than a fact
about the population. **Hold it out of the O3 axis, or label it a theorem.** This file already warned
that `edit_dist_kw` is "nearly tautological" on that axis; `fpd` is the stronger case and the warning
never reached it, even though `documentation/DISTRIBUTIONAL_ANALYSIS.md` had called `fpd` tautological
in a different context since 2026-07-26. **The shipped REL grid is unaffected** — this is an O3-axis
defect only.

🔴 **The `424…776` range this table carried until 2026-09-05 contradicted that note, and was wrong at
both ends (QSET finding 8).** A reader is told to check every observable against its range, and this
range would have flagged correct data. Upward: the note itself says values above 776 are expected,
so 776 cannot be the ceiling. Downward: 424 is the minimum seen in one *enumerated slice*, not a
bound on SUPER — the published structural floor is **C3 = 112** at `G = 12`
([`reports/certificates/c3_positional_witnesses.txt`](../reports/certificates/c3_positional_witnesses.txt)),
and `solve.py`'s own T5 SUPER sample spans **352…1648**. **No hard range is asserted in its place:**
the true supremum over SUPER is not published, and substituting a second guessed interval would
repeat the defect. Treat `c3_total` as unbounded-above for acceptance purposes and check it against
`C3 = 16 + 8·G` instead, which is exact and kernel-checked.

⚠ **Corrected 2026-09-25 (Q-698, V3A-145#1): `fft_peak_amplitude` read `0.0…500.0`, which is not
a bound.** `500.0` is the `--marginals` histogram limit in `solve.py`'s `_P2_FLOAT_COLS`, which was
set for an enumerated slice. It does not bound SUPER, and it rejects a valid walk. **Executed
counterexample:** take the `G = 17` witness in
[`reports/certificates/c3_positional_witnesses.txt`](../reports/certificates/c3_positional_witnesses.txt)
(the `SEQ=` line after `G=17`) and move bit `i` of every hexagram to bit `P[i]`, with
`P = (4,2,0,5,3,1)` and bit 0 the least significant. The image is a member of C1 ∩ C2 ∩ C4 ∩ C5: it opens `(63, 0)`,
every slot pair is a King Wen pair, it has no distance-5 or distance-0 transition, and its
difference wave is exactly `{1:2, 2:20, 3:13, 4:19, 6:9}`. Under the battery's own formula (zero-mean,
`max |F[1:32]|`, float32) it scores **517.53, at frequency 13**. The witness itself scores 312.84.
On the committed full-31 REL grid `tr12/v3_spectrum.tsv`, the observed span is **202.73…448.70**
over 1,000 points. **The proven envelope, for every permutation of 0…63:** Parseval gives
Σ_{k=1..63} |F_k|² = 64 · 21,840 = 1,397,760. Since |F_k| = |F_{64−k}|, the maximum over k = 1…31 is at
most √698,880 = **835.99**. Since |F_32| ≤ 1024, it is at least √((1,397,760 − 1024²)/62) = **75.05**.
The true extremes over SUPER are not published, and this envelope is not claimed to be tight.
`--v3-spectrum` now accepts `fft_peak_amplitude` against this envelope (`_V3_FLOAT_ACCEPT` in
`solve.py`, rounded outward to 75.0…836.0), not against 500.0. `--marginals` keeps its histogram
limit, which applies to its own enumerated scope.

## Input TSV

`<artifact-root>/spectrum/v3_spectrum.tsv` — one row per grid point, `K` data rows. **The committed
full-31 REL table is `tr12/v3_spectrum.tsv`** (K = 1000, no `spectrum/` level;
`report_figures.tr12_figures` falls back to that flat path when the spec path is absent):

| Column | Type | Meaning |
|---|---|---|
| `i` | int, 0…K−1 | grid index |
| `rank` | decimal **string** | `r_i = i · ⌊N/K⌋`, exact 192-bit — parse with `int()` |
| `x` | float | `r_i / N ∈ [0,1)`, the plotted abscissa |
| `order` | `O3` \| `REL` | which total order the rank refers to — **mandatory, never dropped** |
| `walk` | string | `entry,exit,…` (62 integers at full-31), the unranked walk |
| `edit_dist_kw` … `fft_peak_amplitude` | int / float | one column per battery observable, in the table order above |
| `kw_<observable>` | int / float, **optional** | King Wen's value for that observable, constant down the grid — drawn as the horizontal reference line, never plotted as a panel of its own. **Deliberately absent for the four KW-anchored observables** (below) |

One TSV per order; a spectrum mixing O3 and REL rows in one panel is a labelling error.

The `kw_*` columns are optional **and they are the only way a reference line gets drawn**.
`viz/` holds no analysis, so the renderer will not look King Wen's value up: a panel whose
`kw_<observable>` column is absent is drawn with no reference line, and the figure's subtitle says
how many panels carry one. A `kw_*` column that is *not* constant down the grid is refused as a
labelling error rather than averaged. The King Wen column of the observable table above is the
source those values are emitted from.

### 🔴 Four panels carry no King Wen line, on purpose (KW-anchored observables)

`solve.py --v3-spectrum` writes **no** `kw_*` column for `edit_dist_kw`, `first_position_deviation`,
`shift_conformant_count` and `c6_c7_count`. Each measures similarity **to King Wen** (`kw_exp` is
literally `arange(32)`), so King Wen necessarily takes the extreme value (0, 33, 17 and 2 in the
table above), and a reference line would sit outside the cloud and read as a discovery.
[DISTRIBUTIONAL_ANALYSIS.md](../documentation/DISTRIBUTIONAL_ANALYSIS.md)'s adversarial circularity
audit (2026-07-26) names exactly these four and withdrew a published joint-KDE headline over the same
inference. The decision is made in the **data**, not in `viz/`; the figure's subtitle names the
unlined panels so a missing line cannot be read as a missing value. `c3_total` keeps its line — that
audit's objection to it was the C3 ≤ 776 population filter, which this unfiltered SUPER grid does not
apply.

### Two observables are dropped as CONSTANT, and both constants are theorems

On the committed grid `max_transition_hamming = 6` and `mean_transition_hamming = 3.3492064` at
every one of the 1000 points, so the renderer drops both (rule 1) and names them in the subtitle.
Neither is a finding about the index: C5 forces exactly one `d = 6` boundary, so the maximum is 6
for every member of SUPER; and the 63 transitions are the 32 within-pair steps (C1:
`12·2 + 12·4 + 8·6 = 120`) plus the 31 boundaries (C5: `2·1 + 8·2 + 13·3 + 7·4 + 1·6 = 91`), so the
mean is `211/63 = 3.349206…` for every member. (Arithmetic checked 2026-09-24; it is the same forced
multiset V2 and V5 quote.)

## Generation

**Full-31, as SHIPPED (2026-09-23, REL order, no VM):**

```bash
# 1. the grid -- the --kc-unrank K-loop, row a1_v3 of scripts/tr12_repro.sh (needs the f ladder)
#    -> tr12/v3_rel_grid.tsv   (columns i, r, walk; K = 1000)
# 2+3. the battery and the join, in one instrument
python3 solve.py --v3-spectrum tr12/v3_rel_grid.tsv tr12/v3_spectrum.tsv    # V3_SPECTRUM=PASS
# 4. the figure (from reports/figures/, where save() writes)
python3 -c "import sys; sys.path.insert(0,'../../viz'); import report_figures as R; R.fig_tr12_kc_spectrum('../../tr12/v3_spectrum.tsv')"
```

**The originally specified route (PENDING `--kc-unrank-grid`; needed for an O3-order spectrum at
scale, not for the shipped REL figure):**

```bash
# 1. the grid  (PENDING --kc-unrank-grid)
solve --kc-unrank-grid FDIR GDIR 10000 tr12/spectrum/grid_o3.bin --kc-order O3

# 2. the battery (EXISTS)
python3 solve.py --compute-stats tr12/spectrum/grid_o3.bin tr12/spectrum/stats_o3/

# 3. join by row index into the evidence TSV (pure paste; PENDING the emitter's sidecar)
#    tr12/spectrum/grid_o3.ranks.tsv  ⋈  tr12/spectrum/stats_o3/*  →  v3_spectrum.tsv
```

**Rehearsal at n=9 (once `--kc-unrank-grid` exists; sub-second, $0):** build the n=9 f and g
ladders as in [viz_kc_field.md](viz_kc_field.md), then emit a grid over the 26,112-walk space and
check every point against `--kc-o3-rank` round-tripping. The n=9 world has no King Wen and no
64-hexagram record, so the *battery* half of the pipeline is exercised at full-31 only; the n=9 gate
covers the grid emitter's rank arithmetic and walk correctness, which is where the risk is.

**TSV → figure:** `viz/report_figures.py` (`fig_tr12_kc_spectrum`) — small-multiples line/scatter of
each observable against `x`, King Wen's value drawn as a horizontal reference line **for each
observable whose `kw_<observable>` column the TSV supplies** (see the schema below). Where that
column is absent the panel has no reference line: the renderer will not invent one, because there is
**no analysis logic in `viz/`**. TSV in, figure out.

## How to read it

- **A flat, high-variance band** = the rank index carries no structural information for that
  observable. This is the expected outcome for most of the battery and is a legitimate, reportable
  negative. ⚠ *(noted 2026-09-24: "flat" is only informative for an observable that varies. On the
  rendered n=31 REL grid, `c6_c7_count` is 0 at 995 of 1000 points and `first_position_deviation`
  takes only 2 or 3, so their flat panels say nothing about the index (rule 1). The other five are
  broad bands, and on all seven |r(x)| < 0.073 (`tr12/v3_spectrum.tsv`).)*
- **A monotone drift** = the order's leading coordinate correlates with that observable. For O3
  (pair-vector lex) a drift in `edit_dist_kw` would be nearly tautological — the order sorts on the
  pair vector, and King Wen's pair vector is the identity — so read that panel with suspicion.
- **Step structure** = the order's leading positions partition the index into blocks; block
  boundaries in `x` correspond to changes in the earliest pair-slots. ⚠ *(noted 2026-09-24: in the
  rendered REL grid the blocks are 32 contiguous runs of the walk's final hexagram, so in REL order
  the most significant coordinate is the walk's end, not its earliest pair-slots. None of the seven
  drawn observables steps with those blocks.)*
- **Compare O3 against REL** on the same observable: agreement means the property is order-robust;
  disagreement is a statement about the *orders*, not about the space.
- **Density is uniform by construction.** The grid is systematic (equally spaced ranks), not random,
  so no point is more representative than another; the *spacing* is exact, but the sample is a
  lattice and inherits every hazard of lattice sampling against periodic structure.

## What this figure is allowed to claim

1. **Exact rank identities.** Each `rank` names one specific walk, exactly, and the walk can be
   re-ranked to prove it (`--kc-o3-rank` round trip).
2. **Property values at exactly those index positions**, with the order named.
3. **The negative**, which is the likely and reportable result: that the citable index is not a
   structural coordinate for these observables.

## What it may NOT claim

- **A systematic grid is not a uniform sample.** It is a lattice on the index. Distributional
  statements ("x% of the space has …") require `--kc-sample`'s exact-uniform draw with a pinned
  seed, not this grid. Do not compute percentiles from the spectrum.
- **Nothing about C3 or C15.** The space is C1 ∩ C2 ∩ C4 ∩ C5. `c3_total` is plotted as an
  observable of superspace members; the C15-conditioned distribution is a different quantity, and
  this figure does not carry it. It is exactly computable in principle (`--f1-c3-hist --with-c5`),
  but its full-31 run was priced and permanently declined on cost
  ([TR-12](../reports/TR12_QUERY_PROGRAM.md) §9). ⚠ *Corrected 2026-09-25 (Q-698, V3A-145#7): this
  read "a different, and not exactly computable, quantity", which contradicts TR-12's own record.*
- **Never quote a REL rank as a rank.** REL is the compiler's native descent order; the citable
  order is O3. The `order` column exists so this cannot be lost in a figure caption.
- **No King Wen percentile.** King Wen's position in the citable order is the Q1 certificate
  (`--kc-o3-cert`), a separate exact result with its own verification; it is not readable off this
  figure, and drawing King Wen's rank as a vertical line invites exactly that misreading unless the
  caption forbids it.
- **No aesthetic-rank commentary.** TR-12 §9 declines "interesting rank" framing outright.

## Verification gates

| Gate | Where |
|---|---|
| n=9 exhaustive: `unrank3(i)` byte-matches the independently sorted brute enumeration for all 26,112 walks | `solve --kc-o3-selftest` |
| **O3** unrank/rank round trip + exhaustive emission check (⚠ *corrected 2026-09-25, Q-698, V3A-145#2: this row read "REL"; AR-2 is the O3 battery and its trailer prints `order=O3`*) | `solve --kc-ar2 FDIR GDIR`, `solve --kc-ar2-selftest` |
| **REL** unrank/rank round trip, n=9 exhaustive (the order of the shipped table) | `solve --kc-selftest`, gate `A3 unrank(i)==i-th walk && rank o unrank == id, ALL i` |
| **grid emitter, n=9 exhaustive** (PENDING with the flag — the O3 route only; the shipped REL figure does not use it) | must be shown able to FAIL before any full-31 use |
| **the shipped join** | `--v3-spectrum` re-derives C1/C2/C4/C5 membership from every emitted record through the battery's own decoder and packs King Wen as a positive control that must reproduce every frozen `_P2_KW_VALUES` entry; any failure refuses the run (`V3_SPECTRUM=FAIL`) |
| **reader-side:** re-rank every walk in the TSV with the ranker of the row's `order`; `rank` must come back byte-identical (⚠ *corrected 2026-09-25, Q-698, V3A-145#2: this named `--kc-o3-rank` for every row, but the shipped table is REL. Executed at n=9: the REL rank-0 walk has O3 rank 16244, and `--kc-rank` returns 0*) | `order = REL`: `solve --kc-rank FDIR "$walk"`; `order = O3`: `solve --kc-o3-rank FDIR GDIR "$walk"` |
| **reader-side:** `rank` a canonical integer, strictly increasing; `x` in [0,1), strictly increasing; one `order` per table (⚠ *corrected 2026-09-25, Q-698, V3A-145#3: the old one-liner compared only `$3`, which is `x`, and only for a decrease. It never read `rank`, and it never tested equality or [0,1). `rank` is compared as a string by length because awk compares numeric-looking fields through a binary64*) | `awk -F'\t' 'NR==1{next} {r=$2 ""; if (r !~ /^(0\|[1-9][0-9]*)$/) print "BADRANK", NR; else if (NR>2 && (length(r)<length(p) \|\| (length(r)==length(p) && r<=p))) print "NONMONOTONE", NR; if (!($3+0>=0 && $3+0<1)) print "X_RANGE", NR; if (NR>2 && $3+0<=px) print "X_NONMONOTONE", NR; if (NR>2 && $4!=o) print "MIXED_ORDER", NR; p=r; px=$3+0; o=$4}' tr12/v3_spectrum.tsv` (must print nothing) |
| **reader-side:** every observable within its documented range | the table above |

## Where the files live

- **This doc:** `viz/viz_kc_spectrum.md`
- **Generator (TSV → figure):** `viz/report_figures.py`
- **Evidence TSV:** `<artifact-root>/spectrum/v3_spectrum.tsv` (one per order); committed REL table
  `tr12/v3_spectrum.tsv`, from the grid `tr12/v3_rel_grid.tsv`
- **Figures:** `runs/<run-id>/viz/viz_kc_spectrum.{png,svg}` → mirrored to
  `reports/figures/fig_tr12_kc_spectrum.{png,svg}`

## Related

- [SOLUTIONS_FORMAT.md](../documentation/SOLUTIONS_FORMAT.md) — the 32-byte record encoding the
  grid emitter must produce.
- [DISTRIBUTIONAL_ANALYSIS.md](../documentation/DISTRIBUTIONAL_ANALYSIS.md) — the observable battery
  and why slice-scoped distributions are not population distributions.
- [SOLVE_C_CLI.md](../documentation/SOLVE_C_CLI.md) — the `--kc-*` family and the REL / O3 order
  labelling rule.

---

*Specification per TR-12 §2 (V3). Ranking and unranking against a counting DP is classical
(Nijenhuis & Wilf; Knuth TAOCP 4A §7.2.1) — nothing here is claimed novel; the figure is a scatter
of existing observables against an existing index. Developed with AI assistance (Claude, Anthropic);
corrections invited.*
