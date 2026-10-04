#!/bin/sh
# Pre-commit dispatcher — runs FIVE legs in this order: registry, stamp, reproduction-currency (all WARN ONLY), size, generated (both BLOCKING).
#
# Installed to .git/hooks/pre-commit 2026-08-03 per operator ruling #1
# (O-redfloor); tracked here since 2026-08-06 (task #145) because the hook
# previously existed ONLY as an untracked file inside .git/hooks — a fresh
# clone lost it, and the install line DEVELOPMENT.md documented at the time
# (a bare symlink to pre_commit_generated_gate.sh) would have silently
# dropped the registry gate. Replacing this dispatcher with a bare symlink
# to any one gate SILENTLY DISABLES the others — that is the failure this
# dispatcher exists to prevent.
#
# INSTALL (one command per clone, see DEVELOPMENT.md "Git hooks"; no chmod
# needed -- the symlink targets carry their exec bit in git):
#
#   ln -sf ../../scripts/pre_push_gate.sh .git/hooks/pre-push && ln -sf ../../scripts/pre_commit_gate.sh .git/hooks/pre-commit
#
#   1. registry gate  -- WARN ONLY: retraction-registry / ledger findings; it MUST NOT block (a hook
#      that refuses a red commit also stops a unit committing to protect its work from another unit's
#      `git checkout -- .`, which destroyed uncommitted work four times). Since task #150 it also fires
#      WARN-only retraction scans when any reports/*.md, documentation/*.md or README.md is staged.
#   2. stamp gate, 3. reproduction-currency gate -- WARN ONLY (O-redfloor; the latter refuses only on opt-in).
#   4. size gate -- BLOCKING, and it exits before leg 5 when it refuses (V3A-119#2: this list named two legs).
#   5. generated gate (#85) -- BLOCKING, run last by exec. Its exit status is the hook's.
# Q-971 (c) (2026-10-03, batch 40): a refs/replace/* entry would change the HEAD and index objects
# the legs below read (the size gate sizes staged blobs with `git cat-file -s`), while the commit
# records the real ones. Ignore replace refs for every leg; same rule as scripts/pre_push_gate.sh.
export GIT_NO_REPLACE_OBJECTS=1
ROOT=$(git rev-parse --show-toplevel) || exit 1
# WORKTREE FIX (2026-08-13): resolve the gate scripts from THIS script's own
# location, not from $ROOT. .git/hooks is shared across git worktrees, so a
# commit made in a worktree (e.g. v4canon-b1464fa) sets $ROOT to that worktree,
# which has no scripts/ dir -- the gates then failed with rc=127 "No such file
# or directory" and the BLOCKING generated gate aborted every commit there.
# Silently skipping would be worse than aborting, so the old behaviour was
# fail-safe, but it forced --no-verify, which skips the gates for real.
# $0 is the hook path (a symlink into scripts/); readlink -f resolves it.
SDIR=$(cd "$(dirname "$(readlink -f "$0")")" 2>/dev/null && pwd)
[ -n "$SDIR" ] && [ -f "$SDIR/pre_commit_generated_gate.sh" ] || SDIR="$ROOT/scripts"
if [ ! -f "$SDIR/pre_commit_generated_gate.sh" ]; then
  echo "[pre-commit] FATAL: cannot locate pre_commit_generated_gate.sh (tried '$SDIR')." >&2
  echo "[pre-commit] Refusing to commit -- a BLOCKING gate that cannot run must not pass." >&2
  exit 1
