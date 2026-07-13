#!/bin/bash
# r11_phase2_battery.sh — runs ON THE VM under nohup. SELF-CONTAINED + SELF-HALT.
# R11 Phase-2 N_gs re-measurement battery (Option A), per
# R11_RESOLUTION_PHASE1_DIAGNOSIS_2026_07_11.md §5.1.  HELD results (no push).
#
# ORPHAN-PROOF design (agent may stall; subagents cannot wait across turns):
#  * trap EXIT -> write DONE marker + `sudo shutdown -h +3`  (guest self-halt)
#  * background HARD CAP -> `sudo shutdown -h now` at HARDCAP_MIN (>= abort budget)
#  * orchestrator monitor is PRIMARY teardown (az vm delete after fetching results)
#
# Gates (abort + self-halt on any failure):
#  * ./solve --selftest  == sha 403f7202...   (estimator edits are sha-neutral)
#  * ./solve --r11-verify == PASS              (two-language KW axis reproduction)
#  * instrument smoke: a short strict run must print leaves_canonical + DERIVED-N_gs
#
# Pre-committed ABORT (design §5.5): if seed-1 wall implies > 30 h or > $20 total,
# stop after seed 1 (its 5.5e10-probe result alone ~8% relerr = usable fallback).
set -uo pipefail

WORK="${WORK:-/home/solver/r11p2}"      # OS disk (persists across Spot deallocate; /mnt is ephemeral)
SOLVE="${SOLVE:-$WORK/solve}"
OUT="${OUT:-$WORK/results}"
THREADS="${THREADS:-64}"
HARDCAP_MIN="${HARDCAP_MIN:-1860}"      # 31 h guest hard cap (> 30 h abort budget)
RATE_PER_HR="${RATE_PER_HR:-0.50}"      # Spot D64als_v7 ~$/hr, for the abort $ check
SELFTEST_SHA="403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e"

# Battery sizes (probes)
SEED_PROBES="${SEED_PROBES:-55000000000}"     # 5.5e10 per direct seed  (runs 1..4)
SEEDS="${SEEDS:-1001 2003 3011 4013}"         # 4 distinct u64 seeds
STRAT_TOTAL="${STRAT_TOTAL:-20000000000}"     # 2e10 total, split over the 56 branches
DERIVED_PROBES="${DERIVED_PROBES:-40000000000}" # 4e10 Moore-strict-only derived-CI run
AUDIT_DEPTHS="${AUDIT_DEPTHS:-20 22 24}"      # exact-count calibration prefix depths
AUDIT_SEEDS_PER_DEPTH="${AUDIT_SEEDS_PER_DEPTH:-8}"
AUDIT_EXACT_TIMEOUT="${AUDIT_EXACT_TIMEOUT:-180}"
AUDIT_EST_PROBES="${AUDIT_EST_PROBES:-2000000000}"

mkdir -p "$OUT"
ulimit -s unlimited
exec > >(tee -a "$OUT/battery.log") 2>&1
echo "=== R11 Phase-2 battery start $(date -u +%FT%TZ) host=$(hostname) threads=$THREADS ==="

# ---- guest hard-cap backstop (independent of everything below) ----
( sleep $((HARDCAP_MIN*60)); echo "HARDCAP $(date -u +%FT%TZ) forcing halt"; sudo shutdown -h now ) &
HARDCAP_PID=$!

finish() {
  rc=$?
  echo "=== battery finish rc=$rc $(date -u +%FT%TZ) ==="
  echo "$rc" > "$OUT/EXIT_CODE"
  date -u +%FT%TZ > "$OUT/DONE"                       # <-- marker the monitor watches
  kill "$HARDCAP_PID" 2>/dev/null || true
  sync
  echo "guest self-halt in +3 min (orchestrator monitor is primary teardown)"
  sudo shutdown -h +3 || true
}
trap finish EXIT

fail() { echo "GATE/RUN FAILURE: $*"; exit 1; }

# ---- GATE 1: selftest sha ----
echo "--- gate: --selftest ---"
ST=$("$SOLVE" --selftest 2>&1 | grep -oE '[0-9a-f]{64}' | tail -1)
echo "selftest sha=$ST"
[ "$ST" = "$SELFTEST_SHA" ] || fail "selftest sha mismatch ($ST != $SELFTEST_SHA)"

