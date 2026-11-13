#!/usr/bin/env bash
# atlas_followups.sh -- the TR-12 section 12.7 follow-up queries (8, 1b, 7, 9) against retained f and g ladders.
#
# This is the script that produced reports/evidence/tr12/atlas_followups_n31_20260925/ (run 2026-09-25
# and again 2026-10-26 on a second copy of the n=31 ladders; the published files of the two runs are
# byte-identical). Its query section is unchanged from those runs; the header, the defaults and
# the closing summary step are what differ (the README beside the evidence lists them).
#
# WHAT IT NEEDS. The f and g ladders of one --kc-build / --kc-g-build pair and the atlas a
# --kc-scan of them produced. At n=31 the two ladders are 11.57 TB and are not distributed with this
# repository (runs/20260906_kc_ladders_n31/README.md); without them, check the committed outputs with
#   E=reports/evidence/tr12/atlas_followups_n31_20260925; python3 $E/atlas_followups.py summary $E --expect $E/EXPECTED_TOKENS.txt
# which needs no ladder. A small-n end-to-end run takes minutes: build n=9 ladders and an n=9 atlas
# (commands in the README beside the evidence) and point FDIR/GDIR/ATLAS/Q8_IN/Q1B_IN at them.
#
# Order: Q8 (11 profiles, serial) -> Q1b (1,000 profiles, PARALLEL) -> Q7 (dead census, streaming)
#        -> Q9 (witness walks). Each query owns one output directory under $OUT and prints ONE
#        whole-line verdict token: ATLAS_Q8= ATLAS_Q1B= ATLAS_Q7= ATLAS_Q9= (ANSWERED | FAIL:<reason>).
# The completion marker $OUT/ATLAS_QUERIES_COMPLETE is written LAST and only when all four answered.
# Idempotent: a query whose token file already reads ANSWERED is skipped on re-run; Q1b resumes
# per walk. Nothing is ever written under FDIR or GDIR (checked: a post-run scan for files newer
# than the run's start marker under each ladder dir FAILS the run).
#
# Every solve invocation is read-only on the ladders (kc_open / kc_open_as). The binary is built
# from $SRC here, and its --selftest sha, --kc-profile-selftest, --kc-dead-census-selftest and
# --kc-witness-walks-selftest must all pass before any ladder is touched.
#
# Env:
#   FDIR GDIR  the ladders                                          (REQUIRED)
#   SRC        repository checkout                                  (default: the checkout this script is in)
#   OUT        output root                                          (default: $HOME/atlas_queries_out)
#   ATLAS      the atlas the ladders produced                       (default: $SRC/runs/20260906_kc_ladders_n31/atlas_n31.json)
#   Q8_IN Q1B_IN   walk lists, label<TAB>e,x,...                    (default: built into $OUT/inputs by atlas_followups.py inputs)
#   Q1B_PAR    parallel --kc-profile processes for Q1b              (default: 6; capped by MemAvailable / 3.5 GiB)
#   Q7_LAYERS  half-open layer range for the census                 (default: "24 31" at n=31; "0 N" otherwise)
#   Q7_LOCAL_LAYERS  layers for the g-free cross-check              (default: "27 31" at n=31; "N-4 N" otherwise)
#   CACHE_MB_PAR / CACHE_MB_ONE   block cache per profile process / per single big process (256 / 4096)
#
# At n != 31 the King-Wen-vs-atlas cross-check and the --check-arrangement legs do not apply and say
# so. Developed with AI assistance (Claude Fable 5.1, 2026-09-24; public form Claude Fable 5.2,
# 2026-11-13). Corrections welcome.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SRC:-$(cd "$HERE/.." && pwd)}"
AFPY="$HERE/../reports/evidence/tr12/atlas_followups_n31_20260925/atlas_followups.py"   # inputs + summary; reads no ladder
OUT="${OUT:-$HOME/atlas_queries_out}"
if [ -z "${FDIR:-}" ] || [ -z "${GDIR:-}" ]; then
  echo "ATLAS_QUERIES=FAIL:usage (set FDIR and GDIR to the f and g ladder directories; see the header of this script)"; exit 2
