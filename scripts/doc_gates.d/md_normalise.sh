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
#                    backslash escapes dropped (the escaped character kept as a literal), CODE SPANS
#                    kept with their backticks removed (Q-976: no escape or entity processing inside one,
#                    and a `*`/`_` between alphanumerics stays, so `3*5*7*2^15` stays 3*5*7*2^15; an
#                    emphasis-shaped run at a word edge is dropped there too), LINKS and images read as
#                    their text with the destination dropped (Q-976: `[P](url)` is "P"), emphasis
#                    markers removed OUTSIDE code spans (every `*`, `~~`, and `_` at a word edge -- an
#                    `_` inside a word such as twenty_four_dvd_c1 is not emphasis and stays), stray
#                    backticks dropped, whitespace collapsed.
#   md_inline_lines(lines) the same fold for the lines of ONE block, with code spans paired across
#                    the line ends (a span that wraps is code on both lines); md_para and md_flatten use it.
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
#                      heading 'level', 'title' (raw), 'text' (md_inline of the title), and (Q-977) the
#                              para offset table ('lines', 'starts', 'lns'), so a heading is a unit too
#                      table   'header' (lineno, cells) or None, 'delim' (bool), 'rows' [(lineno, cells)]
#                      code    'lines' [(lineno, raw)] of the content, 'body' [(lineno, content)] -- the
#                              content with its block-quote and indentation container stripped (Q-977) --
#                              and 'info' (the fence info string)
#                    and every block carries 'shadow' (Q-976): True when it lies under an UNCLOSED fence,
#                    i.e. it renders as code; a leg that harvests anchors or exemptions skips it.
#   md_units(text)   the scope units a prose leg reads (Q-977): each paragraph and list item, each
#                    heading, each table row, each code line, as {'start','end','lines','text','kind'}.
#   md_cells(line)   a table row's cells, with or without edge pipes; `\|` is not a cell break.
#   md_flatten(text) -> (flat, starts): the whole file, md_inline per line, joined by one space;
#                    starts[i] is the offset of source line i+1 (the _g1 flatten contract).
#   md_lno(...)      offset -> source line, for a para block or for a (flat, starts) pair.
#
# THE STRUCTURE RULES, and where they are looser than CommonMark/GFM ON PURPOSE (looser = scans more):
#   * FENCES are matched by opener: ``` or ~~~, length >= 3; a fence closes only on the SAME
#     character at a length >= the opener's, alone on its line. A `~~~` line inside a ``` block, or
#     a ``` line inside a ```` block, is CONTENT. Q-976 (batch 43): a fence belongs to its CONTAINER.
#     It opens 0-3 columns past the content column of the list item it sits in (a ``` indented 4 or
#     more past it is indented code, scanned as prose, not a fence), and it closes only on a line of
#     the same block-quote depth; a shallower line (an unquoted line, a blank line with no `>`) or a
#     line that leaves the list item ends the container, and a fence still open then is UNCLOSED.
#     The list model is CommonMark's in outline: an item's content column is its marker's width plus
#     1-4 spaces, a line indented less ends it unless it is a lazy paragraph continuation, and an
#     ordered item other than 1 (or an empty item) cannot interrupt a paragraph.
#   * 🔴 AN UNCLOSED FENCE IS NOT A FENCE HERE. CommonMark renders it as code to end of file; a leg
#     that exempts code would then silently exempt the whole rest of the document, and one stray
#     ``` is all that takes. So the opener is returned in `unclosed` (its line number) and its lines
#     are parsed as ordinary prose -- every prose leg SCANS them (fail-closed); the blocks it covers
#     carry 'shadow' so a leg never HARVESTS an anchor or exemption from them (Q-976) -- and the legs that
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
#     delimited, as the markdown is rendered -- and (Q-976) a LIST ITEM starts a paragraph of its own,
#     so two items are two blocks. Blockquote lines stay in the paragraph they are wrapped in.
#     md_flatten keeps a bullet's marker, written `-`, so a unit splitter still sees the item start.
#   * Indented (4-space) code is NOT treated as code: it is scanned as prose (fail-closed), except by
#     a leg that reads indented displays on purpose (GATE 57 keeps its own rule).
#
# WHAT IT DOES NOT DO, so nobody reads it as more: it is not a CommonMark renderer (no HTML blocks,
# link reference definitions or reference-style links, lazy continuation of block quotes, or lists
# nested inside block quotes beyond a reset of the list model at each change of quote depth),
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

