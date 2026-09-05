#!/usr/bin/env bash
# d5_08_q6_q10a_shell_gate.sh — the c_q6 and c_q10a shell legs must implement the 2026-09-04 (Q-394)
# specifications exactly, at full-31 magnitude, and must be able to fail.
#
# WHY. Q-394 (2026-09-04) re-specified two Group-C rows and landed a consumer patch for one of them;
# the battery's own awk/bc legs -- the second implementation the consumer is meant to be checked
# against -- were left on the pre-ruling spec (D5-08, sibling residue):
#   c_q6   emitted anchor_mass_below / anchor_percentile from the --kc-trace mass_below column, which
#          is an O3 rank-block contribution (n=9 k=1: 2720 beside a g_parent of 2368) and is
#          identically 0 for KW at full-31; not a percentile under any reading. Now: anchor_d,
#          anchor_class_mass = m_k(d_k), anchor_p = m_k(d_k)/N and
#          anchor_class_pct = sum_{d: m_k(d) <= m_k(d_k)} m_k(d)/N, from the atlas by_class masses
#          and the anchor's dclass column in --kc-profile --kc-tsv (step k+1 <-> layer k).
#   c_q10a printed N/24 once per layer as an "orbit census" (the atlas gate forces flow == N). Now:
#          N/24 stated once, the per-layer mod-24 gate, and the per-layer state census by
#          G-orbit-size class + branching histogram TRANSCRIBED from the f-ladder sidecars
#          f1c5_layer_stats_XX.json; the KW-orbit-rank leg is dropped; a missing or unparseable
#          sidecar fails the row, and the last sidecar's mass_total must equal N.
#
# WHAT IS PINNED. `ratio9` and both row bodies are extracted VERBATIM from scripts/tr12_repro.sh
# and run in a stub harness on synthetic inputs of the exact byte shapes the rows read:
#   c_q6   leg 1  n=31-shaped atlas with 192-bit class masses; anchor classes chosen to include a
#                 TIE (m_k(d_anchor) == m_k(other)) and rows where orient != dclass
#                 -> anchor_p / anchor_class_pct equal an independent Python Fraction recomputation,
#                    half-up to 9 places; exit 0
#          leg 2  the committed n=9 fixture: atlas rebuilt from n9/c_q6.txt's class columns, profile
#                 = n9/a2_q3_profile.txt -> stdout byte-identical to n9/c_q6.txt
#          leg 3  an anchor class outside {1,2,3,4,6} -> Q6_FAIL, exit 1
#          leg 4  no profile TSV -> anchor columns NA, exit 0 (the reduced table is still the row)
#   c_q10a leg 1  31 layers, 32 sidecars in the v2 byte layout -> census equals an independent
#                 json-module transcription; 32 census rows; N_div_24 stated exactly once; exit 0
#          leg 2  one layer flow not divisible by 24 -> Q10A_LAYER_MOD24_FAILS 1, exit 1
#          leg 3  sidecar k=17 deleted -> "17<TAB>MISSING-SIDECAR", Q10A_SIDECARS_MISSING 1, exit 1
#          leg 4  last sidecar mass_total != N -> Q10A_LAST_LAYER_MASS_EQ_N NO, exit 1
# plus four mutants per row, each of which must turn a leg red.
#
# KNOWN LIMITATION, stated rather than papered over. (i) Extraction anchors on the literal lines
# `ratio9(){`, `row_begin c_q6` ... `row_end TR12_Q6 $rc`, `row_begin c_q10a` ... `row_end TR12_Q10A
# $rc`; a refactor makes this gate FAIL with "anchors moved", never pass blind. (ii) The sidecar byte
# layout is the v2 writer's as measured on the n=9 f sidecars and the full-31 g sidecars
# (roae-private, 2026-08-11); the full-31 f sidecars are archived and were not re-read here.
# (iii) The consumer half (solve.py atlas_emit_q6) is not exercised by this gate; the shell/consumer
# agreement is a full-31 comparison (the consumer emits -1 below n=31).
#
# Verdict: prints exactly one D5_08_Q6_Q10A_SHELL_GATE=<PASS|FAIL> line. Consume with grep -qx.
# D5_08_SRC overrides the source file -- ONLY so the closure check can point the gate at a file that
# lacks its target and confirm it reports FAIL.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "D5_08_Q6_Q10A_SHELL_GATE=FAIL"; exit 40; }
SRC="${D5_08_SRC:-scripts/tr12_repro.sh}"
GOLD_Q6=scripts/tr12_expected/n9/c_q6.txt
GOLD_PROFILE=scripts/tr12_expected/n9/a2_q3_profile.txt
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [gate] $*"; echo "D5_08_Q6_Q10A_SHELL_GATE=FAIL"; exit 40; }
[ -f "$SRC" ] || fail "missing $SRC"
[ -f "$GOLD_Q6" ] && [ -f "$GOLD_PROFILE" ] || fail "missing the n=9 golden c_q6 / a2_q3_profile blocks"
command -v bc >/dev/null 2>&1 || fail "bc is not on PATH (the rows need it)"

