#!/usr/bin/env bash
# exec_lane.sh — the EXECUTION LANE: run the repo's documented commands, verbatim, on a
# default environment, and report what actually happens.
#
# WHY THIS EXISTS (2026-08-21)
#   Every defect the cold review found — the estimator SIGSEGV under the default 8 MB stack,
#   the verify.c build line that did not link (-lm missing), the stale test count, the
#   prefix-depth trilemma — existed because documentation was checked and EXECUTION never
#   was. No review pass and no repo gate had ever executed a published reproduction command.
#   Four named blind spots (roae-private/PRECODEX_GAP_ANALYSIS_2026_08_21.md §2):
#     (a) no execution lane at all — a text sweep cannot see a 7.23 MB stack frame;
#     (b) doc-vs-code auditing covered flags and env vars, never BUILD/LINK lines or arity;
#     (c) the counted-number sweep was LIST-driven, so anything off the list was invisible;
#     (d) report-only gate legs were never invoked.
#   This lane closes (a) and (b) directly and is built class-driven, not list-driven, so it
#   does not reintroduce (c): commands are EXTRACTED from the docs by shape (fenced blocks,
#   `Reproduce:` directives, inline backticked commands), never from a curated list.
#
# WHAT IT DOES
#   1. EXTRACT every command-shaped line from every tracked *.md file (three generative
#      sources: fenced code blocks, `Reproduce:` paragraphs, inline backtick spans).
#   2. EXECUTE the executable ones verbatim in a scratch copy of the tree, serially, under
#      a DEFAULT environment — soft stack limit 8 MB (the Linux default), no special flags —
#      each under a wall-clock budget. Build lines (cc/gcc/clang) run first, with their own
#      larger budget, so the binaries the run-commands need exist exactly as the docs build
#      them.
#   3. REPORT three outcome classes, never two (the verify_all.sh lesson: a host without
#      drat-trim once produced 22 indistinguishable "FAIL cert" lines):
#        PASS       — exit 0; or a documented-requirement refusal (the command declined
#                     loudly, naming a prerequisite the source doc also states earlier —
#                     e.g. the estimator's stack preflight where the doc requires
#                     `ulimit -s unlimited`).
#        FAIL       — crash (SIGSEGV), link/compile error, or unexplained nonzero exit.
#                     A refusal whose prerequisite the doc does NOT state is also FAIL:
#                     an undocumented environment requirement is a doc defect.
#        SKIPPED-*  — not a verdict, and every skip is PRINTED with its reason:
#                     MISSING-TOOL (tool/module not on this host), MISSING-INPUT (the
#                     command names a file the tree does not ship), BUDGET (ran past the
#                     cheap budget and was killed — expensive, not failed), RESOURCE
#                     (SIGKILL/SIGABRT with allocator messages — the host, not the claim),
#                     PLACEHOLDER (<metavars>, unset $VARS, ..., heredocs — not runnable
#                     verbatim), OPS (cloud/network/privileged/destructive — never run),
#                     FRAGMENT (an inline prose mention that is not a complete command).
#   4. VERDICT: EXEC_LANE=PASS only if no gating FAIL. Machine-checkable tokens
#      (grep -qx): EXEC_LANE=PASS|FAIL, plus EXEC_LANE_{EXTRACTED,RUN,PASS,FAIL,SKIP}=N
#      and EXEC_LANE_SCOPE=FULL|PARTIAL|LIST-ONLY.
#
# GATING SCOPE (a class rule, not a per-command list): a FAIL gates the verdict only when
#   its source document instructs a present-day reader — README.md, documentation/,
#   reports/, lean/, viz/, example/. Files that narrate past runs (documentation/HISTORY.md,
#   documentation/PERFORMANCE_HISTORY.md, runs/, enumeration/) and the operator doc
#   (CLAUDE.md) are executed and reported but marked FAIL-NONGATING: a command that ran in
#   April is not a present-tense claim that it runs today.
#
# KNOWN LIMITS, stated so a green run is not over-read:
#   - The lane checks that commands EXECUTE, not that their output matches published
#     figures ("must print sha 403f..." comments are not asserted — future work).
#   - SKIPPED-BUDGET commands are NOT covered; the skip list is printed precisely so a
#     silent cap cannot read as coverage. Long-running repo gates (verify_all.sh, tests.py,
#     full roae.py) budget-skip here because they are already executed elsewhere.
#   - The OPS deny-list means cloud/deployment recipes are never exercised here.
#
# USAGE
#   scripts/exec_lane.sh                 # full lane on this tree
#   scripts/exec_lane.sh --list          # extraction inventory only, nothing executed
#   scripts/exec_lane.sh --only REGEX    # run only commands matching REGEX (builds always
#                                        # run) — a DEV/DEMO filter; verdict marked PARTIAL
#   scripts/exec_lane.sh --tree DIR      # run against another checkout (e.g. a scratch
#                                        # copy with a defect re-introduced, to prove the
#                                        # lane catches it)
#   EXEC_LANE_BUDGET=30                  # per-command budget, seconds (default 30)
#   EXEC_LANE_BUILD_BUDGET=300           # per-build budget, seconds (default 300)
#   EXEC_LANE_KEEP=1                     # keep the scratch workspace for inspection
#
# https://github.com/petersm3/roae — Developed with AI assistance (Claude, Anthropic)
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ONLY=""; MODE="run"
while [ $# -gt 0 ]; do
  case "$1" in
    --list) MODE="list"; shift ;;
    --only) ONLY="$2"; shift 2 ;;
    --tree) ROOT="$(cd "$2" && pwd)"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
