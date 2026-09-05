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

# The fingerprint covers everything that can invalidate a PASS: the engine (solve.c), the two
# Python files the battery CALLS as second implementations (verify.py, solve.py), the driver, the
# expected blocks, and THIS GATE ITSELF. Including the gate is deliberate -- a weakened gate still
# reporting its old PASS is the silent failure this whole exercise is about.
#
# verify.py and solve.py were MISSING from this list until 2026-08-24, found the same day by
# landing the Q6 reading-(B) oracle INTO verify.py: the battery began depending on a file whose
# change the gate could not see. A fingerprint is only as good as its enumeration of inputs, and
# the way that goes wrong is a new input, not a changed one. The stamp is excluded or it could
# never be stable.
fingerprint(){
  { sha256sum solve.c verify.py solve.py scripts/tr12_repro.sh scripts/tr12_repro_gate.sh 2>/dev/null
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
  echo "TR12_REPRO_GATE_CURRENT=NO (solve.c, verify.py, solve.py, tr12_repro.sh, this gate, or an expected block changed since the last recorded PASS)"
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

# D5-01 leg (2026-09-05). THIS GATE ONLY EVER RUNS --n9, so it can never exercise the full-31 path
# on its own -- and the full-31 path is precisely where a2_q1c was guaranteed to FAIL after burning
# 3-5 h. Wiring the skip guard's own red/green gate in here is the only way an n=9 pre-push check
# protects a full-31 run. Fails the whole gate: a broken or moved guard means the next full-31
# battery is a scheduled 3-5 h failure.
if ! bash ./scripts/d5_01_q1c_skip_gate.sh; then
  echo "  [FAIL] the a2_q1c full-31 skip guard is broken or has moved (see message above)"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# MQ1A-3 leg (2026-09-05). Same reasoning: the a2_q3_reader row is exact at n=9 (N < 2^53) and was
# a 53-bit comparison at full-31, so an n=9 battery can never see that defect. The reader's own
# full-31-magnitude red/green gate runs here instead (0.2 s). Fails the whole gate.
if ! bash ./scripts/q3_reader_exactness_gate.sh; then
  echo "  [FAIL] the a2_q3_reader exact-identity row can no longer fail at full-31 magnitude (see message above)"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# Sibling sweep (2026-09-05, MQ1A adjudication): the two other full-31-only verdict gates already in
# the tree were wired into NOTHING -- each could be run by hand and was run by nobody. Same class,
# same remedy; 1.1 s and 0.3 s.
if ! bash ./scripts/a2_slot_verdict_gate.sh | grep -qx 'A2_SLOT_VERDICT=OK'; then
  echo "  [FAIL] the A2 slot / verdict-exit gate (MQ1 §2a/§2d) did not report OK"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi
if ! bash ./scripts/xa_exact_verdict_gate.sh | grep -qx 'XA_EXACT_VERDICT=OK'; then
  echo "  [FAIL] the XA exact-verdict gate (MQ1 §4) did not report OK"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

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