fi
ATLAS="${ATLAS:-$SRC/runs/20260906_kc_ladders_n31/atlas_n31.json}"
if [ -z "${Q8_IN:-}" ] || [ -z "${Q1B_IN:-}" ]; then   # the n=31 walk lists, rebuilt from the public tree and sha-pinned
  mkdir -p "$OUT/inputs" || { echo "ATLAS_QUERIES=FAIL:cannot_mkdir_out"; exit 2; }
  python3 "$AFPY" inputs "$OUT/inputs" > "$OUT/inputs/inputs.log" 2>&1 \
    && grep -qx 'AF_INPUTS=PASS' "$OUT/inputs/inputs.log" || { echo "ATLAS_QUERIES=FAIL:inputs (see $OUT/inputs/inputs.log)"; exit 2; }
  Q8_IN="${Q8_IN:-$OUT/inputs/q8_walks.tsv}"; Q1B_IN="${Q1B_IN:-$OUT/inputs/q1b_walks.tsv}"
fi
Q1B_PAR="${Q1B_PAR:-6}"
CACHE_MB_PAR="${CACHE_MB_PAR:-256}"
CACHE_MB_ONE="${CACHE_MB_ONE:-4096}"
EXPECTED_SELFTEST_SHA="403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e"

mkdir -p "$OUT" || { echo "ATLAS_QUERIES=FAIL:cannot_mkdir_out"; exit 2; }
LOG="$OUT/run.log"
exec > >(tee -a "$LOG") 2>&1
echo "== atlas_followups.sh start $(date -u +%FT%TZ) SRC=$SRC OUT=$OUT FDIR=$FDIR GDIR=$GDIR ATLAS=$ATLAS"
echo "== source: commit=$(git -C "$SRC" rev-parse HEAD 2>/dev/null || echo unknown) tree_dirty=$(git -C "$SRC" status --porcelain -- solve.c 2>/dev/null | grep -c . || true) solve_c_sha256=$(sha256sum "$SRC/solve.c" 2>/dev/null | cut -d' ' -f1)"
START_MARK="$OUT/.start_mark"; touch "$START_MARK"

verdict() {  # verdict TOKEN VALUE -> prints the whole-line token and records it
  printf '%s=%s\n' "$1" "$2" | tee "$OUT/$1.token"
}
answered() { [ -r "$OUT/$1.token" ] && grep -qx "$1=ANSWERED" "$OUT/$1.token"; }
secs() { date +%s; }
timing() { echo "#timing	$1	seconds=$2	$(date -u +%FT%TZ)" | tee -a "$OUT/timing.tsv"; }

# ---------------------------------------------------------------- preflight: binary + gates
for f in "$SRC/solve.c" "$ATLAS" "$Q8_IN" "$Q1B_IN"; do
  [ -r "$f" ] || { verdict ATLAS_QUERIES "FAIL:missing_input:$f"; exit 2; }
done
for d in "$FDIR" "$GDIR"; do
  [ -d "$d" ] || { verdict ATLAS_QUERIES "FAIL:missing_ladder:$d"; exit 2; }
done
BIN="$OUT/solve"
if [ ! -x "$BIN" ] || [ "$SRC/solve.c" -nt "$BIN" ]; then
  echo "== building $BIN from $SRC/solve.c"
  ( cd "$SRC" && gcc -O3 -pthread -fopenmp -o "$BIN" solve.c -lm -lz ) 2>"$OUT/build.err" \
    || { verdict ATLAS_QUERIES "FAIL:build"; exit 2; }
