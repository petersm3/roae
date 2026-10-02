#!/usr/bin/env bash
# cli_decl_metadata_gate.sh — a CLI doc's stated DEFAULT, CHOICES and ARITY for a flag must agree
# with the flag's argparse declaration in solve.py, roae.py and verify.py.
#
# WHY (Q-410, the declaration-metadata leg; batch 32, 2026-10-02). GATE 2 (`doc_gates.sh cli`)
# compares the SET OF FLAG NAMES in code with the set a CLI doc mentions, and its usage-grammar
# leg compares solve.c's printed `Usage:` strings with SOLVE_C_CLI.md. Neither can see a flag that
# is present in the doc with a WRONG default, a wrong choice list, or the wrong number of
# arguments. The three argparse files print no Usage: strings, so their oracle is the declaration
# itself: `default=`, `choices=`, `nargs=`/`action=`, `const=`, `type=`. This gate reads those with
# `ast` (never imports or runs the file) and checks every place the doc STATES one of them.
#
# WHAT IS A STATEMENT. Only what the doc says is checked; a terse entry that states nothing is
# not a finding (Q-410's scope note: terse is fine, FALSE is the finding).
#   DEFINITION SITES. (a) A markdown table row whose FIRST cell carries a backticked grammar that
#       begins with the flag (optionally after `python3 <file>`; a segment for another program,
#       `./verify …` or `solve …`, is skipped). (b) A man-page line inside a code fence, indented
#       at most 2 spaces, that begins with the flag; its grammar is the text before the first run
#       of 2+ spaces and its description runs on over the more-indented lines below it.
#   ARITY. A definition grammar that shows at least one operand is parsed: `X` required, `[X]`
#       optional, `X...` / `[X ...]` / `…` unbounded. Its (min, max) must lie inside the
#       declaration's: store_true/store_false/store_const/count 0..0, plain 1..1, nargs=k k..k,
#       `?` 0..1, `+` 1..inf, `*` 0..inf — plus the parser's positionals, since a grammar may
#       render one after the flag (`--fiber-sweep [solutions.bin]`). A BARE `--flag` with no operand is a name reference
#       (error tables, memory tables) and is not an arity claim.
#   CHOICES. An operand written `a|b|c` is a choice list. At a definition site it must EQUAL the
#       declared `choices=`; in a synopsis or example command line (`python3 <file> …` inside a
#       fence, and its `\`-continuations) it must be a SUBSET, and a concrete value given to a
#       flag that declares choices must be one of them. A definition that renders a choice list
#       for a flag declaring none is a finding. A man-page description's "One of a, b, c." list is
#       compared with `choices=` the same way.
#   DEFAULT. In a definition's description: `(default X)`, `(default: X)`, `default `X``,
#       `Default `X``, `defaults to X`, `X = … (default)`; and a table's `Default` column. A statement is attributed
#       to the nearest flag of this file named in the 60 characters before it, else to the row's
#       flag when the row defines exactly one, else it is AMBIGUOUS (counted, not compared). A
#       number is compared numerically (`10,000,000` = `10_000_000` = 10000000); a backticked
#       literal is compared as a string; any other wording ("all", "the atlas's own directory")
#       is PROSE — counted, never compared. A literal stated for a flag whose declared default is
#       None must equal its `const=` (nargs='?'), or it is a finding. A literal that is not
#       parseable by the declared `type=` is a finding. A statement right after a backticked
#       PLACEHOLDER (`N` (default 2)) is an operand's default, not the flag's: counted, not
#       compared. A literal equal to the default of a POSITIONAL of the same parser is accepted
#       (VERIFY.md states verify.py's `path` default inside flag rows).
#
# POSITIVE CONTROL, EVERY RUN. After judging the real docs the checker is re-run on three in-memory
# mutants of them — one compared default changed, one compared choice list with an alternative
# renamed, one store_true definition given an operand — and each must be reported naming its flag.
# A checker that cannot see those three edits would print [ok] over any doc; that is an ERROR.
#
# FLOORS (measured 2026-10-02, set below the measurement so a broken extractor ERRORs rather than
# passing on less): declarations, definition sites, and the defaults, choice lists and grammars
# actually compared. "Compared nothing" is never agreement.
#
# NOT CHECKED, stated: a default the doc words as prose; help= text; required=; metavar spelling
# (a placeholder name is the doc's choice); flags declared by sub-parsers the doc documents under
# a different program prefix; env-var defaults (GATE 84's surface); sat.py and solve.c (GATE 2's
# usage-grammar leg and sat.py's own surface, CX-249).
#
# VERDICT (whole line; read it with `grep -qx`): CLI_DECL_METADATA=PASS | FAIL | ERROR.
#   FAIL  at least one stated default, choice list or arity disagrees with the declaration.
#   ERROR a file could not be read or parsed, a floor was not met, or a positive control was not
#         reported — NOTHING trustworthy was compared.
# Exit status: 0 PASS, 1 FAIL, 2 ERROR.
# Runs from the repository root, or from any directory holding the same relative paths (that is
# how its red test runs on a scratch copy). `CLIDECL_PAIRS="code=doc ..."` narrows the pairs.
# Wired into `doc_gates.sh cli` (GATE 2) as its declaration-metadata leg.
set -uo pipefail

