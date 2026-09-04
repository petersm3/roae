#!/usr/bin/env bash
#
# tr12_repro.sh — the TR-12 reproduction battery driver.
#
# TR12_QUERY_PROGRAM §R step 6 / §8 item 13:
#   "runs every TR-12 query against named FDIR/GDIR, diffs each output against the committed
#    expected-output blocks, non-zero exit on any mismatch (shell only, no new .c/.py)."
#
# It is shell only: it adds no .c and no .py file of its own.  Its own arithmetic — including the
# 192-bit atlas sums, the mod-24 gates and the Q3 reader check — is done in `awk` and `bc`, never
# by a helper script.  It does CALL the repo's existing Python where that Python is the authority:
#   * `python3 -c "import solve; ..."` for the three historical arrangements of Q7 and for the KW
#     walk at n=31 (both have a shell-only fallback or a loud SKIP);
#   * `python3 solve.py --atlas-queries/--atlas-selftest` for the atlas consumer, as a SECOND
#     implementation to cross-check the awk+bc legs against;
#   * `viz/report_figures.py` for the V1/V2/V4/V5 figures.
# Every one of those is optional: if the interpreter, the module or matplotlib is absent, the row
# reports SKIPPED with the reason instead of failing or, worse, quietly passing.
#
# ---------------------------------------------------------------------------------------------
# WHAT IT DOES
#   1. Determines the universe (n, N) from the mounted f-ladder.
#   2. Runs the battery in the QUERY_INVENTORY §5 RUN ORDER:
#          A0 (no ladder)  ->  A1 (f)  ->  A2 (f+g)  ->  B (the scan)  ->  C (atlas-derived)
#      That order is eviction insurance: the scan is one unresumable pass that writes its atlas
#      only at the end, so everything cheap is banked before it. The order is NOT optional and
#      this script does not offer a flag to reorder it.
#   3. Normalises each output (build identity, absolute paths and wall-clock timings are the only
#      things stripped — see `norm` below, which lists every substitution) and DIFFS it against
#      the committed expected block for this universe.
#   4. Emits one KEY=value verdict per row into $OUT/VERDICTS.txt, matched with `grep -qx`.
#   5. Prints an explicit SKIPPED report. A skip is never silent and never counts as a pass:
#      TR12_REPRO_COMPLETE=NO is emitted whenever anything was skipped, and a parent token whose
#      leg was skipped is itself downgraded to SKIP — never left reading PASS.
#   6. Exits NON-ZERO on any mismatch, any non-zero row exit, or any missing expected block.
#
# EXIT STATUS
#   0  every executed row matched its expected block   (TR12_REPRO=PASS)
#   1  at least one row failed / mismatched / had no expected block   (TR12_REPRO=FAIL)
#   2  usage or environment error (no binary, no ladder, unusable universe)
#
# USAGE
#   scripts/tr12_repro.sh --n9                       # self-contained: builds its own n=9 ladders
#   scripts/tr12_repro.sh --fdir F --gdir G --tdir T # full-31 (or any n) against mounted ladders
#   scripts/tr12_repro.sh --n9 --regen               # (re)mint the expected blocks for n=9
#
# OPTIONS
#   --n9                 build a throwaway n=9 f/g/t ladder set and run against it
#   --pairs N            with --n9, use n=N instead of 9 (n<=13 is the sane range)
#   --fdir/--gdir/--tdir named ladder directories (TDIR is optional; without it the t-legs SKIP)
#   --solve PATH         the solve binary (default: build solve.c into a temp dir)
#   --out DIR            artifact root (default: a temp dir; printed at the end)
#   --expect DIR         expected-block directory (default: scripts/tr12_expected/n<N>)
#   --regen              write the expected blocks from this run instead of diffing against them
#   --wave3              also run the wave-3 rows that are cost-gated at full-31 (Q5 extremals)
#   --with-gcheck        run --kc-g-check at full-31 (a ~24 h single-threaded full ladder pass)
#   --with-chunked       run the chunked-scan == whole-scan identity at full-31 (a second scan)
#   --no-scan            skip Group B's long pass (Group C then reports SKIP, not PASS)
#   --keep               keep the work directory
#
# ENVIRONMENT KNOBS (all have defaults; every one is echoed into the run header)
#   TR12_C3MAX   TR12_SEED   TR12_Q8_K   TR12_Q4AC_M   TR12_Q1C_M   TR12_V3_K
#
# ---------------------------------------------------------------------------------------------
# 2026-08-22. Claude (Opus 5). Developed with AI assistance (Claude, Anthropic).
# Direction and the query program are the operator's; TR-12's query specifications are by
# Claude (Fable 5), 2026-07-17; the executable contract this drives is QUERY_INVENTORY.md.
# This driver is a certificate of what the binary does on a named universe, not a proof.
# Errors are Claude's; corrections invited.
# ---------------------------------------------------------------------------------------------

set -u
# NOTE: pipefail is deliberately NOT set. Several rows legitimately end a pipeline in
# `head -1` or `grep -q`, which SIGPIPEs the producer; under pipefail that reads as a failure.
# Every row captures the rc of its primary command directly instead.

if [ -z "${BASH_VERSINFO:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "FATAL: bash >= 4 required (associative arrays)" >&2; exit 2
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# ------------------------------------------------------------------ defaults / arg parsing ----
MODE_N9=0; PAIRS=9
FDIR=""; GDIR=""; TDIR=""
SOLVE=""; OUTDIR=""; EXPECTDIR=""
REGEN=0; WAVE3=0; WITH_GCHECK=0; WITH_CHUNKED=0; DO_SCAN=1; KEEP=0

# --help prints the file's leading comment block verbatim (it stops at the first non-comment line).
usage(){ awk 'NR>1 { if (!/^#/) exit; sub(/^# ?/,""); print }' "${BASH_SOURCE[0]}"; }

while [ $# -gt 0 ]; do
    case "$1" in
        --n9)           MODE_N9=1 ;;
        --pairs)        PAIRS="$2"; shift ;;
        --fdir)         FDIR="$2"; shift ;;
        --gdir)         GDIR="$2"; shift ;;
        --tdir)         TDIR="$2"; shift ;;
        --solve)        SOLVE="$2"; shift ;;
        --out)          OUTDIR="$2"; shift ;;
        --expect)       EXPECTDIR="$2"; shift ;;
        --regen)        REGEN=1 ;;
        --wave3)        WAVE3=1 ;;
        --with-gcheck)  WITH_GCHECK=1 ;;
        --with-chunked) WITH_CHUNKED=1 ;;
        --no-scan)      DO_SCAN=0 ;;
        --keep)         KEEP=1 ;;
        -h|--help)      usage; exit 0 ;;
        *) echo "FATAL: unknown option '$1' (try --help)" >&2; exit 2 ;;
    esac
    shift
done

if [ "$MODE_N9" -eq 0 ] && [ -z "$FDIR" ]; then
    echo "FATAL: give --n9 (self-contained reduced universe) or --fdir/--gdir [--tdir]" >&2
    usage >&2; exit 2
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/tr12repro.XXXXXX")"
[ "$KEEP" -eq 1 ] || trap 'rm -rf "$WORK"' EXIT
[ -n "$OUTDIR" ] || OUTDIR="$WORK/out"
mkdir -p "$OUTDIR"

RAWDIR="$OUTDIR/raw";  GOTDIR="$OUTDIR/got";  DIFFDIR="$OUTDIR/diff"; ARTDIR="$OUTDIR/artifacts"
mkdir -p "$RAWDIR" "$GOTDIR" "$DIFFDIR" "$ARTDIR"
VERD="$OUTDIR/VERDICTS.txt"; : > "$VERD"
LOG="$OUTDIR/tr12_repro.log"; : > "$LOG"

say(){ printf '%s\n' "$*" | tee -a "$LOG"; }
die(){ say "FATAL: $*"; exit 2; }

# ------------------------------------------------------------------------------- the binary ---
if [ -z "$SOLVE" ]; then
    [ -f "$REPO_ROOT/solve.c" ] || die "no --solve given and $REPO_ROOT/solve.c not found"
    say "[build] gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz"
    SOLVE="$WORK/solve"
    gcc -O2 -pthread -fopenmp -o "$SOLVE" "$REPO_ROOT/solve.c" -lm -lz 2>"$WORK/build.err" \
        || { cat "$WORK/build.err" >&2; die "solve.c did not compile"; }
fi
[ -x "$SOLVE" ] || die "solve binary '$SOLVE' is not executable"

# ------------------------------------------------------------------------------ the universe --
if [ "$MODE_N9" -eq 1 ]; then
    FDIR="$WORK/f"; GDIR="$WORK/g"; TDIR="$WORK/t"; mkdir -p "$FDIR" "$GDIR" "$TDIR"
    say "[ladders] building the reduced universe n=$PAIRS (f, g, t) — seconds, \$0"
    "$SOLVE" --kc-build   "$FDIR" --f1-pairs "$PAIRS" >"$WORK/bf.log" 2>&1 || die "--kc-build failed"
    "$SOLVE" --kc-g-build "$GDIR" --f1-pairs "$PAIRS" >"$WORK/bg.log" 2>&1 || die "--kc-g-build failed"
    "$SOLVE" --kc-t-build "$FDIR" "$TDIR"             >"$WORK/bt.log" 2>&1 || die "--kc-t-build failed"
fi
[ -d "$FDIR" ] || die "FDIR '$FDIR' is not a directory"
[ -n "$GDIR" ] && [ -d "$GDIR" ] || die "GDIR '$GDIR' is not a directory (f+g rows need it)"
HAVE_T=0; [ -n "$TDIR" ] && [ -d "$TDIR" ] && HAVE_T=1

COUNTLINE="$("$SOLVE" --kc-count "$FDIR" 2>/dev/null | grep '^KC COUNT' | tail -1)" \
    || die "--kc-count failed on FDIR"
N_PAIRS="$(printf '%s' "$COUNTLINE" | sed -n 's/^KC COUNT n=\([0-9]*\) = .*/\1/p')"
N_TOTAL="$(printf '%s' "$COUNTLINE" | sed -n 's/^KC COUNT n=[0-9]* = \([0-9]*\)$/\1/p')"
[ -n "$N_PAIRS" ] && [ -n "$N_TOTAL" ] || die "could not parse the universe from: $COUNTLINE"

N_MINUS_1="$(echo "$N_TOTAL - 1" | bc)"
N_HALF="$(echo "$N_TOTAL / 2" | bc)"
N_MOD24="$(echo "$N_TOTAL % 24" | bc)"
N_DIV24="$(echo "$N_TOTAL / 24" | bc)"

[ -n "$EXPECTDIR" ] || EXPECTDIR="$SCRIPT_DIR/tr12_expected/n${N_PAIRS}"

# knobs — reduced universes get reduced batch sizes so the whole battery stays under a minute
if [ "$N_PAIRS" -ge 31 ]; then
    C3MAX_DEF=387;  Q8K_DEF=1000; Q4ACM_DEF=1000000; Q1CM_DEF=10000; V3K_DEF=1000
else
    C3MAX_DEF=31;   Q8K_DEF=200;  Q4ACM_DEF=20000;   Q1CM_DEF=200;   V3K_DEF=32
