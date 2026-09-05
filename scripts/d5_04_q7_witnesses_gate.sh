#!/usr/bin/env bash
# d5_04_q7_witnesses_gate.sh — the Q7 SAT-witness leg must be a NAMED skip, aggregated into TR12_Q7,
# so the parent token can never read PASS while the witnesses are uncommanded; and it must be able
# to fail.
#
# WHY. TR-12 section Q7 promised "the SAT witnesses are IN C15 ... they get ranks (post-O3) -- the
# only non-KW named sequences in this report with serial numbers", and QUERY_INVENTORY row Q7
# commands `python3 sat.py --witness moore-strict|grand-strict` before --check-arrangement. Until
# 2026-09-05 scripts/tr12_repro.sh never invoked sat.py: a2_q7_ranks iterated q7_kw.json and the
# three historical arrangements (all OUT), so at full-31 the "ranks of IN members" leg would have
# been rank_O3(KW)=0 alone while `agg TR12_Q7 TR12_Q7_KW TR12_Q7_HIST TR12_Q7_RANKS` read PASS
# (D5-04, WRONG-OBJECT). The witnesses need kissat (absent; QUERY_INVENTORY section 3.4). The row is
# now `row_skip a0_q7_witnesses TR12_Q7_WITNESSES PENDING:...`, and TR12_Q7_WITNESSES is a leg of
# TR12_Q7. WHAT IS NO LONGER CLAIMED: no non-KW sequence receives a serial number in the battery.
#
# WHAT IS PINNED. `tok_record`, `agg` and the a0_q7_witnesses block are extracted VERBATIM from
# scripts/tr12_repro.sh and run in a stub harness that plays the full-31 world where every other Q7
# leg PASSes:
#   leg 1  kissat absent from PATH   -> TOKSTATE[TR12_Q7_WITNESSES] = PENDING:kissat, TR12_Q7 = SKIP:*
#   leg 2  a stub kissat on PATH     -> TOKSTATE[TR12_Q7_WITNESSES] = PENDING:*   (still not PASS: the
#                                       row is unbuilt even with the solver), TR12_Q7 = SKIP:*
#   leg 3  the live `agg TR12_Q7 ...` line names TR12_Q7_WITNESSES
#   leg 4  no line of the source records TR12_Q7_WITNESSES as PASS
# plus four mutants, each of which must be caught: the pre-fix aggregation line (witnesses not a
# leg), the row recording PASS, the aggregator ignoring SKIP/PENDING legs, and the row deleted
# (an UNREACHED leg is not the same as a NAMED skip).
#
# KNOWN LIMITATION, stated rather than papered over. Extraction anchors on the literal
# `tok_record(){`, `agg(){`, `if command -v kissat` ... `fi` and `agg TR12_Q7 ` lines; a refactor makes
# this gate FAIL with "anchors moved", never pass blind. The gate does not run sat.py: it pins that
# the battery does not CLAIM the witness leg, not that the leg could be built.
#
# Verdict: prints exactly one D5_04_Q7_WITNESSES_GATE=<PASS|FAIL> line. Consume with grep -qx.
# D5_04_SRC overrides the source file -- ONLY so the closure check can point the gate at a file that
# lacks its target and confirm it reports FAIL.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "D5_04_Q7_WITNESSES_GATE=FAIL"; exit 40; }
SRC="${D5_04_SRC:-scripts/tr12_repro.sh}"
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [gate] $*"; echo "D5_04_Q7_WITNESSES_GATE=FAIL"; exit 40; }
[ -f "$SRC" ] || fail "missing $SRC"

extract(){ # extract <src> <out>  -- tok_record, agg, the witnesses block, the agg line
python3 - "$1" "$2" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
def block(start, end_marker):
    a=s.index(start); b=s.index(end_marker, a)+len(end_marker); return s[a:b]
tok=block('tok_record(){', '\n}\n')
agg=block('agg(){', '\n}\n')
a=s.index('if command -v kissat >/dev/null 2>&1; then'); b=s.index('\nfi\n', a)+4
wit=s[a:b]
if 'a0_q7_witnesses' not in wit or 'TR12_Q7_WITNESSES' not in wit: raise SystemExit(3)
line=[l for l in s.splitlines() if l.startswith('agg TR12_Q7 ')]
if len(line)!=1: raise SystemExit(4)
open(sys.argv[2],'w',encoding='utf-8').write(tok+'\n'+agg+'\n'+'WITNESS_BLOCK_START\n'+wit+'WITNESS_BLOCK_END\n'+line[0].split('#')[0].rstrip()+'\n')
PY
}
extract "$SRC" "$WORK/parts.sh" || fail "could not extract tok_record/agg/a0_q7_witnesses/agg-line from $SRC (anchors moved?)"

# leg 3 / leg 4 on the source text
grep -E '^agg TR12_Q7 ' "$SRC" | grep -q 'TR12_Q7_WITNESSES' || fail "leg 3: the agg TR12_Q7 line does not name TR12_Q7_WITNESSES"
if grep -E 'TR12_Q7_WITNESSES' "$SRC" | grep -vE '^\s*#' | grep -q '"PASS"'; then fail "leg 4: a line records TR12_Q7_WITNESSES as PASS"; fi

