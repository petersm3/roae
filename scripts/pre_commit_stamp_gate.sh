#!/usr/bin/env bash
#
# pre_commit_stamp_gate.sh — ADVISORY. Does this commit stage a reproduction-closure input
# WITHOUT the stamp that attests it?
#
# Developed with AI assistance (Claude, Anthropic). Direction is the operator's. Errors are
# Claude's; corrections invited — mrpeterson2@gmail.com.
#
# 🔴 THE DEFECT THIS CLOSES, MEASURED 2026-09-21 AND NOT ARGUED.
# Public commit 6fc04532 staged documentation/CORRECTIONS.md — one of the 44 files in the
# reproduction fingerprint closure ($CORE plus derived_inputs' transitive scan, as
# scripts/tr12_repro_gate.sh itself enumerates them) — and did NOT stage
# scripts/tr12_expected/_GATE_STAMP.txt. Measured at the object level: the stamp blob at
# 6fc04532 is 25d08b86…, BYTE-IDENTICAL to its parent fa5a98dd's. So as committed, that tree
# shipped a fingerprint describing SOME OTHER TREE — exactly what the stamp's own header
# forbids: "Re-stamp in the SAME commit as any solve.c, tr12_repro.sh or expected-block change,
# or --check will correctly report NO."
#
# The correct stamp ALREADY EXISTED. The tr12_repro_canary cron saw the input change, ran the
# full battery and re-stamped at 04:46:31Z (roae-private
# scripts/v4_execlane_evidence/tr12_canary.log:1645); the commit landed at 05:11:21Z, 25 minutes
# later, and took the source files without it. Nothing was missing except a consumer.
#
# 🔴 WHY NOTHING CAUGHT IT. scripts/pre_push_gate.sh:744-757 DOES consume the stamp, and it is
# correct — but it runs at PUSH, and commits here are batched and pushed later, so by the time
# anything looked the defect was already history. Measured the same day:
#
#     grep -c tr12_repro_gate .git/hooks/pre-commit   ->   0
#
# The COMMIT path had no stamp awareness at all. That is this repository's recurring shape one
# level out from the code: a gate that is correct, runs somewhere, and is never asked at the
# moment the damage is done.
#
# 🔴 ADVISORY, NOT BLOCKING — A HARD REQUIREMENT, NOT A PREFERENCE, and the reasoning is
# pre_push_gate.sh:737-741's, honoured rather than re-invented. A stale or unstaged stamp means
# "this tree has not been shown to reproduce", which is a fact about EVIDENCE, not a broken tree.
# Beyond that, operator ruling O-redfloor applies with full force here: a hook that refuses a
# commit also stops a unit committing to protect its work from another unit's `git checkout --`,
# which has destroyed uncommitted work four times. A buggy blocking hook on this path would lock
# an unattended session out of committing entirely — a far worse failure than the visibility gap
# being closed. So: print, name the files, name the fix command, and let the commit proceed. The
# dispatcher ignores this script's exit status by construction.
#
# 🔴 WHAT THIS DOES NOT DO, stated because the boundary is the whole design.
#   * It does NOT recompute a fingerprint, and that is deliberate. `--check` compares against the
#     WORKING TREE; the thing being committed is the INDEX. Answering "is the stamp current?"
#     against the worktree at commit time would rebuild Q-601's defect (the push gate's --check
#     leg runs in $ROOT while its content legs use a detached worktree of the pushed sha) one
#     hook earlier. The question answerable EXACTLY from the index alone is "did you stage a
#     closure input without staging its stamp?", and that is the question asked. Any byte change
#     to a closure input moves the fingerprint, so "the stamp must move in the same commit" is
#     not an approximation of the stamp's header requirement — it IS the requirement.
#   * CLOSURE MEMBERSHIP is derived from the worktree (the gate's functions read files), while
#     the STAGED SET comes from the index. They differ only if the worktree moved after staging;
#     in that window membership can be misjudged. Bounded, named, not silently assumed away.
#   * It says nothing about whether a STAGED stamp is correct. That is the push gate's leg, and
#     Q-601 is the open row about where that leg looks.
#
# 🔴 THE CLOSURE IS EXTRACTED FROM THE GATE, NEVER COPIED. A curated list here would rot exactly
# as tr12_repro_gate.sh's own hand-maintained list rotted before Q-94 derived it — and it would
# rot silently, because a list cannot notice its own omission. This sources derived_inputs(),
# $CORE and fingerprint_files() out of scripts/tr12_repro_gate.sh and calls them. If that
# extraction stops working, this gate ERRORs; it never degrades to "nothing staged".
#
# Verdict tokens, whole-line, `grep -qx` them — never gate on output shape:
#   PRECOMMIT_STAMP=OK               closure input(s) staged, and the stamp is staged with them
#   PRECOMMIT_STAMP=MISSING-STAMP    the finding: closure input(s) staged, stamp is not
#   PRECOMMIT_STAMP=NOT-APPLICABLE   no closure input in this commit (the common case)
#   PRECOMMIT_STAMP=ERROR            could not measure. NEVER the same as NOT-APPLICABLE
#   PRECOMMIT_STAMP_INPUT=<path>     one line per staged closure input (on MISSING-STAMP)
#   PRECOMMIT_STAMP_COUNT=<n>        staged closure inputs. -1 when unmeasured
#   PRECOMMIT_STAMP_ERROR=<cause>    emitted only beside =ERROR
#   PRECOMMIT_STAMP_SELFTEST=PASS|FAIL   --selftest only
#
# rc: 0 = OK or NOT-APPLICABLE, 1 = MISSING-STAMP, 2 = ERROR. The rc is for scripting; the
# TOKEN is the authority, and the dispatcher acts on NEITHER by blocking.
#
# Usage:
#   scripts/pre_commit_stamp_gate.sh              # the real leg, reads the index
#   scripts/pre_commit_stamp_gate.sh --selftest   # the comparison on fixtures, no index needed
set -uo pipefail

