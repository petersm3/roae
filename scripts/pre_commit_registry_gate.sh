#!/bin/bash
# Pre-commit gate for the RETRACTION REGISTRY and the CORRECTIONS LEDGER (item R17).
#
# STATUS: INSTALLED since 2026-08-03 via the pre-commit DISPATCHER
# (scripts/pre_commit_gate.sh — see DEVELOPMENT.md §"Git hooks"), which runs
# this gate WARN-only per operator ruling O-redfloor, then the blocking #85
# generated gate. Do not symlink this file into .git/hooks directly: that
# would drop the #85 gate (see INSTALL below).
#
# WHY THIS EXISTS — measured, not supposed.
#   The only pre-commit hook this repo had (scripts/pre_commit_generated_gate.sh,
#   task #85) has a WATCHED set of exactly roae.py plus the five example/ artifacts.
#   A commit touching documentation/RETRACTED_PHRASES.tsv, RETRACTED_FIGURES.tsv or
#   CORRECTIONS.md was therefore gated by NOTHING.
#
#   Round 14 (2026-08-02) landed THREE commits with a red floor, all in that hole:
#     316c6581  GATE 11 red — registry rows with no ledger entry
#     8f2f292c  GATE 11 red — five more of the same, from a different unit, 59 min later
#     bed707db  GATE 3  red — the fix for the above quoted all five retracted phrasings
#                             VERBATIM into the append-only ledger
#   A fourth, 728778e7, turned GATE 10b red by rewriting a committed CORRECTIONS.md
#   entry in place, deleting ten lines from a version that was already committed.
#   Each unit's own gate run was green at the moment it ran; the collisions were
#   between units. No per-unit discipline can catch that, which is what makes this
#   mechanical rather than advisory.
#
#   One of those commits produced a defect that can NEVER be removed, because the
#   ledger is append-only and the commit was subsequently pushed. This gate is aimed
#   squarely at that: the cost of a red registry/ledger commit is not "fix it next
#   time", it is permanent.
#
# WHAT IT RUNS, and why the union rather than a per-file selection.
#   All six leaf gates run whenever ANY of the three files is staged. That is a
#   correctness choice, not a convenience one: GATE 11 relates registry ROWS to
#   ledger ENTRIES, so editing either side can turn it red, and GATE 3's `allow`
#   column was re-scoped to CORRECTIONS.md (b4f20e2c) — which couples the ledger's
#   content to the retraction corpus scan. Selecting gates per-file would have to
#   re-derive that coupling and would rot when it changes.
#
#   Measured cost on this box, 2026-08-03, one run each:
#     retract 4.02s · retract-figures 0.16s · ledger-phrases 0.11s
#     ledger-figures 0.11s · appendonly-head + appendonly-history 0.17s combined
#   Total ~4.4s, against 62.2s for `generated`. The "only fires when the commit
#   touches the watched set" property of #85's hook is preserved, and even when it
#   does fire it costs seconds.
#
#   LEAF DISPATCH NAMES are used deliberately (item B2). `ledger` runs both halves
#   and `appendonly` runs both of its own, so a refusal reported against either
#   combined name could not say which half answered. Every name below is a leaf.
#
# FAIL DIRECTION: CLOSED, for the same reason #85's hook is closed. A false stop
#   costs one `git commit` retry. A false pass writes a permanent line into an
#   append-only ledger. The asymmetry is not close.
#
# NO BYPASS ENV VAR, deliberately, per #85's hook: `git commit --no-verify` already
#   exists, is standard, and stays visible in the operator's shell history.
#
# ---------------------------------------------------------------------------
# WHAT THIS GATE CANNOT SEE. Read this before trusting a PASS.
#
#   1. It checks the WORKING TREE, because doc_gates.sh does. It refuses when a
#      WATCHED path differs between index and working tree (below), so the watched
#      bytes are the committed bytes — but GATE 3 scans the WHOLE corpus, and an
#      unrelated dirty file elsewhere in documentation/ or reports/ is read in its
#      dirty state. A pass is a statement about the tree as it stands, not purely
#      about the commit. #85's hook has the identical limitation.
#   2. It cannot see a defect in the ENGLISH of a ledger entry. GATE 11 asks only
#      whether the RP-<sha> key appears in CORRECTIONS.md. An entry citing the right
#      key while describing the wrong thing passes. Round 14's CX-23 did exactly
#      that and needed CX-24 to correct it; no gate caught it, and this one would
#      not have either.
#   3. It does not decide whether a commit may land red AT ALL. That is the
#      operator's call (inbox O-redfloor). This script is the mechanism; it is
#      supplied uninstalled so that installing it remains a decision someone makes.
#
# ---------------------------------------------------------------------------
# INSTALL — READ THIS, a naive symlink SILENTLY DISABLES THE #85 GATE.
#
#   Git runs exactly one pre-commit hook. Pointing .git/hooks/pre-commit at
#   this file would remove the generated-artifact gate (#85) without any
#   message saying so. The hook is the tracked DISPATCHER, which runs both:
#
#     ln -sf ../../scripts/pre_commit_gate.sh .git/hooks/pre-commit
#
#   (The 2026-08-03 install predated the tracked dispatcher and wrote an
#   untracked two-line dispatcher directly into .git/hooks; scripts/
#   pre_commit_gate.sh is that dispatcher, tracked, since task #145.)
#
#   Or invoke directly, without installing:
#     bash scripts/pre_commit_registry_gate.sh && git commit ...
set -u

