#!/usr/bin/env bash
# =============================================================================
# q7ranks_parse_gate.sh — condition 1b of F-5 round 5.
# Emits exactly one whole-line token: Q7RANKS_PARSE=PASS | FAIL | ERROR
#
# 2026-09-11. Claude (Opus 5). Developed with AI assistance (Claude, Anthropic).
#
# WHY THIS EXISTS, and why row_assertion_gate.sh cannot own it.
# F-5 round 5 B1(r5): `a2_q7_ranks` asserted `rank3 == 0` by reading the engine's
# output with `sed -n 's/.*\brank3=\([0-9]*\).*/\1/p'`. THE ENGINE PRINTS A TAB:
# solve.c's --kc-o3-rank driver does printf("rank3\t%s\n", tdec). Verified by
# execution -- `cat -A` shows `rank3^I0$`. The only `rank3=` anywhere in solve.c
# is `class_first_rank3=`, which the `\b` deliberately did not match because `_`
# is a word character. So the pattern avoided the false positive and NEVER
# MATCHED THE TRUE ONE: the row could only ever FAIL.
#
# It is n >= 31-ONLY (tr12_repro.sh guards it on N_PAIRS), so no golden, no
# rehearsal and no gate had ever run it against the engine -- and the battery
# ships FROZEN by `git archive` at launch, so a fix landed mid-run cannot reach
# the run's VERDICTS.txt. The flagship run would have published
# TR12_Q7_RANKS=FAIL for a correct rank_O3(KW)=0, in the row carrying the
# labeling theorem TR-12 leans on.
#
# HOW IT SURVIVED ITS OWN RED TEST, which is the part worth institutionalising:
# the test drove four STUBS printing `rank3=0` and `rank3=5`. The regex was
# validated against fixtures written to match the regex. That is verifier
# closure -- the check was handed its witness by the thing it was meant to
# check. Both the round-4 prescription and its implementation wrote that stub
# format without running --kc-o3-rank once.
#
# 🔴 THE CLASS: an n >= 31-only row that parses ENGINE OUTPUT through a pattern
# nothing at n <= 13 ever exercises. `row_assertion_gate.sh` proves a row
# ASSERTS; it cannot prove the assertion's PARSE MATCHES ITS PRODUCER. This gate
# closes that gap, and it does it the only honest way: by running the real
# engine and reading what it actually prints.
#
# LEGS -- rewritten 2026-09-11 with the gate itself. The previous list described the
# leg design this file had BEFORE F-5 round 6, and survived the rewrite that replaced
# them: it advertised two "MUTANT: a producer printing ..." legs that no longer exist.
# A header that describes legs the script does not run is the same defect class as a
# gate that checks a copy of its subject, one layer out, so it is corrected here with
# the code rather than left for the next reviewer.
#   1 the real binary prints `rank3<TAB><digits>` -- the producer's format, measured
#   2 THE EXTRACTED ROW returns 0 on the O3-least walk with a matching anchor (baseline)
#   3 THE EXTRACTED ROW fails on a walk of rank 16244, and NAMES the value
#   4 THE EXTRACTED ROW fails when the walk is not $ANCHOR
#   5 the producer's format is restated, so a change to it is visible here
# ERROR (rc 2) when it cannot measure: no compiler, no build, no ladders. A gate
# that cannot see its subject must never report PASS.
# =============================================================================
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || { echo "Q7RANKS_PARSE=ERROR"; exit 2; }
W=$(mktemp -d "${TMPDIR:-/tmp}/q7ranks_gate_XXXXXX") || { echo "Q7RANKS_PARSE=ERROR"; exit 2; }
trap 'rm -rf "$W"' EXIT
fail=0
r(){ printf '  [%s] %s\n' "$1" "$2"; [ "$1" = FAIL ] && fail=1; return 0; }