BUDGET="${EXEC_LANE_BUDGET:-30}"
BUILD_BUDGET="${EXEC_LANE_BUILD_BUDGET:-300}"

# ---------------------------------------------------------------- 1. EXTRACT
# Generative extraction: every tracked *.md, three source shapes, no curated command list.
INV="$(mktemp "${TMPDIR:-/tmp}/exec_lane_inv.XXXXXX")"
python3 - "$ROOT" > "$INV" <<'PYEOF'
import os, re, shutil, subprocess, sys
ROOT = sys.argv[1]
files = [f for f in subprocess.run(['git','-C',ROOT,'ls-files','*.md'],
         capture_output=True, text=True).stdout.split('\n') if f]
KNOWN = {'solve','verify','drat-trim','lean','kissat','elan','ulimit'}   # project/toolchain names
                                                                # not necessarily on PATH
def tok0(c):
    m = re.match(r'^(?:[A-Za-z_][A-Za-z0-9_]*=\S+\s+)*([A-Za-z0-9_./+-]+)', c)
    return m.group(1) if m else None
def cmd_shaped(c, need_args):
    t = tok0(c)
    if not t: return False
    if need_args and len(c.split()) < 2: return False
    if t.startswith('/') and os.path.exists(t) and not os.access(t, os.X_OK): return False
    return (t.startswith(('./','../','/')) or t in KNOWN or shutil.which(t) is not None)
def strip_opt(c):   # remove [ optional ] synopsis groups so e.g. `solve --verify [f]` runs
    prev = None
    while prev != c:
        prev = c; c = re.sub(r'\[[^\[\]]*\]', '', c)
    return re.sub(r'\s+', ' ', c).strip()
def dequote(c):
    c = re.sub(r'\$\([^)]*\)', '', c)
    c = re.sub(r'"[^"]*"', '', c)
    return re.sub(r"'[^']*'", '', c)
def fence_reject(c):
    if ' = ' in c or '<<' in c: return True          # pseudocode / heredoc
    if re.match(r'^[A-Za-z0-9_.]+\(', c): return True # function-call pseudocode
    if '(' in dequote(c): return True                 # prose parentheticals
    t = tok0(c); w = c.split()
    if t and not (t.startswith(('./','../','/')) or t in KNOWN):
        if len(w) >= 3 and not any(re.search(r'[-/.|>=$]', x) for x in w[1:]):
            return True                               # bare-word prose ("sleep 30 minutes")
    return False
