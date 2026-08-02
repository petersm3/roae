# Testing the Literature's Structural Rules at Population Scale

**Result (2026-07-02):** Structural rules asserted for the King Wen sequence in prior literature — none of
them ROAE discoveries — were formalized in the C1–C5 pair representation and measured against the *entire*
constraint-satisfying population (≈1.33×10³⁸ orderings) by unbiased weighted-Knuth estimation
(`SOLVE_KNUTH_SCORE=1`, 2×10¹⁰ probes; the instrument reproduced the previously-published total space
size *estimate* to 0.03%, a consistency check within the same estimator family; the absolute validation of
the estimator is TR-11's exact anchors). *(Corrected 2026-08-01: "independently-established" was the
adjective [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) v1.18/v1.21 retracted — the total space size
is itself a Knuth estimate from the same estimator family (METHODS status **estimate**, source TR-4 §3),
so agreement with it is not independent establishment. TR-1 v1.21 recorded this file's copy as still
outstanding; it is corrected here.)* This converts decades of by-inspection claims into measured
population statistics for the first time. **Attribution:** every rule below is credited to its source (with lineage where it runs deep — the pair
structure itself is attested to [Yu Fan](CITATIONS.md#yufan), 164–233 AD; the 36-unit consolidation to [Lai Zhide](CITATIONS.md#laizhide), 1525–1604; the
gender/position-parity rule measured at ×11,364 in the companion registry originates with **[Schulz 1990](CITATIONS.md#schulz1990-motifs)**
and was elaborated by [Cook 2006](CITATIONS.md#cook2006)); see
[CITATIONS.md](CITATIONS.md) §Attributed candidate rules. ROAE's contribution is formalization + measurement.

## The scoreboard

| Rule (source) | Fraction of C1–C5 mass | Cut factor | King Wen |
|---|---|---|---|
| Pair-positioning parity, strict 18/18 ([Moore 2005](CITATIONS.md#moore2005)) | 5×10⁻⁶ | ×200,000 | **fails** (16/18) |
| Both Moore rules at KW's level (joint) | 1.85×10⁻⁵ | ×54,000 | satisfies |
| Pair-positioning parity ≥16/18 (Moore 2005) | 7.3×10⁻⁴ | ×1,362 | satisfies (exactly 16/18) |
| Rising/falling alternation, 0 breaks ([Moore 1989](CITATIONS.md#moore1989)) | 6.3×10⁻⁴ | ×1,598 | **fails** (2 breaks) |
| Rising/falling alternation ≤2 breaks (Moore 1989) | 3.85% | ×26 | satisfies |
| Final-pair anchor: alternating pair last (Cook 2006) | 7.84% | ×12.8 | satisfies |
| First 7 pairs cover all 7 levels (Cook 2006) | 12.03% | ×8.3 | satisfies |
| 18:18 two-part class split (Zheng Qiao ~1150; Hu Yigui 1247; [Hacker & Moore 2003](CITATIONS.md#hacker-moore2003); Cook 2006) | 36.4% | ×2.7 | satisfies |

## What the measurements establish

1. **Moore's pair-positioning rule is the strongest literature discriminator among the population-measured
   rules in this table** (later exceeded by the SAT-decided S25–28 trigram rule at ×5×10⁷ — see "A new
   strongest discriminator" below). King Wen's 16-of-18
   compliance is shared by ~1 in 1,362 constraint-satisfying orderings; its *joint* profile under Moore's
   two rules by ~1 in 54,000. The rules are **negatively correlated** (joint mass = 0.66× the independence
   prediction) — the parity and rhythm constraints compete, a structural fact not previously observed.
2. **King Wen is near-optimal but strictly suboptimal on both Moore rules — and fully-compliant orderings
   exist on each.** Perfect 18/18 parity compliance is achieved by ~5×10⁻⁶ of the population (observed
   directly; Moore himself conjectured such "uncorrupted" orderings might exist — the conjecture is
   **confirmed** for each rule separately; whether an ordering satisfies both strict forms simultaneously
   is under investigation with a targeted instrument, since ~10⁻⁹-scale masses exceed plain sampling).
   Both readings of the pairs-22/23 anomaly therefore remain live: deliberate/corrupted deviation from a
   compliant precursor (Moore), or the rules being strong tendencies rather than exact laws.
3. **Cook's anchor rules are real but partially explained.** The final-pair anchor holds in 7.8% of the
   population — far above the naive 1/31 ≈ 3.2%, **but most of that gap is forced: the wrap-parity theorem
   makes 16 of the 31 non-initial pairs ineligible to close ([TR-7](../reports/TR7_CIRCULAR_READING.md)
   §"The anchors on the circle"), so the eligibility-adjusted baseline is 1/16 = 6.25% and the residual
   enrichment is only ×1.25** — the rule is genuine but its surprise is smaller than raw position-counting
   suggests. (The earlier "because C5's transition budget favors closing on a distance-6 pair" reading is
   demoted to at most a candidate mechanism for the ×1.25 residual: only 4 of the 16 eligible closers are
   distance-6-within pairs, so it cannot carry the main effect.)
4. **The classical 18:18 split is weak as a discriminator** (36% of all valid orderings have it) — its
   significance is historical attestation, not statistical rarity.
5. None of these rules, singly or jointly, approaches uniqueness (the full C1–C7 space itself holds
   ≈5.2×10³¹ orderings — see [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md)). Accordingly **none is promoted
   into the formal constraint system**; they are measured properties of King Wen's position in the
   population, with description-length and attestation recorded for each.

## Method and caveats

Weighted Knuth random probes (validated in [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md)): each probe walks
a uniformly-random constraint-satisfying completion, weighting by the product of branching factors; per-leaf
rule predicates accumulate weighted mass; fractions are ratios of canonical-leaf masses. Caveats: fractions
are over raw orientation-resolved sequences. A rule's *value* is orientation-invariant when it depends
only on the pair ordering, but its reported *fraction* is not: it is Σ_{P: R(P)} fiber(P) / Σ_P fiber(P),
a fiber-size-weighted fraction, and fiber size is a function of the pair ordering's transition geometry —
the same geometry most literature rules score. Fiber size is far from constant (0 for every pair ordering
admitting no valid orientation; ≥1,720,320 for King Wen's, against a mean of ≈1.3×10⁵ over all 31! pair
orderings). Read every fraction below as a weighted-population fraction whose weighting is not known to be
independent of the rules. *(Corrected 2026-08-01: this caveat previously said "orientation-invariant rules
are unaffected", which is true of a predicate's value and **false of the reported fraction** — the
correction landed in [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) §1(b) on 2026-08-01 and is
propagated here.)* Moore's 1989
rising/falling rule is orientation-sensitive by design; strict-form masses near 10⁻⁶ carry ~±10-15%
relative sampling error at this probe count; formalizations were verified to reproduce each source's stated
King Wen values exactly before measurement (16/18 with violations at pair positions 22–23; rhythm breaks at
(7,8) and (22,23)). Reproduce: `SOLVE_KNUTH_SCORE=1 ./solve --estimate-knuth 20000000000`.

## SAT-decided exact results (2026-07-02, second instrument)

Population fractions above are statistical; a SAT layer (`sat.py`, encoding derived from `solve.py`'s
constraint definitions, external kissat solver, DRAT certificates) adds *exact* decisions:

1. **Moore's conjectured fully-compliant ordering exists — here is one.** An explicit C1–C5-valid sequence
   satisfying his 2005 parity rule 18/18 AND his 1989 rhythm rule with 0 breaks, differing from King Wen
   only by swapping pairs 22↔23 (his anomaly) and flipping two within-pair orientations (pairs 8 and 23):
   `63,0,17,34,23,58,2,16,55,59,7,56,61,47,8,4,25,38,3,48,41,37,32,1,57,39,33,30,18,45,28,14,60,15,40,5,
   53,43,20,10,35,49,24,6,62,31,26,22,29,46,9,36,52,11,13,44,54,27,50,19,51,12,21,42` (complement-distance
   sum 776 — it satisfies C3 at the same ceiling as KW). Moore (1989) judged the bare 22/23 swap "too
   simplistic" because it leaves the rhythm broken; the two orientation flips complete the repair.
2. **The minimal repair is exactly 3 slot-edits** — SAT-decided: no ordering within 2 slot-edits of King Wen
   achieves joint compliance (UNSAT, a fortiori under C3), and 3 suffices. If a compliant precursor ever
   existed, the deviation to KW was a 3-edit event centered on Moore's own anomaly locus.
3. **The parity-alternation theorem is SAT-verified over the full space** (its third independent
   verification after the prose proof and the Lean-checked lemmas): both "≤14 alternations" and "≥16
   alternations" are UNSAT under C1+C2+C4+C5.
4. The joint-strict population size (pinned-walk estimate): ≈1.13×10²⁹ canonical orderings (±4.7%).

Certificates are archived and **independently verified** (drat-trim, 2026-07-03: all four UNSAT proofs —
alt-le-14, alt-ge-16, moore-strict-near-2, rc4-strict-near-2 — check `s VERIFIED` against regenerated
CNFs). The encoder round-trip validation's first solver model, pleasingly, is King Wen itself. Reproduce
with `python3 sat.py --witness moore-strict` and
`python3 sat.py --emit-cnf alt-le-14 f.cnf && kissat f.cnf`.

### Schulz gender rule + the grand unified precursor (2026-07-03)

5. **Schulz's gender rule is perfectly satisfiable — and its minimal repair is ALSO exactly 3 edits.**
   The strict form of the strongest measured discriminator (gender/position-parity, Schulz 1990; exception
   first noticed by Zhu Yuansheng, 13th c.) had 0 hits in 36M samples — *flagged 2026-08-01 as unsourced
   and withdrawn pending a stated null: no null, sampler or source run was ever recorded with that figure,
   and it is not consistent with this suite's later measurement of the strict gender rule at ≈10⁻⁶ of
   canonical mass (`../reports/evidence/f11/RESULTS.md`, RUN C2) — if those 36M draws were canonical, that
   mass predicts ≈36 hits, not 0. Treat the strict form as population-rare at order 10⁻⁶; the flag was
   raised in [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) §4 and is propagated here.* SAT decides
   it: witnesses exist
   (C1–C5-valid, C3 = 776), and the minimal repair from King Wen is exactly 3 slot-edits (≤2 UNSAT, DRAT
   cert archived) — a swap of the adjacent pairs at slots 21/22 (= class positions 25/26, precisely the
   Zhu Yuansheng/Schulz exception locus) plus one orientation flip.

   *Convention-stability note (2026-07-12).* The rule admits two natural predicate forms: the form its
   sources state — parity throughout, with at most one exception pair at adjacent class positions
   ([Schulz 1990](CITATIONS.md#schulz1990-motifs), elaborated by [Cook 2006](CITATIONS.md#cook2006); the
   exception first recognized by Zhu Yuansheng, 13th c.) — and the "≤2 violations anywhere" relaxation
   under which the ×11,364 figure was measured. Re-measured under the source-stated exception form,
   paired on identical probes with the published form, the population fraction comes out the same order —
   within about one order of magnitude (≈11× smaller, hence a somewhat *stronger* cut; no weaker is
   possible, the exception form being a subset of the relaxation by construction) — so the ×11,364
   discriminator is robust to the choice of convention, not an artifact of the relaxation. King Wen passes
   both forms: its two violations are adjacent, at class positions 25/26, precisely the Zhu
   Yuansheng/Schulz exception locus (two-language verifier `--rc4b-verify`; predicates R-C4-A/R-C4-B,
   [SOLVE_C_CLI.md](SOLVE_C_CLI.md#--rc4b-verify)). Two-convention re-measurement is standard robustness
   practice, recorded as due diligence rather than claimed as a result.
6. **The grand unified precursor exists: one ordering satisfies ALL THREE literature rules perfectly** —
   Moore's 2005 parity (18/18), Moore's 1989 rhythm (0 breaks), and Schulz's 1990 gender rule (0
   violations) — again C1–C5-valid at C3 = 776:
   `63,0,17,34,23,58,2,16,55,59,7,56,61,47,8,4,25,38,3,48,41,37,32,1,57,39,33,30,18,45,28,14,60,15,40,5,
   53,43,20,10,35,49,24,6,62,31,26,22,29,46,9,36,52,11,13,44,54,27,50,19,51,12,21,42`
7. **The grand minimal repair is exactly 3 slot-edits** (a fortiori ≥3 from result 5; 3 achieved): an
   orientation flip at slot 7 and an adjacent-pair swap at slots 21/22. The three rules' minimal repairs
   are not merely equal-sized — they are *compatible*: a single 3-edit event completes all three at once.
   If any corruption/precursor reading of the literature is right, the deviation was one small event, and
   every independently-observed anomaly (Moore's pairs 22–23, Zhu Yuansheng/Schulz's stations 25–26) is a
   shadow of it. We note the standard caveat: witnesses produced by a solver seeded with King Wen's
   variable order are biased toward KW-like repairs; minimality (3) is exact, the specific repair need not
   be unique. Reproduce: `python3 sat.py --witness grand-strict`; certificates in the evidence archive.

## The extended scoreboard: 31 further literature rules (2026-07-03 batch, 2×10¹⁰ probes)

The full candidate inventory from the Schulz corpus (1990/2011/2016/2018 + the 1982 dissertation's
Lai Zhide rules), [McKenna & Mair 1979](CITATIONS.md#mckenna-mair1979), [Drasny](CITATIONS.md#drasny2007), and [Schöter](CITATIONS.md#schoter1998) — 31 rules formalized (two-language verified,
each reproducing its source's stated King Wen values), measured in one run. Full per-rule registry and
attribution: solve.py `--registry-verify` section.

> **The rule predicates are code-resident, and that is a replication limit** (stated 2026-08-01, lens
> sweep). There is no document — not this one, not [SPECIFICATION.md](SPECIFICATION.md), not
> [SAT_CLI.md](SAT_CLI.md) — that states Moore parity, Moore rhythm, Schulz gender, CC-N4 or CC-N8
> formally enough for an independent team to re-encode them. The definitions live in `solve.py`'s
> `reg_*` predicates; `sat.py`'s targets import those semantics rather than restating them
> ([SAT_CLI.md](SAT_CLI.md) §TARGETS), so the SAT layer inherits the same single reading. The
> KW-value gate each rule passes is a **one-point** check: it establishes that our encoding agrees
> with the source's published King Wen tally, and cannot distinguish a faithful rendering of what
> Moore or Schulz wrote from a differently-scoped predicate that happens to agree on that one
> sequence — which is where every population figure on this page actually lives. This is
> [METHODS.md](../reports/METHODS.md)'s independence rung 2 ("only the encoder") made concrete: a
> replicator can *re-run* our encoding and reproduce the numbers, but cannot *independently re-derive*
> the encoding from the published record. Formal prose statements of the 31 rules would close the
> gap; they have not been written.

Three headline findings:

**1. A new strongest discriminator — with the data-likeness caveat stated plainly.** Schulz's S25–28
trigram configuration (2011/2016: four consecutive stations sharing the dui top trigram, bottoms = the
four "right" trigrams in order) holds in 2×10⁻⁸ of the population (×5×10⁷) — 2.4 orders beyond the
previous champion. Like Cook's exact level-3 positions, this is a highly *specific* configuration: its
registry classification is data-like rather than principled, and it is reported as a measured property,
not promoted. The exception-co-location meta-rule (both Schulz rules' violations confined to S25/26)
measures 2.6×10⁻⁷ (×3.8M) — the anomaly locus itself is population-rare.

**2. Eight literature rules are consequences of the constraint system — proven, not sampled (upgraded
2026-07-21).** All eight rules that measure at 1.0 of canonical mass (mmt4, p1c4, s1, s6, r3, r4, r5,
c2 — including three consequences of [Radisic's](CITATIONS.md#radisic2026) optimality structure),
asserted in the literature as design features, are now **theorems**: each depends only on the unordered
pair-partition, which C1 fixes, so each is constant on the *entire C1 space* — a superset of the C1–C5
population, hence a fortiori equal to King Wen's value on every C1–C5 ordering. Machine-checked in Lean 4
([lean/C1RuleConstants.lean](../lean/C1RuleConstants.lean); the r4/r5 threshold forms hold because the
C1-fixed within-pair HD histogram {2:12, 4:12, 6:8} — which is c2 — sums to a total pairing cost of
exactly 120, meeting r4's ≤120 threshold with equality). Their zero-violation readings in 2×10¹⁰ weighted
probes — previously reported only as "empirically forced to the estimator's precision", since sampling
cannot distinguish mass 1 from mass 1−ε — now validate the instrument end-to-end rather than carry the
claim. A separate, additional analytic theorem — the no-5 rule's implication chain, behind McKenna's 3:1
even:odd transition ratio, the first literature rule proven forced — is distinct from these eight and
stands unchanged. Several more rules are near-forced (0.95–0.9998); those remain sampling results. The
literature's design inventory therefore splits three ways: proven forced / typical / genuinely
discriminating.

**3. The xiaoxi-placement row `d7` is DATA-LIKE, and its "maximality" is an artefact of its own
specification** (classified 2026-08-02; this replaces the earlier reading, which called KW's 8/8 "a
genuine extremal property"). `d7` counts how many of the 12 xiaoxi hexagrams occupy eight hard-coded slots
— 0-based 18, 19, 22, 23, 32, 33, 42, 43 — which are verifiably eight of King Wen's own twelve xiaoxi
slots (KW's full set: 0, 1, 10, 11, 18, 19, 22, 23, 32, 33, 42, 43). Eight borrowed degrees of freedom;
KW's 8/8 is guaranteed by construction, and 8 is the functional's range ceiling rather than a located
population maximum. Shift the window by 1–5 and KW scores 4, 0, 1, 2, 1. Under
[reports/METHODS.md](../reports/METHODS.md) §"Data-like vs principled" the row is data-like and its
1.7×10⁻⁴ mass is priced as specification. Attribution narrows accordingly: Drasny and Schulz & Cunningham
state the *identification* of the xiaoxi (a bit-pattern classification, constant on every ordering); the
positional predicate is this suite's own formalization. Schulz's separate xiaoxi *placement* rule — the
1/13/25 trisection, row `rs1` — is a distinct row and is **not** classified here; it needs its own dof
count. Full detail in
[reports/TR1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) §3 headline 3.

Full table (fraction of canonical mass; KW satisfies each at its measured level by construction of the
threshold forms; the eight **1.0 (theorem)** entries are the proven C1 constants of headline 2 — exact by
theorem, not estimates): rs1 6.6×10⁻⁴ · rs2 3.0×10⁻³ (max seen 26/26 vs KW 20) · ccn1 3.4×10⁻⁵ ·
ccn2 1.5×10⁻³ · ccn3 6.6×10⁻⁶ · **ccn4 2×10⁻⁸** · ccn6 0.427 · ccn7 1.1×10⁻³ · **ccn8 2.6×10⁻⁷** ·
c2011n1 <10⁻⁹ (0 hits) · c2011n2 5.9×10⁻⁵ · c2011n4 1.1×10⁻² · mmt3 0.953 (min Gray-transitions seen 0
vs KW 4) · mmt4 **1.0 (theorem)** · mmt5 0.9998 · mmt6 0.993 · p1c4 **1.0 (theorem)** · p2c3 6.7×10⁻² ·
p2c4 1.0×10⁻³ · p2c5 2.3×10⁻³ · p2c6 4.1×10⁻⁴ · d4 5.7×10⁻⁴ · d7 1.7×10⁻⁴ (KW 8/8 — *data-like*: 8
borrowed dof, 8 is the range ceiling; see headline 3) ·
s1 **1.0 (theorem)** · s6 **1.0 (theorem)** · m2 8.0×10⁻² · r3 **1.0 (theorem)** · r4 **1.0 (theorem)** ·
r5 **1.0 (theorem)** · c1 6.6×10⁻² (min deviation seen 4 vs KW 24) · c2 **1.0 (theorem)**.
Wrap-distance finals: d1 = 17.5%, d3 = 65.2%, **d5 = 17.4%** of the full space — see
[CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md) (the slice contains zero d5 records in 10.5B).
**Deep-tail caveat (travels with the smallest figures; details in
[reports/METHODS.md](../reports/METHODS.md)):** below ~10⁻⁷ per-probe hit rates the estimator's CIs
degrade (low effective sample size, right-skewed weights) — read ccn4 (2×10⁻⁸) and ccn8 (2.6×10⁻⁷) as
order-of-magnitude figures, not point estimates, and c2011n1's "<10⁻⁹ (0 hits)" as sampling starvation,
not a bound.

## The conflict theorem (2026-07-04, SAT-decided, drat-trim verified): perfection was never available

The literature's four strongest rules are **jointly unsatisfiable**: no C1∩C2∩C4∩C5-valid ordering achieves
Moore's 2005 parity (18/18), Moore's 1989 rhythm (0 breaks), the Schulz gender rule (0 violations), and
the Schulz S25–28 trigram configuration simultaneously (UNSAT under C1+C2+C4+C5, hence a fortiori with
C3; certificate independently verified). The pieces fit together sharply:

- King Wen satisfies the trigram configuration **exactly**, and misses the other three by the minimal
  measured margins (16/18, 2 breaks, 2 violations).
- The 3-edit "grand precursor" satisfies those three **perfectly** — and breaks the trigram configuration.
- Both cannot be had: **the rules compete**, and any ordering must choose which to satisfy.

Consequence for the corruption hypothesis: an "uncorrupted precursor" perfect under the literature's full
rule inventory **never existed** — the corruption reading survives only in the restricted sense (perfect
under Moore's two rules alone, breaking the trigram structure KW keeps). King Wen's profile now reads
naturally as a **trade-off position**: exact on one strong rule, minimally imperfect on the others. All
four rules are KW-derived — selected because King Wen exhibits them, even where their form is general —
so King Wen sitting near their joint Pareto frontier is expected rather than an efficiency result; the
~1-in-25-million figure **describes** how population-atypical that joint profile is under KW-fitted
rules, and is not a measure of design efficiency (no arbitrary-rule-bundle baseline exists to read it
against; restated per TR-1 v1.14, adversarial-review F-45). *(Sourcing flag, propagated 2026-08-01 from
[TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) §5: the ~1-in-25-million figure (≈4×10⁻⁸) is carried
from the v1.14 pass with **no derivation, probe count, CI or verification command anywhere in the repo**,
is not reconstructible from the published masses, and sits below the ~10⁻⁷ per-probe hit rate at which
§"The extended scoreboard" says to read figures as order-of-magnitude only — so the two significant figures are
unearned. Treat it as an unreproduced figure until a regeneration command is published; what would settle
it is a stated joint-profile predicate plus a run of `SOLVE_KNUTH_SCORE=1 ./solve --estimate-knuth
<probes>` reporting its mass with a CI.)* The usual
caveat travels with this: the trigram configuration is a data-like rule (highly specific); the theorem is
about the literature's rules exactly as its authors stated them. Reproduce:
`python3 sat.py --emit-cnf grand-ccn4 f.cnf && kissat f.cnf` (encoding two-way validated: ccn4-kwtest SAT,
rc4-kwtest UNSAT).