command -v gcc >/dev/null 2>&1 || { echo "  [ERROR] no gcc"; echo "Q7RANKS_PARSE=ERROR"; exit 2; }
S=$(sha256sum solve.c | cut -d' ' -f1)
gcc -O2 -pthread -fopenmp -DSOURCE_SHA="\"$S\"" -o "$W/solve" solve.c -lm -lz 2>"$W/cc.err" \
  || { echo "  [ERROR] build failed"; tail -3 "$W/cc.err"; echo "Q7RANKS_PARSE=ERROR"; exit 2; }
"$W/solve" --kc-build "$W/f" --f1-pairs 9 >/dev/null 2>&1 || { echo "  [ERROR] f ladder"; echo "Q7RANKS_PARSE=ERROR"; exit 2; }
"$W/solve" --kc-g-build "$W/g" --f1-pairs 9 >/dev/null 2>&1 || { echo "  [ERROR] g ladder"; echo "Q7RANKS_PARSE=ERROR"; exit 2; }
W0=$("$W/solve" --kc-o3-unrank "$W/f" "$W/g" 0 2>/dev/null | grep -E '^[0-9]+(,[0-9]+)+$' | head -1)
[ -n "$W0" ] || { echo "  [ERROR] could not unrank 0"; echo "Q7RANKS_PARSE=ERROR"; exit 2; }

# ---- LEG 1: what does the producer ACTUALLY print? ------------------------
"$W/solve" --kc-o3-rank "$W/f" "$W/g" "$W0" >"$W/real.out" 2>&1
if grep -qP '^rank3\t[0-9]+$' "$W/real.out" 2>/dev/null || awk -F'\t' '$1=="rank3" && $2 ~ /^[0-9]+$/{ok=1} END{exit ok?0:1}' "$W/real.out"; then
  r ok "leg 1: engine prints a TAB-separated rank3 field ($(awk -F'\t' '$1=="rank3"{print "rank3<TAB>"$2; exit}' "$W/real.out"))"
else
  r FAIL "leg 1: engine output is not a tab-separated rank3 field -- the parse below is keyed to a format that no longer holds"
  head -2 "$W/real.out"
fi

# 🔴 F-5 ROUND 6. THE FIRST VERSION OF THIS GATE DEFINED ITS OWN parse() HERE -- a hand-copied
# second instance of the row's awk -- and never read scripts/tr12_repro.sh at all. Fable measured
# the consequence: restore the exact 92516f8d defect at tr12_repro.sh:1970 and this gate still
# reported PASS while the row itself failed; DELETE tr12_repro.sh entirely and it STILL reported
# PASS. It bound to the producer and to a COPY of the consumer, so the red test that shipped
# mutated THE GATE, not THE ROW. That is the same verifier closure B1(r5) was, committed inside
# the instrument built to catch it.
#
# The row is now EXTRACTED FROM THE BATTERY AND EXECUTED. There is exactly one copy of the parse
# in the tree and this gate runs it. Extraction is by the row's own markers, and an empty or
# absent extraction is ERROR -- a gate that cannot find its subject must never report PASS.
BATTERY=${BATTERY:-./scripts/tr12_repro.sh}
[ -r "$BATTERY" ] || { echo "  [ERROR] battery not readable: $BATTERY"; echo "Q7RANKS_PARSE=ERROR"; exit 2; }
awk '/^[[:space:]]*row_begin a2_q7_ranks[[:space:]]*$/{f=1} f{print} /^[[:space:]]*row_end TR12_Q7_RANKS/{if(f)exit}' \
    "$BATTERY" > "$W/block.sh"
if [ ! -s "$W/block.sh" ] || ! grep -q 'row_begin a2_q7_ranks' "$W/block.sh" \
   || ! grep -q 'row_end TR12_Q7_RANKS' "$W/block.sh"; then
  echo "  [ERROR] could not extract the a2_q7_ranks block from $BATTERY (markers moved or row removed)"
  echo "          -- the subject of this gate is absent, which is not the same as passing"
  echo "Q7RANKS_PARSE=ERROR"; exit 2
