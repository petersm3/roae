#!/usr/bin/env bash
# Canonical PGO build helper for solve.c.
#
# Builds solve in two passes (instrument → profile-gen → use) with
# the hardened path-handling discipline that prevents the silent
# no-PGO fallback first observed in the v1-vs-v3 paired bench
# 2026-05-24. See:
#   x/roae/V1_V3_PAIRED_BENCH_RESULTS_2026_05_24.md
#   x/roae/OVERNIGHT_2026_05_24_AUTONOMOUS_SUMMARY.md
#
# Three discipline rules this script enforces:
#   1. Same output binary name in both passes (then rename), so the
#      .gcda lookup key under -flto matches.
#   2. -Werror=missing-profile on Pass 2 — any future regression
#      fails the build LOUD instead of silently falling back to no-PGO.
#   3. Assert .gcda file count > 0 between passes — verifies that
#      Pass 1 actually wrote profile data before Pass 2 starts.
#
# Usage:
#   build_pgo.sh [output_name [build_dir [source_file [pgo_workload_cmd]]]]
#
# Args:
#   output_name        Final binary name. Default: solve_pgo
#   build_dir          Where to build (must contain source_file).
#                      Default: $(pwd)
#   source_file        Source filename relative to build_dir.
#                      Default: solve.c
#   pgo_workload_cmd   Command to run the instrumented binary for
#                      profile collection. Default: a short 1B-node
#                      enum workload at SOLVE_PER_SUB_BRANCH_LIMIT=6315.
#                      It is NOT representative of a canonical run:
#                      PERFORMANCE_HISTORY.md ("Workload mismatch")
#                      records that it trains the budget-bound exit
#                      code, not the DFS hot path the 1T canonical run
#                      (1000x the per-branch limit) spends its time in
#                      (V3A-102#4).
#                      The string is eval'd; use $INSTR_BIN to refer
#                      to the instrumented binary path. It runs with
#                      its working directory set to a FRESH
#                      subdirectory of build_dir (pgo_work.XXXXXX), so
#                      a later build never resumes the checkpoints an
#                      earlier one left (V3A-102#2); a workload that
#                      needs a file from build_dir must name it by
#                      absolute path.
#                      It MUST exit 0: a non-zero workload is an ERROR
#                      (2026-09-24, Q-749). A sub-canonical node limit
#                      needs SOLVE_PER_SUB_BRANCH_LIMIT (as the default
#                      sets) or SOLVE_ALLOW_SUB_CANONICAL=1, or solve.c
#                      refuses it with rc 25.
#                      It MUST also FINISH (2026-09-27, Q-828): solve.c
#                      exits 0 after a SIGTERM too, so the workload log
#                      must hold solve's whole-line ENUM_RUN=FINISHED and
#                      no ENUM_RUN=STOPPED or "*** Signal received" line,
#                      or the build is an ERROR with no Pass 2. Bound the
#                      workload with a node limit, not a time limit or a
#                      signal.
#
# Logs: the two selftest logs and the workload log go to a fresh
#   mktemp directory, build_dir/pgo_logs.XXXXXX, printed at the end and
#   kept for forensics like the workload directory. They were fixed
#   /tmp/pgo_*.log names until 2026-09-27 (Q-856): two concurrent builds
#   overwrote each other's log, and the failure path tails that log.
#
# Example (560T-class build):
#   cd /home/solver/src
#   scripts/build_pgo.sh solve_v3 /home/solver/build_dir
#
# Example with custom workload (the source file is the 3rd argument; the
# workload was once written in its slot, which fails "... not found"):
#   scripts/build_pgo.sh solve /opt/build solve.c \
#     'SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=5000000000 \
#      SOLVE_PER_SUB_BRANCH_LIMIT=31577 \
#      SOLVE_THREADS=$(nproc) SOLVE_SKIP_AUTOMERGE=1 \
#      "$INSTR_BIN" 0 $(nproc)'

set -uo pipefail

OUTPUT="${1:-solve_pgo}"
BUILD_DIR="${2:-$(pwd)}"
SOURCE_FILE="${3:-solve.c}"
DEFAULT_WORKLOAD='SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=1000000000 SOLVE_PER_SUB_BRANCH_LIMIT=6315 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_THREADS=$(nproc) SOLVE_SKIP_AUTOMERGE=1 "$INSTR_BIN" 0 $(nproc)'
PGO_WORKLOAD="${4:-$DEFAULT_WORKLOAD}"

# Absolute, because the script `cd`s into it below (V3A-102#3: a relative
# build_dir broke the `mv` after the cd).
BUILD_DIR=$(cd "$BUILD_DIR" 2>/dev/null && pwd) || {
    echo "ERROR: build_dir ${2:-} is not a directory" >&2; exit 1; }

