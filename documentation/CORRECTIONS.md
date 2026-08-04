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
