#!/usr/bin/env bash
# d5_01_q1c_skip_gate.sh — the a2_q1c full-31 skip guard must fire, and must be able to NOT fire.
#
# WHY. Before 2026-09-05 `tr12_repro.sh` ran a2_q1c unconditionally. At n>=31 rank_O3(KW)=0 by the
# labeling theorem, so the row's awk keep-test can never hold, m stays 0, and the row exits 1 with
# Q1C_FAIL -- taking TR12_REPRO=FAIL with it, AFTER the Q1CM-draw descent loop has burned 3-5 h.
# The row was already ruled SKIP:merged-into-Q4AC by Q-394 section 2; the ruling was never landed.
#
# THE THIRD LEG IS THE POINT. A guard keyed on N_PAIRS must not turn an UNSET N_PAIRS into a free
# skip -- that would be the fail-open class this project keeps finding. Mutant M3 below exists to
# prove that leg is load-bearing and not decorative.
#
# KNOWN LIMITATION, stated rather than papered over. Extraction anchors on the LITERAL guard line
# `if [ "${N_PAIRS:-0}" -ge 31 ]; then`. A legitimate refactor of that line makes this gate FAIL with
# "anchors moved", not with a threshold diagnosis -- it is over-sensitive to edits and never
# under-sensitive to them. That direction is deliberate (a gate that cannot find its target must
# ERROR, never pass), but it means a FAIL here can mean "guard broken" OR "guard moved": read the
# message, do not assume the former.
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
a=s.index('if [ "${N_PAIRS:-0}" -ge 31 ]; then')
b=s.index('\nfi', s.index('row_end TR12_Q1C $rc'))+3
open(sys.argv[2],'w',encoding='utf-8').write(s[a:b])
PY

mk(){ # mk <outfile> ; wraps the guard in stubs. row_begin is the expensive-path tripwire.
  { echo '#!/usr/bin/env bash'; echo 'set -uo pipefail'
    echo 'row_skip(){ echo "SKIP $2=$3"; }'
    echo 'row_begin(){ echo "RAN_EXPENSIVE_PATH"; }'
    echo 'row_end(){ echo "END $1=$2"; }'
    echo 'SOLVE=/bin/false; FDIR=; GDIR=; ANCHOR=; Q1CM=1; SEED=1; C3MAX=1'
    echo 'WORK=$(mktemp -d); RAW=$WORK/raw; ARTDIR=$WORK; : > "$RAW"'
    cat "$WORK/guard.txt"; } > "$1"
}
verdict(){ # PASS iff n=31 skips, n=9 runs, and UNSET runs
  local f="$1" a b c
  a=$(N_PAIRS=31 bash "$f" 2>/dev/null | head -1)
  b=$(N_PAIRS=9  bash "$f" 2>/dev/null | head -1)
  c=$(bash "$f" 2>/dev/null | head -1)
  [[ "$a" == SKIP* && "$b" == RAN_EXPENSIVE_PATH && "$c" == RAN_EXPENSIVE_PATH ]]
}

mk "$WORK/base.sh"
verdict "$WORK/base.sh" || fail "baseline: guard does not skip at n=31, or does not run at n=9/unset"

# Mutants. Every one MUST be caught; a mutant that survives means the gate proves nothing.
i=0
for m in 's/-ge 31/-ge 999/' 's/-ge 31/-lt 31/' 's/\${N_PAIRS:-0}/\${N_PAIRS:-99}/' 's/-ge 31/-ge 9/'; do
  i=$((i+1)); sed "$m" "$WORK/base.sh" > "$WORK/m$i.sh"
  verdict "$WORK/m$i.sh" && fail "mutant $i SURVIVED ($m) -- this gate cannot detect a broken guard"
done
echo "  [gate] baseline PASS; $i/$i mutants killed"
echo "D5_01_Q1C_SKIP_GATE=PASS"
