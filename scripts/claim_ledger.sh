#!/usr/bin/env bash
# claim_ledger.sh — check documentation/CLAIMS.tsv, the typed claim ledger: every row's published
# value is re-derived from committed artifacts and compared with the text that publishes it.
# Q-296, first tranche, 2026-09-26. Claude (Opus 5.5), developed with AI assistance (Claude, Anthropic).
#
# WHY. A published number is a sentence, and a sentence cannot be checked for the thing that keeps
# going wrong here, which is less often the arithmetic than the KIND of statement: an extremum over
# one set printed as one over another, a figure its own source holds conditional printed bare. The
# ledger gives each published figure a typed row, and this script checks every row against two
# things it does not control: the published line, and a command that re-derives the value from
# files in this repository. A row that agrees with itself proves nothing, so neither check reads
# the ledger's value from anywhere but the ledger.
#
# THE ROW (tab-separated, 13 columns, `#` lines are comments; the header row is required):
#   id           [A-Z0-9_]+, unique. The row's verdict token is CLAIM_<id>=TRUE|FALSE.
#   set          the population the figure is over (SUPER = C1∩C2∩C4∩C5, King Wen's walk, a file set)
#   equivalence  raw | orbit | K4 | pair-class | none   (none: not a count of mathematical objects)
#   unit         what one unit of the figure is (orderings, t-units, steps, bits, registry rows, ...)
#   scope        universal | scoped:<condition> | conditional-on:<premise>
#   status       proven | measured | near-certain | hypothesis | retracted
#   value        the figure VERBATIM as published (a U+2212 minus is compared as '-')
#   render       how the derived value is written in the text: exact | commas | kv | word | count |
#                range | range:N | round:N | absround:N | ceil:N | pct:N | sci:N | tb:N
#   source       FILE:LINE of the published line that carries `value`
#   premise      conditional-on rows: text that must appear in the SAME SENTENCE as the value;
#                every other row: `-`
#   evidence     a shell command, run from the repository root, whose output carries KEY=value
#   key          the KEY whose value (exactly one distinct one) is the derived figure
#   artifact     the committed file(s) the evidence reads, comma-separated; each must exist
#
# WHAT A ROW MUST SATISFY (all of them; the first failure is printed):
#   S  the source line contains `value` as a whole figure (not inside a longer number or word)
#   E  the evidence's KEY, rendered, equals `value`
#   P  scope conditional-on:<premise>  =>  `premise` is in the sentence that carries `value`. The
#      design's load-bearing invariant: a conditional figure may not be printed without its premise.
#   F  the evidence resolves: every `solve.py --flag` it names is an add_argument flag of solve.py,
#      and every `claim_ledger.sh --derive NAME` a derivation below (the ledger form of GATE 25's
#      "a repro must name a real flag")
#   A  every artifact exists
#
# USAGE
#   bash scripts/claim_ledger.sh [--check] [--selftest] [--ledger FILE]
#   bash scripts/claim_ledger.sh --derive NAME     print one derivation's KEY=value lines
#   --check is the default when neither mode is named. Both may be given; they share one evidence
#   cache, so the evidence commands run once (~15 s on the worker, measured 2026-09-26).
#
# VERDICTS, whole lines, `grep -qx`-able:
#   CLAIM_<id>=TRUE|FALSE          one per row
#   CLAIM_LEDGER=PASS  rc 0        every row TRUE
#   CLAIM_LEDGER=FAIL  rc 1        some row FALSE ([FALSE] lines name it and why)
#   CLAIM_LEDGER=ERROR rc 2        nothing was compared: unreadable ledger, bad schema, no rows
#   CLAIM_LEDGER_SELFTEST=PASS|FAIL   from --selftest; rc 0 / 1
#
# SELF-TEST (--selftest). In memory: the ledger text and the published files are replaced by
# mutated copies, and no tracked file is written. The unmodified ledger must read PASS (positive
# control), then each mutant must give its stated verdict:
#   M1  a wrong value planted in the ledger (68.67 -> 68.68)                     row FALSE
#   M2  the published text changed under a correct ledger (68.67 -> 68.76)        row FALSE
#   M3  a conditional-on figure rendered bare: the premise removed from its sentence  row FALSE
#   M4  a planted conditional-on row whose premise sits in the same PARAGRAPH but a
#       different sentence                                                         row FALSE
#   M5  twin of M4 with the premise in the same sentence                           row TRUE
#   M6  one line inserted above the cited lines (every pin shifts)                  rows FALSE
#   M7  the evidence key renamed to one the command does not print                  row FALSE
#   M8  a solve.py flag that does not exist in the evidence                         row FALSE
#   M9  a figure present only inside a longer number on its line (3 in 0.0337)      row FALSE
#   M10 an unknown status / an unknown render / a short row / a duplicate id         ERROR each
#   M11 an artifact path that does not exist                                        row FALSE
#   M12 FOR EVERY ROW: its value perturbed (last digit +1, next number word, FAIL<->PASS)
#       in the ledger AND on its published line, so S and P still hold       that row FALSE on E
#   M1 and M2 fire on S; M12 is what shows each row's evidence discriminates on its own.
set -uo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || { echo "CLAIM_LEDGER=ERROR"; exit 2; }
exec python3 - "$@" <<'CLAIM_LEDGER_PY'
import csv, io, json, itertools, math, os, re, subprocess, sys
from decimal import Decimal, ROUND_HALF_UP, ROUND_CEILING

