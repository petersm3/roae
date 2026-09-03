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
#      sources: fenced code blocks, `Reproduce:` paragraphs, inline backtick spans). A fenced
#      line continues on the next one after `\`, `|`, `||` or `&&`, and a quoted program that
#      spans lines (`python3 -c "` ... `"`) is one command with its newlines kept; `[optional]`
#      synopsis groups and `# comments` are stripped OUTSIDE quotes only (all 2026-09-02 —
#      before that, 13 of the lane's 21 gating FAILs were commands the extractor had cut).
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
#                     MISSING-TOOL (tool not on this host; for a python MODULE the skip is
#                     granted ONLY when the source doc names the module — an import error
#                     for a module the doc never mentions is FAIL, the same doctrine the
#                     `ulimit` refusal already followed), MISSING-INPUT (the command names
#                     a file the tree does not ship — for a BUILD line this is FAIL: a
#                     compile recipe naming a source or header the tree lacks is the
#                     defect this lane exists to find), DIFF-UNSTATED (`diff`/`cmp` exited
#                     1 = the inputs differ and the source doc says nothing about the
#                     expected outcome; when the doc says "identical"/"no output" that is
#                     FAIL, when it says the inputs differ that is PASS), BUDGET (ran past the
#                     cheap budget and was killed — expensive, not failed), RESOURCE
#                     (SIGKILL/SIGABRT with allocator messages — the host, not the claim),
#                     PLACEHOLDER (<metavars>, unset $VARS, ..., heredocs — not runnable
#                     verbatim; quoting is honoured, so a literal inside a quoted argument
#                     is NOT a metavariable), OPS (cloud/network/privileged/destructive —
#                     never run), FRAGMENT (an inline prose mention that is not a complete
#                     command — listed individually, never silent, and split into
#                     "justified" (the corpus publishes a complete form of the same command)
#                     and UNJUSTIFIED (it does not — the only invocation a reader has is the
#                     one that did not run)).
#   3b. MEASURED-FIGURE LEG (prose batch P31 / Codex V2-F11 #2, #4; built 2026-09-02). Every
#      TR opens with "Every MEASURED result carries a reproduction command". This leg holds the
#      TRs to it mechanically: each line of reports/TR*.md carrying the marker MEASURED (the
#      header promise and changelog rows excluded) must sit within a window (2 lines above,
#      15 below) of a command the extractor classes RUN or BUILD — i.e. a complete invocation
#      with no ellipsis and no metavariable. An UNRESOLVED site is a gating FAIL. The leg
#      ERRORS (never passes) when it can scan no TR or finds the promise in none of them:
#      an absent population is not a clean one. Evidence bundles under reports/evidence/ are
#      outside the leg (their figures resolve through the bundle's `Reproduce:` directive,
#      not a per-figure window) and are COUNTED, not silently dropped. Runs in --list too.
#   4. VERDICT: EXEC_LANE=PASS only if no gating FAIL. Machine-checkable tokens
#      (grep -qx): EXEC_LANE=PASS|FAIL, plus EXEC_LANE_{EXTRACTED,RUN,PASS,FAIL,SKIP}=N,
#      EXEC_LANE_{FRAGMENT,FRAGMENT_UNJUSTIFIED}=N,
#      EXEC_LANE_{UNDOC_DEP,DIFF_UNSTATED,BUILD_MISSING_SOURCE}=N (the three exemptions
#      closed 2026-09-02 — each printed so its blast radius is a number, not a guess),
#      EXEC_LANE_MEASURED_{TRS,PROMISES,SITES,UNRESOLVED,EXCLUDED}=N,
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
#   - SKIP-FRAGMENT is a skip, not a verdict: by default a published command that exits with a
#     usage error still does not gate. EXEC_LANE_FRAGMENT_UNJUSTIFIED is the number to watch,
#     and EXEC_LANE_STRICT_FRAGMENT=1 is how to make it bite.
#   - A command a source line QUOTES AS FAILING (the verb right after the closing backtick:
#     "fails", "does not link", ...) is held to failing — PASS if rc != 0, FAIL if it exits 0 (a
#     stale correction note). Counting cannot tell a defect from its own withdrawal quote; the
#     verb can (2026-09-02, SOLVE_C_CLI.md:2061).
#   - A failed BUILD line's `-o` target is restored from the previous successful build: ld
#     unlinks its output on a failed link, and on 2026-09-02 one quoted-as-failing build line
#     took `solve` with it, so 167 RUN commands reported SKIP-MISSING-INPUT and no `./solve`
#     command ran at all. A skip that large hid in the census; it no longer can.
#   - The grep-family / diff-family exit-1 rules look at the LAST stage of a pipeline, since
#     that is whose status a pipeline returns (`env | grep -c ...` exiting 1 is grep's no-match).
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
#   EXEC_LANE_STRICT_FRAGMENT=1          # promote UNJUSTIFIED fragments from a gating document
#                                        # to FAIL. OFF by default and the reason is measured,
#                                        # not assumed: 204 inline-origin RUN commands in the
#                                        # tracked corpus publish no longer runnable form, and at
#                                        # least one (`gcc -Wconversion -Wsign-conversion`,
#                                        # reports/TR11:366) is a genuine prose mention of two
#                                        # compiler flags that would become a false FAIL. The
#                                        # count is published either way; turning this on is the
#                                        # operator's call and costs a full lane run.
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
# Shared normalisation helpers, loaded by BOTH python blocks below (the extractor and the
# MEASURED-figure leg) so the two can never disagree about what a command's key is.
HELP="$(mktemp "${TMPDIR:-/tmp}/exec_lane_help.XXXXXX")"
cat > "$HELP" <<'PYHELP'
import re, shlex
def qsplit(s):
    """[(text, quoted)] by shell quoting -- "..." and '...' spans, backslash escapes outside quotes
    and inside double quotes. An UNTERMINATED quote runs to the end and is reported quoted (the
    fail-closed direction: nothing after an open quote is judged as shell syntax)."""
    segs, buf, q, i, n = [], [], None, 0, len(s)
    def flush(quoted):
        if buf: segs.append((''.join(buf), quoted)); buf.clear()
    while i < n:
        ch = s[i]
        if q is None:
            if ch in '"\'': flush(False); q = ch; buf.append(ch)
            elif ch == '\\' and i+1 < n: buf.append(ch); buf.append(s[i+1]); i += 1
            else: buf.append(ch)
        else:
            buf.append(ch)
            if ch == '\\' and q == '"' and i+1 < n: buf.append(s[i+1]); i += 1
            elif ch == q: flush(True); q = None
        i += 1
    flush(q is not None)
    return segs
