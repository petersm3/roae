#@ scripts/doc_gates.d/word_match.sh -- sourced by scripts/doc_gates.sh, scripts/gate_published_consistency.sh and
#@ scripts/tr12_output_paths_gate.sh; not runnable on its own. It defines _wm_prelude and _wm_tok_ere, and nothing else.
# ---------------------------------------------------------------------------------------------
# THE SHARED WORD / TOKEN MATCHER (Q-966, batch 40; R2 of the Q-962 adjudication of the Q-835 Codex
# lens-A review). It sits next to the markdown normaliser (md_normalise.sh) and is separate from it:
# the normaliser decides WHAT TEXT a leg reads, this decides WHETHER A WORD OR TOKEN IS IN IT.
#
# WHY. The legs matched exemption words, supersession markers, ids and KEY=value pairs as
# UNBOUNDED, NEGATION-BLIND SUBSTRINGS, and read comments as code. Measured on 35782834 (28
# findings, the R2 table of review_2026_09_27/Q962_ADJUDICATION_REPORT.md), every one an rc 0:
#   "unretracted" / "uncorrected" counted as supersession markers, and "not superseded" or
#   "(not a typo)" as exemptions; "mainframe" named the frame and `dissolve --demo` was a `solve`
#   command; `base=` was an `se=` field, CX-999 was found inside CX-9990 and PICK=2 inside PICK=20;
#   UNRELATED_X documented X; a `# comment` supplied a flag or a producer, and a bare mention of
#   `cap` made a printer "cap-aware".
#
# WHAT IT PROVIDES. _wm_prelude prints python, used like _md_norm_prelude:
#     out=$( { _g1_prelude; _wm_prelude; cat <<'PY' ... PY } | python3 - ... )
#     python3 -c "$(_wm_prelude)"'...'
# All names start wm_ so they cannot shadow a leg's own.
#   wm_re(alt, flags=re.I)  compile the regex alternation `alt` as WHOLE WORDS: no word character
#                    (Unicode \w, so `_` and CJK count) on either side, and no hyphenated prefix on the
#                    left -- "non-empty" does not contain the word "empty", "un-retracted" does not
#                    contain "retracted", "unretracted" never did. A word that is part of a compound is
#                    part of a different word.
#   wm_negated(text, pos, window=3)
#                    True when the word starting at `pos` is negated in its own clause: one of the
#                    `window` words before it (never crossing . ; : ! ? ( ) [ ] | or a dash) is a
#                    negator -- not, never, no (so "no longer"), nor, neither, without, cannot, or an
#                    n't contraction.
#   wm_before(text, pos, window=3)
#                    the (lower-cased) words before `pos` in its own clause, at most `window` of them: the
#                    window wm_negated reads, for a leg that needs a different cue list (GATE 30's
#                    concessive "even with C3").
#   wm_has(text, rx, window=3)
#                    any match of the bounded regex `rx` that is NOT negated. This is the marker test:
#                    "not superseded", "has not been retracted", "never withdrawn" and "(not a typo)"
#                    are not markers; "superseded", "[RETRACTED 2026-..." and "withdrawn, not
#                    superseded" (a comma ends the negation's clause) are.
#   wm_tok_re(tok) / wm_tok(text, tok)
#                    an EXACT TOKEN: an id, a flag, a command or a KEY=value. If the token begins with a
#                    word character, none may precede it (`dissolve --demo` is not `solve --demo`,
#                    UNRELATED_X is not X, base= is not se=); if it ends with one, none may follow it
#                    and neither may a decimal fraction (CX-999 is not CX-9990, PICK=2 is not PICK=20
#                    or PICK=2.5; "PICK=2." at a sentence end still is).
#   WM_CMD_LB        the left boundary of a COMMAND token (no word character, `.` or `-` before it; `/`
#                    and `./` are allowed), for a leg that builds its own command regex: `dissolve --demo`
#                    is not a `solve` command, `xverify.py` is not verify.py.
#   wm_hex_re(lo=8, hi=64)
#                    a lower-case HEX token of lo..hi nibbles, bounded by non-alphanumerics, with at least one
#                    a-f letter: sha evidence. A decimal such as the budget 1000000000 is not a sha prefix.
#   wm_strip_comments(src, lang)   lang 'py' | 'c' | 'sh'
#                    the source with every COMMENT replaced by spaces, newlines kept, so offsets and
#                    line numbers survive. Comments are not code: a leg that asks what the code
#                    implements reads this. 'py' uses the tokenize module (exact; a file it cannot
#                    tokenize raises, and the leg fails closed). 'c' and 'sh' are small lexers that
#                    track string and character literals ('sh': `#` starts a comment only at a word
#                    start, outside quotes; a here-document body is scanned the same way, which can
#                    only REMOVE text from the code view, never add it).
# _wm_tok_ere TOKEN  (bash) prints the same exact-token rule as a POSIX ERE for grep -E.
#
# A PATTERN PASSED TO wm_re MUST END AT A WORD END: the right boundary is applied to the whole
# alternation, so `corrected\s+20` (which stops inside "2026") never matches; write `corrected\s+20\d\d`.
#
# WHAT IT DOES NOT DO. It is not a parser of English. Negation is a fixed word list in a fixed
# window of the same clause; a double negative, or a negator further back ("it is NOT a claim that
# the search space was exhausted" is 5 words), needs the caller to pass a wider window, and every
# caller that does says so. A leg that matched a stem on purpose (retract -> retracted/retraction)
# keeps that by writing the stem as `retract\w*` inside wm_re.
# ---------------------------------------------------------------------------------------------
_wm_prelude() {
cat <<'WM_PY'
import re as _wre, io as _wio, tokenize as _wtokz
_WM_NEGW = {'not', 'never', 'no', 'nor', 'neither', 'without', 'cannot', 'nothing'}
_WM_CLAUSE = _wre.compile(r'[.;:!?()\[\]|—–]|\s-\s|\s--\s')
_WM_WORD = _wre.compile(r"[^\W_]+(?:'[^\W_]+)?")

def wm_re(alt, flags=_wre.I):
    return _wre.compile(r'(?<!\w)(?<!\w-)(?:' + alt + r')(?!\w)', flags)

def wm_before(text, pos, window=3):
    head = text[:pos]
    cut = None
    for cut in _WM_CLAUSE.finditer(head):
        pass
    if cut is not None:
        head = head[cut.end():]
    return [w.lower() for w in _WM_WORD.findall(head)[-window:]] if window > 0 else []

def wm_negated(text, pos, window=3):
    return any(w in _WM_NEGW or w.endswith("n't") for w in wm_before(text, pos, window))

def wm_has(text, rx, window=3):
    for m in rx.finditer(text):
        if not wm_negated(text, m.start(), window):
            return True
    return False

def wm_tok_re(tok, flags=0):
    left = r'(?<!\w)' if _wre.match(r'\w', tok) else ''
    right = r'(?!\w)(?!\.\d)' if _wre.search(r'\w$', tok) else ''
    return _wre.compile(left + _wre.escape(tok) + right, flags)

def wm_tok(text, tok, flags=0):
    return wm_tok_re(tok, flags).search(text) is not None

WM_CMD_LB = r'(?<![\w.-])'

def wm_hex_re(lo=8, hi=64):
    return _wre.compile(r'(?<![0-9A-Za-z])(?=[0-9]*[a-f])[0-9a-f]{%d,%d}(?![0-9A-Za-z])' % (lo, hi))

def _wm_blank(s):
    return ''.join(c if c == '\n' else ' ' for c in s)

def wm_strip_comments(src, lang):
    if lang == 'py':
        out = list(src)
        lines = src.split('\n')
        offs, acc = [], 0
        for l in lines:
            offs.append(acc)
            acc += len(l) + 1
        for t in _wtokz.generate_tokens(_wio.StringIO(src).readline):
            if t.type == _wtokz.COMMENT:
                a = offs[t.start[0] - 1] + t.start[1]
                b = offs[t.end[0] - 1] + t.end[1]
                for k in range(a, b):
                    out[k] = ' '
        return ''.join(out)
    out = []
    i, n = 0, len(src)
    if lang == 'c':
        while i < n:
            c = src[i]
            if c in '"\'':
                j = i + 1
                while j < n and src[j] != c and src[j] != '\n':
                    j += 2 if src[j] == '\\' else 1
                out.append(src[i:j + 1]); i = j + 1
            elif src.startswith('//', i):
                j = src.find('\n', i)
                j = n if j < 0 else j
                out.append(_wm_blank(src[i:j])); i = j
            elif src.startswith('/*', i):
                j = src.find('*/', i + 2)
                j = n if j < 0 else j + 2
                out.append(_wm_blank(src[i:j])); i = j
            else:
                out.append(c); i += 1
        return ''.join(out)
    if lang == 'sh':
        while i < n:
            c = src[i]
            if c == '\\':
                out.append(src[i:i + 2]); i += 2
            elif c == "'":
                j = src.find("'", i + 1)
                j = n - 1 if j < 0 else j
                out.append(src[i:j + 1]); i = j + 1
            elif c == '"':
                j = i + 1
                while j < n and src[j] != '"':
                    j += 2 if src[j] == '\\' else 1
                out.append(src[i:j + 1]); i = j + 1
            elif c == '#' and (i == 0 or src[i - 1] in ' \t\n;|&('):
                j = src.find('\n', i)
                j = n if j < 0 else j
                out.append(_wm_blank(src[i:j])); i = j
            else:
                out.append(c); i += 1
        return ''.join(out)
    raise ValueError('wm_strip_comments: unknown language %r' % lang)
WM_PY
}

# _wm_tok_ere TOKEN -- the exact-token rule of wm_tok_re as a POSIX ERE (grep -E): no word character
# before a token that starts with one, and none (nor a decimal fraction) after a token that ends with
# one. Example: grep -qE "$(_wm_tok_ere "PICK=2")" FILE does not match PICK=20.
_wm_tok_ere() {
  local t=$1 e l='' r=''
  e=$(printf '%s' "$t" | sed 's/[][\.*^$+?(){}|/]/\\&/g')
  case "$t" in [[:alnum:]_]*) l='(^|[^[:alnum:]_])';; esac
  case "$t" in *[[:alnum:]_]) r='([^[:alnum:]_.]|[.]([^0-9]|$)|$)';; esac
  printf '%s%s%s' "$l" "$e" "$r"
}