PAIRS=${CLIDECL_PAIRS:-"solve.py=documentation/SOLVE_PY_CLI.md roae.py=documentation/ROAE_PY_CLI.md verify.py=documentation/VERIFY.md"}

out=$(python3 - $PAIRS <<'CLIDECL_PY'
import ast, re, sys
from decimal import Decimal, InvalidOperation

INF = float("inf")
# Floors, per code file: (declarations, definition sites). Totals: defaults, choices, arities.
# Measured 2026-10-02: declarations 121 / 59 / 45; definition sites 132 / 57 / 43; compared 32
# defaults, 13 choice lists, 122 arities. Each floor sits ~15-25% under its measurement, so routine
# doc edits do not trip it and an extractor that stops matching a whole format does.
FLOOR_DECL = {"solve.py": 110, "roae.py": 55, "verify.py": 40}
FLOOR_SITES = {"solve.py": 110, "roae.py": 48, "verify.py": 35}
FLOOR_DEFAULTS, FLOOR_CHOICES, FLOOR_ARITY = 25, 10, 100

def out(*a):
    print(" ".join(str(x) for x in a))

# ------------------------------------------------------------------ code side
class Unresolved:
    def __init__(self, src): self.src = src
    def __repr__(self): return "<unresolved %s>" % self.src

def module_consts(tree):
    c = {}
    for n in tree.body:
        if isinstance(n, ast.Assign) and len(n.targets) == 1 and isinstance(n.targets[0], ast.Name):
            try:
                c[n.targets[0].id] = ast.literal_eval(n.value)
            except (ValueError, TypeError, SyntaxError):
                pass
    return c

def resolve(node, consts):
    try:
        return ast.literal_eval(node)
    except (ValueError, TypeError, SyntaxError):
        pass
    if isinstance(node, ast.Name) and node.id in consts:
        return consts[node.id]
    # A numeric wrapper type called on one literal (solve.py's _ExactAnchor("2.0")): the value
    # the user sees is the literal.
    if (isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and len(node.args) == 1
            and not node.keywords):
        try:
            v = ast.literal_eval(node.args[0])
            return Decimal(str(v))
        except (ValueError, TypeError, SyntaxError, InvalidOperation):
            pass
    return Unresolved(ast.unparse(node))

def extract_decls(path):
    tree = ast.parse(open(path, encoding="utf-8").read(), filename=path)
    consts = module_consts(tree)
    decls = {}
    # A flag belongs to a PARSER: (enclosing function, receiver name). That parser's POSITIONAL
    # arguments matter twice. A doc grammar may render one after a flag (`verify.py --fiber-sweep
    # [solutions.bin]`, the positional `path`), so a flag's arity ceiling is its own plus its
    # parser's positionals'; and a doc may state a positional's default in a flag's row.
    parent = {}
    for nd in ast.walk(tree):
        for c in ast.iter_child_nodes(nd):
            parent[c] = nd
    def parser_key(call):
        p = parent.get(call); fn = None
        while p is not None:
            if isinstance(p, (ast.FunctionDef, ast.AsyncFunctionDef)):
                fn = p.name; break
            p = parent.get(p)
        recv = call.func.value.id if isinstance(call.func.value, ast.Name) else ast.unparse(call.func.value)
        return (fn, recv)
    positionals = {}
    for n in ast.walk(tree):
        if not (isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute)
                and n.func.attr == "add_argument" and n.args):
            continue
        a0 = n.args[0]
        if isinstance(a0, ast.Constant) and isinstance(a0.value, str) and not a0.value.startswith("-"):
            kw = {k.arg: k.value for k in n.keywords if k.arg}
            na = resolve(kw["nargs"], consts) if "nargs" in kw else None
            hi = 1 if na in (None, "?") else (na if isinstance(na, int) else INF)
            dv = resolve(kw["default"], consts) if "default" in kw else None
            pk = parser_key(n)
            hi0, dvs = positionals.get(pk, (0, []))
            positionals[pk] = (hi0 + hi, dvs + ([dv] if dv is not None else []))
    for n in ast.walk(tree):
        if not (isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute)
                and n.func.attr == "add_argument" and n.args):
            continue
        names = [a.value for a in n.args if isinstance(a, ast.Constant) and isinstance(a.value, str)]
        longs = [x for x in names if x.startswith("--")]
        if not longs:
            continue
        kw = {k.arg: k.value for k in n.keywords if k.arg}
        action = resolve(kw["action"], consts) if "action" in kw else "store"
        nargs = resolve(kw["nargs"], consts) if "nargs" in kw else None
        if action in ("store_true", "store_false", "store_const", "count", "append_const", "help", "version"):
            lo, hi = 0, 0
        elif nargs is None:
            lo, hi = 1, 1
        elif isinstance(nargs, int):
            lo, hi = nargs, nargs
        elif nargs == "?":
            lo, hi = 0, 1
        elif nargs == "+":
            lo, hi = 1, INF
        elif nargs == "*":
            lo, hi = 0, INF
        else:
            lo, hi = 0, INF
        if "default" in kw:
            default = resolve(kw["default"], consts)
        else:
            default = False if action == "store_true" else (True if action == "store_false" else None)
        choices = resolve(kw["choices"], consts) if "choices" in kw else None
        if choices is not None and not isinstance(choices, Unresolved):
            choices = [str(x) for x in choices]
        tname = ast.unparse(kw["type"]) if "type" in kw else None
        const = resolve(kw["const"], consts) if "const" in kw else None
        pos_hi, pos_defaults = positionals.get(parser_key(n), (0, []))
        d = dict(line=n.lineno, action=action, nargs=nargs, lo=lo, hi=hi, default=default,
                 choices=choices, type=tname, const=const, pos_hi=pos_hi, pos_defaults=pos_defaults)
        for f in longs:
            decls.setdefault(f, []).append(d)
    return decls

