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
