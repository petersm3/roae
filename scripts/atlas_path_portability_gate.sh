#!/usr/bin/env bash
# atlas_path_portability_gate.sh — two CORRECT runs of --kc-scan, in different directories, must
# produce a BYTE-IDENTICAL atlas.
#
# 🔴 Q-92. The atlas embedded ABSOLUTE ladder paths, so the artifact the TR-12 query program exists
# to produce could never be compared across hosts by a plain sha256sum. Measured before the fix:
#     fdir = "/tmp/tr12repro.M2ZJcc/f"
# and two runs differing only in their mktemp directory produced different digests.
#
# 🔴 WHY THIS WAS INVISIBLE FOR SO LONG. tr12_repro.sh's normaliser rewrites those fields to <FDIR>
# before diffing, so the battery was unaffected and stayed green -- the harness HID the defect. A
# check that lives inside the harness could not have caught it. This one builds the artifact twice
# and compares the bytes, which is the property the query program actually needs.
#
# Verdict: ATLAS_PATH_PORTABLE=PASS|FAIL|ERROR
# ERROR (exit 2) is not a defect report: it means the gate could not establish its own subject
# (see the SOLVE currency guard below) and therefore measured nothing.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
SOLVE=${SOLVE:-}
if [ -z "$SOLVE" ]; then
  SOLVE=$(mktemp -d)/solve
  gcc -O2 -pthread -fopenmp -DGIT_HASH='"gate"' -o "$SOLVE" solve.c -lm -lz 2>/dev/null \
    || { echo "  [FAIL] cannot build solve.c -- this gate measured NOTHING"; echo "ATLAS_PATH_PORTABLE=FAIL"; exit 2; }
else
  # 🔴 EXECUTABLE IS NOT CURRENT -- and this arm did not even check THAT. The build arm above
  # compiles the committed solve.c seconds before use and is safe by construction; $SOLVE is a bare
  # PATH taken from the environment and, before this guard, was used unexamined. pre_push_compile_gate.sh:210
  # hands in a binary it just built, but `SOLVE=./solve bash scripts/atlas_path_portability_gate.sh`
  # by hand points the gate at whatever artifact is lying in the tree.
  #
  # This gate is unusually easy to fool in the SAFE direction, which is why the guard matters here:
  # it compares one binary against ITSELF in two directories, so a stale binary that embedded
  # absolute paths CONSISTENTLY would report PASS and certify a property of an engine nobody is
  # shipping. Q-92 is the defect it exists to keep fixed.
  #
  # Added 2026-09-08 after scripts/resume_budget_infinity_gate.sh -- same `${VAR:-}`-names-a-path
  # shape -- reported FAIL, an UNDERCOUNT PRESENTED AS A COMPLETE ENUMERATION, against a ./solve two
  # days older than 779fff4c, the commit that fixed exactly that. Stale -> FAIL, HEAD -> PASS.
  #
  # ERROR, NEVER FAIL: an unestablished subject is not a defect. This file had no ERROR token at
  # all -- every exit was FAIL, including the two "measured NOTHING" ones -- so ATLAS_PATH_PORTABLE=ERROR
  # is introduced here and recorded in the Verdict line above. Consumers use
  # `grep -qx 'ATLAS_PATH_PORTABLE=PASS'` or the exit status; neither reads ERROR as agreement.
  #
  # Called INSIDE an `if`: lib_binary_currency.sh's foreign-sha arm ends in a `grep -vxF` that exits
  # 1 in the NORMAL case, so a bare call under this file's pipefail would abort mid-function with an
  # empty signal.
  [ -x "$SOLVE" ] || { echo "  [ERROR] SOLVE=$SOLVE is not executable"; echo "ATLAS_PATH_PORTABLE=ERROR"; exit 2; }
  if [ "${ATLAS_PORTABILITY_ALLOW_STALE-}" != "1" ]; then
    . "$(cd "$(dirname "$0")" && pwd)/lib_binary_currency.sh"
    # cwd is the repo root (the cd on the line above SOLVE=), so bare `solve.c` is unambiguous.
    if ! solve_binary_currency "$SOLVE" solve.c; then
      echo "  [ERROR] $BINCUR_MSG" >&2
      echo "          (set ATLAS_PORTABILITY_ALLOW_STALE=1 to override, deliberately.)" >&2
      echo "ATLAS_PATH_PORTABLE=ERROR"; exit 2
    fi
  fi
fi
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
for d in A B; do
  mkdir -p "$W/$d"
  "$SOLVE" --kc-build   "$W/$d/f" --f1-pairs 9 >/dev/null 2>&1
  "$SOLVE" --kc-g-build "$W/$d/g" --f1-pairs 9 >/dev/null 2>&1
  "$SOLVE" --kc-t-build "$W/$d/f" "$W/$d/t"    >/dev/null 2>&1
  "$SOLVE" --kc-scan "$W/$d/f" "$W/$d/g" "$W/$d/atlas.json" --kc-tdir "$W/$d/t" --kc-raw >/dev/null 2>&1
done
[ -s "$W/A/atlas.json" ] && [ -s "$W/B/atlas.json" ] || {
  echo "  [FAIL] one or both atlases were not produced -- this gate measured NOTHING"
  echo "ATLAS_PATH_PORTABLE=FAIL"; exit 2; }
a=$(sha256sum "$W/A/atlas.json" | cut -d' ' -f1)
b=$(sha256sum "$W/B/atlas.json" | cut -d' ' -f1)
if [ "$a" != "$b" ]; then
  echo "  [FAIL] two correct runs produced different atlases -- the artifact is not portable"
  echo "         A $a"
  echo "         B $b"
  diff <(python3 -m json.tool "$W/A/atlas.json" 2>/dev/null) \
       <(python3 -m json.tool "$W/B/atlas.json" 2>/dev/null) | head -6 | sed 's/^/         /'
  echo "ATLAS_PATH_PORTABLE=FAIL"; exit 1
fi
echo "  [ok]   two runs in different directories produced a byte-identical atlas ($(printf %.12s "$a")…)"
echo "ATLAS_PATH_PORTABLE=PASS"
