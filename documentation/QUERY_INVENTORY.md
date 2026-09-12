# QUERY INVENTORY — the executable contract for the TR-12 query program

> ### PUBLIC DRAFT — 2026-09-05
> This is the **public-safe** derivation of the project's internal `QUERY_INVENTORY.md`, prepared
> so that an external query-set (QSET) reviewer can see **the whole question set**, not the ~quarter
> of it that the TR-12 draft covers. TR-12 carries **9** numbered question sections; §2 of this file
> carries **35** question rows — Q1, Q1b, Q1c, Q2, Q2b, Q2c, Q2d, Q3, Q4a/c, Q4b, Q5, Q6, Q7, Q8,
> Q9, V1–V5, XA-iii, XA-a, XA-b, XA-c/d, XA-24, LS-w0, LS-forced8, LS-exact, LS-audit, LS-cite,
> EW-1, EW-gov, Q10a, Q10b, Q4-Gexact — plus **9** capability rows in §1 (the `PENDING:` table) and
> a **36**-step run order in §5. (Counted 2026-09-05 by enumerating the bolded row labels between the §2 and §3 headings; an
> earlier tally of "39" is not reproducible against the file and is superseded by this one.) **A
> review that returns findings on nine questions and silence on the other twenty-six cannot be told
> apart from approval** — that is why this file ships alongside TR-12 rather than after it.
>
> **Four passes were applied to produce it**, each recorded in the appendices:
> (1) a novelty scrub under the publication freeze (Appendix A), (2) a figure → reproduction-command
> audit (Appendix B), (3) a private-reference sweep that replaces internal pointers with **public
> anchors** — a committed document, a runnable command, or a code site — and reports a **FINDING**
> wherever no public anchor exists (Appendix C), and (4) an infrastructure/cost scrub: no mount
> points, host or storage identifiers, and **no monetary figures at all** (Appendix D).
>
> **Reading conventions for this draft.**
> `🔎 PUBLIC ANCHOR:` marks a claim re-pointed at something a reader can run or read in the public
> repository. `🔻 FINDING:` marks a claim whose only support is an internal artifact — it is
> disclosed as such and **not** dressed up in generic prose. Internal tracker identifiers (`Q-nnn`,
> `QL-n`, `A-nn`, `D5-nn`, `W0-D`, `S-B`, `D6`) are retained as stable labels; they have no public
> resolution and are not evidence — see Appendix C.
>
> **`<sha>` in a command is a placeholder — substitute a commit-ish before running it.** For any
> claim about the tree as it stands, `main` works. Where a row is about a state that has since
> changed, the row names its own sha or tag and that one is the authority: `453e1bf5` (the sha this
> file was written against), `archive/v4-query-program-20260829` (§8), `9d7de84c` (§9). This is
> stated up front because the same standard applies to it as to the branch names above — **a
> placeholder that does not resolve is not a reproduction instruction either.**

**2026-08-22. Claude (Opus 5). Developed with AI assistance (Claude, Anthropic).**
Public draft prepared 2026-09-05 from the 2026-08-22 original. All verification commands below run
against the **public** repository. The working branch this file was written on (`v4-query-program`)
has since been **merged into `main` and its ref deleted**; its content *is* `main`, and the exact
pre-merge trees are preserved as tags. Verify:
```
git show <sha>:documentation/BRANCH_REGISTRY.tsv | grep -n v4-query-program
git ls-remote --tags origin | grep v4-query-program
#   archive/v4-query-program-20260824   archive/v4-query-program-20260829
#   premerge/v4-query-program-20260903  merged/v4-query-program-20260904
```
Every branch-relative citation in this draft has therefore been **re-pinned to a commit sha or a
tag**, because a branch name that no longer resolves is not a reproduction instruction.

> **What this file is.** One row per item of the TR-12 query specification — Q1–Q9 (§1),
> V1–V5 (§2), XA (§3), LS (§4), EW-1 (§5), Q10 (§11) — giving the exact command line, the ladders
> it mounts, its cost class, its output artifact, and its verdict token; then the **run order**.
> Later agents build against this file. Where the spec is ambiguous this file **decides** and says
> so; where a flag does not exist it is marked `PENDING:<flag>` and nothing pretends otherwise.
>
> **Authorities it obeys.** The query specification itself (TR-12 §1/§2/§3/§4/§5/§11 — what to
> ask), its invariants brief, its wave ruling (§7) and its not-report-grade ruling (§9 — scope),
> a measured cost/wall addendum, the scan preconditions, and a landing-day sequence
> **corrected in §6 below**.
> 🔻 **FINDING (C-01): these six authority documents are not public.** They are internal planning
> records, so a reader cannot check that this file obeys them. What a reader *can* check is the
> **executable** consequence: `scripts/tr12_repro.sh` implements this file's §5 run order row by
> row and names it in its own header, and `scripts/tr12_repro_gate.sh` gates the result.
> 🔎 **PUBLIC ANCHOR:**
> ```
> git show <sha>:scripts/tr12_repro.sh | sed -n '20,70p'   # names QUERY_INVENTORY.md as its contract
> git grep -n QUERY_INVENTORY <sha> -- scripts/            # the public tree cites this file by section
> ```
> Publishing this file closes those dangling public references.

---

## 0. Conventions this file fixes (bind these before writing any driver)

### 0.1 Shell variables used by every command in the table
```bash
SOLVE=<path to the solve binary>   # built from the query-program lineage (now merged to main);
                                   # record the BINARY GIT_HASH, not a launcher pin
FDIR=<f-ladder directory>          # Stage F  f-ladder  (32 layers)
GDIR=<g-ladder directory>          # Stage G  g-ladder  (32 layers)
TDIR=<t-ladder directory>          # Stage T  t-ladder  (32 layers)
OUT=<artifact root>                # mkdir -p $OUT $OUT/scan $OUT/gallery $OUT/viz
VERD=$OUT/VERDICTS.txt             # one KEY=value line per row (see 0.3)
```

### 0.2 Literal constants (do not re-derive; computed 2026-08-22 and checked `N mod 24 == 0`)
```
N      = 1097051278789181790036112071176579186688      # |SUPER|, TR-11 §9
N-1    = 1097051278789181790036112071176579186687
N/2    = 548525639394590895018056035588289593344       # floor
N/24   = 45710469949549241251504669632357466112        # exact integer  (Q10(a) global gate)
T_C3   = 387        # the CT1.6 WALK-FUNCTIONAL C3 gate. NEVER 776 on --kc-c3-max.
GALSEED= 9276183659154465378                            # Q8 gallery seed (see 0.4)
```

### 0.3 Verdict tokens — `KEY=value`, matched with `grep -qx`, never output shape
Every row emits **exactly one** line into `$VERD`. Checked as
`grep -qx 'TR12_Q1=PASS' "$VERD"`. Values are `PASS` / `FAIL` / `SKIP:<reason>` /
`PENDING:<flag>`. The aggregate `QUERY_PROGRAM=PASS` is emitted **only** if every non-`SKIP`
token in scope is `PASS`. The n=9 rehearsal of this same driver emits `QUERY_DRYRUN=PASS`
(names carried over from the readiness plan's §2 P1/P3 — do not rename them; they are the
token names the public battery greps for).

### 0.4 Two ambiguities in the spec, DECIDED here (do not re-litigate)
1. **Q8's seed.** TR-12 §Q8 pins the seed as the *string* `TR12-GALLERY-1`; `--kc-sample` takes a
   `uint64`. **DECIDED:** `seed = int(sha256("TR12-GALLERY-1").hexdigest()[:16], 16) =
   9276183659154465378`. Reproduce with
   `python3 -c "import hashlib;print(int(hashlib.sha256(b'TR12-GALLERY-1').hexdigest()[:16],16))"`.
   The string stays the human label; the integer is what ships in the command.
2. **Arrangement → walk adapter (Q7 ranks).** A 64-hexagram arrangement becomes a `--kc-*` walk
   string by **dropping the first two values** (the C4-anchored pair `63,0`) and passing the
   remaining **62** as `"e,x,e,x,…"`. Verified against `kc_h_kw_walk` — 🔎 **PUBLIC ANCHOR:** `git grep -n "kc_h_kw_walk" <sha> -- solve.c` (`solve.c:21246` at `453e1bf5`, the sha this file was written against) ("the anchor
   pair (63,0) is slot 0 and not part of the walk") and `kc_parse_walk` (`solve.c:20043` at `453e1bf5`; find it at any sha with `git grep -n "static int kc_parse_walk" <sha> -- solve.c` — it has moved, so cite the symbol, requires
   exactly `2n` values). No flag needed; **this is the adapter, write it once in the driver.**
3. **The literal string `KW` is accepted by only SOME subcommands. VERIFIED, and it bit this
   document's own first draft.** `kc_h_resolve_walk` (`solve.c:21264` at `453e1bf5`; 🔎 **PUBLIC ANCHOR:** `git grep -n "kc_h_resolve_walk" <sha> -- solve.c`) resolves `"KW"` — it is
   reached by **`--kc-o3-cert`** and **`--kc-ar2`** only. Everything else (`--kc-o3-rank`,
   `--kc-o3-unrank`, `--kc-rank`, `--kc-member`, `--kc-repr`) calls `kc_parse_walk` directly and
   **rejects `KW`**: at n=9, `--kc-o3-rank F G KW --kc-trace` returns
   `ERROR: [kc] walk needs 18 hexagrams (entry,exit per pair), got 0`. **DECIDED:** the driver
   computes the walk string once —
   `KWW=$(python3 -c 'import solve;print(",".join(map(str,solve._r7_kw()[2:])))')`, 62 values,
   beginning `17,34,23,58,…` — and passes `"$KWW"` everywhere except `--kc-o3-cert`.

### 0.5 Effort classes used in the table
Monetary figures are **deliberately absent from this public draft** (Appendix D). What survives is
the *shape* of each class — whether it mounts a ladder, and the order of magnitude of its wall —
because that is what a reviewer needs in order to judge whether a question is answerable.

| class | meaning | wall, order of magnitude |
|---|---|---|
| **DOC** | writing/arithmetic only, no binary, no ladder | none |
| **NOLADDER** | runs the binary but mounts **no** ladder — runnable on any workstation | seconds |
| **POINT** | ladder-mounted, single descent/lookup batch | seconds–minutes |
| **POINT-BATCH** | many descents; pays a two-phase cold/warm law — the first rows are ~an order of magnitude slower than the steady state, so **keep a batch in ONE process** | minutes–hours |
| **SCAN** | the one long pass over the ladders. 🔴 Its read volume was **restated upward by ~1.5 orders of magnitude on 2026-09-05**; the wall is measured in **days, not hours**, and there is no checkpoint in a single unchunked pass. Chunk it with `--kc-layers A B` + `--kc-scan-merge`. See the note under this table | days |
| **DERIVED** | pure post-processing of `atlas.json` (a few KB at n=9, tens of KB at full-31) | milliseconds |

🔴 **CORRECTED 2026-09-05 — the scan's read-volume figure this row carried until today was wrong by
more than an order of magnitude, and the error is instructive.** It descended from a **single
unsourced comment on a default constant in a progress-estimator script**, and it was wrong twice
over: its `f` term was a stale pre-measurement estimate rather than the measured ladder size, and it
assumed `--kc-scan` *streams* the g ladder when in fact `--kc-scan` makes **random point lookups**
into g. Consequences: the wall is **days, not hours**; the single attempted pass was a low
single-digit **percentage** complete, not roughly a quarter; and that attempt was **deliberately
stopped to free its host for an archival upload** — not a crash, not a pre-emption, not a failure.
🔻 **FINDING (C-02): the corrected read-volume and wall figures have no public reproduction
command.** They are a re-derivation over private storage measurements. They are therefore **stated
as a direction and an order of magnitude only** in this public draft, and the numbers are withheld
rather than published unreproducibly (Appendix B, class *no-command → withheld*). The *structural*
half of the correction **is** publicly checkable: that `--kc-scan` point-looks-up rather than streams
g is readable in the source — 🔎 **PUBLIC ANCHOR:**
`git grep -n "kc_scan_main\|kc_g_lookup" <sha> -- solve.c`.

⚠ **What did NOT change:** `--kc-scan` is still the one long pass, it still has no checkpoint when
run unchunked, `--kc-raw` is still mandatory at n=31, and the requirement that the g ladder sit on
storage fast enough to be distinguishable from a hang still stands — the throughput measurement that
motivated it was genuine.

### 0.6 Gate status — verified by execution 2026-08-22 on this branch, `-O2` scratch build
All twelve self-tests run clean at n=9 (`--check-arrangement-selftest --kc-selftest --kc-o3-selftest
--kc-g-selftest --kc-t-selftest --kc-cert-selftest --kc-ladder-selftest --kc-ar2-selftest
--kc-oracle-selftest --kc-scan-selftest` → each `PASS (0 failures)`; `--kc-t-cert` → `PASS`,
n=9 EXHAUSTIVE per-state + n=13 spot). These are the **existing** brute-force gates; every
`PENDING:` row below names the **new** n=9 gate it must ship with, per invariant 3.

---

## 1. What ALREADY EXISTS vs what is PENDING (verified on source + compiled binary, this branch)

**EXISTS and executed at n=9 today:** `--kc-build --kc-g-build --kc-t-build --kc-t-check
--kc-t-cert --kc-scan --kc-scan-selftest --kc-count --kc-rank --kc-unrank --kc-member --kc-repr
--kc-sample --kc-enum --kc-o3-rank --kc-o3-unrank --kc-o3-cert --kc-ar2 --kc-g-check --kc-oracle
--kc-ladder-verify --kc-midn --kc-oocverify --check-arrangement --f1c5-layer-sha --c3-min
--c3-dist --null-historical --null-pair-constrained`, modifiers `--kc-tdir --kc-raw --kc-trace
--kc-bracket --kc-c3-max --kc-limit --kc-record --kc-class-uniform --kc-cert-out --kc-ooc
--kc-cache-mb --kc-g-ooc`.

**ABSENT everywhere (`PENDING:`):**

| PENDING id | what it is | who needs it | n=9 gate it must ship with |
|---|---|---|---|
| ~~`PENDING:atlas-consumer`~~ **LANDED 2026-08-22 (§8.1)** | landed **inside `solve.py`** (`def atlas_queries`), NOT as `scripts/atlas_queries.py` (single-file rule). 🔎 **PUBLIC ANCHOR:** `git grep -n "def atlas_queries" <sha> -- solve.py` — the line number has moved with the file, so cite the symbol, not the line; driven by `scripts/tr12_repro.sh` row `c_consumer`. | Q6, V1, V2, V5, XA, Q10(a) | every emitted TSV re-derived from `fixtures/kc_n9/atlas_n9.json` and diffed against a brute-force recount at n=9; **break one column, observe FAIL, restore, observe PASS** |
| ~~`PENDING:--kc-enum-desc`~~ **LANDED (§8.2)** | descending in-order enumeration — emits `KC_ENUM_DESC=OK\|FAIL`; n9 expected block `a1_q2d.txt` | Q2 LAST^C15 only | at n=9, `--kc-enum-desc --kc-limit 1` == last line of full `--kc-enum`; shown able to fail |
| ~~`PENDING:--kc-extremal`~~ **LANDED as a flag (§8.3); the COST GATE stands** | per-functional DP extremal sweep + witness (`--kc-witness --kc-json`); n9 block `a1_q5.txt` | Q5 only — still SKIP:wave3-not-budgeted, **and at n=31 also blocked by the unbuilt OOC extremal builder (R5, 2026-09-11): `--wave3` exits 2** | exhaustive n=9/n≤13 extremal must match; **Wave 3, NOT BUDGETED** |
| `PENDING:--kc-coset-census` | (ℤ/2)⁶ coset labelling of the transversal, aggregated over the scan tables | Q10(b) only | Σ over cosets == layer mass at n=9; exhaustive n≤13 orbit counts |
| `PENDING:sat-c3min-driver` | bisection loop on integer G over `sat.py --witness plain --with-c3 --c3-max <16+8G>`, with DRAT retention | Q4(b) | reduced-n bracket reproduces a known witness; UNSAT leg checked by `drat-trim` |
| ~~`PENDING:--kc-layers A B`~~ **LANDED (§8.4)** | chunked/restartable scan + `--kc-scan-merge`; chunked==whole identity block `b_chunked.txt` | the SCAN — Group B premise changed, see §8.4 | chunked atlas == whole atlas at n=9, **shown able to fail first**; `--kc-scan-selftest` still 10/10 |
| ~~`PENDING:tr12_repro.sh`~~ **LANDED (§8.5)** | public `scripts/tr12_repro.sh` + `tr12_repro_gate.sh` + `scripts/tr12_expected/n9/` | reproduction section | non-zero exit on any mismatch, demonstrated |
| ~~`PENDING:viz/viz_kc_*.md`~~ **LANDED (§8.6)** | all five `viz/viz_kc_*.md` + `viz/report_figures.py::tr12_figures` | V1–V5 rendering | figures regenerate byte-stably from the committed TSVs |
| `PENDING:kissat` | external SAT solver, **not on PATH** (`which kissat` empty; `d4`, `cpog-gen`, `drat-trim` also absent) | Q4(b) | n/a — an install, not a gate |

