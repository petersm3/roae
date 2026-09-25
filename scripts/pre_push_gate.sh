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
#   - NEW remote branch (remote sha all zeros): gated like any update. The
#     content gates need only the sha being published; the range-scoped legs
#     (the conditional ones, and the citation gate's shift leg) fall back as
#     described at each of them.
#   - duplicate shas across refs are gated once.
#   The REMOTE sha is the base of the pushed range: what this push publishes
#   OVER. Every range-scoped leg diffs against it (Q-792: including the
#   citation gate's leg A, see "THE CITATION GATE'S SHIFT LEG NEEDS A BASE").
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
#      Run with CITGATE_BASE set to the pushed range's base (Q-792, below).
#   1b. scripts/doc_gates.sh generated    — CONDITIONAL, blocking when it runs;
#      see "THE `generated` LEG IS CONDITIONAL" below for when and why.
#   2. scripts/pre_push_compile_gate.sh   — solve.c compile + --selftest sha.
#   2b. scripts/gate_published_consistency.sh — RATCHET over three published-consistency classes.
#      Blocks only when a count RISES above scripts/gate_published_consistency.pin; the token
#      PASS-AT-PIN (no regression, known-open items stand) is accepted.
#   ADVISORY legs (never blocking) also run per pushed sha in its worktree -- the
#      reproduction stamp + skip pin (Q-601/Q-477) and the row-assertion sweep --
#      and every verdict is read through one_token(): exactly one KEY= line (Q-523).
#   ADVISORY, once per push: doc_gates.sh --selftest on the last pushed sha whose range
#      touches scripts/, in a FRESH standalone clone of its own (Q-720). PASS only on the one
#      whole-line token DOC_GATES_SELFTEST=PASS; a refusal or missing graphviz is NOT-RUN.
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

# ---- EXACTLY-ONE verdict reader (Q-523, 2026-09-24) -------------------------
# Every verdict this hook consumes is read through here. The reads it replaced were
# `grep -E "^KEY=" | tail -1`: key-named, so a FOO=FAIL can never satisfy a BAR= read,
# but POSITIONAL, so a producer that emits its own key twice (FAIL, then PASS) was
# silently judged by the LATER line. Every producer is single-emission today by
# construction and nothing asserted it; Q-516 was a script in this repo family that grew
# a second emission of its own key. So: count the key, accept exactly one, and refuse --
# never pick -- on zero or many. Zero is not agreement: a gate that measured nothing is
# not a gate that passed.
#   $1 = verdict KEY   $2 = the producer's captured output
#   rc 0 -> TOK holds the one whole line.  rc 1 -> TOK is empty, and the DIAGNOSIS is
#   printed as one fixed-form line naming the key and the count, so a test can assert
#   WHY the read refused and not merely that it did (the Q-517 lesson: an exactly-one
#   branch once survived its mutant because the refusal happened for another reason).
#   It is deliberately NOT a KEY=value token: doc_gates GATE 89 requires every emitted
#   token to be documented, and this diagnosis is a log line, not a published verdict.
# Call it directly, never inside $(...): it sets TOK in this shell and prints the diagnosis.
one_token() {
  local key=$1 out=$2 n
  TOK=""
  n=$(printf '%s\n' "$out" | grep -cE "^${key}=") || true
  if [ "${n:-0}" = 1 ]; then
    TOK=$(printf '%s\n' "$out" | grep -E "^${key}=")
    return 0
  fi
  echo "    [verdict-count] ${key}= emitted ${n:-0} time(s); exactly 1 required -- none believed"
  return 1
}
# Whole-line comparison of the one line one_token accepted: grep -qx, never a substring
# or prefix test ("PASS" is a prefix of "PASS-AT-PIN").
tok_is() { printf '%s\n' "$TOK" | grep -qxF -- "$1"; }

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

# ---- does this pushed sha need the fail-open closure sweep? ----------------
# $1 = pushed sha, $2 = remote sha ('' or all-zeros when there is no base).
# Returns 0 (leg required) when anything under scripts/ differs between base
# and pushed sha, and on every path where that cannot be established — the
# same fail-closed rule as the two above. The pathspec is the gate's SUBJECT:
# scripts/failopen_closure_gate.sh executes every token-emitting script in the
# tree with all inputs absent, so a NEW fail-open can only enter the published
# record through a scripts/ change. A markdown-only push cannot create one and
# pays nothing (measured 61 s when it does run — see the advisory leg below).
needs_scripts() {
  local base="$2" changed
  [ -n "$base" ] && [ "$base" != "$Z40" ] || return 0
  git cat-file -e "$base^{commit}" 2>/dev/null || return 0
  changed=$(git diff --name-only "$base" "$1" -- scripts/ 2>/dev/null) || return 0
  [ -n "$changed" ]
}

