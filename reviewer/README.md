# The ROAE reviewer package, v1

## In short

This package tests a program that counts ways to order the 64 hexagrams of the I Ching under four
rules taken from the traditional King Wen order. The rules keep the hexagrams in fixed pairs, fix
the opening pair, forbid a five-line change between neighbours, and fix how often each size of
change occurs.

The project reports a 40-digit total from a run of several days. A bug could produce a
convincing but wrong answer, so this package gives you smaller checks to run, several by
programs written separately from the counting program.

In about two minutes, you build the counting program, repeat five smaller counts, and compare the
files it writes with recorded hashes. A separate Python program recounts two of those problems. A
separate C program counts every valid start of the full problem up to six placed pairs. Another
check counts its symmetry families at every layer.

These checks are evidence about the cases they test. They do not recompute or prove the
40-digit count. The full table is checked against the bundled run log: a match shows the table was copied
correctly, not that the run's arithmetic was right. Proofs and data are not included.

**To run everything:** from the unpacked package's top directory, run `bash reviewer/selfcheck.sh`.
A passing run ends with `PACKAGE_MANIFEST=OK`, `SELFCHECK_FAILED=0` and `REVIEWER_PACKAGE=PASS`.

**What is recounted, and by what.** The engine runs five smaller problems. Python recounts two of
them (n = 9 and n = 13) layer by layer. C counts the first six layers of the full problem one start
at a time. Python counts the symmetry families at all 31 layers. The other layers of the full
problem (7 to 31), and its total, are checked against the run log, not recounted.

## About this package

ROAE, the Received Order Analysis Engine, studies the King Wen sequence of the I Ching as a
combinatorial object: it counts orderings of the 64 hexagrams that satisfy stated rules. This
package lets you recompute, on a laptop, the project's small exact counts and the first six layers
of its full-scale count, and compare each result with a published digest or integer. It does
**not** recompute the headline full-scale figures. For those it gives you the published per-layer
table and a check that the table is a faithful copy of the published run log. Nothing is
downloaded from us; the package is the only input.