fi
# 🔴 THREE VERDICTS, NOT TWO (FINDING_FAILOPEN_CLASS instance 38, 2026-09-02).
# This line used to be `[ "$RRC" -ne 0 ] && echo "... reported findings (rc=$RRC) ..."`. Observed
# live: another unit was mid-edit on scripts/doc_gates.sh, bash refused to parse it, every leg
# returned 2, and this dispatcher announced that the registry gate "reported findings" — on a commit
# staging RETRACTED_PHRASES.tsv and CORRECTIONS.md. The gate reported nothing; it never ran. The
# commit was verified by nothing while the message said the gates had looked and had opinions.
#
# WARN-ONLY IS UNCHANGED AND IS NOT THE DEFECT. The caller still decides; nothing here blocks. What
# changes is that "I could not look" now has its own words and its own exit status, so the two are
# no longer indistinguishable downstream.
#
# rc contract, defined in pre_commit_registry_gate.sh's header:
#   0 = CLEAN or NOT-APPLICABLE   1 = FINDINGS   2 = COULD-NOT-RUN
# Anything else (127 = the gate script itself is missing/unexecutable, >=128 = signal) is also
# "could not look" — classified, never defaulted to "findings".
bash "$SDIR/pre_commit_registry_gate.sh"; RRC=$?
case "$RRC" in
  0) ;;
  1) echo "[pre-commit] registry gate reported FINDINGS (rc=1) - WARN ONLY, commit proceeds" ;;
  *) echo "[pre-commit] 🔴 registry gate COULD NOT RUN (rc=$RRC) - it reported NOTHING."
     echo "[pre-commit]    This is not a finding and not a pass: the registry/ledger content of this"
     echo "[pre-commit]    commit was checked by NOTHING. WARN ONLY, commit proceeds (O-redfloor),"
     echo "[pre-commit]    but do not record this commit as gated. Re-run once the box is quiet:"
     echo "[pre-commit]        bash scripts/pre_commit_registry_gate.sh" ;;
esac
# 🔴 THE REPRODUCTION STAMP, AT COMMIT TIME — added 2026-09-21, because the push-path check
# arrives after the damage. Public 6fc04532 staged documentation/CORRECTIONS.md, one of the 44
# files in the reproduction fingerprint closure, WITHOUT scripts/tr12_expected/_GATE_STAMP.txt:
# the stamp blob it committed is byte-identical to its parent's, so as committed that tree
# carried a fingerprint describing a different tree. pre_push_gate.sh does check the stamp (the
# per-sha leg headed "ADVISORY: THE REPRODUCTION STAMP OF THE PUSHED SHA"); it simply runs at PUSH, and commits here
# are batched and pushed later. (Until Q-601, 2026-09-24, that leg also measured $ROOT rather than
# the pushed sha, so it was not correct either; see pre_commit_stamp_gate.sh's header, Q-710.)
# Measured that day: `grep -c tr12_repro_gate .git/hooks/pre-commit` -> 0.
#
# WARN-ONLY, like the registry gate above and for the same operator ruling (O-redfloor), plus
# the "ADVISORY, NOT BLOCKING" reasoning in pre_push_gate.sh's "ADVISORY: THE REPRODUCTION STAMP OF THE PUSHED SHA" leg: a missing stamp means "not yet shown to reproduce",
# which is a fact about evidence, not a broken tree. Its rc is READ and CLASSIFIED and never
# propagated -- three verdicts, not two, so "I could not look" cannot read as "nothing to see".
# `timeout` is belt-and-braces: a wedged leg must not be able to stall a commit.
if [ -f "$SDIR/pre_commit_stamp_gate.sh" ]; then
  timeout 60 bash "$SDIR/pre_commit_stamp_gate.sh"; STRC=$?
  case "$STRC" in
    0) ;;
    1) echo "[pre-commit] ⚠ a reproduction-closure input is staged WITHOUT its stamp (named above)."
       echo "[pre-commit]    WARN ONLY, commit proceeds. Fix: ./scripts/tr12_repro_gate.sh --stamp" ;;
    *) echo "[pre-commit] ⚠ stamp gate COULD NOT RUN (rc=$STRC) - it reported NOTHING. That is not"
       echo "[pre-commit]    a pass: the stamp content of this commit was checked by nothing."
       echo "[pre-commit]    WARN ONLY, commit proceeds." ;;
  esac
else
  echo "[pre-commit] ⚠ scripts/pre_commit_stamp_gate.sh is ABSENT - the commit-path stamp check"
  echo "[pre-commit]    did NOT run. WARN ONLY, commit proceeds."
fi

