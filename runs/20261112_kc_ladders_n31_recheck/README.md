# n=31 ladders, checked again (2026-11-06 to 2026-11-12)

Two later runs on the retained ladder bytes: the f, g and t ladders that
[`../20260906_kc_ladders_n31/`](../20260906_kc_ladders_n31/README.md) fingerprints. Each transcript opens
with a comment header that gives the verdict, the dates, the command, the binary and the public commit
it was built from, and says exactly what was left out of the captured log.

| file | command | verdict | finished |
|---|---|---|---|
| `VERIFY_CHECK_LAYERS_F_n31.txt` | `LC_LAYERS_COMPLETE=1 verify --check-layers FDIR 31 MASSREF` | `F_LADDER_CHECK_LAYERS=PASS`: `LAYERS_REDERIVED=32`, `LAYERS_ABSENT=0`, `MASSES_COMPARED=31`, `LAST_IN_PLACED_PAIR_CHECKED=526496343563`, `LAST_NOT_IN_PLACED_PAIR=0`, final-layer sum `MATCH` | 2026-11-12 04:27 UTC |
| `LAYERSHA_RECHECK_n31.txt` | `solve --f1c5-layer-sha` on each of the 96 layer files | `TR12_FSHA=PASS`, `TR12_GSHA=PASS`, `TR12_TSHA=PASS`; 96 of 96 equal to `STAGE_{F,G,T}_LAYERSHA.txt` | 2026-11-10 05:41 UTC |

`SHA256SUMS` covers the two transcripts (`sha256sum -c SHA256SUMS`). Both are plain text hashed as raw
bytes; neither is gz-framed, so the #169 framing era does not apply.

**What the f pass adds.** Before it, the f ladder had been checked as a whole: its layer masses, its
digests, and the f·t and f·g identities, which are sums over each layer and do not pin single
entries. `--check-layers` reads every one of the f ladder's 526,496,343,563 entries against
`documentation/F1C5_LAYER_FORMAT.md`: key, rid, value, mask canonicity and, for each entry, that its
stored `last` lies in one of the pairs its mask selects. It also re-derives each layer's
orbit-weighted mass from the bytes and compares it with the published mass column of
`reports/FULL31_EXACT_AGGREGATES.md`. All of it held. The g and t ladders have no per-entry pass of
this kind here.

**What the digest pass adds.** The 96 logical digests were last taken on 2026-09-17 by a standalone
sweep. This run took them again from the retained bytes, with a binary built from a public commit,
and every one is unchanged.