def placeholder(c):
    if re.search(r' == | = | % | — |[×→≠≥≤]', c): return True
    if re.search(r'<[^>]*>', c) or '...' in c or '…' in c: return True
    if '<<' in c: return True
    for v in re.findall(r'\$\{?([A-Z][A-Z0-9_]*)', c):
        if v not in os.environ: return True           # unset $METAVAR
    if re.search(r'\S\|\S', c): return True           # a|b alternation inside a token
    body = re.sub(r'^(?:[A-Za-z_][A-Za-z0-9_]*=\S+\s+)*', '', c)
    for w in body.split()[1:]:
        w = w.strip('"\'')
        if re.match(r'^[A-Z][A-Z0-9_.]*$', w): return True   # ALL-CAPS metavariable
    return False
GIT_MUT = r'\bgit\s+(clone|push|commit|fetch|pull|reset|checkout|rebase|merge|tag|add|rm|mv|stash|init|remote)\b'
OPS = r'(?:^|[\s|&;])(sudo|ssh|scp|sftp|az|azcopy|apt-get|apt|dpkg|pip3?|mkfs(\.\w+)?|mount|umount|dd|reboot|shutdown|poweroff|blkid|curl|wget|nc|ncat|setsid|nohup|kill|pkill|killall|crontab|systemctl|systemd-run|service|rm|resize2fs|fdisk|parted|mkswap|swapon|swapoff|fsck(\.\w+)?|e2fsck|tune2fs|losetup|elan|rustup)\b'
DEVREF = r'(?:^|[\s="\'])/dev/(sd|nvme|xvd|loop)'   # block-device references are ops, full stop
def ops_deny(c):
    if re.search(GIT_MUT, c): return True
    if re.search(r'\bgit\b', c) and not re.search(r'\bgit\s+(-C\s+\S+\s+)?(rev-parse|log|show|status|diff|reflog|describe|ls-files)\b', c):
        return True
    if re.search(r'>\s*/(proc|sys)/', c): return True
    if re.search(DEVREF, c): return True
    return re.search(OPS, c) is not None
def gating(f):
    if f == 'CLAUDE.md': return 0
    if f.startswith(('runs/','enumeration/')): return 0
    if f in ('documentation/HISTORY.md','documentation/PERFORMANCE_HISTORY.md'): return 0
    return 1
def pick_cwd(f, c):
    docdir = os.path.dirname(f)
    t = tok0(c) or ''
    args = re.sub(r'^(?:[A-Za-z_][A-Za-z0-9_]*=\S+\s+)*', '', c).split()
    cand = []
    if t.startswith(('./','../')): cand.append(t)
    if t in ('python3','python','bash','sh') and len(args) > 1 and not args[1].startswith('-'):
        cand.append(args[1])
    if t == 'lean' and len(args) > 1: cand.append(args[-1])
    for p in cand:
        if docdir and os.path.exists(os.path.join(ROOT, docdir, p)) \
           and not os.path.exists(os.path.join(ROOT, p)):
            return docdir
    return '.'
seen = {}
def emit(f, ln, origin, raw, ulimit_ctx):
    c = strip_opt(raw.strip())
    c = re.sub(r'\s+#\s.*$', '', c).strip()
    if not c or c.startswith('#'): return
    if not cmd_shaped(c, need_args=(origin == 'inline')): return
    if origin == 'fence' and fence_reject(c): return
    t = tok0(c)
    cls = 'BUILD' if t in ('cc','gcc','clang','g++') else 'RUN'
    if ops_deny(c): cls = 'SKIP-OPS'
    elif placeholder(c): cls = 'SKIP-PLACEHOLDER'
    if cls == 'RUN':
        m2 = re.match(r'^(?:ulimit [^;]*;\s*)?(?:bash|sh)\s+(\S+)', c)
        if m2:
            for base in (os.path.join(ROOT, os.path.dirname(f)), ROOT):
                q = os.path.join(base, m2.group(1))
                if os.path.isfile(q):
                    body = open(q, encoding='utf-8', errors='replace').read()
                    if re.search(r'\bsudo\b|\bshutdown\b|\bnohup\b|\bsetsid\b|\bssh\b|\baz |/(home|data|mnt)/', body):
                        cls = 'SKIP-OPS'
                    break
    key = re.sub(r'\s+', ' ', c)
    e = seen.setdefault(key, {'cls':cls,'gat':0,'ctx':0,'cwd':pick_cwd(f,c),
                              'src':[], 'origins':set()})
    e['gat'] = max(e['gat'], gating(f)); e['ctx'] = max(e['ctx'], ulimit_ctx)
    e['origins'].add(origin)
    if len(e['src']) < 3: e['src'].append(f'{f}:{ln}')
