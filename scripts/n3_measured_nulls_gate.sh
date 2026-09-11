#!/usr/bin/env bash
#
# n3_measured_nulls_gate.sh — the two measured nulls must be able to say EMPTY, must be able to
# REFUSE to say EMPTY, and must be able to say ERROR.
#
# WHY. Q1c and Q10a's KW-orbit-rank leg were both published as hand-written absence claims —
# `row_skip a0_q1c TR12_Q1C "SKIP:merged-into-Q4AC"` and, in c_q10a's golden, the sentence
# "(iv) KW-orbit-rank: DROPPED". Both were TRUE. Neither was CHECKED. Replacing a hand-typed
# SKIP with a hand-typed EMPTY would move the defect, not fix it: this project's dominant failure
# mode is a program emitting a success token for something it never computed, and "the answer is
# nothing" is exactly the kind of claim that rots silently once the thing it describes changes.
#
# So the two producers in scripts/tr12_repro.sh (q1c_interval_measure, q10a_kwrank_measure) are
# extracted here VERBATIM between their anchor lines and run against certificates that the live
# battery will never hand them: a rank-0 anchor, a certificate whose two engine sources disagree,
# a certificate that has grown a class-rank field, a certificate whose bracket contradicts its own
# rank. A producer that cannot be made to change its mind has not measured anything.
#
# THE FIXTURES ARE REAL ENGINE OUTPUT, not invented JSON. Both certificates below were produced on
# a throwaway n=9 ladder by
#     solve --kc-o3-cert F G <walk> --kc-cert-out cert.json
# with <walk> = the battery's own O3-midpoint anchor (rank 13056) and, for the degenerate case,
# = solve --kc-o3-unrank F G 0 (rank 0). Only fdir/gdir/engine_git/engine_source_sha were
# normalised away, exactly as scripts/tr12_repro.sh's `norm` does. The ERROR fixtures are those
# same two files with ONE field edited, so every negative differs from a positive by one line.
#
# 🔴 THE n=9 RANK-0 FIXTURE IS THE POINT. n=31 is where the null actually lands, and n=31 cannot be
# run here — the ladders are a multi-day mount. But the property being measured is "is the anchor
# the O3-least object", which is universe-independent, and at n=9 BOTH answers are obtainable from
# the real engine: the midpoint anchor is not least, unrank_O3(0) is. So the producer is exercised
# in both directions against the instrument it will use at n=31, not against a simulation of it.
#
# KNOWN LIMITATION, stated rather than papered over. Extraction anchors on the literal lines
# `# >>> N3-PRODUCERS-BEGIN` and `# <<< N3-PRODUCERS-END`. If those move or are reformatted this
# gate FAILS with "anchors moved", not with a diagnosis of the producers — over-sensitive to edits,
# never under-sensitive. A FAIL here can mean "producer broken" OR "producer moved": read the
# message.
#
# Verdict: prints exactly one N3_MEASURED_NULLS_GATE=<PASS|FAIL> line. Consume with grep -qx.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "N3_MEASURED_NULLS_GATE=FAIL"; exit 40; }
SRC=scripts/tr12_repro.sh
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [gate] $*"; echo "N3_MEASURED_NULLS_GATE=FAIL"; exit 40; }
[ -f "$SRC" ] || fail "missing $SRC"

# ---- extract the producers verbatim. If the anchors are gone the gate ERRORS; it never passes blind.
python3 - "$SRC" "$WORK/producers.sh" <<'PY' || fail "could not extract the N3 producers from $SRC (anchors moved?)"
import sys
s = open(sys.argv[1], encoding='utf-8').read()
a = s.index('# >>> N3-PRODUCERS-BEGIN'); a = s.index('\n', a) + 1
b = s.index('# <<< N3-PRODUCERS-END')
open(sys.argv[2], 'w', encoding='utf-8').write(s[a:b])
PY
grep -q 'q1c_interval_measure()'  "$WORK/producers.sh" || fail "q1c_interval_measure not inside the anchors"
grep -q 'q10a_kwrank_measure()'   "$WORK/producers.sh" || fail "q10a_kwrank_measure not inside the anchors"

