# TR-8 dof-matched sampler — the pre-registered recorded run of 2026-10-03

This directory holds the files behind the NEW MEASUREMENT in
[TR-8](../../reports/TR8_REORDERING_REVISITED.md) v1.21 (§Executive summary, the dated insertion
after the CX-27 withdrawal marker) and [CORRECTIONS.md](../../documentation/CORRECTIONS.md) CX-293.
Every number that text quotes is in `TOKENS.txt` or `analysis_RECORDED.json` here, and every one of
them can be recomputed from the per-shard hit files in about two seconds (§Reproduce).

## What was run, and under what registration

- **Registration.** The pre-registration frozen 2026-08-11 (private; escrowed digest `4b307f07…`,
  66,659 bytes), read with its two dated addenda:
  [A1](../../documentation/PREREG_TR8_DOF_MATCHED_SAMPLER_20260811_ADDENDUM_A1_20261003.md)
  (instrument pin and every open parameter, published and escrowed before the run) and
  [A2](../../documentation/PREREG_TR8_DOF_MATCHED_SAMPLER_20260811_ADDENDUM_A2_20261003.md)
  (the admitted clause bank, committed privately after calibration and before the first pool draw).
  Both digests are on [PREREGISTRATION_ESCROW.md](../../documentation/PREREGISTRATION_ESCROW.md).
- **Instrument.** `solve.py --tr8-dof-sampler` at commit `35782834ea709969910419cce4e739da39dac19f`,
  solve.py sha256 `38f3f886dcfed34b36fe5be4de17b2ed5363c719a63d3bde634934738aa4b609`
  (`CODE_SHA`, `SOLVE_PY_SHA256`), CPython 3.12.3 (`PYTHON`).
- **Worker.** One Standard D16als_v7 (16 vCPU, `NPROC=16`), not Spot, so no eviction could
  interrupt a shard. The draws do not depend on the host.
- **Counts.** Seed root `ROAE-TR8-DOFMATCH-2026-08-11`; N_pool = 10,000,000 pair-only-null draws per
  pool in 8 shards of 1,250,000; N_pred = 1,000 predicates at each K in {8, 12, 16, 20, 24};
  N_calib = 100,000 (`N_POOL`, `SHARDS`, `N_PRED`, `K_LADDER`, `N_CALIB`). Every derived seed, as a
  decimal integer, is in `poolA/header.json` and `poolB/header.json`.
- **Wall times** (UTC, from the token log). Setup 09:59:59; bank 10:00:05 (`BANK_WALL_S=5`); A2
  committed privately 10:02:41; probe 10:03:41 (`PROBE_WALL_S=9.6`); pools 10:03:51, both pools as
  16 concurrent shard processes (`POOLS_WALL_S=219`; each shard 215–219 s); analysis 10:07:30.

## The result, by token

| token | value |
|---|---|
| `B_RAW` / `B_ADMITTED` | 319 / 242 |
| `GEOMEAN_ADMITTED_MARGINAL` | 0.446630 |
| `POOL_A_K16_X` · `POOL_A_K16_FHAT` · `POOL_A_K16_FCI` | 1000 · 1.0000 · 0.99632,1.00000 |
| `POOL_A_K16_MEDIAN` · `POOL_A_K16_MEDIAN_CI` · `POOL_A_K16_CENSORED_FRACTION` | 3.6000e-06 · 3.4000e-06,4.1000e-06 · 0.0020 |
| `POOL_B_K16_FHAT` · `POOLB_ABS_DIFF_F16` | 1.0000 · 0.0000 |
| `POOL_A_N_LE2` · `POOL_B_N_LE2` · band | 1047 · 1073 · [925, 1184] |
| `GATE_B_RAW_319` · `GATE_B_ADMITTED_GE_120` · `GATE_H_A` · `GATE_H_B` · `GATE_POOL_B_REPLICATION` | PASS · PASS · PASS · PASS · PASS |
| `OVERRIDE` | none |
| `CODE_GOVERNING_D1_K16` · `D2_K16` · `PREREG_S6_ROW` | COMMON · UNCENSORED · COMMON/UNCENSORED |
| `CODE_S6_OUTCOME` · `TR8_MEDIAN` | REFILLED · RESTORED |
| `CODE_VS_KIT_CHECKS` · `CODE_VS_KIT` | 69 · AGREE |
| `OLD_6E-5_FIGURE` | STAYS_WITHDRAWN |

All five K, pool A (`POOL_A_K<K>_FHAT`, `_MEDIAN`, `_CENSORED_FRACTION`): F̂ = 0.0000, 0.6370,
1.0000, 1.0000, 1.0000; m̂ = 1.8450e-03, 8.1400e-05, 3.6000e-06, 2.0000e-07 and, at K = 24, the bound
`<1.000e-07`; censored fractions 0, 0, 0.002, 0.237, 0.837. Their CIs, deciles, hit ranges, mean
pairwise clause overlaps and family compositions are in `analysis_RECORDED.json`.

