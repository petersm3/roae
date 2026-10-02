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
# R18 (the KCV review's Fable triage, batch 30, 2026-10-01) -- the KB1-KB7 summary sentence in
# CompilerCorrectness.lean no longer calls every bridge fact runtime-verified: KB4 is carried by
# substitute evidence (R9 above) and KB7 is derived-but-unverified, and the summary now says so.
# PRECONDITION: the file must still carry the "KB1" anchor; an empty or replaced file is a FAIL,
# not a pass, because the retired wording is absent from an empty file too.
t = need("R18", "lean/CompilerCorrectness.lean")
if t is not None:
    if "KB1" not in t:
        fail("R18", "lean/CompilerCorrectness.lean has no KB1 anchor -- not the file this leg checks, so nothing was checked")
    else:
        r18 = [i + 1 for i, l in enumerate(t.split("\n"))
               if re.search(r"each RUNTIME-VERIFIED by the named executable witnes[s]", l)]
        print("R18_KB_SUMMARY_RETIRED_WORDING_LINES=%d" % len(r18))
        if r18:
            fail("R18", "lean/CompilerCorrectness.lean:%s still calls every bridge fact runtime-verified (KB4 is substitute evidence, KB7 derived-but-unverified)" % ",".join(map(str, r18)))
        else:
            ok("R18", "lean/CompilerCorrectness.lean's KB1-KB7 summary no longer calls every bridge fact runtime-verified")
absent("R13", "reports/TR1_EIGHT_CENTURIES_MEASURED.md", r"compatible 3-edit even[t]", "a minimum repair distance, not an event")
line_has("R18g", "documentation/SAT_CLI.md", r"base\*\* ground truth", [r"partner pair"], "verify_seq checks the C1 pairing")
line_has("R18g", "reports/certificates/c3_positional_witnesses.txt", r"verify\.py: ", [r"PAIRS"], "the manual recipe checks the C1 pairing")
line_has("R18k", "documentation/SAT_CLI.md", r"DRAT_CERTS_CHECKED=<n>", [r"passed"], "the count is of verified certificates")
line_has("R18a", "reports/certificates/README.md", r"c3_positional_witnesses\.txt` \| 42 verified", [r"WITNESS_G95_LAYOUT", r"WITNESS_ANNOTATIONS_CHECKED"], "document the witness-file tokens")
# ---- Q-754 (lane G31, 2026-10-01): the Codex v3 E3 batch-4 P3 sweep -- Lean module comments,
# ---- docstrings and scope notes, plus the additive scopings of the .md items (the retired .md
# ---- phrases are RETRACTED_PHRASES.tsv rows). Each leg anchors on a line that must still exist,
# ---- so an emptied file cannot pass. On 38feb643 (the tree before the sweep) every leg FAILS.
def gone(leg, path, anchor_rx, rx, why):
    """`rx` must be absent from `path`, AND the anchor must be present (precondition)."""
    t = need(leg, path)
    if t is None:
        return
    if not re.search(anchor_rx, t):
        fail(leg, "%s: anchor /%s/ not found -- not the file this leg checks, so nothing was checked" % (path, anchor_rx))
        return
    hits = [i + 1 for i, l in enumerate(t.split("\n")) if re.search(rx, l)]
    if hits:
        fail(leg, "%s:%s still carries the retired wording (%s)" % (path, ",".join(map(str, hits[:5])), why))
    else:
        ok(leg, "%s is clear of /%s/ (anchor present)" % (path, rx))
gone("Q754-C3D#2", "lean/C3Decomposition.lean", r"remains bridge fact KB7", r"KB7, runtime-carried \(the two-language gat[e]", "KB7 is pending, not runtime-carried")
line_has("Q754-C3D#3", "lean/C3Decomposition.lean", r"^#print axioms C3Decomposition\.c3(slot_ge_12|_ge_112)$", [r"#print axioms"], "the two doc-cited C3-floor theorems carry directives")
t = need("Q754-C3D#3", "lean/C3Decomposition.lean")
if t is not None and len([l for l in t.split("\n") if re.fullmatch(r"#print axioms C3Decomposition\.c3(slot_ge_12|_ge_112)", l)]) != 2:
    fail("Q754-C3D#3", "lean/C3Decomposition.lean does not carry both c3slot_ge_12 and c3_ge_112 directives")
