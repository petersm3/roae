#!/usr/bin/env bash
# One-command verification of the ROAE technical-report suite's machine-checkable claims.
# Requirements: gcc, python3, kissat, drat-trim, lean (elan). See reports/METHODS.md for versions.
# https://github.com/petersm3/roae — Developed with AI assistance (Claude, Anthropic)
set -uo pipefail
cd "$(dirname "$0")/../.."
PASS=0; FAIL=0
check() { if eval "$2" >/dev/null 2>&1; then echo "PASS  $1"; PASS=$((PASS+1)); else echo "FAIL  $1"; FAIL=$((FAIL+1)); fi; }

echo "== 1. Enumerator selftest (canonical baseline sha) =="
check "solve.c build" "gcc -O2 -pthread -fopenmp -o /tmp/roae_verify_solve solve.c -lm -lz"
check "--selftest" "/tmp/roae_verify_solve --selftest | grep -q PASS"

echo "== 2. Two-language gates =="
check "solve.py --registry-verify (31 rules)" "python3 solve.py --registry-verify | grep -q 'ALL 31'"
check "f4p two-language match" "diff <(/tmp/roae_verify_solve --f4p-verify) <(python3 solve.py --f4p-verify)"

echo "== 3. DRAT certificates (regenerated CNF vs archived proof) =="
KISSAT=${KISSAT:-kissat}; DRAT=${DRAT:-drat-trim}
declare -A CERTS=( [alt-le-14]="alt-le-14" [alt-ge-16]="alt-ge-16" \
  [moore-strict-near-2]="moore-strict-near-2" [rc4_near2_unsat]="rc4-strict-near-2" \
  [grand_ccn4_unsat]="grand-ccn4" )
for cert in "${!CERTS[@]}"; do
  t=${CERTS[$cert]}
  check "cert $cert ($t)" \
    "python3 sat.py --emit-cnf $t /tmp/roae_$t.cnf && gunzip -kc reports/certificates/$cert.drat.gz > /tmp/roae_$t.drat && $DRAT /tmp/roae_$t.cnf /tmp/roae_$t.drat | grep -q 's VERIFIED'"
done

echo "== 4. Lean kernel check =="
LEAN=${LEAN:-lean}; command -v "$LEAN" >/dev/null || LEAN="$HOME/.elan/bin/lean"
check "lean/KingWen.lean" "\"$LEAN\" lean/KingWen.lean"

echo; echo "RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
