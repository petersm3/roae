#!/usr/bin/env bash
# Q-374 SE validation: 12 independent-seed replicates of the Davis (2012) mass
# estimator at 10^7 probes each, run SERIALLY. Seeds are the explicit list 1..12.
# Reproduce (from the repo root, with ./solve built from solve.c as documented in
# documentation/SOLVE.md; the estimator needs a >=16 MB stack):
#   ulimit -s unlimited; bash reports/evidence/q374_se_replicates/run_replicates.sh
# Thread count is PART OF THE SAMPLE (per-worker seed = base ^ ((i+1)*0x9E3779B97F4A7C15));
# the archived replicates ran at SOLVE_THREADS=2. Output is byte-identical only at
# identical (probes, threads, seed).
set -u
BIN=${BIN:-./solve}
OUT=${OUT:-reports/evidence/q374_se_replicates}
PROBES=${PROBES:-10000000}
for SEED in 1 2 3 4 5 6 7 8 9 10 11 12; do
  f=$(printf '%s/rep%02d_seed%d.out' "$OUT" "$SEED" "$SEED")
  SOLVE_THREADS=2 SOLVE_KNUTH_SCORE_DAV=1 SOLVE_KNUTH_SEED=$SEED \
    "$BIN" --estimate-knuth "$PROBES" > "$f" 2>&1
  echo "REPLICATE seed=$SEED rc=$? file=$f $(date -u +%FT%TZ)"
done
