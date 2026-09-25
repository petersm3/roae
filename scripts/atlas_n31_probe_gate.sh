#!/usr/bin/env bash
# atlas_n31_probe_gate.sh — PUSH-TIME ENFORCEMENT OF THE n=31 ATLAS PROBE (Q-737, 2026-09-25).
#
# WHAT IT CHECKS. TR-12 §12 publishes every atlas-derived figure with one reproduction command:
#     python3 solve.py --atlas-probe runs/20260906_kc_ladders_n31/atlas_n31.json
# tests.py pins that command at ATLAS_PROBE=PASS (Q-734), but nothing runs tests.py on the push
# path, so a commit that corrupted the atlas, or changed solve.py so that the probe no longer
# passed on it, could be pushed with nothing noticing. This gate runs the same two checks as that
# test, and pre_push_gate.sh runs it on every pushed sha:
#   1. DIGEST. The atlas bytes must match the ONE sha256 that reports/TR12_QUERY_PROGRAM.md pins
#      for "The atlas every §12 figure is read from". The digest is read from the report and not
#      restated here, so a PASS is a PASS on the published atlas and on nothing else.
#   2. PROBE. `solve.py --atlas-probe` on it must exit 0 and print exactly one ATLAS_PROBE= line,
#      ATLAS_PROBE=PASS, plus ATLAS_N=31, all as whole lines.
# Both legs always run and each reports its own token, so a FAIL says which one broke.
#
# WHY IT IS LIGHT, which is the reason for this design. The pre-push hook runs on a 2-core
# orchestrator. The probe reads only the tracked atlas and needs no build (tests.py measured
# ~0.5 s on the worker, 2026-09-24); the digest is one sha256 of 5,978,126 bytes. The measured
# cost is in the pre_push_gate.sh leg that calls this script.
#
# WHAT IT DOES NOT CHECK. It does not rebuild the atlas from the solver (that is the n=31 campaign
# itself, far beyond a hook), and it checks only the one n=31 atlas TR-12 §12 reads.
#
# Verdict tokens (grep -qx), each a WHOLE line: ATLAS_N31_GATE=PASS|FAIL|ERROR, plus
# ATLAS_N31_DIGEST=PASS|FAIL, ATLAS_N31_PROBE=PASS|FAIL|ERROR, and ATLAS_N31_GATE_ERROR=<cause> on
# ERROR (bad-args | no-solve-py | no-tr12 | no-atlas | no-python3 | no-sha256sum | pin-count).
# Exit 0 PASS / 1 FAIL / 2 ERROR. A probe that could not score the atlas is ERROR, never PASS.
# `--selftest` corrupts COPIES of the atlas and proves each leg red, then the real atlas green:
# ATLAS_N31_GATE_SELFTEST=PASS|FAIL.
#
# usage: atlas_n31_probe_gate.sh [--atlas PATH] [--selftest]
#   --atlas PATH   probe PATH instead of the tracked atlas (the digest leg still compares it with
#                  TR-12's pin, so any file but the published atlas is a FAIL)
set -uo pipefail
ATLAS_REL=runs/20260906_kc_ladders_n31/atlas_n31.json
ATLAS=""; SELFTEST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --atlas)    [ $# -ge 2 ] || { echo "ATLAS_N31_GATE_ERROR=bad-args"; echo "ATLAS_N31_GATE=ERROR"; exit 2; }
                ATLAS=$2; shift 2 ;;
    --selftest) SELFTEST=1; shift ;;
    *) echo "usage: $0 [--atlas PATH] [--selftest]"
       echo "ATLAS_N31_GATE_ERROR=bad-args"; echo "ATLAS_N31_GATE=ERROR"; exit 2 ;;
  esac