Corrections to this page are recorded in the full repository's
[CORRECTIONS.md](https://github.com/petersm3/roae/blob/main/documentation/CORRECTIONS.md)
(not included; needs network).

## What is being counted

A hexagram is six lines, each broken or unbroken, so it is a 6-bit number from 0 to 63. An
ordering puts all 64 in a sequence. The full definitions are in
[SPECIFICATION.md](../documentation/SPECIFICATION.md), which is included. The counts in this
package use four of the project's seven rules:

- **C1.** The 64 hexagrams form 32 pairs, and each pair sits in two consecutive places, in either
  order. A hexagram's partner is its *reverse*: the same six lines read from the other end. Eight
  hexagrams read the same both ways; each of those is paired with its *complement*, the hexagram
  with every broken line made unbroken and every unbroken line made broken.
- **C2.** No two neighbouring hexagrams differ in exactly five lines.
- **C4.** The sequence opens with the pair ䷀ Qian, ䷁ Kun (63 then 0).
- **C5.** The sizes of change between neighbours occur exactly as often as in King Wen's order.
  Across its 63 neighbouring positions, 2 changes affect one line, 20 affect two, 13 affect three,
  19 affect four and 9 affect all six.

C4 fixes the first pair, which leaves **31 free pairs**. Inside a pair the size of change is fixed
by C1, so C5 constrains only the 31 boundaries between consecutive pairs.

**Sizes.** `n` counts free pairs; the fixed opening pair comes on top. So the n = 13 problem uses
14 pairs, or 28 hexagrams, and the full problem is n = 31. `k` counts how many free pairs have been
placed so far: layer 6 of the full problem is about starts of 14 hexagrams (the opening pair and
six more pairs).

| term | meaning |
|---|---|
| layer `k` | the number of free pairs placed so far, after the fixed first pair |
| prefix | a start: the first `k` free pairs, each in one of its two orders, that breaks no rule so far. It need not extend to a complete valid ordering |
| `mass` | the number of valid prefixes at layer `k`: an exact integer count |
| `B0` | the boundary budget: how many pair-to-pair boundaries of each size of change 1, 2, 3, 4 and 6 an ordering must use (5 is excluded by C2). For the full problem it is King Wen's own, (2, 8, 13, 7, 1) |
| rung `n` | a separate, smaller problem of the same kind, on `n` of the 31 free pairs plus the fixed opening pair. `--f1-pairs n` picks a union of whole symmetry orbits of pairs, and each rung derives its own `B0` from its own pairs. A rung is not a sample of the full problem |
| orbit quotient | the rules are unchanged by a group of 24 symmetries, so the engine stores one representative of each orbit (family of symmetric copies) of placed-pair sets and weights it by the orbit's size; `canonical_masks` counts those representatives |
| f-ladder | the per-layer files the engine writes, one file per layer (step 4 writes the n=13 f-ladder into `out13/`). The g- and t-ladders are two further per-layer structures, described upstream and not used here |
| catalog | a compact structure that stores shared counting work instead of listing every ordering (`--kc-build`, steps 7 and 8) |

## What this package establishes, and how

Each figure on this page carries one of these labels.

| label | meaning |
|---|---|
| **recomputed here** | your machine computes it, from the sources in this package, during the steps |
| **compared** | a recomputed value is compared with a value the project published (a digest or an integer) |
| **transcription check** | two published documents are compared with each other; nothing is recomputed |
| **consistency check** | a property the published value must have; it does not show the value is right |
| **reported upstream (exact / measured / estimated)** | a figure the project reports and this package does not recompute; the kind says which |
| **proved upstream** | covered by the project's machine-checked proofs, which are not in this package |

| what | label |
|---|---|
| the five small rungs n = 9, 13, 16, 18, 19: engine totals, layer-file digests, byte counts and file counts | recomputed here, compared |
| rungs n = 9 and n = 13: every layer's mass, by a separate Python program; at n = 13 your engine log's layer masses too | recomputed here, compared |
| the full problem, layers 1 to 6 of the `mass` column | recomputed here (by enumeration, in a separate C program), compared |
| the full problem, the `canonical_masks` column at all 31 layers | recomputed here (by Burnside's lemma), compared |
| the full problem, layers 7 to 31 of the `mass` column, and the headline count | reported upstream (exact); step 13 is a transcription check |
| the other five columns of the full-scale table (`states`, `entries`, `V_k`, `layer GB`, and `C(31,k)`) | reported upstream: `layer GB` is rounded telemetry (measured), the rest exact; `C(31,k)` is also recomputed here by arithmetic |
| the headline count is divisible by 24 | consistency check |
| the full-scale ladder sizes, run time, and the count under all seven rules | reported upstream (measured, measured, estimated) |
| the step times on this page | measured by the project, on the machine named below |

A matching SHA-256 hash is strong evidence that the files you generated are byte for byte the
files we recorded. It does not show that what those files say is mathematically right; the
recounts by separate programs are what bear on that.

## What this package does not show you

- **The headline count is not recomputed here.** |C1∩C2∩C4∩C5| =
  1,097,051,278,789,181,790,036,112,071,176,579,186,688 is *reported upstream (exact)*. It comes
  from the full n=31 run: the same `--f1-exact-c1c2c4c5` command as step 4, with no `--f1-pairs`
  flag, run out of core over many resumed sessions. The bundled log shows those sessions, on 64-
  and then 128-thread machines; it does not by itself establish the total elapsed time, which the
  project reports as multi-day. The project also reports that a second, independent engine,
  `verify.c --ie-count`, recomputed the same total at full scale (TR-11 §10(vi), in the full
  repository). That mode is in the bundled `verify.c`, but the full-scale run is not one of these
  steps and its records are not in this package. The sizes of the three full-scale ladders
  (f 3.29 TB, g 8.27 TB, t 3.48 TB, 15.05 TB together) are *reported upstream (measured)*, on
  different bases, in [REPRODUCE.md](../documentation/REPRODUCE.md) ("What this does NOT
  reproduce"); the provisioning table they come from is in the full repository's TR-12, not here.
- **This package recomputes the small-rung results, prefix masses for layers 1–6, and symmetry
  widths. The full-31 table contains reported exact counts and rounded telemetry. Step 13 checks
  transcription against the bundled log; it does not verify the full-31 arithmetic.** Layers 7 to
  31 of the `mass` column rest on the engine, and on instruments that read the multi-terabyte
  ladders, which are not in this package.
- **The rungs are small.** All 20 layer files of the n=19 rung are 88,311,188 bytes (recomputed
  here, in step 9), about **0.003 %** of the n=31 f-ladder's reported size; even n=21 is about
  0.013 %. A rung is the same engine run on a smaller, self-contained problem. It is not a sample
  of the full problem and does not estimate it.
- **The aggregate table is an aggregate, not a catalog.** It does not let you list, rank or query
  individual orderings, and nothing in this package does at full scale.
- **The catalog is checked only in part.** Steps 7 and 8 check that the n=13 catalog builds, that
  it gives the right total, and that its binary layer files are the published bytes. They do not
  test its other queries or its metadata files.
- **The estimated figures are not touched.** The project's figure of about 5×10³¹ orderings
  satisfying all seven rules C1–C7 (5.21×10³¹, from weighted Knuth sampling with stated probe
  counts) is *reported upstream (estimated)*, in the full repository's
  [SEARCH_SPACE_SIZE.md](https://github.com/petersm3/roae/blob/main/documentation/SEARCH_SPACE_SIZE.md)
  (not included; needs network). Its probe records are not in this package, and no step here bears
  on it.
- **The proofs are not in this package.** The Lean proofs and SAT certificates are in the full
  repository; checking them needs at least 12 GB of free RAM (*reported upstream (measured)*;
  `reports/certificates/verify_all.sh` there). That requirement does not apply to the 13 steps.

## What is in it

Generate the layer files locally and compare their hashes with the published ledger: the package
ships the method and the exact aggregates, never a sample of the data.

| part | what | where |
|---|---|---|
| commands and expected files | exact commands, `*.bin` digests and the three mistakes that make a correct run look wrong | [documentation/REPRODUCE.md](../documentation/REPRODUCE.md) |
| the reported full-run table | the 31-row per-layer table of the full run, with each column's provenance | [reports/FULL31_EXACT_AGGREGATES.md](../reports/FULL31_EXACT_AGGREGATES.md) |
| smaller problems you can rebuild | rungs n = 9, 13, 16, 18, 19, as commands (steps 3 to 9) | this page |
| the limits of these checks | what the package cannot show | the section above |

The package is these 13 files. `bash reviewer/make_package.sh` bundles exactly these into one
`.tar.gz` and adds `reviewer/MANIFEST.sha256` and `reviewer/PACKAGE_VERSION` (the version and the
source commit); it refuses to build a release from files that differ from that commit. The
self-check requires the manifest, requires it to list exactly these 13 files and
`PACKAGE_VERSION`, each once, and checks every file against it before step 1; it then prints
`PACKAGE_MANIFEST=OK`. A directory with no manifest fails. The one exception is a repository
checkout, which has none: there, run `bash reviewer/selfcheck.sh --source-checkout`, which prints
`PACKAGE_MANIFEST=SKIPPED`.

| file | role |
|---|---|
| `reviewer/README.md` | this page |
| `reviewer/selfcheck.sh` | runs every step below and checks its output; `--files` prints this list |
| `reviewer/make_package.sh` | bundles the package into one file |
| `solve.c` | the counting engine (one C file) |
| `verify.c` | an independent verifier in C; shares no code with `solve.c` |
| `verify.py` | an independent verifier in Python; shares no code with either |
| `documentation/SPECIFICATION.md` | the formal definitions of the rules |
| `documentation/REPRODUCE.md` | commands and expected files |
| `reports/FULL31_EXACT_AGGREGATES.md` | the reported full-run table |
| `scripts/reproduce_digests_gate.sh` | runs REPRODUCE.md's own commands and compares its digests |
| `runs/20260716_f1c5_c1c2c4c5_d128westus3/run.out` | the published log of the full-31 run (51,190 bytes) |
| `LICENSE.md`, `CITATION.cff` | licence and citation |

Links on the included pages that point at files outside this list are not included and do not
work in an unpacked copy. Those files are in the full repository, https://github.com/petersm3/roae
(needs network), at the commit named in `reviewer/PACKAGE_VERSION`. You do not need them to run
the steps.

## What you need

- Linux on x86-64. macOS is not supported: the build uses `-fopenmp` and the scripts use GNU
  `find`, `date` and `sha256sum`. Windows users can try WSL2, which we have not tested.
- `gcc` with OpenMP, the zlib headers (Debian/Ubuntu `zlib1g-dev`, Fedora `zlib-devel`), and
  `python3` 3.8 or later. The steps use no third-party Python packages.
- `bash`, GNU coreutils (`sha256sum`, `sort`, `tee`, `timeout`, `mktemp`, `cut`, `head`, `tail`,
  `cp`, `date`, `dd`), GNU findutils (`find`, `xargs`), `sed`, `awk`, `grep`, `gzip`, and `tar` to
  unpack. `--selftest` also needs `cmp` and `diff`, from GNU diffutils. Most Linux systems have all
  of these.
- No network and no `git`. The steps build and run programs in a scratch directory under
  `$TMPDIR` (default `/tmp`), so it must allow both writing and running programs. If `/tmp` is
  mounted `noexec`, set `TMPDIR` to a directory that allows it. Step 2 writes a few MB there; step 9
  about 200 MB.

## The steps

There are **13 steps**. Run them in order from the package's top directory. **A step passes only
when its command exits zero, every listed expectation matches, and nothing in its output
contradicts them.** An `expect:` line must equal a whole line of the output, ignoring leading and
trailing blanks; an `expect:` line that ends in `…` must begin a line of the output, which then
goes on with a blank (these lines end in a timing). Three things count as a contradiction:

- another line setting the same `KEY=` to something else, beside an expectation such as
  `AGGREGATES=PASS`, or the expected `KEY=` line itself printed more than once;
- a line of the same form as a matched expectation with another value, such as a second
  `KC COUNT n=13 = ` line with a different number (a line whose first number differs, such as
  another layer's line, is another record, not a contradiction);
- a line that reports a failure: one that contains the word `FAIL` or `ERROR`, a starred
  `MISMATCH`, or the start of a Python traceback, including after the expected beginning of a line
  that ends in `…`.

A step that does not finish proves nothing either way. One that runs past the self-check's time
limit (`SELFCHECK_STEP_TIMEOUT`, 1800 seconds unless you set it) is reported as `[TIMEOUT]`, and one
killed by a signal (a segmentation fault, or out of memory) as `[CRASH]`; the run then ends with
`REVIEWER_PACKAGE=ERROR`, not `PASS` or `FAIL`, whatever the step printed before it stopped.

To run the steps by hand exactly as the self-check does, first start a shell that fails a
pipeline when any part of it fails, and clear any engine settings you may have exported:

```
bash -o pipefail
unset ${!SOLVE_*}
```

Run them in a fresh copy of the package: step 4 resumes a finished `out13/` if one is already
there, and its log then differs. Copy only the command after each `[n]`. The `Why:` line above it
says what the step shows; the `expect:` lines below it are the output to compare. Neither is shell
input. Or run them all at once:

```
bash reviewer/selfcheck.sh          # ends with REVIEWER_PACKAGE=PASS
```

The self-check copies the 13 package files, and nothing else, into a fresh scratch directory, runs
each step there exactly as written below with `bash -o pipefail` and no inherited `SOLVE_*`
setting, and compares the output with the `expect:` lines. Files you made by hand are never used or
changed. It reads the steps from this page, so the page and the check cannot drift apart, and it
refuses a page whose step count differs from the number stated above. It skips the `Why:` lines.

```text
Why: build the engine from its one source file, so every later check runs a program compiled on your machine.
[1] gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz && echo BUILD_SOLVE=OK
    expect: BUILD_SOLVE=OK

Why: one fixed enumeration test, its answer's hash recorded in the source; a match shows your build
     gives our answer on that test. Later steps test the counting mode behind the headline.
[2] ./solve --selftest
    expect: [--selftest] Actual sha256:   403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e
    expect: [--selftest] PASS — sha256 matches canonical baseline

Why: a separate Python program counts the n=9 problem layer by layer, with no symmetry shortcut,
     and every layer must match the published table.
[3] python3 verify.py --recount-rung-layers 9
    expect: layer  9: recount 26,112  published 26,112  [ok]
    expect: all 9 layer masses MATCH reports/FULL31_EXACT_AGGREGATES.md …

Why: the engine counts the n=13 problem with its symmetry shortcut; steps 5, 8 and 13 check its files and its log.
[4] SOLVE_F1_KEEP_LAYERS=1 ./solve --f1-exact-c1c2c4c5 --f1-pairs 13 --layers-dir out13 2>&1 | tee run13.log
    expect: F1C5 SUBSET n=13 pairs [3,7,11,5,8,26,31,10,15,20,23,27,29] start_exit=0 B0=(1,6,0,6,0)
    expect: orbit-quotient C5-DP total = 2063395607040

Why: the hash of all your layer files must equal the published one, so your files match ours byte for byte.
[5] (cd out13 && find . -name '*.bin' | sort | xargs sha256sum | sha256sum)
    expect: 40387eed07b11319ba3943fca64ab94a7e19c6acfb56d2b42ce86e6ac0625c4e  -

Why: the separate Python program counts every layer of the n=13 problem against the published table;
     step 13 checks your engine's layers against the same table.
[6] python3 verify.py --recount-rung-layers 13
    expect: layer 13: recount 2,063,395,607,040  published 2,063,395,607,040  [ok]
    expect: all 13 layer masses MATCH reports/FULL31_EXACT_AGGREGATES.md …

Why: build the n=13 catalog, which stores shared counting work instead of listing orderings; step 8 checks it.
[7] ./solve --kc-build kc13 --f1-pairs 13
    expect: KC BUILD n=13 dir=kc13 count=2063395607040 …

Why: check the catalog's total and the hash of all its binary layer files. This does not check its metadata files.
[8] ./solve --kc-count kc13 && (cd kc13 && find . -name '*.bin' | sort | xargs sha256sum | sha256sum)
    expect: KC COUNT n=13 = 2063395607040
    expect: 40387eed07b11319ba3943fca64ab94a7e19c6acfb56d2b42ce86e6ac0625c4e  -

Why: rerun the engine at five sizes with REPRODUCE.md's own commands, and compare totals, file counts,
     byte counts and hashes with that page.
[9] bash scripts/reproduce_digests_gate.sh
    expect: REPRODUCE_DIGESTS_RUNGS=5
    expect: REPRODUCE_DIGESTS=PASS

Why: build the separate C checker used in step 11; it shares no code with the engine.
[10] gcc -O2 -o verify verify.c -lz -lpthread -lm && echo BUILD_VERIFY=OK
    expect: BUILD_VERIFY=OK

Why: count every valid start of the full 31-pair problem one by one, up to six placed pairs, and compare
     the six totals with the published run log.
[11] ./verify --brute-masses runs/20260716_f1c5_c1c2c4c5_d128westus3/run.out 6
    expect: BRUTE_MASSES_COMPARED=6
    expect: BRUTE_MASSES_MISMATCHED=0
    expect: BRUTE_MASSES_RESULT=PASS

Why: count the symmetry families of placed-pair sets at every layer with Burnside's formula and compare
     them with the table. This checks the engine's bookkeeping, not the ordering counts.
[12] python3 verify.py --recount-orbit-widths 31
    expect: all 31 canonical_masks MATCH reports/FULL31_EXACT_AGGREGATES.md (widest 13,047,760 at k=15)
    expect: ORBIT_WIDTHS=GATED

Why: check that the full table copies the published run log exactly, and that your n=13 log matches the
     table. This does not redo the full count.
[13] bash reviewer/selfcheck.sh --aggregates run13.log
    expect: AGGREGATES=PASS
```

## What each step shows

1. **Build the engine.** One C file, one compiler line. Building it shows it compiles on your
   machine, nothing more. GCC may print two `-Wformat-truncation` warnings on some versions; they
   do not affect the result.
2. **The engine's regression check** (*recomputed here, compared*). It enumerates a fixed slice of
   the C1–C5 space and compares the sha256 of the result with the baseline recorded in the source,
   `403f7202…`. It covers that one test case, in the engine's enumeration mode; the counting mode
   behind the headline is tested by steps 4 to 9. It writes into a scratch directory under
   `$TMPDIR`.
3. **The smallest rung, counted in Python** (*recomputed here, compared*). A *rung* is a smaller
   puzzle of the same kind, built from only some of the 31 free pairs (here 9). A *layer* is how
   many pairs have been placed so far. `verify.py` counts the n=9 rung layer by layer with a plain
   dynamic program: it keeps a running tally as it places each pair, merging starts that end in the
   same state, but with no symmetry shortcut. It is written separately from the engine and shares
   no code with it, though the two follow the same rules and so the same kind of recurrence. It
   compares each layer with the published n=9 column. The rung's total is **26,112**.
4. **The same kind of rung, counted by the engine** (*recomputed here, compared*). At n=13 the
   engine counts **2,063,395,607,040** orderings, with the published budget `B0` = (1,6,0,6,0). It
   uses a shortcut called the *orbit quotient*: the rules look the same under 24 symmetries, so
   the sets of pairs placed so far come in families of symmetric copies, and the engine stores one
   set from each family and weights it by the family's size. It writes one layer file per layer
   into `out13/` (the project calls such a set of files an *f-ladder*) and its log into
   `run13.log`.
5. **Your layer files are the published ones, byte for byte** (*recomputed here, compared*). The
   digest of `out13/*.bin` equals the n=13 row of the ledger in REPRODUCE.md. The layer files were
   generated locally.
6. **Two methods agree at n=13** (*recomputed here, compared*). The Python count gives the same 13
   layer masses as the published n=13 column, which step 13 also compares with your engine's log
   from step 4.
7. **A catalog** (*recomputed here*). `--kc-build` writes the n=13 knowledge-compiler catalog into
   `kc13/`. A knowledge compiler turns the rules into a structure that stores shared counting work,
   so it need not list trillions of orderings, and can answer questions about the orderings
   themselves; "how many?" is only the simplest of them. These steps test that one.
8. **A query, and the catalog's own bytes** (*recomputed here, compared*). `--kc-count` reads the
   catalog back and answers the simplest query, "how many?", with the same number as step 4. The
   count is read from the catalog's last layer, so the step also hashes the catalog's binary layer
   files: they must equal the published n=13 digest, the one your `out13/` matched in step 5. A
   changed byte in any binary layer of the catalog fails this step even when the count is right.
   The catalog's metadata files (`*.json`) are not checked.
9. **All five small rungs** (*recomputed here, compared*). The gate builds the engine from
   REPRODUCE.md's own build line, runs the page's command at n = 9, 13, 16, 18 and 19, and compares
   each digest, byte count, file count and total with the page. A hashing command that fails, even
   after printing the right digest, fails the step. The gate also shows that the digest recipe is
   path-independent, that one flipped byte changes it, and that leaving out
   `SOLVE_F1_KEEP_LAYERS=1` changes it. Per-layer masses of these rungs are not compared here; the
   digests cover the layer files, and steps 3, 6 and 13 compare the masses at n = 9 and 13.
10. **Build the second verifier.** `verify.c` shares no code with `solve.c`.
11. **The full problem, first six layers, by enumeration** (*recomputed here, compared*).
    `verify --brute-masses` walks to every valid prefix of length 1 to 6, one at a time, with no
    merging of states and no symmetry, and compares each count with the `mass` in the published
    full-31 log: 56; 3,030; 158,364; 7,975,320; 386,225,352; 17,953,712,064. This is 6 of 31
    layers. Every run session in the log must be the full problem (all 31 pairs, starting exit 0),
    and every layer record must parse, each layer once; only layers 1 to 6 are compared here, and
    step 13 checks that the log holds all 31.
12. **The symmetry column, all 31 layers** (*recomputed here, compared*). Burnside's lemma is a
    standard formula for counting families of symmetric copies without listing them. Applied to the
    24 symmetries, it reproduces every `canonical_masks` value in the aggregate table, from 7 at
    k=1 to 13,047,760 at k=15 and 16. This column counts the families the engine stores at each
    layer. It describes the symmetry and says nothing about whether the count itself is right.
13. **The aggregate table is the log** (*transcription check*, with one *consistency check* and one
    comparison of your own run). All seven fields of all 31 rows of the aggregate table equal the
    published run log (sha256 `8c7d063e…`); of these, `layer GB` is rounded telemetry and the rest
    are exact integers reported by the run. Every layer record of the log must be a well-formed
    full-31 record, each layer once, every run session must be the full problem (all 31 pairs,
    starting exit 0), and every final-count line must agree. The table's own digest is
    `165cda4e804e398a1d3690cf1d73348d7ddd743134a61c84ba99df8b38881547`, and its last row is the
    headline count. That count is divisible by 24, as the theory requires; this is a consistency
    check, not a validation of the count. `C(31,k)` is checked by arithmetic. Finally, your n=13
    log from step 4 must hold exactly one n=13 run of the published pairs from exit 0, each layer
    once and in order, and match the table's n=13 column, which must have exactly one row per layer
    (*recomputed here, compared*). This step does not verify the full-31 arithmetic (see the
    sections above).

`bash reviewer/selfcheck.sh --selftest` tests the checker itself: the pass rule, the manifest
check, step 13's table and log checks, and steps 2, 4, 7 and 8 of this page run against small
stand-in programs. It plants one defect at a time and requires the targeted check, and only that
check, to reject it. It does not plant faults in the counting programs: steps 3, 6, 9, 11 and 12
rest on their own comparisons with published numbers (and `bash scripts/reproduce_digests_gate.sh
--selftest` tests step 9's gate the same way, with a compiler). The planted defects are: for step
13, each digest, a field of the table, a field of the log, a `C(31,k)` cell, the headline row,
divisibility, a repeated, relabelled or extra record, a run session of another problem or from
another starting exit, a repeated row in the n=13 column, and ten defects in an n=13 log; for the
manifest, a changed file, a truncated, duplicated or extended manifest, a missing one, and both
marker files removed; for the runner, a wrong token, an extra digit, a malformed digest, a quoted
success line, conflicting verdicts, a second line of the same form with another value, a reported
failure, a failing command that prints every token, a failing program before `| tee`, a wrong step
count, a step with no expectation, a verdict printed twice, a failure word after an expected
beginning, a reported `ERROR`, a Python traceback, and a step that times out, crashes, or is killed
behind `| tee`; for the aggregate and manifest checks, a verdict line beside a crash, a timeout or
an exit status that disagrees, no verdict line, and two; that a step neither sees nor changes outputs already in the
package directory; and the real steps 2, 4, 7 and 8 against stand-ins that print a wrong sha, a
second all-zero sha, the engine's own failure line, a second count, exit nonzero after the right
lines, print ten times the count, or leave a corrupted catalog. It prints
`SELFCHECK_SELFTEST=PASS` and needs no compiler.

## Measured times

<!-- TIMES:BEGIN -->
Measured on 2026-10-03, AMD EPYC 9V45 96-Core Processor, 31.3 GiB RAM, pinned to **one core**, gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0; Python 3.12.3.

| step | what | wall time, one core | peak memory |
|--:|---|--:|--:|
| 1 | build the engine | 18.8 s | 434 MB |
| 2 | engine regression check | 32.8 s | 144 MB |
| 3 | n=9, counted in Python | 0.1 s | 34 MB |
| 4 | n=13, counted by the engine | 0.8 s | 12 MB |
| 5 | digest of your layer files | < 0.1 s | 4 MB |
| 6 | n=13, counted in Python | 4.2 s | 99 MB |
| 7 | build the n=13 catalog | 0.4 s | 13 MB |
| 8 | query the catalog | < 0.1 s | 12 MB |
| 9 | all five small rungs, rebuilt and compared | 28.8 s | 433 MB |
| 10 | build the second verifier | 2.8 s | 131 MB |
| 11 | full-31 layers 1-6, by enumeration | 48.4 s | 4 MB |
| 12 | symmetry column, all 31 layers | 0.1 s | 35 MB |
| 13 | aggregate table vs the run log | < 0.1 s | 16 MB |

All 13 steps together, including the self-check's own work: **138 s** on one core. The largest peak memory of any step is **434 MB**.
<!-- TIMES:END -->

These times were measured by the project on the one machine named above, with
`bash reviewer/selfcheck.sh --times FILE`, which writes each step's wall time and peak memory to
`FILE`; run it to measure your own machine. Wall time and memory depend on the machine. The
digests, counts and tokens should not. If one of them differs, that is a finding, and we want to
hear about it.

## If a step fails

- **Step 2 fails with "selftest child produced no output".** It prints the last lines of the
  child's error output and keeps its scratch directory. Check that `$TMPDIR` (default `/tmp`) is writable, that it allows
  running programs, and that `bash`, `gzip` and `sha256sum` are installed.
- **Step 5 gives a different digest.** Check the three mistakes in REPRODUCE.md: the
  `SOLVE_F1_KEEP_LAYERS=1` setting, hashing `*.bin` only, and hashing from inside the directory
  with `| sort`. If you ran step 4 twice by hand, remove `out13/`, `kc13/` and `run13.log` and
  start again.
- **Step 1 or 10 fails to link.** Install the zlib headers.
- **A step fails with "Permission denied" on a program it just built.** The scratch directory is
  on a `noexec` filesystem; set `TMPDIR` to one that allows running programs.
- **A step runs out of memory.** The measured peaks are in the table above. Close other programs.
- **Anything else.** Run `bash reviewer/selfcheck.sh --keep`. It keeps the scratch directory, with
  each step's full output in `.selfcheck/step_N.log`. To report it, keep that log,
  `reviewer/PACKAGE_VERSION`, and your `gcc --version` and `python3 --version`, and tell us what
  differed before you change any expected value.

## Credit

Nothing here is new as a method. Publishing commands and digests instead of data is ordinary
artifact-evaluation practice, and the plain dynamic program, the Burnside count and the
one-by-one enumeration in steps 3, 6, 11 and 12 are standard techniques. The project's sources are
cited in the full repository's
[CITATIONS.md](https://github.com/petersm3/roae/blob/main/documentation/CITATIONS.md) (not
included; needs network).

For a step-by-step walk through the same counts on a laptop, starting from a clone and explaining
why each step is there, see the
[capstone guide](https://github.com/petersm3/roae/blob/main/reports/CAPSTONE_GUIDE.md).

*The project and this package are maintained by Matthew Peterson, the author named in
`CITATION.cff`; please send corrections to him. The package was prepared by Claude (Opus 5.5),
2026-10-01, and revised 2026-10-02 and 2026-10-03 after reviews by Codex (PKG-V1 and PKG-V3).
Developed with AI assistance (Claude, Anthropic).*
