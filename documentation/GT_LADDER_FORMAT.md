# g-ladder and t-ladder on-disk format specification (`--kc-g-build` / `--kc-t-build` artifacts)

Formats documented: **`F1C5GLY1`/`F1C5GLY2`** (g-ladder layer files, v1 raw /
v2 per-block zlib), **`F1C5TLY1`/`F1C5TLY2`** (t-ladder layer files),
**`g_manifest_v1`** / **`t_manifest_v1`** (run manifests). Companion to
[F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md), which defines the shared
container (header layout, v1/v2 body encodings, entry key packing, write
discipline); this document specifies only what the g and t ladders **add or
change** — file naming, magics, manifest direction, value semantics, seeds,
stored domains, and the cross-ladder identities a reader can check.

Source of truth: `solve.c` on the `v4-compiler` branch at commit `453e1bf`
(read 2026-07-24). The format-defining code is the Stage-G module
(`kc_g_gather_pair` / `kc_g_gather_target` / `kc_g_layer_n` / `kc_g_build_mem`
/ `kc_g_write` / `kc_g_ooc_build_layer` / `kc_g_build_ooc`, 2026-07-16), the
Stage-T module (`kc_t_seed_from_f` / `kc_t_build_layer_mem` / `kc_t_write` /
the `fdom` value-channel switch inside the OOC builder, 2026-07-17), the
kind→magic map `f1c5_kind_magic`, and the prefix-parameterized writer/manifest
/resume functions (`f1c5_write_layer_as`, `f1c5_write_layer_v2_as`,
`f1c5_write_manifest_as`, `f1c5_try_resume_as`). The pinned `v4-compiler`
worktree at `befd4e1` contains the g-ladder but **not** the t-ladder (the
t module landed at `fd2de49`, after the pin); this spec follows the branch tip.

## Why this document exists

[TR-11](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §10(vi)'s
single-instrument honesty limit was addressed for the f-ladder by publishing
[F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md) first and writing the
independent reader (`verify.c --check-layers`) against the spec second — the
two-step discipline that surfaced defect F-3. The g-ladder (exact
count-from-any-prefix, the basis of the rank instrument) and the t-ladder
(exact search-tree node counts) had, until this document, **no published
format and no independent verifier**: the only reader was `solve.c` itself
(`--kc-g-check`, `--kc-t-check`), silently extending the single-instrument
limit to them. This document publishes the formats so an independent reader —
written **against this specification, not against `solve.c`** — can verify
the ladders. In the same spirit as the companion spec: **if anything here
fails to match bytes on disk, that mismatch is a finding — report it, do not
patch around it.**

Note on timing: at this writing no full-scale g or t ladder exists on disk
(the modules are written-and-gated on `v4-compiler`, which launches nothing).
The spec therefore precedes the artifacts, which is the correct order.

## What the two ladders are (semantics)

Both are **backward** layered DPs over the same state space as the f-ladder
(TR-11 §3–§5): states `(mask, last, rid)` where `mask` ⊆ the run's `n` pairs,
`last` = exit hexagram of the most recently placed pair, and `rid` = the
capped C5-residual **of the prefix** (mixed-radix over classes `(1,2,3,4,6)`,
least-significant first — identical to the f-ladder's rid coordinate,
[F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md) §Entry encoding). Layer `k`
holds states with `popcount(mask) = k`; the rid digit sum equals `k` (the sum
invariant carries over unchanged). Only canonical masks are stored, values
are per-representative (not orbit aggregates), and both ladders are
G-equivariant under the same hexagram lifts as f — transitions are
Hamming-isometric, so suffix counts and subtree sizes are preserved.

- **g-ladder** (`--kc-g-build`): `g(k, m, last, rid)` = the exact number of
  valid **completions** (placements of the `n−k` remaining pairs into a full
  C1∩C2∩C4∩C5 walk) from that state. `g` of the empty prefix is the
  whole-space count `N` re-derived from the suffix side; more generally
  `f(s)·g(s)` = the number of full walks whose depth-`k` state is `s`, which
  is what makes exact rank/unrank from any prefix possible.
- **t-ladder** (`--kc-t-build FDIR TDIR`): `t(s)` = the exact number of
  **search-tree nodes** in the subtree rooted at `s` of the reference DFS,
  under the node-accounting convention pinned below.

## Backward recurrences (the value definitions)

Notation: pair `i` has hexagrams `(a_i, b_i)`; placing pair `i` from a state
with exit `l` in orientation "enter `e`, exit `x`" (where `{e,x} = {a_i,b_i}`)
is valid iff `d = popcount(l XOR e)` is not 5 (C2) and the residual digit
`p_c(rid) < b0[c]` for `c = class(d)`; the child state is
`(m | bit(i), x, rid + rad[c])`. (`d = 0` cannot occur: all 64 hexagrams are
distinct.) Then, with layer `n` as the base case:

    g(k, m, l, rid) = Σ over valid placements of  g(k+1, m|bit(i), x, rid + rad[c])
    g(n, ·)         = 1   (the empty suffix)

    t(k, m, l, rid) = 1 + Σ over valid placements of  t(k+1, m|bit(i), x, rid + rad[c])
    t(n, ·)         = 1   (a full walk is one leaf node)

Both are built layer `n` down to layer `0` (a "pull" gather from layer `k+1`
into layer `k`).

**t node-accounting convention** (pinned; `--kc-t-cert` certifies it against
an independent brute DFS): a *node* is one valid oriented prefix
`(E_1..E_k)`, `k = 0..n`; the **root** (empty prefix) counts as 1 node;
orientation is explicit and **joint** (one child edge = one
(pair, orientation) placement — no separate orientation-only branch level);
**leaves** (full walks) have `t = 1`; **dead ends** (valid prefixes with no
valid completion, `g = 0`) are still nodes — the DFS visits them and
backtracks. The mapping of these t-units to the production enumerator's
`SOLVE_NODE_LIMIT` counter semantics is deliberately **not** claimed by the
format; that is a separate certificate.

## Stored domains (the load-bearing g/t difference)

- **g**: stored keys at layer `k ≥ 1` are restricted to `last` ∈ the
  **elements of the mask's pairs** (exactly the forward-reachable `last`
  values, closed under the recurrence); at `k = 0` the only `last` is the
  anchor `start_exit`. States with `g = 0` are **not stored** (the emitters
  skip zero slots, as in f). `g` is well-defined on other `last` values too
  but they are never stored — a documented deviation that keeps the g ladder
  f-sized.
