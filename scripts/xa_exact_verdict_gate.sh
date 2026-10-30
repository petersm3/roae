#!/usr/bin/env bash
# xa_exact_verdict_gate.sh — Codex review MQ1 section 4.
#
# WHY. `xa_verdict.md` calls `cost/budget` "the exact shortfall" and prints an
# EXHAUSTIBLE / INFEASIBLE call.  That call is a SCIENTIFIC VERDICT: it is the
# sentence "this branch can / cannot be exhausted for the stated money."  Until
# 2026-09-04 it was decided by
#
#     hours = nodes / rate / 3600.0 ;  usd = hours * usd_per_hour
#     ok    = usd <= budget_usd
#
# in binary64, while `nodes` is an exact 192-bit integer.  The relative error is
# ~1e-19 — far too small to matter for the printed numeral, and MORE than large
# enough to REVERSE the verdict at the boundary.  That is the "correct answer to
# the wrong question" class: the number was fine, only the claim of exactness on
# the call derived from it was false.
#
# 🔴 THIS GATE IS A PAIR OF BOUNDARY MUTANTS, NOT A HAPPY PATH.  Two fixtures,
# because the defect has two independent halves and neither fixture catches the
# other's:
#
#   FIXTURE A -- exactness of the ARITHMETIC.  Budget 2**100 (exactly a double,
#     so nothing but the arithmetic can move), cost 2**100 + 1/3600.  The excess
#     is ~1e-15 of one ulp, so EVERY float route -- comparing in float, computing
#     `hours` in float, computing `usd` in float -- rounds the cost back onto the
#     budget and says EXHAUSTIBLE.  Exactly, the budget IS exceeded: INFEASIBLE.
#
#   FIXTURE B -- exactness of the $/hour ANCHOR.  Cost lands EXACTLY on the
#     budget when $/hour is read as the typed decimal 0.1, and 5.6e-17 ABOVE it
#     when 0.1 is read as its binary64 approximation.  Fixture A cannot catch
#     this: there every anchor is exactly representable, so an anchor round trip
#     is invisible.  Honest call: EXHAUSTIBLE.
#
#   FIXTURE C -- exactness of the RATE DIVISION.  hedge = 3, so the effective
#     rate is 1/3, which is not a double.  Cost lands exactly on the budget in
#     exact arithmetic and 5.6e-17 above it if the rate is divided in binary64
#     first.  Fixtures A and B both use rate 1 and cannot see this.  Honest
#     call: EXHAUSTIBLE.
#
# Each fixture kills a mutant the other two survive; that is why there are three
# and not one.  Adding a float back anywhere on this path turns one of them red.
#
# 🔴 IT IS NOT SATISFIED BY ITS OWN EMPTINESS (Codex N07).  If `atlas_emit_xa`
# were deleted, renamed, or stopped emitting an Exhaustibility section, that is
# an ERROR here, not a pass: the gate asserts the section EXISTS and carries a
# priced branch row and a Call line before it grades which token they hold.
#
# COST: pure Python, no solve.c build, well under a second.
#
# Usage: scripts/xa_exact_verdict_gate.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

PYTHONPATH="$PWD" python3 - <<'PY'
import json, os, re, sys, tempfile
from fractions import Fraction
import solve

