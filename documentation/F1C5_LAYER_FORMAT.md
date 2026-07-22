# f1c5 layer-file format specification (`--f1-exact-c1c2c4c5` out-of-core artifacts)

Formats documented: **`F1C5LAY1`** (v1, raw), **`F1C5LAY2`** (v2, per-block
zlib — the out-of-core default), **`f1c5_manifest_v1`** (run manifest),
**`F1C5BLD1`** (intra-layer build checkpoint).

Source of truth: `solve.c` on `main` at commit `c5821dd` (read 2026-07-22).
The format-defining code (`f1_pl_hash`, the layer header, the v1/v2 writers,
the manifest writer, the resume reader, `f1c5_v2_kblk_base`, the build-
checkpoint writer and reader) was diffed function-by-function against the
`v4-canonical` branch at `28826e2` and is **byte-identical** on both branches.
The branches differ only in sha-neutral operational extras present on `main`
and absent on `v4-canonical`: the `f1c5_progress.json` observability sidecar,
`SOLVE_F1_KEEP_LAYERS`, and the `SOLVE_F1_STREAM_COLD_CMD` archival hook (all
noted below where relevant). Nothing on either branch writes different layer
bytes.

## Why this document exists

[TR-11](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §10(vi) is
explicit that the full-31 exact count currently rests on a single instrument.
The layer files that instrument streams to disk are its only inspectable
intermediate state, and until now their on-disk format was not published —
an independent checker could not read them without reading `solve.c`, which
would reintroduce the shared-misreading failure class that finding F-3 proved
is real. This document publishes the format so that an independent reader —
written **against this specification, not against `solve.c`** — can verify
sampled content of all 31 layers, not just the run's printed head/tail
values. Precedent: [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) did this for
`solutions.bin`, and `verify.py` was then written against the spec; the act
of publishing the TR-11 §4b/§5 recipe is likewise what surfaced defect F-3.
In that spirit: **if anything in this document fails to match bytes on disk,
that mismatch is a finding — report it, do not patch around it.**

This is a specification only. The independent reader is a separate, later
artifact (per the repository's verifier discipline it belongs in `verify.py`
or `verify.c`, which import nothing from `solve.c`).

## What a layer file contains (semantics)

`solve --f1-exact-c1c2c4c5` computes the exact `|C1 ∩ C2 ∩ C4 ∩ C5|` count by
a layered dynamic program over the 31 non-anchor hexagram pairs (TR-11 §3–§5).
The DP state is a triple:

- **mask** — a subset of the `n` pairs already placed (bit `i` set = subset
  index `i` placed; for the full-31 run subset index `i` corresponds to pair
  `i+1` of the pair table in [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) §Pair
  table; pair 0 = (63, 0) is the C4-fixed anchor and never appears).
  Only **canonical** masks are stored: a mask is canonical iff it is the
  numeric minimum of its orbit under the 24 pair-permutations induced by the
  TR-5 symmetry group (TR-11 §2 defines the action).
- **last** — the exit hexagram (0–63) of the most recently placed pair.
- **rid** — the capped C5-residual: the multiset of boundary-transition
  distance classes used so far, packed as a mixed-radix integer (§Entry
  encoding below).

Layer `k` holds every reachable state with `popcount(mask) = k`. The stored
values are **exact plain-DP forward path counts at the canonical
representative mask itself** (not orbit aggregates): the entry for
`(m, last, rid)` in layer `k` is the number of ways to place the `k` pairs of
canonical mask `m` in sequence, obeying C2 and the C5 boundary budget, ending
at exit hexagram `last` with residual `rid`. Orbit weighting (multiplying by
orbit size) happens only when a layer *mass* is reported, never in the stored
values. Consequently any single entry can be independently spot-checked from
the previous layer's file (§Reading recipe).

Counts are plain **192-bit unsigned integers** (three 64-bit little-endian
limbs, low limb first). There is no CRT or multi-residue representation; the
code is explicit that counting is "single pass, no CRT".

## Run-directory layout and lifecycle

A run directory (`--layers-dir DIR` for the in-RAM mode, `--f1-out-of-core
DIR` for the streaming mode; mutually exclusive) contains:

| Name | What it is |
|---|---|
| `f1c5_layer_<kk>.bin` | Completed layer `k` (`<kk>` = zero-padded decimal `%02d`, `00`–`31` for full-31). The **only** completeness marker for a layer is the existence of this final name (files appear atomically via rename). |
| `f1c5_manifest.txt` | Run manifest; records the last complete layer (§Manifest). |
| `f1c5_layer_<kk>.bin.tmp` | In-progress final assembly of layer `k`. Never valid to read; a leftover `.tmp` after a crash is garbage and is overwritten by the next run. |
| `f1c5_layer_<kk>.bin.vals.tmp` | v1 out-of-core only: value-section staging sidecar, relocated into the `.tmp` at finalize and deleted. |
| `f1c5_layer_<kk>.bin.kblk.tmp`, `.vblk.tmp` | v2 only: streaming compressed-block sidecars (keys / values), assembled into the `.tmp` at finalize and deleted. They persist across a mid-layer crash on purpose — the intra-layer checkpoint references them (§Intra-layer checkpoint). |
| `f1c5_build.ckpt` (+ `.tmp`) | v2 only: intra-layer chunk checkpoint marker (§Intra-layer checkpoint). Deleted when the layer's final rename lands. |
| `f1c5_progress.json` (+ `.tmp`) | `main` branch only: sha-neutral JSON observability sidecar, atomically swapped ~every 5 s. Not part of the verification surface; never affects layer bytes. Absent on `v4-canonical`. |

**Write discipline (every durable file):** write to a `.tmp` name → `fflush`
+ `fsync` the file → `rename` to the final name → `fsync` the directory.
A reader may therefore treat any file at its final name as complete and
internally consistent, crash or no crash.

**Ordering:** a layer's file is renamed into place **before** the manifest is
updated to point at it. `last_complete_k = k` in the manifest therefore
guarantees `f1c5_layer_<kk>.bin` exists and is durable.

**Rolling window:** by default, when layer `k+1` starts building (out-of-core
mode) or finishes (in-RAM mode), layer `k−1` is deleted — the directory holds
at most two adjacent complete layers, and after a completed full run it holds
layers `n−1` and `n` only. Two `main`-only environment hooks modify this:
`SOLVE_F1_KEEP_LAYERS=1` suppresses the delete entirely (all layers `0..n`
retained; full-31 v2 ladder ≈ 2.5–2.7 TB), and `SOLVE_F1_STREAM_COLD_CMD`
names a command run as `<cmd> <layer_path> <k>` on each layer just before the
rolling delete (non-fatal, purely archival). Neither changes layer bytes.

**Format selection:** the in-RAM `--layers-dir` mode always writes v1. The
out-of-core mode writes v2 by default; `SOLVE_F1_OOC_FORMAT=v1` selects raw
v1. On resume the engine **adopts the on-disk format** regardless of the
environment, so a directory is never mixed-format. v2 files require the
out-of-core mode to resume.

## Layer file header (72 bytes, common to v1 and v2)

The header is a C struct written whole (`fwrite(&h, sizeof h, 1, f)`), native
byte order, no packing pragma. Under the x86-64/AArch64 System V ABI the
layout below has no padding holes and `sizeof = 72`. All multi-byte fields
are **little-endian** on every host the project supports; a big-endian reader
must byte-swap.

| Offset | Size | Field | Type | Contents |
|---|---|---|---|---|
| 0 | 8 | magic | ASCII | `F1C5LAY1` (v1) or `F1C5LAY2` (v2); no NUL terminator |
| 8 | 4 | version | u32 | 1 (v1) or 2 (v2); must agree with the magic |
| 12 | 4 | n | u32 | number of pairs in the run (31 for full) |
| 16 | 4 | k | u32 | this layer's index; equals `<kk>` in the file name |
| 20 | 4 | start_exit | u32 | anchor exit hexagram, 0 or 63 (0 for full-31) |
| 24 | 8 | pl_hash | u64 | run-parameter hash (§Manifest → pl_hash) |
| 32 | 8 | n_masks | u64 | `nm`, number of canonical masks in this layer |
| 40 | 8 | n_entries | u64 | `ne`, total number of entries |
| 48 | 20 | b0[5] | u32×5 | boundary budget per distance class `(d=1,2,3,4,6)`; `(2,8,13,7,1)` for full-31 |
| 68 | 4 | pad | u32 | **v1: 0. v2: the block size BLK in entries** (see below) |

The field named `pad` is a misnomer retained for layout compatibility: in v2
files it carries the entry-block size `BLK` (compile-time constant
`F1C5_OOC_BLK`, default **65536**, overridable with `-DF1C5_OOC_BLK=…`).
A v2 reader MUST take the block size from this field, not assume 65536.

## v1 body (raw)

Immediately after the header, four contiguous sections:

    masks : nm × u32     canonical masks, strictly ascending
    off   : (nm+1) × u64 entry-offset table; off[0]=0, off[nm]=ne;
                         mask i's entries occupy indices [off[i], off[i+1])
    keys  : ne × u32     packed (last, rid) keys (§Entry encoding),
                         strictly ascending within each mask's span
    vals  : ne × 24 B    F1U192 values (3 × u64 LE limbs, low limb first),
                         all nonzero

Exact file size: `72 + 4·nm + 8·(nm+1) + 28·ne  =  80 + 12·nm + 28·ne` bytes.

## v2 body (per-block zlib)

v2 stores the *identical* logical content — same masks, off, keys, vals, in
the same order — with the keys and vals sections cut into fixed-size entry
blocks and each block independently compressed:

    masks : nm × u32         as v1
    off   : (nm+1) × u64     as v1
    kidx  : (nblk+1) × u64   compressed-byte offsets of the key blocks;
                             kidx[0] = 0, monotone non-decreasing
    vidx  : (nblk+1) × u64   same for the value blocks; vidx[0] = 0
    kblocks : kidx[nblk] B   concatenated compressed key blocks
    vblocks : vidx[nblk] B   concatenated compressed value blocks

where `nblk = ceil(ne / BLK)` (0 when `ne = 0`, in which case kidx and vidx
each contain the single entry 0 and there are no blocks).

Block `b` (0-based) covers entries `[b·BLK, min((b+1)·BLK, ne))`; call the
count `bn`. Section base offsets:

    kblk_base = 72 + 4·nm + 8·(nm+1) + 16·(nblk+1)  =  96 + 12·nm + 16·nblk
    vblk_base = kblk_base + kidx[nblk]

Key block `b` occupies file bytes `[kblk_base + kidx[b], kblk_base +
kidx[b+1])` and decompresses to exactly `4·bn` bytes = `keys[b·BLK …]` as a
little-endian u32 array. Value block `b` occupies `[vblk_base + vidx[b],
vblk_base + vidx[b+1])` and decompresses to exactly `24·bn` bytes of F1U192
values. Exact file size: `kblk_base + kidx[nblk] + vidx[nblk]`.

**The codec is zlib, not gzip.** Despite the project shorthand "v2-gz" and
names like `--f1c5-gzip-selftest` / `SOLVE_F1_OOC_GZIP_LEVEL`, each block is
a single **zlib stream (RFC 1950)** as produced by zlib's `compress2()`:
2-byte zlib header (first byte `0x78`), raw DEFLATE body, 4-byte Adler-32
trailer. There is no gzip (RFC 1952) member header, no file-level wrapper,
and no dictionary. Any RFC-1950-capable inflater can decompress a block;
the Adler-32 trailer gives each block a built-in integrity check, and the
expected decompressed size is known exactly in advance (`4·bn` / `24·bn`) —
a reader should hard-fail on any size mismatch. This is native-zlib only by
project policy (no third-party compression dependencies).

**Compression level** defaults to 6 (`SOLVE_F1_OOC_GZIP_LEVEL`, 1–9). The
level — and the zlib library version, and BLK — affect the compressed
*bytes* but never the decompressed *content*. Only the decompressed content
is canonical; do not expect v2 files to be byte-reproducible across zlib
versions or level settings. v1 bytes, by contrast, are configuration-
independent. (`solve --f1c5-verify-layer <v1> <v2>` is the engine's own
cross-format content check; an independent reader should perform the same
comparison from this spec alone.)

## Entry encoding

Each entry is a `(key: u32, value: F1U192)` pair; the two arrays are
parallel (entry `e` = `keys[e]` + `vals[e]`).

**Key packing:** `key = (last << 16) | rid`.

- `last` = bits 16–21 (value 0–63), the exit hexagram of the last-placed
  pair. Bits 22–31 are always zero, so `key < 64·65536`.
- `rid` = bits 0–15, the capped C5-residual, a **mixed-radix integer with
  least-significant digit first** over the five distance classes in the
  fixed order `d = (1, 2, 3, 4, 6)`:

      radix of class c   :  b0[c] + 1
      place value rad[c] :  ∏_{c' < c} (b0[c'] + 1)
      rid                =  Σ_c  p_c · rad[c]

  where `p_c` = number of boundary transitions of class `c` used so far
  (`0 ≤ p_c ≤ b0[c]`). The rid space size is `R = ∏(b0[c]+1)`, always
  `≤ 65535` (asserted at startup). Worked example, full-31 budget
  `b0 = (2,8,13,7,1)`: radices `(3,9,14,8,2)`, place values
  `rad = (1,3,27,378,3024)`, `R = 6048`; the all-max residual (`p = b0`)
  is `rid = 2·1 + 8·3 + 13·27 + 7·378 + 1·3024 = 6047 = R−1`.

