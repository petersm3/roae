#!/bin/bash
# r11_stratified_repair.sh — runs ON THE VM under nohup. SELF-CONTAINED + SELF-HALT.
# R11 gate-2 closure: REPAIRED stratified pass ONLY (56 first-level branches),
# on the strict-prefix-composition-fixed solve.c (roae commit 4166632).
# Everything else from the Phase-2 battery (4 direct seeds, derived-CI, exact
# audits) is already done and archived (R11_PHASE2_RESULTS_20260711_190410).
#
# Derived from r11_phase2_battery.sh (archived) — SAME env/flags/seed formula/
# probe split for the stratified portion (pre-committed design §5.1):
#   SOLVE_KNUTH_MOORE_STRICT=1 SOLVE_KNUTH_GENDER_STRICT=1 SOLVE_KNUTH_SCORE=1
#   SOLVE_KNUTH_R11_HIST=1 SOLVE_KNUTH_SEED=$((700000 + p*10 + o))
#   STRAT_TOTAL=2e10 split evenly over the branches.
# Change vs the battery: per-branch output captured UNFILTERED (supervisor
# logging discipline) into branch_<p>_<o>.out; stratified.out keeps the old
# 2-line-per-branch extract for parse compatibility.
#
# ORPHAN-PROOF: trap EXIT -> DONE marker + `sudo shutdown -h +3`; background
# HARD CAP `sudo shutdown -h now` at HARDCAP_MIN; soft abort guard at
# SOFTCAP_S so the trap still writes DONE + partial results cleanly.
# Idempotent: completed branches (KNUTH-ESTIMATE line present) are skipped,
# so an eviction-resume re-invocation continues where it stopped.
set -uo pipefail

WORK="${WORK:-/home/solver/r11strat}"
SOLVE="${SOLVE:-$WORK/solve}"
OUT="${OUT:-$WORK/results}"
THREADS="${THREADS:-32}"
HARDCAP_MIN="${HARDCAP_MIN:-360}"       # 6 h guest hard cap (task abort budget)
SOFTCAP_S="${SOFTCAP_S:-17400}"         # 290 min soft abort (clean partial finish)
SELFTEST_SHA="403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e"
STRAT_TOTAL="${STRAT_TOTAL:-20000000000}"   # 2e10 total, split over the 56 branches

mkdir -p "$OUT"
ulimit -s unlimited
exec > >(tee -a "$OUT/battery.log") 2>&1
echo "=== R11 stratified-repair start $(date -u +%FT%TZ) host=$(hostname) threads=$THREADS ==="

( sleep $((HARDCAP_MIN*60)); echo "HARDCAP $(date -u +%FT%TZ) forcing halt"; sudo shutdown -h now ) &
HARDCAP_PID=$!

finish() {
  rc=$?
  echo "=== stratified-repair finish rc=$rc $(date -u +%FT%TZ) ==="
  echo "$rc" > "$OUT/EXIT_CODE"
  date -u +%FT%TZ > "$OUT/DONE"
  kill "$HARDCAP_PID" 2>/dev/null || true
  sync
  echo "guest self-halt in +3 min (orchestrator monitor is primary teardown)"
  sudo shutdown -h +3 || true
}
trap finish EXIT

fail() { echo "GATE/RUN FAILURE: $*"; exit 1; }

# ---- provenance: source + binary shas ----
sha256sum "$WORK/solve.c" "$SOLVE" > "$OUT/build_provenance.txt" 2>/dev/null || true
grep -m1 "model name" /proc/cpuinfo >> "$OUT/build_provenance.txt" || true
gcc --version | head -1 >> "$OUT/build_provenance.txt" || true

# ---- GATE 1: selftest sha (repaired estimator must be sha-neutral) ----
echo "--- gate: --selftest ---"
ST=$("$SOLVE" --selftest 2>&1 | grep -oE '[0-9a-f]{64}' | tail -1)
echo "selftest sha=$ST"
[ "$ST" = "$SELFTEST_SHA" ] || fail "selftest sha mismatch ($ST != $SELFTEST_SHA)"

# ---- GATE 2: r11-verify ----
echo "--- gate: --r11-verify ---"
"$SOLVE" --r11-verify 2>&1 | tee "$OUT/r11_verify.out" | grep -q "R11 VERIFY: PASS" || fail "r11-verify not PASS"

# ---- branches (must reproduce the archived 56) ----
"$SOLVE" --list-branches 2>/dev/null \
  | awk '/^  +[0-9]+ +[0-9]+ +[0-9]+ +\(/ {print $1, $2}' > "$OUT/branches.txt"
NB=$(wc -l < "$OUT/branches.txt")
echo "branches=$NB"
[ "$NB" = "56" ] || fail "expected 56 branches, got $NB"
PER=$(( STRAT_TOTAL / NB )); [ "$PER" -lt 1 ] && PER=1
echo "per-branch probes=$PER"

# ---- REPAIRED stratified pass ----
T0=$(date +%s)
: > "$OUT/stratified.out"
while read -r p o; do
  [ -z "$p" ] && continue
  BF="$OUT/branch_${p}_${o}.out"
  if [ -f "$BF" ] && grep -q "KNUTH-ESTIMATE" "$BF"; then
    echo "branch $p $o already complete — SKIP (resume)"
  else
    EL=$(( $(date +%s) - T0 ))
    if [ "$EL" -gt "$SOFTCAP_S" ]; then
      echo "SOFT-ABORT: elapsed ${EL}s > ${SOFTCAP_S}s — stopping cleanly with partial results"
      echo "SOFT_ABORT_AT branch $p $o elapsed=${EL}s" > "$OUT/ABORT"
      exit 1
    fi
    echo "--- branch $p $o probes=$PER $(date -u +%FT%TZ) ---"
    SOLVE_KNUTH_MOORE_STRICT=1 SOLVE_KNUTH_GENDER_STRICT=1 SOLVE_KNUTH_SCORE=1 \
    SOLVE_KNUTH_R11_HIST=1 SOLVE_KNUTH_SEED=$(( 700000 + p*10 + o )) SOLVE_THREADS=$THREADS \
      "$SOLVE" --estimate-knuth "$PER" "$p" "$o" > "$BF" 2>&1     # UNFILTERED capture
  fi
  # parse-compatible extract (same 2 lines the battery kept) + dead marker
  {
    echo "### branch $p $o probes=$PER"
    grep -E "leaves_canonical_C1C5|DERIVED-N_gs|STRICT-PREFIX DEAD" "$BF"
  } >> "$OUT/stratified.out"
done < "$OUT/branches.txt"
echo "stratified done $(date -u +%FT%TZ) wall=$(( $(date +%s) - T0 ))s"

# ---- convenience naive pooled sum + SE (authoritative pooling on orchestrator) ----
awk '/leaves_canonical_C1C5/{
       for(i=1;i<=NF;i++) if($i ~ /^est=/) e=substr($i,5)+0;
       if (match($0, /relerr=[0-9.]+/)) r=substr($0, RSTART+7, RLENGTH-7)+0;
       s+=e; v+=(e*r/100.0)^2 }
     END{printf "ONBOX-POOL sum=%.6e se=%.4e relerr=%.2f%%\n", s, sqrt(v), s>0?100*sqrt(v)/s:0}' \
  "$OUT/stratified.out" || true

echo "=== STRATIFIED-REPAIR COMPLETE $(date -u +%FT%TZ) ==="