# ------------------------------------------------------------------ doc side
FLAG_RE = re.compile(r"--[a-z0-9][a-z0-9_-]*")
NUM_RE = re.compile(r"[-+]?(?:\d{1,3}(?:,\d{3})+|\d[\d_]*)(?:\.\d+)?(?:[eE][-+]?\d+)?")

def split_cells(line):
    # split on unescaped | ; drop the outer empties
    cells, cur, i = [], "", 0
    s = line.strip()
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s) and s[i + 1] == "|":
            cur += "\\|"; i += 2; continue
        if s[i] == "|":
            cells.append(cur); cur = ""; i += 1; continue
        cur += s[i]; i += 1
    cells.append(cur)
    return [c for c in cells[1:-1]] if len(cells) >= 2 else []

def parse_grammar(seg):
    """seg: grammar text starting at a flag. Returns [(flag, lo, hi, [choice-sets], [concrete])]."""
    seg = seg.replace("\\|", "|").replace("…", "...")
    toks = seg.split()
    res, cur = [], None
    for t in toks:
        core = t.strip("[]")
        if core.startswith("--") and FLAG_RE.fullmatch(core.split("=")[0]):
            cur = [core.split("=")[0], 0, 0, [], []]
            res.append(cur)
            continue
        if cur is None:
            continue
        if t in ("|", "·", "/", "or", "and") or t.startswith("(") or t.startswith("#"):
            cur = None
            continue
        if core in ("...", ""):
            if core == "...":
                cur[2] = INF
            continue
        opt = t.startswith("[")
        if not opt:
            cur[1] += 1
        cur[2] = cur[2] + 1 if cur[2] != INF else INF
        if core.endswith("..."):
            cur[2] = INF
            core = core[:-3]
        if "|" in core:
            cur[3].append([x.strip("<>[]`") for x in core.split("|") if x.strip("<>[]`")])
        else:
            cur[4].append(core)
    return [tuple(r) for r in res]