for f in files:
    try: lines = open(os.path.join(ROOT,f), encoding='utf-8', errors='replace').read().split('\n')
    except OSError: continue
    ul = [i for i,L in enumerate(lines) if 'ulimit -s' in L]
    def ctx(i): return 1 if any(j <= i for j in ul) else 0   # requirement stated EARLIER in file
    in_f = False; i = 0
    while i < len(lines):
        L = lines[i]
        if re.match(r'^\s*```', L):
            in_f = not in_f; i += 1; continue
        if in_f:
            raw = L.strip()
            if raw.startswith('$ '): raw = raw[2:]
            j = i
            while raw.endswith('\\') and j+1 < len(lines) and not lines[j+1].strip().startswith('```'):
                j += 1; raw = raw[:-1] + ' ' + lines[j].strip()
            emit(f, i+1, 'fence', raw, ctx(i)); i = j+1; continue
        if 'Reproduce:' in L:
            para = L; j = i
            while j+1 < len(lines) and lines[j+1].strip() and not lines[j+1].strip().startswith('```'):
                j += 1; para += ' ' + lines[j]
            for cmd in re.findall(r'`([^`]+)`', para):
                emit(f, i+1, 'repro', cmd, ctx(i))
            i = j+1; continue
        for cmd in re.findall(r'`([^`\n]+)`', L):
            emit(f, i+1, 'inline', cmd, ctx(i))
        i += 1
for key, e in seen.items():
    org = 'inline' if e['origins'] == {'inline'} else '+'.join(sorted(e['origins']))
    print('\t'.join([e['cls'], str(e['gat']), str(e['ctx']), e['cwd'], org,
                     ';'.join(e['src']), key]))
PYEOF

N_EXTRACTED=$(wc -l < "$INV")
if [ "$MODE" = "list" ]; then
  sort -t$'\t' -k1,1 "$INV" | awk -F'\t' '{printf "%-17s gat=%s %-13s %-28s %s\n",$1,$2,$5,$6,$7}'
  echo "EXEC_LANE_EXTRACTED=$N_EXTRACTED"; echo "EXEC_LANE_SCOPE=LIST-ONLY"
  rm -f "$INV"; exit 0
fi

# ---------------------------------------------------------------- 2. WORKSPACE
WS="$(mktemp -d "${TMPDIR:-/tmp}/exec_lane_ws.XXXXXX")"
LOGDIR="$(mktemp -d "${TMPDIR:-/tmp}/exec_lane_logs.XXXXXX")"
( cd "$ROOT" && git ls-files -z | tar --null -T - -cf - ) | tar -xf - -C "$WS"
[ -d "$ROOT/.git" ] && cp -a "$ROOT/.git" "$WS/.git"
mkdir -p "$WS/.git/hooks" 2>/dev/null
# Stage the copied tree so the per-command reset (git checkout -- .) restores the tree AS
# GIVEN, not the last commit — without this, a --tree target's uncommitted state (e.g. a
# scratch copy with a defect re-introduced) is silently reverted after the first command.
git -C "$WS" add -A 2>/dev/null
echo "workspace: $WS  (scratch copy of tracked files; nothing runs in the real tree)"
echo "logs:      $LOGDIR"
echo "budgets:   run=${BUDGET}s build=${BUILD_BUDGET}s   stack: soft limit 8 MB (Linux default)"
[ -n "$ONLY" ] && echo "PARTIAL RUN: --only '$ONLY' — verdict does NOT attest full coverage"
echo

