# Knuth estimator validation ladder — fresh draw with a recorded thread count (2026-09-25)

**What this is.** TR-4 §2 and SEARCH_SPACE_SIZE.md §"Validation — the estimator is correct" compare the Knuth estimator with
exact subtree counts on three King Wen-following prefixes, at 5, 7 and 9 free positions. The exact
counts reproduce from `./solve --estimate-knuth 0 <prefix>` and from `python3 verify.py
--recount-subtree`. The published Monte-Carlo column (442.9 / 62,257 / 9,424,649 nodes; 4.01 /
2,233 / 16,422 leaves) has no recorded probe count or thread count, so it cannot be reproduced as
a draw. This directory archives a fresh draw with both recorded. It does not reproduce the
published column's digits, and does not claim to (Codex v3 review, V3B-07#4).

A grid of 30 settings on the 5-free rung (10⁶, 10⁷ and 10⁸ probes at 1, 2, 4, 8, 16, 32, 48,
64, 96 and 128 threads) found several that round to the published 442.9 / 4.01, so the original
setting cannot be identified from the published digits.

## Prefixes

The prefix for n free positions is King Wen's pairs 1 to 31 − n, each at orientation 0 (pair 0 is
the pinned opening pair and is not passed). 5-free passes 26 pairs, 7-free 24, 9-free 22.

## Reproduce

The estimator needs a stack limit of at least 16 MB (`ulimit -s 16384` suffices).

```bash
gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz
ulimit -s 16384
for f in 5 7 9; do
  P=$(for i in $(seq 1 $((31 - f))); do printf '%d 0 ' $i; done)
  SOLVE_THREADS=16 ./solve --estimate-knuth 0 $P        > ladder_${f}free_exact.out 2>&1
  SOLVE_THREADS=16 ./solve --estimate-knuth 10000000 $P > ladder_${f}free_1e7_t16.out 2>&1
done
```

The thread count selects the sample, so these digits reproduce only at 10⁷ probes and 16 threads,
on a binary built from the same `solve.c`; a re-run matched every line except the `wall_s=` field. The exact files do not depend on the thread count.

## Result

| free positions | exact nodes | draw nodes | exact oriented leaves | draw oriented leaves |
|---:|---:|---:|---:|---:|
| 5 | 443 | 443.16 | 4 | 4.00 |
| 7 | 62,256 | 62,242.9 | 2,232 | 2,222.7 |
| 9 | 9,422,793 | 9,422,281 | 16,504 | 16,548 |

Every draw value is within 1% of its exact value (largest gap: 7-free leaves, 0.42%).

## Provenance

Run 2026-09-25 on a 16-core x86-64 Linux worker; gcc 13.3.0, flags as above. `solve.c` sha256
`950525812ffb9af71806c4d46ee02ec9553b0e03f4918f61414dccaeeaf5e7fe`. Wall time about 1 to 3 s per
sampled rung. The files are the unedited stdout and stderr of the commands above.
