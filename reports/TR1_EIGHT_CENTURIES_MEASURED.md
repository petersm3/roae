# TR-1 — Eight Centuries of Rules, Measured: the Population Scoreboard
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

For roughly eight centuries, scholars have claimed the King Wen sequence follows hidden design rules —
almost always by pointing at the sequence and asserting the pattern. This report does what none of that
literature could: it **measures every claimed rule against the entire space of orderings** that satisfy
the sequence's core constraints. The result sorts the claims into three kinds. Eight celebrated "design
choices" behave as **forced** — no valid ordering violating them was found in twenty billion weighted
probes (one is proven outright), so they reveal nothing about the
arranger. Others are **typical** — common enough to be unremarkable. A few are **genuinely rare** (down
to one in fifty million), and King Wen has them. The report culminates in the conflict theorem: the
literature's four strongest rules **cannot all be satisfied by any ordering that preserves the classical pairing**, and King Wen sits
exactly where that conflict forces a choice. A follow-up battery (§7) turns the same measurement on the
sequence's most-ignored layer — which member of each pair comes first — and finds that the one rule the
literature ever offered for it, [Van den Berghe's](../documentation/CITATIONS.md#vandenberghe1999) hand-derived nuclear rule (c. 1999–2002), places King Wen
at the exact maximum of everything achievable: of 1,720,320 possible orientation configurations, only 12
score as high, none higher — and his rule's single declared exception turns out to be forced. Every number
here can be recomputed, and the impossibility results carry machine-checkable certificates.

## Abstract
Structural rules asserted for the King Wen sequence across eight centuries of literature — from Zheng Qiao
(~1150) and Zhu Yuansheng (13th c.) through [Lai Zhide](../documentation/CITATIONS.md#laizhide) (1525–1604) to Moore, Schulz, [Cook](../documentation/CITATIONS.md#cook2006), [McKenna & Mair](../documentation/CITATIONS.md#mckenna-mair1979),
[Drasny](../documentation/CITATIONS.md#drasny2007), and [Schöter](../documentation/CITATIONS.md#schoter1998) — none of them ROAE discoveries — were formalized in the C1–C5 pair representation and
measured against the *entire* constraint-satisfying population (≈1.33×10³⁸ orderings) by unbiased
weighted-Knuth estimation (2×10¹⁰ probes; the instrument reproduced the independently-established total
space size to 0.03%, self-validating the method). This converts decades of by-inspection claims into
measured population statistics for the first time. The literature's design inventory splits three ways:
**forced** (eight rules measure at exactly 1.0 of canonical mass — they are theorems of C1–C5, asserted as
design features), **typical** (e.g., the classical 18:18 split holds in 36.4% of all valid orderings), and
**genuinely discriminating** (down to 2×10⁻⁸ for [Schulz's](../documentation/CITATIONS.md#schulz2011) S25–28 trigram configuration). A SAT layer adds
exact decisions: Moore's conjectured "uncorrupted precursor" exists, its minimal repair from King Wen is
exactly 3 slot-edits, and one ordering — the grand unified precursor — perfects Moore's two rules and
Schulz's gender rule simultaneously via a single compatible 3-edit event centered on the literature's own
anomaly loci. And then the ceiling: **the four strongest rules are jointly unsatisfiable** (THE CONFLICT
THEOREM, drat-trim-verified). Perfection was never available; King Wen's profile reads as a trade-off
optimum — exact on one strong rule, minimally imperfect on the others.

## Sections
1. **The question and the instrument.** The literature's rules were established by inspection of one
   object; population measurement asks how much of the C1–C5-satisfying space (≈1.33×10³⁸ orderings —
   [SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md)) shares each property. Method: weighted Knuth random probes
   (`SOLVE_KNUTH_SCORE=1`, 2×10¹⁰ probes) — each probe walks a uniformly-random constraint-satisfying
   completion, weighting by the product of branching factors; per-leaf rule predicates accumulate weighted
   mass; fractions are ratios of canonical-leaf masses. Self-validation: the instrument reproduced the
   independently-established total space size to 0.03%. Every formalization was verified to reproduce its
   source's stated King Wen values exactly before measurement (Moore's 16/18 with violations at pair
   positions 22–23; rhythm breaks at (7,8) and (22,23)); rule predicates are two-language verified
   (independent C and Python implementations). Caveats stated up front: fractions are over raw
   orientation-resolved sequences (orientation-invariant rules unaffected; [Moore's 1989](../documentation/CITATIONS.md#moore1989) rising/falling
   rule is orientation-sensitive by design); strict-form masses near 10⁻⁶ carry ~±10-15% relative sampling
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
   | 18:18 two-part class split (Zheng Qiao ~1150; Hu Yigui 1247; [Hacker & Moore 2003](../documentation/CITATIONS.md#hacker-moore2003); Cook 2006) | 36.4% | ×2.7 | satisfies |

   What this wave establishes: (a) Moore's pair-positioning rule was the strongest first-wave
   discriminator — KW's 16-of-18 compliance is shared by ~1 in 1,362 valid orderings, its joint Moore
   profile by ~1 in 54,000; (b) the two Moore rules are **negatively correlated** (joint mass = 0.66× the
   independence prediction) — parity and rhythm compete, a structural fact not previously observed;
   (c) KW is near-optimal but strictly suboptimal on both Moore rules, and fully-compliant orderings exist
   on each (Moore's "uncorrupted" conjecture confirmed per rule) — so both readings of the pairs-22/23
   anomaly remain live: deliberate/corrupted deviation from a compliant precursor (Moore), or strong
   tendencies rather than exact laws; (d) Cook's final-pair anchor is real but partially explained — 7.8%
   vs the naive 1/31 ≈ 3.2%, because C5's transition budget favors closing on a distance-6 pair;
   (e) the classical 18:18 split is weak as a discriminator (36%) — its significance is historical
   attestation, not statistical rarity.
3. **The extended scoreboard: 31 further rules (2026-07-03 batch, 2×10¹⁰ probes).** The full candidate
   inventory from the Schulz corpus (1990/2011/2016/2018 + the 1982 dissertation's Lai Zhide rules),
   McKenna & Mair 1979, Drasny, and Schöter — 31 rules formalized (two-language verified, each reproducing
   its source's stated KW values), measured in one run. Three headline findings. **(1) A new strongest
   discriminator — with the data-likeness caveat stated plainly:** Schulz's S25–28 trigram configuration
   (2011/2016: four consecutive stations sharing the dui top trigram, bottoms = the four "right" trigrams
   in order) holds in 2×10⁻⁸ of the population (×5×10⁷) — three orders beyond the previous champion. Like
   Cook's exact level-3 positions, this is a highly *specific* configuration: its registry classification
   is data-like rather than principled, and it is reported as a measured property, not promoted. The
   exception-co-location meta-rule (both Schulz rules' violations confined to S25/26) measures 2.6×10⁻⁷
   (×3.8M) — the anomaly locus itself is population-rare. **(2) Eight literature rules are THEOREMS of the
   constraint system** — they measure at exactly 1.0 of canonical mass: asserted in the literature as
   design features, they are in fact *forced* by C1–C5. [McKenna's](../documentation/CITATIONS.md#mckenna-mckenna1975) 3:1 ratio was the first known case; this
   batch found seven more (mmt4, p1c4, s1, s6, r3, r4, r5, c2), including three consequences of [Radisic's](../documentation/CITATIONS.md#radisic2026)
   optimality structure, whose 1.0 readings also validate the instrument end-to-end. Several more are
   near-forced (0.95–0.9998). **(3) King Wen is exactly maximal on xiaoxi placement** (Drasny/Schulz d7:
   8 of 8, and 8 is the observed population maximum) — a genuine extremal property, one of very few axes
   where KW attains the boundary. Full table (fraction of canonical mass; KW satisfies each at its
   measured level by construction of the threshold forms): rs1 6.6×10⁻⁴ · rs2 3.0×10⁻³ (max seen 26/26 vs
   KW 20) · ccn1 3.4×10⁻⁵ · ccn2 1.5×10⁻³ · ccn3 6.6×10⁻⁶ · **ccn4 2×10⁻⁸** · ccn6 0.427 · ccn7 1.1×10⁻³
   · **ccn8 2.6×10⁻⁷** · c2011n1 <10⁻⁹ (0 hits) · c2011n2 5.9×10⁻⁵ · c2011n4 1.1×10⁻² · mmt3 0.953 (min
   Gray-transitions seen 0 vs KW 4) · mmt4 **1.0** · mmt5 0.9998 · mmt6 0.993 · p1c4 **1.0** · p2c3
   6.7×10⁻² · p2c4 1.0×10⁻³ · p2c5 2.3×10⁻³ · p2c6 4.1×10⁻⁴ · d4 5.7×10⁻⁴ · d7 1.7×10⁻⁴ (KW maximal 8/8)
   · s1 **1.0** · s6 **1.0** · m2 8.0×10⁻² · r3 **1.0** · r4 **1.0** · r5 **1.0** · c1 6.6×10⁻² (min
   deviation seen 4 vs KW 24) · c2 **1.0**. Wrap-distance finals: d1 = 17.5%, d3 = 65.2%, d5 = 17.4% of
   the full space (the 560T slice contains zero d5 records in 10.5B — see [TR-7](TR7_CIRCULAR_READING.md) / [CIRCULAR_KING_WEN.md](../documentation/CIRCULAR_KING_WEN.md)).
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
   by Zhu Yuansheng, 13th c.; strict form had 0 hits in 36M samples) is perfectly satisfiable, and its
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
   UNSAT under C1+C2+C4+C5); joint-strict population size (pinned-walk estimate) ≈1.13×10²⁹ canonical
   orderings (±4.7%). The encoder round-trip validation's first solver model, pleasingly, is King Wen
   itself.
5. **THE CONFLICT THEOREM (2026-07-04, SAT-decided, drat-trim verified): perfection was never available.**
   The literature's four strongest rules are **jointly unsatisfiable**: no C1–C5-valid ordering achieves
   Moore's 2005 parity (18/18), Moore's 1989 rhythm (0 breaks), the Schulz gender rule (0 violations), and
   the Schulz S25–28 trigram configuration simultaneously (UNSAT under C1+C2+C4+C5, hence a fortiori with
   C3; certificate independently verified). The pieces fit together sharply: King Wen satisfies the
   trigram configuration **exactly**, and misses the other three by the minimal measured margins (16/18,
   2 breaks, 2 violations); the 3-edit grand precursor satisfies those three **perfectly** — and breaks
   the trigram configuration. Both cannot be had: **the rules compete**, and any ordering must choose
   which to satisfy. Consequence for the corruption hypothesis: an "uncorrupted precursor" perfect under
   the literature's full rule inventory **never existed** — the corruption reading survives only in the
   restricted sense (perfect under Moore's two rules alone, breaking the trigram structure KW keeps). King
   Wen's profile now reads naturally as a **trade-off optimum**: exact on one strong rule, minimally
   imperfect on the others, at a Pareto position the population measurements already showed to be
   ~1-in-25-million efficient. The usual caveat travels with this: the trigram configuration is a
   data-like rule (highly specific); the theorem is about the literature's rules exactly as its authors
   stated them. Certificate chain: all four UNSAT proofs (alt-le-14, alt-ge-16, moore-strict-near-2,
   rc4-strict-near-2) plus the conflict-theorem CNF check `s VERIFIED` under drat-trim against regenerated
   CNFs (2026-07-03); the conflict encoding is two-way validated (ccn4-kwtest SAT, rc4-kwtest UNSAT).
6. **Attribution, lineage, and what is claimed.** Every rule is credited to its source, with lineage where
   it runs deep: the pair structure itself is attested to **[Yu Fan](../documentation/CITATIONS.md#yufan) (164–233 AD)** (pangtong/fandui, via Li
   Dingzuo); the 36-unit consolidation to **Lai Zhide (1525–1604)** (via [Schulz 1982](../documentation/CITATIONS.md#schulz1982)); the 18:18 split to
   **Zheng Qiao (~1150)** and **Hu Yigui (1247)**, modern treatment **Hacker & Moore 2003**; the
   pair-positioning parity rule and rhythm rule to **Moore (2005, 1989)**, building on the *Dazhuan*
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
   positions/configurations, e.g. ccn4, Cook's level-3 positions) carry rarity that is partly
   specification, not principle; none of these rules, singly or jointly, approaches uniqueness (the full
   C1–C7 space holds ≈5.2×10³¹ orderings). Accordingly **none is promoted into the formal constraint
   system**; they are measured properties of King Wen's position in the population, with
   description-length and attestation recorded for each (see [TR-9](TR9_PRICING_THE_CONSTRAINTS.md)).
7. **The orientation layer, measured (2026-07-05).** Everything above concerns which pair goes where. A
   final pre-registered battery measures the layer the literature has almost entirely ignored — **which
   member of each pair comes first**. Of the 32 within-pair orientation choices, slot 0 is forced
   (Theorem 6), leaving 31 binary choices; but conditioning on King Wen's pair sequence, exact
   enumeration shows the constraints leave a valid orientation **fiber of exactly 1,720,320 vectors**
   (= 3·5·7·2¹⁴ ≈ 2^20.7 — far below the naive 2³¹; 30 of the 31 bits vary somewhere in the fiber, and
   slot 30, hexagrams 61/62, is the only additionally forced bit). This already corrects our own earlier
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
   | 11 | **Nuclear orientation rule — Van den Berghe c. 1999–2002** | **29/30** | **1.3951×10⁻⁵** | **notable — the fiber maximum** |

   Rows 8–10 join the forced class of §3: three of McKenna's difference-wave statistics turn out to be
   **constant across all 1,720,320 valid orientations** — given the pair sequence they measure constraint
   geometry, not an arranger's orientation choice. Rows 1–7: seven literature-anchored orientation ideas,
   from Cook's correct-line stage (the one explicit within-pair orientation rule in the modern academic
   literature) through Moore's rising/falling system (our count reproduces his published 10R/8F exactly)
   to the classical yang-precedence reading, are all **null** — dead-typical of the choices actually
   available. The orientation layer is not decorated with weak echoes of the ordering rules; it is silent
   on every axis but one.

   **The headline: Van den Berghe found, by hand, the single most extreme orientation regularity
   achievable.** Around the turn of the millennium, D.H. Van den Berghe — working independently and
   publishing on the open web (c. 1999–2002) — proposed a nuclear-hexagram decision procedure predicting
   which member of each pair comes first, and reported that King Wen follows it in 29 of the 30 pairs it
   addresses, with one declared exception (hexagram pair 3/4). Both halves of his claim verify exactly —
   and exact enumeration sharpens both in his favor. King Wen's agreement count of 29 is the **maximum
   attained anywhere on its orientation fiber**: exactly **12 of 1,720,320** vectors reach 29 (King Wen
   among them; exact P(X ≥ 29) = 6.9754×10⁻⁶ one-sided), and **none reaches 30** — perfect agreement is
   unattainable, so his declared exception is not a blemish his rule tolerates but a **forced** feature:
   no valid orientation of King Wen's pair sequence satisfies all 30 predictions. That clarifies the
   rule's standing — it is not "almost perfect"; it is **perfect up to impossibility**. The unconditional
   population concurs: zero mass at ≥ 29 in ≈2.9×10⁷ weighted valid-sequence leaves (2×10⁹-probe run).
   Credit where it is due: Van den Berghe **found** this regularity, a quarter-century ago and without
   any of this machinery; ROAE's contribution is to operationalize it, enumerate its null exactly, and
   locate it in the population — the finding is his, the measurement is ours. It is of a piece with his
   work overall: our audit of his web-published reconstruction verified 17 of 19 checkable claim-groups
   exactly, with his two self-declared exceptions falling precisely where computation finds the misfits.

   The honest scoping travels with the headline. Under the frozen thresholds the result is **notable**
   (two-sided p = 1.3951×10⁻⁵, ~2.5 orders of magnitude past the 0.05/11 = 4.545×10⁻³ bar) but, on the
   strictest pre-registered reading, **not** a "candidate rule": the two-sided p exceeds the
   10⁻⁴/11 = 9.091×10⁻⁶ bar (the one-sided 6.9754×10⁻⁶ would pass, but the frozen convention is
   two-sided and the strictest reading governs), and the strict gauge-control reading additionally marks
   the flag convention-tied (it inverts, attenuated ~50× in p, under direction-reversing gauge
   relabelings — arguably covariant behavior for a rule about which member *leads*, but reported as
   frozen). More fundamentally: Van den Berghe derived the rule *from* King Wen, so this is
   population-atypicality of a **fitted description** — the described configuration carries
   ≈17.1 bits of atypicality (≥ ~14 after discounting the rule's ~2–3 fitted degrees of freedom) out of
   the layer's ≈20.7-bit budget — and **not** independent confirmation of a design rule; no out-of-sample
   test is possible from the same document the rule was read off of. The corpus gate is clean and
   KW-specific: Mawangdui scores 1 — below the entire 2×10⁹-probe sampled range [2, 28], i.e. the
   *opposite* tail at population-extreme depth (a by-product of its trigram-block sort) — and [Jing Fang](../documentation/CITATIONS.md#jingfang)
   scores 6, also the opposite tail; both historical controls anti-agree with the rule, so no
   classical-norm explanation is available. *(Corrected 2026-07-05: the Mawangdui control was
   originally reported as 14, "dead central, p ≈ 0.97" — computed on an erroneous Mawangdui array;
   the corrected array ([Shaughnessy 2022](../documentation/CITATIONS.md#shaughnessy2022), Table 11.2) makes the gate verdict stronger, not weaker.
   All 11 F5 functionals on the corrected Mawangdui: 15, 19, 11, 0, 4, 7, 8, 12, 0, 1, 1 in f5_names
   order, two-language verified.)* Per the frozen
   pre-commitment, nothing here promotes into the constraint system; it is a measured property of King
   Wen. Raw outputs, the exact-fiber script, and exercised reproduction commands (the fiber analysis
   reruns byte-identically in ~11 s): [evidence/f5/](evidence/f5/README.md).

## Figure

![Grouped bar chart of the four conflicting rules: King Wen misses Moore's 2005 parity rule by 2 (16/18), Moore's 1989 rhythm rule by 2 breaks, and Schulz's 1990 gender rule by 2 violations while satisfying the Schulz S25–28 trigram configuration exactly; the grand unified precursor is perfect (0) on the first three and violates the trigram configuration — no pairing-preserving ordering achieves zero on all four.](figures/fig_tr1_rules_tradeoff.png)

*The conflict theorem's trade-off (§5). King Wen (red) misses the three graded rules by the minimal
measured margins (2 each) and keeps the S25–28 trigram configuration exactly; the grand unified
precursor (green, 3 slot-edits from KW) perfects all three graded rules and breaks the trigram
configuration — which, being a specific binary configuration, has no graded miss count. The jointly
UNSAT result (drat-trim-verified) says no C1–C5-valid ordering can reach zero on all four axes at once.
All values are the reports' stated numbers; generated by
[`viz/report_figures.py`](../viz/report_figures.py); [SVG](figures/fig_tr1_rules_tradeoff.svg).*

## Verification Guide
- Population fractions, both waves: `SOLVE_KNUTH_SCORE=1 ./solve --estimate-knuth 20000000000`
  (self-validation vs the total-space size in documentation/SEARCH_SPACE_SIZE.md, agreement 0.03%)
- Per-rule registry, formalizations, attributions, KW-value reproduction: `solve.py --registry-verify`;
  [documentation/LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md); documentation/CITATIONS.md §Attributed candidate
  rules
- Moore joint witness: `python3 sat.py --witness moore-strict` (explicit sequence in
  LITERATURE_RULES_POPULATION_TESTS.md §SAT-decided, C3 = 776)
- Grand precursor witness: `python3 sat.py --witness grand-strict`
- Joint-strict population size (§4, ≈1.13×10²⁹ ±4.7%): `SOLVE_KNUTH_MOORE_STRICT=1 ./solve
  --estimate-knuth 5000000000` (pinned strict-Moore walk; flag documented in [SOLVE_C_CLI.md](../documentation/SOLVE_C_CLI.md)
  §ENVIRONMENT; archived instance: reports/evidence/f11/f11_runB.out)
- Minimal-repair UNSAT certificates (moore-strict-near-2, rc4-strict-near-2) + alternation-theorem
  certificates (alt-le-14, alt-ge-16): regenerate CNFs via `python3 sat.py --emit-cnf <name> f.cnf &&
  kissat f.cnf`; check archived DRAT certificates with drat-trim → `s VERIFIED` (all four, 2026-07-03)
- THE CONFLICT THEOREM: `python3 sat.py --emit-cnf grand-ccn4 f.cnf && kissat f.cnf` → UNSAT; encoding
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
| v1.5 | 2026-07-04 | Adversarial round 2 corrections: conflict-theorem claims scoped to pairing-preserving orderings; TR-3 weeks-not-months; TR-9 residual dual-convention phrasing |
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
| v1.2 | 2026-07-04 | Figures added |
| v1.6 | 2026-07-04 | Reproducibility completion: joint-strict population estimate (§4, ≈1.13×10²⁹) given an explicit rerun line in the Verification Guide; its `SOLVE_KNUTH_MOORE_STRICT` flag documented in SOLVE_C_CLI.md; archived instance cross-referenced (reports/evidence/f11/f11_runB.out) |
| v1.7 | 2026-07-05 | New §7 "The orientation layer, measured": pre-registered 11-functional battery over the exact 1,720,320-vector orientation fiber (+ 2×10⁹-probe population run). Van den Berghe's nuclear rule (c. 1999–2002) shown to be the fiber maximum (12/1,720,320; his declared exception proven forced); three McKenna statistics forced; seven other literature axes null. Evidence bundle reports/evidence/f5/ with exercised reproduction |
| v1.8 | 2026-07-05 | **Erratum (Mawangdui corpus control):** the Mawangdui array used project-wide since 2026-04-06 was wrong (right octet membership; wrong octet order and within-octet order). §7's corpus-gate row recomputed on the corrected array (authority: Shaughnessy 2022, Brill, p. 50 + Table 11.2; discovered by the literature-audit cross-check): vdb_nuc 14 → 1, moving Mawangdui from "dead central" to the opposite-tail extreme — the KW-specificity verdict stands, strengthened. Note the authentic Mawangdui order *fails C2* (one 5-line transition at its Kan→Zhen octet seam). No §7 verdict flips |