- Distance classes: for a boundary transition between hexagrams `x → y`,
  the class of Hamming distance `d = popcount(x XOR y)` is the index of `d`
  in `(1,2,3,4,6)`. `d = 5` is forbidden by C2 (such transitions are never
  taken); `d = 0` cannot occur between distinct hexagrams.

**Ordering guarantees:** within each mask's span `[off[i], off[i+1])`, keys
are **strictly ascending** — i.e. grouped by `last` ascending, and by `rid`
ascending within a `last` group. Masks themselves are strictly ascending
across the file. This total order is what makes the layer files bitwise
deterministic across the in-RAM and out-of-core builders.

**Values:** `F1U192` = `{u64 l0, l1, l2}` little-endian limbs (value =
`l0 + 2^64·l1 + 2^128·l2`). Stored values are never zero (the emitters skip
zero slots). The full-31 total is ≈ 1.097×10³⁹ ≈ 2^130, comfortably inside
192 bits; overflow aborts the run rather than wrapping.

**Sum invariant (key per-layer self-check):** for every entry of layer `k`,
the rid digit sum equals `k`: `Σ_c p_c = k`, and `p_c ≤ b0[c]` per class.
Layer 0 has exactly one entry: mask 0, key `start_exit << 16` (rid 0),
value 1. Layer `n` has exactly one mask (the full mask `2^n − 1`) and every
entry has `rid = R−1` (the budget exactly consumed) — the run's total is the
plain sum of layer `n`'s values, and for full-31 it must be divisible by 24
(TR-5 free action).

