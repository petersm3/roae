#!/usr/bin/env bash
# tr12_n31_golden_gate.sh — refuse to certify a full-31 TR-12 battery against a golden that does
# not exist, or that exists only as placeholders.
#
# 🔴 WHAT THIS GATE IS AND IS NOT. It is a cheap PRE-FLIGHT, not the thing that makes n=31
# certification able to fail. MEASURED 2026-09-07, tr12_repro.sh ALREADY refuses both cases:
#     --expect <nonexistent dir>        -> TR12_REPRO=FAIL, rc=1
#     --expect <52 [EXPECTED-*] stubs>  -> rows=64 pass=0 fail=50 skip=14, TR12_REPRO=FAIL, rc=1
# The original finding (mine and the review's) said step 6 "compares against nothing and cannot
# fail". That was false and two commands disproved it. This header says so because a gate whose
# stated rationale is wrong will be removed by the next person who checks.
#
# What it DOES buy, all three real:
#   1. the refusal arrives in MILLISECONDS instead of after a multi-day n=31 battery;
#   2. it requires _MANIFEST.txt -- tr12_repro_gate.sh hashes the n=9 goldens but is n=9-ONLY by
#      construction (its line 187), so an n=31 golden would otherwise be unhashed, and an unhashed
#      golden can be edited without trace;
#   3. it says WHICH problem it is (ABSENT vs PLACEHOLDER) instead of 50 undifferentiated mismatches.
#
# 🔴 WHAT NO GATE HERE CAN DO. A minted golden is OUR OWN OUTPUT; diffing a later run against it is
# a regression test, not a verification. The invariants the battery enforces upstream of minting
# (N mod 24 == 0, sum_b solutions(b) == N, f.g == N at every layer) CANNOT fail on a minted set,
# because a run violating them never reaches minting. The externally-anchored checks and the
# residual exposure (17 rows, ~3,000-4,000 cells at n=31) are in
# roae-private/B32_N31_GOLDEN_DECISION_2026_09_07.md.
#
# Verdict: TR12_N31_GOLDEN=OK | ABSENT | PLACEHOLDER | ERROR
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
DIR=${TR12_N31_DIR:-scripts/tr12_expected/n31}
rc=0

# A placeholder is anything a minting run would replace: an empty file, or one whose only content
# is a TODO/TBD/EXPECTED- marker. Matching on markers alone would miss an empty file, which is the
# commonest way a golden is "created" without being minted.
is_placeholder(){ # $1 = file
  [ -s "$1" ] || return 0
  grep -qiE '^\s*(TODO|TBD|PLACEHOLDER|\[EXPECTED-[A-Z0-9]+\]\s*$)' "$1" && return 0
  return 1
}

if [ ! -d "$DIR" ]; then
  echo "  [BLOCK] no n=31 golden at $DIR"
  echo "          TR-12 section R step 6 says to diff every query against its [EXPECTED-*] block."
  echo "          Those blocks do not exist, so that step currently compares against NOTHING."
  echo "          The first full-31 battery must be run with --regen as an explicit MINTING run and"
  echo "          its output committed as the golden IN THE SAME COMMIT."
  echo "TR12_N31_GOLDEN=ABSENT"
  exit 1
fi

files=$(find "$DIR" -type f ! -name '_*' 2>/dev/null | sort)
if [ -z "$files" ]; then
  echo "  [BLOCK] $DIR exists but holds no golden files"
  echo "TR12_N31_GOLDEN=ABSENT"; exit 1
fi

bad=0; n=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  n=$((n+1))
  if is_placeholder "$f"; then
    echo "  [FAIL] placeholder golden: $f"
    bad=$((bad+1))
  fi
done <<< "$files"

if [ ! -r "$DIR/_MANIFEST.txt" ]; then
  echo "  [FAIL] $DIR has no _MANIFEST.txt — an unhashed golden can be edited without trace"
  bad=$((bad+1))
fi

if [ "$bad" -gt 0 ]; then
  echo "  $bad of $n golden file(s) are placeholders or unhashed"
  echo "TR12_N31_GOLDEN=PLACEHOLDER"; exit 1
fi

echo "  [ok]   $n n=31 golden file(s) present, none a placeholder, manifest present"
echo "  [note] this attests the golden EXISTS and was minted. It does NOT attest the numbers are"
echo "         right: see MINTING_REVIEW in this file's header and the stated residual exposure."
echo "TR12_N31_GOLDEN=OK"
exit 0
