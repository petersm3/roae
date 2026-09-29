#@ scripts/doc_gates.d/99_lsd_text.sh -- sourced by scripts/doc_gates.sh; not runnable on its own.
#@ GATE 93: the TEXT fixes of the Codex Lean/SAT/DRAT adversarial review, as triaged by Fable
#@ (CX-232, 2026-09-29), stay fixed. Run it through the entry: bash scripts/doc_gates.sh lsd-text
# ---------------------------------------------------------------------------
# GATE 93 — the LSD TEXT fixes stay fixed (`lsd-text`). CX-232, 2026-09-29.
#
# WHY. The review found wording that said more than its proof, recipe or count supports, in places
# GATE 3's registry cannot reach: shell scripts, a committed golden, solve.c comments, recipe lines in
# a .txt certificate file, and statements whose defect is an ABSENT citation rather than a present
# phrase. Each leg below names its triage row. A leg of the form "must be absent" is a needle for a
# retired wording in a non-markdown file; a leg of the form "must be present" pins the scoping clause
# or citation the fix added, on the line that needs it.
#
# EVERY LEG ASSERTS ITS PRECONDITION. A file that cannot be read, or an anchor line that is no longer
# found, is a FAIL, not a pass: a leg whose target moved has checked nothing.
#
# RED/GREEN. DOC_GATE_LSD_REF=<commit> reads every file from that commit instead of the working tree.
# On b0abe4e5 (the tree before CX-232) every leg but the precondition-only ones FAILS; on the fixed
# tree every leg passes. The needles for retired wordings are spelled with a bracketed character class
# where a registry row also holds the phrase, so that this file is not itself a carrier of it.
# ---------------------------------------------------------------------------
gate_lsd_text() {
  echo "== GATE 93: the LSD review's TEXT fixes stay fixed (CX-232) =="
  DOC_GATE_LSD_REF="${DOC_GATE_LSD_REF:-}" python3 - <<'LSD_PY'
import os, re, subprocess, sys
REF = os.environ.get("DOC_GATE_LSD_REF", "")
bad = 0
def read(path):
    if REF:
        r = subprocess.run(["git", "show", "%s:%s" % (REF, path)], capture_output=True)
        if r.returncode != 0:
            return None
        return r.stdout.decode("utf-8", "replace")
    try:
        return open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return None
def ls(pattern):
    cmd = ["git", "ls-tree", "-r", "--name-only", REF] if REF else ["git", "ls-files"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        return None
    return [f for f in r.stdout.split() if re.fullmatch(pattern, f)]
def fail(leg, msg):
    global bad
    bad = 1
    print("  [FAIL] %s: %s" % (leg, msg))
def ok(leg, msg):
    print("  [ok] %s: %s" % (leg, msg))
def need(leg, path):
    t = read(path)
    if t is None:
        fail(leg, "%s cannot be read -- nothing was checked" % path)
    return t
def absent(leg, path, rx, why):
    t = need(leg, path)
    if t is None:
        return
    hits = [i + 1 for i, l in enumerate(t.split("\n")) if re.search(rx, l)]
    if hits:
        fail(leg, "%s:%s still carries the retired wording (%s)" % (path, ",".join(map(str, hits[:5])), why))
    else:
        ok(leg, "%s is clear of /%s/" % (path, rx))
def line_has(leg, path, anchor_rx, must_rx, why):
    t = need(leg, path)
    if t is None:
        return
    lines = [(i + 1, l) for i, l in enumerate(t.split("\n")) if re.search(anchor_rx, l)]
    if not lines:
        fail(leg, "%s: no line matches the anchor /%s/ -- the target moved, so nothing was checked" % (path, anchor_rx))
        return
    for n, l in lines:
        for m in must_rx:
            if not re.search(m, l):
                fail(leg, "%s:%d lacks /%s/ (%s)" % (path, n, m, why))
                break
        else:
            ok(leg, "%s:%d carries %s" % (path, n, " + ".join("/%s/" % m for m in must_rx)))

# R2 -- SOLVE.md's C3-ceiling sentence: the retired share is not restated outside the ledger.
mds = ls(r".*\.md")
if not mds:
    fail("R2", "the markdown corpus could not be listed -- nothing was checked")
else:
    hits = []
    for f in mds:
        if f == "documentation/CORRECTIONS.md":
            continue
        t = read(f) or ""
        hits += ["%s:%d" % (f, i + 1) for i, l in enumerate(t.split("\n")) if re.search(r"99\.99999[9]", l)]
    if hits:
        fail("R2", "the retired C3-ceiling share survives at %s (the measured split is 90.09 %% strictly below, 9.91 %% tied)" % ", ".join(hits[:5]))
    else:
        ok("R2", "no markdown file outside CORRECTIONS.md restates the retired share (%d files)" % len(mds))
# R3 / R5 -- the Q10 echo lines and their committed n=9 golden.
absent("R3", "scripts/tr12_repro.sh", r"STATE census by G-orbit-size clas[s]", "a mask-orbit census, not a state census")
absent("R5", "scripts/tr12_repro.sh", r"RECORD-level orbit identit[y]", "N/24 is an integrality identity")
absent("R5", "scripts/tr12_expected/n9/c_q10a.txt", r"RECORD-level orbit identit[y]", "golden must match the script")
# R9 -- the KB4 out-of-core reader gate's status is stated where a reader of the ladders looks.
line_has("R9", "documentation/GT_LADDER_FORMAT.md", r"F2_GCHECK_DETECTS=NO", [r"reader-side corruption"], "substitute evidence and its limit")
line_has("R9", "reports/TR12_QUERY_PROGRAM.md", r"TR12_OOCVERIFY=SKIP", [r"F2_GCHECK_DETECTS=NO"], "the skip is stated beside its substitute evidence")
# R11 -- solve.c no longer calls the G accumulator's equality with the Lean model machine-checked.
absent("R11", "solve.c", r"not bridge-carrie[d]", "the equality is a bridge fact")
# R16 -- the minimal-repair ledger row cites its SAT witness.
line_has("R16", "reports/TR12_QUERY_PROGRAM.md", r"Minimal repair from KW", [r"q7_witnesses/moore-strict\.txt"], "the k = 3 half is SAT-witnessed")
# R17 -- a recipe must not chain a checker behind kissat with && (kissat exits 10/20).
files = (ls(r".*\.md") or []) + (ls(r"reports/certificates/.*\.txt") or []) + (ls(r"reports/evidence/.*\.txt") or [])
if not files:
    fail("R17", "no recipe-bearing file could be listed -- nothing was checked")
else:
    hits = []
    for f in files:
        if f in ("documentation/CORRECTIONS.md", "documentation/HISTORY.md"):
            continue
        t = read(f) or ""
        hits += ["%s:%d" % (f, i + 1) for i, l in enumerate(t.split("\n"))
                 if re.search(r"kissat[^|;]*&&", l) and "|| true" not in l]
    if hits:
        fail("R17", "kissat ... && recipe(s) that never reach the next command: %s" % ", ".join(hits[:6]))
    else:
        ok("R17", "no kissat ... && recipe in %d files" % len(files))
# R19c / R19e / R19f -- scoping clauses on the lines that need them.
line_has("R19c", "reports/TR8_REORDERING_REVISITED.md", r"Gray adjacency requires distance 1", [r"one-line corollary"], "Lean proves the canonical-partner case")
line_has("R19c", "documentation/SPECIFICATION.md", r"xor_all_seven_attained", [r"one-line corollary"], "Lean proves the canonical-partner case")
line_has("R19e", "reports/TR12_QUERY_PROGRAM.md", r"partner_is_unique_minimum", [r"IsCompRevPairing"], "optimal among complement/reverse matchings")
line_has("R19f", "reports/TR12_QUERY_PROGRAM.md", r"Literature rules proven forced", [r"_const`", r"transcription"], "cite the constancy theorems with the transcription caveat")
# R21 -- TR-2's count of the certificate directory equals the directory.
t = need("R21", "reports/TR2_THE_RULES_CONFLICT.md")
certs = ls(r"reports/certificates/[^/]*\.drat\.gz")
if t is not None:
    m = re.search(r"\((\d+) in the\s+directory today", t)
    if not m:
        fail("R21", "TR-2's '(N in the directory today' count is gone -- the anchor moved, nothing was checked")
    elif certs is None:
        fail("R21", "the certificate directory could not be listed")
    elif int(m.group(1)) != len(certs):
        fail("R21", "TR-2 says %s certificates are in the directory; git lists %d" % (m.group(1), len(certs)))
    else:
        ok("R21", "TR-2's directory count %s equals the %d tracked .drat.gz files" % (m.group(1), len(certs)))
# R22 -- retired comment wordings in C and a run page.
absent("R22", "solve.c", r"4 rev-palindrom", "there are 8 rev-palindromes: 0,12,18,30,33,45,51,63")
absent("R22", "solve.c", r"stored ONLY on the f-reachable domai[n]", "stored on a superset of it")
absent("R22", "runs/20260906_kc_ladders_n31/README.md", r"F1C5LAY2` for f and [g]", "g layers carry F1C5GLY2")
# LSR (the reconciliation of the TEXT and LEAN-SAT halves, 2026-09-29) -- prose that must describe
# what the merged tree does: the census leg and its token, the directives, the emitted-clause test,
# the verified-certificate count, the witness-file tokens, the C1 pairing in both recipes, the KB4
# status in the Lean comment, and the scoped sat.py header rule where the unscoped one survived.
absent("R7", "sat.py", r"NO hand-written constraint semantic[s]", "the rule covers predicates; the clause arithmetic is tested, not derived")
absent("R7", "CLAUDE.md", r"NO hand-written constraint semantic[s]", "same rule, scoped")
line_has("R7", "documentation/SAT_CLI.md", r"clause arithmetic that positions them", [r"TestSatEmittedClausesNonKW"], "the emitted clauses are now tested off King Wen")
line_has("R7", "reports/certificates/README.md", r"offset mutant", [r"TestSatEmittedClausesNonKW"], "the mutant is caught by the emitted-clause test")
line_has("R8", "lean/README.md", r"source-census leg", [r"LEAN_SOURCE_CENSUS", r"partial def"], "name the token and every pattern the leg screens")
line_has("R8", "documentation/QUERY_INVENTORY.md", r"All four are committed, and each theorem", [r"LEAN_SOURCE_CENSUS", r"carried none until 2026-09-29"], "KingWen.lean now carries directives")
line_has("R9", "lean/CompilerCorrectness.lean", r"Status 2026-09-29: not run as specified", [r"F2_GCHECK_DETECTS=NO"], "the KB4 comment states its status")
absent("R13", "reports/TR1_EIGHT_CENTURIES_MEASURED.md", r"compatible 3-edit even[t]", "a minimum repair distance, not an event")
line_has("R18g", "documentation/SAT_CLI.md", r"base\*\* ground truth", [r"partner pair"], "verify_seq checks the C1 pairing")
line_has("R18g", "reports/certificates/c3_positional_witnesses.txt", r"verify\.py: ", [r"PAIRS"], "the manual recipe checks the C1 pairing")
line_has("R18k", "documentation/SAT_CLI.md", r"DRAT_CERTS_CHECKED=<n>", [r"passed"], "the count is of verified certificates")
line_has("R18a", "reports/certificates/README.md", r"c3_positional_witnesses\.txt` \| 42 verified", [r"WITNESS_G95_LAYOUT", r"WITNESS_ANNOTATIONS_CHECKED"], "document the witness-file tokens")
print("LSD_TEXT_GATE=%s" % ("FAIL" if bad else "PASS"))
sys.exit(bad)
LSD_PY
}
