#@ scripts/doc_gates.d/md_normalise.sh -- sourced by scripts/doc_gates.sh and by scripts/tr12_output_paths_gate.sh;
#@ not runnable on its own. It defines four functions, _md_norm_prelude, fold_join, _md_num_prelude and
#@ md_num_scan (Q-968), and nothing else.
# ---------------------------------------------------------------------------------------------
# THE SHARED MARKDOWN NORMALISER (Q-965, batch 40; R1 of the Q-962 adjudication of the Q-835 Codex
# lens-A review). _md_norm_prelude prints a block of python that a prose or number leg puts in
# front of its own scanner, the way the G1 legs use _g1_prelude:
#     out=$( { _md_norm_prelude; cat <<'PY' ... PY } | python3 - ... )      # a `python3 -` leg
#     python3 -c "$(_md_norm_prelude)"'...'                                  # a `python3 -c` leg
#
# WHY. The legs scanned RAW LINES, so ordinary Markdown hid what they were looking for. Measured
# on 35782834 (30 findings, the R1 table of review_2026_09_27/Q962_ADJUDICATION_REPORT.md): the
# withdrawn "null P = 0.034", the retracted 1.4σ, "Every claim is machine-verifiable" and "24
# divides every ..." all passed once written with a hard wrap, emphasis or backticks, a table
# without edge pipes or indented one space, a setext or indented heading, a `~~~` fence or a fence
# tracked by parity, CRLF, an XML entity, curly quotes, or a `**` that ended a banner early.
#
# WHAT IT PROVIDES (all names start md_ so they cannot shadow a leg's own):
#   md_text(raw)     CRLF and lone CR -> LF.  md_read(path) reads utf-8 (errors=replace) through it;
#                    an OSError still propagates, so an unreadable file stays the caller's ERROR.
#   md_inline(s)     the INLINE fold: XML/HTML entities decoded (`&#x3c3;` -> σ), a digit group joined
#                    by a thin space or NBSP made a comma group (Q-968: "1 023" stays ONE number), curly quotes and
#                    the dash family folded to ASCII, NBSP and the other space variants to a space,
#                    backslash escapes dropped, backticks removed with their CONTENT kept, emphasis
#                    markers removed (every `*`, `~~`, and `_` at a word edge -- an `_` inside a word
#                    such as twenty_four_dvd_c1 is not emphasis and stays), whitespace collapsed.
#                    md_inline(s, fold=False) skips the quote/dash/space fold for a leg whose own
#                    patterns read those glyphs.
#   md_fold_quotes(s) the curly-quote half of that fold alone (same length, so offsets survive).
#   md_parse(text)   -> (lines, kinds, blocks, unclosed). One kind per source line:
#                    code | fence | blank | heading | setext | thead | tdelim | trow | hr | text.
#   blocks           dicts in source order, each with 'kind' (para | heading | table | code | hr),
#                    'start' (1-based line), 'end', and:
#                      para    'lines' [(lineno, raw)], 'text' (md_inline of each line, blockquote
#                              and list markers dropped, joined by one space), 'starts'/'lns' (the
#                              offset table: md_lno(block, off) is the REAL source line of offset off)
#                      heading 'level', 'title' (raw), 'text' (md_inline of the title)
#                      table   'header' (lineno, cells) or None, 'delim' (bool), 'rows' [(lineno, cells)]
#                      code    'lines' [(lineno, raw)] of the content, 'info' (the fence info string)
#   md_cells(line)   a table row's cells, with or without edge pipes; `\|` is not a cell break.
#   md_flatten(text) -> (flat, starts): the whole file, md_inline per line, joined by one space;
#                    starts[i] is the offset of source line i+1 (the _g1 flatten contract).
#   md_lno(...)      offset -> source line, for a para block or for a (flat, starts) pair.
#
# THE STRUCTURE RULES, and where they are looser than CommonMark/GFM ON PURPOSE (looser = scans more):
#   * FENCES are matched by opener: ``` or ~~~, length >= 3; a fence closes only on the SAME
#     character at a length >= the opener's, alone on its line. A `~~~` line inside a ``` block, or
#     a ``` line inside a ```` block, is CONTENT. Any indentation is accepted for both (fences inside
#     list items are indented), and a `>` blockquote prefix is looked through.
#   * 🔴 AN UNCLOSED FENCE IS NOT A FENCE HERE. CommonMark renders it as code to end of file; a leg
#     that exempts code would then silently exempt the whole rest of the document, and one stray
#     ``` is all that takes. So the opener is returned in `unclosed` (its line number) and its lines
#     are parsed as ordinary prose -- every prose leg SCANS them (fail-closed), and the legs that
#     read code itself (GATE 57 display equations, GATE 95 transcripts) FAIL on any `unclosed`
#     entry rather than certify a block they cannot delimit. Measured on 35782834: the public
#     markdown corpus has no unclosed fence, so this costs nothing today.
#   * HEADINGS: ATX at 0-3 spaces of indent (`##` must be followed by a space or the end of the line;
#     a closing `#` run is dropped from the title), and SETEXT -- a paragraph followed by a `===` or
#     `---` underline (2+ dashes). A paragraph whose first line is a list item is not underlined by a
#     following `---` (that is a thematic break, as CommonMark has it). Fenced lines are never headings.
#   * TABLES: a header line containing `|` followed by a GFM delimiter row with the same cell count,
#     at ANY indent, with or without edge pipes; rows continue while a line contains an unescaped `|`.
#     A line that STARTS with `|` (after indent and any `>`) is a table row even outside a GFM table,
#     because every leg before this one judged such a line as a row, and narrowing that would move
#     rows into paragraph windows where a neighbour's marker could exempt them. A row-continuation
#     line with no `|` at all ends the table (GFM would keep it as a one-cell row); it is then prose,
#     so it is still scanned.
#   * PARAGRAPHS: maximal runs of non-blank lines that are none of the above, i.e. blank-line
#     delimited, as the markdown is rendered. List items and blockquote lines stay in the paragraph
#     they are wrapped in; a leg that wants smaller units splits further itself.
#   * Indented (4-space) code is NOT treated as code: it is scanned as prose (fail-closed), except by
#     a leg that reads indented displays on purpose (GATE 57 keeps its own rule).
#
# WHAT IT DOES NOT DO, so nobody reads it as more: it is not a CommonMark renderer (no HTML blocks,
# link reference definitions, lazy continuation of block quotes, or nested-list indentation model),
# and md_inline does not fold the needle-matching variants of fold_variants in doc_gates.sh (×->x,
# ≥->>=, digit commas, spacing around `+`). fold_variants is the FIXED-STRING layer GATES 3/6/47 use;
# it applies the same CR and whitespace rules on top of its own folds.
# ---------------------------------------------------------------------------------------------
# fold_join -- the post-join half of fold_variants (doc_gates.sh), for the FIXED-STRING legs. Such a
# leg flattens a file onto ONE line after folding it, and fold_variants' `+` rule runs per LINE, so "C1+"
# at a line end and "C2+C3+C5" on the next became "C1+ C2+C3+C5" and missed its needle (A11#2, measured
# on 35782834). fold_variants now also folds RUNS of spaces around `+` ("C1  +  C2"), and this re-applies
# the rule after the join. GATE 3 and GATE 6 use it wherever they used `tr '\n' ' ' | tr -s ' '`.
fold_join() { tr '\n' ' ' | tr -s ' ' | sed 's/ *+ */+/g'; }