⚠ *(OVERTAKEN 2026-08-29, §8.7: `--kc-profile` WAS subsequently built — with `--kc-profile-selftest` — and is O3-independent, which matters for the Q-331 labeling degeneracy. The subsumption argument below is retained as history.)* ⚠ **`--kc-profile` is NOT needed.** TR-12 §8 item 5 lists it as TO-BUILD; it is **subsumed by
`--kc-o3-rank … --kc-trace`, which exists and works.** Verified at n=9: the trace prints
`step / pair / entry / exit / orient / alts / mass_below / f / g / g_parent / p / bits` per step
plus a `#o3-trace-summary` line asserting `g(s_0)=N VERIFIED`, `g(s_n)=1 VERIFIED`,
`flow_identities=n/n`, and `product(p_i)=1/N EXACT`. **Do not build `--kc-profile`.** ⚠ But note `--kc-o3-rank` needs the **explicit walk string**, not `KW` — §0.4(3).

---

## 2. THE INVENTORY

### 2.0 🔴 NOT IN SCOPE for this run — five rows, with the reason for each

These will **not** produce a number in the 80+ run. They are stated here rather than left reading
`PENDING`, which implies work in progress. Each row's reason is the one its own skip token carries in `scripts/tr12_expected/n9/_EXPECTED_SKIPS.txt`, so this table cannot drift from the harness.

| row | why it is out | cheap to reconsider? |
|---|---|---|
| **`TR12_Q4B`** | **ALREADY ANSWERED** — `min{C3(w) : w ∈ SUPER}` = **112**, witness `G=12 C3=112` published 2026-07-24 in `reports/certificates/c3_positional_witnesses.txt`. `G ≥ 12` is structural and the witness achieves it, so the bracket closes at its floor and the SAT bisection is **not needed for the minimum** (§Q4b, ruled 2026-09-05). ~~The battery still emits `PENDING:sat-c3min-driver` — a harness/ruling disagreement, not a missing tool~~ **2026-09-08 (F-5 D10): the battery row `a0_q4b` now RUNS `--check-arrangement` over every line of the certificate and over the G=12 witness in full, and `TR12_Q4B` is PASS on that computed fact (SUPER verdict IN, checker C3 = the line's stated C3, KW's step-distance histogram) or FAIL. The earlier skip reason "no 64-int sequence validator exists" was false — `--check-arrangement` is that validator, and row `a0_q7_hist` had been calling it all along** | **yes — it is done, and the harness now checks it** |
| **`TR12_V3_FIG`** | needs `spectrum/v3_spectrum.tsv`, a rank grid joined to per-walk functionals. **The rank grid IS produced** (`a1_v3` → `v3_rel_grid.tsv`); only the join is missing | **yes — a join** |
| **`TR12_Q7_WITNESSES`** | `kissat` is not on PATH, and installing it is **not sufficient**: which satisfying sequence a solver returns is **build-dependent**, so a golden of solver-chosen bytes would pin one build's arbitrary choice. The reproducible contract is a **property** of the returned witness, not its bytes | no — needs a contract decision first |
| **`TR12_Q10B`** | `--kc-coset-census` does not exist (`git grep -c` → **0**, re-confirmed 2026-09-05). The Ouyang coset lens is labelled **EXPLORATORY (EW-class, FRONTIER)** in TR-12 — it may show concentration or be flat, and flat is a result | no — a new subcommand |
| **`TR12_XA_CD`** | **doubly blocked**: the R-1 throughput anchors **and** a W0-D t-unit → `SOLVE_NODE_LIMIT` mapping certificate. The latter **cannot be produced at HEAD** — the production enumerator has no reduced-n mode (`solve.c:1705–1707`) — and even after W0-D the verdict is **one-sided**, since the production DFS prunes with C3 while t counts SUPER prefixes, so t-units bound nodes from above | no |

⚠ **Nothing here is a silent omission.** `solve.py` refuses to price XA-c/d without a mapping cert
(2026-09-07), and every row above is keyed to a token in the battery's own pinned skip set, so a row cannot
leave this list without the harness changing too.


Legend for **ladders**: `f` = FDIR, `g` = GDIR, `t` = TDIR, `—` = none.
Commands assume §0.1 variables. `2>&1 | tee` plumbing omitted for width; the driver adds it.

### §1 — the nine core queries

| id | must produce | exact command line(s) | ladders | class | artifact (format) | verdict token |
|---|---|---|---|---|---|---|
| **Q1** | `rank_O3^SUPER(KW)` exact + the r−1/r/r+1 neighbour bracket + the H3b certificate (`rank(unrank(r))==r`, `unrank(rank(KW))` byte-identical to KW, `#provenance`). | `$SOLVE --kc-o3-cert "$FDIR" "$GDIR" KW --kc-cert-out $OUT/q1_rank_kw.json --kc-ooc --kc-cache-mb 196608 > $OUT/q1_rank_kw.txt` | f+g | POINT | `tr12/q1_rank_kw.txt` (text) + `q1_rank_kw.json` (JSON) | `TR12_Q1=PASS` ⚠ **RULED 2026-09-04 (§9.1): DOC + GATE.** `rank3(KW)=0` is a labeling theorem (KW-derived `pl`/`pa`), executed at n=9 in miniature; the run must print `rank3=0, class_first_rank3=0, orient_idx=0` → **`TR12_Q1_LABELING=PASS`**; no rank/rarity statement about KW under O3 may be published; **Q1b (REL) is the reported coordinate**; O3′ stays PROPOSED. |
| **Q1b** | the REL-order second coordinate — a *different* order, reported and labelled, **never** conflated with O3. | `$SOLVE --kc-rank "$FDIR" "$(python3 -c 'import solve;print(",".join(map(str,solve._r7_kw()[2:])))')" --kc-ooc >> $OUT/q1_rank_kw.txt` | f | POINT | same file, labelled `order=REL` | `TR12_Q1B=PASS` |
| **Q1c** | `rank_O3^C15(KW)` as a **labelled ESTIMATE ±binomial CI**: M=10⁴ exact-uniform ranks drawn in `[0, rank_O3^SUPER(KW))`, C3-tested at `T=387`. | `$SOLVE --kc-sample "$FDIR" 10000 $GALSEED --kc-c3-max 387 --kc-ooc --kc-cache-mb 196608 > $OUT/q1_c15_estimate.tsv` — then p̂ and CI in `scripts/atlas_queries.py`. ⚠ `--kc-sample` draws over **all** of SUPER, not a rank prefix; the prefix restriction is post-filter arithmetic in the consumer. | f | POINT-BATCH (**3–5 h**, ADDENDUM §B P0) | `tr12/q1_c15_estimate.tsv` (TSV) | ~~`TR12_Q1C=PASS`~~ ~~**DESCOPED 2026-09-04 (§9.2): `TR12_Q1C=SKIP:merged-into-Q4AC`**~~ 🔴 **MEASURING PRODUCER 2026-09-10 (N3), value NOT YET PRODUCED AT n=31: `TR12_Q1C=EMPTY:interval-degenerate-at-n31`.** ⚠ **Read the distinction, because an earlier draft of this row got it wrong in exactly the way the row exists to prevent:** what is MEASURED is the **producer** — red-tested in both directions on real n=9 engine output. What the token asserts is the **expected** n=31 value, and **no n=31 run of this producer exists**, because the ladders have not been scanned. The advance over `SKIP` is real and narrower than "measured": `SKIP` could never become false, whereas this token is now **produced by a check that can refuse** — at n=9 it does refuse, returning `NONEMPTY:interval-cardinality-13056`. It becomes a measured null on the first full-31 run and not before. The descope token was right and *unchecked*: it ASSERTED that `[0, rank_O3(KW))` is empty at full-31 (§9.1). `SKIP` says we did not run it; the truth is we can run it and the answer is nothing, and those are opposite epistemic states. Row `a2_q1c` now measures the interval's cardinality before spending anything — `rank3` from `--kc-o3-cert` **and** from `--kc-o3-rank` (two subcommands, cross-checked) plus the certificate's own predecessor witness, all three artifacts already on disk, so the marginal cost is zero — and emits `EMPTY:…` only when the measurement is 0, `NONEMPTY:interval-cardinality-<c>` (then the estimate runs) when it is not, and `ERROR:<why>` when it cannot tell. Both directions are red-tested on **real n=9 engine output** by `scripts/n3_measured_nulls_gate.sh`: the O3-midpoint anchor has 13,056 objects below it and is refused, `unrank_O3(0)` has none and returns EMPTY. The uncommanded per-draw O3-rank leg and the merge of `P(C3 ≤ 387 \| SUPER)` into Q4a/c at M=10⁶ are unchanged. |
| **Q2** | **three O3 probes — two endpoints + a midpoint** — `unrank_O3(0)`, `unrank_O3(N−1)`, `unrank_O3(⌊N/2⌋)` in SUPER, exact, full 64-hexagram sequences + records + ranks. **COMPLETION IS DEFINED** (B7, 2026-09-07): all three must return `CERTIFICATE PASS` under `--kc-bracket`, which unranks r−1/r/r+1, ranks all three back and checks strict O3 order with an independent comparator (rc=1 on any failure); at the two endpoints its `r∓1: NONE` line is the endpoint certificate. ⚠ **That certifies the rank/unrank PAIR, not the ladder** — measured, a g ladder corrupted at 3 of 12 probed offsets fails `--kc-g-check` (rc=70) while the bracket still certifies PASS, because rank and unrank read the same wrong g. So completion **also** requires `TR12_GCHECK` and `TR12_GSHA` PASS, and at n≥31 the one external anchor: `unrank_O3(0)` byte-identical to King Wen. | `for R in 0 1097051278789181790036112071176579186687 548525639394590895018056035588289593344; do $SOLVE --kc-o3-unrank "$FDIR" "$GDIR" $R --kc-ooc --kc-cache-mb 196608; done > $OUT/q2_endpoints_o3.txt` | f+g | POINT | `tr12/q2_endpoints_o3.txt` (text) | `TR12_Q2=PASS` |
| **Q2b** | the same three in REL order (available from f alone; the Wave-1 coordinate). | `for R in 0 …N−1… …N/2…; do $SOLVE --kc-unrank "$FDIR" $R --kc-record --kc-ooc; done > $OUT/q2_endpoints_rel.txt` | f | POINT | `tr12/q2_endpoints_rel.txt` (text) | `TR12_Q2B=PASS` |
| **Q2c** | `FIRST^C15` — the in-order-least C3-passing walk (REL order). | `timeout "${TR12_Q2_ENUM_TIMEOUT:-21600}" $SOLVE --kc-enum "$FDIR" --kc-c3-max 387 --kc-limit 1 --kc-ooc > $OUT/q2_first_c15.txt` | f | POINT (hedged; wall-clock abort, `TR12_Q2_ENUM_TIMEOUT`) | `tr12/q2_first_c15.txt` (text) | `TR12_Q2C=PASS` |
| **Q2d** | `LAST^C15` — the in-order-greatest C3-passing walk. | `PENDING:--kc-enum-desc` → `timeout "${TR12_Q2_ENUM_TIMEOUT:-21600}" $SOLVE --kc-enum-desc "$FDIR" --kc-c3-max 387 --kc-limit 1 --kc-ooc` | f | POINT (hedged; wall-clock abort, `TR12_Q2_ENUM_TIMEOUT`) | `tr12/q2_last_c15.txt` (text) | `TR12_Q2D=PASS` *(flag landed 2026-08-2x — §8.2; was PENDING)* |
| **Q3** | KW's 31-step rarity profile: per step the chosen pair, #alternatives, f, g, g_parent, `p_i = g(s_i)/g(s_{i−1})`, `−log₂ p_i`; **and the printed self-check `Π p_i = 1/N`**. | `KWW=$(python3 -c 'import solve;print(",".join(map(str,solve._r7_kw()[2:])))'); $SOLVE --kc-o3-rank "$FDIR" "$GDIR" "$KWW" --kc-trace --kc-bracket --kc-ooc --kc-cache-mb 196608 > $OUT/q3_profile_kw.txt && grep '^#o3-trace' $OUT/q3_profile_kw.txt \| tr -s ' \t' '\t' > $OUT/q3_profile_kw.tsv` | f+g | **POINT** | `tr12/q3_profile_kw.tsv` (TSV) + `.txt` (raw, carries `#o3-trace-summary`) | `TR12_Q3=PASS` |
| **Q4a/c** | the C3 census over SUPER: histogram of cd\* + **μ_walk^SUPER** = P(C3 = 776) — ⚠ **the shipped μ is a WALK fraction over SUPER**, and the historical ~10.11% is a **record-level tie share over a 560T traversal prefix**; the two are not the same quantity. Measured at n=9, T=31: walk/SUPER **17.64%**, walk/C15 **66.6%**, record/SUPER **22.2%**, record/C15 **50.0%** (tie records carry 2× the multiplicity). **Also emit `μ_rec^C15`** via the project's ratified 1/m Horvitz–Thompson reweighting (`V4_RECORD_CONVENTION_DECISION_2026_07_14.md`), which recovers the exact record census to 0.2% at n=9 and needs only `--kc-record` on this row — `m` already ships. The C15 *estimate* needs no missing instrument (rejection on cd ≤ T); only the exact count does. Publish both, and the **difference against the 10.11% is itself reportable** as an estimate of the traversal's C3-tie bias — with ⚠ **one Wilson interval on the acceptance mass, not per-bin CIs — narrowed 2026-09-06 (QSET-2 finding 5); this is the unfixed half of the 2026-09-05 correction to the same row, which addressed only its space label** — **ESTIMATE with CI**; the exact version is not shipped — no instrument in this program counts
C3-conditioned, and the run that would was priced and declined on **cost**, not ruled out
structurally (TR-11 §10(ii) v1.5). | `$SOLVE --kc-sample "$FDIR" 1000000 $GALSEED --kc-ooc --kc-cache-mb 196608 > $OUT/q4_c3_sample.tsv` (`cd=` column is emitted per draw) — histogram + CIs in the consumer. | f | POINT-BATCH (sampling is ~100× cheaper/draw than a descent; M=10⁶ ≪ 4 h) | `tr12/q4_c3_hist.tsv` (TSV) + `q4_c3_sample.tsv` (raw) | `TR12_Q4AC=PASS` |
| **Q4b** | 🔴 **ANSWERED — see the note below this table; corrected 2026-09-05.** `min{C3(w) : w ∈ SUPER}` = **112**, witness published at `reports/certificates/c3_positional_witnesses.txt` (`G=12 C3=112`, committed 2026-07-24); `G ≥ 12` is structural and the witness achieves it, so the bracket closes at its floor and the SAT bisection is **not needed for the minimum**. The row as originally written — `min{C3(w) : w ∈ SUPER}` + argmin witness, by SAT bisection **on integer G**, bracket **G ∈ [12, 47]**, `c3_max = 16 + 8·G`. Rung-1 exact if the bracket closes; otherwise the honest bracket. | `PENDING:sat-c3min-driver` over: `python3 sat.py --witness plain --with-c3 --c3-max $((16+8*G))` for G bisected in [12,47]. Requires `PENDING:kissat`. Existing floor witness extractable with `$SOLVE --c3-min solutions.bin`. | — | NOLADDER (**NOW-able**, no ladder, no VM) | `tr12/q4_c3min.txt` (text) + DRAT certs; **as built (2026-09-08):** `tr12/raw/a0_q4b.txt` + `q4b_g12_witness.json` | ~~`TR12_Q4B=PENDING:sat-c3min-driver`~~ `TR12_Q4B=PASS` — earned by `--check-arrangement` over all 42 certificate lines + the G=12 witness (F-5 D10); the SAT bisection stays unneeded for the minimum |
| **Q5** | functional extremals over SUPER (min/max of a shortlisted G-invariant functional) + explicit witness walk. | `PENDING:--kc-extremal` → `$SOLVE --kc-extremal FUNC "$FDIR"` | f | SCAN-class, **one full Stage-F-shaped pass per functional** | `tr12/q5_<func>.txt` | `TR12_Q5=SKIP:wave3-not-budgeted` 🔴 **AND AT n=31, COST IS NOT THE ONLY GATE (Codex R5, 2026-09-11).** `kc_open` returns out-of-core whenever `n > KC_MEM_MAX_PAIRS` (`solve.c:20490`) and `kc_extremal_main` refuses an out-of-core f ladder immediately (`:32664`), *before* the invariance gate, the DP, the null-vs-g check, the witness and the certificate: *"v1 is IN-MEMORY ONLY … the streaming, eviction-resumable OOC extremal builder is a SEPARATE, UNBUILT item … it is the full-31 enabler."* So `--wave3` at n=31 **exits 2 and computes nothing**. Budget is an operator decision; an unbuilt builder is not, and reading this row as "money would buy it" is wrong. |
| **Q6** | per layer k: exact walk mass through each (state, choice), G-expanded; argmax/argmin-nonzero choices; KW's path percentile per layer. | `$SOLVE --kc-scan "$FDIR" "$GDIR" $OUT/atlas.json --kc-tdir "$TDIR" --kc-raw --kc-ooc --kc-cache-mb 32768` **then** `PENDING:atlas-consumer` → `python3 scripts/atlas_queries.py $OUT/atlas.json --q6 $OUT/scan/` | f+g(+t) | **SCAN** then DERIVED | `tr12/scan/q6_layer_mass.tsv` (TSV) | `TR12_Q6=PASS` **(reduced form — see §3.1)** ⚠ **RULED 2026-09-04 (§9.3): the "KW's path percentile" leg is REPLACED** — `mass_below` is an O3 rank-block contribution (n9: 2720 > g_parent 2368; 0 at full-31), not a percentile numerator; the consumer emits `kw_p` = m_k(d_KW)/N and `kw_class_pct` = Σ_{d: m_k(d) ≤ m_k(d_KW)} m_k(d)/N instead (patch tested on the n=9 atlas). |
| **Q7** | per historical arrangement: IN/OUT + first-violated constraint under the pinned order C1→C2→C3→C4→C5 + full violation list; rank if IN. | `$SOLVE --check-arrangement KW --cert-out $OUT/q7_kw.json` · for each of `_r7_mawangdui _r7_fuxi _r7_jingfang`: `A=$(python3 -c "import solve;print(','.join(map(str,solve.<fn>())))"); $SOLVE --check-arrangement "$A" --cert-out $OUT/q7_<name>.json` · SAT witnesses via `python3 sat.py --witness moore-strict` / `grand-strict` then the same call; **ranks** for IN cases via the §0.4(2) adapter into `--kc-o3-cert`. | **—** (verdicts); f+g (ranks only) | **NOLADDER — runnable today** | `tr12/q7_<name>.json` (JSON) + `q7_summary.md` (MD) | `TR12_Q7=PASS` |
| **Q8** | k=1,000 exact-uniform SUPER samples with the pinned seed + the C3-rejection C15 draws ⚠ (**corrected 2026-09-05, QSET finding 5: NOT a "~121 subset" of gallery 1.** `--kc-sample … --kc-c3-max 387` *rejects until it has COUNT accepted draws* — `solve.c` `continue`s until the count is met — so the second command yields **1,000 C15 walks, a second gallery**, not the ~121 survivors of the first. Measured on the committed fixtures: `a1_q8_super.txt` 43/200 pass at the reduced ceiling, `a1_q8_c15.txt` 200/200. The ~121 figure describes an object the command does not build) + records + cd\*; chi² uniformity gate. | `$SOLVE --kc-sample "$FDIR" 1000 $GALSEED --kc-record --kc-ooc --kc-cache-mb 196608 > $OUT/gallery/q8_super.tsv` · `$SOLVE --kc-sample "$FDIR" 1000 $GALSEED --kc-c3-max 387 --kc-record --kc-ooc > $OUT/gallery/q8_c15.tsv` · membership re-check of every sample via `--kc-member`; chi² in the consumer. Plumbing gate: `$SOLVE --kc-midn 13 --kc-chi2-samples 20000` | f | POINT | `tr12/gallery/q8_*.tsv` (TSV) + `q8_chi2.txt` | `TR12_Q8=PASS` |
| **Q9** | the reportable negatives, as **certified restatements with scopes** — no compute. TR-5 free action / 23 record-twins; TR-6 15 alternations + 30 switches; TR-7 odd wrap distance, 16 circular alternations, 32 switches; **plus §11's equivariance ceiling P(KW-record) ≤ 1/24** and the 8 forced literature rules promoted to theorem class. | none (writing). Cite **by theorem name, not by line** — 🔎 **PUBLIC ANCHOR:** `git grep -n "twenty_four_dvd_solution_count" <sha> -- lean/Automorphism.lean`, `git grep -n "within_pair_even_nonzero\|wrap_parity_general" <sha> -- lean/KingWen.lean`, `git grep -n "c3_slot_decomposition" <sha> -- lean/C3Decomposition.lean`. All four are committed and carry `#print axioms`. ⚠ `lean/C1RuleConstants.lean` — **the §3.3 branch finding is now STALE; see the correction there.** | — | **DOC (no compute)** | `tr12/q9_negatives.md` (MD) | `TR12_Q9=PASS` |