# ---- THE CITATION GATE'S SHIFT LEG NEEDS A BASE (Q-792, 2026-09-25) ---------
# `doc_gates.sh all` runs `citation_line_gate.sh --all-files`, whose LEG A turns
# `git diff -U0 BASE -- solve.c` into an old->new line map and FAILs every
# `solve.c:N` citation that the change left byte-identical while N moved. BASE is
# `--base REF`, else $CITGATE_BASE, else HEAD. This hook runs the gate in a
# detached worktree of the PUSHED sha, where HEAD IS the pushed sha: with no
# CITGATE_BASE the diff is empty and leg A measures nothing — at the one point
# where a commit that moved solve.c under an unmoved citation is about to be
# published. Found by Opus XX the day --all-files landed; only leg B (anchors)
# ran at pre-push, and leg B cannot see a citation whose line names no symbol.
#   So each pushed sha gets the commit it is published OVER:
#     - the REMOTE sha, when it is non-zero and present locally (an ordinary
#       update, fast-forward or forced: either way it is what the remote holds);
#     - otherwise (a NEW branch, or a remote tip this clone has not fetched) the
#       NEAREST merge-base of the pushed sha with any refs/remotes/origin/* ref,
#       i.e. the published commit the new history forks from. Nearest = fewest
#       commits to the pushed sha, so the range is the new history, not more;
#     - otherwise nothing. There is no base to prove, so leg A stays vacuous and
#       the hook SAYS SO on every such push, loudly and by sha. It does not block:
#       the missing base is a property of the remote, not a defect in the tree,
#       and leg B still runs. (The fail-closed rule of needs_*() above has no
#       analogue here: they fail closed by RUNNING a leg, and there is no base to
#       run this one against.)
# Sets CB_SHA (full sha or "") and CB_HOW (how it was chosen, for the log).
# $1 = pushed sha (peeled to a commit), $2 = remote sha ('' or all-zeros).
citgate_base() {
  local lsha="$1" rsha="${2:-}" r mb n bestn="" pre=""
  CB_SHA=""; CB_HOW=""
  case "$rsha" in ''|*[!0]*) ;; *) rsha="" ;; esac
  if [ -n "$rsha" ]; then
    if mb=$(git rev-parse -q --verify "${rsha}^{commit}" 2>/dev/null) && [ -n "$mb" ]; then
      CB_SHA=$mb; CB_HOW="the remote tip being pushed over"; return 0
    fi
    pre="remote tip ${rsha:0:12} is not in this clone (fetch?); "
  fi
  for r in $(git for-each-ref --format='%(refname)' refs/remotes/origin/ 2>/dev/null); do
    mb=$(git merge-base "$lsha" "$r" 2>/dev/null) || continue
    [ -n "$mb" ] || continue
    n=$(git rev-list --count "$mb..$lsha" 2>/dev/null) || continue
    if [ -z "$bestn" ] || [ "$n" -lt "$bestn" ]; then
      CB_SHA=$mb; bestn=$n; CB_HOW="${pre}merge-base with ${r#refs/remotes/}, $n commit(s) back"
    fi
  done
  [ -n "$CB_SHA" ] || CB_HOW="${pre}no remote tip and no merge-base with any origin ref"
  return 0
}
# CITBASE[sha] / CITHOW[sha]: one base per pushed sha. A sha pushed via two refs with
# different bases gets the merge-base of the two, so the range covers both.
declare -A CITBASE=() CITHOW=()
note_citbase() {  # $1 pushed sha, $2 remote sha
  local prev mb
  citgate_base "$1" "${2:-}"
  [ -n "$CB_SHA" ] || { [ -n "${CITHOW[$1]:-}" ] || CITHOW[$1]=$CB_HOW; return 0; }
  prev=${CITBASE[$1]:-}
  if [ -z "$prev" ]; then
    CITBASE[$1]=$CB_SHA; CITHOW[$1]=$CB_HOW
  elif [ "$prev" != "$CB_SHA" ] && mb=$(git merge-base "$prev" "$CB_SHA" 2>/dev/null) && [ -n "$mb" ]; then
    CITBASE[$1]=$mb; CITHOW[$1]="merge-base of the bases of the refs publishing this sha"
  fi
}