def default_statements(text):
    """Yield (pos, raw_value, backticked) for every default statement in TEXT."""
    found = []
    for m in re.finditer(r"\(\s*defaults?\s*:?\s+(`[^`]+`|[^)]*)\)", text, re.I):
        found.append((m.start(), m.group(1)))
    for m in re.finditer(r"(?<!\()\bdefaults?\b\s*(?:to\s+)?:?\s*(?:\*\*)?(`[^`]+`|" + NUM_RE.pattern + r")", text, re.I):
        if any(abs(m.start() - p) < 3 for p, _ in found):
            continue
        found.append((m.start(), m.group(1)))
    for m in re.finditer(r"(`[^`]+`|[\w.,-]+)\s*=\s*[^,;()=|]{1,40}?\(default\)", text, re.I):
        found.append((m.start(), m.group(1)))
    outl = []
    for pos, raw in found:
        raw = raw.strip()
        if raw.startswith("`"):
            mm = re.match(r"`([^`]+)`", raw)
            outl.append((pos, mm.group(1), True))
            continue
        mm = re.match(NUM_RE.pattern + r"(?![\w%])", raw)
        if mm:
            outl.append((pos, mm.group(0), False))
        else:
            outl.append((pos, raw, None))   # prose
    return outl

def is_literal_expr(v):
    return not any(c in v for c in "()<>{} ") and not v.startswith("$")

def to_num(v):
    try:
        return Decimal(v.replace(",", "").replace("_", ""))
    except InvalidOperation:
        return None

def judge_default(flag, ds, value, backticked):
    """Return (status, detail): status in ok / bad / prose / unresolved."""
    if backticked is None:
        return "prose", None
    if backticked and not is_literal_expr(value):
        return "prose", None
    vals = []
    for d in ds:
        vals.append(d["default"])
        if d["nargs"] == "?" and d["const"] is not None:
            vals.append(d["const"])
        vals += d["pos_defaults"]
    if all(isinstance(v, Unresolved) for v in vals):
        return "unresolved", None
    dnum = to_num(value)
    for d in ds:
        t = d["type"]
        if t == "int" and (dnum is None or dnum != dnum.to_integral_value()):
            if value.lower() not in ("none",):
                return "bad", "stated default %r is not an int, but the declaration is type=int" % value
        if t == "float" and dnum is None and value.lower() not in ("none",):
            return "bad", "stated default %r is not a number, but the declaration is type=float" % value
    for v in vals:
        if isinstance(v, Unresolved) or v is None or isinstance(v, bool):
            if v is None and value.lower() == "none":
                return "ok", None
            if isinstance(v, bool) and value.lower() == str(v).lower():
                return "ok", None
            continue
        if isinstance(v, (int, float, Decimal)) and dnum is not None:
            if Decimal(str(v)) == dnum:
                return "ok", None
            continue
        if isinstance(v, str) and value == v:
            return "ok", None
    shown = [v for v in vals]
    return "bad", "doc states default %r; the declaration says %s" % (value, " / ".join(
        "None" if v is None else repr(v.src) if isinstance(v, Unresolved) else
        str(v) if isinstance(v, Decimal) else repr(v) for v in shown))