def strip_opt(c):
    """Remove [ optional ] synopsis groups whose BRACKETS sit outside quotes (the group may contain
    a quoted span: `[--dp-spec "3.0,3.1,3.2@0" | --dp-spec full31@0]` goes as a whole), so e.g.
    `solve --verify [f]` runs; a bracket INSIDE quotes is program text and stays
    (`int(sys.argv[1])`, `lambda k:[...]`). Whitespace collapses outside quotes only, so a quoted
    multi-line program keeps its newlines and indentation. (Quote-aware since 2026-09-02;
    measured pre-fix: CANONICAL_HASHES.md:436 ran as `int(sys.argv)`, CIRCULAR_KING_WEN.md:57 as
    `r=lambda k:;` -- two FAIL(rc=1) verdicts the lane itself manufactured.)"""
    out, stack, q, i, n = [], [], None, 0, len(c)
    while i < n:
        ch = c[i]
        if q is None:
            if ch in '"\'': q = ch; out.append(ch)
            elif ch == '\\' and i+1 < n: out.append(ch); out.append(c[i+1]); i += 1
            elif ch == '[': stack.append(len(out)); out.append(ch)
            elif ch == ']' and stack: del out[stack.pop():]
            else: out.append(ch)
        else:
            out.append(ch)
            if ch == '\\' and q == '"' and i+1 < n: out.append(c[i+1]); i += 1
            elif ch == q: q = None
        i += 1
    return ''.join(re.sub(r'[ \t\r]+', ' ', t) if not quoted else t
                   for t, quoted in qsplit(''.join(out))).strip()
def strip_comment(c):
    """Drop a `# note` that sits OUTSIDE quotes -- a whole-line comment, or a trailing one preceded
    by whitespace -- and everything after it. A `#` inside a quoted program is code, and a quote
    character inside a comment (`# the launcher's budget`) is prose, not an open quote: measured
    2026-09-02, that apostrophe made the fence walker swallow the six commands after it."""
    out = []
    for t, quoted in qsplit(c):
        if quoted: out.append(t); continue
        m = re.search(r'(^|\s)#(\s|$)', t)
        if m: out.append(t[:m.start()]); break
        out.append(t)
    return ''.join(out).strip()
def balanced(s):
    try: shlex.split(strip_comment(s)); return True
    except ValueError: return False
def norm_cmd(c):
    """The extractor's key normalisation, applied identically by the MEASURED leg."""
    c = c.strip()
    if c.startswith('$ '): c = c[2:]
    return strip_comment(strip_opt(c))
PYHELP
python3 - "$ROOT" "$HELP" > "$INV" <<'PYEOF'
import os, re, shlex, shutil, subprocess, sys
ROOT = sys.argv[1]
exec(open(sys.argv[2], encoding='utf-8').read())
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
QSPAN = r'("[^"]*"|\'[^\']*\')'   # a quoted span (regex form, for the prose-shape tests below;
                                  # strip_opt/strip_comment/balanced/norm_cmd come from $HELP)
def dequote(c):
    c = re.sub(r'\$\([^)]*\)', '', c)
    c = re.sub(r'"[^"]*"', '', c)
    return re.sub(r"'[^']*'", '', c)
def fence_reject(c):
    d = dequote(c)
    if ' = ' in d or '<<' in d: return True          # pseudocode / heredoc -- judged OUTSIDE quotes,
                                                     # so a quoted program (`python3 -c "x = 1"`) is
                                                     # a command, not pseudocode (2026-09-02)
    if re.match(r'^[A-Za-z0-9_.]+\(', c): return True # function-call pseudocode
    if '(' in d: return True                          # prose parentheticals
    t = tok0(c); w = c.split()
    if t and not (t.startswith(('./','../','/')) or t in KNOWN):
        if len(w) >= 3 and not any(re.search(r'[-/.|>=$]', x) for x in w[1:]):
            return True                               # bare-word prose ("sleep 30 minutes")
    return False
