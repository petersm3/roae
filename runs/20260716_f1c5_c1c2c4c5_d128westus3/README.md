# Run record — exact |C1 ∩ C2 ∩ C4 ∩ C5| (full-31), 2026-07-16

*Completed run 2026-07-16 (landed ~06:18 UTC). Reproducibility record for the flagship exact count reported in [TR-11 §9](../../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md).*

## Result

**|C1 ∩ C2 ∩ C4 ∩ C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688** (≈ 1.097051 × 10³⁹, log₂ ≈ 129.7 bits)

Orientation-explicit sequences, C4's opening pair pinned; the raw convention (baseline 64!, C1+C4 layer 31!·2³¹).

## Verification gates (all pass)

| Gate | Value | Result |
|---|---|---|
| Free-action divisibility | N mod 24 | **0** (exact) |
| Orbit count | N / 24 | 45,710,469,949,549,241,251,504,669,632,357,466,112 |
| Estimator calibration | N / (Knuth estimate 1.0971 × 10³⁹) | **0.999956** (estimate accurate to 0.0044%) *(preserved as recorded; per [TR-11 v1.4](../../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) the 0.0044% is the estimate's five-sig-fig rounding gap, not a resolved estimator error — the validation statement is that the exact value falls inside the stated ±0.01% envelope)* |
| Per-layer Burnside palindrome | masks(k) = masks(31−k) | 6/6 recoverable pairs hold; peak k15=k16=13,047,760; terminal k31=1 |

Reader-side re-derivation of the divisibility gate: reduce the integer above mod 24 in any big-integer language (= 0).

## Method

Out-of-core symmetry-quotient dynamic program (`solve --f1-exact-c1c2c4c5 --f1-out-of-core DIR`). Layer-by-layer over mask popcount k = 0..31, storing only canonical masks (minimum image over the 24 pair-permutations of the record-level S₄). The mathematics, validation ladder, and out-of-core design are documented in TR-11. Exactness rests on the TR-5 free-action theorem; the count is carried in hand-rolled 192-bit integers (no third-party bignum dependency).

## Run parameters

| Field | Value |
|---|---|
| Constraints | C1 (classical pairing) ∩ C2 (no distance-5 adjacency) ∩ C4 (fixed opening pair) ∩ C5 (KW transition-distance multiset) |
| n (free pairs) | 31 |
| n_eff (symmetry quotient) | 24 |
| Threads | 128 |
| Layer format | out-of-core v2 (zlib-blocked — per-block RFC-1950 zlib, not gzip-framed `.gz`; see [F1C5_LAYER_FORMAT.md](../../documentation/F1C5_LAYER_FORMAT.md)) |
| B0 boundary budget (d=1,2,3,4,6) | (2, 8, 13, 7, 1), sum = 31 [KW-derived] |
| Pair-list hash | da2d4756d0535d0e |
| Solver | `main` commit `14db3f5` (v2 zlib-blocked layers + intra-layer checkpointing) |
| Hardware | D128als_v7 Spot, westus3, 4 TB scratch disk |
| Launched / landed | 2026-07-09 / 2026-07-16 (~7 days wall) |
| Spot evictions | 12, every one auto-recovered from the last complete-layer checkpoint (no lost work) |
| Peak RSS | **24,122.0 MB** (≈23.6 GiB) — the highest `rss_peak` in the run's own `[f1c5-ooc]` telemetry, at `SOLVE_F1_OOC_SCRATCH_MB` = 16384 (see the correction below) |

⚠ **[CORRECTED 2026-09-25 (Q-758, Codex V3B-02#12) — the Peak RSS row read "~13 MB (out-of-core;
index-only in RAM)", and `count_result.json` carried `"peak_rss_mb": 13`.** That is below TR-11's own
floor: the two live layers' 12 B/mask indexes alone are 12 × (13,047,760 + 11,530,906) B ≈ 295 MB at
k16/k17. The run's log, `run.out` (now published beside this README; its sha256 `8c7d063e…` is the
one `PRESERVE_SHA256.txt` has listed since the landing), shows where 13 came from. After the count
landed at line 169, the relaunch loop started the binary 18 more times. Each start resumed from the
completed layer 31, did no work, and printed `PEAK RSS 10.8`–`12.9 MB measured … (at layer k=0)`.
The landing record's "~13 MB" matches those no-op lines, not the working run. The segment that actually finished the count prints
`PEAK RSS 24122.0 MB measured` at line 165. Across the 31 per-layer `[f1c5-ooc] layer k=` lines, `rss_peak`
rises from 13.5 MB at k=1 to 24,122.0 MB by k=24. Every one of the 31 segment headers prints
`scratch_budget=16384 MB`. The number in the row above is therefore a high-water mark per process
(`VmHWM`), and it is the maximum over what was logged. A segment that was evicted between two layer
lines could have gone higher without leaving a record. No count, sha or gate moves.]**

## Files in this record

- `README.md` — this file
- `count_result.json` — machine-readable result + gates
- `layer_curve.md` — per-layer canonical-mask counts (Burnside palindrome) + peak
- `f1c5_manifest.txt` — the run manifest (last_complete_k=31, pl_hash)
- `PRESERVE_SHA256.txt` — sha256 of the preserved landing artifacts
- `run.out` — the run's full console log (385 lines; published 2026-09-25, Q-758; sha256 as listed in `PRESERVE_SHA256.txt`)

## Reproducing

Any reader can reproduce the count on commodity hardware (~64 GB RAM + ~4 TB disk):

```
./solve --f1-exact-c1c2c4c5 --f1-out-of-core DIR   # raise SOLVE_F1_OOC_SCRATCH_MB (e.g. 16384 on a 64 GiB box) to hold read amplification near 1x
```

⚠ **[CORRECTED 2026-09-24 (Codex V3B-13#23, Q-742) — the example read `61440`. Resident memory runs at
about 2.2× the setting, so 61440 asks for ≈132 GiB on the ~64 GB box this section sizes. 61440 is the
production 256-GiB D128 setting. TR-11 v1.26 (2026-09-03) and `documentation/SOLVE_C_CLI.md` already give
16384 for this box, and this run README was not swept then.]**

Every completed layer file in `DIR` is a checkpoint; after any interruption re-run with `--resume-from-layers`. Cross-mode equivalence: run any `--f1-pairs N` subset with and without `--f1-out-of-core` — totals must match, and with `SOLVE_F1_OOC_FORMAT=v1` the layer files must be byte-identical (under the v2 out-of-core default the files are content-identical but byte-different; compare with `--f1c5-verify-layer` — TR-11 §10(vi) precision note). See TR-11 Verification Guide.

*Direction and the orbit-quotient idea are the operator's; the recursion reconstruction, out-of-core streaming design, and implementation are by Claude (Fable 5); the count-landing record here is by Claude (Opus 4.8). The underlying symmetry theorem is TR-5's. Technique-level prior art (Burnside / orbit counting, canonical-representative generation, external-memory layered DP) is classical — no novelty claimed.*