def check_pair(code_path, doc_text, decls, stats, findings, records):
    lines = doc_text.split("\n")
    prog = code_path.split("/")[-1]
    infence = False
    default_col = None
    def flag_ok(f):
        return f in decls
    def attrib_defaults(desc, row_flags, where, override=None):
        for pos, value, bt in default_statements(desc):
            before = desc[max(0, pos - 60):pos]
            # `N` (default 2): the default of an OPERAND placeholder (an argument inside a
            # nargs='+' list, say), not of the flag. Counted, not compared.
            if re.search(r"`[A-Z][A-Z0-9_]*`\s*$", before):
                stats["operand"] += 1
                continue
            near = [f for f in FLAG_RE.findall(before) if flag_ok(f)]
            if near:
                f = near[-1]
            elif len(row_flags) == 1:
                f = row_flags[0]
            else:
                stats["ambiguous"] += 1
                continue
            st, det = judge_default(f, decls[f], value, bt)
            stats["def_" + st] += 1
            if st == "ok":
                records["default"].append((where, f, value))
            if st == "prose":
                records["prose"].append((where, f, value))
            if st == "bad":
                findings.append("DEFAULT %s %s: %s (declared %s:%d)" % (where, f, det, code_path, decls[f][0]["line"]))
    def judge_grammar(g, where, definition):
        for f, lo, hi, chs, concrete in g:
            if not flag_ok(f):
                continue
            ds = decls[f]
            if definition and (hi > 0 or lo > 0):
                stats["arity"] += 1
                if not any(d["lo"] <= lo and hi <= d["hi"] + d["pos_hi"] for d in ds):
                    d = ds[0]
                    findings.append("ARITY %s %s: the doc shows %s argument(s); the declaration (%s) takes %s (declared %s:%d)"
                                    % (where, f, fmt_range(lo, hi), descr_nargs(d), fmt_range(d["lo"], d["hi"]),
                                       code_path, d["line"]))
                elif hi == 0 or (lo == 0 and hi == 0):
                    pass
                records["arity"].append((where, f))
            for cs in chs:
                code_ch = [d["choices"] for d in ds if d["choices"] is not None and not isinstance(d["choices"], Unresolved)]
                if not code_ch:
                    if definition:
                        findings.append("CHOICES %s %s: the doc renders the choice list %s; the declaration has no choices= (declared %s:%d)"
                                        % (where, f, "|".join(cs), code_path, ds[0]["line"]))
                    continue
                stats["choices"] += 1
                okk = any((set(cs) == set(c)) if definition else set(cs) <= set(c) for c in code_ch)
                if not okk:
                    findings.append("CHOICES %s %s: the doc shows %s; the declaration's choices are %s (declared %s:%d)"
                                    % (where, f, "|".join(cs), "|".join(code_ch[0]), code_path, ds[0]["line"]))
                elif definition:
                    records["choices"].append((where, f, "|".join(cs)))
            if True:
                code_ch = [d["choices"] for d in ds if d["choices"] is not None and not isinstance(d["choices"], Unresolved)]
                for v in concrete[:1]:
                    if code_ch and re.fullmatch(r"[A-Za-z0-9._-]+", v) and not re.fullmatch(r"[A-Z][A-Z0-9_]*", v):
                        stats["choices"] += 1
                        if not any(v in c for c in code_ch):
                            findings.append("CHOICES %s %s: the example passes %r; the declaration's choices are %s (declared %s:%d)"
                                            % (where, f, v, "|".join(code_ch[0]), code_path, ds[0]["line"]))
    i = 0
    while i < len(lines):
        ln = lines[i]; where = "L%d" % (i + 1)
        s = ln.strip()
        if s.startswith("```"):
            infence = not infence; i += 1; continue
        if infence:
            # synopsis / example command lines, with their backslash continuations
            m = re.match(r"(?:python3\s+)?(\S*%s)\s+(.*)$" % re.escape(prog), s)
            if m and (s.startswith("python3") or s.startswith(prog)):
                text = m.group(2); j = i
                while text.rstrip().endswith("\\") and j + 1 < len(lines):
                    j += 1; text = text.rstrip()[:-1] + " " + lines[j].strip()
                # a synopsis may hang its grammar on more-indented lines with no backslash
                while j + 1 < len(lines) and re.match(r"\s{8,}\[--", lines[j + 1]):
                    j += 1; text += " " + lines[j].strip()
                text = text.split("  #")[0]
                stats["synopsis"] += 1
                judge_grammar(parse_grammar(text), where, definition=False)
                i = j + 1; continue
            # man-page definition line
            ind = len(ln) - len(ln.lstrip(" "))
            mm = FLAG_RE.match(s)
            prev = lines[i - 1].rstrip() if i else ""
            if mm and ind <= 2 and not s.rstrip().endswith("\\") and not prev.endswith("\\") and flag_ok(mm.group(0)):
                parts = re.split(r"\s{2,}", s, maxsplit=1)
                gram = parts[0]; desc = parts[1] if len(parts) > 1 else ""
                j = i
                while j + 1 < len(lines):
                    nx = lines[j + 1]
                    if nx.strip().startswith("```") or not nx.strip():
                        break
                    nind = len(nx) - len(nx.lstrip(" "))
                    if nind <= 2:
                        break
                    j += 1; desc += " " + nx.strip()
                stats["sites"] += 1
                g = parse_grammar(gram)
                judge_grammar(g, where, definition=True)
                fl = [x[0] for x in g if flag_ok(x[0])]
                attrib_defaults(desc, fl[:1], where)
                for om in re.finditer(r"\bOne of\s+([^.]+(?:\.[^\s][^.]*)*)\.", desc):
                    items = [x.strip().strip("`") for x in re.split(r",\s*|\s+or\s+", om.group(1)) if x.strip()]
                    f = fl[0]
                    code_ch = [d["choices"] for d in decls[f] if d["choices"] and not isinstance(d["choices"], Unresolved)]
                    if code_ch:
                        stats["choices"] += 1
                        if not any(set(items) == set(c) for c in code_ch):
                            findings.append("CHOICES %s %s: the doc says 'One of %s'; the declaration's choices are %s (declared %s:%d)"
                                            % (where, f, ", ".join(items), "|".join(code_ch[0]), code_path, decls[f][0]["line"]))
                        else:
                            records["choices"].append((where, f, ",".join(items)))
                i = j + 1; continue
            i += 1; continue
        if s.startswith("|"):
            cells = split_cells(s)
            nxt = lines[i + 1].strip() if i + 1 < len(lines) else ""
            if re.fullmatch(r"\|?\s*:?-{2,}.*", nxt) and set(nxt) <= set("|-: "):
                hdr = [c.strip().strip("*").lower() for c in cells]
                default_col = hdr.index("default") if "default" in hdr else None
                i += 2; continue
            if not cells:
                i += 1; continue
            first = cells[0].replace("\\|", "|")
            segs = re.findall(r"`([^`]+)`", first)
            row_flags, defined = [], False
            for k, seg in enumerate(segs):
                seg = seg.strip()
                if seg.startswith("python3 "):
                    p = seg.split(None, 2)
                    if len(p) < 2 or not p[1].endswith(prog):
                        continue
                    seg = p[2] if len(p) > 2 else ""
                elif seg.startswith(prog + " "):
                    seg = seg[len(prog) + 1:]
                if not FLAG_RE.match(seg):
                    continue
                if k == 0 or defined:
                    defined = True
                    g = parse_grammar(seg)
                    judge_grammar(g, where, definition=True)
                    row_flags += [x[0] for x in g if flag_ok(x[0])]
            if defined and row_flags:
                stats["sites"] += 1
                desc = " | ".join(cells[1:]).replace("\\|", "|")
                if default_col is not None and default_col < len(cells) and len(set(row_flags)) == 1:
                    dv = cells[default_col].strip()
                    f = row_flags[0]
                    if dv and dv not in ("—", "-", "–"):
                        bt = dv.startswith("`")
                        val = dv.strip("`") if bt else dv
                        if not bt:
                            mm = re.fullmatch(NUM_RE.pattern, dv)
                            bt = False if mm else None
                        st, det = judge_default(f, decls[f], val, bt)
                        stats["def_" + st] += 1
                        if st == "ok":
                            records["default"].append((where, f, val))
                        if st == "prose":
                            records["prose"].append((where, f, val))
                        if st == "bad":
                            findings.append("DEFAULT %s %s: %s (declared %s:%d)" % (where, f, det, code_path, decls[f][0]["line"]))
                    cells_desc = [c for k2, c in enumerate(cells[1:], 1) if k2 != default_col]
                    desc = " | ".join(cells_desc).replace("\\|", "|")
                attrib_defaults(desc, sorted(set(row_flags)), where)
            i += 1; continue
        default_col = None if not s.startswith("|") else default_col
        i += 1

