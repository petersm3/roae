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
# Companion tokens, also whole-line, emitted on EVERY terminal path:
#   SIZE_GATE_UNAPPROVED=n   unapproved first-time files at or over the limit; -1 = not measured
#   SIZE_GATE_LIMIT=n        the threshold in bytes that was actually applied; -1 = not reached, or
#                            LIMIT was not a positive integer (then nothing was applied)
#   SIZE_GATE_ERROR=<cause>  ERROR only: not-in-git-repo | limit-invalid | staged-list-failed |
#                            allowlist-unparseable
#
# 🔴 2026-09-08: every one of the three values carried trailing prose on the verdict line
# ("SIZE_GATE=OK no new files staged"), so the `grep -qx` this header promises could not match any
# of them. The prose moved to its own line and the numbers to the companion tokens above.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "  [ERROR] not inside a git repository — there is no index to measure"
  echo "SIZE_GATE_UNAPPROVED=-1"; echo "SIZE_GATE_LIMIT=-1"
  echo "SIZE_GATE_ERROR=not-in-git-repo"; echo "SIZE_GATE=ERROR"; exit 2; }

# 1.25 MiB. RAISED from 1 MiB 2026-09-04 on the operator's instruction ("if it's easier, just
# increase gate to 1.25 mb"), in step with roae-private's postwindow_commit.sh so the two halves of
# one rule cannot drift. NOTE, measured the same day: neither gate ever applied to an already-tracked
# file -- this one scopes to `--diff-filter=A` and the private one to `git ls-files --others`. The
# row that prompted the raise (Q-412) assumed a growing tracked file was about to be refused; it was
# not, and could not be.
LIMIT=${LIMIT:-1310720}
ALLOW=${ALLOW:-scripts/oversize_approved.tsv} # path<TAB>who approved<TAB>date<TAB>why

# 🔴 Q-746 / V3A-122 (Codex v3 E3 batch 3, Fable R, 2026-09-24). FIVE BYPASSES, all executed at
# 5c296837 against a 2,242,768 B control that this gate correctly REFUSED. Each of the following
# read SIZE_GATE=OK:
#   #1 the working copy was absent (`git add big; rm big`, or `gzip -9 big` without re-staging --
#      the dispatcher's own advice): a `[ -f "$f" ] || continue` skipped the path while its blob
#      stayed staged. The index is what is committed; the working tree is irrelevant here.
#   #2 a non-ASCII name: `git diff --name-only` without -z prints "r\303\251sultat.dat" in quotes,
#      and that quoted string names no file. Now read NUL-delimited.
#   #3 a name that is also a glob (`gate?.dat`): `git ls-files -s -- "$f"` treated it as a
#      PATHSPEC and measured gate0.dat's blob instead. There is no pathspec lookup any more: the
#      blob id comes from the same `--raw` record as the name, so the two cannot disagree.
#   #4 a tracked DIRECTORY replaced by a file of the same name: `git cat-file -e HEAD:$f` is true
#      for a tree, so the new file read as "already in a parent". Now only a REGULAR-FILE entry
#      (mode 100644/100755) in a parent exempts a path.
#   #5 LIMIT=1.25MiB: `[ "$sz" -ge "$LIMIT" ]` errored ("integer expression expected"), the
#      `|| continue` swallowed the error, and nothing was ever compared. LIMIT is now validated
#      first and anything but a plain positive decimal integer is SIZE_GATE=ERROR.
# Found by nothing in this repository: every one was a path the gate's author did not try.
case "$LIMIT" in
  ''|*[!0-9]*|0*) _limit_ok=0 ;;
  *) [ "${#LIMIT}" -le 18 ] && _limit_ok=1 || _limit_ok=0 ;;
esac
if [ "$_limit_ok" != 1 ]; then
  echo "  [ERROR] LIMIT='$LIMIT' is not a positive whole number of bytes — nothing could be compared"
  echo "          against it. (Plain decimal only: 1310720, not 1.25MiB, not 0, no leading zero.)"
  echo "SIZE_GATE_UNAPPROVED=-1"; echo "SIZE_GATE_LIMIT=-1"
  echo "SIZE_GATE_ERROR=limit-invalid"; echo "SIZE_GATE=ERROR"; exit 2
