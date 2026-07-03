# [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) — Eight Centuries of Rules, Measured: the Population Scoreboard
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Abstract
Structural rules asserted for the King Wen sequence across eight centuries of literature — from Zheng Qiao
(~1150) and Zhu Yuansheng (13th c.) through Lai Zhide (1525–1604) to Moore, Schulz, Cook, McKenna & Mair,
Drasny, and Schöter — none of them ROAE discoveries — were formalized in the C1–C5 pair representation and
measured against the *entire* constraint-satisfying population (≈1.33×10³⁸ orderings) by unbiased
weighted-Knuth estimation (2×10¹⁰ probes; the instrument reproduced the independently-established total
space size to 0.03%, self-validating the method). This converts decades of by-inspection claims into
measured population statistics for the first time. The literature's design inventory splits three ways:
**forced** (eight rules measure at exactly 1.0 of canonical mass — they are theorems of C1–C5, asserted as
design features), **typical** (e.g., the classical 18:18 split holds in 36.4% of all valid orderings), and
**genuinely discriminating** (down to 2×10⁻⁸ for Schulz's S25–28 trigram configuration). A SAT layer adds
exact decisions: Moore's conjectured "uncorrupted precursor" exists, its minimal repair from King Wen is
exactly 3 slot-edits, and one ordering — the grand unified precursor — perfects Moore's two rules and
Schulz's gender rule simultaneously via a single compatible 3-edit event centered on the literature's own
anomaly loci. And then the ceiling: **the four strongest rules are jointly unsatisfiable** (THE CONFLICT
THEOREM, drat-trim-verified). Perfection was never available; King Wen's profile reads as a trade-off
optimum — exact on one strong rule, minimally imperfect on the others.

## Sections
1. **The question and the instrument.** The literature's rules were established by inspection of one
   object; population measurement asks how much of the C1–C5-satisfying space (≈1.33×10³⁸ orderings —
   SEARCH_SPACE_SIZE.md) shares each property. Method: weighted Knuth random probes
   (`SOLVE_KNUTH_SCORE=1`, 2×10¹⁰ probes) — each probe walks a uniformly-random constraint-satisfying
   completion, weighting by the product of branching factors; per-leaf rule predicates accumulate weighted
   mass; fractions are ratios of canonical-leaf masses. Self-validation: the instrument reproduced the
   independently-established total space size to 0.03%. Every formalization was verified to reproduce its
   source's stated King Wen values exactly before measurement (Moore's 16/18 with violations at pair
   positions 22–23; rhythm breaks at (7,8) and (22,23)); rule predicates are two-language verified
   (independent C and Python implementations). Caveats stated up front: fractions are over raw
   orientation-resolved sequences (orientation-invariant rules unaffected; Moore's 1989 rising/falling
   rule is orientation-sensitive by design); strict-form masses near 10⁻⁶ carry ~±10-15% relative sampling
   error at this probe count.
2. **The first-wave scoreboard (2026-07-02).**

   | Rule (source) | Fraction of C1–C5 mass | Cut factor | King Wen |
   |---|---|---|---|
   | Pair-positioning parity, strict 18/18 (Moore 2005) | 5×10⁻⁶ | ×200,000 | **fails** (16/18) |
   | Both Moore rules at KW's level (joint) | 1.85×10⁻⁵ | ×54,000 | satisfies |
   | Pair-positioning parity ≥16/18 (Moore 2005) | 7.3×10⁻⁴ | ×1,362 | satisfies (exactly 16/18) |
   | Rising/falling alternation, 0 breaks (Moore 1989) | 6.3×10⁻⁴ | ×1,598 | **fails** (2 breaks) |
   | Rising/falling alternation ≤2 breaks (Moore 1989) | 3.85% | ×26 | satisfies |
   | Final-pair anchor: alternating pair last (Cook 2006) | 7.84% | ×12.8 | satisfies |
   | First 7 pairs cover all 7 levels (Cook 2006) | 12.03% | ×8.3 | satisfies |
   | 18:18 two-part class split (Zheng Qiao ~1150; Hu Yigui 1247; Hacker & Moore 2003; Cook 2006) | 36.4% | ×2.7 | satisfies |

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
   design features, they are in fact *forced* by C1–C5. McKenna's 3:1 ratio was the first known case; this
   batch found seven more (mmt4, p1c4, s1, s6, r3, r4, r5, c2), including three consequences of Radisic's
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
   the full space (the 560T slice contains zero d5 records in 10.5B — see [TR-7](TR7_CIRCULAR_READING.md) / CIRCULAR_KING_WEN.md).
