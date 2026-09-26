#!/usr/bin/env bash
# run_v3_rows.sh -- the TR-12 battery's V3 rows, standalone, at n=31. Opus BP, 2026-09-25.
# Precedent: an earlier standalone driver (not published). The row code is NOT re-implemented: it is extracted
# at run time from SRC/scripts/tr12_repro.sh (sha-pinned) by awk ranges keyed on literal lines, and
# sourced. Extracted: norm(); the row/token machinery (declare -A TOKSTATE .. row_skip); the knob
# block (V3K); row a1_v3; v3_join_row + its gate (row c_v3_join); the c_viz block; v3_fig_verdict;
# agg(); `agg TR12_V3 ...`; the VERDICTS body loop. Only a1_v3 needs a ladder, and only FDIR.
# USAGE  run_v3_rows.sh SRC FDIR SOLVE OUT
#   SRC   tree with the batch-15 scripts/tr12_repro.sh + solve.py (+ viz/, tr12/). Read-only.
#   FDIR  n=31 f ladder, MUST be on a read-only mount (findmnt), else refused.
#   SOLVE solve binary (--kc-unrank / --kc-count).   OUT  output dir (recreated).
# TEST   TEST_N=9  run_v3_rows.sh SRC - SOLVE OUT   builds a throwaway n=9 f ladder (no ro check)
#        JOIN_ONLY=1 run_v3_rows.sh SRC - - OUT     no ladder: joins SRC/tr12/v3_rel_grid.tsv (or $JOIN_GRID)
# Golden: a1_v3 is diffed (the battery's own row_end) against EXPECT_GRID, default SRC/tr12/
# v3_rel_grid.tsv at n>=31, SRC/scripts/tr12_expected/n<N>/a1_v3.txt below; other rows MINT.
# Consumer dir: seeded at n>=31 from SRC/tr12/{scan,q3_profile_kw.tsv} (not the flat v3 TSV).
# OUT/VERDICTS.txt: whole-line KEY=value; V3ROWS_STATE=RUNNING until the end, then DONE.
# OUT/bundle.sha256 is written LAST (after OUT/v3rows_bundle.tar.gz, gzip -9): pull after it exists.
# Bundle = VERDICTS, run.log, raw/ (raw/a1_v3.txt == the grid), diff/, + the spectrum iff != pin.
set -u
export LC_ALL=C
SRC="${1:-${SRC:-}}"; FDIR="${2:-${FDIR:-}}"; SOLVE="${3:-${SOLVE:-}}"; OUT="${4:-${OUT:-}}"
TEST_N="${TEST_N:-}"; JOIN_ONLY="${JOIN_ONLY:-0}"
[ -n "$SRC" ] && [ -n "$OUT" ] && [ -d "$SRC" ] || { echo "usage: $0 SRC FDIR SOLVE OUT" >&2; exit 2; }
SRC="$(cd -- "$SRC" && pwd)"; mkdir -p "$OUT" || exit 2; OUT="$(cd -- "$OUT" && pwd)"
BATTERY="$SRC/scripts/tr12_repro.sh"
BATTERY_PIN=fdfa94bf009193e04044b1fe15bfa80bad9eea6c9d4f44072900b10f05c0c154
SOLVEPY_PIN=7b4447177d6709731100ae02f10fd3eac084074ef5ca114acb9741c0232bfc04
GRID_PIN=38457ee67dcf5cce359b80e2cd93148085394c016e50aa5362f51b8dd17d3a69   # tr12/v3_rel_grid.tsv
SPEC_PIN=22ac482fe8f25e3a6db683adda0459b414729fa6e045796b276640b67ec6e6b2   # b15 tr12/v3_spectrum.tsv