python3 - "$SRC" "$WORK/ratio9.sh" "$WORK/q6.row" "$WORK/q10a.row" <<'PY' || fail "could not extract ratio9 / c_q6 / c_q10a from $SRC (anchors moved?)"
import sys
s=open(sys.argv[1],encoding='utf-8').read()
a=s.index('ratio9(){'); b=s.index('\n}\n',a)+3
r9=s[a:b]
a=s.index('    row_begin c_q6\n'); b=s.index('row_end TR12_Q6 $rc',a)
q6=s[a:b]
a=s.index('    row_begin c_q10a\n'); b=s.index('row_end TR12_Q10A $rc',a)
q10=s[a:b]
if 'anchor_class_pct' not in q6 or 'f1c5_layer_stats' not in q10: raise SystemExit(3)
open(sys.argv[2],'w').write(r9); open(sys.argv[3],'w').write(q6); open(sys.argv[4],'w').write(q10)
PY

N=1097051278789181790036112071176579186688
mk(){ # mk <out> <row> ; harness: $1=ATLAS $2=FDIR $3=ARTDIR $4=N_PAIRS $5=N_TOTAL
  { echo '#!/usr/bin/env bash'; echo 'set -u'; echo 'row_begin(){ :; }'
    echo 'WORK=$(mktemp -d); trap '"'"'rm -rf "$WORK"'"'"' EXIT; RAW="$WORK/raw.txt"; : > "$RAW"'
    echo 'ATLAS="$1"; FDIR="$2"; ARTDIR="$3"; N_PAIRS="$4"; N_TOTAL="$5"; N_DIV24=$(echo "$N_TOTAL / 24" | bc)'
    cat "$WORK/ratio9.sh" "$2"; echo 'cat "$RAW"; exit $rc'; } > "$1"
}
run(){ bash "$1" "$2" "$3" "$4" "$5" "$6" > "$WORK/last.out" 2>"$WORK/last.err"; echo $?; }

# ---------------------------------------------------------------- synthetic worlds (Python builds them
# and computes the EXPECTED transcripts independently: Fraction arithmetic and the json module)
python3 - "$WORK" "$GOLD_Q6" "$GOLD_PROFILE" <<'PY'
import sys, os, json
from fractions import Fraction
W,goldq6,goldprof=sys.argv[1],sys.argv[2],sys.argv[3]
N=1097051278789181790036112071176579186688
def r9(n,d):
    r=(2*n*10**9+d)//(2*d)
    return "0" if r==0 else "%d.%09d" % divmod(r,10**9)
def atlas_line(k,flow,by):
    return '    {"k": %d, "flow": "%d", "by_class": {%s}, "marginal_quotient": {"q0": "1"}, "marginal_raw": {"pair1": "1"}}' % (
        k, flow, ", ".join('"d%d": "%d"' % (d,by[d]) for d in (1,2,3,4,6)))
def write_atlas(path, layers):
    with open(path,'w') as f:
        f.write('{\n  "type": "roae-kc-scan-atlas",\n  "n": %d,\n  "N_total": "%d",\n  "layers": [\n' % (len(layers),N))
        f.write(',\n'.join(atlas_line(k,fl,by) for k,fl,by in layers)+'\n  ],\n  "gates": {"fails": 0}\n}\n')
