#@ scripts/doc_gates.d/97_atlas_probe_tokens.sh -- sourced by scripts/doc_gates.sh; not runnable on its own.
#@ GATE 90: the --atlas-probe token list in SOLVE_PY_CLI.md against atlas_probe() in solve.py (Q-739,
#@ 2026-09-25). Added after the Q-797 split, so it has no pre-split line range; `#@` lines are split
#@ commentary. Run it through the entry: bash scripts/doc_gates.sh atlas-probe-tokens
# ---------------------------------------------------------------------------
# GATE 90 — SOLVE_PY_CLI.md's `--atlas-probe` token list is the list the probe prints, in print
# order (`atlas-probe-tokens`). Q-739, 2026-09-25.
#
# WHY. documentation/SOLVE_PY_CLI.md documents `solve.py --atlas-probe` with a sentence that
# reads "Tokens, in print order:" and then names every whole-line KEY=value token the probe
# prints. Nothing compared that list with the code. A 2026-09-24 review found 10 tokens the
# probe printed and the list omitted (the four INVENTORY tokens among them) and 2 out of order,
# and corrected the list by hand. A hand correction fixes the instance; the next token added to
# atlas_probe() drifts the same way. This gate is the standing comparison.
#
# WHAT IT READS.
#   CODE  solve.py's atlas_probe(), parsed with `ast` (never executed). Every tok()/gate() call
#         in source order. A first argument that is a string literal is taken as is; a literal
#         `"..%d.." % p` is expanded over a `for p in (<literal tuple>)` that binds it; a call
#         to a nested helper (the V5 `_v5_max`) is followed with its literal arguments bound.
#         Exception handlers are skipped: they are the ERROR paths, and each prints ATLAS_PROBE
#         early, which is not its print position on a scored atlas. A name repeated later keeps
#         its first position. A first argument the pass cannot resolve is a FAIL naming its
#         line, never a smaller list.
#   DOC   the text from "Tokens, in print order:" to the closing "ATLAS_PROBE." of the
#         `--atlas-probe ATLAS_JSON` entry. Backtick spans and parenthesised asides are
#         removed (they quote table names, values and other tokens' history), `X{,_AT}` is
#         expanded to X and X_AT, and every remaining UPPER_CASE name with an underscore is a
#         documented token.
#   The two sequences must be EQUAL: same names, same order, because the doc claims print order.
#
# MEASURED 2026-09-25 on the n = 31 atlas: `python3 solve.py --atlas-probe
# runs/20260906_kc_ladders_n31/atlas_n31.json` printed 130 distinct keys, and they equal this
# gate's static extraction line for line. The static read is used so the gate needs no atlas
# and costs well under a second; a runtime-only token (a name built from atlas data) would show
# as UNRESOLVED here and fail, not pass silently.
#
# POSITIVE CONTROL, every run: the comparison is re-run on the documented list with one token
# dropped and with two adjacent tokens swapped, and each must be reported as a difference. A
# comparator that cannot see those two edits would print [ok] over any list.
#
# SCOPE. It checks names and order only. What each token means, and the values it takes, are
# the probe's own tests' subject (tests.py TestAtlasProbe), not this gate's.
# ---------------------------------------------------------------------------
gate_atlas_probe_tokens() {
  echo "== GATE 90: SOLVE_PY_CLI.md's --atlas-probe token list equals the tokens atlas_probe() prints, in order =="
  python3 - solve.py documentation/SOLVE_PY_CLI.md <<'ATLAS_TOKENS_PY'
import ast, re, sys
src_path, doc_path = sys.argv[1], sys.argv[2]

def fail(msg):
    print("  [FAIL] " + msg)
    print("ATLAS_PROBE_TOKEN_LIST=FAIL")
    sys.exit(1)

try:
    tree = ast.parse(open(src_path, encoding="utf-8").read())
    doc = open(doc_path, encoding="utf-8").read()
except (OSError, SyntaxError, ValueError) as exc:
    fail("cannot read %s or %s: %s -- nothing was compared" % (src_path, doc_path, exc))

# ---------- CODE: tok()/gate() names in source order ----------
fns = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == "atlas_probe"]
if len(fns) != 1:
    fail("found %d top-level def atlas_probe in %s; exactly 1 is required" % (len(fns), src_path))
fn = fns[0]
EMIT = ("tok", "gate")
helpers = {n.name: n for n in ast.walk(fn)
           if isinstance(n, ast.FunctionDef) and n is not fn and n.name not in EMIT}
code, unresolved = [], []

def lit(node):
    try:
        return ast.literal_eval(node)
    except (ValueError, TypeError, SyntaxError, MemoryError, RecursionError):
        return None

