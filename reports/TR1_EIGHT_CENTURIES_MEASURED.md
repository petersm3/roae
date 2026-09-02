# TR-1 — Eight Centuries of Rules, Measured: the Population Scoreboard
*Technical report — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. One caveat is structural, and it frames all the rest: the same
author wrote the claims, the software that checks them, and this report that grades the check.
Verification here is independent in mechanism, never in authorship; no independent party has yet
audited or reproduced any of it (METHODS.md §"Authorship independence").*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

For roughly eight centuries — the span of the *testable design-rule* literature this report measures,
which begins with Zhang Xingcheng 张行成 and Zhu Xi 朱熹 (both 12th c., so the span stands; the
18:18-split credit, corrected 2026-07-30 — see [CITATIONS.md](../documentation/CITATIONS.md#hacker-moore2003)
§"Attributed candidate rules"); structural observation of the sequence itself is far older (the
*Yi Zhuan*; [Yu Fan](../documentation/CITATIONS.md#yufan), 3rd c. CE) — scholars have claimed the King
Wen sequence follows hidden design rules —
almost always by pointing at the sequence and asserting the pattern. This report does what none of that
literature could: it **measures every claimed rule against the entire space of orderings** that satisfy
the sequence's core constraints — by unbiased weighted sampling of that space (2×10¹⁰ probes), not by
enumerating it. The result sorts the claims into three kinds. Eight celebrated "design
choices" are **forced** — and as of 2026-07-21 all eight are **theorems**, not sampling results (two of the eight, r3 (Radisic 2026) and p1c4 (Schulz 1982, citing Lai Zhide 1599), formalize to extensionally the **same** function of the ordering, so the eight literature rules state **seven distinct** ordering facts — one fact under two separately-published citations; both attributions stand. See TR-1 §3(2)): each is
proven constant on the entire C1 space (every pair-respecting ordering, a superset of the measured
population, so every C1–C5 ordering inherits it), equal to King Wen's value — machine-checked in Lean 4
([lean/C1RuleConstants.lean](../lean/C1RuleConstants.lean)). The twenty billion weighted probes that found
no violating ordering now serve as instrument validation, not as the basis of the claim. (A separate,
additional analytic theorem — the no-5 rule's implication chain, behind McKenna's 3:1 even:odd transition
ratio — was proven earlier and stands; it is not one of the eight.) Forced-ness means they reveal nothing
about the arranger. Others are **typical** — common enough to be unremarkable. A few are **extremely rare as
stated** (down
to roughly one in fifty million — an order-of-magnitude figure at that sampling depth, with the most
specific configurations rare largely by specification rather than principle; see §3's data-like caveat), and King Wen has them. The report culminates in the conflict theorem: the
literature's four strongest rules **cannot all be satisfied by any C1∩C2∩C4∩C5-valid ordering**, and King Wen sits
exactly where that conflict forces a choice. A follow-up battery (§7) turns the same measurement on the
sequence's most-ignored layer — which member of each pair comes first — where the one rule the literature
ever offered ([Van den Berghe's](../documentation/CITATIONS.md#vandenberghe1999) hand-derived nuclear
rule, c. 1999–2002) places King Wen at the ceiling of what is achievable. But that rule is a **fitted
description read off King Wen**, so its perfect score is not independent confirmation of design — the
mechanics and this scoping are in §7. Every number
here can be recomputed, and the impossibility results carry machine-checkable certificates.

## Abstract
Structural rules asserted for the King Wen sequence across eight centuries of literature — from
Zhang Xingcheng 张行成 and Zhu Xi 朱熹 (12th c.) and Zhu Yuansheng (13th c.) through [Lai Zhide](../documentation/CITATIONS.md#laizhide) (1525–1604) to Moore, Schulz, [Cook](../documentation/CITATIONS.md#cook2006), [McKenna & Mair](../documentation/CITATIONS.md#mckenna-mair1979),
[Drasny](../documentation/CITATIONS.md#drasny2007), and [Schöter](../documentation/CITATIONS.md#schoter1998) — none of them ROAE discoveries — were formalized in the C1–C5 pair representation and
measured against the *entire* constraint-satisfying population (≈1.33×10³⁸ orderings) by unbiased
weighted-Knuth estimation (2×10¹⁰ probes; the instrument reproduced the previously-published total
space size estimate to 0.03% — a consistency check within the same estimator family, since that figure
is itself a Knuth estimate (METHODS §"Canonical quantities", status **estimate**); the absolute validation of
the estimator is TR-11's exact anchors). This converts decades of by-inspection claims into
measured population statistics — to our knowledge for the first time; corrections welcome. The literature's design inventory splits three ways:
**proven forced** (eight literature rules stating seven distinct ordering facts — r3 and p1c4 are one predicate under two citations, §3(2) — each now a theorem: constant on the entire C1 space — a superset of the
measured population — equal to King Wen's value, machine-checked in Lean 4; their measured 1.0 of
canonical mass in 2×10¹⁰ weighted probes now reads as instrument validation — asserted in the literature
as design features), **typical** (e.g., the classical 18:18 split holds in 36.4% of all valid orderings), and
**discriminating as stated** (down to 2×10⁻⁸ for [Schulz's](../documentation/CITATIONS.md#schulz2011) S25–28 trigram configuration — a data-like rule whose rarity is partly specification, not principle; §3). A SAT layer adds
exact decisions: Moore's conjectured "uncorrupted precursor" exists, its minimal repair from King Wen is
exactly 3 slot-edits, and one ordering — the grand unified precursor — perfects Moore's two rules and
Schulz's gender rule simultaneously via a single compatible 3-edit event centered on the literature's own
anomaly loci. And then the ceiling: **the four strongest rules are jointly unsatisfiable** (the conflict
theorem, drat-trim-verified). Perfection was never available; King Wen's profile reads as a trade-off
position — exact on one strong rule, missing the other three by 2 each (measured margins; no
extremal check exists). (All four rules are
KW-descriptive, so sitting near their joint Pareto frontier is expected rather than an efficiency
result — see §5.)

## Sections
1. **The question and the instrument.** The literature's rules were established by inspection of one
   object; population measurement asks how much of the C1–C5-satisfying space (≈1.33×10³⁸ orderings —
   [SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md)) shares each property. Method: weighted Knuth random probes
   (`SOLVE_KNUTH_SCORE=1`, 2×10¹⁰ probes) — each probe walks a uniformly-random constraint-satisfying
   completion, weighting by the product of branching factors; per-leaf rule predicates accumulate weighted
   mass; fractions are ratios of canonical-leaf masses. Consistency check: the instrument reproduced the
   previously-published total space size estimate to 0.03% (agreement within the same estimator family,
   since that figure is itself a Knuth estimate — the
   absolute validation of the estimator is TR-11's exact anchors). Every formalization was verified to reproduce its
   source's stated King Wen values exactly before measurement (Moore's 16/18 with violations at pair
   positions 22–23; rhythm breaks at (7,8) and (22,23)); rule predicates are two-language verified
   (independent C and Python implementations). Caveats stated up front:
   **(a) the KW-value gate constrains each formalization at one point.** Reproducing a source's stated
   King Wen value is the credential every rule here carries, but the measurements live at the other
   ≈10³⁸ orderings, where an off-by-one window, a tie convention or a wrap-vs-linear reading would pass
   every published gate and still produce wrong masses. Two-language agreement does not close this — both
   implementations derive from the same reading of the source — so rule faithfulness sits on rung 2 of
   METHODS' independence ladder ("only the encoder"), and the class has fired once already
   ([CRITIQUE.md](../documentation/CRITIQUE.md) records the widely-quoted 14:2 odd-transition figure as
   the *circular* reading presented as linear, caught by recomputation, not by a KW gate).
   **(b) the reported fractions are fiber-weighted, not uniform over pair orderings.** Fractions are over
   raw orientation-resolved sequences. A rule's *value* is orientation-invariant when it depends only on
   the pair ordering, but its reported *fraction* is not: it is Σ_{P: R(P)} fiber(P) / Σ_P fiber(P), a
   fiber-size-weighted fraction, and fiber size is a function of the pair ordering's transition geometry —
   the same geometry most literature rules score. Fiber size is far from constant: it is 0 for every pair
   ordering admitting no valid orientation and at least 1,720,320 for King Wen's, against a mean of
   ≈1.3×10⁵ over all 31! pair orderings (|C1∩C2∩C4∩C5| / 31!). These figures should therefore be read as
   weighted-population fractions, and the weighting is not known to be independent of the rules. *(Corrected 2026-08-01: this caveat previously said
   "orientation-invariant rules unaffected", which is true of the predicate's value and false of the
   fraction.)* [Moore's 1989](../documentation/CITATIONS.md#moore1989) rising/falling
   rule is orientation-sensitive by design. **(c) the C1–C5 denominator is itself partly KW-fitted.**
   C2 and C5 are regularities read off the received order and C3's ceiling is King Wen's own value 776
   ([METHODS.md](METHODS.md)), so the reference population against which King Wen is scored is not an
   undisputed null — it is conservative in the sense [TR-8](TR8_REORDERING_REVISITED.md) §2 states
   plainly, and the same firewall METHODS builds for constraints-as-evidence is not applied to
   constraints-as-denominator. **(d)** strict-form masses near 10⁻⁶ carry ~±10-15% relative sampling
   error at this probe count.
2. **The first-wave scoreboard (2026-07-02).**

   | Rule (source) | Fraction of C1–C5 mass | Cut factor | King Wen |
   |---|---|---|---|
   | Pair-positioning parity, strict 18/18 ([Moore 2005](../documentation/CITATIONS.md#moore2005)) | 5×10⁻⁶ | ×200,000 | **fails** (16/18) |
   | Both Moore rules at KW's level (joint) | 1.85×10⁻⁵ | ×54,000 | satisfies |
   | Pair-positioning parity ≥16/18 (Moore 2005) | 7.3×10⁻⁴ | ×1,362 | satisfies (exactly 16/18) |
   | Rising/falling alternation, 0 breaks (Moore 1989) | 6.3×10⁻⁴ | ×1,598 | **fails** (2 breaks) |
   | Rising/falling alternation ≤2 breaks (Moore 1989) | 3.85% | ×26 | satisfies |
   | Final-pair anchor: alternating pair last (Cook 2006) | 7.84% | ×12.8 | satisfies |
   | First 7 pairs cover all 7 levels (Cook 2006) | 12.03% | ×8.3 | satisfies |
   | 18:18 two-part class split (Zhang Xingcheng + Zhu Xi, 12th c.; Hu Yigui 1247; [Hacker & Moore 2003](../documentation/CITATIONS.md#hacker-moore2003); Cook 2006) | 36.4% | ×2.7 | satisfies |

   What this wave establishes: (a) Moore's pair-positioning rule was the strongest first-wave
   discriminator — KW's 16-of-18 compliance is shared by ~1 in 1,362 valid orderings, its joint Moore
   profile by ~1 in 54,000; (b) the two Moore rules are **negatively correlated** (joint mass = 0.66× the
   independence prediction) — parity and rhythm compete, a structure not, to our knowledge, previously observed. *(Interval
   caveat, added 2026-08-01: 0.66 is a ratio of three separately-estimated weighted masses and no
   uncertainty is published for it. Per the §1 caveat, masses near 10⁻⁶ carry ~±10-15% relative sampling
   error at this probe count, so read the direction — joint mass below the independence product — rather
   than the two-figure value, until a per-quantity relerr is published for the ratio.)*
   (c) KW is near-optimal but strictly suboptimal on both Moore rules, and fully-compliant orderings exist
   on each (Moore's "uncorrupted" conjecture confirmed per rule) — so both readings of the pairs-22/23
   anomaly remain live: deliberate/corrupted deviation from a compliant precursor (Moore), or strong
   tendencies rather than exact laws; (d) Cook's final-pair anchor is real but **mostly forced** — the
   measured 7.84% looks like a ×2.4 enrichment against the naive 1/31 ≈ 3.2%, but 1/31 is the wrong null:
   the wrap-parity theorem makes 16 of the 31 non-initial pairs ineligible to close
   ([TR-7](TR7_CIRCULAR_READING.md) §"The anchors on the circle"), so the eligibility-adjusted baseline is
   1/16 = 6.25%, ×1.9 of the apparent enrichment is parity-forced (it holds for *every* C4+C5 ordering)
   and only **×1.25 is the contingent residual**. *(Corrected 2026-08-01: this entry priced the anchor
   against the 1/31 uniform-slot null and attributed it to "C5's transition budget favouring a distance-6
   closer" — both superseded. Per
   [LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md), only 4
   of the 16 eligible closers are distance-6-within pairs, so that mechanism cannot carry the main effect;
   it is demoted to at most a candidate mechanism for the ×1.25 residual.)*
   (e) the classical 18:18 split is weak as a discriminator (36%) — its significance is historical
   attestation, not statistical rarity.
3. **The extended scoreboard: 31 further rules (2026-07-03 batch, 2×10¹⁰ probes).** The full candidate
   inventory from the Schulz corpus (1990/2011/2016/2018 + the 1982 dissertation's Lai Zhide rules),
   McKenna & Mair 1979, Drasny, and Schöter — 31 rules formalized (two-language verified, each reproducing
   its source's stated KW values), measured in one run. Three headline findings. **(1) A new strongest
   discriminator — with the data-likeness caveat stated plainly:** Schulz's S25–28 trigram configuration
   — the scoreboard row `ccn4`, id named here since 2026-08-02 so this verdict is findable by the row's
   identifier and not only by its description
   (2011/2016: four consecutive stations sharing the dui top trigram, bottoms = the four "right" trigrams
   in order) holds in 2×10⁻⁸ of the population (×5×10⁷) — 2.4 orders beyond the previous champion (×5×10⁷ vs ×2×10⁵ = ×250; corrected 2026-08-01 from "three orders"). Like
   Cook's exact level-3 positions, this is a highly *specific* configuration: its registry classification
   is data-like rather than principled, and it is reported as a measured property, not promoted. The
   exception-co-location meta-rule `ccn8` (both Schulz rules' violation sets sharing the locus S25/26) ⚠ **[CORRECTED 2026-08-28 — "confined" overstates the code, which requires only that the two violation sets SHARE the locus. Measured on King Wen: CC-A2 = {25,26} (confined), but R-S2 = {11,13,14,25,26,32} (not confined). `reg_ccn8`'s predicate is `set(v_a2)=={25,26}` and `{25,26} <= v_s2`, and its docstring already says "share the locus". The 2.6×10⁻⁷ population figure comes from the correct predicate and is UNAFFECTED. See CORRECTIONS.md]** measures 2.6×10⁻⁷
   (×3.8M) — the anomaly locus itself is population-rare. **`ccn8` carries no data-like/principled
   verdict**, here or anywhere in the suite; nor do the remaining sampled rows of the §3 table. That is
   stated rather than left implied: `d7` (2026-08-01) and `ccn4` were each classified only after being
   named individually, so an unclassified row is the default state of this scoreboard, not a residue. **(2) Eight literature rules are consequences of
   the constraint system — proven, not sampled (upgraded 2026-07-21)**: all eight rules that measure at
   1.0 of canonical mass (mmt4, p1c4, s1, s6, r3, r4, r5, c2 — including three consequences of
   [Radisic's](../documentation/CITATIONS.md#radisic2026) optimality structure) are now **theorems**. Each
   depends only on the unordered pair-partition, which C1 fixes, so each is constant on the *entire C1
   space* — a superset of the C1–C5 population, hence a fortiori equal to King Wen's value on every C1–C5
   ordering. Machine-checked in Lean 4 ([lean/C1RuleConstants.lean](../lean/C1RuleConstants.lean)); the
   r4/r5 threshold forms hold because the C1-fixed within-pair HD histogram {2:12, 4:12, 6:8} (which is
   c2) sums to a total pairing cost of exactly 120 (= r4's ≤120 threshold, met with equality). Their
   zero-violation 2×10¹⁰-probe readings — previously reported only as "empirically forced to the
   estimator's precision", since sampling cannot distinguish mass 1 from mass 1−ε — now validate the
   instrument end-to-end rather than carry the claim. A separate, additional analytic theorem — the no-5
   rule's implication chain, behind [McKenna's](../documentation/CITATIONS.md#mckenna-mckenna1975) 3:1
   even:odd transition ratio, the first literature rule proven forced — is distinct from these eight and
   stands unchanged. Several more rules are near-forced (0.95–0.9998); those remain sampling results. **(3) The xiaoxi-placement row `d7` is DATA-LIKE, and its "maximality" is
   an artefact of its own specification (classified 2026-08-02; this replaces the earlier reading, which
   called KW's 8/8 "a genuine extremal property").** `d7` counts how many of the 12 xiaoxi (waxing-waning)
   hexagrams occupy eight *hard-coded slots* — 0-based 18, 19, 22, 23, 32, 33, 42, 43. Those eight are
   verifiably eight of King Wen's own twelve xiaoxi slots (KW's full set is 0, 1, 10, 11, 18, 19, 22, 23,
   32, 33, 42, 43; the four omitted are pairs #1-2 and #11-12). So the statement carries **eight borrowed
   degrees of freedom**, KW's 8/8 is guaranteed by construction rather than discovered, and 8 is the
   functional's range ceiling — a count over eight slots — not an empirically located population maximum.
   Slide the same eight-slot window by 1–5 positions and KW scores 4, 0, 1, 2, 1: the slot choice is doing
   all of the work. Under [METHODS](METHODS.md) §"Data-like vs principled" (≥1 borrowed dof → data-like)
   the row is data-like, and the 1.7×10⁻⁴ mass is priced as specification, not as evidence of design.
   **Attribution is also split, and narrowed.** What [Drasny](../documentation/CITATIONS.md#drasny2007)
   and [Schulz & Cunningham](../documentation/CITATIONS.md#schulz1990-motifs) state is the *identification*
   of the xiaoxi — which hexagrams they are, by monotone yang-line accumulation. That is a claim about
   bit-patterns, true of every ordering, so it is not an ordering constraint and has no rarity. The
   positional predicate measured here is **this suite's own formalization**, and is classified as ours;
   Drasny's group B is defined by hexagram structure, not by King Wen slot indices. (Schulz's separate
   xiaoxi *placement* rule — the 1/13/25 trisection — is a distinct row, `rs1`, and is **not** classified
   by this entry; it needs its own dof count.) `d7` is
   retained as a measured row, not promoted, and no design inference rests on it. Full table (fraction of canonical mass; KW satisfies each at its
   measured level by construction of the threshold forms; the eight **1.0 (theorem)** entries are the
   proven C1 constants of (2) — exact by theorem, not estimates): rs1 6.6×10⁻⁴ · rs2 3.0×10⁻³ (max seen 26/26 vs
   KW 20) · ccn1 3.4×10⁻⁵ · ccn2 1.5×10⁻³ · ccn3 6.6×10⁻⁶ · **ccn4 2×10⁻⁸** (*data-like* — see headline 1) · ccn6 0.427 · ccn7 1.1×10⁻³
   · **ccn8 2.6×10⁻⁷** · c2011n1 <10⁻⁹ (0 hits) · c2011n2 5.9×10⁻⁵ · c2011n4 1.1×10⁻² · mmt3 0.953 (min
   Gray-transitions seen 0 vs KW 4) · mmt4 **1.0 (theorem)** · mmt5 0.9998 · mmt6 0.993 ·
   p1c4 **1.0 (theorem)** · p2c3 6.7×10⁻² · p2c4 1.0×10⁻³ · p2c5 2.3×10⁻³ · p2c6 4.1×10⁻⁴ · d4 5.7×10⁻⁴
   · d7 1.7×10⁻⁴ (KW 8/8 — *data-like*: 8 borrowed dof, 8 is the range ceiling; see headline 3) · s1 **1.0 (theorem)** · s6 **1.0 (theorem)** · m2 8.0×10⁻² ·
   r3 **1.0 (theorem)** · r4 **1.0 (theorem)** · r5 **1.0 (theorem)** · c1 6.6×10⁻² (min deviation seen
   4 vs KW 24) · c2 **1.0 (theorem)**. Wrap-distance finals: d1 = 17.5%, d3 = 65.2%, d5 = 17.4% of
   the full space (the 560T slice contains zero d5 records in 10.5B — see [TR-7](TR7_CIRCULAR_READING.md) / [CIRCULAR_KING_WEN.md](../documentation/CIRCULAR_KING_WEN.md)).
   **Deep-tail caveat (travels with the smallest figures; details in [METHODS.md](METHODS.md)):** below
   ~10⁻⁷ per-probe hit rates the estimator's CIs degrade (low effective sample size, right-skewed
   weights) — read ccn4 (2×10⁻⁸) and ccn8 (2.6×10⁻⁷) as order-of-magnitude figures, not point
   estimates, and c2011n1's "<10⁻⁹ (0 hits)" as sampling starvation, not a bound.
4. **SAT-decided exactness: the precursors and the 3-edit events.** Population fractions are statistical; a
   SAT layer (`sat.py`, encoding derived from solve.py's constraint definitions, external kissat solver,
   DRAT certificates) adds *exact* decisions. (a) **Moore's conjectured fully-compliant ordering exists —
   here is one:** an explicit C1–C5-valid sequence satisfying his 2005 parity rule 18/18 AND his 1989
   rhythm rule with 0 breaks, differing from King Wen only by swapping pairs 22↔23 (his anomaly) and
   flipping two within-pair orientations (pairs 8 and 23), complement-distance sum 776 — C3 at the same
   ceiling as KW. Moore (1989) judged the bare 22/23 swap "too simplistic" because it leaves the rhythm
   broken; the two orientation flips complete the repair. (b) **The minimal repair is exactly 3
   slot-edits** — SAT-decided: no ordering within 2 slot-edits of KW achieves joint compliance (UNSAT, a
   fortiori under C3), and 3 suffices. (c) **Schulz's gender rule** ([Schulz 1990](../documentation/CITATIONS.md#schulz1990-motifs); exception first noticed
   by Zhu Yuansheng, 13th c.; strict form had 0 hits in 36M samples — *flagged 2026-08-01 as unsourced:
   no null, sampler or source run was ever recorded with that figure, and it is not consistent with the
   suite's later measurement of the strict gender rule at ≈10⁻⁶ of canonical mass
   (`reports/evidence/f11/RESULTS.md`, RUN C2) — if those 36M draws were canonical, that mass predicts
   ≈36 hits, not 0; treat the strict form as population-rare at order 10⁻⁶ and the 36M figure as
   withdrawn pending a stated null*) is perfectly satisfiable, and its
   minimal repair is ALSO exactly 3 edits — a swap of the adjacent pairs at slots 21/22 (= class positions
   25/26, precisely the Zhu Yuansheng/Schulz exception locus) plus one orientation flip. (d) **The grand
   unified precursor exists:** one ordering satisfies ALL THREE literature rules perfectly — Moore's 2005
   parity (18/18), Moore's 1989 rhythm (0 breaks), and Schulz's 1990 gender rule (0 violations) — again
   C1–C5-valid at C3 = 776. (e) **The grand minimal repair is exactly 3 slot-edits** (a fortiori ≥3; 3
   achieved): an orientation flip at slot 7 and an adjacent-pair swap at slots 21/22. The three rules'
   minimal repairs are not merely equal-sized — they are *compatible*: a single 3-edit event completes all
   three at once. If any corruption/precursor reading of the literature is right, the deviation was one
   small event, and every independently-observed anomaly (Moore's pairs 22–23, Zhu Yuansheng/Schulz's
   stations 25–26) is a shadow of it. Standard caveat: witnesses produced by a solver seeded with King
   Wen's variable order are biased toward KW-like repairs; minimality (3) is exact, the specific repair
   need not be unique. Also SAT-verified: the parity-alternation theorem over the full space (third
   independent verification after the prose proof and the Lean-checked lemmas — "≤14" and "≥16" both
   UNSAT under C1+C2+C4+C5); joint-strict population size (pinned-walk estimate) ≈1.13×10²⁹ canonical orderings (95% CI [1.09, 1.17]×10²⁹; relerr 1.66%) ⚠ **[CORRECTED 2026-08-28 — the ±4.7% was a PREREGISTERED ANCHOR TOLERANCE BAND, not an error bar: `reports/evidence/f11/compute_f11_bf.py:85` names its check "Moore-joint size outside the +/-4.7% anchor band". The published 1.13×10²⁹ comes from `reports/evidence/r11/r11_moore_strict.out` (`est=1.131036e+29`, 95%CI [1.0942e+29, 1.1679e+29], relerr 1.66%), NOT from `f11_runB.out`, which reports 1.16583e29. See CORRECTIONS.md]**. The encoder round-trip validation's first solver model, pleasingly, is King Wen
   itself.
5. **The conflict theorem (2026-07-04, SAT-decided, drat-trim verified): perfection was never available.**
   The literature's four strongest rules are **jointly unsatisfiable**: no C1∩C2∩C4∩C5-valid ordering achieves
   Moore's 2005 parity (18/18), Moore's 1989 rhythm (0 breaks), the Schulz gender rule (0 violations), and
   the Schulz S25–28 trigram configuration simultaneously (UNSAT under C1+C2+C4+C5, hence a fortiori with
   C3; certificate independently verified). The pieces fit together sharply: King Wen satisfies the
   trigram configuration **exactly**, and misses the other three by (16/18,
   2 breaks, 2 violations) ⚠ **[CORRECTED 2026-08-28 — "minimal" is UNSUPPORTED: `reports/evidence/f11/f11_runA.out` carries `f11_hist 1 1 0` and `f11_hist 2 1 1`, both componentwise better than KW's `2 2 2` with nonzero mass, and the histogram is not CC-N4-conditioned so no extremal check exists. See CORRECTIONS.md]**; the 3-edit grand precursor satisfies those three **perfectly** — and breaks
   the trigram configuration. Both cannot be had: **the rules compete**, and any ordering must choose
   which to satisfy. Consequence for the corruption hypothesis: an "uncorrupted precursor" perfect under
   the literature's full rule inventory **never existed** — the corruption reading survives only in the
   restricted sense (perfect under Moore's two rules alone, breaking the trigram structure KW keeps). King
   Wen's profile now reads naturally as a **trade-off position**: exact on one strong rule, missing the
   other three by 2 each — a measured margin, with no extremal check (see the correction marker
   earlier in this paragraph; "minimally imperfect" asserted the same unsupported extremal property and is withdrawn here
   too). All four rules are KW-derived — selected because King Wen exhibits them, even
   where their form is general — so King Wen
   sitting near their joint Pareto frontier is expected rather than an efficiency result; the
   ~1-in-25-million figure **describes** how population-atypical that joint profile is under KW-fitted
   rules, and is not a measure of design efficiency (no arbitrary-rule-bundle baseline exists to read it
   against). *(Sourcing flag, added 2026-08-01: the ~1-in-25-million figure (≈4×10⁻⁸) is carried from the
   v1.14 pass with **no derivation, probe count, CI or verification command anywhere in the repo**, and it
   is not reconstructible from the published masses; it also sits below the ~10⁻⁷ per-probe hit rate at
   which §3's deep-tail caveat says to read figures as order-of-magnitude only, so the two significant
   figures are unearned. Treat it as an unreproduced figure until a regeneration command is published;
   what would settle it is a stated joint-profile predicate plus a run of
   `SOLVE_KNUTH_SCORE=1 ./solve --estimate-knuth <probes>` reporting its mass with a CI.)* The usual caveat travels with this: the trigram configuration is a
   data-like rule (highly specific); the theorem is about the literature's rules exactly as its authors
   stated them. Certificate chain: all four UNSAT proofs (alt-le-14, alt-ge-16, moore-strict-near-2,
   rc4-strict-near-2) plus the conflict-theorem CNF check `s VERIFIED` under drat-trim against regenerated
   CNFs (2026-07-03); the conflict encoding is two-way validated (ccn4-kwtest SAT, rc4-kwtest UNSAT).
6. **Attribution, lineage, and what is claimed.** Every rule is credited to its source, with lineage where
   it runs deep: the pair structure itself is attested to **[Yu Fan](../documentation/CITATIONS.md#yufan) (164–233 AD)** (pangtong/fandui, via Li
   Dingzuo); the 36-unit consolidation to **Lai Zhide (1525–1604)** (via [Schulz 1982](../documentation/CITATIONS.md#schulz1982); the earlier statement of the 8+28=36 *count* — not the consolidation — by Shao Yong (11th c.) is **confirmed first-hand as of 2026-08-27** and applied 2026-08-29 in [CITATIONS.md](../documentation/CITATIONS.md#shaoyong), superseding the "second-hand, unconfirmed" hedge recorded here 2026-08-21; the consolidation attribution to Lai Zhide is unchanged); the 18:18 split to
   **Zhang Xingcheng 张行成 and Zhu Xi 朱熹 (Song, 12th c.)** and **Hu Yigui (1247)** — attribution
   corrected 2026-07-30 per the [Li Shangxin 2008](../documentation/CITATIONS.md#li2008) first-hand
   pass (the prior credit was unsupported by Li's treatment; see CITATIONS.md §Classical sources) —
   modern treatment **[Hacker & Moore 2003](../documentation/CITATIONS.md#hacker-moore2003)**; the
   pair-positioning parity rule and rhythm rule to **Moore ([2005](../documentation/CITATIONS.md#moore2005), [1989](../documentation/CITATIONS.md#moore1989))**, building on the *Dazhuan*
   odd=Heaven/yang attribution; the gender/position-parity rule (measured at ×11,364 in the companion
   registry) originates with **Schulz 1990** — attribution corrected 2026-07-03 upon first-hand reading
   (Cook had been credited as primary) — elaborated by **Cook 2006**, its single exception first
   recognized by **Zhu Yuansheng (13th c.)** per [Schulz 2018](../documentation/CITATIONS.md#schulz2018) fn. 42; the trigram configuration to
   **Schulz 2011/2016**; further rules to **McKenna & Mair 1979**, **Drasny**, and **Schöter**. McKenna &
   Mair 1979 also retain clear priority for the idea driving this methodology: evaluating King Wen against
   explicitly constructed alternatives rather than by inspection alone. ROAE's contribution is
   formalization + measurement (+ the SAT decisions), to our knowledge the first population-scale
   measurement of this inventory — corrections welcome via CITATIONS.md. Honest closing caveats: rule
   classes differ in kind — forced rules explain nothing beyond C1–C5; data-like rules (exact
   positions/configurations, e.g. ccn4, Cook's level-3 positions, and d7 — classified 2026-08-02, §3
   headline 3) carry rarity that is partly specification, not principle; none of these rules, singly or jointly, approaches uniqueness (the full
   C1–C7 space holds ≈5.2×10³¹ orderings). Accordingly **none is promoted into the formal constraint
   system**; they are measured properties of King Wen's position in the population, with
   description-length and attestation recorded for each (see [TR-9](TR9_PRICING_THE_CONSTRAINTS.md)).
7. **The orientation layer, measured (2026-07-05; re-scoped + pair-only re-check 2026-07-26).**
   Everything above concerns which pair goes where. A
   final pre-registered battery measures the layer the literature has almost entirely ignored — **which
   member of each pair comes first**. Of the 32 within-pair orientation choices, slot 0 is fixed by
   **C4's definition** *(re-scoped 2026-07-26: the earlier text said "forced (Theorem 6)" — that
   theorem is retracted as false; C4's orientation is definitional — this project's convention, not a
   classical attestation, since the Xugua attests that the {Heaven, Earth} pair opens and not the
   order within it (narrowed 2026-09-01); and complementation is an exact symmetry of C1∩C2∩C3∩C5 — see [lean/KingWen.lean](../lean/KingWen.lean)
   and CLAIMS_DECIDED's corrections ledger)*, leaving 31 binary choices; conditioning on King Wen's
   pair sequence, exact enumeration shows the constraints leave a valid orientation **fiber of exactly
   1,720,320 vectors** — the **C4-oriented fiber**, the battery's frozen dispositive null
   (= 3·5·7·2¹⁴ ≈ 2^20.7 — far below the naive 2³¹; 30 of the 31 bits vary somewhere in the fiber, and
   slot 30, hexagrams 61/62, is the only additionally forced bit). Under the **pair-only reading of
   C4** (opening pair {0, 63}, orientation free) the fiber is exactly **2,703,360 vectors**
   (1,720,320 opening (63, 0) + 983,040 opening (0, 63)); the full battery was re-run on that larger
   fiber on 2026-07-26 — the seven null verdicts and two of the three forced rows survive unchanged,
   and the changes are confined to rows 8 and 11 (detailed below). This already corrects our own earlier
   gloss that orientation "appears to be a free choice at each pair": the freedom is real but coupled and
   ~20.7 bits, not 31. Eleven functionals were frozen before measurement ([Bonferroni](../documentation/CITATIONS.md#bonferroni1936) N = 11; two-sided
   atom-inclusive p; the exact fiber is the dispositive null; all results published regardless of
   outcome), each anchored to a named author's idea:

   | # | Functional (source) | KW | Exact fiber p (two-sided) | Verdict |
   |---|---|---|---|---|
   | 1 | Correct-line lead — Cook 2006's `sO` orientation stage | 15/32 | 9.499×10⁻² | null |
   | 2 | Rising count — Moore 1989 (reproduces his own 10R/8F) | 10/18 | 0.8144 | null |
   | 3 | Rising/falling alternation — Moore 1989 rule K-8 | 10/17 | 0.6972 | null |
   | 4 | Yang-heavier member leads — the *Dazhuan*/Xici yang-precedence reading, via Cook 2006 (Schulz 1990 quotes the Xici passage but his own placement statement runs the opposite polarity — the negative-balance unit leads; at 2/4 the functional is polarity-symmetric, so the verdict is identical under either reading) | 2/4 | 0.6667 | null |
   | 5 | Order-true mirror links — [Davis 2012](../documentation/CITATIONS.md#davis2012) | 7/12 | 0.8214 | null |
   | 6 | Binary-larger member leads — the [Shao Yong](../documentation/CITATIONS.md#shaoyong) / [Leibniz 1703](../documentation/CITATIONS.md#leibniz1703) axis | 17/32 | 1.0 | null |
   | 7 | Orientation-string alternation — [Chan 2026](../documentation/CITATIONS.md#chan2026)'s anti-habituation axis, transported | 13/31 | 0.3732 | null |
   | 8 | Greedy smooth entry — McKenna & McKenna 1975 | 23/31 | constant on fiber | **forced** |
   | 9 | Placement of the unique between-pair 6 — McKenna & McKenna 1975 | 18 | constant on fiber | **forced** |
   | 10 | Span of the two between-pair 1s — McKenna & McKenna 1975 | 4 | constant on fiber | **forced** |
   | 11 | **Nuclear orientation rule — Van den Berghe c. 1999–2002** | **29/30** | **1.3951×10⁻⁵**† | **fiber maximum (fitted description)** |

   † The row-11 p-values are **descriptive, not graded** against the family or global observable bars:
   Van den Berghe's functional was fitted to King Wen, so a p-value on the object it was fitted to carries
   no design inference — the same discipline applied to the D-B1 fitted template in [TR-10](TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) §3b.
   The numbers are recorded for completeness; see the scoping paragraph below.

   *Scope of the table (re-scoped 2026-07-26):* all tabulated p-values are exact over the
   **C4-oriented fiber** (N = 1,720,320) — the battery's frozen null. On the pair-only-C4 fiber
   (N = 2,703,360) the 2026-07-26 re-run leaves every null verdict null (largest shift:
   row 1, two-sided p 9.499×10⁻² → 9.171×10⁻²; row 4 moves to 0.982, row 7 to 0.347 — all far from
   any gate), rows 9–10 stay forced, row 8 becomes slot-0-determined (below), and row 11's
   descriptive values become P(X ≥ 29) = 30/2,703,360 = 1.1097×10⁻⁵ one-sided / 2.2195×10⁻⁵
   two-sided, with the fiber maximum rising to 30 (below).

   Rows 9–10 join the forced class of §3: two of McKenna's difference-wave statistics turn out to be
   **constant across the entire pair-only fiber** (all 2,703,360 valid orientation vectors, both
   opening orientations — re-checked 2026-07-26) — given the pair sequence they measure constraint
   geometry, not an arranger's orientation choice. Row 8 (greedy smooth entry) is constant at 23 on
   the C4-oriented fiber but takes exactly the value 24 on every reversed-opening vector: it is a
   deterministic function of the single C4-orientation bit — still no orientation freedom expressed
   anywhere in the fiber, but "forced" only relative to the defined opening *(re-scoped 2026-07-26;
   the earlier text grouped it with rows 9–10 as fiber-constant, which was true only of the
   C4-oriented fiber)*. Rows 1–7: seven literature-anchored orientation ideas,
   from Cook's correct-line stage (the one explicit within-pair orientation rule in the modern academic
   literature) through Moore's rising/falling system (our count reproduces his published 10R/8F exactly)
   to the classical yang-precedence reading, are all **null** — dead-typical of the choices actually
   available. The orientation layer is not decorated with weak echoes of the ordering rules; it is silent
   on every axis but one.

   **The one non-null axis: a fitted description at the fiber ceiling — Van den Berghe's nuclear rule.**
   Around the turn of the millennium, D.H. Van den Berghe — working independently and
   publishing on the open web (c. 1999–2002) — proposed a nuclear-hexagram decision procedure predicting
   which member of each pair comes first, and reported that King Wen follows it in 29 of the 30 pairs it
   addresses, with one declared exception (hexagram pair 3/4). Both halves of his claim verify exactly —
   and exact enumeration sharpens both in his favor, **on the C4-oriented fiber** *(scope made explicit
   2026-07-26)*. King Wen's agreement count of 29 is the **maximum
   attained anywhere on the C4-oriented fiber**: exactly **12 of 1,720,320** vectors reach 29 (King Wen
   among them; exact P(X ≥ 29) = 6.9754×10⁻⁶ one-sided), and **none reaches 30** — given the received
   opening orientation, which C4 fixes by definition, perfect agreement is
   unattainable, so his declared exception is not a blemish his rule tolerates but a **forced** feature:
   no valid orientation of King Wen's pair sequence *keeping the (63, 0) opening* satisfies all 30
   predictions. The 2026-07-26 pair-only re-check locates where the impossibility lives: on the
   **pair-only-C4 fiber** (2,703,360 vectors, both opening orientations) exactly **2 vectors attain
   30/30** — both open (0, 63), and the minimal one is King Wen with precisely the opening pair and
   pair 3/4 (**his own declared exception**) orientation-reversed (the second additionally reverses the
   final pair); fiber-wide P(X ≥ 29) = 30/2,703,360 = 1.1097×10⁻⁵ one-sided. The exception is therefore
   forced **by the received Heaven-first opening**, not by the pair geometry alone — the received
   text's one deviation from his rule is exactly what C4's definitional orientation makes unavoidable.
   That clarifies the
   rule's standing — under the received opening it is not "almost perfect"; it is **perfect up to
   impossibility**. The unconditional
   population concurs: zero mass at ≥ 29 in ≈3.6×10⁶ weighted **canonical** (C1–C5) leaves
   (2×10⁹-probe run, `leaves_canonical_C1C5` hit rate 0.0018 in `reports/evidence/f5/f5_tier1.out`).
   *(Corrected 2026-08-01: this read "≈2.9×10⁷ weighted valid-sequence leaves", which is the C3-free
   `leaves_C1C2C4C5` count — an 8× overstatement of the sample the F5 scorer actually saw. `score_f5`
   runs inside the C3 gate and its masses are normalised by canonical mass, so the canonical count is the
   right depth. Note also that a raw leaf count is not the effective sample size for a weighted estimator:
   METHODS defines n_eff = 1/relerr², which is far smaller.)*
   Credit where it is due: Van den Berghe **found** this regularity, a quarter-century ago and without
   any of this machinery; ROAE's contribution is to operationalize it, enumerate its null exactly, and
   locate it in the population — the finding is his, the measurement is ours. It is of a piece with his
   work overall: our audit of his web-published reconstruction verified 17 of 19 checkable claim-groups
   exactly, with his two self-declared exceptions falling precisely where computation finds the misfits.

   The honest scoping travels with the result — and it is decisive about how the number may be read.
   Van den Berghe derived the rule *from* King Wen, so King Wen's placement on the rule's own scale is a
   **fitted-description property, not an evidential test**: a p-value on the object a statistic was fitted
   to is descriptive, and per the standing extraction-circularity policy (the same discipline applied to
   the D-B1 fitted template in [TR-10](TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) §3b) **no family- or
   global-ledger p-grading is attached to it.** What the exact fiber establishes descriptively is sharp:
   King Wen's agreement count of 29 is the **maximum attained anywhere on its 1,720,320-vector
   C4-oriented orientation
   fiber** (exactly 12 vectors reach 29, none reaches 30), so the described configuration sits at that
   fiber's
   ceiling and carries ≈17.1 bits of atypicality (≥ ~14 after discounting the rule's ~2–3 fitted degrees
   of freedom) out of the layer's ≈20.7-bit budget. *(Discount caveat, added 2026-08-01: that residual
   discounts a fitted dof at exactly **1 bit each**, which is asserted, not derived, and holds only when
   the fitted choice is binary. The dof in question is a window over pair slots (`solve.py`: the
   64-generator leads iff the pair lies within positions 17..54), and naming its two endpoints under a
   uniform code costs ≈9.0 bits if they are chosen among the 32 pair slots (log₂ C(32,2) = 8.95) or
   ≈11.0 bits among the 64 hexagram positions (log₂ C(64,2) = 10.98) — so an MDL-consistent discount
   would leave materially less than ~14 bits. The counter-argument, that the window edges coincide with the two
   anti-symmetric special pairs and so cost less to name, is available but is nowhere made here. The
   ≈17.1-bit **undiscounted** figure is the exactly-enumerated one; the discounted residual should be read
   as a rough upper bound, not a measurement.)* On the pair-only-C4 fiber (2,703,360 vectors,
   re-checked 2026-07-26) King Wen sits one below the ceiling of 30 (attained only by the 2
   reversed-opening vectors described above; 30 of 2,703,360 vectors reach ≥ 29, ≈16.5 bits).
   That extremal placement is a real, exactly-enumerated
   fact about where the fitted description puts King Wen; it is **not** independent confirmation of a
   design rule, and no out-of-sample test is possible from the same document the rule was read off of.
   (For readers who want the raw statistic: the frozen two-sided C4-oriented-fiber value is 1.3951×10⁻⁵
   and the
   one-sided is 6.9754×10⁻⁶; on the pair-only fiber, 2.2195×10⁻⁵ and 1.1097×10⁻⁵ respectively; these
   are recorded for completeness but are **not** graded against the family
   or global bars, because the functional was fitted to the sequence being scored. The gauge-control
   flag — the statistic inverts, ~50× attenuated, under direction-reversing relabelings — is likewise
   reported as frozen, not adjudicated.) The corpus gate runs clean but carries little weight:
   Mawangdui scores 1 — below the whole 2×10⁹-probe sampled range [2, 28] of `vdb_nuc` over C1–C5-valid
   leaves — and [Jing Fang](../documentation/CITATIONS.md#jingfang) scores 6, near that range's bottom;
   both are far below King Wen's 29.
   *(Scope corrections, 2026-08-01. **(i)** Neither control is a member of that population — SOLVE.md
   records that Mawangdui and Jing Fang **fail both C1 and C3**, and v1.8 below notes Mawangdui also
   fails C2 — so "below the entire sampled range" and "population-extreme depth" are not probability
   statements about them; their low scores are largely guaranteed, since any non-C1 ordering scores low on
   a pair-defined rule (Mawangdui, for instance, scores 0 on `bpd_six_pos`, a functional that is constant
   at 18 across every vector of King Wen's fiber — row 9 above). **(ii)** The earlier wording read the gate as ruling out a "classical-norm explanation".
   For a functional derived from King Wen that inference is weak: a decision procedure read off one
   sequence is expected to score low on any other, under a design hypothesis and an accident hypothesis
   alike, so the gate has little discriminating power — the same reason
   [TR-10](TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) §3b attaches neither a p-value nor a design inference to
   the KW-fitted D-B1 template, reading its population extremity as "diagnostic of the same thing:
   extraction, not design". The gate is retained as a sanity check that the statistic is not trivially satisfied by any
   received ordering; it is not independent support.)* *(Corrected 2026-07-05: the Mawangdui control was
   originally reported as 14, "dead central, p ≈ 0.97" — computed on an erroneous Mawangdui array;
   the corrected array ([Shaughnessy 2022](../documentation/CITATIONS.md#shaughnessy2022), Table 11.2) makes the gate verdict stronger, not weaker.
   All 11 F5 functionals on the corrected Mawangdui: 15, 19, 11, 0, 4, 7, 8, 12, 0, 1, 1 in f5_names
   order, two-language verified.)* Per the frozen
   pre-commitment, nothing here promotes into the constraint system; it is a measured property of King
   Wen. Raw outputs, the exact-fiber script, and exercised reproduction commands (the fiber analysis
   reruns byte-identically in ~11 s): [evidence/f5/](evidence/f5/README.md). The 2026-07-26 pair-only
   re-check reuses that bundle's exact enumeration + scoring machinery seeded at **both** slot-0
   orientations (validity + scoring gated on 400 samples against the bundle's independent
   ground-truth scorer, including 200 reversed-opening samples; the two 30/30 vectors additionally
   verified by direct `vdb_nucorient` scoring); its instrument and raw output join evidence/f5 in a
   follow-up commit after operator review of this retraction.

## Figure

![Grouped bar chart of the four conflicting rules: King Wen misses Moore's 2005 parity rule by 2 (16/18), Moore's 1989 rhythm rule by 2 breaks, and Schulz's 1990 gender rule by 2 violations while satisfying the Schulz S25–28 trigram configuration exactly; the grand unified precursor is perfect (0) on the first three and violates the trigram configuration — no C1∩C2∩C4∩C5-valid ordering achieves zero on all four.](figures/fig_tr1_rules_tradeoff.png)

*The conflict theorem's trade-off (§5). King Wen (red) misses the three graded rules by 2 each ⚠ **[CORRECTED 2026-09-01 — this caption read "by the minimal measured margins (2 each)"; "minimal" is UNSUPPORTED on the same grounds §5 gave on 2026-08-28: `reports/evidence/f11/f11_runA.out` carries `f11_hist 1 1 0` and `f11_hist 2 1 1`, both componentwise better than KW's `2 2 2` and with nonzero mass, and that histogram is not CC-N4-conditioned, so no extremal check exists. The rendered image above still carries the old wording: its generator `viz/report_figures.py` is outside this pass's file scope and has not been regenerated — the caption, not the image, is authoritative until it is.]** and keeps the S25–28 trigram configuration exactly; the grand unified
precursor (green, 3 slot-edits from KW) perfects all three graded rules and breaks the trigram
configuration — which, being a specific binary configuration, has no graded miss count. The jointly
UNSAT result (drat-trim-verified) says no C1∩C2∩C4∩C5-valid ordering can reach zero on all four axes at once.
All values are the reports' stated numbers; generated by
[`viz/report_figures.py`](../viz/report_figures.py); [SVG](figures/fig_tr1_rules_tradeoff.svg).*

## Verification Guide

⚠ **`ulimit -s unlimited` is REQUIRED for every `--estimate-knuth` command in this document.** Under the default 8 MB stack the estimator does not start: `main` allocates a ~7.23 MB frame and `estimate_tree_knuth` a further ~1.02 MB (since 2026-08-21 the binary refuses with an actionable message; previously a bare SIGSEGV). *(Added 2026-08-21, an execution-lane finding — `scripts/exec_lane.sh` executes every documented command on a default environment; the same-day warning propagation (`1e4bd04a`) covered the four estimator guides but missed this file.)*

- Population fractions, both waves: `SOLVE_KNUTH_SCORE=1 ./solve --estimate-knuth 20000000000`
  (consistency check vs the total-space size *estimate* in documentation/SEARCH_SPACE_SIZE.md, agreement
  0.03% — same estimator family, so this is consistency, not independent validation; cf. v1.18)
- Per-rule registry, formalizations, attributions, KW-value reproduction: `solve.py --registry-verify`;
  [documentation/LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md); documentation/CITATIONS.md §Attributed candidate
  rules
- Moore joint witness: `python3 sat.py --witness moore-strict` (explicit sequence in
  LITERATURE_RULES_POPULATION_TESTS.md §SAT-decided, C3 = 776)
- Grand precursor witness: `python3 sat.py --witness grand-strict`
- Joint-strict population size (§4, ≈1.13×10²⁹, 95% CI [1.09, 1.17]×10²⁹) ⚠ **[CORRECTED 2026-08-28 — the ±4.7% was a PREREGISTERED ANCHOR TOLERANCE BAND, not an error bar: `reports/evidence/f11/compute_f11_bf.py:85` names its check "Moore-joint size outside the +/-4.7% anchor band". The published 1.13×10²⁹ comes from `reports/evidence/r11/r11_moore_strict.out` (`est=1.131036e+29`, 95%CI [1.0942e+29, 1.1679e+29], relerr 1.66%), NOT from `f11_runB.out`, which reports 1.16583e29. See CORRECTIONS.md]**: `SOLVE_KNUTH_SCORE=1 SOLVE_KNUTH_R11_HIST=1
  SOLVE_KNUTH_MOORE_STRICT=1 SOLVE_THREADS=64 ./solve --estimate-knuth 20000000000` (pinned
  strict-Moore walk; flags documented in [SOLVE_C_CLI.md](../documentation/SOLVE_C_CLI.md) §ENVIRONMENT;
  archived instance: reports/evidence/r11/r11_moore_strict.out — the run the published figure comes
  from, and its own first four lines record the invocation: `STRICT-MOORE walk ACTIVE`, `R11 8-axis
  joint violation histogram ACTIVE`, `attributed-rule scoring ACTIVE`, `20000000000 probes, 64
  threads`. Probe **and** thread count are both load-bearing: PRNG seeds are fixed constants, so a
  re-run reproduces this output identically only at the same (probes, threads) —
  [METHODS.md](METHODS.md). The `SCORE`/`R11_HIST` flags are report-only additions carried by the
  archived run.)
- Minimal-repair UNSAT certificates (moore-strict-near-2, rc4-strict-near-2) + alternation-theorem
  certificates (alt-le-14, alt-ge-16): regenerate CNFs via `python3 sat.py --emit-cnf <name> f.cnf &&
  kissat f.cnf`; check archived DRAT certificates with drat-trim → `s VERIFIED` (all four, 2026-07-03)
- The conflict theorem: `python3 sat.py --emit-cnf grand-ccn4 f.cnf && kissat f.cnf` → UNSAT; encoding
  validation: ccn4-kwtest SAT, rc4-kwtest UNSAT
- Wrap-distance finals cross-reference: documentation/CIRCULAR_KING_WEN.md (TR-7)
- Orientation battery (§7), KW ground-truth gates: `./solve --f5-verify` (11/11) and `python3 solve.py
  --vdb-verify` (Van den Berghe rule, KW = 29)
- Orientation battery, exact fiber (dispositive): `cd reports/evidence/f5 && python3 f5_modec_fiber.py`
  (~11 s; rerun exercised 2026-07-05, byte-identical to the archived reports/evidence/f5/f5_modec_fiber.out)
- Orientation battery, population run: `SOLVE_KNUTH_SCORE_F5=1 SOLVE_KNUTH_F5_HIST=1 ./solve
  --estimate-knuth 2000000000` (archived instance: reports/evidence/f5/f5_tier1.out; flags documented in
  SOLVE_C_CLI.md §ENVIRONMENT)

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
| v1.2 | 2026-07-04 | Figures added |
| v1.5 | 2026-07-04 | Adversarial round 2 correction: conflict-theorem claims scoped to pairing-preserving orderings |
| v1.6 | 2026-07-04 | Reproducibility completion: joint-strict population estimate (§4, ≈1.13×10²⁹) given an explicit rerun line in the Verification Guide; its `SOLVE_KNUTH_MOORE_STRICT` flag documented in SOLVE_C_CLI.md; archived instance cross-referenced (reports/evidence/f11/f11_runB.out) |
| v1.7 | 2026-07-05 | New §7 "The orientation layer, measured": pre-registered 11-functional battery over the exact 1,720,320-vector orientation fiber (+ 2×10⁹-probe population run). Van den Berghe's nuclear rule (c. 1999–2002) shown to be the fiber maximum (12/1,720,320; his declared exception proven forced); three McKenna statistics forced; seven other literature axes null. Evidence bundle reports/evidence/f5/ with exercised reproduction |
| v1.8 | 2026-07-05 | **Erratum (Mawangdui corpus control):** the Mawangdui array used project-wide since 2026-04-06 was wrong (right octet membership; wrong octet order and within-octet order). §7's corpus-gate row recomputed on the corrected array (authority: Shaughnessy 2022, Brill, p. 50 + Table 11.2; discovered by the literature-audit cross-check): vdb_nuc 14 → 1, moving Mawangdui from "dead central" to the opposite-tail extreme — the KW-specificity verdict stands, strengthened. Note the authentic Mawangdui order *fails C2* (one 5-line transition at its Kan→Zhen octet seam). No §7 verdict flips |
| v1.9 | 2026-07-11 | Wording precision (no numeric change): the eight sampled-1.0 rules are now stated as "empirically forced" — 1.0 to the estimator's precision, no violating ordering in 2×10¹⁰ weighted probes — with only the analytically proven case called a theorem; "are THEOREMS"/"exactly 1.0" phrasing retired (sampling cannot distinguish mass 1 from mass 1−ε). Certified/proven results (conflict theorem, parity alternation, fiber-exact rows) unchanged |
| v1.10 | 2026-07-11 | §7 framing scope-down (no numeric change): the Van den Berghe result retitled from "The headline" to "The one non-null axis", led with its own fitted-description-at-the-fiber-ceiling scoping (imported from CLAIMS_DECIDED); the frozen-threshold miss, gauge-tie flag, and every number unchanged |
| v1.11 | 2026-07-11 | Global-ledger qualifier added to §7's notable verdict (clears the 91-observable global bar as well as the family correction; see METHODS §"Global observable ledger") — part of the suite-wide global multiple-comparisons accounting pass. **Superseded — annotated 2026-08-01:** §7 no longer contains a "notable verdict" and now states the opposite in three places, attaching *no* family- or global-ledger p-grading to row 11 because the Van den Berghe functional was fitted to King Wen. The ungrading happened between v1.11 and v1.20 (the v1.10 fitted-description scoping is its likely origin) but **no revision entry recorded it**, so this row misdescribed the report's own grading posture for three weeks. Recorded here rather than silently deleted |
| v1.12 | 2026-07-11 | Deep-tail caveat attached to the smallest quoted masses in §3's table (ccn4, ccn8 order-of-magnitude; c2011n1 starvation-not-bound) and hedged in the executive summary — the METHODS CI-degradation caveat now travels with the figures. No values change |
| v1.13 | 2026-07-11 | Styling: "THE CONFLICT THEOREM" sentence-cased throughout (here, LITERATURE_RULES_POPULATION_TESTS, certificates/README) — content, statement, and certificates unchanged |
| v1.14 | 2026-07-20 | **Baseline-calibration pass (adversarial-review F-45, F-30).** §5's "trade-off **optimum** … ~1-in-25-million efficient" restated as a trade-off **position**: all four rules are KW-descriptive, so King Wen sitting near their joint Pareto frontier is expected rather than an efficiency result, and the 1-in-25-million figure describes how population-atypical the joint profile is under KW-fitted rules rather than measuring design efficiency (no arbitrary-rule-bundle baseline exists to read it against). Executive summary's "forced" finding marked as **sampled** for seven of the eight claims, with the one proven case named — twenty billion weighted probes is evidence, not proof. No measurement changed |
| v1.15 | 2026-07-21 | **The eight forced rules are now theorems (sampled → proven).** All eight registry rules measuring at 1.0 (mmt4, p1c4, s1, s6, r3, r4, r5, c2) proven constant on the entire C1 space — a superset of the measured population, so every C1–C5 ordering inherits King Wen's value — machine-checked in Lean 4 ([lean/C1RuleConstants.lean](../lean/C1RuleConstants.lean); proof by Claude (Fable 5), independent recompile/re-verification by Claude (Opus 4.8)). Executive summary, abstract, and §3(2) reworded from "empirically forced (sampled)" to "proven forced (theorem)"; the eight 1.0 table entries marked "(theorem)"; the 2×10¹⁰-probe zero-violation readings reclassified as end-to-end instrument validation. Also fixes an accounting tangle: the batch's forced class is all **eight** listed ids (the prior text said "seven more" while listing eight), and the previously-proven case — the no-5 rule's implication chain behind McKenna's 3:1 even:odd ratio — is a **separate, additional** analytic theorem, not one of the eight. No measurement changed |
| v1.16 | 2026-07-26 | **§7 re-scope + pair-only fiber re-check (the "Theorem 6" retraction).** The forced-orientation "Theorem 6" is retracted repo-wide as FALSE (complementation is an exact symmetry of C1∩C2∩C3∩C5, machine-checked in [lean/KingWen.lean](../lean/KingWen.lean); C4's orientation is definitional, classically attested — see SPECIFICATION.md and CLAIMS_DECIDED's corrections ledger). §7 accordingly re-scoped: the 1,720,320-vector population is named the **C4-oriented fiber**; the pair-only-C4 fiber is 2,703,360 vectors (+983,040 reversed-opening), and the full 11-functional battery was re-run on it. Verdict deltas: rows 1–7 stay null; rows 9–10 stay fiber-constant on the larger fiber; row 8 (greedy_entry, 23) is constant per opening orientation (24 on every reversed-opening vector); row 11 (vdb_nuc): 29 remains the C4-oriented-fiber maximum, but **30/30 is attainable on the pair-only fiber — exactly 2 of 2,703,360 vectors, both opening (0, 63)**, the minimal one being KW with the opening pair and pair 3/4 (Van den Berghe's own declared exception) reversed; his exception is forced by the classical opening orientation, not by pair geometry alone. Descriptive p re-computed: P(X ≥ 29) = 1.1097×10⁻⁵ one-sided / 2.2195×10⁻⁵ two-sided on the pair-only fiber (C4-oriented frozen values unchanged). All frozen 2026-07-05 numbers stand within their (now explicit) C4-oriented scope |
| v1.17 | 2026-07-26 | **Headline-adjective + lineage-framing precision (round-2 audit, loops 4b F-5 and 4d F-C3).** Executive summary: "genuinely rare" → "extremely rare as stated", and abstract: "genuinely discriminating" → "discriminating as stated", with the data-like caveat (§3: the champion ccn4 figure is "partly specification, not principle") now carried in the headline sentences rather than only in the body; "eight centuries" scoped in the opening to the *testable design-rule* literature (Zheng Qiao ~1150) with the far older structural tradition (*Yi Zhuan*; Yu Fan, 3rd c. CE) acknowledged — TR-1 itself already attested both, the opening now says so. No number, verdict, or certificate changed |
| v1.18 | 2026-08-01 | **Estimator-language precision (Pass-2 fresh-eyes review, finding F10).** The executive summary / §1 phrase "self-validating the method" is corrected to "a consistency check within the same estimator family" — cross-run agreement of the Knuth estimator with itself is consistency, not independent validation; the *absolute* validation of the estimator is TR-11's exact full-scale anchors. No number, verdict, or certificate changed |
| v1.19 | 2026-08-01 | **Conflict-theorem scope retraction propagated (2026-08-01 cross-model calibration review).** TR-2 v1.18 (2026-07-30) retracted the theorem's pairing-preserving (C1-only) scope as **unearned** — the DRAT certificate establishes it at **C1∩C2∩C4∩C5** scope, because the shared CNF base fixes C2, C4 and King Wen's C5 transition multiset. TR-1's executive summary and the §5 figure alt-text still carried the retracted broader wording; both now read "C1∩C2∩C4∩C5-valid", matching TR-2 §4 and the identical figure's alt-text in TR-2 §5. **Correction to the record:** TR-2 v1.18's entry stated that "TR-1 and LITERATURE_RULES already carried the correct 'C1–C5-valid' wording" — for TR-1 that was not the case, so v1.18 recorded a propagation that had not happened. No certificate, measurement, or verdict changed; the theorem is stated at the scope its certificate proves |
| v1.20 | 2026-08-01 | **Order-of-magnitude correction (2026-08-01 cross-model calibration review).** §3 said ccn4's rarity is "three orders beyond the previous champion"; ×5×10⁷ against the previous strongest discriminator's ×2×10⁵ is a factor of **250 ≈ 2.4 orders**, not three. Corrected in place. No measurement or verdict changed |
| v1.21 | 2026-08-01 | **Statistical + ACH lens adjudication (lens sweep unit q-tr1-tr2-tr8-tr10).** Eleven verified defects corrected or flagged in place. **Numbers/inferences:** §2(d) Cook's final-pair anchor was priced against the 1/31 uniform-slot null and a mechanism the suite had already demoted — restated at the parity-forced 1/16 = 6.25% baseline with the contingent residual **×1.25** (TR-7 §"The anchors on the circle"; LITERATURE_RULES). §7's population concurrence quoted **≈2.9×10⁷** leaves — the C3-free `leaves_C1C2C4C5` count — where the F5 scorer runs inside the C3 gate and normalises by canonical mass; corrected to **≈3.6×10⁶** canonical leaves (8× overstatement), with a note that a raw leaf count is not n_eff. **Retracted wording still live:** the Abstract still read "trade-off **optimum**" twelve days after v1.14 restated it to "position" — it had survived every grep because the phrase spanned a line break; fixed, and the string is now registered in `documentation/RETRACTED_PHRASES.tsv` so gate 3 catches any recurrence. "Independently-established total space size" (abstract and §1) is the adjective v1.18's correction was about — the quantity is itself a Knuth estimate (METHODS status **estimate**, source TR-4 §3, the same estimator); now "previously-published … estimate". The Verification Guide still called the same comparison "self-validation", the exact word v1.18 replaced; now "consistency check". The identical construction in [TR-10](TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) §1 was corrected in the same pass; the one in LITERATURE_RULES_POPULATION_TESTS.md was left for a serialized cross-file pass and is **still outstanding**. **Caveats that were missing or false:** §1's "orientation-invariant rules unaffected" is true of a predicate's value and **false of the reported fraction**, which is fiber-size-weighted; corrected. §1 now also states that the KW-value gate constrains a formalization at one point only (rung 2, and the class has fired once — CRITIQUE's 14:2 correction), and that C2/C5/C3's ceiling make the C1–C5 **denominator** itself partly KW-fitted (stated in TR-8 §2, previously silent here). §7's corpus gate is rescoped: neither historical control is in the population (both fail C1 and C3), so "below the entire sampled range" is not a probability statement, and for a KW-fitted functional the gate has little discriminating power — no "classical-norm explanation" inference is drawn from it now (matching TR-10 §3b's treatment of D-B1). **Flagged, not guessed:** §5's ~1-in-25-million figure has no derivation, probe count or CI anywhere in the repo and sits below the deep-tail threshold it is quoted past — flagged unreproduced with the measurement that would settle it. §4's "0 hits in 36M samples" names no null or sampler and conflicts with the later ≈10⁻⁶-of-canonical measurement (evidence/f11 RUN C2) — flagged withdrawn. §7's 1-bit-per-fitted-dof discount is an assertion, not a derivation (the window's two endpoints among 32 pair slots cost ≈8.6 bits) — the undiscounted ≈17.1 bits is the enumerated figure. §2(b)'s 0.66× correlation ratio is published without an interval — direction retained, two-figure value hedged. **Revision-history integrity:** the v1.11 row claimed a global-ledger grading for §7 row 11 that the current text refuses in three places, with no entry recording the withdrawal; annotated rather than deleted. No measurement, certificate or theorem changed; two published numbers changed (the §7 leaf depth, the Cook baseline) and both are recomputations from archived evidence already in the repo |
| v1.22 | 2026-08-02 | **`d7` classified DATA-LIKE; the "genuine extremal property" reading retracted.** [METHODS](METHODS.md) §"Data-like vs principled" makes classification mandatory for a load-bearing constraint, and §3 headline 3 carried none — it called King Wen's 8/8 on xiaoxi placement "a genuine extremal property, one of very few axes where KW attains the boundary". Measured: `reg_d7`'s eight hard-coded slots (0-based 18, 19, 22, 23, 32, 33, 42, 43) are a **subset of King Wen's own twelve xiaoxi slots** (0, 1, 10, 11, 18, 19, 22, 23, 32, 33, 42, 43), so the statement borrows **eight** degrees of freedom, KW's 8 is forced by construction, and 8 is the functional's **range ceiling** — a count over eight slots — not a located population maximum; sliding the same window by 1–5 gives KW 4, 0, 1, 2, 1. Headline 3 rewritten to the data-like verdict, the table row annotated, and `d7` added to §7's data-like examples. **Attribution narrowed**: Drasny and Schulz & Cunningham are credited for the *identification* of the xiaoxi (a bit-pattern claim, constant on every ordering, hence not an ordering constraint); the positional predicate is this suite's own formalization. This is consistent with the suite's own private R11 axis design, which had already placed the same axis (`g8`) in its **data-like** tier while this report called it extremal. The 1.7×10⁻⁴ mass is unchanged and `d7` is retained as a measured row; it was never promoted, and no verdict elsewhere rested on it. `solve.py`'s `reg_d7` docstring records the classification and the split attribution — **behaviour unchanged**: `--registry-verify` still reports `reg_d7: 8 OK`, 31/31. **Revision-history integrity (2026-08-02):** this row was first published as a SECOND `v1.21`, inserted above the existing v1.21 and dated a day later, leaving two rows with the same number and the `*(current)*` marker on the older one. Renumbered to v1.22 and moved below v1.21 so the history ascends; the 2026-08-01 row keeps v1.21, so every external citation of "TR-1 v1.21" still resolves to the row it was written about |
| v1.23 | 2026-08-02 | **The `ccn4` data-like verdict was findable only by description, not by its row id (hardening item C1).** §3 headline 1 has classified Schulz's S25–28 configuration as data-like since 2026-07-03, but never wrote the scoreboard id `ccn4` next to it — so the 2026-08-01 sweep that concluded `d7` was "the last unclassified load-bearing row" worked by matching id tokens and could not see it. The most-cited row on the board (2×10⁻⁸, the strongest discriminator) was carried as unclassified by that sweep's own instrument. The id is now named at the verdict, in this report and in [LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md), and the §3 mass listing carries the verdict inline as `d7`'s already does. **No classification changed and none was added**: `ccn8` and the remaining sampled rows carry no data-like/principled verdict, which §3 now states outright instead of leaving it to be inferred from silence. No figure, mass, theorem or scope changed |
| v1.24 | 2026-08-06 | **18:18-split attribution correction propagated (fix-landing pass, task #157).** The 2026-07-30 correction (CITATIONS.md: the classical 18:18 hexagram-split credit is Zhang Xingcheng 张行成 + Zhu Xi 朱熹 per the Li Shangxin 2008 first-hand pass, in which the previously-credited Zheng Qiao does not appear — attribution corrected 2026-07-30) had reached the bibliography but not this report's live text. Four sites updated: the executive summary's "begins with" clause, the abstract's lineage opening, the §2 rule-table row, and §6's bolded credit line (which now carries the dated correction note in the same style as the Schulz 2026-07-03 correction). Both replacement names are 12th-century, so the "eight centuries" framing in the title, executive summary, and abstract is unchanged by the correction. The v1.17 revision row retains the superseded name as an append-only historical record. No number, verdict, measurement, or certificate changed |
| v1.25 | 2026-08-21 | **Shao Yong candidate-cession hedge added to the 36-unit attribution (pre-review self-hardening pass; attribution unchanged).** §6's "36-unit consolidation to Lai Zhide (1525–1604)" now notes that a candidate earlier statement of the 8+28=36 *count* — not the consolidation — by Shao Yong (11th c.) is recorded, second-hand and unconfirmed, in CITATIONS.md (⚠ CANDIDATE EARLIER CESSION, 2026-08-21). The Lai Zhide attribution stands until the 皇極經世 locus is read first-hand. No measurement, verdict, or certificate changed |
| v1.26 | 2026-08-29 | **Shao Yong candidate-cession hedge discharged (attribution of the 36-*count* moves; consolidation attribution unchanged).** The v1.25 hedge ("second-hand and unconfirmed") is superseded: the 皇極經世/觀物外篇 locus was read first-hand from the 四庫 woodblock scan (twice, 2026-08-26/27), the 8+28=36 count confirmed in 邵雍's own wording, and the applied cession published in CITATIONS.md 2026-08-29 (see CORRECTIONS.md). §6's lineage clause now points to the confirmed entry instead of the candidate paragraph. The 36-unit *consolidation* remains credited to Lai Zhide; no measurement, verdict, or certificate changed |
| v1.27 | 2026-09-01 | **The 2026-08-28 "minimal" retraction completed at the three sites its own gate could not see, and the §4 joint-strict rerun line finished.** (i) The 2026-08-28 correction withdrew "minimal" from §5's margin claim, but three phrase-variants survived in this report because they span line breaks or use a different spelling: the executive summary and §5 both re-asserted "minimally imperfect" (§5's within five lines of the marker retracting it), and the figure caption read "the minimal measured margins (2 each)". All three now state the measured margin (2 each) with the absence of an extremal check said explicitly. The rendered PNG/SVG and their generator `viz/report_figures.py` still carry the old wording and are flagged in the caption; regenerating them is outside this pass's file scope. Surviving out-of-scope siblings: `documentation/LITERATURE_RULES_POPULATION_TESTS.md` (2 sites) and the generator. (ii) §4's joint-strict Verification Guide bullet still gave the pre-correction recipe (`--estimate-knuth 5000000000`, archived instance `f11_runB.out`) beside the marker saying the published 1.13×10²⁹ is **not** from that file; the command and instance now match the marker — `reports/evidence/r11/r11_moore_strict.out`, 2×10¹⁰ probes / 64 threads, as that file's own header lines record — with the (probes, threads) reproduction condition stated. No theorem, certificate, count or verdict changed |
| v1.28 *(current)* | 2026-09-01 | **C4's orientation narrowed from attested to definitional at four §7 sites (the 2026-08-30 correction propagated).** [METHODS.md](METHODS.md) §"Constraint set" established on 2026-08-30 that the *Xugua* attests only that the {Heaven, Earth} pair opens, and not the order of Heaven over Earth within it — 天地 is a compound, not an ordering — so what the classical record carries is C1's pairing rule (孔穎達《周易正義·序卦傳疏》, 二二相耦，非覆即變), verified from the primary text, and C4's *pair choice*, which is unaffected. Four sites in this report still gave C4's orientation the wider classical epithet: §7's re-scope parenthetical, the Van den Berghe fiber-ceiling sentence, and the two clauses of the 2026-07-26 pair-only re-check that credited a *classical* rather than a *received* opening with forcing his declared exception. All four now say **definitional — this project's convention**, and where the point is about the received text they say **received**. **No number, count, fiber size, p-value, verdict or certificate changed**: the 12-of-1,720,320 C4-oriented result, the 2-of-2,703,360 pair-only result, both P(X ≥ 29) figures and every frozen 2026-07-05 value stand exactly as published — the orientation is fixed by C4 either way, so the fibers are the same fibers and only the epithet on their defining bit moved. The v1.16 row above retains the superseded epithet as an append-only historical record, per the v1.24 precedent |
