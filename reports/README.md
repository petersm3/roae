# ROAE Technical Reports — Index and Reading Guide

*Context in one line: ROAE analyzes the King Wen sequence (the received ordering of the 64 I Ching
hexagrams) as a combinatorial object — enumerating, measuring, and proving; the repository README is the
front door, these reports are the findings in depth.*
*Technical reports — not peer-reviewed. Every claim in every report is machine-verifiable; each report
ends with a Verification Guide mapping claims to commands and certificates.*

Every report opens with a plain-language executive summary — start there. For a one-page scorecard of what the suite has settled (refuted / corrected / forced / confirmed), see [CLAIMS_DECIDED](../documentation/CLAIMS_DECIDED.md). Reports are numbered by our assessment of significance and impact (numbering is editorial, not a ranking
law — impact is audience-relative; see the reading paths). Each stands alone; together they cover the
record. Reproducibility contract: [CANONICAL_HASHES](../documentation/CANONICAL_HASHES.md); attribution registry: [CITATIONS](../documentation/CITATIONS.md).

| # | Report | One-line claim | Verification core |
|---|---|---|---|
| [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) | Eight Centuries, Measured | The literature's rules at population scale: forced / typical / discriminating; the grand precursor; the conflict | the flagship; all modalities |
| [TR-2](TR2_THE_RULES_CONFLICT.md) | The Rules Conflict | The four strongest rules are jointly unsatisfiable; KW's anomalies are a forced trade-off; within the three graded rules, a pre-registered Bayes factor favored corruption over soft tendency — that Bayes verdict is UNDER REVIEW (v1.10): its pre-registered N_gs stop-flag fired | SAT + DRAT certs + pre-registered BF |
| [TR-3](TR3_REPRODUCIBLE_ENUMERATION.md) | Reproducible Enumeration at Scale | 10.5B records, twice byte-identical across two independent runs (5 + 7 = 12 Spot evictions total) at ~15% cost | sha registry + gates |
| [TR-4](TR4_SIZE_OF_THE_SPACE.md) | The Size of the Space | 1.3287×10³⁸ orderings; uniqueness conjecture false; slice-unique boundaries admit ~10²⁶ | validated estimator |
| [TR-5](TR5_SYMMETRY.md) | Symmetry | Order-48 group; free action (every solution has exactly 23 twins); a published negative corrected | proof + Lean + tree isomorphism |
| [TR-6](TR6_PARITY_SKELETON.md) | The Parity Skeleton | Exactly 15 alternations, always | prose + Lean kernel + SAT certs |
| [TR-7](TR7_CIRCULAR_READING.md) | The Circular Reading | Wrap parity forced; 5-wraps are 17.4% of the space yet 0 in 10.5B slice records | Lean + SAT witness + estimator |
| [TR-8](TR8_REORDERING_REVISITED.md) | A Reordering Revisited | [McKenna & Mair (1979)](../documentation/CITATIONS.md#mckenna-mair1979): premise refuted; construction impossible by parity | 2-line proof + sampling |
| [TR-10](TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md) | A Textual Archaeology, Measured | [Davis's (2012)](../documentation/CITATIONS.md#davis2012) structural claims tested against the population: flagship units typical, one uniqueness claim corrected, exact templates data-like | pre-registered batch + corpus control |
| [TR-9](TR9_PRICING_THE_CONSTRAINTS.md) | Pricing the Constraints | C1 explains ~146 bits (and is optimal); C5 is confirmed description; ~126 bits unexplained | measured ledger (conventions stated) |

**Reading paths.** Newcomer: [TR-3](TR3_REPRODUCIBLE_ENUMERATION.md) → [TR-4](TR4_SIZE_OF_THE_SPACE.md) → [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md). Systems engineer: [TR-3](TR3_REPRODUCIBLE_ENUMERATION.md) first (its methods transfer
beyond this project). Mathematician: [TR-5](TR5_SYMMETRY.md) → [TR-6](TR6_PARITY_SKELETON.md) → [TR-7](TR7_CIRCULAR_READING.md). Sinologist: [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) → [TR-2](TR2_THE_RULES_CONFLICT.md) → [TR-8](TR8_REORDERING_REVISITED.md).
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
entry — never a silent edit.

## Completeness principle
The ten reports cover the project's **findings**. Instruments, engineering internals, and the
exploratory statistical corpus (the 28-analysis suite, trigram profile, distributional studies) are
covered by the standing documentation set (CLI references, [DEVELOPMENT](../documentation/DEVELOPMENT.md), [DISTRIBUTIONAL_ANALYSIS](../documentation/DISTRIBUTIONAL_ANALYSIS.md),
example/) — deliberately not duplicated as reports. If a future result rises to finding-grade, it becomes
a new report or a version bump of the one it extends; the README's "What was found" list and this index
are maintained in lockstep.