### §2 — the visualization program

| id | must produce | exact command line(s) | ladders | class | artifact | verdict token |
|---|---|---|---|---|---|---|
| **V1** | positional-marginal field: `P(pair j at slot k)` = 32×31 heat matrix, KW's placements overlaid. **Source: `atlas.layers[k].marginal_raw`** (RAW frame — requires `--kc-raw`). | scan (row Q6) then `PENDING:atlas-consumer --v1` then `PENDING:viz` | f+g | DERIVED (post-scan) | `tr12/scan/v1_field.tsv` + `reports/figures/fig_tr12_v1.{png,svg}` + `viz/viz_kc_field.md` | `TR12_V1=PASS` |
| **V2** | mass river: layer-k mass split across k=1..31, KW's path drawn as a line. **Source: `atlas.layers[k].by_class{d1,d2,d3,d4,d6}`.** | same scan → `PENDING:atlas-consumer --v2` → `PENDING:viz` | f+g | DERIVED | `tr12/scan/v2_river.tsv` + `fig_tr12_v2.*` + `viz/viz_kc_river.md` | `TR12_V2=PASS` **(distance-class form only — §3.1)** |
| **V3** | rank spectrum: walk-decomposable functional values of `unrank(r)` on a systematic grid `r = i·⌊N/K⌋`, K=10³. | `for i in $(seq 0 999); do R=$(python3 -c "print($i*(1097051278789181790036112071176579186688//1000))"); $SOLVE --kc-unrank "$FDIR" $R --kc-ooc --kc-cache-mb 196608; done > $OUT/v3_rel_grid.txt` — **then the rank-grid → per-walk-functional join that produces `spectrum/v3_spectrum.tsv`, which does not exist**; `solve.py` has no batch walk-functional evaluator at HEAD (no `--eval-walks` / `--walk-functionals` / `--batch-eval`), so this cell named no command until 2026-09-12 (V3A-044#4) | f (REL axis); f+g for the O3 axis | **POINT-BATCH — K=10³ MEASURED 31.4 min**, K=10⁴ ≈ +2.5–3 h. Keep it ONE process (cold phase is per-invocation). | `tr12/v3_rel_grid.tsv` + `PENDING:viz-v3-spectrum` (the figure `fig_tr12_v3.*` is not produced) + `viz/viz_kc_spectrum.md` | `TR12_V3_TSV=PASS`, `TR12_V3=SKIP:leg-TR12_V3_FIG` |
| **V4** | KW's neighbourhood shells: `g(KW-prefix_k)` vs k, log-scale = Q3 as a figure. **Source: the `g=` column of Q3's trace — needs NO scan.** | `PENDING:viz` over `$OUT/q3_profile_kw.tsv` | (rides Q3) | DERIVED, no compute, local | `fig_tr12_v4.*` + `viz/viz_kc_shells.md` | `TR12_V4=PASS` |
| **V5** | transition grammar: `P(next-choice class \| layer k)` heat map, KW's actual choices marked. **Source: `atlas.layers[k].by_class`.** | same scan → `PENDING:atlas-consumer --v5` → `PENDING:viz` | f+g | DERIVED | `tr12/scan/v5_grammar.tsv` + `fig_tr12_v5.*` + `viz/viz_kc_grammar.md` | `TR12_V5=PASS` **(distance-class form only — §3.1)** |

### §3 — the Exhaustion Atlas (XA)

| id | must produce | exact command line(s) | ladders | class | artifact | verdict token |
|---|---|---|---|---|---|---|
| **XA-iii** | **the mandatory accounting-convention pin, runs FIRST** — what a t-unit is vs `SOLVE_NODE_LIMIT` node-counter semantics, verified byte-exactly against exhaustive brute DFS at n=9 with n=13 spot totals. **No atlas number ships before this.** | `$SOLVE --kc-t-cert $OUT/xa_node_convention.json > $OUT/xa_node_convention.txt` | **—** | **NOLADDER — NOW-able, no compute.** Verified PASS 2026-08-22. | `tr12/xa_node_convention.{json,txt}` | `TR12_XA_III=PASS` |
| **XA-a** | `solutions(b)` per top-level branch, exact, SUPER. **Source: `atlas.branch_atlas[b].solutions`.** Gate `Σ_b solutions(b) == N`. | scan (row Q6) → `PENDING:atlas-consumer --xa` | f+g | DERIVED | `tr12/xa_branches.tsv` (TSV) | `TR12_XA_A=PASS` |
| **XA-b** | `prefixes(b)` in valid-prefix t-units per branch + `t(root)`. **Source: `atlas.branch_atlas[b].prefixes_t_units`, `atlas.t_root_t_units`, `t_source` must read `t-ladder`.** Gate `Σ_b prefixes(b) + shared trunk == t(root)`. | same scan **with `--kc-tdir "$TDIR"`** → consumer | f+g+**t** | DERIVED | same TSV | `TR12_XA_B=PASS` |
| **XA-c/d** | exhaustion wall + $ at measured orbit-engine throughput (R-1 anchors: 36.14× work factor, 19.8× wall at 1T, nodes/sec from R-1 pilot artifacts hedged ×2), and the verdict **EXHAUSTIBLE vs INFEASIBLE with the exact shortfall factor**. ~~Retroactively upgrades the standing single-branch-exhaustion shortfall estimate to exact.~~
*(The shortfall factor itself is **not quoted** — it has no public reproduction command, and the
companion TR-12 draft §3 withholds it on the same ground: publishing an unsourced factor beside a
promise of the exact one is strictly worse than publishing neither. Its public anchor is the run,
not a number — `documentation/HISTORY.md` §"April 22, 2026 — Campaign A Pass 1" and
`runs/20260422_passA_10T_d64_laggard/`. Caught 2026-09-05 in the pre-publication read; Appendix B's
audit missed it because the numeral sat inside a strikethrough.)* 🔴 **RULED 2026-09-04 (§9.6): the landed consumer (`solve.py:12049ff`, on `main` since `a19682b2`) prices t-units as production DFS nodes and emits EXHAUSTIBLE/INFEASIBLE, while the t-unit → `SOLVE_NODE_LIMIT` mapping is W0-D's and explicitly unclaimed. Token is `TR12_XA_CD=PENDING:W0-D-node-mapping` until W0-D lands; the "upgrades … to exact" sentence is WITHDRAWN (it would relabel a t-unit count as a node count).** | `PENDING:atlas-consumer --xa-cost` (arithmetic over XA-b + the R-1 anchors) | (none — arithmetic) | DERIVED, no compute | `tr12/xa_verdict.md` (MD) | ~~`TR12_XA_CD=PASS`~~ `TR12_XA_CD=PENDING:W0-D-node-mapping` (2026-09-04) |
| **XA-24** | §11 refinement: a **24-divisibility integrity self-check on `N` and on every per-layer flow**, Lean-kernel-backed (`twenty_four_dvd_*`). Dispositive and cheap. ⚠ **Corrected 2026-09-05 (QSET finding 10): this read "on every headline count", which a CORRECT atlas fails.** The order-24 group permutes walks *between* branches, so an individual per-branch `solutions(b)` need not be divisible by 24 — this repository's own n=9 fixture is the counterexample: `scripts/tr12_expected/n9/c_xa_mod24.txt` records `branch0_solutions 2368 16 (reported, not gated)`, and 2368 ≡ 16 (mod 24). Per-branch counts are **reported, not gated**, and `scripts/tr12_repro.sh` already says why. | `PENDING:atlas-consumer --gate-mod24` over every count in `atlas.json` | — | DERIVED, no compute | line in `tr12/xa_verdict.md` | `TR12_XA_MOD24=PASS` |

### §4 — the literature-claims exactness sweep (LS)

| id | must produce | exact command line(s) | ladders | class | artifact | verdict token |
|---|---|---|---|---|---|---|
| **LS-w0** | TR-8's pair-only null (a C1-only-space count; CHEAP, near-closed-form) — the **only** LS item inside the funded waves. | `$SOLVE --null-pair-constrained 1000000000 > $OUT/ls_pair_null.txt` | — | **NOLADDER — NOW-able** | `tr12/ls_pair_null.txt` (text); **since 2026-09-08 the artifact carries two labels that must travel with the number (F-5 §5 / D15): `threshold_label` = KW-anchored (the tail is taken at KW's own `rc4_violations` = 2) and `correction_family` = the 91-observable suite ledger TR-8 reads it against (Bonferroni bar 0.05/91)** | `TR12_LS_W0=PASS` |
| **LS-forced8** | the eight forced-1.0 rows (mmt4, p1c4, s1, s6, r3, r4, r5, c2). §11 rules these **PROVEN C1 constants** ⇒ theorem class ⇒ they move into **Q9**, not into a DP run. | none (citation). ⚠ artifact **absent from this branch** — §3.3. | — | DOC (no compute) | folded into `tr12/q9_negatives.md` | `TR12_LS_FORCED8=PASS` |
| **LS-exact** | the ≥6–10 exact-count upgrades (N_gs, ccn4/ccn8 tails, ×11,364 gender fraction, scoreboard fractions) via extended-state count DPs. | `PENDING:--kc-oracle` **property-channel grammar** (TR-12 §8 item 8) — the flags to express violation counters / the 36-station counter **do not exist**. `--kc-oracle` today is the H1 merge oracle over `solutions.bin`, not a property counter. | f | **wave 3 — not budgeted, sizing-gated** | — | `TR12_LS_EXACT=SKIP:wave3-not-budgeted` |
| **LS-audit** | the **mandatory D-B1 circularity audit gate** — every literature-derived functional passes an adversarial provenance audit *before* any striking exact tail ships. | none (review protocol; the precedent audit is an internal record — 🔻 **FINDING (C-06)**: the circularity-audit protocol itself is not published, only its verdicts. Its *criterion* is public in `reports/METHODS.md`, which grades each constraint by provenance and marks the ones "Extracted from KW (confirmatory, not predictive)") | — | DOC (no compute) | `tr12/ls_circularity_gate.md` (MD) | `TR12_LS_AUDIT=PASS` |
| **LS-cite** | (e) already-exact/certified rows — TR-8's within-pair distance family {2,4,6} (`within_pair_even_nonzero`), TR-10's derivative groups. **The sweep cites, does not redo.** Plus the §11 q-binomial framing note (Suenaga 2012 `1395 = [6,3]₂`, Ouyang 1990/1992). | none | — | DOC (no compute) | citations inside `tr12/ls_*.md` | `TR12_LS_CITE=PASS` |

### §5 — the exploration wave (EW-1 only; EW-2/EW-3 are not in this task's scope)

| id | must produce | exact command line(s) | ladders | class | artifact | verdict token |
|---|---|---|---|---|---|---|
| **EW-1** | the surprise-localization ledger: the exact per-choice surprise spectrum (31 bars) decomposing `log₂ N ≈ 129.689` bits = `Σᵢ −log₂ p_i`, **plus the pre-fixed interpretation contract** (concentration ⇒ where an undiscovered constraint must live; near-uniform typicality ⇒ boundable evidence that no further simple positional constraint exists — **both outcomes are findings**), plus the units bridge to TR-9's 296-bit ledger stated explicitly, plus the Q8 gallery comparison band. | `awk` the `bits=` column out of `$OUT/q3_profile_kw.tsv`; ~~band from `$OUT/gallery/q8_super.tsv`~~ 🔴 **PHANTOM (2026-09-04, §9.4): `q8_super.tsv` has no `bits` column.** Band = `for w in $(cut -f3 $OUT/gallery/q8_super.tsv); do $SOLVE --kc-profile "$FDIR" "$GDIR" "$w" --kc-tsv …; done` (1,000 profiles; statistic `top1_share = max bits / Σ bits`). **Rides Q3 — needs f+g, NOT the scan.** Gate: `sum_bits == log2N` on the `#o3-trace-summary` line. ⚠ **RULED 2026-09-04 (§9.4): calibrated null ADOPTED (audit P3) — KW's `top1_share` vs the gallery's 1st/99th percentiles, two-sided, once; the "both outcomes are findings" contract is replaced by the three pre-stated outcomes; n=9 rehearsal verdict `typicality-bound`.** | (rides Q3 + Q8) | DERIVED, no compute | a private frontier note + `tr12/ew1_spectrum.tsv` | `TR12_EW1=PASS` + `TR12_EW1_NULL=<verdict>` |
| **EW-gov** | the pre-registration: candidate list + family size + interpretation contract, **content-hash recorded BEFORE any tail computation**. | write a dated pre-registration note and hash it into the project's pre-registration lock ledger **before** any tail computation. 🔻 **FINDING (C-07): the ledger and the pre-registration notes are private.** `documentation/VERIFY.md` discloses the same arrangement for the T1–T4 catalog (bars "frozen in the pre-registration (private repo) … committed **before** the first recorded draw"), so the practice is disclosed publicly even though the artifact is not | — | DOC (no compute) | a dated private pre-registration note | `TR12_EW_GOV=PASS` |

