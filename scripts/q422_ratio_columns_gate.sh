#!/usr/bin/env bash
# q422_ratio_columns_gate.sh — the atlas consumer's brute-force legs must gate the DERIVED columns
# (p, p_cond, share, the Q6 ratio / kw_p / kw_class_pct, the Q3 p), and must be able to fail on them.
#
# WHY. Until 2026-09-05 every "cell-by-cell" gate in solve.py::atlas_selftest compared the integer
# columns (mass, solutions, flow) and nothing else. Replace `_atlas_f` with a function returning "0"
# and every derived ratio in every emitted table reads 0 -- V1, which plots float(r["p"]), draws an
# empty field -- while all 24 consumer gates print PASS, ATLAS_CONSUMER=PASS, `tr12_repro.sh --n9`
# reports TR12_REPRO=PASS and the committed golden scripts/tr12_expected/n9/c_consumer.txt is
# byte-identical (MEASURED at 76e5d680: rows=60 pass=47 fail=0). Codex MQ1 section 2c (Sol) and
# MQ1A finding 2 (Astra) reached it independently; adjudicated in roae-private
# CODEX_MQ1_ADJUDICATION.md / CODEX_MQ1A_ADJUDICATION.md; code half = Q-422. The five pre-existing
# --atlas-fault injections all fire as designed and none of them touches this: the suite's
# population had a hole exactly where documentation/SOLVE_PY_CLI.md made its promise.
#
# WHAT IS PINNED. A fresh n=9 universe is built with the binary (published build line from
# documentation/VERIFY.md unless Q422_SOLVE names one), scanned, enumerated, and the consumer of the
# solve.py under test is run on it three ways:
#   leg 1  plain                       -> rc 0, ATLAS_CONSUMER=PASS, and the selftest transcript
#                                         byte-identical to the golden's selftest block
#   leg 2  --atlas-fault ratio-zero    -> rc 1, ATLAS_CONSUMER=FAIL, EXACTLY the five Q-422 gates
#                                         FAIL and the 24 pre-existing gates still PASS (the fault
#                                         corrupts derived cells only; an integer gate firing would
#                                         mean the fault is not the one described)
#   leg 3  the cell Astra computed      -> v2_river.tsv k=0 d=1 p == 0.54411764705882353, which is
#                                         14208/26112 to 17 digits (bc: scale=25 -> ...352941176...)
# plus six mutants of a COPY of the solve.py under test, every one of which must turn a leg red:
#   M1 _atlas_f -> "0"                                    the defect itself (Sol / Astra)
#   M2 _atlas_f at 9 significant digits                   a truncating formatter
#   M3 _atlas_f through a binary64 ("%.17g" % float(x))   the pre-2026-08-23 path
#   M4 V1 emit site divides by 2*N                        wrong denominator at the WIRING -- the
#                                                         formatter's unit test (tests.py) cannot see it
#   M5 _atlas_ratio_text_ok returns True                  a vacuous oracle: leg 2 goes green, so the
#                                                         gate detects its own checker being hollowed
#   M6 _atlas_ratio_text_ok accepts any decimal-looking   a shape-only oracle: "0" is a decimal
#      text                                               -> leg 2 goes green -> killed
# A mutant whose sed does not change the file is itself a FAIL (a mutant equal to the baseline
# proves nothing). Recorded EQUIVALENT mutants, not run: (a) ROUND_HALF_UP in place of HALF_EVEN --
# no n=9 ratio terminates at exactly 18 significant digits ending in 5 (N = 2^9*3*17; a tie needs a
# 2^17-scale denominator), so no cell distinguishes them below n=31; (b) V5 p_cond denominator
# `flow` -> `N` -- the emitter raises AtlasError unless flow == N at every layer.
#
# KNOWN LIMITATION, stated. (i) Reduced n only: at n=9 no King Wen walk exists, so the Q6-extremes
# gate's kw_d >= 0 branch (recomputing kw_p / kw_class_pct) is exercised by no leg here; it is the
# same code shape as the placeholders branch and is reachable only at full-31, where atlas_selftest
# refuses to run (n > 13). (ii) The transcript compare in leg 1 ties this gate to the golden: a
# legitimate new consumer gate must re-gold c_consumer.txt in the same change, or leg 1 FAILS --
# that is the intended direction (a gate that vanished must not pass). (iii) Builds solve.c on
# every run unless Q422_SOLVE is given (tr12_repro_gate.sh passes its own build); MEASURED 2026-09-05:
# ~4 s on 2 cores with Q422_SOLVE, plus the ~10 s build without it.
#
# Verdict: prints exactly one Q422_RATIO_COLUMNS_GATE=<PASS|FAIL> line. Consume with grep -qx.
# Q422_SRC overrides the solve.py under test -- ONLY so the closure check can point the gate at a
# tree that lacks its target (e.g. `git show 76e5d680:solve.py`) and confirm it reports FAIL.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "Q422_RATIO_COLUMNS_GATE=FAIL"; exit 40; }
SRC="${Q422_SRC:-solve.py}"
GOLD=scripts/tr12_expected/n9/c_consumer.txt
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [gate] $*"; echo "Q422_RATIO_COLUMNS_GATE=FAIL"; exit 40; }
[ -f "$SRC" ] || fail "missing $SRC"
[ -f "$GOLD" ] || fail "missing the n=9 golden $GOLD"
command -v python3 >/dev/null 2>&1 || fail "python3 not on PATH"

