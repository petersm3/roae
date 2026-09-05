#!/usr/bin/env bash
# a2_slot_verdict_gate.sh — Codex review MQ1 §2a.
#
# WHY.  `atlas_a2_slot_check` is the per-pair EXTERNAL check: it compares the atlas's own
# raw positional-marginal field against numbers published in TR-7 before the scan existed.
# It had two independent defects, and either one alone was enough to make it useless:
#
#   (1) IT READ THE WRONG PAIR-SLOT.  The published convention (viz/viz_kc_field.md:34) is
#       "layer k ... fills pair-slot k+2", so slot 2 is layers[0].  The check read
#       `frac(layers[1])` — pair-slot THREE — and compared it against slot 2's published
#       reference.  The two are DISTINGUISHABLE in published output: TR-7 gives slot 2 =
#       5.20% and slot 3 = 3.84%, so the R-C1c sum being graded was slot32 + slot3.
#
#   (2) A FAILURE STILL EXITED 0.  The `--atlas-queries` CLI path ended in an unconditional
#       `sys.exit(0)`, so `[atlas] A2 slot check: FAIL` printed the word FAIL and the process
#       returned success.  scripts/tr12_repro.sh row `c_consumer` grades on that return code
#       and never ingests the verdict tokens.
#
# 🔴 WHY THE TWO HALVES ARE GATED TOGETHER.  Fixing (1) without (2) leaves the next wrong
# slot silent; fixing (2) without (1) makes the gate loudly certify the wrong cell.  Neither
# half is a fix on its own, so neither half is graded on its own here.
#
# 🔴 WHY IT HAD TO LAND BEFORE THE FIRST FULL-31 --regen.  This is a full-31-only path: at
# n<31 the check returns SKIP:n=<n>, so nothing published carries the defect today.  The
# first `tr12_repro.sh --regen` at n=31 would have captured the wrong number as the EXPECTED
# one, after which the battery could only ever detect drift AWAY from a wrong answer.  After
# that point this is a retraction, not a fix.
#
# 🔴 IT IS NOT SATISFIED BY ITS OWN EMPTINESS (Codex N07).  A verdict that is absent, or that
# comes back SKIP, is an ERROR here and not a pass: a fixture built to reach the full-31 path
# that does not reach it has measured nothing.  The published convention this gate's fixtures
# are built on is itself re-read out of viz/viz_kc_field.md, so a silent change to that
# convention ERRORs rather than leaving the fixtures resting on a stale premise.
#
# THE FIXTURES ARE MIRRORED ON PURPOSE.  One fixture with distinct slot-2/slot-3 values kills
# an off-by-one in one direction only, and is also survived by a "return PASS always" mutant.
# The mirror pins the other direction: with the published values moved onto slot 3, the
# CORRECT code must FAIL.
#
# 🔴 IT ALSO GATES THE SIBLINGS (Codex MQ1 §2d, added in the same pass). A2 was not the only
# verdict that could not fail. `TR12_Q10A` and `TR12_XA_A` were the LITERAL string "PASS" in
# atlas_queries, and `TR12_XA_B` tested only that a field was PRESENT, never that its identity
# held — each beside a markdown table that was free to print FAIL. `TR12_XA_MOD24` covered
# `N mod 24` and not the per-layer flows the same table checks. LEG 6 below pins all four,
# including Codex's own construction: a branch perturbed to 26,113 against N = 26,112.
# A verdict that cannot be FAIL is not a verdict, and that is the class, not the instance.
#
# COST: pure Python plus six subprocess runs of solve.py. No solve.c build. About a second.
#
# Usage: scripts/a2_slot_verdict_gate.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

PYTHONPATH="$PWD" python3 - <<'PY'
import json, os, re, subprocess, sys, tempfile
import solve

rc = 0
REPO = os.getcwd()

# ---------------------------------------------------------------------------
# LEG 0 (CLOSURE): the premise this gate rests on must still be the published one.
# ---------------------------------------------------------------------------
try:
    field_md = open(os.path.join(REPO, "viz", "viz_kc_field.md")).read()
except OSError as e:
    print("  [ERROR] cannot read viz/viz_kc_field.md (%s) -- the slot convention this gate" % e)
    print("          encodes is unverifiable, so the gate has measured NOTHING.")
    print("A2_SLOT_VERDICT=ERROR"); sys.exit(2)