# 🔴 THE REPRODUCTION STAMP MUST BE CURRENT FOR THE STAGED TREE (Q-694, the residual of Q-685).
# The leg above only notices that the stamp did not MOVE; nothing asked whether the staged stamp is
# RIGHT. pre_commit_repro_current_gate.sh does, when a fingerprint input is staged: it lays the
# index's fingerprint members into a scratch tree and runs the staged gate's own
#     bash scripts/tr12_repro_gate.sh --check
# there (no build, no battery) and reports unless it prints TR12_REPRO_GATE_CURRENT=YES.
# WARN-ONLY like the leg above, per operator ruling O-redfloor (a hook that refuses a commit also
# stops a unit committing to protect its work). A leg that is missing, times out or cannot measure
# is reported as unmeasured, never as current. ROAE_REQUIRE_CURRENT_STAMP=1 opts in to refusing.
if [ -f "$SDIR/pre_commit_repro_current_gate.sh" ]; then
  timeout 120 bash "$SDIR/pre_commit_repro_current_gate.sh"; RCRC=$?
else
  echo "[pre-commit] scripts/pre_commit_repro_current_gate.sh is ABSENT - reproduction currency unmeasured."
  RCRC=127
fi
if [ "$RCRC" -ne 0 ]; then
  case "$RCRC" in
    1) RCWHY="the staged stamp does not describe the staged tree (TR12_REPRO_GATE_CURRENT is not YES)" ;;
    *) RCWHY="the reproduction-currency leg could not measure (rc=$RCRC)" ;;
  esac
  echo "[pre-commit] ⚠ $RCWHY."
  echo "[pre-commit]    Stamp the exact tree being committed (./scripts/tr12_repro_gate.sh --stamp,"
  echo "[pre-commit]    or on a VM and copy scripts/tr12_expected/_GATE_STAMP.txt back), then"
  echo "[pre-commit]    git add scripts/tr12_expected/_GATE_STAMP.txt."
  if [ "${ROAE_REQUIRE_CURRENT_STAMP:-}" = 1 ]; then
    echo "[pre-commit] 🔴 BLOCKED (ROAE_REQUIRE_CURRENT_STAMP=1). Nothing was committed."
    exit 1
  fi
  echo "[pre-commit]    WARN ONLY (operator ruling O-redfloor), commit proceeds."
  echo "[pre-commit]    This commit is NOT shown reproduction-current."
fi

# 🔴 SIZE GATE — added 2026-09-04 because the standing >=1 MB rule was enforced NOWHERE here.
# Measured that day: no size check existed in this dispatcher, pre_commit_registry_gate.sh,
# pre_commit_generated_gate.sh or pre_push_gate.sh, and `oversize_approved.tsv` lived only in
# roae-private, read only by that repo's postwindow committer. HARDENING_BACKLOG Q-210 asserted the
# public tree "has its own separate guard" — it did not. A rule everyone believes is enforced, and
# which is enforced nowhere, is worse than one known to be manual: nobody checks, because everybody
# assumes something already did.
#
# BLOCKING, not warn-only, and deliberately unlike the registry gate above. That one warns because a
# registry finding is a judgement call about content. This one is arithmetic about a file the
# operator has said must not be added without their word, and letting it through means the commit
# has already happened by the time anyone reads a warning.
# Q-746 / V3A-119#1 (2026-09-24): the advice below used to say only "gzip -9 the file". Followed
# literally that leaves the big blob in the index, and the size gate then skipped it because the
# working copy was gone -- the remedy WAS the bypass. The gate now measures the index blob whether
# or not a working copy exists, and the advice says to re-stage.
bash "$SDIR/pre_commit_size_gate.sh"; SZRC=$?
if [ "$SZRC" -ne 0 ]; then
  echo "[pre-commit] 🔴 BLOCKED by the size gate (rc=$SZRC). Nothing was committed."
  echo "[pre-commit]    Get the operator's OK and record it in scripts/oversize_approved.tsv AND STAGE IT,"
  echo "[pre-commit]    or gitignore it, or gzip -9 it AND RE-STAGE: the size gate measures the INDEX,"
  echo "[pre-commit]    so run 'git rm --cached -- <file>' and 'git add -- <file>.gz' as well; gzip alone"
  echo "[pre-commit]    leaves the uncompressed blob staged. Do not raise the threshold."
  exit "$SZRC"
fi

exec bash "$SDIR/pre_commit_generated_gate.sh"
