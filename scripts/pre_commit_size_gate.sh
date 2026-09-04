#!/usr/bin/env bash
# pre_commit_size_gate.sh — refuse to NEWLY TRACK a file >= 1 MiB without a recorded approval.
#
# 🔴 WHY THIS EXISTS. The standing operator rule is: **any file >= 1 MB needs an explicit OK before
# `git add`** (`solve.c` exempt, 2026-08-06). Measured 2026-09-04: that rule had **NO ENFORCEMENT IN
# THIS REPOSITORY AT ALL.**
#
#   * `scripts/pre_commit_gate.sh`, `pre_commit_registry_gate.sh`, `pre_commit_generated_gate.sh`
#     and `pre_push_gate.sh` contain no size check of any kind.
#   * `oversize_approved.tsv` existed only in roae-private and was read only by that repo's
#     `postwindow_commit.sh` PRIVATE block. Its public block runs `git add -A` with no size check.
#   * `HARDENING_BACKLOG.md` Q-210 states the public tree "has its own separate guard". It did not.
#     A rule believed to be enforced, enforced nowhere, is worse than one known to be manual: nobody
#     looks, because everybody assumes something already did.
#
# 22 tracked files here are already >= 1 MiB, which is exactly why the scope below is NEWLY-tracked
# files only. A gate that fires on the existing corpus fires on every commit and gets removed within
# a day -- the failure mode this project has recorded for guards that "always fire".
#
# Verdict token, whole-line, grep -qx-able -- never inferred from output shape:
#   SIZE_GATE=OK        nothing newly tracked crosses the threshold, or every crossing is approved
#   SIZE_GATE=REFUSED   an unapproved large file is staged for first-time tracking. rc 1.
#   SIZE_GATE=ERROR     could not measure. rc 2 -- NEVER reports OK from a list it could not read,
#                       because "looked and found nothing" and "could not look" are different facts.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "SIZE_GATE=ERROR not in a git repo"; exit 2; }

# 1.25 MiB. RAISED from 1 MiB 2026-09-04 on the operator's instruction ("if it's easier, just
# increase gate to 1.25 mb"), in step with roae-private's postwindow_commit.sh so the two halves of
# one rule cannot drift. NOTE, measured the same day: neither gate ever applied to an already-tracked
# file -- this one scopes to `--diff-filter=A` and the private one to `git ls-files --others`. The
# row that prompted the raise (Q-412) assumed a growing tracked file was about to be refused; it was
# not, and could not be.
LIMIT=${LIMIT:-1310720}
ALLOW=${ALLOW:-scripts/oversize_approved.tsv} # path<TAB>who approved<TAB>date<TAB>why

# ONLY files being added for the first time. `git diff --cached --diff-filter=A` is the whole point:
# a modification to an already-tracked large file (solve.c, doc_gates.sh) is not a new obligation.
# 🔴 --diff-filter=A IS RELATIVE TO HEAD, AND THAT IS WRONG DURING A MERGE. Caught 2026-09-04 when
# this gate refused a LEGITIMATE merge: bringing main into an older branch presents every file the
# branch lacks as an "addition", so scripts/doc_gates.sh (1,162,877 B) and
# reports/certificates/core_gender_ccn4_unsat.drat.gz (1,299,983 B) -- both long since tracked on
# main -- read as first-time additions and the commit was blocked. Left unfixed this would have
# quietly blocked EVERY future merge carrying a large existing file, and the failure would have
# looked exactly like the gate working. A path is newly tracked only if it is in NEITHER parent.
_in_a_parent() {   # $1=path -> 0 if the path already exists on either merge parent
  git cat-file -e "HEAD:$1" 2>/dev/null && return 0
  _mh="$(git rev-parse --git-dir)/MERGE_HEAD"
  [ -f "$_mh" ] || return 1
  while read -r _p; do
    [ -n "$_p" ] || continue
    git cat-file -e "$_p:$1" 2>/dev/null && return 0
  done < "$_mh"
  return 1
}

if ! staged=$(git diff --cached --name-only --diff-filter=A 2>/dev/null); then
  echo "SIZE_GATE=ERROR could not list staged additions"; exit 2
fi
[ -n "$staged" ] || { echo "SIZE_GATE=OK no new files staged"; exit 0; }

# 🔴 AN UNREADABLE ALLOWLIST IS NOT AN EMPTY ONE. If the file is missing every approved path would
# read as unapproved and the gate would refuse a legitimate commit; if it were silently treated as
# permissive, every path would read as approved. Neither is acceptable -- say which happened.
approved=""
if [ -e "$ALLOW" ]; then
  if ! approved=$(awk -F'\t' '!/^#/ && NF>=1 && $1!="" {print $1}' "$ALLOW" 2>/dev/null); then
    echo "SIZE_GATE=ERROR $ALLOW exists but could not be parsed"; exit 2
  fi
fi

bad=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  [ -f "$f" ] || continue                      # staged deletion/rename target that is gone: not ours
  if _in_a_parent "$f"; then continue; fi   # arrives via a merge parent: not a NEW obligation
  # Measure the STAGED bytes, not the worktree's -- they can differ, and the commit ships the staged
  # ones. `git cat-file -s` on the index blob is the only number that describes what is published.
  blob=$(git ls-files -s -- "$f" 2>/dev/null | awk '{print $2; exit}')
  if [ -z "$blob" ]; then
    echo "  [FAIL] $f is staged but has no index blob — cannot measure what would be committed"
    bad=$((bad+1)); continue
  fi
  sz=$(git cat-file -s "$blob" 2>/dev/null)
  case "${sz:-}" in ''|*[!0-9]*) echo "  [FAIL] $f: could not size its staged blob"; bad=$((bad+1)); continue;; esac
  [ "$sz" -ge "$LIMIT" ] || continue
  # solve.c is exempt by operator ruling 2026-08-06 (it is the enumerator; it grows by design).
  [ "$f" = "solve.c" ] && { echo "  [ok]   $f ($sz B) — exempt by operator ruling 2026-08-06"; continue; }
  if printf '%s\n' "$approved" | grep -qxF -- "$f"; then
    echo "  [ok]   $f ($sz B) — approved in $ALLOW"
  else
    echo "  [FAIL] $f is $sz B (>= $LIMIT) and is being tracked for the FIRST time, unapproved."
    bad=$((bad+1))
  fi
done <<< "$staged"

if [ "$bad" -gt 0 ]; then
  echo "SIZE_GATE=REFUSED $bad unapproved file(s) >= $LIMIT B staged for first-time tracking"
  echo "   The standing rule is that a file this size needs an explicit operator OK before \`git add\`."
  echo "   To clear: get the OK and add a row to $ALLOW quoting it, or gzip -9 it, or gitignore it."
  echo "   Do NOT widen \$LIMIT to get past this — the threshold is the operator's, not the gate's."
  exit 1
fi
echo "SIZE_GATE=OK no unapproved first-time file >= $LIMIT B"
exit 0