if "fills **pair-slot k+2**" not in field_md:
    print("  [ERROR] viz/viz_kc_field.md no longer states 'layer k ... fills pair-slot k+2'.")
    print("          Every fixture below is built on that convention. Re-derive the gate")
    print("          against the new convention rather than editing solve.py to match it.")
    print("A2_SLOT_VERDICT=ERROR"); sys.exit(2)
print("  [ok]   published convention re-read from viz/viz_kc_field.md: layer k -> pair-slot k+2")

# The reference constants must stay the PUBLISHED ones. Without this leg the cheapest way to
# make a red fixture green is to edit the expected values, which is not a fix but a retraction.
REFS = solve._A2_SLOT_REFS
if not (abs(REFS["slot32"] - 0.0785) < 1e-9 and abs(REFS["slot2"] - 0.0520) < 1e-9
        and abs(REFS["rc1c"] - (REFS["slot32"] + REFS["slot2"])) < 1e-9):
    print("  [FAIL] _A2_SLOT_REFS no longer carries the published TR-7 values")
    print("         (slot32 0.0785, slot2 0.0520, rc1c = their sum); got %r" % (dict(REFS),))
    rc = 1
else:
    print("  [ok]   _A2_SLOT_REFS still carries the published TR-7 anchors and their sum")
if solve._A2_PAIR != 31:
    print("  [FAIL] _A2_PAIR is %r, not 31 -- A2 is {Jiji, Weiji}." % (solve._A2_PAIR,))
    rc = 1

# ---------------------------------------------------------------------------
# The fixtures.  N is round so every published percentage is an exact integer mass;
# the three cells are far enough apart (5.20 vs 3.84 vs 7.85) that no tolerance can
# blur them: tol is 2e-3 and the slot2/slot3 gap is 1.36e-2, ~7x tol.
# ---------------------------------------------------------------------------
N = 1000000
PAIR = "pair%d" % solve._A2_PAIR


def atlas(slot2_pct, slot3_pct, slot32_pct=0.0785, n=31):
    """A minimal but LOADABLE n=31 atlas carrying only what the A2 check reads."""
    layers = []
    for k in range(n):
        pct = {0: slot2_pct, 1: slot3_pct, n - 1: slot32_pct}.get(k, 0.0)
        layers.append({"k": k, "flow": str(N),
                       "marginal_raw": {PAIR: str(int(round(pct * N)))}})
    return {"type": solve._ATLAS_TYPE, "n": n, "N_total": str(N),
            "space": "a2-slot-gate-fixture",
            "semantics": "synthetic fixture for the A2 pair-slot gate; not a measurement",
            "branch_atlas": [], "layers": layers}


def grade(label, A, want, hint):
    """In-process leg: the check itself must return `want`."""
    global rc
    st, detail = solve.atlas_a2_slot_check(A)
    if st.startswith("SKIP"):
        print("  [ERROR] %s -> %s. The fixture never reached the full-31 path, so this leg" % (label, st))
        print("          measured NOTHING. %s" % detail)
        print("A2_SLOT_VERDICT=ERROR"); sys.exit(2)
    if st == want:
        print("  [ok]   %s -> %s" % (label, want))
        return
    print("  [FAIL] %s -> the check said %s, the fixture is built to be %s." % (label, st, want))
    print("         %s" % detail)
    print("         %s" % hint)
    rc = 1


# FIXTURE 1 -- the published values on their published slots.  Slot 2 = 5.20%, slot 3 = 3.84%.
# Reading layers[1] here grades 3.84% against slot 2's 5.20% reference: a 1.36e-2 deviation.
grade("fixture 1 (slot 2 = 5.20%, slot 3 = 3.84%)", atlas(0.0520, 0.0384), "PASS",
      "The check is reading a slot other than 2 for `slot2`. viz/viz_kc_field.md:34 makes "
      "slot 2 = layers[0]; layers[1] is slot 3.")

# FIXTURE 2 -- the MIRROR.  The published slot-2 value is moved onto slot 3 and vice versa.
# The correct check must now FAIL. This is the leg an off-by-one PASSES fixture 1's way, and
# it is also the leg a `return PASS` mutant cannot survive.
grade("fixture 2 (mirror: 5.20% on slot 3, 3.84% on slot 2)", atlas(0.0384, 0.0520), "FAIL",
      "The check accepted an atlas whose slot 2 does NOT carry the published value -- it is "
      "either reading slot 3, or not comparing at all.")

