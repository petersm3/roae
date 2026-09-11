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
#   * `python3 solve.py --kc-x-recheck` for row a1_q5, which is the TR-12 §Q5 TWO-LANGUAGE
#     obligation itself: solve.c prints the extremal witness, solve.py re-evaluates Phi on it
#     from its own formulas.  This one is NOT optional -- without it the Q5 numbers are, by the
#     KC-X module header's own rule, not shippable, so the row SKIPS rather than passing;
#   * `viz/report_figures.py` for the V1/V2/V4/V5 figures.
# Every one of the others is optional: if the interpreter, the module or matplotlib is absent, the
# row reports SKIPPED with the reason instead of failing or, worse, quietly passing.
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
#   --atlas PATH         do NOT scan; validate the atlas at PATH (row b_atlas_supplied, token
#                        TR12_SCAN_SUPPLIED) and run Group C against it. TR12_SCAN is recorded as
#                        SKIP:atlas-supplied -- this battery never claims a scan it did not run.
#                        Added 2026-09-08 (roae-private F-5 D1) so the production driver can hand
#                        its chunk-banked, merged atlas to THIS file instead of mirroring Group C.
#   --mint-missing       a row with no expected block is MINTED (written to --expect) and counted
#                        in TR12_REPRO_MINTED instead of failing with no-expected-block; rows that
#                        do have a block are still diffed. This is how a first run at a universe
#                        with no committed goldens (n=31) can execute and record what it saw.
#                        Never use it where goldens exist and you want them enforced -- they are.
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
ATLAS_IN=""; MINT_MISSING=0

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
        --atlas)        ATLAS_IN="$2"; DO_SCAN=0; shift ;;
        --mint-missing) MINT_MISSING=1 ;;
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
SOLVE_HANDED_IN=0; [ -n "$SOLVE" ] && SOLVE_HANDED_IN=1
if [ -z "$SOLVE" ]; then
    [ -f "$REPO_ROOT/solve.c" ] || die "no --solve given and $REPO_ROOT/solve.c not found"
    say "[build] gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz"
    SOLVE="$WORK/solve"
    gcc -O2 -pthread -fopenmp -o "$SOLVE" "$REPO_ROOT/solve.c" -lm -lz 2>"$WORK/build.err" \
        || { cat "$WORK/build.err" >&2; die "solve.c did not compile"; }
fi
[ -x "$SOLVE" ] || die "solve binary '$SOLVE' is not executable"

# 🔴 EXECUTABLE IS NOT CURRENT. The build arm above compiles $REPO_ROOT/solve.c seconds
# before use and is safe by construction. `--solve <path>` is not: it names a PATH, and the line
# above checks only the +x bit. tr12_repro_gate.sh:343 passes a binary it just built from the
# PUBLISHED build line, so the pre-push route was never exposed; a hand run
# `scripts/tr12_repro.sh --n9 --solve ./solve` is, and that is the documented way to run this
# battery against an existing binary. This file is the TR-12 REPRODUCTION harness: every row it
# grades -- counts, ranks, atlas digests -- is an assertion about the engine, so a stale subject
# here turns "the committed tree does not reproduce its own published battery" into a statement
# about an artifact nobody committed.
#
# Added 2026-09-08 after scripts/resume_budget_infinity_gate.sh -- same shape -- reported FAIL, an
# UNDERCOUNT PRESENTED AS A COMPLETE ENUMERATION, against a ./solve two days older than 779fff4c,
# the commit that fixed exactly that. Stale -> FAIL, built from HEAD -> PASS, same tree, one night.
#
# ERROR, NEVER FAIL. TR12_REPRO=ERROR is written to $VERD as well as stdout, so a caller that
# reads the verdict file (tr12_repro_gate.sh does; it ignores this script's exit status) sees an
# unestablished subject rather than an absent PASS it would otherwise narrate as a reproduction
# failure. exit 2 matches die()'s code and is distinct from a graded FAIL.
#
# Called INSIDE an `if`. This file sets no pipefail, but lib_binary_currency.sh's foreign-sha arm
# ends in a `grep -vxF` that exits 1 in the NORMAL case; keeping the call in a condition is the
# rule that makes it safe in every caller regardless of shell options.
#
# ONLY A HANDED-IN BINARY IS CHECKED -- the internally built one cannot be stale, and it is built
# by a bare `gcc -O2 ...` with no -DSOURCE_SHA, so it carries no source-sha signal to check.
if [ "$SOLVE_HANDED_IN" = 1 ] && [ "${TR12_REPRO_ALLOW_STALE-}" != "1" ]; then
    . "$SCRIPT_DIR/lib_binary_currency.sh"
    if ! solve_binary_currency "$SOLVE" "$REPO_ROOT/solve.c"; then
        say "ERROR: $BINCUR_MSG"
        say "       (set TR12_REPRO_ALLOW_STALE=1 to override, deliberately.)"
        echo "TR12_REPRO=ERROR" | tee -a "$VERD"
        exit 2
    fi
fi

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
    # 🔴 Q-92, 2026-09-07. These substitutions exist because the ATLAS embedded absolute ladder
    # paths, so the artifact differed between hosts and the diff had to normalise them away. That
    # normalisation is exactly why the defect survived: the battery stayed green while the artifact
    # the query program exists to produce was not sha-comparable across machines. The atlas now
    # emits BASENAMES and its golden asserts them literally ("fdir": "f"), so the portability is
    # CHECKED rather than erased. The rules stay for the other paths in the raw logs -- OUT, WORK,
    # SOLVE, REPO, and the chunk writer, which still binds merge identity on the full path.
    # 🔴 ESCAPE BEFORE INTERPOLATING (fixed 2026-09-09). These eight values become sed
    # REGEXES, and an unescaped "." matches any character. Invoked as `--solve ./solve`, the
    # pattern "./solve" matched "p/solve" inside "/tmp/solve_selftest_XXXX", rewriting it to
    # "/tm<SOLVE>_selftest_XXXX" -- which the <SELFTEST_TMP> rule below then could not match, so
    # the RANDOM SUFFIX survived into the golden. a0_build.txt therefore baked in one run's temp
    # suffix and TR12_BUILD could never pass twice: it passed only in the run that generated it.
    # Measured 2026-09-09: golden held YPd1rQ, the next run produced zJwQx7.
    _rq() { printf '%s' "$1" | sed -e 's#[][\.*^$/&#]#\\&#g'; }
    # 🔴 A NEWLINE IN A PATH IS NOT ESCAPABLE HERE (RCQ01 F4, second half). _rq escapes regex
    # metacharacters; it cannot escape a newline, which TERMINATES the sed s-command. Measured
    # 2026-09-09: a SOLVE path containing a newline makes this chain print
    # "sed: -e expression #2, char 10: unterminated `s' command" and return 1 -- and before the
    # status check above, the caller took the empty result and, under --mint-missing, minted an
    # EMPTY golden from it. Refuse the input rather than normalise it wrongly; a path like this is
    # a mistake in every case we care about, and silently producing a blank artifact is worse.
    # NB: NOT $(printf '\n') -- command substitution strips trailing newlines, so that pattern is
    # `**` and matches every path. It did, and the guard refused a perfectly ordinary run.
    case "$FDIR$GDIR$TDIR$ARTDIR$OUTDIR$SOLVE$WORK$REPO_ROOT" in
      *$'\n'*)
        echo "TR12_REPRO=ERROR" >&2
        echo "ERROR: a path (FDIR/GDIR/TDIR/ARTDIR/OUTDIR/SOLVE/WORK/REPO_ROOT) contains a newline;" >&2
        echo "       the output normaliser cannot escape one, and would emit an empty block." >&2
        exit 2 ;;
    esac
    [ -n "$FDIR" ]      && s+=( -e "s#$(_rq "$FDIR")#<FDIR>#g" )
    [ -n "$GDIR" ] && s+=( -e "s#$(_rq "$GDIR")#<GDIR>#g" )
    [ -n "$TDIR" ] && s+=( -e "s#$(_rq "$TDIR")#<TDIR>#g" )
    [ -n "$ARTDIR" ] && s+=( -e "s#$(_rq "$ARTDIR")#<ART>#g" )
    [ -n "$OUTDIR" ] && s+=( -e "s#$(_rq "$OUTDIR")#<OUT>#g" )
    [ -n "$SOLVE" ] && s+=( -e "s#$(_rq "$SOLVE")#<SOLVE>#g" )
    [ -n "$WORK" ] && s+=( -e "s#$(_rq "$WORK")#<WORK>#g" )
    [ -n "$REPO_ROOT" ] && s+=( -e "s#$(_rq "$REPO_ROOT")#<REPO>#g" )
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
declare -a MINTED=()        # rows whose expected block was WRITTEN by this run (--mint-missing)
NROWS=0; NPASS=0; NFAIL=0; NSKIP=0

# expected_block_for ROWID -> prints the path of the block to diff ROWID against, or nothing.
# One derived case: b_atlas_supplied (an atlas handed in with --atlas) has no block of its own,
# but the committed b_scan block ends in "### atlas" + the whole-shot atlas, and that tail IS the
# expected content -- so at n=9 a supplied atlas is diffed against the golden whole-shot atlas,
# which makes "chunked-merged == whole-shot" a fact this battery checks rather than one the
# supplier asserts. Where neither block exists the caller sees nothing and --mint-missing decides.
expected_block_for(){
    local id="$1" exp="$EXPECTDIR/$1.txt"
    if [ -f "$exp" ]; then printf '%s\n' "$exp"; return; fi
    if [ "$id" = b_atlas_supplied ] && [ -f "$EXPECTDIR/b_scan.txt" ] && grep -qx '### atlas' "$EXPECTDIR/b_scan.txt"; then
        sed -n '/^### atlas$/,$p' "$EXPECTDIR/b_scan.txt" > "$WORK/b_atlas_supplied.expected"
        printf '%s\n' "$WORK/b_atlas_supplied.expected"
    fi
}

tok_record(){   # tok_record TOKEN STATUS ROWID
    local t="$1" st="$2" id="$3"
    if [ -z "${TOKSTATE[$t]+x}" ]; then TOKORDER+=("$t"); TOKSTATE[$t]="$st"; TOKROWS[$t]="$id"
    else
        TOKROWS[$t]="${TOKROWS[$t]} $id"
        # FAIL dominates everything; a SKIPPED leg downgrades a PASS parent to SKIP.
        # 🔴 N3, 2026-09-10: ERROR* joins FAIL* on BOTH sides. A measured-null producer that cannot
        # take its measurement reports ERROR:<why> -- "I cannot tell" -- and that is a failure, not
        # a pass. Before this, an ERROR-valued token was counted in NPASS and could be overwritten
        # by a later leg, i.e. the one verdict that exists to say "do not trust this row" was the
        # one verdict the driver ignored.
        case "${TOKSTATE[$t]}" in
            FAIL*|ERROR*) : ;;
            *)     case "$st" in
                       FAIL*|ERROR*)  TOKSTATE[$t]="$st" ;;
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
    local got="$GOTDIR/$ROW_ID.txt" exp="$EXPECTDIR/$ROW_ID.txt" status minted=0
    # 🔴 "WRITTEN" MUST MEAN WRITTEN (RCQ01 F4, CONFIRMED by execution 2026-09-09). norm's status
    # was discarded and mkdir/cp were unchecked, so with cp shadowed to fail both helpers recorded
    # a minted row, incremented NPASS, left NFAIL=0 and returned 0 -- announcing a golden that was
    # never on disk. At n=31 --mint-missing is how new goldens are established.
    norm < "$RAW" > "$got" || status="FAIL:normalize"
    NROWS=$((NROWS+1))
    [ -f "$exp" ] || exp="$(expected_block_for "$ROW_ID")"
    if [ -n "${status:-}" ]; then
        :                                     # normalisation already failed; keep that verdict
    elif [ "$rc" -ne 0 ]; then
        status="FAIL:nonzero-exit($rc)"
    elif [ "$REGEN" -eq 1 ]; then
        if mkdir -p "$EXPECTDIR" && cp "$got" "$EXPECTDIR/$ROW_ID.txt"; then status="PASS"
        else status="FAIL:mint-write"; fi
    elif [ -z "$exp" ] && [ "$MINT_MISSING" -eq 1 ]; then
        if mkdir -p "$EXPECTDIR" && cp "$got" "$EXPECTDIR/$ROW_ID.txt"; then
            MINTED+=("$ROW_ID"); minted=1; status="PASS"
        else status="FAIL:mint-write"; fi
    elif [ -z "$exp" ]; then
        status="FAIL:no-expected-block"
    elif diff -u "$exp" "$got" > "$DIFFDIR/$ROW_ID.diff" 2>&1; then
        rm -f "$DIFFDIR/$ROW_ID.diff"; status="PASS"
    else
        status="FAIL:output-mismatch"
    fi
    case "$status" in
        PASS) NPASS=$((NPASS+1))
              if [ "$minted" -eq 1 ]; then printf '  [MINT] %-22s %s   (no expected block existed; WRITTEN, not diffed)\n' "$ROW_ID" "$token" | tee -a "$LOG"
              else printf '  [ok  ] %-22s %s\n' "$ROW_ID" "$token" | tee -a "$LOG"; fi ;;
        *)    NFAIL=$((NFAIL+1));  FAILED+=("$ROW_ID  $token  $status")
              printf '  [FAIL] %-22s %-24s %s\n' "$ROW_ID" "$token" "$status" | tee -a "$LOG"
              [ -f "$DIFFDIR/$ROW_ID.diff" ] && head -40 "$DIFFDIR/$ROW_ID.diff" | tee -a "$LOG" ;;
    esac
    tok_record "$token" "$status" "$ROW_ID"
    ROW_ID=""
}

row_end_val(){ # row_end_val TOKEN RC VALUE
    # Same golden-diff as row_end, but records VALUE instead of "PASS" when the row reproduces.
    #
    # 🔴 WHY THIS EXISTS. QUERY_INVENTORY.md specifies TR12_EW1_NULL=<verdict>, where the verdict
    # is an OUTCOME NAME, not PASS/FAIL -- the whole point of a calibrated null is that its result
    # is data. Before this helper the only way to record a data-valued token was row_skip, i.e. by
    # declaring the row NOT RUN. A harness that can only say PASS about a row that executed cannot
    # express a measured verdict, so it would have had to be smuggled into prose or a second token.
    # The golden diff still guards correctness: the full band -- percentiles, anchor, position --
    # is in the row output and is compared byte-for-byte.
    local token="$1" rc="$2" value="$3"
    local got="$GOTDIR/$ROW_ID.txt" exp="$EXPECTDIR/$ROW_ID.txt" status
    norm < "$RAW" > "$got" || status="FAIL:normalize"      # RCQ01 F4, see row_end above
    NROWS=$((NROWS+1))
    if [ -n "${status:-}" ]; then
        :
    elif [ "$rc" -ne 0 ]; then
        status="FAIL:nonzero-exit($rc)"
    elif [ -z "$value" ]; then
        status="FAIL:no-verdict-extracted"
    elif [ "$REGEN" -eq 1 ]; then
        if mkdir -p "$EXPECTDIR" && cp "$got" "$exp"; then status="$value"
        else status="FAIL:mint-write"; fi
    elif [ ! -f "$exp" ] && [ "$MINT_MISSING" -eq 1 ]; then
        if mkdir -p "$EXPECTDIR" && cp "$got" "$exp"; then
            MINTED+=("$ROW_ID"); status="$value"
            printf '  [MINT] %-22s %s   (no expected block existed; WRITTEN, not diffed)\n' "$ROW_ID" "$token" | tee -a "$LOG"
        else status="FAIL:mint-write"; fi
    elif [ ! -f "$exp" ]; then
        status="FAIL:no-expected-block"
    elif diff -u "$exp" "$got" > "$DIFFDIR/$ROW_ID.diff" 2>&1; then
        rm -f "$DIFFDIR/$ROW_ID.diff"; status="$value"
    else
        status="FAIL:output-mismatch"
    fi
    case "$status" in
        FAIL*|ERROR*) NFAIL=$((NFAIL+1));  FAILED+=("$ROW_ID  $token  $status")
               printf '  [FAIL] %-22s %-24s %s\n' "$ROW_ID" "$token" "$status" | tee -a "$LOG"
               [ -f "$DIFFDIR/$ROW_ID.diff" ] && head -40 "$DIFFDIR/$ROW_ID.diff" | tee -a "$LOG" ;;
        *)     NPASS=$((NPASS+1));  printf '  [ok  ] %-22s %-24s %s\n' "$ROW_ID" "$token" "$status" | tee -a "$LOG" ;;
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

# ratio9 NUM DEN -> NUM/DEN as a 9-place decimal, ROUNDED HALF-UP, in exact integer arithmetic.
#
# 🔴 Q-316 item (3), fixed 2026-09-04. `bc` TRUNCATES at `scale`; it does not round. `scale=9;
# 2720/26112` yields 0.104166666 where the correct 9-place value is 0.104166667, and the wrong
# digit was COMMITTED into scripts/tr12_expected/n9/c_q6.txt -- i.e. into the fixture set that
# gates this whole battery, so the battery was enforcing the defect rather than catching it.
# Q-316 named the two c_q6 cells; the same expression at the V5 site had put EIGHT more into
# c_v5.txt, which nothing had looked at. Ten wrong last digits in the published fixtures.
#
# WHY THE ARITHMETIC IS WHAT IT IS. These numerators are 192-bit at full-31, so awk's `%.9f`
# (a double) is not an option -- that trades a truncation for a silent precision loss at scale.
# bc stays, but the rounding is done in INTEGERS before any fractional division:
#     floor(n/d * 1e9 + 1/2)  ==  (2*n*1e9 + d) / (2*d)     with bc's scale=0 integer division
# exact for every magnitude bc can hold, and half-up by construction.
# A zero numerator still prints a bare `0`, which is the shape the fixtures already carry.
ratio9(){  # ratio9 NUM DEN
    local n="$1" d="$2" r
    [ -n "$n" ] && [ -n "$d" ] || { printf 'NA'; return; }
    [ "$(echo "$d == 0" | bc 2>/dev/null)" = 1 ] && { printf 'NA'; return; }
    r=$(echo "(2*$n*1000000000 + $d) / (2*$d)" | bc) || { printf 'NA'; return; }
    echo "scale=9; $r/1000000000" | bc | sed 's/^\./0./'
}

