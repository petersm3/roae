#!/bin/bash
# Pre-push compile gate for solve.c
#
# Catches the failure mode that landed commit 85fff78 in main with a
# duplicate-declaration compile error, undetected for hours.
#
# DO NOT install this file as .git/hooks/pre-push directly — that was the
# install from 2026-05-12 to 2026-08-06, and it silently left the doc gates
# with no publish-point coverage. The hook is the DISPATCHER, which runs this
# gate AND scripts/doc_gates.sh:
#
#   ln -sf ../../scripts/pre_push_gate.sh .git/hooks/pre-push
#
# WHAT THIS GATE CHECKS IS THE TREE IT RUNS IN. It compiles solve.c under
# `git rev-parse --show-toplevel` of its working directory, so invoked
# standalone it gates the WORKING TREE — which is NOT what `git push`
# publishes. The dispatcher closes that mismatch (task #150) by running this
# script's own committed copy inside a temporary detached worktree of each
# pushed sha, where toplevel IS the pushed tree; at the push point the bytes
# compiled and selftested are exactly the bytes being published. Standalone
# invocation remains useful as a fast working-tree check while iterating:
#
#   bash scripts/pre_push_compile_gate.sh && git push
#
# Hard-fails (exit 1) on:
#  - solve.c missing or empty
#  - gcc returns non-zero (compile error)
#  - a WARNING outside the inventoried baseline below (new class, or a known
#    class exceeding its baselined count)
#  - verify.c missing, failing to compile, or emitting ANY warning
#  - --selftest does not produce sha 403f7202…
#
# WARNING SEMANTICS (2026-08-06). Until today this gate printed "compiles
# cleanly under -Wall -Wextra" while inspecting ONLY gcc's exit code — gcc
# exits 0 with warnings, so warnings passed in silence (observed live: a
# -Wstringop-truncation warning sailed through a green run). The claim now
# matches the check: stderr is captured and censused per warning class.
#   - solve.c currently emits 12 warnings in 7 classes (measured 2026-08-06,
#     gcc 13.3.0, the orchestrator's stock toolchain — the same toolchain
#     this hook runs on). solve.c is sha-anchored; silencing those 12 goes
#     through its own build/verify pipeline, not through this gate. Until
#     then they are BASELINED BY NAME below — a RATCHET, not an exemption:
#     any new class, or a known class growing, fails the push. When solve.c
#     drops below the baseline this gate says so on every run; ratchet the
#     table down in the same commit.
#   - verify.c is warning-free today and is held at ZERO.
#   - The baseline is toolchain-relative: a different gcc emits a different
#     warning set. If the orchestrator's toolchain moves, re-measure and
#     update the table DELIBERATELY (with the gcc version) — never widen it
#     to make a red run green.

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
SOLVE_C="$REPO_ROOT/solve.c"
VERIFY_C="$REPO_ROOT/verify.c"

if [ ! -s "$SOLVE_C" ]; then
    echo "FAIL: solve.c missing or empty"
    exit 1
fi

TMP_BIN=$(mktemp /tmp/precommit_solve.XXXXXX)
WARN_LOG=$(mktemp /tmp/precommit_warnings.XXXXXX)
trap 'rm -f "$TMP_BIN" "$WARN_LOG"' EXIT

if ! gcc -O3 -Wall -Wextra -pthread -fopenmp -march=native "$SOLVE_C" -lm -lz -o "$TMP_BIN" 2> "$WARN_LOG"; then
    echo "FAIL: solve.c does not compile under -Wall -Wextra"
    cat "$WARN_LOG"
    exit 1
fi

# ---- warning ratchet: census this compile's warnings against the baseline ----
# Baseline: 12 warnings / 7 classes, solve.c @ 2026-08-06, gcc 13.3.0 (see header).
# Format: "<max-count> <class-tag>". The (untagged) row is for warning lines gcc
# emits without a [-W...] tag; none exist today, so any is a new warning.
WARN_BASELINE='3 [-Wmisleading-indentation]
1 [-Wcomment]
1 [-Wunused-variable]
2 [-Wunused-function]
3 [-Wformat-truncation=]'
# [-Wstringop-truncation] REMOVED from the baseline 2026-09-04, in the same commit that fixed its
# only instance. `strncpy(best_dev, dev, sizeof(best_dev)-1)` + an explicit NUL became
# `snprintf(best_dev, sizeof(best_dev), "%s", dev)`, which gcc can see is safe. Removed rather than
# left at 1 because this gate's own guidance is that a stale baseline entry keeps a slot open for a
# FUTURE warning of that class to land unnoticed -- the baseline is a census of what IS, not a budget.

