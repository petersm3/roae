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
#       218-commit history replay (task #149, an internal replay whose record is not in this repository) found 12 commits whose
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
#   ADVISORY, once per push: scripts/reproduce_digests_gate.sh (REPRODUCE.md's five published
#      digests, re-derived) on the last pushed sha whose range touches solve.c, REPRODUCE.md or
#      the gate (Q-869). PASS only on the whole-line token REPRODUCE_DIGESTS=PASS.
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
# measured 2026-08-07 (~107 s on the 2026-08-06 measurement — three roae.py report
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
#   The cost figures above are unchanged in kind: still three roae.py report runs (plus LEG 7's five ~0.6 s data exports, eight invocations in all), now
# SEEDED rather than unseeded. See pre_commit_generated_gate.sh's header.
#
# NO PRIVATE BYPASS (same contract as both underlying gates): there is
# deliberately no SKIP env var. `git push --no-verify` already exists and
# leaves the decision visible in shell history.
#   The one env var that changes what runs is ROAE_PREPUSH_RECORD (Q-798, below), and it is not
# a skip: it names a TREE-KEYED VERDICT RECORD that another machine wrote after running this same
# battery on this same tree, and the hook reuses it ONLY when that record is complete, all-PASS,
# and for the exact tree, citation base and toolchain being pushed. Anything else runs the full
# battery. See "Q-798: TREE-KEYED REUSE" in the per-sha loop and scripts/prepush_verdict_record.sh.
#   The reverse also holds (Q-949, 2026-10-03): a test-fixture or override variable inherited from
# the pusher's shell is REFUSED before anything runs, so nothing in the environment can quietly
# change what the gates check. See "Q-949" just below.
#
# FAIL DIRECTION: CLOSED. A false stop costs one retry; a false pass ships a
# doc-integrity defect or a compile error into the published record.
set -u

# ---- Q-971 (c): REPLACE REFS ARE IGNORED (2026-10-03, batch 40) -------------------------------
# A refs/replace/<bad> -> <clean> entry makes every git read of <bad> (cat-file, show, ls-tree,
# `worktree add`) see <clean>'s content, while `git push` sends <bad>'s real objects. So the tree
# this hook gated was not the tree it published (measured in a scratch clone: the per-sha
# worktree checked out the CLEAN README). Found by Codex (gpt-6-astra), push-path review Q835;
# adjudicated Q-962 R9. Exported BEFORE the first git read, and inherited by every leg and gate
# below. A replace ref is not refused: with this set it changes nothing this hook reads, and a
# [note] names it so its presence is visible.
export GIT_NO_REPLACE_OBJECTS=1
ROOT=$(git rev-parse --show-toplevel) || exit 1
_q971_nrep=$(git for-each-ref --format='%(refname)' refs/replace/ 2>/dev/null | wc -l)
[ "${_q971_nrep:-0}" -gt 0 ] && echo "pre-push: [note] $_q971_nrep refs/replace/* entr(y/ies) present; IGNORED (GIT_NO_REPLACE_OBJECTS=1), the real objects are gated"
Z40=0000000000000000000000000000000000000000

# ---- Q-949: INHERITED FIXTURE AND OVERRIDE VARIABLES ARE REFUSED (2026-10-03, batch 38) --------
# WHY. Every leg below runs in the pusher's environment. Before this guard the hook dropped only
# GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE and CITGATE_BASE, so any test-fixture or override variable
# left exported in the pusher's shell reached the gates and changed what they checked: e.g.
# DOC_GATE_LSD_REF moves GATE 99's reference, DOC_GATE_TR_REG/DOC_GATE_TR_CORPUS swap the
# transcript registry and corpus, DOC_GATES_SRC_OVERRIDE makes the instrument scan read another
# file, CITGATE_ROOT/CITGATE_SRC re-root the citation gate, CLIDECL_PAIRS replaces the CLI pairs,
# G19_DOC/G19_TR12 and the other G<n>_* names repoint gate_published_consistency.sh, ATLAS swaps
# the n=31 atlas the blocking probe reads, SOLVE/BIN/SOLVE_BIN pick the binary, and *_ALLOW_STALE
# accepts a stale one. Found by Codex (gpt-6-astra), push-path review Q835 (P-02).
#
# REFUSE, NOT SCRUB. Dropping these silently would hide a mistaken setup: a pusher who exported
# one meant something by it, and the honest answer is "this push would not be judged the way you
# think", said before anything runs. So the hook stops with one line per variable and
# PREPUSH_ENV=REFUSED, exit 1. Re-push without them (`env -u NAME git push ...`). An EMPTY value is
# refused too: several gates read `${VAR-default}`, where empty is a value and not an absence.
# There is no bypass variable (same rule as the rest of this hook); --no-verify stays the visible one.
#
# THE ONE DOCUMENTED SCRUB, kept as it was (PREPUSH_ENV_DROP). CITGATE_BASE has been dropped, not
# refused, since Q-792: the hook computes the right base for each pushed sha and sets it itself,
# and the Q-792 red test pins that an exported CITGATE_BASE is overridden and the push still
# gated. SHAFAIL_SEEN and TOK are this hook's own working variables. These are unset here and a
# [note] says so.
#
# THE ALLOW-LIST (PREPUSH_ENV_ALLOW): variables a REAL push legitimately carries.
#   ROAE_PREPUSH_RECORD  Q-798 verdict-record reuse; the hook validates the record itself.
#   ROAE_PRIVATE_DIR     the operator's private checkout; turns on GATE 21's private legs and the
#                        scale gate. The operator's push runs set it.
#   ROAE_REVIEW_QUEUE    the advisory review-loop print at the foot of this file; never blocking.
#   TMPDIR, PATH, HOME   process environment: where scratch goes and where tools are found.
# None of the refusal families below can match these names; they are checked first anyway.
#
# WHERE THE LIST COMES FROM. A scan of every file the push path can reach from this hook (the file
# reference closure, without tests.py and the commit-time pre_commit_* gates), for every
# `${NAME:-` / `${NAME-` / `${NAME:=` / `${NAME:+` / `${NAME:?` read, every os.environ / os.getenv
# read, and every getenv("NAME") in C. tests.py (TestQ949Q950PrepushEnvAndRegistry) re-runs that
# scan and fails when a name it finds is neither refused here, allowed, dropped, nor on its own
# short list of names that are proven assigned before they are read. A family pattern or a named
# entry that matches nothing the scan finds also fails it, so the lists cannot go stale either way.
# NOT COVERED, and said so here: a variable read bare (`$NAME` with no default) and never assigned
# before the read. Under `set -u` that aborts; without it the scan cannot tell it from a local.
PREPUSH_ENV_ALLOW="ROAE_PREPUSH_RECORD ROAE_PRIVATE_DIR ROAE_REVIEW_QUEUE TMPDIR PATH HOME"
PREPUSH_ENV_DROP="CITGATE_BASE SHAFAIL_SEEN TOK"
# Named entries: inherited reads whose names belong to no family below.
PREPUSH_ENV_REFUSE_NAMES="ATLAS BATTERY BIN SOLVE MUT ROWRC C2C3_FORCE_STDLIB CMI_KEEP_LOGS REDACT_FILE
  CORPUS_RC DOC_CTX STRICT_FRAG CHAIN_BUDGET CHAIN_MODE PROVE_CONFIG_TIMEOUT LC_LAYERS_COMPLETE LC_RESUME
  _DG_SRC ATLAS_PORTABILITY_TIMEOUT"
# Families (shell glob patterns, matched with `case`; never pathname-expanded).
PREPUSH_ENV_REFUSE_FAMILIES='DOC_GATE_* DOC_GATES_* CITGATE_* CLIDECL_* G[0-9]*_* _G[0-9]*_* GROUPC_*
  TR12_* D5_[0-9]*_* Q[0-9]*_* *_ALLOW_STALE SOLVE_* KC_MIDN_* MANIFEST_ZERO_ENTRY_* EXEC_LANE_*
  HISTORY_* DISK_PRECHECK_* DG_* LC_SCAN_* CORRECTIONS_*'
