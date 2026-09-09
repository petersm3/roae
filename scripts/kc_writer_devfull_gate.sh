#!/usr/bin/env bash
# kc_writer_devfull_gate.sh — a KC artifact writer that cannot write must SAY SO.
#
# 🔴 WHY THIS EXISTS, AND WHY IT IS A GATE RATHER THAN A FIX.
# On 2026-09-02 an external review (Codex KC04 #3, adjudicated by Fable) measured every KC writer
# against /dev/full and found that all of them announced success: --kc-scan printed "atlas written"
# and KC_SCAN=OK at rc 0, the chunk writer KC_SCAN_CHUNK=OK at rc 0, and every certificate writer
# printed "certificate written", with nothing on disk. The adjudication recorded "Fixes NOT landed,
# NOT queued". On 2026-09-04 ONE writer -- the merge -- was fixed, annotated in solve.c as "the KC04
# #3 sibling for this one writer", and the other six were left with no backlog row at all.
#
# A week later a fresh review (RCQ01 F3, 2026-09-09) found the same thing again, from scratch, and
# it cost a full review cycle to re-learn. The fix is now a shared helper (kc_h_close_artifact) at
# every site. THIS FILE is the part that makes that durable: without an executable check, "we fixed
# the class" is a claim, and the last claim of that kind survived four days.
#
# WHAT IT ASSERTS, per writer: red to /dev/full (nonzero exit, and a FAIL token where the writer has
# one), and green to a real file. BOTH HALVES ARE REQUIRED. A gate that only checked the red half
# would pass on an engine that refused to write anything at all.
#
# Verdict, whole line, grep -qx-able:  KC_WRITER_DEVFULL_GATE=PASS|FAIL|ERROR
# ERROR is NOT a pass. A gate that could not build the engine or the ladders measured nothing, and
# nothing is not a clean result.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "KC_WRITER_DEVFULL_GATE=ERROR"; exit 2; }
ROOT=$(pwd -P)
WORK=$(mktemp -d "${TMPDIR:-/tmp}/kcwdf.XXXXXX") || { echo "KC_WRITER_DEVFULL_GATE=ERROR"; exit 2; }
trap 'rm -rf "$WORK"' EXIT
fails=0; checks=0
say(){ printf '  %s\n' "$*"; }
die(){ printf '  [ERROR] %s\n' "$*"; echo "KC_WRITER_DEVFULL_GATE=ERROR"; exit 2; }

# ---- the engine ------------------------------------------------------------------------------
SOLVE=${SOLVE:-}
if [ -z "$SOLVE" ]; then
  SS=$(sha256sum "$ROOT/solve.c" | cut -d' ' -f1) || die "cannot digest solve.c"
  SOLVE=$WORK/solve
  gcc -O2 -pthread -fopenmp -DGIT_HASH='"devfull-gate"' -DGIT_BRANCH='"HEAD"' \
      -DSOURCE_SHA="\"$SS\"" -o "$SOLVE" "$ROOT/solve.c" -lm -lz 2>"$WORK/build.err" \
      || { sed 's/^/        /' "$WORK/build.err" >&2; die "solve.c did not compile"; }
fi
[ -x "$SOLVE" ] || die "no engine at $SOLVE"

# ---- the n=9 universe ------------------------------------------------------------------------
F=$WORK/f; G=$WORK/g; T=$WORK/t; mkdir -p "$F" "$G" "$T"
"$SOLVE" --kc-build   "$F" --f1-pairs 9 >"$WORK/bf.log" 2>&1 || die "--kc-build failed"
"$SOLVE" --kc-g-build "$G" --f1-pairs 9 >"$WORK/bg.log" 2>&1 || die "--kc-g-build failed"
"$SOLVE" --kc-t-build "$F" "$T"         >"$WORK/bt.log" 2>&1 || die "--kc-t-build failed"

# An explicit n=9 walk. The built-in KW walk needs a full-31 ladder, so it cannot be used here.
# If this string ever stops being a valid walk over the n=9 subset the GREEN legs go red and the
# gate reports FAIL -- it does not quietly skip, which is the failure mode this file exists to stop.
W="1,32,16,2,8,4,55,59,62,31,47,61,45,18,51,12,33,30"

