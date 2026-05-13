#!/bin/bash
# Pre-push compile gate for solve.c
#
# Catches the failure mode that landed commit 85fff78 in main with a
# duplicate-declaration compile error, undetected for hours. Install via:
#
#   ln -s ../../scripts/pre_push_compile_gate.sh .git/hooks/pre-push
#   chmod +x .git/hooks/pre-push
#
# Or invoke directly as part of any commit-and-push workflow:
#
#   bash scripts/pre_push_compile_gate.sh && git push
#
# Hard-fails (exit 1) on:
#  - solve.c missing or empty
#  - gcc returns non-zero (compile error)
#  - --selftest does not produce sha 403f7202…

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
SOLVE_C="$REPO_ROOT/solve.c"

if [ ! -s "$SOLVE_C" ]; then
    echo "FAIL: solve.c missing or empty"
    exit 1
fi

TMP_BIN=$(mktemp /tmp/precommit_solve.XXXXXX)
trap 'rm -f "$TMP_BIN"' EXIT

if ! gcc -O3 -Wall -Wextra -pthread -fopenmp -march=native "$SOLVE_C" -lm -o "$TMP_BIN" 2>&1; then
    echo "FAIL: solve.c does not compile cleanly under -Wall -Wextra"
    exit 1
fi

# selftest is fast (~30s on a 2-core orchestrator) and exercises the full enum+merge
# pipeline at depth-2, SOLVE_THREADS=4, SOLVE_NODE_LIMIT=100M. Sha must equal the
# canonical baseline 403f7202… — change of this sha is a regression unless
# accompanied by a corresponding update to the expected_sha constant in solve.c.
EXPECTED="403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e"
ACTUAL=$("$TMP_BIN" --selftest 2>&1 | awk '/Actual sha256:/ {print $4}' | head -1)

if [ "$ACTUAL" != "$EXPECTED" ]; then
    echo "FAIL: selftest sha mismatch"
    echo "  expected: $EXPECTED"
    echo "  actual:   $ACTUAL"
    echo "If this is an intentional sha change, update the expected_sha constant"
    echo "in solve.c around line 6346, then re-run this gate."
    exit 1
fi

echo "PASS: solve.c compiles + selftest produces canonical sha $EXPECTED"
exit 0
