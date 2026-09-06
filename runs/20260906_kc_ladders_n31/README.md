# Knowledge Compiler ladders, n=31 — the published per-layer SHA registries

**This directory publishes fingerprints, not data.** The f, g and t ladders are 15.05 TB; they are
not distributed here and nothing in TR-12 is conditional on obtaining them. What ships is the
*recipe plus a fingerprint* — rebuild by TR-12's Tier A, then check your bytes against these files.

| file | rows | what it fingerprints |
|---|--:|---|
| `STAGE_F_SHA256.txt` · `STAGE_F_MD5.txt` | 65 | f ladder — membership over C1 ∩ C2 ∩ C4 ∩ C5 |
| `STAGE_G_SHA256.txt` · `STAGE_G_MD5.txt` | 65 | g ladder — completions |
| `STAGE_T_SHA256.txt` · `STAGE_T_MD5.txt` | 65 | t ladder — pruned-DFS subtree size |

**195 rows.** 32 layer `.bin` + 32 per-layer stats `.json` + 1 manifest, per stage.

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
per-block RFC-1950 zlib internally (`F1C5LAY2` for f and g, `F1C5TLY2` for t), but there is **no
outer wrapper, nothing is `.gz`, and nothing was re-compressed at archive time.** There is nothing
to uncompress before hashing. See `documentation/F1C5_LAYER_FORMAT.md` and
`documentation/GT_LADDER_FORMAT.md` for the container specification.

The md5 companion exists for one specific job: cloud object storage records a Content-MD5, and
sha256 cannot be checked against it. Neither file supersedes the other.

⚠ **`--f1c5-layer-sha` is a different attestation and is not this registry.** It digests the layer's
logical content rather than the stored file, which makes it useful for comparing two independently
built ladders, and makes it **not comparable to the rows here**. Comparing them directly fails on
every layer, not one. `documentation/QUERY_INVENTORY.md` §C-04 records that correction.

## Provenance

Generated 2026-09-06 from the ladders as archived, and cross-checked in both directions against the
Content-MD5 that cloud storage stored at upload time — 195/195 matching on byte count and digest.

| stage | files | bytes |
|---|--:|--:|
| f | 65 | 3,293,894,509,534 |
| g | 65 | 8,274,432,288,476 |
| t | 65 | 3,483,654,585,228 |

The producing commits are pinned in TR-12: `befd4e1be70ded9a50826df05fefec3d3422835d` for f,
`453e1bf5c7e40151485a89be76c5bc88a08be910` for g and t.

## Rights

The **code** in this repository is public domain. The **ladder data these fingerprint is not** — see
the project's rights notice before redistributing any ladder you obtain. Publishing a digest places
no rights claim on it and grants none.
