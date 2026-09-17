# Stage T container verification — the t ladder's bytes, hashed on disk

**Verdict: `T_RAW_BYTES=PASS` — 65 of 65 files match `STAGE_T_SHA256.txt`, zero mismatches.**
Measured 2026-09-16 (started 01:22:02Z, finished 05:18:41Z) on the live t ladder, 8 parallel
`sha256sum` streams.

## Why this was the last open gap

The three ladders were NOT equally attested, and t was the odd one out:

| ladder | bytes on disk -> published registry | builder's record -> published registry |
|---|---|---|
| f | verified at copy-in: `dd iflag=direct` after `drop_caches`, 130/130 | `TR12_FIDENT=PASS` |
| g | same, 130/130 | `TR12_GIDENT=PASS` |
| **t** | **was: NOTHING HAD EVER HASHED t's BYTES ON THIS DISK** | `TR12_TIDENT=PASS` |

t is never copied — it is the original managed disk, mounted read-only (`blockdev --setro`), so it
never received the copy-in verifier's treatment that f and g did (`expected_digests.tsv` holds zero
t rows). Its published registry was generated **from the ladders as archived**, and `TR12_TIDENT`
compares each layer's **builder-recorded** `own_sha256_decompressed` against that registry. Both are
real checks, and neither reads the disk as it stands today: a sidecar would still match its registry
row if the bytes underneath had rotted.

This check closes that. It is the container question — *are these still the archived bytes* —
answered directly from the device.

## What it proves, and what it does not

**Proves:** every one of the 32 layer `.bin` files, 32 stats `.json` sidecars, and the manifest on
this disk is byte-identical to what was archived and published on 2026-09-06.

**Does NOT prove:** that the t ladder is mathematically correct. That is a different question and a
different instrument — `--kc-t-check`, published in `KC_T_CHECK_n31.txt`, which verified the f.t node
identity at every layer 0..31. Nor does it re-derive the *logical* (decompressed-stream) digests.
That is a separate attestation against `STAGE_T_LAYERSHA.txt`, and it has since been done: on
2026-09-17 all **32 of 32** t layers matched, as part of a **96 of 96** sweep across f, g and t with
zero mismatches. Reproduce with `./solve --f1c5-layer-sha DIR` and compare against
`STAGE_T_LAYERSHA.txt`. Note the battery row itself still reports `TR12_TSHA=SKIP:cost-gated`,
because the battery does not run that pass inline — the row and the question have different answers,
and the ~40 h figure was a per-process serial estimate, not a floor.

The three t checks are orthogonal and none substitutes for another:

| check | what it hashes | status |
|---|---|---|
| `--kc-t-check` | nothing — the f.t node identity | PASS (`KC_T_CHECK_n31.txt`) |
| `TR12_TIDENT` | the builder's recorded digest vs registry | PASS, 32/32 |
| **this file** | **the files as stored, on the disk** | **PASS, 65/65** |

## Reproduce

```bash
cd <the directory containing run_t/>
sha256sum -c STAGE_T_SHA256.txt
```

**Which framing era this recipe assumes: the RAW container, post-#169.** `STAGE_T_SHA256.txt` records
each file's digest *as stored on disk*, gzip framing included, so plain `sha256sum -c` is the correct
tool here and no `gzip -dc` step belongs in front of it. That is the **opposite** of the #169 shard
case, where the `.sha256` sidecar held the LOGICAL (decompressed) digest and `sha256sum -c` therefore
printed `FAILED` on a byte-correct artifact. The logical digests for t live in a *different* registry,
`STAGE_T_LAYERSHA.txt`, checked with `./solve --f1c5-layer-sha` — never compare one against the other.

Stock coreutils; no project code needed. A mismatch at layer *k* localises the divergence to that
layer, which is the point of a per-layer registry.

## Provenance

Run on the Path C host while the managed disk `v4-staget-data-westus3` was mounted read-only at
`/mnt/staget/run_t`. Measured digests preserved at
`roae-private/scripts/v4_query_evidence/run1_prescan/T_SHA256_MEASURED.txt`. The comparison
normalises path prefixes: the registry stores `run_t/t_layer_NN.bin`, the measurement stores the
bare filename.
