#!/usr/bin/env bash
# d5_04_q7_witnesses_gate.sh — the Q7 SAT-witness row must verify the PINNED witnesses without a
# solver, fail on a witness that is not what it claims to be, and keep TR12_Q7 honest.
#
# HISTORY. D5-04 (2026-09-05): TR-12 section Q7 promised "the SAT witnesses are IN C15 ... they get
# ranks (post-O3) -- the only non-KW named sequences in this report with serial numbers", and the
# battery never invoked sat.py, so TR12_Q7 could read PASS with the witness leg uncommanded. The
# first version of this gate pinned the REMEDY OF THAT DAY: a named skip (PENDING:kissat /
# PENDING:q7-witness-row) aggregated into TR12_Q7, in both PATH worlds. Its four mutants killed the
# ways the skip could quietly turn into a PASS.
#
# CX-93 (2026-09-25, Fable): the witness bytes are pinned under reports/evidence/q7_witnesses/ and
# row a0_q7_witnesses is REAL -- it verifies the pinned sequences with no solver on PATH -- so the
# old contract (the row must skip) is now wrong, and this gate pins the new one:
#   leg 1   source text: `agg TR12_Q7 ...` still names TR12_Q7_WITNESSES; the row ends in
#           `row_end TR12_Q7_WITNESSES`; no row_skip records TR12_Q7_WITNESSES as PENDING:kissat
#           or PASS (the Q-714 dependence of the skip pin on `command -v kissat` is gone)
#   leg 2   GREEN: the extracted row, on the committed witnesses, with NO kissat on PATH -> rc 0,
#           Q7WIT_OK for both targets, a witness_sha256 line equal to sha256sum of each file, and
#           (Q-795) each q7_<target>.json it wrote carries "label": "<target>" from --label
#   leg 3   the same run with a stub kissat FIRST on PATH -> byte-identical row output (Q-714)
#   leg 4   RED, planted bad witness: two hexagrams from different pairs swapped (C1 broken) -> FAIL,
#           named ("does not say IN SUPER")
#   leg 5   RED, a genuine IN-C15 non-KW sequence that breaks ONE literature rule the target
#           enforces (built deterministically from the pinned witnesses themselves) -> FAIL, named
#           ("violates a rule the target enforces")
#   leg 6   RED, King Wen submitted as the witness -> FAIL, named ("IS King Wen" / "byte-identical
#           to the KW arrangement"). KNOWN LIMITATION, stated: KW also violates both Moore rules, so
#           the rule check catches it too; the identity check is exercised, not isolated -- no
#           rule-satisfying sequence can be KW for these targets
#   leg 7   RED, missing witness file -> FAIL, named ("MISSING")
#   leg 8   RED, malformed file (no SEQ= line) -> FAIL, named ("exactly one SEQ= line")
#   leg 9   RED, --q7-resolve with a stub kissat (exit 42, no verdict) -> TR12_Q7_RESOLVE row FAILS,
#           named ("did not end in WITNESS_RESULT=WITNESS")
#   leg 10  RED, --q7-resolve with NO kissat on PATH -> FAILS loudly ("kissat is not on PATH"),
#           never skips
#   leg 11  (only with Q7WIT_LIVE=1 and a real kissat on PATH) the live re-solve row on the real
#           solver -> rc 0, Q7RESOLVE_OK for both targets. Opt-in because it costs a SAT solve; it
#           is never a condition of the verdict, and its absence is printed, not hidden
# plus row mutants, each of which must be caught by the legs above:
#   M1  the missing-file branch no longer fails the row      (leg 7 would go green)
#   M2  the property check's failure no longer fails the row  (legs 4/5/6 would go green)
#   M3  the pre-fix aggregation line (witnesses not a leg)     (leg 1 would go green)
#
# The row and its two helpers are EXTRACTED VERBATIM from scripts/tr12_repro.sh and executed against
# a real solve binary (Q7WIT_SOLVE=<path> if given, else built here) in a stub harness. Extraction
# anchors on `q7wit_props(){`, `q7wit_check(){`, `row_begin a0_q7_witnesses`, `row_end
# TR12_Q7_WITNESSES`, `row_begin a0_q7_resolve`, `row_end TR12_Q7_RESOLVE` and `agg TR12_Q7 `; a
# refactor makes this gate report ERROR ("anchors moved"), never pass blind.
#
# Verdict: exactly one D5_04_Q7_WITNESSES_GATE=<PASS|FAIL|ERROR> line; exit 0 / 40 / 2. ERROR means
# the subject could not be measured (no python3, no binary, anchors moved) -- not the same as PASS.
# D5_04_SRC overrides the source file -- ONLY so the closure check can point the gate at a file that
# lacks its target and confirm it reports FAIL/ERROR.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "D5_04_Q7_WITNESSES_GATE=ERROR"; exit 2; }
SRC="${D5_04_SRC:-scripts/tr12_repro.sh}"
ROOT=$(pwd)
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [gate] $*"; echo "D5_04_Q7_WITNESSES_GATE=FAIL"; exit 40; }
err(){  echo "  [gate] ERROR: $*"; echo "D5_04_Q7_WITNESSES_GATE=ERROR"; exit 2; }
[ -f "$SRC" ] || fail "missing $SRC"
command -v python3 >/dev/null 2>&1 || err "no python3"
PYTHONPATH="$ROOT" python3 -c 'import solve, sat, verify' >/dev/null 2>&1 || err "solve/sat/verify do not import"
EVID="$ROOT/reports/evidence/q7_witnesses"
for t in moore-strict grand-strict; do [ -f "$EVID/$t.txt" ] || fail "pinned witness $EVID/$t.txt is missing"; done