# ---- collect the shas being published -------------------------------------
# GENSHAS ⊆ SHAS: the pushed shas whose range touches the generated-artifact
# surface (or has no provable base). A sha pushed via two refs needs the leg
# if EITHER ref's range does.
SHAS=""
GENSHAS=""
R167SHAS=""
SCRIPTSHAS=""
NEWREFS=""
if [ -t 0 ]; then
  SHAS=$(git rev-parse HEAD) || exit 1
  echo "pre-push: direct invocation (no ref list on stdin) — gating HEAD ${SHAS:0:12}"
  # A plain `git push` publishes HEAD onto its upstream; diff against that
  # when it exists, otherwise fail-closed into the leg.
  UPSTREAM=$(git rev-parse '@{u}' 2>/dev/null || true)
  if needs_generated "$SHAS" "$UPSTREAM"; then GENSHAS=$SHAS; fi
  if needs_resume167 "$SHAS" "$UPSTREAM"; then R167SHAS=$SHAS; fi
  if needs_scripts   "$SHAS" "$UPSTREAM"; then SCRIPTSHAS=$SHAS; fi
  note_citbase "$SHAS" "$UPSTREAM"
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
    note_citbase "$lsha" "${rsha:-}"      # Q-792: the citation gate's leg A base
    if needs_resume167 "$lsha" "${rsha:-}"; then
      case " $R167SHAS " in *" $lsha "*) ;; *) R167SHAS="$R167SHAS $lsha";; esac
    fi
    if needs_scripts "$lsha" "${rsha:-}"; then
      case " $SCRIPTSHAS " in *" $lsha "*) ;; *) SCRIPTSHAS="$SCRIPTSHAS $lsha";; esac
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
SCRIPTSHAS=${SCRIPTSHAS# }
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
STBASE=""   # the Q-720 selftest leg's own clone (see its header below)
cleanup() {
  if [ -n "$WTBASE" ]; then
    git -C "$ROOT" worktree remove --force "$WTBASE/tree" >/dev/null 2>&1
    rm -rf "$WTBASE"
    git -C "$ROOT" worktree prune >/dev/null 2>&1
    WTBASE=""
  fi
  if [ -n "$STBASE" ]; then   # a standalone --shared clone, not a worktree: rm is the whole job
    rm -rf "$STBASE"
    STBASE=""
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
    # Q-792: leg A of the citation gate diffs solve.c against the pushed range's base. An
    # inherited CITGATE_BASE is dropped first, so the operator's shell cannot choose the base.
    _cb=${CITBASE[$sha]:-}
    if [ -n "$_cb" ]; then
      echo "pre-push: citation gate leg A (shift) base for $short = ${_cb:0:12} (${CITHOW[$sha]:-?})"
    else
      echo "pre-push: ⚠ citation gate leg A (shift) has NO BASE for $short — ${CITHOW[$sha]:-no base recorded}."
      echo "          Leg A is VACUOUS on this push (it diffs the pushed sha against itself); leg B"
      echo "          (anchors) still runs. Not blocking: see citgate_base() for why."
    fi
    ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u CITGATE_BASE \
        ${_cb:+CITGATE_BASE=$_cb} bash scripts/doc_gates.sh all ); _arc=$?
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

      # ---- published-consistency ratchet (2026-09-06). THIS GATE HAD ZERO INVOKERS.
      # scripts/gate_published_consistency.sh was written to close the three classes that dominated
      # v3 lens B's surviving yield, then wired into nothing -- `grep -rn` found only the file
      # itself. It is the same defect it exists to catch, and the same one that left _MANIFEST.txt
      # stale for two commits: an artifact generated and never consumed is not a safeguard.
      #
      # It is a RATCHET, not a pass mark. 15 defects stand today, each with a written reason in
      # scripts/gate_published_consistency.pin; this blocks only when a count RISES. PASS-AT-PIN
      # means no regression with known-open items and is deliberately ACCEPTED -- treating it as a
      # failure would make every push noisy and the gate would be bypassed within a week.
      if [ -f "$WT/scripts/gate_published_consistency.sh" ]; then
        _gpc=$( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
                  bash scripts/gate_published_consistency.sh 2>&1 )
        # grep -qx, never a substring test: "PASS" is a prefix of "PASS-AT-PIN".
        # Q-523 sibling sweep: exactly one emission first. Before, a FAIL anywhere in the
        # output won (fail-closed), but FAIL-free duplicates -- PASS-AT-PIN then PASS --
        # certified whichever branch was tested first. Zero or many now block.
        if ! one_token PUBLISHED_CONSISTENCY "$_gpc"; then
          echo "pre-push: COULD NOT RUN the published-consistency gate (no single verdict token)."
          echo "         A gate that cannot report is not a gate that passed."
          SHARC=1
        elif tok_is 'PUBLISHED_CONSISTENCY=FAIL'; then
          echo "pre-push: published-consistency RATCHET BROKEN -- a count rose above its pin:"
          printf '%s\n' "$_gpc" | grep -E 'rose to|no pin file|malformed' | sed 's/^/         /'
          echo "         Fix it, or re-pin in this same commit with the reason written down."
          SHARC=1
        elif tok_is 'PUBLISHED_CONSISTENCY=PASS-AT-PIN'; then
          echo "pre-push: published consistency at pin (no regression; known-open items stand)"
          # Echo WHICH legs stand. "at pin" alone reads as "fine"; the gate knows the list, so the
          # push log should carry it rather than making the lane re-run the gate to find out.
          printf '%s\n' "$_gpc" | grep -E '^  OUTSTANDING:' | sed 's/^/         /'
        elif tok_is 'PUBLISHED_CONSISTENCY=PASS'; then
          echo "pre-push: published consistency CLEAN -- all 19 legs measured zero;"
          echo "         tighten any non-zero pin to 0 in this commit (repaired-defect budget is headroom)"
        else
          echo "pre-push: COULD NOT RUN the published-consistency gate (unrecognised verdict '$TOK')."
          echo "         A gate that cannot report is not a gate that passed."
          SHARC=1
        fi
      fi
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
              bash scripts/selftest_resume_167_gate.sh --solve ./solve_167 || exit $?
              # \U0001f534 The marker leg of --disk-precheck printed "present: PASS" for a bare
              # stat() under a comment claiming it "proves the mount holds the canonical
              # disk contents". A zero-byte file satisfied it. Identity is safety-critical here
              # (a solver-data disk was destroyed by a wrong-disk operation on 2026-05-06), so a
              # leg that READS as an attestation while performing none is the wrong thing to
              # ship. Reuses ./solve_167 -- the mutants are rebuilt inside the gate, because a
              # handed-in binary cannot carry a mutation. ~33 s on top of the #167 leg.
              DISK_PRECHECK_SOLVE=./solve_167 bash scripts/disk_precheck_marker_gate.sh || exit 45' ); _r167=$?
          if [ "$_r167" -eq 44 ]; then
            echo "pre-push: 🔴 COULD NOT RUN — solve.c in pushed sha $short did not build for the"
            echo "         #167 gate. The compile gate above is the authority on WHY; this leg"
            echo "         reports only that it could not check, which is not a pass."
            SHARC=1
          elif [ "$_r167" -eq 45 ]; then
            echo "pre-push: FAIL — scripts/disk_precheck_marker_gate.sh did not PASS on pushed sha"
            echo "         $short: the --disk-precheck marker leg no longer reports its content, or"
            echo "         a mutant that merely REWORDED the output without testing it survived."
            SHARC=1
          elif [ "$_r167" -ne 0 ]; then
            echo "pre-push: FAIL — #167 zero-yield resume gate rc=$_r167 on pushed sha $short."
            SHARC=1
          fi
          # ---- Q-731 (2026-09-24): the DISCRIMINATOR legs, --mutant M3 and --mutant M4. BLOCKING.
          # The M0 run above is BLIND to the one property the #167 fix adds. In a clean PHASE_A
          # every shard-less sidecar is attested-zero, so a binary whose guard DROPS the flag
          # term (`&& ts->dfs_resume_yield_attested`) resumes exactly the same cells and prints
          # the same R=Z, D=0, sha and EXCESS as the correct one. MEASURED by Fable N
          # (discriminator attack, mutant A11; transcript off-tree): that mutant PASSes M0 byte for
          # byte; only an M3-shaped input separates it. So each leg below hands the fixed binary
          # a sidecar it MUST refuse, and REQUIRES the refusal:
          #   M3  attestation flag CLEARED on one zero-yield sidecar -> kills a flag-ignoring guard
          #   M4  flag set, prior_solutions_found=5 (attested LOSS)  -> kills a count-ignoring guard
          # PASS is the defect here: it means the binary resumed a cell it had no right to trust.
          # Required = the battery's own kill criterion for M3/M4, read token by token:
          #   SELFTEST_RESUME_167=FAIL, RESUME_167_DISCARDED=1, RESUMED = ZERO_YIELD_CELLS-1, rc 40.
          # Single-run mutants need NO pre-fix baseline (only M1 does), which is why pre-push can
          # run these two and not --battery. COST: two more gate runs, ~1 min at 4 threads on a
          # VM, ~2 x 188 s on the 2-core orchestrator; solve.c pushes only, like the leg above.
          # --workdir is placed under $WTBASE (beside the tree, not in it) because an expected
          # FAIL makes the gate KEEP its evidence dirs; cleanup() removes them with $WTBASE.
          if [ "$_r167" -ne 44 ] && [ -x "$WT/solve_167" ]; then
            for _m in M3 M4; do
              _mo=$( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
                       bash scripts/selftest_resume_167_gate.sh --solve ./solve_167 \
                         --mutant "$_m" --workdir "$WTBASE/r167_$_m" 2>&1 ); _mrc=$?
              _mv=""; _md=""; _mr=""; _mz=""
              one_token SELFTEST_RESUME_167        "$_mo" && _mv=${TOK#*=}
              one_token RESUME_167_DISCARDED       "$_mo" && _md=${TOK#*=}
              one_token RESUME_167_RESUMED         "$_mo" && _mr=${TOK#*=}
              one_token RESUME_167_ZERO_YIELD_CELLS "$_mo" && _mz=${TOK#*=}
              case "$_m" in
                M3) _mwhat="a sidecar whose attestation flag was CLEARED (the guard ignores the flag)" ;;
                M4) _mwhat="a sidecar attesting 5 LOST solutions (the guard ignores the count)" ;;
              esac
              # Counts are checked for digits BEFORE any arithmetic: $(( )) on a malformed token
              # is an expansion error, not a false test.
              _mnum=0
              case "$_mr$_mz" in ''|*[!0-9]*) ;; *) [ -n "$_mr" ] && [ -n "$_mz" ] && _mnum=1 ;; esac
              if [ "$_mrc" -eq 40 ] && [ "$_mv" = FAIL ] && [ "$_md" = 1 ] \
                 && [ "$_mnum" = 1 ] && [ "$_mr" -eq $(( _mz - 1 )) ]; then
                echo "pre-push: #167 --mutant $_m OK — the binary REFUSED $_m's sidecar"
                echo "          (SELFTEST_RESUME_167=FAIL, D=1, R=$_mr=Z-1 of Z=$_mz: the expected verdict)"
              elif [ "$_mv" = PASS ]; then
                echo "pre-push: 🔴 FAIL — #167 --mutant $_m: the solve.c in pushed sha $short RESUMED"
                echo "         $_mwhat."
                echo "         SELFTEST_RESUME_167=PASS on a mutant that MUST fail means the discriminator is gone."
                echo "         Reproduce: scripts/selftest_resume_167_gate.sh --solve ./solve --mutant $_m"
                SHARC=1
              else
                echo "pre-push: FAIL — #167 --mutant $_m on pushed sha $short did not reach the required"
                echo "         refusal (rc=$_mrc, SELFTEST_RESUME_167=${_mv:-<none>}, D=${_md:-<none>},"
                echo "         R=${_mr:-<none>}, Z=${_mz:-<none>}; required rc 40, FAIL, D=1, R=Z-1)."
                echo "         ERROR/VACUOUS is not a refusal: nothing was shown to be discarded."
                printf '%s\n' "$_mo" | grep -E '^\[gate\] (ERROR|FAIL|VACUOUS)' | head -3 | sed 's/^/           /'
                SHARC=1
              fi
            done
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

  # ---- ADVISORY: the Q-479 solve.c battery (2026-09-11) --------------------
  # WHY THIS EXISTS. Four gates in this repository had NO INVOKER: nothing ran
  # them, so at run time each was indistinguishable from a gate that does not
  # exist -- this project's dominant defect class. They all need one thing the
  # periodic ticks cannot supply: a solve binary built from the source they are
  # asserting about. This leg supplies exactly that, once, and hands the same
  # binary to all four.
  #
  # THE BUILD CARRIES -DSOURCE_SHA AND THAT IS LOAD-BEARING, NOT DECORATION.
  # f1c5_adopt_digest_gate.sh compares the binary's embedded SOURCE_SHA against
  # sha256(solve.c) and reports ERROR (rc 40) when they differ -- its guard
  # against a stale ./solve reproducing the very failure signature it looks for.
  # A build without -DSOURCE_SHA leaves it "unknown", so wiring this gate into a
  # runner that omits the define would make it report ERROR FOR EVER: a gate
  # that cannot be satisfied, which is worse than an unwired one because it also
  # produces noise. MEASURED 2026-09-11 on the 2-core orchestrator with this
  # exact build line: F1C5_ADOPT_DIGEST_GATE=PASS, all five legs, 6.7 s.
  #
  # ADVISORY, NEVER BLOCKING -- and the reason is per-gate, not blanket:
  #   * q317_missing_shard_merge_gate.sh is EXPECTED RED. Its own banner says so:
  #     Q-317 item (4) is not landed, "do not add it to any blocking hook until
  #     solve.c is fixed". MEASURED today: MISSING_SHARD_MERGE=FAIL in 103 s,
  #     which is the gate WORKING. Blocking on it would stop every solve.c push.
  #   * the other three are GREEN today (measured below), but they judge the
  #     PUSHED tree, and a solve.c commit mid-way through a multi-commit fix can
  #     legitimately be red. The blocking coverage of solve.c on this path is the
  #     compile gate and the #167 leg above; this battery adds verdicts to the
  #     push record without adding anything to the blocking set.
  #
  # CONDITIONAL on the pushed range touching solve.c, for the same reason the
  # #167 leg is: every one of the four asserts something about solve.c, so a
  # markdown-only push cannot change any of their answers -- and the ONE push
  # that can turn q317 green is by construction a solve.c push.
  #
  # COST, measured 2026-09-11 on the 2-core orchestrator, and only on a solve.c
  # push: build 27 s + f1c5 6.7 s + resume-budget 23 s + q317 103 s + scale 0.3 s
  # = ~160 s, alongside the ~221 s the #167 leg already costs on the same shas.
  case " $R167SHAS " in
    *" $sha "*)
      if [ -f "$WT/solve.c" ]; then
        echo
        echo "pre-push: [advisory] Q-479 solve.c battery on pushed sha $short — NEVER blocking (~160 s)"
        _q479_src=$(sha256sum "$WT/solve.c" 2>/dev/null | cut -d' ' -f1)
        _q479_bin="$WT/solve_q479"
        if ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
               gcc -O2 -pthread -fopenmp -DSOURCE_SHA="\"$_q479_src\"" \
                   -o solve_q479 solve.c -lm -lz ) >/dev/null 2>&1; then
          # Report a gate by its OWN whole-line KEY=value token, never by output
          # shape or exit code: an absent token is [ERROR], not a pass.
          _q479_leg() {  # $1 label, $2 verdict key, $3.. the command
            local lbl=$1 key=$2; shift 2
            local out
            out=$( "$@" 2>&1 )
            # Q-523: exactly one ${key}= line, or [ERROR] -- never the positional last one.
            if ! one_token "$key" "$out"; then
              echo "    [ERROR]    $lbl — no single ${key}= verdict line (diagnosis above)."
              echo "               A gate that cannot report is not a gate that passed."
            elif tok_is "$key=PASS" || tok_is "$key=OK"; then
              echo "    [ok]       $lbl — $TOK"
            else
              echo "    [advisory] $lbl — $TOK"
              printf '%s\n' "$out" | grep -E '^ *\[(FAIL|ERROR)' | head -4 | sed 's/^/               /'
            fi
          }
          _q479_leg "f1c5 finalized-layer ADOPT compares its digest" F1C5_ADOPT_DIGEST_GATE \
                    bash "$WT/scripts/f1c5_adopt_digest_gate.sh" "$_q479_bin"
          _q479_leg "an uncapped resume must not inherit budget-truncated cells" RESUME_BUDGET_INFINITY \
                    env BIN="$_q479_bin" bash "$WT/scripts/resume_budget_infinity_gate.sh"
          _q479_leg "an absent shard must not pass the merge (Q-317 (4) — EXPECTED RED until the fix lands)" MISSING_SHARD_MERGE \
                    env BIN="$_q479_bin" bash "$WT/scripts/q317_missing_shard_merge_gate.sh"
          # The scale gate is an OPERATOR-SIDE artifact (roae-private) whose
          # subject is PUBLIC: the CANONICAL_RECIPES table inside solve.c. It is
          # handed ROAE_DIR=$WT so it parses the PUSHED table, and SOLVE_BIN so
          # it reuses the build above instead of compiling solve.c a second time
          # (~40 s saved; its header says it must not go in a periodic tick for
          # exactly that reason). Silent when absent, like the review-loop leg
          # below: a fresh clone, a third-party replicator and CI see nothing.
          if [ -x "$ROOT/../../roae-private/scripts/canonical_scale_distinguishable_gate.sh" ]; then
            _q479_leg "every CANONICAL_RECIPES label is distinguishable from a typo" SCALE_DISTINGUISHABLE \
                      env ROAE_DIR="$WT" SOLVE_BIN="$_q479_bin" \
                      bash "$ROOT/../../roae-private/scripts/canonical_scale_distinguishable_gate.sh"
          fi
          rm -f "$_q479_bin"
        else
          echo "    [ERROR]    pushed sha $short did not build with -DSOURCE_SHA — the battery"
          echo "               measured NOTHING. The compile gate above is the authority on why."
        fi
      fi ;;
  esac

  # ---- ADVISORY: fail-open closure sweep (Q-479, 2026-09-11) ---------------
  # scripts/failopen_closure_gate.sh is the META-GATE for the fail-open class:
  # it copies every token-emitting script into an EMPTY skeleton and executes it
  # there, and any script that still prints an OK-class token or exits 0 has a
  # PASS consistent with its target being absent. It had no invoker.
  #
  # THE RUNNER QUESTION WAS DECIDED BY MEASURING IT, not by estimating. The
  # 2026-09-11 triage left this one UNKNOWN and refused to guess, on the reading
  # that ~118 scripts at a default --timeout 60 EACH could cost tens of minutes.
  # MEASURED on the 2-core orchestrator that same day, against this tree:
  #     population 45 · run 38 · unrun 7 · allowlisted 1 · OPEN 0 · RC0 0
  #     FAILOPEN_CLOSURE=OK        61.2 s wall / 60.1 s CPU
  # The estimate was wrong by an order of magnitude, and for a structural reason
  # worth recording: a gate that fails-CLOSED exits in milliseconds in an empty
  # world, so the only script that costs its full timeout is the one already
  # allowlisted as `timeout` (c2c3_joint_null.py, a Monte-Carlo with no tree
  # input) — ~60 of those 61 seconds are that single script waiting out its
  # clock. So this does NOT need its own scheduled slot; 61 s sits inside the
  # ~70-90 s this hook already costs per pushed sha.
  #
  # CONDITIONAL on the pushed range touching scripts/ — its exact subject. A new
  # fail-open reaches the public record only through a scripts/ change, and the
  # common markdown-only push pays one `git diff --name-only`.
  #
  # It runs the PUSHED TREE'S OWN copy against the PUSHED TREE, so both the rule
  # and the allowlist judged are the ones being published (the same semantics
  # the blocking legs above use, and the reason this leg sits here rather than
  # beside the advisory legs at the foot of this file, which run in $ROOT).
  #
  # ADVISORY: it EXECUTES 38 third-party-shaped scripts, so a single flaky one
  # would block an unrelated push, and its FAIL direction is a finding about the
  # tree's gates rather than about the tree's content. It is loud, it names the
  # offenders, and it never touches $RC. MEASURED GREEN today, so the option of
  # promoting it to blocking is open once it has a green history behind it.
  case " $SCRIPTSHAS " in
    *" $sha "*)
      if [ -x "$WT/scripts/failopen_closure_gate.sh" ]; then
        echo
        echo "pre-push: [advisory] fail-open closure sweep on pushed sha $short — NEVER blocking (~61 s)"
        _fo_out=$( bash "$WT/scripts/failopen_closure_gate.sh" 2>&1 )
        # Q-523: exactly one FAILOPEN_CLOSURE= line, or the *) arm below -- never the last one.
        one_token FAILOPEN_CLOSURE "$_fo_out"; _fo=$TOK
        case "$_fo" in
          FAILOPEN_CLOSURE=OK)
            echo "    [ok]       every runnable gate in the pushed tree refuses an empty world"
            printf '%s\n' "$_fo_out" | grep -E '^FAILOPEN_CLOSURE_(POP|RUN|OPEN|RC0|ALLOWED|UNRUN)=' | sed 's/^/               /' ;;
          FAILOPEN_CLOSURE=FAIL)
            echo "    ⚠ $_fo — a gate in the pushed tree reports success from an EMPTY WORLD."
            printf '%s\n' "$_fo_out" | grep -E '^ *\[(OPEN|RC0|FAIL)' | head -6 | sed 's/^/               /'
            echo "               ADVISORY: the push continues. Reproduce with:"
            echo "                 ./scripts/failopen_closure_gate.sh" ;;
          FAILOPEN_CLOSURE=ERROR)
            echo "    ⚠ $_fo — the sweep could not grade the tree; that is not a pass."
            printf '%s\n' "$_fo_out" | grep -E '^FAILOPEN_CLOSURE_ERROR=|^ *\[ERROR' | head -4 | sed 's/^/               /' ;;
          *)
            echo "    [ERROR]    fail-open sweep emitted no FAILOPEN_CLOSURE= verdict line (got '${_fo:-<nothing>}')"
            echo "               — not the same as OK." ;;
        esac
      fi ;;
  esac

  # ---- ADVISORY: THE REPRODUCTION STAMP OF THE PUSHED SHA (Q-601, Q-477) ------
  # Added 2026-09-10 (Q-477) because NOTHING ON THE PUSH PATH CHECKED IT, and that single
  # gap produced two defects in one commit: a stamp that did not fingerprint the tree it
  # shipped in, and two pinned skip rows that drifted with nothing noticing. Measured then:
  #     grep -c tr12_repro_gate  scripts/pre_push_gate.sh  .git/hooks/pre-push   ->  0  0
  # The reproduction gate was correct, ran on a cron canary, was RED for ~42 h, and nothing
  # that could stop a push ever asked it. The pre-gate leg B-1 consumes it for the KC launch;
  # this consumes it for every push. --check cost 0.42 s measured (2026-09-10, 2-core box).
  #
  # 🔴 Q-601 (moved here 2026-09-24). The 2026-09-10 leg asked the right question -- "does
  # the recorded stamp fingerprint THE TREE BEING PUSHED?" -- and then answered it about
  # $ROOT, the DEVELOPER'S working tree, at the foot of this file. MEASURED 2026-09-19 on
  # public bec69b7a: the committed stamp carried e697f2bb..., a clean checkout of that sha
  # fingerprinted to bf785e83..., so every fresh clone read TR12_REPRO_GATE_CURRENT=NO while
  # every local check read YES -- the corrected stamp existed only as an UNCOMMITTED edit.
  # The two halves of this hook disagreed in exactly the case the stamp exists to catch, and
  # the half that was wrong was the half that got published. So it runs HERE, in the pushed
  # sha's own detached worktree, with that tree's own gate, like every content leg above.
  # The fingerprint is filesystem-based (tr12_repro_gate.sh fingerprint()), and a fresh
  # worktree holds only committed bytes, so an untracked or modified file in $ROOT can no
  # longer vouch for a tree nobody published.
  #
  # ADVISORY, NOT BLOCKING -- AND THAT CHOICE IS THE OPERATOR'S, NOT THIS HOOK'S (Q-477 (a)).
  # The case for advisory: a stale stamp means "this tree has not been shown to reproduce",
  # a fact about EVIDENCE rather than a broken tree, and a docs-only push should not be held
  # hostage to a ~2-minute battery re-run (a re-stamp). The case for blocking: bec69b7a was
  # published with a stamp describing no published tree, and an advisory line was on the
  # push path and did not stop it (it was measuring the wrong tree, but a correct advisory
  # line can be scrolled past just the same). Promoting it is one line -- set SHARC=1 in the
  # NO/UNKNOWN/unmeasured arms below -- and is recorded as an OPEN operator decision.
  #
  # THE SKIP PIN'S PUSH-PATH CONSUMER (Q-477 (b), (c)). scripts/tr12_expected/n9/
  # _EXPECTED_SKIPS.txt lies under scripts/tr12_expected, which fingerprint() hashes in
  # full, and --stamp rewrites it from the observed skip set BEFORE recomputing the stamp
  # (Q-587). So CURRENT=YES here already binds the pin: its bytes are the ones the last
  # passing --stamp of this exact tree wrote. What the push path could not see was the
  # comparator and the pin's shape, so this leg also runs the pushed tree's own
  # `--selftest-skip-pin` (skip_pin_compare -- the gate's HARD FAIL -- on fixtures, plus its
  # live-pin row count), and checks that every pin row is a line observed_skips() could ever
  # produce: a row it cannot produce can never match, so it fails every future battery.
  # The FULL comparison needs VERDICTS.txt from a battery run, and a battery run on every
  # push is exactly the cost argument above; that stays on the canary and --stamp.
  #
  # Silent-by-design is gone: a pushed tree with no tr12_repro_gate.sh is SAID to be
  # unmeasured, because for a current tree that is a deleted gate, not "nothing to check".
  echo
  if [ -f "$WT/scripts/tr12_repro_gate.sh" ]; then
    echo "pre-push: [advisory] reproduction stamp + skip pin of pushed sha $short (its own tree) — NEVER blocking"
    _st_out=$( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
                 bash scripts/tr12_repro_gate.sh --check 2>&1 )
    if ! one_token TR12_REPRO_GATE_CURRENT "$_st_out"; then
      echo "  ⚠ reproduction stamp of $short: COULD NOT BE MEASURED — not the same as current"
      printf '%s\n' "$_st_out" | grep -E '^TR12_REPRO_GATE=|^ *\[(FAIL|ERROR)' | head -4 | sed 's/^/      /'
    elif tok_is 'TR12_REPRO_GATE_CURRENT=YES'; then
      echo "  [ok]   reproduction stamp describes pushed sha $short — $TOK"
    elif tok_is 'TR12_REPRO_GATE_CURRENT=NO'; then
      echo "  ⚠ REPRODUCTION STAMP IS STALE IN PUSHED SHA $short — $TOK"
      echo "    The stamp COMMITTED in $short does NOT fingerprint the tree committed beside it, so"
      echo "    nothing published attests that this tree reproduces its own battery. A corrected"
      echo "    stamp that is only an uncommitted edit does not count. ADVISORY: the push continues."
      echo "    Fix with:   ./scripts/tr12_repro_gate.sh --stamp     (then commit the stamp WITH the code)"
    elif tok_is 'TR12_REPRO_GATE_CURRENT=UNKNOWN'; then
      echo "  ⚠ pushed sha $short carries NO reproduction stamp — $TOK. ADVISORY: the push continues."
    else
      echo "  ⚠ reproduction stamp of $short: unrecognised verdict '$TOK' — not the same as current"
    fi
    # A pushed tree whose gate predates --selftest-skip-pin must NOT be asked for it: that
    # gate has no unknown-mode guard, so an unrecognised mode falls through to the full
    # build + battery run (minutes). Ask only a gate that declares the mode.
    if grep -qF -- '"--selftest-skip-pin"' "$WT/scripts/tr12_repro_gate.sh"; then
      _sp_out=$( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
                   bash scripts/tr12_repro_gate.sh --selftest-skip-pin 2>&1 )
      if ! one_token TR12_SKIP_PIN_SELFTEST "$_sp_out"; then
        echo "  ⚠ skip-pin comparator of $short: COULD NOT BE MEASURED — not the same as PASS"
      elif tok_is 'TR12_SKIP_PIN_SELFTEST=PASS'; then
        echo "  [ok]   skip-pin comparator + live pin row count — $TOK"
      else
        echo "  ⚠ $TOK — the skip-pin comparator, or the pushed tree's live pin, is broken:"
        printf '%s\n' "$_sp_out" | grep -E '^ *\[FAIL' | head -4 | sed 's/^/      /'
      fi
    else
      echo "  ⚠ pushed sha $short's tr12_repro_gate.sh has no --selftest-skip-pin — comparator UNMEASURED"
    fi
    _pin="$WT/scripts/tr12_expected/n9/_EXPECTED_SKIPS.txt"
    if [ -r "$_pin" ]; then
      _pin_rows=$(grep -vE '^[[:space:]]*(#|$)' "$_pin")
      _pin_n=$(printf '%s\n' "$_pin_rows" | grep -c .) || true
      # The producer grammar, verbatim from observed_skips() in tr12_repro_gate.sh.
      _pin_bad=$(printf '%s\n' "$_pin_rows" | grep . \
                 | grep -vE '^TR12_[A-Z0-9_]+=(SKIP|PENDING)[:A-Za-z0-9_.-]*$'; \
                 printf '%s\n' "$_pin_rows" | grep -E '_REASON=')
      if [ "${_pin_n:-0}" -eq 0 ]; then
        echo "  ⚠ skip pin of $short has ZERO rows — an empty pin certifies nothing, and the next battery run FAILS on it"
      elif [ -n "$_pin_bad" ]; then
        echo "  ⚠ skip pin of $short has row(s) the battery can never emit, so every battery run will FAIL on them:"
        printf '%s\n' "$_pin_bad" | head -4 | sed 's/^/      /'
      else
        echo "  [ok]   skip pin of $short: ${_pin_n} row(s), every one in the grammar observed_skips() produces"
      fi
    else
      echo "  ⚠ pushed sha $short has no readable scripts/tr12_expected/n9/_EXPECTED_SKIPS.txt — skip set UNPINNED"
    fi
  else
    echo "pre-push: [advisory] pushed sha $short has no scripts/tr12_repro_gate.sh — its reproduction"
    echo "          stamp and skip pin were NOT measured. For a current tree that is a deleted gate."
  fi

  # ---- ADVISORY: THE ROW-ASSERTION SWEEP, ON THE PUSHED SHA (Q-601 sibling) ---
  # Added 2026-09-11. F-5 round 4 finding B2 was "round 1's D11 class, fixed for c_v1 and
  # never swept to its siblings." CODEX_ROUNDS_STOPPING_RULE criterion 2: when the residue
  # shares a SHAPE, the next step is a gate, not a reviewer. This is that gate.
  # It judges the battery's rows, a property of the TREE, so it had the Q-601 defect too:
  # it ran in $ROOT and graded the developer's battery, not the pushed one. Moved into the
  # pushed worktree 2026-09-24 in the same sweep. (The Group C rehearsal below stays in
  # $ROOT on purpose; its header argues why.)
  # ADVISORY, deliberately: 4 driver-built rows are known-unasserted and a blocking leg
  # would gate every push on work nobody has scheduled. Red-tested at landing by deleting
  # the c_v1, c_v2 and c_v5 assertions -- rows CURRENTLY FIXED -- and confirming each is
  # named; a detector that only recognises the rows already known to be bad is a list.
  if [ -f "$WT/scripts/row_assertion_gate.sh" ]; then
    _ra_out=$( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
                 bash scripts/row_assertion_gate.sh --strict 2>&1 )
    if ! one_token ROW_ASSERTION "$_ra_out"; then
      echo "  ⚠ row-assertion sweep of $short: COULD NOT BE MEASURED — not the same as PASS"
    elif tok_is 'ROW_ASSERTION=PASS'; then
      echo "  [ok]   every emitting battery row in $short asserts something about what it emitted"
    elif tok_is 'ROW_ASSERTION=FAIL'; then
      _n=$(printf '%s\n' "$_ra_out" | grep -cE '^UNASSERTED') || true
      echo "  ⚠ ROW_ASSERTION=FAIL in $short — ${_n:-0} battery row(s) emit a table and assert nothing about it."
      echo "    A row that can publish an empty or wrong table with rc 0 is the defect class this"
      echo "    project keeps paying for. ADVISORY: the push continues. List them with:"
      echo "      ./scripts/row_assertion_gate.sh --strict"
    else
      echo "  ⚠ row-assertion sweep of $short: $TOK — not the same as PASS"
    fi
  fi

  cleanup
  if [ "$SHARC" -ne 0 ]; then
    RC=1; SHAFAIL_SEEN=1
    echo "pre-push: pushed sha $short FAILED its gates ($((SECONDS - t0)) s)"
  else
    echo "pre-push: pushed sha $short passed both gates ($((SECONDS - t0)) s)"
  fi