# ---- one writer, both directions ---------------------------------------------------------------
# probe NAME FAILTOKEN -- cmd...   ; %OUT% is replaced by the destination
probe(){
  local name="$1" tok="$2"; shift 3
  local red green rc out
  checks=$((checks+1))
  # RED: destination cannot be written
  local -a cmd=(); for a in "$@"; do cmd+=("${a//%OUT%//dev/full}"); done
  out=$("${cmd[@]}" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then
    say "[FAIL] $name: exit 0 writing to /dev/full — it reported success for an artifact that does not exist"
    fails=$((fails+1)); red=0
  elif [ -n "$tok" ] && ! printf '%s\n' "$out" | grep -qx "$tok"; then
    say "[FAIL] $name: nonzero exit but no whole-line $tok — a wrapper grepping tokens still reads it as clean"
    fails=$((fails+1)); red=0
  else
    red=1
  fi
  # GREEN: a real file must still work, or the red result above proves nothing
  local dst="$WORK/out_${name}"
  cmd=(); for a in "$@"; do cmd+=("${a//%OUT%/$dst}"); done
  out=$("${cmd[@]}" 2>&1); rc=$?
  if [ "$rc" -ne 0 ]; then
    say "[FAIL] $name: exit $rc writing to a REAL file — the red leg above is not evidence of a check"
    printf '%s\n' "$out" | tail -3 | sed 's/^/         /'
    fails=$((fails+1)); green=0
  elif [ ! -s "$dst" ]; then
    say "[FAIL] $name: exit 0 to a real file but the file is empty"
    fails=$((fails+1)); green=0
  else
    green=1
  fi
  [ "$red" = 1 ] && [ "$green" = 1 ] && say "[ok]   $name: red on /dev/full, green on a real file"
}

echo "== KC artifact writers: does a failed write reach the caller? =="
probe scan_atlas   'KC_SCAN=FAIL'       -- "$SOLVE" --kc-scan "$F" "$G" %OUT% --kc-tdir "$T" --kc-raw
probe scan_chunk   'KC_SCAN_CHUNK=FAIL' -- "$SOLVE" --kc-scan "$F" "$G" %OUT% --kc-tdir "$T" --kc-raw --kc-layers 0 4
probe profile_tsv  'KC_PROFILE=FAIL'    -- "$SOLVE" --kc-profile "$F" "$G" "$W" --kc-tsv %OUT%
probe t_cert       ''                   -- "$SOLVE" --kc-t-cert %OUT%
probe o3_cert      ''                   -- "$SOLVE" --kc-o3-cert "$F" "$G" "$W" --kc-cert-out %OUT%
probe arr_cert     ''                   -- "$SOLVE" --check-arrangement KW --cert-out %OUT%

# The merge was the ONE writer fixed in 2026-09-04, and is now routed through the same helper as the
# rest. It is here as the control that the shared helper did not regress the site that already worked.
C0=$WORK/c0.json; C1=$WORK/c1.json
"$SOLVE" --kc-scan "$F" "$G" "$C0" --kc-tdir "$T" --kc-layers 0 4 >/dev/null 2>&1
"$SOLVE" --kc-scan "$F" "$G" "$C1" --kc-tdir "$T" --kc-layers 4 9 >/dev/null 2>&1
if [ -s "$C0" ] && [ -s "$C1" ]; then
  probe scan_merge 'KC_SCAN_MERGE=FAIL' -- "$SOLVE" --kc-scan-merge "$F" "$G" %OUT% "$C0" "$C1" --kc-tdir "$T"
else
  die "could not produce two chunks for the merge control — the control did not run"
fi

# 🔴 A CHECK THAT MEASURED NOTHING MUST ERROR. If the probe list were emptied, or every probe
# skipped, `fails` would be 0 and this would otherwise report PASS.
[ "$checks" -ge 7 ] || die "only $checks writer(s) probed, expected at least 7 — this measured almost nothing"

echo "KC_WRITER_DEVFULL_CHECKS=$checks"
echo "KC_WRITER_DEVFULL_FAILS=$fails"
[ "$fails" -eq 0 ] && { echo "KC_WRITER_DEVFULL_GATE=PASS"; exit 0; }
echo "KC_WRITER_DEVFULL_GATE=FAIL"; exit 1
