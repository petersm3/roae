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
import os, sys, tempfile
from fractions import Fraction
import solve

K = solve.binary_hexagrams
rc = 0


def price(nodes, nps, uph, budget, hedge="1", wf="1"):
    """Run the REAL emitter over a one-branch atlas; return (branch row, Call line)."""
    A = {"n": 9, "N_total": 24, "type": "branch-atlas", "space": "xa-exact-gate-fixture",
         "semantics": "synthetic fixture for the XA exact-verdict boundary gate",
         "t_root_t_units": str(nodes + 1),
         "layers": [{"k": 0, "flow": 24}],
         "branch_atlas": [{"global_pair": 1, "entry": K[2], "exit": 0, "solutions": 24,
                           "walks": 24, "prefixes_t_units": str(nodes)}]}
    cost = {"nodes_per_sec": solve._ExactAnchor(nps),
            "usd_per_hour":  solve._ExactAnchor(uph),
            "budget_usd":    solve._ExactAnchor(budget),
            "hedge":         solve._ExactAnchor(hedge),
            "work_factor":   solve._ExactAnchor(wf),
            "note":          "xa_exact_verdict_gate.sh boundary fixture"}
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
    global rc
    other = "EXHAUSTIBLE" if want == "INFEASIBLE" else "INFEASIBLE"
    if want in row and "**%s**" % want in call:
        print("  [ok]   %s -> %s (row and Call agree)" % (label, want))
        return
    print("  [FAIL] %s -> the emitter said %s, exact arithmetic says %s." % (label, other, want))
    print("         %s" % row.strip())
    print("         %s" % call.strip())
    print("         %s" % hint)
    rc = 1


BUDGET = 2**100                             # exactly a double: only the code can move it

# ---- FIXTURE A: exact ARITHMETIC ---------------------------------------
NODES_A = 3600 * BUDGET + 1                 # cost = BUDGET + 1/3600, i.e. over by a hair
assert Fraction(NODES_A, 3600) > BUDGET, "fixture A is not a boundary case"
assert Fraction(NODES_A / 1.0 / 3600.0) <= BUDGET, "fixture A does not round back onto the budget"
print("  fixture A: exact cost EXCEEDS the budget by 1/3600 of a dollar -- about 1e-15 of one")
print("             ulp, so every binary64 route rounds it back ONTO the budget.  INFEASIBLE.")
rowA, callA, mdA = price(NODES_A, "1", "1", str(BUDGET))
grade("fixture A (exact arithmetic)", "INFEASIBLE", rowA, callA,
      "The cost is being rounded to binary64 somewhere on this path -- the comparison, "
      "`hours`, or `usd`.  Do not widen the budget: keep every step a Fraction.")

# ---- FIXTURE B: exact $/hour ANCHOR -------------------------------------
NODES_B = 36000 * BUDGET                    # cost is EXACTLY the budget when $/h is 1/10
assert Fraction(NODES_B, 3600) * Fraction("0.1") == BUDGET, "fixture B is not a tie"
assert Fraction(NODES_B, 3600) * Fraction(float(0.1)) > BUDGET, "fixture B has no gap"
print("  fixture B: $/hour typed as 0.1 puts the cost EXACTLY on the budget; read as its")
print("             binary64 approximation it lands 5.6e-17 above.  Honest call: EXHAUSTIBLE.")
rowB, callB, mdB = price(NODES_B, "1", "0.1", str(BUDGET))
grade("fixture B (typed decimal $/hour anchor)", "EXHAUSTIBLE", rowB, callB,
      "The operator's typed decimal is being round-tripped through binary64 before it is "
      "priced.  Keep the anchors as _ExactAnchor (argparse type=) so `.exact` survives.")

# ---- FIXTURE C: exact RATE DIVISION -------------------------------------
NODES_C = 1200 * BUDGET                     # rate 1/3 => cost = nodes*3/3600 = BUDGET exactly
assert Fraction(NODES_C) / Fraction(1, 3) / 3600 == BUDGET, "fixture C is not a tie"
assert Fraction(NODES_C) / Fraction(1.0 / 3.0) / 3600 > BUDGET, "fixture C has no gap"
print("  fixture C: hedge 3 makes the effective rate 1/3, which is not a double.  Exactly the")
print("             cost is ON the budget; divided in binary64 it lands above.  EXHAUSTIBLE.")
rowC, callC, mdC = price(NODES_C, "1", "1", str(BUDGET), hedge="3")
grade("fixture C (exact rate division)", "EXHAUSTIBLE", rowC, callC,
      "The effective rate is being computed in binary64 before the cost is divided by it.  "
      "Keep `x_rate` a Fraction; `rate` is the display copy.")

# ---- LEG 3: the CLI must hand the anchors over as typed decimals ---------
# The three value fixtures build `cost` directly, so a regression of the argparse
# `type=` back to plain float is invisible to them (it survived them as a mutant).
# This leg reads the REAL parser definition out of solve.py's AST.
import ast
_ANCHORS = {"--xa-nodes-per-sec", "--xa-usd-per-hour", "--xa-budget-usd",
            "--xa-hedge", "--xa-work-factor"}
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
    print("  [ok]   all 5 --xa-* anchors are parsed as _ExactAnchor (typed decimal preserved)")
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
[ "$rc" -eq 0 ] || { echo "XA_EXACT_VERDICT=FAIL"; exit "$rc"; }
echo "XA_EXACT_VERDICT=OK"
