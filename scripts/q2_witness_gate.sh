#!/usr/bin/env bash
# =============================================================================
# q2_witness_gate.sh — the red test for the FIRST^C15 / LAST^C15 witness requirement.
# Emits exactly one whole-line token: Q2_WITNESS=PASS | FAIL | ERROR
#
# 2026-09-11. Claude (Opus 5). Developed with AI assistance (Claude, Anthropic).
# Raised by external reviewer R5 (item 4), adjudicated in roae-private. Backlog Q-487.
#
# WHY THIS EXISTS.
# Rows a1_q2c / a1_q2d published FIRST^C15 and LAST^C15 with the solver's EXIT STATUS as
# their only failure flag. An enumeration that finds NOTHING exits 0. Measured against the
# real binary at n=9:
#     --kc-enum      f --kc-c3-max 0 --kc-limit 1  ->  "[kc] enumerated 0 walk(s) (C3 in-path)"  rc 0
#     --kc-enum-desc f --kc-c3-max 0 --kc-limit 1  ->  "... 0 walk(s) ... (descending)"          rc 0
# At n=31 the golden is MINTED from whatever was emitted, so an n=31-only pruning defect that
# suppressed every candidate -- or a wrong C3 threshold plumbed into the row -- would have
# published an EMPTY extremal walk as TR12_Q2C=PASS. The battery ships FROZEN by `git archive`
# at launch, so the fix had to be inside the battery for the run's own verdict to be honest.
#
# SCOPE, stated so it is not read as more than it is. EXTREMALITY IS NOT CHECKED HERE.
# ⚠ IT IS NOT UNCHECKABLE -- B32's limit was read too widely and this text said so until 2026-09-11.
# WHAT IS TRUE: extremality IS decidable, and this gate does not decide it. (a) A SUFFICIENT
# certificate, one call: if the emitted walk is in F = {cd <= T} and `--kc-rank` returns 0, it is
# min SUPER and therefore min F. Symmetric at N-1 for LAST. (b) A GENERAL EXACT certificate:
# w = min F iff w is in F and every u with rank(u) < rank(w) has cd(u) > T -- decidable in
# rank(w) `--kc-unrank` + `--kc-profile` calls, and it is a SECOND IMPLEMENTATION of the
# enumerator's claim (unrank+profile against the in-path C3 pruner). MEASURED on the real engine:
# `--kc-enum` emits in `--kc-rank` order and `--kc-enum-desc` in reverse; at n=9, T=31 gives
# rank 0 (0 calls), T=28 gives rank 88 and all 88 predecessors have cd>28 -- CERTIFIED; LAST at
# T=28 certified over 864 successors. At n=31 with T=387 the banked C3 acceptance rate is ~0.121,
# so rank(FIRST^C15) is geometric with mean ~8 and the certificate costs ~8 calls.
# IT IS POST-HOC: the walk and the f ladder are both retained, so it runs AFTER the run and is
# NOT frozen. It is not done here.
# This gate proves the row
# refuses to publish (a) nothing at all, (b) a walk the structure does not call a member, and
# (c) a walk violating the row's own C3 bound. It says NOTHING about whether the emitted walk
# is the least or the greatest one.
#
# WHY IT EXTRACTS AND EXECUTES rather than re-implementing the check.
# F-5 round 6: a gate built to catch verifier closure was written with a hand-copied second
# instance of the row's logic. Restoring the real defect in the real row left that gate
# PASSing; deleting the battery outright left it PASSing. It bound to a COPY. So the helper
# and BOTH rows here are extracted from scripts/tr12_repro.sh by their own markers and run,
# and an absent or empty extraction is ERROR -- a gate that cannot find its subject must never
# report PASS.
#
# WHY THE FIXTURES ARE REAL. F-5 round 5 shipped a parse validated against stubs written to
# match the parse. Every walk below comes out of the real binary on a real n=9 ladder; the only
# stubs are row_begin/row_end, which are harness, not subject.
#
# LEGS
#   1 extraction integrity: helper + a1_q2c + a1_q2d all present and non-empty
#   2 baseline: the real a1_q2c row returns 0 on the real universe (C3MAX=31)
#   3 THE DEFECT: C3MAX=0 -> the engine emits 0 walks at rc 0; the row must FAIL and say so
#   4 the C3 bound: a real cd=31 walk against C3MAX=30 must FAIL and name cd
#   5 membership: a well-formed non-member walk must FAIL and name --kc-member
#   6 a1_q2d carries the same requirement (C3MAX=0 -> FAIL)
#   7 the wall-clock bound is wired and loud (TR12_Q2_ENUM_TIMEOUT)
# =============================================================================
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || { echo "Q2_WITNESS=ERROR"; exit 2; }
W=$(mktemp -d "${TMPDIR:-/tmp}/q2_witness_XXXXXX") || { echo "Q2_WITNESS=ERROR"; exit 2; }
trap 'rm -rf "$W"' EXIT
fail=0
r(){ printf '  [%s] %s\n' "$1" "$2"; [ "$1" = FAIL ] && fail=1; return 0; }

