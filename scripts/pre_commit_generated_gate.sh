#!/bin/bash
# Pre-commit gate for GENERATED artifacts (task #85).
#
# WHY THIS EXISTS
#   Generated output under example/ has now been hand-edited THREE times
#   (example/report.html at dbba77d was caught by the operator, not by a gate).
#   `doc_gates.sh generated` detects it — but nothing ever forced that gate to
#   run before a commit, so detection depended on someone remembering. Memory-
#   based discipline is exactly what this project's retrospective says does not
#   work; this makes it mechanical.
#
# INSTALL (same pattern as scripts/pre_push_compile_gate.sh):
#
#   ln -s ../../scripts/pre_commit_generated_gate.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Or invoke directly:  bash scripts/pre_commit_generated_gate.sh && git commit
#
# WHEN IT FIRES
#   Only when the commit touches the generator or one of its outputs. A commit
#   that touches neither is not slowed down at all.
#
# FAIL DIRECTION: CLOSED, deliberately, and opposite to the Stage G ENOSPC guard.
#   That guard fails OPEN because a false stop costs a Spot restart. Here a false
#   stop costs one `git commit` retry, while a false pass ships a fabricated
#   number into the published record. Cheap to be wrong in the blocking direction.
#
# NO PRIVATE BYPASS. There is deliberately no SKIP=1 env var: an env-var escape
# hatch is how a gate quietly stops running. `git commit --no-verify` already
# exists, is standard, and is visible in the operator's own command line.
#
# WHAT IT DOES *NOT* COVER — read scripts/doc_gates.sh around gate_generated
# before trusting this. The `generated` gate compares NON-NUMERIC lines only for
# report.txt/report.md/README.md, because roae.py seeds nothing by default
# (roae.py:22) and Monte-Carlo figures differ every run. A hand-edited DIGIT in
# example/report.txt is therefore still caught by nothing — measured, and
# documented at doc_gates.sh's "ITEM A2" comment. This hook forces the gate we
# have to run; it does not widen it. Closing that hole means shipping example/
# with `--seed` so the comparison can be byte-exact, which changes published
# artifacts and is an operator decision, not a gate edit.
set -u

REPO_ROOT="$(git rev-parse --show-toplevel)" || exit 1
cd "$REPO_ROOT" || exit 1

# The generator plus every artifact derived from it.
#
# Codex v2 / gate-population class: this was a HARDCODED list of six, while example/
# holds TWELVE tracked generated files. hexagrams.{csv,json,svg} and all four wave.*
# were unguarded -- a corrupted hexagrams.csv staged cleanly with rc=0. A hardcoded
# population silently narrows every time the generator gains an output, which is the
# same defect shape as GATE 3 (blind to C string literals) and GATE 25 (excludes
# lean/). DERIVE it instead: roae.py plus everything tracked under example/.
WATCHED=$(printf 'roae.py\n'; git ls-files example/ 2>/dev/null)
# A population that collapses is an error, not an empty watch list. If git ls-files
# returns nothing the gate would silently watch only roae.py and pass everything else.
if [ "$(printf '%s\n' "$WATCHED" | grep -c .)" -lt 2 ]; then
    echo "pre-commit: GENERATED_GATE=ERROR could not enumerate example/ — refusing to certify" >&2
    exit 1
fi

STAGED=$(git diff --cached --name-only --diff-filter=ACM)
[ -n "$STAGED" ] || exit 0

HITS=$(printf '%s\n' "$WATCHED" | grep -Fxf <(printf '%s\n' "$STAGED") 2>/dev/null || true)
[ -n "$HITS" ] || exit 0

echo "pre-commit: generated artifacts touched by this commit:"
printf '  %s\n' $HITS

# The gate reads the WORKING TREE, but the commit records the INDEX. If those
# disagree for a watched path, the gate would validate bytes that are not the
# bytes being committed and report a pass for them. Refuse rather than mislead.
DIRTY=""
for f in $HITS; do
  if ! git diff --quiet -- "$f" 2>/dev/null; then DIRTY="$DIRTY $f"; fi
done
if [ -n "$DIRTY" ]; then
  echo "pre-commit: REFUSING — these paths differ between the index and the working tree:"
  printf '  %s\n' $DIRTY
  echo "  The gate inspects the working tree, so it would be checking bytes this"
  echo "  commit will not contain. Stage them (git add) or stash the difference."
  exit 1
fi

if [ ! -x scripts/doc_gates.sh ] && [ ! -f scripts/doc_gates.sh ]; then
  echo "pre-commit: REFUSING — scripts/doc_gates.sh is missing, so the artifacts in"
  echo "  this commit cannot be checked. That is a reason to stop, not to proceed."
  exit 1
fi

echo "pre-commit: running doc_gates.sh generated ..."
if bash scripts/doc_gates.sh generated; then
  echo "pre-commit: generated-artifact gate PASSED"
  echo "  NOTE: GATE 8 compares report.txt/report.md/README.md/report.html/report.pdf ONLY.
  It does NOT compare example/hexagrams.{csv,json,svg} or example/wave.* at all —
  staging those triggers this hook but nothing verifies their content. Widening the
  WATCHED population (done) is not the same as widening the COMPARISON (not done).
  For report.txt/report.md/README.md the comparison is non-numeric lines"
  echo "  only. A hand-edited DIGIT in example/report.txt is not covered by it."
  exit 0
fi

echo
echo "pre-commit: BLOCKED — the generated-artifact gate failed."
echo "  Fix the SOURCE (roae.py) and regenerate; never edit the artifact by hand."
echo "    python3 roae.py --all > example/report.txt"
echo "    ( cd example && python3 ../roae.py --markdown )"
echo "    cp example/report.md example/README.md"
echo "    ( cd example && python3 ../roae.py --html )"
echo "  If you are certain this is wrong, 'git commit --no-verify' bypasses it"
echo "  and leaves that decision visible in your shell history."
exit 1
