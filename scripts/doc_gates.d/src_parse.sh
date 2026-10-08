#@ scripts/doc_gates.d/src_parse.sh -- sourced by scripts/doc_gates.sh; not runnable on its own. It defines
#@ _sp_prelude and nothing else. (row_assertion_gate.sh reads bash's canonical form with its own copy of that step.)
# ---------------------------------------------------------------------------------------------
# THE SHARED SOURCE READER (Q-970, batch 41; R6 of the Q-962 adjudication of the Q-835 Codex lens-A
# review). It sits next to md_normalise.sh (what text a prose leg reads) and word_match.sh (whether a
# word is in it); this one decides what a piece of SOURCE CODE says.
#
# WHY. The source-code analysers recognised ONE spelling of each construct. Measured on 35782834 (33
# findings, the R6 table of review_2026_09_27/Q962_ADJUDICATION_REPORT.md), every one an rc 0: a shell
# function whose `{` is on the next line, a renamed copy variable, a half-anchored ERE, Python `re`
# reading a POSIX ERE, a concatenated shell word, a trailing `# comment`, a `)` inside a string,
# `getenv ( "X" )`, `add_argument("-z", "--x")`, `import os, numpy`, an inline `if ...; then echo`,
# a quoted value or a `\` continuation in a documented command, `{a,b}_{1,2}`, a titled link, an
# `if False:` branch. Each analyser now reads through a parser rather than a pattern where one exists:
# bash itself (`bash -n`, and `declare -f` for the canonical form), python `ast`/`tokenize`, grep -E
# for ERE semantics, and the small lexers below where no parser is at hand.
#
# WHAT IT PROVIDES. _sp_prelude prints python, used like _wm_prelude (all names start sp_):
#   SpError                      raised on anything the reader cannot complete; the caller FAILS.
#   sp_sh_check(text, name)      `bash -n` (extglob on) over the text; SpError on any diagnostic.
#   sp_sh_canon(text, name)      bash's OWN canonical form of the text (`declare -f` of a wrapper
#                                function, after sp_sh_check proves the text parses on its own, so
#                                the wrapper cannot close early and nothing in the text runs):
#                                comments gone, continuations joined, one statement per line, every
#                                function definition printed as `function NAME () `.
#   sp_sh_lex(text)              a shell lexer: quotes ('..', "..", $'..'), backslash escapes and
#                                line continuations, $(..)/`..`/${..}/<(..) expansions, comments,
#                                operators, and HERE-DOCUMENTS (their bodies are not code). Returns
#                                tokens (kind, value, line): kind 'word' (value = SpWord), 'op',
#                                'nl', 'heredoc' (value = (delim, body, first body line)).
#   SpWord                       .raw (source text), .parts [(text, 'lit'|'exp')], .value (the
#                                literal text with each expansion kept as written), .quoted.
#   sp_sh_commands(text, sub=True)
#                                every SIMPLE COMMAND: (line, [SpWord...]) with assignments,
#                                redirections and reserved words removed; with sub=True the commands
#                                inside $(..), `..`, <(..) and >(..) are returned too.
#   sp_sh_funcdefs(text)         {name: line} for all three spellings (`f() {`, `f ()\n{`, `function f`).
#   sp_sh_split(s)               a QUOTE-AWARE split of one documented command line into
#                                (value, quoted) pairs; an unterminated quote ends the split there.
#   sp_ere_branches(ere)         the top-level alternatives of a POSIX ERE (SpError if unbalanced).
#   sp_grep_E(ere, lines)        the lines grep -E matches -- the dialect the assertion helpers
#                                run; SpError if grep cannot compile it.
#   sp_brace_expand(s, cap=4096) bash brace expansion: every group, nested groups, {a..b} ranges.
#   sp_md_links(text)            markdown link targets: inline links with or without a title, and
#                                reference definitions; [(offset, target)].
#   sp_py_truth(expr)            True / False / None: the static truth of an `if`/`while` test.
#   sp_py_dead(tree)             ids of the ast nodes no execution can reach: the body of an
#                                `if <false>:`/`while <false>:`, the else of an `if <true>:`, and
#                                statements after a return/raise/continue/break in the same block.
#
# WHAT IT DOES NOT DO, stated so a clear is not read as more: sp_sh_lex is not a shell grammar --
# it does not know `case` patterns or `[[ ... ]]` operands (a `<` there reads as a redirection), and
# its $(..) scan counts parentheses outside quotes (a `case` arm inside $(..) unbalances it, and
# that raises SpError, never a quiet misread). sp_py_dead reads constants only: `if DEBUG:` with a
# module-level DEBUG = False is live to it. sp_md_links does not resolve nested brackets in link
# text or HTML anchors.
# ---------------------------------------------------------------------------------------------
_sp_prelude() {
cat <<'SP_PY'
import ast as _sast, os as _sos, re as _sre, subprocess as _ssub, tempfile as _stmp
class SpError(Exception):
    pass

def sp_sh_check(text, name='<source>'):
    with _stmp.NamedTemporaryFile('w', suffix='.sh', delete=False, encoding='utf-8') as fh:
        fh.write(text if text.endswith('\n') else text + '\n'); p = fh.name
    try:
        r = _ssub.run(['bash', '--norc', '--noprofile', '-O', 'extglob', '-n', p], capture_output=True,
                      text=True, timeout=120, env={'PATH': _sos.environ.get('PATH', '/usr/bin:/bin'), 'LC_ALL': 'C'})
    finally:
        _sos.unlink(p)
    if r.returncode != 0 or r.stderr.strip():
        raise SpError('%s: bash -n rejects it: %s' % (name, (r.stderr.strip().splitlines() or ['rc %d' % r.returncode])[0]))

def sp_sh_canon(text, name='<source>'):
    sp_sh_check(text, name)
    with _stmp.NamedTemporaryFile('w', suffix='.sh', delete=False, encoding='utf-8') as fh:
        fh.write('__sp_canon_w() {\n%s\n}\ndeclare -f __sp_canon_w\n' % text.rstrip('\n')); p = fh.name
    try:
        r = _ssub.run(['bash', '--norc', '--noprofile', '-O', 'extglob', p], capture_output=True, text=True,
                      timeout=120, env={'PATH': _sos.environ.get('PATH', '/usr/bin:/bin'), 'LC_ALL': 'C'})
    finally:
        _sos.unlink(p)
    L = r.stdout.split('\n')
    if r.returncode != 0 or r.stderr.strip() or len(L) < 3 or not L[0].startswith('__sp_canon_w ()'):
        raise SpError('%s: bash could not print its canonical form: %s' % (name, r.stderr.strip()[:200]))
    while L and L[-1] == '':
        L.pop()
    if L[-1] != '}':
        raise SpError('%s: the canonical form does not close' % name)
    return '\n'.join(l[4:] if l.startswith('    ') else l for l in L[2:-1]) + '\n'

class SpWord(object):
    __slots__ = ('raw', 'parts', 'quoted')
    def __init__(self):
        self.raw, self.parts, self.quoted = '', [], False
    @property
    def value(self):
        return ''.join(t for t, _ in self.parts)
    def lit(self):
        return all(k == 'lit' for _, k in self.parts)
    def __repr__(self):
        return 'SpWord(%r)' % self.value

_SP_OPS = sorted(['&&', '||', ';;&', ';;', ';&', '|&', '>>', '<<<', '<<-', '<<', '&>>', '&>', '>&', '<&',
                  '<>', '>|', ';', '&', '|', '(', ')', '<', '>'], key=len, reverse=True)
_SP_ESC = {'n': '\n', 't': '\t', 'r': '\r', 'a': '\a', 'b': '\b', 'e': '\x1b', 'f': '\f', 'v': '\v',
           '\\': '\\', "'": "'", '"': '"', '?': '?'}

_SP_HD = _sre.compile(r"""[ \t]*(['"]?)([^\s'"<>|&;()]+)\1""")

def _sp_balanced(s, i, op, cl):
    # s[i] is just past the opener; returns the index just past the matching closer. Inside $(..)
    # it reads what bash reads: quotes, nested expansions, comments, here-documents (their bodies
    # are skipped whole) and `case` arms (a pattern's `)` closes nothing).
    depth, n, case_d, hds, at_word = 1, len(s), 0, [], True
    while i < n:
        c = s[i]
        if c == '\n':
            i += 1
            for delim, strip in hds:
                while True:
                    if i >= n:
                        raise SpError('here-document %r inside an expansion has no terminator' % delim)
                    j = s.find('\n', i)
                    j = n if j < 0 else j
                    ln = s[i:j]
                    i = j + 1 if j < n else n
                    if (ln.lstrip('\t') if strip else ln) == delim:
                        break
            hds, at_word = [], True
            continue
        if c in ' \t;|&':
            at_word = True; i += 1; continue
        if c == '\\':
            i += 2; at_word = False; continue
        if c == '#' and at_word and op == '(':
            j = s.find('\n', i)
            i = n if j < 0 else j
            continue
        if c == "'":
            j = s.find("'", i + 1)
            if j < 0:
                raise SpError('unterminated single quote inside an expansion')
            i = j + 1; at_word = False; continue
        if c == '"':
            i = _sp_dq_end(s, i + 1) + 1; at_word = False; continue
        if c == '$' and s[i + 1:i + 2] in ('(', '{'):
            i = _sp_balanced(s, i + 2, s[i + 1], ')' if s[i + 1] == '(' else '}'); at_word = False; continue
        if c == '`':
            j = i + 1
            while j < n and s[j] != '`':
                j += 2 if s[j] == '\\' else 1
            if j >= n:
                raise SpError('unterminated backquote inside an expansion')
            i = j + 1; at_word = False; continue
        if op == '(' and s.startswith('<<', i) and not s.startswith('<<<', i):
            j, strip = i + 2, False
            if s[j:j + 1] == '-':
                strip, j = True, j + 1
            m = _SP_HD.match(s, j)
            if m:
                hds.append((m.group(2), strip)); i = m.end(); at_word = False; continue
        if op == '(' and at_word:
            m = _sre.match(r'(case|esac)(?![A-Za-z0-9_])', s[i:i + 5])
            if m:
                case_d += 1 if m.group(1) == 'case' else -1
                i += 4; at_word = False; continue
        if c == op:
            depth += 1
        elif c == cl:
            if not (op == '(' and case_d > 0 and depth == 1):
                depth -= 1
                if depth == 0:
                    return i + 1
        at_word = c in '(){}'
        i += 1
    raise SpError('unbalanced %s...%s expansion' % (op, cl))

def _sp_dq_end(s, i):
    n = len(s)
    while i < n:
        c = s[i]
        if c == '\\':
            i += 2; continue
        if c == '"':
            return i
        if c == '$' and s[i + 1:i + 2] == '(':
            i = _sp_balanced(s, i + 2, '(', ')'); continue
        if c == '$' and s[i + 1:i + 2] == '{':
            i = _sp_balanced(s, i + 2, '{', '}'); continue
        if c == '`':
            j = i + 1
            while j < n and s[j] != '`':
                j += 2 if s[j] == '\\' else 1
            if j >= n:
                raise SpError('unterminated backquote')
            i = j + 1; continue
        i += 1
    raise SpError('unterminated double quote')

def _sp_expansion(s, i):
    # s[i] == '$'; returns end index of the expansion starting at i (or i+1 for a lone '$').
    nx = s[i + 1:i + 2]
    if nx == '(':
        return _sp_balanced(s, i + 2, '(', ')')
    if nx == '{':
        return _sp_balanced(s, i + 2, '{', '}')
    m = _sre.match(r'[A-Za-z_][A-Za-z0-9_]*|[0-9@*#?$!-]', s[i + 1:])
    return i + 1 + (m.end() if m else 0)

def sp_sh_lex(text):
    toks, s, n = [], text, len(text)
    i, line = 0, 1
    cur, cur_line, cur_start = None, 1, 0
    pending = []        # heredocs opened on this line: [delim, strip_tabs, op_index]
    want_delim = None

    def flush():
        nonlocal cur, want_delim
        if cur is not None:
            cur.raw = s[cur_start:i]
            if want_delim is not None:
                pending.append((cur.value, want_delim))
                want_delim = None
            toks.append(('word', cur, cur_line))
            cur = None

    def add(text_, kind):
        nonlocal cur, cur_line, cur_start
        if cur is None:
            cur = SpWord(); cur_line = line; cur_start = i
        if kind == 'lit' and cur.parts and cur.parts[-1][1] == 'lit':
            cur.parts[-1] = (cur.parts[-1][0] + text_, 'lit')
        else:
            cur.parts.append((text_, kind))

    while i < n:
        c = s[i]
        if c == '\n':
            flush()
            toks.append(('nl', '\n', line))
            line += 1; i += 1
            for delim, strip in pending:
                body, first = [], line
                while True:
                    if i >= n:
                        raise SpError('here-document %r has no terminator (opened before line %d)' % (delim, first))
                    j = s.find('\n', i)
                    j = n if j < 0 else j
                    ln = s[i:j]
                    i = j + 1 if j < n else n
                    line += 1
                    if (ln.lstrip('\t') if strip else ln) == delim:
                        break
                    body.append(ln)
                toks.append(('heredoc', (delim, '\n'.join(body) + ('\n' if body else ''), first), first))
            pending = []
            continue
        if c in ' \t':
            flush(); i += 1; continue
        if c == '#' and cur is None:
            j = s.find('\n', i)
            i = n if j < 0 else j
            continue
        if c == '\\':
            if s[i + 1:i + 2] == '\n':
                i += 2; line += 1; continue
            if cur is None:
                cur = SpWord(); cur_line = line; cur_start = i
            cur.quoted = True
            add(s[i + 1:i + 2], 'lit'); i += 2; continue
        if c == "'":
            j = s.find("'", i + 1)
            if j < 0:
                raise SpError('unterminated single quote at line %d' % line)
            if cur is None:
                cur = SpWord(); cur_line = line; cur_start = i
            cur.quoted = True
            add(s[i + 1:j], 'lit'); line += s.count('\n', i, j); i = j + 1; continue
        if c == '$' and s[i + 1:i + 2] == "'":
            j, out = i + 2, []
            while j < n and s[j] != "'":
                if s[j] == '\\' and j + 1 < n:
                    out.append(_SP_ESC.get(s[j + 1], '\\' + s[j + 1])); j += 2
                else:
                    out.append(s[j]); j += 1
            if j >= n:
                raise SpError("unterminated $'...' at line %d" % line)
            if cur is None:
                cur = SpWord(); cur_line = line; cur_start = i
            cur.quoted = True
            add(''.join(out), 'lit'); line += s.count('\n', i, j); i = j + 1; continue
        if c == '"':
            j = _sp_dq_end(s, i + 1)
            if cur is None:
                cur = SpWord(); cur_line = line; cur_start = i
            cur.quoted = True
            k = i + 1
            while k < j:
                ch = s[k]
                if ch == '\\' and s[k + 1:k + 2] in ('$', '`', '"', '\\', '\n'):
                    if s[k + 1] != '\n':
                        add(s[k + 1], 'lit')
                    k += 2; continue
                if ch == '$' and k + 1 < j and _sre.match(r'[({A-Za-z_0-9@*#?$!-]', s[k + 1]):
                    e = _sp_expansion(s, k); add(s[k:e], 'exp'); k = e; continue
                if ch == '`':
                    e = s.find('`', k + 1)
                    add(s[k:e + 1], 'exp'); k = e + 1; continue
                add(ch, 'lit'); k += 1
            line += s.count('\n', i, j); i = j + 1; continue
        if c == '$' and i + 1 < n and _sre.match(r'[({A-Za-z_0-9@*#?$!-]', s[i + 1]):
            e = _sp_expansion(s, i); add(s[i:e], 'exp'); line += s.count('\n', i, e); i = e; continue
        if c == '`':
            j = i + 1
            while j < n and s[j] != '`':
                j += 2 if s[j] == '\\' else 1
            if j >= n:
                raise SpError('unterminated backquote at line %d' % line)
            add(s[i:j + 1], 'exp'); line += s.count('\n', i, j); i = j + 1; continue
        if c in '<>' and s[i + 1:i + 2] == '(':
            e = _sp_balanced(s, i + 2, '(', ')'); add(s[i:e], 'exp'); line += s.count('\n', i, e); i = e; continue
        op = next((o for o in _SP_OPS if s.startswith(o, i)), None)
        if op == '(' and cur is not None and not cur.quoted and cur.value.endswith(('@', '?', '*', '+', '!')):
            e = _sp_balanced(s, i + 1, '(', ')'); add(s[i:e], 'lit'); i = e; continue   # an extglob pattern
        if op is not None:
            if op[0] in '<>' and cur is not None and not cur.quoted and cur.value.isdigit():
                cur = None                      # a file-descriptor number belongs to the redirection
            flush()
            toks.append(('op', op, line))
            if op in ('<<', '<<-'):
                want_delim = op == '<<-'
            i += len(op); continue
        add(c, 'lit'); i += 1
    flush()
    if pending or want_delim is not None:
        raise SpError('here-document opened on the last line has no body')
    return toks

_SP_RESERVED = {'if', 'then', 'else', 'elif', 'fi', 'do', 'done', 'while', 'until', '{', '}', '!',
                'time', 'esac', 'function', 'coproc', '[[', ']]'}
_SP_REDIR = {'<', '>', '>>', '<<<', '<<', '<<-', '&>', '&>>', '>&', '<&', '<>', '>|'}
_SP_ASSIGN = _sre.compile(r'[A-Za-z_][A-Za-z0-9_]*(?:\[[^]]*\])?\+?=')

class SpCmd(list):
    """A simple command's words; .redirs is [(operator, target SpWord or None)]."""
    redirs = ()

def sp_sh_commands(text, sub=True, _off=0):
    out, cur, cur_line, skip, drop = [], SpCmd(), 0, False, False
    cur.redirs = []
    case_in, pattern = 0, False     # inside `case ... in`; reading an arm's pattern list
    toks = sp_sh_lex(text)
    def push():
        nonlocal cur, drop
        if cur and not drop:
            out.append((cur_line + _off, cur))
        cur, drop = SpCmd(), False
        cur.redirs = []
    fdef = False                     # the word after `function` names a definition, not a command
    for ti, (kind, v, ln) in enumerate(toks):
        if kind == 'heredoc':
            continue
        if kind == 'op' and v == '(' and len(cur) == 1 and not cur[0].quoted and ti + 1 < len(toks) \
                and toks[ti + 1][:2] == ('op', ')'):
            cur, drop = SpCmd(), False     # `name ( )` is a function DEFINITION: no command ran
            cur.redirs = []
            continue
        if kind == 'op' and v == ')' and ti and toks[ti - 1][:2] == ('op', '(') and not cur:
            continue
        if fdef and kind == 'word':
            fdef = False
            continue
        if pattern:
            if kind == 'op' and v == ')':
                pattern = False
            elif kind == 'word' and not cur and not v.quoted and v.value == 'esac':
                pattern = False; case_in -= 1
            continue
        if kind in ('op', 'nl'):
            if kind == 'op' and v in _SP_REDIR:
                skip = True; cur.redirs.append((v, None)); continue
            push()
            if kind == 'op' and v in (';;', ';&', ';;&') and case_in:
                pattern = True
            continue
        if not cur and not v.quoted and v.value == 'case':
            drop = True
        if drop and cur and not v.quoted and v.value == 'in' and cur[0].value == 'case':
            cur.append(v); push(); case_in += 1; pattern = True; continue
        if not cur and not v.quoted and v.value == 'esac' and case_in:
            case_in -= 1; continue
        if sub:
            for t, k in v.parts:
                for pre in ('$(', '<(', '>('):
                    if k == 'exp' and t.startswith(pre) and not t.startswith('$(('):
                        out.extend(sp_sh_commands(t[2:-1], True, ln - 1 + _off))
                if k == 'exp' and t.startswith('`'):
                    out.extend(sp_sh_commands(t[1:-1], True, ln - 1 + _off))
        if skip:
            skip = False
            if cur.redirs:
                cur.redirs[-1] = (cur.redirs[-1][0], v)
            continue
        if not cur:
            if not v.quoted and v.value in ('for', 'select', 'case', 'in'):
                drop = True
            if not v.quoted and v.value == 'function':
                fdef = True
            if not v.quoted and v.value in _SP_RESERVED:
                continue
            if _SP_ASSIGN.match(v.raw):
                continue
            cur_line = ln
        cur.append(v)
    push()
    return out

def sp_sh_funcdefs(text):
    toks = [t for t in sp_sh_lex(text) if t[0] != 'heredoc']
    defs, n = {}, len(toks)
    def body_opens(k):
        while k < n and toks[k][0] == 'nl':
            k += 1
        return k < n and ((toks[k][0] == 'word' and toks[k][1].value == '{' and not toks[k][1].quoted)
                          or (toks[k][0] == 'op' and toks[k][1] == '('))
    for k in range(n):
        kind, v, ln = toks[k]
        if kind != 'word' or v.quoted:
            continue
        prev = toks[k - 1] if k else ('nl', '\n', 0)
        at_cmd = prev[0] == 'nl' or (prev[0] == 'op' and prev[1] in (';', '&&', '||', '&', '|', '(', ')', ';;')) \
            or (prev[0] == 'word' and not prev[1].quoted and prev[1].value in ('then', 'else', 'do', '{', '}'))
        if v.value == 'function' and at_cmd and k + 1 < n and toks[k + 1][0] == 'word':
            j = k + 2
            if j + 1 < n and toks[j][:2] == ('op', '(') and toks[j + 1][:2] == ('op', ')'):
                j += 2
            if body_opens(j):
                defs.setdefault(toks[k + 1][1].value, ln)
        elif at_cmd and _sre.fullmatch(r'[A-Za-z_][A-Za-z0-9_:.-]*', v.value) and k + 2 < n \
                and toks[k + 1][:2] == ('op', '(') and toks[k + 2][:2] == ('op', ')') and body_opens(k + 3):
            defs.setdefault(v.value, ln)
    return defs

def sp_sh_split(s):
    out, i, n = [], 0, len(s)
    while i < n:
        while i < n and s[i] in ' \t':
            i += 1
        if i >= n:
            break
        val, quoted, ok = [], False, True
        while i < n and s[i] not in ' \t':
            c = s[i]
            if c in '"\'':
                j = s.find(c, i + 1)
                if j < 0:
                    ok = False; val.append(s[i:]); i = n; break
                val.append(s[i + 1:j]); quoted = True; i = j + 1
            elif c == '\\' and i + 1 < n:
                val.append(s[i + 1]); i += 2
            else:
                val.append(c); i += 1
        out.append((''.join(val), quoted))
        if not ok:
            break
    return out

def sp_ere_branches(ere):
    out, cur, depth, i, n = [], [], 0, 0, len(ere)
    while i < n:
        c = ere[i]
        if c == '\\':
            cur.append(ere[i:i + 2]); i += 2; continue
        if c == '[':
            j = i + 1
            if ere[j:j + 1] == '^':
                j += 1
            if ere[j:j + 1] == ']':
                j += 1
            while j < n and ere[j] != ']':
                j = ere.index(']', j + 2) + 1 if ere[j:j + 2] in ('[:', '[=', '[.') and ere.find(']', j + 2) >= 0 else j + 1
            if j >= n:
                raise SpError('unterminated bracket expression in %r' % ere)
            cur.append(ere[i:j + 1]); i = j + 1; continue
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
            if depth < 0:
                raise SpError('unbalanced ) in %r' % ere)
        elif c == '|' and depth == 0:
            out.append(''.join(cur)); cur = []; i += 1; continue
        cur.append(c); i += 1
    if depth:
        raise SpError('unbalanced ( in %r' % ere)
    out.append(''.join(cur))
    return out

def sp_grep_E(ere, lines):
    r = _ssub.run(['grep', '-E', '--', ere], input='\n'.join(lines) + '\n', capture_output=True,
                  text=True)      # the caller's locale: the assertion helpers' own grep runs in it
    if r.returncode not in (0, 1):
        raise SpError('grep -E cannot use %r: %s' % (ere, r.stderr.strip()[:200]))
    return [l for l in r.stdout.split('\n') if l] if r.returncode == 0 else []

def sp_brace_expand(s, cap=4096):
    def first_group(t):
        i, n = 0, len(t)
        while i < n:
            if t[i] == '\\':
                i += 2; continue
            if t[i] == '{' and (i == 0 or t[i - 1] != '$'):
                depth, j, commas = 1, i + 1, []
                while j < n and depth:
                    if t[j] == '\\':
                        j += 2; continue
                    if t[j] == '{':
                        depth += 1
                    elif t[j] == '}':
                        depth -= 1
                    elif t[j] == ',' and depth == 1:
                        commas.append(j)
                    j += 1
                if depth == 0:
                    inner = t[i + 1:j - 1]
                    if commas:
                        alts, a = [], i + 1
                        for c in commas + [j - 1]:
                            alts.append(t[a:c]); a = c + 1
                        return i, j, alts
                    m = _sre.fullmatch(r'(-?\d+)\.\.(-?\d+)(?:\.\.(-?\d+))?|([A-Za-z])\.\.([A-Za-z])', inner)
                    if m:
                        if m.group(1) is not None:
                            a, b = int(m.group(1)), int(m.group(2)); st = abs(int(m.group(3) or 1)) or 1
                            w = max(len(m.group(1)), len(m.group(2))) if m.group(1).startswith('0') or m.group(2).startswith('0') else 0
                            rng = range(a, b + 1, st) if a <= b else range(a, b - 1, -st)
                            return i, j, [str(x).zfill(w) for x in rng]
                        a, b = ord(m.group(4)), ord(m.group(5))
                        rng = range(a, b + 1) if a <= b else range(a, b - 1, -1)
                        return i, j, [chr(x) for x in rng]
                    i += 1; continue
            i += 1
        return None
    out, work = [], [s]
    while work:
        t = work.pop()
        g = first_group(t)
        if g is None:
            out.append(t)
        else:
            a, b, alts = g
            for alt in reversed(alts):
                work.append(t[:a] + alt + t[b:])
        if len(out) + len(work) > cap:
            raise SpError('brace expansion of %r exceeds %d words' % (s[:80], cap))
    return out

_SP_LINK = _sre.compile(r'\]\(\s*(<[^<>\n]*>|[^\s()<>]*(?:\([^\s()]*\)[^\s()<>]*)*)'
                        r'(?:\s+(?:"[^"]*"|\'[^\']*\'|\([^()]*\)))?\s*\)')
_SP_REFDEF = _sre.compile(r'(?m)^ {0,3}\[[^\]\n]+\]:\s*(<[^<>\n]*>|\S+)')

def sp_md_links(text):
    out = [(m.start(), m.group(1).strip('<>')) for m in _SP_LINK.finditer(text)]
    out += [(m.start(), m.group(1).strip('<>')) for m in _SP_REFDEF.finditer(text)]
    return sorted(out)

def sp_py_truth(expr):
    try:
        return bool(_sast.literal_eval(expr))
    except Exception:
        pass
    if isinstance(expr, _sast.UnaryOp) and isinstance(expr.op, _sast.Not):
        t = sp_py_truth(expr.operand)
        return None if t is None else (not t)
    if isinstance(expr, _sast.BoolOp):
        ts = [sp_py_truth(v) for v in expr.values]
        if isinstance(expr.op, _sast.And):
            return False if False in ts else (True if all(t is True for t in ts) else None)
        return True if True in ts else (False if all(t is False for t in ts) else None)
    return None

def sp_py_dead(tree):
    dead = set()
    def kill(node):
        for x in _sast.walk(node):
            dead.add(id(x))
    def block(stmts):
        live = True
        for st in stmts:
            if not live:
                kill(st); continue
            visit(st)
            if isinstance(st, (_sast.Return, _sast.Raise, _sast.Continue, _sast.Break)):
                live = False
    def visit(node):
        if isinstance(node, (_sast.If, _sast.While)):
            t = sp_py_truth(node.test)
            if t is False:
                for st in node.body:
                    kill(st)
                block(node.orelse)
                return
            if t is True and isinstance(node, _sast.If):
                block(node.body)
                for st in node.orelse:
                    kill(st)
                return
        for f in ('body', 'orelse', 'finalbody', 'handlers'):
            v = getattr(node, f, None)
            if isinstance(v, list) and v and all(isinstance(x, (_sast.stmt, _sast.excepthandler)) for x in v):
                block(v)
        for x in _sast.iter_child_nodes(node):
            if not isinstance(x, (_sast.stmt, _sast.excepthandler)):
                visit(x)
    visit(tree)
    return dead
SP_PY
}
