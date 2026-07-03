# Testing the Literature's Structural Rules at Population Scale

**Result (2026-07-02):** Structural rules asserted for the King Wen sequence in prior literature — none of
them ROAE discoveries — were formalized in the C1–C5 pair representation and measured against the *entire*
constraint-satisfying population (≈1.33×10³⁸ orderings) by unbiased weighted-Knuth estimation
(`SOLVE_KNUTH_SCORE=1`, 2×10¹⁰ probes; the instrument reproduced the independently-established total space
size to 0.03%, self-validating the method). This converts decades of by-inspection claims into measured
population statistics for the first time. **Attribution:** every rule below is credited to its source (with lineage where it runs deep — the pair
structure itself is attested to Yu Fan, 220–265 AD; the 36-unit consolidation to Lai Zhide, 1525–1604; the
gender/position-parity rule measured at ×11,364 in the companion registry originates with **Schulz 1990**
and was elaborated by Cook 2006); see
[CITATIONS.md](CITATIONS.md) §Attributed candidate rules. ROAE's contribution is formalization + measurement.

## The scoreboard

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

## What the measurements establish

1. **Moore's pair-positioning rule is the strongest known literature discriminator.** King Wen's 16-of-18
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
   population — far above the naive 1/31 ≈ 3.2%, because C5's transition budget favors closing on a
   distance-6 pair; the rule is genuine but its surprise is smaller than raw position-counting suggests.
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
are over raw orientation-resolved sequences (orientation-invariant rules are unaffected; Moore's 1989
rising/falling rule is orientation-sensitive by design); strict-form masses near 10⁻⁶ carry ~±10-15%
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
   first noticed by Zhu Yuansheng, 13th c.) had 0 hits in 36M samples; SAT decides it: witnesses exist
   (C1–C5-valid, C3 = 776), and the minimal repair from King Wen is exactly 3 slot-edits (≤2 UNSAT, DRAT
   cert archived) — a swap of the adjacent pairs at slots 21/22 (= class positions 25/26, precisely the
   Zhu Yuansheng/Schulz exception locus) plus one orientation flip.
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
Lai Zhide rules), McKenna & Mair 1979, Drasny, and Schöter — 31 rules formalized (two-language verified,
each reproducing its source's stated King Wen values), measured in one run. Full per-rule registry and
attribution: solve.py `--registry-verify` section. Three headline findings:

**1. A new strongest discriminator — with the data-likeness caveat stated plainly.** Schulz's S25–28
trigram configuration (2011/2016: four consecutive stations sharing the dui top trigram, bottoms = the
four "right" trigrams in order) holds in 2×10⁻⁸ of the population (×5×10⁷) — three orders beyond the
previous champion. Like Cook's exact level-3 positions, this is a highly *specific* configuration: its
registry classification is data-like rather than principled, and it is reported as a measured property,
not promoted. The exception-co-location meta-rule (both Schulz rules' violations confined to S25/26)
measures 2.6×10⁻⁷ (×3.8M) — the anomaly locus itself is population-rare.

**2. Eight literature rules are THEOREMS of the constraint system** — they measure at exactly 1.0 of
canonical mass: asserted in the literature as design features, they are in fact *forced* by C1–C5
(McKenna's 3:1 ratio was the first known case; this batch found seven more, including three consequences
of Radisic's optimality structure, whose 1.0 readings also validate the instrument end-to-end). Several
more are near-forced (0.95–0.9998). The literature's design inventory therefore splits three ways:
forced / typical / genuinely discriminating.

**3. King Wen is exactly maximal on xiaoxi placement** (Drasny/Schulz d7: 8 of 8, and 8 is the observed
population maximum) — a genuine extremal property, one of very few axes where KW attains the boundary.

Full table (fraction of canonical mass; KW satisfies each at its measured level by construction of the
threshold forms): rs1 6.6×10⁻⁴ · rs2 3.0×10⁻³ (max seen 26/26 vs KW 20) · ccn1 3.4×10⁻⁵ · ccn2 1.5×10⁻³
· ccn3 6.6×10⁻⁶ · **ccn4 2×10⁻⁸** · ccn6 0.427 · ccn7 1.1×10⁻³ · **ccn8 2.6×10⁻⁷** · c2011n1 <10⁻⁹ (0
hits) · c2011n2 5.9×10⁻⁵ · c2011n4 1.1×10⁻² · mmt3 0.953 (min Gray-transitions seen 0 vs KW 4) · mmt4
**1.0** · mmt5 0.9998 · mmt6 0.993 · p1c4 **1.0** · p2c3 6.7×10⁻² · p2c4 1.0×10⁻³ · p2c5 2.3×10⁻³ ·
p2c6 4.1×10⁻⁴ · d4 5.7×10⁻⁴ · d7 1.7×10⁻⁴ (KW maximal 8/8) · s1 **1.0** · s6 **1.0** · m2 8.0×10⁻² ·
r3 **1.0** · r4 **1.0** · r5 **1.0** · c1 6.6×10⁻² (min deviation seen 4 vs KW 24) · c2 **1.0**.
Wrap-distance finals: d1 = 17.5%, d3 = 65.2%, **d5 = 17.4%** of the full space — see
[CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md) (the slice contains zero d5 records in 10.5B).

## THE CONFLICT THEOREM (2026-07-04, SAT-decided, drat-trim verified): perfection was never available

The literature's four strongest rules are **jointly unsatisfiable**: no C1–C5-valid ordering achieves
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
naturally as a **trade-off optimum**: exact on one strong rule, minimally imperfect on the others, at a
Pareto position the population measurements already showed to be ~1-in-25-million efficient. The usual
caveat travels with this: the trigram configuration is a data-like rule (highly specific); the theorem is
about the literature's rules exactly as its authors stated them. Reproduce:
`python3 sat.py --emit-cnf grand-ccn4 f.cnf && kissat f.cnf` (encoding two-way validated: ccn4-kwtest SAT,
rc4-kwtest UNSAT).