command -v gcc >/dev/null 2>&1 || { echo "  [ERROR] no gcc"; echo "Q2_WITNESS=ERROR"; exit 2; }
S=$(sha256sum solve.c | cut -d' ' -f1)
gcc -O2 -pthread -fopenmp -DSOURCE_SHA="\"$S\"" -o "$W/solve" solve.c -lm -lz 2>"$W/cc.err" \
  || { echo "  [ERROR] build failed"; tail -3 "$W/cc.err"; echo "Q2_WITNESS=ERROR"; exit 2; }
"$W/solve" --kc-build   "$W/f" --f1-pairs 9 >/dev/null 2>&1 || { echo "  [ERROR] f ladder"; echo "Q2_WITNESS=ERROR"; exit 2; }
"$W/solve" --kc-g-build "$W/g" --f1-pairs 9 >/dev/null 2>&1 || { echo "  [ERROR] g ladder"; echo "Q2_WITNESS=ERROR"; exit 2; }

BATTERY=${BATTERY:-./scripts/tr12_repro.sh}
[ -r "$BATTERY" ] || { echo "  [ERROR] battery not readable: $BATTERY"; echo "Q2_WITNESS=ERROR"; exit 2; }

# ---- LEG 1: extraction integrity ----------------------------------------
awk '/^# --- BEGIN kc_first_last_witness/{f=1} f{print} /^# --- END kc_first_last_witness/{if(f)exit}' \
    "$BATTERY" > "$W/helper.sh"
awk '/^row_begin a1_q2c[[:space:]]*$/{f=1} f{print} /^row_end TR12_Q2C/{if(f)exit}' \
    "$BATTERY" > "$W/q2c.sh"
awk '/^[[:space:]]*row_begin a1_q2d[[:space:]]*$/{f=1} f{print} /^[[:space:]]*row_end TR12_Q2D/{if(f)exit}' \
    "$BATTERY" > "$W/q2d.sh"
missing=""
[ -s "$W/helper.sh" ] && grep -q 'kc_first_last_witness()' "$W/helper.sh" || missing="$missing helper"
[ -s "$W/q2c.sh" ]    && grep -q 'row_end TR12_Q2C'        "$W/q2c.sh"    || missing="$missing a1_q2c"
[ -s "$W/q2d.sh" ]    && grep -q 'row_end TR12_Q2D'        "$W/q2d.sh"    || missing="$missing a1_q2d"
if [ -n "$missing" ]; then
  echo "  [ERROR] could not extract from $BATTERY:$missing (markers moved, or the subject was removed)"
  echo "          -- the subject of this gate is absent, which is not the same as passing"
  echo "Q2_WITNESS=ERROR"; exit 2
fi
r ok "leg 1: extracted the helper and both rows from $BATTERY ($(grep -c . "$W/helper.sh")+$(grep -c . "$W/q2c.sh")+$(grep -c . "$W/q2d.sh") lines)"

# Run an EXTRACTED row against the real binary. row_begin/row_end are stubbed; the helper and
# the row body are the battery's own text.
run_row(){ # $1 = q2c|q2d, $2 = C3MAX, $3 = timeout ; echoes row output, returns the row's rc
  local which=$1 c3=$2 tmo=$3 d="$W/run.$$"; rm -rf "$d"; mkdir -p "$d/work"
  ( set +u
    row_begin(){ :; }; row_end(){ ROWRC=$2; }
    SOLVE="$W/solve"; FDIR="$W/f"; GDIR="$W/g"; WORK="$d/work"
    N_PAIRS=9; C3MAX="$c3"; Q2_ENUM_TIMEOUT="$tmo"; RAW="$d/raw"; : > "$RAW"
    . "$W/helper.sh"
    . "$W/$which.sh" >/dev/null 2>&1
    cat "$RAW"
    exit "${ROWRC:-99}" )
}

