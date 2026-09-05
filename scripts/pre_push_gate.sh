#!/bin/bash
# Pre-push dispatcher — runs BOTH push gates against the PUSHED SHA, plus a
# CONDITIONAL third leg (`doc_gates.sh generated`) when the pushed range
# touches the generated-artifact surface.
# (dispatcher: 2026-08-06, task #145; pushed-sha semantics: 2026-08-06,
# task #150; conditional generated leg: 2026-08-07)
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
#   1b. scripts/doc_gates.sh generated    — CONDITIONAL, blocking when it runs;
#      see "THE `generated` LEG IS CONDITIONAL" below for when and why.
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
# THE `generated` LEG IS CONDITIONAL (2026-08-07, gate-blind-spot closure #1;
# it was previously absent entirely). `doc_gates.sh generated` costs ~67 s
# measured 2026-08-07 (~107 s on the 2026-08-06 measurement — three roae.py
# runs either way, unseeded then, seeded since 2026-09-04, ≥4x the ~17 s the rest of the doc gates take), so
# running it on EVERY push would roughly double this hook for artifacts most
# pushes cannot have touched — and a hook that slow is a hook that gets
# bypassed with --no-verify, which uncovers everything. It also cannot be
# left out: until today a hand-edited artifact committed with
# `git commit --no-verify` (the pre-commit gate is staged-path-conditional)
# reached a push with NOTHING between it and the public repo — the `all`
# banner itself says GATE 8 is not in `all`.
#   So this hook mirrors the pre-commit gate's conditioning at push
# granularity: for each pushed sha it runs the pushed tree's own
# `doc_gates.sh generated` exactly when the PUSHED RANGE (remote sha →
# pushed sha) touches roae.py or example/ — the only way the generated-
# artifact surface can be changing hands — and FAIL-CLOSED runs it when
# there is no base to diff against (new remote branch, unknown remote sha,
# direct invocation with no upstream): with no base the artifacts cannot be
# proven untouched, and a wrongly-run leg costs ~67 s once while a
# wrongly-skipped one ships an unchecked artifact. Common markdown-only
# pushes pay one `git diff --name-only` (~ms).
#   THAT RESIDUAL IS CLOSED (2026-09-04, later the same day it widened). It read:
# for report.txt/.md, README.md and — since 2026-09-04 — report.html, the
# generated gate compares NON-NUMERIC lines only (roae.py is unseeded), so a
# hand-edited digit in those FOUR is caught by nothing; report.html joined the
# list when example/report.pdf was removed for embedding the complete
# unsubsetted DejaVu font programs, that PDF having been GATE 8 LEG 5, the only
# leg comparing report.html digit-for-digit. example/ was then regenerated and
# reshipped under `--seed 20260904`, GATE 8 regenerates under the same seed, and
# all ELEVEN tracked example/ artifacts are compared BYTE-EXACT, digits
# included. No file in this hook's scope is digit-blind any more.
#   The cost figures above are unchanged in kind: still three roae.py runs, now
# SEEDED rather than unseeded. See pre_commit_generated_gate.sh's header.
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

# ---- does this pushed sha need the `generated` leg? -----------------------
# $1 = pushed sha, $2 = remote sha ('' or all-zeros when there is no base).
# Returns 0 (leg required) when roae.py or example/ differs between base and
# pushed sha, AND on every path where that cannot be established — no base,
# base not present locally, diff error — because fail-closed is the cheap
# direction here (~67 s once vs an unchecked artifact published). Fixed
# pathspecs only, no patterns.
needs_generated() {
  local base="$2" changed
  [ -n "$base" ] && [ "$base" != "$Z40" ] || return 0
  git cat-file -e "$base^{commit}" 2>/dev/null || return 0
  changed=$(git diff --name-only "$base" "$1" -- roae.py example/ 2>/dev/null) || return 0
  [ -n "$changed" ]
}

# ---- does this pushed sha need the #167 resume leg? -----------------------
# $1 = pushed sha, $2 = remote sha ('' or all-zeros when there is no base).
# Returns 0 (leg required) when solve.c differs between base and pushed sha,
# and on every path where that cannot be established — same fail-closed rule
# as needs_generated, and for a sharper reason: the gate exists because
# `--selftest-resume` is BLIND to the #167 defect in both directions, so a
# solve.c change that skips this leg is exactly the regression it prevents.
# Fixed pathspec only, no patterns.
needs_resume167() {
  local base="$2" changed
  [ -n "$base" ] && [ "$base" != "$Z40" ] || return 0
  git cat-file -e "$base^{commit}" 2>/dev/null || return 0
  changed=$(git diff --name-only "$base" "$1" -- solve.c 2>/dev/null) || return 0
  [ -n "$changed" ]
}