# The target must be PRESENT in the source under test, or this gate has nothing to certify.
grep -q '^def _atlas_ratio_text_ok(' "$SRC" || fail "target absent: $SRC has no _atlas_ratio_text_ok (the Q-422 oracle) -- nothing to certify"
grep -q '"ratio-zero"' "$SRC"              || fail "target absent: $SRC has no ratio-zero fault injection -- leg 2 cannot run"
sed '/^ATLAS_CONSUMER=/q' "$GOLD" > "$WORK/gold_selftest.txt"
grep -q '^\[atlas-consumer\] .*Q-422' "$WORK/gold_selftest.txt" || fail "target absent: the golden $GOLD carries no Q-422 gate line -- re-gold in the same change as the consumer"

# ---- the binary: the PUBLISHED build line, or the one the caller already built -----------------
if [ -n "${Q422_SOLVE:-}" ]; then
  SOLVE="$Q422_SOLVE"; [ -x "$SOLVE" ] || fail "Q422_SOLVE=$SOLVE is not executable"
else
  [ -f solve.c ] || fail "missing solve.c"
  BUILD=$(grep -m1 -E '^gcc .*solve\.c' documentation/VERIFY.md 2>/dev/null)
  [ -n "$BUILD" ] || fail "no 'gcc ... solve.c' line in documentation/VERIFY.md -- the published build line is this gate's input"
  ( eval "${BUILD/-o solve/-o $WORK/solve}" ) >"$WORK/build.log" 2>&1 || fail "the published build line does not build: $(grep -E 'error:|undefined reference' "$WORK/build.log" | head -3)"
  SOLVE="$WORK/solve"
fi

# ---- the n=9 universe, exactly as scripts/tr12_repro.sh --n9 makes it ---------------------------
mkdir -p "$WORK/f" "$WORK/g" "$WORK/t"
"$SOLVE" --kc-build   "$WORK/f" --f1-pairs 9 >"$WORK/bf.log" 2>&1 || fail "--kc-build failed"
"$SOLVE" --kc-g-build "$WORK/g" --f1-pairs 9 >"$WORK/bg.log" 2>&1 || fail "--kc-g-build failed"
"$SOLVE" --kc-t-build "$WORK/f" "$WORK/t"    >"$WORK/bt.log" 2>&1 || fail "--kc-t-build failed"
"$SOLVE" --kc-scan "$WORK/f" "$WORK/g" "$WORK/atlas.json" --kc-tdir "$WORK/t" --kc-raw >"$WORK/scan.log" 2>&1 || fail "--kc-scan failed"
"$SOLVE" --kc-enum "$WORK/f" 2>/dev/null | grep -v '^\[' > "$WORK/walks.txt"
NW=$(grep -c . "$WORK/walks.txt"); [ "$NW" = 26112 ] || fail "n=9 enumeration gave $NW walks, expected 26112"
NT=$("$SOLVE" --kc-count "$WORK/f" 2>/dev/null | sed -n 's/^KC COUNT n=9 = \([0-9]*\)$/\1/p'); [ "$NT" = 26112 ] || fail "--kc-count gave '$NT', expected 26112"
ANCHOR=$("$SOLVE" --kc-o3-unrank "$WORK/f" "$WORK/g" $((NT / 2)) 2>/dev/null | grep -E '^[0-9]+(,[0-9]+)+$' | head -1)
[ -n "$ANCHOR" ] || fail "could not materialise the O3-midpoint anchor walk"
"$SOLVE" --kc-o3-rank "$WORK/f" "$WORK/g" "$ANCHOR" --kc-trace --kc-bracket > "$WORK/q3_profile.txt" 2>&1 || fail "--kc-o3-rank failed"

