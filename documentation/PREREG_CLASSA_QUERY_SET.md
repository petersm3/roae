
# Pre-registration — the class-A query set

> ## ⚠ PUBLISHED FOR ADVERSARIAL REVIEW — **NOT YET FROZEN**
>
> **This text is public so that it can be attacked before it is sealed, and the sealing has not
> happened yet.** The freeze is the **third-party timestamp**, not this commit: until an independent
> archive snapshot and an OpenTimestamps proof of these exact bytes are recorded in the escrow row,
> nothing here is frozen and this file may still change.
>
> **Why it is public first.** Two external reviews of the adjacent query specification returned
> **eighteen findings with none rejected**, three of them questions this repository had already
> answered — and every one had been cleared by an internal reader first. This document had five
> internal passes and no external one. Publishing it before the timestamp is what lets an outside
> reviewer read it while corrections are still possible; a defect found after the stamp would be
> permanent.
>
> **What that costs, stated rather than hidden.** The git history will show this text being corrected
> between publication and freeze. That is the intended behaviour and not a defect: the pre-hoc claim
> is about the **question text** being fixed since 2026-07-17, not about the surrounding document
> never being edited. **Any change to a question's own text between now and the freeze will be
> recorded here explicitly**, because that would weaken the claim and a reader must not have to
> diff commits to discover it.

**Drafted 2026-09-05; published for review 2026-09-06; frozen when the timestamp lands.** Once
frozen, this file is closed: its sha256 goes on
[PREREGISTRATION_ESCROW.md](PREREGISTRATION_ESCROW.md) as a freeze-commit digest, and per the rule
adopted there on 2026-09-04 **no result is ever appended to it** — results will appear in a separate
artifact citing this one by digest.

**Developed with AI assistance (Claude, Anthropic).** The query specifications restated here were
written 2026-07-17; this document is their public form.

---

## 0. Why this file exists, stated without softening

This project already publishes an escrow page carrying digests for sixteen frozen
pre-registrations. **Not one of them converts freeze timing for an outside reader.** The escrow page
says so itself, twice, and this file exists because that admission is worth acting on rather than
merely repeating:

- For the original **ten**, "every one … was first committed between 2026-07-17 and 2026-08-18 …
  For several, the result was already recorded by then, and for one it was already public in this
  repository." The digests were published **after** the measurements ran.
- For the **six** added 2026-09-04, the digest is taken at the freeze commit — better — but that
  commit lives in a private repository, so, as that section states, it "still does not convert
  freeze timing for an outside reader."

**This is intended to be the project's first pre-registration whose timing is checkable rather than
attested** — and the sub-section below names the exact fact that would make it so, together with the
one operator action that has to happen on the freeze day for that fact to exist. The **three**
questions below are published **in full, in the open, before their answers are computed**; the
answers have not been produced. A reader does not have to take our word for the ordering — the
question text is public, and the results, when they exist, will cite this file's digest.

### What a reader can check, and what is still only claimed

**Checkable, without trusting us:**

- **A timing fact.** On the freeze day the raw URL of this file is submitted to an **independent
  public web archive**, and the resulting snapshot URL and its capture timestamp are recorded in
  this file's escrow row. A reader can fetch that snapshot and read a capture time set by a **third
  party**. **This is the only timing statement in this file that a reader can check without
  trusting us, and until that snapshot exists the claim above is a commitment rather than a fact.**
  A git commit date is settable by its author on a **public** repository exactly as on a private
  one; a third-party capture time is not.
- That this text existed publicly at this commit; that its digest matches the escrow row; that any
  later change to it is a hash mismatch rather than an invisible edit.
- That every observable, threshold and command below was fixed before any result citing them was
  published.
- Every claim in §3 and §5 about what this repository's own code already determines: each is
  cited to a public file and can be read there.