MODE=${1:-run}
STAMP_PATH=scripts/tr12_expected/_GATE_STAMP.txt
GATE_SRC=scripts/tr12_repro_gate.sh
# The gate's own floor (tr12_repro_gate.sh fingerprint_coverage_check refuses below 5): a
# derivation that silently narrows still returns plenty of files, so a bare count is weak — but
# a count below the floor is unambiguously broken.
MIN_CLOSURE=5
# Positive controls. An ABSENCE needs one: "no closure input staged" is only meaningful if the
# closure could have contained something. These two are in $CORE verbatim, so a derivation that
# cannot see them is not a narrow derivation, it is a broken one.
CONTROL_A=solve.c
CONTROL_B=scripts/tr12_repro.sh

# classify STAGED_LIST CLOSURE_LIST — PURE: it reads two newline-delimited files and nothing
# else, which is what lets --selftest drive it on fixtures. Both are read as FILES, never piped
# into `grep -q`: a producer piped into `grep -q` is SIGPIPE'd on first match, which this project
# has measured turning a match into an intermittent failure.
classify(){
  local staged="$1" closure="$2" n hits count
  if [ ! -r "$closure" ]; then
    echo "  [ERROR] closure list unreadable ($closure)"
    echo "PRECOMMIT_STAMP_COUNT=-1"; echo "PRECOMMIT_STAMP_ERROR=closure-unreadable"
    echo "PRECOMMIT_STAMP=ERROR"; return 2
  fi
  if [ ! -r "$staged" ]; then
    echo "  [ERROR] staged list unreadable ($staged)"
    echo "PRECOMMIT_STAMP_COUNT=-1"; echo "PRECOMMIT_STAMP_ERROR=staged-unreadable"
    echo "PRECOMMIT_STAMP=ERROR"; return 2
  fi
  n=$(grep -c . "$closure")
  # 🔴 EMPTY IS NOT AGREEMENT. An empty closure intersects nothing, so a broken derivation would
  # read as "no closure input staged" and certify every commit silently — the same shape as the
  # defect this gate exists for, rebuilt inside the instrument.
  if [ "${n:-0}" -lt "$MIN_CLOSURE" ]; then
    echo "  [ERROR] the closure derivation returned ${n:-0} file(s), below the floor of $MIN_CLOSURE."
    echo "          A derivation that stops working must not read as 'nothing to check'."
    echo "PRECOMMIT_STAMP_COUNT=-1"; echo "PRECOMMIT_STAMP_ERROR=closure-too-small"
    echo "PRECOMMIT_STAMP=ERROR"; return 2
  fi
  if ! grep -qxF "$CONTROL_A" "$closure" || ! grep -qxF "$CONTROL_B" "$closure"; then
    echo "  [ERROR] the closure no longer contains its positive controls ($CONTROL_A, $CONTROL_B)."
    echo "          A search that cannot find what is certainly there cannot report an absence."
    echo "PRECOMMIT_STAMP_COUNT=-1"; echo "PRECOMMIT_STAMP_ERROR=closure-control-missing"
    echo "PRECOMMIT_STAMP=ERROR"; return 2
  fi
  # Exact WHOLE-LINE intersection (-x). Substring matching would sweep in solve.c.orig and any
  # path that merely contains a member's name.
  hits=$(grep -Fxf "$closure" "$staged")
  if [ -z "$hits" ]; then
    echo "PRECOMMIT_STAMP_COUNT=0"
    echo "PRECOMMIT_STAMP=NOT-APPLICABLE"; return 0
  fi
  count=$(printf '%s\n' "$hits" | grep -c .)
  if grep -qxF "$STAMP_PATH" "$staged"; then
    echo "  [ok]   $count reproduction-closure input(s) staged, and $STAMP_PATH moves with them"
    echo "PRECOMMIT_STAMP_COUNT=$count"
    echo "PRECOMMIT_STAMP=OK"; return 0
  fi
  echo
  echo "  ⚠ REPRODUCTION-CLOSURE INPUT STAGED WITHOUT ITS STAMP — $count file(s):"
  printf '%s\n' "$hits" | sed 's/^/        /'
  echo "    $STAMP_PATH is NOT in this commit, so as committed this tree will carry a"
  echo "    fingerprint describing a DIFFERENT tree — which is what the stamp's own header"
  echo "    forbids, and what public 6fc04532 did on 2026-09-21."
  echo "    ADVISORY: the commit proceeds. Fix with:"
  echo "        ./scripts/tr12_repro_gate.sh --stamp     (then stage the stamp INTO this commit)"
  echo "    Cheap check first — if the stamp is already current, just stage it:"
  echo "        ./scripts/tr12_repro_gate.sh --check"
  printf '%s\n' "$hits" | while IFS= read -r f; do [ -n "$f" ] && echo "PRECOMMIT_STAMP_INPUT=$f"; done
  echo "PRECOMMIT_STAMP_COUNT=$count"
  echo "PRECOMMIT_STAMP=MISSING-STAMP"; return 1
}