def fmt_range(lo, hi):
    if hi == INF:
        return "%d or more" % lo
    return str(lo) if lo == hi else "%d..%d" % (lo, hi)

def descr_nargs(d):
    if d["action"] not in ("store",):
        return "action=%s" % d["action"]
    return "nargs=%r" % (d["nargs"],) if d["nargs"] is not None else "one value"

def run(pairs, docs_override=None):
    stats_all = {}; findings = []; records = {"default": [], "choices": [], "arity": [], "prose": []}
    err = []
    for code, doc in pairs:
        try:
            decls = extract_decls(code)
            text = docs_override[doc] if docs_override and doc in docs_override else open(doc, encoding="utf-8").read()
        except (OSError, SyntaxError, UnicodeDecodeError) as e:
            err.append("cannot read or parse %s / %s: %s" % (code, doc, e)); continue
        st = {k: 0 for k in ("sites", "synopsis", "arity", "choices", "ambiguous", "operand", "def_ok", "def_bad", "def_prose", "def_unresolved")}
        st["decls"] = len(decls)
        recs = {"default": [], "choices": [], "arity": [], "prose": []}
        check_pair(code, text, decls, st, findings_local := [], recs)
        findings += ["%s: %s" % (doc, f) for f in findings_local]
        for k in recs:
            records[k] += [(code, doc) + r for r in recs[k]]
        stats_all[code] = st
    return stats_all, findings, records, err

