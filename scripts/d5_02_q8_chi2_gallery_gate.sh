#!/usr/bin/env bash
# d5_02_q8_chi2_gallery_gate.sh — the a1_q8_chi2 row must compute the pre-registered chi-square over
# the GALLERY ranks, exactly, at full-31 magnitude, and must be able to fail.
#
# WHY. Until 2026-09-05 row a1_q8_chi2 ran `--kc-midn 13 --kc-chi2-samples 20000`: the engine's own
# n=13 sampler self-test, on a universe it builds in-process. Its PASS attested nothing about the
# draws in q8_super.tsv, while TR-12 section Q8, QUERY_INVENTORY row Q8 and WAVE1_RUNBOOK W1-1 all
# promise "chi-square over 16 rank buckets of the gallery ranks" (D5-02, WRONG-OBJECT). The row now
# computes that statistic in awk+bc from the rank column of q8_super.tsv: bucket = floor(16*rank/N)
# in exact integer arithmetic, chi2 = (16*S - k^2)/k with S the sum of squared bucket counts, bar
# chi2 < 37.70 decided as 100*(16S - k^2) < 3770*k. The engine's self-test survives as its own
# separately named row (a1_q8_midn13 / TR12_Q8_MIDN13).
#
# WHAT IS PINNED. The row body is extracted VERBATIM from scripts/tr12_repro.sh (never re-typed
# here -- a copy would drift) and run on synthetic galleries at full-31 magnitude
# (N = 1097051278789181790036112071176579186688, TR-11):
#   leg 1  1000 ranks on a uniform grid                      -> PASS, exit 0, chi2_exact == the value an
#                                                               independent Python big-int recomputation gives
#   leg 2  500 x (N/16 - 1) and 500 x (N/16)                 -> bucket 0 = 500 AND bucket 1 = 500. A binary64
#                                                               bucketing puts all 1000 in bucket 1 (the 53-bit
#                                                               failure class of MQ1A finding 3)
#   leg 3  the 2026-08-07 full-31 bucket counts reproduced   -> chi2 printed as 20.224 (the launcher-side
#          [71,55,64,59,75,58,53,74,51,49,64,60,58,81,60,68]    figure was 20.22), PASS, exit 0
#   leg 4  all 1000 ranks in bucket 0                        -> FINDING, exit 1   (the gate can fail)
#   leg 5  a rank equal to N (not a member rank)             -> Q8_CHI2_FAIL, exit 1
#   leg 6  a gallery with no draw lines                      -> exit 1
#   leg 7  the committed n=9 gallery a1_q8_super.txt         -> stdout byte-identical to the committed
#                                                               n9/a1_q8_chi2.txt expected block
# plus five mutants of the extracted row, each of which must turn a leg red.
#
# KNOWN LIMITATION, stated rather than papered over. (i) Extraction anchors on the literal lines
# `row_begin a1_q8_chi2` ... `row_end TR12_Q8_CHI2 $rc`; a refactor of either makes this gate FAIL
# with "anchors moved", never pass blind. (ii) The full-31 gallery itself is not in the public tree;
# leg 3 reproduces the recorded BUCKET COUNTS, which pins the arithmetic, not the rank extraction on
# the real file (that was run once against the private 2026-08-07 output and recorded in
# roae-private FABLE_D5_02_03_04_08_2026_09_05.md). (iii) awk and bc are whatever is on PATH, as in
# tr12_repro.sh; bc's integer division is POSIX, awk is used only for counting.
#
# Verdict: prints exactly one D5_02_Q8_CHI2_GALLERY_GATE=<PASS|FAIL> line. Consume with grep -qx.
# D5_02_SRC overrides the source file -- ONLY so the closure check can point the gate at a file that
# lacks its target and confirm it reports FAIL.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "D5_02_Q8_CHI2_GALLERY_GATE=FAIL"; exit 40; }
SRC="${D5_02_SRC:-scripts/tr12_repro.sh}"
GOLD_GALLERY=scripts/tr12_expected/n9/a1_q8_super.txt
GOLD_CHI2=scripts/tr12_expected/n9/a1_q8_chi2.txt
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [gate] $*"; echo "D5_02_Q8_CHI2_GALLERY_GATE=FAIL"; exit 40; }
[ -f "$SRC" ] || fail "missing $SRC"
[ -f "$GOLD_GALLERY" ] && [ -f "$GOLD_CHI2" ] || fail "missing the n=9 golden gallery / chi2 block"
command -v bc >/dev/null 2>&1 || fail "bc is not on PATH (the row needs it)"