fi

# ONLY paths whose content is newly tracked. `--diff-filter=A` is the whole point: a modification to
# an already-tracked large file (solve.c, doc_gates.sh) is not a new obligation. T (type change) is
# included because a symlink or submodule replaced by a regular file IS new content at that path;
# the parent check below exempts it only if a parent held a regular file there.
# `--no-renames`, pinned rather than left to diff.renames: with rename detection on, a new path
# that git pairs with a deleted one reads as R and was never measured. A pure rename of an approved
# large file therefore needs its NEW path in $ALLOW -- the allowlist is keyed by path anyway.
# 🔴 --diff-filter=A IS RELATIVE TO HEAD, AND THAT IS WRONG DURING A MERGE. Caught 2026-09-04 when
# this gate refused a LEGITIMATE merge: bringing main into an older branch presents every file the
# branch lacks as an "addition", so scripts/doc_gates.sh (1,162,877 B) and
# reports/certificates/core_gender_ccn4_unsat.drat.gz (1,299,983 B) -- both long since tracked on
# main -- read as first-time additions and the commit was blocked. Left unfixed this would have
# quietly blocked EVERY future merge carrying a large existing file, and the failure would have
# looked exactly like the gate working. A path is newly tracked only if it is in NEITHER parent.
_regular_in() {   # $1=commit $2=path -> 0 iff $1 holds a REGULAR FILE (not a tree/symlink/gitlink) at $2
  local _m
  _m=$(git ls-tree -z "$1" -- ":(literal)$2" 2>/dev/null | tr '\0' '\n' | head -n1 | cut -d' ' -f1)
  case "$_m" in 100644|100755) return 0 ;; *) return 1 ;; esac
}
_in_a_parent() {   # $1=path -> 0 if the path already exists AS A FILE on either merge parent
  _regular_in HEAD "$1" && return 0
  _mh="$(git rev-parse --git-dir)/MERGE_HEAD"
  [ -f "$_mh" ] || return 1
  while read -r _p; do
    [ -n "$_p" ] || continue
    _regular_in "$_p" "$1" && return 0
  done < "$_mh"
  return 1
}

_raw=$(mktemp 2>/dev/null) || {
  echo "  [ERROR] mktemp failed — cannot hold the staged list, so it was not read"
  echo "SIZE_GATE_UNAPPROVED=-1"; echo "SIZE_GATE_LIMIT=$LIMIT"
  echo "SIZE_GATE_ERROR=staged-list-failed"; echo "SIZE_GATE=ERROR"; exit 2; }
trap 'rm -f "$_raw"' EXIT
# One NUL-delimited record per path: ":oldmode newmode oldsha newsha status" NUL "path" NUL.
# The newsha IS the index blob -- the bytes the commit ships -- read off the same record as the name.
if ! git diff --cached --raw -z --no-abbrev --no-renames --diff-filter=AT > "$_raw" 2>/dev/null; then
  echo "  [ERROR] could not list staged additions (git diff --cached --raw --diff-filter=AT failed)"
  echo "SIZE_GATE_UNAPPROVED=-1"; echo "SIZE_GATE_LIMIT=$LIMIT"
  echo "SIZE_GATE_ERROR=staged-list-failed"; echo "SIZE_GATE=ERROR"; exit 2
fi
[ -s "$_raw" ] || {
  echo "  [ok]   no new files staged"
  echo "SIZE_GATE_UNAPPROVED=0"; echo "SIZE_GATE_LIMIT=$LIMIT"; echo "SIZE_GATE=OK"; exit 0; }