pairs = [tuple(a.split("=", 1)) for a in sys.argv[1:]]
if not pairs or any(len(p) != 2 for p in pairs):
    out("ERROR no code=doc pairs given"); sys.exit(0)
stats, findings, records, err = run(pairs)
if err:
    for e in err: out("ERROR", e)
    sys.exit(0)

tot = {k: sum(s[k] for s in stats.values()) for k in next(iter(stats.values()))}
for code, s in stats.items():
    out("INFO %s: %d declared flags; %d definition sites, %d synopsis/example lines; compared %d arities,"
        " %d choice lists, %d defaults (%d prose, %d operand-level, %d ambiguous, %d unresolvable — not compared)"
        % (code, s["decls"], s["sites"], s["synopsis"], s["arity"], s["choices"],
           s["def_ok"] + s["def_bad"], s["def_prose"], s["operand"], s["ambiguous"], s["def_unresolved"]))
short = []
for code, s in stats.items():
    if code in FLOOR_DECL and s["decls"] < FLOOR_DECL[code]:
        short.append("%s: %d declarations < floor %d" % (code, s["decls"], FLOOR_DECL[code]))
    if code in FLOOR_SITES and s["sites"] < FLOOR_SITES[code]:
        short.append("%s: %d definition sites < floor %d" % (code, s["sites"], FLOOR_SITES[code]))
full = all(c in stats for c in FLOOR_DECL)
if full:
    if tot["def_ok"] + tot["def_bad"] < FLOOR_DEFAULTS:
        short.append("%d defaults compared < floor %d" % (tot["def_ok"] + tot["def_bad"], FLOOR_DEFAULTS))
    if tot["choices"] < FLOOR_CHOICES:
        short.append("%d choice lists compared < floor %d" % (tot["choices"], FLOOR_CHOICES))
    if tot["arity"] < FLOOR_ARITY:
        short.append("%d arities compared < floor %d" % (tot["arity"], FLOOR_ARITY))
if short:
    for x in short: out("ERROR floor:", x)
    out("ERROR the extractor is reading less than it did when measured — NOTHING useful was compared")
    sys.exit(0)

import os
if os.environ.get("CLIDECL_DEBUG"):
    for k in records:
        for r in records[k]: out("DEBUG", k, *r)

