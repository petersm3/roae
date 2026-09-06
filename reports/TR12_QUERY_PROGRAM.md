# TR-12 QUERY PROGRAM — Distinguished Elements of the Solution Space — 2026-07-17
*Technical report — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. One caveat is structural, and it frames all the rest: the same
author wrote the claims, the software that checks them, and this report that grades the check.
Verification here is independent in mechanism, never in authorship; no independent party has yet
audited or reproduced any of it (METHODS.md §"Authorship independence").*

**2026-07-17. Claude (Fable 5). Developed with AI assistance (Claude, Anthropic).**

> **STATUS: executable SPECIFICATION, not an execution order.** Nothing here fires autonomously:
> every unbuilt `solve.c` surface is under the project's standing operator gate for engine code, and
> every run above small-worker scale is cost-gated. Sections marked TO-BUILD in the 2026-07-17 text
> are annotated in §8 with their status at public `main` HEAD; most have since shipped.

---

## What this document is, and what it is not

**It is a question set, not a results report.** This is the specification of a query program
against the compiled solution catalog: for each query, the exact definition, the space label, the
instrument, the cost band, the output shape, and the check a reader can re-run. **The full-31
answers are not computed here and are not stated here.** Where a number appears it is one of
three things, and never a fourth: (i) a quantity already published in TR-1…TR-11 or
`documentation/`, cited; (ii) a quantity with a public reproduction command, printed beside it;
(iii) a cost band or plan parameter, labelled `[ESTIMATED]`. **No figure in this document is
asserted ahead of its reproduction command.** Several figures that once appeared here had neither
a public command nor a public citation; they have been struck rather than shipped, and each
strike says in place what was removed and why.

**It is not a pre-registration, and does not claim to be one.** Publishing a question set before
its answers exist is not the same act as registering those questions with a checkable timestamp
and a per-query pre-hoc/post-hoc provenance label. **This document carries no such labels and
makes no claim about when any individual query was first written.** A reader should treat the
program as a specification of what will be asked and how it will be checked — nothing more. Any
future use of it as a pre-registration would require that per-query provenance work to be done
first, and it has not been.

**Reproduction is already public and does not depend on this document.** The battery driver
(`scripts/tr12_repro.sh`), its committed expected outputs (`scripts/tr12_expected/n9/`), the run
order and hardware notes (`documentation/VERIFY.md` §"TR-12 query program"), the five figure specs
(`viz/viz_kc_*.md`) and the gate scripts are all on public `main`. §R below is the methods
specification behind them, not a substitute for them.

---

## 0. Conventions every item below inherits

**Spaces (the C-8 label discipline; used on every quantity).**
- **SUPER** = C1∩C2∩C4∩C5, the compiled walk superspace. |SUPER| = N =
  **1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097051×10³⁹** (exact; TR-11 §9;
  log₂ N ≈ 129.689 bits — reader arithmetic on the published exact N, e.g.
  `python3 -c "import math;print(math.log2(1097051278789181790036112071176579186688))"`;
  N/24 exact). Orientation-explicit walks, C4's pair pinned.
- **C15** = C1–C5 (C3 applied). |C15| = **1.3287×10³⁸, ESTIMATE** (TR-4; ±0.02%); **no
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
  any project document. (The step-by-step derivation is an internal proof note; it is not cited,
  because nothing above needs it.) Every C15 query
  passes `--kc-c3-max 387`, never 776.

**Orders (never conflated).**
- **REL** = reverse-exit lexicographic — the compiler's native descent order; `--kc-rank/--kc-unrank`
  implement it TODAY from forward layers alone.
- **O3** = the ratified `compare_solutions` record comparator (pair-identity bytes primary, full
  bytes tiebreak) — the CITABLE order (charter D2/H5). Ranking in O3 needs the Stage-G g-ladder +
  the **O3 ranker (TO-BUILD, freeze row C7/E3; already on the Fable worklist)**.
