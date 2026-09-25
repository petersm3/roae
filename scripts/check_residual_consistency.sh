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
# Tokens (grep -qx), each a WHOLE line with nothing after the value:
#   RESIDUAL_CONSISTENCY=PASS|FAIL|ERROR   the verdict. Exit 0 PASS / 1 FAIL / 2 ERROR.
#   RESIDUAL_CONSISTENCY_OFFENDERS=n       bare point estimates found; -1 = not measured
#   RESIDUAL_CONSISTENCY_SCANNED=n         lines scanned across $FILES; -1 = not measured
#   RESIDUAL_CONSISTENCY_ERROR=<cause>     ERROR only: unreadable:<f> | empty:<f> |
#                                          population-collapsed
# 🔴 2026-09-08: the verdict line read "RESIDUAL_CONSISTENCY=PASS offenders=n scanned=n", so the
# `grep -qx` this very header promised could never match it — an instrument reporting something
# no one could read. The counts moved to their own tokens; the verdict line carries only a verdict.
get(){ if [ -n "$REF" ]; then git show "$REF:$1"; else cat "$1"; fi; }
scanned=0
FILES="reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md reports/TR9_PRICING_THE_CONSTRAINTS.md README.md"
bad=0
for f in $FILES; do
  if ! body=$(get "$f" 2>/dev/null); then
    echo "  [ERROR] cannot read $f${REF:+ at $REF} — a report this gate exists to check is absent or unreadable"
    echo "RESIDUAL_CONSISTENCY_OFFENDERS=-1"; echo "RESIDUAL_CONSISTENCY_SCANNED=-1"
    echo "RESIDUAL_CONSISTENCY_ERROR=unreadable:$f"
    echo "RESIDUAL_CONSISTENCY=ERROR"; exit 2
  fi
  n=$(printf '%s\n' "$body" | grep -c .)
  if [ "${n:-0}" -eq 0 ]; then
    echo "  [ERROR] $f${REF:+ at $REF} is EMPTY — zero lines scanned is not zero offenders"
    echo "RESIDUAL_CONSISTENCY_OFFENDERS=-1"; echo "RESIDUAL_CONSISTENCY_SCANNED=-1"
    echo "RESIDUAL_CONSISTENCY_ERROR=empty:$f"
    echo "RESIDUAL_CONSISTENCY=ERROR"; exit 2
  fi
  scanned=$((scanned+n))
  # a point estimate is "~126...-bit/bits ... residual" with NO range marker on the same line
  # 🔴 2026-09-24 (Q-747, Codex v3 E3 V3A-104). Two holes, both executed by Fable R on fixtures:
  #   #1 the matcher was `12[0-9](\.[0-9])?-bit`, so the range's own endpoints and anything
  #      outside 120-129 -- ~105.4-bit, ~139.1-bit -- and a two-decimal ~126.60-bit all PASSED,
  #      although the header promises to catch any bare point estimate of the 105-139 range.
  #      Now: any 105-139 value, any number of decimals, as its own number (not the tail of 1105).
  #   #2 the exemption was a bare SUBSTRING test for `105|139|range`, so "rearrangement" and
  #      "Of 139 tests" exempted the line. Now a line is exempt only for a written RANGE
  #      (105-139, 105–139, ~105 to ~139: two 105-139 values joined by a dash or "to"), the whole
  #      word "range"/"ranges", or one of the layer-scope phrases, each at word boundaries. A
  #      NAMED LAYER SET (log₂|C1–C7|, |C1∩C2∩C4|) is a layer scope too: it says which reading
  #      the number is. That is not a new exemption but the old `C1.C5.layer` one generalised --
  #      the widened matcher first flagged TR-9:210, "log₂|C1–C7| = 105.4 bits ... the most
  #      conservative reading", whose range is stated two lines on.
  #   A REVISION-HISTORY ROW (`| v1.24 | ...`) keeps the PRE-2026-09-24 matcher (12x only): the
  #      widening does not reach it, and nothing the old gate checked is un-checked. It is an
  #      append-only record, never reworded, and the widened matcher's other new hit was one:
  #      TR-9's v1.24 row, whose "107.2 bits" is a savings-envelope corner that shares the line
  #      with "residual endpoint", not a residual.
  PT='(^|[^0-9.])~?(10[5-9]|1[12][0-9]|13[0-9])(\.[0-9]+)?[- ]?bits?([^[:alnum:]]|$)'
  PT_REVROW='(^|[^0-9.])~?12[0-9](\.[0-9]+)?[- ]?bits?([^[:alnum:]]|$)'
  RANGE_MARK='(^|[^0-9.])~?(10[5-9]|1[12][0-9]|13[0-9])(\.[0-9]+)?(-bits?)? ?(-|–|—|to) ?~?(10[5-9]|1[12][0-9]|13[0-9])(\.[0-9]+)?([^0-9]|$)'
  SCOPE_MARK='(^|[^[:alnum:]])(ranges?|depends on which layers|C1.C5.layer|C1.C5 reading)([^[:alnum:]]|$)|\|C1(–|—|-|∩)C[0-9]'
  while IFS= read -r line; do
    printf '%s' "$line" | grep -qE "$PT" || continue
    if printf '%s' "$line" | grep -qE '^\| *v[0-9]'; then
      printf '%s' "$line" | grep -qE "$PT_REVROW" || continue
    fi
    # a point estimate WITH its scope named is fine -- "~126-bit (C1-C5-layer)" is honest.
    # Only a BARE point estimate, with neither the range nor the layer scope, is the defect.
    printf '%s' "$line" | grep -qE "$RANGE_MARK" && continue
    printf '%s' "$line" | grep -qiE "$SCOPE_MARK" && continue
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
  echo "RESIDUAL_CONSISTENCY_OFFENDERS=-1"; echo "RESIDUAL_CONSISTENCY_SCANNED=$scanned"
  echo "RESIDUAL_CONSISTENCY_ERROR=population-collapsed"
  echo "RESIDUAL_CONSISTENCY=ERROR"; exit 2
fi
echo "RESIDUAL_CONSISTENCY_OFFENDERS=$bad"
echo "RESIDUAL_CONSISTENCY_SCANNED=$scanned"
echo "RESIDUAL_CONSISTENCY=$([ "$bad" -eq 0 ] && echo PASS || echo FAIL)"
[ "$bad" -eq 0 ]