# FIXTURE 3 -- slot 32.  Guards the OTHER index in the same expression: layers[-1].
grade("fixture 3 (slot 32 perturbed to 6.00%)", atlas(0.0520, 0.0384, slot32_pct=0.0600),
      "FAIL", "The final-layer index is not being read, or is not being compared.")

# FIXTURE 4 -- an incomplete ladder.  layers[-1] is slot 32 only when the ladder is complete;
# a short atlas must SKIP loudly, never silently grade some other slot against slot 32.
st4, d4 = solve.atlas_a2_slot_check(
    {"type": solve._ATLAS_TYPE, "n": 31, "N_total": str(N), "branch_atlas": [],
     "layers": atlas(0.0520, 0.0384)["layers"][:20]})
if st4.startswith("SKIP:layer-count"):
    print("  [ok]   fixture 4 (20 layers for n=31) -> %s" % st4)
else:
    print("  [FAIL] fixture 4 (20 layers for n=31) -> %s. A short ladder silently re-points" % st4)
    print("         layers[-1] at a slot that is not 32 and grades it against slot 32.")
    rc = 1

# ---------------------------------------------------------------------------
# LEG 5 -- THE EXIT CODE.  End-to-end through the real CLI, because the defect being
# gated lives in the CLI path and NOT in atlas_a2_slot_check: every leg above passes
# happily while `sys.exit(0)` is unconditional.
# ---------------------------------------------------------------------------
def cli(A):
    with tempfile.TemporaryDirectory() as d:
        ap = os.path.join(d, "atlas.json")
        with open(ap, "w") as fh:
            json.dump(A, fh)
        p = subprocess.run([sys.executable, "solve.py", "--atlas-queries", ap,
                            "--atlas-select", "a2", "--atlas-out", d],
                           cwd=REPO, capture_output=True, text=True)
        vp = os.path.join(d, "VERDICTS.txt")
        verd = open(vp).read() if os.path.exists(vp) else ""
    m = re.search(r"^TR12_A2_SLOT=(.+)$", verd, re.M)
    return p.returncode, (m.group(1) if m else None), p.stdout + p.stderr


for label, A, want_tok, want_rc in (
        ("PASS atlas", atlas(0.0520, 0.0384), "PASS", 0),
        ("FAIL atlas", atlas(0.0384, 0.0520), "FAIL", 1)):
    got_rc, tok, out = cli(A)
    if tok is None:
        print("  [ERROR] `--atlas-queries --atlas-select a2` on the %s wrote no TR12_A2_SLOT" % label)
        print("          verdict at all -- this leg measured NOTHING.")
        print("          ---- captured output ----")
        for l in out.splitlines():
            print("          %s" % l)
        print("A2_SLOT_VERDICT=ERROR"); sys.exit(2)
    if tok != want_tok:
        print("  [FAIL] CLI on the %s wrote TR12_A2_SLOT=%s, expected %s" % (label, tok, want_tok))
        rc = 1
    if got_rc != want_rc:
        print("  [FAIL] CLI on the %s exited %d, expected %d. A verdict file is a claim; an"
              % (label, got_rc, want_rc))
        print("         exit code is what a shell can act on -- scripts/tr12_repro.sh row")
        print("         c_consumer grades this invocation on its RETURN CODE alone, so a")
        print("         FAIL that exits 0 is a FAIL the battery will gold as expected output.")
        rc = 1
    if tok == want_tok and got_rc == want_rc:
        print("  [ok]   CLI on the %s -> TR12_A2_SLOT=%s, exit %d" % (label, tok, got_rc))

# A non-failure must NOT be promoted to a failure: SKIP and PENDING are honest statements
# that a query did not run, and a reduced-n battery is full of them.
for tok in ("SKIP:n=9", "PENDING:--kc-coset-census", "PASS", "PASS:REDUCED-NO-CROSSTAB"):
    if solve.atlas_verdicts_rc({"K": tok}) != 0:
        print("  [FAIL] verdict %r is treated as a failure; SKIP/PENDING/qualified-PASS are not." % tok)
        rc = 1
for tok in ("FAIL", "FAIL:short-ladder"):
    if solve.atlas_verdicts_rc({"K": tok}) != 1:
        print("  [FAIL] verdict %r is not treated as a failure." % tok)
        rc = 1
print("  [ok]   FAIL/FAIL:* are failures; PASS, PASS:*, SKIP:* and PENDING:* are not")

# ---------------------------------------------------------------------------
# LEG 6 -- the sibling verdicts that were hardcoded PASS (Codex MQ1 §2d).
# Same defect class as A2's `sys.exit(0)`: a token that no input can turn red.
# ---------------------------------------------------------------------------
NX = 26112              # the real n=9 world size; divisible by 24, so a clean fixture is PASS