# ================================================================================================
# N3 — THE TWO MEASURED NULLS.  Q1c's conditioning interval, and Q10a's KW-orbit-rank leg.
# ================================================================================================
# WHY THEY EXIST. Both were carried as HAND-WRITTEN claims: `row_skip a0_q1c TR12_Q1C
# "SKIP:merged-into-Q4AC"` and, in c_q10a's own header, the literal sentence "(iv) KW-orbit-rank:
# DROPPED (no commanded source; 0 under KW-derived labels)". Neither had been checked by anything.
# "SKIP" says WE DID NOT RUN IT and a prose "DROPPED" says nothing a reader can grep, but the real
# state in both cases is WE COMPUTED IT AND THE ANSWER IS NOTHING -- the opposite epistemic
# position, and the one worth publishing. A hand-typed `EMPTY` would be the same defect wearing a
# better word, so each null gets a producer that can FAIL, and both are red-tested in both
# directions by scripts/n3_measured_nulls_gate.sh.
#
# COST. Neither runs the engine. They read artifacts this battery has ALREADY written:
#   a2_q1  --kc-o3-cert  ->  $ARTDIR/q1_rank.json
#   a2_q3  --kc-o3-rank  ->  $ARTDIR/q3_profile.txt
# Marginal cost at n=31 is zero, which is why they ride the pass that is already budgeted.
#
# VERDICT PROTOCOL. Each writes whole-line KEY=value verdicts to a file, matched with `grep -qx`;
# neither signals through exit status or output shape. Values are:
#   TR12_Q1C          EMPTY:interval-degenerate-at-n31 | NONEMPTY:interval-cardinality-<c> | ERROR:<why>
#   TR12_Q10A_KWRANK  EMPTY:class-rank-uncomputable-under-kw-labels | NONVACUOUS:<why>
#                     | COMPUTABLE:<why> | ERROR:<why>
# ERROR is a first-class outcome: "I cannot tell" is honest and EMPTY is not, so a measurement
# that cannot be taken says so. `tok_record`/`row_end_val` count an ERROR* token as a FAILURE.
#
# >>> N3-PRODUCERS-BEGIN  (scripts/n3_measured_nulls_gate.sh extracts everything between these two
#     anchor lines verbatim and sources it; do not reformat the anchors.)

# _n3_json_str FILE KEY -> the value of a JSON string field, or empty. Top-level scalars only.
_n3_json_str(){ sed -n 's/^[[:space:]]*"'"$2"'": "\([^"]*\)".*/\1/p' "$1" | head -1; }
# _n3_json_num FILE KEY -> the value of a JSON bare-number field, or empty.
_n3_json_num(){ sed -n 's/^[[:space:]]*"'"$2"'": \([0-9][0-9]*\),*[[:space:]]*$/\1/p' "$1" | head -1; }
# _n3_is_dec S -> true iff S is a non-empty run of decimal digits (192-bit safe: never arithmetic).
_n3_is_dec(){ case "${1:-}" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }

# q1c_interval_measure CERT_JSON O3RANK_TXT VERDICT_FILE
#
# Measures the CARDINALITY of Q1c's conditioning interval [0, rank_O3(anchor)) -- the set Q1c
# draws its M samples from. That cardinality IS rank_O3(anchor), because O3 is a bijection onto
# [0, N); so the interval is empty exactly when the anchor is the O3-least object in the universe.
# At n=31 the anchor is King Wen and the O3 labels ARE King Wen's own pair table (QUERY_INVENTORY
# 9.1), which forces rank 0 -- but that is the argument, not the measurement, and this row exists
# so the battery does not have to take the argument's word for it.
#
# THREE WITNESSES, because one source that agrees with itself proves nothing:
#   A  rank3 from --kc-o3-cert's certificate JSON
#   B  rank3 from --kc-o3-rank's transcript (a different subcommand, a different code path)
#   C  the certificate's own neighbour bracket: rank 0 has NO predecessor (neighbor_prev_rank
#      NONE); rank r>0 must have exactly r-1. A rank that claims 0 while naming a predecessor is
#      a defect, and this is the leg that catches it.
# Any disagreement, any missing input, any rank outside [0, N) -> ERROR. Never EMPTY.
q1c_interval_measure(){   # CERT_JSON  O3RANK_TXT  VERDICT_FILE
    local cert="$1" o3txt="$2" vf="$3" ra rb prev ntot exp
    _n3_q1c_err(){ printf 'q1c_error\t%s\n' "$1"
                   printf 'Q1C_CARD\tNA\nq1c_verdict\tERROR\n'
                   printf 'TR12_Q1C=ERROR:%s\n' "$2" > "$vf"; }
    : > "$vf"
    echo "# Q1(c) — the conditioning interval [0, rank_O3(anchor)) is MEASURED, not assumed."
    echo "# Sources: A = --kc-o3-cert JSON (row a2_q1); B = --kc-o3-rank transcript (row a2_q3);"
    echo "# C = the certificate's own predecessor witness. Disagreement is an ERROR, never an EMPTY."
    [ -s "$cert" ]  || { _n3_q1c_err "no --kc-o3-cert certificate to read" "cert-absent";  return 0; }
    [ -s "$o3txt" ] || { _n3_q1c_err "no --kc-o3-rank transcript to read"  "o3rank-absent"; return 0; }
    ra=$(_n3_json_str "$cert" rank3)
    rb=$(awk -F'\t' '$1=="rank3"{print $2; exit}' "$o3txt")
    prev=$(_n3_json_str "$cert" neighbor_prev_rank)
    ntot=$(_n3_json_str "$cert" N_total)
    _n3_is_dec "$ra" || { _n3_q1c_err "source A has no decimal rank3 (got '${ra:-}')" "cert-rank-unparsed"; return 0; }
    _n3_is_dec "$rb" || { _n3_q1c_err "source B has no decimal rank3 (got '${rb:-}')" "o3rank-unparsed"; return 0; }
    printf 'q1c_rank_A_kc_o3_cert\t%s\n' "$ra"
    printf 'q1c_rank_B_kc_o3_rank\t%s\n' "$rb"
    if [ "$ra" != "$rb" ]; then
        printf 'q1c_sources_agree\tNO\n'
        _n3_q1c_err "the two engine subcommands disagree about rank_O3(anchor): A=$ra B=$rb" "sources-disagree"; return 0
    fi
    printf 'q1c_sources_agree\tYES\n'
    if [ "$ra" = "0" ]; then exp="NONE"; else exp=$(echo "$ra - 1" | bc 2>/dev/null); fi
    printf 'q1c_predecessor_witness\t%s\t(expected %s)\n' "${prev:-<absent>}" "$exp"
    if [ "${prev:-}" != "$exp" ]; then
        _n3_q1c_err "the bracket contradicts the rank: rank3=$ra but neighbor_prev_rank='${prev:-<absent>}', expected '$exp'" "predecessor-witness-contradicts-rank"; return 0
    fi
    if _n3_is_dec "$ntot"; then
        printf 'q1c_universe_N\t%s\n' "$ntot"
        if [ "$(echo "$ra < $ntot" | bc)" != "1" ]; then
            _n3_q1c_err "rank3=$ra is not inside [0, N=$ntot); a rank outside its own universe is not a rank" "rank-outside-universe"; return 0
        fi
    else
        _n3_q1c_err "the certificate carries no decimal N_total, so [0, N) cannot be bounded" "universe-size-unparsed"; return 0
    fi
    printf 'q1c_interval\t[0, %s)\n' "$ra"
    printf 'Q1C_CARD\t%s\n' "$ra"
    if [ "$ra" = "0" ]; then
        printf 'q1c_verdict\tEMPTY\n'
        printf '# The interval is degenerate: the anchor IS the O3-least object, so there is nothing\n'
        printf '# below it to draw from and P(C3 <= T | rank < rank(anchor)) has no conditioning set.\n'
        printf '# This is a RESULT, not a skip; the estimate that would consume the interval is not run\n'
        printf '# because it has been MEASURED to have no input, not because it was descoped.\n'
        printf 'TR12_Q1C=EMPTY:interval-degenerate-at-n31\n' > "$vf"
    else
        printf 'q1c_verdict\tNONEMPTY\n'
        printf 'TR12_Q1C=NONEMPTY:interval-cardinality-%s\n' "$ra" > "$vf"
    fi
    return 0
}

# q10a_kwrank_measure CERT_JSON VERDICT_FILE
#
# Q10a's KW-orbit-rank leg -- "KW's orbit's rank among the 24-orbits" -- was dropped for TWO
# stated reasons, and until now neither was checked by anything:
#   (1) NOT COMPUTED. The o3-cert says so in its own words (class_rank_note: "class-rank =
#       distinct records preceding, NOT computed") and, more to the point, carries no field that
#       supplies one. Leg 1 asserts the ABSENCE by enumerating the field names that would end it,
#       so the day the engine grows one this row stops saying EMPTY instead of going stale.
#   (2) VACUOUS UNDER KW-DERIVED LABELS. If rank_O3(anchor) = 0 the anchor is the O3-least object
#       in the universe, so its 24-orbit contains the global minimum and no orbit can precede it:
#       the orbit rank is FORCED to 0 by the labelling, whatever a producer would compute. Leg 2
#       measures that forcing (rank3, class_first_rank3 and orient_idx all 0, and no predecessor)
#       rather than asserting it -- and at n<31, where the labels are not anchor-derived, it
#       measures that the forcing does NOT hold and refuses to call the quantity vacuous.
# EMPTY needs BOTH. Leg 1 alone would be "no one has computed it"; leg 2 alone would be "it is 0".
q10a_kwrank_measure(){    # CERT_JSON  VERDICT_FILE
    local cert="$1" vf="$2" note keys k hit r c o prev sum
    local forbidden="class_rank orbit_rank orbit_index orbit_rank3 class_rank3 kw_orbit_rank record_rank"
    _n3_q10a_err(){ printf 'q10a_error\t%s\n' "$1"; printf 'q10a_verdict\tERROR\n'
                    printf 'TR12_Q10A_KWRANK=ERROR:%s\n' "$2" > "$vf"; }
    : > "$vf"
    echo "# Q10(a) KW-orbit-rank — the DROPPED leg, MEASURED. Two reasons were asserted in prose"
    echo "# (no commanded source; 0 under KW-derived labels); both are checked here, and EMPTY needs both."
    [ -s "$cert" ] || { _n3_q10a_err "no --kc-o3-cert certificate to read" "cert-absent"; return 0; }

    # ---- leg 1: the instrument does not supply a class/orbit rank ------------------------------
    note=$(_n3_json_str "$cert" class_rank_note)
    keys=$(grep -o '^[[:space:]]*"[A-Za-z0-9_]*":' "$cert" | sed 's/[^"]*"//; s/"://' | sort -u)
    hit=""
    for k in $forbidden; do printf '%s\n' "$keys" | grep -qx "$k" && hit="$hit $k"; done
    printf 'q10a_class_rank_note\t%s\n' "$(case "$note" in *"NOT computed"*) echo "present, says NOT computed" ;; "") echo "ABSENT" ;; *) echo "present, does NOT say NOT computed" ;; esac)"
    printf 'q10a_rank_fields_searched\t%s\n' "$forbidden"
    printf 'q10a_rank_fields_present\t%s\n' "$(printf '%s' "${hit:-NONE}" | sed 's/^ //')"
    if [ -n "$hit" ]; then
        printf 'q10a_verdict\tCOMPUTABLE\n'
        printf '# The certificate now supplies a class/orbit rank, so "not computed" is no longer true\n'
        printf '# and this leg must be RE-SPECIFIED rather than reported as an empty result.\n'
        printf 'TR12_Q10A_KWRANK=COMPUTABLE:cert-supplies%s\n' "$(printf '%s' "$hit" | tr ' ' '-')" > "$vf"
        return 0
    fi
    case "$note" in
        *"NOT computed"*) : ;;
        "") _n3_q10a_err "the certificate carries no class_rank_note, so its own statement about class-rank cannot be read" "class-rank-note-absent"; return 0 ;;
        *)  _n3_q10a_err "class_rank_note no longer says 'NOT computed' (reads: $note)" "class-rank-note-changed"; return 0 ;;
    esac

    # ---- leg 2: the rank is FORCED to 0 by the labelling ---------------------------------------
    r=$(_n3_json_str "$cert" rank3); c=$(_n3_json_str "$cert" class_first_rank3)
    o=$(_n3_json_num "$cert" orient_idx); prev=$(_n3_json_str "$cert" neighbor_prev_rank)
    _n3_is_dec "$r" || { _n3_q10a_err "no decimal rank3 in the certificate (got '${r:-}')" "rank3-unparsed"; return 0; }
    _n3_is_dec "$c" || { _n3_q10a_err "no decimal class_first_rank3 in the certificate (got '${c:-}')" "class-first-rank3-unparsed"; return 0; }
    _n3_is_dec "$o" || { _n3_q10a_err "no decimal orient_idx in the certificate (got '${o:-}')" "orient-idx-unparsed"; return 0; }
    printf 'q10a_rank3\t%s\nq10a_class_first_rank3\t%s\nq10a_orient_idx\t%s\n' "$r" "$c" "$o"
    sum=$(echo "$c + $o" | bc 2>/dev/null)
    if [ "$sum" != "$r" ]; then
        printf 'q10a_decomposition\tBROKEN\n'
        _n3_q10a_err "rank3 != class_first_rank3 + orient_idx ($r != $c + $o); the certificate is internally inconsistent and nothing may be concluded from it" "cert-decomposition-broken"; return 0
    fi
    printf 'q10a_decomposition\tOK\t(rank3 == class_first_rank3 + orient_idx)\n'
    printf 'q10a_neighbor_prev_rank\t%s\n' "${prev:-<absent>}"
    if [ "$r" = "0" ]; then
        if [ "$c" != "0" ] || [ "$o" != "0" ] || [ "${prev:-}" != "NONE" ]; then
            _n3_q10a_err "rank3 is 0 but the certificate does not agree it is the least object (class_first_rank3=$c orient_idx=$o neighbor_prev_rank='${prev:-<absent>}')" "least-object-witnesses-disagree"; return 0
        fi
        printf 'q10a_forced_zero_under_kw_labels\tYES\n'
        printf '# The anchor is the O3-least object, so its 24-orbit contains the global minimum and no\n'
        printf '# orbit precedes it: the orbit rank is 0 by construction of the labels, and a producer\n'
        printf '# for it could only recover the same 0. The quantity is not missing; it is vacuous.\n'
        printf 'TR12_Q10A_KWRANK=EMPTY:class-rank-uncomputable-under-kw-labels\n' > "$vf"
    else
        printf 'q10a_forced_zero_under_kw_labels\tNO\n'
        printf '# The anchor is NOT the O3-least object here, so the labelling does not force the orbit\n'
        printf '# rank to 0 and the quantity is a real unanswered question, not an empty one. Refusing\n'
        printf '# to call it vacuous is the whole point of measuring instead of asserting.\n'
        printf 'TR12_Q10A_KWRANK=NONVACUOUS:anchor-is-not-the-o3-least-object\n' > "$vf"
    fi
    return 0
}
# <<< N3-PRODUCERS-END

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
if [ "$MINT_MISSING" -eq 1 ]; then
    mkdir -p "$EXPECTDIR"
    say "  --mint-missing: $(ls "$EXPECTDIR"/*.txt 2>/dev/null | grep -vc '/_' ) expected block(s) present will be DIFFED; every other row is MINTED and reported in TR12_REPRO_MINTED"
fi
[ -n "$ATLAS_IN" ] && say "  --atlas: Group B will NOT scan; $ATLAS_IN is validated and Group C runs against it"
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
# 🔴 Q-483 (2026-09-11). The line above was PRINTED AND ASSERTED NOTHING. The enumeration sha
# itself IS carried by rc -- solve.c returns 40 when --selftest mismatches -- but this DERIVED
# line is not: if either sed matched nothing (a renamed banner, a truncated transcript, a binary
# that prints neither line) the row published `SELFTEST_EXPECTED_EQ_ACTUAL=NO` and STILL EXITED 0,
# so the one line a reader would grep for could say NO in a passing battery. Both shas must be
# present, 64 hex, and equal. `e` and `a` are already set by the group above, which runs in this
# shell, so nothing is re-parsed. Success output is UNCHANGED -- only a failure prints -- so
# scripts/tr12_expected/n9/a0_build.txt does not move.
if [ "${#e}" -ne 64 ] || [ "${#a}" -ne 64 ] || [ "$e" != "$a" ]; then
    printf 'BUILD_FAIL\t--selftest sha lines: expected=%s actual=%s -- SELFTEST_EXPECTED_EQ_ACTUAL is DERIVED from both, and an absent line publishes NO at rc 0\n' \
        "${e:-<absent>}" "${a:-<absent>}" >>"$RAW"
    [ "$rc" -ne 0 ] || rc=1