4. **SAT-decided exactness: the precursors and the 3-edit events.** Population fractions are statistical; a
   SAT layer (`sat.py`, encoding derived from solve.py's constraint definitions, external kissat solver,
   DRAT certificates) adds *exact* decisions. (a) **Moore's conjectured fully-compliant ordering exists —
   here is one:** an explicit C1–C5-valid sequence satisfying his 2005 parity rule 18/18 AND his 1989
   rhythm rule with 0 breaks, differing from King Wen only by swapping pairs 22↔23 (his anomaly) and
   flipping two within-pair orientations (pairs 8 and 23), complement-distance sum 776 — C3 at the same
   ceiling as KW. Moore (1989) judged the bare 22/23 swap "too simplistic" because it leaves the rhythm
   broken; the two orientation flips complete the repair. (b) **The minimal repair is exactly 3
   slot-edits** — SAT-decided: no ordering within 2 slot-edits of KW achieves joint compliance (UNSAT, a
   fortiori under C3), and 3 suffices. (c) **Schulz's gender rule** (Schulz 1990; exception first noticed
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
   it runs deep: the pair structure itself is attested to **Yu Fan (220–265 AD)** (pangtong/fandui, via Li
   Dingzuo); the 36-unit consolidation to **Lai Zhide (1525–1604)** (via Schulz 1982); the 18:18 split to
   **Zheng Qiao (~1150)** and **Hu Yigui (1247)**, modern treatment **Hacker & Moore 2003**; the
   pair-positioning parity rule and rhythm rule to **Moore (2005, 1989)**, building on the *Dazhuan*
   odd=Heaven/yang attribution; the gender/position-parity rule (measured at ×11,364 in the companion
   registry) originates with **Schulz 1990** — attribution corrected 2026-07-03 upon first-hand reading
   (Cook had been credited as primary) — elaborated by **Cook 2006**, its single exception first
   recognized by **Zhu Yuansheng (13th c.)** per Schulz 2018 fn. 42; the trigram configuration to
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

## Verification Guide
- Population fractions, both waves: `SOLVE_KNUTH_SCORE=1 ./solve --estimate-knuth 20000000000`
  (self-validation vs the total-space size in documentation/SEARCH_SPACE_SIZE.md, agreement 0.03%)
- Per-rule registry, formalizations, attributions, KW-value reproduction: `solve.py --registry-verify`;
  documentation/LITERATURE_RULES_POPULATION_TESTS.md; documentation/CITATIONS.md §Attributed candidate
  rules
- Moore joint witness: `python3 sat.py --witness moore-strict` (explicit sequence in
  LITERATURE_RULES_POPULATION_TESTS.md §SAT-decided, C3 = 776)
- Grand precursor witness: `python3 sat.py --witness grand-strict`
- Minimal-repair UNSAT certificates (moore-strict-near-2, rc4-strict-near-2) + alternation-theorem
  certificates (alt-le-14, alt-ge-16): regenerate CNFs via `python3 sat.py --emit-cnf <name> f.cnf &&
  kissat f.cnf`; check archived DRAT certificates with drat-trim → `s VERIFIED` (all four, 2026-07-03)
- THE CONFLICT THEOREM: `python3 sat.py --emit-cnf grand-ccn4 f.cnf && kissat f.cnf` → UNSAT; encoding
  validation: ccn4-kwtest SAT, rc4-kwtest UNSAT
- Wrap-distance finals cross-reference: documentation/CIRCULAR_KING_WEN.md (TR-7)

## TODO before review
- [ ] Decide whether the full 31-rule table renders as prose (current, per source doc) or a proper table
      with per-rule source column pulled from the registry
- [ ] Add the registry's rule-ID → source-citation legend (rs/ccn/c2011/mmt/p/d/s/m/r/c prefixes) as an
      appendix so the extended table is self-contained
- [ ] Confirm the joint-strict "targeted instrument" investigation status (first-wave item 2's open
      question was superseded by the SAT witness — say so explicitly)
- [ ] Operator voice pass on section 5 (the conflict-theorem framing is the flagship claim)
- [ ] One figure: Pareto/trade-off diagram — KW vs grand precursor on the four strongest rules

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
