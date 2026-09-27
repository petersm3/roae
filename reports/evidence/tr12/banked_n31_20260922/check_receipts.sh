#!/usr/bin/env bash
# check_receipts.sh — re-derive, from the bytes in this directory and the public tree only (no ladder,
# no compiled binary), every number the n=31 receipts in this directory publish that CAN be re-derived
# without the f/g ladders. Everything else in these receipts is attested, not reproduced; README.md
# says which is which. (Q-857, 2026-09-27.)
#
# Usage (from the repository root):
#   bash reports/evidence/tr12/banked_n31_20260922/check_receipts.sh
#   bash reports/evidence/tr12/banked_n31_20260922/check_receipts.sh --emit-c-q10a OUT   # write the re-derived c_q10a transcript
# Q3_N9=<file> points the Q3 reader check at another --kc-alts transcript (default: the committed n=9 golden,
# the small-n control that shows the same checks pass on a universe anyone can rebuild).
#
# Output: KEY=value lines; the last line is CHECK_RECEIPTS=PASS or CHECK_RECEIPTS=FAIL. Consume with grep -qx.
set -uo pipefail
cd "$(dirname "$0")/../../../.." || { echo "CHECK_RECEIPTS=FAIL"; exit 2; }
B=reports/evidence/tr12/banked_n31_20260922
R=runs/20260906_kc_ladders_n31
EMIT=""; [ "${1:-}" = "--emit-c-q10a" ] && EMIT="${2:?--emit-c-q10a needs a path}"
Q3_N9="${Q3_N9:-scripts/tr12_expected/n9/a2_q3_profile.txt}"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
bad=0

# ---- 1. Python checks over the committed receipts (uses solve.py's public constraint helpers)
python3 - "$B" "$Q3_N9" <<'PY' | tee "$W/py.out"
import sys, re, math
sys.path.insert(0, '.')
import solve
B, q3n9 = sys.argv[1], sys.argv[2]
N = 1097051278789181790036112071176579186688
ok = True
def emit(k, v):
    print('%s=%s' % (k, v))
def c3(walk):                      # the receipts print the 62 hexagrams after the fixed (63, 0) start
    return solve.total_complement_distance_c3([63, 0] + walk)
def superspace(seq):               # C1 + C4 (start 63,0) + C5 (transition multiset; implies C2), no C3 bound
    return (sorted(seq) == list(range(64))
            and all(seq[2*i+1] == solve._tg_partner(seq[2*i]) for i in range(32))
            and seq[:2] == [63, 0]
            and solve._tg_multiset(solve._tg_transitions(seq)) == {1: 2, 2: 20, 3: 13, 4: 19, 6: 9})
def walk(s): return [int(x) for x in s.split(',')]
kw = solve._r7_kw()
emit('KW_CONTROL_C3', solve.total_complement_distance_c3(kw))
if solve.total_complement_distance_c3(kw) != 776 or kw[:2] != [63, 0]: ok = False

# -- Q2 (a2_q2.txt): the three O3 probes; the O3-greatest walk's C3 settles O3-LAST^C15
q2 = open(B + '/a2_q2.txt').read()
blocks = re.split(r'^### ', q2, flags=re.M)[1:]
probes = {}
for b in blocks:
    r = int(re.match(r'O3 unrank r=(\d+)', b).group(1))
    w = walk(re.search(r'^order=O3\tobject=WALK.*\n([0-9,]+)$', b, flags=re.M).group(1))
    probes[r] = (w, 'CERTIFICATE PASS' in b)
