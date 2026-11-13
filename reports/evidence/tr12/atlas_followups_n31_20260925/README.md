# TR-12 evidence — the §12.7 follow-up queries at n = 31 (queries 8, 1b, 7, 9)

**What this is.** [TR-12 §12.7](../../../TR12_QUERY_PROGRAM.md) names three questions the n = 31 atlas
cannot answer without the f and g ladders: a calibrated null for §12.3 (query **1b**), the same
profile for King Wen's nearest valid neighbours (query **8**), and which constraint kills a doomed
prefix (query **7**). A fourth query (**9**) realises one walk through each of the atlas's extreme
transitions. All four were run against the n = 31 ladders on 2026-09-25 and again, end to end, on
2026-10-26 at public commit `9967ec14`. This directory holds the outputs, the summary tokens the
report quotes, and the commands that check them.

**What this is not.** It is not a new result about King Wen. Query 1b is a 1,000-walk *sample* of
the C1∩C2∩C4∩C5 superspace, not an enumeration and not a statement about C1–C5. Query 7 counts the
last blocking step of a doomed prefix and does not rank the constraints. Query 9 is descriptive and
no claim is made from it. Each result's scope is stated beside it below.

## Check it without the ladders (seconds)

```
E=reports/evidence/tr12/atlas_followups_n31_20260925
python3 $E/atlas_followups.py summary $E --expect $E/EXPECTED_TOKENS.txt
#   ... AF_EXPECTED_TOKENS=80 AF_EXPECTED_MISSING=0 ... last line: AF_SUMMARY=PASS
python3 $E/atlas_followups.py inputs /tmp/af_inputs     # AF_INPUTS=PASS: the two walk lists, rebuilt from this tree
( cd $E && sha256sum -c SHA256SUMS )                    # the files as stored here; see the note below
```

`SHA256SUMS` lists the files as they are stored in this directory. For the three `.gz` files that is
the sha256 of the compressed bytes, written with `gzip -9n`; read them with `gzip -dc`. The sha256 of
each table as the run wrote it, uncompressed and with its host paths, is in `AS_RUN_SHA256SUMS`.

The first command recomputes every figure below from the files here and the published atlas
(`runs/20260906_kc_ladders_n31/atlas_n31.json`, sha256
`9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558`). It re-derives each of
the 1,011 octave means from the per-step transition masses, re-sums the census, compares the census
totals with the atlas on every layer, compares the g-free census with the g-ladder census cell for
cell, and re-checks all 308 query-9 walks against C1, C2, C4 and C5 from first principles. It does
**not** recompute the transition masses, the census cells or the walks themselves: those came from
the ladders. `atlas_followups.py` sits in this directory, beside the outputs it summarises, as the
other evidence instruments of this repository do.

## Run it against ladders

```
FDIR=/path/to/run_f GDIR=/path/to/run_g OUT=/path/to/out bash scripts/atlas_followups.sh
```

needs the n = 31 f and g ladders (11.57 TB of the 15.05 TB the three ladders occupy; they are
not distributed with this repository — see `runs/20260906_kc_ladders_n31/README.md` for their
fingerprints and TR-12 Tier A for the rebuild), about 3.5 GiB of memory per profile process, and
2 GiB of scratch. Measured wall times: 2026-09-25, a 16-core host with solid-state storage, six
profile processes: query 8 63 s, query 1b 1,831 s, query 7 75 s + 2 s, query 9 97 s. 2026-10-26, one
process, slower storage: 208 s, 19,437 s, 212 s + 9 s, 114 s. The script writes nothing under
`FDIR` or `GDIR` and fails the run if anything there is newer than its start marker.

A small-n rehearsal needs no retained data and takes minutes:

```
bash scripts/atlas_followups_n9.sh         # builds n=9 ladders, runs all four queries, compares; ATLAS_FOLLOWUPS_N9=PASS
```

It runs the same commands and the same summary code. It does not exercise the out-of-core ladder
reader that n = 31 uses, and it says nothing about any n = 31 figure.

## What ran, and what is pinned