if [ "$MODE" = "--selftest" ]; then
  # The comparison on synthetic lists — no index, no repo state, milliseconds. This proves the
  # COMPARISON only; that the comparison is CALLED on the real index is proved by the end-to-end
  # harness (roae-private scripts/q673_commit_stamp_redtest.sh), because a selftest of a pure
  # function can never show that the function is reached.
  T=$(mktemp -d) || { echo "PRECOMMIT_STAMP_SELFTEST=FAIL"; exit 2; }
  trap 'rm -rf "$T"' EXIT
  f=0
  chk(){ # chk LABEL EXPECTED_TOKEN EXPECTED_RC OUTPUT RC
    local label="$1" tok="$2" erc="$3" out="$4" rc="$5"
    printf '%s\n' "$out" > "$T/_o"
    if grep -qx "$tok" "$T/_o" && [ "$rc" -eq "$erc" ]; then echo "  [ok] $label"; else
      echo "  [FAIL] $label — wanted $tok rc=$erc, got rc=$rc"; sed 's/^/         /' "$T/_o"; f=1; fi
  }
  printf '%s\n' solve.c verify.py solve.py scripts/tr12_repro.sh scripts/tr12_repro_gate.sh \
                documentation/CORRECTIONS.md documentation/VERIFY.md > "$T/closure"
  printf '%s\n' documentation/CORRECTIONS.md > "$T/s_input_only"
  printf '%s\n' documentation/CORRECTIONS.md "$STAMP_PATH" > "$T/s_input_and_stamp"
  printf '%s\n' documentation/DEVELOPMENT.md README.md > "$T/s_none"
  : > "$T/s_empty"
  printf '%s\n' "$STAMP_PATH" > "$T/s_stamp_only"
  printf '%s\n' solve.c.orig documentation/CORRECTIONS.md.bak xsolve.c > "$T/s_substring"
  printf '%s\n' solve.c verify.py > "$T/c_tiny"
  : > "$T/c_empty"
  printf '%s\n' a.md b.md c.md d.md e.md f.md > "$T/c_nocontrol"

  o=$(classify "$T/s_input_only" "$T/closure"); r=$?
  chk "a closure input with NO stamp -> MISSING-STAMP" 'PRECOMMIT_STAMP=MISSING-STAMP' 1 "$o" "$r"
  printf '%s\n' "$o" > "$T/_n"
  if grep -qx 'PRECOMMIT_STAMP_INPUT=documentation/CORRECTIONS.md' "$T/_n"; then
    echo "  [ok] the finding NAMES the file"; else echo "  [FAIL] the finding does not name the file"; f=1; fi

  o=$(classify "$T/s_input_and_stamp" "$T/closure"); r=$?
  chk "a closure input WITH the stamp -> OK" 'PRECOMMIT_STAMP=OK' 0 "$o" "$r"
  printf '%s\n' "$o" > "$T/_n"
  if grep -qx 'PRECOMMIT_STAMP=MISSING-STAMP' "$T/_n"; then
    echo "  [FAIL] staging the stamp still warned"; f=1; else echo "  [ok] staging the stamp is SILENT"; fi

  o=$(classify "$T/s_none"      "$T/closure"); r=$?
  chk "no closure input -> NOT-APPLICABLE"        'PRECOMMIT_STAMP=NOT-APPLICABLE' 0 "$o" "$r"
  o=$(classify "$T/s_empty"     "$T/closure"); r=$?
  chk "an EMPTY staged set -> NOT-APPLICABLE"     'PRECOMMIT_STAMP=NOT-APPLICABLE' 0 "$o" "$r"
  o=$(classify "$T/s_stamp_only" "$T/closure"); r=$?
  chk "the stamp ALONE -> NOT-APPLICABLE"         'PRECOMMIT_STAMP=NOT-APPLICABLE' 0 "$o" "$r"
  o=$(classify "$T/s_substring" "$T/closure"); r=$?
  chk "substring look-alikes do NOT match"        'PRECOMMIT_STAMP=NOT-APPLICABLE' 0 "$o" "$r"
  o=$(classify "$T/s_input_only" "$T/c_empty"); r=$?
  chk "an EMPTY closure -> ERROR, never NOT-APPLICABLE" 'PRECOMMIT_STAMP=ERROR' 2 "$o" "$r"
  o=$(classify "$T/s_input_only" "$T/c_tiny"); r=$?
  chk "a COLLAPSED closure -> ERROR"              'PRECOMMIT_STAMP=ERROR' 2 "$o" "$r"
  o=$(classify "$T/s_input_only" "$T/c_nocontrol"); r=$?
  chk "a closure missing its positive controls -> ERROR" 'PRECOMMIT_STAMP=ERROR' 2 "$o" "$r"
  o=$(classify "$T/s_input_only" "$T/absent"); r=$?
  chk "an ABSENT closure list -> ERROR"           'PRECOMMIT_STAMP=ERROR' 2 "$o" "$r"
  o=$(classify "$T/absent" "$T/closure"); r=$?
  chk "an ABSENT staged list -> ERROR"            'PRECOMMIT_STAMP=ERROR' 2 "$o" "$r"

  # THE LIVE CONTROL: the real extraction, against the real gate, must produce a real closure.
  # Without this the selftest proves only that a comparison works on files I wrote myself.
  # 🔴 RESOLVE FROM THIS SCRIPT'S OWN LOCATION, NOT THE CALLER'S cwd. The first version used
  # `git rev-parse --show-toplevel`, which answers about whatever repo the CALLER is standing in.
  # MEASURED 2026-09-21, by executing the ledger proof that invokes it: run from roae-private,
  # the live control looked for scripts/tr12_repro_gate.sh THERE, did not find it, and the
  # selftest reported FAIL — a green check turned red by the caller's working directory, which is
  # the same "the instrument measured the wrong subject" class this gate exists to catch, shipped
  # inside the gate itself. tr12_repro_gate.sh uses this idiom for exactly this reason (:40).
  # The REAL leg deliberately still uses the caller's repo: the index being committed belongs to
  # it, and .git/hooks is shared across linked worktrees.
  R=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
  if [ -n "$R" ] && [ -r "$R/$GATE_SRC" ]; then
    ( cd "$R" && awk '/^derived_inputs\(\)\{/{p=1} p{print} /^fingerprint_files\(\)\{/{if(p)exit}' "$GATE_SRC" > "$T/fns"
      . "$T/fns" 2>/dev/null && fingerprint_files 2>/dev/null | grep -v '^$' > "$T/live" )
    ln=$(grep -c . "$T/live" 2>/dev/null)
    if [ "${ln:-0}" -ge "$MIN_CLOSURE" ] && grep -qxF "$CONTROL_A" "$T/live" && grep -qxF "$STAMP_PATH" "$T/live"; then
      echo "  [FAIL] the live closure contains the STAMP ITSELF — it must be excluded or every"
      echo "         stamp-only commit would demand a stamp"; f=1
    elif [ "${ln:-0}" -ge "$MIN_CLOSURE" ] && grep -qxF "$CONTROL_A" "$T/live"; then
      echo "  [ok] live closure derived from the shipped gate: $ln files, controls present"
    else
      echo "  [FAIL] live closure derivation returned ${ln:-0} file(s) or lost its control"; f=1
    fi
  else
    echo "  [FAIL] live control could not run — $GATE_SRC not found from $(pwd)"; f=1
  fi

  [ "$f" -eq 0 ] && { echo "PRECOMMIT_STAMP_SELFTEST=PASS"; exit 0; }
  echo "PRECOMMIT_STAMP_SELFTEST=FAIL"; exit 1
