# TR-10 — A Textual Archaeology, Measured: Scott Davis's Structural Reading Against the Population of Valid Orderings

*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

In 2012 the anthropologist Scott Davis published the most detailed structural reading of the King Wen
sequence in decades — arguing that the received ordering is a deliberate, holistic design built from
mid-scale compositional units, and that the centuries-old hunt for a global generating algorithm misses
how its composers actually worked. Unusually for this literature, Davis made **concrete, checkable
claims**: specific blocks, specific placements, specific "found nowhere else" assertions. That is to
his credit — it is precisely what made this report possible. Nine composites operationalized from his
claims were **publicly pre-registered before any measurement**, then measured against the ≈1.33×10³⁸
valid orderings. The headline is the nulls: Davis's flagship compositional units — including the showcase
segment of the group he calls "undeniably designed" — turn out to be **typical-to-mildly-uncommon** among valid orderings.
His exact configurations are rare, but only in the way *every* exact configuration extracted from a
specific sequence is rare — rarity by construction, not evidence of design. One specific uniqueness
claim is refuted with a concrete counterexample he did not scan for; a second candidate refutation was
**withdrawn under our own hostile review** — his claim survives its fairest reading. Nothing promotes
to a constraint; the ~126-bit unexplained residual (TR-9) survives its second literature-guided attack.

