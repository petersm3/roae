# 20260423 Pass B + Pass D — 1T per-branch on D64als_v7 (westus3)

**Date:** 2026-04-23
**Hardware:** 2 × Standard_D64als_v7 spot VMs (westus3)
**Budget:** 1T (1,000,000,000,000) node cap per branch *(Note 2026-10-02, Q-943: the directory name says `10T`, but every one of the 14 runs here had this 1T budget, as each `sub_*.meta.json` records in `budget_nodes`. The name is kept because other files link to this path.)*
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

All 10 BUDGETED. Yield range 7.05M – 19.50M sols. Growth factor from 100T yield (1,116) to 1T yield is **6,320× – 17,476×** — confirms these "low-yield" branches are very far from exhaustion at the budgets tried so far.

## Layout per branch

```
B_<prefix>/
├── sub_<prefix>.meta.json    # full run metadata (sha, size, nodes, timing)
├── sub_<prefix>.sha256       # sha256 of the .bin (not in this repo)
└── run.log.gz                # solver stderr log, gzipped
```

The corresponding `sub_<prefix>.bin` files (155 MB – 624 MB each) are not in this git repo; they are archived on `solver-data-westus3:/data/20260423_passBD/`. *(Note 2026-10-02, Q-943: in every `sub_*.meta.json` here, `c3_valid_records` is a round number of millions, such as `482000000`. It was copied from the run log's final summary line, which prints the C3 count in millions ("482M C3" in `B_20_0_21_0_26_1/run.log.gz`), so it carries only that precision and is not an exact count. The exact fields are `solutions_canonical`, `dedup_collisions`, `actual_nodes` and the file size and sha. The meta files are kept as written.)*

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

## Dated notes (2026-10-22)

Added from Codex's final review (gpt-6-astra); the record above is kept as written. [CORRECTIONS.md](../../documentation/CORRECTIONS.md) CX-35X-K.

- **"Evidence of heavy super-linear growth".** The 2.8× is the spread between ten different branches at one 1T budget, not growth with budget, and the 100T-aggregate yield it is set against came from a different traversal (one depth-3 cell walked within the aggregate budget, against 64 workers on depth-5 tasks here). [HISTORY.md](../../documentation/HISTORY.md) fits this cohort's growth as sub-linear. Read the sentence as a between-branch spread (Codex F07-010#3, F12-020#5).
- **Wall times.** Eight exact wall-time cells differ by 1–4 s from their `sub_*.meta.json` `wall_seconds` (B 20_0_21_1_26_0 1,016; B 20_1_21_0_26_1 1,040; B 20_1_21_1_26_0 1,012; D[1] 1,034; D[2] 1,021; D[3] 1,012; D[4] 1,024; D[5] 1,020); the meta files are the record (F07-010#14).
- **Reproduction.** `solve --sub-branch` takes six integer arguments, not the underscore-joined prefix: branch `20_0_21_0_26_1` runs as `solve --sub-branch 20 0 21 0 26 1` (F12-020#7).
- **Dedup collision counts.** The parallel `--sub-branch` summary line (`… dedup collisions) ***`) added worker 0's `hash_collisions` a second time after summing every worker, so each archived log's collision figure overstates by worker 0's own count; no record count or sha is affected. The engine counts it once since push group G6 ([CORRECTIONS.md](../../documentation/CORRECTIONS.md) CX-35X-B; Codex F04-003#21).