fi
C3MAX="${TR12_C3MAX:-$C3MAX_DEF}"
SEED="${TR12_SEED:-9276183659154465378}"     # int(sha256("TR12-GALLERY-1")[:16],16), QUERY_INVENTORY §0.4(1)
Q8K="${TR12_Q8_K:-$Q8K_DEF}"
Q4ACM="${TR12_Q4AC_M:-$Q4ACM_DEF}"
Q1CM="${TR12_Q1C_M:-$Q1CM_DEF}"
V3K="${TR12_V3_K:-$V3K_DEF}"

# ================================================================================================
# NORMALISATION — the ONLY things stripped before a diff, and why each one has to be.
# ================================================================================================
# Every substitution below removes something that varies between two correct runs of the same
# binary on the same universe. Nothing else is touched: all counts, ranks, walks, shas, gate
# verdicts and provenance scope strings are diffed verbatim.
#
#   <FDIR>/<GDIR>/<TDIR>/<OUT>/<WORK>/<SOLVE>/<REPO>  absolute paths (mount point is the
#                                                     reproducer's choice, not a result)
#   <SELFTEST_TMP>        any mktemp scratch dir a self-contained gate makes for itself — both
#                         --selftest's and the ones --kc-scan-selftest prints in its [sidecar]
#                         lines. NOTE: this is why
#                         `./solve --selftest | sha256sum` is NOT a stable anchor — the
#                         canonical anchor is the Expected/Actual sha256 pair, which IS diffed.
#   git=<GIT> source_sha=<SRC>   build identity from -DGIT_HASH / -DSOURCE_SHA. Recorded
#                         separately in the run header (BUILD block) and diffed there; a
#                         reproducer builds from their own checkout and will differ.
#   branch=<BRANCH>       the #provenance trailer's branch field. Normalised since 2026-08-24.
#                         It USED to be a hard-coded string literal, so diffing it verbatim was
#                         harmless; commit 5f2b1e71 correctly made it report the branch actually
#                         built, which makes it BUILD-ENVIRONMENT-DEPENDENT. The published build
#                         line in documentation/VERIFY.md defines no branch, so a stranger's
#                         binary emits `branch=unknown` and every block carrying the trailer
#                         mismatched -- 11 of the 13 failures on a clean checkout. Which branch a
#                         reproducer built is not a result; git=/source_sha= already carry the
#                         build identity, and they are normalised here for exactly this reason.
#   <T>s / <T> us / <T> MB       wall-clock timings and derived rates.
#   peak_rss_mb=<RSS>            resident-set high-water mark (machine-dependent).
# ================================================================================================
norm(){
    local -a s=( -e "s#\\x00##g" )   # never empty: set -u would reject "${s[@]}" on an empty array
    [ -n "$FDIR" ]      && s+=( -e "s#${FDIR}#<FDIR>#g" )
    [ -n "$GDIR" ]      && s+=( -e "s#${GDIR}#<GDIR>#g" )
    [ -n "$TDIR" ]      && s+=( -e "s#${TDIR}#<TDIR>#g" )
    [ -n "$ARTDIR" ]    && s+=( -e "s#${ARTDIR}#<ART>#g" )
    [ -n "$OUTDIR" ]    && s+=( -e "s#${OUTDIR}#<OUT>#g" )
    [ -n "$SOLVE" ]     && s+=( -e "s#${SOLVE}#<SOLVE>#g" )
    [ -n "$WORK" ]      && s+=( -e "s#${WORK}#<WORK>#g" )
    [ -n "$REPO_ROOT" ] && s+=( -e "s#${REPO_ROOT}#<REPO>#g" )
    sed "${s[@]}" \
        -e 's#/tmp/solve_selftest_[A-Za-z0-9._]*#<SELFTEST_TMP>#g' \
        -e 's#/tmp/[A-Za-z0-9][A-Za-z0-9_.-]*_[A-Za-z0-9]\{6\}#<SELFTEST_TMP>#g' \
        -e 's#"engine_git": "[^"]*"#"engine_git": "<GIT>"#g' \
        -e 's#"engine_source_sha": "[^"]*"#"engine_source_sha": "<SRC>"#g' \
        -e 's#"git_hash": "[^"]*"#"git_hash": "<GIT>"#g' \
        -e 's#source_sha=[0-9A-Za-z._-]*#source_sha=<SRC>#g' \
        -e 's#git=[0-9A-Za-z._-]*#git=<GIT>#g' \
        -e 's#branch=[0-9A-Za-z._/-]*#branch=<BRANCH>#g' \
        -e 's#elapsed=[0-9.]*s#elapsed=<T>s#g' \
        -e 's#build_s=[0-9.]*#build_s=<T>#g' \
        -e 's#peak_rss_mb=[0-9.]*#peak_rss_mb=<RSS>#g' \
        -e 's#wall time [0-9.]*s#wall time <T>s#g' \
        -e 's# in [0-9.]*s# in <T>s#g' \
        -e 's#[0-9.]* us/#<T> us/#g' \
        -e 's#[0-9.]* MB/s#<T> MB/s#g' \
        -e 's#([0-9.]* s)#(<T> s)#g'
}

# ================================================================================================
# ROW + TOKEN MACHINERY
# ================================================================================================
declare -A TOKSTATE=()      # token -> PASS | FAIL:... | SKIP:...
declare -A TOKROWS=()       # token -> space separated row ids
declare -A TOKREASON=()     # token -> the long human reason for a skip
declare -a TOKORDER=()
declare -a SKIPPED=()
declare -a FAILED=()
NROWS=0; NPASS=0; NFAIL=0; NSKIP=0

tok_record(){   # tok_record TOKEN STATUS ROWID
    local t="$1" st="$2" id="$3"
    if [ -z "${TOKSTATE[$t]+x}" ]; then TOKORDER+=("$t"); TOKSTATE[$t]="$st"; TOKROWS[$t]="$id"
    else
        TOKROWS[$t]="${TOKROWS[$t]} $id"
        # FAIL dominates everything; a SKIPPED leg downgrades a PASS parent to SKIP.
        case "${TOKSTATE[$t]}" in
            FAIL*) : ;;
            *)     case "$st" in
                       FAIL*)         TOKSTATE[$t]="$st" ;;
                       SKIP*|PENDING*) case "${TOKSTATE[$t]}" in SKIP*|PENDING*) : ;; *) TOKSTATE[$t]="SKIP:leg-$id-not-run" ;; esac ;;
                       *)             : ;;
                   esac ;;
        esac
    fi
}

ROW_ID=""; RAW=""
row_begin(){ ROW_ID="$1"; RAW="$RAWDIR/$1.txt"; : > "$RAW"; }

row_end(){  # row_end TOKEN RC
    local token="$1" rc="$2"
    local got="$GOTDIR/$ROW_ID.txt" exp="$EXPECTDIR/$ROW_ID.txt" status
    norm < "$RAW" > "$got"
    NROWS=$((NROWS+1))
    if [ "$rc" -ne 0 ]; then
        status="FAIL:nonzero-exit($rc)"
    elif [ "$REGEN" -eq 1 ]; then
        mkdir -p "$EXPECTDIR"; cp "$got" "$exp"; status="PASS"
    elif [ ! -f "$exp" ]; then
        status="FAIL:no-expected-block"
    elif diff -u "$exp" "$got" > "$DIFFDIR/$ROW_ID.diff" 2>&1; then
        rm -f "$DIFFDIR/$ROW_ID.diff"; status="PASS"
    else
        status="FAIL:output-mismatch"
    fi
    case "$status" in
        PASS) NPASS=$((NPASS+1));  printf '  [ok  ] %-22s %s\n' "$ROW_ID" "$token" | tee -a "$LOG" ;;
        *)    NFAIL=$((NFAIL+1));  FAILED+=("$ROW_ID  $token  $status")
              printf '  [FAIL] %-22s %-24s %s\n' "$ROW_ID" "$token" "$status" | tee -a "$LOG"
              [ -f "$DIFFDIR/$ROW_ID.diff" ] && head -40 "$DIFFDIR/$ROW_ID.diff" | tee -a "$LOG" ;;
    esac
    tok_record "$token" "$status" "$ROW_ID"
    ROW_ID=""
}

row_skip(){ # row_skip ROWID TOKEN VALUE REASON
    # VALUE is the SHORT machine verdict — "SKIP:<code>" or "PENDING:<flag>" — so that
    #   grep -qx 'TR12_Q4B=PENDING:sat-c3min-driver'
    # works. REASON is the long human sentence; it goes to the skip report and to a separate
    # <TOKEN>_REASON line, never into the value.
    local id="$1" token="$2" value="$3" reason="$4"
    NROWS=$((NROWS+1)); NSKIP=$((NSKIP+1))
    SKIPPED+=("$id|$token|$value|$reason")
    TOKREASON[$token]="$reason"
    printf '  [SKIP] %-22s %-24s %-34s %s\n' "$id" "$token" "$value" "$reason" | tee -a "$LOG"
    tok_record "$token" "$value" "$id"
}

group(){ say ""; say "=== $* ==="; }

# convenience: run a solve subcommand into $RAW, return its rc
S(){ "$SOLVE" "$@" >>"$RAW" 2>&1; }

# ================================================================================================
# RUN HEADER
# ================================================================================================
say "TR-12 REPRODUCTION BATTERY  (TR12_QUERY_PROGRAM §R step 6 / §8 item 13)"
say "  universe        n=$N_PAIRS   N=$N_TOTAL   N mod 24 = $N_MOD24   N/24 = $N_DIV24"
say "  fdir            $FDIR"
say "  gdir            $GDIR"
say "  tdir            ${TDIR:-<none>}"
say "  solve           $SOLVE"
say "  expected blocks $EXPECTDIR$( [ "$REGEN" -eq 1 ] && echo '   (REGEN — writing, not diffing)')"
say "  artifacts       $OUTDIR"
say "  knobs           C3MAX=$C3MAX SEED=$SEED Q8_K=$Q8K Q4AC_M=$Q4ACM Q1C_M=$Q1CM V3_K=$V3K"
say ""
if [ "$N_MOD24" != "0" ]; then
    say "  🔴 N mod 24 = $N_MOD24, not 0 — the kernel-backed divisibility invariant is violated."
    say "     Refusing to run a battery whose universe is already known to be wrong."
    printf 'TR12_REPRO=FAIL\n' | tee -a "$VERD" >/dev/null
    say "TR12_REPRO=FAIL"; exit 1
fi
if [ "$REGEN" -eq 0 ] && [ ! -d "$EXPECTDIR" ]; then
    say "  🔴 No expected-block directory for n=$N_PAIRS at:"
    say "         $EXPECTDIR"
    say "     A battery with nothing to diff against cannot pass. Mint the blocks with --regen"
    say "     (and review them before they are committed), or point --expect at the right set."
    printf 'TR12_REPRO=FAIL\n' >> "$VERD"
    printf 'TR12_REPRO_REASON=no-expected-block-set-for-n%s\n' "$N_PAIRS" >> "$VERD"
    say ""; say "TR12_REPRO=FAIL"; exit 1
fi

# ================================================================================================
# GROUP A0 — PRE-SCAN, NO LADDER.  Bank everything free first.  (QUERY_INVENTORY §5 Group A0)
# ================================================================================================
group "GROUP A0 — no ladder, \$0"