- **t**: the t layer `k` inherits the f layer `k`'s **geometry — masks,
  offsets, and keys — byte-identically**; only the value channel differs.
  This is forced by the dead-end case: a valid prefix with `g = 0` is still a
  node and must be stored with `t ≥ 1`, but a pure backward gather never
  produces it. The t domain is therefore exactly the f-stored state space
  (the states with `f ≥ 1`), and every valid child of an f-stored state is
  f-stored (forward closure), so the gather over t layer `k+1` sees every
  subtree. Consequently **every t value is ≥ 1** (never zero), and at layer
  `n` every value is exactly 1.

## Files, naming, magics

A ladder directory contains (`<kk>` = zero-padded `%02d`):

| Ladder | Layer files | v1 magic | v2 magic | Manifest | First line | Build ckpt marker |
|---|---|---|---|---|---|---|
| f (for reference) | `f1c5_layer_<kk>.bin` | `F1C5LAY1` | `F1C5LAY2` | `f1c5_manifest.txt` | `f1c5_manifest_v1` | `f1c5_build.ckpt` |
| g | `g_layer_<kk>.bin` | `F1C5GLY1` | `F1C5GLY2` | `g_manifest.txt` | `g_manifest_v1` | `g_build.ckpt` |
| t | `t_layer_<kk>.bin` | `F1C5TLY1` | `F1C5TLY2` | `t_manifest.txt` | `t_manifest_v1` | `t_build.ckpt` |

The t magic is deliberately **new**, not a GLY reuse — a t file must never be
readable as a g file, the same reasoning that separated GLY from LAY. The
manifest's first line is likewise per-kind, so an f directory can never be
silently opened as a g ladder or vice versa. f, g, and t files may share one
directory or live on separate disks; the prefixes and magics keep them
disjoint.

