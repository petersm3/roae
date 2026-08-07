#!/bin/bash
# Pre-push dispatcher — runs BOTH push gates against the PUSHED SHA.
# (dispatcher: 2026-08-06, task #145; pushed-sha semantics: 2026-08-06, task #150)
#
# WHY A DISPATCHER
#   Until 2026-08-06 the pre-push hook was a bare symlink to
#   pre_push_compile_gate.sh, so a markdown-only push — most of what this
#   project publishes — reached the public repo with ZERO documentation-gate
#   coverage: scripts/doc_gates.sh existed but nothing ever forced it to run
#   at a publish point. Same construction as the pre-commit dispatcher
#   (operator ruling #1, O-redfloor): replacing this file with a bare symlink
#   to either gate below SILENTLY DISABLES the other — that is the failure
#   this dispatcher exists to prevent.
#
# WHY THE PUSHED SHA AND NOT THE WORKING TREE
#   `git push` publishes committed history, but until task #150 this hook
#   validated whatever happened to be in the working tree at push time. Two
#   failure modes follow, both real:
#     - a defect present in the pushed commit but already fixed in
#       uncommitted local edits PASSES the hook and ships broken — the
#       218-commit history replay (task #149) found 12 commits whose
#       committed trees failed their own gates, four of them pushed and red
#       in public for ~2.5 days, and at the moment this semantics fix was
#       written, HEAD itself was exactly this case (a retracted figure
#       restated in reports/METHODS.md, fixed only in uncommitted edits);
#     - a defect that exists only in uncommitted local edits BLOCKS a push
#       whose committed content was fine.
#   Both are the same mistake: gating bytes that are not the bytes being
#   published. So for every ref update this hook checks the pushed sha out
#   into a TEMPORARY DETACHED WORKTREE and runs THAT TREE'S OWN copies of
#   both gates inside it — the committed bytes, judged by the gate versions
#   they were committed with (the task-#149 replay semantics). The temp
#   worktree is removed on every exit path, including failure and ^C.
#
#   Measured on the 2-core orchestrator, 2026-08-06: worktree add ~0.2 s,
#   remove+prune ~0.3 s, against a gate runtime of ~70-90 s per pushed sha
#   (doc gates ~12-20 s depending on the tree's gate version, compile+selftest
#   ~56 s). The pushed-sha semantics cost under 1 s — noise. A push of N
#   distinct new branch tips runs the gates N times; the common case is 1.
#
# STDIN CONTRACT (githooks(5)): one line per ref being pushed,
#   <local-ref> SP <local-sha> SP <remote-ref> SP <remote-sha> LF
#   - branch DELETION (local sha all zeros): nothing is published — skipped.
#   - NEW remote branch (remote sha all zeros): gated like any update; the
#     remote sha is never needed, only the sha being published.
#   - duplicate shas across refs are gated once.
#   Run directly (no ref list on a terminal), it gates HEAD — the sha a
#   plain `git push` of the current branch would publish:
#     bash scripts/pre_push_gate.sh && git push
#
# INSTALL — see DEVELOPMENT.md §"Git hooks". One manual step per clone,
# irreducible by git's own design (a clone must never auto-run repo code):
#
#   ln -sf ../../scripts/pre_push_gate.sh .git/hooks/pre-push && ln -sf ../../scripts/pre_commit_gate.sh .git/hooks/pre-commit
#
# GATES — both BLOCKING, and both ALWAYS RUN (findings aggregate: a red doc
# gate does not hide a compile failure, or vice versa). Doc gates run first
# because they are the cheap gate and markdown-only pushes are the common
# case, so the common failure is reported in ~20 s, not ~76 s.
#
#   1. scripts/doc_gates.sh all           — documentation-integrity gates.
#      Blocking set = doc_gates.sh's own hard-gate set (its PASS banner is the
#      maintained list); its report-only gates print [WARN]/[note] without
#      setting the exit code, and this hook takes that exit code as-is.
#   2. scripts/pre_push_compile_gate.sh   — solve.c compile + --selftest sha.
#
#   Both are executed FROM THE PUSHED TREE, so what is enforced is the
#   contract that tree itself declares. A pushed sha whose tree has no
#   scripts/doc_gates.sh or no scripts/pre_push_compile_gate.sh (possible
#   when pushing a tag or branch pointing at pre-gate history, or if a
#   commit DELETES a gate) is BLOCKED, not skipped: for current trees a
#   missing gate is a regression, and for genuinely historical pushes
#   `git push --no-verify` is the visible, deliberate bypass. Same if the
#   tree's doc_gates.sh predates the `all` mode (exits 2 on usage).
#
# WHAT IS DELIBERATELY NOT HERE: `doc_gates.sh generated` (~107 s measured
# 2026-08-06 — three unseeded roae.py runs). It is enforced at pre-commit by
# pre_commit_registry+generated_gate.sh (tracked as scripts/pre_commit_gate.sh)
# exactly when roae.py or an example/ artifact is staged; running it on EVERY
# push would take the hook from ~76 s to ~183 s to re-check artifacts most
# pushes do not touch — and a hook that slow is a hook that gets bypassed
# with --no-verify, which is worse than no gate. Residual hole, stated rather
# than hidden: a hand-edited artifact committed with `git commit --no-verify`
# reaches a push unchecked by this hook. That bypass is visible in shell
# history, which is the project's accepted trade for hooks (DEVELOPMENT.md
# §"Git hooks").
#
# NO PRIVATE BYPASS (same contract as both underlying gates): there is
# deliberately no SKIP env var. `git push --no-verify` already exists and
# leaves the decision visible in shell history.
#
# FAIL DIRECTION: CLOSED. A false stop costs one retry; a false pass ships a
# doc-integrity defect or a compile error into the published record.
set -u