prepush_env_guard() {
  local v p hit refused="" n=0
  local -a fams names allow drop
  # `read -a` splits on IFS and never pathname-expands, so a pattern stays a pattern.
  read -r -d '' -a fams <<<"$PREPUSH_ENV_REFUSE_FAMILIES" || true
  read -r -d '' -a names <<<"$PREPUSH_ENV_REFUSE_NAMES" || true
  read -r -d '' -a allow <<<"$PREPUSH_ENV_ALLOW" || true
  read -r -d '' -a drop <<<"$PREPUSH_ENV_DROP" || true
  for v in "${drop[@]}"; do
    if [ -n "${!v+x}" ]; then
      echo "pre-push: [note] dropped inherited $v (this hook sets it itself where a leg needs it)"
      unset "$v"
    fi
  done
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    hit=0
    for p in "${allow[@]}"; do [ "$v" = "$p" ] && hit=2 && break; done
    [ "$hit" = 2 ] && continue
    for p in "${names[@]}"; do [ "$v" = "$p" ] && hit=1 && break; done
    if [ "$hit" = 0 ]; then
      for p in "${fams[@]}"; do
        case "$v" in $p) hit=1; break ;; esac
      done
    fi
    if [ "$hit" = 1 ]; then refused="$refused $v"; n=$((n+1)); fi
  done < <(compgen -e)
  if [ "$n" -gt 0 ]; then
    echo "pre-push: 🔴 REFUSED — the environment carries $n test-fixture or override variable(s) that"
    echo "         change what the gates below would check. NOTHING was checked."
    for v in $refused; do echo "    [refused] $v"; done
    echo "         Re-run without them, e.g.:  env$(for v in $refused; do printf ' -u %s' "$v"; done) git push ..."
    echo "         (see Q-949 at the top of scripts/pre_push_gate.sh for the list and the allow-list)."
    echo "PREPUSH_ENV=REFUSED"
    return 1
  fi
  echo "PREPUSH_ENV=CLEAN"
  return 0
}
prepush_env_guard || exit 1

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
tok_is() { grep -qxF -- "$1" <<<"$TOK"; }

# ---- ADVISORY LEGS A MATCHING VERDICT RECORD MAY COVER (lane HAJ, 2026-09-27) ------------------
# The advisory legs whose answer depends on nothing but the pushed tree and the toolchain. The
# names must equal ADV_LEGS in scripts/prepush_verdict_record.sh (tests.py checks it). Each pushed
# sha prints PREPUSH_ADV_<NAME>= for each: PASS or FAIL (it ran and gave a verdict), NOT-RUN (not due,
# or no single verdict), or REUSED (taken from a matching record). A reused leg stays ADVISORY: a
# recorded FAIL is printed loudly and never touches $SHARC/$RC. Every other advisory leg always runs
# here; prepush_verdict_record.sh's header says which are excluded and why.
ADV_LEGS="Q479_F1C5_ADOPT Q479_RESUME_BUDGET Q479_MISSING_SHARD REPRODUCE_DIGESTS FAILOPEN_CLOSURE"
# adv_reuse <NAME> <label> [reproduce-command]: 0 = the matching record's verdict was used (printed,
# and _A_<NAME>=REUSED); 1 = the record holds no PASS/FAIL for it, so the caller runs the leg.
adv_reuse() {
  local rv="_RA_$1"
  case "${!rv:-}" in
    PASS) echo "    [reused]   $2 — PASS in the verdict record for this tree (not re-run)" ;;
    FAIL) echo "    ⚠ [reused] $2 — FAIL in the verdict record for this tree (not re-run)."
          echo "               ADVISORY: the push continues.${3:+ Reproduce with: $3}" ;;
    *) return 1 ;;
  esac
  printf -v "_A_$1" '%s' REUSED
  return 0
}

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