fi
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
#            a python3 call (QUERY_INVENTORY §2 row Q7).  It was the ONLY one until the Q5
#            two-language re-check landed in row a1_q5, 2026-09-10. ---------------------------
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
          "$SOLVE" --check-arrangement "$A" --cert-out "$ARTDIR/q7_${fn#_r7_}.json" > "$WORK/q7_hist.out" 2>&1
          crc=$?
          cat "$WORK/q7_hist.out"
          # a historical arrangement is EXPECTED to be OUT; the row diffs the verdict either way,
          # so a non-zero exit here is information, not a failure — record it and continue.
          echo "### $fn checker_rc=$crc"
          # 🔴 F-5 D11 (2026-09-08): until this date the row had NO in-row check -- at n=9 the golden
          # diff caught a wrong verdict, at n=31 (no golden) a checker printing IN, or nothing at
          # all, still ended in TR12_Q7_HIST=PASS. TR-12 §Q7 PUBLISHES that the three historical
          # arrangements are OUT of SUPER (they fail C1 at slot 0; 64-hexagram objects, n-independent),
          # so that is what the row asserts. Success output is unchanged; only a failure prints.
          if ! grep -q 'verdict SUPER (C1&C2&C4&C5):     OUT' "$WORK/q7_hist.out"; then
              echo "Q7_HIST_FAIL	$fn: no 'verdict SUPER ... OUT' line (checker rc=$crc) -- either the checker did not run or a historical arrangement is IN SUPER, which contradicts TR-12 §Q7"
              hrc=1
          fi
      done
      exit $hrc
    ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_Q7_HIST $rc
else
    row_skip a0_q7_hist TR12_Q7_HIST "SKIP:python3-unavailable" \
      "python3+solve.py unavailable — the 3 historical arrangements (_r7_mawangdui/_r7_fuxi/_r7_jingfang) could not be materialised"
fi

# ---- A0.3c Q7 leg 3: the SAT witnesses (TR-1/TR-2's moore-strict / grand-strict).  D5-04 (2026-09-05).
#            TR-12 section Q7 promised "the SAT witnesses are IN C15 ... they get ranks (post-O3) -- the
#            only non-KW named sequences in this report with serial numbers", and QUERY_INVENTORY row Q7
#            commands `python3 sat.py --witness moore-strict|grand-strict` followed by --check-arrangement.
#            This driver never invoked sat.py, so a2_q7_ranks iterated only q7_kw / q7_<historical>.json
#            -- of which only KW is IN -- and at full-31 the "ranks of IN members" leg would have reduced
#            to rank_O3(KW) = 0 while TR12_Q7 read PASS. The witnesses need kissat on PATH
#            (QUERY_INVENTORY section 3.4); and even with it the row is unbuilt, because a solver-chosen
#            witness has no reproducibility contract (which IN sequence kissat returns is build-dependent,
#            so there is no expected block to diff until the witness bytes are pinned). Named skip,
#            aggregated into TR12_Q7 below: the parent can never read PASS without this leg. -----------
if command -v kissat >/dev/null 2>&1; then
    row_skip a0_q7_witnesses TR12_Q7_WITNESSES "PENDING:q7-witness-row" \
      "kissat is on PATH but the witness row is unbuilt: a solver-chosen witness has no reproducibility contract (which IN sequence kissat returns is build-dependent), so there is no expected block to diff until the witness bytes are pinned"
else
    row_skip a0_q7_witnesses TR12_Q7_WITNESSES "PENDING:kissat" \
      "PENDING:kissat — sat.py --witness moore-strict|grand-strict needs kissat on PATH (absent; QUERY_INVENTORY §3.4). No SAT witness is materialised, so no non-KW IN sequence reaches a2_q7_ranks and no witness serial number is produced"
fi

# ---- A0.4  LS-w0: TR-8's pair-only null, EXACT.  D5-03 (2026-09-05).  TR-12 section 4(a)(5) names
#            "TR-8's pair-only null (10^-4 from 10^5 seeded samples)" -- that is P(rc4_violations <= 2 | C1),
#            made exact in TR-8 v1.6 (reports/TR8_REORDERING_REVISITED.md, 2026-07-21):
#            solve.pair_null_gender_le2_exact() = 47/445740 = 1.054426e-4, two-way verified there.
#            Until this date the row ran `--null-pair-constrained 1000000`, whose output is the C2|C1 and
#            C3|C1 conditional pass rates over random pair-permutations -- a different null quantity --
#            so TR12_LS_W0=PASS attested a computation other than the one the prose names. The MC is
#            kept below under its own name (a0_ls_w0_mc) and labelled as what it is. No ladder; both
#            rows are 64-hexagram objects and n-independent, which is what Group A0 is for. ------------
if command -v python3 >/dev/null 2>&1 && [ -f "$REPO_ROOT/solve.py" ] \
   && PYTHONPATH="$REPO_ROOT" python3 -c 'import solve' >/dev/null 2>&1; then
    row_begin a0_ls_w0
    ( cd "$REPO_ROOT" && PYTHONPATH="$REPO_ROOT" python3 -c '
import solve
v = solve.pair_null_gender_le2_exact()
kw = solve.rc4_violations(solve.binary_hexagrams)[0]
print("# LS-w0 -- TR-8 pair-only (C1) null, EXACT: P(rc4_violations <= 2) over uniformly random")
print("# C1-preserving orderings (TR-8 v1.6, 2026-07-21; two-way verified there). No ladder; n-independent.")
print("quantity\tP(rc4_violations <= 2 | C1)")
print("pair_null_gender_le2_exact\t%d/%d" % (v.numerator, v.denominator))
print("decimal\t%.6e" % float(v))
print("kw_rc4_violations\t%d" % kw)
print("event_is_kw_level\t%s" % ("YES" if kw == 2 else "NO"))
# F-5 D15 (2026-09-08): two labels that must travel with the number (F-5 review 5). The tail is taken
# AT the level KW itself realises (the ordinary p-value construction, not definitional circularity;
# TR-8 is the authority that rc4 was not read off KW), and a 1e-4 tail is read against the suite-wide
# family it belongs to, not against 0.05: TR-8 "Look-elsewhere context (F-32)" freezes that ledger at 91.
# (This block sits inside a single-quoted shell string: no apostrophes here.)
print("threshold_label\tKW-anchored: the event level 2 is the rc4_violations value of KW itself (tail at the observed value)")
print("correction_family\t91 observables (TR-8 F-32; METHODS.md Global observable ledger); Bonferroni bar 0.05/91 = 5.5e-4, cleared by ~5x")
' ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_LS_W0 $rc
else
    row_skip a0_ls_w0 TR12_LS_W0 "SKIP:python3-unavailable" \
      "python3+solve.py unavailable — pair_null_gender_le2_exact() could not be evaluated"
fi

# ---- A0.4b the C2|C1 / C3|C1 conditional Monte-Carlo.  NOT the TR-8 pair-null (D5-03): it measures
#            how often a random C1-preserving pair-ordering also passes C2 / C3, at 10^6 draws under the
#            engine's fixed seed. Kept as its own row because it is reproducible and already cited
#            (documentation/HISTORY.md, at 10^9); labelled so nobody reads TR12_LS_W0 off it again. -----
row_begin a0_ls_w0_mc
( echo "# NOT the TR-8 pair-only null (that is row a0_ls_w0 / TR12_LS_W0). This is the C2|C1 and C3|C1"
  echo "# conditional pass-rate Monte-Carlo over random pair-permutations, 10^6 draws, engine seed."
  "$SOLVE" --null-pair-constrained 1000000 ) >>"$RAW" 2>&1; rc=$?
row_end TR12_LS_W0_COND_MC $rc

# ---- A0.5  Q4(b): ANSWERED 2026-09-05, not pending. -------------------------------------------
# 🔴 THIS ROW ADVERTISED WORK THE PROJECT HAD ALREADY RULED UNNECESSARY. It emitted
# PENDING:sat-c3min-driver on BOTH branches -- toolchain present or absent -- while
# QUERY_INVENTORY 9.2 (2026-09-05) records min{C3(w) : w in SUPER} = 112, witness published
# 2026-07-24, G >= 12 structural and achieved, and the SAT bisection therefore NOT NEEDED for the
# minimum. A harness telling a reader a solver is required, for a question already closed, is a
# claim the harness has no business making.
#
# What CAN be checked here with no solver: the certificate states its own relation, C3 = 16 + 8*G.
# That is 42 rungs of internal consistency and catches transcription error.
#
# 🔴 F-5 D10 (2026-09-08): THE "NO VALIDATOR" REASON WAS FALSE. Until this date this block ended
# in a SKIP whose reason said each SEQ's C1&C2&C4&C5 status was "unchecked, for want of a 64-int
# sequence validator" -- while `--check-arrangement "h0,...,h63"` is exactly that validator, and
# row a0_q7_hist above calls it on three 64-int sequences. So the row now RUNS it: every certificate
# line is checked (SUPER verdict + the C3 value against the line's stated C3), the G=12 witness in
# full with its own certificate JSON, and TR12_Q4B is PASS on a computed fact or FAIL. The floor
# G >= 12 is `c3slot_ge_12` (lean/C3Decomposition.lean); a witness achieving it closes the bracket at
# its floor, which is why the SAT bisection is not needed for the MINIMUM (QUERY_INVENTORY 9.2).
# Independently re-derived 2026-09-08 with no repo import (pure Python): the G=12 line is a
# permutation of 0..63 starting 63,0, has no Hamming-5 step, its slot pairs are inverse-partners,
# its step-distance histogram d1..d6 is 2,20,13,19,0,9 (= KW's), and sum_h |pos(h)-pos(h^63)| = 112.
{
  _certrel=reports/certificates/c3_positional_witnesses.txt
  _cert="$REPO_ROOT/$_certrel"       # was cwd-relative: run from anywhere but the repo root, the row saw "MISSING"
  if [ ! -r "$_cert" ]; then
      row_skip a0_q4b TR12_Q4B "SKIP:answered-2026-09-05" "ANSWERED (QUERY_INVENTORY 9.2): min C3 over SUPER = 112. WARNING: the witness certificate $_certrel is MISSING from this tree, so nothing about it could be re-checked"
  else
      row_begin a0_q4b
      (
        bad=$(awk 'match($0,/G=[0-9]+[ \t]+C3=[0-9]+/){g=$0; sub(/.*G=/,"",g); sub(/[ \t].*/,"",g); c=$0; sub(/.*C3=/,"",c); sub(/[ \t].*/,"",c); if (c+0 != 16+8*(g+0)) n++} END{print n+0}' "$_cert")
        rows=$(grep -cE 'G=[0-9]+[ \t]+C3=[0-9]+' "$_cert")
        echo "# Q4(b): min{C3(w) : w in SUPER} = 112 -- ANSWERED 2026-09-05 (QUERY_INVENTORY 9.2, row Q4b). The floor"
        echo "# G >= 12 is the Lean theorem c3slot_ge_12 (lean/C3Decomposition.lean); this row VERIFIES the published"
        echo "# witnesses with the battery's own 64-int validator (--check-arrangement), so PASS is a computed fact."
        echo "certificate	$_certrel"
        echo "certificate_rows	$rows"
        echo "certificate_relation_violations	$bad	(C3 = 16 + 8*G, the file's own stated relation)"
        fails=0
        [ "${bad:-1}" -eq 0 ] && [ "${rows:-0}" -ge 40 ] || { echo "Q4B_FAIL	certificate arithmetic: $rows rows, $bad violate C3 = 16 + 8*G"; fails=1; }
        # every line: SEQ= follows its G=/C3= header line. Checked: SUPER verdict IN and the checker's
        # C3 value equals the line's stated C3 (C3 > 776 lines are legitimately C15-OUT, still SUPER-IN).
        echo "G	C3_stated	verdict_super	c3_checked	ok"
        seen=0; g12seq=""
        while IFS= read -r hdr; do
            case "$hdr" in G=*C3=*) ;; *) continue ;; esac
            g=${hdr#G=}; g=${g%% *}; c=${hdr#*C3=}; c=${c%% *}
            IFS= read -r sq || sq=""
            case "$sq" in SEQ=*) sq=${sq#SEQ=} ;; *) echo "Q4B_FAIL	G=$g: no SEQ= line follows the header"; fails=1; continue ;; esac
            nv=$(printf '%s\n' "$sq" | tr -s ' ' '\n' | grep -c .)
            if [ "$nv" -ne 64 ]; then echo "Q4B_FAIL	G=$g: SEQ has $nv values, not 64"; fails=1; continue; fi
            arr=$(printf '%s' "$sq" | tr -s ' ' ',')
            "$SOLVE" --check-arrangement "$arr" > "$WORK/q4b_line.out" 2>&1 < /dev/null   # never let the checker read the certificate off stdin
            vs=$(sed -n 's/.*verdict SUPER (C1&C2&C4&C5): *\([A-Z]*\).*/\1/p' "$WORK/q4b_line.out" | head -1)
            cv=$(sed -n 's/.*C3 complement distance: *[A-Z]* (value \([0-9]*\), ceiling 776).*/\1/p' "$WORK/q4b_line.out" | head -1)
            ok=NO; [ "$vs" = IN ] && [ -n "$cv" ] && [ "$cv" -eq "$c" ] && ok=YES
            echo "$g	$c	${vs:-NONE}	${cv:-NONE}	$ok"
            [ "$ok" = YES ] || fails=1
            seen=$((seen+1))
            [ "$g" -eq 12 ] && g12seq="$arr"
        done < "$_cert"
        echo "lines_checked	$seen"
        [ "$seen" -eq "$rows" ] || { echo "Q4B_FAIL	checked $seen lines but the certificate has $rows header rows"; fails=1; }
        [ -n "$g12seq" ] || { echo "Q4B_FAIL	no G=12 line in the certificate -- the floor witness is missing"; fails=1; }
        if [ -n "$g12seq" ]; then
            echo "### G=12 witness, full checker output"
            "$SOLVE" --check-arrangement "$g12seq" --cert-out "$ARTDIR/q4b_g12_witness.json" > "$WORK/q4b_g12.out" 2>&1 < /dev/null
            crc=$?
            cat "$WORK/q4b_g12.out"
            echo "### G=12 witness checker_rc=$crc"
            grep -q 'verdict SUPER (C1&C2&C4&C5):     IN' "$WORK/q4b_g12.out" || { echo "Q4B_FAIL	the G=12 witness is not IN SUPER"; fails=1; }
            grep -Eq 'C3 complement distance: +HOLD \(value 112, ceiling 776\)' "$WORK/q4b_g12.out" || { echo "Q4B_FAIL	the G=12 witness does not have C3 = 112"; fails=1; }
            grep -q 'hist d1..d6 = 2,20,13,19,0,9' "$WORK/q4b_g12.out" || { echo "Q4B_FAIL	the G=12 witness step-distance histogram is not KW's (2,20,13,19,0,9)"; fails=1; }
        fi
        [ "$fails" -eq 0 ] && echo "Q4B_MIN_C3_OVER_SUPER	112	floor c3slot_ge_12 + witness verified by --check-arrangement"
        exit $fails
      ) >>"$RAW" 2>&1; rc=$?
      row_end TR12_Q4B $rc
  fi
}

# ---- A0.6  the writing-only rows.  They have no command, so this driver cannot attest them.
#            Reported as skipped with the reason, never folded into a PASS. --------------------
# 🔴 N3, 2026-09-10. TR12_Q1C USED TO BE DECLARED HERE, as a row_skip carrying the hand-typed
# value "SKIP:merged-into-Q4AC" and the sentence "the interval [0, rank_O3(KW)) is EMPTY at
# full-31". That sentence was TRUE and NOTHING CHECKED IT: a program was emitting an
# absence-claim about a quantity it had never looked at, which is this project's dominant
# defect wearing the word SKIP. The claim now belongs to row a2_q1c, which MEASURES the
# interval from two engine subcommands and a bracket witness and emits
# EMPTY:interval-degenerate-at-n31 only when the measurement says so -- and ERROR when it
# cannot say. It is not declared in A0 any more because A0 has no ladder and therefore no
# certificate to read, and a verdict has to be produced where its evidence lives.
row_skip a0_q9        TR12_Q9        "SKIP:doc-only" "DOC-only: Q9 is certified restatement of the reportable negatives (tr12/q9_negatives.md); no executable command exists to diff"
# F-5 D13 (2026-09-08): this reason used to assert that lean/C1RuleConstants.lean is NOT an ancestor of
# this branch. It has been on main since e9490e16 (QUERY_INVENTORY §3.3, corrected 2026-09-05), so the
# skip reason was stale for three days of runs. It now reports what THIS tree actually holds.
if [ -f "$REPO_ROOT/lean/C1RuleConstants.lean" ]; then
    _c1rc="lean/C1RuleConstants.lean IS present in this tree (on main since e9490e16; QUERY_INVENTORY §3.3 corrected 2026-09-05) — cite by theorem name and commit sha"
else
    _c1rc="lean/C1RuleConstants.lean is NOT present in this tree — cite by commit sha with the branch stated (QUERY_INVENTORY §3.3)"
fi
row_skip a0_ls_forced8 TR12_LS_FORCED8 "SKIP:doc-only" "DOC-only: citation row; $_c1rc"
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
(
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
  # 🔴 F-5 D11 (2026-09-08): `... | tail -1` returned tail's rc, so a NON-MEMBER anchor (or a binary
  # that printed nothing) still ended in TR12_ANCHOR=PASS at n=31, where no golden diffs the line.
  # --kc-member prints exactly MEMBER or NON-MEMBER and exits 1 on the latter (solve.c --kc-member
  # arm); the printed word is now the row's exit test. Success output is byte-identical to before.
  m=$("$SOLVE" --kc-member "$FDIR" "$ANCHOR" 2>&1 < /dev/null | tail -1)
  echo "anchor_is_member=$m"
  [ "$m" = MEMBER ] || { echo "ANCHOR_FAIL	the anchor walk is not a member of this f-ladder universe (--kc-member said '${m:-<nothing>}')"; exit 1; }
) >>"$RAW" 2>&1; rc=$?
row_end TR12_ANCHOR $rc

# ================================================================================================
# GROUP A1 — f-ladder only.   (QUERY_INVENTORY §5 Group A1)
# ================================================================================================
group "GROUP A1 — f-ladder mounted"