VERD="$OUT/VERDICTS.txt"; echo V3ROWS_STATE=RUNNING > "$VERD"
rm -f "$OUT/bundle.sha256" "$OUT/v3rows_bundle.tar.gz"
OUTDIR="$OUT"; RAWDIR="$OUT/raw"; GOTDIR="$OUT/got"; DIFFDIR="$OUT/diff"; ARTDIR="$OUT/artifacts"
WORK="$OUT/work"; EXPECTDIR="$OUT/expect"
rm -rf "$RAWDIR" "$GOTDIR" "$DIFFDIR" "$ARTDIR" "$WORK" "$EXPECTDIR" "$OUT/ladders"
mkdir -p "$RAWDIR" "$GOTDIR" "$DIFFDIR" "$ARTDIR" "$WORK" "$EXPECTDIR"
exec >"$OUT/run.log" 2>&1
LOG=/dev/null          # the battery's row_end/row_skip tee to $LOG AND stdout; stdout is run.log
REGEN=0; MINT_MISSING=1; GDIR=""; TDIR=""; REPO_ROOT="$SRC"
T0=$(date +%s); X=()
x(){ X+=("$1"); echo "$1"; }
sha(){ sha256sum < "$1" | cut -d' ' -f1; }
finish(){ # finish STATE : VERDICTS (atomic), then bundle, then bundle.sha256
  x "V3ROWS_ELAPSED_S=$(( $(date +%s) - T0 ))"
  { echo "# run_v3_rows.sh $(date -u +%FT%TZ) host=$(hostname) universe n=${N_PAIRS:-?} N=${N_TOTAL:-?}"
    printf '%s\n' "${X[@]}"; [ -s "$VERD.body" ] && cat "$VERD.body"
    echo "V3ROWS_STATE=$1"; } > "$VERD.tmp" && mv "$VERD.tmp" "$VERD"; rm -f "$VERD.body"
  cat "$VERD"
  # raw/a1_v3.txt IS the grid (the row cp's it); the spectrum ships only if it differs from the pin
  sp=artifacts/consumer/spectrum/v3_spectrum.tsv; grep -qx V3ROWS_SPECTRUM_VS_B15_COMMITTED=MATCH "$VERD" && sp=
  ( cd "$OUT" && ls -d VERDICTS.txt run.log raw diff $sp 2>/dev/null | xargs tar -cf - ) | gzip -9 > "$OUT/v3rows_bundle.tar.gz"
  sync; sha256sum "$OUT/v3rows_bundle.tar.gz" > "$OUT/bundle.sha256.tmp" && mv "$OUT/bundle.sha256.tmp" "$OUT/bundle.sha256"
  exit 0; }
die(){ echo "FATAL: $1"; x "V3ROWS_ERROR=$1"; finish ERROR; }

MODE=ladder; [ -n "$TEST_N" ] && MODE="test-n$TEST_N"; [ "$JOIN_ONLY" = 1 ] && MODE=join-only-committed-grid
x "V3ROWS_MODE=$MODE"
[ -f "$BATTERY" ] && [ -f "$SRC/solve.py" ] || die "SRC lacks scripts/tr12_repro.sh or solve.py"
x "V3ROWS_BATTERY_SHA256=$(sha "$BATTERY")"; x "V3ROWS_SOLVEPY_SHA256=$(sha "$SRC/solve.py")"
[ -f "$SRC/viz/report_figures.py" ] && x "V3ROWS_REPORT_FIGURES_SHA256=$(sha "$SRC/viz/report_figures.py")"
x "V3ROWS_SRC_TREE=$(git -C "$SRC" write-tree 2>/dev/null || echo not-a-git-tree)"
if [ "$(sha "$BATTERY")" != "$BATTERY_PIN" ] || [ "$(sha "$SRC/solve.py")" != "$SOLVEPY_PIN" ]; then
  [ "${ALLOW_DRIFT:-0}" = 1 ] && x "V3ROWS_DRIFT=ALLOWED" || die "source-sha-not-batch15-pin"; fi
x "V3ROWS_NUMPY=$(python3 -c 'import numpy;print(numpy.__version__)' 2>/dev/null || echo absent)"
x "V3ROWS_MATPLOTLIB=$(python3 -c 'import matplotlib;print(matplotlib.__version__)' 2>/dev/null || echo absent)"