# ---- LEG 2: baseline on the real universe -------------------------------
out=$(run_row q2c 31 600); rc=$?
if [ "$rc" -eq 0 ]; then
  r ok "leg 2: the extracted a1_q2c row returns 0 on the real n=9 universe (C3MAX=31)"
else
  r FAIL "leg 2: the extracted a1_q2c row returned $rc on a CORRECT universe -- it can only ever fail"
  printf '%s\n' "$out" | sed 's/^/        /' | head -4
fi

# ---- LEG 3: THE DEFECT -- an empty enumeration must not pass ------------
"$W/solve" --kc-enum "$W/f" --kc-c3-max 0 --kc-limit 1 >"$W/empty.out" 2>&1; erc=$?
if grep -q 'enumerated 0 walk(s)' "$W/empty.out" && [ "$erc" -eq 0 ]; then
  r ok "leg 3a: the engine really does emit 0 walks at rc 0 (C3MAX=0) -- the defect is reproduced, not assumed"
else
  r FAIL "leg 3a: could not reproduce the zero-walk-at-rc-0 condition (rc=$erc); the rest of this leg is not meaningful"
fi
out=$(run_row q2c 0 600); rc=$?
if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'Q2C_FAIL	no walk of 2n=18'; then
  r ok "leg 3b: the row FAILS on an empty enumeration and names the field count"
else
  r FAIL "leg 3b: an enumeration that found NOTHING gave rc=$rc without naming it -- an empty FIRST^C15 would publish as PASS"
  printf '%s\n' "$out" | sed 's/^/        /' | head -4
fi

# ---- LEG 4: the C3 bound, against a real cd=31 walk ---------------------
"$W/solve" --kc-enum "$W/f" --kc-c3-max 31 --kc-limit 1 >"$W/good.out" 2>&1
GW=$(grep -E '^[0-9]+(,[0-9]+)+$' "$W/good.out" | head -1)
CD=$("$W/solve" --kc-profile "$W/f" "$W/g" "$GW" 2>/dev/null | sed -n 's/.*[[:space:]]cd=\([0-9][0-9]*\).*/\1/p' | head -1)
if [ -n "$GW" ] && [ "${CD:-0}" -ge 1 ]; then
  out=$( set +u
         SOLVE="$W/solve"; FDIR="$W/f"; GDIR="$W/g"; N_PAIRS=9; C3MAX=$((CD - 1))
         . "$W/helper.sh"; kc_first_last_witness Q2C "$W/good.out" )
  wrc=$?
  if [ "$wrc" -ne 0 ] && printf '%s\n' "$out" | grep -q "cd=$CD exceeds"; then
    r ok "leg 4: a real cd=$CD walk fails against C3MAX=$((CD - 1)) and cd is named"
  else
    r FAIL "leg 4: a walk violating the row's own C3 bound returned $wrc -- a mis-plumbed threshold would ship"
    printf '%s\n' "$out" | sed 's/^/        /' | head -3
  fi
else
  r FAIL "leg 4: could not obtain a real walk and its cd (walk='${GW:-<none>}' cd='${CD:-<none>}')"
fi