# md_code_spans(line) -> [(start, end)], end exclusive, each span INCLUDING its backticks.
# Q-985 (batch 42; Codex gpt-6-astra, Q964-D08#5): CommonMark inline code spans on one line. A run of
# N backticks opens a span that closes at the next run of EXACTLY N; an opener with no such closer
# is literal text; a backtick after an odd run of backslashes OUTSIDE a span is an escaped literal
# (inside a span a backslash is literal and escapes nothing). The legs that masked spans with
# `[^`]*` took an escaped backtick for a delimiter, so prose between two escaped backticks was
# read as code and exempted.
def md_code_spans(s):
    out, i, n = [], 0, len(s)
    while i < n:
        c = s[i]
        if c == '\\':
            i += 2; continue
        if c != '`':
            i += 1; continue
        j = i
        while j < n and s[j] == '`':
            j += 1
        k, close = j, -1
        while k < n:
            if s[k] != '`':
                k += 1; continue
            m = k
            while m < n and s[m] == '`':
                m += 1
            if m - k == j - i:
                close = m; break
            k = m
        if close < 0:
            i = j; continue
        out.append((i, close)); i = close
    return out

def md_mask_code(s, ch='x'):
    """s with every code span (backticks included) replaced by `ch`, length kept."""
    for a, b in reversed(md_code_spans(s)):
        s = s[:a] + ch * (b - a) + s[b:]
    return s
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
# Q-976 (batch 43; Codex gpt-6-astra Q964-D01#2, D01#3, D05#1): the inline fold reads CODE SPANS and
# LINKS the way CommonMark renders them. A code span (a backtick run closed by a run of the SAME
# length) is literal: no escape or entity is processed inside it and an operator `*` stays, so
# `3*5*7*2^15` stays 3*5*7*2^15 (it was 3572^15 and GATE 32 went blind). A link or image keeps its
# TEXT and drops its destination (and title): `[P](url)` reads "P", and a URL word such as
# `.../withdrawn` can no longer supply a marker. An escaped character survives the emphasis strip
# (`\*` is a literal star). Unmatched backticks are still dropped, as before.
_MD_LINKRX = _mre.compile(r'(?<!\\)!?\[((?:[^\[\]\\\n]|\\.)*)\]'
                          r'(?:\((?:[ \t]*(?:<[^<>\n]*>|(?:[^()\s\\]|\\.|\([^()\s]*\))*)'
                          r'(?:[ \t]+(?:"[^"\n]*"|\'[^\'\n]*\'|\([^()\n]*\)))?[ \t]*)\))')
_MD_ESCPH = _mre.compile(r'\\([!-/:-@\[-`{-~])')

def _md_spans(s):
    """[(is_code, start, end)] covering s in order: CommonMark code spans (a run of n backticks
    closed by the next run of exactly n; a span may cross a line end) and the text between them.
    A backslash-escaped backtick outside a span is not an opener; an opener with no closer is
    literal text. A code segment's (start, end) is its CONTENT, without the backtick runs."""
    out, i, n, t0 = [], 0, len(s), 0
    while i < n:
        c = s[i]
        if c == '\\' and i + 1 < n:
            i += 2; continue
        if c != '`':
            i += 1; continue
        j = i
        while j < n and s[j] == '`':
            j += 1
        run = j - i
        k, close = j, -1
        while k < n:
            if s[k] != '`':
                k += 1; continue
            e = k
            while e < n and s[e] == '`':
                e += 1
            if e - k == run:
                close = k; break
            k = e
        if close < 0:
            i = j; continue
        out.append((False, t0, i))
        out.append((True, j, close))
        i = t0 = close + run
    out.append((False, t0, n))
    return out

def _md_inline_text(s, fold):
    if '&' in s:
        s = _mhtml.unescape(s)
    s = _MD_DGRP.sub(',', s)
    if fold:
        s = s.translate(_MD_FOLD)
    # an escaped character is parked in the private-use area so neither the link nor the emphasis
    # rule below can consume it, then restored as the literal it is
    s = _MD_ESCPH.sub(lambda m: chr(0xF0000 + ord(m.group(1))), s)
    for _ in range(3):   # nested [ [x](u) ] collapses from the inside out
        t = _MD_LINKRX.sub(lambda m: m.group(1), s)
        if t == s:
            break
        s = t
    s = s.replace('`', '')
    s = _MD_EMPH.sub('', s)
    return _mre.sub('[\U000f0000-\U000f007f]', lambda m: chr(ord(m.group(0)) - 0xF0000), s)