fi
export SOLVE_KC_SCRATCH="$OUT/scratch"; mkdir -p "$SOLVE_KC_SCRATCH"
if [ ! -r "$OUT/preflight.ok" ]; then
  t0=$(secs)
  "$BIN" --selftest > "$OUT/selftest.log" 2>&1
  grep -q "Actual sha256:   $EXPECTED_SELFTEST_SHA" "$OUT/selftest.log" && grep -q "PASS" "$OUT/selftest.log" \
    || { verdict ATLAS_QUERIES "FAIL:selftest_sha"; exit 2; }
  "$BIN" --kc-profile-selftest > "$OUT/kc_profile_selftest.log" 2>&1
  grep -qx "KC_PROFILE_SELFTEST=PASS" "$OUT/kc_profile_selftest.log" || { verdict ATLAS_QUERIES "FAIL:kc_profile_selftest"; exit 2; }
  "$BIN" --kc-dead-census-selftest > "$OUT/kc_dead_census_selftest.log" 2>&1
  grep -qx "KC_DEAD_CENSUS_SELFTEST=PASS" "$OUT/kc_dead_census_selftest.log" || { verdict ATLAS_QUERIES "FAIL:kc_dead_census_selftest"; exit 2; }
  "$BIN" --kc-witness-walks-selftest > "$OUT/kc_witness_walks_selftest.log" 2>&1
  grep -qx "KC_WITNESS_WALKS_SELFTEST=PASS" "$OUT/kc_witness_walks_selftest.log" || { verdict ATLAS_QUERIES "FAIL:kc_witness_walks_selftest"; exit 2; }
  timing preflight $(( $(secs) - t0 ))
  touch "$OUT/preflight.ok"
fi
N=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['n'])" "$ATLAS") || { verdict ATLAS_QUERIES "FAIL:atlas_unreadable"; exit 2; }
echo "== atlas n=$N"
if [ "$N" = 31 ]; then
  Q7_LAYERS="${Q7_LAYERS:-24 31}"; Q7_LOCAL_LAYERS="${Q7_LOCAL_LAYERS:-27 31}"
else
  Q7_LAYERS="${Q7_LAYERS:-0 $N}"; Q7_LOCAL_LAYERS="${Q7_LOCAL_LAYERS:-$((N-4)) $N}"
fi

# one profile: label, walk, outdir -> writes outdir/label.tsv (+ .ok) ; rc 0 iff KC_PROFILE=OK
profile_one() {
  local label="$1" walk="$2" dir="$3" cache="$4"
  [ -r "$dir/$label.ok" ] && return 0
  "$BIN" --kc-profile "$FDIR" "$GDIR" "$walk" --kc-tsv "$dir/$label.tsv" --kc-cache-mb "$cache" > "$dir/$label.log" 2>&1
  if grep -qx "KC_PROFILE=OK" "$dir/$label.log" && grep -qx "KC_PROFILE=OK" "$dir/$label.tsv"; then
    touch "$dir/$label.ok"; return 0
  fi
  return 1
}
export -f profile_one; export BIN FDIR GDIR

