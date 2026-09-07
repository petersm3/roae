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
# Verdict: ATLAS_PATH_PORTABLE=PASS|FAIL
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
SOLVE=${SOLVE:-}
if [ -z "$SOLVE" ]; then
  SOLVE=$(mktemp -d)/solve
  gcc -O2 -pthread -fopenmp -DGIT_HASH='"gate"' -o "$SOLVE" solve.c -lm -lz 2>/dev/null \
    || { echo "  [FAIL] cannot build solve.c -- this gate measured NOTHING"; echo "ATLAS_PATH_PORTABLE=FAIL"; exit 2; }
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