# ================================================================================================
# FIXTURES
# ================================================================================================
mkdir -p "$WORK/fx"
cat > "$WORK/fx/anchor.json" <<'JSON'
{
  "type": "roae-h3b-rank-certificate",
  "version": 1,
  "space": "C1C2C4C5-SUPERSPACE",
  "order": "O3(=compare_solutions:pair-vector-lex,then-orient-lex)",
  "object": "WALK-rank",
  "n": 9,
  "walk": "1,32,8,4,2,16,31,62,55,59,61,47,45,18,33,30,12,51",
  "rank3": "13056",
  "m": 128,
  "orient_idx": 96,
  "class_first_rank3": "12960",
  "N_total": "26112",
  "neighbor_prev_rank": "13055",
  "neighbor_prev_walk": "1,32,4,8,16,2,62,31,59,55,47,61,45,18,30,33,12,51",
  "neighbor_next_rank": "13057",
  "neighbor_next_walk": "1,32,8,4,2,16,31,62,55,59,61,47,45,18,30,33,12,51",
  "fdir": "<FDIR>",
  "gdir": "<GDIR>",
  "pl_hash": "b5270954d483baaf",
  "class_rank_note": "WALK rank (class-rank = distinct records preceding, NOT computed); class block = [class_first_rank3, +m)",
  "c15_note": "the exact C15 (C1-C5) rank/count was PRICED AND DECLINED (~$3-5K; TR-12 s9), NOT 'not computable': the C3 obstruction of TR-11 s10(ii) is dissolved by the Lean theorem c3_slot_decomposition (lean/C3Decomposition.lean); every rank here is over the C1&C2&C4&C5 superspace and any C15 figure in this corpus is a labeled estimate",
  "engine_git": "<GIT>",
  "engine_source_sha": "<SRC>",
  "semantics": "certificate, not proof"
}
JSON
cat > "$WORK/fx/w0.json" <<'JSON'
{
  "type": "roae-h3b-rank-certificate",
  "version": 1,
  "space": "C1C2C4C5-SUPERSPACE",
  "order": "O3(=compare_solutions:pair-vector-lex,then-orient-lex)",
  "object": "WALK-rank",
  "n": 9,
  "walk": "2,16,55,59,61,47,31,62,4,8,32,1,33,30,18,45,12,51",
  "rank3": "0",
  "m": 64,
  "orient_idx": 0,
  "class_first_rank3": "0",
  "N_total": "26112",
  "neighbor_prev_rank": "NONE",
  "neighbor_prev_walk": "NONE",
  "neighbor_next_rank": "1",
  "neighbor_next_walk": "2,16,55,59,61,47,31,62,4,8,1,32,33,30,18,45,12,51",
  "fdir": "<FDIR>",
  "gdir": "<GDIR>",
  "pl_hash": "b5270954d483baaf",
  "class_rank_note": "WALK rank (class-rank = distinct records preceding, NOT computed); class block = [class_first_rank3, +m)",
  "c15_note": "the exact C15 (C1-C5) rank/count was PRICED AND DECLINED (~$3-5K; TR-12 s9), NOT 'not computable': the C3 obstruction of TR-11 s10(ii) is dissolved by the Lean theorem c3_slot_decomposition (lean/C3Decomposition.lean); every rank here is over the C1&C2&C4&C5 superspace and any C15 figure in this corpus is a labeled estimate",
  "engine_git": "<GIT>",
  "engine_source_sha": "<SRC>",
  "semantics": "certificate, not proof"
}
JSON

# source B is --kc-o3-rank's transcript; the producer reads exactly one line of it.
printf 'order=O3\tobject=WALK\tspace=C1C2C4C5-SUPERSPACE\nrank3\t13056\n' > "$WORK/fx/anchor.rank"
printf 'order=O3\tobject=WALK\tspace=C1C2C4C5-SUPERSPACE\nrank3\t0\n'     > "$WORK/fx/w0.rank"

# ---- one-field edits of the two real certificates. Each negative differs from a positive by one line.
sed 's#"neighbor_prev_rank": "NONE"#"neighbor_prev_rank": "41"#' "$WORK/fx/w0.json" > "$WORK/fx/w0_liar.json"
sed 's#"N_total": "26112"#"N_total": "9000"#'                     "$WORK/fx/anchor.json" > "$WORK/fx/anchor_smalluniverse.json"
sed 's#"orient_idx": 0,#"orient_idx": 5,#'                        "$WORK/fx/w0.json" > "$WORK/fx/w0_decomp.json"
sed 's#"class_rank_note": "[^"]*"#"class_rank_note": "class-rank = distinct records preceding, computed below"#' \
                                                                  "$WORK/fx/w0.json" > "$WORK/fx/w0_note.json"