REPO_ROOT="$(git rev-parse --show-toplevel)" || exit 1
cd "$REPO_ROOT" || exit 1

# ---------------------------------------------------------------------------
# 🔴 THREE VERDICTS, NOT TWO: CLEAN / FINDINGS / COULD-NOT-RUN.
#
# Observed live 2026-09-02 (FINDING_FAILOPEN_CLASS_2026_08_30.md, instance 38). Another unit was
# mid-edit on scripts/doc_gates.sh; bash could not parse it, every leg returned 2, this gate
# recorded all six as failures, and the dispatcher printed
#     [pre-commit] registry gate reported findings (rc=1) - WARN ONLY, commit proceeds
# on a commit staging RETRACTED_PHRASES.tsv and CORRECTIONS.md — the two files GATE 3 and GATE 11
# exist to police. The gates reported nothing. They never ran. A crashed check and a check with
# findings are the two states that must never be conflated: one says "here is what I found", the
# other says "I could not look", and only the second means the commit was verified by nothing.
#
# WARN-ONLY IS NOT THE DEFECT and is NOT changed here. Whether the commit proceeds stays the
# caller's decision (operator ruling O-redfloor: a hook that refuses a red commit also stops a unit
# committing to protect its work from another unit's `git checkout -- .`). The defect was that the
# two states were INDISTINGUISHABLE downstream, so nothing ever surfaced which one had happened.
#
# EXIT CODES OF THIS SCRIPT, read by scripts/pre_commit_gate.sh:
#     0 = CLEAN or NOT-APPLICABLE   1 = FINDINGS   2 = COULD-NOT-RUN
# and every terminal path prints a whole-line token at column 0, for `grep -qx`:
#     PRECOMMIT_REGISTRY=CLEAN | FINDINGS | COULD-NOT-RUN | NOT-APPLICABLE | REFUSED-DIRTY
# Match the token. NEVER infer the verdict from the shape of the text above it — that inference is
# exactly what produced instance 38.
RC_FINDINGS=1; RC_CANTRUN=2

# Leaf dispatch names only (item B2): each entry names exactly one gate function, so a refusal
# below can say which gate answered. Defined here rather than at the loop so the COULD-NOT-RUN
# message can name what was NOT checked.
GATES="retract retract-figures ledger-phrases ledger-figures appendonly-head appendonly-history"
GATES_LIST="$GATES"

# A leg's exit status, CLASSIFIED rather than tested for zero. doc_gates.sh's own convention is
# 0 = clean (its `exit $RC` tail), 1 = findings (`|| RC=1` at every gate call site), 2 = usage or
# cannot-start (its `*)` usage arm, and its `cd ... || exit 2`). Everything else — 126/127 from
# exec, >=128 from a signal — is likewise "produced no verdict". ONLY 1 is a finding.
leg_verdict(){ case "$1" in 0) echo clean;; 1) echo findings;; *) echo cantrun;; esac; }