PROFILE_DIR="$BUILD_DIR/pgo_profile_$$"
INSTR_BIN="$BUILD_DIR/${OUTPUT}.instr"
FINAL_BIN="$BUILD_DIR/${OUTPUT}"

CFLAGS_BASE="-O3 -flto -pthread -fopenmp -march=native"

# Sanity: source must be present
if [ ! -f "$BUILD_DIR/$SOURCE_FILE" ]; then
    echo "ERROR: $BUILD_DIR/$SOURCE_FILE not found" >&2
    exit 1
fi

# Clean state
rm -rf "$PROFILE_DIR" "$INSTR_BIN" "$FINAL_BIN"
mkdir -p "$PROFILE_DIR"

cd "$BUILD_DIR"

# Q-856: per-build log directory (see "Logs" in the header). Made before
# anything runs, so a mktemp failure has nothing to clean up.
LOG_DIR=$(mktemp -d "$BUILD_DIR/pgo_logs.XXXXXX") || {
    echo "ERROR: could not create a fresh log directory under $BUILD_DIR" >&2; exit 1; }

# ===== Pass 1: instrumented build =====
# Build to the SAME output name as Pass 2 will use, then rename to
# .instr. This makes the .gcda lookup key under -flto identical
# between passes (the LTO-recompile step embeds the output binary's
# basename in the .gcda file path).
echo "[$(date -u +%FT%TZ)] PGO Pass 1: instrumented build"
gcc $CFLAGS_BASE -fprofile-generate="$PROFILE_DIR" \
    -o "${OUTPUT}" "$SOURCE_FILE" -lm -lz
mv "${OUTPUT}" "$INSTR_BIN"

if [ ! -x "$INSTR_BIN" ]; then
    echo "ERROR: Pass 1 build did not produce $INSTR_BIN" >&2
    exit 1
fi

# Quick selftest gate on the instrumented binary
echo "[$(date -u +%FT%TZ)] PGO Pass 1: instrumented selftest"
if ! "$INSTR_BIN" --selftest > "$LOG_DIR/pass1_selftest.log" 2>&1; then
    echo "ERROR: instrumented binary failed selftest" >&2
    tail -20 "$LOG_DIR/pass1_selftest.log" >&2
    exit 1
fi

# 🔴 2026-09-24 (Q-749, Codex v3 E3 V3A-102#1). The selftest above is a
# sanity gate, NOT training data, and its .gcda used to stay in
# $PROFILE_DIR. With the workload `false` the script printed "workload
# returned non-zero; checking .gcda anyway", found the selftest's one
# .gcda, and reported "PGO build complete" at rc 0 -- rule 3 above
# ("Pass 1 actually wrote profile data") satisfied without any workload.
# The selftest's profile is cleared here, and the workload's status is
# read: non-zero is an ERROR. (The old comment said a node-limit hit may
# exit non-zero; measured on the worker, a budgeted run exits 0.)
rm -rf "$PROFILE_DIR"
mkdir -p "$PROFILE_DIR"

# ===== Profile-gen workload =====
# Run the instrumented binary on the training workload so it writes
# .gcda profile data files.
# 🔴 2026-09-25 (Q-756, Codex v3 E3 V3A-102#2). The default workload sets
# SOLVE_DFS_CHECKPOINT=1 and used to run in $BUILD_DIR itself, which the
# clean-state step above does not clear of sub_*.dfs_state files: a second
# build in the same directory resumed the first one's checkpoints and
# trained on whatever work was left. The workload now runs in a new
# directory made by mktemp, so it always starts from nothing. (.gcda files
# go to the absolute $PROFILE_DIR, so the working directory does not move them.)
WORK_DIR=$(mktemp -d "$BUILD_DIR/pgo_work.XXXXXX") || {
    echo "ERROR: could not create a fresh workload directory under $BUILD_DIR" >&2; exit 1; }
echo "[$(date -u +%FT%TZ)] PGO profile-gen workload (in $WORK_DIR)"
export INSTR_BIN
( cd "$WORK_DIR" && eval "$PGO_WORKLOAD" ) > "$LOG_DIR/workload.log" 2>&1
WORKLOAD_RC=$?
if [ "$WORKLOAD_RC" -ne 0 ]; then
    echo "ERROR: PGO workload exited rc=$WORKLOAD_RC; refusing to build a PGO binary from it" >&2
    echo "       workload log:" >&2
    tail -20 "$LOG_DIR/workload.log" >&2
    exit 1
fi