# \U0001f534 A REAL certificate file, not a string stub. The stub used to be the literal
# "STUB-FOR-ARITHMETIC-GATE-ONLY", which worked only while the refusal guard tested that a
# path STRING had been supplied and never opened it. The day that guard learned to read the
# file (Q-433), every fixture here stopped reaching the priced branch and this gate went
# ERROR -- correctly. The lesson is the gate's own: a fixture that satisfies a check by being
# shaped like evidence rather than by being evidence fails the moment the check gets honest.
# \U0001f534 Q-772 (the Q-768 ruling, section 3): the fixture is now a FULL-SCHEMA W0-D certificate,
# because the consumer no longer reads a permission sentence -- it reads `mapping.nodes_per_t_unit`
# and MULTIPLIES every row by it. F = 1/1 and kind = exact keep the three boundary fixtures below
# exactly where they were. `provenance.engine_git` starts "FIXTURE:", and the consumer echoes it
# beside the priced table, so any xa_verdict.md this fixture ever reaches names itself.
_CERT = os.path.join(tempfile.mkdtemp(), "node_mapping_cert.json")
with open(_CERT, "w", encoding="utf-8") as _fh:
    json.dump({"type": "roae-w0d-node-mapping-certificate", "version": 1,
               "mapping": {"kind": "exact", "nodes_per_t_unit": "1/1", "residual": 0,
                           "formula": "FIXTURE: 1 t-unit == 1 production-DFS node, asserted ONLY "
                                      "so the pricing ARITHMETIC can be graded",
                           "law": "FIXTURE: none -- this is not a W0-D certificate and must never "
                                  "be copied into a real run"},
               # Q-841 S6: the loader now requires a non-empty integer `measured.n`, so the
               # fixture names the atlas size it prices (9); the verdict line says no run was made.
               "measured": {"n": [9], "per_n": [],
                            "verdict_line": "FIXTURE: no W0-D run was made"},
               "provenance": {"engine_git": "FIXTURE:xa_exact_verdict_gate.sh",
                              "engine_source_sha": "FIXTURE", "host_fingerprint": "FIXTURE",
                              "produced": "FIXTURE"},
               "semantics": "certificate-not-proof"}, _fh)

K = solve.binary_hexagrams
rc = 0


def price(nodes, nps, uph, budget, hedge="1", wf="1", cost_override=None):
    """Run the REAL emitter over a one-branch atlas; return (branch row, Call line)."""
    A = {"n": 9, "N_total": "24", "type": "branch-atlas", "space": "xa-exact-gate-fixture",
         "semantics": "synthetic fixture for the XA exact-verdict boundary gate",
         "t_root_t_units": str(nodes + 1),
         "layers": [{"k": 0, "flow": "24"}],
         "branch_atlas": [{"global_pair": 1, "entry": K[2], "exit": 0, "solutions": "24",
                           "walks": 24, "prefixes_t_units": str(nodes)}]}
    cost = {"nodes_per_sec": solve._ExactAnchor(nps),
            "usd_per_hour":  solve._ExactAnchor(uph),
            "budget_usd":    solve._ExactAnchor(budget),
            "hedge":         solve._ExactAnchor(hedge),
            "work_factor":   solve._ExactAnchor(wf),
            # This gate grades the pricing ARITHMETIC, so it must reach the priced branch. The
            # t-unit -> SOLVE_NODE_LIMIT refusal (B17) is a separate, upstream question and is
            # exercised by its own fixture below; a stub cert here keeps this leg measuring the
            # thing it exists to measure instead of reporting "measured NOTHING".
            "node_mapping_cert": _CERT,
            "note":          "xa_exact_verdict_gate.sh boundary fixture"}
    if cost_override is not None:
        cost = cost_override
    with tempfile.TemporaryDirectory() as d:
        solve.atlas_emit_xa(A, d, cost=cost, atlas_path="xa_exact_verdict_gate.json")
        md = open(os.path.join(d, "xa_verdict.md")).read()
    # CLOSURE: the things we grade must be THERE.
    if "## Exhaustibility (XA-c/d)" not in md:
        print("  [ERROR] xa_verdict.md has no Exhaustibility section -- gate measured NOTHING.")
        print("XA_EXACT_VERDICT=ERROR"); sys.exit(2)
    call = [l for l in md.splitlines() if l.startswith("Call: ")]
    row = [l for l in md.splitlines() if l.startswith("| 0 | 1 | %d |" % nodes)]
    if not call or not row:
        print("  [ERROR] no Call: line and/or no priced branch row -- gate measured NOTHING.")
        print("XA_EXACT_VERDICT=ERROR"); sys.exit(2)
    return row[0], call[0], md