# ---- A1.1  the 32 f-layer decompressed-stream shas, before trusting any number ----------------
# 🔴 F-5 R2 (2026-09-09). Until today the three ladder-sha rows (a1_fsha, a2_gsha, b_tsha) printed
# --f1c5-layer-sha and diffed the print against scripts/tr12_expected/n<N>/ -- which at n=31 does
# not exist, so under --mint-missing each row was MINTED from the very run it was meant to check:
# a PASS that compared to nothing. The a2_q2 comment below records that the bracket cannot stand
# in ("rank and unrank read the same wrong g and agree with each other") and --kc-g-check is
# cost-gated off at n=31, so a wrong layer reached every O3 rank, the profile, EW-1 and the atlas
# under TR12_REPRO=PASS. Now each layer's tool digest is compared, IN THE ROW, against what the
# BUILDER recorded at build time: the sidecar's own_sha256_decompressed, which solve.c
# (f1c5_sidecar_emit_impl) documents as "the IDENTICAL digest --f1c5-layer-sha registers -- same
# code path, f1c5_layer_sha_hex". The row FAILS (rc=1, whole-line LADDER_SHA_CHECK=FAIL) on any
# digest mismatch, any missing sidecar, any sidecar without the field, a layer count other than
# n+1, or a non-zero tool rc. No n31 golden is needed; it works at every n; and it is red-testable
# at n=9 (the n=9 builders write the same sidecars): flip one byte of one layer, or one hex digit
# of one sidecar, and that row goes red. Measured 2026-09-09 (F5_R2_R3_2026_09_09.md).
# WHAT IT DOES NOT PROVE: the sidecar sits beside the layer, so a layer REBUILT wrong together
# with a fresh sidecar agrees with itself. Identity with the PUBLISHED n=31 build is a different
# question, answered by runs/20260906_kc_ladders_n31/STAGE_{F,G,T}_LAYERSHA.txt (the archived
# ladders' --f1c5-layer-sha rows, 32 per stage, taken from these same sidecars); at n=9 the
# committed golden pins the values.
ladder_sha_row(){ # ladder_sha_row ROWID TOKEN DIR
    local id="$1" token="$2" dir="$3"
    row_begin "$id"
    (
      "$SOLVE" --f1c5-layer-sha "$dir" > "$WORK/lsha.$id" 2>&1; trc=$?
      cat "$WORK/lsha.$id"
      echo "### sidecar cross-check: tool digest vs the own_sha256_decompressed the builder recorded"
      layers=0; ok=0; bad=0
      while read -r tag hex path _rest; do
          [ "$tag" = "sha256(decompressed)" ] || continue
          layers=$((layers+1))
          base=${path##*/}; stem=${base%.bin}                      # <pfx>_layer_NN
          sc="${path%/*}/${stem%_layer_*}_layer_stats_${stem##*_layer_}.json"
          if [ ! -f "$sc" ]; then
              echo "sidecar ${sc##*/}  MISSING"; bad=$((bad+1)); continue
          fi
          own=$(sed -n 's/^ *"own_sha256_decompressed": *"\([0-9a-f]\{64\}\)".*/\1/p' "$sc" | head -1)
          if [ -z "$own" ]; then
              echo "sidecar ${sc##*/}  NO-FIELD own_sha256_decompressed"; bad=$((bad+1))
          elif [ "$own" = "$hex" ]; then
              echo "sidecar ${sc##*/}  own_sha256_decompressed=$own  MATCH"; ok=$((ok+1))
          else
              echo "sidecar ${sc##*/}  own_sha256_decompressed=$own  MISMATCH tool=$hex"; bad=$((bad+1))
          fi
      done < "$WORK/lsha.$id"
      want=$((N_PAIRS+1))
      echo "layers=$layers expected=$want sidecar_match=$ok sidecar_bad=$bad tool_rc=$trc"
      if [ "$trc" -eq 0 ] && [ "$bad" -eq 0 ] && [ "$layers" -eq "$want" ] && [ "$ok" -eq "$want" ]; then
          echo "LADDER_SHA_CHECK=OK"
      else
          echo "LADDER_SHA_CHECK=FAIL"; exit 1
      fi
    ) >>"$RAW" 2>&1; rc=$?
    row_end "$token" $rc
}
ladder_sha_row a1_fsha TR12_FSHA "$FDIR"

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
      nw=$(wc -l < "$WORK/q6_walks.txt")
      echo "# walks regenerated by --kc-enum-desc: $nw"
      # 🔴 Q-483 (2026-09-11). That count was PRINTED AND COMPARED TO NOTHING, and the row's rc was
      # verify.py's alone -- so an --kc-enum-desc that emitted a PREFIX of the universe (or nothing
      # at all) would hand the oracle a short list, and the oracle, which only ever sees the list it
      # is given, would certify extremes over it and the row would pass. The universe size is known
      # INDEPENDENTLY of this enumeration: N_TOTAL comes from `--kc-count` on the f ladder (:211),
      # which counts by DP and never walks. Compared as strings -- both are canonical decimals and
      # N is 192-bit at full-31, where shell arithmetic would silently wrap. Also: an enumeration
      # that repeats a walk has the right length and the wrong content, so distinctness is checked
      # too, and every line must carry 2n hexagrams. Success output is UNCHANGED.
      fails=0
      [ "$nw" = "$N_TOTAL" ] \
        || { echo "Q6_ORACLE_FAIL	--kc-enum-desc emitted $nw walks; the f ladder counts N=$N_TOTAL -- the oracle would rule over a subset"; fails=1; }
      nu=$(sort -u "$WORK/q6_walks.txt" | grep -c .)
      [ "$nu" = "$nw" ] \
        || { echo "Q6_ORACLE_FAIL	$nw walks but only $nu distinct -- an enumeration that repeats a walk is not the universe"; fails=1; }
      nbad=$(awk -F',' -v w="$((2 * N_PAIRS))" 'NF != w {n++} END{print n+0}' "$WORK/q6_walks.txt")
      [ "$nbad" -eq 0 ] \
        || { echo "Q6_ORACLE_FAIL	$nbad walk(s) do not carry 2n=$((2 * N_PAIRS)) hexagrams"; fails=1; }
      python3 "$REPO_ROOT/verify.py" --q6-extremes-oracle "$WORK/q6_walks.txt" || fails=1
      exit $fails
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
  # 🔴 F-5 D11 (2026-09-08): an empty or malformed q8_super.tsv gave n=0, bad=0 and PASS -- a
  # membership re-check of nothing. The row now requires exactly Q8K draws to have been re-checked.
  short=0
  [ "$n" -eq "$Q8K" ] || { echo "Q8_MEMBER_FAIL	re-checked $n draws; the gallery must hold exactly Q8K=$Q8K"; short=1; }
  exit $(( (bad || short) ? 1 : 0 ))
) >>"$RAW" 2>&1; rc=$?
row_end TR12_Q8_MEMBER $rc

# ---- A1.2c Q8 the chi-square uniformity gate OVER THE GALLERY.  D5-02 (2026-09-05).  TR-12 section
#            Q8, QUERY_INVENTORY row Q8 and WAVE1_RUNBOOK W1-1 all promise a chi-square over 16 rank
#            buckets of the gallery draws; until this date this row ran `--kc-midn 13 --kc-chi2-samples
#            20000` -- the engine's n=13 sampler self-test on a universe it builds in-process -- whose
#            PASS attests nothing about the draws in q8_super.tsv. This is the pre-registered statistic
#            (PREREG_F_CATALOG_T1_T4 section 4): bucket = floor(16*rank/N) in EXACT integer arithmetic
#            (bc: ranks are 192-bit decimal strings at full-31, and a double bucketing is a 53-bit
#            bucketing -- the two ranks N/16-1 and N/16 straddle a bucket edge exactly and a binary64
#            puts both in bucket 1), 15 dof, bar chi2 < 37.70. chi2 = (16*S - k^2)/k with S the sum of
#            squared bucket counts; the verdict is decided in integers (100*(16S-k^2) < 3770*k), never
#            through a float. The gallery chi2 was computed once before, launcher-side on 2026-08-07
#            (20.22 over the 1000 full-31 draws); this row is the battery's own reproduction of that
#            statistic. Under the prereg's publish-regardless rule chi2 >= 37.70 is a FINDING; for a
#            REPRODUCTION battery a non-uniform exact-uniform sampler is an instrument defect, so the
#            row exits 1 on it. Pinned by scripts/d5_02_q8_chi2_gallery_gate.sh. -----------------------
row_begin a1_q8_chi2
(
  awk -F'\t' '$1 ~ /^[0-9]+$/ && $2 ~ /^cd=/ {print $1}' "$ARTDIR/q8_super.tsv" > "$WORK/q8.ranks"
  k=$(grep -c . "$WORK/q8.ranks")
  echo "# Q8 chi-square uniformity over the GALLERY ranks: 16 equal rank buckets, 15 dof (PREREG_F_CATALOG_T1_T4 §4)"
  echo "bucket_rule	floor(16*rank/N), exact integer arithmetic (bc)"
  echo "gallery_draws	$k"
  echo "requested_k	$Q8K"
  [ "$k" -gt 0 ] || { echo "Q8_CHI2_FAIL	no draw lines in q8_super.tsv"; exit 1; }
  # one bc process for every bucket index; bc's / at scale=0 is integer division, i.e. floor for r >= 0
  awk -v N="$N_TOTAL" '{print "(16*" $1 ")/" N}' "$WORK/q8.ranks" | BC_LINE_LENGTH=0 bc > "$WORK/q8.buckets"
  # 🔴 THE SUM OF SQUARES IS NOT AN awk INTEGER (RCQ01 F5, CONFIRMED 2026-09-09). This used to
  # accumulate S += c*c inside awk and print it with %d. Under an awk whose %d clamps to int32 --
  # busybox awk on this box, and reportedly some mawk builds -- 200,000 draws all in one bucket
  # give S = 2147483647 instead of 40000000000. Everything downstream is exact bc, so the clamp is
  # invisible: chi2 came out NEGATIVE, about -371,798, and sailed under the "chi2 < 37.70" bar. An
  # overwhelming failure of uniformity was published as PASS. gawk here does not clamp, which is
  # why it survived -- the defect is in which awk runs, and a battery must not depend on that.
  #
  # Counts are bounded by k and stay integers; only their sum of squares overflows. So awk emits
  # the histogram and bc squares and sums it.
  awk '{ b=$1+0; if ($1 !~ /^[0-9]+$/ || b<0 || b>15) bad++; else h[b]++ }
       END{ if (bad) { printf "BAD\t%d\n", bad; exit 1 }
            for (b=0;b<16;b++) printf "%d\t%d\n", b, h[b]+0 }' "$WORK/q8.buckets" > "$WORK/q8.hist" \
    || { echo "Q8_CHI2_FAIL	$(awk '$1=="BAD"{print $2}' "$WORK/q8.hist") rank(s) outside [0,N) (bucket index not in 0..15)"; exit 1; }
  echo "bucket	count"; cat "$WORK/q8.hist"
  # The counts must account for every draw. A histogram that lost or duplicated rows would give a
  # wrong chi2 that is still finite and could still pass; this makes that a FAIL, not a value.
  CSUM=$(awk '{printf "%s+", $2} END{print 0}' "$WORK/q8.hist" | BC_LINE_LENGTH=0 bc)
  [ "$CSUM" = "$k" ] || { echo "Q8_CHI2_FAIL	bucket counts sum to $CSUM, not the $k draws"; exit 1; }
  S=$(awk '{printf "%s*%s+", $2, $2} END{print 0}' "$WORK/q8.hist" | BC_LINE_LENGTH=0 bc)
  case "$S" in ''|*[!0-9]*) echo "Q8_CHI2_FAIL	sum of squared counts did not evaluate"; exit 1;; esac
  NUM=$(echo "16*$S - $k*$k" | bc)
  echo "sum_sq_counts	$S"
  echo "chi2_exact	$NUM/$k"
  # 3-place decimal, rounded half-up in integers (the ratio9 construction), never a float
  R=$(echo "(2*$NUM*1000 + $k) / (2*$k)" | bc)
  echo "chi2	$(echo "scale=3; $R/1000" | bc | sed 's/^\./0./')"
  echo "chi2_crit	37.70 (chi-square 15 dof, 99.9%; the pre-registered bar)"
  if [ "$(echo "100*$NUM < 3770*$k" | bc)" = 1 ]; then echo "Q8_CHI2_GALLERY	PASS"; exit 0; fi
  echo "Q8_CHI2_GALLERY	FINDING (chi2 >= 37.70: the exact-uniform sampler is not uniform over the gallery ranks)"
  exit 1
) >>"$RAW" 2>&1; rc=$?
cp "$RAW" "$ARTDIR/q8_chi2.txt"
row_end TR12_Q8_CHI2 $rc

# ---- A1.2d the engine's sampler self-test on its OWN n=13 universe -- plumbing, separately named
#            (D5-02). It exercises rank/unrank/member/sample on a 2.06e12-walk universe the engine builds
#            in-process, with its own chi-square over 20000 of ITS draws. It says nothing about the
#            gallery above and must never again be read as Q8's uniformity gate. ----------------------
row_begin a1_q8_midn13
( "$SOLVE" --kc-midn 13 --kc-chi2-samples 20000 ) >>"$RAW" 2>&1; rc=$?
row_end TR12_Q8_MIDN13 $rc

