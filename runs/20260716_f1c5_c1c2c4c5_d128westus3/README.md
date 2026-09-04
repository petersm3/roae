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
| Peak RSS | ~13 MB (out-of-core; index-only in RAM) |

## Files in this record

- `README.md` — this file
- `count_result.json` — machine-readable result + gates
- `layer_curve.md` — per-layer canonical-mask counts (Burnside palindrome) + peak
- `f1c5_manifest.txt` — the run manifest (last_complete_k=31, pl_hash)
- `PRESERVE_SHA256.txt` — sha256 of the preserved landing artifacts

## Reproducing

Any reader can reproduce the count on commodity hardware (~64 GB RAM + ~4 TB disk):

```
./solve --f1-exact-c1c2c4c5 --f1-out-of-core DIR   # raise SOLVE_F1_OOC_SCRATCH_MB (e.g. 61440) to hold read amplification near 1x
```

Every completed layer file in `DIR` is a checkpoint; after any interruption re-run with `--resume-from-layers`. Cross-mode equivalence: run any `--f1-pairs N` subset with and without `--f1-out-of-core` — totals must match, and with `SOLVE_F1_OOC_FORMAT=v1` the layer files must be byte-identical (under the v2 out-of-core default the files are content-identical but byte-different; compare with `--f1c5-verify-layer` — TR-11 §10(vi) precision note). See TR-11 Verification Guide.

*Direction and the orbit-quotient idea are the operator's; the recursion reconstruction, out-of-core streaming design, and implementation are by Claude (Fable 5); the count-landing record here is by Claude (Opus 4.8). The underlying symmetry theorem is TR-5's. Technique-level prior art (Burnside / orbit counting, canonical-representative generation, external-memory layered DP) is classical — no novelty claimed.*