def placeholder(c):
    unq0 = re.sub(QSPAN, ' Q ', c)                    # prose-shape tests judged OUTSIDE quotes too
    if re.search(r' == | = | % | — |[×→≠≥≤]', unq0): return True
    if re.search(r'<[^>]*>', c) or '...' in c or '…' in c: return True   # a <metavar> anywhere
    if '<<' in unq0: return True                      # heredoc marker OUTSIDE quotes (`<< i` in a
                                                      # quoted Python program is a shift, measured
                                                      # DISTRIBUTIONAL_ANALYSIS.md:432)
    # A dangling operator is a synopsis alternation or a cut pipeline, not a command. Measured
    # 2026-09-02: SAT_CLI.md:22 `python3 sat.py --decode MODEL.txt [TARGET] ... | [--f1-pairs N]`
    # strips to `python3 sat.py --decode MODEL.txt |` and ran as a bash syntax error, FAIL(rc=2).
    if re.search(r'(\|\|?|&&)\s*$', c): return True
    for v in re.findall(r'\$\{?([A-Za-z_][A-Za-z0-9_]*)', c):
        if v not in os.environ: return True           # unset $METAVAR -- lowercase too: measured
                                                      # 2026-09-02, `./solve --branch $p $o 0 2` is
                                                      # a loop body (LARGE_SCALE_CAMPAIGNS.md:671)
                                                      # and ran as FAIL(rc=1) 'Invalid pair index 0'
    # Codex v2 (adjudication row 27's named policy fix, batch P77): QUOTING WAS IGNORED, so a
    # LITERAL living inside a quoted argument was misread as a metavariable and the command was
    # exempted from execution. MEASURED pre-fix: `grep -n "REFUTED 2026-05-16" doc.md` and
    # `grep -n 'E1 F1U exact' solve.c` carry no metavariable at all -- whitespace-splitting cut
    # the quoted string into words and `REFUTED` / `E1` looked like metavariables. Same shape for
    # the alternation test: `--json|--csv` IS a synopsis alternation, but `grep -E "avx|sse"` is
    # an alternation inside a regex ARGUMENT and the command runs verbatim. Both tests now see
    # quoted spans neutralised, and the ALL-CAPS test walks whole shell WORDS, so a multi-word
    # quoted literal is one word and cannot match. A single-word quoted metavariable ("DIR") does
    # still match -- the exemption is narrowed, never widened.
    unq = re.sub(r'"[^"]*"|\'[^\']*\'', ' Q ', c)
    if re.search(r'\S\|\S', unq): return True         # a|b alternation OUTSIDE any quoted span
    try:
        words = shlex.split(c)
    except ValueError:                                # unbalanced quotes: fail CLOSED, keep the
        words = [w.strip('"\'') for w in            # old whitespace-split behaviour
                 re.sub(r'^(?:[A-Za-z_][A-Za-z0-9_]*=\S+\s+)*', '', c).split()]
    i = 0
    while i < len(words) and re.match(r'^[A-Za-z_][A-Za-z0-9_]*=\S*$', words[i]):
        i += 1                                        # leading VAR=val assignments, as before
    for w in words[i+1:]:
        if re.match(r'^[A-Z][A-Z0-9_.]*$', w): return True   # ALL-CAPS metavariable
        # `OLD.bin`, `MODEL.txt`, `OUT.cnf`: an all-caps STEM with a file extension is a metavariable
        # too -- unless the tree ships a file of that name (README.md, VERIFY.md are real files).
        # Measured 2026-09-02: `solve --verify-superset OLD.bin NEW.bin` ran and reported FAIL(rc=2).
        if re.match(r'^[A-Z][A-Z0-9_]*\.[a-z0-9]+$', w) and not os.path.exists(os.path.join(ROOT, w)) \
           and not any(os.path.exists(os.path.join(ROOT, d, w)) for d in ('documentation','reports','lean','viz','example')):
            return True
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
    c = strip_comment(strip_opt(raw.strip()))
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
    key = c                                           # already normalised; a quoted program keeps
                                                      # its newlines and indentation verbatim
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
            in_f = not in_f; fence_ind = re.match(r'^\s*', L).group(0); i += 1; continue
        if in_f:
            # A fence inside a list item is indented; markdown renders its content with that
            # indentation removed, so that is the verbatim form a reader copies. Measured
            # 2026-09-02: TR9:350's `python3 -c "` program sits in a 2-space-indented fence and ran
            # as IndentationError -- on the raw source, which no reader runs.
            def dedent(x): return x[len(fence_ind):] if x.startswith(fence_ind) else x.lstrip()
            raw = L.strip()
            if raw.startswith('$ '): raw = raw[2:]
            j = i
            def more(k): return k+1 < len(lines) and not lines[k+1].strip().startswith('```')
            # A line ending in `\`, `|`, `||` or `&&` continues on the next one. Measured
            # 2026-09-02 (pre-fix, `\` only): BRANCHES_EXPLAINED.md:578-580's four-stage pipeline
            # was extracted as three fragments, each ending in a bare `|`, each FAIL(rc=2).
            while more(j) and (raw.endswith('\\') or re.search(r'(\|\|?|&&)\s*$', raw)):
                j += 1
                raw = (raw[:-1] if raw.endswith('\\') else raw) + ' ' + lines[j].strip()
            # A quoted program that spans lines (`python3 -c "` ... `"`) is ONE command: keep
            # joining, newline-separated and indentation kept, until the quotes balance or the
            # fence ends. Measured pre-fix: DISTRIBUTIONAL_ANALYSIS.md:84/432/523 and
            # VERIFY.md:154 were extracted as their opening line alone (`python3 -c "`) and each
            # ran as an unterminated-quote error, FAIL(rc=2). A block that never balances is
            # still emitted (it fails closed as before) -- a silent drop would hide a defect.
            while more(j) and not balanced(strip_comment(raw)):
                j += 1; raw = raw + '\n' + dedent(lines[j].rstrip())
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
                     ';'.join(e['src']), key.replace('\n', '\x1e')]))   # one TSV row per
PYEOF

EXTRACT_RC=$?
# Codex v2 / fail-open class: the extractor's exit status was DISCARDED. A stubbed
# failing python3 left $INV empty, N_EXTRACTED=0, zero of ~645 commands ran, and the
# lane reported EXEC_LANE=PASS with exit 0 -- a full green light having executed
# nothing. Two guards: the extractor must succeed, AND it must find work. A corpus
# that genuinely contains no runnable command is itself a finding, not a pass.
if [ "$EXTRACT_RC" -ne 0 ]; then
  echo "EXEC_LANE=ERROR extractor-failed rc=$EXTRACT_RC" >&2
  echo "  The command inventory could not be built, so 'no failures' would be vacuous."
  rm -f "$INV" "$HELP"; exit 1