# ---- does this pushed sha need the REPRODUCE.md digest leg? ----------------
# $1 = pushed sha, $2 = remote sha ('' or all-zeros when there is no base).
# Returns 0 (leg required) when the SUBJECT of scripts/reproduce_digests_gate.sh
# differs between base and pushed sha -- solve.c (the bytes it writes),
# documentation/REPRODUCE.md (the page whose build line, command, recipe and five
# digest rows it executes) or the gate itself -- and on every path where that
# cannot be established, the same fail-closed rule as the three above. A push
# touching none of the three cannot change the gate's answer (Q-869).
needs_reprodig() {
  local base="$2" changed
  [ -n "$base" ] && [ "$base" != "$Z40" ] || return 0
  git cat-file -e "$base^{commit}" 2>/dev/null || return 0
  # One line on purpose: a continuation line starting with the gate's path reads as an
  # INVOCATION to the private gate-wiring census (its arm B keys on the line's first token).
  changed=$(git diff --name-only "$base" "$1" -- solve.c documentation/REPRODUCE.md scripts/reproduce_digests_gate.sh 2>/dev/null) || return 0
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
REPRODIGSHAS=""
NEWREFS=""
declare -A NEWREF_SHA=()   # Q-950: new branch ref -> the (peeled) sha it publishes
PUSHED_HEAD_SHAS=""        # Q-950: every sha this push publishes on a refs/heads/ ref
if [ -t 0 ]; then
  SHAS=$(git rev-parse HEAD) || exit 1
  echo "pre-push: direct invocation (no ref list on stdin) — gating HEAD ${SHAS:0:12}"
  # A plain `git push` publishes HEAD onto its upstream; diff against that
  # when it exists, otherwise fail-closed into the leg.
  UPSTREAM=$(git rev-parse '@{u}' 2>/dev/null || true)
  if needs_generated "$SHAS" "$UPSTREAM"; then GENSHAS=$SHAS; fi
  if needs_resume167 "$SHAS" "$UPSTREAM"; then R167SHAS=$SHAS; fi
  if needs_scripts   "$SHAS" "$UPSTREAM"; then SCRIPTSHAS=$SHAS; fi
  if needs_reprodig  "$SHAS" "$UPSTREAM"; then REPRODIGSHAS=$SHAS; fi
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
        # Q-950: every sha published on a branch is a tree whose COMMITTED registry may declare a
        # new name (see the declaration leg below); remember them, and which sha each new ref names.
        case " $PUSHED_HEAD_SHAS " in *" $lsha "*) ;; *) PUSHED_HEAD_SHAS="$PUSHED_HEAD_SHAS $lsha" ;; esac
        case "${rsha:-}" in
          ''|*[!0]*) ;;                      # existing remote branch: name already known
          *) case " $NEWREFS " in
               *" $rref "*) ;;
               *) NEWREFS="$NEWREFS $rref"; NEWREF_SHA[$rref]=$lsha ;;
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
    # Q-960 (Codex push-path review Q835, P-13): reachable from the DESTINATION's tracking refs,
    # not origin's whatever the destination. git hands the hook the remote's NAME as $1 (a URL for
    # `git push <url>`); only a configured remote name has tracking refs, so a URL push, a run with
    # no $1, or an unknown name skips NOTHING and gates the tree (fail-closed). The trust in the
    # tracking refs themselves (stale or hand-advanced) is unchanged and is the residual.
    _pub="" _dst="${1:-}"
    if [ -n "$_dst" ] && git config --get "remote.$_dst.url" >/dev/null 2>&1; then
      for _r in $(git for-each-ref --format='%(refname)' "refs/remotes/$_dst/" 2>/dev/null); do
        if git merge-base --is-ancestor "$lsha" "$_r" 2>/dev/null; then _pub=$_r; break; fi
      done
    fi
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
    if needs_reprodig "$lsha" "${rsha:-}"; then
      case " $REPRODIGSHAS " in *" $lsha "*) ;; *) REPRODIGSHAS="$REPRODIGSHAS $lsha";; esac
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
REPRODIGSHAS=${REPRODIGSHAS# }
# The REPRODUCE.md digest leg runs ONCE PER PUSH, on the last pushed sha whose range touches
# its subject (same once-per-push rule as the doc_gates --selftest leg; see that leg's RESIDUAL).
REPRODIG_SHA=""
for _s in $REPRODIGSHAS; do REPRODIG_SHA=$_s; done
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
# Q-950 (2026-10-03, batch 38): IT READS THE COMMITTED REGISTRY OF A PUBLISHED TREE, NEVER $ROOT's.
# Until this change it ran `bash "$ROOT/scripts/doc_gates.sh" branch-registry`, i.e. the developer's
# WORKING-TREE gate against the WORKING-TREE documentation/BRANCH_REGISTRY.tsv and README.md. An
# uncommitted registry row therefore cleared a new branch that no published tree declares, and when
# the push carries no new tree that was the whole verdict. Found by Codex (gpt-6-astra), push-path
# review Q835 (P-03). The comment this replaces said the leg ran in $ROOT because "the REMOTE REF
# LIST lives in this clone"; a LINKED worktree shares this clone's refs and remote config, so
# `git ls-remote origin` and refs/remotes/origin/* read the same there (the Q-798 always-local legs
# have run GATE 19 in the pushed worktree since 2026-09-27).
#   THE DECLARING TREE for each new ref is the first of these whose COMMITTED registry has a row for
# the name (column 1, comment rows skipped, the same rule GATE 19 applies):
#   1. the sha the ref itself publishes;
#   2. any other sha this push publishes on a branch (e.g. main carrying the row, pushed together
#      with a snapshot branch at an old commit whose own tree cannot name itself);
#   3. refs/remotes/origin/main, the published main as this clone last fetched it.
# If none declares it, the declaring tree is the ref's own sha, so GATE 19 reports it undeclared
# there. GATE 19 then runs ONCE PER DECLARING TREE, in a temp detached worktree of that sha, with
# that tree's own scripts/doc_gates.sh and DOC_GATES_PENDING_BRANCHES set to the refs it declares.
# FAIL-CLOSED: a declaring tree with no committed documentation/BRANCH_REGISTRY.tsv, or no
# scripts/doc_gates.sh, or one that does not parse, BLOCKS the push and says nothing was checked.
# RESIDUAL: candidate 3 is a cached remote-tracking ref; a main force-pushed since the last fetch to
# drop a row would still read as declaring it. `git fetch` before pushing closes that.
# reg_declares <sha> <branch>: rc 0 when <sha>'s committed registry has a row for <branch>.
reg_declares() {
  git -C "$ROOT" show "$1:documentation/BRANCH_REGISTRY.tsv" 2>/dev/null \
    | awk -F'\t' -v b="$2" '$1 == "#" || $1 ~ /^# / {next} $1 == b {f = 1} END {exit !f}'
}

# ---- temp-worktree lifecycle: removed on EVERY exit path ------------------
# A leaked worktree pollutes `git worktree list` until pruned; clean up on
# normal exit, gate failure, and interrupt alike. The pinned worktrees
# (e.g. roae-v4compiler) are never touched: this removes only the mktemp directory it created itself,
# then runs a REPOSITORY-WIDE `git worktree prune`, which drops the record of any unlocked worktree whose directory is gone.
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

NEWREF_RC=0
if [ -n "$NEWREFS" ]; then
  echo "pre-push: NEW branch ref(s) to declare: $NEWREFS"
  # Group the new refs by declaring tree (see Q-950 above).
  declare -A _DECL_REFS=()
  _DECL_ORDER=""
  _origin_main=$(git -C "$ROOT" rev-parse -q --verify 'refs/remotes/origin/main^{commit}' 2>/dev/null || true)
  for _nr in $NEWREFS; do
    _own=${NEWREF_SHA[$_nr]:-}
    _ds=""
    for _cand in $_own $PUSHED_HEAD_SHAS $_origin_main; do
      if reg_declares "$_cand" "${_nr#refs/heads/}"; then _ds=$_cand; break; fi
    done
    if [ -n "$_ds" ]; then
      [ "$_ds" = "$_own" ] || echo "pre-push: $_nr is declared by the committed registry of ${_ds:0:12}, not its own tree ${_own:0:12}"
    else
      _ds=$_own
      echo "pre-push: no committed registry this push publishes (nor origin/main's) declares $_nr"
    fi
    case " $_DECL_ORDER " in *" $_ds "*) ;; *) _DECL_ORDER="$_DECL_ORDER $_ds" ;; esac
    _DECL_REFS[$_ds]="${_DECL_REFS[$_ds]:-}${_DECL_REFS[$_ds]:+ }$_nr"
  done
  for _ds in $_DECL_ORDER; do
    _dshort=${_ds:0:12}; _drefs=${_DECL_REFS[$_ds]}
    # 🔴 SIBLING SWEEP 2026-09-02 (FINDING_FAILOPEN_CLASS instance 38), kept: a gate that could not
    # run is classified as that, never as "not declared", which would send the reader to edit a
    # registry that is fine. It is BLOCKING either way.
    if ! git -C "$ROOT" cat-file -e "$_ds:documentation/BRANCH_REGISTRY.tsv" 2>/dev/null; then
      echo "pre-push: BLOCKED — ${_dshort} has NO committed documentation/BRANCH_REGISTRY.tsv, so nothing"
      echo "         published declares $_drefs. An uncommitted registry row does not count: commit it."
      NEWREF_RC=1; continue
    fi
    WTBASE=$(mktemp -d "${TMPDIR:-/tmp}/prepush_decl.XXXXXX") || { echo "pre-push: BLOCKED — mktemp failed"; exit 1; }
    if ! git -C "$ROOT" worktree add --detach --quiet "$WTBASE/tree" "$_ds"; then
      echo "pre-push: BLOCKED — cannot check out ${_dshort} into a temp worktree for the branch-registry gate"
      cleanup; NEWREF_RC=1; continue
    fi
    if [ ! -f "$WTBASE/tree/scripts/doc_gates.sh" ]; then
      echo "pre-push: BLOCKED — COULD NOT RUN the branch-registry gate (${_dshort} has no scripts/doc_gates.sh)."
      echo "         Nothing was checked. This is not a registry finding."
      NEWREF_RC=1
    elif ! _dgerr=$(bash -n "$WTBASE/tree/scripts/doc_gates.sh" 2>&1); then
      echo "pre-push: 🔴 BLOCKED — COULD NOT RUN the branch-registry gate: ${_dshort}'s scripts/doc_gates.sh"
      echo "         does not parse, so GATE 19 never executed and the branch registry was NOT read."
      echo "         ${_dgerr:-bash -n returned non-zero with no message}"
      echo "         DO NOT edit the branch registry in response to this."
      NEWREF_RC=1
    else
      echo "pre-push: branch-registry gate for $_drefs in the committed tree of ${_dshort}"
      ( cd "$WTBASE/tree" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
          DOC_GATES_PENDING_BRANCHES="$_drefs" bash scripts/doc_gates.sh branch-registry ); _brc=$?
      case "$_brc" in
        0) echo "pre-push: branch-registry gate PASSED for $_drefs (${_dshort})" ;;
        1) echo "pre-push: BLOCKED — new branch ref(s) not declared in the branch registry of ${_dshort}"; NEWREF_RC=1 ;;
        *) echo "pre-push: 🔴 BLOCKED — COULD NOT RUN: the branch-registry gate exited $_brc, which is"
           echo "         neither clean(0) nor findings(1). It aborted after parsing; the registry was"
           echo "         not read. This is not a registry finding."; NEWREF_RC=1 ;;
      esac
    fi
    cleanup
  done
