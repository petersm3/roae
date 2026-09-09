#!/usr/bin/env bash
# group_c_n9_rehearsal_gate.sh — run every post-scan consumer at n=9 BEFORE the full-31 scan.
#
# 🔴 WHY. Group C is nine query families of pure post-processing on a tens-of-KB JSON: milliseconds,
# $0. It runs AFTER a scan whose wall is 7-14 days on Premium SSD v2 or 16-33 days on a P60. If one
# family needs a field the scan did not emit, the remedy is ANOTHER FULL SCAN. QUERY_INVENTORY has
# said "and it should be" rehearsed since it was written; it had never been done, and the fixture
# path it names (fixtures/kc_n9/) does not exist, so nobody could have followed the instruction.
#
# 🔴 GATE 3 IS THE ONE WITH TEETH. A green n=9 rehearsal does NOT prove the full-31 run works --
# some verdicts only exist at n == 31. Measured 2026-09-09: `if "a5" in sel and n == 31:`
# (solve.py) skips the branch AND EMITS NOTHING at smaller n, so a reader of the n=9 VERDICTS.txt
# sees fourteen tokens with no way to know a fifteenth exists and has never run. atlas_orbit_columns
# and atlas_orbit_membership have 0 references in tests.py. This gate therefore RATCHETS the number
# of n==31 guards in the consumer: a NEW one fails until it is declared here with its coverage.
#
# Verdict, whole line:  GROUPC_REHEARSAL=PASS|FAIL|ERROR
# ERROR is not a pass. A rehearsal that could not build an atlas measured nothing.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "GROUPC_REHEARSAL=ERROR"; exit 2; }
ROOT=$(pwd -P)
WORK=$(mktemp -d "${TMPDIR:-/tmp}/gcreh.XXXXXX") || { echo "GROUPC_REHEARSAL=ERROR"; exit 2; }
trap 'rm -rf "$WORK"' EXIT
fails=0
say(){ printf '  %s\n' "$*"; }
die(){ printf '  [ERROR] %s\n' "$*"; echo "GROUPC_REHEARSAL=ERROR"; exit 2; }

# ---- GATE 1: can the rehearsal run at all -------------------------------------------------------
SOLVE=${SOLVE:-}
if [ -z "$SOLVE" ]; then
  SS=$(sha256sum "$ROOT/solve.c" | cut -d' ' -f1) || die "cannot digest solve.c"
  SOLVE=$WORK/solve
  gcc -O2 -pthread -fopenmp -DGIT_HASH='"groupc-gate"' -DGIT_BRANCH='"HEAD"' \
      -DSOURCE_SHA="\"$SS\"" -o "$SOLVE" "$ROOT/solve.c" -lm -lz 2>"$WORK/build.err" \
      || { sed 's/^/        /' "$WORK/build.err" >&2; die "solve.c did not compile"; }
fi
[ -x "$SOLVE" ] || die "no engine at $SOLVE"

F=$WORK/f; G=$WORK/g; T=$WORK/t; mkdir -p "$F" "$G" "$T"
"$SOLVE" --kc-build   "$F" --f1-pairs 9 >"$WORK/bf.log" 2>&1 || die "--kc-build failed"
"$SOLVE" --kc-g-build "$G" --f1-pairs 9 >"$WORK/bg.log" 2>&1 || die "--kc-g-build failed"
"$SOLVE" --kc-t-build "$F" "$T"         >"$WORK/bt.log" 2>&1 || die "--kc-t-build failed"

# --kc-raw and --kc-tdir are BOTH required: without --kc-raw marginal_raw is absent and V1 dies at
# n=31, and without --kc-tdir the t-identity is skipped while the scan still says KC_SCAN=OK.
# Rehearsing without them would rehearse a different run than the one that will happen.
"$SOLVE" --kc-scan "$F" "$G" "$WORK/atlas_n9.json" --kc-tdir "$T" --kc-raw >"$WORK/scan.log" 2>&1 \
  || die "--kc-scan failed at n=9"