fi
N_EXTRACTED=$(wc -l < "$INV")
if [ "${N_EXTRACTED:-0}" -eq 0 ]; then
  echo "EXEC_LANE=ERROR zero-commands-extracted" >&2
  echo "  The published corpus has never extracted to zero runnable commands. This is a"
  echo "  broken extractor, not a clean tree; refusing to report a lane result."
  rm -f "$INV" "$HELP"; exit 1
fi
# ---------------------------------------------------------------- 1b. MEASURED-FIGURE LEG
# Resolution is judged by THIS lane's own extractor: a window command counts only if the
# inventory holds it as RUN or BUILD (so a `...` recipe, a `<metavar>` synopsis or a bare
# flag mention — all SKIP-PLACEHOLDER or absent — cannot resolve a figure). The window is
# 2 lines above to 15 below the marker line, which covers "figure, then its Reproduce:
# paragraph or fenced block" in every TR layout measured on 2026-09-02.
MEAS_OUT="$(mktemp "${TMPDIR:-/tmp}/exec_lane_meas.XXXXXX")"
python3 - "$ROOT" "$INV" "$HELP" > "$MEAS_OUT" <<'PYEOF'
import re, shlex, subprocess, sys
ROOT, INV = sys.argv[1], sys.argv[2]
exec(open(sys.argv[3], encoding='utf-8').read())   # the extractor's own strip_opt/strip_comment
norm = norm_cmd
def ls(pat):
    r = subprocess.run(['git','-C',ROOT,'ls-files',pat], capture_output=True, text=True)
    if r.returncode != 0: sys.exit(3)
    return [f for f in r.stdout.split('\n') if f]
trs = ls('reports/TR*.md')
others = [f for f in ls('reports/*.md') if f not in trs]
runnable = set()
for row in open(INV, encoding='utf-8'):
    p = row.rstrip('\n').split('\t')
    if len(p) == 7 and p[0] in ('RUN', 'BUILD'): runnable.add(p[6])
PROMISE ='Every MEASURED result carries a reproduction command'
npromise = sites = unres = 0
for f in trs:
    L = open(f'{ROOT}/{f}', encoding='utf-8', errors='replace').read().split('\n')
    if any(PROMISE in l for l in L): npromise += 1
    fence = []; inf = False
    for l in L:
        if re.match(r'^\s*```', l): inf = not inf; fence.append(False)
        else: fence.append(inf)
    for i, l in enumerate(L):
        if not re.search(r'\bMEASURED\b', l): continue
        if PROMISE in l or re.match(r'^\|\s*v\d', l): continue
        sites += 1
        lo, hi = max(0, i-2), min(len(L), i+16)
        cands = []
        for j in range(lo, hi):
            if fence[j]: cands.append(L[j])
            else: cands += re.findall(r'`([^`\n]+)`', L[j])
        hit = next((c for c in cands if norm(c) in runnable), None)
        if hit: print(f'MEASURED-RESOLVED    {f}:{i+1}  -> {norm(hit)}')
        else:
            unres += 1
            print(f'MEASURED-UNRESOLVED  {f}:{i+1}  no RUN/BUILD command within [-2,+15] lines: {l.strip()[:90]}')
excl = 0
for f in others:
    for l in open(f'{ROOT}/{f}', encoding='utf-8', errors='replace').read().split('\n'):
        if re.search(r'\bMEASURED\b', l) and PROMISE not in l: excl += 1
print(f'EXEC_LANE_MEASURED_TRS={len(trs)}')
print(f'EXEC_LANE_MEASURED_PROMISES={npromise}')
print(f'EXEC_LANE_MEASURED_SITES={sites}')
print(f'EXEC_LANE_MEASURED_UNRESOLVED={unres}')
print(f'EXEC_LANE_MEASURED_EXCLUDED={excl}')
if not trs or not npromise:
    print(f'MEASURED-LEG-ERROR: {len(trs)} TR file(s) scanned, {npromise} carry the promise — nothing to hold to it')
    sys.exit(4)
PYEOF
MEAS_RC=$?
if [ "$MEAS_RC" -ne 0 ]; then
  cat "$MEAS_OUT"
  echo "EXEC_LANE=ERROR measured-leg-could-not-run rc=$MEAS_RC" >&2
  echo "  The MEASURED-figure leg found no population (or could not enumerate one), so"
  echo "  'every MEASURED figure resolves' would be vacuous. Refusing to report a lane result."
  rm -f "$INV" "$HELP" "$MEAS_OUT"; exit 1
fi
NMEAS_UNRES=$(sed -n 's/^EXEC_LANE_MEASURED_UNRESOLVED=//p' "$MEAS_OUT" | tail -1)
case "$NMEAS_UNRES" in ''|*[!0-9]*)
  echo "EXEC_LANE=ERROR measured-leg-no-count" >&2; cat "$MEAS_OUT"; rm -f "$INV" "$HELP" "$MEAS_OUT"; exit 1 ;;
esac

if [ "$MODE" = "list" ]; then
  sort -t$'\t' -k1,1 "$INV" | awk -F'\t' '{gsub(/\x1e/," ⏎ ",$7); printf "%-17s gat=%s %-13s %-28s %s\n",$1,$2,$5,$6,$7}'
  echo; echo "== MEASURED figures in reports/TR*.md (window resolution, not executed) =="
  cat "$MEAS_OUT"
  echo "EXEC_LANE_EXTRACTED=$N_EXTRACTED"; echo "EXEC_LANE_SCOPE=LIST-ONLY"
  rm -f "$INV" "$HELP" "$MEAS_OUT"; exit 0
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
NFRAG=0; NFRAGU=0
FRAG_LINES=""

