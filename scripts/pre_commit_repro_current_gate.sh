#!/usr/bin/env bash
#
# pre_commit_repro_current_gate.sh — WARN-ONLY by default. When this commit stages a reproduction-fingerprint
# input, is the STAGED scripts/tr12_expected/_GATE_STAMP.txt current for the STAGED tree?
#
# Developed with AI assistance (Claude, Anthropic). Direction is the operator's. Errors are
# Claude's; corrections invited — mrpeterson2@gmail.com.
#
# 🔴 THE GAP (Q-694, the residual of Q-685). pre_commit_stamp_gate.sh asks only whether the stamp
# file MOVED beside a closure input. It never asks whether the stamp it carries is RIGHT, and it is
# advisory, so nothing refused a commit whose tree its own stamp did not describe. Public d6b1334e
# committed an edit to documentation/VERIFY.md (a CORE input) without the stamp; the rule lived
# only in the comment at the top of the stamp file.
#
# WHAT THIS COMPUTES. The index, not the working tree. It builds a scratch tree in which every
# index path EXISTS (empty placeholders) and only the fingerprint members, plus everything under
# scripts/tr12_expected, carry their STAGED bytes. Then it runs the STAGED gate's own check there:
#
#     bash "$T"/scripts/tr12_repro_gate.sh --check
#
# and the verdict is that command's whole-line TR12_REPRO_GATE_CURRENT token.
#
# WHY IT IS CHEAP. `--check` builds nothing and runs no battery: it is the golden-manifest check,
# the coverage check and one sha256 pass over the members (measured 0.75 s wall on 16 cores). The
# only extra cost here is writing the members, about 8 MB, never the 80+ MB whole tree.
#
# WHY THE SCRATCH TREE IS EXACT, NOT A SAMPLE. Membership is DERIVED by the gate's own
# derived_inputs(), which (a) tests EXISTENCE of every candidate path and (b) READS only files that
# are already members. The placeholders answer (a) exactly as a full checkout would. For (b), the
# members are found by a fixed point: extract derived_inputs()/fingerprint_files() from the STAGED
# gate (the same awk range pre_commit_stamp_gate.sh uses; never a copied list), list the members,
# write the new ones' staged bytes, list again, and stop when the list stops growing. At that point
# every file the derivation reads holds its staged bytes, so the member list, and therefore the
# fingerprint, equals the one a full checkout of the index would give.
#
# WHEN IT FIRES. Only when a staged path (added, modified, deleted, type-changed; renames split
# into delete + add) is a fingerprint member of the STAGED tree, lies under scripts/tr12_expected
# (the stamp included: a stamp staged alone is checked too), or is ANY deletion. Deletions trigger
# unconditionally because a deleted derived member has left the staged derivation and cannot be
# recognised there; deletions are rare and the check is cheap. Anything else is NOT-APPLICABLE and
# costs one pass of the derivation.
#
# THE COMMITTER'S WORKFLOW PASSES. Stamping the same bytes on another machine and copying
# _GATE_STAMP.txt back gives the same fingerprint: the gate hashes repo-relative paths and file
# contents only. What does NOT pass is a stamp taken over a working tree that differs from the
# index (a partial `git add`), which is the point.
#
# WARN-ONLY, per operator ruling O-redfloor: a hook that refuses a commit also stops a unit
# committing to protect its work, so the dispatcher prints a loud named warning on any rc other than
# 0 and lets the commit proceed. ROAE_REQUIRE_CURRENT_STAMP=1 opts in to refusing instead; the
# default stays advisory until the operator rules otherwise.
#
# Verdict tokens, whole-line, `grep -qx` them:
#   PRECOMMIT_REPRO=CURRENT          a fingerprint input is staged and the staged stamp matches
#   PRECOMMIT_REPRO=STALE            a fingerprint input is staged and the staged stamp does not
#   PRECOMMIT_REPRO=NOT-APPLICABLE   nothing staged touches the fingerprint
#   PRECOMMIT_REPRO=ERROR            could not measure. NEVER the same as NOT-APPLICABLE
#   PRECOMMIT_REPRO_INPUT=<path>     one line per staged path that triggered the check
#   PRECOMMIT_REPRO_CHECK=<word>     the gate's own TR12_REPRO_GATE_CURRENT value (YES|NO|UNKNOWN)
#   PRECOMMIT_REPRO_ERROR=<cause>    emitted only beside =ERROR
#
# rc: 0 = CURRENT or NOT-APPLICABLE, 1 = STALE, 2 = ERROR.
set -uo pipefail