# per-step transition mass w_k = f(s_{k-1}) * g(s_k) from a profile, compared with the atlas:
# exact 3-bin vs the reference walk's kw_w (lt/eq/gt) and an OCTAVE-resolution mass percentile
# within the step's distance class from the hist table. Emits one summary row per profile.
summarise_profiles() {  # summarise_profiles DIR OUT.tsv [check_kw_label]
  python3 - "$ATLAS" "$1" "$2" "${3:-}" <<'PY'
import json, os, sys, glob
from fractions import Fraction
atlas, d, outp, kwlabel = sys.argv[1:5]
A = json.load(open(atlas)); L = A['layers']; n = A['n']
rows = []; kw_ok = None
for p in sorted(glob.glob(os.path.join(d, '*.tsv'))):
    label = os.path.basename(p)[:-4]
    if label == 'summary': continue
    lines = [l.rstrip('\n').split('\t') for l in open(p)]
    hdr = None; data = []
    for parts in lines:
        if parts and parts[0] == 'step': hdr = parts; continue
        if hdr and len(parts) == len(hdr) and parts[0].isdigit(): data.append(dict(zip(hdr, parts)))
    if len(data) != n: rows.append((label, 'FAIL:rows=%d' % len(data))); continue
    f_prev = 1; lt = eq = gt = 0; pct = []; ws = []
    for r in data:
        k = int(r['step']); w = f_prev * int(r['g']); f_prev = int(r['f']); d_cls = int(r['dclass'])
        lay = L[k - 1]; kw_w = int(lay['kwrank']['kw_w'])
        if w < kw_w: lt += 1
        elif w == kw_w: eq += 1
        else: gt += 1
        hb = lay['hist']['hb%d' % d_cls]; b = w.bit_length() - 1
        below = sum(int(v['hwo']) for kk, v in hb.items() if int(kk[2:]) < b)
        here = int(hb.get('lg%d' % b, {}).get('hwo', '0'))
        tot = int(lay['by_class']['d%d' % d_cls])
        if here == 0 or tot == 0: rows.append((label, 'FAIL:bucket_missing_step%d' % k)); break
        pct.append(Fraction(2 * below + here, 2 * tot)); ws.append(w)
    else:
        mean = sum(pct) / len(pct)
        rows.append((label, 'OK', lt, eq, gt, '%.6f' % float(mean), ' '.join(str(w) for w in ws)))
        if label == kwlabel:
            kw_ok = all(w == int(L[k]['kwrank']['kw_w']) for k, w in enumerate(ws))
with open(outp, 'w') as o:
    o.write('#summary\tn=%d\tatlas=%s\tw_k=f(s_k-1)*g(s_k)\tbins=vs kwrank.kw_w (exact)\tpct=octave-resolution mass percentile within the step class (hist.hwo; half-bucket credit)\n' % (n, atlas))
    o.write('label\tstatus\tlt_kw\teq_kw\tgt_kw\tmean_octave_pct\tw_per_step\n')
    for r in rows: o.write('\t'.join(str(x) for x in r) + '\n')
    ok = sum(1 for r in rows if r[1] == 'OK')
    o.write('SUMMARY_PROFILES=%d\nSUMMARY_OK=%d\n' % (len(rows), ok))
    if kwlabel: o.write('KW_W_MATCHES_ATLAS=%s\n' % ('YES' if kw_ok else 'NO' if kw_ok is not None else 'NOT_PRESENT'))
print('SUMMARY_PROFILES=%d SUMMARY_OK=%d' % (len(rows), ok))
PY
}

# ---------------------------------------------------------------- Q8: 11 profiles, serial
if answered ATLAS_Q8; then echo "== Q8 already ANSWERED, skipping"; else
  t0=$(secs); D="$OUT/q8"; mkdir -p "$D"; fail=""
  while IFS=$'\t' read -r label walk; do
    [ -z "$label" ] || [ "${label:0:1}" = "#" ] && continue
    profile_one "$label" "$walk" "$D" "$CACHE_MB_ONE" || { fail="profile:$label"; break; }
  done < "$Q8_IN"
  if [ -z "$fail" ]; then
    summarise_profiles "$D" "$D/summary.tsv" kw_itself > "$D/summary.log" || fail="summary"
    want=$(grep -cv '^#' "$Q8_IN"); got=$(sed -n 's/^SUMMARY_OK=//p' "$D/summary.tsv")
    [ "$want" = "$got" ] || fail="summary_ok=$got/$want"
    if [ "$N" = 31 ] && grep -qx 'KW_W_MATCHES_ATLAS=NO' "$D/summary.tsv"; then fail="kw_profile_disagrees_with_atlas_kwrank"; fi
  fi
  timing q8 $(( $(secs) - t0 ))
  if [ -z "$fail" ]; then verdict ATLAS_Q8 ANSWERED; else verdict ATLAS_Q8 "FAIL:$fail"; fi
fi

