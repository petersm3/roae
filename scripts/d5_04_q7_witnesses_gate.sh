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
# CX-321 (2026-10-09, Fable; Q-431) -- the witness PROPERTY contract: the published claims of the
# pinned constant are asserted by the row, and each is red-tested on a fixture that passes everything
# older (its precondition is asserted first) or on a mutated instrument:
#   leg 12  RED, a genuine grand-strict member 4 slot-edits from KW (the witness with slot 5 reversed)
#           -> fails ONLY the published locus 7,21,22, by name; moore-strict still passes beside it
#   leg 13  RED, C3 = 776 as an EQUALITY: (a) the row's claim constant moved to 775, in Python and in
#           the C-side comparison -> the real witness fails by name with both numbers; (b) the published
#           C3 = 112 positional witness (IN SUPER) -> both C3 lines fire by name
#   leg 14  RED, a shimmed sat.py whose grand-strict silently drops the gender rule -> the row's own
#           published rule set catches it, by name (the rule set is no longer read from sat.py)
#   leg 15  RED, (a) a wrapper binary answering --r11-verify with a wrong vector -> C/Python
#           disagreement, by name; (b) the leg-5 rule break is also caught by the C tally
#   leg 16  RED, each in-row control made to pass (KW-rules control fed the witness; slot-1 flip made
#           a no-op) -> "dead control", by name
#   leg 17  the constant printed in LITERATURE_RULES_POPULATION_TESTS.md (twice) and in the witness
#           README equals the pinned SEQ; a planted one-digit change in either is caught
#   leg 18  the green run carries pins_identical YES (Q-796), Q7WIT_CONTRACT HOLDS and every asserted
#           property as a whole line
# plus row mutants, each of which must be caught by the legs above:
#   M1  the missing-file branch no longer fails the row      (leg 7 would go green)
#   M2  the property check's failure no longer fails the row  (legs 4/5/6 would go green)
#   M3  the pre-fix aggregation line (witnesses not a leg)     (leg 1 would go green)
#   M4  both locus checks disabled                            (leg 12 goes green: rc=0, the isolation proof)
#   M5  the Python C3 equality disabled                        (leg 13b loses its named line)
#   M6  the rule-set pin disabled                              (leg 14 goes green)
#   M7  the C/Python R11 disagreement no longer fatal          (leg 15a loses its named line)
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
ROOT=$(pwd); RUN_SOLVE=; RUN_ROOT=   # CX-321: run_row's one-call overrides start EMPTY, so an inherited value never reaches the row (Q-949)
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
grep -E '^agg TR12_Q7 ' "$SRC" | grep -c 'TR12_Q7_WITNESSES' >/dev/null || fail "leg 1: the agg TR12_Q7 line does not name TR12_Q7_WITNESSES"
[ "$(grep -cE '^agg TR12_Q7 ' "$SRC")" -eq 1 ] || fail "leg 1: expected exactly one agg TR12_Q7 line"
grep -qE '^\s*row_end TR12_Q7_WITNESSES ' "$SRC" || fail "leg 1: no row_end TR12_Q7_WITNESSES -- the witness row is not a real row"
if grep -vE '^\s*#' "$SRC" | grep -E 'TR12_Q7_WITNESSES' | grep -cE '"PENDING:kissat"|"PENDING:q7-witness-row"|"PASS"' >/dev/null; then
  fail "leg 1: a non-comment line still records TR12_Q7_WITNESSES as PENDING:kissat / PENDING:q7-witness-row / PASS"