# Codex v2 adjudication row 27 / batch P77, PROVEN BY EXECUTION against a scratch tree: the
# SKIP-FRAGMENT exemption below is what actually swallowed `solve --f1-exact-c1c2`, the command
# published as THE reproduction path for 4.29341%. It is extracted, classed RUN, gating, EXECUTED,
# exits 2 with "Usage: solve --f1-exact-c1c2 --f1-mod P ..." -- and the lane printed
# SKIP-FRAGMENT, EXEC_LANE=PASS, exit 0. (The adjudication and the gate-designation pass both
# attributed this to SKIP-PLACEHOLDER; measured, that class never sees the command.)
#
# The exemption cannot simply be deleted. Measured on the tracked corpus, 204 inline-origin RUN
# commands have no longer runnable form published, and at least one of them --
# `gcc -Wconversion -Wsign-conversion` (reports/TR11:366) -- is a genuine prose mention of two
# compiler flags that would become a false FAIL. There is no mechanical way inside the lane to
# separate "prose mention of a flag" from "published-but-broken invocation".
#
# So: the exemption stays a SKIP (the lane's three-outcome doctrine), but it stops being INVISIBLE.
# Every fragment is now listed with its source and counted in its own whole-line token, and the
# subset with no complete form published anywhere in the corpus -- the suspicious set, which is
# where row 27's defect sat -- is counted separately. EXEC_LANE_STRICT_FRAGMENT=1 promotes that
# subset (gating sources only) to FAIL, so the operator can run the measurement the default
# cannot afford to assume.
STRICT_FRAG="${EXEC_LANE_STRICT_FRAGMENT:-0}"
NUNDOC=0; NDIFFU=0; NBLDMISS=0
DIFF_LINES=""

