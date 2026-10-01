# Knowledge Compiler ladders, n=31 — the published per-layer SHA registries

**This directory publishes fingerprints for the ladders, and — since 2026-09-22 — the atlas itself.**
The f, g and t ladders are 15.05 TB; they are **not** distributed here and nothing in TR-12 is
conditional on obtaining them. What ships for *those* is the *recipe plus a fingerprint* — rebuild
by TR-12's Tier A, then check your bytes against these files.

**`atlas_n31.json` is different, and is the one piece of DATA here.** ⚠ *(2026-09-27, Q-857: no longer the only one — the 64 f and t layer sidecars are published under `sidecars/`; see §"The layer sidecars" below.)* It is 5,978,126 bytes,
sha256 `9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558` — the digest TR-12 §12
pins — and it is the *input* every figure in §12 and every token from
`python3 solve.py --atlas-probe` is computed from. It is published because §12's corrections of
2026-09-22 (CX-60, CX-72) turned on figures a reader could not recompute, and the cheapest honest
answer to "a figure a reader cannot recompute is asserted, not published" is to ship the 6 MB input
rather than to soften the claim. Until that date this file's digest was distributed and the file
was not; the earlier wording of this README said so, and is corrected here rather than silently
replaced.

## Two registries, and they answer different questions

| | rows/stage | covers | check with | a match proves |
|---|--:|---|---|---|
| `STAGE_{F,G,T}_SHA256.txt` · `_MD5.txt` | 65 | 32 layer `.bin` + 32 stats `.json` + 1 manifest | `sha256sum -c` | the **files** are byte-identical to the archived ones |
| `STAGE_{F,G,T}_LAYERSHA.txt` | 32 | the 32 layer `.bin` only | `./solve --f1c5-layer-sha DIR` | the **content** is identical, whatever your compressor did |

**Which one you want depends on where your ladder came from:**

- **Given a disk?** Raw-file. You are asking whether these are the same files.
- **Rebuilt via TR-12 Tier A?** Logical. You are asking whether it is the same ladder — and a correct
  rebuild whose zlib emits different bytes **fails the raw-file check**. Only the logical registry
  distinguishes a compressor difference from wrong data.

🔴 **Never cross them.** They digest different byte streams and share no values. Measured on
`t_layer_30.bin`: 888 bytes stored → `9593fa03…`; 29,660 bytes of content → `7f62f236…`. A cross
comparison fails on every layer, not one. `documentation/QUERY_INVENTORY.md` §C-04 records this.

**The logical digests are not recomputed here.** Each is the `own_sha256_decompressed` field of that
layer's shipped `*_layer_stats_NN.json` sidecar, computed by re-reading each finalized layer file when its sidecar is written (`f1c5_layer_sha_hex`), and re-derived live on 2026-09-17 for all 96 layers ⚠ *(corrected 2026-09-29, Codex KCV R15, CX-241: this said the digest was taken inline while the
layer was being finalized, and quoted a `solve.c` comment about a different digest; the sidecar re-reads the file)*. Verified equal to live
`--f1c5-layer-sha` output on `f/00`, `g/31` and `t/30`. Sidecars and the manifest have no logical
stream, which is why that registry has 32 rows and the raw-file one has 65.

## How to use them

```bash
cd <the directory containing run_f/>
sha256sum -c STAGE_F_SHA256.txt      # and md5sum -c STAGE_F_MD5.txt
```

Stock coreutils; no project code needed for this step. A match says your ladder is byte-identical to
the one every number in TR-12 was computed against. A mismatch at layer *k* localises the divergence
to that layer, which is the point of a per-layer registry rather than one digest per stage.

## Which digest, and why there are two

**These are RAW-FILE digests — sha256 of each file exactly as stored.** The layer container holds
per-block RFC-1950 zlib internally (`F1C5LAY2` for f, `F1C5GLY2` for g, `F1C5TLY2` for t), but there is **no
outer wrapper, nothing is `.gz`, and nothing was re-compressed at archive time.** There is nothing
to uncompress before hashing. See `documentation/F1C5_LAYER_FORMAT.md` and
`documentation/GT_LADDER_FORMAT.md` for the container specification.

The md5 companion exists for one specific job: some transfer and storage tools record an md5, and
sha256 cannot be checked against it. Neither file supersedes the other.