# An emphasis-SHAPED run at a word edge (`**P**`, `_x_`, `~~`) is dropped inside a span too, as the fold
# dropped it before Q-976: a withdrawn phrase set in code font with its P in bold read as the phrase then
# (GATE 27 caught it on f1b27e32) and must still. A `*` or `_` BETWEEN two alphanumerics (3*5*7,
# twenty_four) is an operator or a name and stays, which is what Q-976 (Codex Q964-D01#2) needed.
_MD_CODE_EMPH = _mre.compile(r'(?<![0-9A-Za-z])[*_]+|[*_]+(?![0-9A-Za-z])|~~')
def _md_inline_code(seg, fold):
    seg = seg.replace('\\|', '|')        # GFM: a pipe escaped for a table cell renders as |
    seg = _MD_DGRP.sub(',', seg)
    seg = _MD_CODE_EMPH.sub('', seg)
    return seg.translate(_MD_FOLD) if fold else seg

def md_inline_lines(lines, fold=True):
    """md_inline of each line of ONE block (a paragraph, a list item), with code spans paired
    across the line ends the way the block renders: a span opened on one line and closed on the
    next is code on both. Returns one folded string per line."""
    lines = list(lines)
    joined = '\n'.join(lines)
    segs = _md_spans(joined)
    res, off = [], 0
    for l in lines:
        a, b, parts = off, off + len(l), []
        for code, x, y in segs:
            x, y = max(x, a), min(y, b)
            if x >= y:
                continue
            parts.append(_md_inline_code(joined[x:y], fold) if code else _md_inline_text(joined[x:y], fold))
        res.append(' '.join(''.join(parts).split()))
        off = b + 1
    return res

def md_inline(s, fold=True):
    return md_inline_lines([s], fold)[0]

def md_body(line):
    return _MD_BQ.sub('', line) if line.lstrip().startswith('>') else line

def md_cells(line):
    s = md_body(line).strip()
    if s.startswith('|'):
        s = s[1:]
    if s.endswith('|') and not s.endswith('\\|'):
        s = s[:-1]
    return [c.strip() for c in _MD_PIPE.split(s)]

# Q-976 (batch 43; Codex gpt-6-astra Q964-D01#1, D03#2, D03#7, D03#10): THE CONTAINER MODEL.
# A fence belongs to its CONTAINER, as CommonMark has it: its block-quote depth and the list item it
# sits in. (a) A fence opened inside `>` closes only on a line of the same depth; a line of a
# SHALLOWER depth (an unquoted line, a blank line with no `>`) ends the block quote and with it the
# fence -- a quoted ``` no longer pairs with an unquoted one and hides the prose between them.
# (e) A fence may be indented 0-3 columns past its container's content column; a ``` line indented
# 4 or more is indented code (scanned as prose here, as before), not a fence. (f) A fence that never
# closes, or whose container ends first, is UNCLOSED: its lines stay prose (scanned, fail-closed, as
# before), and every block it covers carries 'shadow': True, because as rendered it is code -- a leg
# that HARVESTS from text (a heading anchor, an exemption marker) must not take it from there.
# (g) A LIST ITEM is a block of its own: a paragraph ends where the next list item starts, so two
# items are two units and a qualifier in one cannot reach the other.
_MD_BQ1 = _mre.compile(r'[ \t]*>[ \t]?')
_MD_OL = _mre.compile(r'^[ \t]*(\d{1,9})[.)](?:[ \t]+|$)')

def _md_indent(s):
    w = 0
    for c in s:
        if c == ' ':
            w += 1
        elif c == '\t':
            w += 4 - w % 4
        else:
            break
    return w

def _md_depth(line):
    d, s = 0, line
    while True:
        m = _MD_BQ1.match(s)
        if not m:
            return d, s
        d += 1
        s = s[m.end():]

def _md_strip_depth(line, d):
    s = line
    for _ in range(d):
        m = _MD_BQ1.match(s)
        if not m:
            break
        s = s[m.end():]
    return s

