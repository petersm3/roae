#!/bin/sh
# Pre-commit dispatcher — runs BOTH commit gates.
#
# Installed to .git/hooks/pre-commit 2026-08-03 per operator ruling #1
# (O-redfloor); tracked here since 2026-08-06 (task #145) because the hook
# previously existed ONLY as an untracked file inside .git/hooks — a fresh
# clone lost it, and the install line DEVELOPMENT.md documented at the time
# (a bare symlink to pre_commit_generated_gate.sh) would have silently
# dropped the registry gate. Replacing this dispatcher with a bare symlink
# to either gate SILENTLY DISABLES the other — that is the failure this
# dispatcher exists to prevent.
#
# INSTALL (one command per clone, see DEVELOPMENT.md "Git hooks"; no chmod
# needed -- the symlink targets carry their exec bit in git):
#
#   ln -sf ../../scripts/pre_push_gate.sh .git/hooks/pre-push && ln -sf ../../scripts/pre_commit_gate.sh .git/hooks/pre-commit
#
#   1. registry gate  -- WARN ONLY. It reports retraction-registry / ledger
#      findings but MUST NOT block: a hook that refuses a red commit also stops
#      a unit committing to protect its work from another unit's
#      `git checkout -- .`, which destroyed uncommitted work four times.
#      Since task #150 it also fires WARN-only cheap retraction scans when any
#      reports/*.md, documentation/*.md or README.md is staged (see its header).
#   2. generated gate (#85) -- BLOCKING. Its exit status is the hook's.
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
exec bash "$SDIR/pre_commit_generated_gate.sh"
