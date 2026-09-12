#!/usr/bin/env bash
# q3_reader_exactness_gate.sh — the a2_q3_reader awk row must decide its three integer identities
# EXACTLY at full-31 magnitude, and must be able to fail.
#
# WHY. Until 2026-09-05 the reader compared `p_den[i] != p_num[i-1]` (and `p_den[1] != N`,
# `g != p_num`, `g_parent != p_den`) on awk FIELDS, which awk compares NUMERICALLY through a
# binary64 whenever both look numeric. Above 2^53 that is a 53-bit equality. At full-31
# (N ~ 1.1e39) the second row's p_den and g_parent could be raised by 1, or by 1e20, and the row
# printed `reader_telescoping OK`, `... EXACT`, `READER_FAILS 0` and exited 0 -- while
# documentation/VERIFY.md called the row "three exact integer identities". Codex MQ1A finding 3
# (Astra, executed); adjudicated in roae-private CODEX_MQ1A_ADJUDICATION.md. The battery had only
# ever run at n=9 (N=26112 < 2^53), where the same comparison IS exact -- so the defect lived at
# exactly the size the row exists for and nowhere the row had been exercised.
#
# WHAT IS PINNED. The awk programme is extracted VERBATIM from scripts/tr12_repro.sh (never
# re-typed here -- a copy would drift) and run on synthetic profile TSVs at full-31 magnitude:
#   leg 1  a telescoping-valid 31-step control            -> exit 0, READER_FAILS 0
#   leg 2  p_den[2] and g_parent[2] +1                    -> exit 1  (Astra's case)
#   leg 3  p_den[2] and g_parent[2] +1e20                 -> exit 1  (Astra's case)
#   leg 4  g[1] = M+1 while p_num[1] = M (full magnitude) -> exit 1  (the (g,g_parent) leg)
#   leg 5  N passed as N+1                                -> exit 1  (the p_den[1] = N leg)
#   leg 6  p_den[2] = p_num[1] = "1.0970512787891818e+39" -> exit 1  (equal STRINGS that are not
#                                                            canonical integers: the guard leg)
#   leg 7  the committed n=9 golden profile               -> stdout byte-identical to
#                                                            scripts/tr12_expected/n9/a2_q3_reader.txt
#   leg 8  g(s_26) = 51 against the published 52          -> exit 1, and EXACTLY ONE READER_FAIL,
#                                                            naming g(s_26)  (V3A-041#3)
#   leg 9  the step column shifted by one                 -> exit 1: the anchors cannot be located,
#                                                            so they must not be read off row index
# plus seven mutants of the extracted programme, every one of which must turn a leg red.
#
# LEGS 8 AND 9 EXIST BECAUSE NOTHING ENFORCED THE THREE PRE-KNOWN V4 TAIL CELLS (V3A-041#3, Fable
# adjudication 2026-09-11). documentation/PREREG_CLASSA_QUERY_SET.md publishes g(s_22) = 690,176,
# g(s_24) = 5,624 and g(s_26) = 52 and says "a descent that disagrees with them is wrong"; measured
# at the tip, `git grep 690176` over scripts/ solve.py solve.c returned NOTHING. A full-31 descent
# carrying g(s_26) = 51 passed every token this program emits. The control traces below therefore
# CARRY the three anchors -- which is also the precondition for leg 8 to mean anything: leg 8's
# trace is telescoping-valid and canonical, and differs from the control in exactly one cell, so
# the single READER_FAIL it must produce can only have come from the anchor comparison.
# One EQUIVALENT mutant is recorded so nobody re-adds it: reverting only `g[k]=$9 ""; gp[k]=$10 ""`
# to bare fields changes nothing, because awk compares a string against a strnum AS STRINGS -- the
# fail-open needs BOTH operands numeric-looking. M4 therefore forces the g leg numeric with +0.
#
# KNOWN LIMITATION, stated rather than papered over. (i) Extraction anchors on the literal
# `awk -F'\t' -v N="$N_TOTAL" -v NP="$N_PAIRS" '` ... `}' "$ARTDIR/q3_profile_exact.tsv"` pair; a
# refactor of either line makes this gate FAIL with "anchors moved", never pass blind. (ii) The
# mutants are sed rewrites of the extracted programme; a mutant whose sed does not apply is
# reported as such and FAILS the gate (a mutant that silently equals the baseline proves nothing).
# (iii) This gate runs the awk in the PATH, as tr12_repro.sh does; it does not pin an awk
# implementation. MEASURED 2026-09-05: gawk 5.2.1, mawk and busybox awk all exhibit the original
# defect (leg 2 accepted at HEAD ecea4b6e) and all pass on the fixed row.
#
# Verdict: prints exactly one Q3_READER_EXACT_GATE=<PASS|FAIL> line. Consume with grep -qx.
# Q3RG_SRC overrides the source file -- ONLY so the closure check can point the gate at a file
# that lacks its target and confirm it reports FAIL.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "Q3_READER_EXACT_GATE=FAIL"; exit 40; }
SRC="${Q3RG_SRC:-scripts/tr12_repro.sh}"
GOLD_PROFILE=scripts/tr12_expected/n9/a2_q3_profile.txt
GOLD_READER=scripts/tr12_expected/n9/a2_q3_reader.txt
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [gate] $*"; echo "Q3_READER_EXACT_GATE=FAIL"; exit 40; }
[ -f "$SRC" ] || fail "missing $SRC"
[ -f "$GOLD_PROFILE" ] && [ -f "$GOLD_READER" ] || fail "missing the n=9 golden profile/reader block"