def grade(label, want, row, call, hint):
    # The VERDICT CELL and the Call's bolded word, compared whole (Codex, gpt-6-astra, F05-018#13):
    # `want in row` accepted NOT_INFEASIBLE / NOT_EXHAUSTIBLE anywhere on the line.
    global rc
    other = "EXHAUSTIBLE" if want == "INFEASIBLE" else "INFEASIBLE"
    cells = [c.strip() for c in row.strip().strip("|").split("|")]
    called = re.findall(r"\*\*([^*]+)\*\*", call)
    if len(cells) == 9 and cells[7] == want and called == [want]:
        print("  [ok]   %s -> %s (row and Call agree)" % (label, want))
        return
    print("  [FAIL] %s -> the emitter said %s, exact arithmetic says %s." % (label, other, want))
    print("         %s" % row.strip())
    print("         %s" % call.strip())
    print("         %s" % hint)
    rc = 1


# 🔴 NO BARE `assert` BELOW, AND THAT IS LOAD-BEARING. These are FIXTURE PRECONDITIONS: they are
# what makes fixture A a boundary case and B and C ties. `python3 -O` (or PYTHONOPTIMIZE=1, which a
# CI image can carry silently) STRIPS assert statements, so as asserts they would vanish and this
# gate would grade three fixtures nobody had verified were fixtures. That is exactly how
# verify_all.sh §3b passed while checking zero of 42 witnesses. `raise SystemExit` cannot be
# stripped. Enforced by tests.py TestNoBareAsserts.test_heredoc_python_has_no_assert_statements.
BUDGET = 2**100                             # exactly a double: only the code can move it

# ---- FIXTURE A: exact ARITHMETIC ---------------------------------------
NODES_A = 3600 * BUDGET + 1                 # cost = BUDGET + 1/3600, i.e. over by a hair
if not (Fraction(NODES_A, 3600) > BUDGET):
    raise SystemExit("FIXTURE PRECONDITION FAILED: fixture A is not a boundary case")
if not (Fraction(NODES_A / 1.0 / 3600.0) <= BUDGET):
    raise SystemExit("FIXTURE PRECONDITION FAILED: fixture A does not round back onto the budget")
print("  fixture A: exact cost EXCEEDS the budget by 1/3600 of a dollar -- about 1e-15 of one")
print("             ulp, so every binary64 route rounds it back ONTO the budget.  INFEASIBLE.")
rowA, callA, mdA = price(NODES_A, "1", "1", str(BUDGET))
grade("fixture A (exact arithmetic)", "INFEASIBLE", rowA, callA,
      "The cost is being rounded to binary64 somewhere on this path -- the comparison, "
      "`hours`, or `usd`.  Do not widen the budget: keep every step a Fraction.")

# ---- FIXTURE B: exact $/hour ANCHOR -------------------------------------
NODES_B = 36000 * BUDGET                    # cost is EXACTLY the budget when $/h is 1/10
if not (Fraction(NODES_B, 3600) * Fraction("0.1") == BUDGET):
    raise SystemExit("FIXTURE PRECONDITION FAILED: fixture B is not a tie")
if not (Fraction(NODES_B, 3600) * Fraction(float(0.1)) > BUDGET):
    raise SystemExit("FIXTURE PRECONDITION FAILED: fixture B has no gap")
print("  fixture B: $/hour typed as 0.1 puts the cost EXACTLY on the budget; read as its")
print("             binary64 approximation it lands 5.6e-17 above.  Honest call: EXHAUSTIBLE.")
rowB, callB, mdB = price(NODES_B, "1", "0.1", str(BUDGET))
grade("fixture B (typed decimal $/hour anchor)", "EXHAUSTIBLE", rowB, callB,
      "The operator's typed decimal is being round-tripped through binary64 before it is "
      "priced.  Keep the anchors as _ExactAnchor (argparse type=) so `.exact` survives.")

# ---- FIXTURE W: exact WORK-FACTOR anchor (G5a; Codex F05-018#11) ----------
# Every other fixture prices at work_factor 1, so rounding that anchor changed nothing they saw.
NODES_W = 36000 * BUDGET                    # cost is EXACTLY the budget when the work factor is 1/10
if not (Fraction(NODES_W, 3600) * Fraction("0.1") == BUDGET):
    raise SystemExit("FIXTURE PRECONDITION FAILED: fixture W is not a tie")
