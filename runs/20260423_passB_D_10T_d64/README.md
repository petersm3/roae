# 20260423 Pass B + Pass D — 1T per-branch on 64-core VMs

**Date:** 2026-04-23
**Hardware:** 2 × 64-core Spot VMs
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

The corresponding `sub_<prefix>.bin` files (155 MB – 624 MB each) are not in this git repo; they are archived on the data disk at `/data/20260423_passBD/`. *(Note 2026-10-02, Q-943: in every `sub_*.meta.json` here, `c3_valid_records` is a round number of millions, such as `482000000`. It was copied from the run log's final summary line, which prints the C3 count in millions ("482M C3" in `B_20_0_21_0_26_1/run.log.gz`), so it carries only that precision and is not an exact count. The exact fields are `solutions_canonical`, `dedup_collisions`, `actual_nodes` and the file size and sha. The meta files are kept as written.)* *(2026-11-15: three location fields in each meta file are now redacted; see the redaction note at the end.)*

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

## Redaction note (2026-11-15)

In each of the 14 `sub_*.meta.json` files below, three values were redacted in place (backlog Q-1140, cloud-sweep batch B8, under the operator's 2026-11-14 rule that public text names no machine size, region or resource name; in-place redaction as in CX-239 part 4, with the CX-36B-C placeholder forms from Codex findings F10-001#3, F10-002#4 and F10-003#3, gpt-6-astra): `vm_sku` reads `"[cloud detail redacted] spot"`, `vm_region` reads `"[cloud detail redacted]"`, and the disk name at the start of `archive_location` reads `<data-disk>`. Each file is still valid JSON with the same keys and line count; no other byte changed, and no record count, wall time or sha256 of a `sub_*.bin` changed.

| file | sha256 before the redaction | sha256 after |
|---|---|---|
| `B_20_0_21_0_26_1/sub_20_0_21_0_26_1.meta.json` | `8fb2b666e1f4d8114c9d47bc0a880ef657248b0729fb70272c9acc606ad7827b` | `a4bb993e88ed91992bcc83e12d00195db460c7b8c91dd65a2bd3318356b4fcb9` |
| `B_20_0_21_1_26_0/sub_20_0_21_1_26_0.meta.json` | `5d895275a46f3b6a9dc30ffb60013b02876725521616d64df9cd3582141145e7` | `3a87d47eae7a6cf0fb27fe54e8b2126c7d43569b04ced95f48459f8523d620e2` |
| `B_20_1_21_0_26_1/sub_20_1_21_0_26_1.meta.json` | `0cc08230f399e293e1c0b27c43dafcecd77079a23150f8d467932e34142bd828` | `d59a35806c030bdb36992bb1ba66f42c5dfeae3232ee0954516d99be79cc917f` |
| `B_20_1_21_1_26_0/sub_20_1_21_1_26_0.meta.json` | `d6e575dd5fbbd685f7eeb3a118919f66c78963bd2bcbb900b8a1bc2ecba698cb` | `95aeef0f6014f2d8146367269facce613119df730235fd4bdc9b7f3b8145d58b` |
| `D_10_0_6_1_2_0/sub_10_0_6_1_2_0.meta.json` | `2b8d63f4f6e06e6ecfd66486163ccb6236edb7448fb6b7a3533f42b088d453a5` | `12c1c698525e2738b6b9ebf2ac3fd3c4e4756c2700cc7dfd7187a45759ab52d4` |
| `D_11_0_6_1_2_1/sub_11_0_6_1_2_1.meta.json` | `643c8fa23c8b616266932f099faee6631672f393edbef83ae84623f8b801ec3a` | `2478ca40287700f7366ca82d4047a394951dae1b428b508892c9b39e428c5c27` |
| `D_12_0_2_0_8_1/sub_12_0_2_0_8_1.meta.json` | `64ba9eb2d3fe0921dca010b5836345f4ae28973f2261c563ade0d2bef9dede3c` | `c33079b0f22c71edd1d8fa51a02832e2129181050fae6cd33c07bbf6bc98f753` |
| `D_13_0_19_0_8_1/sub_13_0_19_0_8_1.meta.json` | `2a5e1f3a2c68329e10f4f72135ecce8af15adc1243a924fe4fc7800ab88575d4` | `8d2c71daa5a29d385253f12f3f0e10a9f8a5d38a3e2aa764989e6d4c22c76c1b` |
| `D_14_0_18_0_8_0/sub_14_0_18_0_8_0.meta.json` | `01e4125fec568b2856a245a2f1e9f2bbe2590304de313539ba3877ee4a76e362` | `17507b063065e686022495d12953029e835c213b3e22ef90af071d0dd1c50a54` |
| `D_1_0_6_1_12_0/sub_1_0_6_1_12_0.meta.json` | `d3b6f78302f1619a4a6b8397fbabf77751c75a3391c54cbff7530ceb5a554f15` | `7f230e6256d669b9c496f964bd6332f9937dc8ffe635cc71ba9c005ea7fc4c75` |
| `D_2_0_6_1_10_1/sub_2_0_6_1_10_1.meta.json` | `bb98f4d8ed0b995c8d8cfdc6122de283b5ce2e58dd5ab1720502a540ea7c3dd8` | `4df6924cc96882c0f6bb42f838d2276e7daf94d2336fd3817f4dad378bde89c1` |
| `D_3_0_4_0_12_0/sub_3_0_4_0_12_0.meta.json` | `e165aba509374eb5d74cb1475fb41dc34cf17b87c4ba9b0181026f412c66fb7a` | `e636254514d55d73104fc6632b9f62f9a8527fe9387b088db78d6c8653cf5826` |
| `D_7_0_4_0_19_1/sub_7_0_4_0_19_1.meta.json` | `a36ced234fba2fb1abc7c33e1436d67bece97b6336f8844942947ccbad126c56` | `0721c1dd5e4fc2441ba67871efc85afb34ca4b439a3a335cc6d358b1e8a2af1f` |
| `D_8_0_2_0_12_0/sub_8_0_2_0_12_0.meta.json` | `43cb4b4b6314f90f77cd81e370eaa371d3729c8769054647ab514038d3d0710b` | `a604bea162330dd24b7d4ffb59028b1f61ffbfa2d1253169bf2ba5c392f4f303` |