### §11 — the novelty-refresh addendum

| id | must produce | exact command line(s) | ladders | class | artifact | verdict token |
|---|---|---|---|---|---|---|
| **Q10a** | orbit census, **EXACT and cheap**: per g-ladder layer, the number of distinct 24-orbits = layer walk-mass / 24; KW's orbit's rank among them; **the `≡ 0 (mod 24)` gate on every layer** (dispositive, kernel-backed). Global anchor `N/24 = 45710469949549241251504669632357466112`. | scan (row Q6) → `PENDING:atlas-consumer --q10a` over `atlas.layers[k].flow`; independently `$SOLVE --kc-g-check "$FDIR" "$GDIR" --kc-ooc` prints the f·g cut identity == N at every layer | f+g | DERIVED (the `--kc-g-check` leg is a separate pass — see §6 note) | `tr12/q10_orbit_census.tsv` (TSV) | `TR12_Q10A=PASS` ⚠ **RE-SPEC 2026-09-04 (§9.5):** as commanded the census is `N/24` ×32 (flow ≡ N by the atlas gate) — stated ONCE as the identity it is; the census content is the **per-layer state census by G-orbit-size class + the branching histogram, already emitted in the f-ladder sidecars** (`f1c5_layer_stats_XX.json: orbit_size_census, branching`; n=9 table in §9.5) — ⚠ *corrected 2026-09-11: `orbit_size_census` is a sidecar schema-v2 field (`317dda34`, 2026-07-18). The n=31 f ladder was built at `befd4e1b` the day before and carries schema v1 without it, so at n=31 row `c_q10a` reports that column `NA:schema-v1-sidecar` and gates every other field*; the mod-24 gate stays; ~~**the KW-orbit-rank leg is DROPPED**~~ **the KW-orbit-rank leg has a MEASURING PRODUCER as of 2026-09-10 (N3) whose n=31 value is EXPECTED, NOT YET PRODUCED: `TR12_Q10A_KWRANK=EMPTY:class-rank-uncomputable-under-kw-labels`, emitted by row `c_q10a_kwrank` only when BOTH halves of the original reason are checked — that the o3-cert supplies no class/orbit-rank field (searched by field name, so a future producer ENDS the null instead of ageing it into a lie) and that `rank_O3(anchor) = 0`, which is what forces the orbit rank to 0. At n=9 it measures that the forcing does not hold and returns `NONVACUOUS:anchor-is-not-the-o3-least-object`; `scripts/n3_measured_nulls_gate.sh` red-tests both directions plus five ERROR paths. `TR12_Q10A` itself is deliberately NOT relabelled — that row measures four live things and is pinned PASS/FAIL by `a2_slot_verdict_gate.sh`** (class-rank `NOT computed` per the o3-cert; vacuous under KW-derived labels). |
| **Q10b** | coset-structured census (the Ouyang lens): walk-mass across the cosets of the relevant (ℤ/2)⁶ XOR-translation subgroups; whether KW's coset is distinguished. ⚠ **UNDERSPECIFIED — flagged 2026-09-05 (QSET finding 4), and it must be fixed before this row is ever run, not while running it.** "The relevant subgroups" names no subgroup, and no mask→coset map is given, so **"KW's coset" has no referent as posed** — a reader cannot tell which of many candidate quotients is meant, and an implementer would be *choosing the question*, which is exactly what a query row must not leave open. The Ouyang lens supplies a natural candidate (the coset of the pair XOR-key under a named subgroup), but the row must **name it** and cite the map. Until then this row is a research direction, not a question. **EXPLORATORY / FRONTIER discipline — "flat" is a reportable negative, not a failure. No structural claim pre-committed.** | `PENDING:--kc-coset-census` (coset id via the XOR structure already in `applyPerm`/`pairKey`, aggregated over the scan mass table) | f+g | DERIVED once built | a private frontier TSV, until the circularity audit clears it | `TR12_Q10B=PENDING:--kc-coset-census` |
| **Q4-Gexact** | §11 refinement: the **EXACT** G-channel companion to Q4's estimated C15 histogram — the C1∩C4 null law of G, support **[12, 228]**, **E[G] = 128** (⇒ E[C3] = 1040), **P(G ≤ 95) = 641983711307479/7919632354008375 ≈ 8.106%**. One column moves estimate→exact; the C15-conditioned histogram **stays labelled ESTIMATE**. | source: an already-derived internal note — transcription + the ceiling-is-KW-defined circularity note. 🔎 **PUBLIC ANCHOR — this row's whole content is already public and independently checkable:** `python3 verify.py --check-null-g` re-derives support `[12,228]`, `E[G] == 128` and `P(G ≤ 95) == 641983711307479/7919632354008375` from scratch, gated against `total == 31!`; see `documentation/VERIFY.md`. The identity `C3 = 16 + 8·G` and the same constant are machine-checked in `lean/C3Decomposition.lean` (`null_p_le_95`, `null_mean_128`). This row therefore needs **no** private source at all | — | DOC (no compute) | column in `tr12/q4_c3_hist.tsv` | `TR12_Q4_GEXACT=PASS` |

---

## 3. Known gaps and corrections — read these before writing any consumer

### 3.0 🔴 At n=31 every row's only failure signal is its own exit status

**Read this before reading any full-31 `PASS` as a golden match, because it is not one.**

`scripts/tr12_expected/` holds exactly one universe, `n9/`. There is no n=31 expected set and there
cannot be one before the run — nothing exists to mint it from. So the full-31 run must be driven
with `--regen` or `--mint-missing`, and under those `row_end` **copies the row's output into the
golden and records `PASS` without diffing anything.**

The consequence, stated in one sentence because it keeps being rediscovered in pieces: **at n=31
the golden mechanism contributes nothing, and every defence rests on what a row ASSERTS, never on
what it MATCHES.** A golden minted by the run cannot check the run.

This is the structural amplifier behind the whole n≥31-only defect class. It is why a row that
takes the solver's exit status as its only failure flag is not a small problem at 31 — an
enumeration that finds nothing exits 0, and the golden it mints is the emptiness it just produced.
It is also what gives `scripts/row_assertion_gate.sh` its real standing: at n=31 that sweep is not
a nice-to-have, **it is the entire check surface**.

Recorded 2026-09-11 (backlog Q-495). Not a defect and not repairable by minting — the remedy is
that nobody forms the wrong expectation, which is what this section is for.

### 3.0b 🔴 Three `--kc-scan` cross-gates do not run at n=31, and one of them is the only
### independent per-branch re-derivation

`solve.c:27767` gates `t_done` on `fkc->total.l0 <= (1ull << 27)` with the high limbs zero — that
is a test on the **magnitude of N**, not on the pair count. At n=31 it is false, so three
`--kc-scan` cross-gates stop firing, **including "per-branch leaves == g mass", which is the only
independent re-derivation of each branch's solution count.**

Measured at n=13, not argued: `grep -c '"walks"' ` on a real n=13 atlas returns **0**, against
**12** at n=9. So the loss begins well below 31 — **even an n=13 rehearsal would not restore it**,
which is worth knowing before anyone proposes n=13 as the rehearsal size for this reason.

**No reader should infer that the per-branch count was independently re-derived at n=31. It was
not.** Whether the ceiling should be raised, sampled, or left as it is depends on what `t_done`
actually costs at full scale, which has not been measured — so this section records the fact rather
than promising a change (backlog Q-494).

⚠ The general lesson, recorded because it cost a dedicated sweep to find: **a guard keyed on
magnitude is invisible to every `n`-based search.** The obvious enumeration of n-dependent
behaviour greps for comparisons against 31; this one is written against 2²⁷.



### 3.1 🔴 The atlas schema does not carry everything Q6/V2/V5 ask for
Measured against `fixtures/kc_n9/atlas_n9.json` (5,684 B). `layers[k]` carries **`flow`,
`by_class{d1,d2,d3,d4,d6}`, `marginal_quotient{q…}`, `marginal_raw{pair…}`** — and nothing else.
Therefore:

