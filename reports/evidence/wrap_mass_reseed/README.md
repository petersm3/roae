# Wrap-distance mass — two independent-seed replicates at 2×10¹⁰ probes (2026-09-04)

**What this is.** The measurement half of `PROSE_LANE_FOLLOWUPS` V2-F09 #2. TR-7 published the
full-space wrap-distance masses **17.5 / 65.2 / 17.4 %** with **no uncertainty**, because the two
archived artifacts (`evidence/r6/rc1c_primary.out`, 64 threads; `evidence/f11/f11_runA.out`,
32 threads) both ran on the fixed base seed `0x243F6A8885A308D3`, carry no `SEED OVERRIDE` line, and
seed worker *i* as `base ^ ((i+1)·0x9E3779B97F4A7C15)` **by thread index alone** — so the 32-thread
and 64-thread runs replay the same first 312.5×10⁶ draws on each of threads 0–31, i.e.
**10×10⁹ of each run's 20×10⁹ probes are literally the same probes**. Their agreement was arithmetic,
not evidence.

These two runs differ **only** in `SOLVE_KNUTH_SEED` (same binary, same 2×10¹⁰ probes, same 128
threads), which is the convention used by `evidence/q374_se_replicates/`. Every worker seed differs,
so they are genuine independent draws.

## Seeds (explicit)

| replicate | `SOLVE_KNUTH_SEED` | `SEED OVERRIDE` base | probes | threads | wall |
|---|---|---|---:|---:|---:|
| wrap_reseed_seed20260904.out | `20260904` | `0x0000000001352828` | 20,000,000,000 | 128 | 2159 s |
| wrap_reseed_seed20260905.out | `20260905` | `0x0000000001352829` | 20,000,000,000 | 128 | 2162 s |

The two bases differ, which is what `scripts/doc_gates.sh seed-provenance` (GATE 51) requires
before any prose may claim independent draws: it maps each evidence file to the base in its
`SEED OVERRIDE ACTIVE: base=` line and needs **≥ 2 distinct bases** among the cited files.
An artifact with no such line contributes nothing to that count, which is why the archived
`r6`/`f11` pair could not satisfy it.

## Result — the `se=` TR-7 records as missing

| class | replicate A (seed 20260904) | replicate B (seed 20260905) | mean | |A−B| |
|---|---|---|---:|---:|
| d=1 | 17.4533 % ± 0.0109 pp | 17.4761 % ± 0.0109 pp | 17.4647 % | 0.0228 pp |
| d=3 | 65.1502 % ± 0.0135 pp | 65.1506 % ± 0.0135 pp | 65.1504 % | 0.0004 pp |
| d=5 | 17.3966 % ± 0.0109 pp | 17.3733 % ± 0.0109 pp | 17.3849 % | 0.0233 pp |

**Between-replicate check.** For two independent estimates of equal precision the difference
has SE = `se·√2`, so the standardised gaps are:

| class | |A−B| | `se·√2` | gap in σ |
|---|---:|---:|---:|
| d=1 | 0.0228 pp | 0.0154 pp | **1.48 σ** |
| d=3 | 0.0004 pp | 0.0191 pp | **0.02 σ** |
| d=5 | 0.0233 pp | 0.0154 pp | **1.51 σ** |

The printed `se` is a delta-method standard error; `evidence/q374_se_replicates/` already validated
it against the between-replicate scatter of 12 seeds (SE/SD inside the χ²₁₁ band [0.71, 1.70]).
These two replicates are a second, independent check of the same field at a 2000× larger probe
budget.

## Reproduce

⚠ The estimator needs a stack limit of **at least 16 MB** (`ulimit -s 16384` suffices;
`ulimit -s unlimited` is one sufficient setting). Below that it refuses to start and exits 1.

Thread count is part of the sample (per-worker seed = `base ^ ((i+1)·0x9E3779B97F4A7C15)`), so a
re-run reproduces these figures only at the identical (probes, threads, seed) triple and binary.

```bash
gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz
ulimit -s unlimited
SOLVE_KNUTH_SCORE=1 SOLVE_THREADS=128 SOLVE_KNUTH_SEED=20260904 \
  ./solve --estimate-knuth 20000000000 > wrap_reseed_seed20260904.out 2>&1
SOLVE_KNUTH_SCORE=1 SOLVE_THREADS=128 SOLVE_KNUTH_SEED=20260905 \
  ./solve --estimate-knuth 20000000000 > wrap_reseed_seed20260905.out 2>&1
```

Both streams are captured: `SEED OVERRIDE` is written to **stderr** and the `se=` lines to stdout,
so `2>&1` is required or the artifact loses its seed provenance.

## Build provenance

| | |
|---|---|
| `solve.c` | built from `main` @ `3515441c`, clean tree; sha256 `2d45f5791390feb1cbd70063399f54a5d11cb222d8a792e3d22ec92021934a48` |
| binary | sha256 `33cc19588954cba0e1ce7cb235d9e5578557c8d40d3980a38c766a76f8ae7799` |
| compiler | `gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0`, flags `-O3 -pthread -fopenmp … -lm -lz` |
| host | Azure `Standard_D128als_v7` Spot, westus3; AMD EPYC 9V45, 128 cores, 251 GB; Linux 6.17.0-1022-azure x86-64 |

Output is byte-identical only at the identical (probes, threads, seed) triple **and** binary; a
different host or compiler may differ in the last digits.

## Artifact digests

- `wrap_reseed_seed20260904.out` — sha256 `bac756b4423b1b5f567e1507f5e6b317a67793aaaf254461f8ce4f606a9dcdba`
- `wrap_reseed_seed20260905.out` — sha256 `584cbdd81de1bc182410d6f4229ccadd0c7be7870d4a6bfb4afea928b0e1f679`

⚠ `main` advanced to `237abb2f` while these runs were in flight (an unrelated licensing/example
commit). **`solve.c` is byte-identical across that commit** — `git diff 3515441c 237abb2f -- solve.c`
is empty and the sha256 above still matches the working tree — so the build pin is unaffected. The
sha256, not the commit id, is the authoritative pin here.