# ---------------------------------------------------------------- 3. EXECUTE
NP=0; NF=0; NS=0; NR=0; NFN=0; IDX=0
FAIL_LINES=""

run_one() {  # $1=class $2=gating $3=ctx $4=cwd $5=origins $6=sources $7=command
  local cls="$1" gat="$2" ctx="$3" cwd="$4" org="$5" src="$6" cmd="$7"
  local budget="$BUDGET"; [ "$cls" = "BUILD" ] && budget="$BUILD_BUDGET"
  IDX=$((IDX+1))
  local log="$LOGDIR/$(printf '%03d' "$IDX").log"
  local execmd="$cmd"
  case "$execmd" in solve\ *|solve) execmd="./$execmd" ;; verify\ *|verify) execmd="./$execmd" ;; esac
  { echo "# src: $src"; echo "# cwd: $cwd  origins: $org  gating: $gat"; echo "# cmd: $cmd"; } > "$log"
  local t0=$SECONDS
  setsid bash -c "ulimit -S -s 8192 2>/dev/null; cd '$WS/$cwd' || exit 97; $execmd" \
    </dev/null >>"$log" 2>&1 &
  local pid=$!
  local i=0 killed=0
  while [ $i -lt $((budget*10)) ]; do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1; i=$((i+1))
  done
  if kill -0 "$pid" 2>/dev/null; then
    kill -TERM -- -"$pid" 2>/dev/null; sleep 2; kill -KILL -- -"$pid" 2>/dev/null; killed=1
  fi
  wait "$pid" 2>/dev/null; local rc=$?
  [ $killed -eq 1 ] && rc=124
  local dt=$((SECONDS-t0))
  local out; out="$(tail -c 4000 "$log")"
  local ref; ref=$(grep -oE "see /[^ )]+\.log" <<<"$out" | head -1 | cut -d" " -f2)
  if [ -n "$ref" ] && [ -f "$ref" ]; then out="$out
$(tail -c 2000 "$ref")"; fi
  local outcome=""
  if   [ $rc -eq 0 ];   then outcome="PASS"
  elif [ $rc -eq 1 ] && grep -qE '^(grep|egrep|fgrep|pgrep|diff|cmp)( |$)' <<<"$cmd" && ! grep -qiE "error|usage" <<<"$out"; then
    outcome="PASS(exit 1 = no-match/differs — documented result, not an error)"
  elif [ $rc -eq 139 ] || grep -q "Segmentation fault" <<<"$out"; then outcome="FAIL(SIGSEGV)"
  elif [ $rc -eq 124 ]; then outcome="SKIP-BUDGET(>${budget}s, killed — expensive, no verdict)"
  elif [ $rc -eq 137 ]; then
    if grep -qiE "out of memory|cannot allocate|bad_alloc|oom" <<<"$out"
    then outcome="SKIP-RESOURCE(SIGKILL+alloc msg — host, not claim)"
    else outcome="SKIP-BUDGET(SIGKILL at ${budget}s — expensive or OOM, no verdict)"; fi
  elif [ $rc -eq 127 ]; then
    if grep -q "No such file" <<<"$out"; then outcome="SKIP-MISSING-INPUT"
    else outcome="SKIP-MISSING-TOOL"; fi
  elif grep -qE "command not found|ModuleNotFoundError|No module named|not found on PATH" <<<"$out"; then
    outcome="SKIP-MISSING-TOOL"
  elif grep -q "ulimit" <<<"$out"; then
    if [ "$ctx" = "1" ]; then outcome="PASS(refused-as-documented: names a prereq the doc states)"
    else outcome="FAIL(refusal names a prereq the source doc does NOT state)"; fi
  elif grep -qiE "failed to allocate|cannot allocate|out of memory|bad_alloc|alloc.{0,16}fail|free disk in cwd|No space left on device" <<<"$out"; then
    outcome="SKIP-RESOURCE(allocation/disk failure — host, not claim)"
  elif grep -qE "No such file or directory|cannot open|cannot read|\[Errno 2\]|[Nn]o .* files found" <<<"$out"; then
    outcome="SKIP-MISSING-INPUT"
  elif [ "$org" = "inline" ] && grep -qiE "usage|requires an argument|missing operand|no input file|invalid|unexpected end of file|stdin|no makefile found|No rule to make target|no matching criteria|Try '" <<<"$out"; then
    outcome="SKIP-FRAGMENT(inline mention, incomplete as a command)"
  else outcome="FAIL(rc=$rc)"; fi
  git -C "$WS" checkout -q -- . 2>/dev/null
  git -C "$WS" clean -fdqx -e solve -e verify >/dev/null 2>&1
  case "$outcome" in
    PASS*) NP=$((NP+1));;
    FAIL*) if [ "$gat" = "1" ]; then NF=$((NF+1)); else outcome="$outcome[NONGATING]"; NFN=$((NFN+1)); fi
           FAIL_LINES="$FAIL_LINES$outcome  $src  $cmd"$'\n';;
    SKIP-RESOURCE*) NR=$((NR+1));;
    *) NS=$((NS+1));;
  esac
  printf '%-4s %-52s %3ss  %s\n     src: %s\n' "$IDX." "$outcome" "$dt" "$cmd" "$src"
}

