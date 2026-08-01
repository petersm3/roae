#!/usr/bin/env bash
# doc_gates.sh — mechanical documentation-integrity gates.
#
# WHY THIS EXISTS
#   The code layer has hard gates (canonical sha, compile gate, tests.py, DRAT certs).
#   The DOC layer had none, so doc-level defects depended on review luck. On 2026-08-01
#   two full adversarial AI review passes cleared the repo and a third found ~20 real
#   defects — including a retracted claim still stated on the README front page, hidden
#   because a revision entry *asserted* the correction had propagated. These three gates
#   turn that class of failure from "hope a reviewer notices" into "the script fails".
#
# USAGE
#   scripts/doc_gates.sh numbers    # cross-file numeric consistency (long integers)
#   scripts/doc_gates.sh cli        # CLI flags live in code but absent from the CLI docs
#   scripts/doc_gates.sh retract    # retracted phrasings that still survive in the corpus
#   scripts/doc_gates.sh all        # run all three
#
# EXIT: 0 = clean, 1 = findings. Report-only classes print [WARN]; hard failures print [FAIL].
#
# SAFETY: index-based (`git ls-files`/`git grep`) and fixed-string matching only.
#   No `find` over trees, no bounded-repetition regex (`.{0,N}`) — a pathological
#   `grep -oE ".{0,80}X.{0,60}"` hung the 2-core orchestrator on a 381-byte input
#   (2026-08-01); cost lives in the PATTERN, not only the data.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
RC=0

DOCS=$(git ls-files '*.md' | grep -v '^example/' || true)

# ----------------------------------------------------------------------------------
gate_numbers() {
  echo "== GATE 1: cross-file numeric consistency (long integers) =="
  # Extract integers of >=12 digits (commas stripped). Group by their first 10 digits.
  # A group holding more than one DISTINCT full value means two docs disagree about
  # what is almost certainly the same quantity (e.g. a single corrupted digit).
  # Key = (length, first 10 digits). SAME LENGTH matters: a corrupted digit preserves
  # length, whereas 10^11 vs 10^12 are simply different budgets, not a disagreement.
  # Round numbers (>=4 trailing zeros) are budgets/powers of ten — skipped.
  # Report-only ([WARN]) with an allowlist, because legitimately-close pairs exist
  # (e.g. a byte count with and without the 32-byte header).
  local tmp allow; tmp=$(mktemp)
  allow="documentation/DOC_GATE_NUMBER_ALLOWLIST.txt"
  for f in $DOCS; do
    grep -oE '[0-9][0-9,]{11,}' "$f" 2>/dev/null | tr -d ',' \
      | awk -v F="$f" 'length($0)>=12 && $0 !~ /0000$/ {print length($0)":"substr($0,1,10)"\t"$0"\t"F}'
  done | sort -u > "$tmp"

  local found=0
  while read -r key; do
    [ -z "$key" ] && continue
    if [ -f "$allow" ] && grep -qxF -- "$key" "$allow" 2>/dev/null; then continue; fi
    echo "  [WARN] near-twin long integers (same length, same 10-digit prefix) — key $key:"
    awk -v K="$key" -F'\t' '$1==K {print "      "$2"   <- "$3}' "$tmp" | sort -u
    found=1
  done < <(cut -f1,2 "$tmp" | sort -u | cut -f1 | uniq -d)

  if [ "$found" -eq 0 ]; then
    echo "  [ok] no long integer disagrees with a same-length near-twin elsewhere"
  else
    echo "  (report-only: confirm each pair is intentional, then add its key to $allow)"
  fi
  rm -f "$tmp"
  return 0   # report-only gate — never blocks
}

# ----------------------------------------------------------------------------------
gate_cli() {
  echo "== GATE 2: CLI flags live in code but undocumented =="
  local bad=0
  check_pair() { # $1=code file  $2=doc file  $3=extractor
    local code="$1" doc="$2" mode="$3" cf df miss
    [ -f "$code" ] && [ -f "$doc" ] || { echo "  [skip] $code / $doc"; return 0; }
    cf=$(mktemp); df=$(mktemp)
    if [ "$mode" = py ]; then
      grep -oE 'add_argument\("--[a-z0-9][a-z0-9_-]*' "$code" | sed 's/.*"//' | sort -u > "$cf"
    else
      grep -oE '"--[a-z0-9][a-z0-9-]*"' "$code" | tr -d '"' | sort -u > "$cf"
    fi
    grep -oE -- '--[a-z0-9][a-z0-9_-]*' "$doc" | sort -u > "$df"
    miss=$(comm -23 "$cf" "$df")
    if [ -n "$miss" ]; then
      echo "  [FAIL] in $code but NOT in $doc:"; echo "$miss" | sed 's/^/      /'; bad=1
    else
      echo "  [ok] $code fully documented in $doc"
    fi
    rm -f "$cf" "$df"
  }
  check_pair roae.py  documentation/ROAE_PY_CLI.md  py
  check_pair solve.py documentation/SOLVE_PY_CLI.md py
  check_pair solve.c  documentation/SOLVE_C_CLI.md  c
  return $bad
}

# ----------------------------------------------------------------------------------
gate_retract() {
  echo "== GATE 3: retracted phrasings still surviving =="
  # Registry-driven and deliberately so: auto-parsing retraction prose is unreliable,
  # and a wrong gate is worse than none. Each entry is a FIXED string that was retracted;
  # the gate fails if it appears anywhere outside the files allowed to narrate the retraction.
  local reg="documentation/RETRACTED_PHRASES.tsv"
  [ -f "$reg" ] || { echo "  [skip] no $reg"; return 0; }
  local bad=0
  while IFS=$'\t' read -r phrase allow note; do
    case "$phrase" in ''|'#'*) continue;; esac
    local hits
    # Exempt (a) the doc allowed to narrate the retraction, and (b) Revision-History
    # rows — a changelog entry quoting the superseded wording is describing history,
    # which is exactly what the no-silent-edit policy requires it to do.
    hits=$(git grep -F -n -- "$phrase" -- '*.md' 2>/dev/null \
           | grep -v -F "$allow" \
           | grep -vE '^[^:]+:[0-9]+:\| v[0-9]' || true)
    if [ -n "$hits" ]; then
      echo "  [FAIL] retracted phrasing still present: \"$phrase\""
      echo "         ($note)"
      echo "$hits" | cut -c1-150 | sed 's/^/      /'
      bad=1
    else
      echo "  [ok] retracted: \"$phrase\""
    fi
  done < "$reg"
  return $bad
}

case "${1:-all}" in
  numbers) gate_numbers || RC=1 ;;
  cli)     gate_cli     || RC=1 ;;
  retract) gate_retract || RC=1 ;;
  all)     gate_numbers || RC=1; echo; gate_cli || RC=1; echo; gate_retract || RC=1 ;;
  *) echo "usage: $0 {numbers|cli|retract|all}"; exit 2 ;;
esac

echo
[ "$RC" -eq 0 ] && echo "DOC GATES: PASS" || echo "DOC GATES: FINDINGS (see above)"
exit $RC