def _md_item(body, interrupts):
    """The content column of the list item `body` opens, or None. An ordered item other than 1, or
    an empty item, cannot interrupt a paragraph (CommonMark), so a wrapped "8. The" stays prose."""
    m = _MD_LIST.match(body)
    if not m or _MD_HR.match(body):
        return None
    rest = body[m.end():]
    if interrupts:
        o = _MD_OL.match(body)
        if (o and int(o.group(1)) != 1) or not rest.strip():
            return None
    mk = m.group(0).rstrip(' \t')
    sp = len(m.group(0)) - len(mk)
    w = _md_indent(body) + len(mk.strip()) + (sp if 1 <= sp <= 4 and rest.strip() else 1)
    return w

def md_parse(text):
    L = md_text(text).split('\n')
    n = len(L)
    B = [md_body(l) for l in L]
    DEP = [_md_depth(l)[0] for l in L]
    kind = ['text'] * n
    info, body, item = {}, {}, set()
    unclosed, shadow = [], [False] * n
    stack, sdep, prev_text = [], 0, False
    i = 0
    while i < n:
        d = DEP[i]
        bi = _md_strip_depth(L[i], d)
        if d != sdep:
            stack, sdep = [], d
        if not bi.strip():
            prev_text = False
            i += 1
            continue
        ind = _md_indent(bi)
        m = _MD_FENCE.match(bi)
        lead = m is not None or _MD_ATX.match(bi) is not None or _MD_HR.match(bi) is not None
        while stack and ind < stack[-1] and not (prev_text and not lead and _md_item(bi, True) is None):
            stack.pop()                     # the line is not indented into the item: the item ended
        base = stack[-1] if stack else 0
        if m and 0 <= ind - base <= 3 and not (m.group(1)[0] == '`' and '`' in m.group(2)):
            close = _mre.compile(r'^[ \t]*' + _mre.escape(m.group(1)[0]) + '{%d,}[ \t]*$' % len(m.group(1)))
            j, end, closed = i + 1, n, False
            while j < n:
                if DEP[j] < d:
                    end = j; break          # the block quote ended, and the fence with it
                bj = _md_strip_depth(L[j], d)
                if bj.strip() and stack and _md_indent(bj) < base:
                    end = j; break          # the list item ended, and the fence with it
                if close.match(bj) and _md_indent(bj) - base <= 3:
                    closed = True; break
                j += 1
            if closed:
                kind[i] = kind[j] = 'fence'
                info[i] = m.group(2).strip()
                cut = ind
                for k in range(i + 1, j):
                    kind[k] = 'code'
                    bk = _md_strip_depth(L[k], d)
                    body[k] = bk[min(cut, _md_indent(bk)):] if bk[:1] != '\t' else bk.lstrip(' \t')
                i = j + 1
                prev_text = False
                continue
            unclosed.append(i + 1)
            for k in range(i, end):
                shadow[k] = True
        w = _md_item(bi, prev_text)
        if w is not None and ind - base <= 3:
            while stack and stack[-1] > ind:
                stack.pop()
            stack.append(w)
            item.add(i)
        prev_text = not lead
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
            while a > 0 and kind[a - 1] == 'text' and (a not in item):
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
                           'lines': [(x + 1, L[x]) for x in range(i + 1, j)],
                           'body': [(x + 1, body[x]) for x in range(i + 1, j)], 'shadow': False})
            i = j + 1
            continue
        if k == 'heading':
            m = _MD_ATX.match(B[i])
            t = m.group(2) or ''
            t = '' if _mre.fullmatch(r'#+', t) else _mre.sub(r'[ \t]+#+$', '', t)
            tx = md_inline(t)
            blocks.append({'kind': 'heading', 'start': i + 1, 'end': i + 1, 'level': len(m.group(1)),
                           'title': t, 'text': tx, 'lines': [(i + 1, L[i])], 'starts': [0],
                           'lns': [i + 1], 'shadow': shadow[i]})
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
                           'lines': [(x + 1, L[x]) for x in range(i, j)], 'shadow': shadow[i]})
            i = j
            continue
        if k == 'hr':
            blocks.append({'kind': 'hr', 'start': i + 1, 'end': i + 1, 'shadow': shadow[i]})
            i += 1
            continue
        j = i + 1
        while j < n and kind[j] == 'text' and j not in item:
            j += 1
        if j < n and kind[j] == 'setext':
            t = ' '.join(B[x].strip() for x in range(i, j))
            hb = md_para([(x + 1, L[x]) for x in range(i, j)])
            hb.update({'kind': 'heading', 'end': j + 1, 'level': 1 if B[j].strip()[0] == '=' else 2,
                       'title': t, 'shadow': shadow[i]})
            blocks.append(hb)
            i = j + 1
            continue
        pb = md_para([(x + 1, L[x]) for x in range(i, j)])
        pb['shadow'] = shadow[i]
        blocks.append(pb)
        i = j
    return L, kind, blocks, unclosed