gone("Q754-CC#2", "lean/CompilerCorrectness.lean", r"canon` idempotence", r"runtime-carried \(`f1_canon`$", "f1_canon carries no F1_CHECK; the scan-path check is the witness")
line_has("Q754-KW#2", "lean/KingWen.lean", r"THE EQUIVARIANCE CEILING: a generator whose", [r"output mass depends only on"], "mass factors through the score")
gone("Q754-PI#1", "lean/PartitionInvariance.lean", r"T4 `", r"Phase-B re-merges, --merge-layers composition\)\.$", "--merge-layers replaces, it does not min-select")
gone("Q754-PI#2", "lean/PartitionInvariance.lean", r"B4", r"byte-identical solutions\.bin file[s]", "only the decompressed stream is fixed")
t = need("Q754-PI#3", "lean/PartitionInvariance.lean")
if t is not None:
    if "5.6T c34390c0" not in t:
        fail("Q754-PI#3", "lean/PartitionInvariance.lean: the c34390c0 witness is no longer named -- nothing was checked")
    elif t.count("irreproducible from any extant") < 2:
        fail("Q754-PI#3", "lean/PartitionInvariance.lean: the deprecated 5.6T sha lacks its irreproducibility qualifier at one of its two sites")
    else:
        ok("Q754-PI#3", "lean/PartitionInvariance.lean names c34390c0 with its qualifier at both sites")
gone("Q754-PE#2", "lean/PruneExactness.lean", r"gLB_step_self", r"runtime gate G5 cross-checks this empiricall[y]", "G5 is a proposed acceptance test, not an implemented gate")
gone("Q754-PE#2", "lean/PruneExactness.lean", r"gLB_step_self", r"esp\. G5 capped ≡ uncapped-then-filter\) and cod[e]", "no capped G prune exists in solve.c")
gone("Q754-PE#2", "lean/PruneExactness.lean", r"gLB_step_self", r"\(runtime gate G5\)\. `C` i[s]", "G5 is proposed, not implemented")
gone("Q754-PE#3", "lean/PruneExactness.lean", r"budget-kill p_d < B0_d", r"whose exactness is `capping_exact`$", "capping_exact's hMbound premise is not met by B0")
line_has("Q754-PGI#1", "lean/PruneGInvariance.lean", r"per-cell DFS work = min\(tree, B\) for a DFS", [r"stops the whole"], "the budget semantics the model assumes are named")
gone("Q754-PGI#2", "lean/PruneGInvariance.lean", r"work_orbit_invariant", r"= \|orbit\| × Σ_reps min\(tree,B\)\. -[/]", "one orbit size cannot leave a sum over four sizes")
gone("Q754-PGI#4", "lean/PruneGInvariance.lean", r"def prune70", r"\(the live predicate in solve\.c\)[:]", "main's solve.c has neither mw_pos nor inevitable")
gone("Q754-PRFC#2", "lean/PruneReprFC.lean", r"sumv_sub_of_vle", r"budget0 sums to κ·np at the top cal[l]", "the top-call budget is 2·31 = 62, not 64")
gone("Q754-LR#4", "lean/README.md", r"906 non-internal constants", r"\*\*7\*\* and \*\*35\*\* `Lean\.ofReduceBool`-bearin[g]", "the 4.31.0 detector cannot see ofReduceBool at a native_decide site")
gone("Q754-RC#1", "lean/RecordConvention.lean", r"visitedMin_exhaustive_agreement", r"wherever enumeration reached per-cell exhaustion[:]", "the hypothesis is every-variant exhaustion, not one cell")
line_has("Q754-RC#2", "lean/RecordConvention.lean", r"B5 \(walk-order monotonicity\)", [r"B5"], "anchor")
t = need("Q754-RC#2", "lean/RecordConvention.lean")
if t is not None and "SCOPE: single-" not in t:
    fail("Q754-RC#2", "lean/RecordConvention.lean: B5 lacks its single-traversal scope (parallel --sub-branch shares one budget)")