| | 2026-09-25 | 2026-10-26 |
|---|---|---|
| `solve.c` | commit **not recorded** by the run (the tables print `git=unknown`); the `--selftest` sha matched (`403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e`) | public commit `9967ec14c364cf10d2b5010a3cfc5c792a0dbb66`; `solve.c` sha256 `3725fc275dcbc3814c0924fc91de28a5e9545ab3001b7010ee37cbe194b25d1d`; built `gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz` (gcc 13.3.0); binary sha256 `84cd23584b06b34a994701c16dc7ab4398f51ade2e6bf092aef47975bad0f5c6`; the same `--selftest` sha |
| walk lists | sha256 `e18d759f3a42909468df3bf84f6945773f01c65d54c7d86ef084d2960d51cf19` (query 8, 11 walks) and `dd99cbf074dbc92f6a69a40eb6ab1baca31353b875cdad5ace9284eb6b21f792` (query 1b, 1,000 walks) | the same two files |
| atlas | sha256 `9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558` | the same |
| verdicts | `ATLAS_Q8`, `ATLAS_Q1B`, `ATLAS_Q7`, `ATLAS_Q9`, `ATLAS_QUERIES` all `ANSWERED`; `LADDERS_UNTOUCHED=YES` | the same |

The second run's outputs are **byte-identical** to the first's in every result file: the 11 + 1,000
profiles, both summaries, both census tables, the atlas cross-check, the 308 witness walks and their
308 arrangement checks, and the verdict tokens (1,330 files; 5 of them differ only in the host
paths their `#` header lines record). So every file here is an output of `9967ec14`, whatever the
first run's commit was. That commit is attested, not printed: the tables of the second run print
`git=unknown` as the first run's do (they are the same bytes), and the commit, build line and binary
sha256 in the table above come from the second run's own record, which is not distributed. The four selftests (`--selftest`, `--kc-profile-selftest`,
`--kc-dead-census-selftest`, `--kc-witness-walks-selftest`) passed before either run read a ladder.

**The script here is not byte-identical to the one that ran.** `scripts/atlas_followups.sh` carries
the query section of the run script unchanged (profiles, summaries, census, cross-checks, witness
walks, the untouched-ladders check). Its header and its defaults differ: `FDIR` and `GDIR` are
required instead of defaulting to one host's mount points, the walk lists are rebuilt from this
tree by `atlas_followups.py inputs` (and must hash to the two values above), the start line
records the commit and the `solve.c` sha256, and a summary step is added at the end. At n = 9 the
two scripts' outputs were compared on the same ladders: 56 of 56 tables identical, and identical
to the n = 9 tables the run script produced at `9967ec14`.

**At the commit that carries this directory the four queries have been run end to end at n = 9
only.** `solve.c` has changed since `9967ec14`; nobody has re-run n = 31 since 2026-10-26.

## Files

| file | content |
|---|---|
| `q8/<label>.tsv` (11) | `--kc-profile` tables: the 9 valid single-orientation flips of King Wen, the distance-2 C15 witness, King Wen itself |
| `q8/summary.tsv` | per-profile transition masses, bins against King Wen's, octave mean; `KW_W_MATCHES_ATLAS=YES` |
| `q1b/summary.tsv.gz` | the same summary for the 1,000 gallery walks (`gzip -9n`; 1,026,768 bytes unpacked) |
| `q7/dead_census.tsv.gz` | `--kc-dead-census`, layers 24–30, liveness from the g ladder |
| `q7/dead_census_gfree.tsv.gz` | the same census on layers 27–30 with liveness decided by local search, no g ladder |
| `q9/witness_walks.tsv` | `--kc-witness-walks`: 308 realised walks |
| `TOKENS_AS_RUN.txt` | the five verdict tokens |
| `AS_RUN_SHA256SUMS` | sha256 of each file **as the 2026-09-25 run wrote it**, and one digest over the 1,000 query-1b profile tables, which are not shipped (17 MB) |
| `atlas_followups.py` | the instrument: `inputs` rebuilds the walk lists, `summary` recomputes the quoted figures; standard library only |
| `EXPECTED_TOKENS.txt` | what the summary command prints on this published folder, which does not ship the 1,000 query-1b profiles (a full output tree that has them prints `AF_GATE_Q1B_CLASSES_FROM_WALKS_EQUAL_PROFILE_CLASSES=PASS` in place of the `AF_Q1B_CLASS_SOURCE` line, so this list is not the one for a full run) |
| `SHA256SUMS` | sha256 of the files in this directory |
| `n9_harness/` | walk lists and expectations for `scripts/atlas_followups_n9.sh` |