fi
echo "  [ok] extracted $(grep -c . "$W/block.sh") lines of a2_q7_ranks from $BATTERY"

# Run the EXTRACTED row against the real binary. row_begin/row_end are stubbed; everything else
# -- the parse, both assertions, the IN branch, the n>=31 guard -- is the battery's own text.
run_row(){ # $1 = arrangement walk, $2 = ANCHOR ; echoes row output, returns the row's rc
  local arr=$1 anchor=$2 d="$W/run.$$"; rm -rf "$d"; mkdir -p "$d/art" "$d/work"
  printf '{"label": "KW", "verdict_super": "IN", "arrangement": "63,0,%s"}' "$arr" > "$d/art/q7_kw.json"
  ( set +u
    row_begin(){ :; }; row_end(){ ROWRC=$2; }
    SOLVE="$W/solve"; FDIR="$W/f"; GDIR="$W/g"; ARTDIR="$d/art"; WORK="$d/work"
    ANCHOR="$anchor"; N_PAIRS=31; RAW="$d/raw"; : > "$RAW"
    . "$W/block.sh" >/dev/null 2>&1
    cat "$RAW"
    exit "${ROWRC:-99}" )
}

# ---- LEG 2: the REAL ROW on a rank-0 walk must PASS ----------------------
W0=$("$W/solve" --kc-o3-unrank "$W/f" "$W/g" 0 2>/dev/null | grep -E '^[0-9]+(,[0-9]+)+$' | head -1)
out=$(run_row "$W0" "$W0"); rc=$?
[ "$rc" -eq 0 ] && r ok "leg 2: the extracted row returns 0 on the O3-least walk with a matching anchor" \
                 || { r FAIL "leg 2: the extracted row returned $rc on a CORRECT input -- it cannot pass"; printf '%s\n' "$out" | sed 's/^/        /' | head -3; }

# ---- LEG 3: a NON-ZERO rank must FAIL, and be NAMED ----------------------
W16=$("$W/solve" --kc-o3-unrank "$W/f" "$W/g" 16244 2>/dev/null | grep -E '^[0-9]+(,[0-9]+)+$' | head -1)
if [ -n "$W16" ]; then
  out=$(run_row "$W16" "$W16"); rc=$?
  if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'rank3=16244'; then
    r ok "leg 3: a walk of rank 16244 fails the row and the value is named"
  else
    r FAIL "leg 3: rank-16244 walk gave rc=$rc without naming the rank -- a wrong rank would ship"
  fi
else
  r FAIL "leg 3: could not unrank 16244 (cannot measure the wrong-rank case)"
fi

# ---- LEG 4: an ANCHOR MISMATCH must FAIL --------------------------------
out=$(run_row "$W0" "1,2,3"); rc=$?
[ "$rc" -ne 0 ] && r ok "leg 4: a walk that is not \$ANCHOR fails the row" \
                 || r FAIL "leg 4: anchor mismatch returned 0 -- two derivations of KW could disagree silently"

# ---- LEG 5: the producer's format, stated so a change is visible ---------
"$W/solve" --kc-o3-rank "$W/f" "$W/g" "$W0" >"$W/real.out" 2>&1
if awk -F'\t' '$1=="rank3" && $2 ~ /^[0-9]+$/{ok=1} END{exit ok?0:1}' "$W/real.out"; then
  r ok "leg 5: the engine prints a TAB-separated rank3 field, which is what the row parses"
else
  r FAIL "leg 5: the engine no longer prints a tab-separated rank3 field -- the row's parse is keyed to a format that no longer holds"
fi

printf 'Q7RANKS_PARSE_LEGS=5\n'
[ "$fail" -eq 0 ] && echo "Q7RANKS_PARSE=PASS" || echo "Q7RANKS_PARSE=FAIL"
exit "$fail"