# 🔴 2026-09-27 (Q-828). rc 0 does not mean the workload FINISHED. solve.c
# answers SIGTERM/SIGINT (a spot eviction, a `timeout`, a Ctrl-C) by
# checkpointing and exiting 0, so a workload stopped after a few seconds
# passed the check above and Pass 2 built from a partial profile without a
# word. The default workload sets SOLVE_SKIP_AUTOMERGE, whose exit printed
# the same line either way ("SOLVE_SKIP_AUTOMERGE set; skipping bundled
# merge", solve.c:49949) and no report, so no line of its log told the two
# apart. solve.c now prints a whole-line verdict at every enumeration exit:
#   ENUM_RUN=FINISHED   the run ended on its own (tree exhausted or node budget reached)
#   ENUM_RUN=STOPPED    a signal or the time limit stopped it (global_timed_out)
# (solve.c:49951, the SOLVE_SKIP_AUTOMERGE exit; solve.c:50412, the full
# report, beside "*** SEARCH COMPLETE" / "TIMED OUT after"; solve.c:49273,
# --branch; solve.c:48883, parallel --sub-branch). The signal handler also
# writes "*** Signal received" (solve.c:1484) to stderr. The log must carry
# ENUM_RUN=FINISHED and neither stop line; a workload of several runs thus
# needs every run to finish. Bound a training workload with a node limit,
# never with a time limit or a signal.
PGO_STOP_RE='^(ENUM_RUN=STOPPED|\*\*\* Signal received)'
if grep -Eq "$PGO_STOP_RE" "$LOG_DIR/workload.log"; then
    echo "ERROR: PGO workload was STOPPED before it finished (Q-828); refusing to build a PGO binary from a partial profile" >&2
    echo "       stop line(s) in $LOG_DIR/workload.log:" >&2
    grep -E "$PGO_STOP_RE" "$LOG_DIR/workload.log" | head -5 >&2
    exit 1
fi
if ! grep -qx 'ENUM_RUN=FINISHED' "$LOG_DIR/workload.log"; then
    echo "ERROR: PGO workload log has no ENUM_RUN=FINISHED line (Q-828); refusing to build a PGO binary from it" >&2
    echo "       workload log ($LOG_DIR/workload.log):" >&2
    tail -20 "$LOG_DIR/workload.log" >&2
    exit 1
fi

# ===== Assert profile data was produced =====
# This is the belt-and-suspenders check that prevents Pass 2 from
# proceeding to a no-PGO build silently.
GCDA_COUNT=$(find "$PROFILE_DIR" -name '*.gcda' | wc -l)
if [ "$GCDA_COUNT" -eq 0 ]; then
    echo "ERROR: PGO profile-gen produced no .gcda files in $PROFILE_DIR" >&2
    echo "       workload log:" >&2
    tail -20 "$LOG_DIR/workload.log" >&2
    exit 1
fi
echo "  PGO Pass 1: $GCDA_COUNT .gcda files in $PROFILE_DIR"

# ===== Pass 2: optimized build using profile data =====
# Build to the SAME output name as Pass 1 used (which we then
# renamed to .instr above). The LTO .gcda lookup key under
# this output name now matches what Pass 1 wrote.
#
# -Werror=missing-profile turns the GCC warning that previously
# caused our silent no-PGO fallback into a hard build failure.
# If a future change breaks PGO path resolution, this script
# exits non-zero instead of producing a quietly-non-PGO binary.
echo "[$(date -u +%FT%TZ)] PGO Pass 2: optimized build (with -Werror=missing-profile)"
gcc $CFLAGS_BASE -fprofile-use="$PROFILE_DIR" -fprofile-correction \
    -Werror=missing-profile \
    -o "${OUTPUT}" "$SOURCE_FILE" -lm -lz

if [ ! -x "$BUILD_DIR/${OUTPUT}" ]; then
    echo "ERROR: Pass 2 build did not produce $FINAL_BIN" >&2
    exit 1
fi

# Final selftest gate
echo "[$(date -u +%FT%TZ)] PGO Pass 2: optimized selftest"
if ! "$FINAL_BIN" --selftest > "$LOG_DIR/pass2_selftest.log" 2>&1; then
    echo "ERROR: PGO-built binary failed selftest" >&2
    tail -20 "$LOG_DIR/pass2_selftest.log" >&2
    exit 1
fi

echo "[$(date -u +%FT%TZ)] PGO build complete"
echo "  binary:        $FINAL_BIN"
sha256sum "$FINAL_BIN"
echo "  gcda files:    $GCDA_COUNT (in $PROFILE_DIR)"
echo "  instrumented:  $INSTR_BIN (kept for forensics; rm to free space)"
echo "  workload dir:  $WORK_DIR (its checkpoints; kept for forensics, rm to free space)"
echo "  logs:          $LOG_DIR (selftest + workload logs; kept for forensics)"

# Don't auto-cleanup — caller decides whether to remove $PROFILE_DIR,
# $WORK_DIR, $LOG_DIR and $INSTR_BIN. They're useful for reproducibility forensics.
