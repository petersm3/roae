#!/usr/bin/env bash
# d5_01_q1c_skip_gate.sh — the a2_q1c cost guard must fire, must be able to NOT fire, and must
#                          fail CLOSED when its producer says nothing.
#
# WHY. Before 2026-09-05 `tr12_repro.sh` ran a2_q1c unconditionally. At n>=31 rank_O3(KW)=0 by the
# labeling theorem, so the row's awk keep-test can never hold, m stays 0, and the row exits 1 with
# Q1C_FAIL -- taking TR12_REPRO=FAIL with it, AFTER the Q1CM-draw descent loop has burned 3-5 h.
#
# 🔴 WHAT CHANGED, 2026-09-10 (N3). The guard used to be `[ "$N_PAIRS" -ge 31 ]` and, above that
# threshold, emitted the HAND-TYPED token `SKIP:merged-into-Q4AC`. Both halves were wrong in the
# same way: n>=31 was a PROXY for the real condition, and the token was an absence claim no program
# had checked. The row now MEASURES the conditioning interval [0, rank_O3(anchor)) first --
# q1c_interval_measure, from --kc-o3-cert, --kc-o3-rank and the neighbour bracket -- and the draw
# loop runs only when that measurement comes back NONEMPTY. So this gate no longer pins a pair
# count; it pins the CONTRACT BETWEEN THE MEASUREMENT AND THE SPEND:
#     NONEMPTY -> the draw loop runs, token PASS
#     EMPTY    -> it does not, token EMPTY:interval-degenerate-at-n31
#     ERROR    -> it does not, and the token stays ERROR (a failure, not a pass)
#     silence  -> it does not, and the token is ERROR:producer-emitted-no-verdict
# The last line is the same third leg the old gate had and for the same reason: an unmeasured state
# must never become a free pass. Mutants M4/M5 exist to prove that leg is load-bearing.
#
# The file and token keep their D5-01 names because tr12_repro_gate.sh and DEVELOPMENT.md consume
# them; "skip" in the name is now historical -- the row does not skip, it reports a measured null.
#
# KNOWN LIMITATION, stated rather than papered over. Extraction anchors on the literal lines
# `row_begin a2_q1c` and `row_end_val TR12_Q1C $rc "$Q1C_VAL"`. A legitimate refactor of either
# makes this gate FAIL with "anchors moved", not with a diagnosis -- over-sensitive to edits and
# never under-sensitive. A FAIL here can mean "guard broken" OR "guard moved": read the message.
#
# Verdict: prints exactly one D5_01_Q1C_SKIP_GATE=<PASS|FAIL> line. Consume with grep -qx.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "D5_01_Q1C_SKIP_GATE=FAIL"; exit 40; }
SRC=scripts/tr12_repro.sh
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [gate] $*"; echo "D5_01_Q1C_SKIP_GATE=FAIL"; exit 40; }
[ -f "$SRC" ] || fail "missing $SRC"

# Extract the guard. If the anchors are gone the gate ERRORS -- it never passes blind.
python3 - "$SRC" "$WORK/guard.txt" <<'PY' || fail "could not extract the a2_q1c guard from $SRC (anchors moved?)"
import sys
s=open(sys.argv[1],encoding='utf-8').read()
a=s.index('row_begin a2_q1c\n')
b=s.index('row_end_val TR12_Q1C $rc "$Q1C_VAL"',a)+len('row_end_val TR12_Q1C $rc "$Q1C_VAL"')
open(sys.argv[2],'w',encoding='utf-8').write(s[a:b])
PY

