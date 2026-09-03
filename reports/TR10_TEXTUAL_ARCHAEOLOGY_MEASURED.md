# TR-10 — A Textual Archaeology, Measured: Scott Davis's Structural Reading Against the Population of Valid Orderings

*Technical report — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. One caveat is structural, and it frames all the rest: the same
author wrote the claims, the software that checks them, and this report that grades the check.
Verification here is independent in mechanism, never in authorship; no independent party has yet
audited or reproduced any of it (METHODS.md §"Authorship independence").*
*Scope note (F-34): "archaeology" here is figurative. This report measures **notational and structural**
properties of the received ordering against the population of valid orderings; it makes no historical,
philological, or text-critical claim beyond what the combinatorics support.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

In 2012 the anthropologist [Scott Davis](../documentation/CITATIONS.md#davis2012) published the most detailed structural reading of the King Wen
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
to a constraint; the unexplained residual of **~105–139 bits** ([TR-9](TR9_PRICING_THE_CONSTRAINTS.md); the figure depends on which layers are granted explanatory standing — ~126.6 bits is the intermediate C1–C5 reading, not the whole range) survives its second literature-guided attack.

## Abstract
Scott Davis, *The Classic of Changes in Cultural Context: A Textual Archaeology of the Yi jing*
(Cambria Press, 2012), asserts specific positional structures in the King Wen ordering — mid-scale
symmetric blocks, coordinated placements of notation-defined hexagram classes, and a terminal-pair
transformation structure — while arguing explicitly against global algorithmic explanation. His claims
were formalized in the pair representation (operationalizations ours; each verified to reproduce his
stated King Wen facts before measurement), and nine composites were pre-registered in the public record
([CRITIQUE](../documentation/CRITIQUE.md), commit `2d19a3f`, thresholds frozen "as F4'": two-sided p < 0.05/9 "notable"; "candidate rule" additionally requires the corpus-control specificity gate — the < 10⁻⁴ candidate-level bar is inherited from the F4' family's own registration (worded "< 10⁻⁴ after Bonferroni"; sidedness unstated there), not restated verbatim in 2d19a3f) before any population number was observed.
Measurement by weighted-Knuth estimation (2×10⁹ probes; the instrument reproduced the
previously-published C1–C5 space size *estimate* to 0.09% in the same run — a consistency check within
the same estimator family, since that figure is itself a Knuth estimate; corrected 2026-08-01 from
"independently-established", the adjective TR-1 v1.18's correction was about) yields: **five of nine NULL** —
including both flagship compositional claims (the hexagram-7–16 complement-mirror block, present in
~1.1% of valid orderings; terminal-pair neighborhood contiguity, two-sided ~5.4×10⁻²); one notable
(the #43–50 regular trigram array, 6.8×10⁻⁴ — survives its family correction but not the global
91-observable ledger's ≈5.5×10⁻⁴ Bonferroni bar, though it *would* survive that ledger under BH-FDR; §3); and three
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
   high risk" of anachronism (paraphrase, p. 67), and he cites [Gardner (1974)](../documentation/CITATIONS.md#gardner) approvingly for the
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
   in the public record (documentation/CRITIQUE.md §"Pre-registered tests: Davis (2012)",
   commit `2d19a3f`, 2026-07-04) **before any population number had been observed**, with decision
   thresholds frozen in advance: "notable" = two-sided p < 0.05/9 ([Bonferroni](../documentation/CITATIONS.md#bonferroni1936), 5.56×10⁻³); "candidate
   rule" = < 10⁻⁴ AND passing the corpus-control specificity gate (the same functional must not flag on
   [Jing Fang](../documentation/CITATIONS.md#jingfang)'s Eight Palaces or the Mawangdui ordering); all nine reported regardless of outcome; and —
   per the standing extraction-circularity policy — **nothing promotes to a solver constraint
   regardless of outcome**. **Masses are weighted-sample estimates**, and each carries a
   delta-method standard error. ⚠ **[CORRECTED 2026-08-30: the archived tier-1 and tier-2 outputs
   (`reports/evidence/dav_tier1.out`, 2026-07-04; `dav2_tier1.out`, 2026-07-12) contain NO `se=`
   field — both predate the estimator gaining it on 2026-08-28, and a reader opening either file
   finds no standard errors. The SEs quoted here were computed separately. Regenerate them with
   `SOLVE_THREADS=32 SOLVE_KNUTH_SCORE_DAV=1 SOLVE_KNUTH_DAV_HIST=1 ./solve --estimate-knuth 2000000000`, whose
   current output prints `se=` per mass; the archived files are retained as the original evidence
   and are NOT being restated.]** **A verdict whose
   95% CI straddles its bar is labelled "unresolved at N probes", not classified.** Among the nine rows
   only `rotinv` approaches that condition — its two-sided p exceeds the 10⁻⁴ candidate bar by
   **≈2.3 SE**, so its 95% CI clears the bar only marginally — and **no published classification
   changes** once the errors are carried. Operationalizations are embedded, two-language verified, and public:
   `solve.py` is the spec (`dav_*` functions), `solve.c` the measurement engine, and the cross-gate
   ([`--dav-verify`](../documentation/SOLVE_C_CLI.md#--dav-verify) in both) confirms each candidate reproduces its expected King Wen value exactly.
   Formalization choices are ours, not Davis's; errors of operationalization are ours.
3. **The scoreboard (2026-07-04, 2×10⁹ probes).** Population = the C1–C5 constraint-satisfying space
   (≈1.33×10³⁸ orderings; the run's own canonical-leaf estimate, 1.3275×10³⁸, matches the established
   figure to 0.09% — a consistency check within the same estimator family (the absolute validation is TR-11's exact anchors)). Fractions are of canonical mass.

   | # | Candidate (Davis claim, pages) | KW | Population | Pre-registered verdict |
   |---|---|---|---|---|
   | 1 | `termruns` — terminal-pair one-line-neighborhood contiguity (flagship, pp. 251–255) | 3 runs | P(≤3) = 2.7×10⁻² (two-sided ~5.4×10⁻²; population mean 5.2 runs) | **NULL** |
   | 2 | `compmirror` — the 7–16 complement-mirror block (pp. 81–82, 92, 95–96) | 1 block | P(≥1) = 1.12×10⁻² (~1 in 89 orderings); **two-sided 2.24×10⁻²** | **NULL** |
   | 3 | `trigarray` — the #43–50 regular trigram array (pp. 76–77, 112) | 1 window | P(≥1) = 6.8×10⁻⁴; **two-sided 1.36×10⁻³** | notable (below candidate gate; does not survive the global 91-observable ledger **under Bonferroni** — would under BH-FDR, see §3 note) ⚠ [SIDEDNESS FLAG 2026-09-01: that BH counterfactual is computed on the ONE-SIDED masses (trigarray 6.8×10⁻⁴, `rotinv` 6.5×10⁻⁵). Under this table's own declared two-sided convention the same rank-2 comparison is 1.36×10⁻³ against 2·(0.05/91) = 1.10×10⁻³, so "would under BH-FDR" does not hold two-sided. The **published** verdict is unchanged either way — 1.36×10⁻³ still exceeds the global Bonferroni bar 0.05/91 = 5.49×10⁻⁴. Flagged for adjudication together with [METHODS.md](METHODS.md) §"Global observable ledger"; deliberately NOT restated here.] |
   | 4 | `parallel3040` — 30s/40s parallel with chiasmus (pp. 78, 253–254) | 1 | zero sampled mass in 2×10⁹ | extreme / data-like class |
   | 5 | `palnbr` — palindrome-neighborhood adjacency mass (pp. 121–128) | 10 | P(≥10) = 7.9×10⁻² (mean 4.9); **two-sided 1.57×10⁻¹** | **NULL** |
   | 6 | `rotinv` — rotation≡inversion pairs at 11/12, 17/18, 53/54, 63/64 (p. 68, 118 n14) | 1 | one-sided P = 6.5×10⁻⁵; **two-sided P = 1.31×10⁻⁴** | **data-like; does not promote — and does NOT meet the candidate bar under the C1–C5 null. `null-sensitive` — see the null-sensitivity note below the table.** ⚠ [CORRECTED 2026-08-28: this read "meets candidate-rule numerically". The suite applies a two-sided convention throughout — row 1 of this same table already doubles — so this row is read two-sided: the published 6.5×10⁻⁵ is the one-sided upper tail (`at`+`above` from `dav_tier1.out`), and 2 × 6.531×10⁻⁵ = 1.306×10⁻⁴ **exceeds** 10⁻⁴. The one-sided value is retained above because downstream BH ranking in METHODS/TR-8 cites it.] ⚠ [SIDEDNESS ATTRIBUTION CORRECTED 2026-09-01: the 2026-08-28 note above read "The bar declared at §3 is **two-sided** p < 10⁻⁴". That contradicts this report's own Abstract. §3's *notable* bar is declared two-sided (0.05/9); the < 10⁻⁴ *candidate* bar is **inherited** from the F4′ family's registration, worded there "< 10⁻⁴ after Bonferroni" with **sidedness unstated**, and is not restated verbatim in `2d19a3f`. The two-sided reading is retained as the suite's operating convention — but it is a convention applied here, not a sidedness the candidate bar's own registration fixed, and under a one-sided reading of the inherited bar this row would meet it numerically (6.5×10⁻⁵ < 10⁻⁴). Nothing turns on the resolution: the row does not promote under either reading, because it is a KW-extracted exact template — the data-like class the pre-registration bars from promoting whatever its rarity.] |
   | 7 | `pureplace` — pure-hexagram placement (pp. 80, 82, 183) | 1 | one-sided P = 5.56×10⁻³; **two-sided P = 1.11×10⁻²** | **NULL** under the C1–C5 null. `null-sensitive` — see the null-sensitivity note below the table. ⚠ [CORRECTED 2026-08-28: this read "borderline (at the 0.05/9 threshold to reported precision)". It is not borderline under either reading — the declared bar is **two-sided** p < 0.05/9 = 5.5556×10⁻³, and the **one-sided** value 5.56152×10⁻³ already exceeds it before doubling — but that is a **≈0.1-SE gap**, true of the printed estimate and far too close to carry weight, so it is recorded and NOT relied on. The NULL rests on the two-sided reading, which is **≈45 SE** clear.] |
   | 8 | `eccplace` — eccentric-class placements incl. 23/24–43/44 at distance 20 (pp. 124–125, 117 n10, 172, 211) | 1 | zero sampled mass | extreme / data-like class |
   | 9 | `asymhalf` — both-asymmetric-trigram half-split (pp. 111–112) | 4 of 16 | P(≤4) = 1.9×10⁻¹ (mean 7.3); **two-sided 3.90×10⁻¹** | **NULL** |

   **Null-sensitivity of rows 6 and 7 (added 2026-09-01; a disclosure gap, not an arithmetic error).**
   Every mass above is computed against the *operative, pre-registered* null — the C1–C5
   constraint-satisfying population — and every one of them is correct under it. That is not the only
   defensible null this suite maintains: [METHODS.md](METHODS.md) §"Permutation-test nulls" also defines the
   **pair-preserving** null — "shuffle the 32 canonical pairs + independent uniform orientation flips, first
   pair fixed by C4 where stated" — and [TR-8](TR8_REORDERING_REVISITED.md) §2 measures against it, noting
   that "C2/C5 are themselves regularities read off the received order, so this null is conservative, not
   'undisputed'", and re-deriving the Schulz gender rule under it in closed form (47/445740). Two of the nine
   rows above change classification under that null, and this report did not previously say so. Both
   predicates are functions of *pair-slot placement only* — `dav_rotinv` compares a position **set**, and
   `dav_pureplace` reads positions that come in whole slots — so both are invariant to the orientation-flip
   half of the pair-preserving null, and the masses below are exact rationals over slot arrangements, not
   estimates:

   | row | predicate | C1 only | C1 + C4 | C1–C5 (published above) |
   |---|---|---:|---:|---:|
   | 6 | `rotinv` | 2/C(32,4) = **5.562×10⁻⁵** | 2/C(31,4) = **6.356×10⁻⁵** | 1.31×10⁻⁴ |
   | 7 | `pureplace` | 2·7/35,960 = **3.893×10⁻⁴** | 2·14/4,495 = **6.229×10⁻³** | 1.11×10⁻² |

   (Two-sided throughout, to match the table above. Row 6: the notation-fixed 8-member class — the hexagram
   values {7, 11, 21, 25, 38, 42, 52, 56} with rev6(*h*) = comp6(*h*) ≠ *h* — forms exactly four pair-blocks,
   {7,56}, {11,52}, {21,42}, {25,38}, and the predicate asks that they occupy pair-slots {6, 9, 27, 32}; with
   31 free blocks exchangeable over 31 free slots that is 4!·27!/31! = 1/C(31,4) = 1/31,465, and 4!·28!/32! =
   1/C(32,4) = 1/35,960 without C4, which pins a block outside the class. Row 7: the two doubled-symmetric
   blocks {63,0} and {18,45} must take slots {1, 15} — 1/C(32,2) under C1, but only 1/31 under C1+C4, because
   **C4 already pins {63,0} to slot 1**, i.e. C4 hands the predicate half of the very placement it tests —
   times the 42 of C(30,2) = 435 remaining slot-pairs that put the two doubled-asymmetric blocks, {9,36} and
   {27,54}, inside one decade straddling its 5/6 centre.)

   **What this changes.** Row 6 `rotinv` clears the 10⁻⁴ candidate bar numerically under *either* alternative
   null, where under C1–C5 it misses at 1.31×10⁻⁴. Row 7 `pureplace` clears both the 0.05/9 = 5.556×10⁻³
   family bar and the 0.05/91 = 5.495×10⁻⁴ global bar under **C1 alone**, against the **NULL** recorded above
   — but is NULL again as soon as C4 is added (6.229×10⁻³, 1.12× the family bar), the whole ×16.0 being C4's
   pinning of {63,0}. **What this does not change:** no published mass here is wrong, each being correct
   under its stated null; the corpus-control specificity gate is null-free; and *nothing promotes* under any
   of the three nulls — rows 6 and 7 are exact templates read off King Wen, the data-like class the
   pre-registration bars from promoting whatever its rarity, which is precisely why a reversal in the rarity
   *number* does not become a reversal in the *verdict*. The correct reading of rows 6 and 7 is therefore
   `null-sensitive`: their classification is a statement about the C1–C5 null, not about the sequence.

   Corpus control: every flagged predicate evaluates to zero on both Jing Fang and Mawangdui — the
   specificity gate passes *(re-verified 2026-07-05 on the corrected Mawangdui array — see the v1.2
   revision row; all flagged predicates remain zero)*; nothing here is an artifact of the instrument lighting up on any
   structured ordering. **The population-informative findings are the nulls.** Davis's flagship
   compositional claims — the terminal contiguity his final chapter builds toward, the 7–16 mirror he
   describes as laid out in "strictest symmetry", the palindrome-neighborhood device of his central
   chapter 6, the asymmetric-trigram half-split — are *not* population-notable: they are
   typical-to-mildly-uncommon among orderings satisfying the **C1–C5 constraints** ⚠ **[CORRECTED 2026-08-29 — this read "the classical constraints". The conditioning set is C1–C5, and only **C1** is classical (Kong Yingda's formulation, per CITATIONS.md). C2 is McKenna 1975, C3 is this project's KW-fitted threshold, and C5 is an extracted transition histogram — calling the whole set classical borrows an authority three of its five members do not have. See CORRECTIONS.md]**. The three
   exact-placement templates (rows 4, 6, 8) are KW-extracted configurations — the data-like class:
   any exact template read off any specific sequence is rare by construction (the circularity caveat
   pre-registered in CRITIQUE), so their rarity is expected, not evidence. Per the pre-commitment,
   **nothing promotes**. The single honest bright spot for Davis is the #43–50 trigram array (row 3):
   a pattern-form (not a placement template) that ~1 in 1,500 valid orderings contains anywhere —
   notable at the Bonferroni gate, well short of the candidate gate, and his best-performing claim.
   The "notable" is family-scoped: it survives its frozen family correction (0.05/9 = 5.56×10⁻³) but
   does **not** survive the global 91-observable ledger (bar ≈ 0.05/91 ≈ 5.5×10⁻⁴; 6.8×10⁻⁴ falls
   outside it — see [METHODS.md](METHODS.md) §"Global observable ledger"). **That last verdict is
   Bonferroni-specific and is the one place in the suite where the correction family matters**: under
   Benjamini–Hochberg FDR ([Benjamini & Hochberg 1995](../documentation/CITATIONS.md#benjamini-hochberg1995))
   at q = 0.05, against the same 91-observable ledger, `trigarray` *would* be
   declared significant. We retain the FWER reading as the conservative choice and disclose the
   dependence rather than rely on it — see METHODS §"Correction-family disclosure". A reader who
   prefers FDR control should read this row as clearing global correction; nothing else in the suite
   changes, since FWER clearance implies FDR clearance.

   3b. **Wave-2 addendum (measured 2026-07-11, 2×10⁹ probes).** The private structural audit's
   frozen queue left four items unmeasured after §3. Wave 2 disposes of all four: two measured
   (the table below), one subsumed — the pair-unit trisection (Davis p. 119 n19, crediting
   Li Shangxin) is the trisection sub-predicate of an already-registered functional and is not
   double-measured under a second name — and one declined on scope without measurement
   (§5(c); power note below). The freeze mechanism differed from wave 1's public
   pre-registration and we state it plainly — together with why nothing below depends on it. The
   wave-2 design is fixed in the **public** record: commit `09e2107` (2026-07-11) landed the
   complete bank in solve.py/solve.c — both functional definitions, their expected King Wen
   values (`tquartet` = 1, `xunslots` = 5), the two-language
   [`--dav2-verify`](../documentation/SOLVE_C_CLI.md#--dav2-verify) gate, the C-D5 decline, and
   the /12 cross-wave Bonferroni denominator, all stated in the public source — before the
   results landed publicly as a batch (this addendum, commit `5ace541`). A git-timestamped
   private pre-registration (2026-07-10, one day earlier) additionally records that the design
   was frozen before any population number was observed; it is retained as provenance and can be
   disclosed to an auditor, but an external reviewer cannot inspect a private repository, so this
   report rests no claim on it. Nor does it need to: the work a pre-measurement freeze normally
   does is carried here by public, re-runnable artifacts and by the results themselves.
   **(i)** Both results are nulls that clear no threshold under any convention — two-sided
   p = 0.849 and 0.148, and the smallest one-sided tail anywhere in the batch (`xunslots`
   P(≥5) = 7.4×10⁻²) fails even the plain *uncorrected* 0.05 gate, a fortiori 0.05/9, the frozen
   0.05/12, and the global ≈0.05/91 ledger — so there is no positive that undisclosed analytic
   freedom could have manufactured, and the verdicts are invariant to the choice of
   multiple-comparisons denominator (or to applying none at all). **(ii)** The converse worry —
   an operationalization tuned after peeking so that Davis's claims would dissolve — is
   answerable from the public record: the functionals' free parameters are Davis's own (the
   quartet window is his instance's own compactness, §4; the twelve x7/x8 slots and the Xun
   trigram class are his stated pattern, p. 114), each functional reproduces its registered King
   Wen value exactly (`--dav2-verify`, both languages), and the measurement — or any variant a
   skeptical reviewer prefers — reruns from the public code (Verification Guide). Neither
   verdict sits near a threshold that tuning could have tipped: at Davis's own compactness the
   quartet configuration is *common* (~88% of valid orderings) with King Wen below the
   population mean, and loosening the window can only make it more common. **(iii)** Selective
   reporting is excluded in public: the source at `09e2107` itself declares the measured bank to
   be exactly these two functionals with C-D5 declined, this addendum dispositions all four
   queue items regardless of outcome (two measured — both null and both reported — one subsumed,
   one declined), and the power note below shows the declined test could never have registered
   under any outcome. The cross-wave Bonferroni denominator, **0.05/12 across the full Davis
   family**, is part of the same public `09e2107` declaration (stricter than wave 1's /9, fixed
   so that neither wave-splitting nor the C-D5 decline could weaken the correction) — and, per
   (i), no verdict below depends on it. Same instrument and self-check as §3: the run's own
   canonical-leaf estimate, 1.3275×10³⁸, matches the established figure to 0.09%.

   | # | Candidate (Davis claim, pages) | KW | Population | Verdict |
   |---|---|---|---|---|
   | 10 | `tquartet` — coordinated per-trigram-rotation quartet at Davis's own compactness (pp. 113–114; the §4 open thread) | 1 | P(≥1) = 0.876; mean 1.86; two-sided p = 0.849 | **NULL** |
   | 11 | `xunslots` — Xun-bearing hexagrams at the twelve x7/x8 decade slots (p. 114) | 5 | P(≥5) = 7.4×10⁻²; mean 2.90; two-sided p = 0.148 | **NULL** |

   **Row 10 answers §4's open thread, and the answer is a plain null.** A quartet at the
   compactness of Davis's own instance is a *common* configuration among valid orderings: about
   88% of them contain at least one, the population mean is 1.86 such quartets, and King Wen's
   single instance sits *below* that mean (observed range 0–10). What §4 shows to be unique
   *within* King Wen is unremarkable *across* the population — the **C1–C5 constraints** already
   make Davis-compact quartets ordinary, so his surviving uniqueness claim, true as stated,
   carries no population force and licenses no design inference. Row 11 was registered at low
   prior (the audit had flagged the underlying list as selective, and the pattern's stated form
   needed correction — §4's note that #28 also qualifies); it lands mildly above expectation
   (KW at roughly the 93rd percentile), nowhere near the 0.05/12 gate, and is reported for
   completeness rather than featured. Neither functional triggered the candidate gate, so no
   corpus-control step fired. Per the standing pre-commitment, **nothing promotes**.

   **The declined candidate, completed with a power analysis.** The scope decline of the
   named-size candidate (§5(c)) stands on its own grounds. Independently of them, an analytic
   result added at this landing shows the declined test was also *incapable* of producing a
   significant result under the pair-exchangeable null it is evaluated against (scope added
   2026-09-01 with the narrowing below):

   > **Power note (analytic).** Independently of the scope grounds for declining it, this
   > test could never have produced a significant result, for a reason that has nothing to
   > do with what its labels mean. The declined predicate belongs to the class of
   > "2-of-6 ordering predicates": mark six of the 32 pairs (here the six marked hexagrams
   > do lie in six distinct pairs — none is another's reversal-partner, and the two
   > palindromic ones pair by complement outside the set), attach a binary attribute to each
   > pair, two of one kind and four of the other, and ask whether the six attributes, read
   > in pair-slot order, spell one specific arrangement. Under the pair-exchangeable null —
   > the 32 pairs assigned uniformly at random to the 32 pair-slots, within-pair
   > orientations free, i.e. the pair structure C1 baked in and nothing else conditioned —
   > the relative slot order of any six fixed pairs is exactly uniform over the 6! = 720
   > orderings: relabeling the six pairs is a measure-preserving bijection of the null space
   > that carries any ordering to any other, and orientations cannot move a pair between
   > slots. A two-plus-four attribute multiset collapses those 720 equiprobable orderings
   > into C(6,2) = 15 distinguishable strings of exactly 2!·4! = 48 orderings each, so every
   > arrangement — the observed one included — has null probability exactly 48/720 = 1/15 ≈
   > 0.067. The smallest p-value any predicate of this class can attain, for any choice of
   > labels and any target arrangement, is therefore 1/15: above the unadjusted 0.05 gate,
   > and sixteen-fold above the 0.05/12 family-corrected gate this test would have faced.
   > The test was uninformative by construction — even its maximally favorable outcome,
   > which the King Wen sequence happens to realize, could never have registered as
   > significant **under this null**. (The bound is exact under the pair-exchangeable null;
   > conditioning further on the boundary constraints perturbs the fifteen arrangement
   > probabilities through the pairs' bit patterns alone — a label-independent, purely
   > structural effect — and breaching the family gate would require a sixteen-fold
   > depletion of the target arrangement.) ⚠ [NARROWED 2026-09-01: this parenthetical
   > used to end with a comparative magnitude claim — that a sixteen-fold depletion was far
   > beyond every effect of its kind the project had measured. It is withdrawn, not
   > restated. The statistic that comparison ranged over is defined nowhere in this
   > repository and no value of it is published anywhere in it — before this narrowing, a
   > search of the public tree for the phrase naming that statistic returned the sentence
   > making the claim and nothing else — so a reader had no way to check it or to falsify
   > it. What survives is the part that is checkable, and it is narrower: the 1/15
   > bound is **exact** under the pair-exchangeable (C1-only) null, and under the fuller
   > C1–C5 conditioning the perturbation is **unmeasured for this predicate class** — this
   > note therefore asserts no bound on it. Nor should the perturbation be assumed small:
   > §3's null-sensitivity table moves `pureplace` by exactly ×16.0 on the addition of C4
   > alone. That is a different predicate class and does not transfer to the 2-of-6 class
   > analysed here — which is precisely why the untested comparison is no longer made.]

   The note is fully reproducible without any ROAE code and without implementing the declined
   predicate — see the Verification Guide. The exchangeability argument is elementary and may
   well exist elsewhere in the statistics literature; no novelty is claimed for it, and
   corrections are welcome. As throughout, the six-hexagram observation itself is Davis's
   (pp. 94–96), credited; the power analysis and any errors in it are ours.

   **A tautology from a different source, reported in the same data-like class (D-B1, landed
   with this addendum).** József Drasny's "Rule of Ten" (*The Yi-globe*, 2007/2011, ch. IV; no
   relation to Davis's separately-named "rule of ten", p. 126) observes that his eight
   trigram-defined functional groups occupy decade-arithmetic "rooms" of the King Wen table —
   group A within ordinals 1–10, group B at 11, 21, 31, 41, and so on — with ten deviant pairs.
   The observation is true and verified: his group classifier reduces to pure bit predicates
   (Table 4.1 reproduced 64/64; two-language [`--db1-verify`](../documentation/SOLVE_C_CLI.md#--db1-verify) gate), and King Wen's conformity
   count is X = 22 of 32 pair-slots, with his ten deviant pairs reproducing exactly. But the
   rooms are King-Wen-derived: Drasny's own derivation (pp. 76–77) reads each room off the
   listed KW ordinals of each group's members, and mechanical re-verification shows every room
   is exactly the **maximum-coverage decade window for its group's King Wen positions** — the
   one group whose best single window covers only 2 is the only group granted two windows, and
   the leftover cells are swept into a residue room — so the fitted per-group coverages sum to
   3+3+3+3+4+5+1 = 22: **KW's conformity count equals the fitted argmax total by construction.**
   Scored against this KW-fitted template, the received sequence naturally sits above the entire
   sampled canonical population (population mean 6.87, observed range 1–20 at 2×10⁹ probes) —
   the same signature as the exact-placement templates of §3 (rows 4, 6, 8), and diagnostic of
   the same thing: extraction, not design. The count is therefore reported as a fitted
   *description* — Drasny's, credited, and the strongest ordinal observation in his book — and
   carries no design inference; no p-value is attached, per the standing extraction-circularity
   policy. (D-B1 belongs to a separate Drasny test family, not the Davis /12 above; it was not
   publicly pre-registered — the operationalization landed publicly first, commit `64e4a42`,
   before any population number was observed — and its classification and process record live in
   [CRITIQUE](../documentation/CRITIQUE.md).) Together, the power note and D-B1 make this
   addendum's methodological theme concrete: literature functionals can be data-like for
   stateable, checkable reasons — C-D5 could never have registered under its null (min p =
   1/15), and D-B1's conformity count scores the sequence against a template extracted from the
   sequence.

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
   ({15–18}, {21–24}, {53–56}). The other 28 pairs appear not to have been checked in the book; the counterexample is
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
   compactness threshold, which any future population scoring must pre-register.) That scoring
   has since been done: the coordination window was fixed at his own instance's
   compactness (both regions within two pair-slots — a parameter read off Davis's quartet, not
   tuned against the population; operationalization and expected King Wen value public at
   commit `09e2107`, freeze provenance in §3b), and the population answer is
   that the configuration is common — about 88% of valid orderings contain such a quartet, with
   a population mean of 1.86 and King Wen's single instance below it (§3b).
5. **His anti-mathematical argument, measured.** Davis's position implies three predictions:
   (a) global algorithmic compressions of the sequence will fail; (b) mid-scale block and symmetry
   structure will score far above chance; (c) many patterns are jointly formal-textual and invisible
   to purely notational scoring (pp. xvii–xix, 67–68, 96, 256). The measurement splits cleanly across
   them. **On (a), the record to date is with him**: no global generator is known, the celebrated
   transition recipe prices as description rather than explanation, ~105–139 bits of the sequence
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
   outside this instrument; nothing here bears on them, for or against. That scope line has since
   proven load-bearing: on 2026-07-11 the project declined, **without measurement**, a conditionally
   pre-registered follow-up candidate built on his big/little hexagram *names* (pp. 94–96, the six
   "big"/"small"-named hexagrams sited small–big–big–big–big–small by pair-slot) — the first candidate
   that would have taken a semantic attribute rather than bit structure as a predicate input —
   precisely to keep names outside the instrument. The observation is Davis's; the decline is ours and
   says nothing for or against his reading. The follow-up family's Bonferroni denominator remains
   frozen at /12, fixed in advance so the decline cannot be read as weakening the correction
   (decision log: [HISTORY.md](../documentation/HISTORY.md), 2026-07-11). A power analysis added
   at the wave-2 landing shows the declined test was additionally uninformative by construction:
   under the pair-exchangeable null its minimum attainable p is exactly 1/15, sixteen-fold above
   the family gate it would have faced (§3b).
6. **Attribution, copyright discipline, and what is claimed.** All Davis material above is paraphrase
   with page citation; no extended quotation is used (single short phrases at most), per the project's
   derived-insights-only handling of copyrighted sources. The operationalizations are ours and public
   (solve.py); errors of formalization are ours, not Davis's; corrections are welcome via
   CITATIONS.md. Davis's own formal debts are credited as he states them: the 7–16 symmetry he had
   himself first published in 1978/79 under his Chinese name, **Dai Sike 戴思客** (a self-citation, not
   a distinct prior author — see [CITATIONS #davis1987](../documentation/CITATIONS.md#davis1987));
   Li Shangxin for the pair-unit trisection; Gardner (1974) for the no-global-pattern verdict; overlaps between his observations and [Schulz's](../documentation/CITATIONS.md#schulz1990-motifs) and [Cook's](../documentation/CITATIONS.md#cook2006) are recorded in the attribution
   registry. What is claimed here: nine pre-registered population measurements (**five** null, one
   notable, three data-like — corrected 2026-08-28: `pureplace` was published as "borderline" and is
   NULL under the report's own declared two-sided bar), one exact refutation of a uniqueness claim, one
   withdrawn refutation, and no promotion of anything into the constraint system. What is *not*
   claimed: that Davis's design thesis is false — population typicality is not a disproof of intent,
   and his textual arguments are unmeasured by construction. The honest summary is narrower: where
   Davis's structural claims can be measured, they mostly dissolve into the typical; where they are
   rare, they are rare the way every specific configuration is rare; and where he asserted uniqueness,
   once it held and once it did not.

## Verification Guide

⚠ **Every `--estimate-knuth` command in this document requires a stack limit of at least 16 MB** — `ulimit -s 16384` suffices, and `ulimit -s unlimited` is one way to satisfy it, not the requirement itself. Under the default 8 MB stack the estimator does not start: `main` allocates a ~7.23 MB frame and `estimate_tree_knuth` a further ~1.02 MB (since 2026-08-21 the binary refuses with an actionable message; previously a bare SIGSEGV). *(Added 2026-08-21, an execution-lane finding — `scripts/exec_lane.sh` executes every documented command on a default environment; the same-day warning propagation (`1e4bd04a`) covered the four estimator guides but missed this file.)* *(Narrowed 2026-09-02, Codex V2-F08 #4, prose batch P37: `ulimit -s unlimited` is a **sufficient** setting that had been published as a **necessary** one — and one that a host or container with a hard stack cap cannot even apply, so the published requirement was a false blocker there. `solve.c`'s `--estimate-knuth` preflight tests `rlim_cur != RLIM_INFINITY && rlim_cur < 16UL*1024*1024` and its message names ">= 16 MB". EXECUTED under TR-9 v1.24 on a locally built binary: `ulimit -s 8192` refuses and exits 1, `ulimit -s 16384` runs the estimator to completion. `solve.c`'s own remedy line still prescribes only `unlimited` and is queued to offer both. This is the sibling propagation of the narrowing TR-9 made on 2026-09-02 and reported but did not sweep.)*

⚠ **`SOLVE_THREADS` is part of the reproduction, not a performance knob.** Every `--estimate-knuth`
command in this document now carries `SOLVE_THREADS=32`, the value the three archived runs used
(`reports/evidence/dav_tier1.out`, `dav2_tier1.out`, `db1_tier1.out`, each line 1: `threads=32`).
The estimator seeds worker *i* at `base ^ ((i+1)·0x9E3779B97F4A7C15)` (`solve.c`), and with
`SOLVE_THREADS` unset the thread count falls back to the running host's core count
(`sysconf(_SC_NPROCESSORS_ONLN)`, `solve.c`) — so the thread count selects the sample, and
[METHODS.md](METHODS.md) §"Reproducibility rule for estimator output" guarantees identical output only for re-runs at
identical *(probes, threads)*. Without the prefix a reader on a different host reproduces a
different draw. *(Added 2026-09-01 — see v1.13. The commands read without it from the report's
first landing.)*

- KW-value reproduction, two-language gate: `python3 solve.py --dav-verify` and `./solve --dav-verify`
  → `DAV VERIFY: PASS` (each of the nine candidates reproduces its expected King Wen value; solve.py
  is the spec, solve.c the engine)
- Population masses and histograms (§3 table): `SOLVE_THREADS=32 SOLVE_KNUTH_SCORE_DAV=1
  SOLVE_KNUTH_DAV_HIST=1 ./solve --estimate-knuth 2000000000` (evidence file: `dav_tier1.out`,
  tier-1 run 2026-07-04;
  self-validation: same run's canonical-leaf estimate 1.3275×10³⁸ vs [SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md)'s
  1.3287×10³⁸, 0.09%)
- Pre-registration prior to measurement: documentation/CRITIQUE.md §"Pre-registered tests … Davis
  (2012)" — registered at commit `2d19a3f` (2026-07-04) before any population number existed;
  thresholds and the nothing-promotes policy are in the registration text
- Corpus-control specificity gate: evaluate the `dav_*` predicates (solve.py) on the Jing Fang and
  Mawangdui orderings (the `--null-historical` data) → 0 on every flagged predicate (holds on both the
  pre- and post-2026-07-05-correction Mawangdui arrays; corrected-array non-flagged values: termruns 5,
  palnbr 13, asymhalf 7)
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
- Wave-2 KW-value reproduction, two-language gate: `python3 solve.py --dav2-verify` and
  `./solve --dav2-verify` → `DAV2 VERIFY: PASS` (`tquartet` = 1, `xunslots` = 5; solve.py is the
  spec, solve.c the engine)
- Wave-2 population masses and histograms (§3b table): `SOLVE_THREADS=32
  SOLVE_KNUTH_SCORE_DAV2=1 SOLVE_KNUTH_DAV2_HIST=1 ./solve --estimate-knuth 2000000000` (evidence file: `dav2_tier1.out`,
  tier-1 run 2026-07-11; self-validation: same run's canonical-leaf estimate 1.3275×10³⁸ vs
  [SEARCH_SPACE_SIZE.md](../documentation/SEARCH_SPACE_SIZE.md)'s 1.3287×10³⁸, 0.09%)
- The C-D5 power note (§3b) — self-contained; **requires no ROAE binary, no data files, and no
  implementation of the declined predicate** (which remains unimplemented everywhere). Inputs:
  hexagrams #9, #14, #26, #28, #34, #62, bit patterns 110111, 101111, 100111, 011110, 001111,
  001100 (bit 0 = bottom line, 1 = yang), labels S,B,B,B,B,S. (1) Six distinct pairs, by finger
  arithmetic: no couple among the six satisfies rev6(a) = b; the two palindromes (011110, 001100)
  pair by complement with #27 and #61, outside the set. (2) Exchangeability, purely analytic from
  the null's definition: a uniform bijection of 32 pairs onto 32 slots is invariant under
  relabeling the six marked pairs, so all 720 relative orders are equiprobable, and orientations
  cannot move a pair between slots. (3) The count — pure combinatorics, checkable with a few
  lines of the reviewer's own code:

  ```python
  from itertools import permutations
  labels = ('S', 'B', 'B', 'B', 'B', 'S')        # any 2-vs-4 labeling
  counts = {}
  for p in permutations(range(6)):               # the 720 relative orders
      s = tuple(labels[i] for i in p)
      counts[s] = counts.get(s, 0) + 1
  assert len(counts) == 15 and set(counts.values()) == {48}
  target = ('S', 'B', 'B', 'B', 'B', 'S')        # both minority labels at the extremes
  print(counts[target], "/ 720 =", counts[target] / 720)   # -> 48 / 720 = 1/15
  ```

  Conclusion: min-p = 1/15 > 0.05 > 0.05/12 — the declined test could never have produced a
  significant result under the stated null, whatever the labels mean.
- The D-B1 tautology (§3b): KW-value + classifier reproduction, two-language gate:
  `python3 solve.py --db1-verify` and `./solve --db1-verify` → `DB1 VERIFY: PASS` (Table 4.1
  reproduced 64/64; KW conformity X = 22, ten deviant pairs listed). Population descriptives:
  `SOLVE_THREADS=32 SOLVE_KNUTH_SCORE_DB1=1 SOLVE_KNUTH_DB1_HIST=1 ./solve --estimate-knuth
  2000000000` (evidence file: `db1_tier1.out`). The argmax verification is arithmetic on the received sequence alone:
  for each group, list its members' KW ordinals and check that Drasny's room is the
  maximum-coverage decade window (or step-10 window) for that list, with per-group coverages
  3+3+3+3+4+5 plus the residue conformity = 22

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | Initial private draft (roae-private staging); adversarial review pending before any public release |
| v1.1-draft | 2026-07-04 | Hostile pre-publication review pass: "strictest symmetry" page cite corrected (p. 112 → p. 96, verified against the book); "undeniably designed" (p. 116) re-scoped to the Big-and-Little group rather than the 7–16 block; §5(a) "came back null" corrected to reflect the one Bonferroni-notable row; §5(b) softened to "largely against him" with the trigarray exception stated, and mixed percentile conventions replaced by the table's tail masses; pureplace "exactly at threshold" → "at the threshold to reported precision" (measured 5.56×10⁻³ vs 0.05/9 = 5.56×10⁻³ at 3 s.f.). All table masses re-derived from dav_tier1.out; refutation and corpus-control numbers independently recomputed; both `--dav-verify` gates re-run (PASS) |
| v1.2 | 2026-07-05 | **Erratum (Mawangdui corpus control):** the project-wide Mawangdui array was found wrong (corrected 2026-07-05 per [Shaughnessy 2022](../documentation/CITATIONS.md#shaughnessy2022), Table 11.2 — see CITATIONS.md errata). The nine `dav_*` predicates were recomputed on the corrected array: every flagged predicate still evaluates to zero on Mawangdui (and Jing Fang, unaffected), so the specificity gate and all TR-10 verdicts stand unchanged. Non-flagged Mawangdui values shifted: palnbr 16 → 13 (termruns 5, asymhalf 7 unchanged) |
| v1.3 | 2026-07-11 | **Scope-decision note (§5(c)):** Davis's big/little named-hexagram size pattern (pp. 94–96), conditionally pre-registered as a follow-up candidate, was declined without measurement on 2026-07-11 — hexagram names (tradition/translation-dependent semantic attributes) are not admitted as predicate inputs, consistent with §5(c)'s published scope statement. The follow-up family's Bonferroni denominator stays frozen at /12. No measured number in this report changes |
| v1.4 | 2026-07-11 | Global-ledger qualifier on the trigarray "notable" (§3 row 3 + narrative): survives its family correction (0.05/9) but not the global 91-observable ledger (≈5.5×10⁻⁴ bar; measured 6.8×10⁻⁴) — see METHODS §"Global observable ledger". No measured number changes |
| v1.5 | 2026-07-12 | **Wave-2 addendum (§3b):** the §4 compactness thread closed by pre-registered measurement — `tquartet` NULL (a Davis-compact quartet is population-common, P(≥1) = 0.876; KW = 1 below the mean 1.86), `xunslots` NULL (p = 0.148, registered at low prior); Bonferroni 0.05/12 across both waves, frozen in advance; design frozen in a git-timestamped private pre-registration 2026-07-10, code public first (`09e2107`), results batch-landed. C-D5 decline (§5(c)) augmented with an analytic power note: min attainable p = 1/15 under the pair-exchangeable null, 16× the family gate — reproducible with no ROAE code (Verification Guide). Companion D-B1 paragraph (§3b): Drasny's Rule of Ten conformity count verified true (X = 22) and shown tautological — every room is the argmax decade window for its group's KW positions, so the count scores KW against a KW-extracted template; data-like, no p attached, separate Drasny family. Nothing promotes; no §3 number changes |
| v1.6 | 2026-07-20 | **Scope qualifier (adversarial-review F-34).** Added a masthead scope note: "archaeology" is figurative — the report measures notational and structural properties against the population of valid orderings and makes no historical, philological, or text-critical claim beyond what the combinatorics support. Title unchanged (the body is already well-scoped); the qualifier prevents the humanities register of the title from being over-read. No measurement changed |
| v1.7 | 2026-07-21 | **Wave-2 freeze re-anchored to the public record (adversarial-review F-22).** The §3b freeze passage no longer presents the private-repository pre-registration timestamp as the anti-HARKing guarantee — a private commit is unverifiable by external reviewers, and is now cited as provenance only, disclosable to an auditor. The guarantee is re-grounded entirely in publicly checkable facts: the complete wave-2 bank (both functional definitions, expected KW values, the two-language `--dav2-verify` gate, the C-D5 decline, and the /12 denominator) is fixed in public commit `09e2107`, which precedes the public results landing (`5ace541`); both results are nulls invariant under every multiple-comparisons convention (two-sided 0.849 and 0.148; smallest one-sided tail 7.4×10⁻², above even uncorrected 0.05), so no pre-measurement freeze is load-bearing for the verdicts; the operationalizations' free parameters are Davis's own (instance compactness; the p. 114 slot/class pattern), excluding tuning-toward-null; and the §4 window parenthetical is aligned with the same anchoring. Both `--dav2-verify` gates re-confirmed PASS (tquartet = 1, xunslots = 5). No measured number changes |
| v1.8 | 2026-08-01 | **Correction-family disclosure (statistics-methodology review, F3).** The trigarray global-ledger verdict is shown to be Bonferroni-specific: under Benjamini–Hochberg FDR at q = 0.05 against the same 91-observable ledger, `trigarray` (6.8×10⁻⁴) *would* be declared significant: BH rejects at every rank ≥ 2 (*i* = 2 already gives 1.1×10⁻³ > 6.8×10⁻⁴), and rank *i* = 1 is excluded by `rotinv` (6.5×10⁻⁵) in the same registered Davis family. *(Ranking support narrowed 2026-08-01, second pass: this row first read "at least twelve ledger values are strictly smaller, so its BH rank is i ≥ 13 … about 10× the measured p". The extra values were literature-rule registry masses outside the 91-observable roster plus two zero-sampled-mass entries; that "≈10×" margin is withdrawn. The verdict is unchanged — see [METHODS.md](METHODS.md) §"Global observable ledger".)* This is the ONLY verdict in the suite the correction family moves, and it moves the result most favourable to the hypothesis the suite argues against; the global-ledger layer was also added (2026-07-11) after the measurement it adjudicates. The FWER reading is retained as the conservative choice and the dependence is disclosed at §3, in the §3 table row, in the narrative, and in METHODS §"Correction-family disclosure". FWER clearance implies FDR clearance, so every claim reported as *clearing* the bar is unaffected. No measured number changes |
| v1.9 | 2026-08-06 | **Benjamini–Hochberg cited at point of use (citation audit, UNASKED-7).** §3's correction-family disclosure has invoked "Benjamini–Hochberg FDR" since v1.8 without a source; the reference ([Benjamini & Hochberg 1995](../documentation/CITATIONS.md#benjamini-hochberg1995), *JRSS-B* 57(1)) is now in CITATIONS.md §Statistical methodology and linked where the FDR verdict is stated. No verdict, rate, or measured number changed |
| v1.10 | 2026-08-06 | **TR-9 residual range propagated (MDL audit, mirrors TR-9 v1.22).** The Davis-predictions passage quoted TR-9's residual as "~105–127 bits"; TR-9 v1.22 widened the range to **105–139** (the former upper endpoint 126.6 retained the bit-cuts of C5 and C3, both of which TR-9 itself classifies as non-explanatory; the consistent endpoint is log₂\|C1∩C2∩C4\| = 139.1). The quoted range is updated; this report's own measurements, batteries, and verdicts are untouched — the widening strengthens the residual claim this report's null results support |
| v1.11 | 2026-08-30 | **The standard-error claim is corrected: no PUBLISHED artifact carries `se=`.** §3 said masses "each now carr[y] a delta-method standard error (printed as `se=` by the estimator since 2026-08-28)" — true of the estimator, false of the evidence: `reports/evidence/dav_tier1.out` (2026-07-04) and `dav2_tier1.out` (2026-07-12) both predate that capability and contain **zero** `se=` fields, so a reader opening either finds no standard errors. The regeneration command is now given in-line per the published-numbers-need-code rule; the archived files are retained as original evidence and are NOT restated. No mass, verdict, or classification changes — `rotinv`'s ≈2.3 SE margin and the "no published classification changes" conclusion both stand. Found by Codex v2 |
| v1.12 | 2026-09-01 | **Null-sensitivity disclosed for §3 rows 6–7; sidedness attribution corrected; one-sided-only rows completed.** (a) §3 gains a null-sensitivity note: the scoreboard's classifications are relative to the pre-registered C1–C5 null, and two rows reverse under the suite's own second null ([METHODS.md](METHODS.md) §"Permutation-test nulls", measured by [TR-8](TR8_REORDERING_REVISITED.md) §2). Exact rationals over slot arrangements, both predicates being orientation-invariant: `rotinv` = 2/C(31,4) = 6.356×10⁻⁵ under C1+C4 and 2/C(32,4) = 5.562×10⁻⁵ under C1, both **below** the 10⁻⁴ candidate bar its C1–C5 figure (1.31×10⁻⁴) misses; `pureplace` = 2·7/35,960 = 3.893×10⁻⁴ under C1, clearing both the 0.05/9 and the 0.05/91 bars against the published **NULL**, but NULL again at 2·14/4,495 = 6.229×10⁻³ once C4 is added — the whole ×16.0 being C4's pinning of block {63,0} to slot 1, half of the placement `pureplace` tests. Rows 6 and 7 now carry a `null-sensitive` marker. **No published mass is wrong** (each is correct under its stated null) and **nothing promotes** under any of the three nulls — both rows are KW-extracted exact templates, the data-like class. (b) Row 6's 2026-08-28 note asserted "The bar declared at §3 is **two-sided** p < 10⁻⁴", contradicting this report's own Abstract, which records the < 10⁻⁴ candidate bar as inherited from F4′ "with sidedness unstated there"; the two-sided reading is retained as the suite's operating convention but is no longer attributed to the bar's registration, and the row does not promote under either reading. (c) Rows 2, 3, 5 and 9 published a one-sided tail only, where row 1 already carried both; the two-sided atom-inclusive values (2.24×10⁻², 1.36×10⁻³, 1.57×10⁻¹, 3.90×10⁻¹) are added from `reports/evidence/dav_tier1.out` — **no verdict moves**. Row 3 additionally carries a sidedness flag: the v1.8 BH-FDR counterfactual is computed on one-sided masses and does not hold two-sided (1.36×10⁻³ vs 2·(0.05/91) = 1.10×10⁻³); the published Bonferroni verdict is unchanged and the BH leg is flagged for adjudication, not restated. Regeneration for every mass: `SOLVE_THREADS=32 SOLVE_KNUTH_SCORE_DAV=1 SOLVE_KNUTH_DAV_HIST=1 ./solve --estimate-knuth 2000000000` (thread count added 2026-09-01 — see v1.13); the closed forms are checkable by hand from the predicate definitions in `solve.py` (`dav_rotinv`, `dav_pureplace`) |
| v1.13 | 2026-09-01 | **Reproduction commands carry their thread count; the undocumented in-place corrections are entered in this table; the power note's comparative magnitude claim is withdrawn.** (a) **`SOLVE_THREADS=32` added to all five `--estimate-knuth` commands in this report** (§3's `se=` regeneration line and the four Verification-Guide lines — including the regeneration command v1.12 itself published without it, which is the defect v1.12 was correcting reproduced one row lower). The thread count is not a performance knob: the estimator seeds worker *i* at `base ^ ((i+1)·0x9E3779B97F4A7C15)` and, with `SOLVE_THREADS` unset, takes the thread count from `sysconf(_SC_NPROCESSORS_ONLN)` (both in `solve.c`), so the thread count selects the sample; [METHODS.md](METHODS.md) §"Knuth estimator CIs" guarantees identical output only at identical *(probes, threads)*. 32 is the value all three archived runs used (`reports/evidence/dav_tier1.out`, `dav2_tier1.out`, `db1_tier1.out`, each line 1: `threads=32`). A Verification-Guide warning now states the rule once. No mass, verdict or classification changes — this makes the published masses reproducible, which they were not. (b) **Revision-history coverage completed.** Per [reports/README.md](README.md) §"Living documents" every content change takes a Revision History entry; five in-place corrections carrying their own dated markers had none. They are entered here rather than back-dated: **2026-08-21** — the `ulimit -s unlimited` requirement added to the Verification Guide (execution-lane finding); **2026-08-28** — §3 row 6 (`rotinv`) re-read two-sided, §3 row 7 (`pureplace`) moved from borderline to NULL, and §5's nine-row summary re-counted to match (five null, one notable, three data-like); **2026-08-29** — §4's conditioning set named as C1–C5 rather than as classical. A sixth, the Abstract's 2026-08-01 adjective correction about the 0.09% cross-check, falls on the same date as v1.8 but is not described by it; it is named here for the same reason. No number or verdict is touched by (b). (c) **§3b power note narrowed.** The analytic power note closed with a comparative magnitude claim ranging over a statistic this repository never defines and never publishes — a search of the public tree returns the claim site alone — so a reader could neither check nor falsify it. It is withdrawn and not restated. The note now asserts only what it establishes: min-p = 1/15 is **exact** under the pair-exchangeable (C1-only) null, and the perturbation from the fuller C1–C5 conditioning is **unmeasured for this predicate class**. The lead-in sentence is scoped to that null to match, and the reader is pointed at v1.12's own null-sensitivity table, where C4 alone moves `pureplace` by ×16.0 — a different predicate class that does not transfer, which is exactly why no untested bound is claimed. The declined test stays declined on the §5(c) scope grounds, which never depended on the power note. Found by Codex v2 (V2-F01 #2–#4). |
| v1.14 *(current)* | 2026-09-02 | **Stack requirement narrowed to what the binary enforces (prose batch P37, Codex V2-F08 #4; wording only).** The `--estimate-knuth` warning published `ulimit -s unlimited` as REQUIRED. It is a **sufficient** setting, not a necessary one, and on a host or container whose hard limit forbids `unlimited` the published requirement was a false blocker. `solve.c`'s preflight tests `rlim_cur != RLIM_INFINITY && rlim_cur < 16UL*1024*1024` and its message names ">= 16 MB"; executed under TR-9 v1.24, `ulimit -s 8192` refuses and exits 1 while `ulimit -s 16384` runs the estimator to completion. The banner now states "at least 16 MB (`ulimit -s 16384` suffices)" with `unlimited` named as one sufficient setting. This is the sibling sweep TR-9 v1.24 reported but did not perform. No figure, count, command, claim or scope changes |