**Still attested, not checkable:** that no full-scale answer to these three questions existed
privately before this file was published. The evidence for that is a private git history — the
question text is unchanged since 2026-07-17, the structures the questions read were built later
(dates in §3), and no full-scale value of any of the three escrowed observables is recorded (tail
cells of V4's curve are, and §4 reclassifies them as pre-known checks) — but an
outside reader cannot audit a private repository. **We state the claim and its limit rather than
dressing the limit up.** Two further exposures we cannot close are in §5.

---

## 1. THE n=9 CORRECTNESS GATES DO NOT SPOIL THIS PRE-REGISTRATION

**Read this before §4, because it decides how the public test fixtures should be read.**

This repository ships a full reduced-scale test corpus — `scripts/tr12_expected/n9/`,
`scripts/tr12_repro.sh`, `solve.py --atlas-selftest`, and the `--kc-*-selftest` family — which
exercises the machinery below at **n = 9**, exhaustively, over a 26,112-walk universe.

**That corpus is not a measurement of the object under study, and it cannot spoil a class-A row.**
The n=9 universe contains **no image of King Wen**: King Wen is an n=31 / 64-hexagram object, and
the n=9 world has no such member. The published viz documentation states the same thing for the
shells figure — *"The n=9 world has no King Wen, so the figure is full-31 only; the n=9 gate covers
the machinery."*

The n=9 corpus is a set of **shown-able-to-fail gates on the instrument**: break a column, observe
FAIL, restore, observe PASS. It answers "does this code compute what it says" and never "what is
King Wen's value". **A reader must not have to infer this**, so it is stated here once, plainly, and
it applies to all three rows below without exception.

The same holds for the fault injectors (`--atlas-fault v1-drop-pair`, `v2-class-swap`,
`xa-drop-branch`): they exist to demonstrate that a gate can fail. Their presence is evidence the
gates are real, not evidence the answers are known.

---

## 2. Definitions — everything needed to read the three questions

All of the following is already public in this repository; nothing here is new.

| symbol | meaning |
|---|---|
| **SUPERSPACE** (`SUPER`) | the set of hexagram orderings satisfying **C1 ∧ C2 ∧ C4 ∧ C5** — every constraint except C3. Defined in `solve.c`, `solve.py`, `verify.py`, `viz/README.md`. |
| **N** | `\|SUPER\| = 1097051278789181790036112071176579186688` (≈ 1.097 × 10³⁹). In `verify.c`, `solve.py`, `verify.py`, `reports/FULL31_EXACT_AGGREGATES.md`. |
| **N/24** | `45710469949549241251504669632357466112` — the orbit anchor. **`N` and every per-layer flow are divisible by 24** (Lean-kernel
`twenty_four_dvd_*`, which is about the solution count). ⚠ **NOT "every published count" — this cell
said so until 2026-09-06 (QSET-3 finding 5), and the XA-a row below refutes it in its own text:**
per-branch counts are reported-not-gated, and the committed n=9 fixture shows residues 16, 8 and 0. |
| **C15** | the subset of SUPER additionally satisfying C3. |
| **C3, and G** | `C3(seq) = 16 + 8·G` universally over C1-valid orderings, by the machine-checked `c3_slot_decomposition` (`lean/C3Decomposition.lean`). `sat.py` refuses any ceiling below the **structural minimum C3 = 112** (i.e. `G ≥ 12`): the refusal is enforced in `sat.py::build()`, which computes `sbudget = (bound − 2·|self-complement pairs|) // 8` and raises `SystemExit` when `sbudget < |complement couples|`. |
| **776 / 387** | King Wen's own C3 value (the ceiling) and the walk-functional C3 gate used by `--kc-c3-max`. **Both are King-Wen-defined**; see the circularity note in §5. |
| **f / g / t ladders** | the three compiled 32-layer structures. `f(s)` = number of valid prefixes reaching state `s`; `g(s)` = number of completions from `s`; `t(s) = 1 + Σ_c t(s∘c)` with `t(final)=1` = the pruned search-tree size. Format documented in `documentation/GT_LADDER_FORMAT.md`. |
| **the scan atlas** | the JSON emitted by `solve --kc-scan F G ATLAS.json` — per-layer `flow`, `by_class{d1,d2,d3,d4,d6}`, `marginal_raw`, `marginal_quotient`, and `branch_atlas[]`. Consumed by `python3 solve.py --atlas-queries`. **`solve.py::atlas_queries()` calls `atlas_load()` unconditionally**, before any `--atlas-select` value is examined, and `atlas_load()` raises unless the JSON carries `n`, `N_total`, `layers`, `branch_atlas` with `len(layers) == n`. **Every command below that invokes `--atlas-queries` therefore needs this atlas**, whatever selector it passes. |
| **the King Wen walk string** | the literal `KW` is accepted by only some subcommands (`--kc-profile` takes it; `--kc-o3-rank` does not). Every command below that needs King Wen's walk passes the 62-value string produced by `python3 -c 'import solve;print(",".join(map(str,solve._r7_kw()[2:])))'` (the C4-anchored pair `63,0` is slot 0 and not part of the walk). |

Shell placeholders used by every command below — set them to your own paths and values:

```bash
SOLVE=./solve                # built from this repository; record the binary's GIT_HASH
FDIR=<f-ladder root>         # Stage F, 32 layers
GDIR=<g-ladder root>         # Stage G, 32 layers
TDIR=<t-ladder root>         # Stage T, 32 layers
OUT=<artifact root>          # mkdir -p "$OUT" "$OUT/scan"
MB=<--kc-cache-mb value>     # out-of-core cache size in MiB, sized to the host
```

Verdicts are `KEY=value` lines checked with `grep -qx`, never by output shape.

---

## 3. What is escrowed here, and what is deliberately not

The query program has **31 counted question rows**. *(The public inventory,
`documentation/QUERY_INVENTORY.md`, tabulates **35**; the four not counted here are **Q1c**, which is
descoped to a column of Q4a/c, and **LS-audit**, **LS-cite** and **EW-gov**, which are review
protocol and citation rows rather than questions. Stated because a reader with the public file counts
35 in thirty seconds, and an unexplained discrepancy in the denominator would undermine the
classification that rests on it.)* Each was classified from git history — not from
recollection — against two requirements:

1. **pre-hoc** — the question's text predates the first existence of the full-31 compiled structure
   it interrogates; and
2. **unrun** — no full-scale value of its headline statistic is recorded anywhere.

The split is **A = 12 pre-hoc-and-unrun, B = 4 post-hoc-but-unrun, C = 15 already answered**.

**Only class A can be pre-registered, and only three of the twelve are freezable as written.**
*(Twelve, not thirteen: Q4b moved from class A to class C on 2026-09-05 when it was found to be
already answered — so the split is A = 12, B = 4, C = 15, and 12 − 3 = **nine** held out. The counts
read 13/4/14 until 2026-09-06, QSET-3 finding 8 — and the sentence above still read 13/4/14
after this note was added, until QSET-4 finding 2 caught the half-applied fix.)*
Those three are escrowed by this file. The other **nine** are class A but are not freezable, for two
different reasons: **six** because their text is not falsifiable as it stands, and **three** because
their text escrows an observable **this repository already determines**. A pre-registration that
cannot fail is not one; neither is one whose answer we already hold.

### Held out because the text is not falsifiable

| held out | why it is not freezable |
|---|---|
| Q5, and one literature-exactness row | the observable is *"shortlist proposed (operator picks)"* — an observable selected later cannot be frozen now |
| XA-c/d (the exhaustion wall and its verdict) | the verdict's numeric inputs (nodes/sec, $/hour, budget) are unpinned, and the t-unit → node-counter mapping is unclaimed; the shipped consumer **refuses to invent them** (`PENDING:xa-throughput-anchors`) |
| Q2c, Q2d | the pre-registered abort rule names a quantity the tooling cannot measure, so the alternative outcome cannot be executed |
| Q2 | one of its three legs is determined by a labelling theorem rather than open, and the row does not yet say so |

### Held out because this repository already determines the answer

These three were drafted for this freeze and **removed from it on 2026-09-05, before publication**, after a
fresh-eyes review of the draft against the committed public tree. Each escrows a King Wen observable
that is a literal constant or a one-line computation in this project's own public code, and for two
of the three **this repository already publishes that fact**. The citations below are public and can
be read by anyone:

| held out | what the repository already determines |
|---|---|
| **V1** — the exact positional-marginal field, *with King Wen's placements overlaid as marks* | the marks are `kw_pair = [k + 1 for k in range(31)]` — a **literal constant** in `solve.py::_atlas_kw_overlay`, no ladder, no atlas, no compute. `viz/viz_kc_field.md` already publishes the point under its own heading: *"They lie on the main diagonal, and that is a labelling artifact, not a finding: the global pair index is *defined* by King Wen's own pairing order, so King Wen places pair `k+1` at slot `k+2` for every k."* The **population field** is genuinely unknown; the **overlay** is not, and the row as drafted escrowed both without distinguishing them. |
| **V2** — the exact layer-mass river, *with King Wen's path drawn as a line* | the line is `kw_d = [popcount(K[2k+1] ^ K[2k+2]) for k in range(31)]` over `binary_hexagrams` in the same function — a one-line function of a **public** sequence. `viz/viz_kc_river.md` already publishes one of its values: *"exactly one d = 6 boundary exists in every valid ordering … King Wen puts it at k = 18."* The **river** is genuinely unknown; the **line** is not. |
| **Q3** — King Wen's exact 31-step profile | the first quantity the frozen question demanded to "report, exactly" was *the pair chosen at step `i`*. That is **`i`**, forced by the labelling, and this repository encodes it as an **exact test**: `solve.py::atlas_q3_trace_is_king_wen` checks `int(srow["pair"]) != i` and reports *"step %d places pair %s; King Wen places pair %d"*. Separately, the row's frozen command could not have emitted another of its own named columns (`g` of each alternative), which requires `--kc-profile … --kc-alts`. |

**These three are not withdrawn as questions.** The population field, the river and King Wen's `g`
descent are exactly the kind of thing escrow exists for, and the `g` descent survives in this file as
**V4**. They are withdrawn from *this* freeze because a pre-registration must escrow something we do
not already hold, and each as drafted escrowed a King Wen observable a reader can compute from this
repository in one line. Reformulations may be escrowable; **the arguments for and against each are
kept, and any adopted reformulation goes in a dated successor file, not in this one.**

Fixes exist for several of the nine. **They are not folded in here.** If adopted they will be
escrowed in a *dated successor file*, so that this file's three rows remain exactly what was published
on 2026-09-06.

**Class B and class C are not pre-registered by this document and never will be.** The four class-B
rows are publishable as *exploratory*. The **fifteen** class-C rows already have full-scale answers
(fifteen, not fourteen: Q4b joined them on 2026-09-05 — see its row in §4);
escrow claims nothing whatsoever about them, and their values, where published, appear as results
elsewhere and carry no timing claim.

### The structure-existence dates that make "pre-hoc" ATTESTED — and what a reader can and cannot check

⚠ **This heading said "checkable" until 2026-09-06 (QSET-3 finding 3), and that overclaimed.** Of the
three question phrasings, only one is traceable to 2026-07-17 in **public** git; the other two first
appear publicly on 2026-08-22 and 2026-09-05. All three do appear in the **private** history on
2026-07-17, which is what §0 says and is the honest claim — but §0 calls that *attested* while this
heading called it *checkable*, and the two are not the same word. **The only timing fact in this file
a reader can check without trusting us is the third-party capture**, and it is named as such in §0.

| structure | first existed |
|---|---|
| the question text of all three rows below | **2026-07-17** |
| Stage F — the f-ladder at n=31 | 2026-07-29 |
| Stage G — the g-ladder at n=31 | built 2026-08-18; verified 2026-08-20 |
| Stage T — the t-ladder at n=31 | built 2026-09-03; **gate passed 2026-09-04** (`--kc-t-check`: 32 identities checked, 0 skipped, `TLADDER_RESULT=PASS`, the root total matching an independent derivation from preserved Stage F layer masses). ⚠ *This cell read "its `--kc-t-check` gate is **still unpassed**" in the 2026-09-05 draft — the gate had passed the day before — and then "gate passed 2026-09-05" until 2026-09-06; corrected rather than carried, because a table of attested dates that are wrong attests nothing* |
| **the scan atlas at n=31** | **never built.** The one attempt (2026-08-20) was **deliberately stopped early, to free its VM for another job** — it was not a crash, an eviction or a failure. `--kc-scan` writes its atlas once, at the end, so that attempt produced nothing. |

### What actually has to run, per row — stated exactly

Three escrowed rows are **not** three independent measurements, and this file will not let a reader
count them as such. There are **two independent computations behind three artifacts** (it was three behind four until Q4b was removed on 2026-09-05 — §4):

🔴 **"Needs the atlas file" and "is expensive" are different claims, and this table separates them
deliberately.** Every row below needs the atlas *file* — for V4 because `atlas_load()` is the reader
gate's first statement, for XA-a and XA-b because `--kc-scan` is the only thing that currently
*writes* the file their values are emitted into. **None of them needs the atlas's expensive content.**
The escrowed observables are point lookups: ≤62 for XA-a, ≤62 for XA-b, 62 for V4.

**This matters for what a reader should expect, and for what this project must not do.** The
`--kc-scan` wall is **days, not hours** (its read volume was restated upward by ~1.5 orders of
magnitude on 2026-09-05, and the honest wall has never been measured), and the n=31 atlas has
**never been built**. A reader could conclude these rows are therefore unanswerable in practice.
They are not. But the cheap routes are **deliberately not taken before the freeze** — see §5(ii).
Answering an escrowed question before its timestamp exists is precisely the defect that removed Q4b
from this set.

| row | needs the atlas **file**? | what the escrowed observable itself costs | needs a ladder? | independent computation |
|---|---|---|---|---|
| **V4** | **yes, and only as a code path** — its reader-side gate leg runs `--atlas-queries`, and `atlas_queries()`'s **first statement** is `atlas_load(atlas_path)`, executed before any `--atlas-select` value is examined | the `g` curve is **31 f-ladder and 31 g-ladder point lookups** along King Wen's own path. Its frozen command reaches them through `--kc-o3-rank … --kc-trace`, a heavier instrument that maintains a frontier; `solve --kc-profile FDIR GDIR KW` computes the same curve from *point lookups alone* (`solve.c`: "no frontier, no `kc_o3_mass`, no `kc_repr_dp`") | f and g | King Wen's f·g descent along his own path |
| **XA-a** | **yes, as the emission path** — `solutions(b)` is a `branch_atlas[]` field and `--kc-scan` writes its atlas only at the end of the whole run | **≤ 62 point lookups into g layer 1** — `kc_h_scan_tail` makes one `kc_glookup(gkc, 1, …)` per valid first placement, i.e. at most one per (pair, orientation) | f and g | the `--kc-scan` atlas — **but see §5(ii): that is the EMISSION path, not the only route.** A cheap exact route to this observable needs a **~754-byte read of one g-ladder layer**, not the full scan, and is authorised and open on the backlog. It is deliberately ordered **after** this file's third-party snapshot. ⚠ *Clarified 2026-09-06: this cell named only the scan, and a reader could reasonably conclude the days-long scan was the sole way to answer this row. It is not.* |
| **XA-b** | **yes, as the emission path**, and additionally requires `--kc-t-check` to pass | **≤ 62 point lookups into t layer 1** — one `kc_flookup(tkc, 1, …)` per branch in the same tail. Its `t(root) == Σ_k fmass[k]` cross-gate reads the **f** ladder's per-layer orbit masses and makes **no g probe at all** | f, g and t | the same `--kc-scan` atlas, read a second way — **and the same §5(ii) caveat applies**: the escrowed observable is ≤62 point lookups into t layer 1, and `--kc-t-check`'s cross-gate has **already passed** (`IDENTITIES_CHECKED=32`, `TLADDER_RESULT=PASS`, 0 skipped, 2026-09-05). The scan is this row's emission path, not its cost. ⚠ *Clarified 2026-09-06, same reason as XA-a.* |

**All three rows need the atlas file** — Q4b, the one row that did not, is removed (§4). **None of them needs the expensive part of the pass that
produces it, and this file states the distinction rather than letting a reader infer a cost that is
not there.** `--kc-scan`'s layer loop is dominated by a join that issues `2·(31−k)` g-ladder point
lookups *per f-ladder entry* at layer `k` (`kc_h_scan_layers`, `solve.c`) — at n=31 that is the
whole cost of the run. But that join produces `flow`, `by_class`, `marginal_raw` and
`marginal_quotient`, and **no row frozen in this file reads any of those four fields *as an escrowed
observable*.** ⚠ **Narrowed 2026-09-06 (QSET-3 finding 6): `flow` IS read** — `solve.py`'s
`atlas_emit_xa`, reached by the `xa` selector, checks every layer's `flow` for divisibility by 24, and
§4's XA-a row already says so. The claim is about what the rows *escrow*, not about what their gates
touch, and it now says that. XA-a and
XA-b are served by `kc_h_scan_tail`, which runs *after* the layer loop and costs the ≤ 62 + ≤ 62
lookups tabulated above; V4 is served by King Wen's own descent. As `--kc-scan` is coded today an
atlas cannot be emitted without running the layer loop, so the dependency is real — but it is an
**emission-path** dependency, not a mathematical one, and a tail-only emitter would discharge it.
Q4b needs no atlas at all.

That the atlas has never been built is still the strongest form of pre-hoc available here, and it is
still a real risk: see §5. **Both over-readings are wrong and this table exists to block both.** A
previous draft of this file said V4 "needs no scan and no additional compute"; that was false as its
command is written, and is corrected here rather than carried. The opposite over-reading — that these
three rows are blocked behind a full-scale pass — is equally false, and is corrected here for the
same reason.

---

## 4. THE THREE PRE-REGISTERED QUESTIONS

*(Four until 2026-09-05. Q4b was removed from the draft on 2026-09-05 — its record stands first below,
kept rather than deleted because the near-miss is worth more than a tidy file.)*

Each row gives the **question as frozen**, its **pre-registered decision rule or gates**, the
**exact command**, and the **class-A justification**.

**A general rule binds all three, and it is part of the pre-registration:** all three (V4,
XA-a, XA-b) are **descriptive** — they fix an observable and its arithmetic gates, and they
pre-register **no hypothesis test**. *(A fourth row, Q4b, asked for an exact extremal value and its
witness — a determinate quantity rather than a test. It was removed from the draft on 2026-09-05; its record is
below.)* **No claim that any value is "rare",
"extreme", "typical" or "distinguished" is pre-registered by this file**, and no row's heading or
question text uses those words. Any such test requires its own dated pre-registration with its own
family size and its own escrow row, and none is granted here. This is deliberate: the failure mode
this project has named for itself is that a question invented while looking at compiled structure
rediscovers King Wen's own features and reports them as rare. Fixing the observable without also
granting a licence to test it is the narrow, honest thing to publish.

---

### Q4b — REMOVED FROM THIS FREEZE 2026-09-05: the repository already answers it

**This row was drafted as class A ("pre-hoc, unrun") and it is not.** `min{C3(w) : w ∈ SUPER}` is
**112**, and this project published a verified witness achieving it on **2026-07-24** — six weeks
before this file was written — at `reports/certificates/c3_positional_witnesses.txt`, under a commit
titled *"C3 positional SAT/DRAT certs (TR-12 Q4b)"*, which names the row it answers. The lower bound
`G ≥ 12` is structural, the witness achieves it, and a structural bound met by an exhibited witness
closes the bracket at its floor. `documentation/CLAIMS_DECIDED.md` and
`reports/certificates/README.md` state the result independently.

**It therefore falls to this file's own §3 rule** — *held out because this repository already
determines the answer* — and it falls to it harder than V1, V2 or Q3 did. Those three were forced by
a labelling; this one has a published certificate.

**Recorded rather than deleted, because the near-miss is the point.** Freezing this row would have
put a claim to have *not yet answered* something we answered in three places under a third-party
timestamp, refutable by one search and unretractable afterwards. It was caught by a Fable
adjudication of the QSET external review — a review explicitly pointed at this defect class, which
**cleared Q4b**. Two earlier internal passes missed it too. The public sites that posed it as open are
corrected at `documentation/CORRECTIONS.md`.

**What is genuinely still open here is the SAT machinery, not the question:** the bisection driver
does not exist and `kissat`/`drat-trim` are absent. That is a tooling gap and it escrows nothing.

---

### V4 — King Wen's neighbourhood shells, as a figure

**Question (frozen).** `g(KW-prefix_k)` versus `k` on a log scale — the number of completions
remaining after each of King Wen's 31 choices.

**⚠ Disclosed narrowing, dated 2026-09-05, with its reason.** The 2026-07-17 text offers,
*optionally*, a band of the min/max `g` over the admissible alternatives at each step. **That band
is not escrowed by this file.** The command below routes through `--kc-o3-rank … --kc-trace`, whose
per-step `alts` column is a **count** of admissible oriented successors, not their `g` values; the
band's columns (`g_alt_min`, `g_alt_max`) are emitted by a different subcommand,
`--kc-profile … --kc-tsv`, as this repository's own consumer comment says. Freezing a named
deliverable the frozen command cannot produce would be worse than narrowing the row and dating the
narrowing. **Only the `g` curve is escrowed.**

**What is already determined here, and is therefore not escrowed.** King Wen's trace also carries a
`pair` column, and that column is **`i` at step `i` by the labelling** — the global pair index is
defined by King Wen's own pairing order — which this repository encodes as an exact test
(`solve.py::atlas_q3_trace_is_king_wen`). **V4 plots `g`, not `pair`.** The `pair` column is used
here only as a **gate** (`TR12_Q3_KW`, below), never reported as a finding. The `g` values
themselves are genuinely unknown **except at the shallow tail, where three of them are already
published — disclosed here 2026-09-06 rather than left for a reader to grep (QSET-3 finding 1).**
`documentation/SYMMETRY_SEARCH.md` publishes, for King Wen's own prefixes,
**`g(s_22) = 690,176`**, **`g(s_24) = 5,624`** and **`g(s_26) = 52`** (as "C1+C2+C4+C5 leaves" at the
9-, 7- and 5-free rungs), and any tail cell with nine or fewer free pairs (k ≥ 22) is a sub-minute
brute force from the committed `verify.py` — re-executed during review in 28 s. **The 10-free cell
(k = 21) is NOT sub-minute:** it took 475 s on a 2-core host when it was brute-forced during the
QSET-4 adjudication on 2026-09-06, and this sentence read "~10 or fewer … sub-minute" until then.
That cell is therefore also a pre-known check; its value is held in the private review record and is
not published. **Those three cells are therefore
PRE-KNOWN CHECKS on the ladder descent, not escrowed results**, exactly as `t(root)` is for XA-b: a
descent that disagrees with them is wrong. **What is escrowed is the HEAD of the curve, k ≤ 20** — the cells where
brute force from `verify.py` is no longer a matter of minutes and only the ladders can answer. No
full-31 f·g descent of any walk has ever been run.

**Not an independent question, and not scan-free — but the dependency is an `open()`, not a
computation.** V4 is King Wen's f·g descent rendered as a figure. It is escrowed as its own row
because it is a separately published artifact with its own gates, **not** because it is an
independent measurement — see the per-row table in §3. And as its command is written it **does**
depend on the n=31 scan atlas, because its reader-side gate leg runs `python3 solve.py
--atlas-queries`, whose `atlas_queries()` calls `atlas_load()` as its first statement, before any
`--atlas-select` value is examined. **That is a file-open, not a quantity.** No number in the `g`
curve escrowed above is computed from the atlas: the curve is 31 f-ladder and 31 g-ladder point
lookups along King Wen's own path, and `solve --kc-profile FDIR GDIR KW` computes it with no atlas in
sight. The dependency is stated because it is real in the command as frozen; it is qualified here so
that it is not mistaken for a full-scale compute requirement.

**Pre-registered gates (all must hold; any failure voids the run and is reported as a failure, not
repaired).**

| gate | how it is checked |
|---|---|
| the trace is **King Wen's own walk**, row for row | `TR12_Q3_KW`, `solve.py::atlas_q3_trace_is_king_wen` — an exact match of `(step, pair, entry, exit)` against `binary_hexagrams` at all 31 free placements. This gate is named explicitly because the reader-side identities below are **walk-generic**: they hold for every valid walk and cannot tell King Wen's trace from any other. |
| `Shell_0 = SUPER` (`g(s_0) = N`) and `Shell_31 = {King Wen}` (`g(s_31) = 1`) | `atlas_q3_reader_check`, and the engine's `#o3-trace-summary` line independently |
| `g` **non-increasing** in `k` — *not* strictly decreasing | `atlas_q3_reader_check`, whose failure predicate is `int(r["g"]) > prev_g`, i.e. it flags **growth**. See the note below: a strict-decrease gate would fail on correct data. |
| `g_parent[i] = g[i−1]` | `atlas_q3_reader_check` |
| `Π_{i=1..31} p_i = 1/N` **exactly** | recomputed **reader-side** in big integers from the emitted TSV, not read from the engine's own summary line. Separate verdict `TR12_Q3_READER`. |
| the **PNG** regenerates byte-stably from the committed TSV, and the rendering reads **only** that TSV | `viz/report_figures.py` |
| ⚠ **SVG byte-stability is NOT pre-registered, and this row said it was until 2026-09-06 (QSET-3 finding 2).** Measured with matplotlib 3.11 at the defaults `report_figures.py` uses: two renders of an identical figure give **identical PNG bytes and DIFFERING SVG bytes** — an embedded `<dc:date>` and randomised element ids (`m95ace04ce0` vs `maf1f00b479`), because `save()` sets neither `metadata={'Date': None}` nor an `svg.hashsalt`. **Frozen as written, this gate would have voided a correct run**, leaving only a gate violation or an un-pre-registered repair as exits | scoped to PNG |

**⚠ Why the shell gate is non-strict, stated so it cannot be misread as an oversight.** A step whose
placement is **forced** contributes `p_i = 1` and `bits_i = 0`, and the shell does not shrink. Forced
placements are a named structural feature of this problem (the C1 forced-rule family), so a flat step
at full-31 is expected, not exotic. This repository's **own committed fixture is the red test**:
`scripts/tr12_expected/n9/a2_q3_profile.txt` reads `g = 26112, 2368, 456, 160, 32, 8, 4, 4, 1, 1` —
flat from step 6 to 7 and from step 8 to 9 — and `viz/viz_kc_shells.md` states the correction
(2026-09-04): *"their sizes are non-increasing — not strictly decreasing."* **A pre-registered
strict-decrease gate would fail on correct data**, and this file does not pre-register one.

**No hypothesis test is pre-registered.** The `g` curve is descriptive. The engine asserting
`product(p_i)=1/N` in its own summary does **not** discharge that gate — the reader-side
recomputation does, and the two verdicts are emitted separately precisely so the engine cannot
grade its own homework.

**Command.**
```bash
KWW=$(python3 -c 'import solve;print(",".join(map(str,solve._r7_kw()[2:])))')
$SOLVE --kc-o3-rank "$FDIR" "$GDIR" "$KWW" --kc-trace \
       --kc-ooc --kc-cache-mb "$MB" > "$OUT/v4_kw_trace.txt"
python3 solve.py --atlas-queries "$OUT/atlas.json" --atlas-out "$OUT" \
       --atlas-select q3 --atlas-q3-trace "$OUT/v4_kw_trace.txt"
# the consumer writes $OUT/q3_profile_kw.tsv -- a name it claims ONLY when
python3 viz/report_figures.py "$OUT"        # renders the V4 figure; see the note below
# TR12_Q3_KW=PASS -- and viz/report_figures.py renders fig_tr12_kc_shells.{png,svg}
# from that file. No step of this command writes that name by hand.
```
Verdicts: `TR12_Q3`, `TR12_Q3_KW`, `TR12_Q3_READER`. Documented in `viz/viz_kc_shells.md`.

**A note on the token names.** The three verdicts and the emitted filename carry a `Q3` / `q3`
prefix because those are the **shipped** token and file names in `solve.py`, and this file will not
rename shipped tokens to make a document read better. The Q3 *row* is held out of this
pre-registration (§3); the `g` descent it would have contained is escrowed here, as V4.

**Class A.** Specified 2026-07-17, in these words. The g-ladder it reads did not exist until
2026-08-18, and the scan atlas its reader leg loads has never been built. No full-31 `--kc-o3-*` or
`--kc-profile` run over King Wen's path has ever been performed; Stage G's banked verification
prints per-layer cut identities, not King Wen's states.

---

### XA-a — the exact per-branch solution counts

**Question (frozen).** For every top-level branch `b` (the first free placement):
`solutions(b) = Σ_{first choices c ∈ b} g(s_0∘c)` — **exact**, over SUPER.

**Pre-registered gate — this one can fail loudly:**

```
Σ_b solutions(b) == N
```

emitted as `TR12_XA_A=PASS` or `FAIL:sum_b(<value>)!=N(<value>)` — the verdict is **read off the
table the consumer just wrote**, not asserted. `N` and every per-layer flow additionally pass the
24-divisibility integrity check, which is Lean-kernel-backed. ⚠ **Per-branch counts are *reported,
not gated*, and this row said otherwise until 2026-09-05.** It read "Every count additionally
passes" — which pre-registers a check that **correct data fails**: the order-24 group permutes walks
*between* branches, so an individual `solutions(b)` need not be divisible by 24. This repository's
own n=9 fixture is the counterexample — `scripts/tr12_expected/n9/c_xa_mod24.txt` records
`branch0_solutions 2368 16 (reported, not gated)`, and 2368 ≡ 16 (mod 24). Frozen as first written,
the row would have failed on a correct atlas.

**No hypothesis test is pre-registered.** Which branch is largest or smallest is a description, not
a claim; "a minimum-mass corridor is expected in any large DP and distinguishes nothing" is already
this project's published position and is not weakened or strengthened here.

**Command.**
```bash
$SOLVE --kc-scan "$FDIR" "$GDIR" "$OUT/atlas.json" --kc-tdir "$TDIR" \
       --kc-raw --kc-ooc --kc-cache-mb "$MB"
python3 solve.py --atlas-queries "$OUT/atlas.json" --atlas-out "$OUT" --atlas-select xa
```
Verdict: `TR12_XA_A`. Artifacts: `xa_branches.tsv`, `xa_verdict.md`.

**Class A.** Specified 2026-07-17, `solutions(b)` with the `Σ_b = N` gate, in those terms. The scan
atlas at n=31 has never been built.

---

### XA-b — the exact per-branch prefix cost in t-units

**Question (frozen).** For every top-level branch `b`, `prefixes(b)` — the number of valid prefixes
extending `b`, i.e. the pruned DFS search-tree size for that branch — in **t-units**, read from the
t-ladder (`t(s) = 1 + Σ_c t(s∘c)`, `t(final) = 1`).

🔴 **`t(root)` IS NOT ESCROWED BY THIS ROW, AND THIS ROW LISTED IT AS A DELIVERABLE UNTIL
2026-09-05.** The root total is **already computed**: the Stage T build produced it on 2026-09-03,
and a 32-identity check re-confirmed it on 2026-09-05 (`IDENTITIES_CHECKED=32`,
`IDENTITIES_SKIPPED=0`, `TLADDER_RESULT=PASS`), agreeing with a value the atlas-scoping pass had
independently derived by summing preserved Stage F layer masses — **two derivations, one number**.
Escrowing it as an unknown would repeat, inside this file, the defect that removed Q4b from it.

**What this changes is the row's strength, and it changes it upward.** `t(root)` is reclassified from
*result* to **pre-known check**: the escrowed object is the **per-branch decomposition**, `prefixes(b)`
over the ~62 top-level branches, which has never been computed, and the gate below tests it against a
total fixed **before** the decomposition is produced. A pre-known aggregate constraining an unknown
decomposition is a strictly stronger gate than one where both are derived in the same pass.

**The value is deliberately not quoted here.** ⚠ **This sentence said its "only" reproduction path
was a multi-week t-ladder build. That is false, corrected 2026-09-06 (QSET-3 finding 4):** `t(root)`
is `1 + Σ_k mass_k` over the per-layer masses already published in
`reports/FULL31_EXACT_AGGREGATES.md`, so it is **one line of arithmetic over a public table** — the
identity `solve.c` itself implements. The value is still not quoted, but the reason is now the honest
one: quoting it adds nothing a reader cannot compute, and the row's claim rests on the per-branch
decomposition rather than on the total. A rebuild of the ladder, and this project does not publish a figure ahead of its reproduction command. The *epistemic*
fact — that the total is known and fixed — is what a reader needs, and it is stated.

**Pre-registered gates.**

| gate | how it is checked |
|---|---|
| `1 + Σ_b prefixes_t_units(b) == t(root)` | `TR12_XA_B=PASS`, else `FAIL:1+sum_t(<value>)!=t_root(<value>)`; read off the emitted table |
| `t_source` reads **`t-ladder`** | if the t-ladder is absent the row reports `PENDING:--kc-t-build`, never a `PASS` |
| t-ladder versus direct recursion at small n | `--kc-t-selftest`, `--kc-scan-selftest` |

**Precondition, disclosed — and DISCHARGED 2026-09-05.** The t-ladder finished building on
2026-09-03. This row said its **`--kc-t-check` gate has not yet passed** and that the row does not run
before it does. ⚠ **That gate PASSED on 2026-09-04 at 06:48:28 UTC** — state-file epoch `1788504508`,
first committed in `28d72e73` at 09-04T09:26Z, in the **private** history — attested, not
checkable, as §3's heading says. *(This document said **2026-09-05** at two sites until
2026-09-06. The error was mine and it is the exact kind this table exists to prevent: I took the date
from a log file's modification time — when I copied it — rather than from the run's own record. A
wrong date in the table whose whole purpose is that its attested dates be right.)* The
sentence was stale by the time anyone read it: 32 layer identities checked, 0 skipped,
`TLADDER_RESULT=PASS`, with the root total matching an independent derivation. The precondition is
therefore **met**, not outstanding — recorded this way rather than silently rewritten, because a
precondition that quietly changes from *unmet* to *met* between drafting and freezing is exactly the
kind of movement a frozen document must show rather than absorb. **A t-unit is not a
production DFS node count**; the mapping between the two is a separate, unclaimed piece of work, and
**no cost, wall-clock or feasibility statement is pre-registered by this row.** That is exactly why
the exhaustion-wall verdict is held out of this file (§3).