done

# ---- ADVISORY: doc_gates.sh --selftest, ONCE PER PUSH (Q-720, 2026-09-24) ----------------
# WHAT. `doc_gates.sh --selftest` is the mutation suite for the doc gates: it plants a defect
# for each gate it covers and requires that gate to go red. Until this leg NOTHING on the push
# path ran it, so a doc gate that had lost the ability to fail could reach the public record
# with a green `doc_gates.sh all` in front of it. Q-702 (Fable K) gave it a bare verdict token,
# DOC_GATES_SELFTEST=PASS|FAIL, and this leg reads ONLY that: one_token (exactly one emission)
# then tok_is (whole line). The banner text and the exit code are not the contract.
#
# THREE OUTCOMES THAT ARE NOT A PASS, each printed as what it is:
#   * NOT-RUN, graphviz absent. The suite's generated-artifact legs need `dot`; without it they
#     cannot run, and a suite that skipped its legs has not passed them. Checked BEFORE running.
#   * NOT-RUN, refused. On a dirty tree the selftest prints `REFUSING:` and exits 2 with no
#     token (it mutates real files and reverts with `git checkout -- .`); a concurrent run is
#     refused the same way. Nothing was tested, so this is NOT-RUN -- never PASS, never FAIL.
#   * NOT-RUN, no single verdict (crash, timeout, a tree that predates the token).
#
# WHEN, AND WHY NOT PER SHA OR OPT-IN. It costs ~4-7 min (one full mutation suite). Per pushed
# sha on every push is the slow-hook-gets-bypassed failure the `generated` leg's header argues
# against, and an OPT-IN leg is a gate with no invoker by default -- the defect class Q-479 and
# row 542 exist to close. So it runs AUTOMATICALLY but at most ONCE PER PUSH, on the LAST pushed
# ref tip whose range touches scripts/ (SCRIPTSHAS, fail-closed like its other consumers: no
# base = runs). scripts/ is where the suite's subject lives; a markdown-only push pays nothing.
# RESIDUAL, stated rather than hidden: (a) a push of several ref tips selftests only the last
# one; (b) a markdown-only push that moves a passage a fire-proof mutates is not selftested
# until the next scripts/ push. Both are advisory-leg gaps, not holes in the blocking set.
#
# IN ITS OWN FRESH CLONE, never the per-sha $WT: by the time the loop above is done, $WT holds
# ./solve_167 and other build products, so the selftest would refuse it EVERY time on a solve.c
# push -- a leg that is structurally NOT-RUN. A fresh checkout of the committed sha is clean by
# construction, and the selftest's lock lives in that clone's own .git.
#   A STANDALONE `git clone --shared` (objects borrowed from $ROOT, nothing copied), NOT a
# `git worktree add`, and that is MEASURED, not taste. In a linked worktree `git rev-parse
# --git-dir` is .git/worktrees/<name>, and GATE 17 LEG 6 of the selftest writes its mutated copy
# of doc_gates.sh there; the copy then does `cd "$(dirname "$0")/.."`, lands in .git/worktrees,
# and the leg reports FAIL on a correct tree. MEASURED 2026-09-24 on the worker (opusCC): the
# worktree form printed "[FAIL] GATE 17 LEG 6 — the gate ran against ONE board" on an
# unplanted tree. In a real clone .git/.. is the tree root, which is where operators run it.
# The clone carries $ROOT's refs/remotes/origin/* (fetched in) and NO other refs, so GATE 19
# sees the published branch set the pushed worktree sees, not $ROOT's local branches.
#
# ADVISORY: it never touches $RC. Promoting it to blocking is an OPERATOR decision (Q-711-like).
DGST_SHA=""
for _s in $SCRIPTSHAS; do DGST_SHA=$_s; done
if [ -n "$DGST_SHA" ]; then
  _ds=${DGST_SHA:0:12}
  echo
  echo "pre-push: [advisory] doc_gates.sh --selftest on pushed sha $_ds (once per push) — NEVER blocking (~4-7 min)"
  if ! command -v dot >/dev/null 2>&1; then
    echo "  ⚠ DOC_GATES_SELFTEST NOT-RUN on $_ds — graphviz 'dot' is not on PATH, so the suite's"
    echo "    rendering legs cannot run. NOT-RUN is not PASS. Install graphviz to measure it."
  else
    STBASE=$(mktemp -d "${TMPDIR:-/tmp}/prepush_selftest.XXXXXX") || STBASE=""
    if [ -z "$STBASE" ] || ! ( env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE sh -c '
           git clone -q --shared --no-checkout "$1" "$2" &&
           git -C "$2" remote remove origin &&
           git -C "$2" fetch -q "$1" "+refs/remotes/origin/*:refs/remotes/origin/*" &&
           git -C "$2" checkout -q --detach "$3"' _ "$ROOT" "$STBASE/tree" "$DGST_SHA" ) >/dev/null 2>&1; then
      echo "  ⚠ DOC_GATES_SELFTEST NOT-RUN on $_ds — could not check the sha out into a fresh clone."
    elif [ ! -f "$STBASE/tree/scripts/doc_gates.sh" ]; then
      echo "  ⚠ DOC_GATES_SELFTEST NOT-RUN on $_ds — the pushed tree has no scripts/doc_gates.sh."
    else
      _to=""; command -v timeout >/dev/null 2>&1 && _to="timeout 1800"
      _dso=$( cd "$STBASE/tree" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u CITGATE_BASE \
                $_to bash scripts/doc_gates.sh --selftest 2>&1 ); _dsrc=$?
      _dsn=$(printf '%s\n' "$_dso" | grep -cE '^DOC_GATES_SELFTEST=') || true
      if [ "${_dsn:-0}" = 0 ] && printf '%s\n' "$_dso" | grep -q '^REFUSING:'; then
        echo "  ⚠ DOC_GATES_SELFTEST NOT-RUN on $_ds — the selftest REFUSED (rc=$_dsrc); nothing was tested:"
        printf '%s\n' "$_dso" | grep -m1 '^REFUSING:' | sed 's/^/      /'
        echo "    NOT-RUN is not PASS."
      elif ! one_token DOC_GATES_SELFTEST "$_dso"; then
        echo "  ⚠ DOC_GATES_SELFTEST NOT-RUN on $_ds — no single verdict token (rc=$_dsrc$( [ "$_dsrc" = 124 ] && echo ', timed out at 1800 s'))."
        echo "    A suite that cannot report is not a suite that passed."
      elif tok_is 'DOC_GATES_SELFTEST=PASS' && [ "$_dsrc" -eq 0 ]; then
        echo "  [ok]   every mutation-tested doc gate in $_ds went red on its planted defect — $TOK"
      elif tok_is 'DOC_GATES_SELFTEST=FAIL'; then
        echo "  ⚠ DOC_GATES_SELFTEST=FAIL on $_ds — a doc gate did NOT fire on its planted defect,"
        echo "    so a green 'doc_gates.sh all' no longer proves that gate can fail:"
        printf '%s\n' "$_dso" | grep -E '^ *\[FAIL' | head -8 | sed 's/^/      /'
        echo "    ADVISORY: the push continues. Reproduce on a clean tree with:"
        echo "      bash scripts/doc_gates.sh --selftest"
      else
        echo "  ⚠ DOC_GATES_SELFTEST NOT-RUN on $_ds — verdict '$TOK' with rc=$_dsrc is not a clean PASS."
      fi
    fi
    cleanup
  fi
fi

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

# =============================================================================
# THE REPRODUCTION STAMP and THE ROW-ASSERTION SWEEP used to sit here and read
# $ROOT, the developer's working tree. Both judge a property of the TREE BEING
# PUBLISHED, so both now run per pushed sha inside its temp worktree (see
# "THE REPRODUCTION STAMP OF THE PUSHED SHA" in the loop above; Q-601, 2026-09-24).

# 🔴 Q-493. `group_c_n9_rehearsal_gate.sh` had NO INVOKER. Repo-wide grep returned its own file,
# two solve.py comments and one row of the DEVELOPMENT.md gate table -- nothing that runs it. Its
# stated job is to run every post-scan consumer at n=9 BEFORE the full-31 scan (milliseconds, $0,
# against a scan whose wall is days) AND to ratchet the count of `n == 31` guards in the consumer.
# It runs and passes today, so this is a gate that existed, worked, and was never called: the same
# shape as a check that cannot fail, one layer out. ADVISORY here because it is a pre-scan
# rehearsal rather than a property of the pushed tree.
if [ -x "$ROOT/scripts/group_c_n9_rehearsal_gate.sh" ]; then
  _gc_out=$( cd "$ROOT" && ./scripts/group_c_n9_rehearsal_gate.sh 2>/dev/null )
  # Q-523: exactly one GROUPC_REHEARSAL= line, or the *) arm -- never the positional last one.
  one_token GROUPC_REHEARSAL "$_gc_out"; _gc=$TOK
  case "$_gc" in
    GROUPC_REHEARSAL=PASS) echo "  [ok]   Group C consumers rehearse clean at n=9, and the consumer's n==31 guard count matches its pin" ;;
    GROUPC_REHEARSAL=FAIL)
      echo "  ⚠ GROUPC_REHEARSAL=FAIL — a post-scan consumer does not rehearse at n=9, or the"
      echo "    consumer's n==31 guard count has moved off its pin. ADVISORY: the push continues."
      echo "      ./scripts/group_c_n9_rehearsal_gate.sh" ;;
    *) echo "  ⚠ Group C rehearsal: could not be measured (got '${_gc:-<nothing>}') — not the same as PASS" ;;
  esac
fi

exit $RC