sed 's#"m": 64,#"m": 64,\n  "class_rank": "0",#'                  "$WORK/fx/w0.json" > "$WORK/fx/w0_computable.json"
grep -q '"class_rank": "0"' "$WORK/fx/w0_computable.json" || fail "fixture w0_computable.json did not grow the field it exists to carry"
grep -q '"orient_idx": 5,'  "$WORK/fx/w0_decomp.json"     || fail "fixture w0_decomp.json was not edited"

# ================================================================================================
# THE EXPECTED SET.  case | producer | args | the whole-line token that MUST come back.
# ================================================================================================
run_case(){ # run_case NAME PRODUCER ARGS... -> echoes the verdict line, or NOVERDICT
  local name="$1" prod="$2"; shift 2
  ( set +u; . "$WORK/producers.sh" >/dev/null 2>&1
    "$prod" "$@" "$WORK/v.txt" >/dev/null 2>&1
    head -1 "$WORK/v.txt" 2>/dev/null ) | head -1
}

check_all(){ # -> 0 iff every case returns its pinned token
  local ok=0 got
  # (1) real n=9 anchor: the interval has 13056 elements. MUST NOT say EMPTY.
  got=$(run_case q1c-nonempty q1c_interval_measure "$WORK/fx/anchor.json" "$WORK/fx/anchor.rank")
  [ "$got" = "TR12_Q1C=NONEMPTY:interval-cardinality-13056" ] || { $VERBOSE && echo "  [case] q1c-nonempty -> ${got:-<none>}"; ok=1; }
  # (2) real n=9 unrank_O3(0): the interval is degenerate. MUST say EMPTY.
  got=$(run_case q1c-empty q1c_interval_measure "$WORK/fx/w0.json" "$WORK/fx/w0.rank")
  [ "$got" = "TR12_Q1C=EMPTY:interval-degenerate-at-n31" ] || { $VERBOSE && echo "  [case] q1c-empty -> ${got:-<none>}"; ok=1; }
  # (3) the two engine subcommands disagree -> ERROR, never EMPTY.
  got=$(run_case q1c-disagree q1c_interval_measure "$WORK/fx/w0.json" "$WORK/fx/anchor.rank")
  [ "$got" = "TR12_Q1C=ERROR:sources-disagree" ] || { $VERBOSE && echo "  [case] q1c-disagree -> ${got:-<none>}"; ok=1; }
  # (4) rank3 says 0 but the bracket names a predecessor -> ERROR, never EMPTY.
  got=$(run_case q1c-liar q1c_interval_measure "$WORK/fx/w0_liar.json" "$WORK/fx/w0.rank")
  [ "$got" = "TR12_Q1C=ERROR:predecessor-witness-contradicts-rank" ] || { $VERBOSE && echo "  [case] q1c-liar -> ${got:-<none>}"; ok=1; }
  # (5) a rank outside its own universe is not a rank.
  got=$(run_case q1c-outside q1c_interval_measure "$WORK/fx/anchor_smalluniverse.json" "$WORK/fx/anchor.rank")
  [ "$got" = "TR12_Q1C=ERROR:rank-outside-universe" ] || { $VERBOSE && echo "  [case] q1c-outside -> ${got:-<none>}"; ok=1; }
  # (6) no certificate at all -> ERROR. "I cannot tell" is a verdict; EMPTY is not.
  got=$(run_case q1c-nocert q1c_interval_measure "$WORK/fx/does-not-exist.json" "$WORK/fx/w0.rank")
  [ "$got" = "TR12_Q1C=ERROR:cert-absent" ] || { $VERBOSE && echo "  [case] q1c-nocert -> ${got:-<none>}"; ok=1; }
  # (7) real n=9 anchor: rank not forced to 0, so the orbit-rank question is REAL, not vacuous.
  got=$(run_case q10a-nonvacuous q10a_kwrank_measure "$WORK/fx/anchor.json")
  [ "$got" = "TR12_Q10A_KWRANK=NONVACUOUS:anchor-is-not-the-o3-least-object" ] || { $VERBOSE && echo "  [case] q10a-nonvacuous -> ${got:-<none>}"; ok=1; }
  # (8) real n=9 unrank_O3(0): not computed AND forced to 0 -> EMPTY.
  got=$(run_case q10a-empty q10a_kwrank_measure "$WORK/fx/w0.json")
  [ "$got" = "TR12_Q10A_KWRANK=EMPTY:class-rank-uncomputable-under-kw-labels" ] || { $VERBOSE && echo "  [case] q10a-empty -> ${got:-<none>}"; ok=1; }
  # (9) the day the certificate supplies a class rank, the null ENDS. It must not age into a lie.
  got=$(run_case q10a-computable q10a_kwrank_measure "$WORK/fx/w0_computable.json")
  [ "$got" = "TR12_Q10A_KWRANK=COMPUTABLE:cert-supplies-class_rank" ] || { $VERBOSE && echo "  [case] q10a-computable -> ${got:-<none>}"; ok=1; }
  # (10) the certificate stops saying "NOT computed" -> ERROR, not a silent EMPTY.
  got=$(run_case q10a-note q10a_kwrank_measure "$WORK/fx/w0_note.json")
  [ "$got" = "TR12_Q10A_KWRANK=ERROR:class-rank-note-changed" ] || { $VERBOSE && echo "  [case] q10a-note -> ${got:-<none>}"; ok=1; }
  # (11) rank3 != class_first_rank3 + orient_idx -> the certificate is inconsistent; conclude nothing.
  got=$(run_case q10a-decomp q10a_kwrank_measure "$WORK/fx/w0_decomp.json")
  [ "$got" = "TR12_Q10A_KWRANK=ERROR:cert-decomposition-broken" ] || { $VERBOSE && echo "  [case] q10a-decomp -> ${got:-<none>}"; ok=1; }
  return $ok
}

