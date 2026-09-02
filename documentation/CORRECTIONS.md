# Corrections — the append-only record

Every claim this project published and later changed, in one place.

> ⚠ **Scoped in part, 2026-09-01 — see item 4 of the 2026-09-01 `rev_V2-F14` entry at the foot of this file.**
> This subtitle promises a completeness the file deliberately does not have: `:520` excludes **C4
> qualifier** changes, which live in the inventory rather than here, and `:521` records that silent
> edits leaving no trace cannot be found by any sweep. Both exclusions are correct and are stated
> below — 517 lines below — so this is a placement defect, not a false claim. Read the promise as
> "except C4 qualifier changes and silent edits, both scoped below." The original wording is
> preserved: this ledger is append-only.

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

> ⚠ **Corrected in part, 2026-09-01 — see item 4 of the 2026-09-01 entry at the foot of this file.**
> The retraction below stands. One clause in its `NOW:` bullet does not: "C4's orientation is
> definitional and classically attested (Xugua)". The Xugua does **not** attest the within-pair order —
> `reports/METHODS.md:24-33`, narrowed 2026-08-30, records that 有天地，然後萬物生焉 sequences the pair
> before the myriad things and that C4's orientation is ours by definition. C4's *pair choice* is the
> classical part. The original wording is preserved: this ledger is append-only.

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

> ⚠ **Corrected in part, 2026-09-01 — see item 1 of the 2026-09-01 entry at the foot of this file.**
> Two statements below are wrong. The step-3 information gain is **larger** than the step-1 divisor
> (11.10 bits against 10.38, `reports/TR4_SIZE_OF_THE_SPACE.md:253`), not smaller — and that reversed
> inequality is what breaks the divide-by-maximum argument, where a genuinely smaller later gain would
> have left it standing. And the "heuristic floor" label, together with the CLAIMS_DECIDED wording
> quoted below, was superseded the **same day** by TR-4 v1.16, which removed the word rather than
> re-qualifying it; `documentation/CLAIMS_DECIDED.md:34` now reads "NOT a floor of any kind". The
> withdrawal this entry records still stands. The original wording is preserved: this ledger is
> append-only.

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

> ⚠ **Corrected in part, 2026-09-01 — see item 5 of the 2026-09-01 entry at the foot of this file.**
> "Both budget exactly 100B nodes" is arithmetically false: 158,364 × 631,545 = 100,013,992,380 and
> 3,030 × 33,003,300 = 99,999,999,000, a 0.014% difference, and neither equals 100B. The comparison is
> a partition-shape comparison, not an exactly budget-matched one. Everything else in this entry —
> the four-build reproduction, the retraction of the deprecation, and shape as the mechanism — stands.
> The original wording is preserved: this ledger is append-only.

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

> ⚠ **Corrected in part, 2026-09-01 — see item 3 of the 2026-09-01 `rev_V2-F14` entry at the foot of this file.**
> The "What follows" bullet states two unhedged universals — that the published line **always was**
> append-only, and that **no reader could ever have observed** the broken invariant — while the
> qualifier that governs them sits in the next bullet, "Residual limitation", which rates the same
> evidence as very strong but **not a proof**. The entry does not bury its limitation; it headlines
> it. The defect is structural: the hedge is never attached to the conclusion, so a reader quoting the
> conclusion carries away the universals alone. The 404 table, the positive control and the reflog
> check are unaffected. The original wording is preserved: this ledger is append-only.

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

> ⚠ **Corrected in part, 2026-09-01 — see item 2 of the 2026-09-01 `rev_V2-F14` entry at the foot of this file.**
> The corrected coverage figure below is stated as "≈1 part in 7.81×10²³", but its denominator is
> `31!` — the **upper** end of this entry's own bounds — so it is a **bound, not an estimate**, and it
> is offered six lines after the entry declines to give a point estimate. Since the true population
> P ≤ 31!, coverage is **at least** 1 part in 7.81×10²³
> (`python3 -c "import math; print(math.factorial(31)/1.0525e10)"` → 7.8127e+23). The withdrawal, the
> bounds and the qualitative verdict are unaffected. The original wording is preserved: this ledger is
> append-only.

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

> ⚠ **Corrected in part, 2026-09-01 — see item 2 of the 2026-09-01 `rev_V2-F14` entry at the foot of this file.**
> The corrected coverage figure below is stated as "≈1 part in 7.81×10²³", but its denominator is
> `31!` — the **upper** end of this entry's own bounds — so it is a **bound, not an estimate**, and it
> is offered six lines after the entry declines to give a point estimate. Since the true population
> P ≤ 31!, coverage is **at least** 1 part in 7.81×10²³
> (`python3 -c "import math; print(math.factorial(31)/1.0525e10)"` → 7.8127e+23). The withdrawal, the
> bounds and the qualitative verdict are unaffected. The original wording is preserved: this ledger is
> append-only.

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

> ⚠ **Corrected in part, 2026-09-01 — see item 5 of the 2026-09-01 `rev_V2-F14` entry at the foot of this file.**
> "The 2026-08-28 entry above corrected `CRITIQUE.md:137`" points at nothing: `CRITIQUE.md:137`
> occurs in this file only at `:1655` and `:1681`, **both inside this entry**, and no earlier
> 2026-08-28 entry treats the C2∩C3 ceiling. The pointer should be a self-reference. The sampler, the
> marginals and the ~11% result are unaffected. The original wording is preserved: this ledger is
> append-only.

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

---

## 2026-08-28 — a rate bound published as a minimum bound, among only three survivors of the battery bar

**What was published.** `CRITIQUE.md:60`, in the list of claims that *"survive both the 0.0018 battery
bar and the 5.5×10⁻⁴ global bar"* — three items in all — named the third as *"the Gray-code
**minimum**-C3 bound (minimum across 10⁵ samples = 832 > 776, CI ≤ 3×10⁻⁵)"*.

**Why it is wrong, in one line.** **A sample minimum is an upper bound on the true minimum, never a
lower bound.** Observing 832 as the smallest C3 across 10⁵ sampled Gray codes establishes that the
family minimum is **≤ 832**. It is entirely consistent with the family minimum being below 776 —
which is the direction the sentence was being read in, since 776 is King Wen's value and the point
being made was that no Gray code reaches it. Sample coverage is 10⁵ of ~10²², about **10⁻¹⁷** of the
family.

**The instrument was more careful than the document.** `solve.c:11465` prints *"Non-uniform sampler;
bounds conditional C3 **rate** over the ~10²² Gray code family"*, and `HISTORY.md:409` describes a
*"biased sampler … bounds the C3 **rate**"*. **Only `CRITIQUE.md:60` said *minimum*.** A rate bound
was converted into a minimum bound at the single site closest to the headline summary of what
survives.

**A second, independent over-reach in the same item.** The `CI ≤ 3×10⁻⁵` is the rule of three
(0 successes in 10⁵ ⇒ 3/10⁵), which is valid — **for the distribution actually sampled**. The
sampler declares itself non-uniform in its own output. So the figure bounds the rate under the
sampler's induced distribution, not under the uniform Gray-code family, and that qualifier was
dropped.

**What survives.** The scoped rate statement: *0 of 10⁵ Gray codes drawn by a non-uniform
Hamiltonian-walk sampler satisfy C3 ≤ 776, giving a rule-of-three upper bound of 3×10⁻⁵ on that
sampler's rate.* **The minimum claim does not survive at all.** This item's standing among the three
battery-bar survivors now rests on the rate half alone, and the line says so.

**The same error was projected into future work.** `CRITIQUE.md:324` proposed that 10⁹ biased samples
"would give a firm upper bound on the Gray-code C3 rate". They would not: more draws shrink the
interval on *that sampler's* rate, and **an estimator's bias does not decay with N**. A firm bound on
the family needs a uniform sampler over Hamiltonian cycles in Q₆, or importance weights with known
likelihood ratios — neither of which this instrument has. Corrected at the site, before "a few hours"
of compute was spent on a result it could not buy.

**No published number changes.** 832, 10⁵ and 3×10⁻⁵ are all as measured; what changes is what they
are claimed to bound.

**Attribution.** Raised by Codex target **R08** via the D1 batch-4 adjudication; the minimum-versus-
rate reading, the coverage figure and the bias-does-not-decay point were derived here. Codex is
**acknowledged**, not credited as an author.

---

## 2026-08-28 (same day, later) — my own run description was wrong: "every free slot" pinned only eight of nine

The entry above ("KW plus seven others") reports the corroborating runs as *"C6/C7 with the pair
ordering free → 8 survivors, 1,169 nodes; C6/C7 with **every free slot** additionally pinned to KW's
pairs → also 8, 233 nodes"*.

**The 233-node run did not pin every free slot.** It passed
`SOLVE_KNUTH_PIN_SLOTS="24,…,32"`, which leaves **position 23 order-free** — pins `24–31` produce the
identical 233, so slot 32 was a no-op. Pinning all nine free steps (`23–32`) gives **75** nodes.

**The finding is unaffected and the conclusion stands.** The survivor count is **8** in all three
variants, so every C6/C7 survivor still carries King Wen's pair ordering; the reviewer additionally
reproduced 690,176 / 16,504 / **899** / 8 from an independently written Python DFS — the first
independent confirmation of the 899 figure. What was wrong was the *description of the run*, which
claimed a stronger pinning than was performed.

**How it was found, which is the part worth keeping.** A Fable reviewer was dispatched with one
instruction the twenty-four Codex lenses could not follow — *run the artifact*. Those lenses all
reported GCC, Lean, kissat and drat-trim absent, so not one executed anything. This reviewer re-ran
the command and got a different node count than the sentence claimed. **An executed review caught,
within hours, an error in a correction written the same day**; no amount of re-reading would have.

These sites are corrected in place rather than by marker alone, because they were **committed but
never pushed** — the error has not been published.

---

> ⚠ **Corrected in part, 2026-09-01 — see item 6 of the 2026-09-01 `rev_V2-F14` entry at the foot of this file.**
> "No such author exists" (`:1797`) is a claim about the world; what the evidence establishes is that
> **this paper's** author is 管小思 and that the printed form was a romanisation collision. The same
> over-reach recurs at `:1803-1804`, where the recorded cost of the error infers nonexistence from absence
> of search results. The bibliographic correction, the dates and the 1995 paper are unaffected. The
> original wording is preserved: this ledger is append-only.

## 2026-08-28 — a firstness claim we had already ruled false stayed live for four weeks, and an author's name was wrong

Two published errors in `CITATIONS.md`, found the same day by a review lens pointed at novelty
language. They are unrelated in substance and share one cause: **the check that was supposed to catch
each of them looked at the wrong line.**

**1. The firstness claim.** The Suenaga 2012 entry read *"the first author we have located to start
counting the arrangement space."* This project's own adjudication of 陳壯維 2007 ruled that sentence
**false as written on 2026-08-24** — 黄石聲 1997 published the 8!×8! matrix-form count, and 陳壯維
2007 restates it with a 7!×7! refinement. Both were already in our record. The sentence entered main
on 2026-07-31 (`6a3feaaa`) and was still there on 2026-08-28. It now reads **"an independent arrival
at counting the arrangement space"**, which is what we can support: independent arrival, no priority.

**Why it survived two checks that both reported it gone.** Q-127 (closed) and Q-263 (open) each
recorded the sentence as no longer live on main. Both were right about the text they read — the
section *preamble* says "independently developed … and initiated counting" and "we claim no
originality" — and neither read the *entry body* further down the same file. The good statement and
the bad one coexisted for four weeks, and each check stopped at the good one. A consequence worth
stating plainly: **an operator question (Q-263) was posed on a false premise**, because it described
the remaining defect as a single citation chain when this sentence was also live.

**2. The author's name.** Two files — this one's sibling `CITATIONS.md` and
`KING_WEN_PROVENANCE.md` — named **關曉思** as the author of a structural mathematical model of the
hexagram sequence. **No such author exists.** The name is **管小思** (Tongji University, 周易研究
2004(1), pp. 61–74); wrong surname and wrong given name, both of which romanise identically to
"GUAN Xiao-si", which is all we ever had from a printed contents list. Corrected across our private
records on 2026-08-24; the two public sites were missed until 2026-08-28.

This is a citation error, not a typo, and it had a cost: the author was repeatedly recorded as
un-findable by author search, which we read as an indexing quirk. We were searching for a person who
does not exist. Correcting the name made a further paper by him (1995) findable in about a minute.

**3. The paragraphs those names sat in are also updated.** Both said the ordering-count question
"has never been the target of a search designed for it" and that the two papers "are unread." Both
statements were true when written and are now false: the designed search ran on 2026-08-16, and every
obtainable paper by either author has been read (one item, 王俊龍 2007 in 劉大鈞 ed. 大易集釋
pp. 812–836, remains unobtainable). **The narrow scoping those paragraphs impose is deliberately left
in force** — the adjudication of those reads is not published yet, so the surrounding claim continues
to be stated as a statement about five named authors and not as a survey result. Nothing here widens
a claim.

**Attribution.** All three were raised by a Fable review lens dispatched to re-read the project's
novelty language from outside; the corrections and the premise analysis were derived here. The
reviewer is **acknowledged**, not credited as an author.

---

> ⚠ **Corrected in part, 2026-09-01 — see item 7 of the 2026-09-01 `rev_V2-F14` entry at the foot of this file.**
> The sentence below stating that the shipped `sat.py` **has no target for this pair** was **false when
> it was committed**. `python3 sat.py --emit-cnf five-sub-gender+ccn4 out.cnf` builds the pair on the
> unmodified shipped file (`vars=7035 clauses=243175`, 0.74 s); `ccn4` is Schulz S25-28 (`sat.py:78`)
> and the generic handler is `sat.py:612-615`, landed in `36a78482` on **2026-07-04**, eight weeks
> before this entry. The entry's own scratch-copy counts four lines below are byte-for-byte what the
> shipped file emits. The fourth minimal core, its certificates and the control run are unaffected,
> and the entry's other explanation — that prior reviews checked the three named pairs instead of
> enumerating the lattice — is correct and is the real one. The original wording is preserved: this
> ledger is append-only.

## 2026-08-28 — "three minimal two-rule cores" was an undercount: there are four

`TR2_THE_RULES_CONFLICT.md:305` stated that the five-rule conflict *"decomposes into **three**
minimal two-rule cores"* and listed {Moore parity, Schulz S25–28}, {Moore rhythm, Schulz S25–28} and
{Schulz gender, CC-N8}.

**There is a fourth: {Schulz gender, Schulz S25–28}.** It is unsatisfiable, and each of its two rules
is satisfiable alone, which is what makes it minimal rather than merely conflicting.

**How it was found, and why it took this long.** Every prior review of this claim read it. The
statement is about what a solver decides, so reading it can neither confirm nor refute it — and the
shipped `sat.py` has no target for this pair, so the claim's own tooling could not test it. It was
found by a review that **enumerated the whole conflict lattice** (10 pairs, 5 singletons, the
core-free triples) instead of checking the three pairs the sentence names. A claim of
*completeness* — "the conflict decomposes into three" — is a claim about everything **not** listed,
and it can only be checked by generating the unlisted cases.

**Independently re-derived before this correction was written.** The CNF was rebuilt from scratch in
a scratch copy of `sat.py` (7,035 variables / 243,175 clauses), solved with kissat
(`s UNSATISFIABLE`), and its proof replayed with drat-trim (`s VERIFIED`) — a separate chain from the
archived certificate. A **control** was run in the same harness ({Moore parity, Moore rhythm} →
`s SATISFIABLE`), because a checker that can only return UNSAT would have "confirmed" this result
regardless of the truth. Both singletons were also checked satisfiable.

**The theorem is unaffected and is if anything strengthened.** The five-rule union is still
unconditionally unsatisfiable; an additional minimal core makes the conflict tighter, not weaker.
What was wrong is the **anatomy**, and specifically a completeness count we published without having
enumerated the space it quantified over.

**Attribution.** Codex **L01** asserted textually that the core list might be incomplete; it did not
identify a pair. A Fable execution lens ran the census and found it. Both are **acknowledged**, not
credited as authors.

---

## 2026-08-28 — two stale front-page statements: the Wilhelm "(hexagram names)" annotation, and a test count frozen at 67

**What was wrong, and where.**

1. `README.md` §References annotated the Wilhelm/Baynes citation "(hexagram names)". That was true
   until 2026-08-27, when the copyrighted Wilhelm/Baynes English titles were removed from this
   repository (see the CRITIQUE.md note of that date) and hexagram labels became trigram-derived.
   The 2026-08-27 removal pass fixed the attribution claims in `CRITIQUE.md`, `SOLVE.md` and
   `example/hexagrams.json` but missed this sibling site: the front page kept citing Wilhelm **as
   the source of hexagram names this repository no longer ships** — the same
   removed-the-data-kept-the-attribution defect the pass existed to cure. The annotation now states
   what is true: the names were shipped until 2026-08-27, then removed rather than replaced.

2. The "Check it yourself" block of the top-level `README.md` said the regression harness "has since grown to 67" tests. The
   harness has 76 (`python3 tests.py`, run 2026-08-28: "Ran 76 tests… OK", agreeing with the
   count already stated in this same README's Quick start). The sentence now pins the count to its
   measurement date instead of asserting a present-tense figure that drifts.

**Why it matters.** (1) is a provenance statement about copyrighted material — precisely the kind
of claim a licensing reviewer checks first — and it was false on the front page while true
everywhere the earlier fix reached. (2) is small, but the README contradicted itself (67 vs 76) in
a corpus whose doc gates exist to catch exactly this class; neither figure was registered anywhere
a gate reads.

**Attribution.** Found by a Fable review lens (D2, sinologist/archivist pass, 2026-08-28), which
re-verified the harness count by execution and the Wilhelm claim against the shipped tree.

---

> ⚠ **Corrected in part, 2026-09-01 — see item 3 of the 2026-09-01 entry at the foot of this file.**
> The candidate bar's **sidedness was never frozen**: the pinned freeze
> (`git show 2d19a3f:documentation/CRITIQUE.md`, line 388; `documentation/CRITIQUE.md:571` at HEAD)
> attaches "two-sided" to the *notable* bar only and does not contain the < 10⁻⁴ figure at all, as
> TR-10's own abstract now records. `rotinv`'s demotion is correct under the two-sided convention
> **adopted uniformly on 2026-08-28**, not by preregistration, so "by our own declared rule" overstates
> it. And "Rows 1–2 … duly report two-sided values" is false for row 2, which reports only
> P(≥1) = 1.12×10⁻². Row 7's NULL, the tally and the non-promotion are unaffected. The original wording
> is preserved: this ledger is append-only.

## 2026-08-28 — two published verdicts in TR-10 were computed against the wrong tail, by our own declared rule

`TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md` §3 freezes its thresholds in advance: *"'notable' = **two-sided**
p < 0.05/9 (5.56×10⁻³); 'candidate rule' = < 10⁻⁴."* Rows 1–2 of the scoreboard duly report two-sided
values. **Rows 6 and 7 did not** — they published the one-sided upper tail and then compared it to the
two-sided bar.

| row | one-sided (published) | two-sided (declared basis) | bar | was | is |
|---|---|---|---|---|---|
| 6 `rotinv` | 6.531×10⁻⁵ | **1.306×10⁻⁴** | candidate < 10⁻⁴ | "meets candidate-rule numerically" | **does not meet it** |
| 7 `pureplace` | 5.56152×10⁻³ | **1.112×10⁻²** | notable < 5.5556×10⁻³ | "borderline (at the threshold to reported precision)" | **NULL** |

Both recomputed from the committed evidence file `reports/evidence/dav_tier1.out`
(`rotinv at=0.00006531 above=0.00000000`; `pureplace at=0.00556152 above=0.00000000`), where the upper
tail is `at + above`.

**`pureplace` was never borderline under either reading.** Its one-sided value **already exceeds**
0.05/9 before any doubling — 5.56152×10⁻³ > 5.55556×10⁻³. The published word "borderline" came from
comparing rounded values ("5.56×10⁻³" against "5.56×10⁻³"); at full precision it fails.

**The tally moves with it:** nine pre-registered composites are now **five null, one notable, three
data-like** — corrected in TR-10's abstract, TR-10 §"What is claimed", and `CITATIONS.md`.

**What is NOT affected, and why.** METHODS and TR-8 use `dav_rotinv` as a **BH ranking anchor** — the
argument needs it to be *strictly smaller* than `dav_trigarray`, not to clear an absolute bar.
**Doubling is order-preserving**, so the rank-ordering and every conclusion resting on it stand
unchanged. Only absolute-bar verdicts move. Both rows retain the one-sided figure alongside the
two-sided one precisely so those downstream citations remain traceable.

**Nothing promoted before or after.** `rotinv` was already classified data-like and non-promoting;
what was wrong was the accompanying claim that it cleared the candidate bar. No constraint entered or
left the system.

**Attribution.** Raised by Codex target **T10** in the max-run cohort; the recomputation, the
one-sided/two-sided diagnosis, the tally propagation and the order-preservation argument were derived
here. Codex is **acknowledged**, not credited as an author.

---

## 2026-08-28 — the withdrawal markers were attached to the wrong words, and on the front page to the wrong figure

The 2026-08-24 withdrawal of the ≈3.3×10³⁷ orientation-deduped figure was applied by appending the
marker to the **end of a physical source line**. Markdown joins consecutive lines into one paragraph,
so in the rendered page several markers landed mid-sentence, away from the figure they withdraw.

**The front page was the damaging case.** `README.md` rendered as:

> …≈3.3×10³⁷ after orientation-dedup…; adding ⚠ **[WITHDRAWN 2026-08-24 …]** C6–C7 still leaves ~5×10³¹.

A reader saw the withdrawal attached to **"adding C6–C7 still leaves ~5×10³¹"** — a figure that is
**not** withdrawn — while the actually-withdrawn ≈3.3×10³⁷ stood a few words earlier as ordinary live
prose. The marker is now adjacent to the figure it withdraws, and the "adding C6–C7…" clause is
contiguous again.

Three further sites in `BRANCHES_EXPLAINED.md` placed the marker inside the phrase *"an exploration
estimate, not a **proven count**"*, so it read as qualifying "proven count" rather than the estimate;
one of those was not prose at all but a **stray extra table cell** past the row's final pipe. All are
relocated onto the figure. Two remaining sites (`SOLVE_SUMMARY.md`, `HISTORY.md`) already sit adjacent
to the correct figure and are left as they are; the `HISTORY.md` instance is changelog text, which is
a record and not re-edited.

**Why no gate caught it.** GATE 27 requires that a line stating a registered withdrawn figure carry a
supersession marker. Every one of these lines did — the marker was on the same *physical* line.
**The gate is line-scoped and cannot see rendered position**, so a marker attached to the wrong clause
satisfies it exactly as well as one attached to the right clause. No figure or verdict changes here;
what changes is which words the withdrawal visibly governs.

**Attribution.** Found by a Fable archivist lens reviewing the rendered output rather than the source.
Acknowledged, not credited as an author.

---

## 2026-08-28 — the newcomer's entry point said the rules were "never written down"; our own methodology says otherwise

`GUIDE.md` — the first page a newcomer reads — stated: *"It appears to follow rules, but those rules
were never written down."*

**This repository's own methodology contradicts that sentence.** `reports/METHODS.md:25` cites the
**Xugua** (序卦傳), one of the Ten Wings, as the **"definitional and classically attested"** basis for
C4's orientation — "the Xugua opens Heaven-then-Earth" — and **14 files** in this repository reference
the Xugua or 序卦. A written classical account of hexagram succession exists, and we rely on it.

**The true statement is narrower and more interesting**, and the page now makes it: *no surviving
source states the rules as a **construction**.* The Xugua supplies a **semantic and moral succession**,
not a computable algorithm. That is the actual gap this project works in — and it is a better framing
than the one it replaces, because "never written down" invites the reader to think nothing classical
addresses the ordering at all.

**Worth recording about how it was found.** This is not a code defect, and **no gate could have caught
it** — it is a conflict between a plain-language sentence and a citation four documents away. It was
raised by exactly **one reviewer out of thirty-five** (a historian-of-ideas lens). The lesson is not
that we need another gate; it is that a certain class of defect is only reachable by a reader who
knows the classical corpus, and that class is worth buying deliberately rather than hoping for.

**Attribution.** Raised by Codex **L09** in the max-run cohort; the corpus check (14 files, the
METHODS C4 attestation) and the replacement wording were derived here. Codex is **acknowledged**, not
credited as an author.

---

## 2026-08-28 — two shipped-identity errors: a false reproducibility contrast, and a ratio computed against the wrong object

**(A) `solutions.sha256` is not byte-reproducible either.** `SOLUTIONS_FORMAT.md` stated: *"The
sidecar contains timestamp and git hash, so it is NOT byte-reproducible across runs — deliberately.
The canonical artifacts (`solutions.bin` and `solutions.sha256`) are."*

`solve.c` writes a `# Date:` line into `solutions.sha256` on **every run**. Only its **first line —
the bare digest — is an identity**. The sentence drew an explicit contrast with the sidecar on
*precisely the property the two files share*, which is worse than simply omitting it: a reader
checking `solutions.sha256` byte-for-byte across two runs would find a difference the document told
them could not happen.

**Rider, corrected with it.** The same file called `sha256(solutions.bin)` *"a pure function … and
reproducible across runs, machines, and years"* **unconditionally**, while `DEVELOPMENT.md` concedes
different hosts may produce different canonical shas, TR-3 records an actual host-level drift event,
and `CANONICAL_HASHES.md` labels the 100B anchors build-recipe specific. The claim is now scoped to
the tested toolchain class, with those three pointers, because the scope is not decoration.

**(B) A published ratio was computed against the wrong object.** On the full-31
`--f1-exact-c1c2c4c5` path, `solve.c` printed `vs estimator 1.3287e38 (+/-0.02%): ratio = …`,
dividing the **C3-free** exact |C1∩C2∩C4∩C5| = 1.097051×10³⁹ by the **C3-inclusive** |C1–C5|
flagship estimate 1.3287×10³⁸. Those are different objects, and the printed value was **8.256574**
where [TR-11](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §9 publishes **0.999956**
against the C3-free estimate 1.0971×10³⁹. Now compared against the same object.

**`verify.c` pairs its own object correctly**, which is what makes this an error rather than a
convention. Both values were recomputed here before the fix: 1.097051×10³⁹ ÷ 1.0971×10³⁹ = 0.999955,
and ÷ 1.3287×10³⁸ = 8.256574 — matching the wrong figure the binary printed.

**Provenance, checked before filing.** (B) is an **in-house** finding from the 2026-08-22
solve-c-counting sweep. It was recorded in three internal documents, **zero fixes were applied, and
no backlog row was ever filed** — a grep for "8.256" and "vs estimator" in the backlog returned
nothing. Codex **R16** corroborated it six days later. Credit is in-house; Codex is
**acknowledged** for the corroboration, not credited as an author.

---

## 2026-08-28 — "the smallest measured margins" was refuted by our own evidence file

Six published sites stated that King Wen keeps one of the four literature rules exactly and misses
the other three **by the smallest / minimal measured margins (2 each)** — `README.md`,
`TR2_THE_RULES_CONFLICT.md` (three sites), `TR1_EIGHT_CENTURIES_MEASURED.md`, and
`SOLVE_SUMMARY.md`.

**TR-2's own evidence file contradicts the superlative.** `reports/evidence/f11/f11_runA.out`
contains:

```
f11_hist 1 1 0   4.1291082539e-09
f11_hist 2 1 1   2.9255247935e-08
```

against King Wen's `f11_hist 2 2 2`. On the axes (Moore-2005 parity violations, Moore-1989 rhythm
breaks, Schulz-1990 gender violations), **both cells are componentwise ≤ King Wen with strict
improvement, and both carry nonzero measured mass.** Orderings that do better exist, and we measured
them ourselves.

**The honest verdict is UNSUPPORTED, not false — and the distinction matters.** That histogram is
**not CC-N4-conditioned**, so an ordering sitting at `(1,1,0)` may well fail the fourth rule. No
CC-N4-conditioned extremal check exists anywhere in the corpus. So the claim is not refuted outright;
it is a superlative that **was never established**, and the sites now say what is measured — two
each — without asserting minimality.

**The surrounding argument is unaffected.** The four rules remain jointly unsatisfiable (UNSAT with
an independently verified certificate), King Wen still keeps the trigram configuration exactly, and
the anomalies are still a forced trade-off rather than damage to a once-perfect original. What is
withdrawn is only the claim that its margins are the *smallest possible*.

**The finding named five sites; there are six.** `reports/README.md:42` carries the "forced
trade-off" language but not the margins claim, while `TR1:242` and `TR2:287` carry it and were not
listed. A sweep for the phrasing variants found them; the two changelog occurrences are left as
historical record.

**Attribution.** Raised by Codex **T01** in the max-run cohort; the evidence-file check, the
CC-N4 narrowing and the site sweep were derived here. Codex is **acknowledged**, not credited as an
author.

---

## 2026-08-28 — two rule descriptions contradicted by our own code, one of them by measurement

**(A) "each reproducing its source's stated King Wen values" was true of 27 of 31, not all 31.**
`LITERATURE_RULES_POPULATION_TESTS.md` described the registry that way, while `solve.py`'s own comment
directly above `REGISTRY_KW_EXPECTED` says the opposite for four of them: *"MM-T3=4, MM-T6=0, C1=24
and the C2 histogram are **KW-measured anchors** (registry states only qualitative/percentile
expectations for those)."* Two of the four carry further disclaimers in their docstrings —
`reg_c1`: *"exact formulation pending full-paper access, registry proxy used … the registry gives the
percentile, not the raw score"*; `reg_c2`: *"exact asymmetry metric pending full-paper access.
Deterministic proxy."* Counted here: **31 entries, 4 anchors, so 27**.

For four rules we are checking against **our own measurement of King Wen**, not against a value the
source published. That is a materially weaker form of verification, and the sentence claimed the
stronger one for all 31.

**(B) "confined to S25/26" was measurably false for one of the two rules.** `LRPT:189` and
`TR1:153` published the meta-rule `ccn8` as *"both Schulz rules' violations **confined** to S25/26."*
Measured on King Wen here:

```
CC-A2 violations : [25, 26]                    -> confined
R-S2  violations : [11, 13, 14, 25, 26, 32]    -> NOT confined
```

**The code was right and said so.** `reg_ccn8`'s predicate is `set(v_a2) == {25,26}` **and**
`{25,26} <= v_s2` — CC-A2's set must be *exactly* {25,26}, while R-S2 need only *contain* it — and its
docstring already used the correct word: the two sets **"share the locus {S25, S26}."** The published
prose upgraded *share* to *confined*. Both sites now say "sharing the locus".

**The population figure is unaffected.** `reg_ccn8(KW)` still returns `True`, and the 2.6×10⁻⁷ figure
comes from the correct predicate. What was wrong was only the English description of it.

**Attribution.** Raised by Codex **R11** in the max-run cohort; the measurement, the registry count
(31 − 4 = 27) and the docstring comparison were derived here. Codex is **acknowledged**, not credited
as an author.

---

## 2026-08-28 — a published figure carried an uncertainty that was not one, and a provenance that did not contain it

The joint-strict population size was published at four sites as **≈1.13×10²⁹ ±4.7%**.

**The ±4.7% is not an error bar.** It is a **preregistered anchor tolerance band**:
`reports/evidence/f11/compute_f11_bf.py:85` names its check *"Moore-joint size outside the +/-4.7%
anchor band"*, and `reports/evidence/f11/RESULTS.md:93` uses it as a pass/fail window — *"+3.5% vs
the 1.1266e29 anchor (inside ±4.7%)"*. It says how far the measurement was allowed to fall from a
pre-registered anchor before the check failed. It says nothing about the estimator's precision.

Standing beside sibling figures that carry genuine confidence intervals, it read as one. The
estimator's own numbers are different and were available all along: relerr **2.98%** at 5×10⁹ probes
and **1.66%** at 2×10¹⁰; 95% half-widths **5.84%** and **3.26%**. **4.7 is none of them.**

**And the archived instance named was the wrong file.** `TR1:473` pointed at
`reports/evidence/f11/f11_runB.out`, which reports **`est=1.165830e+29`** — not the published
1.13×10²⁹. The published value matches
`reports/evidence/r11/r11_moore_strict.out`: **`est=1.131036e+29`, 95%CI [1.0942e+29, 1.1679e+29],
relerr 1.66%**. `SOLVE_C_CLI.md` compounded it by citing "F11 runs B/C", which give 1.16583e29 and
1.091306e29 — **neither is the published figure**.

All four sites now carry the **real** 95% CI and point at the file the number actually came from.

**The estimate itself is unchanged and was never wrong** — 1.13×10²⁹ is what the r11 walk measured.
What was wrong was the uncertainty attached to it and the pointer offered for checking it, which is
the part a reader would use to audit us.

**Attribution.** Raised by Codex **T01** in the max-run cohort; the anchor-band identification, the
file-by-file estimate reconciliation and the CI substitution were derived here. Codex is
**acknowledged**, not credited as an author.

---

## 2026-08-29 — TR-6's "three fully independent ways" was two, plus a corroboration

`TR6_PARITY_SKELETON.md` published the 15-alternation theorem as proved *"three fully independent
ways"* — prose, Lean, and a SAT decision — adding that **"any one of the three would suffice."**

**The SAT leg is not independent of the prose leg.** TR-6 itself names the prose proof's core as
*"three lemmas + **the C5 odd-distance count**"* — and that count is `2(d=1) + 13(d=3) = 15`, read
straight out of `BETWEEN_MULTISET`. The SAT targets ask whether ≤14 or ≥16 alternations are possible,
and **both are refuted by C5's cardinality clauses alone**: the ordering-variable-free clause subset
of each CNF is UNSAT on its own (kissat rc=20, fresh DRAT `s VERIFIED`). The solver re-runs the prose
proof's arithmetic; it does not reach the ordering structure.

**It also assumes the step that carries the content.** The theorem is about *parity-class
alternations*; the encoding defines its `odd` variable as *odd Hamming distance*. The equivalence
between those is the mathematical substance — and the encoding takes it as given rather than
establishing it.

**The Lean leg is genuinely independent and is unaffected.** `lean/KingWen.lean`'s
`alternations_15_general` takes `c5ok l = true` as a *hypothesis* and derives the count by structural
induction over the transition list — it proves the bridge the SAT encoding assumes. Verified by
reading the proof rather than the README.

**The theorem is true and nothing about it changes.** Exactly 15 alternations stands, the DRAT
certificates verify, and prose and Lean each remain sufficient alone. What is corrected is a claim
about **how many independent confirmations we have**: two, plus a mechanized corroboration of one
step. Under this project's own standing rule that independence means *derivation* independence, the
original wording overstated the evidence.

A stronger SAT target — one posing the alternation predicate directly, without the odd-distance
shortcut, so any refutation must traverse the ordering variables and the parity facts — would make
this leg genuinely independent. That is recorded as follow-up work, not claimed here.

**Attribution.** Raised by Codex **T06** in the max-run cohort (and reached first by the effort-none
run); the clause-subset extraction, the Lean-leg check and the replacement wording were derived here.
Codex is **acknowledged**, not credited as an author.

---

## 2026-08-29 — TR-10 now carries standard errors, and one clause in yesterday's own correction was knife-edge

**Addition.** TR-10 §3 now states that the masses are weighted-sample estimates carrying a
delta-method standard error (`se=`, printed by the estimator since 2026-08-28), and adopts an explicit
rule: **a verdict whose 95% CI straddles its bar is labelled "unresolved at N probes", not
classified.** Carrying the errors through changes **no** published classification. Only `rotinv`
approaches the straddle condition — its two-sided p exceeds the 10⁻⁴ candidate bar by **≈2.3 SE**, so
its CI clears the bar only marginally, and that is now said out loud rather than left for a reader to
discover.

**Correction to a correction.** The 2026-08-28 entry above (the two mis-tailed TR-10 verdicts)
supported `pureplace`'s NULL with the observation that its **one-sided** value already exceeds 0.05/9
before doubling. That observation is true of the printed estimate but the margin is **≈0.1 SE** — a
coin flip once the uncertainty is carried. It is retained as an observation and explicitly **not
relied on**; the NULL rests on the two-sided reading, which is **≈45 SE** clear of the bar.

Recording this matters more than the arithmetic: a supporting clause that looks decisive and is
statistically empty is exactly the kind of thing that hardens into a load-bearing claim if nobody
marks it. The verdict does not change.

**Attribution.** The standard-error implementation and the straddle-rule wording came from the C2
review lens; the knife-edge measurement is its finding about work done here the same day.
Acknowledged, not credited as an author.

---

> ⚠ **Corrected in part, 2026-09-01 — see item 4 of the 2026-09-01 entry at the foot of this file.**
> The rewording below is right and stands; its supporting taxonomy over-corrected. **C4's pair choice
> is classical too** (`documentation/CITATIONS.md:58-71`: "classical fact, encoded as C4; not novel to
> ROAE") — what is ours in C4 is the *orientation* (`reports/METHODS.md:24-33`, narrowed 2026-08-30).
> And the count below is wrong by its own sentence: it attributes C2 to McKenna 1975, so **two** of the
> five, not three, are ours. The original wording is preserved: this ledger is append-only.

## 2026-08-29 — "the classical constraints" borrowed an authority three of the five do not have

TR-10 twice described the conditioning set as *"orderings satisfying **the classical constraints**"*.
The conditioning set is **C1–C5**, and only **C1** is classical — Kong Yingda's formulation, which
`CITATIONS.md` is careful to scope that way and nowhere else. **C2** is McKenna 1975. **C3** is this
project's own KW-fitted threshold. **C5** is an extracted transition histogram.

So the phrase lent eighth-century authority to a modern rule, a fitted threshold and a histogram we
extracted ourselves. Both sites now read **"the C1–C5 constraints"**.

**Nothing measured changes** — the conditioning set was always C1–C5 in the code, and every number in
those two paragraphs stands. What changes is the provenance the prose claimed for it, which matters
precisely because this report's argument is about *what the population makes ordinary*: a reader who
believes the population is defined by classical rules draws a different conclusion about design intent
than one who knows three of the five are ours.

These were the **only two occurrences repo-wide**, verified by grep before and after.

**Attribution.** Raised by Codex **L03** and echoed by **L09** in the effort-none cohort; the
provenance check against CITATIONS.md's scoping was derived here. Codex is **acknowledged**, not
credited as an author.

---

## 2026-08-29 — the prior-art adjudication is published, and three published statements move with it

The annotated bibliography for the 2026-08 prior-art acquisition round landed in
`CITATIONS.md` (§"The 2026-08 prior-art acquisition round", plus new entries in the algebra,
Shen Youding, and Li Shangxin sections). Every edit in the batch is a **cession or a credit** —
recording what others did, or did first — and no published number changes. Three previously
published statements change meaning:

1. **"Fifth independent arrival" → "seventh."** The (Z/2)⁶-algebra lineage in `CITATIONS.md`
   counted ROAE the fifth independent arrival. Two further arrivals, read first-hand in August,
   join the chain: 袁作兴 (1991) and 曹红军·厉树忠·刘亚楠 (1995). Neither displaces 欧阳维诚 as
   earliest (his 1990 卦序探原, in our collection, already states the group with a nested
   subgroup chain — a passage an earlier pass missed); neither cites him, so their independence
   is plausible but unprovable. The count grew because the reading got more complete, not
   because anything was previously wrong about the four arrivals then known.

2. **The Shao Yong candidate cession is confirmed and applied.** Since 2026-08-21 the 8+28=36
   reversal-figure *count* carried a "second-hand, unconfirmed" candidate attribution to 邵雍
   (11th c.), with instructions not to move the attribution until the locus was read directly.
   The 觀物外篇 locus has now been read first-hand from the 四庫 woodblock scan (twice,
   2026-08-26/27): the count is his, stated at both levels (4+2=6→8 trigrams; 8+28=36→64
   hexagrams), and the entry, the candidate paragraph, TR-1 §6, and
   LITERATURE_RULES_POPULATION_TESTS.md now say so. The 36-figure *condensation of the received
   text* remains with 胡一桂 → 來知德, and the joint two-operation decomposition remains with
   朱元昇/吳澄 — the widened cession displaces neither.

3. **"No direct assertor known" → "closest direct assertor: Li Shangxin 2007."**
   `CLAIMS_DECIDED.md`'s uniqueness-conjecture row and the CITATIONS attribution note previously
   said no author asserted constraint-determinism of the sequence directly. That sentence
   survives literally for the C1–C7 inventory, but the first-hand read of Li Shangxin's 2007
   thesis found the sharpest instance: he makes unique determination of position the criterion a
   construction-rule system must meet and asserts his own system met it (jointly with his
   meaning-system, hedged to "most" hexagrams, and qualified by himself in 2019). The note was
   upgraded under its own standing invitation.

Alongside these, the two public scoping paragraphs (the Wu Cheng entry and
KING_WEN_PROVENANCE.md) that deliberately narrowed "nothing here counts ORDERINGS" to five named
classical authors — because the adjudication was unpublished — now point to the published
entries instead, with an explicit caution that the sentence must **not** be widened into "no one
counts orderings": the published entries themselves record closed-form counts of
simply-constrained ordering spaces (黄石声 1997, transmitting 沈宜甲/董光璧; 陳壯維 2007), and
TR-11's prior-art chain at the counting-question credit was extended accordingly (v1.21).

---

> ⚠ **Corrected in part, 2026-09-01 — see item 2 of the 2026-09-01 entry at the foot of this file.**
> "Both documents now state the operative rule" was premature. At the reconciling commit `cbf818c4`
> three later blocks of `CLAUDE.md` §Cost control still commanded the blanket rule the paragraph above
> them had withdrawn; they were fixed the next day in `0e4fe585` (2026-08-30). A fourth site,
> `CLAUDE.md:396` in §"Bi-region architecture", still commands Spot for all workloads including merge
> and is live as this note is written. The original wording is preserved: this ledger is
> append-only.

> ⚠ **Corrected in part, 2026-09-01 — see item 1 of the 2026-09-01 `rev_V2-F14` entry at the foot of this file.**
> The measurement paragraph below is the entry's evidential basis and **its arithmetic does not
> close**: five `Regular` plus one Spot is six of the seven VMs it counts, leaving one unaccounted
> for. No VM list from 2026-08-29 survives in either repository, so the seventh is not recoverable;
> the supported statement is that **at least** five of seven were `Regular`, one was Spot, and the
> seventh's priority is unrecorded. Separately, "has never followed" is a claim about the whole
> campaign history drawn from a single day's snapshot — the supported form is **"did not follow it on
> the date measured (2026-08-29)"**. The policy conclusion is unaffected. The original wording is
> preserved: this ledger is append-only.

## 2026-08-29 — two public documents gave contradictory VM policies, and the one claiming priority was the one practice ignored

`CLAUDE.md` stated: *"All VMs other than the … orchestrator MUST be Spot priority. No exceptions for
merge VMs …"*, adding that this **supersedes** the 2026-04-20 split policy. `DEPLOYMENT.md` still
presented that same split policy — *"Enumeration → spot … Merge → on-demand … (not spot) because merge
is fragile under eviction"* — as **STANDING**, with no supersession note anywhere.

So a reader following one document provisioned differently from a reader following the other, and
neither said which to obey.

**Measured on the live subscription before deciding:** of the seven non-orchestrator VMs, **five are
`Regular`**. Only the enumeration VM is Spot. **Practice has never followed the blanket rule** — it
follows the split policy the blanket rule claimed to replace.

Both documents now state the operative rule: **enumeration → Spot; merge and any workload that cannot
checkpoint → Regular/Standard, right-sized; the orchestrator stays Regular.**

**The cost concern behind the blanket rule was real but aimed at the wrong target**, and that is worth
keeping. What accumulated cost was *forgotten* VMs, not Regular *pricing*. The requirement is therefore
to **pair every VM create or start with a teardown plan in the same breath** and stand it down when the
job ends. Blanket-Spot only made the rule unfollowable, which is why it was not followed — and an
unfollowable rule is worse than none, because its existence suppresses the workable one.

**Attribution.** Raised by Codex **L21** in the effort-none cohort, which called it a textbook
document-control failure. The subscription measurement and the reconciliation were derived here. Codex
is **acknowledged**, not credited as an author.

---

> ⚠ **Corrected in part, 2026-09-01 — see item 6 of the 2026-09-01 entry at the foot of this file.**
> "wrong for **anything** produced since #169 … It **cannot match**" states a default as a universal.
> Under `SOLVE_COMPRESS=0` shards are written raw (`solve.c:1165`), the sidecar is framing-invariant,
> and the recipe below verifies OK at rc=0 — measured 2026-08-30. The era sets the default; the
> **container** decides. The entry's own replacement inherited the same flaw: `gzip -dc` on a raw shard
> hashes the empty stream and exits 0. The finding and GATE 28 stand; only the universal quantifier is
> withdrawn. The original wording is preserved: this ledger is append-only.

## 2026-08-29 — the published archive verification recipe FAILED on byte-correct artifacts

`DEPLOYMENT.md` published this as the verification recipe for every archived shard:

    sha256sum -c sub_<branch>.sha256

That command is wrong for anything produced since **#169** (`d8671550`, 2026-06-17), and had been
wrong for two months. Two facts have to be held together to see it:

1. The `.sha256` sidecar holds the **logical (decompressed)** sha. `write_sha256_with_metadata()`
   calls `sha256_of_logical()`, which sniffs the gzip magic and hashes the *decompressed* stream —
   deliberately, so the canonical sha is the same whether the file is stored gz or raw.
2. Since #169 shards are written **gz-framed by default**.

So `sha256sum -c` hashes the gzip **container** and compares it to the **logical** sha. It cannot
match. A reader following the published recipe on a perfectly good archive is told `FAILED`.

**Measured, not inferred.** A fresh `--sub-branch` run with the shipped binary, no environment
overrides, on 2026-08-29:

| | |
|---|---|
| on-disk magic | `1f 8b` (gz-framed, the default) |
| sidecar line 1 | `4cd43b2b389dde48a64b153b3cf611274e13fab013ac05f1ba64b11b532ef287` |
| `sha256sum solutions_1_0.bin` | `6e4d49b8a14813321f5f39220b0f3f32bfae80ad0709dedbac1664fd2fb3a2f2` |
| `gzip -dc solutions_1_0.bin \| sha256sum` | `4cd43b2b…` — **exact match** |
| `sha256sum -c solutions_1_0.sha256` | `FAILED`, rc=1 |

**This is the expensive direction.** A false mismatch on a good artifact is phantom drift, and this
project has already spent about six hours on one of those (the 2026-05-31 11.2T incident). The recipe
manufactured that alarm on demand.

**The class had already been fixed almost everywhere else, and this is the third instance of that
pattern in this wave.** `SOLUTIONS_FORMAT.md`, `CANONICAL_HASHES.md`, `CAMPAIGN_METHODOLOGY.md`,
`DEVELOPMENT.md`, `REBUILD_FROM_SPEC.md`, TR-3 and the 100T run README all already carry the logical-vs-container
note — the 100T README even spells out the era exception in a comment. `DEPLOYMENT.md` and the
2026-04-22 pass-A run README were the two that were missed, and they are precisely the two that ship
the command as an **executable recipe** rather than as a remark.

**Fixed.** `DEPLOYMENT.md` now gives `gzip -dc sub_<branch>.bin | sha256sum` compared against line 1
of the sidecar, and states the era exception explicitly. The pass-A README keeps `sha256sum -c`,
because that run **predates #169** and its shards really are raw — confirmed from the sidecars' own
arithmetic, `525,815,456 = 16,431,733 × 32` and `525,864,544 = 16,433,267 × 32`, exact, with no
framing overhead (all 16 archived shards across the 2026-04-22 and 2026-04-23 runs check out this
way) — and it now says so, and says not to carry the recipe forward.

**Four comments in `solve.c` also overstated what they promised.** They said the sidecar's first line
is *"compatible with `sha256sum -c`"*. That is true of the line's **format** and false of its
**verification**, and DEPLOYMENT.md's recipe was written on the strength of it. They now say format
only, and name the command that does verify.

**Gated.** `doc_gates.sh framing-era` (GATE 28) requires every published `sha256sum -c` recipe to
state which framing era it assumes. It derives its population from the corpus rather than from the
fix's wording, and it **errors rather than passes** if the population collapses — a verifier must be
false when its target is absent. Shown able to fail three ways: on a planted unqualified recipe in a
third file, on the real pre-fix corpus (where it independently rediscovered both defect sites and
nothing else), and on a single-site deletion.

**Attribution.** Raised by the Fable D2 outsider-read lens (section A4), which executed the recipe
instead of reading it. The sibling sweep, the era arithmetic and the gate were derived here.

Canonical selftest sha unchanged: `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e`.

---

> ⚠ **Corrected in part, 2026-09-01 — see item 5 of the 2026-09-01 `rev_V2-F14` entry at the foot of this file.**
> "The 2026-08-28 entry above removed `d2-10T` from a documented scale list" points at nothing:
> `d2-10T` occurs in this file only at `:2425-2471`, all of it inside **this** entry, and no earlier
> 2026-08-28 entry names the scale or the list. The pointer should be a self-reference. The finding,
> the byte-identical-message diagnosis and the distinguishability gate are unaffected. The original
> wording is preserved: this ledger is append-only.

## 2026-08-29 — a real scale and a typo got the same answer from the pre-flight gate

`solve --validate-launcher-config d2-10T <any PSB>` printed
`ERROR: unknown scale 'd2-10T'` and returned 25 — **byte-identical message and exit code to
`d2-10Q`, which is nothing at all.** `d2-10T` is a genuine entry in `CANONICAL_RECIPES`, and
`solve --canonical-config d2-10T` resolved it cleanly (rc=0) at the same moment. Two subcommands
reading the same table disagreed about whether the scale existed, and the shared `known scales:`
usage line — a hand-maintained literal in three places — sided with the one that said yes.

**Why it mattered more than a wording bug.** This is a *pre-flight* gate: launchers call it before
provisioning to catch a PSB typo before compute is spent. A caller that runs it and does not inspect
the exit code sees an error about a scale that is real, and a caller that does inspect it aborts a
valid launch. Either way the gate **fails open** on the one input it was least able to judge.

**Root cause.** The lookup loop required `r->psb > 0`, so a known label with `psb == 0` — meaning
"this scale publishes no per-sub-branch budget", which is exactly right for depth-2 mechanics — fell
through the loop and landed on the unknown-scale error at the bottom. Absence of a budget was
indistinguishable from absence of a scale.

**Fixed.** Three outcomes are now distinct:

| input | result |
|---|---|
| known scale, PSB matches | `0` |
| known scale, PSB differs | `1`, with the diff |
| **known scale, no published PSB** | **`34`**, saying so and pointing at `--canonical-config` |
| genuine typo | `25`, listing the PSB-bearing scales |

The `known scales:` lines are now **generated from the recipe table** rather than hand-maintained,
so a usage line can no longer advertise something the table does not hold — which is the drift that
produced this. `--canonical-config` additionally explains why `d2-10T` emits no PSB line.

**That explanation goes to stderr, and the reason is measured rather than stylistic.** The documented
consumer is `eval $(./solve --canonical-config 100T)`. Unquoted command substitution word-splits, so
`eval` sees a single line, and a `#` comment printed on *stdout* would comment out every variable
after it. Confirmed: with the note on stdout under `--full`, `SOLVE_DFS_ITERATIVE` and
`SOLVE_DFS_CHECKPOINT` both come back unset. A note meant to prevent confusion would have silently
dropped two sha-determining variables.

**Relation to the earlier correction.** The 2026-08-28 entry above removed `d2-10T` from a documented
scale list. That treated the symptom, and its first wording additionally implied the scale was not
real. It is real. The code beneath the documentation is what was wrong, and is now corrected.

**Gated** by `roae-private:scripts/canonical_scale_distinguishable_gate.sh`: every label in
`CANONICAL_RECIPES` must be distinguishable, by running the binary, from a nonexistent control
scale. It derives its population from the table text and its verdict from execution — it greps for
none of this fix's wording — errors rather than passes if the table parses to fewer than two labels
or if the control stops behaving like a control, and was red-tested against the real pre-fix binary,
where it named `d2-10T` and nothing else.

**Attribution.** Raised by the Fable D2 outsider-read lens (section A3), which ran both subcommands
instead of reading one. The root-cause analysis, the eval-safety measurement and the gate were
derived here.

Canonical selftest sha unchanged: `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e`.

---

## 2026-08-29 — the 1169 / 233 figures had no reproduction command, and the provenance note said they did

`SEARCH_SPACE_SIZE.md` and `TR4` publish `tree_nodes 1169 → 233` for the C6/C7 pinned check.
Neither document gave the command that produces them, and neither repository held it anywhere. What
made this worse than an omission is that `SEARCH_SPACE_SIZE.md`'s provenance note told the reader
the public verification path was *"re-running the **published** `SOLVE_KNUTH_C67` command in this
repository"*. **There was no published command.** The document asserted the check it did not supply.

**The cost is not hypothetical.** `--estimate-knuth 0` means *zero random probes* — exact
enumeration. It is bounded here only because a 22-pair prefix makes the subtree small. Issued
without that prefix, which a reader has no way to know, the same command is an unbounded full walk.
A reproduction attempt on 2026-08-29 was killed twice and concluded, wrongly, that no command
produced the figures at all.

**Published now, and all three reproduce in under 10 ms:**

| invocation (prefix `1 0 2 0 … 22 0`, `ulimit -s unlimited`) | tree_nodes | oriented leaves | canonical |
|---|--:|--:|--:|
| `SOLVE_KNUTH_C67=1` | **1169** | 88 | 8 |
| `+ SOLVE_KNUTH_PIN_SLOTS="24,…,31"` | **233** | 8 | 8 |
| `+ SOLVE_KNUTH_PIN_SLOTS="23,…,31"` | **75** | 8 | 8 |

**The slot labels were wrong in both directions, and the 2026-08-28 correction above did not fix
them.** `SOLVE_KNUTH_PIN_SLOTS` takes **step** numbers and accepts **1–31**
(`(knuth_pin_mask >> step) & 1u`), so a "slot 32" is not a value the flag can express — which is why
that correction's own author found slot 32 to be "a no-op". Steps are 0-based and
**position = step + 1**. After the 22-pair prefix the free steps are **23–31**, i.e. **positions
24–32**. The 233 run pins steps 24–31 = **positions 25–32**, so the slot left order-free is
**position 24**, not position 23.

**Nothing substantive moves.** Eight survivors in every variant, all carrying King Wen's pair
ordering. Only the run description and the labels were wrong — twice now, which is why this is
gated rather than merely corrected.

**Gated** by `scripts/knuth_c67_repro_gate.sh`, in two legs that answer different questions. Leg 1
asks whether a reader can check the figure: every document publishing 1169/233 must carry all four
elements of the invocation **inside one fenced code block**. That block scoping was itself measured
— a file-scoped first cut found only one of four tokens missing from the pre-fix documents, because
the rest occurred in scattered prose including the provenance sentence that named the variable while
promising a command it never gave. Leg 2 asks whether the figure is still true: it **runs** the
three commands and compares the binary's own output, so no doc edit can satisfy it. Shown able to
fail both ways — against the real pre-fix documents (neither contained a single fenced code block),
and against a deliberately perturbed binary, which printed 11990 instead of 1169 while leg 1 stayed
green.

**Attribution.** The wrong run description was found by the Fable D2 outsider-read lens (§A1), which
re-ran the check instead of reading it. The missing command, the step/position resolution and the
gate were derived here.

---

## 2026-08-29 — two reports were still giving instructions to their own author

`TR8_REORDERING_REVISITED.md` shipped a full technical-report masthead over a heading that read
**`Structure (4 sections)`** — above what are four **section summaries**, with no written-out §1–§4
beneath them. `reports/README.md` lists TR-8 as a peer of TR-1..TR-11 with an evidence column and no
draft marker anywhere, so a reader was invited to expect four sections that do not exist.

Worse, its Verification Guide addressed the **writer**, not the reader:

> *"but NOTE: section 2 **can be written** so that NOTHING depends on the estimator's absolute value"*
> *"**PREFER** the laptop-runnable framing throughout, with both nulls labeled."*

Three summary items carried the same planning voice — *"fair summary:"*, *"One paragraph of
historical respect:"*, *"Table of measured rule rarities for THREE rules only"*, *"Verifiability
box:"*.

**The class had already been fixed twice and left once.** TR-2 was relabelled for exactly this at
v1.13, and TR-3 was written out into prose. TR-8 was skipped.

**And the finding's own scope claim was wrong, which is why the sweep matters more than the fix.**
It recorded TR-8 as *the only* report still containing author-directive text. Checking the class
rather than the instance found **TR-2 items 2 and 4 still carrying** *"Method in one page:"*,
*"Verifiability box."* and *"One paragraph on the data-like character of the trigram rule,
honestly."* Milder there — v1.13's form note already tells the reader the list is an overview and
that §2–§4 are written out beneath it — but the same shape, and fixed in the same pass.

**Fixed.** TR-8's heading is now `Structure — section summaries (4)` with a form note stating what is
summary, what is written out, and **why §1 and §4 deliberately stay summaries** (humanities-register
prose about what named scholars proposed, where every added sentence is a further claim about a
person). Both author-directives are restated as facts about the report the reader is holding.
TR-2's three are converted to description. No measurement, theorem, certificate, figure or verdict
changed anywhere. (TR-8 v1.15, TR-2 v1.28.)

**Gated** as `doc_gates.sh author-directives` (GATE 29), in two legs: no report may address its own
author, and no `Structure (N sections)` heading may stand without saying the items are summaries.

**Two design points, both forced by measurement rather than chosen.** First, **the exemption is the
whole gate**: calibrating the patterns *before* writing it showed six of eleven candidates still
matched after the fix — because the revision rows that **record** the removal necessarily **quote**
the removed phrases. A naive gate would have fired on the correction that fixed the defect: the
tenth self-defeating-gate instance in a week, authored by the fix for a different one. Second, the
gate's own first run flagged `METHODS.md:105` — *"it can be written as 'positions/values match King
Wen's'"* — a **mathematical** can-be-expressed-as, not an instruction. The pattern is now anchored to
a document part (`section N can be written`), because a term that matches the topic is not the same
as a term that matches the shape being hunted.

**Closure could not be a population floor here, because zero live hits is the goal state.** Instead
the corrections are the fixture: if the pattern set stops matching even the revision rows that quote
these phrases verbatim, it has rotted and the gate ERRORs rather than passing. Shown able to fail
three ways — against the **real pre-fix reports** (it independently found all six live sites,
including the two TR-2 ones the finding said were not there), against the bare heading, and against
a blanked pattern list.

**Attribution.** Raised by the Codex effort-none run (target T08, corroborated by T03).

---

## 2026-08-29 — we cited a second edition our own copy says does not exist

`CITATIONS.md` carried **Schulz, L. J. (2016). *Hexagrammatics* (2nd ed.). Zizai.**

The PDF we hold says otherwise on its own title page: ***"First Edition: 2016"***, ISBN
978-1-365-06531-6. A search of Open Library returns **no record** for either that ISBN or the title,
so no second edition is confirmed to exist anywhere. The edition claim was unsupported and is
withdrawn. Year, publisher and content are unchanged, and the entry now carries the page count and
ISBN it should have had.

**How it was found, and why the finding is worth more than the fix.** It surfaced while adjudicating
the 夏世华 compilation (Q-356), where one question decided whether a purchase was justified: *is our
copy of `Hexagrammatics` complete, or an excerpt?* If it were an excerpt, the material the
compilation advertises and we cannot find might simply sit in the part we do not hold — "absent from
Schulz" and "absent from our copy" are very different claims and only one of them licenses spending.

**The copy is complete.** It runs title page → contents → body → an annotated bibliography of the
author's own works, with the last page footer reading *"Hexagrammatics 38"* inside a 42-page file.
That is a short monograph in full, not a fragment. Which is what makes the absence meaningful: the
fourth-layer treatment of 互体 that the compilation names **is not in this work**, rather than being
missing from our slice of it.

**Checking the edition is what checked the completeness.** The two questions had the same answer and
neither had been asked — the entry sat marked `[analyzed]`, which asserts engagement, while carrying
a bibliographic claim the artifact under it contradicts.

**Sibling sweep:** no other file in `documentation/` or `reports/` repeats the second-edition claim.

---

## 2026-09-01 — six entries in this ledger asserted a state the tree does not have

An adjudicated review of **this file's own entries**. Six of them assert something about the corpus,
the artifacts or the frozen record that does not hold when the assertion is checked: a reversed
inequality, two "now reads / both documents now state" claims that outran the tree, a
preregistration that was never frozen, an arithmetic "exactly" that is not exact, and a default
stated as a universal. Five of the six share one class — **a correction record asserting a tree
state, with nothing checking that the assertion survived the next edit.**

**Nothing below deletes or rewords an existing entry.** This ledger is append-only and gated as such
(`doc_gates.sh appendonly`, GATE 10a/10b): every corrected entry keeps its original wording and now
carries a dated pointer to the item here that corrects it. A reader must be able to see that the
record itself was wrong, which is the whole reason the append-only rule exists.

### 1. CX-11 — the inequality runs the other way, and the label the entry endorses was withdrawn the same day

**(a) "the same data shows a smaller gain at step 3" is backwards.** TR-4 lists the per-boundary
information gains for k = 1..8 as **10.38, 9.64, 11.10, 9.40, 10.13, 8.64, 7.93, …**
(`reports/TR4_SIZE_OF_THE_SPACE.md:253`). The step-3 gain, **11.10 bits, is LARGER** than the
step-1 gain of 10.38 that the withdrawn derivation used as its divisor — and that is exactly what
breaks the argument. The divisor was asserted to be the maximum single-boundary gain *by
construction*, which is true only of the first, unconditional gain; an observed conditional gain
that **exceeds** it demonstrates the divisor was not the supremum, so no bound follows. Had the
later gain genuinely been *smaller*, the divide-by-maximum floor would have survived. CX-11 gives as
its reason for withdrawal the one fact that would have saved the claim.

**(b) "The correct label is a *heuristic* floor" and "CLAIMS_DECIDED now reads 'heuristic floor
≥12'" are superseded — and were already superseded on the day CX-11 was written.** TR-4 v1.16, same
date, removed the word rather than re-qualifying it: *"The 'floor' label is removed, not
re-qualified — the argument bounds nothing"* (`reports/TR4_SIZE_OF_THE_SPACE.md:287`), and the body
says of the two labels *"It is neither"* (`:234`). At HEAD `documentation/CLAIMS_DECIDED.md:34`
reads *"an observed-rate extrapolation of ~12 boundaries — NOT a floor of any kind"*. The quoted
string is not in that file. `grep -rn "heuristic floor" --include=*.md .` returns three lines
corpus-wide and **none of them is a live label**: TR-4:258, recording that file's own 2026-08-09
correction of a pre-v1.16 survivor; CLAIMS_DECIDED.md:34, inside the sentence denying it; and CX-11
itself.

**The entry is also internally contradictory**: it endorses the heuristic label two lines after
recording that *"the decision taken was to delete the 'floor' label rather than qualify it a third
time"*.

**What stands.** CX-11's headline — the hard information-theoretic floor is **withdrawn**, and no
necessity bound follows from the argument at all — is right, and is the stronger of the two readings
the entry contains. Only its mechanism sentence and its CLAIMS_DECIDED quotation are corrected here.

### 2. The 2026-08-29 VM-policy entry — "Both documents now state the operative rule" was a day early, and a fourth site is still live

That entry closes: *"Both documents now state the operative rule: enumeration → Spot; merge and any
workload that cannot checkpoint → Regular/Standard, right-sized; the orchestrator stays Regular."*

`DEPLOYMENT.md` did — its STANDING POLICY block (`documentation/DEPLOYMENT.md:140-147`) states the
split rule and was reaffirmed that day. **`CLAUDE.md` did not.** At the reconciling commit
`cbf818c4` (2026-08-29) three later blocks in the same §Cost control section still commanded the
blanket rule the paragraph above them had just withdrawn: the mandatory pre-launch gate told a
reader whose VM reported `Regular` to stop and recreate it as Spot (`:130`); the creation-command
template admitted only the Spot form (`:132`); and the paragraph asserting that merge VMs too are
now Spot survived verbatim (`:141`). A reader following CLAUDE.md's own mandatory gate would still
have recreated a merge VM as Spot — the precise failure the entry claims to have removed.

Those three were fixed the **next** day, in `0e4fe585` (2026-08-30). At HEAD the gate splits
enumeration from uncheckpointable work (`CLAUDE.md:131-134`), the template carries both forms
(`:146-149`), and the blanket-Spot paragraph is struck with a dated withdrawal marker (`:156-163`).

**A fourth site is still live as this is written.** `CLAUDE.md:396`, in §"Bi-region architecture",
still reads *"**Spot** for ALL workloads, enumeration AND merge, per the 2026-04-29 standing policy …
(which explicitly supersedes the earlier enumeration=Spot / merge=on-demand split…)"*. It
contradicts §Cost control in its own file. It escaped both the 2026-08-29 reconciliation and the
2026-08-30 fix because both worked the §Cost control section and the surviving copy is 250 lines
below it — the same scope-too-narrow mechanism CX-34 and CX-13 record. It is written down here
rather than corrected here: this pass is confined to this file.

### 3. The 2026-08-28 TR-10 tails entry — the candidate bar's sidedness was never frozen, and row 2 does not report a two-sided value

**(a) "by our own declared rule" claims a preregistration the freeze does not contain.** The pinned
freeze is `git show 2d19a3f:documentation/CRITIQUE.md` (line 388 there; `documentation/CRITIQUE.md:571`
at HEAD), and it reads, in full: *"Thresholds as F4': two-sided p < 0.05/9 Bonferroni 'notable';
'candidate rule' additionally requires the corpus-control specificity gate."* **"two-sided" attaches
to the notable bar only, and the < 10⁻⁴ figure is not in that sentence at all.** TR-10's own abstract
now records the same thing: the candidate-level bar is inherited from the F4' family's registration,
*"worded '< 10⁻⁴ after Bonferroni'; sidedness unstated there"*
(`reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md:39`).

So `rotinv`'s demotion off the candidate bar is right **under the two-sided convention adopted
uniformly on 2026-08-28** — consistent with row 1 and with the notable bar — and it is not the
enforcement of an explicit frozen rule. The distinction is the whole difference between a
preregistered verdict and a post-hoc convention applied evenly, and the entry's headline sells the
stronger of the two.

**(b) "Rows 1–2 of the scoreboard duly report two-sided values" is false for row 2.** Row 1
(`termruns`, `reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md:105`) does: *"P(≤3) = 2.7×10⁻² (two-sided
~5.4×10⁻²; population mean 5.2 runs)"*. Row 2 (`compmirror`, `:106`) reports only *"P(≥1) =
1.12×10⁻² (~1 in 89 orderings)"* — there is no two-sided figure on that row.

**What stands, untouched.** Row 7's `pureplace` NULL — its one-sided 5.56152×10⁻³ already exceeds
5.55556×10⁻³ before any doubling, with the ≈0.1-SE knife-edge caveat added 2026-08-29 — the
five-null / one-notable / three-data-like tally, `rotinv`'s non-promotion (data-like under either
convention), and the order-preservation argument that protects the BH ranking anchor in METHODS and
TR-8.

**Still outstanding, outside this file.** TR-10's row-6 inline correction marker (`:110`) still
asserts *"The bar declared at §3 is **two-sided** p < 10⁻⁴"* — the same retrofit, at the claim site.

### 4. The 2026-08-29 provenance entry — the correction over-corrected, and miscounted using its own sentence

That entry replaced TR-10's *"the classical constraints"* with *"the C1–C5 constraints"*. The
direction is right and the two reworded sites stand. Its supporting taxonomy does not.

**(a) "only C1 is classical" is contradicted by CITATIONS.md.** `documentation/CITATIONS.md:58-71`,
§"C4 — fixed start (Qian, Kun)", opens *"The placement of the two constant hexagrams (Qian 乾, Kun 坤)
first is classically attested, independently of any modern analysis"* and closes *"**Status in
ROAE:** classical fact, encoded as C4; not novel to ROAE."* What is **ours** in C4 is the
*orientation*, not the pair: `reports/METHODS.md:24-33` (narrowed 2026-08-30) records that the Xugua
does **not** attest the within-pair order, and that *"C4's orientation is **ours by definition**"* —
while the pedigree the classical record does supply is C1's pairing rule, 孔穎達's 二二相耦，非覆即變,
7th century.

**(b) The count is wrong by the entry's own sentence.** That same sentence attributes **C2 to
McKenna 1975**. So at most **two** of the five — C3, a KW-fitted threshold, and C5, a histogram
extracted from KW — are ours. C2 borrows McKenna's authority: not the classics', and not ours
either.

**The taxonomy as the tree holds it:** C1 classical (Kong Yingda); C4 pair classical, orientation
definitional and ours; C2 external-modern (McKenna 1975); C3 and C5 project-derived. Reading "ours"
loosely as "non-classical" does not rescue the entry — it then fails on the other clause instead,
because C4's pair choice is classical.

**A sibling in this same file, found while checking the above.** The 2026-08-28 GUIDE.md entry cites
*"reports/METHODS.md:25"* as calling the Xugua the *"definitional and classically attested"* basis
for **C4's orientation**. That quotation no longer greps in METHODS.md: the 2026-08-30 narrowing says
the opposite of it. The GUIDE.md sentence that entry replaced stays correctly replaced — a written
classical account of the ordering does exist and this repository does rely on it — but the account is
C1's pairing rule, not C4's orientation, and the entry's supporting quote now describes a state the
tree does not have. **CX-09 carries the same superseded claim as a live assertion**, in its `NOW:`
bullet: *"C4's orientation is definitional and classically attested (Xugua)."* Its retraction of the
forced-orientation theorem is unaffected — that rests on the complementation symmetry, machine-checked
in Lean — but the attestation half of that sentence is now contradicted by METHODS.md. Both sites are
annotated in place and neither is rewritten: same class as items 1, 2 and this one.

### 5. CX-34 — "Both budget exactly 100B nodes" is not exact, and the two budgets are not equal

CX-34 contrasts the 2026-05-25 bisect configuration (158,364 cells × a hand-set
`SOLVE_PER_SUB_BRANCH_LIMIT` of 631,545) with the auto-divided runs (3,030 sub-branches ×
33,003,300 nodes) and says *"Both budget exactly 100B nodes and spend them differently."*
Recomputed:

| configuration | product | vs 100,000,000,000 |
|---|---|---|
| bisect, 158,364 × 631,545 | **100,013,992,380** | +13,992,380 |
| auto-divide, 3,030 × 33,003,300 | **99,999,999,000** | −1,000 |

The two differ from each other by **13,993,380 nodes (0.014%)**, and **neither equals 100B**. No
global cap makes them equal: the budget is enforced **per branch**, against each thread's own
counter (`ts->branch_nodes >= per_branch_node_limit` — `solve.c:4609`, `:4876`, `:9460`, with the
invariant spelled out in the comment at `:592`), and `SOLVE_PER_SUB_BRANCH_LIMIT` **replaces** the
auto-divide quotient rather than capping a total. The allocated work therefore *is* the product.

**CX-34's conclusion is untouched.** The bytes reproduce from four independent code states across
two lineages, the deprecation stays retracted, and partition **shape** — 3,030 deep sub-branches
against roughly 158K shallow ones — remains the mechanism for the record-set divergence, since a
0.014% budget difference cannot move a record count from 12,386,121 to 27,664,734. What is corrected
is the word *exactly*: this is a shape comparison, not an exactly budget-matched one, and a ledger
entry should not claim a control it does not have.

### 6. The 2026-08-29 archive-recipe entry — a default published as a universal, and a replacement that inherited the flaw

**(a) "It cannot match" is true of a default, not of every artifact.** The entry says the published
`sha256sum -c` recipe *"is wrong for anything produced since #169 … It cannot match."* Framing is an
environment variable: `solve.c:1165` documents *"SOLVE_COMPRESS — default ON; =0 writes TRANSPARENT
(raw, no gz wrapper) bytes"*, and the `.sha256` sidecar is framing-invariant by design — which is
fact (1) of the entry itself. On a raw shard the sidecar's logical sha **is** the sha of the bytes on
disk, and the recipe verifies. Measured on the orchestrator 2026-08-30, same sub-branch and same
node budget, two framings:

| | default (gz) | `SOLVE_COMPRESS=0` (raw) |
|---|---|---|
| on-disk magic | `1f 8b 08 00` | `52 4f 41 45` = `ROAE` |
| sidecar line 1 | `4cd43b2b…f287` | `4cd43b2b…f287` — **identical** |
| `sha256sum <bin>` | `6e4d49b8…a2f2` | `4cd43b2b…f287` |
| `sha256sum -c` | FAILED, rc=1 | **OK, rc=0** |

The gz column reproduces the entry's own published table byte-for-byte, both shas. The raw column is
the case the entry does not admit exists. **The era sets the default; the container decides the
recipe.**

**(b) The replacement recipe fails the same way, mirrored.** `gzip -dc <bin> | sha256sum`, run
against a raw shard, writes gzip's complaint to stderr, emits nothing on stdout, and hashes the
**empty stream** — `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`, which is
sha256 of zero bytes — while the pipeline exits **0**. A clean exit plus a digest that cannot match
any sidecar is a false mismatch on a byte-correct artifact: the same phantom-drift direction the
entry itself calls *"the expensive direction"*, and the direction this project has already spent
about six hours on. `gzip -dcf` matches the sidecar in **both** framings, which removes the
era-dependence instead of qualifying it — but `-dcf` fixes the *framing* half only: `| sha256sum`
still discards gzip's exit status, so the loud form needs `set -o pipefail` or an explicit status
check. Evidence for both halves is retained privately.

**Still outstanding, outside this file.** `documentation/DEPLOYMENT.md:1074` still publishes the
`gzip -dc` form as its executable line. The era-exception block immediately below it (`:1077-1082`)
does name `SOLVE_COMPRESS=0`, so a careful reader is warned; the command itself is still
framing-fragile.

**What stands.** The original finding is right and it mattered: the recipe as published was wrong for
the artifacts it was actually pointed at, the sidecar-versus-container diagnosis is correct, and
GATE 28 is a real gate. Only the universal quantifier is withdrawn.

### What this pass did NOT do, and where those items live

Four of the six adjudications prescribe work outside this file, and none of it is done here:
`CLAUDE.md:396`; TR-10's row-6 marker; `DEPLOYMENT.md:1074`; and five proposed `doc_gates.sh` legs —
a `ledger-quotes` leg (every *now reads "…"* quotation in this file must grep verbatim in the named
target, or carry a supersession pointer), a `prereg-claims` leg (any *frozen/preregistered/declared*
sidedness assertion must carry a quote that greps in the pinned freeze), an `exact-products` leg (a
sentence asserting *exactly* of a number next to a stated `A × B` must satisfy A×B = that number),
plus registrations in `RETRACTED_PHRASES.tsv` and an extension of GATE 28's population to
`gzip -dc`-style recipes. Items 1 through 4 of this entry are precisely the class a `ledger-quotes`
leg would have caught mechanically, which is the argument for building it.

**How it was found.** An adjudicated review pass over this ledger's own entries, in which each charge
was re-derived against the working tree before it was written up rather than taken on the reviewer's
word — which is how items 2 and 4 came to be narrowed: the CLAUDE.md blocks had been fixed a day
after the charge was raised, and METHODS.md's C4 wording had already been narrowed, so both had to be
restated against what the tree holds now. Reviewers are **acknowledged**, not credited as authors.

---

## 2026-09-01 — the `--estimate-knuth` stack failure was described as a segfault long after it stopped being one

**Registry keys: `RP-0db497ec`, `RP-05e4f10d`** (`documentation/RETRACTED_PHRASES.tsv`).

**BEFORE.** Five published sites told readers that under the default 8 MB stack the
`--estimate-knuth` commands *abort with SIGSEGV before producing output* — i.e. to expect exit 139
from a crashed process.

**NOW.** Since **2026-08-21** the binary preflights `RLIMIT_STACK`, prints an actionable diagnostic
naming the ≥ 16 MB it needs, and **exits 1**:

```
solve: stack limit is 8 MB, but --estimate-knuth needs >= 16 MB
       (main ~7.2 MB frame + estimator ~1.0 MB frame).
       Re-run with:  ulimit -s unlimited
```

`solve.c:18865-18875` is the preflight; its own comment records *"previously a bare SIGSEGV after the
banner."*

**WHAT DID NOT MOVE — and this is the load-bearing half.** The `ulimit -s unlimited` **requirement is
true and unchanged**. The freshly built binary asserts it itself. Only the *failure mode* was
retracted. No verdict, figure or sha is affected: the estimator's outputs are identical either way,
because in both regimes it either runs with enough stack or does not run at all.

**HOW IT WAS FOUND — six passes, five of them miscounted.** Two independent reviewers filed it, two
adjudication batches accepted it at *13 sites*, and one intermediate finding **denied it entirely**
before being retracted. Every wrong answer came from **counting `grep` hits for `SIGSEGV` instead of
reading what each hit said**:

- **9 files** matched only on a *correct historical clause* — "previously a bare SIGSEGV" — and had
  already been corrected. Sweeping them would have deleted accurate text.
- **5 files** carried the live stale claim. Four were corrected in a dedicated pass; the fifth was
  the file that first reported the other four.
- The denial came from measuring a **binary built 14 hours before the `solve.c` it was testing**. A
  fresh build exits 1; only the stale one segfaulted. A `roae-private/scripts/binary_freshness_check.sh`
  now refuses that mistake.

**WHY REGISTRATION WAITED.** Four consecutive adjudication batches each named this registration as
the cheapest available fix, and each was right that it was cheap and wrong that it was available:
registering the phrase while any live site remained would have turned **GATE 3 red for the whole
corpus**, which is how a gate gets disabled rather than obeyed. It was registered only after a
verified **zero-hit** sweep, and red-tested by planting the phrase and confirming GATE 3 fails.

**Consequence for future notes.** A correction note that **quotes** a retracted phrase verbatim is
indistinguishable from a live claim to a literal-string scan, and blocks its own registration. Notes
in this class **paraphrase** — "described the failure as a segfault before any output" — which is why
the nine already-corrected files say only *"previously a bare SIGSEGV."* That convention is
load-bearing for the registry, not stylistic.

---

## 2026-09-01 — C4's within-pair orientation was called classically attested; it is our convention

**Eight registry keys** in `documentation/RETRACTED_PHRASES.tsv` carry this retraction, one per
surviving phrasing.
**Registry keys, one per phrasing** (each row carries its own allow file). Each is identified below
by the site it lived at, **never by quoting it** — a verbatim quote in this ledger would itself trip
GATE 3, which is the hazard the paraphrase rule exists to prevent and which this list tripped on its
first draft:

- `RP-e4ba092e` — the `TR9_PRICING_THE_CONSTRAINTS.md:94` / `DESCRIPTION_LENGTH.md:43` footnote form
- `RP-ce8ea543` — the `TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md:103` parenthetical
- `RP-458d6f24` — the `lean/README.md:659` form
- `RP-471438a5` — the `TR1_EIGHT_CENTURIES_MEASURED.md:362` framing epithet
- `RP-117df1a3` — the short form at `TR1_EIGHT_CENTURIES_MEASURED.md:371`
- `RP-aa034cb6` — the `TR1_EIGHT_CENTURIES_MEASURED.md:370` "classical opening" form
- `RP-0a5fa699` — the `SOLVE_SUMMARY.md:204` parenthetical (allow: `reports/METHODS.md`)
- `RP-bab8cf34` — the `SPECIFICATION.md` / `CLAIMS_DECIDED.md` form (allow: `documentation/CORRECTIONS.md`)

**BEFORE.** Fourteen sites across eleven files described C4's **orientation** — Heaven (63) before
Earth (0) — as *definitional and classically attested*, citing the *Xugua* commentary's
Heaven-then-Earth opening.

**NOW.** The *Xugua* attests that the **{Heaven, Earth} pair opens**. It does **not** attest the order
**within** that pair. C4's orientation is **this project's convention, not an inheritance it found.**

**HOW IT WAS FOUND, and why the basis is stronger than the correction needed.** The narrowing landed
in `reports/METHODS.md` on 2026-08-30 as an assertion. The **primary-text** verification behind it was
surfaced later, by a prior-art check during propagation:
`roae-private/books/li_shangxin/B1_KONGYINGDA_XUGUA_VERIFY.md` reads 孔穎達's
**二二相耦，非覆即變** against the source and finds it a **C1** pedigree — 乾坤 appears there as an
*example of a complement pair*, not as an ordering. The *Xugua*'s own 有天地，然後萬物生焉 treats
天地 as a compound. So the retraction rests on a reading of the classical text, not on our say-so.

**WHAT DID NOT MOVE.** No count, sha, rung, orbit figure or canonical integer. **C4 is still charged
its full 6 bits** (pair *and* orientation) in `DESCRIPTION_LENGTH.md` and TR-9 — being definitional
rather than attested returns no bit. TR-1's 12-of-1,720,320 result is untouched; only the epithet on
its framing was wrong. No Lean statement, proof, axiom set or trust base changes.

**WHAT WAS DELIBERATELY LEFT.** Three classes of surviving text, each correct as it stands:
- sentences scoped to the **pair choice**, which genuinely is classically attested
- **revision rows** and the append-only entries above, which record what a past pass adopted
- `documentation/HISTORY.md:5740-5741`, a dated narrative log entry that accurately reports what the
  2026-07-26 batch did. Only one of its three descriptors later fell. It carries a dated annotation
  rather than a rewrite: **editing it would make that batch appear to have adopted a position it did
  not hold**, which is falsifying history to make it look better.

**ONE QUESTION LEFT OPEN, deliberately.** `documentation/CITATIONS.md` cites Schulz & Cunningham
(1990) p. 298 for a qian/kun "unavoidable priority". The held notes on that paper are 82 lines and
contain no such passage, so **we cite a page we cannot read**. If it argues *within-pair* order, then
a **modern secondary source** bears on the orientation — which would leave every sentence above
still true, because each is confined to the **classical** record. Tracked in
`roae-private/TASK_VERIFY_SCHULZ_1990_PRECEDENCE_CLAIM.md`; a circularity audit applies before it
could ever be staged as support.

**Registration discipline.** All eight needles were registered only after a verified **zero live
occurrences** sweep run through GATE 3's own pipeline (fold `*`, flatten, `grep -F`), and the two
that need an allow file use the **directory-prefixed** form: the allow column is a *substring* match
on `file:line`, so a bare basename can silently exempt a sibling — a bare `HISTORY.md` would also
exempt `PERFORMANCE_HISTORY.md`.

---

## 2026-09-01 — the front page carried the retracted "seven others" gloss for four days

**Registry key: `RP-8ec652db`** (`documentation/RETRACTED_PHRASES.tsv`), registered on the short
front-page form. The wording is identified here **by its site**, never restated, so this entry does
not itself trip the scan.

**BEFORE.** `README.md:67-68` glossed the exact-counting result as King Wen plus seven others in its
immediate neighbourhood, inside the passage arguing **non-uniqueness**.

**NOW.** All eight C6–C7 survivors carry **King Wen's own pair ordering**; the other seven are
**orientation variants** of it, not different orderings. Read as pair orderings, that slice runs the
*other* way — which the passage now says, immediately before its correct and unchanged statement that
King Wen is unique only within budgeted enumerated slices, never in the full space.

**WHAT DID NOT MOVE.** **16,504 and 8 are correct** and were not touched. The exact corroboration
still stands *at the oriented level*, where 8 ≠ 1 and the full-space figure lives too. Nothing was
softened: the non-uniqueness argument survives, now stated at the level it is true at.

**HOW IT WAS MISSED — and the diagnosis I first published was wrong.**
This was ruled on **2026-08-28** (entry above). `TR-4` and `SEARCH_SPACE_SIZE.md` were corrected then;
the front page was not, and stayed wrong on `main` for four days.

The phrase **wraps a line break**, so the human `grep -rn` sweep that propagated the 2026-08-28 fix
returned nothing for `README.md`. I recorded that as a **gate** defect and wrote up "flatten
whitespace in the retraction legs" as the highest-leverage fix available. **That fix would have been a
no-op.** `scripts/doc_gates.sh:829` and `:1932` **already flatten** (`tr '\n' ' ' | tr -s ' '`), and a
second batch had established the same thing hours earlier.

The gate did not miss this phrase — **it was never asked to look for it.** No row in
`RETRACTED_PHRASES.tsv` covered this wording; its only `King Wen` rows belong to an unrelated
boundary-constraint retraction. **A line break defeated a human sweep; the registry gap is what let it
survive.** Registering the row is the actual fix, and it is done.

**The generalisable point.** A correction is not propagated by fixing the sites a `grep` returns. It
is propagated by **registering the retracted wording**, so that every future pass is checked against
it mechanically. Between 2026-08-28 and today, three separate sweeps of this corpus ran and none
found the front page, because all three were looking for sites rather than being told what to reject.

---

## 2026-09-01 — six ledger sentences claimed more than their evidence reaches, and one was false when it was written

A second adjudicated review of **this file's own entries**, from a transcript (`rev_V2-F14`) nobody
had read until today. The class is narrower than the previous pass's and more uniform: **a true
finding written up in a wider form than the evidence behind it supports** — an inventory whose
arithmetic does not close, a bound printed as an estimate, two unhedged universals, a completeness
promise the body itself scopes, and two internal pointers that resolve to nothing. Item 7 is a
different and worse kind: a sentence that was **false on the day it was committed**, and that this
pass found only because it re-executed the tool the sentence was about.

**Nothing below deletes or rewords an existing entry.** Every corrected entry keeps its original
wording and now carries a dated blockquote pointer to the item here that corrects it. GATE 10a is a
strict `diff` against `HEAD` and would reject anything else; that it permits an inserted pointer is
deliberate and documented (`scripts/doc_gates.sh:6664-6665`).

### 1. The 2026-08-29 VM-policy entry — the inventory offered as its evidential basis does not add up, and "never" outruns a one-day snapshot

The entry's measurement paragraph states that of the **seven** non-orchestrator VMs, **five** are
`Regular`, and that only the enumeration VM is Spot. **Five plus one is six.** One of the seven is
unaccounted for in the very sentence offered as the evidential basis for changing the policy, so a
reader cannot audit the count that decided it.

**The seventh is not recoverable, and that is the honest answer.** The measurement was a live-subscription
snapshot taken on 2026-08-29; no VM list from that date is preserved in either repository. A
plausible candidate is the `c292-codex` review box, which `CLAUDE.md:139` records as having run
`Regular` — but the entry does not say so, and reconstructing an inventory after the fact from a
different document is not auditing it. **What the evidence supports is the weaker statement: at least
five of seven were `Regular`, one was Spot, and the seventh's priority is unrecorded.** The policy
conclusion is unaffected — it needs only that most non-orchestrator VMs were not Spot, which five of
seven establishes on its own.

**"Practice has never followed the blanket rule" is a claim about the whole campaign history drawn
from one day's snapshot.** The supported form is **"did not follow it on the date measured
(2026-08-29)"**. The distinction matters because the entry uses the universal to argue the rule was
*unfollowable*, and a single observation cannot separate a rule never followed from one abandoned.

**Sibling sweep, including files outside this batch.** The same two defects propagated. `CLAUDE.md:105`
and `documentation/DEPLOYMENT.md:143` carry the five-of-seven figure without the "only the enumeration
VM is Spot" clause, so their arithmetic does not fail to close — but all three of `CLAUDE.md:105`,
`CLAUDE.md:107` and `DEPLOYMENT.md:143` carry the "never followed" universal, and `CLAUDE.md:107`
carries both defects in full. Those are recorded here rather than corrected here: this pass is
confined to this file.

**Not re-filed here.** The `CLAUDE.md` §Cost-control half of the originating charge is already ruled —
item 2 of the entry above, and the surviving `CLAUDE.md:396` site disclosed there. Nothing in this
item is about that.

### 2. The withdrawn-figure entries — a coverage figure computed against `31!` is an upper bound, printed six lines after the entry refuses to give a point estimate

Both copies of the withdrawal entry state their replacement as **bounds, both ends exact**, with
`31!` explicitly the **upper** end, and then decline a point estimate on the ground that `E[1/m]` has
never been measured. Six lines later each gives the corrected coverage as **"≈1 part in 7.81×10²³"**.

**The figure's denominator is `31!` itself**, which is what makes the approximation sign wrong:

```
python3 -c "import math; print(math.factorial(31)/1.0525e10)"   # -> 7.8127e+23
```

Since the true population **P ≤ 31!**, coverage `= 1.0525×10¹⁰ / P` is **at least** 1 part in
7.81×10²³ and may be very much better. It is a bound, computed from the entry's own stated upper
limit, and the "≈" presents it as an estimate six lines after the same entry refuses to offer one.

**Corrected reading: "at least 1 part in 7.81×10²³"**, at both sites — `documentation/CORRECTIONS.md:1303`
and the branch-preserved duplicate at `:1377`.

**What does not move.** The qualitative verdict is untouched and survives either reading: exhaustion
is infeasible at any conceivable budget. The entry's own note that the error *understated* the
enumeration is likewise unaffected, and is the reason the label is worth correcting rather than
ignoring — the number is load-bearing in exactly the direction a reader extrapolating search cost
would use it.

### 3. CX-35 — the conclusion paragraph states two universals whose qualifier lives in the next bullet and is never pointed at

CX-35's "What follows" bullet (`:1239-1243`) concludes that the ledger's published line has been
append-only throughout and **always was**, and that **no reader outside this machine could ever have
observed** the broken invariant.

**The reviewer's charge — that the entry over-reaches epistemically — does not survive contact with
the entry.** The bullet that immediately follows is headed *"Residual limitation, stated rather than
buried"*, and it rates the evidence honestly: a 404 six days after the fact is very strong evidence,
**not a proof**, and a stronger form would need the remote's own audit log. The entry headlines its
own weakness and names the instrument that would settle it. That is better practice than most of what
either review pass found, and the record should say so.

**What survives the refutation is structural, and it is the whole defect: the hedge is not attached to
the claim.** A reader quoting the conclusion bullet — the quotable one — carries away two flat
universals with no marker that the qualifier exists. The two paragraphs are adjacent and still
uncross-linked.

**Corrected reading:** the conclusion should read *"…has been append-only throughout, on the
strongest evidence available short of the remote's audit log (see the Residual limitation bullet
below)"*. The finding, the 404 table, the positive control and the reflog check are all unaffected.

### 4. The file's own subtitle promises a completeness the file deliberately does not have

Line 3 promises every claim this project published and later changed, in one place. Two passages
below scope that promise out of existence, both deliberately and both correctly:
`:520` excludes **C4 qualifiers** entirely — they are in the inventory, not in this file — and `:521`
concedes that **silent edits nobody noticed** cannot be found by any sweep, by construction.

**The exclusions are disclosed, so this is a placement defect rather than a false claim** — but the
promise is the file's one-line subtitle and the exclusions are 517 lines below it. A reader who stops
at the subtitle, which is what subtitles are for, gets a guarantee the file does not offer.

**Corrected reading:** *"Every claim this project published and later changed, except C4 qualifier
changes (see the inventory) and silent edits — both scoped below."*

### 5. Two "the entry above" pointers resolve to no entry above

- **`:1655`** attributes to a 2026-08-28 entry above the correction of `CRITIQUE.md:137`'s ceiling
  wording. Whole-file search finds `CRITIQUE.md:137` at exactly two lines, `:1655` and `:1681`, **both
  inside the entry that makes the reference** (headed `:1653`). Every earlier 2026-08-28 entry was
  read; the nearest candidate, the P-value entry at `:1591`, is about `DISTRIBUTIONAL_ANALYSIS.md:358`
  and the 87/465 baseline, not the C2∩C3 ceiling.
- **`:2462`** attributes to a 2026-08-28 entry above the removal of `d2-10T` from a documented scale
  list. `d2-10T` appears only at `:2425-2471`, **all inside the entry that makes the reference**
  (headed `:2423`).

**Sibling sweep, run against this file itself and not only against its neighbours.** A flattened
census — `tr '\n' ' ' | tr -s ' '`, which folds the line wraps that plain `grep` misses — finds
**seven** "entry above" references, one more than a line-based count reports. Five resolve and were
checked individually: `:1329` and `:1493` to the 2026-08-24 withdrawal entry at `:1268`; `:1742` to
the "seven others" entry at `:1591`; `:2204` to the TR-10 tails entry at `:1906`; `:2976` to `:1591`.
**Only the two above dangle.** Recording the sweep's population matters as much as its result: the
previous defect in this class was a sweep that reported "no *other* file" and was structurally unable
to see a second occurrence in its own.

**Corrected reading:** both pointers should be self-references — the correction each describes is made
in the entry that carries the sentence, not in an earlier one.

### 6. "No such author exists" is a claim about the world drawn from one bibliographic correction

`:1797` states, in bold, as the finding of its section, that **no such author exists** for the name
關曉思. What the section's own next sentence establishes is narrower and fully supported: **this
paper's** author is 管小思 (Tongji University, 周易研究 2004(1), pp. 61-74), and 關曉思 was an
artefact of two names romanising identically to "GUAN Xiao-si" in a printed contents list. That
settles the attribution. It does not establish that no person bearing that name exists.

**The entry contains the same error a second time, and the charge named only the first.** At `:1803-1804`
the recorded *cost* of the mistake is that the author was repeatedly un-findable by author search —
*"We were searching for a person who does not exist."* That is a nonexistence inference drawn from
absence of search results, which is precisely the reasoning error the project's own
`prior_art_check.sh` discipline exists to prevent, restated one level up. A sweep that had stopped at
the bolded sentence would have corrected half of it.

**Corrected reading:** *"No author of that name wrote this paper; the name as printed is a
romanisation collision."* The bibliographic correction, the dates, and the observation that fixing
the name made a further 1995 paper findable in about a minute are all unaffected.

### 7. The undercount entry says the shipped `sat.py` could not test the pair it is about. It could, and had been able to for eight weeks.

This is the one item here that is not a matter of scope. `:1843` explains why the fourth minimal
two-rule core went undetected by saying, in part, that the shipped `sat.py` **has no target for this
pair**, so the claim's own tooling could not test it.

**Executed on the shipped file, unmodified:**

```
$ python3 sat.py --emit-cnf five-sub-gender+ccn4 out.cnf
vars=7035 clauses=243175 -> out.cnf          # 0.74 s
```

`ccn4` **is** Schulz S25-28 (`sat.py:78`, `:272`), so `five-sub-gender+ccn4` **is** the pair
{Schulz gender, Schulz S25-28}. The generic `five-sub-` handler is `sat.py:612-615`.

**It was not a late arrival.** `git log -S'five-sub-' -- sat.py` puts the handler in **`36a78482`,
2026-07-04**; `git log -S` on the sentence puts it in **`84259168`, 2026-08-29**. The sentence was
**false by eight weeks on the day it was committed**.

**The entry contradicts itself four lines later**, which is how this was caught: `:1850-1851` reports
the CNF rebuilt "in a scratch copy of `sat.py`" at **7,035 variables / 243,175 clauses** — byte-for-byte
the counts the *shipped* file emits above. The scratch copy was never needed, and its own reported
numbers are the proof.

**What actually explains the miss, and it is the entry's better answer.** The undercount survived
because every prior review **checked the three pairs the sentence names instead of enumerating the
lattice** — which is the reason the entry itself gives, in the same paragraph, and which is true.
The tooling was available and simply was not pointed at the case. **The finding, the fourth core, the
kissat/drat-trim verification and the control run are all unaffected.**

**Why this one matters beyond its own line.** A corrections ledger is cited as authority. This
sentence was cited as authority today, in an adjudication row, for a claim about what the project's
tooling can do — and it was never true. The generalisable rule is the one the sweep above applies:
**a ledger sentence asserting a capability must be executed, not read**, and the same standard that
governs a published figure governs the record of why it was missed.

### Examined and NOT upheld: the append-only prose is accurate, and GATE 10a is order-sensitive

One charge in this batch is recorded here because it was **refuted by execution**, and the refutation
protects prose that would otherwise have been weakened.

The charge held that `:15-16`'s "machine-enforced" and `:457-458`'s stronger statement — every committed
line must still be present **in order**, and **rewriting** an entry fails the gate — overstate what
the gate does; that the implementation is a `sort`ed `comm -23` set difference in which line order is
never examined; and that the prose should therefore be weakened to "no committed line is ever lost".

**Measured, on a scratch clone, against GATE 10a's own logic:**

| injected mutation | `doc_gates.sh appendonly-head` |
|---|---|
| two committed lines transposed, nothing deleted | **[FAIL]** — 2 lines reported, rc 1 |
| one committed line reworded in place | **[FAIL]** — 1 line reported, rc 1 |
| a negating sentence inserted inside an existing entry | `[ok]`, rc 0 |

**The charge measured the wrong half.** The `sort`/`comm -23` it describes is **GATE 10b**
(`scripts/doc_gates.sh:6816`, `:6846`), which is explicitly the multiset-containment half. **GATE 10a**
(`gate_appendonly_head`, `:6741`) is `diff "$tmp" "$f" | grep -c '^< '` — an LCS, and therefore
order-sensitive. The implementation says so itself at `:6789-6790`: *"10a is the order-sensitive half
(diff is an LCS); the two are complementary and both run."* The third row is not a hole either: mid-file
insertion passing is **documented intended behaviour** (`:6664-6665`) and is precisely what lets this
ledger carry a dated pointer in front of the entry it corrects, as every item above does.

**So the prose at `:457-458` is true as written and is not weakened.** Recorded here because the
proposed fix would have made this file's description of its own gate *weaker than the gate*, and an
under-claim in a corrections ledger is a defect in the same family as an over-claim.

**Attribution.** Raised by an **OpenAI Codex** review (target `V2-F14`) whose transcript had not been
read until today. Every item was re-derived against the working tree before being written up: item 1's
seventh VM was searched for and not found, item 2's arithmetic recomputed, item 5's cross-references
resolved one at a time by a flattened census, item 6's second occurrence found by sweeping the entry
rather than the quoted sentence, item 7 settled by executing the tool, and the not-upheld charge
settled by red-testing the gate. Two of the review's ten limbs did not survive that process and are
recorded as not upheld rather than quietly dropped. Reviewers are **acknowledged**, not credited as
authors.

---

## 2026-09-02 — `sat.py` broke its own "no hand-written constraint semantics" rule, and the guard could not have told us

`sat.py`'s header, and [SAT_CLI.md](SAT_CLI.md) §DESCRIPTION, state that the file contains **no
hand-written constraint semantics** — every constraint is derived from `solve.py` imports, so a
transcription error cannot enter the encoding. Two C5 tables violated that rule from the file's
creation (2026-07-02): the King Wen transition multiset `_tot = {1: 2, 2: 20, 3: 13, 4: 19, 6: 9}`,
which the round-trip verifier `verify_seq()` accepted models against, and the pair-boundary multiset
`BETWEEN_MULTISET = {1: 2, 2: 8, 3: 13, 4: 7, 6: 1}`, which builds the C5 clauses. Both were
**correct** — re-derived clean-room from `verify.py`'s own table by the Codex V2 adjudication (A08
row 13) and again from `solve.binary_hexagrams` + `solve.bit_diff` in this fix — so no emitted CNF,
model count or verdict changes. The defect is what stood *between* them: a guard
(`_tot[d] - _wp[d] == BETWEEN_MULTISET[d]`, added 2026-08-28 under Q-357) that tied only their
**difference** to the derived within-pair table. A `+1` applied to both literals at d=2 passed it
(**measured**: `GUARD_PASSES_ON_COMMON_MODE_+1_AT_d2: True`), and `verify_seq()` compared decoded
models against the same `_tot` the encoder used, so encoder and verifier would have drifted together
undetected. That is the verifier-closure shape — a check sharing an assumption with the thing it
checks — in the SAT lane, and it is the one error class hand-writing actually produces.

**Fixed.** Both tables are now computed at import by `derive_c5_tables(solve.binary_hexagrams)` —
three `solve.bit_diff` counts sharing no intermediate (all 63 transitions; the 32 within-pair
transitions; the 31 pair-boundary transitions counted directly) — with key order pinned so CNF
variable numbering is unchanged (ten pre-change emissions, including `--with-c3`, `--c3-min
--not-kw`, `--f1-pairs 9` and `--rigidity-cnf`, re-emitted byte-identical). `c5_tables_guard()`
replaces the difference check with anchors none of which is computed from the table it checks:
`solve.h2_kw_multiset()` (solve.py's own derivation), the distances over `solve.build_pairs()`, the
cardinalities 63/32/31 from `len(KW)`, and the additive identity kept as one leg of five.
`verify_seq()` now calls `solve.h2_pop_valid()` — solve.py's constraint function — rather than the
module table. The red test is a subcommand, `sat.py --c5-selfcheck`, which corrupts copies of the
tables and reports `GUARD_REJECTS_COMMON_MODE=1` only if the `+1`/`+1` corruption is refused (it is:
legs G1 and G3 fire), plus a battery of ten corruption classes and a non-KW sequence, all refused.
`tests.py` pins the tokens and repeats the red test in-process with its reference recomputed from
`solve.py` primitives. The guard's tolerance was not widened anywhere; every leg is an equality.

**In the same pass** (A08 row 18 / A09 row 20): the documented `sat.py --rigidity-cnf OUT.cnf --run`
had exited 1 with nothing written since 2026-08-28, because the unrecognised-flag guard added that
day ran before the rigidity branch consumed `--run` — a complete kissat + DRAT + `drat-trim` path was
unreachable for five days while SAT_CLI.md advertised it. `--run` is now consumed before the guard
(and refused outside `--rigidity-cnf` rather than silently dropped); the same guard now also
validates the subcommand token, so `--wittness plain` exits 1 instead of printing the help banner
with exit 0. No solver was on the fixing host: the CNF-writing and kissat-absent paths are pinned
by `tests.py`; the kissat verdict leg itself was not exercised here.

**Attribution.** Raised by the Codex V2 review (V2-F50 #1, #6; V2-F62 #4, #7), adjudicated in
roae-private A08 rows 13 and 18 and A09 rows 17 and 20, fixed in the Fable lane (T6).

---

## 2026-09-02 — the fourth two-rule core: its certificate ships, its classification is decided, and it carries one checker where the other 21 carry two

**What changed, and where.** The 2026-08-28 entry above established a fourth minimal two-rule core,
{Schulz gender, Schulz S25–28}, and left two things open: its certificate was verified off-tree but
not published (TR-2 v1.29 and CLAIM_TO_ARTIFACT row 8 said so), and whether the core is a genuine
discovery or definitional-by-construction like {gender, CC-N8} was deferred.

**The certificate is now in `reports/certificates/`** as `core_gender_ccn4_unsat.drat.gz` (sha256
`bcfc72a1a9ce5ef7c4703f4fb0f321033ed6eb7f8d593007c136d449fb78fe61`), with its regeneration row
(`python3 sat.py --emit-cnf five-sub-gender+ccn4 f.cnf`, 7,035 vars / 243,175 clauses) and a
`verify_all.sh` entry. The counts move 14→15 and 21→22 in TR-2 §Extension, certificates/README.md,
CLAIM_TO_ARTIFACT.md rows 8 and 12, lean/README.md, SAT_CLI.md and
LITERATURE_RULES_POPULATION_TESTS.md. Before copying, the archived file was checked: `gzip -t` clean,
byte-identical to the blob committed in the private evidence record, and the decompressed proof parsed
as binary DRAT ending in the empty clause against a freshly emitted CNF of the pair.

**The classification: definitional-by-construction.** The criterion is the one already applied to
{gender, CC-N8}: can the contradiction be derived by evaluating one rule's predicate on what the other
pins, using nothing beyond the 36-station coordinate system both are stated in? For this pair, yes.
S25–28 pins the faces at stations 25–28 to `{25: 31, 26: 24, 27: 26, 28: 29}` (`sat.py`), whose
popcounts are 5, 2, 3, 4; the strict gender rule requires a face of popcount ∉ {0, 3, 6} to satisfy
`(pc < 3) == (station odd)`. Station 25 (odd, popcount 5) and station 26 (even, popcount 2) each
violate it; either alone contradicts the rule, and popcount is reversal-invariant, so no orientation
escapes. The conflict is one constant-time evaluation from the rule statements — which is also why it
hid from every census until 2026-08-28: S25–28's *statement* never mentions gender. "Findable only by
census" and "a discovered combinatorial fact" are different claims, and only the second earns the
label. Minimality does not rescue "discovery": {gender, CC-N8} is equally minimal and is classified
definitional. The same criterion confirms the two Moore cores as genuine — parity (18/18) and rhythm
(zero breaks) are aggregates over all 32 slots, and no pointwise substitution on four pinned faces
decides them. The certificate is retained because it makes certificate-backed the statement that
Schulz's S25–28 configuration entails his gender-rule exceptions at exactly their published locus.
What would overturn the ruling: a first-hand reading of Schulz 2016 pp. 23–24 showing that S25–28 as
published prescribes less than a unique face per station (we do not hold that text), or an error in
the gender predicate's exemption set or parity convention, which is validated against Schulz's own KW
tallies in-repo. TR-2's "The other two cores are genuine discoveries" is restated accordingly.

**The disclosure that must travel with the file.** All 21 certificates archived before this one were
run through `drat-trim → LRAT → cake_lpr` on 2026-07-27 — cake_lpr being the formally verified
checker, so those verdicts do not rest on trusting drat-trim. This certificate postdates that batch
and has passed **drat-trim only**. Shipping it silently alongside the others would publish a 22nd
certificate weaker than the 21 beside it, so the gap is stated in certificates/README.md, SAT_CLI.md,
LITERATURE_RULES_POPULATION_TESTS.md, TR-2 and CLAIM_TO_ARTIFACT.md. Also not yet executed: a 22/22
`verify_all.sh` replay of the shipped directory — the shipping host has neither drat-trim nor
cake_lpr; the executed verifications are the 21/21 replay of 2026-08-28 and the off-tree `s VERIFIED`
for the 22nd. The certificate was produced with kissat 4.0.1, where METHODS.md's environment table
lists kissat 4.0.4; the version is recorded here rather than folded into the listed one.

**Attribution.** The publication gap was raised by the Codex V2 review (V2-03, V2-14, V2-19, V2-L08
and V2-F62 #3) and the checker-coverage residue by V2-14 #1, adjudicated in roae-private
(CODEX_V2_ADJUDICATION rows 1, 10, 16); Codex L01 had asserted the core list might be incomplete
without naming a pair. The census that found the core, its certificate, the classification ruling
and this shipping change are the Fable lane's (Claude). Reviewers are acknowledged, not credited as
authors.

## 2026-09-02 — the repr(k) oracle was sold as fails-closed; it is blind to C3, in both languages

**Retraction key: `RP-f89ba1e5`.** VERIFY.md's `--check-repr` row read *"Fails closed: an
*incomputable* key is a finding too, since the artifact claims a canonical record for a key this
instrument says cannot be completed."* Unqualified, that is false on one constraint. The row also
quoted the definition the oracle is written from —
[`lean/RecordConvention.lean`](../lean/RecordConvention.lean), *"the lexicographically least
orientation completion of the pair-order key satisfying the constraint set"* — without saying that
the code implements only part of that set. The Lean file states the predicate explicitly at its B6
bullet: `P` = "the completed sequence satisfies **C2/C3/C5**" (C1/C4 by construction). `verify.py`'s
`repr_of_key` and `verify.c`'s `vc_repr_of_key` apply the forced (63,0) opening, the HD-5 exclusion
and the exact C5 budget, and nothing else — `compute_comp_dist` and `16 + 8·G` appear in neither
function.

**Why it matters, and why it is not cosmetic.** C3 is orientation-invariant (`C3 = 16 + 8·G`,
constant across the orientation fiber), so its absence cannot change *which* completion is
lex-least — the AGREE/DISAGREE verdict on a C3-valid key is unaffected. What it changes is the
`INCOMPUTABLE` leg, which is precisely the leg the retracted sentence advertised: a key whose pair
sequence has `C3 > 776` admits **no** valid completion under the definition, so the correct verdict
is `INCOMPUTABLE`, and both oracles instead return a record and call it agreement.

**Executed, not inferred (2026-09-02).** On a one-record `ROAE`-headed artifact whose decoded
sequence has `C3 = 1080` against the 776 ceiling — the same fixture the `--check-artifact` C3
finding used — `python3 verify.py FILE --check-repr 1` and `./verify --check-repr FILE 1` each
printed `CHECKED=1`, `AGREE=1`, `DISAGREE=0`, `INCOMPUTABLE=0`, `CHECK_REPR=PASS`, rc = 0. The
records path on the same file (`python3 verify.py FILE`) printed `C3 failures: 1 … VERIFY FAIL`,
rc = 1. `--check-artifact` also printed `ARTIFACT=PASS`, rc = 0, in both languages, as already
recorded for that finding.

**Scope of the fix landed today.** Prose only. The `--check-repr` row now says the oracle fails
closed *only over the constraints it implements* and states the C3 gap, the executed verdicts and
the pairing instruction; the `verify.c --check-repr` section carries the same caveat beside its
negative-controls paragraph, with the note that those controls could not have shown it — they
perturb a record until an *existing* check fires; and the `--check-artifact` blind-spot note is
extended from "one mode" to **two modes and four code paths** (`check_artifact` and `repr_of_key`,
in each language). The code legs — a C3 rejection in the repr pair, a `BAD_C3` counter in the
artifact pair, and negative controls for both — are **not** done and are queued to the code lane.

**No registered canonical is exposed.** Every registered canonical's VERIFY PASS is a records-path
pass, and the records path checks C3 (`verify.py:1218`); the enumerator enforces C3 in-walk. The
defect is a latent false-PASS in two review instruments, not a false published result.

**How it was found.** Not by its own charge. The Codex V2 review's accepted finding named
`--check-artifact` alone; this is its sibling, turned up by the standing "fix the class, not the
instance" sweep of the rest of `VERIFY.md` after that charge was confirmed already closed on the
doc side. It is the same A3-audit class the blind-spot note names — an independent verifier
inheriting an enumerator-enforced invariant instead of re-deriving it.

**Attribution.** The `--check-artifact` half was raised by the Codex V2 review (V2-F20 #1) and
adjudicated in roae-private; the repr sibling, its execution and this entry are the Claude lane's.
Reviewers are acknowledged, not credited as authors.

---

## 2026-09-02 — the rebuild recipe was audited against the specs it claims to be derivable from, and eight things did not survive

`documentation/REBUILD_FROM_SPEC.md` exists to be a forcing function: if a reader can build a
conformant `solutions.bin` verifier from it plus `SPECIFICATION.md` plus `SOLUTIONS_FORMAT.md`,
the specs stand on their own. A review pass (Codex V2-F48) charged eight defects against it. All
eight were re-derived here before being acted on, seven were applied as charged, and one was
applied **against** its own prescribed fix. Six retired phrasings are registered:
`RP-1b0f6251`, `RP-60347080`, `RP-1856b0c8`, `RP-e0e32f70`, `RP-0a272ba2`, `RP-584d442b`.

**The class, and why a doc-wide sweep missed it.** Five of the eight are un-propagated residue of
corrections this project had already made elsewhere — the 2026-08-28 budget-scoping of
`SOLUTIONS_FORMAT.md` §Overview, the 2026-09-01 rescope of its §Deduplication representative rule,
the gz-framing note added 2026-08-01, and the `--expect-kw` semantics in `verify.py`. Each of those
corrections was landed and each was correct. None of them had a row in `RETRACTED_PHRASES.tsv`, so
GATE 3 had nothing to look for, and the recipe kept restating the withdrawn readings while every
gate stayed green. The registry rows above are the fix for the class; the edits are the fix for the
instances. A correction that does not register its retired wording is a correction that will be
re-published somewhere else.

**What changed, by site.** The C6/C7 bullet no longer presents the artifact as the complete C1-C5
population: it is the slice a budgeted run reached, its record count is a floor, and the three
canonical counts it cites are relabelled as per-artifact lower bounds rather than population sizes.
Step 9 no longer requires a King Wen record — presence is informational, absence is valid for a
shard or a merged subset, and `--expect-kw` is named as the flag that promotes it — and the size of
King Wen's collapsed orientation class is corrected from a single digit to **1,720,320** = 3·5·7·2¹⁴,
re-derived here by running `python3 verify.py --recount-fiber` to completion on 2026-09-02 (every
figure MATCH, forced slot [30]). The enumerator's per-key orientation space is corrected to **2^31**,
the figure `SOLUTIONS_FORMAT.md` §Deduplication semantics states, since C4 pins slot 0's orientation
and leaves 31 free bits. Step 1 now sniffs the gzip magic before the header parse, because
`SOLVE_COMPRESS` is ON by default and gates the writer on the merge and enumeration paths alike, so
the old Step 1 rejected the generator's own default output — a defect the document already conceded
further down without connecting it to Step 1. The `pair_index` range test moved from Step 4 into
Step 3, ahead of the pair-table lookup: the field decodes to 0..63 against a 32-entry table, so a
literal implementation of the old ordering turned a reportable C1 failure into an out-of-bounds
read. The standalone reproduction of `./solve --selftest` is replaced by the environment `solve.c`
actually builds — a wildcard `SOLVE_*` scrub plus nine settings, measured against the `snprintf`
that composes the child command — where the published one-liner carried three of the nine, no scrub,
and one variable the fork never sets. And two stale size figures for `verify.py` and `solve.c` are
replaced with dated measurements; the unanchored "core" and "enumeration path" line counts are
deleted rather than re-estimated, because neither named a function set or a line range against which
a reader could check them.

**The charge we did not follow.** The review's second finding is right that the closing claim
overreached: Steps 1-11 cannot certify that a producer kept the correct orient variant of a
canonical class, because the competing variants are exactly what deduplication removed. Reproduced
here on 2026-09-02: a two-record artifact holding natural King Wen plus a C1-C5-valid but
non-minimal orient variant of a second pair key (the `…787c` / `…787e` tails the reviewer names)
returns `VERIFY PASS` from `verify.py` even under `--expect-kw`, and `ARTIFACT=PASS` from
`verify.c --check-artifact`. But the prescribed remedy — add a Step 10c and wire the repr oracle
into `--check-artifact` in both verifiers as a hard `BAD_REPR` — is **wrong**, and this is stated
plainly rather than quietly skipped. `solutions.bin` is a pre-normalization artifact: `solve.c`
retains a running minimum over the orient variants a run actually inserts, not the class-global
minimum, so a raw merge output is *expected* to disagree with the global representative on a
regionally varying 1.06%-42.2% of records (measured 2026-08-15 over 1,776,347,935 records,
INCOMPUTABLE=0 throughout), and the normalizing post-pass that would make agreement the right
expectation is on no published ref in this tree. Both verifiers already carry the oracle as a
separate `--check-repr` mode with that rationale written above it in their source; on the fixture
above it correctly reports `DISAGREE=1` / `CHECK_REPR=FAIL`. Adopting the prescription would have
made the shipped verifiers reject the project's own canonical artifacts. The recipe now says
correctness is what it certifies, that byte-reproducibility belongs to the producer, and where the
instrument for the representative question lives and why it is scoped the way it is.

**A defect found while checking the charge, not charged.** The review's third finding asserted in
passing that "both current reference verifiers reject" reserved-field violations. That assertion is
false, and correcting it enlarges the defect rather than closing it. Executed 2026-09-02 on
one-record artifacts built from King Wen: with `header[20]=0x5A`, with a declared format version of
`2`, and with a header declaring 5 records over a 1-record body, `verify.py` returns rc=1, rc=2 and
rc=2 with a named error in each case, and `verify.c --check-artifact` returns `ARTIFACT=PASS` on all
three. `verify.c` reads the 32-byte header and checks the magic only; it holds no version,
reserved-byte or file-geometry test. The three readers inside `solve.c` were all hardened under
Q-350 on 2026-08-28, whose own comment reads that guarding one entry point and leaving its siblings
open "is the defect this project keeps finding" — and the independent C instrument was left open one
level up. The recipe now discloses that scope at the site of the header table so no reader treats a
`verify.c` pass as agreement about the header. **The `verify.c` fix itself is not done**: adding
`BAD_HDR_VERSION`, `BAD_HDR_RESERVED` and `BAD_GEOMETRY`, with a cross-instrument fixture suite
asserting identical verdict tokens from both verifiers on the same poisoned artifacts, is queued to
the code lane and is not claimed here.

**Attribution.** The eight defects were raised by the Codex V2-F48 review pass and adjudicated in
roae-private. The re-derivations recorded above — the fiber recount, the representative
counterexample, the three-fixture cross-instrument divergence, and the `solve.c` selftest-fork
measurement — are the Fable lane's (Claude), as is the ruling that the second finding's prescribed
fix must not be adopted. Reviewers are acknowledged, not credited as authors.

## 2026-09-02 — the McKenna page was audited against the sources it cites, and seven things did not survive

`documentation/MCKENNA.md` is the project's narrative record of what Terence McKenna claimed and
where this project's measurements agree or disagree with him. It is also the page most exposed to a
particular failure: it makes **attribution claims** — statements about what a named person wrote,
computed or conceded — and those are held to the project's strictest standard, because a reader
cannot check them against a number in this repository. Seven defects were raised against it by the
Codex V2-F30 review pass and adjudicated in roae-private; all seven are upheld, two with corrections
to the charge, and the siblings of four of them were swept out of four other documents.

**Registry keys: `RP-65106433`, `RP-be2a6efd`, `RP-be4a6abe`, `RP-743533eb`, `RP-cacb9f78`,
`RP-29cb8f06`, `RP-92dc78d2`, `RP-82072e49`, `RP-9a287287`, `RP-a78e27b3`, `RP-d6011566`,
`RP-636f16f9`, `RP-538fb752`, `RP-1108d09e`, `RP-a6787b2d`, `RP-80ea600d`**
(`documentation/RETRACTED_PHRASES.tsv`, one row each, each carrying its own evidence).

### 1. A budgeted slice was offered as the size of the constrained space, in five places

`MCKENNA.md:120` said five rules cut 10^89 orderings down to *billions*, and `:135` said down to *at
least millions*. Those are enumerated record counts written to disk under a per-cell node budget.
The C1–C5 space itself is estimated at **1.3287×10³⁸ raw** ([TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md),
a Knuth random-probe estimate, not a proven cardinality), so "billions" understated it by roughly 28
decimal orders — and in the direction that flatters the project, by making the constraints look far
more decisive than they are. This is the same inversion `CITATIONS.md` corrected as CX-30 on
2026-08-07 and `PROJECT_OVERVIEW.md` and `GUIDE.md` corrected on 2026-08-24; `MCKENNA.md` is the
un-propagated tail of it.

**The class, not the instance.** A census of the sentence shape found **five** live sites, not two.
The three not charged were `SOLVE_SUMMARY.md:209`, `SOLVE.md:583` and `CRITIQUE.md:362`; all three
are corrected here. `SOLVE_SUMMARY.md:209` was the worst of the five — wholly uncaveated, and
contradicted by the step table twenty lines below it in its own file, which had said since
2026-08-06 that the billion-scale counts are "budgeted 10T slices, not the layer size". **No record
count changes anywhere.** What changes is what a count is said to measure. Each of the five is now
registered separately rather than under one loose needle, because a needle short enough to cover all
five would also fire on legitimate prose.

### 2. A false software attribution, and an objection that was never made

`MCKENNA.md:98` credited Peter Meyer with writing the first Timewave Zero software, and said that he
and the mathematician Matthew Watkins had independently confirmed arithmetic errors in McKenna's
hand calculations. Both halves are settled **against the primary sources the sentence itself
linked**, fetched by `curl` on 2026-09-02.

The archived history page (`fractal-timewave.com/articles/hist.html`, snapshot 2026-07-04) is
Meyer's own account, and it says the wave was calculated "in 1974 or earlier" by **Royce Kelley and
Leon Taylor** using "a FORTRAN program running on a CDC 6400 computer"; that in "1978 or 1979"
**Peter Broadwell** "developed the first Timewave software to run on a microcomputer, the Apple
II+"; and that Meyer's own involvement begins in 1985, producing the Apple //e version in February
1987 and the MS-DOS rewrite in C from January 1989. The cited page refuted the sentence citing it.

The error claim has no source at all. The Watkins objection
(`fourmilab.ch/rpkp/autopsy.html`) contains zero occurrences of *arithmetic*, *error*, *mistake* or
*miscalculat*: its entire argument is that the "half twist" step is unjustified — "why introduce
such a step … whilst admitting that the reason for doing so is 'not well understood at present'?" —
which is a **derivational** objection, and which `MCKENNA.md:95` had been stating correctly all
along, one item earlier on the same page. So this was a within-file contradiction, not a sourcing
gap. Meyer's history describes his own contribution as "a new mathematical description of the
timewave (different from that presented in the appendices to the 1975 version of *The Invisible
Landscape*)" — a reformulation, not a repair. The claim is **withdrawn rather than restated**: this
project relays third-party critiques with attribution and does not re-derive them, so a critique
nobody can be shown to have made cannot be relayed. The closing paragraph at `:135`, which compressed
the same claim into a two-word epithet, is corrected with it.

### 3. The Figure 18B closure was called derived; the predicate does not exist here

`MCKENNA.md:68` said McKenna's 180°-rotation congruence property was partially captured by ROAE's
`--palindromes` analysis and appeared to be a derived property of C1+C2+C3+C5.

**The reviewer's charge understated it.** `--palindromes` is not a partial proxy for that property;
it is a **different symmetry class**. `roae.py` searches the difference wave for contiguous runs
equal to their own reversal — mirror symmetry, D(i) = D(n−i) within a window. Congruence of a plot
with its own 180° rotation is point symmetry about a centre. They are different predicates and in
places opposite ones, which is why no amount of palindrome counting bears on the closure claim.
McKenna's own text does not settle which he meant: his derivation article says the graph is "rotated
180 degrees within the plane and superimposed upon itself", then captions the same figure as the
graph "with its mirror image fitted against it".

A whole-tree search returns no definition, no enumeration and no theorem for the Figure 18B
predicate anywhere in this repository — the private 2026-05-19 book review that seeded the mapping
lists formalising it as a **future** action item, which corroborates the absence rather than filling
it. The correct status is *untested conjecture*. The consequence lands two sections later, where
McKenna's 1971 Monte Carlo filter (3:1 ratio + no-5 + closure) was called "consistent with" this
project's looser C2|C1 rate: that comparison rests on a component never measured here, and now says
so. **The settling programme the reviewer sketched — formalise the predicate, reproduce it on King
Wen, then prove or measure the implication — is recorded as his text and is neither proposed nor
queued.** `documentation/HISTORY.md`'s dated 2026-05-19 entry keeps the original wording as the
record of what was decided then, and carries a supersession marker pointing here.

### 4. The DFT verdict contradicted the report shipped beside it

`MCKENNA.md:88` said the `--fft` showed no frequencies above the white noise floor. `example/report.txt`,
in this repository, prints a white-noise floor of **0.1741** and a magnitude of **0.4266** at
frequency 24 — **2.45×** the floor — and summarises `Frequencies above 2x noise floor: 1/31`. The
sentence was false as written.

The corrected reading does not swing the other way. The report calls its own 2× threshold ad hoc in
its own words and names Fisher's g-statistic or a Bonferroni correction as what a real verdict would
need; with N=63 and no multiple-testing correction, one bin at 2.45× establishes **neither a
significant peak nor a calibrated absence**. A further caveat that had gone missing: this page
concedes at `:22` that McKenna's fractal expansion step is not implemented, so a DFT of the raw
63-value difference wave does not test the multiscale claim it was offered against. Three sibling
sites are swept to the same hedge — `MCKENNA.md:23`, `MCKENNA.md:131` and `PROJECT_OVERVIEW.md:53`.
The last of those was defensible under an ad-hoc threshold and is sharpened rather than retracted:
it now names the threshold instead of leaning on it silently.

### 5. The day calibration and the 384-value module are two different claims

`MCKENNA.md:100` denied the number 384 any bearing on the wave's mathematics and declared the base
period freely replaceable. That is right about the calendar mapping
and wrong about the mathematics. Meyer's *Mathematical Definition of the Timewave* (archived
2026-07-04, fetched 2026-09-02) defines the wave as a doubly-infinite sum of terms `v(x/64^i)·64^i`
"where 64^i is 64 — the so-called 'wave factor' — raised to the ith power", and `v(x)` as "simply
the xth number in the set of 384 numbers … after 383 we use x modulus 384". Substitute a different
module and `v` changes, so the function changes. The item's **heading** — that the 384-*day* period
is assumed, not derived — is correct and stands untouched; what was over-generalised was the leap
from the arbitrary calibration to the fixed construction, and the two are now stated separately.

### 6. A construction-forced zero was read onto a statistic the construction does not force

`MCKENNA.md:107` reported near-zero mutual information between upper and lower trigram *transitions*
and explained it by the complete Latin square — "independence is expected by construction".
`--mutual-info` prints **two** statistics and the explanation belongs to the other one.
`example/report.txt` gives the changed/unchanged **transition** MI as **0.0078 bits**, against a
random-permutation mean of **0.0200 bits**, at the **7.0th percentile**; the construction-forced
quantity is the **static** 8-state MI over trigram identities, **0.000000 bits**, and the report's
own note attaches "independence is expected by construction" to *that* figure, where it is correct
and is left alone. Random permutations contain the same 64 hexagrams and their transition MI varies,
so the construction demonstrably does not force the transition result — and the measured direction is
the opposite of "expected": King Wen sits *below* random on it. The bullet's closing verdict, that
whatever rules govern the sequence do not couple the two halves of each hexagram, went further than a
single binary projection can carry and is deleted.

### 7. A bolded conclusion whose own sentence withdrew its basis

`MCKENNA.md:106` bolded a claim that the wave's structure is local rather than global, and said the
structure arrives in patches, on the evidence of `--windowed-entropy` — whose shipped report states
that it is "an exploratory visualization, not a statistical test" and that "without a null model, no
significance can be assigned to specific regions".

**The reviewer's framing was wrong and it changes the fix.** The bullet was not missing that caveat:
it carried it verbatim, in its own trailing parenthetical. The defect is therefore not an absent
hedge but a **bolded headline retracted by the end of its own sentence** — a reader takes the
headline, and a parenthetical cannot claw it back. Adding a caveat would have changed nothing. The
headline is demoted to what the instrument supports, and the patches claim, which is precisely what
the missing null model forbids, is deleted. The reviewer's failure scenario — a later pass
cherry-picking low-entropy regions as findings — survives the correction and is the reason the
demotion is the right fix.

**Not done, and not claimed.** Two gates were proposed alongside these charges and neither is built:
a cross-check that a published prose verdict may not contradict `example/report.txt`'s own summary
line, and a rule that a **bolded** claim may not be immediately followed by a parenthetical
withdrawing its basis. Both are queued to the code lane. A citation-audit check that verifies a claim
against the page it links — the thing that would have caught defect 2 at write time — is queued with
them.

**Attribution.** The seven defects were raised by the Codex V2-F30 review pass and adjudicated in
roae-private. The source fetches recorded above — the Meyer history, the Watkins objection, the
Timewave mathematical definition and McKenna's derivation article, all retrieved and read on
2026-09-02 — and the corrections to charges 3 and 7, and the sibling census that found four
uncharged sites in four other files, are the Fable lane's (Claude). Reviewers are acknowledged, not
credited as authors.

## 2026-09-02 — TR-9 claimed an upper bound on a denominator this project says it has not published, and a net-bit row that failed the ledger's own definition of "net"

[TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md) prices every constraint in bits. Six defects were
raised against it by the Codex V2-F11 review pass and adjudicated in roae-private; all six are
upheld, one with a correction to the charge. Two of them retire published figures, which is what this
entry records. **No solution count, log-cardinality, marginal compression, residual endpoint or
verdict changes anywhere in the report.**

**Registry keys: `RF-047e690e`, `RF-455570a2`, `RF-e2b24ea8`**
(`documentation/RETRACTED_FIGURES.tsv`, one row each) and **`RP-e35a1705`**
(`documentation/RETRACTED_PHRASES.tsv`).

### 1. A conditional selection charge was published as an upper bound — `RF-047e690e`

§5(f) offered a reader who wants the meta-selection charge — the cost of selecting the constraint
*families themselves* — a closed answer in bits: selecting seven constraints from the frozen
91-observable global ledger "costs **at most** log₂ C(91,7) ≈ 32.9 bits", from which it banked
dominance surviving with a margin of roughly ninety-four bits.

The arithmetic is right and the denominator is the wrong universe.
[METHODS.md](../reports/METHODS.md) §"Global observable ledger" builds the 91 as 28 exploratory
observables + 58 pre-registered testing-family tests + 5 corpus-control predicates — a ledger of
**tests performed**. The meta-selection charge is denominated in **candidate constraint families**,
and METHODS.md §"The file drawer — an open gap, stated as such" says of exactly that quantity: "how
many constraint families were tested and set aside before the published set was fixed? **This suite
does not currently publish that denominator**", adding that it is "a **different quantity** from the
testing-phase ledger" and that "reconstructing that testing ledger does not close this gap". TR-9
therefore converted a gap this project explicitly declares open into a claimed closed bound. The
file-drawer paragraph is dated 2026-08-07; the bound is TR-9 v1.22, dated 2026-08-06. The
contradiction stood for four weeks.

It is not an upper bound on its own denominator either. METHODS.md §"Global observable ledger"
recorded on 2026-08-30 that the ledger omits the pre-registered H1/H3 family and that entering it
gives **95**; log₂ C(95,7) ≈ 33.4 exceeds 32.9.

**What was searched before the absence was claimed.** No roster of tried-and-dropped constraint
families exists anywhere in the corpus:
`prior_art_check.sh 'discovery-phase constraint-family roster'` and
`prior_art_check.sh 'tried-and-dropped constraint families'` both return
`PRIOR_ART=NONE  surfaces searched: roae-private *.md, *.tsv, codex_transcripts/; roae *.md; git log
--all -S on both repos`.

**What is not retracted.** The figure 32.9 itself. It survives, relabelled as conditional on the
testing-phase ledger, alongside the discovery-battery reading log₂ C(28,5) ≈ 16.6. What is retracted
is the claim that it *bounds* anything and the margin computed from it. What the surrounding argument
actually needs — that every selection charge this corpus can price is of order tens of bits against
C1's 146.3 — survives as a statement about the charges that have been quantified, not as a proof that
no larger one exists. Settling it means publishing the tried-and-dropped constraint-family roster and
its encoding; that is not done, is not queued, and §5(f) now says so.

### 2. A net-bit bracket no published cost could produce, and the envelope corner built on it — `RF-e2b24ea8`, `RF-455570a2`

TR-9 §1 defines net value as compression − statement cost, and two of the three rows of §"Sensitivity
table" obey that identity exactly: C1 publishes +133 to +146 from 146.3 − 13 and 146.3 − 0; C5
publishes −6.3 to −13.9 from 9.4 − 15.7 and 9.4 − 23.3. The C2 row did not. It published
"≈ 0 (+2.0 to −4)" against a compression of 4.5 and a cost cell reading "~2.6–4", and the ledger row
in §2 published the same bracket at greater length.

Recomputed from the report's own exact operands: C2's compression is log₂ 23.325025987… = **4.5438**
bits (§2, exact marginals); the declared per-distance-ban family has six members, log₂ 6 = **2.585**,
giving **+1.96** — the published +2.0, correct. The largest statement cost stated anywhere in the
corpus is the sensitivity table's own **4**, giving **+0.54**. Every published coding therefore gives
C2 a **positive** net. Reaching the published −0.6 would require a 5.14-bit statement cost and
reaching −4 an 8.54-bit one, and no explicit-grammar coding producing either is published here or
recorded privately: `prior_art_check.sh 'C2 grammar statement cost derivation'` returns
`PRIOR_ART=NONE`. The mechanical cause is visible in the row itself — the bracket's lower endpoint was
the maximum *cost*, sign-flipped, rather than compression minus that cost.

The bracket is corrected to **+0.5 to +2.0**. The verdict does not move: C2 is break-even to
marginally explanatory either way, and remains the only narrow rule that reaches break-even.

The consequence is not confined to one cell. §4's net-savings envelope was published as
**102.7–148.3 bits ≈ 35–50%**, and its low corner consumed the withdrawn −4:
127.3 + (−4) + (−20.6) = 102.7. With the supported endpoint it is 127.3 + 0.5 − 20.6 = **107.2**, and
107.2 ÷ 296.0 = **36.2%**. The envelope is now **107.2–148.3 bits ≈ 36–50%**. The high corner
(146.3 + 2.0 = 148.3 = 50.1%) and the C5-retaining variant (142.0) are unchanged; the envelope
narrows from below only.

**Two sibling sites are knowingly left live**, and they are registered as such rather than quietly
allowlisted. `documentation/DESCRIPTION_LENGTH.md:36` and `:129` carry the same withdrawn bracket and
`:84` carries the old envelope. All three are adjudicated separately under the Codex V2-F35 pass,
whose prescribed fixes cover exactly those lines, and the batch that produced this entry owns TR-9.
They are entered in `documentation/DOC_GATE_FIGURE_ALLOWLIST.txt` with class `open`, which makes
GATE 3b print each of them as `[OPEN]` on every run until that batch lands. An `[OPEN]` row is an
open defect, not an exemption.

### 3. Four defects that changed no figure, recorded for completeness

(i) The report opened with "Every MEASURED result carries a reproduction command". Its two Knuth
estimates, 1.3287×10³⁸ and 5.21×10³¹, have none: the only published whole-tree invocation reproduces
the *superseded* 5×10⁸ draw, as [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) §Verification Guide and
[SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md) both recorded on 2026-09-02. The banner carrying that
promise is shared boilerplate, byte-identical across all eleven TRs and enforced as such by GATE 9, so
it was left untouched and the exception is disclosed in its own paragraph directly beneath it. (ii) The exact start-free C2 rarity **4.29341%** shipped beside
`solve --f1-exact-c1c2`, which is not a command: executed against a binary built from this
repository's `solve.c` it prints a usage line and exits **2**, because `--f1-mod P` is required and a
single run yields only a residue. The three 63-bit primes, the three complete invocations, the
residues, the CRT reconstruction and the arithmetic from it to the percentage are now published in
TR-9's Verification Guide, all checkable offline without the ~13.1 GB run. The figure was never in
doubt — it was computed and ledgered; only its publication was missing. (iii) The ±0.02% quoted on
estimator counts is a relative **standard error**, not a 95% half-width, so the "±0.0003 bits" beside
it understated the 95% interval by 1.96×; both sites now state ±1.96·SE ≈ ±0.0006 bits. No
one-decimal figure in the report moves. (iv) "`ulimit -s unlimited` is REQUIRED" is a sufficient
setting published as a necessary one — `solve.c`'s preflight tests for **16 MB**, and executed both
ways, `ulimit -s 8192` refuses while `ulimit -s 16384` runs to completion. TR-9's site is narrowed;
twelve sibling sites in other files are reported and queued, not swept here.

**Attribution.** The six defects were raised by the Codex V2-F11 review pass and adjudicated in
roae-private. The execution evidence recorded above — the two `ulimit` runs, the `--f1-exact-c1c2`
exit-2 reproduction, the CRT and percentage re-derivations, and the prior-art searches behind the two
absence claims — is the Fable lane's (Claude). Reviewers are acknowledged, not credited as authors.

---

## 2026-09-02 — two Lean file headers still carried retired wording; both corrected, both re-compiled, axiom sets unchanged

Lean files sit outside GATE 3's corpus (it scans tracked Markdown and `reports/evidence/`), so a
retraction that has been propagated through every document can survive verbatim in a `.lean`
comment — and be re-published the moment a document quotes that header, which
`TRIGRAM_STRUCTURE.md` §4 does by design as a verbatim fence. Three retired phrasings are
registered in `documentation/RETRACTED_PHRASES.tsv`, each identified here by site and key, never
by quotation: `RP-c816eea6`, `RP-365d6b64`, `RP-2e3a1f61`.

**1. `lean/TrigramTheorems.lean`, header ledger §TG-3 (`RP-c816eea6`).**
- **BEFORE:** an attribution rule requiring that any statement about trigram operations on
  hexagrams be cited to Hershock 1991.
- **NOW:** the rule is narrowed to what is his — the 14-family decomposition and the circular
  reordering built from complement, reversal, trigram swap and the nuclear map. Trigram operations
  on hexagrams as such predate him by centuries: `verify.py` (the `--check-classical-groups`
  battery, attributions at its source) credits ⟨comp, rev⟩ and ⟨rev, swap⟩ to
  [Wu Cheng](CITATIONS.md#wucheng) (1249–1333) and ⟨comp, swap⟩ to
  [Jiao Xun](CITATIONS.md#jiaoxun) (1763–1820). The header now also states the real relation
  between the two groups — a shared order-4 subgroup ⟨rev, swap⟩, all of it line-position
  permutations inside G₁₂; complement is not a line permutation — in place of a rule that put the
  whole subject under one 1991 citation.
- **How it was found:** the prose form at `TRIGRAM_STRUCTURE.md` §2 was raised by the Codex V2-F54
  review (#6) and corrected by prose batch P28 (2026-09-01). P28 could not touch the Lean header
  because §4 reproduces `TrigramTheorems.lean`'s header lines verbatim, so the header and the fence
  had to move in one change. They did: the fence now mirrors lines 44–115 of the file (was 44–106),
  less the two-space comment indent and the closing rule, and `diff` against the source is empty.

**2. `lean/KingWen.lean`, complement-symmetry header and the `orientation_not_forced` docstring
(`RP-365d6b64`, `RP-2e3a1f61`).**
- **BEFORE:** both comments described C4's within-pair orientation as classically attested by the
  Xugua's opening.
- **NOW:** both carry the 2026-08-30 narrowing (`reports/METHODS.md` §C4; the 2026-09-01 entry
  above, with its eight keys): the Xugua attests that the {Heaven, Earth} *pair* opens, not the
  order within it, and C4's orientation is our convention. `lean/README.md`'s prose form was
  corrected on 2026-09-01 (`RP-458d6f24`) and already agrees.

**What did not move.** No statement, proof, definition, count or `#print axioms` result. This is
measured, not argued: each file was compiled before and after the edit on the pinned toolchain
(`leanprover/lean4:v4.31.0`, commit `68218e87`) with `#print axioms` appended for every theorem
(70 in `KingWen.lean`, 102 in `TrigramTheorems.lean`, plus the 40 already in that file). All four runs exited 0; the two before/after output pairs are byte-identical once the input-sha and timestamp lines are excluded — 70 results for `KingWen.lean`, 142 for `TrigramTheorems.lean`.
The axiom vocabulary in both files is {`propext`, `Quot.sound`, `Classical.choice`} and
`Lean.ofReduceBool` occurs zero times, before and after.

**Attribution.** The Hershock over-attribution was raised by the Codex V2-F54 review (#6) and
adjudicated in roae-private; the C4 narrowing is the project's own 2026-08-30 finding. The Lean
edits, the fence re-sync and the before/after axiom measurement are the Fable lane's (Claude).
Reviewers are acknowledged, not credited as authors.

---

## 2026-09-02 — the F1C5 layer-format spec was audited against `solve.c`, and six of its operational guarantees did not survive

[`documentation/F1C5_LAYER_FORMAT.md`](F1C5_LAYER_FORMAT.md) is a binary-format specification: an
independent reader implements against it. Its *format* half — header layout, block framing, the
zlib-not-gzip codec, the `pl_hash` recipe — was re-read against the producing code in this pass and
is accurate as written. Its *operational* half was not. Six statements about durability, cadence,
sizing and the archival hook were checked against `solve.c` line by line and all six overstated
what the code does. Four retired phrasings are registered in
[RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) and are identified below by site and key, never by
quotation: `RP-ad9d1d07`, `RP-76bd0543`, `RP-f2905114`, `RP-10357f26`.

**1. A durable, completed layer is not a checkpoint unless the manifest names it (`RP-ad9d1d07`).**
- **BEFORE:** §Checkpoint and resume semantics made durability alone sufficient.
- **NOW:** the guarantee is keyed to the manifest, and the window is stated: the layer file is
  renamed into place *before* `f1c5_write_manifest` runs (`solve.c:16435`, both the in-RAM and
  out-of-core paths), while `f1c5_try_resume` (`solve.c:14523`–`14557`) reads only
  `last_complete_k` and opens that layer — it never stats the directory for a durable next-layer
  file, so no discovery or promotion path exists. A kill between the two writes discards a
  complete, correctly named layer and rebuilds it. **The count is unaffected; only work is lost.**
  §Ordering, two sections earlier, already stated the ordering that makes this true — the defect
  was a guarantee written wider than the mechanism directly beneath it.
- **Swept, two further sites, both live claims and neither in this batch's target file.** Registering
  the phrasing turned GATE 3 red on
  [TR-11](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §10(v), where the use **spanned a
  hard wrap** and was invisible to line-based search — the gate flattens before matching, which is
  the only reason it was seen. Its Verification Guide restated the same guarantee in a different
  spelling that the registry needle does not match, and was corrected with it rather than left as a
  latent survivor. Both now key to the manifest and link to the F1C5 spec; TR-11 carries the change
  as **v1.24**. Neither was allowlisted: an allow row is for a document narrating a retraction, and
  these were live instructions to a reader running the campaign.

**2. The checkpoint rejection path is not unconditional (`RP-76bd0543`).**
- **BEFORE:** §Intra-layer checkpoint said rejection is universal and therefore always safe.
- **NOW:** the narrower true claim (*a rejected marker never yields a wrong count*) is kept, and
  the escape is documented. `f1c5_build_ckpt_read` allocates `off[]`, `kidx[]`/`vidx[]` and the
  partial-block accumulator from the marker's own length fields at `solve.c:15363`–`15385`, each
  guarded by `F1_CHECK`, **before** the trailing CRC32 is compared at `solve.c:15394`–`15396`.
  `F1_CHECK` is `exit(71)` (`solve.c:13172`–`13176`), so an allocation refusal terminates the
  process before both the CRC comparison and the unlink-and-rebuild path at
  `solve.c:15419`–`15422`, and the marker survives to abort every automatic restart identically.
  **Bounded honestly:** under default Linux overcommit the oversized `malloc` succeeds and the
  following short read rejects the marker as designed, so this needs a host that genuinely refuses
  the allocation — a `ulimit -v` or cgroup memory cap, or `vm.overcommit_memory=2`. The retracted
  wording was unconditional regardless of how often the escape fires. The recovery (delete the
  marker by hand) is now in the doc.

**3. The ~300 s snapshot cadence is a floor, not a bound on work at risk (`RP-f2905114`).**
- **BEFORE:** §Intra-layer checkpoint published it as a cadence, which reads as an upper bound on
  what a kill can cost.
- **NOW:** stated as *at chunk boundaries only, and no more often than ~300 s*. The test
  `do_kill || now - last_ckpt_wt >= CKPT_INTERVAL_S` sits **inside** the per-chunk loop, after the
  chunk's output has been pushed (`solve.c:15944`); `CKPT_INTERVAL_S` is 300 s at
  `solve.c:15734`, overridable by `SOLVE_F1_CKPT_SEC`. `chunk_cap` is derived from the scratch
  budget (`solve.c:15700`–`15703`) and nothing subdivides a chunk on time —
  `f1c5_build_ckpt_write` has exactly one call site, so there is no secondary time-triggered path.
  Worst-case loss is therefore one whole chunk, which a large `SOLVE_F1_OOC_SCRATCH_MB` on a slow
  layer makes arbitrarily long.

**4. `f1c5_progress.json` is boundary-triggered, not timer-refreshed (`RP-10357f26`).**
- **BEFORE:** the run-directory table described a periodic refresh.
- **NOW:** four emission points, named: layer begin (`solve.c:15617`), layer end (`:15640`),
  out-of-core chunk boundary (`:15963`), run completion (`:16542`). `f1c5_prog_emit` returns early
  when `!force && now - p->last_emit_wt < 5.0` (`solve.c:15533`–`15538`) — a minimum-interval
  **throttle**, not a timer. No `SIGALRM`, `setitimer`, `timer_create` or emitter thread exists in
  this path, so `updated_utc` is arbitrarily stale during a long non-out-of-core layer or a long
  chunk. **Operational consequence, now stated in the doc:** a watchdog keyed on `updated_utc` age
  kills healthy work; key on phase transitions instead. The upstream source comment at
  `solve.c:15473` carries the same error and is queued to the code lane — the doc inherited it.

**5. The full-ladder disk figure is a projection, and shipped as if measured.** No phrase is
retracted: the figure itself is unchanged and is the best one available. What was missing is its
evidential status. `≈2.5–2.7 TB` is now published as **projected**, with its basis inline —
**1.624 TB measured on disk at `k = 0..16`, 17 of the 32 layers, on 2026-07-23**, the remainder by
mask-palindrome projection, at v2 zlib level 6 and the default BLK. The measurement basis is
recorded in roae-private and is not reproducible from any shipped artifact: the run's
`runs/20260716_f1c5_c1c2c4c5_d128westus3/PRESERVE_SHA256.txt` holds six sha256 lines
(`f1c5_layer_30.bin`, `f1c5_layer_31.bin`, the manifest, `run.out`, `run.pid`, `done.marker`) and
**no byte sizes**, because the rolling window deleted layers 0–29 during the run. A measured total
would require a `SOLVE_F1_KEEP_LAYERS=1` full-31 re-run — a canonical-scale campaign, recorded here
as the reviewer's proposal and **neither proposed nor queued**. Both public sites moved together:
`F1C5_LAYER_FORMAT.md` §Rolling window and
[`SOLVE_C_CLI.md`](SOLVE_C_CLI.md) `SOLVE_F1_KEEP_LAYERS`. A third site, the source comment at
`solve.c:16130`, is queued to the code lane.

**6. The cold-storage archival hook can lose the layer it was invoked to save.** Two properties are
now stated in §Rolling window that the one-line description did not carry. (i) The command string
is passed to `system()`, i.e. to `/bin/sh`, with the layer path interpolated **unquoted** — the
format is literally `"%s %s %d"` (`solve.c:16085`–`16088`) — so a run directory containing a space,
quote or glob character does not reach the hook as two arguments. (ii) The hook's exit status is
logged but not acted on: `unlink()` of that layer runs three lines later regardless
(`solve.c:16367`–`16372` out-of-core, `:16439`–`16444` in-RAM), and the source comment says so in
as many words. Together, a hook that fails *because of* (i) loses the only local copy. **This
repository already knows the class:** `solve.c:17481`–`17486` records that quoting alone is
insufficient, validates `SOLVE_REGRESS_DIR` against an explicit safe alphabet at its source
(`regress_dir_safe`), and notes that "guarding only the first is how this defect class survives a
fix". The cold hook is an unguarded site of that same class. The code fix and a sibling sweep — two
further unquoted interpolations of an argv-supplied path at `solve.c:4131` and `solve.c:4181`,
against the quoted-and-validated `rm -rf` at `solve.c:17745` — are queued to the code lane, not
applied here. The doc now documents the hazard loudly, which is the other half of the prescribed
fix.

**Declined, and why.** The review proposed registering the ladder figure in
[CANONICAL_VALUE_STATUS.tsv](CANONICAL_VALUE_STATUS.tsv). It is not entered. That registry's own
header names `reports/METHODS.md`'s "Canonical quantities" table as its single source of truth and
instructs that a row be added *when METHODS gains a quantity*; a disk-sizing plan figure is not one.
GATE 5's status vocabulary is `exact`/`estimate`, so a `projected` row would be inert — it would
check nothing — while GATE 5b could raise fresh warnings on the `SOLVE_C_CLI.md` table the figure
sits in. The provenance is carried inline at every site instead, which is what the prescribed fix
asked for.

**What did not move.** No layer byte, no header field, no offset, no record size, no framing rule,
no sentinel, no count, and no `pl_hash`. Every structural claim touched in this pass was re-read
against the producing code and confirmed unchanged; the `chunk_cap` formula at §Intra-layer
checkpoint was re-derived from `solve.c:15700`–`15703` and is correct for this document's scope
(the G-band factor in the code is 1 outside `--f1-c3-hist`, which this document does not cover).

**Attribution.** The six defects were raised by the Codex V2-F37 review pass and adjudicated in
roae-private. The code measurements recorded above — the `system()`/`unlink` ordering, the
`f1c5_try_resume` census, the allocate-before-CRC ordering and the `exit(71)` path, the
single-call-site checks on `f1c5_build_ckpt_write` and the four-site census on `f1c5_prog_emit`, and
the `PRESERVE_SHA256.txt` inspection behind item 5 — are the Fable lane's (Claude). Reviewers are
acknowledged, not credited as authors.

---

## 2026-09-02 — SYMMETRY_SEARCH.md: an oriented leaf count called canonical, an orbit test called all-cells, a public-verifiability claim its own page contradicted, and two stale statuses

**Registry keys: `RP-92020fef`, `RP-35480bc8`, `RP-a5c2bc8c`, `RP-78ce5960`, `RP-60226f4a`,
`RP-11f9daff`, `RP-efc6640b`** ([documentation/RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv)).

Prose batch P33, from the Codex V2-F53 review of
[SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md). Six charges were filed; five were live and are corrected
below, one was already fixed and is recorded as declined. Every group-theoretic figure below was
recomputed for this entry from the constraint definitions by a clean-room walk over `verify.py`'s
`KW`/`PAIRS`/`hamming` — not read from a group table, and not taken from either shipped instrument.

### 1. `canonical leaves = 16,504` — the label names the wrong object (`RP-92020fef`, `RP-35480bc8`)

**BEFORE.** §"Empirical corroboration" item 2 and the `--estimate-knuth` code fence beneath it
published the exact-tree-isomorphism anchor as *"tree_nodes = 9,422,793 and canonical leaves =
16,504"* / *"leaves_canonical = 16,504"*. TR-5 §3(ii) carried the same wording at two sites.

**NOW.** 16,504 is an **oriented** C1–C5 leaf count. `solve.c`'s `exact_count` iterates
`for (int orient=0; orient<2; orient++)` over every pair and increments the counter it prints as
`leaves_canonical_C1C5` once per orientation-resolved C3-passing completion. SYMMETRY_SEARCH.md's
own §Result reserves *canonical* for the opposite object — "pair-sequences after orientation dedup" —
and its §Reproducibility snippet performs exactly that dedup with `frozenset`. So the document
contradicted itself, and the root is the shipped binary's field name, which the prose inherited.

The orientation-deduped count is **899 distinct pair orderings**, which this repository was **already
publishing**: `README.md` ("King Wen's alone among the 899 distinct pair orderings that those 16,504
oriented leaves represent") and this ledger's 2026-08-28 `TR-4:95–97` entry both state it. The defect
is that four sites did not propagate.

Recomputed 2026-09-02 by a clean-room DFS with a pair-ordering dedup added:

| KW-following prefix | tree_nodes | leaves C1+C2+C4+C5 | oriented C1–C5 leaves | distinct pair orderings |
|---|---:|---:|---:|---:|
| 5 free positions | 443 | 52 | 4 | **2** |
| 7 free positions | 62,256 | 5,624 | 2,232 | **381** |
| 9 free positions | 9,422,793 | 690,176 | 16,504 | **899** |
| 9 free, σ-related prefix | 9,422,793 | 690,176 | 16,504 | **899** |

The walk that produced this table is now **published**, in
[SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md) §Reproducibility, so every figure in it has a public command.
The first three rows reproduce `verify.py --recount-subtree`'s published anchors to the integer, from
an instrument that shares no code with it, and the fourth shows the tree isomorphism holds at the
pair-ordering level as well as the oriented level. The 899 is **not** new — see above. The 381 and the
2 appear to be published here for the first time: a prior-art check over roae-private `*.md`/`*.tsv`
and `codex_transcripts/`, roae `*.md`, and `git log --all -S` on both repositories returns
`PRIOR_ART=NONE` for "381 distinct pair orderings" and for "2 distinct pair orderings". Corrections
welcome.

**WHAT DID NOT MOVE.** No count. 443 / 62,256 / 9,422,793, 4 / 2,232 / 16,504 and the "exactly 8 of
the 16,504 satisfy C6/C7" anchor are all correct and all unchanged; only the noun they were given is.

**Not swept here, and named so it is not lost.** *"canonical leaves"* remains live and legitimate-looking
at ten further sites — `documentation/SEARCH_SPACE_SIZE.md`, `documentation/VERIFY.md`,
`reports/TR4_SIZE_OF_THE_SPACE.md`, `reports/TR1_EIGHT_CENTURIES_MEASURED.md`,
`documentation/SOLVE_C_CLI.md`, `documentation/LITERATURE_RULES_POPULATION_TESTS.md`, evidence READMEs
— plus `verify.py`, `verify.c`, `tests.py` and `solve.c`'s printf field itself. That relabel is one pass
and belongs with the `solve.c` field rename to `leaves_oriented_C1C5`, which is a code change and is
queued to the code lane; the registry needle is deliberately the `= 16,504` form so this gate does not
fail across the corpus while fixing nothing.

### 2. The "all-cells" orbit test measures 41.2% of the cells (`RP-a5c2bc8c`, `RP-78ce5960`)

**BEFORE.** *"**All-cells orbit test:** the 65,281 productive 560T cells partition into 4,183
G-orbits … True per-cell counts are orbit-equal within measurement resolution across the entire
space."*

**NOW.** Recomputed 2026-09-02 from the C2/C5 prune and from the 48 σ re-derived as the centralizer of
`rev` (order 48 confirmed, element orders {1:1, 2:19, 3:8, 4:12, 6:8}):

- the depth-3 feasible cell space has **158,364** cells;
- it is **G-closed** — every one of the 48 σ maps every feasible cell to a feasible cell, zero escapes;
- it falls into **4,382** ambient G-orbits, of sizes {6:14, 12:270, 24:1736, 48:2362} (6·14 + 12·270 + 24·1736 + 48·2362 = 158,364).

That computation is also **published** — [SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md) §Reproducibility now
carries it as a self-contained snippet that runs in under a second from the repo root, with the
G-closure check as an `assert`.

The 65,281 productive cells are **41.2%** of that space and are *not* G-closed, so the 4,183 measured
classes are **intersections of ambient orbits with the productive subset, not orbits**; 199 ambient
orbits contain no productive cell at all, and 93,083 cells carry no measurement. The invariance
statement is now scoped to the productive subset.

Both halves were already public in this repository before the review:
[SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md) §"What is being measured" gives "each of the 158,364
depth-3 cells" and §"Result — per-cell distribution + budgeted yield is uncorrelated with cell size"
says the remainder "lies in the ~93K cells that produced 0 records", and
SYMMETRY_SEARCH.md's own mechanism section concedes that "orbit-mates of productive cells are often
unproductive at a given budget". This was a zero-compute prose defect; the computation above was run
to state the ambient figures exactly, not to discover the gap.

**WHAT DID NOT MOVE.** The CV figures (0.112 median within-orbit, 0.130 median relerr, 0.72
population) and the 4,183 are unchanged; the 4,183 is read from the private per-cell table and is
**not** independently recomputed here, which item 3 now says on the page.

### 3. The promised public verification path rested on private inputs (`RP-11f9daff`)

**BEFORE.** §Reproducibility: *"The per-cell estimate table itself is private working data … this
rerun spec is the public path."* Four lines later, the provenance parenthetical: *"The theorem, its
proof, the correction notice, and every table needed to verify are public in this document."* Both
cannot hold.

**NOW.** The second sentence is withdrawn and replaced by a named split. Publicly reproducible: the
theorem and proof, the 720-permutation σ(KW) snippet, the exact-subtree commands, and — measured for
this entry — the **ambient** G-orbit partition, which recomputes in about a second from the
document's own published snippet. Not public: the **productive-cell list** (from the 560T shard
manifest) and the **per-cell estimate table** (~65K estimator calls). Verified for this entry: no
tracked file is a 65,281-cell manifest (the largest tracked `.txt`/`.tsv`/`.csv` is 5,490 lines), and
the only `4,183`/`within-orbit` hits in tracked `.py`/`.sh`/`.c` are `solve.py:7174` and
`solve.c:5649`, both about the unrelated Klein-four-group orbit structure — so no aggregation program
for this table is in the tree either.

The rerun command was additionally **machine-dependent**, which the review inferred and this entry
confirms from the source: `solve.c`'s `--estimate-knuth` parse block reads `SOLVE_THREADS` and falls
back to `sysconf(_SC_NPROCESSORS_ONLN)`, then splits the probe budget across workers seeded from
`knuth_seed_base` (`SOLVE_KNUTH_SEED`, default `0x243F6A8885A308D3`) — so the **thread count selects
the sample**, exactly as `reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md` v1.13 recorded on 2026-09-01
for its own five estimator commands. Both variables are now pinned in the published command, with the
reason stated; the exact-mode (`--estimate-knuth 0`) commands are deterministic and are left unpinned.

### 4. `rev` does not map every hexagram to its partner (`RP-60226f4a`)

**BEFORE.** §"Group structure": *"rev itself is the central element −I; it maps every hexagram to its
partner and therefore fixes every pair-sequence."*

**NOW.** False for exactly **8** hexagrams. EXECUTED against `verify.py`'s `_partner`:
`rev(h) ≠ partner(h)` for `{0, 12, 18, 30, 33, 45, 51, 63}` — the palindromes, which `rev` fixes and
whose C1 partner is their complement `h ⊕ 63` — and `rev(h) = partner(h)` for the other **56**. The
**conclusion survives**: `rev` fixes all 32 C1 pairs setwise (verified the same way), so it does act
trivially on pair-sequences and the record-level group is still B₃/{±I} ≅ S₄. The defect was the
stated reason, not the result, and the same document's Theorem proof already carried the careful form
("σ preserves the palindrome set and commutes with comp"). A whole-corpus scan, with line breaks
normalised, finds no second site.

### 5. Related-work status stale in both directions (`RP-efc6640b`)

**BEFORE.** §Related work ended *"full-text verification pending acquisition"*, and both the
§Theorem novelty note and the alignment note enumerated the algebra's arrivals as "at least five —
Goldenberg, Ouyang (1992), Schöter (1998), Suenaga (2012), Radisic (2026)".

**NOW.** (a) [CITATIONS.md](CITATIONS.md) has recorded since **2026-07-11** that Goldenberg (1975) was
read in full from an official interlibrary-loan scan and that all repo-encoded claims (G-T1–T4, T7,
including the KW5↔KW63-via-KW7 worked example, p. 170) are verified against the primary text. The
prose now says so. (b) The enumeration omitted **two** names the ledger credits — Yuan Zuoxing (1991)
and Cao Hongjun / Li Shuzhong / Liu Yanan (1995), added to the chain by the 2026-08-29 correction that
made ROAE the **seventh** arrival — and it listed Schöter inside the numbered chain, where the ledger
places him beside it as an *independent-then-crediting* arrival (he credits Goldenberg's ⊕ and ⊗ as
the direct parallels of his own operators while reporting that the bulk of his work predated his
awareness of Goldenberg). Both sites now reproduce the ledger's six pre-ROAE arrivals, state Schöter's
status as the ledger states it, and name CITATIONS.md as the list of record.

**Correction to the charge as filed.** The review read the ledger as *excluding* Schöter. It does not;
it excludes him from the numbering while calling him an arrival. That distinction is now carried on
the page rather than resolved by picking a side.

### 6. Declined — the stale stack-failure mode was already corrected

The sixth charge held that SYMMETRY_SEARCH.md still described the default-8-MB-stack
`--estimate-knuth` failure as a segfault before any output. **It does not, and has not since
2026-09-01**, when the entry three above this one corrected that wording at five sites including this
one. The site reads "since 2026-08-21 the binary preflights `RLIMIT_STACK` … and exits 1; previously a
bare SIGSEGV" and carries a dated 2026-09-01 correction marker; the retracted phrase survives nowhere
in the corpus but in that entry. The charge also offered a mechanical marker — that the stale sites
say "command **below**" and the corrected ones "command **in this document**". That correlation does
not hold: all four "below" sites (`SYMMETRY_SEARCH.md`, `SEARCH_SPACE_SIZE.md`, `TR4`, `TR5`) carry the
corrected long-form wording, and the two templates differ in length, not in currency. Nothing was
changed for this charge.

**Attribution.** The six charges were raised by the Codex V2-F53 review pass and adjudicated in
roae-private; reviewers are acknowledged, not credited as authors. The computations recorded above —
the clean-room subtree walk with pair-ordering dedup, the depth-3 cell census, the re-derivation of
the 48 σ and the ambient orbit decomposition, and the `rev`-vs-`partner` census — are this lane's
(Claude), and each is reproducible from `verify.py`'s public primitives.

## 2026-09-02 — TR-4: a withdrawn cross-check still live in the body, a premise its own table falsifies, a "measured" band with no measurement, stale calibration coverage, and completed work called queued

Five charges from the Codex V2-F06 review pass against
[`reports/TR4_SIZE_OF_THE_SPACE.md`](../reports/TR4_SIZE_OF_THE_SPACE.md), adjudicated in roae-private
and applied here as prose batch **P34**. All five were true and live. No measurement was re-run and no
count, estimate, CI or canonical value changed; what changed is what the prose claims about them.
Recorded as TR-4 v1.25.

### 1. The withdrawn 56-branch cross-sum was still published as evidence — at two sites, not one

TR-4 v1.22 (2026-08-27) scoped the 56-branch cross-sum out of the report's validation claim: its
per-branch values were never archived, the untraced-claims audit records the claim as NOT FOUND, and
an unreproducible cross-check strengthens nothing. **The withdrawal reached the abstract's marker and
stopped there.** The body — §Sections item 2 — still read "Independent cross-check: 56 per-branch
estimates …ing to 1.33×10³⁸ vs the independently-estimated whole-tree 1.32×10³⁸ (<1%)" — elided here
so the registered needle does not fire on this ledger — three lines below its own retraction.

The review named that one site. **There were three.**
[`SEARCH_SPACE_SIZE.md`](SEARCH_SPACE_SIZE.md) §Validation carried the same sentence, and
[`HISTORY.md`](HISTORY.md)'s 2026-07 narrative carried it in the past tense ("summed to"), a
morphology a needle on "sum to" would have missed. The SEARCH_SPACE_SIZE site invited a refutation
worth recording: it says the 56 estimates are "(below)", which would make the values public and the
withdrawal over-broad. **Checked, and it does not** — that section publishes exactly three order
statistics (min 1.26×10³⁶, median 2.26×10³⁶, max 3.46×10³⁶), from which no sum is recoverable. The
withdrawal stands at both.

Removed from TR-4 and SEARCH_SPACE_SIZE.md. HISTORY.md keeps the sentence, under a scope-out marker,
because it is the dated record of what was run rather than a live evidentiary claim — the same
treatment the other three withdrawn figures in that paragraph already carry. Registered as
**RP-3338fb66**, keyed on a morphology-independent stem that matches both the present and past tense
forms — the literal is deliberately not repeated on this page — with HISTORY.md as the allowed narrator.

### 2. "The maximum by construction" — falsified by a number twelve lines below it

§5's information-gain paragraph described the ~10.1-bits-per-boundary chain as having "the first being
the maximum **by construction**", and added that "unmeasured boundary synergies could beat the
single-boundary maximum, but five steps show none". The same section's Update prints the measured
gains for k = 1..8: **10.38, 9.64, 11.10, 9.40, 10.13, 8.64, 7.93, 6.14 bits**. k = 3 at 11.10 exceeds
k = 1 at 10.38. A conditional gain beat the unconditional one, and one of the five steps shows exactly
the synergy the sentence denies.

This is not a new finding — it is [TR-4 v1.15](../reports/TR4_SIZE_OF_THE_SPACE.md)'s own, recorded on
2026-08-01: "conditioning can increase information, and the greedy construction bounds no conditional
gain." v1.16 then recorded that v1.15's propagation was itself incomplete. **These two sentences are
what it did not reach.** Greedy maximises the *unconditional* single-boundary gain, which is true and
is all it establishes; the retired wording attached that guarantee to the whole five-step chain.

Both restated. The identical claim in [`SEARCH_SPACE_SIZE.md`](SEARCH_SPACE_SIZE.md)'s extrapolation
bullet — "the observed flatness across five steps shows no synergy at all so far", three lines after
that same bullet divides by 11.10 *because* step 3 exceeds step 1 — is corrected in the same pass.
Registered as **RP-7ec28c39**, **RP-0fa05509** and **RP-fa6c3b89**: three needles because the three
sites word one false premise three ways, and one loose needle would have left two live.

### 3. A ×15–17 robustness band with no measurement behind it

Three sites in TR-4 (§5, the figure alt-text, the figure caption), one in SEARCH_SPACE_SIZE.md and two
hard-coded literals in [`viz/report_figures.py`](../viz/report_figures.py) published a
weakest-remaining-boundary bracket as a **measured** ×15–17 per-boundary cut, the figure legend saying
so in as many words.

**MEASURED.** The tree ships exactly two S(k) artifacts,
[`reports/evidence/sk/sk5_7_rounds.out`](../reports/evidence/sk/sk5_7_rounds.out) and
[`sk8_round.out`](../reports/evidence/sk/sk8_round.out). Both are **greedy** chains — `round 5 PICK=2`,
`round 8 PICK=5` — with per-round selection sweeps. Neither contains a weakest-remaining chain; no
command producing one is published anywhere in the corpus; and "the weakest remaining boundaries" is
plural and nowhere defined against a candidate set, so even the object being claimed is unspecified.
`roae-private/scripts/prior_art_check.sh` on `weakest remaining boundaries` and `weakest-remaining-boundary
bracket` returns **PRIOR_ART=HIT n=41**, and every hit is either the same published string, a review
transcript quoting it, or the adjudication of this charge — no run log, public or private. The private
`sk_round_*.out` files that do exist are boundary-conditional probe outputs from a later task, not a
weakest chain.

**The band's own numbers are kept; only their status changes.** Deleting a figure a reader can see on
the published plot would be worse than labelling it honestly. All five prose/code sites and the figure
legend now read *illustrative, not reproducible from published material*, and §5 names the one public
datum that bears on the band: round 5's own selection sweep, whose largest-surviving candidate
(`cand 22: est=5.797785e+24`) is a **×14.5** cut against N(4) = S(4)·1.3287×10³⁸ = 8.42×10²⁵ — *below*
the published band's floor — while its second-largest (`cand 28: est=5.123237e+24`) is ×16.4, inside
it. The figure was regenerated from the edited generator; its PNG is otherwise byte-identical to the
shipped one, and the SVG differs only in its embedded timestamp and element ids.

Registered as **RP-77441d0d**, **RP-540f6cab** and **RP-51313d1a** — again three needles for three
wordings, and deliberately not a loose one on "measured", which is legitimate and correct for the four
S(k) points on the same figure.

**Left open, and named as open:** the reproduction command for this band does not exist, because the
run it would reproduce is not archived. Either the four weakest-chain round outputs are published with
their command, or the band stays illustrative. This is the honest state, not a temporary one.

### 4. Calibration coverage said 2 of 2; a third exact full-scale anchor has existed since 2026-07-26

TR-4's estimator-calibration section read "**Coverage: 2 of 2**" and "With **n=2** we can say the
estimator's envelope has held wherever it has been checkable". [`METHODS.md`](../reports/METHODS.md)
§"Canonical quantities" has recorded since 2026-07-26 that the C1–C7 layer with C3 dropped is **exact**
at **516,880,238,445,773,965,371,923,491,676,160**, two-instrument (an inclusion–exclusion pinned-step
recount and an independent mask-DP recount of a different algorithm class, agreeing on the integer),
and labels it in as many words "a **3rd independent estimator-calibration anchor**".

COMPUTED here from TR-4's own §4 estimate for that layer, 5.18×10³² ±0.25%: est/exact = **1.002166**,
a +0.2166% deviation, inside the stated band [5.16705, 5.19295]×10³². Added as a fourth table row with
the exact integer, the ratio, and both reproduction commands —
`./verify --ie-count --ie-spec full31@0 --ie-pin-c6c7 --ie-no-quotient` and
`./verify --dp-count --dp-spec full31@0 --dp-pin-c6c7`. Coverage is now **3 of 3** and n = 3.

Three consequences carried onto the page rather than left implicit. (a) The table's sixth column read
"Inside stated ±0.01%?"; the new row's envelope is ±0.25%, so the column is now per-row. (b) The
section said the exact values land "with roughly half the claimed error budget to spare" — true of the
two ±0.01% layers, but the new anchor consumes ~87% of its budget, and the sentence now says both.
(c) The new anchor is the **only** calibration on the C6/C7-pinned estimator path, which carries the
≈5.21×10³¹ uniqueness-refutation figure; and being itself C3-free it **sharpens** rather than softens
the standing caveat that C3's conditional ratio is the one full-scale factor with no exact cross-check.

**A fourth consequence the charge did not name, found while applying it.** The section's
"What this does NOT establish" paragraph argued that the deviations' shared positive sign is
indistinguishable from quoting precision, because the estimates are quoted to four and five significant
figures with rounding granularities ≈6.6×10⁻⁵ and ≈4.6×10⁻⁵ — the same order as the deviations. **That
argument does not extend to the third anchor.** 5.18×10³² is quoted to three significant figures, a
granularity of ≈9.7×10⁻⁴, and the deviation is +2.17×10⁻³ — about 2.2× it. The third deviation
therefore survives rounding and is a real signed one. It is still inside its stated envelope and it is
one point, so no bias is claimed; but the paragraph now says which layers its argument covers instead
of saying "both deviations" over a table of three.

**Refutation attempted.** The table is titled for layers "where ground truth exists", so a layer out of
its scope would not belong. It is not out of scope — ground truth now exists — and the row that still
reads "*none — no exact value exists*" is a different layer (C1–C5, C3 included), which remains
correct and uncalibrated.

### 5. Work completed on 2026-07-05 was still described as pending

§5's greedy-curve item ended "**queued**", and the information-gain paragraph ended "sharpens further
**when S(6..8) land**". The heading sixteen lines below the second is "### Update (2026-07-05): the
marginal-gain curve bends — **S(6)-S(8) measured**", and the same numbered item already cites that
measurement eight lines above its own "queued". The evidence is shipped: `sk5_7_rounds.out` ends
"S(6)=1.879066e20" and `sk8_round.out` ends "round 8 PICK=5 … SK8 COMPLETE". There is no reading on
which either was a live status. Both now point at the Update.
[`SEARCH_SPACE_SIZE.md`](SEARCH_SPACE_SIZE.md)'s two sibling sites already carried the corrected
status and were not touched. Registered as **RP-b1c1f805** and **RP-11166bb6** — the first with its
preceding context rather than on the bare word "queued", which is legitimate live status elsewhere in
the corpus.

**Attribution.** The five charges were raised by the Codex V2-F06 review pass and adjudicated in
roae-private; reviewers are acknowledged, not credited as authors. The arithmetic recorded above — the
est/exact ratio against the exact pinned integer, the ×14.5 and ×16.4 cuts read off the round-5 sweep,
and the k = 3 versus k = 1 gain comparison — is this lane's (Claude), and each is reproducible from the
published evidence files and the two `verify` commands named above.

**Not changed, deliberately.** The retired §Sections item 2 sentence sits beside "16,504 vs 16,422
canonical", which prose batch P33 established on 2026-09-02 is an **oriented** leaf count, not a
canonical one. P33 relabelled it at SYMMETRY_SEARCH.md and left ten further sites — TR-4 among them —
because the label's root is `solve.c`'s own field name, and relabelling the documents ahead of the
code would leave the two disagreeing. That decision is respected here; the site is reported, not
relabelled.

## 2026-09-02 — the boundary-stability pages were audited against their own shipped analyze logs, and five things did not survive

Five charges against `documentation/PARTITION_STABILITY_BOUNDARIES.md`, raised by the Codex V2-F44
review pass and adjudicated in roae-private. Every figure on the page survives: no count, sha,
survivor ladder or greedy-minimum size moves. What moves is scope, naming, and one published set
family that was wrong.

### 1. "Mandatory" is a stronger claim than any search that was run (`RP-813641e8`)

**BEFORE.** The page opened by calling `{25, 27}` **mandatory**, and its paper-implications bullet
asked §7 of the analysis paper to preserve their mandatoriness "as the genuine structural invariant".

**NOW.** MEASURED in `solve.c`'s `--analyze` block: §[7] exhausts all C(31, 3) = 4,495 triples and
§[8] exhausts all C(31, 4) = 31,465 quadruples, but **no C(31, 5) pass exists anywhere in the
binary**, and §[6]'s greedy scan compares with a strict `surv < best_remain`, so ties resolve toward
the lowest boundary index and it emits **one** deterministic path per dataset. At 100T and 560T
§[8] = 0, which fixes the minimum **size** at 5 — but the only 5-set ever scored is the greedy one.
The C(31, 5) = 169,911 five-subsets were never enumerated, no tied alternative greedy trajectory was
enumerated, and therefore **no 5-subset lacking 25 or 27 has been tested**. The page now carries a
scope paragraph saying exactly that, and states the claim as presence in the greedy representative at
each of the four partitions.

**Where it *is* settled, checked before rescoping.** At 10T the claim holds at size 4 by exhaustion:
`runs/20260418_10T_d3_fresh/analyze_output.log.gz` §[8] reports 25 and 27 at 100.0% frequency across
all 8 working sets, and both 10T logs print `Boundaries appearing in EVERY working 4-set: { 25 27 }`.
That exhausts size 4 at 10T and says nothing about size 5 at 560T.

**Not registered: the bare word "mandatory".** It is legitimate at 10T scope in ten other files
(`SOLVE.md`, `SOLVE_SUMMARY.md`, `CITATIONS.md`, `HISTORY.md` and others say "in every working
4-set", which is what §[8] proves). [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) has carried the
correct scope since 2026-09-01, when adjudication A01 accepted the identical charge against `:96`
and `:105`; this page missed that propagation.

### 2. The enumerated population was named by a shorthand the project retired a month ago (`RP-c938d088`, `RP-d691d304`)

**BEFORE.** [PARTITION_STABILITY_BOUNDARIES.md](PARTITION_STABILITY_BOUNDARIES.md) and
[BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md) each named the enumerated population with the legacy
three-constraint shorthand.

**NOW.** Both say **C1–C5**, and the first links the two notes that already ruled on it:
[METHODS.md](../reports/METHODS.md) §"Legacy shorthand" (2026-08-01 — "historical naming, not a
narrower constraint set … New text should say C1–C5") and [GUIDE.md](GUIDE.md) §Glossary. Confirmed
a naming defect rather than a scope error before changing anything: `solve.c`'s own comment on the
`solutions_c3` counter reads *"C3-valid" = passed ALL constraints (C1-C5), not just C3*.

**Correction to the charge as filed.** The review's class census listed `SOLVE_SUMMARY.md:288` and
`:320` as two more sites of the same defect. They are not. Both are statements about **three
predicates** in a null-model setting — `:288` reports the measured joint rate P(C2∧C3 | C1) ≈ 0.305%,
and `scripts/c2c3_joint_null.py`, the script it names, implements exactly C1, C2 and C3 with no C4 or
C5 anywhere in it; `:320` asks whether a published order-64 Costas array might satisfy those same
three. Rewriting either to "C1–C5" would make it false. The review's proposed gate needle — the
legacy shorthand in its `satisfies …` form — would in any case have fired on `:288`'s own
correction annotation, which quotes the withdrawn wording it is correcting. Neither site was
changed, and neither needle was registered.

### 3. A published 4-set family advertised seven sets that do not work (`RP-6d921792`)

**BEFORE.** The d3 10T working-4-set family was given as a shorthand union of `{25, 27}` with any
two of `{1..6}` — at three sites: this page, [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md) and
[SPECIFICATION.md](SPECIFICATION.md).

**NOW.** That shorthand admits C(6, 2) = **15** sets. `runs/20260418_10T_d3_fresh/analyze_output.log.gz`
§[8] reports **8** (`total working 4-subsets: 8`), so the shorthand advertised **7 that do not
work**: `{1,2}` `{1,5}` `{1,6}` `{2,6}` `{4,5}` `{4,6}` `{5,6}`, each ∪ `{25, 27}`. All three sites
now list the 8 verbatim.

**And the column header was wrong under it.** Both boundary tables ran a single "Greedy set" column
holding two different objects: the **single ordered set** §[6] selects, and the **family** §[8]
returns by exhaustion. The tables are now split. From the shipped logs: the d2 10T greedy walk is
`2 → 27 → 25 → 21`, the d3 10T walk `4 → 27 → 25 → 1`, and 100T and 560T are both
`4 → 27 → 25 → 21 → 1` — identical in membership and order, which is the claim the
560T row makes.

**Checked and left alone.** The d2 shorthand `one-of-{2,3} ∪ one-of-{21,22}` is **exact**: 2 × 2 = 4,
and the d2 log's §[8] reports `total working 4-subsets: 4` over precisely those sets. It was wrong
only in the column it sat in. `SOLVE.md`'s d3 10T section writes a similar summary but enumerates all
8 sets two lines above it and prints the per-boundary frequency table beneath, so there the summary
abbreviates a stated list rather than replacing one; it is unchanged and outside the registered
needle.

### 4. "Sourced publicly above" was false for the deepest row (`RP-96d7a817`)

**BEFORE.** The provenance parenthetical closed by asserting that the findings the document asks a
reader to accept are stated and sourced publicly on the page.

**NOW.** MEASURED: `canonical-archive/` does not exist in the tree,
`runs/20260608_560T_9a968fa2/` holds only `viz/`, and
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Access boundary" defines `canonical-archive/…` as
operator-held cold blob storage, "not public URLs". So `analyze_v3_560T.log` is not fetchable and
every 560T §[6]–§[8] figure on the page is a **transcription**. The page now says so, marks the two
`canonical-archive/` rows in its source table as operator-held, and distinguishes them from the d2
10T / d3 10T / d3 100T figures, whose `analyze_output.log.gz` files **do** ship in `runs/`.

**Correction to the charge as filed.** The review's title implied the 560T figures are unverified.
They are not. `roae-private/PRIMARY_EVIDENCE_SWEEP_2026_07.md:169–170` records a 2026-07
primary-evidence sweep that checked these exact figures against the operator-held log — the §[6]
560T survivor ladder 51,404 → 481 → 14 → 1 → 0, and §[7]/§[8] at all four scales.
This is a **publication gap, not a computation gap**, and the page now states the attestation and its
boundary rather than claiming a public source it does not have.

### 5. A node budget was repeatedly called a partition depth (`RP-91287bc7`)

**BEFORE.** The page described four enumerations as "progressively deeper partitions" and asserted a
result held "no matter the partition depth (10T to 560T tested)".

**NOW.** 10T, 100T and 560T are **budgets at one depth**.
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Reproducibility parameters" gives all three recipes as
`SOLVE_DEPTH=3`, differing in `SOLVE_PER_SUB_BRANCH_LIMIT` (63,146,557 → 631,456,644 →
3,536,157,207); the only partition-depth comparison the project has ever run is d2 vs d3, both at
10T. The page contradicted itself — its own §"Limits and scope" already said "partition-strategy is
held constant at d3 for the 100T/560T datapoints" — and
[SPECIFICATION.md](SPECIFICATION.md) fixed the identical defect in its own prose on 2026-09-01. The
source-data table's single "Partition" column, which mixed the two axes and is the likely origin,
is split into depth and budget.

**Attribution.** The five charges were raised by the Codex V2-F44 review pass and adjudicated in
roae-private; reviewers are acknowledged, not credited as authors. The measurements recorded above —
the `solve.c` §[6]–§[8] source read (greedy tie-breaking, the absence of any C(31, 5) pass), the
transcription of §[6] and §[8] from the three shipped `analyze_output.log.gz` files, the
`c2c3_joint_null.py` predicate check, and the `runs/` / `canonical-archive/` tree audit — are this
lane's (Claude) and every one of them is reproducible from files in this repository.

## 2026-09-02 — TR-6: a KW-derived premise sold as an unconstrained fact, a stale superlative, an unreproducible experiment, and a sufficient stack setting published as a necessary one

*(Codex V2-F08 #1–#4, prose batch P37. No theorem, count, mass, certificate or verdict changes anywhere
below; every change is to what the prose CLAIMS about premises, rankings, reproducibility and
requirements. Two of the four charges turned out to be partly already-fixed classes and one turned up a
fifth site the charge did not name — recorded as such rather than silently absorbed.)*

### 1. A forcing claim conditioned on a constraint read off King Wen (`RP-a1101ab8`, `RP-8cf62ef8`)

**BEFORE.** Four sites presented the 15-alternation count as forced against an **unconstrained** arranger:
TR-6's Executive summary called it a mathematical law rather than an aesthetic choice, its Abstract denied
it was a King Wen decision, §5(d) called the parity profile something the arranger receives rather than
picks, and [PARITY_ALTERNATION.md](PARITY_ALTERNATION.md) — the proof document TR-6 cites — said the same.
The three retired wordings are keyed above and deliberately **not** restated here, so GATE 3 binds these
sites rather than exempting the ledger that describes them.

**NOW.** All four sites state the premise. The theorem's 15 comes from C5's odd-distance count, and
[reports/METHODS.md](../reports/METHODS.md) grades C5 "Extracted from KW (confirmatory, not
predictive)" — so "forced" is relative to KW-derived constraints, not to an unconstrained arranger.
This is not a new finding: [TR-7](../reports/TR7_CIRCULAR_READING.md) §3 made exactly this correction on
2026-07-20 (v2.1, adversarial-review F-14a — "the prior phrasing smuggled the KW-derived constraints in
as premise"), and in the two months since it reached **zero of the four sibling sites**. The retired
phrasings are registered so the gate, not the next reviewer, holds the class.

### 2. A superlative that its own ledger had already retired (`RP-56313583`)

**BEFORE.** TR-6 §6 credited Schulz (1990) with "the strongest measured literature discriminator",
unqualified.

**NOW.** "…the strongest measured literature discriminator **at the time of the SAT work** (×11,364),
later exceeded by the data-like S25–28 configuration at ×5×10⁷", with the pointer to
[LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md), headline finding 1
("A new strongest discriminator"). [CITATIONS.md](CITATIONS.md) has carried the qualified ranking all along and is
unchanged. **The sibling the charge named is already fixed:** the same unqualified superlative was
corrected inside LITERATURE_RULES_POPULATION_TESTS.md on 2026-09-01, so TR-6 was the last live site, not
one of two. The needle registered for this class is deliberately trailed by the following comma-word,
because the bare superlative is *correct* prose at CITATIONS.md — where it spans a line wrap and so
matches once GATE 3 flattens. A general superlative gate is the durable fix and is queued, not claimed.

### 3. The cardinality-only subset experiment has no public reproduction command (`RP-713f9cf6`, `RP-cb49f826`, `RP-1efe0dbb`)

**BEFORE.** TR-6's 2026-08-29 correction marker justified retracting the SAT leg's independence by an
experiment — extracting each CNF's ordering-variable-free clause subset and showing it UNSAT alone — that
the repository does not contain. `sat.py` has no subset-extraction flag; `reports/certificates/` holds the
two full-encoding proofs and no subset CNF, subset proof or extractor; `verify_all.sh` regenerates only
the full targets. TR-6's own banner promises that every MEASURED result carries a reproduction command.

**NOW.** The gap is stated on the page, in its own paragraph beneath the banner (the banner is shared
boilerplate byte-identical across all eleven TRs and enforced as such, so it is not TR-6's to amend — the
same construction TR-9 used for its two Knuth estimates on 2026-09-02). The subset run was in fact
performed and is recorded in this project's private working notes, with solver version and per-target
clause counts; that is disclosed, and so is the fact that a private note is not a reproduction command.
**The finding it supports does not depend on the missing artifact**, and the page now says why: the same
conclusion follows from *reading* the tracked `sat.py`, where `BETWEEN_MULTISET` fixes 2 between-pair
slots at d=1 and 13 at d=3 and the encoding defines `odd[s]` as `T[s,1] ∨ T[s,3]`, so |odd| = 15
identically. Shipping the extractor and the two subset certificates is queued, not done.

**The propagation half of this charge was already four-fifths done — and the missing fifth was not on the
charge's list.** README.md, [CLAIMS_DECIDED.md](CLAIMS_DECIDED.md),
[CLAIM_TO_ARTIFACT.md](CLAIM_TO_ARTIFACT.md) and LITERATURE_RULES_POPULATION_TESTS.md all already carried
the 2026-08-29 retraction. [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) §4 did not, and is
corrected here. It survived every propagation pass for the same reason the 2026-08-01 conflict-theorem
scope did: the phrase **spans a hard line wrap** ("(third⏎independent verification"), so no line-based
grep for it could see it. It was found only by flattening the corpus before matching — the check GATE 3
performs and reviewers do not. Three needles are registered for this class; until today **none existed**,
so the gate had been blind to the retraction for the whole of its life.

### 4. A sufficient stack setting published as a necessary one, at fifteen sites (`RP-21300ed8`)

**BEFORE.** Eleven documents carried a banner declaring the `unlimited` stack setting a requirement of
every `--estimate-knuth` command (retired wording keyed above, not restated), and four more said the same
in their own words
([VERIFY.md](VERIFY.md)'s requirements table, [GUIDE.md](GUIDE.md),
LITERATURE_RULES_POPULATION_TESTS.md's scoreboard note, and
[reports/evidence/r11/PHASE2_README.md](../reports/evidence/r11/PHASE2_README.md)).

**NOW.** All fifteen state what the binary enforces: **at least 16 MB**, of which `ulimit -s 16384`
suffices and `unlimited` is one sufficient setting. `solve.c`'s `--estimate-knuth` preflight tests
`rlim_cur != RLIM_INFINITY && rlim_cur < 16UL*1024*1024` and its message names ">= 16 MB"; executed under
TR-9 v1.24 on a locally built binary, `ulimit -s 8192` refuses and exits 1 while `ulimit -s 16384` runs
the estimator to completion. The published requirement was therefore a **false blocker** on any host or
container whose hard limit forbids `unlimited`. TR-9 narrowed its own site on 2026-09-02 and reported the
siblings without sweeping them; this is that sweep. `solve.c`'s own remedy line still prescribes only
`unlimited` and is queued — it is a defect of helpfulness, not of correctness, since the setting it names
does satisfy the requirement. Four of the eleven banners also carried a 2026-09-01 tail asserting the
requirement "is unchanged and remains mandatory"; that sentence was true of the failure-mode correction it
belonged to and false of this one, and is rescoped rather than deleted. Note the two classes stay
disjoint: the older `RP-` row retracting the SIGSEGV failure *mode* had carried a standing caution that
this requirement was true and must never be swept, which is corrected in the registry itself.

**Attribution.** The four charges were raised by the Codex V2-F08 review pass and adjudicated in
roae-private; reviewers are acknowledged, not credited as authors. The work recorded above — the
`sat.py` encoding read (`BETWEEN_MULTISET` = {1:2, 2:8, 3:13, 4:7, 6:1} and the `odd[s]` clauses, both
verified against the tracked file), the `reports/certificates/` and `verify_all.sh` inventory, the
flattened-corpus sweep that found the TR-1 survivor, and the fifteen-site stack census — is this lane's
(Claude), and every one of them is reproducible from files in this repository.

## 2026-09-02 — TR-7: a symmetry claim C3 refutes, an "independence" check that shares half its probes, an enrichment split resting on an unproved uniformity, and a prior-art note that outran its own citation

Four charges against [`reports/TR7_CIRCULAR_READING.md`](../reports/TR7_CIRCULAR_READING.md), raised
by the Codex V2-F09 review pass and adjudicated in roae-private. No measurement, theorem, canonical
sha or wrap mass moves. Two published *ratios* move, and both are recomputations from figures the
report already prints. One charge was applied in part and refused in part, on the record below.

### 1. Rotations are not symmetries, because C3 is not rotation-invariant (`RP-ed80aa5e`)

**BEFORE.** §6 closed with a symmetry aside: without C4, a circular system "would be
invariant under the 32 pair-slot rotations" as well as the B₃ relabelings. The same sentence stood at
[`documentation/CIRCULAR_KING_WEN.md`](CIRCULAR_KING_WEN.md) §"Symmetry under closure".

**WHY IT IS FALSE.** C3 is an absolute-position functional — Σ over all v of |pos[v] − pos[v^63]|,
with the ceiling 776 set by King Wen's own value — so rotating the sequence moves it. Both documents
foreclosed their own escape four lines earlier by stating that "C1, C3, C4 are position/pair
properties, unaffected by closure": *unaffected by closure* is not rotation-invariance, and keeping C3
linear is exactly what breaks the group action. A genuinely circular system might also circularize C3
(minimum circular displacement), which would be rotation-invariant — but neither document does that.

**MEASURED**, on two derivations inside `verify.py` that agree on every value: `c3_of_ordering`, which
reads the pair-slot map only, and `compute_comp_dist`, which walks the reconstituted 64-hexagram
sequence. C3(KW) = 776; rotate-4 = 888; rotate-16 = 1240; maximum 1320, minimum 664; **21 of the 31
non-identity pair-slot rotations exceed 776**, and only 10 survive. The circular transition multiset
{1:2, 2:20, 3:14, 4:19, 6:9} is preserved *exactly* under rotation, so C1, circular C2 and C5 all
survive it and **C3 alone breaks it** — dropping C4 yields no C₃₂ action on the C1–C5 space at all.

**REPRODUCTION** (seconds, no build):

```
python3 -c "import verify as v; c=v.c3_of_ordering; r=lambda k:[(s+k)%32 for s in range(32)]; print(c(r(0)), c(r(4)), c(r(16)), sum(c(r(k))>776 for k in range(1,32)))"
```

prints `776 888 1240 21`. The command is now in TR-7's Verification Guide and in CIRCULAR_KING_WEN.md.

**AFTER.** Both sentences state the C3 exclusion and the 21-of-31 count; both files carry the caveat
that C3's immunity to *closure* is not immunity to *rotation*. The phrase "invariant under the 32
pair-slot rotations" is registered as `RP-ed80aa5e` on its **bare** form, and both corrected sentences
were reworded to "the 32 pair-slot rotations would be symmetries of …" so the conditional truth is
still sayable. The bare form was chosen because this class recurred: an earlier adjudication accepted
the identical charge at the TR-7 site, nothing landed, and a second reviewer refiled it at the
CIRCULAR_KING_WEN.md sibling. A needle that only covered TR-7 would not have stopped that.

### 2. The published uncertainty statement rested on two runs that share half their probes (`RP-3d9ad619`)

**BEFORE.** The abstract, §5 and the Verification Guide all said the same thing three ways: the
instrument prints point masses with no per-class CIs, so the published uncertainty for the
wrap-distance masses 17.5 / 65.2 / 17.4% is the agreement of the f11 primary and the r6 rerun —
"two independent draws agreeing within 0.05 percentage points per class, which bounds the run-to-run
scatter".

**WHY IT IS FALSE.** The two runs are not independent. `reports/evidence/f11/f11_runA.out` is
`probes=20000000000 threads=32`; `reports/evidence/r6/rc1c_primary.out` is
`probes=20000000000 threads=64`; and `grep -c 'SEED OVERRIDE'` returns **0 in both**, so both ran on
the fixed base seed. The estimator splits `per = n_total/nthreads` and seeds worker *i* as
`base ^ ((i+1)·0x9E3779B97F4A7C15)` — by thread **index** alone, with no dependence on the thread
count. 2×10¹⁰ divides evenly by 32 and by 64, so threads 0–31 of the 64-thread run replay the first
312,500,000 draws of threads 0–31 of the 32-thread run: **10×10⁹ of each run's 20×10⁹ probes are
literally the same probes.** The 0.05-percentage-point agreement is arithmetic, not evidence.

The companion premise was separately stale. Per-class `se=` landed for every published mass family,
the wrap-distance masses included, on **2026-08-28** ([METHODS.md](../reports/METHODS.md)
§"Statistics conventions"); only the 2026-07 archived artifacts predate the field, and neither carries `se=`.

**AFTER.** All three sites now say that **no ± figure is published for these masses**, name the r6 run
a partially overlapping replicate rather than an independence check, and date the `se=` field. The
mass values themselves are untouched. Quoting a real run-to-run scatter needs reruns under distinct
`SOLVE_KNUTH_SEED` values; that is stated as open, not as done.

### 3. The enrichment split converted an eligibility *support* into a probability (`RP-f21d636c`)

**BEFORE.** §"The anchors on the circle" priced Cook's final-pair anchor as: against the naive
1/31 ≈ 3.2% the measured 7.84% is a ×2.4 enrichment, of which — against the "parity-forced eligibility
baseline" 1/16 = 6.25% — ×1.9 "is parity-forced" and ×1.25 "is the contingent residual".

**WHY IT IS FALSE.** The wrap-parity theorem restricts the closing pair to a 16-element **support**.
Turning that into a probability of 1/16 requires exchangeability across those 16 pairs, which the
report does not prove — T2ii states eligibility as *necessary* only, and the per-pair spread inside a
class is unknown except for A₂ — and which the report's own measurements contradict: the measured
class masses are 65.2 / 17.5 / 17.4% against the counting baseline 62.5 / 18.75 / 18.75%. The
paragraph does hedge two lines above ("the baseline is a heuristic reference, not a null"), then
states the split in unhedged causal language anyway; that contradiction is the defect.

**COMPUTED** from figures the same paragraph already prints — no new measurement. A₂ carries 7.84%
against a **6.52%** d = 3 class average. So 6.52 / 3.2258 = **×2.02** of the apparent enrichment
tracks class structure, and 7.84 / 6.52 = **×1.20** is the A₂-specific residual; the two compose to
7.84 / 3.2258 = ×2.43, the ×2.4 observed.

**AFTER.** The split is stated as ×2.02 · ×1.20 against the measured class average, and 1/16 is
relabelled a reference rather than a null.

**NOT CHANGED, and visible rather than whitelisted.** Two sibling sites state the same counting split
— [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) §2(d) and
[LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md) §3. They are adjudicated
separately and are **still live**. `RP-f21d636c` is registered on TR-7's specific word order, "of that
apparent enrichment ×1.9 is parity-forced", rather than on the bare figures, precisely so that the two
outstanding sites stay outstanding: a bare-figure needle would have forced an allow-row for each,
which is whitelisting a known defect. TR-7 §"The anchors on the circle" now names both as outstanding
in its own text.

### 4. The Meyer prior-art note asserted content its own citation says cannot be re-verified (`RP-b5267deb`)

**BEFORE.** §"Prior work note" stated flatly that Peter Meyer (1998, web) "published the complete
cyclic line-change sequence of the King Wen order … with an explicit XOR-and-popcount formalization",
and that "His data thus contains the wrap value d=3 this report analyzes, decades before this work."

**WHY IT OVERRAN THE CITATION.** The source is unrecoverable. `serendipity.li/dna/kws.html` returned
404 on re-check 2026-08-01 (the site root is still live, so the page was removed) and the Internet
Archive holds **zero captures of it** — both the Wayback availability API and a CDX query come back
empty. [CITATIONS.md](CITATIONS.md) also records that an earlier attempt to source Meyer's priority
quoted a *McKenna*-authored page and "was circular, and it is withdrawn". The report carried none of
that: it stated the content as established prior art with no indication a reader cannot check it.

**AFTER.** The note marks the read unrepeatable, gives the 404 and the zero-capture result, links the
CITATIONS.md entry including the withdrawn circular attribution, and credits the wrap value and the
absence of distance-5 **as stated claims** to McKenna & McKenna (1975), which is in print and citable.
No ROAE novelty claim rested on the Meyer entry before or after; this is an over-attribution to a
third party, not a novelty overclaim.

**REFUSED, and why.** The charge named three sites and proposed rewriting all of them to say the
project "cannot verify its content". Two of the three — CITATIONS.md's `meyer1998` entry and its
§"C5's axis" stub — were **not** changed, because that rewrite would have made a true record false.
Their live text says the content was **read first-hand on 2026-07-04**, before the page went, and that
the project "can no longer **re**-verify" it, with both sites flagging the read as unrepeatable by a
reader. That framing landed in the 2026-09-01 prose sweep, after the charge was drafted; the charge
quotes the pre-sweep wording. Deleting the dated first-hand read would erase a real provenance fact in
the name of caution. The TR-7 site, which had no hedge at all, is the one that was live and is fixed.

**Attribution.** The four charges were raised by the Codex V2-F09 review pass (charge 1 refiled
against the CIRCULAR_KING_WEN.md sibling as V2-F32 #1) and adjudicated in roae-private; reviewers are
acknowledged, not credited as authors. The measurements recorded above — the two-instrument C3
rotation sweep, the `SEED OVERRIDE` and thread-count audit of the two archived artifacts, the
estimator's seeding and probe-splitting read, the `se=` landing date, and the ×2.02 / ×1.20
recomputation — are this lane's (Claude), and every one of them is reproducible from files in this
repository.

## 2026-09-02 — TR-5's summary claimed the one thing its own scope note leaves open, and its banner's reproduction promise fails three times

Four charges against [reports/TR5_SYMMETRY.md](../reports/TR5_SYMMETRY.md), raised by the Codex V2-F07
review pass and adjudicated in roae-private. **No count, theorem, group order, orbit size or estimate
moves.** What moves is the scope the executive summary states, and how the page describes the evidence
behind three of its results. Two of the four charges arrived already fixed by earlier batches and are
recorded here as a census correction rather than as a change.

### 1. The summary stated the solution-set result the report does not have (`RP-d11cce62`, `RP-376ec746`)

**BEFORE.** The executive summary announced the order-48 group as the *complete set of the symmetries*
that carry one valid ordering to another, and described the 23 twins as indistinguishable in a way it
attributed to the rules themselves rather than to relabeling.

**WHY IT IS WRONG — and why the reviewer understated the proved result while doing so.** The charge said
the report establishes only "a particular 48-element subgroup". Measured, that is false and the truth is
stronger: [SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md) §Completeness proves the classification over **all
64! hexagram relabelings** (C4 forces σ(63)=63 and σ(0)=0; C2's distance-5 witness family forces
σ ∈ Aut(G₅), order 46,080; the fix-0 and partner-commuting filters cut that to 48), and TR-5 §1 states
this correctly. The defect is narrower and real: §1 also records the limit — *the solution-set
automorphism group is bounded below by G and not decided above*, a per-predicate scope repeated in the
v2.0 revision row — and the summary dropped that qualifier at two sites while the body carried it at
three. The second of the two summary sites was the sharper one: describing the twins as
indistinguishable *to the rules* is the solution-set-automorphism reading verbatim, which is exactly the
question §1 leaves open. A narrow reading rescues the first site (if "such symmetries" is read as
"relabelings" it is true); nothing rescues the second.

**AFTER.** The summary now says the report works out the complete set of such **relabeling** symmetries
— a group of 48, complete over all 64! hexagram relabelings, with §1 named — and states the twins result
as "23 twins that no hexagram relabeling can distinguish", followed by the open question in plain words:
whether some map on the solution set not induced by a hexagram relabeling could tell a twin pair apart
is undecided. Both retired phrasings are registered in
[RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) at the keys above.

**NOT REGISTERED, deliberately.** The companion wording that attributes the indistinguishability to the
rules is live at `documentation/SOLVE_SUMMARY.md` in a **qualified** form, where its subject is
*relabelings* and the sentence therefore says only that the C1–C5 predicate is relabeling-invariant —
which is true and proved. Registering the short needle would have failed GATE 3 on correct prose. The
census in the charge named one file; a whole-corpus flattened scan finds two sites, of which one is
sound.

### 2. The banner promises a reproduction command for every MEASURED result; three TR-5 results have none

**BEFORE.** The report's banner carries the suite-wide promise about reproduction commands. Three of its
results do not keep it: §3(ii)'s exact-tree-isomorphism claim covers four σ-related prefixes and the
Verification Guide publishes runnable commands for two of them (`verify.py --recount-subtree` encodes
the same one σ); §3(iii)'s orbit and within-orbit-CV statistics have no aggregation script and no
archived per-cell estimate table — SYMMETRY_SEARCH.md §Reproducibility itself names the productive-cell
list and the per-cell table as private working data; and §5's twins-absent bisection has no shipped flag
and no result artifact. A private reproducibility audit graded the CV item the weakest TR-5 item in
2026-07 and the promise was left standing.

**AFTER, and what was REFUSED.** The banner is **not** edited. `scripts/doc_gates.sh` **GATE 9 requires
the report banner byte-identical across every `reports/TR*.md`**, so softening it in TR-5 alone fails the
gate, and softening it everywhere is a claim about eleven reports this pass has not audited — the same
promise was separately charged against TR-9 and is likewise open. That sweep is queued, not performed.
Instead each gap is flagged where the result is stated: §3(ii) and §3(iii) each gain a *Reproduction
status* note, and the Verification Guide gains an entry for the CV test — which it had never listed at
all — and marks the twins bisection a prose recipe rather than a command. A reader can now see which
figures on the page are re-derivable from this repository and which are not.

**Not claimed here.** An exhaustive all-48-σ replacement for §3(ii)'s three-σ sample was proposed in the
adjudication and is *not* published: no generator ships, so the figure would arrive ahead of its
reproduction command. It is queued to the code lane with the CV aggregation script and a
`verify.py --twins-bisect` flag. The third charged bullet was **overstated** by the reviewer — the 24
record keys are derivable in under a second from the published snippet and the sort key specified in
[SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) §Sort order, so what is missing is a shipped command and an
artifact, not the information.

### 3 and 4. Two charges arrived already fixed — census correction, both directions

The oriented-versus-canonical leaf mislabel was charged at four TR-5 sites. Measured: two were the
§3(ii) body sites and were relabelled by prose batch P33 on 2026-09-02 (see this ledger's entry for that
pass); a third carries no label at all and never needed one; **the fourth, which P33's own record did not
count, was the v2.7 revision row 70 lines below the body** — the correction had reached the prose and
stopped short of the history that describes it. That row now matches the body. The bare label remains
live and **deliberately deferred** at the ten sites named earlier in this ledger, pending the `solve.c`
field rename; it is not registered, because a needle for it would fail across the corpus while fixing
nothing.

The `--estimate-knuth` stack charge — that `unlimited` is published as required and that the sub-16 MB
failure mode is a segfault — was **fully fixed before this pass**: the failure mode by prose batch P48
on 2026-09-01 and the necessity claim by prose batch P37 on 2026-09-02, whose registry row already gates
the class corpus-wide. A flattened whole-corpus re-scan on 2026-09-02 finds no surviving site of either
wording outside the ledger, the registry and dated historical clauses. No change was made for it.

**Attribution.** The four charges were raised by the Codex V2-F07 review pass and adjudicated in
roae-private; reviewers are acknowledged, not credited as authors. The measurements recorded above — the
flattened whole-corpus scans that produced both census corrections, the GATE 9 byte-identity constraint
that refuses the banner edit, and the reads of `verify.py --recount-subtree`, SYMMETRY_SEARCH.md
§Reproducibility and SOLUTIONS_FORMAT.md §Sort order — are this lane's (Claude), and every one is
reproducible from files in this repository.

## 2026-09-02 — BOUNDARY_MINIMUM.md: a record index quoted across datasets, a measure quoted across conventions, and a record count quoted as a depth

*(Codex V2-F31 #1–#4, prose batch P39. No count, sha, survivor ladder, greedy-minimum size or set
membership moves anywhere below; every change is to what an identifier, a measure or a ratio is
qualified as holding over. One of the four charges arrived already fixed, one census expanded from one
site to four, and one sibling sweep was carried in that no charge named.)*

### 1. Charge #1 arrived already fixed — census correction, downward

The first charge held that the result table's "Greedy set" column conflated the §[6] greedy result with
the §[8] unordered family at the two 10T rows, and that the d3 10T family was published as a 15-set
shorthand for an 8-set result. Both were true when the charge was drafted and **both were fixed on
2026-09-02 by prose batch P35**, whose ledger entry is `RP-6d921792` earlier on this page: the table now
runs separate "Greedy set (§[6], in greedy order)" and "Working 4-sets (§[8], exhaustive over C(31,4))"
columns, and lists the eight d3 10T sets verbatim. Re-verified against the shipped logs before
concluding that, rather than taken on the ledger's word — `runs/20260418_10T_d2_fresh/analyze_output.log.gz`
§[6] gives `2 → 27 → 25 → 21` and §[8] `total working 4-subsets: 4`;
`runs/20260418_10T_d3_fresh/…` §[6] gives `4 → 27 → 25 → 1` and §[8] the eight sets, in the order the
page prints them; `runs/20260419_100T_d3_d128westus3/…` §[6] gives `4 → 27 → 25 → 21 → 1` and §[8] `0`.
**No change was made and no needle was registered for this charge.**

### 2. A `rec#` index was qualified as holding across datasets (`RP-c79db9ce`, `RP-926ac304`)

**BEFORE.** The page named the hardest-to-kill King Wen impostor `rec#330177707` and qualified that
literal as holding "at every tested depth" (headline) and "at both canonical scales" (§What this
implies). A third site carried the literal in a paper-implications bullet spanning both canonical
scales.

**NOW.** A `rec#` is a position in **one dataset's own sort order** and does not survive a change of
dataset. MEASURED: `grep 330177707` over
`runs/20260419_100T_d3_d128westus3/analyze_output.log.gz` returns **0 hits**. What is stable is the
*ordering* — King Wen with the pair blocks at positions 2 and 3 interchanged — and it is indexed
`rec#330177707` at d3 560T, `rec#104178045` at d3 100T (§[24] row 12: `[ 12] dist=2 rec#104178045:
pos2=2 pos3=1`) and `rec#21262918` at d3 10T (§[24] row 10). The page now names the swap, lists all
three indices against their datasets, and says at both sites that the index is dataset-relative.

**A second reason not to quote the number across scales.** `104178045` also appears in the same 100T log
as boundary 1's discriminating count (3.0351% of 3.43 B) — a different quantity that happens to share the
integer. A reader grepping the figure across scales can land on either.

**The companion figure was per-dataset too, and the charge caught it in passing.** "One of the **14**
dist-2 records" is a 560T count. §[24] holds **10** dist-2 records at d3 10T and **12** at d3 100T. The
sentence had scoped its *log* to 560T but not its *number*, so the 14 read as scale-free. The page now
gives all three counts and states that the 100T half of the check is publicly reproducible — the 100T
`analyze_output.log.gz` ships, prints the §[24] row above, and prints `Step 4: Boundary 21 eliminates 6,
1 remain` in §[6] — while the 560T half is a transcription.

**Census correction, upward.** The charge named one site. Four carry the literal in this file: the
headline, the §What-this-implies paragraph, the paper-implications bullet, and the 560T survivor-curve
paragraph. The first three were qualified across scales and are corrected; **the fourth was left alone
deliberately** — its sentence opens "The cumulative-survivor curve for d3 560T's greedy set", so the
560T index is the right one there and rewriting it would have removed a true statement. Two needles, not
one, because the two defective sentences share no wording: the headline says "at every tested depth" and
the body "at both canonical scales", and one needle would have missed the other. The **bare** literal is
not registered — it is correct prose at 560T scope in eight other files.

**Noted, not changed, and outside this file.** [CLAIMS_DECIDED.md](CLAIMS_DECIDED.md)'s row for the
boundary-minimum correction calls `rec#330177707` "the lone 4-boundary survivor" in a sentence whose
subject is the identical 5-set "at 100T and 560T". That is the same reading, one step weaker, and is
queued rather than edited: the row is mirrored verbatim in
[CORRECTIONS_INVENTORY.tsv](CORRECTIONS_INVENTORY.tsv) and the two must move together.

### 3. The historical 742M row was not the measure the column header names

**BEFORE.** §What is being measured defines Measure B as the count of unordered 4-subsets whose
conjunction "reduces survivors to **≤ 1**". The result table gave the historical 742M row a (B) of
**4**, in that column, with no qualifier. The page caveated the *dataset* three paragraphs above; it
never caveated the *measure*.

**NOW.** MEASURED in `enumeration/analyze_c_742M.txt`: §[8] is headed *"All 4-subsets that reduce
survivors to `<=4`"* and lists four sets each reporting `survivors=4`; §[7] likewise tests "Triples
reaching `<=4` survivors". The `<=4` is the pre-format-v1 convention, and §[4] of the same log says why —
`KW records found: 4`, because that dataset held King Wen as **four un-deduplicated orientation
variants** (varying at positions 2, 3, 28, 29, 30). So "survivors ≤ 4" there carries the meaning
"survivors ≤ 1" carries on an orientation-deduplicated canonical, and under this document's literal
definition the 742M value would be **0** — King Wen alone accounts for four survivors in that dataset.
Footnote ² now states the threshold, the reason for it, and the value under the page's own definition;
the table cell is marked.

**Checked before writing it, and it narrows the claim.** §[6] on the same log **is** directly comparable,
because it counts *non-KW* survivors: it reaches 0 with `{2, 21, 25, 27}`, a greedy minimum of 4. The
convention gap is confined to Measure B. The greedy-minimum cell for that row is left as "—" and was not
filled in; that is a separate editorial question about how far a bug-era dataset should be presented
alongside four sha-anchored canonicals.

**No needle registered, and why.** The defect is an **omission** — a missing qualifier — not a phrasing
that can be banned. A needle on the table row would be brittle against any unrelated table edit and would
protect nothing. What is wanted is a positive-assertion gate (any row citing `analyze_c_742M.txt` must
state the `<=4` threshold within its paragraph); `scripts/doc_gates.sh` is under concurrent edit by
another lane, so the gate is queued in `roae-private/PROSE_LANE_FOLLOWUPS.md` rather than added here.

**Census, checked outward.** Two sibling sites quote the same "4 at 742M" for §[8] without the
convention: [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) §560T results and [CRITIQUE.md](CRITIQUE.md)'s
2026-06-11 update block. Neither was changed. Neither page defines Measure B as `≤ 1`, so neither
contradicts itself the way this one did, and the CRITIQUE.md block is mirrored verbatim in
`CORRECTIONS_INVENTORY.tsv`. [`LEADERBOARD.md`](../enumeration/LEADERBOARD.md) already carries the
convention caveat and needed nothing. Both are queued with the gate.

### 4. A record count was called a depth (`RP-0147d9f7`, `RP-4dbc26f6`)

**BEFORE.** Two sentences — the opening of §What this implies and the §7 paper-implications
bullet — attached the bare figure **3.07×** to the words *deepening* and *depth increase* for the
100T → 560T step. (The two retracted strings are registered as `RP-0147d9f7` and `RP-4dbc26f6` and are
deliberately **not** quoted here: they carry no allow-row, so the ban is corpus-wide with no exemption,
including for this ledger.)

**NOW.** COMPUTED: 10,525,271,997 / 3,432,399,297 = **3.0664** — the **record-count** ratio. MEASURED at
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Reproducibility parameters": the 100T and 560T recipes are
both `SOLVE_DEPTH=3` and differ in `SOLVE_PER_SUB_BRANCH_LIMIT`, 631,456,644 → 3,536,157,207 — **5.6×**,
the same factor `SOLVE_NODE_LIMIT` moves by. Calling the record ratio a deepening erases exactly the
relationship [`LEADERBOARD.md`](../enumeration/LEADERBOARD.md) states in its own headline: a linear node
budget yields sublinear new orderings. Both sentences now name the budget and give the record ratio
beside it, and §"Limits and scope" gains a bullet stating that the budget ratio is 5.6×, the record ratio
is 3.07×, the gap is the sublinear growth, and a record-count ratio is never a depth.

**Census checked in both directions, and it narrows the class.** The figure has **7** sites. **Five**
attach it to "scale", "workload" or "ratio" — [`LEADERBOARD.md`](../enumeration/LEADERBOARD.md) ×2,
[CRITIQUE.md](CRITIQUE.md), [DEPLOYMENT.md](DEPLOYMENT.md) ×2 — where the record-count reading is the
natural one and is correct. **They are not retracted and were not touched.** Exactly two attached it to
the word *depth*, and both were in this file. Sibling of `RP-91287bc7`, which retracted the same axis
confusion on [PARTITION_STABILITY_BOUNDARIES.md](PARTITION_STABILITY_BOUNDARIES.md) earlier the same
day; the bare word "depth" is again **not** registered, because the page uses "canonical depth" as the
project's established idiom for the deepest enumerations and a bare needle would fail on correct prose
in half the corpus. The new bullet defines the idiom instead of banning it.

### 5. Sibling sweep no charge named: the 560T analyze log was listed as though a reader could open it

`RP-96d7a817`, adjudicated earlier on this page on 2026-09-02, established that
`canonical-archive/…` is operator-held cold blob storage, that `canonical-archive/` is not in this tree,
and that `runs/20260608_560T_9a968fa2/` holds only `viz/`. That correction landed on
[PARTITION_STABILITY_BOUNDARIES.md](PARTITION_STABILITY_BOUNDARIES.md) and **stopped there**.
`BOUNDARY_MINIMUM.md` listed `analyze_v3_560T.log` under "Pre-computed analyze logs" in the same bullet
list as the three `analyze_output.log.gz` files that **do** ship in `runs/`, and its source table marked
neither cold-blob row. Since this pass makes the page lean harder on 560T-only §[24] and §[6] figures,
leaving them looking fetchable was not an option. §Reproducibility and both cold-blob rows in the source
table now say what is operator-held, state that every 560T §[6]/§[8]/§[24] figure on the page is a
**transcription**, name the 2026-07 primary-evidence sweep that attests them, and distinguish them from
the 10T/100T figures a reader can read out of `runs/`. This is a **publication gap, not a computation
gap**, and the page now says which.

**Attribution.** The four charges were raised by the Codex V2-F31 review pass and adjudicated in
roae-private; reviewers are acknowledged, not credited as authors. The measurements recorded above — the
§[4]/§[6]/§[7]/§[8]/§[24] transcriptions from `enumeration/analyze_c_742M.txt` and the three shipped
`analyze_output.log.gz` files, the `330177707` null grep over the 100T log, the
`SOLVE_PER_SUB_BRANCH_LIMIT` read, the record-ratio arithmetic, and the flattened whole-corpus scans that
produced both census corrections — are this lane's (Claude), and every one is reproducible from files in
this repository.

---

## 2026-09-02 — DESCRIPTION_LENGTH.md's four inherited defects: a bound on an unpublished denominator, a literature figure that priced our own relaxation, a net bracket no published cost could produce, and a standard error published as a ± band

[DESCRIPTION_LENGTH.md](DESCRIPTION_LENGTH.md) is the public face of the bit ledger that
[TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md) computes. Four defects were raised against it by
the Codex V2-F35 review pass and adjudicated in roae-private; all four are upheld. Three of them
were already known: TR-9's own correction on 2026-09-02 (prose batch P31) fixed the report and
deliberately left this page's three sibling sites live, registering them in
`documentation/DOC_GATE_FIGURE_ALLOWLIST.txt` with class `open` so GATE 3b would print each as
`[OPEN]` on every run until this batch landed. It has landed; all three rows are deleted and
GATE 3b reports **0 open** rows against this file. **No solution count, log-cardinality, marginal
compression, residual endpoint or verdict changes.**

**Registry keys: `RP-fe502239`** (`documentation/RETRACTED_PHRASES.tsv`, new) and
**`RF-e2b24ea8`, `RF-455570a2`** (`documentation/RETRACTED_FIGURES.tsv`, registered by prose batch
P31 on 2026-09-02; both rows are amended here to record that their last live sites are closed).

### 1. A conditional selection charge published as an upper bound — `RP-fe502239`

The Framework conventions told a reader that the meta-selection charge — the cost of selecting the
constraint *families themselves* — has a closed answer in bits, priced against the frozen
91-observable ledger at ≈ 32.9 bits, "small against C1's 146.3". The arithmetic is right
(log₂ C(91,7) = 32.914) and the denominator is the wrong universe.
[METHODS.md](../reports/METHODS.md) §"Global observable ledger" builds the 91 as 28 exploratory
observables + 58 pre-registered testing-family tests + 5 corpus-control predicates — a ledger of
**tests performed** — while METHODS.md §"The file drawer — an open gap, stated as such" says of the
constraint-family denominator that "this suite does not currently publish that denominator" and that
it is "a different quantity" from the testing-phase ledger. It is not a bound on its own denominator
either: METHODS.md recorded on 2026-08-30 that entering the omitted pre-registered H1/H3 family gives
**95**, and log₂ C(95,7) = 33.363 > 32.914.

This is the same defect TR-9 §5(f) withdrew earlier the same day, and the sentence here was the last
live one in the corpus. It was not caught by either needle that batch registered — `RP-e35a1705`
(the phrase naming the withdrawn joint charge) and `RF-047e690e` (the margin it licensed) — because this page worded the
claim differently and never quoted either. That is the sibling-residue failure mode in its exact
form, and it is why the wording is registered here rather than only edited.

**What survives.** The figures 32.9 and log₂ C(28,5) ≈ 16.6, relabelled as conditional readings, and
the *direction* of the argument: every selection charge this corpus can currently price is of order
tens of bits against C1's 146.3. What does not survive is the word "bounded" and any margin computed
from it. Settling the charge means publishing the tried-and-dropped constraint-family roster; that is
not done and the page now says so.

### 2. A literature figure that prices this project's own relaxation

The ledger's last row gives "the strongest *principled* literature rule (Schulz gender)" a
compression of 13.5 bits, and the residual paragraph promotes that to "the literature's strongest
independent rule prices at ~13.5 bits gross". Measured: log₂(11,364) = 13.472, so the figure is
log₂ of the ×11,364 rarity — and
[LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md)'s 2026-07-12
convention-stability note states in terms what that ×11,364 measures: the "≤2 violations anywhere"
relaxation **this project defined**, not the form Schulz's sources state (parity throughout with at
most one exception pair at adjacent class positions). Re-measured on identical probes the
source-stated form is ≈11× rarer, so the rule *as its sources state it* compresses
log₂(11,364 × 11) = 16.932 bits — about 3.5 bits more than the row prices.

The error runs in the direction that makes the literature look **weaker**, so no headline moves: 16.9
against a 105–139-bit residual is still negligible, and the row's "≈ 0 to small +" verdict becomes
+1.9 to +6.9 against the same cost cell, which is slightly stronger for the literature, not weaker.
What was wrong is what the number is *about*. The cell and the residual sentence now name the
relaxation and give the source-stated figure beside it.

Separately, the same row's cost cell "rule text ≈ 10–15" is now labelled **underived**, in the exact
style the page already uses for the C6/C7 "~20.6". `prior_art_check.sh 'Schulz rule text statement
cost 10-15 bits derivation'` returns `PRIOR_ART=NONE  surfaces searched: roae-private *.md, *.tsv,
codex_transcripts/; roae *.md; git log --all -S on both repos`: no codebook, computation or working
note producing 10–15 exists, and every occurrence of the figure in the corpus is this cell, its TR-9
mirror, or a review transcript quoting one of them. It is retained, so labelled, because nothing
rests on it — the verdict holds across the whole band and at 16.9 as well.

### 3. The two sites TR-9's correction knowingly left live — `RF-e2b24ea8`, `RF-455570a2`

The C2 ledger row and the 2026-07-10 refinement note both carried a net bracket whose lower endpoint
no published cost can produce. Net is compression − statement cost; C2's compression is
log₂ 23.325025987… = 4.5438 bits; the declared per-distance-ban family has six members, log₂ 6 =
2.585, giving +1.96 (the published +2.0, correct); the largest statement cost stated anywhere in the
corpus is 4, giving +0.54. Every published coding gives C2 a **positive** net. The retired endpoints
would need 5.14-bit and 8.54-bit explicit grammars; `prior_art_check.sh 'C2 explicit-grammar coding
statement cost 5.14 8.54 bits'` returns `PRIOR_ART=NONE  surfaces searched: roae-private *.md, *.tsv,
codex_transcripts/; roae *.md; git log --all -S on both repos`. The bracket is corrected to
**+0.5 to +2.0**, mirroring TR-9 §2 fn⁷.

The prose site carried an extra claim the ledger cell did not: that C2's **sign** is therefore a
coding-convention choice. That inference has no surviving premise and is withdrawn with the endpoint.
C2's verdict is unchanged — break-even to marginally explanatory, the only narrow rule that reaches
break-even — but it is now break-even *from above* under every coding the corpus states, not
sign-ambiguous.

The consequence the allowlist row at `:84` flagged is the savings envelope, whose low corner consumed
the retired endpoint. With the supported endpoint it is 127.3 + 0.5 − 20.6 = **107.2** and
107.2 ÷ 296.0 = **36.2%**, so the page now publishes **107.2–148.3 bits ≈ 36–50%** with the corner
arithmetic on the page rather than only behind a pointer to TR-9 §4. The high corner
(146.3 + 2.0 = 148.3 = 50.1%) and the C5-retaining variant (142.0) are unchanged; the envelope
narrows from below only.

### 4. A relative standard error published as a ± precision band

The residual's precision was stated as "±0.01 bits", derived from the C1–C7 estimate's published
0.78%. That 0.78% is the estimator's relative **standard error** — METHODS.md §"Statistics
conventions": the tool prints mean ± 1.96·√(v̂ar/N) with relerr = SE/mean — not a 95% half-width, so
the 95% interval is ±1.96·SE ≈ **±0.022 bits**, understated by a factor of 1.96. The published
interval [5.13, 5.29]×10³¹ gives the same answer independently: −0.0223/+0.0220 bits. The same slip
ran in the Framework conventions bullet, where ±0.02% was converted to ±0.0003 bits; the 95% figure
is ±1.96·SE ≈ ±0.0006 bits, which is what TR-9 §1 already publishes.

This completes on this page the ruling this ledger made on 2026-08-28 — that a relerr is not an error
bar — which reached four F11 sites and none of these, and which prose batch P31 propagated to TR-9's
two sites on 2026-09-02.

**One sibling is knowingly left uncorrected and is not swept here.** `README.md`'s residual bullet
still converts the same 0.78% to "≈ ±0.01 bits" and calls the C1–C5 estimate's 0.02% "tighter" in the
same breath. It is outside this batch's file scope, no figure is retracted by it (the fix is a
conversion, not a withdrawal, so there is no registry needle that would keep it visible), and it is
therefore recorded in the prose lane's backlog in roae-private rather than left to a reader to
rediscover. Stating it here is the second-best guarantee available and is deliberately weaker than an
`[OPEN]` gate row; a batch that owns `README.md` should close it.

**Attribution.** The four defects were raised by the Codex V2-F35 review pass and adjudicated in
roae-private; reviewers are acknowledged, not credited as authors. The arithmetic recorded above —
the C(91,7)/C(95,7)/C(28,5) recomputations, the log₂ 23.325025987 and log₂ 6 marginals, the
log₂(11,364) and log₂(11,364 × 11) compressions, the 127.3 + 0.5 − 20.6 corner, the CI-to-bits
conversions from the two published brackets, the prior-art searches behind both absence claims, and
the whitespace-flattened whole-corpus censuses that fixed the site counts — is this lane's (Claude),
and every one is reproducible from files in this repository.
## 2026-09-02 — PREREGISTRATION_ESCROW.md: an escrow page that claimed more than escrow can deliver

Four defects on the page whose entire value is that it constrains the project after the fact, plus
one disclosure the page never made. All four were raised by the Codex V2-F46 review pass and
adjudicated in roae-private; reviewers are acknowledged, not credited as authors.

**The provenance question first, because on this page it outranks the charges.** A pre-registration
escrow edited after the outcome is not a weak document, it is a destroyed instrument, so the first
check was whether the page's own record survives. It does. `git log --follow` on
`documentation/PREREGISTRATION_ESCROW.md` returns **one** commit, `0daa5ecb`, authored and committed
2026-08-22 03:10:07 +0000 — matching the publication date the page states — with a clean working
tree and no intervening edit. Independently, all ten escrowed digests were re-verified against the
operator-held files on 2026-09-02 and **all ten still match**, and every one of the ten
"first committed (private)" dates equals that file's first-commit date in the private history. The
date column and the hash column are both honest. What follows are scope errors, not fabrications,
and the amendment below changes no published hash, byte count or date.

### 1. Escrow converts content identity, not freeze timing — `RP-f145f963`, `RP-057e3756`

The page answered the question in its own title by saying that publishing a hash converts freeze
timing from attested to checkable, and its own bullet list denied that five lines later. The narrow
version is truer and worse than the reviewer's: the sentence is not always false — for a test
measured *after* the escrow is published it is exactly right — but it was written prospectively for a
table that is **entirely retrospective**. All ten rows carry a first-committed date between
2026-07-17 and 2026-08-18, every one before the 2026-08-22 publication, and for the Half-B extension
the *result* was already public in this repository on 2026-08-04, eighteen days early. The page's one
genuinely converting case has **zero instances in its own table**.

The census was corrected upward. The charge named one site; there were two. `documentation/README.md`
line 62 carried the same claim in wording the escrow page never uses, and would have survived any
needle drawn from the page itself — the morphology-evasion lesson of 2026-08-01, now caught the way
prose batch P40 caught its last live site.

### 2. "Each frozen file" over a table of ten — `RP-be8e188a`

A whole-tree sweep for private pre-registration filenames appearing in tracked public files found
**six** further frozen pre-registrations with no row on the page, each described in shipped source as
fixed before measurement with a Bonferroni denominator attached: F4′ (N=13), F5 orientation (N=11),
F6 books (N=7), R3 permutation (N=13), R8 Davis (§3.1/§3.2) and the F11 Bayes model. These are
exactly the families `METHODS.md` §"Global observable ledger" builds the 91-observable ledger from, so
they are what a referee checking that ledger would ask for. Both the reviewer's four and the
adjudication's five undercounted the files; the adjudication's **19 sites overcounted** the
occurrences, which measure at 14 across 6 distinct tracked files. Two further names are not omissions
and the page now says so: a superseded F5 draft, and a name cited in `RESULTS.md` as "the frozen
pre-registration" that matches no file in the private repository today — an unresolved citation, not
an unescrowed freeze. The page now says it escrows ten, names the six, and states that adding them is
an operator action that has not been done.

### 3. The undisclosed defect: for three rows the date and the hash describe different versions

No charge named this one. The escrow pairs a "first committed" date with a hash, and a reader who
obtains a disclosed file and finds it matches will conclude that this is what was frozen on that
date. For seven rows that is right — one commit each. **For three it is wrong.**
`PREREG_KNUTH_CLEANROOM_2026_08_08.md` was 4,254 bytes when frozen on 2026-08-08 before the prober
was written; the escrowed 7,117-byte digest is of the version committed on **2026-08-09 in a commit
whose message records the gate's PASS result**. `PREREG_REPR_COST_VS_T_2026_08_18.md` was 5,298 bytes
when frozen before the correlation was computed; the escrowed 8,359-byte digest is of a **2026-08-19**
version appending metrics and conclusions. `PREREG_F_CATALOG_T1_T4_2026_08_06.md` gained same-day
dated annotations, recorded in its commit message as made before the first T3 draw — benign, but
still not the frozen bytes. The escrowed hash of two pre-registrations therefore attests a document
that **contains its own outcome**. The page now publishes the freeze-commit digest for all three, so
both states are checkable, under the same "claim, not proof" caveat the date column already carries.

### 4. "Not publicly fetchable", and a promise the page's own argument refutes — `RP-fe3f7b05`, `RP-920e2f02`

Sweeping the ten digests against `sha256sum` of every tracked file returns exactly one match:
`reports/evidence/f11halfb/PREREGISTRATION_VMATCHED.md`, 5,336 bytes, **byte-identical** to its
escrowed row. So one of the ten is published in full and verifies — the page's only end-to-end
checkable row, and it is now presented as the worked example.

The second instance is the one that matters, and it resolves the question the adjudication recorded
as unresolvable from the public side. `reports/evidence/f11halfb/PREREGISTRATION_EXTENDED.md`
(3,986 bytes, `1dedbda1…`) is the escrowed `PREREG_HALFB_EXTENDED_2026_08_03.md` (3,965 bytes,
`09d711c3…`) **published in redacted form**: the two are 81 lines each and differ in **exactly one
line, the last**, where a name identifying operator-held infrastructure was replaced with a generic
description. Same document, one redaction, different digest. The page had promised that each
published file would verify against its hash — two sentences after arguing that publishing the files
would require redaction and that redaction breaks byte-identity. The page contained its own
refutation, and the refutation had already fired **before the page was written**: the public copy was
committed 2026-08-04 and neither file has changed since, so the mismatch was published knowingly
rather than introduced by drift. The promise is now conditional on unredacted publication, and both
outcomes are enumerated on the page.

A third public counterexample sits outside the table entirely: `reports/evidence/f11/PREREGISTRATION.md`
is headed "FROZEN 2026-07-04 by operator approval", is 3,901 bytes, is published in full, and has no
row on the escrow page.

### What was deliberately not changed

The ten published rows. Not one hash, byte count or date was altered, reordered or removed; the
table and its verification snippet are byte-identical to the 2026-08-22 commit, and every correction
is additive and dated. `documentation/ROAE_PY_CLI.md` was checked because the adjudication's A03
row 9 recorded it as reading the escrow with the weight this correction removes; its lines 214 and
227 are CLI-table rows about a JSON pre-registration record and a spec followed verbatim, carry no
escrow-weight claim, and were left alone. `reports/TR2_THE_RULES_CONFLICT.md`'s sentence on readers
who discount unverifiable freezes is correct prose and was not touched.

**Attribution.** The measurements recorded above — the `git log --follow` provenance check on the
page and on every escrowed file, the ten-way re-verification of the escrowed digests, the
freeze-commit digests for the three amended rows, the whole-tree filename census and its correction
in both directions, the sweep of all ten digests against every tracked file, the line-level
resolution of the Half-B pair, and the prior-art searches behind the absence claims — are this lane's
(Claude), and each is reproducible with `git`, `grep` and `sha256sum`.

## 2026-09-02 — PARITY_ALTERNATION.md: a sha prediction for code that was never written, a reproduction promise wider than its command, and a lemma cited by the wrong number

Three defects raised by the Codex V2-F42 review pass and adjudicated in roae-private; the reviewer
is acknowledged, not credited as an author. No theorem, lemma, figure or canonical value changes
below — all three are scope and citation errors in the prose around them, and the checker's 18-line
output is byte-for-byte what it was before this pass.

### 1. An unwritten prune's sha effect was stated as fact — `RP-8717d434`

§Consequences item 3 said that an exact prune changes node-visit ordering and counts, and then
asserted the consequence for per-cell budgeted canonical outputs, and for canonical shas, in the
unhedged conditional — the phrasing registered as `RP-8717d434`. The certainty is wrong twice over.

It is wrong about *this* prune because this prune does not exist. MEASURED: `grep -ic alternation
solve.c` returns **5**, and all five are scoring functionals or comments — Moore's `rf_alt` and
Chan's `orient_alt` in the score table, a Moore-1989 comment, and two prose lines. A sweep for a
differently-named equivalent (`parity_class`, `class_change`, `alt_used`, `alt_left`, an alternation
budget) returns nothing, and the two parity prunes that *do* exist in `solve.c` are the Moore-2005
c(S) slot restriction and the Schulz-1990 gender-strict walk, neither of which is the
parity-class-alternation prefix prune item 2 describes. The item therefore predicted the sha
behaviour of code that has never been written. (A small citation correction to the adjudication
while we are here: it credited the surrounding discipline to "this document's own §Status decision
… NOT promoted", but PARITY_ALTERNATION.md has no such section — that heading belongs to
[CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md), the sibling discussed below, and the line range the
adjudication gave points at this page's §Consequences instead.)

It is also wrong as a general statement about exact prunes, and the project's own record settles it
in both directions. [HISTORY.md](HISTORY.md) records that the v2 prune bundle did **not** flip the
100B reference sha — at that per-cell budget of 631K nodes the DFS never reaches the subtrees the
prunes would skip, so the prunes never fire and the output is identical to the pre-prune code. The
same bundle **did** move the 11.2T canonical, where the per-cell budget is 70.7M: v1's `0c0fe37c…`
and v2's `2cc966e4…` are different artifacts. So whether a prune moves a sha is an empirical
question per prune-set and per budget, not a corollary of exactness. The corrected item says "can
change, at budgets deep enough for the prune to fire" and states both v2 outcomes.

One qualification the reviewer's counterexample did not carry, and it matters:
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) heads the section holding the 100B figure "100B and
sub-canonical reference shas — code-specific, NOT canonical-grade", so the 100B non-flip demonstrates
the firing mechanism but is not by itself a counterexample about a *canonical* output. The corrected
prose says so rather than leaning on it.

**Not changed, deliberately.** [CIRCULAR_KING_WEN.md](CIRCULAR_KING_WEN.md) §"Status decision" and
[TR-7](../reports/TR7_CIRCULAR_READING.md) §6 carry the sibling analysis for circular C2 — "as a pure
leaf-emission filter it would be byte-identical to the current lineage at every published canonical
scale … as a prune it would change node consumption and open a new sha lineage". That already draws
the filter-versus-prune distinction this correction restores, its byte-identity half is evidenced
(zero 5-wrap records exist in any slice), and its second half is a lineage-policy statement rather
than a claim that two measured shas differ. Both were left as they stand.

### 2. The reproduction promise was wider than the command — `RP-dc836305`, `RP-1734cf96`

EXECUTED, 0.108 s, `rc=0`: `python3 verify.py --check-parity-alternation` emits **18** lines, and two
numeric figures on the page appear in none of them — the **48**-element relabeling group in
§Consequences item 4, and Moore's **16/18** King Wen compliance in §Novelty status. Both figures are
correct; the defect is coverage, and the hazard is mechanical, because a drift in either uncovered
figure would leave `PARITY_ALTERNATION=PASS` green. The promise is now narrowed to the theorem's
figures, and each uncovered figure is named with its own reproducer.

**A correction to the charge, in the direction that matters.** The adjudication proposed saying that
Moore's 16/18 "is a literature figure with no in-repo reproducer". It has one. `solve.h2_parity_slots`
returns KW's violating pair-slots (`[21, 22]`) against 18 non-exempt slots — comp-pairs and
popcount-3 pairs are exempt — so `python3 -c "import solve; print(18 -
len(solve.h2_parity_slots(list(solve.binary_hexagrams))))"` prints `16`, and
`reports/evidence/r11/r11_calibration.py` asserts the same figure as its KW gate
(`solve.r11_axes(KW) == [2, 2, 2, 0, 0, 0, 0, 0]`, the leading 2 being the parity violations). The
page now names that command rather than declaring an absence that is not there. The 48 is checked by
`python3 solve.py --symmetry-completeness`, leg SC-7, in about 4 s.

**The census was corrected upward.** The charge named one site. Two markdown sites were live:
[VERIFY.md](VERIFY.md)'s row for this command made the same unconditional claim in wording
PARITY_ALTERNATION.md never uses — registered separately as `RP-1734cf96` — so no needle on this
page's phrasing would have reached it. It is fixed in the same pass. A third site is in code and is queued rather than edited here, per the prose lane's code
rule: `verify.py`'s `check_parity_alternation` docstring opens "Re-derive every published figure in
PARITY_ALTERNATION.md from KW itself". GATE 3 does not scan it — its corpus is tracked `*.md` plus
`reports/evidence/**` — so the registry rows above do not cover that site and the queue entry says so.

### 3. The well-definedness clause cited the wrong lemma — `RP-2857f455`

The page said the checker confirms that a pair's parity class is well defined, and named the wrong
lemma as the one it thereby avoids assuming — the clause registered as `RP-2857f455`.
Well-definedness is **Lemma 1** — pairs are parity-homogeneous, `popcount(partner(h)) ≡
popcount(h) (mod 2)`, so each pair has a parity class independent of orientation. **Lemma 3** is the
different transition-parity result, which *uses* the class Lemma 1 establishes. `verify.py`'s
implementation is Lemma 1 verbatim: `all(bin(a).count("1") % 2 == bin(b).count("1") % 2 for a, b in
pairs)`.

**The census was corrected upward here too.** The charge named one markdown site and one code site.
Two markdown sites were live — [VERIFY.md](VERIFY.md) carries the identical clause, word for word —
and both are fixed. The code site is `verify.py`'s docstring, which restates Lemma 1's proof under
Lemma 3's name; it is queued rather than edited, and the doc-side fix now stands ahead of it, so
until that queue item lands the docstring and the page disagree. That is stated here rather than left
to be discovered.

**Attribution.** The measurements above — the `solve.c` alternation census and its
differently-named-prune sweep, the timed execution and line count of the checker, the recovery of
Moore's 16/18 from `solve.h2_parity_slots` and its cross-check against `r11_calibration.py`'s gate,
the whitespace-flattened whole-corpus census behind each retracted needle, and the prior-art check
behind the "no such prune exists" claim (`PRIOR_ART=HIT` — the parity-alternation prune is a
pilot-gated future lever in the private v4 roadmap, never implemented, which confirms the absence
rather than contradicting it) — are this lane's (Claude), and each is reproducible with `git`,
`grep`, `python3` and the commands named above.

---

## 2026-09-02 — HISTORY.md: a null-model aggregate that outlived its own roster, a uniqueness claim its seventh family refutes, a withdrawal that never travelled fifteen lines, and an equivalence table one row short of its own heading

Three charges from the Codex V2-F12 adjudication, all on [HISTORY.md](HISTORY.md). Two were executed
rather than accepted: one prescribed figure was recomputed and found wrong, and one prescribed fix
would have deleted a validation path from the public record.

### 1. The null-model batch aggregate (Codex V2-F12 #1) — three legs, three different verdicts

The 2026-04-19 null-model section closes with an aggregate paragraph carrying three claims. All three
were live. They do not resolve the same way.

**Leg (a) — the aggregate figure. The reviewer's replacement is wrong and the original is kept.**
The figure is the six-unconditional-family roster total from when `--null-random` sampled 10⁸. That
row was later raised to 10⁹ **in place, fifteen to twenty lines above the aggregate**, and the
aggregate never followed — so the paragraph stopped summing the roster printed directly above it.
The current total is **2,760,021,104**: de Bruijn 134,217,728 + Gray orbit 256 + random Gray walks
10⁵ + Latin row × column 1,625,702,400 + lexicographic 720 + random 64-permutations 10⁹. The four
`--null-historical` point-tests are excluded because they are point-tests, not a family; the Latin
column × row pass is a direction-invariance re-traversal of the same 8!×8! population and is not
double-counted.

The adjudication prescribed **2,759,921,108**, reached by counting the four historical point-tests
as a family and omitting the 10⁵ random-Gray walks. Those two errors nearly cancel — the gap is
99,996 — which is why the wrong sum still rounds to the right billions. The roster is already
enumerated in [SOLVE.md](SOLVE.md) §"Null model: is the constraint framework special?", which has
carried 2,760,021,104 since 2026-08-30 together with the pre-upgrade total 1,860,021,104; that roster was used rather than
re-derived, and the prescribed figure was **not** published.

The figure itself is **not overwritten**. [GUIDE.md](GUIDE.md) records a 2026-08-30 decision that the
dated aggregate in HISTORY.md is a correct record of the then-current roster and stays, and that
decision post-dates the 2026-07-26 in-place amendment the adjudication cited as evidence the sentence
is maintained rather than frozen. What was actually defective is that the staleness was invisible: a
reader met a total that no longer matched the roster above it with nothing saying so. The paragraph
now carries the current total, the roster arithmetic, and the reason the two differ. Registered as
**RP-0b44734e**, with `documentation/HISTORY.md` as the allow column and every other file guarded.

**Leg (b) — the uniqueness claim. Withdrawn, and the census was one site short.**
The sentence said the conjunction C1 ∧ C2 ∧ C3 picks out King Wen in all seven tested families. It
holds for the six unconditional families and holds **vacuously** there, because C1 is 0% in each, so
nothing in them reaches the conjunction at all. In the seventh, pair-constrained family C1 holds by
construction and the joint rate is ≈**0.305%** — about **3.06 million of 10⁹** orderings satisfy
C2 ∧ C3 as well.

Re-executed here rather than accepted: `python3 scripts/c2c3_joint_null.py` →
`P(C2|C1) = 4.29159%` (−0.3σ against the exact 4.29341%), `P(C3|C1) = 6.41625%` (−0.6σ against the
exact 6.4211367%), `P(C2^C3|C1) = 0.30478%`, **+16.7σ** over the 0.27569% independence product,
`C2C3_JOINT_NULL=OK`. That agrees with the 0.305832% measured over 10⁹ draws on 2026-08-28.

**CENSUS CORRECTED UPWARD.** The charge named one site; there were two. [SOLVE.md](SOLVE.md)
§"Null model: is the constraint framework special?" carried the same claim with bold emphasis splitting it — invisible to
a plain grep for the registered wording, visible once GATE 3's fold and whitespace normalisation are
applied. That page contradicts itself: the paragraph immediately above publishes the pair-constrained joint
rate and the +16.7σ excess over the product. Both sites now scope the claim to the six unconditional
families and the four historical orderings and state plainly that King Wen is not alone in the
seventh. The retired wording is registered as **RP-79f8f30b** with allow column `__none__`.

**Leg (c) — the shared-classical-design-principle inference. Withdrawn 2026-07-05; the withdrawal
never travelled fifteen lines.** The `--null-historical` entry in the same section has carried
"the shared-design-principle inference is withdrawn" since 2026-07-05, and the aggregate paragraph
fifteen lines below restated the inference unqualified. [CRITIQUE.md](CRITIQUE.md), [GUIDE.md](GUIDE.md)
and [SOLVE.md](SOLVE.md) all received that 2026-07-05 propagation; this paragraph did not. It now
carries the withdrawal with its citation ([Shaughnessy 2022](CITATIONS.md#shaughnessy2022), Table
11.2 — the authentic Mawangdui order has exactly one 5-line transition at its Kan→Zhen octet seam,
so C2 is 2 of 4, not 3 of 4).

**Sibling sweep, in the other direction.** The 2026-08-30 aggregate correction had reached SOLVE.md
and GUIDE.md and **three further pages were still publishing the pre-10⁹ total as a live,
present-tense figure**: [CRITIQUE.md](CRITIQUE.md) §Missing analyses, [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)
§"Important methodological note", and [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) §"Seven-family null-model
framework" — the last of which was publishing **both** totals on one page, the corrected one in an
earlier section and the stale one here. All three now carry 2,760,021,104.

### 2. A status row reviving a restriction two rows of its own table disprove (Codex V2-F12 #2)

The "What actually advanced understanding" table carried a row whose Status read "Observed
universally; driven by C3 not budget" for the positions-3–19 shift pattern, with "Analysis of 31.6M
solutions" as its evidence. Two rows of the **same table** already record that the 31.6M dataset was
undersampled by the file-collision bug and that only 2.93% of the corrected 742M conform.

MEASURED against the shipped primary log, [`enumeration/analyze_c_742M.txt`](../enumeration/analyze_c_742M.txt)
§[5]: rows with any shift exception **720,334,146 (97.074%)**, rows fully shift-conforming
**21,709,157 (2.926%)**, total 742,043,303 — all three reproduced. The second clause fails too: the
2-option restriction is `--prove-cascade`'s own 2-candidate enumeration, not a consequence of C3, as
the cascade-determinism row above already states. The Status cell now reads **Superseded** and names
both the corrected rate and the dataset it comes from. The middle column's "Analysis of 31.6M
solutions" is left as-is — it is a correct record of what was analysed, and the defect was that the
**Status** column, which is where a reader takes the verdict, carried no scope at all.

### 3. An "8-path equivalence" table publishing seven paths (Codex V2-F12 #3) — the prescribed fix was declined

The heading "8-path equivalence at 11.2T proven" is followed by a table with **seven** data rows. The
adjudication's reviewer concluded no eighth path was identifiable and prescribed renumbering the
heading to seven.

**That fix was declined, and the count was right.** The eighth path is the **recovery cascade
(post-#45 patch)**, and it is described in this same public file, under "May 4 – May 5, 2026 PDT":
*"Patched binary 11.2T fresh full-enum reproduced sha=`0c0fe37c…` byte-identically with the Tier 1
canonical (May 4 04:21Z)."* The loss inventory further down names "recovery cascade artifacts, 8-path
equivalence validation" side by side. Renumbering the heading would have deleted a real validation
path from the public record. The row has been added instead.

**A second defect the charge did not name.** The eighth path landed 2026-05-04, two days after the
heading's own "as of May 2, 2026 evening PDT / 2026-05-02 ~22:30 UTC" timestamp — a retrospective
count wearing a contemporaneous date. The heading now separates the two: seven as of May 2, the
eighth on May 4.

**CENSUS CORRECTED UPWARD.** The charge named one inconsistent site for the count; there were two.
Both sit in the 2026-05-05 reconciliation discussion — one describing `0c0fe37c`'s validation with a
seven, the other contrasting runs "13 days apart in code stability and seven-path validation
discipline". The retired count is spelled out in words here deliberately: GATE 36 (added by this
batch) has no quotation exemption, so a ledger entry that quoted the digit form would trip the gate it
records. Both sites now read 8-path, matching the heading and the loss inventory.

**Deliberately not added: Tier 7c (multi-stage chain).** It appears in the campaign's planning
material as a ninth candidate but was still running when the validation-path roster was fixed at
eight, and the roster is what the heading counts. Adding it would break the heading's own arithmetic
in the opposite direction.

**Attribution.** The measurements above — the roster re-derivation and the arithmetic showing the
adjudication's 99,996 discrepancy, the `scripts/c2c3_joint_null.py` re-run, the shift-conformance
figures read off the primary log, the whitespace-flattened whole-corpus needle scans that found the
second uniqueness site and the three stale aggregate siblings, and the public re-location of the
eighth validation path — are this lane's (Claude). Codex's V2-F12 review located all three sites;
its prescribed figure for leg (a) and its prescribed fix for charge 3 were both declined on evidence,
and both declines are recorded above rather than left silent.

## 2026-09-02 — CLAUDE.md: an enumerator described as exhaustive in the file the correction did not sweep, a withdrawn VM rule citing its own retraction as authority, and a single-source-file rule contradicted by sixteen tracked files

Prose batch P44, adjudicating Codex review V2-F56 against `CLAUDE.md` at `4b320e5c`. All three
charges were TRUE and LIVE; one was three-quarters stale and is recorded as such below, and two
uncharged siblings were fixed alongside.

### 1. The orientation file still described the solver as exhaustive (`RP-309f3fd7`, `RP-0ae93dfb`)

`solve.c`'s own header carries a `CORRECTED 2026-08-28 (Q-353)` block stating plainly that no run
has ever enumerated the whole C1–C5 population: every published enumeration is budgeted per cell, so
what it produces is an exactly-reproducible **slice** and its record count is a **LOWER BOUND**. That
correction names the three files it swept — `SOLUTIONS_FORMAT.md`, `BRANCHES_EXPLAINED.md`,
`SOLVE.md`. `CLAUDE.md` is not among them, and the wording survived in **its opening paragraph**: the
first substantive sentence of the file every agent and every new reader is pointed at first.

**Why this one matters more than its size suggests.** `SOLUTIONS_FORMAT.md` calls every published
result a lower bound. Reading the 560T artifact's 10,525,271,997 records as the complete C1–C5
population converts a *slice* absence into a *full-space* conclusion — which is the exact inference
the Q-353 correction exists to block.

**Census checked in both directions**, with a whitespace-flattened, bold-stripped scan over every
tracked file rather than a line-based grep. It **confirms the charge at two live sites**: this one,
and `solve.c:19–20`, ten lines below its own correction note. Three near-miss sites are correct prose
and were deliberately left alone — `PARTITION_INVARIANCE.md` prefixes the phrase "Under exhaustive
enumeration"; `BRANCHES_EXPLAINED.md` states it as the solver's *goal* and denies in the next clause
that any run has achieved it; `lean/README.md`'s is a finite 120/5040 brute force.

**The second site is not fixed here, and that is a scope limit, not an oversight.** GATE 3's corpus
is `git ls-files '*.md'`, so C comments are structurally invisible to every retraction gate, and this
lane does not edit `solve.c`. That half is queued for the code lane; it is also charge 7 of the same
adjudication. Both wordings are registered so that neither can re-enter the markdown corpus, and they
are registered as **two rows** because they share no substring — the morphology-evasion lesson of
2026-08-01.

### 2. A withdrawn VM rule citing, as its authority, the section that retracts it (`RP-8f82e8fd`)

The blanket "every VM must be Spot" rule was withdrawn 2026-08-29 after measurement on the live
subscription showed five of seven non-orchestrator VMs were `Regular`: the rule had never been
followed and it contradicted `DEPLOYMENT.md`'s standing enumeration=Spot / merge=on-demand split.

**CENSUS CORRECTED DOWNWARD, from four sites to one.** The charge named four. Checked against current
`main` rather than against the reviewed sha, **three had already been repaired in place** by public
commits landed after the review: the mandatory pre-launch gate no longer says a `Regular` answer means
STOP (it now splits by checkpointability and calls Regular the *required* type for uncheckpointable
work), the merge-VM paragraph now exists only as quoted text inside a dated `[CORRECTED 2026-08-30]`
withdrawal, and the section heading's instructions are the corrected ones.

**The one survivor was worse than anything the charge described.** `CLAUDE.md` §"Bi-region
architecture" still commanded Spot for enumeration *and* merge, "per the 2026-04-29 standing policy in
§'Cost control — VM purchase type' above (which explicitly supersedes the earlier enumeration=Spot /
merge=on-demand split)" — and the section it named as its authority is precisely the one carrying the
`[CORRECTED 2026-08-29]` block retracting that supersession. A cross-reference of the form "per §X,
which supersedes Y" had outlived §X's own withdrawal of the supersession. It now states the split
directly and marks the retraction inline.

### 3. A single-source-file rule that twenty tracked files contradict (`RP-e12e4661`)

The rule described itself as admitting exactly one Python file outside `solve.py`. Measured the same
day: `git ls-files '*.py'` returns **20** and `git ls-files '*.c'` returns **2**. The section's later
paragraphs license three more (`sat.py`, `verify.py`, `verify.c`), leaving **sixteen tracked Python
files covered by no clause of the rule** — four of them named elsewhere in `CLAUDE.md` itself, and
five of them listed in `tests.py`'s own trust base, which makes the contradiction machine-readable.

The wording was a description, not an aspiration, and the failure mode is concrete: an agent obeying
it literally folds `scripts/c2c3_joint_null.py` into `solve.py` and destroys the independence that
this ledger's own 2026-08-28 entry created it to supply — "a published figure whose only reproduction
path was a private script would not be reproducible at all". It is replaced by an **enumerated
approved-separates list** whose dates are *first-tracked* dates measured with
`git log --diff-filter=A -1 -- <path>` rather than asserted approvals; two of the entries (`roae.py`,
2025-07-11; `verify.py`, 2026-04-17) **predate the 2026-04-21 rule** and were never approvals at all.
The prohibition on *new* files outside the list is retained verbatim and is not retracted.

**The `.c` half was stale too, which the charge did not say**, though benignly: "no new `.c` files
elsewhere" was written when `solve.c` stood alone, and `verify.c` is covered by the independence
exception the same section grants.

### Two uncharged siblings, found by reading rather than by the charge sheet

- **The `viz/` directory exception named one of its three files.** The closing paragraph glossed
  `viz/` as "(visualize.py — heavy plotting deps)"; `viz/growth_curve.py` (2026-06-15) and
  `viz/report_figures.py` (2026-07-04) have been tracked for months. All three are now named.
- **The Lean module count was one file behind.** `CLAUDE.md` said the directory "is now thirteen",
  citing `PruneReprFC.lean` (2026-08-15). `git ls-files 'lean/*.lean' | wc -l` returns **14**, and
  `lean/README.md` has said **fourteen** since `SatEncodingFidelity.lean` landed 2026-08-31 — so the
  two files disagreed. `CLAUDE.md` now gives fourteen, names both landings, and cites the command.

**Attribution.** Codex's V2-F56 review located all three charges. The measurements above — the
flattened whole-corpus needle scans that confirmed charge 1's census at two and narrowed charge 2's
from four to one, the `git ls-files` counts and per-file first-tracked dates, and the `lean/` count
discrepancy — are this lane's (Claude). The gate legs prescribed for charges 1 and 3 are not written
here: charge 1's is partly unreachable (GATE 3 cannot see `.c` comments) and charge 3's must be wired
to the filesystem rather than to a string; both are queued in the private prose-lane follow-ups
rather than left implied.

## 2026-09-02 — A conditional-forcing correction that reached one site of eight in six weeks, and a format spec whose g-domain parenthetical contradicted its own seed layer

*(Prose batch P45. Codex V2-F32 #1/#2 and V2-F38 #1.)*

### The rotation charge was already closed — census correction, 2 named, 0 live

V2-F32 #1 charged that `CIRCULAR_KING_WEN.md` §"Symmetry under closure" and
[TR-7](../reports/TR7_CIRCULAR_READING.md) §6 both assert rotation-invariance of "the constraint
system" without naming the C3 exclusion, and named the class as **2 sites in 2 files**. **Both were
corrected earlier the same day** by prose batch P36 (TR-7 v2.3): each page now states the exclusion
conditionally, gives the measured 21-of-31 violation count with `rotate-4 = 888` and
`rotate-16 = 1240`, and `CIRCULAR_KING_WEN.md` carries a one-line reproduction from `verify.py`'s
clean-room C3. The retired wording is registered (the row's key is **RP-ed80aa5e**) and
`scripts/doc_gates.sh rotation-c3` — a claim-shape gate, not a string gate — was added the same
night. **Live sites at this batch: zero.** Nothing was changed for this charge, and the charge is
not wrong about the defect, only about its survival.

### The conditional-forcing correction: three live sites, and what the propagation census actually is

TR-7 v2.1 (2026-07-20, adversarial-review F-14a) restated §3's forcing claim about McKenna's 3:1
even:odd transition ratio as **forced given C4 + C5** — and therefore not an independent design
choice *within* that system — noting that **C5 is itself a regularity read off King Wen**, which
[SPECIFICATION.md](SPECIFICATION.md) grades "**extracted from KW** — King Wen's own multiset". So
"forced" is relative to KW-derived constraints, not to an unconstrained arranger.

That correction stayed inside the report that authored it. A05 recorded that it had reached **zero of
the four** TR-6/`PARITY_ALTERNATION.md` sites; those four landed in prose batch P37 earlier tonight.
The three remaining sites are corrected here:

- **`CIRCULAR_KING_WEN.md` §"What carries over unchanged"** stated the forcing in the unconditioned
  short form and delegated the qualification to `MCKENNA.md` by bare parenthetical. The delegation
  failed: `MCKENNA.md` carried the unqualified form **twice** and the qualification nowhere. The
  bullet now states the conditioning, cites `SPECIFICATION.md` for C5's provenance, and points at
  TR-7 §3. Registered: **RP-49f1f526**.
- **`MCKENNA.md`'s closing assessment of the 25/75 observation** graded the ratio forced rather than
  coincidental with no premise named. Now conditioned in full, with the reason the conditioning is
  load-bearing spelled out rather than left to the citation. Registered: **RP-1ddfe122** — a
  **differently-worded twin**, invisible to any needle built for the `CIRCULAR_KING_WEN.md` site,
  which is why it outlived six weeks of review.
- **`MCKENNA.md`'s cross-reference table**, status cell for McKenna's Rule (3), read "Now a theorem"
  flat. It now reads "A theorem **given C4 + C5**". That two-word cell is **deliberately not
  registered as a fixed string**: it is too generic to gate on and would ban legitimate future use.

**What was deliberately not changed.** TR-7 §3's own bullet headline uses the short form and states
the conditioning four lines below it, inside the same bullet — the charge grades that page passing
and so do we; it was left alone. `solve.py`'s `trigram_tg5b` docstring and the "not a design choice"
sentences in `TRIGRAM_STRUCTURE.md` and `lean/README.md` are about **pure-hexagram pair adjacency
forced by C1**, which `SPECIFICATION.md` records as *classical* rather than KW-extracted — a
different claim, correctly worded, and **not** in this class. `CLAIMS_DECIDED.md`'s "Consequences of
the constraints, not choices" grades the eight literature rules, which are constant on the whole C1
space; also not in this class.

**Why the bare phrase is not registered.** The obvious needle would have false-positived on every one
of those correct C1-family sentences, and on TR-7 §3. The rows are registered on the
**scope-bearing** forms instead, and both notes say so. A green GATE 3 attests that the registered
*strings* are absent, not that the retracted *claim* is; the claim-shaped instrument is a proximity
gate — a forcing claim about a C5-conditioned result must name "given C4 + C5" or the KW extraction
within ±3 lines — and it is **queued**, not written here.

### `GT_LADDER_FORMAT.md`: a normative parenthetical the same spec's seed layer denies

§"Stored domains" said the g-ladder's stored keys at layer `k ≥ 1` are restricted to `last` ∈ the
elements of the mask's pairs, **as an exact characterization of the forward-reachable `last`
values**. Two other sections of the same document deny it: §"Expected boundary layers" requires the
seed layer `n` — which is a g layer with `k = n ≥ 1` — to store **all** `2n` pair elements
*including* `last` values no valid prefix ever reaches, and §"What is convention vs derivable"
already lists the restriction as "pair-elements only". The parenthetical was the odd one out of
three.

The relation is a **superset**, and the stored set coincides with the forward-reachable set in
neither direction: unreachable pair elements are stored at the seed with `g = 1` by the empty-suffix
convention, while a **forward-reachable dead end** has `g = 0` and is skipped. The section now says
this.

**Provenance of the wording**, from the private record: it is the section *heading* of a 2026-07-17
Stage-G review whose *body* states the correct thing. The heading was transcribed into the published
spec as a normative claim. Registered: **RP-1877125a**, on the scope-bearing form — bare
"forward-reachable" is correct and load-bearing in `reports/evidence/f1/FH1_RESIDUAL_DOMINANCE.md`
and `lean/PruneExactness.lean` and is not touched.

**Census extension the charge did not name.** The identical sentence survives as a `solve.c` source
comment on the `v4-compiler` branch at `453e1bf` — the commit this specification records itself as
having been written from. It is outside GATE 3's markdown corpus and outside this batch's edit
scope; it is **queued for the code lane**. The class is **2 sites**, not 1.

**What was deliberately not changed.** The reviewer's failure scenario — an implementer emitting only
the reachable seed entries and going undetected until after an expensive build — does not hold as
stated: `verify.c`'s `--check-g-ladder` reconstructs all `2n` elements at `k == n`, compares the
count, and reports "seed layer content wrong", so a short seed **fails the shipped gate**. What
survives is the intermediate-layer half: at `1 ≤ k < n` the checked rule is a membership bitmap, an
⊆ test rather than the equality the retracted parenthetical asserted, so a suffix-only omission there
is invisible to both the structural check and the f·g cut identity (the missing entries meet
`f = 0`). Tightening that check from membership to equality is a **`verify.c` change** and is queued
for the code lane; no prose in this batch claims the tighter check exists.

**Attribution.** Codex located all three charges (V2-F32 #1/#2, V2-F38 #1). The propagation census
across the flattened corpus, the two census corrections above, the in-class/out-of-class
adjudication of the seven "forced"/"not a design choice" sentences the flattened sweep returned, and
the branch-level survival of the `solve.c` twin are this lane's (Claude). No figure, count,
certificate, theorem or canonical sha changes in this batch.

---

## 2026-09-02 — a wrong division published in three files, corrected in one, and the two sites the correction did not reach

The 2026-09-01 sweep corrected the `floor(NL/158,364)` column of
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"PSB-formula caveat", which was wrong in three of its six
rows. That correction is complete and is verified below. What it did not do is follow the same wrong
arithmetic out of the registry: the **10T** row's bad floor had already been copied into two other
documents, in two different wordings, and both were still live at `origin/main` a day later.

### 1. The 10T auto-divide was published as 63,146,544 in two files — `RP-32ce2154`, `RP-c7f1960c`, `RP-9be4fa60`

- **Documents:** [DEVELOPMENT.md](DEVELOPMENT.md) §"Reproduce from scratch" step 2;
  [BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md) §"Exactly what counts as a node".
- **Claimed BEFORE:** that with `SOLVE_PER_SUB_BRANCH_LIMIT` unset a 10T depth-3 run auto-divides to
  a per-cell budget of **63,146,544**, i.e. **13** nodes per cell below the recipe value 63146557 —
  and, in `BRANCHES_EXPLAINED.md`, that a gap that small (2×10⁻⁷) already suffices to produce a valid
  but non-canonical sha.
- **Claimed NOW:** the auto-divide is **63,145,664** and the gap is **893** nodes per cell
  (1.4×10⁻⁵). Both documents say so, both carry a dated correction marker, and neither figure is
  derived by hand:

  ```
  python3 -c 'print(10**13 // 158364, 63146557 - 10**13 // 158364)'   # 63145664 893
  ```

  The auto-divide is `node_limit / total_branches` — `solve.c`, the block that sets
  `per_branch_node_limit` from `divisor` — and `total_branches` at depth 3 is 158,364, so the floor is
  what the command prints. Checked a second, independent way, because a division that was already
  published wrong once does not get to be checked only by re-dividing — a bracketing multiplication,
  which uses no division at all and so cannot inherit its error:

  ```
  python3 -c 'f=63145664; d=158364; print(d*f <= 10**13 < d*(f+1))'   # True
  ```

  The first draft of this very bullet stated that product by hand and stated it **wrong**. The
  command replaced it, which is the rule this ledger keeps re-learning: a figure ships with the
  command that prints it, or it does not ship.
- **What did NOT change, and this is most of the point:** no sha, no record count, no file size and
  no published canonical parameter. `63146557` was the required value before this entry and is the
  required value after it; the instruction both documents give is unchanged. What changed is that the
  number they printed as the *consequence of ignoring* that instruction is now the number the solver
  would actually use.
- **One claim was withdrawn rather than repaired.** `BRANCHES_EXPLAINED.md` used the 13-node gap as
  its worked example of how little counter drift breaks a canonical sha. Correcting 13 to 893 would
  have left the sentence asserting, still without evidence, that a specific gap was *measured* to
  produce a non-canonical sha; no run was ever cited for it, at either value. It now cites the case
  the project did measure — the 11.2T canonical, where a **derived** PSB of 70,723,144 against the
  published 70,723,196 (a 52-node gap, 7×10⁻⁷) produced output whose sha begins `2184bdd8`, against
  the anchor `0c0fe37c…`, recorded in `solve.c`'s `CANONICAL_RECIPES` comment. That is a smaller gap
  than either published figure and it is attested, so the section's point survives on better evidence
  than it had. **GATE 22 fired on the first version of that sentence**, which wrote the prefix with an
  ellipsis: the full 64-nibble digest of the non-canonical output was never published, so nothing in
  the tree expands it. The gate was right, and the replacement says on the page that the prefix is
  provenance rather than a value a reader can check — the anchor it is measured against is fully
  published, the mismatching output is not.
- **How it was found:** not by the charge sheet. The batch was dispatched against the
  `CANONICAL_HASHES.md` caveat table alone, found that table already correct at `HEAD`, and re-ran
  the table's own six rows two ways before looking anywhere else. The two survivors came from
  grepping the corpus for the *retired* values rather than the corrected ones — a census in the
  direction that finds propagation. Nineteen prior-art hits show four Codex review transcripts
  reading `BRANCHES_EXPLAINED.md`'s sentence verbatim and none filing on it; one internal
  adjudication row cites the 13-node figure as support for a different argument.
- **Registered on scope-bearing forms, deliberately not on the bare number.** `63,146,544` is now
  legitimately narrated in three correction markers — the `CANONICAL_HASHES.md` caveat block and the
  two markers added today — so a bare needle would fire on the very sentences that withdraw it. The
  three registered rows are the two site wordings and the worked-example phrase, which share no
  substring with each other.

### 2. Verification of the 2026-09-01 caveat-table correction it inherits

Re-derived independently before extending it, because this entry rests on it. All six rows of the
`floor(NL/158,364)` column and all six off-by values reproduce exactly from the one-line command the
table ships, and again from a bracketing multiplication `158364 × f ≤ NL < 158364 × (f+1)`, which
holds for all six. The six recipe PSBs the table takes as inputs match `solve.c`'s `CANONICAL_RECIPES`
table row for row — 1T 6315458, 5.6T 35361598, 10T 63146557, 11.2T 70723196, 100T 631456644, 560T
3536157207 — so the table's inputs are the binary's, not a transcription of themselves.

### What was deliberately not changed

- **`CANONICAL_HASHES.md` §"PSB-formula caveat".** Correct at `HEAD`, verified above, untouched. Its
  correction marker keeps `63,146,544` and the other two retired floors; that is narration of a
  withdrawal, which is what the ledger and the registry both exist to protect.
- **`PARTITION_INVARIANCE.md`'s `SOLVE_PER_SUB_BRANCH_LIMIT=35361572`** (§3, §4). It looks like a
  fourth site of the same class and is not: 35361572 is exactly `floor(5.6×10¹² / 158364)`, and it is
  a regression-test budget chosen to be that quotient, not a canonical recipe PSB. The 5.6T canonical
  PSB is 35361598 and is elsewhere. Left alone.
- **`solve.c:1467`'s parenthetical** — "These are EMPIRICAL values (NOT floor(NODE_LIMIT/158364))" —
  which is true of four rows and false of the two deepest, where recipe and floor coincide exactly.
  The rule it defends is right; only its justification overreaches. It is a source-comment change and
  is queued for the code lane, not made here.

## 2026-09-02 — CANONICAL_HASHES.md: three derived figures that do not reproduce — a compression ratio built from mixed units, a retired IOPS floor that survived only where it was load-bearing, and a ninth witness that was an intention

Prose batch P47, charge `UNREPRODUCIBLE_DERIVED_FIGURES` against `documentation/CANONICAL_HASHES.md`.
Three charges, all TRUE and LIVE, all from Codex reviews (V2-F25 #10/#11/#12, corroborated for the
third by V2-F43 #8, the only one of the four already adjudicated ACCEPTED). Each is a number the
registry publishes that cannot be re-derived from what the registry publishes. One census correction
upward and one downward are recorded below, and one of the two Codex prescriptions is declined.

### 1. A compression ratio assembled from a decimal numerator and a binary denominator (`RP-9788f906`)

The v2 100T row published its gzip ratio beside the two byte counts that determine it, and the ratio
did not follow from them. MEASURED: the archive is 13,462,264,289 bytes; the logical artifact, per
this document's own §Format size convention, is `3,663,580,914 × 32 + 32 = 117,234,589,280` bytes;
the quotient is **8.708×**, not the value published. The mechanism is exactly reconstructible rather
than merely plausible — 13,462,264,289 bytes is **12.54 GiB**, the logical size is **117 GB decimal**,
and dividing the second by the first reproduces the retired figure to three significant digits. A
figure sitting between the two operands that contradict it is the easiest kind to leave standing,
because nothing in the sentence looks unsourced.

Both sites now state the operands in bytes and carry the one-line command that derives the ratio, so
the number is checkable without any archive access. No sha256, record count, file size or archive
location is affected: this is a derived field only. It is not cosmetic in the one use the figure has
— storage or transfer planning at the retired ratio under-allocates compressed capacity by ~7%.

**CENSUS CORRECTED UPWARD.** The charge named one site. A whitespace-flattened sweep for the
*retired* value found **two**: the registry's frozen-lineage section and `HISTORY.md`'s 2026-05-23
v2 100T entry, which is where the mixed units are actually visible ("117 GB → 12.54 GB"). The
registry site had been rewritten into bytes at some point and so no longer displayed the unit error
it inherited — the sweep for the withdrawn figure found it anyway, which a sweep for the class would
not have.

### 2. A gate criterion retired in code three months before it was retired in this document (`RP-c410da42`)

The `SOLVE_SKIP_IOPS_CHECK=1` bullet named a fixed single-thread fsync/sec floor as the disk-IOPS
pre-flight's criterion. **No such floor is in the shipped binary.** It was the task-#107 design of
2026-05-27 and was retooled away by task #115 on 2026-05-29 *because it was mis-calibrated*:
`solve.c`'s own retool comment records that single-thread fsync is latency-bound and that no
network-attached managed disk reaches the rate (HDD 134/sec, Premium P40 218/sec measured), so the
gate fired on every durable-disk canonical run.

The shipped gate is a ratio, not a rate: a concurrent probe over `min(threads,32)` workers measures
aggregate throughput, and the launch is refused when projected `fsync_wait / est_wall > 0.25`.
Because `expected_fsyncs` and `est_wall` are both linear in `SOLVE_NODE_LIMIT`, **the node budget
cancels**, and the implied aggregate floor is `threads / (1.4 × SOLVE_FSYNC_BATCH_SIZE × 0.25)`
fsync/sec — **≈366/sec at the canonical 128 threads with batch 1**. That derivation, and the command
that evaluates it for any thread count, are now on the page; there was previously no way to obtain
the criterion from the document at all.

**Why this one was worth the space: the error was fail-open for the reader.** A host measuring 500
aggregate fsync/sec *passes* the real gate at 128 threads, and this bullet instructed its operator to
disable the gate — surrendering the protection against a genuinely fsync-bound disk that the gate
exists to provide. That is the same shape as the pre-flight failures catalogued elsewhere in this
ledger: a numeric check that cannot fail its target, sitting immediately before real compute.

**CENSUS CORRECTED DOWNWARD, in the useful direction.** Three occurrences of the retired rate exist
in the corpus; **only this one was live**. `HISTORY.md`'s #115 entry and `SOLVE_C_CLI.md`'s exit-code
31 row both narrate it as superseded and both state the ratio form correctly — so the single site
that still asserted it was the operational one, in the document a launcher author reads. `solve.c` is
**deliberately not changed**: the code has been right since 2026-05-29 and this was a documentation
defect only.

### 3. A ninth witness that was written as an intention and closed as a fact (`RP-8c9b7bd3`)

The d3 11.2T section carried three different counts for one campaign: a heading of eight, a table of
seven data rows, and a trailing sentence saying a 2026-06-13 re-derive was archived to add a ninth.
Codex V2-F43 #8 was adjudicated ACCEPTED on the first two; V2-F25 #12 filed the third separately and
prescribed renumbering the heading down to seven.

**That prescription is declined, on the same evidence that declined its twin in `HISTORY.md`.** The
eighth path is real and locatable: the post-`#45` patched-binary fresh full-enum of 2026-05-04
04:21Z, which reproduced `0c0fe37c…` byte-identically and is recorded in `HISTORY.md` under "May 4 –
May 5, 2026 PDT". Prose batch P43 restored it to `HISTORY.md`'s method-indexed roster after the same
eight-versus-seven discrepancy was charged there; it belongs equally in this build-indexed table,
where it is a distinct binary shared with no other row. Renumbering the heading would have deleted a
real validation path from the public record for the second time. **The row has been added instead**,
and the heading, the table, and the two restatements in §Quick reference and §Validation status now
all read eight.

The ninth is a different matter and is **withdrawn rather than repaired**, because it was never
evidenced. Git history settles the provenance: the sentence was written 2026-06-13 with the re-derive described as *in flight* and the further
witness named in the infinitive as its **purpose** — a statement of intent about an unfinished run. (The
retired wording is not quoted here: it is registered, and quoting it would reintroduce into the corpus the
exact string GATE 3 now exists to keep out.) A 2026-07-04 consistency sweep closed the in-flight wording to the past tense on the
evidence that the 3-point trajectory analysis had consumed the run, and carried the purpose clause
across unchanged. Consumption is evidence the run **completed**; it is not evidence its **sha
matched**, and a witness is the second claim. **No sha attestation for that run is published anywhere
in the tracked corpus** — checked in both directions, including the fact that it has no entry in the
section's own Archives list, which every other witness campaign does. It is therefore not counted. If
the run's sha and host tuple are published later it becomes a table row, and the count moves with the
table rather than ahead of it.

**A definition that was never given.** Neither the heading nor any restatement said what made a path
independent, so a reader could not tell whether re-merges, rebuilt binaries or thread-count variants
counted. The criterion is now stated — a row must differ from every other in source commit, build
flags, physical host, CPU architecture, or merge path — together with a command that recomputes the
count from the table's own rows, so the heading can no longer drift from what it introduces.

**Verified in the other direction too.** V2-F43 #8 also cited `PARTITION_INVARIANCE.md:294` as
restating the count as seven. That site no longer states a number: it now names this table as "the
witness list of record" and defers. So the charge's two sites were one live site, and this document
is the sole authority for the count — which is why making it computable here was the fix.

### What was deliberately not changed

- **The power-law fit.** `records ∝ T^α with α ≈ 0.67`, its pairwise legs 0.69 and 0.65, and the
  ≈16.7 B projection at 1120T carry no reproduction command anywhere public, so they were examined as
  a fourth candidate under this batch's charge. They were left alone because they **do** reproduce:
  re-derived this batch from the three published record counts, the 3-point log-log slope is 0.6727,
  the legs are 0.6889 and 0.6504, and `10,525,271,997 × 2^0.6727 = 16.78 B`. The published figures are
  correct to their stated precision. A repro command would still be an improvement, but the charge is
  for figures that do not reproduce, and adding one here would ripple into `HISTORY.md`,
  `LEADERBOARD.md`, `PROJECT_OVERVIEW.md`, TR-4 and `viz/`, which is a separate sweep. Recorded so the
  next batch inherits the measurement rather than repeating it.
- **The `~8×` v2 11.2T compression precedent** quoted in `HISTORY.md` beside the ratio corrected
  above. The v2 11.2T archive's compressed size is not published, so the comparison cannot be checked
  either way; the corrected 8.708× still exceeds it, so the sentence's claim survives and the hedge is
  left as-is rather than sharpened on unpublished bytes.
- **`solve.c`.** Correct on both the IOPS gate and the recipe table; item 2 above is a doc-only defect.

## 2026-09-02 — a determinism envelope corrected in its source report, and the two HISTORY.md sites the correction did not reach

`documentation/PASS1_TRAJECTORY_DETERMINISM.md`'s headline was corrected on **2026-09-01**: the
report claimed a far tighter run-to-run agreement, over a node range starting a decade lower, than
its own seven-row comparison table supports. Only two of those seven rows meet the retired envelope
and the first row misses it by **165×**; the report's body had already stated the table-supported
figure twice, so the headline contradicted its own document.

**The correction did not travel.** A day later `documentation/HISTORY.md` still carried the retired
envelope at **two** sites, in two different shapes — the April-24 trajectory-match paragraph, and
the findings-directory index line, which had reformatted the same figure into a superscript node
range. Both are corrected now (prose batch P64), each with a dated callout naming its registry key.

**The census, before → after.** The retired value was searched for as a *value*, not as a shape,
which is what found the second site: a page that has reformatted a wrong number no longer looks
wrong. Over the tracked corpus, live carriers of the retired envelope went **2 → 0**, both in
`documentation/HISTORY.md`. Three neighbours were checked and deliberately **not** swept:

- `documentation/README.md`'s findings index already carried the corrected figure — under 1% from
  10¹¹ to 10¹³ with the 10¹⁰ row named as a startup transient — and is correct as written. (The
  charge sheet named this site as `README.md:52`; the file is `documentation/README.md`, and the
  repository-root `README.md` contains no form of this figure at all.)
- `documentation/PASS1_TRAJECTORY_DETERMINISM.md` quotes the retired wording inside its own
  retraction note, which is the legitimate narration of it.
- the `~0.2%` / `~0.5%` new-cell contributions in the 3-point scaling trajectory are a *different*
  measurement and stand untouched.

**Registered:** `RP-17381934` and `RP-501fb35a` in `documentation/RETRACTED_PHRASES.tsv`, one per
shape, because a single needle would have matched only one of the two sites. Both were verified at
registration to match the two defective sites and nothing else in the tracked corpus, and neither
matches the source report's own retraction note — one intervening word separates them.

**What is corrected, and what is merely narrower.** This is **not** a re-measurement. The corrected
envelope is read off the table that was already published. What the correction does is shrink the
claim to the evidence that exists.

**A limit on that evidence, which the source report states and this ledger repeats.** The
comparison's second column comes from a run whose log was **never archived**, and no public script
recomputes it, so the seven ratios cannot be re-derived by a reader. The **first** column can be,
and was, at correction time — from the log shipped in this repository:

```
$ gzip -dc runs/20260422_passA_10T_d64_laggard/22_0_30_1_20_0/run.log.gz \
  | awk '/B nodes,/ && /sol,/ {gsub(/B/,"",$1); n=$1+0; gsub(/M/,"",$3); s=$3+0; N[++c]=n; S[c]=s}
         END{split("10 30 100 300 1000 3000 10000",T," ");
             for(i=1;i<=7;i++){t=T[i]+0; b=1;
               for(j=1;j<=c;j++) if((N[j]>t?N[j]-t:t-N[j]) < (N[b]>t?N[b]-t:t-N[b])) b=j;
               printf "  target %7dB -> nearest sample %8.1fB, sol = %10.1fM\n", t, N[b], S[b]}}'
  target      10B -> nearest sample      9.1B, sol =      345.0M
  target      30B -> nearest sample     27.8B, sol =     1064.5M
  target     100B -> nearest sample    100.7B, sol =     3667.7M
  target     300B -> nearest sample    297.0B, sol =     9981.4M
  target    1000B -> nearest sample    999.9B, sol =    32247.4M
  target    3000B -> nearest sample   2995.5B, sol =    93205.6M
  target   10000B -> nearest sample   9997.7B, sol =   298819.9M
```

All seven reproduce the report's first column exactly. That also settles one thing the report says
is unsettleable: it states that the node-matching rule "cannot be re-derived by a reader", and the
rule is **nearest sample** — first-sample-at-or-above does *not* reproduce the column, nearest does,
on all seven rows. The report's caveat is therefore correct about the second column and too wide
about the first. Correcting that sentence is owed on
`documentation/PASS1_TRAJECTORY_DETERMINISM.md`, which this batch did not own; it is recorded here
rather than left to be rediscovered.

**Attribution.** The census, the two corrections, the registry rows and the reproduction above are
this lane's (Claude, Opus 5) under operator direction, and each is reproducible with `git`, `grep`,
`gzip` and `awk`. The charge that opened this item came from the prose queue; its scoping note about
the neighbouring index line was substantively right and wrong about the path, which is recorded
above rather than quietly obeyed.

## 2026-09-02 — two `[REFUTED 2026-05-16]` callouts that had been owed in HISTORY.md, and the composite that inherited the refuted factor

`documentation/HISTORY.md` narrates the AVX-512 (#46) null result under its May 18, 2026 entry: a
definitive 1T paired bench measured AVX2 at 433.0 s against AVX-512 at 434.6 s — **0.9963×**, Welch
t = −1.281, 95% CI [−4.05, +0.85] s, null not rejected — and the work was closed via REVERT, gcc
having already auto-vectorized the one loop that benefits.

Two earlier sites in the same file still carried the **1.4–2.0×** projection with no callout: the
bullet that first stated the ceiling, and the Phase 1 status row that still listed the item as the
high-value candidate. Both now carry a dated `[REFUTED 2026-05-16]` callout naming the measurement
that closed it. **The line numbers on the charge sheet had drifted** — the tracked item was recorded
at `:1510-1514` and `:2610`, and the figures sit at `:1521` and `:2619`; both were located by
content.

**Census, before → after.** Live carriers of the projection with no refutation callout went
**2 → 0** in `documentation/HISTORY.md`. Two further sites were examined:

- a third `HISTORY.md` occurrence sits *inside* the refutation narrative itself and needs no
  callout;
- 🔴 `documentation/DEVELOPMENT.md` carries the same projection, as a live expectation, with no
  callout and no reference to the null result. That file was outside this batch's ownership and is
  **not** fixed here. It is the same class of defect and is recorded so the next pass can close it.

**A sibling the charge did not name.** The CPU-optimization-bundle bullet immediately below the
first site multiplies the refuted AVX-512 factor into a combined-speedup composite. It is now scoped
rather than repaired: the composite's premise does not hold as written, no replacement figure is
substituted because none was measured after the refutation, and the bundle's other factors moved in
both directions when measured separately. Flagged under the standing caution against banking
undirected multiplicative composites.

**Not verified, and said plainly.** The three commit hashes the refutation narrative cites as its
evidence (`cd4e61c`, `b26cd9b`, `0783d52`) **do not resolve on any ref or tag in this repository** —
checked against the full history and every tag, not a shallow clone. They are v2-lineage commits and
the v2 lineage is closed. The callouts added here therefore cite the *measured bench figures*, which
are stated in the narrative itself, and not the commits. Whether those hashes should be annotated as
unresolvable is a separate question this batch did not settle.

**Attribution.** Located and corrected by this lane (Claude, Opus 5) under operator direction; the
owed-callout item was raised by an earlier batch in the same lane and had gone unwritten.

---

## 2026-09-02 — a reproducibility contract missing a parameter at its second site, and the analyze-sizing entry a prior pass reported but left standing

Prose batch **P70** worked eight ACCEPTED charges against `documentation/CAMPAIGN_METHODOLOGY.md`
(Codex reviewers V2-F22, V2-L05, V2-L11; adjudication batch 11). **Six of the eight were already
fixed at HEAD** by a 2026-09-01 pass and are listed at the end as verified-no-op rather than
reported as work. The two that were still live are recorded here, and both were half-fixes: in each
case the earlier pass corrected one site of a defect and left a second one that the same charge had
named.

### 1. A byte-identical-reproducibility contract stated over an incomplete tuple (`RP-60bf9367`)

`CAMPAIGN_METHODOLOGY.md` §1 defines what a canonical artifact is, and item 4 of that definition
promised byte-identical reproduction on independent hardware given a **two**-element tuple. Partition
depth was absent from it.

The omission is not cosmetic, and the document says so itself three sections later: `SOLVE_DEPTH` is
sha-determining, and omitting it does **not** raise an error, because the code default is `2`. A
reader who plans a reproduction from §1's definition alone therefore enumerates the depth-2
partition and can never match a depth-3 sha, with nothing to signal why.
`CANONICAL_HASHES.md` §"Reproducibility parameters" settles the point empirically: it publishes
**distinct d3 and d2 canonicals at the identical 10 T node limit**, which is only possible if depth
is an element of the tuple.

The same defect at this file's "Why budget matters" tuple was corrected on 2026-09-01 to a
four-element form — source commit, partition depth, global node limit, per-sub-branch limit — and
that site carries its own marker. **The §1 site was not swept in that pass, although the charge that
raised it named both.** Item 4 now states the same four elements and points at the fuller treatment
below it.

**Census, before → after: 1 → 0.** The retired clause was registered on the full phrase rather than
on the words "search budget", which are legitimate throughout the corpus, and it matched
`CAMPAIGN_METHODOLOGY.md` and nothing else under GATE 3's own character fold before the fix.

### 2. A per-pass disk time that contradicts its own stated bandwidth, and a cost comparison built on a projection (`RP-a8eb3931`, `RP-dd27f0bf`)

`documentation/HISTORY.md`'s 2026-06-10/11 analyze-VM-sizing entry stated two figures and then a
quotient that is not theirs. The file is 336,808,703,936 bytes and the entry names ~450 MB/s of
Premium SSD bandwidth; that division is **748 s ≈ 12.5 min** per pass. The figure published beside
it was about 76 % larger, implying ~255 MB/s. This is a division, not a forecast — one of the two
stated numbers had to be wrong, and it was the derived one. It is corrected in place.

The dependent "~3 h on D32" is **withdrawn rather than re-derived**: it was computed from the retired
per-pass figure, and no D32 analyze run at 560 T was ever executed against which a replacement could
be checked.

The same entry then priced the run by multiplying an hourly rate by the D128 **projection**, and
concluded that D128 costs marginally more than D32 while finishing sooner. The measurement refutes
the numerator: the post-rewrite D128 analyze run completed in **13,631 s (3 h 47 m)**, recorded eight
lines below in that same entry, so at the stated $5/h the run cost **~$18.93**, roughly 2.5× the
published product. The comparison is withdrawn rather than rescaled, because its D32 half has no
measured wall at any scale.

**What was deliberately preserved.** The sentence "Projected total wall on D128: ~1.5 h" stands
exactly as written. It is correctly labelled a projection of that date, and it is the primary
evidence `CAMPAIGN_METHODOLOGY.md` rule 8 cites when showing that the same figure was later restated
*there* as an accomplished fact. Deleting it would have removed the ground under a correction that
depends on it.

**How this site was found — and it was not found by this batch.** The 2026-09-01 pass that corrected
rule 8 in `CAMPAIGN_METHODOLOGY.md` located this HISTORY.md entry, named it in its own marker, and
recorded that it was "reported, not edited". That handoff is now closed, and the marker carrying it
has been extended rather than reworded, so the trail from report to fix stays readable. The line
number on the charge sheet had drifted by 18 lines; the site was located by content.

**Census, before → after: 1 → 0 for each of the two retired forms.** They were registered as **two
narrow needles, not one**: they share no substring, sit in different sentences, and a single needle
would have caught only one of them. The per-pass form was registered on its verb-bearing clause
rather than on the bare number, because `CAMPAIGN_METHODOLOGY.md`'s own correction marker
legitimately quotes that number in different words and a bare needle would have fired on it.

### A prescribed fix that had been dropped, and is now applied

Charge 8 (V2-F22 #4) was adjudicated against §6's claim that a cross-host reproduction may yield a
different sha at an unchanged record set — impossible under the published format, since the sha is a
pure function of the record set. That mechanism was corrected on 2026-09-01. But the adjudicated fix
had a second clause the pass did not apply: **also compare the record count against the published
count.** §6 now carries it. The canonical layout is a 32-byte header plus fixed 32-byte records, so
the count is `(filesize − 32) ÷ 32`, and for the 560 T canonical
`(336,808,703,936 − 32) ÷ 32 = 10,525,271,997` — the count published for that scale. The bullet is
explicit that a matching count does not prove set equality, only that the walk did not stop short.

### Verified still-live FALSE — six charges already fixed at HEAD

Reported as no-ops rather than as work, each checked by content because the line numbers had drifted:
the §1/§7 front-matter box (now states the §10 settlement, no replacement or checklist language
survives anywhere in the tree); the extension-cost and extension-wall rules 9 and 10 (rebuilt from
the 100 % cap-hit fraction, dollar figures withdrawn for want of a ledger); the delegated cost
authority (the delegation no longer includes cost estimation, and the older guide's worked example
now shows planned-against-actual); the exhaustion floor (the arithmetic is corrected and the
single-cell probe is now published in full, with its comparability assumption and n = 1 caveat, in
`CANONICAL_HASHES.md`); the mid-run zero-cell rate in the operations bullet (replaced by the final
actuals); and rule 8's wall and cost (re-derived from the measured 13,631 s).

### What was deliberately not changed

- **The realized cost of the 560 T campaign is not published here.** The adjudication asked that the
  older guide's worked example be annotated with it, but the figure exists only in operator-held
  material and has no public reproduction path. The example's cost row already says the planned
  range is unreliable and declines to state an actual, which is the honest form; publishing a number
  a reader cannot check would be a weaker one. Left pending the open ruling on private-material
  citation.
- **The single-cell probe's cost and wall are not published**, for the same reason. The probe's
  *derivation* — the addressable cell, the three-rung ladder, the 2,488 tasks, the comparability
  assumption — is public and reproducible from the command shown; its dollar and minute figures are
  host-specific measurements with no public artifact behind them.
- **`CAMPAIGN_METHODOLOGY.md`'s "Why budget matters" and rule 8 correction markers quote wording that
  a strict reading of the adjudication's proposed grep legs would forbid.** Those legs were proposed
  as file-wide phrase bans; applied literally they would fire on the correction markers that exist to
  narrate the retraction. This batch did not write those gate legs and flags the conflict for
  whoever does: the registry's allow-column, not a file-wide ban, is the mechanism that handles it.

**Attribution.** Located and corrected by this lane (Claude, Opus 5) under operator direction; the
charges were raised by Codex reviewers V2-F22, V2-L05 and V2-L11 and adjudicated in batch 11. The
HISTORY.md site was surfaced by the 2026-09-01 pass, which recorded it rather than fixing it — this
batch's contribution there is closing the handoff, not finding the defect.

---

## 2026-09-02 — ROAE_PY_CLI.md: a randomness census three sections wide against a code base of thirteen, a survivor bar printed one term short of the floor above it, a grammar called escrowed that has no row, and two history bullets a year off

Prose batch **P71** worked five ACCEPTED charges against `documentation/ROAE_PY_CLI.md` (Codex
reviewer V2-F49; adjudication rows 5, 6, 9, 11 and 14). **All five were still live at HEAD** — none
had been closed by the 2026-09-01 pass — and each was verified against `roae.py` before it was
edited, not against another document. A sixth defect, out of charge, was found while restating a
sentence the page already carried; it is recorded last because it is the one a reader would have
been most likely to act on.

### 1. A null-model promise the same document withdraws before it ends (`RP-01d32a30`)

The DESCRIPTION section stated that the program compares every one of its 29 measures against an
appropriate null. The NOTES section, twelve lines from the end of the same file, already used the
correct quantifier — *some* analyses include null-model framing — so the page contradicted itself on
its face.

`CRITIQUE.md` settles which reading is right, and it is the tail's. Trigram transition matrices have
~1 expected observation per cell, so no goodness-of-fit test has power against them and the matrices
are ruled descriptive only; windowed entropy is exploratory visualization with no null and no
significance test; and the 64×64 Hamming matrix is a fixed property of the 6-bit encoding, identical
under any ordering of the 64 hexagrams, so a null over *orderings* is not a meaningful comparison for
it at all. The DESCRIPTION now scopes the claim to where a null comparison is meaningful, names those
sections, and points at both `CRITIQUE.md` and the section below.

**Census, before → after: 1 → 0**, corpus-wide under GATE 3's own character fold.

### 2. A randomness census that named three sections and missed nine (`RP-0b8a8eab`, `RP-7f2b1c58`)

This is the charge that changed the most text, and the adjudication's own census was itself one
section short.

Two places in the page told a reader which analyses use random numbers, and both named the same
three: `--stats`, `--bootstrap`, `--constraints`. The REPRODUCIBILITY list went further and put
`--complements` and `--trigrams` in the *deterministic* column, with the mechanism spelled out —
their output was said to be a function of the King Wen sequence and nothing else.

The code says otherwise, and it is not close. **Twelve** of the 29 sections call `_reseed()`:
`--complements`, `--palindromes`, `--canons`, `--entropy`, `--path`, `--markov`, `--constraints`,
`--mutual-info`, `--neighborhoods`, `--recurrence`, `--bootstrap`, `--stats`. `print_complements`
alone runs a 10,000-shuffle null.

**Measured at correction time**, because a census is a claim until it is run: `--seed 1` against
`--seed 2` gives *visibly different output* for eight of the nine sections the page had not listed —
`--palindromes`, `--canons`, `--entropy`, `--path`, `--markov`, `--mutual-info`, `--neighborhoods`,
`--recurrence`. A researcher who pinned `--seed` for "the Monte Carlo analyses" as the page defined
them left every one of those unpinned while believing them closed-form.

`--complements` is the ninth, and it is byte-identical across seeds. That is not a rescue of the old
text; it is the reason the defect was invisible. Its 10,000-trial aggregates concentrate enough that
the one-decimal printed summary does not move — **empirical concentration at the current print
precision, not determinism**. One added decimal, or a smaller trial count, breaks it silently. The
page now says so in those words and tells the reader to treat the section as randomized.

**A thirteenth section the charge did not name.** The adjudication's census was taken by grepping
`_reseed` and returned thirteen call sites, one of which is the `--cast` mode rather than a section.
`print_trigrams` does not appear in it — and `print_trigrams` runs three 10,000-trial permutation
nulls, off `random.Random(42)`, a constant private to the function. So it is a Monte Carlo section
that is byte-identical on every run **and ignores `--seed` entirely**: a third category that neither
the old two-way split nor the proposed fix had a slot for. The page now carries a three-way census —
12 seed-honouring, 1 internally pinned, 16 closed-form — which sums to 29, and each of the 29 flag
names was checked against `roae.py`'s argparse definitions rather than copied from the prose.

All 16 sections in the closed-form group were **run under `--seed 1` and `--seed 999` and confirmed
byte-identical**; the claim is not inferred from the absence of a grep hit.

The census is now reproducible from the page rather than asserted by it. Both published commands
were executed and return exactly what the page says they return:

```
$ awk '/^def /{f=$0} /^ +_reseed\([0-9]+\)/ {print f}' roae.py \
    | sed 's/^def //;s/(.*//' | sort -u
print_bootstrap
print_canons
print_casting
print_complements
print_constraints
print_entropy
print_markov
print_mutual_info
print_neighborhoods
print_palindromes
print_path
print_recurrence
print_stats

$ grep -n 'Random(' roae.py
480:    _rng = _rnd.Random(42)
4023:    rng = random.Random(seed)
4052:    rng = random.Random(seed)
4568:    rng = random.Random(seed_base + seed_off + batch_idx)
```

Line 480 is inside `print_trigrams`; the other three are the grammar-search and pre-registration
machinery, which take their seed as an explicit argument.

**Census, before → after: 1 → 0 for each of the two shapes.** They were registered as two needles
rather than one because they share no substring; a single needle would have closed one site and left
the other reading like closure.

### 3. A grammar described as pre-registered that has no escrow row (`RP-b0f4f882`)

The `--grammar-search` section described the U2 search space with a term that, everywhere else in
this project, denotes a hash-escrowed artifact. It is not one.

`PREREGISTRATION_ESCROW.md` publishes ten hashes and none of them is the grammar. It also publishes,
since its 2026-09-02 amendment, an itemized list of six further frozen pre-registrations that it does
**not** escrow — and the grammar is absent from that list too, so it is not even a recorded omission.
What the grammar has instead is `roae.py` asserting its own frozen sizes at startup: 118 transition
atoms, 52 position atoms, 24 gates per domain, checked in the same file that defines them. That is
self-attestation, and an outside reader cannot use it to establish that the grammar predates any
particular run.

The section now says frozen in code and self-attested, states plainly that no external escrow
artifact exists for it, and contrasts it with `--prereg-h1h3` below, which does have a row.

**The second site the charge named is a different problem and got a different fix.** The
`--prereg-h1h3` section claims verbatim implementation of a frozen spec the reader cannot read. That
spec *is* escrowed — `PREREG_H1_H3_TEST_2026_07_26.md`, one commit in its private history, so its
escrowed digest and its freeze-state digest are the same value. Nothing there needed retracting; what
was missing was the pointer. The section now carries a scope note routing the reader to the escrow
page **and to that page's own statement of its limits**: the hash makes content checkable only on
unredacted disclosure, establishes nothing about correctness, and — for this row specifically — was
published 2026-08-22 against a file first committed 2026-07-28, which is *after* the date the
filename carries. The escrow page calls its own first-committed column a claim rather than a proof,
and the CLI reference now says so at the point of use instead of leaving the reader to find it.

**Census, before → after: 1 → 0.** The needle is the enumerates-clause, not the bare term, which also
appears in `roae.py`'s `--help` text — outside this gate's markdown corpus, and outside this batch's
ownership. See the code-owned siblings at the end.

### 4. Two bars, one of them printed, and the page described the other (`RP-eaf9bc64`)

The U2 MDL ledger was described as weighing bits-explained against the statement cost **and** the
selection charge, and then printing survivors. That reads as one bar. There are two, and the one that
governs the printed list is the weaker.

The detection-floor line applies the full bar. The survivor gate is `if be > L:` — no selection term.
A candidate sitting between the two therefore prints as a `SURVIVOR?` line and flips the run verdict
to `ATTENTION` **without having cleared the multiple-selection charge**, and the JSON `verdict` and
`survivors` fields carry no qualifier saying so.

The direction matters and is stated in the fix: this over-flags, it does not under-detect. Nothing
that clears the full bar can be lost this way. The cost is a reader — or a downstream consumer of the
JSON — treating a shortlist entry as a result.

**Credit where the adjudication placed it, and it is deserved: the code already knows.** It labels
the tally *MDL-net-positive (pre-selection)*, ends every candidate line with a question mark, and
heads the margin list *closest approaches (bits-explained − L(C), pre-selection)*. The implementation
was honest about the two-tier structure and the document was not. The section now carries a
two-row table naming each bar and where it appears, and says explicitly that the trailing `?` is
doing real work.

**Census, before → after: 1 → 0.**

### 5. A history section whose two dated bullets are wrong by up to a year (`RP-44ddcb59`, `RP-2bfae150`)

Both were checked against `git log`, not against `HISTORY.md`.

The first dated the section buildout to **2026-03**. This repository has **zero commits in that
month** — the date census jumps from 2025-08-09 straight to 2026-04-06. The buildout is `37065808`,
2026-04-06 ("Add hexagram names, trigram analysis, spark lines, Monte Carlo, and CLI flags", 24
commits that day), and the 29th section arrives at `7d84ffe5`, 2026-05-19.

The second credited a review dated before 2026 with surfacing the trigram name swap bug. The
trigram-names code was **added** 2026-04-06 and the swap **fixed** 2026-04-07 (`dc489e8c`); a review
cannot have surfaced a defect in code that did not exist. Care was taken not to over-claim here: the
repository genuinely does begin 2025-07-11, so a pre-2026 review is not impossible in principle. It
is refuted for this bullet specifically — only six commits predate 2026-04 and none touches trigram
names, XOR or null-model framing, the other three items the bullet credits all land 2026-04-08/09
(`5494ebac`, `32bf7bf5`, `d149bb70`), and `HISTORY.md` frames the entire phase as its "Prelude —
Before April 10, 2026". Both bullets are redated from git and now cite the commits.

**Census, before → after: 1 → 0 for each.** Registered with their full clauses because bare `2026-03`
occurs legitimately elsewhere in the corpus — a publication date in `CITATIONS.md`, a Microsoft Learn
SKU date in `HISTORY.md` — and a bare needle would have fired on both.

### 6. Out of charge: a correction that landed in the code and one document, and missed three sites in this one (`RP-733f9b69`, `RP-e11d6b76`)

This page said `--cast` was not reproducible under `--seed`, and gave the mechanism: the cast path
returned before the global seed was installed. **That was true and measured when it was written, and
it stopped being true the same day.** Code batch C2 (`3901097b`, 2026-09-02) hoisted the global-seed
assignment above the early-dispatch ladder, and `tests.py` now holds the behaviour with
`CAST_SEED_DETERMINISTIC=1`, verified red against the pre-fix file.

Re-measured here before touching the text, with `python3 roae.py --cast --seed N | sha256sum`:
three `--cast --seed 42` runs are byte-identical, at
`d80da293985398e5b0dd2d555495aa8f067d2bbdcb73d518502774db09f31b36`; `--seed 7` gives a different
casting, `613fa06273d1877b90347f97a5d942c16794efbb07f460e38b76f1f9396c0ae4`; and three unseeded runs
give three distinct ones. These are digests of program stdout, reproducible from the command above on
any host with the same `roae.py`; they are not digests of any file in the tree. The behaviour is now
exactly what a reader would want.

`GUIDE.md` was corrected on the day of the fix and carries a dated history note. **This page carried
the retired claim at three sites** — the modifier note, the reproducibility list, and the comparison
table, where it had been compressed to a four-word parenthetical. This was found only because the
batch restated the sentence while fixing something else, which is the honest account of how it
surfaced. All three are corrected, and the modifier note now carries a dated history note in the same
shape `GUIDE.md` uses, rather than deleting the old claim.

The two prose shapes and the table parenthetical were registered as two needles. The third site is
the reason: it had reformatted the claim into a parenthetical and no longer looked like the claim,
which is the recurring lesson that a census must hunt the retired *content*, not the defect's shape.

**Census, before → after: 1 → 0 for each shape**, and `GUIDE.md`'s own narration of the same
correction uses different wording and is correctly not caught.

### Verified still-live before editing

All five charged rows were confirmed live at HEAD against `roae.py` before any edit. **Every line
number on the charge sheet had drifted** — the file had grown by roughly seventy lines since the
sheet was written — and every site was located by content. The sheet's `:185-192`, `:167-172`,
`:216-222`, `:405-407`, `:53-55`, `:41-43` and `:479-484` should be read as identifiers, not
addresses.

One item on the sheet was checked and found **already correct**, and is recorded as a no-op rather
than as work: the dependency row asserting `roae.py` is Python-3-stdlib-only. Its imports are
`argparse`, `cmath`, `json`, `math`, `os`, `random`, `sys`, `time`, `unicodedata`, plus `io`, `re`,
`subprocess`, `itertools` and `importlib.util` in function scope — every one of them standard
library. `wkhtmltopdf` and `dot` are invoked through `subprocess` and skipped when absent, exactly as
the row says.

### What was not changed, and why

- **The JSON `survivors` and `verdict` fields still carry no pre-selection marker.** The adjudication
  offered two remedies for §4 — apply the charge in the survivor gate, or state the two-tier reality
  in the document. This batch owns the document and took the documentation remedy. Stamping the
  applied bar into the JSON record is a `roae.py` change and is left to the code lane, which is the
  only place it can be made correctly.
- **`roae.py`'s `--help` text carries the same grammar wording this batch retracted from the
  document.** It is outside GATE 3's markdown corpus and outside this batch's ownership, so it is
  flagged rather than fixed. It is a real sibling: the retraction is incomplete until it lands.
- **The U2 grammar was not escrowed.** The adjudication named creating an escrow row as an
  alternative to scoping the claim. Hashing the grammar definition block is an operator action on
  operator-held material, and the honest scoping was available without it, so the scoping was taken
  and the escrow option left open. The page now states the gap, which is what makes the option
  legible.
- **No private filename was newly cited.** The one private artifact this batch points at,
  `PREREG_H1_H3_TEST_2026_07_26.md`, is already named in the public escrow page and is cited by
  routing the reader there rather than by asserting anything new about it.

**Attribution.** Located and corrected by this lane (Claude, Opus 5) under operator direction; the
five charges were raised by Codex reviewer V2-F49 and adjudicated in the V2 batch. The
thirteenth randomized section, the `--cast` staleness and its three sites were found by this batch
while verifying the charges, not by the review.
## 2026-09-02 — TR-11: a per-layer profile that stopped four layers short of its own peak, a withdrawn quantity back with an extra digit, a closed universal inside a sentence a later pass had already edited, and an evidence pointer aimed at a directory that holds none of it

**Charges.** Codex reviewer V2-F02, adjudication batch 4, charges 2, 3, 4 and 5, worked as prose
batch P72. Two charges of that batch are not corrections here and are recorded as such: **charge 6**
(the header version line disagreeing with the revision table's *(current)* row) was re-verified at
HEAD and is **already fixed** — v1.24 refreshed the subtitle on 2026-09-02 and recorded the miss in
its own row — so it is logged as a no-op, not as work; **charge 1** (an out-of-core scratch-budget
example) belongs to another lane and was not touched.

### 1. §6's measured layer profile stopped four layers short of its own peak, in a unit it did not have

§6 is the table an operator sizes a machine from. It ran k=9 to k=15, gave k=12 as a subtraction from
two-live-layer telemetry, gave k=15 as a lower bound above 2.45 TB with the provenance
*observed-incomplete (in-RAM run retired mid-layer)*, and had no rows past 15. From those rows it drew
two conclusions: that footprints fall from layer 16 onward, because the canonical-mask count follows
C(31,k); and that the in-RAM two-live-layer floor is k14 + k15, above 4.05 TB.

Three things are wrong, and the third is the one that costs money.

**The unit.** The 2.45 TB figure is a real measurement, but not of what the column measures. It is the
live in-RAM allocation observed part-way through layer 15 on the retired in-RAM attempt — hash-table
overhead included — and [HISTORY.md](HISTORY.md) records it as exactly that. The column's unit is
packed bytes. A mid-layer partial cannot exceed its own completed layer in packed bytes, and the
completed layer packs to 2155.82 GB, so the two figures were never the same quantity. The observation
is not withdrawn; it is relabelled in place, and HISTORY.md's narration of the retired attempt is
correct as it stands and was left alone.

**The reason given for the shrink.** It refutes the claim it was offered for. C(31,15) = C(31,16), and
the canonical-mask counts are palindromic — masks(15) = masks(16) = 13,047,760, a pair TR-11 §9's own
integrity check already prints. Mask counts therefore cannot make layer 16 smaller. Entries per mask
keep growing: k16 holds 83,585,570,784 entries against k15's 76,987,817,848. **Layer 16 is the peak.**

**The floor.** Because both inputs were wrong, so was the number derived from them. Measured from the
completed run: k14 + k15 = 3.85 TB, and the true peak adjacent live pair is **k16 + k17 = 4.51 TB**
packed, with k15 + k16 just behind at 4.50 TB. An operator provisioning to the retired floor was short
of the real peak window by ~460 GB. **The adjudication itself named the wrong pair here** — it gave
k15 + k16 as the peak — and the figures published are this batch's recomputation from the aggregate
table, not the charge's arithmetic. Maximising GB[k] + GB[k+1] over all k puts the maximum at k=16.

**What replaced it.** All ten rows k9–k18 now come from
[FULL31_EXACT_AGGREGATES.md](../reports/FULL31_EXACT_AGGREGATES.md) §1, the completed full-31 run's
own aggregate, which has sat in the same directory since 2026-07-16. §6's future-tense promise that
the out-of-core manifest *will* complete the profile is deleted with it — it completed thirteen
revisions ago. The unit line is also made exact: that file's `layer GB` column is
entries × 28 B **plus a 12 B per-canonical-mask index**, GB = 10⁹ B, which reproduces all 31 published
rows to the last printed digit; TR-11 had been calling it entries × 28 B, off by under 0.02% but off.
The rows are quoted with that file's own caveat attached — engine-internal telemetry, how *this*
implementation laid the layer out, not a property of the mathematical object — because sizing a
machine is exactly the use that caveat permits.

Registered: `RP-9d39b21a` (executive summary), `RP-089c4de7` (abstract), `RP-8c31ba03` (the table
cell), `RP-754f8752` (§6 body) for the mislabelled footprint; `RP-bb84c16f` for the shrink claim;
`RP-bb7395cd` for the floor. Four needles for one mislabel because the only string common to all four
sites is `2.45 TB`, which HISTORY.md carries legitimately — a single broad needle would have killed
the true record along with the false ones.

### 2. An evidence pointer aimed at a directory that holds none of the evidence

§8's Spot-ladder bullet publishes four integers — the 24-, 25-, 27- and 28-pair rungs — and closed by
citing `reports/evidence/f1/` as publishing the run outputs behind them. That directory holds the
|C1∩C2∩C4| headline result, its progress log and the Python prototypes. It holds no out-of-core
output for any of the four rungs, no manifest, no kill/resume log, and **none of the four integers
appears anywhere in it**. The Verification Guide's separate pointer to the same directory is the
accurate one; this one over-pointed it.

The records do exist. Checked before the sentence was rewritten, and each integer matched
digit-for-digit against a private artifact: a 24-pair out-of-core session log with its manifest; the
2026-07-08 retool battery's Phase-1 lines carrying the 24/27/28-pair v1-vs-v2 count-identical
comparison; a later 25-pair re-run manifest and progress record; and a random-timing crash-fuzz log,
15/15 direct-PID kills, resume byte-identical. **One record is gone**: the original ladder session's
raw outputs, including the 25-pair kill-and-resume log the bullet narrates, were copied to a volatile
`/tmp` on the orchestrator before the VM was deleted. The corrected sentence enumerates what is
retained, says plainly that it is retained privately and not published, says which warrant now carries
the 25-pair integer and which carries kill-and-resume at scale, and states that no public artifact
backs these four integers today. Registered as `RP-71e86ccc`, cut at `published at` so the retraction
survives a future edit that re-points the same sentence at some other directory.

### 3. A quantity v1.4 withdrew, back seven lines below its own hedge with an extra digit

The executive summary reported the exact count's distance from the prior statistical estimate as a
measured deviation, to seven significant figures, under the word *actual*. Seven lines above, the same
paragraph says that deviation is unmeasured at that precision. §9 says the figure is the estimate's
five-significant-figure rounding gap and not a resolved error. And v1.4 (2026-07-21) recorded
withdrawing precisely this quantity, on precisely this ground.

Recomputed here rather than taken on the adjudication's word: the number is obtained only by
differencing against the estimate's **rounded** numeral 1.0971×10³⁹. It is the rounding gap, restated
with more precision than the estimate itself carries, under a word that asserts the resolved-error
reading v1.4 retired. The v1.4 sweep fixed §9 and missed the executive summary — the
correction-missed-a-site shape v1.15, v1.19 and v1.20 each record for other passes. The sentence now
makes the claim that is supported: the exact value falls inside the estimate's stated ±0.01%
envelope. Registered as `RP-507e823d`.

### 4. A universal this report closed in 2026-07-17, still live in a sentence a 2026-08-01 pass had edited

§7's reproducibility sentence ended on a universal about machines in general — that none could
meet the multi-terabyte requirement. TR-11 v1.1 retired that universal on 2026-07-17 and §6 states the replacement in terms:
no machine class **this project provisioned** sufficed; 6–24 TiB single nodes exist commercially and
were not tested; the multi-terabyte route was dead at the price points this project could justify, not
in principle. The aggravator is that a 2026-08-01 status-correction pass rewrote the front half of
this very sentence — the parenthetical recording that the run had landed — and left the retired
universal standing in its tail. §6's scope is now stated inline, per the rule that a scoped result
states its scope at every occurrence. Registered as `RP-1b6b1678`. The v1.1 row's quotation of the
older wording is a changelog record and is untouched.

### What was not changed, and why

- **The retained ladder records were not published into the public tree.** The adjudication's remedy
  for §2 above was to publish them into a new `f1c5` subdirectory of `reports/evidence/`. That
  publication is already an open
  operator decision point (D2 on the batch's decision sheet: copying private artifacts into the public
  tree, review-before-push applies). Two further reasons found while checking the files: the battery
  log that warrants the 27- and 28-pair integers also contains a crash-fuzz phase that reads as a
  26-of-40 failure and is recorded privately as a **test-harness** defect, not a checkpoint defect —
  publishing the passing excerpt alone would be selective, and publishing the whole file requires the
  framing the private record supplies; and the 25-pair artifact is a later re-run, not the original
  session. So the false citation was corrected — which is the defect the charge names — and the
  publication left where it already sat, as a decision for the operator with the reasons now written
  down. Until it lands, TR-11 says outright that no public artifact backs those four integers.
- **The bare digits of the withdrawn deviation were not registered in `RETRACTED_FIGURES.tsv`.** The
  adjudication proposed a GATE 3b row keyed on the digits, which would catch a reworded restatement
  that the phrase needle misses. That registry and its content-anchored allowlist were outside this
  batch's ownership, and adding a figure row without its allowlist rows would fire on the legitimate
  quotations. Flagged, not done.
- **HISTORY.md's account of the retired in-RAM attempt was left alone.** It carries the same 2.45 TB
  number, correctly labelled as an in-RAM observation, and it is the source the relabelling now cites.
  Editing it would have deleted the evidence the correction rests on.
- **A discrepancy found in passing, not adjudicated.** HISTORY.md describes the retired in-RAM machine
  as 2.79 TB of RAM with 5.6 TB of striped swap; TR-11 §6 and its abstract say 2.75 TB with 3.55 TB.
  Both cannot be right. TR-11's figures were left as they stand because nothing in this batch's
  charges settles which is the measurement, and guessing would have replaced a visible inconsistency
  with an invisible one. It is flagged for whoever holds the machine-provisioning record.

**Attribution.** Charges raised by Codex reviewer V2-F02 and adjudicated in the V2 batch-4 sheet;
located, verified against source and corrected by this lane (Claude, Opus 5) under operator direction.
The unit correction (the 12 B per-mask index term), the peak-pair arithmetic, and the two items
flagged above under "not changed" were found by this batch while verifying the charges, not by the
review.

## 2026-09-02 — TR-2: a withdrawn result reinstated in the one section the withdrawal's own propagation list missed, a historical event decided by a theorem that cannot reach it, a reproduction promise no shipped command kept, two source attributions the project's own held notes contradict, and the last live copy of a retracted superlative — inside the figure

Codex reviewer charges V2-F04 #4/#5/#6 and V2-L09 #2, adjudication batch 6 rows 4, 6, 7, 8 and 10.
All five verified still live at HEAD before anything was edited; none had been fixed by an earlier
pass. Located, re-derived and corrected by this lane (Claude, Opus 5) under operator direction. Where
this entry states a number, it was recomputed here rather than taken on the adjudication's word.

### 1. The four-class Outcome section still said the withdrawn result stood

CX-26 (2026-08-07) demoted the v1.7/v1.12 Bayes factor and posterior from claimed results to the
as-computed record — recorded, not claimed. Its revision row lists its own propagation set: executive
summary, the result banner, the CX-25 bullet, the band note, the scope note, README, the evidence
banners, SOLVE_SUMMARY and CRITIQUE. TR-2's four-class §Outcome is not in that list, and it closed on
an absolute present-tense status sentence saying the earlier two-model result was untouched and still
published. For a reader entering the report at that section — which is where the four-class veto is
told — the standing withdrawal was inverted.

Swept before rewriting: this was the only live occurrence. The same words in TR-2's own v1.9 revision
row are a dated changelog record and are left alone; the superficially similar sentences in TR-1,
LITERATURE_RULES and HISTORY are about other results entirely. The corrected sentence keeps what was
true — the four-class comparison does not revise the earlier computation — and carries the withdrawal
with its CX id. Registered as `RP-e7b774b8`.

### 2. A theorem that decides existence, used to decide a historical event

§3 opened by stating Moore's conjecture in its historical form — an originally compliant ordering
*had been altered* — and then pronounced it decided and true. What the SAT results establish is that
the compliant ordering exists and sits exactly three slot-edits from the received order. That it ever
historically existed, and that an alteration event occurred, are not in the reach of any theorem here.
The report already knew this six lines below, where it says the result settles the *existence half*;
LITERATURE_RULES states it in the correct conditional register; and the alteration question is
precisely what §6's Bayesian comparison weighed — which CX-26 has made recorded-not-claimed, so after
that withdrawal there is no standing support for the historical half at all.

The section's closing paragraph carried the same slide in softer form. Both are corrected, and they
are registered separately (`RP-0df9f7d5` and `RP-6d478af9`) because they share no usable substring: a
single needle would have retired one and left the other, which is the half-fix shape this session has
now met repeatedly.

### 3. A reproduction promise the shipped script does not keep — fixed at the root

§"Reproduction" offered a single command as regenerating all of the report's Bayes factors. Run at the
pinned tree: `cd reports/evidence/f11 && python3 compute_f11_bf.py` prints
`N_gs(C,primary)=3.5686e+25` and primary BF **6625** (U) / **7901** (A) — the v1.7 as-computed record,
the 6.6×10³/7.9×10³ figures. It derives N_gs internally and never opens the r11 direct measurement,
and it has no argument parsing at all, so nothing shipped emitted the **live v1.12 headline**
(≈5.2×10³ / ≈6.3×10³) that the same report quotes two sections earlier. A published figure with
methods prose and no runnable command is exactly what the standing rule forbids.

The adjudication offered two remedies — ship the missing path, or label the live headline as
prose-only. The first was taken, because relabelling would have left a published figure without a
command. `compute_f11_bf.py` now accepts an opt-in `--ngs-measured`, which pools the four published
r11 seeds to N_gs = 4.5031×10²⁵ and re-emits BF **5250** (U) / **6261** (A) — the live figures, to the
digit, through the same integration and the same grids, with only n_gs moved. The flag is opt-in and
the bare-run output was verified byte-identical before and after the change, so the frozen record is
untouched. The report now names both commands and what each produces. Registered as `RP-c2c5074a`;
the same unqualified promise on the f11 bundle README's first line — a different spelling, found by
grepping the retired promise rather than the charge's named site — as `RP-4d682627`.

### 4. Two attributions the project's own first-hand notes contradict

The M_corr model bullet credited the alteration conjecture to Schulz alongside Moore. Checked against
the held source record (`books/papers/SCHULZ_2011_NOTES.md` SC-25, pp. 648 and 661–662): Schulz reads
the S25/S26 exceptions as *intentional* — exceptions that stand out by design to highlight the
patterns they figure in — and raises no corruption conjecture. TR-2's own structure list calls that
design reading vindicated in exact form, so the bullet contradicted the source and the report at once.
Registered as `RP-afe960d9`.

The same bullet gave Rutt (1996) the mechanism and then, in apposition, named the model's event
operations as its content. The held record (`books/papers/HACKER_MOORE_2003_NOTES.md`) carries Rutt
only as bamboo-slat cord fraying, a physical corruption hypothesis, and CITATIONS.md already marks him
`[secondary]`, read via Hacker & Moore 2003. No held source states an adjacency restriction,
disjointness, orientation flips, a geometric k, or an adjacency weighting: those are this work's
operationalization. Rutt's own 1996 text **could not be checked** — there are no first-hand Rutt notes
in `books/` — so this is corrected on the burden the scoped-results rule puts on the citing sentence,
not on a demonstration that Rutt says otherwise. The report's attribution footer is split the same
way. Registered as `RP-12595256`, and the sibling site the charge named, in
`reports/evidence/f11/RESULTS.md` §3, as `RP-cdff36be` — a file whose own attribution footer already
said the event model is ours, so the document had been contradicting itself.

### 5. The retracted superlative was still in the figure's pixels

The 2026-08-28 margin correction withdrew "minimal" from the claim that King Wen misses the three
graded rules by the smallest possible margins, and the 2026-09-01 pass finished the prose and the
captions. Neither reached the rendered figure. `viz/report_figures.py` still drew the withdrawn
wording into the plot; the shipped SVG carried it in its accessibility text; the PNG embedded in both
TR-1 §5 and TR-2 §Figure rendered it. A reader or republisher of the image alone received the
retracted claim with no marker attached, and the marker TR-1 added on 2026-09-01 said so in terms —
recording the defect, and reading like closure.

Re-derived before touching it: `reports/evidence/f11/f11_runA.out:112` is `f11_hist 1 1 0` at
4.1291082539e-09 and `:320` is `f11_hist 2 1 1` at 2.9255247935e-08, both nonzero and componentwise no
worse than King Wen's `2 2 2`, and that histogram is not CC-N4-conditioned, so no extremal check
exists. The drawn string now states the measured margin and says no extremal check excludes a smaller
miss; the PNG and SVG were regenerated and both reports' captions updated. Verified before
regenerating that the generator reproduces the committed PNG byte-for-byte, so the only change in the
image is the corrected sentence.

### What was not changed, and why

- **No registry row for the figure's wording.** The adjudication's gate proposal was to register the
  retracted phrase and grep `viz/*.py` and the shipped SVGs against it. It cannot be a GATE 3 row:
  measured at HEAD, that phrase has five occurrences in the markdown corpus and every one of them is a
  legitimate correction marker or changelog record quoting what was withdrawn. GATE 3 allows exactly
  one file per row, so the row would have fired on four honest narrations. And GATE 3's corpus is
  `*.md` plus `reports/evidence/**` — neither `viz/*.py` nor `reports/figures/*.svg` is in it, so no
  registry row could have protected the image in the first place. The gate the charge wants is a new
  leg in `scripts/doc_gates.sh`, which is another lane's file this session. Run here as a one-off
  instead: all 152 registry phrases against all 9 generator and SVG targets, 0 hits after the fix.
- **`PREREGISTRATION.md` was not touched.** It carries the Rutt attribution correctly scoped —
  "gives physical plausibility" — and it is a frozen pre-registration regardless.
- **TR-2 has no §5 body section.** The charge cites "§1/§5" for the design reading; the phrase is in
  the executive summary's structure list, and the report's headings run §2, §3, §4, then the
  Verification Guide. The citation was adjusted to what exists. Whether TR-2 should have the §5 and §6
  bodies its own structure list promises is a separate question, flagged and not acted on.
- **Files edited outside this batch's charge set, named here for the record:**
  `reports/evidence/f11/compute_f11_bf.py` (the new flag), `reports/evidence/f11/README.md` (census
  sibling), `viz/report_figures.py` plus the two regenerated figure files, and
  `reports/TR1_EIGHT_CENTURIES_MEASURED.md` — the last because regenerating the image made TR-1's own
  marker, which said the image had not been regenerated, false as it stood.

**Attribution.** Charges raised by Codex reviewers V2-F04 and V2-L09 and adjudicated in the V2 batch-6
sheet; verified against source, re-derived and corrected by this lane. The f11 README sibling, the
missing-§5 observation, and the byte-identity check on the figure generator were found by this batch
while verifying the charges, not by the review.

## 2026-09-02 — DEVELOPMENT.md: an archival banner that was the exact inverse of the catalogue, a verifier wall time two orders of magnitude off its own stated rate, a completed measurement still written as future work with the wrong partition attached, and a topology claim a shipped script contradicts on every run

Four adjudicated Codex charges against `documentation/DEVELOPMENT.md`, plus a hook-contract rewrite
routed from the code lane. All four charges verified still live at HEAD before anything was edited;
none was a no-op. Two further defects were found by this batch while verifying the charges and are
corrected here with the rest, marked as such.

### The archival banner (Codex V2-F15 #9) — `RP-2e39a795`, `RP-456ed634`

The section head banner declared the Azure Blob Archive flow designed but never stood up, no
automation chosen, and the `solver-data` managed disk the sole tier of redundancy the project had.
`CANONICAL_HASHES.md` records archives at every active-lineage canonical scale: d3 560T with a warm
gzip mirror and a cold blob for the original campaign and again for the byte-identical 2026-06-30
re-run, d3 100T with a cold blob re-verified live 2026-07-17, d3 11.2T with a build-A/build-B pair
plus a witness-only v3 upload plus the dress rehearsal, and d3 10T, d3 5.6T and d2 10T with a
build-A/build-B pair each. (The banner's replacement deliberately does not publish a total: a raw
grep of `canonical-archive/` returns fourteen distinct paths in sixteen lines, and that population
includes the CLOSED v2 lineage and one path CANONICAL_HASHES.md's own note records as never
populated. A count that needs three caveats to be true is worse than the enumeration.) The banner was not imprecise; it was
inverted. The incident cost of believing it is the reviewer's own scenario — an operator declares
recoverable data lost, or re-pays to archive what is already archived.

**Half-fix, and which half.** The charge named two sites. The second, the historical `aa1415174c…`
paragraph, had already been repaired by an earlier pass, which added a *Superseded:* note; its
retired sentence "No run has yet been archived" has zero matches corpus-wide today. The banner
twelve lines above it was left. Only by grepping the *retired values* rather than the charge's line
numbers was it clear which half survived — the line numbers themselves had drifted by ~80 lines.

**Found while verifying, not by the review:** with the banner corrected to DEPLOYED, the
long-term-pause procedure's step 3 — **"Delete the managed disk"**, in bold, justified by ~$64 saved
over six months — stopped being harmless aspirational text and became an executable instruction
contradicting the standing rule this repo states three times in `DEPLOYMENT.md` ("never delete data
disks"; "Managed disks preserved = the win condition for every class of failure"; "Never delete
`solver-data`"). It is corrected to retain-and-resize in the same pass, because the banner fix is
what made it dangerous.

### The verify.py wall time (Codex V2-F15 #14) — `RP-e0ad193f`

The tool description promised one to five minutes single-threaded on a 10T `solutions.bin` and, in
the same sentence, a rate of ~19k records/sec per Python worker. The two are inconsistent by more
than two orders of magnitude and the arithmetic needed to see it is entirely inside the sentence:
706,427,594 / 19,000 = 37,180 s = 10.3 h. The sentence's own 100T arm was already right —
3,432,399,297 / (16 × 19,000) = 11,291 s = 3.1 h — which is what identifies the 10T arm as the
defect rather than the rate. `HISTORY.md`'s May 4–5 entry measured it: ~10 h single-threaded on the
759M-record file before an eviction killed it at ~95%, and ~6 min for the same file at `--jobs 128`,
i.e. 16.5k records/sec/worker. A contributor who schedules a five-minute timeout kills a healthy
verifier and reports a hang.

**Where this batch declined the adjudication's prescription.** The row prescribed a flat "~10 h /
~40 min / ~3 h". Those numbers are kept, but not as facts: `DEPLOYMENT.md` records that the 560T
campaign measured roughly a **3× shortfall** against the 19k projection, and says in terms that the
projection itself may be optimistic. The corrected passage therefore labels 19k a projection rather
than a floor and sends the reader to the measured rates. Publishing the derived hours without that
qualifier would have replaced one over-confident number with three.

**Two stale pointers in the charge itself, corrected rather than transcribed.** The row cited
`HISTORY.md:1590-1593` for the ten-hour measurement; that passage is at ~`:1604-1632` today and
`:1590-1593` is about an unrelated validation chain. The row also implied a second "sheet site" at
`:870`; `verify.py` is mentioned at six places in `DEVELOPMENT.md` and **exactly one** of them
carries a wall-time claim. There was no second site to fix. `solve.py:3822` also says "~1-5
minutes", and is **not** a sibling — it describes `--null-debruijn-exact`, a different program.

### The partition-stability item (Codex V2-F15 #18)

Item 6 of "What's pending / open" presented the 100T re-check as future work: a 100T dataset will
either confirm the 4-boundary structure or refine it. The measurement completed and is published.
`PARTITION_STABILITY_BOUNDARIES.md` records the greedy-ordered minimum rising 4 → 5 → 5 across d3
10T → 100T → 560T and the count of working unordered 4-subsets collapsing 8 → 0 → 0. The outcome
was "refine", so the sentence is technically satisfied — and that is exactly why it needed
rewriting: a researcher reads an open item and re-spends the compute, or cites the 4-boundary
structure as a live hypothesis.

**Found while verifying, not by the review — the item also attached the family to the wrong
partition.** It named `{25, 27} ∪ one-of-{2,3} ∪ one-of-{21,22}` as established on the **d3** 10T
canonical. That shorthand is the **d2** 10T family: exactly 2 × 2 = 4 sets, exactly what §[8]
reports for d2. The d3 10T family is **8** explicitly enumerated sets and none of them contains
boundary 21 or 22. Every other site in the corpus scopes the shorthand to d2 correctly —
`CRITIQUE.md:3` and `:108`, `SOLVE.md:389` and `:603`, `SOLVE_SUMMARY.md:218`,
`enumeration/LEADERBOARD.md:178-181`, which states outright that the phrasing is d2-specific. This
was the last site in the corpus still carrying the d3 attribution, and it was found by grepping the
retired value, not the charge's named defect.

**No registry row for it, deliberately.** The string is a *correct* statement about d2 at six other
sites. A needle narrow enough to catch only this one would have to encode the surrounding
attribution and would not survive a reword; a needle robust enough to survive would fire on six
honest sentences. GATE 3 allows one allowlisted file per row, which is not enough. An inline
correction marker carries it instead.

### The network-topology claim (Codex V2-L21 #2) — `RP-5e7da3fc`

The section’s claim that each new solver VM is created without a public IP or an NSG rule and
therefore presents no external attack surface at all is contradicted unconditionally by `scripts/perf_bench.sh`, the standardized paired benchmark harness
this same document endorses. It provisions a fresh resource group with its **own** `vnet`/`subnet`
at `10.0.0.0/16` (`:104-105`) instead of joining `claude-vnet`, so no private path from the
orchestrator exists at all, then creates the VM with `--public-ip-sku Standard --nsg-rule SSH`
(`:110`) and connects with `StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null`
(`:118-119`). This happens on every invocation, including from the orchestrator — the existing
laptop caveat does not cover it.

The adjudication's mechanism was slightly off and is corrected here: it read the script as taking
the public path *despite* sharing `claude-vnet`. It does not share it. The script builds its own
isolated network, which is *why* it cannot be reached privately — a structural reason, not an
oversight, and it changes what the fix would have to be.

Severity stands as adjudicated (High → Medium): key-auth-only port 22 on a transient Spot VM
holding public repo source and bench output. A posture contradiction and a first-connection MITM
window; no credential or data-secrecy stake. One thing the charge did not note and the doc now
says: `teardown()` is called explicitly at three sites with **no `trap`**, so an interrupted or
crashed run leaves the public-IP VM standing until someone deletes the resource group by hand.

**The preferred repair is not the one applied.** Putting the NIC on `claude-vnet/default` with no
public IP when the run originates on the orchestrator, keeping an explicit `--public` flag for the
off-vnet case, fixes the posture instead of documenting the hole. That is a change to `scripts/`,
which another lane owns this session. The exception is documented, the residual is stated plainly,
and the script change is left open rather than silently dropped.

### The hook verdict contract (routed from the code lane, `0414d072`) — not a Codex charge

§"Git hooks" described a two-state world. Since `0414d072` there are three, and the section now
states the contract read off the shipped scripts rather than off the hand-off note that requested
the edit. **The scripts disagree with that note in one material respect and the scripts win:** the
`0` / `1` / `2` return-code contract holds for `pre_commit_registry_gate.sh` and its dispatcher, and
**does not hold for `pre_commit_generated_gate.sh`**, which never returns 2 — being blocking, it
exits `0` for CLEAN and `1` for everything else, FINDINGS and COULD-NOT-RUN alike. Its token still
separates the three states; its exit status cannot, so anything scripting on it must `grep -qx` the
token. `PRECOMMIT_REGISTRY=` also has **five** values, not three: `NOT-APPLICABLE` (nothing staged,
or no watched path) exits 0, and `REFUSED-DIRTY` (index and working tree disagree on a watched path)
exits 2. `pre_push_gate.sh` was swept for the same class in the same commit but emits **no**
`PREPUSH_*` token and changed no return code — only its message text distinguishes a crash from a
finding — so the section says not to write a `grep -qx` reader against it.

WARN-ONLY is unchanged and is stated as such in three places, because the rework reads like a
tightening and is not one: the registry gate still blocks nothing, on FINDINGS or on COULD-NOT-RUN,
per O-redfloor. The one operational consequence the section adds is that a COULD-NOT-RUN commit
proceeds and **must not be recorded as gated**.

The pre-commit "Both fail closed" sentence was sharpened in the same pass: it was true of the
pre-push hook and the generated gate and false of the registry gate, and "both" invited reading it
as both *hooks*.

### What was not changed, and why

- **`scripts/perf_bench.sh` was not touched** — another lane owns `scripts/` this session. Neither
  was `scripts/pre_commit_generated_gate.sh`, whose own install header still documents the
  superseded bare-symlink recipe (`ln -s ../../scripts/pre_commit_generated_gate.sh
  .git/hooks/pre-commit` plus `chmod +x`) that `pre_commit_gate.sh` exists to prevent. Reported, not
  edited — and reported *as* a defect, not as a fix.
- **No registry row for the d2/d3 boundary-family misattribution**, for the reason given above.
- **`DEPLOYMENT.md:188`'s 19k caveat was read, not rewritten.** It is already honest about the
  measured shortfall; `DEVELOPMENT.md` now points at it instead of restating it.

**Attribution.** Charges raised by Codex reviewers V2-F15 (#9, #14, #18) and V2-L21 (#2), adjudicated
in the V2 sheet; verified against the shipped scripts and the canonical catalogue, re-derived and
corrected by this lane. The managed-disk deletion step, the d2/d3 family misattribution, the two
stale pointers inside the verify.py charge, the corrected mechanism for the perf_bench exposure, the
missing `trap`, and the generated gate's divergence from the stated return-code contract were found
by this batch while verifying the charges, not by the review.

## 2026-09-02 — a recorded seed nothing reads, a label correction that reached two of five files, and a versioning promise whose scope was never decided

Prose batch P76. Four adjudicated charges were re-verified at HEAD before anything was
touched; **two were already closed** and are recorded here as no-ops rather than as fixes,
because a no-op reported as a repair is a false record. What was live is below, plus one
defect found by census rather than by charge.

### The timing-probe seed (Codex V2-F52 #4) — `RP-f5a32940`

`documentation/SOLVE_PY_CLI.md` §Cost stated that the `timing-probe` seed is derived and
recorded in `header.json` so that the probe is fixed by it, even though a probe produces no
statistic. **Both halves are false, and the second is what makes the first matter.**

MEASURED at HEAD, in `solve.py`:

- The seed is derived and written at `:744` — and that is the **only** occurrence of the
  string `timing-probe` in the file. No code path reads the value back.
- Pool draws come from the `pool-<A|B>/shard-<i>` seeds at `:887`; `tr8_pool_shard` hands
  each one to a fresh `random.Random`. A probe run with the same seed root and pool name
  therefore redraws a **prefix of the measurement pool's own shard streams** — not an
  isolated stream. To keep a probe off them, give it its own `--tr8-dof-seed` root.
- `results.json` and `RESULTS.md` are written unconditionally at `:1023`, probes included.
  A probe's statistics are discarded **by convention, not by code**.

The narrowing the adjudication attached to the charge is adopted and is worth keeping: the
measurement **pool is not corrupted** — a probe writes into a throwaway `OUT_DIR`, so no
artifact is polluted. What fails is the pinning claim and the isolation of the seeded
stream. Corrected in place, and at a second site the charge did not name: the
`--tr8-dof-seed` flag row listed `timing-probe` among the seed purposes with nothing to say
it is reserved. The registry needle is the pinning clause only — "timing evidence only" is
true and still stated.

### The pre-merge shard label (Codex V2-F14 #5, by census) — `RP-4ab3aa76`

The 2026-08-28 entry above ruled that 43,876,464,466 counts **per-sub-branch canonical
keys** — `solve.c` deduplicates on pair identity with the orient bit masked and clears the
table after each sub-branch — so the figure is a lower bound on raw leaves visited and the
4.17× quotient is cross-sub-branch rediscovery, not an orientation-dedup ratio.

The two sites the V2 charge named, `CANONICAL_HASHES.md` and `HISTORY.md`, **are both marked
at HEAD** and needed nothing; the charge is closed, not fixed. But grepping the retired
*value* rather than the charge's named sites found the label alive in a fifth file the
2026-08-28 sweep and its follow-up both missed: `documentation/LARGE_SCALE_CAMPAIGNS.md`, at
**three** sites — the §9a RAM-sizing note, the §9b preamble, and the §9b Option-3 caveat —
each writing the compressed `43.88 B` spelling with the retired label attached, which is why
a long-form grep on the full integer exonerated the file. All three now read "pre-merge
shard records (per-sub-branch canonical keys)"; the §9a site carries the full marker and the
other two point at it.

Two nearby strings were checked and deliberately **not** swept, for the reasons the
2026-08-28 adjudication already gave: `HISTORY.md`'s "26.5 B of 43.88 B (pre-dedup) records"
is correct as written (these *are* pre-merge-dedup, and it asserts no ratio), and
`CORRECTIONS_INVENTORY.tsv`'s 2026-06-08 row is a git commit-message transcript — a record
of what a commit said, which must not be rewritten. One sibling is **reported, not edited**:
`HISTORY.md:4002` writes "15,035,483,184 raw records → 3,663,580,914 unique canonical
orderings" for a different, smaller campaign. The same mechanism would make the same label
wrong there, but that figure was never adjudicated, this lane has not verified which
producer emitted it, and correcting it on inference would be exactly the over-reach the
2026-08-28 entry warns against.

### The reports versioning policy (Codex V2-L18 #2) — no registry row, and why

`reports/README.md` promises that "every content change is a version bump with a Revision
History entry in the affected report". The two violations the charge named are **both closed
at HEAD**: TR-6 is at v1.8 (2026-09-02) against its 2026-08-29 correction marker, and TR-4 —
the third instance an earlier adjudication found by sweeping rather than trusting the charge
— is at v1.26 (2026-09-02) against its 2026-08-28 markers. A fresh sweep of all fourteen
files in `reports/` (last `*(current)*` date vs the newest dated correction marker in the
same file) shows **all eleven numbered reports passing**.

What was still open is the item that adjudication explicitly left unruled: whether
`METHODS.md` and `FULL31_EXACT_AGGREGATES.md` — which sit in `reports/`, carry dated
corrections, and have no Revision History at all — are in scope for that promise. They are
not, and neither is the index itself; that is now **stated at the policy** instead of being
inferable from a table three screens up. The three unversioned files are named, their
correction mechanism (dated inline marker plus a ledger entry) is described, and readers are
told to cite them by commit sha.

**No registry row for this one.** Nothing was retracted: the policy sentence is true of the
eleven reports it governs and stands unchanged. Registering a needle against wording that
still stands would put a false retraction on the record and make the gate lie about it.

### Charges that were already closed, recorded as such

- **`reports/METHODS.md` C4 attestation (Codex V2 batch-2 #8).** Closed on 2026-08-30 and
  propagated: `METHODS.md:25` carries the marker, `SPECIFICATION.md` at :69/:104/:163,
  `DESCRIPTION_LENGTH.md` fn 1, and `TR9:271` all read the narrowed wording, and the phrase
  is already registered with `reports/METHODS.md` as its allow file. Nothing to do, and the
  landing gate the adjudication attached (the v4 constraint freeze / Li Shangxin review) is
  therefore not engaged by this batch.
- **`CANONICAL_HASHES.md` and `HISTORY.md` dedup labels** — see above.
- **TR-6 and TR-4 version bumps** — see above.

**Attribution.** Charges raised by Codex reviewers V2-F52 (#4), V2-F14 (#5) and V2-L18 (#2),
adjudicated in the V2 sheet; re-verified against the shipped `solve.py`, the tracked corpus
and the `reports/` sweep, and corrected by this lane. The three
`LARGE_SCALE_CAMPAIGNS.md` sites, the `--tr8-dof-seed` flag row, and the unversioned-file
scope question were found by this batch while verifying the charges, not by the review.

## 2026-09-02 — a source-provenance claim that survived its own correction because it was spelled short and wrapped

**Retraction key: `RP-502d8730`.** The 2026-08-28 entry above — *"'each reproducing its
source's stated King Wen values' was true of 27 of 31, not all 31"* — corrected
[LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md) and left
[TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) untouched. TR-1's extended-scoreboard
paragraph still claimed the provenance for *each* of the 31 formalized literature rules,
five days later. It is now corrected there to **27 of the 31**, with the four exceptions
named.

**The measurement, re-derived rather than inherited.** `solve.py`'s comment directly above
`REGISTRY_KW_EXPECTED` (`solve.py:7343-7347`) reads *"MM-T3=4, MM-T6=0, C1=24 and the C2
histogram are **KW-measured anchors** (registry states only qualitative/percentile
expectations for those)"*, and the list it introduces (`solve.py:7348-7357`) holds **31**
entries — counted, not quoted: `rs1 rs2 ccn1 ccn2 ccn3 ccn4 ccn6 ccn7 ccn8 c2011n1 c2011n2
c2011n4 mmt3 mmt4 mmt5 mmt6 p1c4 p2c3 p2c4 p2c5 p2c6 d4 d7 s1 s6 m2 r3 r4 r5 c1 c2`. 31
entries, 4 anchors, so **27**. Nothing about the registry run changes: `--registry-verify`
checks all 31 and passes; what was wrong is the stated *origin* of four of the values it
checks against.

**Why it survived, and it is the transferable part.** TR-1 spells the clause `KW values`
where the corrected sibling spells it `King Wen values`, **and** the clause spans a hard
line break. A long-spelling grep missed it; a line-oriented grep of the short spelling
missed it too. It was found only by flattening every tracked file before matching — the
operation GATE 3 performs and an ordinary sweep does not. **Census, whitespace-flattened
over every tracked file:** `reproducing its source` matches exactly three —
`reports/TR1_EIGHT_CENTURIES_MEASURED.md` (the defect, now fixed),
`LITERATURE_RULES_POPULATION_TESTS.md` (correct at 27 since 2026-08-28, with its marker)
and this ledger (the append-only entry quoting the old wording). Before: 1 wrong of 3.
After: 0 wrong of 3.

**The needle registered is the abbreviated spelling**, and deliberately so: the long
spelling is what the corrected site and this ledger's 2026-08-28 entry legitimately quote
while explaining the retraction, and GATE 3's allow column names one file, so no single row
could exempt both. The short spelling is the one that evaded the sweep, which is exactly
what the registry exists to keep dead. Its allow column is `__none__`; the only surviving
instance is TR-1's v1.31 revision row, which GATE 3 exempts as a changelog row, and this
entry cites the key rather than the string.

**`tests.py` cannot see this class.** `test_registry_verify` (`tests.py:433-439` at HEAD;
the adjudication cited `:416-419`, which has drifted to an unrelated trigram test) asserts
the banner `ALL 31 REGISTRY CHECKS PASS` and `returncode == 0`. **Executed here:**
`python3 solve.py --registry-verify` prints that banner and exits 0 — identically whether a
checked value came from a source or from King Wen. Provenance was invisible to the test
suite before this correction and still is; the gate that now covers it is GATE 3, on the
flattened text.

**Not touched, and deliberately.** `LITERATURE_RULES_POPULATION_TESTS.md` is already correct
at 27 and needed no edit; the 2026-08-28 entry above quotes the retired wording under the
append-only discipline and must keep it.

### The batch's second charge was already closed, and is recorded as such

`CODEX_V2_ADJUDICATION` row 16 charged `documentation/CLAIM_TO_ARTIFACT.md:35` and
`reports/TR2_THE_RULES_CONFLICT.md:313` with labelling a fourth two-rule core CERTIFIED
against an unshipped certificate, and separately charged this ledger's 2026-08-28 sentence
that the shipped `sat.py` had no target for the pair. **Both limbs are closed at HEAD, and
the closure was checked against the artifacts rather than against the entries claiming it.**
`reports/certificates/` holds **22** `.drat.gz` files including
`core_gender_ccn4_unsat.drat.gz`; `verify_all.sh`'s regeneration map names all four cores
(`five-sub-parity+ccn4`, `five-sub-rhythm+ccn4`, `gender-ccn8`, `five-sub-gender+ccn4`);
row 8's own command was **executed here** — `python3 sat.py --emit-cnf five-sub-gender+ccn4
f.cnf` → `vars=7035 clauses=243175`, 0.75 s, exit 0 — and row 16's independent statement of
the same arithmetic ("27 of 31 reproduce a source-stated KW value; 4 are KW-measured
anchors") agrees with the correction above. The `sat.py` limb was closed on 2026-09-01 by
the banner now standing above the 2026-08-28 entry. **What this lane could NOT re-execute,
stated rather than implied:** neither `kissat`, `drat-trim` nor `cake_lpr` is on this
orchestrator's PATH, so rows 8 and 12's checker verdicts (`s VERIFIED UNSAT`, the 22/22
`verify_all.sh` replay) were confirmed only for internal consistency across
`reports/certificates/README.md`, `HISTORY.md` and TR-2, not re-run. Nothing was edited for
this charge; TR-2 is another lane's file and needed no change either.

**Attribution.** The charge was raised by the Codex V2 review (V2-F63 #6) and adjudicated in
roae-private (`CODEX_V2_ADJUDICATION` rows 26 and 16). The re-derivation from `solve.py`, the
flattened census and the registry decision are this lane's. Reviewers are acknowledged, not
credited as authors.

---

## 2026-09-02 — a retracted attestation that survived nine registered needles because one site hyphenated it

**Key:** RP-032dfbe6 (`documentation/RETRACTED_PHRASES.tsv`).

**Site:** `documentation/DEVELOPMENT.md:1894` **as of HEAD `0f55aad1`** (the correction below adds
lines, so the item now spans 1888-1908), item 3 of §"Scientific / analysis extensions", the
entry that records the 2026-07-26 retraction of the forced-orientation "Theorem 6".

**BEFORE:** the clause closing that item gave C4's within-pair orientation a parenthetical epithet
crediting the *Xugua* with attesting it — written as a single hyphenated compound rather than as the
"classically attested" phrasing every other site in the tree used.

**AFTER:** the orientation is stated as definitional — this project's convention, not a classical
attestation — with a dated marker recording what the *Xugua* does and does not attest and pointing at
the narrowing in [METHODS.md](../reports/METHODS.md) §"Constraint set".

**Why it survived.** The narrowing landed 2026-08-30 in METHODS.md and was propagated on 2026-09-01
to SPECIFICATION.md, DESCRIPTION_LENGTH.md, SOLVE.md, SOLVE_SUMMARY.md, BRANCHES_EXPLAINED.md,
CITATIONS.md, CLAIMS_DECIDED.md, lean/README.md, TR-1, TR-9 and TR-11, with eight needles registered
and two more added on 2026-09-02 by the Lean batch. All ten spell the claim with the words
*classically attested*. The DEVELOPMENT.md site spells it as a hyphenated adjective instead, so no
registered needle could reach it, and GATE 3 reported clean over it every time. **A green GATE 3
attests that the registered strings are absent, not that the retracted claim is** — the lesson the
CX-34 row already recorded, reproduced here in a second, independent instance.

**Verified live before editing.** `documentation/DEVELOPMENT.md:1894` carried the wording at
HEAD `0f55aad1`, and a run of all pre-existing registry needles against that file returned no match,
confirming the site was unreachable from the registry rather than merely unswept. Census of the
retired claim across the tree: **1 live site before -> 0 after**. Every other hit is either correctly
scoped to C4's *pair choice* (`CRITIQUE.md:75`, `SOLVE.md:576`, `SOLVE_SUMMARY.md:200`,
`BRANCHES_EXPLAINED.md:59`), or an append-only historical record already annotated in place
(`HISTORY.md:5872`, TR-1's v1.16 revision row, `CORRECTIONS_INVENTORY.tsv`, and this ledger's own
:230/:247/:1985/:2752 — the last of which the 2026-09-01 sibling audit deliberately annotated rather
than rewrote).

**Nothing quantitative moves.** The Theorem 6 retraction the site records rests on the Complement Z₂
symmetry theorem, machine-checked in `lean/KingWen.lean` with a kernel-only trust base, not on any
attestation; TR-9 continues to price C4 at its full ≈6 bits (pair + orientation), and a definitional
bit returns nothing to the ledger for exactly the reason an attested one returns nothing.

**Attribution.** The charge was raised by the Codex V2 review (V2-13 #1) and adjudicated in
roae-private (`CODEX_V2_ADJUDICATION` line 2843). The adjudicated site itself — `reports/METHODS.md`
— was already closed on 2026-08-30 and is confirmed closed here; this entry records the survivor that
the closure's own propagation sweep could not see. Reviewers are acknowledged, not credited as authors.

---

## 2026-09-02 — a numberless universal in two files, one day after the same sentence was retired in a third

**Keys:** RP-33e91f43 and RP-944b9b41 (`documentation/RETRACTED_PHRASES.tsv`).

**Sites:** `documentation/SOLVE.md` §"Null model: is the constraint framework special?", the
paragraph beginning "What is genuinely special about King Wen", and
`documentation/SOLVE_SUMMARY.md` §"An important caveat", its closing sentence — both **as of HEAD
`599acfcf`** (line numbers omitted deliberately; the correction adds text and both had already
drifted from the numbers the charge was filed against).

**BEFORE:** each paragraph ended by asserting that the properties the constraint framework extracts
— complement distance, starting pair, difference distribution — carry the same narrowing power for
an unrestricted universal class of sequences as they do for King Wen. Two different predicates, two
different objects, one defect: a sweeping claim with **no population, no scope and no measured
degree** behind it. Neither site's wording could be reached by a needle written against the other's.

**AFTER:** the quantifier is gone and the paragraphs state the **deductive** content in its place —
the extraction is self-fulfilling, because C3–C5 are values read *off the target*, so the constraints
it returns are ones that target satisfies by construction and the narrowing that follows is narrowing
around *it*. Each site then states the gap in terms: **the mechanism is deductive; the scale is not
measured.** Nothing in this project reports, for any population of orderings, what fraction the
extraction drives to near-uniqueness or how near it drives them.

**Why a gap and not a number.** The project's standing rule is that a published figure ships with its
reproduction command; the corollary this entry applies is that a published *universal* ships with its
population. Before concluding that no measurement exists, the lane checked whether one was
**derivable**, which is the failure mode that produced RP-502d8730 four batches ago (a "each of the 31
rules" universal whose true count, 27, was sitting in `solve.py`). It is not derivable here. The only
evidence bearing on the claim is the 9/10 historical null run already disclosed at the SOLVE.md site,
whose artifacts were not preserved. The **outstanding fix** is a `solve.py --extraction-null` mode, and
it has never been built — it appears in this tree only at documentation sites
that disclaim it and in `scripts/doc_gates.sh`'s GATE 25 proposal-marker comment, which exists
*because* those sites are the project being scrupulous about what does not exist. roae-private's
`CURRENT_STATE.md` records the same conclusion independently ("no reproduction surface in either
tree"). No cached 13,296-ordering differential population survives from which a fiber-size
distribution could be derived instead, and regenerating it is a ~63-minute solver run — a measurement
task, not a prose-lane derivation. **A stated gap outranks a confident sentence**, so the gap is what
is published.

**One consequence handled rather than left standing.** Both paragraphs also carry a hedged sibling of
the same shape — the framework "makes almost any sequence appear uniquely determined". It is left as
written, because it is explicitly labelled a qualitative conclusion resting on stated reasoning, and
because `documentation/HISTORY.md` deliberately preserves the identical wording as an annotated
period record while `documentation/DISTRIBUTIONAL_ANALYSIS.md` scopes its version to C1+C2 orderings,
a named population. Retiring it would have been a second, wider claim needing its own sweep. Instead
each corrected paragraph now says explicitly that the qualitative wording is an inference from the
mechanism plus the unreproduced run and **not a measured frequency**, which scopes it rather than
contradicting it. Reported, not silently absorbed.

**This is a sibling-residue closure, and the residue was one day old.** `documentation/GUIDE.md`
retired the identical sentence on 2026-09-01 as `INL-b7f79b5`
(`documentation/CORRECTIONS_INVENTORY.tsv:227`). That pass reached GUIDE.md alone. The same lesson has
now been recorded three times in four days — RP-502d8730 (a retired value surviving in an abbreviated
spelling), RP-032dfbe6 (a retired claim surviving as a hyphenated compound), and here, a retired
sentence surviving in two files under two different predicates. No needle registered against the
GUIDE.md wording could match either survivor.

**Anchor safety.** `SOLVE_SUMMARY.md` §"An important caveat" is the target of three inbound anchors to
`#an-important-caveat` — two in `documentation/GUIDE.md` and one in
`documentation/DISTRIBUTIONAL_ANALYSIS.md`. The correction is body prose only; no heading, and no
heading's slug, changed. All three were re-checked against the heading after the edit and resolve.

**Census.** Whitespace-flattened over every tracked `.md`, `.tsv` and `.txt`: each needle 1 → 0. The
subject-side spelling that would have covered both sites in a single row was considered and
**rejected** — it carries an ASCII apostrophe, and GATE 3's character-variant fold normalises dashes,
multiplication signs, inequality signs and four space variants but **not** quote characters, so a
typographic apostrophe would walk past it unseen. Both registered needles are apostrophe-free by
construction. `allow` is `__none__` on both: this entry cites the keys rather than quoting the
strings, per the RP-502d8730 precedent.

**Nothing measured changed.** No count, percentage, sha, certificate, theorem or claim verdict moves.
The 9/10 run keeps exactly the standing it already had. What changed is that two paragraphs stopped
asserting a frequency nobody has measured.

**Attribution.** The charge was filed against this lane as `NUMBERLESS_UNIVERSALS`. The derivability
check, the decision to publish the gap rather than a hedge, the apostrophe-fold reasoning behind the
needle choice and the anchor re-verification are this lane's.

---

## 2026-09-02 — an order-preservation argument that names the wrong comparator at two of the three sites it clears, an independence universal a six-boundary set refutes, and a lookup key the tool stopped accepting a week before the docs did

Three adjudicated charges, one of them against this ledger itself. Each was re-verified at HEAD
before anything was written, and one of the three was **already closed** at the line it cited — that
is reported below rather than counted as a fix.

### 1. The 2026-08-28 entry's "What is NOT affected" paragraph — corrected by supersession, not by edit

**How append-only is honoured.** The charge asks for an amendment to a sentence committed on
2026-08-28. This ledger is append-only and is gated as such (GATE 10a against HEAD, GATE 10b against
every historical version), so no committed line may be reworded or removed. The only honest
instrument is this **appended superseding entry**, and it is used deliberately: the 2026-08-28
paragraph stands exactly as written, and this entry states where it is right, where it is wrong, and
what the wrong part costs. Nothing above this line was touched.

**What that paragraph says.** It clears the `dav_rotinv` doubling (one-sided 6.531×10⁻⁵ → two-sided
1.306×10⁻⁴) on the ground that METHODS and TR-8 use `dav_rotinv` only as a **BH ranking anchor**,
that the argument needs it to be strictly smaller than `dav_trigarray`, and that doubling is
order-preserving.

**That is exactly right for one of its three downstream sites and wrong for the other two, because
they do not share a comparator.** Read rather than counted:

| site | what `dav_rotinv` is compared against | 6.531×10⁻⁵ | 1.306×10⁻⁴ | order |
|---|---|---|---|---|
| `reports/METHODS.md:264` | `dav_trigarray`, 6.8×10⁻⁴ | smaller | still smaller | **preserved** — the paragraph is right |
| `reports/TR8_REORDERING_REVISITED.md:62` | the Schulz-gender **pair-null exact** mass 47/445740 = 1.054426×10⁻⁴ | smaller | **larger** | **reversed** |
| `reports/METHODS.md:292` | the same 1.054×10⁻⁴ rarity, same sentence shape | smaller | **larger** | **reversed** |

`dav_trigarray` is named in the paragraph; the pair-null mass is not, and it is the quantity the two
reversed sites rank. Only one operand of that comparison was doubled, so order-preservation is not
available there — it is a property of doubling *both* sides.

**What the reversal costs, stated under every reading rather than under the one that flatters it.**
The BH bar at rank *i* is *i*·0.05/91; at rank 1 it coincides with the Bonferroni bar 5.4945×10⁻⁴.

- **Mixed** (the rarity left one-sided, the anchor doubled): the anchor no longer sits below the
  rarity, so *i* ≥ 2 is not forced by it, and at rank 1 the margin is
  5.4945×10⁻⁴ ÷ 1.054426×10⁻⁴ = **5.21×** — the Bonferroni number, because at rank 1 the two bars
  are the same bar.
- **Consistently two-sided** (the convention TR-10 adopted on 2026-08-28): the rarity doubles too, to
  2.108853×10⁻⁴, so *i* ≥ 2 is restored — and the margin is
  2·(0.05/91) ÷ 2.108853×10⁻⁴ = **5.21×** again. Under this reading the *Bonferroni* margin also
  halves, from 5.21× to **2.61×**.
- **Consistently one-sided:** the published ≥~10× stands, but that reading is the one the
  2026-08-28 correction ruled against.

So the published BH margin survives only under a wholly one-sided ledger, and under both readings
that respect the 2026-08-28 convention the figure is ~5.2×, not ≥~10×. The two arithmetics landing on
the same number is not a coincidence: doubling the anchor either demotes the rank or doubles the
ranked value, and those cancel.

**One dependency stated rather than assumed.** The rank-1 conclusion holds *given that the anchor
those two sentences name is the only support they offer for i ≥ 2*, which is what they say. The full
91-observable ordering is not published as a list anywhere in this corpus, so "no ledger value is
strictly smaller than 1.054426×10⁻⁴" is **not** something this entry checked; METHODS' own
2026-08-01 narrowing withdrew the nine registry masses that were the previously-offered support, and
the C1–C5 counterpart of this same rule (≈8.80×10⁻⁵) is itself a registry mass excluded from BH
ranking. If some other ranked value is smaller, the rank rises and the margin rises with it.

**Still outstanding, and not fixed here.** `TR8:62`, `TR8:242` (the v1.11 revision row, which
restates the claim in the present tense) and `METHODS:292` all still carry the *i* ≥ 2 support and
the ≥~10× margin. They are outside this documentation lane's files; the outstanding fix is to restate
TR-8's BH margin as ~5.21× or rebuild the ordering with consistently sided p-values, and to add a
TR-8 revision row for it. Nothing in this entry changes a measured value in those reports, and no
verdict in the suite moves either way: the rarity clears the global bar under every reading above.
`reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md:110` already carries the two-sided correction inline
and needs nothing.

**No needle is registered for this defect, and the reason is structural.** The wording that is wrong
lives in this append-only ledger, where it must stay. A registry row would match at HEAD forever and
fail GATE 3 on every run. A gate that cannot be satisfied is not a gate.

### 2. `documentation/PROJECT_OVERVIEW.md` — the charged site was already closed; two uncharged siblings were not

The charge cited the conditional-entropy paragraph's claim that boundaries 25 and 27 are structurally
independent "of all other boundaries". **Verified at HEAD: already closed.** That sentence now reads
"of the other boundaries … that the rest of the greedy set does not reach", and carries a scope
paragraph. Reported as closed, not counted as a fix.

**Censusing the claim rather than the charged string found two live sites the charge did not name** —
the minimum-4-set paragraph and the 560T "still mandatory" bullet, both asserting that the
information carried by 25 and 27 is implied by no other boundary. That is false, and deciding it
needs no enumeration at all. `documentation/SOLVE.md` defines boundary *N* as pinning the pair at
position *N* **and** the pair at position *N*+1. So boundary 24 ∧ boundary 26 entails boundary 25
(24 supplies position 25, 26 supplies position 26), and boundary 26 ∧ boundary 28 entails boundary
27. Every record satisfying {1, 4, 21, 24, 26, 28} therefore satisfies {1, 4, 21, 25, 27}, which
leaves **zero** non-KW survivors at 560T — so a six-boundary set containing neither 25 nor 27
identifies King Wen.

**Both sites now state the exact claim instead of the universal:** no *single* other boundary carries
that information, because one boundary pins two consecutive positions and only boundary 25 pins
{25, 26}. The scope paragraph now records the decided counterexample **and its limit**: the argument
cannot be pushed to cardinality 5, because entailing boundary 25 and boundary 27 together requires
positions 25, 26, 27 and 28 all pinned, two boundaries pin at most four positions, and the only
two-boundary set pinning exactly those four is {25, 27} itself. The five-subset question stays open
by enumeration; the unrestricted reading is closed as false. Registered as **RP-212288d7**.

**Where the charge overreached, published rather than repeated.** The adjudication reads the
counterexample as showing "the surviving claim is about greedy minima only". It shows less than that
and more than the page said. It refutes the *unrestricted* reading — every identifying set contains
25 or 27 — at cardinality 6. It does **not** touch the *minimum-set* reading, since 6 > 5, and the
construction provably cannot reach cardinality 5. Both bounds are now on the page.

**One sibling site is reported, not fixed, because it is outside this lane's files:**
`documentation/HISTORY.md:795` states the same universal in a different grammatical form ("no
combination of other boundaries kills the families they catch"). **RP-212288d7 cannot reach it**

🔴 **A second sibling was claimed and is withdrawn before this entry was committed.** The draft of
this entry also named `documentation/SOLVE.md:391` as carrying "no other boundary combination can
eliminate what they eliminate". That is wrong twice over, and both halves were checked rather than
one: the quoted string appears **nowhere** in `SOLVE.md` — nor anywhere in the adjudication it was
attributed to — and `:391` is a per-boundary conditional-entropy paragraph. The genuinely related
claim in that file is at **`:413`**, and it is **correctly scoped and not contradicted**: it says
"no matter how cleverly you choose the other 2 of your **4** boundary constraints…", which is the
*minimum-set* reading the counterexample at cardinality 6 explicitly leaves standing. Naming it as a
survivor would have manufactured a contradiction that does not exist, in an append-only file where
it could only ever be superseded, never removed — that is the reachability class this batch also recorded in the private
finding note, and it is why the two survivors are named here in full rather than left to a needle.

### 3. `documentation/ROAE_PY_CLI.md` — the data description was corrected on 2026-08-27; the interface description was not

Traditional and translated hexagram titles were removed from `roae.py` on 2026-08-27, and prose batch
P07 corrected the §FILES description of the shipped **data**. Three summaries of the **interface**
kept advertising a name as an accepted lookup key: the SYNOPSIS comment and the two INTERACTIVE
QUERIES rows.

**Verified by running the tool, not by reading it.** `--lookup Qian`, `--lookup 乾`, `--lookup Zhun`
and `--lookup 屯` each print `No hexagram found matching '…'`; `--lookup "Water over Thunder"`
returns hexagram 3; `--compare Qian Kun` prints `Could not find hexagram: Qian`. All three doc rows
now name the trigram-derived label as the key, and the `--lookup` row states the negative the
reviewer executed, so the row is falsifiable by running it. Registered as **RP-f00d31ac**,
**RP-625ddaa2** and **RP-40edf278** — three rows and not one, because the three sites share no
substring; the single spelling that would have covered all three matches seven files at HEAD, in most
of which it is correct, so it was measured and rejected rather than registered.

**Code-side residue disclosed in the doc rather than left silent.** `roae.py:2241` and `:2242` (the
`--help-sections` menu rows) and `roae.py:5088` and `:5090` (the matching `argparse` help strings)
still offer a name as a key, and the not-found message still does not say what the tool accepts.
Those are code edits outside this documentation pass. **No registry row can guard them:** GATE 3's
corpus is the tracked `*.md` set plus `reports/evidence/**`, so a needle cannot reach a Python file
at all.

### Census

Whitespace-flattened and character-folded over GATE 3's own corpus, by re-implementing its fold and
match rather than trusting a plain `grep`: **RP-212288d7 1 file / 2 sites → 0. RP-f00d31ac 1 → 0.
RP-625ddaa2 1 → 0. RP-40edf278 1 → 0.** The `allow` column is `__none__` on all four, and this entry
cites the keys rather than quoting the strings. The in-place marker on the 560T bullet **describes**
the retired universal instead of quoting it, for the same reason: quoting it in the file the needle
guards would have made the needle unsatisfiable there.

### Nothing measured changed

No count, sha, certificate, theorem or verdict moves. The §[9] independence ratio, the §[6] greedy
set and the 560T survivor counts are as published. What changed is that two pages stopped stating a
universal that is decidably false, one page stopped advertising an input the tool rejects, and the
BH-margin arithmetic is now on the record with its comparator named per site.

### Attribution

The three charges were raised by Codex review lenses (V2-L01 #1 and #3, V2-L22 #1). The per-site
comparator split, the two-reading margin arithmetic, the cardinality-6 counterexample's **limit** at
cardinality 5, the two uncharged PROJECT_OVERVIEW siblings, the rejection of a single broad CLI
needle on a measured seven-file count, and the append-only reasoning are this lane's. Codex is
**acknowledged**, not credited as an author.

## 2026-09-02 — the conflict theorem is a FOUR-rule result; three sites said five (backlog 43/44/45, SAT batch B5)

`sat.py`'s `grand-ccn4` target is the certificate-backed conflict theorem. Its `RULESETS` entry enforces
exactly `("parity", "rhythm", "gender", "ccn4")` — four gated clause blocks in `build()` — and the emitted
CNF is exactly additive over them: `plain` 239,062 clauses + parity 558 + rhythm 18,360 + gender 3,113
(incl. the 635-clause E-counter) + ccn4 1,000 = **262,093 = `grand-ccn4`**; adding CC-N8 (8,973 more,
+214 vars) gives `grander-strict` 271,066, the five-rule union. `five-loo-ccn8` regenerates a CNF whose
non-comment bytes are identical to `grand-ccn4`'s. Three sites nevertheless called the four-rule
decision "five": the `grand-ccn4` docstring (`sat.py`), the EXAMPLES heading above the `grand-ccn4`
command (`documentation/SAT_CLI.md`), and the executive summary of `reports/certificates/README.md`
("the retired five-rules wording"). All three now say four and name the rules; the SAT_CLI example additionally
gives the `grander-strict` command for the five-rule union. The README's dangling clause left by the
2026-08-01 scope insertion (", and specific two-rule pairs are already incompatible." hanging after a
closed parenthesis) is repaired in the same sentence. Registered as **RP-c4a9eaf8** and **RP-84aeeb62**.

### Census
Whitespace-flattened (the `sat.py` site wrapped "five-rule / conflict decision" across a line break and
is invisible to a line-wise grep): RP-c4a9eaf8 2 files / 2 sites → 0; RP-84aeeb62 1 → 0. The correct
`SAT_CLI.md` table row "The four- / five-rule conflict decisions" is untouched and does not match the
needle. No number, certificate, clause count or verdict changed: `grand-ccn4` re-emitted after the edit is
byte-identical to the pre-edit emission (md5 1ad4d61adffacb9076fb806664fc518c).

*(Key correction, pre-commit: this entry was drafted citing `RP-61e5ca49` for the first needle. The registry key is `sha256(phrase)[0:8]`, and the computed value is **`RP-c4a9eaf8`** — the drafted key was never computed. Caught by GATE 11 asking for a key no entry cited, and fixed before this append was committed, since the ledger is append-only thereafter.)*