# ---- collect the shas being published -------------------------------------
# GENSHAS ⊆ SHAS: the pushed shas whose range touches the generated-artifact
# surface (or has no provable base). A sha pushed via two refs needs the leg
# if EITHER ref's range does.
SHAS=""
GENSHAS=""
R167SHAS=""
NEWREFS=""
if [ -t 0 ]; then
  SHAS=$(git rev-parse HEAD) || exit 1
  echo "pre-push: direct invocation (no ref list on stdin) — gating HEAD ${SHAS:0:12}"
  # A plain `git push` publishes HEAD onto its upstream; diff against that
  # when it exists, otherwise fail-closed into the leg.
  UPSTREAM=$(git rev-parse '@{u}' 2>/dev/null || true)
  if needs_generated "$SHAS" "$UPSTREAM"; then GENSHAS=$SHAS; fi
  if needs_resume167 "$SHAS" "$UPSTREAM"; then R167SHAS=$SHAS; fi
else
  while read -r lref lsha rref rsha; do
    [ -n "${lsha:-}" ] || continue
    if [ "$lsha" = "$Z40" ]; then
      echo "pre-push: ${rref:-?} — deletion, nothing is published, no gates to run"
      continue
    fi
    # ---- (1) PEEL ANNOTATED TAGS -------------------------------------------
    # For an annotated tag git hands us the TAG OBJECT sha, and a tag object has
    # no tree. Every file-based gate below then reports "has no scripts/..." and
    # BLOCKS the push. That made the standing tag-before-branch-delete rule
    # impossible to execute — found 2026-08-21 pushing v4-2a-engine-ed8125c,
    # where the compile gate PASSED (anchor 403f7202 reproduced) yet the push
    # was refused. Peel to the underlying commit and gate that instead.
    _peeled=$(git rev-parse -q --verify "${lsha}^{commit}" 2>/dev/null || true)
    if [ -z "$_peeled" ]; then
      echo "pre-push: ${rref:-?} — $lsha is not commit-ish (no tree to gate); skipping"
      continue
    fi
    if [ "$_peeled" != "$lsha" ]; then
      echo "pre-push: ${rref:-?} — annotated tag peeled to commit ${_peeled:0:12}"
      lsha=$_peeled
    fi
    # ---- (1b) EVERY NEW BRANCH REF IS A DECLARATION EVENT -------------------
    # Codex v2 charge 5, SECOND HALF (2026-09-02). NEWREFS used to be collected ONLY
    # inside the already-published arm below, so a new branch carrying a NEW tree was
    # never named to GATE 19 either — and GATE 19, run inside the pushed tree's own
    # worktree, enumerates `refs/remotes/origin/*`, which by definition does not yet
    # contain the branch being created. Both halves of "a new public ref name" were
    # therefore ungated: one because the check was skipped, one because the check could
    # not see its subject. An all-zero REMOTE sha is the githooks(5) signal for "this ref
    # does not exist on the remote yet", and that is the only condition that matters here
    # — it is orthogonal to whether the TREE is new.
    #
    # SCOPED TO refs/heads/, and that scope is load-bearing rather than tidy. GATE 19 is a
    # BRANCH registry; it strips `refs/heads/` and looks the remainder up. The first cut of
    # this collection took ${rref} unconditionally, so pushing a TAG at a published sha
    # handed GATE 19 the literal string "refs/tags/v4-…" as a branch name and BLOCKED the
    # push — reintroducing exactly the breakage the annotated-tag peel at (1) above was
    # written to cure (found 2026-08-21 pushing v4-2a-engine-ed8125c). MEASURED 2026-09-02
    # on the shipped hook: `refs/tags/v4-test` at a published sha produced
    # "[pending] also checking branch about to be published: refs/tags/v4-test".
    # Tags are not in the branch registry's population; a tag push must not consult it.
    case "${rref:-}" in
      refs/heads/*)
        case "${rsha:-}" in
          ''|*[!0]*) ;;                      # existing remote branch: name already known
          *) case " $NEWREFS " in
               *" $rref "*) ;;
               *) NEWREFS="$NEWREFS $rref" ;;
             esac ;;
        esac ;;
    esac
    # ---- (2) SKIP WHAT IS ALREADY PUBLISHED --------------------------------
    # A ref pointing at a commit already reachable on origin publishes NO new
    # tree, so there is nothing to gate. This is not a loophole: to be reachable
    # on origin a commit had to clear this gate when it was first pushed — or it
    # predates the gate entirely, in which case the requirement is unsatisfiable
    # by construction (ed8125c5 has no scripts/doc_gates.sh because that script
    # did not yet exist). Without this clause the hook retroactively re-gates
    # published history and can never pass.
    _pub=""
    for _r in $(git for-each-ref --format='%(refname)' refs/remotes/origin/ 2>/dev/null); do
      if git merge-base --is-ancestor "$lsha" "$_r" 2>/dev/null; then _pub=$_r; break; fi
    done
    if [ -n "$_pub" ]; then
      # Codex v2: this skip is correct for TREE CONTENT -- no new tree, nothing to
      # gate -- but it is ORTHOGONAL to the branch-name declaration check, which is
      # about the REF, not the tree. A new branch pointing at an already-published
      # sha therefore published with no declaration gate at all. Measured. The ref was
      # already recorded in NEWREFS at (1b) above, unconditionally, so the declaration
      # check still runs whether or not we skip the content gates here.
      echo "pre-push: ${rref:-?} — ${lsha:0:12} already published (reachable from ${_pub#refs/remotes/}); no new tree, content gates skipped"
      continue
    fi
    case " $SHAS " in
      *" $lsha "*) ;;                       # same sha via another ref: gate once
      *) SHAS="$SHAS $lsha" ;;
    esac
    if needs_resume167 "$lsha" "${rsha:-}"; then
      case " $R167SHAS " in *" $lsha "*) ;; *) R167SHAS="$R167SHAS $lsha";; esac
    fi
    if needs_generated "$lsha" "${rsha:-}"; then
      case " $GENSHAS " in
        *" $lsha "*) ;;
        *) GENSHAS="$GENSHAS $lsha" ;;
      esac
    fi
  done
fi
SHAS=${SHAS# }
R167SHAS=${R167SHAS# }
NEWREFS=${NEWREFS# }
# ---- DECLARATION LEG: unconditional, and it runs BEFORE the content legs -------
# Codex v2 charge 5, RESIDUAL (2026-09-02). This leg used to live INSIDE the
# `[ -z "$SHAS" ]` arm below, so it ran only when the push carried no new tree at all.
# A push of two refs — one new undeclared branch at a published sha, one ordinary
# branch with new commits — made SHAS non-empty and skipped the declaration check
# entirely. MEASURED: with both lines on stdin the hook never emitted "NEW branch
# ref(s) to declare" and never set DOC_GATES_PENDING_BRANCHES, so GATE 19 ran in the
# pushed worktree against `refs/remotes/origin/*` only and could not see the branch
# being created. That is the same defect the charge closed, restored by the shape of
# the fix: a check nested under a precondition orthogonal to it.
#
# It runs in $ROOT and not in a pushed worktree ON PURPOSE: the registry rows that
# matter are the ones in the tree being published, but the REMOTE REF LIST lives in
# this clone. GATE 19 reads both, so it must run where both are readable.
NEWREF_RC=0
if [ -n "$NEWREFS" ]; then
  echo "pre-push: NEW branch ref(s) to declare: $NEWREFS"
  # 🔴 SIBLING SWEEP 2026-09-02 (FINDING_FAILOPEN_CLASS instance 38). This leg is the ONE dispatch
  # in this hook that reads $ROOT's WORKING-TREE doc_gates.sh rather than a pushed sha's committed
  # copy, so it sits squarely in the concurrency window where another unit's half-written script is
  # unparseable. It is BLOCKING either way — the fail direction does not change — but "not declared
  # in the branch registry" is a false statement about a gate that never ran, and it sends the
  # reader to edit a registry that is fine. Classify instead of testing for zero.
  if [ ! -f "$ROOT/scripts/doc_gates.sh" ]; then
    echo "pre-push: BLOCKED — COULD NOT RUN the branch-registry gate (scripts/doc_gates.sh missing)."
    echo "         Nothing was checked. This is not a registry finding."
    NEWREF_RC=1
  elif ! _dgerr=$(bash -n "$ROOT/scripts/doc_gates.sh" 2>&1); then
    echo "pre-push: 🔴 BLOCKED — COULD NOT RUN the branch-registry gate: $ROOT/scripts/doc_gates.sh"
    echo "         does not parse, so GATE 19 never executed and the branch registry was NOT read."
    echo "         ${_dgerr:-bash -n returned non-zero with no message}"
    echo "         DO NOT edit the branch registry in response to this — re-push once 'bash -n' is quiet."
    NEWREF_RC=1
  else
    DOC_GATES_PENDING_BRANCHES="$NEWREFS" bash "$ROOT/scripts/doc_gates.sh" branch-registry; _brc=$?
    case "$_brc" in
      0) echo "pre-push: branch-registry gate PASSED for $NEWREFS" ;;
      1) echo "pre-push: BLOCKED — new branch ref(s) not declared in the branch registry"; NEWREF_RC=1 ;;
      *) echo "pre-push: 🔴 BLOCKED — COULD NOT RUN: the branch-registry gate exited $_brc, which is"
         echo "         neither clean(0) nor findings(1). It aborted after parsing; the registry was"
         echo "         not read. This is not a registry finding."; NEWREF_RC=1 ;;
    esac
  fi
fi

if [ -z "$SHAS" ]; then
  if [ -n "$NEWREFS" ]; then
    echo "pre-push: no new tree; the declaration leg above is the whole verdict"
    exit "$NEWREF_RC"
  fi
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
# Seeded from the declaration leg: an undeclared new branch blocks the push even when
# every pushed tree passes its own gates.
RC=$NEWREF_RC
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
  SHAFAIL_SEEN=${SHAFAIL_SEEN:-0}
  if [ -f "$WT/scripts/doc_gates.sh" ]; then
    ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
        bash scripts/doc_gates.sh all ); _arc=$?
    # Sibling sweep 2026-09-02: same class as the branch-registry leg above. Blocking either way
    # (SHARC=1 in both arms) — what changes is that a pushed tree whose doc_gates.sh does not parse,
    # or which aborted, is no longer reported as a documentation finding it never made.
    if [ "$_arc" -gt 1 ]; then
      echo "pre-push: 🔴 COULD NOT RUN — 'doc_gates.sh all' in pushed sha $short exited $_arc"
      echo "         (neither clean(0) nor findings(1)). NOTHING in that tree was checked; this is"
      echo "         not a documentation finding. bash -n on that tree's copy says:"
      ( cd "$WT" && bash -n scripts/doc_gates.sh 2>&1 | sed 's/^/           /' ) || true
      SHARC=1
    elif [ "$_arc" -ne 0 ]; then SHARC=1; fi
  else
    echo "pre-push: FAIL — pushed sha $short has no scripts/doc_gates.sh."
    echo "  For a current tree that is a regression; for a deliberate push of"
    echo "  pre-gate history, 'git push --no-verify' is the visible bypass."
    SHARC=1
  fi
  # Conditional `generated` leg (see header): only for shas whose pushed range
  # touches roae.py/example/ or has no provable base. Runs the PUSHED TREE's
  # own gate, like the two unconditional legs; a tree whose doc_gates.sh
  # predates the mode exits 2 there and is blocked, same rule as above. The
  # missing-doc_gates.sh case is already a FAIL in the leg above — no second
  # report here.
  case " $GENSHAS " in
    *" $sha "*)
      if [ -f "$WT/scripts/doc_gates.sh" ]; then
        echo
        echo "pre-push: pushed range touches roae.py/example/ (or has no base to diff) —"
        echo "          running its generated-artifact gate (GATE 8, ~67-107 s: 3 roae.py runs)"
        ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
            bash scripts/doc_gates.sh generated ); _grc=$?
        if [ "$_grc" -gt 1 ]; then
          echo "pre-push: 🔴 COULD NOT RUN — 'doc_gates.sh generated' in pushed sha $short exited"
          echo "         $_grc (neither clean(0) nor findings(1)). No artifact comparison completed;"
          echo "         do NOT regenerate example/ in response to this."
          SHARC=1
        elif [ "$_grc" -ne 0 ]; then SHARC=1; fi
      fi ;;
  esac
  echo
  if [ -f "$WT/scripts/pre_push_compile_gate.sh" ]; then
    ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
        bash scripts/pre_push_compile_gate.sh ) || SHARC=1
    # ---- CONDITIONAL #167 zero-yield resume leg (2026-09-05, PROSE_LANE_FOLLOWUPS row 542).
    # Runs ONLY when the pushed range touches solve.c. `--selftest-resume` — the standing
    # acceptance test for the resume path — is BLIND to this defect in BOTH directions: the fixed
    # and pre-fix binaries pass it byte-identically, because the guard's stderr is deleted with the
    # tempdirs and the sha comparator measures output while the fix changes WORK. So the resume
    # path had an acceptance test that could not fail on it, and this gate is the one that can.
    # It had ZERO INVOKERS until this leg existed; a gate nothing runs is not a gate, which is
    # this project's dominant failure class and precisely what row 542 exists to close.
    # COST is why it is conditional, not unconditional: measured 188 s on the 2-core orchestrator
    # (~32 s at 4 threads on a VM) because it runs real enumerations. Unconditional, that is the
    # slow-hook-gets-bypassed failure the `generated` leg's header already argues against, and
    # markdown-only pushes — most pushes — cannot touch the resume path at all.
    case " $R167SHAS " in
      *" $sha "*)
        if [ -f "$WT/scripts/selftest_resume_167_gate.sh" ]; then
          echo
          echo "pre-push: pushed range touches solve.c — running the #167 zero-yield resume gate"
          echo "          (~32 s on a VM, ~188 s on the 2-core orchestrator: real enumerations)"
          _r167=0
          ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE bash -c '
              gcc -O2 -pthread -fopenmp -o ./solve_167 solve.c -lm -lz 2>/dev/null || exit 44
              bash scripts/selftest_resume_167_gate.sh --solve ./solve_167' ); _r167=$?
          if [ "$_r167" -eq 44 ]; then
            echo "pre-push: 🔴 COULD NOT RUN — solve.c in pushed sha $short did not build for the"
            echo "         #167 gate. The compile gate above is the authority on WHY; this leg"
            echo "         reports only that it could not check, which is not a pass."
            SHARC=1
          elif [ "$_r167" -ne 0 ]; then
            echo "pre-push: FAIL — #167 zero-yield resume gate rc=$_r167 on pushed sha $short."
            SHARC=1
          fi
        else
          echo "pre-push: FAIL — pushed sha $short touches solve.c but has no"
          echo "  scripts/selftest_resume_167_gate.sh. Deleting the gate that covers the resume"
          echo "  path is the regression it exists to prevent; --no-verify is the visible bypass."
          SHARC=1
        fi ;;
    esac
  else
    echo "pre-push: FAIL — pushed sha $short has no scripts/pre_push_compile_gate.sh."
    echo "  Same rule as above: blocked, and --no-verify is the visible bypass."
    SHARC=1
  fi

  cleanup
  if [ "$SHARC" -ne 0 ]; then
    RC=1; SHAFAIL_SEEN=1
    echo "pre-push: pushed sha $short FAILED its gates ($((SECONDS - t0)) s)"
  else
    echo "pre-push: pushed sha $short passed both gates ($((SECONDS - t0)) s)"
  fi
done

if [ "$RC" -ne 0 ]; then
  echo
  if [ "$NEWREF_RC" -ne 0 ]; then
    echo "pre-push: BLOCKED — a NEW branch ref is not declared in documentation/BRANCH_REGISTRY.tsv."
    echo "  Declare it (authoritative or snapshot) before publishing the name; an"
    echo "  undeclared public branch is the CX-30-on-five-refs failure mode."
  fi
  if [ "${SHAFAIL_SEEN:-0}" -ne 0 ]; then
    echo "pre-push: BLOCKED — at least one pushed sha failed its gates above."
    echo "  The gates ran against the COMMITTED trees being published, not the"
    echo "  working tree: a fix that exists only as an uncommitted edit does not"
    echo "  clear this — commit it."
  fi
  echo "  'git push --no-verify' bypasses this and leaves that visible in shell history."
fi

# ---- ADVISORY: pre-codex review-loop state (NEVER blocking) ---------------
# WHY. The review loop kept stopping — not because it was finished, but because
# nothing surfaced that it wasn't. Its state lived in a model's context and then
# in a file nobody read. This prints the open-item count on every push so the
# loop's true state is visible at the moment work is published.
#
# ADVISORY BY DESIGN, and that is a deliberate choice, not laziness: blocking on
# an open review queue would penalise the OPERATOR for the reviewer's backlog and
# create pressure to close items in order to push — precisely the incentive the
# queue's close-rule (a gate, or a named accepted risk — never prose) exists to
# prevent. It never touches $RC.
#
# The queue is operator-side (roae-private) and NOT part of this repo, so this
# leg stays silent when absent: a fresh clone, a third-party replicator, and CI
# all see nothing. Host-agnostic; no network; costs one file read.
RLQ="${ROAE_REVIEW_QUEUE:-$ROOT/../../roae-private/scripts/review_loop.sh}"
if [ -x "$RLQ" ]; then
  RL_OUT=$(bash "$RLQ" 2>/dev/null | grep -E '^  items:|^  NEXT:' || true)
  if [ -n "$RL_OUT" ]; then
    echo
    echo "pre-push: [advisory] pre-codex review loop — NOT blocking this push:"
    echo "$RL_OUT" | sed 's/^/    /'
  fi
fi

exit $RC