# ---------------------------------------------------------------------------------------------
# THE SHARED NUMBER LEXER (Q-968, batch 40; R4 of the Q-962 adjudication of the Q-835 Codex lens-A
# review). _md_num_prelude prints python that a number leg puts in front of its scanner, the same
# way as _md_norm_prelude (which now emits it too, so every normaliser leg has it). md_num_scan is
# the bash-side wrapper for a grep leg.
#
# WHY. Each leg read numbers with its own `[\d.]+`, `\d(?:[.,]\d+)?` or `[0-9]+`, and each lost
# something. Measured on 35782834 (the R4 table of review_2026_09_27/Q962_ADJUDICATION_REPORT.md):
# "1,023 distinct proofs" was read as 023 = 23 and "1,002.156 TB" as 2.156 (the match began after
# the comma); "-58.8 %" was read as +58.8; an ungrouped 30-digit anchor and an ungrouped registry
# integer were invisible to legs that required comma groups; "+/-0.01" was not a band; "= ×10." and
# "7.84 / 0" fell out of the quotient population; 1001 and 0x3e9 were two seeds; "12×10³³" was read
# as 2×10³³; "C(91 , 6)" and "(1 min" did not parse.
#
# WHAT A NUMBER IS HERE (MD_NUM; every name starts md_/MD_ so it cannot shadow a leg's own):
#   LEFT EDGE  not after a letter, digit, `_` or `.`; and not after "digit," (or digit + thin space /
#              NBSP) when it starts a 3-digit group -- so "023" of "1,023" is never a number of its
#              own, while the 6 of "C(91,6)" still is.
#   SIGN       optional: - + U+2212, and the band forms ± and +/- (a space may follow ± or +/-).
#              A sign counts only at a left edge, so "3-5", "TR-11" and "2026-09-27" carry none.
#   DIGITS     1-3 digits then 3-digit groups joined by ONE kind of separator (comma, thin space
#              U+2009, narrow NBSP U+202F, NBSP U+00A0), or a plain digit run of any length. A
#              group run must not continue into a 4th digit ("1,0234" is 1 then 0234).
#   FRACTION   optional .digits.
#   EXPONENT   optional: e/E[sign]digits, or [space]×|x|·|⋅|*[space]10 then ^[sign]digits, ^(..)
#              or a superscript run (⁻⁵); and a BARE power of ten, 10^k / 10⁻⁵, as a magnitude.
#   HEX        0x/0X then hex digits, either case.
# A bare "×10" with no exponent is NOT an exponent: "7.84 / 6.52 = ×10" is a ratio of ten.
# MD_MAG is the same without the left edge and the sign, for a pattern that already fixed the
# character before the number (the × of a ratio).
#
# md_num(raw) parses one string that must be EXACTLY a number and raises MdNumError otherwise --
# a leg that captured a number and cannot read it must say so, never drop it. Its result carries
# raw, sign ('' '-' '+' '±'), pm (the band forms), mag and value (exact Fractions; value is signed,
# and a band's value is its magnitude), dp (printed decimals of the mantissa), exp (int or None),
# kind (int|dec|sci|hex), grouped, is_int, and float(). md_nums(text) yields every number in text
# with .start/.end; the one token shape it passes over is an exponent beyond +-4000 ("0e153637" is a
# sha fragment, not 10^153637), and each one is appended to MD_NUM_OVERRANGE so a leg can count it. md_ratio(a, b) raises on a zero denominator. md_binoms(text) yields
# (offset, n, k) for C(n,k), C(n, k), binom(n,k) and \binom{n}{k}, with any whitespace inside.
#
# WHAT IT DOES NOT DO: decimal commas ("8,2") are NOT read as decimals -- a comma is a group
# separator only before exactly three digits, and otherwise ends the number; ASCII space is never a
# group separator; words ("twelve") and fractions written with a slash are not numbers.
# ---------------------------------------------------------------------------------------------
_md_num_prelude() {
cat <<'MD_NUM_PY'
import re as _nre
from fractions import Fraction as _NFrac
class MdNumError(ValueError):
    pass
_MD_SUPS = '⁰¹²³⁴⁵⁶⁷⁸⁹'
_MD_SUPD = {c: str(i) for i, c in enumerate(_MD_SUPS)}
_MD_SUPD.update({'⁻': '-', '⁺': '+'})
_MD_POW = r'(?:\^\(?[-+−]?\d+\)?|[⁻⁺]?[' + _MD_SUPS + r']+)'
_MD_EXP = (r'(?:[eE][-+−]?\d+(?![0-9A-Za-z])'
           r'|[ \t]?[×x·⋅*][ \t]?10' + _MD_POW + r')')
MD_MAG = (r'(?:0[xX][0-9A-Fa-f]+(?![0-9A-Za-z])'
          r'|(?:\d{1,3}(?:,\d{3})+|\d{1,3}(?: \d{3})+|\d{1,3}(?: \d{3})+'
          r'|\d{1,3}(?: \d{3})+|\d+)(?!\d)(?:\.\d+)?'
          r'(?:' + _MD_EXP + r'|(?:(?<=[^\d.,]10)|(?<=^10))' + _MD_POW + r')?)')
MD_EDGE = r'(?<![\w.])(?:(?<!\d[,   ])|(?!\d{3}(?!\d)))'
MD_SIGN = r'(?:(?:\+/[-−]|±)[ \t]?|[-+−])'
MD_NUM = MD_EDGE + r'(?:' + MD_SIGN + r')?' + MD_MAG
MD_UNUM = MD_EDGE + MD_MAG
_MD_NUM_RE = _nre.compile(MD_NUM)
_MD_INTP = _nre.compile(r'(\d{1,3}(?:([,   ])\d{3})(?:\2\d{3})*|\d+)(?:\.(\d+))?(.*)', _nre.S)
_MD_EXPP = _nre.compile(r'(?:[eE]([-+−]?\d+)|[ \t]?[×x·⋅*][ \t]?10(\^\(?[-+−]?\d+\)?|[⁻⁺]?[' + _MD_SUPS + r']+))')

class MdNum(object):
    __slots__ = ('raw', 'sign', 'pm', 'mag', 'value', 'dp', 'exp', 'kind', 'grouped', 'start', 'end')
    def __float__(self):
        return float(self.value)
    @property
    def is_int(self):
        return self.value.denominator == 1
    def __repr__(self):
        return 'MdNum(%r)' % self.raw

def _md_powexp(p):
    if p.startswith('^'):
        p = p[1:].strip('()')
    else:
        p = ''.join(_MD_SUPD[c] for c in p)
    return int(p.replace('−', '-'))

def md_num(raw):
    """Parse a string that must be EXACTLY one number; MdNumError otherwise."""
    s = raw.strip()
    o = MdNum(); o.raw = raw; o.sign = ''; o.pm = False; o.exp = None; o.grouped = False
    o.start = o.end = None
    for sg in ('+/-', '+/−', '±', '-', '−', '+'):
        if s.startswith(sg):
            o.sign = {'+/-': '±', '+/−': '±', '−': '-'}.get(sg, sg)
            o.pm = o.sign == '±'
            s = s[len(sg):]
            if o.pm:
                s = s.lstrip(' \t')
            break
    if _nre.fullmatch(r'0[xX][0-9A-Fa-f]+', s):
        o.mag = _NFrac(int(s, 16)); o.dp = 0; o.kind = 'hex'
    else:
        m = _MD_INTP.fullmatch(s)
        if not m:
            raise MdNumError('not a number: %r' % raw)
        ip, sep, fr, rest = m.group(1), m.group(2), m.group(3) or '', m.group(4)
        o.grouped = bool(sep)
        digits = ip.replace(sep, '') if sep else ip
        mant = _NFrac(int(digits + fr), 10 ** len(fr))
        o.dp = len(fr)
        e = 0
        if rest:
            me = _MD_EXPP.fullmatch(rest)
            if me:
                e = int(me.group(1).replace('−', '-')) if me.group(1) else _md_powexp(me.group(2))
            elif digits == '10' and not fr and not o.grouped and _nre.fullmatch(_MD_POW, rest):
                mant = _NFrac(1); e = _md_powexp(rest)
            else:
                raise MdNumError('not a number: %r (trailing %r)' % (raw, rest))
            if abs(e) > 4000:
                raise MdNumError('exponent out of range: %r' % raw)
            o.exp = e
        o.mag = mant * _NFrac(10) ** e
        o.kind = 'sci' if rest else ('dec' if fr else 'int')
    o.value = -o.mag if o.sign == '-' else o.mag
    return o

MD_NUM_OVERRANGE = []   # tokens md_nums passed over: an exponent beyond +-4000 (a sha fragment such as 0e153637)
def md_nums(text, pattern=None):
    """Every number in text, left to right, as MdNum with .start/.end."""
    for m in (pattern or _MD_NUM_RE).finditer(text):
        try:
            o = md_num(m.group(0))
        except MdNumError:
            MD_NUM_OVERRANGE.append(m.group(0))
            continue
        o.start, o.end = m.start(), m.end()
        yield o

def md_ratio(a, b):
    a = a if isinstance(a, MdNum) else md_num(a)
    b = b if isinstance(b, MdNum) else md_num(b)
    if b.value == 0:
        raise MdNumError('zero denominator: %s / %s' % (a.raw, b.raw))
    return a.value / b.value

_MD_BINOM = _nre.compile(r'(?<![\w])(?:C|binom)\(\s*(\d+)\s*,\s*(\d+)\s*\)|\\binom\s*\{\s*(\d+)\s*\}\s*\{\s*(\d+)\s*\}')
def md_binoms(text):
    for m in _MD_BINOM.finditer(text):
        yield (m.start(), int(m.group(1) or m.group(3)), int(m.group(2) or m.group(4)))
MD_NUM_PY
}