# ---- A0.0  the build anchor: --selftest must still produce the canonical enumeration sha ------
row_begin a0_build
( "$SOLVE" --selftest ) >>"$RAW" 2>&1; rc=$?
{ printf 'SELFTEST_EXPECTED_EQ_ACTUAL='
  e=$(sed -n 's/.*Expected sha256: *\([0-9a-f]*\).*/\1/p' "$RAW" | head -1)
  a=$(sed -n 's/.*Actual sha256: *\([0-9a-f]*\).*/\1/p'   "$RAW" | head -1)
  if [ -n "$e" ] && [ "$e" = "$a" ]; then echo YES; else echo NO; fi
} >>"$RAW"
row_end TR12_BUILD $rc

# ---- A0.1  every free brute-force gate.  Exit status is the contract (VERIFY.md);  the four
#            newest gates also emit a KEY=value token, which is matched with grep -qx. ---------
row_begin a0_gates
(
  fails=0
  for g in --check-arrangement-selftest --kc-selftest --kc-o3-selftest --kc-g-selftest \
           --kc-t-selftest --kc-cert-selftest --kc-ladder-selftest --kc-ar2-selftest \
           --kc-oracle-selftest --kc-scan-selftest --f1c5-gzip-selftest; do
      if "$SOLVE" "$g" >/dev/null 2>&1; then echo "GATE $g rc=0"; else echo "GATE $g rc=NONZERO"; fails=1; fi
  done
  # gates that carry a real verdict token — decided by grep -qx on the token, not by output shape
  for pair in "--kc-enum-desc-selftest:KC_ENUM_DESC_SELFTEST=PASS" \
              "--kc-profile-selftest:KC_PROFILE_SELFTEST=PASS" \
              "--kc-layers-selftest:KC_LAYERS_SELFTEST=PASS" \
              "--kc-extremal-selftest:KC_EXTREMAL_SELFTEST=PASS"; do
      g="${pair%%:*}"; want="${pair#*:}"
      out=$("$SOLVE" "$g" 2>&1); grc=$?
      if [ "$grc" -eq 0 ] && printf '%s\n' "$out" | grep -qx "$want"; then
          echo "GATE $g rc=0 token=$want"
      else
          echo "GATE $g rc=$grc token=MISSING($want)"; fails=1
      fi
  done
  exit $fails
) >>"$RAW" 2>&1; rc=$?
row_end TR12_GATES $rc

# ---- A0.2  XA(iii): the t-unit accounting-convention pin.  No atlas number ships before it. ---
row_begin a0_xa_iii
( "$SOLVE" --kc-t-cert "$ARTDIR/xa_node_convention.json" && cat "$ARTDIR/xa_node_convention.json" ) >>"$RAW" 2>&1; rc=$?
row_end TR12_XA_III $rc

# ---- A0.3  Q7 leg 1: King Wen through the independent first-principles checker (no ladder) ----
row_begin a0_q7_kw
( "$SOLVE" --check-arrangement KW --cert-out "$ARTDIR/q7_kw.json" && cat "$ARTDIR/q7_kw.json" ) >>"$RAW" 2>&1; rc=$?
row_end TR12_Q7_KW $rc

# ---- A0.3b Q7 leg 2: the three historical arrangements.  Their hexagram lists live in the
#            repo's existing solve.py; there is no --check-arrangement name lookup, so this is
#            the one python3 call in the battery (QUERY_INVENTORY §2 row Q7). --------------------
if command -v python3 >/dev/null 2>&1 && [ -f "$REPO_ROOT/solve.py" ] \
   && PYTHONPATH="$REPO_ROOT" python3 -c 'import solve' >/dev/null 2>&1; then
    row_begin a0_q7_hist
    (
      hrc=0
      for fn in _r7_mawangdui _r7_fuxi _r7_jingfang; do
          A=$(cd "$REPO_ROOT" && PYTHONPATH="$REPO_ROOT" python3 -c \
              "import solve;print(','.join(map(str,solve.$fn())))" 2>/dev/null)
          if [ -z "$A" ]; then echo "ARRANGEMENT $fn UNAVAILABLE"; hrc=1; continue; fi
          echo "### $fn"
          "$SOLVE" --check-arrangement "$A" --cert-out "$ARTDIR/q7_${fn#_r7_}.json"
          # a historical arrangement is EXPECTED to be OUT; the row diffs the verdict either way,
          # so a non-zero exit here is information, not a failure — record it and continue.
          echo "### $fn checker_rc=$?"
      done
      exit $hrc
    ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_Q7_HIST $rc
else
    row_skip a0_q7_hist TR12_Q7_HIST "SKIP:python3-unavailable" \
      "python3+solve.py unavailable — the 3 historical arrangements (_r7_mawangdui/_r7_fuxi/_r7_jingfang) could not be materialised"
fi

# ---- A0.4  LS-w0: TR-8's pair-only null (C1-only space, near closed form, no ladder) ----------
row_begin a0_ls_w0
( "$SOLVE" --null-pair-constrained 1000000 ) >>"$RAW" 2>&1; rc=$?
row_end TR12_LS_W0 $rc

# ---- A0.5  Q4(b): SAT C3-min bisection.  PENDING, and its whole toolchain is absent. ----------
{
  miss=""
  for t in kissat drat-trim d4 cpog-gen; do command -v "$t" >/dev/null 2>&1 || miss="$miss $t"; done
  if [ -n "$miss" ]; then
      row_skip a0_q4b TR12_Q4B "PENDING:sat-c3min-driver" "PENDING:sat-c3min-driver — and the toolchain is absent (missing:$miss); sat.py also invokes kissat without a proof flag, so DRAT emission is itself PENDING (QUERY_INVENTORY §3.4)"
  else
      row_skip a0_q4b TR12_Q4B "PENDING:sat-c3min-driver" "PENDING:sat-c3min-driver — the bisection loop over sat.py --with-c3 --c3-max \$((16+8*G)), G in [12,47], does not exist yet (QUERY_INVENTORY §1)"
  fi
}

# ---- A0.6  the writing-only rows.  They have no command, so this driver cannot attest them.
#            Reported as skipped with the reason, never folded into a PASS. --------------------
row_skip a0_q9        TR12_Q9        "SKIP:doc-only" "DOC-only: Q9 is certified restatement of the reportable negatives (tr12/q9_negatives.md); no executable command exists to diff"
row_skip a0_ls_forced8 TR12_LS_FORCED8 "SKIP:doc-only" "DOC-only: citation row; and lean/C1RuleConstants.lean is NOT an ancestor of this branch (QUERY_INVENTORY §3.3) — cite by commit sha with the branch stated"
row_skip a0_ls_cite   TR12_LS_CITE   "SKIP:doc-only" "DOC-only: the sweep cites, it does not recompute"
row_skip a0_ls_audit  TR12_LS_AUDIT  "SKIP:doc-only" "DOC-only: the D-B1 circularity audit is a review protocol, not a computation"
row_skip a0_q4_gexact TR12_Q4_GEXACT "SKIP:doc-only" "DOC-only: transcription of the already-derived exact C1∩C4 null law of G (C3_CONDITIONAL_VS_NULL_LAW_20260812.md)"
row_skip a0_ew_gov    TR12_EW_GOV    "SKIP:doc-only" "DOC-only: pre-registration + content hash into PREREG_LOCK_LEDGER.txt happens before any tail computation"
row_skip a0_ls_exact  TR12_LS_EXACT  "SKIP:wave3-not-budgeted" "wave3-not-budgeted (§7 operator ruling) AND blocked on the --kc-oracle property-channel grammar, which does not exist"

# ================================================================================================
# THE ANCHOR WALK
# ================================================================================================
# TR-12's Q1/Q1b/Q1c/Q3/EW-1/V4 are all "…of KW".  KW only exists in the full-31 universe, so the
# reduced universes need a *stated* stand-in rather than a silent one:
#
#   n = 31   ANCHOR = KW.  The literal string "KW" is resolved by --kc-o3-cert / --kc-ar2 /
#            --kc-profile ONLY; --kc-o3-rank / --kc-rank / --kc-member call kc_parse_walk and
#            REJECT it (QUERY_INVENTORY §0.4(3)).  So the driver materialises the 62-value walk
#            once — dropping the C4-anchored pair (63,0), which is slot 0 and not part of the
#            walk (§0.4(2)) — and passes the string everywhere except --kc-o3-cert.
#   n < 31   ANCHOR = unrank_O3(floor(N/2)).  Deterministic, mid-space (so the Q1 neighbour
#            bracket is non-trivial in both directions), and its O3 rank is known a priori, which
#            makes Q1 a rank/unrank roundtrip certificate for free.  Labelled as a stand-in in
#            every artifact; nothing in the reduced run is ever reported as a KW result.
# ================================================================================================
ANCHOR=""; ANCHOR_LABEL=""; ANCHOR_SRC=""
if [ "$N_PAIRS" -ge 31 ]; then
    ANCHOR_LABEL="KW"
    if command -v python3 >/dev/null 2>&1 && [ -f "$REPO_ROOT/solve.py" ]; then
        ANCHOR=$(cd "$REPO_ROOT" && PYTHONPATH="$REPO_ROOT" python3 -c \
                 "import solve;print(','.join(map(str,solve._r7_kw()[2:])))" 2>/dev/null || true)
        [ -n "$ANCHOR" ] && ANCHOR_SRC="solve.py:_r7_kw()[2:]"
    fi
    if [ -z "$ANCHOR" ]; then
        # shell-only fallback: --kc-profile resolves "KW" itself and prints entry/exit per step,
        # which reassembles the walk string exactly.
        ANCHOR=$("$SOLVE" --kc-profile "$FDIR" "$GDIR" KW 2>/dev/null \
                 | awk -F'\t' '$1 ~ /^[0-9]+$/ {printf "%s%s,%s", (n++?",":""), $3, $4} END{print ""}')
        [ -n "$ANCHOR" ] && ANCHOR_SRC="--kc-profile FDIR GDIR KW (entry/exit columns)"
    fi
else
    ANCHOR_LABEL="O3-MIDPOINT(unrank_O3(floor(N/2)))"
    ANCHOR=$("$SOLVE" --kc-o3-unrank "$FDIR" "$GDIR" "$N_HALF" 2>/dev/null \
             | grep -E '^[0-9]+(,[0-9]+)+$' | head -1)
    ANCHOR_SRC="--kc-o3-unrank FDIR GDIR $N_HALF"
fi
[ -n "$ANCHOR" ] || die "could not materialise the anchor walk for n=$N_PAIRS"

row_begin a0_anchor
{
  echo "universe_n=$N_PAIRS"
  echo "N_total=$N_TOTAL"
  echo "N_minus_1=$N_MINUS_1"
  echo "N_half=$N_HALF"
  echo "N_mod_24=$N_MOD24"
  echo "N_div_24=$N_DIV24"
  echo "anchor_label=$ANCHOR_LABEL"
  echo "anchor_source=$ANCHOR_SRC"
  echo "anchor_values=$(printf '%s' "$ANCHOR" | tr ',' '\n' | grep -c .)"
  echo "anchor_walk=$ANCHOR"
  echo "c3_max_used=$C3MAX"
  [ "$N_PAIRS" -ge 31 ] && [ "$C3MAX" != "387" ] && echo "🔴 WARNING: at n=31 the C3 walk-functional gate is 387, NEVER 776 — got $C3MAX"
  echo -n "anchor_is_member="; "$SOLVE" --kc-member "$FDIR" "$ANCHOR" 2>&1 | tail -1
} >>"$RAW" 2>&1; rc=$?
row_end TR12_ANCHOR $rc

# ================================================================================================
# GROUP A1 — f-ladder only.   (QUERY_INVENTORY §5 Group A1)
# ================================================================================================
group "GROUP A1 — f-ladder mounted"

# ---- A1.1  the 32 f-layer decompressed-stream shas, before trusting any number ----------------
row_begin a1_fsha
( "$SOLVE" --f1c5-layer-sha "$FDIR" ) >>"$RAW" 2>&1; rc=$?
row_end TR12_FSHA $rc

# ---- A1.0  the INDEPENDENT reading-(B) extremes oracle ------------------------------
# Q6's per-(state,choice) argmax/argmin leg is SKIPPED by the engine (the atlas schema does not
# serve it). This row exists anyway, and it is not decoration: the oracle below is the
# operational DEFINITION of reading (B), and it has already REJECTED TWO implementations
# written from the prose (2026-08-22 and 2026-08-24), which produced two different wrong
# answers. Until 2026-08-24 it existed only inside a chat transcript -- a load-bearing gate one
# lost scrollback from being unreproducible.
#
# The walk list is REGENERATED here by --kc-enum-desc, never committed: it is 1.3 MB at n=9 and
# a data file is the wrong artifact. n>9 is refused rather than attempted -- the walk count at
# n=13 is 2.06e12.
if [ "$N_PAIRS" -le 9 ] && command -v python3 >/dev/null 2>&1 && [ -f "$REPO_ROOT/verify.py" ]; then
    row_begin a1_q6_oracle
    (
      "$SOLVE" --kc-enum-desc "$FDIR" 2>/dev/null \
        | grep -E '^[0-9]+(,[0-9]+)+$' > "$WORK/q6_walks.txt"
      echo "# walks regenerated by --kc-enum-desc: $(wc -l < "$WORK/q6_walks.txt")"
      python3 "$REPO_ROOT/verify.py" --q6-extremes-oracle "$WORK/q6_walks.txt"
    ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_Q6_ORACLE $rc
elif [ "$N_PAIRS" -gt 9 ]; then
    row_skip a1_q6_oracle TR12_Q6_ORACLE "SKIP:universe-too-large" \
      "the oracle enumerates every walk; that is 26,112 at n=9 and 2.06e12 at n=13 — refused, not attempted"
else
    row_skip a1_q6_oracle TR12_Q6_ORACLE "SKIP:python3-unavailable" \
      "python3 or verify.py unavailable — the independent reading-(B) oracle could not be run"
fi

# ---- A1.2  Q8 the exemplar gallery: exact-uniform draws under the pinned seed -----------------
row_begin a1_q8_super
( "$SOLVE" --kc-sample "$FDIR" "$Q8K" "$SEED" --kc-record ) >>"$RAW" 2>&1; rc=$?
cp "$RAW" "$ARTDIR/q8_super.tsv"
row_end TR12_Q8_SUPER $rc

row_begin a1_q8_c15
( "$SOLVE" --kc-sample "$FDIR" "$Q8K" "$SEED" --kc-c3-max "$C3MAX" --kc-record ) >>"$RAW" 2>&1; rc=$?
cp "$RAW" "$ARTDIR/q8_c15.tsv"
row_end TR12_Q8_C15 $rc

# ---- A1.2b membership re-check of EVERY gallery draw through the independent membership path --
row_begin a1_q8_member
(
  bad=0; n=0
  while IFS=$'\t' read -r _rank _cd walk; do
      case "$_rank" in ''|*[!0-9]*) continue ;; esac
      n=$((n+1))
      if ! "$SOLVE" --kc-member "$FDIR" "$walk" 2>/dev/null | grep -qx 'MEMBER'; then
          echo "NON-MEMBER draw rank=$_rank walk=$walk"; bad=$((bad+1))
      fi
  done < "$ARTDIR/q8_super.tsv"
  echo "q8_member_rechecked=$n"
  echo "q8_member_failures=$bad"
  exit $(( bad ? 1 : 0 ))
) >>"$RAW" 2>&1; rc=$?
row_end TR12_Q8_MEMBER $rc

# ---- A1.2c the chi-square uniformity plumbing gate (its own reduced universe, n=13) -----------
row_begin a1_q8_chi2
( "$SOLVE" --kc-midn 13 --kc-chi2-samples 20000 ) >>"$RAW" 2>&1; rc=$?
row_end TR12_Q8_CHI2 $rc

# ---- A1.3  Q4(a,c) the C3 census — histogram of the walk-functional cd over exact-uniform draws.
#            ESTIMATE with CI; the exact C15 count is OPEN (C3 counting obstruction). ----------
row_begin a1_q4ac
(
  "$SOLVE" --kc-sample "$FDIR" "$Q4ACM" "$SEED" 2>/dev/null > "$WORK/q4.raw" || exit 1
  awk -v M="$Q4ACM" -v T="$C3MAX" '
    /^[0-9]/ { if (match($0,/cd=[0-9]+/)) { v=substr($0,RSTART+3,RLENGTH-3)+0; h[v]++; n++; if (v<=T) le++ } }
    END{
      printf "# Q4(a,c) C3 census — ESTIMATE over SUPER, space=C1C2C4C5-SUPERSPACE\n"
      printf "# walk-functional units (cd_true = 2*(walk_cd+1)); threshold used T=%d\n", T
      printf "requested_M\t%d\nrealised_M\t%d\n", M, n
      printf "cd\tcount\tfraction\n"
      k=0; for (v in h) a[k++]=v+0
      for (i=0;i<k;i++) for (j=i+1;j<k;j++) if (a[j]<a[i]) { t=a[i];a[i]=a[j];a[j]=t }
      for (i=0;i<k;i++) printf "%d\t%d\t%.6f\n", a[i], h[a[i]], h[a[i]]/n
      p = (n? le/n : 0)
      # Wilson score interval, 95%
      z=1.959964; d=1+z*z/n; c=(p+z*z/(2*n))/d; hw=z*sqrt(p*(1-p)/n + z*z/(4*n*n))/d
      printf "p_hat_cd_le_T\t%.8f\n", p
      printf "wilson95_lo\t%.8f\nwilson95_hi\t%.8f\n", (c-hw<0?0:c-hw), (c+hw>1?1:c+hw)
      printf "label\tESTIMATE-with-CI (exact C15 count is OPEN)\n"
    }' "$WORK/q4.raw"
) >>"$RAW" 2>&1; rc=$?
cp "$RAW" "$ARTDIR/q4_c3_hist.tsv"
row_end TR12_Q4AC $rc

# a degenerate C3 threshold would make every C15 leg silently equal to SUPER — say so out loud
FRAC_LE=$(awk -F'\t' '$1=="p_hat_cd_le_T"{print $2}' "$ARTDIR/q4_c3_hist.tsv" 2>/dev/null || echo "")
DEGEN=NO
if [ -n "$FRAC_LE" ]; then
    case "$FRAC_LE" in
        1.00000000|0.00000000) DEGEN=YES ;;
    esac
