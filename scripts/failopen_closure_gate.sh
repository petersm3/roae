#!/usr/bin/env bash
# failopen_closure_gate.sh — THE META-GATE for the fail-open class (2026-09-05 sweep).
#
# THE ONE-LINE RULE every gate must satisfy, stated so it can be checked mechanically:
#
#   Run with its target absent, a gate must neither print an OK-class token nor exit 0.
#
# "Target absent" is made concrete and uniform: the script is copied ALONE into an empty
# directory (only scripts/<name> exists — no repo, no documentation/, no solve.c, no ledgers, no
# artifacts) and executed from there with stdin closed and HOME pointed at the empty tree. Every
# relative input it reads is therefore missing. A gate that still says `KEY=OK|PASS|CLEAN`, or
# exits 0, has a PASS that is consistent with its target being absent — which is the class
# definition. This is the same test that found 5 of the 2026-09-05 sweep's hits in one pass.
#
# WHY A HARNESS AND NOT A CODE PATTERN. The 56 ledgered instances share no code shape — a
# `2>/dev/null` cat, a `while read < missing`, a `|| exit 0`, a grep on a moved anchor, a `.pyc`
# cache, an awk binary64. What they share is the OBSERVABLE: success reported from an empty
# world. So the check is on the observable, by execution, and a new gate is covered the moment
# it exists — no registration step to forget.
#
# WHAT IT CANNOT SEE, stated: (1) the anchor-moved case where the FILE exists but the PATTERN
# inside it is gone (that needs a per-gate mutant; require_tracked's history check covers the
# file-level half); (2) a subprocess dying MID-stream after producing partial output; (3) scripts
# it refuses to execute (UNRUN: anything whose non-comment lines touch az/ssh/azcopy/sudo/
# git commit|push/crontab/nohup/setsid, or ABSPATH: a hard-coded /home/*/github or /mnt path,
# which the skeleton cannot isolate — both are graded by reading, not here); (4) the
# skeleton is not a git repo, so a gate that ERRORs on "not in a git repo" is CLOSED here for
# that reason alone — a weaker warrant than a gate that survived a one-file corpus.
#
# ALLOWLIST (scripts/failopen_closure_allow.tsv, TAB-separated: name  class  reason). Classes:
#   self-contained  the OK token is a computed result with no tree input (a Monte-Carlo null,
#                   a fixture-only red-test) — PASS legitimately does not depend on the tree
#   timeout         the script cannot finish inside --timeout in an empty tree (say why)
#   rc0-by-design   exits 0 with an explicit non-OK token that a consumer must grep
# A row that names a script which is NOT open here exempts nothing and is a FAIL (stale
# exemptions rot — GATE 4b LEG 5's rule). A row naming a nonexistent script is an ERROR.
#
# Verdict tokens (grep -qx): FAILOPEN_CLOSURE=OK|FAIL|ERROR, plus FAILOPEN_CLOSURE_POP=n
# (gate-shaped scripts found: any KEY=OK|PASS|CLEAN|FAIL|ERROR|SKIP|BLOCKED|REFUSED in source), _RUN=n, _OPEN=n, _RC0=n, _ALLOWED=n, _UNRUN=n, _TIMEOUT=n.
# Exit 0 OK / 1 FAIL / 2 ERROR. `--selftest` plants fixtures and proves every verdict class.
#
# usage: failopen_closure_gate.sh [--tree DIR] [--allow FILE] [--timeout SECS] [--selftest]
set -uo pipefail
TREE=""; ALLOW=""; TO=60; SELFTEST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --tree)    TREE=$2; shift 2 ;;
    --allow)   ALLOW=$2; shift 2 ;;
    --timeout) TO=$2; shift 2 ;;
    --selftest) SELFTEST=1; shift ;;
    *) echo "usage: $0 [--tree DIR] [--allow FILE] [--timeout SECS] [--selftest]"; echo "FAILOPEN_CLOSURE=ERROR bad-args"; exit 2 ;;
  esac
done
case "$TO" in ''|*[!0-9]*) echo "FAILOPEN_CLOSURE=ERROR --timeout must be an integer"; exit 2 ;; esac

