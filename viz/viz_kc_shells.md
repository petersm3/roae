# Visualization — V4, King Wen's neighbourhood shells (how the space collapses onto one ordering)

**The rarity profile of King Wen, drawn.** Fix King Wen's first *i* pair placements; count — exactly
— how many members of the whole superspace still agree with it. That count is the *i*-th shell. The
figure plots the 32 shells on a log axis as they fall from the entire space to the single ordering,
together with the surprisal each individual choice contributes. It is TR-12's Q3 table as a picture.

← Back to [README.md](README.md) (index) · V-family: [V1 field](viz_kc_field.md) ·
[V2 river](viz_kc_river.md) · [V3 spectrum](viz_kc_spectrum.md) · **V4** ·
[V5 grammar](viz_kc_grammar.md)

## Status (2026-08-22)

| Piece | Instrument | State |
|---|---|---|
| The 31-row f·g descent trace along King Wen's own path | `solve --kc-o3-rank FDIR GDIR "<walk>" --kc-trace` | **EXISTS** (source + binary, verified) |
| Per-step flow identity, endpoint checks, `Π p_i = 1/N` self-check | printed by the same command as `#o3-trace-summary` | **EXISTS** |
| Optional band: min/max `g` over the *alternatives* at each step | `solve --kc-profile FDIR GDIR "<walk>" --kc-tsv FILE --kc-alts` | **EXISTS** (`g_alt_min` / `g_alt_max`; the consumer carries them through and `fig_tr12_kc_shells` shades the band) |
| Full-31 f and g ladders | Stage F / Stage G | **NOT YET BUILT** |
| Trace text → figure TSV | `python3 solve.py --atlas-queries ATLAS.json --atlas-q3-trace TRACE.txt` | **EXISTS** (n=9 gated: `--atlas-selftest`, `ATLAS_CONSUMER=PASS`) |

Unlike the other four, V4's main curve needs **no new engine work at all** — only the ladders. The
optional band does.

## The quantity plotted

Let **SUPER** = C1 ∩ C2 ∩ C4 ∩ C5 (C3 is **not** applied) with `N = |SUPER|` exact, and let
`s_0, s_1, …, s_31` be the states along King Wen's own walk: `s_0` is the root (C4 has already
pinned pair 0 at slot 1) and `s_i` is the state after King Wen's *i*-th free placement.

**The shells.** Define

```
Shell_i = { w ∈ SUPER : w agrees with King Wen on free placements 1 … i }
|Shell_i| = g(s_i)
```

so `Shell_0 = SUPER` (`g(s_0) = N`), the shells are strictly nested and decreasing, and
`Shell_31 = {King Wen}` (`g(s_31) = 1`). The main panel plots `g(s_i)` against `i` on a **log₂
axis** — a monotone descent from `log₂N` bits to 0.

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

**The alternatives band (PENDING).** At step *i* the trace reports `alts` — the number of admissible
oriented successors with `g > 0` — but not their individual masses. TR-12 §8 item 5 specifies
`--kc-profile "e,x,…"` to print `g` for *each* alternative, which is what a min/max band around the
shell curve requires. Without it the figure ships as the curve plus the `alts` count, and **must not
draw a band**.

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

`tr12/q3_profile_kw.tsv` — one row per free placement, 31 data rows at full-31:

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

**Full-31 (PENDING the ladders).** `--kc-o3-rank` takes an explicit walk — it does **not** accept
the literal `KW` (that convenience lives on `--kc-o3-cert` and `--check-arrangement`), so build the
walk string from `solve.py`, the single source of truth for the King Wen sequence:

```bash
KWWALK=$(python3 -c 'from solve import binary_hexagrams as K; print(",".join(str(K[i]) for i in range(2,64)))')
#   62 integers: entry,exit for each of the 31 FREE pairs; the C4-pinned pair 0 is not part of a walk.

solve --kc-o3-rank FDIR GDIR "$KWWALK" --kc-trace [--kc-ooc] [--kc-cache-mb MB] \
      > tr12/q3_trace_kw.txt
```