## Manifest (`f1c5_manifest.txt`)

Plain LF-terminated ASCII text, rewritten atomically after every completed
layer. Exact content, in order (values here are the full-31 run's):

    f1c5_manifest_v1
    n=31
    start_exit=0
    pl=1,2,3,…,31
    pl_hash=da2d4756d0535d0e
    b0=2,8,13,7,1
    last_complete_k=<k>

| Field | Meaning |
|---|---|
| line 1 | literal format tag `f1c5_manifest_v1` |
| `n` | number of pairs (31 = full run) |
| `start_exit` | anchor exit hexagram (0 or 63; 0 for full-31) |
| `pl` | comma-separated pair indices of the run, in subset-index order (`1,…,31` for full-31; reduced runs list a group-closed orbit union) |
| `pl_hash` | run-parameter hash, 16 lowercase hex digits (below) |
| `b0` | boundary budget per class `(1,2,3,4,6)` — for full-31 this is KW's boundary multiset `(2,8,13,7,1)`; for reduced runs it is the deterministic-DFS witness multiset (TR-11 §4b) |
| `last_complete_k` | index of the most recent layer whose file is durably renamed in place; 0 after layer 0, `n` after a completed run |

**`pl_hash` algorithm.** An FNV-1a-64 *variant* absorbing 64-bit words
instead of bytes — this is a project convention, not derivable from the FNV
specification, and is stated here precisely so a verifier can reproduce it:

    h = 0xcbf29ce484222325                    # FNV-1a 64 offset basis
    for x in [n, start_exit, pl[0], …, pl[n−1]]:
        h = h XOR x                           # x zero-extended to 64 bits
        h = (h × 0x100000001b3) mod 2^64      # FNV-1a 64 prime

Rendered `%016llx` (lowercase, zero-padded). For the full-31 run
(`n=31, start_exit=0, pl=1..31`) this evaluates to **`da2d4756d0535d0e`** —
computed from the definition above; a reader implementing the recipe should
reproduce it exactly, and its value must equal the `pl_hash` header field of
every layer file in the directory. It commits only to the run's *inputs*
(pair set, anchor), not to the budget — the budget is committed separately
by the `b0` line and the header `b0[5]` field, both of which the engine
cross-checks on resume.

## Checkpoint and resume semantics

**Layer-level (both formats):** every completed layer file is a free
checkpoint. On start (automatic; `--resume-from-layers` merely makes a
missing manifest a hard error) the engine reads the manifest, validates
`n` / `start_exit` / `pl_hash` / `b0` against the current run parameters,
opens `f1c5_layer_<last_complete_k>.bin`, validates its header (magic,
version, `n`, `k`, `start_exit`, `pl_hash`, `b0`), and resumes building from
layer `last_complete_k + 1`. For v2 it additionally validates `pad == BLK`
of the running binary, `kidx[0] = vidx[0] = 0`, per-block compressed sizes
within `compressBound(24·BLK)`, and the exact file-size formula, before any
block is decompressed. Any mismatch is a hard error (wrong directory), not a
silent rebuild.

**Intra-layer (v2 + out-of-core only, `F1C5BLD1`):** full-31 mid layers take
hours, so the builder also snapshots at chunk boundaries — a *chunk* is a
range of `chunk_cap` consecutive target masks, where `chunk_cap =
max(1, min(nm, floor(SOLVE_F1_OOC_SCRATCH_MB·2^20 / (64 · V_{k+1} · 24))))`
and `V_{k+1}` is the number of rids with digit sum `k+1`. Snapshot cadence is
~300 s of wall time (`SOLVE_F1_CKPT_SEC`), plus a deterministic test kill
hook (`SOLVE_F1_KILL_AFTER_CHUNK`).

`f1c5_build.ckpt` layout (contiguous, native little-endian, written
tmp + fsync + rename + dir-fsync):

    magic[8] = "F1C5BLD1"
    nxt_k, pl_hash, chunk_cap, BLK, gzip_level      : 5 × u64
    t0_next                                         : u64   (next chunk's first mask index)
    off[0 … t0_next]                                : (t0_next+1) × u64
    nblk                                            : u64
    kidx[0 … nblk], vidx[0 … nblk]                  : 2 × (nblk+1) × u64
    fill                                            : u64   (partial-block accumulator count)
    bk[fill] (u32 keys), bv[fill] (24 B values)     : present only if fill > 0
    mass (24 B F1U192), states (u64)                : running layer statistics
    io: bytes_read, bytes_written, windows          : 3 × u64
    crc32                                           : u32   (zlib crc32 of ALL preceding bytes; not self-inclusive)

Crash-consistency contract: the `.kblk.tmp` / `.vblk.tmp` sidecars are
fsync'd **before** the marker is written, so the marker's recorded byte
offsets (`kidx[nblk]`, `vidx[nblk]`) always refer to durable data; a kill can
only leave the sidecars *longer* than recorded, never shorter. On resume the
marker is accepted only if **all** of: magic matches; `nxt_k`, `pl_hash`,
`chunk_cap`, `BLK`, and gzip level match the current build; the trailing
CRC32 verifies; the entry-conservation invariant
`off[t0_next] = nblk·BLK + fill` holds; and both sidecars exist with size
`≥` the recorded offsets. On acceptance the sidecars are truncated to
exactly the recorded sizes (discarding any post-marker partial append) and
the build restarts at chunk `t0_next`; because the partial-block accumulator
is restored byte-for-byte, the finished layer file is **byte-identical** to a
straight-through build (given the same zlib, level, and BLK). On *any*
rejection the marker is unlinked and the layer rebuilds from scratch —
always correct, never a silent wrong count. Note the `chunk_cap` match makes
checkpoint validity environment-dependent: resuming under a different
`SOLVE_F1_OOC_SCRATCH_MB` silently discards the intra-layer snapshot (the
layer restarts; the count is unaffected). The marker is deleted when the
layer's final rename lands, so a stale marker can never leak into the next
layer.

## Reading recipe: independently re-deriving a layer's mass

The per-layer `mass=` decimal printed on the run's `[f1c5]` stderr lines —
and checked at small `k` by the independent non-quotient verifier — is a
pure function of the layer file plus the TR-11 §2 group. To recompute it
(sequence of operations; implement in any language):

1. Open `f1c5_layer_<kk>.bin`; validate the header per §Layer file header.
2. Read `masks[nm]` and `off[nm+1]`; check `off[0]=0`, monotone,
   `off[nm]=ne`.
3. Obtain the entry arrays: v1 — read `keys` / `vals` directly; v2 — read
   `kidx` / `vidx`, then for each block `b` inflate the key and value blocks
   and check the exact decompressed sizes.
4. For each mask index `i`: `s_i` = 192-bit sum of `vals[off[i] … off[i+1])`.
5. Compute mask `i`'s **orbit size** = 24 / |stab(masks[i])| for the full-31
   run, where the stabilizer is counted over the 24 pair-permutations of the
   TR-11 §2 action (for reduced runs, over the *distinct restricted*
   permutations, of which there may be fewer than 24). This step is the only
   one requiring the group; steps 1–4 and 6 are purely structural.
6. `mass(k) = Σ_i s_i · orbit(masks[i])` (exact 192-bit arithmetic).
   `states(k)` = number of `(i, last)` pairs having ≥ 1 entry (same-`last`
   entries are contiguous within a span, so this is a linear scan).

Compare against the run log's layer-`k` `mass=` and `states=` fields. For
the final layer, skip the orbit weighting: check `nm = 1`,
`masks[0] = 2^n − 1`, every `rid = R−1`, and sum the values — that sum is
the published count, and `mod 24 = 0` for full-31.

**Sampled entry-level verification (the stronger check).** Any single
canonical mask `m` of layer `k` can be recomputed from layer `k−1`'s file
alone, giving sampled coverage of every layer without rerunning the DP. The
recurrence, entirely in terms of published definitions: for each bit `i` set
in `m`, let `pred = m` with bit `i` cleared, canonicalize `pred` to
`(cpred, g)` (minimum over the 24 mask images; `g` = an element achieving
it), locate `cpred`'s span in layer `k−1`, and for each of its entries
`(last', rid')` let `lp = hinv_g(last')` (the inverse hexagram lift of `g`
applied to `last'` — the TR-5 group element's action on hexagrams) and let
`(a_i, b_i)` be pair `pl[i]`'s two hexagrams (SOLUTIONS_FORMAT.md pair
table). The pair can be entered at `a_i` (exiting `b_i`) or entered at `b_i`
(exiting `a_i`); for each orientation with entry hexagram `f` and exit `s`:
compute `d = popcount(lp XOR f)`; if `d = 5` the transition is C2-dead;
otherwise let `c` = class of `d` and, **iff the residual digit `p_c` of
`rid'` is < `b0[c]`**, add the entry's value into accumulator slot
`(last = s, rid = rid' + rad[c])`. After all predecessors, the nonzero
accumulator slots must equal mask `m`'s span in layer `k` exactly — keys,
values, order and all. (Any tie in the canonicalizing element `g` is
harmless: elements achieving the same minimal mask image act identically on
the stored data by the orbit-invariance the DP relies on; the engine picks
the first in its sorted group order.)

## Invariants a reader can check

Structural (no group needed):

- magic/version pair consistent; `k` equals the filename index; `n`,
  `start_exit`, `pl_hash`, `b0[5]` identical across every layer file and
  the manifest; `Σ b0 = n`; `R = ∏(b0[c]+1) ≤ 65535`; `pl_hash` recomputable
  from the manifest's `n`/`start_exit`/`pl` line via §Manifest.
- `off[0] = 0`; `off` monotone non-decreasing; `off[nm] = ne`.
- `masks` strictly ascending; every mask has `popcount = k` and no bits
  ≥ `n`.
- keys strictly ascending within each mask span; key bits 22–31 zero;
  `last ≤ 63`; `rid < R`; **rid digit sum = k** and each digit ≤ its
  `b0[c]` (the sum invariant — a strong per-entry check);
  values nonzero.
- v1: `pad = 0`; file size `= 80 + 12·nm + 28·ne`.
- v2: `pad = BLK > 0`; `kidx[0] = vidx[0] = 0`; both monotone; each
  compressed key block ≤ `compressBound(4·BLK)` and each value block ≤
  `compressBound(24·BLK)` (zlib's worst-case bound, ≈ source size + a few
  hundred bytes; the engine itself validates both against the larger bound);
  file size `= kblk_base + kidx[nblk] + vidx[nblk]`; every block inflates to
  its exact expected size with a valid Adler-32.
- Layer 0: `nm = 1, masks = [0], ne = 1, keys = [start_exit·65536]`,
  value = 1. Layer `n`: `nm = 1`, mask `= 2^n − 1`, all `rid = R−1`.

With the TR-11 §2 group implemented independently:

- every stored mask is canonical (numeric minimum of its orbit);
- layer masses match the run log (§Reading recipe);
- sampled per-mask entry recomputation from the previous layer (§Reading
  recipe) matches byte-for-byte.

## What is convention (must be told) vs publicly derivable

A verifier author should know which parts of this format they could *not*
have reconstructed from public mathematical definitions — i.e. what this
document is load-bearing for:

**Pure conventions, published here for the first time:** the magic strings;
the 72-byte header layout and field order (including `pad` carrying BLK in
v2); the `(last << 16) | rid` key packing; the rid digit order (classes
`1,2,3,4,6`, least-significant first) — mathematically any digit order
works, files are readable only with this one; the word-wise FNV-1a `pl_hash`
variant; the fact that "gzip"-named machinery actually emits zlib (RFC 1950)
streams; the block-framing scheme and the `F1C5BLD1` checkpoint layout; the
strict `(mask, last, rid)`-ascending entry order; and the tmp/rename/fsync +
manifest-last protocol.

**Derivable from published material once the conventions are known:** the
canonical-mask predicate and orbit sizes (TR-5 / TR-11 §2 group), the pair
table (SOLUTIONS_FORMAT.md), the boundary budget `(2,8,13,7,1)` (recomputed
from the King Wen sequence, TR-11 §4b — noting TR-11 v1.8's correction that
at full 31 the budget is *defined* as KW's boundary multiset), the sum
invariant, the gather recurrence (TR-11 §5), and the expected layer-0/-n
contents.

**Deliberately not canonical:** v2 compressed bytes (zlib-version-, level-,
and BLK-dependent); everything in `f1c5_progress.json`; stderr telemetry.
The canonical content of a layer is its decompressed
`(masks, off, keys, vals)` tuple.

## Notes on cross-mode byte-identity claims

TR-11 §7–§8 state that the in-RAM and out-of-core modes produce byte-
identical layer files. That statement is exact for the configuration those
gates ran: both modes writing the **v1** format (the v2 codec postdates
those commits). Under current defaults the two modes write *different
formats* (in-RAM: v1 always; out-of-core: v2), so their files differ in
bytes while remaining identical in decompressed content — which
`--f1c5-verify-layer` checks, and which an independent reader can check from
this spec. Within a fixed format the byte-identity claims hold as stated,
including across intra-layer checkpoint resumes (same zlib/level/BLK).

## Sibling format (for disambiguation): `F1LAYER1`

The pre-C5 orbit DP (`--f1-exact-c1c2c4`, TR-11 §3) writes a *different,
simpler* family in its `--layers-dir`: `f1_layer_<kk>.bin` with a 40-byte
header (`magic "F1LAYER1"`, u32 version=1/n/k/start_exit, u64
pl_hash/n_masks) followed by `nm × u32` masks and a **dense** value section
of `nm × 64` F1U192s (indexed `[mask_idx·64 + last]`, no rid dimension, no
offset table), plus `f1_manifest.txt` (`f1_manifest_v1`; same fields as
§Manifest minus the `b0` line). Same atomicity discipline, same `pl_hash`.
It is not part of the C5 verification surface but shares the directory
naming style; do not confuse `f1_layer_*` with `f1c5_layer_*`.

## Attribution

The f1c5 orbit-quotient DP and the out-of-core layer format (#215/#217/#221)
were designed and implemented by Claude (Fable 5), 2026-07-04/05, under the
operator's direction (FH-1 direction, residual-dominance conjecture, and the
out-of-core requirement are the operator's). The v2 per-block zlib codec
retool and the intra-layer checkpoint (#223) are by Claude (Opus),
operator-directed, 2026-07-07/08, with correctness findings from Fable
review passes incorporated (format adoption on resume, BLK-in-header,
index validation). This specification was written from the `solve.c` source
by Claude (Fable 5), 2026-07-22. If any statement here disagrees with bytes
an actual run produced, the disagreement is a reportable finding — please
open a correction rather than assuming the document is right.