# THREE EXEMPTIONS CLOSED 2026-09-02 (FINDING_FAILOPEN_CLASS instances 43-44's "three more in
# the same if/elif chain — REPORTED, NOT FIXED"). Each swallowed exactly the class of defect the
# lane exists to surface:
#   (i)   `ModuleNotFoundError` -> SKIP-MISSING-TOOL excused a documented command with an unmet
#         third-party dependency, while the lane's own doctrine ("a refusal whose prerequisite
#         the doc does NOT state is FAIL") was applied to `ulimit` and to nothing else. Now the
#         source doc must NAME the module (word match in the doc the command came from) for the
#         skip to be granted; otherwise FAIL(undocumented dependency).
#   (ii)  `diff`/`cmp` exit 1 -> PASS reported inputs that DIFFER as a documented result. For a
#         doc that says "these must be identical" that is backwards. The +-3-line context of the
#         source site now decides: identical/empty wording -> FAIL; "differ" wording -> PASS;
#         nothing stated -> SKIP-DIFF-UNSTATED, listed and counted (EXEC_LANE_DIFF_UNSTATED).
#   (iii) "No such file or directory" -> SKIP-MISSING-INPUT caught a BUILD line failing on a
#         missing source or header — a published compile recipe the tree cannot satisfy. For
#         BUILD that is now FAIL; RUN keeps the skip (the command names an input the tree does
#         not ship, which is a different, already-listed class).
# Blast radius of each is published as a whole-line token, measured by a full lane run rather
# than assumed.
doc_context() {   # $1 = "file:line;file:line" -> the +-3 lines around each source site
  local s f ln
  for s in ${1//;/ }; do
    f="${s%%:*}"; ln="${s##*:}"
    [ -f "$ROOT/$f" ] || continue
    case "$ln" in ''|*[!0-9]*) continue ;; esac
    sed -n "$(( ln > 3 ? ln - 3 : 1 )),$(( ln + 3 ))p" "$ROOT/$f"
  done
}
doc_states_prereq() {   # $1 = sources, $2 = name; true iff SOME source doc names it (whole word)
  # OUTSIDE any command: backtick spans and fenced blocks are stripped first. Measured on the
  # first red test of this function: `python3 -c "import nosuchmod_zz"` was judged "documented"
  # because the module's name appears in the doc — inside the very command that failed. A
  # prerequisite is stated in prose or it is not stated.
  local s f
  for s in ${1//;/ }; do
    f="${s%%:*}"
    [ -f "$ROOT/$f" ] || continue
    awk '/^[[:space:]]*```/ { inf = !inf; next } !inf { print }' "$ROOT/$f" \
      | sed -E 's/`[^`]*`//g' | grep -qiw -- "$2" && return 0
  done
  return 1
}

corpus_publishes_complete_form() {   # $1 = command; true iff the inventory holds a STRICTLY
  C="$1" awk -F'\t' '               # longer RUN/BUILD form of it (a runnable complete form --
    function norm(x) { sub(/^\.\//, "", x); return x }   # a SKIP-PLACEHOLDER synopsis such as
    BEGIN { c = norm(ENVIRON["C"]); n = length(c) + 1 }    # `... --f1-mod P` does NOT count)
    ($1 == "RUN" || $1 == "BUILD") {
      f = norm($7)
      if (length(f) > n && substr(f, 1, n) == c " ") { found = 1; exit }
    }
    END { exit found ? 0 : 1 }
  ' "$INV"
}

doc_says_fails() {   # $1 = sources, $2 = command; true iff a source LINE (joined with the line
  # after it -- the verb is often hard-wrapped) quotes the command and says, right after the
  # closing backtick, that it fails. Measured 2026-09-02: SOLVE_C_CLI.md:2061 quotes the
  # pre-correction build line `gcc -O0 -fopenmp -o solve solve.c -lm -lpthread` and line 2062
  # begins "fails with 13 undefined references" -- a correction note DOCUMENTING the defect it
  # withdrew, and the lane reported the quote as a live FAIL. Counting cannot tell a defect from
  # its own correction; the verb after the backtick can. A quoted defect is then held the other
  # way round: it must STILL fail -- if it exits 0 the correction note is stale, and that is the
  # FAIL. Fenced blocks cannot carry a same-line verb, so pure-fence origins never reach here.
  local s f ln line
  for s in ${1//;/ }; do
    f="${s%%:*}"; ln="${s##*:}"
    [ -f "$ROOT/$f" ] || continue
    case "$ln" in ''|*[!0-9]*) continue ;; esac
    line="$(sed -n "${ln},$(( ln + 1 ))p" "$ROOT/$f" | tr '\n' ' ')"
    CMD="$2" LINE="$line" python3 - <<'PY' && return 0
import os, re, sys
cmd, line = os.environ['CMD'], os.environ['LINE']
# Present-tense claims about the command only. "failed"/"did not" narrate a past run over some
# input (CRITIQUE.md:105 "`gzip -t` failed with ..." is a story about four truncated files, not
# a claim that `gzip -t` fails) and are deliberately NOT here.
VERB = (r'\s*(fails\b|fails to\b|(does|will|would) not (link|compile|build|run|work)\b'
        r'|cannot (link|compile|build|run)\b|would fail\b|is (broken|rejected|refused)\b'
        r'|exits (with )?(nonzero|non-zero|rc ?[1-9]|[1-9]\b)|dies with\b|errors out\b'
        r'|no longer (links|compiles|runs)\b|is not (a |an )?(dispatched|recogni[sz]ed|accepted|implemented|subcommand|mode|flag|option)\b'
        r'|does not exist\b)')   # "is not dispatched" / "is not a subcommand": SOLVE_C_CLI.md:522, LARGE_SCALE_CAMPAIGNS.md:1031
norm = lambda x: re.sub(r'\s+', ' ', x).strip()
for m in re.finditer(r'`([^`]+)`', line):
    if norm(m.group(1)) == norm(cmd) and re.match(VERB, line[m.end():m.end()+48]):
        sys.exit(0)
sys.exit(1)
PY
  done
  return 1
}
last_stage_tok() {  # first token of the LAST pipeline stage, quoted spans blanked first. A
  # pipeline's exit status is its last command's, so `env | grep -c '^SOLVE_'` exiting 1 is
  # grep's documented no-match exactly as a bare `grep` is. Measured 2026-09-02: three published
  # sites whose doc says the count is 0 (SOLUTIONS_FORMAT.md:405, SOLVE_C_CLI.md:365/1840) were
  # reported FAIL(rc=1) because the grep-family rule looked only at the first token, `env`.
  local s; s="$(sed -E "s/'[^']*'/Q/g; s/\"[^\"]*\"/Q/g" <<<"$1")"
  s="${s##*|}"; s="${s#"${s%%[![:space:]]*}"}"
  printf '%s\n' "${s%% *}"
}

run_one() {  # $1=class $2=gating $3=ctx $4=cwd $5=origins $6=sources $7=command
  local cls="$1" gat="$2" ctx="$3" cwd="$4" org="$5" src="$6" cmd="$7"
  local budget="$BUDGET"; [ "$cls" = "BUILD" ] && budget="$BUILD_BUDGET"
  IDX=$((IDX+1))
  local log="$LOGDIR/$(printf '%03d' "$IDX").log"
  # A multi-line quoted program travels through the inventory with its newlines as \x1e (one TSV
  # row per command); restore them for execution and show them as a visible mark in reports.
  local execmd="${cmd//$'\x1e'/$'\n'}" show="${cmd//$'\x1e'/ ⏎ }"
  local asdoc="$execmd"   # the command AS THE DOC WROTE IT -- before the ./ prefix below, which is
                          # what the documented-failure lookup must match (measured 2026-09-02:
                          # `solve --extended-selftest` vs the doc's span, missed on the first run)
  case "$execmd" in solve\ *|solve) execmd="./$execmd" ;; verify\ *|verify) execmd="./$execmd" ;; esac
  # A failed link UNLINKS its output (ld's default). Measured 2026-09-02 on the full lane: BUILD
  # `gcc -O0 -fopenmp -o solve solve.c -lm -lpthread` (SOLVE_C_CLI.md:2061, a quoted pre-fix line)
  # failed as documented and took the `solve` that BUILD 17 had just built with it; 167 RUN
  # commands then reported SKIP-MISSING-INPUT and `./solve --selftest` never ran. Keep the
  # previous output of a build line's `-o` target and put it back if the failed build removed it.
  local bout="" bkeep="" restored=""
  if [ "$cls" = "BUILD" ]; then
    bout="$(grep -oE -- '(^| )-o +[^ ]+' <<<"$execmd" | head -1 | sed -E 's/^ ?-o +//')"
    if [ -n "$bout" ] && [ -f "$WS/$cwd/$bout" ]; then bkeep="$LOGDIR/keep.$IDX"; cp -p "$WS/$cwd/$bout" "$bkeep"; fi
  fi
  { echo "# src: $src"; echo "# cwd: $cwd  origins: $org  gating: $gat"; echo "# cmd: $show"; } > "$log"
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
  if [ -n "$bkeep" ] && [ $rc -ne 0 ] && [ ! -e "$WS/$cwd/$bout" ]; then
    cp -p "$bkeep" "$WS/$cwd/$bout"
    restored=" [restored $bout: the failed link unlinked it; the previous successful build is kept for the RUN phase]"
  fi
  [ -n "$bkeep" ] && rm -f "$bkeep"
  local out; out="$(tail -c 4000 "$log")"
  local ref; ref=$(grep -oE "see /[^ )]+\.log" <<<"$out" | head -1 | cut -d" " -f2)
  if [ -n "$ref" ] && [ -f "$ref" ]; then out="$out
$(tail -c 2000 "$ref")"; fi
  local outcome="" docfail=0 lst
  lst="$(last_stage_tok "$execmd")"
  if [ "$org" != "fence" ] && doc_says_fails "$src" "$asdoc"; then docfail=1; fi
  if   [ $docfail -eq 1 ] && [ $rc -ne 0 ]; then outcome="PASS(fails as the source line says it does — a quoted, withdrawn defect, rc=$rc)"
  elif [ $docfail -eq 1 ]; then outcome="FAIL(the source line says this command fails, but it exited 0 — the correction note is stale)"
  elif [ $rc -eq 0 ];   then outcome="PASS"
  elif [ $rc -eq 1 ] && grep -qxE 'grep|egrep|fgrep|pgrep' <<<"$lst" && ! grep -qiE "error|usage" <<<"$out"; then
    outcome="PASS(exit 1 = no-match — documented result, not an error)"
  elif [ $rc -eq 1 ] && grep -qxE 'diff|cmp' <<<"$lst" && ! grep -qiE "error|usage|no such file" <<<"$out"; then
    local dctx; dctx="$(doc_context "$src")"
    if grep -qiE "identical|byte-for-byte|byte-exact|no output|empty|no difference|should match|must match|same bytes|no diff|exits? 0|exit status 0|prints nothing" <<<"$dctx"; then
      outcome="FAIL(diff/cmp exit 1 = the inputs DIFFER, and the source doc says they must be identical)"
    elif grep -qiE "differ|delta|what changed|the change" <<<"$dctx"; then
      outcome="PASS(exit 1 = differs — the source doc states the inputs differ)"
    else
      outcome="SKIP-DIFF-UNSTATED(diff/cmp exit 1 = differs; the source doc states no expected outcome)"
      NDIFFU=$((NDIFFU+1))
      DIFF_LINES="$DIFF_LINES  $src  $show"$'\n'
    fi
  elif [ $rc -eq 139 ] || grep -q "Segmentation fault" <<<"$out"; then outcome="FAIL(SIGSEGV)"
  elif [ $rc -eq 124 ]; then outcome="SKIP-BUDGET(>${budget}s, killed — expensive, no verdict)"
  elif [ $rc -eq 137 ]; then
    if grep -qiE "out of memory|cannot allocate|bad_alloc|oom" <<<"$out"
    then outcome="SKIP-RESOURCE(SIGKILL+alloc msg — host, not claim)"
    else outcome="SKIP-BUDGET(SIGKILL at ${budget}s — expensive or OOM, no verdict)"; fi
  elif [ $rc -eq 127 ]; then
    if grep -qi "no such file" <<<"$out"; then
      if [ "$cls" = "BUILD" ]; then
        outcome="FAIL(build: a source/header/tool the compile line names does not exist)"; NBLDMISS=$((NBLDMISS+1))
      else outcome="SKIP-MISSING-INPUT"; fi
    else outcome="SKIP-MISSING-TOOL"; fi
  elif grep -qE "ModuleNotFoundError|No module named" <<<"$out"; then
    local mod; mod="$(grep -oE "No module named '?[A-Za-z0-9_.]+" <<<"$out" | head -1 | sed -E "s/^No module named '?//; s/\..*$//")"
    if [ -n "$mod" ] && doc_states_prereq "$src" "$mod"; then
      outcome="SKIP-MISSING-TOOL(python module '$mod' absent on this host; the source doc names it)"
    else
      outcome="FAIL(undocumented dependency: python module '${mod:-?}' is required and the source doc never names it)"
      NUNDOC=$((NUNDOC+1))
    fi
  elif grep -qE "command not found|not found on PATH" <<<"$out"; then
    outcome="SKIP-MISSING-TOOL"
  elif grep -q "ulimit" <<<"$out"; then
    if [ "$ctx" = "1" ]; then outcome="PASS(refused-as-documented: names a prereq the doc states)"
    else outcome="FAIL(refusal names a prereq the source doc does NOT state)"; fi
  elif grep -qiE "failed to allocate|cannot allocate|out of memory|bad_alloc|alloc.{0,16}fail|free disk in cwd|No space left on device" <<<"$out"; then
    outcome="SKIP-RESOURCE(allocation/disk failure — host, not claim)"
  elif grep -qiE "no such file|cannot open|cannot read|\[Errno 2\]|no .* files found" <<<"$out"; then
    # case-insensitive since 2026-09-02: `python3 sat.py --decode model.txt plain` (SAT_CLI.md:221)
    # says "--decode 'model.txt': no such file" -- lowercase, no "or directory" -- and was FAIL(rc=1)
    if [ "$cls" = "BUILD" ]; then
      outcome="FAIL(build cannot find a source or header its compile line names — the tree does not ship what the recipe compiles)"
      NBLDMISS=$((NBLDMISS+1))
    else outcome="SKIP-MISSING-INPUT"; fi
  # Usage-error shapes, each measured on a real published fragment. Added 2026-09-02: git's
  # "switch `S' requires a value" (`git log -S`, CORRECTIONS.md:3164, rc 129), "--follow requires
  # exactly one pathspec" (`git log --follow`, CORRECTIONS.md:4969, rc 128) and sha256sum's "no
  # properly formatted ... checksum lines found" (`sha256sum -c`, CORRECTIONS.md:2365, rc 1) --
  # four inline prose mentions reported FAIL because their usage text matched no shape here.
  elif [ "$org" = "inline" ] && grep -qiE "usage|requires an argument|requires a value|requires exactly one|missing operand|no input file|invalid|unexpected end of file|stdin|no makefile found|No rule to make target|no matching criteria|no properly formatted|arguments are required|too few arguments|Try '" <<<"$out"; then
    if corpus_publishes_complete_form "$cmd"; then
      outcome="SKIP-FRAGMENT(inline mention; the corpus publishes a complete form)"
      NFRAG=$((NFRAG+1))
      FRAG_LINES="$FRAG_LINES  justified   $src  $show"$'\n'
    elif [ "$STRICT_FRAG" = "1" ] && [ "$gat" = "1" ]; then
      outcome="FAIL(incomplete invocation — the corpus publishes no complete form of this command)"
      NFRAG=$((NFRAG+1)); NFRAGU=$((NFRAGU+1))
      FRAG_LINES="$FRAG_LINES  UNJUSTIFIED $src  $show"$'\n'
    else
      outcome="SKIP-FRAGMENT(inline mention; NO complete form published — see UNJUSTIFIED below)"
      NFRAG=$((NFRAG+1))
      # NOT `[ ... ] && NFRAGU=...` as the branch's last statement: that leaves run_one
      # returning 1 for every non-gating fragment, which is a landmine for any future caller
      # that checks its status.
      if [ "$gat" = "1" ]; then NFRAGU=$((NFRAGU+1)); fi
      FRAG_LINES="$FRAG_LINES  UNJUSTIFIED $src  $show"$'\n'
    fi
  else outcome="FAIL(rc=$rc)"; fi
  git -C "$WS" checkout -q -- . 2>/dev/null
  git -C "$WS" clean -fdqx -e solve -e verify >/dev/null 2>&1
  outcome="$outcome$restored"
  case "$outcome" in
    PASS*) NP=$((NP+1));;
    FAIL*) if [ "$gat" = "1" ]; then NF=$((NF+1)); else outcome="$outcome[NONGATING]"; NFN=$((NFN+1)); fi
           FAIL_LINES="$FAIL_LINES$outcome  $src  $show"$'\n';;
    SKIP-RESOURCE*) NR=$((NR+1));;
    *) NS=$((NS+1));;
  esac
  printf '%-4s %-52s %3ss  %s\n     src: %s\n' "$IDX." "$outcome" "$dt" "$show" "$src"
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