# ---- the binary: given, or built here (the q7ranks_parse_gate.sh idiom) ------------------------
if [ -n "${Q7WIT_SOLVE:-}" ] && [ -x "$Q7WIT_SOLVE" ]; then
  SOLVE="$Q7WIT_SOLVE"; echo "  [gate] using Q7WIT_SOLVE=$SOLVE"
else
  command -v gcc >/dev/null 2>&1 || err "no gcc and no Q7WIT_SOLVE"
  S=$(sha256sum solve.c | cut -d' ' -f1)
  gcc -O2 -pthread -fopenmp -DSOURCE_SHA="\"$S\"" -o "$WORK/solve" solve.c -lm -lz 2>"$WORK/cc.err" \
    || { tail -3 "$WORK/cc.err"; err "build failed"; }
  SOLVE="$WORK/solve"; echo "  [gate] built $SOLVE"
fi
"$SOLVE" --check-arrangement KW --cert-out "$WORK/q7_kw.json" >/dev/null 2>&1 || err "the binary cannot certify KW"

# ---- leg 1: source text -------------------------------------------------------------------------
grep -E '^agg TR12_Q7 ' "$SRC" | grep -q 'TR12_Q7_WITNESSES' || fail "leg 1: the agg TR12_Q7 line does not name TR12_Q7_WITNESSES"
[ "$(grep -cE '^agg TR12_Q7 ' "$SRC")" -eq 1 ] || fail "leg 1: expected exactly one agg TR12_Q7 line"
grep -qE '^\s*row_end TR12_Q7_WITNESSES ' "$SRC" || fail "leg 1: no row_end TR12_Q7_WITNESSES -- the witness row is not a real row"
if grep -vE '^\s*#' "$SRC" | grep -E 'TR12_Q7_WITNESSES' | grep -qE '"PENDING:kissat"|"PENDING:q7-witness-row"|"PASS"'; then
  fail "leg 1: a non-comment line still records TR12_Q7_WITNESSES as PENDING:kissat / PENDING:q7-witness-row / PASS"
fi
if grep -vE '^\s*#' "$SRC" | grep -qE 'command -v kissat.*then\s*$' ; then
  # a `command -v kissat` BRANCH is allowed only inside the opt-in resolve row (a failure, never a skip)
  if grep -vE '^\s*#' "$SRC" | grep -E 'row_skip .*(kissat|q7-witness)' | grep -q .; then
    fail "leg 1: a row_skip keyed on kissat's presence is back (Q-714)"
  fi
fi
echo "  [gate] leg 1: source text pins hold"

