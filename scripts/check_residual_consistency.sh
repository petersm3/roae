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
get(){ if [ -n "$REF" ]; then git show "$REF:$1" 2>/dev/null; else cat "$1" 2>/dev/null; fi; }
FILES="reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md reports/TR9_PRICING_THE_CONSTRAINTS.md README.md"
bad=0
for f in $FILES; do
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
  done < <(get "$f")
done
echo "RESIDUAL_CONSISTENCY=$([ "$bad" -eq 0 ] && echo PASS || echo FAIL) offenders=$bad"