# Pre-classified skips are still PRINTED — a silent cap reads as coverage it does not have.
while IFS=$'\t' read -r cls gat ctx cwd org src cmd; do
  case "$cls" in
    SKIP-OPS)         echo "SKIP-OPS(cloud/network/privileged/destructive — never run)  $src  $cmd"; NS=$((NS+1));;
    SKIP-PLACEHOLDER) echo "SKIP-PLACEHOLDER(metavars/unset vars — not runnable verbatim)  $src  $cmd"; NS=$((NS+1));;
  esac
done < "$INV"
echo
echo "== BUILD lines (documented compiler invocations — always run, even under --only) =="
while IFS=$'\t' read -r cls gat ctx cwd org src cmd; do
  [ "$cls" = "BUILD" ] && run_one "$cls" "$gat" "$ctx" "$cwd" "$org" "$src" "$cmd"
done < "$INV"
echo
echo "== RUN commands =="
while IFS=$'\t' read -r cls gat ctx cwd org src cmd; do
  [ "$cls" = "RUN" ] || continue
  if [ -n "$ONLY" ] && ! grep -qE "$ONLY" <<<"$cmd"; then continue; fi
  run_one "$cls" "$gat" "$ctx" "$cwd" "$org" "$src" "$cmd"
done < "$INV"

# ---------------------------------------------------------------- 4. VERDICT
echo
echo "== SUMMARY =="
[ -n "$FAIL_LINES" ] && { echo "FAILURES:"; printf '%s' "$FAIL_LINES"; echo; }
echo "EXEC_LANE_EXTRACTED=$N_EXTRACTED"
echo "EXEC_LANE_RUN=$IDX"
echo "EXEC_LANE_PASS=$NP"
echo "EXEC_LANE_FAIL=$NF"
echo "EXEC_LANE_FAIL_NONGATING=$NFN"
echo "EXEC_LANE_SKIP=$((NS+NR))"
if [ -n "$ONLY" ]; then echo "EXEC_LANE_SCOPE=PARTIAL"; else echo "EXEC_LANE_SCOPE=FULL"; fi
if [ "${EXEC_LANE_KEEP:-0}" != "1" ]; then rm -rf "$WS"; else echo "workspace kept: $WS"; fi
rm -f "$INV"
if [ "$NF" -gt 0 ]; then echo "EXEC_LANE=FAIL"; exit 1; else echo "EXEC_LANE=PASS"; exit 0; fi