Everything else about a layer file is **identical to
[F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md)**: the 72-byte header (same
field order; `magic` and `version` per the table above; `n`, `k`,
`start_exit`, `pl_hash`, `n_masks`, `n_entries`, `b0[5]`, and `pad` = 0 for
v1 / BLK for v2), the v1 raw body (`masks`, `off`, `keys`, `vals` — same
sizes, same file-size formula), the v2 per-block zlib body (same `kidx` /
`vidx` framing, same codec), the `(last << 16) | rid` key packing, the
strictly-ascending mask and per-span key order, the 192-bit little-endian
values, and the tmp → fsync → rename → dir-fsync write discipline. Catalog
sidecars (`<pfx>_layer_stats_<kk>.json`) are sha-neutral observability, not
part of the verification surface.

**Mask lists.** Every layer's `masks` array is the **complete list of
canonical masks** of popcount `k` over the run's `n` pairs (produced by the
same canonical-mask enumeration as the forward builder), in strictly
ascending numeric order; a canonical mask whose states all vanished under the
budget keeps an **empty span** (`off[i] = off[i+1]`) rather than being
dropped. The f, g, and t mask lists at the same layer are therefore
identical; for t the equality extends to `off` and `keys` byte-for-byte.

## Manifest: `last_complete_k` counts DOWN

The g/t manifests have the **same fields** as the f manifest
(`n`, `start_exit`, `pl`, `pl_hash`, `b0`, `last_complete_k`; same `pl_hash`
FNV-1a-64 word variant), but because both ladders are built backward
(`n → 0`), `last_complete_k` records the **lowest** built layer:

- after the seed layer `n` is written, `last_complete_k = n`;
- after layer `k` lands, `last_complete_k = k` (layers `k..n` are durably
  present — each layer file is renamed into place **before** the manifest is
  updated to reference it);
- a **complete** ladder has `last_complete_k = 0`.

Unlike the f run's rolling window, the g/t builds **retain every layer**
(building the ladder *is* the point); a completed directory holds all `n+1`
layer files. Eviction resume re-opens the manifest'd layer and continues
downward; intra-layer chunk checkpoints use the same `F1C5BLD1` marker layout
as the f build, under the per-kind marker name in the table. As on the f
side, resume **adopts the on-disk format** (v1/v2), and the in-memory build
path (small `n`) writes v1 while the out-of-core path writes v2 by default
(`SOLVE_F1_OOC_FORMAT=v1` overrides).

Reduced instances: the g build accepts the same group-closed pair-orbit
unions as the f engine (`n ∈ {9,13,16,18,19,21,22,24,25,27,28}`) plus full
31; the t build takes its instance from the f ladder it is built on.

## Expected boundary layers (exact content)

- **g layer `n` (the seed):** exactly one mask (`2^n − 1`), exactly `2n`
  entries — one per element of the run's pairs, `last` values in ascending
  numeric order, every `rid = R−1` (the budget exactly consumed; forced by
  the sum invariant), every value = 1. The full mask is G-fixed and the
  identity lift is trivial, so raw = stored. Note the seed stores **all**
  `2n` pair elements, including `last` values no valid prefix ever reaches
  (their `g` is 1 by the empty-suffix convention; harmless — they meet no
  f entry in any identity).
- **g layer 0:** exactly `{mask 0, key start_exit<<16, value g(0) = N}` —
  the whole-space count from the suffix side. For the full-31 instance `N`
  is the published `|C1∩C2∩C4∩C5|` = 1097051278789181790036112071176579186688.
- **t layer `n`:** the f layer `n` geometry with every value = 1 (every
  `rid = R−1` inherited).
- **t layer 0:** exactly `{mask 0, key start_exit<<16, value t(root)}` —
  the total search-tree size under the pinned convention.

## The cross-ladder identities (what an independent reader can check)

Let `M_j` = the f layer `j` **orbit-weighted mass** (the
[F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md) §Reading-recipe quantity
`Σ_i s_i · orbit(mask_i)`) = the exact number of valid depth-`j` prefixes;
`M_0 = 1` and `M_n = N`. Let `orbit(cm) = |G_run| / |stab(cm)|` over the
run's distinct restricted pair-permutations (TR-11 §2 group; same weight as
the f mass gate — NOT the record adapter's orientation-class multiplicity).

**The f·g cut identity** (`--kc-g-check` asserts this; derivation: the
prefix×suffix concatenation bijection means exactly `f(s)·g(s)` walks cross
state `s`, each walk crosses layer `k` in exactly one state, and
G-equivariance turns the raw-state sum into an orbit-weighted canonical sum):
for **every** layer `k` in `0..n`,

    Σ over canonical masks cm at layer k of
        orbit(cm) · Σ over keys (last,rid) stored in BOTH ladders of
            f(k,cm,last,rid) · g(k,cm,last,rid)
      =  N