if not (Fraction(NODES_W, 3600) * Fraction(float(0.1)) > BUDGET):
    raise SystemExit("FIXTURE PRECONDITION FAILED: fixture W has no gap")
rowW, callW, mdW = price(NODES_W, "1", "1", str(BUDGET), wf="0.1")
grade("fixture W (typed decimal work-factor anchor)", "EXHAUSTIBLE", rowW, callW,
      "The work factor is being round-tripped through binary64 before it is priced.")

# ---- FIXTURE C: exact RATE DIVISION -------------------------------------
NODES_C = 1200 * BUDGET                     # rate 1/3 => cost = nodes*3/3600 = BUDGET exactly
if not (Fraction(NODES_C) / Fraction(1, 3) / 3600 == BUDGET):
    raise SystemExit("FIXTURE PRECONDITION FAILED: fixture C is not a tie")
if not (Fraction(NODES_C) / Fraction(1.0 / 3.0) / 3600 > BUDGET):
    raise SystemExit("FIXTURE PRECONDITION FAILED: fixture C has no gap")
print("  fixture C: hedge 3 makes the effective rate 1/3, which is not a double.  Exactly the")
print("             cost is ON the budget; divided in binary64 it lands above.  EXHAUSTIBLE.")
rowC, callC, mdC = price(NODES_C, "1", "1", str(BUDGET), hedge="3")
grade("fixture C (exact rate division)", "EXHAUSTIBLE", rowC, callC,
      "The effective rate is being computed in binary64 before the cost is divided by it.  "
      "Keep `x_rate` a Fraction; `rate` is the display copy.")

# ---- LEG 2b: the t-unit -> SOLVE_NODE_LIMIT refusal must actually refuse ----
# B17. Pricing t-units as production-DFS nodes is a scientific verdict resting on a map that
# NOTHING certifies -- `solve --kc-t-cert` says so in its own JSON. Before the guard, three flags
# produced EXHAUSTIBLE rows under a heading asserting the equality. A guard with no failing input
# is decorative, so this leg drives BOTH directions.
import re
_A = {"n": 9, "N_total": "26112", "layers": [{"flow": "26112"} for _ in range(9)],
      "branch_atlas": [{"global_pair": 1, "entry": 2, "exit": 0, "solutions": "24",
                        "walks": 24, "prefixes_t_units": "10"}]}
_base = {"nodes_per_sec": solve._ExactAnchor("1000000"), "usd_per_hour": solve._ExactAnchor("1"),
         "budget_usd": solve._ExactAnchor("1000"), "hedge": solve._ExactAnchor("2.0"),
         "work_factor": solve._ExactAnchor("1.0"), "note": "refusal leg"}
def _run(c):
    with tempfile.TemporaryDirectory() as d:
        solve.atlas_emit_xa(_A, d, cost=c, atlas_path="refusal_leg.json")
        return open(os.path.join(d, "xa_verdict.md")).read()
_without = _run(dict(_base))
_with    = _run(dict(_base, node_mapping_cert=_CERT))
_bad = []
if "PENDING" not in _without or "W0-D" not in _without or "node_mapping_cert" in _without:
    _bad.append("no cert supplied but the emitted verdict does not name the W0-D refusal")
if re.search(r"^\|.*EXHAUSTIBLE", _without, re.M) or re.search(r"^\|.*INFEASIBLE", _without, re.M):
    _bad.append("no cert supplied but a priced verdict row was still emitted")
if not (re.search(r"^\|.*EXHAUSTIBLE", _with, re.M) or re.search(r"^\|.*INFEASIBLE", _with, re.M)):
    _bad.append("cert supplied but the priced branch was NOT reached -- the guard blocks everything")
if "t-units = pruned-DFS nodes" in _without or "t-units = pruned-DFS nodes" in _with:
    _bad.append("the heading still asserts t-units == pruned-DFS nodes")
