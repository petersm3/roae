#!/usr/bin/env bash
# correction_marker_inventory.sh — step 1 of the inline-correction hygiene work: every inline
# correction MARKER in the public markdown, and whether a doc gate depends on it.
#
# WHAT IT IS
#   The inline markers (`⚠ **[CORRECTED …]**`, `[WITHDRAWN …]`, `[RETRACTED …]`, `[SUPERSEDED …]`,
#   "now reads") are to move into documentation/CORRECTIONS.md so that each document reads as its
#   corrected self. A marker does one of three jobs, and only the first is safe to move as it
#   stands:
#     class 1  redundant     — the current text already reads correctly without it;
#     class 2  load-bearing  — without it a reader could re-derive the withdrawn claim from text
#                              that was not changed; the surrounding text must be rewritten first;
#     class 3  gate-anchored — a doc gate's verdict depends on it, so the gate must be re-anchored
#                              (and shown red on a planted violation) before the marker moves.
#                              Once every leg of a row is re-anchored (the REANCHORED table, Q-937)
#                              the row reads `reanchored:<leg>=<anchor>` instead: the marker may
#                              move, provided it leaves that anchor behind.
#   This script decides class 3 MECHANICALLY and records which gate leg it is. Classes 1 and 2
#   are an editorial judgement; a row nobody has reviewed yet says `1|2` and `unreviewed`, and a
#   reviewed row carries its verdict from the REVIEWED table below, keyed on the line's content.
#
# HOW CLASS 3 IS DECIDED (ablation, not a keyword list)
#   Several gates treat marker vocabulary as "this is narration, not a claim" and exempt the
#   line or paragraph (GATE 27's MARK, the NARR/CORRM patterns of later gates, the `[CORRECTED …]`
#   span strip of the derived-figure gates). Reading ~50 such patterns and guessing which marker
#   each one needs is the error-prone route. Instead the script MEASURES it: it copies the tree
#   twice, deletes every marker span in one copy (newlines kept, so no line moves), runs
#   `scripts/doc_gates.sh` (all) and `scripts/citation_line_gate.sh --all-files --all-targets` in
#   both copies, and diffs the output. A new output line that cites `FILE.md:N` is attributed to
#   every marker whose span covers line N or whose block (the table row for a table line, else the
#   blank-line paragraph) contains N. The gate section the new line appears under is the leg.
#   A changed line that cites no line is handled by shape: the citation gate's `A.md->B[key]` pin
#   form is tied to the marker in A whose block holds `key`; a FINDING ([FAIL]/[note]/…) naming a
#   file is tied to the markers whose block holds a string the finding quotes, else to every marker
#   in that file (leg suffixed `(file)`); a COUNT line ([ok]/[info]/[cite] …) means the gate's
#   population moved, and becomes a `population` row (class `3?`, per gate and file), because no
#   single marker can be named from it. Those rows are what makes the verdict INCOMPLETE.
#   GATE 13 (a TR body edit needs a revision row; report-only) changes on ANY edit and is recorded
#   as one `any-edit` row, not as evidence against any marker.
#   The ablation is conservative in one direction: all markers are removed at once, so a gate that
#   only fails once EVERY marker is gone is attributed to each marker in the cited block, never
#   missed. It deletes the whole span, including any withdrawn wording quoted inside it, which is
#   what moving the marker into the ledger would do.
#
# WHAT IS A MARKER, AND WHAT IS NOT
#   kind=marker     a bracketed `[CORRECTED`, `[CORRECTION <date>`, `[WITHDRAWN`, `[RETRACTED`,
#                   `[SUPERSEDED` span (token column: the word as written, upper case). Ablated.
#                   Also the PARENTHESISED form (Q-935, 2026-10-02), e.g. `⚠ *(Corrected 2026-09-20,
#                   Q-123: this read …)*` or `(Superseded 2026-08-03 — …)`: an opening parenthesis
#                   directly before Corrected/Correction/Superseded/Withdrawn/Retracted (any case),
#                   and then the MARKER SHAPE: a YYYY-MM-DD date within 40 characters inside the same
#                   parenthesis (a line break allowed, a blank line not), or a `:`/`—`/`–` right after
#                   the word. Prose that merely contains the word in a parenthesis ("(corrected for
#                   drift)", "(correction 4)", "§6 (retracted)") has neither, and is not a marker.
#                   Its token column is the word in Title case (`Corrected`, `Superseded`, …), so the
#                   two forms stay distinguishable: upper case = bracketed, Title case = parenthesised.
#                   The span is the parenthesis (nesting counted, bounded by the paragraph), widened
#                   over a leading `⚠ ` and an italic/bold `*`/`**` that is closed right after it.
#                   Before 2026-10-02 the inventory could not see this form at all (CX-166 item 5).
#   kind=narration  the prose phrase "now reads". Ablated by deleting the phrase.
#   kind=ledger-link a `[CORRECTIONS.md](…)` / `[CORRECTIONS CX-NN](…)` / `[RETRACTED_PHRASES.tsv](…)`
#                   LINK (any bracket that is a link's text). Not a marker: it is the back-pointer
#                   form this work moves markers TO. Counted, never ablated.
#                   (A plain `grep '\[CORRECTION'` counts these as markers; most `[CORRECTION`
#                   hits in this corpus are these links.)
#   kind=changelog  a revision-history row (`| vN.M |`). The report's own changelog, read by
#                   GATE 12/13. Counted, never ablated, never moved.
#   CORRECTIONS.md and HISTORY.md are excluded: both are append-only ledgers.
#
# USAGE (the ablation runs the doc gates twice, ~3 minutes on a 16-core box: NOT on a 2-core one)
#   scripts/correction_marker_inventory.sh            # write documentation/CORRECTION_MARKER_INVENTORY.tsv
#   scripts/correction_marker_inventory.sh --stdout   # the same TSV on stdout
#   scripts/correction_marker_inventory.sh --list     # enumeration only, no gates run (class column `-`)
#   scripts/correction_marker_inventory.sh --selftest # span/kind known answers on synthetic text
#   CMI_KEEP_LOGS=DIR …                               # also keep the two gate logs in DIR, and
#   scripts/correction_marker_inventory.sh --attribute BASE.log ABL.log   # re-attribute them
# Verdict: one whole line CORRECTION_MARKER_INVENTORY=<COMPLETE|INCOMPLETE|ERROR> on stderr.
#   COMPLETE   every changed gate line was attributed to a marker line;
#   INCOMPLETE some gate's population moved with no marker nameable (listed; `population` rows);
#              the TSV is still written;
#   ERROR      nothing trustworthy was measured (no markers found, a gate run failed to start,
#              or the positive control below failed); nothing is written.
# POSITIVE CONTROL: GATE 27 exempts a withdrawn figure only when its block carries a marker, and
#   this corpus has WITHDRAWN markers beside registered withdrawn figures. If the ablation produces
#   no GATE 27 attribution the detector is blind, and the run is an ERROR, not an empty class 3.
#
# COLUMNS: file  line  kind  token  class  legs  review  line_sha
#   line_sha is the first 12 hex of sha256 of the line's text: it keys the REVIEWED table and
#   tells a reader whether the line still says what was classified. No line text is copied here:
#   quoting a withdrawn phrase into a data file would restate it.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "CORRECTION_MARKER_INVENTORY=ERROR cd" >&2; exit 2; }
OUT="documentation/CORRECTION_MARKER_INVENTORY.tsv"
MODE="${1:-write}"

