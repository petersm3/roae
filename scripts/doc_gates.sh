#!/usr/bin/env bash
# doc_gates.sh — mechanical documentation-integrity gates.
#
# WHY THIS EXISTS
#   The code layer has hard gates (canonical sha, compile gate, tests.py, DRAT certs).
#   The DOC layer had none, so doc-level defects depended on review luck. On 2026-08-01
#   two full adversarial AI review passes cleared the repo and a third found ~20 real
#   defects — including a retracted claim still stated on the README front page, hidden
#   because a revision entry *asserted* the correction had propagated. These gates turn
#   that class of failure from "hope a reviewer notices" into "the script fails".
#
# USAGE
#   scripts/doc_gates.sh numbers    # cross-file numeric consistency (long integers)
#   scripts/doc_gates.sh cli        # CLI flags live in code but absent from the CLI docs
#   scripts/doc_gates.sh retract    # GATE 3: retracted phrasings that still survive in the corpus
#   scripts/doc_gates.sh retract-figures  # GATE 3b: retracted FIGURES (statistics) restated with no
#                                   # supersession marker; content-anchored allowlist, no auto-exemption
#   scripts/doc_gates.sh links      # GATE 4 + 4b: internal markdown links/#anchors, then section refs
#   scripts/doc_gates.sh links-internal   # GATE 4 ALONE — internal links/#anchors (self-test target)
#   scripts/doc_gates.sh secrefs    # GATE 4b ALONE — plain-text `FILE.md §"..."` references (self-test target)
#   scripts/doc_gates.sh status     # GATE 5: canonical quantities whose exact/estimate status
#                                   # drifted, + GATE 5b: a canonical quantity restated with NO
#                                   # marker among siblings that carry one
#   scripts/doc_gates.sh figures    # retracted phrasing in figure GENERATORS (rendered text is ungreppable)
#   scripts/doc_gates.sh liveness   # frozen present-tense run status; runs named after unreached budgets
#   scripts/doc_gates.sh banner     # the TR banner is byte-identical across every report + index-aligned
#   scripts/doc_gates.sh appendonly # GATE 10a + 10b: CORRECTIONS.md has lost no committed line
#   scripts/doc_gates.sh appendonly-head    # GATE 10a ALONE — vs HEAD (self-test target)
#   scripts/doc_gates.sh appendonly-history # GATE 10b ALONE — vs every historical/published
#                                   # version, not just HEAD (self-test target)
#   scripts/doc_gates.sh ledger     # every RETRACTED_PHRASES.tsv row, and every
#                                   # RETRACTED_FIGURES.tsv row, is recorded in CORRECTIONS.md
#   scripts/doc_gates.sh ledger-figures  # GATE 11's FIGURES pass ALONE (self-test target)
#   scripts/doc_gates.sh ledger-phrases  # GATE 11's PHRASES pass ALONE (self-test target)
#   scripts/doc_gates.sh revrows    # GATE 13: a TR body edit carries a revision row (REPORT-ONLY)
#   scripts/doc_gates.sh revhist    # GATE 12: TR revision tables — one *(current)* and last, no repeated
#                                   # released version, dates and versions ascending
#   scripts/doc_gates.sh regdupes   # GATE 14: two literature-registry rules that are the same predicate
#   scripts/doc_gates.sh instruments # GATE 15: a --selftest instrument with no declared fire-proof,
#                                   # and (LEG 2) a fire-proof its own source text could satisfy
#   scripts/doc_gates.sh collisions # GATE 16: a per-gate assertion a PREFLIGHT could satisfy,
#                                   # and (LEG 2) a fire-proof naming a dispatch that runs
#                                   # more than one gate
#   scripts/doc_gates.sh generated  # generated artifacts still match their generator (~135s, 3 runs; NOT in `all`)
#   scripts/doc_gates.sh all        # run all fifteen cheap gates (1-7 incl. 3b, 9, 10, 11, 12, 13, 14, 15, 16); `generated` is separate by cost
#   scripts/doc_gates.sh --selftest # mutation-test the gates themselves (requires a clean tree)
#
# EXIT: 0 = clean, 1 = findings. Report-only classes print [WARN]; hard failures print [FAIL].
# GATES 1 and 5 are REPORT-ONLY by construction — they always `return 0` / `sys.exit(0)`, so their
# findings never reach RC and are NOT covered by the "DOC GATES: PASS" banner. The banner says so.
#
# SAFETY: index-based (`git ls-files`/`git grep`) and fixed-string matching only.
#   No `find` over trees, no bounded-repetition regex (`.{0,N}`) — a pathological
#   `grep -oE ".{0,80}X.{0,60}"` hung the 2-core orchestrator on a 381-byte input
#   (2026-08-01); cost lives in the PATTERN, not only the data.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
RC=0

# example/ was excluded here until 2026-08-01. That is a CONTAINER-level exemption — the same
# construction that let the retracted "hard floor k >= 13" survive in TR-4's body while its
# changelog narrated the retraction. Exempt a construction, never a directory.
DOCS=$(git ls-files '*.md' || true)

# ----------------------------------------------------------------------------------
# ITEM A1 (2026-08-02) — WHAT EVERY GATE DOES WITH A MISSING INPUT.
#
# GATE 8's five legs used to `[skip]` a deleted git-tracked artifact, so `rm example/report.pdf`
# passed in silence. That was fixed and proven on 2026-08-02; the same question was then asked
# of GATES 2, 3, 3b, 6, 10a, 10b and 11, and every one of them had the same shape. MEASURED,
# not reasoned: with `documentation/CORRECTIONS.md` deleted from the working tree,
#   scripts/doc_gates.sh retract  ->  "DOC GATES: PASS (retract)", rc 0
#   scripts/doc_gates.sh ledger   ->  "[skip] ... absent" then "DOC GATES: PASS", rc 0
# GATE 3's only trace was a bash redirect error on stderr (line 145), and the self-test harness
# runs each gate with `2>&1 >/dev/null` — so that trace is invisible to the one instrument that
# would have caught it.
#
# TWO SEPARATE HOLES, and the second is the one that matters:
#   (a) PER-GATE. Each gate that opens a named registry or ledger skipped on `! -f`.
#       `require_tracked` below turns that into a FAIL when git tracks the path.
#   (b) CORPUS-WIDE, and INVISIBLE. `$DOCS` is `git ls-files '*.md'` — an INDEX listing. A
#       tracked .md deleted from the working tree stays in `$DOCS`, and every consumer
#       (GATES 3, 3b, 4, 4b, 5, 5b, 9) then reads it as EMPTY and reports [ok] on it. One
#       deletion blinds seven gates at once, which is why this is the corpus-level preflight
#       below rather than seven more `[ -f ]` tests.
#
# WHAT THIS STILL CANNOT SEE, stated rather than implied: absence of a TOOL. `pdftotext`
# absence remains a `[skip]` (poppler is not part of the toolchain this repo requires);
# `python3` and `sha256sum` absence are now FAILs because each voids a whole gate, but neither
# carries a mutation fire-proof — hiding one tool from `$PATH` without also hiding `git`,
# `grep` and `cut` cannot be done cleanly, so those two legs are asserted by reading, not by
# running. That is a weaker warrant than every other leg here and is recorded as such.
#
# require_tracked <path> [remedy-line]
#   rc 0 = present; rc 1 = absent and NOT tracked (a legitimate skip, printed); rc 2 = tracked
#   but absent (a FAIL, printed). Callers must map rc 2 onto their own failure variable.
require_tracked() {
  [ -f "$1" ] && return 0
  if git ls-files --error-unmatch -- "$1" >/dev/null 2>&1; then
    echo "  [FAIL] $1 is tracked in git but missing from the working tree"
    echo "         ${2:-A gate whose input is absent has checked nothing. Absence of a tracked input is the strongest possible mismatch, not a reason to skip.}"
    return 2
  fi
  echo "  [skip] $1 absent (not tracked, so nothing shipped is being checked)"
  return 1
}

# require_final_newline <path>
#   Every registry in this suite is consumed by `while read`, and `read` returns non-zero on
#   a final line with no terminator — so the shell loop DROPS it. A registered retraction or
#   figure appended without a trailing newline would silently stop being checked, and the
#   gate would print [ok] with a smaller count than the file has rows. Nobody reads the
#   count. MEASURED 2026-08-02: all three registries currently end in \n, so this guard is a
#   tripwire on a hazard that has not fired yet, not a fix for a live defect.
#   rc 0 = terminated; rc 1 = not (printed as a FAIL by the caller's rc mapping).
#
#   SECOND ARGUMENT `quiet` (item A6, 2026-08-02) suppresses the message so a caller can
#   print its own. It exists for exactly one reason and the reason is load-bearing: the
#   A6 preflight below checks every support file, INCLUDING the two registries GATE 11
#   checks itself, and GATE 11's fire-proof asserts on the literal string
#   "RETRACTED_FIGURES.tsv does not end with a newline". If the preflight printed that same
#   sentence, the assertion would be satisfied by the preflight and would no longer prove
#   GATE 11's leg fired at all — the shared-dispatch defect that item A3 fixed for GATE 4b
#   and item A7 for GATE 10a, reintroduced through a shared MESSAGE instead of a shared exit
#   code. The preflight's wording ("gate-support file has no final newline: <f>") therefore
#   shares no substring with this one.
require_final_newline() {
  [ -f "$1" ] || return 0                     # absence is require_tracked's business
  [ -s "$1" ] || return 0
  if [ "$(tail -c1 "$1" | od -An -c | tr -d ' \n')" = '\n' ]; then
    return 0
  fi
  [ "${2:-}" = quiet ] && return 1
  echo "  [FAIL] $1 does not end with a newline"
  echo "         Its last row is dropped by every \`while read\` that consumes it, so that"
  echo "         row is registered and unchecked. Append a newline."
  return 1
}

# ITEM A6 (2026-08-02) — THE SILENT-DROP GUARD, APPLIED TO EVERY SUPPORT FILE AT ONCE.
#
# require_final_newline was added for three registries one at a time. The item that raised it
# asked for one mechanical pass instead, and named six more files said to share "the same
# reader shape". THE PREMISE IS WRONG FOR ALL SIX, and that is worth recording rather than
# quietly acting on, because acting on it would have shipped six guards against a hazard
# those files do not have — and a guard whose motivating example is imaginary is the shape
# this suite keeps catching elsewhere. MEASURED, each at its consumption site:
#   (Each row names its READER, not a line number. All five carried line numbers until
#   2026-08-02 and ALL FIVE had drifted — by 82, 115, 140, 234 and 234 lines — in a block
#   whose own first sentence says "MEASURED, each at its consumption site". Nothing reads a
#   comment, so the pointers rotted silently while the measurement they cite stayed true.
#   Round 8, drain-3, found while re-checking two line citations of its own that were stale
#   within the hour. Names do not drift; that is the whole reason for the change.)
#   DOC_GATE_FIGURE_ALLOWLIST.txt   gate_retract_figures, `ALLOW =` — python `for ln in open(...)`
#   DOC_GATE_SECREF_ALLOWLIST.txt   gate_secrefs, `ALLOW  =`        — python `for ln in open(...)`
#   DOC_GATE_STATUS_ALLOWLIST.txt   gate_status, `allow =`          — python `for l in open(...)`
#   DOC_GATE_UNMARKED_ALLOWLIST.txt gate_status, `alw5b =` (5b)     — python `for l in open(...)`
#   DOC_GATE_NUMBER_ALLOWLIST.txt   gate_numbers, `allow=`          — `grep -qxF -- "$key" "$allow"`
#   CORRECTIONS_INVENTORY.tsv       no consumer in this suite at all; it is WRITTEN by
#                                   scripts/corrections_inventory.sh, and the only documented
#                                   reader is the `awk` recipe at CORRECTIONS.md:52
# Python file iteration, grep and awk all yield an unterminated final line. `while read` is
# the one reader that drops it, and today it is used on exactly the three files already
# guarded. So SIX guards would have been six no-ops.
#
# WHAT IS SHIPPED INSTEAD, and why it is not the same no-op: the guard is applied to every
# support file by CONSTRUCTION rather than to a hand-listed six, because the hazard is not a
# property of the file — it is a property of whichever reader a future gate happens to use.
# The next gate to consume an allowlist with `while read` inherits the protection instead of
# rediscovering the defect. The list is a `git ls-files` glob, so a support file added
# tomorrow is covered without anyone remembering this note.
#
# WHAT IT CANNOT SEE, stated because a clear from a guard I wrote is worth less than a
# failure: it covers documentation/DOC_GATE_*.txt and documentation/*.tsv only — a support
# file placed anywhere else, or given another extension, is outside it. And it addresses ONE
# way a reader silently drops a row; a `while read` without `-r`, or with unset IFS, mangles
# rows it does not drop, and nothing here looks for that.
#
# ITEM A9 — THE OTHER SUPPORT-FILE HAZARD, MEASURED AND DELIBERATELY NOT GATED (2026-08-02).
# A9 asked for an instrument against PROSE COUNTS in support-file headers going stale, after
# DOC_GATE_FIGURE_LEDGER_OPEN.txt shipped saying "the ELEVEN missing ledger entries" over a
# file holding SEVEN rows while its sibling RETRACTED_FIGURES.tsv already said seven
# (corrected at `c737858`). All six DOC_GATE_*.txt files and all four .tsv registries were
# swept for header numbers that are snapshots of a live measurement. FOUR exist:
#   documentation/DOC_GATE_FIGURE_LEDGER_OPEN.txt:20-24  "4 recorded, 7 open ... holds SEVEN
#       rows"  — three coupled counts; correct today (7 rows, 11 registry rows verified)
#   documentation/DOC_GATE_UNMARKED_ALLOWLIST.txt:21     "64 of 127 ... and 0 of those"
#   documentation/DOC_GATE_FIGURE_ALLOWLIST.txt:27       "There are none today."
#   documentation/RETRACTED_FIGURES.tsv:26-27            '"+1.6" matches twelve places'
# Of the four, exactly ONE restates a number a gate recomputes on every run. The other three
# are one-off corpus measurements that nothing recalculates, so a "does the stated count
# match the computed one" gate has a live corpus of one — and would have to find its number
# by regex over free prose that also contains dates, gate numbers, version strings, line
# numbers and ratios. That is the shape drain-1 measured and rejected for GATE 4b's coverage
# floor on the same day: an instrument whose false-positive rate exceeds its yield.
# NOT SHIPPED, therefore, and the choice among (i) a computed-vs-stated [note], (ii) a
# convention that support-file counts are written "as of <date>", and (iii) nothing, on the
# grounds that headers are commentary, is left open with this measurement attached to it.
# The four sites above are the whole surface; anyone taking the decision does not have to
# re-derive it.
#
# ITEM N1 — CITATION-BY-LINE: ALL THREE FORMS NOW COUNTED, AND ONLY TWO ARE GATEABLE
# (2026-08-02, unit drain-1). Round 9 adjudicated `name.ext:N` — 72 citations, 4 stale. It
# recorded that two other forms had been SAMPLED, not counted. Both are counted now, over
# `git ls-files`. THE POPULATIONS BELOW ARE AS OF THAT CENSUS AND WILL NOT RE-MEASURE TO
# THE SAME NUMBERS: this batch's four fixes removed four form-3 occurrences after it was
# taken, and prose ABOUT a citation form is itself an instance of it — the two "lines 2-4"
# examples further down are two more. Re-run the census; do not reconcile against these.
#   FORM 2, bare `:NNN` — 15 lines. 7 in this file (GATE 5's "WHY the anchor is now the
#     PRIMARY key" block, its item-A8 fire-proof header, and its drift-immunity [ok]
#     message), 3 in DOC_GATE_STATUS_ALLOWLIST.txt, 2 in CORRECTIONS_INVENTORY.tsv: every
#     one NARRATES a past anchor drift or a synthetic move, so round 9's "all narrative"
#     verdict holds on the population and not only on its sample. 2 are numpy slices in
#     solve.py and viz/visualize.py. The ONE live pointer — the "Checked and needing
#     nothing" bullet in CORRECTIONS.md, chaining three notes in DESCRIPTION_LENGTH.md,
#     resolves — as does the alias sub-form `TR-n:NNN` (4 sites).
#   FORM 3, `line NNN` — 122 lines / 138 occurrences, and 92 of those lines are the DOMAIN
#     sense: "Line 3" of a hexagram, "lines 2-4" of a nuclear trigram. 2 more describe a
#     file FORMAT or a manifest's data line. Only 28 lines cite anything, 15 of them dated
#     changelog rows. Of the 13 live pointers, FOUR were stale and are fixed at `2f976d3`.
# NOT SHIPPED, and this one is not a close call: no mechanical test separates "lines 2-4 of
# a hexagram" from "lines 2-4 of a file", so a form-3 gate is ~75% false positives — which
# is how a real hit later gets ignored. The gateable forms are `name.ext:N` and `TR-n:NNN`,
# both already resolvable. THE CONVENTION IS THE FIX: cite the SYMBOL and it cannot drift.
# solve.c is excluded by the sha anchor, not by policy — it carries 5 live self-pointers
# and all 5 are stale; they belong to the solve.c correction batch, not to a gate.
# The first draft of THIS BLOCK cited three of its own form-2 sites by line, and inserting
# the block moved all three by 22 — the census demonstrated on the census, caught by the
# Phase-4 pass and not by any gate. That is the argument for the convention, in one line.
preflight_support_newlines() {
  local f bad=0
  for f in $(git ls-files 'documentation/DOC_GATE_*.txt' 'documentation/*.tsv' 2>/dev/null); do
    require_final_newline "$f" quiet && continue
    if [ "$bad" -eq 0 ]; then
      echo "== PREFLIGHT: every gate-support file must end with a newline =="
    fi
    echo "  [FAIL] gate-support file has no final newline: $f"
    bad=1
  done
  if [ "$bad" -ne 0 ]; then
    echo "         A gate-support file's last row is invisible to any \`while read\` consumer,"
    echo "         and the gate would still print [ok] with a count nobody reads."
    echo
    return 1
  fi
  return 0
}

# Corpus preflight — hole (b). Runs before every mode (see the dispatch at the foot of the
# file) and DOES NOT short-circuit: it sets RC and lets the gates run anyway, so a per-gate
# fire-proof can still tell its own leg's message from this one. The two messages are
# deliberately worded differently for exactly that reason.
preflight_tracked_docs() {
  local f missing=0
  for f in $DOCS; do
    [ -f "$f" ] && continue
    if [ "$missing" -eq 0 ]; then
      echo "== PREFLIGHT: every tracked .md must exist in the working tree =="
    fi
    echo "  [FAIL] tracked markdown missing from the working tree: $f"
    missing=$((missing+1))
  done
  if [ "$missing" -ne 0 ]; then
    echo "         GATES 3, 3b, 4, 4b, 5, 5b and 9 all iterate this list and would read each"
    echo "         missing file as EMPTY — reporting [ok] on a document they never opened."
    echo "         Restore it (git checkout -- <path>) or remove it from the index."
    echo
    return 1
  fi
  return 0
}

# ----------------------------------------------------------------------------------
gate_numbers() {
  echo "== GATE 1: cross-file numeric consistency (long integers) =="
  # Extract integers of >=12 digits (commas stripped). Group by their first 10 digits.
  # A group holding more than one DISTINCT full value means two docs disagree about
  # what is almost certainly the same quantity (e.g. a single corrupted digit).
  # Key = (length, first 10 digits). SAME LENGTH matters: a corrupted digit preserves
  # length, whereas 10^11 vs 10^12 are simply different budgets, not a disagreement.
  # Round numbers (>=4 trailing zeros) are budgets/powers of ten — skipped.
  # Report-only ([WARN]) with an allowlist, because legitimately-close pairs exist
  # (e.g. a byte count with and without the 32-byte header).
  local tmp allow; tmp=$(mktemp)
  allow="documentation/DOC_GATE_NUMBER_ALLOWLIST.txt"
  for f in $DOCS; do
    grep -oE '[0-9][0-9,]{11,}' "$f" 2>/dev/null | tr -d ',' \
      | awk -v F="$f" 'length($0)>=12 && $0 !~ /0000$/ {print length($0)":"substr($0,1,10)"\t"$0"\t"F}'
  done | sort -u > "$tmp"

  local found=0
  while read -r key; do
    [ -z "$key" ] && continue
    if [ -f "$allow" ] && grep -qxF -- "$key" "$allow" 2>/dev/null; then continue; fi
    echo "  [WARN] near-twin long integers (same length, same 10-digit prefix) — key $key:"
    awk -v K="$key" -F'\t' '$1==K {print "      "$2"   <- "$3}' "$tmp" | sort -u
    found=1
  done < <(cut -f1,2 "$tmp" | sort -u | cut -f1 | uniq -d)

  if [ "$found" -eq 0 ]; then
    echo "  [ok] no long integer disagrees with a same-length near-twin elsewhere"
  else
    echo "  (report-only: confirm each pair is intentional, then add its key to $allow)"
  fi
  rm -f "$tmp"
  return 0   # report-only gate — never blocks
}

# ----------------------------------------------------------------------------------
gate_cli() {
  echo "== GATE 2: CLI flags live in code but undocumented =="
  local bad=0
  check_pair() { # $1=code file  $2=doc file  $3=extractor
    local code="$1" doc="$2" mode="$3" cf df miss rcc=0 rcd=0
    # ITEM A1. Both sides are probed before either verdict, so a run that lost both prints
    # both names; a single `&&` chain would hide the second. A deleted CLI doc used to make
    # this pair vanish from the gate entirely — the flags it documented then went unchecked
    # while the run stayed green.
    require_tracked "$code" "Delete a source file and every flag it declares stops being checked." || rcc=$?
    require_tracked "$doc"  "Delete a CLI doc and its pair stops being checked, silently." || rcd=$?
    if [ "$rcc" -eq 2 ] || [ "$rcd" -eq 2 ]; then bad=1; return 0; fi
    if [ "$rcc" -ne 0 ] || [ "$rcd" -ne 0 ]; then return 0; fi
    cf=$(mktemp); df=$(mktemp)
    # ITEM A4 (2026-08-02) — DECIDED: NARROW, and here is the decision rather than a
    # rediscovery of the question. The extractor is a line-based grep, so a COMMENTED-OUT
    # declaration was emitted as an undocumented flag. MEASURED while writing item A3's
    # fire-proof: run against a comment line it returned `--commented-out-flag`. Nothing had
    # triggered it, so it was a latent false positive, and the round-6 note recorded it as
    # "decide, do not rediscover".
    #
    # WHY NARROW AND NOT ACCEPT. The first person to comment out a flag would have been
    # handed a RED gate with a correct-looking finding and no way to satisfy it except by
    # documenting a flag that does not exist. A gate whose remedy is to write a false
    # sentence into a CLI doc is worse than no gate.
    #
    # THE DIRECTION OF FAILURE IS THE REASON THIS IS SAFE. The comparison is `comm -23`
    # (code minus doc) and nothing else, so dropping lines from the CODE side can only
    # SUPPRESS a finding, never manufacture one. The cost is stated rather than waved away:
    # if a flag is declared on a commented line but still parsed somewhere else, GATE 2 now
    # stops reporting it. That is a real, remote loss, accepted deliberately.
    #
    # WHAT THIS FILTER CANNOT SEE: a flag inside a C block comment (`/* ... */`) spanning
    # lines, a flag in a docstring or other string literal, and a declaration sharing a line
    # with a trailing comment that itself names a second flag. Whole-line `#` and `//`
    # comments are all it removes.
    if [ "$mode" = py ]; then
      grep -vE '^[[:space:]]*(#|//)' "$code" \
        | grep -oE 'add_argument\("--[a-z0-9][a-z0-9_-]*' | sed 's/.*"//' | sort -u > "$cf"
    else
      grep -vE '^[[:space:]]*(#|//)' "$code" \
        | grep -oE '"--[a-z0-9][a-z0-9-]*"' | tr -d '"' | sort -u > "$cf"
    fi
    grep -oE -- '--[a-z0-9][a-z0-9_-]*' "$doc" | sort -u > "$df"
    miss=$(comm -23 "$cf" "$df")
    # THE PASS LINE CARRIES A CENSUS (item B9, round 9, 2026-08-02). It did not, and the
    # consequence was measured rather than supposed: GATE 2's two negative controls could
    # only ever pin `solve.py fully documented`, a sentence that is printed whenever the leg
    # RUNS. No ERE over a countless pass line can tell "the classifier read my injection and
    # correctly ignored it" from "the classifier never looked". Three numbers fix that, and
    # each is chosen so that one of the two controls MOVES it:
    #   flags     — the extracted code-side set. The "flag added to BOTH" control adds one
    #               declaration and one doc line, so this moves; that leg's ERE now pins the
    #               POST-injection value and fails if the file was not re-read.
    #   documented— the doc-side set, which moves with it.
    #   commented — declarations on whole-line comments, which the item-A4 filter DROPS. The
    #               "SAME declaration commented out" control adds exactly one of these, so it
    #               moves this number while leaving the other two fixed. That is the A4
    #               property made visible: the line was seen AND classified as a comment,
    #               which a flags count alone cannot distinguish from never reading it.
    local ncode ndoc ncmt
    ncode=$(wc -l < "$cf"); ndoc=$(wc -l < "$df")
    if [ "$mode" = py ]; then
      ncmt=$(grep -E '^[[:space:]]*(#|//)' "$code" \
             | grep -oE 'add_argument\("--[a-z0-9][a-z0-9_-]*' | sort -u | wc -l)
    else
      ncmt=$(grep -E '^[[:space:]]*(#|//)' "$code" \
             | grep -oE '"--[a-z0-9][a-z0-9-]*"' | sort -u | wc -l)
    fi
    if [ -n "$miss" ]; then
      echo "  [FAIL] in $code but NOT in $doc:"; echo "$miss" | sed 's/^/      /'; bad=1
    else
      echo "  [ok] $code fully documented in $doc ($ncode flag(s) compared against $ndoc" \
           "documented, $ncmt commented-out declaration(s) dropped)"
    fi
    rm -f "$cf" "$df"
  }
  check_pair roae.py  documentation/ROAE_PY_CLI.md  py
  check_pair solve.py documentation/SOLVE_PY_CLI.md py
  check_pair solve.c  documentation/SOLVE_C_CLI.md  c
  # sat.py hand-rolls sys.argv parsing with literal quoted flag strings, so the
  # C-mode extractor applies verbatim (verified 2026-08-01: passes).
  check_pair sat.py   documentation/SAT_CLI.md      c
  return $bad
}

# ----------------------------------------------------------------------------------
gate_retract() {
  echo "== GATE 3: retracted phrasings still surviving =="
  # Registry-driven and deliberately so: auto-parsing retraction prose is unreliable,
  # and a wrong gate is worse than none. Each entry is a FIXED string that was retracted;
  # the gate fails if it appears anywhere outside the file allowed to narrate the retraction.
  #
  # HARDENED 2026-08-01 after this gate missed a LIVE survivor two ways at once
  # (SOLVE_SUMMARY.md still carried the retracted conflict-theorem scope):
  #   (a) line-break evasion — the phrase spanned a hard wrap, so line-based `git grep -F`
  #       could not see it. FIX: whitespace-normalise each file to a single line first.
  #   (b) morphology evasion — the registry held "preserving…" while the survivor said
  #       "preserves…". FIX: register the morphology-independent STEM (and add variants).
  #   (c) allow-column over-reach — matching the allow string anywhere on the line exempted
  #       too much. FIX: the allow column now matches the FILENAME only.
  local reg="documentation/RETRACTED_PHRASES.tsv"
  # ITEM A1: the registry IS this gate. Skipping on its absence reported PASS for a gate
  # that had checked nothing at all.
  require_tracked "$reg" "The retraction registry IS this gate; with it gone, zero phrases are checked."
  case $? in 1) return 0;; 2) return 1;; esac
  local bad=0
  while IFS=$'\t' read -r phrase allow note; do
    case "$phrase" in ''|'#'*) continue;; esac
    local np hits=""
    np=$(printf '%s' "$phrase" | tr '\n' ' ' | tr -s ' ')
    for f in $DOCS; do
      case "$f" in *"$allow"*) continue;; esac          # the doc allowed to narrate it
      # normalise the whole file to one whitespace-collapsed line, then fixed-string match
      if tr '\n' ' ' < "$f" | tr -s ' ' | grep -qF -- "$np"; then
        # changelog rows legitimately quote superseded wording; only exempt if EVERY
        # line-level hit is a revision row.
        # RECORD WHERE, not just WHICH FILE (2026-08-02, #65). A bare filename makes the
        # reader re-run the search by hand to find out what the gate saw; with the registry
        # holding morphology-independent STEMS, the surviving sentence often does not read
        # like the registry row, so "which phrase matched" is a real question. Cite the first
        # line that is NOT a changelog row — the same line the condition below turns on.
        local hitln
        hitln=$(git grep -F -n -- "$np" -- "$f" 2>/dev/null | grep -vE ':[0-9]+:\| v[0-9]' \
                | head -1 | cut -d: -f2)
        if [ -n "$hitln" ]; then
          hits="$hits $f:$hitln"
        elif ! git grep -qF -- "$np" -- "$f" 2>/dev/null; then
          hits="$hits $f(spans-lines)"                  # only visible after normalisation
        fi
      fi
    done
    if [ -n "$hits" ]; then
      echo "  [FAIL] retracted phrasing still present: \"$phrase\""
      echo "         matched as the fixed string: \"$np\"   ($note)"
      for h in $hits; do echo "      $h"; done
      bad=1
    else
      echo "  [ok] retracted: \"$phrase\""
    fi
  done < "$reg"
  return $bad
}

# ----------------------------------------------------------------------------------
# GATE 3b — retracted FIGURES (2026-08-02, item A6). The half of the retraction surface
# GATE 3 and GATE 1 both miss.
#
# WHY. GATE 3 matches retracted PHRASES; GATE 1 only compares integers of >=12 digits.
# A retracted STATISTIC — "1.4σ", "~5,500×", "≈10×", "net +1.6" — is invisible to both.
# That is not hypothetical: the surviving "1.4σ above" in evidence/r11/PHASE2_README.md
# was found by a human reading (TR-2 v1.23), and TR-9's draft-stage note carried two
# figures its own v1.7 had superseded through five subsequent revisions (TR-9 v1.20).
# Both were one-off manual sweeps. This gate is that sweep, permanent.
#
# THE EXEMPTION PROBLEM, and why this gate has NO automatic exemption.
# A retracted figure is quoted MORE after its retraction than before — every revision row,
# every ledger entry, every "this sentence read X until <date>" note must repeat it to
# record what changed. GATE 3 handles that with a filename allow-column plus a changelog-row
# exemption. Neither works here, and the failure is measured, not assumed:
#   * filename is too coarse — the legitimate quotations sit in BODY paragraphs of files
#     (METHODS.md, CORRECTIONS.md, TR-9) that also carry live prose;
#   * a changelog exemption would have HIDDEN this gate's first live finding, TR-2 v1.12's
#     "2.0σ", which sits inside a revision row and had been superseded for a day.
# So every legitimate occurrence is an explicit, CONTENT-ANCHORED allowlist row, in the
# shape GATE 4b uses (A8's lesson: no line numbers — they drift). Anything not allowlisted
# is a [FAIL]. The cost is ~25 curated rows; the benefit is that the exemption mechanism
# cannot silently widen.
#
# WHY-IT-FIRED (#65): every finding prints the matched fixed string, the registry note
# saying what superseded it, and the line text. Every exemption prints its class and reason.
# Allowlist rows that no longer match anything are re-printed as [note] — the drift audit.
# ITEM A2 (2026-08-02) — THE TWO QUESTIONS, for GATE 3b's whitespace normalisation.
#
# The normalisation is `flat = ' '.join(text.split())`, used only for the hard-wrap check.
#
# Q1. WHAT LEGITIMATE VARIATION DOES IT ERASE? The difference between one space and many,
#     and the difference between a space and a newline. That is the point: a figure split
#     across a hard wrap is the same figure. It also erases the difference between a figure
#     written with one internal space and the same figure written with two — which is the
#     residual already recorded below the wrap check, and it over-reports rather than
#     misses.
# Q2. WHAT ILLEGITIMATE VARIATION DOES IT LET THROUGH? Everything that is not whitespace.
#     The matching itself is FIXED-STRING, so `2σ` and `2.00σ` do not match the registered
#     `2.0σ`; that is round-5 item A6, still open, and it is a property of the match rule
#     rather than of this normalisation. Note also that the ALLOWLIST anchor is matched
#     against the raw line and the wrap check against `flat`, so a legitimate occurrence
#     that is itself hard-wrapped cannot be anchored at all — it is reported, which is the
#     safe direction, but it cannot be exempted without rewrapping the source.
gate_retract_figures() {
  echo "== GATE 3b: retracted FIGURES restated without a supersession marker =="
  # ITEM A1, at the bash level so the check uses the git index (python's os.path.exists
  # cannot tell "never existed" from "deleted"). The ALLOWLIST is deliberately NOT guarded
  # here: losing it makes this gate STRICTER, not blinder — every exemption disappears and
  # the gate goes red. That is the fail-safe direction, so it needs no guard.
  require_tracked "documentation/RETRACTED_FIGURES.tsv" \
    "The figure registry IS this gate; with it gone, zero statistics are checked."
  case $? in 1) return 0;; 2) return 1;; esac
  python3 - <<'PY'
import os, re, subprocess, sys
REG   = 'documentation/RETRACTED_FIGURES.tsv'
ALLOW = 'documentation/DOC_GATE_FIGURE_ALLOWLIST.txt'
if not os.path.exists(REG):
    # ITEM A1: unreachable in normal use — the bash `require_tracked` above returns first —
    # but it must not be left as a `sys.exit(0)` skip. A dead false-clear is still a false
    # clear the moment someone edits the guard above it out, and this one would report PASS
    # for a gate that had inspected nothing.
    print(f'  [FAIL] {REG} is absent, so this gate checked nothing'); sys.exit(1)

figs = []
for ln in open(REG, encoding='utf-8'):
    if not ln.strip() or ln.startswith('#'):
        continue
    f = ln.rstrip('\n').split('\t')
    if len(f) >= 2 and f[0].strip():
        figs.append((f[0], f[1]))

# (file, figure, anchor) -> (class, why).  Anchor is a fixed substring that must appear on
# the SAME LINE as the figure for the exemption to apply.
allow, used = {}, set()
if os.path.exists(ALLOW):
    for ln in open(ALLOW, encoding='utf-8'):
        if not ln.strip() or ln.startswith('#'):
            continue
        f = ln.rstrip('\n').split('\t')
        if len(f) >= 5:
            allow[(f[0], f[1], f[2])] = (f[3], f[4])

mds = subprocess.run(['git', 'ls-files', '*.md'], capture_output=True, text=True).stdout.split()
# COST, evaluated before writing it (box-safety rule): |mds| ~ 130 files x ~500 lines x
# |figs| = 9 fixed-string `in` tests ~ 6e5 substring checks over data already in memory.
# No regex, no bounded repetition, no accumulation across the loop.
bad, exempt, spans = [], [], []
# The registry (.tsv) and the allowlist (.txt) are not in `git ls-files '*.md'`, so the
# gate cannot match its own rows. Verified rather than assumed: both extensions are
# outside the glob.
for m in mds:
    text = open(m, encoding='utf-8', errors='replace').read()
    lines = text.split('\n')
    flat = ' '.join(text.split())          # line-break evasion check, GATE 3's lesson (a)
    for fig, note in figs:
        n_online = 0
        for i, line in enumerate(lines, 1):
            if fig not in line:
                continue
            n_online += line.count(fig)     # OCCURRENCES, not lines: TR-2:650 carries
                                            # "1.4σ" twice and would otherwise look short
            # MARK EVERY MATCHING ROW USED, not just the first (fixed on this gate's
            # first run, before it shipped). Two anchors can legitimately land on one
            # line: TR-2 v1.23 quotes v1.19's "not reconstructible from the stated
            # errors" AND says where 1.4 came from, so both rows match line 654. A
            # break-on-first left the second looking dead and printed a [note] that was
            # a pure false alarm — the drift audit crying wolf on its own first run is
            # exactly how a real dead row later gets ignored.
            hits = [(anchor, cls, why)
                    for (af, afig, anchor), (cls, why) in allow.items()
                    if af == m and afig == fig and anchor in line]
            if hits:
                for anchor, _, _ in hits:
                    used.add((m, fig, anchor))
                exempt.append((m, i, fig, hits[0][1], hits[0][2]))
            else:
                bad.append((m, i, fig, note, line.strip()))
        # A figure visible only after whitespace normalisation spans a hard wrap, so no
        # single line carries it and the anchor rule cannot be applied. Report it as a
        # finding rather than passing it: this is exactly the evasion that hid the
        # conflict-theorem scope from GATE 3 until 2026-08-01.
        #
        # COUNT-based, not "did any line carry it" (tightened in this batch's own Phase-4
        # pass). The first cut asked `if not seen_on_a_line`, which meant a file with one
        # ordinary occurrence AND one wrapped occurrence reported only the ordinary one —
        # the wrapped copy, i.e. the harder-to-see one, was masked by the easy one. flat
        # collapses runs of whitespace to a single space, so a figure whose own internal
        # spacing is already single is counted identically on both sides.
        #
        # And the count is of OCCURRENCES, not of matching lines. The first version of this
        # comparison counted lines, so a line carrying the figure twice (TR-2:650 does) read
        # as one and the file reported a phantom hard wrap. Caught by this batch's own
        # Phase-4 pass, three false [FAIL]s, before it shipped.
        #
        # Residual, stated: a figure containing a space ("marginal 4.6") that is written with
        # a DOUBLE space on some line is collapsed by flat and not by line.count, so it would
        # be reported as wrapped. That direction over-reports rather than misses, which is the
        # direction a retraction gate should err in.
        if flat.count(fig) > n_online:
            spans.append((m, fig, note))

for m, i, fig, note, line in bad:
    print(f'  [FAIL] {m}:{i} — retracted figure "{fig}" restated with no supersession marker')
    print(f'         WHY: {note}')
    print(f'         LINE: {line[:150]}')
for m, fig, note in spans:
    print(f'  [FAIL] {m} — retracted figure "{fig}" present only after whitespace')
    print(f'         normalisation, so it spans a hard wrap and cannot be anchored.')
    print(f'         WHY: {note}')

opens = [e for e in exempt if e[3] != 'meta-mention' and e[3] != 'historical']
for m, i, fig, cls, why in opens:
    print(f'  [OPEN] {m}:{i} "{fig}" — {why}')
dead = [k for k in allow if (k[0], k[1], k[2]) not in used]
for k in dead:
    print(f'  [note] allowlist row matched nothing this run: {k[0]} "{k[1]}" @ "{k[2][:40]}"')
    print(f'         Either the text was fixed (delete the row) or the anchor drifted.')

nbad = len(bad) + len(spans)
if not nbad:
    byclass = {}
    for _, _, _, cls, _ in exempt:
        byclass[cls] = byclass.get(cls, 0) + 1
    tally = ', '.join(f'{v} {k}' for k, v in sorted(byclass.items())) or 'none'
    print(f'  [ok] {len(figs)} registered retracted figure(s); every occurrence in '
          f'{len(mds)} markdown files is an allowlisted narration ({tally})')
sys.exit(1 if nbad else 0)
PY
}

# ----------------------------------------------------------------------------------
gate_links() {
  local rc=0
  echo "== GATE 4: internal markdown links + anchors resolve =="
  # Every [text](target) pointing INSIDE the repo must resolve: the file must exist,
  # and a #fragment must match a heading slug (GitHub rules, including the -1/-2
  # suffixing of duplicate headings) or an explicit <a name=>/<a id=> anchor.
  # External http(s)/mailto targets are NOT fetched — this gate is offline and
  # deterministic by design; link-rot is a separate, network-dependent concern.
  # A dangling CITATIONS.md#anchor is the specific failure this protects against:
  # attribution that silently stops resolving when a citation entry is renamed.
  python3 - <<'PY'
import os, re, sys, subprocess, collections
LINK = re.compile(r'\[[^\]]*\]\(([^)\s]+)\)')
HEAD = re.compile(r'^(#{1,6})\s+(.*?)\s*$', re.M)
def slug(t):
    t = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', t)
    t = re.sub(r'[`*_~]', '', t).strip().lower()
    t = re.sub(r'[^\w\s-]', '', t)
    return re.sub(r'\s+', '-', t)
mds = [p for p in subprocess.run(['git','ls-files','*.md'],capture_output=True,text=True)
       .stdout.split()]
anchors = {}
for m in mds:
    txt = open(m, encoding='utf-8', errors='replace').read()
    seen, a = collections.Counter(), set()
    for _, h in HEAD.findall(txt):
        s = slug(h); seen[s] += 1
        a.add(s if seen[s] == 1 else f"{s}-{seen[s]-1}")
    a.update(re.findall(r'<a\s+(?:name|id)="([^"]+)"', txt))
    anchors[os.path.realpath(m)] = a
bad = []
for m in mds:
    txt = open(m, encoding='utf-8', errors='replace').read()
    base = os.path.dirname(m) or '.'
    for tgt in LINK.findall(txt):
        if tgt.startswith(('http://','https://','mailto:')):
            continue
        path, _, frag = tgt.partition('#')
        if path == '':
            dest = os.path.realpath(m)
        else:
            dest = os.path.realpath(os.path.join(base, path))
            if not os.path.exists(dest):
                bad.append((m, tgt, 'no such file')); continue
        if frag and dest in anchors and frag not in anchors[dest] \
           and frag.lower() not in anchors[dest]:
            bad.append((m, tgt, 'no such anchor'))
for m, t, why in bad:
    print(f"  [FAIL] {m} -> {t}  ({why})")
if not bad:
    print(f"  [ok] all internal links + anchors resolve across {len(mds)} markdown files")
sys.exit(1 if bad else 0)
PY
  rc=$?

  return $rc
}

# ----------------------------------------------------------------------------------
gate_secrefs() {
  local rc=0
  # -- GATE 4b (added 2026-08-01, unit r70-serialize) --------------------------------
  # The half of a cross-reference that phase 1 CANNOT see. A pointer like
  #     [CRITIQUE.md](../documentation/CRITIQUE.md) Q1
  # has a LINK target that resolves perfectly — the file exists — so phase 1 passes it,
  # while the part a reader actually follows ("go to section Q1") is dead. Six such
  # pointers to a non-existent "CRITIQUE.md Q1" survived every gate in this file for
  # months for exactly that reason.
  #
  # SCOPE, deliberately narrow: only DELIMITED section references are checked —
  #   FILE.md §"Quoted Name"     and     FILE.md Q<n>
  # Undelimited `FILE.md §Some words` is NOT checked: prose runs on past the section
  # name with no terminator, so the extracted "name" is whatever the sentence happened
  # to say next, and a first cut of this gate produced ~60 findings of which most were
  # mis-parses. A gate that cries wolf gets switched off. If you want an undelimited
  # reference checked, quote it.
  #
  # MATCH RULE: the reference text, normalised (case, smart quotes, dashes, emphasis,
  # trailing punctuation), must appear as a substring of some heading in the target
  # file; "…" in the reference acts as a gap, its fragments matched in order. That is
  # the convention the repo already uses, e.g. CRITIQUE.md §"Pre-registered tests …
  # Davis (2012)" against a much longer real heading.
  #
  # WHY-IT-FIRED: every finding prints the target file it resolved to and the reason,
  # not just a verdict — and allowlisted entries are re-printed every run as [OPEN]
  # with a count, so the known-dangling set can never quietly become invisible.
  #
  # OWN DISPATCH NAME (`secrefs`, added 2026-08-02, item A3). 4b used to live inside
  # gate_links, and the self-test asserted on `doc_gates.sh links` — one exit code
  # covering BOTH phases. A phase-1 failure for any unrelated reason would have satisfied
  # that assertion with 4b never having fired: [ok] printed for a gate that was not
  # exercised, which is precisely the untested-test shape this file's header warns about
  # (and the shape GATE 8's manual fire-proof shipped in). `links` still runs both, so
  # `all` and every existing caller are unchanged; the SELF-TEST now targets `secrefs`,
  # whose exit code no other gate can supply.
  # ITEM A2 (2026-08-02) — THE TWO QUESTIONS, for `norm()` and for the SUBSTRING match rule.
  #
  # Q1. WHAT LEGITIMATE VARIATION DOES IT ERASE? Case, smart quotes vs ASCII quotes, en/em
  #     dashes vs hyphens, emphasis markers, link syntax around the heading text, runs of
  #     whitespace, and trailing `.,;:`. Every one of those is a difference between how a
  #     heading is WRITTEN and how it is CITED, and none changes which section is meant.
  #
  # Q2. WHAT ILLEGITIMATE VARIATION DOES IT LET THROUGH? The substring rule, not the
  #     normalisation, is where the give is. A reference resolves if its text appears
  #     ANYWHERE inside ANY heading of the target file, so `§"Rule 2"` would also resolve
  #     against a heading named "Rule 25", and `§"A … B"` resolves against any heading with
  #     A somewhere before B. The gate reports RESOLUTION, never IDENTITY: it cannot tell
  #     "this points at the right section" from "some heading contains these characters".
  #
  #     MEASURED, because a claim about how weak a rule is should not be a guess. Across the
  #     corpus there are 55 resolving delimited references, 2 of them using the `…` gap form.
  #     Ranked by (reference length / matched heading length) the weakest is 0.10 —
  #     `HISTORY.md:4987 -> MCKENNA.md §"Rule 2"` against the heading "mckenna's rule 2 —
  #     declined for promotion to formal c-rule". Every one of the 15 weakest was read: all
  #     are a short PREFIX of a long heading, which is how this repo cites, and NONE resolves
  #     against an unrelated heading. So the rule is loose but is not currently producing a
  #     false clear — a statement about today's corpus, not about the rule.
  echo "== GATE 4b: plain-text section references resolve to a real heading =="
  python3 - <<'PY'
import os, re, sys, subprocess
MDLINK = re.compile(r'\[([^\]]*)\]\(([^)\s]+)\)')
HEAD   = re.compile(r'^#+\s+(.*?)\s*$', re.M)
# ITEM B1 (2026-08-02, drain-2) — THE SECOND ANCHOR FORM. This repo names a block in two
# ways, and until now the gate modelled only one. `**Global observable ledger (enterprise-wide
# multiple comparisons).**` at reports/METHODS.md:165 is cited as METHODS.md §"Global observable
# ledger" from five files; `**Stop-flag resolution (v1.12, 2026-07-13): …**` at
# TR2_THE_RULES_CONFLICT.md:412 is cited from three. MEASURED, not assumed: of the 19 non-meta
# rows on the allowlist, 10 resolve against a line-leading bold label and 2 more resolve after a
# stale word is fixed in the citation — a majority. Rewriting twelve citations to name the
# enclosing `##` heading instead would have made each of them point at a whole section rather
# than the paragraph meant, so the corpus was right and the gate's model of an anchor was wrong.
#
# DELIBERATELY NARROW. Only a bold span that OPENS a line (after an optional blockquote marker
# and an optional list bullet) counts. Arbitrary mid-sentence emphasis does not — the corpus is
# full of it, and treating it as an anchor would make almost any short reference resolve. A table
# cell (`| **x** |`) is not an anchor either: the line opens with `|`.
#
# WHAT THIS CANNOT SEE, stated because a widened rule is a weakened rule: heading resolution
# already reports RESOLUTION, never IDENTITY (see the A7 block below), and bold labels are far
# more numerous than headings, so the substring rule has more room to find a wrong match here
# than it did before. That is why bold resolution is NOT silent — every one is printed as
# [bold-anchor] with the label it matched, on every run, so the weaker leg is auditable instead
# of being a clear.
BOLD   = re.compile(r'^[ \t]*(?:>[ \t]*)*(?:[-*+][ \t]+|\d+\.[ \t]+)?\*\*([^*][^*]*?)\*\*', re.M)
# The trailing `` ` `` is ITEM B1's backtick leg: a path written as `` `documentation/X.md` §"…" ``
# was invisible to this gate because \s* cannot match the closing backtick. Two references in the
# corpus are written that way and one of them — PARTITION_STABILITY_BOUNDARIES.md:83 — is dead.
SEC_Q  = re.compile(r'([\w./+-]+\.md)`?\s*§\s*"([^"]+)"')
SEC_N  = re.compile(r'([\w./+-]+\.md)`?\s+(Q\d+)\b')
ALLOW  = 'documentation/DOC_GATE_SECREF_ALLOWLIST.txt'

def norm(s):
    s = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', s)
    for a, b in (('’', "'"), ('‘', "'"), ('“', '"'), ('”', '"'),
                 ('–', '-'), ('—', '-')):
        s = s.replace(a, b)
    s = re.sub(r'[`*_~"]', '', s)
    s = re.sub(r'\s+', ' ', s)
    return s.strip().strip('.,;:').lower()

mds = subprocess.run(['git','ls-files','*.md'],capture_output=True,text=True).stdout.split()
heads, bolds, bybase = {}, {}, {}
for m in mds:
    txt = open(m, encoding='utf-8', errors='replace').read()
    heads[os.path.realpath(m)] = [norm(h) for h in HEAD.findall(txt)]
    bolds[os.path.realpath(m)] = [norm(b) for b in BOLD.findall(txt)]
    bybase.setdefault(os.path.basename(m), []).append(os.path.realpath(m))

allow, allow_why = set(), {}
if os.path.exists(ALLOW):
    for ln in open(ALLOW, encoding='utf-8'):
        if not ln.strip() or ln.startswith('#'):
            continue
        f = ln.rstrip('\n').split('\t')
        if len(f) >= 4:
            allow.add((f[0], f[1], norm(f[2])))
            allow_why[(f[0], f[1], norm(f[2]))] = f[3]

bad, opened, ambiguous, viabold = [], [], [], []
hit_allow = set()
# ITEM B1 (2026-08-02, drain-2) — TWO-LINE WINDOW. The scan was per line, so a reference a hard
# wrap splits between `FILE.md` and its §"…" was invisible. GATE 3's hardening note (a) already
# records that exact evasion for a different gate; this is the same hole, and MEASURED it hides
# 15 of the corpus's 85 delimited references — 18%, none of which any run had adjudicated. Each
# line is flattened SEPARATELY and then joined, so the boundary offset stays exact and a markdown
# link is never mangled across the join; a match is attributed to the line it STARTS on
# (mo.start() < boundary), which is also what stops a reference lying wholly on line i+1 from
# being counted twice. SEC_Q is blanked with same-length spaces before the SEC_N pass for the
# same reason — a shortening substitution would move every offset after it.
for m in mds:
    base = os.path.dirname(m) or '.'
    flats = [MDLINK.sub(lambda mo: mo.group(2), ln)      # [text](path) -> path
             for ln in open(m, encoding='utf-8', errors='replace').read().split('\n')]
    for lineno in range(1, len(flats) + 1):
        head = flats[lineno - 1]
        boundary = len(head)
        cont = ''
        if lineno < len(flats):
            # drop the wrap's own blockquote/bullet decoration; it is not part of the sentence
            cont = ' ' + re.sub(r'^[ \t]*(?:>[ \t]*)*(?:[-*+][ \t]+)?', '', flats[lineno])
        window = head + cont
        hits  = [(mo.group(1), mo.group(2)) for mo in SEC_Q.finditer(window)
                 if mo.start() < boundary]
        blanked = SEC_Q.sub(lambda mo: ' ' * len(mo.group(0)), window)
        hits += [(mo.group(1), mo.group(2)) for mo in SEC_N.finditer(blanked)
                 if mo.start() < boundary]
        for path, sec in hits:
            if path.startswith(('http://', 'https://')):
                continue
            dest = None
            for cand in (os.path.realpath(os.path.join(base, path)), os.path.realpath(path)):
                if cand in heads:
                    dest = cand; break
            if dest is None:                       # bare "CRITIQUE.md", no path
                same = bybase.get(os.path.basename(path), [])
                if len(same) == 1:
                    dest = same[0]
            if dest is None:
                continue                           # file-level resolution is phase 1's job
            want = norm(sec)
            if not want:
                continue
            parts = [p.strip() for p in re.split('…|\\.\\.\\.', want) if p.strip()]

            # ITEM B4 (2026-08-02, drain-1) — `anchored` is the bold leg's PREFIX rule. The
            # reference's first part must sit at offset 0 of the label, not anywhere inside
            # it. Heading resolution is unchanged (anchored=False); see the B4 note below the
            # ratio block for why the two legs get different rules.
            def _match(anchors, parts=parts, anchored=False):
                out = []
                for h in anchors:
                    pos, ok = 0, True
                    for k, p in enumerate(parts):
                        i = h.find(p, pos)
                        if i < 0 or (anchored and k == 0 and i != 0):
                            ok = False; break
                        pos = i + len(p)
                    if ok:
                        out.append(h)
                return out

            matches = _match(heads[dest])
            if not matches:
                # ITEM B1 — the second anchor form. Reported, never silent: see the BOLD note.
                bm = _match(bolds[dest], anchored=True)
                if bm:
                    viabold.append((m, lineno, os.path.relpath(dest), sec, bm[0]))
                    continue
            if matches:
                # ITEM A7 (2026-08-02). This gate reports RESOLUTION, never IDENTITY: a
                # reference resolves if its text appears anywhere inside ANY heading of the
                # target, so §"Rule 2" also resolves against a heading "Rule 25", and the gap
                # form §"A … B" resolves against any heading with A before B.
                if len(matches) > 1:
                    ambiguous.append((m, lineno, os.path.relpath(dest), sec, matches))
                continue
            rel = os.path.relpath(dest)
            key = (m, rel, want)
            if key in allow:
                hit_allow.add(key)
                opened.append((m, lineno, rel, sec, key))
            else:
                bad.append((m, lineno, rel, sec, key))

for m, ln, d, s, key in bad:
    print(f'  [FAIL] {m}:{ln} -> {d} §"{s}"')
    print(f'         WHY: nothing in {d} is named "{norm(s)}" — no heading contains that'
          f' normalised text, and no line-leading bold label BEGINS with it (ITEM B4: a bold'
          f' label matched mid-text is not an anchor)')
for m, ln, d, s, key in opened:
    print(f'  [OPEN] {m}:{ln} -> {d} §"{s}"  ({allow_why.get(key, "allowlisted")})')
# ITEM B1 (2026-08-02, drain-2) — STALE ALLOWLIST ROWS ARE A FAILURE, not a tidiness issue.
# This gate's allowlist is the record of what is KNOWN broken. A row that no longer corresponds
# to any live finding is an exemption with nothing under it: it can be silently satisfying a
# future reference that happens to reuse the same (source, target, section) triple, and it makes
# the [note] count below overstate the open-defect load. Widening the anchor model in this very
# commit retired ten rows at a stroke, which is exactly the moment such rot gets created — so
# the check ships with the change that would otherwise have caused it.
stale = sorted(allow - hit_allow)
for src, tgt, want in stale:
    print(f'  [FAIL] stale allowlist row: {src} -> {tgt} §"{want}"')
    print(f'         WHY: that reference no longer fails, so the row exempts nothing.'
          f' Delete it from {ALLOW} — an exemption with no finding under it is a silent'
          f' licence for the next reference that reuses the same triple')
# ITEM A7 (2026-08-02) — REPORT-ONLY AMBIGUITY NOTE, and why it is this and not a strength
# floor on the match.
#
# The hazard A7 names is that "the next dangling reference that happens to be a substring of
# an unrelated heading passes silently". The obvious instrument is a COVERAGE RATIO — flag a
# resolution when the matched heading is much longer than the reference — and it was measured
# before being written. Over the 55 references that resolve today the ratio runs:
#     1.0 : 12    0.8 : 2    0.7 : 3    0.6 : 3    0.5 : 3
#     0.4 : 12    0.3 : 13   0.2 : 3    0.1 : 4
# so any threshold loose enough to be a tripwire fires on ~15-20 references that were each
# read individually in round 5 and are each a legitimate short prefix (§"d3 560T" ->
# "d3 560t - current deepest", ratio 0.28; §"Data-like vs principled" -> the F-23 heading,
# 0.33). A report-only note firing twenty times on correct references is how a report-only
# gate stops being read, which is the open question C3 already carries.
#
# AMBIGUITY is the same hazard with none of that cost. A reference is dangerous precisely
# when it does NOT single out one heading; §"Rule 2" is harmless until MCKENNA.md gains a
# "Rule 25". MEASURED on the corpus of 2026-08-02: 55 references resolve and ZERO resolve
# against more than one heading, so this note is silent today and speaks only when a heading
# is added that makes an existing reference stop identifying its target.
#
# IT IS DELIBERATELY NOT A FAILURE. Whether an ambiguous-but-resolving reference should go
# red is a judgment about the corpus, not a mechanical fact, and A7 lists "accept as
# documented" as a live option; escalating this to rc 1 is the operator's call, not a drain
# unit's. WHAT IT CANNOT SEE: a reference that resolves against exactly one WRONG heading —
# no amount of counting finds that, only reading does.
#
# ITEM B4 (2026-08-02, drain-1) — THE PREFIX RULE, SHIPPED. `f3179f8` measured the two candidate
# strength floors for the bold leg and rejected one of them; this ships the other. The decision
# is NOT re-derived here, because re-deriving it with a length ratio is the specific error the
# measurement warns against — the seven lowest-ratio references (0.159-0.193) are the CORRECT
# ones, citing the stable opening of a long annotated label, so the ratio is backwards for this
# corpus and a floor loose enough to spare them (<=0.15) sits far below the ~0.47 the motivating
# defect scored. No threshold separates them. Recorded at f3179f8; do not re-measure it.
#
# WHAT SHIPPED INSTEAD: `_match(..., anchored=True)` on the bold leg only. A reference must match
# at the LABEL'S START. Population at ship time: 0 of 18 — the rule is green with NO allowlist,
# because the one reference that violated it was fixed at f3179f8
# (documentation/CITATIONS.md:1055 -> SPECIFICATION.md §"wrap-around parity", which resolved at
# offset 9 inside "theorem (wrap-around parity is odd)" and was widened to the label's own
# opening form). That fix is what the LEG 7 fire-proof re-injects, so this rule is proven against
# its real motivating example rather than a synthesised one.
#
# WHY THE HEADING LEG IS LEFT ALONE. Its anchors are far less numerous, its §"A … B" gap form is
# in live use, and A7's ambiguity note already covers its weak case. Tightening both legs in one
# commit would make a green run unattributable to either. WHAT THE PREFIX RULE CANNOT SEE: a
# reference that IS a correct prefix of the WRONG label — prefix anchoring constrains WHERE a
# match may start, never WHICH label is meant, so it is a strictly weaker claim than identity and
# the [bold-anchor] print stays.
for m, ln, d, s, hs in ambiguous:
    print(f'  [note] {m}:{ln} -> {d} §"{s}" resolves against {len(hs)} headings, so it does')
    print(f'         not identify one section. Lengthen the reference until it does:')
    for h in hs[:4]:
        print(f'           also matches: {h}')
for m, ln, d, s, b in viabold:
    print(f'  [bold-anchor] {m}:{ln} -> {d} §"{s}" resolves against a line-leading bold label,')
    print(f'         not a heading: "{b[:96]}"')
if viabold:
    print(f"  [note] {len(viabold)} reference(s) above resolve via the WEAKER of the two anchor "
          f"forms; bold labels outnumber headings, so this leg is printed rather than cleared")
if opened:
    print(f"  [note] {len(opened)} allowlisted dangling reference(s) above are OPEN DEFECTS, "
          f"not exemptions — see {ALLOW}")
if not bad and not stale:
    print(f"  [ok] every delimited section reference resolves to a heading or a line-leading "
          f"bold label ({len(mds)} markdown files scanned)")
sys.exit(1 if (bad or stale) else 0)
PY
  [ $? -ne 0 ] && rc=1
  return $rc
}

# `links` keeps running BOTH phases, so `all` and every existing caller are unchanged.
gate_links_and_secrefs() {
  local rc=0
  gate_links   || rc=1
  gate_secrefs || rc=1
  return $rc
}

# ----------------------------------------------------------------------------------
gate_status() {
  echo "== GATE 5: canonical quantities keep their epistemic status =="
  # GATE 1 catches a number whose DIGITS changed. This catches the other half: a number
  # that keeps its digits while silently changing epistemic status — an estimate promoted
  # to "exact", or an exact count demoted to an estimate. reports/METHODS.md is the single
  # source of truth; documentation/CANONICAL_VALUE_STATUS.tsv is its machine-readable
  # projection. Report-only, because legitimate sentences DO compare the two (e.g. "the
  # ratio of the exact count to the Knuth estimate"), so an allowlist carries those.
  python3 - <<'PY'
import re, subprocess, sys, os
reg = 'documentation/CANONICAL_VALUE_STATUS.tsv'
allow = 'documentation/DOC_GATE_STATUS_ALLOWLIST.txt'
if not os.path.exists(reg):
    print(f"  [FAIL] missing registry {reg}"); sys.exit(1)
rows = []
for line in open(reg, encoding='utf-8'):
    line = line.rstrip('\n')
    if not line.strip() or line.lstrip().startswith('#'): continue
    p = line.split('\t')
    if len(p) >= 2: rows.append((p[0].strip(), p[1].strip()))
# Allowlist entries are "path:line" with an optional TAB-separated content anchor: a literal
# substring identifying the reviewed sentence.
#
# WHY the anchor is now the PRIMARY key (2026-08-01, second revision). The file:line form drifts,
# and drifts constantly: both entries in the allowlist drifted within a single day. The TR-4
# calibration row was written at :119, two lines were inserted above it, and the entry then
# (a) failed to suppress the real row at :121 and (b) silently covered whatever had moved into
# :119. Direction (b) is the dangerous one — an unreviewed line inheriting somebody else's
# suppression. The HISTORY.md entry then repeated the pattern: correct at :5563 when written,
# pushed to :5566 hours later by an unrelated insertion three lines above it.
#
# Matching an anchored entry by (file, anchor) instead of (file, line) fixes both directions at
# once. Direction (b) becomes impossible — suppression now REQUIRES the reviewed text, so no
# unreviewed line can inherit it no matter how the file is edited. And benign renumbering stops
# raising a WARN that carries no information. The recorded line number is kept as documentation
# and audited below, so a stale or dead entry is still reported rather than silently accumulating.
# ITEM A8, DECIDED 2026-08-02: the recorded line number is GONE from the format. The key is
# (file, anchor) and nothing else.
#
# The item offered three options — (i) keep and refresh by hand, (ii) drop it and lose the
# dead-entry audit, (iii) have the gate REWRITE the recorded line, self-healing. (iii) was
# the favourite. All three are declined, because (ii)'s stated cost is not real and (iii)
# has a cost that was not stated:
#
#   * "(ii) loses the dead-entry audit" is FALSE. Read the audit below: of its four
#     branches, three — file gone, anchor gone, anchor matches several lines — are driven
#     entirely by the ANCHOR. Only the fourth, "anchor now sits at :N, update the recorded
#     line", uses the number, and that branch is precisely the recurring [note] the item
#     complains about. Dropping the number costs the noise and keeps the whole audit.
#   * (iii) would make a gate a writer. The self-test REFUSES TO RUN unless the tree is
#     clean, so a self-healing gate run first would break the next run's precondition, and
#     a writer needs its own mutation case proving it wrote the RIGHT line — a new
#     instrument to trust, added to solve a documentation problem.
#
# The locator readers actually want is still printed: the gate resolves the anchor and
# reports the line it found, every run. A computed location cannot go stale.
#
# An entry with no anchor now SUPPRESSES NOTHING. It used to suppress by line number, which
# is the dangerous direction this whole design exists to close: an unreviewed line inheriting
# somebody else's exemption after an edit above it.
anchorless = []    # entries with no anchor: reported, and deliberately inert
anchored = {}      # file -> [anchor] — matched by content, immune to renumbering
if os.path.exists(allow):
    for l in open(allow, encoding='utf-8'):
        l = l.rstrip('\n')
        if not l.strip() or l.lstrip().startswith('#'): continue
        parts = l.split('\t')
        key = parts[0].strip()
        anc = parts[1].strip() if len(parts) > 1 and parts[1].strip() else None
        if anc is None:
            anchorless.append(key)
        else:
            anchored.setdefault(key, []).append(anc)
EST = r'estimate|estimated|Knuth|\bCI\b|confidence|Monte'
EX  = r'\bexact|\bproven|\bproved'
files = [p for p in subprocess.run(['git','ls-files','*.md'],capture_output=True,text=True)
         .stdout.split()]
seen = 0; bad = 0; hits = set()   # hits: which registry rows actually occur in the corpus
# GATE 5b state (2026-08-02, item A4). Cost formula, evaluated before writing it: F files x
# L lines, F ~ 250 and the whole tracked-markdown corpus ~10 MB, held once.
TEXT = {}          # f -> lines, kept only for files that actually carry a registry value
unmarked = {}      # f -> [(ln, val, want, line)] occurrences with NEITHER kind of token
marked = {}        # f -> {ln} occurrences that DID carry a token (either side)
n_unmarked = 0
for f in files:
    _lines = open(f, encoding='utf-8', errors='replace').read().splitlines()
    for ln, line in enumerate(_lines, 1):
        for val, want in rows:
            if re.fullmatch(r'[\d.]+', val) and ',' not in val:
                if not re.search(re.escape(val) + r'\s*[×x]\s*10', line): continue
            elif val not in line:
                continue
            seen += 1
            hits.add(val)
            TEXT[f] = _lines
            etoks = sorted(set(t.lower() for t in re.findall(EST, line, re.I)))
            xtoks = sorted(set(t.lower() for t in re.findall(EX, line, re.I)))
            he, hx = bool(etoks), bool(xtoks)
            if not he and not hx:
                unmarked.setdefault(f, []).append((ln, val, want, line))
                n_unmarked += 1
            else:
                marked.setdefault(f, set()).add(ln)
            conflict = (want == 'exact' and he and not hx) or (want == 'estimate' and hx and not he)
            if conflict:
                if any(a in line for a in anchored.get(f, ())): continue
                # RECORD WHICH QUANTITY AND WHICH TOKEN (2026-08-02, #65). "this line reads
                # otherwise" made the reader re-run the classifier by eye to find the word that
                # tripped it — and on a report-only gate, an unexplained WARN is one nobody
                # actions. Name the registry value, its METHODS status, and the exact status
                # token(s) matched on the wrong side.
                got = ", ".join(f'"{t}"' for t in (xtoks if want == 'estimate' else etoks))
                side = 'exact/proven' if want == 'estimate' else 'estimate'
                print(f"  [WARN] {f}:{ln} — quantity {val[:28]} is '{want}' in METHODS, but this line "
                      f"carries {side} token(s) {got} and no '{want}' marker")
                print(f"         {line.strip()[:170]}")
                bad += 1
if bad == 0:
    print(f"  [ok] {seen} occurrences of {len(hits)}/{len(rows)} canonical quantities "
          f"all carry a consistent status")
else:
    print(f"  (report-only: if a hit is a legitimate exact-vs-estimate COMPARISON, add its 'file:line' to {allow})")
# Audit the allowlist itself. A suppression that no longer corresponds to real text is a
# permission nobody reviewed and nobody can see; it must be reported, not accumulate silently.
for fpath, entries in sorted(anchored.items()):
    if not os.path.exists(fpath):
        print(f"  [note] allowlist: {fpath} no longer exists — prune its {len(entries)} entry/entries")
        continue
    text = open(fpath, encoding='utf-8', errors='replace').read().splitlines()
    for anc in entries:
        # ITEM A11 (2026-08-02): this loop variable used to be called `hits`, rebinding the
        # registry-hit SET built above into a list of allowlist line numbers. Benign only by
        # ordering — the "[ok] {seen} occurrences of {len(hits)}/{len(rows)}" print happens
        # before this loop. Any future edit that adds or moves a use of `hits` after this
        # point would silently report allowlist line numbers as canonical-quantity coverage:
        # a wrong denominator inside a coverage claim, which is the exact class this suite
        # exists to catch. Renamed so the two can never collide.
        anchor_lines = [i for i, l in enumerate(text, 1) if anc in l]
        if not anchor_lines:
            print(f"  [note] allowlist: {fpath} anchor no longer appears in the file — prune it")
            print(f"         anchor: {anc[:120]}")
        elif len(anchor_lines) > 1:
            print(f"  [note] allowlist: {fpath} anchor matches {len(anchor_lines)} lines {anchor_lines[:6]} — "
                  "suppression is broader than one reviewed sentence; make it more specific")
        else:
            # The locator, COMPUTED not recorded (item A8). Printed as [ok] rather than
            # [note] because a live, single-match exemption is not a defect and must not
            # compete for attention with the two branches above, which are.
            print(f"  [ok]   allowlist: {fpath}:{anchor_lines[0]} exemption live (matched by content)")
for key in sorted(anchorless):
    print(f"  [note] allowlist: \"{key}\" has no TAB-separated anchor, so it SUPPRESSES NOTHING "
          "and is ignored. Add an anchor: the format is file<TAB>anchor, no line number.")

# ---------------------------------------------------------------------------------
# GATE 5b — a canonical quantity restated with NO epistemic marker among siblings that
# carry one (2026-08-02, item A4).
#
# WHY. GATE 5 above fires only when a line carries a status token that CONTRADICTS
# METHODS. The two unlabelled TR-9 ledger cells fixed under #23 carried no token at all
# and were therefore invisible to it BY CONSTRUCTION — TR-9's own v1.19 row says so in as
# many words: "GATE 5 ... fires on a status token contradicting METHODS, and these cells
# carried no status token at all." An omission is the commoner shape and it was ungated.
#
# WHY IT IS SCOPED TO MIXED TABLES, and not to every unmarked occurrence. "Report every
# occurrence with neither token" measures at the noise floor printed below — most prose
# mentions of a canonical number legitimately carry no marker, and a gate that prints
# hundreds of lines every run is one whose output reviewers learn to skip (the same
# erosion items A8 and B2 describe). The DEFECT shape is narrower and is exactly what
# TR-9 v1.19 describes: "In a table where siblings are explicitly marked exact, an
# unmarked cell reads as one more exact count." So the reported class is: an unmarked
# occurrence inside a markdown table block where ANOTHER line of the SAME table carries a
# marker. The bare count is printed alongside, so the noise floor is MEASURED rather than
# assumed, and a future implementer can widen the class knowing what widening costs.
#
# REPORT-ONLY, with its own allowlist. The allowlist is a SEPARATE file from GATE 5's on
# purpose: 5 and 5b are different classes, and one file would let a suppression written
# for a reviewed exact-vs-estimate COMPARISON silently also exempt an unmarked cell on the
# same line. Anchored entries only — the line-number-only form drifted twice in one day.
alw5b = 'documentation/DOC_GATE_UNMARKED_ALLOWLIST.txt'
anc5b = {}
if os.path.exists(alw5b):
    for l in open(alw5b, encoding='utf-8'):
        l = l.rstrip('\n')
        if not l.strip() or l.lstrip().startswith('#'): continue
        parts = l.split('\t')
        if len(parts) < 2 or not parts[1].strip():
            print(f"  [note] {alw5b}: entry without a TAB-separated anchor is ignored — {parts[0][:80]}")
            continue
        # (file, anchor), no line number — the same convention GATE 5's allowlist adopted
        # under item A8 on 2026-08-02. Aligned in the same batch, because two allowlists
        # disagreeing about their own format is how the NEXT entry gets written in the old
        # one. This file is empty today, so aligning it costs nothing and leaving it costs a
        # silent parse failure later: rpartition(':') on a path with no colon yields
        # fpath == '', which would have keyed every entry under the empty string and
        # suppressed nothing, quietly.
        anc5b.setdefault(parts[0].strip(), []).append(parts[1].strip())

def table_blocks(lines):
    """Maximal runs of consecutive markdown table lines, as (start, end) 1-based inclusive."""
    blocks, start = [], None
    for i, l in enumerate(lines, 1):
        if l.lstrip().startswith('|'):
            if start is None: start = i
        elif start is not None:
            blocks.append((start, i - 1)); start = None
    if start is not None: blocks.append((start, len(lines)))
    return blocks

def header_labels(header, row, val, want):
    """True if the table HEADER already labels the column this value sits in.

    Found by running 5b for the first time, which is the point of running it: 4 of its 6
    initial findings were cells in tables whose header column IS the label — TR-4's
    "| Layer | Exact value | Prior Knuth estimate | ... |" and SEARCH_SPACE_SIZE's
    "| quantity | estimate | 95% CI | rel. error |". Those cells are not unlabelled; the
    label is one row up, where a per-line classifier cannot see it. Reporting them would
    have been the false-positive flood that gets a report-only gate ignored.

    Column-aware rather than whole-header: a table with BOTH an exact and an estimate
    column (TR-4 has exactly that) would otherwise be self-exempting in both directions.
    """
    hc = [c.strip() for c in header.split('|')]
    rc = [c.strip() for c in row.split('|')]
    pat = EST if want == 'estimate' else EX
    idx = [i for i, c in enumerate(rc) if val in c]
    if idx and len(hc) == len(rc):
        return bool(re.search(pat, hc[idx[0]], re.I))
    return False                        # ragged table: fall through and report it

found5b = 0
print("  -- 5b: unmarked canonical quantity among marked siblings in the same table --")
for f in sorted(unmarked):
    mk = marked.get(f, set())
    if not mk:
        continue
    for lo, hi in table_blocks(TEXT[f]):
        if not any(lo <= m <= hi for m in mk):
            continue                      # no marked sibling in this table — not the class
        header = TEXT[f][lo - 1]
        for ln, val, want, line in unmarked[f]:
            if not (lo <= ln <= hi):
                continue
            # A REVISION-HISTORY row is exempt, exactly as GATE 3 exempts one: a changelog
            # records what was said at a date and quotes figures in passing; demanding an
            # epistemic marker there would fire on every historical entry forever. Both of
            # 5b's remaining initial findings were changelog rows.
            if line.lstrip().startswith('| v'):
                continue
            if header_labels(header, line, val, want):
                continue
            if any(a in line for a in anc5b.get(f, ())):
                continue
            sibs = sorted(m for m in mk if lo <= m <= hi)
            # RECORD WHY IT FIRED (#65): the quantity, its METHODS status, the table it sits
            # in, and the sibling line whose marker makes the omission readable as a claim.
            print(f"  [WARN] {f}:{ln} — quantity {val[:28]} is '{want}' in METHODS and carries NO "
                  f"status marker, inside the table at :{lo}-{hi} whose sibling line(s) "
                  f"{sibs[:4]} DO carry one")
            print(f"         {line.strip()[:170]}")
            found5b += 1
if found5b == 0:
    print(f"  [ok] no unmarked canonical quantity sits in a table whose siblings are marked")
else:
    print(f"  (report-only: label the cell, or add 'file<TAB>anchor' to {alw5b})")
print(f"  [measured] noise floor: {n_unmarked} of {seen} registry-value occurrences carry no "
      f"status token at all; {found5b} of those are in a MIXED table, which is the reported class")
for fpath, entries in sorted(anc5b.items()):
    if not os.path.exists(fpath):
        print(f"  [note] {alw5b}: {fpath} no longer exists — prune its {len(entries)} entry/entries")
        continue
    txt = open(fpath, encoding='utf-8', errors='replace').read().splitlines()
    for anc in entries:
        hh = [i for i, l in enumerate(txt, 1) if anc in l]
        if not hh:
            print(f"  [note] {alw5b}: {fpath} anchor no longer appears — prune it")
        elif len(hh) > 1:
            print(f"  [note] {alw5b}: {fpath} anchor matches {len(hh)} lines {hh[:6]} — "
                  "make it more specific")
        else:
            print(f"  [ok]   {alw5b}: {fpath}:{hh[0]} exemption live (matched by content)")
sys.exit(0)
PY
}

# ----------------------------------------------------------------------------------
gate_figures() {
  echo "== GATE 6: figure GENERATORS carry no retracted phrasing =="
  # WHY: on 2026-08-01 a withdrawn claim ("hard floor k >= 13") was found RENDERED in a
  # published figure, having survived every gate. matplotlib converts text to glyph
  # paths, so fig_tr4_boundary_information.svg holds 0 <text> elements and 920 <use>
  # refs — the sentence is visible to a reader and invisible to grep. 38 of the repo's
  # 40 image assets are in that state (15 matplotlib SVGs incl. the PCA plots, plus
  # every PNG). We cannot grep the output, so we grep what PRODUCES it: the annotation
  # strings in the figure generators. Keeping generator text and figure in sync is the
  # generators' documented obligation.
  #
  # ITEM A8 (2026-08-02) — THE SAME BLINDNESS, FOR STATISTICS. Until now this gate read
  # RETRACTED_PHRASES.tsv only, so a withdrawn NUMBER annotated onto a published plot —
  # "~5,500×", "1.4σ", "+125" — was invisible everywhere: to GATE 3b (markdown only, and it
  # says so at RETRACTED_FIGURES.tsv's item 5), to GATE 6 (phrase registry only), and to any
  # grep of the asset itself (matplotlib renders text to glyph paths). The figure registry is
  # now a SECOND pass over the same generators. MEASURED before shipping: all nine registered
  # figures against the three tracked generators gives ZERO hits, so this ships with no
  # allowlist and a clean baseline — and, unlike the markdown corpus GATE 3b policed, the
  # legitimate-restatement problem does not arise here, because a figure generator has no
  # changelog rows and no retraction narrations to quote.
  local reg="documentation/RETRACTED_PHRASES.tsv"
  local figreg="documentation/RETRACTED_FIGURES.tsv"
  # ITEM A1, and this gate had the shape TWICE. (i) the registry skip, same as GATE 3.
  # (ii) the worse one: `gens` comes from `git ls-files`, an INDEX listing, so deleting
  # viz/report_figures.py from the working tree left it in `gens`, made `tr < "$f"` emit a
  # redirect error to stderr, produced no match, and the gate reported [ok] on a generator
  # it never opened. The `-n "$gens"` test cannot see that: the list was never empty.
  require_tracked "$reg" "The retraction registry IS this gate; with it gone, zero generators are checked."
  case $? in 1) return 0;; 2) return 1;; esac
  local gens bad=0 g
  gens=$(git ls-files 'viz/*.py')
  [ -n "$gens" ] || { echo "  [skip] no figure generators tracked in viz/*.py (index is empty for that path)"; return 0; }
  for g in $gens; do
    # Every path here came out of the index, so require_tracked can only return 0 or 2.
    local grc=0
    require_tracked "$g" "A tracked figure generator that is absent is not a clean generator." || grc=$?
    [ "$grc" -eq 0 ] || bad=1
  done
  [ "$bad" -eq 0 ] || return 1
  while IFS=$'\t' read -r phrase allow note; do
    case "$phrase" in ''|'#'*) continue;; esac
    local np hits=""
    np=$(printf '%s' "$phrase" | tr '\n' ' ' | tr -s ' ')
    for f in $gens; do
      if tr '\n' ' ' < "$f" | tr -s ' ' | grep -qF -- "$np"; then
        # RECORD WHERE (2026-08-02, item A5 / #65). This printed a bare filename, so a
        # maintainer given a 900-line generator had to re-run the search by hand to find
        # the annotation string — the same debugging cost #65 removed from GATE 3 and
        # GATE 5. Cite the line; fall back to the filename when the hit is only visible
        # after normalisation, which is the case a hard-wrapped Python string produces.
        local gln
        gln=$(grep -nF -- "$np" "$f" 2>/dev/null | head -1 | cut -d: -f1)
        if [ -n "$gln" ]; then hits="$hits $f:$gln"; else hits="$hits $f(spans-lines)"; fi
      fi
    done
    if [ -n "$hits" ]; then
      echo "  [FAIL] retracted phrasing in a figure generator: \"$phrase\""
      echo "         matched as the fixed string: \"$np\"   ($note)"
      for h in $hits; do echo "      $h  — regenerate the figure after fixing"; done
      bad=1
    fi
  done < "$reg"

  # ---- ITEM A8: the FIGURE registry, second pass over the same generators. -------------
  # Deliberately NOT merged into the loop above. The two registries have different column
  # counts (3 vs 2) and their verdicts must read differently — a maintainer needs to know
  # which registry to go and edit. Merging them would have rewritten the phrase leg's output
  # lines, and two existing fire-proofs assert on exactly those lines: that is the GATE 8
  # shape (an invocation rewritten under a fire-proof that was not re-run) and it is not
  # worth fifteen lines. What IS shared is the scan itself, below.
  local figbad=0 nfig=0
  require_tracked "$figreg" "The figure registry is the second half of this gate; absent, no retracted STATISTIC is checked."
  case $? in
    2) return 1 ;;
    1) echo "  [note] no figure registry, so retracted STATISTICS in generators are unchecked" ;;
    0)
      while IFS=$'\t' read -r figure fignote; do
        case "$figure" in ''|'#'*) continue;; esac
        nfig=$((nfig+1))
        local nf fighits=""
        nf=$(printf '%s' "$figure" | tr '\n' ' ' | tr -s ' ')
        for f in $gens; do
          if tr '\n' ' ' < "$f" | tr -s ' ' | grep -qF -- "$nf"; then
            local fgln
            fgln=$(grep -nF -- "$nf" "$f" 2>/dev/null | head -1 | cut -d: -f1)
            if [ -n "$fgln" ]; then fighits="$fighits $f:$fgln"; else fighits="$fighits $f(spans-lines)"; fi
          fi
        done
        if [ -n "$fighits" ]; then
          echo "  [FAIL] retracted FIGURE in a figure generator: \"$figure\""
          echo "         matched as the fixed string: \"$nf\"   ($fignote)"
          for h in $fighits; do echo "      $h  — regenerate the figure after fixing"; done
          figbad=1
        fi
      done < "$figreg"
      ;;
  esac
  [ "$figbad" -eq 0 ] || bad=1

  if [ "$bad" -eq 0 ]; then
    echo "  [ok] $(echo $gens | wc -w) figure generator(s) carry no registered retracted phrasing"
    echo "  [ok] ...and none of the $nfig registered retracted FIGURE(s) either (item A8)"
  fi
  return $bad
}

# ---------------------------------------------------------------------------
# GATE 7 — a run's status must not be frozen in the present tense, and a run
# must not be NAMED after a budget it never reached.
#
# Why: PASS1_TRAJECTORY_DETERMINISM.md — a doc CLAUDE.md lists under "Stable
# paper-citable findings" — described a run as "1000T (in flight)" and "3,666
# lines and growing" from 2026-04-24 until 2026-08-01. The run had stopped at
# ~154T on 2026-04-27. Worse, correcting the TENSE alone left the row labelled
# "Fresh 1000T": naming a run after a budget it never reached asserts the
# accomplishment just as strongly as the present tense did.
#
# HISTORY.md is exempt BY DESIGN. It is a dated narrative log; "the run is in
# flight as of this entry" is correct there and must not be rewritten. The
# whole point of that file is to preserve what was believed at the time.
gate_liveness() {
  echo "== GATE 7: no frozen present-tense run status; no run named after an unreached budget =="
  python3 - <<'PY'
import re, glob, sys
LIVE = ['in flight', 'currently running', 'results pending', 'and growing',
        'is underway', 'awaiting results', 'run is ongoing']
# Words that mean the status IS qualified rather than frozen, or that the text is
# quoting/correcting an old claim rather than making one.
# Each entry must describe an OUTCOME or mark the text as quoted/hypothetical.
# The first draft included 'budget', 'if ', 'would' and 'example' — far too generic.
# 'budget' alone made the gate VACUOUS on its own motivating example, because the
# stale table had a "Budget" column header three lines above the frozen status. A
# suppression list that matches ordinary prose suppresses everything; this is the
# same defect as a scrub that samples zero items and reports PASS.
DISPO = ['stopped at', 'was stopped', 'completed', 'requested', 'never reached',
         'never carried out', 'superseded', 'aborted', 'cancelled', 'partial',
         'previously read', 'corrected', 'no longer', 'observed scenario',
         'hypothetical', 'as of this', 'at the time']
bad = 0
# The registry is the authority on which budgets were actually REACHED. A run named
# after a budget in the registry is named correctly; one named after a budget that
# is NOT in the registry is asserting an accomplishment that may never have happened.
# Pattern-matching alone cannot tell those apart, and a gate that flags the correct
# ones too is a gate that gets ignored — the mistake GATE 4 of ops_gates.sh made.
# OPERATOR RULE (2026-08-01): "if you ever need to know if a large enumeration
# completed, it should be cataloged with a sha256 as a canonical hash." So the
# authority is not the mere APPEARANCE of a budget in the registry — it is a
# budget that carries a sha256. The first version of this gate took any <N>T
# token from the file, which silently admitted 1120T (mentioned only in a
# power-law extrapolation sentence, and CANCELLED on 2026-08-01) and 900T. A doc
# could then have said "the 1120T run" and passed. Require a sha in the vicinity.
reg = open('documentation/CANONICAL_HASHES.md', errors='replace').read()
REACHED = set()
MENTIONED = set()          # appears in the registry at all — but appearing is not attesting
for m in re.finditer(r'\b([0-9.]+T)\b', reg):
    MENTIONED.add(m.group(1))
    window = reg[max(0, m.start() - 600): m.end() + 600]
    if re.search(r'\b[0-9a-f]{16,64}\b', window):     # a sha256 (or its prefix) attests completion
        REACHED.add(m.group(1))
files = [f for f in glob.glob('documentation/*.md') + glob.glob('reports/*.md') + ['README.md']
         if 'HISTORY.md' not in f]      # dated narrative is exempt by design
for f in files:
    text = open(f, errors='replace').read()
    lines = text.split('\n')
    for i, l in enumerate(lines, 1):
        low = l.lower()
        for k in LIVE:
            if k not in low:
                continue
            ctx = ' '.join(lines[max(0, i-4):i+3]).lower()
            if any(d in ctx for d in DISPO):
                continue
            print(f"  [FINDING] {f}:{i} — status frozen in the present tense: \"{k}\"")
            print(f"            {l.strip()[:110]}")
            bad = 1
            break
    for m in re.finditer(r'\b(\d+(?:\.\d+)?T) (run|campaign|enumeration)\b', text):
        if m.group(1) in REACHED:
            continue                      # budget was actually reached — correct name
        st = max(0, m.start() - 400)
        para = text[st:m.end() + 400].lower()
        if any(d in para for d in DISPO):
            continue                      # disposition is stated nearby
        ln = text[:m.start()].count('\n') + 1
        # SAY WHY IT IS NOT ATTESTED (2026-08-02, #65). "not a budget any canonical reached"
        # states the verdict but hides the test, and the two ways of failing that test need
        # different fixes: a budget absent from the registry may be a typo or an invented run,
        # while one PRESENT but sha-less is the 1120T shape — a real number quoted from a
        # projection sentence and then written up as though it had been run. Operator rule:
        # completion is attested by a sha256 in CANONICAL_HASHES.md, nothing weaker.
        why = ("appears in documentation/CANONICAL_HASHES.md but with no sha256 within +/-600 "
               "chars of any mention — mentioned is not attested"
               if m.group(1) in MENTIONED else
               "does not appear in documentation/CANONICAL_HASHES.md at all")
        print(f"  [FINDING] {f}:{ln} — \"{m.group(0)}\" names a run after budget {m.group(1)}, which")
        print(f"            {why}, and no disposition is stated nearby.")
        print(f"            sha-attested budgets: {', '.join(sorted(REACHED)) or '(none)'}")
        bad = 1
if not bad:
    print("  [ok] no frozen run status; every budget-named run carries a disposition")
sys.exit(bad)
PY
}

# ---------------------------------------------------------------------------
# GATE 9 — the technical-report banner must be byte-identical across every TR,
# and must not re-assert the over-claim it replaced.
#
# WHY (2026-08-01, unit d72-banner): all 11 reports opened with
#   "Every claim is machine-verifiable; see the Verification Guide."
# which is FALSE as written — TR-8 says so about ITSELF in its executive summary's
# "Reproducibility flag": the dof-matched baseline has no artifact, command, seed or code
# path anywhere in the repo. reports/README.md had already been corrected to
# disclose the exceptions, so the suite was publishing one standard in its index
# and a stronger, false one on all 11 covers.
#
# The banner is the single most-copied string in the corpus — exactly the shape
# that drifts silently. Before this gate existed it ALREADY had: TR-2 and TR-8
# carried "…see the Verification Guide below." while nine others did not, and
# nothing in the repo could see it. That two-variant split is this gate's
# known-answer anchor: it was verified to FAIL on the pre-fix tree, naming those
# two files, before the corrected banner was applied.
#
# Byte-identity ALONE is not enough — eleven files reverted together are still
# byte-identical. So the gate also pins the discriminating clause, bans the
# retracted over-claim, and holds reports/README.md to the same clause so the
# index cannot drift back to a blanket promise.
#
# SAFETY: fixed-string containment and endswith() only — no regex at all.
# ITEM A2 (2026-08-02) — THE TWO QUESTIONS. GATE 9 does not normalise at all: the blocks
# are compared byte-for-byte. Its normalisation-equivalent is the SEGMENTATION rule — which
# lines count as "the banner" — and that carries exactly the same kind of claim.
#
# Q1. WHAT LEGITIMATE VARIATION DOES IT ERASE? Nothing inside the block; the comparison is
#     byte-wise. What it erases is everything OUTSIDE it. The block starts at the single
#     line containing "not peer-reviewed" and ends at the first line whose text ends in `*`.
#
# Q2. WHAT ILLEGITIMATE VARIATION DOES IT LET THROUGH? Any divergent sentence placed AFTER
#     that closing italic. MEASURED across the suite: every one of the 11 TR banner blocks
#     is exactly 3 lines (cap 8) and the index's is 12 (cap 24) — so no block is being
#     truncated by an early `*` today. But TR-10 carries its own italic *Scope note (F-34)*
#     paragraph on the very next line, and that paragraph is invisible to this gate. That is
#     correct behaviour (a per-report scope note is not banner drift) and it is also the
#     demonstration: "byte-identical across every report" is a claim about the 3 lines this
#     rule selects, not about what a reader sees under the heading.
gate_banner() {
  echo "== GATE 9: report banner byte-identical across all TRs =="
  python3 - <<'PY'
import glob, sys

MARK    = 'not peer-reviewed'
KEEP    = 'argued, not verified'          # the discriminating scope clause
RETRACT = 'Every claim is machine-verifiable'
MAXBLK  = 8                               # a REPORT banner is a short italic block
MAXIDX  = 24                              # the INDEX banner also enumerates the exceptions

def block(path, cap=MAXBLK):
    """Return (block_text, marker_line_count, 1-based line no) for the banner.

    `cap` is per-role and not cosmetic. The first version of this gate used the
    tight report cap of 8 for reports/README.md too; the index banner is 11+
    lines because it names each disclosed exception, so the gate reported it as
    "never closed its italic" and the index check never actually ran. It looked
    like a finding and was a bug in the checker — caught only because the gate
    was run against its known-answer anchor before being trusted.
    """
    lines = open(path, errors='replace').read().split('\n')
    hits = [i for i, l in enumerate(lines) if MARK in l]
    if len(hits) != 1:
        return None, len(hits), 0
    i = hits[0]
    blk = []
    for l in lines[i:i + cap]:
        blk.append(l)
        if l.rstrip().endswith('*'):      # closing italic marker
            return '\n'.join(blk), 1, i + 1
    return None, -1, i + 1                # never closed its italic within `cap`

trs = sorted(glob.glob('reports/TR*.md'))
bad = 0
variants = {}                             # block text -> [file:line]
if not trs:
    print('  [FAIL] no reports/TR*.md found — wrong working directory?')
    sys.exit(1)

for f in trs:
    blk, n, ln = block(f)
    if blk is None:
        bad = 1
        if n == -1:
            print(f'  [FAIL] {f}:{ln} — banner never closes its italic within {MAXBLK} lines')
        else:
            print(f'  [FAIL] {f} — expected exactly 1 line containing "{MARK}", found {n}')
        continue
    variants.setdefault(blk, []).append(f'{f}:{ln}')

print(f'  scanned {len(trs)} reports/TR*.md; {len(variants)} distinct banner(s)')

if len(variants) > 1:
    bad = 1
    print(f'  [FAIL] the banner is NOT byte-identical: {len(variants)} variants in use')
    ranked = sorted(variants.items(), key=lambda kv: -len(kv[1]))
    for n, (blk, files) in enumerate(ranked, 1):
        print(f'    variant {n} — {len(files)} report(s): {", ".join(files)}')
        for l in blk.split('\n'):
            print(f'        | {l}')
    # WHY it fired, not just THAT it fired: name the line where two variants diverge.
    a = ranked[0][0].split('\n')
    b = ranked[1][0].split('\n')
    for i in range(max(len(a), len(b))):
        x = a[i] if i < len(a) else '<no line>'
        y = b[i] if i < len(b) else '<no line>'
        if x != y:
            print(f'    first divergence at block line {i + 1}:')
            print(f'        variant 1 > {x}')
            print(f'        variant 2 > {y}')
            break

for blk, files in variants.items():
    if RETRACT in blk:
        bad = 1
        print(f'  [FAIL] the retracted over-claim "{RETRACT}" is back in: {", ".join(files)}')
    if KEEP not in blk:
        bad = 1
        print(f'  [FAIL] banner lacks its scope clause "{KEEP}" in: {", ".join(files)}')

# The index must not promise more than the covers do.
idx = 'reports/README.md'
iblk, n, ln = block(idx, MAXIDX)
if iblk is None:
    bad = 1
    print(f'  [FAIL] {idx} — no single well-formed banner block (marker lines: {n})')
elif RETRACT in iblk:
    bad = 1
    print(f'  [FAIL] {idx}:{ln} — index banner re-asserts "{RETRACT}"')
elif KEEP not in iblk:
    bad = 1
    print(f'  [FAIL] {idx}:{ln} — index banner lacks "{KEEP}"; the index may not')
    print(f'         promise more than the {len(trs)} report covers do')

if not bad:
    first = next(iter(variants)).split('\n')[0]
    print(f'  [ok] all {len(trs)} TR banners byte-identical; scope clause present; index aligned')
    print(f'       | {first}')
sys.exit(bad)
PY
}

# ---------------------------------------------------------------------------
# GATE 12 — a TR's revision history must be well-formed.
#
# WHY (item A4, filed round 1, written round 5 against MEASURED data): TR-1 shipped two
# rows both numbered v1.21 for a day and nothing in the repo could see it. The revision
# table is how every correction in this suite is attested, so a malformed one breaks the
# audit trail the corrections ledger and GATES 3/3b/10/11 all lean on.
#
# THE GATE FOUND TWO LIVE INSTANCES THE MOMENT IT WAS WRITTEN, both the same mistake and
# both PRE-EXISTING (neither introduced by this unit):
#   reports/TR8_REORDERING_REVISITED.md — `85d3b2c` added v1.11 by REPLACING the v1.10
#     line and re-adding v1.10 underneath, so the newest row was PREPENDED: dates ran
#     2026-08-02 then 2026-08-01, and `*(current)*` was not the last row.
#   reports/TR4_SIZE_OF_THE_SPACE.md — same shape, v1.16 above v1.15. Its two dates are
#     BOTH 2026-08-01, so the date leg alone does NOT see it; that is why the version-order
#     and current-is-last legs exist rather than the single "dates ascending" the item asked
#     for. A gate written to the item's letter would have cleared TR-4.
#
# SCOPE, and why it is exactly this: `git ls-files 'reports/TR*.md'`. Measured 2026-08-02 —
# all 11 TRs carry exactly one `## Revision history` heading; no file under documentation/
# carries one at all; reports/METHODS.md and reports/README.md have no revision rows and are
# not TRs. Rows are read only AFTER that heading, so a table elsewhere in the file whose
# first cell happens to start with `v` cannot be mistaken for a revision row.
#
# THE ONE TOLERATED DUPLICATE, measured not assumed: TR-11 carries three `v1.0-draft` rows
# (its lines 630-632), which are legitimate — a draft label is not a released version
# number. The exemption is therefore keyed on the SUFFIX (`v1.0-draft` vs `v1.0`), not on a
# filename or a line number, so it cannot silently widen. A repeat of a RELEASED number is a
# FAIL and is mutation-tested below.
#
# WHAT THIS GATE CANNOT SEE, stated rather than implied. (i) A revision row whose PROSE
# misdescribes what changed — it checks the table's shape, never its truthfulness; the
# defect TR-11 v1.15 records (a row asserting a propagation that had not happened) is
# invisible here. (ii) A missing row: a body edit that never got a revision entry at all
# leaves a perfectly well-formed table. (iii) TR-9's revision block is interrupted by a
# stray `*Draft-stage corrections (2026-07-04)*` paragraph between v1.10 and v1.11 (an
# already-filed operator item); this gate reads rows, not contiguity, so it does not fire on
# that and must not be read as clearing it.
gate_revhist() {
  echo "== GATE 12: TR revision histories (versions, dates, one current) =="
  python3 - <<'PY'
import re, subprocess, sys

HEAD = '## Revision history'
ROW  = re.compile(r'^\|\s*(v[0-9][^|]*?)\s*\|\s*([^|]*?)\s*\|')
VER  = re.compile(r'^v(\d+)\.(\d+)(.*)$')
DATE = re.compile(r'^\d{4}-\d{2}-\d{2}$')

out = subprocess.run(['git', 'ls-files', 'reports/TR*.md'],
                     capture_output=True, text=True)
trs = sorted(p for p in out.stdout.split('\n') if p)
bad = 0
# ROW CENSUS (item B9, round 9, 2026-08-02). The pass line counted FILES, and the file count
# does not move when a row is added — so GATE 12's negative control ("a repeated DRAFT label
# is exempt") could pin only `no repeated released version`, a phrase printed whenever the
# leg runs at all. The control INSERTS a revision row; a row count moves with it, and its
# ERE now pins the post-injection total. What it still cannot prove is that the inserted row
# was checked for the DRAFT-suffix exemption specifically — only that it was parsed as a row.
rows_seen = 0
if not trs:
    print('  [FAIL] git tracks no reports/TR*.md — wrong working directory, or the suite is gone')
    sys.exit(1)

for f in trs:
    # Enumerated from the INDEX, opened from the WORKTREE (item A1, hole (b)). A tracked TR
    # deleted from the tree would otherwise vanish from a glob and be reported as nothing at
    # all. The corpus preflight also catches this; the message is worded differently on
    # purpose so a fire-proof can tell the two apart.
    try:
        lines = open(f, encoding='utf-8', errors='replace').read().split('\n')
    except OSError as e:
        print(f'  [FAIL] {f} is tracked but could not be read ({e.__class__.__name__}) —')
        print('         a revision history that cannot be opened has not been checked')
        bad = 1
        continue

    start = next((i for i, l in enumerate(lines) if l.strip() == HEAD), None)
    if start is None:
        print(f'  [FAIL] {f} — no "{HEAD}" heading; every TR must carry one')
        bad = 1
        continue

    rows = []                       # (1-based line, version cell, date cell)
    for i in range(start, len(lines)):
        m = ROW.match(lines[i])
        if m:
            rows.append((i + 1, m.group(1).strip(), m.group(2).strip()))
    if not rows:
        print(f'  [FAIL] {f}:{start + 1} — "{HEAD}" heading with no version rows under it')
        bad = 1
        continue
    rows_seen += len(rows)

    keys, released, prev_date, prev_key = [], [], None, None
    for ln, ver, date in rows:
        plain = ver.replace('*(current)*', '').strip()
        m = VER.match(plain)
        if not m:
            print(f'  [FAIL] {f}:{ln} — version cell "{plain}" is not vN.N')
            bad = 1
            keys.append(None)
            continue
        key, suffix = (int(m.group(1)), int(m.group(2))), m.group(3).strip()
        keys.append(key)
        # SUFFIX-KEYED exemption: `v1.0-draft` is a draft label, not a released number, so
        # repeats of it are legitimate (TR-11 x3). `v1.0` repeated is not.
        if not suffix:
            released.append((plain, ln))
        if not DATE.match(date):
            print(f'  [FAIL] {f}:{ln} — date cell "{date}" is not YYYY-MM-DD, so this row\'s')
            print('         position in the history cannot be checked')
            bad = 1
        else:
            if prev_date and date < prev_date:
                print(f'  [FAIL] {f}:{ln} — dates run BACKWARDS: {prev_date} (row above) then {date}')
                print('         A revision table is chronological; a newer row was prepended, not appended.')
                bad = 1
            prev_date = date
        if prev_key and key < prev_key:
            print(f'  [FAIL] {f}:{ln} — versions run BACKWARDS: v{prev_key[0]}.{prev_key[1]}'
                  f' (row above) then {plain}')
            bad = 1
        prev_key = key

    seen = {}
    for plain, ln in released:
        if plain in seen:
            print(f'  [FAIL] {f}:{ln} — released version {plain} is already used at line {seen[plain]}')
            print('         (draft-suffixed labels like v1.0-draft may legitimately repeat; this one has no suffix)')
            bad = 1
        else:
            seen[plain] = ln

    cur = [(ln, ver) for ln, ver, _ in rows if '(current)' in ver]
    if len(cur) != 1:
        where = ', '.join(f'{f}:{ln}' for ln, _ in cur) or 'nowhere'
        print(f'  [FAIL] {f} — expected exactly one *(current)* row, found {len(cur)} ({where})')
        bad = 1
    elif cur[0][0] != rows[-1][0]:
        print(f'  [FAIL] {f}:{cur[0][0]} — *(current)* is not the LAST revision row '
              f'(last is line {rows[-1][0]}, {rows[-1][1]})')
        print('         The current version is by definition the newest; a table whose newest')
        print('         row is not at the bottom was appended to in the wrong place.')
        bad = 1

if not bad:
    print(f'  [ok] {len(trs)} TR revision histories, {rows_seen} revision row(s) checked: '
          'one *(current)* each and last, '
          'no repeated released version, dates and versions ascending')
sys.exit(bad)
PY
}

# ----------------------------------------------------------------------------------
# GATE 13 — a TR body edit must carry a revision row. REPORT-ONLY, and the measurement
# below is the reason it is report-only rather than the reason it might become blocking.
#
# WHY (item A4, filed round 5 in GATE 12's own header as the LARGER hole): GATE 12 checks a
# revision table's SHAPE. Its stated blindness (ii) is "a missing row: a body edit that never
# got a revision entry at all leaves a perfectly well-formed table". That is not theoretical —
# reports/TR4_SIZE_OF_THE_SPACE.md v1.13 exists ONLY to record, after the fact, a §3 edit that
# shipped with no row. This gate looks for that shape directly: a commit (or a working tree)
# that changes a TR's body and adds no `| vN.N |` row to the same file.
#
# MEASURED BEFORE WRITING A SINGLE VERDICT, over all 131 commits that touch reports/TR*.md:
# **102 of them would be flagged.** Not a long tail either — 13 are dated 2026-08-02 and 10
# are 2026-08-01. A BLOCKING gate here would not be enforcing this suite's rule; it would be
# announcing that the suite has never followed it. So this gate returns 0 unconditionally and
# prints `[note]`, in the same class as GATES 1, 5 and 5b. **Escalating it to [FAIL] is an
# operator decision and needs the 102/131 number in front of it**, together with a decision
# about the three false-positive classes below — it is not a drain unit's call and was not
# taken as one.
#
# THE THREE THINGS A `[note]` DOES NOT MEAN, all measured on real commits, not imagined:
#   (i)  A CROSS-CUTTING EDIT RECORDED IN THE LEDGER INSTEAD. `14d8751` rewrote the
#        not-peer-reviewed banner on all ELEVEN report covers and added no revision row to
#        any of them — and it is properly recorded, as CORRECTIONS.md CX-16 / RP-a823340f.
#        This gate reads diffs, never the ledger, so it notes all eleven. That single commit
#        is 11 of the 102.
#   (ii) A ROW THAT LANDS IN THE NEXT COMMIT. The check is per-commit: edit the body, commit,
#        then add the row, and the first commit is noted for a rule that was ultimately kept.
#   (iii) A ROW THAT LIES. GATE 12's blindness (i) is untouched here — TR-11 v1.15 records a
#        row that ASSERTED a propagation which had not happened, and a row like that satisfies
#        this gate completely. Presence is all that is checked. Nothing in this suite reads a
#        revision row's prose against the diff it claims to describe.
#
# SCOPE, and why two legs rather than one:
#   WORKTREE — `git diff HEAD -- reports/TR*.md`. This is the only leg that can PREVENT the
#     defect rather than record it, because it is the one that runs before the commit exists.
#     It costs nothing on a clean tree, which is most runs.
#   BATCH — a commit range, default `origin/main..HEAD` (the stack not yet pushed, i.e. the
#     one still under review) and overridable with $DOC_GATE_REVROW_RANGE. Merges are skipped:
#     `git show` on a merge prints a combined diff that is empty by default, so a merge would
#     be silently classified as "no body change" and the skip is stated rather than implied.
#     With no `origin/main` — a fresh clone, a detached checkout — the leg says so and does
#     not run; it does not pretend to have checked.
#
# COST FORMULA, evaluated before writing it (box rule): C commits in range x F touched TRs,
# one single-file `git show` each, F <= 11. Default C is the unpushed stack (single digits
# today); the self-test's ranges are one commit each, so <= 12 subprocess calls per assertion.
# Nothing accumulates across iterations.
gate_revrows() {
  echo "== GATE 13: TR body edits carry a revision row (REPORT-ONLY) =="
  python3 - <<'PY'
import os, re, subprocess, sys

ROW = re.compile(r'^([+-])\|\s*v\d+\.\d+')

def sh(*a):
    return subprocess.run(list(a), capture_output=True, text=True).stdout

def classify(diff):
    """(added revision rows, changed body lines) for ONE file's diff.

    Classification starts only after the first @@ hunk header, so the `---`/`+++` file
    headers can never be mistaken for content — a removed markdown rule (`---`) appears
    as `----` and would otherwise be indistinguishable from the header by prefix alone.
    Blank-only changes are not body changes; a revision row is counted on the + side only.
    """
    rows = body = 0
    in_hunk = False
    for l in diff.split('\n'):
        if l.startswith('@@'):
            in_hunk = True
            continue
        if not in_hunk or l.startswith('\\'):
            continue
        if l[:1] in '+-':
            if ROW.match(l):
                if l[0] == '+':
                    rows += 1
                continue
            if l[1:].strip():
                body += 1
    return rows, body

notes = []

# --- LEG 1: the working tree, the only leg that can catch this before it is committed.
wt = [f for f in sh('git', 'diff', '--name-only', 'HEAD', '--', 'reports/TR*.md').split('\n') if f]
for f in wt:
    rows, body = classify(sh('git', 'diff', '--unified=0', 'HEAD', '--', f))
    if body and not rows:
        notes.append(f'  [note] WORKTREE {f} — {body} body line(s) changed vs HEAD, no revision row added')
if not wt:
    print('  [ok] working tree: no uncommitted TR edit')

# --- LEG 2: a commit range. Default is the stack that is not yet pushed.
rng = os.environ.get('DOC_GATE_REVROW_RANGE', '').strip()
if not rng:
    if subprocess.run(['git', 'rev-parse', '--verify', '--quiet', 'origin/main'],
                      capture_output=True).returncode == 0:
        rng = 'origin/main..HEAD'
    else:
        print('  [note] no origin/main in this clone, so the BATCH leg did NOT run.')
        print('         Set DOC_GATE_REVROW_RANGE=<rev-range> to check a range explicitly.')
        rng = None

if rng:
    commits = [c for c in sh('git', 'rev-list', '--no-merges', rng).split('\n') if c]
    print(f'  [ok] batch leg range {rng}: {len(commits)} non-merge commit(s) examined'
          if commits else f'  [ok] batch leg range {rng}: no non-merge commits to examine')
    for c in commits:
        files = [f for f in sh('git', 'show', '--name-only', '--format=', c,
                               '--', 'reports/TR*.md').split('\n') if f]
        for f in files:
            rows, body = classify(sh('git', 'show', '--unified=0', '--format=', c, '--', f))
            if body and not rows:
                notes.append(f'  [note] {c[:8]} {f} — {body} body line(s) changed, no revision row added')

CAP = 25
for n in notes[:CAP]:
    print(n)
if len(notes) > CAP:
    print(f'  [note] ... and {len(notes) - CAP} more (capped at {CAP}; widen the range deliberately)')
if notes:
    print('  (report-only. A note is a QUESTION — "was this edit meant to be recorded?" — not a')
    print('   verdict. It cannot see a change recorded in CORRECTIONS.md instead, a row added in')
    print('   the NEXT commit, or a row whose prose misdescribes the edit it claims to record.)')
else:
    print('  [ok] every examined TR body edit carries a revision row in the same commit')
sys.exit(0)   # report-only gate — never blocks
PY
  return 0
}

# ===========================================================================
# SELF-TEST — mutation testing. Run: scripts/doc_gates.sh --selftest
#
# WHY (2026-08-01): these seven gates had never been observed to FAIL. GATE 7
# was VACUOUS on the day it was written — its suppression list contained the
# word "budget", and the stale table it was built for has a "Budget" column
# header three lines above the frozen status, so it passed cleanly on its own
# motivating defect. A gate nobody has watched fire is an untested test, and
# a green row of [ok] from an untested gate reads as coverage while providing
# none. That is the same failure as verify_archive.sh sampling zero shards and
# reporting PASS.
#
# METHOD: inject one known defect at a time into the real tree, run only the
# gate that should catch it, assert it FAILS, then revert with git checkout.
# Mutation testing rather than synthetic fixtures, deliberately: the gates read
# real paths (CANONICAL_HASHES.md, solve.py, viz/), so a fixture would test a
# different program than the one that runs in anger.
#
# SAFETY: refuses to run unless the tree is clean, so it can never destroy
# uncommitted work; every mutation is reverted immediately after its assertion,
# including on failure.
#
# ITEM A3 (2026-08-02) — TWO WAYS THE ABOVE WAS NOT TRUE, both met in the wild.
#
#  (1) NO MUTUAL EXCLUSION. Two --selftests could run at once. Observed: a background
#      --selftest's `git checkout -- .` discarded uncommitted edits to this very file and
#      left example/report.html sitting mutated. The clean-tree refusal cannot help — it is
#      a check at START, and the second runner passes it because the first has already
#      reverted its current mutation. Fixed below with an atomic `mkdir` lock in $GIT_DIR
#      (not the working tree, so the lock can never dirty the tree it is protecting, and
#      not /tmp).
#
#  (2) NO SIGNAL HANDLER. Every assertion helper reverts after each case, but a SIGTERM or
#      Ctrl-C between the mutation and the revert left the mutated file in place. That is
#      how example/report.html came to be mutated on disk with no run in progress. Fixed
#      below: INT and TERM restore and release before exiting, and an EXIT trap catches
#      every other path out.
#
# WHAT A3 DOES *NOT* FIX, stated rather than implied: a writer that is not a --selftest
# arriving mid-run. The lock only excludes other --selftests. An editor saving a file while
# assertions are in flight still loses that save to the next `git checkout -- .`, because the
# harness cannot distinguish its own mutation from someone else's edit. The only real
# protection there is not to edit the tree while the self-test runs; the round-4 workaround
# (commit first, then self-test) remains the operating procedure, and this note is here so
# that procedure is not mistaken for a guarantee the code provides.
#
# ITEM A1 + A2 (2026-08-02) — PREVENTION IS STILL ABSENT; RECOVERY IS NOT. The paragraph
# above stood for a round while the same idiom destroyed work twice more, so the answer is
# no longer only procedural: every revert in this harness now snapshots the whole dirty tree
# into refs/doc-gates/selftest-revert first (see `_selftest_revert` below). A discarded save
# is still discarded — but it is reachable through that ref's reflog instead of gone. Read
# the helper's header for the recovery commands; do NOT read this as making the tree safe to
# edit mid-run.
#
# A THIRD WAY, met 2026-08-02 while building legs 5 and 6 below, and the cheapest to warn
# about: the revert idiom itself gets COPIED. Taking a fire-proof by hand means running the
# mutation and then the harness's own `git checkout -- .` — which reverts the WHOLE tree,
# including the uncommitted edit to this script that the fire-proof was testing. That is
# what happened: two new legs and their self-test cases were written, proven to fire by
# hand, and then destroyed by the copied revert, with no --selftest involved at all. The
# harness is not what has to change (its `-- .` is load-bearing; see `_selftest_revert`). What
# changes is the procedure, and it is the same one as above, for a second reason: COMMIT
# FIRST, then mutate — by hand or by harness. `git checkout -- <path>` naming only the
# mutated file is the safe hand form.
#
# THE ORDER BELOW IS LOAD-BEARING: clean-tree check FIRST, then lock, then trap. Installing
# a restoring EXIT trap before the clean-tree check would make the dirty-tree refusal itself
# run `git checkout -- .` and destroy exactly the uncommitted work it exists to protect.
# ===========================================================================
if [ "${1:-}" = "--selftest" ]; then
  cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "REFUSING: working tree is not clean. This self-test mutates real files and"
    echo "reverts them with 'git checkout --'; that would discard your uncommitted work."
    exit 2
  fi

  # --- A3 (1): mutual exclusion. `mkdir` is atomic on every POSIX filesystem; a lockFILE
  # written with `>` is not. The holder's pid goes inside so a lock left behind by `kill -9`
  # (which no trap can catch) can be identified as stale and broken, loudly, rather than
  # wedging the suite until someone deletes it by hand.
  SELFTEST_LOCK="$(git rev-parse --git-dir 2>/dev/null || echo .git)/doc_gates_selftest.lock"
  if ! mkdir "$SELFTEST_LOCK" 2>/dev/null; then
    _holder=$(cat "$SELFTEST_LOCK/pid" 2>/dev/null || echo '?')
    if [ "$_holder" != '?' ] && ! kill -0 "$_holder" 2>/dev/null; then
      echo "  [note] breaking a STALE self-test lock: pid $_holder is gone (kill -9 leaves no"
      echo "         chance to release). If that run was interrupted mid-mutation, check"
      echo "         'git status' before trusting this one."
      rm -rf "$SELFTEST_LOCK"
      mkdir "$SELFTEST_LOCK" 2>/dev/null || { echo "REFUSING: cannot acquire $SELFTEST_LOCK"; exit 2; }
    else
      echo "REFUSING: another --selftest is running (pid $_holder, lock $SELFTEST_LOCK)."
      echo "Two concurrent self-tests revert each other's mutations with 'git checkout -- .',"
      echo "so one of them reverts the OTHER's injected defect and reports [ok] on a gate that"
      echo "never saw it — and any uncommitted edit made meanwhile is discarded."
      exit 2
    fi
  fi
  echo $$ > "$SELFTEST_LOCK/pid" 2>/dev/null

  # RECURSION STOP, reached only if the lock above is broken. The A3 fire-proof below calls
  # `bash "$0" --selftest` from inside a live run and expects the LOCK to refuse it; if the
  # lock ever stops working, that call would otherwise run the whole suite recursively. This
  # guard is deliberately placed AFTER the lock so that on a healthy system the lock message
  # is the one that prints (and the fire-proof asserts on that message, so a depth-guard
  # refusal correctly reads as a FAILURE of the lock rather than a pass).
  if [ "${DOC_GATES_SELFTEST_DEPTH:-0}" -ge 1 ]; then
    echo "REFUSING: nested --selftest reached the depth guard, which means the lock did NOT"
    echo "hold. Fix the lock; this guard exists only to stop unbounded recursion."
    rm -rf "$SELFTEST_LOCK" 2>/dev/null
    exit 2
  fi
  export DOC_GATES_SELFTEST_DEPTH=1

  # --- ITEM A1 + A2 (2026-08-02): every revert below is now RECOVERABLE.
  #
  # A1 records that `git checkout -- .` has destroyed uncommitted work THREE times by three
  # independent routes: a concurrent self-test (fixed by the lock), a SIGTERM between mutate
  # and revert (fixed by the traps), and — the one no code change reaches — the idiom being
  # COPIED into a by-hand fire-proof, which reverted the whole tree including the edits the
  # proof was testing. A2 is the residual the lock cannot close: an editor saving a file
  # while assertions are in flight is indistinguishable from the harness's own mutation, so
  # that save is discarded. Both were answered with PROCEDURE ("commit first"), and procedure
  # is exactly what failed, twice in one round.
  #
  # WHAT THIS CHANGES AND WHAT IT DOES NOT — stated rather than implied, because the previous
  # note's "can never destroy uncommitted work" is the claim that turned out to be false.
  # It does NOT prevent the discard. Nothing here can: `-- .` is load-bearing (see
  # the GATE 6 glob note further down this header), and the harness genuinely cannot tell whose edit
  # it is. What it does is make the discard RECOVERABLE. `git stash create` writes the entire
  # dirty tree to a commit object and returns its sha WITHOUT touching the working tree or
  # the index; `git update-ref` then anchors that object so gc cannot collect it. The ref's
  # REFLOG is the real record — one entry per revert, so the third-from-last revert is still
  # reachable, not merely the most recent.
  #
  # Recovery, worth reading before you need it:
  #     git reflog refs/doc-gates/selftest-revert       # every revert, newest first
  #     git show   refs/doc-gates/selftest-revert@{3}   # what that one threw away
  #     git checkout refs/doc-gates/selftest-revert@{3} -- <path>
  #
  # LOCAL AND EXPIRING BY CONSTRUCTION. refs/doc-gates/ is neither refs/heads nor refs/tags,
  # so no default push refspec carries it, it is empty in a fresh clone, and its reflog
  # expires on git's normal schedule. That is deliberately the same shape the GATE 10b
  # boundary note proposes for its own tripwire.
  #
  # WHY NOT `git stash push`: push MODIFIES the working tree (reverting is its side effect)
  # and rewrites the index. `create` is pure — it records and returns a sha and changes
  # nothing — so the revert that follows is still the plain, auditable `git checkout`, and
  # this wrapper cannot alter WHICH files come back. Scope matches too: `stash create`
  # captures tracked modifications, including a tracked file deleted by `os.remove`, and
  # tracked files are exactly what `checkout -- .` restores.
  #
  # WHAT IT STILL CANNOT SEE: an UNTRACKED file. `stash create` does not capture one and
  # `checkout -- .` does not delete one, so the two agree — but a human's brand-new,
  # never-added file is outside this safety net in both directions.
  #
  # WHY THE DEFAULT IS `-- .` AND NOT `-- "$file"` (corrected 2026-08-01, same-day
  # re-review; the note used to live on the deleted `assert_fires` helper and is kept here
  # because two comments above still point at it). The GATE 6 case mutates whatever
  # `glob('viz/*.py')` returns first — a path the caller cannot name, and glob order is not
  # guaranteed — while its documented <file> column said viz/README.md. So that mutation was
  # never reverted by its own assertion; only the blanket `git checkout -- .` after the last
  # case cleaned it up, leaving every later assertion running against a mutated tree.
  # Reverting everything is correct here and costs nothing: the self-test refuses to start
  # unless the tree is already clean, so there is never uncommitted work for `-- .` to
  # discard. The optional argument narrows it where a caller genuinely can name its target.
  _selftest_revert() {
    local snap
    snap=$(git stash create 2>/dev/null)
    if [ -n "$snap" ]; then
      # `--create-reflog` IS LOAD-BEARING AND WAS MISSING FOR ONE COMMIT (fbdbe26, fixed
      # same day). git's `core.logAllRefUpdates=true` — the default — writes reflogs ONLY
      # for refs/heads, refs/remotes, refs/notes and HEAD. refs/doc-gates/ is none of those,
      # so without this flag `update-ref` silently kept just the LATEST snapshot: the ref
      # resolved, `git show <ref>:<path>` worked, and every recovery command in the header
      # above appeared to function — while `@{1}` and older were never written at all.
      # MEASURED after a full 57-assertion run: `git rev-parse` resolved the ref and
      # `git reflog refs/doc-gates/selftest-revert` printed ZERO lines. A clear taken by
      # reading the code would have missed this; only running it and counting the entries
      # found it.
      git update-ref --create-reflog \
        -m "doc_gates --selftest revert $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        refs/doc-gates/selftest-revert "$snap" 2>/dev/null
    fi
    git checkout -- "${1:-.}" 2>/dev/null
  }

  # --- A3 (2): restore on every exit path, including signals. Installed only now, with the
  # tree already proven clean and the lock already held, so it can never discard real work.
  _selftest_release() {
    _selftest_revert
    rm -rf "$SELFTEST_LOCK" 2>/dev/null
  }
  trap '_selftest_release; echo; echo "DOC GATES SELF-TEST: INTERRUPTED (tree restored, lock released)"; exit 130' INT
  trap '_selftest_release; echo; echo "DOC GATES SELF-TEST: TERMINATED (tree restored, lock released)"; exit 143' TERM
  trap '_selftest_release' EXIT

  PASS=0

  # THERE IS NO EXIT-CODE-ONLY FIRE-PROOF HELPER IN THIS HARNESS (item A1, round 8,
  # 2026-08-02). `assert_fires <label> <file> <gate> <mutation>` used to live here and
  # asserted on the gate's EXIT CODE and nothing else. It is DELETED, and its six callers
  # were converted to `assert_fires_why` below. Read this before writing another one.
  #
  # WHY DELETED RATHER THAN DOCUMENTED. Both corpus preflights run before EVERY mode and
  # both return non-zero, so an exit-code assertion is satisfied by a preflight firing on a
  # defect that has nothing to do with the injected one. That is precisely the class GATE 16
  # was built for — arriving through the helper GATE 16 structurally could not examine,
  # since GATE 16 scans `assert_fires_why` invocations for their evidence-ERE and an
  # exit-code helper has none to scan. The weakness was written into GATE 16's own
  # "what it cannot see" note rather than fixed, for a round. Leaving the helper defined but
  # uncalled would have kept a working example of "an exit code is enough" in the file.
  #
  # THE CONVERSION FOUND TWO LIVE DEFECTS, not only the theoretical one. Two of the six
  # were dispatched to a COMBINED gate name, so each was satisfiable by the half that was
  # never in question:
  #   * "GATE 4 internal links" ran `links`, which is gate_links_and_secrefs — GATE 4 AND
  #     GATE 4b. A GATE 4b failure satisfied an assertion written about GATE 4.
  #   * "GATE 11 ledger completeness" ran `ledger`, which is gate_ledger_phrases AND
  #     gate_ledger_figures, and the figures pass already carries [OPEN] rows.
  # This is the same shared-dispatch class that got GATES 10a, 10b and 11-figures their own
  # dispatch names; these two were missed at the time. Asserting on each leg's own MESSAGE
  # pins the leg without needing a third and fourth dispatch name.
  #
  # EVERY EVIDENCE-ERE BELOW WAS TAKEN FROM A REAL RUN of its own mutation — inject, run the
  # gate, read the [FAIL] line, revert — never written from reading the gate's source. GATE
  # 8's hand-taken proof is why that is written down instead of assumed.
  #
  # ITEM A5 (2026-08-02) — A MOVED ANCHOR IS A FAILURE, NOT A SKIP, and that rule outlived
  # the helper it was written on. The deleted helper used to `return` after printing [SKIP],
  # leaving PASS untouched, so the suite reported "DOC GATES SELF-TEST: PASS" with the
  # assertion never having run. Its callers all pin HARDCODED CORPUS TEXT — GATE 9's two
  # banner sentences, GATE 10a's `len(L) > 60`, GATE 10b's "a line of the oldest version
  # survives" — every one of which a normal edit can move. Same shape as GATE 5b's first
  # run, which printed "[SKIP] anchor moved" because of a `%%` typo and was recorded as a
  # pass. MEASURED before that change: two helpers printed [SKIP] and left PASS alone while
  # four set PASS=1 on the identical condition — drift, not design. All surviving helpers
  # say failure.

  # assert_fires_why <label> <gate-name> <evidence-ERE> <python-mutation>
  #
  # ITEM A5 (task #65, the assertion half). An exit code cannot tell "the gate fired for the
  # reason I injected" from "the gate fired for some unrelated reason and my mutation was
  # never seen". Every classifier gate now prints the token/anchor/registry note that drove
  # its verdict; this harness is what makes that printing load-bearing instead of
  # decorative — the assertion FAILS if the WHY line does not name the injected thing.
  # Modelled on assert_gen_fires, which already did this for GATE 8; generalised here so
  # every classifier class can carry one, and since round 8 it is the ONLY fire helper.
  #
  # ITS INVOCATIONS ARE PARSED BY GATE 16, which extracts the evidence-ERE from each one and
  # refuses any ERE a preflight could emit. That parser requires the shape used below: the
  # call line starts with exactly two spaces, the label is the first double-quoted token on
  # it, the ERE is the first single-quoted token in the argument list, and the mutation body
  # opens at column 0. Keep the shape or GATE 16's per-invocation vacuity guard fails.
  assert_fires_why() {
    local label="$1" gate="$2" want="$3" mut="$4" out rc
    python3 -c "$mut" || { echo "  [FAIL] $label — could not inject (anchor moved), so the"
                           echo "         assertion did NOT run. A skipped assertion is not a pass."
                           PASS=1; _selftest_revert; return; }
    out=$(bash "$0" "$gate" 2>&1); rc=$?
    _selftest_revert
    if [ "$rc" -eq 0 ]; then
      echo "  [FAIL] $label — $gate did NOT fire on an injected defect"; PASS=1; return
    fi
    if printf '%s' "$out" | grep -qE -- "$want"; then
      echo "  [ok]   $label — $gate fires, and WHY names: $want"
    else
      echo "  [FAIL] $label — $gate fired, but its output never names \"$want\","
      echo "         so the assertion cannot tell this firing from an unrelated one."
      PASS=1
    fi
  }

  # assert_stays_clean_why <label> <gate-name> <evidence-ERE> <python-mutation>
  #
  # The other half of any gate that EXEMPTS or COMPARES: proof that the silence is driven by
  # what it claims to be driven by. Without it, a green gate is equally consistent with "the
  # exemption is correct" and "the exemption swallows the whole file".
  #
  # ITS [ok] MESSAGE NAMED THE WRONG MECHANISM until 2026-08-02 (item A3's review). It read
  # "exempted, as the ALLOWLIST says it should be" for all callers, and most of them consult
  # no allowlist at all: GATE 12's draft-label exemption is SUFFIX-keyed, and GATE 2's two
  # negative controls are a comm(1) comparison and a comment filter with no allowlist
  # anywhere in either. A message that attributes a verdict to a mechanism that was not
  # consulted is a small false attestation of exactly the kind this file exists to refuse, so
  # it now says only what it knows. (The original wording of this note counted "two of the
  # six"; the count is deliberately not restated, because a hand-taken tally in a comment is
  # the caveat-4 shape and it went stale the moment a seventh caller landed. The per-caller
  # strength lines below are the authority.)
  #
  # THE EVIDENCE ARGUMENT (item A1's residue, round 8 drain-3, 2026-08-02). This helper
  # asserted on rc 0 ALONE until now, which is the negative-control mirror of the defect that
  # deleted `assert_fires`: an exit code cannot tell "the gate looked at the injected case and
  # correctly stayed silent" from "the gate never looked at it", and it cannot tell either
  # from "the leg that would have looked was skipped". All three exit 0. The mutation is
  # reverted immediately afterwards, so nothing downstream ever notices which of the three
  # happened. It must now also match an ERE on the gate's OWN OUTPUT — a line that a run which
  # never reached the mutated file could not print.
  #
  # STRENGTH VARIES BY CALLER AND IS RECORDED AT EACH CALL, because a uniform claim here would
  # be the over-attestation this file exists to refuse. RE-TAKEN 2026-08-02 (round 9, item
  # B9), which is what moved the numbers below — round 8 shipped this helper with ONE measured
  # discriminator out of six, and said so. FOUR are now measured DISCRIMINATORS, meaning the
  # pinned number differs between the mutated run and a run that never read the injection,
  # each verified by running the mode BOTH ways. THE TOTAL IS DELIBERATELY NOT RESTATED HERE:
  # this sentence said "SEVEN callers" and was stale within the hour, because the same batch
  # that wrote it added an eighth call site — the caveat-4 shape, in the comment that names
  # caveat 4. The authority is the machine-read `callers=N` on this helper's row in
  # documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt, which GATE 15 LEG 3 re-derives every run:
  #   GATE 3b  meta-mention count 44 -> 45
  #   GATE 2   flags/documented 78/95 -> 79/96 (a flag added to both sides)
  #   GATE 2   commented-out declarations dropped 0 -> 1 (item A4's leg — the one a FLAG
  #            count could not discriminate, since the injected line must NOT become a flag)
  #   GATE 12  revision rows checked 158 -> 159
  # The other three pin a COUNT THAT THE DEFECT THE CONTROL IS ABOUT WOULD MOVE, which is
  # weaker: GATE 14's adjudicated-pair count, GATE 15's instrument count, and GATE 15 LEG 3's
  # claims census. NONE now pins only "the leg ran". Every one is strictly stronger than rc 0.
  #
  # NOT SCANNED BY GATE 16, and that is a reasoned exemption rather than an oversight: a
  # preflight-emittable ERE cannot produce a false [ok] here, because both preflights set
  # RC=1 at their `preflight_tracked_docs || RC=1` / `preflight_support_newlines || RC=1` call
  # sites, so a firing preflight fails this assertion at the rc test before the ERE is
  # consulted at all. See GATE 16's caveat (a). (Cited by NAME, not line number: a same-file
  # line citation drifts on every insertion above it, and both of these were stale within
  # the hour they were written — caught by this batch's own Phase-4 pass.)
  assert_stays_clean_why() {
    local label="$1" gate="$2" want="$3" mut="$4" out rc
    python3 -c "$mut" || { echo "  [FAIL] $label — could not inject; assertion did NOT run."
                           PASS=1; _selftest_revert; return; }
    out=$(bash "$0" "$gate" 2>&1); rc=$?
    _selftest_revert
    if [ "$rc" -ne 0 ]; then
      echo "  [FAIL] $label — $gate fired on a case it is supposed to leave alone"
      PASS=1; return
    fi
    if printf '%s' "$out" | grep -qE -- "$want"; then
      echo "  [ok]   $label — stays green, and its output names: $want"
    else
      echo "  [FAIL] $label — $gate stayed green, but its output never names \"$want\","
      echo "         so this assertion cannot tell an exemption that ran from a leg that"
      echo "         never looked. If the corpus moved a pinned COUNT, re-take the number"
      echo "         from a real run under this mutation; do not weaken the ERE."
      PASS=1
    fi
  }

  echo "== DOC GATES SELF-TEST (mutation) =="

  # ITEM A3 FIRE-PROOF (the mutual-exclusion half), IN-HARNESS and re-proven every run.
  #
  # This is here rather than in a note because of what happened to GATE 8's: its fire-proof
  # was taken by hand, never re-run after its invocation was rewritten, and a one-directional
  # comparison shipped behind it. A lock asserted only in a commit message decays the same
  # way. So the assertion runs from INSIDE a live self-test, where the lock is held: the
  # nested call must be refused, and refused FOR THE LOCK REASON. Asserting only on rc 2
  # would be satisfied by the dirty-tree refusal, the depth guard, or a missing file — three
  # different ways to pass without the lock working at all. The tree is clean at this point
  # (it is the harness's own precondition and no mutation has run yet), so the dirty-tree
  # branch cannot be what answers.
  _a3_out=$(bash "$0" --selftest 2>&1); _a3_rc=$?
  if [ "$_a3_rc" -eq 2 ] && printf '%s' "$_a3_out" | grep -q 'another --selftest is running'; then
    echo "  [ok]   A3 lock — a concurrent --selftest is refused, and the refusal names the lock"
  else
    echo "  [FAIL] A3 lock — a concurrent --selftest was not refused for the LOCK reason (rc=$_a3_rc)"
    printf '%s\n' "$_a3_out" | head -3 | sed 's/^/           > /'
    PASS=1
  fi

  # ITEM A1 FIRE-PROOF — the snapshot must be WRITTEN and READABLE BACK, asserted in-harness
  # and re-proven every run.
  #
  # THIS ASSERTION EXISTS BECAUSE ITS ABSENCE ALREADY COST A SHIPPED DEFECT. `_selftest_revert`
  # went out at fbdbe26 with a commit message claiming "the ref's reflog keeps one entry per
  # revert, so the third-from-last is still reachable". After a full 57-assertion run the ref
  # RESOLVED and its reflog held ZERO entries: git's default core.logAllRefUpdates writes
  # reflogs only for refs/heads, refs/remotes, refs/notes and HEAD, so every revert but the
  # last had been overwritten with no record. Reading the code could not show that — `git
  # update-ref` succeeds either way and every documented recovery command still appeared to
  # work. Only running it and COUNTING found it, which is why the count is now the assertion.
  #
  # It asserts TWO things, because either alone is satisfiable by a broken snapshot: the
  # reflog GREW (so history is retained, not just the latest value) and the discarded text is
  # actually readable out of @{0} (so the object holds the pre-revert tree, not an empty one).
  _A1_REF=refs/doc-gates/selftest-revert
  _a1_before=$(git reflog "$_A1_REF" 2>/dev/null | wc -l)
  if python3 -c "open('documentation/GUIDE.md','a',encoding='utf-8').write(
chr(10)+'<!-- A1 snapshot probe: this line is discarded and must stay recoverable -->'+chr(10))" 2>/dev/null; then
    _selftest_revert documentation/GUIDE.md
    _a1_after=$(git reflog "$_A1_REF" 2>/dev/null | wc -l)
    if [ "$_a1_after" -gt "$_a1_before" ] \
       && git show "$_A1_REF@{0}:documentation/GUIDE.md" 2>/dev/null | grep -q 'A1 snapshot probe'; then
      echo "  [ok]   A1 snapshot — a reverted edit is read back from $_A1_REF@{0}, and the"
      echo "         reflog grew ($_a1_before -> $_a1_after), so earlier reverts survive too"
    else
      echo "  [FAIL] A1 snapshot — the discarded edit is NOT recoverable (reflog $_a1_before ->"
      echo "         $_a1_after). Every revert in this harness is silently unrecoverable; check"
      echo "         that update-ref still passes --create-reflog."
      PASS=1
    fi
  else
    echo "  [FAIL] A1 snapshot — could not inject the probe, so the assertion did NOT run."
    PASS=1
  fi
  # THE SIGNAL HALF CANNOT BE ASSERTED HERE — a case that TERMs the self-test kills the
  # harness that would report on it. It was proven externally and deterministically on
  # 2026-08-02: with a run live and holding the lock, a marker line was appended to
  # example/report.html FROM OUTSIDE, then SIGTERM sent. Result: rc 143, final line
  # "DOC GATES SELF-TEST: TERMINATED (tree restored, lock released)", marker gone, lock
  # gone, `git status --porcelain` empty. An earlier version of that proof TERM'd before any
  # mutation existed and was therefore VACUOUS — "tree restored" was true of a tree that had
  # never been dirtied. The recorded proof is the second, non-vacuous one.

  # GATE 1 is REPORT-ONLY (`return 0`) and only inspects integers of >=12 digits. Asserting a
  # non-zero exit was wrong twice over: it can never exit non-zero, and the number I first
  # mutated has 10 digits so the gate would not look at it either way. Assert on its OUTPUT.
  # This also means "DOC GATES: PASS" has never included gate 1's findings — a real limit on
  # what that banner attests, now stated in the banner itself.
  # Anchor: the |C1nC2nC4nC5| exact count in README.md — 40 digits, non-round, and present
  # in more than one doc, which is exactly the shape gate 1 looks for. Flipping its last
  # digit creates a same-length near-twin sharing the first 10 digits: the corrupted-digit
  # case the gate exists to catch.
  python3 -c "s=open('README.md').read()
a='1,097,051,278,789,181,790,036,112,071,176,579,186,688'
assert a in s, 'anchor moved'
open('README.md','w').write(s.replace(a, a[:-1]+'9', 1))" 2>/dev/null \
    && { G1OUT=$(bash "$0" numbers 2>&1)
         if printf '%s' "$G1OUT" | grep -q 'WARN'; then
           echo "  [ok]   GATE 1 cross-file numbers — emits a WARN (report-only gate)"
         else
           echo "  [FAIL] GATE 1 cross-file numbers — no WARN on an injected near-twin"
           printf '%s\n' "$G1OUT" | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert README.md; } \
    || { echo "  [FAIL] GATE 1 — the 40-digit |C1nC2nC4nC5| anchor is no longer in README.md,"
         echo "         so the assertion did NOT run (item A5). Re-anchor it on a non-round"
         echo "         integer of >=12 digits that appears in more than one doc."
         PASS=1; }

  # GATE 2's FLAG-DRIFT CLASSIFIER (item A3, 2026-08-02). Until now the only GATE 2
  # assertions were the A1 missing-INPUT legs — delete sat.py, delete SAT_CLI.md — which
  # prove the gate notices its inputs are gone and nothing at all about whether it can still
  # spot an undocumented flag. That is the leg that has fired in anger (13 undocumented
  # flags, 2026-07/08), and it was the one thing GATE 2 exists for that no assertion touched.
  #
  # THE STATED BLOCKER WAS WRONG, and the correction is the point. The coverage note said
  # injecting a flag "would mutate solve.py, a costlier revert than the assurance is worth".
  # The revert is `_selftest_revert`'s `git checkout -- .`, which restores a modified
  # solve.py at exactly the cost it restores a modified GUIDE.md — the A1 legs already
  # `os.remove` a tracked source file and restore it the same way. The cost claim was
  # inherited, never measured, and it kept the gate's only real leg unproven for a round.
  #
  # BOTH EXTRACTORS, because they are two different regexes and only one is exercised per
  # pair: `add_argument\("--...` for py mode (roae.py, solve.py) and a bare quoted `"--..."`
  # for c mode (solve.c, sat.py). A fire-proof on one says nothing about the other. c mode is
  # injected into sat.py, not solve.c: solve.c is sha-anchored, and sat.py already carries
  # the A1 legs, so it is the established mutation target for this pair's shape.
  #
  # EACH INJECTION IS SYNTACTICALLY VALID PYTHON, deliberately. A comment carrying the same
  # text would satisfy the grep just as well — the gate never imports the file — but then a
  # revert that failed would leave a broken module behind, and the assertion would prove the
  # extractor sees TEXT rather than that it sees a FLAG. (That the two are the same thing to
  # this gate is a real property of it: a commented-out `add_argument("--x"` WOULD be
  # reported as undocumented. Recorded, not fixed; widening is not a fire-proof's business.)
  #
  # THE FLAG NAMES DIFFER PER ASSERTION (-py, -c, -neg) so the evidence ERE identifies which
  # extractor answered. An ERE naming only the file pair would be satisfied by any unrelated
  # drift in the same file, which is the class of false clear this harness exists to refuse.
  assert_fires_why "GATE 2 flag drift — undocumented flag, py extractor (solve.py)" cli \
    '--doc-gates-fireproof-py' \
"p='solve.py'
a='    parser.add_argument(\"--pairs\", action=\"store_true\",'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
n='    parser.add_argument(\"--doc-gates-fireproof-py\", action=\"store_true\", help=\"doc_gates --selftest injection; reverted by the harness\")\n'
open(p,'w',encoding='utf-8').write(s.replace(a,n+a,1))"

  assert_fires_why "GATE 2 flag drift — undocumented flag, c extractor (sat.py)" cli \
    '--doc-gates-fireproof-c' \
"p='sat.py'
a='    if \"--with-c3\" in args:'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
n='    _doc_gates_fireproof = \"--doc-gates-fireproof-c\" in args\n'
open(p,'w',encoding='utf-8').write(s.replace(a,n+a,1))"

  # THE NEGATIVE CONTROL, and it is not optional. The two assertions above are equally
  # consistent with "the gate compares code against doc" and with "the gate fails on any
  # flag name it has not seen before". Adding the SAME flag to both sides must leave it
  # silent; if this one ever fires, the comparison has stopped being a comparison.
  # EVIDENCE (round 8 drain-3, UPGRADED round 9 item B9): `solve.py fully documented` is
  # GATE 2's per-file pass line, so a green run that never reached the
  # solve.py<->SOLVE_PY_CLI.md comparison cannot print it. That pinned only that the LEG RAN
  # — round 8 said so plainly, and B9 is the fix rather than a re-statement. The pass line
  # now carries a census, and this ERE pins the POST-INJECTION values: clean, solve.py is
  # `78 flag(s) compared against 95 documented`; under this mutation both sides gain exactly
  # one, so a run that did not re-read either file prints 78/95 and this leg goes RED.
  # MEASURED under this very mutation, not arithmetic off the clean run.
  assert_stays_clean_why "GATE 2 — a flag added to BOTH solve.py and its CLI doc stays silent" cli \
    'solve\.py fully documented in documentation/SOLVE_PY_CLI\.md \(79 flag\(s\) compared against 96 documented' \
"p='solve.py'
a='    parser.add_argument(\"--pairs\", action=\"store_true\",'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
n='    parser.add_argument(\"--doc-gates-fireproof-neg\", action=\"store_true\", help=\"doc_gates --selftest injection; reverted by the harness\")\n'
open(p,'w',encoding='utf-8').write(s.replace(a,n+a,1))
d='documentation/SOLVE_PY_CLI.md'
t=open(d,encoding='utf-8').read()
open(d,'w',encoding='utf-8').write(t+'\ndoc_gates selftest injection: --doc-gates-fireproof-neg (reverted by the harness)\n')"

  # ITEM A4 (2026-08-02) — THE COMMENTED-OUT DECLARATION, PROVEN AS A MATCHED PAIR.
  #
  # The round-6 note recorded that a commented-out `# parser.add_argument("--x"` was emitted
  # as an undocumented flag (measured: it returned --commented-out-flag), and asked for a
  # decision rather than a rediscovery. Decided: NARROW — the reasoning is at the extractor.
  #
  # TWO LEGS WITH ONE FLAG NAME, and the pairing is the point. "Stays green" is also what a
  # gate prints when the injection never landed, when the extractor stopped working, and
  # when the whole comparison was silently disabled — so a lone negative control here would
  # be indistinguishable from the filter swallowing every flag in solve.py. The fire leg
  # injects `--doc-gates-fireproof-cmt` UNCOMMENTED and requires GATE 2 to name it; the
  # clean leg injects the SAME text COMMENTED OUT, one `# ` apart, and requires silence. The
  # only difference between the two runs is the comment marker, so the silence is
  # attributable to the marker and to nothing else.
  assert_fires_why "GATE 2 (A4) a LIVE declaration of the paired flag is still reported" cli \
    '--doc-gates-fireproof-cmt' \
"p='solve.py'
a='    parser.add_argument(\"--pairs\", action=\"store_true\",'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
n='    parser.add_argument(\"--doc-gates-fireproof-cmt\", action=\"store_true\", help=\"doc_gates --selftest injection; reverted by the harness\")\n'
open(p,'w',encoding='utf-8').write(s.replace(a,n+a,1))"

  # EVIDENCE (item B9): this is the leg a FLAG count could never discriminate — the whole
  # property under test is that the injected line does NOT become a flag, so `78 flag(s)
  # compared against 95 documented` is what a run that never looked would print too. The
  # census therefore carries a THIRD number for exactly this leg: commented-out declarations
  # DROPPED by the item-A4 filter, which is 0 on a clean tree and 1 under this mutation. The
  # ERE pins all three, so it now proves the line was read AND classified as a comment,
  # rather than that the mode exited 0.
  assert_stays_clean_why "GATE 2 (A4) the SAME declaration commented out is not a flag" cli \
    'solve\.py fully documented in documentation/SOLVE_PY_CLI\.md \(78 flag\(s\) compared against 95 documented, 1 commented-out declaration\(s\) dropped\)' \
"p='solve.py'
a='    parser.add_argument(\"--pairs\", action=\"store_true\",'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
n='    # parser.add_argument(\"--doc-gates-fireproof-cmt\", action=\"store_true\", help=\"doc_gates --selftest injection; reverted by the harness\")\n'
open(p,'w',encoding='utf-8').write(s.replace(a,n+a,1))"

  # A5/#65: assert the MATCHED STRING, not just the exit code. GATE 3's registry holds
  # morphology-independent stems, so several rows can be live at once and an exit code alone
  # cannot say which one saw the injection.
  assert_fires_why "GATE 3 retracted phrasing" retract \
    'matched as the fixed string: "hard floor k>=13"' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nThe ordering has a hard floor k>=13 by construction.\n')"

  # GATE 3b — THREE cases, and the positive one is its OWN MOTIVATING EXAMPLE rather than a
  # synthetic string. reports/evidence/r11/PHASE2_README.md is the artifact that actually
  # carried an uncorrected "1.4σ above" after TR-2 v1.19 retracted it, surviving until a
  # human read it on 2026-08-02 (TR-2 v1.23). The mutation puts that sentence back, as a bare
  # assertion with none of the narration the allowlist anchors on.
  assert_fires_why "GATE 3b retracted figure restated (its own motivating example)" \
    retract-figures 'retracted figure "1\.4σ" restated' \
"p='reports/evidence/r11/PHASE2_README.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nThe pooled value sits 1.4σ above the Phase-1 single run.\n')"

  # GATE 3b, LINE-BREAK EVASION. GATE 3's hardening note (a) records that a retracted phrase
  # once hid inside a hard wrap where line-based grep could not see it. GATE 3b matches
  # per-line so it can anchor exemptions, which reintroduces that exposure — the normalised
  # whole-file pass is the compensating branch, and this is the only thing that exercises it.
  assert_fires_why "GATE 3b retracted figure split across a hard wrap" \
    retract-figures 'spans a hard wrap' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nThe ledger prices C2 at marginal\n4.6 bits under that convention.\n')"

  # GATE 3b NEGATIVE CONTROL — the exemption must be driven by the ANCHOR, not by the file.
  # Same file as an existing allowlist row, same figure, and the row's anchor text present:
  # this must NOT fire. Without it, the [ok] above is equally consistent with the allowlist
  # having quietly exempted reports/evidence/ wholesale.
  # EVIDENCE (round 8 drain-3) — THE ONE MEASURED DISCRIMINATOR IN THE SIX. GATE 3b prints its
  # allowlisted-narration census, and that census MOVES when this injection is read: clean it
  # says `(1 historical, 44 meta-mention)`, under this mutation `45`. Both numbers were taken
  # from real runs in a scratch clone. So matching 45 proves the injected line was SEEN and
  # then EXEMPTED, which is the whole content of the claim; rc 0 alone is equally consistent
  # with the file having dropped out of the 79-file scan entirely.
  # DELIBERATELY COUNT-PINNED: if the corpus gains an allowlisted narration this FAILS loudly
  # and the number must be re-measured under the mutation. A range ERE would restore exactly
  # the blindness this argument is about.
  assert_stays_clean_why "GATE 3b negative control — an anchored narration is exempt" \
    retract-figures '45 meta-mention' \
"p='reports/evidence/r11/README.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nRestated for the index: this figure read 1.4σ until 2026-08-02.\n')"

  # FIRE-PROOF OF THE EVIDENCE HALF ITSELF (round 8 drain-3, item A1's residue). The six
  # negative controls above now claim to assert more than an exit code. Nothing above proves
  # that claim: all six are expected to pass, so all six would look identical if the ERE test
  # were inert — an `if` that never fails is exactly the shape GATE 8's one-directional
  # comparison had, and it survived because its fire-proof was taken by hand and never re-run.
  # So the failing direction runs here, every run.
  #
  # IT IS THE MOTIVATING DEFECT, NOT A STYLISED ONE. Same gate, same mutation, same green
  # run — scored against `44`, the census a run that NEVER READ the injected line prints.
  # That is precisely the state the corpus would be in if reports/evidence/r11/README.md were
  # renamed out of the 79-file scan: rc 0, [ok] under the old helper, and a negative control
  # that had silently stopped controlling anything.
  #
  # THE ASSERTION IS ON THE MESSAGE, NOT ON [FAIL]. A [FAIL] alone would also be produced by
  # the rc branch ("fired on a case it is supposed to leave alone"), so grepping for [FAIL]
  # would let a gate that broke for an unrelated reason stand in for the proof. It matches the
  # evidence branch's own sentence instead.
  #
  # PASS IS NOT CLOBBERED because the call runs inside a command substitution: the helper's
  # `PASS=1` dies with the subshell, while its `_selftest_revert` acts on the real tree and
  # persists. The expected [FAIL] text is captured, never printed.
  #
  # 44 AND 45 MOVE TOGETHER. Both come from the same pair of runs; if the corpus gains an
  # allowlisted narration, the live assertion above FAILS loudly and BOTH numbers must be
  # re-taken from real runs — the probe's number is the clean census, the assertion's is the
  # census under the mutation.
  _asc_probe=$(assert_stays_clean_why \
    "PROBE (expected to FAIL) — a green run scored against the census of a run that never read the injection" \
    retract-figures '44 meta-mention' \
"p='reports/evidence/r11/README.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nRestated for the index: this figure read 1.4σ until 2026-08-02.\n')")
  if printf '%s' "$_asc_probe" | grep -q 'stayed green, but its output never names'; then
    echo "  [ok]   assert_stays_clean_why — a gate that stays green WITHOUT printing the"
    echo "         evidence line is a FAIL, so every negative control on it asserts more than"
    echo "         rc 0 (the COUNT is not restated here — it said six against a live seven,"
    echo "         and a stale number in PRINTED output is worse than one in a comment; the"
    echo "         authority is callers=N in DOC_GATE_SELFTEST_INSTRUMENTS.txt)"
  else
    echo "  [FAIL] assert_stays_clean_why — the evidence half is INERT. A green run that never"
    echo "         read the injected case was accepted, so every negative control in this"
    echo "         harness is back to asserting an exit code. Probe output:"
    printf '%s\n' "$_asc_probe" | head -3 | sed 's/^/           > /'
    PASS=1
  fi

  # DISPATCH NOTE (item A1, round 8; CORRECTED item B2, round 9, 2026-08-02). `links` is
  # gate_links_and_secrefs, i.e. GATE 4 AND GATE 4b behind one exit code. This used to be an
  # exit-code assertion and was therefore satisfied by a GATE 4b failure — the shared-dispatch
  # class GATES 10a/10b and 11-figures each got their own dispatch name for. Round 8 answered
  # that with an ERE instead of a dispatch name — "GATE 4's OWN line for the injected target,
  # so no third dispatch name is needed" — and the argument was TRUE and MEASURED (drain-2
  # confirmed the string is emitted nowhere in gate_secrefs, which is why this was latent and
  # not a live defect). It is retired anyway, because it was an argument about wording holding
  # a structural property: reword GATE 4b's finding line into the same shape and the assertion
  # silently stops distinguishing the two, with nothing looking. It now runs `links-internal`,
  # GATE 4 alone, and GATE 16 LEG 2 refuses a fire-proof on a combined name mechanically.
  assert_fires_why "GATE 4 internal links (documentation/GUIDE.md)" links-internal \
    'documentation/GUIDE\.md -> NO_SUCH_FILE_XYZ\.md +\(no such file\)' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nSee [the missing doc](NO_SUCH_FILE_XYZ.md).\n')"

  # GATE 4b, in the EXACT shape of its motivating defect: the link target resolves
  # (CRITIQUE.md exists, so phase 1 stays green) and only the section half is dead.
  # If this assertion ever passes-through, the extension has stopped seeing the one
  # class it was written for. The quoted form §\"...\" was verified by the same
  # method when the gate was written.
  #
  # DISPATCH (corrected 2026-08-02, item A3): this used to run `links`, which is GATE 4
  # AND 4b behind one exit code — so a phase-1 failure for any unrelated reason would
  # have satisfied the assertion with 4b never fired, printing [ok] for an unexercised
  # gate. It now runs `secrefs`, which is 4b alone; no other gate can supply that
  # exit code. (Compensated manually once, with phase 1 verified green by hand — a
  # by-hand guarantee the permanent assertion did not carry, which is the same shape as
  # GATE 8's hand-taken fire-proof going stale across a refactor.)
  # A5/#65: also assert the WHY line, which names the target file and the normalised text
  # that failed to resolve. 4b has an allowlist, so an exit code alone cannot distinguish
  # "fired on my injection" from "fired on a pre-existing entry that fell out of the list".
  # ERE re-anchored 2026-08-02 (item B1) because the WHY line changed when the gate learned a
  # second anchor form: it no longer says "no heading", it says nothing is NAMED that, and the
  # distinction is the whole point of the change. Re-proven by running --selftest after the
  # rewrite — the exact failure mode GATE 8's stale hand-taken proof is on record for.
  assert_fires_why "GATE 4b dangling section ref" secrefs \
    'WHY: nothing in documentation/CRITIQUE\.md is named "q7"' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nPriced as data ([CRITIQUE.md](CRITIQUE.md) Q7).\n')"

  # ITEM A7 — GATE 4b's AMBIGUITY note, proven on the corpus's own weakest reference.
  #
  # documentation/HISTORY.md:4987 carries `MCKENNA.md §"Rule 2"`, which today resolves against
  # exactly one heading ("mckenna's rule 2 - declined for promotion to formal c-rule",
  # coverage ratio 0.10 — the weakest in the corpus). A7's hazard is stated in exactly these
  # terms: `§"Rule 2"` would ALSO resolve against a heading `"Rule 25"`. So the mutation adds
  # that heading and nothing else, and the note must appear.
  #
  # WHY THIS IS AN OUTPUT ASSERTION, not assert_fires_why: the note is REPORT-ONLY by design
  # (see the gate's A7 block), so `secrefs` still exits 0 and an rc-based assertion would fail
  # on a working gate. The injected heading creates no dangling reference, so rc 0 is also the
  # correct verdict — asserting on rc would prove the opposite of what is wanted.
  python3 -c "p='documentation/MCKENNA.md'
s=open(p,encoding='utf-8').read()
import re
h=[x for x in re.findall(r'^#+\s+(.*?)\s*\$', s, re.M) if 'Rule 2' in x]
assert len(h)==1, 'anchor moved: %d headings contain \"Rule 2\", expected exactly 1' % len(h)
open(p,'w',encoding='utf-8').write(s+chr(10)+chr(10)+'## McKenna Rule 25 (self-test heading)'+chr(10))" 2>/dev/null \
    && { A7OUT=$(bash "$0" secrefs 2>&1); A7RC=$?
         if [ "$A7RC" -eq 0 ] \
            && printf '%s' "$A7OUT" | grep -q 'resolves against 2 headings, so it does' \
            && printf '%s' "$A7OUT" | grep -q 'mckenna rule 25 (self-test heading)'; then
           echo "  [ok]   GATE 4b ambiguity note — a second matching heading is reported, and named"
         else
           echo "  [FAIL] GATE 4b did not note an ambiguous resolution (rc=$A7RC). A reference that"
           echo "         matches two headings identifies neither, which is the A7 hazard."
           printf '%s\n' "$A7OUT" | grep -E 'note|FAIL' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert documentation/MCKENNA.md; } \
    || { echo "  [FAIL] GATE 4b ambiguity case — could not inject; assertion did NOT run."; PASS=1; }

  # ITEM B1 (2026-08-02, drain-2) — FOUR LEGS, EACH PROVEN LOAD-BEARING BY DELETING WHAT IT
  # DEPENDS ON. Three of them widen the gate, and a widened gate is how a false clear gets
  # built, so none of them is asserted by "the corpus is green now" — each is asserted by a
  # mutation that must turn it red.

  # LEG 1, the bold-anchor form, proven on its own motivating example and in the DIRECTION
  # that matters. Asserting that METHODS.md §"Global observable ledger" resolves would be
  # satisfied by a gate that resolves everything; instead the anchor's `**` markers are
  # STRIPPED, which must break the five references that depend on them. If this ever stops
  # firing, the bold leg has become decorative and those five are resolving some other way.
  assert_fires_why "GATE 4b LEG 1: bold anchors are load-bearing (strip METHODS' label)" secrefs \
    'nothing in reports/METHODS\.md is named "global observable ledger"' \
"p='reports/METHODS.md'
s=open(p,encoding='utf-8').read()
a='- **Global observable ledger (enterprise-wide multiple comparisons).**'
assert s.count(a)==1, 'anchor moved: found %d occurrences' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'- Global observable ledger (enterprise-wide multiple comparisons).',1))"

  # LEG 2, the SCOPE of leg 1 — the negative control without which leg 1's [ok] is equally
  # consistent with "any bold text anywhere is an anchor". A line-leading label is an anchor;
  # emphasis in the middle of a sentence is not, and the corpus is full of the latter. Same
  # bold text, same file, mid-line: this must still be reported dangling.
  assert_fires_why "GATE 4b LEG 2: mid-line bold is NOT an anchor" secrefs \
    'nothing in documentation/GUIDE\.md is named "frobnicate the widget xyz"' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'Prose that mentions **Frobnicate the widget xyz** part-way through a sentence.'+chr(10)+chr(10)+'See [GUIDE.md](GUIDE.md) '+chr(167)+'\"Frobnicate the widget xyz\" for that.'+chr(10))"

  # LEG 3, the backtick path. Before this commit `\s*` could not cross the closing backtick,
  # so a reference written `` `documentation/X.md` §\"...\" `` was not extracted AT ALL — not
  # passed, not failed, invisible. One of the corpus's two was dead
  # (PARTITION_STABILITY_BOUNDARIES.md:83, pointing at a section de3422b had relocated).
  assert_fires_why "GATE 4b LEG 3: a backticked path no longer hides a dead reference" secrefs \
    'nothing in documentation/CRITIQUE\.md is named "no such section zzz"' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'See \`documentation/CRITIQUE.md\` '+chr(167)+'\"no such section zzz\" for that.'+chr(10))"

  # LEG 4, the two-line window. Same invisibility, different mechanism: the scan was
  # line-at-a-time, so a hard wrap between the file name and its §\"…\" hid the reference
  # completely. GATE 3's hardening note (a) records the identical evasion for a different
  # gate; MEASURED here, it was hiding 15 of 85 references, one of them dead
  # (SYMMETRY_SEARCH.md:275).
  assert_fires_why "GATE 4b LEG 4: a hard wrap no longer hides a dead reference" secrefs \
    'nothing in documentation/CRITIQUE\.md is named "no such wrapped section qqq"' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'See [CRITIQUE.md](CRITIQUE.md)'+chr(10)+chr(167)+'\"no such wrapped section qqq\" for that.'+chr(10))"

  # LEG 5, STALE ALLOWLIST ROWS. This commit retired 19 of 22 rows at once, which is exactly
  # the moment a dead exemption gets left behind — so the check against that ships with it.
  # The injected row exempts a reference that does not exist, which is what a row left over
  # from a fixed defect looks like, and it must be refused rather than quietly carried.
  assert_fires_why "GATE 4b LEG 5: an allowlist row that exempts nothing is refused" secrefs \
    'stale allowlist row: documentation/GUIDE\.md -> documentation/CRITIQUE\.md' \
"p='documentation/DOC_GATE_SECREF_ALLOWLIST.txt'
s=open(p,encoding='utf-8').read()
t=chr(9)
open(p,'w',encoding='utf-8').write(s+'documentation/GUIDE.md'+t+'documentation/CRITIQUE.md'+t+'a section nobody cites'+t+'self-test: exempts nothing'+chr(10))"

  # ITEM B1, PHASE-4 ON THIS UNIT'S OWN BATCH. Legs 1-5 all assert that the gate goes RED when
  # something is broken. NONE of them asserts the promise the bold leg was allowed to ship on:
  # that a bold-anchor resolution is PRINTED rather than cleared. Delete the [bold-anchor] loop
  # and every leg above still passes, while eighteen weak resolutions become invisible — the
  # exact "clears are weaker than failures" outcome the leg's own comment argues against.
  #
  # So this asserts the REPORT, on a reference the corpus has never contained: the gate must
  # stay GREEN (it resolves) and must NAME it. Both halves are load-bearing — rc alone would be
  # satisfied by a gate that skipped the reference entirely, and the grep is anchored to
  # GUIDE.md because the same bold label is already reported for two other files, so an
  # unanchored match would be satisfied by output that has nothing to do with the injection.
  #
  # PROVEN DISCRIMINATING, not assumed (2026-08-02): the same injection was run against a COPY
  # of this script with the [bold-anchor] print loop deleted and nothing else changed. The
  # anchored grep counted 1 against the live script and 0 against the copy, while the copy
  # still exited 0 — i.e. the deletion produces exactly the silent green this asserts against.
  # An assertion that has never been shown to fail is not a proof, which is the whole reason
  # GATE 8 shipped a one-directional comparison.
  python3 -c "p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'See [CRITIQUE.md](CRITIQUE.md) '+chr(167)+'\"Per-branch yield labels in the canonical\" for that.'+chr(10))" 2>/dev/null \
    && { B1OUT=$(bash "$0" secrefs 2>&1); B1RC=$?
         if [ "$B1RC" -eq 0 ] \
            && printf '%s' "$B1OUT" | grep -qE '\[bold-anchor\] documentation/GUIDE\.md:[0-9]+ -> documentation/CRITIQUE\.md'; then
           echo "  [ok]   GATE 4b LEG 6: a bold-anchor resolution is REPORTED, not cleared"
         else
           echo "  [FAIL] GATE 4b LEG 6 — a reference resolving only via the weaker anchor form was"
           echo "         not named in the output (rc=$B1RC). Resolving it silently is the clear"
           echo "         this leg was allowed to ship on the promise of never producing."
           printf '%s\n' "$B1OUT" | grep -E 'bold-anchor|FAIL' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert documentation/GUIDE.md; } \
    || { echo "  [FAIL] GATE 4b LEG 6 — could not inject; assertion did NOT run."; PASS=1; }

  # ITEM B4 (2026-08-02, drain-1) — LEG 7, the PREFIX RULE, proven on the REAL defect that
  # motivated it rather than on a synthesised one. `f3179f8` measured prefix anchoring at 1 of
  # 18 and then FIXED that one, so by the time the rule shipped its population was 0 — which is
  # exactly the situation in which a new gate can ship decorative and nobody notices. The
  # mutation therefore re-injects the historical defect verbatim: CITATIONS.md's reference to
  # SPECIFICATION.md's wrap-around-parity theorem, narrowed back to the form that resolved at
  # OFFSET 9 inside "theorem (wrap-around parity is odd)".
  #
  # BOTH HALVES ARE LOAD-BEARING. rc alone would be satisfied by any unrelated failure the
  # mutation happened to cause, so the ERE pins the gate's own WHY on this exact target.
  #
  # WHICH CLAUSE IS LOAD-BEARING WAS RE-VERIFIED 2026-08-02 (round 10, drain-2), AND THE
  # STANDING MAINTENANCE NOTE CARRIED INTO ROUND 10 NAMED THE WRONG ONE. That note said this
  # proof is meaningful only while the ERE remains the gate's FAIL wording "no line-leading
  # bold label BEGINS with it". IT IS NOT THAT STRING. That phrase occurs exactly ONCE in
  # this file, in the WHY message itself, and NO assertion anywhere asserts on it. The ERE
  # below is the message's FIRST clause, `nothing in <doc> is named "<normalised section>"`,
  # and what makes it unprintable by a build without the prefix rule is not its wording but
  # its TARGET: without the rule the mutated reference RESOLVES, at offset 9 inside a bold
  # label, so the gate prints nothing about it at all.
  #
  # THE MAINTENANCE CONDITION IS THEREFORE, EXACTLY: re-take this proof from a run if the
  # `nothing in {d} is named "{norm(s)}"` clause is reworded, if `norm()` changes what the
  # section title normalises to, or if this reference gains an allowlist row (which would
  # route it to [OPEN] instead of [FAIL]). Rewording the prefix-rule clause does NOT void it.
  # Recording the wrong trigger is worse than recording none: it invites a future unit to
  # rewrite the clause that IS load-bearing believing the proof does not depend on it.
  #
  # WHAT IT DOES NOT PROVE, both directions: that no OTHER weak resolution exists — the leg
  # covers the one form the corpus is known to have produced; and that no OTHER finding in
  # the same `secrefs` output could print the same line. The second rests on GATE 4b being
  # GREEN on the clean tree, so the mutated reference is the only unresolved citation of that
  # target in the run. That is a real argument and it is a standing one, re-established by
  # every green `all`, but it is an argument about the corpus rather than a check.
  assert_fires_why "GATE 4b LEG 7: a bold label matched mid-text is not an anchor" secrefs \
    'nothing in documentation/SPECIFICATION\.md is named "wrap-around parity"' \
"p='documentation/CITATIONS.md'
s=open(p,encoding='utf-8').read()
a='[SPECIFICATION.md](SPECIFICATION.md) '+chr(167)+'\"Theorem (Wrap-around parity is odd)\"'
assert s.count(a)==1, 'anchor moved: found %d occurrences' % s.count(a)
b='[SPECIFICATION.md](SPECIFICATION.md) '+chr(167)+'\"wrap-around parity\"'
open(p,'w',encoding='utf-8').write(s.replace(a,b,1))"

  # ITEM A6 — the corpus-wide final-newline PREFLIGHT, proven on a file whose own gate does
  # NOT check it. RETRACTED_FIGURES.tsv would be the obvious target and is the wrong one:
  # GATE 11 already guards it, so the case would pass with the preflight deleted.
  # DOC_GATE_SECREF_ALLOWLIST.txt has no such guard, and — measured — is read by python file
  # iteration, which does not drop an unterminated line, so NOTHING but the preflight can be
  # what answers here. The ERE is the preflight's own wording, which deliberately shares no
  # substring with require_final_newline's ("does not end with a newline"), so GATE 11's
  # fire-proof and this one cannot be satisfied by each other's output.
  assert_fires_why "A6 preflight: a gate-support file loses its final newline" secrefs \
    'gate-support file has no final newline: documentation/DOC_GATE_SECREF_ALLOWLIST\.txt' \
"p='documentation/DOC_GATE_SECREF_ALLOWLIST.txt'
s=open(p,encoding='utf-8').read()
assert s.endswith(chr(10)), 'anchor moved: the file does not currently end with a newline'
open(p,'w',encoding='utf-8').write(s[:-1])"

  # A5/#65: assert the matched string AND that a file:line is cited (the location GATE 6
  # did not print until 2026-08-02). `\.py:[0-9]` is what proves the location half.
  assert_fires_why "GATE 6 figure generators" figures \
    'matched as the fixed string: "hard floor k>=13"' \
"import glob,sys
c=[f for f in glob.glob('viz/*.py')]
sys.exit(1) if not c else None
s=open(c[0]).read()
open(c[0],'w').write(s+'\n# hard floor k>=13\n')"

  # ITEM A8: the FIGURE half of GATE 6. The phrase assertions above cannot cover it — they
  # inject a registered PHRASE, which the phrase loop would catch whether or not the figure
  # loop exists. This injects a registered STATISTIC, which nothing in this repo could see
  # before today: GATE 3b is markdown-only, and matplotlib renders the annotation to glyph
  # paths. The assertion names the registry's own string so it cannot be satisfied by the
  # phrase leg firing.
  assert_fires_why "GATE 6 a retracted FIGURE annotated into a generator (item A8)" figures \
    'retracted FIGURE in a figure generator: "~5,500×"' \
"import glob,sys
c=sorted(glob.glob('viz/*.py'))
sys.exit(1) if not c else None
s=open(c[0],encoding='utf-8').read()
open(c[0],'w',encoding='utf-8').write(s+chr(10)+'# annotate(\"rarer by ~5,500× than chance\")'+chr(10))"

  # ITEM A8 + A1: the figure registry's own missing-input leg. Absent registry, absent check
  # — and the message must name THIS registry, not the phrase one, or a maintainer restores
  # the wrong file.
  assert_fires_why "GATE 6 (A1) figure registry deleted" figures \
    'RETRACTED_FIGURES\.tsv is tracked in git but missing from the working tree' \
"import os
f='documentation/RETRACTED_FIGURES.tsv'
assert os.path.exists(f), 'anchor moved'
os.remove(f)"

  assert_fires_why "GATE 6 figure generators name the LINE, not just the file" figures \
    'viz/.*\.py:[0-9]+  — regenerate' \
"import glob,sys
c=[f for f in glob.glob('viz/*.py')]
sys.exit(1) if not c else None
s=open(c[0]).read()
open(c[0],'w').write(s+'\n# hard floor k>=13\n')"

  # A5/#65: GATE 7's LIVE list has seven keywords and its DISPO suppression list has
  # sixteen; the finding line names the keyword that matched, and that is what this asserts.
  assert_fires_why "GATE 7 frozen run status" liveness \
    'status frozen in the present tense: "in flight"' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nThe ladder build is in flight and the log is 3,666 lines and growing.\n')"

  # A5/#65: 1120T is the MENTIONED-but-sha-less shape, not the absent-from-registry shape,
  # and the two need different fixes — so assert the branch, not just the failure.
  assert_fires_why "GATE 7 unreached budget" liveness \
    'with no sha256 within' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nThe 1120T run reproduced the published ladder exactly.\n')"

  # GATE 9, in the EXACT shape the operator specified: a SYNTHETIC SINGLE-FILE EDIT.
  # The injected change is one space — whitespace only, still valid markdown, still
  # closing its italic, and semantically identical. A gate that normalised whitespace
  # (the obvious "robustness" tweak) would pass this and would not be a byte-identity
  # gate at all. If this assertion ever stops firing, the gate has stopped being one.
  # The ERE names the byte-identity verdict AND its variant COUNT: one mutated cover means
  # exactly 2 variants, so a gate that had stopped comparing and failed for some other
  # reason (a missing marker, an unclosed italic) cannot satisfy this.
  assert_fires_why "GATE 9 banner drift (1 byte, 1 file)" banner \
    'the banner is NOT byte-identical: 2 variants in use' \
"s=open('reports/TR5_SYMMETRY.md').read()
a='interpretation are argued, not verified.*'
assert a in s, 'anchor moved'
open('reports/TR5_SYMMETRY.md','w').write(s.replace(a,'interpretation are argued, not verified. *',1))"

  # GATE 9's second branch: the 11 covers can be perfectly uniform while the INDEX
  # drifts back to a blanket promise. Byte-identity across the reports cannot see
  # that, so the branch is exercised separately — an unexercised branch is untested.
  # The ERE names the INDEX leg specifically. Both GATE 9 branches live behind one dispatch
  # name and one exit code, so an exit-code assertion here was satisfiable by the cover
  # byte-identity branch above — the two assertions could not be told apart.
  assert_fires_why "GATE 9 index drops the scope clause" banner \
    'reports/README\.md:[0-9]+ — index banner lacks "argued, not verified"' \
"s=open('reports/README.md').read()
a='interpretation are argued, not verified.'
assert a in s, 'anchor moved'
open('reports/README.md','w').write(s.replace(a,'interpretation are sound.',1))"

  # GATE 10 POSITIVE: deleting a committed line from the corrections ledger must fire it.
  # The deleted line is chosen from the middle of the file rather than the end, so the
  # assertion cannot be satisfied by a "file got shorter" check that would miss a
  # reword-in-place — the defect this gate actually exists for.
  # DISPATCH (2026-08-02, item A7): `appendonly-head`, not `appendonly`. Since 10b landed,
  # `appendonly` is two gates behind one exit code and this assertion would be satisfiable
  # by either — the same untested-test shape A3 fixed for GATE 4b.
  assert_fires_why "GATE 10a append-only vs HEAD (committed line deleted)" appendonly-head \
    '1 committed line\(s\) no longer present' \
"L=open('documentation/CORRECTIONS.md').read().split(chr(10))
assert len(L) > 60, 'ledger too short to mutate meaningfully'
del L[len(L)//2]
open('documentation/CORRECTIONS.md','w').write(chr(10).join(L))"

  # GATE 10 NEGATIVE CONTROL. An APPEND must NOT fire it. Without this the [ok] above
  # proves only that the gate is capable of failing, not that it is capable of passing
  # — and a gate that always fails is turned off within a day, which is how the
  # container-level exemptions in this file got there in the first place.
  python3 -c "open('documentation/CORRECTIONS.md','a').write(chr(10)+'### CX-selftest — an appended line.'+chr(10))" 2>/dev/null \
    && { if bash "$0" appendonly >/dev/null 2>&1; then
           echo "  [ok]   GATE 10 negative control — a pure APPEND does not fire it"
         else
           echo "  [FAIL] GATE 10 fired on a pure append; it is not an append-only gate"
           bash "$0" appendonly 2>&1 | sed 's/^/           > /' | head -5
           PASS=1
         fi
         _selftest_revert; } \
    || { echo "  [FAIL] GATE 10 negative control — could not append to the ledger, so the"
         echo "         assertion did NOT run (item A5)."; PASS=1; }

  # =========================================================================
  # GATE 10b — THREE assertions (added 2026-08-02, item A7), because they prove three
  # different things and the first one alone would have passed on the BROKEN gate.
  #
  # (i) runs in the real tree and proves the DETECTOR works. It is dispatched to
  #     `appendonly-history`, which is 10b alone — the A3 lesson applied here, since a
  #     deleted line fires 10a too and a shared dispatch name would let the assertion be
  #     satisfied by the half that was never in question.
  #
  # (ii) and (iii) are the DIFFERENTIATORS, and they cannot be staged in this repo: the
  #     defect A7 reports only exists once the removal has been COMMITTED (ii) or the
  #     history REWRITTEN (iii), and the self-test may do neither to the real tree. They
  #     are staged in throwaway repos built by `cp "$0"` — so they exercise THIS script,
  #     not a re-implementation of it, which is the difference between a fire-proof and a
  #     clever proxy.
  assert_fires_why "GATE 10b vs history (a line of the OLDEST committed version deleted)" \
    appendonly-history '1 line\(s\) present in .* are absent from the working copy' \
"import subprocess
f='documentation/CORRECTIONS.md'
revs=subprocess.run(['git','rev-list','HEAD','--',f],capture_output=True,text=True).stdout.split()
assert revs, 'the ledger has no history to test against'
old=subprocess.run(['git','show',revs[-1]+':'+f],capture_output=True,text=True).stdout.split(chr(10))
cur=open(f,encoding='utf-8').read().split(chr(10))
cand=[l for l in old if l.strip() and l in cur]
assert cand, 'no line of the oldest committed version survives to delete'
cur.remove(cand[len(cand)//2])
open(f,'w',encoding='utf-8').write(chr(10).join(cur))"

  # scratch_appendonly <label> <setup-shell-run-inside-the-scratch-repo>
  #   Asserts BOTH verdicts at once: 10a must be GREEN (that is the blindness A7 reports)
  #   and 10b must be RED (that is the fix). Asserting only 10b would still pass in a
  #   world where 10a had caught it — and "10a does not catch it" is the whole claim.
  scratch_appendonly() {
    local label="$1" setup="$2" d rcA rcB rcS
    d=$(mktemp -d) || { echo "  [SKIP] $label — no tmpdir"; return; }
    ( set -e
      mkdir -p "$d/scripts" "$d/documentation"
      cp "$0" "$d/scripts/doc_gates.sh"
      cd "$d"
      export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@invalid
      export GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@invalid
      git init -q .
      git symbolic-ref HEAD refs/heads/main
      printf 'CX-1 first entry.\nCX-2 second entry.\nCX-3 third entry.\n' \
        > documentation/CORRECTIONS.md
      git add -A && git commit -qm 'ledger: three entries'
      eval "$setup" ) >/dev/null 2>&1; rcS=$?
    # ITEM A5: rc 3 is the ONE designed skip in this suite — case (iii) exits 3 when its
    # premise (the pre-rewrite commit is no longer an ancestor of HEAD) does not hold, and
    # skipping is then correct because the scenario would be testing nothing. Every OTHER
    # non-zero rc means `git init`, the seed commit or the setup itself broke, which is a
    # fire-proof that did not run. Those two were conflated behind one [SKIP] and one
    # message that ASSERTED the premise reading for both.
    if [ "$rcS" -eq 3 ]; then
      echo "  [SKIP] $label — premise does not hold here (setup exited 3 by design), so the"
      echo "         scenario would test nothing"
      rm -rf "$d"; return
    elif [ "$rcS" -ne 0 ]; then
      echo "  [FAIL] $label — scratch setup broke (rc=$rcS), so the assertion did NOT run"
      PASS=1; rm -rf "$d"; return
    fi
    ( cd "$d" && bash scripts/doc_gates.sh appendonly-head    >/dev/null 2>&1 ); rcA=$?
    ( cd "$d" && bash scripts/doc_gates.sh appendonly-history >/dev/null 2>&1 ); rcB=$?
    rm -rf "$d"
    if [ "$rcA" -eq 0 ] && [ "$rcB" -ne 0 ]; then
      echo "  [ok]   $label — 10a green on it (the blindness), 10b fires (the fix)"
    else
      echo "  [FAIL] $label — expected 10a rc=0 and 10b rc!=0; got 10a rc=$rcA, 10b rc=$rcB"
      PASS=1
    fi
  }

  # (ii) COMMIT THE REMOVAL — no unusual git required, which is why it is the likelier of
  #      the two. After the second commit the working copy and HEAD agree perfectly.
  scratch_appendonly "GATE 10b vs a COMMITTED removal (working copy == HEAD)" \
"printf 'CX-1 first entry.\nCX-3 third entry.\n' > documentation/CORRECTIONS.md
git add -A && git commit -qm 'tidy: drop CX-2'"

  # (iii) HISTORY REWRITE. This is the case an ancestor-walk alone CANNOT close, and the
  #       setup asserts that premise rather than assuming it: if the pre-rewrite commit
  #       were still an ancestor of HEAD the walk would see it, the scenario would be
  #       testing nothing, and the setup exits 3 so the case reports [SKIP] instead of a
  #       false [ok]. With the premise held, refs/remotes/origin/main is the only baseline
  #       still holding the dropped line.
  scratch_appendonly "GATE 10b vs an AMEND that drops a PUBLISHED line" \
"git update-ref refs/remotes/origin/main HEAD
orig=\$(git rev-parse HEAD)
printf 'CX-1 first entry.\nCX-3 third entry.\n' > documentation/CORRECTIONS.md
git add -A && git commit -q --amend -m 'ledger: three entries'
if git merge-base --is-ancestor \"\$orig\" HEAD; then exit 3; fi"

  # GATE 11: a registry row with no ledger entry must fire it. Injected as a NEW registry
  # row rather than by deleting a ledger entry, because deletion would fire GATE 10 and
  # the assertion would pass for the wrong reason — the two gates must be shown to be
  # independent, not merely both red.
  # DISPATCH NOTE (item A1, round 8; RE-POINTED item B2, round 9): `ledger` is phrases AND
  # figures behind one exit code, and the figures pass already carries [OPEN] rows — so an
  # exit-code assertion here was satisfiable by the figures half and would have stayed green
  # with the phrases pass deleted. Round 8 defended that with the ERE alone (it names the
  # PHRASES leg's own line, which the figures leg cannot print). Round 9 added the LEAF
  # dispatch name `ledger-phrases`, so the defence is now structural as well: this assertion
  # runs one gate function, and a reader does not have to verify an ERE's provenance to see
  # it. The RP key is matched as a pattern, never hardcoded: a sha copied out of a run into a
  # fire-proof is the shape this project bans everywhere else, and the registry note is
  # deliberately NOT in the ERE, since that string is the mutation's own source text.
  assert_fires_why "GATE 11 ledger completeness (unrecorded retraction)" ledger-phrases \
    'RP-[0-9a-f]+ has NO entry in documentation/CORRECTIONS\.md' \
"open('documentation/RETRACTED_PHRASES.tsv','a').write(
 'a synthetic phrasing that was never published'+chr(9)+'__none__'+chr(9)+'Self-test row: no ledger entry exists for it, so GATE 11 must fail.'+chr(10))"

  # GATE 11 FIGURES PASS — three fire-proofs (item A5, 2026-08-02).
  #
  # Each targets `ledger-figures`, not `ledger`. The combined dispatch runs BOTH passes, so
  # an assertion on its exit code is satisfied by the phrases pass failing and would stay
  # green if this whole pass were deleted — the GATE 4b lesson, applied at the point where
  # it would otherwise be repeated.
  #
  # CASE 1 is the item's own concern: a figure registered TODAY, with nobody having written
  # anything anywhere, must fail. CASE 2 proves what is holding the seven known-open rows
  # green — delete one row from the open list and its figure fails immediately, so the file
  # is load-bearing rather than decorative. CASE 3 is the missing-input class.
  assert_fires_why "GATE 11 (figures) a newly registered figure nobody recorded" ledger-figures \
'"a synthetic figure 9\.99sigma" has NO entry' \
"open('documentation/RETRACTED_FIGURES.tsv','a').write(
 'a synthetic figure 9.99sigma'+chr(9)+'Self-test row: no ledger entry and no open-list row, so the figures pass must fail.'+chr(10))"

  assert_fires_why "GATE 11 (figures) an open-list row deleted stops holding its figure" ledger-figures \
'RF-1f093dc3 "\+125" has NO entry' \
"p='documentation/DOC_GATE_FIGURE_LEDGER_OPEN.txt'
L=open(p,encoding='utf-8').read().split(chr(10))
h=[i for i,x in enumerate(L) if x.startswith('+125'+chr(9))]
assert len(h)==1, 'anchor moved: %d rows' % len(h)
del L[h[0]]
open(p,'w',encoding='utf-8').write(chr(10).join(L))"

  # CASE 4 — the SILENT DROP. `while read` returns non-zero on an unterminated final line,
  # so a row appended without a trailing newline is registered and never checked, and the
  # gate prints [ok] with a count nobody compares against the file. Found by asking the
  # missing-input question of the READER rather than of the file. No live instance: all
  # three registries end in \n today, which is why this is a tripwire and is asserted here
  # rather than described in a comment.
  assert_fires_why "GATE 11 (figures) registry with no final newline drops its last row" ledger-figures \
'RETRACTED_FIGURES\.tsv does not end with a newline' \
"p='documentation/RETRACTED_FIGURES.tsv'
s=open(p,encoding='utf-8').read()
assert s.endswith(chr(10)), 'anchor moved: already unterminated'
open(p,'w',encoding='utf-8').write(s.rstrip(chr(10)))"

  assert_fires_why "GATE 11 (figures, A1) figure registry deleted" ledger-figures \
'RETRACTED_FIGURES\.tsv is tracked in git but missing' \
"import os
assert os.path.exists('documentation/RETRACTED_FIGURES.tsv'), 'anchor moved'
os.remove('documentation/RETRACTED_FIGURES.tsv')"

  # -----------------------------------------------------------------------
  # GATE 12 — FIVE fire-proofs and ONE negative control (2026-08-02, item A4).
  #
  # The gate has five independent legs and they do NOT subsume one another; the tree it was
  # written against proves it. TR-8's misordering broke the DATE order, TR-4's broke only
  # the VERSION order (both of its rows read 2026-08-01, because `a15c6dd` had already
  # corrected v1.16's future-dated stamp). A gate built to item A4's literal wording — "no
  # duplicate version number, exactly one *(current)*, dates ascending" — would have cleared
  # TR-4. So each leg gets its own assertion, and each mutation is chosen to fire ONE leg:
  # a duplicate that is also a version regression would pass an assertion that never
  # exercised the duplicate check.
  #
  # Every case asserts WHY (item A5 / #65). The negative control is not optional here — the
  # duplicate leg carries a suffix-keyed exemption, and without a control a green gate is
  # equally consistent with "the exemption is precise" and "the exemption swallows the
  # table".
  #
  # (1) DUPLICATE RELEASED VERSION — the motivating example: TR-1 shipped two v1.21 rows for
  #     a day. The mutation copies the PENULTIMATE row's version onto the last row, which
  #     leaves the order non-descending (equal, not backwards), the date untouched and the
  #     marker in place, so ONLY the duplicate leg can fire.
  #
  #     ANCHOR-FREE ON PURPOSE, and this is not a stylistic preference. The first version
  #     hardcoded `| v1.22 *(current)* |`, and four commits later the same unit appended TR-1
  #     v1.23 — the anchor was gone and the assertion could no longer inject. It reported
  #     [FAIL] rather than a silent pass, which is the harness working, but the fix is to stop
  #     writing a version number into a fire-proof for a table whose whole purpose is to grow.
  #     The evidence ERE is generic for the same reason; no other leg prints this sentence.
  assert_fires_why "GATE 12 duplicate released version (TR-1's real two-v1.21 defect)" revhist \
    'released version v[0-9.]+ is already used at line' \
"f='reports/TR1_EIGHT_CENTURIES_MEASURED.md'
lines=open(f,encoding='utf-8').read().split(chr(10))
h=[n for n,l in enumerate(lines) if l.strip()=='## Revision history']
assert len(h)==1, 'no single revision-history heading'
rows=[n for n in range(h[0],len(lines)) if lines[n].startswith('| v')]
assert len(rows)>=2, 'need two rows to duplicate one onto the other'
prev=lines[rows[-2]].split('|')[1].strip()
last=lines[rows[-1]].split('|')
assert '(current)' in last[1], 'the last row is not the current one'
last[1]=' '+prev+' *(current)* '
lines[rows[-1]]='|'.join(last)
open(f,'w',encoding='utf-8').write(chr(10).join(lines))"

  # (2) DATES BACKWARDS — TR-8's shape. Back-date the last row only; its version stays the
  #     highest and the marker stays last, so no other leg can account for the firing.
  assert_fires_why "GATE 12 a row dated before the row above it" revhist \
    'dates run BACKWARDS: 2026-07-31 \(row above\) then 2020-01-01' \
"f='reports/TR3_REPRODUCIBLE_ENUMERATION.md'
s=open(f,encoding='utf-8').read()
a='| v1.9 *(current)* | 2026-08-01 |'
assert a in s, 'anchor moved'
open(f,'w',encoding='utf-8').write(s.replace(a,'| v1.9 *(current)* | 2020-01-01 |',1))"

  # (3) VERSIONS BACKWARDS — TR-4's shape, the one the date leg is blind to. Raising an
  #     EARLY row above its successor (v1.2 -> v1.9 in a file that stops at v1.7) keeps every
  #     date untouched and introduces no duplicate, so this fires the version leg alone.
  assert_fires_why "GATE 12 versions out of order with every date legitimate" revhist \
    'versions run BACKWARDS: v1\.9 \(row above\) then v1\.3' \
"f='reports/TR6_PARITY_SKELETON.md'
s=open(f,encoding='utf-8').read()
a='| v1.2 | 2026-07-04 | Figures added |'
assert a in s, 'anchor moved'
open(f,'w',encoding='utf-8').write(s.replace(a,'| v1.9 | 2026-07-04 | Figures added |',1))"

  # (4) *(current)* NOT LAST — the leg that caught TR-4. Moving the marker up one row keeps
  #     the count at exactly one, so the count leg cannot be what fires.
  assert_fires_why "GATE 12 the *(current)* marker is not on the last row" revhist \
    'is not the LAST revision row' \
"f='reports/TR7_CIRCULAR_READING.md'
s=open(f,encoding='utf-8').read()
a='| v2.2 *(current)* |'
b='| v2.1 |'
assert a in s and b in s, 'anchor moved'
open(f,'w',encoding='utf-8').write(s.replace(a,'| v2.2 |',1).replace(b,'| v2.1 *(current)* |',1))"

  # (5) MISSING INPUT (item A1's class, applied to the new gate before it can grow the
  #     hole). The gate enumerates from `git ls-files` and opens from the worktree, so a
  #     deleted tracked TR is a FAIL naming the file — NOT a silently shorter list. The
  #     corpus preflight also fires here; the assertion targets GATE 12's own wording so it
  #     cannot be satisfied by the preflight's.
  assert_fires_why "GATE 12 (A1) a tracked TR deleted from the worktree" revhist \
    'TR6_PARITY_SKELETON\.md is tracked but could not be read' \
"import os
f='reports/TR6_PARITY_SKELETON.md'
assert os.path.exists(f), 'anchor moved'
os.remove(f)"

  # (6) NEGATIVE CONTROL for the duplicate leg's exemption. TR-11 legitimately carries three
  #     `v1.0-draft` rows; a FOURTH must still be clean, and the exemption must be doing that
  #     because of the SUFFIX. Case (1) above is the other half: strip the suffix and the
  #     same duplicate is a FAIL.
  # EVIDENCE (round 8 drain-3, UPGRADED round 9 item B9): the duplicate-version clause of
  # GATE 12's own pass line pinned that the leg which WOULD have flagged this row ran, and
  # nothing more — GATE 12 counted FILES, and a file count does not move when a row is
  # inserted. It now counts ROWS: 158 clean, and this mutation inserts exactly one, so the
  # ERE below pins 159 and a run that never re-read TR-11 goes RED.
  # WHAT IT STILL DOES NOT PROVE, since a clear is weaker than a failure: that the inserted
  # row was tested for the DRAFT-suffix exemption specifically. It proves it was PARSED as a
  # row and that no duplicate-release finding came out of the file it went into.
  assert_stays_clean_why "GATE 12 a repeated DRAFT label is exempt (suffix-keyed, not file-keyed)" revhist \
    '11 TR revision histories, 159 revision row\(s\) checked: .* no repeated released version' \
"f='reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md'
lines=open(f,encoding='utf-8').read().split(chr(10))
i=[n for n,l in enumerate(lines) if l.startswith('| v1.0-draft | 2026-07-05 |')]
assert len(i)==1, 'anchor moved'
lines.insert(i[0]+1,'| v1.0-draft | 2026-07-05 | Self-test row: a repeated DRAFT label is legitimate. |')
open(f,'w',encoding='utf-8').write(chr(10).join(lines))"

  # GATE 13 (item A4). Four assertions, and the third is the one that matters: it is not a
  # mutation at all but a REAL COMMIT — `b5bcff7c`, the 2026-07-25 one-line edit to TR-4 §3
  # that shipped with no revision row and that TR-4 v1.13 exists to record after the fact.
  # A synthetic injection proves the classifier reacts to something; pointing the gate at the
  # defect it was written for proves it reacts to THAT. Both directions are asserted, because
  # a one-directional fire-proof is exactly what GATE 8 shipped behind (see this file's
  # header) — 00c0db0 touched the same two TRs and gave BOTH a row, so it must stay silent.
  #
  # THE RANGE IS PINNED ON EVERY ASSERTION, including the worktree ones, where it is set to
  # the empty range HEAD..HEAD. Without that the batch leg would also run and its output could
  # satisfy — or mask — an assertion written about the worktree leg. That is the GATE 4b
  # lesson (an assertion aimed at a combined dispatch cannot say which half answered), applied
  # before it can bite rather than after.
  #
  # ASSERT ON OUTPUT, never on rc: GATE 13 is report-only and returns 0 by design.
  _g13() { DOC_GATE_REVROW_RANGE="$1" bash "$0" revrows 2>&1; }

  if python3 -c "f='reports/TR6_PARITY_SKELETON.md'
s=open(f,encoding='utf-8').read()
open(f,'w',encoding='utf-8').write(s+chr(10)+'Self-test body sentence with no revision row.'+chr(10))" 2>/dev/null; then
    G13OUT=$(_g13 'HEAD..HEAD')
    if printf '%s' "$G13OUT" | grep -qE 'WORKTREE reports/TR6_PARITY_SKELETON\.md — 1 body line'; then
      echo "  [ok]   GATE 13 worktree — an uncommitted TR body edit with no revision row is noted"
    else
      echo "  [FAIL] GATE 13 worktree — a body edit with no revision row was NOT noted."
      printf '%s\n' "$G13OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 13 worktree — could not inject, so the assertion did NOT run."; PASS=1
  fi
  _selftest_revert

  # The negative control for the worktree leg. Without it, "notes a body edit" is equally
  # consistent with "notes ANY edit to a TR", which would make the gate pure noise.
  if python3 -c "f='reports/TR6_PARITY_SKELETON.md'
s=open(f,encoding='utf-8').read()
open(f,'w',encoding='utf-8').write(s+chr(10)+'Self-test body sentence, recorded below.'+chr(10)+'| v9.99 | 2026-08-02 | Self-test revision row. |'+chr(10))" 2>/dev/null; then
    G13OUT=$(_g13 'HEAD..HEAD')
    # THE VACUITY GUARD, and it is not decoration. "No WORKTREE note" is also what a run
    # prints when the injection never reached the tree — the gate would then say
    # "working tree: no uncommitted TR edit" and this assertion would pass having tested
    # nothing. Requiring that line to be ABSENT is what makes the silence mean something.
    if printf '%s' "$G13OUT" | grep -qE 'no uncommitted TR edit'; then
      echo "  [FAIL] GATE 13 worktree negative control — the gate saw a CLEAN tree, so the"
      echo "         injection never landed and the silence proves nothing (vacuous pass)."
      PASS=1
    elif printf '%s' "$G13OUT" | grep -qE 'WORKTREE'; then
      echo "  [FAIL] GATE 13 worktree negative control — a body edit that DID get a row was noted."
      printf '%s\n' "$G13OUT" | sed 's/^/           > /' | head -5
      PASS=1
    else
      echo "  [ok]   GATE 13 worktree negative control — a body edit WITH a revision row is silent"
    fi
  else
    echo "  [FAIL] GATE 13 worktree negative control — could not inject; assertion did NOT run."; PASS=1
  fi
  _selftest_revert

  G13OUT=$(_g13 'b5bcff7c^..b5bcff7c')
  if printf '%s' "$G13OUT" | grep -qE 'b5bcff7c reports/TR4_SIZE_OF_THE_SPACE\.md'; then
    echo "  [ok]   GATE 13 batch — fires on b5bcff7c, the real silent TR-4 edit v1.13 records"
  else
    echo "  [FAIL] GATE 13 batch — b5bcff7c is the commit this gate was written for (TR-4 §3"
    echo "         edited, no revision row; recorded after the fact as v1.13) and it was NOT"
    echo "         noted. If that commit has been rewritten, re-anchor on another real one."
    printf '%s\n' "$G13OUT" | sed 's/^/           > /' | head -6
    PASS=1
  fi

  G13OUT=$(_g13 '00c0db0^..00c0db0')
  # THE SAME VACUITY GUARD. If that sha is ever rewritten or unreachable, `git rev-list`
  # returns nothing, the gate reports zero commits examined, and "no note was printed"
  # becomes true for a reason that has nothing to do with the gate working. Assert the
  # commit was actually READ before reading anything into its silence.
  if ! printf '%s' "$G13OUT" | grep -qE '1 non-merge commit\(s\) examined'; then
    echo "  [FAIL] GATE 13 batch negative control — the range 00c0db0^..00c0db0 resolved to no"
    echo "         commit, so the absence of a note proves nothing (vacuous pass). Re-anchor"
    echo "         on a reachable commit that gives every TR it touches a revision row."
    printf '%s\n' "$G13OUT" | sed 's/^/           > /' | head -4
    PASS=1
  elif printf '%s' "$G13OUT" | grep -qE '\[note\] 00c0db0'; then
    echo "  [FAIL] GATE 13 batch negative control — 00c0db0 gave BOTH TRs it touched a revision"
    echo "         row and must be silent. A gate that notes a compliant commit is noise."
    printf '%s\n' "$G13OUT" | sed 's/^/           > /' | head -6
    PASS=1
  else
    echo "  [ok]   GATE 13 batch negative control — 00c0db0 gave both its TRs a row, and is silent"
  fi

  # GATE 5, added 2026-08-02 with the #65 work. The old note said this gate could not be
  # mutation-tested because doing so "would require editing a canonical quantity" — which
  # was true only of the mutation shape assumed. APPENDING a new sentence that quotes 5.21
  # with the wrong status edits no existing value at all, and reverts like every other
  # GUIDE.md mutation here. The stated reason for a coverage gap is worth re-testing, not
  # just inheriting: that is the same "recorded state that was not true" class this suite
  # exists for. Assert on OUTPUT, like GATE 1: gate 5 is report-only and always exits 0.
  # The assertion is on the WHY text, not merely on the presence of a WARN — a gate that
  # fires without saying what it matched is the defect #65 was raised to fix.
  python3 -c "s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+chr(10)+'The exact figure 5.21 x 10^31 is a proven count.'+chr(10))" 2>/dev/null \
    && { G5OUT=$(bash "$0" status 2>&1)
         if printf '%s' "$G5OUT" | grep -q "carries exact/proven token(s)"; then
           echo "  [ok]   GATE 5 epistemic status — WARNs and names the tokens it matched"
         else
           echo "  [FAIL] GATE 5 did not fire, or fired without naming what it matched"
           printf '%s\n' "$G5OUT" | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert documentation/GUIDE.md; } \
    || { echo "  [FAIL] GATE 5 — could not append to GUIDE.md, so the assertion did NOT run"
         echo "         (item A5)."; PASS=1; }

  # -----------------------------------------------------------------------
  # GATE 5's ALLOWLIST — three assertions (2026-08-02, item A8). Re-keying the allowlist on
  # (file, anchor) alone deleted the drift branch that had a live negative control (an
  # entry recorded at :9999 fired it). Deleting a branch deletes its proof, so the
  # replacement proofs are written here rather than assumed. All three are OUTPUT
  # assertions: GATE 5 is report-only and always exits 0.
  #
  # (1) DRIFT IMMUNITY — the whole point of A8. Insert a line ABOVE the anchored TR-4
  #     sentence. The exemption must still resolve (to a line one greater) and the run must
  #     produce NO [note] at all: under the old scheme this exact edit produced one.
  python3 -c "s=open('reports/TR4_SIZE_OF_THE_SPACE.md').read()
a='*none — no exact value exists*'
assert a in s, 'anchor moved'
i=s.index(a); j=s.rindex(chr(10), 0, i)
open('reports/TR4_SIZE_OF_THE_SPACE.md','w').write(s[:j]+chr(10)+'<!-- selftest: a line inserted above the anchored row -->'+s[j:])" 2>/dev/null \
    && { A8OUT=$(bash "$0" status 2>&1)
         if printf '%s' "$A8OUT" | grep -q 'TR4_SIZE_OF_THE_SPACE.md:124 exemption live' \
            && ! printf '%s' "$A8OUT" | grep -q '\[note\] allowlist'; then
           echo "  [ok]   GATE 5 allowlist drift immunity — anchor moved :123 -> :124, still live, no [note]"
         else
           echo "  [FAIL] GATE 5 allowlist did not survive an insertion above its anchor"
           printf '%s\n' "$A8OUT" | grep -E 'allowlist' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert; } \
    || { echo "  [FAIL] GATE 5 allowlist drift case — could not inject; assertion did NOT run."; PASS=1; }

  # (2) DEAD ANCHOR still audited. This is the branch A8's option (ii) was said to cost,
  #     and it does not: it never read the line number.
  python3 -c "open('documentation/DOC_GATE_STATUS_ALLOWLIST.txt','a').write(
'documentation/HISTORY.md'+chr(9)+'a sentence that appears nowhere in the corpus'+chr(10))" 2>/dev/null \
    && { A8OUT=$(bash "$0" status 2>&1)
         if printf '%s' "$A8OUT" | grep -q 'anchor no longer appears in the file'; then
           echo "  [ok]   GATE 5 allowlist dead-anchor audit — fires, and says prune it"
         else
           echo "  [FAIL] GATE 5 allowlist accepted an anchor matching nothing, silently"
           PASS=1
         fi
         _selftest_revert; } \
    || { echo "  [FAIL] GATE 5 dead-anchor case — could not inject; assertion did NOT run."; PASS=1; }

  # (3) AN UNANCHORED ENTRY SUPPRESSES NOTHING. Under the old scheme it suppressed by line
  #     number, which is the direction that let an unreviewed line inherit somebody else's
  #     exemption. The entry injected here names the exact file:line GATE 5 warns about in
  #     assertion (1) above, so if it still suppressed, the WARN would vanish.
  python3 -c "s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+chr(10)+'The exact figure 5.21 x 10^31 is a proven count.'+chr(10))
n=len(open('documentation/GUIDE.md').read().split(chr(10)))-1
open('documentation/DOC_GATE_STATUS_ALLOWLIST.txt','a').write('documentation/GUIDE.md:%d'%n+chr(10))" 2>/dev/null \
    && { A8OUT=$(bash "$0" status 2>&1)
         if printf '%s' "$A8OUT" | grep -q 'SUPPRESSES NOTHING' \
            && printf '%s' "$A8OUT" | grep -q "carries exact/proven token(s)"; then
           echo "  [ok]   GATE 5 unanchored allowlist entry — reported AND inert"
         else
           echo "  [FAIL] GATE 5 unanchored entry suppressed a WARN, or was not reported"
           printf '%s\n' "$A8OUT" | grep -E 'allowlist|WARN' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert; } \
    || { echo "  [FAIL] GATE 5 unanchored case — could not inject; assertion did NOT run."; PASS=1; }

  # GATE 5b (item A4), asserted against ITS OWN MOTIVATING EXAMPLE rather than a synthetic
  # table: the mutation reverts TR-9's C3 ledger cell to the bare-number form it carried
  # before #23 fixed it. That is the defect the class exists for, and TR-9 v1.19 states
  # that GATE 5 could not see it. Report-only, so the assertion is on the OUTPUT.
  #
  # WHY THE ASSERTION NAMES THE FILE AND THE WORD "NO status marker": 5b was narrowed TWICE
  # after its first run — a column-aware header exemption and a changelog-row exemption,
  # which between them took its live findings from 6 to 0. A gate narrowed to silence is
  # indistinguishable from a gate narrowed to precision unless something re-proves it still
  # fires, and neither narrowing may be allowed to swallow this case.
  # A DRIFTED ANCHOR IS A FAILURE HERE, NOT A SKIP. Written as a [SKIP] first, and the very
  # first run printed "[SKIP] GATE 5b — anchor moved" because the injector's `%` had been
  # written `%%` (a printf habit; this is a plain double-quoted bash string). The assertion
  # never ran and the suite still reported PASS — GATE 8's failure exactly, reproduced
  # within an hour of writing the rule down. So: no silent skip. If TR-9's cell is legitimately
  # reworded, this must go red and be re-anchored by hand, because a fire-proof that opts
  # itself out is not a proof.
  #
  # The mutation is NOT injected via `python3 -c` for the same reason: the shell layer is
  # where the escaping went wrong. It is written to a file and run, so the string reaching
  # python is the string in this script.
  G5BMUT=$(mktemp)
  cat > "$G5BMUT" <<'G5BPY'
p = 'reports/TR9_PRICING_THE_CONSTRAINTS.md'
a = '1.3287×10³⁸ (**estimate** — Knuth random-probe, 95% CI [1.3283, 1.3292]×10³⁸, 0.02%)'
s = open(p, encoding='utf-8').read()
assert s.count(a) == 1, 'anchor moved: found %d occurrences' % s.count(a)
open(p, 'w', encoding='utf-8').write(s.replace(a, '1.3287×10³⁸', 1))
G5BPY
  if python3 "$G5BMUT" 2>&1; then
    G5BOUT=$(bash "$0" status 2>&1)
    if printf '%s' "$G5BOUT" | grep -q 'TR9_PRICING_THE_CONSTRAINTS.md:70 .* carries NO status marker'; then
      echo "  [ok]   GATE 5b unmarked-among-marked — fires on the pre-#23 TR-9 ledger cell"
    else
      echo "  [FAIL] GATE 5b did not fire on the defect it was written for"
      printf '%s\n' "$G5BOUT" | sed 's/^/           > /' | head -6
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 5b — could not inject its anchor, so the assertion did NOT run."
    echo "         Re-anchor it against TR-9's C3 ledger cell; a skipped fire-proof is not a proof."
    PASS=1
  fi
  rm -f "$G5BMUT"
  _selftest_revert reports/TR9_PRICING_THE_CONSTRAINTS.md

  # =========================================================================
  # GATE 8 — THREE mutation cases, ONE regeneration (added 2026-08-02, item A1).
  #
  # WHY THIS IS HERE AT ALL. GATE 8's fire-proof was taken BY HAND at df4ddc9. Its
  # invocation was rewritten hours later at 91129a4 and the proof was never re-run —
  # which is exactly how a ONE-DIRECTIONAL comparison shipped and attested "matches
  # exactly" over a DELETED line (b0ee2f8). A hand-taken proof is not a proof of the
  # code that ships; only an assertion that re-runs is.
  #
  # WHY IT ASSERTS ON THE EVIDENCE, NOT THE EXIT CODE. The bug it exists to catch —
  # comparing in one direction only — still exits non-zero on a SUBSTITUTION, because a
  # substitution leaves an added line behind as well. An exit-code assertion would have
  # passed on the broken gate. Each case therefore names the exact counted verdict
  # GATE 8 must print, so "0 added, 1 missing" (deletion, the direction that was
  # missing) is asserted as a number and cannot be satisfied by any other finding.
  #
  # THE COST, AND WHAT PAYS IT. Each GATE 8 invocation regenerates example/ from
  # roae.py — three runs, ~45 s each, so three naive cases would cost ~7 minutes. They
  # share ONE regeneration through DOC_GATES_GEN_CACHE, keyed on roae.py's sha256:
  # measured 135 s for the first case and 0.08 s for each of the others.
  GEN_CACHE=$(mktemp -d)

  # assert_gen_fires <label> <evidence-ERE> <python-mutation>
  #   <evidence-ERE> must match a line of GATE 8's output.
  # ITEM A5: [FAIL], not [SKIP] — see the moved-anchor note at the head of the harness. This
  # one matters most of the helpers:
  # all four of its cases anchor on shipped prose in example/ ('terminal attractor', the
  # "organizing feature" sentence, report.pdf's existence), and example/ is REGENERATED
  # output, so a legitimate roae.py change moves those anchors without anyone editing a
  # fire-proof. GATE 8 is also the gate whose hand-taken proof already went stale once.
  assert_gen_fires() {
    local label="$1" want="$2" mut="$3" out rc
    python3 -c "$mut" || { echo "  [FAIL] $label — could not inject (anchor moved), so the"
                           echo "         assertion did NOT run. A skipped fire-proof is not a proof."
                           PASS=1; _selftest_revert; return; }
    out=$(DOC_GATES_GEN_CACHE="$GEN_CACHE" bash "$0" generated 2>&1); rc=$?
    _selftest_revert
    if [ "$rc" -eq 0 ]; then
      echo "  [FAIL] $label — GATE 8 did NOT fire on an injected defect"
      PASS=1; return
    fi
    if printf '%s\n' "$out" | grep -Eq -- "$want"; then
      echo "  [ok]   $label — GATE 8 fires, and WHY matches: $want"
    else
      echo "  [FAIL] $label — GATE 8 fired, but not for the asserted reason"
      echo "         expected a line matching: $want"
      printf '%s\n' "$out" | grep -E '\[FAIL\]' | head -3 | sed 's/^/           got > /'
      PASS=1
    fi
  }

  # CASE 1 — DELETION, the direction the shipped comparison could not see, in the exact
  # shape of the 2026-08-01 demonstration: remove the nuclear-attractor line from
  # example/report.txt. 0 added / 1 missing is the whole point — a `comm -13`-only gate
  # scores 0 added and reports [ok].
  assert_gen_fires "GATE 8 deletion from a shipped artifact" \
'example/report\.txt vs roae\.py --all: 0 added, 1 missing' \
"p='example/report.txt'
L=open(p,encoding='utf-8').read().split(chr(10))
h=[i for i,x in enumerate(L) if 'terminal attractor' in x]
assert len(h)==1, 'anchor moved'
del L[h[0]]
open(p,'w',encoding='utf-8').write(chr(10).join(L))"

  # CASE 2 — SUBSTITUTION, the shape of defect (a): example/README.md was a hand-edited
  # copy of report.md differing by one word. One letter, in a line roae.py prints
  # UNCONDITIONALLY (print_complements' static preamble), so the case cannot be flaked by
  # a Monte Carlo verdict landing in a different branch.
  assert_gen_fires "GATE 8 one-word substitution in a shipped artifact" \
'example/README\.md vs roae\.py --markdown: 1 added, 1 missing' \
"p='example/README.md'
a=\"is an organizing feature of the sequence's structure\"
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved'
open(p,'w',encoding='utf-8').write(s.replace(a,a.replace('organizing','organising'),1))"

  # CASE 3 — the PDF leg (item A2), which has no other proof. Mutating report.html trips
  # leg 4 as well, so the assertion targets leg 5's OWN verdict line: proof that the
  # pdftotext/tag-strip comparison ran and disagreed, not merely that the gate went red
  # for some earlier reason.
  assert_gen_fires "GATE 8 PDF no longer renders the shipped HTML" \
'example/report\.pdf vs example/report\.html: 1 line\(s\) only in the PDF, 1 only in the HTML' \
"p='example/report.html'
a=\"is an organizing feature of the sequence's structure\"
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved'
open(p,'w',encoding='utf-8').write(s.replace(a,a.replace('organizing','organising'),1))"

  # CASE 4 — a DELETED shipped artifact. Found by Phase-4'ing this batch and asking what
  # every leg does when its input is not there: all five used to [skip] on `! -f`, so
  # `rm example/report.pdf` passed in silence. Absence is the strongest mismatch there is.
  assert_gen_fires "GATE 8 shipped artifact deleted outright" \
'example/report\.pdf is tracked in git but missing from the working tree' \
"import os
assert os.path.exists('example/report.pdf'), 'anchor moved'
os.remove('example/report.pdf')"

  # CASE 5 — the NEGATIVE control the other four do not provide, and the one that pins
  # the 2026-08-02 false FAIL. Cases 1-4 all prove GATE 8 goes RED; none proves it stays
  # GREEN when the generator legitimately prints a different Monte Carlo figure, which is
  # the single thing the digit-stripping exists to tolerate. It did not tolerate a figure
  # that crosses 1000: roae.py:1400 formats with `{ratio:,}`, the normaliser stripped
  # digits but not the separator, and `doc_gates.sh generated` reported
  #   +added   > Approximately in random orderings share this property.
  #   -missing > Approximately in , random orderings share this property.
  # on artifacts that were correct. This case mutates the REGENERATED REFERENCE (not the
  # shipped artifact) to carry a grouped figure and asserts the gate stays green AND still
  # prints the html leg's own [ok] line — an rc-only assertion would be satisfied by the
  # leg skipping. FIRE-PROOF: run against the pre-fix normaliser this case FAILS; see the
  # round-4 handover for the transcript.
  assert_gen_clean() {
    local label="$1" want="$2" mut="$3" out rc
    if [ ! -s "$GEN_CACHE/report.html" ]; then
      echo "  [FAIL] $label — no regenerated reference to mutate"; PASS=1; return
    fi
    cp "$GEN_CACHE/report.html" "$GEN_CACHE/report.html.orig"
    if ! GEN_CACHE="$GEN_CACHE" python3 -c "$mut"; then
      echo "  [FAIL] $label — could not inject (anchor moved)"; PASS=1
      mv "$GEN_CACHE/report.html.orig" "$GEN_CACHE/report.html"; return
    fi
    out=$(DOC_GATES_GEN_CACHE="$GEN_CACHE" bash "$0" generated 2>&1); rc=$?
    mv "$GEN_CACHE/report.html.orig" "$GEN_CACHE/report.html"
    if [ "$rc" -ne 0 ] || ! printf '%s\n' "$out" | grep -Eq -- "$want"; then
      echo "  [FAIL] $label — GATE 8 did not stay green on a legitimate figure change (rc=$rc)"
      echo "         expected rc 0 and a line matching: $want"
      printf '%s\n' "$out" | grep -E '\[FAIL\]|\+added|-missing' | head -4 | sed 's/^/           got > /'
      PASS=1; return
    fi
    echo "  [ok]   $label — GATE 8 stays green, and says so: $want"
  }

  assert_gen_clean "GATE 8 comma-grouped Monte Carlo figure is not a difference" \
'example/report\.html agrees with roae\.py --html on every NON-NUMERIC line' \
'import os, re
p = os.path.join(os.environ["GEN_CACHE"], "report.html")
s = open(p, encoding="utf-8").read()
pat = re.compile(r"Approximately 1 in (\d[\d,]*) random orderings share this property\.")
m = pat.search(s)
assert m, "anchor moved"
assert m.group(1) != "1,046", "reference already carries the injected value"
open(p, "w", encoding="utf-8").write(
    pat.sub("Approximately 1 in 1,046 random orderings share this property.", s, count=1))'

  # CASES 6 and 7 — THE DIGIT LEGS (item A2 residual, 2026-08-02).
  #
  # These two assert something the other cases cannot: that the new leg is the ONLY thing
  # that sees the defect. Every case above is satisfied by ANY leg going red, so a case that
  # merely proved "GATE 8 fires" would still be green if legs 5/6 were deleted tomorrow and
  # some other leg fired for its own reason. Each of these therefore asserts TWO lines: the
  # new leg's own verdict, AND the digit-blind leg's [ok] on the same file — the second is
  # what proves the coverage is new. That is the shape GATE 8's own history argues for: its
  # first fire-proof was taken by hand, was satisfied by an exit code, and a one-directional
  # comparison shipped behind it.
  #
  # THE MUTATION IS ONE DIGIT in a line roae.py prints unconditionally (the static preamble),
  # so no Monte Carlo branch can flake it, and 64 -> 65 keeps the line's length and every
  # non-digit character identical — which is exactly why the digit-stripped legs cannot see
  # it, and is the point being proven.
  #
  # assert_gen_fires_only <label> <new-leg-ERE> <other-leg-stays-ok-ERE> <mutation>
  assert_gen_fires_only() {
    local label="$1" want="$2" alsowant="$3" mut="$4" out rc
    python3 -c "$mut" || { echo "  [FAIL] $label — could not inject (anchor moved), so the"
                           echo "         assertion did NOT run. A skipped fire-proof is not a proof."
                           PASS=1; _selftest_revert; return; }
    out=$(DOC_GATES_GEN_CACHE="$GEN_CACHE" bash "$0" generated 2>&1); rc=$?
    _selftest_revert
    if [ "$rc" -eq 0 ]; then
      echo "  [FAIL] $label — GATE 8 did NOT fire on a hand-edited digit"; PASS=1; return
    fi
    if ! printf '%s\n' "$out" | grep -Eq -- "$want"; then
      echo "  [FAIL] $label — GATE 8 fired, but not on the digit leg"
      echo "         expected a line matching: $want"
      printf '%s\n' "$out" | grep -E '\[FAIL\]' | head -3 | sed 's/^/           got > /'
      PASS=1; return
    fi
    if ! printf '%s\n' "$out" | grep -Eq -- "$alsowant"; then
      echo "  [FAIL] $label — the digit leg fired, but the digit-BLIND leg did not report [ok],"
      echo "         so this case does not prove the new leg is what caught it."
      echo "         expected a line matching: $alsowant"
      PASS=1; return
    fi
    echo "  [ok]   $label — only the digit leg sees it: \"$want\" while \"$alsowant\""
  }

  # CASE 6 — a hand-edited digit in example/report.html. This is the dbba77d class: that
  # file was hand-patched once already and was caught by the operator, not by a gate.
  assert_gen_fires_only "GATE 8 hand-edited DIGIT in report.html (leg 5 only)" \
'example/report\.pdf vs example/report\.html: the PROSE agrees and the NUMBERS do not' \
'\[ok\] +example/report\.html agrees with roae\.py --html on every NON-NUMERIC line' \
"p='example/report.html'
a='giving 8x8 = 64 possible hexagrams'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'giving 8x8 = 65 possible hexagrams',1))"

  # CASE 7 — a hand-edited digit in example/README.md, which legs 2 and 3 compare against
  # the generator separately and digit-blind, so before leg 6 the two shipped copies could
  # disagree on every number in the corpus and the gate printed [ok] twice.
  assert_gen_fires_only "GATE 8 hand-edited DIGIT in README.md (leg 6 only)" \
'example/README\.md is not byte-identical to example/report\.md' \
'\[ok\] +example/README\.md agrees with roae\.py --markdown on every NON-NUMERIC line' \
"p='example/README.md'
a='giving 8x8 = 64 possible hexagrams'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'giving 8x8 = 65 possible hexagrams',1))"

  rm -rf "$GEN_CACHE"

  # ITEM A1 — THE MISSING-INPUT CLASS, for every gate that has one.
  #
  # GATE 8's leg above ("shipped artifact deleted outright") was the first of these. The same
  # question — what does this gate do when its input is not there? — was then asked of GATES
  # 2, 3, 3b, 6, 10a, 10b and 11, and all seven answered `[skip]` + rc 0. MEASURED before the
  # fix: with documentation/CORRECTIONS.md deleted, `doc_gates.sh retract` printed
  # "DOC GATES: PASS (retract)" and exited 0, its only trace a bash redirect error on stderr —
  # which this very harness discards (`>/dev/null 2>&1`).
  #
  # The mutation is `os.remove`, and the revert is the harness's own `git checkout -- .`,
  # which restores a deleted tracked file exactly as it restores a modified one. So this
  # whole class is cheap: no regeneration, no scratch clone, no history rewrite.
  #
  # TWO DISTINCT MESSAGES, deliberately. The corpus preflight fires on any missing tracked
  # .md, so the CORRECTIONS.md cases below trip it as well as the gate's own leg. The
  # evidence ERE names the GATE's wording ("<f> is tracked in git but missing"), never the
  # preflight's ("tracked markdown missing from the working tree: <f>"), so each assertion
  # still proves the leg it was written for and not the preflight standing behind it.
  assert_fires_why "GATE 2 (A1) source file deleted" cli \
    'sat\.py is tracked in git but missing' \
"import os
assert os.path.exists('sat.py'), 'anchor moved'
os.remove('sat.py')"

  assert_fires_why "GATE 2 (A1) CLI doc deleted" cli \
    'SAT_CLI\.md is tracked in git but missing' \
"import os
assert os.path.exists('documentation/SAT_CLI.md'), 'anchor moved'
os.remove('documentation/SAT_CLI.md')"

  assert_fires_why "GATE 3 (A1) retraction registry deleted" retract \
    'RETRACTED_PHRASES\.tsv is tracked in git but missing' \
"import os
assert os.path.exists('documentation/RETRACTED_PHRASES.tsv'), 'anchor moved'
os.remove('documentation/RETRACTED_PHRASES.tsv')"

  assert_fires_why "GATE 3b (A1) figure registry deleted" retract-figures \
    'RETRACTED_FIGURES\.tsv is tracked in git but missing' \
"import os
assert os.path.exists('documentation/RETRACTED_FIGURES.tsv'), 'anchor moved'
os.remove('documentation/RETRACTED_FIGURES.tsv')"

  assert_fires_why "GATE 6 (A1) retraction registry deleted" figures \
    'RETRACTED_PHRASES\.tsv is tracked in git but missing' \
"import os
assert os.path.exists('documentation/RETRACTED_PHRASES.tsv'), 'anchor moved'
os.remove('documentation/RETRACTED_PHRASES.tsv')"

  # The worse of GATE 6's two: `gens` is `git ls-files`, an INDEX listing, so a deleted
  # generator stayed in the list, `tr < "$f"` failed to stderr, no phrase matched, and the
  # gate reported [ok] on a file it never opened. The `-n "$gens"` guard cannot see this —
  # the list was never empty. Anchored on viz/growth_curve.py, a real tracked generator.
  assert_fires_why "GATE 6 (A1) tracked generator deleted from the worktree" figures \
    'viz/growth_curve\.py is tracked in git but missing' \
"import os
assert os.path.exists('viz/growth_curve.py'), 'anchor moved'
os.remove('viz/growth_curve.py')"

  # Deleting the ledger is the LIMITING CASE of what 10a and 10b forbid: every committed
  # line lost at once. It was the one edit that made both halves report nothing.
  assert_fires_why "GATE 10a (A1) ledger deleted" appendonly-head \
    'CORRECTIONS\.md is tracked in git but missing' \
"import os
assert os.path.exists('documentation/CORRECTIONS.md'), 'anchor moved'
os.remove('documentation/CORRECTIONS.md')"

  assert_fires_why "GATE 10b (A1) ledger deleted" appendonly-history \
    'CORRECTIONS\.md is tracked in git but missing' \
"import os
assert os.path.exists('documentation/CORRECTIONS.md'), 'anchor moved'
os.remove('documentation/CORRECTIONS.md')"

  # GATE 11 named both files in ONE skip line, so it needs BOTH cases: an assertion on the
  # registry alone would pass against a gate that still skipped silently on a missing ledger.
  #
  # RE-POINTED FROM `ledger` TO `ledger-phrases` (item B2, round 9, 2026-08-02), and the
  # SECOND of these two was a LIVE instance of the class, not a tidy-up. Its ERE,
  # `CORRECTIONS.md is tracked in git but missing`, is emitted by `require_tracked "$f"` in
  # gate_ledger_phrases AND by the identical call in gate_ledger_figures — both halves guard
  # the same ledger. Under the combined `ledger` dispatch either one satisfied it, so the
  # assertion labelled "GATE 11 (A1) ledger deleted" could not say which half answered, and
  # deleting the phrases guard would have left it green. That is the fifth sighting of the
  # class GATE 4/4b, GATE 10a/10b and GATE 11-figures were each hand-fixed for. The first of
  # the two was never ambiguous (only the phrases half reads RETRACTED_PHRASES.tsv) and is
  # re-pointed for uniformity, so a future reader does not have to re-derive which is which.
  assert_fires_why "GATE 11 (A1) registry deleted" ledger-phrases \
    'RETRACTED_PHRASES\.tsv is tracked in git but missing' \
"import os
assert os.path.exists('documentation/RETRACTED_PHRASES.tsv'), 'anchor moved'
os.remove('documentation/RETRACTED_PHRASES.tsv')"

  assert_fires_why "GATE 11 (A1) ledger deleted" ledger-phrases \
    'CORRECTIONS\.md is tracked in git but missing' \
"import os
assert os.path.exists('documentation/CORRECTIONS.md'), 'anchor moved'
os.remove('documentation/CORRECTIONS.md')"

  # THE CORPUS PREFLIGHT — hole (b), and the one that made this item worth doing. `$DOCS` is
  # an index listing, so a tracked .md deleted from the working tree is read as EMPTY by
  # GATES 3, 3b, 4, 4b, 5, 5b and 9 simultaneously; each then reports [ok] on a document it
  # never opened. Asserted through `retract`, a gate with NO input of its own missing, so the
  # only thing that can make it fail here is the preflight.
  assert_fires_why "PREFLIGHT (A1) a tracked .md deleted blinds every DOCS-iterating gate" \
    retract 'tracked markdown missing from the working tree: documentation/GUIDE\.md' \
"import os
assert os.path.exists('documentation/GUIDE.md'), 'anchor moved'
os.remove('documentation/GUIDE.md')"

  # GATE 14 FIRE-PROOFS (item A6, 2026-08-02) — FOUR legs, and the count is deliberate.
  #
  # The suite's own header records GATE 8 shipping a ONE-DIRECTIONAL comparison behind a
  # fire-proof that was taken by hand and never re-run. A duplicate-detector has exactly the
  # same shape of hole: an assertion that only removes the allowlist row proves the ALLOWLIST
  # is load-bearing and says nothing about whether the gate can find a duplicate it has never
  # been told about. So the legs are split by what each one can fail on its own:
  #   (1) the MOTIVATING EXAMPLE — drop the r3/p1c4 row and the real pair must be reported;
  #   (2) a NEW pair the allowlist has never seen — reg_c1's body replaced by reg_r4's, so
  #       two rules that were plainly different become identical. Leg 1 passes even if the
  #       allowlist is the only thing the gate consults; leg 2 does not;
  #   (3) the BLIND-SPOT detector — reg_r4 pinned to its KW constant, which is precisely the
  #       state MM-T5 was in before the witnesses were added. A gate that reported [ok] on an
  #       uncomparable rule would be a false clear of the exact kind that hid a Lean defect
  #       for twelve hours on 2026-08-01; this leg makes the refusal load-bearing;
  #   (4) the MISSING-INPUT leg (item A1's class) — allowlist deleted.
  # Plus a negative control: a comment appended to the allowlist must change nothing, or the
  # parser is failing closed on its own file format and legs 1-4 prove less than they look.
  #
  # ITEM A2 CHECKED BEFORE THESE WERE WRITTEN, not after: neither preflight can emit any of
  # the four EREs below. preflight_tracked_docs prints only "tracked markdown missing from
  # the working tree", preflight_support_newlines only "gate-support file has no final
  # newline" — and DOC_GATE_REGISTRY_DUPLICATES.txt matches preflight_support_newlines'
  # `documentation/DOC_GATE_*.txt` glob, so that check was necessary rather than pro forma.
  # Every ERE here contains a `reg_` rule id, which no preflight ever prints.
  assert_fires_why "GATE 14 duplicate predicates — the r3/p1c4 pair the gate was built for" \
    regdupes 'reg_p1c4 and reg_r3 return the SAME value' \
"p='documentation/DOC_GATE_REGISTRY_DUPLICATES.txt'
s=open(p,encoding='utf-8').read()
assert s.count(chr(10)+'r3'+chr(9)+'p1c4'+chr(9))==1, 'anchor moved'
open(p,'w',encoding='utf-8').write(
    ''.join(l for l in s.splitlines(True) if not l.startswith('r3'+chr(9))))"

  assert_fires_why "GATE 14 a NEW duplicate the allowlist has never seen (reg_c1 := reg_r4)" \
    regdupes 'reg_c1 and reg_r4 return the SAME value' \
"p='solve.py'
a='    return sum(abs(sum(_reg_hw(h) for h in seq[i:i + 4]) - 12)'+chr(10)+'               for i in range(0, 64, 4))'+chr(10)
b='    return sum(bit_diff(seq[2 * k], seq[2 * k + 1]) for k in range(32))'+chr(10)
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'reg_c1 body anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,b,1))"

  assert_fires_why "GATE 14 a rule that cannot be compared is a FAIL, not a silent pass" \
    regdupes 'reg_r4 takes ONE value across all' \
"p='solve.py'
a='    return sum(bit_diff(seq[2 * k], seq[2 * k + 1]) for k in range(32))'+chr(10)
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'reg_r4 body anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'    return 120'+chr(10),1))"

  # PHASE-4 ON THIS BATCH, not a later thought: the first draft printed
  # "[ok] 0 rules, 0 pairs compared" and exited 0 if REGISTRY_KW_EXPECTED were emptied or
  # renamed. Both new gates in this batch had a way to be green having compared nothing,
  # which is the failure mode they were written to refuse, so both guards are asserted here
  # rather than reasoned about in a comment.
  assert_fires_why "GATE 14 an emptied registry is a finding, not a clean run" regdupes \
    'fewer than two cannot form a pair' \
"p='solve.py'
s=open(p,encoding='utf-8').read()
a='REGISTRY_KW_EXPECTED = ['
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
i=s.index(a); j=s.index(chr(10)+']'+chr(10), i)
open(p,'w',encoding='utf-8').write(s[:i]+'REGISTRY_KW_EXPECTED = [(\"r3\", True),'+s[j:])"

  assert_fires_why "GATE 14 (A1) duplicate allowlist deleted" \
    regdupes 'DOC_GATE_REGISTRY_DUPLICATES\.txt is tracked in git but missing' \
"import os
p='documentation/DOC_GATE_REGISTRY_DUPLICATES.txt'
assert os.path.exists(p), 'anchor moved'
os.remove(p)"

  # EVIDENCE (round 8 drain-3): the adjudicated-pair count is exactly the number the defect
  # this control is about would move — a comment line parsed as a pair makes it 2, or breaks
  # the parse outright. Pinning `1 adjudicated pair(s), 0 new` therefore covers the failure
  # the control names, without proving the appended line was read.
  assert_stays_clean_why "GATE 14 a comment appended to the allowlist changes nothing" regdupes \
    '1 adjudicated pair\(s\), 0 new' \
"open('documentation/DOC_GATE_REGISTRY_DUPLICATES.txt','a',encoding='utf-8').write(
    '# GATE 14 negative control: a comment line must not be parsed as a pair.'+chr(10))"

  # GATE 15 FIRE-PROOFS (item A1, 2026-08-02) — the instrument that catches an undeclared
  # instrument, which had better be able to catch one.
  #
  # THE MOTIVATING MUTATION MUTATES THIS FILE, so it mutates a COPY. `_selftest_revert`
  # restores tracked files with `git checkout -- .`, and doc_gates.sh is the script bash is
  # executing; task #77 is open on precisely that hazard. The gate's source seam is
  # read-only and announces itself, so the leg below tests the shipped code path on a
  # mutated input — which is what every other assertion here does, the input just happens to
  # be the program. The three legs that mutate only the TABLE need no copy and use none.
  _gsrc() { DOC_GATES_SRC_OVERRIDE="$1" bash "$0" "$2" 2>&1; }

  _G15_COPY=$(git rev-parse --git-dir)/doc_gates_g15_copy.sh
  # ANCHOR RE-POINTED 2026-08-02 (item A1, round 8): this used to inject above
  # `  assert_fires() {`, and that helper was deleted with the item.
  #
  # THE GUARD BELOW WAS `grep -qF`, AND IT WAS DEFEATED BY ITS OWN SOURCE TEXT (item A2,
  # round 8 drain-2, 2026-08-02). The comment here used to claim that a moved anchor "would
  # have taken the else branch — a LOUD failure, not a silent pass". MEASURED, and the claim
  # was false in the direction that matters. `sed` reads THIS FILE and writes the copy, so
  # the sed EXPRESSION on the line below — which contains the literal
  # `_fireproof_undeclared_instrument() { :; }` mid-line — is itself copied verbatim into
  # `$_G15_COPY`. An unanchored `grep -qF` for that literal therefore succeeds on a copy in
  # which NOTHING was injected: re-pointing the sed at a non-existent anchor produced a copy
  # byte-identical to the source (`diff -q` reported identical) and the guard still took the
  # THEN branch. The leg would then have run GATE 15 against an unmutated file and reported
  # its real, correct output as if it were the mutation's — a fire-proof passing with the
  # injection switched off, which is the exact class this file's LEG-6 header states as
  # "a fire-proof searching its own source file must match on a form its own text cannot
  # take". Third instance of that class in two days, and the first one that was LIVE.
  #
  # THE FIX IS THAT FORM. `^  ` + the literal + `$` matches the injected line, which `sed`
  # writes at column 0 with exactly two leading spaces, and matches NO line of this
  # fire-proof: the sed line starts `  if sed 's|...` and this grep line starts `     && `.
  # Proven in both directions before it was written: with the real anchor the copy has
  # exactly ONE matching line; with the anchor deliberately moved it has zero. The
  # generic check that no OTHER copy-guard can regress this way is the second half of
  # gate_selftest_instruments (GATE 15 LEG 2).
  if sed 's|^  assert_fires_why() {$|  _fireproof_undeclared_instrument() { :; }\n  assert_fires_why() {|' \
       scripts/doc_gates.sh > "$_G15_COPY" \
     && grep -qE '^  _fireproof_undeclared_instrument\(\) \{ :; \}$' "$_G15_COPY"; then
    G15OUT=$(_gsrc "$_G15_COPY" instruments)
    if printf '%s' "$G15OUT" | grep -qF '_fireproof_undeclared_instrument() is defined at'; then
      echo "  [ok]   GATE 15 an undeclared instrument in the --selftest region — fires, and names it"
    else
      echo "  [FAIL] GATE 15 — a new function in the --selftest region declared in NO row was"
      echo "         not reported. That is the fbdbe26 defect this gate exists for."
      printf '%s\n' "$G15OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 15 — could not build the mutated copy (the \`  assert_fires_why() {\`"
    echo "         anchor moved), so the assertion did NOT run."
    PASS=1
  fi
  rm -f "$_G15_COPY"

  # GATE 15 LEG 2 FIRE-PROOFS (item A2, round 8 drain-2, 2026-08-02) — the check that no
  # copy-confirmation guard can be satisfied by the fire-proof's own source text. TWO legs,
  # one per clause, because a single leg would prove one direction and the shipped comment
  # would claim both — which is the GATE 8 defect this whole file exists to stop repeating.
  #
  # CLAUSE (1)'s MUTATION IS THE PRE-FIX LINE VERBATIM. It reconstructs the `grep -qF` guard
  # that was LIVE in this file until this commit, so the leg is proven against the real
  # defect rather than a stylised one.
  #
  # THE MUTATION STRINGS ARE SPLIT (`'grep '+'-qF '`), and that is item A2 applied to this
  # fire-proof itself: written whole, the line below would be a copy-guard in the --selftest
  # region and the gate would flag ITS OWN mutation string on the live tree. The split is not
  # trusted, it is PROVEN CONTINUOUSLY — `instruments` runs in `all` and would be RED right
  # now if any line here matched, so a green `all` is the standing proof that it held.
  _G15B_COPY=$(git rev-parse --git-dir)/doc_gates_g15b_copy.sh
  for _g15b in unanchored fixedstring; do
    if python3 -c "
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
g='grep '+'-qE '
t=[i for i,l in enumerate(L) if l.strip().startswith('&& '+g) and '_G15_COPY' in l]
assert len(t)==1, 'anchor moved: %d' % len(t)
if '$_g15b'=='unanchored':
    L[t[0]]=L[t[0]].replace(chr(39)+'^  _fireproof', chr(39)+'  _fireproof', 1)
    assert chr(39)+'^  _fireproof' not in L[t[0]], 'the anchor was not stripped'
else:
    L[t[0]]='     && '+'grep '+'-qF '+chr(39)+'_fireproof_undeclared_instrument() { :; }'+chr(39)+' \"\$_G15_COPY\"; then'+chr(10)
open('$_G15B_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
      G15BOUT=$(_gsrc "$_G15B_COPY" instruments)
      case "$_g15b" in
        unanchored)  _g15bwhy='this guard'"'"'s ERE is not anchored at line start' ;;
        fixedstring) _g15bwhy='with a FIXED string' ;;
      esac
      if printf '%s' "$G15BOUT" | grep -qF "$_g15bwhy"; then
        echo "  [ok]   GATE 15 LEG 2 a copy-confirmation guard satisfiable by its own source ($_g15b) — fires, and says why"
      else
        echo "  [FAIL] GATE 15 LEG 2 — a $_g15b copy guard was NOT reported. That guard passes"
        echo "         with the injection switched off (item A2, five instances in two days)."
        printf '%s\n' "$G15BOUT" | sed 's/^/           > /' | head -5
        PASS=1
      fi
    else
      echo "  [FAIL] GATE 15 LEG 2 ($_g15b) — could not build the mutated copy (the anchored"
      echo "         \`&& grep -qE ... \$_G15_COPY\` line moved), so the assertion did NOT run."
      PASS=1
    fi
  done
  rm -f "$_G15B_COPY"

  # THE LABEL CHECK IS THE HALF THAT MAKES THIS MORE THAN A CHECKLIST. Without it a row could
  # name any string at all and the table would degrade into a list of names — which is how
  # "documented" becomes indistinguishable from "proven".
  #
  # ROW RE-POINTED 2026-08-02 (item A1, round 8): this leg used to mutate the `assert_fires`
  # row, and that helper — and therefore its row — was deleted with the item. It now mutates
  # the `assert_stays_clean_why` row. The `s.count(a)==1` guard is what makes the re-point
  # safe: had it been left pointing at a row that no longer exists, the leg would have
  # reported "anchor moved" and PASS=1, never a quiet skip. RE-POINTED AGAIN the same day
  # (A1's residue, drain-3) when that helper gained its evidence argument and was renamed.
  # AND THE RENAME COULD NOT HAVE LANDED SILENTLY EITHER WAY, which was measured rather than
  # assumed: with the script renamed and the table row left at the old key, `doc_gates.sh
  # instruments` FAILS first, naming assert_stays_clean_why as declared in no row. So a
  # forgotten row key is caught by the gate before this leg's guard is even reached, and the
  # guard is the second line, not the only one.
  #
  # THE ANCHORED LABEL IS ALSO SPLIT, and that is the item-A2 form applied one level deeper
  # than the substitute label below. The old version carried its anchor label as ONE literal,
  # so the label the gate searches doc_gates.sh for occurred TWICE in doc_gates.sh — once in
  # the real assertion and once inside this mutation string. Delete the real assertion and
  # GATE 15 would still have found the label, in this fire-proof's own source. Splitting the
  # literal makes the two disjoint, and `src.count(lbl)==1` asserts the split actually held
  # rather than trusting that it did — the count is the fire-proof of the fire-proof.
  #
  # THE SUBSTITUTE LABEL IS ASSEMBLED FROM FRAGMENTS, and that is not stylistic. The first
  # version of this leg injected the literal 'GATE 9 banner drift that nobody ever wrote' —
  # and FAILED in the harness, because writing that literal into the mutation string put it
  # into doc_gates.sh, which is the very file the gate searches. The fire-proof satisfied the
  # condition it was testing for. That is the A2 shared-message class arriving through an
  # assertion's own source text, it was caught by running the suite rather than by reading
  # it, and it is the reason this comment exists instead of a tidier one-liner.
  assert_fires_why "GATE 15 a row naming an assertion nobody wrote" instruments \
    'that label does not occur' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
row='assert_stays_clean_why'+chr(9)
lbl='GATE 12 a repeated DRAFT label is'+' exempt (suffix-keyed, not file-keyed)'
a=row+lbl+chr(9)
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
src=open('scripts/doc_gates.sh',encoding='utf-8').read()
assert src.count(lbl)==1, \\
    'the anchored label occurs %d times in the source; splitting it failed' % src.count(lbl)
lab='ZZ'+chr(45)+'no-such-assertion-label'
assert lab not in src, \\
    'the substitute label leaked into the source; the leg would test nothing'
open(p,'w',encoding='utf-8').write(s.replace(a, row+lab+chr(9), 1))"

  assert_fires_why "GATE 15 a row for a function that no longer exists" instruments \
    'which is no longer defined in the --selftest' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
assert s.count(chr(10)+'_g13'+chr(9))==1, 'anchor moved'
open(p,'w',encoding='utf-8').write(s.replace(
    chr(10)+'_g13'+chr(9), chr(10)+'_g13_deleted_long_ago'+chr(9), 1))"

  assert_fires_why "GATE 15 (A1) instrument declaration table deleted" instruments \
    'DOC_GATE_SELFTEST_INSTRUMENTS\.txt is tracked in git but missing' \
"import os
p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
assert os.path.exists(p), 'anchor moved'
os.remove(p)"

  # EVIDENCE (round 8 drain-3): same shape as GATE 14's — the instrument count is what a
  # comment mis-parsed as a row would move. RE-TAKEN 10 -> 11 (round 9, item B2) when _g16b
  # was declared, and 11 -> 12 (round 10, item N4) when _g15d was: each number came from
  # running `instruments` under this exact mutation, not from adding one to the old ERE,
  # which is the difference this control exists to enforce. TWICE IN TWO ROUNDS IS THE
  # EVIDENCE THAT THE CONTROL IS LOAD-BEARING: a batch that declares an instrument SHOULD
  # trip it, and a batch that trips nothing has probably pinned nothing.
  assert_stays_clean_why "GATE 15 a comment appended to the table changes nothing" instruments \
    '12 instrument\(s\) in the --selftest region, all declared' \
"open('documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt','a',encoding='utf-8').write(
    '# GATE 15 negative control: a comment line declares nothing and breaks nothing.'+chr(10))"

  # GATE 15 LEG 3 FIRE-PROOFS (items B8 + B3, round 9 drain-2, 2026-08-02) — the claims
  # column. THE FIRST LEG IS THE MOTIVATING EXAMPLE ITSELF, NOT A SYNTHETIC ONE: it puts the
  # `scratch_appendonly` row back to the exact label it carried from 6d93ed5 to b4442cf —
  # "GATE 10b vs history (…)" — which is a REAL assertion in this file that never calls
  # scratch_appendonly. That row was green under LEG 1 for the whole of its life, because
  # LEG 1 asks only whether the label exists somewhere in doc_gates.sh, and it does — it is
  # the label of the live "GATE 10b vs history" assert_fires_why (named, not cited by line:
  # a same-file line citation rots on the next insertion above it, item B1).
  # So this leg proves the new check catches the defect the old check shipped.
  #
  # THE HISTORICAL LABEL IS ASSEMBLED FROM TWO FRAGMENTS, and the leg asserts the assembled
  # form occurs exactly ONCE in the source before mutating. That is the item-A2 discipline:
  # written as one literal, this mutation string would itself become a second occurrence, and
  # a future reader could not tell whether LEG 1 was satisfied by the real assertion or by
  # this fire-proof's own source text (caveat 1a of the table).
  assert_fires_why "GATE 15 LEG 3 the historical scratch_appendonly misdeclaration" instruments \
    'declares kind=INVOCATION for scratch_appendonly\(\), but no line of' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
row='scratch_appendonly'+chr(9)
cur='GATE 10b vs a COMMITTED removal (working copy == HEAD)'
a=row+cur+chr(9)
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
old='GATE 10b vs history (a line of the '+'OLDEST committed version deleted)'
src=open('scripts/doc_gates.sh',encoding='utf-8').read()
assert src.count(old)==1, \\
    'the historical label occurs %d times in the source; splitting it failed' % src.count(old)
open(p,'w',encoding='utf-8').write(s.replace(a, row+old+chr(9), 1))"

  # A ROW MAY NOT DOWNGRADE ITS OWN KIND. Without this direction the claims column is an
  # opt-out: any row failing the INVOCATION check could relabel itself BLOCK and go green,
  # which is the ratchet every report-only gate in this file has had to argue about.
  #
  # THE ANCHOR CARRIES THE ROW KEY, and it did not on this leg's first run. Anchored on the
  # claims field alone (`kind=INVOCATION callers=2`) it matched TWO rows — scratch_appendonly
  # and assert_gen_fires_only both have two callers — and the `count(a)==1` guard refused to
  # inject and reported PASS=1. That is the guard working: a fire-proof that had silently
  # mutated whichever row came first would have been asserting about a row nobody chose.
  assert_fires_why "GATE 15 LEG 3 a row downgrading INVOCATION to BLOCK" instruments \
    'declares kind=BLOCK for scratch_appendonly\(\), but the INVOCATION form holds' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
a=('scratch_appendonly'+chr(9)+'GATE 10b vs a COMMITTED removal (working copy == HEAD)'
   +chr(9)+'kind='+'INVOCATION callers=2'+chr(9))
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a, a.replace(
    'kind=INVOCATION callers=2', 'kind=BLOCK callers=2'), 1))"

  # A BLOCK ROW MAY NOT BE PROVEN BY A STRING THE HARNESS NEVER PRINTS (item N3, round 10
  # drain-3, 2026-08-02). THIS MUTATION IS THE LIVE DEFECT, NOT A SYNTHETIC ONE. The
  # `_selftest_revert` row's label is "A1 snapshot"; below the one call that is the assertion
  # sits `… | grep -q 'A1 snapshot probe'`, the marker text the assertion searches FOR. That
  # line is not an echo, and until today it was what satisfied the row: as measured on
  # 2026-08-02 the `+3` the gate printed was the distance to that grep, and the `[ok]` line
  # was at `+4`. The live distance is on the gate's own [ok] line every run; those two are a
  # dated observation, not a standing claim about where the lines are.
  #
  # THE LEG SETS THE LABEL TO THE FULL MARKER, and what makes that fire is that the marker is
  # ECHOED NOWHERE — not that it is rare. MEASURED against the pre-fix code before the fix was
  # written: LEG 3 stayed GREEN and printed the identical `_selftest_revert +3`. So this leg
  # fires on the fix and only on the fix.
  #
  # THE GUARDS ASSERT THE PROPERTY, NOT A COUNT, AND THAT IS THIS BATCH'S OWN LESSON. The
  # first draft of this comment said the marker "occurs in this file ONLY as the injected
  # probe text and as that grep pattern" — and the commit that wrote the sentence added three
  # more occurrences, in comments, one of them the sentence itself. A count-based guard would
  # have shipped RED or, worse, been "fixed" by bumping the number. `echoed == []` cannot rot
  # that way: prose about the marker is not an echo of it, so this paragraph may grow freely.
  #
  # THE LITERAL IS STILL SPLIT, for the reason at the scratch_appendonly leg above: written
  # whole, the mutation string would be an occurrence a reader could confuse with the probe's.
  # Splitting it keeps the MUTATION out of the source; it does not, and cannot, keep the
  # surrounding prose out.
  assert_fires_why "GATE 15 LEG 3 a BLOCK row proven by a string the harness never prints" \
    instruments \
    'declares kind=BLOCK for _selftest_revert\(\), but no \[ok\]/\[FAIL\] REPORT line' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
a='_selftest_revert'+chr(9)+'A1 snapshot'+chr(9)
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
marker='A1 snapshot'+' probe'
src=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines()
echoed=[i+1 for i,l in enumerate(src) if marker in l and l.lstrip().startswith('echo \"')]
assert not echoed, 'the marker IS echoed at %r, so this leg would fire vacuously' % echoed
assert any(marker in l for l in src), 'the marker is gone from the source entirely'
open(p,'w',encoding='utf-8').write(s.replace(a, '_selftest_revert'+chr(9)+marker+chr(9), 1))"

  # THE OTHER ARM OF THE SAME FAIL (item R6, round 11 drain-1, 2026-08-02). The kind=BLOCK
  # FAIL above branches on WHY it fired: an occurrence that is not a report line, or no
  # occurrence at all. The leg shipped in f5fac73 exercises the first arm only. The second is
  # PRE-EXISTING text — exposure is unchanged rather than new — but by this file's own rule an
  # unexercised arm is an untested arm. What it prints for is a row whose label is still in the
  # file but no longer anywhere below a call site, which is the drift a rename leaves behind.
  #
  # IT ASSERTS ON THE `WHY` LINE, NOT ON THE FAIL HEADER, because the header is identical for
  # both arms: an ERE taken from it would be satisfied by the arm already proven, and this leg
  # would then be proof of nothing. That is the same SHAPE GATE 16 LEG 3 refuses one commit
  # above — and LEG 3 does NOT cover this population (its caveat (h): it reads the
  # parameterised drivers, not assert_fires_why's evidence-EREs), so the disambiguation here
  # had to be done by hand and by running. The mechanism has not reached this class yet.
  #
  # THE OBVIOUS MUTATION DOES NOT ISOLATE THIS ARM, WHICH WAS MEASURED, NOT REASONED. R6 says
  # to "point the label at a string that occurs nowhere". Run: that ALSO trips GATE 15's
  # label-EXISTENCE leg, which fires first with `The declared proof does not exist`, so the
  # run proves both arms at once and neither on its own — a fire-proof that cannot say which
  # check caught the defect is the ambiguity GATE 16 LEG 3 refuses one commit above.
  #
  # SO THE LABEL MUST EXIST AND BE OUT OF WINDOW. It is pointed at a marker that occurs in this
  # script but far from every `_g13` mention, which leaves the existence leg green and reaches
  # the `no occurrence in window` arm alone. The mutation ASSERTS BOTH HALVES of that premise
  # before writing — the marker is present, and no occurrence of it is within 40 lines of any
  # `_g13` line, a deliberately looser bound than BLOCK_WINDOW so a small drift aborts the
  # mutation with a named reason instead of silently proving the other arm.
  assert_fires_why "GATE 15 LEG 3 a BLOCK row whose label exists but never below a call site" \
    instruments \
    'WHY: the label does not occur in' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
a='_g13'+chr(9)
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
i=s.index(a)+len(a)
j=s.index(chr(9), i)
mark='preflight_support'+'_newlines'
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines()
hits=[k for k,l in enumerate(L) if mark in l]
near=[k for k,l in enumerate(L) if '_g13' in l]
assert hits and near, 'marker or _g13 gone from the script: %d/%d' % (len(hits),len(near))
assert min(abs(h-n) for h in hits for n in near) > 40, \\
    'the marker moved next to a _g13 line, so the in-window arm would answer instead'
open(p,'w',encoding='utf-8').write(s[:i]+mark+s[j:])"

  # THE CALLERS COUNT IS CHECKED, WHICH IS THE HALF OF CAVEAT (4) A MACHINE CAN HOLD TRUE.
  # The row that motivated caveat (4) said "four callers" against six and no gate noticed for
  # a round; this leg is that failure made loud.
  assert_fires_why "GATE 15 LEG 3 a callers count that drifted" instruments \
    'has callers=9; the rule in this table.s header counts 1' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
a=chr(9)+'kind='+'INVOCATION callers=1'+chr(9)
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a, chr(9)+'kind=INVOCATION callers=9'+chr(9), 1))"

  # EVIDENCE (B9's lesson applied at birth): the pinned census MOVES if any row's kind
  # changes or a row is dropped, so it proves the claims leg ran and produced its
  # classification — not merely that the mode exited 0. What it deliberately does NOT prove
  # is that the mutated NOTE was read, because it was not read: that is caveat (4), and this
  # control is the standing demonstration of it rather than a sentence asserting it.
  # RE-TAKEN 6 -> 7 kind=INVOCATION (round 9, item B2) when _g16b's row landed, and 7 -> 8
  # (round 10, item N4) when _g15d's did; each taken from a run under this mutation, and it
  # is the census MOVING that made the re-take necessary, which is the property being
  # asserted.
  assert_stays_clean_why "GATE 15 LEG 3 a rewritten note changes no claim" instruments \
    'claims column: 8 kind=INVOCATION' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
a=chr(9)+\"GATE 8's negative control: proves\"
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(
    a, chr(9)+'This sentence is false and no machine reads it: proves', 1))"

  # GATE 15 LEG 4 FIRE-PROOFS (item N4, round 10 drain-2, 2026-08-02) — THREE LEGS, ALL RUN.
  #
  # LEG 4 is a COVERAGE rule, and the instruction it was left under says why it needs three
  # rather than one: shipping a coverage rule in the same pass that grew the population it
  # counts is how a gate ends up proven against its own arithmetic instead of against a
  # defect. So none of these asserts on a COUNT. Each removes one confirmation and requires
  # the leg to name the builder that lost it:
  #   (a) the SHELL form  — the anchored guard after a `> "$_X_COPY"` redirect is stripped;
  #   (b) the PYTHON form — the `assert` before an `open(…,'w')` is stripped;
  #   (c) the CROSS-CHECK — the guard is left in place but rewritten to a shape LEG 2's
  #       extractor cannot read (an UNQUOTED pattern). LEG 2 then silently checks one guard
  #       instead of two and still prints [ok] with a smaller number, which is precisely the
  #       count-nobody-reads failure caveat (vi) has recorded since round 8. Without (c) this
  #       vacuity guard would be the untested half of the pair, and the untested half is what
  #       rots — GATE 8 shipped a one-directional comparison for exactly that reason.
  #
  # EACH LEG ASSERTS ON A SUBSTRING ONLY LEG 4 PRINTS, and the three are mutually distinct:
  # (a) names the shell wording, (b) the python wording, (c) the cross-check wording. If any
  # of those three FAIL messages is reworded, ITS PROOF MUST BE RE-TAKEN FROM A RUN — the
  # standing hazard item N2 names for GATE 4b LEG 7, and it applies here identically because
  # the same thing makes the proof meaningful: the string is what a build without the rule
  # cannot print.
  #
  # THE MUTATIONS CARRY NO SHELL METACHARACTERS. Every `$` and `"` they must write is built
  # with chr(36)/chr(34), and every anchor is assembled from fragments, so (i) this
  # fire-proof's own source cannot satisfy the anchor it searches for (item A2) and (ii)
  # nothing here is expanded by the shell before python sees it.
  _G15D_COPY=$(git rev-parse --git-dir)/doc_gates_g15d_copy.sh

  _g15d() {  # <label> <expected-substring> <python-mutation>
    if _G15D_COPY="$_G15D_COPY" python3 -c "$3" 2>/dev/null; then
      _G15DOUT=$(_gsrc "$_G15D_COPY" instruments)
      if printf '%s' "$_G15DOUT" | grep -qF "$2"; then
        echo "  [ok]   GATE 15 LEG 4 $1 — fires"
      else
        echo "  [FAIL] GATE 15 LEG 4 $1 — NOT reported, so an unconfirmed copy would ship"
        printf '%s\n' "$_G15DOUT" | sed 's/^/           > /' | head -6
        PASS=1
      fi
    else
      echo "  [FAIL] GATE 15 LEG 4 $1 — could not build the mutated copy (anchor moved), so"
      echo "         the assertion did NOT run. A skipped assertion is not a pass."
      PASS=1
    fi
  }

  _g15d "a shell-redirect copy whose anchored guard was stripped" \
        'and no anchored guard within' "
import os
G='&& '+'grep '+'-qE '+chr(39)+'^  _fireproof_undeclared_instrument'
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip().startswith(G)]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]='     && '+'true; then'+chr(10)
assert 'grep' not in L[t[0]], 'the guard survived the substitution'
open(os.environ['_G15D_COPY'],'w',encoding='utf-8').writelines(L)"

  _g15d "a python builder whose assert was stripped" \
        'with no assert earlier in the same' "
import os
W='.write'+'lines(out)'
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if W in l]
assert len(t)==1, 'builder anchor moved: %d' % len(t)
a=[i for i in range(t[0]-1,0,-1) if L[i].startswith('assert'+' ')]
assert a and t[0]-a[0] < 12, 'no assert in the builder-s own program: %s' % a[:1]
L[a[0]]='pass'+chr(10)
open(os.environ['_G15D_COPY'],'w',encoding='utf-8').writelines(L)"

  _g15d "a guard LEG 2's extractor can no longer read" \
        'and LEG 2 did not extract' "
import os
G='&& '+'grep '+'-qE '+chr(39)+'^  _fireproof_undeclared_instrument'
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip().startswith(G)]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=('     && '+'grep '+'-qE X '+chr(34)+chr(36)+'_G15_COPY'+chr(34)+'; then'+chr(10))
assert chr(39) not in L[t[0]], 'the pattern is still quoted, so LEG 2 would still read it'
open(os.environ['_G15D_COPY'],'w',encoding='utf-8').writelines(L)"

  rm -f "$_G15D_COPY"

  # GATE 16 FIRE-PROOFS (item A2, 2026-08-02) — REPRODUCE THE A6 NEAR-MISS, do not describe it.
  #
  # The motivating leg rewrites GATE 3's evidence-ERE to the corpus preflight's wording. That
  # is precisely what item A6 nearly shipped: an assertion about one gate that the preflight —
  # which runs before EVERY mode — would satisfy on its own, leaving the named gate free to
  # stop working unnoticed. Both legs mutate a COPY through the shared read-only source seam,
  # because the file to mutate is the one bash is executing (task #77, same reasoning as
  # GATE 15's).
  #
  # THE SECOND LEG IS THE VACUITY GUARD MADE LOAD-BEARING. A parser that silently skipped an
  # assert_fires_why invocation would leave that assertion unchecked forever and still print
  # [ok] with a smaller count than the file has calls — nobody reads counts. Deleting an
  # ERE argument must therefore be a FAIL, not a quieter [ok].
  #
  # BOTH COPIES ARE BUILT LINE-ANCHORED, IN PYTHON, AND THAT IS A CORRECTION. The first
  # version used `sed` plus a `grep -F` build check, and the vacuity leg FAILED in the
  # harness: its check asked whether the string `'spans a hard wrap'` had disappeared from
  # the copy, and that string still occurred — inside this fire-proof's own sed expression
  # and inside its own failure message. The build check could never succeed. Same shape as
  # GATE 15's first fire-proof (an assertion satisfied by its own source text), reached from
  # the opposite direction: there the injected string was found where it should not have
  # been, here it was found where its absence was the test. Both legs now match a WHOLE
  # STRIPPED LINE and assert the exact number of anchors found, so no other occurrence of
  # the text — comment, message, or the mutation itself — can participate.
  _G16_COPY=$(git rev-parse --git-dir)/doc_gates_g16_copy.sh

  if python3 -c "
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L)
   if l.strip()==chr(39)+'matched as the fixed string: \"hard floor k>=13\"'+chr(39)+' '+chr(92)]
assert len(t)==2, 'anchor moved: %d (GATE 3 and GATE 6 share this ERE)' % len(t)
L[t[0]]='    '+chr(39)+'tracked markdown missing from the working tree'+chr(39)+' '+chr(92)+chr(10)
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions)
    if printf '%s' "$G16OUT" | grep -qF 'is satisfied by a PREFLIGHT line'; then
      echo "  [ok]   GATE 16 an assertion reworded onto the preflight's wording — fires (the A6 near-miss)"
    else
      echo "  [FAIL] GATE 16 — a per-gate assertion whose ERE the corpus preflight emits was"
      echo "         NOT reported. That assertion would pass with its gate switched off."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 — could not build the mutated copy (GATE 3's ERE line anchor"
    echo "         moved), so the assertion did NOT run."
    PASS=1
  fi

  if python3 -c "
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L)
   if l.strip()=='retract-figures '+chr(39)+'spans a hard wrap'+chr(39)+' '+chr(92)]
assert len(t)==1, 'anchor moved: %d' % len(t)
del L[t[0]]
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions)
    if printf '%s' "$G16OUT" | grep -qF 'no evidence-ERE could be extracted'; then
      echo "  [ok]   GATE 16 an assert_fires_why whose ERE cannot be extracted — fires, not skipped"
    else
      echo "  [FAIL] GATE 16 — an invocation with no extractable ERE was passed over in"
      echo "         silence. The scan would under-report and still say [ok]."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 vacuity guard — could not build the mutated copy (the"
    echo "         'spans a hard wrap' anchor moved), so the assertion did NOT run."
    PASS=1
  fi
  # PHASE-4, the GATE 16 half: the "no templates at all" guard could not see ONE preflight
  # going quiet. A rewrite from `echo` to `printf` in either function would silently drop its
  # lines from the comparison, leave the other's, and print a plausible count nobody reads.
  if python3 -c "
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
out=[]; n=0; inb=False
for l in L:
    if l.startswith('preflight_support_newlines() {'): inb=True
    elif inb and l=='}'+chr(10): inb=False
    if inb and l.lstrip().startswith('echo '+chr(34)):
        l=l.replace('echo '+chr(34), 'printf '+chr(34)+'%s'+chr(92)+chr(92)+'n'+chr(34)+' '+chr(34), 1); n+=1
    out.append(l)
assert n>0, 'no echo lines found in preflight_support_newlines'
open('$_G16_COPY','w',encoding='utf-8').writelines(out)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions)
    if printf '%s' "$G16OUT" | grep -qF 'preflight_support_newlines() contributed ZERO message templates'; then
      echo "  [ok]   GATE 16 one preflight going quiet is a FAIL, not a smaller count"
    else
      echo "  [FAIL] GATE 16 — a preflight whose messages the extractor can no longer read was"
      echo "         not reported; its output would silently stop being compared."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 per-preflight guard — could not build the mutated copy, so the"
    echo "         assertion did NOT run."
    PASS=1
  fi
  rm -f "$_G16_COPY"

  # GATE 16 LEG 2 FIRE-PROOFS (item B2, round 9, 2026-08-02) — FOUR LEGS, ALL RUN.
  #
  # THE FIRST TWO ARE THE REAL HISTORICAL TEXT, not a synthesis. B2 expected to need a
  # synthesised motivating example because the two live instances round 8 found were fixed by
  # hand the same day; drain-2 then found a fifth, and this batch a sixth, so the leg is
  # proven against the exact lines that shipped:
  #   (1) `ledger` on "GATE 11 (A1) ledger deleted" — live from 3ab5161 to 8f2aed2. Both
  #       halves of GATE 11 require_tracked the same file, so the ERE was emitted by the
  #       FIGURES half and the leg stayed green with the PHRASES guard deleted.
  #   (2) `links` on "GATE 4 internal links" — live until this batch. That one was LATENT, not
  #       broken: its ERE really is emitted only by GATE 4. It is here because a fire-proof
  #       held to its gate by a wording argument is held by nothing a machine reads.
  # The other two are the vacuity guards, and they are the reason this leg's [ok] means
  # anything: (3) an invocation the extractor cannot see must be a FAIL rather than a smaller
  # total, and (4) a call-graph reader that has gone blind must be a FAIL rather than a
  # corpus in which nothing fans out.
  #
  # ALL FOUR MUTATE A COPY through the read-only source seam (task #77 — the file to mutate
  # is the one bash is executing), and each asserts the EXACT number of whole-stripped-line
  # anchors it found before writing. The anchors below occur in this comment's own vicinity
  # as python string literals; whole-line matching is what keeps a fire-proof from being
  # satisfied by its own source text, which this file has now recorded three times.
  _G16B_COPY=$(git rev-parse --git-dir)/doc_gates_g16b_copy.sh

  _g16b() {  # <label> <expected-substring> <python-mutation>
    if _G16B_COPY="$_G16B_COPY" python3 -c "$3" 2>/dev/null; then
      _G16BOUT=$(_gsrc "$_G16B_COPY" collisions)
      if printf '%s' "$_G16BOUT" | grep -qF "$2"; then
        echo "  [ok]   GATE 16 $1 — fires"
      else
        echo "  [FAIL] GATE 16 $1 — NOT reported, so the leg would stay green on it"
        printf '%s\n' "$_G16BOUT" | sed 's/^/           > /' | head -6
        PASS=1
      fi
    else
      echo "  [FAIL] GATE 16 $1 — could not build the mutated copy (anchor moved), so"
      echo "         the assertion did NOT run. A skipped assertion is not a pass."
      PASS=1
    fi
  }

  _g16b "LEG 2: the historical ledger dispatch on GATE 11's (A1) fire-proof" \
        'is 2 gates behind one exit code' "
import os
A='assert_fires_why \"GATE 11 (A1) ledger deleted\" ledger-phrases \\\\'
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip()==A]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace(' ledger-phrases ',' ledger ')
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  _g16b "LEG 2: the historical links dispatch on GATE 4's fire-proof" \
        'is 2 gates behind one exit code' "
import os
A='assert_fires_why \"GATE 4 internal links (documentation/GUIDE.md)\" links-internal \\\\'
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip()==A]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace(' links-internal ',' links ')
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  _g16b "LEG 2: an invocation the extractor can no longer see" \
        'One of the two extractors is wrong' "
import os
A='assert_stays_clean_why \"GATE 15 LEG 3 a rewritten note changes no claim\" instruments \\\\'
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip()==A]
assert len(t)==1, 'anchor moved: %d' % len(t)
del L[t[0]]
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  _g16b "LEG 2: a call graph that can no longer see one gate calling another" \
        'the call graph is' "
import os,re
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
n=0
for i,l in enumerate(L):
    if re.match(r'^\s+gate_[a-z0-9_]+\s*\|\|', l):
        L[i]=l.replace('gate_','command gate_',1); n+=1
assert n>0, 'no in-function gate call lines found'
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  # GATE 16 LEG 3 FIRE-PROOFS (item R4, round 11 drain-1, 2026-08-02) — BOTH DIRECTIONS.
  #
  # LEG 3 refuses a fire-proof substring that resolves to anything other than exactly one
  # message template, so it has two failure directions and both are exercised. Proving only
  # the rewording arm would ship the ambiguity arm untested, and item R7 says in as many words
  # that a matcher accepting too much is how the ORIGINAL defect (f5fac73) got in.
  #
  # THEY REUSE _g16b RATHER THAN ADDING A DRIVER, which is why `_g16b` is now the driver with
  # the larger caller count. That is deliberate: a third driver would be a third row to keep,
  # and LEG 3's own guard 2 requires every fixed-`$2` assertion to live inside a driver it can
  # read — so the cheapest way to keep that guard honest is to not multiply drivers.
  #
  # ARM 1 REWORDS A LIVE MESSAGE. It renames one word of GATE 15 LEG 4's shell-form finding in
  # the copy, which orphans the substring `_g15d`'s first leg asserts on. That is item N2's
  # hazard reproduced rather than described: N2 was a maintenance note naming a string no
  # assertion asserted on, and this is the same drift caught from the assertion's side.
  #
  # ARM 2 ADDS A SECOND PRINTER of the same wording — a decoy `echo` — so the substring becomes
  # producible by two templates and can no longer say which finding satisfied it.
  #
  # BOTH ANCHORS ARE ASSEMBLED FROM FRAGMENTS (item A2). Written whole, either would occur in
  # this fire-proof's own source, and arm 1's anchor would then match two lines and abort as
  # `anchor moved` instead of running. The split is load-bearing, not style.
  _g16b "LEG 3: a message reworded out from under a fire-proof's substring" \
        'no message template can produce' "
import os
A='and no anchored '+'guard within %d line(s)'
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if A in l]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace(A, 'and no anchored '+'sentinel within %d line(s)')
assert A not in L[t[0]], 'the wording survived the substitution'
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  _g16b "LEG 3: a second message able to produce the same substring" \
        'message templates can produce' "
import os
A='echo '+chr(34)+'-- GATE 16 LEG 3: '
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.lstrip().startswith(A)]
assert len(t)==1, 'anchor moved: %d' % len(t)
D='  echo '+chr(34)+'  [note] decoy: and no anchored '+'guard within lines'+chr(34)+chr(10)
L.insert(t[0], D)
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  # LEG 3's VARIABLE-CARRIED HALF (round 11 drain-2, 2026-08-02). THE ARMS BELOW PROVE
  # DIFFERENT PROPERTIES, which is the whole reason there is more than one of them.
  #
  # ARM 1 PROVES THE SITE IS SEEN. It renames the variable at the assertion only, so the
  # assignments still exist under the old name and the asserted name has none. Without this
  # arm, a sort that silently dropped the variable form would still print [ok].
  #
  # ARM 2 PROVES THE LITERALS ARE ACTUALLY RESOLVED. Seeing the site and comparing the string
  # it carries are separate properties, and arm 1 alone would leave the second untested — the
  # asymmetric-pair shape this file's history says rots on the untested side. It rewords GATE
  # 15 LEG 2's live unanchored-guard finding, which is what the `case`'s first arm asserts on,
  # so that literal resolves to zero templates. MEASURED BEFORE WRITING: that wording occurs
  # exactly once in the file, and no driver substring contains it, so the mutation cannot
  # orphan a second assertion and satisfy this arm by the other one.
  #
  # THE ARMS ASSERT ON THE VARIABLE HALF'S OWN MESSAGE, not on the driver half's. That is why
  # the variable half prints its own verdict line: an arm asserting `no message template can
  # produce` would be satisfiable by the driver-side finding the leg above already covers, and
  # a fire-proof satisfiable by the check it is not testing proves nothing about the one it is.
  #
  # BOTH ANCHORS ARE SPLIT (item A2). Written whole, arm 1's would occur in its own source and
  # match two lines; arm 2's would put a second contiguous copy of a live message in the file,
  # which is a second template and would make LEG 3 fail itself.
  _g16b "LEG 3: a fire-proof asserting on a variable with no resolvable literal" \
        'a variable this leg found no literal assignment for' "
import os
A='grep '+'-qF '+chr(34)+'\$_g15b'+'why'+chr(34)
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if A in l]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace(A, 'grep '+'-qF '+chr(34)+'\$_g15b'+'whyZZ'+chr(34))
assert A not in L[t[0]], 'the asserted name survived the substitution'
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  _g16b "LEG 3: a message reworded out from under a variable-carried substring" \
        'carries a fire-proof literal' "
import os
A='this guard'+chr(39)+'s ERE is not anchored '+'at line start'
L=open('scripts/doc_gates.sh',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if A in l]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace(A, 'this guard'+chr(39)+'s ERE is not anchored '+'at the head of a line')
assert A not in L[t[0]], 'the wording survived the substitution'
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  rm -f "$_G16B_COPY"

  # ------------------------------------------------------------------------------
  # GATE 17 FIRE-PROOFS (round-7 brief item 6, 2026-08-02) — FIVE LEGS.
  #
  # The first two REPRODUCE the two historical defects rather than describing them: ccn4's
  # verdict written by description and not at the id, and a load-bearing row nobody was
  # looking at. The remaining three exist because this gate's own first live run was WRONG
  # in both directions at once — it reported rs1 missing from both published boards and
  # invented an orphan row "Full" — and the fault was entirely in the parser. A gate whose
  # first run mis-parsed the corpus does not get to be trusted on a green run.
  _G17_TR=reports/TR1_EIGHT_CENTURIES_MEASURED.md

  # LEG 1 — THE MOTIVATING EXAMPLE, and it is a LEG-B (report-only) case, so it asserts on
  # OUTPUT and requires rc 0. Stripping ccn4's inline verdict recreates the corpus exactly as
  # it stood before TR-1 v1.23: the row IS classified, in prose, next to its description --
  # and this gate must nonetheless move it into the "no verdict at the id" bucket, because
  # that bucket is about FINDABILITY BY ID and nothing else. If this leg ever stops firing,
  # the gate has started crediting a verdict to a row that does not carry one, which is the
  # false clear that let the 2026-08-01 sweep call d7 "the last unclassified row".
  if python3 -c "
p='$_G17_TR'
s=open(p,encoding='utf-8').read()
a=' (*data-like* — see headline 1)'
assert s.count(a)==1, 'ccn4 inline-verdict anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'',1))" 2>/dev/null; then
    G17OUT=$(bash "$0" scoreboard 2>&1); G17RC=$?
    if [ "$G17RC" -eq 0 ] \
       && printf '%s' "$G17OUT" | grep -qF 'TR1_EIGHT_CENTURIES_MEASURED.md: 1/31 rule(s) carry a verdict at the id (d7)' \
       && printf '%s' "$G17OUT" | grep -qE 'TR1_EIGHT_CENTURIES_MEASURED\.md: 22 row\(s\) carry NO verdict at the id \(rs1, rs2, ccn1, ccn2, ccn3, ccn4,'; then
      echo "  [ok]   GATE 17 LEG 1: ccn4's verdict stripped from the id — 2/31 becomes 1/31 and ccn4 joins the silent bucket (the pre-v1.23 corpus)"
    else
      echo "  [FAIL] GATE 17 LEG 1 — the ccn4 row kept its verdict after the verdict was deleted"
      echo "         (rc=$G17RC). That is the ccn4 defect, inverted: the ledger would report a"
      echo "         classification nobody wrote."
      printf '%s\n' "$G17OUT" | grep -E 'TR1_EIGHT' | sed 's/^/           > /' | head -3
      PASS=1
    fi
    _selftest_revert "$_G17_TR"
  else
    echo "  [FAIL] GATE 17 LEG 1 — could not inject; the assertion did NOT run."; PASS=1
  fi

  # LEG 2 — LEG A, hard, on the other historical row. d7 was unclassified for weeks and was
  # found because a human named it; deleting its board entry outright is the coarsest version
  # of the same invisibility, and must be a FAIL naming d7 rather than a note.
  assert_fires_why "GATE 17 LEG 2: a registry rule deleted from the published board (d7)" \
    scoreboard 'registry rule\(s\) never reach the published board: d7' \
"p='$_G17_TR'
s=open(p,encoding='utf-8').read()
a=' · d7 1.7×10⁻⁴'
assert s.count(a)==1, 'd7 board-entry anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'',1))"

  # LEG 3 — THE VACUITY GUARD, and the one this gate most needs. If an anchor moves, the
  # naive outcome is an empty region: every id reads as missing, or (had the scan been written
  # the other way) nothing reads as missing and the run is GREEN with the instrument switched
  # off. That second outcome is the 2026-08-01 false clear exactly. The mutation breaks the
  # TABLE anchor specifically — the one added AFTER the first live run mis-parsed rs1 — so
  # this leg also pins the fix that run forced.
  assert_fires_why "GATE 17 LEG 3: the table anchor moved — an unlocatable board is a FAIL, not an empty scan" \
    scoreboard 'table anchor MISSING' \
"p='$_G17_TR'
s=open(p,encoding='utf-8').read()
a='estimates): rs1'
assert s.count(a)==1, 'table anchor already absent or duplicated: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'estimates) : rs1',1))"

  # LEG 4 — PROVES THE GATE READS THE REGISTRY, not a list transcribed into this script. A
  # gate that hard-coded the 31 ids would pass legs 1-3 unchanged and would be silent on the
  # only event it exists to catch: a rule added to solve.py that never reaches the board.
  # This is the same distinction GATE 14's "a NEW pair the allowlist has never seen" leg
  # draws, and it is the leg a refactor is most likely to quietly invalidate.
  assert_fires_why "GATE 17 LEG 4: a NEW registry rule that never reaches the board (proves the id list is derived, not transcribed)" \
    scoreboard 'never reach the published board: zzselftest' \
"p='solve.py'
s=open(p,encoding='utf-8').read()
a='REGISTRY_KW_EXPECTED = ['
assert s.count(a)==1, 'registry anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,a+chr(10)+'    (\"zzselftest\", 0),',1))"

  # LEG 5 — NEGATIVE CONTROL, and it targets the boundary rather than the happy path. The
  # word "principled" is inserted AFTER the close anchor, i.e. outside the table. A gate that
  # grepped the file instead of the bounded region would credit some row with a verdict it
  # does not have; the counts must not move. Without this leg, legs 1-4 are equally consistent
  # with a scan that reads the whole document.
  if python3 -c "
p='$_G17_TR'
s=open(p,encoding='utf-8').read()
a='Wrap-distance finals:'
assert s.count(a)==1, 'close anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'These are principled, data-like rows. '+a,1))" 2>/dev/null; then
    G17OUT=$(bash "$0" scoreboard 2>&1); G17RC=$?
    if [ "$G17RC" -eq 0 ] \
       && printf '%s' "$G17OUT" | grep -qF 'TR1_EIGHT_CENTURIES_MEASURED.md: 2/31 rule(s) carry a verdict at the id (ccn4, d7)'; then
      echo "  [ok]   GATE 17 LEG 5: a verdict word OUTSIDE the close anchor changes no count — the region bounds the scan"
    else
      echo "  [FAIL] GATE 17 LEG 5 — text outside the board moved the verdict ledger (rc=$G17RC),"
      echo "         so the gate is grepping the document, not reading the table."
      printf '%s\n' "$G17OUT" | grep -E 'TR1_EIGHT' | sed 's/^/           > /' | head -3
      PASS=1
    fi
    _selftest_revert "$_G17_TR"
  else
    echo "  [FAIL] GATE 17 LEG 5 — could not inject; the assertion did NOT run."; PASS=1
  fi

  # LEG 6 — PHASE-4 ON THIS UNIT'S OWN BATCH, and it is here because the first draft failed
  # it. Shortening BOARDS to a single path left `len(regions) != len(BOARDS)` satisfied, so
  # the gate printed "present on 1 board(s)" and exited 0 with the report-vs-documentation
  # comparison switched off entirely. A count nobody is required to read is not a check. The
  # mutation removes the documentation copy from the list and the gate must REFUSE.
  #
  # THIS LEG'S OWN FIRST RUN FAILED, and for the reason GATE 15's header already records:
  # the confirmation searched for the bare literal, which THESE VERY LINES write into
  # doc_gates.sh, so the copy always "still contained" the path and the leg reported it could
  # not build. The check is therefore anchored at line start (`^    "docum...`), which the
  # BOARDS entry matches and no line of this fire-proof does. Second instance of the class in
  # two days; the general lesson is that a fire-proof searching its own source file must
  # match on a form its own text cannot take.
  _G17_COPY=$(git rev-parse --git-dir)/doc_gates_g17_copy.sh
  if grep -v '^    "documentation/LITERATURE_RULES_POPULATION_TESTS.md",$' \
       scripts/doc_gates.sh > "$_G17_COPY" \
     && ! grep -qE '^    "documentation/LITERATURE_RULES_POPULATION_TESTS\.md",$' "$_G17_COPY"; then
    G17OUT=$(bash "$_G17_COPY" scoreboard 2>&1); G17RC=$?
    if [ "$G17RC" -ne 0 ] \
       && printf '%s' "$G17OUT" | grep -qF 'the board list holds 1 file(s)'; then
      echo "  [ok]   GATE 17 LEG 6: one of the two published boards dropped from the list is a FAIL, not a smaller count"
    else
      echo "  [FAIL] GATE 17 LEG 6 — the gate ran against ONE board and reported success"
      echo "         (rc=$G17RC). The report's copy of the table and the documentation's could"
      echo "         then diverge without anything noticing."
      printf '%s\n' "$G17OUT" | sed 's/^/           > /' | head -4
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 17 LEG 6 — could not build the mutated copy (the BOARDS entry anchor"
    echo "         moved), so the assertion did NOT run."
    PASS=1
  fi
  rm -f "$_G17_COPY"

  # THE COVERAGE GAP, STATED IN FULL. One gate is not mutation-tested here, and until
  # 2026-08-02 this note named only one gap at a time -- it said "GATE 2 + GATE 5" and
  # silently omitted GATE 8. A self-test that under-reports its own gap is the defect it
  # tests for, so the list is enumerated against the assertion calls above:
  #   covered: 1 (output), 3, 3b x3 (+negative control), 4, 4b, 5 (output) + its
  #            ALLOWLIST x3 (drift immunity, dead anchor, unanchored-and-inert),
  #            5b (output), 6 x3 (2 phrase + 1 FIGURE, item A8), 7 x2,
#            8 x5 (4 fire + 1 NEGATIVE control), 9 x2,
  #            10a (+negative control), 10b x3, 11, 12 x5 (+1 NEGATIVE control),
  #            13 x2 (worktree + batch) each with its own NEGATIVE control, and the batch
  #            one anchored on a REAL commit (b5bcff7c) rather than on an injection,
  #            14 x4 (the motivating r3/p1c4 pair, a NEW pair the allowlist has never seen,
  #            the uncomparable-rule refusal, and the A1 missing-input leg) + 1 negative
  #            control, 15 x5 (undeclared instrument, a row naming an assertion nobody
  #            wrote, a row for a function that no longer exists, and LEG 2's two clauses —
  #            a copy-confirmation guard written as an unanchored ERE and as the fixed
  #            string that was LIVE here until item A2) + its A1 leg + 1 negative
  #            control,
  #            17 x4 (LEG B's motivating ccn4 case, a registry rule deleted from the board,
  #            the moved-anchor vacuity guard, and a NEW registry rule proving the id list is
  #            derived from solve.py rather than transcribed) + 1 NEGATIVE control that puts a
  #            verdict word OUTSIDE the close anchor and requires the counts not to move
  #            + 1 PHASE-4 leg (one of the two published boards dropped from the list must be
  #            a FAIL, not a smaller count)
  #   plus the MISSING-INPUT class (item A1, 2026-08-02): 2 x2, 3, 3b, 6 x2, 10a, 10b,
  #            11 x2, 12, and the corpus preflight x1 -- 13 assertions, all asserting WHY.
#            (GATE 6 now has THREE A1 legs: its registry, a deleted generator, and the
#            FIGURE registry added with item A8.)
  #   Of those, the ones asserting WHY and not merely an exit code (item A5 / #65):
  #            3, 3b x2, 4b, 6 x3, 7 x2, 8 x5, 11, 12 x5, and the whole A1 class. GATES 1, 5 and
  #            5b are report-only and already assert on output. GATES 4, 9, 10a/10b are
  #            structural, not classifier-driven: there is no matched token for them to name.
  #            AS OF 2026-08-02 (item A1's residue, round 8) THIS LIST IS EVERY ASSERTION IN
  #            THE HARNESS: the last exit-code-only helper, assert_stays_clean, became
  #            assert_stays_clean_why and its negative controls each carry an evidence-ERE
  #            measured under their own mutation. THE STRENGTH TALLY IS NOT RESTATED HERE and
  #            the count of callers is not either — see assert_stays_clean_why's own header for
  #            the tally, and the machine-read `callers=N` on its row in
  #            DOC_GATE_SELFTEST_INSTRUMENTS.txt for the count. This sentence used to carry both
  #            ("only ONE of the six ... two ... three pin only that the leg ran") and round 9
  #            item B9 falsified every number in it in one commit (4e7fb94): four are now
  #            measured discriminators, three pin a count the control's own defect would move,
  #            and NONE pins only that the leg ran. Round 9 item B2 then marked the TOTAL stale
  #            here but left the 1/2/3 breakdown standing, so this file stated two contradictory
  #            tallies until the ledger unit read both. Strength is recorded AT EACH CALL SITE,
  #            because "they all assert WHY" would otherwise read as equal proofs; a second copy
  #            of the distribution in this inventory is a copy that nothing reads and nothing
  #            updates. That is caveat (4)'s class applied to this comment itself.
  #   plus 1 PROBE beside the GATE 3b control (round 8 drain-3) that exercises the FAILING
  #            direction of assert_stays_clean_why — the only leg here expected to fail, run in
  #            a command substitution so its PASS=1 cannot escape, and asserted on the evidence
  #            branch's own sentence rather than on [FAIL], which the rc branch also prints.
  #   NOW COVERED (item A3, 2026-08-02), and this entry is left in place rather than deleted
  #            because the reason it was uncovered is the useful part. It read: "Injecting a
  #            flag would mutate solve.py, a costlier revert than the assurance is worth."
  #            That was never measured. The revert is the same `git checkout -- .` the A1
  #            legs already use to restore an `os.remove`d sat.py, so the cost was identical
  #            to every other case in this file and the only real leg of a gate that has
  #            FIRED IN ANGER (13 undocumented flags, 2026-07/08) went unproven for a round
  #            behind an inherited cost claim. Three assertions now: py extractor, c
  #            extractor, and a negative control proving the comparison is a comparison.
  #   NOT covered, no fire-proof possible here: the TOOL-absence legs (GATE 8's python3,
  #            GATE 11's sha256sum), both converted from [skip] to [FAIL] under A1. Hiding
  #            one tool from $PATH cannot be done without also hiding git, grep and cut, so
  #            the gate would then fail for the wrong reason and the assertion would prove
  #            nothing. Those two legs are warranted by reading, not by running.
  # The old note said GATE 8 was excluded because ~90s regeneration "exceeds the
  # orchestrator's budget". MEASURED 2026-08-02 on the orchestrator: 45 s and 31 MB peak
  # RSS per run. The budget claim was inherited, not measured, and it was wrong; the
  # shared cache makes the marginal case free regardless.
  echo "  [note] not mutation-tested: the two tool-absence legs (GATE 8's python3, GATE 11's"
  echo "         sha256sum), which cannot be isolated from \$PATH without breaking the gate"
  echo "         for an unrelated reason. GATE 2's flag-drift classifier LEFT this list on"
  echo "         2026-08-02 (item A3) — three assertions, both extractors + a negative control."

  _selftest_revert
  echo
  [ "$PASS" -eq 0 ] && echo "DOC GATES SELF-TEST: PASS" || echo "DOC GATES SELF-TEST: FAIL"
  exit "$PASS"
fi

# ---------------------------------------------------------------------------
# GATE 8 — generated artifacts must match their generator.
#
# WHY (2026-08-01, two independent instances in one day):
#  (a) example/README.md was a hand-edited copy of example/report.md. They
#      differed by exactly one line — "keeps COMPLEMENTS unusually near one
#      another" where roae.py:774 emits "OPPOSITES". Someone edited the artifact
#      instead of the source, and it survived indefinitely.
#  (b) I did the same thing while fixing the C8 defect: patched roae.py AND
#      string-patched the four shipped artifacts, two independent routes to the
#      same text. Committed in dbba77d, caught by the operator, reverted.
#
# No other gate covers this. Retraction, link, status, number and liveness gates
# all pass on a hand-edited artifact, because the text is not retracted, the
# links resolve and the numbers are self-consistent. The defect is only visible
# by RE-RUNNING THE GENERATOR.
#
# Comparison is DIGIT-STRIPPED. roae.py seeds nothing by default, so Monte Carlo
# figures legitimately change every run; a byte-diff would fail always and the
# gate would be turned off within a day. Stripping digits compares the PROSE and
# the structure, which is where hand-edits live. Numeric drift is gate 1's job.
#
# COVERAGE, stated exactly (extended 2026-08-02, item A2). Until then the gate covered
# report.txt, report.md and README.md only — example/report.html and example/report.pdf
# were shipped generator-derived artifacts with NO generator-match check of any kind,
# and report.html is the file that was hand-patched in dbba77d. Both are now covered,
# by two DIFFERENT strategies, because a PDF cannot be line-diffed:
#
#   report.html  -> compared against a fresh `roae.py --html` (like-for-like, same as
#                   the other three: digit-stripped line diff, both directions).
#   report.pdf   -> compared against the SHIPPED example/report.html, by extracting the
#                   PDF's text with pdftotext and the HTML's text by tag-stripping, then
#                   comparing the two as MULTISETS of digit-stripped lines.
#
# The PDF leg deliberately does NOT regenerate. wkhtmltopdf(report.html) is the ONLY
# route by which report.pdf is produced (roae.py's export_html shells out to it), so
# "the PDF's text equals the shipped HTML's text" is exactly the derivation invariant,
# and checking it against the shipped HTML costs nothing and is deterministic. The
# chain closes: generator -> html (leg 4) -> pdf (leg 5). Regenerating a PDF and
# diffing it would instead compare two renderings whose page breaks move whenever a
# Monte Carlo figure changes width — a gate that fails for reasons nobody can act on.
# MEASURED before shipping: on the artifacts as committed the two bags differ by
# exactly ZERO lines once <title>/<style>/<script> are stripped.
#
# Cost: three roae.py runs (~45 s each, measured 2026-08-02 at 31 MB peak RSS), so this
# is NOT part of `all`. Run it before publishing. See DOC_GATES_GEN_CACHE below for how
# the self-test pays that cost ONCE across multiple invocations.
#
# DOC_GATES_GEN_CACHE (added 2026-08-02, item A1): a caller may name a directory to hold
# the regenerated reference artifacts. If it already holds a complete set generated from
# the CURRENT roae.py, it is reused instead of regenerating. This exists so the self-test
# can run several mutation cases for one regeneration; it is opt-in precisely because a
# silently-reused stale cache would be a false clear, and it self-invalidates on the only
# input that can change the answer — roae.py's own sha256.
gate_generated() {
  echo "== GATE 8: generated artifacts match their generator =="
  # Compare LIKE FOR LIKE. The first draft diffed every artifact against `--all`
  # stdout, so the markdown files failed on their own headers -- a gate that
  # flags correct files gets switched off, which is the mistake ops_gates GATE 4
  # made the same day. Each artifact is now compared against the invocation that
  # actually produces it.
  #
  # Digit-stripped: roae.py seeds nothing by default, so Monte Carlo figures
  # legitimately change every run. Stripping digits compares PROSE and structure,
  # which is where hand-edits live. Numeric drift is gate 1's business.
  local tmp rc=0 owned=0 cur_sha
  # ITEM A1 (tool half). This was a [skip], and roae.py IS python3 — without it the gate
  # regenerates nothing and compares nothing, while `generated` still exits 0. GATES 3b and 5
  # already invoke python3 with no guard at all, so a host without it cannot run this suite
  # anyway; saying so loudly beats attesting a comparison that never happened. NO FIRE-PROOF
  # COVERS THIS LEG — see the A1 note at the head of the file.
  command -v python3 >/dev/null 2>&1 || {
    echo "  [FAIL] python3 not on PATH — roae.py cannot be run, so nothing was regenerated"
    echo "         and nothing was compared. This is not a skip."
    return 1; }
  cur_sha=$(sha256sum roae.py 2>/dev/null | cut -d' ' -f1)

  if [ -n "${DOC_GATES_GEN_CACHE:-}" ]; then
    tmp="$DOC_GATES_GEN_CACHE"; mkdir -p "$tmp" || return 1
  else
    tmp=$(mktemp -d) || return 1; owned=1
  fi

  # Reuse only if the cache is COMPLETE and was built from THIS roae.py. A cache keyed on
  # nothing would turn a stale directory into a false clear — the failure mode this whole
  # suite exists to stop — so the key is the generator's own sha256, the only input that
  # can change what the reference should be.
  if [ -s "$tmp/fresh.txt" ] && [ -s "$tmp/report.md" ] && [ -s "$tmp/report.html" ] \
     && [ -n "$cur_sha" ] && [ "$(cat "$tmp/.roae_sha" 2>/dev/null)" = "$cur_sha" ]; then
    echo "  reusing regeneration cache $tmp (roae.py sha256 $(printf '%.12s' "$cur_sha")… unchanged)"
  else
    # `--markdown` and `--html` are run WITHOUT `--all` and from inside $tmp, because that
    # is what the generator actually does: roae.py's main() short-circuits on args.markdown
    # (returns before the --all dispatch), and export_markdown()/export_html() open their
    # files in the CWD. Spelling it "--all --markdown > file" is the recipe that corrupted
    # example/ once already; the gate should not model it. (Function names, not line
    # numbers, on purpose — a recorded line number is the thing that drifts, cf. the
    # GATE 5 allowlist.)
    echo "  regenerating (3 runs, ~45s each, unseeded): --all to stdout, then --markdown and --html into a temp dir"
    rm -f "$tmp/.roae_sha"
    if ! timeout 300 python3 roae.py --all > "$tmp/fresh.txt" 2>/dev/null; then
      echo "  [FAIL] the generator itself did not run cleanly"; [ "$owned" = 1 ] && rm -rf "$tmp"; return 1
    fi
    ( cd "$tmp" && timeout 300 python3 "$OLDPWD/roae.py" --markdown >/dev/null 2>&1 )
    ( cd "$tmp" && timeout 300 python3 "$OLDPWD/roae.py" --html     >/dev/null 2>&1 )
    [ -n "$cur_sha" ] && printf '%s\n' "$cur_sha" > "$tmp/.roae_sha"
  fi
  [ -f "$tmp/report.md" ] || { echo "  [skip] --markdown produced no report.md"; [ "$owned" = 1 ] && rm -rf "$tmp"; return 0; }

  # THE GROUP SEPARATOR IS PART OF THE NUMBER (fixed 2026-08-02, round 4).
  # The first version stripped [0-9] and nothing else, so roae.py's `f"{ratio:,}"`
  # (roae.py:1400) left a bare comma behind whenever a Monte Carlo figure landed at
  # >= 1000 on one side of the comparison and < 1000 on the other:
  #     artifact  "Approximately 1 in 476 random orderings share this property."
  #               -> "Approximately in random orderings share this property."
  #     generator "Approximately 1 in 1,046 random orderings share this property."
  #               -> "Approximately in , random orderings share this property."
  # That is a FALSE FAIL — it fired in anger on `doc_gates.sh generated` this round and
  # is the exact pair of lines the gate printed as +added/-missing. A gate that goes red
  # at random on correct artifacts is a gate that gets switched off, which is the same
  # failure mode the digit-stripping was introduced to avoid; it was simply not carried
  # through to the separator. Digit-adjacent commas are collapsed FIRST (the /g scan
  # handles multi-group values: 1,234,567 -> 1234567), then digits are stripped. Commas
  # that are not between two digits — ordinary prose punctuation — are untouched, so no
  # sensitivity to hand-edited prose is given up.
  # ITEM A2 (2026-08-02) — THE TWO QUESTIONS, ANSWERED BY RUNNING THE NORMALISER.
  #
  # Q1. WHAT LEGITIMATE VARIATION DOES THIS ERASE? Every numeric difference, by design.
  #     roae.py seeds nothing by default (`_global_seed`, roae.py:22 — a `--seed` flag
  #     exists but the shipped artifacts were not produced with it), so Monte Carlo figures
  #     differ every run and a byte comparison would fail always.
  #
  # Q2. WHAT ILLEGITIMATE VARIATION DOES IT LET THROUGH? A HAND-EDITED NUMBER. MEASURED,
  #     with a clean tree: corrupting `111111` to `911111` in example/report.txt and running
  #     `doc_gates.sh generated` gives rc 0 and prints
  #       "[ok] example/report.txt matches roae.py --all exactly (digit-stripped, both directions)"
  #     GATE 1 does not cover it either — GATE 1 iterates $DOCS = `git ls-files '*.md'`, and
  #     report.txt is not markdown. So for a corrupted digit in report.txt there is currently
  #     NO gate at all, and this one says "exactly" while missing it. That word is doing more
  #     work than the comparison behind it.
  #
  # AN ATTEMPTED FIX THAT FAILED, recorded so it is not rebuilt. Sample the generator TWICE
  # and treat a line identical in both samples as deterministic, requiring the artifact to
  # match those lines with digits intact. IT PRODUCES FALSE FAILS ON CORRECT ARTIFACTS, which
  # is round 4's `9084589` defect reached by a different route. Measured: `Min pair-constrained
  # observed:` (roae.py:1355, `min(pair_totals)` over `random.random()` draws) read 192 in two
  # consecutive runs and 189 in the shipped artifact; three further samples gave 193, 190, 192.
  # A min over a narrow discrete range repeats often, so two agreeing samples are not evidence
  # of determinism, and no number of samples turns that into a sound inference. The leg was
  # written, run against the CORRECT artifacts, seen to fire, and reverted. It is only because
  # the negative control ran that this was caught before shipping.
  #
  # WHAT WOULD ACTUALLY CLOSE Q2 FOR EVERY LEG is not a normalisation change: ship example/
  # generated with `--seed`, after which the comparison can be byte-exact and the whole
  # question disappears. That changes published artifacts, so it is an operator decision,
  # not a gate edit.
  #
  # WHAT WAS CLOSED WITHOUT IT (item A2 residual, 2026-08-02) — legs 5 and 6 below. The
  # reason legs 1-4 must strip digits is that they compare a shipped artifact against a
  # FRESH generator run. Two of the shipped artifacts are not in that relationship with
  # anything: report.pdf is rendered from report.html inside ONE `--html` invocation, and
  # README.md is a `cp` of report.md. Those two pairs agree digit-for-digit by
  # construction, so they are now compared with digits INTACT — leg 5 by multiset, leg 6
  # byte-exact. A hand-edited digit in report.html, report.pdf or README.md now fires;
  # before 2026-08-02 none of them did, and example/report.html had already been
  # hand-patched once (dbba77d, caught by the operator, not by a gate).
  #
  # THE HOLE THAT REMAINS, stated so the two new legs are not read as closing it:
  # example/report.txt is the output of a SEPARATE `--all` run and has no shipped partner,
  # so its digits are still compared by nothing — the measurement under Q2 above stands
  # exactly as written. The same is true of a hand-edit applied identically to BOTH
  # report.md and README.md. Digit coverage after this change is 4 artifacts of 5, and one
  # of those 4 (report.md) is covered only against its own copy.
  _norm() { sed -E 's/([0-9]),([0-9])/\1\2/g; s/[0-9]//g; s/[[:space:]]+/ /g' "$1" | grep -v '^ *$' | sort; }
  # BOTH DIRECTIONS. The first version compared one way only (`comm -13`: lines the
  # ARTIFACT has that the generator does not), so a pure DELETION from a shipped
  # artifact passed -- and passed while printing "matches ... exactly", which is the
  # same over-attestation this suite exists to catch. Demonstrated 2026-08-01 by
  # deleting the nuclear-attractor line from example/report.txt: the gate said [ok].
  # Substitutions were caught only because they leave an added line behind as well.
  # A MISSING shipped artifact is a FAILURE, not a skip (2026-08-02). Every leg below used
  # to `[skip]` on `! -f`, so `rm example/report.pdf` passed the gate in silence — the same
  # false-clear shape as the one-directional comparison, and reached the same way: by asking
  # what the gate does when its input is not there. Absence is only a skip for an artifact
  # git does not track; for a tracked one it is the strongest possible mismatch.
  # Hoisted to the top of the file as `require_tracked` (item A1, 2026-08-02) once the same
  # shape was found in GATES 2, 3, 3b, 6, 10a, 10b and 11. One implementation, so a future
  # correction to the rule cannot land in six places and miss the seventh.
  _present() {   # <path>
    require_tracked "$1" "A shipped artifact that is absent is not a passing artifact — regenerate it."
  }
  _cmp() {   # <artifact> <reference> <label>
    _present "$1"; case $? in 1) return 0;; 2) return 1;; esac
    local extra missing
    extra=$(comm -13 <(_norm "$2") <(_norm "$1") | wc -l)
    missing=$(comm -23 <(_norm "$2") <(_norm "$1") | wc -l)
    if [ "$extra" -eq 0 ] && [ "$missing" -eq 0 ]; then
      # NOT "matches exactly" (item A2, 2026-08-02). It said that for years while ignoring
      # every digit in both files, so a corrupted number was reported as an exact match. The
      # verdict now states its own scope: this comparison is silent about numbers.
      echo "  [ok]   $1 agrees with $3 on every NON-NUMERIC line (both directions; digits not compared)"
    else
      echo "  [FAIL] $1 vs $3: $extra added, $missing missing (normalised lines) -- hand-edited?"
      comm -13 <(_norm "$2") <(_norm "$1") | head -3 | sed 's/^/           +added   > /'
      comm -23 <(_norm "$2") <(_norm "$1") | head -3 | sed 's/^/           -missing > /'
      echo "         Fix the SOURCE (roae.py) and regenerate; never edit the artifact."
      echo "         CAUTION (recipe corrected 2026-08-01): only --all writes to stdout."
      echo "         --markdown and --html OPEN THEIR OWN FILES in the cwd (roae.py's"
      echo "         export_markdown / export_html) and print only a status line, so"
      echo "         'roae.py --markdown > f' writes 'Markdown report written to"
      echo "         report.md' INTO f and leaves the real report at the repo root."
      echo "         Run them from example/ instead:"
      echo "           python3 roae.py --all > example/report.txt"
      echo "           ( cd example && python3 ../roae.py --markdown )   # writes example/report.md"
      echo "           cp example/report.md example/README.md"
      echo "           ( cd example && python3 ../roae.py --html )       # writes report.html + report.pdf"
      return 1
    fi
  }
  _cmp example/report.txt  "$tmp/fresh.txt"   "roae.py --all"      || rc=1
  _cmp example/report.md   "$tmp/report.md"   "roae.py --markdown" || rc=1
  _cmp example/README.md   "$tmp/report.md"   "roae.py --markdown" || rc=1
  if [ -f "$tmp/report.html" ]; then
    _cmp example/report.html "$tmp/report.html" "roae.py --html"    || rc=1
  else
    echo "  [skip] --html produced no report.html"
  fi

  # LEG 5 — example/report.pdf is the wkhtmltopdf rendering of example/report.html.
  # No regeneration: see the header. Multiset (not sorted-diff) comparison, because
  # pdftotext reflows page-by-page and the ORDER of identical lines carries no
  # information here; what a hand-edit changes is WHICH lines exist.
  #
  # DIGITS ARE COMPARED HERE, and legs 5 and 6 are the ONLY legs in this gate that compare
  # them (item A2, 2026-08-02). Legs 1-4 compare a shipped artifact against a FRESH
  # generator run, and roae.py seeds nothing by default, so their Monte Carlo figures
  # legitimately differ and every digit must be stripped. Legs 5 and 6 compare two SHIPPED
  # artifacts that come out of ONE generator invocation — `roae.py --html` writes
  # report.html and then renders report.pdf from it — so their digits agree BY CONSTRUCTION
  # and a difference is a hand-edit. That asymmetry is the whole reason these two legs can
  # be strict where the others cannot.
  #
  # MEASURED BEFORE SWITCHING IT ON, on the shipped pair (2026-08-02):
  #   digits stripped : 0 pdf-only, 0 html-only, 1424 normalised lines
  #   digits INTACT   : 0 pdf-only, 0 html-only, 1428 normalised lines
  # Not reasoned — run. The 4-line difference in the totals is lines made up ENTIRELY of
  # digits, which the digit-stripped bag drops as empty: those four lines were previously
  # not compared at all, in either direction.
  #
  # THE FALSE-FAIL RISK, and why it is not the round-4 `9084589` shape. pdftotext -layout
  # decides line breaks from rendered text width, so in principle a longer number could
  # reflow a line and produce a difference that is not a hand-edit. If that happens the
  # PROSE moves across lines too, so the digit-STRIPPED comparison disagrees as well —
  # which is why a failure here recomputes the stripped bags and says which of the two
  # cases it is. A digits-only disagreement cannot be a reflow.
  _cmp_pdf() {   # <pdf> <html>
    _present "$1"; case $? in 1) return 0;; 2) return 1;; esac
    _present "$2"; case $? in 1) return 0;; 2) return 1;; esac
    command -v pdftotext >/dev/null 2>&1 || { echo "  [skip] no pdftotext — $1 not checked"; return 0; }
    python3 - "$1" "$2" <<'PY'
import collections, html, re, subprocess, sys, tempfile, os
pdf, htm = sys.argv[1], sys.argv[2]
with tempfile.TemporaryDirectory() as d:
    txt = os.path.join(d, 'p.txt')
    if subprocess.run(['pdftotext', '-layout', pdf, txt],
                      capture_output=True).returncode != 0:
        print(f"  [skip] pdftotext could not read {pdf}"); sys.exit(0)
    pdftext = open(txt, encoding='utf-8', errors='replace').read()
h = open(htm, encoding='utf-8', errors='replace').read()
for tag in ('style', 'script', 'title'):     # <title> duplicates the <h1>; not body text
    h = re.sub(r'(?s)<%s\b.*?</%s>' % (tag, tag), '', h)
# `</?[A-Za-z!]` and NOT `<[^>]+>`: roae.py emits unescaped "<->" inside <pre>, and the
# permissive pattern eats it — which silently made 69 lines look mismatched while the
# artifacts were in fact identical (measured 2026-08-02 while designing this leg).
h = html.unescape(re.sub(r'</?[A-Za-z!][^>]*>', '', h))
def bag(t, keep_digits):
    c = collections.Counter()
    for ln in t.splitlines():
        # Group separators are collapsed in BOTH modes, so "1,046" and "1046" are the same
        # number to this leg. wkhtmltopdf does not reformat numbers, but pdftotext -layout
        # can pad with spaces, and the separator rule is the one _norm above already uses —
        # keeping the contract single rather than double is deliberate (round 4's false FAIL
        # came from two legs disagreeing about what "the same line" means).
        ln = re.sub(r'(?<=[0-9]),(?=[0-9])', '', ln)
        if not keep_digits:
            ln = re.sub(r'[0-9]', '', ln)
        ln = re.sub(r'\s+', ' ', ln).strip()
        if ln: c[ln] += 1
    return c
P, H = bag(pdftext, True), bag(h, True)
only_p, only_h = P - H, H - P
if not only_p and not only_h:
    print(f"  [ok]   {pdf} is the rendering of {htm} "
          f"({sum(H.values())} normalised lines, both directions, DIGITS INCLUDED)")
    sys.exit(0)
# Which kind of difference is it? Recomputed, not guessed: if the digit-stripped bags
# agree, every differing line differs ONLY in its numbers, and a pdftotext reflow cannot
# produce that (a reflow moves prose too). Saying which case it is costs one more pass
# over data already in memory, and is the difference between "regenerate" and "someone
# edited a number".
sp, sh = bag(pdftext, False), bag(h, False)
if not (sp - sh) and not (sh - sp):
    print(f"  [FAIL] {pdf} vs {htm}: the PROSE agrees and the NUMBERS do not — "
          f"{sum(only_p.values())} line(s) only in the PDF, {sum(only_h.values())} only in the HTML")
    print("         A digits-only difference between these two cannot come from PDF reflow.")
else:
    print(f"  [FAIL] {pdf} vs {htm}: {sum(only_p.values())} line(s) only in the PDF, "
          f"{sum(only_h.values())} only in the HTML")
for x, n in list(only_p.items())[:3]: print(f"           +pdf-only  ({n}) > {x[:100]}")
for x, n in list(only_h.items())[:3]: print(f"           -html-only ({n}) > {x[:100]}")
print("         The PDF's ONLY production route is wkhtmltopdf(report.html) via roae.py's")
print("         export_html, so a difference means one of the two was edited by hand.")
print("         Fix roae.py, then: ( cd example && python3 ../roae.py --html )")
sys.exit(1)
PY
  }
  _cmp_pdf example/report.pdf example/report.html || rc=1

  # LEG 6 — example/README.md is a COPY of example/report.md (item A2, 2026-08-02).
  #
  # Legs 2 and 3 compare each of them, separately and digit-stripped, against a fresh
  # `--markdown` run. Neither compares them TO EACH OTHER, so until now the two shipped
  # files could disagree on every number in the corpus and this gate said [ok] twice.
  # The production route is a copy — the gate's own remediation text says
  # `cp example/report.md example/README.md` — so the pair can be compared BYTE-EXACT,
  # which is stronger than anything legs 1-4 can do. MEASURED before switching it on:
  # `cmp example/report.md example/README.md` is byte-identical on the shipped tree.
  #
  # WHAT THIS STILL CANNOT SEE: an identical hand-edit applied to BOTH files. That is a
  # real hole and it is not closable from here — it would have to be caught by legs 2 and
  # 3, which are digit-blind. So a hand-edited number surviving in both copies is caught
  # by nothing.
  _cmp_copy() {   # <copy> <original>
    _present "$1"; case $? in 1) return 0;; 2) return 1;; esac
    _present "$2"; case $? in 1) return 0;; 2) return 1;; esac
    if cmp -s "$1" "$2"; then
      echo "  [ok]   $1 is BYTE-IDENTICAL to $2 (digits included)"
      return 0
    fi
    echo "  [FAIL] $1 is not byte-identical to $2, but its only production route is a copy"
    diff "$2" "$1" | head -6 | sed 's/^/           /'
    echo "         Regenerate the original and re-copy; never edit either one by hand:"
    echo "           ( cd example && python3 ../roae.py --markdown )"
    echo "           cp example/report.md example/README.md"
    return 1
  }
  _cmp_copy example/README.md example/report.md || rc=1

  [ "$owned" = 1 ] && rm -rf "$tmp"
  return "$rc"
}

# ---------------------------------------------------------------------------
# GATE 10 — documentation/CORRECTIONS.md is APPEND-ONLY.
#
# WHY: a corrections ledger that can be edited is not a record, it is a draft. The
# failure mode is not malice — it is tidying: rewording an entry to read better,
# merging two entries, or dropping one that "was already fixed". Each of those makes
# the ledger agree with the present, which is exactly the property it must not have.
#
# WHAT IT CHECKS: every line of the LAST COMMITTED version must still be present, in
# order, in the working copy. `diff` is an LCS, so a moved or reworded line shows up as
# a deletion and fires — moving is not appending. Appending anywhere (including in the
# middle of the file, e.g. inserting a new entry between two existing ones) passes.
#
# NEGATIVE CONTROL: the self-test asserts BOTH halves — that a deleted line fires it and
# that a pure append does NOT. A gate with no negative control might simply always fail,
# and "it went red" would then be evidence of nothing.
#
# ITEM A2 (2026-08-02) — THE TWO QUESTIONS, for `diff`'s LCS.
#
# Q1. WHAT LEGITIMATE VARIATION DOES IT ERASE? Position. A line that survives anywhere in
#     the working copy, in the same relative order as its neighbours, is not a deletion —
#     which is what lets a new entry be inserted BETWEEN two existing ones without firing.
#     Nothing else: the comparison is line-exact, so whitespace, case and punctuation all
#     count, and a reworded entry is a deletion plus an addition.
#
# Q2. WHAT ILLEGITIMATE VARIATION DOES IT LET THROUGH? Two things, and both are real.
#     (i) INSERTION INSIDE AN ENTRY. "Append anywhere passes" is documented above as a
#     feature — it is how a new entry goes between two existing ones — but the same rule
#     lets a line be inserted in the MIDDLE of a committed entry, which can change what that
#     entry says while every one of its lines is still present and still in order. The gate
#     preserves lines; it does not preserve meanings.
#     (ii) DUPLICATION. Every committed line must still be PRESENT; nothing says it must be
#     present once. Appending a second copy of an existing entry passes, as it should, since
#     the file is append-only and a later entry may legitimately quote an earlier one.
#     GATE 10 is a preservation gate, not a uniqueness gate, and the [ok] wording says
#     "no committed line removed or reworded" rather than anything stronger.
#     BOTH WERE RUN, not reasoned (2026-08-02). Duplicating CX-07's heading line at EOF:
#     "[ok] no committed line removed or reworded (2 line(s) appended since HEAD)", rc 0.
#     Inserting a fresh bullet three lines INTO CX-07: same [ok], rc 0.
#
# ITEM A8 — THE MEASUREMENT A PER-ENTRY BOUNDARY RULE TURNS ON (2026-08-02). The proposal
# was "no insertion between an entry's own heading and the next heading". Before deciding,
# the question was measured over ALL 8 commits that have ever touched this file, comparing
# each CX entry's line block in parent and child:
#     121 entry-blocks unchanged
#       0 rewordings or removals inside a committed entry   <- GATE 10 is holding
#       1 mid-entry insertion: `2533bc89` added a bullet at offset 16 of CX-20's 30 lines
# SO THE RULE IS NOT FREE. That single insertion is legitimate and is the kind of edit this
# suite should want: a Phase-4 pass tightening its own "only such occurrence" claim to "the
# only one among the nine registered figures", added to the entry it qualifies, before push.
# A blanket boundary rule forbids it and pushes the qualification into a NEW entry that
# readers of CX-20 would never see.
#
# THREE OPTIONS, and the third did not exist when the item was filed: (a) forbid mid-entry
# insertion outright — costs the case above; (b) report-only [note] — cheap, no policy
# change; (c) forbid it only for entries that are ALREADY ON origin/main, which permits
# same-session tightening and still refuses to rewrite a published entry. (c) is the same
# published-vs-local distinction GATE 10b already draws against history, so the machinery
# exists. Which one applies is a closure call on a published append-only ledger and is
# deliberately NOT taken here.
#
# HOW THE MEASUREMENT WAS ARRIVED AT, because the number is only trustworthy with this
# attached: the first two versions of that checker were WRONG in the same direction. Both
# ended an entry at "the next `### CX-` heading or EOF", so the file's LAST entry absorbed
# everything after it — the trailing `<a id="gates"></a>` anchor and a whole following
# section — and every ordinary append to the file read as "an existing entry grew" or "an
# existing entry was reworded". v1 reported 4 mid-entry changes and v2 reported 2
# rewordings; both were artifacts, and GATE 10 would have had to be failing for either to
# be real. Only ending a block at the next heading OF ANY LEVEL gives the numbers above.
gate_appendonly_head() {
  echo "== GATE 10a: CORRECTIONS.md is append-only vs HEAD =="
  local f="documentation/CORRECTIONS.md"
  # ITEM A1. Deleting the ledger is the LIMITING CASE of the thing this gate forbids —
  # every committed line is gone at once — and it used to be the one way to make the gate
  # report nothing.
  require_tracked "$f" "Deleting the ledger removes every committed line at once: the maximal append-only violation."
  case $? in 1) return 0;; 2) return 1;; esac
  if ! git cat-file -e "HEAD:$f" 2>/dev/null; then
    echo "  [ok] $f is not yet in HEAD — nothing committed to be append-only against"
    return 0
  fi
  local tmp gone
  tmp=$(mktemp) || return 1
  git show "HEAD:$f" > "$tmp" 2>/dev/null
  gone=$(diff "$tmp" "$f" | grep -c '^< ' || true)
  if [ "${gone:-0}" -eq 0 ]; then
    local added
    added=$(diff "$tmp" "$f" | grep -c '^> ' || true)
    echo "  [ok] no committed line removed or reworded ($added line(s) appended since HEAD)"
    rm -f "$tmp"; return 0
  fi
  echo "  [FAIL] $gone committed line(s) no longer present — CORRECTIONS.md is append-only."
  echo "         Removed or reworded (first 5):"
  diff "$tmp" "$f" | grep '^< ' | head -5 | cut -c1-140 | sed 's/^/           /'
  echo "         If an entry is wrong, APPEND an entry saying so. Both stay."
  rm -f "$tmp"
  return 1
}

# ---------------------------------------------------------------------------
# GATE 10b — the SAME invariant against every version that ever existed, not just HEAD.
#
# WHY (2026-08-02, item A7). 10a's baseline is `git show HEAD:<f>`, which makes
# "append-only" mean "append-only since the last commit". Two ordinary operations
# reset it:
#
#   (1) COMMIT THE REMOVAL. Delete an entry, commit. 10a compared against the
#       pre-commit HEAD and fired — but on the very next run HEAD *is* the truncated
#       version, the working copy matches it, and the gate returns to [ok] forever.
#       The ledger is permanently shorter and the gate attests that it is intact.
#       This is the likelier of the two; it needs no unusual git at all.
#   (2) REWRITE THE HISTORY. amend / rebase / squash moves the baseline along with
#       the content it dropped.
#
# WHAT THIS HALF CHECKS: every non-blank line of every baseline version must still be
# present in the working copy, counting multiplicity. Baselines are (i) every commit
# reachable from HEAD that touched the file, and (ii) every remote-tracking ref's
# version of it.
#
# WHY (ii) IS NOT REDUNDANT, and it is the half that answers case (2): after an amend
# or a rebase the pre-rewrite commit is NO LONGER AN ANCESTOR OF HEAD, so walking
# `git rev-list HEAD` cannot see it — a walk alone would close case (1) and leave
# case (2) exactly as open as before. `refs/remotes/*` is not moved by a local
# rewrite, so anything already PUBLISHED stays a baseline whatever happens to the
# local history.
#
# WHAT THIS CANNOT SEE, stated rather than implied:
#   - a line committed locally and then amended away BEFORE it was ever pushed. It is
#     unreachable from HEAD and was never on a remote, so no baseline holds it. The
#     reflog does, but the reflog is local, expires, and is empty in a fresh clone —
#     it is not an invariant anything can be gated on.
#   - ORDER and BLANK LINES. This half is a multiset containment check, so a
#     re-ordering passes it. 10a is the order-sensitive half (diff is an LCS); the two
#     are complementary and both run.
#
# COST (stated as a formula first, per the box-safety rule): B distinct blob versions
# x L lines, where B = commits-touching-the-file + remote-tracking-refs. Measured
# 2026-08-02: B = 5, L = 525.
gate_appendonly_history() {
  echo "== GATE 10b: CORRECTIONS.md has lost no line from ANY committed or published version =="
  local f="documentation/CORRECTIONS.md"
  # ITEM A1, same limiting case as 10a and worse here: this half compares against every
  # PUBLISHED version, so a deleted working copy loses every line of all of them.
  require_tracked "$f" "Deleting the ledger loses every line of every published version at once."
  case $? in 1) return 0;; 2) return 1;; esac
  local cur tmp bad=0 n=0 blob src seen=""
  cur=$(mktemp) || return 1
  tmp=$(mktemp) || { rm -f "$cur"; return 1; }
  grep -v '^[[:space:]]*$' "$f" | sort > "$cur"
  # Baselines, deduplicated by BLOB id: a commit that did not change the file, and a
  # remote ref pointing at a commit already walked, contribute nothing.
  for src in $( { git rev-list HEAD -- "$f" 2>/dev/null
                  git for-each-ref --format='%(refname)' refs/remotes 2>/dev/null; } ); do
    blob=$(git rev-parse --quiet --verify "$src:$f" 2>/dev/null) || continue
    [ -n "$blob" ] || continue
    case " $seen " in *" $blob "*) continue;; esac
    seen="$seen $blob"
    n=$((n+1))
    git cat-file -p "$blob" 2>/dev/null | grep -v '^[[:space:]]*$' | sort > "$tmp"
    local lost
    lost=$(comm -23 "$tmp" "$cur" | wc -l)
    if [ "${lost:-0}" -ne 0 ]; then
      echo "  [FAIL] $lost line(s) present in $src ($blob) are absent from the working copy."
      echo "         That version is committed or published; append-only means it can never lose a line."
      comm -23 "$tmp" "$cur" | head -5 | cut -c1-140 | sed 's/^/           /'
      echo "         If an entry is wrong, APPEND an entry saying so. Both stay."
      bad=1
    fi
  done
  if [ "$n" -eq 0 ]; then
    echo "  [ok] $f has no committed or published version yet — no baseline to lose a line from"
  elif [ "$bad" -eq 0 ]; then
    echo "  [ok] every line of all $n distinct historical/published version(s) survives in the working copy"
  fi
  rm -f "$cur" "$tmp"
  return $bad
}

gate_appendonly() {
  local rc=0
  gate_appendonly_head    || rc=1
  echo
  gate_appendonly_history || rc=1
  return $rc
}

# ---------------------------------------------------------------------------
# GATE 11 — every REGISTERED retraction has an entry in the corrections ledger.
#
# WHY: RETRACTED_PHRASES.tsv (gate 3) stops a retracted wording from REAPPEARING. It
# says nothing about whether the retraction was ever RECORDED. Those are different
# failures, and the second is the quieter one: the corpus goes clean, the gate goes
# green, and no reader ever learns the claim was published in the first place.
#
# INDEPENDENCE (the reason this gate is worth having): it is registry-driven and does
# NOT consult scripts/corrections_inventory.sh's classifier. That classifier's C1 rule
# deliberately requires a hard retraction token and therefore deliberately under-fires;
# this gate is the instrument that catches what it misses. Two instruments that share a
# failure mode are one instrument.
#
# KEYING: each row is keyed by RP-<first 8 hex of sha256 of the retracted string>. The
# ledger cites the KEY, never the string — quoting the string in CORRECTIONS.md would
# reintroduce into the corpus the exact wording gate 3 exists to keep out. A key also
# cannot be faked by paraphrase, and a truncated quote cannot satisfy it.
gate_ledger() {
  local rc=0
  gate_ledger_phrases || rc=1
  echo
  gate_ledger_figures || rc=1
  return $rc
}

# GATE 11, FIGURES PASS (item A5, 2026-08-02) — the partner GATE 3b never had.
#
# GATE 11's phrases pass proves every RETRACTED_PHRASES.tsv row reaches CORRECTIONS.md.
# RETRACTED_FIGURES.tsv had no equivalent, so a figure could be registered, gated by GATE 3b
# on every run, and never recorded — the quieter half of the failure GATE 11 exists for.
#
# IT KEYS ON `RF-<sha8>`, NOT ON THE FIGURE TEXT, and that is the whole design. MEASURED
# before writing it: of the eleven registered figures, six OCCUR somewhere in CORRECTIONS.md
# and only four are RECORDED there. `1.4σ` (line 542) and `≈10×` (line 541) both appear
# inside CX-19's "How it was found" paragraph, as examples of meta-mentions found elsewhere
# in the corpus — a text-presence gate would have cleared two unrecorded retractions and
# called it coverage.
#
# OWN DISPATCH NAME (`ledger-figures`), for the reason GATE 4b got one: a self-test that
# asserts on the COMBINED `ledger` exit code is satisfied by the phrases pass failing, and
# would stay green if this pass were deleted. `ledger` still runs both.
#
# THE OPEN LIST IS NOT AN ALLOWLIST. documentation/DOC_GATE_FIGURE_LEDGER_OPEN.txt holds the
# seven figures whose ledger entries have not been written; each prints as [OPEN] with a
# count every run, in the shape GATE 4b uses for dangling section refs. A figure registered
# from today on FAILS unless it is recorded or deliberately listed. The list is deliberately
# NOT guarded by require_tracked: losing it makes this gate STRICTER, not blinder, which is
# the fail-safe direction (same argument as GATE 3b's allowlist).
gate_ledger_figures() {
  echo "== GATE 11 (figures): registered retracted FIGURES are recorded in CORRECTIONS.md =="
  local reg="documentation/RETRACTED_FIGURES.tsv" f="documentation/CORRECTIONS.md"
  local open="documentation/DOC_GATE_FIGURE_LEDGER_OPEN.txt" rcr=0 rcf=0
  require_tracked "$reg" "With the figure registry gone this pass has zero figures to look for." || rcr=$?
  require_tracked "$f"   "With the ledger gone every registered figure is unrecorded by definition." || rcf=$?
  if [ "$rcr" -eq 2 ] || [ "$rcf" -eq 2 ]; then return 1; fi
  if [ "$rcr" -ne 0 ] || [ "$rcf" -ne 0 ]; then return 0; fi
  command -v sha256sum >/dev/null 2>&1 || {
    echo "  [FAIL] sha256sum not on PATH — the RF-<sha> keying this pass is built on cannot"
    echo "         be computed, so the pass can check nothing. This is not a skip."
    return 1; }
  local bad=0 n=0 nopen=0 key fig note why
  require_final_newline "$reg"  || bad=1
  require_final_newline "$open" || bad=1
  while IFS=$'\t' read -r fig note; do
    case "$fig" in ''|'#'*) continue;; esac
    n=$((n+1))
    key="RF-$(printf '%s' "$fig" | sha256sum | cut -c1-8)"
    why=''
    if [ -f "$open" ]; then
      why=$(awk -F'\t' -v want="$fig" '$1==want {print $2; exit}' "$open")
    fi
    if grep -qF -- "$key" "$f"; then
      if [ -n "$why" ]; then
        echo "  [note] $key \"$fig\" is recorded in $f, but is still listed as open in"
        echo "         $open — delete that row."
      else
        echo "  [ok] $key \"$fig\" recorded"
      fi
    elif [ -n "$why" ]; then
      nopen=$((nopen+1))
      echo "  [OPEN] $key \"$fig\" — no ledger entry yet: $why"
    else
      echo "  [FAIL] $key \"$fig\" has NO entry in $f and is not listed in $open"
      echo "         registry note: $note"
      echo "         Either append an entry to $f citing $key, or add a row to $open"
      echo "         saying what still has to be adjudicated. Silence is not an option:"
      echo "         a figure can otherwise be registered, gated, and never recorded."
      bad=1
    fi
  done < "$reg"
  if [ -f "$open" ]; then
    while IFS=$'\t' read -r fig note; do
      case "$fig" in ''|'#'*) continue;; esac
      grep -qF -- "$(printf '%s\t' "$fig")" "$reg" || {
        echo "  [note] open-list row matches no registry row: \"$fig\""
        echo "         Either the figure was de-registered (delete the row) or the text drifted."; }
    done < "$open"
  fi
  if [ "$nopen" -ne 0 ]; then
    echo "  [note] $nopen registered figure(s) above are OPEN DEFECTS, not exemptions —"
    echo "         see $open. Writing those entries is an adjudication, not a gate change."
  fi
  [ "$bad" -eq 0 ] && echo "  [ok] all $n registered figure(s) accounted for ($((n-nopen)) recorded, $nopen open)"
  return $bad
}

gate_ledger_phrases() {
  echo "== GATE 11: registered retractions are recorded in CORRECTIONS.md =="
  local reg="documentation/RETRACTED_PHRASES.tsv" f="documentation/CORRECTIONS.md" rcr=0 rcf=0
  # ITEM A1. The old test named both files in ONE skip line, so a reader could not tell
  # which was missing; both are probed now and both verdicts print.
  require_tracked "$reg" "With the registry gone this gate has zero retractions to look for." || rcr=$?
  require_tracked "$f"   "With the ledger gone every registered retraction is unrecorded by definition." || rcf=$?
  if [ "$rcr" -eq 2 ] || [ "$rcf" -eq 2 ]; then return 1; fi
  if [ "$rcr" -ne 0 ] || [ "$rcf" -ne 0 ]; then return 0; fi
  # TOOL absence, not input absence: this was a [skip], which voided the whole gate while
  # the banner still said PASS. sha256sum is coreutils and is required by the keying scheme,
  # so its absence is a FAIL. NO FIRE-PROOF COVERS THIS LEG — see the A1 note at the head of
  # the file; hiding sha256sum from $PATH also hides git, grep and cut.
  command -v sha256sum >/dev/null 2>&1 || {
    echo "  [FAIL] sha256sum not on PATH — the RP-<sha> keying this gate is built on cannot"
    echo "         be computed, so the gate can check nothing. This is not a skip."
    return 1; }
  local bad=0 n=0 key
  require_final_newline "$reg" || bad=1
  while IFS=$'\t' read -r phrase allow note; do
    case "$phrase" in ''|'#'*) continue;; esac
    n=$((n+1))
    key="RP-$(printf '%s' "$phrase" | sha256sum | cut -c1-8)"
    if grep -qF -- "$key" "$f"; then
      echo "  [ok] $key recorded"
    else
      echo "  [FAIL] $key has NO entry in $f"
      echo "         registry note: $note"
      echo "         Add an entry to CORRECTIONS.md citing $key (append only)."
      bad=1
    fi
  done < "$reg"
  [ "$bad" -eq 0 ] && echo "  [ok] all $n registered retraction(s) accounted for"
  return $bad
}

# ----------------------------------------------------------------------------------
# GATE 14 — no two registry rules may be the same predicate (ITEM A6, 2026-08-02).
#
# WHY THIS EXISTS. `reg_r3` and `reg_p1c4` in solve.py are byte-distinct, separately
# attributed to two different authors, separately counted in a published total (EIGHT proven
# C1 constants — documentation/CLAIMS_DECIDED.md, TR-1 section 3) and separately proven in
# Lean 4 — and are the same function over orderings. That was found by hand on 2026-08-02.
# No gate looked for it, and nothing in the suite would have looked for the next one.
#
# WHAT IT DOES. Evaluates every rule in solve.py's REGISTRY_KW_EXPECTED over one SHARED,
# fully deterministic sample of orderings and compares the resulting value VECTORS. Two rules
# whose vectors are equal everywhere are reported; the adjudicated pairs live in
# documentation/DOC_GATE_REGISTRY_DUPLICATES.txt, and anything not there is a FAIL.
#
# COST, MEASURED NOT ESTIMATED (this is the reason it is in `all` and GATE 8 is not):
# 4,000 orderings x 31 rules = 124,000 rule evaluations, 4.4 s wall, a few MB resident —
# the sample is generated lazily and only 31 value-vectors are held. Sized as a formula
# before it was written, per the box-safety rule that a python DP's state key rebooted this
# orchestrator on 2026-08-01.
#
# THE SAMPLE IS THE INSTRUMENT, and a naive one would be worse than none. On UNIFORMLY
# RANDOM orderings nearly every boolean rule is False, so nearly every boolean PAIR would
# match and the gate would report ~200 duplicates, all spurious. The sample is therefore
# built where the rules are near their trip points:
#   * King Wen itself (every rule at its registry-expected value);
#   * ALL 2,016 single transpositions of KW — exhaustive, no sampling, no seed;
#   * 1,400 k-transposition perturbations, k = 2..8, seeded;
#   * 400 full shuffles, seeded, so a rule that only moves far from KW still moves;
#   * targeted MM-T5 witnesses (an ordering carrying the Qian-Kun-Zhen-Xun-Kan-Li-Gen-Dui
#     lower-trigram run in a window, at three offsets, plus 60 one-swap neighbours each).
# The witnesses are not decoration: WITHOUT them reg_mmt5 took ONE value across the whole
# sample, and a rule with one value is vacuously equal to every other constant rule and
# vacuously unequal to every varying one. Measured before and after.
#
# WHAT THIS GATE CANNOT SEE, said plainly rather than left to be inferred:
#   (a) It can prove two rules DIFFER. It cannot prove they are IDENTICAL — a finite sample
#       is a refutation instrument only. Every hit is a claim for a human to check, which is
#       exactly what the r3/p1c4 NOTEs in solve.py record having done.
#   (b) It compares VALUES, not attributions, not Lean theorems, not prose. Two rows can be
#       one ordering fact under two honest citations; that is O6/O2's question, not this
#       gate's.
#   (c) A rule that is constant on the sample is UNCOMPARABLE, and the gate FAILS on that
#       rather than passing quietly. A checker that reports [ok] on a rule it could not
#       examine is the false-clear class this suite exists to refuse.
gate_registry_dupes() {
  echo "== GATE 14: no two literature-registry rules are the same predicate =="
  local allow=documentation/DOC_GATE_REGISTRY_DUPLICATES.txt rca=0
  require_tracked "$allow" \
    "The allowlist IS half this gate: without it every adjudicated pair reads as new." || rca=$?
  [ "$rca" -eq 1 ] && return 0      # untracked and absent — nothing shipped is being checked
  [ "$rca" -eq 2 ] && return 1
  DOC_GATES_DUPE_ALLOW="$allow" python3 - <<'PY'
import itertools, os, random, sys
sys.path.insert(0, '.')
try:
    import solve
except Exception as exc:                       # noqa: BLE001 — any import failure is a FAIL
    print("  [FAIL] cannot import solve.py, so ZERO rules were compared: %s" % exc)
    print("         A gate that cannot load its subject has checked nothing.")
    sys.exit(1)

ids = [r for r, _ in solve.REGISTRY_KW_EXPECTED]
# PHASE-4 ON THIS GATE'S OWN FIRST DRAFT: without this, an emptied or renamed
# REGISTRY_KW_EXPECTED made the gate print "[ok] 0 rules, 0 pairs compared" and exit 0 — a
# green verdict from an instrument that compared nothing. Fewer than two rules cannot form a
# pair, so there is nothing this gate could have been doing.
if len(ids) < 2:
    print("  [FAIL] REGISTRY_KW_EXPECTED holds %d rule(s); fewer than two cannot form a pair,"
          " so this gate compared NOTHING" % len(ids))
    print("         A registry that shrank to nothing is a finding, not a clean run.")
    sys.exit(1)
kw = list(solve.binary_hexagrams)
# MM-T5's family order, quoted from reg_mmt5's own docstring so the witness cannot drift
# away from the rule silently.
FAMILY = [7, 0, 1, 6, 2, 5, 4, 3]


def witnesses():
    block = []
    for t in FAMILY:
        for h in range(64):
            if solve.lower_trigram(h) == t and h not in block:
                block.append(h)
                break
    rest = [h for h in kw if h not in block]
    for off in (0, 20, 49):
        yield rest[:off] + block + rest[off:]


def sample():
    yield list(kw)
    for i, j in itertools.combinations(range(64), 2):
        s = list(kw)
        s[i], s[j] = s[j], s[i]
        yield s
    rng = random.Random(20260802)
    for k in range(2, 9):
        for _ in range(200):
            s = list(kw)
            for _ in range(k):
                a, b = rng.randrange(64), rng.randrange(64)
                s[a], s[b] = s[b], s[a]
            yield s
    for _ in range(400):
        s = list(kw)
        rng.shuffle(s)
        yield s
    for w in witnesses():
        yield w
        for _ in range(60):
            s = list(w)
            a, b = rng.randrange(64), rng.randrange(64)
            s[a], s[b] = s[b], s[a]
            yield s


fns = [getattr(solve, "reg_" + r) for r in ids]
vecs = [[] for _ in ids]
n = 0
for seq in sample():
    if sorted(seq) != list(range(64)):
        print("  [FAIL] sample generator emitted a non-permutation at index %d" % n)
        sys.exit(1)
    n += 1
    # repr(), not the raw value, and the reason is a live hazard rather than tidiness:
    # `True == 1` in Python, so a boolean rule and a count rule that happened to return 1
    # would compare EQUAL under `==` and the gate would report a duplicate that is only a
    # type pun. registry_verify() guards the same confusion with `type(value) is
    # type(expected)`; this is the vector-comparison form of that check.
    for idx, fn in enumerate(fns):
        vecs[idx].append(repr(fn(seq)))

allow = {}
path = os.environ["DOC_GATES_DUPE_ALLOW"]
with open(path, encoding="utf-8") as fh:
    for lineno, line in enumerate(fh, 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 3 or not parts[2].strip():
            print("  [FAIL] %s:%d is not `a<TAB>b<TAB>note`, so the row exempts nothing"
                  " and names no reason" % (path, lineno))
            sys.exit(1)
        allow[tuple(sorted(parts[:2]))] = lineno

bad = 0
known = set(ids)
for pair, lineno in sorted(allow.items()):
    unknown = [r for r in pair if r not in known]
    if unknown:
        print("  [FAIL] %s:%d allowlists %s, which is not in REGISTRY_KW_EXPECTED"
              % (path, lineno, "/".join(unknown)))
        print("         A row keyed to a rule that no longer exists exempts nothing and"
              " hides that it exempts nothing.")
        bad = 1

flat = [ids[i] for i in range(len(ids)) if len(set(vecs[i])) < 2]
if flat:
    for r in flat:
        print("  [FAIL] reg_%s takes ONE value across all %d sampled orderings, so it cannot"
              " be compared" % (r, n))
    print("         An unvarying rule is vacuously equal to every other unvarying rule and"
          " vacuously")
    print("         unequal to every varying one, so its column of this gate is a false"
          " clear, not a pass.")
    print("         Add a targeted witness to the sample (see the MM-T5 witnesses) that"
          " makes it vary.")
    bad = 1

hits = []
for a, b in itertools.combinations(range(len(ids)), 2):
    if vecs[a] == vecs[b]:
        hits.append(tuple(sorted((ids[a], ids[b]))))

for pair in hits:
    if pair in allow:
        print("  [note] reg_%s and reg_%s agree on all %d sampled orderings — adjudicated at"
              " %s:%d" % (pair[0], pair[1], n, path, allow[pair]))
    else:
        print("  [FAIL] reg_%s and reg_%s return the SAME value on all %d sampled orderings"
              % (pair[0], pair[1], n))
        print("         Two registry rows that are one function are one ordering fact under"
              " two citations —")
        print("         separately attributed, separately counted in any published total,"
              " and separately")
        print("         proven. Check by hand, then record the verdict in %s." % path)
        bad = 1

stale = [(p, ln) for p, ln in sorted(allow.items())
         if p not in set(hits) and all(r in known for r in p)]
for pair, lineno in stale:
    print("  [FAIL] %s:%d allowlists reg_%s/reg_%s, but they now DIFFER on the sample"
          % (path, lineno, pair[0], pair[1]))
    print("         The exemption is stale: it would silently absolve a future duplication"
          " of the same")
    print("         pair that nobody adjudicated. Delete the row.")
    bad = 1

if not bad:
    print("  [ok] %d rules, %d pairs compared on %d orderings; %d adjudicated pair(s), 0 new"
          % (len(ids), len(ids) * (len(ids) - 1) // 2, n, len(hits)))
sys.exit(bad)
PY
}

# ----------------------------------------------------------------------------------
# GATE 15 — a new instrument in the --selftest region cannot land silent (ITEM A1, 2026-08-02).
#
# WHY THIS EXISTS, and why it is a gate rather than a resolution. `_selftest_revert` shipped
# at fbdbe26 with no fire-proof, in the one file whose header already records GATE 8 shipping
# a one-directional comparison behind a hand-taken proof. It was caught only because someone
# checked that commit message's claim against a run — and the claim was false (the ref
# resolved and its reflog held ZERO entries). That is the THIRD instance of one class in this
# file: GATE 8's hand-taken proof, GATE 4b's shared dispatch, and now this. Three instances
# of the same shape is a structural hole, and "be more careful" has already been tried.
#
# WHAT IT DOES. Enumerates every function DEFINED between the `--selftest` guard and its
# closing `fi`, and requires a row for each in documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt
# naming the assertion that proves it — or the explicit token NOT-PROVEN-IN-HARNESS with a
# reason. A declared label must actually occur in this file, so a row cannot point at an
# assertion nobody wrote.
#
# IT RUNS IN `all`, NOT ONLY IN --selftest, AND THAT IS THE POINT. The self-test needs a
# clean tree and takes minutes; a helper added during a normal edit would not meet it for
# hours. This gate is a text scan of one file and costs milliseconds.
#
# THE PARSER MUST NOT SILENTLY FIND NOTHING. If the region markers move, a naive scan
# returns zero functions and every row looks stale while nothing looks undeclared — a green
# run with the instrument switched off. Finding zero functions is therefore a FAIL, stated
# here because that is exactly the failure mode of the checker whose false clear hid a Lean
# defect for twelve hours on 2026-08-01.
#
# WHAT IT CANNOT SEE, said plainly (the full version is in the table's own header):
#   (a) It verifies that the function exists and that the named label exists. It CANNOT
#       verify the named assertion exercises the function. A row pointing at a real but
#       unrelated label passes. This is bookkeeping with a spell-check, not coverage proof.
#       The label search is over the WHOLE file, so a label that appears only in a comment,
#       or only inside another assertion's mutation string, satisfies it. That is not
#       hypothetical: this gate's own second fire-proof failed for exactly that reason on
#       its first run and had to assemble its substitute label from fragments.
#       AND THE BLIND SPOT HAD AN INSTANCE IN THIS GATE'S OWN FIRST ROW SET, found by the
#       row-by-row audit in round 8 (item A3): `scratch_appendonly` declared the label of a
#       real assert_fires_why that mutates the live repo and never calls it. Shipped with
#       the gate at 6d93ed5, green the whole time, re-pointed 2026-08-02. The audit's full
#       classification of all 10 rows — and why the cheap mechanical rule cannot ship as a
#       blanket FAIL — is in the table's caveat (1).
#   (b) --selftest region only. Helpers inside gate bodies are gate implementation and are
#       covered by the gates' own fire-proofs.
#   (c) It cannot rank proofs. `assert_fires_why`'s anchor-moved branch is exercised by
#       nothing; its row says so in prose that no machine reads.
gate_selftest_instruments() {
  echo "== GATE 15: every --selftest instrument declares the assertion that proves it =="
  local tbl=documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt rct=0
  require_tracked "$tbl" \
    "The declaration table IS this gate; absent, every instrument reads as declared." || rct=$?
  [ "$rct" -eq 1 ] && return 0
  [ "$rct" -eq 2 ] && return 1
  DOC_GATES_INSTR_TBL="$tbl" python3 - <<'PY'
import os, re, sys

# READ-ONLY SOURCE SEAM, and it exists for one reason that is worth stating because a
# testing backdoor in a gate deserves suspicion. The mutation this gate must be proven
# against is "a new function appears in the --selftest region" — and the file that would
# have to be mutated is THIS ONE, the script bash is currently executing. Task #77 is open
# on exactly that hazard (bash reads scripts by byte offset), and a fire-proof that risks
# leaving a half-restored doc_gates.sh behind is not worth the assurance. So the fire-proof
# mutates a COPY and points the scan at it, which is the same thing every other assertion in
# this file does — mutate the gate's input — the input here just happens to be the program.
# The seam is READ-ONLY (the file is scanned, never executed, never written) and an override
# is ANNOUNCED below, so it cannot quietly weaken a real run.
src = os.environ.get("DOC_GATES_SRC_OVERRIDE") or "scripts/doc_gates.sh"
if src != "scripts/doc_gates.sh":
    print("  [note] scanning OVERRIDE source %s (DOC_GATES_SRC_OVERRIDE), not the live script"
          % src)
if not os.path.isfile(src):
    print("  [FAIL] %s is not a readable file, so zero instruments were scanned" % src)
    sys.exit(1)
lines = open(src, encoding="utf-8").read().splitlines()

start = end = None
for i, ln in enumerate(lines):
    if start is None and '= "--selftest" ]; then' in ln:
        start = i
    elif start is not None and ln == "fi":
        end = i
        break
if start is None or end is None:
    print("  [FAIL] could not locate the --selftest region in %s (start=%s end=%s)"
          % (src, start, end))
    print("         The scan would have returned zero functions and reported [ok] on an")
    print("         instrument that was switched off. Re-anchor this gate, do not silence it.")
    sys.exit(1)

DEF = re.compile(r"^[ \t]*([A-Za-z_][A-Za-z0-9_]*)\(\)[ \t]*\{")
defined = {}
for i in range(start + 1, end):
    m = DEF.match(lines[i])
    if m:
        defined[m.group(1)] = i + 1

if not defined:
    print("  [FAIL] zero functions found in the --selftest region (lines %d-%d), which is"
          % (start + 1, end + 1))
    print("         a broken parser, not an empty harness. A checker that finds nothing must")
    print("         never report [ok].")
    sys.exit(1)

path = os.environ["DOC_GATES_INSTR_TBL"]
rows = {}
bad = 0
for lineno, line in enumerate(open(path, encoding="utf-8"), 1):
    if not line.strip() or line.lstrip().startswith("#"):
        continue
    parts = line.rstrip("\n").split("\t")
    if len(parts) < 4 or not all(p.strip() for p in parts[1:4]):
        print("  [FAIL] %s:%d is not `function<TAB>proof-label<TAB>claims<TAB>note`, so it"
              " declares nothing" % (path, lineno))
        print("         The claims column landed 2026-08-02 (round 9, items B8 + B3). A row")
        print("         in the old three-column shape carries no kind= and no callers=, and")
        print("         would be waved through by a parser that tolerated it.")
        bad = 1
        continue
    rows[parts[0]] = (parts[1], parts[2], parts[3], lineno)

whole = "\n".join(lines)
for name in sorted(defined):
    if name not in rows:
        print("  [FAIL] %s() is defined at %s:%d and is declared in NO row of %s"
              % (name, src, defined[name], path))
        print("         A new instrument in this harness lands with a fire-proof or lands")
        print("         declared as unprovable. `_selftest_revert` landed as neither"
              " (fbdbe26),")
        print("         and its commit message asserted a property it did not have.")
        bad = 1
        continue
    label, claims, note, lineno = rows[name]
    if label == "NOT-PROVEN-IN-HARNESS":
        print("  [note] %s() is declared UNPROVABLE in-harness (%s:%d) — %s"
              % (name, path, lineno, note.split(".")[0]))
    elif label not in whole:
        print("  [FAIL] %s:%d says %s() is proven by \"%s\", and that label does not occur"
              % (path, lineno, name, label))
        print("         anywhere in %s. The declared proof does not exist." % src)
        bad = 1

for name in sorted(rows):
    if name not in defined:
        print("  [FAIL] %s:%d declares %s(), which is no longer defined in the --selftest"
              " region" % (path, rows[name][3], name))
        print("         A row for a function nobody calls exempts nothing and hides that it")
        print("         exempts nothing. Delete the row.")
        bad = 1

# --- LEG 2 (ITEM A2, round 8 drain-2, 2026-08-02): a fire-proof that searches a COPY of
# this script must match on a form its own source lines cannot take.
#
# THE MOTIVATING EXAMPLE WAS LIVE WHEN THIS WAS WRITTEN, not historical. GATE 15's own
# first fire-proof built its copy with `sed` and confirmed the injection with an
# unanchored `grep -qF` for the injected literal — and `sed` reads THIS file, so the sed
# EXPRESSION carrying that literal was copied verbatim into the copy. The guard therefore
# succeeded on a copy in which nothing had been injected (measured: a deliberately moved
# anchor produced a byte-identical copy and the guard still passed). Item A2 lists five
# instances of this class across two days — GATE 15's label leg, GATE 16's vacuity leg,
# GATE 16's extractor, GATE 17 LEG 6's confirmation, and a stale-identifier sweep that
# matched itself and reported clean. Four of the five were caught by RUNNING, none by
# reading, and every fix was hand-applied at one site. This is the check on the class.
#
# THE RULE IS ITEM A2's SECOND FORM, the one that is mechanical: the confirmation must
# anchor on a form its own source cannot take. Concretely, a `grep -q` guard whose target
# is a `$..._COPY` of this script must (1) use an ERE (`-qE`) — a `-qF` fixed string
# cannot express an anchor at all — and (2) begin that ERE with `^`. Both live guards
# satisfy it; the pre-fix GATE 15 guard fails clause (1) and, with the `^` stripped,
# clause (2). Both directions are fire-proven in --selftest.
#
# IT CANNOT BE SATISFIED BY ITS OWN SOURCE, and that is DEMONSTRATED, not asserted —
# which is the whole point of the item. Two independent mechanisms:
#   * the pattern is written `grep\s+-q`, a form no line it searches for can take, so the
#     regex does not match its own definition (checked);
#   * the scan is bounded to the --selftest region, which excludes this gate body.
# The second is load-bearing TODAY and can be seen to be: caveat (v) below contains a
# literal `grep -qE "$PAT" "$_G15_COPY"` and the compiled pattern DOES match that line.
# It is excluded solely by the region bound. So if the region bound ever breaks, this gate
# flags its own documentation and goes RED — a loud failure, not the silent self-satisfying
# clear that item A2 catalogues five instances of. That is a standing proof rather than a
# claim, and it re-runs on every `all`.
#
# WHAT IT CANNOT SEE, stated because a clear is weaker than a failure:
#   (i)   `^` is NECESSARY, not sufficient. A source line that itself begins with the
#         guarded text at column 0 would still defeat an anchored guard. Neither live
#         guard has that shape (one starts `  if sed`, the other `     && !`), but this
#         gate does not check it.
#   (ii)  It sees `grep` guards only. A confirmation written in PYTHON — inside the builder
#         itself, as `assert len(t)==N` / `assert n>0` before the copy is written — is
#         outside the scan; those are item A2's FIRST form applied by hand. THE COUNT OF
#         SUCH LEGS IS DELIBERATELY NOT STATED: this caveat said "GATE 16's two legs" and
#         was stale twice over inside one day, which is the caveat-4 shape appearing in a
#         caveat. The SHAPE is what this points at; the population is re-measured below.
#   (iii) It says nothing about the MUTATION half: a mutation whose injected literal
#         collides with the corpus is item A2's other direction and is still hand-guarded
#         (`src.count(lbl)==1` in GATE 15's label leg).
#   (iv)  The scan is PER LINE, so a guard wrapped across a `\` continuation — `grep -q` on
#         one line, `"$_G15_COPY"` on the next — is invisible. MEASURED rather than left as
#         a worry, the way item A7's three-line window was: re-running this scan over
#         continuation-JOINED lines finds the same two guards and no third, so the blind
#         spot is real and currently empty. Two lines DO contain both tokens after joining
#         and are correctly not flagged — a comment and a [FAIL] message, both this leg's
#         own — which is also the evidence that the pattern discriminates. RE-MEASURED
#         2026-08-02 (item B10) after item B2 added four more fire-proofs: the joined scan
#         still finds the SAME TWO guards and no third. Re-taken from a run, not re-asserted
#         from the round-8 sentence — the blind spot is real and is still empty.
#   (v)   A guard whose pattern is a VARIABLE (`grep -qE "$PAT" "$_G15_COPY"`) is reported
#         as unanchored, because `$PAT` does not start with `^`. That is a false FAIL in the
#         conservative direction: this gate cannot follow an indirection, and refusing one
#         is better than clearing it. There are none today.
#   (vi)  CLOSED BY LEG 4 (item N4, round 10, 2026-08-02) — READ THIS ENTRY FOR THE HISTORY,
#         NOT FOR A NUMBER. The count THIS leg prints is still a FLOOR: deleting one of the
#         two anchored guards leaves the other and still prints [ok] with a smaller number.
#         Round 8 looked for a derived invariant to pin it against and found none, because the
#         `_COPY` VARIABLES are not in bijection with the guards — other legs confirm in
#         python instead. Round 9 found the thing that IS in bijection: copy BUILDERS. LEG 4
#         below now enforces "a copy may not be written without a confirmation of what went
#         into it" as coverage, so a deleted guard is a FAIL naming the builder that lost it
#         rather than a quieter count here.
#         NO POPULATION FIGURE IS STATED IN THIS COMMENT, DELIBERATELY. Round 9 recorded the
#         split as a number and the instruction "do not re-derive the 10/10 by hand", and
#         that instruction was not followable: only the COUNT was written down, and the
#         obvious definition of a builder — a shell redirect `> "$_*COPY"` plus an
#         `open('$_*COPY','w')` — returns SIX of the ten, silently. The four it misses write
#         through the environment, `open(os.environ['_*COPY'],'w')`. LEG 4 carries all three
#         syntaxes and PRINTS the per-syntax census every run, which is the durable form of
#         what this paragraph used to assert; a fourth syntax would still be invisible, and
#         a syntax falling to zero is now visible where the third one's absence was not.
#   (vii) It sees `grep -q` only. A confirmation written as `grep -c`, `[ -n "$(grep …)" ]`
#         or a `case` on file contents is outside the scan. Measured 2026-08-02 (item B10):
#         no confirmation in this region takes any of those three forms today, so (vii) is a
#         second real-and-currently-empty blind spot rather than an unmeasured one. It is
#         NOT the same hole as (ii) — (ii) is the PYTHON confirmation form. NO POPULATION
#         IS STATED HERE, and the reason is that one was: this sentence read `which is
#         populated at 8` from the day it was written (round 9), and LEG 4's own
#         fire-proofs then took that population to eleven without touching this line —
#         so the number was falsified by the same round's commits, in the same file,
#         ten lines from caveat (vi) which had just been rewritten to stop stating
#         populations. Caveat (ii) says outright that this count is deliberately not
#         stated; this line stated it anyway. THE LIVE FIGURE IS THE `N by an assert
#         earlier in the same python program` TERM OF LEG 4's [ok] LINE, which is
#         re-measured on every run and cannot go stale.
COPY_GUARD = re.compile(
    r"grep\s+-q([A-Za-z]*)\s+(?P<q>['\"])(?P<pat>.*?)(?P=q)[^&|;]*\$_[A-Za-z0-9_]*COPY")
guards = []
for i in range(start + 1, end):
    m = COPY_GUARD.search(lines[i])
    if m:
        guards.append((i + 1, m.group(1), m.group("pat")))

if not guards:
    print("  [FAIL] zero copy-confirmation guards found in the --selftest region (lines"
          " %d-%d)." % (start + 1, end + 1))
    print("         Two are known to exist (GATE 15's and GATE 17 LEG 6's). Finding none")
    print("         means the extractor stopped reading them, not that the harness stopped")
    print("         using them — a checker that finds nothing must never report [ok].")
    bad = 1

for lineno, flags, pat in guards:
    if "F" in flags:
        print("  [FAIL] %s:%d — this guard confirms an injection into a COPY of this script"
              " with a FIXED string:" % (src, lineno))
        print("           grep -q%s %s" % (flags, pat))
        print("         A fixed string cannot be anchored, and `sed`/`grep` build the copy")
        print("         FROM this file, so the guard's own source line is inside the copy it")
        print("         searches. It then passes with the injection switched off. Use -qE")
        print("         with a `^` anchor no line of the fire-proof itself can match.")
        bad = 1
    elif not pat.startswith("^"):
        print("  [FAIL] %s:%d — this guard's ERE is not anchored at line start:" % (src, lineno))
        print("           grep -q%s %s" % (flags, pat))
        print("         Unanchored, it also matches the fire-proof's own source line, which")
        print("         the copy contains verbatim. Anchor it with `^`.")
        bad = 1

# --- LEG 3 (ITEMS B8 + B3, round 9 drain-2, 2026-08-02): the claims column.
#
# WHAT IT REPLACES. Until today the only machine-read facts in a row were "this function
# exists" and "this label exists SOMEWHERE in doc_gates.sh". The table's caveat (1) recorded
# the consequence in its own first row set: `scratch_appendonly` named a real assertion that
# never called it, and the gate was green from 6d93ed5 until 2026-08-02. Round 8 offered two
# survivable designs — a reachability check, or a declared proof-KIND per row — and item B8
# names the second. Item B3's residue (an explicit `callers=N`) is the same format change, so
# it is taken here in one pass rather than twice.
#
# THE KINDS ARE THE THREE THE ROW-BY-ROW AUDIT MEASURED, not invented categories:
#   kind=INVOCATION  the label is the FIRST QUOTED ARGUMENT of a call to the declared
#                    function. Fully mechanical, and the strongest claim available: the label
#                    cannot then be satisfied by a comment or by another assertion's mutation
#                    string, which is what caveat (1a) is about.
#   kind=BLOCK       the label is echoed within BLOCK_WINDOW lines BELOW a call site of the
#                    declared function. Weaker, and it is the shape the three wrapper rows
#                    genuinely have (`_selftest_revert`, `_g13`, `_gsrc`).
#   kind=EXTERNAL    paired with NOT-PROVEN-IN-HARNESS, both directions enforced.
#
# THE STRONGEST SATISFIED KIND MUST BE DECLARED. A row saying BLOCK when the INVOCATION form
# holds is a FAIL — otherwise the column is an opt-out and a row could downgrade itself to
# escape the strict check, which is the ratchet every report-only gate in this file has had
# to argue about.
#
# THE CALL-SITE RULE IS ONE RULE, STATED ONCE, and it is stated in the table's header too so
# a row author can compute it. It counts the name in COMMAND POSITION — at line start, after
# `$(`, after `&&`/`||`/`;`/`|`/`then`/`else`/`do`, or opening a `trap` handler string —
# skipping comment lines and the function's own definition line.
#
# THAT RULE WAS MEASURED AGAINST THE HAND AUDIT, and it CORRECTED it. The table's caveat (4a)
# concluded "distinguishing the three requires a shell parse, not a grep" and published ten
# hand-adjudicated counts. This rule reproduces NINE of the ten exactly; on the tenth it says
# `_selftest_revert` has 24 call sites where the hand audit said 20. All 24 were read one by
# one; the ones the weaker rules missed are the `PASS=1; _selftest_revert; return; }` form
# and the `_selftest_revert; } \` form, four of each, every one a real call. So the number
# that shipped as the reason a mechanical form was impossible was itself wrong, and the
# mechanical form is what found it. (Cited by FORM, not by line — the first draft of this
# comment named eight line numbers and its own commit invalidated them, which is item B1
# happening inside the fix for item B8.)
#
# WHAT LEG 3 CANNOT SEE, stated because a clear is weaker than a failure:
#   (viii) BLOCK is PROXIMITY, not reachability — STILL TRUE, and it was NOT the worst of it.
#          A call followed within the window by a report line does not prove that line is on a
#          path the call reaches; it could sit in the `else`. Item B8's option (a), a `bash -x`
#          run with `PS4` carrying `$LINENO`, is the form that would close it. Round 10 drain-2
#          MEASURED that GATE 16 LEG 2's call-graph reader is NOT the reusable half — it maps
#          gate function to gate function and has no notion of statement position — so anyone
#          taking that route is starting from zero. The measured distance is printed every run
#          so a window that starts creeping is visible. NOT BUILT.
#
#          WHAT WAS BUILT, because it was a hole underneath that one (item N3, round 10
#          drain-3, 2026-08-02). Until today the check asked whether the label OCCURRED on a
#          line within the window, and an occurrence is not an echo. In the live harness the
#          `_selftest_revert` row's satisfier was
#          `… | grep -q 'A1 snapshot probe'` — the marker text the assertion searches FOR,
#          which merely BEGINS with the row's label "A1 snapshot". So the strongest row on this
#          gate was proven by a string the harness never prints; as measured on 2026-08-02 the
#          printed `+3` was the distance to that grep and the `[ok]` line was at `+4`.
#          PROVEN BEFORE THE FIX, not argued: setting the row's label to the full probe marker
#          `A1 snapshot probe` — a string this harness ECHOES NOWHERE, which is the property
#          the fire-proof guards and the only one it needs — left LEG 3 GREEN at the identical
#          `_selftest_revert +3`. The fire-proof is that exact mutation, so the leg is proven
#          against the real defect and not a stylised one. It states no occurrence count on
#          purpose: the commit that first wrote one falsified it in the same diff, by writing
#          this paragraph.
#          The check now requires a REPORT line (see REPORT_ECHO), and the FAIL prints the
#          non-report occurrence it rejected, so the reason is in the output and not only here.
#          THIS IS NOT REACHABILITY AND MUST NOT BE DESCRIBED AS SUCH. A report line inside a
#          dead `else` still satisfies it.
#   (ix)   `callers=N` is a SYNTACTIC call-site count. It does not know which sites execute,
#          and it does not know what the note's prose means by its own number: caveat (4a)(ii)
#          measured that `assert_stays_clean_why`'s "SIX negative controls" is a semantic
#          SUBSET of seven call sites. The column proves the total is current; the prose still
#          says what the total is made of, and nothing reads that.
#   (x)    The call rule does not parse heredocs or quoted blobs. A name in command position
#          inside a python `<<'PY'` body would be counted. There are none today (the rule
#          reproduces the hand audit), but it is a grep-shaped rule and it is not a shell.
#   (xi)   Because the FAIL prints the measured count, `callers=N` is cheap to satisfy by
#          copying the number the gate just printed. That makes it bookkeeping that cannot go
#          stale — which is exactly caveat (4)'s complaint — and nothing more.
BLOCK_WINDOW = 8
CALL_PRE = (r"(?:^[ \t]*|\$\([ \t]*|(?:&&|\|\||;|\||\bthen\b|\belse\b|\bdo\b)[ \t]*"
            r"|^[ \t]*trap[ \t]+['\"][ \t]*)")
CALL_POST = r"(?=[ \t;&|\"')]|$)"
# A REPORT LINE, which is what "the label is ECHOED below the call" was always supposed to
# mean and did not (item N3, round 10 drain-3, 2026-08-02 — see caveat (viii)). Every verdict
# this harness prints takes this one shape: `echo "  [marker] <label> …`, with the label
# starting immediately after the marker. Requiring the shape is what stops a line that merely
# CONTAINS the label — a grep pattern, a comment, a mutation string — from standing in for the
# assertion reporting.
#
# DECIDED 2026-08-02 (item R7, round 11 drain-1): `printf` IS NOT ACCEPTED, and the decision
# rests on a measurement rather than on the wording above. MEASURED over this script: every
# `printf` in it re-emits a CAPTURED VARIABLE through a pipe — `printf '%s\n' "$OUT" | sed`
# — as evidence under a verdict already written; not one of them writes an `[ok]`/`[FAIL]`
# marker itself. The two forms are doing different jobs here, so the rule is not merely
# accurate today, it matches how the harness is built. The count is not quoted: it moves, and
# the [ok] line prints the live distances every run.
# WIDENING IT WOULD BE A REGRESSION RISK, NOT A CONVENIENCE. A verdict written with `printf`
# is a FAIL under this rule — conservative and loud, a refusal rather than a reading, and
# nothing is silently cleared by it. A matcher that accepts too much is how f5fac73's defect
# got in: `printf '%s\n' "$OUT" | sed 's/^/           > /'` re-emits [FAIL] lines from a
# CAPTURED output, so a `printf`-tolerant matcher would let a fire-proof's own evidence dump
# stand in for the assertion reporting — the same class as the `grep -q 'A1 snapshot probe'`
# satisfier, reintroduced. If this is ever widened, it needs fire-proofs in BOTH directions:
# a `printf` verdict accepted, and a `printf` evidence dump still refused.
REPORT_ECHO = re.compile(r"^[ \t]*echo[ \t]+\"[ \t]*\[(?:ok|FAIL|WARN|note)\][ \t]*")


def call_sites(fn):
    pat = re.compile(CALL_PRE + re.escape(fn) + CALL_POST)
    dfn = re.compile(r"^[ \t]*" + re.escape(fn) + r"\(\)")
    out = []
    for i, ln in enumerate(lines):
        if ln.lstrip().startswith("#") or dfn.match(ln):
            continue
        out.extend(i + 1 for _ in pat.finditer(ln))
    return out


KINDS = ("INVOCATION", "BLOCK", "EXTERNAL")
kindcount = {k: 0 for k in KINDS}
blockdist = []
for name in sorted(defined):
    if name not in rows:
        continue
    label, claims, note, lineno = rows[name]
    kv = {}
    malformed = []
    for tok in claims.split():
        if tok.count("=") != 1 or not tok.split("=")[1]:
            malformed.append(tok)
        else:
            k, v = tok.split("=")
            kv[k] = v
    if malformed or set(kv) != {"kind", "callers"}:
        print("  [FAIL] %s:%d claims column is %r; it must be exactly `kind=<K> callers=<N>`"
              % (path, lineno, claims))
        bad = 1
        continue
    kind = kv["kind"]
    if kind not in KINDS:
        print("  [FAIL] %s:%d declares kind=%s for %s(); the kinds are %s"
              % (path, lineno, kind, name, "/".join(KINDS)))
        bad = 1
        continue

    sites = call_sites(name)
    if not kv["callers"].isdigit():
        print("  [FAIL] %s:%d callers=%s is not a number" % (path, lineno, kv["callers"]))
        bad = 1
    elif int(kv["callers"]) != len(sites):
        print("  [FAIL] %s:%d says %s() has callers=%s; the rule in this table's header"
              " counts %d" % (path, lineno, name, kv["callers"], len(sites)))
        print("         Call sites: %s" % ", ".join("%s:%d" % (src, s) for s in sites[:8])
              + (" ..." if len(sites) > 8 else ""))
        print("         A note claiming a count nobody reads is caveat (4); this column is")
        print("         the part of it that a machine can hold true.")
        bad = 1

    inv = re.compile(r"^[ \t]*" + re.escape(name) + r"[ \t]+\"" + re.escape(label) + r"\"")
    inv_at = [i + 1 for i, ln in enumerate(lines) if inv.match(ln)]

    if kind == "EXTERNAL":
        if label != "NOT-PROVEN-IN-HARNESS":
            print("  [FAIL] %s:%d declares kind=EXTERNAL for %s() but names an in-harness"
                  " label %r" % (path, lineno, name, label))
            bad = 1
    elif label == "NOT-PROVEN-IN-HARNESS":
        print("  [FAIL] %s:%d says %s() is NOT-PROVEN-IN-HARNESS but declares kind=%s"
              % (path, lineno, name, kind))
        print("         An unprovable instrument is kind=EXTERNAL; anything else claims a")
        print("         proof this harness does not contain.")
        bad = 1
    elif kind == "INVOCATION":
        if not inv_at:
            print("  [FAIL] %s:%d declares kind=INVOCATION for %s(), but no line of %s calls"
                  " it with that label as its first quoted argument"
                  % (path, lineno, name, src))
            print("         Label: %s" % label)
            print("         This is the scratch_appendonly defect (b4442cf): a row naming a")
            print("         real assertion that never calls the function it declares.")
            bad = 1
    else:  # BLOCK
        if inv_at:
            print("  [FAIL] %s:%d declares kind=BLOCK for %s(), but the INVOCATION form holds"
                  " at %s:%d" % (path, lineno, name, src, inv_at[0]))
            print("         The strongest satisfied kind must be declared, or the column is")
            print("         an opt-out from the check it exists to impose.")
            bad = 1
        else:
            hit = None
            bare = None
            for i, ln in enumerate(lines):
                if label not in ln:
                    continue
                near = [s for s in sites if 0 < (i + 1) - s <= BLOCK_WINDOW]
                if not near:
                    continue
                m = REPORT_ECHO.match(ln)
                if m and ln[m.end():].startswith(label):
                    hit = (i + 1, max(near))
                    break
                if bare is None:
                    bare = (i + 1, max(near))
            if hit is None:
                print("  [FAIL] %s:%d declares kind=BLOCK for %s(), but no [ok]/[FAIL] REPORT"
                      " line naming its label sits within %d lines below a call site"
                      % (path, lineno, name, BLOCK_WINDOW))
                print("         Label: %s" % label)
                if bare is None:
                    print("         WHY: the label does not occur in %s below a call site at"
                          " all." % src)
                else:
                    print("         WHY: an occurrence IS in window, at %s:%d (+%d), and it is"
                          " not a report line:" % (src, bare[0], bare[0] - bare[1]))
                    print("           %s" % lines[bare[0] - 1].strip()[:100])
                    print("         Until 2026-08-02 that occurrence satisfied this check. In")
                    print("         the live harness the satisfier was `grep -q 'A1 snapshot")
                    print("         probe'` — the text the assertion searches FOR — so the row")
                    print("         was proven by a string the harness never prints. A kind of")
                    print("         BLOCK claims the assertion REPORTS under this label.")
                bad = 1
            else:
                blockdist.append((name, hit[0] - hit[1]))
    kindcount[kind] += 1

# --- LEG 4 (ITEM N4, round 10 drain-2, 2026-08-02): A COPY MAY NOT BE WRITTEN WITHOUT A
# CONFIRMATION OF WHAT WENT INTO IT.
#
# WHAT IT CLOSES. LEG 2 above checks that every copy-confirmation GUARD is anchored, and its
# caveat (vi) says outright that the number it prints is a FLOOR: delete one of the two
# guards and LEG 2 still prints [ok] with a smaller number. Round 8 looked for a derived
# invariant to pin it against and did not find one, because the `$..._COPY` VARIABLES are not
# in bijection with the guards — several legs confirm in python instead. Round 9 measured the
# thing that IS in bijection: copy BUILDERS. Every line that writes a copy has a confirmation
# of what went into it, in one of two forms, and that is a coverage rule rather than a count.
#
# THE TWO CONFIRMATION FORMS ARE THE TWO THE CORPUS ACTUALLY USES:
#   shell-redirect  `sed|grep … > "$_X_COPY"` followed within CONFIRM_WINDOW lines by an
#                   anchored `grep -q…"$_X_COPY"`. LEG 2 then checks that guard is anchored;
#                   this leg checks it EXISTS. The two halves are what make the pair sound.
#   python          `open(…'_X_COPY'…,'w')` with an `assert` earlier in the SAME python
#                   program. This is item A2's first form, applied inside the builder.
#
# THE BUILDER DEFINITION IS THREE SYNTAXES AND THAT IS NOT COSMETIC. Reconstructing it from
# caveat (vi)'s recorded COUNT — a HISTORICAL measurement over the round-9 corpus, quoted here
# as history and not as this file's population — the obvious two, a shell redirect plus
# `open('$_X_COPY','w')`, returned SIX of the ten then known, silently: a plausible number, no
# error, and a coverage rule proven against a population missing four members. The four
# invisible ones write through the environment,
# `open(os.environ['_X_COPY'],'w')`. The per-syntax census is PRINTED on every run for exactly
# that reason: a syntax dropping to zero is now visible, where the third one's absence was not.
#
# WHY IT IS NOT SATISFIED BY ITS OWN SOURCE (item A2, the standing hazard in this file). Two
# independent mechanisms, and BOTH are real here rather than one being decorative:
#   * the three builder patterns escape the metacharacter they search for — the source of
#     BUILD_PY_LIT contains `open\(`, and the pattern demands `open` followed by a literal
#     `(`, so no builder regex matches its own definition line (checked);
#   * the scan is bounded to the --selftest region, which excludes this gate body entirely.
# Unlike LEG 2, whose first mechanism alone would not save it (caveat (v) there contains a
# line the compiled pattern DOES match), neither mechanism here is currently load-bearing on
# its own. That is a weaker claim than LEG 2's standing proof, and it is stated as weaker:
# nothing would go RED if the escaping stopped working, because the region bound would still
# hold. The fire-proofs below are what hold this leg non-vacuous, not this paragraph.
#
# WHAT LEG 4 CANNOT SEE, stated because a clear is weaker than a failure:
#   (xii)  It resolves the extent of a python program by QUOTE PARITY, walking up from the
#          builder to the nearest line with an odd number of unescaped `"`. If that line ends
#          with `"` it opens a shell string and the program starts below it; if it does not,
#          the builder is not inside a string at all and this leg refuses rather than
#          guessing. NO POPULATION IS QUOTED HERE ON PURPOSE — the first draft of this
#          sentence said "all eight python builders", and the same commit that wrote it
#          added three more. Every python builder resolving is what a green run of this leg
#          MEANS, so the run is the statement and this comment is not. It is NOT a shell
#          parser: a `'` -quoted blob, a heredoc, or a `$'…'` string would break the parity
#          walk, and a builder inside one would be refused with a FAIL naming the line —
#          conservative, but a FAIL nonetheless.
#          THE PARITY WALK DELIBERATELY DOES NOT SKIP COMMENT LINES, and that is the
#          opposite of what `uncommented` does two paragraphs up, so the reason is worth
#          having in writing before someone "fixes" it: inside the blob these lines are
#          PYTHON comments, the shell sees the whole blob as one quoted string, and their
#          quotes therefore do count toward its parity. Skipping them would desynchronise
#          the walk from what the shell actually did. Above the blob a shell comment's
#          quotes do NOT count — but the walk stops at the blob opener before it can reach
#          one, so the distinction never arises in the direction that would be wrong.
#   (xiii) It checks that an `assert` EXISTS earlier in the program, not that the assert is
#          ABOUT the thing being written. `assert 1==1` would satisfy it. This is the same
#          class as caveat (viii)'s proximity-not-reachability, one level down, and it is why
#          the shell half cross-checks against LEG 2's extractor and the python half does not:
#          no second extractor exists for the python form.
#          STILL NOT BUILT, AND THE OBVIOUS BUILD WAS MEASURED AND REJECTED (item R5, round 11
#          drain-1, 2026-08-02). The natural second extractor is a taint rule: the assert must
#          reference a name derived from the READ of the file being mutated. Evaluated against
#          every live python builder, it FAILS on the counter-shaped ones — the builders that
#          bind `n = 0`, increment it inside a loop over the file's lines, and then
#          `assert n > 0`. Their assert IS about the file, by a route the rule cannot see:
#          the increment rides on a `;`-joined statement or an element assignment (`L[i] = …`),
#          neither of which is a plain binding. A refinement that tainted loop-body bindings
#          was measured too and failed the same two for the same reason. SHIPPING IT WOULD
#          HAVE TURNED A CLEAN CORPUS RED, which is the failure R4's measurement caught one
#          leg over on the same day, so the epicycles stop here and the limit is recorded
#          instead.
#          THE WEAK FORM IS ALSO DECLINED, on this file's own threshold rather than on taste.
#          Requiring only that the assert mention some identifier would kill `assert 1==1` and
#          nothing else, and it passes every live builder — but LEG 2's header sets four
#          sightings as the bar for converting care into a mechanism, and the vacuous-assert
#          defect has ZERO sightings here. Building for it would add a leg, a fire-proof and a
#          callers count against a hypothetical. What makes this a live risk is asymmetry, not
#          frequency: the shell half is cross-checked and the python half is not, and it is the
#          LARGER half. That is the argument for a real second extractor, and it is not an
#          argument for a cheap one.
#   (xiv)  It sees the WRITE, not the CONTENT. A builder that asserts correctly and then
#          writes different bytes is outside it.
BUILD_SH = re.compile(r">[ \t]*\"\$(_[A-Za-z0-9_]*COPY)\"")
BUILD_PY_LIT = re.compile(r"open\([ \t]*'\$(_[A-Za-z0-9_]*COPY)'[ \t]*,[ \t]*'w'")
BUILD_PY_ENV = re.compile(
    r"open\([ \t]*os\.environ\[[ \t]*'(_[A-Za-z0-9_]*COPY)'[ \t]*\][ \t]*,[ \t]*'w'")
UNESCAPED_DQ = re.compile(r'(?<!\\)"')
PY_ASSERT = re.compile(r"^[ \t]*assert[ \t]")
CONFIRM_WINDOW = 2

def uncommented(ln):
    # A COMMENT CANNOT WRITE A FILE, and leaving this out was not a hypothetical. This leg's
    # own header comment contains the prose `> "$_X_COPY"` describing what a builder looks
    # like, and the first run read it AS one and demanded a guard for it. Same shape as GATE
    # 16 LEG 2's `uncomment`, found the same way — by running, not by reading. The header
    # sentence is deliberately left as it stands: it is a live occurrence of the pattern, in
    # a comment, inside the scanned region, so if this skip is ever removed the leg goes RED
    # on its own documentation rather than quietly mis-reading someone else's.
    return "" if ln.lstrip().startswith("#") else ln


builders = []
for i in range(start + 1, end):
    for rx, style in ((BUILD_SH, "shell-redirect"), (BUILD_PY_LIT, "python-literal"),
                      (BUILD_PY_ENV, "python-environ")):
        m = rx.search(uncommented(lines[i]))
        if m:
            builders.append((i + 1, style, m.group(1)))

if not builders:
    print("  [FAIL] LEG 4: zero copy BUILDERS found in the --selftest region (lines %d-%d)."
          % (start + 1, end + 1))
    print("         They exist, in THREE syntaxes, and the third was invisible to the")
    print("         obvious definition of a builder — which is why this message states no")
    print("         expected number: the per-syntax census on the [ok] line is the live")
    print("         count and this text would only go stale beside it. Finding none means")
    print("         this extractor stopped reading them, not that the harness stopped")
    print("         building copies — a checker that finds nothing must never report [ok].")
    bad = 1

guard_lines = {g[0] for g in guards}
shdist, pyconf = [], 0
for lineno, style, var in builders:
    if style == "shell-redirect":
        hit = None
        for j in range(lineno, min(lineno + CONFIRM_WINDOW, end) + 1):
            cand = uncommented(lines[j - 1])
            if ("$" + var) in cand and re.search(r"grep[ \t]+-q", cand):
                hit = j
                break
        if hit is None:
            print("  [FAIL] LEG 4: %s:%d writes $%s and no anchored guard within %d line(s)"
                  " confirms what went into it." % (src, lineno, var, CONFIRM_WINDOW))
            print("           %s" % lines[lineno - 1].strip())
            print("         `sed`/`grep` build the copy FROM this file, so a moved anchor")
            print("         yields a byte-identical copy and every assertion downstream")
            print("         passes with the injection switched off. Confirm the injection")
            print("         with an anchored `grep -qE` before using the copy.")
            bad = 1
            continue
        if hit not in guard_lines:
            print("  [FAIL] LEG 4: %s:%d confirms $%s at %s:%d, and LEG 2 did not extract"
                  " that line as a guard." % (src, lineno, var, src, hit))
            print("           %s" % lines[hit - 1].strip())
            print("         Two extractors written for different purposes disagree, so one")
            print("         of them is wrong. If LEG 2's is, it is silently checking fewer")
            print("         guards than the harness has and still printing [ok] — which is")
            print("         the count-nobody-reads failure this leg exists to end.")
            bad = 1
            continue
        shdist.append((var, hit - lineno))
    else:
        opener = None
        for k in range(lineno - 1, start + 1, -1):
            if len(UNESCAPED_DQ.findall(lines[k - 1])) % 2 == 1:
                opener = k if lines[k - 1].rstrip().endswith('"') else None
                break
        if opener is None:
            print("  [FAIL] LEG 4: %s:%d writes $%s and this leg could not establish which"
                  " python program it belongs to." % (src, lineno, var))
            print("         The parity walk found no line opening a shell string above it")
            print("         (caveat xii). A builder whose program cannot be delimited is")
            print("         refused, not cleared: the alternative is reading an unrelated")
            print("         `assert` from the program above as this one's confirmation.")
            bad = 1
            continue
        if not any(PY_ASSERT.match(lines[k - 1]) for k in range(opener + 1, lineno)):
            print("  [FAIL] LEG 4: %s:%d writes $%s with no assert earlier in the same"
                  " python program (opens at %s:%d)." % (src, lineno, var, src, opener))
            print("           %s" % lines[lineno - 1].strip())
            print("         The builder reads THIS file and writes a mutated copy of it. An")
            print("         anchor that has moved then produces a copy with nothing injected,")
            print("         and every assertion using it passes for the wrong reason. Assert")
            print("         the anchor count before the write, as the other builders do.")
            bad = 1
            continue
        pyconf += 1

if not bad:
    unprov = sum(1 for n in defined if rows[n][0] == "NOT-PROVEN-IN-HARNESS")
    # WORDED DOWN 2026-08-02 (round 8, item A3). This read "%d proven by a named assertion",
    # which is the over-claim caveat (1) of the table exists to deny — and the audit that
    # round found one of these rows naming a real assertion that never calls its function
    # (scratch_appendonly, misdeclared since GATE 15 shipped at 6d93ed5). A gate whose own
    # pass line claims more than its check performs is the false attestation this suite is
    # for, so it now says what it did: the label was found.
    print("  [ok] %d instrument(s) in the --selftest region, all declared; %d name an"
          " assertion whose label EXISTS (caveat 1: existing is not exercising),"
          " %d declared unprovable in-harness"
          % (len(defined), len(defined) - unprov, unprov))
    print("  [ok] %d copy-confirmation guard(s) all anchored at line start, so none can be"
          " satisfied by the fire-proof's own source text (item A2)" % len(guards))
    print("  [ok] claims column: %d kind=INVOCATION (label IS the call's first argument),"
          " %d kind=BLOCK, %d kind=EXTERNAL; every callers=N matches the header's rule"
          % (kindcount["INVOCATION"], kindcount["BLOCK"], kindcount["EXTERNAL"]))
    print("  [ok] BLOCK: each row's [ok]/[FAIL] REPORT line measured below a call site, not"
          " assumed (window %d): %s — caveat (viii): a report line is still proximity, not"
          " reachability"
          % (BLOCK_WINDOW, ", ".join("%s +%d" % b for b in sorted(blockdist))))
    syn = {}
    for _b in builders:
        syn[_b[1]] = syn.get(_b[1], 0) + 1
    print("  [ok] LEG 4: %d copy builder(s), every one confirmed — %d by an anchored guard"
          " LEG 2 also extracted (distance %s), %d by an assert earlier in the same python"
          " program" % (len(builders), len(shdist),
                        ", ".join("%s +%d" % d for d in sorted(shdist)), pyconf))
    print("       builder syntaxes seen: %s — a syntax falling to zero is a rewrite this"
          " leg can no longer see, not a corpus that stopped building copies"
          % ", ".join("%s %d" % (k, syn[k]) for k in sorted(syn)))
sys.exit(bad)
PY
}

# ----------------------------------------------------------------------------------
# GATE 16 — no per-gate assertion may be satisfiable by a PREFLIGHT (ITEM A2, 2026-08-02).
#
# WHY THIS EXISTS. Item A6 nearly shipped one: a new preflight would have printed the exact
# string GATE 11's fire-proof asserts on, so the preflight — which runs before EVERY mode —
# would have satisfied an assertion written about GATE 11, and GATE 11's leg could have
# stopped working without any assertion noticing. It was caught by hand. That is the A3/A7
# shared-DISPATCH defect arriving through a shared MESSAGE, and require_final_newline's
# `quiet` argument exists solely to dodge it. The dodge is real; the CHECK on the dodge was
# a sentence in a comment ("The preflight's wording therefore shares no substring with this
# one") that had never been mechanically verified. This gate verifies it.
#
# WHAT IT DOES. Extracts the evidence-ERE from every assert_fires_why invocation, extracts
# every line the two preflights can emit, expands their `$f` over the real file lists, and
# fails if any ERE matches any preflight-emittable line. Two preflights now run before every
# mode and both emit [FAIL] lines, so this is not hypothetical arithmetic.
#
# THE EXEMPTION IS NAMED AND PRINTED, NEVER SILENT. Two assertions are ABOUT a preflight and
# must match its output — that is their whole purpose. They are identified by their LABEL
# containing "preflight" (case-insensitive) and are listed in the output every run, so the
# exemption cannot quietly grow to cover an assertion that should have failed.
#
# THREE VACUITY GUARDS, because the failure mode of this gate is finding nothing and saying
# [ok] — the same shape as the checker whose false clear hid a Lean defect for twelve hours
# on 2026-08-01:
#   (1) one ERE must be extracted per assert_fires_why invocation; a mismatch is a FAIL, so
#       a parser that silently skips a call cannot pass;
#   (2) the preflight message set must be non-empty;
#   (3) the expanded candidate-line set must be non-empty.
#
# WHAT IT CANNOT SEE, stated rather than implied:
#   (a) `assert_stays_clean_why` and `assert_gen_*` are outside this scan. NARROWED TWICE on
#       2026-08-02. First (item A1, round 8): this note used to name assert_fires, and that
#       helper's six callers have since been converted to assert_fires_why — each with an
#       evidence-ERE taken from a real run — and the helper deleted, so those six are now
#       INSIDE this scan. Second (item A1's residue, drain-3): the note also said
#       assert_stays_clean "asserts on an EXIT CODE (rc 0) and carries no ERE", and that is
#       now FALSE — its six callers each carry an evidence-ERE too, and it was renamed
#       assert_stays_clean_why to say so at the call site.
#       IT IS STILL EXCLUDED, and now for a reasoned rather than a structural cause: a
#       preflight-emittable ERE cannot produce a false [ok] on a negative control, because
#       both preflights set RC=1 at their `|| RC=1` call sites below, so a firing preflight
#       fails that assertion at its rc test before the ERE is consulted. The collision this
#       gate exists to refuse is a FALSE PASS; on the stays-clean side the same collision can
#       only produce a loud [FAIL]. Extending the extractor to a second call shape would also
#       have to keep guard (1) exact, and guard (1) is what makes this gate non-vacuous.
#       assert_gen_* remain outside for the older and weaker reason: they do assert on an
#       evidence-ERE, but against GATE 8's `generated` output rather than through this
#       extractor.
#   (b) It over-approximates the candidate files (both preflights' file lists are unioned),
#       which is the conservative direction: it can report a collision that a real run would
#       not produce, never miss one that it would.
#   (c) LEG 1 reasons about the preflights only. A collision between two PER-GATE messages is
#       a different question — and LEG 2 below now asks half of it.
#
# LEG 2 — NO FIRE-PROOF MAY NAME A DISPATCH THAT RUNS MORE THAN ONE GATE (item B2, round 9,
# 2026-08-02).
#
# WHY IT IS A MECHANISM AND NOT MORE CARE. This is the same defect as LEG 1 reached from the
# other side: an assertion satisfiable by something other than the gate it names. LEG 1's
# "something" is a preflight; LEG 2's is the OTHER gate behind a shared dispatch name. It has
# now been found and fixed BY HAND six times — GATE 10a, GATE 10b, GATE 4b, GATE 11-figures
# (round 8), GATE 11-phrases (round 9, and that one was LIVE: both halves of GATE 11
# require_tracked the same ledger, so the assertion stayed green with the guard it tested
# deleted), and GATE 4 (this batch). Four sightings is this project's stated threshold for
# converting care into a mechanism; this is the sixth.
#
# WHAT IT DOES. Resolves each `assert_fires_why` / `assert_stays_clean_why` invocation's
# dispatch name through the `case` block and the gate-to-gate call graph, and FAILS if it
# reaches more than one gate function, or a name the dispatch block does not define.
#
# IT SHIPS WITH NO EXEMPTION MECHANISM, AND THAT IS A MEASUREMENT, NOT AN OMISSION. B2
# specified an escape hatch — allow a combined name when the ERE is proven to come from
# exactly one of the gates behind it — because one assertion needed it. That assertion was
# GATE 4's, its wording argument was true, and it was retired anyway (see its DISPATCH NOTE),
# leaving a population of ZERO. A blanket refusal with nothing to allowlist is strictly
# stronger than a rule with one hand-argued row in it, so the escape hatch was not built. If
# a future assertion genuinely must run a combined name, this leg has to grow one — and the
# right form is then a declared reason in the source, not a silent pass.
#
# WHAT LEG 2 CANNOT SEE:
#   (d) `assert_gen_*` take no dispatch name at all (they drive the `generated` gate through
#       their own harness), so they are outside this scan entirely.
#   (e) It is a STATIC resolution of `case` arms and `gate_x || rc=1` call lines. A gate
#       reached by `eval`, by a variable, or from outside a gate function is invisible; so is
#       a leg SKIPPED at runtime inside a single gate function, which is a different failure
#       (LEG 2 says "one gate answered", never "the leg inside it ran").
#   (f) Its own two vacuity guards are what make a green here mean anything, and they are
#       cross-checks rather than proofs: the invocation count must equal the `callers=N` that
#       GATE 15 LEG 3 derives by a different rule, and at least one gate function must still
#       be seen calling two others. Both are fire-proven in the self-test.
#
# LEG 3 — A FIRE-PROOF'S EXPECTED SUBSTRING MUST NAME EXACTLY ONE MESSAGE TEMPLATE (item R4,
# round 11, 2026-08-02).
#
# WHY IT IS A MECHANISM AND NOT MORE CARE. LEGS 1 and 2 both refuse an assertion satisfiable
# by something other than the gate it names — a preflight, or the other gate behind a shared
# dispatch. LEG 3 is the third source of the same false pass and the one nearest the
# assertion: a DIFFERENT FINDING BY THE SAME GATE. A fire-proof driver greps its gate's output
# for a fixed string; if two of that gate's messages can print that string, the leg goes green
# on the wrong one and the injected defect was never observed. Until this leg, that was an
# ARGUMENT WRITTEN IN A COMMENT, stated separately in each driver's row in
# documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt, one of them ending "which is an argument,
# not a check". Item N2 is the same hazard from the maintenance side: a note naming a string
# no assertion asserts on. This leg makes both mechanical.
#
# WHAT IT DOES. Reconstructs every message this harness can print — python `print(...)`,
# joining the literals of one call, and shell `echo "..."` — then resolves each fire-proof's
# expected substring against that set and FAILS unless exactly one template can produce it.
#
# BOTH FORMS THE HARNESS USES, and the second was added because the first was not the whole
# population (round 11 drain-2, 2026-08-02, from the round-11 could-not-see column):
#   * the DRIVER form, a helper asserting on its positional `$2`; and
#   * the VARIABLE-CARRIED form, where the substring is selected away from the call site — in
#     GATE 15 LEG 2's pair, in a `case` arm — and the assertion greps for the variable.
# The second was outside this leg in BOTH directions on the day the leg shipped: not a driver
# positional, so never parsed, and not matched by the driver guard either, so not reported as
# an orphan. That is the state a vacuity guard exists to make impossible, so the sort over
# fixed-string assertions is now exhaustive: driver positional, named variable, or FAIL.
#
# THE MATCH IS NORMALISED, AND THE NORMALISATION IS THE WHOLE DESIGN. A driver substring is
# compared against the message AFTER substitution, so a substring that pins a formatted value
# cannot match the template literally. Every %-specifier in a template, and every digit run on
# BOTH sides, collapses to one wildcard — which is what lets `is 2 gates behind one exit code`
# resolve against `which is %d gates behind one exit code:`. This was measured before it was
# written: under a plain literal containment test that substring resolved to ZERO templates,
# and a leg shipped on that test would have gone RED on a corpus with no defect in it.
#
# WHAT LEG 3 CANNOT SEE, stated because a clear is weaker than a failure:
#   (g) ONE TEMPLATE IS NOT ONE INSTANTIATION. The leg proves the substring identifies one
#       message; it cannot prove it identifies one CALL of that message. Measured, and printed
#       on the [ok] line every run so it is not only here: two `_g16b` legs assert on the same
#       `is %d gates behind one exit code` wording, so either could be satisfied by any
#       assertion whose dispatch reaches that many gates. Closing this needs the value pinned,
#       not the wording — which is a different check and is not claimed here.
#   (h) IT DOES NOT COVER THE INLINE-LITERAL FIRE-PROOFS — the ones that write the expected
#       string at the assertion itself rather than passing it to a driver or selecting it into
#       a variable. (This caveat opened as "the parameterised drivers ONLY"; the
#       variable-carried form was brought inside the leg the same day, and the sentence was
#       corrected rather than left to describe a coverage the leg had outgrown.) MEASURED
#       2026-08-02, the majority of those resolve to zero templates under this test because
#       their substrings pin a `%s` VALUE (a function name, a file name) rather than a digit.
#       That is not a defect in those fire-proofs — pinning the value is the STRONGER one —
#       and the naive widening is worse than incomplete: treating `%s` as "anything" makes
#       every substring producible by every `%s`-bearing template, so the exactly-one rule
#       becomes vacuous rather than strict. The count is deliberately not quoted; it moves
#       with the corpus and the property is what matters.
#   (i) It sees the TEMPLATE, not whether that template is reachable in the mode the driver
#       runs. This is caveat (viii)'s proximity-not-reachability limit again, one gate over.
#   (j) The python reconstruction counts parentheses including those inside string literals
#       and is bounded to TPL_SPAN lines. A template it mis-joins resolves its substring to
#       zero and FAILS by name — loud and wrong-way-round, never a silent clear.
#   (k) THE VARIABLE-CARRIED HALF RESOLVES A NAME, NOT A SCOPE. It gathers every literal
#       assignment to the asserted name anywhere in the file and requires each to resolve
#       uniquely; it has no notion of function scope, and no notion of WHICH `case` arm the
#       run that asserts actually takes. Both directions of that are refusals rather than
#       clears — a name reused in an unrelated function would put an extra literal under the
#       rule, and an assignment it cannot read as whole string literals is a FAIL instead of a
#       comparison against a fragment — but a refusal is still not a reading, and this is
#       caveat (i)'s reachability limit one level in.
#   (l) THE EXHAUSTIVE SORT IS EXHAUSTIVE OVER ONE SPELLING. It triggers on `grep -qF "$`; a
#       fixed-string assertion written `grep -F -q` or `-Fq` would carry a fire-proof
#       substring past the sort AND past the FAIL that exists to catch a form it cannot
#       classify. MEASURED 2026-08-02 rather than assumed: no such spelling occurs in this
#       file, and the only non-`-F` `grep -q… "$…"` lines are comments. Widening the detector
#       is the safe direction — it is a trigger, not a matcher — but it would have to widen
#       the two classifiers with it, and this is being recorded on ZERO sightings, which is
#       under the threshold this file applied to item R5 the same day.
#       Second, smaller: one variable asserted at two DIFFERENT sites is resolved once and
#       only its first site is named. The substring is still checked, so this costs a name in
#       a message, not a comparison.
gate_preflight_collisions() {
  local rc=0
  echo "== GATE 16: no per-gate assertion is satisfiable by a preflight =="
  python3 - <<'PY' || rc=1
import os, re, subprocess, sys

# The same read-only source seam GATE 15 uses, and for the same reason: the mutation this
# gate must be proven against edits an assertion inside THIS file, which bash is executing
# (task #77). Read-only, and announced below so it cannot quietly weaken a real run.
src = os.environ.get("DOC_GATES_SRC_OVERRIDE") or "scripts/doc_gates.sh"
if src != "scripts/doc_gates.sh":
    print("  [note] scanning OVERRIDE source %s (DOC_GATES_SRC_OVERRIDE), not the live script"
          % src)
if not os.path.isfile(src):
    print("  [FAIL] %s is not a readable file, so zero assertions were compared" % src)
    sys.exit(1)
lines = open(src, encoding="utf-8").read().splitlines()

# --- the assertions. The ERE is the first single-quoted token in the invocation's ARGUMENT
# LIST: the call line after the double-quoted label, then continuation lines, stopping at the
# line that opens the python mutation (column 0, `"`).
#
# THE STOP CONDITION IS NOT TIDINESS. Without it the scan walks into the mutation body and
# takes a quoted PYTHON literal as the ERE. Measured, not reasoned: with the 'spans a hard
# wrap' ERE deleted, the earlier 3-line-lookahead version reported the mutation's
# 'documentation/GUIDE.md' as that assertion's evidence-ERE — an assertion with NO evidence
# argument was scored as having one, and it then collided with a preflight line, so the gate
# fired for a reason that had nothing to do with the deletion. Found by running the vacuity
# fire-proof, which is exactly what that fire-proof is for.
#
# The label is skipped by starting the search after its closing quote, so a label containing
# an apostrophe cannot be mistaken for the ERE.
calls = [i for i, ln in enumerate(lines) if ln.startswith("  assert_fires_why ")]
QUOTED = re.compile(r"'((?:[^'\\]|\\.)*)'")
LABEL = re.compile(r'^  assert_fires_why "((?:[^"\\]|\\.)*)"')
found = []
for i in calls:
    m = LABEL.match(lines[i])
    label = m.group(1) if m else "<unparsed label at %s:%d>" % (src, i + 1)
    ere = None
    j, start = i, (m.end() if m else 0)
    while j < len(lines) and j <= i + 4:
        ln = lines[j]
        if j > i and ln.startswith('"'):
            break                       # the mutation body begins; the argument list is over
        q = QUOTED.search(ln, start if j == i else 0)
        if q:
            ere = q.group(1)
            break
        if not ln.rstrip().endswith("\\"):
            break                       # the invocation ended with no quoted ERE at all
        j += 1
    found.append((label, ere, i + 1))

bad = 0
missing = [(l, n) for l, e, n in found if e is None]
for label, n in missing:
    print("  [FAIL] no evidence-ERE could be extracted from the assert_fires_why at %s:%d"
          " (%s)" % (src, n, label))
    bad = 1
if len(found) != len(calls) or missing:
    print("         The extractor must produce exactly one ERE per invocation. A parser that")
    print("         silently skips a call would leave that assertion unchecked and still")
    print("         print [ok] — the false-clear shape this gate exists to refuse.")
    bad = 1

# --- what the preflights can print.
def body(name):
    out, on = [], False
    for ln in lines:
        if ln.startswith(name + "() {"):
            on = True
            continue
        if on and ln == "}":
            break
        if on:
            out.append(ln)
    return out

ECHO = re.compile(r'^\s*echo\s+"(.*)"\s*$')
templates = []
for fn in ("preflight_tracked_docs", "preflight_support_newlines"):
    b = body(fn)
    if not b:
        print("  [FAIL] %s() body not found in %s, so zero preflight messages were compared"
              % (fn, src))
        bad = 1
    n_before = len(templates)
    for ln in b:
        m = ECHO.match(ln)
        if m:
            templates.append(m.group(1).replace('\\`', '`').replace('\\"', '"'))
    # PHASE-4: the global "no templates at all" guard below would not notice ONE preflight
    # going quiet — a rewrite from `echo` to `printf` in either function would drop its lines
    # from the comparison and leave the other's, and the count nobody reads would still look
    # plausible. Each preflight must contribute at least one line of its own.
    if b and len(templates) == n_before:
        print("  [FAIL] %s() contributed ZERO message templates, so none of its output was"
              " compared against any assertion" % fn)
        print("         The extractor reads `echo \"...\"` lines; if this preflight now")
        print("         emits its findings some other way, teach the extractor that way.")
        bad = 1

files = []
for glob in ("*.md", "documentation/DOC_GATE_*.txt", "documentation/*.tsv"):
    files += subprocess.run(["git", "ls-files", glob], capture_output=True, text=True
                            ).stdout.split()

if not templates:
    print("  [FAIL] zero preflight message templates extracted — the scan is inert, not clean")
    bad = 1
candidates = set()
for t in templates:
    if "$f" in t:
        for f in files:
            candidates.add(t.replace("$f", f))
    else:
        candidates.add(t)
if not candidates:
    print("  [FAIL] zero candidate preflight lines after expansion — the scan is inert")
    bad = 1

exempt, checked = [], 0
for label, ere, n in found:
    if ere is None:
        continue
    if "preflight" in label.lower():
        exempt.append((label, n))
        continue
    checked += 1
    try:
        rx = re.compile(ere)
    except re.error as exc:
        print("  [FAIL] %s:%d — the evidence-ERE of \"%s\" does not compile: %s"
              % (src, n, label, exc))
        bad = 1
        continue
    hit = next((c for c in sorted(candidates) if rx.search(c)), None)
    if hit is not None:
        print("  [FAIL] %s:%d — the assertion \"%s\" is satisfied by a PREFLIGHT line:"
              % (src, n, label))
        print("           ERE : %s" % ere)
        print("           line: %s" % hit.strip())
        print("         A preflight runs before EVERY mode, so this assertion would pass")
        print("         with the gate it names switched off entirely. Reword one of the two.")
        bad = 1

for label, n in exempt:
    print("  [note] EXEMPT (asserts ON a preflight, by design): %s (%s:%d)" % (label, src, n))

if not bad:
    print("  [ok] %d evidence-ERE(s) checked against %d preflight-emittable line(s) from %d"
          " template(s); %d exempt" % (checked, len(candidates), len(templates), len(exempt)))
sys.exit(bad)
PY
  echo "-- GATE 16 LEG 2: no fire-proof names a dispatch that runs more than one gate --"
  python3 - <<'PY' || rc=1
import os, re, sys

# LEG 2 (item B2, round 9, 2026-08-02). See the gate header for why this is mechanical
# rather than another hand application.
src = os.environ.get("DOC_GATES_SRC_OVERRIDE") or "scripts/doc_gates.sh"
TABLE = "documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt"
if src != "scripts/doc_gates.sh":
    print("  [note] LEG 2 scanning OVERRIDE source %s, not the live script" % src)
if not os.path.isfile(src):
    print("  [FAIL] LEG 2: %s is not a readable file, so zero assertions were resolved" % src)
    sys.exit(1)
lines = open(src, encoding="utf-8").read().splitlines()
bad = 0

def uncomment(ln):
    # A shell comment cannot call anything. Reading them as calls is how this unit's FIRST
    # resolver decided `secrefs` reached gate_links: gate_secrefs' body carries a comment
    # naming gate_links, and the collapsed graph then hid the very fan-out being measured.
    return "" if ln.lstrip().startswith("#") else ln

GATEDEF = re.compile(r"^(gate_[a-z0-9_]+)\(\) \{")
GATECALL = re.compile(r"(?:^|;|&&|\|\||\bthen\b|\belse\b|\bdo\b|\{|\()\s*(gate_[a-z0-9_]+)\b")
defined = {m.group(1) for l in lines for m in [GATEDEF.match(l)] if m}

def fnbody(name):
    out, on = [], False
    for ln in lines:
        if ln.startswith(name + "() {"):
            on = True
            continue
        if on and ln == "}":
            break
        if on:
            out.append(uncomment(ln))
    return out

direct = {f: sorted({g for ln in fnbody(f) for g in GATECALL.findall(ln)
                     if g != f and g in defined}) for f in sorted(defined)}

def leaves(f, seen=frozenset()):
    if f in seen:
        return set()
    kids = direct.get(f, [])
    if not kids:
        return {f}
    out = set()
    for k in kids:
        out |= leaves(k, seen | {f})
    return out

CASE_OPEN = 'case "$MODE" in'
CASE_CLOSE = "esac"
LABEL_ROW = re.compile(r"^\s{2}([a-z0-9|*-]+)\)\s*(.*)$")
try:
    a = next(i for i, l in enumerate(lines) if l.startswith(CASE_OPEN))
    b = next(i for i in range(a, len(lines)) if lines[i] == CASE_CLOSE)
except StopIteration:
    print("  [FAIL] LEG 2: the dispatch block was not found in %s, so every mode would"
          " resolve to nothing and this leg would be inert" % src)
    sys.exit(1)
disp, cur = {}, None
for i in range(a + 1, b):
    ln = lines[i]
    m = LABEL_ROW.match(ln)
    if m:
        cur = m.group(1)
        disp.setdefault(cur, [])
        rest = uncomment("  " + m.group(2))
    else:
        rest = uncomment(ln)
    if cur:
        disp[cur] += GATECALL.findall(rest)
    if cur and ";;" in ln:
        cur = None
disp.pop("*", None)
reach = {k: (set().union(*[leaves(f) for f in v]) if v else set()) for k, v in disp.items()}

# --- the fire-proofs and negative controls, and the dispatch name each one names.
HELPERS = ("assert_fires_why", "assert_stays_clean_why")
CALLPOS = re.compile(r"(?:^|\$\()\s*(?:[A-Za-z_][A-Za-z0-9_]*=\$\(\s*)?(%s)\s+(?!\()"
                     % "|".join(HELPERS))
LABEL_ARG = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*(.*)$')
found = []
for i, ln in enumerate(lines):
    if not uncomment(ln):
        continue
    m = CALLPOS.search(ln)
    if not m:
        continue
    helper = m.group(1)
    toks, j = [], i
    while j < len(lines):
        l = lines[j]
        if j > i and l.startswith('"'):
            break               # the python mutation body opens at column 0
        toks.append(l)
        if not l.rstrip().endswith("\\"):
            break
        j += 1
    blob = " ".join(t.rstrip("\\").strip() for t in toks)
    tail = blob[blob.index(helper) + len(helper):].strip()
    la = LABEL_ARG.match(tail)
    if not la:
        found.append((helper, "<unparsed label>", None, i + 1))
        continue
    gm = re.match(r"^([A-Za-z0-9_-]+)(?:\s|$)", la.group(2))
    found.append((helper, la.group(1), gm.group(1) if gm else None, i + 1))

# --- VACUITY GUARD 1: an INDEPENDENTLY-DERIVED count of the same call sites.
# The failure mode of this leg is an extractor that silently skips an invocation and still
# prints [ok] with a number nobody reads. GATE 15 LEG 3 already machine-checks a `callers=N`
# for each helper, derived by a DIFFERENT rule (command position over the whole file, round 9
# item B3's residue). Two extractors written for different purposes must agree, or one of
# them is wrong and this leg says so instead of reporting a smaller total.
declared = {}
if os.path.isfile(TABLE):
    for ln in open(TABLE, encoding="utf-8").read().splitlines():
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        f = ln.split("\t")
        if len(f) >= 3:
            mm = re.search(r"callers=(\d+)", f[2])
            if mm:
                declared[f[0]] = int(mm.group(1))
else:
    print("  [FAIL] LEG 2: %s is missing, so this leg's extractor has nothing to be"
          " cross-checked against" % TABLE)
    bad = 1
for h in HELPERS:
    mine = sum(1 for x in found if x[0] == h)
    if h not in declared:
        print("  [FAIL] LEG 2: %s declares no callers=N in %s, so a skipped invocation would"
              " be invisible here" % (h, TABLE))
        bad = 1
    elif declared[h] != mine:
        print("  [FAIL] LEG 2: %s — this leg resolved %d invocation(s); %s declares"
              " callers=%d. One of the two extractors is wrong; a silent under-count here"
              " would leave that assertion's dispatch unchecked forever."
              % (h, mine, TABLE, declared[h]))
        bad = 1

# --- VACUITY GUARD 2: the call graph must still SEE fan-out.
# If the resolver stops reading `gate_x || rc=1` bodies, every dispatch name collapses to one
# leaf and this leg goes green on a corpus it can no longer measure. At least one gate
# function must be seen calling two or more others.
fanout = sorted(f for f, kids in direct.items() if len(kids) > 1)
if not fanout:
    print("  [FAIL] LEG 2: no gate function was seen calling two others, so the call graph is"
          " inert and every dispatch name would resolve to a single gate by construction")
    bad = 1

for helper, label, mode, n in found:
    if mode is None:
        print("  [FAIL] %s:%d — no dispatch name could be read from the %s for \"%s\","
              % (src, n, helper, label))
        print("         so this leg cannot tell which gate that assertion exercises.")
        bad = 1
    elif mode not in reach:
        print("  [FAIL] %s:%d — \"%s\" names the dispatch `%s`, which the dispatch block does"
              " not define." % (src, n, label, mode))
        print("         An unknown mode prints usage and exits 2, which is a non-zero status")
        print("         a fire-proof can mistake for the gate firing.")
        bad = 1
    elif len(reach[mode]) > 1:
        print("  [FAIL] %s:%d — \"%s\" runs the dispatch `%s`, which is %d gates behind one"
              " exit code:" % (src, n, label, mode, len(reach[mode])))
        print("           %s" % ", ".join(sorted(reach[mode])))
        print("         Any of them can supply the failure, so the assertion cannot say which")
        print("         gate it exercised. Give the gate under test its own leaf dispatch")
        print("         name — GATES 10a/10b, 4b, 11-figures, 11-phrases and 4 all have one.")
        bad = 1

if not bad:
    combined = sorted(k for k, v in reach.items() if len(v) > 1)
    print("  [ok] LEG 2: %d fire-proof(s) and negative control(s) resolved through %d dispatch"
          " name(s); every one runs exactly ONE gate" % (len(found), len(disp)))
    print("       (%d combined name(s) exist and are unused by any assertion: %s; %d gate"
          " function(s) fan out)" % (len(combined), ", ".join(combined), len(fanout)))
sys.exit(bad)
PY
  echo "-- GATE 16 LEG 3: a fire-proof's expected substring names exactly ONE message --"
  python3 - <<'PY' || rc=1
import os, re, sys

# LEG 3 (item R4, round 11 drain-1, 2026-08-02). See the gate header for why this is
# mechanical rather than the argument it replaces.
src = os.environ.get("DOC_GATES_SRC_OVERRIDE") or "scripts/doc_gates.sh"
TABLE = "documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt"
if src != "scripts/doc_gates.sh":
    print("  [note] LEG 3 scanning OVERRIDE source %s, not the live script" % src)
if not os.path.isfile(src):
    print("  [FAIL] LEG 3: %s is not a readable file, so zero substrings were resolved" % src)
    sys.exit(1)
lines = open(src, encoding="utf-8").read().splitlines()
bad = 0

# --- THE MESSAGES THIS HARNESS CAN PRINT. Both forms, because it uses both: a python
# `print(...)` inside a gate body and a shell `echo "..."`. A comment cannot print, and both
# patterns are anchored at line start, so a `#` prefix excludes the line without a separate
# skip — unlike LEG 2's `uncomment`, which had to strip comments because its call pattern was
# not anchored.
STRLIT = re.compile(r"\"((?:[^\"\\]|\\.)*)\"|'((?:[^'\\]|\\.)*)'")
SPEC = re.compile(r"%[-#0 +]*[0-9]*(?:\.[0-9]+)?[sdiroxefgu]")
DIGITS = re.compile(r"[0-9]+")
PRINT_OPEN = re.compile(r"^[ \t]*print\(")
ECHO_LINE = re.compile(r'^[ \t]*echo[ \t]+"(.*)"[ \t]*$')
TPL_SPAN = 12


def norm(s, template):
    # ONE WILDCARD FOR EVERY VARYING FIELD, on both sides. A template's %-specifier and a
    # substring's digit run collapse to the same sentinel, so `is 2 gates behind one exit
    # code` resolves against `which is %d gates behind one exit code:`. Collapsing a literal
    # digit run in a template too is what keeps the two sides symmetric.
    if template:
        s = s.replace("%%", "\x01")
        s = SPEC.sub("\x00", s)
        s = s.replace("\x01", "%")
    return DIGITS.sub("\x00", s).replace('\\"', '"').replace("\\`", "`")


def literals(s):
    return "".join((m.group(1) if m.group(1) is not None else m.group(2))
                   for m in STRLIT.finditer(s))


templates, i = [], 0
while i < len(lines):
    ln = lines[i]
    if PRINT_OPEN.match(ln):
        buf, depth, j = "", 0, i
        while j < len(lines) and j - i < TPL_SPAN:
            seg = lines[j]
            buf += literals(seg[seg.index("print(") + 6:] if j == i else seg)
            depth += seg.count("(") - seg.count(")")
            if depth <= 0:
                break
            j += 1
        templates.append((i + 1, "print", norm(buf, True)))
        i = j + 1
        continue
    m = ECHO_LINE.match(ln)
    if m:
        templates.append((i + 1, "echo", norm(m.group(1), True)))
    i += 1

# --- VACUITY GUARD 1: neither message form may go quiet. This is LEG 1's per-preflight guard
# applied to a set of two: a rewrite of every `print` to some other call, or of every `echo`,
# would silently halve the comparison and every substring would still resolve against what
# was left. A count nobody reads is not a check.
for kind in ("print", "echo"):
    if not any(t[1] == kind for t in templates):
        print("  [FAIL] LEG 3: zero `%s` message templates extracted from %s, so that half of"
              " this harness's output is outside the comparison" % (kind, src))
        print("         A substring resolving uniquely against the remaining half would")
        print("         still print [ok] — the false-clear shape GATE 16 exists to refuse.")
        bad = 1

# --- THE FIRE-PROOF DRIVERS, DISCOVERED RATHER THAN NAMED. A driver is a helper whose body
# asserts on its second argument with a fixed string. Naming them here would be a population
# statement in a comment, which this file has now falsified in its own diff more than once.
DRIVER_DEF = re.compile(r"^[ \t]*(_g[A-Za-z0-9_]+)\(\)[ \t]*\{[ \t]*(?:#.*)?$")
QF_ARG = re.compile(r"grep[ \t]+-qF[ \t]+\"\$2\"")
drivers, spans = [], []
for i, ln in enumerate(lines):
    m = DRIVER_DEF.match(ln)
    if not m:
        continue
    stop = next((j for j in range(i + 1, min(i + 41, len(lines)))
                 if lines[j].strip() == "}"), None)
    if stop is None:
        continue
    if any(QF_ARG.search(lines[j]) for j in range(i + 1, stop)):
        drivers.append(m.group(1))
        spans.append((i + 1, stop + 1))

# --- VACUITY GUARD 2: every fixed-string-on-$2 assertion in the file must belong to a driver
# this leg found. A driver written in a shape DRIVER_DEF cannot read would otherwise take its
# assertions out of scope silently, which is the one failure this leg cannot survive: it would
# report [ok] over a smaller population and nothing would say so.
orphan = [i + 1 for i, ln in enumerate(lines)
          if QF_ARG.search(ln) and not any(a <= i + 1 <= b for a, b in spans)]
if orphan:
    print("  [FAIL] LEG 3: %s asserts on a fixed `$2` outside any driver this leg could read:"
          " %s" % (src, ", ".join(str(o) for o in orphan)))
    print("         The driver definition must open its body on its own line (`_gX() {`) or")
    print("         this leg stops seeing that driver's substrings while still saying [ok].")
    bad = 1
if not drivers:
    print("  [FAIL] LEG 3: zero fire-proof drivers found in %s — the scan is inert, not clean"
          % src)
    bad = 1

# --- VARIABLE-CARRIED ASSERTIONS (round 11 drain-2, 2026-08-02, from drain-1's could-not-see
# column). A fire-proof does not have to put its expected substring at the call site. GATE 15
# LEG 2's pair selects its substring in a `case` arm and asserts on the variable, and those
# substrings are fire-proof substrings by every property this leg cares about. They were
# outside it in BOTH directions, which is why nothing said so: not a driver positional, so
# never parsed; and not matched by guard 2's QF_ARG either, so not an orphan. A population
# that is invisible to both the scan and the scan's own vacuity guard is the exact state this
# leg exists to refuse, one level up from the drivers it already reads.
#
# THE SORT IS EXHAUSTIVE ON PURPOSE. Every fixed-string assertion whose pattern is an
# expansion must land in one of two bins — a driver's positional, handled by guard 2 above,
# or a named variable, resolved below. A third form is a FAIL, not a shrug: an assertion this
# leg cannot classify is one it stops resolving while still printing [ok].
QF_ANY = re.compile(r"grep[ \t]+-qF[ \t]+\"\$")
QF_VAR = re.compile(r"grep[ \t]+-qF[ \t]+\"\$([A-Za-z_][A-Za-z0-9_]*)\"")
varsites = {}
for i, ln in enumerate(lines):
    if ln.lstrip().startswith("#") or not QF_ANY.search(ln) or QF_ARG.search(ln):
        continue
    m = QF_VAR.search(ln)
    if m:
        varsites.setdefault(m.group(1), i + 1)
        continue
    print("  [FAIL] LEG 3: %s:%d — a fixed-string assertion reads an expansion this leg sorts"
          " into neither a driver's positional nor a named variable:" % (src, i + 1))
    print("           %s" % ln.strip())
    print("         Its substring is a fire-proof substring and is now outside the")
    print("         exactly-one-template rule, with nothing but this line to say so.")
    bad = 1

varfound = []
for v, site in sorted(varsites.items()):
    apat = re.compile(r"(?:^|[ \t;&|(])" + re.escape(v) + r"=(.*)$")
    occ = re.compile(r"(?<![A-Za-z0-9_])" + re.escape(v) + r"(?![A-Za-z0-9_])")
    use = '"$' + v + '"'
    seen = 0
    for i, ln in enumerate(lines):
        if ln.lstrip().startswith("#") or not occ.search(ln):
            continue
        am = apat.search(ln)
        if am:
            rhs = am.group(1)
            # literals() is the SAME concatenating reader the template side uses, which is
            # what makes `x='a'"'"'b'` resolve to the one string the shell builds rather than
            # to its first fragment. The residue test is the guard on that: if anything
            # OUTSIDE the quotes expands, the reconstruction is a fragment of the real
            # substring and comparing it would be a clear taken on partial text.
            lit = literals(rhs)
            if "$" in STRLIT.sub("", rhs) or not lit:
                print("  [FAIL] LEG 3: %s:%d — `$%s` is assigned from something this leg"
                      " cannot read as a whole literal:" % (src, i + 1, v))
                print("           %s" % ln.strip())
                print("         Resolving a FRAGMENT of a fire-proof's substring against the")
                print("         message set would be a verdict taken on partial text.")
                bad = 1
                continue
            varfound.append((v, lit, i + 1))
            seen += 1
        elif use not in ln:
            # VACUITY GUARD 4, and it is derived by a DIFFERENT rule from the assignment scan
            # above: bare occurrence of the name, not assignment shape. An assignment written
            # in a form `apat` cannot read would otherwise drop its substring out of the
            # comparison in silence — the under-count shape guards 2 and 3 exist for, which
            # this population would otherwise reintroduce.
            print("  [FAIL] LEG 3: %s:%d — `$%s` occurs here as neither a literal assignment"
                  " this leg resolved nor the assertion itself:" % (src, i + 1, v))
            print("           %s" % ln.strip())
            print("         An assignment in a shape the scan cannot read takes its substring")
            print("         out of the comparison while this leg still prints [ok].")
            bad = 1
    if not seen:
        print("  [FAIL] LEG 3: %s:%d — the fire-proof asserts on `$%s`, a variable this leg"
              " found no literal assignment for" % (src, site, v))
        print("         The string it greps the gate's output for is then unknown here, so")
        print("         the exactly-one-template rule was never applied to that assertion.")
        bad = 1

SUB_LINE = re.compile(r"^[ \t]*'((?:[^'\\]|\\.)*)'")
found = []
for d in drivers:
    one = re.compile(r"^[ \t]*" + re.escape(d) + r"[ \t]+\"((?:[^\"\\]|\\.)*)\"[ \t]+"
                     r"'((?:[^'\\]|\\.)*)'")
    wrap = re.compile(r"^[ \t]*" + re.escape(d) + r"[ \t]+\"((?:[^\"\\]|\\.)*)\"[ \t]*\\[ \t]*$")
    for i, ln in enumerate(lines):
        if ln.lstrip().startswith("#"):
            continue
        m = one.match(ln)
        if m:
            found.append((d, m.group(1), m.group(2), i + 1))
            continue
        m = wrap.match(ln)
        if m and i + 1 < len(lines):
            m2 = SUB_LINE.match(lines[i + 1])
            if m2:
                found.append((d, m.group(1), m2.group(1), i + 1))

# --- VACUITY GUARD 3: an INDEPENDENTLY-DERIVED count of the same call sites, exactly as
# LEG 2's guard 1 above. GATE 15 LEG 3 machine-checks a `callers=N` for each driver by a
# different rule (name in command position over the whole file). Two extractors written for
# different purposes must agree, or one of them is wrong.
declared = {}
if os.path.isfile(TABLE):
    for ln in open(TABLE, encoding="utf-8").read().splitlines():
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        f = ln.split("\t")
        if len(f) >= 3:
            mm = re.search(r"callers=(\d+)", f[2])
            if mm:
                declared[f[0]] = int(mm.group(1))
elif drivers:
    print("  [FAIL] LEG 3: %s is missing, so this leg's extractor has nothing to be"
          " cross-checked against" % TABLE)
    bad = 1
for d in drivers:
    mine = sum(1 for x in found if x[0] == d)
    if d not in declared:
        if os.path.isfile(TABLE):
            print("  [FAIL] LEG 3: %s declares no callers=N in %s, so a substring this leg"
                  " failed to parse would be invisible" % (d, TABLE))
            bad = 1
    elif declared[d] != mine:
        print("  [FAIL] LEG 3: %s — this leg parsed %d substring(s); %s declares callers=%d."
              " One of the two extractors is under-reading, and an unparsed invocation is an"
              " unchecked substring." % (d, mine, TABLE, declared[d]))
        bad = 1

for d, label, sub, n in found:
    want = norm(sub, False)
    hits = [t for t in templates if want in t[2]]
    if len(hits) == 1:
        continue
    if not hits:
        print("  [FAIL] LEG 3: %s:%d — %s(\"%s\") asserts a substring no message template can"
              " produce:" % (src, n, d, label))
        print("           %s" % sub)
        print("         The driver greps for that fixed string in the gate's output, so the")
        print("         leg can now only ever report NOT reported. This is a message reworded")
        print("         out from under its own fire-proof, caught at the source instead of at")
        print("         the next run that happens to exercise it.")
    else:
        print("  [FAIL] LEG 3: %s:%d — %s(\"%s\") asserts a substring %d message templates can"
              " produce:" % (src, n, d, label, len(hits)))
        print("           %s" % sub)
        for t in hits[:6]:
            print("           -> %s:%d (%s)" % (src, t[0], t[1]))
        print("         The assertion cannot then say WHICH finding satisfied it, and a leg")
        print("         satisfied by a different finding in the same output is green for the")
        print("         wrong reason — which is the entire content of a fire-proof.")
    bad = 1

# THE VARIABLE-CARRIED HALF GETS ITS OWN VERDICT LINE, and that is not duplication. Both
# directions collapse into one message here because the site is an ASSIGNMENT, not a call —
# there is no driver and no label to name — and because a fire-proof for this half must be
# able to assert on a string the driver half cannot also print. Sharing the driver wording
# would have made the two halves indistinguishable in the output, which is the very confusion
# this leg refuses one level down.
for v, sub, n in varfound:
    want = norm(sub, False)
    hits = [t for t in templates if want in t[2]]
    if len(hits) == 1:
        continue
    print("  [FAIL] LEG 3: %s:%d — `$%s` carries a fire-proof literal %d message template(s)"
          " can produce; exactly one is required:" % (src, n, v, len(hits)))
    print("           %s" % sub)
    for t in hits[:6]:
        print("           -> %s:%d (%s)" % (src, t[0], t[1]))
    print("         Zero means a message was reworded out from under an assertion that can")
    print("         now only ever report NOT reported; more than one means the assertion")
    print("         cannot say which finding satisfied it. Both are green for a wrong reason.")
    bad = 1

if not bad:
    print("  [ok] LEG 3: %d fire-proof substring(s) across %d driver(s) (%s), plus %d carried"
          " by %d asserted variable(s), each produced by exactly ONE of %d message template(s)"
          % (len(found), len(drivers), ", ".join(sorted(drivers)), len(varfound),
             len(varsites), len(templates)))
    print("       caveat (g): ONE template is not one INSTANTIATION — a substring spanning a"
          " %-field still cannot say which call printed it")
sys.exit(bad)
PY
  return $rc
}

# ----------------------------------------------------------------------------------
# GATE 17 — every registry rule reaches the published scoreboard, and its data-like /
# principled verdict is findable AT ITS ROW ID (round-7 brief item 6, 2026-08-02).
#
# WHY THIS EXISTS. Twice now a load-bearing scoreboard row has been carried unclassified
# for weeks and been found only because a human named it:
#   * `d7` — unclassified until 2026-08-01, found because the operator asked about it.
#   * `ccn4` — classified data-like since 2026-07-03, but the verdict was written next to
#     the DESCRIPTION ("Schulz's S25-28 trigram configuration") and never next to the id.
#     TR-1 v1.23 records what that cost: the 2026-08-01 sweep that concluded d7 was "the
#     last unclassified load-bearing row" matched id tokens, could not see the ccn4 verdict,
#     and so carried THE MOST-CITED ROW ON THE BOARD (2x10^-8, the strongest discriminator)
#     as unclassified. The sweep's conclusion was wrong in both directions at once.
# Two instances, one shape: a verdict is findable by description but not by id, and the only
# instrument that has ever looked was a human reading prose. TR-1 v1.23 states the residue in
# prose — "`ccn8` and the remaining SAMPLED rows carry no verdict" — which is honest but is a
# sentence about a sample, written on 2026-08-02, that ages the moment a rule is added.
#
# WHAT IT DOES, and the split between the two halves is the whole design:
#   LEG A (HARD).   Every id in solve.py's REGISTRY_KW_EXPECTED must appear as a row on the
#                   published board in BOTH files that carry it, and no board row may name a
#                   rule the registry does not have. This is mechanical and has one right
#                   answer, so it FAILS.
#   LEG B (REPORT-ONLY). For each id, is a data-like / principled verdict findable within
#                   that id's own board entry? Printed as a per-row ledger with counts. This
#                   does NOT fail: 21 rows carry no verdict today, and whether they need one
#                   is a METHODS judgment routed to the operator (inbox O2), not a gate's
#                   call. A gate that declared two thirds of a published table in violation
#                   would be turned off within the day — the same reasoning that ships
#                   GATE 13 report-only.
#
# WHAT IT CANNOT SEE, said plainly, because a clear from this gate is weaker than a failure:
#   (a) It cannot see a verdict written ANYWHERE BUT the id's own board entry. That is not a
#       limitation to apologise for, it is the measurement: the ccn4 defect WAS a verdict
#       that existed elsewhere. A row this gate calls "silent" may well be classified in
#       prose two paragraphs up. The ledger says "no verdict at the id", never "unclassified".
#   (b) It cannot judge whether a verdict is CORRECT, or whether the dof count behind it is
#       right. reg_d7's verdict was wrong for weeks while being present.
#   (c) "(theorem)" rows are counted in their own bucket, not as classified. Whether a rule
#       that measures at 1.0 of canonical mass — a forced consequence, which discriminates
#       nothing — even admits a data-like/principled verdict is exactly the sort of judgment
#       (c) says this gate does not make.
#
# COST: two file reads and 31 substring searches. Milliseconds; it is in `all`.
gate_scoreboard_verdicts() {
  echo "== GATE 17: every registry rule is on the scoreboard, verdict findable at its id =="
  python3 - <<'PY'
import re, sys
sys.path.insert(0, '.')
try:
    import solve
except Exception as exc:                       # noqa: BLE001 — any import failure is a FAIL
    print("  [FAIL] cannot import solve.py, so ZERO rules were checked: %s" % exc)
    print("         A gate that cannot load its subject has checked nothing.")
    sys.exit(1)

ids = [r for r, _ in solve.REGISTRY_KW_EXPECTED]
# Same vacuity guard as GATE 14, and for the same measured reason: an emptied or renamed
# REGISTRY_KW_EXPECTED otherwise yields "[ok] 0 rules checked" and exit 0.
if not ids:
    print("  [FAIL] REGISTRY_KW_EXPECTED holds no rules, so this gate checked NOTHING")
    sys.exit(1)

# The two files that publish the board. Both must carry every rule: they are hand-maintained
# copies of one table, so a rule added to one and not the other is precisely the drift a
# reader comparing the report against the documentation would hit.
BOARDS = [
    "reports/TR1_EIGHT_CENTURIES_MEASURED.md",
    "documentation/LITERATURE_RULES_POPULATION_TESTS.md",
]
# PHASE-4 ON THIS GATE'S OWN BATCH. Shortening BOARDS to one path was a green run with half
# the check switched off: `len(regions) != len(BOARDS)` still held, the summary printed
# "present on 1 board(s)", and the second published copy silently stopped being compared. The
# count was there to read and nothing required it to be two. This is the same defect the
# suite already recorded once — GATE 16's "one preflight going quiet is a FAIL, not a smaller
# count" — so it gets the same answer rather than a note.
if len(BOARDS) < 2:
    print("  [FAIL] the board list holds %d file(s); leg A exists to compare the REPORT's copy"
          " of the table against the DOCUMENTATION's" % len(BOARDS))
    print("         A single board cannot disagree with anything. Restore the second path.")
    sys.exit(1)

OPEN_ANCHOR = "Full table (fraction of canonical mass"
# The board's FIRST entry (rs1) does not begin a "·"-separated chunk — it follows the
# table's introductory clause on the same run of prose. MEASURED, not anticipated: the
# first live run of this gate reported rs1 missing from BOTH files and reported a phantom
# orphan row "Full", because the opening chunk began "Full table (fraction ...". Both
# findings were defects in this parser, not in the corpus. So the region starts AFTER the
# clause's closing "estimates):", and failing to find it is a FAIL like any moved anchor.
TABLE_ANCHOR = "estimates):"
CLOSE_ANCHOR = "Wrap-distance finals"

bad = 0
regions = {}
for path in BOARDS:
    try:
        text = open(path, encoding="utf-8").read()
    except OSError as exc:
        print("  [FAIL] %s cannot be read, so its board was not checked: %s" % (path, exc))
        bad = 1
        continue
    i = text.find(OPEN_ANCHOR)
    k = text.find(TABLE_ANCHOR, i) if i >= 0 else -1
    j = text.find(CLOSE_ANCHOR, k + 1) if k >= 0 else -1
    # THE ANCHOR-MOVED BRANCH IS THE GATE'S OWN FAILURE MODE, not a corner case. If the
    # prose is rewritten and either anchor moves, a naive scan returns an empty region, every
    # id reads as missing OR (worse, if the scan is written the other way) nothing reads as
    # missing at all, and the run is green with the instrument switched off. Finding no
    # region is therefore a FAIL that names the anchor, exactly as GATE 15's header requires.
    if i < 0 or k < 0 or j < 0:
        print("  [FAIL] %s — the board region could not be located (open anchor %s, table"
              " anchor %s, close anchor %s)"
              % (path, "FOUND" if i >= 0 else "MISSING", "FOUND" if k >= 0 else "MISSING",
                 "FOUND" if j >= 0 else "MISSING"))
        print("         The anchors are prose and prose gets rewritten. Re-point them at the")
        print("         table; do NOT let this gate scan an empty region and report [ok].")
        bad = 1
        continue
    regions[path] = text[k + len(TABLE_ANCHOR):j]

if len(regions) != len(BOARDS):
    sys.exit(1)

# A board entry is "<id> <mass>[ (annotation)]", entries separated by " \xb7 ". Split on the
# separator so an annotation is attributed to the id it follows and to no other -- the whole
# point is that ccn4's verdict must not be credited to ccn3 because they share a line.
ID_AT_START = re.compile(r"^\**([A-Za-z][A-Za-z0-9]*)\b")
# AND AN ENTRY ENDS AT ITS SENTENCE, which is not a refinement but a fix for a defect this
# gate's own NEGATIVE CONTROL caught. The LAST entry on the board has no "·" after it, so it
# ran to the close anchor and swallowed every word in between: leg 5 inserted the sentence
# "These are principled, data-like rows." before "Wrap-distance finals" and `c2` -- a forced
# constant -- was reported as carrying a verdict. The live corpus has nothing in that gap, so
# every positive leg passed and only the control saw it. No board entry contains ". " (masses
# are "6.6×10⁻⁴", decimals are digit.digit), so truncating each chunk at its first sentence
# break bounds the last row without touching any other.
SENTENCE_END = re.compile(r"\.(\s|$)")


# ONE parser, used by BOTH legs. It was written twice in the first draft, which is the
# duplicated-predicate hazard GATE 14 exists for, arriving inside GATE 14's own suite: legs A
# and B would have disagreed about what an entry IS the moment either was touched.
def entries_of(region):
    out = {}
    for chunk in region.split("·"):
        body = chunk.strip()
        m = ID_AT_START.match(body)
        if m:
            cut = SENTENCE_END.search(body)
            out.setdefault(m.group(1), []).append(body[:cut.start()] if cut else body)
    return out


for path, region in sorted(regions.items()):
    entries = entries_of(region)
    missing = [r for r in ids if r not in entries]
    if missing:
        print("  [FAIL] %s — %d registry rule(s) never reach the published board: %s"
              % (path, len(missing), ", ".join(missing)))
        print("         A rule that is measured but not published is invisible to every")
        print("         reader who audits the table instead of the code.")
        bad = 1
    known = set(ids)
    # Wrap-distance finals (d1/d3/d5) are NOT registry rules and are published in the
    # following sentence, outside the close anchor; anything else with a mass on the board
    # and no rule behind it is a row nobody can reproduce.
    orphans = [r for r in sorted(entries) if r not in known]
    if orphans:
        print("  [FAIL] %s — board row(s) with no registry rule behind them: %s"
              % (path, ", ".join(orphans)))
        bad = 1

if bad:
    sys.exit(1)

# LEG B — report-only ledger, printed PER BOARD rather than once. The two files are
# hand-maintained copies, so a verdict added to the report and not to the documentation is a
# real divergence; collapsing them into one ledger would hide exactly that.
VERDICT = re.compile(r"data-like|principled", re.I)
THEOREM = re.compile(r"\(theorem\)")
for path, region in sorted(regions.items()):
    entries = entries_of(region)
    at_id, theorem, silent = [], [], []
    for r in ids:
        blob = " ".join(entries[r])
        if VERDICT.search(blob):
            at_id.append(r)
        elif THEOREM.search(blob):
            theorem.append(r)
        else:
            silent.append(r)
    print("  [note] %s: %d/%d rule(s) carry a verdict at the id (%s)"
          % (path, len(at_id), len(ids), ", ".join(at_id) or "none"))
    print("  [note] %s: %d forced-constant row(s) marked (theorem) — bucket, not a verdict (%s)"
          % (path, len(theorem), ", ".join(theorem) or "none"))
    print("  [note] %s: %d row(s) carry NO verdict at the id (%s)"
          % (path, len(silent), ", ".join(silent) or "none"))
print("  [note] REPORT-ONLY: 'no verdict at the id' is NOT 'unclassified' — this gate cannot")
print("         see a verdict written next to the row's DESCRIPTION, which is exactly how the")
print("         ccn4 verdict hid from the 2026-08-01 sweep. Classifying these rows is a")
print("         METHODS judgment (inbox O2), not a gate change.")
print("  [ok] %d registry rule(s) present on %d board(s); verdict ledger above is report-only"
      % (len(ids), len(regions)))
sys.exit(0)
PY
}

MODE="${1:-all}"

# ITEM A1, hole (b) — runs for EVERY mode, including the single-gate invocations the
# self-test uses. Deliberately does NOT short-circuit: RC is set and the requested gate still
# runs, so a per-gate fire-proof can distinguish its own leg's message ("<f> is tracked in git
# but missing from the working tree") from this one ("tracked markdown missing from the
# working tree: <f>"). Placed after the --selftest block above, which exits before reaching it.
preflight_tracked_docs || RC=1
# ITEM A6: same placement and the same non-short-circuiting contract, for the same reason —
# GATE 11's own final-newline leg must still be able to fire and be told apart from this one.
# The two messages differ: this one names the file and says "does not end with a newline"
# via require_final_newline; GATE 11's names the registry AND the figure it dropped.
preflight_support_newlines || RC=1

case "$MODE" in
  numbers) gate_numbers || RC=1 ;;
  cli)     gate_cli     || RC=1 ;;
  retract) gate_retract || RC=1 ;;
  retract-figures) gate_retract_figures || RC=1 ;;
  links)   gate_links_and_secrefs || RC=1 ;;
  # LEAF DISPATCH NAME (item B2, round 9, 2026-08-02) — the FIFTH hand application of this
  # one fix, and the last one that was live. `links` is gate_links_and_secrefs, i.e. GATE 4
  # AND GATE 4b behind a single exit code; the "GATE 4 internal links" fire-proof ran on it
  # and was argued safe because its evidence-ERE is GATE 4's own line. That argument was
  # correct and it was also the only thing holding the assertion to GATE 4 — reword either
  # gate and it stops holding, silently. GATE 16 LEG 2 below now REFUSES a fire-proof on a
  # combined dispatch name outright, which is only possible because this name exists.
  links-internal) gate_links || RC=1 ;;
  secrefs) gate_secrefs || RC=1 ;;
  status)  gate_status  || RC=1 ;;
  figures) gate_figures || RC=1 ;;
  liveness) gate_liveness || RC=1 ;;
  banner)  gate_banner   || RC=1 ;;
  generated) gate_generated || RC=1 ;;
  appendonly) gate_appendonly || RC=1 ;;
  appendonly-head)    gate_appendonly_head    || RC=1 ;;
  appendonly-history) gate_appendonly_history || RC=1 ;;
  ledger)  gate_ledger  || RC=1 ;;
  ledger-figures) gate_ledger_figures || RC=1 ;;
  # LEAF DISPATCH NAME (item B2, round 9, 2026-08-02). `ledger` runs BOTH halves, so an
  # assertion written against it cannot say which half answered — measured live at
  # "GATE 11 (A1) ledger deleted", whose ERE `CORRECTIONS.md is tracked in git but
  # missing` is emitted by gate_ledger_phrases AND by gate_ledger_figures, both of which
  # require_tracked the same ledger. This is the fourth hand application of one fix:
  # GATE 10a/10b, GATE 4/4b and GATE 11-figures each got a leaf name for the same reason.
  ledger-phrases) gate_ledger_phrases || RC=1 ;;
  revhist) gate_revhist || RC=1 ;;
  revrows) gate_revrows || RC=1 ;;
  regdupes) gate_registry_dupes || RC=1 ;;
  instruments) gate_selftest_instruments || RC=1 ;;
  collisions) gate_preflight_collisions || RC=1 ;;
  scoreboard) gate_scoreboard_verdicts || RC=1 ;;
  all)     gate_numbers || RC=1; echo; gate_cli || RC=1; echo; gate_retract || RC=1
           echo; gate_retract_figures || RC=1
           echo; gate_links_and_secrefs || RC=1; echo; gate_status || RC=1
           echo; gate_figures || RC=1
           echo; gate_liveness || RC=1
           echo; gate_banner || RC=1
           echo; gate_appendonly || RC=1
           echo; gate_ledger || RC=1
           echo; gate_revhist || RC=1
           echo; gate_revrows || RC=1
           echo; gate_registry_dupes || RC=1
           echo; gate_selftest_instruments || RC=1
           echo; gate_preflight_collisions || RC=1
           echo; gate_scoreboard_verdicts || RC=1 ;;
  *) echo "usage: $0 {numbers|cli|retract|retract-figures|links|links-internal|secrefs|status|figures|liveness|banner|appendonly|appendonly-head|appendonly-history|ledger|ledger-figures|ledger-phrases|revhist|revrows|regdupes|instruments|collisions|scoreboard|generated|all}"; exit 2 ;;
esac

echo
# State what the banner does NOT attest. GATES 1 and 5 are report-only (`return 0` /
# `sys.exit(0)`), so their [WARN]/[note] output never reaches RC; and GATE 8 is excluded
# from `all` by cost. A green banner that silently covers only 5 of 8 gates reads as more
# coverage than it has — the same over-attestation this suite exists to catch. (The
# self-test's own comment asserted this was "stated in the banner itself" before it was;
# written into the banner 2026-08-01 on same-day re-review.)
if [ "$RC" -ne 0 ]; then
  echo "DOC GATES: FINDINGS (see above)"
elif [ "$MODE" = all ]; then
  echo "DOC GATES: PASS  — hard gates only: 2, 3, 3b, 4 (incl. 4b), 6, 7, 9, 10 (a+b), 11, 12, 14, 15, 16, 17 (LEG A only). Gates 1, 5 (incl. 5b), 13"
  echo "                   and GATE 17's LEG B (the verdict ledger) are REPORT-ONLY,"
  echo "                   so any [WARN]/[note] above is NOT covered by this verdict."
  echo "                   GATE 8 ('generated') is not in 'all' — run it separately."
elif [ "$MODE" = numbers ] || [ "$MODE" = status ] || [ "$MODE" = revrows ]; then
  echo "DOC GATES: PASS  — NOTE: '$MODE' is a REPORT-ONLY gate and always exits 0."
  echo "                   Read its [WARN]/[note] lines above; this verdict does not."
else
  echo "DOC GATES: PASS  ($MODE)"
fi
exit $RC
