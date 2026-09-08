#!/usr/bin/env bash
# Q-317 (1) — an UNCAPPED resume must not inherit budget-truncated cells.
#
# THE DEFECT. load_sub_checkpoint_file() decided whether to re-run a stored
# BUDGETED sub-branch with
#     if (current_per_branch_budget > 0 && stored_budget < current_per_branch_budget)
# Budget 0 means UNCAPPED, i.e. infinite. The `> 0` made the guard FALSE for
# exactly that case, so an uncapped resume SKIPPED every stored BUDGETED cell and
# silently inherited budget-truncated results as if they were exhaustive: an
# UNDERCOUNT presented as a complete enumeration, which is the worst direction of
# error for this project.
#
# BOTH DIRECTIONS ARE CHECKED, from the same binary:
#   capped run, stored budget >= current   -> the cell IS skipped   (no regression)
#   uncapped run, any finite stored budget -> the cell is NOT skipped (the fix)
# A one-sided test would pass on a binary that never skips anything.
#
# Verdict: RESUME_BUDGET_INFINITY=PASS|FAIL|ERROR
set -uo pipefail
cd "$(dirname "$0")/.."
BIN=${BIN:-./solve}
[ -x "$BIN" ] || { echo "   [ERROR] no binary at $BIN"; echo "RESUME_BUDGET_INFINITY=ERROR"; exit 2; }

# 🔴 THE BINARY MUST CORRESPOND TO THE SOURCE THIS GATE IS ASSERTING ABOUT.
#    Added 2026-09-08 after this gate reported RESUME_BUDGET_INFINITY=FAIL -- "budget 0 is
#    being read as 'no constraint' instead of infinity" -- against a ./solve dated Sep 5,
#    two days OLDER than 779fff4c (2026-09-07), the commit that fixed exactly that.
#    MEASURED both ways: stale on-disk binary -> FAIL; a binary built from HEAD -> PASS.
#    So the gate was announcing a live undercount-presented-as-complete-enumeration --
#    this project's worst error class -- in an engine where the defect had been fixed for
#    two days. A false alarm in the most expensive possible direction, and it defaulted
#    into that state simply because a stale artifact was lying in the working directory.
#    A gate whose subject is "whatever binary happens to be on disk" is not testing the
#    engine; it is testing the housekeeping.
#    ERROR, not FAIL: an unestablished subject is not a defect, and reporting it as one
#    sends a reader hunting a bug that is not there.
if [ -f solve.c ] && [ solve.c -nt "$BIN" ] && [ "${RESUME_BUDGET_ALLOW_STALE-}" != "1" ]; then
  echo "   [ERROR] $BIN is OLDER than solve.c — it cannot attest anything about the current"
  echo "           source. Rebuild, or pass BIN=<path> to a binary you know matches."
  echo "           (set RESUME_BUDGET_ALLOW_STALE=1 to override, deliberately.)"
  echo "RESUME_BUDGET_INFINITY=ERROR"; exit 2
fi

ckpt_line='Sub-branch BUDGETED (thread -1 [v3.1 promoted], pair1 3 orient1 0 pair2 5 orient2 0): 0 nodes, 0 C3-valid, 7 solutions, 0s elapsed, budget 1000000'

# NOTE ON THE KNOB. SOLVE_NODE_LIMIT cannot be used here: the binary REFUSES any
# value below 1T ("below the canonical-stability threshold ... the output sha256 is
# CODE-SPECIFIC"), and its own error text points at SOLVE_PER_SUB_BRANCH_LIMIT for
# "intentional within-code-state runs", which is exactly what this is.  That
# override sets current_per_branch_budget directly (solve.c:41904, :43098), which
# is the variable under test.
run_case() { # run_case <budget-or-empty>; echoes the completed-from-checkpoint count
  local d out here bin
  here=$(pwd)
  # BIN may be absolute or repo-relative; only the relative form needs $here.
  # Getting this wrong made the gate run a nonexistent path and report FAIL for a
  # reason unrelated to what it tests -- the run simply never happened.
  case "$BIN" in /*) bin="$BIN" ;; *) bin="$here/$BIN" ;; esac
  d=$(mktemp -d "${TMPDIR:-/tmp}/resume_gate_XXXXXX") || return 1
  printf '%s\n' "$ckpt_line" > "$d/checkpoint.txt"
  if [ -n "$1" ]; then
    out=$(cd "$d" && env SOLVE_PER_SUB_BRANCH_LIMIT="$1" SOLVE_DEPTH=2 \
                        timeout 180 "$bin" 1 2 2>&1)
  else
    out=$(cd "$d" && env -u SOLVE_PER_SUB_BRANCH_LIMIT -u SOLVE_NODE_LIMIT SOLVE_DEPTH=2 \
                        timeout 180 "$bin" 1 2 2>&1)
  fi
  rm -rf "$d"
  printf '%s' "$out" | sed -n 's/.*(\([0-9]\+\) completed from checkpoint).*/\1/p' | head -1
}

fails=0
capped=$(run_case 1000)
uncapped=$(run_case "")
echo "   capped run   (stored 1,000,000 >= current): completed-from-checkpoint = ${capped:-0}"
echo "   uncapped run (budget 0 = infinite)        : completed-from-checkpoint = ${uncapped:-0}"

if [ "${capped:-0}" -lt 1 ]; then
  echo "   [FAIL] a capped resume did NOT skip a cell whose stored budget covers it --"
  echo "          this leg would pass on a binary that never skips, so it is checked."
  fails=$((fails+1))
fi
if [ "${uncapped:-0}" -gt 0 ]; then
  echo "   [FAIL] an UNCAPPED resume skipped $uncapped budget-truncated cell(s):"
  echo "          budget 0 is being read as 'no constraint' instead of infinity."
  fails=$((fails+1))
fi
[ "$fails" -eq 0 ] && echo "RESUME_BUDGET_INFINITY=PASS" || echo "RESUME_BUDGET_INFINITY=FAIL"
[ "$fails" -eq 0 ]