mk(){ # mk <outfile> <parts.sh>  -- a harness that plays the full-31 world with every other Q7 leg PASS
  python3 - "$1" "$2" <<'PY'
import sys
out,parts=sys.argv[1],sys.argv[2]
p=open(parts).read()
a=p.index('WITNESS_BLOCK_START\n')+len('WITNESS_BLOCK_START\n'); b=p.index('WITNESS_BLOCK_END\n')
funcs=p[:p.index('WITNESS_BLOCK_START\n')]; wit=p[a:b]; aggline=p[b+len('WITNESS_BLOCK_END\n'):]
h='''#!/usr/bin/env bash
set -u
declare -A TOKSTATE=() TOKROWS=() TOKREASON=()
declare -a TOKORDER=() SKIPPED=() FAILED=()
NROWS=0; NPASS=0; NFAIL=0; NSKIP=0; LOG=/dev/null
'''+funcs+'''
row_skip(){ NROWS=$((NROWS+1)); NSKIP=$((NSKIP+1)); SKIPPED+=("$1|$2|$3|$4"); TOKREASON[$2]="$4"; tok_record "$2" "$3" "$1"; }
tok_record TR12_Q7_KW PASS a0_q7_kw
tok_record TR12_Q7_HIST PASS a0_q7_hist
'''+wit+'''
tok_record TR12_Q7_RANKS PASS a2_q7_ranks
'''+aggline+'''
echo "WITNESSES=${TOKSTATE[TR12_Q7_WITNESSES]:-MISSING}"
echo "Q7=${TOKSTATE[TR12_Q7]:-MISSING}"
'''
open(out,'w').write(h)
PY
}
mkdir -p "$WORK/nokissat" "$WORK/withkissat"
printf '#!/bin/sh\nexit 0\n' > "$WORK/withkissat/kissat"; chmod +x "$WORK/withkissat/kissat"
verdict(){ # verdict <harness>; 0 iff both PATH worlds behave
  local h="$1" w q
  w=$(PATH="$WORK/nokissat:/usr/bin:/bin" bash "$h" 2>/dev/null | sed -n 's/^WITNESSES=//p')
  q=$(PATH="$WORK/nokissat:/usr/bin:/bin" bash "$h" 2>/dev/null | sed -n 's/^Q7=//p')
  [ "$w" = "PENDING:kissat" ] && [[ "$q" == SKIP:* ]] || { echo "    leg 1 (no kissat): WITNESSES=$w Q7=$q"; return 1; }
  w=$(PATH="$WORK/withkissat:/usr/bin:/bin" bash "$h" 2>/dev/null | sed -n 's/^WITNESSES=//p')
  q=$(PATH="$WORK/withkissat:/usr/bin:/bin" bash "$h" 2>/dev/null | sed -n 's/^Q7=//p')
  [[ "$w" == PENDING:* ]] && [[ "$q" == SKIP:* ]] || { echo "    leg 2 (stub kissat): WITNESSES=$w Q7=$q"; return 1; }
  return 0
}
mk "$WORK/base.sh" "$WORK/parts.sh"
verdict "$WORK/base.sh" || fail "baseline: the witness leg does not keep TR12_Q7 off PASS (see above)"

# Mutants of the extracted parts. Each MUST be caught.
mutant(){ # mutant <id> <sed-expr>
  local id="$1" expr="$2" m="$WORK/m_$1.parts"
  sed -e "$expr" "$WORK/parts.sh" > "$m"
  cmp -s "$m" "$WORK/parts.sh" && fail "mutant $id did not apply ($expr) -- anchors inside the parts moved?"
  mk "$WORK/m_$1.sh" "$m"
  if verdict "$WORK/m_$1.sh" >/dev/null 2>&1; then fail "mutant $id SURVIVED ($expr) -- this gate cannot detect that regression"; fi
  echo "  [gate] mutant $id killed"
}
mutant M1_prefix_agg_line       's/^agg TR12_Q7 .*/agg TR12_Q7 TR12_Q7_KW TR12_Q7_HIST TR12_Q7_RANKS/'
mutant M2_row_records_PASS      's/"PENDING:kissat"/"PASS"/; s/"PENDING:q7-witness-row"/"PASS"/'
mutant M3_agg_ignores_skips     's/SKIP\*|PENDING\*) \[ "\${st#FAIL}" = "\$st" \] && st="SKIP:leg-\$c" ;;/SKIP*|PENDING*) : ;;/'
mutant M4_row_deleted           '/^WITNESS_BLOCK_START$/,/^WITNESS_BLOCK_END$/{/^WITNESS_BLOCK_/!d}'
echo "  [gate] baseline PASS on 4 legs; 4/4 mutants killed"
echo "D5_04_Q7_WITNESSES_GATE=PASS"
