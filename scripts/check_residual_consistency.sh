#!/usr/bin/env bash
# The residual is a RANGE (~105-139 bits) whose value depends on which layers are granted
# explanatory standing. Any place that states it as a bare POINT estimate contradicts the
# README and TR-10's own body.
#
# 🔴 This is the claim-lineage failure class: TR-9 v1.22 widened the range, the body and README
# were propagated, and TR-10's EXECUTIVE SUMMARY was not. A summary that says something narrower
# than its own body is what a reader quotes.
#
# Usage: check_residual_consistency.sh [git-ref]   (default: working tree)
set -uo pipefail
REF=${1:-}
# 🔴 FAIL-CLOSED (2026-09-05 fail-open class sweep). Until this date `get` read a missing file
# through `cat … 2>/dev/null`, so an absent or renamed report yielded ZERO lines, ZERO offenders
# and RESIDUAL_CONSISTENCY=PASS — and the script's exit status was that of its final echo, so
# even a FAIL verdict exited 0. A check whose input is absent has checked nothing: it ERRORs.
# Tokens (grep -qx): RESIDUAL_CONSISTENCY=PASS|FAIL|ERROR. Exit 0 PASS / 1 FAIL / 2 ERROR.
get(){ if [ -n "$REF" ]; then git show "$REF:$1"; else cat "$1"; fi; }
scanned=0
FILES="reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md reports/TR9_PRICING_THE_CONSTRAINTS.md README.md"
bad=0
for f in $FILES; do
  if ! body=$(get "$f" 2>/dev/null); then
    echo "  [ERROR] cannot read $f${REF:+ at $REF} — a report this gate exists to check is absent or unreadable"
    echo "RESIDUAL_CONSISTENCY=ERROR unreadable:$f"; exit 2
  fi
  n=$(printf '%s\n' "$body" | grep -c .)
  if [ "${n:-0}" -eq 0 ]; then
    echo "  [ERROR] $f${REF:+ at $REF} is EMPTY — zero lines scanned is not zero offenders"
    echo "RESIDUAL_CONSISTENCY=ERROR empty:$f"; exit 2
  fi
  scanned=$((scanned+n))
  # a point estimate is "~126...-bit/bits ... residual" with NO range marker on the same line
  while IFS= read -r line; do
    printf '%s' "$line" | grep -qE '~?12[0-9](\.[0-9])?[- ]?bit' || continue
    # a point estimate WITH its scope named is fine -- "~126-bit (C1-C5-layer)" is honest.
    # Only a BARE point estimate, with neither the range nor the layer scope, is the defect.
    printf '%s' "$line" | grep -qE '105|139|range|depends on which layers|C1.C5.layer|C1.C5 reading|C1.C5-layer' && continue
    printf '%s' "$line" | grep -qiE 'residual|unexplained' || continue
    echo "  POINT-ESTIMATE RESIDUAL without its range: $f"
    echo "    $(printf '%s' "$line" | cut -c1-120)"
    bad=$((bad+1))
  done <<< "$body"
done
# Population floor: the three reports together are thousands of lines; a scan of fewer than 100
# means a truncated read, not a clean corpus.
if [ "$scanned" -lt 100 ]; then
  echo "  [ERROR] only $scanned line(s) scanned across $FILES — population collapsed"
  echo "RESIDUAL_CONSISTENCY=ERROR population-collapsed scanned=$scanned"; exit 2
fi
echo "RESIDUAL_CONSISTENCY=$([ "$bad" -eq 0 ] && echo PASS || echo FAIL) offenders=$bad scanned=$scanned"
[ "$bad" -eq 0 ]