# 🔴 AN UNREADABLE ALLOWLIST IS NOT AN EMPTY ONE. If the file is missing every approved path would
# read as unapproved and the gate would refuse a legitimate commit; if it were silently treated as
# permissive, every path would read as approved. Neither is acceptable -- say which happened.
approved=""
if [ -e "$ALLOW" ]; then
  if ! approved=$(awk -F'\t' '!/^#/ && NF>=1 && $1!="" {print $1}' "$ALLOW" 2>/dev/null); then
    echo "  [ERROR] $ALLOW exists but could not be parsed — an unreadable allowlist is not an empty one"
    echo "SIZE_GATE_UNAPPROVED=-1"; echo "SIZE_GATE_LIMIT=$LIMIT"
    echo "SIZE_GATE_ERROR=allowlist-unparseable"; echo "SIZE_GATE=ERROR"; exit 2
  fi
fi
# Exact string equality, one allowlist row at a time. `grep -qxF -- "$f"` was a bypass of its own:
# a path containing a newline is SEVERAL fixed-string patterns, and any one of them matching an
# approved row approved the whole path.
_approved() {
  local _a
  while IFS= read -r _a; do [ "$_a" = "$1" ] && return 0; done <<< "$approved"
  return 1
}

bad=0; n=0
while IFS= read -r -d '' meta && IFS= read -r -d '' f; do
  n=$((n+1))
  read -r _om nm _os blob _st <<< "${meta#:}"
  [ "$nm" = 160000 ] && continue            # a submodule pointer: no blob of ours to measure
  if _in_a_parent "$f"; then continue; fi   # a regular file in a merge parent: not a NEW obligation
  # Measure the STAGED bytes, never the worktree's -- they can differ, the worktree copy may not
  # exist at all, and the commit ships the staged ones.
  case "${blob:-}" in
    *[!0-9a-f]*|''|0000000000000000000000000000000000000000*)
      echo "  [FAIL] $f is staged but has no index blob — cannot measure what would be committed"
      bad=$((bad+1)); continue ;;
  esac
  sz=$(git cat-file -s "$blob" 2>/dev/null)
  case "${sz:-}" in ''|*[!0-9]*) echo "  [FAIL] $f: could not size its staged blob"; bad=$((bad+1)); continue;; esac
  [ "$sz" -ge "$LIMIT" ] || continue
  # solve.c is exempt by operator ruling 2026-08-06 (it is the enumerator; it grows by design).
  [ "$f" = "solve.c" ] && { echo "  [ok]   $f ($sz B) — exempt by operator ruling 2026-08-06"; continue; }
  if _approved "$f"; then
    echo "  [ok]   $f ($sz B) — approved in $ALLOW"
  else
    echo "  [FAIL] $f is $sz B (>= $LIMIT) and is being tracked for the FIRST time, unapproved."
    bad=$((bad+1))
  fi
done < "$_raw"
# A non-empty listing that yielded no complete record was not read, whatever else it was.
if [ "$n" -eq 0 ]; then
  echo "  [ERROR] the staged listing was non-empty but held no complete path record"
  echo "SIZE_GATE_UNAPPROVED=-1"; echo "SIZE_GATE_LIMIT=$LIMIT"
  echo "SIZE_GATE_ERROR=staged-list-failed"; echo "SIZE_GATE=ERROR"; exit 2
fi

if [ "$bad" -gt 0 ]; then
  echo "  [REFUSED] $bad unapproved file(s) >= $LIMIT B staged for first-time tracking"
  echo "   The standing rule is that a file this size needs an explicit operator OK before \`git add\`."
  echo "   To clear: get the OK and add a row to $ALLOW quoting it, or gitignore it, or gzip -9 it"
  echo "   AND RE-STAGE: this gate measures the INDEX, so the uncompressed blob stays staged until"
  echo "   you run \`git rm --cached -- <file>\` and \`git add -- <file>.gz\` (the .gz is measured too)."
  echo "   Do NOT widen \$LIMIT to get past this — the threshold is the operator's, not the gate's."
  echo "SIZE_GATE_UNAPPROVED=$bad"; echo "SIZE_GATE_LIMIT=$LIMIT"; echo "SIZE_GATE=REFUSED"
  exit 1
fi
echo "  [ok]   no unapproved first-time file >= $LIMIT B"
echo "SIZE_GATE_UNAPPROVED=0"; echo "SIZE_GATE_LIMIT=$LIMIT"; echo "SIZE_GATE=OK"
exit 0