# ---- run the consumer of a given solve.py copy; prints its rc, transcript in $WORK/last.out ----
mkdir -p "$WORK/base"; cp "$SRC" "$WORK/base/solve.py"
consumer(){ # consumer <dir-with-solve.py> <keepdir> [extra args...] -> rc; stdout+stderr in $WORK/last.out
  local d="$1" keep="$2"; shift 2
  rm -rf "$keep"; mkdir -p "$keep"
  ( cd "$d" && python3 solve.py --atlas-selftest "$WORK/atlas.json" --atlas-walks "$WORK/walks.txt" \
      --atlas-q3-trace "$WORK/q3_profile.txt" --atlas-keep "$keep" "$@" ) > "$WORK/last.out" 2>&1
  echo $?
}
verdict(){ # verdict <dir> ; 0 iff every leg behaves; explains on stderr-of-gate otherwise
  local d="$1" rc nf np
  # leg 1
  rc=$(consumer "$d" "$WORK/keep1")
  [ "$rc" = 0 ] && grep -qx 'ATLAS_CONSUMER=PASS' "$WORK/last.out" || { echo "    leg 1 (plain) rc=$rc: $(grep -E '^ATLAS_CONSUMER=|Traceback|Error' "$WORK/last.out" | head -2 | tr '\n' ' ')"; return 1; }
  cmp -s "$WORK/last.out" "$WORK/gold_selftest.txt" || { echo "    leg 1 (plain): selftest transcript differs from the golden block in $GOLD"; diff "$WORK/gold_selftest.txt" "$WORK/last.out" | head -6 | sed 's/^/      /'; return 1; }
  # leg 3 (from leg 1's tables)
  local cell; cell=$(awk -F'\t' '$1==0 && $2==1 {print $4}' "$WORK/keep1/scan/v2_river.tsv" 2>/dev/null)
  [ "$cell" = "0.54411764705882353" ] || { echo "    leg 3: v2_river k=0 d=1 p='$cell', expected 0.54411764705882353 (14208/26112)"; return 1; }
  # leg 2
  rc=$(consumer "$d" "$WORK/keep2" --atlas-fault ratio-zero)
  [ "$rc" = 1 ] && grep -qx 'ATLAS_CONSUMER=FAIL' "$WORK/last.out" || { echo "    leg 2 (ratio-zero) rc=$rc: the consumer did not FAIL on zeroed ratios: $(grep -E '^ATLAS_CONSUMER=|error:' "$WORK/last.out" | head -1)"; return 1; }
  nf=$(grep -cE '^\[atlas-consumer\] .* FAIL( |$)' "$WORK/last.out"); np=$(grep -cE '^\[atlas-consumer\] .* PASS$' "$WORK/last.out")
  [ "$nf" = 5 ] && [ "$np" = 24 ] || { echo "    leg 2 (ratio-zero): $nf FAIL / $np PASS gate lines, expected exactly 5 / 24"; return 1; }
  grep -E '^\[atlas-consumer\] .* FAIL' "$WORK/last.out" | grep -qE 'V1 p == marginal/N' || { echo "    leg 2 (ratio-zero): the V1 p gate (the plotted column) did not fire"; return 1; }
  return 0
}

verdict "$WORK/base" || fail "baseline: the consumer under test does not behave on one of the three legs (see above)"

# ---- mutants: each is a sed rewrite of a COPY and MUST turn a leg red ---------------------------
mutant(){ # mutant <id> <sed-expr>
  local id="$1" expr="$2" m="$WORK/m_$1"
  mkdir -p "$m"; sed -e "$expr" "$WORK/base/solve.py" > "$m/solve.py"
  cmp -s "$m/solve.py" "$WORK/base/solve.py" && fail "mutant $id did not apply ($expr) -- anchors inside solve.py moved?"
  if verdict "$m" >/dev/null 2>&1; then fail "mutant $id SURVIVED ($expr) -- this gate cannot detect that regression"; fi
  echo "  [gate] mutant $id killed"
}
mutant M1_atlas_f_zero          's/^def _atlas_f(x):$/def _atlas_f(x):\n    return "0"/'
mutant M2_nine_digits           's/^            ctx.prec = _ATLAS_SIG$/            ctx.prec = 9/'
mutant M3_via_binary64          's/^        return format(d, ".%dg" % _ATLAS_SIG)$/        return "%.17g" % float(x)/'
mutant M4_v1_wrong_denominator  's/^            rows.append((k, k + 2, p, m, _atlas_f(_atlas_ratio(m, N)),$/            rows.append((k, k + 2, p, m, _atlas_f(_atlas_ratio(m, 2 * N)),/'
mutant M5_oracle_vacuous        's/^    sig = _ATLAS_SIG$/    return True\n    sig = _ATLAS_SIG/'
mutant M6_oracle_shape_only     's/^    mant, _, ex = text.replace("E", "e").partition("e")$/    return True\n    mant, _, ex = text.replace("E", "e").partition("e")/'
echo "  [gate] baseline PASS on 3 legs; 6/6 mutants killed"
echo "Q422_RATIO_COLUMNS_GATE=PASS"