**No hypothesis test is pre-registered.**

**Command.** The same scan as XA-a — **with `--kc-tdir "$TDIR"` supplied** — then the `xa` selector
as in XA-a.

**Class A — the strongest row in the set.** Specified 2026-07-17; it reads a structure that is
pre-hoc with respect to **F, G and T simultaneously**. The t-ladder it depends on did not exist
until **2026-09-03**, forty-eight days after the question was written, and the scan atlas that joins
them has never been built.

---

## 5. Disclosures — what this pre-registration does not close

**1. Escrow does not make an answer correct.** It fixes the question. A frozen wrong question stays
wrong.

**2. Two exposures our own method cannot close.**
 - **A large enumeration record predates the question text.** A ~560T-node DFS campaign closed out
   around 2026-07-01, sixteen days before these questions were written, and it is a compiled record
   of constraint-satisfying orderings. No row here queries it, and its outputs are partial prefix
   counts rather than the exact f/g/t quantities asked for above — but the author of the 07-17 text
   had that record available. **This is the residue that stays attested.** Nothing in a git history
   can close it.
 - **Reduced-n ladders existed from 2026-07-14**, three days before the question text. What those
   ladders compile is **not a prefix of the 31-pair problem**: a reduced-*n* universe is a **union
   of C5 orbit classes over a sub-alphabet of pairs**, chosen from a fixed table in `solve.c`
   (`f1c5_unions[]`: `n = 9` is `3.0,3.1,3.2@0`, `n = 13` is `3.0,4.0,6.2@0`, and so on), and each
   derives its own C4 start-exit anchor. King Wen is a full-31 object, and the shipped code says in
   two places that no reduced-*n* universe carries a King Wen walk to compare against
   (`solve.py::_atlas_kw_overlay` fills the overlay columns with `−1` at `n < 31`;
   `solve.py::atlas_q3_name` returns `SKIP` with the reason *"the reduced n=… universe carries no
   King Wen walk to compare against"*). **So the residual exposure from 07-14 is the machinery, not
   King Wen's values:** whoever wrote the 07-17 text had a working reduced-scale instrument and
   could have known what the *instrument* does, but not what it says about King Wen. A search of the
   private history for any King-Wen-specific measurement from this machinery before 2026-07-17
   returns only planning and validation commits — which is the strongest negative a git history can
   give, and it is **not** proof of absence. **This correction is itself not a proof either:** it is
   what the table and those code sites say, not an exhaustive demonstration that no reduced-*n*
   universe could coincide with a King Wen prefix.

**3. The circularity note, carried once and plainly.** C3's ceiling of 776 **is King Wen's own
value**, extracted from the sequence rather than derived independently; the 387 walk-functional gate
is defined from it. Q4b's bracket and any C3-conditioned statement inherit that circularity. This is
already stated in the published specification and is repeated here so that no row below is read as
if its threshold were structurally motivated.

**4. All three rows read a file that has never been produced — which is not the same as
needing the run that would produce it.** V4, XA-a and XA-b all reach the n=31 scan atlas: XA-a and
XA-b as their data source, V4 through its reader-side gate leg, which opens the atlas
unconditionally. The single attempt at that run was **deliberately stopped early, to free its VM for
another job**, and it produced nothing, because `--kc-scan` writes its atlas only at the end.
**This pre-registration does not promise that the scan will be run, or that it will finish.** If it
never finishes, the honest report is that these three rows are unanswered — a legitimate outcome,
pre-registered as one. Only Q4b is independent of it, and Q4b has a toolchain problem of its own.
⚠ **What this paragraph does not say, and must not be read as saying:** it does not say the three
rows need the *expensive* part of that run. Per §3, the observables they escrow are ~10² ladder point
lookups; the coupling is to the atlas **file**, which today is emitted only at the end of the full
layer loop. A reader estimating the cost of answering this pre-registration from this paragraph would
get the wrong answer, and §3 is the paragraph to use instead.

**5. Where the answers are genuinely unknown, and where they are partly constrained.**
 - **V4** — the **head** of the `g` curve (k ≤ 20) is genuinely unknown: no full-31 f·g descent of
   King Wen's path, or of any walk, has ever been run. **Its tail is not unknown**, and this bullet
   said "the `g` curve is genuinely unknown" without that qualifier until 2026-09-06 (QSET-4 finding
   1): `g(s_22)`, `g(s_24)` and `g(s_26)` are published in `documentation/SYMMETRY_SEARCH.md`, and
   every cell with k ≥ 21 is a minutes-or-less brute force from committed `verify.py` — pre-known
   checks on the descent, not escrowed results, as the row states. Its `pair` column is **not**
   unknown either (it is `i` by the labelling) and is used only as a gate, never reported — see the
   row.
 - **XA-a, XA-b** — genuinely unknown; constrained only by the gate identities above (each sums to
   `N`, or to `t(root)`), which pin the totals without pinning any cell.
   ⚠ **Two disclosures a reader can find for themselves, added 2026-09-06 rather than left to be
   found.** (i) A **56-branch Monte-Carlo cross-sum was run** and is described in public
   `reports/TR4_SIZE_OF_THE_SPACE.md` — *"56 branch sum 1.33e38 vs whole 1.32e38, <1%"* — so a
   sampled, order-of-magnitude version of XA-a's shape exists in the published record. **Its
   per-branch values were never archived** and the report itself records them as untraced, so no
   exact `solutions(b)` is determined by it; but a reader is entitled to know a sampled cross-sum
   preceded this row rather than discovering it unaided. (ii) **A cheap exact route to XA-a's
   observable is authorised and open** in this project's own backlog: it needs a ~754-byte read of
   one g-ladder layer, not the full scan. **It is therefore ordered AFTER this file's third-party
   snapshot, and that ordering is recorded on the backlog row itself** — because running it first
   would convert this row into exactly the class of defect that removed Q4b, in a document that by
   then carries a timestamp and cannot be amended. Both points were raised by an external review's
   adjudication, not found by us unprompted.
 - **Q4b** — 🔴 **REMOVED FROM THIS DRAFT on 2026-09-05: nothing about it is open.** This bullet
   read *"What remains open is the exact minimum and its witness"* until 2026-09-05. **It is not
   open.** The structural lower bound `C3 = 112` (`G ≥ 12`) is **met by a published witness**
   (`reports/certificates/c3_positional_witnesses.txt`, `G=12 C3=112`, committed 2026-07-24), so the
   minimum is 112 exactly, with its witness, and the bracket closes at its floor. The earlier
   phrasing described `C3 = 392` as the upper bound while quoting 112 as the lower one and did not
   notice that a *witness at the floor* leaves nothing between them. **The gap was not in the
   evidence — every number needed was in the sentence.** See the row in §4.

**6. Three rows were removed from this draft on 2026-09-05**, because each escrowed a King
Wen observable this repository already determines. §3 names all three, what determines each, and the
public file that already publishes the point for two of them. They are recorded here rather than
quietly dropped, because a reader is entitled to know that the set was seven, then four, and is three, and why.

**7. No result may ever be appended to this file.** Per the rule adopted on the escrow page,
2026-09-04, the results will live in a separate artifact citing this file's digest. If this file
ever changes, its digest will no longer match, and that mismatch is the intended alarm.