gone("Q754-RC#3", "lean/RecordConvention.lean", r"visitedMin_not_nested below", r"breaking partition-invariance and record-level nestin[g]", "the theorem shows non-nesting; the partition effect is budgeted visiting")
line_has("Q754-RC#4", "lean/RecordConvention.lean", r"regionally, with INCOMPUTABLE=0", [r"STOPPED EARLY"], "the sweep's coverage qualification travels with its rates")
gone("Q754-SEF#1", "lean/SatEncodingFidelity.lean", r"model_completeness", r"which stays with$", "verify.py's recurrence has no model-count half")
line_has("Q754-SEF#2", "lean/SatEncodingFidelity.lean", r"S01/S03 external reviews", [r"private review records"], "the review ids resolve to nothing public")
line_has("Q754-SC#1", "lean/SymmetryCompleteness.lean", r"gate SC-8 for the W2", [r"W2 × 1824"], "the W2 family is gate SC-8")
gone("Q754-TT#1", "lean/TrigramTheorems.lean", r"theorem uChange_mapP", r"record-level representatives suffice for the battery gat[e]", "uChange/lChange are oriented-list functionals")
gone("Q754-TT#1", "lean/TrigramTheorems.lean", r"theorem uChange_mapP", r"refinement \(G6, §4d\) preserves trigram functionals, s[o]", "only uChange/lChange on oriented sequences are covered")
gone("Q754-TT#2", "lean/TrigramTheorems.lean", r"theorem nuc_partner_descent", r"the canonical pairing descends along nu[c]", "nuc is not injective; the theorem is conditional on the original h")
line_has("Q754-TT#3", "lean/TrigramTheorems.lean", r"due to McKenna &$", [r"OBSERVATION at King Wen"], "McKenna is credited with the observation, not the universal")
# additive .md scopings (the retired .md phrases are registry rows: keys in CORRECTIONS.md)
line_has("Q754-PI-MD", "documentation/PARTITION_INVARIANCE.md", r"Verified via `--double-regression-test` \(2026-04-30\)", [r"irreproducible from any extant commit"], "the deprecated 5.6T sha carries its qualifier")
line_has("Q754-PO#2", "documentation/PROJECT_OVERVIEW.md", r"lex-smallest orient variant", [r"among those the run encountered"], "the kept variant is run-local, not class-global")
line_has("Q754-SPEC#4", "documentation/SPECIFICATION.md", r"~20\.6 bits to state", [r"underived"], "the statement cost carries its source's label")
line_has("Q754-SPEC#2", "documentation/SPECIFICATION.md", r"adjacency_27_satisfied", [r"step ≠ 28"], "C6 completes at step 28")
line_has("Q754-SPEC#2", "documentation/SPECIFICATION.md", r"adjacency_25_satisfied", [r"step ≠ 26"], "C7 completes at step 26")
line_has("Q754-VER#6", "documentation/VERIFY.md", r"generalises the same object to an", [r"C3-valid"], "the fiber DP assumes C3")
line_has("Q754-TS#1", "documentation/TRIGRAM_STRUCTURE.md", r"due to McKenna &$", [r"(?:\*observation\*|OBSERVATION) at King Wen"], "the binding ledger credits the observation only (it is a verbatim copy of the Lean header, GATE 66)")
# Q-763 rulings (lane G31, 2026-10-01): V3A-020#3 and V3A-025#5 CONFIRMED and fixed here.
line_has("Q763-U1", "documentation/PARITY_ALTERNATION.md", r"36-class ordering", [r"Schulz"], "the gender/position rule is Schulz-primary, Cook-elaborated, at every surviving site")
gone("Q763-U2", "documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt", r"three defensible counting rules disagree", r"on 4 of the 10 row[s]", "under the two rules as stated, six rows disagree")

print("LSD_TEXT_GATE=%s" % ("FAIL" if bad else "PASS"))
sys.exit(bad)
LSD_PY
}