**Which computation governs.** By A1 §A1.3(l), the governing verdict, gates and §6 outcome are the
public instrument's: the two `--tr8-dof-merge` commands below, whose `poolA/replication.json`
carries `governing_d1_k16` and `s6_outcome`. The `CODE_*` tokens are read from those outputs.
`analysis_RECORDED.json` and the other tokens come from a separate run kit, kept privately, that
re-derives every statistic, gate and verdict from the shard files and the frozen text.
`CODE_VS_KIT=AGREE` over 69 checks means the two agreed everywhere; any disagreement would have
voided the run.

## Reproduce

From the shipped hit files, about 2 s, run at the repository root:

```bash
python3 solve.py --tr8-dof-merge runs/20261003_tr8_dof_sampler_35782834/poolB
python3 solve.py --tr8-dof-merge runs/20261003_tr8_dof_sampler_35782834/poolA \
    --tr8-dof-replicate runs/20261003_tr8_dof_sampler_35782834/poolB
```

At commit `35782834` this rewrites `pool{A,B}/results.json` and `pool{A,B}/RESULTS.md` byte for byte
(checked 2026-10-03 against the worker's copies) and `poolA/replication.json`.

Redrawing the pools (each shard re-runs the 100,000-draw calibration first):

```bash
for I in 0 1 2 3 4 5 6 7; do python3 solve.py --tr8-dof-sampler OUT_A --tr8-dof-pool A --tr8-dof-shard $I; done
for I in 0 1 2 3 4 5 6 7; do python3 solve.py --tr8-dof-sampler OUT_B --tr8-dof-pool B --tr8-dof-shard $I; done
# then the two merges above, on OUT_B and OUT_A
```

Every other flag is at its default, and the defaults are the registered values (seed root, N_pool,
N_pred, the K ladder, 8 shards, N_calib). The run passed them explicitly, with the same values.

## Files, and what differs from the worker's copies

| file | what it is |
|---|---|
| `TOKENS.txt` | the run's whole token log, setup to analysis |
| `analysis_RECORDED.json` | the independent re-derivation, byte-identical to the worker's file |
| `pool{A,B}/header.json` | the run header: seed root, every derived seed, counts, bank digest, solve.py sha256 |
| `pool{A,B}/bank.json` | the admitted bank as measured on the calibration pool (the two are identical; sha256 `0189607d5b7a995c23752a86ae0976c2ad3a46773aa2d5172536918a66c0b9ea`) |
| `pool{A,B}/shard_*_I.json` | the per-predicate hit counts of each shard: the merge's only data input |
| `pool{A,B}/results.json`, `RESULTS.md` | the public merge's statistics, byte-identical to the worker's |
| `poolA/replication.json` | the public pool-B replication gate's output |

Three differences, all to paths, none to a value:

- **`TOKENS.txt`**: 8 lines (`KIT_WORK`, `PREREG_FILE`, `ANNOTATION_DRAFT`) carried the worker's
  home directory, which names operator-held infrastructure. That prefix is replaced by `~/`;
  nothing else in the file is changed.
- **`poolA/replication.json`** is the copy the first command above wrote here from the shipped
  files. It differs from the worker's copy only in `pool_a_dir` and `pool_b_dir`, which hold the
  directory each was run in.
- **Not shipped:** the per-shard environment files and logs (Python version, shard index and wall time; the host name does appear once, as `HOST=`, in TOKENS.txt), the
  merge's console output, and the run kit. None holds a number the text quotes.

| sha256 | file |
|---|---|
| `3f216837db281fe41127c1352d9263342100634d6f9091ca6af3c41eca5be4a5` | `TOKENS.txt` |
| `b38805a0dbb000e44c582c8eed4946dcf68abb2078cd1d91fb61db591eee1cf6` | `analysis_RECORDED.json` |
| `613225481b3f26a25d11879cb5783e4809271a4bf64da6897e66c27f18126f44` | `poolA/header.json` |
| `ce2e28a566967f373f5b0a58f6c9737882227081147193a30091f977df360b08` | `poolB/header.json` |
| `93c1a4a521893ac0de5bac694357758b22e2d60b7ca2cc94bce679d05820ca22` | `poolA/results.json` |
| `ee5c8a361ba04d5dbf9512f07c8baa0473b1271d5a9dfe3d81380736e735ce2a` | `poolB/results.json` |
| `1da7c06b2b604d44ce639590ddd5a086d5fca54f269e21d40f43774514d30d4a` | `poolA/replication.json` |

## What this run does not do

It does not reinstate the withdrawn median figure: that stays withdrawn permanently, whatever this
run found. The statement is about this reference class only, a modelling choice. Its CIs are
conditional on the shared pool, and pool B is the pre-registered check on that, not a full error
model. No other figure, count, certificate or sha in the suite moves.
