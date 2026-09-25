# TR-12 — The Query Program: Distinguished Elements of the Solution Space
*Technical report — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. One caveat is structural, and it frames all the rest: the same
author wrote the claims, the software that checks them, and this report that grades the check.
Verification here is independent in mechanism, never in authorship; no independent party has yet
audited or reproduced any of it (METHODS.md §"Authorship independence").*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

[TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) counted the space this project had only ever
sampled: **1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097×10³⁹** orderings satisfy
C1∩C2∩C4∩C5. A population that size is never listed, only **queried** — and a query you cannot
re-run is not a result. This report is the question set written to query it, and the answers that
came back. Drafted 2026-07-17 as a specification, it fixed for each of ten query families (Q1–Q10),
five figures, an Exhaustion Atlas and a reproduction spine the same four things *before* any of them
could be answered: the exact definition, the space the quantity is scoped to, the instrument, and
the check a reader can re-run. **The program was then built and executed.** The three-stage compiled
catalog — the f, g and t ladders, **15.05 TB** — was built in 2026-09 and checked against its
published per-layer registries (96 of 96 logical digests over f, g and t; 65 of 65 container digests
over **t**, with f and g re-read 130 of 130 at copy-in; §R Tier B) ⚠ *(corrected 2026-09-24: this read
"96 of 96 logical digests, 65 of 65 container digests", which reads as all three stages; the
container check covered t only)*;
the n=31 atlas was assembled from it on 2026-09-21; the queries ran on 2026-09-22, on hardware since
torn down. §0–§11 are preserved as written, with every correction made in place; **§12 is what the
atlas answered**, each figure printed beside the one public command that reproduces it.

**What it answered.** The C5 budget vector `2,8,13,7,1` is recovered exactly from the atlas's own
column sums — and it is King Wen's own boundary multiset, a *parameter the run was given*, not a
property the ladders discovered (§12.1). **68.67 % of the pruned search tree is doomed**: prefixes
valid so far that can never complete — and the waste is late, none before layer 9 and a majority of
a layer only from layer 25 (§12.2, in t-units, which price no production-DFS node). King Wen's own
transition sits low in its distance class at **24 of 31 steps**, mean percentile 0.219 against a
null mean of 0.5 — published as a **pointer with no p-value**, because the 31 steps are dependent
and the atlas yields no distribution for their mean (§12.3). Two results are **negative, and
reported as negative**: the raw one-step transition kernel is stationary across the interior of the
walk (TV ≤ 0.00099 over layers 6–23) and scores King Wen just **0.10 bits** from the population mean
(§12.4), and the positional pair field is **flat to about 3 %**, King Wen's placements typical of it
(§12.5) — both entered under Q9, the reportable-negatives section, which is where this program
expects most of its answers to land. The order in which the C5 budget is spent sits within TV
**0.0415** of the exchangeable null (§12.6). Finally, the two checks that compare this compiler
against numbers **published from a different instrument** disagree, by about twelve times tolerance:
`TR12_A2_SLOT=FAIL` and `TR12_A3_EXTERNAL=FAIL` (§12.10). **That FAIL is the measurement, not a
defect** — the two sides count different populations, differing by exactly C3 — but this program has
no C3 channel, so the attribution is an inference from two instruments each being right about what
it measured, and **not a measurement of C3 by this program**.

**What it withheld, and why.** The Exhaustion Atlas's headline verdict — EXHAUSTIBLE vs INFEASIBLE —
is **withheld**, and the consumer refuses to emit it: pricing t-units as production-DFS nodes needs a
mapping nothing certifies, and the run that would certify it needs a change to the production
enumerator that was never budgeted (§3). Whether the near-exchangeability of §12.6 is *informative*
rather than forced by the same structure that makes the kernel stationary has no calibrated null
here, so the number ships as a measurement and the interpretation does not (§12.6). Q10(b), the
coset census, is **undefined** — no subgroup set, no coset-id map — and needs a definition before it
can have a producer (§12.8). The Q7 historical-arrangement *witnesses* need `kissat`, which is
absent. Peak build space is **UNMEASURED** and no figure is quoted for it (§R.0). An exact C15 count
was **priced and permanently declined on cost — not found impossible**, and §9 keeps those two
reasons apart. **Wave 3 was never budgeted and never ran** (§Wave-status ruling), so the extremal
sweeps, the literature exact-count shortlist and the EW-2 screens specified here remain
specifications. The cost bands throughout are the 2026-07-17 estimates; realized costs are not
restated (§0 "Cost basis").

## Abstract

We specify and execute a query program over a compiled catalog of the C1∩C2∩C4∩C5 solution space
(**SUPER**, |SUPER| = N = 1.097051×10³⁹ exact, TR-11), in which the space is never materialized:
every result is a query against a three-stage out-of-core ladder — f (membership), g (exact
completions) and t (exhaustion cost) — totalling 15.05 TB, whose per-layer digests are published as
the reproduction fingerprint while the ladder data itself is not distributed. The specification
(§0–§11, 2026-07-17) fixes for each query its exact definition, its space label under a mandatory
C-8 discipline that never conflates SUPER with C15 = C1–C5, its instrument, its output shape and its
reader-side check; §R gives the three-tier reproduction spine (full rebuild, registry check, and a
laptop-scale small tier that exercises every claim *type* at n=9 and n=13 in minutes). The program
executed at n=31 in 2026-08/09, and §12 reports what the resulting atlas establishes, measured over
the whole population rather than over an enumerated slice: the C5 budget is recovered exactly from
the atlas's column sums and is King Wen's own multiset by construction; 68.67 % of the pruned search
tree consists of prefixes that cannot complete, none before layer 9; King Wen's transition is low in
its distance class at 24 of 31 steps (mean percentile 0.219 vs a null mean of 0.5), stated as a
pointer rather than a p-value because the steps are dependent; the one-step transition kernel is
stationary across the interior and does not distinguish King Wen at the scale its marginals fix
(−0.102 bits, 0.05 of an independent-step SD); the positional pair field is flat to ~3 % with King
Wen typical of it; and the C5 budget path lies within TV 0.0415 of the exchangeable null, measured
with two-sided controls and with its interpretation withheld. Two checks against externally
published C1–C5 quantities FAIL by ~12× tolerance — a difference between populations that this
C3-free compiler can exhibit but cannot attribute by measurement. The exactness frontier is stated
as cost where it is cost and as capability where it is capability, and never traded: an exact
C3-conditioned count is declined on price, not barred by structure; the Exhaustion Atlas's
exhaustibility verdict is withheld for want of a certified t-unit-to-node mapping; wave 3 was never
budgeted and did not run.

## Sections

- **What this document is, and what it is not.** The standing rules every figure below inherits: a
  number appears only as a cited prior publication, as a quantity printed beside its reproduction
  command, or as a labelled `[ESTIMATED]` plan parameter. The document is **not** a
  pre-registration and does not claim to be one.
- **§0. Conventions.** The space labels (SUPER, C15) and why no instrument here counts
  C3-conditioned; the units gate `cd_true = 2·(walk_cd+1)`, so every C15 query passes
  `--kc-c3-max 387` and never 776; the two orders (REL, the compiler's native descent; O3, the
  citable record comparator) and the walk-rank/class-rank distinction; the H3b amendment; the cost
  basis.
- **§1. The nine core queries (Q1–Q9).** rank(KW) and its neighbours; the O3/REL endpoints; King
  Wen's 31-step rarity profile; the C3 census (and the C3 minimum, **112**, closed by a structural
  bound met by a published witness); functional extremals; density extremes; historical-arrangement
  certificates; the exact-uniform gallery; and the reportable negatives.
- **§2. Visualization program (V1–V5).** Five population-exact figures over all ~1.1×10³⁹ members.
  **All five are rendered and embedded here** (V1, V2, V3, V4, V5) as of 2026-09-23 — see the
  section, which also records that two of them were reported blocked for reasons that did not hold.
- **§3. The Exhaustion Atlas (XA).** Per-branch exact solution mass and exhaustion cost in t-units.
  The EXHAUSTIBLE/INFEASIBLE verdict is **withheld**, and the reason is a missing certificate, not
  a missing number.
- **§4. Literature-claims exactness sweep (LS).** Which of ~70 literature-anchored functionals are
  walk-decomposable and could be counted exactly, which need extended state, and which honestly
  stay sampled — under a mandatory circularity-audit gate.
- **§5. The exploration wave (EW).** Constraint hunting under FRONTIER discipline, with a
  pre-registered three-outcome interpretation contract that is allowed to return nothing.
- **§6. Capabilities program appendix (CAP-1..8).** The 2026-07-17 capability plan; build status at
  HEAD is in §8.
- **§R. Independent-reproduction methods spec.** The ladder fan (f → {g, t}; g and t never read
  each other), the measured per-ladder sizes, and the three tiers: **A** full rebuild from public
  source, **B** registry check (executed here, 96/96 logical over f/g/t and 65/65 container over t), **C** the laptop small tier.
- **§7. Dependency waves + cost.** The 2026-07-17 plan. Waves 0–2 executed; wave 3 did not.
- **§8. The TO-BUILD worklist and its build status.** Thirteen rows, re-verified against HEAD.
- **§9. Judged NOT report-grade (and why).** The honesty section: what was declined, and whether the
  reason was cost or capability.
- **§10. Capstone additions.** The DONE-contract set (A–D) and the versioned updates to other
  reports (E–G).
- **§11. Prior-art refresh addendum.** Q10, the orbit/(ℤ/2)⁶-coset census in the Ouyang framing,
  plus refinements that need no new compute.
- **§12. What the n=31 atlas establishes.** This document's results section: six measured readings
  over SUPER (§12.1–§12.6), what the atlas leaves open (§12.7), Q10(b) (§12.8), the figure→token
  table for `grep -Fqx` (§12.9), and the two external anchors that disagree (§12.10).
- **§Open Problems.** Every unanswered question, classified and pointed at where its partial state
  lives — including what was *closed* rather than deferred, so the two are not confused.
- **§Confidence Ledger.** One row per headline figure across TR-1…TR-12, graded, with the artifact
  a referee should pull. Two notes record where the grading rubric itself falls short.
- **§Verification Guide.** Every claim type above, mapped to the command that checks it.

---

## What this document is, and what it is not

**It is a question set (§0–§11) with a results section (§12).** This is the specification of a query
program against the compiled solution catalog: for each query, the exact definition, the space label,
the instrument, the cost band, the output shape, and the check a reader can re-run. **The full-31
answers to Q1–Q10 are not stated in §0–§11**; §12 states, for the rows it names, what the n=31 atlas
establishes, each beside the command that reproduces it. Where a number appears it is one of
three things, and never a fourth: (i) a quantity already published in TR-1…TR-11 or
`documentation/`, cited; (ii) a quantity with a public reproduction command, printed beside it;
(iii) a cost band or plan parameter, labelled `[ESTIMATED]`. **No figure in this document is
asserted ahead of its reproduction command.** Several figures that once appeared here had neither
a public command nor a public citation; they have been struck rather than shipped, and each
strike says in place what was removed and why.
⚠ *(2026-09-21: §12 now states full-31 answers for the rows it names — each a clause-(ii)
quantity, printed beside the one public command that reproduces it. The sentence above is kept
as the rule for the question set; §12 is this document's first results section and is labelled
as one.)*

**It is not a pre-registration, and does not claim to be one.** Publishing a question set before
its answers exist is not the same act as registering those questions with a checkable timestamp
and a per-query pre-hoc/post-hoc provenance label. **This document carries no such labels and
makes no claim about when any individual query was first written.** A reader should treat the
program as a specification of what was asked and how it is checked — nothing more. Any
future use of it as a pre-registration would require that per-query provenance work to be done
first, and it has not been.

**Reproduction is already public and does not depend on this document.** The battery driver
(`scripts/tr12_repro.sh`), its committed expected outputs (`scripts/tr12_expected/n9/`), the run
order and hardware notes (`documentation/VERIFY.md` §"TR-12 query program"), the five figure specs
(`viz/viz_kc_*.md`) and the gate scripts are all on public `main`. §R below is the methods
specification behind them, not a substitute for them.

**Why the program queries a compiled space rather than an enumerated one — the scale figure.**
*(Added 2026-09-24.)*

![Log-log plot. Horizontal axis: per-cell node budget, SOLVE_PER_SUB_BRANCH_LIMIT, from about 3×10⁷ to 4×10¹⁰. Vertical axis: count, from 10⁸ to about 10⁴². Three red points near the bottom, labelled 11.2T with 759,608,573 records, 100T with 3,432,399,297 records and 560T with 10,525,271,997 records, each with its sha prefix, lie on a shallow blue power-law fit with exponent about 0.67. A purple horizontal line near the top marks N = 1,097,051,278,789,181,790,036,112,071,176,579,186,688, the exact count of the C1C2C4C5 superspace. A vertical arrow from the 560T point to the line is labelled N divided by the deepest measured slice, about 1.04×10²⁹, 29.0 decades. The legend and the vertical-axis label both state that the points and the line count different spaces. The image carries no counting-unit note; the caption below supplies it: the points count canonical pair orderings and the line counts orientation-explicit sequences.](figures/viz_scale.png)