# ---- extraction: ext NAME START [AFTER] END -- first line == START (or prefix, for END) ----------
ext(){ awk -v s="$2" -v a="$3" -v e="$4" '
  !p && $0==s {p=1; b=NR} p {print} p && (a=="" || seen) && index($0,e)==1 && (NR>b || index(s,e)==1) {print b"-"NR > "/dev/stderr"; exit}
  p && a!="" && index($0,a)==1 {seen=1}' "$BATTERY" > "$WORK/$1.sh" 2> "$WORK/$1.range"
  [ -s "$WORK/$1.range" ] && bash -n "$WORK/$1.sh" || die "extract-$1-failed"
  x "V3ROWS_EXTRACT_$1=lines:$(cat "$WORK/$1.range"):sha256:$(sha "$WORK/$1.sh" | cut -c1-16)"; }
ext norm      'norm(){' '' '}'
ext machinery 'declare -A TOKSTATE=()      # token -> PASS | FAIL:... | SKIP:...' 'row_skip(){' '}'
ext knobs     'if [ "$N_PAIRS" -ge 31 ]; then' '' 'V3K="${TR12_V3_K:-$V3K_DEF}"'
ext a1_v3     'row_begin a1_v3' '' 'row_end TR12_V3_TSV $rc'
ext v3join    'v3_join_row(){   # v3_join_row GRID_TSV CONSUMER_DIR' '' 'fi'
ext cviz      'if [ -d "$ARTDIR/consumer" ] && python3 -c "import matplotlib, numpy" >/dev/null 2>&1; then' '' 'fi'
ext v3fig     'v3_fig_verdict(){' '' '}'
ext agg       'agg(){' '' '}'
ext aggv3     'agg TR12_V3 TR12_V3_TSV TR12_V3_FIG' '' 'agg TR12_V3 '
ext verdloop  'for t in "${TOKORDER[@]}"; do' '' 'done | awk'
grep -qF -- '--kc-unrank "$FDIR" "$R"' "$WORK/a1_v3.sh" && grep -qF -- '--v3-spectrum "$grid" "$out"' "$WORK/v3join.sh" \
  && grep -qF 'v3_join_row "$ARTDIR/v3_rel_grid.tsv" "$ARTDIR/consumer"' "$WORK/v3join.sh" \
  && grep -qF 'SKIP:reduced-universe' "$WORK/v3fig.sh" || die "extracted-rows-lack-their-calls"
for f in norm machinery agg; do . "$WORK/$f.sh"; done

# ---- universe ----------------------------------------------------------------------------------
if [ "$JOIN_ONLY" = 1 ]; then
  N_PAIRS=31; N_TOTAL=committed-grid; FDIR=""; SOLVE=""
else
  [ -x "$SOLVE" ] || die "solve-binary-missing"; SOLVE="$(cd "$(dirname "$SOLVE")" && pwd)/$(basename "$SOLVE")"
  x "V3ROWS_SOLVE_BIN_SHA256=$(sha "$SOLVE")"
  if [ -n "$TEST_N" ]; then
    FDIR="$OUT/ladders/f"; mkdir -p "$FDIR"
    nice "$SOLVE" --kc-build "$FDIR" --f1-pairs "$TEST_N" > "$WORK/bf.log" 2>&1 || die "kc-build-failed"
    x "V3ROWS_RO=SKIP:test-ladder"
  else
    [ -d "$FDIR" ] || die "FDIR-not-a-directory"
    opts=$(findmnt -no OPTIONS --target "$FDIR" 2>/dev/null)
    printf '%s' "$opts" | tr , '\n' | grep -qx ro || { x "V3ROWS_RO=FAIL:$(findmnt -no TARGET --target "$FDIR")"; die "FDIR-mount-not-read-only"; }
    x "V3ROWS_RO=PASS:$(findmnt -no TARGET --target "$FDIR")"
  fi
  touch "$WORK/.start_mark"; sleep 1
  COUNTLINE="$("$SOLVE" --kc-count "$FDIR" 2>/dev/null | grep '^KC COUNT' | tail -1)"
  N_PAIRS="$(printf '%s' "$COUNTLINE" | sed -n 's/^KC COUNT n=\([0-9]*\) = .*/\1/p')"
  N_TOTAL="$(printf '%s' "$COUNTLINE" | sed -n 's/^KC COUNT n=[0-9]* = \([0-9]*\)$/\1/p')"
  [ -n "$N_PAIRS" ] && [ -n "$N_TOTAL" ] || die "kc-count-unparsed"
  [ -n "$TEST_N" ] || [ "$N_PAIRS" -ge 31 ] || die "FDIR-is-n$N_PAIRS-not-31"