fi
if grep -vE '^\s*#' "$SRC" | grep -cE 'command -v kissat.*then\s*$' >/dev/null ; then
  # a `command -v kissat` BRANCH is allowed only inside the opt-in resolve row (a failure, never a skip)
  if grep -vE '^\s*#' "$SRC" | grep -E 'row_skip .*(kissat|q7-witness)' | grep -c . >/dev/null; then
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
  # CX-321: RUN_SOLVE / RUN_ROOT (env) substitute the binary / the repository root for ONE call -- legs 14
  # and 15 run the row against a shimmed sat.py and a wrapped binary; everything else sees the real ones.
  local row="$1" helpers="$2" wdir="$3" q7r="$4" path="$5" d="$WORK/run.$RANDOM$RANDOM"
  local solve="${RUN_SOLVE:-$SOLVE}" root="${RUN_ROOT:-$ROOT}"
  rm -rf "$d"; mkdir -p "$d/art" "$d/work"; cp "$WORK/q7_kw.json" "$d/art/q7_kw.json"
  {
    echo 'set -u'
    echo "SOLVE=$(printf '%q' "$solve"); WORK=$(printf '%q' "$d/work"); ARTDIR=$(printf '%q' "$d/art"); REPO_ROOT=$(printf '%q' "$root"); RAW=$(printf '%q' "$d/raw"); Q7_RESOLVE=$q7r"
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
  grep -qx "Q7WIT_OK	$t" <<<"$out" || fail "leg 2: no Q7WIT_OK for $t"
  want=$(sha256sum < "$EVID/$t.txt" | cut -d' ' -f1)
  grep -qx "witness_sha256	$want" <<<"$out" || fail "leg 2: the row did not print the sha256 of $t.txt ($want)"
done
grep -q 'Q7WIT_FAIL' <<<"$out" && fail "leg 2: a Q7WIT_FAIL line on a green run"
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
[ "$rc" -ne 0 ] && grep -q 'Q7WIT_FAIL	moore-strict: --check-arrangement does not say IN SUPER' <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT' | sed 's/^/        /'; fail "leg 4: a witness with C1 broken did not fail the row by name (rc=$rc)"; }
grep -qx 'Q7WIT_OK	grand-strict' <<<"$out" || fail "leg 4: the untouched grand-strict witness should still pass beside the bad one"
echo "  [gate] leg 4: RED on a planted C1-broken witness, named"

# ---- leg 5: an IN-C15 non-KW sequence breaking one enforced rule ---------------------------------
if [ "$L5TARGET" = grand-strict ]; then mkfix "$WORK/fix5" - "$L5SEQ"; else mkfix "$WORK/fix5" "$L5SEQ" -; fi
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix5" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -q "Q7WIT_FAIL	$L5TARGET: the pinned sequence violates a rule the target enforces" <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|rule_' | sed 's/^/        /'; fail "leg 5: an IN-C15 sequence breaking a $L5TARGET rule did not fail the row by name (rc=$rc)"; }
grep -q "verdict C15  (C1-C5, C3<=776):   IN" <<<"$out" || fail "leg 5: the fixture was meant to be IN C15 (only a rule broken) and is not"
echo "  [gate] leg 5: RED on an IN-C15 non-KW sequence that breaks one $L5TARGET rule ($(printf '%s\n' "$out" | sed -n 's/^rule_violations\t//p' | head -1)), named"

# ---- leg 6: King Wen submitted as the witness ---------------------------------------------------
mkfix "$WORK/fix6" "$KWARR" -
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix6" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -q 'Q7WIT_FAIL	moore-strict: the sequence is byte-identical to the KW arrangement' <<<"$out" \
  && grep -q 'Q7WIT_FAIL	moore-strict: the sequence IS King Wen' <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|kw_' | sed 's/^/        /'; fail "leg 6: King Wen as the witness did not fail the row by both identity checks (rc=$rc)"; }
grep -qx 'kw_identical	YES	(positions differing from KW: 0; pair-slot layout differs from KW: NO)' <<<"$out" || fail "leg 6: kw_identical line missing"
echo "  [gate] leg 6: RED on King Wen submitted as the witness, named by both identity checks (and by the rule check, as stated above)"

# ---- leg 7: missing witness file ---------------------------------------------------------------
mkfix "$WORK/fix7" - ""
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix7" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -q 'Q7WIT_FAIL	grand-strict: pinned witness file is MISSING' <<<"$out" \
  || fail "leg 7: a missing grand-strict.txt did not fail the row by name (rc=$rc)"
echo "  [gate] leg 7: RED on a missing witness file, named"

# ---- leg 8: malformed file ---------------------------------------------------------------------
mkfix "$WORK/fix8" - -; printf '# no SEQ line here\n' > "$WORK/fix8/moore-strict.txt"
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix8" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -q 'Q7WIT_FAIL	moore-strict: expected exactly one SEQ= line, found 0' <<<"$out" \
  || fail "leg 8: a file without a SEQ= line did not fail the row by name (rc=$rc)"
echo "  [gate] leg 8: RED on a malformed witness file, named"

# ---- leg 9: --q7-resolve with a stub solver -----------------------------------------------------
out=$(run_row "$WORK/res.sh" "$WORK/helpers.sh" "$EVID" 1 "$STUB:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -q 'Q7RESOLVE_FAIL	moore-strict: sat.py --witness did not end in WITNESS_RESULT=WITNESS' <<<"$out" \
  && grep -qx 'witness_result	WITNESS_RESULT=SOLVER_ERROR' <<<"$out" \
  || { printf '%s\n' "$out" | sed 's/^/        /' | head -8; fail "leg 9: a stub solver (exit 42) did not fail the re-solve row by name (rc=$rc)"; }
echo "  [gate] leg 9: RED on --q7-resolve with a stub solver (WITNESS_RESULT=SOLVER_ERROR), named"

# ---- leg 10: --q7-resolve with no solver -------------------------------------------------------
out=$(run_row "$WORK/res.sh" "$WORK/helpers.sh" "$EVID" 1 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -q 'Q7RESOLVE_FAIL	moore-strict: --q7-resolve given but kissat is not on PATH' <<<"$out" \
  && ! grep -q '^SKIPPED' <<<"$out" \
  || fail "leg 10: --q7-resolve without kissat did not FAIL loudly (rc=$rc)"
echo "  [gate] leg 10: RED, loud, on --q7-resolve with no solver on PATH (never a skip)"

# ---- leg 11: the live re-solve, opt-in ----------------------------------------------------------
if [ "${Q7WIT_LIVE:-0}" = 1 ]; then
  command -v kissat >/dev/null 2>&1 || err "Q7WIT_LIVE=1 but no kissat on PATH"
  out=$(run_row "$WORK/res.sh" "$WORK/helpers.sh" "$EVID" 1 "$PATH"); rc=$?
  [ "$rc" -eq 0 ] && grep -qx 'Q7RESOLVE_OK	moore-strict' <<<"$out" && grep -qx 'Q7RESOLVE_OK	grand-strict' <<<"$out" \
    || { printf '%s\n' "$out" | sed 's/^/        /' | head -12; fail "leg 11: the live re-solve row failed on the real solver (rc=$rc)"; }
  grep -qE '^witness_seq|^SEQ|[0-9]+(,[0-9]+){63}' <<<"$out" && fail "leg 11: the re-solve row printed a sequence (build-dependent bytes in diffed output)"
  echo "  [gate] leg 11: live re-solve with $(kissat --version 2>/dev/null | head -1 | sed 's/^/kissat /'): rc 0, Q7RESOLVE_OK for both targets, no sequence printed"
else
  echo "  [gate] leg 11: NOT RUN (opt-in: Q7WIT_LIVE=1 with kissat on PATH); the live re-solve is unmeasured by this run"
fi

# ==== CX-321 (2026-10-09, Fable; Q-431): the witness PROPERTY contract -- the published claims of the
#      pinned constant are asserted, not merely printed. Each leg below plants a fixture that passes
#      every OLDER check and breaks exactly one NEW one (or mutates the instrument the check relies
#      on), asserts that precondition first, and then requires the row to fail BY NAME. =============
GS=$(sed -n 's/^SEQ=//p' "$EVID/grand-strict.txt" | tr -d ' \r')
# leg 12 fixture: the grand-strict witness with slot 5 reversed -- tests.py::test_r13_a_four_edit_compliant_ordering_exists
# records it as compliant with all three rules and 4 slots from KW. PRECONDITION (asserted): grand-strict
# ok, C3 = 776, every rule 0, slots 5,7,21,22 -- so the ONLY new thing it breaks is the published locus.
L12SEQ=$(printf '%s' "$GS" | awk -F, -v OFS=, '{t=$11; $11=$12; $12=t; print}')
PYTHONPATH="$ROOT" Q7X="$L12SEQ" python3 - <<'PY' || err "leg 12 precondition: the slot-5-reversed witness is not (grand-strict ok, C3 776, rules 0, slots 5,7,21,22)"
import os, sat, solve
s = [int(x) for x in os.environ["Q7X"].split(",")]; kw = list(solve._r7_kw())
v = sat.target_verdict(s, "grand-strict")
slots = [k for k in range(32) if s[2*k:2*k+2] != kw[2*k:2*k+2]]
ok = v["ok"] and v["c3"] == 776 and not v["rule_viol"] and slots == [5, 7, 21, 22] and all(v["scores"][r] == 0 for r in ("parity", "rhythm", "gender"))
raise SystemExit(0 if ok else 1)
PY
mkfix "$WORK/fix12" - "$L12SEQ"
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix12" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -qx 'Q7WIT_FAIL	grand-strict: the sequence differs from KW at slots 5,7,21,22, the published 3-slot-edit locus is 7,21,22' <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|kw_slot' | sed 's/^/        /'; fail "leg 12: a 4-slot-edit member of grand-strict did not fail the row on the published locus, by name (rc=$rc)"; }
[ "$(grep -c '^Q7WIT_FAIL	grand-strict:' <<<"$out")" -eq 1 ] || { printf '%s\n' "$out" | grep '^Q7WIT_FAIL' | sed 's/^/        /'; fail "leg 12: the locus fixture failed more than the locus check -- the leg is not isolated"; }
grep -qx 'Q7WIT_OK	moore-strict' <<<"$out" || fail "leg 12: the untouched moore-strict witness should still pass beside the fixture"
grep -qx 'Q7WIT_CONTRACT	BROKEN	rules=published c3==776 locus=7,21,22 r11=C+py gender=verify.py controls=live' <<<"$out" || fail "leg 12: no whole-line Q7WIT_CONTRACT BROKEN token on a red run"
echo "  [gate] leg 12: RED on a genuine grand-strict member 4 slot-edits from KW -- fails ONLY the published locus, by name"

# leg 13: C3 is an EQUALITY. No member of either target with C3 != 776 is known without a solver (a
# deterministic sweep of every 1..4-slot-edit neighbour of the witness found 41 moore-strict members, all
# at C3 = 776; 2026-10-09), so the value check is proven live two ways: (a) the row's CLAIM constant is
# mutated to 775 in each language and the REAL witness must then fail by name with both numbers in the
# message; (b) the published C3 = 112 positional witness (IN SUPER, reports/certificates/
# c3_positional_witnesses.txt) is planted and must fail on the C3 lines by name -- it also breaks the
# literature rules, which is stated, so (b) proves the message fires and (a) proves the comparison.
sed 's/^CLAIM_C3 = 776$/CLAIM_C3 = 775/' "$WORK/helpers.sh" > "$WORK/helpers_c3py.sh"
cmp -s "$WORK/helpers_c3py.sh" "$WORK/helpers.sh" && err "leg 13a: the CLAIM_C3 = 776 line is not in the extracted helpers (anchor moved?)"
out=$(run_row "$WORK/wit.sh" "$WORK/helpers_c3py.sh" "$EVID" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -qx 'Q7WIT_FAIL	grand-strict: C3 is 776, the published claim is C3 = 775 -- IN C15 (c3 <= 776) is not the claim' <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|c3_' | sed 's/^/        /'; fail "leg 13a: with the Python claim moved to 775 the real witness did not fail by name (rc=$rc)"; }
sed 's/\[ "\$c3v" != 776 \]/[ "$c3v" != 775 ]/; s/the published claim is C3 = 776"; frc=1; fi/the published claim is C3 = 775"; frc=1; fi/' "$WORK/helpers.sh" > "$WORK/helpers_c3c.sh"
cmp -s "$WORK/helpers_c3c.sh" "$WORK/helpers.sh" && err "leg 13a: the C-side c3v != 776 comparison is not in the extracted helpers (anchor moved?)"
out=$(run_row "$WORK/wit.sh" "$WORK/helpers_c3c.sh" "$EVID" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -qx 'Q7WIT_FAIL	moore-strict: --check-arrangement measures C3 = 776, the published claim is C3 = 775' <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|c3_' | sed 's/^/        /'; fail "leg 13a: with the C-side claim moved to 775 the real witness did not fail by name (rc=$rc)"; }
C3POS="$ROOT/reports/certificates/c3_positional_witnesses.txt"
[ -f "$C3POS" ] || err "leg 13b: $C3POS is missing"
L13SEQ=$(sed -n 's/^SEQ=//p' "$C3POS" | head -1 | tr -s ' ' ',' | sed 's/^,//; s/,$//')
"$SOLVE" --check-arrangement "$L13SEQ" > "$WORK/l13.out" 2>&1 < /dev/null
grep -q 'verdict SUPER (C1&C2&C4&C5):     IN' "$WORK/l13.out" && grep -q 'C3 complement distance: *HOLD (value 112, ceiling 776)' "$WORK/l13.out" \
  || err "leg 13b precondition: the first c3_positional_witnesses.txt sequence is not IN SUPER at C3 = 112"
mkfix "$WORK/fix13" "$L13SEQ" -
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix13" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -qx 'Q7WIT_FAIL	moore-strict: --check-arrangement measures C3 = 112, the published claim is C3 = 776' <<<"$out" \
  && grep -qx 'Q7WIT_FAIL	moore-strict: C3 is 112, the published claim is C3 = 776 -- IN C15 (c3 <= 776) is not the claim' <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|c3_' | sed 's/^/        /'; fail "leg 13b: an IN-SUPER sequence at C3 = 112 did not fail both C3 lines by name (rc=$rc)"; }
echo "  [gate] leg 13: RED on C3 != 776 -- the claim constant moved to 775 fails the real witness by name in C and in Python; the C3 = 112 positional witness fails both C3 lines by name"

# leg 14: the rule SET is pinned in the row, not read from sat.py. A shimmed sat.py whose target_rules
# drops gender from grand-strict (everything else re-exported from the real module) must fail by name.
SHIM="$WORK/shimroot"; rm -rf "$SHIM"; mkdir -p "$SHIM"
ln -s "$ROOT/solve.py" "$SHIM/solve.py"; ln -s "$ROOT/verify.py" "$SHIM/verify.py"
cat > "$SHIM/sat.py" <<PY
import importlib.util as _u, sys as _s
_spec = _u.spec_from_file_location("_real_sat", "$ROOT/sat.py"); _m = _u.module_from_spec(_spec); _s.modules["_real_sat"] = _m; _spec.loader.exec_module(_m)
globals().update({k: v for k, v in vars(_m).items() if not k.startswith("__")})
def target_rules(t):
    r = set(_m.target_rules(t)); r.discard("gender"); return r
PY
(cd "$SHIM" && PYTHONPATH="$SHIM" python3 -c 'import sat; raise SystemExit(0 if set(sat.target_rules("grand-strict")) == {"parity","rhythm"} and sat.target_verdict(sat.KW,"grand-strict")["rule_viol"].get("parity") == 2 else 1)') \
  || err "leg 14 precondition: the shimmed sat.py does not drop gender from grand-strict while re-exporting the rest"
out=$(RUN_ROOT="$SHIM" run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$EVID" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -qx 'Q7WIT_FAIL	grand-strict: sat.target_rules enforces {parity rhythm} but the published target enforces {gender parity rhythm} -- the rule set moved under the claim' <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|rules_' | sed 's/^/        /'; fail "leg 14: a sat.py whose grand-strict no longer enforces gender did not fail the row by name (rc=$rc)"; }
grep -qx 'Q7WIT_OK	moore-strict' <<<"$out" || fail "leg 14: moore-strict (whose rule set the shim leaves alone) should still pass"
echo "  [gate] leg 14: RED on a sat.py whose grand-strict silently drops the gender rule -- the published rule set is pinned in the row, by name"

# leg 15: the SECOND LANGUAGE. (a) a wrapper binary that answers --r11-verify with a wrong vector and
# delegates everything else to the real binary -> the row must fail on the C/Python disagreement by name
# (the C form's exit status is 0 either way, which is why the fields, not rc, are compared); (b) the
# leg-5 rule-breaking fixture must ALSO be caught by the C tally (both languages read rhythm=2).
WRAP="$WORK/wrapsolve"; mkdir -p "$WRAP"
printf '#!/bin/sh\nif [ "$1" = "--r11-verify" ]; then echo "1,0,0,0,0,0,1,2"; exit 0; fi\nexec %s "$@"\n' "$(printf '%q' "$SOLVE")" > "$WRAP/solve"; chmod +x "$WRAP/solve"
[ "$("$WRAP/solve" --r11-verify "$GS")" = "1,0,0,0,0,0,1,2" ] || err "leg 15 precondition: the wrapper does not answer --r11-verify"
grep -q 'verdict SUPER (C1&C2&C4&C5):     IN' <<<"$("$WRAP/solve" --check-arrangement "$GS" 2>/dev/null)" || err "leg 15 precondition: the wrapper does not delegate --check-arrangement"
out=$(RUN_SOLVE="$WRAP/solve" run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$EVID" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -qx 'Q7WIT_FAIL	moore-strict: solve.c and solve.py disagree on the R11 rule vector (1,0,0,0,0,0,1,2 vs 0,0,0,0,0,0,1,2)' <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|r11_' | sed 's/^/        /'; fail "leg 15a: a binary whose --r11-verify disagrees with solve.py did not fail the row by name (rc=$rc)"; }
if [ "$L5TARGET" = grand-strict ]; then mkfix "$WORK/fix15" - "$L5SEQ"; else mkfix "$WORK/fix15" "$L5SEQ" -; fi
out=$(run_row "$WORK/wit.sh" "$WORK/helpers.sh" "$WORK/fix15" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -q "^Q7WIT_FAIL	$L5TARGET: the C re-tally of the enforced rules (parity,rhythm\[,gender\]) is " <<<"$out" \
  && grep -q "^r11_agree	YES" <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|r11_' | sed 's/^/        /'; fail "leg 15b: the rule-breaking fixture was not caught by the C tally with both languages agreeing (rc=$rc)"; }
echo "  [gate] leg 15: RED on a C/Python R11 disagreement, by name; the leg-5 rule break is caught in C too ($(printf '%s\n' "$out" | sed -n 's/^r11_c\t//p' | head -1))"

# leg 16: the in-row CONTROLS are live. (a) feed the KW-rules control the witness itself -> it "passes"
# and the row must fail as a dead control; (b) make the slot-1 flip a no-op -> the checker says IN and
# the row must fail as a dead control. Either silently passing would mean a dead instrument reads green.
sed 's/^ctl = sat.target_verdict(kw, t)$/ctl = sat.target_verdict(seq, t)/' "$WORK/helpers.sh" > "$WORK/helpers_ctl1.sh"
cmp -s "$WORK/helpers_ctl1.sh" "$WORK/helpers.sh" && err "leg 16a: the KW-rules control line is not in the extracted helpers (anchor moved?)"
out=$(run_row "$WORK/wit.sh" "$WORK/helpers_ctl1.sh" "$EVID" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -qx 'Q7WIT_FAIL	moore-strict: dead control -- King Wen scores 0 violations on every rule the target enforces, so the rule re-score can fail nothing' <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|ctl_' | sed 's/^/        /'; fail "leg 16a: a passing rules control did not fail the row as a dead control (rc=$rc)"; }
sed "s/awk -F, -v OFS=, '{x=\$3; \$3=\$4; \$4=x; print}'/awk -F, -v OFS=, '{print}'/" "$WORK/helpers.sh" > "$WORK/helpers_ctl2.sh"
cmp -s "$WORK/helpers_ctl2.sh" "$WORK/helpers.sh" && err "leg 16b: the slot-1 flip awk is not in the extracted helpers (anchor moved?)"
out=$(run_row "$WORK/wit.sh" "$WORK/helpers_ctl2.sh" "$EVID" 0 "$NOKISSAT:$BASEPATH"); rc=$?
[ "$rc" -ne 0 ] && grep -qx 'Q7WIT_FAIL	moore-strict: dead control -- --check-arrangement does not say OUT for King Wen with slot 1 flipped' <<<"$out" \
  || { printf '%s\n' "$out" | grep -E 'Q7WIT|ctl_' | sed 's/^/        /'; fail "leg 16b: a passing checker control did not fail the row as a dead control (rc=$rc)"; }
echo "  [gate] leg 16: RED when either in-row control passes -- a dead instrument cannot read green"

# leg 17: TWO SOURCES. The constant the reports print (documentation/LITERATURE_RULES_POPULATION_TESTS.md,
# twice, wrapped across lines; reports/evidence/q7_witnesses/README.md, once) must equal the pinned
# SEQ= byte-for-byte: the property row verifies the file, and this leg ties the file to the prose that
# makes the claims. D5_04_LRPT / D5_04_WREADME override the documents ONLY so the red half can plant a
# one-digit change and confirm the leg catches it.
two_sources(){ # two_sources <lrpt> <readme> <seq>  -> prints TWO_SOURCES=AGREE|DISAGREE:<why>; rc 0 iff AGREE
  PYTHONPATH="$ROOT" python3 - "$1" "$2" "$3" <<'PY'
import re, sys
lrpt, readme, seq = sys.argv[1], sys.argv[2], sys.argv[3]
t = open(lrpt, encoding="utf-8").read()
hits = [re.sub(r"\s+", "", m) for m in re.findall(r"`(63,0(?:,\s*\d+)+)`", t)]
hits = [h for h in hits if h.count(",") == 63]
r = [l.strip()[4:].replace(" ", "") for l in open(readme, encoding="utf-8") if l.strip().startswith("SEQ=")]
why = []
if len(hits) != 2: why.append("LRPT prints %d 64-value backticked constants, expected 2" % len(hits))
if any(h != seq for h in hits): why.append("an LRPT copy differs from the pinned SEQ")
if len(r) != 1: why.append("README has %d SEQ= lines, expected 1" % len(r))
if r and r[0] != seq: why.append("the README SEQ= differs from the pinned SEQ")
print("TWO_SOURCES=" + ("AGREE" if not why else "DISAGREE:" + "; ".join(why)))
raise SystemExit(0 if not why else 1)
PY
}
LRPT_REL=documentation/LITERATURE_RULES_POPULATION_TESTS.md; LRPT="${D5_04_LRPT:-$ROOT/$LRPT_REL}"; WREADME="${D5_04_WREADME:-$EVID/README.md}"
two_sources "$LRPT" "$WREADME" "$GS" | sed 's/^/        /'
two_sources "$LRPT" "$WREADME" "$GS" >/dev/null || fail "leg 17: the constant printed in LRPT / the witness README does not equal the pinned grand-strict SEQ"
sed '0,/`63,0,17,34/s//`63,0,17,35/' "$LRPT" > "$WORK/lrpt_planted.md"
cmp -s "$WORK/lrpt_planted.md" "$LRPT" && err "leg 17: could not plant a one-digit change in the LRPT constant (anchor moved?)"
two_sources "$WORK/lrpt_planted.md" "$WREADME" "$GS" >/dev/null && fail "leg 17: a one-digit change in the LRPT constant was not caught"
sed '0,/^SEQ=63,0,17,34/s//SEQ=63,0,17,35/' "$WREADME" > "$WORK/readme_planted.md"
cmp -s "$WORK/readme_planted.md" "$WREADME" && err "leg 17: could not plant a one-digit change in the README SEQ= (anchor moved?)"
two_sources "$LRPT" "$WORK/readme_planted.md" "$GS" >/dev/null && fail "leg 17: a one-digit change in the README SEQ= was not caught"
echo "  [gate] leg 17: the two LRPT copies and the README SEQ= equal the pinned constant; a planted one-digit change in either is caught"

# leg 18: the two pins are one sequence (TR-12 section Q7; Q-796: Q7_DISTINCT_WITNESSES=NO). The row
# prints it; this leg pins the public sentence to the committed files.
grep -qx 'pins_identical	YES' "$WORK/green.raw" || fail "leg 18: the green run did not print pins_identical YES -- TR-12 section Q7 says the two pinned files carry one sequence"
grep -qx 'Q7WIT_CONTRACT	HOLDS	rules=published c3==776 locus=7,21,22 r11=C+py gender=verify.py controls=live' "$WORK/green.raw" || fail "leg 18: the green run did not print the whole-line Q7WIT_CONTRACT HOLDS token"
for ln in 'c3_checker	776' 'c3_value	776	(published claim: C3 = 776)' 'kw_slot_edits	7,21,22	(published locus: 7,21,22; positions differing: 6, published: 6)' 'kw_edit_decomposition	slot 7 flipped; pairs 21/22 swapped, slot 22 flipped	(as published)' 'r11_agree	YES' 'ctl_slot1flip	OUT' 'rules_claimed	gender parity rhythm	(the published rule set; sat.target_rules agrees)'; do
  grep -qx "$ln" "$WORK/green.raw" || fail "leg 18: the green run lacks the whole line [$ln]"
done
echo "  [gate] leg 18: the green run carries pins_identical YES, Q7WIT_CONTRACT HOLDS and every asserted property as a whole line"

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
  if [ "$rc" -ne 0 ] && grep -q "$6" <<<"$out"; then
    fail "mutant $id SURVIVED ($expr): the mutated row still fails by name on $5, so the covering leg cannot detect that regression"
  fi
  echo "  [gate] mutant $id killed (mutated row: rc=$rc on $5 -- the covering leg goes red)"
}
mutant_row M1_missing_file_not_fatal wit.sh 's/is MISSING \(.*\)"; wrc=1; continue; fi/is MISSING \1"; continue; fi/' "$WORK/fix7" "a missing file" 'pinned witness file is MISSING'
mutant_row M2_property_check_not_fatal wit.sh 's/|| { wrc=1; continue; }/|| true/' "$WORK/fix6" "King Wen" 'the sequence IS King Wen'
# M3 is a source-text mutant of leg 1: the pre-fix aggregation line must be caught by leg 1's grep
if sed 's/^agg TR12_Q7 .*/agg TR12_Q7 TR12_Q7_KW TR12_Q7_HIST TR12_Q7_RANKS/' "$SRC" | grep -E '^agg TR12_Q7 ' | grep -c 'TR12_Q7_WITNESSES' >/dev/null; then
  fail "mutant M3 SURVIVED: leg 1's grep would accept an aggregation line without the witness leg"
fi
echo "  [gate] mutant M3_prefix_agg_line killed"
# CX-321 helper mutants: the same kill criterion, applied to the shared helpers rather than the row.
# RUN_ROOT / RUN_SOLVE (env) reach run_row so that M6 and M7 are measured in the world of their legs.
mutant_helpers(){ # mutant_helpers <id> <sed-expr> <fixture-dir> <fixture-name> <named-line-the-leg-greps>
  local id="$1" expr="$2" fix="$3" out rc
  local m="$WORK/mh_$id.sh"
  sed -e "$expr" "$WORK/helpers.sh" > "$m"
  cmp -s "$m" "$WORK/helpers.sh" && err "mutant $id did not apply ($expr) -- anchors inside the helpers moved?"
  out=$(run_row "$WORK/wit.sh" "$m" "$fix" 0 "$NOKISSAT:$BASEPATH"); rc=$?; MH_RC=$rc
  if [ "$rc" -ne 0 ] && grep -q "$5" <<<"$out"; then
    fail "mutant $id SURVIVED ($expr): the mutated helpers still fail by name on $4, so the covering leg cannot detect that regression"
  fi
  echo "  [gate] mutant $id killed (mutated helpers: rc=$rc on $4 -- the covering leg goes red)"
}
# M4 disables BOTH locus checks (the slot list and the 6-position count), so its kill is also the proof that
# the leg-12 fixture passes every OTHER check: the mutated helpers must return rc=0 on it.
mutant_helpers M4_locus_not_asserted 's/^    if slots != CLAIM_SLOTS:$/    if False and slots != CLAIM_SLOTS:/; s/^    elif diff != 6:$/    elif False:/' "$WORK/fix12" "the 4-slot-edit member (leg 12)" 'the published 3-slot-edit locus is 7,21,22'
[ "$MH_RC" -eq 0 ] || fail "mutant M4: with both locus checks disabled the leg-12 fixture still fails (rc=$MH_RC) -- the fixture is not isolated to the locus"
mutant_helpers M5_c3_equality_not_asserted 's/^    if pinned and v\["c3"\] != CLAIM_C3:$/    if False:/' "$WORK/fix13" "the C3 = 112 witness (leg 13b)" 'C3 is 112, the published claim is C3 = 776'
RUN_ROOT="$SHIM" mutant_helpers M6_rule_set_not_pinned 's/^elif set(rules) != CLAIM_RULES\[t\]:$/elif False:/' "$EVID" "the shimmed sat.py (leg 14)" 'the rule set moved under the claim'
RUN_SOLVE="$WRAP/solve" mutant_helpers M7_r11_disagreement_not_fatal 's/^    elif \[ "\$r11c" != "\$r11py" \]; then/    elif false; then/' "$EVID" "the wrapped binary (leg 15a)" 'disagree on the R11 rule vector'

echo "  [gate] 17 legs measured (leg 11 $([ "${Q7WIT_LIVE:-0}" = 1 ] && echo run || echo opt-in, not run)); 7/7 mutants killed"
echo "D5_04_Q7_WITNESSES_GATE=PASS"