# ---- extraction ---------------------------------------------------------------------------------
extract(){ python3 - "$SRC" "$WORK" <<'PY'
import sys
s = open(sys.argv[1], encoding='utf-8').read(); w = sys.argv[2]
def block(start, end_marker):
    a = s.index(start); b = s.index(end_marker, a) + len(end_marker); return s[a:b]
def rowblock(begin, endtok):
    a = s.index(begin); b = s.index('\n', s.index(endtok, a)) + 1; return s[a:b]
helpers = block('q7wit_props(){', '\n}\n') + block('q7wit_check(){', '\n}\n')
wit = rowblock('    row_begin a0_q7_witnesses', 'row_end TR12_Q7_WITNESSES')
res = rowblock('    row_begin a0_q7_resolve', 'row_end TR12_Q7_RESOLVE')
open(w + '/helpers.sh', 'w').write(helpers)
open(w + '/wit.sh', 'w').write(wit)
open(w + '/res.sh', 'w').write(res)
PY
}
extract || err "could not extract q7wit_props/q7wit_check/a0_q7_witnesses/a0_q7_resolve from $SRC (anchors moved?)"
for f in helpers.sh wit.sh res.sh; do [ -s "$WORK/$f" ] || err "empty extraction: $f"; done
grep -q 'Q7WIT_OK' "$WORK/wit.sh" || err "the extracted witness row does not print Q7WIT_OK"
grep -q 'Q7RESOLVE_OK' "$WORK/res.sh" || err "the extracted resolve row does not print Q7RESOLVE_OK"
echo "  [gate] extracted $(grep -c . "$WORK/helpers.sh")+$(grep -c . "$WORK/wit.sh")+$(grep -c . "$WORK/res.sh") lines from $SRC"

# run_row <wit.sh|res.sh> <helpers.sh> <witness-dir> <q7-resolve 0|1> <PATH> ; prints RAW, returns the row's rc
run_row(){
  local row="$1" helpers="$2" wdir="$3" q7r="$4" path="$5" d="$WORK/run.$RANDOM$RANDOM"
  rm -rf "$d"; mkdir -p "$d/art" "$d/work"; cp "$WORK/q7_kw.json" "$d/art/q7_kw.json"
  {
    echo 'set -u'
    echo "SOLVE=$(printf '%q' "$SOLVE"); WORK=$(printf '%q' "$d/work"); ARTDIR=$(printf '%q' "$d/art"); REPO_ROOT=$(printf '%q' "$ROOT"); RAW=$(printf '%q' "$d/raw"); Q7_RESOLVE=$q7r"
    echo 'ROWRC=99; row_begin(){ :; }; row_end(){ ROWRC=$2; }; row_skip(){ ROWRC=0; echo "SKIPPED $2 $3" >>"$RAW"; }'
    cat "$helpers"
    printf '%s=%q\n' Q7WIT_DIR "$wdir"     # a harness assignment, not a verdict token (GATE 89 LEG 2 reads echo "KEY=..." lines)
    cat "$row"
    echo 'exit $ROWRC'
  } > "$d/h.sh"
  : > "$d/raw"
  PATH="$path" bash "$d/h.sh" >"$d/stdout" 2>&1; local rc=$?
  # the battery's norm() rewrites $ARTDIR to <ART>; this harness has one run dir per call, so the
  # `certificate written:` path is the one host-specific token in the raw and is rewritten the same way
  sed "s#$d/art#<ART>#g" "$d/raw"; return $rc
}
NOKISSAT="$WORK/nokissat"; mkdir -p "$NOKISSAT"
STUB="$WORK/stubkissat"; mkdir -p "$STUB"; printf '#!/bin/sh\necho "c stub"\nexit 42\n' > "$STUB/kissat"; chmod +x "$STUB/kissat"
# the no-solver world: python3's own directory plus the system bins, and it must NOT resolve kissat
BASEPATH="$(dirname "$(command -v python3)"):/usr/bin:/bin"
if PATH="$NOKISSAT:$BASEPATH" command -v kissat >/dev/null 2>&1; then
  err "cannot construct a PATH without kissat (it sits beside python3 or in /usr/bin); legs 2/3/10 need one"
fi

# ---- leg 2: GREEN on the committed witnesses, no solver on PATH ---------------------------------
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$EVID" 0 "$NOKISSAT:$BASEPATH"); rc=$?
printf '%s\n' "$out" > "$WORK/green.raw"
[ "$rc" -eq 0 ] || { printf '%s\n' "$out" | grep -E 'Q7WIT_FAIL|checker_rc' | sed 's/^/        /'; fail "leg 2: the row FAILS (rc=$rc) on the committed witnesses with no solver on PATH"; }
for t in moore-strict grand-strict; do
  printf '%s\n' "$out" | grep -qx "Q7WIT_OK	$t" || fail "leg 2: no Q7WIT_OK for $t"
  want=$(sha256sum < "$EVID/$t.txt" | cut -d' ' -f1)
  printf '%s\n' "$out" | grep -qx "witness_sha256	$want" || fail "leg 2: the row did not print the sha256 of $t.txt ($want)"
