# VERIFY.md — reproduction batteries

> **⚠ MERGE NOTE — read before resolving a conflict on this file.** On `main` this filename holds
> a much longer document, *"the independent second instruments (`verify.py`, `verify.c`)"*, added
> in `817ee95f`. That commit is **after** this branch's fork point, so `VERIFY.md` does not exist
> in this branch's history and this file is a **new add** here, carrying one section only. It
> deliberately does **not** copy `main`'s text: that text documents `verify.c` modes which do not
> exist on this branch, and importing it would publish claims this tree cannot back.
> **At merge, APPEND the section below to `main`'s file — do not let it replace `main`'s.**
> `git merge` will report an add/add conflict; the correct resolution is concatenation.

---

## TR-12 query program — what a reproducer runs, in what order, on what hardware

*Added 2026-08-22 on branch `v4-query-program`. Authority for individual flag syntax is
[SOLVE_C_CLI.md](SOLVE_C_CLI.md) and [SAT_CLI.md](SAT_CLI.md); this section is the **battery and
its order**, which no per-flag reference states.*

### Scope, stated before any command

**Constraint scope.** Every quantity below is computed over **SUPER = C1∩C2∩C4∩C5**, the frozen
v4 constraint set that the knowledge compiler compiles. **C15** (C1–C5, i.e. C3 applied) is a
*membership gate*, not a counting space: exact C3-conditioned counting is an open obstruction, so
C15-scoped results are estimates-with-CI, witnesses, or filtered enumerations — **never exact
counts**. Any output that mixes the two without a space label is a defect, not a result.

**Units gate.** True C3 ≤ 776 ⟺ the walk functional `--kc-c3-max 387` at full 31 pairs
(`cd_true = 2·(walk_cd+1)`). Pass **387**, never 776. Passing 776 silently doubles the ceiling.