*The scale figure. The two series count **different spaces**, and neither is a fraction of the
other. **Points:** the d3 canonical record counts (11.2T 759,608,573; 100T 3,432,399,297; 560T
10,525,271,997; shas in `documentation/CANONICAL_HASHES.md`). Each canonical is an
exactly-reproducible **node-budgeted slice of C1–C5**, and its record count is a **LOWER BOUND** on the
C1–C5 population, not that population's size (`documentation/SOLUTIONS_FORMAT.md`). **Line:**
`N = |C1∩C2∩C4∩C5|`, the **EXACT** cardinality of the **C1C2C4C5-SUPERSPACE** (SUPER, §0), computed by
the knowledge compiler (TR-11 §9). C3 is **not** among its constraints, and neither are C6/C7, so N
does not count C1–C5 either. **The gap** of about 1.04×10²⁹ (29 decades) lies between a *budgeted
slice* and a *compiled superspace*. It is **not** "how much of the space was found". **The two series
also count in different units.** A record is one *canonical pair ordering*, with within-pair
orientation masked (`documentation/SOLUTIONS_FORMAT.md` §Deduplication); under C4 there are at most
31! ≈ 8.2×10³³ of them. N counts *orientation-explicit sequences*, so each pair ordering contributes
its whole orientation fiber, between 1 and 2³¹ sequences (King Wen's is 1,720,320). Even 31! records
would sit 133,415× below N, so between 5.1 and 9.3 of the plotted 29 decades are a change of unit,
not a budget shortfall. In like units, pair orderings, the superspace holds between N/2³¹ ≈ 5.1×10²⁹
and 31! ≈ 8.2×10³³ orderings, which is 19.7 to 23.9 decades above the 560T count. What the figure does
show is that more node budget is not a route to the space: the three points grow sublinearly in the
budget (fitted exponent α ≈ 0.67 < 1), the line sits 29 decades above the deepest point, and the fitted
curve would need a per-cell budget of roughly 10³⁹ to 10⁴⁵ nodes to reach even the like-unit bracket,
against 3.5×10⁹ at 560T. That is why every question below is asked of the compiled
catalog and not of an enumeration. The axis runs the full 29 decades unbroken on purpose, and the spec
and caption rules are in [`viz/viz_scale.md`](../viz/viz_scale.md). [SVG](figures/viz_scale.svg).*

---

## 0. Conventions every item below inherits

**Output paths.** Output names of the form `tr12/<file>` below are the 2026-07-17 specification's.
**A `tr12/` directory IS tracked in this repository**, and holds the n=31 outputs this report cites:
`tr12/VERDICTS.txt`, `tr12/q10_orbit_census.tsv`, `tr12/q3_profile_kw.tsv`, `tr12/v3_rel_grid.tsv`,
`tr12/v3_spectrum.tsv`, `tr12/xa_branches.tsv`, `tr12/xa_verdict.md` and, under `tr12/scan/`,
`v1_field.tsv`, `v2_river.tsv`, `v2_branches.tsv`, `v5_grammar.tsv`, `q6_layer_mass.tsv` and
`q6_layer_extremes.tsv` (thirteen files; `git ls-files tr12`). ⚠ *(corrected 2026-09-24: this read
"**no `tr12/` directory is tracked in this repository**. The basenames are real and the prefix is
not". That was measured true on 2026-09-22 and stopped being true the next day, when v1.10 tracked
the directory without revisiting this sentence; §2 cites two files inside it.)* The
basenames are also what the tools write:
`python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR` writes `VERDICTS.txt`,
`q10_orbit_census.tsv`, `xa_branches.tsv`, `xa_verdict.md` and a `scan/` subdirectory
(`v1_field.tsv`, `v2_river.tsv`, `v2_branches.tsv`, `v5_grammar.tsv`, `q6_layer_mass.tsv`,
`q6_layer_extremes.tsv`) into whatever `DIR` the reader names, and `scripts/tr12_repro.sh` writes the
same basenames under its own run directory's `artifacts/` tree — so a reader who re-runs the
consumer chooses where its output goes, and can diff it against the tracked copies. Three of the spec's names correspond to nothing at HEAD
and are flagged where they appear: `q10_coset_census.tsv` has no producer (`--kc-coset-census` does
not exist, §11 Q10(b)), `q9_negatives.md` has never existed in this repository (CX-73), and the XA
convention pin is written as `xa_node_convention.json`, not `.txt` (§3). *(Added 2026-09-23.)*

**Spaces (the C-8 label discipline; used on every quantity).**
- **SUPER** = C1∩C2∩C4∩C5, the compiled walk superspace. |SUPER| = N =
  **1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097051×10³⁹** (exact; TR-11 §9;
  log₂ N ≈ 129.689 bits — reader arithmetic on the published exact N, e.g.
  `python3 -c "import math;print(math.log2(1097051278789181790036112071176579186688))"`;
  N/24 exact). Orientation-explicit walks, C4's pair pinned.
- **C15** = C1–C5 (C3 applied). |C15| = **1.3287×10³⁸, ESTIMATE** (TR-4 abstract), **95 % CI
  [1.3283, 1.3292]×10³⁸**. ⚠ *(Corrected 2026-09-12, V3B-03#4: this read "±0.02%". The 0.02 % TR-4
  publishes is a **relative standard error** — `relerr = SE/mean`, `reports/METHODS.md` §relerr —
  **not** a 95 % half-width, and rendering it with a ± sign invited exactly that reading. The CI's
  own half-width is 0.00045/1.3287 = **0.034 %**, and 1.96·SE would be 0.039 %, so the ± form
  understated the interval a reader would draw from it by ~1.7–2×. The estimate is unchanged; only
  the uncertainty notation is.)* **no
  instrument in this program counts C3-conditioned** — the f/g/t ladders carry no C3 channel and
  the profile mode refuses `--kc-c3-max` outright — so C15-scoped results are estimates-with-CI,
  witness/search results, or filtered-enumeration results, never exact counts. *(Wording narrowed
  2026-09-05: this read "exact C3-conditioned counting is an open obstruction (TR-11 §10(ii))",
  which cites TR-11 §10(ii) for a claim TR-11 §10(ii) **v1.5 withdrew** — the barrier there is
  "footprint cost, not structure". What binds THIS program is its instruments, and that is now
  what the sentence says; see the H3b note below.)* Exclusion factor SUPER/C15 ≈ 8.26 (measured-sampled).
- **Units gate (CT1.6):** true C3 ≤ 776 ⟺ walk-functional cd\* ≤ **T = 387** at full-31
  (cd_true = 2·(walk_cd+1)). **The gate is published and the arithmetic is the reader's:**
  `documentation/VERIFY.md` §"TR-12 query program" states it in the same terms — *"True C3 ≤ 776
  ⟺ the walk functional `--kc-c3-max 387` at full 31 pairs (`cd_true = 2·(walk_cd+1)`). Pass 387,
  never 776. Passing 776 silently doubles the ceiling."* — and 2·(387+1) = 776 closes it without
  any project document. **`walk_cd` is the sum, over the 31 free complement couples `{h, 63^h}`
  with both endpoints placed, of `|pos(h) − pos(63^h)|` — each couple counted ONCE.**
  **The step-by-step derivation is PUBLIC, in `solve.c`, and this document used to say it was not**
  *(corrected 2026-09-13, V3B-03#3; the retired sentence read "the step-by-step derivation is an
  internal proof note; it is not cited, because nothing above needs it" — wrong in fact, and every
  C15-scoped figure in this program rests on the `--kc-c3-max 387` it justifies)*. It is the
  `UNITS (review C-1)` comment block on the walk functional, quoted verbatim: *"this walk functional
  counts each couple ONCE and, at full-31, never sees the anchor couple {63,0} (neither endpoint is
  a walk hexagram), whereas true C3 counts every couple TWICE over all 64 hexagrams and includes the
  anchor couple. So at full-31 cd_true = 2*(walk_cd + 1), and C3 <= 776 (KW's ceiling) <=> walk
  cd <= T = 387."* It is also gated **executably**, not merely commented: `kc_oracle_selftest`
  asserts `KW boundary: walk-cd(KW) == 387 exactly (T admits KW)` and
  `units: 2*(walk_cd+1) == whole-seq C3, every sampled walk`, so a 387-vs-388 off-by-one cannot
  recur silently. Every C15 query
  passes `--kc-c3-max 387`, never 776.

**Orders (never conflated).**
- **REL** = reverse-exit lexicographic — the compiler's native descent order; `--kc-rank/--kc-unrank`
  implement it TODAY from forward layers alone.
- **O3** = the ratified `compare_solutions` record comparator (pair-identity bytes primary, full
  bytes tiebreak) — the CITABLE order (charter D2/H5). **An independent comparator is constructible
  from public sources alone, and this section cited none of them** *(added 2026-09-13, V3B-03#5)*:
  the 32-byte record layout `byte[i] = (pair_index << 2) | (orient << 1)` and the 32-row pair table
  are both published in `documentation/SOLUTIONS_FORMAT.md` (§"Record format", §"Pair table"); the
  comparator is `compare_solutions` in `solve.c` — *"total strict order on 32-byte records. Primary
  key is pair identity (byte & 0xFC); secondary key is the full byte (including orient bit)"* — and
  the ladder-side implementation a reader can diff against it is `kc_o3_cmp`, a pure byte-level
  comparison with no ladder involvement (both cited by symbol; line numbers drift).
  Ranking in O3 needs the Stage-G g-ladder +
  the **O3 ranker (TO-BUILD, freeze row C7/E3; already on the Fable worklist)**.
- **Walk-rank vs class-rank (design note for the O3-ranker builder, must be pinned before any
  citable rank ships):** records are orientation-masked classes (multiplicity m(k)); N counts
  walks. Freeze-row E3 defines rank(KW) as the superspace **walk** O3 rank; the class-rank (# of
  distinct records preceding KW's record) is a second quantity. TR-12 publishes the walk-rank as
  primary; class-rank only if the ranker's m(k)-collapsed mode lands. **`repr(KW)=KW`, and the
  argument is one sentence** *(supplied 2026-09-13, V3B-03#5; this read "`repr(KW)=KW` is PROVEN"
  and gave neither argument nor citation)*: a record's class representative is the
  orientation-lex-least member of its class, and the labels are KW's OWN pair table, so KW's
  pair-vector is the identity and every one of its orientation bits is 0 — the lex-least member of
  its own class, i.e. its own representative. It is not only argued but **checked at n=31** by
  battery row `a2_q1_labeling`, which requires `rank3`, `class_first_rank3` and `orient_idx` to read
  0, 0, 0; at n=9 those same three fields are the fixture triple **13056 / 12960 / 96**
  (`scripts/tr12_expected/n9/a2_q1.txt`), which is what a NON-degenerate labelling looks like and is
  why the n=9 rehearsal cannot exercise the forced-zero branch.

**H3b — the normative texts were AMENDED (2026-09-05), and this says so rather than leaving a
reader to find the seam.** Until then this project's own specifications named two different
measurements for one certificate: four planning texts pinned rank(KW) "in the C1–C5 space
(C3 ON…)", while the charter's own H3b (corrected 2026-07-17), freeze-checklist row E3 and
capstone B-3 — the respec this program follows — said "superspace-walk O3 rank", with C3 as the
membership gate and the space label mandatory. **The four stale sites are amended to the
superspace form**, which is what the program computes and what ships. Left alone, the conflict
would have promised a reader an exact number and then delivered an estimate — a documentation
defect handed to a reviewer as a finding.

**What ships, unchanged by the amendment:** **rank_O3^SUPER(KW), exact** (the H3b certificate) +
**rank_O3^C15(KW) as a labelled estimate** (Q1). **Why the C15 rank is an estimate — stated as
cost, because that is what it is.** An exact C15 rank is *not* barred in principle. C3 collapses
to the bounded scalar identity **C3 = 16 + 8·G** — a machine-checked theorem
(`lean/C3Decomposition.lean`, `c3_slot_decomposition`) — so a DP
can carry it, and `reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md` §10(ii) **v1.5
withdrew** this project's earlier "open structural obstruction" wording in favour of *"the
remaining barrier is footprint cost, not structure."* The bounded-state instrument is built
(`--f1-c3-hist --with-c5`). A full-31 C3-conditioned run was **priced and permanently declined on
cost** (operator, 2026-08-25); no dollar band is restated here, per TR-11 v1.10's withdrawal of
its own cost figures and `documentation/CAMPAIGN_METHODOLOGY.md` §7 rule 9's itemized-ledger bar.
**Cost and capability are two different reasons and this document never trades one for the
other** — see §9.

**Instruments that EXIST** (v4-compiler pin `8a7e3f0`+`86ec533`): `--kc-count/-unrank/-rank/
-member/-repr/-sample/-enum` (OOC, full-n; REL order; `--kc-c3-max`, `--kc-record`,
`--kc-class-uniform`; `#provenance` trailer on all record-facing output), `--kc-g-build/-check/
-selftest` (Stage G engine; the n=31 g-ladder was built 2026-09 — 8.27 TB, 32/32 layer digests
registered, §R.0 and §R Tier B), `--f1c5-layer-sha` (decompressed-stream layer
shas), `sat.py` (CNF emit incl. C3 encoding, witnesses, DRAT), `verify.py`/`solve.py` constraint
predicates, `--null-historical`, the DFS walker (v4-canonical `b1464fa`). **Certificate hygiene:**
every published number carries: command line, build identity (git+source sha), layer-dir sha
registry, `#provenance` scope line, and the reader-side re-derivation (H6 form; "certificate, not
proof").

**Cost basis [all ESTIMATED unless marked].** Stage F ≈ $75–105 central and Stage G +$60–110 — both
are 2026-07-17 estimates, and both stages have since been built (measured sizes, §R.0); realized
cost is not restated (`documentation/CAMPAIGN_METHODOLOGY.md` §7 rule 9). Spot D8/D16/D32 ≈
$0.03–0.30/hr; a full-31 layered count-DP re-run
(no layer retention) ≈ $40–80; a full ladder streaming pass (scan class) ≈ $15–50; point queries
against mounted ladders ≈ $1–5. **No campaign-scale dollar anchor is quoted here.** The 560 T
campaign's realized total is not published: `documentation/CAMPAIGN_METHODOLOGY.md`
(§"Total realized cost", corrected and amended 2026-09-01) withdraws it as an estimation anchor
under that file's §7 rule 9, which sets the bar for restating one at an **itemized** ledger —
VM-hours by SKU, disk-months, closeout. Heavy ops on Spot workers, never the orchestrator.

> **⚠ The cost bands in this section and in every per-query `Cost:` line below are the 2026-07-17
> estimates**, made before Stage G existed and before any query was executed. Every stage and every
> wave-0–2 query has since run; **realized costs are not restated** (`documentation/CAMPAIGN_METHODOLOGY.md`
> §7 rule 9 bars putting a cost total in a published document without an itemized ledger), and the
> measured wall times and hardware are in `documentation/VERIFY.md` §"TR-12 query program". The bands
> are stated as *dollar* bands; **their implied wall times are not current.** Wave 3 was never
> budgeted and did not run, so its bands were never tested against anything.

---

## 1. The nine core queries (Q1–Q9)

**TO-BUILD** below is the 2026-07-17 label, kept as written. §8 gives each surface's status at HEAD:
items 1–7, 11 and 13 are **BUILT**; item 8's LS/EW property-channel extension, item 9's SAT
bisection driver loop, item 10 (the CAP-7 slice wrapper) and item 12 (the CAP-4 prototype) are not.
The TO-BUILD marks that remain accurate are the BnB walker, the SAT driver, CAP-4, CAP-7 and the
Q10(b) coset census.

### Q1. rank(KW) in the citable order + rank-neighbors — the H3b certificate
- **Definition.** rank_O3^SUPER(KW) = |{w ∈ SUPER : w <_O3 KW}| (walk-rank; exact integer
  ∈ [0, N)). Neighbors: unrank_O3(rank±1) — the walks immediately adjacent to KW in the citable
  order, reported in full with first-divergence positions. Scoped companion:
  rank_O3^C15(KW) = |{w ∈ C15 : w <_O3 KW}| — **estimate only** (see mechanism).
- **Endpoint case (forced at full-31 by the KW-derived labelling, §Q2)** *(added 2026-09-13,
  V3B-03#6; the battery has handled this case all along and this report never stated it)*:
  `rank_O3(KW) = 0`, so the predecessor is `NONE` (`--kc-o3-cert` writes the literal), the successor
  is `unrank_O3(1)`, and Q1(c)'s conditioning interval `[0, 0)` is empty — the battery records
  `TR12_Q1C=EMPTY:interval-degenerate-at-n31` as a RESULT, not a skip, and the C15 estimate over
  that interval is not run. **Read the headline rank accordingly:** a rank of 0 in ~10³⁹ is not a
  measured rarity, it is a tautology of the labelling, because the labels are KW's own pair table
  (§0, "Orders"). At n=9 the anchor is not the O3-least object, so the n=9 rehearsal returns
  `NONEMPTY:interval-cardinality-13056` instead — the producer can refuse, which is what makes the
  n=31 `EMPTY:` a measured null rather than an assertion.
- **Mechanism.** O3 ranker (**TO-BUILD**, the CT1.5/CT3.6 item; g-weighted forward descent over
  the record order, consuming f·g per descent position; F1_CHECK f>0 on every g consumed per
  Stage-G review SG-1). C15 estimate: draw M exact-uniform ranks in [0, rank_O3^SUPER(KW)) via
  `--kc-sample`-style unranking, C3-test each (T=387), p̂ ⇒ rank^C15 ≈ p̂·rank^SUPER with binomial
  CI. H3b certificate = rank(unrank(r))=r + unrank(rank(KW)) byte-identical to KW + neighbor
  bracket + `#provenance`.
- **Stage:** needs Stage G + O3 ranker. **Cost:** queries ≈ $1–5; estimate leg (M=10⁴) ≈ $5–15.
- **Output:** `<artifact-root>/q1_rank_kw.txt` — exact decimal rank, the two neighbor walks + records, the
  C15 estimate ±CI, certificate block. Machine-checkable: re-run rank/unrank; big-int compare.
- **Cross-check:** DFS rank consistency at exhaustive n ≤ 13 (cross-engine byte-match precedent,
  n=9 landed); REL-order rank(KW) via existing `--kc-rank` as an independent second coordinate
  (different order — reported, labeled, never conflated).

### Q2. Solutions #0, #N−1, #⌊N/2⌋
- **Definition.** unrank_O3(0), unrank_O3(N−1), unrank_O3(⌊N/2⌋) in SUPER (exact). C15-scoped:
  FIRST^C15 = the O3-least C3-passing walk; LAST^C15 = O3-greatest. 🔴 **Two corrections, QSET-2
  finding 3, 2026-09-06.** (a) **What the battery commands for the C15-SCOPED endpoints is REL, not
  O3.** ⚠ *Narrowed 2026-09-13 (V3B-03#7): this read as a blanket — "what the battery actually
  commands is REL, not O3" — which understates the run in the SUPER direction. The two scopes are
  delivered in different orders, and the definition is now stated as delivered.*
  **SUPER endpoints — delivered in O3, with certificates.** Row `a2_q2` commands `--kc-o3-unrank`
  at `0`, `N−1` and `⌊N/2⌋` under `--kc-bracket`, which unranks r∓1/r/r+1, ranks all three back and
  checks strict O3 order with an independent comparator; at the two endpoints its `r∓1: NONE` line
  IS the endpoint certificate. These are O3 quantities, not REL analogues.
  **C15-scoped endpoints — delivered in REL.** The inventory's
  Q2c/Q2d rows invoke `--kc-enum` / `--kc-enum-desc`, whose own golden provenance line reads
  `order=REL-DESCENDING(…;NOT-O3)` and whose CLI documentation states REL "is **not** O3". No
  filtered *O3* endpoint command exists in this tree, so for the C15 scope the O3 definition above
  is not the quantity the battery delivers.
  **The completion criterion, in one place so a reader needs no other:** the three SUPER probes are
  complete when all three return `CERTIFICATE PASS` under `--kc-bracket` **and** `TR12_GCHECK` and
  `TR12_GSHA` are PASS — the bracket certifies the rank/unrank PAIR, not the ladder, and measured, a
  g ladder corrupted at 3 of 12 probed offsets fails `--kc-g-check` while the bracket still
  certifies PASS, because rank and unrank read the same wrong g — plus, at n ≥ 31, the one external
  anchor: `unrank_O3(0)` byte-identical to King Wen. (b) **The O3 form is already determined:** `rank_O3(KW) = 0` is forced by the
  KW-derived labelling (the Q1 labeling ruling), and King Wen is in C15, so **O3-`FIRST^C15` is King
  Wen** — by construction, not by measurement. O3-`LAST^C15` remains uncommanded. A C15 *midpoint* is **not
  shipped** — it would require an exact C3-conditioned count, which was priced and permanently
  declined on cost (§9), not found to be impossible. Not claimed; the reason is stated in §9.
- **Mechanism.** SUPER: O3 ranker unrank (post-G); REL-order analogs available post-F TODAY via
  `--kc-unrank DIR 0|N−1|mid` (`--kc-midn` machinery validates mid-rank plumbing). FIRST^C15:
  in-order filtered descent = `--kc-enum DIR --kc-c3-max 387 --kc-limit 1` (post-F for REL;
  O3-order variant rides the ranker). LAST^C15: **TO-BUILD** trivial descending-order enum flag
  (`--kc-enum-desc`) or descend-max mirror.
- **Stage:** REL forms post-F; O3 forms post-G+O3. **Cost:** ≈ $1–5 each; FIRST/LAST^C15 descent
  cost bounded by prune tightness — expected minutes, hedged (worst case the first satisfying
  walk is deep; bounded by a wall-clock abort, `TR12_Q2_ENUM_TIMEOUT`). ⚠ **This read
  "abort-and-report protocol if > 10⁶ backtracks" until 2026-09-11, and no such mechanism was
  ever built** — `grep -i backtrack` finds none in `solve.c` or the battery. The 2026-09-11
  correction (CX-44) swept `documentation/`, `solve.c` and the battery and did NOT search
  `reports/`, so this published site kept the promise three hours longer than the others.
- **Output/verification:** full 64-hexagram sequences + records + ranks + certificates; skeptic
  re-derives by re-running unrank and by validating constraints with `verify.py`-class checkers.
- **Ranks of "aesthetic interest": DECLINED** (no numerology framing; any specific rank is O(1)
  to query later if the operator wants it — nothing pre-committed).

### Q3. KW's rarity profile — f·g at each of KW's 31 prefix steps
- **Definition (SUPER-labeled).** For i = 1..31, with s_i = KW's prefix state after i placements:
  **g(s_i)** = completions remaining (exact); **f(s_i)** = # prefixes reaching that state (KW's
  prefix is one of them); the per-step conditional probability of KW's next choice under the
  uniform measure on SUPER: **p_i = g(s_i) / Σ_{c admissible at s_{i−1}} g(s_{i−1}∘c)** — note
  the denominator equals g(s_{i−1}) (DP recurrence), so the curve is g(s_i)/g(s_{i−1}).
  Deliverables: BOTH the raw completion counts g(s_i) (the "neighborhood shells") and the
  conditional-probability curve p_1..p_31. **Self-check: Π p_i = 1/N exactly** (telescoping —
  g(s_31)=1, g(s_0)=N); the published table must print this product.
- **Mechanism.** 31 g-lookups against the Stage-G ladder (canonicalize KW's prefix state per
  layer; g is G-equivariant) + per-layer admissible-choice sweeps for the alternatives'
  g-masses (also g-lookups). No new subcommand strictly needed if the O3 ranker's descent
  exposes its per-position f·g trace; else **TO-BUILD** `--kc-profile "e,x,..."` (thin wrapper,
  prints the 31-row table for ANY walk — KW is just the first customer).
- **Stage:** post-G. **Cost:** ≈ $1–5.
- **Output:** `<artifact-root>/q3_profile_kw.tsv` (31 rows: choice, #alternatives, g of each alternative,
  p_i, −log₂ p_i) + the product self-check line. C15 companion: ⚠ **WITHDRAWN
  2026-09-05 (QSET finding 2).** This promised "sampled per-step C3-pass corrections (rejection
  sampling), labeled ESTIMATE" — a named deliverable **with no instrument**. The battery commands
  only the SUPER trace, and `--kc-profile` *refuses* `--kc-c3-max`
  (`documentation/SOLVE_C_CLI.md`), so no commanded path produces it. Withdrawn rather than left as
  a promise the program cannot keep.
- **Cross-check:** Π p_i = 1/N (reader-side big-int); Σ over alternatives of g = g(parent) at
  every step; DFS subtree counts at n ≤ 13. Feeds V4 (shells figure) and EW-1 (surprise ledger).

### Q4. The C3 census — ceiling count, min, extremes
- **Correction adopted from research: FH-1 is C5-residual machinery** (capping/no-lumping — cited
  here as the reason exact C3 state-tracking is blocked, i.e. the honest wall), NOT a
  C3-range instrument. **The C3-range record is public and needs no internal note.**
  `documentation/SPECIFICATION.md` §C3 states that at the C1–C5 canonical scope King Wen sits
  **at the C3 ceiling, 12.125 exactly**; that the AT-ceiling tie fraction is measured per
  enumerated set and is not a universal constant (**~9.91%** over the 3.43 B-ordering 100 T
  canonical = **340,179,649** ties, and **~10.11%** over the 10.5 B-ordering 560 T canonical =
  **1,063,580,364 of 10,525,271,997** records — ⚠ both are **560T/100T
  traversal samples: a DFS-order PREFIX of the space, not a uniform draw**, which is why the figure
  moved 9.91% → 10.11% as the budget grew; they are **record-level** tie shares and must not be read
  against a **walk-level** μ without the 1/m weighting of §Q4); and that the threshold is
  King Wen's own value, *"extracted from the sequence, not derived independently."* A private
  foothold (F-MC) holds a further sample-scoped AT-ceiling tie fraction — **that sample's number
  is not quoted here** and nothing above depends on it. The nearest quantity with a public
  reproduction command is `P(C3 ≤ 776) = 12.1288%` over the T5 mega-sample,
  `documentation/VERIFY.md` `verify.py --check-t5-c3`, a different estimand under its own scope
  label. Instrument: `--c3-min` (min over a `solutions.bin`).
  **Where each numerator comes from, and which inputs are not public** *(added 2026-09-12,
  V3B-03#8 — the figures above were quoted as bare percentages with their public numerators
  uncited).* The 560 T pair 1,063,580,364 / 10,525,271,997 is published in
  `documentation/PROJECT_OVERVIEW.md` §C3 and the record count in
  `documentation/CANONICAL_HASHES.md` §"d3 560T"; the same sites carry min cd×64 = 392. Both, and
  the 100 T analogue 340,179,649 = 9.9108 %, are `./solve --c3-min <solutions.bin>` outputs; the
  100 T recipe and its log lines are committed at
  `runs/20260419_100T_d3_d128westus3/README.md`, but **the 560 T `--c3-min` run log is not
  committed** — `runs/20260608_560T_9a968fa2/` holds only `viz/` — so at 560 T the counts are
  cited, not re-runnable from this tree (regenerating them means reading the archived 560 T
  canonical, a deep-Archive rehydrate barred by standing rule). The 12.1288 % figure is
  `verify.py --check-t5-c3` over the T5 parquet, whose **input is not in this repo**
  (`documentation/VERIFY.md`). **[I1 correction, C3 adversarial review 2026-07-22
  (internal; the corrected value is public and is the anchor): the "sample min cd×64 = 576"
  formerly cited here was stale —
  `SPECIFICATION.md` §C3 records min cd×64 = 392 (i.e. G = 47) over the 10.5B-ordering 560T
  canonical population, a known witness that supersedes 576. *(Witness value corrected
  2026-07-27, claim-defense lens CD-3: the I1 correction as first applied quoted 424/G = 51,
  which is SPECIFICATION's 100T minimum, not the 560T one — 392 at 560T per SPECIFICATION §C3,
  SOLVE_SUMMARY §[22], SOLVE.md, CLAIMS_DECIDED, PROJECT_OVERVIEW, CITATIONS.)*]**
- **Definitions.** (a) CEILING census: μ = P_{C15}(C3 = 776) — fraction of C15 solutions AT KW's
  sharpness. ⚠ **Space-label correction, 2026-09-05 (QSET finding 6): μ is defined here over
  C15 and the executable contract computes it over SUPER** (`documentation/QUERY_INVENTORY.md`
  row Q4a/c, `--kc-sample` draws over all of SUPER). The two are different estimands and the
  8.26 exclusion factor separates them. **The shipped quantity is the SUPER one**; a C15-scoped μ
  would need the C3-conditioned draws this program does not command. Whichever ships must carry its
  own label, per §0's space discipline — the mismatch is recorded rather than silently resolved,
  because which one the report wants is a scope decision, not a typo.
  🔴 **RESOLVED 2026-09-11 (V3B-03#9), and this row no longer reads "unresolved".** The scope
  decision was taken and the battery implements it. **Exactly one estimand ships as the headline:
  the WALK fraction, at `cd ≤ 387`, OF C15** — `μ_walk^C15` = `mu_hat_P_C15_cd_eq_T` in row
  `a1_q4ac`, an ESTIMATE with a 95 % Wilson interval on the C15-accepted draws.
  ⚠ **Space label corrected 2026-09-13 (V3B-03#9): this read "the WALK fraction **over SUPER**" and
  labelled the quantity `μ_walk^SUPER`.** The shipped number is `h[T] / le` — numerator **and**
  denominator are C15-accepted draws — so it is a fraction **of C15**, and publishing it "over
  SUPER" stated it against a population **8.26× larger** than the one it is a fraction of. The
  2026-09-05 space-label correction that introduced the wording confused the **sampling frame** with
  the **conditioning set**: the draws are uniform over SUPER (that is how the sample is taken) and
  the ratio is conditioned on C3-acceptance (that is what the number is a fraction of). Both are
  true; only the second is the space label. Beside it, and
  labelled as a companion rather than as the headline, the row now also emits **`μ_rec^C15`
  (`mu_rec_C15_HT`)**: the same draws reweighted by `1/m(k)`, the ratified Horvitz–Thompson
  correction from `V4_RECORD_CONVENTION_DECISION_2026_07_14`, which converts the walk-uniform
  gallery into the **record-level** census the historical ~10.11 % tie share belongs to. Its
  interval is Wilson at the effective sample size `n_eff = (Σw)² / Σw²`, never at the draw count.
  The two numbers are different quantities over one sample and each carries its own label; neither
  is the other, and the difference between `μ_rec^C15` and the historical figure is the reportable
  quantity. (b) C3-MIN: min{C3(w) : w ∈ SUPER} with argmin witness (note C3-min over SUPER =
  over C15 automatically since min ≤ 776). (c) The C3 distribution over SUPER (histogram).
🔴 **Q4b(b) IS ALREADY ANSWERED IN THIS REPOSITORY, and this section posed it as open until
2026-09-05.** `min{C3(w) : w ∈ SUPER} = **112**`, with a public witness. The lower bound `G ≥ 12` is
structural — 12 complement couples in pairwise-distinct slots, by counting — and
[`reports/certificates/c3_positional_witnesses.txt`](../reports/certificates/c3_positional_witnesses.txt)
(committed 2026-07-24 under the title *"C3 positional SAT/DRAT certs (TR-12 Q4b)"*) carries a
verified ordering **achieving** it: `G=12 C3=112` with its 64-hexagram sequence. A structural bound
met by an exhibited witness closes the bracket at its floor, so **no bisection, no UNSAT leg and no
DRAT certificate are required** for the minimum. The same tree already says so in two other places —
[`documentation/CLAIMS_DECIDED.md`](../documentation/CLAIMS_DECIDED.md) and
[`reports/certificates/README.md`](../reports/certificates/README.md) (*"G = 12 is the structural
floor … and it is achieved"*).

Reproduce, from published artifacts only:
```
./solve --check-arrangement "$(sed -n 's/^SEQ=//p' reports/certificates/c3_positional_witnesses.txt | head -1 | tr -s ' ' ,)"
#   -> C3 complement distance: HOLD (value 112, ceiling 776);  verdict SUPER: IN
```
**What remains genuinely open is only the SAT *machinery*** — `sat.py`'s bisection driver, `kissat`
and `drat-trim` are still absent. The `PENDING:sat-c3min-driver` token this sentence once pointed at
has since been retired (2026-09-21 correction below): the tooling is absent, and the question is
closed at 112. Found 2026-09-05 by a Fable adjudication of the
QSET external review, which the external review itself missed; see
[`documentation/CORRECTIONS.md`](../documentation/CORRECTIONS.md).

  **Exact versions of (a)/(c) are not shipped** — no instrument in this program counts
  C3-conditioned (§0), and the run that would has been priced and declined on cost, not ruled
  out structurally (§9); published as estimates-with-CI.
- **Mechanism.** (a)/(c): exact-uniform `--kc-sample` (post-F; M = 10⁵–10⁶ walks; evaluate
  cd\* per walk; ⚠ **CI claim narrowed 2026-09-06, QSET-2 finding 5 — and this is residue of a
  correction applied only halfway on 2026-09-05.** That pass fixed the C15-vs-SUPER space label on
  this row and left this clause untouched. 🔴 **Re-corrected 2026-09-12 (V3B-03#10): the 2026-09-06
  narrowing was itself stale, in the opposite direction.** It said the battery emits "one Wilson
  interval on the acceptance mass, not per-bin intervals: the histogram bins ship with counts and no
  CIs". The battery at HEAD emits all three. **One output contract, stated once:** M =
  `TR12_Q4AC_M` (default 10⁶ at n = 31), seed `TR12_SEED` (default **9276183659154465378**), level
  95 % Wilson with z = 1.959964 — on `P(cd ≤ T)`, on μ = h[T]/accepted, **and as a per-bin Wilson
  table over the histogram** (`cd  count  wilson95_lo  wilson95_hi`), row `a1_q4ac` of
  `scripts/tr12_repro.sh`, landed battery F-5 D8 2026-09-08 and pinned in
  `scripts/tr12_expected/n9/a1_q4ac.txt`) — an estimator upgrade over this project's own prior C3
  histograms (previous data was enumeration-slice-scoped; this is uniform over ALL of SUPER). (b): SAT
  binary search — `sat.py` C3 encoding — **[I1 correction, C3 adversarial review 2026-07-22:
  bisect on integer G, not on cd×64 units.** By the
  machine-checked `c3_slot_decomposition` (lean/C3Decomposition.lean), C3 = 16 + 8·G universally
  over C1-valid orderings, so C3 is supported on the mod-8 lattice and "+2" cd×64 granularity is
  impossible; and the starting bracket is **G ∈ [12, 47]**, not "from 576 downward" — G ≥ 12 is
  structural (12 couples in distinct slots), and G = 47 (cd×64 = 392) is a *known witness* from
  the 560T canonical population (`SPECIFICATION.md` §C3, extractable via `--c3-min`; bracket
  corrected 2026-07-27 from [12, 51]/424 — 424/G = 51 is the 100T minimum, not the 560T one).] Decide
  "∃ C1–C5-valid with G ≤ X" for integer X, ~5–6 SAT decisions; each SAT=witness, each
  UNSAT=DRAT certificate ⇒ **rung-1 exact min**. SAT hardness unbounded — pre-declare a
  per-decision timeout + fallback: report the bracket [deepest-UNSAT-G+1, best-witness-G]
  honestly (G units; ×8+16 for cd×64). Optional cross-check: BnB walker with the monotone
  partial-cd bound (**TO-BUILD**, research-grade, not report-critical).
- **The bisection is pre-registered in public, and the instrument that would run it does not exist
  in this repository** — and, as the 2026-09-21 correction below shows, running it for the minimum
  would re-derive 112 with zero UNSAT legs, hence zero DRAT certificates. This is stated as a method
  commitment, not a result. Its three public anchors, all at
  `main` HEAD: (i) the primitives — `python3 sat.py --emit-cnf|--decode|--witness TARGET
  [--with-c3] [--c3-max N] [--c3-min N]`, grammar and semantics in
  `documentation/SAT_CLI.md` (§usage synopsis; `DECODE_VERDICT=PASS|FAIL` is `PASS` only when C3
  falls inside the requested `--c3-max`/`--c3-min` window); (ii) the *method*, already committed
  in the battery driver — `scripts/tr12_repro.sh` prints, as the Q4(b) skip reason, that "the
  bisection loop over `sat.py --with-c3 --c3-max $((16+8*G))`, G in [12,47], does not exist yet";
  and (iii) the *status token* — `TR12_Q4B=PENDING:sat-c3min-driver`, pinned in
  `scripts/tr12_expected/n9/_EXPECTED_SKIPS.txt`, so the gate fails if this row silently changes
  state. A reader can therefore check the arithmetic of the bracket (`C3 = 16 + 8·G`, G ∈ [12,47]
  ⇒ cd×64 ∈ [112, 392]) and the pre-commitment of the search **before** any driver is written.
  Pre-committing a method ahead of its instrument is the intended direction; **the driver loop is
  TO-BUILD and nothing here claims otherwise.**
  ⚠ **[CORRECTED 2026-09-21, Q-665 — anchors (ii) and (iii) above no longer exist at `main` HEAD,
  so a reader following them finds neither.** Since battery F-5 D10 (2026-09-08) row `a0_q4b` of
  `scripts/tr12_repro.sh` does not skip: it runs `--check-arrangement` over every line of
  `reports/certificates/c3_positional_witnesses.txt` and `TR12_Q4B` is `PASS` on a computed fact,
  so no skip reason naming the bisection loop is printed and no `TR12_Q4B=PENDING:sat-c3min-driver`
  row is pinned in `scripts/tr12_expected/n9/_EXPECTED_SKIPS.txt` (measured at `8c2ce1f0`:
  `grep -c TR12_Q4B` over that file returns 0 against 21 readable lines). The *question* was
  answered 2026-09-05 — min C3 over SUPER = 112 — see the paragraph above beginning "What remains
  genuinely open" and the 2026-09-05 entry in `documentation/CORRECTIONS.md` (the
  `PENDING:sat-c3min-driver` token "accurate about the tooling and misleading about the question").
  What still stands of this pre-registration is anchor (i), the CLI grammar, and the I1 method
  bullet (bisect on integer G). A driver for that method has since been drafted outside this
  repository; on `plain` it is not worth running for the minimum, because a G = 12 witness is IN
  SUPER and SAT at G implies SAT at every larger G, so every probe from G = 12 upward is SAT and a
  bisection can only return 112 after zero UNSAT legs — hence zero DRAT certificates — re-deriving
  a published constant while exercising none of the certificate path.]**
- **Stage:** (a)/(c) post-F; (b) NOW-able (SAT needs no compiler). **Cost:** (a)/(c) ≈ $5–20;
  (b) ≈ $5–50 on a Spot D16 depending on SAT behavior [wide-hedged].
- **Output/verification:** histogram TSV + the three Wilson tables named in the Mechanism bullet
  (acceptance mass, μ, and the per-bin table); DRAT certs re-checkable via drat-trim
  (rung 1); witnesses validated by `verify.py`-class checkers. TR-9's circularity note on C3's
  threshold is restated wherever the census is quoted (the ceiling is KW-defined).

### Q5. Functional extremals — what the DP can optimize
- **Decomposability verdict (from the suite audit; full table in §4-LS).** The compiled DP state
  is (canonical-mask, last, rid≤6048) per layer. DP-optimizable over SUPER, class (a) —
  pairwise/placement-local: wave/`--path` (C5-forced CONSTANT — nothing to optimize, say so),
  `--lines` per-line change counts, `--canons` half-statistics, `--graycode` tallies, positional
  pair-marginal matches, boundary KW-match counts, edit-distance-to-KW (§ but see caveat 3).
  Class (b) — small extra state: `--markov` (×5 last-distance), `--mutual-info`
  (bounded counters), `--yinyang` running-balance extrema, prefix level-cover masks, **and C3
  itself** — ⚠ *(moved from class (c) on 2026-09-12, V3A-134#10; this row read "`--complements`
  (C3 itself — monotone in-path prune only)" under **NOT DP-optimizable**, which the same
  repository's own code contradicts.* C3 collapses to the bounded scalar **C3 = 16 + 8·G**
  (`lean/C3Decomposition.lean`, `c3_slot_decomposition`), and the running slot-gap sum G has range
  ±496 and is **orbit-invariant** — machine-checked as `runningG_orbit_invariant` in
  `lean/PruneGInvariance.lean` — so it rides the canonical-mask quotient exactly like `rid`. The
  instrument is built and shipped: `--f1-c3-hist --with-c5`. What actually blocks a C3 extremal is
  narrower and is an *instrument* boundary, not a mathematical one: **the KC f/g/t ladders carry no
  G channel**, and the full-31 run that does was priced and permanently declined on cost (§9).*)
  **NOT DP-optimizable (class c), honestly listed:**
  `--palindromes`, `--autocorrelation` (all lags), `--fft` magnitudes,
  `--windowed-entropy` (5¹⁵ state), `--recurrence` plots, positional maps of specific values,
  Davis GLB predicates. Constants-on-the-space (entropy of the wave histogram, path length,
  parity counts) are reported as TR-12 §11 material (theorem class), not extremals.
- **Caveats.** (1) The production DP is an ORBIT QUOTIENT: only G-invariant functionals ride it;
  non-invariant ones (yang-POSITION-, specific-trigram-, specific-hexagram-based) need the plain
  #215-path DP — full-31 plain is memory-infeasible in RAM; an OOC plain variant is a sizing exercise,
  deferred. **NB (2026-07-21 correction):** pure popcount / yang-COUNT is G48-invariant (G48 permutes
  line positions ⇒ preserves popcount — a consequence of the published order-48 group; see the §4
  triage-correction bullet) — count rows DO ride the quotient DP;
  only *positional* yang / specific-trigram rows are non-invariant. See the §4 triage-correction bullet.
  (2) Each extremal = a full-31 layered sweep carrying (extreme, backpointer) per state —
  Stage-F-shaped pass, ≈ $40–80 each ⇒ run a SHORTLIST only. (3) Edit-distance-to-KW extremal
  (nearest SUPER neighbor to KW) needs a ×32 matched-count state on the PLAIN DP (KW-indicators
  are not G-invariant) — sizing unknown. ⚠ **CLOSED 2026-09-06, not DEFERRED — corrected
  2026-09-22 (v1.8).** This clause read *"flagged DEFERRED; the 560T sample minimum stands as the
  interim bound"* while §9 already recorded the answer: the pair-slot Hamming floor is **2**, it is
  structural, and it is attained by a published witness, so the "interim bound" had equalled the
  answer all along. See §9, *Edit-distance-to-KW extremal*. No sweep should be spent on it.
🔴 **TWO OF THE FUNCTIONALS THIS ROW WOULD SWEEP ARE ALREADY CLOSED — do not spend a sweep on them
  (QSET-2 finding 1, 2026-09-06).** `--kc-extremal`'s registry carries exactly two `invariant/VARIES`
  functionals, `yangcount` and `entryyang`, and both extrema of both are **90 and 96**, over SUPER
  *and* over C15. The bound is two lines: of 31 free pairs, the 28 reversal pairs contribute a fixed
  84 because popcount is reversal-invariant, and the three free self-complement pairs
  `(12,51) (18,45) (30,33)` contribute 2 or 4 each — so the range is `[90, 96]`. **Both endpoints are
  attained by orderings this project published on 2026-07-24**: lines 22 and 50 of
  `reports/certificates/c3_positional_witnesses.txt` give `yangcount=96 entryyang=90` and
  `yangcount=90 entryyang=96`, each `verdict SUPER: IN` and `C15: IN`. ⚠ *Annotated in the
  certificate 2026-09-13 (V3B-03#11): the file carried the two orderings but no occurrence of
  "yang", so it held the objects and not the claim. Each of those two lines now states its own
  measured pair on the `G=`/`C3=` header immediately above it — the annotation sits on the header
  because the `SEQ=` line is parsed as exactly 64 integers by row `a0_q4b`.* A `$40–80` sweep of either
  would rediscover a published number. *(This closes the two REGISTRY functionals, not §Q5's proposed
  shortlist — yinyang excursion, markov self-transition, `--lines` imbalance are untouched.)*

- **Mechanism:** **TO-BUILD** `--kc-extremal FUNC DIR` (per-functional min/max sweep + witness
  reconstruction; separate subcommand, sha-neutral). **Shortlist PROPOSED — no formula pinned, not
  in the extremal registry** *(labelled 2026-09-12, V3B-03#12: these three were listed as a
  shortlist an operator could simply pick from, and none of them is buildable as written. The
  registry `--kc-extremal` actually dispatches — `KC_X_REG` in `solve.c`, cited by symbol because
  line numbers drift — holds exactly `dclass:1/2/3/4/6`, `linechanges`, `graycode`, `yangcount`,
  `entryyang` and the `posyang0` negative control. None of the three below is in it; `solve.py`
  defines no `yinyang` or `markov` functional and `documentation/SOLVE_PY_CLI.md` documents no such
  flag; and the registry's nearest entry, `linechanges`, is `invariant/C5-CONSTANT` — a forced
  constant with nothing to optimise, which is not the imbalance functional proposed here. **Each
  needs its formula — sequence scored, normalisation, objective — written down before it can be a
  pick; until then it is a proposal, not a shortlist.** Nothing shipped depends on this: Q5 is
  `SKIP:wave3-not-budgeted` and unbuildable at n = 31 regardless.)* (operator picks):
  max/min `--yinyang` cumulative-balance excursion; max/min `--markov` self-transition count;
  ⚠ ~~max KW-boundary-match count~~ **STRUCK 2026-09-05 (QSET finding 3,
  a circularity catch): the maximum is 31 and King Wen is the witness, BY CONSTRUCTION** — King Wen
  is a member of SUPER, so "how close does any solution get to King Wen's transition skeleton" is
  maximised at King Wen itself. It measures the labelling, not the space. The non-trivial form is
  already listed in this section as the edit-distance-to-KW extremal (nearest SUPER *neighbour*),
  which is **CLOSED at distance 2** (§9; corrected 2026-09-22 from "DEFERRED on sizing");
  min/max `--lines` imbalance. **Stage:** post-F (f layers suffice for forward sweeps).
  **Cost:** ≈ $40–80 per functional [ESTIMATED].
- **Output/verification:** extreme value + explicit witness walk + certificate; witness re-checked
  by evaluating the functional in `solve.py`/`roae.py` (two-language); DFS exhaustive extremal at
  n ≤ 13 as the small-scope gate before any full-31 sweep.

### Q6. Density extremes — crowded corridors, lonely starts
- **Definition (SUPER).** Per layer k and admissible transition class: the exact walk mass
  through each (state, choice) = f(s)·g(s∘c), G-expanded to raw pair identities (each canonical
  mask carries orbit(cm) raw masks; placed-pair identity maps through the orbit transversal).
  Report per layer: argmax/argmin-nonzero choices by mass; KW's own **anchor-class percentile**
  per layer — the statistic the code computes is D5-08 `anchor_class_pct`, which is not a
  "path percentile"; the older wording named a quantity nothing emits. **The formulae, stated here
  rather than left to the inventory** *(added 2026-09-12, V3B-03#13 — this site renamed the
  statistic in 2026-09-06 and never gave it):* with `m_k(d)` the layer-k mass in distance class `d`
  and `d_KW` the class of KW's own k-th transition,
  **`anchor_p = m_k(d_KW)/N`** and **`anchor_class_pct = Σ_{d : m_k(d) ≤ m_k(d_KW)} m_k(d) / N`**
  (ties included by the `≤`), per `documentation/QUERY_INVENTORY.md` §10.4.
- **Mechanism:** **TO-BUILD** `--kc-scan FDIR GDIR --kc-raw` — ONE streaming pass joining adjacent f- and
  g-layers, emitting: (i) per-layer per-choice mass table (this query), (ii) positional-marginal
  field (V1), (iii) layer mass-flow aggregates (V2), (iv) transition-grammar table (V5). One
  pass, four tables — amortized.
- **Stage:** post-F + post-G. **Cost:** ≈ $15–50 for the joined pass (disk-bound, 2 ladders).
- **Output/verification:** TSVs under `tr12/scan/`; internal gate: per-layer Σ orbit·f·g = N
  (the V3/`--kc-g-check` identity recomputed inside the scan); marginals row/column sums = N.

### Q7. Historical-arrangement membership certificates
- **Definition.** For each arrangement A: verdict ∈ {IN, OUT}; if OUT — first-violated constraint
  under the PINNED check order C1→C2→C3→C4→C5 (order stated in the certificate; violations of
  later constraints also listed); if IN — rank_O3^SUPER + C3 verdict.
- **Corpus + data (already in-repo):** Mawangdui (`roae.py mawangdui_kw_indices`, 2026-07-05
  Shaughnessy-corrected), Jing Fang (generator in `solve.c run_null_historical` /
  `solve.py _r7_jingfang`), Fuxi/Shao Yong (`fuxi_order`), plus TR-1/TR-2's SAT-constructed
  witnesses (`sat.py --witness moore-strict|grand-strict`) and TR-10's corpus controls (same
  three). **Known results to certify** (from `--null-historical` + tests.py): Fuxi OUT (C1; also
  C2, C3=2048); Mawangdui OUT (C1; C2 — exactly one d=5 seam at 24→25; C3=2048); Jing Fang OUT
  (C1; C2 holds; C3=2048); the SAT witnesses are IN C15 (grand-strict has C3=776) → they get
  ranks (post-O3) — the only non-KW named sequences in this report with serial numbers.
  **[D5-04 correction, 2026-09-05 (Fable): WITHDRAWN as a promise of this report. The battery
  (`scripts/tr12_repro.sh`) never invokes `sat.py`; the witnesses need `kissat`, which is absent
  (QUERY_INVENTORY §3.4), and a solver-chosen witness has no reproducibility contract until its bytes
  are pinned. The leg is a named skip `a0_q7_witnesses` / `TR12_Q7_WITNESSES=PENDING:kissat`,
  aggregated into `TR12_Q7`, so the parent reads SKIP, never PASS. What is no longer claimed: no
  non-KW named sequence receives a serial number in TR-12 as built. Also note (D5-14): an O3 rank is
  label-relative — rank_O3(KW) = 0 by construction — so even a landed witness rank would be a
  serial number in a KW-derived coordinate, not a rarity statement.]**
  **[CX-93 correction, 2026-09-25 (Fable): the withdrawal above is LIFTED for the witnesses'
  membership, and the row is real. The witness bytes are pinned —
  `reports/evidence/q7_witnesses/moore-strict.txt` and `grand-strict.txt`, produced once with
  kissat 4.0.4 (command, CNF and model sha256 in the README beside them) — and battery row
  `a0_q7_witnesses` / `TR12_Q7_WITNESSES` verifies the PINNED sequences with no solver on PATH:
  `--check-arrangement` says IN SUPER and IN C15 (C3 = 776), the sequence is not KW (6 of 64
  positions differ; pair-slot layout differs), and every rule the target enforces re-scores 0
  through `solve.py` (Schulz gender also by `verify.py`). Both pinned files carry the SAME
  sequence — every production chain returned this one ordering, and a grand-strict witness is a
  moore-strict witness by definition; it is recorded as produced, not curated into two. The
  certificate `q7_<target>.json` feeds `a2_q7_ranks`, so at n = 31 the witness receives its
  `rank_O3` — the serial number this section promised — and D5-14's caveat stands: that rank is a
  coordinate in the KW-derived O3 order, not a rarity statement. What is still NOT claimed: that a
  solver would return these bytes (the opt-in `--q7-resolve` row asserts SAT status and re-verifies
  whatever comes back, never byte-equality), and no rank has been computed yet — the n = 31 run
  of 2026-09-22 predates this row. Gate: `scripts/d5_04_q7_witnesses_gate.sh` (red on a planted
  C1 break, on an IN-C15 sequence breaking one enforced rule, on King Wen submitted as the witness,
  on a missing and on a malformed file; green on the pinned files; output byte-identical with and
  without a solver on PATH).]**
- **The three arrangements, printed** *(added 2026-09-12, V3B-03#14 — this section named them by
  code identifier only, so a reader could not check a verdict without running the repository).*
  `H = {0..63}` as 6-bit integers (`documentation/SPECIFICATION.md` §H); each array below is a
  permutation of 0..63 and reproduces with
  `python3 -c 'import solve;print(",".join(map(str,solve._r7_mawangdui())))'` (and the `_r7_fuxi` /
  `_r7_jingfang` twins):
  ```
  _r7_mawangdui:
  63,56,60,59,58,61,57,62,36,39,32,35,34,37,33,38,18,23,16,20,19,21,17,22,9,15,8,12,11,10,13,14,
  0,7,4,3,2,5,1,6,27,31,24,28,26,29,25,30,45,47,40,44,43,42,41,46,54,55,48,52,51,50,53,49
  _r7_fuxi:       0,1,2,…,63 (the identity on H)
  _r7_jingfang:
  63,62,60,56,48,32,40,47,9,8,10,14,6,22,30,25,18,19,17,21,29,13,5,2,36,37,39,35,43,59,51,52,
  0,1,3,7,15,31,23,16,54,55,53,49,57,41,33,38,45,44,46,42,34,50,58,61,27,26,24,28,20,4,12,11
  ```
- **Mechanism:** **TO-BUILD** `--check-arrangement "h0,h1,...,h63"` (capability CAP-2's wrapper):
  raw-sequence adapter → the five existing predicates (`verify.py` check block; `solve.py`
  C1/C2/C3 helpers; C4/C5 point-checks trivial) → first-violation report; if valid → walk
  adapter → `--kc-member` + rank. Membership additionally **walker-verified** (DFS run-to-witness
  at the arrangement's cell) — the DFS cross-check this item gets.
- **Stage:** verdicts + certificates NOW-able (predicates exist; wrapper is small); ranks
  post-G+O3. **Cost:** ≈ $0–5.
- **Output/verification:** per-arrangement certificate file; skeptic re-derives from the
  published arrays + any constraint checker (rung 2).

### Q8. Random exemplar gallery
- **Definition.** k = 1,000 exact-uniform SUPER samples (seed pinned: `TR12-GALLERY-1`,
  documented; reproducible byte-identically) + the C3-rejection subset (≈ 1/8.26 acceptance ⇒
  ~121 expected C15 exemplars — ⚠ see the gallery-size correction in the inventory); each sample:
  walk, record (`--kc-record`), REL rank, ⚠ **O3 rank and functional profile are DESCOPED
  2026-09-06 (QSET-2 finding 6): no commanded path produces either.** The battery delivers REL rank,
  `cd`, walk and record only, and `--kc-o3-rank` exists, so "post-O3" is a stage label whose stage
  has passed — the legs are simply uncommanded, exactly as Q1c's were and now disclosed the same way.
  Retained for the record: O3 rank
  (post-O3), cd\*/C3 value + verdict, functional profile (solve.py batch), `#provenance`.
- **Mechanism:** `--kc-sample DIR 1000 <seed> --kc-record` (EXISTS, post-F); chi-square
  uniformity gate on rank buckets (the `--kc-midn` gate pattern at full-31).
  **The gate is fully specified in public, and this section carried none of it** *(cross-referenced
  2026-09-12, V3B-03#15 — TR-12 named a string seed and a "chi-square uniformity gate" while every
  number lived elsewhere: `documentation/VERIFY.md`, `documentation/QUERY_INVENTORY.md` §0.4(1) and
  the battery driver).* **Seed** = `TR12_SEED` = **9276183659154465378** =
  `int(sha256("TR12-GALLERY-1")[:16],16)`; **K** = `TR12_Q8_K` = **1000** draws, plus a second
  gallery of 1,000 C15 draws (not a ~121 subset). **Gate:** χ² over 16 rank buckets
  `⌊16·rank/N⌋`, 15 dof, computed in integer arithmetic as `χ² = (16·S − k²)/k`, **PASS below
  37.70**; the anchor run of 2026-08-07 gives buckets
  `[71,55,64,59,75,58,53,74,51,49,64,60,58,81,60,68]` and **χ² = 20.224** on its 1,000 draws.
- **Stage:** post-F. **Cost:** ≈ $5–15. **Output:** `<artifact-root>/gallery/` + seed + chi² line.
- **Cross-check:** membership of every sample via `--kc-member` + constraint re-validation in
  Python (two-language); the gallery is the "typical member" baseline for TR-12.

### Q9. The reportable negatives — what CANNOT distinguish any solution
- **No compute.** Certified restatements with scopes: TR-5 free action (C1–C5; no solution has a
  nontrivial symmetry; every solution has exactly 23 record-twins) — so symmetry can never
  distinguish; TR-6 exactly 15 parity alternations + 30 switches (Lean kernel-checked at C1+C5
  generality; SAT ≤14/≥16 UNSAT under C1+C2+C4+C5); TR-7 odd wrap distance (C4+C5, Lean
  `wrap_parity_general`), 16 circular alternations, 32 switches (C1+C4+C5). Also the
  forced-class literature rows (§4-LS): 8 scoreboard rules with empirical mass 1.0 — candidates
  for PROOF upgrade (LS-1), which would move them into this section's theorem class.
- **Stage:** NOW. **Cost:** $0. **Verification:** the three TRs' own guides (rungs 1–2).
  ⚠ *(2026-09-21: two further measured negatives from the n=31 atlas join this section — the
  one-step transition kernel scores King Wen 0.10 bits below the population mean over 31 steps,
  and the positional pair field is flat to ~3 % with King Wen's placements typical of it — §12.4
  and §12.5, each with its reproduction command.)*

---

## 2. Visualization program (V1–V5)

House convention: each figure gets a `viz/viz_kc_*.md` doc (definition, generation command,
how-to-read) + generation code in `viz/` (the single-file rule's exception dir — extend
`report_figures.py`/`visualize.py`, no new top-level .py elsewhere); rendered figures committed
per-run under `runs/<run-id>/viz/` and mirrored to `reports/figures/fig_tr12_*.{png,svg}` per the
TR pattern; TR-12 links the viz docs and embeds from `reports/figures/`. Every caption carries
the space label. What these show: **population-exact fields computed over ALL ~1.1×10³⁹
members via f·g** — population quantities, not a projection of an enumerated sample slice.

| # | Figure | Exact definition (SUPER unless noted) | Data source | Stage | Script sketch |
|---|---|---|---|---|---|
| V1 | `viz_kc_field.md` — positional-marginal field | P(pair j placed at slot k) = Σ_transitions orbit·f·g·[σ(pair)=j] / N; 32×31 heat matrix; KW's placements overlaid as marks. **Conventions the figure is read against** (`viz/viz_kc_field.md`): row `pair = 0` is **identically zero** (C4 pins pair 0 at slot 1, before layer 0 exists) and is kept so the row index reads as the pair index; `P` is **doubly stochastic** — every column sums to 1, and every non-pinned row sums to 1. All three are reader-side checks on the TSV | `--kc-scan` table (ii) | F+G+scan | matplotlib imshow from TSV; KW overlay from kw walk |
| V2 | `viz_kc_river.md` — mass river | Layer-k mass split **by distance class of the k-th transition** (`atlas.layers[k].by_class{d1,d2,d3,d4,d6}`) — the **reduced form**, and the only one the atlas schema carries: a split by top-level branch class is **not** available, because `branch_atlas[]` holds per-branch totals, not per-layer-per-branch mass (`documentation/QUERY_INVENTORY.md` §3.1). Sankey/stacked flow across k=1..31; KW's path drawn as a line | scan table (iii) | F+G+scan | stacked-area/Sankey from TSV |
| V3 | `viz_kc_spectrum.md` — rank spectrum | For ranks r on a systematic grid (r = i·⌊N/K⌋, K=10³–10⁴): walk-decomposable functional values of unrank(r) vs r — property drift across the index | `--kc-unrank` grid + solve.py evals | F (REL grid); G+O3 for the citable-order axis | shell loop + solve.py batch + scatter/line |
| V4 | `viz_kc_shells.md` — KW's neighborhood shells | g(KW-prefix_k) vs k, log-scale (completions remaining after each KW choice) = Q3's rarity profile as a figure; optional band: min/max g over alternatives per step | Q3 output | G | semilog line from q3 TSV |
| V5 | `viz_kc_grammar.md` — transition grammar | P(next-choice class \| layer k) exact, choice class = **(d, w)**: boundary distance class d∈{1,2,3,4,6} × **new-pair category, pinned 2026-09-23 as w = popcount(entry XOR exit) ∈ {2,4,6}**, the within-pair distance of the newly placed pair; heatmap over k; KW's actual choices marked. ⚠ *Updated 2026-09-24: this cell read "choice classes: **distance class d∈{1,2,3,4,6} only**" and "`documentation/QUERY_INVENTORY.md` §3.1 rules V5 the distance-class form only". "New-pair category" was never defined in this section; it was pinned by operator ruling as `w`, and the `(d, w)` cross-tab is derived consumer-side from the persisted kernel (`TR12_V5=PASS`, figure below). The history that follows is kept.* ⚠ *The "× new-pair category" second dimension was promised here until 2026-09-12 (V3B-03#13); `documentation/QUERY_INVENTORY.md` §3.1 rules V5 the distance-class form only.* ⚠ *Corrected 2026-09-12 (Codex KCP5 #4, Opus disposition): this read "**is absent from the atlas schema**", and that overstates the limitation in the one direction that costs money. With `--kc-raw` the atlas persists every nonzero raw kernel cell `m<a>_<b>` (`solve.c:28002`), and both `d = popcount(a ^ b)` and the new pair's identity through entry `b` are recoverable from the key — so the joint is **derivable from saved data, without a second n=31 pass**. What is actually missing is the category DEFINITION (`viz/viz_kc_grammar.md:61-62`), a consumer-side decision. "Absent from the schema" would have implied re-scanning to obtain it; that is not the situation.* | scan table (iv) | F+G+scan | heatmap from TSV |

Costs: data extraction rides §Q6's scan pass (V1/V2/V5) and Q3 (V4); V3's grid ≈ $5–20
(K unranks). Rendering ≈ $0 (local). Verification: every figure's TSV is committed as evidence;
row/column sums = N gates printed by the scan.

### Figures — all five (V1, V2, V5 from the n=31 atlas; V4 from King Wen's profile; V3 from the rank grid; rendered 2026-09-23; V2, V3 and V5 re-rendered 2026-09-24)

**All five are rendered below.** ⚠ *Updated 2026-09-24: this read "Three of the five are rendered
below. V3 and V4 are not", which stopped being true on 2026-09-23 — both are embedded further down,
and the paragraphs after V4 record why each was wrongly reported blocked.* V1, V2 and V5 are
computed over the *whole* superspace — every one of the ~1.097×10³⁹ members at once, via f·g — not
over an enumerated sample slice; V4 is **one walk** (King Wen's), and V3 is a 1000-point **lattice**
on the index, not a sample of the space. Each is generated by
[`viz/report_figures.py`](../viz/report_figures.py) from the TSV whose content digest is printed in
the figure's own lower-right corner.

![Heat matrix of the exact positional-marginal field over the C1C2C4C5 superspace: 32 global pair-index rows against pair-slots 2 to 32, every interior cell between 0.0297 and 0.0345 against a uniform 1/31 = 0.0323, with the two end slots ranging 0.0205–0.0636, with King Wen's own 31 placements outlined in blue along the diagonal, an identically zero row 0 (C4 pins pair 0 at slot 1), three zero cells in the slot-2 column (pairs 4, 6 and 21, the popcount-5 pairs C2 forbids at distance 5 from exit 0), and a slot-32 column in which only 16 of the 32 pairs are admissible. A legend below the axes identifies the blue outline as King Wen's own placement, one cell per slot.](figures/fig_tr12_kc_field.png)

*V1, the positional-marginal field (§12.5's object). P(pair j at slot k), exact over SUPER; the
field is doubly stochastic by gate — every column sums to 1, and so does every non-pinned row. **The
reading is negative:** the interior is flat to about 3 % (`POSITIONAL_TV_FROM_UNIFORM_MAX_INTERIOR=0.0329`)
and King Wen's own pair at its own slot carries 0.0299–0.0337 at every interior slot — indistinguishable
from any other pair. King Wen's outlined cells run down the diagonal **by construction**, because the
pair indices are King Wen's own labels: the value in each cell, not the shape of the outline, is the
content. The structure that *is* visible is forced — row 0 zero by C4, the three slot-2 zeros by C2,
the 16 admissible closers by the wrap predicate (§12.1). Flat marginals do not test the **joint**
placement pattern, which is not asked here. [SVG](figures/fig_tr12_kc_field.svg).*

![Two-panel figure. Upper panel: a stacked mass river across layers 0 to 30 showing the exact share of the superspace in each boundary-distance class d = 1, 2, 3, 4 and 6, the bands nearly parallel across the whole walk with d = 3 the widest at about 0.41, and King Wen's own class at each layer drawn as a white step line. Lower panel: a bar chart of the 56 top-level branches sorted by solution mass, each between about 0.010 and 0.021 of N in seven levels, with log10 exhaustion cost in t-units overlaid as a red line that steps down with the bars from about 38.27 to 37.94, never rising where the bars fall.](figures/fig_tr12_kc_river.png)

*V2, the mass river, and the branch panel. **Upper:** exact per-layer mass by boundary-distance
class. The band **areas** are fixed by the C1+C5 theorem — each class d is spent exactly b0(d) times
by every walk, so the column sums recover the budget `2,8,13,7,1` (§12.1) — and therefore only the
**shape across k** carries information; it is nearly flat, the per-layer class shares staying within
0.18 percentage points of b0/31 on layers 1–29 (§12.6). **Lower:** each top-level branch's exact
solution mass against its exact exhaustion cost in t-units. **Measured, the two track each other
exactly in rank:** the 56 branches fall into 7 mass levels (0.0102–0.0212 of N) that map one-to-one
onto 7 cost levels (log₁₀ 37.94–38.27 t-units), and **0 of the 1,540 branch pairs** has the smaller
mass with the larger cost; cost per solution spans only 7.65–8.20 t-units. So **no branch is
small-but-expensive** at n=31 — the case this panel used to be captioned as showing does not occur. ⚠
*Corrected 2026-09-24 (CX-75): this read "the atlas's point being that mass and cost do not track each other,
so a small branch need not be a cheap one", and the panel's own subtitle read "a small-but-expensive
branch is the atlas's point"; both described a possibility as if it were the drawn result, over a
table that contradicts it (recount: `tr12/scan/v2_branches.tsv`, columns `solutions` and
`prefixes_t_units`).* The EXHAUSTIBLE/INFEASIBLE
verdict is **not** drawn from this panel and remains withheld (§3). ⚠ **This is the REDUCED form**
(`TR12_V2=PASS:REDUCED-NO-BRANCH-CLASS-RIVER`): the river is split by distance class, **not** by
top-level branch class as §2's table originally specified. The branch-class split is not a missing
flag — the compiled DP state carries no tag for which branch a prefix descended from, so it would
need a branch-tagged forward ladder of order 10² TB ([`viz/viz_kc_river.md`](../viz/viz_kc_river.md)).
[SVG](figures/fig_tr12_kc_river.svg).*

![Heat map of the exact transition grammar: fifteen rows, one per pair of boundary-distance class d = 1, 2, 3, 4, 6 and within-pair distance w = 2, 4, 6, against layers 0 to 30, each column summing to 1. The two d = 3 rows with w = 2 and w = 4 are the brightest at about 0.15 to 0.17 across the interior layers 1 to 29, the d = 1 and d = 6 rows are dark, the d = 6, w = 6 row is zero at every layer, and the first and last columns differ visibly from the near-constant interior. King Wen's own (d, w) cell at each layer is marked by a white outline, one per column. A legend below the axes, set on a dark patch so the white key is visible against the page, identifies that outline as King Wen's own (d, w) cell at this layer.](figures/fig_tr12_kc_grammar.png)

*V5, the transition grammar. P(d, w | layer k), exact over SUPER, read down each column. Summed
over w, d = 3 is the largest class at every layer (`LARGEST_CLASS_SET_OVER_LAYERS=d3`,
`D3_MIN_LAYER_SHARE=0.40687`), and d = 6 is zero at layer 0 only — the complement of the anchor exit
is already placed (§12.1). 🔴 **THE SECOND AXIS IS BUILT, AND V5 IS NO LONGER A RE-PLOT OF V2 (2026-09-23)**. What it adds is
the per-layer `P(w|k)` marginal (see below). Through v1.11
this caption read *"This is the REDUCED form (`TR12_V5=PASS:REDUCED-NO-CROSSTAB`)… With only the
distance-class axis available, **V5 and V2's upper panel plot the same numbers**"* — true then,
false now. The axis was **pinned** rather than discovered: §2 specified "distance class × new-pair
category" and never defined the second term, so the category was an operator ruling, taken on the
candidate [`viz/viz_kc_grammar.md`](../viz/viz_kc_grammar.md) names as the only free, exact and safe
one — `w = popcount(entry XOR exit) ∈ {2,4,6}`, the within-pair distance, whose multiset over the 32
pairs is fixed by C1. **No new data was needed:** the `(d,w)` cross-tab is derived consumer-side from
`layers[k].kernel`, which already ships inside the published atlas. No re-scan, no ladder read, no
VM. The table goes from 155 rows to **465** (31 layers × 5 distance classes × 3 within-pair values,
zero cells included), and `TR12_V5` now reads **`PASS`**.

**What V5 adds over V2 is the per-layer `P(w|k)` marginal, not a measured dependence.** On layers
1–30 the joint `P(d,w|k)` is within **0.0097** of `P(d|k)·P(w|k)` (maximum at k=1, d=3, w=4;
`V5_FACTORISATION_MAX_DEV_K_GE_1=0.0097`), so the cross-tab is reconstructible from its two marginals
to within 1 %. The all-layer maximum **0.173** (`V5_FACTORISATION_MAX_DEV_ALL=0.1732`) is a layer-0
artefact: C4 pins the exit to hexagram 0, so only 7 of the 15 `(d,w)` cells are admissible
(`V5_K0_ADMISSIBLE_DW_CELLS=7,15`), and 0.173 is the product of the marginals at a cell whose joint is
identically zero (`V5_K0_MAX_DEV_CELL_JOINT_AND_PRODUCT=0.0000,0.1732`). All four tokens are printed by
`python3 solve.py --atlas-probe runs/20260906_kc_ladders_n31/atlas_n31.json`. Nonzero cells go from 154 to **422**, and King Wen's overlay — which on `(d,w)` the old table could not draw at all —
now marks exactly one cell per layer. ⚠ **The resolution claim must not be overstated:** `w` is
constant on each of the seven pair-orbits and takes only **three** distinct values across them, so a
row is a statement about **3 orbit-classes, never about an individual pair**, and it does not even
separate the seven orbits. The identities were checked rather than trusted — every column sums to 1
in exact rationals, `Σ_w G[k][d][w] == by_class[d]` at all 155 `(k,d)`, the per-`w` column totals
come out {2:12, 4:12, 6:7} exactly as C1 forces once the C4-pinned anchor pair is excluded, and a
fault-injection control that moves mass *inside* one `(k,d)` — preserving every marginal — is caught
only by the `(d,w)` recount. [SVG](figures/fig_tr12_kc_grammar.svg).*

![Two-panel figure of King Wen's own trajectory. Upper panel: log10 of g(prefix), the exact number of completions remaining after each of King Wen's 31 free placements, falling in steps from about 37.2 to 0, each step annotated with the number of admissible alternatives at that point, running from 56 down through 3, 1 and 2. Lower panel: the surprise spectrum, bars of minus log2 p_i in bits per step, from about 6.3 bits down to zero, the bars summing to log2 N; the step offering a single admissible alternative has a bar of height zero.](figures/fig_tr12_kc_shells.png)

*V4, King Wen's neighbourhood shells — Q3's rarity profile drawn as a figure. **Upper:** the exact
completions remaining after each placement, `g(prefix)`, on a log axis, annotated with the number of
admissible alternatives. **Lower:** the surprise spectrum, the per-step `−log₂ p_i` whose bars sum to
`log₂ N` (EW-1). Unlike V1, V2 and V5 this figure plots **one walk, not a population** — every point
is King Wen's own, and the title says so, because a reader arriving from the three population
figures would otherwise read an overlay that is not there. Two checks are visible in the figure
itself: `g` reaches exactly 1 at the last placement, and the step with a single admissible
alternative costs **0 bits**. [SVG](figures/fig_tr12_kc_shells.svg).*

🔴 **V4 WAS NOT BLOCKED ON THE LADDERS, AND THIS PARAGRAPH SAID IT WAS.** Through v1.11 this read
*"V3 and V4 are not rendered, and no full-31 version of either exists. Both need a read of the f/g
ladders, which are cold and unmounted."* **That was false for V4.** Its input was produced by the
full-31 run of 2026-09-22 *while the ladders were mounted* — the receipt records
`TR12_V4_TSV=PASS` ([`evidence/tr12/`](evidence/tr12/)) — and the figure failed to appear for one
reason, recorded in the same receipt: `TR12_VIZ=SKIP:matplotlib-absent`. matplotlib and numpy are
not project dependencies and were not installed on the query host, which was then torn down. The
profile was banked, is committed here as `tr12/q3_profile_kw.tsv`, and renders in seconds on any
machine with those two packages — **no ladder, no VM**. The error is worth naming rather than
quietly fixing: a *rendering* gap was published as a *data* gap, which told a reader the figure
would cost 15 TB of rehydration when it cost nothing.

![Seven scatter panels of observable values against normalised rank from 0 to 1 in REL order, each one showing no trend across the index; five are broad bands, and two are nearly constant, one of them zero at almost every point and the other taking only the values 2 and 3. Three panels carry a dashed red King Wen reference line; four deliberately carry none because those observables measure similarity to King Wen.](figures/fig_tr12_kc_spectrum.png)

*V3, the rank spectrum — **and the reading is negative, which is the point**. 1000 grid points on the
REL rank axis, each evaluated on the frozen `--compute-stats` battery. **No drawn observable tracks
the index:** the correlation with x is at most 0.073 in absolute value on all seven (largest
`fft_dominant_freq`, r = −0.0724), and no panel's ten decile means show a trend. So **the rank index is
not a structural coordinate** for these observables, and a reader cannot treat position in the
enumerated order as carrying information about the ordering. Two panels are flat for a different
reason and say nothing about the index: `c6_c7_count` is 0 at 995 of 1000 points, and
`first_position_deviation` takes only the values 2 and 3 (955 and 45 points). Their flatness is a
property of SUPER, not of the order (`viz_kc_spectrum.md` rule 1). The index does have structure of
its own: along x the grid's walks fall into **32 contiguous runs by their final hexagram** (the block
structure `viz_kc_spectrum.md` §"How to read it" describes), and none of the seven observables follows it. ⚠ *(corrected
2026-09-24: this read "Every panel is a flat, high-variance band … for any battery observable", which
overstated the two near-constant panels and generalised past the seven observables drawn.
Recompute from `tr12/v3_spectrum.tsv`.)*
Two constant observables are dropped and named in the subtitle rather than drawn as flat lines
(`viz_kc_spectrum.md` rule 1). ⚠ **Three of seven panels carry King Wen's reference line, not
seven.** `edit_dist_kw`, `first_position_deviation`, `shift_conformant_count` and `c6_c7_count` are
suppressed as **KW-anchored**: each measures similarity to King Wen — `kw_exp` is literally
`arange(32)` — so King Wen necessarily takes the extreme value, and drawing it would make an
arithmetic certainty look like a discovery. `documentation/DISTRIBUTIONAL_ANALYSIS.md`'s adversarial
circularity audit of 2026-07-26 names exactly these four and **withdrew a published joint-KDE
headline** over the same inference. `c3_total` keeps its line: that audit's reason for it — a
C3 ≤ 776 population filter — does not apply to this unfiltered SUPER grid, where King Wen's 776 sits
inside an observed 464–1576 span. Evidence: `tr12/v3_spectrum.tsv`.
[SVG](figures/fig_tr12_kc_spectrum.svg).*

🔴 **V3 WAS REPORTED BLOCKED ON AN INSTRUMENT THAT WAS NOT THE BLOCKER EITHER.** Through v1.11 this
paragraph said the join "would yield `spectrum/v3_spectrum.tsv`… Neither the battery driver nor the
atlas consumer emits it", and `viz/viz_kc_spectrum.md` said of the unrankers and the battery that
"**nothing joins them**". The grid had been produced all along (`tr12/v3_rel_grid.tsv`, 1000 points,
31.4 min measured) and the battery had existed all along; what was absent was a forty-line join,
written on 2026-09-23 as `solve.py --v3-spectrum`. It needs **no ladder, no VM and no new figure
code** — the renderer had been waiting for its input since it was written. ⚠ The *proposed*
convenience flag `--kc-unrank-grid` still does not exist and is NOT what unblocked this: the grid
came from the `--kc-unrank` K-loop the battery already ran. **The five-figure program of this section
is now delivered in full.**

---

## 3. The Exhaustion Atlas (XA) — headline TR-12 section

**Definition.** For every top-level branch b (first free placement; generalizable to any
cell/prefix): (a) **solutions(b)** = Σ_{first choices c ∈ b} g(s_0∘c) — exact, SUPER;
(b) **prefixes(b)** = the number of valid prefixes extending b = the DFS's pruned search-tree
size = its exhaustion node cost — via the **t-ladder**: t(s) = 1 + Σ_c t(s∘c), t(final)=1 — a
Stage-G-shaped backward DP with the +1 node channel (`--kc-t-build`, same skeleton as
`--kc-g-build`; Stage T is **standalone** — it reads FDIR, not GDIR, so it carries no scheduling
dependency on Stage G, and `--kc-tdir` is an *optional* argument to `--kc-scan`); (c) **exhaustion wall/$** at measured orbit-engine throughput, hedged ×2 for
scale — the throughput anchor is the atlas run's own measurement, published with it. **The
pilot *artifacts* are not public, and re-deriving them would take a fresh paired benchmark that is
not authorised — but the two anchors themselves are already published** and are quoted here rather
than withheld: the R-1 orbit-engine work factor **36.14×** and wall ratio **19.8×** at 1 T are
committed in the battery driver as the stated reason its **`c_xa_cd`** row skips
(`SKIP:xa-throughput-anchors`) — cited by row name rather than by line number, because the line
moved (this read `scripts/tr12_repro.sh` line 1401 until 2026-09-12, V3A-044#6, and a later revision
replaced that with another line number, which had moved again by 2026-09-23 — no line number is
quoted here for that reason); read them with
`git grep -n "xa-throughput-anchors" main -- scripts/tr12_repro.sh`. What has **no** public
basis, and is therefore still not quoted, is the nodes/sec rate itself; (d) **verdict**: EXHAUSTIBLE (fits a stated $ ceiling) vs
INFEASIBLE. ⚠ **This call is WITHHELD and the consumer now refuses to make it.** Pricing t-units as
production-DFS nodes assumes a t-unit → `SOLVE_NODE_LIMIT` map that **nothing certifies** —
`--kc-t-cert` says so in its own JSON (`solve_node_limit_mapping: NOT CLAIMED HERE`). `solve.py`
emits `TR12_XA_CD=PENDING:W0-D-node-mapping` unless a **usable W0-D certificate** is supplied with
`--xa-node-mapping-cert`: a fixed JSON schema whose `mapping.nodes_per_t_unit` factor (an exact
`"p/q"`) multiplies every priced row and whose `mapping.kind` (exact / upper-bound / lower-bound)
limits the call — a bound can never print the call its direction cannot support, and its token is
`TR12_XA_CD=ONE-SIDED:<kind>`, never `PASS`. Anything else, including a path that merely exists or
the `--kc-t-cert` output, is refused with a reason. ⚠ *(Corrected 2026-09-25, Q-772. This read
"unless `--xa-node-mapping-cert` is supplied", which was true of the consumer it described: any
supplied certificate that carried a permission sentence was accepted, and nothing it said reached the
arithmetic. The consumer now loads and USES the certificate; see `documentation/SOLVE_PY_CLI.md`
`--xa-node-mapping-cert`.)* "Exact
shortfall factor" is withdrawn: it would relabel a t-unit count as a node count.

**Deliverables.** (i) argmin branch + the exhaustibility call; if ANY branch is genuinely
exhaustible → spec the **provably-exhausted-region certificate**: DFS walks the branch to
completion; ASSERT walked-prefix-count == t-derived prefix count (⚠ **this equality IS the uncertified
mapping**, not a consequence of it) AND emitted records byte-match
the compiler's branch emission (O3/REL-sorted, dedup'd) — cross-engine set equality EXECUTED at a
real scope (H2 ladder layer (i)); flagship-grade if it exists. Prior evidence says temper
expectations: an early single-cell probe of the smallest branch returned a node count large enough
that every branch was expected to be INFEASIBLE. **That probe's run no longer exists, it has no
public counterpart, and its number is not quoted here.** The published evidence pointing the same
way is the Campaign A Pass 1 record cited under (ii) below. The atlas answers the question exactly either way, which is the
point of building it. (ii) Retroactive exactness
upgrade of the standing "single-branch exhaustion is infeasible" estimate. **The standing
estimate's shortfall factor is not quoted ahead of the t-ladder that computes it exactly** —
publishing an unsourced factor beside a promise of the exact one is strictly worse than
publishing neither. **The standing estimate's public anchor is a run, not a note:**
`documentation/HISTORY.md` §"April 22, 2026 — Campaign A Pass 1 (10T × 2 yield-16 laggards):
single-branch exhaustion ruled out" records the measurement and its verdict — both depth-3
laggard branches BUDGETED (not EXHAUSTED) at a 10 T node budget, 16,431,733 and 16,433,267
canonical solutions, with the per-branch sha256 — and concludes that "single-branch exhaustion
via budget-ladder is **infeasible** for the yield-16-at-100T class." The artifacts are in the
public tree at `runs/20260422_passA_10T_d64_laggard/`
(README, per-branch `.meta.json`, `.sha256`, checkpoint, gzipped log). The roadmap framing is
`documentation/BRANCHES_EXPLAINED.md` Part 15 §"Single-branch exhaustion". Internal planning
notes on the same question are superseded by the atlas and are not cited here; **the exact
shortfall factor is not quoted from any of them.** (iii)
**MANDATORY accounting-convention pin — PARTLY LANDED, and its remaining half CANNOT run at HEAD:**
what `--kc-t-cert` certifies today is **t vs an independent brute DFS** (n=9 exhaustive, n=13 spot);
it explicitly does **not** claim the `SOLVE_NODE_LIMIT` mapping. Completing it (W0-D) needs the
production enumerator to run at reduced n, which it cannot: `init_pairs()` fixes all 32 KW pairs
unconditionally (`solve.c:1708–1714`) and `--f1-pairs` reaches only the f1c5/c3/kc paths. So W0-D's
cost is **~$1 of compute PLUS an unbudgeted change to the production enumerator** — an operator
gate, not a $1 line item. ⚠ And even after W0-D the verdict stays **one-sided** — but in the
**other direction** from the one this paragraph gave. t-units bound production nodes from **below**:
the production DFS (`backtrack` / `backtrack_iterative` in `solve.c`) applies C3 only as a filter at
the full-walk leaf, never as a prune, and checks C5 against one combined budget over all 63
transitions, which is weaker than the t-ladder's boundary cap; so every t-unit prefix is a
production node and production visits more (dead prefixes that overdraw a boundary class). A
t-derived price is therefore a floor: INFEASIBLE is sound, EXHAUSTIBLE is not. `python3 solve.py
--xa-w0d-lb-cert OUT.json` produces the full-31 **lower-bound** certificate from that argument plus an
exact trunk enumeration (`reports/evidence/w0d_lower_bound/`); whether a one-sided call may be
published is an operator decision, and this section still makes none. ⚠ *(Corrected 2026-09-25. This
read "the production DFS prunes with C3 while t counts SUPER prefixes, so the ratio is per-branch,
and t-units bound production nodes from above — EXHAUSTIBLE would be sound, INFEASIBLE would not".
The C3 premise is false of the code and the direction is reversed; an upper-bound certificate built
on it would have made EXHAUSTIBLE rows unsound.)* Original wording: "valid prefixes" (t-units) vs
`solve.c`'s `SOLVE_NODE_LIMIT` node-counter semantics — at n ≤ 13, exhaust with the DFS
(node counter on) AND compute t; assert the exact mapping (incl. orientation-explicitness, d3
cell-splitting, and C3-prune visit accounting); no atlas number **priced in production-DFS nodes**
ships before this certificate — the t-unit ratios of §12.2 carry no such price, which is why they
ship and the exhaustibility verdict does not. **W0-D was not run** (the host is torn down) and the
certificate does not exist; the ≈ $1 is the 2026-07-17 estimate. The battery emits it as
`xa_node_convention.json`, not the `.txt` this 2026-07-17 line names.

**Stage:** convention pin NOW; (a) post-G; (b) post-t-ladder; (c)/(d) then. **Cost:** t-ladder
≈ $60–110 if standalone [ESTIMATED]; atlas assembly: see §R — **measured ~47 h single-threaded** on
the n=31 ladders (v1.4); the earlier dollar figure is withdrawn there and is not restated here.
**Verification:** t vs DFS at n ≤ 13
(the pin); Σ_b solutions(b) = N; Σ_b prefixes(b) + shared trunk = t(root).
⚠ *(2026-09-21: one exact t-unit figure the atlas now supplies — 68.67 % of the pruned-DFS tree
is doomed prefixes, none before layer 9 — is in §12.2. It is a ratio of t-units and says nothing
about production-DFS nodes, so the withheld exhaustibility call above is unaffected.)*

---

## 4. Literature-claims exactness sweep (LS) — flagship CAP-1 application

**(a) Triage.** The measured corpus is ~70+ literature-anchored functionals (hub:
`documentation/LITERATURE_RULES_POPULATION_TESTS.md`; TR-1 scoreboard + 31-rule batch +
orientation fiber; TR-2 N_gs; TR-10 Davis; review-C synthesis). Structural classes map to DP
feasibility as follows (full per-rule table lives in the research annex of this program's
execution ticket; classes verified against `solve.py` definitions):
- **WALK-DECOMPOSABLE (exact count feasible now-shaped):** ADJ (adjacent-transition: Moore
  rhythm-class, mmt3/6, wrap-distance classes, par_switch, dist_autocorr lag-1), POS
  (slot-indexed placement predicates: Moore 2005 parity, Cook anchors, p2c3–p2c6, d4, d7, m2),
  PAIR (order-free pair-content rows — several are the forced 1.0s), WIN with small windows.
  DP must track: per-step indicator sums / violation counters (bounded), i.e. a small product
  channel on the (mask, last, rid) state.
- **DECOMPOSABLE-WITH-EXTENDED-STATE (feasible at cost):** ST-POS/ST-ADJ station rules (Schulz
  gender ×11,364, rs1/rs2, ccn2/3/4/7/8, c2011n2) — need the 36-station first-appearance
  counter (+ violation counter ≤3); sizing per rule BEFORE launch (the FH-1 no-lumping lesson:
  do NOT assume state collapses; measure at reduced n first). Cost per exact count: a full-31
  extended-state DP run ≈ $40–105 each [ESTIMATED, sizing-gated].
- **NOT-DECOMPOSABLE (stays sampled/estimated — honesty row):** GLB items — Davis
  termruns/palnbr/tquartet, f4p housedisp/value_trend, rs1's global-min clause,
  c2011n4's uniqueness scan, full autocorrelation/FFT families. These keep their K20/K2
  estimates with CIs; no exactness is promised.
- **Triage correction (2026-07-21 exactness pass; the pass's script is not in the public tree —
  see the note at the end of this bullet).**
  Three items were filed too conservatively; two move into the cheap-exact tier:
  - **f4p_comp_adj is ADJ-class (transition-local), NOT GLB.** It is a sum of adjacent-transition
    indicators, so it is walk-decomposable via a small product channel on `(mask,last,rid)` — no GLB
    scan. The transition-local form was checked equal to the reference implementation over a C1 trial
    battery in the private exactness pass; **the trial count and KW's own value are not quoted here**,
    because that pass's script is not public. Removed from the GLB list above; belongs under
    WALK-DECOMPOSABLE/ADJ.
  - **Pure popcount / yang-COUNT functionals are G48-invariant, so they CAN ride the orbit-quotient DP.**
    The "yang-based ⇒ non-invariant" grouping (Caveats (1)) is over-conservative for count rows: G48 acts
    by line-position permutation, which preserves popcount. **The public half of this fact is already
    published and needs no private artifact:** `documentation/VERIFY.md` states the group is the
    centralizer of reversal in S₆, order 48, and `verify.py` derives the orbit partition itself, so
    popcount-invariance follows from published material. Only yang-POSITION and specific-trigram rows
    are genuinely non-invariant (those still need the plain #215-path DP).
  - **mmt3/mmt6 need only a small bounded channel** (adjacent Gray-transition counts) — already correctly
    under WALK-DECOMPOSABLE/ADJ; no extended station state. Confirmation, no move.
  - *Reproduction note.* The pass that produced these three calls is a private Python script. It is
    **not** a public reproduction command, so no figure of that pass is published above. Promoting it
    is an open operator call: it is a `.py`, and the single-file rule's Python side is `solve.py`.
- **Priority upgrade order (payoff-ranked):** (1) the **eight forced-class 1.0 rows** (mmt4,
  p1c4, s1, s6, r3, r4, r5, c2) — sampling cannot distinguish mass 1 from 1−ε; an exact count
  (= N) or a counterexample settles each; several may fall to PROOF instead (cheaper — try
  Lean/pen-and-paper first, DP second); (2) **N_gs** (see (c)); (3) the deep tails ccn4
  (~2×10⁻⁸), ccn8 (~2.6×10⁻⁷), c2011n1 (0 hits — starvation) — exact counts replace
  order-of-magnitude flags; (4) the ×11,364 gender fraction and the first-wave scoreboard
  fractions; (5) TR-8's pair-only null (10⁻⁴ from 10⁵ seeded samples — a C1-only-space count,
  CHEAP, near-closed-form); (6) the orientation fiber rows are ALREADY exact — no action.
- **(b) Per-upgrade bookkeeping:** each executed upgrade names the doc row it converts
  (estimate→exact): hub table rows; TR-1 scoreboard/§3; TR-9 ledger rows where a rule enters
  pricing. Query definitions carry the space label (population fractions are of C15 canonical
  mass — so each exact numerator ALSO needs the C15 denominator caveat: exact numerator over the
  TR-4 estimated |C15| stays an estimate UNLESS the rule count is computed within SUPER and
  paired with the C3-conditional sampling correction — state per-row which form ships).
- **(c) TR-2's N_gs explicitly:** N_gs = |triple-strict ∩ C15| currently 4.50×10²⁵ ±6.1%
  (~300 effective samples). The three component rules are POS + ADJ + ST-POS ⇒ a composed
  extended-state DP is feasible-in-principle; sizing gate first. An exact N_gs (or exact
  SUPER-numerator + sampled C3 correction) makes the corruption-model Bayes denominator exact —
  ⚠ **overstated, corrected 2026-09-05 (QSET finding 9): an exact SUPER numerator multiplied by a
  SAMPLED C3 acceptance rate is an ESTIMATE, not an exact count.** Only the first form (a count
  computed within C15) would be exact; the second tightens the estimate and does not remove its CI.
  The same conflation appears in the two sentences above and is withdrawn with this one —
  **touches a published verdict ⇒ lands only as a TR-2 version bump, operator-gated**, with the
  BF sensitivity re-run.
- **(d) CIRCULARITY-AUDIT GATE (mandatory):** every literature-derived functional passes the
  D-B1-class adversarial provenance audit BEFORE any striking exact tail ships
  **The precedent is published, and is the anchor for this gate.** `documentation/CLAIMS_DECIDED.md`
  carries the worked case: Drasny's "Rule of Ten" is CONFIRMED as a *fitted description*, because
  each "room" is verifiably the maximum-coverage decade window for its own group's KW positions,
  so the coverages "sum to 22 by construction — the count scores KW against a template extracted
  from KW," and the row records the consequence in terms — **"No p-value attached, no design
  inference (extraction-circularity policy)."** The same file's Davis names row records a DECLINED
  measurement on the same ground. The instrument is public (`--db1-verify`, two-language gate),
  the analysis is `reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md` §3b, the standing
  caveat is `documentation/CRITIQUE.md`, and `documentation/CLAIM_TO_ARTIFACT.md` is where a
  claim's evidence — or its absence — is registered. Rule, restated: rooms fitted to KW ⇒ p void;
  KW-extracted templates get descriptive reporting only, never a headline p.
- **(e) Certificates for already-closed claims:** TR-8's within-pair distance family {2,4,6}
  (Lean `within_pair_even_nonzero`) and TR-10's exact derivative-groups recomputation are
  ALREADY exact/certified — the sweep cites, does not redo.
- **Grading:** N_gs → TR-2 bump; scoreboard/tail fractions → hub-doc + TR-1 bumps; forced-1.0
  resolutions → TR-12 §11 (theorem class) if proven, TR-1 bump if merely exact-counted; nothing
  here is TR-12-headline except the forced-class resolutions.
- **Stage:** most post-F (count DPs are independent of Stage F's artifact but reuse its
  machinery; extended-state runs are standalone); TR-8 pair-null NOW-able. **Cost:** shortlist
  of 6–10 exact counts ≈ $250–800 [ESTIMATED, sizing-gated, operator-selected].

---

## 5. The exploration wave (EW) — constraint hunting under FRONTIER discipline

**Discipline banner:** exploration-grade; artifacts live in `frontier/` (roae-private) until a
finding survives adversarial audit; the base rate from the two prior hunts (biroco #207;
review-C literature audit) is **0-for-everything** — this program expects nulls and treats a
well-bounded null as a publishable finding.

- **EW-1. The surprise-localization ledger (lead instrument).** From Q3: KW's within-SUPER
  improbability is exactly log₂ N ≈ **129.689 bits**, and the rarity profile decomposes it
  exactly: 129.689 = Σᵢ −log₂ p_i over KW's 31 choices. Deliverable: the exact per-choice
  surprise spectrum (31 bars, exact rationals) + the **interpretation contract, fixed before
  looking**: **hypothesis under test (calibrated null, `documentation/QUERY_INVENTORY.md` §9.4) — KW's surprise is more concentrated
  than a uniform SUPER member's.** `localized-constraint-candidate` is a **lead** (where to look for
  a per-step prefix-state rule), not evidence that a rule exists; `typicality-bound` bounds nothing
  outside the named class; `anti-concentration` is reportable as-is.
  ⚠ **Corrected 2026-09-13 (V3B-03#23). The retired clause (i) read that surprise CONCENTRATION
  "marks where any undiscovered simple constraint MUST LIVE".** The identity cannot license it:
  `Σᵢ bits_i = log₂ N` is a chain-rule identity, and nothing in it places a missing constraint's
  bits at the steps where `bits_i` happens to be large — any sequence-global functional (this
  project's own C3 sum is the worked example) spreads them across every step. "Must live" is
  withdrawn; a lead is what concentration yields. The battery no longer prints the clause, so no
  verdict token is affected.
  ⚠ **The contract is narrowed, 2026-09-05 (QSET finding 12).** As written, (ii) named no constraint
  CLASS and no statistical POWER, and the outcome vocabulary had no "the instrument could not
  decide" branch — so every result mapped to a finding and nothing could come out empty. That is
  unfalsifiable in the only way that matters. **Narrowed to:** the class is *simple positional
  constraints expressible as a per-step function of the prefix state*, and no claim is made about
  constraints outside it; the band is the Q8 gallery's 1st/99th percentiles on `top1_share`,
  two-sided, evaluated **once**; and the outcome vocabulary is **three**, not two —
  `localized-constraint-candidate`, `typicality-bound`, and `anti-concentration`.
  A pre-registered instrument must be allowed to return nothing, and **`typicality-bound` is that
  outcome** — it is returned precisely when KW sits inside the band.
  **The decision rule, stated here rather than only in the battery** *(added 2026-09-13,
  V3B-03#24: `TR12_EW1_NULL=<verdict>` was published under a statistic this report never defined)*.
  **Statistic:** `top1_share = max_i(bits_i) / sum_i(bits_i)` over the 31 steps, with
  `bits_i = −log₂ p_i` (`documentation/QUERY_INVENTORY.md` §5; printed by the battery).
  **Band:** the Q8 gallery of K = `TR12_Q8_K` = 1,000 exact-uniform SUPER walks at the pinned seed
  `TR12_SEED` = 9276183659154465378 (row `a1_q8_super`), one `--kc-profile` per gallery walk
  (row `a2_ew1_null`), each walk contributing its own `top1_share`.
  **Quantile convention:** percentiles are order statistics on the sorted band — the q-quantile is
  `v[ceil(q·n)]`, index clamped to `[1, n]` — so p01 and p99 are band members, never interpolated.
  **Outcome map (two-sided, evaluated ONCE):** KW's `top1_share` **> p99** ⇒
  `localized-constraint-candidate`; **< p01** ⇒ `anti-concentration`; **otherwise** ⇒
  `typicality-bound`. The n=9 rehearsal band is reproducible from the public battery
  (`scripts/tr12_expected/n9/a2_ew1_null.txt`), so no private rehearsal script is needed to check
  the rule.
  ⚠ Earlier revisions of this line named a **fourth** outcome, `undecided`, for "the band is too wide
  to exclude anything". It is removed: the governing ruling (`QUERY_INVENTORY.md` §9.4, 2026-09-04)
  adopts **three**, the executable implements three, and no width criterion was ever defined — so the
  fourth could not be returned by any run and named a verdict nothing could emit. If a width test is
  ever wanted it must be defined in §9.4 and implemented **before** it is published here. Explicit connection
  to TR-9: the **105.4–139.1** unexplained bits (public TR-9 v1.24 §2/§5 — 105.4 = log₂|C1–C7|,
  the most conservative reading, keeping every cut; 139.1 = log₂|C1∩C2∩C4|, the residual against
  the claimed-explanatory layers alone) live in a different ledger (296.0-bit baseline); this
  instrument localizes the within-space remainder — the units bridge
  (walk-choice bits vs record bits vs the ledger's conventions) is stated in the deliverable,
  not glossed. Stage: post-G (rides Q3). Cost ≈ $1–5 + gallery band.
- **EW-2. Exact screening of pre-registered candidate families.** KW-INDEPENDENT functional
  families only (definable with no reference to KW): e.g. distance-class run-length spectra;
  parity-block statistics; trigram-transition family counts; prefix-cover times. Protocol:
  candidates + family sizes LOCKED (pre-registered in the frontier doc, hash-pinned) BEFORE any
  tail is computed; then per candidate: exact population distribution (decomposable ones via the
  §4-LS DP channels) + KW's exact tail position; multiple-comparisons accounting up front
  (family size discounts every tail, and **the adjusted threshold must be stated with the tail**:
  under this suite's standing convention — **Bonferroni / family-wise error rate at α = 0.05**,
  applied throughout per [METHODS.md](METHODS.md) §"Statistics conventions" — a 100-family screen
  carries a per-candidate bar of α/m = 0.05/100 = **5×10⁻⁴**, so a 10⁻⁴ tail **clears** that bar by
  ~5× and its Bonferroni-adjusted p is 10⁻⁴ × 100 = **10⁻²**, which is significant at α = 0.05. A
  10⁻⁴ tail in a 100-family screen is noise only under a **pre-registered α ≤ 10⁻²**, or under a
  correction family stricter than Bonferroni; EW-2's pre-registration must therefore pin **α**
  alongside the candidate list and the family size, and every tail it publishes must name the
  adjusted threshold it is read against)
  ⚠ **[CORRECTED 2026-09-19, V3B-03#25 — this parenthetical read "(family size discounts every tail
  — a 10⁻⁴ tail in a 100-family screen is NOISE, said so)", and that is **arithmetically false** at
  the α this suite publishes under. Bonferroni-adjusting a 10⁻⁴ tail for a 100-family screen gives
  10⁻⁴ × 100 = 10⁻², and 10⁻² < 0.05, so such a tail is **significant, not noise**; equivalently it
  clears the per-candidate bar 0.05/100 = 5×10⁻⁴ by a factor of ~5. The retracted sentence is true
  only under a threshold it never stated, and it sat in the very clause that tells a reader how
  multiple-comparisons accounting will be done — so as written it would have licensed discarding
  exactly the findings this screen exists to catch. **No published number moves: EW-2 was not run** —
  it is a wave-3 item and wave 3 was never budgeted (§Wave-status ruling) — and no tail, candidate
  list or α was computed or published under it; the figure was
  illustrative. See [CORRECTIONS.md](../documentation/CORRECTIONS.md).]**;
  the D-B1 circularity audit as a MANDATORY pre-publication gate per candidate. Stage: post-F;
  cost per exact screen ≈ $40–105 (shares LS machinery — schedule jointly).
- **EW-3. Criticality census.** From CAP-5's sensitivity atlas: every constraint parameter where
  KW sits extremal/critical rather than interior — instance #1 (cite, already established): the
  C3 ceiling is EXACTLY KW's value (cd\* = 387 ⟺ 776, zero margin, circular by construction);
  C5's budget B0 is KW's own multiset (every class exactly consumed — tight by definition);
  the census makes the margin table exact: per parameter, the count change under ±1 perturbation
  and whether KW remains a member. Deliverable: the per-parameter margin table with the honest
  framing that KW-derived parameters are tight BY CONSTRUCTION (TR-9's circularity discipline) —
  criticality is only evidence when the parameter is KW-independent. Stage: rides CAP-5.
- **GOVERNANCE (required).** (1) Pre-registration protocol: candidate list + family size +
  interpretation contract committed to `frontier/EW_PREREG_<date>.md` (roae-private) with a
  content hash recorded BEFORE any tail computation; deviations = new pre-registration.
  (2) Graduation bar: frontier → core only via the airtight-or-back-catalog rule (adversarial
  audit incl. circularity; reproduction commands; operator sign-off); reputation over
  completeness. (3) Honest framing: this wave is the successor to TR-9's unexplained-bits
  question; a null result IS the publishable answer ("the residual bits are not localized in any
  of these families"), staged as a TR-9/TR-12 addendum, not buried.

---

## 6. Capabilities program appendix (CAP-1..8) — the 2026-07-17 capability plan, with status at HEAD in §8

Grading key: **[R]** report-grade findings (feed TR-12 or a future TR) · **[I]** infrastructure
(documented in SOLVE_C_CLI/SOLVE_PY_CLI when built) · **[RG]** research program, not report-grade.

- **CAP-1. Certified Q&A oracle [R+I].** Exact counts for walk-decomposable properties P with
  certificates. Def: count(P) = |{w ∈ SUPER : P(w)}| exact (C15 companion by sampling
  correction, labeled). Mechanism: the §4-LS DP channels + `--kc-oracle` (the R-3.5 harness,
  ALREADY on the H-tier worklist — this extends its query grammar with property channels).
  Certificate: run log + layer shas + the mod-24 gate where the property is G-closed + reduced-n
  brute-force gates. Feeds the TR-9 pricing upgrade path (exact numerators for rule rows).
  Stage: post-F machinery; per-query $40–105. Wave 3.
- **CAP-2. Claim-verifier [I; results feed Q7].** Any submitted 64-arrangement → verdict +
  first-violated constraint + rank-if-valid. Mostly EXISTS piecewise (predicates + `--kc-member`
  + ranker); **TO-BUILD**: the one-command wrapper `--check-arrangement` (pinned check order,
  certificate output). Stage: NOW (verdict) / post-O3 (rank). ≈ $0. Wave 0.
- **CAP-3. Canonical naming [I].** The citable ID convention — spec (freeze-gated, D2-adjacent):
  `KW-O3-SUPER-r<rank>` where order label = O3 (ratified comparator BY NAME), space label =
  SUPER (or C15-est), rank = exact decimal (≤ 40 digits); every ID resolves via unrank + carries
  the build/convention provenance. IDs are coordinates, not names — no semantic loading.
  Stage: post-O3; $0. Wave 2.
- **CAP-4. Minimal-repair [RG→R].** Nearest valid solution (SUPER, and C15 variant) to any
  invalid arrangement under a stated edit metric (slot-edits per the SAT precedent). Precedent:
  the SAT minimal-repair results (grand minimal repair = exactly 3 slot-edits, DRAT-certified) —
  those are KW-anchored; this capability generalizes to arbitrary inputs via f·g-pruned
  branch-and-bound (admissible bound: remaining-mismatch lower bound; g>0 feasibility prune).
  **TO-BUILD**, runtime unbounded — RESEARCH-GRADE until benchmarked at n ≤ 16; SAT remains the
  certified path for specific instances. Wave 3.
- **CAP-5. Constraint-sensitivity atlas [R].** N(B) as a function of perturbed C5 budgets B
  (and C2 relaxations). Each point = one count-only full-31 DP re-run (~$40–80, hours–days).
  Grid worth running (priority subset, ~9 runs): the 8 single-unit adjacent transfers of B0
  mass between distance classes + the C2-off row; full ±1 grid (20 pts) is elective. Cost table:
  9 pts ≈ $360–720; 20 pts ≈ $800–1,600 [ESTIMATED] — **operator-gated, NOT authorized here**.
  Output: the margin table (feeds EW-3). Certificate: each run's mod-24 gate + layer integrity.
  Wave 3.
- **CAP-6. Conditional sampling [I].** Uniform samples given decomposable properties: exact via
  property-extended ladders (a Stage-F/G-class build per property family — expensive), or
  rejection from `--kc-sample` when acceptance ≥ ~10⁻³ (cheap, exact, preferred; the C3 case is
  the worked example at 1/8.26). Spec both; default rejection. Stage: post-F. Wave 2–3.
- **CAP-7. Datasets-on-demand [I].** Rank-range streaming emission: slice request =
  (order, space, [r_lo, r_hi), format) → `--kc-enum`-class stream (REL exists; O3 post-ranker)
  with integrity sidecars (record count, decompressed-stream sha256, `#provenance`, the H6
  certificate). Non-canonical unless certificate-bound (AR-1 discipline). **TO-BUILD**: the
  slice-request wrapper + sidecar emitter. Stage: post-F/post-G. Wave 2.
- **CAP-8. Solution-space connectivity [RG].** Adjacency-graph program: candidate move sets =
  orientation flip; adjacent-pair-slot swap; general slot-edit pairs; k-edit balls. Computable
  EXACTLY at exhaustive small n (full `--kc-enum` + BFS at n ≤ 13 — component counts, diameters);
  full-31 connectivity is OPEN (no known decomposition; degree statistics of single solutions
  are computable via membership probes of all neighbors — cheap per-solution). RESEARCH-GRADE;
  explicitly NOT TR-12 material. Wave 3.

---

## R. Independent-reproduction methods spec (RM) — the TR-12 spine

TR-12 ships reproduction as a first-class SECTION (not an appendix): the step-by-step by which
an outsider rebuilds everything and reproduces every published number. Two tiers, both fully
specced in the report; this is the execution spec behind them.

### R.0 — The catalog is THREE stages, f → g → t, and WHICH of them a query needs is per-query (read this first)

⚠ *(Heading corrected 2026-09-13, V3B-03#29 / V3A-086#7. It read "**and ALL are required**" — the
blanket this section's own body had already been narrowed away from on 2026-09-12, leaving the
heading asserting what the bullets below deny. The per-query table is the authority, and the
difference is load-bearing for a third party's provisioning, not just for prose: on the measured
sizes below, an f-only reproducer needs **3.29 TB** and an f+g reproducer **11.57 TB**, against
**15.05 TB** for all three. Only the Exhaustion Atlas and its per-branch numbers need t. No run
number moves either way.)*

**The Exhaustion Atlas and every exact-count or ranking query need the compiled catalog; a
per-query table follows, and it is the `ladders` column of `documentation/QUERY_INVENTORY.md` §1
rather than a blanket.** ⚠ *(Narrowed 2026-09-12, V3A-086#7. This read "No TR-12 query, no
Exhaustion-Atlas number, and **no published count** can be reproduced without first building the
three-tier compiled catalog. There is no shortcut and no partial path" — a blanket this document's
own anchors contradict. `solve --kc-count FDIR` returns the exact N **from f alone**
(`documentation/VERIFY.md`), REL rank/unrank works "from forward layers alone" (§0 above), and the
inventory's own ladders column carries `f` for Q1b, Q2b, Q2c/d, Q4a/c and Q8 and `—` for Q4b, Q7
and Q9 — which need no ladder at all. R.0 should reproduce that table, not contradict it.)* the
1.097×10³⁹ solution space is never materialized; every TR-12 result is a *query against this
catalog*, so the catalog IS the reproduction artifact. The three stages must be built **in
dependency order** — **CORRECTED 2026-08-13: this is a FAN, NOT A CHAIN.** `f -> {g, t}`: both `g` and `t`
read `f`, and **NEITHER `g` NOR `t` READS THE OTHER** (verified in code and from the recurrence
`t(s) = 1 + sum_c t(s.c)`, which needs to know WHICH CHILDREN ARE ADMISSIBLE — that is `f` — never HOW MANY
COMPLETIONS a state has, which is `g`). The "each consumes the previous" phrasing below, and any caption
saying **Stage T reads GDIR**, are WRONG and have misinformed reproducers. *(The wrong-caption
example in this sentence itself read "Stage G reads FDIR" until 2026-09-05, and this sentence then
called that phrasing "the **correct** dependency". ⚠ **Corrected 2026-09-13, V3B-03#30: that
conflates two different claims.** As a *logical* dependency it is true — g's values are determined
by the same state space f enumerates. As a statement about the *command* it is false: `--kc-g-build`
takes no FDIR argument and rebuilds the state space itself, which is why the step-2 heading below
now says so. Settled by execution: with no f directory present anywhere on disk,
`./solve --kc-g-build ./g9 --f1-pairs 9` succeeds.)* **Public anchors, no
internal note required:** `documentation/GT_LADDER_FORMAT.md` §"t-ladder" gives the signature
**`--kc-t-build FDIR TDIR`** — an f-directory and an output directory, no `GDIR` argument —
and `documentation/VERIFY.md` and `documentation/SOLVE_PY_CLI.md` both publish the runnable line
`./solve --kc-t-build "$A"/f "$A"/t` beside `--kc-g-build`, so the fan is checkable from the
published grammar alone.

*(The retracted wording, quoted so the seam is visible rather than silently repaired: this
paragraph used to read "the three stages must be built in dependency order — **each consumes the
previous**", and the diagram below used to carry a left-to-right chain `Stage F ──► Stage G ──►
Stage T`. Both are wrong. `g` and `t` are siblings; the arrows below are the corrected ones.)*

```
                   Stage F
                  (f-ladder)
                  membership
                       │
            ┌──────────┴──────────┐
            ▼                     ▼
        Stage G               Stage T
       (g-ladder)            (t-ladder)
      exact count      exhaustion-cost / Exhaustion Atlas

   g and t are each DETERMINED BY f's state space; neither TAKES an FDIR argument.
   (--kc-g-build rebuilds it; --kc-t-build takes FDIR.)  g and t never read each other.
   branch atlas (XA) needs all three: FDIR + GDIR + TDIR
```

- **f alone** answers membership, first-violation, **`--kc-count` (the exact N — `documentation/VERIFY.md`
  §counts)**, **REL rank/unrank** (Q1b, Q2b, Q2c/d, and the V3 REL axis) and **`--kc-sample`**
  (Q4a/c, Q8, Q1c). *(Corrected 2026-09-12, V3A-086#7: this read "membership / first-violation
  only".)*
- **No ladder at all** is needed by Q7 (arrangement verdicts), Q9 (certified restatements) or
  Q4b (SAT) — the inventory's ladders column carries `—` for all three.
- **f + g** are needed for any exact count or ranking query (Q1–Q3, Q6; Wave 2) — **and for EW-1**,
  which is DERIVED from Q3's `--kc-profile FDIR GDIR` artifact and opens no t ladder at all.
  *(EW-1 moved here from the f+g+t bullet 2026-09-13, V3B-03#29: `documentation/QUERY_INVENTORY.md`
  §5 already classed it `DERIVED, no compute` — "Rides Q3 — needs f+g, NOT the scan" — and the
  battery builds it from a `--kc-profile FDIR GDIR` artifact with no `--kc-tdir` anywhere.)*
- **f + g + t** are needed for the Exhaustion Atlas — the headline TR-12 section — and every
  per-branch exhaustion number (XA, CAP-3/5/7).

<!-- RESOLVED 2026-09-23 (v1.11). The REPRO-TAG placeholder that stood here (V3B-03#28, Fable
     adjudication 2026-09-11) has been replaced by the real tag name, `tr12-v1.10`, which is
     minted at the commit carrying this revision and pushed to the public remote before this
     line ships -- the tag-before-anything order the placeholder existed to enforce. The rule it
     encoded still stands for any FUTURE pin: never substitute a sha or a guessed tag name before
     the tag exists, because a reproduction instruction that resolves to nothing is the exact
     defect corrected at this line on 2026-09-05. Verify with:
       git ls-remote --tags origin | grep tr12
     The second occurrence, in Tier A step 1 of section R, is resolved in the same commit. -->
**Build commands.** The pin is the tag **`tr12-v1.10`**, minted at this report's publication and
named in §R Tier A step 1; resolve it with `git ls-remote --tags origin | grep tr12`. *(Corrected
2026-09-05: this line carried a truncated v4-compiler sha as the pin. That commit is a real Stage-T
build pin in the compiler lineage, but it is **not reachable from this repository's `main`** —
`documentation/HISTORY.md` records exactly that — so as a reproduction instruction in a published
report it resolved to nothing. A reproduction instruction pointing at
nothing is worse than one pointing at a tag the reader can list, so the placeholder is named as a
placeholder rather than dressed as a commit.)* Each command below is OOC, resumable and sha-gated.
Let `FDIR`/`GDIR`/`TDIR` be the three catalog directories. **They are not the same size, and
the difference is load-bearing for provisioning**. ⚠ *(Basis stated per row 2026-09-12, V3B-03#33.
This table headed all three rows "measured … with `du -sb`" and they are **not on one basis** —
which is why f exceeds its own archive total. Each row now says what was summed, and the
reproducible public basis for all three is the 65-file registry in
`runs/20260906_kc_ladders_n31/README.md` §Provenance.)*

| ladder | measured size | basis of the measurement | provision |
|---|---|---|---|
| **f** (`FDIR`) | **3.29 TB** (3,293,894,951,830 B) | `du -sb FDIR` on 2026-08-02 — **directory contents**, so sidecars and extras are included. It therefore **exceeds** the 65-file archive total 3,293,894,509,534 B by 442,296 B; not a contradiction, but a different basis | a 4 TB volume holds it, with little headroom |
| **g** (`GDIR`) | **8.27 TB** (8,274,431,592,051 B) | **sum of the 32 `.bin` layer files only.** The 65-file archive total is 8,274,432,288,476 B; the 696,425 B difference is sidecars + manifest | ⚠ **≥ 10 TB.** A 4 TB volume does **not** hold it, and neither does an 8 TB volume shared with f |
| **t** (`TDIR`) | **3.48 TB** (3,483,654,585,228 B) | the **65-file archive total** *(MEASURED on the completed ladder, 2026-09-06; was "~3.1 TB projected")* | a 4 TB volume |
| **total** | **15.05 TB** *(measured; was "~14.7 TB" from the t projection)* | the three rows above, on the three different bases named | — |

**Peak build space: UNMEASURED.** No peak figure exists for any stage and none can be obtained
without a rebuild, so none is quoted. The bound the *format* gives is the finished ladder plus the
live-layer window (`documentation/F1C5_LAYER_FORMAT.md`); a reproducer should provision above the
finished sizes above, not at them.

*(Corrected 2026-09-05. This line read "three catalog directories on ~4 TB disk each", and both
`solve.c`'s `--kc-g-build` usage text and `documentation/SOLVE_C_CLI.md` predicted g at "~2.5-2.7 TB
… the same size class as f", hedged and — in the source comment's own words — "unmeasured until the
run". The run happened and the prediction was wrong by 3×. A reproducer provisioning from the old
guidance would have run out of disk partway through a multi-day out-of-core build. All three sites
are corrected; see `documentation/CORRECTIONS.md`.)*

1. **Stage F (f-ladder):**
   ```
   SOLVE_F1_KEEP_LAYERS=1 ./solve --f1-exact-c1c2c4c5 --f1-out-of-core FDIR
   #   resume after any interruption:  add  --resume-from-layers
   #   verify:  ./solve --f1c5-layer-sha FDIR   (32 shas == runs/20260906_kc_ladders_n31/STAGE_F_LAYERSHA.txt)
   #   the run prints total == N and hard-aborts unless N ≡ 0 (mod 24)
   ```
2. **Stage G (g-ladder) — standalone, takes NO FDIR:** it rebuilds the state space on its own;
   FDIR and GDIR meet only at `--kc-g-check` / `--kc-scan`. *(Heading corrected 2026-09-13,
   V3B-03#30; it read "reads FDIR", which the command below contradicts — there is no FDIR argument
   to contradict it with.)*
   ```
   ./solve --kc-g-build GDIR --f1-pairs 31 --kc-g-ooc
   #   --f1-pairs 31 is REQUIRED. Without it --kc-g-build silently builds n=9 (measured:
   #   '[kc-g] build: n=9 ... g(0)=26112'), and --kc-g-check then fails 'f/g ladder context
   #   mismatch'. Stage F above needs no such flag: --f1-exact-c1c2c4c5 defaults to FULL-31.
   #   verify shas:  32 g-layer shas == runs/20260906_kc_ladders_n31/STAGE_G_LAYERSHA.txt
   #   verify identity:  ./solve --kc-g-check FDIR GDIR   (f·g cut identity prints N at EVERY layer)
   ```
3. **Stage T (t-ladder) — reads FDIR:**
   ```
   ./solve --kc-t-build FDIR TDIR --kc-ooc --kc-cache-mb <MB>
   #   resume is AUTOMATIC (adopts an existing t_manifest.txt + t_build.ckpt)
   #   verify shas:  t-layer shas == runs/20260906_kc_ladders_n31/STAGE_T_LAYERSHA.txt
   #   cross-check:  t vs DFS exhaustion cost at n ≤ 13 must agree exactly
   ```
4. **Assemble the Exhaustion Atlas (needs all three):**
   ```
   ./solve --kc-scan FDIR GDIR atlas.json --kc-tdir TDIR --kc-raw   # per-branch table; internal gate Σ_b solutions(b) == N
   #   --kc-raw is REQUIRED at n=31: without it marginal_raw is not emitted and V1 dies. It is
   #   automatic at small n, which is why the omission survives every small-n rehearsal. The
   #   n=31 pass is UNRESUMABLE, so discovering this at the end costs a full re-scan.
   ```

Cost/time per stage, hedged [ESTIMATED]: each of F/G/T ≈ 2–7 days cloud-Spot wall, ~$60–140.

**Atlas assembly is not a rounding error, and an earlier revision of this line said it was.** The
figure it carried is **withdrawn, not restated** — v1.0's rule for the declined exact-C3 run: a
withdrawal that requotes a number publishes it. `--kc-scan-merge` does not merely assemble; it
**re-digests every f and g layer** before writing the atlas. Measured 2026-09-18 on the n=31
ladders, its scope is f layers 0..30 plus g layers 1..31 — **62 layers, 43.91 TB decompressed** —
and at the measured single-process rate of **258.7 MB/s** that is **~47 h of wall time**. It is
single-threaded by construction: the digest loop is a plain nest with no OpenMP, and the
subcommand exposes no threads knob, so a host with more cores does not shorten it.

Commodity contract (TR-11 §7): ~64 GB RAM + ~4 TB disk — that disk figure is
TR-11's, and it is the **f**-ladder contract; **g needs ≥ 10 TB**, per the measured table above. Only
*after* F/G/T exist do the query steps below (Tier A step 6 onward) run — **those** are the steps
that take minutes at near-$0; the atlas step above them is not one of them.

**TIER A — full rebuild (gold standard; trusts only public source + own hardware).**
<!-- RESOLVED 2026-09-23 (v1.11): step 1's pin now names the real tag, `tr12-v1.10`, minted at the
     commit carrying this revision and pushed public before this line shipped. See the note at the
     Build commands paragraph above (V3B-03#28). -->
1. Clone the public repo at the pinned tag **`tr12-v1.10`** (host-agnostic git — no
   GitHub-specific machinery; the tag is minted at TR-12 publication and named in the report).
2. Build `solve.c` with the **published** line — `documentation/VERIFY.md` Stage 0 of
   §"TR-12 query program":
   ```
   gcc -O2 -pthread -fopenmp -DGIT_HASH="\"$(git rev-parse --short=12 HEAD 2>/dev/null || echo unknown)\"" -DSOURCE_SHA="\"$(sha256sum solve.c | cut -d' ' -f1)\"" -DGIT_BRANCH="\"$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)\"" -o solve solve.c -lm -lz
   ```
   ⚠ **The three `-D` identity flags were missing from this step until 2026-09-22 (v1.8, CX-61).**
   Without them the binary defaults both identity fields to `"unknown"`, every artifact it writes
   records `engine_git "unknown"` / `engine_source_sha "unknown"`, and **the atlas digest §12 pins
   can never be reproduced from the recipe this step printed** — the document demanded a thing its
   own command could not produce. `documentation/VERIFY.md` Stage 0 gained these flags on
   2026-09-06 (Q-331 item 7); this copy cites that file as its source and never received them,
   which is a correction that did not propagate. Note `--short=12`: the `engine_git` value pinned
   in §12 is the twelve-hex `8af5e55c8eed`, while a bare `git rev-parse --short HEAD` yields
   **eight** hex on this repository (measured 2026-09-22), so VERIFY.md's own line reproduces that
   field's content but not its width. The flags are **sha-neutral** for the `--selftest` anchor —
   VERIFY.md Stage 0 measures this rather than assuming it — so adding them moves no pinned digest
   here. Even correctly flagged, the raw atlas digest still depends on the ladder directory
   basenames; see §12 "The input, pinned" for the normalised digest that does not.
   `-lz` is required to link and `-o solve` is required because every later step invokes
   `./solve`. For a multi-day ladder rebuild the repository's other published recipe adds
   optimisation — `gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm -lz`
   (`../README.md` §"Check it yourself" — the repository-root README, not `reports/README.md`) — and by the next sentence the two are sha-equivalent.
   **Toolchain freedom is load-bearing and stated:** all registered layer shas are over
   the DECOMPRESSED stream (the CR-3b subcommand `--f1c5-layer-sha`), and recompress-invariance
   is PROVEN (CR-3b work, 2026-07-16). **Two claims live here and they have different standing —
   split 2026-09-12 (V3B-03#35), where one sentence had promoted both to "CANNOT".**
   (i) **zlib version and gzip level cannot change a decompressed-stream sha** — that is a
   *proof*, true by construction for a lossless codec. (ii) **Invariance to compiler, flags and
   architecture is OBSERVED, not proven:** it holds on every recipe `reports/METHODS.md` §toolchain
   lists — `-O2`, `-O3 -march=native`, `-O3 -march=x86-64-v3`, `-O3 -flto`, and x86 vs ARM — which
   METHODS itself records as **two witnesses, not an exhaustive guarantee** over every compiler
   version and host. `--selftest` anchor + `build.sha` hygiene apply as usual.
3. Rebuild the f-ladder from scratch: `--f1-exact-c1c2c4c5 --f1-out-of-core DIR` with
   `SOLVE_F1_KEEP_LAYERS=1` (the Stage-F form; `--resume-from-layers` after any interruption).
   The TR-11 §7 commodity contract governs: **~64 GB RAM + ~4 TB disk**. Expected cost/time,
   hedged: cloud Spot (64–128 cores) ≈ 2–7 days wall, ~$75–140 [ESTIMATED; the project's own
   runs are the anchor]; owned workstation (16–32 cores, 64 GB, 4 TB SSD) ≈ 1–4 weeks wall,
   ~$0 marginal [ESTIMATED, unmeasured — stated as a hedge, not a promise].
4. Verify all 32 f-layer decompressed-stream shas against the published registry
   `runs/20260906_kc_ladders_n31/STAGE_F_LAYERSHA.txt` via `--f1c5-layer-sha`; the run itself must print total == N and
   hard-aborts unless N ≡ 0 (mod 24).
5. Stage G likewise: `--kc-g-build GDIR --f1-pairs 31 --kc-g-ooc` (the flag is required; without it the build is n=9) (+ a contract/cost of the same shape,
   ~$60–110 cloud); verify the 32 g-layer shas `runs/20260906_kc_ladders_n31/STAGE_G_LAYERSHA.txt`; run
   `--kc-g-check FDIR GDIR` — the f·g cut identity must print N at EVERY layer.
5b. **Stage T likewise (REQUIRED for the Exhaustion Atlas and every per-branch number)** per
   R.0 step 3: `--kc-t-build FDIR TDIR --kc-ooc`; verify the t-layer shas
   `runs/20260906_kc_ladders_n31/STAGE_T_LAYERSHA.txt` and the n ≤ 13 t-vs-DFS agreement; then assemble the atlas with
   `--kc-scan FDIR GDIR atlas.json --kc-tdir TDIR --kc-raw` (internal gate Σ_b solutions(b) == N; `--kc-raw` is required at n=31).
6. Run each TR-12 query as ONE command and diff each row's output against the **committed
   expected-output blocks**, `scripts/tr12_expected/n9/<row>.txt`. ⚠ *(Corrected 2026-09-23: this
   step named a block `[EXPECTED-Q1]..[EXPECTED-Q9], [EXPECTED-XA], …` and said "every published
   number appears in a verbatim, diff-able block". **No `[EXPECTED-…]` block has ever existed in
   this report** — `grep -c '\[EXPECTED-'` over this file matched only that one instruction — so the
   step pointed a reproducer at an object it could not find. The real objects are the per-row files
   under `scripts/tr12_expected/n9/`, which is what this step now names.)*
   **The driver is public and built:** `scripts/tr12_repro.sh` runs the battery against named
   FDIR/GDIR, diffs each output against those committed blocks, prints `TR12_REPRO=PASS|FAIL`,
   reports skips explicitly, and exits non-zero on any mismatch.
   ⚠ *At n=31 **no expected set is committed in this tree.** The 2026-09-22 production run minted
   its own blocks (`--mint-missing`), and a minted row records PASS without diffing anything;
   publishing that minted set is a separate publication action, not taken in this revision. At full
   scale every defence is therefore what a row ASSERTS, never what it MATCHES
   (`documentation/QUERY_INVENTORY.md` §3.0). Added 2026-09-11 (Fable PD-3); tense closed
   2026-09-23, the run having happened.*
7. Re-derive the certificates: rank(unrank(r)) = r + the KW neighbor bracket (Q1);
   Π p_i = 1/N exactly (Q3); N mod 24 = 0; Σ_b solutions(b) = N (XA); the gallery chi² gate
   (Q8); the f·g identity (step 5). The ÷24 and product-of-conditionals checks are reader
   arithmetic — no project code needed.

**TIER B — check a ladder you already hold against the published registries (container check
minutes; the logical sweep MEASURED at 7 h 11 min, ~$0 marginal compute on hardware you already
have).** *(Heading corrected 2026-09-22, v1.8: it read "(minutes, ~$0 compute)" against this
section's own measured 7 h 11 min at the logical-registry paragraph below — v1.3 updated the body
and left the heading.)*

**Resolved 2026-09-05 — what is published, and what is not.** **This project publishes the
per-layer SHA registries, not the ladder data.** The ladders are large; they are also *derived*
— every byte of them is determined by the published source, the published build commands above,
and the published specifications (`documentation/F1C5_LAYER_FORMAT.md`,
`documentation/GT_LADDER_FORMAT.md`). So the reproducible
object is the *recipe plus a fingerprint*, and that is what ships: **rebuild by Tier A, then check
your bytes against the registry.** A registry match is a strong statement — it says your
independently built ladder is byte-identical, on the decompressed stream, to the one every number
in this report was computed against.

**Stated plainly so no reader is left guessing:** the ladder data is **not distributed by this
project**, and nothing in this program is conditional on obtaining it from us. Tier A is the
complete path from published source to published number; Tier B below is a check, not an
acquisition step.

1. Have a ladder — one you built with the Tier-A commands, or one you were given. Its origin does
   not matter to this check; that is the point of a fingerprint.
2. Verify the layer digests against `runs/20260906_kc_ladders_n31/`. **Which registry you want
   depends on where your ladder came from, and the two never match each other:**

   | your ladder | check | registry | what a match proves |
   |---|---|---|---|
   | **given to you** | `sha256sum -c` | `STAGE_{F,G,T}_SHA256.txt` — 65 rows/stage | the *files* are byte-identical to the archived ones |
   | **rebuilt via Tier A** | `./solve --f1c5-layer-sha DIR` | `STAGE_{F,G,T}_LAYERSHA.txt` — 32 rows/stage | the *content* is identical, whatever your compressor did |

   **Which framing era the first row assumes, so it is not misread:** `STAGE_{F,G,T}_SHA256.txt`
   holds the **RAW** container bytes — each file exactly as stored, gzip framing included, which is
   the post-#169 default — so `sha256sum -c` is the correct tool for that row and no `gzip -dc` step
   belongs in front of it. The second row is the opposite case: it digests the decompressed content.

   **Do not cross them.** They digest different byte streams — measured on `t_layer_30.bin`: 888
   bytes stored, 29,660 bytes of content, two unrelated digests — so a cross comparison fails on
   every layer, not one (`documentation/QUERY_INVENTORY.md` §C-04).

   **Both registries have now been executed against the live ladders by this project (2026-09-17),
   and both passed with zero mismatches.** The table above says what a reader *can* check; this says
   what was checked here, so the reader knows the registries are exercised rather than merely
   published.

   | check | command | scope | result |
   |---|---|---|---|
   | logical (content) | `./solve --f1c5-layer-sha DIR` | 32 f + 32 g + 32 t layers | **96 of 96 match** `STAGE_{F,G,T}_LAYERSHA.txt` |
   | container (files) | `sha256sum -c STAGE_T_SHA256.txt` | 65 t files | **65 of 65 match** (`runs/20260906_kc_ladders_n31/STAGE_T_RAW_VERIFY.md`) |

   Two things this does **not** claim. It does not prove the ladders are mathematically correct —
   that is `--kc-t-check` and `--kc-g-check`, different instruments answering a different question.
   Both of those did run at n=31, standalone rather than as battery rows, and both passed at every
   layer: `--kc-t-check` in `runs/20260906_kc_ladders_n31/KC_T_CHECK_n31.txt` and `--kc-g-check` in
   `reports/KC_G_CHECK_n31.txt` — each an integrity check of the files, not of the transition relation
   (`documentation/GT_LADDER_FORMAT.md` line 297). *(Added 2026-09-24.)*
   And the container row is the **RAW, post-#169 framing**: `STAGE_T_SHA256.txt` records each file as
   stored, gzip framing included, so `sha256sum -c` is correct there and needs no `gzip -dc`, which
   is the opposite of the case where a sidecar holds the logical digest.

   The logical sweep was previously recorded as cost-gated on a ~40 h estimate. That estimate was
   **per-process and serial**; because `--f1c5-layer-sha` accepts FILE arguments, the layers digest
   concurrently and the wall cost is set by the largest single layer rather than by the sum — all 96
   completed in **7 h 11 min**, with `g_layer_16` the makespan at 25,868 s. The battery row still
   reports `TR12_TSHA=SKIP:cost-gated` because the battery does not run that pass inline; the row and
   the question have different answers.

   The distinction is not pedantry: a correct rebuild whose zlib emits different bytes **fails the
   raw-file check**, and only the logical registry can tell that apart from wrong data. Conversely a
   disk you were handed should match raw-file exactly, and a logical-only match there would leave
   file corruption undetected.

   A mismatch at layer *k* localises the divergence to that layer, which is the point of a per-layer
   registry rather than one digest per stage.
3. Run the identical step-6 query battery + step-7 certificates (identical commands; the query
   layer is artifact-source-agnostic by construction).

**TIER C — the SMALL TIER (laptop scale, minutes, no ladder build, ~$0).** *(Added 2026-09-13,
V3B-03#32. §10D states that "the §R small-tier commands ARE the appendix", and §R carried no such
commands — `grep -c -- '--n9'` over this file returned **0**. The route existed only in
`scripts/tr12_expected/README.md`. It is written out here, so §10D's sentence is true.)*

```
scripts/tr12_repro.sh --n9          # the whole battery at n=9 against the committed goldens:
                                    #   each row diffed verbatim against scripts/tr12_expected/n9/,
                                    #   QUERY_DRYRUN=PASS on success, skips reported explicitly,
                                    #   non-zero exit on any mismatch
scripts/tr12_repro_gate.sh --check  # currency check (milliseconds, no build): does the COMMITTED
                                    #   tree still fingerprint-match its last recorded reproducing
                                    #   PASS?   TR12_REPRO_GATE_CURRENT=YES|NO|UNKNOWN
scripts/tr12_repro_gate.sh          # the full gate: EXTRACTS the published build line from
                                    #   documentation/VERIFY.md, builds with it, runs the n=9
                                    #   battery.  ~2 minutes on two cores; no ladder data, no
                                    #   network, no disk beyond the repo
./solve --kc-build D --f1-pairs 13 && ./solve --kc-count D
                                    # the n=13 exact count witness: prints 2063395607040
                                    #   (documentation/QUERY_INVENTORY.md §count witnesses);
                                    #   ~352 ms to build, ~9 ms to count
```

These are the commands §10D's appendix refers to. Between them they exercise every TR-12 claim
TYPE — exact count, rank/unrank round-trip, membership verdict, atlas identities, the mod-24 gate
and the reproduction battery itself — at a scale a reader runs on a laptop in minutes, with no
15 TB catalog and no cloud spend.

**Independence-ladder labels (METHODS.md conventions; printed with each tier).**
- Tier A: rung 3 (instrument stack) for all compiler-derived numbers — but with NO trust in any
  project-distributed artifact (everything rebuilt from public source); the mod-24 and
  product-of-conditionals gates sit at rung 1 (reader arithmetic); membership/first-violation
  certs at rung 2. What Tier A does NOT establish: instrument-independence — it re-runs the
  SAME solve.c mathematics. **That caveat splits, and TR-11 has since closed half of it.** The
  full-31 totals |C1∩C2∩C4∩C5| and |C1∩C2∩C4| are **two-instrument**: independently recomputed at
  full scale on 2026-07-25 by `verify.c`'s inclusion–exclusion transfer-walk engine — a different
  algorithm class sharing no code and no state with `solve.c` — exact MATCH, mod-24 gated
  ([TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §10(vi); [METHODS.md](METHODS.md)
  §"Canonical quantities"). Every **per-query** Q1–Q10 output specified in this report is
  **single-instrument**: no second engine computes it. So the TR-11 §10(vi) single-instrument
  caveat is INHERITED BY BOTH TIERS **for the per-query outputs, and for those only** — not for the
  totals — and stated in the section body, not the margins (an independent reimplementation from
  the published recurrences is the only true second instrument; the H8 two-language boundary
  applies).
  ⚠ **[CORRECTED 2026-09-19, V3B-03#36 — this read "the TR-11 §10(vi) single-instrument caveat is
  INHERITED BY BOTH TIERS" with no split, inheriting a caveat TR-11 had already retired for the
  totals. TR-11 §10(vi) records the full-31 integer as **two-instrument** and calls the earlier
  "remains single-instrument" wording a **stale label, aligned 2026-07-26**; METHODS.md's
  canonical-quantities table has carried both counts as two-instrument since then. This report
  contained the string `two-instrument` **zero times**, so the defect ran **against interest** — the
  published text understated this project's own verification rather than overstating it — and **no
  count, verdict or query specification moves**. Same class as
  [TR-4](TR4_SIZE_OF_THE_SPACE.md) v1.13, which repaired the identical stale label. The honest
  residual TR-11 states is unchanged and is not cured here: **both instruments are project-authored**,
  so no third-party recomputation exists. See [CORRECTIONS.md](../documentation/CORRECTIONS.md).]**
- Tier B: the registry check adds no independence of its own and is not a substitute for Tier A.
  It attests byte-identity to the artifact this project ran, **as attested by registries this
  project published** — so a reader who did not build the ladder from published source is
  trusting the registry, and one who did has already earned Tier A's standing. Stated plainly in
  the report. *(Revised 2026-09-05 with the tier: the earlier wording priced the trust in
  "downloaded blobs", which presumed a distribution that does not exist.)*

**Stage/cost:** the RM section itself is documentation (wave 0, ~$0); `tr12_repro.sh` was the
small wave-2 TO-BUILD and is **BUILT at HEAD** (§8 item 13); the ladder-publication question is **RESOLVED (2026-09-05): SHA registries
are published, the ladder data is not distributed** — so it is no longer a gate on anything.
The registries land automatically with Stage F/G (R-2's 32 per-layer sha registration is
already a pass gate).

---

## 7. Dependency waves + cost (the 2026-07-17 plan; waves 0–2 executed 2026-08/09, wave 3 not run)

| Wave | Gate | Items | Incremental cost [ESTIMATED] |
|---|---|---|---|
| **0 — NOW** (no compiler artifacts needed) | none (small Spot workers only; TO-BUILD code operator-gated) | Q7 verdicts+certs; Q9; Q4(b) SAT C3-min; XA convention pin (n≤13); EW governance + pre-registration; LS TR-8 pair-null; CAP-2 wrapper; RM section text (the ladder-publication question is resolved — registries published, data not distributed — and gates nothing); small-n oracle/atlas prototypes (n≤13) | ~$10–60 |
| **1 — post-Stage-F** (f-ladder on disk; R-2 complete) | R-2 PASS (==N + layer shas) | Q8 gallery; Q4(a,c) sampled census; Q2 REL endpoints + FIRST^C15; REL rank(KW) coordinate; V3 (REL grid) | ~$30–80 |
| **2 — post-Stage-G + O3 ranker** | D3 Stage-G run + CT1.5/CT3.6 ranker gates | Q1 (H3b cert); Q2 O3 endpoints; Q3 profile; Q6 + `--kc-scan`; V1/V2/V4/V5; XA(a); EW-1; CAP-3 IDs; CAP-7 slices | Stage G $60–110 (authorized D3) + t-ladder $60–110 (if standalone; ~$0–30 if co-scheduled as a G channel) + scan $15–50 + queries $10–30 |
| **3 — elective, per-item operator-gated** | operator selection + cost-confirm each | Q5 extremal shortlist ($40–80 ea); LS exact-count shortlist ($250–800); CAP-5 grid ($360–720 for 9 pts); EW-2 screens ($40–105 ea); CAP-4/CAP-8 research | $700–2,400 depending on selection |

**Status at HEAD:** waves 0–2 **ran** — the surfaces in §8, the ladders and their registry checks in
§R Tier B, and the measured results in §12. **Wave 3 did not run** and was never budgeted
(§Wave-status ruling), so every wave-3 item above remains a specification. The dollar bands are the
2026-07-17 estimates (§0 "Cost basis"); realized costs are not restated.

**Total line:** committed-path (waves 0–2, beyond the already-authorized Stage F/G):
**≈ $125–360 [ESTIMATED]**; with the elective wave 3 as scoped: **≈ $0.8–2.8K [ESTIMATED,
NOT AUTHORIZED — per-item cost gates]**. Per the charter, quote per-stage figures only.

---

## 8. The 2026-07-17 TO-BUILD worklist and its build status

All C items = `solve.c` subcommands, argv-dispatched, sha-neutral, NEVER inside `--selftest`
(F-C-5); all under the H-code operator gate; every one ships with reduced-n brute-force gates
before full-31 use. Ordered by wave.

**Build status against public `main` HEAD `d6b1334e`, re-verified 2026-09-23** (previously pinned to
`76e5d680` and re-verified 2026-09-05; that commit is an ancestor of this one, so nothing below was
false, but "HEAD" had come to name a commit several revisions old). The re-verification greps each
row's argv string in the tracked sources — `solve.c`, `sat.py`, `scripts/` — not a working tree. **A surface's presence in the committed source is evidence that it exists; it is not
a certification that it satisfies the requirement stated in its row** — that is what each
surface's own selftest and the committed n = 9 expected blocks are for. This list was written on
2026-07-17 as a worklist; most of it has since shipped.

1. **O3 ranker** `--kc-o3-rank/--kc-o3-unrank` — ALREADY the CT1.5/CT3.6 worklist item; this
   program adds requirements: expose the per-position f·g descent trace (Q3/EW-1); pin
   walk-rank vs class-rank semantics (§0); neighbor-bracket mode (Q1).
   **BUILT at HEAD:** `--kc-o3-rank`, `--kc-o3-unrank`, `--kc-o3-selftest`, `--kc-o3-cert`; the
   per-position descent trace is `--kc-trace`, the neighbour bracket is `--kc-bracket`.
2. `--check-arrangement "h0,...,h63"` — CAP-2/Q7 wrapper (pinned check order, first-violation
   verdict, walk adapter, certificate). Small; wave 0.
   **BUILT at HEAD:** `--check-arrangement`, `--check-arrangement-selftest`.
3. `--kc-scan FDIR GDIR OUT.json --kc-raw` — the f·g join pass emitting the four tables (Q6, V1, V2, V5) with
   G-expansion + the Σ orbit·f·g = N internal gate. Wave 2.
   **BUILT at HEAD:** `--kc-scan`, `--kc-scan-selftest`, `--kc-scan-merge`.
4. `--kc-t-build` (or a value-channel flag on `--kc-g-build`) — the tree-size ladder (XA);
   the per-branch table is then assembled by `--kc-scan FDIR GDIR OUT.json --kc-tdir TDIR --kc-raw` (XA is one
   of `--kc-scan`'s extractors — there is no separate atlas subcommand; see F-19). Wave 2.
   **BUILT at HEAD:** `--kc-t-build`, `--kc-t-check`, `--kc-t-cert`, `--kc-t-selftest`.
5. `--kc-profile "e,x,..."` — 31-row rarity/surprise profile for any walk (Q3/EW-1/V4);
   may be subsumed by item 1's trace mode. Wave 2.
   **BUILT at HEAD:** `--kc-profile`, `--kc-profile-selftest`.
6. `--kc-enum-desc` (descending in-order enumeration) — LAST^C15 (Q2). Trivial. Wave 1–2.
   **BUILT at HEAD:** `--kc-enum-desc`, `--kc-enum-desc-selftest`.
7. `--kc-extremal FUNC DIR` — per-functional DP extremal sweep + witness (Q5 shortlist);
   G-invariance check per functional; reduced-n exhaustive gate mandatory. Wave 3.
   **BUILT at HEAD:** `--kc-extremal`, `--kc-extremal-selftest`. The surface existing does not
   authorise the sweeps: wave 3 is deferred and unbudgeted (see the wave-status ruling).
8. `--kc-oracle` property channels — extend the `--kc-oracle` harness (BASE BUILT, below) with the LS/EW
   count-DP property grammar (violation counters, station counter for ST-* rules). Wave 3.
   **BASE BUILT at HEAD** (`--kc-oracle`, `--kc-oracle-repr`, `--kc-oracle-selftest`); **the LS/EW
   property-channel extension is not present.**
9. `sat.py` C3-min bisection driver (thin loop over the existing C3 encoding; DRAT retention;
   timeout/bracket protocol). Wave 0.
   **PARTLY BUILT at HEAD:** the ≥-side encoding is public (`sat.py --c3-min N`, with `--c3-max`);
   **the bisection driver loop, its DRAT retention and its timeout/bracket protocol are not
   present.**
10. CAP-7 slice-request wrapper + integrity sidecars. Wave 2. **Not present at HEAD.**
11. viz: 5 × `viz/viz_kc_*.md` docs + generation code in `viz/` (extend `report_figures.py`);
    TSV-to-figure only, no new analysis logic in viz. Wave 2.
    **BUILT at HEAD:** all five docs are on public `main` — `viz/viz_kc_field.md`,
    `viz_kc_river.md`, `viz_kc_spectrum.md`, `viz_kc_shells.md`, `viz_kc_grammar.md`.
12. CAP-4 minimal-repair BnB prototype (research; n ≤ 16 benchmark first). Wave 3.
    **Not present at HEAD** — conformance, not slippage: §9 flags this item, it does not promise it.
13. `scripts/tr12_repro.sh` — the RM battery driver: runs every TR-12 query against named
    FDIR/GDIR, diffs each output against the committed expected-output blocks, non-zero exit on
    any mismatch (shell only, no new .c/.py). Wave 2. ⚠ *The diff applies where an expected set exists
    (n=9 today); at n=31 the run mints and asserts rather than diffs — see step 6 above and
    `QUERY_INVENTORY.md` §3.0.*
    **BUILT at HEAD:** `scripts/tr12_repro.sh`, **3,531 lines** at `d6b1334e` (measured
    2026-09-23 with `wc -l`; the "1,570 lines" this row carried was true of `76e5d680` and had
    since more than doubled), with its committed expected blocks under `scripts/tr12_expected/n9/`.

---

## 9. Judged NOT report-grade (and why) — honesty section

- **"Aesthetic-interest" ranks (Q2):** declined entirely — numerology framing risk; any rank is
  O(1) later.
- **C15 midpoint / any C15 exact count:** **PRICED AND DECLINED — not "not computable."**
  *(Corrected 2026-08-25, Q-144/Q-06. The original wording — "not computable (C3 obstruction)" —
  predates the C3 = 16 + 8·G identity, which is a machine-checked Lean theorem
  (`lean/C3Decomposition.lean`, `c3_slot_decomposition`) and dissolves the C3 obstruction outright:
  it turns C3 from a global positional sum into a bounded scalar the DP can carry. The instrument
  exists and is built — `solve --f1-c3-hist --with-c5` (`documentation/SOLVE_C_CLI.md`
  §`--f1-c3-hist`).* **What is true is that the run was priced and then PERMANENTLY DECLINED, on
  cost.** *(Public anchors, in place of an internal note. The capability correction:
  `reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md` §10(ii) **v1.5, 2026-07-21**
  withdrew the "open structural obstruction … no feasible exact design in hand" wording and
  replaced it with "the remaining barrier is footprint **cost**, not structure"; the same file's
  changelog carries the withdrawal verbatim, and `documentation/HISTORY.md` records the
  supersession in the 2026-07-16/21 entry. **No dollar figure or footprint band for this run is
  restated here, and that is itself a published position, not an omission:** TR-11 **v1.10,
  2026-07-22** withdrew its own §10(ii) compute-cost figures — the footprint multiplier and the
  wall-time band derive from the same entry-count scaling, so their uncertainties are correlated
  and the band was not a ceiling — and resolved to say only that such a run is *computationally
  expensive, not bounded above*; and `documentation/CAMPAIGN_METHODOLOGY.md` §7 rule 9 sets this
  project's bar for putting any cost total into a published document at an **itemized** ledger —
  VM hours by SKU, disk-months, closeout. A one-line price quoted from an internal note clears
  neither. The earlier revision of this bullet quoted a dollar band and an operator price quote for
  this run; both are withdrawn here under those two rules, and **the dollar figures are redacted
  rather than restated** — following `reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md`
  v1.10, which withdrew its own cost band and redacted the dollar figures from the changelog row
  that had carried it, while leaving the footprint and wall-time figures standing. A withdrawal
  that requotes the number publishes it. **The decision those figures described — priced,
  declined, permanently — is unchanged.*)* Claiming a sampled midpoint would still imply
  false precision,
  so it remains **omitted rather than estimated** — but the reason is **cost, not capability**, and
  the two must never be conflated in anything published. ⚠ *Overstating a limit in the direction that
  flatters the author is a reporting error this document does not make: where a quantity is absent,
  the reason given is cost or capability — whichever is actually true.*
- **Edit-distance-to-KW extremal (KW's nearest SUPER neighbor):** 🔴 **CLOSED, and the row's own
  "interim bound" already equalled the answer (QSET-2 finding 2, 2026-09-06).** `edit_dist_kw` is
  pair-slot Hamming distance, and two distinct permutations differ in at least two slots, so **2 is
  the structural floor** for a distinct key. It is attained: the public 100 T log
  `runs/20260419_100T_d3_d128westus3/analyze_output.log.gz` (committed 2026-04-20) prints
  `[ 12] dist=2 rec#104178045`, and an explicit C15 witness at distance 2 was found by execution
  during the review. ⚠ *That witness is no longer execution-only: it was appended to
  [`reports/certificates/c3_positional_witnesses.txt`](../reports/certificates/c3_positional_witnesses.txt)
  on 2026-09-13 (V3B-03#11) as the `DISTANCE-2 C15 WITNESS` block — King Wen with pair-slots 1 and
  13 exchanged, `edit_dist_kw = 2`, C3 = 680, `verdict SUPER: IN` and `C15: IN`, carrying its full
  `--check-arrangement` transcript. It is recorded as a commented block rather than as a `G=`/`C3=`
  witness row because row `a0_q4b` grades on this file's row COUNT, and a 43rd row would change a
  frozen n=9 golden.* Under the alternative "distinct walk" reading the minimum is **0**
  (`python3 verify.py --check-flips` → 9 of 31 single-orientation flips remain valid). Either way
  this needed no plain-DP sizing exercise. The original text, retained: it required the plain
  (unquotiented) DP with a ×32 channel — sizing unknown, possibly infeasible; DEFERRED with the
  560T-sample minimum as the standing bound. Flagged, not promised.
- **Deep-tail exact counts for KW-extracted templates (ccn4-class, D-B1-class):** computable,
  but evidentially void per the circularity discipline — if run, published DESCRIPTIVELY only,
  never as a headline p; most fail the report-grade bar regardless of exactness.
- **Per-layer argmin "loneliest corridor" trivia (Q6 tail):** figure fodder (V2/V5), not
  headline claims — a minimum-mass corridor is expected in any large DP and distinguishes
  nothing by itself.
- **CAP-8 connectivity at full-31:** open research; only small-n exact results exist-able;
  excluded from TR-12.
- **CAP-4 minimal-repair for arbitrary inputs:** unbounded runtime; research-grade until
  benchmarked; the SAT path remains the certified instrument for named instances.
- **EW screens without pre-registration:** any tail computed before its family is locked is
  DISCARDED by protocol — running ahead of governance is worse than not running.

---

## Attribution

*Attribution: direction and the distinguished-elements/capabilities/exploration programs are the
operator's; the query specifications, feasibility triage, and this document are by Claude
(Fable 5), 2026-07-17, building on prior Fable/Opus session work (compiler, Stage-G engine,
FH-1, TR suite) — per-artifact attribution in the cited sources. Technique-level prior art is
classical throughout (Nijenhuis–Wilf ranking; knowledge-compilation query taxonomies:
Bryant/Minato/Darwiche; MDL: Rissanen) — no novelty claimed for any mechanism; the contribution
is the instantiation and the exactness discipline. Errors are Claude's; corrections invited.
The 2026-09-05 publication pass — figure/command audit, the corrections
named in place, and the removal of internal build-status scaffolding that had gone stale — is by
Claude (Opus 5); the underlying specifications are unchanged by it. A second 2026-09-05 pass, also
by Claude (Opus 5), replaced this document's citations to internal working notes with **public
anchors** — a published document, a runnable command, or a code site that makes the same fact
checkable — withdrew the one figure that had no public basis, recorded the one citation for which
no public anchor exists as exactly that, resolved the ladder-publication question (per-layer SHA
registries are published; the ladder data is not distributed by this project), and recorded the
H3b specification amendment in §0. No query definition, no verdict, and no cost band other than
the withdrawn one changed in either pass.*

*The 2026-09-23 finalization pass — the six house-format elements (Executive summary, Abstract,
Sections map, Verification Guide, the METHODS.md line and the title form), the removal of the draft
byline and STATUS box, the closing of stale and forward-looking tense throughout, and the embedding
of the three rendered figures — is by Claude (Opus 5), against a format-parity and staleness review
by Claude (Fable 5.1). No query definition, no verdict, no count and no published figure changed in
that pass.*


## Wave-status ruling (operator, 2026-07-17)
- **Waves 0–2: approved in principle** (~$125–360 total new compute beyond the authorized R-ladder), sequenced behind the campaign; wave 2's t-ladder doubles as the byte-level gate upgrade — until it runs, the promotion uses the pre-declared degraded-rank labeling. *(t-ladder built 2026-09-06; 32/32 logical and 65/65 container digests verified, §R Tier B.)*
- **Wave 3: DEFERRED — NOT BUDGETED** ("I can't afford wave 3"). Every wave-3 item is independently gated and may be cherry-picked individually later (e.g., a 5-rule literature-sweep slice ≈ $50–100 instead of the full ~70-rule sweep at $250–800). No wave-3 item is required for the campaign, the promotion, or TR-12 v1.0 (waves 0–1 suffice for a lean TR-12; wave 2 makes it the full report).

---

## 10. Capstone additions (operator-blessed 2026-07-17; the DONE-contract set)

*From the 2026-07-17 completeness analysis. That analysis is an internal planning pass with **no
public counterpart** — searched for, not found — so no pointer is given: the items below are a
worklist, they assert nothing a reader must check, and a citation to a document nobody can open
would only look like evidence. Items A–D are
the MUST-ADD cheap set; E is the one with budget; F/G are versioned updates to OTHER TRs
recorded here for the worklist. TR-13 stays reserved solely for an EW-promoted constraint.*

### A. §Open Problems (the handoff section) — MUST
Every unanswered question precisely stated + classified (conjecture / obstruction / unpriced
computation / research direction): exact |C15| (an **unpriced-computation** entry, not an
obstruction — see §9: the C3 = 16 + 8·G identity dissolved the structural barrier and the run
was declined on cost), C3-min if SAT leaves a bracket, CAP-8 connectivity, plain-DP extremals
(edit-distance-to-KW), the unexplained bits (TR-9 — published range **105.4–139.1**; ~126 is the
C1–C5-layer reading of the same residual and is labelled as such wherever it appears), anything
post-Aug-8. **Cost:** $0
(writing). **Verification:** each entry cites the doc/section where its partial state lives.
This section is the pressure valve of the DONE contract.

### B. §Confidence Ledger — MUST
One table: every headline number in TR-1..12, graded machine-checked / proven / sha-witnessed
exact / estimated-with-CI / scoped-sample, with the artifact that backs it (Lean sha, canonical
sha, DRAT cert, CI method). **Cost:** $0 (compilation + audit pass). **Verification:** each row
links to its source; the hostile-referee pass audits this table first.

### C. Distributional upgrade — exact-uniform observable battery — MUST
Re-run the standard observable battery (DISTRIBUTIONAL_ANALYSIS.md set + TR-1/2 rule stats)
under EXACT-uniform `--kc-sample` over SUPER (the prior versions are enumeration-slice-scoped).
KW's joint/marginal percentiles under the true measure; retires the slice-bias objection.
**Stage:** post-F. **Cost:** ≈ $10–20 (rides Q4's sampling infrastructure; same walks, more
evaluators). **Verification:** two-language evaluation (solve.py) on a sub-sample; CIs stated;
slice-vs-uniform deltas reported honestly.

### D. Small-universe appendix (n=9 / n=13 worked worlds) — MUST
The fully-solved miniatures as pedagogy: complete n=9 universe (**26,112 walks**, byte-exhaustive,
cross-engine byte-matched — the walk count is the published figure, `documentation/VERIFY.md`
§"Every published EXACT count"; **no class count is quoted**, because no published command emits
one) + n=13 count-witnessed instance; every TR-12
claim-TYPE demonstrated at laptop scale with commands. **Cost:** $0 (artifacts exist).
**Verification:** the §R small-tier commands ARE the appendix; reader-runnable in minutes.

### E. The constraint lattice ("which constraint does the work") — SHOULD (the budget item)
The 2^5 intersection anatomy. **Today the suite publishes at least three exact cells of the 2⁵
lattice and one estimate** — C1∩C2∩C4 (TR-11 abstract, 7.5706×10⁴¹), C1∩C2∩C4∩C5 (TR-11 §9), and
the closed-form C1∩C4 / C1 nulls whose exact G-laws `verify.py --check-null-g [--unpinned]` prints
(which make C1∩C3∩C4 and C1∩C3 exact rationals × closed-form totals); the one estimate is TR-4's
C15. ⚠ *(Corrected 2026-09-12, V3A-086#9: this read "publishes exactly two cells (TR-11 exact
C1C2C4C5; TR-4 estimated C15)", which understates the suite's own published exact results — TR-11's
abstract publishes |C1∩C2∩C4| exactly, with its command, and TR-4 tabulates it as a calibrated
layer.)* Plan: (1) SIZING PASS first — which non-C3 cells the TR-11
DP method computes exactly and at what cost (some cells may be far cheaper than Stage F;
some larger-count cells may be pricier; no cell is run before its quote); (2) exact cells
within budget + validated-estimator values for the rest, ALL cells labeled by method;
(3) per-constraint marginal kill-factors at each lattice level — the exact-arithmetic
completion of TR-9's MDL story. **Stage:** post-F (reuses machinery). **Cost:** sizing pass
≈ $0 (analysis); exact cells $40–140 EACH [wide-hedged until sized] — operator picks the set
inside the August envelope; estimator cells ≈ $5–20 total. **Verification:** each exact cell
mod-24 gated + subset-monotonicity cross-checks (cell ⊇ its supersets' counts); estimator
cells carry the TR-11-validated calibration note.

### F. TR-5 v-next: symmetry completeness — versioned update (not TR-12)
Prove order-48 is the FULL symmetry: no additional hexagram-set permutation preserves the
C1–C5 predicate family (structural argument and/or pair-level exhaustive/SAT check). Closes
"how do you know you quotiented by everything?" — made concrete by TR-11's ÷24 exactness.
**Cost:** ≈ $0–10. **Verification:** proof text + machine check where feasible (Lean or SAT
cert per the Fable-work rule).

### G. TR-4 v-next: estimator recalibration — versioned update (not TR-12)
TR-11's exact count falls inside the Knuth estimator's stated ±0.01 % envelope at the C1∩C2∩C4∩C5
cell (the ratio 0.999956 is a five-significant-figure rounding gap, TR-11 v1.4). It **validates**
that envelope; it does **not** tighten any interval, and nothing licenses a tightened error bar on
the uncalibrated C3 layer — TR-4 §"Three points are consistency, not an error model" says so in
terms. ⚠ *(Corrected 2026-09-12, V3A-086#6: this read "retroactively tightens every published
estimate", promising a statistical tightening the cited reports deny.)* One table: each prior
estimate, its method, and its **calibration status** — not a revised CI.
**Cost:** $0 (writing + arithmetic). **Verification:** cites TR-11 §; no new computation.

---

## 11. Prior-art refresh addendum (2026-07-31) — queries the July prior-art sweep opens/refines

*Folded in 2026-07-31 after the July prior-art sweep + the #32 Lean
closeout. Assessment basis: the sharpest prior-art frameworks the sweep surfaced are **Ouyang
1990/1992** (the hexagram set as (ℤ/2)⁶ with explicit subgroups and cosets — the fullest algebraic
framing) and **Suenaga 2012** (an **independent arrival** at counting the arrangement space,
1395 = [6,3]₂ Gaussian binomial — ⚠ *this read "the earliest to START the count" until 2026-09-12
(V3A-086#8). That is a firstness claim, and `documentation/CITATIONS.md` §suenaga2012 **withdrew
exactly it on 2026-08-28**, naming Huang 1997 (which transmits an earlier closed-form count) and
Chen 2007 as earlier. No firstness is asserted here; the supported claim is independence, which is
also the form TR-11's novelty note already uses*);
plus the now-kernel-only DIV-24 theorems (`twenty_four_dvd_*`, #32) and the equivariance ceiling
(P ≤ 1/24). None of this opens a new heavy-compute program — the flagship queries (Q1–Q3, Q6, Q8)
and the exact/estimate boundary are UNCHANGED (the sweep did not make |C15| exact). It adds ONE new
query family and refines four existing items. All items below are labeled by space + method per §0.*

### Q10 (NEW). Orbit / (ℤ/2)⁶-coset census — the Ouyang-framing query
- **Definition (SUPER, exact part).** The record-level action is free with 24-element orbits
  (TR-5; `twenty_four_dvd_*` now **kernel-only**, #32), so |SUPER|/24 and every layer count /24 are
  exact integers. (a) **Orbit census:** per g-ladder layer, the exact number of distinct 24-orbits,
  **computed by canonical-form census — NOT by dividing the layer mass by 24**. ⚠ *(Matched to the
  battery 2026-09-12, V3B-03#41. This promised "the exact number of distinct 24-orbits per layer …
  **and KW's orbit's rank among them**", and the run produces neither as written. What row `c_q10a`
  delivers is: N/24 **stated once** — a record-level identity, not a walk-orbit count — a per-layer
  mod-24 gate, and a per-layer **STATE** census by G-orbit-size class plus a branching histogram,
  transcribed from the f-ladder sidecars. The orbit-rank leg is measured separately as row
  `c_q10a_kwrank`, and the value that row is expected to emit at n=31 is
  **`TR12_Q10A_KWRANK=EMPTY:class-rank-uncomputable-under-kw-labels`** — forced to 0 by KW-derived
  labels, so it is a null result, not a rank. ⚠ **Corrected 2026-09-13 (V3B-03#41): this read "its
  **measured** value is", and nothing has measured it.** The only run to date is at n=9, where the
  same producer returns `NONVACUOUS:anchor-is-not-the-o3-least-object`. The `EMPTY:` value above is
  a **FORCED PREDICTION at n=31** — forced by the KW-derived labelling (§Q1's endpoint case) and
  therefore certain, which is not the same thing as measured. It becomes a measured null on the
  first full-31 run and not before.)* ⚠ *(Updated 2026-09-23, v1.11: that run has since happened.
  The full-31 battery of 2026-09-22 emitted
  `TR12_Q10A_KWRANK=EMPTY:class-rank-uncomputable-under-kw-labels`, so this is now a **measured
  null** rather than a prediction — and the receipt saying so is published at
  [`evidence/tr12/VERDICTS_n31_20260922.txt`](evidence/tr12/VERDICTS_n31_20260922.txt), line 89.
  The distinction the 2026-09-13 correction drew was the right one and is kept in place above;
  what changed is which side of it this value sits on.)* `layer walk-mass / 24` is not an orbit count and this document said it was:
  measured exhaustively at n=9: 432 records give **18 record-orbits** (432/24) and the 26,112 walks
  give **544 walk-orbits**, while N/24 = **1088** is neither. TR-11 §2's precision note already states
  why — *at the orientation-explicit sequence level orbits have size 48, so N/24 is 2× the
  sequence-orbit count* — and 1088 = 2 × 544 exactly. 24 is the **record-level** divisor; applying it
  to a walk-level mass counts nothing. TR-11 was right and this line did not carry its qualifier; a global "24 ∣ count" self-check on
  every layer. (b) **Coset-structured census (the Ouyang lens):** classify solution mass by position
  in the (ℤ/2)⁶ subgroup/coset lattice that Ouyang 1992 uses for the hexagram algebra — i.e. tabulate
  how walk-mass distributes across the cosets of the relevant XOR-translation subgroups, and whether
  KW's coset is distinguished. 🔴 **(b)'s SUBGROUP SET AND COSET-ID MAP ARE UNDEFINED, and must be
  defined before `--kc-coset-census` can even be specified** *(2026-09-12, V3B-03#41).* "The
  relevant XOR-translation subgroups" names no particular set of subgroups, and "coset id via the
  XOR structure" names no map from a canonical mask to a coset id — so there is nothing here a
  builder could implement. `--kc-coset-census` does not exist (`git grep -c` → 0,
  `documentation/QUERY_INVENTORY.md`), and `TR12_Q10B=PENDING:--kc-coset-census` is pinned in the
  harness. **(b) does not need a producer yet; it needs a definition.**
  **Honesty label:** (a) is EXACT and cheap; (b) is **EXPLORATORY
  (EW-class, FRONTIER discipline)** — it may reveal a real concentration or may be flat, and "flat"
  is a reportable negative (feeds Q9), NOT a failure. No structural claim is pre-committed.
- **Mechanism.** (a) rides the existing `--kc-g-check` mass identity (Σ orbit·f·g = N already computed
  in the scan pass) — the /24 orbit counts are a projection of numbers the ladder already produces; no
  new subcommand strictly needed (a thin `--kc-orbit-census` wrapper at most). (b) **TO-BUILD** light:
  a coset-labeling of the transversal (map each canonical mask to its (ℤ/2)⁶ coset id via the XOR
  structure — but NOT via `applyPerm`/`pairKey`.
  ⚠ **[CORRECTED 2026-09-20 — this read "the XOR structure already in `applyPerm`/`pairKey`", and
  both symbols are **Lean definitions**, not engine helpers: `lean/Automorphism.lean:127` defines
  `applyPerm` and `:131` defines `pairKey`. Measured on `origin/main`: `applyPerm` occurs **0**
  times in `solve.c` under every casing tried (`applyPerm`, `applyperm`, `APPLYPERM`, `ApplyPerm`,
  `apply_perm`; control `main` = 38, `zzznotreal` = 0). The `PairKey` struct at `solve.c:44878` is
  an unrelated `qsort` sort-record (`{ unsigned char pi[32]; long long idx; }`) with no coset
  semantics, so calling this a misspelling would point the reader at real machinery that does the
  wrong thing. The engine's actual XOR/coset tables are `F1Coset`/`f1_g24[24]`
  (`solve.c:13944-14074`) and `F1UCoset`/`f1u_cos[48]` (`:38439-38586`), and **neither is
  referenced anywhere on the `--kc-scan` path**.]** Aggregating the scan-pass mass table by coset
  id is therefore not possible at all — see the withdrawn cost line below.
- **Stage:** post-G (needs the g-ladder). **Cost:** (a) ≈ $1–5 (projection of existing tables);
  (b) **ESTIMATE WITHDRAWN.**
  ⚠ **[CORRECTED 2026-09-20 — this read "≈ $5–15 (one extra aggregation over the scan pass). Rides
  Q6's `--kc-scan`; no new heavy pass." It is **withdrawn rather than re-priced**, because it
  understated by omitting FEASIBILITY, not by mis-pricing. `solve.c:24990` names what the scan pass
  touches — `flow[k]`, `cls[k][.]`, `qmarg[k][.]`, `rawmarg[k][.]`, `fmass[k]` — every one keyed by
  layer and by distance class or quotient, with **no hexagram-identity axis**. No coset projection
  can be aggregated out of those tables at any price, so (b) does not ride Q6's scan pass. No
  replacement figure is offered: (b) needs a definition before it can honestly be costed.]**
  ⚠ **[NARROWED 2026-09-21, CX-58 — the feasibility clause above reaches past the five tables it
  names.** Those five accumulators are what the cited `--kc-layers` chunking comment lists, and
  none carries hexagram identity; but the same scan pass, under `--kc-raw`, also accumulates the
  per-layer 64×64 raw kernel `T->kern` — emitted as `kernel`, cells `m<a>_<b>`, exit hexagram ×
  entry hexagram — which the V5 row of §2 has said since 2026-09-12, and which the n=31 atlas
  carries at every layer (`KERNEL_EVERY_LAYER_SUMS_TO_N=PASS`, §12). For the **step-difference**
  reading of (b) — cosets of `x = a ⊕ b` under an XOR-translation subgroup — a coset projection
  is a finite sum of persisted kernel cells: zero data cost, no ladder. For the reading the
  Mechanism bullet above specifies — a coset id per canonical **mask** — the kernel does not
  help: a kernel cell is one transition, not a prefix state, and no per-mask table is persisted.
  Under **either** reading the blocker is the one already stated: the subgroup set and coset-id
  map are undefined, `--kc-coset-census` does not exist, and `TR12_Q10B=PENDING:--kc-coset-census`
  stays pinned. The conclusion — no replacement figure; a definition first — stands. See §12.8
  and [CORRECTIONS.md](../documentation/CORRECTIONS.md) CX-58.]**
- **Output/verification:** `tr12/q10_orbit_census.tsv` (per-layer orbit counts + the /24 integrality
  gate — now Lean-kernel-backed) + `<artifact-root>/q10_coset_census.tsv` (mass by coset id + KW's coset).
  **Gate — and WHICH counted object it runs on, because "every layer count" named none.**
  ⚠ *(Corrected 2026-09-13, V3B-03#40. This read "Gate: every layer count ≡ 0 (mod 24) EXACTLY
  (dispositive; ties to `twenty_four_dvd_*`)" and never said what a "layer count" was. Under the
  **prefix-mass** reading the claim is simply false, and a reader can falsify it from this
  repository's own committed golden in one line of arithmetic: `scripts/tr12_expected/n9/c_q10a.txt`
  records per-layer `mass_total` of 1, 4, 28, 212, 894, 3580, 12784, 18272, 26720, 26112 — i.e.
  1, 4, 4, 20, 6, 4, 16, 8, 8, 0 (mod 24) — so **only the final layer** is ≡ 0 (mod 24). Under the
  **flow** reading it is true but not a discovery, since `flow(k) = N` is itself an atlas identity.
  A gate advertised as dispositive must say which object it gates.)* The three objects, each with
  its own divisor:
  **(a) `flow(k)` = Σ_{s ∈ layer k} f(s)·g(s) = N** at every layer — walk-level. Every complete walk
  crosses every layer exactly once, so this is the atlas's own cut identity restated per layer, and
  `24 ∣ flow(k)` follows from `24 ∣ N`, not from anything about layer k. Sequence orbits have size
  48 (TR-11 §2), so in fact `48 ∣ flow(k)`. **This is the gate**; it is an identity, and it is
  checked independently by `--kc-g-check`, which prints the f·g cut identity == N at every layer.
  **(b) per-layer per-class mass `m[k,d]`** — walk-level and G-closed, hence `48 ∣ m[k,d]`.
  Per-branch masses are **not** G-closed: they are reported, not gated (measured, branch 0 = 2368 ≡
  16 mod 24 — which is why extending the gate to "every headline count" makes a *correct* atlas
  fail; see the XA row in §11's refinement table).
  **(c) the sidecar `orbit_size_census`** — a census of DP **states** by stabiliser size over the
  f-ladder canonical masks. It counts neither walks nor records, and no mod-24 gate applies to it.
  Note also that Q10(a)'s **record-orbit** census is not emitted at n=31 by this run: the n=31
  f ladder carries schema-v1 sidecars, so row `c_q10a` reports that column `NA:schema-v1-sidecar`
  and gates every other field. Σ over cosets = layer mass.
  Cross-check: n ≤ 13 exhaustive orbit counts. **Cite Ouyang 1990/1992 (framework) +
  Suenaga 2012 (independent counting arrival) at the query site** — this is the query that visibly extends their lineage.

### Refinements to existing queries (no new compute)
| Query | Refinement (source) | Action |
|---|---|---|
| **Q4** (C3 census) | C3 = 16 + 8·G identity CLOSED (kernel, `C3Decomposition.lean`). Beyond the already-adopted "bisect on integer G / bracket [12,47] / mod-8 lattice" correction, publish an **EXACT** G-channel companion to the (estimated) C15 histogram: the C1∩C4 null law of G — support **[12, 228]**, **E[G] = 128** (⇒ E[C3] = 1040), **P(G ≤ 95) = 641983711307479/7919632354008375 ≈ 8.106%** — **exact of the DP-defined law** via the G-channel DP (kernel-checked, `C3Decomposition.lean`). ⚠ **[CORRECTED 2026-09-19, V3B-03#42 — this read "exact via the G-channel DP", with no qualifier. The number is not wrong; the **label** was. What is kernel-proved is a fact about the **DP-defined law**: at production size (12 couples, 31 slots) there is **no theorem asserting that bin g of the DP histogram counts the permutations whose G equals g** — the DP→permutation-count bridge is machine-checked only at the toy sizes (2,1,5), (2,3,7) and (3,1,7), so reading the figure as a probability over the 31! pair-orders rests on that bridge plus the DP-free E[G] = 128 linearity cross-check, not on a production-size semantic theorem. That argument is already stated in full at [lean/README.md](../lean/README.md) (the "What is NOT kernel-proved, stated plainly" note, lines 90-99), which this report never cited: it carried `DP-defined` **zero times**, so a reader of this row saw "exact" with no pointer. The rational and the ≈8.106% are **unchanged** and are published in nine public files; `verify.py --check-null-g` agreeing is independent corroboration, not the missing theorem. See [CORRECTIONS.md](../documentation/CORRECTIONS.md).]** One column moves estimate→exact **at the DP-law layer**; the C15-conditioned histogram stays labeled ESTIMATE. | Add exact-G companion table + the ceiling-is-KW-defined circularity note (already in Q4). |
| **Q9** (reportable negatives) | (i) Add the **equivariance ceiling** (P(KW-record) ≤ 1/24 for ANY G-invariant generator; `KingWen.lean`, kernel-only) as a strong new negative — no G-invariant scoring can concentrate on KW beyond 1/24. (ii) The **8 forced literature rules** (Find 1 → `C1RuleConstants.lean`) are now PROVEN constants of the entire C1 space — **Lean-proven modulo a transcription step whose check is attested only**, a qualifier that is load-bearing here: Lean proves constancy of the `countP` **forms** defined in that file, and identifying those forms with the executable registry rules (`reg_*` in `solve.py`, `score_registry` in `solve.c`) is a **NON-Lean step**. Its one numerical check, a drive of the repo's own `reg_*` over 5,449 structured C1 sequences, is **attested, not reproducible**: the script is not in the repo. The limitation is stated in [lean/README.md](../lean/README.md), in the bullet "The eight 'forced' literature rules are proven, not just measured" (lines 61-72 at this revision). ⚠ **[CORRECTED 2026-09-24 (Q-780) — this read "Lean-proven modulo a validated transcription" and "validated numerically by driving the repo's own `reg_*` …", and cited lean/README.md "(lines 62-70)". lean/README.md dropped "validated" on 2026-09-24 (Q-778, CX-84), because the check behind it is a scratchpad script that is not in the repo, and its bullet now sits at lines 61-72. The 2026-09-19 note below and the v1.5 revision row quote the README as it read on 2026-09-19. They are kept as written.]** The theorem itself is kernel-checked. ⚠ **[CORRECTED 2026-09-19, V3B-03#43 — this read "are now PROVEN constants of the entire C1 space", unqualified, and "PROVEN" so written reaches further than the artifact supports. The Lean theorem is real and kernel-checked, but it is a theorem about the `countP` forms; carrying it to the eight executable registry rules is the non-Lean transcription step above, which [lean/README.md](../lean/README.md) discloses at lines 62-70 as "Lean-proven **modulo a validated transcription**". The validator for that step — a 5,449-sequence drive of the repo's own `reg_*` — is a **scratchpad script with zero occurrences in the public tree** (measured against a positive control of one for `verify.py`, which proves the search could find a tracked script), so the check that carries the theorem to the executable rules is **not reproducible by a reader today**. This is a **label and reproducibility** defect: no count, rate or verdict moves, and the eight rules still measure at rate 1.0 under enumeration. See [CORRECTIONS.md](../documentation/CORRECTIONS.md).]** So they move from Q9's "candidates for proof upgrade (LS-1)" into the theorem class **with that transcription caveat attached**. | Promote the 8 rules; add the ceiling negative with its hypothesis-class scope stated. |
| **XA** (Exhaustion Atlas) | Add an explicit **24-divisibility integrity self-check** on every **G-closed** headline count (⚠ NOT on every count: per-branch masses are not G-closed — measured, branch 0 = 2368 ≡ 16 (mod 24) — so extending this gate as first written makes a *correct* atlas fail) — now **Lean-kernel-backed** (`twenty_four_dvd_*`, no longer native_decide, #32). Cheap, dispositive, and it hardens the whole count cascade. | Add the mod-24 gate row to XA's integrity block; cite the kernel theorem. |
| **LS / XA framing** | Express the counting cascade in the **Gaussian-binomial / [6,3]₂ lineage** which Suenaga 2012 exhibits (1395 = [6,3]₂), so the Atlas visibly EXTENDS a known partial count rather than presenting a bare number. | Add the q-binomial framing note + Ouyang 1992 / Suenaga 2012 citations to LS and XA provenance. |

### Not changed (stated for the record)
The exact/estimate boundary is UNCHANGED: |C1–C5| and |C1–C7| remain **estimates** (compute-bound;
Lean/SAT prove properties, not counts). Q1–Q3, Q6, Q8 are untouched. This addendum is additive polish
plus Q10 — not a re-scoping. **Citations to add project-wide where a symmetry/counting claim is made:**
Ouyang 1990/1992, Zhang 1994/1998/2000, Suenaga 2012, Luo 2015 (already in CITATIONS.md post-sweep).

---

## 12. What the n=31 atlas establishes — measured from the atlas alone (2026-09-21)

*Added 2026-09-21 by Claude (Fable 5.1). Everything in this section is a MEASURED quantity over
SUPER — walk-uniform, N-weighted — read off the n=31 atlas. §12.1–§12.8 come from one public
command and no other input; §12.10 names its own second command and reads a published TR-7
evidence file besides (corrected 2026-09-22, v1.8 — this sentence claimed "one public command and
no other input" for the whole section, and §12.10 has neither property).
It is a results section appended to a question set, and it is labelled as such: no query
definition above changes, and nothing here is a p-value. Where a null is stated it is stated as a
null, and where a result is negative it is reported as a negative. Cost is not discussed here.*

**The input, pinned.** The atlas is §R Tier A step 4's output at full-31 —
`./solve --kc-scan FDIR GDIR atlas.json --kc-tdir TDIR --kc-raw` — carrying the `version` 2
logging tables (`counts`, `hist`, `outdeg`, `kwrank`, `rid_mass`, `digits`, `extrema` and the raw
64×64 `kernel`, logged 2026-09-11 so that questions could be asked after the one expensive
pass): `type=roae-kc-scan-atlas`, `n=31`, 31 layers, **5,978,126 B**, sha256
**`9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558`**, `engine_git`
**`8af5e55c8eed`** (on this repository's `main`), `engine_source_sha`
`ed9c65b24e9f2ff9cab05eef9f817dca9453ea2edf25b9186fc1f667abe063c9` (the sha256 of the `solve.c`
that wrote it), its 14 internal gates all `true` with `fails: 0`, its 5 tail checks all `PASS`.
**The file itself is distributed** at `runs/20260906_kc_ladders_n31/atlas_n31.json`, and its raw
sha256 is the pin above; `python3 solve.py --atlas-probe runs/20260906_kc_ladders_n31/atlas_n31.json`
prints the §12.9 tokens from it. The ladders it was scanned from are not distributed.
⚠ *(corrected 2026-09-24: this read "The file itself is not distributed with this report; its digest
is." The file has been tracked since v1.10 (2026-09-23), and this report's Confidence Ledger, its
v1.11 revision row and `reports/METHODS.md` §Artifact access already said so. The digest paragraph
below still governs what a **rebuild** can be checked against.)*

⚠ **What that digest does and does not promise — corrected 2026-09-22 (v1.8, CX-61).** This
paragraph read *"its digest is, so a Tier-A rebuild … can be checked against it"*, and that
contract was **unsatisfiable as printed**. The sha256 is over the file as written, and the atlas
embeds its own provenance inside those bytes: `engine_git`, `engine_source_sha`, and the
**basenames of the three ladder directories** — `"fdir": "run_f"`, `"gdir": "run_g"`,
`"tdir": "run_t"`, the argv basenames of the production run, not the `FDIR`/`GDIR`/`TDIR` that §R
writes. So the raw digest reproduces only for a reader who builds with the identity flags (§R
Tier A step 2, which until this revision omitted them), whose binary is stamped with the same
`engine_git` string, **and** who happens to name their directories `run_f`, `run_g`, `run_t`. The
last two are not properties of the mathematics. **What a reproducer can check instead** is the
provenance-normalised content digest: replace those five string values with `"-"` in the bytes and
hash the result —
**`923faa1b097cd364bbedd58044963df971809bf1c3d27765d29e84ae9f73071a`** (measured 2026-09-22 on the
pinned file; the raw digest above is unaffected). That digest is invariant to the build stamp and
to what the reader called their directories, and it is the one a Tier-A rebuild (the ~47 h merge
of v1.4, once the ladders exist) can actually be checked against.

**One command reproduces every figure in §12.1–§12.8**, as whole-line `KEY=value` tokens matched with
`grep -Fqx`, never by output shape:

```
python3 solve.py --atlas-probe atlas_n31.json      # ATLAS_PROBE=PASS, ATLAS_PROBE_FAILS=0, rc 0
```

The probe re-sums every table it reads against N and against the atlas's own gates before it
prints a figure that depends on that table; the one statistic that needs a null is also evaluated
against a deliberately wrong null, so the reader can see the statistic discriminates; and the
King Wen cross-checks (`REF_WALK_IS_KING_WEN=PASS`, `REF_WALK_TRANSITIONS_MATCH_KW_CLS=PASS`)
establish that the walk the atlas's `kwrank` table tracks is King Wen at this n. The same command
runs at laptop scale on the n=9 atlas of the Tier-C recipe — `./solve --kc-build f --f1-pairs 9`,
`--kc-g-build g --f1-pairs 9`, `--kc-t-build f t`, `--kc-scan f g atlas9.json --kc-tdir t
--kc-raw` — where the King Wen legs print `SKIP:n=9` (below full-31 the tracked walk is the
reduced universe's O3 midpoint, `REF_WALK_SOURCE=O3-MIDPOINT`); `tests.py TestAtlasProbe` builds
exactly that atlas, requires `ATLAS_PROBE=PASS` on it, and requires the probe to go red on a
perturbed class mass and to refuse a quotient-only atlas. Every token is named in
`documentation/SOLVE_PY_CLI.md`.

### 12.1 The C5 budget is a run parameter, and the small-n class zeros are its consequence

Σ_k m_k(d) = b0(d)·N exactly for every class d — every walk spends class d exactly b0(d)
times — so the `by_class` column sums recover the run's budget: `B0_COLUMN_SUMS_EXACT_MULTIPLES_OF_N=PASS`,
**`B0_FROM_COLUMN_SUMS=2,8,13,7,1`**. That is King Wen's own boundary multiset, which is what
full-31 is *run at*, not something the ladders derive: `documentation/F1C5_LAYER_FORMAT.md`'s
manifest row gives `b0=2,8,13,7,1` for full-31, and TR-11 §5 (v1.8) records that the Step-1
first-completion DFS returns (2,7,13,8,1) at full-31, so the budget is set to KW's by
construction. The same line, `b0=2,8,13,7,1`, is what the f- and t-ladder manifests of the
2026-09 ladders carry, so a Tier-A reproducer meets the vector three times — in the manifests
of the ladders they build, in the column sums of the atlas they assemble, and here. **Reduced
runs use a different budget** — the deterministic-DFS witness multiset (same file, same row) —
and at n=9 it is **`B0_FROM_COLUMN_SUMS=2,5,0,2,0`** (the n=9 rehearsal, pinned in `tests.py`).
The transition rule is one predicate, `if (cls < 0 || kc->B.dig[cls][rid] >= kc->B.b0[cls])
continue;` (`kc_brute_rec`; the same line sits in `kc_h_prefix_rec`, `kc_validate` and eight
further sites — cited by symbol because line numbers drift): a class whose budget component is 0
is never used. So a reduced-n atlas in which classes d3 and d6 carry zero mass at every layer is
reporting its budget, not a property of the ladders, and the question does not arise at n=31:
all five classes are nonzero at every layer k ≥ 1 (`CLASSES_WITH_ZERO_MASS_AT_SOME_LAYER_K_GE_1=NONE`;
`d3,d6` at n=9), d3 is the largest class at every layer (`LARGEST_CLASS_SET_OVER_LAYERS=d3`, with
**`D3_MIN_LAYER_SHARE=0.40687`** — the share alone would not establish it), and d6 is zero at layer 0 only (`D6_MASS_AT_LAYER0=0` — the
complement of the anchor exit 0 is 63, already placed). Two further zeros are local for the same
kind of reason and are recorded so nobody rediscovers them as ladder facts: pairs **4, 6, 21**
never occupy the first slot (`PAIRS_NEVER_FIRST=4,6,21`) and are exactly the three pairs whose
hexagrams both have popcount 5 — (55,59), (61,47), (31,62) — at distance 5 from exit 0, which C2
forbids (`PAIRS_NEVER_FIRST_ARE_EXACTLY_THE_POPCOUNT5_PAIRS=PASS`; the same three at n=9); and
only 16 pairs are admissible in the last slot (`PAIRS_ADMISSIBLE_LAST_COUNT=16`, the wrap/anchor
predicate — the exact rule is not derived here and not claimed). *Not determined:* the n=13
budget, whose atlas is not held; the mechanism is shown at n=9 and by the predicate, not by n=13
numbers.

### 12.2 Doomed prefixes: 68.67 % of the pruned-DFS tree, in t-units

The `counts` table splits each layer's prefix mass into prefixes with g > 0 (live) and g = 0
(dead — valid so far, unable to complete). Gates: `DEAD_PLUS_LIVE_EQ_FMASS_EVERY_LAYER=PASS`,
`FMASS_SUM_EQ_T_ROOT=PASS`, `FMASS_N_EQ_N_TOTAL=PASS`. Result, exact:
**`DOOMED_PREFIX_NODES=5968022288905786404124160364971149064064`** of
t(root) = 8,690,552,978,660,778,147,480,075,615,137,911,218,123 t-units, i.e.
**`DOOMED_FRACTION_OF_T_ROOT=0.686725`**; live nodes including the N leaves are 31.33 %. Shape:
no dead prefix exists through k = 8; the first appear at **k = 9**
(`FIRST_LAYER_WITH_DEAD_PREFIXES=9`, 0.06 % of that layer); a layer's dead share first exceeds
one half at **k = 25** (`FIRST_LAYER_DEAD_FRACTION_ABOVE_HALF=25`, 51.4 %) and peaks at 82.3 % at
k = 29 (`DEAD_FRACTION_BY_LAYER`); 99.95 % of all doomed mass sits at k ≥ 26, and the share at
k ≥ 24 rounds to 1.0000 at four decimals (`DOOMED_MASS_TAIL_SHARE_FROM_LAYER`). **Scope:** a ratio
of t-units — valid oriented SUPER prefixes, the atlas's own `t_units_note` — which says nothing
about production-DFS node counts. The production DFS prunes on one combined `kw_dist` budget,
weaker than the t-ladder's boundary cap, and applies C3 only as a filter at the full-walk leaf, so
the only relation between the two is §3's one-sided one: t-units bound production nodes from
below. The withheld exhaustibility call is unaffected. ⚠ *(Corrected 2026-09-25, Q-787. This read
"about production-DFS node counts under C3 pruning; the mapping between the two is the
uncertified W0-D convention of §3". Production checks C3 only at step 32 of `backtrack` /
`backtrack_iterative` in `solve.c`, so there is no C3 pruning for its nodes to be counted under;
see `reports/evidence/w0d_lower_bound/README.md`.)* What it
does say, exactly, is the share of exhaustive search that is provably wasted on prefixes that
cannot complete, and that it is late: the pruned tree is dead-end-free for its first nine layers
and essentially so for its first twenty-four.
**The t ladder these t-units are read from was checked by the sound instrument.**
`runs/20260906_kc_ladders_n31/KC_T_CHECK_n31.txt` records `solve --kc-t-check` at n=31: **PASS, 0
failing layers over k = 0..31** (2026-09-14 19:31 → 2026-09-15 21:17 UTC, single core, binary sha256
`a253828b…`), and it prints the same t(root) as above. Its scope is stated in
`documentation/GT_LADDER_FORMAT.md` (line 297): the check constrains the
*files*, not the shared transition relation, and the k = 0 and k = n endpoints degenerate.
⚠ *(added 2026-09-24: until now this section rested on the t ladder without citing the one check of
it that ran. The n=31 battery receipt's `TR12_TCHECK_REASON`, "no --kc-t-check PASS verdict has EVER
been recorded", was already stale when that run wrote it (the record predates the run by a week) and
is superseded; see
`reports/evidence/tr12/README.md`.)*

### 12.3 King Wen's transition sits low in its distance class at 24 of 31 steps — a pointer, not a p-value

The L6a `kwrank` table records, per layer k, the walk mass of same-class transitions lighter
than, equal to and heavier than King Wen's own (`lt`, `eq`, `gt`;
`KWRANK_BINS_SUM_TO_CLASS_MASS_EVERY_LAYER=PASS`). The mass-weighted lower percentile
`lt/(lt+eq+gt)` per step is **`REF_WALK_CELL_PERCENTILE_BY_LAYER_MASS_WEIGHTED_LT`** = 0.000,
0.368, 0.153, 0.539, 0.235, 0.147, 0.067, 0.031, 0.060, 0.166, 0.243, 0.320, 0.277, 0.123, 0.099,
0.166, 0.217, 0.101, 0.076, 0.137, 0.147, 0.131, 0.118, 0.116, 0.054, 0.074, 0.175, 0.344, 0.202,
0.981, 0.914 — mean **0.219** (`REF_WALK_CELL_PERCENTILE_MEAN_OVER_N_STEPS`), **24 of 31 steps
below 0.25** (`REF_WALK_CELL_PERCENTILE_STEPS_BELOW_0_25=24`), the last two steps at 0.98 and
0.91. **The null, stated and not measured:** under the uniform measure a walk's layer-k
transition is drawn in proportion to its mass, so by the probability-integral transform the
per-step statistic has mean 0.5 less half the tie mass (`CELL_PERCENTILE_NULL_MEAN_PER_STEP`).
**The limit, stated first:** the 31 steps are dependent — a light choice at step k conditions
every later layer — so the atlas yields no distribution for the 31-step mean, and 0.219 against
0.5 is a *pointer* to where a per-step prefix-state rule would have to act (EW-1's
`localized-constraint-candidate` class), not a finding that one exists. What would settle it is
named in 12.7. Two audits precede any headline use, per §4(d): whether the profile is an f-side
effect (King Wen's prefixes reached by few orderings) or a g-side one, which the atlas cannot
separate; and whether King Wen's C3-compactness already predicts a low f, which would make the
profile a restatement.

### 12.4 The raw one-step kernel is stationary across the walk and does not distinguish King Wen — a negative result

The `kernel` table is the per-layer 64×64 matrix M_k[a][b] of walk mass through the transition
exit-a → entry-b (`KERNEL_EVERY_LAYER_SUMS_TO_N=PASS`). **Stationarity:** the total-variation
distance between adjacent layers' kernels is ≤ **0.00099** over layers 6–23
(`KERNEL_TV_ADJACENT_MAX_INTERIOR`, window `KERNEL_INTERIOR_WINDOW=6,23`; k=24 meets the same bound
at 0.000290 and is merely outside the declared window). The departures sit at **k ≤ 5 and k ≥ 25**:
on the low side k=4 at 0.004979 and k=5 at 0.001105, on the high side k=25 at 0.001007 and k=26 at
0.001025, each above the interior bound, before the series climbs to 1.0000 at k=1 and 0.4684 at
k=30 (`KERNEL_TV_ADJACENT_LAYERS_K1_TO_KNM1`). That token prints four decimals, at which 0.00099
and 0.0010 are indistinguishable, so these four layers are settled by
**`KERNEL_TV_ADJACENT_LAYERS_K1_TO_KNM1_FULL`**, the same vector at ten decimals: k=4
**0.0049787974**, k=5 **0.0011054067**, k=24 **0.0002900820**, k=25 **0.0010072525**, k=26
**0.0010246560**, and the window maximum **0.0009874424**, which is the published 0.00099 to five
decimals. ⚠ *Corrected 2026-09-22 (v1.9, CX-72): until this revision those six digits were settled
by a **private** recomputation from the same `kernel` tables, and were therefore the single
exception to this section's promise that one public command reproduces every figure in §12.1–§12.8.
The figures were right — each is reproduced exactly by the new token — but a figure a reader cannot
recompute is not published, it is asserted. Closed in the direction of more public output rather
than a softer claim. Codex TRQ1-F6b.*
**Discrimination:** King Wen's
log₂-score under its own layers' kernels is **−354.964** against a population mean of
**−354.862** (`REF_WALK_KERNEL_LOG2_SCORE`, `KERNEL_POPULATION_MEAN_LOG2_SCORE` — minus the
summed kernel entropies, i.e. the same score averaged over all N walks): **−0.102 bits over 31
steps** (`REF_WALK_KERNEL_SCORE_MINUS_POPULATION_MEAN_BITS`). The one-step hexagram-to-hexagram
kernel does not distinguish King Wen from a typical member of SUPER **at the scale these marginals
fix**, and that scale is now stated rather than left implicit: were the 31 per-step terms
independent the score's SD would be **1.943 bits** (`KERNEL_SCORE_INDEPENDENT_STEP_SD_BITS`;
per-step SDs 0.257–0.428, `KERNEL_SCORE_PER_STEP_SD_MIN_MAX_BITS`), and −0.102 is **0.05 of it**
(`REF_WALK_KERNEL_SCORE_DEVIATION_OVER_INDEPENDENT_STEP_SD=-0.053`). The steps are **not**
independent, and one-step marginals fix neither the score's distribution nor its variance — only
that its SD is at most **10.794 bits** (`KERNEL_SCORE_SD_UPPER_BOUND_ANY_DEPENDENCE_BITS`, a
Minkowski bound, rigorous under any dependence). So the atlas does not show the one-step kernel
distinguishing King Wen, and **cannot show that it does not**: that needs the per-walk score
distribution (one f+g point-lookup per gallery walk, the 12.7(i) class), which is not computed
here. This is a Q9-class reportable negative and is entered there **as "not distinguished at the
one-step scale measured", not as "cannot tell"**. ⚠ *Corrected 2026-09-22 (v1.8, CX-68): this read
"the one-step hexagram-to-hexagram kernel cannot tell King Wen from a typical member of SUPER" — a
conclusion drawn from −0.102 bits with no dispersion, percentile or threshold computed anywhere in
the document. Codex KCR1-7 / TRQ1-F5a; scale derived here from the atlas alone.* **Scope:** one-step *marginal* stationarity only — the kernel is
not a Markov model of the walk and its columns do not compose (`viz/viz_kc_grammar.md`); a true
Markov test needs two-step joints — the mass through consecutive transitions from a layer-k state s
is f(s)·g(s∘c₁∘c₂), which the f and g ladders **do** hold but the atlas does not persist, and which
the one-step kernels cannot recover (M_{k+1} is the marginal over the first choice). Forming them is
a **second scan pass, not a lookup**: sized in 12.7, and not costed for authorisation here. ⚠
*Corrected 2026-09-22 (v1.8, CX-69): this read "cannot be formed from f×g at any price and so is
not askable of these ladders" — a **capability** limit published where a **cost** limit is the
truth, which is exactly the class §9 says this document does not make. Codex TRQ1-F3.* **Step-difference census:** the 31 kernels sum to
`STEP_XOR_DISTINCT_VALUES=57` distinct step values x = a ⊕ b — the 63 nonzero six-bit values less
the six of popcount 5, which C2 forbids (`STEP_XOR_TOTAL_EQ_N_TIMES_N_TOTAL=PASS`). The per-value
figures below are **expected uses per walk**, not fractions of one: each is that step value's total
mass over all 31 layers divided by N, so within a distance class they sum to that class's C5 budget
b0(d) — measured 2, 8, 13, 7, 1 against `B0_FROM_COLUMN_SUMS=2,8,13,7,1` — and over all 57 values to
n = 31. Within a class they are near-uniform: popcount 1, six values, each exactly
0.3333 — forced, since the six single-line steps are one orbit of the order-48 group and the
atlas's `kernel_g_invariance` tail check holds; popcount 3, twenty values, 0.6494–0.6504;
popcount 2, fifteen values, 0.479–0.547; popcount 4, fifteen values, 0.416–0.479; popcount 6, one
value, 1.0 (`STEP_XOR_POPCOUNT<p>_SHARE_MIN_MAX`; the token's name says "share" but the quantity is
the per-walk expectation just described). Within-orbit equality is forced by
G-invariance; the between-orbit spread inside the popcount-2 and popcount-4 classes is the only
content here that is not.

### 12.5 The positional pair field is flat to about 3 % — the reading of V1, and it is negative

V1's field P(pair j at slot k) is doubly stochastic by gate; this is its reading. Over all 31
slots every nonzero cell lies in **0.0205–0.0636** (`MARGINAL_RAW_NONZERO_CELL_MIN_MAX`), and both
extremes are end slots: 0.0205 at slot 2 (pairs 3, 7 and 11) and 0.0636 at slot 32 (pairs 5, 8, 26
and 31). On the interior slots 3–31 (layers 1–29) every nonzero cell lies in **0.0297–0.0345**
against 1/31 = 0.0323 (`MARGINAL_RAW_NONZERO_CELL_MIN_MAX_INTERIOR`). ⚠ *(corrected 2026-09-24: this
read "Over the interior slots 1–29 every nonzero cell lies in 0.0205–0.0636". That token covers all
31 layers, not the interior, and "slots 1–29" was the layer window, not slot numbers. The two tokens
beside it are windowed; this one was not.)* The total-variation distance of each slot's row from
uniform is ≤ **0.0329** (`POSITIONAL_TV_FROM_UNIFORM_MAX_INTERIOR`), and King Wen's own pair at
its own slot carries **0.0299–0.0337** at every interior slot
(`KW_PAIR_SHARE_AT_OWN_SLOT_MIN_MAX_INTERIOR`) — indistinguishable from any other pair. Pair
position **marginals** carry essentially no information about membership in SUPER, and King Wen's
per-slot placements are typical of them. ⚠ *Scope, corrected 2026-09-22 (v1.8, CX-68): that is a
statement about slot **marginals**. Flat marginals do not test the **joint** placement pattern —
which pairs co-occur where — and a doubly-stochastic field can be flat in every row and column
while its joint is far from product. Whether King Wen's joint placement pattern is typical is **not
asked here**. This previously read "Pair position carries essentially no information about
membership in SUPER, and King Wen's placements are typical of it", which generalised past what the
marginals test. Codex TRQ1-F5b, the §12.5 sibling of KCR1-7.* Reportable negative; entered under
Q9.

### 12.6 The order in which the C5 budget is spent, against the exchangeable null — measured; interpretation withheld

The `rid_mass` table is the exact joint distribution of the residual budget vector at each layer
(`RID_MASS_EVERY_LAYER_SUMS_TO_N=PASS`, `RID_DIGIT_SUM_EQ_LAYER_EVERY_CELL=PASS`,
`RID_CELLS_TOTAL=5918` nonzero cells). Against the multivariate-hypergeometric law of a
uniformly random arrangement of the multiset (2,8,13,7,1) — the law under which the class
sequence would be exchangeable — the total-variation distance is ≤ **0.0415** at every layer,
maximal at k = 4 (`EXCHANGEABLE_NULL_TV_MAX_OVER_LAYERS`, `EXCHANGEABLE_NULL_TV_BY_LAYER`). The
deviations are one-sided: no cell exceeds the null by more than ×1.101
(`EXCHANGEABLE_NULL_MOST_ENHANCED_CELL`, k = 4, digits [0,1,1,2,0]), while front-loading a
class is strongly suppressed — the cell [2,0,13,7,1] at k = 23 (every d1, d3, d4 and d6 already
spent, no d2) carries ×0.058 of its null mass (`EXCHANGEABLE_NULL_MOST_SUPPRESSED_CELL`).
Consistently, the per-layer class shares stay within 0.18 percentage points of b0/31 on layers
1–29 (`BY_CLASS_MAX_ABS_DEV_FROM_B0_OVER_N_INTERIOR=0.00179`), and the single complement step
(d6) takes 3.13–3.35 % of every interior layer (`D6_POSITION_LAW_MIN_MAX_INTERIOR`). King Wen's
own residual is the modal cell at k = 0, 3 and 30 and mid-pack through the middle
(`REF_WALK_RID_RANK_BY_LAYER_1_IS_MODAL`). **Controls, both directions:** against a deliberately
wrong null — the product of the joint's own digit marginals — the same statistic reads 0.83, about
twenty times larger (`CONTROL_WRONG_NULL_TV_OVER_EXCHANGEABLE_TV=19.97`), so it can discriminate —
**though what that control discriminates is narrower than the number alone suggests**: to four
decimals the 0.83 **is** the mass the product form puts off the Σc = k hyperplane
(`CONTROL_WRONG_NULL_MASS_OFF_BUDGET_HYPERPLANE_MAX_OVER_LAYERS=0.8289`, against
`CONTROL_WRONG_NULL_PRODUCT_FORM_TV_MAX=0.8289`). Every observed cell lies **on** that hyperplane,
so a product form — which ignores the budget identity — places 56–83 % of its mass where no walk
can be, and the control mostly measures **that**, not dependence among the digits given the budget.
Conditioned on the hyperplane and renormalised the same control reads 0.1333 at n=31 (3.2× the
exchangeable 0.0415) and 0.1948 at n=9 (0.34× the exchangeable 0.5686 — below 1 again for *that*
control); neither is emitted as a token, and both are stated here so the reading is not overdrawn;
and at n=9, where the budget is (2,5,0,2,0), the same statistic against the same exchangeable null
reads **0.569**, so the statistic can read large and 0.04 at n=31 is not a floor of the instrument.
⚠ *Corrected 2026-09-22 (v1.8, CX-60). Until this revision the quantity printed here summed
`½Σ|P−Q|` over the cells the atlas **stores**, and `rid_mass` stores only cells of nonzero observed
mass; both nulls put mass outside that support, so the term `½·Q(Sᶜ)` the definition requires was
never added and the statistic was not the total-variation distance it is named as. The **n=31
headline `0.0415` is unchanged** — layer 4, where the maximum falls, omits no mass — but the
wrong-null control and every n=9 figure move. Superseded: the control read `0.4145` and the ratio
`9.99`; at n=9 the three figures read `0.3554`, `0.2927` and `0.82`. The control now discriminates
by more than was claimed, so the argument of this section is unchanged and only its numbers are.*
⚠ *The n=9 figures in this section and in §12.9 are measured on an atlas **rebuilt from the
n=9 recipe below**, not read from a committed fixture — no n=9 atlas ships in this tree
(`git ls-files | grep atlas_n9` is empty, as `documentation/QUERY_INVENTORY.md` §8.10 records), so
reproducing them means running that four-command recipe first. Measured 2026-09-22 on a freshly
built n=9 atlas: `B0_FROM_COLUMN_SUMS=2,5,0,2,0`, `EXCHANGEABLE_NULL_TV_MAX_OVER_LAYERS=0.5686`,
`CONTROL_WRONG_NULL_PRODUCT_FORM_TV_MAX=0.5854`, `CONTROL_WRONG_NULL_TV_OVER_EXCHANGEABLE_TV=1.03`.*
**What is withheld, and why.** Exact exchangeability is refuted by the data itself (the ×0.058
cells). Whether *approximate* exchangeability to TV 0.04 is informative — rather than forced by
the same structure that makes the kernel stationary (12.4) — has no calibrated null here and no
argument either way has been checked; a near-flat result can be forced rather than found. So the
number ships as a measurement, with its command and its controls, and this report makes no
claim that near-exchangeability is a property of the space beyond what the number says. The
house precedent for the null form is TR-8's pair-exchangeable null, which is a different object
(pair identities, not class order) and is precedent for the method, not for this result.

### 12.7 What the atlas leaves open, and what would close it — ladder dependence stated per item

Everything in 12.1–12.6 is computed from the atlas alone and needs no ladder. Three follow-ups
do: (i) **a calibrated null for 12.3** — per-walk profiles for the Q8 gallery (`--kc-profile
FDIR GDIR`, one per gallery walk: f+g point lookups) ranked against per-layer mass distributions
the atlas holds only at octave resolution (`hist`), or exactly by a further scan carrying a
per-walk `kwrank`; (ii) **the same profile for King Wen's nearest valid neighbours** — the 9
single-orientation flips `verify.py --check-flips` reports valid, and the distance-2 C15 witness
in `reports/certificates/c3_positional_witnesses.txt` (f+g point lookups; if the flips leave the
profile unchanged, the profile is a property of pair *order*, not orientation, which would itself
be the finding); (iii) **which constraint kills** — among the doomed prefixes of 12.2, whether
death is a C2 event or a C5 class exhausted, and which class; `rid_mass` and `digits` carry live
mass only, so this needs a tally over the late f and g layers (k ≥ 24 holds all but 0.005 % of
doomed mass) that no shipped subcommand performs. None of the three is authorised or scheduled by
this section; each is a point-lookup or a small tally, not a re-scan. Two things are **not in the atlas** and are a
**further pass over the ladders rather than a lookup** — listed so the cost is visible and is not
authorised here: (i) **two-step joints** (12.4) — naively 2(n−k−1) g-lookups per nonzero child,
**3.49×10¹⁴** against the first scan's **1.27×10¹³** (27.6×; ≈ 800 h at the measured 28.9 h per
64-thread scan, if lookup-bound), or ≈ 2.3× that scan (≈ 65 h) by recovering the previous exit per
layer-(k+1) entry with ≤ 2k f-lookups and reusing the one-step g-lookups — on ladders that are now
**cold**, whose 11.5 TB rehydration is not permitted by standing rule; and (ii) **per-branch
per-layer marginals** (V2's original form) — ⚠ *this second clause is carried forward unchanged and
is **not adjudicated**: it may share the same defect as the first (a pass mistaken for an
impossibility) and has not been derived either way.* ⚠ *Corrected 2026-09-22 (v1.8, CX-69): this
read "not askable of these ladders at all", a capability claim; the two-step half is a cost, now
derived from the atlas's own measured counts. Codex TRQ1-F3.*

### 12.8 Q10(b): the data cost is zero under one reading, and the question is undefined under both

See the 2026-09-21 annotation at §11 Q10(b)'s cost line and
[CORRECTIONS.md](../documentation/CORRECTIONS.md) CX-58: the raw kernel gives the step-difference
reading of (b) a zero-data-cost projection once a subgroup set is chosen, and gives the
mask-level reading nothing; under either reading the blocker is the definition,
`--kc-coset-census` does not exist, and `TR12_Q10B=PENDING:--kc-coset-census` stays pinned. No
row moves.

### 12.9 Figure → token, for the reader's `grep -Fqx`

⚠ *`-F` is load-bearing and was missing until 2026-09-22 (v1.8, CX-62): two tokens in this table
carry `digits=[…]`, and a bracket expression is regex syntax, so under plain `grep -qx` those two
**fail to match their own output line**. In the other direction `.` matches any character, so a
corrupted `DOOMED_FRACTION_OF_T_ROOT=0x686725` satisfies the published `…=0.686725` pattern under
`-qx`. Both directions measured. Use `-F` everywhere in this document.*

| figure | token at n=31 |
|---|---|
| the run's C5 budget from column sums | `B0_FROM_COLUMN_SUMS=2,8,13,7,1` (n=9: `2,5,0,2,0`) |
| d3 the largest class at every layer; no class empty at k ≥ 1 | `LARGEST_CLASS_SET_OVER_LAYERS=d3`; `CLASSES_WITH_ZERO_MASS_AT_SOME_LAYER_K_GE_1=NONE`; `D3_MIN_LAYER_SHARE=0.40687` |
| pairs never first / admissible last | `PAIRS_NEVER_FIRST=4,6,21`; `PAIRS_ADMISSIBLE_LAST_COUNT=16` |
| doomed share of the pruned-DFS tree | `DOOMED_FRACTION_OF_T_ROOT=0.686725` |
| first dead layer / dead share above one half | `FIRST_LAYER_WITH_DEAD_PREFIXES=9`; `FIRST_LAYER_DEAD_FRACTION_ABOVE_HALF=25` |
| KW's per-step cell percentile, mean, steps below 0.25 | `REF_WALK_CELL_PERCENTILE_MEAN_OVER_N_STEPS=0.219`; `REF_WALK_CELL_PERCENTILE_STEPS_BELOW_0_25=24` |
| kernel stationarity, layers 6–23 | `KERNEL_TV_ADJACENT_MAX_INTERIOR=0.00099` |
| KW's kernel score minus the population mean | `REF_WALK_KERNEL_SCORE_MINUS_POPULATION_MEAN_BITS=-0.102` |
| distinct step values | `STEP_XOR_DISTINCT_VALUES=57` |
| positional field, TV from uniform | `POSITIONAL_TV_FROM_UNIFORM_MAX_INTERIOR=0.0329` |
| KW's pair at its own slot | `KW_PAIR_SHARE_AT_OWN_SLOT_MIN_MAX_INTERIOR=0.0299,0.0337` |
| budget path vs exchangeable null, max TV | `EXCHANGEABLE_NULL_TV_MAX_OVER_LAYERS=0.0415` (n=9: `0.5686`) |
| wrong-null control ratio | `CONTROL_WRONG_NULL_TV_OVER_EXCHANGEABLE_TV=19.97` (n=9: `1.03`) |
| most suppressed / most enhanced cell | `EXCHANGEABLE_NULL_MOST_SUPPRESSED_CELL=ratio=0.058 layer=23 digits=[2, 0, 13, 7, 1]`; `EXCHANGEABLE_NULL_MOST_ENHANCED_CELL=ratio=1.101 layer=4 digits=[0, 1, 1, 2, 0]` |
| the walk the atlas tracks is King Wen | `REF_WALK_IS_KING_WEN=PASS` (n=9: `SKIP:n=9`) |
| A2 anchor-pair slot shares vs TR-7's published anchors | `TR12_A2_SLOT=FAIL` (n=9: `SKIP:n=9`) — from `--atlas-queries`, `DIR/VERDICTS.txt`; see §12.10; FAIL is the result, not a defect |
| closing-pair wrap-class masses vs TR-7 §5 | `TR12_A3_EXTERNAL=FAIL` (n=9: `SKIP:n=9`) — from `--atlas-queries`, `DIR/VERDICTS.txt`; see §12.10; FAIL is the result, not a defect |

### 12.10 The two external anchors compare across populations, and at full-31 they disagree

Two checks in the consumer compare the atlas against numbers **published from a different
instrument**: `TR12_A2_SLOT` (the alternating anchor pair's slot shares, against TR-7's R-C1c) and
`TR12_A3_EXTERNAL` (the closing pair's wrap-class masses, against TR-7 §5). Below full-31 both
return `SKIP:n=<n>` — C4 fixes the first pair-slot only at n=31, so the closing pair does not determine the wrap
distance at reduced n. **Both first executed 2026-09-22**, in Group C of the post-scan battery; the atlas they need was complete 2026-09-21T10:29Z. Both FAIL — a fact about the two populations — and the
failure is the measurement. ⚠ *Corrected 2026-09-22 (v1.8, CX-71): this read "a fact about the two
populations, **not a defect in either instrument**". A population difference **explains** a
disagreement; it **certifies** neither implementation. What stands behind each instrument is its own
gates and its own reproduction, not the existence of a gap between them — a FAIL is equally
consistent with a population difference and with a fault, and only the gates distinguish them.
Codex TRQ1-C3b, the unswept sibling of a same-day pre-push cure applied to the very next sentence.*

**The two sides count different populations, and that was the open question.** The atlas counts over
**SUPER** (C1∩C2∩C4∩C5, **C3 not applied**); the published references are fractions of
**C3-passing** C1–C5 mass. The consumer has said so in its own output **since 2026-09-05**, when a Codex review finding (MQ1A #4) put it there — *"Agreement
corroborates only if the law is C3-insensitive at tol, which is UNMEASURED until the first full-31
atlas."* That question is now answerable on one side only: the SUPER side is measured below; the
C1–C5 side is not this program's to measure.

| quantity | atlas (SUPER) | published (C1–C5) | deviation |
|---|---|---|---|
| A2, anchor pair at slot 32 | **0.0636** | 0.0785 | 0.0149 |
| A2, anchor pair at slot 2 | **0.0424** | 0.0520 | 0.0096 |
| A2, R-C1c (their sum) | **0.1059** | 0.1305 | **0.0246** |
| A3, wrap class d3 | **0.6271** | 0.652 | **0.0249** |
| A3, wrap class d1 | **0.1884** | 0.175 | 0.0134 |
| A3, wrap class d5 | **0.1845** | 0.174 | 0.0105 |

Tolerance is 0.0020, compared in exact rationals. **The two sides disagree by about twelve times
tolerance.**

**What this program can and cannot say about that gap.** This compiler is built on **C1, C2, C4
and C5 only**. §0 states it plainly — *"no instrument in this program counts C3-conditioned: the
f/g/t ladders carry no C3 channel"* — and the atlas labels its own space `C1C2C4C5-SUPERSPACE`.
So the SUPER side is measured here, exactly. The C1–C5 side is **not measured here at all**: it is
TR-7's, from a different instrument. The two conditioning sets differ by exactly C3, and TR-7's
published uncertainties (below) exclude estimator error on its side, so the difference is
**attributable** to C3-conditioning. But that attribution is an inference from two instruments
each being right about what it measured — **not a measurement of C3 by this program**, which has
no channel that could make one. Nothing here should be read as this program having measured a C3
effect.

**The structure of the gap is the interesting part.** A2's three cells rescale by the *same* factor
to three significant figures — **≈1.23 in every cell**. (Exact-atlas against the unrounded published
values: 1.234, 1.228, 1.232. A fourth figure is not determined at the published precision, and
R-C1c is the *sum* of the first two, so it is a weighted mean of their ratios and cannot fall
outside them — not a third independent confirmation.) **What separates the two populations reshapes
that histogram rather than rescaling it**: it enriches the two circle-adjacent slots by the same
≈×1.23 and, because both histograms sum to exactly 1, depletes the interior to pay for it. Over all
31 slots the published/atlas ratio runs from **0.872 (slot 17)** to **1.234 (slot 32)**, exceeding 1
only at slots 2–7 and 27–32. ⚠ *Corrected 2026-09-22 (v1.8, CX-63). This read "does not perturb that
histogram, it **rescales** it, uniformly across both circle-adjacent slots" — **measured false**, and
arithmetically impossible as a reading about the histogram: two distributions that each sum to 1
cannot differ by a uniform factor. The three-cell arithmetic that the sentence generalised from is
correct and unchanged; only the generalisation was wrong. Re-derived 2026-09-22 from the pinned
atlas against `reports/evidence/r6/rc1c_primary.out`.* A further measured consequence, not
previously stated: **on SUPER the A2 slot histogram is flat away from the two circle-adjacent
slots** — interior slots 3–31 sit between 0.0297 and 0.0326 against 1/31 = 0.0323 — so TR-7's
published U-shape is not a property of SUPER, and under this section's own inference rule it is
attributable to C3. That is a *negative* for the SUPER side in the Q9 sense: A2 pair-slot position
carries no interior structure here. A3 moves instead: mass flows *into*
d3 (×1.040) and *out of* d1 and d5 (×0.929, ×0.943). Atlas masses sum to exactly 1, and all 16
eligible closers are realised.

**No published figure is contradicted.** TR-7's quantities are C1–C5 quantities and remain so — and
nothing here tests that side. Estimator error on the C1–C5 side is excluded as the explanation: TR-7
publishes the wrap masses as 17.4647 ± 0.0077, 65.1504 ± 0.0096 and 17.3849 ± 0.0077 pp, so the A3
gap of 0.0249 is roughly **260 standard errors**. What changes
is that the SUPER-side values are now measured rather than assumed to track the published ones, and a reader may no longer treat a SUPER-side measurement as corroborating a C1–C5
published number at this tolerance.

**Why `ATLAS_PROBE=PASS` on the same atlas is not a contradiction.** §12's probe tests the atlas's
*internal* consistency — every table re-summed against N and against the atlas's own gates. These
two checks test it against *external* published numbers from a different population. Both verdicts
are correct simultaneously, and a reader should expect exactly this pattern.

**Reproduction.** §12's `--atlas-probe` does **not** carry these two tokens; they come from the
consumer. Against the atlas pinned in §12 (sha256 `9d6ba3d2…`):

```
python3 solve.py --atlas-queries atlas_n31.json --atlas-out DIR
# exit 1;  TR12_A2_SLOT=FAIL  TR12_A3_EXTERNAL=FAIL
```

**The atlas is the only input these two tokens need.** `--atlas-q3-trace` is *not* required for
them and is deliberately omitted above, because the trace is a run artifact and is not distributed
with this report — a recipe gated on a file the reader cannot obtain is not a reproduction recipe.
Measured both ways on the same atlas: with and without the trace, `TR12_A2_SLOT` and
`TR12_A3_EXTERNAL` and every figure in the table above are **character-for-character identical**;
the only difference is that `TR12_Q3`, `TR12_Q3_KW` and `TR12_Q3_READER` report `SKIP:no-trace(--atlas-q3-trace)`
instead of `PASS`. Supplying the trace reproduces the run's full 17-token verdict set with zero
differences, and is the right form if you have it — but §12.10's figures do not depend on it.

Exit status 1 is the documented behaviour when any verdict written is a failure, and it is the
correct status here. The run takes well under a second on the 5.98 MB JSON, on any machine — no
ladder, no scan, no cluster. The `solve.c` that wrote the atlas is byte-identical to this
revision's (`engine_source_sha ed9c65b24e9f…`), and `atlas_a2_slot_check`,
`atlas_a3_external_check`, `atlas_a3_wrap_class_map` and all of their reference constants are
**unchanged** since the atlas was written, so the verdict-producing chain has not moved beneath the
measurement.

**Scope, stated plainly.** These figures establish what the SUPER side is. They do not adjudicate
the C1–C5 side, which was measured by a different instrument over a different population, and
nothing here should be read as revising it. The gap between the two is the result.

---

*(The wall-time caveat that stood here through v1.9 has **moved to §0 "Cost basis"**, where a reader
meets it before the ~25 cost bands it governs rather than after all of them. Its content is
unchanged and is extended there with the execution status of each wave.)*


---

## Open Problems

*§10.A of this report declares this section a MUST and it did not exist until v1.11. Every entry
states the question precisely, classifies it, and cites where its partial state lives. The
classification is §10.A's own — conjecture / obstruction / unpriced computation / research
direction — and one row does not fit it cleanly, which is said rather than smoothed over.*

| # | Open question | Class | Where its partial state lives |
|---|---|---|---|
| 1 | **Exact `\|C15\|`** — the C1–C5 count, exactly rather than as an estimate with a CI. | **unpriced computation**, explicitly NOT an obstruction | The structural barrier is gone: `C3 = 16 + 8·G` is kernel-checked (`lean/C3Decomposition.lean`, `c3_slot_decomposition`), so a bounded-state exact DP exists and `solve --f1-c3-hist --with-c5` is it. Priced ≈ $3–5K / ≈ 36 TB and **declined on cost** — §9, and [METHODS.md](METHODS.md) §"Why these two remain estimates". |
| 2 | **The Exhaustion Atlas verdict** — EXHAUSTIBLE vs INFEASIBLE. | **obstruction** (a missing certificate, not a missing number) | Pricing t-units as production-DFS nodes needs a mapping nothing certifies. `TR12_XA_CD=PENDING:W0-D-node-mapping`; the consumer *refuses* to emit the verdict — §3. |
| 3 | **Q10(b), the coset census** — mass by coset id, and King Wen's coset. | *does not fit the four classes*: it is a **definition gap** before it is anything else | No subgroup set and no coset-id map are fixed, so neither reading of (b) has a producer; `--kc-coset-census` does not exist. `TR12_Q10B=PENDING:--kc-coset-census` — §12.8 and [CORRECTIONS.md](../documentation/CORRECTIONS.md) CX-58. |
| 4 | **Q7 historical-arrangement witnesses** — a rank for each named non-KW sequence. | **research direction** — a *contract* decision, NOT the tooling gap it looks like | ⚠ **Installing the solver does not close this, and the battery says so in code.** `scripts/tr12_repro.sh:915@5c296837` branched on `command -v kissat`: with the solver present the token becomes `PENDING:q7-witness-row`, not `PASS`, because *which* satisfying sequence a solver returns is **build-dependent**, so a golden of solver-chosen bytes would pin one build's arbitrary choice. **The reproducible contract is a PROPERTY of the returned witness, not its bytes** ([QUERY_INVENTORY.md](../documentation/QUERY_INVENTORY.md) row `TR12_Q7_WITNESSES`, decision column: *"needs a contract decision first"*). A second gap sits underneath it: `sat.py` invokes `kissat -q` with **no proof flag** on the `--witness` path, so DRAT emission is absent there. Today `kissat` is also simply not on PATH (nor `drat-trim`, `cake_lpr`, `d4`, `cpog-gen`), and the leg is a *named* skip red-tested by `scripts/d5_04_q7_witnesses_gate.sh` — §Q7. ⚠ **[corrected 2026-09-25, CX-93: the contract decision is TAKEN and the row is built.** The witness bytes are pinned in `reports/evidence/q7_witnesses/` (kissat 4.0.4, once; README there) and `TR12_Q7_WITNESSES` verifies the pinned sequences solver-free, so this row of the table is no longer a direction; what remains open is the n = 31 rank itself, which no run has computed yet, and the DRAT gap on the `--witness` path, which is unchanged and irrelevant to a SAT witness (the model is its own certificate). §Q7.] |
| 5 | **`TR12_V3_FIG` cannot clear by measurement: no battery row runs the V3 join.** The figure itself is delivered. ⚠ *(retitled 2026-09-24: this row was headed "**Figure V3** — the rank spectrum", classed "**obstruction** — a missing emitter, NOT a ladder read", while its own body recorded V3 as rendered. V4 left this list when it was rendered on 2026-09-23.)* | **unpriced computation** — one battery row (`solve.py --v3-spectrum` over the `a1_v3` grid at n=31, before the render step), plus the n=9 golden re-mint and re-stamp it forces; an operator gate | ⚠ **This row named V4 too, on the ground that it "needs a read of the 15.05 TB f/g ladders, now cold". That was wrong and is withdrawn:** V4's input was produced by the 2026-09-22 run with the ladders mounted (`TR12_V4_TSV=PASS`), and the figure was missing only because matplotlib was absent on the query host (`TR12_VIZ=SKIP:matplotlib-absent`). It is now rendered and embedded in §2 from the committed `tr12/q3_profile_kw.tsv`. ⚠ **AND THEN V3 WENT THE SAME WAY, hours later on the same day.** This row said "V3 genuinely remains: … the **join** to per-walk observables … is emitted by neither the battery driver nor the atlas consumer." Both halves of that were true and the conclusion still did not follow: the rank grid was produced, the observable battery existed, and what stood between them was a join that nobody had written — now `solve.py --v3-spectrum`, and the figure is embedded in §2. **Two figures in one day were reported blocked by the wrong thing**, once by a 15 TB ladder read that was really two absent Python packages, once by a "missing emitter" that was really an unwritten forty-line join. The shared lesson is recorded in CX-74: *the published reason was the last observed symptom rather than the measured cause.* ⚠ `TR12_V3_FIG=PENDING:viz-v3-spectrum` **remains pinned and is deliberately not hand-edited** — ⚠ *but it will **not** clear on the next full-31 run as this row said until 2026-09-24 ("`scripts/tr12_repro.sh` already emits `PASS` when the figure is present, so the token clears on the next full-31 run by measurement").* The battery records `PASS` only if its own render step draws `fig_tr12_kc_spectrum`, and that step reads `<consumer>/spectrum/v3_spectrum.tsv` — a file no row of `scripts/tr12_repro.sh` writes, because no row runs `solve.py --v3-spectrum` (row `a1_v3` stops at the grid). The committed figure was rendered outside the battery from `tr12/v3_spectrum.tsv`. The token clears by measurement once a battery row runs the join, and not before; and the published n=31 receipt keeps `PENDING` because that is what was true when that run executed. **§2's five-figure program is now delivered in full.** What this row now tracks is only the battery token above. The other eleven rows of §Open Problems remain open (row 12's cell was itself corrected on 2026-09-24, see there) — §2 and [viz/README.md](../viz/README.md). |
| 6 | **Peak build space** for the three-stage catalog. | **unpriced computation** | **UNMEASURED**, and no figure is quoted for it anywhere in this report — §R.0. |
| 7 | **Is §12.6's near-exchangeability informative, or forced** by the same structure that makes the kernel stationary? | **research direction** | There is no calibrated null here, so the TV **0.0415** ships as a measurement and the interpretation is **withheld** — §12.6. |
| 8 | **What the A2/A3 disagreement attributes to.** | **research direction** | §12.10 publishes the FAIL as the result. The "two populations differing by exactly C3" reading is an **inference from two instruments each being right about what it measured — not a measurement of C3 by this program**, which has no C3 channel. |
| 9 | **Three atlas follow-ups**: a calibrated null for §12.3; the same profile for King Wen's nearest valid neighbours; and *which constraint kills* among the doomed prefixes. | **unpriced computation** (each is a point lookup or a small tally, not a re-scan) | Stated with costs, and **none is authorised or scheduled** — §12.7. |
| 10 | **Two-step joints, and per-branch per-layer marginals** (V2's original form). | **unpriced computation** | A further pass over the ladders rather than a lookup: ≈ 65 h by the efficient route, on ladders that are cold and whose 11.5 TB rehydration is barred by standing rule. The second clause is explicitly **not adjudicated** — §12.7, CX-69. |
| 11 | **Wave 3** — the extremal sweeps, the literature exact-count shortlist, the EW-2 screens. | **unpriced computation** | Never budgeted and never run (*"I can't afford wave 3"*), so these remain specifications rather than results — §Wave-status ruling. |
| 12 | **The ladder digests were not re-taken after the scan.** | **unpriced computation** | `TR12_FSHA` / `TR12_GSHA` / `TR12_TSHA` = `SKIP:banked-pre-scan`, but **no battery run has taken the layer digests** (CX-65): the pre-scan run stood the same rows down as `SKIP:cost-gated`, and what it did pin is each ladder's identity against the published registry (`TR12_{F,G,T}IDENT`). The digests were taken by the **standalone 2026-09-17 sweep**, 96 of 96 logical (§R Tier B), not by the battery. ⚠ *(corrected 2026-09-24: this cell read "the pre-scan run took them under the same binary and universe", repeating the receipt's pre-CX-65 reason string; `scripts/tr12_repro.sh` has said "NOT TAKEN, here or in the pre-scan" since 2026-09-22.)* `TR12_GCHECK=SKIP:cost-gated` (~24 h single-threaded) and `TR12_TCHECK=SKIP:cost-gated` in the battery; both checks ran standalone and passed at every layer with 0 failing layers — [`KC_G_CHECK_n31.txt`](KC_G_CHECK_n31.txt) and [`KC_T_CHECK_n31.txt`](../runs/20260906_kc_ladders_n31/KC_T_CHECK_n31.txt), each an integrity check of the files, not of the transition relation. Receipt: [`evidence/tr12/`](evidence/tr12/). |

**What is NOT on this list, because it was closed rather than deferred:** the C3 **minimum** is
**112**, closed by a structural bound `G ≥ 12` meeting a published witness
(`reports/certificates/c3_positional_witnesses.txt`) — no SAT bisection, no UNSAT leg and no DRAT
certificate are needed for it, and `TR12_Q4B` reads `PASS` (§Q4).

## Confidence Ledger

*§10.B of this report declares this section a MUST and it did not exist until v1.11. One row per
headline figure across TR-1…TR-12, graded, with the artifact a referee should pull. **Read the two
notes under the table before the table** — they are the reason several cells say UNRESOLVED
instead of carrying a grade.*

| Report | Figure | Value | Scope | Grade | Backing artifact |
|---|---|---|---|---|---|
| TR-1 | Literature rules proven forced | 8 rules stating **7 distinct** facts, each constant = KW's | all of **C1** | machine-checked | `lean/C1RuleConstants.lean` — per-rule `decide` theorems (`mmt4CompViol_inv`, `p1c4Viol_inv`, `s1CompViol_inv`, `s6WithinViol_inv`, `r3Viol_inv`, `r5Viol_inv`, …) |
| TR-1 | Van den Berghe nuclear-orientation ceiling | KW **29/30**; **12 of 1,720,320** at X=29; P(X ≥ 29) = **1.1097×10⁻⁵** one-sided | KW's **orientation fiber** — a fitted description read off KW, not the C1–C5 space | scoped-sample (exhaustive *within* the fiber) | `reports/evidence/f5/f5_modec_fiber.py`; gates `./solve --f5-verify`, `solve.py --vdb-verify` |
| TR-2 | Conflict theorem: four strongest rules jointly unsatisfiable | **UNSAT** | C1∩C2∩C4∩C5 | machine-checked (verdict rung 1; rule-faithfulness rung 2) | `sat.py --emit-cnf grand-ccn4` → `kissat` → `drat-trim` `s VERIFIED`; `reports/certificates/grand_ccn4_unsat.drat.gz` |
| TR-2 | Minimal repair from KW to a Moore-compliant ordering | exactly **3** slot-edits (2 UNSAT, 3 SAT) | C1–C5-valid orderings within k edits of KW | machine-checked | `reports/certificates/moore-strict-near-2.drat.gz`; `reports/certificates/grander_strict_near2_unsat.drat.gz`, `reports/certificates/grander_strict_near3_unsat.drat.gz`, `reports/certificates/grander_strict_near4_unsat.drat.gz` |
| TR-3 | The d3 560T canonical | sha256 `9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`, **10,525,271,997** records | the **560T budgeted slice** — a LOWER BOUND on C1–C5, not the space | sha-witnessed exact | `CANONICAL_HASHES.md` §"d3 560T"; `gzip -dc solutions.bin \| sha256sum`; `./solve --verify` |
| TR-4 | C1–C5 space size | **1.3287×10³⁸**, 95% CI **[1.3283, 1.3292]×10³⁸** (half-width 0.03%) | C15, orientation-raw | estimated-with-CI | `reports/evidence/knuth_whole_tree_5e10.out` — the archived estimator run. ⚠ The **artifact**, not the command, is cited here deliberately: a published estimator command carries no thread pin, and the thread count selects the sample, so pinning one after the fact would fabricate provenance rather than supply it. That gap is the standing G2 leg of the published-consistency ratchet |
| TR-4 | C1–C7 space size (Uniqueness Conjecture refuted) | **5.21×10³¹**, 95% CI **[5.13, 5.29]×10³¹** | C1–C7, orientation free, raw | estimated-with-CI | `reports/evidence/c67_probe.out`:14, which records `est=5.211639e+31`. Same deliberate choice as the row above — the archived run is the citation, because the published command does not name the artifact it produced |
| TR-4 | C1–C7 with C3 dropped | **516,880,238,445,773,965,371,923,491,676,160** | C1–C7 minus C3, raw | **exact, two-instrument** (see note 1) | `verify.c --ie-pin-c6c7 --ie-no-quotient` **and** `verify.c --dp-count --dp-pin-c6c7` |
| TR-5 | Sequence-level symmetry group | **48** (B₃ ≅ Z₂≀S₃), complete over all 64! relabelings | the C1–C5 predicate family | proven; rigidity kernel machine-checked | `solve.py --symmetry-completeness` (SC-1…SC-8); `certificates/rigidity_sc4_unsat.drat.gz`; `lean/SymmetryCompleteness.lean` |
| TR-5 | Record-level group; free action; twins | **24** (S₄), free, **23** twins each | canonical **record** level | proven | `cd lean && lean KingWen.lean`; `SYMMETRY_SEARCH.md` §Reproducibility |
| TR-5 | KW's 23 twins absent from the enumeration | all **23** absent | **560T slice only** — set-level absence NOT implied | scoped-sample | `verify.py --twins-bisect` (ships; ⚠ no result artifact archived) |
| TR-6 | Parity alternations | exactly **15** across the 31 pair boundaries | every C1+C5 sequence | machine-checked | `lean/KingWen.lean` `alternations_15_general` (kernel, no mathlib) |
| TR-6 | Transition-parity switches | exactly **30** | every C1+C5-valid ordering | machine-checked | `lean/KingWen.lean` `switches_30_general` |
| TR-7 | Wrap-around distance parity | **odd** for every C4+C5-valid ordering (KW's wrap d = 3) | every C4+C5 sequence | machine-checked | `lean/KingWen.lean` `wrap_parity_general`, `transitions_sum_parity` |
| TR-7 | McKenna's 3:1 even:odd ratio | **16 odd of 64**, 25.00% exact — forced, not designed | every C4+C5-valid circular reading | proven — a corollary, carrying no certificate of its own | derived from `lean/KingWen.lean` `wrap_parity_general` (kernel-checked) together with C5; the ratio itself is arithmetic over that theorem, not a separately certified result |
| TR-7 | d5-wrap mass vs the enumeration | **17.4%** of valid space wraps at d=5; **zero** of 10,525,271,997 records do | mass over C1–C5; the absence only within the **560T slice** | scoped-sample (the absence); witness existence machine-checked | `./solve --verify-wrap-parity`; `sat.py --witness wrap-d5` |
| TR-8 | Schulz gender rule, exact rarity | **47/445740 = 1.054426×10⁻⁴** | the **pair-only (C1) null** — a different object from the C1–C5 mass | proven (exact rational from an exact DP) | `solve.pair_null_gender_le2_exact()`, < 1 s |
| TR-8 | Gray-code impossibility | within-pair Hamming distances are **{2, 4, 6}**, never 1 | any complement/inversion pairing | machine-checked | `lean/KingWen.lean` `within_pair_even_nonzero` |
| TR-9 | MDL baseline; C1's share | baseline **log₂ 64! = 296.0 bits**; **C1 explains 146.3** (+ C4 6.0) | all 64! → the C1+C4 layer | proven (arithmetic); C1's optimality machine-checked | `lean/HammingOptimalMatching.lean` `partner_is_unique_minimum`, axiom base `[propext]` |
| TR-9 | Unexplained residual | **105.4 – 139.1 bits** | *stated per layer — the scope is the point of the range* | mixed: 139.1 exact-backed, 105.4 estimated-with-CI | `DESCRIPTION_LENGTH.md` ledger rows; §Verification Guide arithmetic checks |
| TR-9 | C2 start-free rarity | **4.29341%**; `\|C1∩C2\|` = **48521466573683942822764571590770825624846336** | start-unpinned C1∩C2 | **exact** (3-prime CRT, reader-checkable) | three `./solve --f1-exact-c1c2 --f1-mod P` runs + the published 3-line CRT check |
| TR-10 | Davis pre-registered battery | **five of nine NULL**; flagship block ~**1.1%** | C1–C5 population, 2×10⁹ probes | **UNRESOLVED** — see note 2 | pre-registration commit `2d19a3f`; `reports/evidence/dav_tier1.out` |
| TR-10 | Davis uniqueness claim refuted | #63/64 → **12 distinct** derivatives; **twelve** pairs attain the 10-derivative minimum | the received KW sequence alone | proven (deterministic recomputation) | `solve.py --dav-verify` / `./solve --dav-verify` → `DAV VERIFY: PASS` |
| TR-11 | `\|C1∩C2∩C4\|` | **757,058,601,340,255,440,651,419,713,405,330,315,358,208** | orientation-explicit, C4 pinned | **exact, two-instrument** (note 1) | `./solve --f1-exact-c1c2c4`; independent `verify.c --ie-count --ie-no-budget`; mod-24 → 0 |
| TR-11 | `\|C1∩C2∩C4∩C5\|` = SUPER | **1,097,051,278,789,181,790,036,112,071,176,579,186,688** | **SUPER**, orientation-explicit — **not** C15 | **exact, two-instrument** (note 1) | `./solve --f1-exact-c1c2c4c5 --f1-out-of-core DIR`; `verify.c --ie-count`; mod-24 → 0 |
| TR-11 | N/24 | **45,710,469,949,549,241,251,504,669,632,357,466,112** | ⚠ **2× the sequence-orbit count**, NOT a record-level orbit count (label corrected 2026-09-19, CX-53 / Q-642) | exact (the integer never moved; only its name did) | reader-side: reduce N mod 24 and mod 48 |
| TR-11 | C3 as a bounded scalar | **C3 = 16 + 8·G** | all C1-respecting orderings | machine-checked | `lean/C3Decomposition.lean` `c3_slot_decomposition` (kernel `decide`) |
| TR-12 | Compiled catalog + registry check | **15.05 TB**; **96 of 96** logical digests (f, g, t) and **65 of 65** container digests (**t only**; f and g 130 of 130 at copy-in), zero mismatches ⚠ *(corrected 2026-09-24: the container count was not scoped to t)* | the f/g/t ladders at n=31 over SUPER | sha-witnessed exact | Two digests, two eras, and they must not be confused: the **logical** (decompressed) leg is `./solve --f1c5-layer-sha DIR` against `STAGE_{F,G,T}_LAYERSHA.txt`, 32 rows per stage; the **container** leg is `sha256sum -c` against `STAGE_{F,G,T}_SHA256.txt` read in the **RAW, post-#169 framing** — since shards became gz-framed by default, a `sha256sum -c` run against a *logical* sidecar hashes the gzip container and reports FAILED on a byte-correct artifact. The integrity checks of the ladder *contents* are separate records: `runs/20260906_kc_ladders_n31/KC_T_CHECK_n31.txt` (`--kc-t-check`, PASS, 0 failing layers) and `reports/KC_G_CHECK_n31.txt` (`--kc-g-check`, PASS, 0 failing layers); both constrain the files, not the transition relation *(added 2026-09-24)* |
| TR-12 | The atlas every §12 figure is read from | 5,978,126 B, sha256 `9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558` | n=31 atlas over SUPER | sha-witnessed exact | `runs/20260906_kc_ladders_n31/atlas_n31.json`; verify with `solve.py --atlas-probe` |
| TR-12 | Doomed prefixes | **68.67 %** (`DOOMED_FRACTION_OF_T_ROOT=0.686725`); first at k=9, majority-of-layer from k=25 | SUPER, in **t-units** — says nothing about production-DFS nodes, which t-units bound from below only (§3) ⚠ *(corrected 2026-09-25, Q-787: this read "says nothing about production-DFS nodes under C3"; production applies C3 only as a leaf filter)* | exact over SUPER | `solve.py --atlas-probe atlas_n31.json`, matched `grep -Fqx` |
| TR-12 | KW's transition rank in its distance class | mean percentile **0.219** vs null 0.5; **24 of 31** steps below 0.25 | SUPER, walk-uniform | exact over SUPER, **published as a pointer with no p-value** (the 31 steps are dependent) | `REF_WALK_CELL_PERCENTILE_MEAN_OVER_N_STEPS` from `--atlas-probe` |
| TR-12 | The three negatives | kernel TV ≤ **0.00099** (layers 6–23); KW **−0.102 bits**; positional field flat to **0.0329** | SUPER | exact over SUPER | `--atlas-probe`; wrong-null control corrected 2026-09-22 (CX-60): 0.4145 → **0.8289** |
| TR-12 | The two external anchors | `TR12_A2_SLOT=FAIL`, `TR12_A3_EXTERNAL=FAIL` — ≈ 12× tolerance | SUPER vs TR-7's published **C1–C5** figures | the FAIL **is** the measurement; the C3 attribution is an **inference, not a measurement** | [`evidence/tr12/VERDICTS_n31_20260922.txt`](evidence/tr12/VERDICTS_n31_20260922.txt) |

**Note 1 — the rubric needs a sixth grade, and this is said rather than force-fitted.** §10.B names
five: machine-checked / proven / sha-witnessed exact / estimated-with-CI / scoped-sample. Four
figures fit none of them — `\|C1∩C2∩C4\|`, `\|C1∩C2∩C4∩C5\|`, C1–C7-with-C3-dropped, and
`\|C1∩C2\|`. They are **exact at full scale and independently recomputed by a second engine sharing
no code**, but their witness is a reproduction command plus a reader-side mod-24 or CRT gate — **not
a canonical sha**. Grading them "sha-witnessed" would name an artifact that does not exist; grading
them "proven" would understate a machine recomputation. They are entered as **exact,
two-instrument**, and the rubric is what is wrong here, not the figures.

**Note 2 — six published masses carry no interval, and are therefore ungraded.** TR-1's 36.4 % /
2×10⁻⁸ / 7.3×10⁻⁴, TR-8's ×11,364, and TR-10's ~1.1 % and 6.8×10⁻⁴ are weighted-Knuth estimator
outputs whose archived runs (`dav_tier1.out`, `dav2_tier1.out`, `f5_tier1.out`) **predate the
estimator's `se=` field**. They are not `estimated-with-CI` (no interval was published) and not
`scoped-sample` (the estimator samples the whole tree), so this ledger records them as
**UNRESOLVED** rather than inventing a grade. Closing them is a re-run, not a re-labelling.

**Three figures are deliberately absent because they are withdrawn, not graded:** TR-2's Bayes
factor (CX-26), TR-4's ≈3.3×10³⁷ orientation-dedup size (withdrawn 2026-08-24, it exceeds its own
31! ceiling by ~4,013×), and TR-8's ~6×10⁻⁵ dof-matched median (CX-27, withdrawn pending an
artifact that exists nowhere in the repository). A withdrawn figure has no confidence to record.

🔴 **Four suite-level inconsistencies this audit surfaced, none adjudicated here.** Each needs an
owner's ruling, and a ledger that silently picked a side would be asserting rather than recording:
(i) TR-5's abstract still reads *"the record-level orbit count is exactly N/24"* while METHODS.md
and TR-11 §9 were corrected on 2026-09-19 to state that N/24 is **2×** the sequence-orbit count;
(ii) TR-9 publishes **two** C5 ranges, −6.3 to −13.9 and −6.3 to −20.6, by construction;
(iii) TR-2's executive summary still leads with the Bayes factor that v1.27 withdraws;
(iv) the estimator self-consistency figure is quoted as 0.03 % in TR-1 and 0.09 % in TR-10.

## Verification Guide

Every claim type in this report, mapped to the command that checks it. Match tokens whole-line with
`grep -Fqx` — **`-F` is load-bearing** (§12.9 explains both directions in which plain `grep -qx`
fails on this document's own tokens).

- **Every figure in §12.1–§12.8** — `python3 solve.py --atlas-probe atlas_n31.json`. Prints
  `ATLAS_PROBE=PASS`, `ATLAS_PROBE_FAILS=0`, `ATLAS_GATE_COUNT=14`, `ATLAS_TAIL_CHECK_COUNT=5`; rc 0;
  under a second on the 5.98 MB JSON, no ladder and no cluster. The probe re-sums every table it
  reads against N before printing a figure that depends on it, and evaluates the one statistic
  needing a null against a deliberately wrong null so the reader can see it discriminates. The
  figure→token table is **§12.9**.
- **§12.10's two external anchors** — `python3 solve.py --atlas-queries atlas_n31.json --atlas-out DIR`.
  Exit status **1**, `TR12_A2_SLOT=FAIL`, `TR12_A3_EXTERNAL=FAIL`. The FAIL **is** the result (two
  populations differing by exactly C3), and exit 1 is the documented behaviour when any verdict
  written is a failure. `--atlas-q3-trace` is deliberately not required: it is a run artifact not
  distributed with this report.
- **The whole battery at laptop scale, no ladder** — `scripts/tr12_repro.sh --n9`: every row diffed
  verbatim against the committed goldens in `scripts/tr12_expected/n9/`, `QUERY_DRYRUN=PASS` on
  success, skips reported explicitly, non-zero exit on any mismatch. Currency check (milliseconds,
  no build): `scripts/tr12_repro_gate.sh --check` → `TR12_REPRO_GATE_CURRENT=YES|NO|UNKNOWN`. Full
  gate (~2 minutes on two cores, no network): `scripts/tr12_repro_gate.sh`, which **extracts** the
  published build line from `documentation/VERIFY.md` rather than trusting a copy.
- **The exact-count witness at n=13** — `./solve --kc-build D --f1-pairs 13 && ./solve --kc-count D`
  prints `2063395607040` (~352 ms to build, ~9 ms to count).
- **Q4(b), the C3 minimum = 112** — reproduce from published artifacts only:
  `./solve --check-arrangement "$(sed -n 's/^SEQ=//p' reports/certificates/c3_positional_witnesses.txt | head -1 | tr -s ' ' ,)"`
  → `C3 complement distance: HOLD (value 112, ceiling 776); verdict SUPER: IN`. The structural bound
  `G ≥ 12` plus this exhibited witness closes the bracket at its floor: **no bisection, no UNSAT leg
  and no DRAT certificate are required for the minimum** (§Q4).
- **Q7, the historical arrangements** — the three permutations are printed in full in §Q7; re-derive
  them with `python3 -c 'import solve;print(",".join(map(str,solve._r7_mawangdui())))'` (and the
  `_r7_fuxi` / `_r7_jingfang` twins) and feed each to `--check-arrangement` for its verdict and
  first-violated constraint. ⚠ The *witnesses* leg is a named skip — `TR12_Q7_WITNESSES=PENDING:kissat`
  — because `kissat` is absent; no non-KW named sequence receives a rank in this report.
  ⚠ *(corrected 2026-09-25, CX-93: the witnesses leg is a real row now. Re-derive it without any
  solver: `./solve --check-arrangement "$(sed -n 's/^SEQ=//p' reports/evidence/q7_witnesses/moore-strict.txt)"`
  must print IN for SUPER and for C15, and `sat.target_verdict(seq, "grand-strict")["ok"]` must be
  `True` for the `grand-strict.txt` sequence (both files pin the same ordering; README there). The
  rank is still not in this report — no n = 31 run has executed the row yet.)*
- **The ladders, if you hold or rebuild them** (§R Tier B) — logical/content:
  `./solve --f1c5-layer-sha DIR` against `runs/20260906_kc_ladders_n31/STAGE_{F,G,T}_LAYERSHA.txt`
  (32 rows/stage). Container/files: `sha256sum -c` against `STAGE_{F,G,T}_SHA256.txt` (65
  rows/stage). **Do not cross them** — they digest different byte streams. Both were executed by this
  project 2026-09-17: **96 of 96** logical (f, g, t), **65 of 65** container (t only; f and g were re-read
130 of 130 at copy-in), zero mismatches. A match says your
  ladder is byte-identical to the one every number here was computed against; it does **not** say the
  ladder is mathematically sound — that is `--kc-g-check` and `--kc-t-check`, different instruments.
- **Reader-side arithmetic, needing no project code** (rung 1) — N mod 24 = 0 on the published exact
  N; Π p_i = 1/N exactly over Q3's 31 rows; Σ_b solutions(b) = N; the f·g cut identity printing N at
  every layer.
- **The full three-tier spec** — §R: Tier A rebuilds everything from public source (the gold
  standard, and the only tier that establishes anything without trusting a registry this project
  published), Tier B checks a ladder you already hold, Tier C is the laptop tier above.

**What this tree does not let you check, stated so no reader hunts for it.** The atlas file itself
**is** distributed, at `runs/20260906_kc_ladders_n31/atlas_n31.json` (raw sha256
`9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558`), so the §12 figures can be
re-derived from it directly (`--atlas-probe`, `--atlas-queries`). What cannot be checked byte-for-byte is a **rebuild**: because the raw
digest embeds the build stamp and the ladder directory basenames, the digest a rebuild can actually
match is the provenance-normalised `923faa1b097cd364bbedd58044963df971809bf1c3d27765d29e84ae9f73071a`
(§12). ⚠ *(corrected 2026-09-24: this sentence read "The atlas file itself is **not distributed**", which
has been false since v1.10 tracked the file.)* The **ladder data** is not distributed; the per-layer registries are the published
fingerprint (§R Tier B). **No n=31 expected-output set is committed** — the production run minted its
own (§R Tier A step 6). `kissat` and `drat-trim` are absent, so the SAT legs are named skips. And
every **per-query** Q1–Q10 output here is **single-instrument**: no second engine computes it. Only
the full-31 totals |C1∩C2∩C4∩C5| and |C1∩C2∩C4| are two-instrument, independently recomputed by
`verify.c`'s transfer-walk engine — and both instruments are project-authored, so no third-party
recomputation of anything in this report exists.

---

## Revision history

| version | date | change |
|---|---|---|
| v1.0 | 2026-09-05 | **First public release.** The specification body is the 2026-07-17 text by Claude (Fable 5) and is unchanged in substance. Three publication passes ran before release and are recorded here because each changed what a reader is looking at. (1) A **figure → reproduction-command audit**: every asserted figure was classified, and those with neither a public citation nor a public reproduction command were **struck rather than shipped**, each strike saying in place what was removed and why. (2) A **public-anchor pass**: citations to internal working notes were replaced by a published document, a runnable command or a code site; the one citation for which no public anchor exists is recorded as exactly that; the ladder-publication question was resolved as **per-layer SHA registries are published, the ladder data is not distributed by this project**; and the H3b specification amendment is recorded in §0. (3) A **novelty scrub under the publication freeze**, temporarily removing priority assertions; the removals are registered verbatim so the scrub is a loan, not a deletion, and their restoration is separately gated. **Cost figures:** the earlier revision of §9 quoted a dollar band and an operator price quote for the declined exact-C3 run; both are withdrawn, and the **dollar figures are redacted rather than restated**, following `TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md` v1.10 — a withdrawal that requotes a number publishes it. **Withheld:** the standing single-branch-exhaustion shortfall factor is not quoted; it has no public reproduction command, and its public anchor is a run (`documentation/HISTORY.md` §"April 22, 2026 — Campaign A Pass 1"; `runs/20260422_passA_10T_d64_laggard/`), not a figure. **Corrected at release:** four sites reused framings this document retracts elsewhere in its own text — the exact C15 count described as an "obstruction" or "not computable" when §9 records it as **priced and permanently declined on cost** (TR-11 §10(ii) v1.5 having withdrawn the structural claim), and §R.0's ladder diagram carrying both the retracted chain arrows and the corrected fan annotations under one label. No count, definition, verdict or query specification changed in any pass |
| v1.1 | 2026-09-05 | **Ladder provisioning corrected — g is 8.27 TB, not "~4 TB like the others" (found by a reader's challenge, hours after v1.0 shipped).** §R.0's build section said "three catalog directories on ~4 TB disk each" and now carries the measured per-ladder table: f **3.29 TB**, g **8.27 TB** (2.5× f), t ~3.1 TB projected, **~14.7 TB total**. The same stale hedge — "~2.5-2.7 TB … the same size class as f" — was live in four `solve.c` sites including the `--kc-g-build` **runtime usage string**, which told a reproducer that "a second 4 TB disk or a shared 8 TB with the f ladder both work"; g alone exceeds 8 TB, so provisioning from that line ran out of disk partway through a multi-day build. All corrected, with `du -sb` as the reproduction command; `documentation/CAMPAIGN_METHODOLOGY.md`-style commodity contract wording clarified — TR-11 §7's "~64 GB RAM + ~4 TB disk" is the **f** contract, not per-ladder. The g comment had said "hedged, **unmeasured until the run**"; the run happened and nothing propagated the measurement back. See [CORRECTIONS.md](../documentation/CORRECTIONS.md). **Sha-neutral** (`403f7202…` measured before and after). No count, definition, verdict or query specification changed |
| v1.2 | 2026-09-12 | **Documentation tranche from the Fable adjudication of the Codex v3 KC-surface review (17 findings; no count, definition or verdict changed, and no query specification changed).** §0: \|C15\|'s "±0.02%" is relabelled as what TR-4 actually publishes — a relative standard error, `relerr = SE/mean` — with the 95 % CI `[1.3283, 1.3292]×10³⁸` printed beside it (V3B-03#4). §Q4: the ~9.91 % / ~10.11 % ceiling-tie shares now carry their public numerators (340,179,649 and 1,063,580,364 / 10,525,271,997) and name the two inputs that are **not** public — the 560 T `--c3-min` log and the T5 parquet (V3B-03#8); the Q4(a,c) output contract is restated once, with M, seed, level and **all three** Wilson tables including the per-bin one, the 2026-09-06 narrowing having been stale in the opposite direction (V3B-03#10). §Q5: C3 moves from "NOT DP-optimizable" to the small-extra-state class, since `C3 = 16 + 8·G` is machine-checked and running G is orbit-invariant (`runningG_orbit_invariant`) — the real obstruction is that the KC ladders carry no G channel and the full-31 run was declined on cost (V3A-134#10); the three shortlisted functionals are labelled **PROPOSED — no formula pinned, not in the extremal registry**, with `KC_X_REG`'s actual contents named (V3B-03#12). §Q6/V1/V2/V5: the `anchor_p` / `anchor_class_pct` formulae are given at the site, V1 gains its doubly-stochastic and zero-row conventions, and V2/V5 are stated in the reduced distance-class form the atlas schema actually carries (V3B-03#13). §Q7 prints the three arrangement arrays (V3B-03#14); §Q8 prints the seed, K, bucket rule, `χ² = (16·S − k²)/k`, the 37.70 bar and the 20.224 anchor (V3B-03#15). §R.0's blanket "no published count can be reproduced without the catalog" is narrowed to the per-query table it contradicted — `--kc-count`, REL rank/unrank and `--kc-sample` all run from f alone, and Q4b/Q7/Q9 need no ladder (V3A-086#7); the ladder-size table states its basis per row, cites the 65-file archive registry, and records peak build space as UNMEASURED (V3B-03#33); the sha-invariance sentence is split into the codec proof and the **observed** compiler/flag/architecture property (V3B-03#35). §10E now says the suite publishes at least three exact cells plus one estimate (V3A-086#9); §10G states that TR-11's validation confirms the estimator envelope rather than tightening any interval (V3A-086#6). §11: the Suenaga 2012 firstness wording is replaced by the independent-arrival form its own bibliography entry adopted on 2026-08-28 (V3A-086#8), Q10(a) is matched to what the battery measures including `TR12_Q10A_KWRANK=EMPTY:class-rank-uncomputable-under-kw-labels`, and Q10(b) is marked undefined — no subgroup set, no coset-id map — ahead of any producer (V3B-03#41). §3 cites the throughput anchors by battery row name `c_xa_cd` instead of a line number that had moved (V3A-044#6) |
| v1.3 | 2026-09-18 | **The published registries are now exercised, not merely published — both Tier-B checks executed against the live ladders, zero mismatches.** §R Tier B previously described two registry checks a reader *could* run and recorded the logical one as cost-gated; it now records that this project ran both. **Logical (content): 96 of 96** layer digests — 32 f + 32 g + 32 t — match `STAGE_{F,G,T}_LAYERSHA.txt` via `./solve --f1c5-layer-sha DIR`. **Container (files): 65 of 65** t files match `STAGE_T_SHA256.txt` via `sha256sum -c`, hashed directly from the read-only managed disk and published as `runs/20260906_kc_ladders_n31/STAGE_T_RAW_VERIFY.md`. The container check closed a real asymmetry: f and g were re-read off the device at copy-in (`dd iflag=direct` after dropping the page cache, 130/130) but **t is never copied** — it is the original disk mounted read-only — so nothing had ever hashed t's bytes as they sit today; both prior t checks (`--kc-t-check`, and builder-record-vs-registry) are real but neither reads the disk in its present state. **The ~40 h cost gate on the logical sweep rested on a false premise:** that figure was *per-process and serial*, and because `--f1c5-layer-sha` accepts FILE arguments the layers digest concurrently, so the wall cost is set by the largest single layer rather than by the sum — all 96 completed in **7 h 11 min**, `g_layer_16` the makespan at 25,868 s. The battery row still reports `TR12_TSHA=SKIP:cost-gated`, because the battery does not run that pass inline; the row and the question have different answers, and that distinction is stated at the site rather than left for a reader to reconcile. The container row also states its **framing era** (RAW, post-#169: the registry holds each file as stored, gzip framing included, so `sha256sum -c` is correct there and needs no `gzip -dc`) — without that qualifier a reader arriving from the logical registry would follow the recipe, see `FAILED` on a byte-correct artifact, and conclude the ladder was corrupt. **Scope, stated so the PASS is not over-read:** these are integrity results about bytes. They do not prove the ladders are mathematically sound — that is `--kc-t-check` and `--kc-g-check`, different instruments — and the §1 completion criterion for the SUPER probes is **not** asserted met here, since it also requires `TR12_GCHECK`, whose n=31 run was still executing at the time of this revision. No count, definition, verdict or query specification changed |
| v1.4 | 2026-09-18 | **§R understated the reproduction cost of the atlas step — the one number a reproducer budgets against.** §R priced atlas assembly as a rounding error and said the steps after it run "in minutes"; the second half is right, the first was not. `--kc-scan-merge` does not merely assemble, it **re-digests every f and g layer** before writing the atlas. **Measured 2026-09-18** on the n=31 ladders: scope is f layers 0..30 plus g layers 1..31 — **62 layers, 43.91 TB decompressed** — at a measured single-process rate of **258.7 MB/s**, i.e. **~47 h of wall time**, which makes it the dominant cost of a reproduction once the ladders exist. The earlier figure is **withdrawn rather than restated**, following the rule this report applied to the declined exact-C3 run in v1.0. Two further facts a reproducer needs, because both change what is worth trying. (i) The merge is **single-threaded by construction** — plain digest nest, no OpenMP, no threads knob on the subcommand — so a 64-core host does not shorten it. (ii) It is **not parallelisable for already-banked chunks by patching the engine**: `kc_scan_merge` leg 2 refuses a chunk whose `engine_source_sha` is present and does not match, and that field is the sha256 of `solve.c` itself, so *any* patched binary is refused outright and the only route around it is re-scanning every chunk. A parallel digest pre-pass was built and proved correct for a future lineage — merged atlas byte-identical on a full sha, with both a positive and a negative control firing — and is mentioned here only so the ~47 h is not mistaken for something a reader can optimise away on already-banked data. **Scope, so the figure is not over-read:** the hours are measured on this project's hardware and will move with the reader's; the layer count and the decompressed volume are properties of the n=31 ladders and will not. No count, definition, verdict or query specification changed |
| v1.5 | 2026-09-19 | **Four documentation defects cured from the Fable adjudication of the Codex v3 lens-B review (V3B-03): one published arithmetic error, three labels that understated this project's own verification. No count, definition, verdict or query specification changed, and no published figure moves.** **§EW-2 (V3B-03#25) — the substantive one.** The multiple-comparisons clause read *"a 10⁻⁴ tail in a 100-family screen is NOISE, said so"*. That is **false** at the α this suite publishes under: Bonferroni-adjusting gives 10⁻⁴ × 100 = 10⁻², and 10⁻² < 0.05, so such a tail is significant — equivalently it clears the per-candidate bar 0.05/100 = 5×10⁻⁴ by ~5×. The clause now states the adjusted threshold explicitly, names the correction family and α ([METHODS.md](METHODS.md) §"Statistics conventions"), and requires EW-2's pre-registration to pin α alongside the candidate list and family size. The sentence was illustrative and **EW-2 has not run**, so no published tail is affected. **§R independence-ladder labels (V3B-03#36).** The report inherited TR-11 §10(vi)'s single-instrument caveat for *both* tiers — a caveat TR-11 retired for the totals on 2026-07-26 as a *"stale label"*. It now splits: the full-31 totals \|C1∩C2∩C4∩C5\| and \|C1∩C2∩C4\| are **two-instrument** (`verify.c`'s inclusion–exclusion transfer-walk, full scale, exact MATCH, mod-24 gated), while every **per-query** Q1–Q10 output is **single-instrument**. This report had carried the string `two-instrument` **zero times**, so the defect ran against interest. TR-11's honest residual — both instruments are project-authored — is restated, not cured. **§11 Q4 (V3B-03#42).** *"P(G ≤ 95) … exact via the G-channel DP"* is exact **of the DP-defined law**: at production size there is no theorem asserting that bin g of the DP histogram counts the permutations whose G equals g, the bridge being machine-checked only at (2,1,5)/(2,3,7)/(3,1,7). The row now carries that qualifier and cites [lean/README.md](../lean/README.md) lines 90-99, which already carried the argument; the rational and the ≈8.106% are **unchanged**. **§11 Q9 (V3B-03#43).** The 8 forced literature rules were called *"PROVEN constants"* without the qualifier lean/README.md lines 62-70 states: **Lean-proven modulo a validated transcription**, the `countP`→`reg_*` identification being a non-Lean step whose 5,449-sequence validator is a scratchpad script with zero occurrences in the public tree. Qualifier and pointer added; the theorem itself is kernel-checked. **Not cured here, recorded so it is not mistaken for closed:** the EW-2 pre-registration hash a reader would check (`ew_prereg_lock`) remains unpublished, and the `c1_constants_check.py` validator remains absent from the public tree — both are publication actions, not text edits, and neither is claimed done |
| v1.6 | 2026-09-21 | **§12 added — this document's first results section: what the n=31 atlas establishes, measured from the atlas alone, every figure beside the one public command that reproduces it.** The command is new in this revision: `python3 solve.py --atlas-probe ATLAS.json` (ported into `solve.py` under the single-file rule, every token named in `documentation/SOLVE_PY_CLI.md`, gated by `tests.py TestAtlasProbe` on a real n=9 atlas with a red mutant and a refused quotient-only atlas). The atlas is pinned by sha256 and `engine_git`; the file is not distributed. **Six results.** (12.1) The C5 budget is a run parameter recovered exactly from the `by_class` column sums — `2,8,13,7,1` at full-31, `2,5,0,2,0` at n=9 — and the small-n zero-mass classes are its consequence via one predicate, so the n=13 `d3`/`d6` zeros are a local budget fact and not a question at n=31; corroborated by the f- and t-ladder manifests' `b0=` line and by `documentation/F1C5_LAYER_FORMAT.md`. (12.2) 68.67 % of the pruned-DFS tree, in t-units, is doomed prefixes — none before layer 9, a layer's majority from layer 25 — a ratio that leaves the withheld XA exhaustibility call untouched. (12.3) King Wen's own transition sits in the bottom quartile of its distance class by walk mass at 24 of 31 steps, mean percentile 0.219 against a stated null mean of 0.5; the steps are dependent, so it is published as a pointer with no p-value, and the instrument that would calibrate it is named. (12.4) The raw one-step kernel is stationary to TV ≤ 0.001 over layers 6–23 and scores King Wen 0.10 bits below the population mean — a **negative** result, entered under Q9. (12.5) The positional pair field is flat to ~3 % and King Wen's placements are typical of it — a **negative** reading of V1, entered under Q9. (12.6) The C5 budget path is within TV 0.042 of the exchangeable null with one-sided front-loading suppression, controlled against a wrong null (×10) and against n=9 (0.36); the measurement ships, and the claim that near-exchangeability is informative is **withheld** pending an argument either way. **One narrowing, in place** (§11 Q10(b), CX-58): the 2026-09-20 feasibility clause "no coset projection can be aggregated out of those tables at any price" is true of the five accumulators it names and reaches past them — the same scan pass persists the raw kernel, which gives the step-difference reading a zero-data-cost projection and the mask-level reading nothing; under either reading the blocker is the definition, as line 1597 (at `fa5a98dd`) already said, and no row moves. The "what this document is" paragraph is annotated so that its "no full-31 answers are stated here" reads as the rule for the question set. **Same-day adversarial review of this revision (Fable, before push):** every §12.9 token re-executed against the pinned atlas and matched whole-line, 42 of 42, with a negative control; the 59 values shared with the private generation probe re-compared, 0 differing. The review found the probe could return `ATLAS_PROBE=PASS` over a `by_class` table whose rows summed to 2N and 0, and over a `marginal_raw` row summing to 2N — its "re-sums every table" claim held for six tables and not those two, which it had trusted from the atlas's self-reported gate booleans. Four cross-table gates were added (`BY_CLASS_ROW_SUMS_EQ_N_EVERY_LAYER`, `MARGINAL_RAW_ROW_SUMS_EQ_N_EVERY_LAYER`, `KERNEL_CLASS_MARGINALS_EQ_BY_CLASS_EVERY_LAYER`, `KERNEL_ENTRY_PAIR_MARGINALS_EQ_MARGINAL_RAW_EVERY_LAYER`), each red-tested in `tests.py` with the older gates asserted green so the new one is proven load-bearing; two tokens now carry the 12.1 claims that had none (`CLASSES_WITH_ZERO_MASS_AT_SOME_LAYER_K_GE_1=NONE`, `LARGEST_CLASS_SET_OVER_LAYERS=d3` — `D3_MIN_LAYER_SHARE=0.40687` alone does not establish "largest at every layer"); and the self-reported gate and tail-check counts are printed (`ATLAS_GATE_COUNT=14`, `ATLAS_TAIL_CHECK_COUNT=5`), since `{"fails": 0}` alone satisfied both verdicts. No figure in §12 moved. No query definition, verdict or count changes; §12 is additive |
| v1.7 | 2026-09-22 | **§12.10 added — the two external-anchor checks, first executed at n=31, disagree with the published references by about twelve times tolerance.** `TR12_A2_SLOT` and `TR12_A3_EXTERNAL` set this compiler's SUPER-space values against numbers TR-7 published for C1–C5; below full-31 both return `SKIP:n=<n>`, and 2026-09-22 was the first time either ran. The disagreement is a fact about the two populations. **This program is built on C1, C2, C4 and C5 only and has no C3 channel** (§0), so although the conditioning sets differ by exactly C3 and TR-7's published uncertainties exclude estimator error on its side, the attribution is an INFERENCE and not a measurement of C3 by this program. No published figure changes and nothing is retracted — §12 predates the consumer run and made no A2/A3 claim. Two rows added to §12.9 annotating why a FAIL there is a result. |
| v1.8 | 2026-09-22 | **Two published figures were wrong and one published sentence was false; both were found by independent re-derivation rather than by re-running the instrument against itself.** **(1) §12.6's "total-variation distance" was not one (CX-60).** The statistic summed `½Σ\|P−Q\|` over the cells the atlas *stores*, and `rid_mass` stores only cells of nonzero observed mass; both nulls place mass outside that support, so the `½·Q(Sᶜ)` term the definition requires was never added. **The n=31 headline `EXCHANGEABLE_NULL_TV_MAX_OVER_LAYERS=0.0415` is UNCHANGED** — layer 4, where the maximum falls, omits no mass — and "≤ 0.0415 at every layer" still holds. What moves: the wrong-null control `CONTROL_WRONG_NULL_PRODUCT_FORM_TV_MAX` **0.4145 → 0.8289** and the ratio `CONTROL_WRONG_NULL_TV_OVER_EXCHANGEABLE_TV` **9.99 → 19.97** (§12.6 "reads 0.41, ten times larger" → "reads 0.83, about twenty times larger"); and at n=9 **0.3554 → 0.5686**, **0.2927 → 0.5854**, **0.82 → 1.03**. 🔴 **The qualitative claim inverts:** the control ratio was published as *below 1 at n=9* and is now *just above 1*, corrected here and at `documentation/SOLVE_PY_CLI.md`. The control discriminates by more than was claimed, so this section's argument is unchanged and only its numbers are. **The n=9 provenance is now stated rather than implied:** those figures come from an atlas rebuilt with the four-command n=9 recipe, **not** from a committed fixture — no n=9 atlas ships in this tree — and the rebuilt-atlas values are printed at the site. **(2) §12's reproduction contract was unsatisfiable as printed (CX-61).** §12 said the pinned digest is published "so a Tier-A rebuild … can be checked against it", while §R Tier A step 2 printed a build line carrying **no `-DGIT_HASH`/`-DSOURCE_SHA`** — so a rebuilt atlas records `engine_git "unknown"` and could never hash to `9d6ba3d2…`. The hashed bytes further embed the ladder directory **basenames** `run_f`/`run_g`/`run_t`, which §R names as `FDIR`/`GDIR`/`TDIR`, so even a correctly flagged rebuild in differently named directories misses. Step 2 now prints `documentation/VERIFY.md` Stage 0's flagged line with `--short=12` (the pinned `engine_git` is 12 hex; a bare `--short` yields 8 here), and §12 states the basenames and publishes the **provenance-normalised content digest `923faa1b…`** — the five provenance fields set to `"-"` — which is invariant to build stamp and directory naming and is what a rebuild can actually match. This is the promise an archival export makes about its own reproducibility, so it is stated truthfully rather than repaired with a recipe that still would not reproduce. **(3) §12.10's rescaling sentence was false (CX-63).** It said the population difference "does not perturb that histogram, it **rescales** it, uniformly across both circle-adjacent slots". Measured over all 31 slots the published/atlas ratio runs **0.872 (slot 17) to 1.234 (slot 32)**, and since both histograms sum to 1 a uniform rescaling is arithmetically impossible. C3-conditioning **reshapes** the histogram: it enriches the two circle-adjacent slots ×1.23 and depletes the interior by up to 13 %. The three-cell arithmetic the sentence generalised from is correct and unchanged. A new measured consequence is recorded: on SUPER the A2 slot histogram is **flat** away from the circle-adjacent slots (interior 0.0297–0.0326 against 1/31), so TR-7's U-shape is attributable to C3 — a further negative under Q9. **(4) Reader instructions that cannot match their own tokens (CX-62).** §12 told readers to match with `grep -qx`, which is a **regex** match: the two tokens carrying `digits=[…]` fail to match their own output line, while a corrupted `DOOMED_FRACTION_OF_T_ROOT=0x686725` spuriously satisfies the published `0.686725` pattern. Both directions measured; every reader instruction in §12 and `SOLVE_PY_CLI.md` is now `grep -Fqx`. **(5) Four sites contradicting this document's own text, and a harness asserting work never done.** §12's intro claimed "one public command and no other input" for a section whose §12.10 has a second command and a TR-7 input; the Q5 caveat and shortlist still read DEFERRED where §9 records the edit-distance extremal **CLOSED** at distance 2; the Tier B heading read "(minutes, ~$0 compute)" against its own measured **7 h 11 min**; the §R.0 diagram read "g reads f" against the step-2 heading "standalone, takes NO FDIR" (CX-66). In `scripts/tr12_repro.sh`, the `SKIP:banked-pre-scan` reason claimed the pre-scan run "already took this ladder's digests" when the pre-scan receipts carry `SKIP:cost-gated` — the digests were never taken by any run — and `TR12_Q2` printed PASS beside two cost-gated legs its own published completion contract requires; the reason string now says what happened and the contract is **enforced** rather than weakened (CX-65). `documentation/QUERY_INVENTORY.md`'s "36-step run order" is re-counted as **37** (CX-64). No count, definition or query specification changes; the three moved figures above are the only published values affected. **Four further corrections landed in this same revision, none of which moves a figure but each of which changes what the document asserts** — and they are listed here because a revision row that stops at the figures understates what a reader should re-read. **(4) CX-67:** the entry CX-52 certified a neighbouring skip reason as "already correct" and it was false; that certification is withdrawn, CX-52 itself untouched, and the reason at the latent `--kc-t-check` branch now names the real provenance of the banked PASS. **(5) CX-68:** §12.4 concluded the one-step kernel "cannot tell" King Wen from a typical walk from −0.102 bits with **no dispersion, percentile or threshold computed anywhere**; the scale is now printed (independent-step SD 1.943 bits, so −0.102 is 0.05 of it; SD at most 10.794 bits under any dependence) and the conclusion is entered as *not distinguished at the one-step scale measured*. §12.5's sibling claim is scoped from marginals to marginals, with the joint placement pattern named as not asked. **(6) CX-69:** §12.4 and §12.7 published a **cost** limit as a **capability** limit — two-step joints CAN be formed from f and g, at a derived 27.6× the first scan naively or ≈2.3× by reusing the one-step lookups; §12.7's sibling per-branch clause is marked **not adjudicated** rather than silently carried. **(7) CX-70:** the wrong-null control's 0.83 is, to four decimals, the mass a product form puts **off the budget hyperplane** where no walk can be, so it mostly shows that a product form ignores the budget identity rather than that the digits are dependent given it; conditioned and renormalised it reads 0.1333 at n=31 and 0.1948 at n=9. The number is unchanged; the sentence around it is not |
| v1.9 | 2026-09-22 | **Three further corrections from the same two Codex reviews, landed after v1.8 was published rather than folded into it, because v1.8 was already live and silently growing a published revision is its own defect.** **(1) §12.4's six full-precision figures now have a public command (CX-72).** §12 promises that one command reproduces every figure in §12.1–§12.8, and these six were the exception: `KERNEL_TV_ADJACENT_LAYERS_K1_TO_KNM1` prints four decimals, at which 0.00099 and 0.0010 are indistinguishable, so four layers could not be told apart from the public output and the digits rested on a private recomputation. A new token, `KERNEL_TV_ADJACENT_LAYERS_K1_TO_KNM1_FULL`, emits the same vector at ten decimals. **Every published figure is reproduced exactly and none moves** — k=4 `0.0049787974`, k=5 `0.0011054067`, k=24 `0.0002900820`, k=25 `0.0010072525`, k=26 `0.0010246560`, window maximum `0.0009874424`. The alternative cure, narrowing §12's promise to exclude them, would also have made the document true and would have left the reader with less: **a reproduction gap is better closed by publishing more output than by claiming less.** **(2) §12.10 no longer argues that a disagreement certifies its instruments (CX-71).** It read *"Both FAIL — a fact about the two populations, not a defect in either instrument"*; a population difference **explains** a disagreement and **certifies** nothing, since a FAIL is equally consistent with a genuine gap and with a fault, and only each instrument's own gates separate them. This was the unswept sibling of a v1.7 pre-push cure applied one sentence later. **(3) Three harness statements that misdescribed what the run did (CX-73)** — a skip reason naming a deliverable, `tr12/q9_negatives.md`, that has never existed in this repository; a skip justified by a subsumption that does not hold, since the digest pass binds bytes to sidecar while the identity row binds sidecar to the published registry; and both `--regen` arms reporting `TR12_REPRO_GOLDEN_STATE=DIFFED` while having written every block and diffed nothing. None is reachable on the production path, so no shipped verdict changes. No count, definition, query specification or published figure changes in this revision |
| v1.10 | 2026-09-23 | **Finalization: the report is brought into the house format, and its framing is closed on a program that has finished.** Measured against TR-1..TR-11, all eleven carry six elements this report carried none of; all six are added. A `# TR-N — Title` **title form** (the trailing 2026-07-17 date moves to this table, where the v1.0 row already records that provenance); the **METHODS.md** line; an **Executive summary** stating what the program asked, what it answered at n=31, and what it withheld; a single-paragraph **Abstract**; a **Sections** map, which for a document this long is the element whose absence cost a referee most; and a **Verification Guide** mapping every claim type to the command that checks it, including a closing paragraph on what this tree does **not** let a reader check. Two elements **no** other report carries are removed: the dated draft byline, whose facts the Attribution section already carried, and the `STATUS: executable SPECIFICATION, not an execution order` box, whose framing had been overtaken — the ladders were built and registry-checked, the atlas assembled 2026-09-21, the queries run 2026-09-22. The attribution is promoted to a `## Attribution` section in TR-11's form. **Tense and staleness, ~30 sites.** The head no longer opens by denying it has results: it reads "a question set (§0–§11) with a results section (§12)". A pre-registration caveat read "what **will** be asked and how it **will** be checked"; Stage G read "reviewed, run pending" against a ladder built in 2026-09 at 8.27 TB with 32 of 32 digests registered; §7's wave table, §8's worklist heading and §6's heading read as plans. **Three honest limitations had their tense closed without being weakened:** the SAT C3-min instrument "does not **yet** exist" becomes "does not exist in this repository", with the added point that running it for the minimum would re-derive 112 with zero UNSAT legs; "EW-2 **has not** run" becomes "was not run", naming the wave-3 budget as the reason; and the n=31 expected set is stated as not committed, with the minted blocks named as an unpublished publication action rather than as something that cannot exist. **Two published pointers were checked and found stale:** `scripts/tr12_repro.sh` is **3,531 lines**, not the 1,570 recorded at two sites, and §8's build status is re-pinned from `76e5d680` to `d6b1334e` with each row's argv string re-greped 2026-09-23. **One instruction pointed at nothing:** §R Tier A step 6 told a reproducer to diff against `EXPECTED-Q1`-through-`EXPECTED-XA` blocks that **have never existed in this report**; it now names the real objects, the per-row files under `scripts/tr12_expected/n9/`. **One false sentence:** §3 said "no atlas number ships before this certificate" while §12.2 ships t-unit ratios — scoped to numbers *priced in production-DFS nodes*, which is what the certificate governs and what keeps the withheld exhaustibility call withheld. **Spec-era output paths are labelled once, in §0**, after measurement: the `tr12/` prefix is a directory a reader chooses and is tracked nowhere here, the basenames are what `--atlas-out DIR` really writes, and three spec names correspond to nothing at HEAD. The 2026-07-17 cost-band caveat **moves from the last screen to §0**, where a reader meets it before the bands rather than after all of them, extended with each wave's execution status. **Figures: three of five now exist and are embedded** (§2) — V1 the positional-marginal field, V2 the mass river with its branch panel, V5 the transition grammar — each with the space label, a reproduction pointer and its content digest. Both reduced forms are declared rather than glossed: V2 carries no branch-class split and V5 no cross-tab, and because only the distance-class axis exists **V5 and V2's upper panel plot the same numbers**, which the captions say outright. **V3 and V4 are stated as not rendered**: both need the now-cold ladders, and V3 additionally needs an emitter that does not exist. **Deliberately not done, and not to be read as closed:** no git tag is minted, so the two REPRO-TAG pins stand; §10's DONE-contract MUSTs A and B are neither delivered nor retired; and the n=31 battery's verdict set is not published, so §11 Q10(a)'s forced prediction is **left as a prediction** rather than restated as measured — a "measured" claim resting on a private anchor is the defect class v1.0 struck. No count, definition, verdict, query specification or published figure changes in this revision |
| v1.11 | 2026-09-23 | **The report stops failing its own contract, and the receipt behind its conclusions is published.** §10 has declared `§Open Problems` and `§Confidence Ledger` MUST since 2026-07-17 and neither existed; a referee checks a document against its own stated requirements first, so both are **written rather than retired**. §Open Problems states twelve questions, classifies each by §10.A's own scheme, and cites where its partial state lives — and names separately what was *closed* rather than deferred, because the C3 minimum **112** is settled (a structural bound `G ≥ 12` met by a published witness) and listing it as open would be a false debt. One row is recorded as **not fitting** the four-way classification: Q10(b) is a definition gap before it is anything else. §Confidence Ledger grades one row per headline figure across TR-1…TR-12 with the artifact a referee should pull, and carries two notes that matter more than the table: **the rubric needs a sixth grade** — `\|C1∩C2∩C4\|`, `\|C1∩C2∩C4∩C5\|`, C1–C7-with-C3-dropped and `\|C1∩C2\|` are exact at full scale and independently recomputed by a second engine sharing no code, but their witness is a reproduction command plus a reader-side mod-24 or CRT gate, **not a canonical sha**, so calling them "sha-witnessed" would name an artifact that does not exist — and **six published masses carry no interval and are therefore left UNRESOLVED rather than given an invented grade**, their archived runs predating the estimator's `se=` field. Three withdrawn figures are deliberately absent: a withdrawn figure has no confidence to record. Four suite-level inconsistencies are surfaced and **none is adjudicated here**, since a ledger that silently picked a side would be asserting rather than recording. **The n=31 battery receipt is now public** at `reports/evidence/tr12/` — 42 PASS, 32 SKIP, 6 DOC-only, 5 PENDING, **3 FAIL** ⚠ *(this tally double-counts; corrected in v1.12: 42 PASS, 32 SKIP of which 6 are `SKIP:doc-only`, 3 PENDING, 3 FAIL)* — and all three FAILs are the single A2/A3 population disagreement §12.10 already publishes **as the result**; two host paths carrying a cloud username are redacted to `<RUNDIR>` and **no verdict token changed**, checked by diff. The g-check that did run is published beside it as `reports/KC_G_CHECK_n31.txt` (PASS at every layer 0..31, 0 failing layers). **`[REPRO-TAG]` is resolved**: both pins now name `tr12-v1.10`, minted at this commit and pushed before the line shipped — the tag-before-anything order the placeholder existed to enforce. §11's Q10(a) forced prediction becomes a **measured null**, because the 2026-09-22 run emitted it and the receipt saying so is now citable. `reports/METHODS.md` §Artifact access covered nine of eleven reports and **said nothing about TR-12** while TR-12's own header pointed readers there for artifact access; it now names the ladders, the registries and the distributed atlas. No count, definition, query specification or published figure changes in this revision |
| v1.12 *(current)* | 2026-09-24 | **All five §2 figures are embedded, one published caption claim is withdrawn, and a review pass corrects seven sentences that had gone stale against the tree (CX-75).** **(1) V2's branch-panel caption is withdrawn.** It read that *"mass and cost do not track each other, so a small branch need not be a cheap one"*, and the rendered subtitle said *"a small-but-expensive branch is the atlas's point"*. The committed table says the opposite: the 56 branches fall into 7 mass levels that map one-to-one onto 7 cost levels, **0 of 1,540** branch pairs have the smaller mass with the larger cost, and cost per solution spans only 7.65–8.20 t-units. Caption, alt text, subtitle and `viz/viz_kc_river.md` now say **co-monotone**, and V2 is re-rendered. **(2) V3 is rendered**, from `tr12/v3_spectrum.tsv`, produced by the new `solve.py --v3-spectrum` join over the rank grid that had existed all along. v1.11 had said the join was a missing emitter, and CX-74 had called V3 genuinely unrendered. The four KW-anchored panels are deliberately unlined, and the caption states the measured negative (\|r(x)\| < 0.073 on all seven observables), names the two near-constant panels as properties of SUPER rather than of the index, and notes the 32-block structure of the REL grid, which no observable follows. §Open Problems row 5 is retitled to what is actually open: `TR12_V3_FIG` cannot clear by measurement while no battery row runs the join (it had claimed the token clears on the next full-31 run). **(3) V5 is no longer a re-plot of V2, and what it adds is stated at its true size.** It gains its pinned second axis `w = popcount(entry XOR exit)` (operator ruling on §2's undefined "new-pair category"), derived consumer-side from the persisted kernel, and reads `TR12_V5=PASS`. The v1.10 statement that V5 and V2's upper panel "plot the same numbers" was true of the reduced form and is retired with it. §2's V5 specification row, the figures-section header ("Three of the five are rendered") and the V5 alt text (five rows → fifteen) follow. A draft of this revision captioned V5's independence from V2 as "MEASURED" at a maximum deviation from factorisation of 0.173. That figure was the product of the marginals at a layer-0 cell whose joint is identically zero, because C4 pins the exit and only 7 of 15 cells are admissible. On layers 1–30 the joint is within **0.0097** of the product of its marginals, so what V5 adds over V2 is `P(w\|k)`, not a measured d–w dependence. The caption says so, citing four new `--atlas-probe` tokens (`V5_FACTORISATION_MAX_DEV_ALL`, `V5_FACTORISATION_MAX_DEV_K_GE_1`, `V5_K0_ADMISSIBLE_DW_CELLS`, `V5_K0_MAX_DEV_CELL_JOINT_AND_PRODUCT`). Figure-side: V5's title is static per branch and wrapped, and V3 gains x-axis labels and a subtitle. **(4) §12.5's and V1's interior range is corrected.** Both read that every interior cell lies in 0.0205–0.0636. That range is `MARGINAL_RAW_NONZERO_CELL_MIN_MAX` over **all 31** slots, and both extremes are end slots. The interior slots 3–31 lie in **0.0297–0.0345** against 1/31 = 0.0323, printed by the new token `MARGINAL_RAW_NONZERO_CELL_MIN_MAX_INTERIOR`. The correction narrows a published range and moves no conclusion: the reading of V1 was already that the field is flat. **(5) The scale figure is embedded once**, in the scope section, with both space labels in its caption: the canonicals are node-budgeted slices of C1–C5 whose record counts are lower bounds, and N is the exact count of the C1C2C4C5-superspace, with no C3. The caption also carries a **counting-unit note**, added before first publication (Codex V3A-147#1, adjudicated by Fable): a record is one canonical pair ordering with orientation masked, of which C4 allows at most 31! ≈ 8.2×10³³, while N counts orientation-explicit sequences, each pair ordering contributing a fiber of 1 to 2³¹ of them. N/31! ≈ 133,415, so between 5.1 and 9.3 of the plotted 29 decades are a change of unit rather than a budget shortfall, and in like units the superspace is 19.7–23.9 decades above the 560T count. The plotted ratio, 1.04×10²⁹, is unchanged; the caption no longer calls the deepest canonical "29 decades short". **(6) Seven stale sentences, from an adversarial review of the working tree.** §0 said no `tr12/` directory is tracked, and thirteen files are. §12 and the Verification Guide said the atlas is not distributed, but it is tracked at `runs/20260906_kc_ladders_n31/atlas_n31.json` and METHODS.md already said so. §Open Problems row 12 said the pre-scan run took the ladder digests, repeating a reason string CX-65 had already retired. No battery run took them; the standalone 2026-09-17 sweep did. The Executive summary and Confidence Ledger gave "65 of 65 container digests" without saying it was t only. The n=31 `--kc-t-check` PASS record (`runs/20260906_kc_ladders_n31/KC_T_CHECK_n31.txt`) was cited nowhere, though §12.2 rests on the t ladder, and it is now cited in §12.2, §R Tier B, row 12 and the Ledger. The receipt README's tally double-counted: the six DOC-only rows sit inside the 32 SKIPs, and there are 3 PENDING tokens, not 5. It now also records that `TR12_Q2=PASS` predates the driver's Q2 contract and would read `SKIP:leg-TR12_GSHA` today, together with the four reason strings the receipt carries that are false at HEAD. No count, definition or query specification changes. The published statements that change are V2's branch-panel caption and subtitle (withdrawn) and §12.5's and V1's interior range (narrowed) |
