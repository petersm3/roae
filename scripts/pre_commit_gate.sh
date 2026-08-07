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
bash "$ROOT/scripts/pre_commit_registry_gate.sh"; RRC=$?
[ "$RRC" -ne 0 ] && echo "[pre-commit] registry gate reported findings (rc=$RRC) - WARN ONLY, commit proceeds"
exec bash "$ROOT/scripts/pre_commit_generated_gate.sh"
