#!/usr/bin/env bash
# reproduce_digests_gate.sh — Q-727. The small-rung f-ladder digests that
# documentation/REPRODUCE.md publishes must still be what the page's OWN commands produce.
#
# WHY. REPRODUCE.md publishes five `*.bin` directory digests (n = 9, 13, 16, 18, 19) and tells a
# stranger that matching them shows their build wrote byte-identical layer files. Those digests
# were measured by hand, twice (2026-08-25, re-measured 2026-09-24), and nothing public ever
# re-derived them. A solve.c change that moved a layer byte, or a page edit that broke the recipe,
# would leave the page promising a match that no reader could get, and every instrument green.
# The recipe also has a known trap, failure mode 3 on the page: `sha256sum` writes each file's path
# into its output, so a recipe that hashes from OUTSIDE the directory (`find out13 …`) gives a
# different digest for identical bytes. A gate that ran its own curated copy of the recipe could
# not see the page's copy rot into that form.
#
# SO THIS GATE CURATES NOTHING. Every command it runs is EXTRACTED from the page:
#   * the build line (the `gcc …` line of "The short version" block, which must equal the
#     "build line" row of the environment table: two different build lines on one page FAIL),
#   * the ledger's "Command for every row" template and "The digest is" recipe, instantiated at
#     each row's n (the short-version block must equal both at n = 13, or the page contradicts
#     itself and the gate FAILs),
#   * every ledger row: n, `*.bin` bytes, `*.bin` files, printed total and digest.
# It builds solve.c with that build line in a scratch directory, runs each row's command there,
# runs the page's digest recipe, and compares the digest, the byte count, the file count and the
# printed `orbit-quotient C5-DP total` with the row. Wall time and peak RSS are machine-dependent
# and are NOT compared (the page says so too).
#
# THE THREE PROPERTIES THE PAGE CLAIMS ARE RE-DERIVED, not quoted. REPRODUCE.md says the recipe
# was shown deterministic, tamper-evident and sensitive to the settings. Each is a leg here:
#   P1 path independence: n = 13 run into a DIFFERENTLY NAMED directory gives the same digest
#      (this is what failure mode 3 breaks, so a recipe that hashes paths fails P1 as well as the
#      rows);
#   P2 tamper evidence: one flipped byte in one n = 13 layer file changes the digest;
#   P3 settings sensitivity: the n = 13 command with `SOLVE_F1_KEEP_LAYERS=1` removed gives a
#      different digest and fewer `*.bin` files (failure mode 1).
#
# 🔴 IT IS NOT SATISFIED BY ITS OWN EMPTINESS. A page with no ledger rows, no command template or
# no build line is an ERROR, never a pass; so is a page that cannot be read or a build that fails.
# The rung population is pinned (EXPECT_RUNGS): a row that disappears from the page is a FAIL, so
# the gate cannot quietly shrink to the rows that still happen to match.
#
# COST, measured 2026-09-25 on the D16 worker: build ~12 s; all five rows together ~5 s;
# P1-P3 ~2 s. n = 18 and n = 19 are ~1-1.5 s each, so no rung is gated behind a flag.
# --selftest builds once and grades nine pages (~55 s): the real page, the real page with a
# hashing command that exits nonzero, the real page with two wrapped binaries (Q-983), and five planted pages. Needs gcc, zlib, python3, ~200 MB
# of scratch under ${TMPDIR:-/tmp}; no network, no ladder data.
#
# Usage:
#   scripts/reproduce_digests_gate.sh                 # the real page, documentation/REPRODUCE.md
#   scripts/reproduce_digests_gate.sh --page FILE     # grade another copy of the page
#   scripts/reproduce_digests_gate.sh --selftest      # prove the gate discriminates (see below)
#
# Verdict tokens (grep -qx), each a WHOLE line with nothing after the value:
#   REPRODUCE_DIGESTS=PASS|FAIL|ERROR          exit 0 | 1 | 2
#   REPRODUCE_DIGESTS_ERROR=<cause>            ERROR only: page-unreadable | extractor-failed |
#                                              page-unparsed | unsafe-command | build-failed |
#                                              no-scratch | bad-args
#   REPRODUCE_DIGESTS_RUNGS=<n>                rows whose digest was compared (printed before the
#                                              verdict whenever the rows ran)
#   REPRODUCE_DIGESTS_SELFTEST=PASS|FAIL       --selftest only: every planted page got its
#                                              expected verdict (exit 0 | 1)
#
# Developed with AI assistance (Claude, Anthropic).
set -uo pipefail
ORIG_PWD=$PWD
cd "$(dirname "$0")/.." || { echo "REPRODUCE_DIGESTS_ERROR=page-unreadable"; echo "REPRODUCE_DIGESTS=ERROR"; exit 2; }