**One change from the as-run bytes.** On `#` header lines the values of `fdir=`, `gdir=`, `tdir=`
and `atlas=` (host paths) are replaced by `<PATH>`. Five files carry such a line (`q8/summary.tsv`,
`q1b/summary.tsv`, the two census tables, `q9/witness_walks.tsv`), which is why their sha256 in
`AS_RUN_SHA256SUMS` differs from `SHA256SUMS`; no data line is touched. (In the g-free census the
as-run value of `gdir=` was `-`, no directory; it reads `<PATH>` here like the others.) The 1,000 query-1b walks are
the rank lines of the published gallery, `../banked_n31_20260922/a1_q8_super.txt` (battery row
`a1_q8_super`: `solve --kc-sample FDIR 1000 SEED --kc-record`, exact-uniform by unranking, drawn
with replacement).

## Results, each with its scope

### Query 1b — King Wen's profile against a sampled band

*Statistic.* For a walk, the mean over its 31 steps of the mass percentile of its transition within
its distance class, at the octave resolution the atlas stores (`hist`: bucket ⌊log₂ w⌋, half credit
for the walk's own bucket), where w = f(state before) · g(state after). The atlas holds exact bins
only for King Wen's own transitions, so §12.3's exact percentile cannot be formed for a sampled
walk; this is the like-for-like comparison.

*Measured.* King Wen reads **0.2343** (`AF_Q1B_KW_OCTAVE_MEAN=0.234272`). **22 of the 1,000**
sampled walks read lower and none ties (`AF_Q1B_SAMPLED_WALKS_BELOW_KW=22/1000`); the Clopper–Pearson
95 % interval for that tail fraction is **[0.0138, 0.0331]**. The sample's 1st percentile is 0.1996,
its median 0.5049 and its 99th percentile 0.7960, so King Wen lies **inside the p01–p99 band**
(`AF_Q1B_KW_INSIDE_P01_P99=YES`). The band's standard deviation is 0.1325; 31 independent uniform
steps would give 0.0518, so the steps are dependent, as §12.3 said they would be, and King
Wen sits 2.0 sample standard deviations below the band mean of 0.4991.

*Two checks on the instrument.* §12.3's 0.219 counts a tie as "not lighter"; with half the tie mass
the same exact statistic is 0.2337 (`AF_KW_EXACT_MIDRANK_PERCENTILE_MEAN`), which is what the octave
value approximates. And the sample reproduces the atlas: per step, the fraction of same-class
sampled walks lighter than King Wen's transition has a 95 % interval that contains the atlas's
exact value at 29 of 31 steps (about 1.5 misses are expected by chance). Without conditioning on the
step's class the same count is 12 of 31, which is kept as the negative control.

*Reading.* King Wen's profile is in the lower tail of this sample and not outside it. §12.3 called
0.219 "a pointer, not a p-value"; this does not turn the pointer into a finding.

*Not shown.* Anything about C1–C5: the sample is of the superspace, with C3 not applied. Any tail
probability below about 0.014. The exact (non-octave) statistic for a sampled walk. Whether the low
profile is an f-side or a g-side effect. The statistic was chosen after §12.3's value was seen.

### Query 8 — the flips and the distance-2 witness

*Measured.* King Wen's own profile reproduces the atlas's `kw_w` at all 31 steps (the control). For
**7 of the 9** valid single-orientation flips, f, g and the transition mass equal King Wen's at
every step, the flipped slot included; these are the seven flips that leave the sequence of step
classes unchanged. The other two change the class at two adjacent steps (slot 5: steps 5–6; slot 17:
steps 17–18) and the mass at steps 5 and 17–18; their octave means are 0.2412 and 0.2318. The
distance-2 C15 witness differs at steps 1–14 and reads 0.2424. All eleven octave means lie in
**[0.2318, 0.2424]**; between 21 and 27 of the 1,000 sampled walks read at or below each.

*Reading.* On these ten neighbours the profile moves little, and on seven not at all.

*Not shown.* Why f and g are unchanged where the last hexagram differs (not derived here).
Neighbours at distance greater than 2, or any neighbour not on this list.

### Query 7 — which constraint blocks a doomed prefix

*Measured, exactly, over layers 24–30* (which hold 0.9999972 of all doomed prefixes;
`AF_Q7_RANGE_SHARE_OF_ALL_DOOMED_PREFIXES`). A dead state has f > 0 and g = 0. By what blocks its
candidate next steps (`documentation/SOLVE_C_CLI.md`, `--kc-dead-census`):

| kill class | dead states | doomed prefixes | share of doomed prefixes | share of *terminal* doomed prefixes |
|---|--:|--:|--:|--:|
| C2 (every candidate is a distance-5 step) | 58 | 2.137×10³⁷ | 0.36 % | **0.58 %** |
| C5 (every candidate needs an exhausted class) | 278,492 | 2.714×10³⁹ | 45.48 % | **74.07 %** |
| MIXED (both kinds, nothing admissible) | 1,123,436 | 9.286×10³⁸ | 15.56 % | **25.34 %** |
| DEEP (an admissible step exists; every one leads to a dead state) | 220,555,510 | 2.304×10³⁹ | 38.60 % | — |

A *terminal* doomed prefix has no admissible next step. An exhausted C5 class is among the blockers
of **99.42 %** of them and a distance-5 step among the blockers of 25.93 %; C2 alone blocks 0.58 %. At layer 30 no dead state is DEEP. Cross-checks: the
per-layer dead and live totals equal the atlas's on all seven layers, and the census that decides
liveness by local search with no g ladder agrees cell for cell on layers 27–30.

*Reading.* Within the superspace, on these layers, a doomed prefix with no admissible next step
almost always has a spent distance-class budget among what blocks it.

*Not shown.* That C2 matters less than C5: the census counts only the last blocking step, C2 also
decides which prefixes exist at all, and near the end of a walk few classes have budget left, so
this outcome is close to forced by C5's definition. C2 is in fact implied by C5's histogram, which
has no distance-5 step (`documentation/SPECIFICATION.md`), so the two labels are not two independent
constraints: the split is between the one class that never has budget and the classes whose budget is
spent. And the pooled shares are mostly the last layer's: 74.13 % of the terminal doomed prefixes sit
at layer 30, where one pair and one unit of budget remain and the kill class records only how many of
the last pair's two entries are distance-5 steps, and 97.09 % sit at layers 29–30; by layer the share
blocked only by exhausted classes runs from 26.27 % (layer 24) to 79.45 % (layer 30)
(`AF_Q7_TERMINAL_PREFIX_SHARE_BY_LAYER`, `AF_Q7_TERMINAL_C5_ONLY_SHARE_BY_LAYER`). Layers below 24 (0.00028 % of doomed prefixes).
Anything about C3, which the ladders do not carry.

### Query 9 — one walk through each extreme transition

*Measured.* The atlas records the heaviest and the lightest transition per layer and distance class:
310 cells, 2 of them empty. `--kc-witness-walks` realised one complete walk through each of the
other **308**; 305 of the walks are distinct. Every row passes the engine's own checks (realised,
valid, through its transition, f, g and w equal to the atlas's), and all 308 are superspace members
by a first-principles check in Python. 132 are also in C1–C5. None is King Wen.

*No claim is made from them.* Each walk is one realisation, the first predecessor and the first
completion in the engine's order, so away from its witness step its shape reflects search order.
TR-12 §9 already says that a minimum-mass corridor "is expected in any large DP and distinguishes
nothing by itself".

## Provenance

Run and interpreted with AI assistance (Claude Fable 5.1 and Claude Opus 5.5, Anthropic, 2026-09-24
to 2026-10-26); this directory, the public scripts and the wording by Claude Fable 5.2, 2026-11-13.
No novelty is claimed. Corrections welcome.