# `bash -n` BEFORE dispatch. This is the check instance 38 needed and did not have: a file that
# does not parse cannot have an opinion, and asking it for one costs six subshells that all
# return 2 and read as six failing gates. Measured 2026-09-02: 11 ms on the 12k-line doc_gates.sh,
# against ~4.4 s for the six legs — the precheck is free.
DG_PARSE_ERR=""
doc_gates_runnable(){
  if [ ! -f scripts/doc_gates.sh ]; then DG_PARSE_ERR="scripts/doc_gates.sh is missing"; return 1; fi
  if ! DG_PARSE_ERR=$(bash -n scripts/doc_gates.sh 2>&1); then
    [ -n "$DG_PARSE_ERR" ] || DG_PARSE_ERR="bash -n returned non-zero with no message"
    return 1
  fi
  DG_PARSE_ERR=""; return 0
}

# The loud third verdict. It ERRORS rather than summarising, per feedback_failure_must_be_loud:
# a check that cannot run must say so, not report a verdict it never obtained.
cantrun(){
  echo
  echo "pre-commit: 🔴 COULD NOT RUN — the registry/ledger gate(s) did not execute."
  echo "  THIS IS NOT A FINDING, AND IT IS NOT A PASS. Nothing was checked."
  echo "  Reason: $1"
  [ -n "${2:-}" ] && printf '  %s\n' "$2"
  echo "  Most likely cause: another unit is mid-edit on scripts/doc_gates.sh (the concurrency"
  echo "  window — see instance 36/38). Re-run"
  echo "      bash scripts/pre_commit_registry_gate.sh"
  echo "  once 'bash -n scripts/doc_gates.sh' is quiet, and read THAT result before relying on"
  echo "  this commit having been gated. The pre-push hook gates the committed tree and will"
  echo "  re-ask the same question against the pushed sha."
  echo "PRECOMMIT_REGISTRY=COULD-NOT-RUN"
  exit "$RC_CANTRUN"
}

# The retraction registries and the append-only ledger they are checked against.
WATCHED="documentation/RETRACTED_PHRASES.tsv
documentation/RETRACTED_FIGURES.tsv
documentation/CORRECTIONS.md"

# DELETIONS ARE INCLUDED (D), unlike #85's hook, which uses ACM. Deleting the
# ledger or a registry is the maximal form of the defect this gate exists for, not
# an exemption from it; require_tracked inside GATE 11 is what catches it. R covers
# a rename, which reports the new path.
STAGED=$(git diff --cached --name-only --diff-filter=ACMRD)
[ -n "$STAGED" ] || { echo "PRECOMMIT_REGISTRY=NOT-APPLICABLE"; exit 0; }

HITS=$(printf '%s\n' "$WATCHED" | grep -Fxf <(printf '%s\n' "$STAGED") 2>/dev/null || true)