**Trace text → TSV** — the atlas consumer. Pure re-shaping; the only arithmetic is the float
rendering of an exact fraction the engine already printed:

```bash
python3 solve.py --atlas-queries tr12/scan/atlas.json --atlas-out tr12 \
                 --atlas-q3-trace tr12/q3_trace_kw.txt --atlas-select q3
#   --atlas-q3-trace also accepts a `--kc-profile ... --kc-tsv` table (auto-detected); that
#   source additionally carries dclass / g_alt_min / g_alt_max / choice_rank, and carries no
#   mass_below (an O3-rank quantity), which the consumer writes as -1 rather than guessing.
#   writes tr12/q3_profile_kw.tsv (tr12/q3_profile.tsv at n != 31) and, in tr12/VERDICTS.txt,
#   BOTH TR12_Q3= and TR12_Q3_READER=.
```

`TR12_Q3_READER` is the separate, reader-side verdict QUERY_INVENTORY §3.2 demands: the consumer
recomputes `Π (p_num/p_den)` from the WRITTEN TSV in exact big-integer rationals and compares it
to `1/N`, rather than trusting the engine's own `#o3-trace-summary` attestation. It also re-checks
`g_parent[i] == g[i−1]`, `g(s_0) == N` and `g(s_n) == 1`.


**Rehearsal at n=9 (sub-second, $0):** build the n=9 f and g ladders as in
[viz_kc_field.md](viz_kc_field.md) and run `solve --kc-o3-selftest`, which exercises the trace's
flow identities and the `Π p_i = 1/N` product check exhaustively over all 26,112 walks. The n=9
world has no King Wen, so the *figure* is full-31 only; the n=9 gate covers the machinery.

**TSV → figure:** `viz/report_figures.py` (`fig_tr12_kc_shells`) — a semilog-y step plot of `g`
against `step` (main panel) with a `bits` bar panel beneath and `alts` annotated. TSV in, figure
out; **no analysis logic in `viz/`**.

## How to read it

- **The main curve is a descent from `log₂N` bits to zero** across 31 steps. Its *shape* is the
  content: steep segments are choices that discard most of the remaining space, flat segments are
  choices that barely narrow it.
- **`bits_i` is the same information, differenced.** A tall bar is a rare choice; a short bar is a
  cheap one. Because `Σ bits_i = log₂ N` exactly, the bar panel is a **budget allocation** — it
  shows *where* King Wen's total improbability is spent, and the total is fixed for every member of
  the space, King Wen included.
- **`alts` gives the reference level.** If the `a = alts_i` admissible successors all carried equal
  mass, King Wen's choice would cost exactly `log₂ a` bits. The **signed gap**
  `bits_i − log₂ alts_i` is therefore the readable quantity: negative means King Wen took a
  heavier-than-average alternative, positive means a lighter-than-average one. Read the two series
  together; neither is interpretable alone.
- **Late steps are nearly forced.** As the C5 boundary budget is exhausted, `alts` collapses; expect
  the last handful of steps to contribute almost no bits at all. That is a property of the
  constraint system, not of King Wen.
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
  min/max envelope drawn from `alts` alone would be fabricated.
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
| **reader-side:** `g` strictly decreasing, `g[31] == 1`, `g_parent[i] == g[i−1]` | `awk` over the TSV |

## Where the files live

- **This doc:** `viz/viz_kc_shells.md`
- **Generator (TSV → figure):** `viz/report_figures.py`
- **Evidence:** `tr12/q3_trace_kw.txt` (raw engine output) and `tr12/q3_profile_kw.tsv`
- **Figures:** `runs/<run-id>/viz/viz_kc_shells.{png,svg}` → mirrored to
  `reports/figures/fig_tr12_kc_shells.{png,svg}`

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