⚠ **`--f1c5-layer-sha` is a different attestation and is not this registry.** It digests the layer's
logical content rather than the stored file, which makes it useful for comparing two independently
built ladders, and makes it **not comparable to the rows here**. Comparing them directly fails on
every layer, not one. `documentation/QUERY_INVENTORY.md` §C-04 records that correction.

## Provenance

Generated 2026-09-06 from the ladders as archived, and cross-checked in both directions against an
independently recorded md5 and byte count for each file — 195/195 matching on byte count and digest.

| stage | files | bytes |
|---|--:|--:|
| f | 65 | 3,293,894,509,534 |
| g | 65 | 8,274,432,288,476 |
| t | 65 | 3,483,654,585,228 |

The producing commits are pinned in TR-12: `befd4e1be70ded9a50826df05fefec3d3422835d` for f,
`453e1bf5c7e40151485a89be76c5bc88a08be910` for g and t.

## The f·t node identity, checked at full n=31 (added 2026-09-15)

`KC_T_CHECK_n31.txt` in this directory records a **`KC-T CHECK n=31 PASS`** — the f·t node identity
holding at every layer `k = 0..31`, **0 failing layers**.

This is a different kind of attestation from the digest registries above, and the difference is the
point. A digest says *these bytes are the bytes we archived*. This says *the t ladder and the f
ladder agree as mathematics*: it tests a **relationship between two ladders**, which no digest of
either can substitute for.

    f total (walks)      = 1097051278789181790036112071176579186688
    t(root) (tree nodes) = 8690552978660778147480075615137911218123

Reproduce, after rebuilding f and t per TR-12 Tier A and checking your bytes against the registries
above:

```bash
./solve --kc-t-check FDIR TDIR --kc-ooc --kc-cache-mb 8192
```

Measured: 25 h 47 m single-threaded (2026-09-14 19:31:13 UTC → 2026-09-15 21:17:51 UTC), binary
sha256 `a253828bfe9e065a82c57f1eec7f00e66f0416822deb1c7521cb7204eb576e59`. `--kc-cache-mb` is a
memory/time trade only and does not change the values.

🔴 **What a PASS does not establish.** From `documentation/GT_LADDER_FORMAT.md`: these are
*"integrity checks: they constrain the FILES, not the shared transition relation. They hold for any
transition DAG from which f, g and t were built consistently, so passing them cannot settle whether
that relation is the right one; and the two endpoints degenerate."* The `k=0` and `k=n` endpoints
degenerate by construction — the k=31 sum equals the f total exactly for that reason, and is not an
independent confirmation. Read this as strong evidence of **file-level consistency between f and
t**, not as a proof that the relation is correct.

## Stage T's bytes, verified on the disk (added 2026-09-16)

`STAGE_T_RAW_VERIFY.md` records **`T_RAW_BYTES=PASS` — 65 of 65 t files matching
`STAGE_T_SHA256.txt`, zero mismatches**, hashed directly from the live managed disk.

This closes an asymmetry the other two ladders did not have. f and g were re-read off the device at
copy-in (`dd iflag=direct` after dropping the page cache, 130/130); **t is never copied** — it is the
original disk, mounted read-only — so it never received that treatment. Its registry was generated
*from the ladders as archived*, and the per-layer identity check compares each layer's
**builder-recorded** digest to the registry. Both are real checks; neither reads the disk as it
stands today. A sidecar would still match its registry row if the bytes beneath it had rotted.

Three t checks now exist and none substitutes for another: `--kc-t-check` (the f·t node identity,
`KC_T_CHECK_n31.txt`), the per-layer identity check (builder record vs registry), and this one
(files as stored).

**The *logical* per-layer digests are no longer cost-gated — they were re-derived on 2026-09-17.**
All **32 of 32** t layers matched `STAGE_T_LAYERSHA.txt`, as part of a **96 of 96** sweep across f, g
and t with zero mismatches. Reproduce with `./solve --f1c5-layer-sha DIR` and compare against the
matching `STAGE_{F,G,T}_LAYERSHA.txt`. The ~40 h figure this note previously carried was a
*per-process serial* estimate; because `--f1c5-layer-sha` accepts FILE arguments, the work runs
concurrently and the real cost is set by the largest single layer, not by the sum.

## The layer sidecars (added 2026-09-27)