done
printf '%s\n' "$out" | grep -q 'Q7WIT_FAIL' && fail "leg 2: a Q7WIT_FAIL line on a green run"
# Q-795: the row passes --label <target>, so each certificate it writes is named by its target, and
# a2_q7_ranks keys on that label. Exactly one run dir exists at this point (leg 2's).
for t in moore-strict grand-strict; do
  set -- "$WORK"/run.*/art/"q7_$t.json"
  [ "$#" -eq 1 ] && [ -f "$1" ] || fail "leg 2: expected one q7_$t.json from the green run, found $# ($*)"
  grep -qx "  \"label\": \"$t\"," "$1" 2>/dev/null || fail "leg 2: q7_$t.json does not carry \"label\": \"$t\" -- a2_q7_ranks would fall back to the filename"
done
echo "  [gate] leg 2: GREEN -- both pinned witnesses verify solver-free; sha256 lines match the files; certificates carry their target label"

# ---- leg 3: byte-identical with a stub solver first on PATH --------------------------------------
out2=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$EVID" 0 "$STUB:$BASEPATH"); rc=$?
[ "$rc" -eq 0 ] || fail "leg 3: rc=$rc with a stub kissat on PATH"
if [ "$out" != "$out2" ]; then
  diff <(printf '%s\n' "$out") <(printf '%s\n' "$out2") | head -5 | sed 's/^/        /'
  fail "leg 3: the row's output depends on what is on PATH (Q-714)"
fi
echo "  [gate] leg 3: output byte-identical with and without a solver on PATH"

# ---- fixtures for the red legs ------------------------------------------------------------------
MS=$(sed -n 's/^SEQ=//p' "$EVID/moore-strict.txt" | tr -d ' \r')
KWARR=$(sed -n 's/.*"arrangement": "\([^"]*\)".*/\1/p' "$WORK/q7_kw.json" | head -1)
[ -n "$MS" ] && [ -n "$KWARR" ] || err "cannot read the pinned moore-strict sequence or KW"
mkfix(){ # mkfix <dir> <moore-strict SEQ or -> <grand-strict SEQ or -> ; '-' = the committed file, '' = omit
  local d="$1"; rm -rf "$d"; mkdir -p "$d"
  case "$2" in -) cp "$EVID/moore-strict.txt" "$d/";; "") ;; *) printf '# gate fixture\nSEQ=%s\n' "$2" > "$d/moore-strict.txt";; esac
  case "$3" in -) cp "$EVID/grand-strict.txt" "$d/";; "") ;; *) printf '# gate fixture\nSEQ=%s\n' "$3" > "$d/grand-strict.txt";; esac
}
# leg 4 fixture: swap positions 3 and 4 (members of two different pairs) -> C1 pair adjacency breaks
BAD=$(printf '%s' "$MS" | awk -F, -v OFS=, '{t=$4; $4=$5; $5=t; print}')
# leg 5 fixture: an IN-C15 non-KW sequence that violates exactly one rule its target enforces, built
# from the pinned witnesses: (a) the moore-strict witness submitted as grand-strict, if its Schulz
# gender count is non-zero; else (b) the first within-pair orientation flip of the moore-strict
# witness that stays IN C15 (verify_seq ok, C3<=776) and breaks parity or rhythm.
read -r L5TARGET L5SEQ < <(PYTHONPATH="$ROOT" Q7MS="$MS" python3 - <<'PY'
import os, sat
ms = [int(x) for x in os.environ["Q7MS"].split(",")]
v = sat.target_verdict(ms, "grand-strict")
if v["base"] and v["c3_ok"] and v["rule_viol"] == {"gender": v["scores"]["gender"]} and v["scores"]["gender"]:
    print("grand-strict", ",".join(map(str, ms))); raise SystemExit
for i in range(1, 32):
    s = ms[:]; s[2*i], s[2*i+1] = s[2*i+1], s[2*i]
    v = sat.target_verdict(s, "moore-strict")
    if v["base"] and v["c3_ok"] and v["rule_viol"]:
        print("moore-strict", ",".join(map(str, s))); raise SystemExit
print("NONE", "-")
PY
)
[ "$L5TARGET" != "NONE" ] || err "leg 5: no IN-C15 rule-breaking fixture could be built from the pinned witnesses"