- **Walk-rank vs class-rank (design note for the O3-ranker builder, must be pinned before any
  citable rank ships):** records are orientation-masked classes (multiplicity m(k)); N counts
  walks. Freeze-row E3 defines rank(KW) as the superspace **walk** O3 rank; the class-rank (# of
  distinct records preceding KW's record) is a second quantity. TR-12 publishes the walk-rank as
  primary; class-rank only if the ranker's m(k)-collapsed mode lands. `repr(KW)=KW` is PROVEN.

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
-selftest` (Stage G engine, reviewed, run pending), `--f1c5-layer-sha` (decompressed-stream layer
shas), `sat.py` (CNF emit incl. C3 encoding, witnesses, DRAT), `verify.py`/`solve.py` constraint
predicates, `--null-historical`, the DFS walker (v4-canonical `b1464fa`). **Certificate hygiene:**
every published number carries: command line, build identity (git+source sha), layer-dir sha
registry, `#provenance` scope line, and the reader-side re-derivation (H6 form; "certificate, not
proof").

**Cost basis [all ESTIMATED unless marked].** Stage F ≈ $75–105 central (RUNNING, R-2); Stage G
+$60–110 (D3-authorized); Spot D8/D16/D32 ≈ $0.03–0.30/hr; a full-31 layered count-DP re-run
(no layer retention) ≈ $40–80; a full ladder streaming pass (scan class) ≈ $15–50; point queries
against mounted ladders ≈ $1–5. **No campaign-scale dollar anchor is quoted here.** The 560 T
campaign's realized total is not published: `documentation/CAMPAIGN_METHODOLOGY.md`
(§"Total realized cost", corrected and amended 2026-09-01) withdraws it as an estimation anchor
under that file's §7 rule 9, which sets the bar for restating one at an **itemized** ledger —
VM-hours by SKU, disk-months, closeout. Heavy ops on Spot workers, never the orchestrator.

---

## 1. The nine core queries (Q1–Q9)

### Q1. rank(KW) in the citable order + rank-neighbors — the H3b certificate
- **Definition.** rank_O3^SUPER(KW) = |{w ∈ SUPER : w <_O3 KW}| (walk-rank; exact integer
  ∈ [0, N)). Neighbors: unrank_O3(rank±1) — the walks immediately adjacent to KW in the citable
  order, reported in full with first-divergence positions. Scoped companion:
  rank_O3^C15(KW) = |{w ∈ C15 : w <_O3 KW}| — **estimate only** (see mechanism).
- **Mechanism.** O3 ranker (**TO-BUILD**, the CT1.5/CT3.6 item; g-weighted forward descent over
  the record order, consuming f·g per descent position; F1_CHECK f>0 on every g consumed per
  Stage-G review SG-1). C15 estimate: draw M exact-uniform ranks in [0, rank_O3^SUPER(KW)) via
  `--kc-sample`-style unranking, C3-test each (T=387), p̂ ⇒ rank^C15 ≈ p̂·rank^SUPER with binomial
  CI. H3b certificate = rank(unrank(r))=r + unrank(rank(KW)) byte-identical to KW + neighbor
  bracket + `#provenance`.
- **Stage:** needs Stage G + O3 ranker. **Cost:** queries ≈ $1–5; estimate leg (M=10⁴) ≈ $5–15.
- **Output:** `tr12/q1_rank_kw.txt` — exact decimal rank, the two neighbor walks + records, the
  C15 estimate ±CI, certificate block. Machine-checkable: re-run rank/unrank; big-int compare.
- **Cross-check:** DFS rank consistency at exhaustive n ≤ 13 (cross-engine byte-match precedent,
  n=9 landed); REL-order rank(KW) via existing `--kc-rank` as an independent second coordinate
  (different order — reported, labeled, never conflated).

### Q2. Solutions #0, #N−1, #⌊N/2⌋
- **Definition.** unrank_O3(0), unrank_O3(N−1), unrank_O3(⌊N/2⌋) in SUPER (exact). C15-scoped:
  FIRST^C15 = the O3-least C3-passing walk; LAST^C15 = O3-greatest. 🔴 **Two corrections, QSET-2
  finding 3, 2026-09-06.** (a) **What the battery actually commands is REL, not O3.** The inventory's
  Q2c/Q2d rows invoke `--kc-enum` / `--kc-enum-desc`, whose own golden provenance line reads
  `order=REL-DESCENDING(…;NOT-O3)` and whose CLI documentation states REL "is **not** O3". No
  filtered *O3* endpoint command exists in this tree, so the O3 definition above is not the quantity
  the battery delivers. (b) **The O3 form is already determined:** `rank_O3(KW) = 0` is forced by the
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
  walk is deep; abort-and-report protocol if > 10⁶ backtracks).
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
- **Output:** `tr12/q3_profile_kw.tsv` (31 rows: choice, #alternatives, g of each alternative,
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
  canonical, **~10.11%** over the 10.5 B-ordering 560 T canonical); and that the threshold is
  King Wen's own value, *"extracted from the sequence, not derived independently."* A private
  foothold (F-MC) holds a further sample-scoped AT-ceiling tie fraction — **that sample's number
  is not quoted here** and nothing above depends on it. The nearest quantity with a public
  reproduction command is `P(C3 ≤ 776) = 12.1288%` over the T5 mega-sample,
  `documentation/VERIFY.md` `verify.py --check-t5-c3`, a different estimand under its own scope
  label. Instrument: `--c3-min` (min over a `solutions.bin`). **[I1 correction, C3 adversarial review 2026-07-22
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
  because which one the report wants is a scope decision, not a typo. (b) C3-MIN: min{C3(w) : w ∈ SUPER} with argmin witness (note C3-min over SUPER =
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
and `drat-trim` are still absent, so the `PENDING:sat-c3min-driver` token below is accurate about the
*tooling* and was misleading about the *question*. Found 2026-09-05 by a Fable adjudication of the
QSET external review, which the external review itself missed; see
[`documentation/CORRECTIONS.md`](../documentation/CORRECTIONS.md).

  **Exact versions of (a)/(c) are not shipped** — no instrument in this program counts
  C3-conditioned (§0), and the run that would has been priced and declined on cost, not ruled
  out structurally (§9); published as estimates-with-CI.
- **Mechanism.** (a)/(c): exact-uniform `--kc-sample` (post-F; M = 10⁵–10⁶ walks; evaluate
  cd\* per walk; ⚠ **CI claim narrowed 2026-09-06, QSET-2 finding 5 — and this is residue of a
  correction applied only halfway on 2026-09-05.** That pass fixed the C15-vs-SUPER space label on
  this row and left this clause untouched. The battery emits **one Wilson interval on the acceptance
  mass** `P(cd ≤ T)`, not per-bin intervals: the histogram bins ship with counts and no CIs. Read
  "binomial/multinomial CIs" as the **intended** design and the single Wilson interval as what is
  delivered) — an estimator upgrade over this project's own prior C3
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
- **The bisection is pre-registered in public, and the instrument that would run it does not yet
  exist.** This is stated as a method commitment, not a result. Its three public anchors, all at
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
- **Stage:** (a)/(c) post-F; (b) NOW-able (SAT needs no compiler). **Cost:** (a)/(c) ≈ $5–20;
  (b) ≈ $5–50 on a Spot D16 depending on SAT behavior [wide-hedged].
- **Output/verification:** histogram TSV + CI table; DRAT certs re-checkable via drat-trim
  (rung 1); witnesses validated by `verify.py`-class checkers. TR-9's circularity note on C3's
  threshold is restated wherever the census is quoted (the ceiling is KW-defined).

### Q5. Functional extremals — what the DP can optimize
- **Decomposability verdict (from the suite audit; full table in §4-LS).** The compiled DP state
  is (canonical-mask, last, rid≤6048) per layer. DP-optimizable over SUPER, class (a) —
  pairwise/placement-local: wave/`--path` (C5-forced CONSTANT — nothing to optimize, say so),
  `--lines` per-line change counts, `--canons` half-statistics, `--graycode` tallies, positional
  pair-marginal matches, boundary KW-match counts, edit-distance-to-KW (§ but see caveat 3).
  Class (b) — small extra state: `--markov` (×5 last-distance), `--mutual-info`
  (bounded counters), `--yinyang` running-balance extrema, prefix level-cover masks. **NOT
  DP-optimizable (class c), honestly listed:** `--complements` (C3 itself — monotone in-path
  prune only), `--palindromes`, `--autocorrelation` (all lags), `--fft` magnitudes,
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
  are not G-invariant) — sizing unknown, flagged DEFERRED; the 560T sample minimum stands as the
  interim bound.
🔴 **TWO OF THE FUNCTIONALS THIS ROW WOULD SWEEP ARE ALREADY CLOSED — do not spend a sweep on them
  (QSET-2 finding 1, 2026-09-06).** `--kc-extremal`'s registry carries exactly two `invariant/VARIES`
  functionals, `yangcount` and `entryyang`, and both extrema of both are **90 and 96**, over SUPER
  *and* over C15. The bound is two lines: of 31 free pairs, the 28 reversal pairs contribute a fixed
  84 because popcount is reversal-invariant, and the three free self-complement pairs
  `(12,51) (18,45) (30,33)` contribute 2 or 4 each — so the range is `[90, 96]`. **Both endpoints are
  attained by orderings this project published on 2026-07-24**: lines 22 and 50 of
  `reports/certificates/c3_positional_witnesses.txt` give `yangcount=96 entryyang=90` and
  `yangcount=90 entryyang=96`, each `verdict SUPER: IN` and `C15: IN`. A `$40–80` sweep of either
  would rediscover a published number. *(This closes the two REGISTRY functionals, not §Q5's proposed
  shortlist — yinyang excursion, markov self-transition, `--lines` imbalance are untouched.)*

- **Mechanism:** **TO-BUILD** `--kc-extremal FUNC DIR` (per-functional min/max sweep + witness
  reconstruction; separate subcommand, sha-neutral). **Shortlist proposed** (operator picks):
  max/min `--yinyang` cumulative-balance excursion; max/min `--markov` self-transition count;
  ⚠ ~~max KW-boundary-match count~~ **STRUCK 2026-09-05 (QSET finding 3,
  a circularity catch): the maximum is 31 and King Wen is the witness, BY CONSTRUCTION** — King Wen
  is a member of SUPER, so "how close does any solution get to King Wen's transition skeleton" is
  maximised at King Wen itself. It measures the labelling, not the space. The non-trivial form is
  already listed in this section as the edit-distance-to-KW extremal (nearest SUPER *neighbour*),
  and is DEFERRED on sizing;
  min/max `--lines` imbalance. **Stage:** post-F (f layers suffice for forward sweeps).
  **Cost:** ≈ $40–80 per functional [ESTIMATED].
- **Output/verification:** extreme value + explicit witness walk + certificate; witness re-checked
  by evaluating the functional in `solve.py`/`roae.py` (two-language); DFS exhaustive extremal at
  n ≤ 13 as the small-scope gate before any full-31 sweep.

### Q6. Density extremes — crowded corridors, lonely starts
- **Definition (SUPER).** Per layer k and admissible transition class: the exact walk mass
  through each (state, choice) = f(s)·g(s∘c), G-expanded to raw pair identities (each canonical
  mask carries orbit(cm) raw masks; placed-pair identity maps through the orbit transversal).
  Report per layer: argmax/argmin-nonzero choices by mass; KW's own path percentile per layer.
- **Mechanism:** **TO-BUILD** `--kc-scan FDIR GDIR` — ONE streaming pass joining adjacent f- and
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
- **Stage:** post-F. **Cost:** ≈ $5–15. **Output:** `tr12/gallery/` + seed + chi² line.
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
| V1 | `viz_kc_field.md` — positional-marginal field | P(pair j placed at slot k) = Σ_transitions orbit·f·g·[σ(pair)=j] / N; 32×31 heat matrix; KW's placements overlaid as marks | `--kc-scan` table (ii) | F+G+scan | matplotlib imshow from TSV; KW overlay from kw walk |
| V2 | `viz_kc_river.md` — mass river | Layer-k mass split by top-level branch class (and by distance-class of the k-th transition): Sankey/stacked flow across k=1..31; KW's path drawn as a line | scan table (iii) | F+G+scan | stacked-area/Sankey from TSV |
| V3 | `viz_kc_spectrum.md` — rank spectrum | For ranks r on a systematic grid (r = i·⌊N/K⌋, K=10³–10⁴): walk-decomposable functional values of unrank(r) vs r — property drift across the index | `--kc-unrank` grid + solve.py evals | F (REL grid); G+O3 for the citable-order axis | shell loop + solve.py batch + scatter/line |
| V4 | `viz_kc_shells.md` — KW's neighborhood shells | g(KW-prefix_k) vs k, log-scale (completions remaining after each KW choice) = Q3's rarity profile as a figure; optional band: min/max g over alternatives per step | Q3 output | G | semilog line from q3 TSV |
| V5 | `viz_kc_grammar.md` — transition grammar | P(next-choice class \| layer k) exact (choice classes: distance class d∈{1,2,3,4,6} × new-pair category), heatmap over k; KW's actual choices marked | scan table (iv) | F+G+scan | heatmap from TSV |

Costs: data extraction rides §Q6's scan pass (V1/V2/V5) and Q3 (V4); V3's grid ≈ $5–20
(K unranks). Rendering ≈ $0 (local). Verification: every figure's TSV is committed as evidence;
row/column sums = N gates printed by the scan.

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
committed in the battery driver, `scripts/tr12_repro.sh:1401`, as the stated reason its `c_xa_cd`
row skips (`SKIP:needs-r1-throughput-anchors`); read them with
`git grep -n "needs-r1-throughput-anchors" main -- scripts/tr12_repro.sh`. What has **no** public
basis, and is therefore still not quoted, is the nodes/sec rate itself; (d) **verdict**: EXHAUSTIBLE (fits a stated $ ceiling) vs
INFEASIBLE with the exact shortfall factor.

**Deliverables.** (i) argmin branch + the exhaustibility call; if ANY branch is genuinely
exhaustible → spec the **provably-exhausted-region certificate**: DFS walks the branch to
completion; ASSERT walked-prefix-count == t-derived prefix count AND emitted records byte-match
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
**MANDATORY accounting-convention pin (runs FIRST, NOW-able):** "valid prefixes" (t-units) vs
`solve.c`'s `SOLVE_NODE_LIMIT` node-counter semantics — at n ≤ 13, exhaust with the DFS
(node counter on) AND compute t; assert the exact mapping (incl. orientation-explicitness, d3
cell-splitting, and C3-prune visit accounting); no atlas number ships before this certificate
(`tr12/xa_node_convention.txt`). Small Spot worker, ≈ $1.

**Stage:** convention pin NOW; (a) post-G; (b) post-t-ladder; (c)/(d) then. **Cost:** t-ladder
≈ $60–110 if standalone [ESTIMATED]; atlas assembly ≈ $5. **Verification:** t vs DFS at n ≤ 13
(the pin); Σ_b solutions(b) = N; Σ_b prefixes(b) + shared trunk = t(root).

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
  looking**: (i) surprise CONCENTRATION at specific steps marks where any undiscovered simple
  constraint must live (a rule that "explains" KW must absorb bits where KW spends them);
  (ii) near-uniform typicality (spectrum ≈ the entropy profile of a uniform random member —
  computed as the comparison band from Q8's gallery) is boundable evidence that NO
  further simple positional constraint exists. Both outcomes are findings.
  ⚠ **The contract is narrowed, 2026-09-05 (QSET finding 12).** As written, (ii) named no constraint
  CLASS and no statistical POWER, and the outcome vocabulary had no "the instrument could not
  decide" branch — so every result mapped to a finding and nothing could come out empty. That is
  unfalsifiable in the only way that matters. **Narrowed to:** the class is *simple positional
  constraints expressible as a per-step function of the prefix state*, and no claim is made about
  constraints outside it; the band is the Q8 gallery's 1st/99th percentiles on `top1_share`,
  two-sided, evaluated **once**; and the outcome vocabulary is **three**, not two —
  `localized-constraint-candidate`, `typicality-bound`, and `anti-concentration` — with a fourth,
  **`undecided`**, when KW falls inside the band but the band is too wide to exclude anything.
  A pre-registered instrument must be allowed to return nothing. Explicit connection
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
  (family size discounts every tail — a 10⁻⁴ tail in a 100-family screen is NOISE, said so);
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

## 6. Capabilities program appendix (CAP-1..8) — "per 1–8, plan to do them"

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

### R.0 — The catalog is THREE stages, f → g → t, and ALL are required (read this first)

**No TR-12 query, no Exhaustion-Atlas number, and no published count can be reproduced without
first building the three-tier compiled catalog. There is no shortcut and no partial path:** the
1.097×10³⁹ solution space is never materialized; every TR-12 result is a *query against this
catalog*, so the catalog IS the reproduction artifact. The three stages must be built **in
dependency order** — **CORRECTED 2026-08-13: this is a FAN, NOT A CHAIN.** `f -> {g, t}`: both `g` and `t`
read `f`, and **NEITHER `g` NOR `t` READS THE OTHER** (verified in code and from the recurrence
`t(s) = 1 + sum_c t(s.c)`, which needs to know WHICH CHILDREN ARE ADMISSIBLE — that is `f` — never HOW MANY
COMPLETIONS a state has, which is `g`). The "each consumes the previous" phrasing below, and any caption
saying **Stage T reads GDIR**, are WRONG and have misinformed reproducers. *(The wrong-caption
example in this sentence itself read "Stage G reads FDIR" until 2026-09-05 — which is the
**correct** dependency and so named the wrong error; corrected here.)* **Public anchors, no
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

   g reads f.  t reads f.  NEITHER reads the other.
   branch atlas (XA) needs all three: FDIR + GDIR + TDIR
```

- **f alone** answers membership / first-violation only (Wave 1 queries).
- **f + g** are needed for any exact count or ranking query (Q1–Q3, Q6; Wave 2).
- **f + g + t** are needed for the Exhaustion Atlas — the headline TR-12 section — and every
  per-branch exhaustion number (XA, EW-1, CAP-3/5/7).

**Build commands.** The pin `[REPRO-TAG]` is the tag minted at this report's publication and named
in §R Tier A step 1; resolve it with `git ls-remote --tags origin | grep tr12`. *(Corrected
2026-09-05: this line carried a truncated v4-compiler sha as the pin. That commit is a real Stage-T
build pin in the compiler lineage, but it is **not reachable from this repository's `main`** —
`documentation/HISTORY.md` records exactly that — so as a reproduction instruction in a published
report it resolved to nothing. A reproduction instruction pointing at
nothing is worse than one pointing at a tag the reader can list, so the placeholder is named as a
placeholder rather than dressed as a commit.)* Each command below is OOC, resumable and sha-gated.
Let `FDIR`/`GDIR`/`TDIR` be the three catalog directories. **They are not the same size, and
the difference is load-bearing for provisioning** — measured on the completed full-31 ladders with
`du -sb`:

| ladder | measured size | provision |
|---|---|---|
| **f** (`FDIR`) | **3.29 TB** (3,293,894,951,830 B) | a 4 TB volume holds it, with little headroom |
| **g** (`GDIR`) | **8.27 TB** (8,274,431,592,051 B over 32 layers) | ⚠ **≥ 10 TB.** A 4 TB volume does **not** hold it, and neither does an 8 TB volume shared with f |
| **t** (`TDIR`) | **~3.1 TB** *(projected from the completed build's layer table; re-measure with `du -sb TDIR`)* | a 4 TB volume |
| **total** | **~14.7 TB** | — |

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
   #   verify:  ./solve --f1c5-layer-sha FDIR   (32 shas == runs/20260906_kc_ladders_n31/STAGE_F_SHA256.txt)
   #   the run prints total == N and hard-aborts unless N ≡ 0 (mod 24)
   ```
2. **Stage G (g-ladder) — reads FDIR:**
   ```
   ./solve --kc-g-build GDIR --kc-g-ooc
   #   verify shas:  32 g-layer shas == runs/20260906_kc_ladders_n31/STAGE_G_SHA256.txt
   #   verify identity:  ./solve --kc-g-check FDIR GDIR   (f·g cut identity prints N at EVERY layer)
   ```
3. **Stage T (t-ladder) — reads FDIR:**
   ```
   ./solve --kc-t-build FDIR TDIR --kc-ooc --kc-cache-mb <MB>
   #   resume is AUTOMATIC (adopts an existing t_manifest.txt + t_build.ckpt)
   #   verify shas:  t-layer shas == runs/20260906_kc_ladders_n31/STAGE_T_SHA256.txt
   #   cross-check:  t vs DFS exhaustion cost at n ≤ 13 must agree exactly
   ```
4. **Assemble the Exhaustion Atlas (needs all three):**
   ```
   ./solve --kc-scan FDIR GDIR atlas.json --kc-tdir TDIR   # per-branch table; internal gate Σ_b solutions(b) == N
   ```

Cost/time per stage, hedged [ESTIMATED]: each of F/G/T ≈ 2–7 days cloud-Spot wall, ~$60–140;
atlas assembly ≈ $5. Commodity contract (TR-11 §7): ~64 GB RAM + ~4 TB disk — that disk figure is
TR-11's, and it is the **f**-ladder contract; **g needs ≥ 10 TB**, per the measured table above. Only
*after* F/G/T exist do the query steps below (Tier A step 6 onward) run — in minutes, near-$0.

**TIER A — full rebuild (gold standard; trusts only public source + own hardware).**
1. Clone the public repo at the pinned tag/commit **[REPRO-TAG]** (host-agnostic git — no
   GitHub-specific machinery; the tag is minted at TR-12 publication and named in the report).
2. Build `solve.c` with the **published** line — `documentation/VERIFY.md` Stage 0 of
   §"TR-12 query program":
   ```
   gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz
   ```
   `-lz` is required to link and `-o solve` is required because every later step invokes
   `./solve`. For a multi-day ladder rebuild the repository's other published recipe adds
   optimisation — `gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm -lz`
   (`../README.md` §"Check it yourself" — the repository-root README, not `reports/README.md`) — and by the next sentence the two are sha-equivalent.
   **Toolchain freedom is load-bearing and stated:** all registered layer shas are over
   the DECOMPRESSED stream (the CR-3b subcommand `--f1c5-layer-sha`), and recompress-invariance
   is PROVEN (CR-3b work, 2026-07-16) — compiler choice, zlib version, and gzip level CANNOT
   change any registered sha. `--selftest` anchor + `build.sha` hygiene apply as usual.
3. Rebuild the f-ladder from scratch: `--f1-exact-c1c2c4c5 --f1-out-of-core DIR` with
   `SOLVE_F1_KEEP_LAYERS=1` (the Stage-F form; `--resume-from-layers` after any interruption).
   The TR-11 §7 commodity contract governs: **~64 GB RAM + ~4 TB disk**. Expected cost/time,
   hedged: cloud Spot (64–128 cores) ≈ 2–7 days wall, ~$75–140 [ESTIMATED; the project's own
   runs are the anchor]; owned workstation (16–32 cores, 64 GB, 4 TB SSD) ≈ 1–4 weeks wall,
   ~$0 marginal [ESTIMATED, unmeasured — stated as a hedge, not a promise].
4. Verify all 32 f-layer decompressed-stream shas against the published registry
   `runs/20260906_kc_ladders_n31/STAGE_F_SHA256.txt` via `--f1c5-layer-sha`; the run itself must print total == N and
   hard-aborts unless N ≡ 0 (mod 24).
5. Stage G likewise: `--kc-g-build GDIR --kc-g-ooc` (+ a contract/cost of the same shape,
   ~$60–110 cloud); verify the 32 g-layer shas `runs/20260906_kc_ladders_n31/STAGE_G_SHA256.txt`; run
   `--kc-g-check FDIR GDIR` — the f·g cut identity must print N at EVERY layer.
5b. **Stage T likewise (REQUIRED for the Exhaustion Atlas and every per-branch number)** per
   R.0 step 3: `--kc-t-build FDIR TDIR --kc-ooc`; verify the t-layer shas
   `runs/20260906_kc_ladders_n31/STAGE_T_SHA256.txt` and the n ≤ 13 t-vs-DFS agreement; then assemble the atlas with
   `--kc-scan FDIR GDIR atlas.json --kc-tdir TDIR` (internal gate Σ_b solutions(b) == N).
6. Run each TR-12 query as ONE command and diff against the report's **expected-output block**
   ([EXPECTED-Q1]..[EXPECTED-Q9], [EXPECTED-XA], … — every published number appears in a
   verbatim, diff-able block). **The driver is public and built:** `scripts/tr12_repro.sh`
   (1,570 lines at public `main` `76e5d680`) runs the battery against named FDIR/GDIR, diffs each
   output against the committed expected blocks in `scripts/tr12_expected/n9/`, prints
   `TR12_REPRO=PASS|FAIL`, reports skips explicitly, and exits non-zero on any mismatch.
7. Re-derive the certificates: rank(unrank(r)) = r + the KW neighbor bracket (Q1);
   Π p_i = 1/N exactly (Q3); N mod 24 = 0; Σ_b solutions(b) = N (XA); the gallery chi² gate
   (Q8); the f·g identity (step 5). The ÷24 and product-of-conditionals checks are reader
   arithmetic — no project code needed.

**TIER B — check a ladder you already hold against the published registries (minutes, ~$0
compute).**

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
2. Verify all ~96 decompressed-stream shas (`--f1c5-layer-sha`, all three dirs f/g/t) against the
   published registries `runs/20260906_kc_ladders_n31/STAGE_F_SHA256.txt` /
   `runs/20260906_kc_ladders_n31/STAGE_G_SHA256.txt` /
   `runs/20260906_kc_ladders_n31/STAGE_T_SHA256.txt`. A mismatch at layer *k* localises the divergence to that layer.
3. Run the identical step-6 query battery + step-7 certificates (identical commands; the query
   layer is artifact-source-agnostic by construction).

**Independence-ladder labels (METHODS.md conventions; printed with each tier).**
- Tier A: rung 3 (instrument stack) for all compiler-derived numbers — but with NO trust in any
  project-distributed artifact (everything rebuilt from public source); the mod-24 and
  product-of-conditionals gates sit at rung 1 (reader arithmetic); membership/first-violation
  certs at rung 2. What Tier A does NOT establish: instrument-independence — it re-runs the
  SAME solve.c mathematics, so the TR-11 §10(vi) single-instrument caveat is INHERITED BY BOTH
  TIERS and stated in the section body, not the margins (an independent reimplementation from
  the published recurrences is the only true second instrument; the H8 two-language boundary
  applies).
- Tier B: the registry check adds no independence of its own and is not a substitute for Tier A.
  It attests byte-identity to the artifact this project ran, **as attested by registries this
  project published** — so a reader who did not build the ladder from published source is
  trusting the registry, and one who did has already earned Tier A's standing. Stated plainly in
  the report. *(Revised 2026-09-05 with the tier: the earlier wording priced the trust in
  "downloaded blobs", which presumed a distribution that does not exist.)*

**Stage/cost:** the RM section itself is documentation (wave 0, ~$0); `tr12_repro.sh` is a
small wave-2 TO-BUILD; the ladder-publication question is **RESOLVED (2026-09-05): SHA registries
are published, the ladder data is not distributed** — so it is no longer a gate on anything.
The registries land automatically with Stage F/G (R-2's 32 per-layer sha registration is
already a pass gate).

---

## 7. Dependency waves + cost

| Wave | Gate | Items | Incremental cost [ESTIMATED] |
|---|---|---|---|
| **0 — NOW** (no compiler artifacts needed) | none (small Spot workers only; TO-BUILD code operator-gated) | Q7 verdicts+certs; Q9; Q4(b) SAT C3-min; XA convention pin (n≤13); EW governance + pre-registration; LS TR-8 pair-null; CAP-2 wrapper; RM section text (the ladder-publication question is resolved — registries published, data not distributed — and gates nothing); small-n oracle/atlas prototypes (n≤13) | ~$10–60 |
| **1 — post-Stage-F** (f-ladder on disk; R-2 complete) | R-2 PASS (==N + layer shas) | Q8 gallery; Q4(a,c) sampled census; Q2 REL endpoints + FIRST^C15; REL rank(KW) coordinate; V3 (REL grid) | ~$30–80 |
| **2 — post-Stage-G + O3 ranker** | D3 Stage-G run + CT1.5/CT3.6 ranker gates | Q1 (H3b cert); Q2 O3 endpoints; Q3 profile; Q6 + `--kc-scan`; V1/V2/V4/V5; XA(a); EW-1; CAP-3 IDs; CAP-7 slices | Stage G $60–110 (authorized D3) + t-ladder $60–110 (if standalone; ~$0–30 if co-scheduled as a G channel) + scan $15–50 + queries $10–30 |
| **3 — elective, per-item operator-gated** | operator selection + cost-confirm each | Q5 extremal shortlist ($40–80 ea); LS exact-count shortlist ($250–800); CAP-5 grid ($360–720 for 9 pts); EW-2 screens ($40–105 ea); CAP-4/CAP-8 research | $700–2,400 depending on selection |

**Total line:** committed-path (waves 0–2, beyond the already-authorized Stage F/G):
**≈ $125–360 [ESTIMATED]**; with the elective wave 3 as scoped: **≈ $0.8–2.8K [ESTIMATED,
NOT AUTHORIZED — per-item cost gates]**. Per the charter, quote per-stage figures only.

---

## 8. Consolidated TO-BUILD worklist (feeds the O3-ranker + H-tier agents)

All C items = `solve.c` subcommands, argv-dispatched, sha-neutral, NEVER inside `--selftest`
(F-C-5); all under the H-code operator gate; every one ships with reduced-n brute-force gates
before full-31 use. Ordered by wave.

**Build status against public `main` HEAD `76e5d680`, re-verified 2026-09-05** by reading the
committed blob (`git show HEAD:solve.c`, `git show HEAD:sat.py`, `git ls-tree HEAD`), not a
working tree. **A surface's presence in the committed source is evidence that it exists; it is not
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
3. `--kc-scan FDIR GDIR OUT.json` — the f·g join pass emitting the four tables (Q6, V1, V2, V5) with
   G-expansion + the Σ orbit·f·g = N internal gate. Wave 2.
   **BUILT at HEAD:** `--kc-scan`, `--kc-scan-selftest`, `--kc-scan-merge`.
4. `--kc-t-build` (or a value-channel flag on `--kc-g-build`) — the tree-size ladder (XA);
   the per-branch table is then assembled by `--kc-scan FDIR GDIR OUT.json --kc-tdir TDIR` (XA is one
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
8. `--kc-oracle` property channels — extend the already-queued R-3.5 harness with the LS/EW
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
    any mismatch (shell only, no new .c/.py). Wave 2.
    **BUILT at HEAD:** `scripts/tr12_repro.sh`, 1,570 lines, with its committed expected blocks
    under `scripts/tr12_expected/n9/`.

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
  during the review. Under the alternative "distinct walk" reading the minimum is **0**
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


## Wave-status ruling (operator, 2026-07-17)
- **Waves 0–2: approved in principle** (~$125–360 total new compute beyond the authorized R-ladder), sequenced behind the campaign; wave 2's t-ladder doubles as the byte-level gate upgrade — until it runs, the promotion uses the pre-declared degraded-rank labeling.
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
The 2^5 intersection anatomy. Today the suite publishes exactly two cells (TR-11 exact
C1C2C4C5; TR-4 estimated C15). Plan: (1) SIZING PASS first — which non-C3 cells the TR-11
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
TR-11's absolute validation (ratio 0.999956 at 10^39) retroactively tightens every published
estimate. One table: each prior estimate, its method, the post-validation confidence statement.
**Cost:** $0 (writing + arithmetic). **Verification:** cites TR-11 §; no new computation.

---

## 11. Prior-art refresh addendum (2026-07-31) — queries the July prior-art sweep opens/refines

*Folded in 2026-07-31 after the July prior-art sweep + the #32 Lean
closeout. Assessment basis: the sharpest prior-art frameworks the sweep surfaced are **Ouyang
1990/1992** (the hexagram set as (ℤ/2)⁶ with explicit subgroups and cosets — the fullest algebraic
framing) and **Suenaga 2012** (the earliest to START the count, 1395 = [6,3]₂ Gaussian binomial);
plus the now-kernel-only DIV-24 theorems (`twenty_four_dvd_*`, #32) and the equivariance ceiling
(P ≤ 1/24). None of this opens a new heavy-compute program — the flagship queries (Q1–Q3, Q6, Q8)
and the exact/estimate boundary are UNCHANGED (the sweep did not make |C15| exact). It adds ONE new
query family and refines four existing items. All items below are labeled by space + method per §0.*

### Q10 (NEW). Orbit / (ℤ/2)⁶-coset census — the Ouyang-framing query
- **Definition (SUPER, exact part).** The record-level action is free with 24-element orbits
  (TR-5; `twenty_four_dvd_*` now **kernel-only**, #32), so |SUPER|/24 and every layer count /24 are
  exact integers. (a) **Orbit census:** per g-ladder layer, the exact number of distinct 24-orbits
  (= layer walk-mass / 24) and KW's orbit's rank among them; a global "24 ∣ count" self-check on
  every layer. (b) **Coset-structured census (the Ouyang lens):** classify solution mass by position
  in the (ℤ/2)⁶ subgroup/coset lattice that Ouyang 1992 uses for the hexagram algebra — i.e. tabulate
  how walk-mass distributes across the cosets of the relevant XOR-translation subgroups, and whether
  KW's coset is distinguished. **Honesty label:** (a) is EXACT and cheap; (b) is **EXPLORATORY
  (EW-class, FRONTIER discipline)** — it may reveal a real concentration or may be flat, and "flat"
  is a reportable negative (feeds Q9), NOT a failure. No structural claim is pre-committed.
- **Mechanism.** (a) rides the existing `--kc-g-check` mass identity (Σ orbit·f·g = N already computed
  in the scan pass) — the /24 orbit counts are a projection of numbers the ladder already produces; no
  new subcommand strictly needed (a thin `--kc-orbit-census` wrapper at most). (b) **TO-BUILD** light:
  a coset-labeling of the transversal (map each canonical mask to its (ℤ/2)⁶ coset id via the XOR
  structure already in `applyPerm`/`pairKey`), then aggregate the scan-pass mass table by coset id.
- **Stage:** post-G (needs the g-ladder). **Cost:** (a) ≈ $1–5 (projection of existing tables);
  (b) ≈ $5–15 (one extra aggregation over the scan pass). Rides Q6's `--kc-scan`; no new heavy pass.
- **Output/verification:** `tr12/q10_orbit_census.tsv` (per-layer orbit counts + the /24 integrality
  gate — now Lean-kernel-backed) + `tr12/q10_coset_census.tsv` (mass by coset id + KW's coset). Gate:
  every layer count ≡ 0 (mod 24) EXACTLY (dispositive; ties to `twenty_four_dvd_*`); Σ over cosets =
  layer mass. Cross-check: n ≤ 13 exhaustive orbit counts. **Cite Ouyang 1990/1992 (framework) +
  Suenaga 2012 (counting start) at the query site** — this is the query that visibly extends their lineage.

### Refinements to existing queries (no new compute)
| Query | Refinement (source) | Action |
|---|---|---|
| **Q4** (C3 census) | C3 = 16 + 8·G identity CLOSED (kernel, `C3Decomposition.lean`). Beyond the already-adopted "bisect on integer G / bracket [12,47] / mod-8 lattice" correction, publish an **EXACT** G-channel companion to the (estimated) C15 histogram: the C1∩C4 null law of G — support **[12, 228]**, **E[G] = 128** (⇒ E[C3] = 1040), **P(G ≤ 95) = 641983711307479/7919632354008375 ≈ 8.106%** — exact via the G-channel DP. One column moves estimate→exact; the C15-conditioned histogram stays labeled ESTIMATE. | Add exact-G companion table + the ceiling-is-KW-defined circularity note (already in Q4). |
| **Q9** (reportable negatives) | (i) Add the **equivariance ceiling** (P(KW-record) ≤ 1/24 for ANY G-invariant generator; `KingWen.lean`, kernel-only) as a strong new negative — no G-invariant scoring can concentrate on KW beyond 1/24. (ii) The **8 forced literature rules** (Find 1 → `C1RuleConstants.lean`) are now PROVEN constants of the entire C1 space, so they move from Q9's "candidates for proof upgrade (LS-1)" into the theorem class. | Promote the 8 rules; add the ceiling negative with its hypothesis-class scope stated. |
| **XA** (Exhaustion Atlas) | Add an explicit **24-divisibility integrity self-check** on every headline count — now **Lean-kernel-backed** (`twenty_four_dvd_*`, no longer native_decide, #32). Cheap, dispositive, and it hardens the whole count cascade. | Add the mod-24 gate row to XA's integrity block; cite the kernel theorem. |
| **LS / XA framing** | Express the counting cascade in the **Gaussian-binomial / [6,3]₂ lineage** where Suenaga 2012 began it (1395 = [6,3]₂), so the Atlas visibly EXTENDS a known partial count rather than presenting a bare number. | Add the q-binomial framing note + Ouyang 1992 / Suenaga 2012 citations to LS and XA provenance. |

### Not changed (stated for the record)
The exact/estimate boundary is UNCHANGED: |C1–C5| and |C1–C7| remain **estimates** (compute-bound;
Lean/SAT prove properties, not counts). Q1–Q3, Q6, Q8 are untouched. This addendum is additive polish
plus Q10 — not a re-scoping. **Citations to add project-wide where a symmetry/counting claim is made:**
Ouyang 1990/1992, Zhang 1994/1998/2000, Suenaga 2012, Luo 2015 (already in CITATIONS.md post-sweep).

---

> **⚠ Wall-time caveat.** The cost bands in §0 and per-query above are the 2026-07-17 estimates,
> made before Stage G existed and before any query was executed. They are stated as *dollar* bands;
> **their implied wall times are not current.** The measured hardware and rate table in public
> `documentation/VERIFY.md` §"TR-12 query program" is the figure of record for timing and sizing.


---

## Revision history

| version | date | change |
|---|---|---|
| v1.0 | 2026-09-05 | **First public release.** The specification body is the 2026-07-17 text by Claude (Fable 5) and is unchanged in substance. Three publication passes ran before release and are recorded here because each changed what a reader is looking at. (1) A **figure → reproduction-command audit**: every asserted figure was classified, and those with neither a public citation nor a public reproduction command were **struck rather than shipped**, each strike saying in place what was removed and why. (2) A **public-anchor pass**: citations to internal working notes were replaced by a published document, a runnable command or a code site; the one citation for which no public anchor exists is recorded as exactly that; the ladder-publication question was resolved as **per-layer SHA registries are published, the ladder data is not distributed by this project**; and the H3b specification amendment is recorded in §0. (3) A **novelty scrub under the publication freeze**, temporarily removing priority assertions; the removals are registered verbatim so the scrub is a loan, not a deletion, and their restoration is separately gated. **Cost figures:** the earlier revision of §9 quoted a dollar band and an operator price quote for the declined exact-C3 run; both are withdrawn, and the **dollar figures are redacted rather than restated**, following `TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md` v1.10 — a withdrawal that requotes a number publishes it. **Withheld:** the standing single-branch-exhaustion shortfall factor is not quoted; it has no public reproduction command, and its public anchor is a run (`documentation/HISTORY.md` §"April 22, 2026 — Campaign A Pass 1"; `runs/20260422_passA_10T_d64_laggard/`), not a figure. **Corrected at release:** four sites reused framings this document retracts elsewhere in its own text — the exact C15 count described as an "obstruction" or "not computable" when §9 records it as **priced and permanently declined on cost** (TR-11 §10(ii) v1.5 having withdrawn the structural claim), and §R.0's ladder diagram carrying both the retracted chain arrows and the corrected fan annotations under one label. No count, definition, verdict or query specification changed in any pass |
| v1.1 *(current)* | 2026-09-05 | **Ladder provisioning corrected — g is 8.27 TB, not "~4 TB like the others" (found by a reader's challenge, hours after v1.0 shipped).** §R.0's build section said "three catalog directories on ~4 TB disk each" and now carries the measured per-ladder table: f **3.29 TB**, g **8.27 TB** (2.5× f), t ~3.1 TB projected, **~14.7 TB total**. The same stale hedge — "~2.5-2.7 TB … the same size class as f" — was live in four `solve.c` sites including the `--kc-g-build` **runtime usage string**, which told a reproducer that "a second 4 TB disk or a shared 8 TB with the f ladder both work"; g alone exceeds 8 TB, so provisioning from that line ran out of disk partway through a multi-day build. All corrected, with `du -sb` as the reproduction command; `documentation/CAMPAIGN_METHODOLOGY.md`-style commodity contract wording clarified — TR-11 §7's "~64 GB RAM + ~4 TB disk" is the **f** contract, not per-ladder. The g comment had said "hedged, **unmeasured until the run**"; the run happened and nothing propagated the measurement back. See [CORRECTIONS.md](../documentation/CORRECTIONS.md). **Sha-neutral** (`403f7202…` measured before and after). No count, definition, verdict or query specification changed |