LEDGER_DEFAULT = "documentation/CLAIMS.tsv"
ATLAS = "runs/20260906_kc_ladders_n31/atlas_n31.json"
COLS = ["id", "set", "equivalence", "unit", "scope", "status", "value", "render", "source",
        "premise", "evidence", "key", "artifact"]
STATUS = {"proven", "measured", "near-certain", "hypothesis", "retracted"}
EQUIV = {"raw", "orbit", "K4", "pair-class", "none"}
RENDER_RE = re.compile(r"^(exact|commas|kv|word|count|range|(range|round|absround|ceil|pct|sci|tb):\d+)$")
SCOPE_RE = re.compile(r"^(universal|scoped:.+|conditional-on:.+)$")
WORDS = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
         "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen",
         "nineteen", "twenty"]
SUP = str.maketrans("0123456789-", "⁰¹²³⁴⁵⁶⁷⁸⁹⁻")
# A sentence ends at . ! or ? (after any closing markup) followed by whitespace and then a
# capital or a digit, optionally behind opening markup. Decimal points never qualify: they are
# not followed by whitespace.
SENT_END = re.compile(r"[.!?][*_)`\]]*\s+(?=[*_`(\[]*[A-Z0-9])")


# ------------------------------------------------------------------ derivations (--derive NAME)
def _tsv(path):
    return list(csv.DictReader(open(path, encoding="utf-8"), delimiter="\t"))


def d_catalog():
    """Ladder sizes and registry row counts, from runs/20260906_kc_ladders_n31/."""
    base = "runs/20260906_kc_ladders_n31/"
    total = 0
    for line in open(base + "README.md", encoding="utf-8"):
        m = re.match(r"^\| ([fgt]) \| 65 \| ([0-9,]+) \|$", line.rstrip("\n"))
        if m:
            total += int(m.group(2).replace(",", ""))
    rows = lambda f: sum(1 for l in open(base + f, encoding="utf-8") if l.strip() and not l.startswith("#"))
    print("LADDER_BYTES=%d" % total)
    print("LAYERSHA_ROWS=%d" % sum(rows("STAGE_%s_LAYERSHA.txt" % s) for s in "FGT"))
    print("T_SHA256_ROWS=%d" % rows("STAGE_T_SHA256.txt"))
    print("FG_SHA256_ROWS=%d" % (rows("STAGE_F_SHA256.txt") + rows("STAGE_G_SHA256.txt")))


def d_atlas_space():
    """The constraints of C1..C5 that the atlas's own space label does not carry."""
    space = json.load(open(ATLAS, encoding="utf-8"))["space"]
    print("ATLAS_SPACE=%s" % space)
    head = space.split("-")[0]
    print("ATLAS_OMITTED_CONSTRAINTS=%s" % ",".join(c for c in ("C1", "C2", "C3", "C4", "C5")
                                                   if not re.search(c + r"(?!\d)", head)))


