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
1. **Establish each observable's range on the space FIRST** (`--kc-extremal FUNC DIR max` and `min`;
   `constant_on_space=yes` is printed for exactly the forced ones). An observable with one value
   carries no spectrum; drop it or label it CONSTANT rather than plotting a flat line.
2. **Values are orbit-replicated.** G-invariant observables are constant on a whole orbit, so a
   K-point rank grid samples far fewer independent values than K. The step structure that results
   is symmetry, not signal — the same caveat V1 carries.


## Status (2026-08-22)

| Piece | Instrument | State |
|---|---|---|
| Unrank at an arbitrary rank, REL order | `solve --kc-unrank DIR RANK` (f ladder only) | **EXISTS** |
| Unrank at an arbitrary rank, **O3 citable order** | `solve --kc-o3-unrank FDIR GDIR RANK` (both ladders) | **EXISTS** |
| The observable battery over a record file | `python3 solve.py --compute-stats SOLUTIONS_BIN OUT_DIR` | **EXISTS** |
| Grid emitter: unranked walks → a `solutions.bin` the battery can read | — | **PENDING** — proposed `--kc-unrank-grid` (below) |
| Full-31 f / g ladders | Stage F / Stage G | **NOT YET BUILT** |

**This figure is the one V-family member with a real missing instrument.** Both unrankers exist and
the observable battery exists, but nothing joins them: `--kc-o3-unrank` prints a walk as an
`entry,exit,…` line, while `solve.py --compute-stats` consumes a 32-byte-record `solutions.bin`
([SOLUTIONS_FORMAT.md](../documentation/SOLUTIONS_FORMAT.md)). The walk → record adapter (prepend
the C4-pinned pair, pack `byte i = (pair_index << 2) | (orient << 1)`, write the `ROAE` header)
belongs in `solve.c` next to the unranker that already owns those conventions — **not** in `viz/`,
where the standing rule is TSV-to-figure only.

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

Until it lands, V3 has no TSV and therefore no figure. The shell-loop alternative
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
| `fft_peak_amplitude` | 0.0…500.0 | 374.77 |

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

## Input TSV

`tr12/spectrum/v3_spectrum.tsv` — one row per grid point, `K` data rows:

| Column | Type | Meaning |
|---|---|---|
| `i` | int, 0…K−1 | grid index |
| `rank` | decimal **string** | `r_i = i · ⌊N/K⌋`, exact 192-bit — parse with `int()` |
| `x` | float | `r_i / N ∈ [0,1)`, the plotted abscissa |
| `order` | `O3` \| `REL` | which total order the rank refers to — **mandatory, never dropped** |
| `walk` | string | `entry,exit,…` (62 integers at full-31), the unranked walk |
| `edit_dist_kw` … `fft_peak_amplitude` | int / float | one column per battery observable, in the table order above |
| `kw_<observable>` | int / float, **optional** | King Wen's value for that observable, constant down the grid — drawn as the horizontal reference line, never plotted as a panel of its own |

One TSV per order; a spectrum mixing O3 and REL rows in one panel is a labelling error.

The `kw_*` columns are optional **and they are the only way a reference line gets drawn**.
`viz/` holds no analysis, so the renderer will not look King Wen's value up: a panel whose
`kw_<observable>` column is absent is drawn with no reference line, and the figure's subtitle says
how many panels carry one. A `kw_*` column that is *not* constant down the grid is refused as a
labelling error rather than averaged. The King Wen column of the observable table above is the
source those values are emitted from.

## Generation

**Full-31 (PENDING both the ladders and `--kc-unrank-grid`):**

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
  negative.
- **A monotone drift** = the order's leading coordinate correlates with that observable. For O3
  (pair-vector lex) a drift in `edit_dist_kw` would be nearly tautological — the order sorts on the
  pair vector, and King Wen's pair vector is the identity — so read that panel with suspicion.
- **Step structure** = the order's leading positions partition the index into blocks; block
  boundaries in `x` correspond to changes in the earliest pair-slots.
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
  observable of superspace members; the C15-conditioned distribution is a different, and not exactly
  computable, quantity.
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
| REL unrank/rank round trip + exhaustive emission check | `solve --kc-ar2 FDIR GDIR`, `solve --kc-ar2-selftest` |
| **grid emitter, n=9 exhaustive** (PENDING with the flag) | must be shown able to FAIL before any full-31 use |
| **reader-side:** re-rank every walk in the TSV; `rank` must come back byte-identical | `solve --kc-o3-rank FDIR GDIR "$walk"` per row |
| **reader-side:** `rank` strictly increasing, `x` in [0,1) | `awk -F'\t' 'NR>1{if ($3<p) print "NONMONOTONE", NR; p=$3}'` |
| **reader-side:** every observable within its documented range | the table above |

## Where the files live

- **This doc:** `viz/viz_kc_spectrum.md`
- **Generator (TSV → figure):** `viz/report_figures.py`
- **Evidence TSV:** `tr12/spectrum/v3_spectrum.tsv` (one per order)
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