TOKRE='^[A-Z][A-Z0-9_]{2,}=(OK|PASS|CLEAN)( |$)'                 # what "OK-class token" means
SRCTOK='[A-Z][A-Z0-9_]{2,}=(OK|PASS|CLEAN|FAIL|ERROR|SKIP|BLOCKED|REFUSED)\b'  # a verdict-shaped token in source = a gate
ABSRE='/home/[a-z]+/github/|/mnt/[a-z]'                            # a hard-coded absolute repo/mount path: the skeleton cannot isolate it
UNRUNRE='\baz +(vm|storage|disk|network|login|account|group|snapshot)\b|\bssh +[^ ]|\bazcopy\b|\bgit +(commit|push)\b|\bcrontab +-|\bnohup\b|\bsetsid\b|\bsudo\b|\bmkfs\b|\bshutdown\b|\breboot\b'

noncomment(){ grep -vE '^[[:space:]]*#' "$1" 2>/dev/null; }

# run_one <abs script> -> prints "CLASS<TAB>rc<TAB>token" where CLASS in OPEN|RC0|CLOSED|TIMEOUT|UNRUN
run_one(){
  local f=$1 name rc out tok skel interp
  name=$(basename "$f")
  # 🔴 NOT `noncomment | grep -q`: under `set -o pipefail`, grep -q exits at the first match, the
  # upstream grep takes SIGPIPE, the pipeline returns 141, and a `||`/`if` reads that as NO MATCH.
  # That is ledger instance 24, and the first cut of THIS gate reproduced it: the population came
  # back 9 instead of 25, and perf_bench.sh (ssh) slipped past this very filter and was executed.
  # `grep -c` reads to EOF and never SIGPIPEs its producer.
  if [ "$(noncomment "$f" | grep -cE "$UNRUNRE")" -gt 0 ]; then printf 'UNRUN\t-\t-\n'; return; fi
  if [ "$(noncomment "$f" | grep -cE "$ABSRE")" -gt 0 ]; then printf 'ABSPATH\t-\t-\n'; return; fi
  case "$name" in *.py) interp=python3 ;; *) interp=bash ;; esac
  skel=$(mktemp -d "${TMPDIR:-/tmp}/failopen_skel.XXXXXX") || { printf 'ERROR\t-\tmktemp\n'; return; }
  mkdir -p "$skel/scripts" && cp "$f" "$skel/scripts/$name"
  out=$(cd "$skel" && HOME=$skel TMPDIR=$skel nice -n 15 timeout -k 5 "$TO" "$interp" "scripts/$name" </dev/null 2>&1); rc=$?
  rm -rf "$skel"
  tok=$(printf '%s\n' "$out" | grep -E "$TOKRE" | head -1 | cut -c1-60)
  if [ -n "$tok" ]; then printf 'OPEN\t%s\t%s\n' "$rc" "$tok"
  elif [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then printf 'TIMEOUT\t%s\t-\n' "$rc"
  elif [ "$rc" -eq 0 ]; then printf 'RC0\t%s\t%s\n' "$rc" "$(printf '%s\n' "$out" | grep -E '^[A-Z][A-Z0-9_]{2,}=' | tail -1 | cut -c1-60)"
  else printf 'CLOSED\t%s\t-\n' "$rc"; fi
}

