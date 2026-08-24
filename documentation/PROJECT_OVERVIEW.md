# Project Overview — the detailed findings narrative

This page holds the detailed findings narrative that formerly lived on the repository front page —
relocated during the 2026-07 front-page streamlining (nothing was deleted; scope notes have since been
reconciled in place). For the tight front-facing summary, see [README.md](../README.md); for depth per
finding, see [reports/](../reports/).

> **Authority note (legacy narrative).** This page predates the 2026-07 technical-report suite and is
> retained as the project's narrative record. Where this page and the
> [technical reports](../reports/README.md) (or [CRITIQUE.md](CRITIQUE.md)) disagree, **the reports
> win** — the discrepancy is a bug in this page; please report it (the same convention as
> [CLAIMS_DECIDED.md](CLAIMS_DECIDED.md)).

Can the King Wen sequence be reconstructed from its mathematical constraints? Five constraints narrow 10^89 possibilities to an estimated ≈1.33×10³⁸ valid orderings (the "billions" figures below are *budget slices* of that space, not the space itself). The deepest published partial enumeration finds **10,525,271,997 canonical orderings** at the d3 560T budget (sha `9a968fa2…`, established 2026-06-08; CANONICAL-verified 2026-06-30). Canonical counts and the sha256 hashes that anchor them — across multiple partition strategies and node budgets — are listed in [CANONICAL_HASHES.md](CANONICAL_HASHES.md). All listed canonicals are partial enumerations; under true exhaustive enumeration they would converge.

Across the three deepest canonicals the per-cell record sets are strictly nested (11.2T ⊆ 100T ⊆ 560T, 0 monotonicity violations under pair-identity keying) and grow sublinearly (×50 budget → ×13.86 records), driven by deepening of existing productive cells rather than new regions — and remain unsaturated (every sampled sub-branch is still budget-limited), so each is a reproducible *slice* at a fixed budget rather than a final count.

The **number of boundary constraints needed to uniquely identify King Wen is 4 at d2/d3 10T and 5 at both d3 100T and d3 560T** — monotone non-decreasing with scale, with the identical greedy set `{1, 4, 21, 25, 27}` at both canonical scales *(corrected 2026-07-04: an earlier version reported "4 again at 560T, non-monotone" — a survivor-counting error, see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md))*. Boundaries **{25, 27}** are in every greedy minimum at all four partitions tested (most stable structural finding).

See [SPECIFICATION.md](SPECIFICATION.md) for the formal definition, [SOLVE.md](SOLVE.md) for the constraint analysis (`solve.py` + `solve.c`), [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) for a plain-language version, or [PARTITION_STABILITY_BOUNDARIES.md](PARTITION_STABILITY_BOUNDARIES.md) + [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md) for the paper-citable stable findings. The binary output format is in [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md); [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md) is a step-by-step recipe for building an independent verifier from those two specs alone. Enumeration results are in `enumeration/`. Full `solve.c` command-line reference (subcommands, env vars, exit codes) is in [SOLVE_C_CLI.md](SOLVE_C_CLI.md).

**Important methodological note.** Constraints C1–C2 (pair structure, no 5-line transitions) are genuinely rare statistical properties of King Wen — the pair structure does not appear in any random permutation we tested (0 of 1.86 billion across the six unconditional null-model families; the seventh, pair-constrained family of the framework satisfies C1 by construction). Constraint C3 (complement distance ≤ 776) is a ceiling constraint using KW's own value; per the 100T and 560T d3 analyses, **KW sits AT the C3 ceiling, not the floor** — a large fraction of records tie with KW at C3=776, and the minimum C3 is 424 (221 records at 100T). Constraints C4–C7 were **extracted from King Wen** (exact starting pair, exact distance distribution, specific boundary adjacencies) and then shown to be highly constraining against King Wen. A null-model test (see [CRITIQUE.md](CRITIQUE.md)) found that applying the same extraction methodology to random pair-constrained sequences also produces apparent "uniqueness" in 9/10 cases.