fi

# ---- the real leg ------------------------------------------------------------------------
ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$ROOT" ] || ! cd "$ROOT"; then
  echo "  [ERROR] not inside a git work tree — the index cannot be read"
  echo "PRECOMMIT_STAMP_COUNT=-1"; echo "PRECOMMIT_STAMP_ERROR=not-in-git-repo"
  echo "PRECOMMIT_STAMP=ERROR"; exit 2
fi
STAGED=$(mktemp) || { echo "PRECOMMIT_STAMP_ERROR=mktemp-failed"; echo "PRECOMMIT_STAMP=ERROR"; exit 2; }
CLOSURE=$(mktemp) || { rm -f "$STAGED"; echo "PRECOMMIT_STAMP_ERROR=mktemp-failed"; echo "PRECOMMIT_STAMP=ERROR"; exit 2; }
FNS=$(mktemp) || { rm -f "$STAGED" "$CLOSURE"; echo "PRECOMMIT_STAMP_ERROR=mktemp-failed"; echo "PRECOMMIT_STAMP=ERROR"; exit 2; }
trap 'rm -f "$STAGED" "$CLOSURE" "$FNS"' EXIT

# DELETIONS ARE INCLUDED (D), like pre_commit_registry_gate.sh and unlike the generated gate:
# deleting a closure input moves the fingerprint exactly as editing one does. R reports the new
# path. An index that cannot be read is ERROR — a `git diff --cached` that fails and an empty
# index are indistinguishable by output alone, which is how a gate comes to certify nothing.
if ! git diff --cached --name-only --diff-filter=ACMRD > "$STAGED" 2>/dev/null; then
  echo "  [ERROR] could not read the index (git diff --cached failed)"
  echo "PRECOMMIT_STAMP_COUNT=-1"; echo "PRECOMMIT_STAMP_ERROR=staged-list-failed"
  echo "PRECOMMIT_STAMP=ERROR"; exit 2