fi
x "V3ROWS_UNIVERSE_N=$N_PAIRS"; x "V3ROWS_N_TOTAL=$N_TOTAL"
. "$WORK/knobs.sh"; x "V3ROWS_V3K=$V3K"

# ---- expected block for a1_v3; consumer dir ------------------------------------------------------
if [ "$N_PAIRS" -ge 31 ]; then EG="${EXPECT_GRID:-$SRC/tr12/v3_rel_grid.tsv}"
else EG="${EXPECT_GRID:-$SRC/scripts/tr12_expected/n$N_PAIRS/a1_v3.txt}"; fi
if [ -f "$EG" ]; then cp "$EG" "$EXPECTDIR/a1_v3.txt"; x "V3ROWS_A1_EXPECT_SHA256=$(sha "$EG")"
else x "V3ROWS_A1_EXPECT=none-minted"; fi
if [ "$N_PAIRS" -ge 31 ] && [ "${SEED_CONSUMER:-1}" = 1 ]; then
  mkdir -p "$ARTDIR/consumer" && cp -r "$SRC/tr12/scan" "$ARTDIR/consumer/" \
    && cp "$SRC/tr12/q3_profile_kw.tsv" "$ARTDIR/consumer/" || die "consumer-seed-failed"
  x "V3ROWS_CONSUMER=seeded-from-SRC/tr12"
fi

# ---- the rows, in battery order -------------------------------------------------------------------
if [ "$JOIN_ONLY" = 1 ]; then
  cp "${JOIN_GRID:-$SRC/tr12/v3_rel_grid.tsv}" "$ARTDIR/v3_rel_grid.tsv" || die "no-grid-to-join"
  tok_record TR12_V3_TSV PASS given-grid; x "V3ROWS_JOIN_GRID=${JOIN_GRID:-SRC/tr12/v3_rel_grid.tsv}"
else
  echo "a1_v3 start $(date -u +%T); progress: wc -l $RAWDIR/a1_v3.txt (K+2 when done)"
  . "$WORK/a1_v3.sh"
fi
. "$WORK/v3join.sh"
. "$WORK/cviz.sh"
. "$WORK/v3fig.sh"; v3_fig_verdict
. "$WORK/aggv3.sh"
. "$WORK/verdloop.sh"

# ---- driver-level checks (not battery tokens) ------------------------------------------------------
G="$ARTDIR/v3_rel_grid.tsv"; S="$ARTDIR/consumer/spectrum/v3_spectrum.tsv"
if [ -s "$G" ]; then x "V3ROWS_GRID_SHA256=$(sha "$G")"
  [ "$N_PAIRS" -ge 31 ] && { [ "$(sha "$G")" = "$GRID_PIN" ] && x V3ROWS_GRID_VS_COMMITTED=MATCH || x V3ROWS_GRID_VS_COMMITTED=DIFFER; }; fi
if [ -s "$S" ]; then x "V3ROWS_SPECTRUM_SHA256=$(sha "$S")"
  [ "$(sha "$S")" = "$SPEC_PIN" ] && x V3ROWS_SPECTRUM_VS_B15_COMMITTED=MATCH || x V3ROWS_SPECTRUM_VS_B15_COMMITTED=DIFFER
elif [ "$N_PAIRS" -ge 31 ]; then x V3ROWS_SPECTRUM_VS_B15_COMMITTED=ABSENT; fi
if [ -n "$FDIR" ] && [ -f "$WORK/.start_mark" ]; then
  [ -z "$(find "$FDIR" -newer "$WORK/.start_mark" -print -quit 2>/dev/null)" ] \
    && x V3ROWS_LADDER_UNMODIFIED=YES || x V3ROWS_LADDER_UNMODIFIED=NO; fi
finish DONE