# ---- LEG 5: membership, against a real non-member -----------------------
# Built by swapping the first two hexagrams of a real member walk. If the structure still calls
# it a member the leg says so rather than asserting it does not.
NM=$(printf '%s' "$GW" | awk -F',' '{t=$1; $1=$2; $2=t; s=$1; for(i=2;i<=NF;i++) s=s","$i; print s}')
if [ -n "$NM" ] && ! "$W/solve" --kc-member "$W/f" "$NM" 2>/dev/null | grep -qx 'MEMBER'; then
  printf '%s\n' "$NM" > "$W/nonmember.out"
  out=$( set +u
         SOLVE="$W/solve"; FDIR="$W/f"; GDIR="$W/g"; N_PAIRS=9; C3MAX=31
         . "$W/helper.sh"; kc_first_last_witness Q2C "$W/nonmember.out" )
  wrc=$?
  if [ "$wrc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'kc-member'; then
    r ok "leg 5: a well-formed non-member walk fails and --kc-member is named"
  else
    r FAIL "leg 5: a non-member walk returned $wrc -- the membership check is not load-bearing"
    printf '%s\n' "$out" | sed 's/^/        /' | head -3
  fi
else
  r FAIL "leg 5: could not construct a non-member walk by transposition (the structure still calls it a member) -- membership is untested here"
fi

# ---- LEG 6: a1_q2d carries the same requirement -------------------------
out=$(run_row q2d 0 600); rc=$?
if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'Q2D_FAIL	no walk of 2n=18'; then
  r ok "leg 6: a1_q2d also fails on an empty enumeration -- LAST^C15 carries the same witness requirement"
else
  r FAIL "leg 6: a1_q2d returned $rc on an empty enumeration -- the fix reached Q2c and not Q2d"
  printf '%s\n' "$out" | sed 's/^/        /' | head -4
fi

# ---- LEG 7: the wall-clock bound is wired and loud ----------------------
# QUERY_INVENTORY promised "abort-and-report if >10^6 backtracks" and no such mechanism was ever
# built. The wall-clock bound replaces it; this leg proves it fires and is not silent.
out=$(run_row q2c 31 0.001); rc=$?
if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'Q2C_FAIL	--kc-enum did not finish within'; then
  r ok "leg 7: the wall-clock bound fires and names TR12_Q2_ENUM_TIMEOUT"
else
  r FAIL "leg 7: a 1 ms budget gave rc=$rc with no timeout token -- an unbounded enumeration would stall silently"
  printf '%s\n' "$out" | sed 's/^/        /' | head -3
fi

# ---- LEG 8: a SECOND helper definition would silently win -----------------
# 🔴 KCP2. This gate extracts the helper between its markers. A second definition of
# kc_first_last_witness placed AFTER the END marker but BEFORE the rows is the one the shipped
# shell actually uses -- bash takes the last definition -- while the gate goes on measuring the
# first. Measured by the reviewer: original -> rc 1 on an empty enumeration, override -> rc 0,
# and this gate still said PASS. The battery is correct today (one definition), so this is the
# gate catching up to its own subject, not a live defect.
ndef=$(grep -cE '^[[:space:]]*kc_first_last_witness[[:space:]]*\(\)' "$BATTERY")
if [ "${ndef:-0}" -eq 1 ]; then
  r ok "leg 8: exactly one kc_first_last_witness definition in the battery"
else
  echo "  [ERROR] the battery defines kc_first_last_witness ${ndef} time(s); bash uses the LAST one"
  echo "          and this gate extracts the MARKED one -- they need not be the same function"
  echo "Q2_WITNESS=ERROR"; exit 2
fi

# ---- LEG 9: a1_q2d must PUBLISH, not merely refuse ------------------------
# Every other Q2d leg here runs at C3MAX=0, where the correct answer is "no walk". So hard-wiring
# the row's own threshold to 0 would leave this gate's argv unchanged and it would never notice.
# This leg exercises SUCCESSFUL LAST publication at the real universe threshold.
out=$(run_row q2d 31 600); rc=$?
if [ "$rc" -eq 0 ]; then
  r ok "leg 9: a1_q2d PUBLISHES a LAST^C15 at the real threshold, not only refuses at zero"
else
  r FAIL "leg 9: a1_q2d returned $rc at C3MAX=31 -- it can refuse but never publish, and no other leg here would see that"
  printf '%s\n' "$out" | sed 's/^/        /' | head -4
fi

# ---- LEG 10: the battery's own timeout default must be a real bound -------
# `timeout 0` means NO timeout. The gate supplies its own value to run_row, so a battery-side
# default of 0 is invisible to every leg above.
tmo=$(sed -n 's/^Q2_ENUM_TIMEOUT="\${TR12_Q2_ENUM_TIMEOUT:-\([0-9][0-9]*\)}"/\1/p' "$BATTERY" | head -1)
if [ -n "$tmo" ] && [ "$tmo" -gt 0 ] 2>/dev/null; then
  r ok "leg 10: the battery's wall-clock default is ${tmo}s, a real bound"
else
  r FAIL "leg 10: the battery's TR12_Q2_ENUM_TIMEOUT default is '${tmo:-<unparseable>}' -- 0 or absent means NO timeout, and no other leg here reads the battery's own value"
fi

printf 'Q2_WITNESS_LEGS=11\n'
[ "$fail" -eq 0 ] && echo "Q2_WITNESS=PASS" || echo "Q2_WITNESS=FAIL"
exit "$fail"