# ---------------------------------------------------------------- Q1b: 1,000 profiles, parallel
if answered ATLAS_Q1B; then echo "== Q1b already ANSWERED, skipping"; else
  t0=$(secs); D="$OUT/q1b/profiles"; mkdir -p "$D"; fail=""
  avail_kb=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
  par_cap=$(( avail_kb / (3500 * 1024) )); [ "$par_cap" -lt 1 ] && par_cap=1
  PAR="$Q1B_PAR"; [ "$PAR" -gt "$par_cap" ] && { echo "== Q1b: Q1B_PAR=$Q1B_PAR capped to $par_cap by MemAvailable=${avail_kb}kB (3.5 GiB per process)"; PAR=$par_cap; }
  ncpu=$(nproc); [ "$PAR" -gt "$ncpu" ] && PAR=$ncpu
  echo "== Q1b: $(grep -cv '^#' "$Q1B_IN") walks, $PAR in parallel, cache ${CACHE_MB_PAR} MB each"
  grep -v '^#' "$Q1B_IN" | tr '\t' '\n' | \
    xargs -d '\n' -n 2 -P "$PAR" bash -c 'profile_one "$0" "$1" "'"$D"'" "'"$CACHE_MB_PAR"'" || echo "PROFILE_FAIL $0"' \
    > "$OUT/q1b/xargs.log" 2>&1
  want=$(grep -cv '^#' "$Q1B_IN"); got=$(ls "$D"/*.ok 2>/dev/null | wc -l)
  [ "$want" = "$got" ] || fail="profiles_ok=$got/$want"
  if [ -z "$fail" ]; then
    summarise_profiles "$D" "$OUT/q1b/summary.tsv" > "$OUT/q1b/summary.log" || fail="summary"
    got=$(sed -n 's/^SUMMARY_OK=//p' "$OUT/q1b/summary.tsv"); [ "$want" = "$got" ] || fail="summary_ok=$got/$want"
  fi
  timing q1b $(( $(secs) - t0 ))
  if [ -z "$fail" ]; then verdict ATLAS_Q1B ANSWERED; else verdict ATLAS_Q1B "FAIL:$fail"; fi
fi

# ---------------------------------------------------------------- Q7: the dead census
if answered ATLAS_Q7; then echo "== Q7 already ANSWERED, skipping"; else
  t0=$(secs); D="$OUT/q7"; mkdir -p "$D"; fail=""
  # shellcheck disable=SC2086
  "$BIN" --kc-dead-census "$FDIR" "$GDIR" --kc-layers $Q7_LAYERS --kc-out "$D/dead_census.tsv" --kc-cache-mb "$CACHE_MB_ONE" > "$D/dead_census.log" 2>&1
  grep -qx "KC_DEAD_CENSUS=OK" "$D/dead_census.log" && [ -r "$D/dead_census.tsv" ] || fail="census"
  timing q7_census $(( $(secs) - t0 ))
  if [ -z "$fail" ]; then   # cross-check 1: per-layer dead states / dead prefixes == the atlas's counts
    python3 - "$ATLAS" "$D/dead_census.tsv" <<'PY' > "$D/atlas_xcheck.log" || fail="atlas_counts_mismatch"
import json, sys
A = json.load(open(sys.argv[1])); L = {r['k']: r for r in A['layers']}
bad = 0; seen = 0
for line in open(sys.argv[2]):
    if not line.startswith('#L\t'): continue
    p = line.rstrip('\n').split('\t'); k = int(p[1]); seen += 1
    c = L[k]['counts']
    ok = int(p[2]) == c['st_dead'] and p[3] == c['st_dead_fmass'] and p[5] == c['st_live_fmass']
    print('layer', k, 'dead_states', p[2], 'atlas', c['st_dead'], 'dead_prefixes', p[3], 'atlas', c['st_dead_fmass'], 'OK' if ok else 'MISMATCH')
    bad += not ok
print('ATLAS_XCHECK_LAYERS=%d ATLAS_XCHECK_BAD=%d' % (seen, bad))
sys.exit(1 if bad or seen == 0 else 0)
PY
  fi
  if [ -z "$fail" ]; then   # cross-check 2: the g-free shortcut agrees with the g ladder on the late layers
    t1=$(secs)
    # shellcheck disable=SC2086
    "$BIN" --kc-dead-census "$FDIR" - --kc-layers $Q7_LOCAL_LAYERS --kc-local-max 4 --kc-out "$D/dead_census_gfree.tsv" --kc-cache-mb "$CACHE_MB_ONE" > "$D/dead_census_gfree.log" 2>&1
    grep -qx "KC_DEAD_CENSUS=OK" "$D/dead_census_gfree.log" || fail="gfree_census"
    if [ -z "$fail" ]; then
      lo=${Q7_LOCAL_LAYERS% *}; hi=${Q7_LOCAL_LAYERS#* }
      sel() { awk -F'\t' -v lo="$lo" -v hi="$hi" '($1 ~ /^[0-9]+$/ && $1>=lo && $1<hi) || ($1=="#L" && $2>=lo && $2<hi) {print}' "$1" | cut -f1-7; }
      if cmp -s <(sel "$D/dead_census.tsv") <(sel "$D/dead_census_gfree.tsv"); then echo "GFREE_XCHECK=PASS layers=[$lo,$hi)"; else echo "GFREE_XCHECK=FAIL"; fail="gfree_xcheck"; fi
    fi
    timing q7_gfree_xcheck $(( $(secs) - t1 ))
  fi
  if [ -z "$fail" ]; then verdict ATLAS_Q7 ANSWERED; else verdict ATLAS_Q7 "FAIL:$fail"; fi
fi

# ---------------------------------------------------------------- Q9: witness walks
if answered ATLAS_Q9; then echo "== Q9 already ANSWERED, skipping"; else
  t0=$(secs); D="$OUT/q9"; mkdir -p "$D"; fail=""
  "$BIN" --kc-witness-walks "$FDIR" "$GDIR" "$ATLAS" --kc-out "$D/witness_walks.tsv" --kc-cache-mb "$CACHE_MB_ONE" > "$D/witness_walks.log" 2>&1
  grep -qx "KC_WITNESS_WALKS=OK" "$D/witness_walks.log" && [ -r "$D/witness_walks.tsv" ] || fail="witness_walks"
  if [ -z "$fail" ] && [ "$N" = 31 ]; then   # independent first-principles check of EVERY realised walk
    bad=0; tot=0
    while IFS=$'\t' read -r idx rest; do
      [[ "$idx" =~ ^[0-9]+$ ]] || continue
      walk="${rest##*	}"; tot=$((tot+1))
      "$BIN" --check-arrangement "63,0,$walk" > "$D/ca_$idx.log" 2>&1
      grep -q 'verdict SUPER (C1&C2&C4&C5):     IN' "$D/ca_$idx.log" || bad=$((bad+1))
    done < "$D/witness_walks.tsv"
    echo "CHECK_ARRANGEMENT_WALKS=$tot CHECK_ARRANGEMENT_BAD=$bad"
    [ "$bad" = 0 ] && [ "$tot" -gt 0 ] || fail="check_arrangement:$bad/$tot"
  fi
  timing q9 $(( $(secs) - t0 ))
  if [ -z "$fail" ]; then verdict ATLAS_Q9 ANSWERED; else verdict ATLAS_Q9 "FAIL:$fail"; fi
fi

# ---------------------------------------------------------------- ladders untouched? then the marker
touched=$( { find "$FDIR" "$GDIR" -newer "$START_MARK" -print 2>/dev/null || true; } | head -5)
if [ -n "$touched" ]; then echo "LADDER_WRITE_DETECTED:"; echo "$touched"; verdict ATLAS_QUERIES "FAIL:ladder_dir_modified"; exit 1; fi
echo "LADDERS_UNTOUCHED=YES"
if answered ATLAS_Q8 && answered ATLAS_Q1B && answered ATLAS_Q7 && answered ATLAS_Q9; then
  verdict ATLAS_QUERIES ANSWERED
  date -u +%FT%TZ > "$OUT/ATLAS_QUERIES_COMPLETE"
  echo "== complete $(date -u +%FT%TZ): marker $OUT/ATLAS_QUERIES_COMPLETE"
  # the summary tokens the report quotes (no ladder read; ATLAS_QUERIES stays ANSWERED, a summary gate failure exits 3)
  python3 "$AFPY" summary "$OUT" --atlas "$ATLAS" --walks "$Q1B_IN" > "$OUT/SUMMARY_TOKENS.txt" 2>&1
  tail -1 "$OUT/SUMMARY_TOKENS.txt"
  grep -qx 'AF_SUMMARY=PASS' "$OUT/SUMMARY_TOKENS.txt" || exit 3   # queries answered, summary gates not all PASS
  exit 0
fi
verdict ATLAS_QUERIES "FAIL:see_tokens"
exit 1