# Census: one "count class" line per class seen. awk ERE has no bounded
# repetition ('+' only). Lines matching ' warning:' but carrying no tag are
# counted as (untagged) so they cannot slide through the census.
WARN_SEEN=$(awk '/warning:/ {
    if (match($0, /\[-W[a-zA-Z0-9=-]+\]/)) c[substr($0, RSTART, RLENGTH)]++;
    else c["(untagged)"]++
} END { for (k in c) print c[k], k }' "$WARN_LOG")

WARN_BAD=0
WARN_TOTAL=0
while read -r n cls; do
    [ -n "$cls" ] || continue
    WARN_TOTAL=$((WARN_TOTAL + n))
    base=$(printf '%s\n' "$WARN_BASELINE" | grep -F -- " $cls" | awk '{print $1}')
    if [ -z "$base" ]; then
        echo "FAIL: solve.c emits a warning class OUTSIDE the baseline: $n x $cls"
        WARN_BAD=1
    elif [ "$n" -gt "$base" ]; then
        echo "FAIL: solve.c warning class $cls grew: $n emitted, baseline $base"
        WARN_BAD=1
    elif [ "$n" -lt "$base" ]; then
        echo "note: solve.c warning class $cls shrank ($n < baseline $base) — ratchet the baseline down"
    fi
done <<EOF
$WARN_SEEN
EOF
# ---- ELIMINATED-CLASS SWEEP -------------------------------------------------
# 🔴 The census loop above iterates over classes that were EMITTED, so it can only
# report a class that SHRANK, never one that reached ZERO — the best outcome is the
# one it cannot see. Measured 2026-08-28: the -Wnonnull memcpy(_,NULL,0) UB in
# h2_ball_enum was fixed, the class went 1 -> 0, and this gate printed its ordinary
# PASS with no ratchet note. A baselined class left standing at zero is not inert:
# it keeps the class PERMANENTLY ALLOWED, so if the defect regresses the ratchet
# accepts it silently at its old count. Same shape as the verifier-closure rule --
# a check must be able to notice the target's ABSENCE, not only its presence.
while read -r base cls; do
    [ -n "$cls" ] || continue
    seen=$(printf '%s\n' "$WARN_SEEN" | grep -F -- " $cls" | awk '{print $1}')
    if [ -z "$seen" ]; then
        echo "note: solve.c warning class $cls is now ELIMINATED (baseline $base, 0 emitted)"
        echo "      — remove it from WARN_BASELINE in this same commit. Leaving it keeps the"
        echo "      class permanently allowed and a regression would pass this gate silently."
    fi
done <<EOF
$WARN_BASELINE
EOF

if [ "$WARN_BAD" -ne 0 ]; then
    echo "----- full -Wall -Wextra output -----"
    cat "$WARN_LOG"
    echo "-------------------------------------"
    echo "A new warning is a defect until adjudicated. If it is genuinely benign and"
    echo "cannot be fixed (solve.c is sha-anchored), extend WARN_BASELINE in this"
    echo "script IN THE SAME COMMIT, with the reason — never silence it by ignoring."
    exit 1
fi

# ---- verify.c: compile + hold at ZERO warnings (clean today, stays clean) ----
if [ ! -s "$VERIFY_C" ]; then
    echo "FAIL: verify.c missing or empty (every tree carrying this gate version has it)"
    exit 1
fi
TMP_VBIN=$(mktemp /tmp/precommit_verify.XXXXXX)
trap 'rm -f "$TMP_BIN" "$WARN_LOG" "$TMP_VBIN"' EXIT
if ! gcc -O2 -Wall -Wextra "$VERIFY_C" -lm -lz -o "$TMP_VBIN" 2> "$WARN_LOG"; then
    echo "FAIL: verify.c does not compile under -Wall -Wextra"
    cat "$WARN_LOG"
    exit 1
fi
VWARN=$(grep -c 'warning:' "$WARN_LOG" || true)
if [ "$VWARN" -ne 0 ]; then
    echo "FAIL: verify.c emits $VWARN warning(s) under -Wall -Wextra (baseline: zero)"
    cat "$WARN_LOG"
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
echo "PASS: solve.c compiles under -Wall -Wextra with $WARN_TOTAL warning(s), all inside"
echo "      the inventoried baseline (12 across 7 classes, 2026-08-06 — no new warnings);"
echo "      verify.c compiles warning-free; selftest produces (binary-internal) canonical sha $ACTUAL"
exit 0