ROOT=$(git rev-parse --show-toplevel) || exit 1
Z40=0000000000000000000000000000000000000000

# ---- collect the shas being published -------------------------------------
SHAS=""
if [ -t 0 ]; then
  SHAS=$(git rev-parse HEAD) || exit 1
  echo "pre-push: direct invocation (no ref list on stdin) — gating HEAD ${SHAS:0:12}"
else
  while read -r lref lsha rref rsha; do
    [ -n "${lsha:-}" ] || continue
    if [ "$lsha" = "$Z40" ]; then
      echo "pre-push: ${rref:-?} — deletion, nothing is published, no gates to run"
      continue
    fi
    case " $SHAS " in
      *" $lsha "*) ;;                       # same sha via another ref: gate once
      *) SHAS="$SHAS $lsha" ;;
    esac
  done
fi
SHAS=${SHAS# }
if [ -z "$SHAS" ]; then
  echo "pre-push: no shas to gate"
  exit 0
fi

# ---- temp-worktree lifecycle: removed on EVERY exit path ------------------
# A leaked worktree pollutes `git worktree list` until pruned; clean up on
# normal exit, gate failure, and interrupt alike. The pinned worktrees
# (e.g. roae-v4compiler) are never touched: this only ever removes the
# mktemp directory it created itself.
WTBASE=""
cleanup() {
  if [ -n "$WTBASE" ]; then
    git -C "$ROOT" worktree remove --force "$WTBASE/tree" >/dev/null 2>&1
    rm -rf "$WTBASE"
    git -C "$ROOT" worktree prune >/dev/null 2>&1
    WTBASE=""
  fi
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap 'cleanup; exit 129' HUP

# ---- gate each pushed sha in its own detached worktree --------------------
RC=0
for sha in $SHAS; do
  short=${sha:0:12}
  t0=$SECONDS
  WTBASE=$(mktemp -d "${TMPDIR:-/tmp}/prepush_gate.XXXXXX") || { echo "pre-push: BLOCKED — mktemp failed"; exit 1; }
  WT="$WTBASE/tree"
  if ! git -C "$ROOT" worktree add --detach --quiet "$WT" "$sha"; then
    echo "pre-push: BLOCKED — cannot check out pushed sha $short into a temp worktree"
    exit 1
  fi
  echo "pre-push: gating pushed sha $short (its own committed gates, temp worktree)"

  SHARC=0
  if [ -f "$WT/scripts/doc_gates.sh" ]; then
    ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
        bash scripts/doc_gates.sh all ) || SHARC=1
  else
    echo "pre-push: FAIL — pushed sha $short has no scripts/doc_gates.sh."
    echo "  For a current tree that is a regression; for a deliberate push of"
    echo "  pre-gate history, 'git push --no-verify' is the visible bypass."
    SHARC=1
  fi
  echo
  if [ -f "$WT/scripts/pre_push_compile_gate.sh" ]; then
    ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
        bash scripts/pre_push_compile_gate.sh ) || SHARC=1
  else
    echo "pre-push: FAIL — pushed sha $short has no scripts/pre_push_compile_gate.sh."
    echo "  Same rule as above: blocked, and --no-verify is the visible bypass."
    SHARC=1
  fi

  cleanup
  if [ "$SHARC" -ne 0 ]; then
    RC=1
    echo "pre-push: pushed sha $short FAILED its gates ($((SECONDS - t0)) s)"
  else
    echo "pre-push: pushed sha $short passed both gates ($((SECONDS - t0)) s)"
  fi
done

if [ "$RC" -ne 0 ]; then
  echo
  echo "pre-push: BLOCKED — at least one pushed sha failed its gates above."
  echo "  The gates ran against the COMMITTED trees being published, not the"
  echo "  working tree: a fix that exists only as an uncommitted edit does not"
  echo "  clear this — commit it. 'git push --no-verify' bypasses this and"
  echo "  leaves that visible in shell history."
fi
exit $RC
