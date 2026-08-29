#!/usr/bin/env bash
# knuth_c67_repro_gate.sh — Q-395. The published 1169 / 233 / 75 tree-node figures must (a) carry
# their reproduction command in the same document, and (b) still be what the shipped binary prints.
#
# WHY. SEARCH_SPACE_SIZE.md and TR4 published "tree_nodes 1169 → 233" for the C6/C7 pinned check,
# and SEARCH_SPACE_SIZE.md's provenance note told the reader that the public verification path was
# "re-running the published SOLVE_KNUTH_C67 command in this repository". No such command was
# published anywhere in either repository. A reader who tried it had to guess the 22-pair prefix,
# and guessing wrong turns `--estimate-knuth 0` — zero probes, i.e. EXACT enumeration — into an
# unbounded full walk. That is exactly what happened on 2026-08-29: the reproduction attempt was
# killed twice and concluded, wrongly, that no command produced the figures.
#
# This project's standing rule is that a published figure never ships ahead of its reproduction
# command, and that a private script does not make a public number reproducible. This gate is that
# rule made executable.
#
# 🔴 LEG 2 DOES NOT CHECK THE PROSE. It RUNS the commands and compares the binary's own output to
# the published integers. A doc edit cannot satisfy it and a doc typo cannot break it; only the
# code and the figures agreeing satisfies it. Leg 1 (the command is present) is about the reader;
# leg 2 (the command is right) is about the truth.
#
# 🔴 IT IS NOT SATISFIED BY ITS OWN EMPTINESS. If the figures were deleted from the corpus, a
# naive version would pass while measuring nothing — the closure defect (Codex N07: a verifier must
# be FALSE when its target is absent). Absence of the figures is an ERROR here, not a pass.
#
# COST: builds solve.c (~40 s) unless SOLVE_BIN names a binary. The three runs together take under
# 30 ms. Deliberately NOT wired into any periodic tick — a gate that rebuilds the solver on every
# reconcile is a gate that gets removed.
#
# Usage: knuth_c67_repro_gate.sh      [SOLVE_BIN=/path/to/solve]
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

DOCS=(documentation/SEARCH_SPACE_SIZE.md reports/TR4_SIZE_OF_THE_SPACE.md)
rc=0

# ---- LEG 1: every document that PUBLISHES the figures also publishes the command ----
echo "  == LEG 1: the figures do not ship ahead of their reproduction command =="
present=0
for d in "${DOCS[@]}"; do
  [ -r "$d" ] || { echo "  [FAIL] $d unreadable — cannot check a document that is not there."; rc=1; continue; }
  if ! grep -q '1169' "$d" || ! grep -q '233' "$d"; then
    continue                      # this document does not carry the figures; nothing to require
  fi
  present=$((present+1))
  # 🔴 BLOCK-SCOPED, not file-scoped, and the difference was measured. A first cut required each
  # token to appear ANYWHERE in the file, and against the real pre-fix documents only ONE of the
  # four tokens was missing — the others already occurred in scattered prose, including a
  # provenance sentence that merely NAMED the env var while promising a command it never gave.
  # Tokens dotted around a document are not a runnable recipe. All four must occur inside ONE
  # fenced code block, which is the smallest unit a reader can actually copy and paste.
  miss=$(python3 - "$d" <<'PY'
import re, sys
body = open(sys.argv[1], encoding='utf-8', errors='replace').read()
need = {'SOLVE_KNUTH_C67=1': 'SOLVE_KNUTH_C67=1',
        'SOLVE_KNUTH_PIN_SLOTS=': 'SOLVE_KNUTH_PIN_SLOTS',
        '--estimate-knuth 0': '--estimate-knuth-0',
        '1 0 2 0 3 0': 'the-22-pair-prefix'}
blocks = re.findall(r'^```[^\n]*\n(.*?)^```', body, re.M | re.S)
best = None
for b in blocks:
    missing = [label for tok, label in need.items() if tok not in b]
    if best is None or len(missing) < len(best):
        best = missing
    if not missing:
        best = []
        break
if best is None:
    best = ['no-fenced-code-block-at-all']
print(' '.join(best))
PY
)
  miss=$(printf '%s' "$miss" | tr -s ' ')
  if [ -n "$miss" ]; then
    echo "  [FAIL] $d publishes 1169/233 but no single code block runs them; missing from the closest block: $miss"
    echo "         A reader cannot check this figure, and guessing the prefix turns an exact"
    echo "         subtree enumeration into an unbounded full walk."
    rc=1
  else
    echo "  [ok]   $d publishes the figures AND the invocation"
  fi
done
if [ "$present" -lt 2 ]; then
  echo "  [FAIL] only $present of ${#DOCS[@]} document(s) still carry the 1169/233 figures."
  echo "         With the subject gone this gate would measure nothing, so this is an ERROR."
  echo "KNUTH_C67_REPRO=ERROR population-collapsed"; exit 1
fi

# ---- LEG 2: the binary still prints those integers ----
echo "  == LEG 2: the shipped binary still prints them =="
BIN=${SOLVE_BIN:-}
if [ -z "$BIN" ]; then
  BIN=$(mktemp -u /tmp/claude-1000/solve_knuthgate.XXXXXX)
  gcc -O2 -pthread -fopenmp -o "$BIN" solve.c -lm -lz 2>/dev/null || {
    echo "KNUTH_C67_REPRO=ERROR build-failed"; exit 1; }
  trap 'rm -f "$BIN"' EXIT
fi
[ -x "$BIN" ] || { echo "KNUTH_C67_REPRO=ERROR not-executable:$BIN"; exit 1; }

PREFIX=""
for i in $(seq 1 22); do PREFIX="$PREFIX $i 0"; done

# label | expected tree_nodes | PIN_SLOTS value ("" = none)
run_case(){
  local label=$1 want=$2 pins=$3 out got
  if [ -n "$pins" ]; then
    out=$( ulimit -s unlimited 2>/dev/null; SOLVE_KNUTH_C67=1 SOLVE_KNUTH_PIN_SLOTS="$pins" "$BIN" --estimate-knuth 0 $PREFIX 2>&1 )
  else
    out=$( ulimit -s unlimited 2>/dev/null; SOLVE_KNUTH_C67=1 "$BIN" --estimate-knuth 0 $PREFIX 2>&1 )
  fi
  got=$(printf '%s\n' "$out" | awk '/tree_nodes/{print $NF; exit}')
  if [ "$got" = "$want" ]; then
    echo "  [ok]   $label -> tree_nodes $got"
  else
    echo "  [FAIL] $label -> tree_nodes '${got:-<none>}', published figure is $want"
    echo "         Either the figure is stale or the estimator changed. Do not edit the number"
    echo "         to match: find out which of the two moved."
    rc=1
  fi
}
run_case "C6/C7 only, no slot pins          " 1169 ""
run_case "C6/C7 + steps 24-31 (positions 25-32)" 233 "24,25,26,27,28,29,30,31"
run_case "C6/C7 + every free step 23-31     "   75 "23,24,25,26,27,28,29,30,31"

[ "$rc" -eq 0 ] || { echo "KNUTH_C67_REPRO=FAIL"; exit 1; }
echo "KNUTH_C67_REPRO=OK"