fi
say "  C3 filter at T=$C3MAX retains p_hat=${FRAC_LE:-?}  (degenerate: $DEGEN)"

# ---- A1.4  Q2(b) the REL-order endpoints:  0, N-1, floor(N/2) --------------------------------
row_begin a1_q2b
(
  erc=0
  for R in 0 "$N_MINUS_1" "$N_HALF"; do
      echo "### REL unrank r=$R"
      "$SOLVE" --kc-unrank "$FDIR" "$R" --kc-record || erc=1
  done
  exit $erc
) >>"$RAW" 2>&1; rc=$?
row_end TR12_Q2B $rc

# ---- A1.5  Q2(c) FIRST^C15 — the in-order-least C3-passing walk (REL order) -------------------
row_begin a1_q2c
( "$SOLVE" --kc-enum "$FDIR" --kc-c3-max "$C3MAX" --kc-limit 1 ) >>"$RAW" 2>&1; rc=$?
row_end TR12_Q2C $rc

# ---- A1.6  Q2(d) LAST^C15 — the in-order-greatest C3-passing walk.  --kc-enum-desc has landed;
#            its n=9 exhaustive gate ran in row a0_gates and carries a KEY=value token. ---------
if "$SOLVE" --kc-enum-desc "$FDIR" --kc-limit 1 >/dev/null 2>&1; then
    row_begin a1_q2d
    ( "$SOLVE" --kc-enum-desc "$FDIR" --kc-c3-max "$C3MAX" --kc-limit 1 ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_Q2D $rc
else
    row_skip a1_q2d TR12_Q2D "PENDING:--kc-enum-desc" "PENDING:--kc-enum-desc — this binary does not accept it"
fi

# ---- A1.7  Q1(b) the REL-order second coordinate.  A DIFFERENT order from O3; labelled. ------
row_begin a1_q1b
( echo "order=REL (reverse-exit-lex; NOT O3 — never conflate the two)"
  echo -n "rel_rank($ANCHOR_LABEL)="; "$SOLVE" --kc-rank "$FDIR" "$ANCHOR" ) >>"$RAW" 2>&1; rc=$?
row_end TR12_Q1B $rc

# ---- A1.8  V3 the REL rank spectrum on a systematic grid r = i*floor(N/K) ---------------------
#            NOTE at full-31 this is the measured 31.4 min row and each --kc-unrank pays its own
#            cold descent; there is no batch flag, so the loop below IS the inventory's command.
row_begin a1_v3
(
  step=$(echo "$N_TOTAL / $V3K" | bc)
  echo "# V3 REL grid: K=$V3K  step=floor(N/K)=$step"
  echo -e "i\tr\twalk"
  erc=0; i=0
  while [ "$i" -lt "$V3K" ]; do
      R=$(echo "$i * $step" | bc)
      W=$("$SOLVE" --kc-unrank "$FDIR" "$R" 2>/dev/null | grep -E '^[0-9]+(,[0-9]+)+$' | head -1) || erc=1
      [ -n "$W" ] || { echo "MISSING r=$R"; erc=1; }
      printf '%d\t%s\t%s\n' "$i" "$R" "$W"
      i=$((i+1))
  done
  exit $erc
) >>"$RAW" 2>&1; rc=$?
cp "$RAW" "$ARTDIR/v3_rel_grid.tsv"
row_end TR12_V3_TSV $rc

# ---- A1.9  Q5 functional extremals.  --kc-extremal has landed (in-memory v1, n<=22), so the
#            reduced universes run it for free.  At full-31 it is SCAN-class per functional and
#            §7 rules wave 3 NOT BUDGETED — it stays skipped unless --wave3 is passed. ---------
if [ "$N_PAIRS" -ge 31 ] && [ "$WAVE3" -eq 0 ]; then
    row_skip a1_q5 TR12_Q5 "SKIP:wave3-not-budgeted" "wave3-not-budgeted (§7 operator ruling): one full Stage-F-shaped pass per functional, \$40–80 each. Pass --wave3 to run it anyway."
elif ! "$SOLVE" --kc-extremal list >/dev/null 2>&1; then
    row_skip a1_q5 TR12_Q5 "PENDING:--kc-extremal" "PENDING:--kc-extremal — this binary does not accept it"
else
    row_begin a1_q5
    (
      erc=0
      "$SOLVE" --kc-extremal list || erc=1
      for f in $("$SOLVE" --kc-extremal list 2>/dev/null | awk -F'\t' 'NR>1 && $1 !~ /^#/ && $1 !~ /=/ && $1!="" {print $1}'); do
          for dir in max min; do
              echo "### $f $dir"
              "$SOLVE" --kc-extremal "$f" "$FDIR" "$dir" --kc-witness --kc-gdir "$GDIR" ; frc=$?
              echo "### $f $dir rc=$frc"
              # posyang0 is the negative control: it MUST trip KC_EXTREMAL_INVARIANT=no and exit
              # non-zero. Any other functional exiting non-zero is a real failure.
              if [ "$f" = "posyang0" ]; then
                  [ "$frc" -eq 0 ] && { echo "CONTROL-DID-NOT-TRIP: posyang0 passed the invariance gate"; erc=1; }
              else
                  [ "$frc" -ne 0 ] && erc=1
              fi
          done
      done
      exit $erc
    ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_Q5 $rc
fi

# ================================================================================================
# GROUP A2 — f + g mounted.   Q3 / Q3-reader / EW-1 / V4 are PRE-SCAN (QUERY_INVENTORY §6).
# ================================================================================================
group "GROUP A2 — f + g mounted (still pre-scan)"

row_begin a2_gsha
( "$SOLVE" --f1c5-layer-sha "$GDIR" ) >>"$RAW" 2>&1; rc=$?
row_end TR12_GSHA $rc

# ---- A2.2  Q1 the H3b rank certificate: rank/unrank roundtrip + the r-1/r/r+1 bracket ---------
row_begin a2_q1
( "$SOLVE" --kc-o3-cert "$FDIR" "$GDIR" "$ANCHOR" --kc-cert-out "$ARTDIR/q1_rank.json" \
  && echo "### certificate JSON" && cat "$ARTDIR/q1_rank.json" ) >>"$RAW" 2>&1; rc=$?
row_end TR12_Q1 $rc

# ---- A2.3  Q3 the 31-step rarity profile via the O3 descent trace + neighbour bracket ---------
row_begin a2_q3
( "$SOLVE" --kc-o3-rank "$FDIR" "$GDIR" "$ANCHOR" --kc-trace --kc-bracket ) >>"$RAW" 2>&1; rc=$?
cp "$RAW" "$ARTDIR/q3_profile.txt"
grep '^#o3-trace' "$ARTDIR/q3_profile.txt" > "$ARTDIR/q3_profile.tsv" 2>/dev/null || true
row_end TR12_Q3 $rc

# ---- A2.3b Q3 cross-instrument: --kc-profile recomputes the same profile by an independent
#            path and emits exact rationals (p_num/p_den) plus the alternatives at each step. ---
if "$SOLVE" --kc-profile "$FDIR" "$GDIR" "$ANCHOR" >/dev/null 2>&1; then
    row_begin a2_q3_profile
    ( "$SOLVE" --kc-profile "$FDIR" "$GDIR" "$ANCHOR" --kc-tsv "$ARTDIR/q3_profile_exact.tsv" --kc-alts ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_Q3_PROFILE $rc
else
    row_skip a2_q3_profile TR12_Q3_PROFILE "PENDING:--kc-profile" "PENDING:--kc-profile — this binary does not accept it"
fi

# ---- A2.4  Q3 READER arithmetic.  QUERY_INVENTORY §3.2: the engine printing
#            "product(p_i)=1/N EXACT" is the ENGINE attesting.  TR-12 §R step 7 wants the READER
#            to redo it.  Prod_i (p_num_i / p_den_i) = 1/N telescopes iff
#                p_den_1 == N,   p_den_i == p_num_{i-1} for i>1,   p_num_n == 1
#            — three exact integer identities, no big-int arithmetic library needed, decided here
#            by string comparison over the emitted columns.  This does not read the engine's own
#            summary line at all; it is checked against the columns.
if [ -s "$ARTDIR/q3_profile_exact.tsv" ]; then
    row_begin a2_q3_reader
    (
      awk -F'\t' -v N="$N_TOTAL" -v NP="$N_PAIRS" '
        $1 ~ /^[0-9]+$/ {
            step[++k]=$1; pn[k]=$11; pd[k]=$12; g[k]=$9; gp[k]=$10
        }
        END{
            fails=0
            printf "reader_steps\t%d\n", k
            if (k != NP+0) { printf "READER_FAIL\tstep count %d != n %d\n", k, NP; fails++ }
            if (pd[1] != N) { printf "READER_FAIL\tp_den[1]=%s != N=%s\n", pd[1], N; fails++ }
            else printf "reader_p_den_1_eq_N\tOK (%s)\n", pd[1]
            for (i=2;i<=k;i++) if (pd[i] != pn[i-1]) { printf "READER_FAIL\tp_den[%d]=%s != p_num[%d]=%s\n", i, pd[i], i-1, pn[i-1]; fails++ }
            if (fails==0) printf "reader_telescoping\tOK (%d links)\n", k-1
            if (pn[k] != "1") { printf "READER_FAIL\tp_num[%d]=%s != 1\n", k, pn[k]; fails++ }
            else printf "reader_p_num_n_eq_1\tOK\n"
            for (i=1;i<=k;i++) { if (g[i]!=pn[i] || gp[i]!=pd[i]) { printf "READER_FAIL\tstep %d: (g,g_parent)=(%s,%s) != (p_num,p_den)=(%s,%s)\n", i,g[i],gp[i],pn[i],pd[i]; fails++ } }
            printf "reader_product_p_i\t1/%s EXACT (telescoping, re-derived by the reader from the columns)\n", N
            printf "READER_FAILS\t%d\n", fails
            exit (fails?1:0)
        }' "$ARTDIR/q3_profile_exact.tsv"
    ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_Q3_READER $rc
else
    row_skip a2_q3_reader TR12_Q3_READER "SKIP:no-profile-tsv" "needs the exact-rational profile TSV from --kc-profile --kc-tsv (row a2_q3_profile); the --kc-trace text carries p as a display fraction only"
fi

# ---- A2.5  EW-1 the surprise-localisation ledger.  Rides Q3; NOT the scan. --------------------
if [ -s "$ARTDIR/q3_profile_exact.tsv" ]; then
    row_begin a2_ew1
    (
      awk -F'\t' -v N="$N_TOTAL" '
        BEGIN{ printf "# EW-1 surprise ledger — bits_i = -log2 p_i, decomposing log2 N\n"
               printf "step\tpair\tdclass\talts\tbits\n" }
        $1 ~ /^[0-9]+$/ { printf "%s\t%s\t%s\t%s\t%s\n", $1,$2,$6,$7,$13; s+=$13; n++
                          if ($13+0>mx){mx=$13+0;mxs=$1} }
        END{
            printf "sum_bits\t%.6f\n", s
            # log2(N) via natural log; N is a decimal string, awk carries it as a double — that is
            # display precision only, which is why the EXACT statement lives in the reader row.
            l2 = log(N)/log(2)
            printf "log2N\t%.6f\n", l2
            d = s-l2; if (d<0) d=-d
            printf "abs_diff\t%.9f\n", d
            printf "max_surprise_step\t%s\nmax_surprise_bits\t%.6f\n", mxs, mx
            printf "concentration_top1_share\t%.6f\n", (s? mx/s : 0)
            printf "interpretation_contract\tPRE-FIXED: concentration => where an undiscovered constraint must live; near-uniform typicality => boundable evidence that no further simple positional constraint exists. BOTH outcomes are findings.\n"
            if (d > 1e-4) { printf "EW1_FAIL\tsum_bits != log2N within 1e-4\n"; exit 1 }
            printf "EW1_SUM_EQ_LOG2N\tOK\n"
        }' "$ARTDIR/q3_profile_exact.tsv"
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/ew1_spectrum.tsv"
    row_end TR12_EW1 $rc
else
    row_skip a2_ew1 TR12_EW1 "SKIP:no-profile-tsv" "rides Q3's exact-rational profile TSV, which was not produced"
fi

# ---- A2.6  V4 the shells series g(prefix_k) vs k.  The TSV; the FIGURE is PENDING:viz. --------
if [ -s "$ARTDIR/q3_profile_exact.tsv" ]; then
    row_begin a2_v4
    ( awk -F'\t' 'BEGIN{print "k\tg\tg_parent\tf"} $1 ~ /^[0-9]+$/ {printf "%s\t%s\t%s\t%s\n",$1,$9,$10,$8}' \
        "$ARTDIR/q3_profile_exact.tsv" ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/v4_shells.tsv"
    row_end TR12_V4_TSV $rc
else
    row_skip a2_v4 TR12_V4_TSV "SKIP:no-profile-tsv" "rides Q3's exact-rational profile TSV, which was not produced"
fi

# ---- A2.7  Q2 the O3-order endpoints:  0, N-1, floor(N/2) ------------------------------------
row_begin a2_q2
(
  erc=0
  for R in 0 "$N_MINUS_1" "$N_HALF"; do
      echo "### O3 unrank r=$R"
      "$SOLVE" --kc-o3-unrank "$FDIR" "$GDIR" "$R" || erc=1
  done
  exit $erc
) >>"$RAW" 2>&1; rc=$?
row_end TR12_Q2 $rc

# ---- A2.8  Q7 ranks: the O3 rank of each arrangement that is IN.  The §0.4(2) adapter drops the
#            C4-anchored pair (63,0).  Only meaningful in the full-31 universe. -----------------
if [ "$N_PAIRS" -ge 31 ]; then
    row_begin a2_q7_ranks
    (
      erc=0
      for j in "$ARTDIR"/q7_*.json; do
          [ -f "$j" ] || continue
          v=$(sed -n 's/.*"verdict_super": "\([^"]*\)".*/\1/p' "$j" | head -1)
          lab=$(sed -n 's/.*"label": "\([^"]*\)".*/\1/p' "$j" | head -1)
          arr=$(sed -n 's/.*"arrangement": "\([^"]*\)".*/\1/p' "$j" | head -1)
          echo "### $(basename "$j") label=$lab verdict_super=$v"
          if [ "$v" = "IN" ] && [ -n "$arr" ]; then
              # §0.4(2): drop the first two values (the C4-anchored pair 63,0), pass the rest
              w=$(printf '%s' "$arr" | cut -d, -f3-)
              "$SOLVE" --kc-o3-rank "$FDIR" "$GDIR" "$w" || erc=1
          else
              echo "(not IN — no rank; a rank of a non-member is not defined)"
          fi
      done
      exit $erc
    ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_Q7_RANKS $rc
else
    row_skip a2_q7_ranks TR12_Q7_RANKS "SKIP:reduced-universe" "the historical arrangements are 64-hexagram objects; they have no image in the reduced n=$N_PAIRS universe"
fi

# ---- A2.9  Q1(c) the C15 rank estimate.  QUERY_INVENTORY §3.5: --kc-sample draws over ALL of
#            SUPER and has no rank-range argument, so the "[0, rank_O3(anchor))" restriction is
#            post-filter arithmetic here.  The REALISED M is reported, never the requested M.
#            Note --kc-sample --kc-c3-max returns exactly M accepted draws and does NOT report
#            its rejection rate, so p-hat is taken from the UNFILTERED draws' cd column. --------
row_begin a2_q1c
(
  RANCH=$("$SOLVE" --kc-o3-rank "$FDIR" "$GDIR" "$ANCHOR" 2>/dev/null | awk -F'\t' '$1=="rank3"{print $2}')
  if [ -z "$RANCH" ]; then echo "could not obtain rank_O3(anchor)"; exit 1; fi
  echo "# Q1(c) — labelled ESTIMATE with binomial CI. Space: C15 rank is NOT exactly computable."
  echo "rank_O3_anchor	$RANCH"
  echo "requested_M	$Q1CM"
  "$SOLVE" --kc-sample "$FDIR" "$Q1CM" "$SEED" 2>/dev/null > "$WORK/q1c.raw" || exit 1
  : > "$WORK/q1c.ranks"
  while IFS=$'\t' read -r _r _cd walk; do
      case "$_r" in ''|*[!0-9]*) continue ;; esac
      cd_v=${_cd#cd=}
      o3=$("$SOLVE" --kc-o3-rank "$FDIR" "$GDIR" "$walk" 2>/dev/null | awk -F'\t' '$1=="rank3"{print $2}')
      [ -n "$o3" ] && printf '%s\t%s\n' "$o3" "$cd_v" >> "$WORK/q1c.ranks"
  done < "$WORK/q1c.raw"
  awk -F'\t' -v R="$RANCH" -v T="$C3MAX" '
    { drawn++
      # decimal-string compare: shorter is smaller; equal length falls back to lexicographic
      a=$1 ""; r=R ""
      keep = (length(a)<length(r)) || (length(a)==length(r) && a<r)
      if (keep) { m++; if ($2+0<=T) le++ } }
    END{
      printf "drawn_M\t%d\n", drawn
      printf "realised_M_in_rank_prefix\t%d\n", m
      if (m==0) { printf "Q1C_FAIL\tno draw fell below the anchor rank; CI undefined\n"; exit 1 }
      p=le/m; z=1.959964; d=1+z*z/m; c=(p+z*z/(2*m))/d
      hw=z*sqrt(p*(1-p)/m + z*z/(4*m*m))/d
      printf "p_hat_C15_given_rank_lt_anchor\t%.8f\n", p
      printf "wilson95_lo\t%.8f\nwilson95_hi\t%.8f\n", (c-hw<0?0:c-hw), (c+hw>1?1:c+hw)
      printf "label\tESTIMATE +- binomial CI at the REALISED M (never the requested M)\n"
    }' "$WORK/q1c.ranks"
) >>"$RAW" 2>&1; rc=$?
cp "$RAW" "$ARTDIR/q1_c15_estimate.tsv"
row_end TR12_Q1C $rc

# ---- A2.10 the f.g cut identity at every layer.  At full-31 this is a ~24 h single-threaded
#            FULL LADDER PASS, not a point query — it stays behind --with-gcheck. --------------
if [ "$N_PAIRS" -ge 31 ] && [ "$WITH_GCHECK" -eq 0 ]; then
    row_skip a2_gcheck TR12_GCHECK "SKIP:cost-gated" "--kc-g-check at n=31 is a ~24 h single-threaded full ladder pass, not a point query. Pass --with-gcheck, or reuse Stage G's own banked --kc-g-check PASS."
else
    row_begin a2_gcheck
    ( "$SOLVE" --kc-g-check "$FDIR" "$GDIR" ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_GCHECK $rc
fi

# ================================================================================================
# GROUP B — THE SCAN.  One shot, unresumable: kc_scan_main writes its atlas ONCE, at the end, so
# an interruption at hour 47 of 48–85 yields nothing.  Everything above is already banked.
# ================================================================================================
group "GROUP B — the scan"

ATLAS="$ARTDIR/atlas.json"
SCAN_OK=0

row_begin b_scan_selftest
( "$SOLVE" --kc-scan-selftest ) >>"$RAW" 2>&1; rc=$?
row_end TR12_SCAN_SELFTEST $rc

if [ "$HAVE_T" -eq 1 ]; then
    # ---- B.0  the t-layer decompressed-stream shas, before trusting any t-derived number ------
    # The f ladder is pinned by a1_fsha and the g ladder by a2_gsha; without this row the THIRD
    # ladder -- the one Stage T exists to produce -- was the only one whose bytes nothing pinned.
    # sha256 is taken over the DECOMPRESSED stream, so a different zlib level or version changes
    # the file without changing this value: the gate tracks the mathematics, not the container.
    row_begin b_tsha
    ( "$SOLVE" --f1c5-layer-sha "$TDIR" ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_TSHA $rc

    row_begin b_tcheck
    ( "$SOLVE" --kc-t-check "$FDIR" "$TDIR" ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_TCHECK $rc
else
    row_skip b_tsha TR12_TSHA "SKIP:no-tdir" "no TDIR given — the t-ladder's per-layer shas cannot be taken"
    row_skip b_tcheck TR12_TCHECK "SKIP:no-tdir" "no TDIR given — the t-ladder is REQUIRED for the Exhaustion Atlas and every per-branch number (TR-12 §R.0)"
fi

if [ "$DO_SCAN" -eq 0 ]; then
    row_skip b_scan TR12_SCAN "SKIP:no-scan-requested" "--no-scan was passed; the atlas was not produced, so every Group C row is skipped too"
elif [ "$HAVE_T" -eq 0 ]; then
    row_skip b_scan TR12_SCAN "SKIP:no-tdir" "no TDIR: --kc-scan without --kc-tdir yields an atlas with no t_source, and XA-b cannot be gated"
else
    row_begin b_scan
    # --kc-raw is REQUIRED at n=31 or marginal_raw is not emitted and V1 dies. It is automatic at
    # n<=13; passing it always costs nothing and removes the single most expensive mistake in the
    # program (re-running a 48–85 h unresumable pass to add a column).
    ( "$SOLVE" --kc-scan "$FDIR" "$GDIR" "$ATLAS" --kc-tdir "$TDIR" --kc-raw && echo "### atlas" && cat "$ATLAS" ) >>"$RAW" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && SCAN_OK=1
    row_end TR12_SCAN $rc
fi

# ---- B.4  the chunked-scan identity (WORKSTREAM O-9 option A).  At n=31 this is a SECOND full
#           scan, so it stays behind --with-chunked; in a reduced universe it is free. ----------
if [ "$SCAN_OK" -eq 0 ]; then
    row_skip b_chunked TR12_SCAN_CHUNKED "SKIP:no-atlas" "the whole-atlas scan did not run, so there is nothing to compare a chunked atlas against"
elif [ "$N_PAIRS" -ge 31 ] && [ "$WITH_CHUNKED" -eq 0 ]; then
    row_skip b_chunked TR12_SCAN_CHUNKED "SKIP:cost-gated" "at n=31 the chunked==whole identity costs a second full scan; pass --with-chunked. The identity IS gated for free by --kc-layers-selftest, which ran in row a0_gates."
elif ! "$SOLVE" --kc-scan-merge 2>&1 | grep -q 'Usage: solve --kc-scan-merge'; then
    row_skip b_chunked TR12_SCAN_CHUNKED "PENDING:--kc-layers" "PENDING:--kc-layers/--kc-scan-merge — this binary does not accept them"
else
    row_begin b_chunked
    (
      half=$(( N_PAIRS / 2 ))
      "$SOLVE" --kc-scan "$FDIR" "$GDIR" "$WORK/chunk0.json" --kc-tdir "$TDIR" --kc-raw --kc-layers 0 "$half" || exit 1
      "$SOLVE" --kc-scan "$FDIR" "$GDIR" "$WORK/chunk1.json" --kc-tdir "$TDIR" --kc-raw --kc-layers "$half" "$N_PAIRS" || exit 1
      "$SOLVE" --kc-scan-merge "$FDIR" "$GDIR" "$WORK/merged.json" "$WORK/chunk0.json" "$WORK/chunk1.json" --kc-tdir "$TDIR" || exit 1
      if cmp -s "$ATLAS" "$WORK/merged.json"; then echo "CHUNKED_ATLAS_EQ_WHOLE=BYTE-IDENTICAL"
      else echo "CHUNKED_ATLAS_EQ_WHOLE=DIFFERS"; diff "$ATLAS" "$WORK/merged.json" | head -20; exit 1; fi
    ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_SCAN_CHUNKED $rc
fi

# ================================================================================================
# GROUP C — POST-SCAN.  Milliseconds on a tens-of-KB JSON.
#
# QUERY_INVENTORY listed these as PENDING:atlas-consumer (scripts/atlas_queries.py).  No new .py
# may be added (QUERY_BUILD_BRIEF), so the consumer landed inside solve.py instead
# (`--atlas-queries` / `--atlas-selftest`, documented in documentation/SOLVE_PY_CLI.md).  The
# numeric legs below stay computed HERE in awk + bc — bc because every count in the atlas is a
# 192-bit decimal STRING and a 64-bit or double parse loses it silently — and row c_consumer runs
# the solve.py consumer over the same atlas, so the two independent implementations can be diffed.
# The FIGURE legs are rendered by viz/report_figures.py from these TSVs (row c_viz).
# ================================================================================================
group "GROUP C — atlas-derived"

sum_bc(){ # sum a stream of decimal integers, exactly
    awk 'BEGIN{s=""} {s = (s=="" ? $0 : s "+" $0)} END{print (s==""?"0":s)}' | bc | tr -d '\\\n'
}

if [ "$SCAN_OK" -eq 0 ] || [ ! -s "$ATLAS" ]; then
    for pair in "c_atlas:TR12_ATLAS" "c_xa_ab:TR12_XA_AB" "c_xa_mod24:TR12_XA_MOD24" \
                "c_q10a:TR12_Q10A" "c_q6:TR12_Q6" "c_v1:TR12_V1_TSV" "c_v2:TR12_V2_TSV" "c_v5:TR12_V5_TSV"; do
        row_skip "${pair%%:*}" "${pair#*:}" "SKIP:no-atlas" "no atlas.json — Group B did not produce one"
    done
else
    # ---- C.1 atlas integrity re-read -----------------------------------------------------------
    row_begin c_atlas
    (
      fails=0
      nt=$(sed -n 's/.*"N_total": "\([0-9]*\)".*/\1/p' "$ATLAS" | head -1)
      echo "atlas_N_total	$nt"; echo "ladder_N_total	$N_TOTAL"
      [ "$nt" = "$N_TOTAL" ] || { echo "ATLAS_FAIL	N_total != the f-ladder's N"; fails=1; }
      for g in per_layer_flow_eq_N raw_marginal_sums_eq_N branch_masses_sum_eq_N; do
          v=$(sed -n "s/.*\"$g\": \([a-z]*\).*/\1/p" "$ATLAS" | head -1)
          echo "gate_$g	$v"; [ "$v" = "true" ] || { echo "ATLAS_FAIL	gate $g is not true"; fails=1; }
      done
      f=$(sed -n 's/.*"fails": \([0-9]*\).*/\1/p' "$ATLAS" | head -1)
      echo "gate_fails	$f"; [ "$f" = "0" ] || { echo "ATLAS_FAIL	fails != 0"; fails=1; }
      nb=$(grep -c '"global_pair"' "$ATLAS"); echo "branches	$nb"
      nl=$(grep -c '"marginal_quotient"' "$ATLAS"); echo "layers	$nl"
      bad=$(grep -o '"t_source": "[^"]*"' "$ATLAS" | grep -vc '"t-ladder"' || true)
      echo "branches_with_t_source_not_t_ladder	$bad"
      [ "$bad" = "0" ] || { echo "ATLAS_FAIL	some branch t_source is not \"t-ladder\""; fails=1; }
      echo "ATLAS_FAILS	$fails"
      exit $fails
    ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_ATLAS $rc

    # ---- C.2 XA-a / XA-b: the branch table and its two sum gates --------------------------------
    row_begin c_xa_ab
    (
      fails=0
      grep -o '{"global_pair":[^}]*}' "$ATLAS" \
        | sed -e 's/.*"global_pair": *\([0-9]*\).*"entry": *\([0-9]*\).*"exit": *\([0-9]*\).*"solutions": *"\([0-9]*\)".*"prefixes_t_units": *"\([0-9]*\)".*"t_source": *"\([^"]*\)".*/\1\t\2\t\3\t\4\t\5\t\6/' \
        > "$WORK/xa.tsv"
      echo "# XA-a/XA-b branch atlas"
      echo -e "global_pair\tentry\texit\tsolutions\tprefixes_t_units\tt_source"
      cat "$WORK/xa.tsv"
      SS=$(cut -f4 "$WORK/xa.tsv" | sum_bc)
      SP=$(cut -f5 "$WORK/xa.tsv" | sum_bc)
      TR=$(sed -n 's/.*"t_root_t_units": "\([0-9]*\)".*/\1/p' "$ATLAS" | head -1)
      echo "sum_solutions	$SS"
      echo "N_total	$N_TOTAL"
      [ "$SS" = "$N_TOTAL" ] && echo "XA_A_GATE	Sum_b solutions(b) == N  OK" || { echo "XA_A_FAIL	Sum_b solutions(b) != N"; fails=1; }
      echo "sum_prefixes_t_units	$SP"
      echo "t_root_t_units	$TR"
      TRUNK=$(echo "$TR - $SP" | bc)
      echo "shared_trunk_t_units	$TRUNK   # = t(root) - Sum_b prefixes(b); the root node above the branch fan"
      [ "$TRUNK" = "1" ] && echo "XA_B_GATE	Sum_b prefixes(b) + trunk == t(root), trunk == 1 (the root)  OK" \
                         || { echo "XA_B_FAIL	trunk = $TRUNK, expected exactly 1 (the root node)"; fails=1; }
      exit $fails
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/xa_branches.tsv"
    row_end TR12_XA_AB $rc

    # ---- C.4 XA-24: the mod-24 integrity gate on EVERY headline count ---------------------------
    row_begin c_xa_mod24
    (
      fails=0
      echo "# XA-24 — the (mod 24) divisibility gate, kernel-backed (twenty_four_dvd_solution_count)"
      echo -e "quantity\tvalue\tmod24"
      chk(){ local name="$1" v="$2" m; m=$(echo "$v % 24" | bc); printf '%s\t%s\t%s\n' "$name" "$v" "$m"
             [ "$m" = "0" ] || { echo "MOD24_FAIL	$name is not divisible by 24"; fails=1; }; }
      chk "N_total" "$N_TOTAL"
      i=0
      while read -r fl; do chk "layer${i}_flow" "$fl"; i=$((i+1)); done < <(grep -o '"flow": "[0-9]*"' "$ATLAS" | sed 's/.*"\([0-9]*\)"$/\1/')
      # Per-branch counts are REPORTED, not gated: the order-24 group moves walks BETWEEN
      # top-level branches, so solutions(b) has no reason to be divisible by 24 and at n=9 it
      # demonstrably is not (2368 = 24*98.67).  Gating it would be a wrong invariant that fails
      # on a correct atlas; the divisibility theorem is about the TOTAL and about each cut, both
      # of which are gated above.
      j=0
      while read -r b; do
          m=$(echo "$b % 24" | bc); printf 'branch%d_solutions\t%s\t%s\t(reported, not gated)\n' "$j" "$b" "$m"
          j=$((j+1))
      done < <(cut -f4 "$WORK/xa.tsv")
      echo "MOD24_FAILS	$fails"
      exit $fails
    ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_XA_MOD24 $rc

    # ---- C.5 Q10(a): the orbit census — distinct 24-orbits per layer ----------------------------
    row_begin c_q10a
    (
      echo "# Q10(a) orbit census — EXACT. distinct 24-orbits = layer walk-mass / 24."
      echo "global_anchor_N_div_24	$N_DIV24"
      echo -e "k\tflow\torbits\tflow_mod_24"
      fails=0; i=0
      while read -r fl; do
          m=$(echo "$fl % 24" | bc); o=$(echo "$fl / 24" | bc)
          printf '%d\t%s\t%s\t%s\n' "$i" "$fl" "$o" "$m"
          [ "$m" = "0" ] || fails=1
          i=$((i+1))
      done < <(grep -o '"flow": "[0-9]*"' "$ATLAS" | sed 's/.*"\([0-9]*\)"$/\1/')
      echo "Q10A_LAYER_MOD24_FAILS	$fails"
      exit $fails
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/q10_orbit_census.tsv"
    row_end TR12_Q10A $rc

    # ---- C.6 Q6 (REDUCED FORM, QUERY_INVENTORY §3.1) -------------------------------------------
    #      The atlas carries per-layer per-DISTANCE-CLASS mass, not per-(state,choice) mass.  The
    #      spec's per-choice argmax/argmin needs a new emitter.  This ships the reduced table and
    #      SAYS SO in the artifact; it is never presented as the spec's table.
    row_begin c_q6
    (
      echo "# Q6 — REDUCED FORM (QUERY_INVENTORY §3.1): per-layer per-DISTANCE-CLASS mass."
      echo "# The spec's per-(state,choice) argmax/argmin is NOT served by this atlas schema."
      echo "# §9 already rules the per-layer argmin 'loneliest corridor' figure fodder, not a headline."
      echo -e "k\tflow\td1\td2\td3\td4\td6\tanchor_mass_below\tanchor_percentile"
      awk -F'\t' '$1=="#o3-trace"{ delete v; for(i=2;i<=NF;i++){ split($i,a,"="); v[a[1]]=a[2] }
                                   print v["step"] "\t" v["mass_below"] }' "$ARTDIR/q3_profile.tsv" > "$WORK/mb.tsv" 2>/dev/null || true
      i=0
      while read -r line; do
          fl=$(printf '%s' "$line" | sed -n 's/.*"flow": "\([0-9]*\)".*/\1/p')
          d1=$(printf '%s' "$line" | sed -n 's/.*"d1": "\([0-9]*\)".*/\1/p')
          d2=$(printf '%s' "$line" | sed -n 's/.*"d2": "\([0-9]*\)".*/\1/p')
          d3=$(printf '%s' "$line" | sed -n 's/.*"d3": "\([0-9]*\)".*/\1/p')
          d4=$(printf '%s' "$line" | sed -n 's/.*"d4": "\([0-9]*\)".*/\1/p')
          d6=$(printf '%s' "$line" | sed -n 's/.*"d6": "\([0-9]*\)".*/\1/p')
          mb=$(awk -F'\t' -v k="$((i+1))" '$1==k{print $2}' "$WORK/mb.tsv"); mb=${mb:-NA}
          if [ "$mb" = "NA" ] || [ -z "$fl" ]; then pc=NA
          else pc=$(echo "scale=9; $mb / $fl" | bc | sed 's/^\./0./'); fi
          printf '%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$i" "$fl" "$d1" "$d2" "$d3" "$d4" "$d6" "$mb" "$pc"
          i=$((i+1))
      done < <(grep '"marginal_quotient"' "$ATLAS")
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/q6_layer_mass.tsv"
    row_end TR12_Q6 $rc

    # ---- C.7 V1 / V2 / V5 source tables (figures are PENDING:viz) ------------------------------
    row_begin c_v1
    (
      echo "# V1 positional-marginal field — source: atlas.layers[k].marginal_raw (RAW frame)"
      echo -e "k\tpair\tmass"
      i=0
      while read -r line; do
          printf '%s' "$line" | grep -o '"pair[0-9]*": "[0-9]*"' \
            | sed -e "s/\"pair\([0-9]*\)\": \"\([0-9]*\)\"/$i\t\1\t\2/"
          i=$((i+1))
      done < <(grep -o '"marginal_raw": {[^}]*}' "$ATLAS")
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/v1_field.tsv"
    row_end TR12_V1_TSV $rc

    row_begin c_v2
    (
      echo "# V2 mass river — REDUCED FORM (§3.1): split by distance class of the k-th transition,"
      echo "# which is the spec's own parenthetical alternative. branch_atlas[] carries per-branch"
      echo "# TOTALS only, so a per-layer-per-branch split is NOT available from this schema."
      echo -e "k\td1\td2\td3\td4\td6"
      i=0
      while read -r line; do
          printf '%d\t%s\t%s\t%s\t%s\t%s\n' "$i" \
            "$(printf '%s' "$line" | sed -n 's/.*"d1": "\([0-9]*\)".*/\1/p')" \
            "$(printf '%s' "$line" | sed -n 's/.*"d2": "\([0-9]*\)".*/\1/p')" \
            "$(printf '%s' "$line" | sed -n 's/.*"d3": "\([0-9]*\)".*/\1/p')" \
            "$(printf '%s' "$line" | sed -n 's/.*"d4": "\([0-9]*\)".*/\1/p')" \
            "$(printf '%s' "$line" | sed -n 's/.*"d6": "\([0-9]*\)".*/\1/p')"
          i=$((i+1))
      done < <(grep -o '"by_class": {[^}]*}' "$ATLAS")
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/v2_river.tsv"
    row_end TR12_V2_TSV $rc

    row_begin c_v5
    (
      echo "# V5 transition grammar — REDUCED FORM (§3.1): P(distance class | layer k)."
      echo "# The spec's second dimension (new-pair category) is ABSENT from this atlas schema."
      echo -e "k\tclass\tmass\tp"
      i=0
      while read -r line; do
          fl=$(printf '%s' "$line" | sed -n 's/.*"flow": "\([0-9]*\)".*/\1/p')
          for c in d1 d2 d3 d4 d6; do
              m=$(printf '%s' "$line" | sed -n "s/.*\"$c\": \"\([0-9]*\)\".*/\1/p")
              p=$(echo "scale=9; $m / $fl" | bc | sed 's/^\./0./')
              printf '%d\t%s\t%s\t%s\n' "$i" "$c" "$m" "$p"
          done
          i=$((i+1))
      done < <(grep '"marginal_quotient"' "$ATLAS")
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/v5_grammar.tsv"
    row_end TR12_V5_TSV $rc
fi

# ---- the rows that remain genuinely blocked -----------------------------------------------------
row_skip c_xa_cd  TR12_XA_CD  "SKIP:needs-r1-throughput-anchors" "needs the R-1 orbit-engine throughput anchors (36.14x work factor, 19.8x wall at 1T, nodes/sec hedged x2) — they are campaign measurements, not atlas fields, so the EXHAUSTIBLE/INFEASIBLE verdict cannot be derived from atlas.json alone"
row_skip c_q10b   TR12_Q10B   "PENDING:--kc-coset-census" "PENDING:--kc-coset-census — the (Z/2)^6 coset labelling of the transversal is not aggregated by any subcommand"
# The atlas consumer LANDED 2026-08-22 — in solve.py, not scripts/atlas_queries.py (the single-file
# rule: all Python lives in solve.py).  It writes the same tables this driver computes in awk+bc,
# so running both is a genuine two-implementation cross-check of every atlas-derived number.
if [ "$SCAN_OK" -eq 0 ] || [ ! -s "$ATLAS" ]; then
    row_skip c_consumer TR12_ATLAS_CONSUMER "SKIP:no-atlas" "no atlas.json — Group B did not produce one, so there is nothing for the consumer to read"
elif PYTHONPATH="$REPO_ROOT" python3 -c 'import sys, solve; sys.exit(0 if hasattr(solve, "atlas_queries") else 1)' >/dev/null 2>&1; then
    row_begin c_consumer
    (
      crc=0
      # (a) the consumer's OWN reduced-n brute-force gate, over the very atlas just produced.
      #     It needs the explicit enumeration to check against, which only exists at reduced n.
      if [ "$N_PAIRS" -le 13 ]; then
          "$SOLVE" --kc-enum "$FDIR" > "$WORK/walks.txt" 2>/dev/null || crc=1
          ( cd "$REPO_ROOT" && python3 solve.py --atlas-selftest "$ATLAS" \
              --atlas-walks "$WORK/walks.txt" --atlas-q3-trace "$ARTDIR/q3_profile.txt" ) || crc=1
      else
          echo "[consumer] --atlas-selftest SKIPPED: it needs an explicit --kc-enum of the whole"
          echo "[consumer] universe, which is only possible at reduced n (here n=$N_PAIRS)."
      fi
      # (b) the tables themselves, cross-checkable against the awk+bc legs above.
      ( cd "$REPO_ROOT" && python3 solve.py --atlas-queries "$ATLAS" \
          --atlas-out "$ARTDIR/consumer" --atlas-q3-trace "$ARTDIR/q3_profile.txt" ) || crc=1
      exit $crc
    ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_ATLAS_CONSUMER $rc
else
    row_skip c_consumer TR12_ATLAS_CONSUMER "PENDING:atlas-consumer" "solve.py on this tree has no atlas_queries entry point (pre-2026-08-22 checkout). The numeric legs (XA-a/b, XA-24, Q10a, Q6, V1, V2, V5) were computed by this driver in awk+bc instead."
fi
# The V1/V2/V4/V5 generators landed in viz/report_figures.py (TSV -> figure, no analysis logic).
# They need matplotlib + numpy, which are deliberately NOT project dependencies, so a box without
# them skips the row rather than failing it.
if [ -d "$ARTDIR/consumer" ] && python3 -c "import matplotlib, numpy" >/dev/null 2>&1; then
    row_begin c_viz
    mkdir -p "$ARTDIR/figures"
    #   V4 (shells) renders only if row c_consumer wrote a q3_profile TSV, i.e. only if the
    #   --atlas-q3-trace file it was given held exactly this atlas's n '#o3-trace' rows.
    ( cd "$ARTDIR/figures" && python3 -c "import sys
sys.path.insert(0, sys.argv[1] + '/viz')
import report_figures as R
R.tr12_figures(sys.argv[2])" "$REPO_ROOT" "$ARTDIR/consumer" ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_VIZ $rc
elif [ -d "$ARTDIR/consumer" ]; then
    row_skip c_viz TR12_VIZ "SKIP:matplotlib-absent" "matplotlib/numpy absent on this box (they are not project dependencies); the SOURCE TSVs are produced above and under $ARTDIR/consumer, so the figures render anywhere those two packages exist"
else
    row_skip c_viz TR12_VIZ "SKIP:no-consumer-output" "the atlas consumer did not run, so there is no TSV tree to render from"
fi

# The V3 spectrum figure has its own input (a rank grid joined to per-walk functionals) that the
# consumer does not emit. If it did not render, that is a SKIP with a name — not a silent hole
# inside c_viz's PASS.
if [ -s "$RAWDIR/c_viz.txt" ] && grep -q 'fig_tr12_kc_spectrum' "$RAWDIR/c_viz.txt"; then
    tok_record TR12_V3_FIG PASS c_viz
else
    row_skip c_v3_fig TR12_V3_FIG "PENDING:viz-v3-spectrum" \
      "the V3 spectrum figure needs <consumer>/spectrum/v3_spectrum.tsv — a rank grid joined to per-walk functionals, which neither this driver nor the atlas consumer emits. The rank grid itself IS produced (row a1_v3 -> v3_rel_grid.tsv); only the join is missing."
fi

# ================================================================================================
# AGGREGATION + VERDICTS
# ================================================================================================
# A parent token PASSes only if every one of its legs passed.  A skipped leg downgrades the parent
# to SKIP — it is never allowed to read PASS with a hole in it.  That is the whole point of this
# script: "the query ran and matched" and "the query did not run" must not look alike.
agg(){
    local parent="$1"; shift
    local st="PASS" c
    for c in "$@"; do
        case "${TOKSTATE[$c]:-MISSING}" in
            PASS)           : ;;
            MISSING)        st="SKIP:leg-$c-not-reached" ;;
            FAIL*)          st="FAIL:leg-$c"; break ;;
            SKIP*|PENDING*) [ "${st#FAIL}" = "$st" ] && st="SKIP:leg-$c" ;;
        esac
    done
    TOKSTATE[$parent]="$st"; TOKORDER+=("$parent")
}

agg TR12_Q7 TR12_Q7_KW TR12_Q7_HIST TR12_Q7_RANKS
agg TR12_Q8 TR12_Q8_SUPER TR12_Q8_C15 TR12_Q8_MEMBER TR12_Q8_CHI2
agg TR12_XA_A TR12_XA_AB
agg TR12_XA_B TR12_XA_AB
agg TR12_V1 TR12_V1_TSV TR12_VIZ
agg TR12_V3 TR12_V3_TSV TR12_V3_FIG
agg TR12_V2 TR12_V2_TSV TR12_VIZ
agg TR12_V4 TR12_V4_TSV TR12_VIZ
agg TR12_V5 TR12_V5_TSV TR12_VIZ

{
  echo "# TR-12 reproduction battery verdicts — one KEY=value line per row, matched with grep -qx."
  echo "# universe n=$N_PAIRS  N=$N_TOTAL  expected-blocks=$EXPECTDIR"
} > "$VERD.hdr"

for t in "${TOKORDER[@]}"; do
    printf '%s=%s\n' "$t" "${TOKSTATE[$t]}"
    [ -n "${TOKREASON[$t]:-}" ] && printf '%s_REASON=%s\n' "$t" "${TOKREASON[$t]}"
done | awk '!seen[$0]++' > "$VERD.body"

cat "$VERD.hdr" "$VERD.body" > "$VERD"; rm -f "$VERD.hdr" "$VERD.body"

# ================================================================================================
# THE SKIPPED REPORT — printed even on success, because a silent skip reading as a pass is the
# exact failure mode this workflow exists to prevent.
# ================================================================================================
say ""
say "================================================================================"
if [ "${#SKIPPED[@]}" -eq 0 ]; then
    say "SKIPPED: none. Every row in the battery executed."
else
    say "SKIPPED — ${#SKIPPED[@]} row(s) did NOT run. A skip is NOT a pass. Read every line."
    say "================================================================================"
    for s in "${SKIPPED[@]}"; do
        printf '  %-22s %-26s %s\n      reason: %s\n' \
               "$(printf '%s' "$s" | cut -d'|' -f1)" \
               "$(printf '%s' "$s" | cut -d'|' -f2)" \
               "$(printf '%s' "$s" | cut -d'|' -f3)" \
               "$(printf '%s' "$s" | cut -d'|' -f4-)" | tee -a "$LOG"
    done
fi
say "================================================================================"

if [ "${#FAILED[@]}" -ne 0 ]; then
    say ""
    say "FAILED — ${#FAILED[@]} row(s):"
    for f in "${FAILED[@]}"; do say "  $f"; done
    say "  full diffs: $DIFFDIR"
fi

say ""
say "rows=$NROWS  pass=$NPASS  fail=$NFAIL  skip=$NSKIP"
say "verdicts:  $VERD"
say "artifacts: $ARTDIR"
[ "$KEEP" -eq 1 ] && say "work dir kept: $WORK"

# ------------------------------------------------------------------------------- the verdict ---
{
  printf 'TR12_REPRO_ROWS=%d\n' "$NROWS"
  printf 'TR12_REPRO_SKIPPED=%d\n' "$NSKIP"
  if [ "$NSKIP" -eq 0 ]; then printf 'TR12_REPRO_COMPLETE=YES\n'; else printf 'TR12_REPRO_COMPLETE=NO\n'; fi
  printf 'TR12_C3_FILTER_DEGENERATE=%s\n' "$DEGEN"
} >> "$VERD"

# §0.3: the aggregate is emitted only if every non-SKIP token in scope is PASS.
AGG_OK=1
for t in "${TOKORDER[@]}"; do
    case "${TOKSTATE[$t]}" in FAIL*) AGG_OK=0 ;; esac
done
if [ "$NFAIL" -eq 0 ] && [ "$AGG_OK" -eq 1 ]; then
    if [ "$N_PAIRS" -ge 31 ]; then printf 'QUERY_PROGRAM=PASS\n' >> "$VERD"
    else                            printf 'QUERY_DRYRUN=PASS\n'  >> "$VERD"; fi
    printf 'TR12_REPRO=PASS\n' >> "$VERD"
    say ""
    if [ "$REGEN" -eq 1 ]; then
        {
          echo "# Expected-output blocks for the TR-12 reproduction battery, universe n=$N_PAIRS."
          echo "# Regenerate with:  scripts/tr12_repro.sh --n9 --regen   (then REVIEW the diff)"
          echo "# universe n=$N_PAIRS  N=$N_TOTAL  N/24=$N_DIV24"
          echo "# knobs C3MAX=$C3MAX SEED=$SEED Q8_K=$Q8K Q4AC_M=$Q4ACM Q1C_M=$Q1CM V3_K=$V3K"
          echo "# anchor $ANCHOR_LABEL = $ANCHOR"
          echo "#"
          echo "# sha256(block)                                                     block"
          ( cd "$EXPECTDIR" && ls *.txt | grep -v '^_' | sort | xargs sha256sum | sed 's/^/  /' )
        } > "$EXPECTDIR/_MANIFEST.txt"
        say "expected blocks WRITTEN to $EXPECTDIR — review them before they are committed."
        say "manifest: $EXPECTDIR/_MANIFEST.txt"
    fi
    say "TR12_REPRO=PASS"
    exit 0
else
    printf 'TR12_REPRO=FAIL\n' >> "$VERD"
    say ""
    say "TR12_REPRO=FAIL"
    exit 1
fi