# Q-772 R7: the priced branch carries the certificate's echo block, and the fixture names itself.
if "- provenance.engine_git: `FIXTURE:xa_exact_verdict_gate.sh`" not in _with:
    _bad.append("cert supplied and priced, but the echo block does not name the FIXTURE provenance")
if "- kind: `exact`; F = nodes_per_t_unit = `1`; residual = 0" not in _with:
    _bad.append("cert supplied and priced, but the echo block does not state kind and F")
if _bad:
    for b in _bad: print("  [FAIL] node-mapping refusal: %s" % b)
    print("XA_EXACT_VERDICT=FAIL"); sys.exit(1)
print("  [ok]   node-mapping refusal fires without a cert AND lifts with one (both directions);")
print("         the priced run echoes kind, F and the FIXTURE: provenance")

# ---- LEG 2c: THE HEDGE IS A BAND, AND INFEASIBLE IS CALLED AT ITS FAST END (Q-433, batch 49) ----
# Until batch 49 the hedge only DIVIDED the rate, so the default x2 doubled every cost: cautious
# for EXHAUSTIBLE, and for INFEASIBLE -- the only call a lower-bound certificate can print -- it
# MANUFACTURED shortfall. Fixture D sits where that mattered: at the measured rate its cost is 1.5x
# the ceiling, at the slow end (rate / 2) 3x, at the fast end (rate x 2) 0.75x. So no end of the
# band supports EXHAUSTIBLE and the fast end does not support INFEASIBLE: honest call UNDECIDED.
# The old arithmetic read INFEASIBLE here, for both kinds. Fixture E is the positive control: one
# t-unit further than 2x the ceiling at the fast end, so INFEASIBLE survives the band and the leg
# cannot pass by refusing to call anything.
_LB = os.path.join(os.path.dirname(_CERT), "node_mapping_cert_lb.json")
with open(_CERT, encoding="utf-8") as _fh:
    _lbdoc = json.load(_fh)
_lbdoc["mapping"]["kind"] = "lower-bound"
_lbdoc["mapping"]["formula"] = "FIXTURE: production nodes >= 1 x t-units, asserted ONLY to grade the hedge band"
with open(_LB, "w", encoding="utf-8") as _fh:
    json.dump(_lbdoc, _fh)


def price_band(nodes, cert, budget, hours=False, hedge="2", extra=None):
    A = {"n": 9, "N_total": "24", "type": "branch-atlas", "space": "xa-exact-gate-fixture",
         "semantics": "synthetic fixture for the XA hedge-band leg",
         "t_root_t_units": str(nodes + 1), "layers": [{"k": 0, "flow": "24"}],
         "branch_atlas": [{"global_pair": 1, "entry": K[2], "exit": 0, "solutions": "24",
                           "walks": 24, "prefixes_t_units": str(nodes)}]}
    c = {"nodes_per_sec": solve._ExactAnchor("1"), "hedge": solve._ExactAnchor(hedge),
         "work_factor": solve._ExactAnchor("1"), "node_mapping_cert": cert,
         "note": "xa_exact_verdict_gate.sh hedge-band fixture"}
    if hours:
        c["budget_hours"] = solve._ExactAnchor(str(budget))
    else:
        c.update(usd_per_hour=solve._ExactAnchor("1"), budget_usd=solve._ExactAnchor(str(budget)))
    c.update(extra or {})
    with tempfile.TemporaryDirectory() as d:
        _t, _m, v, _g = solve.atlas_emit_xa(A, d, cost=c, atlas_path="xa_hedge_band_leg.json")
        md = open(os.path.join(d, "xa_verdict.md")).read()
    row = [l for l in md.splitlines() if l.startswith("| 0 | 1 | %d |" % nodes)]
    if not row:
        print("  [ERROR] hedge-band leg: no priced branch row -- this leg measured NOTHING.")
        print("XA_EXACT_VERDICT=ERROR"); sys.exit(2)
    price_band.call = next((l for l in md.splitlines() if l.startswith("Call: ")), None)
    return [c.strip() for c in row[0].strip().strip("|").split("|")][7], v