| spec asks for | atlas provides | verdict |
|---|---|---|
| **V1** `P(pair j at slot k)` | `marginal_raw` (RAW, needs `--kc-raw`) | ✅ **fully served** |
| **Q6** per-layer **per-(state,choice)** mass; argmax/argmin-nonzero *choices* | per-layer per-**distance-class** mass only | ⚠ **reduced form.** Ships as per-layer distance-class mass + per-slot pair marginals. The per-choice argmax/argmin needs a new emitter. §9 already rules the argmin "loneliest corridor" **figure fodder, not a headline claim** — so the reduced form does not cost a headline. **Do not silently publish the reduced table as the spec's table.** ⚠ *A correction of mine was WITHDRAWN here on 2026-09-12, same day it landed. Acting on Codex KCP5 #4 I deleted "The per-choice argmax/argmin needs a new emitter", on the grounds that `extrema` (`solve.c:27873`) records argmax/argmin witnesses. **That was wrong and the sentence is restored.** `verify.py:1840` `q6_extremes_oracle` is the operational DEFINITION of reading (B) — state = (placed set, LAST ENDPOINT), choice = the UNORDERED pair — and it names the exact trap I fell into: "key on the ORIENTED pair → 3072/896 … 1728/224", which is what `extrema` produces, and "k=0 agreement proves nothing". Measured at n=9: oracle vs atlas disagree at EVERY layer (k=0 4736/3968 vs 3072/896; k=8 1952/992 vs 1728/224). `extrema` keys on the ORIENTED choice and on a state refined by the C5 residual `rid`, so it is a finer partition and no arithmetic recovers the coarse extremum. The per-(state,choice) table is also not a cheap re-emit: its cell space at n=31 is ~2×10¹², against the kernel's 126,976. Four places in this tree already said so — `scripts/tr12_repro.sh:1179`, `scripts/tr12_expected/n9/c_q6.txt:2`, `solve.py:12285`, `solve.py:13725` — and my edit contradicted all of them.* |
| **V2** layer mass split **by top-level branch class** | `branch_atlas[]` is per-branch **totals**, not per-layer-per-branch | ⚠ **reduced form.** Ships in the spec's parenthetical alternative — split by distance class of the k-th transition. |
| **V5** choice classes = distance class **× new-pair category** | distance class only | ⚠ **reduced form.** The second dimension is not shipped as its own table. ⚠ *Corrected 2026-09-12 (Codex KCP5 #4, Opus disposition): this cell read "The second dimension is absent." It is not absent from the DATA — with `--kc-raw` the atlas persists every nonzero raw kernel cell `m<a>_<b>` (`solve.c:27967`), and both `d = popcount(a ^ b)` and the new pair's identity through entry `b` are recoverable from the key, so the joint is derivable from saved data without a re-scan. What is genuinely missing is the CATEGORY DEFINITION (`viz/viz_kc_grammar.md:44`), which is a consumer-side decision, not a scan-side gap. The distinction matters because the n=31 pass is paid once: "absent from the schema" would mean re-scanning to get it, and that is not the situation.* |
| **KW's path percentile per layer** (Q6) | ~~derivable: `mass_below` from Q3's `--kc-trace` ÷ `layers[k].flow`~~ | ~~✅ served, but **only by joining Q3's output to the atlas**~~ 🔴 **WRONG (Codex A09 f3; Q-48 executed; RULED 2026-09-04 §9.3):** `mass_below` is the O3 rank-block contribution, not a percentile numerator. Served instead by `kw_p` / `kw_class_pct` from the atlas alone (no join). |

**Decision required from the operator (not from a later agent):** accept the reduced Q6/V2/V5, or
authorize a scan-emitter extension. The extension must land **before** the scan runs — an unchunked
scan is one multi-day unresumable pass, and re-running it to add a column is the single most
expensive mistake available in this program.

### 3.2 🔴 `Π p_i = 1/N` is asserted by the engine, not by the reader
The `#o3-trace-summary` line prints `product(p_i)=1/N EXACT (telescoping + per-step flow
identities)` — that is the **engine** attesting. TR-12 §R step 7 requires this as **reader
arithmetic** (rung 1). The consumer must independently recompute `Π (g_i / g_parent_i)` from the
TSV columns as exact big-int rationals and compare to `1/N`. **Emit `TR12_Q3_READER=PASS`
separately from `TR12_Q3=PASS`.** Do not let the engine grade its own homework.

### 3.3 ✅ `lean/C1RuleConstants.lean` — the branch finding held on 2026-08-22, and is now RESOLVED
§11's Q9 refinement (ii) promotes the 8 forced literature rules to theorem class citing
`C1RuleConstants.lean`. **As written on 2026-08-22, and re-verified on 2026-08-29, that file was
NOT reachable from the query-program branch** — it is added by commit `9225098f`, and
`git merge-base --is-ancestor 9225098f v4-query-program` returned **false**. The instruction was
therefore: cite it by commit sha with the branch stated, or land it on the query-program lineage
before publication.

🔴 **CORRECTED 2026-09-05, and this is a correction the public draft makes rather than inherits.**
The query-program lineage subsequently merged `main`, and the file **is now present**. Re-verify:
```
git merge-base --is-ancestor 9225098f main            && echo on-main
git cat-file -e merged/v4-query-program-20260904:lean/C1RuleConstants.lean && echo present
```
Both succeed today. **§8.11 below, which re-asserted the negative on 2026-08-29, is likewise
superseded.** The original finding was correct when made; it is recorded here rather than deleted,
because the discipline it illustrates still binds — *do not cite a file as if it were in the same
tree you are grepping*, which is exactly the pinned-worktree error the §3 retraction box logs. The
lesson survives its own instance.

### 3.4 SAT toolchain is absent
`which kissat d4 cpog-gen drat-trim` → **all empty** on this box. Q4(b) cannot run until `kissat`
is installed, and its UNSAT legs cannot be certified until `drat-trim` is too. Worse, `sat.py`
invokes `kissat -q` **without a proof flag** on the `--witness` path — so **DRAT emission is itself
PENDING**, not merely the checker. 🔎 **PUBLIC ANCHOR:**
`git grep -n 'kissat", "-q"' <sha> -- sat.py` (the `--rigidity-cnf --run` path *does* pass a proof
file; the `--witness` path does not — compare the two call sites). Q4(b)'s "each UNSAT = DRAT certificate ⇒ rung-1 exact min"
is not achievable with today's `sat.py`.

### 3.5 `--kc-sample` semantics vs Q1c's estimator
Q1c's spec says "draw M exact-uniform ranks **in [0, rank_O3^SUPER(KW))**". `--kc-sample` draws
uniformly over **all** of SUPER and has no rank-range argument. The prefix restriction is therefore
**post-filter arithmetic in the consumer** (compare each draw's O3 rank to KW's), which changes the
effective M. Either budget M large enough that the retained subsample still gives the stated CI, or
build a rank-range sampler. **State the realised M and CI, never the requested M.**

---

## 4. What §9 EXCLUDES — do not build these, do not let them creep back in

TR-12 §9 ("Judged NOT report-grade") declines the following. Any later agent proposing work on
them is proposing out-of-scope work:

1. **"Aesthetic-interest" ranks (Q2).** Declined **entirely** — numerology framing risk. Any
   specific rank is O(1) to query later; **nothing is pre-committed.** No row exists for it above.
2. **C15 midpoint, and any C15 exact count.** **Priced and permanently declined on cost — *not*
   "not computable."** (Corrected 2026-09-05: this row read "not computable (the C3 counting
   obstruction)", which inverts the very section it summarises — TR-12 §9 says "PRICED AND DECLINED
   — not 'not computable'", because `c3_slot_decomposition` dissolved the structural barrier.)
   A sampled midpoint would imply false precision ⇒ **omitted rather than estimated.** This is why
   Q2's midpoint row is SUPER-only and Q1c/Q4a-c are labelled ESTIMATE.
3. **Edit-distance-to-KW extremal** (KW's nearest SUPER neighbour). Needs the plain unquotiented DP
   with a ×32 channel; sizing unknown, possibly infeasible ⇒ **DEFERRED**, with the 560T-sample
   minimum as the standing bound. Flagged, **not promised**.
4. **Deep-tail exact counts for KW-extracted templates** (ccn4-class, D-B1-class). Computable but
   **evidentially void** per the circularity discipline; if run at all, published **descriptively
   only, never as a headline p**.
5. **Per-layer argmin "loneliest corridor" trivia (Q6 tail).** Figure fodder for V2/V5, **not a
   headline claim** — a minimum-mass corridor is expected in any large DP and distinguishes nothing.
   (This is why §3.1's reduced Q6 costs no headline.)
6. **CAP-8 connectivity at full-31.** Open research; only small-n exact results are possible;
   **excluded from TR-12.**
7. **CAP-4 minimal-repair for arbitrary inputs.** Unbounded runtime; research-grade until
   benchmarked; **SAT remains the certified instrument** for named instances.
8. **EW screens without pre-registration.** Any tail computed before its family is locked is
   **DISCARDED by protocol** — running ahead of governance is worse than not running.

**Separately excluded by the §7 wave ruling (operator, 2026-07-17: "I can't afford wave 3"):**
Q5 (the `--kc-extremal` shortlist), the LS exact-count shortlist,
`--kc-oracle` property channels, CAP-5's grid, EW-2 screens, CAP-4/CAP-8. **Wave 3 is DEFERRED and
NOT BUDGETED**; each item may be cherry-picked individually later behind its own cost gate. **No
wave-3 item is required for TR-12.**

---

## 5. THE RUN ORDER

**The rule that generates it:** as originally specified the scan is **one multi-day pass with no
resume flag, no checkpoint, and no layer range** — `kc_scan_main` writes its atlas JSON *once, at the
end*, so an interruption near the finish yields nothing. (§8.4 retires the no-layer-range half of
that premise; the write-once-at-the-end half still holds for an unchunked pass.) Everything that can be banked before it, must be. Ordering costs zero
and is the cheapest interruption/crash insurance available. (Even on non-pre-emptible capacity, a
crash, an out-of-memory kill, or a reboot loses the whole unchunked pass, so the ordering matters
regardless of host priority.)

### Group A — PRE-SCAN. Bank everything cheap first.

**A0 — no ladder mounted, runnable today, no compute cost.** Nothing here waits for Stage T.
| step | command | token |
|---|---|---|
| A0.1 | `$SOLVE --check-arrangement-selftest && $SOLVE --kc-selftest && $SOLVE --kc-o3-selftest && $SOLVE --kc-g-selftest && $SOLVE --kc-t-selftest && $SOLVE --kc-cert-selftest && $SOLVE --kc-ladder-selftest && $SOLVE --kc-ar2-selftest && $SOLVE --kc-oracle-selftest && $SOLVE --kc-scan-selftest` — **all must print `PASS (0 failures)` or STOP** | `TR12_GATES=PASS` |
| A0.2 | **XA-iii convention pin** — `$SOLVE --kc-t-cert $OUT/xa_node_convention.json`. **No atlas number ships before this.** | `TR12_XA_III` |
| A0.3 | **Q7** — all arrangements + SAT witnesses through `--check-arrangement` (verdicts need no ladder) | `TR12_Q7` |
| A0.4 | **LS-w0** — `$SOLVE --null-pair-constrained 1000000000` | `TR12_LS_W0` |
| A0.5 | **Q9 / LS-forced8 / LS-cite / LS-audit / Q4-Gexact / EW-gov** — writing only | `TR12_Q9`, `TR12_LS_*`, `TR12_Q4_GEXACT`, `TR12_EW_GOV` |
| A0.6 | **Q4b** — ~~SAT C3-min bisection, once `kissat` is installed~~ the published C3 witnesses re-verified with `--check-arrangement` (all 42 certificate lines; the G=12 floor witness in full). PASS = min C3 over SUPER is 112 on a computed fact; no solver needed (F-5 D10, 2026-09-08) | `TR12_Q4B` |
| A0.7 | **the n=9 full-program rehearsal** — every command below against `$A/f $A/g $A/t`, diffed vs `fixtures/kc_n9/atlas_n9.json` | `QUERY_DRYRUN=PASS` |

**A1 — f-ladder mounted only.** Right-size for descents: the binding resource is **RAM, not
cores** — enough memory to hold the working set is what collapses the cold phase into the warm one.
The cores are freight.
| step | command | class | token |
|---|---|---|---|
| A1.1 | `$SOLVE --f1c5-layer-sha "$FDIR"` — 32 layer digests, each compared against the `own_sha256_decompressed` its builder recorded in that layer's sidecar, **before trusting any number** (see the note below this table) | POINT | `TR12_FSHA=PASS` |
| A1.2 | **Q8** gallery (1,000 samples, seed `$GALSEED`) + a second, **independent** C15 gallery (`--kc-c3-max` rejects until 1,000 draws are *accepted*; **not** a subset of gallery 1 — see row Q8, corrected 2026-09-05) + `--kc-member` re-check + chi² + the *actual* C3-rejection subset of gallery 1, derived for free by filtering it on `cd ≤ T` (`a1_q8_subset` / `TR12_Q8_SUBSET`, 2026-09-08, F-5 D9) | POINT | `TR12_Q8` |
| A1.3 | **Q4a/c** C3 census, M=10⁶ | POINT-BATCH | `TR12_Q4AC` |
| A1.4 | **Q2b** REL endpoints (0, N−1, ⌊N/2⌋) | POINT | `TR12_Q2B` |
| A1.5 | **Q2c** FIRST^C15 (`--kc-c3-max 387 --kc-limit 1`); wall-clock abort (`TR12_Q2_ENUM_TIMEOUT`, default 6 h) | POINT | `TR12_Q2C` |
| A1.6 | **Q1b** REL rank(KW) — the labelled second coordinate | POINT | `TR12_Q1B` |
| A1.7 | **V3** REL grid, K=10³ — **ONE process**, the cold phase is per-invocation | POINT-BATCH, **31.4 min MEASURED** | `TR12_V3` |
| A1.8 | **Q2d** LAST^C15 — only if `PENDING:--kc-enum-desc` has landed **with its n=9 gate shown able to fail** | POINT | `TR12_Q2D` |

> **What A1.1 / A2.1 / A3.1 actually check, and what they do not.** Until 2026-09-09 these rows
> only *printed* the per-layer digests and this table described them as checked "vs the registry" —
> nothing compared them to anything, so the row passed on a corrupted ladder. Measured at n=9 with
> one byte of `g_layer_05.bin` flipped: `--kc-g-check`, `TR12_Q1`, `TR12_Q2`, `TR12_Q3` and
> `TR12_EW1` all still returned PASS. The rows now compare each digest against the
> `own_sha256_decompressed` the builder wrote into that layer's sidecar, and go red on any mismatch,
> a missing sidecar, a missing field, a layer count other than n+1, or a non-zero tool status. The
> comparison emits its own whole-line verdict into the row body, **`LADDER_SHA_CHECK=OK|FAIL`**, and
> the row's `TR12_FSHA` / `TR12_GSHA` / `TR12_TSHA` token follows it. With that check present the
> corrupted ladder produces exactly one failing row out of 66.
>
> **The limit of it:** the sidecar sits beside the layer, so a layer rebuilt wrong together with a
> fresh sidecar agrees with itself. This proves internal consistency, not identity with the
> published build. That is a different question, answered by
> `runs/20260906_kc_ladders_n31/STAGE_{F,G,T}_LAYERSHA.txt` — 32 rows per stage, taken from these
> same sidecars — which the row does not consult, because the launcher snapshot does not ship
> `runs/`. At n=9 the committed golden pins the values.


**A2 — f + g mounted.** ⚠ **Put the g ladder on storage fast enough to read it BEFORE the first g
read.** On slow-tier storage the random-lookup pattern collapses to a few MB/s and the run looks
**hung, not slow** — which is the failure mode that wastes a window.
| step | command | class | token |
|---|---|---|---|
| A2.1 | `$SOLVE --f1c5-layer-sha "$GDIR"` — 32 g layer digests vs their sidecars (see the note under A1.1) | POINT | `TR12_GSHA=PASS` |
| A2.2 | **Q1** — `--kc-o3-cert … KW` (H3b certificate + neighbour bracket) | POINT | `TR12_Q1` |
| A2.3 | **Q3** — `--kc-o3-rank … "$KWW" --kc-trace --kc-bracket` (explicit 62-value walk — **not** the literal `KW`, see §0.4(3)). 🔴 **This is a PRE-SCAN point query, not a post-scan one** — see §6. | POINT | `TR12_Q3` |
| A2.4 | **Q3 reader check** — recompute `Π p_i = 1/N` as exact big-int rationals from the TSV (§3.2) | DERIVED | `TR12_Q3_READER` |
| A2.5 | **EW-1** — surprise ledger from A2.3's `bits=` column + A1.2's gallery band. 🔴 **Also pre-scan.** | DERIVED | `TR12_EW1` |
| A2.6 | **V4** — shells figure from A2.3's `g=` column | DERIVED | `TR12_V4` |
| A2.7 | **Q2** — O3 endpoints (three `--kc-o3-unrank` calls) | POINT | `TR12_Q2` |
| A2.8 | **Q7 ranks** — O3 ranks for the IN arrangements via the §0.4(2) adapter | POINT | folded into `TR12_Q7` |
| A2.9 | **Q1c** — the interval measurement, then the C15 rank estimate leg at M=10⁴ *if the interval is non-empty* (N3, 2026-09-10) | measurement **~0**; estimate POINT-BATCH, **3–5 h**, and at n=31 the measurement is what stops it being spent | `TR12_Q1C` |
| A2.10 | `$SOLVE --kc-g-check "$FDIR" "$GDIR" --kc-ooc` — the f·g cut identity must print N at **every** layer. ⚠ This is a **full ladder pass**, ~24 h, single-threaded, **not** a point query. ~~Schedule it deliberately or skip it if Stage G already banked its own `--kc-g-check` PASS.~~ **RESOLVED (§8.8): the Stage G build banked `KCG_CHECK=PASS` on 2026-08-20** — the f·g cut identity did execute at every layer k=0..31, rc 0 after **90,141 s**, each layer printing the 40-digit N. ⚠ **The battery nevertheless emits `TR12_GCHECK=SKIP:cost-gated`, not `SKIP:already-banked`** — this row previously named a token the shipped code does not emit, and a reader reconciling the run's `VERDICTS.txt` against this table would have found a mismatch. Corrected 2026-09-11 while settling reviewer R5's one unresolved item (R5 could not find the banked PASS because it grepped `KC_G_CHECK`; the token is `KCG_CHECK`). ⚠ **Two caveats travel with the banked PASS and are not optional:** the token string came from a **VM-side wrapper that was never committed** — `solve.c` prints the output shape `KC-G CHECK n=%d PASS (…)`, which is the verdict-by-output-shape pattern this project bans — and **`F2_GCHECK_DETECTS=NO`**: the check passes on ladders corrupted through the adopt path. **Ladder soundness rests on provenance, not on this check.** 🔻 **FINDING (C-03): the banking record is an internal build report, not a public artifact.** The *check itself* is public and re-runnable — 🔎 **PUBLIC ANCHOR:** `git grep -n -- "--kc-g-check" <sha> -- solve.c documentation/SOLVE_C_CLI.md`, and the n=9 leg is `scripts/tr12_expected/n9/a2_gcheck.txt`. | SCAN-class | `TR12_GCHECK=SKIP:cost-gated` |

**A3 — t-ladder mounted.** 🔴 **ADDED 2026-08-22 (backlog Q-08).** The run order verified f shas
(A1.1) and g shas (A2.1) *"before trusting any number"* and had **no t equivalent at all** — while
the t ladder is the one built on pre-emptible capacity **with four recorded interruptions**, and the atlas is the
headline section. `--f1c5-layer-sha` handles t natively (verified: it reports `kind=t`), so this was
a missing STEP, not a missing capability.

| step | command | class | token |
|---|---|---|---|
| A3.1 | `$SOLVE --f1c5-layer-sha "$TDIR"` — 32 t layer digests vs their sidecars, **before `--kc-tdir` is passed to anything** (see the note under A1.1) | POINT | `TR12_TSHA=PASS` |
| A3.2 | `$SOLVE --kc-t-check "$FDIR" "$TDIR"` via `roae-private/scripts/staget_check_verdict.sh` (it emits a `KEY=value` token; the raw command
prints a SHAPE). ⚠ **Access boundary:** that wrapper lives in the project's private repository and is
not publicly readable; nothing here depends on it — the public path is to run `--kc-t-check` directly
and read its output | SCAN-class | `KCT_CHECK=PASS` |

> 🔴🔴 **TWO DIFFERENT HASHES, AND THE RUN ORDER CONFLATES THEM (found 2026-08-22, Q-08).**
> `--f1c5-layer-sha` prints **`sha256(DECOMPRESSED)`** — the payload, excluding the header magic.
> The ladder hash registry stores **`sha256(RAW FILE)`** plus its md5. Measured on the same layer
> file, the two digests differ, as digests of two different byte streams must:
> ```
> tool  (decompressed)  <digest A>
> raw file sha256sum    <digest B>      # different byte streams, therefore different digests
> ```
> **They are digests of different byte streams.** So A1.1's *"32 shas vs the registry"* and A2.1's
> *"32 g shas vs the registry"* are **NOT EXECUTABLE AS WRITTEN** — a direct comparison fails on
> **every** layer, not one. The canonical registries are raw-file digests, as their own names say,
> and the archive driver gates on them.
>
> 🔻 **FINDING (C-04) — RESOLVED 2026-09-06.** When written, the ladder hash registry and its archive
> driver were internal and the registry files were not public. **They are public now**, at
> `runs/20260906_kc_ladders_n31/`, in BOTH attestations and for all three stages:
> `STAGE_{F,G,T}_SHA256.txt` and `_MD5.txt` (65 rows each — raw-file digests, the registry kind) and
> `STAGE_{F,G,T}_LAYERSHA.txt` (32 rows each — logical/decompressed content, what `--f1c5-layer-sha`
> prints). So A1.1's *"32 shas vs the registry"* and A2.1's are now **executable as written**, provided
> each is compared against the registry of its own kind — which is the distinction this note exists to
> make. The n=13 check below remains valid and still needs no private artifact.
> ⚠ Do not read the two registries against each other: they digest different byte streams and
> disagree on every layer by construction.
>
> **Use `sha256sum` when comparing against a registry.** `--f1c5-layer-sha` is a *different and also
> useful* attestation — content identity that survives a re-compression — but it is not the registry
> digest and must not be described as if it were. Left as a documented correction rather than a
> silent edit to the commands, because which attestation each step wants is an operator call.
>
> ⚠ **And bind the KIND either way.** `--f1c5-layer-sha` reports
> **`sha256(decompressed)`**, i.e. the payload, excluding the header magic. Measured at n=13 across
> all 42 f/g/t layer digests: **exactly one collides across ladder kinds** — the terminal `t` and `g`
> layers share a digest because their terminal payloads are identical, even though the FILES differ
> at byte 5 (`F1C5TLY` vs `F1C5GLY`). A registry of bare shas therefore **cannot detect a t/g swap at
> the terminal layer.** The tool prints `kind=` on every line; record it, and compare it.
>
> 🔎 **PUBLIC ANCHOR — this one is fully reproducible with no private data.** Build the three n=13
> ladders from the public binary and compare the two attestations directly.
> ⚠ **Corrected 2026-09-07.** These lines previously read `--kc-build 13 <dir>/f`. The pair count is
> `--f1-pairs N`, never a positional, so as published the command took `13` as the OUTPUT DIRECTORY
> and built **n=9** into a folder named `13` — measured: `[kc] build: n=9 … count=26112`, 21 files
> written to `./13/`. An anchor labelled *fully reproducible* has to be run before it is labelled.
> ```
> $SOLVE --kc-build   <dir>/f --f1-pairs 13
> $SOLVE --kc-g-build <dir>/g --f1-pairs 13
> $SOLVE --kc-t-build <dir>/f <dir>/t
> $SOLVE --f1c5-layer-sha <dir>/g   # prints kind= and sha256(decompressed)
> $SOLVE --f1c5-layer-sha <dir>/t
> sha256sum <dir>/g/*.bin <dir>/t/*.bin   # the OTHER digest: sha256(raw file)
> ```
> The terminal-layer collision and the tool-vs-`sha256sum` divergence both appear.

> **🔴 Checkpoint before Group B.** `$VERD` must already contain every A-group token. Copy `$OUT`
> off the compute host **now**, as a standing rule of this project. If the scan then dies, nothing
> above is lost.

### Group B — THE SCAN. ~~One shot, unresumable.~~ 🔴 **PREMISE RETIRED (§8.4):** `--kc-layers A B` + `--kc-scan-merge` landed; the scan is chunkable/restartable per layer. The run-order rationale and the Standard-priority argument below were derived from the unresumable premise and need operator re-derivation before Group B is scheduled.

```bash
# preconditions, all four, in order:
#  1. g-ladder placed on fast storage (a metadata operation, seconds -- do it BEFORE the
#     run, not after you are confused by an apparent hang)
#  2. Stage T complete: last_complete_k=0 AND  $SOLVE --kc-t-check "$FDIR" "$TDIR"  passes
#  3. binary built from a branch that HAS --kc-scan; record the BINARY GIT_HASH (453e1bf, not a launcher pin)
#  4. accept that an UNCHUNKED pass restarts from zero. The one prior attempt reached a low
#     single-digit percentage of the corrected total -- not the ~quarter implied by the withdrawn
#     denominator -- and it was deliberately stopped to free its host, not failed. There is no
#     checkpoint in an unchunked pass; use --kc-layers (see 8.4).
$SOLVE --kc-scan-selftest                 # PASS (0 failures) or STOP. Never skip this.
$SOLVE --kc-t-check "$FDIR" "$TDIR" --kc-ooc --kc-cache-mb 32768
$SOLVE --kc-scan "$FDIR" "$GDIR" $OUT/atlas.json --kc-tdir "$TDIR" --kc-raw \
       --kc-ooc --kc-cache-mb 32768
# progress: read /proc/PID/io read_bytes -- NOT fdinfo pos. The out-of-core index sits at EOF,
#           so pos reports 100% having read almost nothing. (The project's progress-estimator
#           script is internal; the /proc technique is the whole of it, and is stated here.)
```
- **`--kc-raw` is REQUIRED** at n=31 or `marginal_raw` is not emitted and **V1 dies.** The RAW frame
  is automatic only at `n ≤ 13`.
- 🔴 **Wall WITHDRAWN and restated 2026-09-05.** The previously published wall was a quotient of two figures, the numerator of which descended from a **single unsourced comment on a script default**. Re-derived, the scan's wall is **days, not hours**, and a `--kc-layers`-chunked run saturating fast storage is still **days**. Confidence MEDIUM. 🔻 **FINDING (C-05): neither the withdrawn figure nor its replacement has a public reproduction command**, so this draft publishes the **direction and order of magnitude** and withholds the numbers rather than shipping an unreproducible figure (Appendix B). Monetary figures are omitted from this public draft entirely (Appendix D). Internal gates
  `per_layer_flow_eq_N`, `raw_marginal_sums_eq_N`, `branch_masses_sum_eq_N`,
  `class_row_sums_eq_N` (every layer's distance-class row sums to `N`),
  `quotient_marginal_sums_eq_N` (every layer's quotient-frame marginal row sums to `N`) and
  `class_column_sums_eq_b0_N` (summed down the layer axis, the class-`d` mass is `b0[d] * N` — the
  only one of the seven that can see a mass-preserving rearrangement within a layer row) must all
  report `true` with `fails: 0`. The last three were added 2026-09-08. 🔻 **Seven advertised keys
  are not twelve gate families:** the tail runs twelve and the other five reach the JSON only
  through `fails`, so read `fails` first; every advertised field collapses to `"see fails"` if any
  gate failed, named or not. There is deliberately no vertical `quotient_marginal` gate — see
  [SOLVE_C_CLI.md](SOLVE_C_CLI.md).
- Host priority: **non-pre-emptible** for any unchunked pass. At a multi-day wall, the probability that a single unchunked run survives on pre-emptible capacity is effectively **zero** — the mean time between interruptions measured on this workload is hours, not days. Chunking is therefore not an optimisation here; **it is the only viable shape.**
- If `PENDING:--kc-layers A B` (WORKSTREAM O-9 option A) lands, this becomes ~n restartable chunks
  and pre-emptible capacity becomes viable — **but only after** "chunked atlas == whole atlas at n=9" is shown able
  to fail, and `--kc-scan-selftest` is still 10/10.

Token: `TR12_SCAN=PASS`.

### 🔴 WHAT THE MERGE'S GATES DO **NOT** ESTABLISH — required disclosure for any merged-atlas number

Added 2026-09-10, from two independent external rounds that agreed and one adjudication that
sharpened the result by execution.

`--kc-scan-merge` re-runs every atlas gate on the reassembled table, and those gates are real: an
added class count fails the row equation, and swapping `d1`/`d2` within one row fails the column
equation. **But they establish CONSERVATION, not CELL CORRECTNESS.** Measured:

> **swapping two layers' entire `by_class` objects merges to `KC_SCAN_MERGE=OK` with a wrong atlas.**
> Both conservation equations still balance, because each row's total is preserved — they have
> simply been attached to the wrong layers. **The merge trusts chunk cells.**

So a merged atlas carries this guarantee and no more: *the parts sum correctly, each layer was
supplied exactly once, and the ladder digests and engine identity bind.* It does **not** carry
*"every cell holds the value that layer's computation produced."*

**Consequences that must travel with any published number derived from a merged atlas:**

1. **State the scope.** A `flow[k]`, `by_class[k][c]`, `qmarg` or `rawmarg` figure from a merged run
   is conservation-checked, not cell-verified. [[feedback_proven_scope]]: a scoped result must state
   its scope.
2. **A whole-shot run does not have this exposure** — there are no chunks to mis-attribute. The n=9
   `b_chunked` identity block proves *chunked == whole* **at n=9**, and that is the strongest
   evidence we have; it is not a proof at n=31.
3. **The cheapest closure**, if the guarantee is wanted: bind each chunk's rows to the layer range
   that produced them, so a row landing at the wrong `k` is refused rather than summed. Not built.

### 🔴 And at n=31, NOTHING catches it — measured 2026-09-10

The layer-swap was run against **every** check on the path, not only the merge gates:

| checked against | result |
|---|---|
| the merge's own gates | `KC_SCAN_MERGE=OK`, `"fails": 0`, `TIDENTITY=VERIFIED` |
| the consumer, `atlas_queries` | rc 0, **every `TR12_*` token green** |
| the 22 n-independent selftest gates | **0 failures of 22** |

**A whole-row permutation preserves every row sum, every column sum and every divisibility test**,
so the conservation family cannot see it by construction, and the only **exact** detector in the
pipeline is the **brute-force recount**, which is permanently impossible at n=31.

A **statistical** detector now also exists, and the measurement that came with it narrows what it is
worth. `solve.py --kc-class-swap-detect` classifies the retained Q4AC `--kc-sample` draw by
`popcount(exit ⊕ entry)` and compares it against `by_class`, on a path that uses f-based unranking
and touches neither the g ladder nor the extractor — so it is not closed over the thing it checks,
and the draw it needs is already paid for and retained by the driver's `--keep`. Its resolution is a
simultaneous Hoeffding bound, about **±0.0025 of total mass at the production M=10⁶** over 155 cells,
so it sees only mis-attribution whose induced mass shift exceeds that. It is a gross-mis-attribution
detector, not cell verification.

🔻 **Measured, not assumed, and it does not rescue the case this section is about.** Swapping *every*
layer pair of the real n=13 atlas against a real 10⁶ draw detected **23 of 78 pairs — exactly those
involving layer 0 or layer 1 — and missed all 55 pairs among the interior layers 2..12**, whose rows
differ by at most 0.0017549 of total mass (median 0.000103; the median would need ~5.5×10⁸ draws).
At n=9, 35 of 35 pairs were detected, which is what a small universe with no deep interior looks
like. **The 1↔2 swap is caught because layer 1 is the anchor transient, not because interior swaps
are caught.** So the conclusion of this section stands, now on measured rather than by-construction
grounds: **a swap between two deep interior layers at n=31 is expected to remain undetected.** The
new instrument covers the anchor-adjacent layers; it does not cover the interior case named here.
That expectation is extrapolated from two universes plus a convergence argument — it is not a
measurement of n=31.

🔴 **And the one structural check that WOULD catch it is removed by cost.** `TR12_SCAN_CHUNKED`
compares a chunked atlas against a whole-shot atlas and skips as `SKIP:no-atlas` when the whole-shot
run is absent. **The full-31 scan is planned chunked** (~31 chunks + merge), and running a whole-shot
pass as well means **paying for the most expensive operation in the programme twice**. So the
instrument that would detect a mis-attributed chunk is exactly the instrument the cost gate removes.

What it would change, if it happened: `v2_river.tsv`, `v5_grammar.tsv` and `q6_layer_mass.tsv`,
four rows each.

⚠ **This is a limit on the instrument, not a defect found in any produced atlas.** No merged atlas
has been shown wrong. What has been shown is that this class of wrongness would not be caught here —
and now, more precisely, that at n=31 it would not be caught **anywhere**.

### Group C — POST-SCAN. Milliseconds on a tens-of-KB JSON.

Everything here is `PENDING:atlas-consumer` — **`solve.py::atlas_queries`**, not
`scripts/atlas_queries.py` — plus figure rendering. *(Path corrected 2026-09-05: the planned path
`scripts/atlas_queries.py` was never created and resolves nowhere; §8.1 has recorded the real
landing site since 2026-08-22, and this line had gone on naming the plan. Check it with
`git grep -n "def atlas_queries" -- solve.py`.)*
None of it touches a ladder; all of it can be **rehearsed to completion at n=9 against
`fixtures/kc_n9/atlas_n9.json` before the scan ever runs** — and it should be.

| step | item | token |
|---|---|---|
| C.1 | atlas integrity re-read: `gates.fails == 0`, `N_total == N`, `t_source == "t-ladder"` for every branch | `TR12_ATLAS=PASS` |
| C.2 | **XA-a**, **XA-b** — branch table; gates `Σ solutions == N`, `Σ prefixes + trunk == t(root)` | `TR12_XA_A`, `TR12_XA_B` |
| C.3 | **XA-c/d** — wall + EXHAUSTIBLE/INFEASIBLE verdict. ⚠ **Withheld**: the token is `PENDING:W0-D-node-mapping` (§9.6) and the "exact shortfall factor" wording is WITHDRAWN (§3 row) — it would relabel a t-unit count as a node count | `TR12_XA_CD` |
| C.4 | **XA-24** — mod-24 gate on every headline count | `TR12_XA_MOD24` |
| C.5 | **Q10a** — orbit census + per-layer `≡ 0 (mod 24)` | `TR12_Q10A` |
| C.5b | **Q10a** — the KW-orbit-rank leg, as a MEASURED null (N3, 2026-09-10; row `c_q10a_kwrank`, cost ~0) | `TR12_Q10A_KWRANK` |
| C.6 | **Q6** (reduced form, §3.1) — `kw_p` / `kw_class_pct` **from the atlas alone, no Q3 join** (⚠ this row read "joins the atlas to Q3's `mass_below`" until 2026-09-05, the method §3.1 and §9.3 both retract) | `TR12_Q6` |
| C.7 | **V1** field, **V2** river, **V5** grammar — TSVs then figures | `TR12_V1`, `TR12_V2`, `TR12_V5` |
| C.8 | **Q10b** coset census — only if `PENDING:--kc-coset-census` lands; exploratory-frontier discipline, held privately until the circularity audit clears it | `TR12_Q10B` |
| C.9 | aggregate | `QUERY_PROGRAM=PASS` |

### Group D — teardown discipline
Copy **all** of `$OUT` off the compute host before releasing it. Fold every host-dependent task in
first — once the ladders are detached, every POINT query above costs a remount.

---

## 6. 🔴 Correction to the landing-day sequence in the readiness plan

🔻 **FINDING (C-08): the readiness plan is an internal document.** The correction is reproduced in full below so the reasoning stands on its own, and its *consequence* is public: the run order that `scripts/tr12_repro.sh` actually implements is the corrected one — Q3, the Q3 reader check, EW-1 and V4 all sit in Group A2 (pre-scan) in the committed battery. 🔎 **PUBLIC ANCHOR:** `git grep -n 'a2_q3\|a2_q3_reader\|a2_ew1\|a2_v4' <sha> -- scripts/tr12_repro.sh`.

That file's landing-day sequence reads:
```
point queries Q1 Q2 Q4 Q7 Q8  ->  the scan  ->  atlas queries Q3 Q6 V1 V2 V5 XA EW-1
```
Two placements are wrong, and both make the plan **more** exposed to a lost scan, not less:

- **Q3 is not atlas-derived.** It is `--kc-o3-rank FDIR GDIR KW --kc-trace`, which needs f+g and
  **no atlas at all**. Verified by execution at n=9: the trace emits the full per-step
  `f / g / g_parent / p / bits` table plus the `Π p_i = 1/N` summary. Q3 belongs in **Group A2**.
- **EW-1 rides Q3**, so it moves with it — also **Group A2**. EW-1 is the program's lead
  exploration instrument; leaving it downstream of an unresumable multi-day pass risks it for no
  reason.
- Minor: "Q1 needs `--kc-rank`" understates it. `--kc-rank` gives the **REL** coordinate (row Q1b);
  the H3b certificate is `--kc-o3-cert FDIR GDIR KW`, which needs **f+g**, not f alone.
- Minor: `--kc-raw` is missing from that file's scan line and is **required** at n=31 for V1.

Net effect of the correction: **Q3, Q3-reader, EW-1 and V4 move from post-scan to pre-scan.** Four
more deliverables banked before the one irreversible step.

---

## 7. Coverage ledger — every item of the task, accounted for

| spec section | items | rows above | in scope now |
|---|---|---|---|
| §1 | Q1–Q9 | Q1, Q1b, Q1c, Q2, Q2b, Q2c, Q2d, Q3, Q4a/c, Q4b, Q5, Q6, Q7, Q8, Q9 | all except **Q5** (wave 3, not budgeted) |
| §2 | V1–V5 | V1, V2, V3, V4, V5 | all; V2/V5 in reduced form (§3.1) |
| §3 | XA | XA-iii, XA-a, XA-b, XA-c/d, XA-24 | all |
| §4 | LS sweep | LS-w0, LS-forced8, LS-exact, LS-audit, LS-cite | all except **LS-exact** (wave 3, not budgeted) |
| §5 | EW-1 | EW-1, EW-gov | both |
| §11 | Q10 + refinements | Q10a, Q10b, Q4-Gexact, XA-24, Q9-ceiling | all; Q10b gated on a PENDING flag |
| §9 | not-report-grade | **§4 above** | 8 exclusions enumerated verbatim |

**Reconciliation of the QL-1..13 questioner-lens backlog and the Q-22 adjudication's nine MISSING rows — 2026-09-04, §9.7:** 5 IN, 3 RIDER/partial, 12 OUT with reasons, 4 GAPs recorded, none queued.

**Not covered here because the task did not ask for them:** §6 CAP-1..8, §R reproduction-methods
spine (beyond `PENDING:tr12_repro.sh`), §10 capstone additions A–G. They are real worklist items;
they are simply out of this inventory's scope. Say so rather than implying they are done.

---

## 8. STATUS CORRECTIONS — 2026-08-29 audit overlay (Fable, Q-392 first half)

Landed by an internal audit record (🔻 **FINDING (C-09)**: the audit document is not public; every
row's *verification command* is given below so that nothing here has to be taken on trust). Each
correction was verified on 2026-08-29 against the public tree at `34933bed`, **preserved and pushed
as the tag `archive/v4-query-program-20260829`** — so the sha resolves for any reader even though the
branch name no longer does. Substitute that tag for `<sha>` in the commands below.
**In-place edits above are struck-through-and-dated, never silent**; this section is the record.

| # | correction | verification |
|---|---|---|
| 8.1 | atlas consumer LANDED 2026-08-22 in `solve.py` (not `scripts/atlas_queries.py`) | `git grep -n "def atlas_queries" archive/v4-query-program-20260829 -- solve.py` (the line number has moved since; the symbol has not) |
| 8.2 | `--kc-enum-desc` LANDED, own token `KC_ENUM_DESC=OK\|FAIL` | `git grep -n -- --kc-enum-desc archive/v4-query-program-20260829 -- solve.c`; expected block `scripts/tr12_expected/n9/a1_q2d.txt` (committed) |
| 8.3 | `--kc-extremal` LANDED as a flag; Q5's wave-3 SKIP unchanged | usage block solve.c:16701ff; `a1_q5.txt` |
| 8.4 | the scan is CHUNKABLE: `--kc-layers A B` + `--kc-scan-merge` LANDED; §5 Group B's "one shot, unresumable" premise and the Standard-priority argument derived from it need operator re-derivation (S-B 08-22; D6 08-27 restated) | `git grep -c kc-scan-merge archive/v4-query-program-20260829 -- solve.c` → **46** (re-measured 2026-09-05; the file recorded 47, a transcription slip of one — the flag is emphatically present either way); `scripts/tr12_expected/n9/b_chunked.txt` |
| 8.5 | `tr12_repro.sh` LANDED (public), plus `tr12_repro_gate.sh` + `scripts/tr12_expected/n9/` | `git ls-tree -r archive/v4-query-program-20260829 --name-only scripts/` |
| 8.6 | all five `viz/viz_kc_*.md` + `viz/report_figures.py::tr12_figures` LANDED | `git ls-tree -r archive/v4-query-program-20260829 --name-only viz/` |
| 8.7 | the "do not build `--kc-profile`" ruling was OVERTAKEN: the flag was built (with `--kc-profile-selftest`), is O3-independent (f/g point lookups, no ranking), and is the natural instrument for the Q-331-safe Q3/EW-1 | usage block solve.c:16664ff |
| 8.8 | Stage G Phase 2 BANKED `KCG_CHECK=PASS` 2026-08-20 → A2.10 and Q10a's `--kc-g-check` leg are skipped (~24 h saved in the query window). ⚠ The battery emits `SKIP:cost-gated`, not `SKIP:already-banked` — see A2.10 | internal build report — 🔻 **FINDING (C-03)**, above; the check itself is public and re-runnable |
| 8.9 | still PENDING, re-verified 08-29 and again 2026-09-05: `--kc-coset-census` (0 hits), `sat-c3min-driver`, `kissat`/`drat-trim` (not on PATH; the `--witness` path still emits no DRAT) | 🔎 **PUBLIC ANCHOR:** `git grep -c -- --kc-coset-census <sha> -- solve.c` → 0, re-confirmed on `main` 2026-09-05 |
| 8.10 | `fixtures/kc_n9/atlas_n9.json` (cited in §3.1 and the 8.1 gate cell) is NOT in the committed tree; the committed n=9 ground truth is `scripts/tr12_expected/n9/` + `tr12_repro.sh --n9` (which builds its own ladders) | `git ls-tree -r archive/v4-query-program-20260829 --name-only \| grep atlas_n9` → empty (still empty on `main` today) |
| 8.11 | ~~§3.3 re-verified STILL TRUE 08-29: `lean/C1RuleConstants.lean` not on this branch~~ 🔴 **SUPERSEDED 2026-09-05 — the file is now present on the lineage; see the corrected §3.3.** True when written | `git merge-base --is-ancestor 9225098f archive/v4-query-program-20260829` → false **then**; `… 9225098f main` → **true now** |

⚠ **NOT corrected here because they need decisions, not edits** (queued as **Q-394**, riding the
already-open **Q-331** conditions): Q1's rank-0 labeling degeneracy and its redesign (O3′ or the
labeling theorem), Q1c descope-or-redesign (empty interval + the uncommanded per-draw O3-rank
leg), Q6's percentile leg (`mass_below` is not a percentile numerator — §3.1's "✅ served" cell
is WRONG per Codex A09), EW-1's calibrated null + the phantom Q8 band (no `bits` source in any
commanded output), Q10a's degenerate census (flow ≡ N ⇒ N/24 × 32) and its uncommanded
KW-orbit-rank leg, the XA-c/d consumer's t-unit/node pricing check, and reconciling the QL-1..13
/ Q-22-MISSING backlog into (or explicitly out of) this file's coverage ledger.

---

## 9. Q-394 REDESIGNS OVERLAY — 2026-09-04 (Fable, the seven decision-requiring items)

Landed by an internal redesign record (🔻 **FINDING (C-10)**: that document is not public; the
per-row verification commands below are, and every line reference in this section was re-checked
against the public tree on 2026-09-05 and holds). Every item was verified on public `main`
@ `9d7de84c` — post-merge, so **the consumers are public**. In-place edits above are struck-through-and-dated.
Rides Codex A09's four accepted findings (Q-331 items 1–4, adjudicated 2026-08-28) without
re-deriving them.

| # | item | ruling | verification |
|---|---|---|---|
| 9.1 | **Q1** O3 rank of KW | **DOC + GATE.** `rank3(KW)=0` is forced by KW-derived labels (`f1_pair_a/b = KW[2i], KW[2i+1]`, `pl[i]=i+1`, `orient = exit==pa`): every block contribution and every orientation bit is 0. Executed at n=9: as-implemented labels reproduce the fixture (13056/128/96); KW-style labels give 0; intrinsic O3′ labels give 2243/128/35. New whole-line token `TR12_Q1_LABELING=PASS` (all three of rank3/class_first/orient_idx = 0). REL (Q1b) is the reported coordinate. O3′ = PROPOSED (needs a second ranker in `solve.c` + its own n=9 total-order gate; expected n=9 value now pinned). | 🔎 **PUBLIC ANCHOR, re-verified 2026-09-05:** `git show 9d7de84c:solve.c \| sed -n '13474,13475p;14092p;23062,23069p;23090p;25173,25176p'` shows exactly the KW-derived labelling this ruling turns on (`f1_pair_a[i] = KW[2*i]`, `pl[i] = i + 1`, `orient: 1 <=> exit == pa`). 🔻 **FINDING (C-11): the n=9 gate script `o3_labeling_n9.py` is NOT in the public tree** — the ruling's *premise* is publicly readable, its *rehearsal* is not |
| 9.2 | **Q1c** | ~~**DESCOPE → `TR12_Q1C=SKIP:merged-into-Q4AC`.**~~ **SUPERSEDED 2026-09-10 (N3) by `TR12_Q1C=EMPTY:interval-degenerate-at-n31`, which is measured rather than declared — see the Q1c row in §1.** The original ruling stands on the facts: Empty interval at full-31 + uncommanded O3-rank leg (the battery's `a2_q1c` spends one `--kc-o3-rank` descent per draw, `tr12_repro.sh:848–862`). `P(C3 ≤ 387)` + Wilson CI at M=10⁶ is a Q4a/c column; raw per-draw `cd` retained (QL-10). | as above |
| 9.3 | **Q6** percentile leg | **REPLACE** `kw_mass_below`/`kw_pct` by `kw_class_mass`, `kw_p = m_k(d_KW)/N`, `kw_class_pct = Σ_{d: m_k(d) ≤ m_k(d_KW)} m_k(d)/N` — defined for every walk, no Q3 join. n=9 expected values pinned in the landing doc; reduced-n emits −1 placeholders. `c_q6.txt` needs a two-key regold. Fix lands once here; Q-48 (confirmed) and Q-331(3) close by reference. | 🔎 **PUBLIC ANCHOR — the patch has since LANDED, so the private patch file is moot:** `git grep -n "def atlas_emit_q6" <sha> -- solve.py`, and the pinned n=9 values are in the committed golden `scripts/tr12_expected/n9/c_q6.txt` (`anchor_p` `0.544117647`; `anchor_class_pct` `0.419117647` at k=3 and `0.209558824` at k=7 — checked against the committed blob 2026-09-05) |
| 9.4 | **EW-1** | **ADOPT the calibrated null (P3).** Band source = 1,000 `--kc-profile` runs over the Q8 gallery walks (the `q8_super.tsv` "band" was PHANTOM — no `bits` column). Statistic `top1_share`; KW vs gallery 1st/99th percentiles, two-sided, once; outcomes `localized-constraint-candidate` / `typicality-bound` / `anti-concentration`; per-step extremes display-only. Token `TR12_EW1_NULL=<verdict>`. n=9 rehearsal: gallery 200 walks, p01 .2104 / p50 .2387 / p99 .3316, anchor .2360 → `typicality-bound`. | 🔻 **FINDING (C-12): the n=9 null rehearsal script `ew1_null_n9.py` is not in the public tree**, so the quoted gallery percentiles are not publicly reproducible. The instrument they use **is** public: `git grep -n -- --kc-profile <sha> -- solve.c documentation/SOLVE_C_CLI.md`, with `--kc-profile-selftest` |
| 9.5 | **Q10a** | **RE-SPEC.** Keep the mod-24 gate; state `N/24` once; the census content = per-layer **state census by G-orbit-size class + branching histogram from the f-ladder sidecars** (`orbit_size_census`, `branching` — already emitted by `--kc-build`, n=9 table in the landing doc §5; ⚠ schema-v2 builds only — the n=31 f ladder's sidecars are schema v1 and lack `orbit_size_census`, see §11 Q10a); ~~KW-orbit-rank leg DROPPED with reason.~~ **Its reason is now MEASURED, not written down: row `c_q10a_kwrank` / `TR12_Q10A_KWRANK` (N3, 2026-09-10).** | `kc_n9/f1c5_layer_stats_0*.json` |
| 9.6 | **XA-c/d** consumer | **DEFECTIVE on `main`** (`solve.py:12091` heading `t-units = pruned-DFS nodes`; `:12124–12132` prices and emits EXHAUSTIBLE/INFEASIBLE). Pricing path must refuse until a `--xa-node-mapping-cert` (W0-D) is supplied: `TR12_XA_CD=PENDING:W0-D-node-mapping`. Tested: original → 12 EXHAUSTIBLE rows + PASS; patched → PENDING, no rows. | 🔎 **PUBLIC ANCHOR, re-verified 2026-09-05:** `git show 9d7de84c:solve.py \| sed -n '12091p;12124,12132p'` — the heading `t-units = pruned-DFS nodes` and the EXHAUSTIBLE/INFEASIBLE pricing loop are both there. The public battery now skips the row for the same reason: `git grep -n "c_xa_cd" <sha> -- scripts/tr12_repro.sh` → `SKIP:xa-throughput-anchors` |
| 9.7 | **QL-1..13 + Q-22 MISSING** | **RECONCILED** (landing doc §7): IN — QL-4, QL-10, QL-11, QL-13 (Q7 widening: REL ranks), A-39 (Q4b's `--c3-min`); RIDER/partial — QL-3 (REL only; vacuous under O3), QL-6 (state-weighted half via 9.5), QL-8 (sidecar hists), A-14/A-20 (partial via Q7/V4/Q1b); OUT with reason — QL-1 (capstone P3), QL-2/A-37 (P2 ledger; GAP), QL-5 (f·g pass, TO-VERIFY; GAP), QL-7 (window passed), QL-9 (engine campaign), QL-12 (doc), A-19/A-15 (circularity), A-18 (§9(3)), A-41 (harness gate), A-29 (wave 3). | — |

Public-tree consequences handed over, NOT applied at the time: the `solve.py` patch (items 9.3 +
9.6), `tr12_repro.sh` rows `a2_q1c` (→ SKIP) and `a2_ew1` (+ null leg), and the regold of
`c_q6.txt` — all under the two-key discipline.

✅ **STATUS 2026-09-05, checked against committed blobs:** items **9.2 and 9.3 have LANDED** —
`scripts/tr12_repro.sh` carried `row_skip a2_q1c TR12_Q1C "SKIP:merged-into-Q4AC"` until 2026-09-10, when N3
replaced it with the measured verdict described in the Q1c row of §1, and
`scripts/tr12_expected/n9/c_q6.txt` carries the regolded `anchor_*` columns. Item **9.6 has NOT**:
the public battery reaches the same outcome by a *different* route (`c_xa_cd` skips as
`SKIP:xa-throughput-anchors` rather than `PENDING:W0-D-node-mapping`), so the verdict is
withheld either way, but the two tokens are not the same token and a reviewer should know that.

---

## 10. D5 LANDINGS OVERLAY — 2026-09-05 (Fable; D5-02/-03/-04/-08 applied to the public working tree, uncommitted)

🔎 **PUBLIC ANCHOR — this entire section is already published.** `documentation/VERIFY.md` carries
the same four corrections in prose, including the figures quoted below; read it with
`git show <sha>:documentation/VERIFY.md | grep -n "CORRECTED 2026-09-05"`. Each row carries its own
red/green gate, and **all four gate scripts are committed**:
`scripts/d5_02_q8_chi2_gallery_gate.sh`, `d5_03_ls_w0_exact_gate.sh`, `d5_04_q7_witnesses_gate.sh`,
`d5_08_q6_q10a_shell_gate.sh` — wired into `scripts/tr12_repro_gate.sh`.

Battery counts after the change were recorded as `rows=60 pass=47 fail=0 skip=13` (from
`57/45/0/12`: +`a0_ls_w0_mc` PASS, +`a1_q8_midn13` PASS — the renamed self-test — and
+`a0_q7_witnesses` SKIP). **Re-derive them rather than trusting them:** `bash scripts/tr12_repro.sh
--n9` prints the `rows=… pass=… fail=… skip=…` line itself.
✅ **C-13 — RECONCILED 2026-09-05 by running the battery, which this draft had declined to do.**
`skip=13` counts skipped **rows**; `_EXPECTED_SKIPS.txt` pins fifteen **tokens**. The two extra
tokens are `TR12_Q7` and `TR12_V3`, which are not rows at all: they are produced by the driver's
`agg` aggregator (`scripts/tr12_repro.sh:1480` and `:1485`) from their legs, and their pinned values
say so in their own text — `SKIP:leg-TR12_Q7_RANKS` and `SKIP:leg-TR12_V3_FIG`. Every one of the
other thirteen comes from a `row_skip` call, which is a row. 15 − 2 = 13, exactly. Reproduce:
```
bash scripts/tr12_repro_gate.sh        # → TR12_REPRO_GATE=PASS, "skip set matches the pin"
grep -n '^agg TR12_' scripts/tr12_repro.sh
```
The guess this draft recorded was right, but it was a guess; it is now a measurement.

| # | row | what the row now does | what it did until 2026-09-05 | gate |
|---|---|---|---|---|
| 10.1 | **Q8** `a1_q8_chi2` / `TR12_Q8_CHI2` | chi² over 16 rank buckets of the GALLERY (`q8_super.tsv` rank column), bucket `⌊16·rank/N⌋` in `bc` integer arithmetic, `chi² = (16S−k²)/k`, bar 37.70 decided in integers; exits 1 on FINDING. Reproduces the 2026-08-07 T4 figure on the real 1000 draws: buckets `[71,55,64,59,75,58,53,74,51,49,64,60,58,81,60,68]`, chi² 20.224. The `--kc-midn 13` self-test is its own row `a1_q8_midn13` / `TR12_Q8_MIDN13`, still a leg of `TR12_Q8` | ran `--kc-midn 13 --kc-chi2-samples 20000` (the engine's n=13 self-test) under the Q8 chi² token | `d5_02_q8_chi2_gallery_gate.sh` (7 legs, 5 mutants) |
| 10.2 | **LS-w0** `a0_ls_w0` / `TR12_LS_W0` | `solve.pair_null_gender_le2_exact()` = **47/445740** (TR-8 v1.6, exact, two-way verified) + KW's own `rc4_violations` = 2 (the event's level). The `--null-pair-constrained 10⁶` MC survives as `a0_ls_w0_mc` / `TR12_LS_W0_COND_MC`, labelled "NOT the TR-8 pair-only null: C2\|C1, C3\|C1 conditional MC" | ran the C2\|C1 / C3\|C1 MC under the LS-w0 token | `d5_03_ls_w0_exact_gate.sh` (4 legs, 3 mutants; the 47/445740 literal is pinned from TR-8, not read from solve.py) |
| 10.3 | **Q7** `a0_q7_witnesses` / `TR12_Q7_WITNESSES` | named skip `PENDING:kissat` (or `PENDING:q7-witness-row` if kissat is present — the row is unbuilt either way: no reproducibility contract for a solver-chosen witness), aggregated into `TR12_Q7` → parent reads SKIP. **No non-KW sequence gets a serial number**; the 2026-07-17 sentence of the query specification is annotated WITHDRAWN at its source, and the withdrawal is **also public** — `documentation/VERIFY.md` states it as "no non-KW sequence receives a serial number in this battery, and that sentence of TR-12 is withdrawn until the witness row exists" | `TR12_Q7` aggregated KW+HIST+RANKS only and would have read PASS at full-31 with the witness leg uncommanded | `d5_04_q7_witnesses_gate.sh` (4 legs, 4 mutants) |
| 10.4 | **Q6** `c_q6` / `TR12_Q6` (shell leg) + `solve.py atlas_emit_q6` (consumer, Q-394 patch item 3 APPLIED) | columns `anchor_d, anchor_class_mass, anchor_p = m_k(d_k)/N, anchor_class_pct = Σ_{d: m_k(d)≤m_k(d_k)} m_k(d)/N` from the atlas `by_class` + the profile `dclass` column (step k+1 ↔ layer k). n=9 values = §9.3's pre-registered ones exactly (anchor classes 1,2,2,4,2,2,1,4,2; `anchor_p` .544117647 …; `anchor_class_pct` 1,1,1,.419117647,1,1,1,.209558824,1). Consumer emits `kw_class_mass, kw_p, kw_class_pct` (−1 below n=31) | `anchor_mass_below` / `anchor_percentile` from `--kc-trace mass_below` | `d5_08_q6_q10a_shell_gate.sh` (4 legs, 4 mutants) |
| 10.5 | **Q10a** `c_q10a` / `TR12_Q10A` (shell leg) | N/24 stated once; per-layer mod-24 gate; per-layer state census by G-orbit-size class + branching histogram transcribed from the f sidecars (`f1c5_layer_stats_XX.json`: `n_masks, n_entries, mass_total, orbit_size_census, branching.hist`; `orbit_size_census` is absent from schema-v1 sidecars, including the n=31 f ladder's, and is reported `NA:schema-v1-sidecar` there); a missing/unparseable sidecar FAILS; last sidecar `mass_total` must equal N. n=9 table = §9.5's exactly. ~~KW-orbit-rank leg dropped.~~ **KW-orbit-rank leg is now its own measured-null row `c_q10a_kwrank` / `TR12_Q10A_KWRANK` (N3, 2026-09-10); line (iv) of `c_q10a`'s header points at it instead of asserting the result.** **The consumer half (Q-394 §5(ii) "30 lines of solve.py") is NOT written**; `atlas_emit_q10a` still emits the mod-24 table with `orbits = flow/24` | N/24 printed once per layer as "orbits" | same gate (4 legs, 4 mutants); the KW-orbit-rank leg additionally by `n3_measured_nulls_gate.sh` since 2026-09-10 |

Not landed here, deliberately: Q-394 patch item 6 (XA-c/d `PENDING:W0-D-node-mapping`) — it changes a
verdict that `scripts/xa_exact_verdict_gate.sh` exercises and belongs to D5-09, not to the five
pre-freeze items; `a2_ew1` + null leg (§9.4); the Q10a sidecar consumer.

---

*Attribution: direction and the query program are the operator's; TR-12's query specifications are
by Claude (Fable 5), 2026-07-17. This inventory — the flag verification, the schema-gap findings
(§3.1), the reader-arithmetic split (§3.2), the branch finding (§3.3), the run-order corrections
(§6) — is by Claude (Opus 5), 2026-08-22. The 2026-08-29 audit overlay (§8) and the 2026-09-04
redesigns overlay (§9) are by Claude (Fable 5); the 2026-09-05 D5 landings (§10) likewise. This
public draft — the novelty scrub, the figure→command audit, the public-anchor sweep and the
infrastructure/cost scrub, together with the §3.3 and §8.11 staleness correction and the §8.4
re-measurement — is by Claude (Opus 5), 2026-09-05. Developed with AI assistance (Claude, Anthropic).*

*This file is **a certificate of what the binary actually does, not a proof**. Everything in §1's
EXISTS list was executed at n=9; everything in the PENDING table was searched for in source and in
the compiled binary and not found. Where this draft says a thing is absent from the public tree, that
absence was checked against committed blobs (`git show <sha>:<path>`), not against a working tree —
the difference is the subject of §3.3. **Errors are Claude's; corrections are invited, and the
reviewer is asked to look for them.***

---

## Appendix A — novelty scrub register (pass 1)

The publication freeze of 2026-08-16 stands. The rule applied: **remove the ASSERTION, keep the
RESULT.** *"We enumerated X and found Y"* stays; *"this is the first X"* goes; a sentence doing both
is split. Markers swept: *first, novel, no one has, unprecedented, the only, previously unknown*, and
**unattributed priority — a claim that something is ours by silence about who else did it**.

**Result: 0 scrubs. 1 borderline, KEPT.**

That is not an oversight, and it is worth stating plainly rather than burying: **this file makes no
novelty claims to remove.** It is an engineering contract — commands, flags, verdict tokens, gaps.
The sweep found 18 occurrences of the marker words and every one is ordinal or temporal, not a
priority claim:

| site | text | why it is NOT a novelty assertion |
|---|---|---|
| §0.4(2) | "dropping the **first two** values" | ordinal position in a list |
| §0.4(3) | "this document's own **first draft**" | a self-correction, chronological |
| Q2c / A1.5 | "`FIRST^C15` — the in-order-**least**" | the name of a defined extremal object |
| XA-iii | "runs **FIRST**" | execution order |
| Q7 | "**first**-violated constraint" | ordinal within a pinned constraint order |
| §5 Group A | "Bank everything cheap **first**" | scheduling |
| §5 A2 | "before the **first** g read" | ordinal |
| §8 heading | "Q-392 **first** half" | a work split |
| §1, §3.1 | "the **new** n=9 gate", "a **new** emitter" | newly-required engineering, not priority |
| §9.1 | "**New** whole-line token" | a token that did not exist |
| §4, LS-w0 | "the **only** LS item inside the funded waves", "the **only** viable shape" | scope statements about *this program*, not about the literature |

**BORDERLINE (1), kept and flagged for a second reader:** the §11 section heading *"the
novelty-refresh addendum"*. It reproduces the title of TR-12's own §11 and asserts nothing, but it
does name a priority-oriented workstream, and under the freeze a heading that says "novelty" invites
the reader to expect a priority claim that this draft does not make. **Kept**, per the instruction
not to over-scrub: weakening a result to dodge a question is its own dishonesty, and a section title
is not a result at all.

Worth recording as the opposite finding: the file's prior-art behaviour is *good*. It credits
Suenaga (2012) and Ouyang (1990/1992) by name in LS-cite and calls Q10b's lens "the Ouyang lens" —
attribution, not appropriation. A search for priority-shape phrasing (`we were the first`, `no prior`,
`nobody has`, `uniquely`, `definitive`) returned **zero hits**.

---

## Appendix B — figure → reproduction-command audit (pass 2)

The standing rule: **never publish a figure ahead of its reproduction command.** Every asserted
figure in the file was classified. **Denominator: 42 figures** *(41 as first audited; the
pre-publication read on 2026-09-05 found one the audit had missed — see the correction at the end
of this appendix).*

| class | n | share |
|---|---|---|
| ✅ **already public** — the figure is committed in the public repo, with a command | **25** | 60% |
| 🔎 **public command exists** — reproducible by a public command, figure not itself published | **6** | 14% |
| 🔒 **private command only** — internal script or artifact | **5** | 12% |
| 🔻 **NO command** — withheld from this draft rather than published unreproducibly | **6** | 14% |

⚠ *(Tally corrected 2026-09-12, V3A-044#6: the R-1 throughput anchors moved from ✅ to 🔒, so the
first two counts were 26 and 4. This table's own class definition for ✅ requires the figure to be
public **with a command**; the anchors have a public citation — a skip **reason** in the battery —
and no public command, which is the 🔒 definition. Shares are recomputed on the stated denominator
of 42 and now sum to 100 %; they had been left on the pre-correction denominator of 41.)*

**This is comparable to the TR-12 audit** (76/97 already public, 9 with no command). It does **not**
change the operator's day-estimate.

**✅ Already public (26).** `N` and `N−1`, `N/2`, `N/24`
(`reports/FULL31_EXACT_AGGREGATES.md`; `documentation/CANONICAL_VALUE_STATUS.tsv`); the gallery seed
`9276183659154465378` (its derivation one-liner is printed in §0.4(1) *and* pinned in
`scripts/tr12_repro.sh`); `E[G] = 128`, `E[C3] = 1040`, support `[12,228]`,
`P(G ≤ 95) = 641983711307479/7919632354008375` (`python3 verify.py --check-null-g`, plus
`lean/C3Decomposition.lean`); `C3 = 16 + 8·G`; `47/445740` (TR-8, three sites); `×11,364`
(TR-1/TR-6/TR-8); `1395 = [6,3]₂` and the Suenaga credit (TR-11 §"novelty note"); the Q8 chi²
bucket vector and `chi² = 20.224` and the bar `37.70` (`documentation/VERIFY.md`); the Q6 n=9
`anchor_*` values (`scripts/tr12_expected/n9/c_q6.txt`); the twelve self-test names; the PENDING/LANDED flag
inventory (`documentation/SOLVE_C_CLI.md` documents 135 `--kc-*` mentions).

**🔎 Public command, figure not separately published (6).** `log₂ N ≈ 129.689` (one line of
big-integer arithmetic over the published `N`); the n=13 ladder-digest collision and the
tool-vs-`sha256sum` divergence (§5 A3 now carries the full build-and-compare recipe); the battery
counts `rows/pass/fail/skip` (`bash scripts/tr12_repro.sh --n9`); the `--kc-coset-census` absence
(a `git grep -c` returning 0); the n=9 atlas size; the `--kc-scan` point-lookup-vs-stream structure.

**🔒 Private command only (5).** The **R-1 throughput anchors `36.14×` (work factor) and `19.8×`
(wall at 1 T)** — *moved here from ✅ on 2026-09-12 (V3A-044#6). They are quoted in the battery's
`c_xa_cd` skip **reason**, which is a public citation but not a public command; the driver's own
words are that they "are campaign measurements, not atlas fields", and TR-12 §3 records that
re-deriving them would need a fresh paired benchmark that **is not authorised**. So the fix is the
label, not a run.* The Q1 labeling rehearsal (`o3_labeling_n9.py`, FINDING C-11); the
EW-1 calibrated-null rehearsal percentiles `.2104 / .2387 / .3316 / .2360` (`ew1_null_n9.py`,
FINDING C-12); the Q6/Q10a redesign patch (**now moot — the patch landed publicly**, FINDING
resolved); the Stage G `KCG_CHECK=PASS` banking record (FINDING C-03).

**🔻 No command — WITHHELD from this draft (6).** The single-branch-exhaustion shortfall factor
(§3 XA-c/d — added 2026-09-05, see below); the scan's corrected physical-read volume; its
honest band; the measured ladder-read throughput; the fraction of the scan the one prior attempt
completed; the mean time between host interruptions. Each is a private storage measurement with no
public reproduction path. **This draft states the direction and the order of magnitude and omits the
numbers.** That is a deliberate choice: a figure a reviewer cannot check is worse than an honest
qualitative statement, and the qualitative statement — *days not hours, and therefore chunk it* — is
the entire decision-relevant content.

**One figure was corrected by this audit:** §8.4's `git grep -c kc-scan-merge … → 47` re-measures to
**46** at the pinned sha. A one-off transcription slip with no bearing on the conclusion, corrected
in place rather than silently.

**And one figure this audit MISSED, found by the pre-publication read (2026-09-05).** §3's XA-c/d
row quoted the standing single-branch-exhaustion shortfall as a specific factor. It has **no public
reproduction command and no public anchor of any kind** — a `git grep` over the committed tree
returns nothing but an unrelated digit run inside a seed — and the companion TR-12 draft §3
explicitly refuses to quote it. **The audit walked past it because the numeral sat inside a
strikethrough**, and the classifier was reading live assertions. Strikethrough is a rendering
choice, not a redaction: the number still reaches the reader. The figure is now withheld and the
row says so. **The lesson generalises beyond this file — a figure-vs-command audit must classify
struck-through and commented-out text too**, and a reviewer should assume this audit's other rows
carry the same blind spot until re-run under the wider rule.

---

## Appendix C — private-reference sweep (pass 3)

The bar the operator set: *do not genericise a private pointer into vague prose — replace it with a
**public anchor**: a document, a runnable command, or a code site. Where none exists, report a
FINDING.*

**Pointers processed: 27. Anchored to a public artifact: 14. No public anchor (FINDING): 13** — of
which **one (C-13) was resolved on 2026-09-05** by running the battery this draft had left un-run,
leaving **12 open**.

**Anchored (14).** The atlas consumer (`solve.py::atlas_queries`); `--kc-enum-desc`, `--kc-extremal`,
`--kc-layers`/`--kc-scan-merge`, `--kc-profile`, `--kc-raw` (all `git grep`-able in `solve.c`, and
documented in `documentation/SOLVE_C_CLI.md`); `tr12_repro.sh` + `tr12_repro_gate.sh` +
`scripts/tr12_expected/n9/`; the five `viz/viz_kc_*.md`; the four Lean theorems (by name, since the
line numbers have moved); `sat.py`'s two kissat call sites; the Q4-Gexact null law
(`verify.py --check-null-g` + Lean); the D5 corrections (`documentation/VERIFY.md`); the four D5 gate
scripts; the Q6 regold (`c_q6.txt`); the `--kc-g-check` instrument; the n=13 digest-collision recipe;
the corrected run order (`a2_q3`/`a2_ew1`/`a2_v4` rows in the committed battery).

**FINDINGS — no public anchor exists (13 raised, 12 still open).** These are reported, not
invented around:

| id | claim | what is missing |
|---|---|---|
| **C-01** | the six authority documents this file obeys | internal planning records; the *executable* consequence is public |
| **C-02** | the corrected scan read-volume and wall | private storage measurements; numbers withheld (Appendix B) |
| **C-03** | Stage G banked `KCG_CHECK=PASS` | internal build report; the check itself is public and re-runnable |
| **C-04** | the ladder hash registry and archive driver | internal scripts; the defect class is reproducible at n=13 without them |
| **C-05** | the withdrawn and restated wall figures | as C-02 |
| **C-06** | the circularity-audit precedent | internal; the *criterion* is public in `reports/METHODS.md` |
| **C-07** | the pre-registration lock ledger | private; the practice is disclosed in `documentation/VERIFY.md` |
| **C-08** | the readiness plan's landing-day sequence | internal; the corrected order is what the public battery implements |
| **C-09** | the 2026-08-29 audit document | internal; every row's verification command is given |
| **C-10** | the 2026-09-04 redesigns document | internal; every row's line reference re-verified here |
| **C-11** | `o3_labeling_n9.py` (Q1 labeling rehearsal) | not in the public tree; the ruling's premise in `solve.c` is |
| **C-12** | `ew1_null_n9.py` (EW-1 null rehearsal) | not in the public tree; `--kc-profile` is |
| ~~**C-13**~~ | ~~`skip=13` vs fifteen pinned skip tokens~~ | ✅ **RESOLVED 2026-09-05** — battery run; the two extra tokens are the `agg` parents `TR12_Q7`/`TR12_V3`, which are not rows. See §10 |

**Internal tracker identifiers are retained, not scrubbed.** `Q-08`, `Q-22`, `Q-48`, `Q-331`,
`Q-392`, `Q-394`, `QL-1..13`, `A-09`/`A-14`/…, `D5-02`…, `W0-D`, `S-B`, `D6`, `R-1`. They disclose
nothing and they carry no evidential weight; they exist so that a finding can be traced to the review
that raised it. **A reviewer should treat every one of them as an unresolvable label**, and should
not accept any claim whose only support is one.

**One correction the sweep produced, rather than merely relocated:** §3.3's branch finding —
*"`lean/C1RuleConstants.lean` is NOT reachable from this branch"* — was true when written and
re-asserted on 2026-08-29, and is **false today**. Verifying it against committed blobs, as this pass
required, is what surfaced it. §3.3 and §8.11 are both corrected in place, with the original text
kept.

---

## Appendix D — infrastructure and cost scrub (pass 4)

**Removed: 47 hits, measured, leaving 0.** No host, storage, region or machine-size identifiers; no
filesystem mount points; **no monetary figures at all**; nothing Cook-derived (a search returned zero
occurrences). The count is a measurement, not an estimate — the same pattern set that finds 47 hits
in the source finds **0** here.

| category | hits | disposition |
|---|---|---|
| monetary figures | **20** | **all removed.** 13 were zero-cost markers on documentation-only rows → "no compute"; 3 were wave-3 sizing ranges → "not budgeted"; 4 were a scan cost range, an unsourced order-of-magnitude figure, a ladder cost and a lifetime-spend total → removed entirely, along with the spend-audit citation |
| mount points / paths | **5** | the home- and mount-rooted values in §0.1 → `<f-ladder directory>`-style placeholders. The **variables** are unchanged, so every command in the file still runs verbatim once the operator sets them |
| host / storage / machine identifiers | **11** | a named data host, two storage tiers, a disk class (×3), a machine size with its RAM figure, and a region-bearing name → replaced by the *property* that mattered (fast storage; RAM-bound not core-bound; non-pre-emptible) |
| pre-emption / host vocabulary | **11** | provider-specific priority and interruption terms, and machine-instance nouns → "pre-emptible capacity", "interruptions", "compute host" |

**Two judgement calls, stated so they can be overruled:**

1. **Wall times in days were kept; read volumes in TB were not.** A reviewer must know the scan is a
   multi-day step to judge whether the question is answerable at all — that is scope, not cost. The
   TB figures have no public reproduction command (Appendix B) and buy nothing the qualitative
   statement does not.
2. **Internal document *names* were removed, but their *existence* was not concealed.** Every one
   appears in Appendix C as a FINDING. The precedent runs the other way — `documentation/VERIFY.md`
   names a private document in a public citation — so this draft is *more* conservative than the
   repository's existing practice, not less. If the operator prefers the existing practice, restoring
   the names is a mechanical edit.

---

## Appendix E — what a reviewer should attack first

Offered because a review that only confirms is a review that was not charged properly.

1. **The four reduced forms (§3.1).** Q6, V2 and V5 ship in a *reduced* form because the atlas
   schema does not carry what the spec asks for. The file says so, and says "do not silently publish
   the reduced table as the spec's table". **Is the reduced form still worth reporting, or does the
   reduction hollow out the question?** This is the single most consequential judgement in the file
   and it is currently the operator's alone.
2. **The Q1 labeling degeneracy (§9.1).** `rank_O3(KW) = 0` is *forced* by KW-derived labels — the
   coordinate is vacuous by construction. The ruling is to publish it as a labeling theorem and
   report REL instead. **Is the proposed intrinsic relabeling (O3′) actually intrinsic, or does it
   smuggle KW back in by another route?** Nothing in this file establishes that it does not.
3. **The circularity exposure across LS and EW (§4 item 4, LS-audit, EW-gov).** Several functionals
   are extracted from King Wen and then measured against King Wen. The file's defence is a
   pre-registration protocol and an adversarial audit — **both of which are private** (FINDINGS C-06,
   C-07). **Does a protocol a reader cannot inspect discharge a circularity objection?**
4. **The XA-c/d verdict path (§9.6).** An EXHAUSTIBLE/INFEASIBLE verdict is priced by mapping
   t-units to DFS nodes, and that mapping is *explicitly unclaimed*. The row is skipped — but by two
   different tokens in two places (see the §9 status note). **Should a verdict this consequential
   exist in the code at all before its mapping certificate does?**
5. **`Π p_i = 1/N` (§3.2).** The engine asserts it; the reader is required to recompute it. **Check
   that the shipped consumer really does recompute it independently, rather than re-reading the
   engine's own summary line.** The file itself flags this as "do not let the engine grade its own
   homework" — that instruction deserves to be tested, not trusted.
6. **Every `PENDING:` row.** Four remain: `--kc-coset-census`, `sat-c3min-driver`, `kissat`, and the
   W0-D node mapping. **A PENDING that never lands is a question silently dropped** — which is the
   exact failure mode this file exists to prevent.