# ---- leg 4: planted bad witness (C1 broken) ------------------------------------------------------
mkfix "$WORK/fix4" "$BAD" -
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix4" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'Q7WIT_FAIL	moore-strict: --check-arrangement does not say IN SUPER' \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT' | sed 's/^/        /'; fail "leg 4: a witness with C1 broken did not fail the row by name (rc=$rc)"; }
printf '%s\n' "$out" | grep -qx 'Q7WIT_OK	grand-strict' || fail "leg 4: the untouched grand-strict witness should still pass beside the bad one"
echo "  [gate] leg 4: RED on a planted C1-broken witness, named"

# ---- leg 5: an IN-C15 non-KW sequence breaking one enforced rule ---------------------------------
if [ "$L5TARGET" = grand-strict ]; then mkfix "$WORK/fix5" - "$L5SEQ"; else mkfix "$WORK/fix5" "$L5SEQ" -; fi
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix5" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q "Q7WIT_FAIL	$L5TARGET: the pinned sequence violates a rule the target enforces" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|rule_' | sed 's/^/        /'; fail "leg 5: an IN-C15 sequence breaking a $L5TARGET rule did not fail the row by name (rc=$rc)"; }
printf '%s\n' "$out" | grep -q "verdict C15  (C1-C5, C3<=776):   IN" || fail "leg 5: the fixture was meant to be IN C15 (only a rule broken) and is not"
echo "  [gate] leg 5: RED on an IN-C15 non-KW sequence that breaks one $L5TARGET rule ($(printf '%s\n' "$out" | sed -n 's/^rule_violations\t//p' | head -1)), named"

# ---- leg 6: King Wen submitted as the witness ---------------------------------------------------
mkfix "$WORK/fix6" "$KWARR" -
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix6" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'Q7WIT_FAIL	moore-strict: the sequence is byte-identical to the KW arrangement' \
  && printf '%s\n' "$out" | grep -q 'Q7WIT_FAIL	moore-strict: the sequence IS King Wen' \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|kw_' | sed 's/^/        /'; fail "leg 6: King Wen as the witness did not fail the row by both identity checks (rc=$rc)"; }
printf '%s\n' "$out" | grep -qx 'kw_identical	YES	(positions differing from KW: 0; pair-slot layout differs from KW: NO)' || fail "leg 6: kw_identical line missing"
echo "  [gate] leg 6: RED on King Wen submitted as the witness, named by both identity checks (and by the rule check, as stated above)"

# ---- leg 7: missing witness file ---------------------------------------------------------------
mkfix "$WORK/fix7" - ""
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix7" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'Q7WIT_FAIL	grand-strict: pinned witness file is MISSING' \
  || fail "leg 7: a missing grand-strict.txt did not fail the row by name (rc=$rc)"
echo "  [gate] leg 7: RED on a missing witness file, named"

# ---- leg 8: malformed file ---------------------------------------------------------------------
mkfix "$WORK/fix8" - -; printf '# no SEQ line here\n' > "$WORK/fix8/moore-strict.txt"
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix8" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'Q7WIT_FAIL	moore-strict: expected exactly one SEQ= line, found 0' \
  || fail "leg 8: a file without a SEQ= line did not fail the row by name (rc=$rc)"
echo "  [gate] leg 8: RED on a malformed witness file, named"