NODES_D = 3600 * 3 * BUDGET // 2            # 1.5x the ceiling at the measured rate
NODES_E = 2 * 3600 * BUDGET + 2 * 3600      # fast end = ceiling + 1
if not (Fraction(NODES_D, 3600) * 2 > BUDGET >= Fraction(NODES_D, 3600) / 2):   # slow > B >= fast
    raise SystemExit("FIXTURE PRECONDITION FAILED: fixture D is not inside the hedge band")
if not (Fraction(NODES_E, 3600) / 2 > BUDGET):
    raise SystemExit("FIXTURE PRECONDITION FAILED: fixture E is not over the ceiling at the fast end")
_band = []
for label, cert, hours, nodes, want_row, want_tok in (
        ("D lower-bound $", _LB, False, NODES_D, "UNDECIDED:lower-bound", "ONE-SIDED:lower-bound"),
        ("D lower-bound hours", _LB, True, NODES_D, "UNDECIDED:lower-bound", "ONE-SIDED:lower-bound"),
        ("D exact $", _CERT, False, NODES_D, "UNDECIDED:hedge", "UNDECIDED:hedge"),
        ("E lower-bound $", _LB, False, NODES_E, "INFEASIBLE", "ONE-SIDED:lower-bound"),
        ("E lower-bound hours", _LB, True, NODES_E, "INFEASIBLE", "ONE-SIDED:lower-bound"),
        ("E exact $", _CERT, False, NODES_E, "INFEASIBLE", "PASS")):
    got_row, got_tok = price_band(nodes, cert, BUDGET, hours=hours)
    if (got_row, got_tok) != (want_row, want_tok):
        _band.append("fixture %s: row %s / token %s, want %s / %s"
                     % (label, got_row, got_tok, want_row, want_tok))
    # G5a (Codex F05-018#12): the published Call line too -- the band fixtures read the row and the
    # token only, so a Call saying INFEASIBLE under an UNDECIDED row passed.
    want_call = "Call: the argmin branch is **%s** at the stated ceiling." % want_row
    if price_band.call != want_call:
        _band.append("fixture %s: Call line %r, want %r" % (label, price_band.call, want_call))
for label, kw, needle in (("hedge below 1", dict(hedge="0.5"), ">= 1"),
                          ("two ceilings", dict(hours=True, extra={
                              "usd_per_hour": solve._ExactAnchor("1")}), "not both")):
    try:
        price_band(NODES_D, _LB, BUDGET, **kw)
        _band.append("%s was priced instead of refused" % label)
    except solve.AtlasError as exc:
        if needle not in str(exc):
            _band.append("%s refused for the wrong reason: %s" % (label, exc))
if _band:
    for b in _band: print("  [FAIL] hedge band: %s" % b)
    rc = 1
else:
    print("  [ok]   hedge band: inside the band reads UNDECIDED (both kinds, $ and hours), past its")
    print("         fast end INFEASIBLE; a hedge below 1 and two ceilings are refused")

# ---- LEG 3: the CLI must hand the anchors over as typed decimals ---------
# The three value fixtures build `cost` directly, so a regression of the argparse
# `type=` back to plain float is invisible to them (it survived them as a mutant).
# This leg reads the REAL parser definition out of solve.py's AST.
import ast
_ANCHORS = {"--xa-nodes-per-sec", "--xa-usd-per-hour", "--xa-budget-usd",
            "--xa-hedge", "--xa-work-factor", "--xa-budget-hours"}
seen = {}
for node in ast.walk(ast.parse(open("solve.py").read())):
    if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute)
            and node.func.attr == "add_argument" and node.args
            and isinstance(node.args[0], ast.Constant) and node.args[0].value in _ANCHORS):
        continue
    t = next((k.value for k in node.keywords if k.arg == "type"), None)
    seen[node.args[0].value] = t.id if isinstance(t, ast.Name) else ast.dump(t) if t else None