# Extract the awk programme. If the anchors are gone the gate ERRORS -- it never passes blind.
python3 - "$SRC" "$WORK/reader.awk" <<'PY' || fail "could not extract the a2_q3_reader awk programme from $SRC (anchors moved?)"
import sys
s=open(sys.argv[1],encoding='utf-8').read()
a0="awk -F'\\t' -v N=\"$N_TOTAL\" -v NP=\"$N_PAIRS\" '"
a1="}' \"$ARTDIR/q3_profile_exact.tsv\""
i=s.index(a0)+len(a0); j=s.index(a1,i)
prog=s[i:j]+'}'
if 'READER_FAILS' not in prog or 'reader_telescoping' not in prog: raise SystemExit(3)
open(sys.argv[2],'w',encoding='utf-8').write(prog)
PY

# Synthetic full-31 traces. Columns follow --kc-profile --kc-tsv:
#   step pair entry exit orient dclass alts f g g_parent p_num p_den bits g_alt_min g_alt_max choice_rank
# The g chain descends N -> M -> ... -> 1 and CARRIES THE THREE PUBLISHED TAIL ANCHORS at steps
# 22 / 24 / 26 (690176 / 5624 / 52), because the row now asserts them at NP == 31. Consecutive
# equal cells are legitimate -- the committed n=9 golden has g = 4,4 and 1,1 -- so the plateaus
# between anchors cost the control nothing. p_den[1] = N and p_den[i] = p_num[i-1] = g[i-1], so the
# product telescopes to g[31]/N = 1/N exactly and every (g,g_parent) equals (p_num,p_den).
N=1097051278789181790036112071176579186688       # |C1 n C2 n C4 n C5| at n=31 (TR-11)
mktrace(){ # mktrace <out> <delta_den2> <delta_g2> <den2_lit_or_empty> <num1_lit_or_empty> [g26] [step_offset]
  python3 - "$1" "$2" "$3" "$4" "$5" "$N" "${6:-52}" "${7:-0}" <<'PY'
import sys
out,dden,dg,den2lit,num1lit,N=sys.argv[1],int(sys.argv[2]),int(sys.argv[3]),sys.argv[4],sys.argv[5],int(sys.argv[6])
g26,stepoff=int(sys.argv[7]),int(sys.argv[8])
M=N//2
# The shell sizes, by step. 22/24/26 are the published anchors; g26 is a parameter so leg 8 can
# contradict ONE of them while leaving the telescoping chain intact (p_den[27] follows g[26]).
GA={}
for i in range(1,32):
    if   i <= 21: GA[i]=M
    elif i <= 23: GA[i]=690176
    elif i <= 25: GA[i]=5624
    elif i <= 30: GA[i]=g26
    else:         GA[i]=1
rows=[]
for i in range(1,32):
    g   = GA[i]
    den = N if i==1 else (GA[1]+dden if i==2 else GA[i-1])
    gg  = g+dg if i==1 else g          # dg lands on row 1, where g = M is above 2^53
    gp  = den
    pn  = num1lit if (i==1 and num1lit) else str(g)
    pd  = den2lit if (i==2 and den2lit) else str(den)
    if i==1 and num1lit: gg=num1lit      # keep (g,g_parent) == (p_num,p_den) as STRINGS, so
    if i==2 and den2lit: gp=den2lit      # only the canonical-form guard can reject this trace
    rows.append('\t'.join(map(str,[i+stepoff,i,2,16,0,1,1,1,gg,gp,pn,pd,0,1,1,1])))
open(out,'w').write('\n'.join(rows)+'\n')
PY
}
N1=$(python3 -c "print($N+1)")
mktrace "$WORK/t_ctrl.tsv"   0 0 "" ""
mktrace "$WORK/t_plus1.tsv"  1 0 "" ""
mktrace "$WORK/t_plus20.tsv" 100000000000000000000 0 "" ""
mktrace "$WORK/t_gbad.tsv"   0 1 "" ""
mktrace "$WORK/t_sci.tsv"    0 0 "1.0970512787891818e+39" "1.0970512787891818e+39"
# g(s_26) = 51 against the published 52: telescoping-valid, canonical, one cell wrong (V3A-041#3).
mktrace "$WORK/t_anch26.tsv" 0 0 "" "" 51
# The step column shifted by one: 31 rows, telescoping intact, but row 22 is step 23 -- the anchors
# are NOT at the row indices they name, so reading them off the index would compare the wrong cell.
mktrace "$WORK/t_stepoff.tsv" 0 0 "" "" 52 1

