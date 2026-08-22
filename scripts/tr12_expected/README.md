# `scripts/tr12_expected/` — the TR-12 reproduction battery's expected-output blocks

TR-12 §R step 6 requires that every published number appear "in a verbatim, diff-able block", and
that `scripts/tr12_repro.sh` diff each query's output against it and **exit non-zero on any
mismatch**. This directory holds those blocks, one subdirectory per universe.

| directory | universe | what it is |
|---|---|---|
| `n9/` | n = 9, N = 26,112 | the reduced-universe battery. Self-contained: `scripts/tr12_repro.sh --n9` builds its own f/g/t ladders in a temp dir in about a second, needs no campaign data, no disk and no network, and finishes in ~90 s on two cores. This is the whole correctness argument, and it costs nothing. |
| `n31/` | n = 31, N = 1,097,051,278,789,181,790,036,112,071,176,579,186,688 | **not present yet.** The full-31 blocks are minted at TR-12 publication, from a run against the real Stage F / Stage G / Stage T ladders. Until they exist, `scripts/tr12_repro.sh --fdir … --gdir … --tdir …` refuses to report a pass: a battery with nothing to diff against cannot pass, and it says so rather than exiting 0 on an empty comparison. |

## Regenerating

```bash
scripts/tr12_repro.sh --n9 --regen      # rewrites n9/ from a fresh run
git diff scripts/tr12_expected/n9       # then READ the diff before committing it
```

`--regen` is not a fix. If a block changed, either the engine changed (in which case the diff is
the evidence and belongs in the commit message) or something regressed. Regenerating without
reading the diff destroys the only record of which it was.

## What is and is not normalised

Each block is the row's output after one `sed` pass that removes **only** what varies between two
correct runs of the same binary on the same universe: absolute paths, `mktemp` scratch directories,
the `-DGIT_HASH` / `-DSOURCE_SHA` build identity, wall-clock timings and peak RSS. Every count,
rank, walk, layer sha, gate verdict and provenance scope string is diffed **verbatim**. The exact
substitution list is in the `norm` function of `scripts/tr12_repro.sh`, next to the reason for
each one.

`_MANIFEST.txt` records the universe, the knob settings, the anchor walk and a sha256 per block, so
a reviewer can see at a glance which blocks a change touched.

## Shown able to fail

A gate that has never been observed to fail does not count. This one has been, four ways — a
one-digit edit to a block, a deleted block, a changed sampling seed, and the banned C3 units value
`776` in place of the walk-functional gate — each producing a named `FAIL` row and exit status 1,
with a clean run returning to exit 0 afterwards. Re-run any of them before trusting the battery.

---

*2026-08-22. Claude (Opus 5). Developed with AI assistance (Claude, Anthropic). Direction and the
query program are the operator's. These blocks are a certificate of what this binary does on the
n=9 universe, not a proof. Errors are Claude's; corrections invited.*
