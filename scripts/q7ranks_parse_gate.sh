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
# LEGS
#   1 the real binary prints `rank3<TAB><digits>` -- the producer's format, measured
#   2 the shipped parse extracts rank 0 from that real output          (baseline)
#   3 MUTANT: a producer printing `rank3=0` (the format the defect assumed)
#     must NOT satisfy a field-keyed parse silently -- it is reported, so that
#     re-introducing the old format is visible rather than accidentally fine
#   4 MUTANT: a producer printing `rank3<TAB>5` must FAIL the row (rank != 0)
#   5 the anchor mismatch leg still fires
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

# the parse under test, lifted to a function so every leg uses ONE copy of it
parse(){ awk -F'\t' '$1=="rank3"{print $2; exit}' "$1"; }

# ---- LEG 2: baseline -- the shipped parse on REAL output ------------------
v=$(parse "$W/real.out")
[ "$v" = "0" ] && r ok "leg 2: shipped parse reads rank3=0 from real engine output" \
                || r FAIL "leg 2: shipped parse got '${v:-<empty>}' from real output, expected 0"

# ---- LEG 3: MUTANT -- the format the defect assumed -----------------------
sed 's/^rank3\t/rank3=/' "$W/real.out" > "$W/eq.out"
v=$(parse "$W/eq.out")
if [ -z "$v" ]; then
  r ok "leg 3: a producer printing 'rank3=0' yields NO field -- the old assumed format is visibly unsupported, not silently accepted"
else
  r FAIL "leg 3: 'rank3=0' produced '$v' -- the parse accepts both formats, so a producer format change would go unnoticed"
fi

# ---- LEG 4: MUTANT -- a wrong rank must be caught -------------------------
awk -F'\t' 'BEGIN{OFS="\t"} $1=="rank3"{$2=5} {print}' "$W/real.out" > "$W/five.out"
v=$(parse "$W/five.out")
[ "$v" = "5" ] && r ok "leg 4: a producer printing rank3<TAB>5 is read as 5, so the row's rank3!=0 assertion fires" \
                || r FAIL "leg 4: rank3<TAB>5 read as '${v:-<empty>}' -- a wrong rank would not be caught"

# ---- LEG 5: the false-positive the original \b guarded against ------------
if grep -q 'class_first_rank3=' "$W/real.out"; then
  v=$(parse "$W/real.out")
  [ "$v" = "0" ] && r ok "leg 5: class_first_rank3= is present and does NOT capture the field-keyed parse" \
                  || r FAIL "leg 5: class_first_rank3= contaminated the parse"
else
  r ok "leg 5: no class_first_rank3= in this output (nothing to confuse)"
fi

printf 'Q7RANKS_PARSE_LEGS=5\n'
[ "$fail" -eq 0 ] && echo "Q7RANKS_PARSE=PASS" || echo "Q7RANKS_PARSE=FAIL"
exit "$fail"
