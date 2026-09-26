# King Wen is the first leaf its cell's DFS reaches (2026-09-25)

**What this is.** TR-4 §6 says King Wen's early appearance in the enumeration is produced by the
search setup, including a value ordering that puts King Wen's one leaf early in its cell. Codex v3
review, V3B-07#25, found no cell, rank or trace published for that. This directory supplies them.

**Why it holds.** `init_pairs()` in `solve.c` numbers the 32 pairs in King Wen order
(`pairs[p] = (KW[2p], KW[2p+1])`), and `backtrack()` (and `backtrack_iterative()`) try pairs in
ascending index with orientation 0 before orientation 1. King Wen is pair indices 0, 1, …, 31, all at
orientation 0, so it is the leftmost root-to-leaf path of the tree. Its depth-3 cell is pairs 1, 2
and 3 at orientation 0, and it is the first leaf that cell's DFS reaches.

## Reproduce

```bash
gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz
SOLVE_PER_SUB_BRANCH_LIMIT=29 ./solve --sub-branch 1 0 2 0 3 0 0 1 > kw_first_leaf_limit29.out 2>&1
SOLVE_PER_SUB_BRANCH_LIMIT=30 ./solve --sub-branch 1 0 2 0 3 0 0 1 > kw_first_leaf_limit30.out 2>&1
```

The trailing `0 1` are the time limit (none) and the thread count (one). Setting
`SOLVE_PER_SUB_BRANCH_LIMIT` also suppresses the sub-canonical-budget gate (the binary says so in its own warning text). Each run writes
`sub_1_0_2_0_3_0.bin`, `solutions_1_0.bin` and sidecar files into the working directory and
allocates a 512 MB hash table; run it in a scratch directory.

## Result

| budget | `Total solutions (C1+C2+C4+C5)` | `C3-valid solutions` | `King Wen found` |
|---:|---:|---:|---|
| 29 | 0 | 0 | No |
| 30 | 1 | 1 | YES |

At a budget of 30 the cell has produced exactly one leaf, and it is King Wen. The `Nodes explored`
line reads 733 in both runs; it is not in the budget's unit and is not used here. In this
single-sub-branch mode the record goes to the `sub_1_0_2_0_3_0.bin` shard (`Wrote 1 solutions`).
The claim rests on the counters, not on the merged `solutions_1_0.bin`. ⚠ *(2026-09-25, Q-825: the two
archived outputs come from a binary in which that merged file was always written with 0 records, a defect
fixed the same day, so they show `Unique pair orderings: 0` and a header-only `solutions_1_0.bin`. A rerun
of the budget-30 command on the fixed binary differs from the archived output only there: `Sorting 1`,
`Writing 1`, `Unique pair orderings: 1`, and a 64-byte logical file with its new sidecar sha; the timing lines differ as in any rerun.)*

## Provenance

Run 2026-09-25 on a 16-core x86-64 Linux worker; gcc 13.3.0. `solve.c` sha256
`950525812ffb9af71806c4d46ee02ec9553b0e03f4918f61414dccaeeaf5e7fe`. The two files are the
unedited stdout and stderr of the commands above; their `Start`/`End` lines are wall-clock times.