# md_num_scan FILE PYREGEX -- the bash leg's door to the lexer. PYREGEX is a python regex over the
# WHOLE file (so \s crosses a hard wrap) in which {NUM} (signed), {UNUM} (unsigned, edged) and {MAG}
# (unedged) stand for the lexer's patterns. One line per match: the 1-based line of the match start,
# then each capture group, TAB-separated -- an integer group canonical (no separators, 0x read as
# hex), any other group as written. rc 2, with the reason on stderr, when FILE cannot be read: the
# caller's "could not read" FAIL, never an empty census.
md_num_scan() {
  python3 -c "$(_md_num_prelude)"'
import sys, bisect
f, pat = sys.argv[1], sys.argv[2]
pat = pat.replace("{NUM}", MD_NUM).replace("{UNUM}", MD_UNUM).replace("{MAG}", MD_MAG)
try:
    t = open(f, encoding="utf-8", errors="replace").read().replace("\r\n", "\n")
except OSError as e:
    sys.stderr.write("md_num_scan: cannot read %s (%s)\n" % (f, e.strerror)); sys.exit(2)
starts = [0] + [i + 1 for i, c in enumerate(t) if c == "\n"]
for m in _nre.finditer(pat, t):
    out = [str(bisect.bisect_right(starts, m.start()))]
    for g in m.groups():
        g = g or ""
        try:
            n = md_num(g)
            out.append(str(n.value.numerator) if n.is_int else g)
        except MdNumError:
            out.append(g)
    print("\t".join(out))
' "$1" "$2"
}