def write_profile(path, rows):  # rows: (step, orient, dclass)
    with open(path,'w') as f:
        f.write('order=NATIVE-WALK-PATH\tobject=WALK\n')
        f.write('step\tpair\tentry\texit\torient\tdclass\talts\tf\tg\tg_parent\tp_num\tp_den\tbits\tg_alt_min\tg_alt_max\tchoice_rank\n')
        for s,o,d in rows:
            f.write('\t'.join(map(str,[s,s,1,2,o,d,1,1,1,1,1,1,0,1,1,1]))+'\n')
# ---- c_q6 leg 1: 31 layers, 192-bit masses, ties and orient != dclass
os.makedirs(W+'/q6L1/art',exist_ok=True)
layers=[]; prof=[]; expect=[]
for k in range(31):
    base=(N//7)*(k+1) % N
    d1=(N*3)//10 + k; d2=(N*2)//10 - k; d4=(N*1)//10; d3=N-d1-d2-d4-(N//50); d6=N//50
    if k%5==0: d3=d4                      # a TIE between class 3 and class 4
    d6=N-d1-d2-d3-d4                      # closes the layer to N exactly
    by={1:d1,2:d2,3:d3,4:d4,6:d6}
    ad=[4,1,2,3,6][k%5]                   # the anchor's class at layer k; class 4 at the tie layers
    orient=1-(k%2)                        # orient column deliberately != dclass
    layers.append((k,N,by)); prof.append((k+1,orient,ad))
    am=by[ad]; le=sum(v for v in by.values() if v<=am)
    expect.append('%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%s' % (k,N,d1,d2,d3,d4,d6,ad,am,r9(am,N),r9(le,N)))
write_atlas(W+'/q6L1/atlas.json',layers); write_profile(W+'/q6L1/art/q3_profile_exact.tsv',prof)
open(W+'/q6L1/expect.tsv','w').write('\n'.join(expect)+'\n')
# ---- c_q6 leg 2: the committed n=9 fixture, atlas rebuilt from the golden's own class columns
os.makedirs(W+'/q6L2/art',exist_ok=True)
layers=[]
for l in open(goldq6):
    p=l.rstrip('\n').split('\t')
    if p[0].isdigit(): layers.append((int(p[0]),int(p[1]),{1:int(p[2]),2:int(p[3]),3:int(p[4]),4:int(p[5]),6:int(p[6])}))
with open(W+'/q6L2/atlas.json','w') as f:
    f.write('{\n  "layers": [\n'+',\n'.join(atlas_line(k,fl,by) for k,fl,by in layers)+'\n  ]\n}\n')
open(W+'/q6L2/art/q3_profile_exact.tsv','w').write(''.join(l for l in open(goldprof) if l.split('\t')[0].isdigit() or l.startswith('step\t')))
# ---- c_q6 leg 3: an anchor class of 5
os.makedirs(W+'/q6L3/art',exist_ok=True)
write_atlas(W+'/q6L3/atlas.json',[(0,N,{1:N,2:0,3:0,4:0,6:0})]); write_profile(W+'/q6L3/art/q3_profile_exact.tsv',[(1,0,5)])
# ---- c_q6 leg 4: no profile
os.makedirs(W+'/q6L4/art',exist_ok=True)
write_atlas(W+'/q6L4/atlas.json',[(0,N,{1:N,2:0,3:0,4:0,6:0})])
# ---- c_q10a worlds: 31 layers, 32 sidecars in the v2 byte layout
def sidecar(path,k,nm,ne,mt,census,hist):
    with open(path,'w') as f:
        f.write('{\n  "sidecar": "f1c5_layer_stats_v2",\n  "kind": "f",\n  "layer_file": "f1c5_layer_%02d.bin",\n  "n": 31,\n  "k": %d,\n' % (k,k))
        f.write('  "n_masks": %d,\n  "n_empty_masks": 0,\n  "n_entries": %d,\n  "bin_bytes": 1,\n' % (nm,ne))
        f.write('  "mass_total": "%d",\n  "frame": "canonical-quotient(orbit-unweighted;G-equivariant)",\n' % mt)
        f.write('  "headroom": {"peak_value_bits": 1, "guard_bits": 192, "headroom_bits": 191},\n')
        f.write('  "branching": {"min": 0, "max": 9, "mean": 1.5, "hist": %s},\n' % json.dumps(hist,separators=(',',':')))
        f.write('  "top_heavy": [{"mask": 7, "last": 1, "rid": 7, "value": "8"}],\n')
        f.write('  "orbit_size_census": %s\n}\n' % json.dumps(census,separators=(',',':')))
def q10_world(name, badflow=False, drop=None, badlast=False):
    d=W+'/'+name; os.makedirs(d+'/f',exist_ok=True); os.makedirs(d+'/art',exist_ok=True)
    layers=[(k, N+1 if (badflow and k==3) else N, {1:N,2:0,3:0,4:0,6:0}) for k in range(31)]
    write_atlas(d+'/atlas.json',layers)
    exp=[]
    for k in range(32):
        nm=k*3+1; ne=k*7+2; mt=(N if k==31 else (7**k) % N); census=[[1,k+1,k+2],[3,2*k,5*k+1]]; hist=[[0,k],[2,3*k+1]]
        if badlast and k==31: mt=N-1
        if drop==k: continue
        sidecar('%s/f/f1c5_layer_stats_%02d.json' % (d,k),k,nm,ne,mt,census,hist)
        exp.append('%d\t%d\t%d\t%d\t%s\t%s' % (k,nm,ne,mt,json.dumps(census,separators=(',',':')),json.dumps(hist,separators=(',',':'))))
    open(d+'/expect.tsv','w').write('\n'.join(exp)+'\n')
q10_world('q10L1'); q10_world('q10L2',badflow=True); q10_world('q10L3',drop=17); q10_world('q10L4',badlast=True)
PY

verdict_q6(){ # verdict_q6 <harness>
  local h="$1" rc
  rc=$(run "$h" "$WORK/q6L1/atlas.json" /nonexistent "$WORK/q6L1/art" 31 "$N")
  [ "$rc" = 0 ] && grep -E '^[0-9]+	' "$WORK/last.out" | cmp -s - "$WORK/q6L1/expect.tsv" \
    || { echo "    c_q6 leg 1 (full-31 magnitude, ties, orient!=dclass) rc=$rc or values differ from the Fraction recomputation"; return 1; }
  rc=$(run "$h" "$WORK/q6L2/atlas.json" /nonexistent "$WORK/q6L2/art" 9 26112)
  [ "$rc" = 0 ] && cmp -s "$WORK/last.out" "$GOLD_Q6" \
    || { echo "    c_q6 leg 2 (n=9 golden) rc=$rc or transcript drifted from $GOLD_Q6"; return 1; }
  rc=$(run "$h" "$WORK/q6L3/atlas.json" /nonexistent "$WORK/q6L3/art" 1 "$N")
  [ "$rc" = 1 ] && grep -q '^Q6_FAIL' "$WORK/last.out" || { echo "    c_q6 leg 3 (class 5) rc=$rc: accepted a class outside {1,2,3,4,6}"; return 1; }
  rc=$(run "$h" "$WORK/q6L4/atlas.json" /nonexistent "$WORK/q6L4/art" 1 "$N")
  [ "$rc" = 0 ] && grep -qE '^0	[0-9]+	.*	NA	NA	NA	NA$' "$WORK/last.out" || { echo "    c_q6 leg 4 (no profile) rc=$rc or anchor columns not NA"; return 1; }
  return 0
}
verdict_q10(){ # verdict_q10 <harness>
  local h="$1" rc
  rc=$(run "$h" "$WORK/q10L1/atlas.json" "$WORK/q10L1/f" "$WORK/q10L1/art" 31 "$N")
  [ "$rc" = 0 ] && grep -E '^[0-9]+	[0-9]+	[0-9]+	[0-9]+	\[' "$WORK/last.out" | cmp -s - "$WORK/q10L1/expect.tsv" \
    && [ "$(grep -c '^N_div_24	' "$WORK/last.out")" = 1 ] && grep -qx $'Q10A_LAYER_MOD24_FAILS\t0' "$WORK/last.out" \
    || { echo "    c_q10a leg 1 (32 sidecars, v2 layout) rc=$rc or the transcription differs from the json-module reading"; return 1; }
  rc=$(run "$h" "$WORK/q10L2/atlas.json" "$WORK/q10L2/f" "$WORK/q10L2/art" 31 "$N")
  [ "$rc" = 1 ] && grep -qx $'Q10A_LAYER_MOD24_FAILS\t1' "$WORK/last.out" || { echo "    c_q10a leg 2 (flow not divisible by 24) rc=$rc"; return 1; }
  rc=$(run "$h" "$WORK/q10L3/atlas.json" "$WORK/q10L3/f" "$WORK/q10L3/art" 31 "$N")
  [ "$rc" = 1 ] && grep -qx $'17\tMISSING-SIDECAR' "$WORK/last.out" && grep -qx $'Q10A_SIDECARS_MISSING\t1' "$WORK/last.out" \
    || { echo "    c_q10a leg 3 (sidecar 17 missing) rc=$rc: a transcription silently skipped a layer"; return 1; }
  rc=$(run "$h" "$WORK/q10L4/atlas.json" "$WORK/q10L4/f" "$WORK/q10L4/art" 31 "$N")
  [ "$rc" = 1 ] && grep -q '^Q10A_LAST_LAYER_MASS_EQ_N	NO' "$WORK/last.out" || { echo "    c_q10a leg 4 (last mass_total != N) rc=$rc"; return 1; }
  return 0
}

mk "$WORK/q6.sh" "$WORK/q6.row";   verdict_q6 "$WORK/q6.sh"   || fail "baseline c_q6: the committed row does not behave on one of its four legs (see above)"
mk "$WORK/q10.sh" "$WORK/q10a.row"; verdict_q10 "$WORK/q10.sh" || fail "baseline c_q10a: the committed row does not behave on one of its four legs (see above)"

mutant(){ # mutant <q6|q10> <id> <sed-expr>
  local which="$1" id="$2" expr="$3" src m
  [ "$which" = q6 ] && src="$WORK/q6.row" || src="$WORK/q10a.row"
  m="$WORK/m_${which}_$id.row"; sed -e "$expr" "$src" > "$m"
  cmp -s "$m" "$src" && fail "mutant $which/$id did not apply ($expr) -- anchors inside the row moved?"
  mk "$WORK/m_${which}_$id.sh" "$m"
  if [ "$which" = q6 ]; then verdict_q6 "$WORK/m_${which}_$id.sh" >/dev/null 2>&1 && fail "mutant $which/$id SURVIVED ($expr)"
  else verdict_q10 "$WORK/m_${which}_$id.sh" >/dev/null 2>&1 && fail "mutant $which/$id SURVIVED ($expr)"; fi
  echo "  [gate] mutant $which/$id killed"
}
mutant q6  M1_strict_less_excludes_own_class 's/"\$m <= \$am"/"$m < $am"/'
mutant q6  M2_orient_column_read_as_class     's/print \$1-1 "\\t" \$6/print $1-1 "\\t" $5/'
mutant q6  M3_layer_offset                    's/print \$1-1 "\\t" \$6/print $1 "\\t" $6/'
mutant q6  M4_prefix_columns                  's/anchor_d\\tanchor_class_mass\\tanchor_p\\tanchor_class_pct/anchor_mass_below\\tanchor_percentile/'
mutant q10 M1_missing_sidecar_not_fatal       's/exit \$(( (fails || miss) ? 1 : 0 ))/exit $(( fails ? 1 : 0 ))/'
mutant q10 M2_last_layer_dropped              's/-le "\$N_PAIRS"/-lt "$N_PAIRS"/'
mutant q10 M3_mod24_gate_disabled             's/\[ "\$m" = "0" \] || fails=1/:/'
mutant q10 M4_last_mass_check_disabled        's/\[ "\$last_mt" = "\$N_TOTAL" \]/[ -n "$last_mt" ]/'
echo "  [gate] baseline PASS on 4+4 legs; 8/8 mutants killed"
echo "D5_08_Q6_Q10A_SHELL_GATE=PASS"