# The rows REPRODUCE.md publishes. Changing this set is a deliberate edit, made together with the
# page; a row that vanishes from the page without it is a FAIL.
EXPECT_RUNGS="9 13 16 18 19"
PAGE=documentation/REPRODUCE.md
MODE=run
while [ $# -gt 0 ]; do
  case "$1" in
    --page) PAGE=${2:-}; shift 2 || shift
            case "$PAGE" in /*|'') ;; *) PAGE="$ORIG_PWD/$PAGE" ;; esac ;;
    --selftest) MODE=selftest; shift ;;
    *) echo "usage: $0 [--page FILE] [--selftest]"
       echo "REPRODUCE_DIGESTS_ERROR=bad-args"; echo "REPRODUCE_DIGESTS=ERROR"; exit 2 ;;
  esac
done

err(){ echo "REPRODUCE_DIGESTS_ERROR=$1"; echo "REPRODUCE_DIGESTS=ERROR"; exit 2; }

# ---- the extractor ---------------------------------------------------------------------------
# Prints TSV records: BUILD<TAB>line, CMD<TAB>template, DIG<TAB>template,
# ROW<TAB>n<TAB>bytes<TAB>files<TAB>total<TAB>digest, and FAIL<TAB>msg / ERROR<TAB>msg.
extract(){
  python3 - "$1" "$EXPECT_RUNGS" <<'PY'
import re, sys
page, expect = sys.argv[1], sorted(int(x) for x in sys.argv[2].split())
def out(*a): print("\t".join(str(x) for x in a))
try:
    body = open(page, encoding="utf-8").read()
except (OSError, UnicodeDecodeError) as e:
    out("ERROR", "page-unreadable", "cannot read %s: %s" % (page, e)); sys.exit(0)
lines = body.split("\n")

def section(title_re):
    start = None
    for i, l in enumerate(lines):
        if start is None and re.match(r"^## " + title_re, l):
            start = i + 1
        elif start is not None and l.startswith("## "):
            return lines[start:i]
    return lines[start:] if start is not None else None

# (1) the build line, published twice, which must agree
short = section(r"The short version")
envt = section(r"Environment these figures came from")
if short is None or envt is None:
    out("ERROR", "page-unparsed", "missing section: %s" % ("'The short version'" if short is None
        else "'Environment these figures came from'")); sys.exit(0)
fence = []
inf = False
for l in short:
    if l.startswith("```"):
        if inf: break
        inf = True; continue
    if inf and l.strip():
        fence.append(l.strip())
if len(fence) != 3:
    out("ERROR", "page-unparsed", "'The short version' block has %d command lines, expected 3 (build, run, digest)" % len(fence)); sys.exit(0)
b_short = fence[0]
m = [re.match(r"^\|\s*build line\s*\|\s*`([^`]+)`", l) for l in envt]
m = [x for x in m if x]
if len(m) != 1:
    out("ERROR", "page-unparsed", "environment table has %d 'build line' rows, expected 1" % len(m)); sys.exit(0)
b_env = m[0].group(1).strip()
if b_short != b_env:
    out("FAIL", "the page publishes two build lines: short version '%s' vs environment table '%s'" % (b_short, b_env))
out("BUILD", b_short)

# (2) the ledger's command template and digest recipe
ledger = section(r"The ledger")
if ledger is None:
    out("ERROR", "page-unparsed", "no '## The ledger' section"); sys.exit(0)
ct = [re.match(r"^Command for every row:\s*`([^`]+)`", l) for l in ledger]
ct = [x.group(1).strip() for x in ct if x]
dt = [re.match(r"^The digest is\s*`([^`]+)`", l) for l in ledger]
dt = [x.group(1).strip() for x in dt if x]
if len(ct) != 1 or len(dt) != 1:
    out("ERROR", "page-unparsed", "ledger has %d 'Command for every row' and %d 'The digest is' lines, expected 1 each" % (len(ct), len(dt))); sys.exit(0)
cmd_t, dig_t = ct[0], dt[0]
PH = re.compile(r"(?<=[a-z])N\b|\bN\b")          # `--f1-pairs N`, `outN`
def inst(t, n): return PH.sub(str(n), t)
if not PH.search(cmd_t):
    out("ERROR", "page-unparsed", "the ledger command has no N placeholder: '%s'" % cmd_t); sys.exit(0)
out("CMD", cmd_t); out("DIG", dig_t)
if fence[1] != inst(cmd_t, 13):
    out("FAIL", "the short version's run line '%s' is not the ledger command at n=13 '%s'" % (fence[1], inst(cmd_t, 13)))
if fence[2] != inst(dig_t, 13):
    out("FAIL", "the short version's digest line '%s' is not the ledger recipe at n=13 '%s'" % (fence[2], inst(dig_t, 13)))

# (3) the rows
rows = []
for l in ledger:
    if not re.match(r"^\|\s*\d+\s*\|", l):
        continue
    c = [x.strip() for x in l.strip().strip("|").split("|")]
    if len(c) != 7:
        out("FAIL", "ledger row has %d cells, expected 7: %s" % (len(c), l)); continue
    n, _wall, _rss, byts, files, total, dg = c
    dg = dg.strip("`")
    num = lambda s: s.replace(",", "")
    if not (num(byts).isdigit() and files.isdigit() and num(total).isdigit()):
        out("FAIL", "n=%s: a count cell is not an integer: %s" % (n, l)); continue
    if not re.fullmatch(r"[0-9a-f]{64}", dg):
        out("FAIL", "n=%s: the digest cell is not a 64-hex sha256: '%s'" % (n, dg)); continue
    rows.append((int(n), num(byts), files, num(total), dg))
if not rows:
    out("ERROR", "page-unparsed", "the ledger has no rows: nothing would be compared"); sys.exit(0)
got = sorted(r[0] for r in rows)
if got != expect:
    out("FAIL", "the ledger publishes rungs %s; this gate pins %s. A row that vanished (or appeared) must be a deliberate edit to EXPECT_RUNGS in the gate, made with the page" % (got, expect))
for r in rows:
    out("ROW", *r)
PY
}

# ---- the checker: grade one page against one binary -------------------------------------------
# check_page PAGE BIN — prints its legs; sets RES to PASS|FAIL|ERROR and CAUSE on ERROR.
RES=""; CAUSE=""; NRUNG=0
check_page(){
  local page=$1 bin=$2 x fail=0 work
  RES=""; CAUSE=""; NRUNG=0
  [ -r "$page" ] || { RES=ERROR; CAUSE=page-unreadable; echo "  [ERROR] cannot read $page"; return; }
  if ! x=$(extract "$page"); then RES=ERROR; CAUSE=extractor-failed; echo "  [ERROR] the extractor did not run (python3 failed)"; return; fi
  if grep -q '^ERROR' <<<"$x"; then
    RES=ERROR; CAUSE=$(printf '%s\n' "$x" | awk -F'\t' '/^ERROR/{print $2; exit}')
    printf '%s\n' "$x" | awk -F'\t' '/^ERROR/{print "  [ERROR] " $3}'; return
  fi
  grep -q '^ROW' <<<"$x" || { RES=ERROR; CAUSE=extractor-failed; echo "  [ERROR] the extractor printed no rows and no error"; return; }
  if grep -q '^FAIL' <<<"$x"; then
    printf '%s\n' "$x" | awk -F'\t' '/^FAIL/{print "  [FAIL]  " $2}'; fail=1
  fi
  local cmd_t dig_t
  cmd_t=$(printf '%s\n' "$x" | awk -F'\t' '/^CMD/{print $2; exit}')
  dig_t=$(printf '%s\n' "$x" | awk -F'\t' '/^DIG/{print $2; exit}')
  # The page's text is executed. Refuse anything beyond an env-prefixed command, a subshell, &&
  # and pipes: no ; $ < > backtick or backslash.
  case "$cmd_t$dig_t" in *[\;\$\<\>\`\\]*)
    RES=ERROR; CAUSE=unsafe-command; echo "  [ERROR] the page's commands contain a shell metacharacter this gate will not execute"; return ;; esac
  work=$(mktemp -d "${TMPDIR:-/tmp}/reprodig_run.XXXXXX") || { RES=ERROR; CAUSE=no-scratch; return; }
  ln -s "$bin" "$work/solve"
  # Clear every inherited SOLVE_* so the only settings are the ones the page's command sets.
  local UNSET=() v
  for v in $(compgen -e | grep '^SOLVE_'); do UNSET+=(-u "$v"); done
  inst(){ printf '%s' "$1" | sed -E "s/([a-z])N\b/\1$2/g; s/\bN\b/$2/g"; }
  # digest_of RECIPE -> prints the digest, or nothing if the recipe failed. The recipe runs with
  # pipefail and its exit status is checked, and its whole output must be ONE line
  # "<64 hex>  -": a hashing command that prints the right digest and then exits nonzero, or
  # prints a second line, gives no digest at all (Codex PKG-V3 finding 6: before 2026-10-03 a
  # stand-in sha256sum that printed the real digest and exited 23 still passed).
  digest_of(){
    local out rc
    out=$(cd "$work" && bash -o pipefail -c "$1" 2>/dev/null); rc=$?
    [ "$rc" -eq 0 ] || { echo "  [note]  the digest recipe exited rc=$rc" >&2; return 0; }
    grep -qxE '[0-9a-f]{64}  -' <<<"$out" && [ "$(printf '%s\n' "$out" | wc -l)" -eq 1 ] \
      || { echo "  [note]  the digest recipe printed something other than one '<sha256>  -' line" >&2; return 0; }
    printf '%s' "${out%%  -}"
  }
  run_rung(){  # $1 command, $2 digest recipe -> sets R_RC R_OUT R_DIG R_DIR R_MS
    local t0 t1
    t0=$(date +%s%N)
    R_OUT=$(cd "$work" && env "${UNSET[@]}" timeout 300 bash -o pipefail -c "$1" 2>&1); R_RC=$?
    t1=$(date +%s%N); R_MS=$(( (t1 - t0) / 1000000 ))
    R_DIG=$(digest_of "$2")
    R_DIR=$(printf '%s\n' "$1" | sed -nE 's/.*--layers-dir +([^ ]+).*/\1/p')
  }
  local n byts files total dg c d nb nf tot
  while IFS=$'\t' read -r _ n byts files total dg; do
    c=$(inst "$cmd_t" "$n"); d=$(inst "$dig_t" "$n")
    run_rung "$c" "$d"
    NRUNG=$((NRUNG+1))
    if [ "$R_RC" -ne 0 ]; then
      echo "  [FAIL]  n=$n: the page's command exited rc=$R_RC; a digest from a failed run certifies nothing"
      printf '%s\n' "$R_OUT" | tail -3 | sed 's/^/          | /'; fail=1; continue
    fi
    nb=""; nf=""
    if [ -n "$R_DIR" ] && [ -d "$work/$R_DIR" ]; then
      nf=$(find "$work/$R_DIR" -name '*.bin' | wc -l)
      nb=$(find "$work/$R_DIR" -name '*.bin' -printf '%s\n' | awk '{s+=$1} END{printf "%d", s}')
    fi
    # Exactly one printed total (the Q-952 class, batch 39): before, `| tail -1` kept the last of
    # several, so a wrong total followed by the right one passed.
    # Q-983 (batch 42; Codex gpt-6-astra, Q964-D09#5): "exactly one" counts every LINE carrying the
    # label, whatever follows it, and the value must be a bare integer token. The extraction kept only
    # `= [0-9]+`, so a `total = -1` line was not counted and `26112.5` was read as 26112.
    local ntot
    ntot=$(grep -c 'orbit-quotient C5-DP total =' <<<"$R_OUT" || true)
    tot=$(printf '%s\n' "$R_OUT" | sed -nE 's/.*orbit-quotient C5-DP total = *([^[:space:]]*).*/\1/p')
    local bad=""
    if [ "${ntot:-0}" -gt 1 ]; then bad="$bad totals=${ntot}-lines(page 1)"; tot=""
    elif [ -n "$tot" ] && ! [[ "$tot" =~ ^[0-9]+$ ]]; then bad="$bad total=$tot-not-an-integer(page $total)"; tot=""; fi
    [ "$R_DIG" = "$dg" ] || bad="$bad digest=${R_DIG:-<none>}(page $dg)"
    [ "$nb" = "$byts" ]  || bad="$bad bytes=${nb:-<none>}(page $byts)"
    [ "$nf" = "$files" ] || bad="$bad files=${nf:-<none>}(page $files)"
    [ "$tot" = "$total" ] || bad="$bad total=${tot:-<none>}(page $total)"
    if [ -n "$bad" ]; then
      echo "  [FAIL]  n=$n ($R_MS ms):$bad"; fail=1
    else
      echo "  [ok]    n=$n  digest ${dg:0:16}…  $nf files  $nb bytes  total $tot  ($R_MS ms)"
    fi
  done < <(printf '%s\n' "$x" | grep '^ROW')

  # P1-P3 at n = 13, from the page's own template.
  local c13 d13 base13 dir13
  c13=$(inst "$cmd_t" 13); d13=$(inst "$dig_t" 13)
  run_rung "$c13" "$d13"; base13=$R_DIG; dir13=$R_DIR
  if [ "$R_RC" -ne 0 ] || [ -z "$base13" ] || [ -z "$dir13" ]; then
    echo "  [FAIL]  P1-P3: the n=13 command did not run cleanly (rc=$R_RC, dir '${dir13}')"; fail=1
  else
    # P1: the same bytes in a differently named directory must give the same digest.
    local alt="rep_$dir13"
    run_rung "$(printf '%s' "$c13" | sed "s#\b$dir13\b#$alt#g")" "$(printf '%s' "$d13" | sed "s#\b$dir13\b#$alt#g")"
    if [ "$R_RC" -eq 0 ] && [ "$R_DIG" = "$base13" ]; then
      echo "  [ok]    P1 path independence: $dir13/ and $alt/ give the same digest"
    else
      echo "  [FAIL]  P1 path independence: $dir13/ gave ${base13:0:16}…, $alt/ gave ${R_DIG:-<none>} — the recipe hashes the path (failure mode 3)"; fail=1
    fi
    # P2: flip one byte of one layer file (in the P1 copy); the digest must move.
    local f; f=$(find "$work/$alt" -name '*.bin' | sort | head -1)
    if [ -n "$f" ]; then
      printf '\xff' | dd of="$f" bs=1 seek=64 conv=notrunc status=none
      local t; t=$(digest_of "$(printf '%s' "$d13" | sed "s#\b$dir13\b#$alt#g")" 2>/dev/null)
      if [ -n "$t" ] && [ "$t" != "$base13" ]; then echo "  [ok]    P2 tamper evidence: one flipped byte changes the digest"
      else echo "  [FAIL]  P2 tamper evidence: the digest did not move when a layer byte changed"; fail=1; fi
    else
      echo "  [FAIL]  P2 tamper evidence: no *.bin file to corrupt"; fail=1
    fi
    # P3: without SOLVE_F1_KEEP_LAYERS=1 the digest must differ and fewer files must remain.
    local nk="no_keep_$dir13" ckeep kn nn
    ckeep=$(printf '%s' "$c13" | sed -E 's/(^| )SOLVE_F1_KEEP_LAYERS=[^ ]+ / /; s/^ //' | sed "s#\b$dir13\b#$nk#g")
    if [ "$ckeep" = "$(printf '%s' "$c13" | sed "s#\b$dir13\b#$nk#g")" ]; then
      echo "  [FAIL]  P3 settings sensitivity: the page's command does not set SOLVE_F1_KEEP_LAYERS=1 (failure mode 1)"; fail=1
    else
      run_rung "$ckeep" "$(printf '%s' "$d13" | sed "s#\b$dir13\b#$nk#g")"
      kn=$(find "$work/$dir13" -name '*.bin' | wc -l); nn=$(find "$work/$nk" -name '*.bin' 2>/dev/null | wc -l)
      if [ "$R_RC" -eq 0 ] && [ "$R_DIG" != "$base13" ] && [ "$nn" -lt "$kn" ]; then
        echo "  [ok]    P3 settings sensitivity: without SOLVE_F1_KEEP_LAYERS=1, $nn *.bin files (not $kn) and a different digest"
      else
        echo "  [FAIL]  P3 settings sensitivity: omitting SOLVE_F1_KEEP_LAYERS=1 is invisible (rc=$R_RC, $nn vs $kn files)"; fail=1
      fi
    fi
  fi
  rm -rf "$work"
  if [ "$fail" -eq 0 ]; then RES=PASS; else RES=FAIL; fi
}

# ---- build with the page's build line ------------------------------------------------------------
BDIR=""
cleanup(){ [ -n "$BDIR" ] && rm -rf "$BDIR"; }
trap cleanup EXIT
build_from(){  # $1 page -> sets BIN, or exits ERROR
  local x b
  [ -r "$1" ] || { echo "  [ERROR] cannot read $1"; err page-unreadable; }
  x=$(extract "$1") || { echo "  [ERROR] the extractor did not run (python3 failed)"; err extractor-failed; }
  b=$(printf '%s\n' "$x" | awk -F'\t' '/^BUILD/{print $2; exit}')
  if [ -z "$b" ]; then
    printf '%s\n' "$x" | awk -F'\t' '/^ERROR/{print "  [ERROR] " $3}'
    err "$(printf '%s\n' "$x" | awk -F'\t' '/^ERROR/ && !n++{print $2}' | grep . || echo page-unparsed)"
  fi
  case "$b" in *[\;\$\<\>\`\\\|\&]*) echo "  [ERROR] the build line contains a shell metacharacter: $b"; err unsafe-command ;; esac
  case "$b" in "gcc "*|"cc "*) ;; *) echo "  [ERROR] the build line does not invoke gcc/cc: $b"; err unsafe-command ;; esac
  [ -r solve.c ] || { echo "  [ERROR] no solve.c at the repo root"; err build-failed; }
  BDIR=$(mktemp -d "${TMPDIR:-/tmp}/reprodig_build.XXXXXX") || err no-scratch
  cp solve.c "$BDIR/solve.c" || err no-scratch
  echo "  build (the page's line): $b"
  local t0 t1; t0=$(date +%s)
  if ! (cd "$BDIR" && bash -c "$b") >"$BDIR/build.log" 2>&1 || [ ! -x "$BDIR/solve" ]; then
    echo "  [ERROR] the page's build line did not produce ./solve:"; tail -5 "$BDIR/build.log" | sed 's/^/          | /'
    err build-failed
  fi
  t1=$(date +%s); echo "  built in $((t1 - t0)) s"
  BIN="$BDIR/solve"
}

if [ "$MODE" = run ]; then
  echo "== REPRODUCE.md digests: $PAGE =="
  build_from "$PAGE"
  check_page "$PAGE" "$BIN"
  [ "$NRUNG" -gt 0 ] && echo "REPRODUCE_DIGESTS_RUNGS=$NRUNG"
  case "$RES" in
    PASS) echo "REPRODUCE_DIGESTS=PASS"; exit 0 ;;
    FAIL) echo "REPRODUCE_DIGESTS=FAIL"; exit 1 ;;
    *)    err "${CAUSE:-page-unparsed}" ;;
  esac
fi

# ---- --selftest: the gate must discriminate ------------------------------------------------------
# One build from the real page, then nine gradings against it: the real page, the real page with
# a failing hashing command, and five planted pages. Each planted page differs from
# the real one in ONE place, and each mutation must actually land (asserted, so a page reworded
# under this selftest cannot turn a red leg into a no-op that "passes" by grading the real page).
echo "== REPRODUCE.md digests: --selftest =="
[ -r "$PAGE" ] || { echo "  [ERROR] cannot read $PAGE"; echo "REPRODUCE_DIGESTS_SELFTEST=FAIL"; exit 1; }
build_from "$PAGE"
SD=$(mktemp -d "${TMPDIR:-/tmp}/reprodig_self.XXXXXX") || { echo "REPRODUCE_DIGESTS_SELFTEST=FAIL"; exit 1; }
trap 'cleanup; rm -rf "$SD"' EXIT
sfail=0
plant(){  # $1 name, $2 sed expression -> writes $SD/$1.md; fails the selftest if nothing changed
  sed -E "$2" "$PAGE" > "$SD/$1.md"
  if cmp -s "$PAGE" "$SD/$1.md"; then echo "  [FAIL]  fixture $1: the mutation did not land on the page"; sfail=1; return 1; fi
}
expect(){  # $1 name, $2 expected verdict, $3 page
  check_page "$3" "$BIN" >"$SD/$1.log" 2>&1
  if [ "$RES" = "$2" ]; then
    echo "  [ok]    $1 -> $RES (expected $2)"
    grep -E '^\s*\[(FAIL|ERROR)' "$SD/$1.log" | head -2 | sed 's/^ */          /'
  else
    echo "  [FAIL]  $1 -> ${RES:-<none>}, expected $2"; sed 's/^/          | /' "$SD/$1.log" | tail -12; sfail=1
  fi
}
expect real-page PASS "$PAGE"
# the real page, with a hashing command that prints the true digest and then exits nonzero
# (Codex PKG-V3 finding 6): the recipe's exit status must count, not only its text
SHAREAL=$(command -v sha256sum); mkdir -p "$SD/stubbin"
printf '#!/usr/bin/env bash\n"%s" "$@"\nexit 23\n' "$SHAREAL" > "$SD/stubbin/sha256sum"; chmod +x "$SD/stubbin/sha256sum"
SAVED_PATH=$PATH; PATH="$SD/stubbin:$PATH"; expect hash-tool-fails FAIL "$PAGE"; PATH=$SAVED_PATH
# a planted wrong digest: the last hex digit of the n=16 row
plant wrong-digest 's/(fa2ae688058e5e6ef923f9eae93cbbfddde413ba05859460375069aaab3b471)3/\14/' && expect wrong-digest FAIL "$SD/wrong-digest.md"
# the ledger command with SOLVE_F1_KEEP_LAYERS=1 removed (failure mode 1)
# (in BOTH places the page prints it, so the page stays self-consistent and the red comes from
# executing the command, not from the text comparison)
plant cmd-no-keep 's/^(Command for every row: `)SOLVE_F1_KEEP_LAYERS=1 /\1/; s/^SOLVE_F1_KEEP_LAYERS=1 (\.\/solve --f1-exact-c1c2c4c5 --f1-pairs 13 )/\1/' && expect cmd-no-keep FAIL "$SD/cmd-no-keep.md"
# the digest recipe hashing from outside the directory (failure mode 3)
# (again in both places)
plant recipe-path 's/^(The digest is `)\(cd outN \&\& find \. /\1(find outN /; s/^\(cd out13 \&\& find \. /(find out13 /' && expect recipe-path FAIL "$SD/recipe-path.md"
# Q-983 (Codex Q964-D09#5): the real page and the real binary, with a wrapper that adds a second
# `total = -1` line, and one that prints the total as a decimal; each must FAIL ("exactly one
# total" counts every total line, and a total is an integer)
BINREAL=$BIN
printf '#!/usr/bin/env bash\n"%s" "$@"; rc=$?\necho "orbit-quotient C5-DP total = -1"\nexit $rc\n' "$BINREAL" > "$SD/solve_extra_total"
printf '#!/usr/bin/env bash\nset -o pipefail\n"%s" "$@" | sed -E "s/(orbit-quotient C5-DP total = [0-9]+)/\\1.5/"\n' "$BINREAL" > "$SD/solve_decimal_total"
chmod +x "$SD/solve_extra_total" "$SD/solve_decimal_total"
BIN="$SD/solve_extra_total";   expect total-extra-negative FAIL "$PAGE"
BIN="$SD/solve_decimal_total"; expect total-decimal FAIL "$PAGE"
BIN=$BINREAL
# one ledger row deleted: the population must not shrink quietly
plant row-deleted '/^\| 18 \|/d' && expect row-deleted FAIL "$SD/row-deleted.md"
# every ledger row deleted: nothing to compare is an ERROR, never a PASS
plant rows-gone '/^\| (9|13|16|18|19) \|/d' && expect rows-gone ERROR "$SD/rows-gone.md"
if [ "$sfail" -eq 0 ]; then echo "REPRODUCE_DIGESTS_SELFTEST=PASS"; exit 0; fi
echo "REPRODUCE_DIGESTS_SELFTEST=FAIL"; exit 1