GATE_SRC=scripts/tr12_repro_gate.sh
EXP_DIR=scripts/tr12_expected
MAX_ROUNDS=16
# Positive controls, as in pre_commit_stamp_gate.sh: a derivation that cannot see these is broken.
CONTROL_A=solve.c
CONTROL_B=scripts/tr12_repro.sh
MIN_MEMBERS=5

err(){ echo "  [ERROR] $2"; echo "PRECOMMIT_REPRO_ERROR=$1"; echo "PRECOMMIT_REPRO=ERROR"; exit 2; }

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || err not-in-git-repo "not inside a git work tree; the index cannot be read"
cd "$ROOT" || err not-in-git-repo "cannot enter $ROOT"
W=$(mktemp -d) || err mktemp-failed "could not create a scratch directory"
trap 'rm -rf "$W"' EXIT
T="$W/tree"; mkdir "$T" || err mktemp-failed "could not create $T"

# The staged set. A failing `git diff --cached` and an empty index look the same by output alone.
git diff --cached --name-only --no-renames --diff-filter=ACMDT -z > "$W/staged.z" 2>/dev/null \
  || err staged-list-failed "could not read the index (git diff --cached failed)"
tr '\0' '\n' < "$W/staged.z" > "$W/staged"
if [ ! -s "$W/staged" ]; then echo "PRECOMMIT_REPRO=NOT-APPLICABLE"; exit 0; fi
git diff --cached --name-only --no-renames --diff-filter=D -z > "$W/deleted.z" 2>/dev/null \
  || err staged-list-failed "could not read the index deletions"
git ls-files -z > "$W/index.z" 2>/dev/null || err index-list-failed "git ls-files failed"
tr '\0' '\n' < "$W/index.z" > "$W/index"

# A tree with neither the gate nor its stamp has no fingerprint to keep current (a pinned campaign
# worktree of old history, say). Anything short of that, with the gate missing, is ERROR.
if ! grep -qxF "$GATE_SRC" "$W/index"; then
  if ! grep -qxF "$EXP_DIR/_GATE_STAMP.txt" "$W/index" && ! tr '\0' '\n' < "$W/deleted.z" | grep -cxF "$GATE_SRC" >/dev/null; then
    echo "  no $GATE_SRC and no stamp in this index: nothing to keep current"
    echo "PRECOMMIT_REPRO=NOT-APPLICABLE"; exit 0
  fi
  err gate-absent "$GATE_SRC is not in the index, so the staged fingerprint cannot be computed"
fi

# Placeholders: every index path exists, empty, so the derivation's existence tests answer as a
# full checkout would. Then the gate and the expected blocks get their staged bytes.
( cd "$T" && xargs -0 -r dirname -z -- < "$W/index.z" | LC_ALL=C sort -zu | xargs -0 -r mkdir -p -- \
    && xargs -0 -r touch -- < "$W/index.z" ) || err scratch-failed "could not lay out the placeholder tree"
{ printf '%s\0' "$GATE_SRC"; grep -z "^$EXP_DIR/" "$W/index.z"; } > "$W/seed.z"
git checkout-index -f -z --stdin --prefix="$T/" < "$W/seed.z" \
  || err checkout-failed "could not write the staged gate and expected blocks"
