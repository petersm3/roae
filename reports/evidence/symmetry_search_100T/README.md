# The 2026-04-25 symmetry test on the 100T log, re-run with its definitions (2026-09-25)

**What this is.** TR-5 §2 and SYMMETRY_SEARCH.md quote the overturned 2026-04-25 test's figures:
per-cell yields of σ-related cells differ by "max >1.5M records", with "≥21,000 mismatched cell
pairs per σ", and the closest near-miss σ = [5,4,3,2,1,0] has "43% match". Codex v3 review,
V3B-08#6, found "mismatch" and the 43% denominator undefined in TR-5. This directory re-runs the
test on the tracked 100T enumeration log and archives the output, which defines both.

## Reproduce

```bash
gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz
zcat runs/20260419_100T_d3_d128westus3/enum_output.log.gz \
  | ./solve --symmetry-search --validate-counts \
  > symmetry_search_validate_counts.out 2> symmetry_search_validate_counts.err
```

Under a second, from the repository root. Phase 3 reads the per-cell `Wrote N solutions` lines of
the log from stdin; the stderr line reports how many it parsed (60,533).

## Definitions, read from the output

For each of the 47 non-identity σ, Phase 3 looks up each parsed cell's σ-image cell:

- `matches`: the image cell is in the log with the same yield;
- `mismatches`: the image cell is in the log with a different yield;
- `missing`: the image cell has no `Wrote` line (typically budgeted with 0 solutions);
- `max_diff`: the largest yield difference over the mismatched pairs, in records.

The three counts sum to 60,533 for every σ.

## Result

- Fewest mismatches over the 47 σ: **21,010** (σ #21 and σ #28). This is the "≥21,000".
- Largest `max_diff` over the 47 σ: **1,734,295** records (σ #12, #17, #30 and #35). The ">1.5M" is
  this maximum. It is not a per-σ floor: σ #47 has `max_diff=811359`.
- σ #47 = [5 4 3 2 1 0]: `matches=26158 mismatches=32456 missing=1919`. The "43%" is
  26,158 / 60,533 = 43.2%, over all parsed cells. Over present pairs only, 26,158 / (26,158 +
  32,456) = 44.6%.

These are budgeted-yield comparisons. TR-5 §2 explains why they say nothing about the solution set.

## Provenance

Run 2026-09-25 on a 16-core x86-64 Linux worker; gcc 13.3.0. `solve.c` sha256
`950525812ffb9af71806c4d46ee02ec9553b0e03f4918f61414dccaeeaf5e7fe`. The `.out` and `.err` files are
the unedited stdout and stderr of the command above.
