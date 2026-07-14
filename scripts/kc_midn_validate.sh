#!/usr/bin/env bash
# ============================================================================
# kc mid-n validation driver — branch v4-compiler, Deliverable A (2026-07-14)
# Claude (Fable 5), developed with AI assistance (Claude, Anthropic).
#
# For each n in the ladder, this driver validates the knowledge-compiler
# query layer (--kc-*) at scales where the full brute force is infeasible:
#
#   M1  exact count: compiled --kc-count == the PRODUCTION rolling-window
#       count (--f1-exact-c1c2c4c5) — separate process AND separate code
#       path (two-live-layer rolling window vs retained layers)
#   M2-M5  in-binary gate suite (./solve --kc-midn N): rank/unrank/member
#       roundtrips incl. boundary ranks, reverse-exit-lex monotonicity,
#       mutation coherence vs the independent forward validator, exact-
#       uniform sampling chi-square, largest-layer partition invariance
#   size  compiled-artifact footprint, raw v1 + gzip -9 (plain coreutils
#       gzip, parallel per-layer via xargs -P, binary assets only)
#
# LIGHT-BUDGET GUARD (2-core/8GB orchestrator, measured 2026-07-14):
#   n=18:  16 MB raw layers,   29 MB peak RSS, <1 s   (light)
#   n=19:  88 MB raw layers,  111 MB peak RSS, ~1 s   (light)
#   n=21: 431 MB raw layers,  496 MB peak RSS, ~4 s   (light)
#   n=22: 984 MB raw layers, 1.12 GB peak RSS, ~7 s   (light ceiling)
#   n=24 (next orbit-realizable) projects to ~5-8 GB resident — OVER the
#   light budget: GATED for a Spot worker (operator go required). This
#   driver hard-refuses n > KC_MIDN_MAX_N locally.
#
# Usage: scripts/kc_midn_validate.sh            # default ladder 18 19 21 22
#   env: SOLVE_BIN=./solve  KC_MIDN_NS="18 19"  KC_MIDN_WORK=/path
#        KC_MIDN_MAX_N=22 (raise ONLY on a right-sized worker, never here)
# ============================================================================
set -euo pipefail

BIN="${SOLVE_BIN:-./solve}"
NS="${KC_MIDN_NS:-18 19 21 22}"
MAXN="${KC_MIDN_MAX_N:-22}"
WORK="${KC_MIDN_WORK:-$(mktemp -d /tmp/kc_midn_XXXXXX)}"
mkdir -p "$WORK"

[ -x "$BIN" ] || { echo "ERROR: $BIN not found/executable (build: gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm -lz)" >&2; exit 2; }

echo "== kc mid-n validation: ns=[$NS] work=$WORK bin=$BIN =="
TAB="$WORK/results.md"
{
  echo "| n | exact count | M1 count (kc==prod) | raw v1 | gzip -9 | build | peak RSS | M2-M5 |"
  echo "|---|---|---|---|---|---|---|---|"
} > "$TAB"

fails=0
for n in $NS; do
  if [ "$n" -gt "$MAXN" ]; then
    echo "REFUSED: n=$n exceeds the local light ceiling (KC_MIDN_MAX_N=$MAXN)." >&2
    echo "         Larger n is a GATED Spot-worker job — do not run on the orchestrator." >&2
    exit 3
  fi
  d="$WORK/kc$n"
  echo "-- n=$n: exhaustive --kc-build (retained layers) --"
  "$BIN" --kc-build "$d" --f1-pairs "$n" > "$WORK/build_$n.log" 2>&1
  kc_count=$("$BIN" --kc-count "$d" | awk '{print $NF}')

  echo "-- n=$n: M1 count cross-check vs production --f1-exact-c1c2c4c5 (rolling window) --"
  prod_count=$("$BIN" --f1-exact-c1c2c4c5 --f1-pairs "$n" 2>"$WORK/prod_$n.err" \
               | awk -F'= ' '/orbit-quotient C5-DP total/{print $2}')
  if [ -n "$kc_count" ] && [ "$kc_count" = "$prod_count" ]; then m1=PASS
  else m1=FAIL; fails=$((fails+1)); fi
  echo "   kc=$kc_count prod=$prod_count -> $m1"

  echo "-- n=$n: M2-M5 in-binary gate suite (--kc-midn) --"
  if "$BIN" --kc-midn "$n" > "$WORK/midn_$n.log" 2>&1; then m25=PASS
  else m25=FAIL; fails=$((fails+1)); fi
  grep -E "^\[kc-(selftest|midn)\] M|^KC-MIDN" "$WORK/midn_$n.log" || true
  summary=$(grep "^KC-MIDN" "$WORK/midn_$n.log" || true)
  build_s=$(echo "$summary" | sed -n 's/.*build_s=\([0-9.]*\).*/\1/p')
  rss_mb=$(echo "$summary" | sed -n 's/.*peak_rss_mb=\([0-9.]*\).*/\1/p')

  echo "-- n=$n: artifact size (raw v1 + gzip -9, parallel per-layer) --"
  raw_b=$(find "$d" -maxdepth 1 -name 'f1c5_layer_*.bin' -print0 | xargs -0 -r du -cb | tail -1 | cut -f1)
  find "$d" -maxdepth 1 -name 'f1c5_layer_*.bin' -print0 | xargs -0 -P2 -n1 gzip -9 -k
  gz_b=$(find "$d" -maxdepth 1 -name 'f1c5_layer_*.bin.gz' -print0 | xargs -0 -r du -cb | tail -1 | cut -f1)
  raw_mb=$(awk "BEGIN{printf \"%.1f\", $raw_b/1e6}")
  gz_mb=$(awk "BEGIN{printf \"%.1f\", $gz_b/1e6}")
  echo "   raw=${raw_mb} MB gz=${gz_mb} MB (x$(awk "BEGIN{printf \"%.1f\", $raw_b/$gz_b}"))"

  echo "| $n | $kc_count | $m1 | ${raw_mb} MB | ${gz_mb} MB | ${build_s}s | ${rss_mb} MB | $m25 |" >> "$TAB"
  rm -rf "$d"   # scratch discipline: delete per-n artifacts immediately
done

echo
echo "== results table ($TAB) =="
cat "$TAB"
echo
if [ "$fails" -eq 0 ]; then echo "== kc mid-n validation: ALL PASS =="; else
  echo "== kc mid-n validation: $fails FAILURE(S) =="; exit 1; fi