ok &= sorted(probes) == [0, N // 2, N - 1] and all(p[1] for p in probes.values())
emit('Q2_PROBES_CERT_PASS', '3' if all(p[1] for p in probes.values()) else 'NO')
emit('Q2_R0_EQ_KW', 'YES' if probes[0][0] == kw[2:] else 'NO'); ok &= probes[0][0] == kw[2:]
wl, wm = probes[N - 1][0], probes[N // 2][0]
emit('Q2_LAST_IN_SUPER', 'YES' if superspace([63, 0] + wl) else 'NO'); ok &= superspace([63, 0] + wl)
emit('Q2_LAST_C3', c3(wl)); emit('Q2_MID_C3', c3(wm))
emit('O3_LAST_C15_IS_UNRANK_O3_N_MINUS_1', 'YES' if c3(wl) <= 776 else 'NO')
ok &= c3(wl) == 688 and c3(wm) == 904

# -- Q2b (a1_q2b.txt): the REL-greatest walk's C3
q2b = open(B + '/a1_q2b.txt').read()
rel = [walk(l) for l in q2b.splitlines() if re.fullmatch(r'[0-9]+(,[0-9]+){61}', l)]
emit('Q2B_PLAIN_WALKS', len(rel))
ok &= len(rel) == 3
relN = re.search(r'^### .*r=%d\b.*\n(?:.*\n)*?([0-9]+(?:,[0-9]+){61})$' % (N - 1), q2b, flags=re.M)
if relN:
    emit('Q2B_REL_LAST_C3', c3(walk(relN.group(1))))
    ok &= c3(walk(relN.group(1))) == 1568
else:
    emit('Q2B_REL_LAST_C3', 'UNPARSED'); ok = False

# -- Q3 (a2_q3_profile.txt): the #alt rows are complete and consistent with the table
def q3_check(path, tag):
    global ok
    txt = open(path).read().splitlines()
    alts = [dict(kv.split('=', 1) for kv in l.split('\t')[1:]) for l in txt if l.startswith('#alt\t')]
    hdr = next(l for l in txt if l.startswith('step\t')).split('\t')
    rows = [dict(zip(hdr, l.split('\t'))) for l in txt if re.match(r'[0-9]+\t', l)]
    good = len(alts) == sum(int(r['alts']) for r in rows)
    for r in rows:
        a = [x for x in alts if x['step'] == r['step']]
        gs = [int(x['g']) for x in a]
        ch = [x for x in a if x['rank'] == r['choice_rank']]
        good &= (len(a) == int(r['alts']) and sum(gs) == int(r['g_parent'])      # flow: children sum to parent
                 and min(gs) == int(r['g_alt_min']) and max(gs) == int(r['g_alt_max'])
                 and len(ch) == 1 and int(ch[0]['g']) == int(r['g'])
                 and (ch[0]['entry'], ch[0]['exit']) == (r['entry'], r['exit']))
    emit('Q3_%s_ALT_ROWS' % tag, len(alts)); emit('Q3_%s_STEPS' % tag, len(rows))
    emit('Q3_%s_ALTS_CONSISTENT' % tag, 'YES' if good and rows else 'NO')
    ok &= bool(good and rows)
    return len(alts)
ok &= q3_check(B + '/a2_q3_profile.txt', 'N31') == 880
q3_check(q3n9, 'N9')
tsv = [l for l in open(B + '/q3_profile_exact.tsv').read().splitlines() if re.match(r'[0-9]+\t', l)]
tr = [l for l in open(B + '/a2_q3_profile.txt').read().splitlines() if re.match(r'[0-9]+\t', l)]
emit('Q3_TSV_EQ_TRANSCRIPT_TABLE', 'YES' if tsv == tr and len(tsv) == 31 else 'NO'); ok &= tsv == tr

# -- Q4 (a1_q4ac.txt): p_hat and every per-bin Wilson interval re-derive from the counts
def wilson(k, n, z=1.959964):     # the row's own awk: z = 1.959964, clamped to [0, 1]
    p = k / n; d = 1 + z*z/n; c = (p + z*z/(2*n)) / d; h = z*math.sqrt(p*(1-p)/n + z*z/(4*n*n)) / d
    return max(c - h, 0.0), min(c + h, 1.0)
q4 = open(B + '/a1_q4ac.txt').read().splitlines()
kv = dict(l.split('\t')[:2] for l in q4 if '\t' in l and not re.match(r'[0-9]', l))
M = int(kv['realised_M']); T = 387
bins3 = [tuple(map(int, l.split('\t')[:2])) for l in q4 if re.match(r'[0-9]+\t[0-9]+\t[0-9.]+$', l)]
bins4 = [l.split('\t') for l in q4 if re.match(r'[0-9]+\t[0-9]+\t[0-9.]+\t[0-9.]+$', l)]
acc = sum(c for cd, c in bins3 if cd <= T)
lo, hi = wilson(acc, M)
emit('Q4_DRAWS', sum(c for _, c in bins3)); emit('Q4_ACCEPTED', acc)
emit('Q4_P_HAT', '%.8f' % (acc / M)); emit('Q4_WILSON', '%.8f,%.8f' % (lo, hi))
q4ok = (sum(c for _, c in bins3) == M and acc == int(kv['c15_accepted_draws'])
        and '%.8f' % (acc / M) == kv['p_hat_cd_le_T']
        and '%.8f' % lo == kv['wilson95_lo'] and '%.8f' % hi == kv['wilson95_hi'])
nb = 0
for cd, c, l, h in bins4:
    wl_, wh_ = wilson(int(c), M); nb += 1
    q4ok &= ('%.8f' % wl_, '%.8f' % wh_) == (l, h) and (int(cd), int(c)) in bins3
mu = [c for cd, c in bins3 if cd == T][0] if any(cd == T for cd, _ in bins3) else 0
wl2, wh2 = wilson(mu, acc)
q4ok &= ('%.8f' % (mu / acc), '%.8f' % wl2, '%.8f' % wh2) == (kv['mu_hat_P_C15_cd_eq_T'], kv['mu_wilson95_lo'], kv['mu_wilson95_hi'])
emit('Q4_PER_BIN_WILSON_ROWS', nb); emit('Q4_MU_WALK', '%.8f' % (mu / acc))
emit('Q4_REDERIVED', 'MATCH' if q4ok else 'DIFFER'); ok &= q4ok

# -- Q8 (a1_q8_*.txt): membership of every published walk, the chi-square, the subset count
def gallery(path):
    out = []
    for l in open(path).read().splitlines():
        m = re.fullmatch(r'([0-9]+)\tcd=([0-9]+)\t([0-9,]+)', l)
        if m: out.append((int(m.group(1)), int(m.group(2)), walk(m.group(3))))
    return out
sup, c15 = gallery(B + '/a1_q8_super.txt'), gallery(B + '/a1_q8_c15.txt')
sup_ok = all(superspace([63, 0] + w) and c3(w) == 2 * (cd + 1) and 0 <= r < N for r, cd, w in sup)
c15_ok = all(solve._tg_valid_c15([63, 0] + w) and c3(w) == 2 * (cd + 1) and cd <= T for r, cd, w in c15)
emit('Q8_SUPER_WALKS', len(sup)); emit('Q8_SUPER_MEMBERS_OK', 'YES' if sup_ok else 'NO')
emit('Q8_C15_WALKS', len(c15)); emit('Q8_C15_MEMBERS_OK', 'YES' if c15_ok else 'NO')
cnt = [0] * 16
for r, _, _ in sup: cnt[16 * r // N] += 1
chi2 = sum((c - 62.5) ** 2 for c in cnt) / 62.5
sub = sum(1 for _, cd, _ in sup if cd <= T)
emit('Q8_CHI2', '%.3f' % chi2); emit('Q8_SUPER_SUBSET_CD_LE_T', sub)
chi = open(B + '/a1_q8_chi2.txt').read(); subt = open(B + '/a1_q8_subset.txt').read()
q8ok = (sup_ok and c15_ok and len(sup) == 1000 and len(c15) == 1000
        and '\nchi2\t%.3f\n' % chi2 in chi
        and all('\n%d\t%d\n' % (i, c) in chi for i, c in enumerate(cnt))
        and '\nq8_super_subset_cd_le_T\t%d\n' % sub in subt)
emit('Q8_REDERIVED', 'MATCH' if q8ok else 'DIFFER'); ok &= q8ok
print('PY_CHECKS=%s' % ('PASS' if ok else 'FAIL'))
PY
grep -qx 'PY_CHECKS=PASS' "$W/py.out" || bad=1

# ---- 2. c_q10a: run the battery's own row, cut verbatim from scripts/tr12_repro.sh, on the published
#         sidecars and the published atlas. With TDIR empty it must give the 2026-09-22 as-run receipt
#         byte for byte (the positive control: same inputs, same code path as the run); with TDIR = the
#         t sidecars it must give c_q10a.txt.
python3 - scripts/tr12_repro.sh "$W/q10a.row" <<'PY' || { echo "C_Q10A_EXTRACT=FAIL"; bad=1; }
import sys
s = open(sys.argv[1], encoding='utf-8').read()
a = s.index('    row_begin c_q10a\n'); b = s.index('row_end TR12_Q10A $rc', a)
open(sys.argv[2], 'w').write(s[a:b])
PY
{ echo '#!/usr/bin/env bash'; echo 'set -u'; echo 'row_begin(){ :; }'
  echo 'WK=$(mktemp -d); trap '"'"'rm -rf "$WK"'"'"' EXIT; RAW="$WK/raw.txt"; : > "$RAW"'
  echo 'ATLAS="$1"; FDIR="$2"; TDIR="$3"; ARTDIR="$WK"; N_PAIRS=31; N_TOTAL=1097051278789181790036112071176579186688; N_DIV24=$(echo "$N_TOTAL / 24" | bc)'
  cat "$W/q10a.row"; echo 'cat "$RAW"; exit $rc'; } > "$W/q10a.sh"
bash "$W/q10a.sh" "$R/atlas_n31.json" "$R/sidecars/run_f" "" > "$W/asrun.txt"; rc1=$?
bash "$W/q10a.sh" "$R/atlas_n31.json" "$R/sidecars/run_f" "$R/sidecars/run_t" > "$W/new.txt"; rc2=$?
if cmp -s "$W/asrun.txt" "$B/c_q10a_20260922_asrun.txt" && [ "$rc1" = 0 ]; then echo "C_Q10A_ASRUN_REPRODUCED=YES"; else echo "C_Q10A_ASRUN_REPRODUCED=NO"; bad=1; fi
[ -n "$EMIT" ] && cp "$W/new.txt" "$EMIT"
if [ -f "$B/c_q10a.txt" ] && cmp -s "$W/new.txt" "$B/c_q10a.txt" && [ "$rc2" = 0 ]; then echo "C_Q10A_REPRODUCED=YES"; else echo "C_Q10A_REPRODUCED=NO"; bad=1; fi
echo "C_Q10A_NA_CELLS=$(grep -c 'NA:schema-v1-sidecar' "$W/new.txt")"
[ "$bad" = 0 ] && echo "CHECK_RECEIPTS=PASS" || echo "CHECK_RECEIPTS=FAIL"
exit "$bad"