# ---- A1.3  Q4(a,c) the C3 census — histogram of the walk-functional cd over exact-uniform draws.
#            ESTIMATE with CI; the exact C15 count is priced and declined (~$3-5K; the C3 counting
#            obstruction itself was dissolved 2026-07-21, lean/C3Decomposition.lean) -- D5-16. ----
row_begin a1_q4ac
(
  "$SOLVE" --kc-sample "$FDIR" "$Q4ACM" "$SEED" 2>/dev/null > "$WORK/q4.raw" || exit 1
  awk -v M="$Q4ACM" -v T="$C3MAX" '
    /^[0-9]/ { if (match($0,/cd=[0-9]+/)) { v=substr($0,RSTART+3,RLENGTH-3)+0; h[v]++; n++; if (v<=T) le++ } }
    END{
      printf "# Q4(a,c) C3 census — ESTIMATE over SUPER, space=C1C2C4C5-SUPERSPACE\n"
      printf "# walk-functional units (cd_true = 2*(walk_cd+1)); threshold used T=%d\n", T
      printf "requested_M\t%d\nrealised_M\t%d\n", M, n
      # 🔴 F-5 D11 (2026-09-08): a short or empty sample printed realised_M < requested_M and PASSED --
      # nothing tested n (and at n=0 the Wilson line divided by zero, fatal only under gawk). A census
      # over fewer draws than commanded is a different census: the row FAILS on it.
      if (n != M) { printf "Q4AC_FAIL\trealised_M %d != requested_M %d\n", n, M; exit 1 }
      printf "cd\tcount\tfraction\n"
      k=0; for (v in h) a[k++]=v+0
      for (i=0;i<k;i++) for (j=i+1;j<k;j++) if (a[j]<a[i]) { t=a[i];a[i]=a[j];a[j]=t }
      for (i=0;i<k;i++) printf "%d\t%d\t%.6f\n", a[i], h[a[i]], h[a[i]]/n
      p = (n? le/n : 0)
      # Wilson score interval, 95%
      z=1.959964; d=1+z*z/n; c=(p+z*z/(2*n))/d; hw=z*sqrt(p*(1-p)/n + z*z/(4*n*n))/d
      printf "p_hat_cd_le_T\t%.8f\n", p
      printf "wilson95_lo\t%.8f\nwilson95_hi\t%.8f\n", (c-hw<0?0:c-hw), (c+hw>1?1:c+hw)
      # F-5 D8 (2026-09-08): Q4 deliverable (a) -- mu = P_C15(cd = T) = h[T]/le, the share of the
      # C15-accepted draws sitting exactly AT the ceiling (the level of KW itself; cd_true = 776 at T = 387),
      # with a Wilson interval on le trials; and deliverable (c), a per-bin Wilson interval for the
      # histogram, as a second table so the three-column histogram above keeps its shape.
      if (le > 0) {
        mu = h[T]/le; dl=1+z*z/le; cl=(mu+z*z/(2*le))/dl; hl=z*sqrt(mu*(1-mu)/le + z*z/(4*le*le))/dl
        printf "c15_accepted_draws\t%d\n", le
        printf "mu_hat_P_C15_cd_eq_T\t%.8f\n", mu
        printf "mu_wilson95_lo\t%.8f\nmu_wilson95_hi\t%.8f\n", (cl-hl<0?0:cl-hl), (cl+hl>1?1:cl+hl)
      } else {
        printf "c15_accepted_draws\t0\nmu_hat_P_C15_cd_eq_T\tNA\nmu_wilson95_lo\tNA\nmu_wilson95_hi\tNA\n"
      }
      printf "cd\tcount\twilson95_lo\twilson95_hi\n"
      for (i=0;i<k;i++) { q=h[a[i]]/n; dq=1+z*z/n; cq=(q+z*z/(2*n))/dq; hq=z*sqrt(q*(1-q)/n + z*z/(4*n*n))/dq
        printf "%d\t%d\t%.8f\t%.8f\n", a[i], h[a[i]], (cq-hq<0?0:cq-hq), (cq+hq>1?1:cq+hq) }
      printf "label\tESTIMATE-with-CI (exact C15 count PRICED AND DECLINED, TR-12 s9)\n"
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

# ---- A1.3b Q8's C3-rejection SUBSET, derived -- and the C15 file labelled for what it is (F-5 D9,
#            2026-09-08). QUERY_INVENTORY row Q8 (corrected 2026-09-05) records that q8_c15.tsv is NOT
#            the "~121 subset" of gallery 1: --kc-sample --kc-c3-max T rejects until it has Q8K ACCEPTED
#            draws, so it is a second, independent C15 gallery of exactly Q8K walks. TR-12 §Q8 still
#            describes a subset. This row (i) checks the C15 file against that label (exactly Q8K draws,
#            every one with cd <= T) and (ii) derives the ACTUAL subset for free -- the gallery-1 draws
#            with cd <= T -- printing its size and Wilson interval beside Q4(a,c)'s p_hat. The two are
#            independent samples of the same acceptance probability; they are printed, not gated. ----
row_begin a1_q8_subset
(
  fails=0
  c15n=$(awk -F'\t' '$1 ~ /^[0-9]+$/ && $2 ~ /^cd=/ {n++} END{print n+0}' "$ARTDIR/q8_c15.tsv")
  c15bad=$(awk -F'\t' -v T="$C3MAX" '$1 ~ /^[0-9]+$/ && $2 ~ /^cd=/ {if (substr($2,4)+0 > T) b++} END{print b+0}' "$ARTDIR/q8_c15.tsv")
  echo "q8_c15_label	independent-C15-sample	NOT a subset of q8_super.tsv: --kc-sample --kc-c3-max rejects until Q8K draws are ACCEPTED"
  echo "q8_c15_accepted_draws	$c15n	(requested Q8K=$Q8K)"
  echo "q8_c15_draws_above_T	$c15bad"
  [ "$c15n" -eq "$Q8K" ] || { echo "Q8_SUBSET_FAIL	q8_c15.tsv holds $c15n draws, not Q8K=$Q8K"; fails=1; }
  [ "$c15bad" -eq 0 ] || { echo "Q8_SUBSET_FAIL	$c15bad C15 draws have cd > T=$C3MAX -- the rejection sampler accepted what it should reject"; fails=1; }
  awk -F'\t' -v T="$C3MAX" -v K="$Q8K" '
    $1 ~ /^[0-9]+$/ && $2 ~ /^cd=/ { n++; if (substr($2,4)+0 <= T) le++ }
    END{
      printf "q8_super_draws\t%d\n", n
      printf "q8_super_subset_cd_le_T\t%d\n", le
      if (n != K) { printf "Q8_SUBSET_FAIL\tq8_super.tsv holds %d draws, not Q8K=%d\n", n, K; exit 1 }
      p = le/n; z=1.959964; d=1+z*z/n; c=(p+z*z/(2*n))/d; hw=z*sqrt(p*(1-p)/n + z*z/(4*n*n))/d
      printf "q8_super_subset_fraction\t%.8f\n", p
      printf "q8_subset_wilson95_lo\t%.8f\nq8_subset_wilson95_hi\t%.8f\n", (c-hw<0?0:c-hw), (c+hw>1?1:c+hw)
    }' "$ARTDIR/q8_super.tsv" || fails=1
  echo "q4ac_p_hat_cd_le_T	${FRAC_LE:-NA}	(row a1_q4ac, M=$Q4ACM draws: an independent sample of the same acceptance probability)"
  exit $fails
) >>"$RAW" 2>&1; rc=$?
cp "$RAW" "$ARTDIR/q8_c15_subset.tsv"
row_end TR12_Q8_SUBSET $rc

# ---- A1.4  Q2(b) the REL-order endpoints:  0, N-1, floor(N/2) --------------------------------
row_begin a1_q2b
(
  erc=0
  # 🔴 Q-483 (2026-09-11). This row PUBLISHED THREE WALKS AND CHECKED NEITHER. Its only failure
  # flag was the solver's EXIT STATUS, so a --kc-unrank that printed the wrong walk -- or the same
  # walk three times -- passed. The REL rank/unrank pair has an inverse that costs one extra ladder
  # descent per probe: `--kc-rank FDIR <walk>` must return the r that was unranked. That is the
  # same certificate `--kc-bracket` supplies for O3 in row a2_q2 (--kc-bracket is O3-ONLY,
  # solve.c:33459, so it cannot be used here). ⚠ THE PLAIN WALK LINE IS THE ONE THAT ROUND-TRIPS,
  # not the `record` line: measured 2026-09-11 at n=9, r=0 -> the plain line ranks 0 and the
  # `record m=32` line ranks 21, because the record form is a different representative of the
  # orbit. The solver's output is captured and cat'd rather than written straight to the row
  # stream so the walk can be read back; the bytes and their order are unchanged (both streams
  # still share one file description), so scripts/tr12_expected/n9/a1_q2b.txt does not move.
  for R in 0 "$N_MINUS_1" "$N_HALF"; do
      echo "### REL unrank r=$R"
      "$SOLVE" --kc-unrank "$FDIR" "$R" --kc-record > "$WORK/q2b_probe.out" 2>&1 || erc=1
      cat "$WORK/q2b_probe.out"
      w=$(grep -E '^[0-9]+(,[0-9]+)+$' "$WORK/q2b_probe.out" | head -1)
      nf=$(printf '%s' "$w" | awk -F',' '{print NF}')
      if [ -z "$w" ] || [ "${nf:-0}" -ne "$((2 * N_PAIRS))" ]; then
          echo "Q2B_FAIL	r=$R published no walk of 2n=$((2 * N_PAIRS)) hexagrams (got ${nf:-0})"; erc=1
      else
          rr=$("$SOLVE" --kc-rank "$FDIR" "$w" 2>/dev/null | grep -E '^[0-9]+$' | tail -1)
          [ "$rr" = "$R" ] \
            || { echo "Q2B_FAIL	rank(unrank($R)) = ${rr:-<none>} -- the REL pair is not an inverse at this rank"; erc=1; }
      fi
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
elif ! command -v python3 >/dev/null 2>&1 || [ ! -f "$REPO_ROOT/solve.py" ] \
     || ! PYTHONPATH="$REPO_ROOT" python3 -c 'import solve' >/dev/null 2>&1; then
    # 🔴 THE ROW SKIPS RATHER THAN RUNS WITHOUT THE SECOND LANGUAGE. The KC-X module header makes
    # the solve.py re-check a SHIPPING CONDITION of every Q5 number ("no Q5 number ships without
    # it"), so a run that produces the numbers and cannot re-check them has not reproduced the
    # row -- it has produced an unshippable artifact. Announcing that as a skip is the honest
    # verdict; announcing it as a pass would be the exact defect this battery exists to prevent.
    row_skip a1_q5 TR12_Q5 "SKIP:python3-unavailable" \
      "python3+solve.py unavailable — the TR-12 Q5 two-language obligation (solve.py --kc-x-recheck) cannot be discharged, so the extremal numbers are not shippable and the row is NOT run"
else
    row_begin a1_q5
    (
      erc=0
      # Every run writes a certificate, and solve.py re-evaluates every one of them below. This
      # is the TR-12 §Q5 TWO-LANGUAGE OBLIGATION, landed 2026-09-10 (N2; Codex KCQ03 #1, Fable
      # review 2026-09-09 F2). Before that date the registry's py_ref column named three solve.py
      # functions that did not exist and no artifact in the tree performed the check at all.
      CERTDIR="$WORK/q5certs"; rm -rf "$CERTDIR"; mkdir -p "$CERTDIR" || erc=1
      "$SOLVE" --kc-extremal list || erc=1
      for f in $("$SOLVE" --kc-extremal list 2>/dev/null | awk -F'\t' 'NR>1 && $1 !~ /^#/ && $1 !~ /=/ && $1!="" {print $1}'); do
          for dir in max min; do
              echo "### $f $dir"
              cert="$CERTDIR/$(printf '%s' "$f" | tr -c 'A-Za-z0-9_' '_')_$dir.json"
              "$SOLVE" --kc-extremal "$f" "$FDIR" "$dir" --kc-witness --kc-gdir "$GDIR" \
                       --kc-json "$cert" ; frc=$?
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
      # The second language. solve.py re-evaluates Phi on each printed witness from its OWN
      # formulas (_dist_multiset / _boundary_distances / _yang_count) and requires it to equal
      # the certificate's extreme_value AND witness_value. KC_X_PYCHECK=ERROR (nothing was
      # re-checked) fails the row exactly like KC_X_PYCHECK=FAIL: a check that measured nothing
      # must never read as agreement.
      echo "### two-language re-check (solve.py --kc-x-recheck)"
      ( cd "$REPO_ROOT" && PYTHONPATH="$REPO_ROOT" python3 solve.py --kc-x-recheck \
            "$CERTDIR"/*.json ) ; prc=$?
      echo "### two-language re-check rc=$prc"
      [ "$prc" -eq 0 ] || erc=1
      exit $erc
    ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_Q5 $rc
fi

# ================================================================================================
# GROUP A2 — f + g mounted.   Q3 / Q3-reader / EW-1 / V4 are PRE-SCAN (QUERY_INVENTORY §6).
# ================================================================================================
group "GROUP A2 — f + g mounted (still pre-scan)"

# A2.0  the g-layer shas, cross-checked against the builder's sidecars (F-5 R2; see a1_fsha).
ladder_sha_row a2_gsha TR12_GSHA "$GDIR"

# ---- A2.2  Q1 the H3b rank certificate: rank/unrank roundtrip + the r-1/r/r+1 bracket ---------
row_begin a2_q1
( "$SOLVE" --kc-o3-cert "$FDIR" "$GDIR" "$ANCHOR" --kc-cert-out "$ARTDIR/q1_rank.json" \
  && echo "### certificate JSON" && cat "$ARTDIR/q1_rank.json" ) >>"$RAW" 2>&1; rc=$?
row_end TR12_Q1 $rc

# ---- A2.2b Q1 THE LABELING THEOREM — the engineering gate. Q-394 item (1), QUERY_INVENTORY §9.1.
# rank_O3(KW) is ALGEBRAICALLY FORCED to 0 at full-31: the labels ARE the KW pair table, so KW is
# the smallest object by construction. That makes any rarity or "serial number" statement about KW
# under O3 meaningless — a theorem about the labelling, not a fact about the sequence.
#
# 🔴 SO THE GATE IS AN ENGINEERING ONE, NOT A FINDING. At full-31 the three decomposition fields
# must ALL be 0; anything else is a ranker or pair-table defect and must be caught before any
# number is published. At n=9 the labels are NOT anchor-derived, so the same theorem predicts a
# NON-zero triple — the committed fixture 13056/12960/96. Asserting zeros at n=9 would be asserting
# the theorem where it does not apply.
# Reads the certificate a2_q1 already wrote; no second --kc-o3-cert run.
if [ -s "$ARTDIR/q1_rank.json" ] && command -v python3 >/dev/null 2>&1; then
  row_begin a2_q1_labeling
  ( python3 - "$ARTDIR/q1_rank.json" "$N_PAIRS" <<'PYQ1'
import json, sys
d = json.load(open(sys.argv[1])); n = int(sys.argv[2])
r  = int(d["rank3"]); c = int(d["class_first_rank3"]); o = int(d["orient_idx"])
exp = (0, 0, 0) if n >= 31 else {9: (13056, 12960, 96)}.get(n)
print("n\t%d" % n)
print("rank3\t%d\nclass_first_rank3\t%d\norient_idx\t%d" % (r, c, o))
if exp is None:
    print("Q1_LABELING_FAIL\tno pinned expectation at n=%d" % n); sys.exit(1)
print("expected\t%d/%d/%d\t(%s)" % (exp[0], exp[1], exp[2],
      "the labeling theorem: anchor-derived labels force rank 0" if n >= 31
      else "n<31: labels are NOT anchor-derived, so the theorem predicts a non-zero rank"))
if r != c + o:
    print("Q1_LABELING_FAIL\trank3 != class_first_rank3 + orient_idx (%d != %d + %d)" % (r, c, o)); sys.exit(1)
print("decomposition\tOK\trank3 == class_first_rank3 + orient_idx")
if (r, c, o) != exp:
    print("Q1_LABELING_FAIL\tgot %d/%d/%d, expected %d/%d/%d" % (r, c, o, exp[0], exp[1], exp[2])); sys.exit(1)
if n >= 31:
    # F-5 D7 (2026-09-08): the vacuity, STATED in the artifact and CHECKED. rank 0 is a property of the
    # labels (QUERY_INVENTORY 9.1), not a finding about King Wen; the certificate must agree that the
    # anchor has no predecessor, and row a2_q2 checks unrank_O3(0) == the anchor byte-for-byte.
    pr = d.get("neighbor_prev_rank")
    print("neighbor_prev_rank\t%s" % pr)
    if pr != "NONE":
        print("Q1_LABELING_FAIL\trank3 == 0 but neighbor_prev_rank is %r, not NONE" % (pr,)); sys.exit(1)
    print("vacuity\tunrank_O3(0) = King Wen by the labeling theorem: the O3 order is built from KW's own pair table, so rank 0 says nothing about KW's rarity")
print("Q1_LABELING\tOK")
PYQ1
  ) >>"$RAW" 2>&1; rc=$?
  row_end TR12_Q1_LABELING $rc
else
  row_skip a2_q1_labeling TR12_Q1_LABELING "SKIP:no-cert-json" "rides a2_q1's --kc-o3-cert output, which was not produced"
fi

# ---- A2.2c Q1 THE LABELING THEOREM — EXECUTED, not argued. The audit's F1 objected that "a
# verifier that cannot show rank 0 on the relabeled universe has not tested the claim", and until
# 2026-09-06 the public tree had no such verifier: the demonstration lived in a script outside this
# repository, which makes a published theorem unreproducible by its readers.
# The oracle ranks ONE anchor under THREE labelings of the same order family over the fully
# enumerated universe, and fails in BOTH directions — change the fixture triple and O3 fails;
# change the relabeling and O3-KW9 stops being 0.
# n>9 is refused rather than attempted: 26,112 walks at n=9, 2.06e12 at n=13.
if [ "$N_PAIRS" -le 9 ] && command -v python3 >/dev/null 2>&1 && [ -f "$REPO_ROOT/verify.py" ] && [ -n "$ANCHOR" ]; then
  row_begin a2_q1_relabel
  (
    "$SOLVE" --kc-enum-desc "$FDIR" 2>/dev/null \
      | grep -E '^[0-9]+(,[0-9]+)+$' > "$WORK/q1_walks.txt"
    python3 "$REPO_ROOT/verify.py" --q1-labeling-oracle "$WORK/q1_walks.txt" --q1-anchor "$ANCHOR"
  ) >>"$RAW" 2>&1; rc=$?
  row_end TR12_Q1_RELABEL $rc
else
  row_skip a2_q1_relabel TR12_Q1_RELABEL "SKIP:universe-too-large" \
    "the oracle ranks the anchor under three labelings over EVERY walk; that is 26,112 at n=9 and 2.06e12 at n=13 — refused, not attempted. The theorem is about the labels, so a miniature universe demonstrates it."
fi

# ---- A2.3  Q3 the 31-step rarity profile via the O3 descent trace + neighbour bracket ---------
row_begin a2_q3
( "$SOLVE" --kc-o3-rank "$FDIR" "$GDIR" "$ANCHOR" --kc-trace --kc-bracket ) >>"$RAW" 2>&1; rc=$?
cp "$RAW" "$ARTDIR/q3_profile.txt"
grep '^#o3-trace' "$ARTDIR/q3_profile.txt" > "$ARTDIR/q3_profile.tsv" 2>/dev/null || true
row_end TR12_Q3 $rc

# ---- A2.3a Q3's C15 companion -- WITHDRAWN, and said so here (F-5 D14, 2026-09-08). TR-12 §Q3 withdrew
#            the "sampled per-step C3-pass corrections" on 2026-09-05 (QSET finding 2): no commanded path
#            produces it, and --kc-profile refuses --kc-c3-max (solve.c: "[kc-profile] --kc-c3-max is not
#            accepted here"). Until this date the battery had no row for it, so VERDICTS.txt could not tell
#            a ruled withdrawal from a forgotten leg. Named skip; NOT aggregated into TR12_Q3, which attests
#            the SUPER trace that IS commanded. -----------------------------------------------------------
row_skip a2_q3_c15 TR12_Q3_C15 "SKIP:withdrawn-2026-09-05" "WITHDRAWN 2026-09-05 (TR-12 §Q3, QSET finding 2): the C15 companion of the rarity profile has no instrument -- --kc-profile refuses --kc-c3-max and no commanded path produces per-step C3-pass corrections; every Q3 number is over the SUPER space"

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
#
#            🔴 STRING equality is FORCED, not assumed (2026-09-05, Codex MQ1A finding 3).  awk
#            compares two FIELDS -- or a field and a -v variable -- NUMERICALLY whenever both look
#            numeric, and it does so through a binary64.  Above 2^53 that is a 53-bit equality: at
#            full-31, N ~ 1.1e39, `p_den[2]` and `p_num[1]` can differ by 10^20 and still compare
#            equal, so the three identities below were exact only where the battery has run
#            (n=9, N=26112) and NOT at the one size where they matter.  Astra's executed case:
#            +1 and +1e20 on the second row, exit status and transcript unchanged.  Appending ""
#            makes every operand a string; a string comparison of CANONICAL decimals is integer
#            equality, and the canonical-form guard is what makes that sound (two %g-rounded
#            columns would otherwise be equal strings for unequal integers).  The pass-path
#            transcript is byte-identical to before, so scripts/tr12_expected/n9 is untouched.
#            Pinned by scripts/q3_reader_exactness_gate.sh (mutants, closure).
if [ -s "$ARTDIR/q3_profile_exact.tsv" ]; then
    row_begin a2_q3_reader
    (
      awk -F'\t' -v N="$N_TOTAL" -v NP="$N_PAIRS" '
        function canon(s){ return (s ~ /^(0|[1-9][0-9]*)$/) }
        $1 ~ /^[0-9]+$/ {
            step[++k]=$1; pn[k]=$11 ""; pd[k]=$12 ""; g[k]=$9 ""; gp[k]=$10 ""
        }
        END{
            fails=0
            NS = N ""
            printf "reader_steps\t%d\n", k
            if (k != NP+0) { printf "READER_FAIL\tstep count %d != n %d\n", k, NP; fails++ }
            if (!canon(NS)) { printf "READER_FAIL\tN=%s is not a canonical decimal integer\n", NS; fails++ }
            for (i=1;i<=k;i++) if (!canon(g[i]) || !canon(gp[i]) || !canon(pn[i]) || !canon(pd[i])) { printf "READER_FAIL\tstep %d: non-canonical integer column (g,g_parent,p_num,p_den)=(%s,%s,%s,%s)\n", i,g[i],gp[i],pn[i],pd[i]; fails++ }
            if (pd[1] != NS) { printf "READER_FAIL\tp_den[1]=%s != N=%s\n", pd[1], NS; fails++ }
            else printf "reader_p_den_1_eq_N\tOK (%s)\n", pd[1]
            for (i=2;i<=k;i++) if (pd[i] != pn[i-1]) { printf "READER_FAIL\tp_den[%d]=%s != p_num[%d]=%s\n", i, pd[i], i-1, pn[i-1]; fails++ }
            if (fails==0) printf "reader_telescoping\tOK (%d links)\n", k-1
            if (pn[k] != "1") { printf "READER_FAIL\tp_num[%d]=%s != 1\n", k, pn[k]; fails++ }
            else printf "reader_p_num_n_eq_1\tOK\n"
            for (i=1;i<=k;i++) { if (g[i]!=pn[i] || gp[i]!=pd[i]) { printf "READER_FAIL\tstep %d: (g,g_parent)=(%s,%s) != (p_num,p_den)=(%s,%s)\n", i,g[i],gp[i],pn[i],pd[i]; fails++ } }
            if (fails==0) printf "reader_product_p_i\t1/%s EXACT (telescoping, re-derived by the reader from the columns)\n", NS
            else printf "reader_product_p_i\tNOT ESTABLISHED (%d identity failure(s) above)\n", fails
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
            # 🔴 THE "BOTH OUTCOMES ARE FINDINGS" CONTRACT WAS RETIRED 2026-09-04 (QUERY_INVENTORY
            # §9.4, Q-394 item 4) because it was non-falsifiable: concentration and near-uniformity
            # were BOTH declared findings, so no observation could disconfirm anything. It is replaced
            # by the three pre-stated outcomes of the calibrated null in row a2_ew1_null. This row
            # reports the SPECTRUM; the VERDICT is emitted by that row as TR12_EW1_NULL.
            printf "interpretation_contract\tPRE-FIXED, calibrated null (QUERY_INVENTORY.md 9.4): top1_share vs the Q8 gallery 1st/99th percentiles, two-sided, once. Outcomes localized-constraint-candidate / typicality-bound / anti-concentration. Verdict token TR12_EW1_NULL, emitted by row a2_ew1_null.\n"
            if (d > 1e-4) { printf "EW1_FAIL\tsum_bits != log2N within 1e-4\n"; exit 1 }
            printf "EW1_SUM_EQ_LOG2N\tOK\n"
        }' "$ARTDIR/q3_profile_exact.tsv"
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/ew1_spectrum.tsv"
    row_end TR12_EW1 $rc
else
    row_skip a2_ew1 TR12_EW1 "SKIP:no-profile-tsv" "rides Q3's exact-rational profile TSV, which was not produced"
fi

# ---- A2.5b EW-1 the CALIBRATED NULL.  QUERY_INVENTORY §9.4 / Q-394 item (4). -------------------
# The contract this replaces was NON-FALSIFIABLE as written: concentration and near-uniform
# typicality were BOTH declared findings, so no observation could have disconfirmed anything.
# Codex A09 raised it, the audit's P3 proposed the calibrated null, §9.4 ADOPTED it 2026-09-04 --
# in the documentation only. The battery kept printing the retired contract and emitted no verdict
# until this row landed. That gap is why QUERY_INVENTORY promised a token the tree did not have.
#
# 🔴 THE THRESHOLDS ARE PRE-STATED AND THE TEST RUNS ONCE, TWO-SIDED. The statistic is
#       top1_share = max_i(bits_i) / sum_i(bits_i)
# for the anchor, placed against the empirical 1st/99th percentiles of the SAME statistic over the
# Q8 gallery walks. Three outcomes, fixed before any full-31 trace existed:
#       anchor > p99  -> localized-constraint-candidate
#       anchor < p01  -> anti-concentration
#       otherwise     -> typicality-bound
# "Two-sided" is the point: a one-sided test would have made anti-concentration unreportable, which
# is the same defect as the contract it replaces, merely narrower.
#
# 🔴 THE BAND IS 1,000 PROFILE RUNS AT n=31 (200 at n=9). EW-1 is listed DERIVED/no-compute in the
# inventory; that is true of the spectrum and FALSE of this null. Priced honestly: one --kc-profile
# descent per gallery walk.
#
# 🔴 q8_super.tsv WAS THE PHANTOM BAND. The original spec drew the band from a `bits` column of
# q8_super.tsv that does not exist. The gallery supplies WALKS here, and each walk's bits come from
# its own --kc-profile descent.
# 🔴 A MISSING DEPENDENCY IS A SKIP; A MISSING ANSWER IS A FAILURE. The first draft of this row
# conflated them. If the Q8 gallery was never produced — no ladder, or a1_q8 itself skipped — the
# null has no band and never could have. That is a SKIP with a stated reason, exactly as a2_ew1
# treats its missing profile TSV; failing there would report a defect in this row for a condition
# upstream of it. What must never be a skip is the null RUNNING and declining to produce a verdict,
# and that is still an exit 1 inside.
if [ -s "$ARTDIR/q8_super.tsv" ] && [ -n "$ANCHOR" ]; then
row_begin a2_ew1_null
(
  GAL="$ARTDIR/q8_super.tsv"

  # draw lines only: `<rank>\tcd=..\t<walk>`. The `record  m=..` lines are extremal exemplars,
  # not uniform draws, and including them would bias the band toward its own tail.
  awk -F'\t' '$1 ~ /^[0-9]+$/ && $2 ~ /^cd=/ {print $3}' "$GAL" > "$WORK/ew1_walks.txt"
  NW=$(wc -l < "$WORK/ew1_walks.txt")
  [ "$NW" -gt 0 ] || { echo "EW1_NULL_FAIL	gallery parsed to ZERO draw walks"; exit 1; }

  # 🔴 A PARTIAL DESCENT IS NOT A DESCENT (RCQ01 F1, CONFIRMED by execution 2026-09-09).
  # This used to pipe the solver into awk and accept ANY positive row count. Under a pipe the
  # solver's exit status is unreachable (pipefail is off here by design), so a --kc-profile that
  # printed KC_PROFILE=FAIL and exited 1 after ONE of nine rows returned a clean-looking
  # "1.000000000  3.462972000" -- against a true sum_bits of 14.672425 -- and the classifier
  # published TR12_EW1_NULL typicality-bound at rc 0 from it. With --mint-missing that becomes a
  # committed golden. At n=31 the band is 1,000 descents against the g-disk, where a walk that dies
  # mid-descent (I/O error, an eviction-resume, a bad layer) is exactly what this must catch.
  #
  # Three conditions, all required: the solver exited 0, it said so on its own line, and it produced
  # the number of steps this universe has. Anything else prints ERR, and the NG -ne NW check below
  # already fails the row on an ERR.
  top1_of(){ # $1=walk -> "<top1_share>\t<sum_bits>", or "ERR"
    if ! "$SOLVE" --kc-profile "$FDIR" "$GDIR" "$1" > "$WORK/ew1_prof.one" 2>/dev/null; then
      printf 'ERR\tERR\n'; return
    fi
    grep -qx 'KC_PROFILE=OK' "$WORK/ew1_prof.one" || { printf 'ERR\tERR\n'; return; }
    awk -F'\t' -v np="$N_PAIRS" '
      $1 ~ /^[0-9]+$/ { s += $13; if ($13+0 > mx) mx = $13+0; n++ }
      END { if (n == np+0 && n>0 && s>0) printf "%.9f\t%.9f\n", mx/s, s; else print "ERR\tERR" }
    ' "$WORK/ew1_prof.one"
  }

  : > "$WORK/ew1_top1.txt"
  while IFS= read -r w; do top1_of "$w"; done < "$WORK/ew1_walks.txt" >> "$WORK/ew1_top1.txt"

  NG=$(grep -cv '^ERR' "$WORK/ew1_top1.txt")
  if [ "$NG" -ne "$NW" ]; then
    echo "EW1_NULL_FAIL	$((NW-NG)) of $NW gallery profiles produced no bits — band incomplete"; exit 1
  fi

  read -r ANCHOR_T ANCHOR_S <<EOF2
$(top1_of "$ANCHOR")
EOF2
  [ "$ANCHOR_T" != "ERR" ] || { echo "EW1_NULL_FAIL	anchor profile produced no bits"; exit 1; }

  echo "# EW-1 calibrated null — pre-stated, two-sided, run once. QUERY_INVENTORY.md §9.4."
  echo "statistic	top1_share = max_i(bits_i) / sum_i(bits_i)"
  echo "band_source	Q8 gallery draws, one --kc-profile descent each"
  echo "gallery_walks	$NG"

  # 🔴 awk FUNCTIONS ARE TOP-LEVEL ONLY. Defining pct() inside END is a syntax error, and awk
  # reports it only when the program is parsed at RUN time -- after 200 profile descents have
  # already been spent building the band. Declared before the rules, where it belongs.
  sort -g "$WORK/ew1_top1.txt" | awk -F'\t' -v a="$ANCHOR_T" -v as="$ANCHOR_S" -v n="$NG" '
    # percentile: index ceil(q*n) into a 1-based sorted array, clamped. Spelled out because an
    # off-by-one here silently moves a threshold, and a moved threshold changes a published verdict.
    function pct(q,   i){ i=int(q*n+0.999999); if(i<1)i=1; if(i>n)i=n; return v[i] }
    { v[NR]=$1+0; s[NR]=$2+0 }
    END{
      p01=pct(0.01); p50=pct(0.50); p99=pct(0.99)
      # every walk telescopes to the same sum_bits = log2 N; a band whose walks disagree on the
      # denominator is not measuring one statistic
      smin=s[1]; smax=s[1]; for(i=1;i<=n;i++){ if(s[i]<smin)smin=s[i]; if(s[i]>smax)smax=s[i] }
      printf "sum_bits_min\t%.6f\nsum_bits_max\t%.6f\n", smin, smax
      if (smax-smin > 1e-4) { printf "EW1_NULL_FAIL\tgallery sum_bits spread %.9f exceeds 1e-4 — walks disagree on log2N\n", smax-smin; exit 1 }
      printf "top1_share_p01\t%.6f\ntop1_share_p50\t%.6f\ntop1_share_p99\t%.6f\n", p01, p50, p99
      printf "top1_share_min\t%.6f\ntop1_share_max\t%.6f\n", v[1], v[n]
      printf "anchor_top1_share\t%.6f\nanchor_sum_bits\t%.6f\n", a+0, as+0
      below=0; eq=0; for(i=1;i<=n;i++){ if(v[i]<a+0) below++; else if(v[i]==a+0) eq++ }
      printf "gallery_below\t%d\ngallery_equal\t%d\n", below, eq
      printf "empirical_two_sided_position\t%.4f\n", (below+eq/2)/n
      verdict = (a+0 > p99) ? "localized-constraint-candidate" \
              : ((a+0 < p01) ? "anti-concentration" : "typicality-bound")
      printf "TR12_EW1_NULL\t%s\n", verdict
    }' || exit 1
) >>"$RAW" 2>&1; rc=$?
cp "$RAW" "$ARTDIR/ew1_null.tsv"
# 🔴 THE TOKEN CARRIES THE VERDICT, NOT "PASS". QUERY_INVENTORY.md specifies
# TR12_EW1_NULL=<verdict>, so a reader greps `grep -qx 'TR12_EW1_NULL=typicality-bound'`. Recording
# PASS here would make the token say only that the row ran — which is exactly the information a
# calibrated null does not exist to provide. row_end_val keeps the golden diff and swaps the
# recorded value; if the verdict cannot be extracted it records FAIL rather than an empty string.
EW1_VERDICT=$(awk -F'\t' '$1=="TR12_EW1_NULL"{print $2; exit}' "$RAW")
row_end_val TR12_EW1_NULL "$rc" "$EW1_VERDICT"
else
  row_skip a2_ew1_null TR12_EW1_NULL "SKIP:no-q8-gallery" "the calibrated null places the anchor against a band of one --kc-profile descent per Q8 gallery walk; the gallery (or the anchor) was not produced, so there is no band"
fi

# ---- A2.6  V4 the shells series g(prefix_k) vs k.  The TSV; the FIGURE is PENDING:viz. --------
if [ -s "$ARTDIR/q3_profile_exact.tsv" ]; then
    row_begin a2_v4
    (
      awk -F'\t' 'BEGIN{print "k\tg\tg_parent\tf"} $1 ~ /^[0-9]+$/ {printf "%s\t%s\t%s\t%s\n",$1,$9,$10,$8}' \
        "$ARTDIR/q3_profile_exact.tsv" | tee "$WORK/v4_rows.tsv"
      arc=${PIPESTATUS[0]}
      # 🔴 Q-483 (2026-09-11). THE EXACT D11 SHAPE, on a PUBLISHED surface. This was a bare awk
      # re-projection of Q3's exact-rational TSV with no row count, no identity, and no comparison
      # to row a2_q3_reader next door, which validates the very columns this table republishes. A
      # profile TSV that was absent, truncated, or written with a shifted column layout yielded a
      # header-only (or short, or wrong) table at rc 0.
      #
      # THREE CHECKS, in increasing strength:
      #  (1) the emitted table must carry one data row per source data row, and n of them, in
      #      step order 1..n -- that is what kills the header-only table;
      #  (2) THE TIE TO a2_q3_reader: that row asserts g == p_num and g_parent == p_den on the
      #      source columns (:1587) after proving them canonical decimals and telescoping. This
      #      row therefore checks its OWN published cells against those same source columns, so a
      #      projection that read the wrong column cannot publish a plausible table. String
      #      comparison of canonical decimals is exact integer equality, which is why both sides
      #      are forced to strings with `""` -- awk would otherwise carry 192-bit g values through
      #      a double and two unequal integers would compare equal;
      #  (3) the telescoping identity of the shells series itself, IN bc, never awk:
      #      g_parent[1] == N, g_parent[k] == g[k-1], g[n] == 1, and the product form
      #      N * prod(g) == prod(g_parent) -- which is Pi p_i = 1/N with the denominators cleared.
      #      At full-31 those products run to thousands of bits; bc is exact and awk is not.
      # NOT CHECKED, deliberately: f is monotone non-decreasing in every profile measured here,
      # and the DP argument for it (every prefix reaching s_k extends by the walk's own next
      # transition) does NOT survive f being a QUOTIENT count -- orbit merging could break the
      # injectivity. An assertion I cannot defend at n=31 is worse than none, so f is tied to its
      # source column in (2) and nothing further is claimed about it.
      # Success output is UNCHANGED -- only a failure prints -- so the n=9 golden does not move.
      fails=0
      [ "$arc" -eq 0 ] || { echo "V4_FAIL	the awk projection of q3_profile_exact.tsv exited $arc"; fails=1; }
      nsrc=$(awk -F'\t' '$1 ~ /^[0-9]+$/' "$ARTDIR/q3_profile_exact.tsv" | grep -c .)
      k=0; prev_g=""; last_g=""; gprod="1"; gpprod="1"
      while IFS=$'\t' read -r kk gg gp ff; do
          case "$kk" in ''|*[!0-9]*) continue ;; esac          # the header line
          k=$((k+1))
          [ "$kk" = "$k" ] || { echo "V4_FAIL	emitted row $k carries step=$kk -- V4 must follow the walk in order"; fails=1; }
          ok=1
          for v in "$gg" "$gp" "$ff"; do
              case "$v" in ''|0|*[!0-9]*) ok=0 ;; esac
          done
          if [ "$ok" -ne 1 ]; then
              echo "V4_FAIL	step $kk: (g,g_parent,f)=($gg,$gp,$ff) is not three positive canonical decimal integers"; fails=1
              continue
          fi
          if [ "$k" -eq 1 ]; then
              [ "$gp" = "$N_TOTAL" ] || { echo "V4_FAIL	g_parent[1]=$gp != N=$N_TOTAL"; fails=1; }
          else
              [ "$gp" = "$prev_g" ] || { echo "V4_FAIL	g_parent[$kk]=$gp != g[$((k-1))]=$prev_g -- the shells series does not telescope"; fails=1; }
          fi
          gprod="$gprod*$gg"; gpprod="$gpprod*$gp"; prev_g="$gg"; last_g="$gg"
      done < "$WORK/v4_rows.tsv"
      [ "$k" -gt 0 ] && [ "$k" -eq "$nsrc" ] && [ "$k" -eq "$N_PAIRS" ] \
        || { echo "V4_FAIL	emitted $k data rows, source carries $nsrc, n=$N_PAIRS -- a header-only or short table is not the shells series"; fails=1; }
      [ "$last_g" = "1" ] \
        || { echo "V4_FAIL	g[n]=${last_g:-<none>} != 1 -- the last shell must hold exactly the walk itself"; fails=1; }
      lhs=$(BC_LINE_LENGTH=0 bc <<< "$N_TOTAL*($gprod)"); rhs=$(BC_LINE_LENGTH=0 bc <<< "$gpprod")
      [ -n "$lhs" ] && [ "$lhs" = "$rhs" ] \
        || { echo "V4_FAIL	N*prod(g) != prod(g_parent) -- the product form of Pi p_i = 1/N does not hold over the published cells"; fails=1; }
      awk -F'\t' '
        NR==FNR { if ($1 ~ /^[0-9]+$/) { pn[$1]=$11 ""; pd[$1]=$12 ""; sf[$1]=$8 "" } ; next }
        $1 ~ /^[0-9]+$/ {
            if (!($1 in pn)) { printf "V4_FAIL\tstep %s has no counterpart in q3_profile_exact.tsv\n", $1; bad=1; next }
            if ($2 "" != pn[$1]) { printf "V4_FAIL\tstep %s: published g=%s but the source p_num=%s\n", $1,$2,pn[$1]; bad=1 }
            if ($3 "" != pd[$1]) { printf "V4_FAIL\tstep %s: published g_parent=%s but the source p_den=%s\n", $1,$3,pd[$1]; bad=1 }
            if ($4 "" != sf[$1]) { printf "V4_FAIL\tstep %s: published f=%s but the source f=%s\n", $1,$4,sf[$1]; bad=1 }
        }
        END{ exit bad?1:0 }' "$ARTDIR/q3_profile_exact.tsv" "$WORK/v4_rows.tsv" || fails=1
      exit $fails
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/v4_shells.tsv"
    row_end TR12_V4_TSV $rc
else
    row_skip a2_v4 TR12_V4_TSV "SKIP:no-profile-tsv" "rides Q3's exact-rational profile TSV, which was not produced"
fi

# ---- A2.7  Q2 the O3-order endpoints:  0, N-1, floor(N/2) ------------------------------------
row_begin a2_q2
(
  erc=0
  # B7: --kc-bracket makes each probe a VERIFICATION, not just an output. It unranks r-1, r, r+1,
  # ranks all three back, checks strict O3 order with the independent comparator, prints
  # CERTIFICATE PASS|FAIL and returns rc=1 on any failure. At the two endpoints the "r-1: NONE" /
  # "r+1: NONE" lines ARE the endpoint certificate, which a shell round-trip cannot produce.
  # ⚠ SCOPE: this certifies the rank/unrank PAIR, not the ladder. Measured: with a g ladder
  # corrupted at 3 of 12 probed offsets, --kc-g-check fails rc=70 while the bracket still
  # certifies PASS -- rank and unrank read the same wrong g and agree with each other. The
  # ladder-sensitive checks are a2_gcheck and a2_gsha, and Q2 completion requires those too.
  for R in 0 "$N_MINUS_1" "$N_HALF"; do
      echo "### O3 unrank r=$R (two endpoints + midpoint)"
      "$SOLVE" --kc-o3-unrank "$FDIR" "$GDIR" "$R" --kc-bracket > "$WORK/q2_probe.out" 2>&1 < /dev/null || erc=1
      cat "$WORK/q2_probe.out"
      if [ "$R" = 0 ] && [ "$N_PAIRS" -ge 31 ]; then
          # F-5 D7 (2026-09-08): at full-31 the r=0 probe is VACUOUS as a finding -- the labeling theorem
          # (QUERY_INVENTORY 9.1) makes unrank_O3(0) = King Wen by construction -- and it is the ONE
          # external anchor of the O3 machinery (inventory row Q2, B32): the ranker never took KW as an
          # input, so the byte-identity of its rank-0 output with KW's walk is CHECKED here, not assumed.
          # n=9 output is untouched (there the anchor is the midpoint and the theorem does not apply).
          w0=$(grep -E '^[0-9]+(,[0-9]+)+$' "$WORK/q2_probe.out" | head -1)
          echo "# unrank_O3(0) = King Wen is a THEOREM about the labels (QUERY_INVENTORY 9.1), not a finding about KW;"
          echo "# it is also the only external anchor for the O3 rank/unrank pair at full-31, checked byte-for-byte here."
          if [ -n "$w0" ] && [ "$w0" = "$ANCHOR" ]; then
              echo "Q2_R0_IS_ANCHOR	YES"
          else
              echo "Q2_R0_IS_ANCHOR	NO	unrank_O3(0)=${w0:-<no walk line>}	anchor=$ANCHOR"; erc=1
          fi
      fi
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
      echo "# inputs: every q7_*.json written by the Q7 legs above. D5-04: until TR12_Q7_WITNESSES lands, the"
      echo "# only IN input is KW (the historical arrangements are OUT), and rank_O3(KW) = 0 is a labeling theorem."
      for j in "$ARTDIR"/q7_*.json; do
          [ -f "$j" ] || continue
          v=$(sed -n 's/.*"verdict_super": "\([^"]*\)".*/\1/p' "$j" | head -1)
          lab=$(sed -n 's/.*"label": "\([^"]*\)".*/\1/p' "$j" | head -1)
          arr=$(sed -n 's/.*"arrangement": "\([^"]*\)".*/\1/p' "$j" | head -1)
          echo "### $(basename "$j") label=$lab verdict_super=$v"
          if [ "$v" = "IN" ] && [ -n "$arr" ]; then
              # §0.4(2): drop the first two values (the C4-anchored pair 63,0), pass the rest
              w=$(printf '%s' "$arr" | cut -d, -f3-)
              "$SOLVE" --kc-o3-rank "$FDIR" "$GDIR" "$w" > "$WORK/q7rank.out" 2>&1 || erc=1
              cat "$WORK/q7rank.out"
              # 🔴 F-5 ROUND 4 B3 (2026-09-11). This row took the solver's EXIT STATUS and nothing
              # else, so a stub printing `rank3=5` for a walk that is not the anchor passed it
              # (measured by the reviewer). The row is n>=31-ONLY, so no n=9 golden can ever cover
              # it and no rehearsal has exercised it -- its FIRST execution is the full-31 run, and
              # it publishes King Wen's "serial number". Two things are asserted, and both are
              # forced rather than expected:
              #   (i)  rank_O3(KW) = 0 is a LABELING THEOREM -- the O3 order is built from KW's own
              #        pair table, so KW is the least object by construction (QUERY_INVENTORY §9.1).
              #        A nonzero rank here is not a surprising result; it means the labels moved.
              #   (ii) the walk this row ranks is reached by `cut -d, -f3-` of q7_kw.json, a SECOND
              #        derivation of King Wen's walk, and nothing compared it to $ANCHOR. That is
              #        the two-arms-never-compared defect that tests.py::TestKingWenTableAgrees...
              #        pins one level down, still open at this level until now.
              r3=$(sed -n 's/.*\brank3=\([0-9][0-9]*\).*/\1/p' "$WORK/q7rank.out" | head -1)
              if [ -z "$r3" ]; then
                  echo "Q7RANKS_FAIL	$(basename "$j"): no rank3= value was printed -- an unmeasured rank is not a rank"; erc=1
              elif [ "$r3" != "0" ]; then
                  echo "Q7RANKS_FAIL	$(basename "$j"): rank3=$r3, but rank_O3 of an anchor-derived labeling is FORCED to 0"; erc=1
              fi
              if [ "$lab" = "KW" ] && [ "$w" != "$ANCHOR" ]; then
                  echo "Q7RANKS_FAIL	$(basename "$j"): the walk ranked here is not \$ANCHOR -- two derivations of King Wen's walk disagree"; erc=1
              fi
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

# ---- A2.9  Q1(c).  QUERY_INVENTORY §3.5: --kc-sample draws over ALL of SUPER and has no
#            rank-range argument, so the "[0, rank_O3(anchor))" restriction is post-filter
#            arithmetic here.  The REALISED M is reported, never the requested M.  Note
#            --kc-sample --kc-c3-max returns exactly M accepted draws and does NOT report its
#            rejection rate, so p-hat is taken from the UNFILTERED draws' cd column.
#
# 🔴 N3, 2026-09-10 — THE INTERVAL IS MEASURED FIRST, AND THAT MEASUREMENT IS THE VERDICT.
# Until today this row was guarded by `[ "$N_PAIRS" -ge 31 ]` and, above that threshold, emitted
# the hand-typed token SKIP:merged-into-Q4AC. The guard was right about the COST -- at n>=31 the
# awk keep-test `a < RANCH` can never hold, so the row could only reach Q1C_FAIL after burning the
# 3-5 h descent loop (D5-01, 2026-09-05) -- but it was a PROXY for the real reason, and it
# published that reason as a claim no program had checked.
#
# The real reason is a number: rank_O3(anchor). O3 is a bijection onto [0, N), so the cardinality
# of the conditioning interval [0, rank_O3(anchor)) IS that rank, and the interval is empty
# exactly when the anchor is the O3-least object. At n=31 the O3 labels are King Wen's own pair
# table, which forces rank 0 (QUERY_INVENTORY §9.1) -- so the answer to Q1c at full-31 is not
# "we did not run it", it is "we ran it and the conditioning set is empty". q1c_interval_measure
# establishes that from --kc-o3-cert, --kc-o3-rank and the neighbour bracket, all three already
# on disk, and the expensive draw loop runs only when the interval it draws from has been
# measured to be non-empty. n<31 is unchanged: there the anchor is not O3-least, the interval
# has 13056 elements at n=9, and the estimate runs exactly as before -- which is also this row's
# standing negative control, executed on every n=9 run of the battery.
row_begin a2_q1c
Q1C_VF="$WORK/q1c_verdict.txt"
q1c_interval_measure "$ARTDIR/q1_rank.json" "$ARTDIR/q3_profile.txt" "$Q1C_VF" >>"$RAW" 2>&1
Q1C_VAL=$(sed -n 's/^TR12_Q1C=//p' "$Q1C_VF" | head -1)
case "${Q1C_VAL:-}" in
  NONEMPTY:*)
    (
      RANCH=$(awk -F'\t' '$1=="Q1C_CARD"{print $2; exit}' "$RAW")
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
    Q1C_VAL="PASS" ;;
  EMPTY:*|ERROR:*)
    rc=0 ;;
  *)
    # The producer wrote nothing matchable. That is itself an unmeasured state, not a pass.
    echo "q1c_error	q1c_interval_measure produced no TR12_Q1C= line" >>"$RAW"
    Q1C_VAL="ERROR:producer-emitted-no-verdict"; rc=0 ;;
esac
cp "$RAW" "$ARTDIR/q1_c15_estimate.tsv"
row_end_val TR12_Q1C $rc "$Q1C_VAL"

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
# an interruption at ANY point before the end yields nothing.  Everything above is already banked.
# 🔴 2026-09-05: this comment said "at hour 47 of 48-85".  That wall figure is WITHDRAWN -- it was the
# f+g FOOTPRINT divided by a measured rate, and kc_h_scan_layers does not stream g, it makes
# 2*(31-k) random point lookups into it per f entry at layer k.  The real wall has never been
# measured end to end and is much longer.  documentation/CORRECTIONS.md.
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
    # Cross-checked against the t builder's sidecars (F-5 R2; see a1_fsha).
    ladder_sha_row b_tsha TR12_TSHA "$TDIR"

    row_begin b_tcheck
    ( "$SOLVE" --kc-t-check "$FDIR" "$TDIR" ) >>"$RAW" 2>&1; rc=$?
    row_end TR12_TCHECK $rc
else
    row_skip b_tsha TR12_TSHA "SKIP:no-tdir" "no TDIR given — the t-ladder's per-layer shas cannot be taken"
    row_skip b_tcheck TR12_TCHECK "SKIP:no-tdir" "no TDIR given — the t-ladder is REQUIRED for the Exhaustion Atlas and every per-branch number (TR-12 §R.0)"
fi

if [ -n "$ATLAS_IN" ]; then
    # ---- B.S  an atlas handed in by the caller (--atlas). The scan is the caller's; what THIS
    #           battery attests is that the file is a scan atlas of THIS universe, and (through the
    #           expected block derived from b_scan.txt where one exists) that it is byte-identical
    #           to the golden whole-shot atlas. TR12_SCAN is a named SKIP: no scan ran here. --------
    row_begin b_atlas_supplied
    (
      [ -s "$ATLAS_IN" ] || { echo "SUPPLIED_ATLAS_FAIL	$ATLAS_IN is missing or empty"; exit 1; }
      cp -f "$ATLAS_IN" "$ATLAS" || exit 1
      python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
assert d.get("type") == "roae-kc-scan-atlas", "wrong type tag"
assert d.get("layers") and d.get("branch_atlas"), "layers/branch_atlas missing"
assert str(d.get("N_total")) == sys.argv[2], "atlas N_total %s != ladder N %s" % (d.get("N_total"), sys.argv[2])
' "$ATLAS" "$N_TOTAL" || { echo "SUPPLIED_ATLAS_FAIL	$ATLAS_IN is not a scan atlas of this universe"; exit 1; }
      echo "### atlas"; cat "$ATLAS"
    ) >>"$RAW" 2>&1; rc=$?
    [ "$rc" -eq 0 ] && SCAN_OK=1
    row_end TR12_SCAN_SUPPLIED $rc
    row_skip b_scan TR12_SCAN "SKIP:atlas-supplied" "--atlas was passed: this battery did NOT run the scan. The supplied atlas was validated in row b_atlas_supplied (TR12_SCAN_SUPPLIED) and Group C ran against it; whoever produced it attests the scan itself"
elif [ "$DO_SCAN" -eq 0 ]; then
    row_skip b_scan TR12_SCAN "SKIP:no-scan-requested" "--no-scan was passed; the atlas was not produced, so every Group C row is skipped too"
elif [ "$HAVE_T" -eq 0 ]; then
    row_skip b_scan TR12_SCAN "SKIP:no-tdir" "no TDIR: --kc-scan without --kc-tdir yields an atlas with no t_source, and XA-b cannot be gated"
else
    row_begin b_scan
    # --kc-raw is REQUIRED at n=31 or marginal_raw is not emitted and V1 dies. It is automatic at
    # n<=13; passing it always costs nothing and removes the single most expensive mistake in the
    # program (re-running the whole unresumable pass to add a column -- a wall this project no
    # longer puts a number on; the retired "48-85 h" is withdrawn, documentation/CORRECTIONS.md).
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

    # ---- C.5 Q10(a): RE-SPECIFIED 2026-09-04 (Q-394 section 5; landed here 2026-09-05 as D5-08). ----
    #      As first written this row printed layer_flow/24 for every layer as an "orbit census" -- but
    #      the atlas gate per_layer_flow_eq_N forces flow == N, so the "census" was N/24 printed n times
    #      (n=9: 1088 x 9) -- and the promised "KW's orbit's rank" had no commanded source (the o3-cert's
    #      own line: class-rank NOT computed) and is 0 under KW-derived labels anyway. Now:
    #        (i)   N/24 stated ONCE, as the identity it is (the free order-24 action on solutions);
    #        (ii)  the mod-24 gate on every layer flow (kept; kernel-backed);
    #        (iii) the census CONTENT: the per-layer STATE census by G-orbit-size class and the branching
    #              histogram, transcribed from the f-ladder sidecars f1c5_layer_stats_XX.json that
    #              --kc-build already wrote (orbit_size_census = [orbit_size, n_masks, n_entries] triples;
    #              branching.hist = [children, n_states] pairs; sidecar schema v2). Read, not computed:
    #              this is a transcription of Stage F's own sidecars (D5-15). A missing or unparseable
    #              sidecar FAILS the row, and the last layer's mass_total must equal N (the f-ladder's own
    #              count agreeing with --kc-count), so a transcription cannot silently skip a layer;
    #        (iv)  the KW-orbit-rank leg is DROPPED: uncommanded, and vacuous under KW-derived labels.
    #      Pinned by scripts/d5_08_q6_q10a_shell_gate.sh.
    row_begin c_q10a
    (
      echo "# Q10(a) — (i) the N/24 identity, stated once; (ii) the per-layer mod-24 gate; (iii) the per-layer"
      echo "# STATE census by G-orbit-size class + branching histogram, transcribed from the f-ladder sidecars."
      echo "# (iv) KW-orbit-rank: MEASURED separately as TR12_Q10A_KWRANK (row c_q10a_kwrank, N3 2026-09-10);"
      echo "# this line used to ASSERT it was dropped. Q-394 §5 / D5-08."
      echo "N_div_24	$N_DIV24	# = N/24, the RECORD-level orbit identity. NOT the number of walk-orbits: 24 is the record-level divisor, and at the orientation-explicit sequence level orbits have size 48, so N/24 is 2x the sequence-orbit count (TR-11 sec2 precision note; measured n=9: 544 walk-orbits, N/24 = 1088). Identical at every layer because every layer flow == N (gated in c_atlas)"
      echo "## per-layer flow mod-24 gate (atlas layers[k].flow)"
      echo -e "k\tflow\tflow_mod_24"
      fails=0; i=0
      while read -r fl; do
          m=$(echo "$fl % 24" | bc)
          printf '%d\t%s\t%s\n' "$i" "$fl" "$m"
          [ "$m" = "0" ] || fails=1
          i=$((i+1))
      done < <(grep -o '"flow": "[0-9]*"' "$ATLAS" | sed 's/.*"\([0-9]*\)"$/\1/')
      echo "Q10A_LAYER_MOD24_FAILS	$fails"
      echo "## per-layer state census, transcribed from f1c5_layer_stats_XX.json (frame: canonical quotient, orbit-unweighted; mass_total = f-prefix mass)"
      echo -e "k\tn_masks\tn_entries\tmass_total\torbit_size_census[size,n_masks,n_entries]\tbranching_hist[children,n_states]"
      k=0; miss=0; last_mt=""
      while [ "$k" -le "$N_PAIRS" ]; do
          sc=$(printf '%s/f1c5_layer_stats_%02d.json' "$FDIR" "$k")
          if [ ! -s "$sc" ]; then printf '%d\tMISSING-SIDECAR\n' "$k"; miss=$((miss+1)); k=$((k+1)); continue; fi
          # every field read here is a top-level scalar or array on its own line in the v2 sidecar
          nm=$(sed -n 's/^  "n_masks": \([0-9]*\),*$/\1/p' "$sc" | head -1)
          ne=$(sed -n 's/^  "n_entries": \([0-9]*\),*$/\1/p' "$sc" | head -1)
          mt=$(sed -n 's/^  "mass_total": "\([0-9]*\)",*$/\1/p' "$sc" | head -1)
          oc=$(sed -n 's/^  "orbit_size_census": \(\[.*\]\),*$/\1/p' "$sc" | head -1)
          bh=$(grep -o '"branching": {[^}]*}' "$sc" | sed -n 's/.*"hist": \(\[.*\]\)}.*/\1/p' | head -1)
          if [ -z "$nm" ] || [ -z "$ne" ] || [ -z "$mt" ] || [ -z "$oc" ] || [ -z "$bh" ]; then
              printf '%d\tUNPARSED-SIDECAR\n' "$k"; miss=$((miss+1)); k=$((k+1)); continue
          fi
          printf '%d\t%s\t%s\t%s\t%s\t%s\n' "$k" "$nm" "$ne" "$mt" "$oc" "$bh"
          [ "$k" -eq "$N_PAIRS" ] && last_mt="$mt"
          k=$((k+1))
      done
      echo "Q10A_SIDECARS_MISSING	$miss"
      if [ "$last_mt" = "$N_TOTAL" ]; then echo "Q10A_LAST_LAYER_MASS_EQ_N	YES ($last_mt)"
      else echo "Q10A_LAST_LAYER_MASS_EQ_N	NO (sidecar k=$N_PAIRS mass_total='$last_mt', N=$N_TOTAL)"; fails=1; fi
      exit $(( (fails || miss) ? 1 : 0 ))
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/q10_orbit_census.tsv"
    row_end TR12_Q10A $rc

    # ---- C.5b Q10(a) KW-ORBIT-RANK — the dropped leg, given a token and a producer (N3, 2026-09-10).
    #      Line (iv) of the row above used to be the whole treatment: a comment reading "KW-orbit-rank:
    #      DROPPED (no commanded source; 0 under KW-derived labels)". Both halves of that were true and
    #      neither was checked, and prose in a golden is not a verdict a reader can grep -- so from
    #      outside, "dropped" was indistinguishable from "forgotten". It now has its own whole-line
    #      token, and the token is EMPTY only when both halves are MEASURED to hold:
    #        (1) the o3-cert supplies no class/orbit rank (checked by field name, so a future producer
    #            ENDS the null instead of aging it into a lie), and
    #        (2) rank_O3(anchor) = 0, which forces the orbit rank to 0 whatever a producer computed.
    #      TR12_Q10A itself is deliberately NOT relabelled: that row measures four live things (N/24,
    #      the per-layer mod-24 gate, the sidecar state census, the last-layer mass identity) and is
    #      pinned PASS/FAIL by scripts/a2_slot_verdict_gate.sh. Calling it EMPTY would be a worse
    #      conflation than the one this change exists to remove.
    #      Zero marginal cost: it re-reads a2_q1's certificate and runs nothing.
    row_begin c_q10a_kwrank
    Q10AKW_VF="$WORK/q10a_kwrank_verdict.txt"
    q10a_kwrank_measure "$ARTDIR/q1_rank.json" "$Q10AKW_VF" >>"$RAW" 2>&1
    Q10AKW_VAL=$(sed -n 's/^TR12_Q10A_KWRANK=//p' "$Q10AKW_VF" | head -1)
    if [ -z "${Q10AKW_VAL:-}" ]; then
        echo "q10a_error	q10a_kwrank_measure produced no TR12_Q10A_KWRANK= line" >>"$RAW"
        Q10AKW_VAL="ERROR:producer-emitted-no-verdict"
    fi
    cp "$RAW" "$ARTDIR/q10_kwrank.tsv"
    row_end_val TR12_Q10A_KWRANK 0 "$Q10AKW_VAL"

    # ---- C.6 Q6 (REDUCED FORM, QUERY_INVENTORY §3.1) + the anchor's per-layer class statistics -----
    #      The atlas carries per-layer per-DISTANCE-CLASS mass, not per-(state,choice) mass.  The
    #      spec's per-choice argmax/argmin needs a new emitter.  This ships the reduced table and
    #      SAYS SO in the artifact; it is never presented as the spec's table.
    #
    #      D5-08 (2026-09-05; Q-394 section 3 / Codex A09 f3 / Q-48). Until this date the last two
    #      columns were anchor_mass_below / anchor_percentile, read from the --kc-trace mass_below
    #      column. mass_below is the O3 rank-block contribution at that step (n=9 k=1: 2720, beside a
    #      g_parent of 2368 -- it is not bounded by anything a percentile is bounded by), and at full-31
    #      it is identically 0 for KW by the labeling theorem. Replaced by the two statistics Q-394
    #      defines, computed for the anchor walk from the atlas by_class masses and the anchor's own
    #      transition class per step (the dclass column of --kc-profile --kc-tsv; O3-independent):
    #        anchor_class_mass_k = m_k(d_k)             the mass of the anchor's class at layer k
    #        anchor_p_k          = m_k(d_k) / N         P(a uniform SUPER walk takes the anchor's class at k)
    #        anchor_class_pct_k  = sum_{d : m_k(d) <= m_k(d_k)} m_k(d) / N
    #                              the share of walks whose step-k class is no heavier than the anchor's
    #                              (== 1 when the anchor's class is the layer argmax)
    #      Both are defined for every walk and need no Q3 join. The consumer (solve.py atlas_emit_q6)
    #      emits the same two for KW at n=31 and -1 below it; this leg computes them for the reduced-n
    #      anchor as well, so the fixture is live at n=9 -- Q-394 section 3 pre-registered the n=9 values
    #      (anchor classes 1,2,2,4,2,2,1,4,2; anchor_p .544118 ...; anchor_class_pct 1 1 1 .419118 1 1 1
    #      .209559 1), and c_q6.txt carries them. Pinned by scripts/d5_08_q6_q10a_shell_gate.sh.
    row_begin c_q6
    (
      echo "# Q6 — REDUCED FORM (QUERY_INVENTORY §3.1): per-layer per-DISTANCE-CLASS mass."
      echo "# The spec's per-(state,choice) argmax/argmin is NOT served by this atlas schema."
      echo "# §9 already rules the per-layer argmin 'loneliest corridor' figure fodder, not a headline."
      echo "# anchor_* (Q-394 §3): the anchor's transition class d_k at layer k (profile dclass, step k+1), its class"
      echo "# mass m_k(d_k), anchor_p = m_k(d_k)/N, anchor_class_pct = sum_{d: m_k(d) <= m_k(d_k)} m_k(d)/N. Label-free."
      echo -e "k\tflow\td1\td2\td3\td4\td6\tanchor_d\tanchor_class_mass\tanchor_p\tanchor_class_pct"
      # the anchor's class per step from --kc-profile --kc-tsv (column 6 = dclass); step s = layer s-1
      awk -F'\t' '$1 ~ /^[0-9]+$/ { print $1-1 "\t" $6 }' "$ARTDIR/q3_profile_exact.tsv" > "$WORK/q6_ad.tsv" 2>/dev/null || true
      i=0; fails=0
      while read -r line; do
          fl=$(printf '%s' "$line" | sed -n 's/.*"flow": "\([0-9]*\)".*/\1/p')
          d1=$(printf '%s' "$line" | sed -n 's/.*"d1": "\([0-9]*\)".*/\1/p')
          d2=$(printf '%s' "$line" | sed -n 's/.*"d2": "\([0-9]*\)".*/\1/p')
          d3=$(printf '%s' "$line" | sed -n 's/.*"d3": "\([0-9]*\)".*/\1/p')
          d4=$(printf '%s' "$line" | sed -n 's/.*"d4": "\([0-9]*\)".*/\1/p')
          d6=$(printf '%s' "$line" | sed -n 's/.*"d6": "\([0-9]*\)".*/\1/p')
          ad=$(awk -F'\t' -v k="$i" '$1==k{print $2}' "$WORK/q6_ad.tsv"); ad=${ad:-NA}
          am=NA; ap=NA; pc=NA
          if [ "$ad" != "NA" ] && [ -n "$fl" ]; then
              case "$ad" in 1) am=$d1 ;; 2) am=$d2 ;; 3) am=$d3 ;; 4) am=$d4 ;; 6) am=$d6 ;; *) am="" ;; esac
              if [ -z "$am" ]; then
                  echo "Q6_FAIL	layer $i: anchor class '$ad' is not one of the atlas classes {1,2,3,4,6}"; am=NA; fails=1
              else
                  ap=$(ratio9 "$am" "$N_TOTAL")
                  le=0
                  for m in "$d1" "$d2" "$d3" "$d4" "$d6"; do
                      [ "$(echo "$m <= $am" | bc)" = 1 ] && le=$(echo "$le + $m" | bc)
                  done
                  pc=$(ratio9 "$le" "$N_TOTAL")
              fi
          fi
          printf '%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$i" "$fl" "$d1" "$d2" "$d3" "$d4" "$d6" "$ad" "$am" "$ap" "$pc"
          i=$((i+1))
      done < <(grep '"marginal_quotient"' "$ATLAS")
      exit $fails
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
      done < <(grep -o '"marginal_raw": {[^}]*}' "$ATLAS") > "$WORK/v1_rows.tsv"
      cat "$WORK/v1_rows.tsv"
      # 🔴 F-5 D11 (2026-09-08): an atlas with every marginal_raw block stripped produced a header-only
      # table and PASSED (mutant E4). The table is now checked against the atlas it came from: one raw
      # block per layer row (every layer row carries marginal_quotient; the count must equal N_PAIRS),
      # and each layer's raw marginal must sum to N exactly -- in bc, the masses are 192-bit at full-31.
      # Success output is unchanged; only a failure prints.
      fails=0
      nblk=$(grep -c '"marginal_raw"' "$ATLAS"); nlay=$(grep -c '"marginal_quotient"' "$ATLAS")
      [ "$nblk" -gt 0 ] && [ "$nblk" -eq "$nlay" ] && [ "$nlay" -eq "$N_PAIRS" ] \
        || { echo "V1_FAIL	marginal_raw blocks=$nblk layer rows=$nlay N_PAIRS=$N_PAIRS -- every layer must carry a raw marginal"; fails=1; }
      k=0
      while [ "$k" -lt "$nblk" ]; do
          s=$(awk -F'\t' -v k="$k" '$1==k {printf "%s+", $3} END{print "0"}' "$WORK/v1_rows.tsv" | BC_LINE_LENGTH=0 bc)
          [ "$s" = "$N_TOTAL" ] || { echo "V1_FAIL	layer k=$k raw marginal sums to $s, not N=$N_TOTAL"; fails=1; }
          k=$((k+1))
      done
      exit $fails
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/v1_field.tsv"
    row_end TR12_V1_TSV $rc

    row_begin c_v2
    (
      echo "# V2 mass river — REDUCED FORM (§3.1): split by distance class of the k-th transition,"
      echo "# which is the spec's own parenthetical alternative. branch_atlas[] carries per-branch"
      echo "# TOTALS only, so a per-layer-per-branch split is NOT available from this schema."
      echo -e "k\td1\td2\td3\td4\td6"
      # 🔴 F-5 ROUND 4 B2 (2026-09-11). This row had NO assertion of any kind. An atlas with every
      # `by_class` object stripped drives the loop zero times, prints a header-only table, and exits
      # 0 -- and an atlas with ONE CELL DELETED prints a short row and exits 0. Both measured by the
      # reviewer. This is round 1's D11 class, which was fixed for `c_v1` next door (:2260) and never
      # swept to its siblings -- fix the class, not the instance. Checked against the atlas the table
      # came from, in bc, because the masses are 192-bit at full-31. Success output is UNCHANGED;
      # only a failure prints, so no golden moves.
      i=0
      while read -r line; do
          printf '%d\t%s\t%s\t%s\t%s\t%s\n' "$i" \
            "$(printf '%s' "$line" | sed -n 's/.*"d1": "\([0-9]*\)".*/\1/p')" \
            "$(printf '%s' "$line" | sed -n 's/.*"d2": "\([0-9]*\)".*/\1/p')" \
            "$(printf '%s' "$line" | sed -n 's/.*"d3": "\([0-9]*\)".*/\1/p')" \
            "$(printf '%s' "$line" | sed -n 's/.*"d4": "\([0-9]*\)".*/\1/p')" \
            "$(printf '%s' "$line" | sed -n 's/.*"d6": "\([0-9]*\)".*/\1/p')"
          i=$((i+1))
      done < <(grep -o '"by_class": {[^}]*}' "$ATLAS") | tee "$WORK/v2_rows.tsv"
      fails=0
      nbc=$(grep -c '"by_class"' "$ATLAS"); nlay=$(grep -c '"marginal_quotient"' "$ATLAS")
      nrow=$(grep -c . "$WORK/v2_rows.tsv")
      [ "$nbc" -gt 0 ] && [ "$nbc" -eq "$nlay" ] && [ "$nlay" -eq "$N_PAIRS" ] && [ "$nrow" -eq "$N_PAIRS" ] \
        || { echo "V2_FAIL	by_class blocks=$nbc layer rows=$nlay emitted rows=$nrow N_PAIRS=$N_PAIRS -- every layer must carry a class split and emit one row"; fails=1; }
      # MEASURED on the n=9 atlas before this was written, not assumed: at every layer the five class
      # masses sum to N_total exactly (and the layer flow equals N_total). A deleted or altered cell
      # breaks this sum; a whole-row permutation does NOT, and that limit is stated in QUERY_INVENTORY.
      while IFS=$'\t' read -r k a b c d e; do
          [ -n "$k" ] || continue
          for v in "$a" "$b" "$c" "$d" "$e"; do
              case "$v" in ''|*[!0-9]*) echo "V2_FAIL	layer k=$k has a non-numeric or missing class mass"; fails=1 ;; esac
          done
          s=$(printf '%s+%s+%s+%s+%s\n' "${a:-0}" "${b:-0}" "${c:-0}" "${d:-0}" "${e:-0}" | BC_LINE_LENGTH=0 bc)
          [ "$s" = "$N_TOTAL" ] || { echo "V2_FAIL	layer k=$k class masses sum to $s, not N=$N_TOTAL"; fails=1; }
      done < "$WORK/v2_rows.tsv"
      exit $fails
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
              p=$(ratio9 "$m" "$fl")
              printf '%d\t%s\t%s\t%s\n' "$i" "$c" "$m" "$p"
          done
          i=$((i+1))
      done < <(grep '"marginal_quotient"' "$ATLAS") | tee "$WORK/v5_rows.tsv"
      # 🔴 F-5 ROUND 4 B2 (2026-09-11), the sibling of the c_v2 fix above and the same D11 class.
      # This row also had no assertion: a stripped atlas printed a header and exited 0.
      fails=0
      nrow=$(grep -c . "$WORK/v5_rows.tsv")
      [ "$nrow" -eq $((5 * N_PAIRS)) ] \
        || { echo "V5_FAIL	emitted $nrow rows, expected 5 x N_PAIRS = $((5 * N_PAIRS))"; fails=1; }
      # CROSS-INSTRUMENT: V5's mass column is the same quantity V2 prints, reached by a different
      # extraction (per-class sed inside a flow loop vs one by_class object). They must agree cell
      # for cell. Two readers of one field disagreeing is the defect; agreeing is the check.
      if [ -s "$WORK/v2_rows.tsv" ]; then
          awk -F'\t' 'NR==FNR{n=split("d1 d2 d3 d4 d6",C," ");for(j=1;j<=n;j++)m[$1"\t"C[j]]=$(j+1);next}
                       {key=$1"\t"$2; if(!(key in m)){printf "V5_FAIL\t(k=%s,%s) has no V2 counterpart\n",$1,$2;bad=1}
                        else if(m[key]!=$3){printf "V5_FAIL\t(k=%s,%s) mass %s != V2 mass %s\n",$1,$2,$3,m[key];bad=1}}
                       END{exit bad?1:0}' "$WORK/v2_rows.tsv" "$WORK/v5_rows.tsv" || fails=1
      else
          echo "V5_FAIL	V2's row file is absent or empty -- the cross-check could not run, which is not agreement"; fails=1
      fi
      exit $fails
    ) >>"$RAW" 2>&1; rc=$?
    cp "$RAW" "$ARTDIR/v5_grammar.tsv"
    row_end TR12_V5_TSV $rc