# ---- GATE 2: r11-verify ----
echo "--- gate: --r11-verify ---"
"$SOLVE" --r11-verify 2>&1 | tee "$OUT/r11_verify.out" | grep -q "R11 VERIFY: PASS" || fail "r11-verify not PASS"

# ---- GATE 3: instrument smoke (must print leaves_canonical + DERIVED-N_gs) ----
echo "--- gate: instrument smoke (2e9 strict) ---"
SOLVE_KNUTH_MOORE_STRICT=1 SOLVE_KNUTH_GENDER_STRICT=1 SOLVE_KNUTH_SCORE=1 \
SOLVE_KNUTH_R11_HIST=1 SOLVE_KNUTH_SEED=99 SOLVE_THREADS=$THREADS \
  "$SOLVE" --estimate-knuth 2000000000 > "$OUT/smoke.out" 2>&1 || fail "smoke run crashed"
grep -q "leaves_canonical_C1C5" "$OUT/smoke.out" || fail "smoke: no leaves_canonical line"
grep -q "DERIVED-N_gs" "$OUT/smoke.out" || fail "smoke: no DERIVED-N_gs line"
grep -q "KNUTH-PROVENANCE" "$OUT/smoke.out" || fail "smoke: no provenance line"
echo "smoke gate PASS"

run_direct() {  # $1=seed $2=probes $3=outfile
  local seed=$1 probes=$2 of=$3
  if [ -f "$of" ] && grep -q "leaves_canonical_C1C5" "$of"; then
    echo "--- direct seed=$seed already complete ($of) — SKIP (eviction-resume) ---"; return 0
  fi
  echo "--- direct seed=$seed probes=$probes -> $of $(date -u +%FT%TZ) ---"
  SOLVE_KNUTH_MOORE_STRICT=1 SOLVE_KNUTH_GENDER_STRICT=1 SOLVE_KNUTH_SCORE=1 \
  SOLVE_KNUTH_R11_HIST=1 SOLVE_KNUTH_SEED=$seed SOLVE_THREADS=$THREADS \
    "$SOLVE" --estimate-knuth "$probes" > "$of" 2>&1
}

# ---- RUN 1: 4 independent-seed direct runs (pooled => primary N_gs) ----
i=0
for s in $SEEDS; do
  i=$((i+1))
  t0=$(date +%s)
  run_direct "$s" "$SEED_PROBES" "$OUT/seed${i}_${s}.out"
  t1=$(date +%s); dt=$((t1-t0))
  echo "seed $i (=$s) wall=${dt}s"
  if [ "$i" = "1" ]; then
    # ABORT CHECK on seed-1 rate (design §5.5): project full battery
    total_probes_after=$(( 4*SEED_PROBES + STRAT_TOTAL + DERIVED_PROBES ))
    proj_s=$(awk -v dt="$dt" -v sp="$SEED_PROBES" -v tp="$total_probes_after" 'BEGIN{printf "%d", dt*(tp/sp)}')
    proj_h=$(awk -v p="$proj_s" 'BEGIN{printf "%.1f", p/3600}')
    proj_cost=$(awk -v p="$proj_s" -v r="$RATE_PER_HR" 'BEGIN{printf "%.2f", (p/3600)*r}')
    echo "ABORT-CHECK: projected total wall=${proj_h}h cost=\$${proj_cost}"
    over=$(awk -v h="$proj_h" -v c="$proj_cost" 'BEGIN{print (h>30||c>20)?1:0}')
    if [ "$over" = "1" ]; then
      echo "ABORT (design §5.5): projection exceeds 30h/\$20 — stopping after seed 1 (fallback ~8% relerr)."
      echo "ABORTED_AFTER_SEED_1 proj_h=$proj_h proj_cost=$proj_cost" > "$OUT/ABORT"
      exit 0
    fi
  fi
done

# ---- RUN 2: stratified (sum over the 56 first-level branches) ----
echo "--- stratified run (56 branches) $(date -u +%FT%TZ) ---"
"$SOLVE" --list-branches 2>/dev/null \
  | awk '/^  +[0-9]+ +[0-9]+ +[0-9]+ +\(/ {print $1, $2}' > "$OUT/branches.txt"
