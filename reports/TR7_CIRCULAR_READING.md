# TR-7 — The Circular Reading
*Technical report — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. One caveat is structural, and it frames all the rest: the same
author wrote the claims, the software that checks them, and this report that grades the check.
Verification here is independent in mechanism, never in authorship; no independent party has yet
audited or reproduced any of it (METHODS.md §"Authorship independence").*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

What if the sequence is a circle — the last hexagram wrapping around to the first? Several scholars,
notably [Terence McKenna](../documentation/CITATIONS.md#mckenna-mckenna1975), read it that way. This report re-derives the mathematics under the circular
reading. Two results stand out. First, the wrap-around step is **forced to be odd** (proved formally),
which makes McKenna's observed 3-to-1 ratio of even-to-odd transitions a necessity, not a choice.
Second, a surprise: the sequence's missing distance-5 transition is a **genuine extra rule** in the
circular reading — orderings that wrap at distance 5 make up 17.4% of the valid space, yet **not one**
appears among 10.5 billion enumerated records. That gap between the full space and the enumerated
slice is a stark demonstration of why bounded search results need independent
measurement — and why we decided this rule, though real, stays documented rather than adopted.

## Abstract
McKenna & McKenna (1975) read the King Wen sequence as a *cycle* — position 64 wrapping to position 1 —
and their published counts (64 transitions, "three even integers to each odd integer") depend on that
closure. We work out exactly what the ROAE constraint system says under the circular reading. Three
theorems and one SAT decision result: (i) the wrap-around Hamming distance d(s₆₃, s₀) is odd for *every*
C4+C5-valid ordering — now machine-checked in Lean 4 at full generality (`wrap_parity_general`, structural
induction, not finite enumeration); (ii) McKenna's exact 3:1 even:odd transition ratio is a *forced
consequence* of C4 + C5 plus the XOR parity identity — a regularity he read as a design feature that turns
out to be a theorem, not a choice; (iii) every valid circular reading has exactly 16 parity-class
alternations, and the first and last hexagrams of any valid linear ordering lie in opposite
popcount-parity classes. Finally, the circular form of C2 ("no 5-line transition anywhere on the cycle")
is a *genuine* extra constraint: valid linear orderings with a 5-line wrap exist (SAT-decided, explicit
witness) even though exactly zero appear among the 10,525,271,997 records of the deepest canonical slice;
the full-space wrap-distance masses are measured at d=1: **17.4647 ± 0.0077**, d=3: **65.1504 ± 0.0096**, d=5: **17.3849 ± 0.0077** pp (2×10¹⁰
weighted-Knuth probes.

⚠ **[REPRODUCTION COMMAND ADDED 2026-09-03 — these masses were MEASURED and no runnable command
resolved within their window, only a pointer to an archived artifact. The artifact records its own
parameters, so the invocation is recoverable rather than guessed:**
```
SOLVE_KNUTH_SCORE=1 SOLVE_THREADS=64 ./solve --estimate-knuth 20000000000
```
**read off `evidence/r6/rc1c_primary.out`'s own header — `[knuth] 20000000000 probes, 64 threads` and
`KNUTH-ESTIMATE probes=20000000000 threads=64 start_step=1 prefix_levels=0` — with
`SOLVE_KNUTH_SCORE=1` being the flag that emits the `[score] R-C1c` line at all (`SOLVE_C_CLI.md`
§`SOLVE_KNUTH_SCORE`). 🔴 The `SOLVE_THREADS=64` pin is load-bearing, not decoration: the estimator's
seeds are fixed constants and **the thread count selects the sample** (METHODS §"Reproducibility rule
for estimator output"), so a re-run at a different thread count is a different draw, not this one.]**

The archived v2.0 r6 run —
[`evidence/r6/rc1c_primary.out`](evidence/r6/rc1c_primary.out): 17.45 / 65.18 / 17.37% — agrees
within 0.05 percentage points per class, but it is a **partially overlapping replicate, not an
independent draw**: it shares half its probes with the primary run (§5). The instrument has printed
per-class SEs since 2026-08-28 and the archived artifacts predate that field, so **no ± figure is
published for these masses**). The operator's
documented decision: circular C2 is *not* promoted into the constraint system — the circular reading is
McKenna's interpretive frame, not an attested property of the received artifact.

## Sections
1. **The circular frame and its provenance.** McKenna & McKenna (1975, *The Invisible Landscape*, Part
   Two, Ch. 9) constructed their difference wave over 64 transitions *including* the wrap s₆₃ → s₀ (KW's
   wrap has Hamming distance 3) — the circular reading is theirs, with full attribution (CITATIONS.md,
   [MCKENNA.md](../documentation/MCKENNA.md)). What closure does *not* touch: C1, C3, C4 are position/pair properties, unaffected *by closure* —
   note that C3 is an **absolute-position** functional, so "unaffected by closure" does not make it
   rotation-invariant (§6). What
   it touches: the transition multiset (C5) gains a 64th member, and C2 acquires a 64th application — the
   wrap itself.
2. **The wrap-parity theorem, three ways.** For any sequence satisfying C4 and C5, the wrap distance
   d(s₆₃, s₀) is odd — proven via the XOR parity identity (popcount(a⊕b) ≡ popcount(a)+popcount(b) mod 2).
   KW's wrap is d = 3. Verification stack: (a) the prose proof ([SPECIFICATION.md](../documentation/SPECIFICATION.md)); (b) the Lean 4
   kernel-checked general form `wrap_parity_general` — verified for EVERY C4+C5 sequence of 6-bit values by
   structural induction (telescoping transition-parity lemma + sum-parity/odd-count machinery), upgrading
   the formal core from "finite facts checked" to "sequence-level theorem proven"; (c) empirical
   corroboration at the d3 560T canonical (10,525,271,997 records, sha 9a968fa2…): 100.000000% odd wrap —
   necessarily, since [`solve --verify`](../documentation/SOLVE_C_CLI.md#--verify) enforces the C4+C5 hypotheses; the theorem holds deductively, the
   enumeration validates the implementation.
3. **McKenna's 3:1 is forced, not designed.** His "perfect ratio of three to one" (16 odd of 64 circular
   transitions, 25.00% exact) is the circular reading of the wrap-parity theorem plus C5's 16-odd-of-64
   count. Every C4+C5-valid ordering has it. McKenna discovered the ratio empirically before its proof was
   articulated here — one of his most accurate quantitative claims, and stronger than he may have realized:
   **forced given C4 + C5**, and hence not an independent design choice *within* that constraint system — though C5 is itself a regularity read off King Wen, so "forced" here is relative to KW-derived constraints, not to an unconstrained arranger.
4. **What closure changes: circular C5 and the 16-alternation corollary.** Under closure KW's transition
   multiset becomes {1:2, 2:20, **3:14**, 4:19, 6:9} (the d=3 count rises 13→14); orderings with d=1 wraps
   read {1:3, …, 3:13, …} instead. The parity-alternation theorem ([PARITY_ALTERNATION.md](../documentation/PARITY_ALTERNATION.md); Lean
   `alternations_15_general`) forces exactly 15 alternations linearly; on the cycle the count must be even
   and the wrap boundary is forced to alternate (equivalent to wrap parity — two routes to one fact).
   **Corollary: every valid circular reading has exactly 16 alternations**, and the first and last
   hexagrams of any valid linear ordering lie in opposite popcount-parity classes (KW: 63 even → 42 odd ✓).
5. **Circular C2 is a genuine extra constraint — the SAT decision.** The wrap-parity theorem restricts the
   wrap to d ∈ {1, 3, 5}. At the 560T canonical the wrap is d=3 in 91.83% of records, d=1 in 8.17%, and
   d=5 in **exactly zero of 10,525,271,997**. Nevertheless, valid linear orderings with a 5-line wrap
   EXIST — SAT-decided (2026-07-03) with an explicit C1–C5-valid witness (final pair (32, 1); wrap
   d(1, 63) = 5; complement-distance sum 752). So the circular reading is *not* free: it excludes real
   members of the linear solution set. Per the twins lesson ([SYMMETRY_SEARCH.md](../documentation/SYMMETRY_SEARCH.md)), budgeted-slice absence
   does not measure full-space rarity — and the full-space wrap-distance masses are now MEASURED (2×10¹⁰
   weighted-Knuth probes, 2026-07-03; estimator per METHODS.md; mass ratios are
   heavy-tail dominated — small probe budgets will not resolve them):
   **d=1: 17.5%, d=3: 65.2%, d=5: 17.4%**.

   ✅ **UNCERTAINTY NOW PUBLISHED, 2026-09-04 — d=1 `17.4647 ± 0.0077`, d=3 `65.1504 ± 0.0096`,
   d=5 `17.3849 ± 0.0077` percentage points**, pooled over **two replicates that differ only in
   `SOLVE_KNUTH_SEED`** (`20260904` → base `0x…2828`, `20260905` → base `0x…2829`; same binary, same
   2×10¹⁰ probes, same 128 threads). Every worker seed differs, so these are genuine independent
   draws and the between-replicate gaps — **1.48σ / 0.02σ / 1.51σ** — are a real run-to-run scatter
   rather than an arithmetic identity. Artifacts and the exact reproduction command:
   [`evidence/wrap_mass_reseed/`](evidence/wrap_mass_reseed/). The point masses are unchanged to the
   precision published above; what was missing was the ±, and it is no longer missing.
   **The paragraph below records why the earlier pair could not supply it, and is kept in full:** it
   is the reasoning that made this measurement necessary, and the defect it describes is a live
   hazard for any future replicate that forgets to set a seed. The
   archived artifacts (2026-07) predate the estimator's per-class `se=` field, which landed 2026-08-28
   ([METHODS.md](METHODS.md) §"Statistics conventions"), so they carry point masses only. And the
   2×10¹⁰-probe v2.0 r6 run ([`evidence/r6/rc1c_primary.out`](evidence/r6/rc1c_primary.out),
   2026-07-10), which re-measured the same three masses at **17.45 / 65.18 / 17.37%**, is a
   **partially overlapping replicate, not a second draw**: neither artifact carries a `SEED OVERRIDE`
   line, so both ran on the fixed base seed, and the estimator seeds worker *i* as
   `base ^ ((i+1)·0x9E3779B97F4A7C15)` — by thread index alone. The 32-thread primary and the 64-thread
   rerun therefore replay the same first 312.5×10⁶ draws on each of threads 0–31, so **10×10⁹ of each
   run's 20×10⁹ probes are literally the same probes**. The 0.05-percentage-point agreement is
   arithmetic, not evidence; it bounds nothing. A genuine run-to-run scatter requires reruns under
   distinct `SOLVE_KNUTH_SEED` values, quoting the emitted `se=` values; that is open. The 5-wrap orderings that
   no budgeted slice has ever contained are between a fifth and a sixth of the full space; circular C2
   would cut the space by ×1.21.
6. **The non-promotion decision, on the record.** Operator decision 2026-07-03: circular C2 is documented,
   NOT promoted, and not implemented in solve.c in any form. Rationale (consistent with the R-series
   non-promotion discipline): the circular reading is McKenna's interpretive frame, not an attested
   property of the received artifact; enforcing it would add a reverse-engineered constraint. The
   implementation analysis, for the record: as a pure leaf-emission filter it would be byte-identical to
   the current lineage at every published canonical scale (zero 5-wrap records exist in any slice —
   divergence begins only in territory no budget has reached, as the SAT witness proves); as a prune it
   would change node consumption and open a new sha lineage. Neither is warranted. Closure also invites a
   larger symmetry question — without C4 **and with a circularized C3** (minimum circular displacement),
   the 32 pair-slot rotations would be symmetries of a circular system, alongside the B₃ relabelings.
   Under the C3 this report actually uses, which is absolute-position and is *not* redefined by closure
   (§1), it is not: **21 of the 31 non-identity pair-slot rotations of KW exceed the 776 ceiling** —
   rotate-4 gives 888, rotate-16 gives 1240, the maximum is 1320 and only 10 rotations survive. The
   circular transition multiset is preserved exactly under rotation, so C1, circular C2 and C5 survive
   it and **C3 alone breaks it**; dropping C4 therefore yields no C₃₂ action on the C1–C5 space at all.
   Under the actual system (C4 kept) the circular reading changes nothing about the symmetry group.

⚠ **Every `--estimate-knuth` command in this document requires a stack limit of at least 16 MB** — `ulimit -s 16384` suffices, and `ulimit -s unlimited` is one way to satisfy it, not the requirement itself. Under the default 8 MB stack the estimator does not start: `main` allocates a ~7.23 MB frame and `estimate_tree_knuth` a further ~1.02 MB (since 2026-08-21 the binary refuses with an actionable message; previously a bare SIGSEGV). *(Added 2026-08-21, an execution-lane finding — `scripts/exec_lane.sh` executes every documented command on a default environment; the same-day warning propagation (`1e4bd04a`) covered the four estimator guides but missed this file.)* *(Narrowed 2026-09-02, Codex V2-F08 #4, prose batch P37: `ulimit -s unlimited` is a **sufficient** setting that had been published as a **necessary** one — and one that a host or container with a hard stack cap cannot even apply, so the published requirement was a false blocker there. `solve.c`'s `--estimate-knuth` preflight tests `rlim_cur != RLIM_INFINITY && rlim_cur < 16UL*1024*1024` and its message names ">= 16 MB". EXECUTED under TR-9 v1.24 on a locally built binary: `ulimit -s 8192` refuses and exits 1, `ulimit -s 16384` runs the estimator to completion. `solve.c`'s own remedy line still prescribes only `unlimited` and is queued to offer both. This is the sibling propagation of the narrowing TR-9 made on 2026-09-02 and reported but did not sweep.)*

## Verification Guide
- Wrap-parity theorem, statement + proof: documentation/SPECIFICATION.md §Theorem (Wrap-around parity is
  odd)
- Lean general form: `cd lean && lean KingWen.lean` (Lean 4, tested 4.31.0 — run from inside `lean/` so elan honours `lean/lean-toolchain`; from the repo root it uses its default toolchain instead, measured 2026-09-03; silence = all theorems check) —
  `wrap_parity_general`, supporting lemmas `transitions_sum_parity`, `sum_parity_odd_count`,
  `odd_count_partition`; see lean/README.md §Tier 2
- 560T wrap measurement (91.83% d3 / 8.17% d1 / zero d5): `./solve --verify-wrap-parity` against the d3
  560T canonical (sha registry: [documentation/CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md)). Note: this mode's printed theorem
  line formerly claimed "C2 forbids 5 → d ∈ {1,3}", contradicting §5's SAT result; corrected in public
  commit `0c24637` (2026-07-03) to state d ∈ {1,3,5} with d=5 not excluded by linear C2 (tabulator was
  always correct; stdout/comment only, selftest sha unchanged)
- Wrap-d5 witness: `python3 sat.py --witness wrap-d5` → the explicit 64-hexagram sequence in
  [documentation/CIRCULAR_KING_WEN.md](../documentation/CIRCULAR_KING_WEN.md), C1–C5-valid, wrap d = 5
- Full-space wrap masses: `SOLVE_KNUTH_SCORE=1 ./solve --estimate-knuth 20000000000` (2×10¹⁰ probes,
  the budget behind the published 17.5/65.2/17.4% figures; the scorer has printed per-class `se=`
  since 2026-08-28; the archived artifacts predate the field, so the ± comes instead from
  **two fresh seed-distinct replicates** — `SOLVE_KNUTH_SEED=20260904` and `=20260905`,
  [`evidence/wrap_mass_reseed/`](evidence/wrap_mass_reseed/) — giving
  **17.4647 ± 0.0077 / 65.1504 ± 0.0096 / 17.3849 ± 0.0077** pp. The r6 rerun remains a partially
  overlapping replicate and is NOT an independence check (§5), which is exactly why it could not
  supply this
  — and mass *ratios* are heavy-tail dominated, so small budgets (~10⁵ probes) will NOT
  reproduce them; this is an hours-scale run on many-core hardware. Method self-validation in
  [documentation/SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md))
- Rotations break C3 (§6: 21 of 31, rotate-4 = 888, rotate-16 = 1240) — reproduce in seconds from this
  repository's own clean-room C3, no build required:
  `python3 -c "import verify as v; c=v.c3_of_ordering; r=lambda k:[(s+k)%32 for s in range(32)]; print(c(r(0)), c(r(4)), c(r(16)), sum(c(r(k))>776 for k in range(1,32)))"`
  → `776 888 1240 21`. (`c3_of_ordering` reads the pair-slot map; cross-checked against
  `verify.compute_comp_dist` on the reconstituted 64-hexagram sequence, which returns the same values.)
- 16-alternation corollary ingredients: documentation/PARITY_ALTERNATION.md + Lean
  `alternations_15_general`
- Non-promotion decision + rationale: documentation/CIRCULAR_KING_WEN.md §Status decision (operator,
  2026-07-03)
- Attribution: the circular reading is McKenna & McKenna (1975); the wrap-parity theorem, its 560T
  measurement, the alternation corollary, and the wrap-d5 SAT decision are ROAE (to our knowledge —
  corrections welcome via documentation/CITATIONS.md)

## Figure: the cycle

![The King Wen cycle with the wrap edge](figures/fig_tr7_circular_cycle.png)

*The 64 hexagrams as a cycle in King Wen order (computed from the sequence itself). Red edges are odd
transitions; the highlighted wrap edge 64→1 jumps d = 3 — odd, as the wrap-parity theorem forces. The
circular reading has 16 odd transitions where the linear reading has 15: the wrap adds exactly one,
always.*

## Prior work note (v1.7)

[Peter Meyer](../documentation/CITATIONS.md#meyer1998) (1998, web) published the complete cyclic line-change sequence of the King Wen order —
the 64 Hamming distances including the wraparound term — with an explicit XOR-and-popcount
formalization. ⚠ **This attribution rests on an unrepeatable read.** The page was read first-hand on
2026-07-04 and has since gone: `serendipity.li/dna/kws.html` returned 404 when re-checked 2026-08-01
and the Internet Archive holds **zero captures of it**, so no reader can retrieve it and this project
cannot **re**-verify its content. See the [Meyer 1998](../documentation/CITATIONS.md#meyer1998) entry,
which also records that an earlier attempt to source Meyer's priority quoted a *McKenna*-authored page
and was withdrawn as circular. What is credited to Meyer here is therefore reported, not verifiable:
the wrap value d = 3 and the absence of distance-5 **as stated claims** belong to **McKenna & McKenna
(1975)**, which is in print and citable, and no ROAE novelty claim rests on the Meyer entry. The
wrap-parity theorem, the d ∈ {1,3,5} space analysis, and the 17.4%-vs-absent measurement remain, to
our knowledge, first stated here. Found during a bibliography review 2026-07-04; corrections welcome.

## Corollary (added v1.8): exactly 32 parity switches in every circular reading

The circular transition-parity string (64 values: transition i is "odd" iff an odd number of lines
change, the wrap included) switches value exactly **32 times** in every C1+C4+C5-valid ordering.
Proof: index the 64 cyclic transitions 0..63, transition i connecting positions i and i+1 (mod 64,
0-indexed); pair p occupies positions 2p and 2p+1, so within-pair transitions sit at the 32 even
indices and are all even (C1: reversal preserves line-count parity; the four self-reverse pairs are
complement pairs, d = 6), while between-pair transitions sit at odd indices 1..61 and the wrap at
index 63 — also odd. The parity-alternation theorem ([TR-6](TR6_PARITY_SKELETON.md)) gives exactly 15 odd between-pair
transitions, and the wrap-parity theorem (§2) makes the wrap odd, so there are exactly 16 odd
transitions (McKenna's 16-of-64, §3), all confined to odd cyclic indices. Adjacent indices on a
64-cycle have opposite index parity (including the 63/0 seam), so the 16 odd transitions are pairwise
non-adjacent — 16 isolated values, each contributing exactly two switches: 32. The result is invariant
across the wrap's distance class (d ∈ {1, 3, 5} are all odd). This fills the one remaining cell in the
TR-6/TR-7 linear→circular lattice: alternations 15 → 16 (§4), switches 30 (TR-6 corollary) → **32**.
Verified on King Wen: cyclic odd transitions = 16, all at odd indices; linear switches = 30; cyclic
switches = 32. Derived in cross-report synthesis 2026-07-04 (composition of TR-6's 30-switches
corollary with this report's wrap-parity theorem), independently re-derived and re-verified before
folding in.

*Verification:* both ingredient theorems are kernel-checked (`switches_30_general`,
`wrap_parity_general` in lean/KingWen.lean); the KW instance is a three-line check from solve.py's
`binary_hexagrams` (count sign changes of the cyclic Hamming-distance parity string).

## The anchors on the circle (added v1.9)

The sequence's two endpoint pairs are individually distinguished: the pure pair {Qian, Kun} that opens
it (C4) and the alternating pair {Jiji, Weiji} that closes it — [Cook 2006](../documentation/CITATIONS.md#cook2006)'s
"pure opens, mixed closes," measured linearly as the final-pair anchor (7.84% of C1–C5 mass,
[LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md)). They are
also the only *intrinsically* extremal pairs: the unique pair of run-length-6 (constant) hexagrams and
the unique pair of run-length-1 (strictly alternating) hexagrams. Under McKenna's circular reading the
two observations become one: **the two anchor pairs are neighbors on the circle** — KW places the
alternating pair in the last slot, adjacent to the pure pair across the wrap.

How much of that is forced? Three theorems (elementary; each exhaustively verified by finite computation
over the 64 hexagrams / 32 pairs — a Lean formalization is planned, see the Verification Guide):

(i) *Transition rigidity (T1):* every hexagram of the pure pair is at Hamming distance exactly 3 from
every hexagram of the alternating pair (an alternating 6-bit string has exactly three 1s, so it differs
from 111111 and from 000000 in three positions each) — so an anchor adjacency, wherever it occurs and
however oriented, is a d = 3 transition: C2-legal, odd, one unit of the largest odd budget class. In
particular KW's wrap distance 3 (§2) is forced by *which pair closes*, not by any orientation choice.

(ii) *Seam eligibility (T2i):* pairs are parity-homogeneous (16 even / 16 odd — [TR-6](TR6_PARITY_SKELETON.md)
ingredients), and the wrap-parity theorem (§2) then forbids all 16 even pairs — including all four
self-reverse pairs and the pure pair itself — from ever occupying the final slot.

(iii) *Pair-determined wrap (T2ii):* for each of the 16 eligible (odd) pairs the wrap distance is a
function of the pair alone (orientation-free), classifying them **10 : 3 : 3** into d = 3, 1, 5 closers
(the 4 antipalindromic pairs — A₂ among them — plus the 6 popcount-3 reverse-pairs at d = 3; the 3
popcount-5 reverse-pairs at d = 1; the 3 popcount-1 reverse-pairs at d = 5; the wrap-d5 SAT witness of
§5, which closes on (32, 1), is one of the latter — consistent). Eligibility is a *necessary* condition:
that all 16 eligible pairs are actually realized as closers is not proven here (the measured wrap masses
show every class is realized, and explicit witnesses realize A₂ and (32, 1)).

The measured full-space wrap masses (§5: 65.2 / 17.5 / 17.4% for d = 3 / 1 / 5) sit remarkably close to
the bare eligible-pair-counting baseline (62.5 / 18.75 / 18.75%) — the wrap-distance profile is, to first
order, pair-counting, with only a mild residual tilt toward d = 3. (Hedge: the baseline is a heuristic
reference, not a null; per-class CIs are heavy-tail dominated per §5; the per-pair spread within classes
is unknown except for A₂.)

**This re-prices Cook's anchor.** Against the naive 1/31 ≈ 3.2258% the measured 7.84% looks like a ×2.4
enrichment. Splitting that requires a baseline, and the defensible baseline is the **measured** one, not
a counted one: within its own d = 3 class A₂ carries 7.84% against a **6.52% class average** (the other
nine d = 3 closers average 6.37%) — mildly, not dramatically, over-represented. Against that measured
class mass, **×2.02 of the apparent enrichment tracks class structure** (6.52 / 3.2258) and **×1.20 is
the A₂-specific residual** (7.84 / 6.52); the two compose to the ×2.4 observed.

The bare counting baseline 1/16 = 6.25% is a **reference, not a null**, and the split it supports is
withdrawn. Turning the theorem's 16-element eligibility *support* into a probability of 1/16 needs
exchangeability across the 16 eligible pairs, which is not proven here — T2ii above says only that
eligibility is necessary, and the per-pair spread inside a class is unknown except for A₂ — and the
measured class masses already show the assumption failing: 65.2 / 17.5 / 17.4% against the
counting baseline 62.5 / 18.75 / 18.75%. *(Through v2.2 this paragraph published the counting split
×1.9 parity-forced · ×1.25 contingent as though 1/16 were a null; corrected v2.3 to the measured
×2.02 · ×1.20. The two sibling statements of the counting split — [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md)
§2(d) and [LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md)
§3 — were adjudicated separately and, at v2.3, were still outstanding; both were corrected to the same
measured split later on 2026-09-02 (TR-1 v1.32; the population-tests document's marker of that date), so
no document now prices the anchor off 1/16 as a null.)*

**Measured circular anchor adjacency (v2.0).** What remains genuinely contingent is the adjacency
*placement* itself. Its circular population frequency — R-C1c, the weighted C1–C5-mass fraction in
which the alternating pair occupies slot 2 or slot 32 — was pre-registered above (v1.9) and has now
been measured (2×10¹⁰ weighted-Knuth probes; evidence `evidence/r6/rc1c_primary.out`): **13.05% of
C1–C5 mass** (slot 32: 7.85%, reproducing the published R-C1 = 7.84% — the built-in scorer gate;
slot 2: 5.20%). Against the pre-registered references that is ×2.0 the uniform-slots baseline
(6.45%) and ×1.66 the eligibility-adjusted lower bound (7.84%). The descriptive A₂ slot histogram
is U-shaped: slot 2 is the largest non-final slot (5.20%, vs 3.84% at slot 3 and a 2.68% minimum at
slot 17), so the alternating pair is enriched at *both* circle-adjacent slots, not merely
late-biased — though slot 32 remains the global maximum. The KW ground truth (slot 2 = 0,
slot 32 = 1, adjacent = 1) and the negative control (the wrap-d5 SAT witness scores adjacent = 0)
were verified in both languages before the run. In plain terms: roughly one in eight valid
orderings places the two anchor pairs adjacent on the circle — KW's configuration is
population-common, and this measurement prices it; it does not elevate it. Likewise the *circular
solution-space size* is now measured: the C5-budget-override walk passed its self-gate (the
standard-multiset override reproduces N_lin byte-identically) and gives N(M′) = 6.507×10³⁷
(95% CI [6.50, 6.51]×10³⁷) with wrap-d1 mass f₁(M′) = 0.175, so the exact decomposition yields
**|C_circ| = 0.652·|C1–C5| + 0.175·6.507×10³⁷ ≈ 9.80×10³⁷ — about 0.74× the linear space**
(using the fresh run's f₃ = 0.6518 instead of the published 0.652 changes nothing at 3
significant figures). This resolves the one report-only R-series observable registered in v1.9;
per the §6 non-promotion decision it is measurement and theorem, not constraint — neither the
circular reading (McKenna's frame) nor the anchor rule (Cook's observation) enters the formal
system.

*Attribution: circular frame McKenna & McKenna (1975); the final-pair anchor rule Cook (2006); the
rigidity/eligibility theorems, the 10:3:3 classification, and the eligibility-adjusted re-pricing are
ROAE (to our knowledge first stated here — the ingredients are elementary and may appear elsewhere;
corrections welcome via [CITATIONS.md](../documentation/CITATIONS.md)).*

### Verification Guide additions (v1.9)
- Anchor rigidity (T1) + seam eligibility (T2i) + 10:3:3 classification (T2ii): exhaustive finite
  re-check in one Python session from `solve.py`'s `binary_hexagrams`. **None of the three exists as
  a named theorem in `lean/`.** `anchor_cross_distance_three`, `no_even_pair_closes` and
  `closer_classes_10_3_3` are *intended names* for a planned formalization in `lean/KingWen.lean`;
  no theorem or lemma by any of those names exists in `lean/` on any branch. T2i's conclusion is
  nonetheless kernel-checked, though not as a standalone named theorem: it appears as an
  intermediate step inside the proof of `circular_alternations_16` in `lean/KingWen.lean`
  (`pc6 (l.getD 62 0) % 2 = 1` — the closing pair's class is odd — established for every C1+C4+C5
  sequence from `wrap_parity_general` (§2) and `partner_parity`; that theorem's own *conclusion* is
  the 16-alternation count, not the seam parity). To cite T2i from Lean you must either cite the
  enclosing theorem or lift the step out into a named lemma. The pair-parity
  ingredients `partner_preserves_parity` and `parity_split_32_32` are kernel-`decide` theorems in
  the same file ([TR-6](TR6_PARITY_SKELETON.md)).
- Circular anchor adjacency R-C1c + A₂ slot histogram:
  `SOLVE_KNUTH_SCORE=1 ./solve --estimate-knuth 20000000000` (KW gate: slot2 = 0, slot32 = 1,
  adjacent = 1; d5-witness negative control = 0; the run's slot-32 mass must reproduce
  R-C1 ≈ 7.84% — measured run: `evidence/r6/rc1c_primary.out`, adjacent = 0.130472).
- Circular-space size:
  `SOLVE_KNUTH_C5_BUDGET="1:1,2:20,3:14,4:19,6:9" SOLVE_KNUTH_SCORE=1 ./solve --estimate-knuth 20000000000`
  (self-gate: standard-budget override `1:2,2:20,3:13,4:19,6:9` reproduces N_lin — verified
  byte-identical, `evidence/r6/budget_selfgate.out`; M′ run: `evidence/r6/mprime_walk.out`).

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
| v1.8 | 2026-07-04 | 32-circular-switches corollary added (TR-6 30-switches × wrap-parity composition; derived in cross-report synthesis 2026-07-04, re-verified independently) |
| v1.9 | 2026-07-10 | "The anchors on the circle" section added: anchor-transition rigidity (T1) + seam eligibility (T2i) + pair-determined 10:3:3 wrap classification (T2ii) — elementary, exhaustively finite-verified (Lean formalization planned); Cook's final-pair anchor re-priced against the parity-forced 1/16 eligibility baseline (apparent ×2.4 = ×1.9 forced · ×1.25 contingent). Circular anchor-adjacency population frequency (R-C1c) and circular-space size |C_circ| pre-registered but PENDING measurement (walks not yet run). |
| v2.0 | 2026-07-10 | R-C1c and \|C_circ\| measured (evidence `reports/evidence/r6/`): circular anchor adjacency = 13.05% of C1–C5 mass (slot 32 = 7.85%, reproducing the R-C1 gate; slot 2 = 5.20%, the largest non-final slot — U-shaped A₂ histogram), vs pre-registered references 6.45% uniform-slots / 7.84% eligibility lower bound; \|C_circ\| = 0.652·N_lin + 0.175·6.507×10³⁷ ≈ 9.80×10³⁷ ≈ 0.74× the linear space. Report-only; no promotion. |
| v2.1 | 2026-07-20 | **Conditional-forcing correction (adversarial-review F-14a).** §3's "forced by the constraint system, an artifact of no design choice at all" restated as **forced given C4 + C5** — and therefore not an independent design choice *within* that system — with the added note that C5 is itself a regularity read off King Wen, so "forced" is relative to KW-derived constraints rather than to an unconstrained arranger. The prior phrasing smuggled the KW-derived constraints in as premise. No measurement changed |
| v2.2 | 2026-07-26 | **Wrap-mass uncertainty stated from archived artifacts (round-2 audit, completeness loop 4e G2).** The published 17.5/65.2/17.4% masses always cited "CIs per METHODS" without printing them; the instrument in fact emits point masses without per-class CIs, so no ± existed to print. The abstract and §5 now state the published uncertainty as the two-run agreement: the independent v2.0 r6 rerun (`evidence/r6/rc1c_primary.out`, 2×10¹⁰ probes) re-measured 17.45/65.18/17.37% — within 0.05 pp per class of the published figures. Per-class bootstrap CIs would need a recompute and are left as an open improvement. No mass value changed |
| v2.3 | 2026-09-02 | **Four Codex V2-F09 corrections (prose batch P36).** (1) §6's rotation claim was false: without C4 the 32 pair-slot rotations act as symmetries of a circular system only if C3 is *also* circularized. Under this report's absolute-position C3, **21 of the 31 non-identity rotations of KW exceed the 776 ceiling** (rotate-4 = 888, rotate-16 = 1240); the sentence now says so, §1 carries the matching caveat that "unaffected by closure" is not rotation-invariance, and the Verification Guide gains a one-line reproduction from `verify.py`'s clean-room C3. The identical sentence at documentation/CIRCULAR_KING_WEN.md §"Symmetry under closure" was corrected in the same pass. (2) The published uncertainty statement is **withdrawn**: the r6 rerun is not an independent draw. Neither archived artifact carries a `SEED OVERRIDE` line, and the estimator seeds worker *i* by thread index alone, so the 32-thread and 64-thread runs share 10×10⁹ of their 20×10⁹ probes; the 0.05-pp agreement is arithmetic. The companion "no per-class CIs" premise was also stale — the instrument has printed `se=` since 2026-08-28 (METHODS.md), though the 2026-07 artifacts predate the field. Abstract, §5 and the Verification Guide now all state that **no ± is published for these masses**. (3) The Cook-anchor split ×1.9 forced · ×1.25 contingent assumed exchangeability across the 16 eligible pairs, which is unproved and which the same paragraph's measured class masses contradict; recomputed against the **measured** 6.52% d = 3 class average as **×2.02 · ×1.20**, with 1/16 relabelled a reference rather than a null. Two sibling sites (TR-1 §2(d), LITERATURE_RULES_POPULATION_TESTS.md §3) are adjudicated separately and remain outstanding. (4) The Meyer (1998) prior-art note stated the document's content flatly; the source 404'd in 2026-08 with zero Wayback captures, so the note now marks the read unrepeatable and credits the wrap value and no-5 property as stated claims to McKenna & McKenna (1975), as CITATIONS.md already did. No measurement, theorem or canonical sha changed; two published ratios changed and both are recomputations from figures already printed in this report |
| v2.4 | 2026-09-02 | **Stack requirement narrowed to what the binary enforces (prose batch P37, Codex V2-F08 #4; wording only).** The `--estimate-knuth` warning published `ulimit -s unlimited` as REQUIRED. It is a **sufficient** setting, not a necessary one, and on a host or container whose hard limit forbids `unlimited` the published requirement was a false blocker. `solve.c`'s preflight tests `rlim_cur != RLIM_INFINITY && rlim_cur < 16UL*1024*1024` and its message names ">= 16 MB"; executed under TR-9 v1.24, `ulimit -s 8192` refuses and exits 1 while `ulimit -s 16384` runs the estimator to completion. The banner now states "at least 16 MB (`ulimit -s 16384` suffices)" with `unlimited` named as one sufficient setting. This is the sibling sweep TR-9 v1.24 reported but did not perform. No figure, count, command, claim or scope changes |
| v2.5 *(current)* | 2026-09-02 | **§"The anchors on the circle" marker updated: the two sibling sites of the withdrawn counting split are no longer outstanding (prose lane, backlog item 104).** v2.3 corrected this report's ×1.9 · ×1.25 split to the measured ×2.02 · ×1.20 and named [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) §2(d) and [LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md) §3 as still carrying the counting split. Both were corrected later the same day (TR-1 v1.32; the population-tests document's 2026-09-02 marker) to the same quotients of the same figures this report prints — 6.52 / 3.2258 = ×2.02 and 7.84 / 6.52 = ×1.20 — and the marker now says so. The sibling sweep's population and count are recorded in CORRECTIONS.md. No figure, theorem, certificate or verdict in this report changes |