MARK=$WORK/expensive_path_ran
mk(){ # mk <outfile> <verdict-the-producer-writes>  ; wraps the guard in stubs.
      # SOLVE is the expensive-path tripwire: nothing else in the guard invokes it, and it leaves
      # its mark in a FILE rather than on stderr -- the guard redirects the draw loop's stderr into
      # $RAW, so a stderr tripwire is swallowed and every case reads as "did not spend".
  { echo '#!/usr/bin/env bash'; echo 'set -uo pipefail'
    echo 'WORK=$(mktemp -d); ARTDIR=$WORK; RAW=$WORK/raw; : > "$RAW"'
    echo 'FDIR=; GDIR=; Q1CM=1; SEED=1; C3MAX=1'
    printf 'printf "#!/bin/sh\\necho ran >> %s\\nexit 1\\n" > "$WORK/solve"; chmod +x "$WORK/solve"; SOLVE=$WORK/solve\n' "$MARK"
    echo 'row_begin(){ :; }'
    echo 'row_end_val(){ echo "TOKEN $1=$3"; }'
    printf 'q1c_interval_measure(){ printf %s > "$3"; }\n' "'$2'"
    cat "$WORK/guard.txt"; } > "$1"
}

# probe FILE -> "<ran|noran> <token>"
probe(){ local f="$1" out
  rm -f "$MARK"; out=$(bash "$f" 2>/dev/null | sed -n 's/^TOKEN //p' | head -1)
  if [ -s "$MARK" ]; then printf 'ran %s' "$out"; else printf 'noran %s' "$out"; fi
}

verdict(){ # PASS iff all four contracts hold
  local a b c d
  mk "$WORK/g1.sh" 'TR12_Q1C=NONEMPTY:interval-cardinality-13056'; a=$(probe "$WORK/g1.sh")
  mk "$WORK/g2.sh" 'TR12_Q1C=EMPTY:interval-degenerate-at-n31';    b=$(probe "$WORK/g2.sh")
  mk "$WORK/g3.sh" 'TR12_Q1C=ERROR:sources-disagree';              c=$(probe "$WORK/g3.sh")
  mk "$WORK/g4.sh" '';                                             d=$(probe "$WORK/g4.sh")
  $VERBOSE && { echo "  [case] NONEMPTY -> $a"; echo "  [case] EMPTY    -> $b"
                echo "  [case] ERROR    -> $c"; echo "  [case] silence  -> $d"; }
  [ "$a" = "ran TR12_Q1C=PASS" ] \
  && [ "$b" = "noran TR12_Q1C=EMPTY:interval-degenerate-at-n31" ] \
  && [ "$c" = "noran TR12_Q1C=ERROR:sources-disagree" ] \
  && [ "$d" = "noran TR12_Q1C=ERROR:producer-emitted-no-verdict" ]
}

VERBOSE=true
verdict || fail "baseline: the measurement/spend contract does not hold (cases above)"
VERBOSE=false
echo "  [gate] baseline PASS on 4 contracts (NONEMPTY spends; EMPTY, ERROR and silence do not)"

# Mutants. Every one MUST be caught; a mutant that survives means the gate proves nothing.
BASE=$WORK/guard.txt
i=0
for m in \
  's#  NONEMPTY:\*)#  NONEMPTY:*|EMPTY:*)#' \
  's#  EMPTY:\*|ERROR:\*)#  EMPTY:*)#' \
  's#    Q1C_VAL="PASS" ;;#    : ;;#' \
  's#Q1C_VAL="ERROR:producer-emitted-no-verdict"#Q1C_VAL="PASS"#' \
  's#  \*)#  NEVERMATCHES:*)#' \
  ; do
  i=$((i+1)); cp "$BASE" "$WORK/keep.txt"
  sed "$m" "$WORK/keep.txt" > "$BASE"
  cmp -s "$WORK/keep.txt" "$BASE" && { cp "$WORK/keep.txt" "$BASE"; fail "mutant $i changed NOTHING ($m)"; }
  verdict && { cp "$WORK/keep.txt" "$BASE"; fail "mutant $i SURVIVED ($m) -- this gate cannot detect a broken guard"; }
  cp "$WORK/keep.txt" "$BASE"
done
verdict || fail "the guard was not restored after mutation -- this gate's own result is untrustworthy"
echo "  [gate] $i/$i mutants killed"
echo "D5_01_Q1C_SKIP_GATE=PASS"