tr '\0' '\n' < "$W/seed.z" | LC_ALL=C sort -u > "$W/written"

awk '/^derived_inputs\(\)\{/{p=1} p{print} /^fingerprint_files\(\)\{/{if(p)exit}' "$T/$GATE_SRC" > "$W/fns"
grep -q '^derived_inputs()' "$W/fns" && grep -q '^fingerprint_files()' "$W/fns" \
  || err extraction-failed "could not extract derived_inputs()/fingerprint_files() from the staged $GATE_SRC"

round=0
while :; do
  round=$((round+1))
  [ "$round" -le "$MAX_ROUNDS" ] || err fixed-point-not-reached "member list still growing after $MAX_ROUNDS rounds"
  # shellcheck source=/dev/null
  ( cd "$T" && . "$W/fns" && fingerprint_files ) > "$W/members" 2>/dev/null \
    || err extraction-unparseable "the extracted closure functions failed in the scratch tree"
  grep -Fxf "$W/index" "$W/members" | LC_ALL=C sort -u > "$W/present"
  LC_ALL=C comm -23 "$W/present" "$W/written" > "$W/new"
  [ -s "$W/new" ] || break
  tr '\n' '\0' < "$W/new" | git checkout-index -f -z --stdin --prefix="$T/" \
    || err checkout-failed "could not write staged fingerprint members"
  LC_ALL=C sort -u "$W/written" "$W/new" -o "$W/written"
done

n=$(grep -c . "$W/members")
if [ "${n:-0}" -lt "$MIN_MEMBERS" ] || ! grep -qxF "$CONTROL_A" "$W/members" || ! grep -qxF "$CONTROL_B" "$W/members"; then
  err closure-collapsed "the staged derivation returned ${n:-0} member(s) or lost $CONTROL_A/$CONTROL_B"
fi

# Trigger: staged members (the unfiltered list keeps a deleted CORE file), anything under the
# expected-block directory, and every deletion.
{ cat "$W/members"; grep "^$EXP_DIR/" "$W/staged"; tr '\0' '\n' < "$W/deleted.z"; } | grep -v '^$' > "$W/watch"
grep -Fxf "$W/watch" "$W/staged" > "$W/hits"
if [ ! -s "$W/hits" ]; then echo "PRECOMMIT_REPRO=NOT-APPLICABLE"; exit 0; fi

OUT=$(bash "$T"/scripts/tr12_repro_gate.sh --check 2>&1)
printf '%s\n' "$OUT" > "$W/out"
word=$(sed -n 's/^TR12_REPRO_GATE_CURRENT=\(YES\|NO\|UNKNOWN\)$/\1/p' "$W/out" | tail -1)
sed 's/^/PRECOMMIT_REPRO_INPUT=/' "$W/hits"
if [ -z "$word" ]; then
  sed 's/^/        /' "$W/out"
  err check-no-token "the staged gate's --check printed no TR12_REPRO_GATE_CURRENT line"
fi
echo "PRECOMMIT_REPRO_CHECK=$word"
if [ "$word" = YES ]; then
  echo "  [ok]   $(grep -c . "$W/hits") fingerprint input(s) staged; the staged stamp is current for the staged tree"
  echo "PRECOMMIT_REPRO=CURRENT"; exit 0
fi
echo
echo "  🔴 THE STAGED STAMP DOES NOT DESCRIBE THE STAGED TREE (TR12_REPRO_GATE_CURRENT=$word)."
echo "     These staged paths are reproduction-fingerprint inputs:"
sed 's/^/        /' "$W/hits"
echo "     Stamp the exact tree being committed, then stage the stamp into this commit:"
echo "        ./scripts/tr12_repro_gate.sh --stamp"
echo "        git add $EXP_DIR/_GATE_STAMP.txt"
echo "     A stamp taken over a working tree that differs from the index does not match."
echo "PRECOMMIT_REPRO=STALE"; exit 1