# ---------------------------------------------------------------------------
# DOC-CORPUS TRIGGER (task #150) — WARN-ONLY, the two cheap scans.
#
#   The 3-file WATCHED set above misses the commits that INTRODUCE a retracted
#   phrasing into the corpus without touching a registry file. Measured against
#   the 120 doc-touching commits since this gate's birth: only 26 staged one of
#   the 3 watched files, and the commit that shipped the 2.5-day-open GATE-3
#   defect (task #149 replay) touched NONE of them — so the author first heard
#   about it from a push-point gate days later. This path runs GATE 3's two
#   corpus scans (retract ~4.0 s, retract-figures ~0.16 s, measured 2026-08-03)
#   whenever any reports/*.md, documentation/*.md or README.md is staged, so
#   the warning prints at AUTHORSHIP time.
#
#   WARN-ONLY per operator ruling O-redfloor, even when invoked standalone:
#   findings are printed loudly and the exit code stays 0. Blocking here would
#   also stop a unit committing to protect its work (see dispatcher note #1).
#   The scans read the WORKING TREE (limitation #1 above applies); the
#   pre-push hook gates the committed tree and WILL block the same finding.
#   The expensive ledger/append-only gates are NOT run on this path — they
#   relate registry rows to ledger entries and cannot newly fail on a commit
#   that touches neither.
if [ -z "$HITS" ]; then
  DOC_HITS=$(printf '%s\n' "$STAGED" | grep -E '^(reports/[^/]+\.md|documentation/[^/]+\.md|README\.md)$' || true)
  [ -n "$DOC_HITS" ] || { echo "PRECOMMIT_REGISTRY=NOT-APPLICABLE"; exit 0; }
  echo "pre-commit: doc-corpus file(s) staged — running the two cheap retraction scans (WARN-only):"
  printf '  %s\n' $DOC_HITS
  # WAS: a missing doc_gates.sh printed [WARN] and exited 0 — indistinguishable from "scans ran and
  # were clean" to anything reading the exit status. Same conflation as instance 38, one path over.
  doc_gates_runnable || cantrun "$DG_PARSE_ERR" \
    "The two cheap retraction scans (retract, retract-figures) were NOT run."
  WFAILED=""; WCANT=""
  for g in retract retract-figures; do
    bash scripts/doc_gates.sh "$g"; _rc=$?
    case "$(leg_verdict "$_rc")" in
      findings) WFAILED="$WFAILED $g" ;;
      cantrun)  WCANT="$WCANT $g (rc=$_rc)" ;;
    esac
  done
  # A leg that aborted AFTER the file parsed — unknown mode, killed under contention, internal
  # exit 2. Still "could not look", still must not be reported as a finding or as clean.
  [ -n "$WCANT" ] && cantrun "leg(s) exited with a status that is neither clean(0) nor findings(1):$WCANT" \
    "scripts/doc_gates.sh PARSED, so this is a runtime abort, not a mid-edit file."
  if [ -n "$WFAILED" ]; then
    echo
    echo "[WARN] pre-commit: retraction scan(s) found findings:$WFAILED"
    echo "  WARN-ONLY (operator ruling O-redfloor): the commit proceeds. But the"
    echo "  pre-push hook runs these same gates against the PUSHED sha and WILL"
    echo "  block — fix the finding now, while it is one commit old, not at push"
    echo "  time. Note the scans read the working tree; if the finding is in an"
    echo "  unstaged edit it is not in this commit, but it is still in your tree."
    # EXIT CODE STAYS 0 ON THIS PATH, deliberately and unchanged — see the WARN-ONLY note in the
    # DOC-CORPUS TRIGGER header above ("even when invoked standalone"). Only the TOKEN distinguishes
    # this from clean; the could-not-run path above is the one that changes the exit status, because
    # "I could not look" is not a WARN-able finding, it is an absence of measurement.
    echo "PRECOMMIT_REGISTRY=FINDINGS"
  else
    echo "pre-commit: retraction scans clean (retract, retract-figures)"
    echo "PRECOMMIT_REGISTRY=CLEAN"
  fi
  exit 0
fi

echo "pre-commit: registry/ledger files touched by this commit:"
printf '  %s\n' $HITS

# The gates read the WORKING TREE; the commit records the INDEX. If those disagree
# for a watched path the gate would validate bytes this commit does not contain and
# report a pass for them. Same reasoning as #85's hook, same refusal.
DIRTY=""
for f in $HITS; do
  if ! git diff --quiet -- "$f" 2>/dev/null; then DIRTY="$DIRTY $f"; fi
done
if [ -n "$DIRTY" ]; then
  echo "pre-commit: REFUSING — these paths differ between the index and the working tree:"
  printf '  %s\n' $DIRTY
  echo "  The gates inspect the working tree, so they would be checking bytes this"
  echo "  commit will not contain. Stage them (git add) or stash the difference."
  # rc 2, not 1: this is "the gates were not run against this commit's bytes", which belongs to
  # COULD-NOT-RUN, not to FINDINGS. It used to exit 1 and the dispatcher said "reported findings".
  echo "PRECOMMIT_REGISTRY=REFUSED-DIRTY"
  exit "$RC_CANTRUN"
fi

# WAS: `[ ! -f scripts/doc_gates.sh ] && exit 1`, i.e. missing-file was reported to the dispatcher
# with the same status as six legs full of findings. A missing gate and an unparseable gate are the
# same state — no measurement — and now report as one.
doc_gates_runnable || cantrun "$DG_PARSE_ERR" \
  "The registry and ledger in this commit were NOT checked by any of: $GATES_LIST"