NB=$(wc -l < "$OUT/branches.txt")
echo "branches=$NB"
[ "$NB" -ge 1 ] || fail "no branches parsed"
PER=$(( STRAT_TOTAL / NB )); [ "$PER" -lt 1 ] && PER=1
: > "$OUT/stratified.out"
while read -r p o; do
  [ -z "$p" ] && continue
  echo "### branch $p $o probes=$PER" >> "$OUT/stratified.out"
  SOLVE_KNUTH_MOORE_STRICT=1 SOLVE_KNUTH_GENDER_STRICT=1 SOLVE_KNUTH_SCORE=1 \
  SOLVE_KNUTH_R11_HIST=1 SOLVE_KNUTH_SEED=$(( 700000 + p*10 + o )) SOLVE_THREADS=$THREADS \
    "$SOLVE" --estimate-knuth "$PER" "$p" "$o" 2>/dev/null \
    | grep -E "leaves_canonical_C1C5|DERIVED-N_gs" >> "$OUT/stratified.out"
done < "$OUT/branches.txt"
echo "stratified done"

# ---- RUN 3: derived-with-CI (Moore-strict only; NO gender prune) ----
echo "--- derived-CI run (Moore-strict only) $(date -u +%FT%TZ) ---"
SOLVE_KNUTH_MOORE_STRICT=1 SOLVE_KNUTH_SCORE=1 SOLVE_KNUTH_R11_HIST=1 \
SOLVE_KNUTH_SEED=505051 SOLVE_THREADS=$THREADS \
  "$SOLVE" --estimate-knuth "$DERIVED_PROBES" > "$OUT/derived_ci.out" 2>&1
echo "derived done"

# ---- RUN 4: exact-count calibration audits ($0; no strict prune, C1-C5 canonical) ----
echo "--- exact-count audits $(date -u +%FT%TZ) ---"
: > "$OUT/exact_audit.tsv"
echo -e "depth\tseed\treached\texact_c3\test_c3\test_ci_lo\test_ci_hi" >> "$OUT/exact_audit.tsv"
for D in $AUDIT_DEPTHS; do
  for k in $(seq 1 "$AUDIT_SEEDS_PER_DEPTH"); do
    sd=$(( D*1000 + k*7 + 1 ))
    PL=$("$SOLVE" --knuth-dump-prefix "$D" "$sd" 2>/dev/null)
    PFX=$(echo "$PL" | sed -n '1p' | sed 's/.*: //')
    RCH=$(echo "$PL" | awk '/PREFIX_DEPTH_REACHED/{print $2}')
    [ -z "$PFX" ] && continue
    EX=$(SOLVE_THREADS=$THREADS timeout "$AUDIT_EXACT_TIMEOUT" "$SOLVE" --estimate-knuth 0 $PFX 2>/dev/null \
         | awk '/leaves_canonical_C1C5/{print $3}')
    [ -z "$EX" ] && EX="TIMEOUT"
    read -r ES LO HI < <(SOLVE_THREADS=$THREADS "$SOLVE" --estimate-knuth "$AUDIT_EST_PROBES" $PFX 2>/dev/null \
         | awk '/leaves_canonical_C1C5/{
                  e=""; lo=""; hi="";
                  for(i=1;i<=NF;i++) if($i ~ /^est=/) e=substr($i,5);
                  if (match($0, /95%CI=\[[^]]*\]/)) {
                    s=substr($0, RSTART+7, RLENGTH-8); gsub(/,/," ",s);
                    n=split(s,a," "); lo=a[1]; hi=a[2];
                  }
                  print e, lo, hi }')
    echo -e "${D}\t${sd}\t${RCH}\t${EX}\t${ES:-NA}\t${LO:-NA}\t${HI:-NA}" >> "$OUT/exact_audit.tsv"
    echo "audit d=$D seed=$sd reached=$RCH exact=$EX est=${ES:-NA}"
  done
done
echo "audits done"

echo "=== BATTERY COMPLETE $(date -u +%FT%TZ) ==="
# trap finish handles DONE marker + guest self-halt; orchestrator monitor fetches + deletes.