grep -qx 'KC_SCAN=OK' "$WORK/scan.log" || die "n=9 scan did not report KC_SCAN=OK"
grep -qx 'KC_SCAN_TIDENTITY=VERIFIED' "$WORK/scan.log" \
  || die "n=9 scan did not VERIFY the t-identity -- rehearsing a weaker run than the real one"
[ -s "$WORK/atlas_n9.json" ] || die "no atlas was written"

W="1,32,16,2,8,4,55,59,62,31,47,61,45,18,51,12,33,30"
"$SOLVE" --kc-o3-rank "$F" "$G" "$W" --kc-trace --kc-bracket >"$WORK/q3_trace.txt" 2>&1 \
  || die "--kc-o3-rank trace failed (Q3/V4 have no input without it)"

# ---- GATE 2: every family that CAN run at n=9 does ----------------------------------------------
OUT=$WORK/out
python3 "$ROOT/solve.py" --atlas-queries "$WORK/atlas_n9.json" --atlas-out "$OUT" \
        --atlas-q3-trace "$WORK/q3_trace.txt" >"$WORK/consumer.log" 2>&1 \
  || { sed 's/^/        /' "$WORK/consumer.log" >&2; die "the atlas consumer exited non-zero"; }
V=$OUT/VERDICTS.txt
[ -s "$V" ] || die "the consumer wrote no VERDICTS.txt -- nothing was measured"

NV=$(grep -cE '^TR12_[A-Z0-9_]+=' "$V")
# 🔴 A COUNT, not just a scan for FAIL. A family that silently stops emitting leaves every
# remaining verdict green, and only the count sees it. 14 measured 2026-09-09.
MINV=${GROUPC_MIN_VERDICTS:-16}   # 14 before A5 began announcing its skip (2026-09-09)
if [ "$NV" -lt "$MINV" ]; then
  say "[FAIL] only $NV verdict(s); expected at least $MINV. A family stopped emitting."
  fails=$((fails+1))
else
  say "[ok]   $NV verdicts emitted (floor $MINV)"
fi
BAD=$(grep -E '^TR12_[A-Z0-9_]+=' "$V" | grep -vE '=(PASS|PASS:|SKIP:|PENDING:)' || true)
if [ -n "$BAD" ]; then
  say "[FAIL] verdict(s) that are neither PASS, a qualified PASS:, a SKIP: nor a PENDING::"
  printf '%s\n' "$BAD" | sed 's/^/         /'
  fails=$((fails+1))
else
  say "[ok]   every verdict is PASS / PASS: / SKIP: / PENDING:"
fi

# ---- GATE 3: every n==31-only path is NAMED ------------------------------------------------------
# Declared: the verdict, and WHY it is acceptable that n=9 cannot exercise it.
#   TR12_Q3_KW        SKIP:n=9 emitted  AND tests.py drives atlas_q3_name(...,31) on synthetic steps
#   TR12_A2_SLOT      SKIP:n=9 emitted
#   TR12_A3_EXTERNAL  SKIP:n=9 emitted
#   TR12_A5_ORBIT_COLUMNS  🔴 NEITHER -- emits nothing at n<31 and has 0 tests.py references
for v in TR12_Q3_KW TR12_A2_SLOT TR12_A3_EXTERNAL; do
  if grep -qE "^${v}=SKIP:n=" "$V"; then
    say "[ok]   $v announces itself as SKIP:n=9"
  else
    say "[FAIL] $v neither ran nor announced a SKIP at n=9 -- an unrehearsed path that is also invisible"
    fails=$((fails+1))
  fi
done
for v in TR12_A5_ORBIT_COLUMNS TR12_A5_ORBIT_MEMBERSHIP; do
  if grep -qE "^${v}=SKIP:n=" "$V"; then
    say "[ok]   $v announces itself as SKIP:n=9"
  else
    say "[FAIL] $v emits nothing at n=9. A reader of VERDICTS.txt cannot tell it exists."
    fails=$((fails+1))
  fi
done

