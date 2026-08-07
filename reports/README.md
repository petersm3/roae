# ROAE Technical Reports — Index and Reading Guide

*The finding, first: this project began from the hypothesis that the King Wen sequence (the received
ordering of the 64 I Ching hexagrams) is **determined** by its published constraints. We enumerated, we
measured, and **the hypothesis is false** — about **5.21×10³¹** orderings satisfy the full C1–C7
inventory (a Knuth random-probe **estimate**, 95% CI [5.13, 5.29]×10³¹; the verdict needs only that the
count is not 1), and King Wen is unique only within **budgeted enumerated slices**, never in the full
space. That is a negative result about our own starting position, which is why it leads
([TR-4](TR4_SIZE_OF_THE_SPACE.md) §Abstract owns the measurement). Two labels travel with it: it is
**a measured confirmation of prior under-determination claims** — the direction was stated
qualitatively by Ouyang Weicheng (1990), Zhang Qingyu (1998) and Suenaga (2012) before this project
measured it ([prior negatives](../documentation/CITATIONS.md#uniqueness-conjecture)) — and **the
magnitude is a single-instrument estimate** (solve.c's estimator alone; the suite's two-instrument
exact quantities are all C3-free). Neither label is a correctness doubt — the estimator is validated
against exact ground truth at both layers where it exists ([TR-4](TR4_SIZE_OF_THE_SPACE.md)
§"Estimator calibration") — they are novelty and instrument-coverage scoping. The suite around it treats the
sequence as a combinatorial object — enumerating, measuring, and proving; the repository README is the
front door, these reports are the findings in depth.*
*Technical reports — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. The covers' authorship disclosure holds suite-wide: the same
author wrote the claims, the software that checks them, and the reports that grade the check —
independent in mechanism, never in authorship, and no independent party has yet audited or reproduced
any of it (METHODS.md §"Authorship independence"). Each report ends with a Verification Guide mapping
claims to commands and certificates. The known gaps are disclosed where they occur, not here: cost figures are
rounded from an exact ledger withheld under the project's no-cloud-identifiers policy
([TR-3](TR3_REPRODUCIBLE_ENUMERATION.md) §Verification Guide); the scheduled-reclamation observation is a
single-campaign pattern whose second run's per-eviction timestamps are not public
([TR-3](TR3_REPRODUCIBLE_ENUMERATION.md) §4 and its figure caption); the bit ledger's accounting
conventions are judgment-dependent by construction ([TR-9](TR9_PRICING_THE_CONSTRAINTS.md) executive
summary); and one load-bearing baseline currently has no artifact in the repo, flagged as such at its own
claim site ([TR-8](TR8_REORDERING_REVISITED.md) executive summary). Where a measured claim has no
reproduction command, the report carrying it says so at the claim.*

Every report opens with a plain-language executive summary — start there. For a one-page scorecard of what the suite has settled (refuted / corrected / forced / confirmed), see [CLAIMS_DECIDED](../documentation/CLAIMS_DECIDED.md). For the append-only record of every claim this suite published and later withdrew, rescoped or corrected — with what was claimed before, what is claimed now, and how it was found — see [CORRECTIONS](../documentation/CORRECTIONS.md). Reports are numbered by our assessment of significance and impact (numbering is editorial, not a ranking
law — impact is audience-relative; see the reading paths). Each stands alone; together they cover the
record. Reproducibility contract: [CANONICAL_HASHES](../documentation/CANONICAL_HASHES.md); attribution registry: [CITATIONS](../documentation/CITATIONS.md).

| # | Report | One-line claim | Verification core |
|---|---|---|---|
| [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) | Eight Centuries, Measured | The literature's rules at population scale: forced / typical / discriminating; the grand precursor; the conflict | the flagship; all modalities |
| [TR-2](TR2_THE_RULES_CONFLICT.md) | The Rules Conflict | The four strongest rules cannot all hold at once (no C1∩C2∩C4∩C5-valid ordering can be perfect under all four); KW's anomalies are a forced trade-off, not damage to such an original; a pre-registered Bayes factor favored corruption of the three-graded-rule precursor over soft tendency — but **that pair failed its own confusability gate** (M_tend self-recovery 68/100 against a frozen 70; the failure is confined to the V=0 stratum, and the received sequence has V=6), and the BF and ≈0.9998 posterior are now **withdrawn as claimed results** ([CORRECTIONS](../documentation/CORRECTIONS.md) CX-25, CX-26): they stand as the as-computed record — recorded, not claimed — pending a V-matched gate frozen before it runs. It is also **two-model only**: it does not exclude a greedy/local builder, nor that the three rules are post-hoc regularities, and the wider four-class comparison that would have tested those rivals was pre-registered, ran, **failed its own synthetic-draw confusability gate, and is permanently withheld** (TR-2 §6.3) | SAT + DRAT certs + pre-registered BF |
| [TR-3](TR3_REPRODUCIBLE_ENUMERATION.md) | Reproducible Enumeration at Scale | 10.5B records, twice byte-identical across two independent runs (5 + 7 = 12 Spot evictions total) at 15–20% of on-demand cost | sha registry + gates |
| [TR-4](TR4_SIZE_OF_THE_SPACE.md) | The Size of the Space | This project's own uniqueness hypothesis is false: ≈5.21×10³¹ orderings satisfy C1–C7 and King Wen is unique only within budgeted enumerated slices (1.3287×10³⁸ satisfy C1–C5; both are raw orientation-explicit counts — [METHODS](METHODS.md) §"Canonical quantities" — and both are estimates with stated CIs). A measured confirmation of prior under-determination claims ([prior negatives](../documentation/CITATIONS.md#uniqueness-conjecture)); the magnitude is a single-instrument estimate. Slice-unique boundaries admit ~10²⁶ | validated estimator |
| [TR-5](TR5_SYMMETRY.md) | Symmetry | Order-48 group, complete over all 64! relabelings (v2.0; prose-proven with machine-checked finite parts — see §3 scope); free action (every solution has exactly 23 record-level twins); a published negative corrected | proof + Lean + tree isomorphism |
| [TR-6](TR6_PARITY_SKELETON.md) | The Parity Skeleton | Exactly 15 alternations, always | prose + Lean kernel + SAT certs |
| [TR-7](TR7_CIRCULAR_READING.md) | The Circular Reading | Wrap parity forced; 5-wraps are 17.4% of the space yet 0 in 10.5B slice records | Lean + SAT witness + estimator |
| [TR-8](TR8_REORDERING_REVISITED.md) | A Reordering Revisited | [McKenna & Mair (1979)](../documentation/CITATIONS.md#mckenna-mair1979): premise measured (the claimed defects are among the sequence's rarest configurations, subject to TR-8's specification caveat); the Gray-code construction proven impossible under the pairing | 2-line proof + sampling |
| [TR-9](TR9_PRICING_THE_CONSTRAINTS.md) | Pricing the Constraints | C1 explains ~146 bits (and is optimal); C5 is confirmed description; **about 105–139 bits unexplained** (a range, not a point — the endpoints depend on which layers are granted explanatory standing: 105.4 retains every cut, even the data-like pins; 139.1 = log₂\|C1∩C2∩C4\| is the residual against the claimed-explanatory layers alone) | measured ledger (conventions stated) |
| [TR-10](TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) | A Textual Archaeology, Measured | [Davis's (2012)](../documentation/CITATIONS.md#davis2012) structural claims tested against the population: flagship units typical, one uniqueness claim corrected, exact templates data-like | pre-registered batch + corpus control |
| [TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) | Exact Counting by Symmetry Quotient | The suite's exact full-scale counts: \|C1∩C2∩C4\| = 7.5706×10⁴¹ (the suite's **first** exact full-scale count, 2026-07-04) and \|C1∩C2∩C4∩C5\| = 1.097051×10³⁹ (the second, 2026-07-16; independently recomputed at full scale 2026-07-25 by verify.c's IE transfer-walk engine — a different algorithm class, exact MATCH; mod-24- and ladder-corroborated), each computed to the last digit; the estimator validated absolutely at 10³⁹ | symmetry-quotient DP + out-of-core mode + mod-24 gate |

**Reading paths.** Newcomer: [TR-3](TR3_REPRODUCIBLE_ENUMERATION.md) → [TR-4](TR4_SIZE_OF_THE_SPACE.md) → [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md). Systems engineer: [TR-3](TR3_REPRODUCIBLE_ENUMERATION.md) first (its methods transfer
beyond this project), then [TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) (out-of-core exact counting on commodity hardware). Mathematician: [TR-5](TR5_SYMMETRY.md) → [TR-6](TR6_PARITY_SKELETON.md) → [TR-7](TR7_CIRCULAR_READING.md) → [TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md). Sinologist: [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) → [TR-2](TR2_THE_RULES_CONFLICT.md) → [TR-8](TR8_REORDERING_REVISITED.md).
Skeptic: [TR-3](TR3_REPRODUCIBLE_ENUMERATION.md)'s gates, then any Verification Guide.

## Living documents: the versioning policy

These reports **evolve**. New sources, new measurements, and corrections are incorporated over time —
never silently: every content change is a version bump with a Revision History entry in the affected
report, and claim corrections are stated as corrections (the project's standing practice; see the
corrected result documented in [TR-5](TR5_SYMMETRY.md)). Citations should name a version ("[TR-2](TR2_THE_RULES_CONFLICT.md) v1.0"). Snapshots are
archived with versioned DOIs (Zenodo: a concept DOI resolves to the latest state; version DOIs pin what
you read). Where a journal article is one frozen argument, these reports are the maintained state of what
is known — with its full history attached.

**Version lifecycle:** versioning discipline begins at publication. Pre-release drafts carry
`v1.0-draft` and may churn freely (git history is the audit trail); the first public release is stamped
`v1.0`; every subsequent content change to a published report is a version bump with a Revision History
entry — never a silent edit. *(Some reports' Revision Histories skip version numbers — e.g. a jump from
v1.2 to v1.6: these are suite-wide version-alignment bumps applied across the whole TR set at once, not
deleted entries; the skipped numbers were never issued for that report. Git history is the full audit trail.)*

## Completeness principle
The eleven reports cover the project's **findings**. Instruments, engineering internals, and the
exploratory statistical corpus (the 28-analysis suite, trigram profile, distributional studies) are
covered by the standing documentation set (CLI references, [DEVELOPMENT](../documentation/DEVELOPMENT.md), [DISTRIBUTIONAL_ANALYSIS](../documentation/DISTRIBUTIONAL_ANALYSIS.md),
example/) — deliberately not duplicated as reports. If a future result rises to finding-grade, it becomes
a new report or a version bump of the one it extends; the README's "What was found" list and this index
are maintained in lockstep.
