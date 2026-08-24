#!/usr/bin/env bash
#
# tr12_repro_gate.sh — does the COMMITTED tree still reproduce its own published battery?
#
# WHY THIS EXISTS. On 2026-08-24 a clean checkout was found to be failing its own flagship
# reproduction battery — TR12_REPRO=FAIL, 13 of 56 rows — and had been for two days. Nothing
# noticed, because nothing ever RAN it. The repo's own checks verify that working trees are
# COMMITTED; none verified that the committed tree REPRODUCES. An engine commit can therefore
# silently invalidate the published reproduction path while every instrument reports green.
#
# The specific failure was instructive and is the reason this gate builds the way it does: the
# provenance trailer had just been correctly changed to report the branch actually built, but the
# build line PUBLISHED in documentation/VERIFY.md defines no branch, so a reproducer's binary
# emitted `branch=unknown` against expected blocks that diffed the field verbatim. The defect was
# only visible to someone building the way a STRANGER builds.
#
# So this gate does not use its own build line. It EXTRACTS the one published in
# documentation/VERIFY.md and runs that, verbatim. If the doc's line rots — a missing -lm, a
# renamed flag — this gate fails on it, which is the GAP-1 class the execution lane was built for.
# A curated copy of the build line here would rebuild exactly the blind spot being closed.
#
# Verdict token:  TR12_REPRO_GATE=PASS|FAIL   (grep -qx it; never gate on output shape)
#
# Usage:
#   scripts/tr12_repro_gate.sh            # build + run the n=9 battery, print the verdict
#   scripts/tr12_repro_gate.sh --stamp    # ...and on PASS, record the input fingerprint
#   scripts/tr12_repro_gate.sh --check    # fingerprint only: has anything changed since that PASS?
#
# --check is the cheap leg (milliseconds, no build) that other checks call on every run. The full
# gate is ~2 minutes on two cores and needs no ladder data, no disk and no network.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
STAMP=scripts/tr12_expected/_GATE_STAMP.txt
MODE=${1:-run}

# The fingerprint covers exactly the four things that can invalidate a PASS: the engine, the
# driver, the expected blocks, and THIS GATE ITSELF. Including the gate is deliberate -- a
# weakened gate that still reports its old PASS is the silent failure this whole exercise is
# about. The stamp is excluded or it could never be stable.
fingerprint(){
  { sha256sum solve.c scripts/tr12_repro.sh scripts/tr12_repro_gate.sh 2>/dev/null
    find scripts/tr12_expected -type f ! -name '_GATE_STAMP.txt' -print0 2>/dev/null \
      | sort -z | xargs -0 sha256sum 2>/dev/null
  } | sha256sum | cut -d' ' -f1
}

FP=$(fingerprint)

if [ "$MODE" = "--check" ]; then
  if [ ! -f "$STAMP" ]; then
    echo "TR12_REPRO_GATE_CURRENT=UNKNOWN (no stamp — run scripts/tr12_repro_gate.sh --stamp)"; exit 1
  fi
  WANT=$(awk -F= '/^fingerprint=/{print $2}' "$STAMP")
  if [ "$FP" = "$WANT" ]; then
    echo "TR12_REPRO_GATE_CURRENT=YES"; exit 0
  fi
  echo "TR12_REPRO_GATE_CURRENT=NO (solve.c, tr12_repro.sh or an expected block changed since the last recorded PASS)"
  exit 1
fi

# ---- extract the PUBLISHED build line, do not invent one -------------------------------------
BUILD=$(grep -m1 -E '^gcc .*solve\.c' documentation/VERIFY.md)
if [ -z "$BUILD" ]; then
  echo "  [FAIL] no 'gcc ... solve.c' line found in documentation/VERIFY.md — the published build line is the input to this gate"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
printf '  build line (from documentation/VERIFY.md): %s\n' "$BUILD"
# run it verbatim, only redirecting the output binary into the scratch dir
if ! ( eval "${BUILD/-o solve/-o $WORK/solve}" ) >"$WORK/build.log" 2>&1; then
  # Show the ERRORS, not the first ten lines. A link failure (-lm dropped) lands at the END of
  # the log behind pages of warnings, and the first negative-control run printed warnings only.
  echo "  [FAIL] the PUBLISHED build line does not build:"
  grep -E 'error:|undefined reference|collect2|ld returned' "$WORK/build.log" | head -10 \
    || tail -10 "$WORK/build.log"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi
echo "  [ok] published build line builds"

if ! ./scripts/tr12_repro.sh --n9 --solve "$WORK/solve" --out "$WORK/out" >"$WORK/repro.log" 2>&1; then
  :   # non-zero exit is expected on FAIL; the token below is the authority
fi
if grep -qx 'TR12_REPRO=PASS' "$WORK/out/VERDICTS.txt" 2>/dev/null; then
  sed -n 's/^rows=/  /p' "$WORK/repro.log" | tail -1
  echo "  [ok] TR12_REPRO=PASS"
  if [ "$MODE" = "--stamp" ]; then
    { echo "# Recorded by scripts/tr12_repro_gate.sh --stamp. Proves the committed tree REPRODUCED,"
      echo "# not merely that it was committed. Re-stamp in the SAME commit as any solve.c,"
      echo "# tr12_repro.sh or expected-block change, or --check will correctly report NO."
      echo "fingerprint=$FP"
    } > "$STAMP"
    echo "  [ok] stamped $STAMP"
  fi
  echo "TR12_REPRO_GATE=PASS"; exit 0
fi
echo "  [FAIL] the committed tree does not reproduce its own published battery:"
grep -E '^TR12_[A-Z0-9_]*=FAIL' "$WORK/out/VERDICTS.txt" 2>/dev/null | head -15
sed -n 's/^rows=/  /p' "$WORK/repro.log" | tail -1
echo "TR12_REPRO_GATE=FAIL"; exit 1