# 🔴 VISIBILITY IS NOT COVERAGE, AND A GATE NOBODY RUNS IS NOT COVERAGE EITHER.
# Emitting SKIP:n=9 makes A5 visible; it does not make it rehearsed. Its n==31 code
# (atlas_orbit_columns / atlas_orbit_membership, 0 references in tests.py) is exercised ONLY by
# scripts/a5_orbit_membership_gate.sh against a synthetic 31-pair atlas -- and on 2026-09-09 that
# gate had NO INVOKER, so the only coverage of the only n=31-only path never ran. Requiring the
# invoker is the difference between a coverage claim and coverage.
COV=scripts/a5_orbit_membership_gate.sh
if [ ! -x "$ROOT/$COV" ]; then
  say "[FAIL] $COV is missing or not executable -- A5's only n=31 coverage cannot run"
  fails=$((fails+1))
else
  INV=$(grep -rl -- "a5_orbit_membership_gate.sh" "$ROOT/scripts" "$ROOT/.git/hooks" 2>/dev/null \
        | grep -v "$COV\$" | grep -c . || true)
  if [ "${INV:-0}" -eq 0 ]; then
    say "[FAIL] nothing invokes $COV. It is the ONLY thing that runs A5's n==31 code, so"
    say "       leaving it unwired means the path first executes after a 7-33 day scan."
    fails=$((fails+1))
  else
    say "[ok]   $COV has $INV invoker(s) -- A5's n==31 code is actually exercised"
  fi
fi

# RATCHET: a NEW n==31 guard in the consumer is a NEW unrehearsed path, and must be declared above.
#
# 🔴 MATERIALISE THE REGION, THEN GREP OVER THE FILE, AND CHECK IT EXISTS FIRST.
# The first version did `sed -n '...' solve.py | grep -q atlas_queries` to prove the region was
# found. Under `set -o pipefail` grep -q exits at its first match and SIGPIPEs sed, pipefail takes
# sed's 141, and A MATCH REPORTS AS NO MATCH -- so the check written to prevent a false zero
# produced a false ERROR on a perfectly good tree. Same shape the repo already carries a rule for.
sed -n '/^_ATLAS_SELECTORS/,/^def atlas_selftest/p' "$ROOT/solve.py" > "$WORK/consumer_region.py"
grep -c 'def atlas_queries' "$WORK/consumer_region.py" >/dev/null 2>&1 || true
if [ "$(grep -c 'def atlas_queries' "$WORK/consumer_region.py")" -eq 0 ]; then
  die "could not locate the atlas-consumer region in solve.py -- the ratchet would measure nothing"
fi
NG=$(grep -cE 'n *[!=]= *31' "$WORK/consumer_region.py")
# Pinned at the MEASURED count, 2026-09-09. Four guards, ALL of them now visible:
#   `if "a5" in sel and n != 31:`  -> emits TR12_A5_ORBIT_COLUMNS/_MEMBERSHIP = SKIP:n=<n>
#   `if "a5" in sel and n == 31:`  -> the real A5 work
#   two `if n != 31:` that `return ("SKIP:n=%s", ...)`  -> A2 slot, A3 external
# It went 3 -> 4 when the a5 skip branch was added, and this ratchet FAILED until the pin was
# raised in the same change -- which is the ratchet working on its own author, not against them.
PIN=${GROUPC_N31_GUARDS:-4}
if [ "$NG" -gt "$PIN" ]; then
  say "[FAIL] $NG 'n == 31' guard(s) in the atlas consumer, pinned at $PIN. A new one is a new"
  say "       path n=9 cannot rehearse. Declare it in Gate 3 and raise the pin IN THE SAME CHANGE."
  fails=$((fails+1))
elif [ "$NG" -lt "$PIN" ]; then
  say "[ok]   $NG n==31 guard(s), BELOW the pin $PIN -- lower GROUPC_N31_GUARDS in this change"
else
  say "[ok]   $NG n==31 guard(s) in the consumer, matching the pin"
fi
echo "GROUPC_REHEARSAL_VERDICTS=$NV"
echo "GROUPC_REHEARSAL_N31_GUARDS=$NG"
[ "$fails" -eq 0 ] && { echo "GROUPC_REHEARSAL=PASS"; exit 0; }
echo "GROUPC_REHEARSAL=FAIL"; exit 1