FAILED=""; CANTRUN=""
for g in $GATES; do
  echo "pre-commit: running doc_gates.sh $g ..."
  bash scripts/doc_gates.sh "$g"; _rc=$?
  case "$(leg_verdict "$_rc")" in
    findings) FAILED="$FAILED $g" ;;
    cantrun)  CANTRUN="$CANTRUN $g (rc=$_rc)" ;;
  esac
done

# 🔴 CHECKED BEFORE $FAILED, and that order is the fix. The pre-parse guard above catches a file
# that will not parse; this catches a leg that parsed and then did not produce a verdict — an
# unknown mode (doc_gates.sh's usage arm exits 2), a kill under CPU contention, an internal abort.
# Reporting either as a finding is the instance-38 conflation one line deeper.
if [ -n "$CANTRUN" ]; then
  cantrun "leg(s) exited with a status that is neither clean(0) nor findings(1):$CANTRUN" \
    "scripts/doc_gates.sh PARSED, so this is a runtime abort, not a mid-edit file.${FAILED:+ Other leg(s) DID return findings:$FAILED — but the run as a whole is incomplete, so the absence of a finding from the aborted leg(s) means nothing.}"
fi

if [ -z "$FAILED" ]; then
  echo "pre-commit: registry/ledger gates PASSED ($GATES)"
  echo "  NOTE: this checks that every registry row has a ledger entry citing its"
  echo "  RP-/RF- key, that no retracted phrasing appears in the corpus, and that no"
  echo "  committed CORRECTIONS.md line has been removed. It does NOT check that the"
  echo "  entry DESCRIBES the retraction correctly — round 14's CX-23 passed and was"
  echo "  still wrong."
  echo "PRECOMMIT_REGISTRY=CLEAN"
  exit 0
fi

echo
# 🔴 THIS GATE REPORTS; IT DOES NOT DECIDE. It used to print "BLOCKED" here, which was false
# whenever it ran under scripts/pre_commit_gate.sh -- that dispatcher runs this gate WARN-ONLY on
# purpose (a hook that refuses a red commit also stops one unit committing to protect its work from
# another unit, which destroyed uncommitted work four times). So the log read "pre-commit: BLOCKED"
# and then the commit landed anyway. Observed 2026-09-02: the word sent a reader to check git log
# to find out whether their own commit had happened. A gate that misstates its own consequence is
# the same defect class as a gate that passes while covering less than it claims -- state the
# FINDING, and let the caller state the consequence.
echo "pre-commit: FINDINGS — registry/ledger gate(s) failed:$FAILED"
echo "  ⚠ WHETHER THE COMMIT PROCEEDS IS THE CALLER'S DECISION, NOT THIS GATE'S."
echo "     Under scripts/pre_commit_gate.sh this gate is WARN-ONLY and the commit DOES proceed;"
echo "     that dispatcher prints its own line saying so. Run directly, this exits non-zero."
echo "     Do not read the findings below as evidence that anything was prevented."
echo "  WHY THIS FIRED: this commit stages one or more of"
printf '    %s\n' $HITS
echo "  and the gate(s) named above returned non-zero against the resulting tree."
echo
echo "  If GATE 11 (ledger-phrases / ledger-figures) failed: you added a registry row"
echo "    with no matching entry in documentation/CORRECTIONS.md. Append an entry"
echo "    citing the RP-/RF- KEY. Cite the key, NEVER the retracted string — quoting"
echo "    the string puts it permanently into an append-only file (round 14, CX-23)."
echo "  If GATE 3 (retract / retract-figures) failed: a registered retracted phrasing"
echo "    is live somewhere in the corpus. Reword the corpus, do not widen the allow"
echo "    column to hide it."
echo "  If GATE 10b (appendonly-history) failed: this commit REMOVES a line that a"
echo "    previous commit's CORRECTIONS.md contained. The ledger is append-only over"
echo "    every committed version. Append a superseding entry instead of editing."
echo
echo "  If you are certain this is wrong, 'git commit --no-verify' bypasses it and"
echo "  leaves that decision visible in your shell history."
echo "PRECOMMIT_REGISTRY=FINDINGS"
exit "$RC_FINDINGS"
