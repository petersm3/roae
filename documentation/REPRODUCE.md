# REPRODUCE.md: rebuild the small exact catalogs and check that you got the same bytes

*This page lets you check the counting engine yourself, without downloading a dataset from us. Each
row below gives a command to run and a hash to compare. It covers the **small rungs only** (n ≤ 19).
It does **not** reproduce the headline full-31 results; see
[What this does NOT reproduce](#what-this-does-not-reproduce).*

## The short version

```bash
gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz
SOLVE_F1_KEEP_LAYERS=1 ./solve --f1-exact-c1c2c4c5 --f1-pairs 13 --layers-dir out13
(cd out13 && find . -name '*.bin' | sort | xargs sha256sum | sha256sum)
```

If the last line prints the `n=13` digest from the ledger below, your machine and ours wrote
**byte-identical layer files**, and you downloaded nothing from us to show it. The run also prints
`orbit-quotient C5-DP total = 2063395607040`, the n=13 total published in
[TR-11 §4b](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md).

## What `--f1-pairs n` means

The 64 hexagrams form **32 pairs**. C4 pins one pair, which leaves **31 free**. `--f1-pairs n`
restricts the computation to a **group-closed union of whole symmetry orbits** that together hold
`n` pairs. The 31 free pairs split into orbits of sizes `3,3,3,4,6,6,6`, so the valid `n` are the
subset sums of those sizes: **3, 4, 6, 7, 9, 10, 12, 13, 15, 16, 18, 19, 21, 22, 24, 25, 27, 28,
31**. Any other value is rejected. For example, `--f1-pairs 20` prints `has no group-closed orbit
union` and lists the supported sizes. Several different unions can have the same size, and
`--f1-pairs` picks one of them per size. The full list is in
[SOLVE_C_CLI.md](SOLVE_C_CLI.md) §`--f1-exact-c1c2c4c5`.

🔴 **The rungs are not nested, and none is a prefix of another.** Each rung uses a different
combination of orbits and derives its own C5 budget `B0` from its own pairs. The solver prints
these on every run, and they match TR-11 §4b:

```
n=9   [3,7,11 | 4,6,21 | 13,14,30]                     B0 = (2,5,0,2,0)
n=13  [3,7,11 | 5,8,26,31 | 10,15,20,23,27,29]         B0 = (1,6,0,6,0)
n=16  [5,8,26,31 | 1,9,17,19,22,25 | 2,12,16,18,24,28] B0 = (1,8,1,6,0)
```

n=9 and n=13 share one orbit. **n=16 shares none with n=9.** So the rungs are the same engine run
on several independently chosen sub-problems, not one problem at increasing depth. Agreement across
unrelated cases is stronger evidence than agreement across nested ones.

## The ledger: Stage F layer files (the f-ladder) at n ≤ 19

Command for every row: `SOLVE_F1_KEEP_LAYERS=1 ./solve --f1-exact-c1c2c4c5 --f1-pairs N --layers-dir outN`.
The digest is `(cd outN && find . -name '*.bin' | sort | xargs sha256sum | sha256sum)`.

| n | wall | peak RSS | `*.bin` bytes | `*.bin` files | printed total (= TR-11 §4b) | `*.bin` digest (sha256) |
|--:|--:|--:|--:|--:|--:|---|
| 9 | 0.42 s | 13,228 KiB | 28,840 | 10 | 26,112 | `31f99b4e8ed68271715c5ceb56d38995906ea388b24f0e022c948c557654f3d5` |
| 13 | 0.69 s | 16,332 KiB | 1,142,284 | 14 | 2,063,395,607,040 | `40387eed07b11319ba3943fca64ab94a7e19c6acfb56d2b42ce86e6ac0625c4e` |
| 16 | 0.91 s | 23,820 KiB | 11,722,892 | 17 | 267,765,117,419,520 | `fa2ae688058e5e6ef923f9eae93cbbfddde413ba05859460375069aaab3b4713` |
| 18 | 0.97 s | 25,880 KiB | 16,287,444 | 19 | 3,211,799,156,883,456 | `8c32651484dd35c2b1ca8e3a119b6237c157078917152238ad502f6a8d182134` |
| 19 | 1.36 s | 52,176 KiB | 88,311,188 | 20 | 63,244,766,587,981,824 | `87794ac8eb534b4c5c875212faa43033f8a8443b28c9211c835180e02c5b5b70` |

The five rows together take **under 5 seconds and under 60 MB of RAM** (measured on the host
described below). Wall time and RSS depend on your machine. The byte counts, file counts, totals
and digests should not.

These digests were first measured on 2026-08-25. They were re-measured on 2026-09-24 against a
fresh build of the current `solve.c`, and all five matched. The same
run also confirmed three properties of the recipe:

- **Deterministic.** A second n=13 run into a different directory gave the same digest.
- **Tamper-evident.** Changing one byte of one n=13 layer file changed the digest.
- **Sensitive to the settings.** Leaving out `SOLVE_F1_KEEP_LAYERS=1` gave a different digest (see
  failure mode 1 below).

**A second, independent instrument.** `verify.py` does not share code with `solve.c`. It recounts
these rungs by a different derivation (see [VERIFY.md](VERIFY.md)):

| command | what it checks | measured |
|---|---|---|
| `python3 verify.py --recount` | the n = 9/13/16 rung totals, and more | `RECOUNT_RESULT=PASS`, 106 s, ~0.9 GB |
| `python3 verify.py --recount-rung 18` | the rung-18 count, with `B0` re-derived | `[MATCH]`, 167 s, ~0.9 GB |
| `python3 verify.py --recount-rung 19` | the rung-19 count, with `B0` re-derived | `[MATCH]`, 573 s, ~3.2 GB |
| `python3 verify.py --recount-rung-layers 13` | every n=13 per-layer mass, checked against [FULL31_EXACT_AGGREGATES.md](../reports/FULL31_EXACT_AGGREGATES.md) §2 | `all 13 layer masses MATCH`, 3.5 s |

`--recount` also prints `n/a` for six larger published rows (n = 18, 19, 24, 25, 27, 28) that it does not recount inside one run. n = 18 and 19 are covered by the `--recount-rung` rows above; n = 24, 25, 27 and 28 are **not** checked by this page.

## g and t at the same rung

`--kc-g-build GDIR --f1-pairs N` builds the **g** ladder at rung `N`. **Pass `--f1-pairs`
explicitly.** Without it, `--kc-g-build` builds n=9, whatever f-ladder you intended to pair it
with (see [TR-12](../reports/TR12_QUERY_PROGRAM.md) §R Stage G). `--kc-t-build FDIR TDIR` builds
**t** from an existing f-ladder. Measured at n=13:

```bash
./solve --kc-g-build g13 --f1-pairs 13     # prints g0=2063395607040   (0.27 s)
./solve --kc-t-build out13 t13             # prints t_root=5163044120623 (0.30 s)
./solve --kc-build kc13 --f1-pairs 13 && ./solve --kc-count kc13   # KC COUNT n=13 = 2063395607040
```

| directory | `du -sb` (all files) | `*.bin` only |
|---|--:|--:|
| f (`out13`) | — | 1,142,284 |
| g (`g13`) | 1,711,922 | 1,361,524 |
| t (`t13`) | 1,613,364 | 1,142,284 |

The g root, `g0`, equals the n=13 total printed by the f run. At n=31 the full form of this
check is the f·g cut identity, which `./solve --kc-g-check FDIR GDIR` prints at every layer.

**These small-rung size ratios do not predict n=31 sizes.** Use the measured full-31 sizes in
[What this does NOT reproduce](#what-this-does-not-reproduce).

## How far a reviewer can realistically go

The **f-ladder at n=21** measured **430,629,560 bytes** of `*.bin` in 22 files, 4.6 s, and 170,928 KiB
peak RSS on the same host. We publish **no digest** for any rung between 21 and 28. The middle
rungs are too large for a quick check, and they tell you nothing the small rungs do not. Either you
are checking the engine, in which case use n ≤ 19, or you are running the real computation, which
is n=31.

## 🔴 Three mistakes that would make you think we are wrong

**1. `SOLVE_F1_KEEP_LAYERS=1` is required.** Without it the engine keeps only a rolling two-layer
window. At n=13 you get **2** `*.bin` files instead of 14, and a different digest. The difference
comes from the missing variable, not from the data. See the `SOLVE_F1_KEEP_LAYERS` row of the
environment-variable table in [SOLVE_C_CLI.md](SOLVE_C_CLI.md).

**2. Hash `*.bin` only, never the whole directory.** The run also writes `f1c5_progress.json` and
`f1c5_layer_stats_NN.json`. Their contents legitimately differ from run to run. Two n=13 runs with
identical `*.bin` files differed in all 15 of those files, while `f1c5_manifest.txt` was identical.
**The `-name '*.bin'` filter matters; do not remove it.**

**3. Hash from inside the directory, and sort.** `sha256sum` writes each file's path into its output,
so the outer hash includes the path. `find out13 …` run from outside the directory gives
a different digest for identical bytes: measured, `out13/` and `rep13/` gave different digests even
though every `*.bin` file was byte-identical. The `(cd outN && find . …)` form hashes the same
`./f1c5_layer_NN.bin` names on every machine. `find` also returns files in filesystem order, which
varies, so keep the `| sort`.

For one layer at a time, `./solve --f1c5-layer-sha outN` prints the sha256 of each layer's
decompressed stream. This per-layer instrument is the one the n=31 layer registry uses
(`runs/20260906_kc_ladders_n31/STAGE_F_LAYERSHA.txt`). It hashes content rather than file bytes,
so it does not produce the directory digests in the ledger above.

## Environment these figures came from

| | |
|---|---|
| source | `solve.c` as shipped in the commit that carries this page; the digests above were re-measured against it on 2026-09-25 (build line below) |
| compiler | `gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0` |
| build line | `gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz` (12 s) |
| host | 8 vCPU, 15 GB RAM, Linux x86-64 |
| sanity | `./solve --selftest` → `PASS — sha256 matches canonical baseline` (`403f7202…`, see [CANONICAL_HASHES.md](CANONICAL_HASHES.md)) |

⚠ The hash of the **binary** depends on your compiler, and it will differ. The claim is the
**`*.bin` digests**, which should match across compilers. *If they do not match, that is a finding,
and we want to hear about it.*

## What this does NOT reproduce

🔴 **None of the headline figures in this suite comes from anything on this page.**

The full computation is **n=31, which is Stage F**. It is the same `--f1-exact-c1c2c4c5` command
with no `--f1-pairs` flag, run out of core. It is a multi-day, multi-terabyte build (the commands
are in [TR-12](../reports/TR12_QUERY_PROGRAM.md) §R). The three full-31 ladders, as measured and
published in TR-12's provisioning table:

| ladder | measured size |
|---|--:|
| f | 3.29 TB |
| g | 8.27 TB |
| t | 3.48 TB |
| **total** | **15.05 TB** |

The three rows were measured on different bases, which TR-12 names. The total is not
distributable.

For scale, all 20 `*.bin` files of the n=19 f-ladder (88,311,188 bytes) are about **0.003 %** of the
n=31 f-ladder. Even n=21's 430.6 MB is about 0.013 %. Every rung on this page, taken together, is
tiny next to the real object. It gives you **the same engine, run end to end, on questions small
enough to check exactly**, not the full-31 answer.

**The expensive part to reproduce is the proofs, not these catalogs.**
`reports/certificates/verify_all.sh` needs **≥ 12 GB of free RAM**. The Lean phase peaks at about
9.6 GB on `Automorphism.lean`. A cold external-reviewer pass on a 4 GB host hit `ERROR 134` on all
13 Lean files. The script's own header gives the requirements, and
[lean/README.md](../lean/README.md) gives the measured per-file table.