VERBOSE=true
check_all || fail "baseline: the producers do not reproduce all eleven pinned verdicts (above)"
echo "  [gate] baseline: 11/11 pinned verdicts reproduced (2 EMPTY, 2 refusals, 1 COMPUTABLE, 6 ERROR)"
VERBOSE=false

# ================================================================================================
# MUTANTS.  Every one MUST break at least one case; a survivor means the gate proves nothing.
# Each targets a DIFFERENT load-bearing line, so a survivor names the leg that is decorative.
# ================================================================================================
BASE=$WORK/producers.sh
mutate(){ sed "$1" "$BASE" > "$WORK/producers.sh.mut" && mv "$WORK/producers.sh.mut" "$WORK/producers.sh"; }
i=0; killed=0
for m in \
  's#if \[ "\$ra" = "0" \]; then exp="NONE"; else#if [ "$ra" != "0" ]; then exp="NONE"; else#' \
  's#if \[ "\$ra" != "\$rb" \]; then#if false; then#' \
  's#if \[ "\${prev:-}" != "\$exp" \]; then#if false; then#' \
  's#if \[ "\$(echo "\$ra < \$ntot" | bc)" != "1" \]; then#if false; then#' \
  's#\[ -s "\$cert" \]  || { _n3_q1c_err#[ 1 ]  || { _n3_q1c_err#' \
  's#if \[ -n "\$hit" \]; then#if false; then#' \
  's#\*"NOT computed"\*) : ;;#*) : ;;#' \
  's#if \[ "\$sum" != "\$r" \]; then#if false; then#' \
  's#if \[ "\$r" = "0" \]; then#if [ "$r" != "0" ]; then#' \
  ; do
  i=$((i+1)); cp "$BASE" "$WORK/base.keep"
  mutate "$m" || fail "mutant $i could not be applied"
  if cmp -s "$WORK/base.keep" "$WORK/producers.sh"; then
      cp "$WORK/base.keep" "$BASE"; fail "mutant $i changed NOTHING ($m) -- it tests no line that exists"
  fi
  if check_all; then cp "$WORK/base.keep" "$BASE"
       fail "mutant $i SURVIVED ($m) -- that leg of the producers is decorative"
  fi
  killed=$((killed+1)); cp "$WORK/base.keep" "$BASE"
done
echo "  [gate] $killed/$i mutants killed"
check_all || fail "the base producers were not restored after mutation -- this gate's own result is untrustworthy"
echo "N3_MEASURED_NULLS_GATE=PASS"