# ---- leg 9: --q7-resolve with a stub solver -----------------------------------------------------
out=$(run_row "$WORK/res.sh" "$WORK/helpers.sh" "$EVID" 1 "$STUB:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'Q7RESOLVE_FAIL	moore-strict: sat.py --witness did not end in WITNESS_RESULT=WITNESS' \
  && printf '%s\n' "$out" | grep -qx 'witness_result	WITNESS_RESULT=SOLVER_ERROR' \
  || { printf '%s\n' "$out" | sed 's/^/        /' | head -8; fail "leg 9: a stub solver (exit 42) did not fail the re-solve row by name (rc=$rc)"; }
echo "  [gate] leg 9: RED on --q7-resolve with a stub solver (WITNESS_RESULT=SOLVER_ERROR), named"

# ---- leg 10: --q7-resolve with no solver -------------------------------------------------------
out=$(run_row "$WORK/res.sh" "$WORK/helpers.sh" "$EVID" 1 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'Q7RESOLVE_FAIL	moore-strict: --q7-resolve given but kissat is not on PATH' \
  && ! printf '%s\n' "$out" | grep -q '^SKIPPED' \
  || fail "leg 10: --q7-resolve without kissat did not FAIL loudly (rc=$rc)"
echo "  [gate] leg 10: RED, loud, on --q7-resolve with no solver on PATH (never a skip)"

# ---- leg 11: the live re-solve, opt-in ----------------------------------------------------------
if [ "${Q7WIT_LIVE:-0}" = 1 ]; then
  command -v kissat >/dev/null 2>&1 || err "Q7WIT_LIVE=1 but no kissat on PATH"
  out=$(run_row "$WORK/res.sh" "$WORK/helpers.sh" "$EVID" 1 "$PATH"); rc=$?
  [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -qx 'Q7RESOLVE_OK	moore-strict' && printf '%s\n' "$out" | grep -qx 'Q7RESOLVE_OK	grand-strict' \
    || { printf '%s\n' "$out" | sed 's/^/        /' | head -12; fail "leg 11: the live re-solve row failed on the real solver (rc=$rc)"; }
  printf '%s\n' "$out" | grep -qE '^witness_seq|^SEQ|[0-9]+(,[0-9]+){63}' && fail "leg 11: the re-solve row printed a sequence (build-dependent bytes in diffed output)"
  echo "  [gate] leg 11: live re-solve with $(kissat --version 2>/dev/null | head -1 | sed 's/^/kissat /'): rc 0, Q7RESOLVE_OK for both targets, no sequence printed"
else
  echo "  [gate] leg 11: NOT RUN (opt-in: Q7WIT_LIVE=1 with kissat on PATH); the live re-solve is unmeasured by this run"
fi

# ---- row mutants ---------------------------------------------------------------------------------
# A mutant is KILLED when the red leg that covers it would go green on the mutated row: the mutated
# row returns 0 on the bad fixture, or loses the named failure line the leg greps for. It SURVIVES
# when the mutated row still fails by name -- the leg then cannot tell the mutant from the real row.
# (The first draft of this function had the two cases swapped and reported a killed mutant as
# survived; measured 2026-09-25 on M1 before it shipped.)
mutant_row(){ # mutant_row <id> <file> <sed-expr> <fixture-dir> <fixture-name> <named-line-the-leg-greps>
  local id="$1" f="$2" expr="$3" fix="$4" out rc
  local m="$WORK/m_$id.sh"
  sed -e "$expr" "$WORK/$f" > "$m"
  cmp -s "$m" "$WORK/$f" && err "mutant $id did not apply ($expr) -- anchors inside the row moved?"
  out=$(run_row "$m" "$WORK/helpers.sh" "$fix" 0 "$NOKISSAT:$BASEPATH"); rc=$?
  if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q "$6"; then
    fail "mutant $id SURVIVED ($expr): the mutated row still fails by name on $5, so the covering leg cannot detect that regression"
  fi
  echo "  [gate] mutant $id killed (mutated row: rc=$rc on $5 -- the covering leg goes red)"
}
mutant_row M1_missing_file_not_fatal wit.sh 's/is MISSING \(.*\)"; wrc=1; continue; fi/is MISSING \1"; continue; fi/' "$WORK/fix7" "a missing file" 'pinned witness file is MISSING'
mutant_row M2_property_check_not_fatal wit.sh 's/|| { wrc=1; continue; }/|| true/' "$WORK/fix6" "King Wen" 'the sequence IS King Wen'
# M3 is a source-text mutant of leg 1: the pre-fix aggregation line must be caught by leg 1's grep
if sed 's/^agg TR12_Q7 .*/agg TR12_Q7 TR12_Q7_KW TR12_Q7_HIST TR12_Q7_RANKS/' "$SRC" | grep -E '^agg TR12_Q7 ' | grep -q 'TR12_Q7_WITNESSES'; then
  fail "mutant M3 SURVIVED: leg 1's grep would accept an aggregation line without the witness leg"
fi
echo "  [gate] mutant M3_prefix_agg_line killed"

echo "  [gate] 10 legs measured (leg 11 $([ "${Q7WIT_LIVE:-0}" = 1 ] && echo run || echo opt-in, not run)); 3/3 mutants killed"
echo "D5_04_Q7_WITNESSES_GATE=PASS"