# gate <tree> <allowfile-or-empty> -> verdict lines + token; returns 0/1/2
gate(){
  local tree=$1 allow=$2 f name cls rc tok pop=0 run=0 open=0 rc0=0 allowed=0 unrun=0 tmo=0 fails=0 err=0
  declare -A ALLOWC ALLOWR SEEN
  [ -d "$tree/scripts" ] || { echo "  [ERROR] no scripts/ under $tree"; echo "FAILOPEN_CLOSURE=ERROR no-scripts-dir"; return 2; }
  if [ -n "$allow" ]; then
    [ -r "$allow" ] || { echo "  [ERROR] allowlist unreadable: $allow"; echo "FAILOPEN_CLOSURE=ERROR allowlist-unreadable"; return 2; }
    while IFS=$'\t' read -r aname aclass areason; do
      case "$aname" in ''|\#*) continue ;; esac
      case "$aclass" in self-contained|timeout|rc0-by-design) ;; *) echo "  [ERROR] allowlist row for $aname has unknown class '${aclass:-}'"; err=1; continue ;; esac
      [ "${#areason}" -ge 10 ] || { echo "  [ERROR] allowlist row for $aname carries no reason"; err=1; continue; }
      [ -f "$tree/scripts/$aname" ] || { echo "  [ERROR] allowlist names a script that does not exist: $aname"; err=1; continue; }
      ALLOWC[$aname]=$aclass; ALLOWR[$aname]=$areason
    done < "$allow"
    [ "$err" -eq 0 ] || { echo "FAILOPEN_CLOSURE=ERROR allowlist-malformed"; return 2; }
  fi
  for f in "$tree"/scripts/*.sh "$tree"/scripts/*.py; do
    [ -f "$f" ] || continue
    [ "$(noncomment "$f" | grep -cE "$SRCTOK")" -gt 0 ] || continue   # only gate-shaped scripts (a FAIL-only gate can still exit 0); grep -c, see run_one
    name=$(basename "$f")
    # Self-exclusion, stated: this file carries the UNRUN regex as a literal and would match it;
    # and a copy of this gate alone in a skeleton finds no scripts/ population and ERRORs, which
    # proves nothing about it. Its warrant is `--selftest`, which plants every verdict class.
    [ "$name" = "$(basename "$0")" ] && continue
    pop=$((pop+1))
    IFS=$'\t' read -r cls rc tok < <(run_one "$f")
    SEEN[$name]=$cls
    case "$cls" in
      UNRUN)   unrun=$((unrun+1)); printf '  [unrun ] %-44s not executed (touches az/ssh/sudo/git-commit/…); grade by reading\n' "$name" ;;
      ABSPATH) unrun=$((unrun+1)); printf '  [abspth] %-44s not executed: hard-codes an absolute repo/mount path, so a skeleton cannot isolate its inputs; grade by reading\n' "$name" ;;
      TIMEOUT) run=$((run+1)); tmo=$((tmo+1))
               if [ "${ALLOWC[$name]:-}" = timeout ]; then printf '  [allow ] %-44s timeout — %s\n' "$name" "${ALLOWR[$name]}"; allowed=$((allowed+1))
               else printf '  [ERROR ] %-44s did not finish in %ss with NO inputs — ungradable, and suspicious\n' "$name" "$TO"; err=1; fi ;;
      OPEN)    run=$((run+1))
               if [ "${ALLOWC[$name]:-}" = self-contained ]; then printf '  [allow ] %-44s %s (self-contained: %s)\n' "$name" "$tok" "${ALLOWR[$name]}"; allowed=$((allowed+1))
               else open=$((open+1)); printf '  [OPEN  ] %-44s printed %s with every input ABSENT (rc=%s)\n' "$name" "$tok" "$rc"; fails=1; fi ;;
      RC0)     run=$((run+1))
               if [ "${ALLOWC[$name]:-}" = rc0-by-design ]; then printf '  [allow ] %-44s exit 0 with token %s — %s\n' "$name" "${tok:-none}" "${ALLOWR[$name]}"; allowed=$((allowed+1))
               else rc0=$((rc0+1)); printf '  [RC0   ] %-44s exited 0 with every input ABSENT (last token: %s) — a `|| FAIL=1` consumer reads that as clean\n' "$name" "${tok:-none}"; fails=1; fi ;;
      CLOSED)  run=$((run+1)); printf '  [closed] %-44s rc=%s, no OK token\n' "$name" "$rc" ;;
      *)       err=1; printf '  [ERROR ] %-44s harness failure: %s\n' "$name" "$tok" ;;
    esac
  done
  for name in "${!ALLOWC[@]}"; do
    case "${SEEN[$name]:-absent}" in
      OPEN|RC0|TIMEOUT) ;;
      absent) printf '  [FAIL  ] allowlist row exempts %s, which emits no OK token and was never run — stale row\n' "$name"; fails=1 ;;
      *)      printf '  [FAIL  ] allowlist row exempts %s, but it is %s here — the exemption exempts nothing; delete it\n' "$name" "${SEEN[$name]}"; fails=1 ;;
    esac
  done
  printf 'FAILOPEN_CLOSURE_POP=%d\nFAILOPEN_CLOSURE_RUN=%d\nFAILOPEN_CLOSURE_OPEN=%d\nFAILOPEN_CLOSURE_RC0=%d\nFAILOPEN_CLOSURE_ALLOWED=%d\nFAILOPEN_CLOSURE_UNRUN=%d\nFAILOPEN_CLOSURE_TIMEOUT=%d\n' "$pop" "$run" "$open" "$rc0" "$allowed" "$unrun" "$tmo"
  # Tripwire against the population filter itself: an independent, pipeline-free count of files
  # whose source (comments included) carries a verdict token is an UPPER bound on $pop. If the
  # filter returns less than half of it, the filter — not the tree — is broken.
  local upper; upper=$(grep -lE "$SRCTOK" "$tree"/scripts/*.sh "$tree"/scripts/*.py 2>/dev/null | wc -l)
  if [ "$upper" -gt 0 ] && [ $((pop * 2)) -lt "$upper" ]; then
    echo "  [ERROR] population filter returned $pop of an upper bound of $upper files carrying a verdict token — the filter dropped scripts (the instance-24 shape)"; err=1
  fi
  if [ "$run" -lt 5 ]; then echo "  [ERROR] only $run runnable token-emitting script(s) under $tree/scripts — population collapsed (floor 5)"; err=1; fi
  if [ "$err" -ne 0 ]; then echo "FAILOPEN_CLOSURE=ERROR"; return 2; fi
  if [ "$fails" -ne 0 ]; then echo "FAILOPEN_CLOSURE=FAIL open=$open rc0=$rc0"; return 1; fi
  echo "FAILOPEN_CLOSURE=OK every runnable gate refuses an empty world ($run run, $unrun unrun, $allowed allowlisted)"; return 0
}

if [ "$SELFTEST" -eq 1 ]; then
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; mkdir -p "$T/scripts"; f=0
  mk(){ printf '%s\n' "$2" > "$T/scripts/$1"; }
  mk plant_open.sh      'echo "PLANT_OPEN=OK"; exit 0'
  mk plant_rc0.sh       'echo "PLANT_RC0=SKIP absent"; exit 0'
  mk plant_closed.sh    '[ -r target.txt ] || { echo "PLANT_CLOSED=ERROR"; exit 2; }; echo "PLANT_CLOSED=OK"'
  mk plant_fail.sh      'echo "PLANT_FAIL=FAIL"; exit 1'
  mk plant_unrun.sh     'touch "$HOME/RAN_UNRUN"; az vm delete -n x; echo "PLANT_UNRUN=OK"'
  mk plant_allowed.sh   'echo "PLANT_ALLOWED=PASS"; exit 0'
  mk plant_py_open.py   'print("PLANT_PY=PASS")'
  mk plant_comment.sh   '# az vm delete in a COMMENT must not make this unrun
[ -r target.txt ] || { echo "PLANT_COMMENT=ERROR"; exit 2; }; echo "PLANT_COMMENT=OK"'
  mk plant_notoken.sh   'echo hello; exit 0'
  mk plant_abs.sh       'touch "$HOME/RAN_ABS"; [ -d /home/claude/github/roae ] && echo "PLANT_ABS=OK"'
  mk plant_closed2.sh   '[ -r x.tsv ] || { echo "PLANT_CLOSED2=ERROR unreadable"; exit 2; }; echo "PLANT_CLOSED2=OK"'
  mk plant_closed3.py   'import sys, os\nif not os.path.exists("x.json"): print("PLANT_CLOSED3=ERROR"); sys.exit(2)\nprint("PLANT_CLOSED3=PASS")'
  printf 'plant_allowed.sh\tself-contained\tfixture: prints its token from no input on purpose\n' > "$T/allow"
  out=$(gate "$T" "$T/allow"); rc=$?
  chk(){ if eval "$2"; then echo "  [ok]   $1"; else echo "  [FAIL] $1"; f=1; fi; }
  chk "planted tree -> FAIL (rc 1)"                 '[ "$rc" -eq 1 ]'
  chk "FAILOPEN_CLOSURE=FAIL token, whole line"     'grep -qE "^FAILOPEN_CLOSURE=FAIL" <<<"$out"'
  chk "the unconditional OK is OPEN"                'grep -qE "^\s*\[OPEN  \] +plant_open.sh" <<<"$out"'
  chk "the python OK is OPEN"                       'grep -qE "^\s*\[OPEN  \] +plant_py_open.py" <<<"$out"'
  chk "exit-0-with-SKIP is RC0"                     'grep -qE "^\s*\[RC0   \] +plant_rc0.sh" <<<"$out"'
  chk "ERROR-on-absent is closed"                   'grep -qE "^\s*\[closed\] +plant_closed.sh" <<<"$out"'
  chk "FAIL-on-absent is closed"                    'grep -qE "^\s*\[closed\] +plant_fail.sh" <<<"$out"'
  chk "az in a non-comment line -> UNRUN, never executed" 'grep -qE "^\s*\[unrun \] +plant_unrun.sh" <<<"$out" && [ ! -e "$T/RAN_UNRUN" ]'
  chk "a hard-coded absolute repo path -> ABSPATH, never executed" 'grep -qE "^\s*\[abspth\] +plant_abs.sh" <<<"$out" && [ ! -e "$T/RAN_ABS" ]'
  chk "az in a COMMENT does not make a script unrun" 'grep -qE "^\s*\[closed\] +plant_comment.sh" <<<"$out"'
  chk "allowlisted self-contained script is allowed" 'grep -qE "^\s*\[allow \] +plant_allowed.sh" <<<"$out"'
  chk "a script with no verdict token is not in the population" '! grep -q plant_notoken <<<"$out"'
  chk "counts: OPEN=2 RC0=1 ALLOWED=1 UNRUN=2 (az + abspath)" 'grep -qx "FAILOPEN_CLOSURE_OPEN=2" <<<"$out" && grep -qx "FAILOPEN_CLOSURE_RC0=1" <<<"$out" && grep -qx "FAILOPEN_CLOSURE_ALLOWED=1" <<<"$out" && grep -qx "FAILOPEN_CLOSURE_UNRUN=2" <<<"$out"'
  rm -f "$T/scripts/plant_open.sh" "$T/scripts/plant_rc0.sh" "$T/scripts/plant_py_open.py"
  out=$(gate "$T" "$T/allow"); rc=$?
  chk "with the open fixtures removed -> OK (rc 0)"  '[ "$rc" -eq 0 ] && grep -qE "^FAILOPEN_CLOSURE=OK" <<<"$out"'
  printf 'plant_closed.sh\tself-contained\tthis row exempts a script that is CLOSED\n' >> "$T/allow"
  out=$(gate "$T" "$T/allow"); rc=$?
  chk "an allowlist row that exempts nothing -> FAIL" '[ "$rc" -eq 1 ] && grep -q "exempts nothing" <<<"$out"'
  printf 'plant_allowed.sh\tself-contained\tfixture: prints its token from no input on purpose\nno_such_script.sh\tself-contained\tnames nothing at all\n' > "$T/allow"
  out=$(gate "$T" "$T/allow"); rc=$?
  chk "an allowlist row naming a nonexistent script -> ERROR" '[ "$rc" -eq 2 ] && grep -qE "^FAILOPEN_CLOSURE=ERROR" <<<"$out"'
  printf 'plant_allowed.sh\tself-contained\tfixture: prints its token from no input on purpose\n' > "$T/allow"
  mk plant_slow.sh 'sleep 30; echo "PLANT_SLOW=OK"'
  out=$(TO=2 gate "$T" "$T/allow"); rc=$?; # TO is read by run_one from the global
  chk "a script that cannot finish with no inputs -> ERROR (ungradable)" '[ "$rc" -eq 2 ] && grep -q "did not finish" <<<"$out"'
  rm -f "$T/scripts/plant_slow.sh"
  T2=$(mktemp -d); mkdir -p "$T2/scripts"; printf 'echo A=OK\n' > "$T2/scripts/a.sh"; printf 'echo B=ERROR; exit 2\n' > "$T2/scripts/b.sh"
  out=$(gate "$T2" ""); rc=$?; rm -rf "$T2"
  chk "population floor: 2 scripts -> ERROR"        '[ "$rc" -eq 2 ] && grep -q "population collapsed" <<<"$out"'
  out=$(gate "$T/nowhere" ""); rc=$?
  chk "no scripts/ dir -> ERROR"                    '[ "$rc" -eq 2 ]'
  [ "$f" -eq 0 ] && { echo "FAILOPEN_CLOSURE_SELFTEST=PASS"; exit 0; } || { echo "FAILOPEN_CLOSURE_SELFTEST=FAIL"; exit 1; }
fi

[ -n "$TREE" ] || TREE=$(cd "$(dirname "$0")/.." && pwd)
[ -n "$ALLOW" ] || { [ -f "$TREE/scripts/failopen_closure_allow.tsv" ] && ALLOW="$TREE/scripts/failopen_closure_allow.tsv"; }
echo "== FAIL-OPEN CLOSURE: every token-emitting script under $TREE/scripts, run with all inputs ABSENT (timeout ${TO}s) =="
gate "$TREE" "$ALLOW"; exit $?