(entries present in only one ladder pair with an implicit 0 and contribute
nothing). At `k = n` this degenerates to `Σ f = N`; at `k = 0` to
`g(0) = N`.

**The f·t node identity** (`--kc-t-check` asserts this; obtained by
unfolding the t recurrence against the same bijection — the `Σ orbit·f·t`
telescopes by `M_k` per layer): for **every** `k` in `0..n`,

    Σ over layer-k states of orbit(cm) · f(s) · t(s)  =  Σ_{j=k..n} M_j
                                                      =  (# search-tree nodes at depth ≥ k)

At `k = n` it degenerates to `M_n`; at `k = 0` to
`t(root) = Σ_{j=0..n} M_j`. These are `n+1` independent exact identities per
ladder; for t the geometry (masks, offsets, keys) must additionally mirror f
**byte-exactly** at every layer.

## Invariants a reader can check

Structural (no group needed):

- magic/version per the table; manifest first line per the table; header
  `n`/`k`/`start_exit`/`pl_hash`/`b0` consistent across every layer file and
  the manifest, and `pl_hash` recomputable from the manifest `pl` line;
- all the shared-container invariants of
  [F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md) §Invariants: `off[0]=0`,
  monotone, `off[nm]=ne`; masks strictly ascending, popcount `k`, no bits
  ≥ `n`; keys strictly ascending per span, bits 22–31 zero, `rid < R`,
  **rid digit sum = k** with each digit ≤ `b0[c]`; values nonzero; v1/v2
  file-size formulas; v2 block framing and exact inflate sizes;
- **g**: layer-`n` and layer-`0` exact content per §Expected boundary
  layers; every stored `last` in the mask's pair-element set (`start_exit`
  at `k=0`);
- **t**: geometry byte-identical to the f layer at every `k` (masks, off,
  keys); every value ≥ 1; layer-`n` values all exactly 1; layer-0 singleton.

With the TR-11 §2 group implemented independently:

- every stored mask canonical, and the mask list complete for its layer;
- the f·g cut identity at every layer (= `N`, cross-checked against the f
  ladder's layer-`n` sum and, at full 31, the published count);
- the f·t node identity at every layer (against `M_j` re-derived from the f
  ladder's bytes), `M_0 = 1`, and `t(root) = Σ M_j`.

Entry-level recomputation (the strongest check) is also possible exactly as
in [F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md) §Reading recipe, with the
gather direction reversed (successors `m | bit(i)` canonicalized instead of
predecessors) and, for t, `+1` added per stored state; it requires the
hexagram lifts of the canonicalizing group elements, with the same
harmless-tie caveat noted there.

## What is convention vs derivable

**Pure conventions, published here:** the three-way kind→magic/prefix map;
`g_manifest_v1`/`t_manifest_v1` tags; the DOWN-counting `last_complete_k`;
the g stored-domain restriction (pair-elements only) and the seed's
all-`2n`-elements content; the t geometry-inheritance rule; the t
node-accounting convention (root counts, joint orientation edges, dead ends
count). **Derivable once those are known:** everything else — the container
is [F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md)'s, the recurrences follow
from the published constraint definitions, and both identities follow from
the prefix×suffix bijection.

## Attribution

The Stage-G g-ladder engine (2026-07-16) and Stage-T t-ladder engine
(2026-07-17) on `v4-compiler` are by Claude (Fable 5), operator-directed, on
the #215/#217/#221 out-of-core substrate (see
[F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md) §Attribution for that
lineage). Suffix counting and subtree-size counting on a layered DAG are
classical forward/backward dynamic programming (cf. Nijenhuis & Wilf;
Knuth's search-tree-size estimation lineage, TAOCP 4A §7.2 context); nothing
here is claimed novel beyond composition with the existing substrate. This
specification was written from the `v4-compiler` source at `453e1bf` by
Claude (Fable 5), 2026-07-24, **before** the independent reader
(`verify.c --check-g-ladder` / `--check-t-ladder`) was written against it —
the same spec-first discipline as the companion document. If any statement
here disagrees with bytes an actual build produces, the disagreement is a
reportable finding — please open a correction rather than assuming the
document is right.