def d_a_anchors():
    """Deviation/tolerance multiples of the two external-anchor checks, from --atlas-queries."""
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        r = subprocess.run([sys.executable, "solve.py", "--atlas-queries", ATLAS, "--atlas-out", d],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                           text=True)
    pairs = re.findall(r"max deviation ([0-9.]+) \(tol ([0-9.]+)\)", r.stdout)
    print("A_CHECKS_WITH_TOLERANCE=%d" % len(pairs))
    mult = sorted({int((Decimal(a) / Decimal(b)).quantize(Decimal(1), ROUND_HALF_UP)) for a, b in pairs})
    print("TOL_MULTIPLE_ROUNDED=%s" % ",".join(map(str, mult)))


def d_v2_branches():
    """V2's branch panel, from tr12/scan/v2_branches.tsv."""
    b = _tsv("tr12/scan/v2_branches.tsv")
    sol = [int(r["solutions"]) for r in b]
    cost = [int(r["prefixes_t_units"]) for r in b]
    print("V2_BRANCHES=%d" % len(b))
    print("V2_BRANCH_PAIRS=%d" % (len(b) * (len(b) - 1) // 2))
    print("V2_DISCORDANT_PAIRS=%d" % sum(1 for i, j in itertools.combinations(range(len(b)), 2)
                                         if (sol[i] - sol[j]) * (cost[i] - cost[j]) < 0))
    print("V2_MASS_LEVELS=%d" % len(set(sol)))
    print("V2_COST_LEVELS=%d" % len(set(cost)))
    sh = [float(r["share"]) for r in b]
    print("V2_SHARE_MIN_MAX=%r,%r" % (min(sh), max(sh)))
    lc = [math.log10(c) for c in cost]
    print("V2_LOG10_COST_MIN_MAX=%r,%r" % (min(lc), max(lc)))
    cps = [c / s for c, s in zip(cost, sol)]
    print("V2_COST_PER_SOLUTION_MIN_MAX=%r,%r" % (min(cps), max(cps)))


def d_v3_spectrum():
    """V3's rank spectrum, from tr12/v3_spectrum.tsv (x = normalised REL rank)."""
    s = _tsv("tr12/v3_spectrum.tsv")
    meta = {"i", "rank", "x", "order", "walk"}
    obs = [c for c in s[0] if c not in meta and not c.startswith("kw_")]
    x = [float(r["x"]) for r in s]

    def corr(a, b):
        ma, mb = sum(a) / len(a), sum(b) / len(b)
        sab = sum((u - ma) * (v - mb) for u, v in zip(a, b))
        return sab / math.sqrt(sum((u - ma) ** 2 for u in a) * sum((v - mb) ** 2 for v in b))
    drawn = {c: corr(x, [float(r[c]) for r in s]) for c in obs if len({r[c] for r in s}) > 1}
    print("V3_POINTS=%d" % len(s))
    print("V3_OBSERVABLES_DRAWN=%d" % len(drawn))
    print("V3_MAX_ABS_R=%r" % max(abs(v) for v in drawn.values()))
    print("V3_R_FFT_DOMINANT_FREQ=%r" % drawn["fft_dominant_freq"])
    print("V3_C6_C7_ZERO_POINTS=%d" % sum(1 for r in s if float(r["c6_c7_count"]) == 0))
    for v in ("2", "3"):
        print("V3_FIRST_POSITION_DEVIATION_%s_POINTS=%d" % (v, sum(1 for r in s if r["first_position_deviation"] == v)))
    last = [r["walk"].split(",")[-1] for r in s]
    print("V3_FINAL_HEXAGRAM_RUNS=%d" % (1 + sum(1 for a, b in zip(last, last[1:]) if a != b)))
    c3 = [int(r["c3_total"]) for r in s]
    print("V3_C3_TOTAL_MIN_MAX=%d,%d" % (min(c3), max(c3)))
    kw = {r["kw_c3_total"] for r in s}
    print("V3_KW_C3_TOTAL=%s" % (kw.pop() if len(kw) == 1 else "NOT-CONSTANT"))


def d_v4_profile():
    """V4's two visible checks, from tr12/q3_profile_kw.tsv."""
    p = _tsv("tr12/q3_profile_kw.tsv")
    print("V4_G_AT_LAST_PLACEMENT=%s" % p[-1]["g"])
    bits = {("%g" % float(r["bits"])) for r in p if r["alts"] == "1"}
    print("V4_BITS_AT_SINGLE_ALTERNATIVE=%s" % (",".join(sorted(bits)) or "NONE"))


def d_v5_grammar():
    """V5's cross-tab size, from tr12/scan/v5_grammar.tsv."""
    g = _tsv("tr12/scan/v5_grammar.tsv")
    print("V5_ROWS=%d" % len(g))
    print("V5_NONZERO_CELLS=%d" % sum(1 for r in g if int(r["mass"]) != 0))


DERIVE = {"catalog": d_catalog, "atlas-space": d_atlas_space, "a-anchors": d_a_anchors,
          "v2-branches": d_v2_branches, "v3-spectrum": d_v3_spectrum, "v4-profile": d_v4_profile,
          "v5-grammar": d_v5_grammar}


# ------------------------------------------------------------------ rendering
def q(x, n, mode=ROUND_HALF_UP):
    return Decimal(x).quantize(Decimal(1).scaleb(-n), mode)


def render(derived, spec, key):
    kind, _, n = spec.partition(":")
    n = int(n) if n else 0
    if kind == "exact":
        return derived
    if kind == "kv":
        return "%s=%s" % (key, derived)
    if kind == "commas":
        return "{:,}".format(int(derived))
    if kind == "word":
        return WORDS[int(derived)]
    if kind == "count":
        return str(len(derived.split(",")))
    if kind == "range":
        a, b = derived.split(",")
        if spec == "range":
            return "%s–%s" % (a, b)
        return "%s–%s" % (q(a, n), q(b, n))
    if kind == "round":
        return str(q(derived, n))
    if kind == "absround":
        return str(q(derived, n).copy_abs())
    if kind == "ceil":
        return str(q(derived, n, ROUND_CEILING))
    if kind == "pct":
        return str(q(Decimal(derived) * 100, n))
    if kind == "tb":
        return str(q(Decimal(derived) / Decimal(10) ** 12, n))
    if kind == "sci":
        d = Decimal(derived)
        e = d.adjusted()
        return "%s×10%s" % (q(d.scaleb(-e), n), str(e).translate(SUP))
    raise ValueError(spec)


def norm(s):
    return s.replace("−", "-")


def value_re(v):
    return re.compile(r"(?<![\w.,−-])" + re.escape(v) + r"(?![\w]|[.,]\d)")


# ------------------------------------------------------------------ checking
class SchemaError(Exception):
    pass


def parse(text):
    rows, header = [], None
    for ln, line in enumerate(text.split("\n"), 1):
        if not line.strip() or line.startswith("#"):
            continue
        f = line.split("\t")
        if header is None:
            if f != COLS:
                raise SchemaError("line %d: header must be the %d columns %s" % (ln, len(COLS), " ".join(COLS)))
            header = f
            continue
        if len(f) != len(COLS):
            raise SchemaError("line %d: %d columns, need %d" % (ln, len(f), len(COLS)))
        r = dict(zip(COLS, f))
        r["_line"] = ln
        rows.append(r)
    if header is None or not rows:
        raise SchemaError("no header or no rows")
    seen = set()
    for r in rows:
        where = "line %d (%s)" % (r["_line"], r["id"])
        if not re.fullmatch(r"[A-Z0-9_]+", r["id"]):
            raise SchemaError(where + ": id must be [A-Z0-9_]+")
        if r["id"] in seen:
            raise SchemaError(where + ": duplicate id")
        seen.add(r["id"])
        if r["status"] not in STATUS:
            raise SchemaError(where + ": status %r not in %s" % (r["status"], sorted(STATUS)))
        if r["equivalence"] not in EQUIV:
            raise SchemaError(where + ": equivalence %r not in %s" % (r["equivalence"], sorted(EQUIV)))
        if not SCOPE_RE.match(r["scope"]):
            raise SchemaError(where + ": scope %r" % r["scope"])
        if not RENDER_RE.match(r["render"]):
            raise SchemaError(where + ": render %r" % r["render"])
        if not re.fullmatch(r"[^:\s]+:\d+", r["source"]):
            raise SchemaError(where + ": source must be FILE:LINE")
        cond = r["scope"].startswith("conditional-on:")
        if cond and r["premise"] in ("", "-"):
            raise SchemaError(where + ": a conditional-on row needs a premise")
        if not cond and r["premise"] != "-":
            raise SchemaError(where + ": premise must be '-' unless scope is conditional-on:")
        for c in ("set", "unit", "value", "evidence", "key", "artifact"):
            if not r[c].strip() or r[c] == "-":
                raise SchemaError(where + ": empty %s" % c)
    return rows


_FLAGS = None


def solve_py_flags():
    global _FLAGS
    if _FLAGS is None:
        src = open("solve.py", encoding="utf-8").read()
        _FLAGS = set(re.findall(r"add_argument\(\s*[\"'](--[a-z0-9-]+)[\"']", src))
    return _FLAGS


def unresolved(cmd):
    bad = []
    for seg in re.findall(r"solve\.py([^|;&]*)", cmd):   # up to the end of that command
        for fl in re.findall(r"(?<!\S)(--[a-z0-9-]+)", seg):
            if fl not in solve_py_flags():
                bad.append("solve.py " + fl)
    for name in re.findall(r"claim_ledger\.sh\s+--derive\s+(\S+)", cmd):
        if name not in DERIVE:
            bad.append("claim_ledger.sh --derive " + name)
    return bad


def run_evidence(cmd, cache):
    if cmd not in cache:
        r = subprocess.run(["bash", "-c", cmd], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           stdin=subprocess.DEVNULL, text=True, timeout=900)
        cache[cmd] = r.stdout
    return cache[cmd]


def sentence_of(lines, lno, start):
    """The sentence of the paragraph around line lno (1-based) that contains column `start`."""
    a = b = lno - 1
    while a > 0 and lines[a - 1].strip():
        a -= 1
    while b + 1 < len(lines) and lines[b + 1].strip():
        b += 1
    para, off = "", None
    for i in range(a, b + 1):
        if i == lno - 1:
            off = len(para) + start
        para += lines[i] + " "
    cuts = [0] + [m.end() for m in SENT_END.finditer(para)] + [len(para)]
    for s, e in zip(cuts, cuts[1:]):
        if s <= off < e:
            return para[s:e]
    return para


def check_row(r, files, cache):
    """Return (ok, reason)."""
    path, lno = r["source"].rsplit(":", 1)
    lno = int(lno)
    for art in r["artifact"].split(","):
        if not os.path.exists(art.strip()):
            return False, "A: artifact %s does not exist" % art.strip()
    text = files(path)
    if text is None:
        return False, "S: source file %s not readable" % path
    lines = text.split("\n")
    if not 1 <= lno <= len(lines):
        return False, "S: %s has %d lines, cited line %d" % (path, len(lines), lno)
    vre = value_re(r["value"])
    m = vre.search(lines[lno - 1])
    if not m:
        elsewhere = [str(i + 1) for i, l in enumerate(lines) if vre.search(l)][:5]
        return False, "S: %r is not on %s:%d%s" % (r["value"], path, lno,
                                                   " (found on line(s) %s)" % ",".join(elsewhere) if elsewhere else "")
    if r["scope"].startswith("conditional-on:"):
        sent = sentence_of(lines, lno, m.start())
        if r["premise"] not in sent:
            return False, "P: conditional figure %r printed without its premise %r in the same sentence: %r" % (
                r["value"], r["premise"], sent.strip()[:240])
    bad = unresolved(r["evidence"])
    if bad:
        return False, "F: evidence names what does not exist: %s" % ", ".join(bad)
    out = run_evidence(r["evidence"], cache)
    vals = {mm.group(1) for mm in re.finditer(r"^" + re.escape(r["key"]) + r"=(.*)$", out, re.M)}
    if len(vals) != 1:
        return False, "E: evidence printed %d distinct values for %s (need exactly 1)" % (len(vals), r["key"])
    derived = vals.pop()
    try:
        got = render(derived, r["render"], r["key"])
    except (ValueError, ArithmeticError, IndexError) as exc:
        return False, "E: cannot render %r as %s: %s" % (derived, r["render"], exc)
    if norm(got) != norm(r["value"]):
        return False, "E: evidence gives %s=%s, rendered %s -> %r; ledger and text say %r" % (
            r["key"], derived, r["render"], got, r["value"])
    return True, ""


def disk(path):
    try:
        return open(path, encoding="utf-8").read()
    except OSError:
        return None


def check(text, cache, overrides=None):
    """-> (verdict, {id: (ok, reason)}, error)"""
    overrides = overrides or {}
    files = lambda p: overrides[p] if p in overrides else disk(p)
    try:
        rows = parse(text)
    except SchemaError as exc:
        return "ERROR", {}, str(exc)
    res = {r["id"]: check_row(r, files, cache) for r in rows}
    return ("PASS" if all(ok for ok, _ in res.values()) else "FAIL"), res, ""


def report(verdict, res, err):
    for rid, (ok, why) in res.items():
        if not ok:
            print("  [FALSE] %s: %s" % (rid, why))
        print("CLAIM_%s=%s" % (rid, "TRUE" if ok else "FALSE"))
    if err:
        print("  [ERROR] " + err)
    print("CLAIM_LEDGER_ROWS=%d" % len(res))
    print("CLAIM_LEDGER=%s" % verdict)


# ------------------------------------------------------------------ self-test
def selftest(ledger_path, text, cache):
    fails = []
    T = "reports/TR12_QUERY_PROGRAM.md"
    tr = disk(T) or ""
    rows = text.split("\n")

    def row_of(rid):
        for i, l in enumerate(rows):
            if l.startswith(rid + "\t"):
                return i, l.split("\t")
        raise KeyError(rid)

    def with_row(rid, **kw):
        i, f = row_of(rid)
        f = f[:]
        for k, v in kw.items():
            f[COLS.index(k)] = v
        new = rows[:]
        new[i] = "\t".join(f)
        return "\n".join(new)

    def expect(name, t, want, rid=None, want_row=None, overrides=None):
        v, res, err = check(t, cache, overrides)
        ok = v == want
        if rid is not None and ok:
            ok = rid in res and res[rid][0] == want_row
        detail = err or (res.get(rid, (None, ""))[1] if rid else "")
        print("  [%s] %s -> %s%s%s" % ("ok" if ok else "FAIL", name, v,
                                      " (%s=%s)" % (rid, res[rid][0]) if rid in (res or {}) else "",
                                      ("  " + detail[:160]) if detail else ""))
        if not ok:
            fails.append(name)

    v, res, err = check(text, cache)
    ok = v == "PASS" and len(res) > 0 and all(o for o, _ in res.values())
    print("  [%s] P0 positive control: the tracked ledger on the tracked tree reads PASS (%d rows)" % ("ok" if ok else "FAIL", len(res)))
    if not ok:
        fails.append("P0")
        for rid, (o, why) in res.items():
            if not o:
                print("       %s: %s" % (rid, why))

    # the rows the mutants act on must exist, or a mutant would pass by not firing
    need = ["TR12_SUM_DOOMED_PCT", "TR12_SUM_C3_ATTRIBUTION", "TR12_ABS_EXCH_TV", "TR12_SUM_B0",
            "TR12_V1_KW_OWN_SLOT"]
    try:
        for rid in need:
            row_of(rid)
    except KeyError as exc:
        print("  [FAIL] the self-test needs ledger row %s and it is missing" % exc)
        print("CLAIM_LEDGER_SELFTEST=FAIL")
        return 1
    _, f = row_of("TR12_SUM_DOOMED_PCT")
    dline = int(f[COLS.index("source")].rsplit(":", 1)[1])
    _, f = row_of("TR12_SUM_C3_ATTRIBUTION")
    cline = int(f[COLS.index("source")].rsplit(":", 1)[1])
    _, f = row_of("TR12_ABS_EXCH_TV")
    eline = int(f[COLS.index("source")].rsplit(":", 1)[1])
    trl = tr.split("\n")

    def tr_with(lno, old, new):
        l = trl[:]
        if old not in l[lno - 1]: raise AssertionError((lno, old))
        l[lno - 1] = l[lno - 1].replace(old, new, 1)
        return {T: "\n".join(l)}

    expect("M1 wrong value planted in the ledger (68.67 -> 68.68)",
           with_row("TR12_SUM_DOOMED_PCT", value="68.68"), "FAIL", "TR12_SUM_DOOMED_PCT", False)
    expect("M2 published text changed under a correct ledger (68.67 -> 68.76)",
           text, "FAIL", "TR12_SUM_DOOMED_PCT", False, tr_with(dline, "68.67", "68.76"))
    # M3: find the premise's line in the paragraph (it may wrap onto the next line) and remove it
    _, f = row_of("TR12_SUM_C3_ATTRIBUTION")
    prem = f[COLS.index("premise")]
    pl = next((i for i in range(cline - 2, cline + 3) if prem in trl[i - 1]), None)
    if pl is None:
        print("  [FAIL] M3 cannot find premise %r near line %d" % (prem, cline))
        fails.append("M3")
    else:
        expect("M3 conditional figure rendered bare (premise %r deleted from its sentence)" % prem,
               text, "FAIL", "TR12_SUM_C3_ATTRIBUTION", False, tr_with(pl, prem, "result"))
    # M4/M5: plant a conditional-on row over the abstract's 0.0415, whose paragraph carries
    # "cannot attribute by measurement" in a LATER sentence; then the same premise in its own sentence
    _, f = row_of("TR12_ABS_EXCH_TV")
    planted = f[:]
    planted[COLS.index("id")] = "SELFTEST_PLANTED"
    planted[COLS.index("scope")] = "conditional-on:selftest"
    planted[COLS.index("premise")] = "cannot attribute by measurement"
    t4 = text.rstrip("\n") + "\n" + "\t".join(planted) + "\n"
    para_has = any("cannot attribute by measurement" in trl[i] for i in range(eline - 1, min(eline + 6, len(trl))))
    if not para_has:
        print("  [FAIL] M4 precondition: the premise is not in the paragraph after line %d" % eline)
        fails.append("M4-pre")
    expect("M4 premise in the same paragraph, different sentence", t4, "FAIL", "SELFTEST_PLANTED", False)
    expect("M5 twin: premise moved into the value's sentence", t4, "PASS", "SELFTEST_PLANTED", True,
           tr_with(eline, "0.0415", "0.0415 (cannot attribute by measurement)"))
    expect("M6 one line inserted above every cited line",
           text, "FAIL", "TR12_SUM_DOOMED_PCT", False, {T: "\n" + tr})
    expect("M7 evidence key renamed to one the command does not print",
           with_row("TR12_SUM_DOOMED_PCT", key="DOOMED_FRACTION_OF_T_ROOT_X"), "FAIL", "TR12_SUM_DOOMED_PCT", False)
    _, f = row_of("TR12_SUM_DOOMED_PCT")
    ev = f[COLS.index("evidence")]
    expect("M8 evidence names a solve.py flag that does not exist",
           with_row("TR12_SUM_DOOMED_PCT", evidence=ev.replace("--atlas-probe", "--atlas-probe-nonexistent")),
           "FAIL", "TR12_SUM_DOOMED_PCT", False)
    _, f = row_of("TR12_V1_KW_OWN_SLOT")
    expect("M9 figure present only inside a longer number (3 in 0.0299-0.0337)",
           with_row("TR12_V1_KW_OWN_SLOT", value="3", render="pct:0", key="POSITIONAL_TV_FROM_UNIFORM_MAX_INTERIOR"),
           "FAIL", "TR12_V1_KW_OWN_SLOT", False)
    expect("M10a unknown status", with_row("TR12_SUM_B0", status="certain"), "ERROR")
    expect("M10b unknown render", with_row("TR12_SUM_B0", render="roughly"), "ERROR")
    i, f = row_of("TR12_SUM_B0")
    expect("M10c a row with a column missing",
           "\n".join(rows[:i] + ["\t".join(f[:-1])] + rows[i + 1:]), "ERROR")
    expect("M10d duplicate id", text.rstrip("\n") + "\n" + rows[i] + "\n", "ERROR")
    expect("M11 artifact path that does not exist",
           with_row("TR12_SUM_B0", artifact="runs/no_such_dir/atlas.json"), "FAIL", "TR12_SUM_B0", False)
    # M12: EVERY row's evidence discriminates. A consistent wrong figure -- the same perturbed value
    # in the ledger AND on the published line -- passes S and P by construction, so only E can
    # catch it; every row must go FALSE, and on E.
    missed = []
    parsed = parse(text)
    for r in parsed:
        old = r["value"]
        if old in WORDS:
            new = WORDS[(WORDS.index(old) + 1) % len(WORDS)]
        elif old.endswith("=FAIL") or old.endswith("=PASS"):
            new = old[:-4] + ("PASS" if old.endswith("FAIL") else "FAIL")
        else:
            m = list(re.finditer(r"[0-9]", old))
            if not m:
                missed.append(r["id"] + "(no digit to perturb)")
                continue
            k = m[-1].start()
            new = old[:k] + str((int(old[k]) + 1) % 10) + old[k + 1:]
        path, lno = r["source"].rsplit(":", 1)
        lno = int(lno)
        src = (disk(path) or "").split("\n")
        mm = value_re(old).search(src[lno - 1]) if lno <= len(src) else None
        if not mm:
            missed.append(r["id"] + "(value not on its line)")
            continue
        src[lno - 1] = src[lno - 1][:mm.start()] + new + src[lno - 1][mm.end():]
        one = "\n".join(l if not l.startswith(r["id"] + "\t") else
                        "\t".join(new if c == "value" else r[c] for c in COLS) for l in rows)
        v, res, err = check(one, cache, {path: "\n".join(src)})
        ok, why = res.get(r["id"], (True, err))
        if ok or not why.startswith("E:"):
            missed.append("%s(%s -> %s: %s)" % (r["id"], old, new, "TRUE" if ok else why[:80]))
    print("  [%s] M12 every row's evidence rejects a consistent wrong figure (ledger AND text): %d of %d rows go FALSE on E%s"
          % ("ok" if not missed else "FAIL", len(parsed) - len(missed), len(parsed),
             "" if not missed else "; missed: " + "; ".join(missed[:8])))
    if missed:
        fails.append("M12")
    print("CLAIM_LEDGER_SELFTEST=%s" % ("FAIL" if fails else "PASS"))
    return 1 if fails else 0


def main(argv):
    mode_check = mode_self = False
    ledger = LEDGER_DEFAULT
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--check":
            mode_check = True
        elif a == "--selftest":
            mode_self = True
        elif a == "--ledger" and i + 1 < len(argv):
            ledger = argv[i + 1]
            i += 1
        elif a == "--derive" and i + 1 < len(argv):
            fn = DERIVE.get(argv[i + 1])
            if fn is None:
                print("unknown derivation %r; known: %s" % (argv[i + 1], " ".join(sorted(DERIVE))))
                return 2
            fn()
            return 0
        else:
            print("usage: claim_ledger.sh [--check] [--selftest] [--ledger FILE] | --derive NAME")
            print("CLAIM_LEDGER=ERROR")
            return 2
        i += 1
    if not (mode_check or mode_self):
        mode_check = True
    text = disk(ledger)
    if text is None:
        print("  [ERROR] cannot read %s" % ledger)
        print("CLAIM_LEDGER=ERROR")
        return 2
    cache = {}
    rc = 0
    if mode_check:
        print("== claim ledger: %s ==" % ledger)
        v, res, err = check(text, cache)
        report(v, res, err)
        rc = {"PASS": 0, "FAIL": 1}.get(v, 2)
    if mode_self:
        print("== claim ledger self-test ==")
        rc = max(rc, selftest(ledger, text, cache))
    return rc


sys.exit(main(sys.argv[1:]))
CLAIM_LEDGER_PY