echo
echo "== MEASURED figures in reports/TR*.md (each must resolve to a RUN/BUILD command in its window) =="
cat "$MEAS_OUT"
# An unresolved MEASURED figure is a gating FAIL: the TR's own header promised the command.
if [ "$NMEAS_UNRES" -gt 0 ]; then
  NF=$((NF+NMEAS_UNRES))
  FAIL_LINES="$FAIL_LINES$(grep '^MEASURED-UNRESOLVED' "$MEAS_OUT" | sed 's/^/FAIL(MEASURED figure resolves to no runnable command)  /')"$'\n'
fi

# ---------------------------------------------------------------- 4. VERDICT
echo
echo "== SUMMARY =="
[ -n "$FAIL_LINES" ] && { echo "FAILURES:"; printf '%s' "$FAIL_LINES"; echo; }
[ -n "$DIFF_LINES" ] && {
  echo "DIFF/CMP RESULTS THE DOCS DO NOT INTERPRET (skips, not verdicts — the command exited 1 = the"
  echo "inputs differ, and nothing within +-3 lines of the source site says whether that is expected):"
  printf '%s' "$DIFF_LINES"; echo
}
# A skip is not a verdict, but an INVISIBLE skip reads as coverage. Row 27's defect lived here.
[ -n "$FRAG_LINES" ] && {
  echo "INCOMPLETE PUBLISHED INVOCATIONS (skips, not verdicts — commands the docs publish that"
  echo "did not run; UNJUSTIFIED = the corpus publishes no complete form anywhere, so the only"
  echo "invocation a reader has is this one. Re-run with EXEC_LANE_STRICT_FRAGMENT=1 to gate them):"
  printf '%s' "$FRAG_LINES"; echo
}
echo "EXEC_LANE_EXTRACTED=$N_EXTRACTED"
echo "EXEC_LANE_RUN=$IDX"
echo "EXEC_LANE_PASS=$NP"
echo "EXEC_LANE_FAIL=$NF"
echo "EXEC_LANE_FAIL_NONGATING=$NFN"
echo "EXEC_LANE_SKIP=$((NS+NR))"
echo "EXEC_LANE_FRAGMENT=$NFRAG"
echo "EXEC_LANE_FRAGMENT_UNJUSTIFIED=$NFRAGU"
echo "EXEC_LANE_UNDOC_DEP=$NUNDOC"
echo "EXEC_LANE_DIFF_UNSTATED=$NDIFFU"
echo "EXEC_LANE_BUILD_MISSING_SOURCE=$NBLDMISS"
grep '^EXEC_LANE_MEASURED_' "$MEAS_OUT"
if [ -n "$ONLY" ]; then echo "EXEC_LANE_SCOPE=PARTIAL"; else echo "EXEC_LANE_SCOPE=FULL"; fi
if [ "${EXEC_LANE_KEEP:-0}" != "1" ]; then rm -rf "$WS"; else echo "workspace kept: $WS"; fi
rm -f "$INV" "$HELP" "$MEAS_OUT"
if [ "$NF" -gt 0 ]; then echo "EXEC_LANE=FAIL"; exit 1; else echo "EXEC_LANE=PASS"; exit 0; fi