missing = _ANCHORS - set(seen)
wrong = {f: t for f, t in seen.items() if t != "_ExactAnchor"}
if missing:
    print("  [ERROR] solve.py declares no %s -- this leg measured NOTHING."
          % ", ".join(sorted(missing)))
    print("XA_EXACT_VERDICT=ERROR"); sys.exit(2)
if wrong:
    for f, t in sorted(wrong.items()):
        print("  [FAIL] %s is parsed with type=%s, not _ExactAnchor -- the operator's" % (f, t))
        print("         typed decimal is destroyed before the exact pricing ever sees it.")
    rc = 1
else:
    print("  [ok]   all %d --xa-* anchors are parsed as _ExactAnchor (typed decimal preserved)"
          % len(_ANCHORS))
# LEG 3b (G5a; Codex F05-018#10): the parser's type is not the whole path -- the CLI then builds the
# cost dictionary, and a conversion there (Fraction(float-subclass) takes the binary64 value) was
# invisible. The REAL `cost = {...}` expression of the --atlas-queries handler is evaluated here on
# parsed-looking anchors and priced on fixture B, which only the typed decimal 0.1 reads EXHAUSTIBLE.
_cli = [n.value for n in ast.walk(ast.parse(open("solve.py").read()))
        if isinstance(n, ast.Assign) and len(n.targets) == 1 and isinstance(n.targets[0], ast.Name)
        and n.targets[0].id == "cost" and isinstance(n.value, ast.Dict)
        and any(isinstance(k, ast.Constant) and k.value == "usd_per_hour" for k in n.value.keys)
        and "args.xa_usd_per_hour" in ast.unparse(n.value)]
if len(_cli) != 1:
    print("  [ERROR] found %d CLI `cost = {...}` dictionaries built from args.xa_* -- leg 3b measured NOTHING." % len(_cli))
    print("XA_EXACT_VERDICT=ERROR"); sys.exit(2)
import types
_args = types.SimpleNamespace(xa_nodes_per_sec=solve._ExactAnchor("1"), xa_usd_per_hour=solve._ExactAnchor("0.1"),
                              xa_budget_usd=solve._ExactAnchor(str(BUDGET)), xa_budget_hours=None,
                              xa_hedge=solve._ExactAnchor("1"), xa_work_factor=solve._ExactAnchor("1"),
                              xa_anchor_note="xa gate leg 3b", xa_node_mapping_cert=_CERT)
_cost = eval(compile(ast.Expression(_cli[0]), "solve.py", "eval"), dict(vars(solve)), {"args": _args})
rowB3, callB3, _md3 = price(NODES_B, "1", "0.1", str(BUDGET), cost_override=_cost)
grade("leg 3b (the CLI's own cost dictionary, fixture B)", "EXHAUSTIBLE", rowB3, callB3,
      "The CLI converts an anchor after parsing; keep the _ExactAnchor objects as parsed.")
if solve._xa_exact(solve._ExactAnchor("0.1")) != Fraction(1, 10):
    print("  [FAIL] _ExactAnchor('0.1') does not price as 1/10.")
    rc = 1

# ---- LEG 4: the prose must not claim more exactness than it delivers -----
if "cost/budget` is the exact shortfall" in mdA and "for reading only" not in mdA:
    print("  [FAIL] the prose claims an 'exact shortfall' without saying the printed")
    print("         numerals are display-only renderings of the exact values.")
    rc = 1
else:
    print("  [ok]   prose separates the exact verdict from the display numerals")

sys.exit(rc)
PY
rc=$?
# \U0001f534 ONE verdict token per run. The python body already prints XA_EXACT_VERDICT=ERROR
# and exits 2 when it measured nothing; this wrapper used to add =FAIL on top, so a single run
# emitted TWO tokens and `grep -qx` could not tell "the gate found a fault" from "the gate
# measured nothing" -- which is the exact distinction ERROR exists to carry.
case "$rc" in
  0) echo "XA_EXACT_VERDICT=OK" ;;
  2) : ;;                        # the body already emitted =ERROR
  *) echo "XA_EXACT_VERDICT=FAIL" ;;
esac
exit "$rc"