**Constraint-freeze hedge (standing, required wherever this program's results are stated).** The
v4 constraint set was declared final on 2026-08-22. *"Final" means frozen by operator decision
after auditing every source available at freeze time — **not** a claim that no unexamined source
contains a further constraint, which no finite audit could establish.* **These results are final
at freeze time, not exhaustive.** If a constraint is later found it forks a v5-class definition
(or becomes a labelled in-path filter, as C3 already is); it does **not** invalidate these
artifacts, which remain exact for their stated C1–C5 scope — of which any later space is a subset.

### Stage 0 — build and the sha gate

Any machine. ~11 s to compile, ~30 s for the selftest on 2 cores. Reads no campaign data.

```bash
gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz
./solve --selftest
bash scripts/pre_push_compile_gate.sh
```

**Verdict: exit status 0** from both. `--selftest` compares against a sha compiled into the binary
itself; the gate additionally requires a clean `-Wall -Wextra` build. The query subcommands are
argv-dispatched and **never run inside `--selftest`**, so the selftest sha must be *unchanged* by
any query-program work — capture your own baseline with `./solve --selftest | sha256sum` before
editing and compare after. **Never copy a sha out of a document**, this one included.

### Stage 1 — the n=9 reduced-universe battery

**This is the whole correctness argument, and it costs nothing.** Any 2-core machine; no campaign
data, no disk, no network; every command below returns in well under a second. A reproducer with
no access to the ladders can still run all of it.

Order matters — ladders before their consumers:

```bash
A=$(mktemp -d); mkdir -p "$A"/f "$A"/g "$A"/t
./solve --kc-build   "$A"/f --f1-pairs 9      # f ladder: prefixes reaching a state
./solve --kc-g-build "$A"/g --f1-pairs 9      # g ladder: completions from a state
./solve --kc-t-build "$A"/f "$A"/t            # t ladder: search-tree node counts
./solve --kc-g-check "$A"/f "$A"/g            # Sum orbit*f*g == N at every layer
./solve --kc-t-check "$A"/f "$A"/t            # the f*t node identity at every layer
./solve --kc-scan    "$A"/f "$A"/g "$A"/atlas.json --kc-tdir "$A"/t --kc-raw   # --kc-raw is auto at n<=9 but pass it always: see step 3
python3 verify.py --check-atlas-orbit-frames "$A"/atlas.json   # cross-frame gate; see below
```

**`verify.py --check-atlas-orbit-frames ATLAS.json`** (added 2026-08-23). Emits
`ATLAS_ORBIT_FRAMES=PASS|FAIL`; exit 0 / 1, or 2 with `=SKIP` if the atlas carries only one frame
(pass `--kc-raw`).

The atlas publishes each layer's marginals in two frames — **canonical-quotient** and **raw** — and
the engine's own gate checks only that each frame's layer *total* equals `N`. **A total is blind to
mass moved between pairs**, so a quotient distribution can be wrong in every cell and still pass.
Both frames describe the same walks, so aggregating either over a whole symmetry **orbit** must give
the same number; the raw frame is already gated against brute force at n=9, which makes it a usable
reference for the quotient frame.

**Why it is an independent check and not a second opinion:** `verify.py` derives the orbit partition
itself — bit-position permutations commuting with line reversal (the centralizer of reversal in
S₆, order 48), pushed down to an action on the 32 pairs, then union-found — and it recovers which
orbits the subset contains from the atlas's own raw keys. It imports no orbit table and no union
spec from the engine. An oracle that read the engine's orbit table could not detect a wrong orbit
table.

⚠ **Stated limit.** This catches mass moved **across** orbits, not **within** one. It is a necessary
condition, not a sufficient one. It was verified able to fail: a single-unit cross-orbit shift that
leaves the layer total exactly equal to `N` is rejected, while the same shift **within** an orbit is
not detected — and that is a real gap, not a rounding tolerance.

Then the gates. Each is self-contained and synthesises its own fixtures:

```bash
for g in --kc-g-selftest --kc-t-selftest --kc-scan-selftest --kc-o3-selftest \
         --kc-oracle-selftest --kc-ladder-selftest --kc-cert-selftest \
         --kc-ar2-selftest --check-arrangement-selftest; do
    ./solve "$g" >/dev/null || { echo "GATE_FAILED=$g"; exit 1; }
done
```

**Verdict tokens — read this before writing any harness.**

| gate | how to decide it |
|---|---|
| `--kc-enum-desc-selftest` | `grep -qx 'KC_ENUM_DESC_SELFTEST=PASS'` — a real `KEY=value` token |
| all nine gates in the loop above | **exit status** (`0` = pass, `1` = failure) |

The nine loop gates print a human line of the form `[kc-scan-selftest] PASS (0 failures)`. **That
is output shape, not a verdict — do not grep it.** Gating on shape is what the project's verdict
rule forbids: the line can be reformatted without any behaviour change, and a harness matching it
would then pass a broken build. Each gate's `return fails ? 1 : 0` is the contract. Where a
`KEY=value` token exists, match it with `grep -qx` and nothing looser — `grep PASS` matches
`KC_ENUM_DESC_SELFTEST=FAIL` inside a surrounding "expected PASS" message.

**A gate that has never been observed to fail does not count.** Before trusting any of the above,
break one deliberately (corrupt a byte in a built ladder, or pass a mismatched `FDIR`/`GDIR`
pair), confirm the non-zero exit, restore, and confirm zero. The n=9 universe makes this free.

### Every published EXACT count — the command that produces it

**No exact count is published in this project without the command that reproduces it.** Three of the
four are reproducible on any laptop in under a second; the fourth is not, and that is stated rather
than hidden.

| n | exact count | reproduce | build | count |
|--:|---|---|--:|--:|
| 9 | `26112` | `solve --kc-build D --f1-pairs 9 && solve --kc-count D` | 170 ms | 9 ms |
| 13 | `2063395607040` | `solve --kc-build D --f1-pairs 13 && solve --kc-count D` | 352 ms | 9 ms |
| 16 | `267765117419520` | `solve --kc-build D --f1-pairs 16 && solve --kc-count D` | 753 ms | 15 ms |
| **31** | **`1097051278789181790036112071176579186688`** | `solve --kc-count FDIR` against a **completed Stage F ladder** | ⚠ see below | 10.3 s |

*(measured on a 2-vCPU D2as_v6; ladder sizes 156 KB / 1.6 MB / 12 MB)*

**Independent checks anyone can run on all four, with no ladder at all:**
```bash
python3 -c "N=1097051278789181790036112071176579186688; print('N mod 24 =', N % 24)"   # must be 0
```
`24 | N` is forced by the TR-5 automorphism theorem. It is an **external** constraint — the count had
no obligation to satisfy it, so it is evidence rather than a restatement. All four counts pass.

⚠ **The n=31 count is NOT laptop-reproducible, and the honest statement is that reproducing it means
rebuilding the ladder.** `--kc-count` itself is a 10-second manifest-and-total read, but its input is
a ~2.6 TB retained-layer ladder produced by the Stage F campaign over weeks of cloud compute. What a
reader CAN do without that:
- **Run the identical code path at n=9/13/16** (above) — same builder, same reader, same arithmetic;
- **check `N mod 24 == 0`** (one line, no data);
- **compare against the independent Monte-Carlo estimate** `1.0971×10³⁹` published in
  `SEARCH_SPACE_SIZE.md` — agreement is **0.0044 per cent**;
- **check the two ladders against each other**: the forward f ladder (`--kc-count`) and the
  **backward g ladder** (`--kc-g-build`, which prints `g0=`) are built by different recursions from
  opposite ends and return the identical 40-digit value.

**Ladder provenance for the published n=31 count** — quote these when citing it:
`f1c5_manifest_v1`, `n=31`, `start_exit=0`, `pl_hash=da2d4756d0535d0e`, `b0=2,8,13,7,1`,
`last_complete_k=31`.

### Stage 2 — full-31 queries against mounted ladders

**Not reproducible on a laptop.** This stage needs the three on-disk ladders (f from Stage F, g,
and t) attached to a worker-class machine. Point queries need **f and g**; the exhaustion-atlas
tables additionally need **t**.

Run order is chosen so that cheap, durable results are banked before anything long-running can be
interrupted:

1. `./solve --kc-scan-selftest` — **stop here if it fails.** Never run a priced pass on a binary
   that fails its own free gate.
2. **Point queries (minutes, bankable):** `--kc-rank` / `--kc-unrank` (REL order),
   `--kc-o3-rank … --kc-trace --kc-bracket` (citable O3 order, per-position f·g descent trace,
   neighbour-bracket certificate), `--kc-member`, `--kc-sample`, `--kc-midn`,
   `--check-arrangement KW --cert-out FILE`.
3. **The scan (long):** `./solve --kc-scan FDIR GDIR atlas.json --kc-tdir TDIR --kc-raw`.
   🔴 **`--kc-raw` is REQUIRED at n=31 and is not optional.** `kc_scan_main` auto-enables raw
   expansion only when `n <= 13`. Omit it at n=31 and `marginal_raw` is never written — **figure V1
   is silently absent, and the atlas still reports `gates.fails = 0`**, because the raw gate
   degrades to the string `"not-emitted"` rather than failing. A 48-85 h unresumable pass would
   complete, look clean, and be missing a named figure.
4. **Atlas-derived tables (milliseconds):** everything downstream reads the emitted JSON.

**Hardware and cost, honestly labelled.** Sizing guidance from the project's own instrumented
runs, **not reproducible figures** — they depend on the disk class, the machine and what else it
was doing, so reproduce them by timing your own run rather than by citing these:

| quantity | observed | how to read it |
|---|---|---|
| f-ladder size | ~3.1 TB at full 31 | plan storage, not a claim |
| streaming rate | ~128 MB/s | earlier planning assumed ~2 GB/s and was wrong by ~16× |
| descent cost | ~12.5 s/row cold → ~1 s/row warm | two-phase; a cold first query is not representative |
| `--kc-g-check` | measurably **single-threaded** | core count buys nothing here; size the VM for I/O |
| full scan wall | ~48–85 h, **no resume flag** as of 2026-08-22 | a preemptible instance is unlikely to survive it |

The atlas JSON stores all counts as **decimal strings** (they exceed 64 bits — 192-bit values at
full scale), not JSON numbers. Parse with an arbitrary-precision integer type; a naive JSON
float parse silently loses precision.

### What passing this battery does and does not establish

- **Does:** that the ranking, scanning and ladder code agrees with exhaustive brute force on a
  complete small universe, and that the f/g/t ladders satisfy their cut identities layer by layer.
- **Does not:** say anything about the *contents* of the full-31 artifacts. Completeness of an
  enumeration is attested by its canonical sha, not by a forward pass.
- **Does not:** upgrade any C15-scoped estimate to an exact count.
- Emitted certificates are **certificates, not proofs** — they state what was checked, by which
  build, over which scope, and are re-derivable by a reader; they are not a proof of the claim.

Every published number from this program must carry its command line, the build identity
(git hash + source sha), the layer-directory sha registry, its `#provenance` scope line, and the
reader-side re-derivation. A number without its reproduction command is not published, it is
asserted.

*Section by Claude (Opus 5), 2026-08-22. Developed with AI assistance (Claude, Anthropic).
Technique-level prior art is classical throughout (Nijenhuis–Wilf ranking; knowledge-compilation
query taxonomies) — no novelty is claimed for any mechanism, only for the instantiation and the
exactness discipline. Errors are Claude's; corrections invited.*

---

## `scripts/tr12_repro.sh` — the whole battery as one command

*Added 2026-08-22 on branch `v4-query-program`. TR-12 §R step 6 / §8 item 13.*

Everything above is a list of commands a reproducer runs by hand. This is the same list as a
driver: it runs **every** TR-12 query against named ladder directories, diffs each output against a
committed expected-output block, and **exits non-zero on any mismatch**. Shell only — it adds no
`.c` and no `.py` file, and calls `solve`, coreutils, `awk`, `sed` and `bc`.

```bash
scripts/tr12_repro.sh --n9                         # self-contained: builds its own n=9 f/g/t
                                                   # ladders, ~90 s on two cores, no campaign data
scripts/tr12_repro.sh --fdir F --gdir G --tdir T   # full-31 against the mounted ladders
scripts/tr12_repro.sh --n9 --regen                 # re-mint the expected blocks, then READ the diff
scripts/tr12_repro.sh --help                       # every flag and environment knob
```

**Exit status** — `0` every executed row matched (`TR12_REPRO=PASS`); `1` a mismatch, a non-zero
row, or a missing expected block (`TR12_REPRO=FAIL`); `2` usage or environment error.

**Run order is fixed and is not a preference.** `A0` (no ladder) → `A1` (f) → `A2` (f+g) →
`B` (the scan) → `C` (atlas-derived). `--kc-scan` is one 48–85 h pass with no resume flag that
writes its atlas *once, at the end*, so an interruption at hour 47 yields nothing; everything cheap
is therefore banked before it. Ordering costs zero and is the cheapest crash insurance available.
The script offers no flag to reorder it. Q3, the Q3 reader check, EW-1 and V4 are **pre-scan** —
they need f+g and no atlas at all.

**Verdicts** are `KEY=value` lines in `$OUT/VERDICTS.txt`, matched with `grep -qx` and never by
output shape:

```bash
grep -qx 'TR12_REPRO=PASS'          "$OUT/VERDICTS.txt"   # the battery
grep -qx 'TR12_Q3_READER=PASS'      "$OUT/VERDICTS.txt"   # one row
grep -qx 'TR12_REPRO_COMPLETE=YES'  "$OUT/VERDICTS.txt"   # ... and nothing was skipped
```

Skipped values are short and machine-matchable — `SKIP:doc-only`, `SKIP:wave3-not-budgeted`,
`PENDING:--kc-coset-census` — with the long human reason on a separate `<TOKEN>_REASON` line.

**A skip is not a pass, and the script will not let it look like one.** Every row that cannot run
is printed in a `SKIPPED` block with its reason, `TR12_REPRO_SKIPPED=<n>` and
`TR12_REPRO_COMPLETE=NO` are emitted, and a parent token with a skipped leg is downgraded to
`SKIP:leg-<child>` rather than reporting `PASS` with a hole in it. A universe with **no** expected
blocks at all is a `FAIL`, not a vacuous pass.

**Reader arithmetic is separated from engine attestation.** `--kc-o3-rank --kc-trace` prints
`product(p_i)=1/N EXACT` — that is the *engine* grading its own homework. Row `a2_q3_reader`
re-derives it from the emitted `p_num`/`p_den` columns instead, as three exact integer identities
(`p_den₁ = N`, `p_denᵢ = p_numᵢ₋₁`, `p_numₙ = 1`), and reports `TR12_Q3_READER` separately.

**The n < 31 anchor is a stand-in and is labelled as one.** Q1/Q1b/Q1c/Q3/EW-1/V4 are all "…of
KW", and KW exists only at n = 31. In a reduced universe the driver uses `unrank_O3(⌊N/2⌋)` and
prints `anchor_label=O3-MIDPOINT(...)` in the artifact. Nothing from a reduced run is ever reported
as a King Wen result.

**Shown able to fail** (this is required of it, not optional): corrupting one digit of one expected
block, deleting a block, changing the sampling seed, or passing the banned C3 value `776` instead
of the walk-functional gate each produce a named `FAIL` row and exit `1`; restoring returns exit
`0`. Reproduce any of them in seconds against the n=9 universe before trusting the battery.

The blocks live in `scripts/tr12_expected/n<N>/` — see that directory's `README.md` for what is and
is not normalised before a diff.

*Section by Claude (Opus 5), 2026-08-22. Developed with AI assistance (Claude, Anthropic). The
driver is a certificate of what the binary does on a named universe, not a proof. Errors are
Claude's; corrections invited.*