done
case "$ATLAS" in ''|/*) ;; *) ATLAS="$PWD/$ATLAS" ;; esac   # before the cd below
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || { echo "ATLAS_N31_GATE_ERROR=no-solve-py"; echo "ATLAS_N31_GATE=ERROR"; exit 2; }

err(){ echo "  [ERROR] $2"; echo "ATLAS_N31_GATE_ERROR=$1"; echo "ATLAS_N31_GATE=ERROR"; return 2; }

# run_gate <atlas path> -> prints the verdict lines; returns 0/1/2
run_gate(){
  local atlas=$1 pin npin got dig out rc nprobe ptok probe
  [ -f solve.py ] || { err no-solve-py "no solve.py under $ROOT"; return 2; }
  [ -f reports/TR12_QUERY_PROGRAM.md ] || { err no-tr12 "no reports/TR12_QUERY_PROGRAM.md under $ROOT"; return 2; }
  [ -f "$atlas" ] || { err no-atlas "atlas not found: $atlas"; return 2; }
  command -v python3 >/dev/null 2>&1 || { err no-python3 "python3 not on PATH"; return 2; }
  command -v sha256sum >/dev/null 2>&1 || { err no-sha256sum "sha256sum not on PATH"; return 2; }
  # The same pin tests.py reads. Exactly one, or the subject is not established.
  pin=$(grep -oE 'The atlas every §12 figure is read from [|][^|]*sha256 `[0-9a-f]{64}`' reports/TR12_QUERY_PROGRAM.md \
        | grep -oE '[0-9a-f]{64}')
  npin=$(printf '%s' "$pin" | grep -c .)
  [ "$npin" = 1 ] || { err pin-count "TR-12 must pin exactly one atlas digest; found $npin"; return 2; }
  got=$(sha256sum "$atlas" | cut -c1-64)
  if [ "$got" = "$pin" ]; then dig=PASS
  else dig=FAIL; echo "  [FAIL] atlas sha256 $got is not the digest TR-12 pins ($pin)"; fi
  out=$(python3 solve.py --atlas-probe "$atlas" 2>&1); rc=$?
  # Exactly one ATLAS_PROBE= line: a producer that emits its own key twice is refused, not read.
  nprobe=$(printf '%s\n' "$out" | grep -cE '^ATLAS_PROBE=')
  ptok=$(printf '%s\n' "$out" | grep -E '^ATLAS_PROBE=' | head -1)
  if [ "$nprobe" = 1 ] && [ "$rc" -eq 0 ] && [ "$ptok" = ATLAS_PROBE=PASS ] \
     && [ "$(printf '%s\n' "$out" | grep -cx 'ATLAS_N=31')" = 1 ]; then probe=PASS
  elif [ "$nprobe" = 1 ] && [ "$rc" -eq 1 ] && [ "$ptok" = ATLAS_PROBE=FAIL ]; then probe=FAIL
    echo "  [FAIL] solve.py --atlas-probe scored the atlas FAIL; its failing legs:"
    printf '%s\n' "$out" | grep -E '^[A-Z][A-Z0-9_]*=FAIL' | head -8 | sed 's/^/           /'
  else probe=ERROR
    echo "  [ERROR] solve.py --atlas-probe did not score the atlas (rc=$rc, ${nprobe} ATLAS_PROBE= line(s), first '${ptok:-<none>}')"
    printf '%s\n' "$out" | grep -E '^ERROR|^Traceback|Error:' | head -3 | sed 's/^/           /'
  fi
  echo "ATLAS_N31_DIGEST=$dig"
  echo "ATLAS_N31_PROBE=$probe"
  if [ "$probe" = ERROR ]; then echo "ATLAS_N31_GATE=ERROR"; return 2; fi
  if [ "$dig" = FAIL ] || [ "$probe" = FAIL ]; then echo "ATLAS_N31_GATE=FAIL"; return 1; fi
  echo "  [ok]   the published n=31 atlas has TR-12's digest and solve.py --atlas-probe scores it PASS"
  echo "ATLAS_N31_GATE=PASS"; return 0
}

if [ "$SELFTEST" -eq 1 ]; then
  f=0
  T=$(mktemp -d "${TMPDIR:-/tmp}/atlas_n31_st.XXXXXX") || { echo "ATLAS_N31_GATE_SELFTEST=FAIL"; exit 1; }
  trap 'rm -rf "$T"' EXIT
  chk(){ if eval "$2"; then echo "  [ok]   $1"; else echo "  [FAIL] $1"; f=1; fi; }
  # GREEN: the real, tracked atlas.
  out=$(run_gate "$ATLAS_REL"); rc=$?
  chk "the tracked atlas -> PASS (rc 0), both legs PASS" '[ "$rc" -eq 0 ] && grep -qx ATLAS_N31_GATE=PASS <<<"$out" && grep -qx ATLAS_N31_DIGEST=PASS <<<"$out" && grep -qx ATLAS_N31_PROBE=PASS <<<"$out"'
  # RED 1: a CORRUPTED COPY -- one class-mass cell of layer 3 bumped by 1 (the tests.py mutant).
  # The probe must go red ON ITS OWN, not only the digest: that is what makes the probe leg
  # load-bearing rather than shadowed by the digest.
  python3 - "$ATLAS_REL" "$T/corrupt.json" <<'PY' || f=1
import json, sys
a = json.load(open(sys.argv[1]))
c = a["layers"][3]["by_class"]; old = c["d1"]
c["d1"] = (str if isinstance(old, str) else int)(int(old) + 1)
json.dump(a, open(sys.argv[2], "w"))
PY
  out=$(run_gate "$T/corrupt.json"); rc=$?
  chk "a corrupted copy (layer-3 d1 + 1) -> FAIL (rc 1)" '[ "$rc" -eq 1 ] && grep -qx ATLAS_N31_GATE=FAIL <<<"$out"'
  chk "...and the PROBE leg itself is red on it"         'grep -qx ATLAS_N31_PROBE=FAIL <<<"$out"'
  chk "...and never PASS"                                '! grep -qx ATLAS_N31_GATE=PASS <<<"$out"'
  # RED 2: a digest-only change. One trailing newline leaves every figure the same, so the probe
  # stays PASS (asserted: the precondition) and ONLY the digest leg can catch it.
  cp "$ATLAS_REL" "$T/newline.json" && printf '\n' >> "$T/newline.json"
  out=$(run_gate "$T/newline.json"); rc=$?
  chk "a byte-changed copy with the same figures -> FAIL via the digest (probe PASS, digest FAIL)" '[ "$rc" -eq 1 ] && grep -qx ATLAS_N31_GATE=FAIL <<<"$out" && grep -qx ATLAS_N31_PROBE=PASS <<<"$out" && grep -qx ATLAS_N31_DIGEST=FAIL <<<"$out"'
  # RED 3: a truncated copy the probe cannot parse -> ERROR, never PASS.
  head -c 100000 "$ATLAS_REL" > "$T/trunc.json"
  out=$(run_gate "$T/trunc.json"); rc=$?
  chk "a truncated copy -> ERROR (rc 2), not PASS" '[ "$rc" -eq 2 ] && grep -qx ATLAS_N31_GATE=ERROR <<<"$out" && grep -qx ATLAS_N31_PROBE=ERROR <<<"$out"'
  # RED 4: no atlas at all -> ERROR.
  out=$(run_gate "$T/absent.json"); rc=$?
  chk "an absent atlas -> ERROR (rc 2)" '[ "$rc" -eq 2 ] && grep -qx ATLAS_N31_GATE_ERROR=no-atlas <<<"$out"'
  [ "$f" -eq 0 ] && { echo "ATLAS_N31_GATE_SELFTEST=PASS"; exit 0; } || { echo "ATLAS_N31_GATE_SELFTEST=FAIL"; exit 1; }
fi

echo "== n=31 ATLAS PROBE: TR-12's digest and solve.py --atlas-probe on ${ATLAS:-$ATLAS_REL} =="
run_gate "${ATLAS:-$ATLAS_REL}"; exit $?