# ---- positive control: three in-memory mutants must each be reported -------------------------
def mutate_and_check(kind):
    docs = {d: open(d, encoding="utf-8").read() for _, d in pairs}
    if kind == "default":
        cands = [r for r in records["default"] if to_num(r[4]) is not None]
        if not cands: return None, "no numeric default was compared"
        code, doc, where, flag, val = cands[0]
        ln = int(where[1:]) - 1
        L = docs[doc].split("\n")
        new = str(int(to_num(val)) + 7) if to_num(val) == to_num(val).to_integral_value() else str(to_num(val) + 7)
        if val not in L[ln]: return None, "cannot locate %r on %s" % (val, where)
        L[ln] = L[ln].replace(val, new, 1)
    elif kind == "choices":
        cands = [r for r in records["choices"] if "|" in r[4]]
        if not cands: return None, "no choice list was compared"
        code, doc, where, flag, val = cands[0]
        ln = int(where[1:]) - 1
        L = docs[doc].split("\n")
        alts = val.split("|")
        bogus = alts[:-1] + ["zz-not-a-choice"]
        esc_old, esc_new = "\\|".join(alts), "\\|".join(bogus)
        if esc_old in L[ln]:
            L[ln] = L[ln].replace(esc_old, esc_new, 1)
        elif val in L[ln]:
            L[ln] = L[ln].replace(val, "|".join(bogus), 1)
        else:
            return None, "cannot locate %r on %s" % (val, where)
    else:
        L = None
        for code, doc in pairs:
            decls = extract_decls(code)
            LL = docs[doc].split("\n")
            for k, ln in enumerate(LL):
                m = re.match(r"\|\s*`(--[a-z0-9][a-z0-9-]*)`\s*\|", ln)
                if m and m.group(1) in decls and decls[m.group(1)][0]["action"] == "store_true":
                    LL[k] = ln.replace("`%s`" % m.group(1), "`%s N`" % m.group(1), 1)
                    flag, L = m.group(1), LL
                    break
            if L: break
        if not L: return None, "no store_true table definition found"
    docs[doc] = "\n".join(L)
    _, f2, _, e2 = run(pairs, docs)
    hit = [x for x in f2 if (" %s:" % flag) in x and x.split(": ", 1)[1].startswith(kind.upper())]
    return (flag, hit), None

ctrl_bad = []
for kind in ("default", "choices", "arity"):
    res, why = mutate_and_check(kind)
    if res is None:
        ctrl_bad.append("%s control could not be built: %s" % (kind, why)); continue
    flag, hit = res
    if not hit:
        ctrl_bad.append("the %s mutant of %s was NOT reported" % (kind, flag))
    else:
        out("CONTROL %s mutant of %s reported" % (kind, flag))
if ctrl_bad:
    for x in ctrl_bad: out("ERROR positive control:", x)
    sys.exit(0)

for f in findings:
    out("BAD", f)
out("RESULT", "FAIL" if findings else "PASS")
CLIDECL_PY
)

printf '%s\n' "$out" | sed -n 's/^INFO /  [info] /p'
[ -n "${CLIDECL_DEBUG:-}" ] && printf '%s\n' "$out" | grep '^DEBUG'

if grep -q '^ERROR' <<<"$out" || ! grep -qE '^RESULT (PASS|FAIL)$' <<<"$out"; then
  printf '%s\n' "$out" | sed -n 's/^ERROR /  [FAIL] /p'
  echo "  [FAIL] declaration-metadata leg measured NOTHING trustworthy (see above) — this is not agreement"
  echo "CLI_DECL_METADATA=ERROR"
  exit 2
fi
printf '%s\n' "$out" | sed -n 's/^CONTROL /  [ok]   positive control: /p'
if grep -qx 'RESULT FAIL' <<<"$out"; then
  printf '%s\n' "$out" | sed -n 's/^BAD /  [FAIL] /p'
  echo "         Fix the documentation to match the declaration (the code is the behaviour), or,"
  echo "         if the declaration is what is wrong, change the code and the doc together."
  echo "CLI_DECL_METADATA=FAIL"
  exit 1
fi
echo "  [ok]   every stated default, choice list and arity agrees with its argparse declaration"
echo "CLI_DECL_METADATA=PASS"
exit 0