fi

# ---- the rows that remain genuinely blocked -----------------------------------------------------
row_skip c_xa_cd  TR12_XA_CD  "SKIP:xa-throughput-anchors" "needs the R-1 orbit-engine throughput anchors (36.14x work factor, 19.8x wall at 1T, nodes/sec hedged x2) — they are campaign measurements, not atlas fields, so the EXHAUSTIBLE/INFEASIBLE verdict cannot be derived from atlas.json alone"
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

agg TR12_Q7 TR12_Q7_KW TR12_Q7_HIST TR12_Q7_WITNESSES TR12_Q7_RANKS   # D5-04: the witness leg is a NAMED skip; the parent never reads PASS without it
agg TR12_Q8 TR12_Q8_SUPER TR12_Q8_C15 TR12_Q8_MEMBER TR12_Q8_CHI2 TR12_Q8_MIDN13 TR12_Q8_SUBSET   # D5-02: CHI2 is the GALLERY statistic; MIDN13 is the engine self-test; SUBSET (F-5 D9) labels the C15 file and derives the real subset
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
  printf 'TR12_REPRO_MINTED=%d\n' "${#MINTED[@]}"
  [ "${#MINTED[@]}" -gt 0 ] && printf 'TR12_REPRO_MINTED_ROWS=%s\n' "${MINTED[*]}"
  printf 'TR12_C3_FILTER_DEGENERATE=%s\n' "$DEGEN"
} >> "$VERD"
if [ "${#MINTED[@]}" -gt 0 ]; then
    say ""
    say "MINTED — ${#MINTED[@]} row(s) had NO expected block and were WRITTEN, not diffed: ${MINTED[*]}"
    say "         Their PASS attests exit status and in-row gates only. Review them before they are committed."
fi

# §0.3: the aggregate is emitted only if every non-SKIP token in scope is PASS.
AGG_OK=1
for t in "${TOKORDER[@]}"; do
    case "${TOKSTATE[$t]}" in FAIL*) AGG_OK=0 ;; esac
done
if [ "$NFAIL" -eq 0 ] && [ "$AGG_OK" -eq 1 ]; then
    # The program-level token is emitted only when Group C actually ran (SCAN_OK=1: this battery
    # scanned, or validated a supplied atlas). A --no-scan run is a PASSING BATTERY of the rows it
    # ran (TR12_REPRO=PASS) and must not read as a passing PROGRAM -- added 2026-09-08 (F-5 D1),
    # when the production driver started running this file pre-scan with --no-scan.
    if [ "$N_PAIRS" -ge 31 ]; then AGGKEY=QUERY_PROGRAM; else AGGKEY=QUERY_DRYRUN; fi
    if [ "$SCAN_OK" -eq 1 ]; then printf '%s=PASS\n' "$AGGKEY" >> "$VERD"
    else                          printf '%s=SKIP:no-atlas\n' "$AGGKEY" >> "$VERD"; fi
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