`sidecars/run_f/f1c5_layer_stats_00.json` … `_31.json` (32 files) and
`sidecars/run_t/t_layer_stats_00.json` … `_31.json` (32 files) are the per-layer JSON sidecars the
f and t builds wrote beside each layer, byte for byte: every one of the 64 is a row of
`STAGE_F_SHA256.txt` or `STAGE_T_SHA256.txt` above, so the registry checks them.

```bash
cd runs/20260906_kc_ladders_n31/sidecars
grep -h layer_stats ../STAGE_F_SHA256.txt ../STAGE_T_SHA256.txt | sha256sum -c --quiet && echo SIDECARS_OK
```

The sidecars are plain JSON, hashed as raw bytes; none is gz-framed, so the #169 framing era does
not apply to these rows.

They are here because TR-12 row `c_q10a` (the Q10 per-layer state census) reads nothing but them and
the atlas, so with them the n=31 census reproduces from the tree:
`bash reports/evidence/tr12/banked_n31_20260922/check_receipts.sh` runs the battery's own row on
them and compares the result with the committed transcript. The f sidecars are schema v1 (the f
ladder was built before `orbit_size_census` entered the schema), so the census column comes from
the t sidecar of the same layer. On all 32 layers the row checks that the t sidecar has the same
`n_masks`, `n_entries` and branching histogram as f's, that its census sums to those counts, and
that its orbit-size-weighted mask count equals C(31, k), the number of k-subsets of the 31 pairs
(Q-904, CX-246). These are count checks: the mask lists are not in the published tree, so the two
state sets are not compared mask by mask. The t sidecars' `mass_total` is in t-units, not N, so
every other column stays f's. The g sidecars are **not** published here: g stores every
admissible entry, so its `n_entries` differs from f's on every layer but the first, and a second
census over a different entry set would read as a disagreement.

The sidecars are per-layer summaries written by the builds, not ladder layers.

## The same identities, read by the independent verifier (added 2026-09-28)

`KC_T_CHECK_n31.txt` above and `reports/KC_G_CHECK_n31.txt` are `solve.c` reading its own ladders.
Two further runs read the same n=31 ladders with `verify.c`, which is written against
`documentation/GT_LADDER_FORMAT.md` and shares no code with `solve.c`. Until now their transcripts
were kept only in the project's private records. They are published here, each behind a comment
header that gives the command, the binary and the dates:

| file | command | verdict | finished |
|---|---|---|---|
| `VERIFY_CHECK_T_LADDER_n31.txt` | `verify --check-t-ladder FDIR TDIR 31` | `TLADDER_RESULT=PASS`, `IDENTITIES_CHECKED=32`, `IDENTITIES_SKIPPED=0` | 2026-09-05 13:24 UTC |
| `VERIFY_CHECK_G_LADDER_n31.txt` | `verify --check-g-ladder FDIR GDIR 31` | `GLADDER_RESULT=PASS`, `IDENTITIES_CHECKED=32`, `IDENTITIES_SKIPPED=0` | by 2026-09-21 10:33 UTC |
| `C67_JOIN_n31.txt` | `verify --c67-join FDIR GDIR --join-c6c7` (reads f layer 23 and g layer 27 only) | `C67_JOIN=PASS`, `C67_JOIN_COUNT=516880238445773965371923491676160`, `C67_JOIN_ORBIT_TILING=PASS` | 2026-09-30 ~11:20 UTC |

Below each header the transcript is the captured log, byte for byte. Its sha256 is in the header.
The header removes nothing from the log; the logs name no host or path. What was left out is
operational detail: host names, disk names and costs. The binary for the t run was not hashed
at the time, and its header says so rather than filling the gap.

The t transcript's per-layer sums give the f ladder's layer masses as read from the f bytes:
`S_k − S_{k+1} = M_k`. For all 31 layers these equal the `mass` column of
`reports/FULL31_EXACT_AGGREGATES.md` §1. `verify --brute-masses` counts M_1 … M_7 one prefix at a
time, with no DP, and matches that column (see `documentation/VERIFY.md`).

The scope is the one stated for `KC_T_CHECK_n31.txt` above. These identities are sums over each
layer. They constrain the files collectively and do not pin individual entries.

## Rights

The **code** in this repository is public domain. The **ladder data these fingerprint is not** — see
the project's rights notice before redistributing any ladder you obtain. Publishing a digest places
no rights claim on it and grants none.
