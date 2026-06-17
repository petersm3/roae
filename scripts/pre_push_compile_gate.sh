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

if ! gcc -O3 -Wall -Wextra -pthread -fopenmp -march=native "$SOLVE_C" -lm -lz -o "$TMP_BIN" 2>&1; then
    echo "FAIL: solve.c does not compile cleanly under -Wall -Wextra"
    exit 1
fi

# selftest is fast (~30s on a 2-core orchestrator) and exercises the full enum+merge
# pipeline at depth-2, SOLVE_THREADS=4, SOLVE_NODE_LIMIT=100M. The binary's own
# hardcoded expected_sha is the authoritative target — branch-aware: v1 lineage
# (main) expects 403f7202..., v2 lineage (v2-bundled) expects its current v2 sha.
# We trust --selftest's internal comparison + exit code (0 = PASS, non-0 = FAIL).
# Source changes that alter the produced sha must also update the expected_sha
# constant inside solve.c at the --selftest dispatcher; otherwise this gate fails.
SELFTEST_OUT=$(mktemp /tmp/precommit_selftest.XXXXXX)
trap 'rm -f "$TMP_BIN" "$SELFTEST_OUT"' EXIT
if ! "$TMP_BIN" --selftest > "$SELFTEST_OUT" 2>&1; then
    echo "FAIL: --selftest exited non-zero"
    cat "$SELFTEST_OUT"
    echo ""
    echo "If this is an intentional sha change, update the expected_sha constant"
    echo "in solve.c at the --selftest dispatcher, then re-run this gate."
    exit 1
fi
ACTUAL=$(awk '/Actual sha256:/ {print $4}' "$SELFTEST_OUT" | head -1)
echo "PASS: solve.c compiles + selftest produces (binary-internal) canonical sha $ACTUAL"
exit 0