The honest claim is therefore: *pair structure + no-5 are the robust findings against random; boundary identification of KW needs 4 boundaries at 10T and 5 at canonical depth (100T/560T) — the "exactly 4 specific boundaries" framing is scale-bounded (0 working 4-tuples at d3 100T and d3 560T; see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md)). This reflects the constraint-extraction methodology rather than evidence of KW's inherent specialness beyond the robust pair-structure + no-5 findings.* The full bit-level accounting — what each constraint explains, at what statement cost, and the ~105–139-bit unexplained residual — is in [DESCRIPTION_LENGTH.md](DESCRIPTION_LENGTH.md).

## Example

See [example output](../example/README.md) for a full run of [`roae.py`](ROAE_PY_CLI.md) against the King Wen sequence — hexagram reference tables, 28 statistical analyses, and derived visualizations (`.csv`, `.json`, `.svg`, `.html`, `.pdf`, MIDI wave rendering).

### `roae.py` vs `solve.c` — two different kinds of output

These are easy to confuse; they serve different roles:

| | `roae.py` → `example/` | `solve.c` → `runs/<run>/` |
|---|---|---|
| **What it analyzes** | King Wen itself as a given 64-hexagram sequence | The full space of 10^89 possible orderings, filtered to solutions satisfying C1-C5 |
| **Output** | Descriptive statistics about KW (trigrams, pair structure, entropy, complement distances, palindromes, Markov patterns, Gray-code comparisons, 28 analyses total) | Enumeration artifacts: `solutions.bin` (millions of valid orderings), `solutions.sha256` (reproducibility anchor), `analyze_output.log.gz` (statistics across the solution set) |
| **Deterministic?** | Fully — the sequence is fixed, analyses are closed-form | Fully — given fixed solver + inputs, `solutions.bin` is byte-identical (partition invariance) |
| **Scale** | Single sequence, prints instantly | Hundreds of millions of orderings; canonical runs take hours on D128 |
| **Dependencies** | Python 3 stdlib only (optional deps for `.pdf`, `.html`, `.mid`) | `gcc`, `pthread`, `sha256sum` (no library dependencies) |
| **Who reads it** | Anyone curious about KW's internal structure (the "what"); no enumeration insight | Researchers evaluating the uniqueness question ("how special is KW among all C1-C5 orderings?") |

Both are committed in the repo. The `example/` output is generated by running `roae.py`; the `runs/<run>/` directories archive summaries (sha, meta, compressed logs) of actual enumeration runs against Azure compute. The binary `solutions.bin` files themselves are too large to commit (~10-65 GB each) and live on persistent Azure managed disks — see [enumeration/SOLUTIONS_BIN_LOCATION.txt](../enumeration/SOLUTIONS_BIN_LOCATION.txt).

