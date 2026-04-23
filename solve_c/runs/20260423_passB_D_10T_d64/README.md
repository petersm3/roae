# 20260423 Pass B + Pass D — 1T per-branch on D64als_v7 (westus3)

**Date:** 2026-04-23
**Hardware:** 2 × Standard_D64als_v7 spot VMs (westus3)
**Budget:** 1T (1,000,000,000,000) node cap per branch
**Total runs:** 14 (4 Campaign B + 10 Campaign D)

## Campaign B — orientation symmetry test

Target: measure yield for all four `(o1, o2, o3)` flips of prefix `(20, 21, 26)` to test whether orientation-flip preserves canonical solution count.

| Branch | Yield | Size (bytes) | SHA-256 (trunc) | Wall (s) |
|---|---:|---:|---|---:|
| `20_0_21_0_26_1` | 4,845,906 | 155,068,992 | `c7c60daa...` | 1,021 |
| `20_0_21_1_26_0` | 4,868,087 | 155,778,784 | `18e9cbc6...` | 1,018 |
| `20_1_21_0_26_1` | 4,885,209 | 156,326,688 | `b551f30c...` | 1,042 |
| `20_1_21_1_26_0` | 4,788,353 | 153,227,296 | `6fa65dcc...` | 1,013 |

Spread: 96,856 sols / 4,846,889 avg = **2.0%**. All four BUDGETED at 1T.

## Campaign D — yield-1,116 calibration (D[1..10])

Target: 10 branches that all reported yield = 1,116 at the 100T aggregate run. At 1T each, yields now span 2.8× — evidence of heavy super-linear growth in this class.

| D[i] | Branch | Yield | Size (bytes) | SHA-256 (trunc) | Wall (s) |
|---:|---|---:|---:|---|---:|
| 1 | `1_0_6_1_12_0` | 8,241,253 | 263,720,096 | `06f288b9...` | 1,036 |
| 2 | `2_0_6_1_10_1` | 11,906,095 | 380,995,040 | `9bea8e31...` | 1,024 |
| 3 | `3_0_4_0_12_0` | 7,053,537 | 225,713,184 | `c23f8084...` | 1,013 |
| 4 | `7_0_4_0_19_1` | 18,850,725 | 603,223,200 | `614cb7c9...` | 1,028 |
| 5 | `8_0_2_0_12_0` | 16,308,888 | 521,884,416 | `bd9450c7...` | 1,024 |
| 6 | `10_0_6_1_2_0` | 11,859,058 | 379,489,856 | `4ed5a369...` | ~1,040 |
| 7 | `11_0_6_1_2_1` | 12,597,859 | 403,131,488 | `82e1453a...` | ~1,040 |
| 8 | `12_0_2_0_8_1` | 7,839,995 | 250,879,840 | `9c3e6505...` | ~1,040 |
| 9 | `13_0_19_0_8_1` | 19,504,081 | 624,130,592 | `c60c0d64...` | ~1,500 |
| 10 | `14_0_18_0_8_0` | 11,402,977 | 364,895,264 | `973fc2bc...` | ~1,040 |

All 10 BUDGETED. Yield range 7.05M – 19.50M sols. Growth factor from 100T yield (1,116) to 1T yield is **6,319× – 17,476×** — confirms these "low-yield" branches are very far from exhaustion at the budgets tried so far.

## Layout per branch

```
B_<prefix>/
├── sub_<prefix>.meta.json    # full run metadata (sha, size, nodes, timing)
├── sub_<prefix>.sha256       # sha256 of the .bin (not in this repo)
└── run.log.gz                # solver stderr log, gzipped
```

The corresponding `sub_<prefix>.bin` files (155 MB – 624 MB each) are not in this git repo; they are archived on `solver-data-westus3:/data/20260423_passBD/`.

## Reproduction

Each branch was run as:

```
SOLVE_NODE_LIMIT=1000000000000 SOLVE_THREADS=64 SOLVE_CKPT_INTERVAL=120 \
    solve --sub-branch <prefix>
```

Solver build: Apr 23 2026 01:04:34 UTC (HEAD-of-main at run time).

## Operational note

D[6..10] were run on bcd-runs-2 in parallel with bcd-runs' queue to halve
wall-time. A guard script on bcd-runs killed its runner after D[5] so the
two VMs would not do duplicate work. Implementation lesson: the guard's
`pkill` raced with the bash for-loop's next iteration — the D[6] solve
was forked briefly before the kill propagated. Caught at +7s and
terminated manually; partial dir removed.