def xa_atlas(perturb_flow=False, perturb_sol=False, perturb_t=False, n=9):
    layers = [{"k": k, "flow": str(NX + (1 if (perturb_flow and k == 0) else 0)),
               "marginal_raw": {"pair%d" % j: "0" for j in range(32)}} for k in range(n)]
    return {"type": solve._ATLAS_TYPE, "n": n, "N_total": str(NX),
            "space": "a2-slot-gate-fixture",
            "semantics": "synthetic fixture for the verdict-honesty legs; not a measurement",
            "t_root_t_units": str(NX + 1 + (1 if perturb_t else 0)),
            "branch_atlas": [{"global_pair": 1, "entry": 63, "exit": 0,
                              "solutions": NX + (1 if perturb_sol else 0),
                              "walks": NX, "prefixes_t_units": str(NX)}],
            "layers": layers}


def cli_sel(A, sel, fault=None):
    with tempfile.TemporaryDirectory() as d:
        ap = os.path.join(d, "atlas.json")
        with open(ap, "w") as fh:
            json.dump(A, fh)
        cmd = [sys.executable, "solve.py", "--atlas-queries", ap,
               "--atlas-select", sel, "--atlas-out", d]
        if fault:
            cmd += ["--atlas-fault", fault]
        pr = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True)
        vp = os.path.join(d, "VERDICTS.txt")
        verd = open(vp).read() if os.path.exists(vp) else ""
    return pr.returncode, dict(l.split("=", 1) for l in verd.splitlines() if "=" in l), \
        pr.stdout + pr.stderr


SEL6 = "q10a,xa"
CASES = [
    # label, atlas, fault, expected {token: prefix}, expected rc
    ("clean fixture", xa_atlas(), None,
     {"TR12_Q10A": "PASS", "TR12_XA_A": "PASS", "TR12_XA_B": "PASS",
      "TR12_XA_MOD24": "PASS"}, 0),
    ("--atlas-fault q10-mod24 (the fault's OWN token)", xa_atlas(), "q10-mod24",
     {"TR12_Q10A": "FAIL"}, 1),
    ("layer-0 flow perturbed by 1 (per-layer half of XA-24)", xa_atlas(perturb_flow=True), None,
     {"TR12_Q10A": "FAIL", "TR12_XA_MOD24": "FAIL"}, 1),
    ("branch solutions 26113 against N=26112 (Codex's construction)",
     xa_atlas(perturb_sol=True), None, {"TR12_XA_A": "FAIL"}, 1),
    # This one exists because a mutant survived without it. Reverting TR12_XA_B to its old
    # "is the FIELD present?" test is invisible to every fixture above -- they all carry a
    # t_root that satisfies the identity, so presence and truth coincide. The identity has
    # to be BROKEN while the field stays present for the difference to show.
    ("t(root) off by one while the field is present (XA-b identity, not presence)",
     xa_atlas(perturb_t=True), None, {"TR12_XA_B": "FAIL"}, 1),
]
for label, A, fault, want, want_rc in CASES:
    got_rc, toks, out = cli_sel(A, SEL6, fault)
    missing = [k for k in want if k not in toks]
    if missing:
        print("  [ERROR] leg 6 (%s) emitted no %s -- it measured NOTHING."
              % (label, ", ".join(missing)))
        for l in out.splitlines():
            print("          %s" % l)
        print("A2_SLOT_VERDICT=ERROR"); sys.exit(2)
    bad = [(k, toks[k]) for k, pre in want.items() if not toks[k].startswith(pre)]
    if bad or got_rc != want_rc:
        for k, v in bad:
            print("  [FAIL] leg 6 (%s): %s=%s, expected %s*" % (label, k, v, want[k]))
        if got_rc != want_rc:
            print("  [FAIL] leg 6 (%s): exit %d, expected %d" % (label, got_rc, want_rc))
        rc = 1
    else:
        print("  [ok]   leg 6: %s -> %s, exit %d"
              % (label, " ".join("%s=%s" % (k, toks[k]) for k in sorted(want)), got_rc))

sys.exit(rc)
PY
rc=$?
[ "$rc" -eq 2 ] && exit 2
[ "$rc" -eq 0 ] || { echo "A2_SLOT_VERDICT=FAIL"; exit "$rc"; }
echo "A2_SLOT_VERDICT=OK"