run(){ # run <prog> <trace> <N> <NP>  -> prints rc; stdout in $WORK/last.out
  awk -F'\t' -v "N=$3" -v "NP=$4" -f "$1" "$2" > "$WORK/last.out" 2>"$WORK/last.err"; echo $?
}
# 🔴 COUNT THE FAILURE LINES BY FIELD, NOT BY PREFIX (2026-09-11). Every leg below used to assert
# `grep -q '^READER_FAIL'`, which ALSO matches the summary line `READER_FAILS\t<n>` -- and that line
# is printed on EVERY run, including a clean one. So the grep half of legs 2-5 was vacuous: it was
# satisfied by output that contains no failure at all, and those legs rested entirely on rc. Found
# while adding leg 8, whose "exactly one failure" assertion counted the summary line as a second
# failure. The same shape as the defect this gate exists to pin: a check that cannot say no.
nfails(){ awk -F'\t' '$1=="READER_FAIL"' "$WORK/last.out" | wc -l; }
verdict(){ # verdict <prog> ; 0 iff every leg behaves
  local p="$1" rc
  rc=$(run "$p" "$WORK/t_ctrl.tsv"   "$N" 31); [ "$rc" = 0 ] && grep -qx $'READER_FAILS\t0' "$WORK/last.out" || { echo "    leg 1 (control) rc=$rc"; return 1; }
  rc=$(run "$p" "$WORK/t_plus1.tsv"  "$N" 31); [ "$rc" = 1 ] && [ "$(nfails)" -ge 1 ]                      || { echo "    leg 2 (+1) rc=$rc: accepted a broken identity"; return 1; }
  rc=$(run "$p" "$WORK/t_plus20.tsv" "$N" 31); [ "$rc" = 1 ] && [ "$(nfails)" -ge 1 ]                      || { echo "    leg 3 (+1e20) rc=$rc: accepted a broken identity"; return 1; }
  rc=$(run "$p" "$WORK/t_gbad.tsv"   "$N" 31); [ "$rc" = 1 ] && [ "$(nfails)" -ge 1 ]                      || { echo "    leg 4 (g off by one) rc=$rc"; return 1; }
  rc=$(run "$p" "$WORK/t_ctrl.tsv" "$N1" 31)         # N+1: a canonical integer one ulp-of-integers away
  [ "$rc" = 1 ] && [ "$(nfails)" -ge 1 ] || { echo "    leg 5 (N+1 passed as N) rc=$rc"; return 1; }
  rc=$(run "$p" "$WORK/t_sci.tsv"    "$N" 31); [ "$rc" = 1 ] && grep -q 'non-canonical' "$WORK/last.out"   || { echo "    leg 6 (non-canonical equal strings) rc=$rc"; return 1; }
  rc=$(run "$p" "$GOLD_PROFILE" 26112 9); [ "$rc" = 0 ] && cmp -s "$WORK/last.out" "$GOLD_READER"          || { echo "    leg 7 (n=9 golden) rc=$rc or transcript drifted from $GOLD_READER"; return 1; }
  # Leg 8. EXACTLY ONE READER_FAIL, naming g(s_26): the trace is telescoping-valid and canonical, so
  # a second failure would mean the fixture is broken rather than the anchor check firing, and this
  # gate would be passing for the wrong reason. Count, do not just grep.
  rc=$(run "$p" "$WORK/t_anch26.tsv" "$N" 31)
  [ "$rc" = 1 ] && [ "$(nfails)" = 1 ] && grep -q 'g(s_26)' "$WORK/last.out" \
    || { echo "    leg 8 (tail anchor g(s_26)=51) rc=$rc, READER_FAIL count $(nfails): a descent contradicting a PRE-KNOWN published cell was accepted, or it failed for some other reason"; return 1; }
  # Leg 9. The anchors must be LOCATED, not assumed to sit at row 22/24/26.
  rc=$(run "$p" "$WORK/t_stepoff.tsv" "$N" 31)
  [ "$rc" = 1 ] && [ "$(nfails)" -ge 1 ] \
    || { echo "    leg 9 (step column shifted by one) rc=$rc: the tail anchors were read off the ROW INDEX, not the step"; return 1; }
  # The control must actually CARRY the anchors, or legs 8 and 9 are testing an empty check. This
  # is the precondition, asserted rather than assumed: leg 1 already required rc 0 on t_ctrl, and
  # t_ctrl and t_anch26 differ in exactly the g(s_26) cells.
  cmp -s "$WORK/t_ctrl.tsv" "$WORK/t_anch26.tsv" && { echo "    precondition: t_anch26 is identical to the control -- the anchor fixture did not apply"; return 1; }
  grep -q '690176' "$WORK/t_ctrl.tsv" || { echo "    precondition: the control trace carries no g(s_22) anchor"; return 1; }
  return 0
}