fi
if [ ! -s "$STAGED" ]; then
  echo "PRECOMMIT_STAMP_COUNT=0"
  echo "PRECOMMIT_STAMP=NOT-APPLICABLE"; exit 0
fi

if [ ! -r "$GATE_SRC" ]; then
  echo "  [ERROR] $GATE_SRC is absent — closure membership is UNMEASURED, which is NOT the"
  echo "          same as 'no closure input staged'."
  echo "PRECOMMIT_STAMP_COUNT=-1"; echo "PRECOMMIT_STAMP_ERROR=gate-absent"
  echo "PRECOMMIT_STAMP=ERROR"; exit 2
fi
awk '/^derived_inputs\(\)\{/{p=1} p{print} /^fingerprint_files\(\)\{/{if(p)exit}' "$GATE_SRC" > "$FNS"
if ! grep -q '^derived_inputs()' "$FNS" || ! grep -q '^fingerprint_files()' "$FNS"; then
  echo "  [ERROR] could not extract derived_inputs()/fingerprint_files() from $GATE_SRC."
  echo "          The closure is DERIVED from that file on purpose; a copy here would rot."
  echo "PRECOMMIT_STAMP_COUNT=-1"; echo "PRECOMMIT_STAMP_ERROR=extraction-failed"
  echo "PRECOMMIT_STAMP=ERROR"; exit 2
fi
# shellcheck source=/dev/null
if ! . "$FNS"; then
  echo "  [ERROR] the extracted closure functions do not parse"
  echo "PRECOMMIT_STAMP_COUNT=-1"; echo "PRECOMMIT_STAMP_ERROR=extraction-unparseable"
  echo "PRECOMMIT_STAMP=ERROR"; exit 2
fi
fingerprint_files | grep -v '^$' > "$CLOSURE"

classify "$STAGED" "$CLOSURE"
exit $?