_md_norm_prelude() {
_md_num_prelude   # Q-968: the shared number lexer rides with the normaliser
cat <<'MD_NORM_PY'
import re as _mre, html as _mhtml, bisect as _mbisect
_MD_FOLD = {0x2018: "'", 0x2019: "'", 0x201a: "'", 0x201b: "'", 0x2032: "'",
            0x201c: '"', 0x201d: '"', 0x201e: '"', 0x201f: '"', 0x2033: '"',
            0x2010: '-', 0x2011: '-', 0x2012: '-', 0x2013: '-', 0x2014: '-', 0x2015: '-', 0x2212: '-',
            0x200b: None, 0x200c: None, 0x200d: None, 0x2060: None, 0xfeff: None, 0x00ad: None}
for _c in (0x00a0, 0x2002, 0x2003, 0x2004, 0x2005, 0x2006, 0x2007, 0x2008, 0x2009, 0x200a,
           0x202f, 0x205f, 0x3000, 0x0009):
    _MD_FOLD[_c] = ' '
_MD_ESC = _mre.compile(r'\\([!-/:-@\[-`{-~])')
_MD_EMPH = _mre.compile(r'\*+|~~|(?<![0-9A-Za-z])_+|_+(?![0-9A-Za-z])')
_MD_BQ = _mre.compile(r'^[ \t]*(?:>[ \t]?)+')
_MD_LIST = _mre.compile(r'^[ \t]*(?:[-*+]|\d{1,9}[.)])(?:[ \t]+|$)')
_MD_BULLET = _mre.compile(r'^[ \t]*[-*+](?:[ \t]+|$)')
_MD_FENCE = _mre.compile(r'^[ \t]*(`{3,}|~{3,})(.*)$')
_MD_ATX = _mre.compile(r'^[ ]{0,3}(#{1,6})(?:[ \t]+(.*?))?[ \t]*$')
_MD_SETEXT = _mre.compile(r'^[ ]{0,3}(=+|-{2,})[ \t]*$')
_MD_HR = _mre.compile(r'^[ ]{0,3}(?:(?:\*[ \t]*){3,}|(?:-[ \t]*){3,}|(?:_[ \t]*){3,})$')
_MD_DELIM = _mre.compile(r'^[ \t]*\|?[ \t]*:?-+:?[ \t]*(?:\|[ \t]*:?-+:?[ \t]*)*\|?[ \t]*$')
_MD_PIPE = _mre.compile(r'(?<!\\)\|')

_MD_QFOLD = {k: v for k, v in _MD_FOLD.items() if v in ("'", '"')}

def md_fold_quotes(s):
    return s.translate(_MD_QFOLD)

def md_text(raw):
    return raw.replace('\r\n', '\n').replace('\r', '\n')

def md_read(path):
    with open(path, encoding='utf-8', errors='replace') as _fh:
        return md_text(_fh.read())

_MD_DGRP = _mre.compile('(?<=\\d)[\u00a0\u2009\u202f](?=\\d{3}(?!\\d))')

def md_inline(s, fold=True):
    if '&' in s:
        s = _mhtml.unescape(s)
    # Q-968: a thin-space / NBSP digit group is a comma group, so the fold below cannot split
    # "1 023" into two numbers
    s = _MD_DGRP.sub(',', s)
    if fold:
        s = s.translate(_MD_FOLD)
    s = _MD_ESC.sub(r'\1', s).replace('`', '')
    s = _MD_EMPH.sub('', s)
    return ' '.join(s.split())

def md_body(line):
    return _MD_BQ.sub('', line) if line.lstrip().startswith('>') else line

def md_cells(line):
    s = md_body(line).strip()
    if s.startswith('|'):
        s = s[1:]
    if s.endswith('|') and not s.endswith('\\|'):
        s = s[:-1]
    return [c.strip() for c in _MD_PIPE.split(s)]

def md_parse(text):
    L = md_text(text).split('\n')
    n = len(L)
    B = [md_body(l) for l in L]
    kind = ['text'] * n
    info = {}
    unclosed = []
    i = 0
    while i < n:
        m = _MD_FENCE.match(B[i])
        if m and not (m.group(1)[0] == '`' and '`' in m.group(2)):
            close = _mre.compile(r'^[ \t]*' + _mre.escape(m.group(1)[0]) + '{%d,}[ \t]*$' % len(m.group(1)))
            j = i + 1
            while j < n and not close.match(B[j]):
                j += 1
            if j < n:
                kind[i] = kind[j] = 'fence'
                info[i] = m.group(2).strip()
                for k in range(i + 1, j):
                    kind[k] = 'code'
                i = j + 1
                continue
            unclosed.append(i + 1)
        i += 1
    for i in range(n):
        if kind[i] != 'text':
            continue
        if not B[i].strip():
            kind[i] = 'blank'
            continue
        m = _MD_ATX.match(B[i])
        if m and (len(B[i].lstrip()) == len(m.group(1)) or B[i].lstrip()[len(m.group(1))] in ' \t'):
            kind[i] = 'heading'
    i = 0
    while i + 1 < n:
        if (kind[i] == 'text' and kind[i + 1] == 'text' and _MD_PIPE.search(B[i])
                and '|' in B[i + 1] and _MD_DELIM.match(B[i + 1])
                and len(md_cells(L[i])) == len(md_cells(L[i + 1]))):
            kind[i], kind[i + 1] = 'thead', 'tdelim'
            j = i + 2
            while j < n and kind[j] == 'text' and _MD_PIPE.search(B[j]):
                kind[j] = 'trow'
                j += 1
            i = j
            continue
        i += 1
    for i in range(n):
        if kind[i] == 'text' and B[i].lstrip().startswith('|'):
            kind[i] = 'trow'
    for i in range(n):
        if kind[i] != 'text':
            continue
        if _MD_SETEXT.match(B[i]) and i > 0 and kind[i - 1] == 'text':
            a = i - 1
            while a > 0 and kind[a - 1] == 'text':
                a -= 1
            if not _MD_LIST.match(B[a]):
                kind[i] = 'setext'
                continue
        if _MD_HR.match(B[i]):
            kind[i] = 'hr'
    blocks = []
    i = 0
    while i < n:
        k = kind[i]
        if k == 'blank':
            i += 1
            continue
        if k == 'fence':
            j = i + 1
            while kind[j] != 'fence':
                j += 1
            blocks.append({'kind': 'code', 'start': i + 1, 'end': j + 1, 'info': info.get(i, ''),
                           'lines': [(x + 1, L[x]) for x in range(i + 1, j)]})
            i = j + 1
            continue
        if k == 'heading':
            m = _MD_ATX.match(B[i])
            t = m.group(2) or ''
            t = '' if _mre.fullmatch(r'#+', t) else _mre.sub(r'[ \t]+#+$', '', t)
            blocks.append({'kind': 'heading', 'start': i + 1, 'end': i + 1, 'level': len(m.group(1)),
                           'title': t, 'text': md_inline(t)})
            i += 1
            continue
        if k in ('thead', 'tdelim', 'trow'):
            j = i
            while j < n and kind[j] in ('thead', 'tdelim', 'trow') and not (j > i and kind[j] == 'thead'):
                j += 1
            delim = j > i + 1 and kind[i + 1] == 'tdelim'
            rows = [(x + 1, md_cells(L[x])) for x in range(i + (2 if delim else 1), j)]
            blocks.append({'kind': 'table', 'start': i + 1, 'end': j, 'delim': delim,
                           'header': (i + 1, md_cells(L[i])), 'rows': rows,
                           'lines': [(x + 1, L[x]) for x in range(i, j)]})
            i = j
            continue
        if k == 'hr':
            blocks.append({'kind': 'hr', 'start': i + 1, 'end': i + 1})
            i += 1
            continue
        j = i
        while j < n and kind[j] == 'text':
            j += 1
        if j < n and kind[j] == 'setext':
            t = ' '.join(B[x].strip() for x in range(i, j))
            blocks.append({'kind': 'heading', 'start': i + 1, 'end': j + 1,
                           'level': 1 if B[j].strip()[0] == '=' else 2, 'title': t, 'text': md_inline(t)})
            i = j + 1
            continue
        blocks.append(md_para([(x + 1, L[x]) for x in range(i, j)]))
        i = j
    return L, kind, blocks, unclosed

def md_para(lines):
    parts, starts, lns, off = [], [], [], 0
    for ln, raw in lines:
        # a bullet marker is dropped on any line; an ORDERED marker only on the paragraph's first line,
        # since a wrapped line that starts "8. The" is prose whose "8." must survive
        s = md_inline((_MD_LIST if not parts else _MD_BULLET).sub('', md_body(raw), count=1))
        if parts:
            off += 1
        starts.append(off)
        lns.append(ln)
        parts.append(s)
        off += len(s)
    return {'kind': 'para', 'start': lines[0][0], 'end': lines[-1][0], 'lines': list(lines),
            'text': ' '.join(parts), 'starts': starts, 'lns': lns}

def md_flatten(text):
    out, starts, off = [], [], 0
    for l in md_text(text).split('\n'):
        s = md_inline(l)
        if out:
            out.append(' ')
            off += 1
        starts.append(off)
        out.append(s)
        off += len(s)
    return ''.join(out), starts

def md_lno(block_or_starts, off):
    if isinstance(block_or_starts, dict):
        b = block_or_starts
        return b['lns'][max(0, _mbisect.bisect_right(b['starts'], off) - 1)]
    return _mbisect.bisect_right(block_or_starts, off)
MD_NORM_PY
}
