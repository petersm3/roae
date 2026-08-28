# Corrections — the append-only record

Every claim this project published and later changed, in one place.

This file follows the [HISTORY.md](HISTORY.md) pattern: an honest record kept *out* of the technical
prose, so that the technical prose can be about the mathematics and the record can be about what we
got wrong. It is **append-only**. Entries are never edited to look better and never deleted; if an
entry is itself wrong, a later entry says so and both stay. That property is machine-enforced — see
[Gates](#gates) below.

**Scope.** Corrections to *our own* published claims. Verdicts on other people's claims live in
[CLAIMS_DECIDED.md](CLAIMS_DECIDED.md); the narrative of how the project evolved lives in
[HISTORY.md](HISTORY.md); the exact retracted wordings, and the gate that stops them reappearing,
live in [RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv). This file is the join across all three.

> **Access boundary.** Some entries here — and rows of
> [CORRECTIONS_INVENTORY.tsv](CORRECTIONS_INVENTORY.tsv), which quotes commit messages verbatim —
> cite verification sweeps and review reports in `roae-private`, the project's private staging
> repository, which is not publicly accessible. Those citations record *how a correction was found*;
> they are operator-attested provenance, not evidence a reader can fetch. What each correction
> *changed* is fully public: the before/after wording in the entry itself and the named commit.

**Nothing here supersedes a report.** Where an entry and a technical report disagree, the report is
authoritative and the disagreement is a bug in this page.

---

## How this record is built

Entries are curated by hand from a mechanical sweep, `scripts/corrections_inventory.sh`, which writes
[CORRECTIONS_INVENTORY.tsv](CORRECTIONS_INVENTORY.tsv). The sweep unions **three independent sources**,
because each one alone has a known failure mode:

| Source | What it reads | Why it is not sufficient alone |
|---|---|---|
| `inline` | correction markers in the body prose of every tracked `.md` | a silent edit leaves no marker at all |
| `changelog` | per-report Revision-history rows (`\| v1.7 \| 2026-… \|`) | a revision row can *assert* a correction that never happened — TR-2 v1.20 records exactly that |
| `git` | commit subjects and bodies | a commit can carry a correction its message never mentions |

Each candidate is classified into one of four classes. The inventory's **`matched` column records the
keyword that drove the class** — not just the verdict. That column is mandatory. An earlier build of
the inventory recorded only the class and a truncated excerpt, so the evidence for "why is this row a
retraction?" was usually the part that got cut off; auditing a single row meant re-deriving the
classifier by hand, and that cost a full debugging cycle on 2026-08-01. A classifier that reports a
verdict without its reason is not auditable.

| Class | Meaning | In this file? |
|---|---|---|
| **C1** | **Retraction** — a published claim was withdrawn, or its truth value reversed | yes |
| **C2** | **Circulated scope-label** — the claim survived, but its scope or epistemic label changed *after* it had been repeated in other documents, so the fix had to be propagated | yes |
| **C3** | **Typo / consistency** — a value, digit, date, pointer or wording fixed with no claim changing | yes, where the corrected value was published |
| **C4** | **Qualifier** — a caveat or hedge was added or tightened | **no — excluded, deliberately** |

**Why C4 is excluded.** A qualifier is not historical debris; it is *live, load-bearing scope* in the
current text. "This is measured over C1∩C2∩C4∩C5, not over all orderings" is a statement a reader
needs at the claim site, today — filing it in a corrections ledger would move it out of the reader's
path and reframe a working scope statement as a past mistake. C4 candidates are still written to the
inventory and never deleted from it, so the exclusion is auditable rather than invisible: anyone can
run `awk -F'\t' '$3=="C4"' documentation/CORRECTIONS_INVENTORY.tsv` and check the judgement.

**C1 requires a hard retraction token** (*retract* / *withdraw* / *rescind*). It was first keyed on
soft prose — "that claim is false", "the premise was wrong", "refuted" — which produced 21 false
positives: every counterexample discussion and every sentence describing *someone else's* refuted
claim scored as one of our own retractions. Soft prose is now deliberately not a C1 token. The cost of
that decision is under-firing, and it is covered from the other side by the completeness gate below,
which is registry-driven and does not consult the classifier at all.

**The counts move, and are not the point.** The sweep's own last run is recorded at the
[foot of this file](#sweep-provenance) with the caveat that it is a moving target. It is a candidate
generator, not a census: a single correction usually produces many candidate lines (one per document
that repeats it), and prose that merely uses the word "caveat" also lands in the inventory.

---

## Entries

Each entry: **date · id · class · documents · claimed BEFORE · claimed NOW · how it was found ·
commit**. Retracted wordings are referenced by their registry key `RP-xxxxxxxx` (the first 8 hex of
the SHA-256 of the retracted string, as it appears in
[RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv)) rather than quoted, because quoting them here would
reintroduce the exact strings that `scripts/doc_gates.sh retract` exists to keep out of the corpus.

---

### CX-01 · 2026-04-09 · C1 · complement distance: direction reversed

- **Documents:** SOLVE.md, SOLVE_SUMMARY.md, roae.py output, and everything downstream of them.
- **BEFORE:** King Wen *maximizes* complement distance — presented as a discovered optimum.
- **NOW (2026-04-09):** the direction was reversed. The original reading was an artifact of circular
  filtering: the population it was scored against had already been filtered by a KW-derived criterion.
- **How it was found:** self-review — one of six adversarial review rounds run against the
  documentation before any of it was published. Not a gate; there were no gates yet.
- **Commit:** `5494eba`, whose own subject reads "King Wen MINIMIZES complement distance, not
  maximizes".
- **This entry has been corrected twice since, and the wording of the fix is the reason.** The
  2026-04-09 fix asserted *minimizes*, which is also wrong: CLAIMS_DECIDED now grades this
  **CORRECTED (self)** with the finding that 776 is a **ceiling King Wen sits at, not a minimum**
  (minimum 424 at 100T, 392 at 560T, ~10% tie). The percentile figure that stood in for the magnitude
  in the meantime was separately flagged in 2026-08-01 — see CX-13. The *direction* has stood since
  2026-04-09; every quantitative statement attached to it has moved at least once.

---

### CX-02 · 2026-04-11 · C1 · the "locked positions" and "complete generative recipe" claims

- **Documents:** SOLVE.md, SOLVE_SUMMARY.md, README.md, GUIDE.md.
- **BEFORE:** 23 of 32 pair positions are locked across all solutions; 2 adjacency constraints
  uniquely determine King Wen; a complete generative recipe exists.
- **NOW:** exactly one position is locked (position 1). The 23-locked figure was an artifact of a
  438-solution sample drawn from a single search branch. Millions of orderings satisfy the pair
  constraints, and the recipe does not determine the sequence.
- **How it was found:** **measurement overturned it, not review.** Six rounds of adversarial review
  had already passed over these claims and left them standing; what killed them was running the C
  solver for one hour and finding 20,110,129 unique pair orderings. Review cannot refute a claim whose
  only support is a too-small sample — only a bigger sample can.
- **Commit:** see [HISTORY.md](HISTORY.md) 2026-04-11.

---

### CX-03 · 2026-05-25 · C1 · the +9.2% PGO speedup

- **Documents:** PERFORMANCE_HISTORY.md, and the records-per-dollar and 560T cost projections that
  depended on it.
- **BEFORE:** the LTO + PGO + bitset stack buys +9.2%, quoted as a forward-looking planning figure.
- **NOW:** **retracted** as a forward-looking claim. The +9.2% was never measured — it was the
  *product* of two separately measured factors (LTO ×1.0253 × PGO ×1.065), and the composite did not
  replicate: the re-run measured v3 ~0% over vanilla v1 at full-enum 1T. The real canonical-scale win
  is LTO + bitset, ~+4.4%. An intervening bench that appeared to confirm it had silently built
  without PGO at all (under `-flto`, GCC keys the `.gcda` lookup on the output binary name, and the
  two passes used different names).
- **How it was found:** **the operator asked where the number came from.** PERFORMANCE_HISTORY.md
  records it in as many words — the audit was "prompted by operator question 'where did the 9.2% come
  from'" after the re-run bench showed ~0%. It was not a self-review that went looking, and it was
  not a gate; the claim had been carried forward through two benches and into cost projections.
- **Commits:** `772dc51` (the provenance audit), `b1663d6` (retraction propagated into
  CANONICAL_HASHES.md's records-per-dollar paragraph).
- **Standing rule since:** do not bank a multiplicative composite of separately measured speedups
  without a direct A vs A+X+Y measurement.

---

### CX-04 · 2026-07-02 · C1 + C2 · the uniqueness conjecture

- **Documents:** README.md, SOLVE.md, SOLVE_SUMMARY.md, CLAIMS_DECIDED.md, TR-4.
- **BEFORE:** the published constraints plausibly determine King Wen uniquely — carried as this
  project's own working hypothesis and as the strong reading of the literature.
- **NOW:** **REFUTED.** Roughly 5×10³¹ orderings satisfy all published constraints. This is one of the
  project's principal results.
- **How it was found:** measurement (the estimator, validated), then an external review pass that
  forced the *scope label* as well as the verdict — the refutation had landed while parts of the
  corpus still described uniqueness as an open possibility.
- **Commits:** `8baff0c` (refutation), `88be3d8` (P0 defensibility fixes: uniqueness rescoped).
- **Not finished on the day it landed.** SOLVE.md still described uniqueness as an open possibility
  until 2026-08-01 (`9bcb545`, `0a30d9d`) — thirty days. That is the single longest-lived propagation
  failure in this record, and it was in the project's largest and least-swept document.

---

### CX-05 · 2026-07-02 · C2 · circular vs linear odd-concentration (`RP-4495df3c`)

- **Documents:** CRITIQUE.md (allowed to narrate it), TR-6, and the documents that repeated it.
- **BEFORE:** a between-pair odd-concentration ratio quoted in the circular reading while the
  surrounding text was linear.
- **NOW:** the circular and linear readings are stated separately; the linear between-pair figure is
  13:2. Registered as `RP-4495df3c`.
- **How it was found:** self-review of the adjacency decomposition — the same pass also corrected a
  four-cell decomposition error and a delta-as-ratio misread.
- **Commit:** `bab5d26`. **Propagated 2026-08-01**, i.e. thirty days after the correction itself.

---

### CX-06 · 2026-07-04 · C3 · boundary minimum at 560T (4 → 5)

- **Documents:** SOLVE.md, SPECIFICATION.md, BOUNDARY_MINIMUM.md, PROJECT_OVERVIEW.md,
  CLAIMS_DECIDED.md.
- **BEFORE:** the boundary-minimum trajectory is non-monotone with scale — 4 at 10T, 5 at 100T, back
  to 4 at 560T (published 2026-06-11).
- **NOW:** monotone 4 → 5 → 5. The "4 at 560T" was a survivor-counting error: the count stopped at 1
  remaining non-KW survivor instead of 0. The lone survivor is rec#330177707, which is King Wen with
  positions 2–3 pair-swapped. The 5-set `{1, 4, 21, 25, 27}` is identical at 100T and 560T.
- **How it was found:** self-review, on re-derivation. A non-monotone result was suspicious enough to
  re-run; the suspicion, not a gate, is what caught it.
- **Commit:** see BOUNDARY_MINIMUM.md; entries dated 2026-07-04 across the five documents above.

---

### CX-07 · 2026-07-05 · C1 · the Mawangdui corpus control

- **Documents:** CITATIONS.md (errata), SOLVE.md, CRITIQUE.md, GUIDE.md, SOLVE_SUMMARY.md,
  CLAIMS_DECIDED.md, TR-1, TR-10 (v1.2).
- **BEFORE:** three of the four tested ancient orderings satisfy C2, from which a shared classical
  design principle was inferred.
- **NOW:** the inference is **withdrawn**. The project's Mawangdui array was wrong. On the corrected
  array (Shaughnessy 2022, Table 11.2) the authentic Mawangdui order has exactly one 5-line
  transition, at its trigram-octet seam. The nine `dav_*` predicates were recomputed on the corrected
  array and every flagged predicate still evaluates to zero, so no TR-10 verdict moved; the
  non-flagged values did move (palnbr 16 → 13).
- **How it was found:** self-review against the primary source — checking the array against
  Shaughnessy rather than against the copy of it already in the repo. The corpus control had been
  published and cited for weeks on a wrong array.
- **Commit:** the errata entry in CITATIONS.md, dated 2026-07-05; TR-10 v1.2.

---

### CX-08 · 2026-07-20 · C2 · "optimum" → "position" on the trade-off frontier (`RP-b3fac207`)

- **Documents:** TR-1 (v1.14) and its abstract.
- **BEFORE:** King Wen sits at an *optimum* of the four-rule trade-off — an efficiency result.
- **NOW:** King Wen sits at a *position* on the trade-off frontier. All four conflict rules are
  KW-descriptive, so a frontier position is expected and carries no efficiency content.
  Registered as `RP-b3fac207`.
- **How it was found:** self-review at TR-1 v1.14. **But the fix did not take:** the retracted word
  survived in TR-1's abstract until 2026-08-01, invisible to every review pass *and* to every grep,
  because it spanned a hard line break. That is the defect that made
  `scripts/doc_gates.sh retract` normalise whitespace before matching.
- **Commit:** `fde5852` (v1.14); the surviving abstract instance cleared 2026-08-01 (`486aed2`).

---

### CX-09 · 2026-07-26 · C1 · "Theorem 6 (forced orientation)" (`RP-460f7742`)

The most serious retraction in this record.

- **Documents:** SPECIFICATION.md, SOLVE.md, SOLVE_SUMMARY.md, CRITIQUE.md, CLAIMS_DECIDED.md,
  DESCRIPTION_LENGTH.md, METHODS.md, VERIFY.md, DEVELOPMENT.md, lean/README.md, TR-1 §7.
- **BEFORE:** stated as a **theorem** that C1 + C4(pair) + C5 force the opening orientation
  (s₀ = 63, s₁ = 0), cited to "SOLVE.md, Theorem 6". Registered as `RP-460f7742`.
- **NOW:** **false, and retracted.** Complementing every hexagram of King Wen yields a sequence that
  opens (0, 63) and satisfies C1, C2, C5 and C3 — only the *oriented* form of C4 excludes it.
  Complementation (x ↦ x ⊕ 63) is an exact symmetry of C1∩C2∩C3∩C5, broken only by oriented C4, now
  machine-checked in [lean/KingWen.lean](../lean/KingWen.lean) on a kernel-only trust base. C4's
  orientation is definitional and classically attested (Xugua).
- **What did not move:** no bit value (TR-9 already priced C4 at its full 6 bits), no count, no sha.
  TR-1 §7's fiber numbers were re-scoped to the C4-oriented fiber and the pair-only fiber re-checked.
- **How it was found:** a dedicated proof-audit pass (F1 + F2–F5). Two things about it are
  unflattering and are recorded rather than smoothed. First, the claim's *empirical* support was
  **circular**: the enumerator hardcodes `seq[0] = 63; seq[1] = 0`, so no reversed-orientation
  ordering could ever have appeared in any enumeration, and that enumeration was cited as evidence
  for the very thing it had excluded by construction. Second, the claim carried **mutually
  contradictory epistemic labels across documents at the same time** — "theorem" in one, "prose
  proof" in another, "not yet analytically proven" in a third — and no review caught the
  contradiction for as long as it stood.
- **Commit:** `4910107`.

---

### CX-10 · 2026-07-30 · C2 · the conflict theorem's scope (`RP-74fbfafe`, `RP-1e38a453`, `RP-48f1cacd`)

- **Documents:** TR-2 (allowed to narrate it), TR-1, README.md, SOLVE_SUMMARY.md,
  LITERATURE_RULES_POPULATION_TESTS.md, CLAIMS_DECIDED.md, and a figure's alt-text.
- **BEFORE:** the four-rule conflict theorem stated at C1-only scope.
- **NOW:** the DRAT certificate establishes it at **C1∩C2∩C4∩C5** scope. The claim stands; the scope
  label was wrong wherever it had been repeated. Three registered wordings, including one
  morphological variant (`RP-48f1cacd`) that the registry missed because it held only the other form.
- **How it was found:** the rescope itself, 2026-07-30, by self-review of what the certificate
  actually certifies. **The propagation is the story.** On 2026-08-01 the retracted scope was still
  on the README front page, in TR-1's executive summary, in a figure's alt-text, and in the
  CLAIMS_DECIDED row grading it — invisible to *three* review passes, precisely because TR-2's own
  revision entry asserted the propagation was already done. A changelog row claiming a correction had
  propagated was believed instead of checked.
- **Commits:** `fb356a9` (propagation, TR-2 v1.18); the v1.18 propagation claim was itself retracted
  at TR-2 v1.20.
- **Consequence:** [RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) and `scripts/doc_gates.sh retract`
  exist because of this entry. A ledger that says "this was propagated" is a *claim*; the registry
  makes it a *test*.

---

### CX-11 · 2026-08-01 · C1 · the information-theoretic floor (`RP-3aafb254`, `RP-daf28670`, `RP-98c566a5`, `RP-527b3fcc`)

- **Documents:** TR-4 (v1.15/v1.16), CLAIMS_DECIDED.md, and the figure generator
  `fig_tr4_boundary_information`.
- **BEFORE:** a *hard*, information-theoretic floor on the number of further adjacency facts needed,
  presented as a necessity bound. Four registered spellings (`RP-3aafb254` unicode, `RP-daf28670`
  unspaced ASCII, `RP-98c566a5` without the variable, `RP-527b3fcc` spaced ASCII).
- **NOW:** **withdrawn.** The divisor used is only the *unconditional maximum* gain, and the same data
  shows a smaller gain at step 3; no necessity bound follows from the argument at all. The correct
  label is a *heuristic* floor, and the decision taken was to delete the "floor" label rather than
  qualify it a third time. CLAIMS_DECIDED now reads "heuristic floor ≥12" with the withdrawal noted
  inline.
- **How it was found:** **the operator, not a gate and not a review.** It was held for the operator
  as a claim whose premise was falsified by its own data while carrying a contradictory epistemic
  label. Two further unflattering details: one spelling survived *rendered inside a matplotlib
  figure*, where the text is glyph paths and ungreppable — which is why `doc_gates.sh figures` exists;
  and a fourth spelling was discovered when the gate's own mutation self-test injected it and
  **neither gate fired**, because the registry held three spellings and not the most natural one.
- **Commits:** `7f83437` (A-2 decision), `546aac7` (figure gate), `d99b467` (the spelling the gates
  missed), `8f16543` (removing the `example/` container exemption).

---

### CX-12 · 2026-08-01 · C2 · "exact" vs "estimate" on the C1–C7 count (`RP-e578bdd0`)

- **Documents:** CITATIONS.md (allowed to narrate it), and the documents that repeated the label.
- **BEFORE:** the C1–C7 figure described as an *exact enumeration*.
- **NOW:** it is a **validated estimate** (5.21×10³¹). The suite's exact full-scale counts are
  |C1∩C2∩C4| and |C1∩C2∩C4∩C5|, and only those. Registered as `RP-e578bdd0`.
- **How it was found:** an exact/estimate sweep run as pre-review hygiene across the whole corpus —
  a mechanical check of every canonical quantity's epistemic label, not a reading of the prose.
- **Commit:** 2026-08-01 sweep batch (`5d68c21`, `91129a4`).
- **Related standing gate:** `scripts/doc_gates.sh status`, which is report-only by construction, so
  a green "DOC GATES: PASS" banner does **not** cover this class. The banner now says so.

---

### CX-13 · 2026-08-01 · C2 · the 3.9th-percentile complement-distance figure (`RP-5ed8a7d8`, `RP-f9dc3ad6`)

- **Documents:** SOLVE_SUMMARY.md and CITATIONS.md (each allowed to narrate its own form), SOLVE.md,
  HISTORY.md.
- **BEFORE:** King Wen's complement distance placed at the 3.9th percentile of orderings satisfying
  every other constraint — used, among other things, to support a novelty claim.
- **NOW:** **flagged, and the population disowned.** The figure is a statistic of a
  13,296-ordering differential slice, not of C1∩C2∩C4∩C5; the ledger ratio puts the correct placement
  near 12%. The novelty claim for C3 must stand on the value 776 itself, not on the percentile.
  Registered as `RP-5ed8a7d8` and `RP-f9dc3ad6`.
- **Direction versus magnitude.** CX-01's direction correction (2026-04-09) stands. What is flagged
  here is the *magnitude* that replaced it, which was published for roughly four months and carried a
  population label it did not have. A correction can be right and its replacement value still wrong.
- **How it was found:** a lens sweep — a structured adversarial pass, run in-house, that specifically
  audits statistics for circularity between the quoted figure and the population it is quoted
  against. It had survived a scope-consistency sweep on 2026-07-22 (`d38ea6a`) that *added* a scope
  note without checking whether the scope note was true.
- **Commits:** `8178c33`, `9d27bfa`.

---

### CX-14 · 2026-08-01 · C3 · the 100T canonical record count

- **Documents:** CANONICAL_HASHES.md, CLAIMS_DECIDED.md, runs/ README.
- **BEFORE:** 3,432,399,298 records, itself a 2026-05-30 doc-level "correction".
- **NOW:** 3,432,399,297. The 2026-05-30 correction divided the file size by 32 without subtracting
  the 32-byte header. Re-corrected 2026-07-04 against the primary logs, `solutions.meta.json` and the
  verify output.
- **What did not move:** the sha256 anchors were never affected, at any point.
- **How it was found:** self-review against primary artifacts. Recorded here because it is a
  *correction of a correction* — the class this ledger most needs to make visible, since the second
  error inherits the first one's credibility.

---

### CX-15 · 2026-08-01 · C3 · shipped artifacts hand-edited instead of their generator

- **Documents:** `example/README.md`, `example/report.md`, `example/report.txt`.
- **BEFORE:** `example/README.md` was a hand-edited copy of `example/report.md`, differing by exactly
  one line: it described the constraint as keeping complements near one another where `roae.py`
  emits "OPPOSITES".
- **NOW:** the artifacts are regenerated from `roae.py` and checked against it.
- **How it was found:** the operator, twice. The first instance had survived indefinitely because no
  gate looked at it: the retraction, link, status, number and liveness gates all pass on a hand-edited
  artifact, because the text is not retracted, the links resolve and the numbers are self-consistent.
  The second instance was mine — while fixing the first defect I string-patched the four shipped
  artifacts *as well as* the source, two independent routes to the same text, and the operator caught
  it again. Reverted.
- **Commit:** `dbba77d` (reverted); `doc_gates.sh generated` (GATE 8) written in response.
- **Standing rule since:** never hand-edit a generated artifact — fix the source and regenerate.

---

### CX-16 · 2026-08-02 · C1 · the last blanket "everything here is machine-verifiable" claim (`RP-a823340f`)

- **Documents:** `documentation/SOLVE_SUMMARY.md` (§"The story continued", closing line).
- **BEFORE:** a single closing sentence asserted that every bullet in the section was
  machine-verifiable, with the reports supplying commands and certificates. Cited by key, not
  quoted, per the registry convention above.
- **NOW:** the covers' own formulation — every MEASURED result carries a reproduction command and
  every proof cited as machine-checked names its certificate or Lean theorem — followed by the
  exception the old sentence overrode: the bit-ledger's accounting conventions are chosen, not
  derived, which is why TR-9 publishes a range (about 105–127 bits) rather than a number.
  *(Supersession note, 2026-08-06: TR-9 v1.22 widened the range itself to 105–139; the live
  SOLVE_SUMMARY.md sentence says 105–139. This entry records the 2026-08-02 state.)*
- **Why it survived `14d8751`:** that batch retired the same over-claim from the eleven TR covers,
  and GATE 9 enforces the covers' wording byte-for-byte across all eleven. This instance was in a
  different document, in different words, covering a different list — outside GATE 9 by construction
  and outside GATE 3 for want of a registry row. It was the **last surviving instance of the class**;
  a repo-wide sweep for the phrase now returns only this ledger and the registry.
- **What did not move:** no number, count, sha, certificate or theorem. The four bullets themselves
  are unchanged; only the claim *about* them.
- **Gate added:** registry row `RP-a823340f`, so GATE 3 now stops the wording returning anywhere.

---

### CX-17 · 2026-08-02 · C3 · the reports index stated a POINT where TR-9 states a RANGE

- **Documents:** `reports/README.md` (TR-9 index row).
- **BEFORE:** "~126 bits unexplained".
- **NOW:** "about 105–127 bits unexplained (a range, not a point — the exact figure depends on the
  stated accounting convention)", which is what TR-9's own executive summary says.
  *(Supersession note, 2026-08-06: TR-9 v1.22 widened the range itself to 105–139, and the index row
  now says 105–139 with the endpoints named. This entry records the 2026-08-02 state.)*
- **How it was found:** named in the round-3 harvest and verified at both sites. The index row is the
  claim site a reader meets **first**, and it had dropped the qualifier that the report treats as
  load-bearing — the report is explicitly the most judgment-dependent in the suite.
- **Why it was not fixed under CX-12's unit:** that unit was scoped by the operator to the refutation
  lead and the 5.21×10³¹ label. Silently widening a scoped edit is its own defect, so this was
  carried rather than folded in.
- **What did not move:** TR-9's text, its ledger, and the ~146-bit C1 figure in the same row.

---

### CX-18 · 2026-08-02 · C3 · TR-1 published two revision rows numbered v1.21

- **Documents:** `reports/TR1_EIGHT_CENTURIES_MEASURED.md` (Revision History).
- **BEFORE:** the `d7` classification row (2026-08-02, commit `1134f26`) was inserted **above** the
  existing v1.21 row and numbered v1.21 as well. Two rows carried the same version, the history no
  longer ascended by date, and `*(current)*` sat on the **older** of the two.
- **NOW:** the d7 row is v1.22 `*(current)*` and sits below v1.21; the 2026-08-01 row keeps v1.21.
  The renumber went to the NEW row deliberately, so the external citations of "TR-1 v1.21" in
  `documentation/LITERATURE_RULES_POPULATION_TESTS.md:9,11` still resolve to the row they were
  written about.
- **How it was found:** a sweep of every report for duplicate version numbers, prompted by the
  round-3 harvest's TR-1 scoreboard item. TR-11's three `v1.0-draft` rows and TR-4's `v1.7`/`v1.7.1`
  were checked in the same sweep and are both legitimate under the versioning policy; TR-1 was the
  only true collision. `reports/METHODS.md` has no `*(current)*` row at all — noted, not changed,
  because METHODS is not a numbered report.
- **Self-inflicted, and recorded as such:** this was introduced by the round-3 unit that classified
  `d7`, one day before it was found. The versioning policy in [reports/README.md](../reports/README.md)
  §"Living documents" anticipates *skipped* numbers and says nothing about *duplicated* ones; nothing
  mechanical checks for them.
- **What did not move:** no number, count, sha, certificate, theorem or verdict. Both rows' text is
  unchanged apart from the integrity note appended to v1.22.

---

<a id="gates"></a>

## Gates

Two mechanical gates protect this file. Both are in `scripts/doc_gates.sh`; both have been **proven to
fire** against their own motivating example by the mutation self-test (`scripts/doc_gates.sh
--selftest`), which is the only evidence that a gate is a gate.

**GATE 10 — append-only.** Every line committed to this file must still be present, in order, in the
working copy. Deleting or rewriting an entry fails the gate. Appending does not. Both halves are
asserted in the self-test: an injected deletion must fire it, and an injected append must *not* — a
gate with no negative control is a gate that might simply always fail.

```
scripts/doc_gates.sh appendonly
```

**GATE 11 — completeness against the retraction registry.** Every row of
[RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) must be accounted for in this file by its key
`RP-xxxxxxxx`. A retraction cannot be registered and then quietly left out of the record. This gate is
registry-driven and does **not** consult the inventory's classifier, which is the point: the
classifier's C1 rule deliberately under-fires (see above), and this gate is the independent instrument
that catches what it misses.

```
scripts/doc_gates.sh ledger
```

---

<a id="sweep-provenance"></a>

## Sweep provenance

`scripts/corrections_inventory.sh` last run 2026-08-02, over 78 tracked markdown files and 1,005
commits:

| | candidates |
|---|---|
| **total** | 1,250 |
| C1 retraction | 159 |
| C2 circulated scope-label | 107 |
| C3 typo / consistency | 786 |
| C4 qualifier *(excluded)* | 198 |
| — by source: inline | 899 |
| — by source: git | 283 |
| — by source: changelog | 68 |

> **This table is superseded — see [Re-measurements](#re-measurements) at the foot of the file.** It
> is left standing rather than updated, because this file is append-only and that rule applies to its
> own numbers first.

These numbers are a **moving target** and are recorded for provenance, not as a result. Re-run the
script rather than trusting the table. They are also not directly comparable to the previous
inventory's 651 candidates: that build used a narrower keyword table (essentially
*corrected*/*correction* for C3 and *propagat\** for C2), and this one was rebuilt wider to favour
recall in a candidate generator. The `matched` column makes the difference reconstructible — group the
inventory by it and the narrow set is a subset of the wide one.

To re-derive everything in this section:

```
scripts/corrections_inventory.sh --selftest    # known-answer anchors for the classifier
scripts/corrections_inventory.sh               # rewrite documentation/CORRECTIONS_INVENTORY.tsv
scripts/corrections_inventory.sh --summary     # the table above
```

---

## What this record does not contain

- **C4 qualifiers**, for the reason given above. They are in the inventory, not in this file.
- **Silent edits nobody noticed.** By construction, no sweep can find a correction that left no
  marker, no revision row and no commit message. The three-source union narrows that gap; it does not
  close it. The honest statement is that this file records the corrections we *know about*, and the
  gates above make it hard for a *registered* one to go missing — not for an unregistered one to be
  found.

---

<a id="re-measurements"></a>

## Re-measurements

Later runs of `scripts/corrections_inventory.sh`, appended. The
[Sweep provenance](#sweep-provenance) table above is never edited; it is corrected here, which is the
same rule every entry in this file is held to.

| run | total | C1 | C2 | C3 | C4 | inline | git | changelog | note |
|---|---|---|---|---|---|---|---|---|---|
| 2026-08-02 (first) | 1,250 | 159 | 107 | 786 | 198 | 899 | 283 | 68 | the table above |
| 2026-08-02 (second) | 1,256 | 162 | 108 | 788 | 198 | 904 | 284 | 68 | after this file was linked from six documents, and after its own commit landed |

**The +6 is this file's own footprint**, and it reconciles exactly. Two inline rows were *replaced*
(README.md:177 and reports/README.md:19, both edited in place, so their content-addressed ids changed);
five inline rows are *new* (documentation/README.md, CRITIQUE.md, HISTORY.md and two in
CLAIMS_DECIDED.md); one git row is new (commit `2b3a3ac`, whose own message is full of correction
vocabulary). 2 out, 8 in, net +6. A record of corrections is not outside the system it describes:
CORRECTIONS.md and the inventory are excluded from the sweep (otherwise each regeneration re-ingests
its own output), but the documents that *link* to them are not, and should not be.

**The ids behaved as designed — which is not the same as "did not move".** The re-run rewrote the
`line` column of 256 rows, because the six edits shifted line numbers throughout, and **not one id
changed on account of a line move**. The only ids that changed were the two whose *text* changed,
which is correct: an id addresses content, so re-wording a line is a new row and re-numbering a line
is not. A sequence-numbered inventory would have renumbered a fifth of the file over a change that
corrected nothing.

**A first draft of this subsection asserted "every id stayed identical" and was wrong** — it was
written from the design intent rather than from the diff, and the diff says 2 ids left and 8 arrived.
The by-source figures in the row above were also wrong on first writing (904/284 stated as 905/283).
Recorded here rather than quietly fixed, since the file's entire subject is the difference between
those two responses.
### CX-19 · 2026-08-02 · C3 · TR-9's draft-stage note kept two figures its own v1.7 superseded

- **Documents:** `reports/TR9_PRICING_THE_CONSTRAINTS.md` (Revision History, the dated
  *Draft-stage corrections (2026-07-04)* paragraph).
- **BEFORE:** the paragraph stated "C4 6.0, C2 marginal 4.6, C2 net +1.6" with no marker. TR-9's own
  **v1.7** row (2026-07-10) had restated both C2 figures — marginal 4.6 → 4.5 and net +1.6 → ≈ 0
  (break-even, sign-convention-dependent) — and the paragraph sits **below** that row, so a reader
  going top-to-bottom met the correction first and the superseded pair second, in an order that reads
  as though +1.6 were the later value.
- **NOW:** a supersession clause names both restatements and points at §2 for the live values.
  Nothing is deleted: a dated note is a record and must keep saying what that pass produced.
  Recorded as **v1.20**.
- **How it was found:** the round-4 C7 sweep — for every TR revision row that retracts a figure, grep
  the corpus for that figure. 147 quoted spans in correction rows narrowed to 14 the rows themselves
  mark as superseded wording; this was the only live survivor. The other three hits are meta-mentions
  inside retraction narrations (`METHODS.md:209` "the withdrawn ≈10× margin";
  `reports/evidence/r11/PHASE2_README.md:104` recording the "1.4σ above" fix; and 20 "Theorem 6"
  occurrences, every one inside a strikethrough, a RETRACTED heading or a ledger row).
- **Same class as TR-11 v1.14**, which fixed the surviving "+1.6" in *its* §4 and recorded that the
  retraction "had not propagated across three subsequent revisions". It had not propagated to TR-9's
  own changelog either — so this is the COLD-02 shape (the report fixed, the artifact it points at
  not) recurring, which makes it a pattern rather than an incident.
- **Checked and needing nothing:** `documentation/DESCRIPTION_LENGTH.md`, which mirrors this ledger.
  Its dated-note chain already self-supersedes at `:86` → `:105` → `:113`.
- **What did not move:** no ledger row, bit value, marginal, count, certificate or conclusion.

---

### CX-20 · 2026-08-02 · C3 · TR-2's v1.12 row kept the superseded convergence-gate figure

- **Documents:** `reports/TR2_THE_RULES_CONFLICT.md` (Revision History, the **v1.12** row of
  2026-07-13).
- **BEFORE:** the row summarised the three pre-registered convergence gates as
  "~1σ / 2.0σ / 0.12σ", with no marker. **v1.19** (2026-08-01) recorded that the middle gate reads
  **1.9σ** in the body, and **v1.23** (2026-08-02) reproduces it as 1.92σ under the convention it
  states. Both corrections sit *below* the row carrying the superseded figure, so a reader going
  top-to-bottom met the retracted value first. The distance is not cosmetic: the pre-committed gate
  is 2σ, so 2.0σ reads as sitting *at* the gate and 1.9σ as inside it.
- **NOW:** a supersession clause in place, naming v1.19 and v1.23. Nothing is deleted — a dated row
  is a record. Recorded as TR-2 **v1.24**.
- **How it was found:** by **GATE 3b**, the retracted-FIGURE gate built in this same batch to make
  the round-4 C7 sweep permanent (`scripts/doc_gates.sh retract-figures`). This is the one
  occurrence in the suite that C7's method could NOT have seen: that sweep read *quoted spans*
  inside correction rows, and here the figure is not in quotes.
- **Scope of that "one occurrence" claim** (tightened in the same batch's Phase-4 pass, before
  push): GATE 3b's registry is **hand-seeded and currently holds nine figures**, so the claim is
  "the only such occurrence among those nine", not "the only one in the suite". A retracted figure
  nobody registers is invisible to the gate, which discovers nothing on its own.
- **Why the gate has no changelog exemption:** GATE 3 exempts a revision row so a changelog can
  narrate old wording. Had GATE 3b inherited that rule it would have been structurally blind to
  this defect, which lives inside a revision row. Exempting a *construction* is the same mistake as
  exempting a *directory* — so GATE 3b exempts nothing automatically and every legitimate
  quotation is one content-anchored row in `documentation/DOC_GATE_FIGURE_ALLOWLIST.txt`
  (36 rows today: 35 meta-mentions, 1 historical — two of them covering this ledger entry
  itself, which quotes the retracted figure twice).
- **What did not move:** no measurement, gate verdict, Bayes factor, count, certificate or sha.

---

### CX-21 · 2026-08-02 · registry keys for the retracted FIGURES already recorded above

Not a correction. This entry assigns the four **`RF-`** keys that GATE 11's new figures pass keys
on, for the four registered figures whose retraction is *already* recorded in this file. It records
no new judgement and withdraws nothing.

**Why keys, and why only four.** GATE 11 has always proven that every row of
[RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) reaches this file, by its content-addressed key
`RP-xxxxxxxx`. [RETRACTED_FIGURES.tsv](RETRACTED_FIGURES.tsv) had no partner gate, so a figure could
be registered, gated by GATE 3b on every run, and never recorded — the quieter half of the failure
GATE 11 exists for (round-5 item A5). The new pass, `scripts/doc_gates.sh ledger-figures`, closes the
mechanical half.

It keys on `RF-<first 8 hex of sha256(figure)>` rather than on the figure's text, and the reason is
measured, not stylistic: of the eleven registered figures, **six occur somewhere in this file and
only four are recorded in it**. `1.4σ` and `≈10×` both appear inside CX-19's *How it was found*
paragraph — as examples of meta-mentions found **elsewhere in the corpus** — and neither is a record
of its own retraction. A gate that looked for the figure text would have cleared two unrecorded
retractions and reported coverage.

| key | figure | recorded in |
|---|---|---|
| `RF-8d74e1c4` | `2.0σ` | **CX-20** — TR-2's v1.12 row kept the superseded convergence-gate figure |
| `RF-df361ebc` | `marginal 4.6` | **CX-19** — TR-9's draft-stage note kept two figures its own v1.7 superseded |
| `RF-c1721127` | `net +1.6` | **CX-19** — same entry; TR-11 §4 carried the same figure until v1.14 |
| `RF-1813e230` | `palnbr 16` | **CX-07** — the Mawangdui corpus control, whose corrected array moved this non-flagged value 16 → 13 |

**The other seven are NOT keyed here, deliberately.** Writing their ledger entries is an
adjudication — each has to be classified C1/C2/C3 and written by hand — and this entry does not do
it. They are listed, one row each with what still has to be decided, in
`documentation/DOC_GATE_FIGURE_LEDGER_OPEN.txt`, and the gate prints every one of them as `[OPEN]`
with a count on every run. **An `[OPEN]` row is an open defect, not an exemption.** Adding the
missing four-of-eleven keys to this file *without* writing the entries would satisfy the gate and
record nothing, which is the one edit this entry exists to warn against.

**What the gate cannot see**, stated in the same terms as GATE 11's phrases pass: a key written into
this file with no entry behind it. Both passes trust that a key is only written by someone recording
the correction. The gate is a completeness instrument, not a content one.

- **What did not move:** no measurement, verdict, count, certificate, sha, or classification of any
  existing entry.

---

### CX-22 · 2026-08-02 · C2 · SPECIFICATION.md contradicted its own per-dataset table on the boundary minimum (`RP-711be628`, `RP-43ecf0b4`)

- **Documents:** `documentation/SPECIFICATION.md` — the opening paragraph, and the paragraph ending
  "Every 'uniquely determines King Wen' statement in the project is therefore scoped to the
  enumerated datasets". Both cited by key, not quoted, per the registry convention above.
- **BEFORE:** both sites said four greedy-ordered boundary constraints are enough to isolate King Wen
  across the enumerated datasets, with no depth qualifier — the opening paragraph universally
  ("every enumerated dataset to date").
- **NOW:** four is stated for the shallow datasets (d2 10T, d3 10T) and **five** for the two deepest
  canonicals (d3 100T, d3 560T), where exhaustive test finds **0** working unordered 4-subsets.
- **Why this is C2 and not C1:** the claim was already corrected on **2026-07-04**, and correctly, in
  the same document's per-dataset table and result paragraph and in `SEARCH_SPACE_SIZE.md`. What
  failed was propagation to these two sites. The 2026-07-04 entry is the correction; this entry
  records that it did not reach the document's own summary prose, which therefore **contradicted the
  per-dataset table later in the same file** from 2026-07-04 until 2026-08-02. A reader who stopped
  at the opening paragraph — the most-read paragraph in the file — got the retracted answer.
- **Why the registry rows are keyed on the SCOPE-BEARING wording:** the bare four-constraint fragment
  is *true* when scoped to d2 10T / d3 10T, so registering the fragment alone would make GATE 3 fire
  on the corrected sentence. As shipped, the corrected sentence avoids the fragment only because the
  numeral carries markdown bold — an accident of formatting, not a property of the text. Keying each
  row on wording that is false under every scoping removes that dependence. Verified by running
  GATE 3's own normalisation (`tr '\n' ' ' | tr -s ' '` then fixed-string match) over every tracked
  `.md`: zero hits for either key's phrase.
- **What did not move:** no count, sha, certificate, theorem or canonical. `{25, 27}` remains
  partition-stable at all four depths; the greedy-minimum sequence 4 → 4 → 5 → 5 and the
  working-4-set counts are as the table already stated. Only the summary prose changed.
- **Provenance note:** the SPECIFICATION.md edits and the two registry rows were found
  **uncommitted** in the working tree at the start of round 14, carrying two defects of their own.
  **(1)** Both registry rows had **two**
  tab-separated fields where the schema and every other data row have three, so the note text landed
  in the `allow` column — which GATE 3 matches against filenames, and GATE 11 prints as the row's
  note on failure. The direction of that error happens to be fail-*safe* for GATE 3 (no filename
  contains a sentence, so nothing would have been wrongly exempted); what it would actually have
  cost is GATE 11's diagnostic, which would have reported the failure with an empty note. **(2)**
  Neither row was recorded in this file at all, which GATE 11 fails on outright — reproduced before
  the fix, and green after it. Both were fixed before this entry was written.
- **Concurrency note, recorded because it is the interesting part:** the schema fix and the
  rekeying above were made in the shared working tree, and **a second unit active at the same time
  committed them inside its own commit** before this entry was written — a commit whose message warns
  that
  "an uncommitted fix in a shared tree is one `git add -A` away from landing inside another unit's
  commit". The consequence is measured, not inferred: that commit ships both registry rows with
  **neither key recorded here**, so it is **GATE 11 RED as committed**, and this entry is what turns
  it green. Two units editing one tree with no lock produced a red commit that neither intended and
  that a per-unit gate run cannot catch, because each unit's run was green at the moment it ran.

---

### CX-23 · 2026-08-02 · C2 · five statements about other researchers, each compressed past its evidence (`RP-ec1edc30`, `RP-3de5247a`, `RP-0ac53779`, `RP-b527b673`, `RP-09cc405a`)

- **Documents:** `documentation/MCKENNA.md` (lines 56 and 135), `documentation/HISTORY.md` (3852),
  `reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md` (266), `documentation/CITATIONS.md` (343, 673, 679,
  899).
- **BEFORE — one behaviour, not five slips.** In each case a hedge that the report *body* carried was
  dropped when the claim was compressed into a heading, an index row, a bibliography line, or a
  closing verdict. The five: (i) "McKenna's specific claims … **don't survive mathematical
  scrutiny**", which converted hedged nulls — its own items 1–4 concede "the data is too short to be
  conclusive" — plus Watkins's and Meyer's critiques, whose evidence lives entirely off-repo, into a
  single unqualified judgement; (ii) "**He evidently never scanned** the other 28 pairs", attributing
  a *process* to Davis from an *outcome*; (iii) McKenna's design claim "**lacks independent
  corroboration in the published literature**", a literature-wide negative resting on one checked
  source; (iv) "**measured and refuted**" (twice), conflating the two prongs of McKenna & Mair 1979;
  (v) "**A one-off within his oeuvre**", an unsourced characterisation of Suenaga's whole body of
  work used to bound the standing of the paper we cite as the sharpest published *counting* result.
- **NOW:** each states the scope its evidence supports. (i) no support *in these measurements*, with
  the third-party critiques attributed as relayed rather than re-derived; (ii) the pairs are not
  treated in the book — whether he checked them is not observable from the text; (iii) *we have
  located* no corroboration (checked: Cook 2006); (iv) the structural-poverty **premise** is measured,
  the Gray-code **construction** is refuted; (v) we searched and found no other hexagram-sequence work
  by him.
- **Class, and where it does not fit.** C2 for four of the five: the claim survives, its scope or
  epistemic label changed, and (iii) had already propagated to `HISTORY.md:3852`. **(ii) is nearer
  C1** — the process attribution is withdrawn outright, not rescoped, and nothing replaces it but the
  observable fact. Filed here rather than split so the shared generator stays visible; the exception
  is recorded rather than flattened by the class letter.
- **What did NOT weaken.** The Gray-code impossibility (TR-8 §3) and the four-rule conflict theorem
  (TR-2 §4) are kernel-checked and DRAT-certified respectively, and were found **under**-claimed if
  anything. The no-5 rule and the 3:1 ratio remain credited to McKenna and confirmed by measurement.
  No measurement, count, certificate or sha moved.
- **How it was found:** an audit commissioned by the operator of *every* public statement judging
  another researcher's work wrong — the mirror of a novelty audit. The sixth site (`HISTORY.md:3852`)
  was not in the audit's list; it turned up only by grepping the **claim** rather than the cited line,
  which is the same propagation failure the entry is about.
- **Registry note:** the five phrasings are in
  [RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) so GATE 3 blocks recurrence. This entry exists
  because GATE 3 correctly refused the commit that registered them without it — the retraction
  registry and this ledger are required to move together, and on the first attempt they did not.

---

### CX-24 · 2026-08-02 · C3 · CX-23's registry note names the wrong gate, and no gate refused anything

- **Documents:** this file, `CX-23`'s final bullet.
- **What is wrong.** That bullet says this entry exists because GATE 3 *"correctly refused the commit
  that registered them without it"*. Two errors, both mechanical and both checkable in one run:
  **(1) It was GATE 11, not GATE 3.** The five findings printed under
  `== GATE 11: registered retractions are recorded in CORRECTIONS.md ==`, one
  `[FAIL] RP-<key> has NO entry in documentation/CORRECTIONS.md` per key. GATE 3 is the
  *recurrence* gate; the `RP-` keying is GATE 11's construct and GATE 3 does not use it.
  **(2) No gate refused any commit.** The repository's only pre-commit hook runs
  `scripts/pre_commit_generated_gate.sh`, whose watched set is `roae.py` plus the five `example/`
  artifacts and nothing else — a commit touching this file or
  [RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) is not gated at all. The registering commit landed,
  and the five failures were reported afterwards by a later manual run of the gate.
- **Why this is corrected by appending rather than in place.** `CX-23` is committed, and GATE 10b
  requires every line of every committed version to survive in the working copy, so that sentence
  can never be withdrawn. The rule this file states about itself is the remedy: a later entry says
  so, and both stay.
- **Why it is worth an entry at all.** The wrong half is not the gate's name. It is that a reader of
  this ledger is told a gate *refuses* such commits, and none does — which is exactly the gap that
  let the same defect ship twice in one day, from two different units, three hours apart.
- **What did not move:** no measurement, verdict, count, certificate, sha or classification.
  `CX-23`'s five corrections are unaffected; only its account of which instrument found them, and of
  what that instrument can do.

---
### CX-25 · 2026-08-04 · C2 · The two-model pair has now failed its own confusability gate, and "untouched" no longer holds

- **Documents:** [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) §"The result" and its v1.14 revision row;
  [evidence/f11/RESULTS.md](../reports/evidence/f11/RESULTS.md).
- **What is wrong.** TR-2's v1.14 row records the *four-class* extension failing its synthetic-draw
  confusability gate (M_G at 67/100 against a frozen 70) and states that "the v1.7/v1.12 two-model
  corruption result is untouched." That sentence was accurate when written: the four-class veto
  concerned a different model set. It is no longer accurate. The **two-class** pair behind the
  published BF — M_corr (corrupted precursor) versus M_tend (soft-preference arranger) — has since
  been put through the same style of gate, and **its tendency half failed**.
- **What was measured.** Pre-registered, bar frozen at 70/100 before the run, master seed `20260802`
  published before launch. **Half A** (M_corr self-recovery) **PASSED at 93/100** on 2026-08-02.
  **Half B** (M_tend self-recovery) **FAILED at 68/100** on 2026-08-03. All three conditioning
  variants land below the bar (68 / 68 / 69), there were zero draw failures and zero ties, and every
  wiring gate passed — including the bridge gate that reproduces the published v1.12 BF from the
  driver's own machinery. The failure is not an instrument artifact.
- **What the failure is, precisely — because the pooled number alone misleads in both directions.**
  An extension to n=1000 (same seed, so the original 100 draws are bit-identical inside it and no
  re-seeding was possible by construction) estimates the rate at **714/1000 = 0.714, Wilson 95% CI
  [0.685, 0.741]** — an interval that still *straddles* the 0.70 bar. The failure is a step
  function, not a gradient, and it is confined to one stratum:
  **at V=0 the models are provably confusable (0/277, upper bound 1.4%)**, because a V=0 tendency
  draw lands inside the grand-strict set, which is exactly M_corr's support; **at V≥5 they are
  provably distinguishable (599/599)**. The received sequence has **V=6**, where self-recovery is
  51/51 (95% CI [0.930, 1.000]). The λ-grid prior places 27.7% of its mass at V=0, so the pooled
  statistic is dominated by a regime the observed data does not occupy.
- **What this changes.** The published Bayes factor (**≈5.2×10³** variant U, **≈6.3×10³** variant A — the live v1.12
  figures, not the superseded v1.7 pair) and the ≈0.9998 posterior **must no longer be described as calibrated in the pooled sense**, and TR-2's
  "untouched" must be read as superseded. The numbers themselves are unchanged and are not
  withdrawn; what is withdrawn is the *calibration support* for them.
- **What this does NOT license.** It does not license calling the pair calibrated on the strength of
  the V≥5 stratum. The pre-registration that authorised the n=1000 extension defines **no bar at
  n=1000 and cannot produce a PASS**; quoting the V-restricted rate as though it were the gate
  outcome is explicitly forbidden by that document. The gate vetoed. A V-matched gate — "at V≈6, are
  M_corr and M_tend distinguishable?" — is the question the published claim actually turns on; it
  would be a **new instrument** whose bar must be frozen before it runs, and nothing here may be used
  to argue for a threshold chosen after seeing these numbers.
- **On the temptation this entry exists to refuse.** The seed was published before launch precisely
  so that a disappointing result could not be quietly re-rolled. It was not re-run, and it will not
  be. A pre-registered test that is repeated until it passes is a search, not a test.
- **What did not move:** no theorem, certificate, count, sha or classification. The conflict theorem,
  the DRAT certificates, the enumeration results and the four-class veto are all unaffected. Half A's
  93/100 stands as measured.

---

### CX-26 · 2026-08-07 · C1 · The Bayes factor and posterior are withdrawn as claimed results — CX-25's "not withdrawn" split is not defended

- **Documents:** [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) (executive summary, §"The result", v1.27
  row); [reports/README.md](../reports/README.md)'s TR-2 index row;
  [evidence/f11/](../reports/evidence/f11/), [evidence/f11halfb/](../reports/evidence/f11halfb/),
  [evidence/r11/](../reports/evidence/r11/) (dated notes); [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md);
  [CRITIQUE.md](CRITIQUE.md).
- **What is wrong.** CX-25 recorded the two-model pair's confusability veto (M_tend self-recovery
  68/100 against a bar frozen at 70) and drew a line: "The numbers themselves are unchanged and are
  not withdrawn; what is withdrawn is the *calibration support* for them." A hostile external review
  pressed on that split, and under this project's own standard — airtight-or-shelve; it would rather
  withdraw a claim than defend a weak one — it does not hold. The confusability gate is the
  instrument that was to establish that the two models are distinguishable enough for the number to
  mean what it is quoted as meaning. That gate vetoed. A Bayes factor kept on display as a standing
  result while only its "calibration support" is withdrawn is a weak claim defended in two registers
  at once, by a project that says it does not defend weak claims.
- **What changes.** The published BF (≈5.2×10³ variant U / ≈6.3×10³ variant A, the live v1.12
  figures) and the ≈0.9998 posterior are **withdrawn as claimed results**. The corruption-vs-tendency
  comparison now asserts no verdict on their strength — not "strong evidence", and not the residual
  "narrows the field by one rival". The figures remain published as the **as-computed record** — the
  computation is not in dispute, the derivation and evidence bundle are unchanged and reproducible
  ([evidence/f11/](../reports/evidence/f11/) `compute_f11_bf.py`) — in the register this suite uses
  elsewhere for recorded-but-not-claimed quantities (compare [TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md)
  §2: C3's marginal 3.0 bits are priced as data and NOT claimed as explanation). Recorded, not claimed.
- **The path back, so this entry cannot be read as burying the number.** TR-2 already names the
  instrument the published claim actually turns on: a V-matched confusability gate ("at V≈6, are
  M_corr and M_tend distinguishable?"), a new instrument whose bar must be frozen before it runs.
  If such a gate is registered, run, and passes, the figures can be re-claimed by a dated TR-2
  revision — never by rewording this entry.
- **Class.** C1: the evidential claim is withdrawn outright and nothing replaces it. The figures
  staying visible as history is this ledger's convention (GATE 10b), not a hedge on the withdrawal.
- **What did not move:** the computation and its reproducibility; the pre-registration record and
  the honored publish-whatever-it-says clause; Half A's 93/100; the direct N_gs measurement
  (4.50×10²⁵ ±6%) and its closed stop-flag; the conflict theorem, the DRAT certificates, every
  count and sha. The four-class veto (v1.14) and the two-class veto (CX-25) both stand as measured.
- **How it was found:** the operator-commissioned 18-lens adversarial review campaign, whose
  red-team pass applied the project's own airtight-or-shelve rule to CX-25's split; withdrawal
  authorized by the operator 2026-08-07.

---

### CX-27 · 2026-08-07 · C1 · TR-8's dof-matched median is withdrawn pending artifact — the v1.10 flag was not enough

- **Documents:** [TR-8](../reports/TR8_REORDERING_REVISITED.md) (executive summary, v1.14 row);
  [METHODS.md](../reports/METHODS.md) §"Data-like vs principled constraints".
- **What is wrong.** TR-8 v1.10 (2026-08-01) flagged the dof-matched baseline — "the median
  ≈16-clause KW-fitting predicate reaches a rarity near ~6×10⁻⁵, and about half are at least as rare
  as King Wen's ~1×10⁻⁴" — as having **no artifact, command, code path or evidence bundle anywhere
  in the repo**, and directed readers to treat it as unreproduced. But the flagged figure stayed in
  the executive summary doing load-bearing work: it is the one number that answers the
  predicate-specification ("Bible-code") objection in its own currency, and the surrounding text
  continued to lean on it ("the dof-matched comparison above shows…"). A figure this suite cannot
  reproduce is a figure this suite may not lean on; a flag that leaves the leaning in place is
  disclosure without consequence.
- **What changes.** The ~6×10⁻⁵ median and the "about half are at least as rare" comparison are
  **withdrawn pending artifact**: not to be cited or relied on — by readers or by this suite's own
  text — until the sampler exists. TR-8 itself specifies the fix, and it is the condition for
  reinstatement: a `solve.py` sampler over the ≈16-clause KW-fitting predicate space, published with
  its seed and probe count, reporting the median rarity with a CI. The disclosure stays; the
  qualitative direction stays as an **acknowledged open question** — it argues *against* this
  project's rarity claims (conservative, against interest), and is independently supported by the
  data-like/principled firewall (METHODS) and TR-9's pricing. What is withdrawn is the number and
  the "bulk of the distribution" placement that rests on it.
- **What did not move:** every TR-8 figure that has an artifact — the exact pair-null 47/445740, the
  ×1,362 / ×11,364 registry masses, the Gray-code impossibility theorem and its kernel check; the
  91-observable ledger and its bars; all certificates, counts and shas.
- **How it was found:** the same 18-lens red-team pass as CX-26 — its point was precisely that an
  uncited-able number was answering the strongest objection; operator authorized 2026-08-07.

---

### CX-28 · 2026-08-07 · C2 · The 5.21×10³¹ headline demoted: a measured confirmation with prior art in its direction, single-instrument in its magnitude

- **Documents:** [README.md](../README.md) (lead + attribution paragraph);
  [reports/README.md](../reports/README.md) (lead + TR-4 index row). [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md)
  itself already carried both halves (v1.19, 2026-08-06) — the front pages had not caught up.
- **What is wrong.** Two facts, both already in the corpus, were absent at the headline sites.
  **(i) The refutation's direction is prior art.** [CITATIONS.md](CITATIONS.md#uniqueness-conjecture)
  §"Prior negatives" (appended 2026-07-30) records that Ouyang Weicheng (1990) stated the sharpest
  under-determination position, Zhang Qingyu (1998) conceded his orbit framework could not fix the
  48 散卦, and Suenaga (2012) reported finding no rule that fixes the sequence. README's attribution
  paragraph disclosed only that "no author asserted" the positive conjecture — the half that makes
  the refutation honest — while omitting the prior negatives — the half that makes its direction
  unoriginal. **(ii) The magnitude is single-instrument.** The ≈5.21×10³¹ C1–C7 figure is solve.c's
  Knuth estimator alone; every two-instrument exact quantity in the suite (|C1∩C2∩C4|,
  |C1∩C2∩C4∩C5|, recomputed by verify.c's independent engine) is C3-free, so no second instrument
  has ever measured a C3-inclusive layer.
- **What changes.** The headline is reframed from a standalone refutation to **a measured
  confirmation of prior under-determination claims**, with the magnitude labeled **a
  single-instrument estimate**, and the prior negatives named at the headline sites in one sentence.
- **What this is NOT — stated so the demotion cannot be over-read.** It is a novelty and
  instrument-coverage demotion, **not a correctness doubt**. The estimator is externally validated
  at both full-scale layers where exact ground truth exists — both exact values land inside the
  stated ±0.01% envelope with roughly half the error budget to spare (the C5 layer's deviation of
  +4.44×10⁻⁵ is ≈0.87σ if that envelope is read as a 95% interval) — and the C6–C7 verdict is
  corroborated exactly at small scope (8 of 16,504 in KW's own 22-pair prefix). The count, its CI,
  and the refutation's verdict are unchanged; ROAE's contribution remains the measurement, which no
  prior author performed.
- **What did not move:** the ≈5.21×10³¹ estimate and CI; the ≈1.33×10³⁸ C1–C5 estimate; the exact
  counts; TR-4's text (already correct); the attribution note's positive half (no author asserted
  the conjecture — that stands).
- **How it was found:** the 18-lens red-team pass, reading the front page against CITATIONS'
  own prior-negatives note; operator authorized 2026-08-07.

---

### CX-29 · 2026-08-07 · C3 · This ledger's own history was rewritten to restore its append-only guarantee, and until now nothing said so

- **Documents:** this file ([CORRECTIONS.md](CORRECTIONS.md)) — its published git history, not its
  current content. No claim in any report is affected.
- **What happened.** On 2026-08-02, commit `728778e7` modified **ten already-committed lines** of
  this ledger (+16/−10). The *intent was sound*: the then-current CX-23 reproduced five retracted
  phrasings **verbatim**, and GATE 3 fired on the ledger itself — correctly. The edit replaced those
  quotations with descriptions, following the convention CX-08 established, that a retracted wording
  belongs in [RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) and nowhere else, because that is what
  lets the gate police every other file without tripping on the record of the fix. Two follow-on
  commits (`77042b39`, `ec307098`) failed to reach a clean state in either direction.
- **Why it is a correction.** This file's guarantee is **append-only**: entries are added, never
  altered. That guarantee is the reason the ledger is worth anything — it is what stops an admission
  from being quietly revised later. Editing ten committed lines broke it, however good the reason.
- **How it was cured, and the second problem that created.** The violation was resolved by
  **removing the three commits from the published line** — that is, by rewriting history. At least
  `728778e7` had already been pushed. Restoring an append-only invariant by rewriting history is
  defensible and may be the only way to restore it; leaving the rewrite unrecorded is not. A reader
  reconstructing this file's history would otherwise find a rewrite these documents never mention,
  which is a worse outcome than a disclosed one.
- **What changes.** Nothing in the corpus's claims. This entry exists so the event is on the record
  in the ledger whose own history was repaired. The five excised commits (`728778e7`, `77042b39`,
  `ec307098`, and two clean ones, `3bf04596` and `661b6cb7`) remain reachable git objects, so this
  account is auditable rather than merely asserted.
- **Stated limitation.** That `728778e7` had been pushed is taken from the gate header's own
  contemporaneous claim; it has not been independently confirmed against a remote's reflog.
- **How it was found:** a replay of commits excised from main's published line, during the 18-lens
  red-team campaign — found while doing something else. Operator-authorized 2026-08-07. The
  successor lens it implies (sweep for every non-fast-forward move of the published line and
  classify each as benign amend vs record alteration) is queued and has not been run.

---

### CX-30 · 2026-08-07 · C1 · A novelty claim understated the constrained space by ~29 orders of magnitude, in the direction that flattered the project

- **Documents:** [CITATIONS.md](CITATIONS.md) §"Pair structure + no-5-line + complement proximity as a
  *joint* constraint system".
- **What was wrong.** The section read: "The framing of C1–C5 as a specific system that **narrows
  10^89 orderings to ~700 million** is ROAE-specific." The 10^89 is right — that is ≈64!, the
  unconstrained space. The "~700 million" is not the size of anything C1–C5 defines.
- **The magnitude.** The C1–C5 space is **estimated at 1.33×10³⁸** orientation-explicit (≈3.3×10³⁷
  after orientation-dedup), per [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) — a Knuth random-probe
  estimate, not a proven cardinality. Against that, "~700 million" understates by roughly **29
  orders of magnitude**.
- **The category error underneath it.** Counts in the hundreds of millions to low billions are
  **enumerated record counts from budgeted slices** — what the solver wrote to disk under a per-cell
  budget — not the size of a constrained space. The two are not comparable quantities. Conflating
  them inverts this project's central finding, which is precisely that C1–C5 leaves a space far too
  large to enumerate. A reader quoting that sentence would have cited the reverse of what we found.
- **Additional defect.** The figure "~700 million" appeared **nowhere else in the corpus** and had
  no supporting source. It was not a stale number superseded by a better one; it was unsourced.
- **What changes.** The sentence now claims only what is defensible — that the framing of C1–C5 as a
  *joint* system is ROAE-specific — and a dated note states the prior wording, the correct magnitude
  with its epistemic label, and the slice-vs-space distinction. The novelty claim itself stands: it
  was the number, not the originality, that was wrong.
- **How it was found:** the 18-lens red-team pass flagged the site; the ~29-order figure and the
  no-other-source finding were confirmed by direct search 2026-08-07. Operator-authorized.

---

### CX-31 · 2026-08-07 · C1 · The citation-pinning contract described two mechanisms, and neither existed

- **Documents:** [reports/README.md](../reports/README.md) §"Living documents: the versioning policy";
  [reports/METHODS.md](../reports/METHODS.md) §environment table, Repository row.
- **What was wrong — two halves of one broken promise.**
  **(i) DOIs that do not exist.** reports/README read "Snapshots are **archived with versioned DOIs**
  (Zenodo: a concept DOI resolves to the latest state; version DOIs pin what you read)." Verified
  absent: there is no Zenodo deposit for this project, [CITATION.cff](../CITATION.cff) carries no
  `doi` or `identifiers` key, every DOI in the repo is an external citation, and
  [DEVELOPMENT.md](DEVELOPMENT.md) records the deposits as **declined by operator direction,
  2026-04-18**. The sentence described infrastructure that was considered and rejected.
  **(ii) Tags that were never cut.** METHODS' environment table said to "pin to the release tag
  stamped at publication (git tag per suite version)". Fourteen tags exist, but only `reports-v1.0`
  (2026-07-03) is a suite version; the reports have since advanced to TR-2 v1.24, TR-3 v1.9 and
  beyond, none tagged.
- **Why they had to be fixed together.** Each alone looks like a small overstatement. Together they
  meant the citation-pinning policy had **no executable mechanism whatsoever** — a reader told to
  "cite a version" had no way to pin what they read. Fixing one and leaving the other would have left
  the contract just as broken while looking repaired.
- **What changes.** Both now name the mechanism that actually works and always has: **the commit
  sha**, which is content-addressed and immutable — the property a DOI would have been purchased for.
  Citations should give version *and* commit.
- **Where this sat.** In the paragraph that tells readers how to trust the record's permanence, and
  in the table a replicator reads first. Both are the worst available placement for a false claim.
- **How it was found:** the aspirational-infrastructure sweep. Two sibling claims from the same sweep
  (TR-3's and METHODS' "selftest on every commit") were found **already corrected** at HEAD — they now
  correctly say the gate runs at push, per-clone and opt-in, and is "not a commit-time gate".

---

### CX-32 · 2026-08-07 · C1/C2/C3 · The seven retracted figures that were registered and gated but never recorded

- **Documents:** the seven figures below, each in its own report. This entry closes the backlog in
  [DOC_GATE_FIGURE_LEDGER_OPEN.txt](DOC_GATE_FIGURE_LEDGER_OPEN.txt), whose rows were open defects,
  not exemptions.
- **Why they were open.** GATE 11 has always proven that every row of `RETRACTED_PHRASES.tsv` reaches
  this ledger. `RETRACTED_FIGURES.tsv` had no such partner, so a figure could be registered, policed
  by GATE 3b, and never written up — the quieter half of the failure GATE 11 exists for.
- **Why each item below names a key and not a number.** Retracted figures are **not reproduced
  here**, per the convention CX-08 set and CX-29 records: the exact string lives in
  `RETRACTED_FIGURES.tsv` and nowhere else, because that is what lets GATE 3b police every other file
  without tripping on the record of the fix. The gate keys on the content-addressed `RF-<sha8>`
  precisely so a retraction can be recorded without being restated. *(This entry's first draft
  ignored that and quoted all seven; GATE 3b failed it — the same way it failed CX-23 on 2026-08-02,
  the event CX-29 documents. The gate caught the identical mistake twice, four hours apart.)*

**1. `RF-b8490caf` · C1 — TR-8 v1.9's look-elsewhere factor.** Overstated by an order of magnitude;
the supported value is one tenth of what was published. The most consequential of the seven: it
appeared in a report body and it inflates a multiple-comparisons correction, so the surrounding
argument was presented as more conservative than it was. Corrected, TR-8's conclusion stands but the
margin it claimed to survive is narrower.

**2. `RF-4a208654` · C1 — TR-2's withdrawn σ-distance for the same comparison.** v1.19 withdrew it as
unreconstructible; v1.23 restored the comparison under the file's stated convention and **the sign
flipped** — the quantity did not merely shrink, it reversed direction, landing below rather than
above. That reversal is the part a reader would most want, and the reason this is C1 rather than C3.

**3. `RF-de0e3b47` · C2 — TR-10 v1.8's withdrawn trigarray BH margin.** This file's only prior
mention of it sits inside CX-19's "How it was found" — a meta-mention of a defect found elsewhere,
not a record of this retraction.

**4. `RF-fde8b696` · C2 — the certificate-directory count in TR-2 v1.19's ¶Extension note.** The note
stated a total two lower than the directory holds; TR-5 v2.1 records the intermediate value.
Adjudicated **C2 rather than C3** because the count reached a published extension note where a reader
could rely on it — a decision, per the row's own instruction not to assume.

**5. `RF-1f093dc3` · C3 — TR-9 v1.16 §5(a)'s comp∘rev-admitted low end.** The section quoted two
different values for the same quantity in the same passage; the arithmetic (146.3 − 19.0) settles it.
A self-inconsistent published pair. C3 because the wrong value never propagated beyond that sentence.

**6. `RF-f3f89046` · C3 — DESCRIPTION_LENGTH.md's C6+C7 marginal.** Superseded by that file's own
2026-07-10 unrounded-operand pass, which restated it one tenth of a bit higher. Its sentence-sibling
*was* recorded in CX-19; this one never was — the same asymmetry the registry audit found in the
registry itself.

**7. `RF-a79d9a6e` · EXCLUDED under the C4 rule, and the exclusion is the record.** TR-8 v1.11 and
METHODS §"Statistics conventions" **recorded and DECLINED** this change: the supported statement is a
floor, not the larger figure. A declined change is not a correction, and entering it as one would
misrepresent the corpus as having retracted something it deliberately kept. The C4 exclusion rule is
the precedent; applying it was a judgment, operator-ratified. Closed by exclusion, **not** by
silence — which is why it is named here at all.

- **What changes.** No published number moves as a result of this entry; each figure was already
  corrected in its own report. What changes is that the corrections are now *recorded*, so registry
  and ledger agree.
- **How it was found:** round-5 item A5 built GATE 11's figures partner and shipped it with the
  backlog listed rather than hidden — a gate that fires on its own open rows. Operator-approved
  2026-08-07.

---

### CX-33 · 2026-08-07 · C2 · The Lean trust-base disclosure — "native_decide remains only in two files" — is obsolete in the strong direction: the corpus is now kernel-only

- **Documents:** [lean/README.md](../lean/README.md) §Trust-base note (the primary disclosure and
  its executed-audit companion), and the circulated repetitions:
  [SPECIFICATION.md](SPECIFICATION.md) §Theorem (Trigram-level structure),
  [SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md) §Machine verification (layer ii),
  [TRIGRAM_STRUCTURE.md](TRIGRAM_STRUCTURE.md) §Trust base + §TG-5, and
  [reports/METHODS.md](../reports/METHODS.md) §Independence ladder, rung 1.
- **What this is, stated precisely — no prior claim was wrong.** Unlike most entries in this file,
  nothing here retracts or reverses a published statement. The disclosure — that a subset of
  finite lemmas rested on `native_decide`, which trusts Lean's compiler in addition to its kernel,
  latterly confined to `TrigramTheorems.lean` §4a–§6 and `SymmetryCompleteness.lean` — was
  accurate at every revision that carried it, and the module-wide axiom audit executed earlier on
  2026-08-07 observed exactly the documented sites and nothing else. What changed is the artifact:
  the limitation itself was removed, so every circulated statement of it went stale
  simultaneously. This entry is the propagation record — the C2 mechanics of a label that changed
  after being repeated across documents — not a repair of an error.
- **What changed in the artifact.** The two obligations that had kept those files on
  `native_decide` — their direct kernel enumerations were measured at ~13.7 GB peak RSS
  (`psi_comm_perms`) and ~11.5 GB (`blockPreserving_iff_blockwise`) and rejected as a hardware
  bar — were reproved structurally on 2026-08-07 with both theorem statements kept verbatim, and
  every remaining `native_decide` site in the two files migrated to `decide +kernel`
  (kernel-evaluated, no compiler trust). Measured on the exact shipped tree: ~2.8 GB and ~4.4 GB
  peaks, both under `Automorphism.lean`'s pre-existing ~9.6 GB suite ceiling — so the published
  hardware statement (~10 GB free RAM verifies everything; an 8 GB host cannot check
  `Automorphism.lean` or `KingWen.lean`) was re-confirmed unchanged against measurement rather
  than assumed.
- **The new claim, scoped so it cannot be over-read.** All twelve modules now report
  `#print axioms` ⊆ `[propext, Classical.choice, Quot.sound]` — Lean's standard axioms, zero
  `Lean.ofReduceBool` — observed by a module-wide `collectAxioms` scan over every non-internal
  constant of every compiled module on the exact shipped tree, alongside a clean
  `verify_all.sh` run on the same host (rc 0, 60 passed / 0 failed / 0 skipped). This is a
  statement about the **axiom base** — what a reader must trust for the proofs to be sound — not
  a claim that the formalized statements exhaust what the prose asserts: file headers and scope
  notes still govern meaning, and the model-to-code bridges (PartitionInvariance B1–B4, the
  PruneExactness reachability hypotheses) remain stated prose assumptions, exactly as before.
- **What changes (document-side).** The five documents above now state the kernel-only base, each
  with a dated supersession note preserving what its disclosure said and when it stopped being
  the case; lean/README's hardware table carries the two files' new measured costs and the
  old-cost provenance.
- **How it was found:** not found — executed. Operator-approved adoption of the second structural-
  reproof tranche (2026-08-07), closing out the pending work the tranche-1 disclosure itself had
  named ("they stayed on `native_decide` pending structural reproofs of those two obligations").

---

### CX-34 · 2026-08-08 · C1 · the 100B canonical `f1709ab0…` was deprecated as a resume artifact; it reproduces exactly, and the deprecation is retracted (`RP-adb0fbfa`, `RP-d487703e`)

- **Documents:** [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Deprecated canonicals (the `d3 100B` row),
  and [HISTORY.md](HISTORY.md) §2026-05-25, finding 1.
  **Scope widened 2026-08-08:** also [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §100B and
  sub-canonical reference shas — code-specific, NOT canonical-grade, **item 3**, which still asserted the retracted claim
  22 lines from the reinstatement — and which this entry's own "see §100B…" pointer routed readers
  into. Found by an adversarial sweep the same day, not by the gate: GATE 3 was green because item 3
  used a morphological variant of the registered needle. **Scoping a correction's `Documents:` list
  too narrowly is how a retraction leaves live residue** — the same mechanism as CX-13, whose
  four-file scope let the 3.9th-percentile figure survive at eight non-markdown sites.

- **What was published, and is now retracted.** The `d3 100B` row asserted that
  `f1709ab09486ba912ec5683a4c96211ff31d52b671e898b1b6e3421cc00aa9db` was "Irreproducible from
  `3258f4c` re-run 2026-05-25" and showed the "Same imperfect-resume artifact pattern as
  `c34390c0`/`f7b8c4fb`" — that is, that our own archived bytes were an incomplete file left by an
  interrupted run. **That characterization is withdrawn.** The bytes are a reproducible,
  deterministic output of a well-defined configuration.

- **What is now measured.** Those exact bytes reproduce from **four independent code states across
  two lineages**, every run clean, uninterrupted, `rc=0`, no resume — v1 `3258f4c` and v1 `a2ead96`
  (2026-08-08), v4 `b0221a31` and v4 `a0542067` (2026-08-07), all at **12,386,121 records** and all
  `f1709ab0…` over the 396,355,904-byte file (32-byte header + 12,386,121 x 32-byte records).
  A file truncated by an interrupted run does not reproduce deterministically four times from four
  different builds. Note the first of those in particular: `3258f4c` is the very commit the
  published sentence named as the one it was irreproducible from.

- **Why the 2026-05-25 bisect concluded otherwise — a configuration difference, not corruption.**
  That bisect pinned every one of its six enums to `SOLVE_DEPTH=3` with a hand-set
  `SOLVE_PER_SUB_BRANCH_LIMIT=631545` (approximately 100e9 divided by 158,364 **cells**), decomposing the
  search into roughly 158K shallow sub-branches. The runs above instead let the engine auto-divide:
  **3,030 sub-branches x 33,003,300 nodes**. Both budget exactly 100B nodes and spend them
  differently; broader-and-shallower reaches more distinct records (27,664,734, giving
  `30b52336…`), fewer-and-deeper reaches fewer (12,386,121, giving `f1709ab0…`). Both are correct
  outputs of the same engine at their own configuration. The bisect document states the governing
  principle itself — that in BUDGETED enumeration the record SET depends on which sub-branches
  reach BUDGETED status — and applied it to code differences without applying it to its own
  configuration difference.

- **The information needed to avoid this was inside the artifact.** The deprecated row recorded this
  canonical's record count as "(not recorded)". It was never unrecoverable: `solutions.bin` carries a
  fixed 32-byte header whose bytes 8-15 are the uint64 record count, **inside the hashed stream**, so
  two files with different counts cannot share a sha. Reading `12,386,121` from the disputed file and
  setting it beside the bisect's `27,664,734` would have indicated a configuration difference rather
  than corruption, without re-running anything.

- **How it was found.** A 2026-08-07 gate run for an unrelated change (the telemetry patch's
  byte-identity check) produced `f1709ab0…` from a clean build, which contradicted this file's
  deprecation. Re-examination on 2026-08-08 extended it to the v1 lineage and recovered the bisect's
  recorded environment. Evidence is retained privately; the engine's own `solutions.sha256` and its
  reported record count corroborate the hashes independently of the verification harness.

- **Scope — the sibling deprecations stand.** This entry does **not** disturb `c34390c0` (5.6T) or
  `f7b8c4fb` (10T). Those rest on materially different evidence: each records an explicit
  record-count delta against a **named, reproducible replacement** (+1,030 and +4,607), and a small
  positive delta against an otherwise-matching run is genuinely resume-shaped. Both were re-examined
  for this entry and are better-founded than the row corrected here.

- **What is NOT claimed.** `f1709ab0…` is restored as a valid, **configuration-specific** 100B
  reference. It is *not* restored as a cross-build verification gate: 100B remains intrinsically
  code-specific, as §"100B and sub-canonical reference shas (code-specific)" already warns. The
  correction is to the characterization, not to that recommendation.

---

### CX-35 · 2026-08-08 · C2 · CX-29's one unconfirmed assumption, measured: the excised commits never reached the remote at all

- **Documents:** [CORRECTIONS.md](CORRECTIONS.md) — CX-29, its "Stated limitation" bullet and the
  sentence it qualifies. No claim in any report is affected.

- **What CX-29 said, and why this entry exists.** CX-29 (2026-08-07) recorded that this ledger's
  published git history had been rewritten to restore its append-only guarantee, and stated: *"At
  least `728778e7` had already been pushed."* It then flagged that sentence itself:

  > *"**Stated limitation.** That `728778e7` had been pushed is taken from the gate header's own
  > contemporaneous claim; it has not been independently confirmed against a remote's reflog."*

  **That confirmation has now been done, and it goes the other way.**

- **The measurement.** GitHub retains unreachable objects after a force-push and serves them by
  sha, so the remote's own view is decisive and does not depend on any local clone. Queried
  2026-08-08:

  | commit | on the remote? |
  |---|---|
  | `728778e7`, `77042b39`, `ec307098` (the violating chain) | **404 — no** |
  | `3bf04596`, `661b6cb7` (the two clean excised commits) | **404 — no** |
  | `af12a678` (positive control, pushed the same day) | **present** |

  The control is load-bearing: without it, a uniform 404 would be consistent with the endpoint
  simply not resolving shas. A local check agreed independently — `git reflog show origin/main`,
  514 entries spanning the window, contains no push of any of the five.

- **What follows.** The append-only violation was **caught and cured before it reached the public
  remote.** From `origin`, this ledger's published line has been append-only throughout and always
  was. No reader outside this machine could ever have observed the broken invariant. CX-29's
  account of the event stands unchanged in every other respect; only its assumption about
  publication was wrong, in the direction that made the project look worse than the record supports.

- **Residual limitation, stated rather than buried.** GitHub's retention period for unreachable
  objects is not contractually specified. A 404 six days after the fact is very strong evidence,
  not a proof. If a stronger form is ever wanted, it would need the remote's own audit log.

- **How it was found.** Not by an audit of CX-29 — by preparing an unrelated history entry, hitting
  the same underlying question, and going to check what the source actually said. The generalisable
  lesson is the one this window kept producing: **a citation is not a verification.** CX-29's claim
  was traceable to "the gate header's own contemporaneous claim," which reads as evidence and
  functions as one, and the header supported something adjacent and weaker. What made this
  recoverable is that CX-29 *labelled its own weakest sentence* instead of asserting it flat. The
  hedge is why the correction was findable at all.

---

## 2026-08-24 — the "≈3×10³⁷ distinct canonical orderings" figure is WITHDRAWN

**What was published.** `SEARCH_SPACE_SIZE.md` reported `— distinct canonical (after ~4×
orientation-dedup) | ≈3.3×10³⁷`, and the figure propagated into `README.md`, `METHODS.md`,
`CRITIQUE.md`, `PROJECT_OVERVIEW.md`, `CANONICAL_HASHES.md`, `SOLVE_SUMMARY.md`,
`BRANCHES_EXPLAINED.md`, `SOLVE.md`, `HISTORY.md` and `TR-4` — nineteen sites in all, several of
them as the denominator of a "≈1 part in 10²⁷ of the space" coverage claim.

**Why it is wrong, in one line.** The deduplicated object is a **pair ordering**. C4 pins one pair,
leaving 31 to order, so there are **at most 31! ≈ 8.2228×10³³** of them. **The published figure
exceeds its own combinatorial ceiling by a factor of ~4,013.** A count of a subset of a set of size
31! cannot exceed 31!. No estimator, sampling argument or distributional assumption is involved.

**The mechanism.** The figure divided the raw estimate by a **uniform ~4× orientation-dedup factor**
that does not exist. A within-pair flip changes the cycle structure and the sign, so most
orientations of a valid ordering are invalid (`solve.c:6564`). Two of this project's own
measurements of that ratio disagree by an order of magnitude — **42.2** mean variants per ordering
at a 10⁹-node search (`SOLVE.md`), versus **4.17×** at 560T (`CAMPAIGN_METHODOLOGY.md`). **Both are
artefacts of truncation**: a budgeted search visits only part of each class's orientation fibre, so
the observed ratio is a property of the *budget*, not of the space, and must never be extrapolated.
The correct quantity is `Σ 1/m([x])` over raw valid walks, and **E[1/m] ≠ 1/E[m]** — dividing by any
mean multiplicity is a Jensen error on top of the extrapolation.

**What replaces it.** Bounds, both ends exact:

> distinct canonical ∈ **[1.0525×10¹⁰ enumerated at 560T, 8.2228×10³³ = 31!]**
> implied true dedup factor **≥ 1.62×10⁴** — consistent with King Wen's own measured orientation
> fibre of **1,720,320**, and irreconcilable with `~4×`

**No point estimate is offered**, because `E[1/m]` has never been measured and the deduplication path
discards per-class multiplicities. **A stated absence is preferable to a repaired guess.**

**What survives, and it is most of it.** The coverage claim is **correct raw-against-raw** and has
been relabelled as such: 560T's **4.3876×10¹⁰ raw** records against the **1.3287×10³⁸ raw**
Monte-Carlo estimate is **≈1 part in 3.03×10²⁷**. Only the distinct-against-distinct pairing was
wrong; corrected it is ≈1 part in **7.81×10²³** — about **3,500× more coverage than was claimed**, so
the error understated the enumeration rather than overstating it. **The qualitative verdict —
exhaustion is infeasible at any conceivable budget — survives with 23 orders of magnitude to
spare.** The exact **|C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688** (published 2026-07-16) is
unaffected, as is the raw `1.3287×10³⁸` estimate.

**How it was found — external attribution.** An **OpenAI Codex** review (target `A02` of a
cross-model review programme, 2026-08-23/24) was asked to derive the space arithmetic independently
and compare. It attacked the uniform dedup factor **without being told this project already
suspected the figure**, arriving at the same conclusion by a different route. A subsequent audit
found **no derivation of the ≈3×10³⁷ figure anywhere in the project's private records either** — a
third, independent reason to withdraw rather than repair it. Codex is **acknowledged**, not credited
as an author.

**The lesson worth more than the arithmetic.** The figure was suspected internally on **2026-07-30**
and the internal note recorded *"we have **not** applied any fix."* It stayed published for
**twenty-five days**. The delay between knowing and acting is the more useful finding here.

**Correction-record lines deliberately left unmarked**, because marking them would corrupt the
record of earlier corrections: `CORRECTIONS_INVENTORY.tsv:584`, `CITATIONS.md:87`,
`SOLVE_SUMMARY.md:147` and `:180`.

---
> ⚠ **Provenance note (2026-08-24).** The entry below was authored on branch
> `v4-query-program` on 2026-08-23 and is preserved verbatim, because this ledger is
> append-only over *every committed version* — including versions committed on a branch.
> It describes the **same withdrawal** as the 2026-08-24 entry above, which supersedes it
> with the full 19-site sweep and the private-records audit. **Both stay.** That two
> divergent copies of an append-only ledger could exist at all is itself the defect
> recorded as the branch-documentation drift.

## 2026-08-23 — the "≈3×10³⁷ distinct canonical orderings" figure is WITHDRAWN

**What was published.** `SEARCH_SPACE_SIZE.md` reported `— distinct canonical (after ~4×
orientation-dedup) | ≈3.3×10³⁷`, and that figure propagated into `CRITIQUE.md`,
`PROJECT_OVERVIEW.md` and `CANONICAL_HASHES.md` as the denominator of a "≈1 part in 10²⁷ of the
space" coverage claim.

**Why it is wrong, in one line.** The deduplicated object is a **pair ordering**. C4 pins one pair,
leaving 31 to order, so there are **at most 31! ≈ 8.2228×10³³** of them. **The published figure
exceeds its own combinatorial ceiling by a factor of ~4,013.** A count of a subset of a set of size
31! cannot exceed 31!. No estimator, sampling argument or distributional assumption is involved.

**The mechanism.** The figure divided the raw estimate by a **uniform ~4× orientation-dedup factor**.
That factor is not a constant and is not an orbit size: a within-pair flip changes the cycle
structure and the sign, so most orientations of a valid ordering are invalid. Two of this project's
own measurements disagree by an order of magnitude — 42.2 mean variants per ordering at a 10⁹-node
search, versus a 4.17× ratio at 560T. **Both are artefacts of truncation**: a budgeted search visits
only part of each class's orientation fibre, so the observed ratio is a property of the budget, not
of the space, and must never be extrapolated. The correct quantity is `Σ 1/m([x])` over raw valid
walks, and **E[1/m] ≠ 1/E[m]** — dividing by any mean multiplicity is a Jensen error on top of the
extrapolation.

**What replaces it.** Bounds, both ends exact:

> distinct canonical ∈ **[1.0525×10¹⁰ enumerated at 560T, 8.2228×10³³ = 31!]**
> implied true dedup factor **≥ 1.62×10⁴** — consistent with King Wen's own measured orientation
> fibre of **1,720,320**, and irreconcilable with `~4×`

No point estimate is offered, because `E[1/m]` has never been measured and the deduplication path
discards per-class multiplicities. **A stated absence is preferable to a repaired guess.**

**What survives, and it is most of it.** The coverage claim is **correct raw-against-raw** and has
been relabelled as such: 560T's **4.3876×10¹⁰ raw** records against the **1.3287×10³⁸ raw**
Monte-Carlo estimate is **≈1 part in 3.03×10²⁷**. Only the distinct-against-distinct pairing was
wrong; corrected, it is ≈1 part in **7.81×10²³** — about **3,500× more coverage than was claimed**,
so the error understated the enumeration rather than overstating it. **The qualitative verdict —
exhaustion is infeasible at any conceivable budget — survives with 23 orders of magnitude to
spare.**

**Landed in the same revision:** the exact **|C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688**, which
replaces a Monte-Carlo estimate and retires a `[COUNT — PENDING, do not cite]` placeholder that had
stood in `HISTORY.md` while the value sat computed but unpublished. It agrees with that same Knuth
estimator to **0.0044 per cent**, which is the reason to publish the two together: the instrument
behind the surviving raw figure has now been checked against ground truth.

**How it was found — external attribution.** An **OpenAI Codex** review (target `A02` of a
cross-model review programme run 2026-08-23/24) was asked to derive the space arithmetic
independently and compare. It attacked the uniform dedup factor **without being told this
project already suspected the figure**, arriving at the same conclusion by a different route.
Codex is **acknowledged**, not credited as an author. The ceiling argument came from re-deriving what the deduplicated
object actually is. **The figure had been suspected internally since 2026-07-30 and no fix had been
applied** — the delay between knowing and acting is the more useful lesson here than the arithmetic.

---

## 2026-08-28 — the PER-BRANCH figures carried the same raw/canonical label defect, and the 19-site sweep missed them

**What was published.** `SEARCH_SPACE_SIZE.md` §"Result — per first-level branch" reported
`canonical orderings per branch: min 1.26×10³⁶, median 2.26×10³⁶, max 3.46×10³⁶`, and the same
per-branch figures propagated to `TR-4` §3, `HISTORY.md`, and twice more inside
`SEARCH_SPACE_SIZE.md` itself (the "roughly uniform" bullet and Implication 1's
"any *single* first-level branch (~2×10³⁶)").

**Why it is wrong, in one line.** Word-for-word the defect withdrawn on 2026-08-24, one level down:
the deduplicated object is a **pair ordering**, C4 pins pair 1 and a first-level branch pins pair 2,
leaving 30 to order — so there are **at most 30! ≈ 2.65×10³²** canonical orderings per branch.
Labelled "canonical", the published figures exceed their own combinatorial ceiling by
**4,750× (min), 8,520× (median) and 13,044× (max)**.

**But the numbers are sound; the label is not.** These are **raw** per-branch counts:

- They sum to **1.33×10³⁸** — the raw whole-tree estimate — which `TR-4` §3 states in the very
  sentence preceding them, as an "independent cross-check" against the raw whole-tree figure.
- Against the **raw** per-branch ceiling `30!·2³⁰ ≈ 2.85×10⁴¹` they sit at ≈4.4–12×10⁻⁶, and the
  median sits at **7.94×10⁻⁶** — indistinguishable from the **7.52×10⁻⁶** at which the raw
  whole-space estimate sits against `31!·2³¹`. A relabelling error reproduces that ratio; a
  measurement error would not.

So this is **corrected, not withdrawn**: the figures are relabelled raw, and the per-branch
*canonical* count is recorded as **not established**, because the ≈4× orientation-dedup factor
needed to derive it is precisely the ingredient the 2026-08-24 entry withdrew.

**What survives, on a stronger footing than before.** "No single-branch walk can exhaust anything"
no longer rests on the withdrawn estimate at all. Orientation-deduplication *within* a branch can
divide by at most **2³⁰ ≈ 1.07×10⁹** (pairs 1 and 2 are already orientation-pinned), so the
canonical count of even the **smallest** branch is at least `1.26×10³⁶ / 2³⁰ ≈ 1.2×10²⁷` — still
**≈10¹⁷×** beyond the 1.05×10¹⁰ orderings of the deepest published canonical. That is a worst-case
bound on the dedup factor, not an estimate of it, so it holds however `E[1/m]` eventually measures.
Implication 1's "off by 24+ orders of magnitude" is corrected to **17+**, which is what the
dedup-independent floor supports.

**What does NOT survive.** The *uniformity* claim ("spread of only ≈2.7×", "extrapolation from one
branch to the whole is well-founded") is raw-against-raw and is now stated only for **raw** size.
Per-branch dedup factors were never measured, so uniformity of the **canonical** per-branch counts
is not established and is no longer asserted.

**Why the 2026-08-24 sweep missed it.** That sweep enumerated sites by searching for the
whole-space figure `≈3.3×10³⁷` and its `10²⁷` coverage denominator. The per-branch decomposition of
the same estimate is written as `10³⁶` and matched neither pattern — including at `HISTORY.md:5139`
and `TR-4:72`, where the unmarked per-branch clause sits in the **same sentence** as a marked
whole-space one. A sweep keyed on a figure cannot find that figure's decompositions; it needs to be
keyed on the *property* — a count labelled canonical that exceeds its own factorial ceiling. That
gate is now `doc_gates.sh` GATE 26 (`canonical-ceiling`), which fails on either instance.

**Attribution.** Raised as one of two label residues by **Codex** review target `R03`
("Published search-space arithmetic vs its own definitions"), whose charge was that the
2026-08-24 nineteen-site withdrawal left labels standing; surfaced in the D1 batch-1 transcript
adjudication and verified here against `origin/main` `db4ac3dc` by re-deriving the ceilings and the
raw-fraction comparison. Codex is **acknowledged**, not credited as an author.

**And the sweep missed more than the per-branch family.** Building GATE 26 required enumerating every
site of the withdrawn figure by *property* rather than by string, and that enumeration found **five
live publication sites of the whole-space figure itself**, still unmarked four days after the
nineteen-site sweep:

| site | what it said |
|---|---|
| `enumeration/LEADERBOARD.md:3` | `(≈3×10³⁷ distinct-canonical), so even 560T's 10.5 B is ≈1 part in 10²⁷ of the space` — the withdrawn figure **and** the withdrawn coverage denominator, in the enumeration headline |
| `enumeration/LEADERBOARD.md:170` | `orderings at ≈10³⁸ (≈3×10³⁷ distinct-canonical)` |
| `documentation/SOLVE_SUMMARY.md:178` | `now puts the total at ≈10³⁸ (≈3×10³⁷ distinct-canonical)` |
| `documentation/SOLVE_SUMMARY.md:211` | `an estimated ≈3×10³⁷ valid arrangements` — the *deduplicated* figure wearing a **raw** label; the orientation-explicit estimate is 1.33×10³⁸ |
| `documentation/CITATIONS.md:97` | `estimated at 1.33×10³⁸ orientation-explicit, ≈3.3×10³⁷ after orientation-dedup`, inside CX-30's own correction text |

`enumeration/LEADERBOARD.md` carried **no withdrawal marker at all**, while
`documentation/SOLVE_SUMMARY.md:237` carried one correctly — so the sweep reached that file and
still left two of its lines standing. All five are now marked.

**One site is deliberately left unmarked: `CORRECTIONS.md:948`,** inside **CX-30** (2026-08-07),
which cites `≈3.3×10³⁷` three weeks before the withdrawal. This ledger is append-only and GATE 10a
fails on any reworded committed line, so CX-30 stays verbatim — *verified by reading the gate, not
assumed*. This paragraph is the forward pointer CX-30 cannot carry: **the `≈3.3×10³⁷` in CX-30 is
withdrawn.** The remaining unmarked occurrences are this ledger's own withdrawal entries quoting
what they withdraw, and `TR-4`'s v1.21 revision row explaining the marker — all of which must state
the figure to do their job.

**The lesson, which is the reusable part.** Both misses share one cause: **a sweep keyed on a string
cannot find that string's decompositions or its restatements.** The per-branch figures are the same
estimate written as `10³⁶`; `SOLVE_SUMMARY.md:211` is the same figure relabelled "valid
arrangements"; `LEADERBOARD.md` used the hyphenated `distinct-canonical`. None matched a search for
`3.3×10³⁷` next to `distinct canonical`. GATE 26 is keyed on the property instead — *a count labelled
canonical whose magnitude exceeds `31!`* — which is invariant to all three rewordings, and it is
tested by planting each of the two historical defects and confirming the gate goes red on both.

---

## 2026-08-28 — the 43,876,464,466 figure is not "raw records", and the 4.17× is not a dedup ratio

**What was published.** Three sites labelled the 560T pre-merge shard total as **raw**:
`CAMPAIGN_METHODOLOGY.md:487` ("Pre-dedup raw records | 43,876,464,466 (4.17× dedup ratio)"),
`CANONICAL_HASHES.md:67` and `HISTORY.md:5106` ("the old run's raw pre-dedup total"). The
2026-08-24 entry above then paired that total against the raw 1.3287×10³⁸ as the "correct
raw-against-raw" coverage, ≈1 part in 3.03×10²⁷.

**Why the label is wrong, from the code.** `solve.c:39-61` states that each thread's hash table
stores **canonical pair orderings** — "hash and dedup compare pair identity only (orient bit masked
out)" — and that **"after each sub-branch, the thread's hash table is flushed … and the table is
cleared."** So a shard record is a per-sub-branch **canonical** key, not a raw oriented leaf, and
the sum over shards counts the same canonical ordering once per sub-branch that rediscovers it.
43,876,464,466 is therefore **cross-sub-branch rediscovery of canonical keys**, and as a count of
raw oriented leaves it is a **lower bound** (each key implies at least one leaf visited), never the
quantity itself. Every argument built on it survives: the old-vs-new run comparison
(+3,841,927 = 0.009% over-emission, all duplicates) compares two totals of the *same* kind, so it is
unaffected. Only the label moves, and the coverage figure keeps its value as a bound.

**A sharper consequence for this ledger's own reasoning.** The 2026-08-24 entry cites **4.17× at
560T** as one of two disagreeing measurements of the orientation-dedup ratio — "42.2 mean variants
per ordering at a 10⁹-node search versus 4.17× at 560T … both are artefacts of truncation." That
framing is too generous to itself. The 4.17× is `43,876,464,466 / 10,525,271,997`: shard records
over merged records. Since shard records are *already* orientation-deduplicated, **4.17× is not a
measurement of orientation multiplicity at all** — it is the cross-sub-branch rediscovery factor,
a property of the depth-3 partition. The two numbers did not disagree about one quantity; they were
never measuring the same quantity. The 2026-08-24 conclusion (do not extrapolate either) stands, and
its stated reason was weaker than the truth. That entry is preserved unedited — this ledger is
append-only, GATE 10a enforces it — and this paragraph is its correction.

**Also corrected, same root.** `SEARCH_SPACE_SIZE.md`'s estimate-table header read
**"canonical (C1–C5) orderings (raw)"** — a single cell asserting both object conventions at once.
That cell is the origin of the conflation withdrawn on 2026-08-24 and of the per-branch label defect
corrected earlier today; it now names the orientation-explicit object and states both ceilings.

**Scope note.** `SEARCH_SPACE_SIZE.md:193`'s "identifying King Wen requires log₂(1.3287×10³⁸) =
126.6 bits" prices the **raw** object — correct as used, since a boundary constraint identifies an
*oriented* ordering. Over the canonical object the figure would be log₂(31!) = **112.66 bits**, a
ceiling. The ~14-bit gap is about one and a half boundary-steps, so comparing the 126.6 against any
canonical-object count is a units error large enough to change a conclusion. Said explicitly at the
site.

**Attribution.** Codex target **R03**, whose charge was that the withdrawal left labels standing.
The code reading that settles it is `solve.c:39-61`, checked directly rather than taken from the
review. Codex is **acknowledged**, not credited as an author.

---

## 2026-08-28 — two sidecar writers disagreed, and the standalone `--merge` one recorded the gzip container sha

**What was published.** `SOLUTIONS_FORMAT.md` §"File integrity" states that `solutions.sha256`
holds "the SHA-256 hash of the entire **logical** `solutions.bin` byte stream … that is
`gzip -dc solutions.bin | sha256sum`, **not** `sha256sum solutions.bin`", and `CANONICAL_HASHES.md`
stated "Either way the `solutions.sha256` sidecar already holds the logical sha." **Both were false
for any artifact produced by the standalone `--merge` path.**

**The defect.** `solve.c` had **two** sidecar writers. The enumeration path used
`write_sha256_with_metadata()` → `sha256_of_logical()`, which decompresses by magic and hashes the
canonical byte stream. The standalone `--merge` finalizer instead shelled out
`sha256sum <outname> > solutions.sha256`, hashing the file **as it sits on disk**. Since #169 the
default framing is gz, so every gz-framed merge recorded the sha of the **compressed container**.
`solutions.meta.json` inherited the same wrong value, because its hash is parsed back out of the
sidecar.

**Measured, by running the binary.** Two shard fixtures merged to 13,320 records. The pre-fix binary
wrote sidecar `2d6411e65e7b41d654eac5e6d997c1270307b14fd9d61e6b0c6d1c8541327c51`, which is exactly `sha256sum solutions.bin`; the same bytes hash to
`6ce4eea17318edd3f2e5f9488ec0c2a4fed26d940228d08fcf562d32ab7a4f9f` under `gzip -dc | sha256sum` — the value the artifact's own metadata carries. After
the fix the same merge writes `6ce4eea17318edd3f2e5f9488ec0c2a4fed26d940228d08fcf562d32ab7a4f9f`, matching a **coreutils** computation done outside
`solve.c` entirely.

**Why this direction is the expensive one.** gzip framing is not canonical content: it varies with
zlib version and compression level. A container sha therefore **false-mismatches an artifact that is
byte-identical where it counts** — it manufactures phantom drift, and this project has already spent
real time bisecting drift that proved to be host-level rather than content-level.

**Fixed at the root, not in the documentation.** The `--merge` finalizer now calls the same
`sha256_of_logical()` helper the enumeration path uses — one artifact, one definition — so the two
published statements are now true rather than being edited to match a defect. Canonical `--selftest`
sha `403f7202…` and the 12-warning baseline are both unchanged; this path is not on the enumeration
line.

**Gated.** `scripts/sidecar_sha_gate.sh`. LEG 1 (source-level, runs on any clone) forbids writing a
sidecar by shelling out to a sha tool, which is the regression that actually occurred; LEG 2
(artifact-level) checks a present `solutions.bin`/`.sha256` pair against an **independently**
computed logical sha — coreutils, never `solve.c`'s own helper, or the gate would check the
implementation against itself. Both legs were shown red and then green: LEG 1 on the original code
re-planted, LEG 2 on the pre-fix merge output. LEG 1 excludes comment lines, because its first run
went red on the comment *documenting* the defect — a gate that cannot tell code from prose about
code punishes writing the explanation down.

**Scope caveat, stated rather than assumed.** Any sidecar written by a standalone `--merge` before
today, under gz framing, holds a container sha. **No audit of existing archives has been performed
here**, and a mismatch against such a sidecar should be re-checked with `gzip -dc | sha256sum`
before being read as corruption. A related claim — that this is the un-fixed root of the 560T
`daab1c48` episode — was raised in the D1 batch-3 review and is **recorded as unverified by this
entry**; it is tracked as Q-324.

**Attribution.** Raised by Codex target **R04** and surfaced in the D1 batch-3 transcript
adjudication; the code path, the reproduction and the fix were verified here by running the binary.
Codex is **acknowledged**, not credited as an author.

---

## 2026-08-28 — a published P-value that never computed its own caveat, and "seven others" that are all King Wen

Two corrections from the D1 batch-4 Codex adjudication, both **recomputed here** rather than accepted
from the review.

### 1. `DISTRIBUTIONAL_ANALYSIS.md:358` — "mildly notable (4/6, null P = 0.034)" reverses to unremarkable

The sentence carried its own caveat — *"with the C4-fixes-two-positions caveat"* — and **nothing ever
computed that baseline.** `roae.py`'s sampler shuffles all 32 pair blocks, so the published 0.034 is
the **unconstrained** null: P = [C(4,2)·28 + C(4,3)] / C(32,3) = 43/1240 = 0.0347.

But C4 pins the pure block {63,0} into pair slot 1, which is **already an end slot**. The constrained
question is therefore whether at least one of the *remaining three* pure blocks falls in slots
{15,32} among the 31 remaining: **P = 1 − C(28,2)/C(31,2) = 87/465 = 29/155 = 0.1871**, exact, no
simulation required. Verified by a second algebraic route (1 − C(29,3)/C(31,3), identical) and by
Monte Carlo (0.1869 over 2×10⁶ draws).

**That is 5.40× the published value, and the verdict reverses**: a 0.187 result is unremarkable. A
caveat that names the right baseline and never evaluates it is worse than no caveat, because it reads
as though the correction has been considered. The 0.034 is retained only as the unconstrained
comparison.

### 2. `TR-4:95–97` and `SEARCH_SPACE_SIZE.md:126–128` — "KW plus seven others" is the opposite of what the enumeration shows

Published: *"exact counting finds 16,504 C1–C5 completions of which exactly 8 satisfy C6/C7 — KW plus
seven others even in its own immediate neighborhood"*, inside a passage arguing **non-uniqueness**.

**All eight survivors carry King Wen's own pair ordering.** The seven "others" are orientation
variants of KW's pair sequence. The 16,504 are **oriented** leaves — 899 distinct pair orderings — and
C6/C7 eliminate **898 of the 899**, leaving King Wen's alone.

Established with the shipped binary by a route independent of the review's own programs:

| run | pins | `leaves_canonical_C1C5` | `tree_nodes` |
|---|---|---:|---:|
| baseline | 22-pair KW prefix | 16,504 | 9,422,793 |
| C6/C7 | slots 24–27 to KW pairs, **pair ordering free** | **8** | 1,169 |
| C6/C7 + all free slots | slots 24–32 to KW pairs, **orientation free** | **8** | 233 |

The third run's feasible set is a strict subset of the second's (tree_nodes 1169 → 233) and has the
**same cardinality**, so no survivor departs from King Wen's pair sequence.

At this scope the check corroborates **uniqueness in the canonical frame**. The surrounding argument
is about non-uniqueness at the **oriented** level, which is a different object — both can be true, and
the sentence must not be read as evidence for the first. This is the same canonical-vs-oriented
ambiguity corrected twice already today; here it inverted the meaning of a corroboration rather than
inflating a magnitude. Note the binary's own field name, `leaves_canonical_C1C5`, reports an
**oriented** count — tracked with the terminology items as Q-321/Q-330.

**Attribution.** Raised by Codex targets **R08** and **T04** via the D1 batch-4 adjudication; both
numbers recomputed here, the second with an instrument (`SOLVE_KNUTH_PIN_SLOTS`) the review did not
use. Codex is **acknowledged**, not credited as an author.

---

## 2026-08-28 — the C2∩C3 joint, reproduced independently: the product is exceeded by ~11%

The 2026-08-28 entry above corrected `CRITIQUE.md:137`'s "rough **ceiling**" on reasoning alone — a
product of marginals is an independence *estimate*, and bounds the joint from above only if the two
constraints are non-positively correlated. It also recorded, honestly, that the review's supporting
**measurement** had not been reproduced here. **It now has been.**

A separately-written sampler over the same null (C1 given, start-free: a uniform random permutation
of the 32 King Wen pair blocks with uniform random orientations) gives, at 10⁷ trials:

| quantity | measured | published exact | agreement |
|---|---:|---:|---|
| P(C2 \| C1) | 4.29159% | **4.29341%** | 0.3σ |
| P(C3 \| C1) | 6.41625% | **6.4211367496%** | 0.6σ |
| product | 0.27536% | 0.27568% | — |
| **P(C2 ∧ C3 \| C1)** | **0.30478%** | — | **+16.7σ over the product** |

**The marginals are the point of the design.** They are published as *exact* values
(`solve --f1-exact-c1c2`; `verify.py --check-null-g --unpinned`), so reproducing them from an
independent implementation is what licenses trusting its joint — the check validates the instrument
before the instrument is used. The predicates are additionally anchored on King Wen itself: KW
satisfies C2, and cd(KW) = **776** exactly, which is the C3 ceiling by construction.

Two independent runs now agree: **0.305832%** at 10⁹ (D1 batch-4) and **0.30478%** at 10⁷ here —
0.6σ apart. C2 and C3 are **positively correlated** given C1; the independence product is **not** an
upper bound, and the published sentence's "ceiling" framing is wrong in the direction that
understated the joint by ~11%.

`CRITIQUE.md:137` now publishes the measured joint rather than citing an unreproduced figure, and the
sampler ships as `scripts/c2c3_joint_null.py` — a published figure whose only reproduction path was a
private script would not be reproducible at all. The
remaining `Q-329` items — the reversed `DISTRIBUTIONAL_ANALYSIS.md` P-value (corrected 2026-08-28)
and the Gray-code-family bound drawn from a self-described non-uniform sampler (**not yet
addressed**) — are unaffected by this entry.

**Attribution.** Codex target **R08** raised the ceiling claim; the measurement was made twice, once
in the D1 batch-4 adjudication and once here from an independently written sampler. Codex is
**acknowledged**, not credited as an author.
