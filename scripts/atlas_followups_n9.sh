#!/usr/bin/env bash
# atlas_followups_n9.sh -- end-to-end rehearsal of scripts/atlas_followups.sh on n=9 ladders built here.
#
# Builds the n=9 f, g and t ladders and their atlas in a work directory (seconds), runs the four
# follow-up queries (8, 1b, 7, 9) on them with the walk lists in
# reports/evidence/tr12/atlas_followups_n31_20260925/n9_harness/, and compares every output table and
# every summary token with the committed n=9 expectations. It exercises the same commands and the
# same summary code as the n=31 run; it does NOT exercise the out-of-core ladder reader that n=31
# uses (n <= 22 ladders are read in memory), and King Wen does not exist at n=9, so the legs that
# compare with King Wen are named skips. It says nothing about any n=31 figure.
#
# Usage: bash scripts/atlas_followups_n9.sh [WORKDIR]        (default: a fresh mktemp -d, removed on PASS)
#   SOLVE=/path/to/solve   reuse a binary built from this checkout's solve.c (default: build one)
# Whole-line verdict, last line: ATLAS_FOLLOWUPS_N9=PASS | FAIL:<what>.   Exit 0 only on PASS.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; SRC="$(cd "$HERE/.." && pwd)"
H="$SRC/reports/evidence/tr12/atlas_followups_n31_20260925/n9_harness"
KEEP=1; W="${1:-}"; if [ -z "$W" ]; then W="$(mktemp -d)" || { echo "ATLAS_FOLLOWUPS_N9=FAIL:mktemp"; exit 2; }; KEEP=0; fi
mkdir -p "$W" || { echo "ATLAS_FOLLOWUPS_N9=FAIL:workdir"; exit 2; }
fail() { echo "ATLAS_FOLLOWUPS_N9=FAIL:$1 (work directory kept: $W)"; exit 1; }
for f in q8_n9.tsv q1b_n9.tsv EXPECTED_TOKENS_n9.txt TSV_SHA256SUMS_n9; do [ -r "$H/$f" ] || fail "missing:$f"; done
OUT="$W/out"; rm -rf "$OUT" "$W/f" "$W/g" "$W/t" "$W/atlas_n9.json"; mkdir -p "$OUT"
if [ -n "${SOLVE:-}" ]; then
  [ -x "$SOLVE" ] || fail "SOLVE_not_executable"
  cp -- "$SOLVE" "$OUT/solve" && touch "$OUT/solve" || fail "copy_solve"
else
  ( cd "$SRC" && gcc -O3 -pthread -fopenmp -o "$OUT/solve" solve.c -lm -lz ) 2>"$W/build.err" || fail "build"
fi
B="$OUT/solve"
"$B" --kc-build "$W/f" --f1-pairs 9 > "$W/kc_build.log" 2>&1 || fail "kc-build"
"$B" --kc-g-build "$W/g" --f1-pairs 9 > "$W/kc_g_build.log" 2>&1 || fail "kc-g-build"
"$B" --kc-t-build "$W/f" "$W/t" > "$W/kc_t_build.log" 2>&1 || fail "kc-t-build"
"$B" --kc-scan "$W/f" "$W/g" "$W/atlas_n9.json" --kc-tdir "$W/t" --kc-raw > "$W/kc_scan.log" 2>&1 || fail "kc-scan"
SRC="$SRC" OUT="$OUT" FDIR="$W/f" GDIR="$W/g" ATLAS="$W/atlas_n9.json" Q8_IN="$H/q8_n9.tsv" Q1B_IN="$H/q1b_n9.tsv" \
  Q1B_PAR="${Q1B_PAR:-2}" CACHE_MB_ONE="${CACHE_MB_ONE:-256}" bash "$HERE/atlas_followups.sh" > "$W/run.log" 2>&1
rc=$?
[ $rc -eq 0 ] || fail "runner_rc=$rc ($(grep -E '^ATLAS_Q[0-9A-Z]*=FAIL|^ATLAS_QUERIES=FAIL|^AF_SUMMARY=FAIL' "$W/run.log" | head -1))"
grep -qx 'ATLAS_QUERIES=ANSWERED' "$W/run.log" || fail "queries_not_answered"
# every output table, with host paths on '#' header lines replaced (fdir= gdir= tdir= atlas= -> <PATH>)
( cd "$OUT" && find q8 q1b q7 q9 -type f -name '*.tsv' | LC_ALL=C sort | while read -r f; do
    printf '%s  %s\n' "$(sed -E '/^#/ s/((^|\t)(fdir|gdir|tdir|atlas)=)[^\t]*/\1<PATH>/g' "$f" | sha256sum | cut -d' ' -f1)" "$f"; done ) > "$W/TSV_SHA256SUMS_n9"
nt=$(grep -c . "$W/TSV_SHA256SUMS_n9"); echo "ATLAS_FOLLOWUPS_N9_TABLES=$nt"
cmp -s "$W/TSV_SHA256SUMS_n9" "$H/TSV_SHA256SUMS_n9" || fail "tables_differ ($(diff "$W/TSV_SHA256SUMS_n9" "$H/TSV_SHA256SUMS_n9" | grep -c '^[<>]') lines)"
miss=0; want=0
while IFS= read -r line; do
  case "$line" in ''|'#'*) continue;; esac
  want=$((want+1)); grep -Fqx -- "$line" "$OUT/SUMMARY_TOKENS.txt" || { miss=$((miss+1)); echo "#missing: $line"; }
done < "$H/EXPECTED_TOKENS_n9.txt"
echo "ATLAS_FOLLOWUPS_N9_TOKENS=$want ATLAS_FOLLOWUPS_N9_TOKENS_MISSING=$miss"
[ "$want" -gt 0 ] && [ "$miss" -eq 0 ] || fail "summary_tokens_missing=$miss/$want"
[ "$KEEP" -eq 1 ] || rm -rf "$W"
echo "ATLAS_FOLLOWUPS_N9=PASS"
