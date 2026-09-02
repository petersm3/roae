# Known Limitations

> **Note (2026-04-19; d3 sha updated 2026-05-13):** Canonical reference counts: d3 10T = **706,427,594** (sha `b85c8871…`, re-established 2026-05-13 on post-resume-fix code; the original 2026-04-19 figure 706,422,987/`f7b8c4fb…` is deprecated — see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Deprecated), d2 10T = **286,357,503** (sha `a09280fb…`, still valid). Older 742M figure (hash-table bug) superseded. **New partition-stability finding** from the 2026-04-19 analyze runs: boundaries {25, 27} are mandatory at BOTH d2 and d3 scales (stable), but the broader 4-boundary structure (`one-of-{2,3} ∪ one-of-{21,22}`) is **d2-specific**; at d3 the interchangeable boundaries are in the {1..6} range. Any claim involving specific boundaries beyond {25, 27} must be scoped to the partition depth. See updated sections below.
>
> **Note (2026-06-08): 560T canonical landed.** A new d3 560T canonical (sha `9a968fa2…`, 10,525,271,997 orderings) became the deepest published enumeration on 2026-06-08, 3.07× the 100T scale. The findings below were originally computed on the 100T canonical (`915abf30…`); the 560T `--analyze` pass (3 h 47 m on D128 with the rewrite commits 8ac5e8f/fe58e71/bf8d8a5/c0ec4c3) completed 2026-06-11. **Findings whose validity is robust under the 100T → 560T extension** (because the 100T solution set is a strict subset of the 560T set): KW's membership in the canonical, KW vs C3-ceiling, mandatory boundaries {25, 27}, partition-stability claims — all reaffirmed at 560T. **Findings that shifted at 560T**: top pairwise-MI ranks, working-4-subset count. The boundary-minimum did NOT shift: it is 5 at both 100T and 560T with the identical set *(corrected 2026-07-04 — an earlier version of this note listed boundary-minimum among the shifted findings based on a survivor-counting error; see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md))*. Each is flagged inline where mentioned.
>
> **Update (2026-06-11, corrected 2026-07-04): full 560T `--analyze` complete.** `verify.py --jobs 64` PASS on all 10,525,271,997 records. The complete analyze shows: **§[6] greedy-ordered minimum = 5**, set **{4, 27, 25, 21, 1}** (boundary 4 alone eliminates 99.999% of non-KW; 27 → 481 survivors; 25 → 14; 21 → 1; boundary 1 eliminates the last impostor, rec#330177707 — KW with the position-2/3 pair blocks swapped) — identical in membership and greedy order to 100T. **§[7] no 3-tuple works** (best 3-set leaves 15 survivors — no 3-subset isolates KW at 560T; minimum ≥ 4). **§[8] = 0 working 4-subsets** (down from 4 at 742M and 8 at 11.2T) — at 560T no 4-tuple of boundaries jointly reduces survivors to ≤ 1, consistent with the §[6] minimum of 5. **This makes "4-set uniquely identifies KW" a scale-bounded framing; at canonical depth the minimum is 5.** *(Correction 2026-07-04: the 2026-06-11 version of this update reported "§[6] greedy-ordered minimum = 4" — a survivor-counting error that stopped at 1 remaining non-KW survivor instead of 0; the 2026-06-09 partial reading "boundary-minimum is still ≥ 5" had in fact been right. See [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md).)* §[9]: `{25, 27}` is one of the most-INFORMATIONALLY-INDEPENDENT boundary pairs (ratio 0.007), quantifying why those two keep appearing in every minimum set. §[10] top pairwise MI: pos 12 ↔ 13 = 1.3417 bits (cascade-region 11–20 dominates the top-10). §[18] boundary 4 alone yields 45.14 bits of conditional-entropy information gain — over half the 77.81-bit total. §[28] edit-distance mode is at **30** (2.79 B records = 26.5% of all canonicals). Full findings: see [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) §"560T canonical results" + [HISTORY.md](HISTORY.md) "June 10-11, 2026" entry.

A review of the program's methodology, assumptions, and interpretive claims from a mathematical perspective.

This document records limitations that are **live** — things the current results do not settle. Claims that were published and have since been withdrawn, rescoped or corrected are a different category and live in [CORRECTIONS.md](CORRECTIONS.md), the append-only corrections record.

## Data correctness

- The binary hexagram encodings follow [OEIS A102241](https://oeis.org/A102241) with bit 0 = bottom line. Sensitivity analysis confirms the difference wave, pair structure, and no-5 property are all invariant under bit reversal (since Hamming distance is invariant under bit permutation). Trigram assignments do change under reversal, affecting display labels but not mathematical results.
- The hexagram labels are **derived from the two trigrams** ("Heaven over Heaven", "Water over
  Thunder"), composed from the eight standard trigram glosses. They are descriptions of structure,
  not a translation of the traditional titles. Until 2026-08-27 this repository shipped the
  Wilhelm/Baynes English titles, which are under copyright; they were removed rather than replaced
  with another translation, since no result here depends on a hexagram's English name. A rigorous treatment would cite each name individually, not give a blanket attribution.
- The [Mawangdui](https://en.wikipedia.org/wiki/Mawangdui_Silk_Texts) ordering used from 2026-04-06 to 2026-07-05 was **wrong** (a mis-synthesized array, not the manuscript's); it was corrected 2026-07-05 to the sequence in [Shaughnessy 2022](CITATIONS.md#shaughnessy2022) (Brill), p. 50 + Table 11.2, verified against multiple independent sources. Every published Mawangdui-derived number was recomputed; the former "Mawangdui satisfies C2" claim is withdrawn (the authentic order has exactly one 5-line transition, at a trigram-octet seam).
- The sequence is traditionally attributed to [King Wen of Zhou](https://en.wikipedia.org/wiki/King_Wen_of_Zhou) (~1000 BCE), but modern scholarship is divided on the exact origin, authorship, and dating. The attestation record behind that hedge ([Shaughnessy 2022, ch. 11](CITATIONS.md#shaughnessy2022)): the earliest artifactual witness of the received sequence is the Xiping Stone Classics (175–183 CE), with the fragmentary Fuyang *Zhouyi* (tomb dated 165 BCE) an earlier partial witness. The Mawangdui silk manuscript (copied before 168 BCE) attests a *different* ordering still in circulation in the early Han. Earlier manuscripts exist — the Shanghai Museum Chu bamboo *Zhouyi* is c. 300 BCE, the earliest known — but their hexagram *order* is not recoverable: the Chu strips preserve 34 of 64 hexagrams, came out of the ground unbound and disordered, and their published arrangement is the modern editor's own, taken from the received sequence ([Pu Maozuo 2003](CITATIONS.md#pu2003), p. 135). The program uses the traditional attribution as a label without taking a position on historicity. **Full dated record and scope statement: [KING_WEN_PROVENANCE.md](KING_WEN_PROVENANCE.md).**

## Statistical methodology

- The entropy analysis now includes both unconstrained and pair-constrained null models. King Wen remains more structured than random under both (12th and 6th percentile respectively), but neither survives [Bonferroni](CITATIONS.md#bonferroni1936) correction (p > 0.0018).
- The autocorrelation uses the biased estimator (divides by n rather than n-lag), which attenuates values at higher lags. This is the standard estimator but may understate weak periodicity.
- The DFT significance threshold (2x noise floor) is ad hoc. A proper test would use Fisher's g-statistic or Bonferroni correction across frequency bins.
- The DNA codon mapping uses one of 24 possible bit-to-base assignments. Different mappings produce different results. The comparison is illustrative, not evidence of a biological connection.
- The bootstrap confidence intervals measure Monte Carlo estimation precision (how much the estimate would vary if you re-ran the simulation), not fundamental uncertainty about the true proportion. Increasing `--trials` narrows the CIs because the estimate becomes more precise, not because the underlying truth is better known.
- The palindrome analysis now includes both unconstrained and pair-constrained null models. Under pair-constrained comparison, King Wen's palindrome count is at the 49th percentile (completely typical) and longest palindrome at the 14th percentile (somewhat low but not significant).
- The Hamming distance matrix is a fixed property of the 6-bit binary system, identical for any ordering of the 64 hexagrams. Only which hexagrams are adjacent depends on the ordering.
- Trigram transition matrices have ~1 expected observation per cell, so no goodness-of-fit test (chi-square, etc.) has sufficient power to detect deviations. The matrices are descriptive only.
- Windowed entropy is exploratory visualization without a null model or significance test. Apparent patterns in the curve are expected from random variation.
- The full 8-state mutual information between upper and lower trigrams is zero by construction: all 64 hexagrams span every possible (upper, lower) trigram combination exactly once, forming a complete [Latin square](https://en.wikipedia.org/wiki/Latin_square) (an 8×8 grid where each of the 8 trigrams appears exactly once in each row and column). Independence is automatic for any set containing all 64 distinct 6-bit values — it is a property of the binary encoding, not of King Wen's ordering.

### Observable-selection accounting (the look-elsewhere effect) — added 2026-07-02

The constraint set C1–C5 was *selected* after an exploratory sweep of many observables (the **28
exploratory discovery-phase observables** of the frozen global ledger — the roae.py sweep; roae.py
today exposes 29 CLI sections, but the 29th, `--parity` (added 2026-05-19), is theorem-backed —
deductive, no p-value — and so sits outside this statistical accounting, exactly as the wrap-parity
and parity-alternation theorems do below). Adding the
five later pre-registered testing
families (F5 /11, F4′ /13, Davis /9, Davis follow-up /12, permutation /13 — 58 observables) on top of
that discovery-phase
battery brought the running total to 86 (28 + 58); the R7 corpus-control battery's five off-home family predicates
applied to King Wen (J1, M1, M3, M4, B1 — all expected-fail, all failed; see §"Corpus control II" below)
bring the enterprise-wide total to **exactly 91 observables** (28 + 58 + 5, frozen) *(scope disclosure, 2026-08-01: 91 counts tests registered under corrections, and contains two offsetting errors — the Davis "/12" family subsumes the "/9", so the distinct-id count is **82**; and an omitted books family of 7 would make "everything examined" **89**. The bars span 5.49–6.10×10⁻⁴, an 11% spread, and **no published verdict differs between them**, so 0.05/91 is retained as the strictest defensible value. Full statement and the counting rule: [METHODS.md](../reports/METHODS.md) §"Global observable ledger")* — the global ledger that
[reports/METHODS.md](../reports/METHODS.md) §"Global observable ledger" applies (global bar 0.05/91 ≈
5.5×10⁻⁴; distinct from the discovery-battery threshold used just below). Selecting the most striking properties from a
battery and then testing them on the same sequence inflates apparent significance; a referee is entitled to
demand multiple-comparisons accounting across the *whole battery*, not just per-test corrections. Applying
the project's own Bonferroni threshold (p < 0.05/28 ≈ 0.0018) across everything examined:

- **Survives (both the 0.0018 battery bar and the 5.5×10⁻⁴ global bar), by wide margins:** C1 (pair
  structure, ~10⁻⁴⁴ under the random null; 0 of 1.86 B across six structured families; analytically
  impossible in two of them — clears both bars by ~40 orders of magnitude); C3's **unconditional** rarity
  (0.002836% ≈ 2.8×10⁻⁵ under the unconstrained random null, 28,356 of 10⁹ — see the family table under
  §Missing analyses below); and the Gray-code C3 **rate** bound, **scoped to its sampler** (0 of 10⁵ sampled Gray codes satisfy C3 ≤ 776; rule-of-three upper bound 3/10⁵ = 3×10⁻⁵ on *that sampler's* rate) ⚠ **[CORRECTED 2026-08-28 — this read "the Gray-code **minimum**-C3 bound (minimum across 10⁵ samples = 832 > 776, CI ≤ 3×10⁻⁵)", which converts a RATE bound into a MINIMUM bound. Both `solve.c:11465` and `HISTORY.md:409` say *rate*; only this line said *minimum*. **A sample minimum is an upper bound on the true minimum, never a lower bound**: observing 832 across 10⁵ draws shows the family minimum is ≤ 832 and is entirely consistent with its being below 776, which is the direction the sentence was being read in. Coverage is 10⁵ of ~10²², i.e. ~10⁻¹⁷ of the family. Separately, `solve.c:11465` prints **"Non-uniform sampler"** and `HISTORY.md:409` calls it **"biased"**, so the rule-of-three figure bounds the rate under the *sampler's induced distribution*, not under the uniform Gray-code family — a qualifier this line dropped. What survives is the scoped rate statement above; **the minimum claim does not survive at all**, and this item's standing among the battery-bar survivors rests on the rate half alone. See CORRECTIONS.md 2026-08-28.]** The
  wrap-parity and parity-alternation results are theorems (deductive), outside statistical accounting
  entirely.
- **Precisely measured, but does NOT clear the corrected bar as KW-evidence** (re-graded 2026-07-26 for
  self-consistency under the stated bars; an earlier version of this section graded these as "survives"):
  C2's conditional rarity given C1 (4.29% on a 10⁹ sample — the standard error is negligible, so the
  *measurement* is precise, but 0.043 ≫ 0.0018) and C3's conditional placements (8.1% exact under the bare
  C1&C4 null, `verify.py --check-null-g`; 3.9th percentile, sampled, at the C1+C2+C4+C5 scope — **flagged 2026-08-01: not supported by that population, ledger ≈12%, see [SOLVE.md](SOLVE.md) §Rule 3** — scope
  label corrected 2026-07-22; the *threshold's* circularity is a separate, already-documented limitation).
  These are the same order of magnitude as the runs-test p = 0.033 graded non-surviving below, and fail
  the p < 0.0018 bar alike; measurement precision is not battery-wide significance. This matches TR-9's
  bits accounting exactly (C2 ≈ break-even; C3's marginal bits priced as data, not claimed).
- **Does NOT survive, and was already reported as such:** the runs-test alternation (p = 0.033), entropy
  percentiles (12th/6th), palindrome statistics, the canon-split gap, Markov structure, recurrence and
  clustering measures — all flagged non-significant or within-chance in this document's sections above.
- **Not applicable:** C4 (its pair choice is classically attested — *Xugua* — rather than selected from the
  battery) and C5 (descriptive by construction: it is the sequence's own histogram, priced honestly by the
  null-model caveat below rather than by a significance test).

The accounting therefore *changes no conclusion*, but it sharpens the headline: as KW-evidence, the
statistical case rests on C1 — which clears the battery-wide bar by ~40 orders of magnitude — together
with the unconditional C3 rarity and the deductive layer. After conditioning on C1, no additional
constraint's KW-compliance rate clears the corrected bar; those rates are precisely-measured effect
sizes, priced as such (exactly as TR-9's bits accounting concludes). Every marginal observation was
already labeled as non-surviving where it appears. The point of stating this explicitly is procedural
honesty: the survivors were selected from a large explored battery, and their significance claims are
made net of that selection.

## Analytical claims

- The claim that "the designers appear to have been working with a sophisticated understanding of combinatorial structure" is an inference, not a finding. The pair structure could arise from a simple rule ("always place a hexagram next to its mirror or opposite") without any understanding of combinatorics. "Designed" could also mean iterative cultural refinement rather than a single deliberate act.
- The nuclear hexagram chain structure is a fixed function of binary values, independent of the King Wen ordering. The chains, cycle lengths, and frequency distribution are identical for any ordering of the 64 hexagrams. The program now notes this explicitly.
- The no-5-line-transition property, while real, is largely explained by the pair structure: ~4% of pair-constrained orderings also avoid 5-line transitions. Within reverse/inverse pairs, 5-line transitions are mathematically impossible (Hamming distances are always even or 6).
- The complement distance analysis shows King Wen places complements significantly closer together than random (0th percentile) — a strong structural regularity in how opposites are placed. This is a genuine finding *at this scope* (**unconstrained** random permutations as the reference — the population the `--complements` section itself computes against). ⚠ It is **not** the pair-constrained scope: under the exact C1&C4 null the C3 tail is **8.106%**, not a 0th percentile (`verify.py --check-null-g`), and at C1–C5 canonical scope King Wen sits at the C3 **ceiling**, not the floor. The constraint solver (`solve.py`) further shows that among orderings satisfying every other rule, King Wen's complement distance is at the **3.9th percentile** — it sits in the lower 4% of complement distances within that population (sampled; exact confirmation pending). *(**Flagged 2026-08-01, lens sweep** — the 3.9th-percentile figure is not supported by the population it is labelled with; the suite's own ledger gives ≈12% at this scope. Do not cite it: see [SOLVE.md](SOLVE.md) §Rule 3.)* **Scope note**: this percentile claim is against the all-other-rules population (**C1+C2+C4+C5** in the formal naming — every constraint except C3 itself; corrected 2026-07-22, an earlier version of this note said "C1+C2+C5"), *before* C3 ≤ 776 is applied. Once C3 is added — using KW's exact value of 776 as the ceiling — KW sits at the C3 maximum (~340M of 3.43B canonical orderings tie with KW at 776; minimum is 424). The "actively minimizes" framing is appropriate against the Rules 1-6 reference but NOT against the C1–C5 canonical; see [SOLVE_SUMMARY.md §Rule 3](SOLVE_SUMMARY.md) for the resolved framing and §Open question 11 below for the C3-ceiling finding.
- The canon comparison (Upper vs Lower Canon) shows no statistically significant difference in mean line-change differences between the two halves (~12th percentile). The traditional split does not correspond to a structural boundary.
- The recurrence rate is at the 72nd percentile — within the range expected by chance.
- Neighborhood clustering (Hamming-1 neighbors) is at the 12th percentile — closer than average but within chance expectations.
- The Gray code comparison is descriptive only; for significance testing of path length see the path analysis section.
- **The binary/Hamming vocabulary is partly anachronistic — and which parts matter.** Describing hexagrams as 6-bit words and line differences as Hamming distances is a 20th-century re-description; no classical author reasons in these terms (compare the cycle-structure test below, kept report-only precisely because the binary indexing postdates King Wen by ~2 millennia). But the anachronism is not uniform across the constraint set. The underlying quantity "number of lines changed between two hexagrams" — the atom C2 and C5 are built from — is not a purely etic imposition: it has an emic counterpart in the tradition's own moving-line (變) apparatus, in which divination practice tracks which and how many lines change in a hexagram's transformation into another (the derived hexagram, 之卦). Counting changed lines is a quantity the tradition itself handled; "Hamming distance" is our name for it. Applying that count to *sequence-adjacent* hexagrams is still our move, and the rest of the frame has no such counterpart: positional distance between complements (C3) and the exact-multiset accounting of transition sizes (C5's bookkeeping, as opposed to its atom) are etic instruments with no classical analogue known to us. Nothing in the enumeration or the measurements depends on this distinction — but any reading of the constraints as quantities the arrangers could have been tracking does, and it runs through C2's emic atom, not through C3 or C5.

## Computational methodology and self-correction

- **Earlier "31.6M" and "742M" lower bounds were both wrong** — 31.6M was a ~23× undercount from a sub-branch filename collision bug (fixed commit 585880f); 742M was a further undercount from a hash-table probe-cap bug (fixed commit b598067). Both deterministic bugs produced stable sha256s across runs, illustrating the methodological point: **a reproducible sha256 is not a proof of correctness; it only proves the bug, if any, is reproducible**. Both caught only by output-shape sanity checks. The current canonical figures (3.43B d3 100T, 706M d3 10T, 286M d2 10T) come from the fully-fixed solver with format v1 and have been cross-validated across 3 independent merge paths. See [HISTORY.md](HISTORY.md) for the forensic narrative.
- **The enumerated slice is ≈1 part in 10²⁷ of the C1–C5 space (added 2026-07-01).** An unbiased Monte-Carlo tree-size estimate (Knuth random-probe, validated <1% against exact subtree counts) puts the total number of C1–C5-satisfying orderings at ≈10³⁸ (≈3×10³⁷ distinct-canonical). The deepest published canonical (560T, 1.05×10¹⁰ records) has therefore enumerated ≈1 part in 10²⁷ of the space, and no first-level branch (~2×10³⁶) is remotely exhaustible. Two honesty consequences: (1) every count reported here is a lower bound over a budget-defined slice, not a fraction of "all solutions"; and (2) King Wen's significance is necessarily about *where it sits* among astronomically many valid orderings (its near-extremal structural properties), never about being rare or hard to find — it is an easily-reached member of a vast set. This is an estimate, not a proven cardinality. See [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md). ⚠ **[WITHDRAWN 2026-08-24 — this figure exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]**
- **"King Wen is found early in enumeration" is an artifact of the search setup, not a property of King Wen (added 2026-07-01).** That the enumeration surfaces King Wen after ~10¹⁰ records rather than ~10³⁸ is a consequence of three *setup* choices — the constraints (which make solutions dense, and which were reverse-engineered from King Wen so it is a member by construction), the per-cell decomposition (which guarantees King Wen's region is visited regardless of branch order), and the natural variable/value ordering (which places King Wen's leaf inside its cell's budgeted frontier). A different ordering, or a single global budget instead of per-cell breadth, could make a finite-budget search reach King Wen far more slowly or exclude its specific leaf entirely. **This affects no result**, because the findings are relative comparisons over the enumerated set computed with King Wen held known (it is a verified input, not a search target), and are therefore invariant to traversal order — a search that took years to reach King Wen would prove nothing new about it. The claim "King Wen is significant" was never "it is hard to find." See [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md) §"Is finding King Wen early … an artifact of our setup?".
- **Archive integrity is not equivalent to source integrity** (lesson added 2026-04-21). The 2026-04-21 archive of d2/d3 10T artifacts onto `solver-data-westus3` passed a sha256-manifest verification step before the source disks were deleted — but the VM hosting the archive write was then torn down with `az vm delete` *without* a `sync && umount`. On remount (2026-04-21), 4 of 57,754 gzipped files were discovered truncated (`gzip -t` failed with "unexpected end of file"). The scientifically-critical `solutions.bin.gz` for both datasets passed and re-hashed to canonical. The 2 unrecoverable losses were enumeration stdout logs with no raw source preserved; the other 2 were redundant checkpoint gzips (raw `.txt` preserved alongside). Methodological lesson: sha256 manifests written from a live page-cache state can hash dirty pages that were never successfully committed to disk. Any archive-integrity workflow must either (a) sync+umount+remount before hashing, or (b) at minimum `sync` before hashing and accept the limitation. See [HISTORY.md](HISTORY.md) §April 21 evening for the full incident narrative and the standing-rule remediation.
- **The "shift pattern observed universally" claim is scope-sensitive.** At the d2 10T canonical dataset, 2.69% of valid orderings are fully shift-conforming. At d3 10T, that drops to **0.062%** — 43× rarer at deeper partition sampling. The pattern is a local property satisfied by a small and shrinking fraction of the broader space. Anything in `--prove-cascade` that depended on shift-pattern universality should be read as scoped to that subspace, not the full solution space.
- **Per-branch yield labels in the canonical are scope-bounded by per-branch budget, not by branch yield (added 2026-04-29).** The d3 100T canonical (`915abf30…`) classified sub-branch `22_0_30_1_20_0` as a "yield-16 laggard" — 16 unique solutions in its 632 M-per-branch budget allocation. A subsequent single-branch deep-walk pilot at 100 T total budget (40 G per (p4, o4, p5, o5) cell) found **664,086,250 unique canonical orderings** in this *same* sub-branch (sha `52c8d308257d3b75041d0743b4b02a37360fe6567fec7c1c07ed49d8d22a29b9`, 20 GB). The canonical's "yield-16" was a ~50,000,000× truncation, not an honest yield. Implication: the canonical's full-space totals (3.43 B at d3 100T, 706 M at d3 10T, 286 M at d2 10T) are similarly subject to per-branch truncation; their counts are accurate only as **lower bounds** under the partition-budget regime that produced them, not as solution-space cardinality. This does NOT affect the partition-stable findings (`{25, 27}` mandatory boundaries, KW position-1 forcing, the yield-DENSITY-class results, etc.) — those depend on relative comparisons within the same uniformly-truncated dataset. It DOES affect any claim about absolute yield counts or branch-comparison ranking by yield. Cross-branch generalization of this finding (whether all yield-X laggards show similar truncation) is open; a 56 × 10 T per-first-level-branch experiment is queued. See [HISTORY.md](HISTORY.md) §April 28-29 for the full pilot details.
- **Boundary constraint claims must be scoped to the partition depth AND to "ordered" vs "unordered" framing.** The claim "2 adjacency constraints suffice" (early sample) was undersampling. The claim "4 boundaries minimum, specifically `{25,27} ∪ one-of-{2,3} ∪ one-of-{21,22}`" was d2-specific. At d3 10T, there are **8 working unordered 4-subsets**. At d3 100T no 4-subset suffices; greedy-optimal was a 5-set `{1, 4, 21, 25, 27}`. **At d3 560T (current deepest): greedy minimum stays 5 with the identical set `{4, 27, 25, 21, 1}` (that greedy order); working-4-subset count = 0** (down from 8 at 11.2T and 4 at 742M) *(corrected 2026-07-04: previously stated "drops back to 4 at 560T" — a survivor-counting error; see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md))*. So the "exact 4-set uniquely identifies KW" framing is scale-bounded — true at 10T, false at 100T and 560T, where the minimum is 5. Boundaries {25, 27} are present in the greedy-ordered minimum set at every partition tested (the partition-stable claim is robust).
- **`--prove-cascade` proves a narrower claim than its earlier framing implied.** The "16 of 31 branches budget-deterministic" result is correct *within* a 2-candidate-per-position shift-pattern subspace. Across the full canonical solution spaces (d2 and d3), every reachable first-level branch admits multiple distinct configurations at positions 3-19; none have exactly 1.
- **Complement is NOT closed in either canonical dataset — but the published 0 was FORCED, not measured (corrected 2026-08-28).** The conclusion stands and the reasoning behind it did not. What was published: "at both d2 and d3, 0 of the records have their complement partner in the set … a structural property of the constraints, not a contingent observation." That 0 came from `solve.c` §20, and **§20 could not have returned anything else**. C4 pins position 1 to the pair (63,0) in every record, so every record shares byte 0; that pair is self-complementary (63^0x3F = 0, 0^0x3F = 63) with `orient_flip=1`, so the complement image differs from the universal byte 0 in exactly the orientation bit — on every record, in every dataset, under a correct solver or a broken one. The section's own comment claimed it "doubles as a VALIDATION CHECK" for solver bugs; it never could. Its search was also unsound on its own array (`memcmp` against a `compare_solutions`-sorted file, whose primary key masks the orientation bits). **What survives:** complement is genuinely not closed, and no "self-dual" framing of King Wen under complement is correct — because complementing flips the C4-pinned position-1 orientation, so no complement image satisfies C4. **What does not:** this is a restatement of C4, and is **not** evidence that complement fails to preserve C3, which is what the sentence implied and what would have been interesting. Whether the complement's *pair sequence* recurs in the set under some other orientation is the non-forced version of the question; §20 now measures that instead and announces `COMPLEMENT_ORBIT=ANCHOR_FORCED` rather than printing a bare 0. No figure is published for it here until a run reports one. See [CORRECTIONS.md](CORRECTIONS.md).
- **Partition invariance verified at depth-3 strategy level (2026-04-30).** The `--double-regression-test` mode produced sha `c34390c00a2a871d78f49dd419779c0f649ed8271387c424ac4d36e0f3910dbd` (467,483,137 canonical orderings, 14.96 GB) across 4 paths: full-enum layer 1, full-enum layer 2 (deterministic re-run), `--merge-layers` of both full-enum layers, AND `--merge-layers` of 56 first-level `--branch p1 o1` reconstruction layers. All four match. This empirically confirms that at depth-3 with controlled per-sub-branch budget (`SOLVE_PER_SUB_BRANCH_LIMIT=35361572`), the choice between full-enum and 56-branch-reconstruction does NOT affect the canonical sha — strengthening the [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) theorem's empirical foundation. **What this verifies:** reproducibility, determinism, layered-merge correctness. **What it does NOT verify:** absolute count completeness (the 467 M is a lower bound at this budget, like the other canonicals), or that the chosen rule set C1-C5 is itself complete (see [BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md) §"What we've found so far" for the open-question framing). The verification surfaced and fixed a depth-2 bug in `--branch` (commit `cdd8575`); prior 2026-04-29 attempts were INCONCLUSIVE because of that bug. See [HISTORY.md](HISTORY.md) §"April 29, 2026" for the retrospective.
- **A pre-registered budgeted-yield model, refuted (2026-07-10).** A truncated-Galton-Watson account of budgeted per-cell yield (heavy-tailed subtree sizes + independent-offspring extinction, pre-registered with two falsification gates before its measurement run) was tested against a 2×10¹⁰-probe per-depth offspring profile and 5×10,000-root subtree samples. Both gates failed decisively: the measured subtree-size tail at fixed depth is light (Hill α̂ ≈ 3.2 in the registered window, vs the required α̂ ∈ [0.25, 0.45]), and the independence extinction recursion predicts ≈0% zero-yield cells where 59–75% are measured. The zero-yield census and the yield spread are therefore driven by *path-correlated* pruning (the C5 budget state travels down the path; lean regions stay lean), not by heavy-tailed subtree sizes. Evidence: `reports/evidence/r5/`; the independence assumption, not the data pipeline, is the refuted ingredient (the instrument passed three internal closure checks). This is a rejected hypothesis honestly recorded, not a finding; it changes no published result and closes nothing beyond the model it names.

## Missing analyses

- **Structured-permutation null models (comprehensively addressed 2026-04-19).** Seven null-model families are now tested via `solve.c --null-debruijn-exact`, `--null-gray`, `--null-latin`, `--null-lex`, `--null-historical`, `--null-random`, `--null-pair-constrained`, plus a sampled counterpart in `solve.py --null-debruijn`:

  | Family | Scope | C1 (pair struct) | C2 (no 5-line) | C3 (comp dist ≤ 776) |
  |---|---|---|---|---|
  | [de Bruijn B(2, 6)](CITATIONS.md#vanaardenne-debruijn1951) | Exhaustive, 134,217,728 circuits | **0 (0.00%)** — also proven analytically | 0 (0.00%) — min observed 1; **≥1 five-line now proven analytically (Claim 3)** | 247,048 (0.1841%) |
  | 6-bit Gray code orbit | 256 (rot × rev × compl) | **0 (0.00%)** — proven ∀ Gray | 256 (100%) — trivial | 0 (0.00%); range [1792, 2048] |
  | 6-bit Gray codes (random) | 10^5 random Hamiltonian walks in Q_6 | **0 (0.00%)** | 100% (trivial) | **0 (0.00%); range [832, 2048], CI ≤ 3×10⁻⁵** |
  | Latin-square row × column | Exhaustive 8!×8! = 1,625,702,400 | **0 (0.00%)** | **942,243,840 (57.96%)** — see §decomposition below | 108,380,160 (6.67%); range [512, 2048] |
  | Lexicographic (bit-order) | Exhaustive, 6! = 720 | 0 (0%) | 0 (0%) — always 2 five-line | 0 (0%) — always 2048 |
  | Historical (4 orderings) | Fu Xi, KW, Mawangdui, [Jing Fang](CITATIONS.md#jingfang) 8 Palaces | KW only | KW + **Jing Fang** (2 of 4; Jing Fang as linearized in [Nielsen 2003](CITATIONS.md#nielsen2003)'s printed palace order; corrected 2026-07-05 — authentic Mawangdui has one 5-line transition) | KW only |
  | Random 64-permutations | 10^9 uniform samples | **0 / 10^9 (0%)** | 1,827,703 (0.1828%) | 28,356 (0.002836%) |
  | **Pair-constrained (C1 baked in)** | 10^9 samples, C1 guaranteed | 100% (by construction) | 4.29% conditional on C1 | 6.42% conditional on C1 (exact: 6.4211367496%, `verify.py --check-null-g --unpinned`) |

  **Theoretical check**: C1 in random 64-permutations has probability $\approx (32! \cdot 2^{32}) / 64! \approx 10^{-44}$. In 10^9 samples we would expect to see 0 — which we do. The ~3/N [Wilson](CITATIONS.md#wilson1927) upper bound ([Hanley & Lippman-Hand 1983](CITATIONS.md#hanley-lippmanhand1983)) gives 95% CI on the C1 rate of [0, $3 \times 10^{-9}$] from the random 10^9 sample, consistent with the theoretical 10^-44.

  **What this establishes:**

  - **C1 is astronomically KW-specific.** Zero of 1.86 billion permutations sampled across six unconditional families satisfy C1, consistent with the theoretical rate of ~10^-44. For de Bruijn and Gray code families the 0% result is not just empirical — it is provable (see §C1 impossibility below).
  - **C1 is doing most of the structural work.** Given C1 (pair-constrained null), the conditional C2 rate jumps from 0.18% (random) to **4.29% — a ~23.5× multiplier** — and the conditional C3 rate jumps from 0.003% to **6.42% — a ~2,264× multiplier** (the C3|C1 rate is now exact: 6.4211367496%, `verify.py --check-null-g --unpinned`). The pair structure C1 alone enormously constrains the space toward KW-like adjacency and complement geometry; C2 and C3 are then relatively modest additional filters.
  - **C2 (no 5-line transitions) is mildly structural.** Rare in random (0.18%), impossible in de Bruijn, automatic in Gray codes (construction tautology), majority-satisfied in Latin-square row×col (**57.96%**, analytically decomposed below). Among the four tested comparison orderings, King Wen and Jing Fang 8 Palaces satisfy C2 exactly — Jing Fang as linearized in [Nielsen 2003](CITATIONS.md#nielsen2003)'s printed palace order; reading his palace table as one 64-term sequence, so that inter-palace seams count as adjacencies, is an interpretive step, and a load-bearing one (a seam's Hamming distance is popcount(d) + popcount(d⊕2) for palace-trigram difference d, which equals 5 when d is 0b101 or 0b111, so under other palace orders Jing Fang would fail C2; the order used is the transmitted one). The authentic Mawangdui silk-text order has **exactly one** 5-line transition (at the octet seam #48 Jing → #51 Zhen, where its trigram-block construction resets), and Fu Xi has two. *(Corrected 2026-07-05: this paragraph previously claimed 3 of 4 and inferred a "shared classical design principle" — that was computed on an erroneous Mawangdui array and is withdrawn; see CITATIONS.md errata.)* C2 alone is not especially distinguishing among historical orderings; the pair-constrained null shows C2 | C1 ≈ 4.29%.
  - **C3 concentration varies by family.** Random: 0.003%. de Bruijn: 0.18% (~65× random). Latin-square: 6.67% (~2,350× random). Pair-constrained (C1): 6.42% (exact: 6.4211367496%, `verify.py --check-null-g --unpinned`). Gray: 0%, with the strong additional observation that the minimum Gray-code C3 across 10^5 random samples is 832 — **strictly greater than KW's 776**. No Gray code beats KW on complement distance, empirically. The pair-constrained rate being similar to Latin-square is suggestive — both impose strong structural symmetry on complement placement.
  - **Simultaneous C1+C2+C3 satisfaction is uniquely King Wen across all tested unconditional families.** No family has a nonzero fraction achieving all three, because C1 is 0% in each. Under the pair-constrained null (C1 given), the independence estimate 4.29% × 6.42% ≈ 0.28% (both factors now exact: 4.29341% × 6.42114% = 0.2757%) gives a rough **estimate** of "random pair-permutation that also satisfies C2 and C3" ⚠ **[CORRECTED 2026-08-28 — this said "gives a rough **ceiling**", and a product of marginals is not a ceiling. P(C2∧C3) = P(C2)·P(C3) only under independence, and it *bounds* the joint from above only if C2 and C3 are non-positively correlated — which is precisely the open question, not a given. Calling an independence estimate a ceiling asserts the answer. **Reproduced independently 2026-08-28: the measured joint is ≈0.305%, ~11% ABOVE the 0.2757% product** — C2 and C3 are **positively correlated** given C1, and no ceiling holds. Two runs agree: 0.305832% at 10⁹ trials (D1 batch-4) and **0.30478% at 10⁷** by a separately-written sampler (0.6σ apart). The independent run validates its own predicates against the two published *exact* marginals before being trusted — measured C2 | C1 = 4.29159% against exact 4.29341% (0.3σ), C3 | C1 = 6.41625% against exact 6.4211367496% (0.6σ) — and anchors them on King Wen itself (KW satisfies C2; cd(KW) = 776 exactly). The excess over the product is **+16.7σ** at 10⁷. Reproduce with `python3 scripts/c2c3_joint_null.py` (~19 s; it asserts its KW anchors and reports each marginal's σ against the published exact value before reporting the joint). Tracked as Q-329. The reasoning defect stands on its own regardless of the measured value.]**; this aligns with solve.c's canonical enumeration finding (706M orderings under C1–C5 at d3 10T).

  **Remaining gap:** Costas arrays at order 64 (uncertain existence via standard Welch/Lempel–Golomb constructions; full 64! enumeration is infeasible at ~10^89 candidates). Costas at order 64 is the last open "structured permutation" family within reasonable scope; testing it would require either obtaining a published database of order-64 Costas arrays or implementing sporadic constructions. Deferred.

### C1 impossibility in the de Bruijn and Gray code families

Two short analytic proofs formalize what the budgeted enumeration observes empirically.

**Claim 1: No B(2, 6) de Bruijn permutation satisfies C1.**

Let the underlying binary sequence be $s_0 s_1 \ldots s_{63}$ (cyclic). Each hexagram is a 6-bit window: $\mathrm{hex}_i = s_i s_{i+1} s_{i+2} s_{i+3} s_{i+4} s_{i+5}$ (bit 0 = $s_i$). C1 requires, at each pair position $(2i, 2i+1)$, one of:

- (Reverse case) $\mathrm{hex}_{2i+1} = \mathrm{reverse}_6(\mathrm{hex}_{2i})$, i.e., bit $j$ of $\mathrm{hex}_{2i+1}$ equals bit $5-j$ of $\mathrm{hex}_{2i}$ for all $j$.
- (Symmetric-complement case, when both hexagrams are palindromic) $\mathrm{hex}_{2i+1} = \mathrm{hex}_{2i} \oplus 0b111111$.

**Reverse case.** Equating $\mathrm{hex}_{2i+1}$ to $\mathrm{reverse}_6(\mathrm{hex}_{2i})$ bit-by-bit gives three independent constraints on the underlying sequence: $s_{2i+1} = s_{2i+5}$, $s_{2i+2} = s_{2i+4}$, $s_{2i+6} = s_{2i}$. Applied across all 32 pair positions $i = 0, 1, \ldots, 31$, the constraints cascade: every even-indexed bit equals $s_0$, every bit at position $\equiv 1 \pmod 4$ equals $s_1$, every bit at position $\equiv 3 \pmod 4$ equals $s_3$. The sequence must be periodic with period 4: $(s_0, s_1, s_0, s_3, s_0, s_1, s_0, s_3, \ldots)$.

A period-4 sequence produces at most 4 distinct 6-bit windows, contradicting the B(2, 6) requirement that all 64 windows be distinct.

**Symmetric-complement case.** The hexagram $\mathrm{hex}_{2i}$ being palindromic imposes $s_{2i+2} = s_{2i+3}$ (middle bits must match). The complement equation then requires $s_{2i+3} = \overline{s_{2i+2}}$. But if $s_{2i+2} = s_{2i+3}$ AND $s_{2i+3} = \overline{s_{2i+2}}$, then $s_{2i+2} = \overline{s_{2i+2}}$, a contradiction.

Both cases are impossible, so no pair can satisfy C1, and therefore no B(2, 6) de Bruijn permutation satisfies C1 as a whole. ∎

**Claim 2: No 6-bit Gray code satisfies C1.**

In any Gray code, adjacent positions differ by Hamming distance exactly 1. C1 requires each pair to have Hamming distance in $\{0, 2, 4, 6\}$: the reverse case produces $2 \cdot k$ for $k$ mismatched bit-pairs ($0, 2, 4, 6$), and the symmetric-complement case produces exactly 6 (all bits flipped). Hamming distance 1 is never among these. Therefore no Gray code satisfies the C1 pair-structure constraint at any pair position. ∎

**Claim 3 (added 2026-07-02, resolves Open Question 3): Every B(2, 6) de Bruijn permutation contains at least one 5-line transition — C2 is analytically impossible for the de Bruijn family.** *(To our knowledge first proven here; prior-art corrections welcome per CITATIONS.md.)*

With windows $\mathrm{hex}_i = s_i s_{i+1} \ldots s_{i+5}$ as in Claim 1, the transition distance is
$d(\mathrm{hex}_i, \mathrm{hex}_{i+1}) = \#\{j \in \{0..5\} : s_{i+j} \neq s_{i+j+1}\}$ — the number of
alternations among the 6 adjacent bit-pairs of the 7-bit window $s_i \ldots s_{i+6}$. So $d = 5$ iff exactly
five of those six pairs alternate.

*Proof.* The window $A = 010101$ appears exactly once in the cycle, say at index $i$; let $b = s_{i+6}$. The
7-window is $0101\,01b$: its first five adjacent pairs all alternate, and the sixth $(1, b)$ alternates iff
$b = 0$. Hence $d(\mathrm{hex}_i, \mathrm{hex}_{i+1}) = 6$ if $b = 0$ and $= 5$ if $b = 1$. Avoiding a 5-line
transition here forces $b = 0$, making $\mathrm{hex}_{i+1} = 101010 =: B$. Now let $b' = s_{i+7}$: the 7-window
at $i+1$ is $1010\,10b'$, alternating in its first five pairs, with the sixth $(0, b')$ alternating iff
$b' = 1$. So $d(\mathrm{hex}_{i+1}, \mathrm{hex}_{i+2}) = 5$ unless $b' = 1$ — but $b' = 1$ makes
$\mathrm{hex}_{i+2} = 010101 = A$ again, contradicting the de Bruijn property that each window appears exactly
once. Therefore one of the two consecutive transitions following $A$ is 5-line. ∎

*Linear reading.* The forced 5-line transition is the successor-transition of $A$ or of $B$. Neither can be
the cyclic wrap under the standard rotation convention (windows enumerated starting from $000000$): the
successor window of $A$ has the form $10101b$ and of $B$ the form $01010b'$, neither of which is $000000$, so
the forced transition lies among the 63 **linear** transitions. This proves the empirically observed exhaustive
minimum of one 5-line transition per sequence (0 of 134,217,728 sequences avoid it; the bound is tight — the
minimum observed is exactly 1) and localizes it: **every de Bruijn permutation's unavoidable 5-line transition
occurs immediately after one of the two alternating windows.**

These three results, combined with the computationally exhaustive Latin-square row × column test showing 0/1.6B for C1, give independent structured-permutation families where C1 is ruled out (two analytically, one computationally exhaustively) — and now the de Bruijn family is *also analytically excluded on C2 grounds alone*. **Neither C1 nor (for de Bruijn) C2 is an "accidentally satisfied" property of common structured permutation families**; they are specific constraints that King Wen happens to satisfy.

### Latin-square C2-rate decomposition

The empirical observation that **57.96% of 8! × 8! Latin-square row × column traversals satisfy C2** (zero 5-line transitions) is analytically explained by the adjacency structure of the Latin-square grid. Verified by `solve.c --null-latin-explain`, which reproduces the count 942,243,840 exactly from first principles.

**Theorem (C2-rate decomposition).** In a Latin-square row × column traversal of the 64 hexagrams, the row-permutation class determines the C2 rate. Of 63 adjacent transitions, 56 are within-row (share upper trigram, so Hamming ≤ 3, and cannot be 5) and only the 7 between-row boundaries can be Hamming-5. At boundary $i$, the transition Hamming distance is $p_i + d$ where $p_i = \mathrm{popcount}(\mathrm{row}[i] \oplus \mathrm{row}[i+1]) \in \{1, 2, 3\}$ and $d = \mathrm{popcount}(c[0] \oplus c[7]) \in \{1, 2, 3\}$. The transition is Hamming-5 iff $(p_i, d) \in \{(2, 3), (3, 2)\}$. Since $d$ is a property of the column permutation, we get:

| Row-perm class | # row perms (of 8! = 40,320) | Good column perms (of 8! = 40,320) | C2 rate |
|---|---|---|---|
| All $p_i = 1$ (Hamiltonian path in $Q_3$) | 144 (0.36%) | 40,320 (all) | 100% |
| Some $p_i = 2$, no $p_i = 3$ | 13,680 (33.93%) | 34,560 (= 48/56 × 40,320) | 85.71% |
| Some $p_i = 3$, no $p_i = 2$ | 1,008 (2.50%) | 23,040 (= 32/56 × 40,320) | 57.14% |
| Both $p_i = 2$ and $p_i = 3$ | 25,488 (63.21%) | 17,280 (= 24/56 × 40,320) | 42.86% |

The weighted sum $144 \cdot 40{,}320 + 13{,}680 \cdot 34{,}560 + 1{,}008 \cdot 23{,}040 + 25{,}488 \cdot 17{,}280 = 942{,}243{,}840$ exactly matches the empirical `--null-latin` count. The 57.96% rate is thus a direct consequence of: (a) only 7 of 63 transitions can be 5-line in any Latin-square row×col traversal, and (b) the distribution of row-adjacency Hamming profiles among Hamiltonian paths in the 3-cube.

**Direction invariance** (verified 2026-04-19 via `solve.c --null-latin-col`). Reading the Latin-square grid COLUMN-first (reverse nesting: column ordering outer, row ordering inner) produces **identical** aggregate statistics: n = 1,625,702,400, C2 pass = 942,243,840 (57.959184%), C3 pass = 108,380,160 (6.667%), C3 range [512, 2048] mean 1536.0. Every figure matches the row-first traversal to the digit. By the symmetry of the upper/lower-trigram axes in the abstract 8×8 grid, this was expected — but the empirical confirmation shows the 57.96% C2 rate is a property of the Latin-square family as a whole, not an artifact of which axis is read first.

**Connection to KW.** King Wen is **not** a Latin-square row×col traversal (`./solve --null-historical` confirms Fu Xi fails C1). But the Latin-square result suggests a diagnostic question for KW: does KW have its own adjacency decomposition that analogously pushes 5-line transitions into a small subset of positions? KW has 32 pairs, each with within-pair transitions fixed to Hamming {2, 4, 6} by C1's reverse/complement construction — which also mechanically excludes Hamming-5. So KW's 32 within-pair transitions trivially avoid 5-line, leaving C2's constraint work entirely to the 31 between-pair boundaries. This is structurally analogous to Latin-square's within-row/between-row split. (The within-pair Hamming-even property has long been known in I Ching scholarship; see [CITATIONS.md](CITATIONS.md) — [McKenna 1975](CITATIONS.md#mckenna-mckenna1975) and [Cook 2006](CITATIONS.md#cook2006) both discuss the even-transition artifact of the pairing rule. ROAE's contribution here is the analogous decomposition for the Latin-square family.)

### King Wen's own adjacency decomposition

Following from the Latin-square analysis, we can characterize KW's 63 transitions explicitly. KW's 32 pairs partition the transitions into 32 within-pair and 31 between-pair.

**Within-pair transitions** (KW's 32, all Hamming-even by C1 construction):

| Hamming distance | Count |
|---|---|
| 2 | 12 |
| 4 | 12 |
| 6 | 8 |

The within-pair sum is $12 + 12 + 8 = 32$, all 32 pairs. Zero odd distances by construction.
*(Corrected 2026-07-02: this table previously read 11/13/8 — a tabulation error caught by recomputation
during SAT-encoder design; the corrected values are machine-checkable from the KW sequence in seconds.)*

**Between-pair transitions** (KW's 31, where all the "constraint work" happens):

| Hamming distance | KW count | Expected (uniform random adjacency, ×31) | Delta |
|---|---|---|---|
| 1 | 2 | 2.95 | −0.95 |
| 2 | 8 | 7.38 | +0.62 |
| 3 | **13** | 9.84 | **+3.16** |
| 4 | 7 | 7.38 | −0.38 |
| 5 | **0** | 2.95 | **−2.95** |
| 6 | 1 | 0.49 | +0.51 |

The linear between-pair odd counts are 13 threes and 2 ones (matching the proven 15-alternation total —
see [PARITY_ALTERNATION.md](PARITY_ALTERNATION.md)); the widely-quoted **14:2** figure (McKenna 1975, echoed
by Cook 2006 and Wikipedia) is the **circular** reading — the wrap-around transition (Hamming 3 in KW) adds
the fourteenth three. *(Corrected 2026-07-02: this passage previously presented the circular 14 in the
linear table and described the Hamming-3 concentration as "4× the uniform rate" — a misreading of the +4.16
delta as a ratio; the correct linear excess is 13 vs 9.84 expected, ≈1.3×.)* King Wen's between-pair
transitions concentrate modestly on Hamming-3 and drop the Hamming-5 count to zero. No Hamming-0 transitions (all 64 hexagrams distinct, trivially); minimal Hamming-1 count (just 2 occurrences).

**Structural interpretation.** Like Latin-square's within-row/between-row decomposition, KW cleanly splits its 63 transitions into: (a) 32 within-pair transitions, trivially {2, 4, 6} by pair-reflection geometry; (b) 31 between-pair transitions, where C2 (no 5-line) and the 13:2 odd-concentration are the substantive structural signals *(corrected 2026-08-01 from "14:2": per the corrected table above and TR-6 §2, 14:2 is the **circular** reading; the linear between-pair figure is 13:2)*. Prior literature (McKenna 1975, Cook 2006) documents these between-pair features as observed empirical properties of the KW sequence; ROAE's contribution here is to place them alongside the Latin-square decomposition as structurally parallel (different families, same within-group trivialization pattern) and to quantify the deviation from uniform-random between-pair adjacency.

- ~~No formal proof that 4 boundaries are minimum across *all* valid orderings.~~ **UPDATED 2026-06-11; corrected 2026-07-04:** the boundary-minimum is **monotone non-decreasing in scale**. Greedy-ordered minimum trajectory: **4** (d2 10T, d3 10T) → **5** (d3 100T, set {1,4,21,25,27}) → **5** (d3 560T, identical set {1,4,21,25,27}). Working-4-subset count trajectory: **8** (11.2T) → **4** (742M) → **0** (100T, 560T). *(The 2026-06-11 version of this entry claimed the minimum "dropped back to 4" at 560T — a survivor-counting error; see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md).)* The 100T-era expectation that the minimum would "further raise at 1000T+ enumeration" is so far neither confirmed nor refuted: one increment (10T → 100T), then stability (100T → 560T). The minimum-set count is genuinely a function of enumeration depth, not a universal invariant. Boundaries {25, 27} remain partition-stable across all canonicals tested (present in the greedy minimum at every scale).
- No independent derivation of the constraints from first principles. The 5 rules (C1-C5) were extracted from KW and then verified against KW; a stronger result would derive them from external mathematical or coding-theoretic principles. The constraint-extraction methodology produces apparent uniqueness for many random pair-constrained sequences, so the constraints are KW-specific rather than universal — a conclusion resting on the reasoning that C1+C2 is the genuinely rare part while the extracted C3–C7 constraints are not, with the project's null-model run pointing the same way. *(Evidentiary standing clarified 2026-09-01: this sentence previously presented that null-model run as having settled the question. The run's artifacts were not preserved — no command, seed, target list or per-target survivor count for it exists anywhere in the project, and no `solve.py` mode implements the protocol — so it is an **unreproduced historical observation, not a measured result**; full disclosure and provenance: [SOLVE.md](SOLVE.md) §"is the constraint framework special". The conclusion above is **not** withdrawn: it does not depend on that run.)* See [CITATIONS.md](CITATIONS.md) for prior literature — C1 (pair structure) is classical; C2 (no-5-line) is McKenna 1975 / Cook 2006; C3 (complement distance as a quantified threshold) is believed ROAE-original.

## Distributional reframing of KW's "distinctiveness"

Prior framings in this project have struggled with the honesty question: any
set of KW-specific properties can be extracted and make KW appear uniquely
determined; the search for "non-trivial" distinguishing properties has been
circular. A quantified distributional approach was intended to sidestep this:

- Define a **fixed-in-advance 10-dimensional observable-statistics vector**
  (edit_dist_kw, c3_total, c6_c7_count, position_2_pair, mean/max transition
  hamming, fft_dominant_freq, fft_peak_amplitude, shift_conformant_count,
  first_position_deviation).
- Compute it for every record in the 100T d3 canonical (3,432,399,297 valid
  orderings).
- Fit a kernel density estimator on a uniform sample; locate KW; compute
  KW's density-percentile with bootstrap confidence intervals.

**Finding (corrected 2026-07-26):** this section previously presented the joint-KDE
result (rank < 10⁻⁵, ~12,800× density deficit) as a distributional analysis that
"avoids the extraction problem" using dimensions "chosen for general information
content, not custom-fit to KW". That characterization was wrong: five of the seven
KDE dimensions were KW-referencing (two tautological, two KW-extracted, one extreme
by population construction), so the analysis was itself an instance of the extraction
effect this document warns about — the same failure mode diagnosed for D-B1. The
de-circularized re-run (two KW-independent FFT dimensions, same population and
pipeline) places KW at the **~30th percentile of joint density** — unremarkable.
The single surviving marginal deviation, `fft_peak_amplitude` at the exact 95.476th
percentile (p ≈ 0.045 one-sided), fails the battery-wide bars (0.05/28, 0.05/91)
by well over an order of magnitude. **The distributional analysis therefore
contributes no KW-evidence**; its durable content is descriptive (the marginals
table, the invariant transition-Hamming theorem, and the finding that KW's dominant
FFT frequency is bulk-typical). The original numbers are retained in HISTORY as a
worked example of how KW-referencing observables manufacture apparent uniqueness.

**What this is not.** Evidence about KW in either direction beyond a null:
the de-circularized result is that KW is distributionally typical on the
non-circular dimensions. (Even the withdrawn atypicality claim would not
have been a uniqueness proof; population typicality is likewise not a
disproof of intent — cf. TR-10's scope discipline.)

**Caveats properly attached.**

1. The bandwidth-sensitivity caveat previously attached to the withdrawn
   −128,260 figure is moot for a withdrawn result; the de-circularized
   re-run's own robustness checks (5 seeds × 2 bandwidth methods, exact
   full-population histogram cross-checks) are stated in
   DISTRIBUTIONAL_ANALYSIS.md §"Joint density — de-circularized
   re-analysis".
2. One dimension's marginal report (`fft_dominant_freq` at 29%-ile)
   initially suggested KW was on the low tail of that dimension. Closer
   inspection showed KW's value (k=16) is a bulk-typical value — the
   **second-largest bin** (12.62% of records share it; the mode is k=30
   at 14.39% — exact-count correction 2026-07-26, previously "the mode") —
   the 29% comes from standard
   half-bin percentile convention applied to a population with large ties.

**How this compares to the prior "3.9th percentile" C3 claim.** That
claim was specifically: KW's complement distance is in the 3.9th percentile
**at the C1+C2+C4+C5 scope** (every constraint except C3 itself; scope label
corrected 2026-07-22 — this paragraph previously said "under C1+C2 only",
where the measured figure is ~7% and the exact C1&C4-null figure is 8.106%,
`verify.py --check-null-g`), without the C3 filter. *(**Flagged 2026-08-01, lens sweep** — the 3.9th-percentile figure is not supported by the population it is labelled with; the suite's own ledger gives ≈12% at this scope. Do not cite it: see [SOLVE.md](SOLVE.md) §Rule 3.)* Within the C1-C5 canonical, KW is at the C3 **ceiling** (776), not
the floor. Both statements are true in their respective scopes; neither
contradicts the other. The joint-distribution analysis above is additionally
in scope *over the full C1-C5 canonical* — the most defensible reference
population for making claims about KW's distinctiveness under the full
constraint system.

## Open questions

Falsifiable follow-ups surfaced by the current analysis. These are not claims; they are candidate hypotheses testable with the tools already built.

### About the null-model framework

1. **Costas arrays at order 64.** Standard Welch/Lempel–Golomb constructions give adjacent orders 62 and 66; a direct order-64 family is not known to the author. Concrete follow-up: (a) survey the published literature (the Naval Postgraduate School maintains a database of known Costas arrays) for any order-64 examples; (b) test each against C1/C2/C3; (c) if a family of order-64 Costas arrays can be constructed (e.g., via sporadic constructions, or computer search from known order-62/66 seeds), run the full null-model test.

2. **Gray code C3 exhaustive.** The total count of 6-bit Gray codes (Hamiltonian cycles in Q_6) is estimated at ~10²² — exhaustive enumeration is infeasible at any practical compute budget. But the conditional C3 rate could be tightly bounded via biased random Hamiltonian sampling (10⁹ samples in a few hours); would give a firm upper bound on the Gray-code C3 rate ⚠ **[CORRECTED 2026-08-28 — it would NOT. More draws from a biased sampler shrink the confidence interval on **that sampler's** rate and say nothing more about the uniform family: the estimator's bias does not decay with N. A firm bound on the family rate needs either a uniform sampler over Hamiltonian cycles in Q₆, or importance weights whose likelihood ratios are known — neither of which this instrument has. Stated as a proposal it projected the same over-reach corrected at :60 into future work, at a cost of "a few hours" of compute that would not have bought the claimed result.]** rather than the current 0/256 from the restricted orbit.

3. **~~Analytic C2 impossibility for de Bruijn B(2, 6).~~ — RESOLVED 2026-07-02 (proven).** Every B(2, 6) de Bruijn permutation contains at least one 5-line transition, located immediately after one of the two alternating windows (010101 / 101010): avoiding a 5 after 010101 forces the successor window 101010, and avoiding a 5 there forces 010101 to recur — contradicting window uniqueness. Full proof: §"C1 impossibility…" Claim 3 above. The empirical exhaustive minimum (exactly 1 in the best case, 0 of 134,217,728 sequences avoiding it) is thereby explained and shown tight.

### About the Latin-square decomposition

4. **Does King Wen have an analogous adjacency decomposition?** Latin-square row×col traversals split 63 transitions into 56 within-row (Hamming ≤ 3, cannot be 5) and 7 between-row (can be 5). KW has 32 pairs with 32 within-pair transitions (Hamming 2/4/6 by C1 construction, cannot be 5) and 31 between-pair boundaries (where all the C2 work happens). Concrete follow-up: (a) characterize the 31 between-pair boundary Hamming distances in KW; (b) compare to random permutations satisfying C1 to measure how much additional structure the between-pair distribution has.

5. ~~**Why does Mawangdui satisfy C2?**~~ **RESOLVED 2026-07-05 — it doesn't.** The question was premised on an erroneous array. The authentic Mawangdui order decomposes like Latin-square (block-interior = small): within octets the upper trigram is constant, so 56 of 63 adjacencies have Hamming distance ≤ 3; at the 7 octet seams the distance is the seam's trigram distance sum, and exactly one seam (Kan→Zhen: #48 Jing → #51 Zhen) reaches 5. Its transition histogram is {1: 21, 2: 10, 3: 29, 4: 2, 5: 1}.

### About the constraint system

6. **What combinatorial family does KW belong to?** KW is not in any of the seven structured families tested (de Bruijn, Gray, Latin-square row×col, lex, historical, pair-constrained-random-orientation, random). This is consistent with KW being sporadic / hand-constructed. But falsifiable: is there a structured family (yet-untested) that KW IS in? Candidates include necklace/bracelet enumeration orders, hex-based error-correcting codes, group-theoretic orbit constructions, or specific Hamiltonian cycles in graphs with hexagram-meaningful structure (e.g., the pair graph).

7. **Are C1, C2, C3 actually sufficient?** ROAE reports 706M distinct orderings at d3 10T under C1–C5. Under EXHAUSTIVE enumeration (not partial) the count may differ. The current enumeration is node-budget-limited; a true exhaustive enumeration would require much larger compute (100T d3 in progress as of 2026-04-19). The 100T run will not make the enumeration exhaustive but will reduce the gap between partial and exhaustive counts.

8. **Minimum boundary-adjacency set exhaustive minimum.** Currently: 4-boundary minimum proven for d2 10T and d3 10T; **5-boundary minimum proven at d3 100T and d3 560T** (§[8] = 0 excludes all 4-sets; identical greedy 5-set {1,4,21,25,27} at both) *(corrected 2026-07-04: previously claimed a 4-boundary minimum at 560T)*. {25, 27} mandatory in every greedy minimum set. §[7] at 560T proves NO 3-subset works (best 3-set leaves 15 survivors). Deeper enumeration at 1120T+ could in principle push the minimum to 6 — but no such enumeration is planned (2026-08-01), so this stays open with no fifth datapoint forthcoming; if it ever drops below the proven values on a superset dataset, that would indicate a bug, not a finding (supersets can only grow the survivor pool).

### About methodology

9. **~~Formal machine-checked proof of Theorem 6~~ — RESOLVED BY RETRACTION (2026-07-26).** This item formerly said the forced-orientation theorem "has a prose proof" awaiting formalization. Both halves were wrong: no prose proof ever existed (SOLVE.md itself said "not yet analytically proven" while SPECIFICATION.md called it a theorem — a status contradiction), and **the claim is false** — complementation is an exact symmetry of C1∩C2∩C3∩C5, so the reversed opening (0, 63) is fully valid there; only C4's oriented definition excludes it. The machine-checking happened in the opposite direction: the TRUE statement (the Complement Z₂ symmetry theorem) is now kernel-checked in [lean/KingWen.lean](../lean/KingWen.lean), and the false one is retracted (see CLAIMS_DECIDED's corrections ledger). The empirical support had been circular: the solver hardcodes the orientation it was cited as evidence for.

10. **Bootstrap confidence intervals for all percentiles in CRITIQUE.md.** The current framing uses point estimates from finite samples. Bootstrap (or Wilson score intervals for proportions) would put explicit error bars on every rate claim. Partially done in the null-model table (Wilson / 3/N rule mentioned); not yet exhaustively applied.

### About specific numerical values

11. **~~Is King Wen's C3 = 776 mathematically significant?~~ — RESOLVED 2026-04-20 (partial).** Via `solve.c --c3-min` on the 100T d3 canonical (3.43B records):
    - **Minimum C3 observed: 424** (across 221 records)
    - **Maximum C3 observed: 776** (ceiling of the constraint C3 ≤ 776)
    - **KW's C3 = 776** — KW sits at the **CEILING**, not the floor. KW is the **least** C3-optimal among C1–C5 solutions.
    - The earlier "3.9th percentile" claim is among orderings satisfying every other constraint (C1+C2+C4+C5, pre-C3-filter; scope label corrected 2026-07-22 — this line previously said "C1-only", where the measured tail is ~6-8%, see §"What holds up"). Within C1–C5, KW is at the C3-maximum. *(**Flagged 2026-08-01, lens sweep** — the 3.9th-percentile figure is not supported by the population it is labelled with; the suite's own ledger gives ≈12% at this scope. Do not cite it: see [SOLVE.md](SOLVE.md) §Rule 3.)*
    - **Implication for Open Question #7**: the simple axiom "minimize C3" does not uniquely derive KW — it picks out 221 "C3-extremal" records at C3 = 424. **Negative result for Phase A Day 1 MVP.**
    - Remaining: characterize the 221 C3=424 records. What else distinguishes them? Is there a structured family? Do they share boundary features with KW? (Follow-up post-analyze.)

12. **~~Do Hamming-class-preserving permutations of {0..63} induce orbital symmetries on the C1–C5 solution set?~~ — RESOLVED 2026-07-02 (POSITIVE — REVERSES the 2026-04-25 negative).** The C1–C5 constraint system is **exactly invariant** under the 48 bit permutations commuting with reversal (G ≅ B₃, the octahedral group; effective group on canonical records S₄, order 24) — proven, plus corroborated by exhaustive σ(KW) validity (48/720), exact tree-isomorphism (identical 9,422,793-node subtree counts across σ-related prefixes), and orbit-equality of all 65,281 per-cell Knuth estimates within estimator noise. **KW has exactly 23 record-level twin orderings.** The 2026-04-25 "all 47 falsified / constraint set is rigid" conclusion compared **budget-truncated per-cell yields**, which are non-equivariant for two now-understood reasons (σ permutes DFS frontier order under a fixed budget; the lex-smallest-orientation dedup is not σ-equivariant) — a **methodological lesson: budgeted-slice statistics cannot falsify solution-set symmetries**. Bit-flip × bit-perm combinations are excluded analytically (flips move 0/63, violating C4), closing full Aut(Q₆). Corrected writeup + proof: [`SYMMETRY_SEARCH.md`](SYMMETRY_SEARCH.md). An orbit-reduction of enumeration cost (÷ up to 48) is now available in principle; adoption for canonical runs is a gated convention change.

## Summary

The constraint solver (`solve.c`) finds that 5 rules extracted from King Wen narrow 10^89 possible orderings to an estimated **≈1.33×10³⁸ *raw* valid orderings** (raw = orientation-explicit; [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md), a Knuth random-probe estimate, not a proven cardinality); the enumerated counts — 706,427,594 at d3 10T partition (canonical, sha `b85c8871…`), 286,357,503 at d2 10T — are **budgeted slices** of that space in the canonical unit, not its size. *(Corrected 2026-09-02: this sentence gave the slice counts as the size of the constrained space; see [CORRECTIONS.md](CORRECTIONS.md).)* Both are partial enumerations (each sub-branch hits its per-sub-branch node budget rather than completing naturally); the true count under exhaustive enumeration is higher. Only Position 1 is universally locked (forced by Rule 4). The current state is: **greedy minimum 4 at d2/d3 10T, 5 at d3 100T and d3 560T** (identical set `{1, 4, 21, 25, 27}` at both canonical scales; monotone trajectory) *(corrected 2026-07-04: previously claimed "4-boundary minimum reaffirmed at 560T"; see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md))*. Boundaries **{25, 27} appear in the greedy minimum at every partition tested** (the stable mandatory-boundary finding). The other boundaries in the minimum are partition + scale-dependent — d2 uses {2,3} and {21,22}; d3 10T uses combinations from {1..6}; d3 100T/560T use {1, 4, 21}. The rules are confirmatory (extracted from King Wen, then shown to be highly constraining) rather than predictive (derived independently). See [SOLVE.md](SOLVE.md), [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md), [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) (formal theorem guaranteeing the canonical shas are partition-invariant), and [HISTORY.md](HISTORY.md) for details.

The program is honest about what it computes and includes explicit statistical caveats where the evidence is thin. Sensitivity analysis confirms all key mathematical results are invariant under bit-ordering convention (Hamming distance is invariant under bit permutation). The pair structure is the one genuinely extraordinary property — it is vanishingly unlikely by chance (analytic probability ≈10⁻⁴⁴). **Scope of that figure (added 2026-08-01, lens sweep):** the ≈10⁻⁴⁴ is computed against a *uniform-random-permutation* null, which is not a null any competing account of the sequence asserts. The pairing itself is classically attested — Kong Yingda's *Zhouyi zhengyi* is its explicit formulation, with the pangtong/fandui lineage running back to Yu Fan, 3rd c. CE ([CITATIONS.md](CITATIONS.md#yufan)) — and [Radisic (2026)](CITATIONS.md#radisic2026) proves it is the unique Hamming-cost-minimising comp/rev matching, a derivation that never mentions King Wen ([METHODS.md](../reports/METHODS.md) §Constraints). Accordingly [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) §2 treats the pair-structure space as *the literature's own assumption*, shared by every hypothesis under comparison. So ≈10⁻⁴⁴ measures how atypical the pairing layer is among arbitrary permutations; it carries almost no power to discriminate among rival accounts of the layer actually in dispute — the ordering of the 32 pair-units, on which [TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md) prices C1 as fixing 146.3 of 296 bits and leaves the residual to the nulls. "The one genuinely extraordinary property" should be read as *extraordinary relative to chance permutations*, not as the suite's strongest design evidence. The complement distance is also genuinely unusual against unconstrained permutations (0th percentile; 8.1% under the exact pair-constrained C1&C4 null, `verify.py --check-null-g`; 3.9th percentile — sampled, and **flagged 2026-08-01 as unsupported by that population; the ledger gives ≈12%, see [SOLVE.md](SOLVE.md) §Rule 3** — at the stricter C1+C2+C4+C5 scope; and within the fully constrained C1–C5 population KW sits at the C3 *maximum*, per the C3-ceiling correction). Other findings are either explained by the pair structure (no-5 property, ~4% among pair-constrained orderings), not significant after Bonferroni correction (entropy), indistinguishable from pair-constrained random orderings (Markov, path length, palindromes), or purely descriptive without significance tests (windowed entropy, trigram transitions, Gray code ratio). The Wald-Wolfowitz runs test ([Wald & Wolfowitz 1940](CITATIONS.md#wald-wolfowitz1940)) detects alternation in the difference wave (Z = +2.13, p = 0.033), but this does not survive Bonferroni correction (threshold p < 0.0018). **Note: this alternation phenomenon was independently reported by [Chan (2026, arXiv:2604.09234)](CITATIONS.md#chan2026) as "negative lag-1 autocorrelation" of Hamming distances (KW value −0.251, 3.7th percentile, p=0.037). Chan's research predates ROAE; the alternation observation is Chan's prior art under the lag-1 autocorrelation framing. See [CITATIONS.md](CITATIONS.md).** Palindromic subsequences in the wave are unremarkable under pair-constrained null model (49th percentile for count, 14th for longest). The canon split, recurrence rate, and neighborhood clustering are all within chance expectations. Effect sizes (Cohen's d — [Cohen 1988](CITATIONS.md#cohen1988)) are reported alongside percentiles for key analyses.

## Corpus control test (2026-07-04): the battery's specificity, validated

A standing attack on extraction methodologies is that they find "design" wherever they look. We ran the
observable battery (11 axes: transition structure, pairing, trigram dynamics, entropy, autocorrelation,
complement distances, runs, palindromic windows) on three orderings against a 10,000-permutation uniform
null, with a provably algorithmic ordering as **positive control**:

| Ordering | Extreme axes (≤1st or ≥99th percentile) | Reading |
|---|---|---|
| Jing Fang Eight Palaces (fully algorithmic) | **9 of 11** | positive control PASSES — the battery detects provably algorithmic construction |
| Mawangdui (trigram-block sorted) | 9 of 11 | correctly flagged as structured |
| **King Wen** | **3 of 11 — exactly the C1/C2/C3 axes** | and **0 of 11** against the pair-preserving null |

The battery is not a design-finding machine: it lights up on provably constructed orderings, and for King
Wen it flags precisely the three constraints this project documents — nothing else — with every residual
signal disappearing under the correct (pair-preserving) null. The scope of this evidence should be stated
plainly: the control corpus is the **two** documented historical alternatives available to us (Jing Fang,
Mawangdui) plus Fu Xi in the null tables — n = 2 non-KW historical controls is a real limit on how strong
any "specificity" claim can be, and the positive-control logic (the battery detects provably algorithmic
construction) is sound only as far as it goes. Within that limit, the methodology distinguishes *which*
orderings are structured and *where*; additional attested historical orderings, if verifiable to
source-grade standards, would harden this gate and are sought (see the standing invitation in
[CITATIONS.md](CITATIONS.md)). (Results file with the full table and script: project archive.) *(Corrected 2026-07-05: the original 2026-07-03 run
used the erroneous pre-correction Mawangdui array and reported 7 of 11 extremes with a parenthetical
rationalizing the rule/data mismatch its own cross-validation had flagged — that rationalization was
wrong; the array was simply incorrect. Rerun on the corrected array (Shaughnessy 2022 Table 11.2),
Mawangdui flags 9 of 11 extremes — the battery detects the authentic trigram-block construction even
more strongly. KW rows are unaffected.)*

Superseded in depth by Corpus control II below (constraint-family level, N = 10⁶, matched nulls,
pre-registered). The results in this section remain valid anchors.

## Corpus control II: cross-tradition constraint-family test (design frozen 2026-07-11; measured 2026-07-12)

The corpus-control test above ran King Wen's observable battery on the alternatives. Its sequel
completes the symmetric experiment at the constraint-family level, against the standing referee
attack: *does this project's extraction methodology manufacture ×10³-class "design discriminators"
for ANY systematic ordering of the 64 hexagrams (cf. ρ(C2|C1) ≈ 23.5×, ρ(C3|C1) ≈ 2,264× in the
null-model table), or does it correctly identify which orderings are structured, where, and by how
much?* Each historical ordering received its OWN constraint family, extracted from its own data in
its own natural representation, exactly as C1–C5 were extracted from King Wen: **J1–J5** for the
Jing Fang Eight Palaces arrangement (palace-generator representation; the standard classical
construction — [CITATIONS.md](CITATIONS.md#jingfang)), **M1–M5** for the Mawangdui silk-manuscript
ordering (trigram-octet representation; [Shaughnessy 2022](CITATIONS.md), Table 11.2 — the
corrected array of the 2026-07-05 erratum), **B1** for Fu Xi (identity on the binary axis). None of
these generative descriptions is novel — the palace construction is standard sinology, and the
Mawangdui two-key trigram sort is described by Shaughnessy (upper-trigram octets in
[Schulz & Cunningham's (1990)](CITATIONS.md#schulz-cunningham1990) gender-blocked order; lower
trigrams a fixed couple-interleaved family cycle with own-trigram promotion). Only their use as a
symmetric corpus-control instrument is, to our knowledge, this project's own — and that is hedged,
not asserted. The design was pre-registered and frozen 2026-07-11 (families, cross-application
matrix, null ladder, sample sizes, seeds, thresholds, falsification gates), with one dated
pre-measurement amendment (below); measured 2026-07-12; every cell reported as pre-committed;
report-only — nothing promotes to a solver constraint regardless of outcome, per the standing
extraction-circularity policy. Implementation: `solve.py --r7-corpus` / `--r7-verify` (sha-neutral).
Evidence: `reports/evidence/r7/`.

**Specificity, measured three ways.**

1. *The battery flags the algorithmic comparison orderings, not King Wen* (uniform null upgraded ×100 to
   N = 10⁶; pilot-vs-rerun EXTREME sets identical, no boundary crossings): Jing Fang — provably
   algorithmic; J1∧J2∧J3 determine the sequence uniquely, residual 0 bits — flags **9 of 11**
   observables EXTREME; the corrected Mawangdui — also fully algorithmic given its two classical
   conventions — **9 of 11**; Fu Xi 7 of 11; King Wen **3 of 11, exactly the C1/C2/C3 axes**, and
   0 of 11 against the pair-preserving null. Both positive controls pass the pre-committed FC-1
   gate (≥ 8 of 11); a battery that failed to flag Jing Fang would have been published as
   "instrument broken, no specificity conclusion available" — no threshold tuning.
2. *The manufacture alarm is clean.* The cross-application matrix — every family applied to every
   ordering — shows **zero off-home passes** among the alarm predicates {C1, J1, joint-M, B1}. The
   one off-home partial pass, pre-registered by us as an expected pass, is Fu Xi satisfying M1
   (any upper-sorted ordering does — M1 alone is a weak predicate); it is excluded by the joint-M
   requirement, which Fu Xi fails a-priori at M2/M3/M4. We flag it ourselves rather than leave it
   for a reviewer. No off-home ×10³-class enrichment appears anywhere in the grid, and King Wen's
   uniform-null EXTREME set remained exactly {a, b, f} at N = 10⁶.
3. *Matched nulls price each ordering's actual structure.* Under its own exact J1-conditioned null
   (all 8! = 40,320 palace assignments enumerated), Jing Fang is EXTREME on **0 of 11**
   observables — its remaining rarity is precisely the palace order: P(J2∧J3 | J1) = 1/40,320
   (exact). Mawangdui under its M1-conditioned null: 3 of 11; under the fuller M1∧M3-conditioned
   null: 1 of 11 (the obs-h disposition below). Residual description lengths
   ([DESCRIPTION_LENGTH.md](DESCRIPTION_LENGTH.md)): Jing Fang **0 bits**, Mawangdui **0 bits**
   (plus ≤ log₂(8!·8!) ≈ 30.7 bits of classical convention choice), Fu Xi **0 bits** — versus King
   Wen's **~126.6-bit (C1–C5-layer) residual** (TR-9's published range is 105–139 bits; 126.6 is the
   C1–C5 reading, the layer at which this comparison was computed). The home-family enrichments for the comparison orderings are astronomically
   larger than King Wen's (P(J1 | L0) ≈ 3.2×10⁻⁸⁵, P(M1 | L0) ≈ 2.2×10⁻⁴⁸, analytic) — predicted
   in advance: a fully generated ordering is more compressed than a constrained-but-vast one.

**The thesis, and its limits.** Applied symmetrically, the methodology assigns each ordering its
ACTUAL compression — near-total for the algorithmic comparison orderings, partial-with-vast-residual for King
Wen. It is not a design-finding machine: it does not flag every systematic ordering as "designed"
and it does not manufacture off-home discriminators. The critical framing: **this is a specificity
result about the instrument, not evidence that King Wen is "designed"** — no cell of this
experiment licenses any intent inference. Honest limits: (i) n = 3 alternative orderings, all
classical Chinese — a finite historical corpus cannot settle the universal "manufactures for ANY
ordering" claim (the seven structured mathematical families elsewhere in this document are the
complementary synthetic arm); (ii) post-erratum BOTH comparison orderings are fully algorithmic, so the
corpus contains no genuine middle case and the battery's response to *partial* design is
uncalibrated here; (iii) the extraction circularity is symmetric, not eliminated — J1–J5 and M1–M5
were extracted from their own traditions' data exactly as C1–C5 were from King Wen, so the result
demonstrates specificity and calibration, never independence of any family from its sequence;
(iv) the uniform-null matrix was observed at N = 10⁴ in the pilot before the freeze — the
evidentiary weight rests on the genuinely-unobserved cells (the matched-null ladders, the off-home
predicate cells, the exact rates).

**Two pre-registration corrections, disclosed.** (1) A dated pre-measurement amendment (2026-07-12)
corrected the FC-4 coherence anchor: the frozen text predicted Jing Fang's complement-distance sum
(1024) at the ≥99th percentile of the exact J1 null, conflating the J4 count (384/40,320 ≈ 0.95%)
with the full distance-maximizing class (9,216/40,320 ≈ 22.86%; measured mid-percentile 88.57,
exactly as the corrected anchor predicts). (2) One residual flag survived where FC-4's frozen
wording said flags "must vanish": under Mawangdui's fullest sampled matched null (M1∧M3
conditioned, both classical conventions freed over the 8!×8! space), the longest-monotone-run
observable still flags — Mawangdui's value 3 is the observed floor of that space, mid-percentile
0.52 (P(run ≤ 3) ≈ 1.03%; reproduced at three further seeds). Exact single-convention slices
(8! each, enumerated) attribute the rarity to the classical lower-cycle convention Λ itself: its
couple-interleaved order — father, mother, then the three complement couples — forces a strictly
alternating 3,1,3,1,… within-octet difference pattern (the same mechanism places the lag-1
autocorrelation observable at p1.58, just above the line). That is, the battery is detecting real
structure in a classically documented convention that this null deliberately leaves free — not
unpriced structure in the sequence: M1∧M3∧M4 reconstruct Mawangdui exactly (residual 0 bits), and
under true full-family conditioning the null is a single point where flags vanish trivially. We
record this — diagnosed *after* the L2 cell was measured, so the freeze forbids a further amendment and it is disclosed as a dated post-hoc diagnosis — as a wording error in our own frozen FC-4 anchor ("vanish" is guaranteed only under
full-family conditioning), and as a general caution about mid-percentile EXTREME calls on
distribution-floor atoms of near-threshold mass. Neither correction touches the gate-bearing
controls: FC-1 (positive controls) and FC-3 (manufacture alarm) reference no matched-null quantity.

Look-elsewhere ledger: the five off-home family predicates applied to King Wen (J1, M1, M3, M4,
B1 — all expected-fail, all failed) are logged conservatively: global observable count 86 → 91 (frozen).

*Attribution.* The Jing Fang and Mawangdui orderings are classical Chinese artifacts, not project
inventions (traditional attribution to Jing Fang, 77–37 BCE; the Mawangdui manuscript's tomb was
sealed 168 BCE; historical certainty of the palace ordering's authorship is debated). Sources:
[Shaughnessy (2022)](CITATIONS.md) for the Mawangdui construction, with
[Cook's (2006)](CITATIONS.md#cook2006) concordance table and Marshall's biroco.com conversion chart
as cross-checks per the 2026-07-05 erratum; [Schulz & Cunningham (1990)](CITATIONS.md#schulz-cunningham1990)
for the gender-blocked upper axis; the standard palace construction for J1–J5
([CITATIONS.md](CITATIONS.md#jingfang) — alternative palace-internal conventions exist; corrections
welcome). [Drasny (c. 2007)](CITATIONS.md#drasny2007) discussed the regular grouping of the
pre-Yijing hexagram arrangement well before this project — the reading of the comparison orderings as
regular/algorithmic has prior art and is recorded as such. The corpus-control specificity gate
defined here is the one consumed by the F4′, cycle-structure, and Davis pre-registered tracks above
([Davis 2012](CITATIONS.md#davis2012); [Li Shangxin](CITATIONS.md#li2008) credited there per Davis
p. 119 n19). Errors of operationalization are ours (developed with AI assistance — Claude,
Anthropic); sinological corrections are invited and reopen the frozen design via dated amendment.

## Pre-registered test: F4' ordering-layer functionals (registered 2026-07-04; measured same day — all 13 null, results below)

To keep the look-elsewhere accounting honest, this registration is published BEFORE any population
number has been observed. Thirteen integer-valued ordering-layer functionals — each derived from an
axis already present in the literature (Jing Fang palaces, Zheng Qiao/Hu Yigui trigram clustering,
Cook nuclear structure, [Schulz](CITATIONS.md#schulz1990-motifs) gender drift, [Moore](CITATIONS.md#moore1989) run structure, [Davis](CITATIONS.md#davis2012) complement adjacency,
[Lai Zhide](CITATIONS.md#laizhide) halves, Zhu Yuansheng parity, Chan lag-1 autocorrelation, McKenna wave asymmetry, the Fu Xi
binary axis, symmetric-hexagram placement, and the circular wrap class) — are implemented and gated in
`solve.py --f4p-verify` / `solve --f4p-verify` (two-language, KW values embedded). Decision thresholds,
fixed in advance: "notable" = two-sided p < 0.05/13 (Bonferroni); "candidate rule" = < 10⁻⁴ after
Bonferroni AND passes the corpus-control specificity test (Jing Fang / Mawangdui must not flag on the
same functional). All 13 results will be reported regardless of outcome; a null result is a finding
(the ~126-bit residual surviving its first systematic literature-guided attack). Nothing promotes to a
solver constraint regardless of outcome, per the standing extraction-circularity policy above.

⚠ **`ulimit -s unlimited` is REQUIRED for every `--estimate-knuth` command in this document.** Under the default 8 MB stack the estimator does not start: `main` allocates a ~7.23 MB frame and `estimate_tree_knuth` a further ~1.02 MB (since 2026-08-21 the binary refuses with an actionable message; previously a bare SIGSEGV). *(Added 2026-08-21, an execution-lane finding — `scripts/exec_lane.sh` executes every documented command on a default environment; the same-day warning propagation (`1e4bd04a`) covered the four estimator guides but missed this file.)*

**Results (2026-07-04, tier-1, 2×10⁹ probes — reported in full as pre-committed):** all 13 functionals
NULL at the frozen thresholds. Closest calls: dist_autocorr (KW at the ~96.6th percentile) and palspan
(top bin, shared with 12.1% of the space) — neither approaches the Bonferroni gate. One functional
(par_switch) turned out to be CONSTANT across the entire space — a theorem, not a statistic (proof in
[reports/TR6](../reports/TR6_PARITY_SKELETON.md); it is a corollary of the 15-alternations theorem plus pair parity structure), joining the
"forced, not chosen" class of [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md). Net: the ~126-bit residual ([TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md)) survives its first systematic
literature-guided attack. Evidence and per-functional masses: the archived tier-1 run output
`reports/evidence/f4p_tier1.out` (all 13 `[f4p ...]` scoreboard rows — mean/min/max/KW value and
below/at/above-KW masses — plus full `f4p_hist` per-functional value histograms);
regeneration: `SOLVE_KNUTH_SCORE_F4P=1 SOLVE_KNUTH_F4P_HIST=1 ./solve --estimate-knuth 2000000000`
(both flags documented in [SOLVE_C_CLI.md](SOLVE_C_CLI.md) §ENVIRONMENT).

## Pre-registered test: permutation cycle structure (registered 2026-07-09; measured 2026-07-10 — all 13 null)

Following the F4' discipline, a second observable family was frozen BEFORE measurement: treat King Wen as a
permutation of the binary hexagram index and score its cycle structure. Thirteen functionals — cycle count,
longest cycle, fixed points, 2-cycles, order (lcm), and word-descents, each under BOTH the native
(bit0=bottom, OEIS A102241) and the [Ge 2026](CITATIONS.md#ge2026) (bit0=top) conventions, plus the
convention-invariant sign — are implemented and gated in `solve.py --perm-verify` / `solve` (two-language,
KW values embedded). Same frozen thresholds as F4' (notable = two-sided p < 0.05/13; candidate < 10⁻⁴ +
corpus-control specificity). Operative null = the C1–C5 canonical-mass population. This axis is deliberately
**report-only with no promotion path**: the binary indexing postdates King Wen by ~2 millennia, so even a
positive result could not be a design principle its authors used.

**Results (2026-07-10, tier-1, 2×10⁹ probes — reported in full as pre-committed):** all 13 functionals NULL
at the frozen thresholds. Closest call: cycle count (native), KW = 7 at ~the 94th percentile (two-sided
p ≈ 0.30) — nowhere near the Bonferroni gate; nothing reached the tier-2 escalation band. ⚠ *(Figure
corrected 2026-09-01: this read "two-sided p ≈ 0.13", which is 2 × the strictly-above mass and so
**excludes** the equality atom, while this family's frozen convention — `solve.py` §R3 header, "two-sided
atom-inclusive", and `reports/evidence/f5/README.md` — is p = min(1, 2·min(P(X ≤ kw), P(X ≥ kw))) with the
atom counted on both sides. From `reports/evidence/perm_tier1.out` line 7 (`perm_ncyc_bot`: below =
0.84806881, at = 0.08840103, above = 0.06353016) the registered statistic is 2 × (0.08840103 + 0.06353016)
= **0.30386238**; the withdrawn 0.13 is 2 × 0.06353016 = 0.12706032. The atom at KW's value carries 8.84%
of the mass, so no atom-respecting convention reproduces 0.13 (mid-p would give 0.2155). The same sentence's
"~94th percentile" is below + at = 0.9365 and was already atom-inclusive — the one sentence mixed the two
conventions. **The NULL verdict is unchanged**: 0.127 and 0.304 are both far above the 0.05/13 = 3.8×10⁻³
Bonferroni gate, and this family is report-only with no promotion path, so no downstream figure moves.)* The exact
cycle-type-match rate (5.2×10⁻⁶ native / 9.1×10⁻⁴ Ge) is reported data-like with no p-value, since an exact
multiset match is rare for any specific permutation. So [Ge 2026](CITATIONS.md#ge2026)'s cycle-type
observation stands as a descriptive fact about the sequence, not a King-Wen-distinguishing signal; the
residual survives this attack too. Evidence: `reports/evidence/perm_tier1.out`; regeneration:
`SOLVE_KNUTH_SCORE_PERM=1 SOLVE_KNUTH_PERM_HIST=1 ./solve --estimate-knuth 2000000000`. Look-elsewhere
ledger: global observable count → ~83 [STALE running count — superseded by the frozen 91-observable ledger; see METHODS §Global observable ledger].

## Pre-registered tests: Davis (2012) structural claims (wave 1 registered 2026-07-04; wave 2 frozen 2026-07-10, measured 2026-07-11)

Scott Davis, *The Classic of Changes in Cultural Context* (Cambria, 2012), asserts specific positional
structures in the King Wen ordering and argues against purely mathematical explanation. Following the F4'
discipline, nine composite candidates operationalized from his claims are registered here BEFORE any
population number has been observed: (1) terminal-pair one-line-neighborhood contiguity (n_runs; KW=3) +
exact-union template; (2) the hexagram 7-16 complement-mirror block (10-window mirror about its center);
(3) the #43-50 regular trigram array (+ count of qualifying 8-windows); (4) the 30s/40s parallel
(head-pair complementation at slot distance 5 + chiasmus template); (5) palindrome-neighborhood
adjacency mass; (6) rotation-equals-inversion pair placement; (7) pure-hexagram placement; (8)
eccentric-class placements (incl. the 23/24-43/44 distance-20 subset); (9) both-asymmetric-trigram
half-split (KW=4/16). Thresholds as F4': two-sided p < 0.05/9 Bonferroni "notable"; "candidate rule"
additionally requires the corpus-control specificity gate. All nine will be reported regardless of
outcome; nothing promotes to a solver constraint regardless. Full operationalizations with KW values are
frozen in the private audit (derived-insights-only handling of the copyrighted source; claims cited by
page in the eventual report).

**Davis results (2026-07-04, reported in full as pre-committed):** of the nine registered candidates,
Davis's flagship compositional claims (terminal contiguity, the 7–16 mirror, palindrome adjacency, the
asymmetric half-split) are NULL after Bonferroni; the #43–50 trigram array is notable (6.8×10⁻⁴ — at its
family correction; it does not survive the global 91-observable ledger's ≈5.5×10⁻⁴ **Bonferroni** bar,
though it *would* survive that same ledger under BH-FDR at q = 0.05 — the one verdict in the suite the
correction family moves, disclosed at METHODS §"Correction-family disclosure"); the
exact-placement templates are rare-by-construction (data-like class — including two with zero sampled
mass at 2×10⁹ probes) and, per the standing circularity policy, carry no design inference; corpus
controls (Jing Fang, Mawangdui) score zero on every flagged predicate. Under the strict two-sided
convention nothing reaches the candidate-rule level; nothing promotes. Full treatment:
[reports/TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md).

**Davis wave 2 (2026-07-11, reported in full as pre-committed):** the structural audit queue's
unmeasured tail — two functionals: the coordinated rotation-quartet count at Davis's own
compactness (pp. 113–114), and the Xun-at-x7/x8-slot count (p. 114) — has its complete design fixed
in the **public** record: commit `09e2107` (2026-07-11) carries both functional definitions, their
expected KW values, the two-language `--dav2-verify` gate, the C-D5 decline, and the /12 denominator,
before the results landed publicly (`5ace541`). A git-timestamped private pre-registration (2026-07-10)
additionally records the pre-measurement freeze, but is retained as auditor-disclosable provenance only —
nothing here rests on it, because both results are denominator-invariant nulls (see TR-10 §3b). Measured
2026-07-11 at 2×10⁹ probes —
a batch-landing variant of wave 1's public pre-registration, stated plainly as such. Both
**NULL** at the cross-wave 0.05/12 gate (frozen in advance, stricter than wave 1's /9): a
Davis-compact quartet is population-common (P(≥1) = 0.876, mean 1.86; KW = 1, *below* the mean;
two-sided p = 0.849), and the Xun-slot count is mildly above expectation (KW = 5, mean 2.90,
two-sided p = 0.148). One further queue item was subsumed, not separately measured (the pair-unit
trisection is a sub-predicate of an already-registered functional; Li Shangxin credited per
Davis p. 119 n19), and one was declined on scope without measurement (the named-size candidate —
see the 2026-07-11 [HISTORY](HISTORY.md) entry; a landing-time power note shows its minimum
attainable p is 1/15 under the pair-exchangeable null, so it could never have registered).
Neither measured functional triggered the candidate gate; no corpus-control step fired; nothing
promotes. These two functionals were already counted in the (frozen 91-observable) global ledger when
the /12 family was registered — the ledger does not grow. Evidence:
`reports/evidence/dav2_tier1.out`; regeneration: `SOLVE_KNUTH_SCORE_DAV2=1
SOLVE_KNUTH_DAV2_HIST=1 ./solve --estimate-knuth 2000000000`. Full treatment:
[TR-10 §3b](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md).

## Measured descriptive scoring, not a pre-registered test: Drasny's "Rule of Ten" (D-B1, measured 2026-07-11)

József Drasny (*The Yi-globe*, 2007/2011, ch. IV — [drasny2007](CITATIONS.md#drasny2007); no relation
to Davis 2012's separately-named "rule of ten") observes that his eight trigram-defined functional
groups occupy decade-arithmetic "rooms" of the King Wen table, with ten deviant pairs. The
operationalization landed publicly first (commit `64e4a42`: bit-predicate classifier reproducing his
Table 4.1 64/64, KW conformity X = 22 embedded, two-language `--db1-verify` gate) before any
population number was observed, and the conformity count was then measured over the canonical C1–C5
population (2×10⁹ probes; population mean 6.87, observed range 1–20). **Process, stated plainly:
D-B1 was NOT publicly pre-registered** — the public-registration step this document applies to test
families was skipped (the only freeze was the public code commit), and the omission is recorded here
rather than repaired after the fact; the pre-registration step is mandatory for any future
population measurement. **Classification: data-like (a fitted description), and verifiably so.**
KW's X = 22 sits above the entire sampled population — but the rooms are King-Wen-derived: Drasny's
own derivation (pp. 76–77) reads each room off the listed KW ordinals of each group's members, and
mechanical re-verification shows every room is exactly the maximum-coverage decade window for its
group's KW positions (the one group whose best single window covers only 2 is the only group granted
two windows; the leftover cells form a residue room), so the fitted per-group coverages sum to
3+3+3+3+4+5+1 = 22 — **the conformity count scores the sequence against a template extracted from
the sequence, and its population extremity is the predicted signature of that extraction** (the same
signature as the Davis exact-placement templates above), not evidence of design. Accordingly no
p-value is attached and no design inference is drawn; what stands is Drasny's — credited —
descriptive observation, true as stated and the strongest ordinal observation in his book, now
population-quantified as a fitted description. His paper's revised variant (ten groups, four
"alien" pairs) inherits the same classification a fortiori: the revision that shrank the deviants
from ten to four is additional fitting. D-B1 belongs to a separate Drasny family (N = 4 if any
member is ever scored inferentially, at which point the family enters the global observable ledger
first); nothing here is scored inferentially, so the (frozen 91-observable) ledger is unchanged — the
descriptive-by-construction handling already applied to C5 above. Nothing promotes. Evidence:
`reports/evidence/db1_tier1.out`; regeneration: `SOLVE_KNUTH_SCORE_DB1=1 SOLVE_KNUTH_DB1_HIST=1
./solve --estimate-knuth 2000000000`; gates: `--db1-verify` (both languages). Full treatment:
[TR-10 §3b](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md).

## Pre-registered model comparison: four-class generative comparison — calibration RUN, verdict VETOED (registered 2026-07-10; vetoed 2026-07-20)

> **Outcome (corrected here 2026-08-01).** This section previously read "in flight … results pending" and
> stated the calibration "ha[d] not been run". That was stale by twelve days: the synthetic-draw
> calibration **ran on 2026-07-20 and FAILED its confusability gate**, and the frozen design's §6.3
> accordingly forbids computing or publishing any four-class Bayes factor, posterior or verdict — here or
> anywhere. No such result exists and none will be produced. The design description below is retained as
> the pre-registration record; see [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) §Outcome (v1.14). The
> veto is the honest outcome of a gate we froze in advance precisely so it could stop us.

Following the F4′/permutation pre-registration discipline, a four-class Bayesian model comparison over
the C1–C5 canonical-mass population has been frozen BEFORE any measurement. The classes: **M0**
uniform-valid (null), **M_G** greedy-builder (a sequential softmax arranger), **M_D** global-design
(Gibbs energy over the frozen literature-rule bundle, per-axis strengths), and **M_C** corrupted-precursor
(the [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) v1.7 corruption model, unchanged, with the grand-strict
population size N_gs measured directly this time). Model forms, numeric grids and priors, Jeffreys
decision bands, a synthetic-draw calibration run BEFORE the KW verdict (with a frozen confusability
veto), and a posterior-predictive adequacy layer against the full published functional battery are all
fixed in the frozen design. The design's publish-regardless provision — every marginal likelihood, all
six pairwise Bayes factors, and the full sensitivity grid to be reported whatever the direction,
including a verdict against M_C — was **conditional on the calibration gate passing, and is therefore
moot: the gate failed, so there is nothing to publish regardless of.** This axis was **report-only with
no promotion path**, and it does NOT grow the observable look-elsewhere ledger (it is a model comparison,
not a KW-rarity observable). **No Bayes factor, posterior, or verdict for the four-class comparison
exists, is stated here, or will be produced.** The direct N_gs
ingredient run fired the pre-registered stop-and-investigate gate (its measured value fell outside
the F11 derived bracket) and the flag was resolved 2026-07-13: the bracket was never a valid
confidence interval, a four-seed direct re-measurement gives N_gs = 4.50×10²⁵ (±6%, all three
convergence gates passing), and the [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) v1.7 corruption
verdict is re-affirmed (see TR-2 v1.12 §"Stop-flag resolution") — *a re-affirmation itself since
superseded: the two-model pair later failed its own confusability gate and the Bayes factor and
posterior are withdrawn as claimed results
([CORRECTIONS](CORRECTIONS.md) CX-25, CX-26; TR-2 v1.27), leaving them as the as-computed record
only*. Of the remaining ingredients, the
**synthetic-draw calibration RAN on 2026-07-20 and FAILED its confusability gate** — its per-class
confusion matrices and evidence bundle (draws.json, scores.json, calibration_report.txt, master seed
20260720) are published at [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) §Outcome — and the frozen
design's §6.3 then forbade the rest. The greedy-builder numerator, the completion simulation and the
KW-facing integration were never run and, under the veto, never will be. Ingredient bundle in
[`reports/evidence/r11/`](../reports/evidence/r11/).
*(Corrected 2026-08-01, lens sweep: this paragraph previously read "the remaining ingredients …
and the KW-facing integration have not been run; the full four-class design is staged as a separate
private freeze under the operator's resolve-first decision" — stale by twelve days, and directly
contradicted by the correction block that opens this section. A reader of the body concluded the
discriminating test was forthcoming rather than permanently vetoed.)*

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*

*Revision 2026-07-22 (C3 scope-consistency sweep): the 3.9th-percentile complement-distance figure carried three different scope labels in this document ("C1+C2 reference scope", "Rules 1-6 / C1+C2+C5", "C1-only"); all now state the measured scope, **C1+C2+C4+C5** (every constraint except C3 itself — the solve.py differential population). The project's own figures at the mislabeled scopes — C3|C1 = 6.42% (`--null-pair-constrained`, cited in this document since the null-model table), 7.35% at C1+C2 (solve.py Level-2 Monte Carlo), and the exact 8.106% at C1&C4 (`verify.py --check-null-g`) — rule out the C1-only and C1+C2 labels. No counts, shas, or conclusions changed — the multiple-comparisons accounting is unaffected (the C3 effect remains non-marginal at its correct scope).*

*Revision 2026-08-01 (lens sweep — C3 percentile flag): the 3.9th-percentile complement-distance figure is **flagged and withdrawn from citation**. It is a statistic of the 13,296-ordering `solve.py` differential slice, whose stated range [11.75, 14.5] cannot be the range of C1+C2+C4+C5 — the strictly smaller C1–C5 canonical contains orderings at cd = 6.125 — and the suite's own ledger gives 1.3287×10³⁸ / 1.097051×10³⁹ ≈ **12%** at that scope. The 2026-07-22 scope correction above fixed the figure's *label*, not the figure. Authoritative statement of the flag, and the measurement that would settle it: [SOLVE.md](SOLVE.md) §Rule 3. No canonical count, sha, or theorem changed.*