verdict "$WORK/reader.awk" || fail "baseline: the committed reader does not behave on one of the nine legs (see above)"

# Mutants. Each is a sed rewrite of the extracted programme and MUST turn a leg red. A sed that
# does not change the programme is itself a failure: it would be a mutant identical to the baseline.
mutant(){ # mutant <id> <sed-expr>
  local id="$1" expr="$2" m="$WORK/m_$1.awk"
  sed -e "$expr" "$WORK/reader.awk" > "$m"
  cmp -s "$m" "$WORK/reader.awk" && fail "mutant $id did not apply ($expr) -- anchors inside the programme moved?"
  if verdict "$m" >/dev/null 2>&1; then fail "mutant $id SURVIVED ($expr) -- this gate cannot detect that regression"; fi
  echo "  [gate] mutant $id killed"
}
mutant M1_strnum_original_defect 's/pn\[k\]=\$11 ""; pd\[k\]=\$12 ""/pn[k]=$11; pd[k]=$12/'
mutant M2_no_canonical_guard     's/return (s ~ /return (1 || s ~ /'
mutant M3_exit_always_0          's/exit (fails?1:0)/exit 0/'
mutant M4_g_leg_numeric          's/if (g\[i\]!=pn\[i\] || gp\[i\]!=pd\[i\])/if (g[i]+0!=pn[i]+0 || gp[i]+0!=pd[i]+0)/'
mutant M5_N_compared_numeric     's/if (pd\[1\] != NS)/if (pd[1]+0 != NS+0)/'
# M6 and M7 are the V3A-041#3 pair: remove the tail-anchor block entirely (killed by legs 8 and 9),
# and remove only its step-alignment guard so the anchors are read off the row index (killed by
# leg 9 alone). Deleting the check is the regression that matters here -- the check did not exist
# at all until 2026-09-11, so "it was quietly dropped again" is the realistic future failure.
mutant M6_no_tail_anchor_block   's/if (NP+0 == 31) {/if (0) {/'
mutant M7_anchor_by_row_index    's/if (step\[si\] != si "")/if (0) {} else if (0)/'
echo "  [gate] baseline PASS on 9 legs; 7/7 mutants killed"
echo "Q3_READER_EXACT_GATE=PASS"