def resolve(arg, env):
    if isinstance(arg, ast.Constant) and isinstance(arg.value, str):
        return [arg.value]
    if (isinstance(arg, ast.BinOp) and isinstance(arg.op, ast.Mod)
            and isinstance(arg.left, ast.Constant) and isinstance(arg.left.value, str)
            and isinstance(arg.right, ast.Name) and arg.right.id in env):
        return [arg.left.value % v for v in env[arg.right.id]]
    return None

def visit(node, env):
    if isinstance(node, (ast.ExceptHandler, ast.FunctionDef, ast.Lambda)):
        return
    if isinstance(node, ast.For) and isinstance(node.target, ast.Name):
        visit(node.iter, env)
        vals, e = lit(node.iter), dict(env)
        if isinstance(vals, (tuple, list)):
            e[node.target.id] = list(vals)
        else:
            e.pop(node.target.id, None)
        for st in node.body + node.orelse:
            visit(st, e)
        return
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Name):
        if node.func.id in EMIT:
            r = resolve(node.args[0], env) if node.args else None
            if r is None:
                unresolved.append(node.lineno)
            else:
                code.extend(r)
        elif node.func.id in helpers:
            h, e = helpers[node.func.id], dict(env)
            for p, a in zip(h.args.args, node.args):
                v = lit(a)
                if v is None:
                    e.pop(p.arg, None)
                else:
                    e[p.arg] = [v]
            for st in h.body:
                visit(st, e)
    for child in ast.iter_child_nodes(node):
        visit(child, env)

for st in fn.body:
    visit(st, {})
if unresolved:
    fail("%d tok()/gate() name(s) in atlas_probe() could not be resolved statically, at %s line(s) %s."
         " Write the name as a literal, or extend this gate; a list with holes is not compared."
         % (len(unresolved), src_path, ", ".join(map(str, unresolved))))
code = [x for i, x in enumerate(code) if x not in code[:i]]

# ---------- DOC: the "Tokens, in print order:" list ----------
try:
    i = doc.index("--atlas-probe ATLAS_JSON")
    a = doc.index("Tokens, in print order:", i) + len("Tokens, in print order:")
    b = doc.index("ATLAS_PROBE. ", a) + len("ATLAS_PROBE")
except ValueError:
    fail("could not locate the --atlas-probe entry's 'Tokens, in print order:' ... 'ATLAS_PROBE.'"
         " list in %s -- the anchor text moved, so nothing was compared" % doc_path)
s = " ".join(l.strip() for l in doc[a:b].split("\n"))
s = re.sub(r"`[^`]*`", " ", s)
kept, depth = [], 0
for ch in s:
    if ch == "(":
        depth += 1
    elif ch == ")":
        depth -= 1
    elif depth == 0:
        kept.append(ch)
if depth != 0:
    fail("unbalanced parentheses in the documented token list of %s (depth %d at its end);"
         " the asides cannot be told from the list" % (doc_path, depth))
s = re.sub(r"\b([A-Z][A-Z0-9_]*)\{,(_[A-Z0-9_]+)\}", r"\1 \1\2", "".join(kept))
docl = re.findall(r"\b[A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+\b", s)

def differences(want, got):
    out = ["printed by atlas_probe() and missing from the list: " + x for x in want if x not in got]
    out += ["listed and not printed by atlas_probe(): " + x for x in got if x not in want]
    out += ["listed more than once: " + x for x in sorted({x for x in got if got.count(x) > 1})]
    if not out and want != got:
        k = next(j for j in range(len(want)) if want[j] != got[j])
        out.append("out of print order from position %d: printed %s, listed %s" % (k + 1, want[k], got[k]))
    return out

print("  [info] atlas_probe() prints %d distinct token(s); the list names %d" % (len(code), len(docl)))
if not code or not docl:
    fail("an empty side (code %d, doc %d) -- a pattern stopped matching; that is not agreement"
         % (len(code), len(docl)))

# ---------- positive control: the comparator sees a dropped and a swapped token ----------
if len(code) < 3:
    fail("fewer than 3 printed tokens; the positive control needs 3")
dropped = code[:1] + code[2:]
swapped = code[:1] + [code[2], code[1]] + code[3:]
if not differences(code, dropped) or not differences(code, swapped):
    fail("positive control: the comparator did not report a dropped or a swapped token")
print("  [ok]   positive control: a dropped token and a swapped pair are both reported")

diff = differences(code, docl)
if diff:
    for x in diff:
        print("  [FAIL] " + x)
    print("         Edit the 'Tokens, in print order:' list of --atlas-probe in %s to the order" % doc_path)
    print("         atlas_probe() prints; run the probe to see it.")
    print("ATLAS_PROBE_TOKEN_LIST=FAIL")
    sys.exit(1)
print("  [ok]   GATE 90: %d tokens, same names and same order in solve.py and %s" % (len(code), doc_path))
print("ATLAS_PROBE_TOKEN_LIST=PASS")
ATLAS_TOKENS_PY
}