## Abstract
Scott Davis, *The Classic of Changes in Cultural Context: A Textual Archaeology of the Yi jing*
(Cambria Press, 2012), asserts specific positional structures in the King Wen ordering — mid-scale
symmetric blocks, coordinated placements of notation-defined hexagram classes, and a terminal-pair
transformation structure — while arguing explicitly against global algorithmic explanation. His claims
were formalized in the pair representation (operationalizations ours; each verified to reproduce his
stated King Wen facts before measurement), and nine composites were pre-registered in the public record
(CRITIQUE, commit `2d19a3f`, thresholds frozen: two-sided p < 0.05/9 "notable"; < 10⁻⁴ plus a
corpus-control specificity gate "candidate rule") before any population number was observed.
Measurement by weighted-Knuth estimation (2×10⁹ probes; the instrument reproduced the
independently-established C1–C5 space size to 0.09% in the same run) yields: **four of nine NULL** —
including both flagship compositional claims (the hexagram-7–16 complement-mirror block, present in
~1.1% of valid orderings; terminal-pair neighborhood contiguity, two-sided ~5.4×10⁻²); one notable
(the #43–50 regular trigram array, 6.8×10⁻⁴); one borderline at the threshold to reported precision; and three
exact-placement templates rare-to-unsampled — the data-like class whose rarity is expected by
construction (the circularity caveat) and evidential of nothing. Nothing promotes. Separately, exact
recomputation refutes one Davis uniqueness claim — that #63/64 transforms into the fewest derivative
hexagrams of all pairs (pp. 251–255, 257 n2) — under every reading we could construct, while confirming
his worked examples individually; and a second candidate refutation (p. 114) was withdrawn under
hostile self-review, with the episode reported as part of the record. The refutation is offered with
credit: Davis's willingness to make falsifiable structural claims distinguishes his book from most of
this literature, and his scope warning — that jointly formal-textual patterns are invisible to purely
notational scoring — is accepted and stated.

## Sections
1. **Davis's project, and why it is testable.** Davis reads the King Wen sequence as structural
   anthropology in the tradition of Granet and Lévi-Strauss: a deliberate textual design modeling an
   age-graded social system, organized in decades with "centering and symmetry" around each decade's
   5/6 slot, assembled from mid-scale modules — Big and Little Hexagram segments, paired compositional
   devices, a designed terminal (pp. 59–120, 121–148, 247–258). He is explicit that the design idiom is
   "ethnomathematical" and modular, *not* an algorithm: the search for a closed-form generator "runs a
   high risk" of anachronism (paraphrase, p. 67), and he cites Gardner (1974) approvingly for the
   absence of global mathematical pattern beyond the pairing (p. 84 n6) — while asserting rich local
   and mid-scale structure, e.g. the first Big-and-Little segment laid out in "strictest symmetry" (p. 96) and
   the Big and Little group as "undeniably designed" (p. 116). Two things deserve plain credit. First,
   unusually for this literature, many of Davis's structural observations are stated concretely enough
   to formalize and check — blocks with definite boundaries, classes with definite membership,
   uniqueness assertions with definite scope. Second, every formal Davis fact we operationalized
   reproduces in the King Wen sequence exactly as he states it (his verified observations include the
   7–16 complement mirror, the #43–50 array, the rotation≡inversion pair placement, and the
   three-group structure of the terminal pair's one-line neighborhood). The dispute below is never
   about whether his patterns are *there* — they are — but about what they are evidence *of*: the
   population question his method could not ask.
2. **The pre-registration discipline.** Following the F4' protocol, the nine composites were registered
   in the public record (documentation/CRITIQUE.md §"Pre-registered test in flight: Davis (2012)",
   commit `2d19a3f`, 2026-07-04) **before any population number had been observed**, with decision
   thresholds frozen in advance: "notable" = two-sided p < 0.05/9 (Bonferroni, 5.56×10⁻³); "candidate
   rule" = < 10⁻⁴ AND passing the corpus-control specificity gate (the same functional must not flag on
   Jing Fang's Eight Palaces or the Mawangdui ordering); all nine reported regardless of outcome; and —
   per the standing extraction-circularity policy — **nothing promotes to a solver constraint
   regardless of outcome**. Operationalizations are embedded, two-language verified, and public:
   `solve.py` is the spec (`dav_*` functions), `solve.c` the measurement engine, and the cross-gate
   (`--dav-verify` in both) confirms each candidate reproduces its expected King Wen value exactly.
   Formalization choices are ours, not Davis's; errors of operationalization are ours.
3. **The scoreboard (2026-07-04, 2×10⁹ probes).** Population = the C1–C5 constraint-satisfying space
   (≈1.33×10³⁸ orderings; the run's own canonical-leaf estimate, 1.3275×10³⁸, matches the established
   figure to 0.09% — self-validating). Fractions are of canonical mass.

   | # | Candidate (Davis claim, pages) | KW | Population | Pre-registered verdict |
   |---|---|---|---|---|
   | 1 | `termruns` — terminal-pair one-line-neighborhood contiguity (flagship, pp. 251–255) | 3 runs | P(≤3) = 2.7×10⁻² (two-sided ~5.4×10⁻²; population mean 5.2 runs) | **NULL** |
   | 2 | `compmirror` — the 7–16 complement-mirror block (pp. 81–82, 92, 95–96) | 1 block | P(≥1) = 1.12×10⁻² (~1 in 89 orderings) | **NULL** |
   | 3 | `trigarray` — the #43–50 regular trigram array (pp. 76–77, 112) | 1 window | P(≥1) = 6.8×10⁻⁴ | notable (below candidate gate) |
   | 4 | `parallel3040` — 30s/40s parallel with chiasmus (pp. 78, 253–254) | 1 | zero sampled mass in 2×10⁹ | extreme / data-like class |
   | 5 | `palnbr` — palindrome-neighborhood adjacency mass (pp. 121–128) | 10 | P(≥10) = 7.9×10⁻² (mean 4.9) | **NULL** |
   | 6 | `rotinv` — rotation≡inversion pairs at 11/12, 17/18, 53/54, 63/64 (p. 68, 118 n14) | 1 | P = 6.5×10⁻⁵ | meets candidate-rule numerically — data-like; does not promote |
   | 7 | `pureplace` — pure-hexagram placement (pp. 80, 82, 183) | 1 | P = 5.56×10⁻³ | borderline (at the 0.05/9 threshold to reported precision) |
   | 8 | `eccplace` — eccentric-class placements incl. 23/24–43/44 at distance 20 (pp. 124–125, 117 n10, 172, 211) | 1 | zero sampled mass | extreme / data-like class |
   | 9 | `asymhalf` — both-asymmetric-trigram half-split (pp. 111–112) | 4 of 16 | P(≤4) = 1.9×10⁻¹ (mean 7.3) | **NULL** |

   Corpus control: every flagged predicate evaluates to zero on both Jing Fang and Mawangdui — the
   specificity gate passes; nothing here is an artifact of the instrument lighting up on any
   structured ordering. **The population-informative findings are the nulls.** Davis's flagship
   compositional claims — the terminal contiguity his final chapter builds toward, the 7–16 mirror he
   describes as laid out in "strictest symmetry", the palindrome-neighborhood device of his central
   chapter 6, the asymmetric-trigram half-split — are *not* population-notable: they are
   typical-to-mildly-uncommon among orderings satisfying the classical constraints. The three
   exact-placement templates (rows 4, 6, 8) are KW-extracted configurations — the data-like class:
   any exact template read off any specific sequence is rare by construction (the circularity caveat
   pre-registered in CRITIQUE), so their rarity is expected, not evidence. Per the pre-commitment,
   **nothing promotes**. The single honest bright spot for Davis is the #43–50 trigram array (row 3):
   a pattern-form (not a placement template) that ~1 in 1,500 valid orderings contains anywhere —
   notable at the Bonferroni gate, well short of the candidate gate, and his best-performing claim.
4. **One refutation, and one withdrawn.** Davis claims that the terminal pair is transformationally
   unique: transforming each of #63/64's twelve lines yields derivative hexagrams confined to three
   contiguous groups (#3–6, #35–40, #49/50), and "in no other case" does a pair transform into so few
   derivatives — "the lowest of all hexagram pairs" (paraphrase-near, pp. 251, 255, 257 n2). His
   positive findings are exactly right: the three-group structure of #63/64 is real, and his three
   worked negative examples reproduce precisely (#3/4 → 6 groups, #23/24 → 5, #25/26 → 4, with his
   exact group memberships). **The uniqueness sentence, however, fails under every reading we could
   construct.** Read literally (fewest distinct derivative hexagrams): the minimum is 10, attained by
   twelve pairs — among them his own worked example #23/24, whose ten listed derivatives contradict
   the closing sentence of the same endnote; #63/64 has 12. Read charitably under his own group
   metric (maximal runs of contiguous positions, pinned down by his examples): #63/64's 3 groups are
   **tied, not unique** — #51/52's twelve derivatives fall in exactly three contiguous groups
   ({15–18}, {21–24}, {53–56}). He evidently never scanned the other 28 pairs; the counterexample is
   the doubled Zhen/Gen pair his own mountain chapter treats at length. What survives for Davis:
   #63/64 *attains* the group-count minimum, and his description of it is exactly correct — the claim
   fails only at "no other case." (A smaller note in the same spirit: his list of wind-trigram
   hexagrams at the decade 7/8 slots, p. 114, is incomplete rather than wrong — #28 also qualifies.)
   The record should also show the refutation that did **not** survive: our audit initially filed
   Davis's p. 114 assertion — no further example of the per-trigram-rotation relation linking
   #17/18–#21/22 to #53/54–#55/56 — as a failed claim, since the bare transformation links 24 position
   pairs. A hostile-review pass against our own finding withdrew it: under the fairest reading — the
   coordinated four-term quartet at the compactness of his own instance — Davis's claim is **true in
   King Wen and unique**, with the nearest rival configuration appearing only at looser region spans.
   We report the episode because the adversarial standard applied to Davis was applied to our claims
   about Davis, and one of them lost. (Two caveats travel with his surviving claim: pair-onto-pair
   transport under that transformation is notation-forced — true in every pairing-compliant ordering —
   so only the placement coordination is distinctive; and the uniqueness depends on an unstated
   compactness threshold, which any future population scoring must pre-register.)
5. **His anti-mathematical argument, measured.** Davis's position implies three predictions:
   (a) global algorithmic compressions of the sequence will fail; (b) mid-scale block and symmetry
   structure will score far above chance; (c) many patterns are jointly formal-textual and invisible
   to purely notational scoring (pp. xvii–xix, 67–68, 96, 256). The measurement splits cleanly across
   them. **On (a), the record to date is with him**: no global generator is known, the celebrated
   transition recipe prices as description rather than explanation, ~105–127 bits of the sequence
   remain unexplained after all known rules (TR-9), and both systematic literature-guided attacks on
   that residual — the 13-functional F4' battery (all thirteen null) and now this 9-candidate battery
   (one Bonferroni-notable survivor, nothing past the candidate gate) — left it standing.
   The measurement also *agrees* with him in a subtler way: the rarity of his exact configurations
   says little (the circularity caveat), which is the same discipline that keeps this project from
   over-reading rarity anywhere else — raw configuration rarity supports neither the algorithm-hunters
   nor the design reading. **On (b), the measurement is largely against him**: his compositional units are
   population-typical, with the #43–50 array (§3, row 3) the lone Bonferroni-notable exception. The
   flagship block of the group he calls undeniably designed occurs in ~1.1% of valid orderings; the
   terminal contiguity in ~2.7% (one-sided); the chapter-6 adjacency device carries a one-sided tail
   mass of 7.9×10⁻²; the half-split, 1.9×10⁻¹. Whatever the composers of the received order did, these
   mid-scale symmetries are largely what the classical pairing constraints already make unremarkable —
   the design signal his method reads off the single object does not survive comparison against the
   space of objects. **On (c), his scope warning is accepted and stated plainly**: this report
   measures only the notational shadow of his claims. His textual layers — word-repetition sets,
   seasonal loci, numerological sitings (his chs. 2, 10, and passim) — are outside the bit domain and
   outside this instrument; nothing here bears on them, for or against.
6. **Attribution, copyright discipline, and what is claimed.** All Davis material above is paraphrase
   with page citation; no extended quotation is used (single short phrases at most), per the project's
   derived-insights-only handling of copyrighted sources. The operationalizations are ours and public
   (solve.py); errors of formalization are ours, not Davis's; corrections are welcome via
   CITATIONS.md. Davis's own formal debts are credited as he states them: Dai Sike (1978) for the 7–16
   symmetry, Li Shangxin for the pair-unit trisection, Gardner (1974) for the no-global-pattern
   verdict; overlaps between his observations and Schulz's and Cook's are recorded in the attribution
   registry. What is claimed here: nine pre-registered population measurements (four null, one
   notable, one borderline, three data-like), one exact refutation of a uniqueness claim, one
   withdrawn refutation, and no promotion of anything into the constraint system. What is *not*
   claimed: that Davis's design thesis is false — population typicality is not a disproof of intent,
   and his textual arguments are unmeasured by construction. The honest summary is narrower: where
   Davis's structural claims can be measured, they mostly dissolve into the typical; where they are
   rare, they are rare the way every specific configuration is rare; and where he asserted uniqueness,
   once it held and once it did not.

## Verification Guide
- KW-value reproduction, two-language gate: `python3 solve.py --dav-verify` and `./solve --dav-verify`
  → `DAV VERIFY: PASS` (each of the nine candidates reproduces its expected King Wen value; solve.py
  is the spec, solve.c the engine)
- Population masses and histograms (§3 table): `SOLVE_KNUTH_SCORE_DAV=1 SOLVE_KNUTH_DAV_HIST=1
  ./solve --estimate-knuth 2000000000` (evidence file: `dav_tier1.out`, tier-1 run 2026-07-04;
  self-validation: same run's canonical-leaf estimate 1.3275×10³⁸ vs SEARCH_SPACE_SIZE.md's
  1.3287×10³⁸, 0.09%)
- Pre-registration prior to measurement: documentation/CRITIQUE.md §"Pre-registered test … Davis
  (2012)" — registered at commit `2d19a3f` (2026-07-04) before any population number existed;
  thresholds and the nothing-promotes policy are in the registration text
- Corpus-control specificity gate: evaluate the `dav_*` predicates (solve.py) on the Jing Fang and
  Mawangdui orderings (the `--null-historical` data) → 0 on every flagged predicate
- The refutation (§4): recomputable in a few lines from solve.py's `binary_hexagrams` — for each of
  the 32 pairs, take the 12 one-line transforms, map to positions, count distinct targets and maximal
  contiguous position runs. Checks: #63/64 → 12 distinct in 3 runs; #51/52 → 12 distinct in 3 runs
  ({15–18}, {21–24}, {53–56}); #23/24 → 10 distinct in 5 runs; twelve pairs attain the 10-derivative
  minimum; Davis's worked examples (3/4 → 6, 23/24 → 5, 25/26 → 4) all reproduce
- The withdrawn refutation (§4): with T(h) = reverse each trigram in place, verify T commutes with
  line-reversal and complement on all 64 hexagrams (pair→pair transport is notation-forced), the 24
  T-linked position pairs, and that Davis's quartet [17/18 & 21/22 → 53/54 & 55/56] is the unique
  tightest coordinated instance at its region spans
- Claims sourced by page to Davis 2012 (Cambria Press, ISBN 978-1-60497-808-7); full page-cited claim
  inventory in the private audit (copyright: paraphrase-only handling)

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | Initial private draft (roae-private staging); adversarial review pending before any public release |
| v1.1-draft | 2026-07-04 | Hostile pre-publication review pass: "strictest symmetry" page cite corrected (p. 112 → p. 96, verified against the book); "undeniably designed" (p. 116) re-scoped to the Big-and-Little group rather than the 7–16 block; §5(a) "came back null" corrected to reflect the one Bonferroni-notable row; §5(b) softened to "largely against him" with the trigarray exception stated, and mixed percentile conventions replaced by the table's tail masses; pureplace "exactly at threshold" → "at the threshold to reported precision" (measured 5.56×10⁻³ vs 0.05/9 = 5.56×10⁻³ at 3 s.f.). All table masses re-derived from dav_tier1.out; refutation and corpus-control numbers independently recomputed; both `--dav-verify` gates re-run (PASS) |