core() {  # core <mode> [args...] — the Python half; modes: list | ablate DIR | attribute BASE ABL
python3 - "$@" <<'PY'
import hashlib, json, os, re, subprocess, sys

HIT = re.compile(r'\[CORRECTED|\[CORRECTION|now reads|\[WITHDRAWN|\[RETRACTED|\[SUPERSEDED')
# the parenthesised form (Q-935): `(` + the word, then a date in the same parenthesis within 40
# characters (one line break allowed, never a blank line), or a `:`/em/en dash right after the word.
PAREN = re.compile(r'\((?i:(corrected|correction|superseded|withdrawn|retracted))\b'
                   r'(?=(?:[^()\n]|\n(?![ \t]*\n)){0,40}?\b20[0-9]{2}-[0-9]{2}-[0-9]{2}|[ \t]*[:\u2014\u2013])')
CHANGELOG = re.compile(r'^\| *[vV][0-9]')
EXCLUDE = re.compile(r'(^|/)(CORRECTIONS|HISTORY)\.md$')

# REVIEWED — class 1/2 verdicts, keyed (file, line_sha). A key that no longer matches a line is
# reported on stderr (the line changed, so its verdict must be re-read), never silently applied.
# Values are (class, review) and the review is one token (no spaces, no tab): what was decided.
REVIEWED = {
    # tranche 1 (2026-09-26, the f11halfb evidence family). The marker at
    # reports/evidence/f11halfb/README.md:21@5a3b2917 was class 1 and has moved to the ledger, so it
    # is no longer a row here.
    ('reports/evidence/f11halfb/RESULTS.md', 'fd712baff659'):
        ('2', 'stays:the-quoted-recommended-wording-above-it-is-kept-as-TR-2-published-it-and-is-still-inaccurate'),
    ('documentation/F1C5_LAYER_FORMAT.md', '801779b51687'):
        ('1', 'reviewed:text-already-reads-3.29-TB-measured;moving-it-means-rewrapping-lines-105-112'),
    # tranche 2 (2026-10-02, Q-936 (b), batch 34): every row the inventory carried as `1|2 unreviewed`
    # (bracketed and parenthesised markers, and "now reads" narration), each read in its paragraph or
    # table row. Class 1: with the marker deleted, the surrounding text still reads correctly and does
    # not restate the withdrawn claim. Class 2: deleting the marker would leave the withdrawn wording
    # standing, or the marker carries the only statement of a caveat the text depends on, so the text
    # must be rewritten first (Q-938). The review token says which text the verdict rests on.
    ('CLAUDE.md', '00465bcfc043'):
        ('1', 'reviewed:rule-above-already-states-the-split-policy'),
    ('CLAUDE.md', 'd2b8083d4fde'):
        ('1', 'reviewed:operative-rule-below-already-states-the-split-policy'),
    ('CLAUDE.md', 'd3a86349b512'):
        ('1', 'reviewed:bare-date-tag;following-sentences-carry-the-withdrawal'),
    ('CLAUDE.md', 'd63457974d3b'):
        ('1', 'reviewed:bullet-already-reads-14-files'),
    ('CLAUDE.md', 'f0219a4b2b25'):
        ('1', 'reviewed:sentence-already-states-the-lower-bound;note-is-provenance'),
    ('documentation/BOUNDARY_MINIMUM.md', '1a59ec4f6390'):
        ('2', 'reviewed:only-statement-on-the-page-that-the-full-space-minimum-is-at-least-7'),
    ('documentation/BOUNDARY_MINIMUM.md', '5c2b86f94f1e'):
        ('1', 'reviewed:table-already-separates-greedy-set-and-4-set-family'),
    ('documentation/BRANCHES_EXPLAINED.md', '401c7ab46c8e'):
        ('1', 'reviewed:paragraph-above-already-gives-63145664-and-the-893-gap'),
    ('documentation/BRANCHES_EXPLAINED.md', '50090bc50b64'):
        ('1', 'reviewed:clause-already-says-orientation-is-C4s-own-choice'),
    ('documentation/BRANCHES_EXPLAINED.md', 'ab2c4d1a8942'):
        ('1', 'reviewed:row-text-itself-says-withdrawn'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '0908246c963a'):
        ('1', 'reviewed:paragraph-above-already-gives-the-four-element-tuple'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '09e80e1e9cde'):
        ('1', 'reviewed:rule-already-reads-about-one-source-enum-wall'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '25976d2c8868'):
        ('2', 'reviewed:only-statement-that-the-strict-increase-and-coverage-checks-are-not-yet-tooling'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '310d85522c49'):
        ('1', 'reviewed:text-already-gives-the-measured-13631-s'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '37af802a0fa3'):
        ('1', 'reviewed:paragraph-above-already-says-byte-identical'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '3b2d8fa1806c'):
        ('1', 'reviewed:text-already-reads-12.5-min-per-pass'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '42581a08033a'):
        ('1', 'reviewed:list-above-already-names-SOLVE_DEPTH'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '4fc7635b552f'):
        ('1', 'reviewed:text-already-re-derives-from-13631-s'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '630f88baa2c0'):
        ('1', 'reviewed:item-4-already-carries-depth'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '66a968966a97'):
        ('1', 'reviewed:text-above-already-restates-the-scan-count'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '76ce5d6aff9b'):
        ('1', 'reviewed:enclosing-text-already-reads-43876464466-records'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '891f345e3c04'):
        ('2', 'reviewed:table-header-defers-to-it-for-the-framing-and-checkpoint-caveat'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '8b8c7ae51401'):
        ('1', 'reviewed:paragraph-above-already-reads-8767x-short'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '8b9916da816c'):
        ('1', 'reviewed:row-already-says-not-published'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', '8d21139f3080'):
        ('1', 'reviewed:paragraph-already-attributes-1T-sha-differences-to-budget'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', 'a7ff08fb8ac4'):
        ('1', 'reviewed:code-above-already-uses-the-corrected-key'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', 'a8e935dda624'):
        ('1', 'reviewed:bullets-above-already-require-byte-identical-sha'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', 'ac57392ca76f'):
        ('1', 'reviewed:text-already-reads-58.8-percent-and-0.41x'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', 'cde0bab1ab96'):
        ('1', 'reviewed:row-already-separates-the-King-Wen-observation-from-the-verdict'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', 'd91929d6e216'):
        ('1', 'reviewed:paragraph-above-already-explains-the-replacement'),
    ('documentation/CAMPAIGN_METHODOLOGY.md', 'e5f2c082e25c'):
        ('1', 'reviewed:boxed-note-already-reads-consistently'),
    ('documentation/CANONICAL_HASHES.md', '00ff54783292'):
        ('1', 'reviewed:row-no-longer-carries-the-LTO-attribution'),
    ('documentation/CANONICAL_HASHES.md', '11fd7b6f2df8'):
        ('2', 'reviewed:row-still-asserts-the-1T-drift-it-withdraws'),
    ('documentation/CANONICAL_HASHES.md', '18a82188eee5'):
        ('2', 'reviewed:the-drift-gap-note-it-withdraws-is-still-above-it'),
    ('documentation/CANONICAL_HASHES.md', '2663ae1a7c79'):
        ('1', 'reviewed:paragraph-above-already-says-two-per-cell-budgets'),
    ('documentation/CANONICAL_HASHES.md', '2e4d45528618'):
        ('1', 'reviewed:sentence-already-gives-both-arms-stddev'),
    ('documentation/CANONICAL_HASHES.md', '403d25d6040d'):
        ('1', 'reviewed:paragraph-above-already-states-the-corrected-rule'),
    ('documentation/CANONICAL_HASHES.md', '466f5d4840e1'):
        ('1', 'reviewed:convention-already-reads-logical-decompressed-size'),
    ('documentation/CANONICAL_HASHES.md', '50d1907facd1'):
        ('1', 'reviewed:scale-list-already-omits-d2-10T'),
    ('documentation/CANONICAL_HASHES.md', '5e0096ec8528'):
        ('1', 'reviewed:bullet-already-lists-the-real-checks-and-the-shipped-expect-kw'),
    ('documentation/CANONICAL_HASHES.md', '60b8f7a9c810'):
        ('2', 'reviewed:the-sentences-it-withdraws-still-follow-it'),
    ('documentation/CANONICAL_HASHES.md', '63d88d44cf05'):
        ('1', 'reviewed:row-already-gives-2026-04-20-and-edccb16'),
    ('documentation/CANONICAL_HASHES.md', '645bb4f2c6ca'):
        ('1', 'reviewed:bullet-already-drops-the-stack-claim'),
    ('documentation/CANONICAL_HASHES.md', '6baf480affa9'):
        ('2', 'reviewed:the-NOT-REPRODUCIBLE-text-it-withdraws-is-still-above-it'),
    ('documentation/CANONICAL_HASHES.md', '718078bbe242'):
        ('2', 'reviewed:only-thing-withdrawing-the-host-environment-cause-the-bracket-above-gives'),
    ('documentation/CANONICAL_HASHES.md', '7ed5382810ab'):
        ('1', 'reviewed:cell-already-separates-the-King-Wen-observation-from-the-verdict'),
    ('documentation/CANONICAL_HASHES.md', '8f5d0299b94d'):
        ('1', 'reviewed:paragraph-no-longer-carries-the-LTO-attribution'),
    ('documentation/CANONICAL_HASHES.md', 'a35557a8415a'):
        ('1', 'reviewed:text-already-uses-the-corrected-ratio'),
    ('documentation/CANONICAL_HASHES.md', 'b2334245885b'):
        ('1', 'reviewed:sentence-already-corrected'),
    ('documentation/CANONICAL_HASHES.md', 'c7837a45af23'):
        ('1', 'reviewed:dated-label-on-a-heading;notes-are-the-corrected-version'),
    ('documentation/CANONICAL_HASHES.md', 'dcb1fc46614d'):
        ('1', 'reviewed:text-already-reads-4909e18-and-4900000-T'),
    ('documentation/CANONICAL_HASHES.md', 'eb39ffef9153'):
        ('1', 'reviewed:table-already-carries-the-corrected-floors'),
    ('documentation/CANONICAL_HASHES.md', 'f601f33c6903'):
        ('2', 'reviewed:the-bullet-above-defers-to-it-for-what-the-floor-is'),
    ('documentation/CIRCULAR_KING_WEN.md', '24de4f00e658'):
        ('1', 'reviewed:paragraph-above-already-says-C3-alone-breaks-rotation'),
    ('documentation/CITATIONS.md', '081a7f35084a'):
        ('1', 'reviewed:caveat-already-says-budgeted-enumeration'),
    ('documentation/CITATIONS.md', '21630a1867e8'):
        ('1', 'reviewed:entries-above-already-carry-anchors'),
    ('documentation/CITATIONS.md', '266b8291222d'):
        ('1', 'reviewed:sentence-already-reads-correctly'),
    ('documentation/CITATIONS.md', '4b372583ff85'):
        ('1', 'reviewed:sentence-already-reads-3-testable-pairs'),
    ('documentation/CITATIONS.md', '4c6cd6c76ff9'):
        ('1', 'reviewed:sentence-already-records-the-first-hand-read'),
    ('documentation/CITATIONS.md', '534aabe4016a'):
        ('1', 'reviewed:entry-already-dates-the-read-and-warns'),
    ('documentation/CITATIONS.md', '5914e3df6f6a'):
        ('1', 'reviewed:framing-already-names-the-self-reverse-subgroup'),
    ('documentation/CITATIONS.md', '5aac052a61f0'):
        ('1', 'reviewed:item-already-states-toolchain-scope-and-budget-condition'),
    ('documentation/CITATIONS.md', '61d2ec0c2088'):
        ('1', 'reviewed:passage-already-attributes-the-group-to-Yu-Fans-operation'),
    ('documentation/CITATIONS.md', '6bb134b4104a'):
        ('1', 'reviewed:sentence-already-attributes-the-operations-to-Yu-Fan'),
    ('documentation/CITATIONS.md', '70008db57739'):
        ('1', 'reviewed:sentence-already-says-an-exception-is-forced'),
    ('documentation/CITATIONS.md', '903fed00def5'):
        ('1', 'reviewed:entry-already-drops-the-edition-label'),
    ('documentation/CITATIONS.md', '92a4e556aa0f'):
        ('2', 'reviewed:the-withdrawn-3.3e37-figure-is-still-printed-in-the-sentence'),
    ('documentation/CITATIONS.md', 'a2de01656b7f'):
        ('2', 'reviewed:the-1781-sentence-alone-still-implies-the-withdrawn-no-access-inference'),
    ('documentation/CITATIONS.md', 'a53ab4f07e27'):
        ('1', 'reviewed:entry-already-drops-the-edition-label'),
    # ('documentation/CITATIONS.md', 'a5662de10714') — line 421, class 1 'sentence-already-reads-seventh'
    # in tranche 2 — is now class 3 by the one-file ablation (SOLO_ANCHORED below, GATE 71), so its
    # class-1 verdict is no longer applied and the key is removed rather than left to warn.
    ('documentation/CITATIONS.md', 'bc2854ad3918'):
        ('1', 'reviewed:list-already-omits-the-nonexistent-file'),
    ('documentation/CITATIONS.md', 'c179c688913d'):
        ('1', 'reviewed:sentence-already-says-KW-sits-at-the-C3-ceiling'),
    ('documentation/CITATIONS.md', 'c3aa04002a63'):
        ('1', 'reviewed:line-already-gives-the-2-4-6-multiset'),
    ('documentation/CITATIONS.md', 'cdcd6af5e472'):
        ('1', 'reviewed:entry-already-drops-the-edition-claim'),
    ('documentation/CITATIONS.md', 'd37205177895'):
        ('1', 'reviewed:sentence-already-cedes-priority-to-Zhu-Yuansheng'),
    ('documentation/CITATIONS.md', 'e08aff1054e0'):
        ('1', 'reviewed:line-already-says-orientation-is-definitional'),
    ('documentation/CLAIMS_DECIDED.md', '1d8b91106749'):
        ('1', 'reviewed:clause-already-says-orientation-is-definitional'),
    ('documentation/CLAIMS_DECIDED.md', '3cd5418430f8'):
        ('2', 'reviewed:sentence-above-still-names-two-rows-and-the-promised-follow-up'),
    ('documentation/CLAIMS_DECIDED.md', '5675b59012d1'):
        ('1', 'reviewed:row-already-gives-the-one-5-line-transition'),
    ('documentation/CLAIM_TO_ARTIFACT.md', '2ae9ba270ae1'):
        ('1', 'reviewed:label-text-already-states-the-approx-convention'),
    ('documentation/CLAIM_TO_ARTIFACT.md', '324f7ccfdaf1'):
        ('1', 'reviewed:row-already-records-the-cake_lpr-leg'),
    ('documentation/DEPLOYMENT.md', '043dad8683eb'):
        ('1', 'reviewed:table-already-carries-1820-s'),
    ('documentation/DEPLOYMENT.md', '4a49a542d6ee'):
        ('1', 'reviewed:following-sentences-already-explain-merge-takes-no-arguments'),
    ('documentation/DEPLOYMENT.md', 'a6887a7e7e96'):
        ('1', 'reviewed:item-already-checks-decompressed-length'),
    ('documentation/DEPLOYMENT.md', 'c108685b1733'):
        ('1', 'reviewed:box-already-sizes-from-pre-dedup-records'),
    # ('documentation/DEPLOYMENT.md', 'cbe96c2b4198') was read as class 1 (sentence-already-reads-correctly),
    # but its row is class 3 (CITATION LINE GATE, GATE 2c), so the key never applied and was reported stale.
    # Retired in batch 35; restore it here if both legs are re-anchored.
    ('documentation/DEPLOYMENT.md', 'd79088c2324b'):
        ('1', 'reviewed:item-already-reads-wipe-then-write'),
    ('documentation/DESCRIPTION_LENGTH.md', 'a4a692a42886'):
        ('1', 'reviewed:bare-registry-key-tag;following-sentences-carry-the-correction'),
    ('documentation/DEVELOPMENT.md', '1b52abae68a7'):
        ('1', 'reviewed:narration-inside-a-retired-warning-note;text-reads-correctly'),
    ('documentation/DEVELOPMENT.md', '1ee2c8ff61f6'):
        ('1', 'reviewed:row-already-reads-build-id-sha1'),
    ('documentation/DEVELOPMENT.md', '2236f1c55fc2'):
        ('1', 'reviewed:text-above-already-gives-63145664-and-893'),
    ('documentation/DEVELOPMENT.md', '328a7e1a9a6a'):
        ('1', 'reviewed:row-already-reads-proc-pid-exe'),
    ('documentation/DEVELOPMENT.md', '33fde66d7234'):
        ('1', 'reviewed:bullet-already-checks-decompressed-length'),
    ('documentation/DEVELOPMENT.md', '4d55f0fd3e87'):
        ('1', 'reviewed:bullet-already-gives-32768-MB-and-pre-dedup-sizing'),
    ('documentation/DEVELOPMENT.md', '5d6522ddef0c'):
        ('1', 'reviewed:bullet-already-reads-D-als-v7-for-both-phases'),
    ('documentation/DEVELOPMENT.md', '6c9035ef137d'):
        ('1', 'reviewed:paragraph-already-describes-P1-auto-parallelism'),
    ('documentation/DEVELOPMENT.md', '71e678fefb7c'):
        ('1', 'reviewed:paragraph-above-already-documents-the-public-IP-residual'),
    ('documentation/DEVELOPMENT.md', '79ba53ed0166'):
        ('2', 'reviewed:sentence-above-still-says-proc-self-exe;the-marker-carries-the-fix-and-pre-fix-WARN-path'),
    ('documentation/DEVELOPMENT.md', '82e7fe10b5e5'):
        ('1', 'reviewed:item-above-already-reads-as-completed'),
    ('documentation/DEVELOPMENT.md', '8c79421519c1'):
        ('1', 'reviewed:text-already-says-size-equals-stored-size'),
    ('documentation/DEVELOPMENT.md', '9b282f2fc568'):
        ('2', 'reviewed:the-lead-in-above-still-introduces-the-withdrawn-manual-total-recipe'),
    ('documentation/DEVELOPMENT.md', '9fe08b854333'):
        ('1', 'reviewed:sentence-already-scoped-to-observed-reproduction'),
    ('documentation/DEVELOPMENT.md', 'ab81fe2c391b'):
        ('1', 'reviewed:passage-above-already-gives-10-h-single-threaded'),
    ('documentation/DEVELOPMENT.md', 'bb11bb8bf16c'):
        ('2', 'reviewed:the-dated-note-is-what-says-the-rest-of-the-row-predates-the-Q-317-change'),
    ('documentation/DEVELOPMENT.md', 'c510c83c79d4'):
        ('1', 'reviewed:paragraph-already-says-sub_ckpt_load-restores-state'),
    ('documentation/DEVELOPMENT.md', 'd4dcb7a62cd6'):
        ('1', 'reviewed:text-already-separates-count-matching-and-set-matching-K'),
    ('documentation/DEVELOPMENT.md', 'ff1b7fd00155'):
        ('1', 'reviewed:ordinary-present-tense-prose;not-a-correction-note'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', '0a25a691f691'):
        ('1', 'reviewed:bullet-already-credits-C5'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', '3fccde89e11b'):
        ('1', 'reviewed:sentence-already-states-failure-to-reject'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', '62856d90b93b'):
        ('1', 'reviewed:text-already-reads-Nyquist'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', '9036153ccd7d'):
        ('1', 'reviewed:item-already-credits-C5'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', '9863174beb75'):
        ('1', 'reviewed:paragraph-already-carries-the-float64-amplitudes'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', '9cb52cb48ee0'):
        ('1', 'reviewed:dated-label;item-already-states-the-withdrawal'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', 'a3904a2f87ba'):
        ('1', 'reviewed:dated-label;following-sentences-carry-the-withdrawal'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', 'b631e8d495f3'):
        ('1', 'reviewed:bullet-already-carries-the-float64-amplitude'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', 'f80e50122968'):
        ('1', 'reviewed:dated-label-on-a-bold-heading;paragraph-is-the-corrected-version'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', 'fd149d8d377b'):
        ('1', 'reviewed:sentence-already-says-C1-only-null-and-labels-each-figure'),
    ('documentation/GT_LADDER_FORMAT.md', '28f1fa67695a'):
        ('1', 'reviewed:list-already-reads-the-full-f1c5_unions-set'),
    ('documentation/GT_LADDER_FORMAT.md', '2abe8201815f'):
        ('1', 'reviewed:text-already-says-incomparable-with-the-reachable-set'),
    ('documentation/GT_LADDER_FORMAT.md', 'd70c66d8204d'):
        ('1', 'reviewed:clause-already-gives-8.27-TB-and-2.5x-f'),
    ('documentation/GUIDE.md', '03acc9f0c5f5'):
        ('1', 'reviewed:cell-already-separates-containment-and-attainment'),
    ('documentation/GUIDE.md', '47e547c15320'):
        ('1', 'reviewed:sentence-already-gives-the-5000-trial-modes'),
    ('documentation/GUIDE.md', '4953dd1799d5'):
        ('1', 'reviewed:paragraph-already-gives-the-optimality-characterization'),
    ('documentation/GUIDE.md', '74800e488dba'):
        ('1', 'reviewed:sentence-already-states-the-sampler-scoped-rate-bound'),
    ('documentation/GUIDE.md', '8359ad050331'):
        ('1', 'reviewed:entry-already-states-the-attainment-quantifier'),
    ('documentation/GUIDE.md', 'a1ced4a05f11'):
        ('1', 'reviewed:sentence-already-reads-monotone-4-then-5'),
    ('documentation/GUIDE.md', 'c4c826ace6cb'):
        ('1', 'reviewed:example-already-reads-2'),
    ('documentation/GUIDE.md', 'da0773140846'):
        ('1', 'reviewed:sentence-already-says-the-test-only-pointed-the-same-way'),
    ('documentation/GUIDE.md', 'df799cacd74c'):
        ('1', 'reviewed:sentence-already-scoped-to-ancient-sources'),
    ('documentation/GUIDE.md', 'eaab6a5d0d4e'):
        ('1', 'reviewed:cell-already-says-depends-on-the-null'),
    ('documentation/GUIDE.md', 'ebe35790be7c'):
        ('1', 'reviewed:paragraph-already-separates-linear-and-circular-scope'),
    ('documentation/GUIDE.md', 'f1226f140b5d'):
        ('1', 'reviewed:sentence-already-gives-the-one-Mawangdui-5-transition'),
    ('documentation/GUIDE.md', 'fd2e19f79b5f'):
        ('1', 'reviewed:paragraph-already-limits-the-shared-property-to-Jing-Fang'),
    ('documentation/KING_WEN_PROVENANCE.md', '88e8bf323be9'):
        ('1', 'reviewed:sentence-already-says-fragments'),
    ('documentation/KING_WEN_PROVENANCE.md', '8d31a7ebfff4'):
        ('1', 'reviewed:parenthetical-already-gives-the-16-and-8-split'),
    ('documentation/KING_WEN_PROVENANCE.md', '8d387c35b577'):
        ('1', 'reviewed:sentence-already-attributes-the-operations-to-Yu-Fan'),
    ('documentation/KING_WEN_PROVENANCE.md', '9ed102c86ec7'):
        ('2', 'reviewed:the-next-paragraph-refers-to-the-correction-above-for-the-3-testable-split'),
    ('documentation/KING_WEN_PROVENANCE.md', 'fea6292056fb'):
        ('1', 'reviewed:passage-already-reads-correctly;gating-rule-is-in-VERIFY.md'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', '2bbc938fe7bd'):
        ('1', 'reviewed:sentence-already-says-as-encoded-here'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', '492912af87c8'):
        ('1', 'reviewed:paragraph-already-describes-the-weighted-walk'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', '4da10afef401'):
        ('1', 'reviewed:item-already-prices-against-the-measured-6.52-percent'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', '57d478bba14c'):
        ('1', 'reviewed:caveat-already-says-the-fraction-is-weighted'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', '5903a37c4c44'):
        ('1', 'reviewed:text-already-gives-the-C1-C5-mean-16159'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', '5e81ed48b99c'):
        ('1', 'reviewed:sentence-already-reads-27-of-them'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', '7fdaba50b9bd'):
        ('1', 'reviewed:item-already-points-to-the-witness-and-estimate'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', '85d80a1ac4ee'):
        ('1', 'reviewed:item-already-names-all-three-edits'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', '9b3c2776ec1e'):
        ('1', 'reviewed:item-already-calls-the-SAT-leg-a-corroboration'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', '9dbb34dcd8c9'):
        ('1', 'reviewed:bullet-already-reads-by-two-each'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', '9ee222ffc7bf'):
        ('1', 'reviewed:ordinary-present-tense-prose;not-a-correction-note'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', 'b6060d49c0b2'):
        ('1', 'reviewed:text-already-says-sharing-the-locus'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', 'ba6e5b1a1a02'):
        ('1', 'reviewed:sentence-already-says-consistency-check-within-the-estimator-family'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', 'c1cac008ca87'):
        ('1', 'reviewed:item-already-scopes-the-discriminator-claim'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', 'c428343694d9'):
        ('1', 'reviewed:attribution-already-credits-the-lineage'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', 'c8013674f4fb'):
        ('1', 'reviewed:item-already-says-oriented-leaves-and-cites-r11'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', 'd51e96e9bd02'):
        ('1', 'reviewed:item-already-prices-against-the-measured-6.52-percent'),
    ('documentation/LITERATURE_RULES_POPULATION_TESTS.md', 'eee2ef7d81b3'):
        ('1', 'reviewed:text-already-says-the-estimator-refuses-and-exits-1'),
    ('documentation/MCKENNA.md', '4a0171a7ea11'):
        ('1', 'reviewed:bullet-already-separates-transition-and-static-MI'),
    ('documentation/MCKENNA.md', '5827b489c0c6'):
        ('1', 'reviewed:sentence-already-reads-1-in-1491'),
    ('documentation/MCKENNA.md', '6bfd0828d1b1'):
        ('1', 'reviewed:bullet-already-says-Gray-codes-can-beat-King-Wen'),
    ('documentation/MCKENNA.md', '743d04e71cab'):
        ('1', 'reviewed:sentence-already-reads-monotone-4-then-5'),
    ('documentation/MCKENNA.md', '82c5a6aa6ecd'):
        ('1', 'reviewed:paragraph-already-reads-two-of-four'),
    ('documentation/MCKENNA.md', 'acd849c87592'):
        ('1', 'reviewed:item-already-separates-the-module-and-the-day-calibration'),
    ('documentation/MCKENNA.md', 'c78c5123bc89'):
        ('1', 'reviewed:line-already-gives-the-1.33e38-estimate'),
    ('documentation/MCKENNA.md', 'e6189fe00a01'):
        ('1', 'reviewed:bullet-already-leads-with-descriptive-only'),
    ('documentation/MCKENNA.md', 'ffc5d3ef03f9'):
        ('1', 'reviewed:sentence-already-reads-correctly'),
    ('documentation/PARITY_ALTERNATION.md', '367c803f71d8'):
        ('1', 'reviewed:text-above-already-names-the-two-outside-figures'),
    ('documentation/PARITY_ALTERNATION.md', 'a9970f00d5eb'):
        ('1', 'reviewed:item-already-says-the-question-is-open'),
    ('documentation/PARTITION_INVARIANCE.md', '303730ca7ac0'):
        ('1', 'reviewed:consequence-already-reads-identical-record-sets'),
    ('documentation/PARTITION_STABILITY_BOUNDARIES.md', '8994f6c50536'):
        ('1', 'reviewed:table-already-lists-the-8-working-sets'),
    ('documentation/PARTITION_STABILITY_BOUNDARIES.md', '8af9abd8ef6a'):
        ('1', 'reviewed:paragraph-already-reads-monotone-and-stable'),
    ('documentation/PASS1_TRAJECTORY_DETERMINISM.md', '36ee2235a004'):
        ('1', 'reviewed:list-already-itemises-both-missing-commits'),
    ('documentation/PASS1_TRAJECTORY_DETERMINISM.md', '6c11157e7511'):
        ('1', 'reviewed:result-already-reads-under-1-percent-from-1e11'),
    ('documentation/PASS1_TRAJECTORY_DETERMINISM.md', '74eb5fead8b8'):
        ('1', 'reviewed:sentence-already-says-consistent-with-but-cannot-confirm'),
    ('documentation/PASS1_TRAJECTORY_DETERMINISM.md', '8f7805de5217'):
        ('1', 'reviewed:item-already-says-not-a-basis-for-projection'),
    ('documentation/PASS1_TRAJECTORY_DETERMINISM.md', '9e7979fcdfc3'):
        ('1', 'reviewed:paragraph-already-says-the-matching-rule-is-reproducible'),
    ('documentation/PASS1_TRAJECTORY_DETERMINISM.md', 'aa0563dffc6f'):
        ('1', 'reviewed:sentence-already-carries-the-sampling-caveat'),
    ('documentation/PASS1_TRAJECTORY_DETERMINISM.md', 'e9766e71f678'):
        ('1', 'reviewed:paragraph-above-already-gives-the-manual-procedure'),
    ('documentation/PERFORMANCE_HISTORY.md', '75cfed7a5f0e'):
        ('2', 'reviewed:bullet-above-still-carries-the-withdrawn-5.6T-days-derivation'),
    ('documentation/PERFORMANCE_HISTORY.md', '7b2509beaa95'):
        ('2', 'reviewed:bullet-above-still-lists-King-Wen-beside-the-gated-checks'),
    ('documentation/PERFORMANCE_HISTORY.md', 'e459f31d3a93'):
        ('2', 'reviewed:bullet-above-still-says-checkpoint-is-the-sole-resume-input'),
    ('documentation/PROJECT_OVERVIEW.md', '30097c8c87c5'):
        ('1', 'reviewed:dated-label;following-sentences-carry-the-withdrawal'),
    ('documentation/PROJECT_OVERVIEW.md', '37d8b2656705'):
        ('1', 'reviewed:bullet-already-states-the-positive-only-definition'),
    ('documentation/PROJECT_OVERVIEW.md', '3a7734310380'):
        ('1', 'reviewed:note-already-reads-stays-5-at-560T'),
    ('documentation/PROJECT_OVERVIEW.md', '519fab82ca45'):
        ('1', 'reviewed:bullet-already-reads-2-of-4'),
    ('documentation/PROJECT_OVERVIEW.md', '90f401aa2eb2'):
        ('1', 'reviewed:sentence-already-reads-monotone-4-then-5'),
    ('documentation/QUERY_INVENTORY.md', '099315cf46f4'):
        ('1', 'reviewed:cell-already-names-the-landed-consumer'),
    ('documentation/QUERY_INVENTORY.md', '5153589a8057'):
        ('1', 'reviewed:item-already-reads-priced-and-declined'),
    ('documentation/QUERY_INVENTORY.md', '5f70b5c4156d'):
        ('1', 'reviewed:stale-narrowing-is-already-struck-through'),
    # re-keyed batch 35 (was 85bc4c72984a): only a line-number cite on the line moved; re-read, same verdict.
    ('documentation/QUERY_INVENTORY.md', 'b26b7cea9ea8'):
        ('1', 'reviewed:stale-clause-is-already-struck-through'),
    ('documentation/QUERY_INVENTORY.md', '900d958f9aa5'):
        ('1', 'reviewed:cell-already-names-the-kc-figure'),
    ('documentation/QUERY_INVENTORY.md', '94c1605ab856'):
        ('2', 'reviewed:cell-above-still-describes-the-witness-row-as-unbuilt'),
    # re-keyed batch 35 (was daa1160a9ad7): only a line-number cite on the line moved; re-read, same verdict.
    ('documentation/QUERY_INVENTORY.md', '3c456275085a'):
        ('1', 'reviewed:cell-already-states-the-lower-bound-direction'),
    ('documentation/QUERY_INVENTORY.md', 'dacbcd2e9d4c'):
        ('2', 'reviewed:cell-above-still-gives-the-unbuilt-sat-witness-and-cert-path'),
    ('documentation/QUERY_INVENTORY.md', 'dd19eb8d2b73'):
        ('1', 'reviewed:box-already-says-the-identity-row-runs'),
    ('documentation/QUERY_INVENTORY.md', 'ebfbea5d0154'):
        ('1', 'reviewed:stale-clause-is-already-struck-through'),
    ('documentation/README.md', 'b808b2d22f64'):
        ('1', 'reviewed:bare-dated-tag;entry-already-reads-correctly'),
    ('documentation/REBUILD_FROM_SPEC.md', '0d6f61a86d87'):
        ('1', 'reviewed:paragraph-above-already-says-absence-is-not-a-failure'),
    ('documentation/REBUILD_FROM_SPEC.md', '27b224f7bdae'):
        ('1', 'reviewed:following-text-already-says-it-is-closed'),
    ('documentation/REBUILD_FROM_SPEC.md', '316359bbd462'):
        ('1', 'reviewed:text-already-says-reject-nonzero-reserved-bytes'),
    ('documentation/REBUILD_FROM_SPEC.md', '4cb506833207'):
        ('1', 'reviewed:bullet-already-says-slice-and-lower-bound'),
    ('documentation/REBUILD_FROM_SPEC.md', '58b66a480203'):
        ('1', 'reviewed:section-above-already-gives-the-real-fork-settings'),
    ('documentation/REBUILD_FROM_SPEC.md', '8d2089d7f4a6'):
        ('1', 'reviewed:following-text-already-says-the-gap-closed'),
    ('documentation/REBUILD_FROM_SPEC.md', 'a07fdd7ef677'):
        ('1', 'reviewed:paragraph-above-already-scopes-the-verifier'),
    ('documentation/REBUILD_FROM_SPEC.md', 'd16a31b227ea'):
        ('1', 'reviewed:paragraph-above-already-puts-the-range-test-first'),
    ('documentation/ROAE_PY_CLI.md', '1a9d70c8317f'):
        ('1', 'reviewed:following-text-already-states-the-Wilson-bound-rule'),
    ('documentation/ROAE_PY_CLI.md', '3d637f9508dd'):
        ('1', 'reviewed:row-already-lists-the-validated-fields'),
    ('documentation/ROAE_PY_CLI.md', '56e82d36e5cb'):
        ('1', 'reviewed:paragraph-already-says-negative-seeds-are-refused'),
    ('documentation/ROAE_PY_CLI.md', '9a1179f2ba84'):
        ('1', 'reviewed:summaries-above-already-corrected;closure-note-follows'),
    ('documentation/ROAE_PY_CLI.md', 'bff6cf9f9f63'):
        ('1', 'reviewed:following-text-already-states-one-file-per-role'),
    ('documentation/SAT_CLI.md', 'a6342c40e3e4'):
        ('2', 'reviewed:the-stale-2026-09-01-caveat-it-supersedes-is-still-above-it'),
    ('documentation/SEARCH_SPACE_SIZE.md', '01b0b7690f9a'):
        ('1', 'reviewed:text-already-says-all-eight-share-King-Wens-pair-ordering'),
    ('documentation/SEARCH_SPACE_SIZE.md', '046d3091ca0b'):
        ('2', 'reviewed:tag-is-what-qualifies-the-15-20-figure-in-the-same-sentence'),
    ('documentation/SEARCH_SPACE_SIZE.md', '15f866a22238'):
        ('1', 'reviewed:bullet-already-says-not-the-absence-of-synergy'),
    ('documentation/SEARCH_SPACE_SIZE.md', '785a0784b6f8'):
        ('1', 'reviewed:bullet-already-divides-by-11.10'),
    ('documentation/SEARCH_SPACE_SIZE.md', 'c3471d3127f8'):
        ('1', 'reviewed:paragraph-already-says-refuses-and-exits-1'),
    ('documentation/SOLUTIONS_FORMAT.md', '16e8291fe7e1'):
        ('1', 'reviewed:paragraph-above-already-gives-the-DGIT_HASH-build'),
    ('documentation/SOLUTIONS_FORMAT.md', '51d3fdcaa98f'):
        ('1', 'reviewed:paragraph-above-already-names-recount-fiber'),
    ('documentation/SOLUTIONS_FORMAT.md', '55a672f4c90b'):
        ('1', 'reviewed:text-already-says-only-the-logical-stream-is-reproducible'),
    ('documentation/SOLUTIONS_FORMAT.md', '71521e90beea'):
        ('1', 'reviewed:sentence-already-says-slice-and-lower-bound'),
    ('documentation/SOLUTIONS_FORMAT.md', '985d51d9032d'):
        ('1', 'reviewed:paragraph-above-already-sizes-the-core-and-the-file'),
    ('documentation/SOLUTIONS_FORMAT.md', '98c8b305512b'):
        ('1', 'reviewed:sentence-already-names-the-per-sub-branch-budget'),
    ('documentation/SOLUTIONS_FORMAT.md', 'b029690dda6e'):
        ('1', 'reviewed:step-6-already-says-solve-performs-the-check'),
    ('documentation/SOLUTIONS_FORMAT.md', 'bbfae3b641c9'):
        ('1', 'reviewed:sentence-already-says-logical-stream'),
    ('documentation/SOLUTIONS_FORMAT.md', 'ccc455e01f41'):
        ('1', 'reviewed:bullet-already-says-independently-enforced-filter'),
    ('documentation/SOLUTIONS_FORMAT.md', 'f18e86b06d42'):
        ('1', 'reviewed:sentence-already-scoped-to-the-toolchain-class'),
    ('documentation/SOLUTIONS_FORMAT.md', 'fca6092d1bd5'):
        ('1', 'reviewed:paragraph-above-already-states-the-running-minimum-condition'),
    ('documentation/SOLVE.md', '083326300fa5'):
        ('1', 'reviewed:paragraph-already-gives-the-measured-pair-counts'),
    ('documentation/SOLVE.md', '193a35b41031'):
        ('1', 'reviewed:subsection-already-says-definition-alone'),
    ('documentation/SOLVE.md', '30acb2a34949'):
        ('1', 'reviewed:row-already-reads-KW-plus-Jing-Fang'),
    ('documentation/SOLVE.md', '328ca31d5f05'):
        ('1', 'reviewed:sentence-already-says-a-boundary-fixes-the-pair-not-orientation'),
    ('documentation/SOLVE.md', '339c19d61221'):
        ('1', 'reviewed:bullet-already-names-boundary-1-2-or-3'),
    ('documentation/SOLVE.md', '33c9d32a013c'):
        ('1', 'reviewed:list-already-opens-with-boundary-4'),
    ('documentation/SOLVE.md', '3d33e04ce530'):
        ('1', 'reviewed:bullets-already-give-the-measured-pair-counts'),
    ('documentation/SOLVE.md', '41337d7b166b'):
        ('1', 'reviewed:bullet-already-says-orientation-is-definitional'),
    ('documentation/SOLVE.md', '469f1664eeb1'):
        ('1', 'reviewed:paragraph-already-closes-the-Costas-question'),
    ('documentation/SOLVE.md', '4b0ce207ff97'):
        ('1', 'reviewed:passage-already-gives-169-and-127-bits'),
    ('documentation/SOLVE.md', '4e0d4a97a61d'):
        ('1', 'reviewed:item-already-reads-92-94-percent'),
    ('documentation/SOLVE.md', '5216af68c2c2'):
        ('2', 'reviewed:the-dead-branch-figures-it-withdraws-still-follow-it'),
    ('documentation/SOLVE.md', '6054d313347c'):
        ('1', 'reviewed:paragraph-already-says-slice-not-C1-C5'),
    ('documentation/SOLVE.md', '6690d92f942f'):
        ('1', 'reviewed:status-already-gives-the-measured-pair-counts'),
    ('documentation/SOLVE.md', '72382011ced3'):
        ('1', 'reviewed:sentence-already-says-within-its-node-budget'),
    ('documentation/SOLVE.md', '79ac87deb12a'):
        ('1', 'reviewed:paragraph-already-says-the-scale-is-not-measured'),
    ('documentation/SOLVE.md', '7ce3f3cce019'):
        ('1', 'reviewed:sentence-already-counts-9-boundaries'),
    ('documentation/SOLVE.md', '87e1c1e30461'):
        ('1', 'reviewed:proof-already-separates-containment-and-attainment'),
    ('documentation/SOLVE.md', '9628b670d156'):
        ('1', 'reviewed:sentence-already-gives-the-four-independent-constraints'),
    ('documentation/SOLVE.md', '9d1d73f46a15'):
        ('1', 'reviewed:paragraph-already-scopes-the-reconstruct-output'),
    ('documentation/SOLVE.md', 'a99732fec1d5'):
        ('1', 'reviewed:status-already-reads-4-then-5'),
    ('documentation/SOLVE.md', 'b0090bbf58c0'):
        ('1', 'reviewed:paragraph-already-gives-the-one-Mawangdui-5-transition'),
    ('documentation/SOLVE.md', 'bc06215af301'):
        ('1', 'reviewed:paragraph-already-gives-the-tie-aware-nulls'),
    ('documentation/SOLVE.md', 'f68f5f29f9dc'):
        ('1', 'reviewed:bullet-already-gives-the-1-in-10-tie-share'),
    ('documentation/SOLVE.md', 'fc27fdfd642e'):
        ('1', 'reviewed:dated-label;following-text-proves-the-C5-identity'),
    ('documentation/SOLVE.md', 'fc308b1604d4'):
        ('1', 'reviewed:sentence-already-says-not-to-something-unique'),
    ('documentation/SOLVE_C_CLI.md', '1a0038252308'):
        ('2', 'reviewed:only-warning-that-the-pipeline-reproduces-figures-withdrawn-as-evidence'),
    ('documentation/SOLVE_C_CLI.md', '1b2fae92923a'):
        ('1', 'reviewed:dated-change-note;not-a-correction-of-a-claim'),
    ('documentation/SOLVE_C_CLI.md', '1c1c6dba49b7'):
        ('1', 'reviewed:entry-already-reports-the-order-48-group'),
    # re-keyed batch 36 (was 22bf68b96d54): Q-317 (CX-281) appended a dated note to the line; re-read, same verdict.
    ('documentation/SOLVE_C_CLI.md', '1b12ee0a92d0'):
        ('1', 'reviewed:dated-change-note;not-a-correction-of-a-claim'),
    ('documentation/SOLVE_C_CLI.md', '2338b84a23d6'):
        ('1', 'reviewed:dated-label;bullet-already-reads-correctly'),
    # re-keyed batch 35 (was 2cfd795d413c): only a line-number cite on the line moved; re-read, same verdict.
    ('documentation/SOLVE_C_CLI.md', '907e2fa66794'):
        ('1', 'reviewed:line-already-gives-the-256-ceiling'),
    ('documentation/SOLVE_C_CLI.md', '45051dcbdad8'):
        ('1', 'reviewed:rule-already-sized-from-input-bytes'),
    ('documentation/SOLVE_C_CLI.md', '46a97e015195'):
        ('1', 'reviewed:text-already-reads-62-bit-primes'),
    ('documentation/SOLVE_C_CLI.md', '592602838f8a'):
        ('1', 'reviewed:text-already-names-q3_profile_exact.tsv'),
    ('documentation/SOLVE_C_CLI.md', '63c0c714db2a'):
        ('1', 'reviewed:text-already-scopes-the-battery-to-recomputed-fields'),
    ('documentation/SOLVE_C_CLI.md', '6c61e6d03852'):
        ('1', 'reviewed:box-already-says-it-sends-no-signal'),
    ('documentation/SOLVE_C_CLI.md', '6e7c42db49bc'):
        ('1', 'reviewed:row-already-gives-the-checkpoint-line-deletion'),
    ('documentation/SOLVE_C_CLI.md', '72888a99f0d6'):
        ('1', 'reviewed:text-already-says-not-computable-from-these-ladders'),
    ('documentation/SOLVE_C_CLI.md', '808e7bc5c96a'):
        ('1', 'reviewed:paragraph-already-names-the-two-call-sites'),
    ('documentation/SOLVE_C_CLI.md', '89495b0914e8'):
        ('1', 'reviewed:bare-dated-tag;paragraph-already-reads-correctly'),
    ('documentation/SOLVE_C_CLI.md', '8e8057a85468'):
        ('1', 'reviewed:entry-already-says-published-per-cell-budget'),
    ('documentation/SOLVE_C_CLI.md', '96fb6601bad3'):
        ('1', 'reviewed:bare-dated-tag;paragraph-already-reads-correctly'),
    ('documentation/SOLVE_C_CLI.md', 'aa7908b7e52b'):
        ('1', 'reviewed:cell-already-says-priced-and-declined'),
    ('documentation/SOLVE_C_CLI.md', 'ab669c06c3cd'):
        ('1', 'reviewed:cell-already-says-per-depth-5-task'),
    ('documentation/SOLVE_C_CLI.md', 'abdc61332614'):
        ('1', 'reviewed:box-already-says-the-list-is-a-stale-subset-and-no-date'),
    ('documentation/SOLVE_C_CLI.md', 'b208aeec0192'):
        ('1', 'reviewed:text-already-quotes-the-banner'),
    ('documentation/SOLVE_C_CLI.md', 'b4ca98c0f26a'):
        ('1', 'reviewed:text-already-describes-the-measured-table'),
    ('documentation/SOLVE_C_CLI.md', 'b5c21b0c3aed'):
        ('1', 'reviewed:cell-already-gives-the-default-and-report-only'),
    ('documentation/SOLVE_C_CLI.md', 'b8207f4d281a'):
        ('1', 'reviewed:paragraph-already-says-fatal'),
    ('documentation/SOLVE_C_CLI.md', 'b85869d92f61'):
        ('1', 'reviewed:text-already-says-unreadable-layer-is-an-error'),
    ('documentation/SOLVE_C_CLI.md', 'c679478fb3ba'):
        ('1', 'reviewed:cell-already-gives-3.29-TB-measured'),
    ('documentation/SOLVE_C_CLI.md', 'cc7c25fe4496'):
        ('1', 'reviewed:paragraph-already-says-O-offset-on-gzip'),
    ('documentation/SOLVE_C_CLI.md', 'cd93fea96130'):
        ('1', 'reviewed:line-already-gives-exit-40'),
    ('documentation/SOLVE_C_CLI.md', 'cecef1272b2a'):
        ('1', 'reviewed:paragraph-already-reads-256-GB'),
    ('documentation/SOLVE_C_CLI.md', 'd44c32e2312b'):
        ('1', 'reviewed:text-already-quotes-the-banner'),
    ('documentation/SOLVE_C_CLI.md', 'da12417b44fb'):
        ('1', 'reviewed:text-already-names-solutions_p1_o1.bin'),
    ('documentation/SOLVE_C_CLI.md', 'da1d6940526c'):
        ('1', 'reviewed:following-text-already-explains-distinct-not-independent'),
    ('documentation/SOLVE_C_CLI.md', 'dbcd5e611b07'):
        ('1', 'reviewed:paragraph-already-says-no-header'),
    ('documentation/SOLVE_C_CLI.md', 'dc1b247c020e'):
        ('1', 'reviewed:section-above-already-gives-the-real-formats'),
    ('documentation/SOLVE_C_CLI.md', 'e0d8ba7f7138'):
        ('1', 'reviewed:paragraph-above-already-says-both-checkers-fail-a-class-duplicate'),
    ('documentation/SOLVE_C_CLI.md', 'e0fa245a5d0c'):
        ('1', 'reviewed:paragraph-already-says-instrument-boundary'),
    ('documentation/SOLVE_C_CLI.md', 'e7b031833ffa'):
        ('1', 'reviewed:section-already-compares-the-two-correctly'),
    ('documentation/SOLVE_C_CLI.md', 'fa29ec2344cf'):
        ('1', 'reviewed:cell-already-cites-r11-and-the-CI'),
    ('documentation/SOLVE_C_CLI.md', 'fae3082f6785'):
        ('1', 'reviewed:section-above-already-says-budget-and-refuses-non-numeric'),
    ('documentation/SOLVE_PY_CLI.md', '07976c4b6454'):
        ('1', 'reviewed:row-already-names-flow_div_24'),
    ('documentation/SOLVE_PY_CLI.md', '2b526e83b072'):
        ('1', 'reviewed:paragraph-already-gives-the-measured-4.349-percent'),
    ('documentation/SOLVE_PY_CLI.md', '388d511cb961'):
        ('1', 'reviewed:sentence-already-true-since-the-gate-moved-to-the-emitter'),
    # re-keyed batch 36 (was 3f7511a8ab6b): Q-932 (CX-279) named the integer test in the cited code; re-read, still class 2.
    ('documentation/SOLVE_PY_CLI.md', 'ce4fc3faed93'):
        ('2', 'reviewed:only-statement-that-the-CI-is-conditional-on-the-shared-pool'),
    ('documentation/SOLVE_PY_CLI.md', '69dfe1571f39'):
        ('1', 'reviewed:dated-label;sentence-already-reads-correctly'),
    ('documentation/SOLVE_PY_CLI.md', '871c547dbacd'):
        ('2', 'reviewed:paragraph-above-still-says-the-sampler-is-not-on-main'),
    ('documentation/SOLVE_PY_CLI.md', 'a9311de1c5bb'):
        ('1', 'reviewed:row-already-pins-hexagram-63-first'),
    ('documentation/SOLVE_PY_CLI.md', 'adef18abb0c4'):
        ('1', 'reviewed:paragraph-above-already-omits-F5'),
    # re-keyed batch 35 (was d929e80c48aa): only a line-number cite on the line moved; re-read, same verdict.
    ('documentation/SOLVE_PY_CLI.md', 'fc0c83cdf4eb'):
        ('2', 'reviewed:only-statement-that-the-encoded-orientation-is-the-representatives-not-the-draw'),
    ('documentation/SOLVE_SUMMARY.md', '17330333a03e'):
        ('1', 'reviewed:bullet-already-withdraws-the-superlative-in-its-own-words'),
    ('documentation/SOLVE_SUMMARY.md', '19ad9b11bcfb'):
        ('1', 'reviewed:dated-label;item-already-reads-2-of-4'),
    ('documentation/SOLVE_SUMMARY.md', '3c5b8586e07b'):
        ('1', 'reviewed:table-text-already-re-derived-from-the-logs'),
    ('documentation/SOLVE_SUMMARY.md', '5296f1d53f8a'):
        ('1', 'reviewed:paragraph-already-says-the-scale-is-not-measured'),
    ('documentation/SOLVE_SUMMARY.md', '725c72fe2a77'):
        ('1', 'reviewed:paragraph-already-gives-the-same-and-reverse-order-couples'),
    ('documentation/SOLVE_SUMMARY.md', '73e5a645e093'):
        ('1', 'reviewed:sentence-already-scopes-3-to-1-to-the-circular-reading'),
    ('documentation/SOLVE_SUMMARY.md', '99d0ad144096'):
        ('1', 'reviewed:bullet-already-says-definitional-not-forced'),
    ('documentation/SOLVE_SUMMARY.md', '9a7dc3e54e17'):
        ('1', 'reviewed:bullet-already-states-the-560T-figure-hedged'),
    ('documentation/SOLVE_SUMMARY.md', 'a53b5628cc8b'):
        ('1', 'reviewed:dated-label;bullet-already-says-coupled-not-free'),
    ('documentation/SOLVE_SUMMARY.md', 'bd12ec3877f7'):
        ('1', 'reviewed:paragraph-already-places-twins-front-middle-and-back'),
    ('documentation/SOLVE_SUMMARY.md', 'd62604a92ae6'):
        ('1', 'reviewed:paragraph-already-says-Costas-is-closed'),
    ('documentation/SOLVE_SUMMARY.md', 'ee32cf8d5224'):
        ('1', 'reviewed:sentence-already-names-the-distance-5-block'),
    ('documentation/SOLVE_SUMMARY.md', 'ee852cef77a8'):
        ('1', 'reviewed:narration-inside-a-revision-note;text-reads-correctly'),
    ('documentation/SPECIFICATION.md', '05b4538c7973'):
        ('1', 'reviewed:bare-date-tag;following-sentences-carry-the-correction'),
    ('documentation/SPECIFICATION.md', '092ab0017afc'):
        ('1', 'reviewed:bullet-already-lists-the-8-working-sets'),
    ('documentation/SPECIFICATION.md', '23d50b7dc205'):
        ('1', 'reviewed:sentence-already-gives-the-measured-pair-counts'),
    ('documentation/SPECIFICATION.md', '44f715b69340'):
        ('1', 'reviewed:note-already-says-orientation-is-definitional'),
    ('documentation/SPECIFICATION.md', '5976759b5053'):
        ('1', 'reviewed:statement-already-separates-containment-and-attainment'),
    ('documentation/SPECIFICATION.md', '5f9cd49af177'):
        ('1', 'reviewed:sentence-already-says-the-command-does-not-test-uniqueness'),
    ('documentation/SPECIFICATION.md', '7b2b419ca33e'):
        ('1', 'reviewed:block-already-says-the-compiler-is-in-main'),
    ('documentation/SPECIFICATION.md', '7e3976fa3206'):
        ('1', 'reviewed:bullet-already-reads-stays-5'),
    ('documentation/SPECIFICATION.md', '9c849fb61abe'):
        ('1', 'reviewed:bullet-already-attributes-growth-to-node-budget'),
    ('documentation/SPECIFICATION.md', 'e98c37bebecb'):
        ('1', 'reviewed:bullet-already-gives-the-measured-pair-counts'),
    ('documentation/SPECIFICATION.md', 'ef9cd60a8d7e'):
        ('1', 'reviewed:entry-already-says-no-pair-suffices'),
    ('documentation/SPECIFICATION.md', 'f0ca664440fd'):
        ('1', 'reviewed:sentence-already-says-two-partition-depths'),
    ('documentation/SPECIFICATION.md', 'f5e885738c62'):
        ('1', 'reviewed:sentence-already-counts-C6-C7-inside-the-boundary-set'),
    ('documentation/SYMMETRY_SEARCH.md', '1e1ef8d65e95'):
        ('1', 'reviewed:sentence-already-says-read-in-full'),
    ('documentation/SYMMETRY_SEARCH.md', '2abf18eb8c3c'):
        ('1', 'reviewed:note-already-gives-the-full-chain'),
    ('documentation/SYMMETRY_SEARCH.md', '487cfe6dbf8a'):
        ('1', 'reviewed:dated-label;result-already-states-the-order-48-group'),
    ('documentation/SYMMETRY_SEARCH.md', '97e87ff422ea'):
        ('1', 'reviewed:sentence-already-names-the-two-private-inputs'),
    ('documentation/SYMMETRY_SEARCH.md', 'c3471d3127f8'):
        ('1', 'reviewed:paragraph-already-says-refuses-and-exits-1'),
    ('documentation/SYMMETRY_SEARCH.md', 'cd72ebe708fa'):
        ('1', 'reviewed:paragraph-already-separates-palindromes-and-partners'),
    ('documentation/TRIGRAM_STRUCTURE.md', '553c4e750078'):
        ('1', 'reviewed:sentence-already-says-kernel-evaluated-for-all-three'),
    ('documentation/VERIFY.md', '1469cd949612'):
        ('1', 'reviewed:row-already-gives-the-16-MB-requirement'),
    ('documentation/VERIFY.md', '1ef62a3f1feb'):
        ('1', 'reviewed:row-already-attributes-to-Yu-Fan-and-scopes-the-12-16-band'),
    ('documentation/VERIFY.md', '453d2b32b175'):
        ('1', 'reviewed:text-already-gives-9-15-7'),
    ('documentation/VERIFY.md', '4b56db87bbf7'):
        ('2', 'reviewed:paragraph-above-still-says-the-witness-row-does-not-exist'),
    ('documentation/VERIFY.md', '51e29f0a7e61'):
        ('1', 'reviewed:text-already-compares-the-Actual-sha256-line'),
    ('documentation/VERIFY.md', 'b0831baa9ed2'):
        ('2', 'reviewed:the-sentence-it-withdraws-still-stands-immediately-above-it'),
    ('documentation/VERIFY.md', 'c8a94784a806'):
        ('1', 'reviewed:row-already-names-KingWen.lean'),
    ('documentation/VERIFY.md', 'ccc7478b2a31'):
        ('1', 'reviewed:dated-label;row-already-cites-Lemma-1'),
    ('documentation/VERIFY.md', 'fa839526f832'):
        ('1', 'reviewed:paragraph-already-says-no-instrument-here-counts-C3-conditioned'),
    ('enumeration/LEADERBOARD.md', '2cb7abe5c0a2'):
        ('1', 'reviewed:paragraph-already-reads-from-the-742M-archive'),
    # re-keyed batch 35 (was 829aed6413ee): only a line-number cite on the line moved; re-read, same verdict.
    ('enumeration/LEADERBOARD.md', '945a371c2c4b'):
        ('1', 'reviewed:sentence-already-calls-it-an-overlap-ratio'),
    ('enumeration/LEADERBOARD.md', '8ff0ea958479'):
        ('1', 'reviewed:qualifier-already-uses-0-based-pair-numbers'),
    ('lean/README.md', '5b5a41a13f81'):
        ('1', 'reviewed:sentence-above-already-says-definitional'),
    ('lean/README.md', '7e04babdaffb'):
        ('1', 'reviewed:sentence-already-reads-fifteen'),
    ('lean/README.md', '826d33dcd3dd'):
        ('1', 'reviewed:table-already-carries-the-re-measured-figures'),
    ('lean/README.md', 'd4ca86898847'):
        ('1', 'reviewed:sentence-already-names-stdout-as-load-bearing'),
    ('reports/FULL31_EXACT_AGGREGATES.md', '44ec9d8de0a7'):
        ('1', 'reviewed:following-text-already-gives-the-measured-ratios'),
    ('reports/FULL31_EXACT_AGGREGATES.md', '78717a9d8def'):
        ('1', 'reviewed:paragraph-already-calls-the-ceiling-an-extrapolation'),
    ('reports/FULL31_EXACT_AGGREGATES.md', '859f11490cbd'):
        ('1', 'reviewed:sentence-already-names-the-layer_curve-exception'),
    ('reports/FULL31_EXACT_AGGREGATES.md', 'a8b3e44f5cfe'):
        ('1', 'reviewed:text-already-defines-V_k-as-residual-vectors'),
    ('reports/README.md', '2a35a3c9c536'):
        ('1', 'reviewed:meta-mention-of-the-marker-form-in-code;not-a-correction'),
    ('reports/README.md', '31f8297b0b33'):
        ('1', 'reviewed:row-already-scopes-to-the-Gray-path-claim'),
    ('reports/README.md', 'b4ce93c76e88'):
        ('1', 'reviewed:row-already-scopes-to-the-first-four-boundaries'),
    ('reports/README.md', 'eeaba5fb691c'):
        ('1', 'reviewed:row-already-says-not-confined-to-V-0'),
    ('reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md', '07a138384de5'):
        ('2', 'reviewed:only-statement-that-the-archived-outputs-carry-no-se-field'),
    ('reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md', '2e8f4b7da1d6'):
        ('1', 'reviewed:sentence-already-says-C1-C5-constraints'),
    ('reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md', '475777f8f1d6'):
        ('1', 'reviewed:row-already-reads-does-not-meet-the-bar'),
    ('reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md', '4f2bbde898c9'):
        ('1', 'reviewed:row-already-reads-NULL'),
    ('reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md', 'c97ee1aca8e2'):
        ('1', 'reviewed:sentence-already-says-C1-C5-constraints'),
    ('reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md', 'a2af80174980'):
        ('1', 'reviewed:dated-label;following-sentences-carry-the-correction'),
    ('reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md', 'b03da3a55d6e'):
        ('1', 'reviewed:text-already-separates-plain-and-storage-mode-agreement'),
    ('reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md', 'b657a7632159'):
        ('1', 'reviewed:text-above-already-quotes-the-corrected-selector-output'),
    ('reports/TR12_QUERY_PROGRAM.md', '006b75696937'):
        ('1', 'reviewed:text-already-says-the-certificate-is-loaded-and-used'),
    ('reports/TR12_QUERY_PROGRAM.md', '1148e37a9c94'):
        ('1', 'reviewed:text-already-says-validates-not-tightens'),
    ('reports/TR12_QUERY_PROGRAM.md', '180fe56529dc'):
        ('1', 'reviewed:sentence-already-says-the-directory-is-tracked'),
    ('reports/TR12_QUERY_PROGRAM.md', '1c6c27f1c56a'):
        ('1', 'reviewed:text-already-says-solve.c-differs'),
    ('reports/TR12_QUERY_PROGRAM.md', '205d798de93b'):
        ('1', 'reviewed:parenthetical-already-gives-the-Bonferroni-arithmetic'),
    # re-keyed batch 35 (was 2b2404425aa0): Q-944 added the replay check to the cell; re-read, still class 1.
    ('reports/TR12_QUERY_PROGRAM.md', '15f88f5e990f'):
        ('1', 'reviewed:cell-already-says-the-2026-07-21-run-is-attested-and-names-its-replay-check'),
    ('reports/TR12_QUERY_PROGRAM.md', '2c1d251a6490'):
        ('1', 'reviewed:text-already-gives-the-TV-distance-and-cell-range'),
    ('reports/TR12_QUERY_PROGRAM.md', '2e4dad3aee80'):
        ('1', 'reviewed:text-already-describes-what-the-row-delivers'),
    ('reports/TR12_QUERY_PROGRAM.md', '3615257e9c26'):
        ('1', 'reviewed:text-already-says-the-atlas-is-distributed'),
    ('reports/TR12_QUERY_PROGRAM.md', '474bb47a658a'):
        ('1', 'reviewed:cell-already-says-bound-from-below'),
    ('reports/TR12_QUERY_PROGRAM.md', '5208df717772'):
        ('1', 'reviewed:text-already-says-t-price-is-a-floor'),
    ('reports/TR12_QUERY_PROGRAM.md', '5cd736162e40'):
        ('1', 'reviewed:text-already-splits-totals-and-per-query'),
    ('reports/TR12_QUERY_PROGRAM.md', '5cde45e31b0f'):
        ('1', 'reviewed:text-already-names-the-real-files'),
    ('reports/TR12_QUERY_PROGRAM.md', '655061a87291'):
        ('1', 'reviewed:text-already-says-the-file-is-distributed'),
    ('reports/TR12_QUERY_PROGRAM.md', '684884e12ba2'):
        ('1', 'reviewed:scope-already-states-the-one-sided-relation'),
    ('reports/TR12_QUERY_PROGRAM.md', '715e5a15829e'):
        ('1', 'reviewed:bullet-already-lists-what-f-alone-answers'),
    ('reports/TR12_QUERY_PROGRAM.md', '725e799b65d4'):
        ('1', 'reviewed:step-already-names-the-per-row-files'),
    ('reports/TR12_QUERY_PROGRAM.md', '747e86000ac1'):
        ('1', 'reviewed:text-already-separates-all-slots-and-interior'),
    ('reports/TR12_QUERY_PROGRAM.md', '787d37353231'):
        ('1', 'reviewed:sentence-already-scopes-12.10'),
    ('reports/TR12_QUERY_PROGRAM.md', '7bdc9663f67e'):
        ('1', 'reviewed:text-already-scopes-the-asrun-receipt'),
    ('reports/TR12_QUERY_PROGRAM.md', '7eb16a45e8f6'):
        ('1', 'reviewed:output-line-already-names-the-two-galleries'),
    ('reports/TR12_QUERY_PROGRAM.md', '8670f78aa107'):
        ('1', 'reviewed:column-list-already-matches-the-table'),
    ('reports/TR12_QUERY_PROGRAM.md', '8f4153493d43'):
        ('1', 'reviewed:cell-already-says-no-battery-run-took-the-digests'),
    ('reports/TR12_QUERY_PROGRAM.md', '9a7593256e26'):
        ('1', 'reviewed:output-line-already-names-the-consumer-path'),
    ('reports/TR12_QUERY_PROGRAM.md', '9c5d6f746f87'):
        ('2', 'reviewed:the-anchors-it-withdraws-are-still-described-above-it'),
    ('reports/TR12_QUERY_PROGRAM.md', 'a28283b06435'):
        ('1', 'reviewed:dated-label;paragraph-already-reads-correctly'),
    ('reports/TR12_QUERY_PROGRAM.md', 'aa9a1971d4bc'):
        ('1', 'reviewed:text-already-says-not-via-applyPerm-pairKey'),
    ('reports/TR12_QUERY_PROGRAM.md', 'ad03b1023f77'):
        ('1', 'reviewed:text-above-already-says-peak-unmeasured'),
    ('reports/TR12_QUERY_PROGRAM.md', 'bacba42ca97d'):
        ('1', 'reviewed:text-already-says-the-witnesses-leg-verifies-pinned-bytes'),
    ('reports/TR12_QUERY_PROGRAM.md', 'c615aa613801'):
        ('1', 'reviewed:cell-already-scopes-the-container-count-to-t'),
    ('reports/TR12_QUERY_PROGRAM.md', 'c86e0a515c49'):
        ('1', 'reviewed:text-already-counts-three-exact-cells'),
    ('reports/TR12_QUERY_PROGRAM.md', 'c99c91dcc6b8'):
        ('1', 'reviewed:output-line-already-names-q1_rank.json'),
    ('reports/TR12_QUERY_PROGRAM.md', 'ceefbb4faa97'):
        ('1', 'reviewed:sentence-already-lists-the-figure-as-withdrawn'),
    ('reports/TR12_QUERY_PROGRAM.md', 'd1990517891c'):
        ('1', 'reviewed:sentence-already-says-witnesses-are-pinned'),
    ('reports/TR12_QUERY_PROGRAM.md', 'd6942b4ebed7'):
        ('1', 'reviewed:bullet-already-reads-priced-and-declined'),
    ('reports/TR12_QUERY_PROGRAM.md', 'd849097fa10d'):
        ('1', 'reviewed:text-already-says-uncommanded-not-unknown'),
    ('reports/TR12_QUERY_PROGRAM.md', 'e619af87797b'):
        ('1', 'reviewed:cell-already-says-exact-of-the-DP-defined-law'),
    ('reports/TR12_QUERY_PROGRAM.md', 'efc7d1699e2a'):
        ('2', 'reviewed:bullet-above-still-calls-the-witnesses-leg-a-named-skip'),
    ('reports/TR12_QUERY_PROGRAM.md', 'f42fde98cf69'):
        ('1', 'reviewed:following-text-already-names-the-three-objects'),
    ('reports/TR12_QUERY_PROGRAM.md', 'fe63899bd2f6'):
        ('1', 'reviewed:text-already-reads-estimate-withdrawn'),
    ('reports/TR12_QUERY_PROGRAM.md', 'ffa7e6e73b5e'):
        ('1', 'reviewed:text-already-pins-the-tag'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', '0b0c6d3c48e3'):
        ('1', 'reviewed:text-already-cites-r11-and-the-CI'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', '117db48bd83b'):
        ('1', 'reviewed:text-already-reads-correctly'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', '234e2ea62a8f'):
        ('1', 'reviewed:text-already-calls-the-SAT-leg-a-corroboration'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', '44b4c27eab96'):
        ('1', 'reviewed:ordinary-present-tense-prose;not-a-correction-note'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', '51179888e32e'):
        ('1', 'reviewed:caption-already-reads-by-2-each'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', '671fb44f217f'):
        ('1', 'reviewed:bullet-already-cites-r11-and-the-CI'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', '6f5d3afbea04'):
        ('1', 'reviewed:ordinary-present-tense-prose;not-a-correction-note'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', '9103015c1bee'):
        ('1', 'reviewed:text-already-gives-the-margins-without-minimal'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', '9ec29b3bbc44'):
        ('1', 'reviewed:sentence-already-gives-the-canonical-leaf-count'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', 'b1fe3a45cdb9'):
        ('1', 'reviewed:entry-already-prices-against-the-measured-6.52-percent'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', 'c60b3819912d'):
        ('1', 'reviewed:entry-already-prices-against-the-measured-6.52-percent'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', 'dc64c08cacb1'):
        ('1', 'reviewed:text-already-says-sharing-the-locus'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', 'e5524bd1cd03'):
        ('1', 'reviewed:caveat-already-says-the-fraction-is-weighted'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', 'e58c453b01b8'):
        ('1', 'reviewed:sentence-already-says-not-his-particular-one'),
    ('reports/TR1_EIGHT_CENTURIES_MEASURED.md', 'fb1338767194'):
        ('1', 'reviewed:clause-already-reads-27-of-the-31'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '16f3dd64e012'):
        ('1', 'reviewed:sentence-already-withdraws-the-superlative-in-its-own-words'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '352d885dffbc'):
        ('1', 'reviewed:dated-tag;following-sentences-carry-the-withdrawal'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '3da1a028fd5d'):
        ('1', 'reviewed:bullet-already-credits-Moore-and-scopes-Rutt'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '4651a9548a90'):
        ('1', 'reviewed:item-already-lists-the-four-cores'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '5347792796d3'):
        ('1', 'reviewed:sentence-already-reads-consistent-with'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '5a3c0faec052'):
        ('1', 'reviewed:item-already-points-at-the-one-copy'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '608682e5c158'):
        ('1', 'reviewed:text-already-says-the-four-rule-theorem-does-not-survive'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '6f409f5b942d'):
        ('1', 'reviewed:text-already-describes-the-three-slot-footprint'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '8d834628f0a0'):
        ('1', 'reviewed:sentence-already-reads-1.097e39'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '8edf5733ed6a'):
        ('1', 'reviewed:text-already-gives-the-by-V-failures'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '9bcb3a61818f'):
        ('1', 'reviewed:caption-already-reads-by-two-each'),
    ('reports/TR2_THE_RULES_CONFLICT.md', '745ac8b6ee5e'):
        ('1', 'reviewed:text-already-scopes-what-the-lattice-shows;re-read-after-the-Q-934-note-was-added-before-it'),
    ('reports/TR2_THE_RULES_CONFLICT.md', 'cd19d093f284'):
        ('2', 'reviewed:tag-is-the-only-withdrawal-in-the-sentence-stating-the-comparison-result'),
    ('reports/TR2_THE_RULES_CONFLICT.md', 'e4fa7b397922'):
        ('1', 'reviewed:paragraph-already-says-vetoed'),
    ('reports/TR3_REPRODUCIBLE_ENUMERATION.md', '16a1484e94fb'):
        ('1', 'reviewed:following-text-already-says-no-host-level-drift-event'),
    ('reports/TR3_REPRODUCIBLE_ENUMERATION.md', '932cc732b054'):
        ('1', 'reviewed:text-already-says-no-anchor-is-host-fragile'),
    ('reports/TR3_REPRODUCIBLE_ENUMERATION.md', 'c8ce7f461ee3'):
        ('1', 'reviewed:text-already-describes-the-opt-in-pre-push-gate'),
    ('reports/TR3_REPRODUCIBLE_ENUMERATION.md', 'c8ebf3cacb0b'):
        ('1', 'reviewed:code-comment-above-already-says-reported-not-enforced'),
    ('reports/TR3_REPRODUCIBLE_ENUMERATION.md', 'ea8441c5d8df'):
        ('1', 'reviewed:following-text-already-says-the-tools-stay-on-their-design'),
    ('reports/TR4_SIZE_OF_THE_SPACE.md', '6335beed5bb4'):
        ('1', 'reviewed:paragraph-already-says-refuses-and-exits-1'),
    ('reports/TR4_SIZE_OF_THE_SPACE.md', '871aa1b5f28c'):
        ('2', 'reviewed:the-distinct-vs-raw-pairing-it-withdraws-is-still-in-the-sentence-above'),
    ('reports/TR4_SIZE_OF_THE_SPACE.md', '98d091511a86'):
        ('2', 'reviewed:the-withdrawn-3.3e37-figure-is-still-printed-in-the-sentence-above'),
    ('reports/TR4_SIZE_OF_THE_SPACE.md', 'a040cc46ee1a'):
        ('2', 'reviewed:tag-is-what-qualifies-the-15-20-projection-in-the-same-sentence'),
    ('reports/TR4_SIZE_OF_THE_SPACE.md', 'cfdb5878a857'):
        ('1', 'reviewed:text-already-says-all-eight-share-King-Wens-pair-ordering'),
    ('reports/TR4_SIZE_OF_THE_SPACE.md', 'd266588052e1'):
        ('1', 'reviewed:bullet-already-prints-the-probe-count'),
    ('reports/TR5_SYMMETRY.md', '21ce077c312e'):
        ('1', 'reviewed:text-already-says-the-replacement-shipped'),
    ('reports/TR5_SYMMETRY.md', '511a4ff2566e'):
        ('1', 'reviewed:sits-inside-text-already-labelled-superseded'),
    ('reports/TR5_SYMMETRY.md', '6335beed5bb4'):
        ('1', 'reviewed:paragraph-already-says-refuses-and-exits-1'),
    ('reports/TR5_SYMMETRY.md', '6fba5e7a3e72'):
        ('1', 'reviewed:text-already-says-the-flag-ships'),
    ('reports/TR5_SYMMETRY.md', '9b0c1f76bf72'):
        ('1', 'reviewed:text-already-says-the-inputs-are-public'),
    ('reports/TR5_SYMMETRY.md', '9dcd5360988f'):
        ('1', 'reviewed:bullet-already-gives-the-shipped-command;superseded-text-is-labelled'),
    ('reports/TR5_SYMMETRY.md', 'b90c0e2836b9'):
        ('1', 'reviewed:text-already-says-the-absence-alone-shows-nothing'),
    ('reports/TR5_SYMMETRY.md', 'b9b75ef36afc'):
        ('1', 'reviewed:caption-already-says-24-records-S4-invariant'),
    ('reports/TR5_SYMMETRY.md', 'd739d3b3d7b0'):
        ('1', 'reviewed:text-already-names-the-tree-node-statistic'),
    ('reports/TR6_PARITY_SKELETON.md', '07b994dbdadb'):
        ('1', 'reviewed:paragraph-already-says-fully-public-and-checkable'),
    ('reports/TR6_PARITY_SKELETON.md', '3c218a3dc97d'):
        ('1', 'reviewed:text-already-says-corroborating-not-independent'),
    ('reports/TR6_PARITY_SKELETON.md', '8e7e239e8898'):
        ('1', 'reviewed:text-already-states-the-two-modalities'),
    ('reports/TR7_CIRCULAR_READING.md', '950598f00a9b'):
        ('1', 'reviewed:text-already-says-lower-bound'),
    ('reports/TR8_REORDERING_REVISITED.md', '0719eb66ef60'):
        ('1', 'reviewed:text-already-separates-Python-and-Lean-timing'),
    ('reports/TR8_REORDERING_REVISITED.md', '18d9e6d088a8'):
        ('1', 'reviewed:text-already-says-only-one-rarity-is-estimator-independent'),
    ('reports/TR8_REORDERING_REVISITED.md', '804bba4e185c'):
        ('1', 'reviewed:sentence-already-reads-correctly'),
    ('reports/TR8_REORDERING_REVISITED.md', '9ed5548a0e40'):
        ('1', 'reviewed:passage-already-separates-the-two-quantities'),
    ('reports/TR9_PRICING_THE_CONSTRAINTS.md', '36ac98e5990d'):
        ('1', 'reviewed:bare-dated-tag;following-sentences-carry-the-correction'),
    ('reports/TR9_PRICING_THE_CONSTRAINTS.md', 'a5298cb36fc2'):
        ('1', 'reviewed:bare-dated-tag;following-sentences-carry-the-correction'),
    ('reports/TR9_PRICING_THE_CONSTRAINTS.md', 'b3ddf61963b0'):
        ('1', 'reviewed:narration-inside-a-correction-note;text-reads-correctly'),
    ('reports/TR9_PRICING_THE_CONSTRAINTS.md', 'b96b726f4220'):
        ('1', 'reviewed:text-already-reads-62-bit-primes'),
    ('reports/TR9_PRICING_THE_CONSTRAINTS.md', 'd8e1d0becd4b'):
        ('1', 'reviewed:sentence-already-says-zero-hits-bound-nothing'),
    ('reports/certificates/README.md', '2052b944c6ed'):
        ('1', 'reviewed:cell-already-describes-the-fixed-check'),
    ('reports/evidence/decoy/README.md', 'debafc91e8e8'):
        ('1', 'reviewed:paragraph-already-gives-the-relerr-distribution'),
    ('reports/evidence/f11/RESULTS.md', 'bddf92b9a1a9'):
        ('2', 'reviewed:the-re-affirmed-verdict-above-is-what-it-qualifies'),
    ('reports/evidence/f11halfb/README.md', 'd1896fedb93b'):
        ('2', 'reviewed:the-not-withdrawn-sentence-it-supersedes-is-still-above-it'),
    ('reports/evidence/r11/PHASE2_README.md', '3841bb943445'):
        ('2', 'reviewed:the-not-withdrawn-sentence-it-supersedes-is-still-above-it'),
    ('reports/evidence/r11/PHASE2_README.md', 'eec850ded09d'):
        ('1', 'reviewed:dated-label;paragraph-already-states-the-convention'),
    ('reports/evidence/r11/README.md', '552e49ec1111'):
        ('2', 'reviewed:the-not-withdrawn-sentence-it-supersedes-is-still-above-it'),
    ('reports/evidence/tr12/README.md', '32c0b703681b'):
        ('1', 'reviewed:bullet-already-says-no-battery-run-took-the-digests'),
    ('reports/evidence/tr12/README.md', '420b3de03f37'):
        ('1', 'reviewed:table-above-already-carries-the-recount'),
    ('reports/evidence/tr12/README.md', '80ab431c9646'):
        ('1', 'reviewed:bullet-already-scopes-the-container-count-to-t'),
    ('reports/evidence/tr12/v3_rows_n31_20260925/README.md', '27f78169945d'):
        ('1', 'reviewed:narration-inside-a-change-note;text-reads-correctly'),
    ('reports/evidence/w0d_lower_bound/README.md', '2b8aff0baaa3'):
        ('1', 'reviewed:text-already-says-the-atlas-is-distributed'),
    ('runs/20260419_100T_d3_d128westus3/README.md', 'd7c195a0b90a'):
        ('1', 'reviewed:bullet-already-cites-the-git-ls-files-listing'),
    ('runs/20260419_100T_d3_d128westus3/README.md', 'f7f41ce12530'):
        ('1', 'reviewed:dated-label;row-already-says-not-present'),
    ('runs/20260716_f1c5_c1c2c4c5_d128westus3/README.md', '2298a7a58936'):
        ('1', 'reviewed:example-above-already-reads-16384'),
    ('runs/20260716_f1c5_c1c2c4c5_d128westus3/layer_curve.md', 'eacac6a9e8de'):
        ('1', 'reviewed:dated-change-note;the-k19-bar-already-has-19-marks-and-no-count-changed'),
    ('runs/20260906_kc_ladders_n31/README.md', '5a56ba8ff38d'):
        ('1', 'reviewed:text-already-says-the-sidecar-re-reads-the-file'),
    ('scripts/tr12_expected/README.md', 'f830b198793f'):
        ('1', 'reviewed:sentence-above-already-scopes-to-what-a-row-prints'),
    ('viz/archive/viz_narrative.md', '6804ad0845dd'):
        ('1', 'reviewed:block-already-says-the-figures-exist-and-are-held'),
    ('viz/viz_kc_field.md', 'd3c5eb82e912'):
        ('1', 'reviewed:text-already-says-seven-plus-the-zero-row'),
    ('viz/viz_kc_grammar.md', '496a379935f2'):
        ('1', 'reviewed:text-already-gives-the-3-2-2-split'),
    ('viz/viz_kc_river.md', '9b90d85f5548'):
        ('1', 'reviewed:bullet-already-says-population-marginals-not-a-walk'),
    ('viz/viz_kc_shells.md', '2c75f1561ed0'):
        ('1', 'reviewed:text-already-describes-the-published-values'),
    ('viz/viz_kc_shells.md', '4b6e37053434'):
        ('1', 'reviewed:bullet-already-names-the-real-paths'),
    ('viz/viz_kc_shells.md', '94f3854c9362'):
        ('1', 'reviewed:text-already-says-31-post-placement-shells'),
    ('viz/viz_kc_shells.md', '9b76c8f78a29'):
        ('1', 'reviewed:text-already-names-the-consumer-path'),
    ('viz/viz_kc_shells.md', 'ea13d01b4000'):
        ('1', 'reviewed:text-already-lists-the-three-refusals'),
    ('viz/viz_scale.md', '30b54e71b0c4'):
        ('1', 'reviewed:status-already-reads-drawn'),
    ('viz/viz_scale.md', '50292e323d81'):
        ('1', 'reviewed:item-already-says-week-long-and-feasible'),
    ('viz/viz_scale.md', 'e5cd851ab33e'):
        ('1', 'reviewed:row-already-cites-TR-11-and-METHODS'),
    ('viz/viz_scale.md', 'ebc0122e15c3'):
        ('1', 'reviewed:heading-already-reads-decided'),
    # tranche Q-937 (2026-10-02, batch 35). These rows were class 3 only because GATE 4b's stale-row
    # finding named two files and was spread over every marker in both; with that finding tied to the
    # one marker it rests on (reports/METHODS.md, the retired "CRITIQUE.md Q1" pointer) they have no
    # gate leg, and were read here by the CX-266 rule (class 2 = the withdrawn wording still stands,
    # or the marker holds the only statement of something the text relies on). The SOLVE_C_CLI.md and
    # layer_curve.md rows are batch-34 markers that reached the table after CX-266 was read.
    ('documentation/CRITIQUE.md', 'c644bbbeed75'):
        ('1', 'reviewed:note-already-says-the-boundary-minimum-did-not-shift'),
    # re-keyed batch 35 (was eaf5abc0b734): only a line-number cite on the line moved; re-read, same verdict.
    ('documentation/CRITIQUE.md', '597d3234e446'):
        ('1', 'reviewed:update-already-states-minimum-5-and-the-overlap-reading-of-ratio-0.007'),
    ('documentation/CRITIQUE.md', 'f8ba3b65a9cf'):
        ('1', 'reviewed:sentence-already-states-the-rate-bound-scoped-to-its-sampler;no-minimum-claim-left'),
    ('documentation/CRITIQUE.md', '14f8e15eb91d'):
        ('1', 'reviewed:paragraph-already-closes-order-64-Costas-by-construction-and-C1'),
    ('documentation/CRITIQUE.md', '7af2bf88c662'):
        ('1', 'reviewed:proof-already-says-only-all-32-reverse-pairs-together-are-ruled-out'),
    ('documentation/CRITIQUE.md', '515c7944c99a'):
        ('1', 'reviewed:table-already-reads-12/12/8'),
    ('documentation/CRITIQUE.md', '1375d35925cf'):
        ('1', 'reviewed:passage-already-gives-the-circular-14-as-the-circular-reading'),
    ('documentation/CRITIQUE.md', 'd907e831bb97'):
        ('1', 'reviewed:sentence-already-says-13:2'),
    ('documentation/CRITIQUE.md', '46bddd89bbb5'):
        ('1', 'reviewed:label-only;the-narration-after-it-carries-the-correction'),
    ('documentation/CRITIQUE.md', '15db5a90707b'):
        ('1', 'reviewed:item-already-says-the-Golomb-G3-construction-gives-order-64'),
    ('documentation/CRITIQUE.md', 'b20c1fa789ca'):
        ('1', 'reviewed:answer-already-says-three-of-seven-families-cannot-exclude-KW'),
    ('documentation/CRITIQUE.md', '2ba747fae63b'):
        ('1', 'reviewed:item-already-states-the-5-boundary-minimum-at-560T'),
    ('documentation/CRITIQUE.md', '12cf3ecada50'):
        ('2', 'reviewed:marker-holds-the-only-statement-of-the-rerun-result-Mawangdui-9-of-11'),
    ('documentation/CRITIQUE.md', '508d410785a6'):
        ('1', 'reviewed:sentence-already-gives-the-3.4th-4.8th-percentile'),
    ('documentation/CRITIQUE.md', '3ce53bd6ba9a'):
        ('1', 'reviewed:label-only;the-section-already-reports-the-calibration-outcome'),
    ('documentation/CRITIQUE.md', '7e8663968875'):
        ('1', 'reviewed:paragraph-already-says-the-calibration-ran-and-failed-and-the-rest-is-vetoed'),
    ('documentation/SOLVE_C_CLI.md', 'e0d8ba7f7138'):
        ('1', 'reviewed:paragraph-above-already-says-both-checkers-fail-a-duplicate-canonical-class'),
    ('reports/METHODS.md', '0b88d6e7fd91'):
        ('1', 'reviewed:sentence-already-points-at-CORRECTIONS-and-names-no-public-archive'),
    ('reports/METHODS.md', '7572f71d2e55'):
        ('2', 'reviewed:marker-holds-the-only-statement-in-the-C4-bullet-of-what-the-classical-record-attests'),
    ('reports/METHODS.md', 'd5cd7e932a31'):
        ('1', 'reviewed:bullet-already-defines-C5-as-the-63-transition-multiset'),
    ('reports/METHODS.md', '06b77b191546'):
        ('1', 'reviewed:sentence-already-says-priced-and-declined-and-cites-TR-12-section-9'),
    ('reports/METHODS.md', '8dd1ef0fa19f'):
        ('1', 'reviewed:row-already-says-pin-to-a-commit-sha'),
    ('runs/20260716_f1c5_c1c2c4c5_d128westus3/layer_curve.md', 'eacac6a9e8de'):
        ('1', 'reviewed:bar-already-redrawn;note-is-provenance'),
    # tranche batch 35 (2026-10-03): the three markers Q-944 (CX-274) added to SOLVE.md, read by the
    # CX-266 rule. Each records only that the text once called the ~12% magnitude unresolved; the text
    # around it now gives both the ledger figure and the direct estimate.
    ('documentation/SOLVE.md', '9823cbd1f2ae'):
        ('1', 'reviewed:bullet-already-gives-12.1%-ledger-and-12.09%-direct-estimate'),
    ('documentation/SOLVE.md', '5f0ddf10cb02'):
        ('1', 'reviewed:item-already-gives-12.1%-ledger-and-12.09%-direct-estimate'),
    ('documentation/SOLVE.md', '78ad22311840'):
        ('1', 'reviewed:paragraph-already-gives-12.1%-ledger-and-12.09%-direct-estimate'),
    # tranche 3 (2026-10-03, Q-936 (a), batch 36): the `population` rows. Key (file or '-',
    # 'pop:' + gate leg), value (class, review). Each was attributed by a ONE-FILE ablation: the
    # doc gates and the citation gate were run once per file that holds a marker, with only that
    # file's markers deleted (81 runs), and every changed line behind the row was matched to the
    # one-file runs that print the same line (or, for a count, the same line shape). Class `n/a`:
    # the row names no marker of its own. Either it is a count that falls because text inside a
    # deleted span is gone (verdict unchanged), or a line that moves on any edit, or it is the
    # continuation text of a finding whose headline is already tied by line to class-3 rows of the
    # file(s) named. The two findings no line could name are tied by SOLO_ANCHORED below.
    ('-', 'pop:CITATION LINE GATE'):
        ('n/a', 'reviewed:summary-counts-only;legB-all-targets-and-excluded-counts-fall-with-citations-written-inside-deleted-spans;legA-A2-summary-moves-on-any-edit;verdict-tokens-follow-FAILs-already-tied-by-line'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', 'pop:CITATION LINE GATE'):
        ('n/a', 'reviewed:weak-pin-unmatched-list-of-the-content-rule-FAIL;one-file-runs-of-SOLVE_C_CLI.md-and-SOLVE_PY_CLI.md-print-it;their-citing-markers-are-class-3-by-line'),
    ('documentation/SOLVE.md', 'pop:CITATION LINE GATE'):
        ('n/a', 'reviewed:weak-pin-unmatched-list-of-the-content-rule-FAIL;the-SOLVE.md-one-file-run-prints-it;SOLVE.md-markers-are-class-3-by-line'),
    ('documentation/SOLVE_C_CLI.md', 'pop:CITATION LINE GATE'):
        ('n/a', 'reviewed:weak-pin-unmatched-list-of-the-content-rule-FAIL;the-SOLVE_C_CLI.md-one-file-run-prints-it;its-citing-markers-are-class-3-by-line'),
    ('documentation/SOLVE_PY_CLI.md', 'pop:CITATION LINE GATE'):
        ('n/a', 'reviewed:weak-pin-unmatched-list-of-the-content-rule-FAIL;the-SOLVE_PY_CLI.md-one-file-run-prints-it;its-citing-markers-are-class-3-by-line'),
    ('-', 'pop:GATE 2c'):
        ('n/a', 'reviewed:summary-counts-of-the-embedded-citation-run-only;counts-fall-with-citations-inside-deleted-spans;legA2-moves-on-any-edit;FAILs-already-tied-by-line'),
    ('documentation/DISTRIBUTIONAL_ANALYSIS.md', 'pop:GATE 2c'):
        ('n/a', 'reviewed:weak-pin-unmatched-list-of-the-content-rule-FAIL;one-file-runs-of-SOLVE_C_CLI.md-and-SOLVE_PY_CLI.md-print-it;their-citing-markers-are-class-3-by-line'),
    ('documentation/SOLVE.md', 'pop:GATE 2c'):
        ('n/a', 'reviewed:weak-pin-unmatched-list-of-the-content-rule-FAIL;the-SOLVE.md-one-file-run-prints-it;SOLVE.md-markers-are-class-3-by-line'),
    ('documentation/SOLVE_C_CLI.md', 'pop:GATE 2c'):
        ('n/a', 'reviewed:weak-pin-unmatched-list-of-the-content-rule-FAIL;the-SOLVE_C_CLI.md-one-file-run-prints-it;its-citing-markers-are-class-3-by-line'),
    ('documentation/SOLVE_PY_CLI.md', 'pop:GATE 2c'):
        ('n/a', 'reviewed:weak-pin-unmatched-list-of-the-content-rule-FAIL;the-SOLVE_PY_CLI.md-one-file-run-prints-it;its-citing-markers-are-class-3-by-line'),
    ('documentation/SOLVE_C_CLI.md', 'pop:GATE 2'):
        ('n/a', 'reviewed:documented-flag-count-211-to-210-because-a-deleted-span-names-a-flag;verdict-stays-ok;SOLVE_C_CLI.md-one-file-run'),
    ('documentation/SOLVE_PY_CLI.md', 'pop:GATE 2'):
        ('n/a', 'reviewed:documented-flag-count-170-to-169-because-a-deleted-span-names-a-flag;verdict-stays-ok;SOLVE_PY_CLI.md-one-file-run'),
    ('documentation/VERIFY.md', 'pop:GATE 2'):
        ('n/a', 'reviewed:documented-flag-count-167-to-165-because-deleted-spans-name-flags;verdict-stays-ok;VERIFY.md-one-file-run'),
    ('-', 'pop:GATE 3b'):
        ('n/a', 'reviewed:continuation-of-allowlist-row-matched-nothing-notes-plus-the-ok-count;TR9-and-runs-f1c5-README-one-file-runs-print-them;both-files-markers-are-class-3-by-line'),
    ('-', 'pop:GATE 4b'):
        ('n/a', 'reviewed:WHY-line-of-the-stale-allowlist-FAIL;the-METHODS.md-one-file-run-prints-it;METHODS.md-markers-are-class-3-GATE-4b(file)'),
    ('-', 'pop:GATE 5'):
        ('n/a', 'reviewed:noise-floor-count-125-of-247-to-123-of-241-falls-with-registry-values-inside-deleted-spans;no-finding;CLAIM_TO_ARTIFACT-CRITIQUE-LITERATURE_RULES-SOLVE-TR2-runs'),
    ('-', 'pop:GATE 18'):
        ('n/a', 'reviewed:RULING-LINE-FIX-and-stale-exemption-text-of-GATE-18-FAILs;SOLVE_SUMMARY.md-and-SOLVE_PY_CLI.md-one-file-runs-print-them;both-files-markers-are-class-3-GATE-18'),
    ('documentation/CITATIONS.md', 'pop:GATE 18'):
        ('n/a', 'reviewed:LIVES-AT-line-of-the-SOLVE_SUMMARY.md-GATE-18-FAIL-names-the-ruling-home;CITATIONS.md-one-file-run-leaves-GATE-18-unchanged'),
    ('reports/METHODS.md', 'pop:GATE 18'):
        ('n/a', 'reviewed:LIVES-AT-line-of-the-SOLVE_SUMMARY.md-GATE-18-FAIL-names-the-ruling-home;METHODS.md-one-file-run-leaves-GATE-18-unchanged'),
    ('-', 'pop:GATE 21'):
        ('n/a', 'reviewed:path-token-count-469-to-465-falls-with-backticked-paths-inside-deleted-spans;verdict-stays-ok;CLAUDE.md-CITATIONS.md-TR12-runs'),
    ('-', 'pop:GATE 25'):
        ('n/a', 'reviewed:documented-flag-use-count-1965-to-1922-falls-with-commands-inside-deleted-spans;no-finding;18-one-file-runs-move-it'),
    ('-', 'pop:GATE 26'):
        ('n/a', 'reviewed:excerpt-and-explanation-text-of-GATE-26-FAILs;each-excerpt-is-printed-by-its-own-files-one-file-run;all-8-files-have-class-3-GATE-26-rows'),
    ('documentation/SEARCH_SPACE_SIZE.md', 'pop:GATE 26'):
        ('n/a', 'reviewed:GATE-26-FAIL-excerpts-that-link-to-SEARCH_SPACE_SIZE.md;printed-by-CANONICAL_HASHES-SOLVE-SOLVE_SUMMARY-one-file-runs;their-markers-are-class-3-GATE-26'),
    ('-', 'pop:GATE 27'):
        ('n/a', 'reviewed:excerpt-and-explanation-text-of-GATE-27-FAILs;each-excerpt-is-printed-by-its-own-files-one-file-run;all-6-files-have-class-3-GATE-27-rows'),
    ('documentation/SEARCH_SPACE_SIZE.md', 'pop:GATE 27'):
        ('n/a', 'reviewed:GATE-27-FAIL-excerpt-that-links-to-SEARCH_SPACE_SIZE.md;printed-by-the-BRANCHES_EXPLAINED.md-one-file-run;its-markers-are-class-3-GATE-27'),
    ('-', 'pop:GATE 29'):
        ('n/a', 'reviewed:directive-shape-count-3-to-2-falls-with-the-correction-that-quotes-one;no-finding;TR8-one-file-run'),
    ('-', 'pop:GATE 33'):
        ('n/a', 'reviewed:superlative-count-7-to-6-falls-with-a-superlative-inside-a-deleted-span;no-finding;LITERATURE_RULES_POPULATION_TESTS-one-file-run'),
    ('-', 'pop:GATE 38'):
        ('n/a', 'reviewed:claim-count-126-to-121-and-quoted-retired-copy-1-to-0-fall-with-text-inside-deleted-spans;no-finding;lean-README-and-TR12-runs'),
    ('-', 'pop:GATE 39'):
        ('n/a', 'reviewed:SE-row-count-9-to-8-and-its-gap-exemption-4-to-3-fall-together;no-finding;TR10-one-file-run'),
    ('-', 'pop:GATE 41'):
        ('n/a', 'reviewed:mention-count-of-65281-49-to-44-falls-with-mentions-inside-deleted-spans;no-finding;CAMPAIGN_METHODOLOGY-CANONICAL_HASHES-TR5-runs'),
    ('-', 'pop:GATE 44'):
        ('n/a', 'reviewed:verdict-count-2-to-1-is-the-MCKENNA.md:88-span;its-FAIL-is-tied-by-SOLO_ANCHORED-GATE-44'),
    ('-', 'pop:GATE 53'):
        ('n/a', 'reviewed:continuation-text-of-the-GATE-53-sum-FAIL;the-LARGE_SCALE_CAMPAIGNS.md-one-file-run-prints-it;its-markers-are-class-3-GATE-53(file)'),
    ('documentation/LARGE_SCALE_CAMPAIGNS.md', 'pop:GATE 53'):
        ('n/a', 'reviewed:continuation-text-of-the-GATE-53-sum-FAIL;the-LARGE_SCALE_CAMPAIGNS.md-one-file-run-prints-it;its-markers-are-class-3-GATE-53(file)'),
    ('-', 'pop:GATE 56'):
        ('n/a', 'reviewed:judged-paragraph-count-13-to-17-rises-when-spans-no-longer-hide-figures;verdict-stays-ok;notes-tied-by-line-to-PROJECT_OVERVIEW.md'),
    ('-', 'pop:GATE 66'):
        ('n/a', 'reviewed:FIX-line-of-the-GATE-66-verbatim-FAIL;the-TRIGRAM_STRUCTURE.md-one-file-run-prints-it;its-markers-are-class-3-GATE-66'),
    ('-', 'pop:GATE 80'):
        ('n/a', 'reviewed:rec-literal-count-31-to-30-falls-with-a-literal-inside-a-deleted-span;verdict-stays-ok;TR12-one-file-run'),
    ('-', 'pop:GATE 86'):
        ('n/a', 'reviewed:explanation-text-of-the-GATE-86-digest-FAIL;the-PREREG_CLASSA_QUERY_SET.md-one-file-run-prints-it;its-markers-are-class-3-GATE-86(file)'),
    ('-', 'pop:GATE 89'):
        ('n/a', 'reviewed:corpus-byte-count-moves-on-any-edit;the-DOC-GATES-summary-follows-FAILs-tied-elsewhere'),
    ('-', 'pop:GATE 94 (ADVISORY)'):
        ('n/a', 'reviewed:advisory-live-count-falls-with-phrasings-quoted-inside-deleted-spans;CAMPAIGN_METHODOLOGY-GUIDE-viz_kc_river-runs'),
}

# SOLO_ANCHORED — markers a one-file ablation (Q-936 (a)) named for a gate finding that cites no
# line and names no file, so the joint ablation could not tie it to any marker. Each was then
# ablated alone in its file (every other marker of the file left in place) and is the only one that
# turns the gate red. Key (file, line_sha), value (gate leg, review). Applied only when that gate's
# section changed in the run; a key that matches no line, or whose gate did not change, is reported
# on stderr. The row gets the leg with a `(solo)` suffix and is class 3.
SOLO_ANCHORED = {
    # GATE 71: line 421's parenthesised marker fills the whole line; deleting it leaves a blank line
    # that splits the chain paragraph ("independent arrival" above, "→ ROAE" below), so the gate finds
    # 0 chain paragraphs. Moving it must keep the paragraph whole.
    ('documentation/CITATIONS.md', 'a5662de10714'):
        ('GATE 71', 'solo:blank-line-left-by-the-span-splits-the-chain-paragraph'),
    # GATE 44: the span holds one of the corpus's two narrated null-spectrum verdicts; without it the
    # gate falls under its floor of 2 and reports that it is measuring nothing.
    ('documentation/MCKENNA.md', '3a92c159f931'):
        ('GATE 44', 'solo:span-holds-one-of-the-two-null-spectrum-verdicts-the-gate-floor-needs'),
}

def md_files():
    out = subprocess.run(['git', 'ls-files', '-z', '--', '*.md'], capture_output=True, check=True).stdout
    return sorted(f for f in out.decode().split('\0') if f and not EXCLUDE.search(f))

def lsha(s):
    return hashlib.sha256(s.encode()).hexdigest()[:12]

def match_bracket(text, i, op='[', cl=']'):
    """index just past the `cl` matching the `op` at i, bounded by the paragraph (blank line)."""
    depth = 0; j = i; n = len(text)
    while j < n:
        c = text[j]
        if c == op: depth += 1
        elif c == cl:
            depth -= 1
            if depth == 0: return j + 1, True
        elif c == '\n' and re.match(r'\n[ \t]*(\n|$)', text[j:j+80]):
            return j, False
        j += 1
    return n, False

def hits(text):
    """(start, token, form) for every bracketed/narration hit and every parenthesised marker."""
    h = [(m.start(), m.group(0).lstrip('['), 'bracket') for m in HIT.finditer(text)]
    h += [(m.start(), m.group(1).capitalize(), 'paren') for m in PAREN.finditer(text)]
    return sorted(h)

def spans(text):
    """yield (start, end, kind, token, closed, token_pos) for every hit in text."""
    for (s, tok, form) in hits(text):
        ls = text.rfind('\n', 0, s) + 1
        le = text.find('\n', s); le = len(text) if le < 0 else le
        if CHANGELOG.match(text[ls:le]):
            yield (s, s, 'changelog', tok, True, s); continue
        if tok == 'now reads':
            yield (s, s + len(tok), 'narration', tok, True, s); continue
        if form == 'paren':
            e, closed = match_bracket(text, s, '(', ')')
            b = s
            pre = re.search(r'(?:⚠️? ?)?(\**)$', text[max(ls, s-8):s])
            if pre and pre.group(0):
                b = s - len(pre.group(0)); st = pre.group(1)
                if closed and st and text[e:e+len(st)] == st: e += len(st)
            yield (b, e, 'marker', tok, closed, s); continue
        e, closed = match_bracket(text, s)
        if closed and text[e:e+1] == '(':   # a markdown LINK whose text starts with the word
            yield (s, s, 'ledger-link', tok, True, s); continue
        # widen over the decoration around the bracket: `⚠ **[` … `]**`
        b = s
        pre = re.search(r'(⚠️? ?)?\*\*$', text[max(ls, s-8):s])
        if pre: b = s - len(pre.group(0))
        if closed and text[e:e+2] == '**': e += 2
        yield (b, e, 'marker', tok, closed, s)

def line_of(text, pos):
    return text.count('\n', 0, pos) + 1

def blocks(lines):
    """line -> (first,last) of its block: a table row alone, else its blank-line paragraph."""
    blk = {}; n = len(lines); i = 0
    while i < n:
        if not lines[i].strip(): i += 1; continue
        if lines[i].lstrip().startswith('|'):
            blk[i+1] = (i+1, i+1); i += 1; continue
        j = i
        while j + 1 < n and lines[j+1].strip() and not lines[j+1].lstrip().startswith('|'): j += 1
        for k in range(i, j+1): blk[k+1] = (i+1, j+1)
        i = j + 1
    return blk

def inventory():
    rows = []
    for f in md_files():
        try: text = open(f, encoding='utf-8').read()
        except (OSError, UnicodeDecodeError): continue
        lines = text.split('\n')
        seen = {}
        for (b, e, kind, tok, closed, tp) in spans(text):
            ln = line_of(text, tp)          # the line the TOKEN sits on (a decoration may start earlier)
            el = line_of(text, e - 1) if e > tp else ln
            key = (ln, kind, tok)
            if key in seen: continue
            seen[key] = 1
            rows.append(dict(file=f, line=ln, end=el, kind=kind, token=tok, closed=closed,
                             b=b, e=e, sha=lsha(lines[ln-1])))
    return rows

def ablate(root):
    """delete every marker/narration span in the copy at root, newlines kept."""
    n = 0
    for f in md_files():
        p = os.path.join(root, f)
        text = open(p, encoding='utf-8').read()
        cut = [(b, e) for (b, e, kind, tok, closed, tp) in spans(text) if kind in ('marker', 'narration') and e > b]
        if not cut: continue
        out = []; last = 0
        for (b, e) in sorted(cut):
            if b < last: b = last
            if e <= last: continue
            out.append(text[last:b]); out.append(re.sub(r'[^\n]', '', text[b:e])); last = e
        out.append(text[last:])
        new = ''.join(out)
        if new.count('\n') != text.count('\n'): raise SystemExit(f'correction_marker_inventory: blanking changed the line count of {f} (line citations would shift)')
        open(p, 'w', encoding='utf-8').write(new); n += len(cut)
    return n

def sections(path):
    """[(section header, line)] for a gate log; header = the last `== … ==` line above."""
    res = []; cur = '(preamble)'
    for l in open(path, encoding='utf-8', errors='replace').read().split('\n'):
        if re.match(r'^== .* ==$', l):
            cur = l.strip()
        res.append((cur, l))
    return res

CITE = re.compile(r'([A-Za-z0-9_./-]+\.md):([0-9]+)')

CITE2 = re.compile(r'(?:^|\s):([0-9]+) \[([A-Za-z0-9_./-]+\.md)\]')   # citation gate's ":N [path]" form
MDPATH = re.compile(r'[A-Za-z0-9_./-]+\.md\b')
ARROW = re.compile(r'([A-Za-z0-9_./-]+\.md)->[A-Za-z0-9_./-]+\[([^\]]+)\]')
QUOTE = re.compile(r'"([^"]{6,})"')
SECREF = re.compile(r'([A-Za-z0-9_./-]+\.md) -> ([A-Za-z0-9_./-]+\.md) §"([^"]+)"')   # GATE 4b's stale-row form
# Legs whose output changes on ANY edit to a file of their population, whatever the edit: a TR body
# edit needs a revision row (GATE 13, report-only), and the citation gate's leg-A summary counts
# edited files. They are requirements every tranche meets, not evidence that a marker is anchored.
ANY_EDIT = ('GATE 13',)
# REANCHORED (Q-937, batch 35) — gate legs that no longer depend on marker TEXT alone: the gate now
# also accepts a stable anchor, named here, that a moved marker leaves behind. A class-3 row whose
# EVERY leg is listed here, and whose ablation turned EVERY one of those legs red (a [FAIL] line
# tied to the row), reads `reanchored:<leg>=<anchor>[+…]` instead of `gate-anchored`. Both halves
# are needed: the gate's own mutants (tests.py TestQ937LedgerAnchoredGates) show the anchor counts
# and nothing weaker does; the red ablation shows that moving the marker WITHOUT leaving the anchor
# is caught loudly, so the move cannot narrow the leg silently. A listed leg whose removal changed
# only a count or a note stays `gate-anchored`: that is the silent case this table must not hide.
#   ledger-anchor = a `[CORRECTIONS CX-<n>](…/CORRECTIONS.md)` link in the block (GATE 27) or on the
#                   line (GATE 26) whose CX entry quotes the figure; the header of GATE 27 has the rules.
#   allowlist-row = GATE 3b: the marker QUOTES the retracted figure, and a DOC_GATE_FIGURE_ALLOWLIST.txt
#                   row exempts that quote. Moving the marker takes the figure with it; what was left
#                   behind was the row, which printed a [note] and passed. A row that matches nothing
#                   now FAILS (Q-937), so the move must delete it in the same change.
#   ruling-token  = GATE 18: the gate accepts the rule's own pointer token on the line (a pointer to
#                   the ruling, e.g. the METHODS §"Legacy shorthand" note) or a registry allow/open
#                   row, and fails a row that matches nothing; neither is marker text. No gate change.
#                   GATE 4b: the same for DOC_GATE_SECREF_ALLOWLIST.txt, whose rows already fail when stale:
#                   the marker quotes a retired section pointer, and a row exempts that quote.
REANCHORED = {'GATE 26': 'ledger-anchor', 'GATE 27': 'ledger-anchor',
              'GATE 3b': 'allowlist-row', 'GATE 4b': 'allowlist-row', 'GATE 18': 'ruling-token'}
# STAYS3 — a class-3 marker that cannot be freed, keyed (file, line_sha) -> (legs as the TSV prints
# them, review). Applied only while the row's measured legs are exactly those: a new leg on the same
# marker brings `gate-anchored` back.
STAYS3 = {
    # GATE 66 holds TRIGRAM_STRUCTURE.md's fenced attribution ledger byte-identical to the header of
    # lean/TrigramTheorems.lean, and these two markers are inside that fence: they are the Lean
    # header's own text. They can move only together with an edit to the Lean file (Lean work is
    # routed separately), so they stay with the verbatim copy.
    ('documentation/TRIGRAM_STRUCTURE.md', '5edd45dc0476'):
        ('GATE 66', 'stays:verbatim-copy-of-the-lean/TrigramTheorems.lean-header;moves-only-with-the-Lean-file'),
    ('documentation/TRIGRAM_STRUCTURE.md', '58a1c902d08a'):
        ('GATE 66', 'stays:verbatim-copy-of-the-lean/TrigramTheorems.lean-header;moves-only-with-the-Lean-file'),
}

def attribute(base, abl):
    from collections import Counter
    rows = inventory()
    bl = Counter(l for (_, l) in sections(base))
    by = {}
    for r in rows: by.setdefault(r['file'], []).append(r)
    blk = {}; src = {}
    changed = {}; attributed = {}; anyedit = set(); pop = set()
    def resolve(f):
        if f in by: return f
        g = [k for k in by if k.endswith('/' + f)]
        return g[0] if len(g) == 1 else None
    def load(f):
        if f not in src:
            src[f] = open(f, encoding='utf-8').read().split('\n'); blk[f] = blocks(src[f])
    linehit = set(); deferred = []
    def tag(r, leg, sec, line=''):
        r.setdefault('legs', set()).add(leg); attributed[sec] = 1
        if '[FAIL]' in line: r.setdefault('red', set()).add(leg)
        if not leg.endswith('(file)'): linehit.add((sec, r['file']))
    for (sec, l) in sections(abl):
        if bl[l] > 0: bl[l] -= 1; continue
        leg = sec.strip('= ').split(':')[0]
        if leg in ANY_EDIT: anyedit.add(sec); continue
        changed[sec] = changed.get(sec, 0) + 1
        cites = [(f, n) for (f, n) in CITE.findall(l)] + [(f, n) for (n, f) in CITE2.findall(l)]
        hit = False
        for (f, n) in cites:
            f = resolve(f)
            if f is None: continue
            n = int(n); load(f); hit = True
            lo, hi = blk[f].get(n, (n, n))
            for r in by[f]:
                if r['kind'] not in ('marker', 'narration'): continue
                if r['line'] <= n <= r['end'] or (lo <= r['line'] <= hi) or (r['line'] <= hi and r['end'] >= lo):
                    tag(r, leg, sec, l)
        if hit: continue
        # the citation gate's pin form `CITING.md->TARGET[key]`: the CITING line's text changed, so
        # the marker in CITING whose block holds `key` is the one the pin rests on.
        for (f, key) in ARROW.findall(l):
            f = resolve(f)
            if f is None: continue
            load(f); hit = True
            ms = [r for r in by[f] if r['kind'] in ('marker', 'narration')]
            near = [r for r in ms if key in '\n'.join(src[f][blk[f].get(r['line'], (r['line'], r['end']))[0]-1:max(blk[f].get(r['line'], (0, r['end']))[1], r['end'])])]
            for r in (near or ms): tag(r, leg if near else leg + '(file)', sec, l)
        if hit: continue
        # a COUNT line ([ok]/[info]/[cite]/[measured]/scanned …) naming no finding: the gate's
        # population moved. Recorded per section (and file, when one is named), not per marker.
        if not re.search(r'\[(FAIL|note|WARN|NEW|REPIN|inhunk)\]', l):
            for f in (set(MDPATH.findall(l)) or {'-'}):
                pop.add((sec, resolve(f) or '-'))
            continue
        # a FINDING with no line cited: file-level (an allowlist anchor that matched nothing, a
        # digest, a sum over a file). Narrowed by any quoted anchor the line carries; else the file.
        deferred.append((sec, leg, l))
    # second pass, so a file-level finding can see the line-level ones of its own section: a finding
    # that names a file the same section already tied to a marker by line (the citation gate's
    # `[inhunk]`/`[REPIN]` lines, then its `leg A2` summary naming the same pair) is explained by
    # them, and is not spread over every other marker in that file.
    for (sec, leg, l) in deferred:
        # GATE 4b's stale-row form `SRC.md -> TGT.md §"key"` (Q-937): the row exempted a reference
        # written in SRC, so the marker it rests on is the one in SRC whose block names TGT's file
        # and the key as a word (case folded, as GATE 4b folds it). Without this the finding named two
        # files and quoted nothing six characters long, and was spread over every marker in both
        # (23 rows, one real).
        near = []
        for (a, t, k) in SECREF.findall(l):
            a = resolve(a)
            if a is None: continue
            load(a)
            for r in by[a]:
                if r['kind'] not in ('marker', 'narration'): continue
                lo, hi = blk[a].get(r['line'], (r['line'], r['end']))
                bt = '\n'.join(src[a][lo-1:max(hi, r['end'])]).lower()
                if os.path.basename(t).lower() in bt and re.search(r'(?<!\w)%s(?!\w)' % re.escape(k.lower()), bt): near.append(r)
        if near:
            for r in near: tag(r, leg, sec, l)
            continue
        for f in set(MDPATH.findall(l)):
            f = resolve(f)
            if f is None or (sec, f) in linehit: continue
            load(f)
            ms = [r for r in by[f] if r['kind'] in ('marker', 'narration')]
            qs = QUOTE.findall(l)
            near = []
            for r in ms:
                lo, hi = blk[f].get(r['line'], (r['line'], r['end']))
                t = '\n'.join(src[f][lo-1:max(hi, r['end'])])
                if any(q in t for q in qs): near.append(r)
            for r in (near or ms): tag(r, leg if near else leg + '(file)', sec, l)
    # third pass (Q-936 (a)): a finding no line or file could tie, named by the one-file ablation.
    legs_changed = {sec.strip('= ').split(':')[0]: sec for sec in changed}
    seen_solo = set()
    for r in rows:
        k = (r['file'], r['sha'])
        if k not in SOLO_ANCHORED or r['kind'] not in ('marker', 'narration'): continue
        seen_solo.add(k)
        leg, why = SOLO_ANCHORED[k]
        if leg not in legs_changed:
            print('SOLO_ANCHORED key: %s %s — %s did not change in this run (re-measure it)' % (k + (leg,)), file=sys.stderr); continue
        r.setdefault('legs', set()).add(leg + '(solo)'); r['solo'] = why; attributed[legs_changed[leg]] = 1
    for k in sorted(set(SOLO_ANCHORED) - seen_solo):
        print('SOLO_ANCHORED key matches no marker line (re-read it): %s %s' % k, file=sys.stderr)
    unattr = sorted(s for s in changed if s not in attributed)
    pop |= {(s, '-') for s in unattr if not any(p[0] == s for p in pop)}
    return rows, unattr, sorted(anyedit), sorted(pop)

def pop_rows(pop):
    """(table lines, unattributed pairs, stale pop keys) for the population pairs of a run. A pair
    whose (file, 'pop:' + leg) key is in REVIEWED takes that verdict; any other pair stays `3?
    count-changed` and is UNATTRIBUTED, which keeps the verdict INCOMPLETE."""
    out, unattr, used = [], [], set()
    for (s, f) in pop:
        leg = s.strip('= ').split(':')[0]
        k = (f, 'pop:' + leg)
        if k in REVIEWED: cls, rev = REVIEWED[k]; used.add(k)
        else: cls, rev = '3?', 'count-changed'; unattr.append((s, f))
        out.append('\t'.join([f, '-', 'population', '-', cls, leg, rev, '-']))
    stale = sorted(k for k in REVIEWED if k[1].startswith('pop:') and k not in used)
    return out, unattr, stale

def emit(rows, measured):
    print('\t'.join(['file', 'line', 'kind', 'token', 'class', 'legs', 'review', 'line_sha']))
    used = set(); used3 = set()
    for r in sorted(rows, key=lambda r: (r['file'], r['line'], r['kind'], r['token'])):
        legs = ','.join(sorted(r.get('legs', ())))
        k = (r['file'], r['sha'])
        if r['kind'] == 'ledger-link': cls, rev = 'n/a', 'not-a-marker'
        elif r['kind'] == 'changelog': cls, rev = 'keep', 'revision-row'
        elif not measured: cls, rev = '-', 'not-measured'
        elif legs and STAYS3.get(k, ('',))[0] == legs: cls, rev = '3', STAYS3[k][1]; used3.add(k)
        elif legs and all(x in REANCHORED and x in r.get('red', ()) for x in r['legs']):
            cls, rev = '3', 'reanchored:' + '+'.join('%s=%s' % (x.replace(' ', '-'), REANCHORED[x]) for x in sorted(r['legs']))
        elif legs: cls, rev = '3', 'gate-anchored' + (';' + r['solo'] if r.get('solo') else '')
        elif k in REVIEWED: cls, rev = REVIEWED[k]; used.add(k)
        else: cls, rev = '1|2', 'unreviewed'
        if r['kind'] == 'marker' and not r['closed']: rev += ';span-unclosed'
        print('\t'.join([r['file'], str(r['line']), r['kind'], r['token'], cls, legs or '-', rev, r['sha']]))
    for k in sorted(k for k in set(REVIEWED) - used if not k[1].startswith('pop:')):
        print('REVIEWED key matches no unanchored marker line (re-read it): %s %s' % k, file=sys.stderr)
    for k in sorted(set(STAYS3) - used3):
        if measured: print('STAYS3 key matches no class-3 row with those legs (re-read it): %s %s' % k, file=sys.stderr)

mode = sys.argv[1]
if mode == 'list':
    emit(inventory(), False)
elif mode == 'ablate':
    os.chdir(sys.argv[2]); print(ablate('.'))
elif mode == 'attribute':
    rows, unattr, anyedit, pop = attribute(sys.argv[2], sys.argv[3])
    g27 = sum(1 for r in rows if any(x.startswith('GATE 27') for x in r.get('legs', ())))
    emit(rows, True)
    # a changed gate section no marker line could be tied to: the gate's POPULATION moved (a count
    # it prints fell or rose). It is a row of the table, class `3?`, so it cannot be overlooked.
    # a reviewed pair (REVIEWED key (file, 'pop:' + leg), Q-936 (a)) carries its verdict and is not
    # UNATTRIBUTED; a stale key is reported, never silently applied.
    lines, unattr_pop, stale = pop_rows(pop)
    for l in lines: print(l)
    for s in anyedit:
        print('\t'.join(['-', '-', 'any-edit', '-', 'n/a', s.strip('= ').split(':')[0], 'fires-on-any-edit', '-']))
    for k in stale: print('REVIEWED population key matches no population row (re-measure it): %s %s' % k, file=sys.stderr)
    for (s, f) in unattr_pop: print('UNATTRIBUTED\t%s\t%s' % (s, f), file=sys.stderr)
    print('G27=%d UNATTR=%d POP=%d MARKERS=%d' % (g27, len(unattr_pop), len(pop), sum(1 for r in rows if r['kind'] in ('marker', 'narration'))), file=sys.stderr)
elif mode == 'selftest':
    ok = True
    def chk(name, got, want):
        global ok
        print(('  [ok]   ' if got == want else '  [FAIL] ') + name + ' -> %r' % (got,) + ('' if got == want else ' want %r' % (want,)))
        ok = ok and got == want
    t = 'A claim. ⚠ **[CORRECTED 2026-09-01 — this read "x [n]" before.]** More.\n'
    s = list(spans(t))
    chk('marker span covers decoration and nested brackets', t[s[0][0]:s[0][1]], '⚠ **[CORRECTED 2026-09-01 — this read "x [n]" before.]**')
    t = 'See [CORRECTIONS.md](CORRECTIONS.md), [CORRECTIONS CX-25](x/CORRECTIONS.md), [RETRACTED_PHRASES.tsv](R.tsv).\n'
    chk('ledger/registry links are not markers', [x[2] for x in spans(t)], ['ledger-link'] * 3)
    t = '| v1.2 | 2026-09-01 | [CORRECTED x] |\n'
    chk('a revision row is changelog', [x[2] for x in spans(t)], ['changelog'])
    t = 'Para ⚠ **[WITHDRAWN 2026-08-24 — no close\n\nNext para.\n'
    s = list(spans(t))
    chk('an unclosed span stops at the paragraph', (t[s[0][0]:s[0][1]].count('Next'), s[0][4]), (0, False))
    # the parenthesised form (Q-935): seen, with its decoration, nested parentheses and a wrapped date
    t = 'x. ⚠ *(Corrected 2026-09-01, Q-1: this read "a (b)" before.)* y\n'
    s = list(spans(t))
    chk('parenthesised marker: kind, Title-case token, span with decoration and nesting',
        [(x[2], x[3], t[x[0]:x[1]]) for x in s], [('marker', 'Corrected', '⚠ *(Corrected 2026-09-01, Q-1: this read "a (b)" before.)*')])
    t = 'a *(corrected — an earlier line said z)* b (Superseded\n2026-08-03: wrapped) c (WITHDRAWN 2026-08-24, CX-26) d\n'
    chk('parenthesised marker: dash form, date after a line break, any case',
        [(x[2], x[3], x[4]) for x in spans(t)], [('marker', 'Corrected', True), ('marker', 'Superseded', True), ('marker', 'Withdrawn', True)])
    t = '**Result (corrected 2026-08-01):** text\n'
    chk('parenthesised marker inside bold: the bold is not swallowed', [t[x[0]:x[1]] for x in spans(t)], ['(corrected 2026-08-01)'])
    t = ('The value (corrected for drift) was used; the (correction 4) label; see §6 (retracted) and the\n'
         'caption (withdrawn) and (superseded by the exact count); a (corrected\n\n2026-09-01) across a blank line.\n')
    chk('precondition: the prose carries the word after an opening parenthesis', len(re.findall(r'\((?:corrected|correction|retracted|withdrawn|superseded)', t)), 6)
    chk('prose that merely contains "(corrected" etc. is not a marker', list(spans(t)), [])
    t = 'Bracket ⚠ **[CORRECTED 2026-09-01 — x]** and paren *(Corrected 2026-09-01: y)* on one line.\n'
    chk('both forms on one line are both seen', [(x[2], x[3]) for x in spans(t)], [('marker', 'CORRECTED'), ('marker', 'Corrected')])
    lines, ua, _ = pop_rows([('== GATE 2: CLI flags ==', 'documentation/VERIFY.md'), ('== GATE 999: none ==', '-')])
    chk('a reviewed population pair takes its verdict; an unreviewed one stays UNATTRIBUTED',
        ([l.split('\t')[4] for l in lines], ua), (['n/a', '3?'], [('== GATE 999: none ==', '-')]))
    t = 'one ⚠ **[CORRECTED 2026 — a\nb]** two\nthe text now reads y\n'
    import tempfile
    d = tempfile.mkdtemp(); os.chdir(d)
    subprocess.run(['git', 'init', '-q'], check=True)
    t += 'three *(Corrected 2026-09-02: z)* four\n'
    open('A.md', 'w').write(t); open('HISTORY.md', 'w').write(t)
    subprocess.run(['git', 'add', 'A.md', 'HISTORY.md'], check=True)
    chk('inventory lines: marker on its token line, narration', [(r['line'], r['end'], r['kind']) for r in inventory()], [(1, 2, 'marker'), (3, 3, 'narration'), (4, 4, 'marker')])
    ablate('.')
    chk('ablation keeps every newline and deletes span + phrase', open('A.md').read(), 'one \n two\nthe text  y\nthree  four\n')
    chk('HISTORY.md is never ablated', open('HISTORY.md').read(), t)
    print('CORRECTION_MARKER_INVENTORY_SELFTEST=' + ('PASS' if ok else 'FAIL'))
PY
}

case "$MODE" in
  --selftest) core selftest; exit $? ;;
  --list)     core list; exit $? ;;
  --attribute) core attribute "$2" "$3"; exit $? ;;   # re-attribute two kept gate logs (CMI_KEEP_LOGS)
  write|--stdout) ;;
  *) echo "usage: $0 [--stdout|--list|--selftest]" >&2; exit 2 ;;
esac

W=$(mktemp -d) || { echo "CORRECTION_MARKER_INVENTORY=ERROR mktemp" >&2; exit 2; }
trap 'rm -rf "$W"' EXIT
# Two identical copies of the working tree (tracked + untracked-but-not-ignored, with .git so the
# gates that read HEAD see the same HEAD), so the only difference between the two runs is the ablation.
for c in base abl; do
  mkdir -p "$W/$c" && cp -a .git "$W/$c/.git" \
    && git ls-files -z --cached --others --exclude-standard | (cd . && xargs -0 cp --parents -a -t "$W/$c" 2>/dev/null) \
    || { echo "CORRECTION_MARKER_INVENTORY=ERROR copy-failed $c" >&2; exit 2; }
done
N=$(core ablate "$W/abl") || { echo "CORRECTION_MARKER_INVENTORY=ERROR ablate-failed" >&2; exit 2; }
[ "${N:-0}" -gt 0 ] || { echo "CORRECTION_MARKER_INVENTORY=ERROR no-markers-ablated" >&2; exit 2; }
for c in base abl; do
  ( cd "$W/$c" && { bash scripts/doc_gates.sh; echo '== CITATION LINE GATE =='; bash scripts/citation_line_gate.sh --all-files --all-targets; } > "$W/$c.log" 2>&1 ) &
done
wait
for c in base abl; do
  grep -q '^== GATE 1:' "$W/$c.log" || { echo "CORRECTION_MARKER_INVENTORY=ERROR gate-run-empty $c" >&2; exit 2; }
done
core attribute "$W/base.log" "$W/abl.log" > "$W/out.tsv" 2> "$W/err" || { cat "$W/err" >&2; echo "CORRECTION_MARKER_INVENTORY=ERROR attribute-failed" >&2; exit 2; }
cat "$W/err" >&2
[ -n "${CMI_KEEP_LOGS:-}" ] && cp "$W/base.log" "$W/abl.log" "$CMI_KEEP_LOGS/"   # debugging aid: keep both gate logs
G27=$(sed -n 's/^G27=\([0-9]*\) .*/\1/p' "$W/err")
if [ "${G27:-0}" -eq 0 ]; then
  echo "CORRECTION_MARKER_INVENTORY=ERROR positive-control: no GATE 27 attribution, the ablation saw nothing" >&2; exit 2
fi
if [ "$MODE" = --stdout ]; then cat "$W/out.tsv"; else cp "$W/out.tsv" "$OUT"; echo "-> $OUT ($(($(wc -l < "$OUT") - 1)) rows)" >&2; fi
if grep -q '^UNATTRIBUTED' "$W/err"; then
  echo "CORRECTION_MARKER_INVENTORY=INCOMPLETE" >&2
else
  echo "CORRECTION_MARKER_INVENTORY=COMPLETE" >&2
fi