# Extract the row body. If the anchors are gone the gate ERRORS -- it never passes blind.
python3 - "$SRC" "$WORK/row.sh" <<'PY' || fail "could not extract the a1_q8_chi2 row from $SRC (anchors moved?)"
import sys
s=open(sys.argv[1],encoding='utf-8').read()
a=s.index('row_begin a1_q8_chi2\n')
b=s.index('row_end TR12_Q8_CHI2 $rc', a)
body=s[a:b]
if 'q8_super.tsv' not in body or '3770' not in body: raise SystemExit(3)
open(sys.argv[2],'w',encoding='utf-8').write(body)
PY

N=1097051278789181790036112071176579186688
mk(){ # mk <outfile> <row.sh>  -- wraps the row in stubs; $RAW is stdout so the transcript is checkable
  { echo '#!/usr/bin/env bash'; echo 'set -u'
    echo 'row_begin(){ :; }'
    echo 'WORK=$(mktemp -d); trap '"'"'rm -rf "$WORK"'"'"' EXIT; RAW="$WORK/raw.txt"; : > "$RAW"'
    echo 'ARTDIR="$1"; N_TOTAL="$2"; Q8K="$3"'
    cat "$2"; echo 'cat "$RAW"; exit $rc'; } > "$1"
}
# synthetic galleries: <out> <mode> [arg]
mkgal(){ python3 - "$@" <<'PY'
import sys
out,mode=sys.argv[1],sys.argv[2]
N=1097051278789181790036112071176579186688
ranks=[]
if mode=='grid':    ranks=[(i*N)//1000 for i in range(1000)]
elif mode=='edge':  ranks=[N//16-1]*500+[N//16]*500
elif mode=='t4':
    counts=[71,55,64,59,75,58,53,74,51,49,64,60,58,81,60,68]
    for b,c in enumerate(counts): ranks+= [ (b*N)//16 + j for j in range(c) ]
elif mode=='one':   ranks=[7]*1000
elif mode=='overN': ranks=[(i*N)//1000 for i in range(999)]+[N]
elif mode=='empty': ranks=[]
with open(out,'w') as f:
    f.write('[f1] header line the row must ignore\n')
    for r in ranks:
        f.write('%d\tcd=400\t1,2,3\n' % r)
        f.write('record\tm=1\t1,2,3\n')
    f.write('#provenance\tengine=solve.c/kc\n')
PY
}
# independent recomputation: Python big ints, the prereg formula, nothing shared with the row
expect_chi2(){ python3 - "$1" <<'PY'
import sys
N=1097051278789181790036112071176579186688
ranks=[int(l.split('\t')[0]) for l in open(sys.argv[1]) if l.split('\t')[0].isdigit() and '\tcd=' in l]
h=[0]*16
for r in ranks: h[(16*r)//N]+=1
k=len(ranks); S=sum(c*c for c in h)
print("%d/%d" % (16*S-k*k, k))
PY
}
for m in grid edge t4 one overN empty; do d="$WORK/g_$m"; mkdir -p "$d"; mkgal "$d/q8_super.tsv" "$m"; done
mkdir -p "$WORK/g_n9"; cp "$GOLD_GALLERY" "$WORK/g_n9/q8_super.tsv"

run(){ # run <harness> <galdir> <N> <k> -> rc; stdout in $WORK/last.out
  bash "$1" "$2" "$3" "$4" > "$WORK/last.out" 2>"$WORK/last.err"; echo $?
}
verdict(){ # verdict <harness>; 0 iff every leg behaves
  local h="$1" rc want
  rc=$(run "$h" "$WORK/g_grid" "$N" 1000); want=$(expect_chi2 "$WORK/g_grid/q8_super.tsv")
  [ "$rc" = 0 ] && grep -qx $'Q8_CHI2_GALLERY\tPASS' "$WORK/last.out" && grep -qx $'chi2_exact\t'"$want" "$WORK/last.out" \
    || { echo "    leg 1 (grid) rc=$rc or chi2_exact != $want"; return 1; }
  rc=$(run "$h" "$WORK/g_edge" "$N" 1000)
  grep -qx $'0\t500' "$WORK/last.out" && grep -qx $'1\t500' "$WORK/last.out" \
    || { echo "    leg 2 (bucket edge N/16-1 | N/16) rc=$rc: buckets 0/1 are not 500/500 -- inexact bucketing"; return 1; }
  rc=$(run "$h" "$WORK/g_t4" "$N" 1000)
  [ "$rc" = 0 ] && grep -qx $'chi2\t20.224' "$WORK/last.out" && grep -qx $'Q8_CHI2_GALLERY\tPASS' "$WORK/last.out" \
    || { echo "    leg 3 (2026-08-07 bucket counts) rc=$rc or chi2 != 20.224"; return 1; }
  rc=$(run "$h" "$WORK/g_one" "$N" 1000)
  [ "$rc" = 1 ] && grep -q '^Q8_CHI2_GALLERY.FINDING' "$WORK/last.out" \
    || { echo "    leg 4 (all in one bucket) rc=$rc: accepted a non-uniform gallery"; return 1; }
  rc=$(run "$h" "$WORK/g_overN" "$N" 1000)
  [ "$rc" = 1 ] && grep -q '^Q8_CHI2_FAIL' "$WORK/last.out" \
    || { echo "    leg 5 (rank == N) rc=$rc: accepted a rank outside [0,N)"; return 1; }
  rc=$(run "$h" "$WORK/g_empty" "$N" 1000)
  [ "$rc" = 1 ] || { echo "    leg 6 (empty gallery) rc=$rc"; return 1; }
  rc=$(run "$h" "$WORK/g_n9" 26112 200)
  [ "$rc" = 0 ] && cmp -s "$WORK/last.out" "$GOLD_CHI2" \
    || { echo "    leg 7 (n=9 golden) rc=$rc or transcript drifted from $GOLD_CHI2"; return 1; }
  return 0
}

mk "$WORK/base.sh" "$WORK/row.sh"
verdict "$WORK/base.sh" || fail "baseline: the committed row does not behave on one of the seven legs (see above)"

# Mutants. Each is a sed rewrite of the extracted row and MUST turn a leg red. A sed that does not
# change the row is itself a failure: it would be a mutant identical to the baseline.
mutant(){ # mutant <id> <sed-expr>
  local id="$1" expr="$2" m="$WORK/m_$1.row"
  sed -e "$expr" "$WORK/row.sh" > "$m"
  cmp -s "$m" "$WORK/row.sh" && fail "mutant $id did not apply ($expr) -- anchors inside the row moved?"
  mk "$WORK/m_$1.sh" "$m"
  if verdict "$WORK/m_$1.sh" >/dev/null 2>&1; then fail "mutant $id SURVIVED ($expr) -- this gate cannot detect that regression"; fi
  echo "  [gate] mutant $id killed"
}
# M1: bucket through a binary64 (awk) instead of bc -- the 53-bit class
mutant M1_double_bucketing 's#awk -v N="$N_TOTAL" .{print "(16\*" $1 ")/" N}. "$WORK/q8.ranks" | BC_LINE_LENGTH=0 bc#awk -v N="$N_TOTAL" '"'"'{print int(16*$1/N)}'"'"' "$WORK/q8.ranks"#'
# M2: a FINDING that exits 0
mutant M2_finding_exits_0 's/^  exit 1$/  exit 0/'
# M3: the bar moved from 37.70 to 37700
mutant M3_bar_moved 's/3770\*\$k/3770000*$k/'
# M4: the out-of-range check dropped
mutant M4_no_range_check 's/b<0 || b>15/b<0/'
# M5: 15 buckets in the numerator
mutant M5_wrong_numerator 's/16\*\$S - \$k\*\$k/15*$S - $k*$k/'
echo "  [gate] baseline PASS on 7 legs; 5/5 mutants killed"
echo "D5_02_Q8_CHI2_GALLERY_GATE=PASS"