def md_para(lines):
    parts, starts, lns, off = [], [], [], 0
    # a bullet marker is dropped on any line; an ORDERED marker only on the paragraph's first line,
    # since a wrapped line that starts "8. The" is prose whose "8." must survive. Q-976: the lines
    # are folded TOGETHER, so a code span that wraps is code on both of its lines.
    bodies = [(_MD_LIST if not k else _MD_BULLET).sub('', md_body(raw), count=1)
              for k, (ln, raw) in enumerate(lines)]
    for (ln, raw), s in zip(lines, md_inline_lines(bodies)):
        if parts:
            off += 1
        starts.append(off)
        lns.append(ln)
        parts.append(s)
        off += len(s)
    return {'kind': 'para', 'start': lines[0][0], 'end': lines[-1][0], 'lines': list(lines),
            'text': ' '.join(parts), 'starts': starts, 'lns': lns}

# Q-976 (Codex Q964-D03#7): a BULLET keeps its marker in the flattened text, written `-` whatever the
# source used. md_inline drops every `*`, so a `* item` line lost its marker and two items read as one
# sentence (a `-` item kept it). The marker is what tells a unit splitter a new item starts here.
_MD_FLATB = _mre.compile(r'^([ \t]*(?:>[ \t]?)*[ \t]*)[*+](?=[ \t])')

def md_flatten(text):
    src = md_text(text).split('\n')
    for k, l in enumerate(src):
        if _MD_BULLET.match(md_body(l)) and not _MD_HR.match(md_body(l)):
            src[k] = _MD_FLATB.sub(r'\1-', l, count=1)
    folded, run = [], []
    for l in src + ['']:          # Q-976: each blank-line-delimited run is folded together (md_inline_lines)
        if l.strip():
            run.append(l)
            continue
        folded.extend(md_inline_lines(run))
        run = []
        folded.append('')
    folded = folded[:len(src)]
    out, starts, off = [], [], 0
    for s in folded:
        if out:
            out.append(' ')
            off += 1
        starts.append(off)
        out.append(s)
        off += len(s)
    return ''.join(out), starts

# md_units(text) -> [unit]: the SCOPE UNITS a prose leg reads, in source order (Q-977, batch 43;
# Codex gpt-6-astra Q964-D06#19, D06#20): each paragraph and each list item (md_parse splits them),
# each heading, each table row, and each code line on its own -- code is still SCANNED, one line at a
# time, so moving a claim into a fence moves it into no-one's window. A unit is a dict with 'start'
# and 'end' (1-based source lines), 'lines' [(lineno, raw)] and 'text' (md_inline'd, container
# markers dropped). A leg that walked raw lines broke a unit at every `>` line, so a quoted
# two-line claim was two half-claims; and it read `**not**` as written.
def md_units(text):
    L, kind, blocks, unc = md_parse(text)
    out = []
    for b in blocks:
        k = b['kind']
        if k in ('para', 'heading'):
            out.append({'start': b['start'], 'end': b['end'], 'lines': list(b['lines']), 'text': b['text'],
                        'kind': k})
        elif k == 'table':
            for ln, raw in b['lines']:
                if kind[ln - 1] == 'tdelim':
                    continue
                out.append({'start': ln, 'end': ln, 'lines': [(ln, raw)], 'text': md_inline(md_body(raw)),
                            'kind': 'row'})
        elif k == 'code':
            for (ln, raw), (_, x) in zip(b['lines'], b['body']):
                if raw.strip():
                    out.append({'start': ln, 'end': ln, 'lines': [(ln, raw)], 'text': md_inline(x),
                                'kind': 'code'})
    return out

def md_lno(block_or_starts, off):
    if isinstance(block_or_starts, dict):
        b = block_or_starts
        return b['lns'][max(0, _mbisect.bisect_right(b['starts'], off) - 1)]
    return _mbisect.bisect_right(block_or_starts, off)
MD_NORM_PY
}