## Observations

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is traditionally attributed to [King Wen of Zhou](https://en.wikipedia.org/wiki/King_Wen_of_Zhou) (~1000 BCE). It is not random, but it's also not optimized for any single obvious metric. The evidence stacks up:

- **The pair structure is perfect** — every one of the 32 pairs is a reverse or inverse, and zero random permutations out of 10,000 achieved this. (The pair structure itself is a classical observation — described by [Yu Fan](CITATIONS.md#yufan), 164–233 AD; [Radisic 2026](CITATIONS.md#radisic2026) proved it is the unique Hamming-cost-optimal comp/rev pairing — see [CITATIONS.md](CITATIONS.md). The rarity measurement is ROAE's.)
- **The no-5-line property is real but not astronomically rare** — about 1 in 550 random orderings share it. Notable, not miraculous.
- **Combined constraints are rare but context matters** — zero unconstrained random permutations satisfy both the pair structure AND the no-5 property together. However, among orderings that already satisfy the pair constraint, ~4% also avoid 5-line transitions (~1 in 23). The pair structure largely explains the no-5 property, since within-pair transitions are always even-distance.
- **Its entropy is mildly low, but not significantly so** — difference-wave entropy sits at the ≈12th percentile against the unconstrained null (6th against the pair-constrained null), more ordered than most random permutations but **not significant after Bonferroni correction** — see [CRITIQUE.md](CRITIQUE.md).
- **The wave has no detectable periodicity** — (the difference-wave construction is [McKenna & McKenna 1975](CITATIONS.md#mckenna-mckenna1975)'s) — autocorrelation drops off immediately, and the FFT shows no dominant frequency, though with only N=63 data points the statistical power to detect weak periodicity is limited.
- **The Markov transition matrix is not unusual** — a permutation test shows King Wen's transition structure is at the 43rd percentile, indistinguishable from random orderings. Apparent patterns (e.g., "6 is always followed by 2") are based on small samples and are not statistically significant.
- **The path length is typical for its structure** — compared against unconstrained random orderings, King Wen appears rough (97th percentile, 3.35x a Gray code). But compared against the correct null model (random orderings that also satisfy the pair constraint), it's at the 29th percentile — completely typical.
- **Complements are unusually close — with the scope stated** — King Wen places complementary hexagrams closer than random (0th percentile **against unconstrained random permutations**; under the exact pair-constrained C1&C4 null the tail is **8.1%** — P(C3 ≤ 776) = 8.106%, `verify.py --check-null-g`; the 3.9th-percentile figure is a sampled measurement at the stricter C1+C2+C4+C5 scope, every constraint except C3 itself — scope label corrected 2026-07-22, and the figure **flagged 2026-08-01** as unsupported by that population, ledger ≈12%, see [SOLVE.md](SOLVE.md) §Rule 3). Within the fully constrained C1–C5 population, the picture inverts: KW sits at the C3 **maximum** — most valid orderings place complements closer (see [SOLVE.md](SOLVE.md)'s C3-ceiling note and [CRITIQUE.md](CRITIQUE.md)).
- **The XOR algebra is a theorem** — 32 pairs produce only 7 unique XOR products. This is not a property of King Wen — it is a mathematical consequence of any reverse/inverse pairing of 6-bit values (see [SOLVE.md](SOLVE.md#theorem-2-xor-regularity-is-a-theorem-not-a-constraint)).
- **Palindromes, canon split, recurrence, and neighborhoods are unremarkable** — under appropriate null models, all are within chance expectations. Palindromes are at the 49th percentile (pair-constrained), the canon split at the 12th (the split itself is classically attested — Zhang Xingcheng and Zhu Xi, Song, 12th c., Hu Yigui 1247; see CITATIONS.md), recurrence at the 72nd, and neighborhoods at the 12th.
- **The no-5-line property is not KW-exclusive** — `solve.c --null-historical` tests four documented orderings: **King Wen and [Jing Fang](CITATIONS.md#jingfang)'s 8 Palaces avoid 5-line transitions** (2 of 4); the [Mawangdui](https://en.wikipedia.org/wiki/Mawangdui_Silk_Texts) silk-text ordering has **exactly one** (at the octet seam #48 Jing → #51 Zhen, where its trigram-block construction resets), and the [Fu Xi](https://en.wikipedia.org/wiki/Shao_Yong) natural-binary ordering has two. *(Corrected 2026-07-05: an earlier erroneous Mawangdui array scored zero, and this bullet previously claimed "3 of 4" and a shared classical design principle; the corrected array follows [Shaughnessy 2022](CITATIONS.md#shaughnessy2022), Table 11.2 — see CITATIONS.md errata.)* What *is* King-Wen-specific within the tested historical set is the **combination** (C1 + C2 + C3 together). (C3's threshold of 776 is KW's own extracted value, so its "specificity" is definitional rather than a finding — every sequence is specific on its own extracted value; wording corrected 2026-07-22.)

The picture that emerges is of a sequence satisfying multiple simultaneous constraints — pair relationships and avoidance of certain transitions — none of which individually are impossible by chance, but which together are far beyond chance: zero of 10,000 random permutations satisfy the combination (95% upper bound from that sample: less than 1 in 3,333 — and the pair structure alone has analytic probability ≈10⁻⁴⁴ under the uniform null, so the joint rate is far below the sampled bound). Whoever arranged it (traditionally attributed to [King Wen of Zhou, ~1000 BCE](https://en.wikipedia.org/wiki/King_Wen_of_Zhou); the dating of the ordering's fixation is debated in modern scholarship) produced a permutation that behaves exactly as if built to combinatorial rules — whether those rules were held explicitly in mind or accumulated through generations of practice and refinement is outside what these measurements can decide (see [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) §"What we can and cannot say").

Note: with 28 analyses, some results will appear unusual by chance alone. The strongest findings (pair structure, combined constraints) survive multiple comparison correction. Weaker findings should be interpreted with caution. See [CRITIQUE.md](CRITIQUE.md) for known limitations.

See [MCKENNA.md](MCKENNA.md) for how these findings relate to [Terence McKenna's Timewave Zero theory](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero). For the sequence read as a cycle (McKenna's wrap-around) — what closure changes and the SAT-decided 5-line-wrap existence — see [CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md).

---

# Deep-analysis sections relocated from SOLVE_SUMMARY (2026-07-04)

These sections — per-position entropy, mutual information, the 560T/100T canonical analyses, orientation-freedom, yield clustering, and the distributional study — were moved here from the plain-language summary to keep that document readable for newcomers. Content verbatim:

### Per-position constraint strength (Shannon entropy)

Across the canonical datasets, the Shannon entropy H(p) of the pair distribution at each position p quantifies how much "choice" exists at that position (in bits; max possible is log₂(32) = 5.0 bits if any pair were equally likely). Values below are from the d3 10T canonical dataset (706M orderings; §[2], `runs/20260418_10T_d3_fresh/analyze_output.log.gz`):

| Positions | H (bits) | Character |
|-----------|---------:|-----------|
| 1 | 0.00 | Fully determined (only Creative/Receptive) |
| 2 | 4.29 | Near-free (28 distinct pairs observed) |
| 3-4 | 4.52, 4.50 | Most free of all positions (31 pairs each) |
| 5-20 | 0.48 – 1.85 | Highly constrained — the "cascade region" |
| 21-22 | 1.61, 1.74 | Transition |
| 23 | 3.15 | Transition into the freer back zone |
| 24-31 | 3.41 – 3.54 | Moderately free (14 pairs each) |
| 32 | 2.58 | Partial constraint (7 pairs) |

Mean H = 2.29 bits per position. Positions 2-4 are all high-entropy at d3 because the depth-3 enumeration partition leaves three near-free pair choices at the front (position 1 is forced); the cascade region proper begins at position 5 and carries only 0.5-1.9 bits each — a very different regime from the "free" regions above and below it.

*(Revision 2026-07-04, primary-evidence sweep: this table and the MI example below previously presented values from the legacy 742M dataset — an invalidated-era artifact retained for forensic reference only — mislabeled as "d3 10T" (pos 2 = 3.83, pos 3 = 4.12, "cascade 4-20", mean H = 2.05, top MI 19↔20 = 1.15). They have been replaced with the actual d3 10T log values, which also change the structural narrative: at d3 positions 2-4 are all near-free, and the cascade region is 5-20, not 4-20.)*

### How positions relate to one another (mutual information)

Pairwise mutual information I(p; q) measures how much knowing the pair at position p reduces uncertainty about position q. The strongest correlations are between adjacent positions in the cascade region (top pair at d3 10T: position 20 ↔ 21 = 1.39 bits; §[10]), reflecting the tight local propagation. Notably: **boundaries 25 and 27 — both mandatory — have weak mutual information with everything else** (max I ≈ 0.19 bits).

Per-boundary conditional entropy on d3 (`analyze_d3.log` section [18]) directly quantifies how much fixing a boundary to match KW reduces total sequence uncertainty (baseline: 73.17 bits across 32 positions). The most informative boundaries are the early ones: boundary 4 contributes 46.8 bits of information, boundary 5 contributes 42.7 bits, boundary 6 contributes 39.7 bits. **Boundaries 25 and 27 sit mid-pack at 9.96 and 10.64 bits** — roughly one-fifth the information content of the top boundaries. Yet they are mandatory while the high-information boundaries are interchangeable. What makes `{25, 27}` mandatory is not that they carry more information but that the information they carry is **structurally independent** of all other boundaries: they eliminate non-KW solutions that no combination of other boundaries can reach.

### Boundary redundancy and independence

Joint-survivor analysis (counting how many solutions match KW at *both* of two given boundaries simultaneously) reveals two distinct boundary clusters:

- **Boundaries 15-19 are fully redundant.** For every pair within this set, `joint(b1, b2) = min(survivors(b1), survivors(b2))` — knowing one of these boundaries implies all the others. The cascade region propagates so tightly that constraints near its end carry overlapping information.
- **Boundaries 26 and 27 are highly independent of the cascade region.** Joint/min-single ratios with cascade-region boundaries (3-8) are 0.007-0.010 — essentially uncorrelated. This is what makes them structurally valuable in the minimum-boundary set: they eliminate solutions that the cascade region cannot.

This explains why a minimum 4-set like {2, 21, 25, 27} (d2's greedy pick) or {1, 4, 25, 27} (d3's greedy pick) works: early boundaries catch the high-entropy choices in the front zone, and 25 and 27 contribute *independent* information not implied by any other boundary. The specific early-zone picks vary by partition depth; the mandatory-status of {25, 27} does not.

### 560T canonical results (2026-06-08, CANONICAL-verified 2026-06-30; analyze 2026-06-11) — current deepest enumeration

**560T canonical sha `9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`** — 10,525,271,997 canonical orderings, established by budgeted C1–C5 enumeration at 560 trillion node budget (per-cell budget 3.536 × 10⁹ × 158,364 cells). The full `--analyze` pass over the 10.5 B canonical record set was completed 2026-06-11 (3 h 47 m on D128 with the algorithmic rewrites in commits 8ac5e8f / fe58e71 / bf8d8a5 / c0ec4c3 — see [HISTORY.md](HISTORY.md) "June 10-11, 2026" entry). Headline findings (560T scope):

- **Greedy minimum boundaries to uniquely identify KW: 5**, set **{4, 27, 25, 21, 1}** (consumed in that order; each step eliminates the prior survivors) — identical in membership and greedy order to the 100T result. Boundary 4 alone eliminates 10,525,220,592 of 10,525,271,996 non-KW records (99.999%), then 27 → 481 survivors, then 25 → 14, then 21 → 1, then 1 → 0. The single record surviving the first four boundaries is rec#330177707 — KW with the pair blocks at positions 2 and 3 interchanged. *(Corrected 2026-07-04: previously reported as "4, set {4, 27, 25, 21}" — a survivor-counting error that stopped at 1 non-KW survivor instead of 0; see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md).)*
- **Working 4-subset count (§[8]) collapses to 0 at 560T**, vs 4 at 742M and 8 at 11.2T. At 560T (as at 100T) there is no 4-tuple of boundaries that, applied jointly to the 10.5 B record set, reduces survivors to ≤ 1 — consistent with the §[6] greedy minimum of 5. **This makes the "4-set uniquely identifies KW" framing scale-bounded; at canonical depth the minimum is 5.** *(Cross-era caveats, added 2026-07-04: the "8" is log-verified at d3 10T; the 11.2T attribution awaits confirmation from the archived 11.2T analyze log. The 742M figure of 4 was computed under the pre-format-v1 "survivors ≤ 4" convention — that format stored 4 orientation variants per ordering — whereas canonical-era §[8] uses "≤ 1"; the series is directionally sound but not convention-identical.)*
- **Mandatory boundaries 25 + 27 are still mandatory** under the greedy-ordered framing — both appear in the §[6] minimum set. The boundary-25/27 *independence* (§[9]: 25+27 ratio = 0.007) is reaffirmed: their information is not implied by any other boundary.
- **Complement distance (C3) = 776 still the CEILING.** KW is at the maximum of the constraint; large equivalence cohort at the 776 ceiling persists.
- **Edit-distance distribution heavily right-skewed**, mode at distance 30 with 2,789,988,449 records (26.5%). 96% of records are at distance ≥ 25 from KW. KW is structurally rare in the canonical-solution space at 560T scale.
- **Top pairwise mutual information**: pos 12 ↔ pos 13 = **1.3417 bits**; cascade-region positions 11–20 own the entire top-10 of pairwise MI. Mandatory boundaries 25, 27 do *not* appear in the top-20 MI pairs — confirming their structural independence from the cascade-region MI cluster.
- **Per-position conditional entropy headline (§[18])**: boundary 4 alone yields 45.14 bits of information gain (baseline H = 77.81 bits, summed over all 32 positions — position 1 contributes 0.00; wording corrected 2026-07-04 from "across 31 positions"). Boundaries 25 and 27 contribute 10.73 and 10.63 bits respectively — mid-pack on info-gain but indispensable in the *combinatorial* sense per the greedy result.

Full §[1]–§[28] analyze findings: see [HISTORY.md](HISTORY.md) "June 10-11, 2026" entry (public) and `roae-private/560T_FINAL_ANALYSIS.md` (operator-private working analysis log — in a private staging repo, not publicly accessible; a provenance pointer, not a fetchable source).

**3-point scaling trajectory (11.2T → 100T → 560T, 2026-06-14).** The per-cell record sets across the three deepest canonicals are **strictly nested** (11.2T ⊆ 100T ⊆ 560T) with 0 monotonicity violations under pair-identity keying — records 759,608,573 → 3,432,399,297 → 10,525,271,997, pair-identity cells yielding 9,799 → 10,062 → 10,618. Growth is **sublinear** (×50 per-cell budget → ×13.86 records; power-law α ≈ 0.67) and is **deepening, not broadening**: cells first appearing at a larger scale contribute only ~0.2% (→100T) and ~0.5% (→560T) of that scale's records. Every sampled sub-branch is still BUDGETED (none EXHAUSTED) at 560T, so the budgeted enumeration cannot report the total number of C1–C5-satisfying orderings — but an unbiased Monte-Carlo estimate (Knuth random-probe, validated <1%) puts it at **≈10³⁸** (≈3×10³⁷ distinct-canonical), so even 560T's 10.5 B records is ≈1 part in 10²⁷ of the space and no feasible budget approaches exhaustion (see [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md)). Each canonical scale is a reproducible slice at a fixed budget. A 1120T extension would have been a discriminating test of the growth asymptote rather than merely more data, but it is **not planned** (2026-08-01): 560T is the deepest canonical this project will produce, and the α ≈ 0.67 fit stands on the three measured points. ⚠ **[WITHDRAWN 2026-08-24 — this figure exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]**

### 100T d3 canonical results (2026-04-20; historical reference, superseded by 560T)

The 100T d3 canonical (sha `915abf30…`, 3,432,399,297 orderings, established 2026-04-20) was the deepest published enumeration prior to the 560T canonical above. Its findings are preserved here as a historical scale-comparison reference; 560T headline numbers above are now authoritative. *(Revision 2026-07-04: the 100T record count throughout this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-level "correction" had divided the file size by 32 without subtracting the 32-byte header; sha256 anchors unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.)* Findings (100T scope):

- **Boundary minimum was 5 at 100T** (greedy-optimal set **{1, 4, 21, 25, 27}**); the d2 10T and d3 10T canonicals had 4 specific boundaries uniquely determining KW. Boundaries {25, 27} remain mandatory across all three partitions. Note: the 560T re-evaluation above confirms the greedy minimum **stays 5 at 560T with the identical set {1, 4, 21, 25, 27}** — the trajectory is monotone 4 → 5 → 5 *(corrected 2026-07-04: this note previously claimed "4 again at 560T"; see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md))*.
- **Complement distance (C3) = 776 is the CEILING, not the floor.** KW's C3 is at the maximum of the constraint. about **1 in 10 (~10%)** of records tie at exactly 776 — this is a fraction measured over the enumerated set, not a universal constant: 9.91% over the 100T canonical (340,179,649 of 3.43B) and 10.11% over the deeper 560T canonical (1,063,580,364 of 10.5B), both correct at their depth and converging near 10% (the full-space value is unknown — the space was never fully enumerated). Minimum C3 is 424 (221 records) at 100T, 392 at 560T. Axiom "minimize C3" does NOT pick KW; KW is in a large ~10% equivalence cohort at the C3 ceiling. Rule 3 is a ceiling constraint, not a minimization (see updated §Rule 3). *Reference baseline (exact, added 2026-07-22):* the bare C1&C4 null — no C2/C5 conditioning, no budget truncation — already gives a ceiling-tie share of 7.86% (P(C3 = 776 | C3 ≤ 776), `verify.py --check-null-g`), close to the observed ~10%; the populations are not like-for-like, so this is a baseline, not a refutation — but it indicates the tie fraction is largely generic to the pair-slot geometry rather than King-Wen-specific structure.
- **Edit-distance distribution heavily right-skewed toward KW's far side.** Mode at edit distance 30 (867M records = 25.3%); only 10.87% of records within edit distance 25 of KW. KW sits in a sparse neighborhood of the solution manifold.
- **Shift-pattern conformance: 0.077%** (2,635,756 of 3.43B). Trajectory: d2 2.69% → d3 10T 0.062% → d3 100T 0.077%. Not monotonically decreasing.
- **Mean per-position Shannon entropy: 2.37 bits** (of 5.0 max). Similar shape to 10T; KW is identifiable within only ~7% of the 32 position slots without additional constraints.

Canonical sha256: `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5` (102.3 GB). See [`runs/20260419_100T_d3_d128westus3/`](../runs/20260419_100T_d3_d128westus3/) for the run archive and `analyze_output.log.gz` for the full data.

### Within-pair orient freedom: a constraint-geometry finding (not KW-specific)

King Wen appears exactly once per canonical dataset (d3: 1 variant, d2: 1 variant — the canonical dedup keeps the lex-smallest orient variant per pair-sequence). Earlier 742M-era analysis found 4 KW orient variants with coupling at positions {2, 3, 28, 29, 30}; the canonical format v1 with per-canonical-class dedup collapses these to 1. The pair-sequence is the invariant; orient variants are cheaply recoverable by testing 2^31 combinations. Running the orient-coupling generalization analysis (`--analyze` section [14]) across the canonical datasets shows:

In the canonical v1 format, each pair-ordering appears exactly once (lex-smallest orient variant kept; other variants cheaply recoverable by testing 2^31 combinations). The d3 10T dataset contains 706,427,594 unique pair-orderings (current canonical `b85c8871…`, re-established 2026-05-13; the 2026-04-18 `f7b8c4fb…`/706,422,987 is deprecated — see [CANONICAL_HASHES.md](CANONICAL_HASHES.md)); the d2 10T dataset contains 286,357,503. The 742M-era "4 KW orient variants" finding was an artifact of pre-format-v1 storage that stored all orient variants rather than collapsing them.

The underlying constraint geometry — that within-pair orientation is strongly CORRELATED rather than free — for King Wen's pair sequence, exactly 1,720,320 of the 2³¹ C4-oriented orientation vectors remain valid (~20.7 free bits; only 9 of the 31 bits can be flipped individually, but joint reconfigurations open far more than the old 'almost entirely forced' gloss suggested — corrected 2026-07-04 by exact fiber enumeration; scope note 2026-07-26: this is the fiber keeping C4's defined (63, 0) opening — under the pair-only reading of C4 the fiber is 2,703,360 vectors, the opening orientation being definitional rather than forced, see TR-1 §7 and the retracted "Theorem 6" in CLAIMS_DECIDED) — is unchanged. What changes is the STORAGE: canonical format v1 doesn't duplicate-store the orient variants that exist, it stores the canonical form + the implicit fact that some pair-orderings have multiple valid orient variants which could be regenerated on demand.

## Observed structural regularity: yield clustering + orientation-symmetry

An analysis of the 100T d3 canonical enumeration log (60,533 non-zero-yield
depth-3 sub-branches, one per valid (pair₁, orient₁, pair₂, orient₂, pair₃,
orient₃) prefix) — reveals strong regularity that is not visible in the merged
canonical records:

- **Only 9,325 distinct yield values across 60,533 sub-branches** (average of 6.5 sub-branches sharing each yield value). The enumeration is not "flat" across prefix classes; it has a strongly-clustered structure.
- **380 depth-3 prefix groups** (where a "group" = all 2³ = 8 orientation variants sharing the same (pair₁, pair₂, pair₃) triple) — every one of the 8 variants yields an **identical** solution count. That is: for these prefixes, orientation does not affect how many C1-C5-valid orderings extend the prefix.
- **16.3% of multi-variant groups overall (1,636 of 10,027)** exhibit this perfect orientation-symmetry. The remaining 83.7% show variant-dependent yields.

This pattern implies a **partial orientation-invariance property** of the C1-C5 constraint system on depth-3 prefixes: for a substantial minority of prefixes, the count of valid continuations depends only on the pair identities, not the hexagram-within-pair orderings.

Reproducibility: the built-in `./solve --yield-report` subcommand reads a solve.c enumeration log on stdin and produces this report. Invoke via `zcat enum_output.log.gz | ./solve --yield-report`. No external dependencies beyond what `solve.c` already requires.

## Observed distributional regularity: KW's position in joint observable space

Separate from the yield-clustering analysis above — at the record level across
the 3,432,399,297 C1-C5 valid orderings in the 100T d3 canonical — a 10-dimensional
observable-statistics vector was computed per ordering and KW's position in the
joint distribution was quantified via kernel density estimation + bootstrap.

**Headline result (corrected 2026-07-26):** an earlier version of this section
reported KW's joint-density rank as "< 10⁻⁵" with a log-density "~12,800× lower than
any sampled ordering", driven by KW being extreme on four dimensions simultaneously.
A circularity audit found that all four named driver dimensions were tautological,
KW-extracted, or extreme by construction — the result was an artifact of scoring KW
against its own template, and it is withdrawn. On the two KW-independent dimensions
(FFT dominant frequency and peak amplitude), **KW sits at roughly the 30th percentile
of joint density — inside the population bulk**. Its only non-circular deviation is
FFT peak amplitude at the 95.5th percentile, which does not survive the project's
look-elsewhere correction. Full method, exact counts, and the audit trail:
[DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md).

**A concurrent analytical finding: invariant transition-Hamming distribution.**
The multiset of 63 consecutive-hexagram Hamming distances is identical across
every C1-C5 valid ordering (direct consequence of C5's budget constraint —
it's the constraint itself, re-expressed). So any aggregate statistic of that
multiset (mean, max, variance) is structurally constant — not observable
variation to analyze.

Reproducibility: `solve.py --compute-stats` → per-record parquet, then
`solve.py --marginals`, `solve.py --bivariate`, `solve.py --joint-density`.
Full analysis: [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md).

---

*Revision 2026-07-22 (C3 scope-consistency sweep): the 3.9th-percentile complement-distance figure is now labeled at its measured scope (C1+C2+C4+C5 — every constraint except C3 itself; the exact pair-constrained C1&C4-null tail is 8.1%, `verify.py --check-null-g`); the "specific C3 threshold of 776" clause was reworded (the threshold is KW's own extracted value — definitional, not a finding); and an exact null baseline was added beside the ~10% ceiling-tie figure (a baseline, not a refutation — populations are not like-for-like). No counts or shas changed.*

*Revision 2026-08-01 (lens sweep — C3 percentile flag): the 3.9th-percentile complement-distance figure is **flagged and withdrawn from citation**. It is a statistic of the 13,296-ordering `solve.py` differential slice, whose stated range [11.75, 14.5] cannot be the range of C1+C2+C4+C5 — the strictly smaller C1–C5 canonical contains orderings at cd = 6.125 — and the suite's own ledger gives 1.3287×10³⁸ / 1.097051×10³⁹ ≈ **12%** at that scope. The 2026-07-22 scope correction above fixed the figure's *label*, not the figure. Authoritative statement of the flag, and the measurement that would settle it: [SOLVE.md](SOLVE.md) §Rule 3. No canonical count, sha, or theorem changed.*

*Revision 2026-07-26 (de-circularization + precision sweep): the joint-KDE headline in §"Observed distributional regularity" is withdrawn and replaced with the honest de-circularized result (KW ≈ 30th percentile of joint density on the KW-independent dimensions — see [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md)); the "seven null-model families" C1-zero claim is scoped to the six unconditional families; the "~3000 years ago" arranger clause is hedged to the traditional attribution. No counts or shas changed.*