fi

if [ -z "$SHAS" ]; then
  if [ -n "$NEWREFS" ]; then
    echo "pre-push: no new tree; the declaration leg above is the whole verdict"
    exit "$NEWREF_RC"
  fi
  echo "pre-push: no shas to gate"
  exit 0
fi

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
  # ---- Q-798: TREE-KEYED REUSE (2026-09-27) ------------------------------------------------
  # WHY. The blocking legs below cost minutes of CPU and disk I/O per pushed sha, and the machine
  # that pushes is often the smallest one in the loop: on 2026-09-25 and 2026-09-27 a push ran
  # this battery for 16-20 minutes on a 2-core box after a 16-core machine had ALREADY run it green
  # on the identical tree. ROAE_PREPUSH_RECORD names a record that such a run left behind
  # (written by scripts/prepush_verdict_record.sh from a completed check: this hook's own output
  # for that tree, tests.py, the citation gate over every target, and the reproduction stamp).
  # THE RULE. The hook computes the pushed commit's tree id ITSELF and asks the PUSHED TREE's own
  # copy of the helper (the same "its own committed gates" rule as every leg here) whether the
  # record is complete, all-PASS, and for exactly this tree, this push's citation-gate base and
  # this host's toolchain. ONLY on MATCH are the covered legs skipped. On anything else -- no env
  # var, no file, a record inside $ROOT or the temp worktree, truncated, unparseable, any non-PASS,
  # another tree, another base, another toolchain, a tree with no helper -- the FULL battery runs.
  # COVERED (skipped on MATCH): doc_gates.sh all, doc_gates.sh generated, the compile gate, the
  #   published-consistency ratchet, the #167 resume leg with its disk-precheck and M3/M4 mutant
  #   legs, the n=31 atlas probe, and TR-12's output paths.
  # ALWAYS LOCAL (run on MATCH too): the four doc gates whose answer depends on THIS clone's
  #   refs, history, network or git config rather than on the tree -- GATE 19 branch-registry
  #   (ls-remote), GATE 10a/10b appendonly (HEAD and every published CORRECTIONS.md), revrows (the
  #   pushed range), GATE 23 tracked-ignored (.git/info/exclude and core.excludesFile) -- plus the
  #   new-ref declaration leg above and every advisory leg below that is not in ADV_LEGS.
  # ADVISORY, REUSABLE (lane HAJ, 2026-09-27): the ADV_LEGS above (the Q-479 battery's three public
  #   gates, the REPRODUCE.md digests, the fail-open sweep) take a PASS or FAIL from a matching record
  #   and stay advisory either way; with no such verdict in the record they run here as before.
  # Each pushed sha prints PREPUSH_TREE=, PREPUSH_CITGATE_BASE=, PREPUSH_TOOLCHAIN= and one PREPUSH_LEG_<NAME>= per
  # covered leg (PASS|FAIL|NOT-RUN, or REUSED on MATCH), and the push ends with PREPUSH_VERDICT=;
  # a record is distilled from exactly those lines, so a REUSED run can never seed a new record.
  _cb=${CITBASE[$sha]:-}
  _reuse=0
  for _v in $ADV_LEGS; do printf -v "_RA_$_v" '%s' ""; printf -v "_A_$_v" '%s' NOT-RUN; done   # lane HAJ
  _tree=$(git -C "$ROOT" rev-parse -q --verify "${sha}^{tree}" 2>/dev/null) || _tree=""
  echo "PREPUSH_TREE=${_tree:-UNKNOWN}"
  echo "PREPUSH_CITGATE_BASE=${_cb:-NONE}"
  # Q-956: the toolchain this run's legs used, as the pushed tree's helper names it; the record writer
  # takes TOOLCHAIN from this line (and the tests log), not from the host that distils the record.
  _tc=$( [ -f "$WT/scripts/prepush_verdict_record.sh" ] && bash "$WT/scripts/prepush_verdict_record.sh" toolchain 2>/dev/null ) || _tc=""
  echo "PREPUSH_TOOLCHAIN=${_tc:-UNKNOWN}"
  if [ -n "${ROAE_PREPUSH_RECORD:-}" ]; then
    _recpath=$(realpath -m -- "$ROAE_PREPUSH_RECORD" 2>/dev/null) || _recpath=""
    if [ -z "$_tree" ] || [ -z "$_recpath" ]; then
      echo "pre-push: verdict record NOT used for $short (could not resolve the tree or the record path) — full battery"
    elif [ ! -f "$WT/scripts/prepush_verdict_record.sh" ]; then
      echo "pre-push: verdict record NOT used for $short (the pushed tree has no scripts/prepush_verdict_record.sh) — full battery"
    else
      _rec_out=$( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
                    bash scripts/prepush_verdict_record.sh check --record "$_recpath" --tree "$_tree" \
                      --citgate-base "${_cb:-NONE}" --forbid-under "$ROOT" --forbid-under "$WTBASE" 2>&1 ); _recrc=$?
      if one_token PREPUSH_RECORD "$_rec_out" && tok_is 'PREPUSH_RECORD=MATCH' && [ "$_recrc" -eq 0 ]; then
        _reuse=1
        echo "pre-push: verdict record MATCHES pushed tree ${_tree:0:12} — reusing its covered legs; local legs still run:"
        printf '%s\n' "$_rec_out" | grep -E '^  ' | sed 's/^/         /'
        # lane HAJ: the advisory verdicts the record carries (PASS or FAIL only; exactly one line each).
        for _v in $ADV_LEGS; do
          _n=$(printf '%s\n' "$_rec_out" | grep -cE "^PREPUSH_RECORD_ADV_${_v}=(PASS|FAIL)\$") || true
          [ "${_n:-0}" = 1 ] || continue
          _av=$(printf '%s\n' "$_rec_out" | grep -E "^PREPUSH_RECORD_ADV_${_v}=")
          printf -v "_RA_$_v" '%s' "${_av#*=}"
        done
      else
        _why=$(printf '%s\n' "$_rec_out" | grep -m1 -E '^PREPUSH_RECORD_WHY=' || true)
        echo "pre-push: verdict record NOT used for $short (${_why:-${TOK:-no single PREPUSH_RECORD= line}}, rc=$_recrc) — full battery"
        printf '%s\n' "$_rec_out" | grep -E '^  \[' | head -3 | sed 's/^/         /'
      fi
    fi
  fi
  _L_DOC_GATES_ALL=NOT-RUN; _L_GENERATED=NOT-RUN; _L_COMPILE_GATE=NOT-RUN; _L_PUBLISHED_CONSISTENCY=NOT-RUN
  _L_R167=NOT-RUN; _L_R167_M3=NOT-RUN; _L_R167_M4=NOT-RUN; _L_ATLAS_N31=NOT-RUN; _L_TR12_OUTPUT_PATHS=NOT-RUN
  if [ "$_reuse" = 1 ]; then
    for _v in DOC_GATES_ALL GENERATED COMPILE_GATE PUBLISHED_CONSISTENCY R167 R167_M3 R167_M4 ATLAS_N31 TR12_OUTPUT_PATHS; do
      printf -v "_L_$_v" '%s' REUSED
    done
    # The ALWAYS-LOCAL doc gates, in the pushed tree, with the same CITGATE_BASE rule as `all`.
    # Blocking with the same 0 / 1 / >1 classification as the `all` leg below.
    # script-paths (GATE 21) is local too (Q-919, 2026-10-02): its COLLISION and STALE-PRIVATE
    # legs run only where ROAE_PRIVATE_DIR names the private checkout, so a record measured on a
    # host without one (every chain VM) carries a DOC_GATES_ALL=PASS in which those legs were
    # SKIPPED, and cannot speak for them. Re-running it here costs under a second.
    for _lm in branch-registry appendonly revrows tracked-ignored script-paths; do
      echo
      ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u CITGATE_BASE \
          ${_cb:+CITGATE_BASE=$_cb} bash scripts/doc_gates.sh "$_lm" ); _lrc=$?
      if [ "$_lrc" -gt 1 ]; then
        echo "pre-push: 🔴 COULD NOT RUN — local leg 'doc_gates.sh $_lm' in pushed sha $short exited $_lrc."
        SHARC=1
      elif [ "$_lrc" -ne 0 ]; then
        echo "pre-push: FAIL — local leg 'doc_gates.sh $_lm' on pushed sha $short."
        SHARC=1
      fi
    done
  else
  # (Q-798: the covered legs, unchanged and deliberately NOT re-indented, run from here to the
  #  matching "end of the covered legs" line below whenever no record MATCHed.)
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
      ( cd "$WT" && for _dg in scripts/doc_gates.sh scripts/doc_gates.d/*.sh; do bash -n "$_dg"; done 2>&1 | sed 's/^/           /' ) || true  # Q-797: entry + modules
      SHARC=1
    elif [ "$_arc" -ne 0 ]; then SHARC=1; fi
    [ "$_arc" -eq 0 ] && _L_DOC_GATES_ALL=PASS || _L_DOC_GATES_ALL=FAIL
  else
    _L_DOC_GATES_ALL=FAIL
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
        echo "          running its generated-artifact gate (GATE 8, ~67-107 s: 3 roae.py report runs + 5 data exports)"
        ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
            bash scripts/doc_gates.sh generated ); _grc=$?
        if [ "$_grc" -gt 1 ]; then
          echo "pre-push: 🔴 COULD NOT RUN — 'doc_gates.sh generated' in pushed sha $short exited"
          echo "         $_grc (neither clean(0) nor findings(1)). No artifact comparison completed;"
          echo "         do NOT regenerate example/ in response to this."
          SHARC=1
        elif [ "$_grc" -ne 0 ]; then SHARC=1; fi
        [ "$_grc" -eq 0 ] && _L_GENERATED=PASS || _L_GENERATED=FAIL
      fi ;;
  esac
  echo
  if [ -f "$WT/scripts/pre_push_compile_gate.sh" ]; then
    ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
        bash scripts/pre_push_compile_gate.sh ) && _L_COMPILE_GATE=PASS || { SHARC=1; _L_COMPILE_GATE=FAIL; }

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
                  bash scripts/gate_published_consistency.sh 2>&1 ); _gpcrc=$?
        # grep -qx, never a substring test: "PASS" is a prefix of "PASS-AT-PIN".
        # Q-523 sibling sweep: exactly one emission first. Before, a FAIL anywhere in the
        # output won (fail-closed), but FAIL-free duplicates -- PASS-AT-PIN then PASS --
        # certified whichever branch was tested first. Zero or many now block.
        if ! one_token PUBLISHED_CONSISTENCY "$_gpc"; then
          echo "pre-push: COULD NOT RUN the published-consistency gate (no single verdict token)."
          echo "         A gate that cannot report is not a gate that passed."
          SHARC=1; _L_PUBLISHED_CONSISTENCY=FAIL
        elif tok_is 'PUBLISHED_CONSISTENCY=FAIL'; then
          echo "pre-push: published-consistency RATCHET BROKEN -- a count rose above its pin:"
          printf '%s\n' "$_gpc" | grep -E 'rose to|no pin file|malformed' | sed 's/^/         /'
          echo "         Fix it, or re-pin in this same commit with the reason written down."
          SHARC=1; _L_PUBLISHED_CONSISTENCY=FAIL
        # Q-952: a passing token counts only beside rc 0; a PASS with rc 124/137/1 falls to the else arm.
        elif tok_is 'PUBLISHED_CONSISTENCY=PASS-AT-PIN' && [ "$_gpcrc" -eq 0 ]; then
          _L_PUBLISHED_CONSISTENCY=PASS
          echo "pre-push: published consistency at pin (no regression; known-open items stand)"
          # Echo WHICH legs stand. "at pin" alone reads as "fine"; the gate knows the list, so the
          # push log should carry it rather than making the lane re-run the gate to find out.
          printf '%s\n' "$_gpc" | grep -E '^  OUTSTANDING:' | sed 's/^/         /'
        elif tok_is 'PUBLISHED_CONSISTENCY=PASS' && [ "$_gpcrc" -eq 0 ]; then
          _L_PUBLISHED_CONSISTENCY=PASS
          echo "pre-push: published consistency CLEAN -- all 19 legs measured zero;"
          echo "         tighten any non-zero pin to 0 in this commit (repaired-defect budget is headroom)"
        else
          echo "pre-push: COULD NOT RUN the published-consistency gate (verdict '$TOK' with rc $_gpcrc is not a clean pass)."
          echo "         A gate that cannot report is not a gate that passed."
          SHARC=1; _L_PUBLISHED_CONSISTENCY=FAIL
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
          [ "$_r167" -eq 0 ] && _L_R167=PASS || _L_R167=FAIL
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
                printf -v "_L_R167_$_m" '%s' PASS
                echo "pre-push: #167 --mutant $_m OK — the binary REFUSED $_m's sidecar"
                echo "          (SELFTEST_RESUME_167=FAIL, D=1, R=$_mr=Z-1 of Z=$_mz: the expected verdict)"
              elif [ "$_mv" = PASS ]; then
                echo "pre-push: 🔴 FAIL — #167 --mutant $_m: the solve.c in pushed sha $short RESUMED"
                echo "         $_mwhat."
                echo "         SELFTEST_RESUME_167=PASS on a mutant that MUST fail means the discriminator is gone."
                echo "         Reproduce: scripts/selftest_resume_167_gate.sh --solve ./solve --mutant $_m"
                SHARC=1; printf -v "_L_R167_$_m" '%s' FAIL
              else
                echo "pre-push: FAIL — #167 --mutant $_m on pushed sha $short did not reach the required"
                echo "         refusal (rc=$_mrc, SELFTEST_RESUME_167=${_mv:-<none>}, D=${_md:-<none>},"
                echo "         R=${_mr:-<none>}, Z=${_mz:-<none>}; required rc 40, FAIL, D=1, R=Z-1)."
                echo "         ERROR/VACUOUS is not a refusal: nothing was shown to be discarded."
                printf '%s\n' "$_mo" | grep -E '^\[gate\] (ERROR|FAIL|VACUOUS)' | head -3 | sed 's/^/           /'
                SHARC=1; printf -v "_L_R167_$_m" '%s' FAIL
              fi
            done
          fi
        else
          echo "pre-push: FAIL — pushed sha $short touches solve.c but has no"
          echo "  scripts/selftest_resume_167_gate.sh. Deleting the gate that covers the resume"
          echo "  path is the regression it exists to prevent; --no-verify is the visible bypass."
          SHARC=1; _L_R167=FAIL
        fi ;;
    esac
  else
    echo "pre-push: FAIL — pushed sha $short has no scripts/pre_push_compile_gate.sh."
    echo "  Same rule as above: blocked, and --no-verify is the visible bypass."
    SHARC=1; _L_COMPILE_GATE=FAIL
  fi

  # ---- BLOCKING: THE n=31 ATLAS PROBE (Q-737, 2026-09-25) ------------------
  # TR-12 §12's published reproduction command is `solve.py --atlas-probe
  # runs/20260906_kc_ladders_n31/atlas_n31.json`. tests.py pins it at ATLAS_PROBE=PASS
  # (Q-734), and nothing on the push path runs tests.py, so a commit that corrupted the
  # atlas, or changed solve.py so the probe no longer passed on it, reached the public
  # record with nothing noticing. scripts/atlas_n31_probe_gate.sh runs the same two checks
  # as that test: the atlas bytes against the one digest TR-12 pins, and the probe itself.
  # UNCONDITIONAL because it is LIGHT, which is the reason for this design: no build, one
  # sha256 and one probe of a tracked file. MEASURED 2026-09-25: 5.3-5.5 s wall on the
  # D16 worker (three runs) and 7.0 s on the 2-core orchestrator, one core either way.
  # Nearly all of it is the probe's every-layer G48 invariant (Q-738; cProfile puts 14.9
  # of 16.3 profiled seconds there). Before that leg the probe took 0.59 s (public
  # 5c296837's solve.py on the same worker), and tests.py's "~0.5 s" dates from then.
  # `--selftest` runs four probes (16.7 s on the worker), so the hook runs only the gate.
  # Its red test is `--selftest`: a corrupted atlas copy must turn the probe leg red on its own,
  # a byte-only change must be caught by the digest leg, and the real atlas must pass.
  # Read through one_token + tok_is, like every verdict here: PASS is the ONLY accepted value,
  # and a missing script is a FAIL, the same rule as the compile gate above.
  if [ -f "$WT/scripts/atlas_n31_probe_gate.sh" ]; then
    _ap_out=$( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
                 bash scripts/atlas_n31_probe_gate.sh 2>&1 ); _aprc=$?
    if one_token ATLAS_N31_GATE "$_ap_out" && tok_is 'ATLAS_N31_GATE=PASS' && [ "$_aprc" -eq 0 ]; then
      _L_ATLAS_N31=PASS
      echo "pre-push: n=31 atlas probe PASS — TR-12's pinned digest, and solve.py --atlas-probe = ATLAS_PROBE=PASS"
    else
      echo "pre-push: FAIL — the n=31 atlas probe did not PASS on pushed sha $short (rc=$_aprc, '${TOK:-<no single ATLAS_N31_GATE= line>}')."
      printf '%s\n' "$_ap_out" | grep -E '^ *\[(FAIL|ERROR)\]|^ATLAS_N31_(DIGEST|PROBE|GATE_ERROR)=|^ {11}' | head -12 | sed 's/^/         /'
      echo "         Reproduce: bash scripts/atlas_n31_probe_gate.sh"
      SHARC=1; _L_ATLAS_N31=FAIL
    fi
  else
    _L_ATLAS_N31=FAIL
    echo "pre-push: FAIL — pushed sha $short has no scripts/atlas_n31_probe_gate.sh."
    echo "  Deleting the gate that runs TR-12 §12's reproduction command is the regression it"
    echo "  exists to prevent; --no-verify is the visible bypass."
    SHARC=1
  fi

  # ---- BLOCKING: TR-12's published output paths exist (Q-684, 2026-09-25) --------
  # TR-12 named six files under a `tr12/` directory that had never been tracked, and named
  # `<artifact-root>/` outputs that scripts/tr12_repro.sh never writes. doc_gates.sh GATE 21
  # cannot see a path under a top-level directory that does not exist, and no gate read the
  # placeholder form. scripts/tr12_output_paths_gate.sh checks both forms in every tracked
  # *.md (the tables moved from `tr12/` to `reports/tr12/` on 2026-09-29, CX-233; the gate now
  # fails a live `tr12/` name). UNCONDITIONAL because it is LIGHT: no build, ~1 s. Its red test
  # is `--selftest` (fourteen planted repositories, each with its expected verdict). PASS is the
  # only accepted value, and a missing script is a FAIL, the same rule as the atlas gate above.
  if [ -f "$WT/scripts/tr12_output_paths_gate.sh" ]; then
    _op_out=$( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
                 bash scripts/tr12_output_paths_gate.sh 2>&1 ); _oprc=$?
    if one_token TR12_OUTPUT_PATHS "$_op_out" && tok_is 'TR12_OUTPUT_PATHS=PASS' && [ "$_oprc" -eq 0 ]; then
      _L_TR12_OUTPUT_PATHS=PASS
      echo "pre-push: TR-12 output paths PASS — every reports/tr12/ name tracked, every <artifact-root>/ name written by the battery"
    else
      echo "pre-push: FAIL — TR-12's output paths did not PASS on pushed sha $short (rc=$_oprc, '${TOK:-<no single TR12_OUTPUT_PATHS= line>}')."
      printf '%s\n' "$_op_out" | grep -E '^ *\[FAIL\]|^TR12_OUTPUT_PATHS_ERROR=' | head -12 | sed 's/^/         /'
      echo "         Reproduce: bash scripts/tr12_output_paths_gate.sh"
      SHARC=1; _L_TR12_OUTPUT_PATHS=FAIL
    fi
  else
    echo "pre-push: FAIL — pushed sha $short has no scripts/tr12_output_paths_gate.sh."
    echo "  Deleting the gate that checks TR-12's published output paths is the regression it"
    echo "  exists to prevent; --no-verify is the visible bypass."
    SHARC=1; _L_TR12_OUTPUT_PATHS=FAIL
  fi
  fi   # Q-798: end of the covered legs (opened at "TREE-KEYED REUSE" above)
  for _v in DOC_GATES_ALL GENERATED COMPILE_GATE PUBLISHED_CONSISTENCY R167 R167_M3 R167_M4 ATLAS_N31 TR12_OUTPUT_PATHS; do
    _vn="_L_$_v"; echo "PREPUSH_LEG_$_v=${!_vn}"
  done

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
  #   * q317_missing_shard_merge_gate.sh WAS EXPECTED RED; Q-317 (4) landed 2026-09-27 (lane HAC) and it now expects PASS:
  #     until then its banner said Q-317 item (4) was not landed, "do not add it to any blocking hook until
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
        # lane HAJ: a matching verdict record may cover the three public gates; build only if one is left.
        _q479_need=0
        adv_reuse Q479_F1C5_ADOPT "f1c5 finalized-layer ADOPT compares its digest" "bash scripts/f1c5_adopt_digest_gate.sh <solve binary>" || _q479_need=1
        adv_reuse Q479_RESUME_BUDGET "an uncapped resume must not inherit budget-truncated cells" "BIN=<solve binary> bash scripts/resume_budget_infinity_gate.sh" || _q479_need=1
        adv_reuse Q479_MISSING_SHARD "an absent shard must not pass the merge" "BIN=<solve binary> bash scripts/q317_missing_shard_merge_gate.sh" || _q479_need=1
        [ -n "${ROAE_PRIVATE_DIR:-}" ] && [ -x "$ROAE_PRIVATE_DIR/scripts/canonical_scale_distinguishable_gate.sh" ] && _q479_need=1
        if [ "$_q479_need" = 0 ]; then
          :
        elif ( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
               gcc -O2 -pthread -fopenmp -DSOURCE_SHA="\"$_q479_src\"" \
                   -o solve_q479 solve.c -lm -lz ) >/dev/null 2>&1; then
          # Report a gate by its OWN whole-line KEY=value token, never by output
          # shape or exit code: an absent token is [ERROR], not a pass.
          _q479_leg() {  # $1 ADV_LEGS name (or - for none), $2 label, $3 verdict key, $4.. the command
            local adv=$1 lbl=$2 key=$3; shift 3
            local out orc av="_A_$adv"
            [ "$adv" != - ] && [ "${!av:-}" = REUSED ] && return 0   # lane HAJ: covered by the record
            out=$( "$@" 2>&1 ); orc=$?
            # Q-523: exactly one ${key}= line, or [ERROR] -- never the positional last one.
            # Q-952: and a PASS/OK counts only beside rc 0. A gate killed or timed out after printing
            # PASS (rc 124/137/143) is [ERROR] and stays NOT-RUN in the verdict record.
            if ! one_token "$key" "$out"; then
              echo "    [ERROR]    $lbl — no single ${key}= verdict line (rc $orc; diagnosis above)."
              echo "               A gate that cannot report is not a gate that passed."
            elif { tok_is "$key=PASS" || tok_is "$key=OK"; } && [ "$orc" -ne 0 ]; then
              echo "    [ERROR]    $lbl — $TOK but the gate exited $orc: HARNESS_BROKEN, not a pass."
            elif tok_is "$key=PASS" || tok_is "$key=OK"; then
              echo "    [ok]       $lbl — $TOK"
              [ "$adv" = - ] || printf -v "$av" '%s' PASS
            else
              echo "    [advisory] $lbl — $TOK"
              printf '%s\n' "$out" | grep -E '^ *\[(FAIL|ERROR)' | head -4 | sed 's/^/               /'
              [ "$adv" != - ] && tok_is "$key=FAIL" && printf -v "$av" '%s' FAIL   # ERROR stays NOT-RUN
            fi
          }
          _q479_leg Q479_F1C5_ADOPT "f1c5 finalized-layer ADOPT compares its digest" F1C5_ADOPT_DIGEST_GATE \
                    bash "$WT/scripts/f1c5_adopt_digest_gate.sh" "$_q479_bin"
          _q479_leg Q479_RESUME_BUDGET "an uncapped resume must not inherit budget-truncated cells" RESUME_BUDGET_INFINITY \
                    env BIN="$_q479_bin" bash "$WT/scripts/resume_budget_infinity_gate.sh"
          _q479_leg Q479_MISSING_SHARD "an absent shard must not pass the merge (Q-317 (4), landed 2026-09-27: PASS expected)" MISSING_SHARD_MERGE \
                    env BIN="$_q479_bin" bash "$WT/scripts/q317_missing_shard_merge_gate.sh"
          # The scale gate is an OPERATOR-SIDE artifact (roae-private) whose
          # subject is PUBLIC: the CANONICAL_RECIPES table inside solve.c. It is
          # handed ROAE_DIR=$WT so it parses the PUSHED table, and SOLVE_BIN so
          # it reuses the build above instead of compiling solve.c a second time
          # (~40 s saved; its header says it must not go in a periodic tick for
          # exactly that reason). Silent when absent, like the review-loop leg
          # below: a fresh clone, a third-party replicator and CI see nothing.
          # Q-861 sweep: located via ROAE_PRIVATE_DIR (no default), not a sibling-checkout path.
          if [ -n "${ROAE_PRIVATE_DIR:-}" ] && [ -x "$ROAE_PRIVATE_DIR/scripts/canonical_scale_distinguishable_gate.sh" ]; then
            _q479_leg - "every CANONICAL_RECIPES label is distinguishable from a typo" SCALE_DISTINGUISHABLE \
                      env ROAE_DIR="$WT" SOLVE_BIN="$_q479_bin" \
                      bash "$ROAE_PRIVATE_DIR/scripts/canonical_scale_distinguishable_gate.sh"
          fi
          rm -f "$_q479_bin"
        else
          echo "    [ERROR]    pushed sha $short did not build with -DSOURCE_SHA — the battery"
          echo "               measured NOTHING. The compile gate above is the authority on why."
        fi
      fi ;;
  esac

  # ---- ADVISORY: THE REPRODUCE.md DIGESTS (Q-727 gate, wired by Q-869, 2026-09-27) ----
  # documentation/REPRODUCE.md publishes five small-rung f-ladder `*.bin` digests (n = 9, 13,
  # 16, 18, 19) and tells a stranger that matching them proves a byte-identical build.
  # scripts/reproduce_digests_gate.sh executes the page's OWN build line, ledger command and
  # digest recipe at every row and compares digest, bytes, files and total. Its only caller was
  # tests.py (TestQ727ReproduceDigestsGate), and nothing on the push path runs tests.py -- the
  # same gap the n=31 atlas leg above closes -- so a solve.c change that moved a layer byte, or a
  # page edit that broke the recipe, reached the public record with the page still promising a
  # match. The private gate-wiring census reported it `has NO invoker` (Q-869).
  # CONDITIONAL AND ONCE PER PUSH because it BUILDS solve.c and runs `./solve --f1-exact-*`:
  # MEASURED 2026-09-27 on the D16 worker at public ba922e29, REPRODUCE_DIGESTS=PASS, 5 rungs:
  # 26-32 s wall on 16 cores; 24.5 s wall / 18 s user pinned to 2 cores (build ~17 s of it,
  # single-threaded); peak RSS ~450 MB; ~120 MB of scratch under ${TMPDIR:-/tmp}, removed on
  # exit. The Q-479 battery's build on the orchestrator took 27 s, so expect ~35-45 s there.
  # It runs only when the pushed range touches solve.c, REPRODUCE.md or the gate itself
  # (needs_reprodig, fail-closed), on the LAST such sha -- a markdown-only push pays nothing.
  # --selftest is NOT run here (69 s wall, 6 builds' worth of rungs); tests.py runs it.
  # ADVISORY: it never touches $SHARC/$RC. Promoting it to blocking is an OPERATOR decision.
  # Read through one_token + tok_is: PASS is the ONLY accepted value; ERROR is not a pass.
  if [ -n "$REPRODIG_SHA" ] && [ "$sha" = "$REPRODIG_SHA" ]; then
    echo
    echo "pre-push: [advisory] REPRODUCE.md digests on pushed sha $short (once per push) — NEVER blocking (~30-45 s)"
    if adv_reuse REPRODUCE_DIGESTS "REPRODUCE.md digests" "bash scripts/reproduce_digests_gate.sh"; then
      :   # lane HAJ: covered by a matching verdict record
    elif [ -f "$WT/scripts/reproduce_digests_gate.sh" ]; then
      _rd_to=""; command -v timeout >/dev/null 2>&1 && _rd_to="timeout 1800"
      _rd_out=$( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
                   $_rd_to bash scripts/reproduce_digests_gate.sh 2>&1 ); _rdrc=$?
      if ! one_token REPRODUCE_DIGESTS "$_rd_out"; then
        echo "  ⚠ REPRODUCE.md digests NOT-RUN on $short — no single verdict line (rc=$_rdrc$( [ "$_rdrc" = 124 ] && echo ', timed out at 1800 s'))."
        echo "    A gate that cannot report is not a gate that passed."
      elif tok_is 'REPRODUCE_DIGESTS=PASS' && [ "$_rdrc" -eq 0 ]; then
        echo "  [ok]   the page's own build line, command and recipe reproduce every published digest — $TOK"
        _A_REPRODUCE_DIGESTS=PASS
      else
        tok_is 'REPRODUCE_DIGESTS=FAIL' && _A_REPRODUCE_DIGESTS=FAIL   # ERROR or a non-zero PASS stays NOT-RUN
        echo "  ⚠ $TOK (rc=$_rdrc) on $short — REPRODUCE.md promises a digest this tree does not produce:"
        printf '%s\n' "$_rd_out" | grep -E '^ *\[(FAIL|ERROR)\]|^REPRODUCE_DIGESTS_ERROR=' | head -8 | sed 's/^/      /'
        echo "    ADVISORY: the push continues. Reproduce with: bash scripts/reproduce_digests_gate.sh"
      fi
    else
      echo "  ⚠ pushed sha $short has no scripts/reproduce_digests_gate.sh — the REPRODUCE.md digests"
      echo "    were NOT measured. For a current tree that is a deleted gate."
    fi
  fi

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
  # allowlisted (c2c3_joint_null.py, a Monte-Carlo with no tree input) — ~60
  # of those 61 seconds are that single script waiting out its clock. So this
  # does NOT need its own scheduled slot; 61 s sits inside the ~70-90 s this
  # hook already costs per pushed sha.
  # Q-705 (2026-09-25): that script's row was classed `timeout`, and on a host
  # where its numpy engine finishes first (15.9 s on the D16 worker) it printed
  # its OK token and the sweep read FAIL on a pristine tree. It is now
  # `self-contained`, which the gate accepts whether the run finishes or times
  # out; 16.5 s wall for the whole sweep on the D16 worker.
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
        if adv_reuse FAILOPEN_CLOSURE "fail-open closure sweep" "./scripts/failopen_closure_gate.sh"; then
          _fo_out=""; _fo=REUSED   # lane HAJ: covered by a matching verdict record
        else
        _fo_out=$( bash "$WT/scripts/failopen_closure_gate.sh" 2>&1 ); _forc=$?
        # Q-523: exactly one FAILOPEN_CLOSURE= line, or the *) arm below -- never the last one.
        one_token FAILOPEN_CLOSURE "$_fo_out"; _fo=$TOK
        # Q-952: OK counts only beside rc 0; otherwise the *) arm reports it as not measured.
        [ "$_fo" = FAILOPEN_CLOSURE=OK ] && [ "$_forc" -ne 0 ] && _fo="FAILOPEN_CLOSURE=OK (rc $_forc)"
        fi
        case "$_fo" in
          REUSED) ;;
          FAILOPEN_CLOSURE=OK)
            _A_FAILOPEN_CLOSURE=PASS
            echo "    [ok]       every runnable gate in the pushed tree refuses an empty world"
            printf '%s\n' "$_fo_out" | grep -E '^FAILOPEN_CLOSURE_(POP|RUN|OPEN|RC0|ALLOWED|UNRUN)=' | sed 's/^/               /' ;;
          FAILOPEN_CLOSURE=FAIL)
            _A_FAILOPEN_CLOSURE=FAIL
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
                 bash scripts/tr12_repro_gate.sh --check 2>&1 ); _strc=$?
    if ! one_token TR12_REPRO_GATE_CURRENT "$_st_out"; then
      echo "  ⚠ reproduction stamp of $short: COULD NOT BE MEASURED — not the same as current"
      printf '%s\n' "$_st_out" | grep -E '^TR12_REPRO_GATE=|^ *\[(FAIL|ERROR)' | head -4 | sed 's/^/      /'
    elif tok_is 'TR12_REPRO_GATE_CURRENT=YES' && [ "$_strc" -eq 0 ]; then   # Q-952: YES needs rc 0
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
      echo "  ⚠ reproduction stamp of $short: verdict '$TOK' with rc $_strc — not the same as current"
    fi
    # A pushed tree whose gate predates --selftest-skip-pin must NOT be asked for it: that
    # gate has no unknown-mode guard, so an unrecognised mode falls through to the full
    # build + battery run (minutes). Ask only a gate that declares the mode.
    if grep -qF -- '"--selftest-skip-pin"' "$WT/scripts/tr12_repro_gate.sh"; then
      _sp_out=$( cd "$WT" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
                   bash scripts/tr12_repro_gate.sh --selftest-skip-pin 2>&1 ); _sprc=$?
      if ! one_token TR12_SKIP_PIN_SELFTEST "$_sp_out"; then
        echo "  ⚠ skip-pin comparator of $short: COULD NOT BE MEASURED (rc $_sprc) — not the same as PASS"
      elif tok_is 'TR12_SKIP_PIN_SELFTEST=PASS' && [ "$_sprc" -ne 0 ]; then   # Q-952
        echo "  ⚠ skip-pin comparator of $short: $TOK but rc $_sprc — HARNESS_BROKEN, not the same as PASS"
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
                 bash scripts/row_assertion_gate.sh --strict 2>&1 ); _rarc=$?
    if ! one_token ROW_ASSERTION "$_ra_out"; then
      echo "  ⚠ row-assertion sweep of $short: COULD NOT BE MEASURED (rc $_rarc) — not the same as PASS"
    elif tok_is 'ROW_ASSERTION=PASS' && [ "$_rarc" -ne 0 ]; then   # Q-952
      echo "  ⚠ row-assertion sweep of $short: $TOK but rc $_rarc — HARNESS_BROKEN, not the same as PASS"
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

  # lane HAJ: the advisory legs' verdicts, for scripts/prepush_verdict_record.sh (never blocking).
  for _v in $ADV_LEGS; do
    _vn="_A_$_v"; echo "PREPUSH_ADV_$_v=${!_vn}"
  done

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
      # DOC_GATES_SELFTEST_INPLACE=1 (Q-911): $STBASE/tree is already a throwaway clone, so the
      # suite runs here rather than cloning itself a second time. A pushed tree older than
      # Q-911 ignores the variable and runs in place, which is this same clone either way.
      _dso=$( cd "$STBASE/tree" && env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u CITGATE_BASE \
                DOC_GATES_SELFTEST_INPLACE=1 $_to bash scripts/doc_gates.sh --selftest 2>&1 ); _dsrc=$?
      _dsn=$(printf '%s\n' "$_dso" | grep -cE '^DOC_GATES_SELFTEST=') || true
      if [ "${_dsn:-0}" = 0 ] && grep -q '^REFUSING:' <<<"$_dso"; then
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
    echo "  Declare it (authoritative or snapshot) in a COMMITTED registry this push publishes"
    echo "  (or origin/main's) before publishing the name -- an uncommitted row does not count (Q-950);"
    echo "  an undeclared public branch is the CX-30-on-five-refs failure mode."
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
# Q-861 sweep: the default is derived from ROAE_PRIVATE_DIR (no default of its own), not a
# sibling-checkout path; with neither variable set RLQ is empty and the leg stays silent.
RLQ="${ROAE_REVIEW_QUEUE:-${ROAE_PRIVATE_DIR:+$ROAE_PRIVATE_DIR/scripts/review_loop.sh}}"
if [ -n "$RLQ" ] && [ -x "$RLQ" ]; then
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
# stated job is to run every post-scan consumer at n=9 BEFORE the full-31 scan (milliseconds, locally,
# against a scan whose wall is days) AND to ratchet the count of `n == 31` guards in the consumer.
# It runs and passes today, so this is a gate that existed, worked, and was never called: the same
# shape as a check that cannot fail, one layer out. ADVISORY here because it is a pre-scan
# rehearsal rather than a property of the pushed tree.
if [ -x "$ROOT/scripts/group_c_n9_rehearsal_gate.sh" ]; then
  _gc_out=$( cd "$ROOT" && ./scripts/group_c_n9_rehearsal_gate.sh 2>/dev/null ); _gcrc=$?
  # Q-523: exactly one GROUPC_REHEARSAL= line, or the *) arm -- never the positional last one.
  one_token GROUPC_REHEARSAL "$_gc_out"; _gc=$TOK
  # Q-952: PASS counts only beside rc 0; otherwise the *) arm reports it as not measured.
  [ "$_gc" = GROUPC_REHEARSAL=PASS ] && [ "$_gcrc" -ne 0 ] && _gc="GROUPC_REHEARSAL=PASS (rc $_gcrc)"
  case "$_gc" in
    GROUPC_REHEARSAL=PASS) echo "  [ok]   Group C consumers rehearse clean at n=9, and the consumer's n==31 guard count matches its pin" ;;
    GROUPC_REHEARSAL=FAIL)
      echo "  ⚠ GROUPC_REHEARSAL=FAIL — a post-scan consumer does not rehearse at n=9, or the"
      echo "    consumer's n==31 guard count has moved off its pin. ADVISORY: the push continues."
      echo "      ./scripts/group_c_n9_rehearsal_gate.sh" ;;
    *) echo "  ⚠ Group C rehearsal: could not be measured (got '${_gc:-<nothing>}') — not the same as PASS" ;;
  esac
fi

# Q-798: the hook's own overall verdict, one whole line, for scripts/prepush_verdict_record.sh.
if [ "$RC" -eq 0 ]; then echo "PREPUSH_VERDICT=PASS"; else echo "PREPUSH_VERDICT=FAIL"; fi
exit $RC
